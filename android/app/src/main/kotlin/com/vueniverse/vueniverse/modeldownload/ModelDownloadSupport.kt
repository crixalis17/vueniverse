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
        ModelArtifactManager.selectedArtifact,
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
            ModelArtifactManager.selectedArtifact,
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
            ModelArtifactManager.selectedArtifact,
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
    val UNIQUE_WORK_NAME: String
        get() = ModelArtifactManager.downloadWorkName(ModelArtifactManager.selectedArtifact)
    const val WORK_TAG = "medgemma-model-download"
    const val KEY_STATE = "download_state"
    const val KEY_DOWNLOADED = "downloaded_bytes"
    const val KEY_TOTAL = "total_bytes"
    const val KEY_DETAIL = "detail"
    const val KEY_RETRYABLE = "retryable"

    fun artifactTag(revision: String): String = "medgemma-artifact:$revision"

    fun shouldCancelObsoleteDownload(tags: Set<String>, finished: Boolean, selectedRevision: String): Boolean =
        !finished && WORK_TAG in tags && artifactTag(selectedRevision) !in tags

    fun cancelObsoleteDownloads(context: Context) {
        val manager = WorkManager.getInstance(context)
        val revision = ModelArtifactManager.selectedArtifact.modelRevision
        manager.getWorkInfosByTag(WORK_TAG).get().filter {
            shouldCancelObsoleteDownload(it.tags, it.state.isFinished, revision)
        }.forEach {
            // Cancel only this module's obsolete transfers. Partial files and
            // previously verified model/data files remain untouched.
            manager.cancelWorkById(it.id).result.get()
        }
    }

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
        .addTag(artifactTag(ModelArtifactManager.selectedArtifact.modelRevision))
        .build()

    fun enqueue(context: Context, policy: ExistingWorkPolicy) {
        WorkManager.getInstance(context).enqueueUniqueWork(UNIQUE_WORK_NAME, policy, request())
    }
}
