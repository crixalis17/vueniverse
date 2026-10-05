package com.vueniverse.vueniverse.medgemma

import java.io.File
import java.nio.file.Files
import java.security.MessageDigest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class ModelArtifactManagerTest {
    private lateinit var root: File
    private lateinit var locator: ModelArtifactLocator
    private lateinit var manager: ModelArtifactManager

    @Before
    fun setUp() {
        root = Files.createTempDirectory("medgemma-artifact-test").toFile()
        locator = ModelArtifactLocator(root)
        manager = ModelArtifactManager(locator, bufferSizeBytes = 4_096)
    }

    @After
    fun tearDown() {
        root.deleteRecursively()
    }

    @Test
    fun validArtifactPassesWithoutLoadingModel() {
        val bytes = "fictional-gguf".toByteArray()
        val artifact = artifactFor(bytes)
        val file = locator.locate(artifact)
        file.parentFile!!.mkdirs()
        file.writeBytes(bytes)

        val result = manager.validate(artifact)

        assertTrue(result is ArtifactValidationResult.Valid)
        assertEquals(file.canonicalFile, (result as ArtifactValidationResult.Valid).file.canonicalFile)
    }

    @Test
    fun missingArtifactFailsDeterministically() {
        val result = manager.validate(artifactFor("missing".toByteArray()))

        assertTrue(result is ArtifactValidationResult.Missing)
    }

    @Test
    fun sizeMismatchIsReportedBeforeChecksum() {
        val artifact = artifactFor("expected".toByteArray())
        val file = locator.locate(artifact)
        file.parentFile!!.mkdirs()
        file.writeText("short")

        val result = manager.validate(artifact)

        assertTrue(result is ArtifactValidationResult.SizeMismatch)
        assertEquals(5, (result as ArtifactValidationResult.SizeMismatch).actualBytes)
    }

    @Test
    fun checksumMismatchIsReported() {
        val expected = "expected".toByteArray()
        val actual = "different".toByteArray()
        val artifact = artifactFor(expected).copy(sizeBytes = actual.size.toLong())
        val file = locator.locate(artifact)
        file.parentFile!!.mkdirs()
        file.writeBytes(actual)

        val result = manager.validate(artifact)

        assertTrue(result is ArtifactValidationResult.ChecksumMismatch)
        assertEquals(sha256(actual), (result as ArtifactValidationResult.ChecksumMismatch).actualSha256)
    }

    @Test(expected = IllegalArgumentException::class)
    fun artifactFilenameCannotEscapePrivateDirectory() {
        ExpectedModelArtifact(
            modelId = "test",
            modelRevision = "test",
            quantization = "Q4_K_M",
            fileName = "../model.gguf",
            sizeBytes = 1,
            sha256 = "0".repeat(64),
        )
    }

    @Test
    fun retainedLoraCandidateHasSeparateIdentityAndDoesNotReplaceVanilla() {
        val candidate = ModelArtifactManager.MEDGEMMA_1_5_LORA_V7_Q4_K_M
        val active = ModelArtifactManager.MEDGEMMA_1_5_Q4_K_M

        assertEquals("vueniverse/medgemma-1.5-4b-it-lora-v7", candidate.modelId)
        assertEquals("lora-v7-q4-dd9c2a212672a5bb", candidate.modelRevision)
        assertEquals("medgemma-1.5-4b-it-lora-v7-Q4_K_M.gguf", candidate.fileName)
        assertEquals(2_489_893_568L, candidate.sizeBytes)
        assertEquals("dd9c2a212672a5bb18affbc344a4c0fcf4e9000b3b5155d6fdfe9a8104bad234", candidate.sha256)
        assertEquals("b31becdf4f39561800505514cce67681604fe449d04dd35c8c92fd7848c6d7bd", active.sha256)
        assertTrue(locator.locate(candidate) != locator.locate(active))
        assertTrue(candidate.modelRevision != active.modelRevision)
        assertTrue(ModelArtifactManager.downloadWorkName(candidate) != ModelArtifactManager.downloadWorkName(active))
        assertTrue(ModelArtifactManager.runtimeModelName(candidate).contains(candidate.modelRevision))
        assertEquals(active, ModelArtifactManager.artifactForVariant("vanilla"))
        assertEquals(candidate, ModelArtifactManager.artifactForVariant("lora-v7"))
    }

    @Test(expected = IllegalArgumentException::class)
    fun unknownVariantCannotSilentlyFallBackToVanilla() {
        ModelArtifactManager.artifactForVariant("lora-v8")
    }

    private fun artifactFor(bytes: ByteArray): ExpectedModelArtifact = ExpectedModelArtifact(
        modelId = "fictional/model",
        modelRevision = "fictional-revision",
        quantization = "TEST",
        fileName = "fictional.gguf",
        sizeBytes = bytes.size.toLong(),
        sha256 = sha256(bytes),
    )

    private fun sha256(bytes: ByteArray): String = MessageDigest
        .getInstance("SHA-256")
        .digest(bytes)
        .joinToString(separator = "") { byte -> "%02x".format(byte) }
}
