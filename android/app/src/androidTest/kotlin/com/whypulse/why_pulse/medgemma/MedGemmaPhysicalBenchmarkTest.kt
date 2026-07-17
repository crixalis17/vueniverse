package com.whypulse.why_pulse.medgemma

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Debug
import android.os.PowerManager
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.time.Instant
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import kotlin.concurrent.thread
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class MedGemmaPhysicalBenchmarkTest {
    @Test
    fun recordTenCallsCancellationMemoryBatteryAndThermalState() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val required =
            InstrumentationRegistry.getArguments().getString("requirePhysicalBenchmark") == "true"
        val deviceKind = if (isEmulator()) "emulator" else "physical_phone"
        if (required && deviceKind != "physical_phone") {
            fail("MG-12 requires a physical ARM64 phone; detected $deviceKind")
        }
        assumeTrue("Optional MG-12 benchmark requires a physical phone", deviceKind == "physical_phone")

        val validation = ModelArtifactManager(ModelArtifactLocator(context.filesDir)).validate(
            ModelArtifactManager.MEDGEMMA_1_5_Q4_K_M,
        )
        if (required && validation !is ArtifactValidationResult.Valid) {
            fail("MG-12 requires the exact Q4 artifact: $validation")
        }
        assumeTrue("Optional MG-12 benchmark requires the exact Q4 artifact", validation is ArtifactValidationResult.Valid)
        val artifact = validation as ArtifactValidationResult.Valid
        val native = NativeMedGemma()
        assertTrue("MedGemma JNI is unavailable", native.isAvailable())

        val baselineBeforeLoad = pssBytes()
        val loadStarted = System.nanoTime()
        val load = native.load(artifact.file.absolutePath)
        val loadSeconds = elapsedSeconds(loadStarted)
        assertTrue("Q4 load failed: $load", load is NativeOperationResult.Success)
        val coldLoadIncrement = (pssBytes() - baselineBeforeLoad).coerceAtLeast(0)
        val calls = JSONArray()
        try {
            repeat(10) { offset ->
                val index = offset + 1
                val baseline = if (index == 1) baselineBeforeLoad else pssBytes()
                val measurement = measureInference(native, BENCHMARK_PROMPT, baseline)
                calls.put(
                    callJson(
                        context = context,
                        index = index,
                        result = measurement.result,
                        peakIncrementalRss = maxOf(
                            measurement.peakIncrementalRss,
                            if (index == 1) coldLoadIncrement else 0,
                        ),
                        loadSeconds = if (index == 1) loadSeconds else null,
                    ),
                )
            }
            calls.put(cancellationProbe(context, native, 11))
        } finally {
            native.close()
        }

        val report = JSONObject()
            .put("schema_version", 1)
            .put("created_at_utc", Instant.now().toString())
            .put(
                "artifact",
                JSONObject()
                    .put("model_id", artifact.artifact.modelId)
                    .put("model_revision", artifact.artifact.modelRevision)
                    .put("quantization", artifact.artifact.quantization)
                    .put("artifact_bytes", artifact.artifact.sizeBytes)
                    .put("artifact_sha256", artifact.artifact.sha256)
                    .put("llama_cpp_revision", LLAMA_CPP_REVISION),
            )
            .put(
                "device",
                JSONObject()
                    .put("kind", deviceKind)
                    .put("name", "${Build.MANUFACTURER} ${Build.MODEL}".trim())
                    .put("os_version", Build.VERSION.RELEASE)
                    .put("api_level", Build.VERSION.SDK_INT)
                    .put("abi", Build.SUPPORTED_ABIS.firstOrNull() ?: "unknown"),
            )
            .put("runtime_backend", "llama.cpp JNI")
            .put("runtime_revision", "android-mg12-v1")
            .put("calls", calls)
        val output = File(context.filesDir, "medgemma-benchmark/runtime-report.json")
        val outputDirectory = requireNotNull(output.parentFile)
        assertTrue(outputDirectory.isDirectory || outputDirectory.mkdirs())
        output.writeText(report.toString(2))
        assertTrue("Benchmark report was not written", output.isFile && output.length() > 0)
    }

    private fun measureInference(
        native: NativeMedGemma,
        prompt: String,
        baselinePss: Long,
    ): InferenceMeasurement {
        val running = AtomicBoolean(true)
        val peak = AtomicLong(pssBytes())
        val monitor = thread(name = "medgemma-rss-monitor") {
            while (running.get()) {
                peak.updateAndGet { previous -> maxOf(previous, pssBytes()) }
                Thread.sleep(25)
            }
            peak.updateAndGet { previous -> maxOf(previous, pssBytes()) }
        }
        val result = try {
            native.infer(prompt, maxOutputTokens = 192, timeoutMillis = 120_000)
        } finally {
            running.set(false)
            monitor.join(2_000)
        }
        return InferenceMeasurement(result, (peak.get() - baselinePss).coerceAtLeast(0))
    }

    private fun callJson(
        context: Context,
        index: Int,
        result: NativeInferenceResult,
        peakIncrementalRss: Long,
        loadSeconds: Double?,
    ): JSONObject {
        val battery = batteryState(context)
        val json = JSONObject()
            .put("call_index", index)
            .put("cold_start", index == 1)
            .put("peak_incremental_rss_bytes", peakIncrementalRss)
            .put("cancelled", false)
            .put("crashed", false)
            .put("out_of_memory", false)
            .put("thermal_state", thermalState(context))
        if (loadSeconds != null) json.put("load_seconds", loadSeconds)
        if (battery.levelPercent != null) json.put("battery_level_percent", battery.levelPercent)
        if (battery.temperatureCelsius != null) {
            json.put("battery_temperature_celsius", battery.temperatureCelsius)
        }
        when (result) {
            is NativeInferenceResult.Success -> {
                val mapped = MedGemmaRuntimeResultMapper().success(
                    result.text,
                    result.latencyMillis,
                    "benchmark-v1",
                )
                json
                    .put("completed", true)
                    .put("total_seconds", result.latencyMillis / 1_000.0)
                    .put("raw_schema_valid", mapped.metadata.schemaValid)
                    .put("guard_accepted", mapped.safety.accepted && mapped.failure == null)
                    .put("fallback_used", false)
            }
            is NativeInferenceResult.Failure -> json
                .put("completed", false)
                .put("error_code", result.code.name.lowercase())
                .put("raw_schema_valid", false)
                .put("guard_accepted", false)
                .put("fallback_used", true)
        }
        return json
    }

    private fun cancellationProbe(context: Context, native: NativeMedGemma, index: Int): JSONObject {
        val started = CountDownLatch(1)
        var result: NativeInferenceResult? = null
        val worker = thread(name = "medgemma-cancellation-probe") {
            started.countDown()
            result = native.infer(CANCELLATION_PROMPT, maxOutputTokens = 512, timeoutMillis = 120_000)
        }
        assertTrue(started.await(2, TimeUnit.SECONDS))
        Thread.sleep(100)
        native.cancel()
        worker.join(30_000)
        val cancelled = result is NativeInferenceResult.Failure &&
            (result as NativeInferenceResult.Failure).code == NativeErrorCode.CANCELLED
        val battery = batteryState(context)
        return JSONObject()
            .put("call_index", index)
            .put("cold_start", false)
            .put("completed", false)
            .put("cancelled", cancelled)
            .put("crashed", false)
            .put("out_of_memory", false)
            .put("error_code", if (cancelled) "cancelled" else "cancellation_not_observed")
            .put("thermal_state", thermalState(context))
            .apply {
                if (battery.levelPercent != null) put("battery_level_percent", battery.levelPercent)
                if (battery.temperatureCelsius != null) {
                    put("battery_temperature_celsius", battery.temperatureCelsius)
                }
            }
    }

    private fun batteryState(context: Context): BatteryState {
        val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val temperatureTenths = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, Int.MIN_VALUE)
            ?: Int.MIN_VALUE
        return BatteryState(
            levelPercent = if (level >= 0 && scale > 0) level * 100.0 / scale else null,
            temperatureCelsius = if (temperatureTenths != Int.MIN_VALUE) {
                temperatureTenths / 10.0
            } else {
                null
            },
        )
    }

    private fun thermalState(context: Context): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return "unknown"
        val status = context.getSystemService(PowerManager::class.java).currentThermalStatus
        return when (status) {
            PowerManager.THERMAL_STATUS_NONE -> "nominal"
            PowerManager.THERMAL_STATUS_LIGHT,
            PowerManager.THERMAL_STATUS_MODERATE,
            -> "fair"
            PowerManager.THERMAL_STATUS_SEVERE -> "serious"
            else -> "critical"
        }
    }

    private fun isEmulator(): Boolean =
        Build.FINGERPRINT.startsWith("generic") ||
            Build.FINGERPRINT.contains("emulator") ||
            Build.MODEL.contains("Emulator") ||
            Build.MODEL.contains("Android SDK built for") ||
            Build.HARDWARE.contains("goldfish") ||
            Build.HARDWARE.contains("ranchu")

    private fun pssBytes(): Long = Debug.getPss() * 1_024

    private fun elapsedSeconds(startedNanos: Long): Double =
        (System.nanoTime() - startedNanos) / 1_000_000_000.0

    private data class InferenceMeasurement(
        val result: NativeInferenceResult,
        val peakIncrementalRss: Long,
    )

    private data class BatteryState(
        val levelPercent: Double?,
        val temperatureCelsius: Double?,
    )

    companion object {
        private const val LLAMA_CPP_REVISION = "5839ba352471b2a7b45e7ba401619a6896f10f8b"
        private const val BENCHMARK_PROMPT = """<start_of_turn>user
Return exactly one JSON object with keys summary, citedParagraphsJson, uncertainty, citedUnresolvedInfluences, approvedNextObservation. Use summary 'Bounded association.' and cite included_count. No markdown.
<end_of_turn>
<start_of_turn>model
"""
        private const val CANCELLATION_PROMPT = """<start_of_turn>user
Write a long JSON explanation of a fictional repeated association. Return JSON only.
<end_of_turn>
<start_of_turn>model
"""
    }
}
