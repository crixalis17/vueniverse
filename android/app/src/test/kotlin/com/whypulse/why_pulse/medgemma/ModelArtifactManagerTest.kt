package com.whypulse.why_pulse.medgemma

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
