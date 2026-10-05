package com.vueniverse.vueniverse.medgemma

import android.content.Intent
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.runner.lifecycle.ActivityLifecycleMonitorRegistry
import androidx.test.runner.lifecycle.Stage
import com.vueniverse.vueniverse.MainActivity
import dev.flutter.plugins.integration_test.IntegrationTestPlugin
import java.util.concurrent.TimeUnit
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

/** Explicitly enabled only with the phone_lora_contract_test.dart host APK. */
@RunWith(AndroidJUnit4::class)
class PhoneLoraContractInstrumentationTest {
    @Test
    fun realAppPromptResultsPassWithoutFallback() {
        assumeTrue(
            "Requires explicitly compiled Dart contract-test APK and opt-in argument",
            InstrumentationRegistry.getArguments().getString("runPhoneLoraContract") == "true",
        )
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        // Older AndroidX ActivityScenario registers an unflagged receiver that
        // API 34 rejects. The framework launch needs no custom receiver.
        // startActivitySync also waits for UI idle; Flutter test frame scheduling
        // need not become idle before native inference. Await Dart results instead.
        instrumentation.runOnMainSync {
            instrumentation.targetContext.startActivity(
                Intent(instrumentation.targetContext, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }
        try {
            // Same native result channel used by FlutterTestRunner. The Dart
            // test owns a fresh in-memory fixture and never opens the Live store.
            val results = IntegrationTestPlugin.testResults.get(12, TimeUnit.MINUTES)
            assertTrue("Dart contract test must report results", results.isNotEmpty())
            assertTrue(
                "Wrong host APK: expected selected LoRA contract test",
                results.keys.any { it.contains("selected LoRA passes the real app contract") },
            )
            results.forEach { (name, outcome) ->
                assertEquals("Dart contract failure: $name", "success", outcome)
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
