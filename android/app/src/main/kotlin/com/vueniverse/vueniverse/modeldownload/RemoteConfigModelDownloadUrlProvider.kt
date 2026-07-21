package com.vueniverse.vueniverse.modeldownload

import android.content.Context
import com.google.firebase.FirebaseApp
import com.google.firebase.remoteconfig.FirebaseRemoteConfig
import com.google.firebase.remoteconfig.FirebaseRemoteConfigSettings
import kotlinx.coroutines.tasks.await
import java.net.URL
import java.time.Instant

internal interface ModelDownloadUrlProvider {
    suspend fun resolve(forceRefresh: Boolean = false): ModelDownloadConfig
}

internal class StaticModelDownloadUrlProvider(
    private val config: ModelDownloadConfig,
) : ModelDownloadUrlProvider {
    override suspend fun resolve(forceRefresh: Boolean): ModelDownloadConfig = config
}

internal class RemoteConfigModelDownloadUrlProvider(
    context: Context,
    private val fallback: ModelDownloadConfig = ModelDownloadConfig.fromBuild(),
) : ModelDownloadUrlProvider {
    private val applicationContext = context.applicationContext

    override suspend fun resolve(forceRefresh: Boolean): ModelDownloadConfig {
        val remoteConfig = remoteConfigOrNull() ?: return fallback
        try {
            remoteConfig.setConfigSettingsAsync(
                FirebaseRemoteConfigSettings.Builder()
                    .setMinimumFetchIntervalInSeconds(MINIMUM_FETCH_INTERVAL_SECONDS)
                    .build(),
            ).await()
            remoteConfig.setDefaultsAsync(
                mapOf(
                    URL_PARAMETER to fallback.url,
                    EXPIRY_PARAMETER to "",
                ),
            ).await()
            if (forceRefresh) {
                remoteConfig.fetch(0).await()
                remoteConfig.activate().await()
            } else {
                remoteConfig.fetchAndActivate().await()
            }
        } catch (_: Exception) {
            // An already activated value can still be useful while offline. Selection below
            // validates it before the downloader is allowed to use it.
        }

        return ModelDownloadRemoteUrlPolicy.select(
            remoteUrl = remoteConfig.getString(URL_PARAMETER),
            expiresAt = remoteConfig.getString(EXPIRY_PARAMETER),
            fallback = fallback,
        )
    }

    private fun remoteConfigOrNull(): FirebaseRemoteConfig? = runCatching {
        val app = FirebaseApp.getApps(applicationContext).firstOrNull()
            ?: FirebaseApp.initializeApp(applicationContext)
            ?: return@runCatching null
        FirebaseRemoteConfig.getInstance(app)
    }.getOrNull()

    companion object {
        const val URL_PARAMETER = "medgemma_download_url"
        const val EXPIRY_PARAMETER = "medgemma_download_url_expires_at"
        private const val MINIMUM_FETCH_INTERVAL_SECONDS = 60L
    }
}

internal object ModelDownloadRemoteUrlPolicy {
    private const val PATH_STYLE_HOST = "storage.googleapis.com"
    private const val PATH_STYLE_PATH =
        "/mvp_mobile_app/models/medgemma/medgemma-1.5-4b-it-Q4_K_M.gguf"

    fun select(
        remoteUrl: String,
        expiresAt: String,
        fallback: ModelDownloadConfig,
        now: Instant = Instant.now(),
    ): ModelDownloadConfig {
        val candidate = remoteUrl.trim()
        if (!isExpectedObject(candidate)) return fallback

        val expiry = expiresAt.trim()
        if (expiry.isNotEmpty()) {
            val parsed = runCatching { Instant.parse(expiry) }.getOrNull() ?: return fallback
            if (!parsed.isAfter(now)) return fallback
        }
        return fallback.copy(url = candidate)
    }

    private fun isExpectedObject(candidate: String): Boolean = runCatching {
        val url = URL(candidate)
        url.protocol.equals("https", ignoreCase = true) &&
            url.port == -1 &&
            url.userInfo == null &&
            url.ref == null &&
            PATH_STYLE_HOST.equals(url.host, ignoreCase = true) &&
            url.path == PATH_STYLE_PATH
    }.getOrDefault(false)
}
