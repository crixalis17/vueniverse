package com.vueniverse.vueniverse.medgemma

enum class NativeErrorCode(val wireCode: Int) {
    OK(0),
    NATIVE_UNAVAILABLE(1),
    MODEL_NOT_LOADED(2),
    MODEL_LOAD_FAILED(3),
    INVALID_PROMPT(4),
    CONTEXT_CREATION_FAILED(5),
    TOKENIZATION_FAILED(6),
    DECODE_FAILED(7),
    CANCELLED(8),
    TIMEOUT(9),
    INTERNAL_ERROR(10),
    UNKNOWN(-1),
    ;

    companion object {
        fun fromWireCode(code: Int): NativeErrorCode = entries.firstOrNull { it.wireCode == code } ?: UNKNOWN
    }
}

sealed interface NativeOperationResult {
    data object Success : NativeOperationResult

    data class Failure(
        val code: NativeErrorCode,
        val message: String,
    ) : NativeOperationResult
}

sealed interface NativeInferenceResult {
    data class Success(
        val text: String,
        val latencyMillis: Long,
    ) : NativeInferenceResult

    data class Failure(
        val code: NativeErrorCode,
        val message: String,
        val latencyMillis: Long,
    ) : NativeInferenceResult
}

class NativeMedGemma {
    fun isAvailable(): Boolean = libraryLoaded && nativeIsAvailable()

    fun load(modelPath: String): NativeOperationResult {
        if (!libraryLoaded) return unavailableOperation()
        val code = NativeErrorCode.fromWireCode(nativeLoad(modelPath))
        return if (code == NativeErrorCode.OK) {
            NativeOperationResult.Success
        } else {
            NativeOperationResult.Failure(code, nativeLastErrorMessage())
        }
    }

    fun infer(
        prompt: String,
        maxOutputTokens: Int,
        timeoutMillis: Long,
        grammar: String? = null,
    ): NativeInferenceResult {
        require(maxOutputTokens in 1..512) { "maxOutputTokens must be between 1 and 512" }
        require(timeoutMillis in 1..120_000) { "timeoutMillis must be between 1 and 120000" }
        require(grammar == null || grammar.length in 1..16_384) { "grammar is outside its bound" }
        if (!libraryLoaded) {
            return NativeInferenceResult.Failure(
                NativeErrorCode.NATIVE_UNAVAILABLE,
                "MedGemma native library is unavailable",
                0,
            )
        }
        val started = System.nanoTime()
        val output = nativeInfer(prompt, maxOutputTokens, timeoutMillis, grammar)
        val latencyMillis = (System.nanoTime() - started) / 1_000_000
        if (output != null) return NativeInferenceResult.Success(output, latencyMillis)
        return NativeInferenceResult.Failure(
            NativeErrorCode.fromWireCode(nativeLastErrorCode()),
            nativeLastErrorMessage(),
            latencyMillis,
        )
    }

    fun cancel(): Boolean = libraryLoaded && nativeCancel()

    fun close() {
        if (libraryLoaded) nativeClose()
    }

    private fun unavailableOperation(): NativeOperationResult.Failure = NativeOperationResult.Failure(
        NativeErrorCode.NATIVE_UNAVAILABLE,
        "MedGemma native library is unavailable",
    )

    private external fun nativeIsAvailable(): Boolean

    private external fun nativeLoad(modelPath: String): Int

    private external fun nativeInfer(
        prompt: String,
        maxOutputTokens: Int,
        timeoutMillis: Long,
        grammar: String?,
    ): String?

    private external fun nativeCancel(): Boolean

    private external fun nativeClose()

    private external fun nativeLastErrorCode(): Int

    private external fun nativeLastErrorMessage(): String

    companion object {
        private val libraryLoaded = runCatching { System.loadLibrary("medgemma_jni") }.isSuccess
    }
}
