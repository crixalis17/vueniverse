package com.whypulse.why_pulse.medgemma

import com.whypulse.why_pulse.modelruntime.ExplainerRequest
import com.whypulse.why_pulse.modelruntime.ModelExplainerResult
import com.whypulse.why_pulse.modelruntime.ModelRuntimeApi
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

internal fun interface ModelArtifactValidator {
    fun validate(): ArtifactValidationResult
}

internal interface MedGemmaNativeAdapter {
    fun isAvailable(): Boolean

    fun load(modelPath: String): NativeOperationResult

    fun infer(prompt: String, maxOutputTokens: Int, timeoutMillis: Long): NativeInferenceResult

    fun cancel(): Boolean

    fun close()
}

private class DefaultNativeAdapter(
    private val native: NativeMedGemma = NativeMedGemma(),
) : MedGemmaNativeAdapter {
    override fun isAvailable(): Boolean = native.isAvailable()

    override fun load(modelPath: String): NativeOperationResult = native.load(modelPath)

    override fun infer(
        prompt: String,
        maxOutputTokens: Int,
        timeoutMillis: Long,
    ): NativeInferenceResult = native.infer(prompt, maxOutputTokens, timeoutMillis)

    override fun cancel(): Boolean = native.cancel()

    override fun close() = native.close()
}

class MedGemmaRuntime internal constructor(
    private val artifactValidator: ModelArtifactValidator,
    private val native: MedGemmaNativeAdapter,
    private val mapper: MedGemmaRuntimeResultMapper = MedGemmaRuntimeResultMapper(),
    dispatcher: CoroutineDispatcher = Dispatchers.IO,
    private val maxOutputTokens: Int = 384,
    private val timeoutMillis: Long = 30_000,
) : ModelRuntimeApi, AutoCloseable {
    private val scope = CoroutineScope(SupervisorJob() + dispatcher)
    private val inferenceMutex = Mutex()
    private val closed = AtomicBoolean(false)
    private val inferenceActive = AtomicBoolean(false)
    private var loadedModelPath: String? = null

    constructor(appPrivateRoot: File) : this(
        artifactValidator = ModelArtifactValidator {
            ModelArtifactManager(ModelArtifactLocator(appPrivateRoot)).validate(
                ModelArtifactManager.MEDGEMMA_1_5_Q4_K_M,
            )
        },
        native = DefaultNativeAdapter(),
    )

    init {
        require(maxOutputTokens in 1..512) { "maxOutputTokens must be between 1 and 512" }
        require(timeoutMillis in 1..120_000) { "timeoutMillis must be between 1 and 120000" }
    }

    override fun explain(
        request: ExplainerRequest,
        callback: (Result<ModelExplainerResult>) -> Unit,
    ) {
        if (closed.get()) {
            callback(Result.success(mapper.failure("runtime_closed", 0)))
            return
        }
        scope.launch {
            val result = runCatching {
                inferenceMutex.withLock { inferSerialized(request) }
            }.getOrElse {
                mapper.failure(if (closed.get()) "runtime_closed" else "runtime_error", 0)
            }
            callback(Result.success(result))
        }
    }

    fun cancelActive(): Boolean = inferenceActive.get() && native.cancel()

    override fun close() {
        if (!closed.compareAndSet(false, true)) return
        native.cancel()
        scope.launch {
            inferenceMutex.withLock {
                loadedModelPath = null
                native.close()
            }
            scope.cancel()
        }
    }

    private fun inferSerialized(request: ExplainerRequest): ModelExplainerResult {
        if (closed.get()) return mapper.failure("runtime_closed", 0)
        val prompt = runCatching { formatPrompt(request) }.getOrElse {
            return mapper.failure("invalid_request", 0)
        }
        if (loadedModelPath == null) {
            val artifact = artifactValidator.validate()
            if (artifact !is ArtifactValidationResult.Valid) return mapper.artifactFailure(artifact)
            if (!native.isAvailable()) return mapper.failure("native_unavailable", 0)
            when (val load = native.load(artifact.file.absolutePath)) {
                NativeOperationResult.Success -> loadedModelPath = artifact.file.absolutePath
                is NativeOperationResult.Failure -> return mapper.loadFailure(load)
            }
        }

        inferenceActive.set(true)
        return try {
            when (val result = native.infer(prompt, maxOutputTokens, timeoutMillis)) {
                is NativeInferenceResult.Success -> mapper.success(result.text, result.latencyMillis)
                is NativeInferenceResult.Failure -> mapper.nativeFailure(result)
            }
        } finally {
            inferenceActive.set(false)
        }
    }

    private fun formatPrompt(request: ExplainerRequest): String {
        require(request.schemaVersion.matches(VERSION_PATTERN)) { "invalid schema version" }
        require(request.evidenceVersion.matches(VERSION_PATTERN)) { "invalid evidence version" }
        require(request.findingState.length in 1..64) { "invalid finding state" }
        require(request.askIntent.length in 1..64) { "invalid ask intent" }
        require(BoundedJsonParser.parse(request.metricsJson) is JsonValue.ObjectValue) {
            "metricsJson must contain an object"
        }
        listOf(
            request.promotionGatesJson,
            request.exclusionsJson,
            request.counterevidenceJson,
            request.unresolvedInfluencesJson,
        ).forEach {
            val value = BoundedJsonParser.parse(it)
            require(value is JsonValue.ObjectValue || value is JsonValue.ArrayValue) {
                "embedded request JSON must contain an object or array"
            }
        }
        require(request.approvedNextObservations.size <= 3) { "too many next observations" }
        request.approvedNextObservations.forEach {
            require(it.isNotBlank() && it.length <= 180) { "invalid next observation" }
        }
        require(request.approvedNextObservations.size == request.approvedNextObservations.toSet().size) {
            "next observations must be unique"
        }

        val nextObservations = request.approvedNextObservations.joinToString(",") { jsonString(it) }
        val prompt = buildString {
            append("<start_of_turn>user\n")
            append("You are the WhyPulse evidence explainer. Use only this compact evidence. ")
            append("Describe association only; never diagnose, prescribe, claim causality, or invent values. ")
            append("Return exactly one JSON object with keys summary, citedParagraphsJson, uncertainty, ")
            append("citedUnresolvedInfluences, approvedNextObservation. citedParagraphsJson must be a ")
            append("JSON-encoded array of one or two objects with text and one to three citation IDs. ")
            append("Use only metric keys as citations, only supplied unresolved influence IDs, and either ")
            append("one exact approved next observation or null. Do not write digits in prose.\n")
            append("ExplainerRequest:{")
            append("\"schemaVersion\":").append(jsonString(request.schemaVersion)).append(',')
            append("\"evidenceVersion\":").append(jsonString(request.evidenceVersion)).append(',')
            append("\"findingState\":").append(jsonString(request.findingState)).append(',')
            append("\"metrics\":").append(request.metricsJson).append(',')
            append("\"promotionGates\":").append(request.promotionGatesJson).append(',')
            append("\"exclusions\":").append(request.exclusionsJson).append(',')
            append("\"counterevidence\":").append(request.counterevidenceJson).append(',')
            append("\"unresolvedInfluences\":").append(request.unresolvedInfluencesJson).append(',')
            append("\"approvedNextObservations\":[$nextObservations],")
            append("\"askIntent\":").append(jsonString(request.askIntent)).append('}')
            append("\n<end_of_turn>\n<start_of_turn>model\n")
        }
        require(prompt.length <= MAX_PROMPT_CHARACTERS) { "prompt exceeds its bound" }
        return prompt
    }

    private fun jsonString(value: String): String = buildString(value.length + 2) {
        append('"')
        for (character in value) {
            when (character) {
                '"' -> append("\\\"")
                '\\' -> append("\\\\")
                '\b' -> append("\\b")
                '\u000c' -> append("\\f")
                '\n' -> append("\\n")
                '\r' -> append("\\r")
                '\t' -> append("\\t")
                else -> if (character.code < 0x20) {
                    append("\\u").append(character.code.toString(16).padStart(4, '0'))
                } else {
                    append(character)
                }
            }
        }
        append('"')
    }

    private companion object {
        const val MAX_PROMPT_CHARACTERS = 24_000
        val VERSION_PATTERN = Regex("^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$")
    }
}
