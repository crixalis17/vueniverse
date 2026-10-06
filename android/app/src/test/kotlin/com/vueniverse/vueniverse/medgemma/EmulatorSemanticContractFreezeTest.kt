package com.vueniverse.vueniverse.medgemma

import com.vueniverse.vueniverse.modelruntime.ExplainerRequest
import java.io.File
import java.nio.file.Files
import java.security.MessageDigest
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Host-only export. This class cannot load or infer a model, including accidentally. */
class EmulatorSemanticContractFreezeTest {
    private val families = listOf("supported_negative", "supported_positive", "scarce_complete", "context_blocked", "mixed_direction")
    private val intents = listOf("why_promoted", "disagreement", "observe_next")
    private val requestKeys = setOf("schemaVersion", "evidenceVersion", "findingState", "metricsJson", "promotionGatesJson", "exclusionsJson", "counterevidenceJson", "unresolvedInfluencesJson", "approvedNextObservations", "askIntent")

    @Test fun optInExportsActualProductionContractsWithoutModelOperations() {
        val input = System.getenv("VUENIVERSE_SEMANTIC_INPUT")
        val output = System.getenv("VUENIVERSE_SEMANTIC_OUTPUT")
        if (input == null && output == null) return // ordinary host suite remains read-only
        require(!input.isNullOrBlank() && !output.isNullOrBlank()) { "Both semantic export paths are required" }
        val inputFile = File(input)
        val outputDir = File(output)
        require(inputFile.isAbsolute && outputDir.isAbsolute) { "Export paths must be absolute" }
        require(inputFile.isFile && inputFile.length() in 1..1_048_576) { "Input must be a bounded regular file" }
        require(!outputDir.exists()) { "Refusing to replace an existing frozen directory" }
        val rows = validateRows(inputFile.readLines(Charsets.UTF_8))
        val rendered = rows.map(::render)
        assertEquals(rendered.map(::stable), rows.map(::render).map(::stable))
        val nativeFacts = nativeSourceFacts()
        // Complete validation precedes the only publication write. createDirectory is exclusive.
        require(outputDir.parentFile?.isDirectory == true) { "Export parent must already exist" }
        Files.createDirectory(outputDir.toPath())
        rendered.forEach { row ->
            val id = row.getString("case_id")
            for (backend in listOf("lora_v7", "vanilla")) {
                val contract = row.getJSONObject(backend)
                val prompt = contract.remove("prompt_utf8") as String
                val promptName = "$id.$backend.prompt.txt"
                File(outputDir, promptName).writeBytes(prompt.toByteArray(Charsets.UTF_8))
                contract.put("prompt_file", promptName)
                if (backend == "lora_v7") {
                    val grammar = contract.remove("grammar_utf8") as String
                    val grammarName = "$id.$backend.grammar.gbnf"
                    File(outputDir, grammarName).writeBytes(grammar.toByteArray(Charsets.UTF_8))
                    contract.put("grammar_file", grammarName)
                }
            }
        }
        File(outputDir, "rendered-contracts.jsonl").writeText(rendered.joinToString("\n", postfix = "\n", transform = ::stable), Charsets.UTF_8)
        File(outputDir, "host-export-metadata.json").writeText(stable(JSONObject().put("export_schema", "emulator-semantic-contracts-v1").put("case_count", 15).put("input_sha256", sha(inputFile.readBytes())).put("native_source_contract", nativeFacts).put("model_loaded", false).put("model_inference_performed", false).put("tokenizer_prompt_token_ids", JSONObject.NULL).put("tokenizer_prompt_token_count", JSONObject.NULL).put("context_fit_verified", false).put("native_grammar_initialization_verified", false).put("normal_candidate_activation", false).put("known_comparison_confound", "Production vanilla prompt v5 incorrectly defines positive_count as meetings showing the pattern; LoRA prompt v8 preserves strictly-positive meaning. These are actual but not semantically equivalent prompting conditions.")) + "\n", Charsets.UTF_8)
        rendered.forEach { row ->
            for (backend in listOf("lora_v7", "vanilla")) {
                val contract = row.getJSONObject(backend)
                assertEquals(contract.getString("prompt_sha256"), sha(File(outputDir, contract.getString("prompt_file")).readBytes()))
                if (backend == "lora_v7") assertEquals(contract.getString("grammar_sha256"), sha(File(outputDir, contract.getString("grammar_file")).readBytes()))
            }
        }
    }

    @Test fun productionRenderersAndDefaultBoundsAreDeterministic() {
        val row = fixtureRows().first()
        assertEquals(stable(render(row)), stable(render(row)))
        val result = render(row)
        assertEquals(8L, result.getJSONObject("lora_v7").getLong("prompt_version"))
        assertEquals(5L, result.getJSONObject("vanilla").getLong("prompt_version"))
        assertEquals(512, result.getJSONObject("lora_v7").getInt("max_output_tokens"))
        assertEquals(384, result.getJSONObject("vanilla").getInt("max_output_tokens"))
        assertEquals(120_000L, result.getJSONObject("vanilla").getLong("native_inference_timeout_ms"))
        assertTrue(result.getJSONObject("lora_v7").getString("prompt_utf8").endsWith(PhoneLoraExplainerContract.ASSISTANT_PREFILL))
        assertTrue(result.getJSONObject("lora_v7").getString("grammar_utf8").startsWith("root ::= json-char"))
    }

    @Test fun rejectsMissingDuplicateReorderedAndUnknownCaseIds() {
        val good = fixtureRows().map(::stable)
        validateRows(good)
        rejects { validateRows(good.dropLast(1)) }
        rejects { validateRows(good.dropLast(1) + good.first()) }
        rejects { validateRows(good.reversed()) }
        rejects { validateRows(good.toMutableList().also { it[0] = stable(JSONObject(it[0]).put("case_id", "unknown")) }) }
    }

    @Test fun rejectsUnexpectedRequestPropertiesVersionsAndOversizedPayloads() {
        val good = fixtureRows().map(::stable)
        fun altered(change: (JSONObject) -> Unit) = good.toMutableList().also { list ->
            val row = JSONObject(list[0]); change(row.getJSONObject("pigeon_request")); list[0] = stable(row)
        }
        rejects { validateRows(altered { it.put("unknown", true) }) }
        rejects { validateRows(altered { it.remove("metricsJson") }) }
        rejects { validateRows(altered { it.put("schemaVersion", "explainer-v7") }) }
        rejects { validateRows(altered { it.put("evidenceVersion", "not-a-sha") }) }
        rejects { validateRows(altered { it.put("metricsJson", "x".repeat(24_001)) }) }
        rejects { validateRows(altered { it.put("askIntent", "missing_evidence") }) }
        rejects { validateRows(altered { it.put("approvedNextObservations", JSONArray().put(1)) }) }
    }

    @Test fun hostNativeFactsIdentifyUnexecutedProductionStopAndTokenizationContract() {
        val facts = nativeSourceFacts()
        assertEquals(4096, facts.getInt("max_context_tokens"))
        assertEquals("greedy", facts.getString("sampling"))
        assertTrue(facts.getBoolean("tokenizer_add_special"))
        assertTrue(facts.getBoolean("tokenizer_parse_special"))
    }

    private fun validateRows(lines: List<String>): List<JSONObject> {
        require(lines.size == 15 && lines.all { it.isNotBlank() && it.toByteArray(Charsets.UTF_8).size <= 65_536 }) { "Exactly 15 bounded case lines required" }
        val rows = lines.map { line ->
            BoundedJsonParser.parse(line) // rejects duplicate keys, unlike JSONObject
            JSONObject(line)
        }
        val expected = families.flatMap { family -> intents.map { intent -> "${family}__$intent" } }
        require(rows.map { it.getString("case_id") } == expected) { "Case IDs/count/order differ from frozen development matrix" }
        rows.forEachIndexed { index, row ->
            require(row.getString("family_id") == families[index / 3] && row.getString("intent") == intents[index % 3]) { "Case labels disagree" }
            val raw = row.getJSONObject("pigeon_request")
            require(raw.keys().asSequence().toSet() == requestKeys) { "Pigeon properties must match the generated contract exactly" }
            requestKeys.filter { it != "approvedNextObservations" }.forEach { key ->
                require(raw.get(key) is String && raw.getString(key).length in 1..24_000) { "Invalid bounded request property: $key" }
            }
            require(raw.getString("schemaVersion") == "explainer-v8") { "Expected actual app projection v8" }
            require(raw.getString("evidenceVersion").matches(Regex("^[a-f0-9]{64}$"))) { "Expected actual run-bound evidence SHA" }
            require(raw.getString("askIntent") == row.getString("intent")) { "Request intent differs" }
            val observations = raw.getJSONArray("approvedNextObservations")
            require(observations.length() <= 3 && (0 until observations.length()).all { observations.get(it) is String }) { "Invalid observation list" }
            val request = request(raw)
            PhoneLoraExplainerContract.format(request)
            PhoneLoraExplainerContract.grammar(request)
            vanillaPrompt(request)
        }
        return rows
    }

    private fun request(raw: JSONObject) = ExplainerRequest(raw.getString("schemaVersion"), raw.getString("evidenceVersion"), raw.getString("findingState"), raw.getString("metricsJson"), raw.getString("promotionGatesJson"), raw.getString("exclusionsJson"), raw.getString("counterevidenceJson"), raw.getString("unresolvedInfluencesJson"), raw.getJSONArray("approvedNextObservations").let { a -> (0 until a.length()).map(a::getString) }, raw.getString("askIntent"))

    private fun render(row: JSONObject): JSONObject {
        val request = request(row.getJSONObject("pigeon_request"))
        val lora = PhoneLoraExplainerContract.format(request)
        val vanilla = vanillaPrompt(request)
        val grammar = PhoneLoraExplainerContract.grammar(request)
        return JSONObject().put("case_id", row.getString("case_id")).put("family_id", row.getString("family_id")).put("intent", row.getString("intent")).put("evidence_version", request.evidenceVersion)
            .put("lora_v7", runtimeDefaults(true).put("prompt_utf8", lora).put("prompt_sha256", sha(lora.toByteArray(Charsets.UTF_8))).put("prompt_bytes", lora.toByteArray(Charsets.UTF_8).size).put("prompt_utf16_code_units", lora.length).put("grammar_utf8", grammar).put("grammar_sha256", sha(grammar.toByteArray(Charsets.UTF_8))).put("grammar_bytes", grammar.toByteArray(Charsets.UTF_8).size).put("grammar_utf16_code_units", grammar.length).put("assistant_prefill", PhoneLoraExplainerContract.ASSISTANT_PREFILL).put("generated_continuation_prefix_reassembled", true))
            .put("vanilla", runtimeDefaults(false).put("prompt_utf8", vanilla).put("prompt_sha256", sha(vanilla.toByteArray(Charsets.UTF_8))).put("prompt_bytes", vanilla.toByteArray(Charsets.UTF_8).size).put("prompt_utf16_code_units", vanilla.length).put("grammar_file", JSONObject.NULL).put("grammar_sha256", JSONObject.NULL).put("assistant_prefill", "").put("generated_continuation_prefix_reassembled", false))
    }

    private fun runtime() = MedGemmaRuntime(ModelArtifactValidator { error("Artifact validation forbidden in host-only freeze") }, object : MedGemmaNativeAdapter {
        override fun isAvailable(): Boolean = error("Native availability forbidden")
        override fun load(modelPath: String): NativeOperationResult = error("Native load forbidden")
        override fun infer(prompt: String, maxOutputTokens: Int, timeoutMillis: Long, grammar: String?): NativeInferenceResult = error("Native inference forbidden")
        override fun cancel() = false
        override fun close() = Unit
    })

    private fun vanillaPrompt(request: ExplainerRequest): String {
        val runtime = runtime()
        return try {
            val method = MedGemmaRuntime::class.java.getDeclaredMethod("formatPrompt", ExplainerRequest::class.java).apply { isAccessible = true }
            method.invoke(runtime, request) as String
        } finally { runtime.close() }
    }

    private fun runtimeDefaults(lora: Boolean): JSONObject {
        val runtime = MedGemmaRuntime(ModelArtifactValidator { error("No artifact access") }, object : MedGemmaNativeAdapter {
            override fun isAvailable(): Boolean = error("No availability access")
            override fun load(modelPath: String): NativeOperationResult = error("No model load")
            override fun infer(prompt: String, maxOutputTokens: Int, timeoutMillis: Long, grammar: String?): NativeInferenceResult = error("No inference")
            override fun cancel() = false
            override fun close() = Unit
        }, useLoraContract = lora)
        fun field(name: String): Any = requireNotNull(MedGemmaRuntime::class.java.getDeclaredField(name).apply { isAccessible = true }.get(runtime))
        val mapper = field("mapper")
        val promptVersion = MedGemmaRuntimeResultMapper::class.java.getDeclaredField("promptVersion").apply { isAccessible = true }.get(mapper)
        return try { JSONObject().put("prompt_version", promptVersion).put("max_output_tokens", field("maxOutputTokens")).put("native_inference_timeout_ms", field("timeoutMillis")).put("timeout_scope", "Native inference only; model load is outside this bound") } finally { runtime.close() }
    }

    private fun nativeSourceFacts(): JSONObject {
        val file = File("src/main/cpp/medgemma_jni.cpp")
        require(file.isFile) { "Run the host test in the Android app Gradle working directory" }
        val source = file.readText(Charsets.UTF_8)
        val maxContext = Regex("constexpr int MAX_CONTEXT_TOKENS = ([0-9]+);").find(source)?.groupValues?.get(1)?.toInt() ?: error("Context bound changed")
        require(source.contains("prompt.size(), nullptr, 0, true, true") && Regex("prompt_tokens.size\\(\\),\\s*true,\\s*true").containsMatchIn(source) && source.contains("llama_sampler_init_greedy()")) { "Native tokenizer/sampling contract changed; review freeze tooling" }
        require(source.contains("llama_vocab_is_eog(vocab, token)") && source.contains("while (generated < max_output_tokens)") && source.contains("abort_state.deadline") && source.contains("g_cancelled.load()")) { "Native stop contract changed" }
        return JSONObject().put("source_file", "android/app/src/main/cpp/medgemma_jni.cpp").put("source_sha256", sha(file.readBytes())).put("max_context_tokens", maxContext).put("tokenizer_add_special", true).put("tokenizer_parse_special", true).put("sampling", "greedy").put("grammar_root", "root").put("stop_conditions", JSONArray(listOf("vocabulary_eog", "max_output_tokens", "native_inference_timeout", "cancellation", "decode_error"))).put("json_closure_is_stop_condition", false).put("validation_level", "Source inspection assertions only; no native grammar, tokenizer, or model execution")
    }

    private fun fixtureRows(): List<JSONObject> = families.flatMap { family -> intents.map { intent ->
        JSONObject().put("case_id", "${family}__$intent").put("family_id", family).put("intent", intent).put("pigeon_request", JSONObject().put("schemaVersion", "explainer-v8").put("evidenceVersion", "a".repeat(64)).put("findingState", "developing").put("metricsJson", "{\"included_count\":2,\"median_difference_bpm\":10}").put("promotionGatesJson", "{}").put("exclusionsJson", "{}").put("counterevidenceJson", "{}").put("unresolvedInfluencesJson", "{}").put("approvedNextObservations", JSONArray(listOf("Observe the next similar event."))).put("askIntent", intent))
    } }

    private fun rejects(body: () -> Unit) { var rejected = false; try { body() } catch (_: Exception) { rejected = true }; assertTrue("Invalid frozen input must be rejected", rejected) }
    private fun sha(bytes: ByteArray) = MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }
    private fun stable(value: Any?): String = when (value) {
        null, JSONObject.NULL -> "null"
        is JSONObject -> value.keys().asSequence().toList().sorted().joinToString(",", "{", "}") { JSONObject.quote(it) + ":" + stable(value.get(it)) }
        is JSONArray -> (0 until value.length()).joinToString(",", "[", "]") { stable(value.get(it)) }
        is String -> JSONObject.quote(value)
        else -> value.toString()
    }
}
