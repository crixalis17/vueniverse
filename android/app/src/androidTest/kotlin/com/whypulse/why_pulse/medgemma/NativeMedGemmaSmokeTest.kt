package com.whypulse.why_pulse.medgemma

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Assert.fail
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class NativeMedGemmaSmokeTest {
    private val native = NativeMedGemma()

    @After
    fun tearDown() {
        native.close()
    }

    @Test
    fun nativeLibraryLoadsForArm64Runtime() {
        assertTrue(native.isAvailable())
    }

    @Test
    fun installedQ4ModelCanBeginBoundedGreedyGeneration() {
        val file = installedModelOrSkip().file

        assertTrue(native.load(file.absolutePath) is NativeOperationResult.Success)
        val result = native.infer(
            prompt = "Return only this JSON object: {\"status\":\"ok\"}",
            maxOutputTokens = 8,
            timeoutMillis = 60_000,
        )
        assertTrue(result is NativeInferenceResult.Success)
    }

    @Test
    fun missingAndCorruptArtifactsAreRejectedOnDevice() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val root = java.io.File(context.cacheDir, "artifact-validation-${System.nanoTime()}")
        val artifact = ExpectedModelArtifact(
            modelId = "fictional/test",
            modelRevision = "test-revision",
            quantization = "Q4_TEST",
            fileName = "tiny.gguf",
            sizeBytes = 4,
            sha256 = "9f64a747e1b97f131fabb6b447296c9b6f0201e79fb3c5356e6c77e89b6a806a",
        )
        val manager = ModelArtifactManager(ModelArtifactLocator(root))
        assertTrue(manager.validate(artifact) is ArtifactValidationResult.Missing)
        val modelDirectory = ModelArtifactLocator(root).modelDirectory()
        assertTrue(modelDirectory.mkdirs())
        java.io.File(modelDirectory, artifact.fileName).writeBytes(byteArrayOf(0, 1, 2))
        assertTrue(manager.validate(artifact) is ArtifactValidationResult.SizeMismatch)
        java.io.File(modelDirectory, artifact.fileName).writeBytes(byteArrayOf(0, 1, 2, 4))
        assertTrue(manager.validate(artifact) is ArtifactValidationResult.ChecksumMismatch)
        root.deleteRecursively()
    }

    private fun installedModelOrSkip(): ArtifactValidationResult.Valid {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val manager = ModelArtifactManager(ModelArtifactLocator(context.filesDir))
        val validation = manager.validate(ModelArtifactManager.MEDGEMMA_1_5_Q4_K_M)
        val required = InstrumentationRegistry.getArguments().getString("requireRealModel") == "true"
        if (required && validation !is ArtifactValidationResult.Valid) {
            fail("Required Q4 model is not installed or valid: $validation")
        }
        assumeTrue(
            "Q4 model is not installed for optional smoke test: $validation",
            validation is ArtifactValidationResult.Valid,
        )
        return validation as ArtifactValidationResult.Valid
    }
}
