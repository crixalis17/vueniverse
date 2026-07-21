package com.vueniverse.vueniverse.modeldownload

import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.net.URL
import java.nio.file.Files
import java.nio.file.StandardCopyOption

internal sealed interface DownloadResponseDecision {
    data class Transfer(val append: Boolean) : DownloadResponseDecision
    data object Complete : DownloadResponseDecision
    data class Restart(val detail: String) : DownloadResponseDecision
    data class Retry(val detail: String) : DownloadResponseDecision
    data class Failure(val detail: String, val retryable: Boolean) : DownloadResponseDecision
}

internal object ModelDownloadProtocol {
    private const val HTTP_OK = 200
    private const val HTTP_PARTIAL = 206
    private const val HTTP_RANGE_NOT_SATISFIABLE = 416
    private val contentRange = Regex("bytes (\\d+)-(\\d+)/(\\d+)")

    fun evaluate(
        statusCode: Int,
        offset: Long,
        expectedSize: Long,
        storedEtag: String?,
        responseEtag: String?,
        contentRangeHeader: String?,
    ): DownloadResponseDecision {
        if (statusCode == HTTP_RANGE_NOT_SATISFIABLE) {
            return if (offset == expectedSize) {
                DownloadResponseDecision.Complete
            } else {
                DownloadResponseDecision.Restart("range_rejected")
            }
        }
        if (statusCode == 408 || statusCode == 429 || statusCode >= 500) {
            return DownloadResponseDecision.Retry("http_$statusCode")
        }
        if (statusCode != HTTP_OK && statusCode != HTTP_PARTIAL) {
            val detail = when (statusCode) {
                401 -> "unauthorized"
                403 -> "forbidden"
                404 -> "not_found"
                else -> "http_$statusCode"
            }
            return DownloadResponseDecision.Failure(
                detail,
                retryable = statusCode !in listOf(401, 403, 404),
            )
        }
        if (responseEtag.isNullOrBlank()) {
            return DownloadResponseDecision.Failure("etag_missing", false)
        }
        if (statusCode == HTTP_OK) {
            return DownloadResponseDecision.Transfer(append = false)
        }

        val range = parseContentRange(contentRangeHeader)
            ?: return DownloadResponseDecision.Restart("range_mismatch")
        if (range.start != offset ||
            range.total != expectedSize ||
            range.end < range.start ||
            range.end >= range.total
        ) {
            return DownloadResponseDecision.Restart("range_mismatch")
        }
        if (storedEtag != null && storedEtag != responseEtag) {
            return DownloadResponseDecision.Restart("etag_changed")
        }
        return DownloadResponseDecision.Transfer(append = offset > 0)
    }

    fun hasRequiredStorage(available: Long, remaining: Long, reserve: Long): Boolean =
        available >= remaining + reserve

    fun isAllowedUrl(url: URL, allowHttpForTests: Boolean = false): Boolean =
        (url.protocol.equals("https", ignoreCase = true) ||
            (allowHttpForTests && url.protocol.equals("http", ignoreCase = true))) &&
            url.host.isNotBlank()

    private fun parseContentRange(value: String?): ParsedContentRange? {
        val match = contentRange.matchEntire(value.orEmpty()) ?: return null
        return ParsedContentRange(
            start = match.groupValues[1].toLongOrNull() ?: return null,
            end = match.groupValues[2].toLongOrNull() ?: return null,
            total = match.groupValues[3].toLongOrNull() ?: return null,
        )
    }

    private data class ParsedContentRange(
        val start: Long,
        val end: Long,
        val total: Long,
    )
}

internal data class PartialMetadata(
    val etag: String?,
    val revision: String,
    val downloadedBytes: Long,
) {
    fun write(file: File) {
        file.parentFile?.mkdirs()
        val temporary = File(file.parentFile, "${file.name}.tmp")
        temporary.writeText(
            JSONObject()
                .put("etag", etag)
                .put("revision", revision)
                .put("downloadedBytes", downloadedBytes)
                .toString(),
        )
        try {
            Files.move(
                temporary.toPath(),
                file.toPath(),
                StandardCopyOption.ATOMIC_MOVE,
                StandardCopyOption.REPLACE_EXISTING,
            )
        } catch (_: IOException) {
            Files.move(
                temporary.toPath(),
                file.toPath(),
                StandardCopyOption.REPLACE_EXISTING,
            )
        }
    }

    companion object {
        fun read(file: File): PartialMetadata? = runCatching {
            val json = JSONObject(file.readText())
            PartialMetadata(
                etag = json.optString("etag").takeIf { it.isNotBlank() && it != "null" },
                revision = json.getString("revision"),
                downloadedBytes = json.getLong("downloadedBytes"),
            )
        }.getOrNull()

        fun isConsistent(
            metadata: PartialMetadata?,
            partialLength: Long,
            expectedRevision: String,
            expectedSize: Long,
        ): Boolean = metadata != null &&
            partialLength in 0..expectedSize &&
            metadata.revision == expectedRevision &&
            !metadata.etag.isNullOrBlank() &&
            metadata.downloadedBytes == partialLength
    }
}

internal object ModelFilePromotion {
    fun promote(partial: File, destination: File) {
        destination.parentFile?.mkdirs()
        try {
            Files.move(
                partial.toPath(),
                destination.toPath(),
                StandardCopyOption.ATOMIC_MOVE,
                StandardCopyOption.REPLACE_EXISTING,
            )
        } catch (_: IOException) {
            Files.move(
                partial.toPath(),
                destination.toPath(),
                StandardCopyOption.REPLACE_EXISTING,
            )
        }
    }
}
