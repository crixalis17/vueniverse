package com.whypulse.why_pulse.medgemma

import com.whypulse.why_pulse.modelruntime.ExplainerOutput
import com.whypulse.why_pulse.modelruntime.ExplorerDecision
import com.whypulse.why_pulse.modelruntime.InferenceRuntime
import com.whypulse.why_pulse.modelruntime.ModelExplainerResult
import com.whypulse.why_pulse.modelruntime.ModelExplorerResult
import com.whypulse.why_pulse.modelruntime.ModelRuntimeMetadata
import com.whypulse.why_pulse.modelruntime.SafetyResult

internal sealed interface JsonValue {
    data class ObjectValue(val values: Map<String, JsonValue>) : JsonValue

    data class ArrayValue(val values: List<JsonValue>) : JsonValue

    data class StringValue(val value: String) : JsonValue

    data class NumberValue(val value: String) : JsonValue

    data class BooleanValue(val value: Boolean) : JsonValue

    data object NullValue : JsonValue
}

/** Small strict parser used to keep model-output parsing available in local JVM tests. */
internal object BoundedJsonParser {
    fun parse(raw: String): JsonValue {
        require(raw.length in 1..MAX_JSON_CHARACTERS) { "JSON is empty or exceeds its bound" }
        return Parser(raw).parse()
    }

    private class Parser(private val source: String) {
        private var index = 0

        fun parse(): JsonValue {
            val value = value(0)
            whitespace()
            require(index == source.length) { "unexpected trailing JSON content" }
            return value
        }

        private fun value(depth: Int): JsonValue {
            require(depth <= MAX_DEPTH) { "JSON nesting exceeds its bound" }
            whitespace()
            require(index < source.length) { "unexpected end of JSON" }
            return when (source[index]) {
                '{' -> objectValue(depth + 1)
                '[' -> arrayValue(depth + 1)
                '"' -> JsonValue.StringValue(stringValue())
                't' -> literal("true", JsonValue.BooleanValue(true))
                'f' -> literal("false", JsonValue.BooleanValue(false))
                'n' -> literal("null", JsonValue.NullValue)
                '-', in '0'..'9' -> numberValue()
                else -> error("unexpected JSON token")
            }
        }

        private fun objectValue(depth: Int): JsonValue.ObjectValue {
            index += 1
            whitespace()
            val values = linkedMapOf<String, JsonValue>()
            if (consume('}')) return JsonValue.ObjectValue(values)
            while (true) {
                whitespace()
                require(index < source.length && source[index] == '"') {
                    "JSON object key must be a string"
                }
                val key = stringValue()
                require(key !in values) { "duplicate JSON object key" }
                whitespace()
                require(consume(':')) { "JSON object key is missing a value" }
                values[key] = value(depth)
                whitespace()
                if (consume('}')) break
                require(consume(',')) { "JSON object is missing a comma" }
            }
            return JsonValue.ObjectValue(values)
        }

        private fun arrayValue(depth: Int): JsonValue.ArrayValue {
            index += 1
            whitespace()
            val values = mutableListOf<JsonValue>()
            if (consume(']')) return JsonValue.ArrayValue(values)
            while (true) {
                require(values.size < MAX_ARRAY_ITEMS) { "JSON array exceeds its bound" }
                values += value(depth)
                whitespace()
                if (consume(']')) break
                require(consume(',')) { "JSON array is missing a comma" }
            }
            return JsonValue.ArrayValue(values)
        }

        private fun stringValue(): String {
            require(consume('"')) { "JSON string is missing its opening quote" }
            val result = StringBuilder()
            while (index < source.length) {
                val character = source[index++]
                when {
                    character == '"' -> return result.toString()
                    character == '\\' -> result.append(escape())
                    character.code < 0x20 -> error("JSON string contains a control character")
                    else -> result.append(character)
                }
                require(result.length <= MAX_STRING_CHARACTERS) { "JSON string exceeds its bound" }
            }
            error("unterminated JSON string")
        }

        private fun escape(): Char {
            require(index < source.length) { "unterminated JSON escape" }
            return when (val escaped = source[index++]) {
                '"', '\\', '/' -> escaped
                'b' -> '\b'
                'f' -> '\u000c'
                'n' -> '\n'
                'r' -> '\r'
                't' -> '\t'
                'u' -> {
                    require(index + 4 <= source.length) { "short JSON unicode escape" }
                    val digits = source.substring(index, index + 4)
                    index += 4
                    digits.toIntOrNull(16)?.toChar() ?: error("invalid JSON unicode escape")
                }
                else -> error("invalid JSON escape")
            }
        }

        private fun numberValue(): JsonValue.NumberValue {
            val start = index
            consume('-')
            require(index < source.length) { "invalid JSON number" }
            if (consume('0')) {
                require(index >= source.length || source[index] !in '0'..'9') {
                    "JSON number contains a leading zero"
                }
            } else {
                require(source[index] in '1'..'9') { "invalid JSON number" }
                while (index < source.length && source[index] in '0'..'9') index += 1
            }
            if (consume('.')) {
                require(index < source.length && source[index] in '0'..'9') {
                    "invalid JSON fraction"
                }
                while (index < source.length && source[index] in '0'..'9') index += 1
            }
            if (index < source.length && source[index] in "eE") {
                index += 1
                if (index < source.length && source[index] in "+-") index += 1
                require(index < source.length && source[index] in '0'..'9') {
                    "invalid JSON exponent"
                }
                while (index < source.length && source[index] in '0'..'9') index += 1
            }
            return JsonValue.NumberValue(source.substring(start, index))
        }

        private fun literal(expected: String, value: JsonValue): JsonValue {
            require(source.regionMatches(index, expected, 0, expected.length)) {
                "invalid JSON literal"
            }
            index += expected.length
            return value
        }

        private fun whitespace() {
            while (index < source.length && source[index] in " \n\r\t") index += 1
        }

        private fun consume(expected: Char): Boolean {
            if (index >= source.length || source[index] != expected) return false
            index += 1
            return true
        }
    }

    private const val MAX_JSON_CHARACTERS = 32_768
    private const val MAX_STRING_CHARACTERS = 8_192
    private const val MAX_ARRAY_ITEMS = 32
    private const val MAX_DEPTH = 8
}

class MedGemmaRuntimeResultMapper {
    fun success(
        rawOutput: String,
        latencyMillis: Long,
        evidenceVersion: String = "unknown",
    ): ModelExplainerResult {
        val output = runCatching { decodeOutput(rawOutput) }.getOrElse {
            return failure("invalid_model_output", latencyMillis, evidenceVersion)
        }
        return ModelExplainerResult(
            evidenceVersion = evidenceVersion,
            output = output,
            metadata = metadata(latencyMillis, schemaValid = true),
            safety = SafetyResult(accepted = true, failures = emptyList()),
            failure = null,
        )
    }

    fun explorerSuccess(
        rawOutput: String,
        latencyMillis: Long,
        evidenceVersion: String,
    ): ModelExplorerResult {
        val decision = runCatching { decodeExplorerDecision(rawOutput, evidenceVersion) }.getOrElse {
            return explorerFailure("invalid_model_output", latencyMillis, evidenceVersion)
        }
        return ModelExplorerResult(
            evidenceVersion = evidenceVersion,
            decision = decision,
            metadata = metadata(latencyMillis, schemaValid = true),
            failure = null,
        )
    }

    fun artifactFailure(
        result: ArtifactValidationResult,
        evidenceVersion: String = "unknown",
    ): ModelExplainerResult = failure(
        when (result) {
            is ArtifactValidationResult.Missing -> "missing_model"
            is ArtifactValidationResult.Unreadable -> "unreadable_model"
            is ArtifactValidationResult.SizeMismatch -> "corrupt_model_size"
            is ArtifactValidationResult.ChecksumMismatch -> "corrupt_model_checksum"
            is ArtifactValidationResult.IoFailure -> "model_io_failure"
            is ArtifactValidationResult.Valid -> error("a valid artifact is not a failure")
        },
        latencyMillis = 0,
        evidenceVersion = evidenceVersion,
    )

    fun nativeFailure(
        result: NativeInferenceResult.Failure,
        evidenceVersion: String = "unknown",
    ): ModelExplainerResult = failure(
        when (result.code) {
            NativeErrorCode.NATIVE_UNAVAILABLE -> "native_unavailable"
            NativeErrorCode.MODEL_NOT_LOADED -> "model_not_loaded"
            NativeErrorCode.MODEL_LOAD_FAILED -> "model_load_failed"
            NativeErrorCode.INVALID_PROMPT -> "invalid_prompt"
            NativeErrorCode.CONTEXT_CREATION_FAILED -> "context_creation_failed"
            NativeErrorCode.TOKENIZATION_FAILED -> "prompt_too_large"
            NativeErrorCode.DECODE_FAILED -> "decode_failed"
            NativeErrorCode.CANCELLED -> "cancelled"
            NativeErrorCode.TIMEOUT -> "timeout"
            NativeErrorCode.INTERNAL_ERROR, NativeErrorCode.UNKNOWN, NativeErrorCode.OK -> {
                "native_internal_error"
            }
        },
        result.latencyMillis,
        evidenceVersion,
    )

    fun loadFailure(
        result: NativeOperationResult.Failure,
        evidenceVersion: String = "unknown",
    ): ModelExplainerResult = failure(
        when (result.code) {
            NativeErrorCode.NATIVE_UNAVAILABLE -> "native_unavailable"
            NativeErrorCode.MODEL_LOAD_FAILED -> "model_load_failed"
            else -> "native_load_error"
        },
        latencyMillis = 0,
        evidenceVersion = evidenceVersion,
    )

    fun failure(
        code: String,
        latencyMillis: Long,
        evidenceVersion: String = "unknown",
    ): ModelExplainerResult {
        val boundedCode = if (code in FAILURE_CODES) code else "runtime_error"
        return ModelExplainerResult(
            evidenceVersion = evidenceVersion,
            output = null,
            metadata = metadata(latencyMillis.coerceAtLeast(0), schemaValid = false),
            safety = SafetyResult(accepted = false, failures = listOf(boundedCode)),
            failure = boundedCode,
        )
    }

    fun explorerFailure(
        code: String,
        latencyMillis: Long,
        evidenceVersion: String,
    ): ModelExplorerResult {
        val boundedCode = if (code in FAILURE_CODES) code else "runtime_error"
        return ModelExplorerResult(
            evidenceVersion = evidenceVersion,
            decision = null,
            metadata = metadata(latencyMillis.coerceAtLeast(0), schemaValid = false),
            failure = boundedCode,
        )
    }

    private fun decodeOutput(rawOutput: String): ExplainerOutput {
        val root = BoundedJsonParser.parse(rawOutput) as? JsonValue.ObjectValue
            ?: error("model output must be a JSON object")
        require(root.values.keys == OUTPUT_KEYS) { "model output keys do not match the contract" }
        val summary = root.requiredString("summary", 180)
        val paragraphsJson = root.requiredString("citedParagraphsJson", 2_048)
        validateParagraphs(paragraphsJson)
        val uncertainty = root.requiredString("uncertainty", 180)
        val influences = root.requiredStringArray("citedUnresolvedInfluences", 3, 64)
        val nextObservation = when (val value = root.values.getValue("approvedNextObservation")) {
            JsonValue.NullValue -> null
            is JsonValue.StringValue -> value.value.trim().also {
                require(it.isNotEmpty() && it.length <= 180) { "next observation is invalid" }
            }
            else -> error("next observation must be a string or null")
        }
        return ExplainerOutput(
            summary = summary,
            citedParagraphsJson = paragraphsJson,
            uncertainty = uncertainty,
            citedUnresolvedInfluences = influences,
            approvedNextObservation = nextObservation,
        )
    }

    private fun decodeExplorerDecision(
        rawOutput: String,
        expectedEvidenceVersion: String,
    ): ExplorerDecision {
        val root = BoundedJsonParser.parse(rawOutput) as? JsonValue.ObjectValue
            ?: error("explorer output must be a JSON object")
        require(root.values.keys == EXPLORER_OUTPUT_KEYS) {
            "explorer output keys do not match the contract"
        }
        val operation = root.requiredString("operation", 64)
        val categoryId = when (val value = root.values.getValue("categoryId")) {
            JsonValue.NullValue -> null
            is JsonValue.StringValue -> value.value.trim().also {
                require(it.isNotEmpty() && it.length <= 64) { "category ID is invalid" }
            }
            else -> error("category ID must be a string or null")
        }
        val influenceIds = root.requiredStringArray("influenceIds", 3, 64)
        val evidenceVersion = root.requiredString("evidenceVersion", 64)
        require(evidenceVersion == expectedEvidenceVersion) { "evidence version mismatch" }
        return ExplorerDecision(
            operation = operation,
            categoryId = categoryId,
            influenceIds = influenceIds,
            evidenceVersion = evidenceVersion,
        )
    }

    private fun validateParagraphs(raw: String) {
        val paragraphs = (BoundedJsonParser.parse(raw) as? JsonValue.ArrayValue)?.values
            ?: error("cited paragraphs must be an array")
        require(paragraphs.size in 1..2) { "cited paragraphs count is invalid" }
        for (value in paragraphs) {
            val paragraph = value as? JsonValue.ObjectValue ?: error("paragraph must be an object")
            require(paragraph.values.keys == PARAGRAPH_KEYS) { "paragraph keys are invalid" }
            paragraph.requiredString("text", 280)
            paragraph.requiredStringArray("citations", 3, 64, requireNonEmpty = true)
        }
    }

    private fun metadata(latencyMillis: Long, schemaValid: Boolean) = ModelRuntimeMetadata(
        runtime = InferenceRuntime.PHONE_MED_GEMMA,
        modelName = MODEL_NAME,
        promptVersion = PROMPT_VERSION,
        outputGuardVersion = 0,
        latencyMillis = latencyMillis,
        schemaValid = schemaValid,
    )

    private fun JsonValue.ObjectValue.requiredString(key: String, maxLength: Int): String {
        val text = (values[key] as? JsonValue.StringValue)?.value?.trim()
            ?: error("$key must be a string")
        require(text.isNotEmpty() && text.length <= maxLength) { "$key is outside its bound" }
        return text
    }

    private fun JsonValue.ObjectValue.requiredStringArray(
        key: String,
        maxItems: Int,
        maxItemLength: Int,
        requireNonEmpty: Boolean = false,
    ): List<String> {
        val array = (values[key] as? JsonValue.ArrayValue)?.values
            ?: error("$key must be an array")
        require(array.size <= maxItems && (!requireNonEmpty || array.isNotEmpty())) {
            "$key count is invalid"
        }
        return array.map { value ->
            val text = (value as? JsonValue.StringValue)?.value?.trim()
                ?: error("$key items must be strings")
            require(text.isNotEmpty() && text.length <= maxItemLength) { "$key item is invalid" }
            text
        }.also { require(it.size == it.toSet().size) { "$key contains duplicates" } }
    }

    private companion object {
        const val MODEL_NAME = "google/medgemma-1.5-4b-it-Q4_K_M"
        const val PROMPT_VERSION = 2L
        val OUTPUT_KEYS = setOf(
            "summary",
            "citedParagraphsJson",
            "uncertainty",
            "citedUnresolvedInfluences",
            "approvedNextObservation",
        )
        val PARAGRAPH_KEYS = setOf("text", "citations")
        val EXPLORER_OUTPUT_KEYS = setOf(
            "operation",
            "categoryId",
            "influenceIds",
            "evidenceVersion",
        )
        val FAILURE_CODES = setOf(
            "missing_model",
            "unreadable_model",
            "corrupt_model_size",
            "corrupt_model_checksum",
            "model_io_failure",
            "native_unavailable",
            "model_not_loaded",
            "model_load_failed",
            "invalid_prompt",
            "context_creation_failed",
            "prompt_too_large",
            "decode_failed",
            "cancelled",
            "timeout",
            "native_internal_error",
            "native_load_error",
            "invalid_model_output",
            "invalid_request",
            "runtime_closed",
            "runtime_error",
        )
    }
}
