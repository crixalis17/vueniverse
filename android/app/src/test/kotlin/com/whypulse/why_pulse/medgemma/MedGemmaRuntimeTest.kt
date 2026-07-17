package com.whypulse.why_pulse.medgemma

import com.whypulse.why_pulse.modelruntime.ExplainerRequest
import com.whypulse.why_pulse.modelruntime.ExplorerRequest
import com.whypulse.why_pulse.modelruntime.InferenceRuntime
import com.whypulse.why_pulse.modelruntime.ModelArtifactState
import com.whypulse.why_pulse.modelruntime.ModelExplainerResult
import com.whypulse.why_pulse.modelruntime.ModelExplorerResult
import com.whypulse.why_pulse.modelruntime.ModelRuntimeStatus
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import kotlin.concurrent.thread
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class MedGemmaRuntimeTest {
    @Test
    fun successfulInferenceLoadsOnceOffCallerThreadAndMapsMetadata() {
        val validator = FakeValidator(validArtifact())
        val native = FakeNative()
        val runtime = MedGemmaRuntime(validator, native)

        val status = runtime.awaitInspect()
        val first = runtime.awaitExplain(request())
        val second = runtime.awaitExplain(request())

        assertNotNull(first.output)
        assertNull(first.failure)
        assertTrue(first.safety.accepted)
        assertEquals(InferenceRuntime.PHONE_MED_GEMMA, first.metadata.runtime)
        assertEquals(2L, first.metadata.promptVersion)
        assertEquals(0L, first.metadata.outputGuardVersion)
        assertTrue(first.metadata.schemaValid)
        assertEquals(ModelArtifactState.AVAILABLE, status.state)
        assertEquals(1, validator.calls.get())
        assertEquals(1, native.loadCalls.get())
        assertEquals(2, native.inferCalls.get())
        assertFalse(native.inferenceThreadNames.any { it == Thread.currentThread().name })
        assertNull(second.failure)
        runtime.close()
    }

    @Test
    fun missingAndCorruptArtifactsHaveDistinctBoundedResults() {
        val missingFile = File("/private/missing/medgemma.gguf")
        val expected = ModelArtifactManager.MEDGEMMA_1_5_Q4_K_M
        val missing = MedGemmaRuntime(
            FakeValidator(ArtifactValidationResult.Missing(missingFile)),
            FakeNative(),
        ).awaitExplain(request())
        val corrupt = MedGemmaRuntime(
            FakeValidator(
                ArtifactValidationResult.ChecksumMismatch(
                    missingFile,
                    expected.sha256,
                    "0".repeat(64),
                ),
            ),
            FakeNative(),
        ).awaitExplain(request())

        assertEquals("missing_model", missing.failure)
        assertEquals(listOf("missing_model"), missing.safety.failures)
        assertEquals("corrupt_model_checksum", corrupt.failure)
        assertEquals(listOf("corrupt_model_checksum"), corrupt.safety.failures)
    }

    @Test
    fun nativeUnavailableAndTimeoutRemainDistinct() {
        val unavailableNative = FakeNative(available = false)
        val unavailable = MedGemmaRuntime(
            FakeValidator(validArtifact()),
            unavailableNative,
        ).awaitExplain(request())
        val timeoutNative = FakeNative(
            inference = {
                NativeInferenceResult.Failure(NativeErrorCode.TIMEOUT, "private detail", 30_000)
            },
        )
        val timeout = MedGemmaRuntime(
            FakeValidator(validArtifact()),
            timeoutNative,
        ).awaitExplain(request())

        assertEquals("native_unavailable", unavailable.failure)
        assertEquals("timeout", timeout.failure)
        assertEquals(30_000L, timeout.metadata.latencyMillis)
        assertFalse(timeout.metadata.schemaValid)
    }

    @Test
    fun activeInferenceCanBeCancelled() {
        val entered = CountDownLatch(1)
        val cancelled = CountDownLatch(1)
        val native = FakeNative(
            inference = {
                entered.countDown()
                assertTrue(cancelled.await(2, TimeUnit.SECONDS))
                NativeInferenceResult.Failure(NativeErrorCode.CANCELLED, "private detail", 15)
            },
            onCancel = { cancelled.countDown() },
        )
        val runtime = MedGemmaRuntime(FakeValidator(validArtifact()), native)
        val completed = CountDownLatch(1)
        var result: ModelExplainerResult? = null

        runtime.explain(request()) {
            result = it.getOrThrow()
            completed.countDown()
        }
        assertTrue(entered.await(2, TimeUnit.SECONDS))
        assertTrue(runtime.cancelActive())
        assertTrue(completed.await(2, TimeUnit.SECONDS))
        assertEquals("cancelled", result?.failure)
        runtime.close()
    }

    @Test
    fun concurrentRequestsAreSerialized() {
        val active = AtomicInteger()
        val maxActive = AtomicInteger()
        val native = FakeNative(
            inference = {
                val count = active.incrementAndGet()
                maxActive.updateAndGet { current -> maxOf(current, count) }
                Thread.sleep(40)
                active.decrementAndGet()
                NativeInferenceResult.Success(VALID_OUTPUT, 40)
            },
        )
        val runtime = MedGemmaRuntime(FakeValidator(validArtifact()), native)
        val finished = CountDownLatch(2)

        repeat(2) {
            thread {
                runtime.explain(request()) { finished.countDown() }
            }
        }

        assertTrue(finished.await(3, TimeUnit.SECONDS))
        assertEquals(1, maxActive.get())
        assertEquals(1, native.loadCalls.get())
        runtime.close()
    }

    @Test
    fun invalidRequestAndMalformedOutputAreBounded() {
        val native = FakeNative(inference = { NativeInferenceResult.Success("not-json", 9) })
        val runtime = MedGemmaRuntime(FakeValidator(validArtifact()), native)
        val malformedOutput = runtime.awaitExplain(request())
        val invalidRequest = runtime.awaitExplain(request().copy(metricsJson = "not-json"))
        val wrongJsonShape = runtime.awaitExplain(request().copy(metricsJson = "[]"))

        assertEquals("invalid_model_output", malformedOutput.failure)
        assertEquals("invalid_request", invalidRequest.failure)
        assertEquals("invalid_request", wrongJsonShape.failure)
        assertEquals(1, native.inferCalls.get())
        runtime.close()
    }

    @Test
    fun closeIsIdempotentAndRejectsNewWork() {
        val native = FakeNative()
        val runtime = MedGemmaRuntime(FakeValidator(validArtifact()), native)

        runtime.close()
        runtime.close()
        assertTrue(native.closed.await(2, TimeUnit.SECONDS))
        val result = runtime.awaitExplain(request())

        assertEquals("runtime_closed", result.failure)
        assertEquals(1, native.closeCalls.get())
    }

    @Test
    fun mapperRejectsWrongKeysAndInvalidEmbeddedParagraphs() {
        val mapper = MedGemmaRuntimeResultMapper()
        val wrongKeys = mapper.success("{\"summary\":\"only\"}", 1)
        val noParagraphs = mapper.success(
            VALID_OUTPUT.replace(
                "[{\\\"text\\\":\\\"Bounded association.\\\",\\\"citations\\\":[\\\"included_count\\\"]}]",
                "[]",
            ),
            1,
        )

        assertEquals("invalid_model_output", wrongKeys.failure)
        assertEquals("invalid_model_output", noParagraphs.failure)
    }

    @Test
    fun runtimeInspectionMapsArtifactAndNativeAvailability() {
        val missingRuntime = MedGemmaRuntime(
            FakeValidator(ArtifactValidationResult.Missing(File("/missing/model.gguf"))),
            FakeNative(),
        )
        val unavailableRuntime = MedGemmaRuntime(
            FakeValidator(validArtifact()),
            FakeNative(available = false),
        )
        val missing = missingRuntime.awaitInspect()
        val unavailable = unavailableRuntime.awaitInspect()

        assertEquals(ModelArtifactState.MISSING, missing.state)
        assertEquals("missing_model", missing.detail)
        assertEquals(ModelArtifactState.NATIVE_UNAVAILABLE, unavailable.state)
        assertEquals("native_unavailable", unavailable.detail)
        missingRuntime.close()
        unavailableRuntime.close()
    }

    @Test
    fun explorerOutputPreservesEvidenceVersionAndKnownDecisionShape() {
        val native = FakeNative(
            inference = { NativeInferenceResult.Success(VALID_EXPLORER_OUTPUT, 18) },
        )
        val runtime = MedGemmaRuntime(FakeValidator(validArtifact()), native)

        val result = runtime.awaitExplore(explorerRequest())

        assertEquals("fictional-wave2-v1", result.evidenceVersion)
        assertEquals("compare_repeated_event", result.decision?.operation)
        assertEquals("recurring_meeting", result.decision?.categoryId)
        assertTrue(result.metadata.schemaValid)
        assertNull(result.failure)
        runtime.close()
    }

    private fun MedGemmaRuntime.awaitExplain(request: ExplainerRequest): ModelExplainerResult {
        val latch = CountDownLatch(1)
        var result: ModelExplainerResult? = null
        explain(request) {
            result = it.getOrThrow()
            latch.countDown()
        }
        assertTrue("inference callback timed out", latch.await(3, TimeUnit.SECONDS))
        return requireNotNull(result)
    }

    private fun MedGemmaRuntime.awaitInspect(): ModelRuntimeStatus {
        val latch = CountDownLatch(1)
        var result: ModelRuntimeStatus? = null
        inspectRuntime {
            result = it.getOrThrow()
            latch.countDown()
        }
        assertTrue("inspection callback timed out", latch.await(3, TimeUnit.SECONDS))
        return requireNotNull(result)
    }

    private fun MedGemmaRuntime.awaitExplore(request: ExplorerRequest): ModelExplorerResult {
        val latch = CountDownLatch(1)
        var result: ModelExplorerResult? = null
        explore(request) {
            result = it.getOrThrow()
            latch.countDown()
        }
        assertTrue("Explorer callback timed out", latch.await(3, TimeUnit.SECONDS))
        return requireNotNull(result)
    }

    private fun request() = ExplainerRequest(
        schemaVersion = "explainer-v1",
        evidenceVersion = "fictional-wave2-v1",
        findingState = "supported",
        metricsJson = "{\"included_count\":8}",
        promotionGatesJson = "{}",
        exclusionsJson = "[]",
        counterevidenceJson = "[]",
        unresolvedInfluencesJson = "[]",
        approvedNextObservations = listOf("Observe the next comparable meeting."),
        askIntent = "why_promoted",
    )

    private fun explorerRequest() = ExplorerRequest(
        schemaVersion = "explorer-v1",
        evidenceVersion = "fictional-wave2-v1",
        analysisVersion = 1,
        promptVersion = 1,
        eventSummariesJson = "[]",
        availableCategoryIds = listOf("recurring_meeting"),
        availableInfluenceIds = emptyList(),
        allowedOperations = listOf("compare_repeated_event"),
    )

    private fun validArtifact(): ArtifactValidationResult.Valid {
        val file = File.createTempFile("medgemma-runtime-test", ".gguf")
        file.deleteOnExit()
        return ArtifactValidationResult.Valid(
            file,
            ModelArtifactManager.MEDGEMMA_1_5_Q4_K_M,
        )
    }

    private class FakeValidator(
        private val result: ArtifactValidationResult,
    ) : ModelArtifactValidator {
        val calls = AtomicInteger()

        override fun validate(): ArtifactValidationResult {
            calls.incrementAndGet()
            return result
        }
    }

    private class FakeNative(
        private val available: Boolean = true,
        private val inference: () -> NativeInferenceResult = {
            NativeInferenceResult.Success(VALID_OUTPUT, 25)
        },
        private val onCancel: () -> Unit = {},
    ) : MedGemmaNativeAdapter {
        val loadCalls = AtomicInteger()
        val inferCalls = AtomicInteger()
        val closeCalls = AtomicInteger()
        val inferenceThreadNames = mutableListOf<String>()
        val closed = CountDownLatch(1)

        override fun isAvailable(): Boolean = available

        override fun load(modelPath: String): NativeOperationResult {
            loadCalls.incrementAndGet()
            return NativeOperationResult.Success
        }

        override fun infer(
            prompt: String,
            maxOutputTokens: Int,
            timeoutMillis: Long,
        ): NativeInferenceResult {
            inferCalls.incrementAndGet()
            inferenceThreadNames += Thread.currentThread().name
            assertTrue(prompt.contains("<start_of_turn>model"))
            assertEquals(384, maxOutputTokens)
            assertEquals(30_000L, timeoutMillis)
            return inference()
        }

        override fun cancel(): Boolean {
            onCancel()
            return true
        }

        override fun close() {
            closeCalls.incrementAndGet()
            closed.countDown()
        }
    }

    private companion object {
        const val VALID_OUTPUT = """{"summary":"Bounded association.","citedParagraphsJson":"[{\"text\":\"Bounded association.\",\"citations\":[\"included_count\"]}]","uncertainty":"The association remains uncertain.","citedUnresolvedInfluences":[],"approvedNextObservation":null}"""
        const val VALID_EXPLORER_OUTPUT = """{"operation":"compare_repeated_event","categoryId":"recurring_meeting","influenceIds":[],"evidenceVersion":"fictional-wave2-v1"}"""
    }
}
