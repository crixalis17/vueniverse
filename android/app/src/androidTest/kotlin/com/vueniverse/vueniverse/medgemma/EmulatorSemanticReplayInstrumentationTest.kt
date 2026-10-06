package com.vueniverse.vueniverse.medgemma

import android.content.Intent
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.runner.lifecycle.ActivityLifecycleMonitorRegistry
import androidx.test.runner.lifecycle.Stage
import com.vueniverse.vueniverse.BuildConfig
import com.vueniverse.vueniverse.MainActivity
import dev.flutter.plugins.integration_test.IntegrationTestPlugin
import java.util.concurrent.TimeUnit
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

/** Synthetic frozen replay only; no collection store, no retries or activation. */
@RunWith(AndroidJUnit4::class)
class EmulatorSemanticReplayInstrumentationTest {
    @Test
    fun frozenReplayReportsTransportResults() {
        assumeTrue(
            "Requires explicit synthetic replay opt-in",
            InstrumentationRegistry.getArguments().getString("runEmulatorSemanticReplay") == "true",
        )
        assertTrue("Fixture candidate capability required", BuildConfig.VUENIVERSE_CANDIDATE_EVALUATION)
        assertEquals("lora-v7", BuildConfig.VUENIVERSE_MODEL_VARIANT)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        instrumentation.runOnMainSync {
            instrumentation.targetContext.startActivity(
                Intent(instrumentation.targetContext, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }
        try {
            // Fifteen calls have 120-second native bounds. Includes cold load and
            // final transport; this outer ceiling is not an inference override.
            val results = IntegrationTestPlugin.testResults.get(45, TimeUnit.MINUTES)
            assertTrue("Dart replay must report results", results.isNotEmpty())
            assertTrue(
                "Wrong host APK; frozen replay was not compiled",
                results.keys.any {
                    it.contains("frozen emulator semantic LoRA replay captures all attempted cases")
                },
            )
            results.forEach { (name, outcome) ->
                assertEquals("Dart replay transport failure: $name", "success", outcome)
            }
        } finally {
            instrumentation.runOnMainSync {
                ActivityLifecycleMonitorRegistry.getInstance()
                    .getActivitiesInStage(Stage.RESUMED)
                    .filterIsInstance<MainActivity>()
                    .forEach { it.finish() }
            }
        }
    }
}
