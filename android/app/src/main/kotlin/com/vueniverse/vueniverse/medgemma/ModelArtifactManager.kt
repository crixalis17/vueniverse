package com.vueniverse.vueniverse.medgemma

import com.vueniverse.vueniverse.BuildConfig
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.security.MessageDigest

data class ExpectedModelArtifact(
    val modelId: String,
    val modelRevision: String,
    val quantization: String,
    val fileName: String,
    val sizeBytes: Long,
    val sha256: String,
) {
    init {
        require(fileName.isNotBlank() && '/' !in fileName && '\\' !in fileName && fileName != "." && fileName != "..") {
            "model filename must be a plain filename"
        }
        require(sizeBytes > 0) { "model size must be positive" }
        require(sha256.matches(Regex("^[a-f0-9]{64}$"))) { "model SHA-256 must be lowercase hexadecimal" }
    }
}

sealed interface ArtifactValidationResult {
    data class Valid(
        val file: File,
        val artifact: ExpectedModelArtifact,
    ) : ArtifactValidationResult

    data class Missing(val file: File) : ArtifactValidationResult

    data class Unreadable(val file: File) : ArtifactValidationResult

    data class SizeMismatch(
        val file: File,
        val expectedBytes: Long,
        val actualBytes: Long,
    ) : ArtifactValidationResult

    data class ChecksumMismatch(
        val file: File,
        val expectedSha256: String,
        val actualSha256: String,
    ) : ArtifactValidationResult

    data class IoFailure(
        val file: File,
        val reason: String,
    ) : ArtifactValidationResult
}

class ModelArtifactLocator(
    private val appPrivateRoot: File,
) {
    fun modelDirectory(): File = File(appPrivateRoot, "medgemma-models")

    fun locate(artifact: ExpectedModelArtifact): File = File(modelDirectory(), artifact.fileName)
}

class ModelArtifactManager(
    private val locator: ModelArtifactLocator,
    private val bufferSizeBytes: Int = DEFAULT_BUFFER_SIZE_BYTES,
) {
    init {
        require(bufferSizeBytes in 4_096..1_048_576) { "checksum buffer is outside the safe range" }
    }

    fun validate(artifact: ExpectedModelArtifact): ArtifactValidationResult {
        return validateFile(locator.locate(artifact), artifact)
    }

    fun validateFile(file: File, artifact: ExpectedModelArtifact): ArtifactValidationResult {
        if (!file.exists() || !file.isFile) return ArtifactValidationResult.Missing(file)
        if (!file.canRead()) return ArtifactValidationResult.Unreadable(file)
        val actualSize = file.length()
        if (actualSize != artifact.sizeBytes) {
            return ArtifactValidationResult.SizeMismatch(file, artifact.sizeBytes, actualSize)
        }
        return try {
            val actualHash = sha256(file)
            if (actualHash == artifact.sha256) {
                ArtifactValidationResult.Valid(file, artifact)
            } else {
                ArtifactValidationResult.ChecksumMismatch(file, artifact.sha256, actualHash)
            }
        } catch (error: IOException) {
            ArtifactValidationResult.IoFailure(file, error.message ?: "model file could not be read")
        } catch (error: SecurityException) {
            ArtifactValidationResult.Unreadable(file)
        }
    }

    private fun sha256(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        FileInputStream(file).use { input ->
            val buffer = ByteArray(bufferSizeBytes)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                if (count > 0) digest.update(buffer, 0, count)
            }
        }
        return digest.digest().joinToString(separator = "") { byte -> "%02x".format(byte) }
    }

    companion object {
        private const val DEFAULT_BUFFER_SIZE_BYTES = 64 * 1_024

        val selectedArtifact: ExpectedModelArtifact
            get() = artifactForVariant(BuildConfig.VUENIVERSE_MODEL_VARIANT)

        fun artifactForVariant(variant: String): ExpectedModelArtifact = when (variant) {
            "vanilla" -> MEDGEMMA_1_5_Q4_K_M
            "lora-v7" -> MEDGEMMA_1_5_LORA_V7_Q4_K_M
            else -> throw IllegalArgumentException("unknown model variant")
        }

        fun runtimeModelName(artifact: ExpectedModelArtifact): String = when (artifact) {
            MEDGEMMA_1_5_Q4_K_M -> "google/medgemma-1.5-4b-it-Q4_K_M"
            else -> "${artifact.modelId}-${artifact.quantization}@${artifact.modelRevision}"
        }

        fun downloadWorkName(artifact: ExpectedModelArtifact): String =
            "medgemma-model-${artifact.modelRevision}-${artifact.quantization.lowercase()}"

        val MEDGEMMA_1_5_Q4_K_M = ExpectedModelArtifact(
            modelId = "unsloth/medgemma-1.5-4b-it-GGUF",
            modelRevision = "1fe03a2916e0a4ed250fdeedc3e56a94f3bf2a30",
            quantization = "Q4_K_M",
            fileName = "medgemma-1.5-4b-it-Q4_K_M.gguf",
            sizeBytes = 2_489_894_976,
            sha256 = "b31becdf4f39561800505514cce67681604fe449d04dd35c8c92fd7848c6d7bd",
        )

        // Inactive candidate: activate only with matching download, runtime metadata,
        // cache identity, and physical-device validation. Never alias the vanilla pin.
        val MEDGEMMA_1_5_LORA_V7_Q4_K_M = ExpectedModelArtifact(
            modelId = "vueniverse/medgemma-1.5-4b-it-lora-v7",
            modelRevision = "lora-v7-q4-dd9c2a212672a5bb",
            quantization = "Q4_K_M",
            fileName = "medgemma-1.5-4b-it-lora-v7-Q4_K_M.gguf",
            sizeBytes = 2_489_893_568,
            sha256 = "dd9c2a212672a5bb18affbc344a4c0fcf4e9000b3b5155d6fdfe9a8104bad234",
        )
    }
}
