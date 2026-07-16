package com.whypulse.why_pulse.medgemma

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
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
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val locator = ModelArtifactLocator(context.filesDir)
        val manager = ModelArtifactManager(locator)
        val validation = manager.validate(ModelArtifactManager.MEDGEMMA_1_5_Q4_K_M)
        assumeTrue(
            "Q4 model is not installed for optional smoke test: $validation",
            validation is ArtifactValidationResult.Valid,
        )
        val file = (validation as ArtifactValidationResult.Valid).file

        assertTrue(native.load(file.absolutePath) is NativeOperationResult.Success)
        val result = native.infer(
            prompt = "Return only this JSON object: {\"status\":\"ok\"}",
            maxOutputTokens = 8,
            timeoutMillis = 60_000,
        )
        assertTrue(result is NativeInferenceResult.Success)
    }
}
