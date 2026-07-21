package com.vueniverse.vueniverse.medgemma

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class NativeMedGemmaContractTest {
    @Test
    fun everyWireErrorCodeMapsDeterministically() {
        NativeErrorCode.entries.filterNot { it == NativeErrorCode.UNKNOWN }.forEach { code ->
            assertEquals(code, NativeErrorCode.fromWireCode(code.wireCode))
        }
        assertEquals(NativeErrorCode.UNKNOWN, NativeErrorCode.fromWireCode(999))
    }

    @Test
    fun absentJvmNativeLibraryIsABoundedUnavailableState() {
        val runtime = NativeMedGemma()

        assertFalse(runtime.isAvailable())
        val result = runtime.load("/fictional/model.gguf")
        assertTrue(result is NativeOperationResult.Failure)
        assertEquals(
            NativeErrorCode.NATIVE_UNAVAILABLE,
            (result as NativeOperationResult.Failure).code,
        )
    }

    @Test(expected = IllegalArgumentException::class)
    fun outputTokenLimitIsEnforcedBeforeNativeCall() {
        NativeMedGemma().infer("bounded", maxOutputTokens = 513, timeoutMillis = 1_000)
    }
}
