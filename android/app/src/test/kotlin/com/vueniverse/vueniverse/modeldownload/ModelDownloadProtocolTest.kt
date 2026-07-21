package com.vueniverse.vueniverse.modeldownload

import androidx.work.NetworkType
import com.vueniverse.vueniverse.medgemma.ModelArtifactManager
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import java.net.URL
import java.nio.file.Files
import java.time.Instant

class ModelDownloadProtocolTest {
    private val size = 1_024L

    @Test
    fun canonicalArtifactContractMatchesHostedFile() {
        val artifact = ModelArtifactManager.MEDGEMMA_1_5_Q4_K_M

        assertEquals("unsloth/medgemma-1.5-4b-it-GGUF", artifact.modelId)
        assertEquals("1fe03a2916e0a4ed250fdeedc3e56a94f3bf2a30", artifact.modelRevision)
        assertEquals("medgemma-1.5-4b-it-Q4_K_M.gguf", artifact.fileName)
        assertEquals(2_489_894_144L, artifact.sizeBytes)
        assertEquals(
            "9f3480a68099ab445cc5224aebfc00f0e3c471cacc4a1b8a36a98631e79e0a63",
            artifact.sha256,
        )
        assertFalse(artifact.verifyChecksum)
    }

    @Test
    fun downloadConfigurationRequiresHttpsHost() {
        assertFalse(ModelDownloadConfig("").isValid)
        assertFalse(ModelDownloadConfig("http://example.test/model.gguf").isValid)
        assertFalse(ModelDownloadConfig("https:///model.gguf").isValid)
        assertTrue(ModelDownloadConfig("https://example.test/model.gguf").isValid)
    }

    @Test
    fun schedulingUsesUniqueUnmeteredBatteryAndStorageConstraints() {
        val request = ModelDownloadScheduler.request()
        val constraints = request.workSpec.constraints

        assertEquals(NetworkType.UNMETERED, constraints.requiredNetworkType)
        assertTrue(constraints.requiresBatteryNotLow())
        assertTrue(constraints.requiresStorageNotLow())
        assertFalse(constraints.requiresCharging())
        assertTrue(request.tags.contains(ModelDownloadScheduler.WORK_TAG))
        assertEquals(30_000L, request.workSpec.backoffDelayDuration)
    }

    @Test
    fun validRangeResponseAppendsAtExpectedOffset() {
        val decision = evaluate(
            code = 206,
            offset = 256,
            etag = "v1",
            range = "bytes 256-1023/1024",
            length = 768,
        )

        assertEquals(DownloadResponseDecision.Transfer(append = true), decision)
    }

    @Test
    fun fullResponseAfterRangeRequestRestartsFromZero() {
        val decision = evaluate(
            code = 200,
            offset = 256,
            etag = "v2",
            length = size,
        )

        assertEquals(DownloadResponseDecision.Transfer(append = false), decision)
    }

    @Test
    fun etagOrRangeDriftRestartsCleanly() {
        assertEquals(
            DownloadResponseDecision.Restart("etag_changed"),
            evaluate(
                code = 206,
                offset = 256,
                storedEtag = "v1",
                etag = "v2",
                range = "bytes 256-1023/1024",
                length = 768,
            ),
        )
        assertEquals(
            DownloadResponseDecision.Restart("range_mismatch"),
            evaluate(
                code = 206,
                offset = 256,
                etag = "v1",
                range = "bytes 128-1023/1024",
                length = 896,
            ),
        )
        assertEquals(
            DownloadResponseDecision.Transfer(append = true),
            evaluate(
                code = 206,
                offset = 256,
                etag = "v1",
                range = "bytes 256-1023/1024",
                length = 700,
            ),
        )
    }

    @Test
    fun rangeNotSatisfiableCompletesOnlyAtExactSize() {
        assertEquals(
            DownloadResponseDecision.Complete,
            evaluate(code = 416, offset = size, etag = null),
        )
        assertEquals(
            DownloadResponseDecision.Restart("range_rejected"),
            evaluate(code = 416, offset = 512, etag = null),
        )
    }

    @Test
    fun transientAndPermanentHttpErrorsAreSeparated() {
        for (code in listOf(408, 429, 500, 503)) {
            assertEquals(
                DownloadResponseDecision.Retry("http_$code"),
                evaluate(code = code, offset = 0, etag = null),
            )
        }
        assertEquals(
            DownloadResponseDecision.Failure("unauthorized", false),
            evaluate(code = 401, offset = 0, etag = null),
        )
        assertEquals(
            DownloadResponseDecision.Failure("forbidden", false),
            evaluate(code = 403, offset = 0, etag = null),
        )
        assertEquals(
            DownloadResponseDecision.Failure("not_found", false),
            evaluate(code = 404, offset = 0, etag = null),
        )
    }

    @Test
    fun missingEtagFailsButContentLengthDoesNotBlockTransfer() {
        assertEquals(
            DownloadResponseDecision.Failure("etag_missing", false),
            evaluate(code = 200, offset = 0, etag = null, length = size),
        )
        assertEquals(
            DownloadResponseDecision.Transfer(append = false),
            evaluate(code = 200, offset = 0, etag = "v1", length = size - 1),
        )
    }

    @Test
    fun storageIncludesRemainingBytesAndSafetyReserve() {
        val reserve = 512L
        assertFalse(ModelDownloadProtocol.hasRequiredStorage(1_023, 512, reserve))
        assertTrue(ModelDownloadProtocol.hasRequiredStorage(1_024, 512, reserve))
    }

    @Test
    fun redirectsMustRemainHttps() {
        assertTrue(ModelDownloadProtocol.isAllowedUrl(URL("https://cdn.example/model.gguf")))
        assertFalse(ModelDownloadProtocol.isAllowedUrl(URL("http://cdn.example/model.gguf")))
        assertTrue(
            ModelDownloadProtocol.isAllowedUrl(
                URL("http://127.0.0.1/model.gguf"),
                allowHttpForTests = true,
            ),
        )
    }

    @Test
    fun sidecarRecoveryRejectsProcessInterruptedMetadataMismatch() {
        val root = Files.createTempDirectory("model-sidecar-test").toFile()
        try {
            val sidecar = File(root, "model.part.json")
            val metadata = PartialMetadata("v1", "revision", 512)
            metadata.write(sidecar)

            assertEquals(metadata, PartialMetadata.read(sidecar))
            assertTrue(
                PartialMetadata.isConsistent(metadata, 512, metadata.revision, size),
            )
            assertFalse(
                PartialMetadata.isConsistent(metadata, 768, metadata.revision, size),
            )
            assertFalse(
                PartialMetadata.isConsistent(
                    metadata.copy(etag = null),
                    512,
                    metadata.revision,
                    size,
                ),
            )
        } finally {
            root.deleteRecursively()
        }
    }

    @Test
    fun legacySidecarDoesNotPersistOrPinRotatingSignedUrl() {
        val root = Files.createTempDirectory("model-legacy-sidecar-test").toFile()
        try {
            val sidecar = File(root, "model.part.json")
            sidecar.writeText(
                """{"url":"https://old.example/signed","etag":"v1","revision":"revision","downloadedBytes":512}""",
            )

            val metadata = PartialMetadata.read(sidecar)

            assertEquals(PartialMetadata("v1", "revision", 512), metadata)
            metadata!!.write(sidecar)
            assertFalse(sidecar.readText().contains("old.example"))
            assertTrue(PartialMetadata.isConsistent(metadata, 512, "revision", size))
        } finally {
            root.deleteRecursively()
        }
    }

    @Test
    fun remoteConfigAcceptsOnlyThePinnedGcsObjectAndValidExpiry() {
        val fallback = ModelDownloadConfig("https://fallback.example/model.gguf")
        val signedUrl =
            "https://storage.googleapis.com/mvp_mobile_app/models/medgemma/" +
                "medgemma-1.5-4b-it-Q4_K_M.gguf?X-Goog-Signature=test"
        val virtualHostSignedUrl =
            "https://mvp_mobile_app.storage.googleapis.com/models/medgemma/" +
                "medgemma-1.5-4b-it-Q4_K_M.gguf?x-goog-signature=test"
        val now = Instant.parse("2026-07-21T00:00:00Z")

        assertEquals(
            signedUrl,
            ModelDownloadRemoteUrlPolicy.select(
                remoteUrl = signedUrl,
                expiresAt = "2026-07-21T01:00:00Z",
                fallback = fallback,
                now = now,
            ).url,
        )
        assertEquals(
            fallback,
            ModelDownloadRemoteUrlPolicy.select(
                remoteUrl = virtualHostSignedUrl,
                expiresAt = "2026-07-21T01:00:00Z",
                fallback = fallback,
                now = now,
            ),
        )
        assertEquals(
            fallback,
            ModelDownloadRemoteUrlPolicy.select(
                remoteUrl = signedUrl,
                expiresAt = "2026-07-20T23:59:59Z",
                fallback = fallback,
                now = now,
            ),
        )
        assertEquals(
            fallback,
            ModelDownloadRemoteUrlPolicy.select(
                remoteUrl = "https://evil.example/model.gguf",
                expiresAt = "",
                fallback = fallback,
                now = now,
            ),
        )
        assertEquals(
            fallback,
            ModelDownloadRemoteUrlPolicy.select(
                remoteUrl = signedUrl.replace("Q4_K_M", "Q8_0"),
                expiresAt = "",
                fallback = fallback,
                now = now,
            ),
        )
    }

    @Test
    fun verifiedPartialIsPromotedWithoutLeavingPartFile() {
        val root = Files.createTempDirectory("model-promotion-test").toFile()
        try {
            val partial = File(root, "model.gguf.part").apply { writeText("verified") }
            val destination = File(root, "models/model.gguf")

            ModelFilePromotion.promote(partial, destination)

            assertFalse(partial.exists())
            assertEquals("verified", destination.readText())
        } finally {
            root.deleteRecursively()
        }
    }

    private fun evaluate(
        code: Int,
        offset: Long,
        storedEtag: String? = "v1",
        etag: String?,
        range: String? = null,
        length: Long = -1,
    ): DownloadResponseDecision = ModelDownloadProtocol.evaluate(
        statusCode = code,
        offset = offset,
        expectedSize = size,
        storedEtag = storedEtag,
        responseEtag = etag,
        contentRangeHeader = range,
    )
}
