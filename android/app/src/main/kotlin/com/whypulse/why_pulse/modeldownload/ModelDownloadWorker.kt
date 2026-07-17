package com.whypulse.why_pulse.modeldownload

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.StatFs
import androidx.core.app.NotificationCompat
import androidx.work.CoroutineWorker
import androidx.work.ForegroundInfo
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import com.whypulse.why_pulse.medgemma.ArtifactValidationResult
import com.whypulse.why_pulse.medgemma.ExpectedModelArtifact
import com.whypulse.why_pulse.medgemma.ModelArtifactLocator
import com.whypulse.why_pulse.medgemma.ModelArtifactManager
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

class ModelDownloadWorker(
    appContext: Context,
    parameters: WorkerParameters,
) : CoroutineWorker(appContext, parameters) {
    private val environment = testEnvironmentFactory?.invoke(appContext)
    private val artifact = environment?.artifact ?: ModelArtifactManager.MEDGEMMA_1_5_Q4_K_M
    private val config = environment?.config ?: ModelDownloadConfig.fromBuild()
    private val files = ModelDownloadFiles(appContext, artifact)
    private val store = ModelDownloadStore(appContext)
    private val manager = ModelArtifactManager(ModelArtifactLocator(appContext.filesDir))

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        if (!config.isValid) {
            return@withContext failure(
                if (config.isConfigured) "invalid_url" else "configuration_missing",
                false,
            )
        }
        files.directory.mkdirs()
        when (val existing = manager.validate(artifact)) {
            is ArtifactValidationResult.Valid -> {
                store.markVerified(existing.file, artifact)
                return@withContext Result.success()
            }
            is ArtifactValidationResult.Missing -> Unit
            else -> {
                store.clearVerifiedMarker()
                files.finalFile.delete()
            }
        }

        return@withContext try {
            setForeground(foregroundInfo(files.partialFile.length(), "Preparing download"))
            when (val transfer = download()) {
                TransferResult.Complete -> verifyAndPromote()
                is TransferResult.Retry -> {
                    publishProgress(files.partialFile.length(), ModelDownloadState.QUEUED, transfer.detail)
                    Result.retry()
                }
                is TransferResult.Failure -> failure(transfer.detail, transfer.retryable)
            }
        } catch (cancelled: CancellationException) {
            preservePartialMetadata()
            throw cancelled
        } catch (error: IOException) {
            publishProgress(files.partialFile.length(), ModelDownloadState.QUEUED, "network_retry")
            Result.retry()
        } catch (error: SecurityException) {
            failure("storage_unavailable", true)
        }
    }

    private suspend fun download(): TransferResult {
        normalizePartialState()
        var restartAllowed = true
        while (true) {
            currentCoroutineContext().ensureActive()
            val offset = files.partialFile.length()
            val remaining = (artifact.sizeBytes - offset).coerceAtLeast(0)
            val available = StatFs(files.directory.absolutePath).availableBytes
            if (!ModelDownloadProtocol.hasRequiredStorage(available, remaining, config.reserveBytes)) {
                return TransferResult.Failure("insufficient_storage", true)
            }
            if (offset == artifact.sizeBytes) return TransferResult.Complete

            val metadata = PartialMetadata.read(files.metadataFile)
            val connection = openFollowingRedirects(offset, metadata?.etag)
                ?: return TransferResult.Failure("redirect_invalid", false)
            try {
                val code = connection.responseCode
                val responseEtag = connection.getHeaderField("ETag")
                val decision = ModelDownloadProtocol.evaluate(
                    statusCode = code,
                    offset = offset,
                    expectedSize = artifact.sizeBytes,
                    storedEtag = metadata?.etag,
                    responseEtag = responseEtag,
                    contentRangeHeader = connection.getHeaderField("Content-Range"),
                    contentLength = connection.contentLengthLong,
                )
                when (decision) {
                    DownloadResponseDecision.Complete -> return TransferResult.Complete
                    is DownloadResponseDecision.Retry -> return TransferResult.Retry(decision.detail)
                    is DownloadResponseDecision.Failure -> {
                        return TransferResult.Failure(decision.detail, decision.retryable)
                    }
                    is DownloadResponseDecision.Restart -> {
                        if (!restartAllowed) {
                            return TransferResult.Failure(decision.detail, true)
                        }
                        clearPartial()
                        restartAllowed = false
                        continue
                    }
                    is DownloadResponseDecision.Transfer -> Unit
                }

                val append = decision.append
                val etag = responseEtag!!
                val start = if (append) offset else 0L
                PartialMetadata(config.url, etag, artifact.modelRevision, start)
                    .write(files.metadataFile)
                streamResponse(connection, append, start, etag)
                val downloadedLength = files.partialFile.length()
                return if (downloadedLength == artifact.sizeBytes) {
                    TransferResult.Complete
                } else if (downloadedLength > artifact.sizeBytes) {
                    clearPartial()
                    TransferResult.Failure("size_mismatch", false)
                } else {
                    TransferResult.Retry("download_incomplete")
                }
            } finally {
                connection.disconnect()
            }
        }
    }

    private suspend fun streamResponse(
        connection: HttpURLConnection,
        append: Boolean,
        start: Long,
        etag: String,
    ) {
        var downloaded = start
        var lastReportedAt = 0L
        connection.inputStream.use { input ->
            FileOutputStream(files.partialFile, append).use { output ->
                val buffer = ByteArray(1_048_576)
                while (true) {
                    currentCoroutineContext().ensureActive()
                    val count = input.read(buffer)
                    if (count < 0) break
                    if (count == 0) continue
                    output.write(buffer, 0, count)
                    downloaded += count
                    val now = System.currentTimeMillis()
                    if (now - lastReportedAt >= 1_000L) {
                        PartialMetadata(config.url, etag, artifact.modelRevision, downloaded)
                            .write(files.metadataFile)
                        publishProgress(downloaded, ModelDownloadState.DOWNLOADING, null)
                        lastReportedAt = now
                    }
                }
                output.fd.sync()
            }
        }
        PartialMetadata(config.url, etag, artifact.modelRevision, downloaded)
            .write(files.metadataFile)
    }

    private fun preservePartialMetadata() {
        val existing = PartialMetadata.read(files.metadataFile) ?: return
        if (!files.partialFile.exists() ||
            existing.url != config.url ||
            existing.revision != artifact.modelRevision
        ) {
            return
        }
        existing.copy(downloadedBytes = files.partialFile.length()).write(files.metadataFile)
    }

    private suspend fun verifyAndPromote(): Result {
        publishProgress(artifact.sizeBytes, ModelDownloadState.VERIFYING, null)
        return when (manager.validateFile(files.partialFile, artifact)) {
            is ArtifactValidationResult.Valid -> {
                ModelFilePromotion.promote(files.partialFile, files.finalFile)
                files.metadataFile.delete()
                store.markVerified(files.finalFile, artifact)
                store.cancelled = false
                Result.success()
            }
            else -> {
                files.partialFile.delete()
                files.metadataFile.delete()
                val failures = store.integrityFailures + 1
                store.integrityFailures = failures
                if (failures <= 1) Result.retry() else failure("integrity_check_failed", true)
            }
        }
    }

    private fun normalizePartialState() {
        val metadata = PartialMetadata.read(files.metadataFile)
        val invalid = !PartialMetadata.isConsistent(
            metadata = metadata,
            partialLength = files.partialFile.length(),
            expectedUrl = config.url,
            expectedRevision = artifact.modelRevision,
            expectedSize = artifact.sizeBytes,
        )
        if (files.partialFile.exists() && invalid) clearPartial()
        if (!files.partialFile.exists()) files.metadataFile.delete()
    }

    private fun clearPartial() {
        files.partialFile.delete()
        files.metadataFile.delete()
    }

    private fun openFollowingRedirects(offset: Long, etag: String?): HttpURLConnection? {
        var current = URL(config.url)
        repeat(6) {
            if (!ModelDownloadProtocol.isAllowedUrl(current, config.allowHttpForTests)) return null
            val connection = current.openConnection() as HttpURLConnection
            connection.instanceFollowRedirects = false
            connection.connectTimeout = 30_000
            connection.readTimeout = 60_000
            connection.requestMethod = "GET"
            connection.setRequestProperty("Accept-Encoding", "identity")
            if (offset > 0) {
                connection.setRequestProperty("Range", "bytes=$offset-")
                if (!etag.isNullOrBlank()) connection.setRequestProperty("If-Range", etag)
            }
            val code = connection.responseCode
            if (code !in 300..399) return connection
            val location = connection.getHeaderField("Location") ?: return null
            val next = URL(current, location)
            connection.disconnect()
            if (!ModelDownloadProtocol.isAllowedUrl(next, config.allowHttpForTests)) return null
            current = next
        }
        return null
    }

    private suspend fun publishProgress(
        downloaded: Long,
        state: ModelDownloadState,
        detail: String?,
    ) {
        val data = workDataOf(
            ModelDownloadScheduler.KEY_STATE to state.name,
            ModelDownloadScheduler.KEY_DOWNLOADED to downloaded,
            ModelDownloadScheduler.KEY_TOTAL to artifact.sizeBytes,
            ModelDownloadScheduler.KEY_DETAIL to detail,
        )
        setProgress(data)
        setForeground(foregroundInfo(downloaded, notificationText(state, downloaded)))
    }

    private fun failure(detail: String, retryable: Boolean): Result = Result.failure(
        workDataOf(
            ModelDownloadScheduler.KEY_DOWNLOADED to files.partialFile.length(),
            ModelDownloadScheduler.KEY_TOTAL to artifact.sizeBytes,
            ModelDownloadScheduler.KEY_DETAIL to detail,
            ModelDownloadScheduler.KEY_RETRYABLE to retryable,
        ),
    )

    private fun foregroundInfo(downloaded: Long, text: String): ForegroundInfo {
        val manager = applicationContext.getSystemService(Service.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    NOTIFICATION_CHANNEL,
                    "On-device AI model",
                    NotificationManager.IMPORTANCE_LOW,
                ),
            )
        }
        val progress = ((downloaded.toDouble() / artifact.sizeBytes) * 100).toInt().coerceIn(0, 100)
        val cancel = WorkManager.getInstance(applicationContext).createCancelPendingIntent(id)
        val notification = NotificationCompat.Builder(applicationContext, NOTIFICATION_CHANNEL)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle("Preparing WhyPulse on-device AI")
            .setContentText(text)
            .setOnlyAlertOnce(true)
            .setOngoing(true)
            .setProgress(100, progress, false)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Cancel", cancel)
            .build()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ForegroundInfo(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            ForegroundInfo(NOTIFICATION_ID, notification)
        }
    }

    private fun notificationText(state: ModelDownloadState, downloaded: Long): String = when (state) {
        ModelDownloadState.VERIFYING -> "Verifying model integrity"
        else -> "${downloaded / (1_024L * 1_024L)} MB of ${artifact.sizeBytes / (1_024L * 1_024L)} MB"
    }

    private sealed interface TransferResult {
        data object Complete : TransferResult
        data class Retry(val detail: String) : TransferResult
        data class Failure(val detail: String, val retryable: Boolean) : TransferResult
    }

    companion object {
        @Volatile
        internal var testEnvironmentFactory: ((Context) -> ModelDownloadWorkerEnvironment)? = null

        private const val NOTIFICATION_CHANNEL = "medgemma_model_download"
        private const val NOTIFICATION_ID = 6204
    }
}

internal data class ModelDownloadWorkerEnvironment(
    val artifact: ExpectedModelArtifact,
    val config: ModelDownloadConfig,
)
