package com.vueniverse.vueniverse.modeldownload

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.vueniverse.vueniverse.BuildConfig
import com.vueniverse.vueniverse.medgemma.ExpectedModelArtifact
import com.vueniverse.vueniverse.medgemma.ModelArtifactLocator
import com.vueniverse.vueniverse.medgemma.ModelArtifactManager
import java.io.File
import java.net.URI
import java.util.concurrent.TimeUnit

internal data class ModelDownloadConfig(
    val url: String,
    val reserveBytes: Long = 512L * 1_024L * 1_024L,
    val allowHttpForTests: Boolean = false,
) {
    val isConfigured: Boolean get() = url.isNotBlank()

    val isValid: Boolean
        get() = runCatching {
            val uri = URI(url)
            (uri.scheme == "https" || (allowHttpForTests && uri.scheme == "http")) &&
                !uri.host.isNullOrBlank()
        }.getOrDefault(false)

    companion object {
        fun fromBuild(): ModelDownloadConfig = ModelDownloadConfig(
            url = BuildConfig.VUENIVERSE_MODEL_DOWNLOAD_URL.trim(),
        )
    }
}

internal class ModelDownloadFiles(
    context: Context,
    private val artifact: ExpectedModelArtifact =
        ModelArtifactManager.MEDGEMMA_1_5_Q4_K_M,
) {
    private val locator = ModelArtifactLocator(context.filesDir)

    val directory: File get() = locator.modelDirectory()
    val finalFile: File get() = locator.locate(artifact)
    val partialFile: File get() = File(directory, "${artifact.fileName}.part")
    val metadataFile: File get() = File(directory, "${artifact.fileName}.part.json")
}

internal class ModelDownloadStore(context: Context) {
    private val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    var consented: Boolean
        get() = preferences.getBoolean(KEY_CONSENTED, false)
        set(value) = preferences.edit().putBoolean(KEY_CONSENTED, value).apply()

    var cancelled: Boolean
        get() = preferences.getBoolean(KEY_CANCELLED, false)
        set(value) = preferences.edit().putBoolean(KEY_CANCELLED, value).apply()

    var integrityFailures: Int
        get() = preferences.getInt(KEY_INTEGRITY_FAILURES, 0)
        set(value) = preferences.edit().putInt(KEY_INTEGRITY_FAILURES, value).apply()

    fun markVerified(
        file: File,
        artifact: ExpectedModelArtifact =
            ModelArtifactManager.MEDGEMMA_1_5_Q4_K_M,
    ) {
        preferences.edit()
            .putString(KEY_VERIFIED_REVISION, artifact.modelRevision)
            .putLong(KEY_VERIFIED_LENGTH, file.length())
            .putLong(KEY_VERIFIED_MODIFIED, file.lastModified())
            .putInt(KEY_INTEGRITY_FAILURES, 0)
            .apply()
    }

    fun isVerifiedMarkerCurrent(
        file: File,
        artifact: ExpectedModelArtifact =
            ModelArtifactManager.MEDGEMMA_1_5_Q4_K_M,
    ): Boolean =
        preferences.getString(KEY_VERIFIED_REVISION, null) ==
            artifact.modelRevision &&
            preferences.getLong(KEY_VERIFIED_LENGTH, -1) == file.length() &&
            preferences.getLong(KEY_VERIFIED_MODIFIED, -1) == file.lastModified()

    fun clearVerifiedMarker() {
        preferences.edit()
            .remove(KEY_VERIFIED_REVISION)
            .remove(KEY_VERIFIED_LENGTH)
            .remove(KEY_VERIFIED_MODIFIED)
            .apply()
    }

    companion object {
        private const val PREFERENCES = "medgemma_model_download"
        private const val KEY_CONSENTED = "consented"
        private const val KEY_CANCELLED = "cancelled"
        private const val KEY_INTEGRITY_FAILURES = "integrity_failures"
        private const val KEY_VERIFIED_REVISION = "verified_revision"
        private const val KEY_VERIFIED_LENGTH = "verified_length"
        private const val KEY_VERIFIED_MODIFIED = "verified_modified"
    }
}

internal object ModelDownloadScheduler {
    const val UNIQUE_WORK_NAME = "medgemma-model-unsloth-1fe03a29-q4-k-m"
    const val WORK_TAG = "medgemma-model-download"
    const val KEY_STATE = "download_state"
    const val KEY_DOWNLOADED = "downloaded_bytes"
    const val KEY_TOTAL = "total_bytes"
    const val KEY_DETAIL = "detail"
    const val KEY_RETRYABLE = "retryable"

    internal fun request() = OneTimeWorkRequestBuilder<ModelDownloadWorker>()
        .setConstraints(
            Constraints.Builder()
                .setRequiredNetworkType(NetworkType.UNMETERED)
                .setRequiresBatteryNotLow(true)
                .setRequiresStorageNotLow(true)
                .build(),
        )
        .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
        .addTag(WORK_TAG)
        .build()

    fun enqueue(context: Context, policy: ExistingWorkPolicy) {
        WorkManager.getInstance(context).enqueueUniqueWork(UNIQUE_WORK_NAME, policy, request())
    }
}
