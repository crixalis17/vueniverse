package com.whypulse.why_pulse.modeldownload

import android.content.Context
import androidx.work.ExistingWorkPolicy
import androidx.work.WorkInfo
import androidx.work.WorkManager
import com.whypulse.why_pulse.medgemma.ArtifactValidationResult
import com.whypulse.why_pulse.medgemma.ModelArtifactLocator
import com.whypulse.why_pulse.medgemma.ModelArtifactManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class ModelDownloadApiImpl(context: Context) : ModelDownloadApi {
    private val appContext = context.applicationContext
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val workManager = WorkManager.getInstance(appContext)
    private val store = ModelDownloadStore(appContext)
    private val files = ModelDownloadFiles(appContext)
    private val config = ModelDownloadConfig.fromBuild()
    private val artifact = ModelArtifactManager.MEDGEMMA_1_5_Q4_K_M
    private val artifactManager = ModelArtifactManager(ModelArtifactLocator(appContext.filesDir))

    override fun inspectDownload(callback: (Result<ModelDownloadStatus>) -> Unit) = respond(callback) {
        inspect()
    }

    override fun acceptAndStart(callback: (Result<ModelDownloadStatus>) -> Unit) = respond(callback) {
        availableStatus()?.let { return@respond it }
        configurationFailure()?.let { return@respond it }
        store.consented = true
        store.cancelled = false
        ModelDownloadScheduler.enqueue(appContext, ExistingWorkPolicy.KEEP)
        status(ModelDownloadState.QUEUED, downloaded = files.partialFile.length(), detail = "waiting_for_unmetered_network")
    }

    override fun ensureScheduled(callback: (Result<ModelDownloadStatus>) -> Unit) = respond(callback) {
        availableStatus()?.let { return@respond it }
        configurationFailure()?.let { return@respond it }
        if (!store.consented) return@respond status(ModelDownloadState.REQUIRES_CONSENT)
        val current = currentWorkInfo()
        if (current?.state == WorkInfo.State.FAILED) return@respond mapWorkInfo(current)
        store.cancelled = false
        ModelDownloadScheduler.enqueue(appContext, ExistingWorkPolicy.KEEP)
        current?.let { mapWorkInfo(it) }
            ?: status(ModelDownloadState.QUEUED, downloaded = files.partialFile.length(), detail = "waiting_for_unmetered_network")
    }

    override fun retryDownload(callback: (Result<ModelDownloadStatus>) -> Unit) = respond(callback) {
        store.consented = true
        store.cancelled = false
        store.integrityFailures = 0
        configurationFailure()?.let { return@respond it }
        ModelDownloadScheduler.enqueue(appContext, ExistingWorkPolicy.REPLACE)
        status(ModelDownloadState.QUEUED, downloaded = files.partialFile.length(), detail = "waiting_for_unmetered_network")
    }

    override fun cancelDownload(callback: (Result<ModelDownloadStatus>) -> Unit) = respond(callback) {
        availableStatus()?.let { return@respond it }
        store.cancelled = true
        workManager.cancelUniqueWork(ModelDownloadScheduler.UNIQUE_WORK_NAME).result.get()
        status(ModelDownloadState.CANCELLED, downloaded = files.partialFile.length(), detail = "download_cancelled", retryable = true)
    }

    fun dispose() {
        scope.cancel()
    }

    private fun respond(
        callback: (Result<ModelDownloadStatus>) -> Unit,
        block: () -> ModelDownloadStatus,
    ) {
        scope.launch {
            callback(runCatching(block))
        }
    }

    private fun inspect(): ModelDownloadStatus {
        availableStatus()?.let { return it }
        configurationFailure()?.let { return it }
        if (!store.consented) return status(ModelDownloadState.REQUIRES_CONSENT)
        if (store.cancelled) {
            return status(
                ModelDownloadState.CANCELLED,
                downloaded = files.partialFile.length(),
                detail = "download_cancelled",
                retryable = true,
            )
        }
        return currentWorkInfo()?.let(::mapWorkInfo)
            ?: status(ModelDownloadState.CANCELLED, downloaded = files.partialFile.length(), detail = "not_scheduled", retryable = true)
    }

    private fun availableStatus(): ModelDownloadStatus? {
        if (store.isVerifiedMarkerCurrent(files.finalFile)) {
            return status(ModelDownloadState.AVAILABLE, downloaded = artifact.sizeBytes)
        }
        return when (val validation = artifactManager.validate(artifact)) {
            is ArtifactValidationResult.Valid -> {
                store.markVerified(validation.file)
                status(ModelDownloadState.AVAILABLE, downloaded = artifact.sizeBytes)
            }
            else -> null
        }
    }

    private fun currentWorkInfo(): WorkInfo? {
        val infos = workManager.getWorkInfosForUniqueWork(ModelDownloadScheduler.UNIQUE_WORK_NAME).get()
        return infos.firstOrNull { !it.state.isFinished } ?: infos.lastOrNull()
    }

    private fun configurationFailure(): ModelDownloadStatus? {
        if (config.isValid) return null
        return if (config.isConfigured) {
            status(
                ModelDownloadState.FAILED,
                detail = "invalid_url",
                retryable = false,
            )
        } else {
            status(
                ModelDownloadState.NOT_CONFIGURED,
                detail = "configuration_missing",
                retryable = false,
            )
        }
    }

    private fun mapWorkInfo(info: WorkInfo): ModelDownloadStatus {
        val data = if (info.state == WorkInfo.State.FAILED) info.outputData else info.progress
        val downloaded = data.getLong(ModelDownloadScheduler.KEY_DOWNLOADED, files.partialFile.length())
        val detail = data.getString(ModelDownloadScheduler.KEY_DETAIL)
        return when (info.state) {
            WorkInfo.State.ENQUEUED, WorkInfo.State.BLOCKED ->
                status(ModelDownloadState.QUEUED, downloaded, detail ?: "waiting_for_unmetered_network")
            WorkInfo.State.RUNNING -> {
                val state = data.getString(ModelDownloadScheduler.KEY_STATE)
                status(
                    if (state == ModelDownloadState.VERIFYING.name) ModelDownloadState.VERIFYING else ModelDownloadState.DOWNLOADING,
                    downloaded,
                    detail,
                )
            }
            WorkInfo.State.SUCCEEDED ->
                availableStatus() ?: status(ModelDownloadState.FAILED, downloaded, "promotion_missing", true)
            WorkInfo.State.FAILED -> status(
                ModelDownloadState.FAILED,
                downloaded,
                detail ?: "download_failed",
                data.getBoolean(ModelDownloadScheduler.KEY_RETRYABLE, true),
            )
            WorkInfo.State.CANCELLED -> status(
                ModelDownloadState.CANCELLED,
                downloaded,
                detail ?: "download_cancelled",
                true,
            )
        }
    }

    private fun status(
        state: ModelDownloadState,
        downloaded: Long = 0,
        detail: String? = null,
        retryable: Boolean = state == ModelDownloadState.FAILED || state == ModelDownloadState.CANCELLED,
    ): ModelDownloadStatus {
        val safeDownloaded = downloaded.coerceIn(0, artifact.sizeBytes)
        return ModelDownloadStatus(
            state = state,
            downloadedBytes = safeDownloaded,
            totalBytes = artifact.sizeBytes,
            progress = safeDownloaded.toDouble() / artifact.sizeBytes.toDouble() * 100.0,
            retryable = retryable,
            detail = detail,
        )
    }
}
