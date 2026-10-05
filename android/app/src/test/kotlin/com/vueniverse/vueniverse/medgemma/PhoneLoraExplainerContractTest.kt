package com.vueniverse.vueniverse.medgemma

import com.vueniverse.vueniverse.modelruntime.ExplainerRequest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

class PhoneLoraExplainerContractTest {
    @Test fun appNullAndInsufficientEnumSpellingsMapWithoutChangingState() {
        for ((app, trained) in mapOf("nullFinding" to "null", "insufficientData" to "insufficient_data", "null" to "null", "insufficient_data" to "insufficient_data")) {
            val prompt = PhoneLoraExplainerContract.format(request(state = app))
            val evidence = BoundedJsonParser.parse(prompt.substringAfter("EvidenceBundle:\n").substringBefore("\nAllowed citation IDs:")) as JsonValue.ObjectValue
            assertEquals(JsonValue.StringValue(trained), evidence.values["finding_state"])
        }
        reject { PhoneLoraExplainerContract.format(request(state = "unsupported_state")) }
    }
    @Test fun promptUsesV7ShapeExactNumbersAndAuthoritativePrefill() {
        val prompt = PhoneLoraExplainerContract.format(request())
        assertEquals(7L, PhoneLoraExplainerContract.PROMPT_VERSION)
        assertTrue(prompt.endsWith("<start_of_turn>model\n" + PhoneLoraExplainerContract.ASSISTANT_PREFILL))
        val evidence = BoundedJsonParser.parse(prompt.substringAfter("EvidenceBundle:\n").substringBefore("\nAllowed citation IDs:")) as JsonValue.ObjectValue
        assertEquals(JsonValue.StringValue("explain"), evidence.values["ask_intent"])
        assertFalse(evidence.values.containsKey("context_reference"))
        val metrics = (evidence.values.getValue("metrics") as JsonValue.ArrayValue).values.map { it as JsonValue.ObjectValue }
        assertTrue(metrics.any { it.values["citation_id"] == JsonValue.StringValue("completeness") && it.values["value_text"] == JsonValue.StringValue("0.8500") })
        assertTrue(metrics.any { it.values["citation_id"] == JsonValue.StringValue("median_difference_bpm") && it.values["value_text"] == JsonValue.StringValue("-7") })
        assertFalse(metrics.any { it.values["citation_id"] == JsonValue.StringValue("finding_state") })
        BoundedJsonParser.parse(prompt.substringAfter("\nRequired JSON schema:\n").substringBefore("\n<end_of_turn>"))
    }
    @Test fun unsafeSemanticAliasesAndAbsoluteBoundsAreNotProjected() {
        val prompt = PhoneLoraExplainerContract.format(request())
        assertTrue(prompt.contains("\"citation_id\":\"positive_count\""))
        assertTrue(prompt.contains("strictly positive"))
        assertFalse(prompt.contains("\"citation_id\":\"consistent_count\""))
        assertFalse(prompt.contains("\"citation_id\":\"effect_range\""))
        assertFalse(prompt.contains("effect_lower_bpm"))
        assertFalse(prompt.contains("unresolved_influences\""))
    }
    @Test fun approvedIdMapsToExactOriginalTextAndParagraphTextIsPreserved() {
        val output = PhoneLoraExplainerContract.decode(validOutput(), request())
        assertEquals("Record caffeine intake and the time covered.", output.approvedNextObservation)
        assertEquals(listOf("caffeine_timing"), output.citedUnresolvedInfluences)
        val paragraphs = BoundedJsonParser.parse(output.citedParagraphsJson) as JsonValue.ArrayValue
        assertEquals(JsonValue.StringValue("  Exactly 8 windows were compared.  "), (paragraphs.values.first() as JsonValue.ObjectValue).values["text"])
        assertEquals(JsonValue.StringValue("included_count"), ((paragraphs.values.first() as JsonValue.ObjectValue).values["citations"] as JsonValue.ArrayValue).values.single())
    }
    @Test fun nullOrAbsentContextIsAcceptedButNeverInvented() {
        assertNull(PhoneLoraExplainerContract.decode(validOutput(next = "null"), request()).approvedNextObservation)
        PhoneLoraExplainerContract.decode(validOutput().replace(",\"context_reference_id\":null", ""), request())
        reject { PhoneLoraExplainerContract.decode(validOutput().replace("\"context_reference_id\":null", "\"context_reference_id\":\"ctx_guessed\""), request()) }
    }
    @Test fun mapsOnlySupportedAppIntents() {
        for ((app, trained) in mapOf("explain" to "explain", "why_promoted" to "explain", "missing_evidence" to "what_is_missing", "disagreement" to "what_disagrees", "observe_next" to "observe_next")) {
            assertTrue(PhoneLoraExplainerContract.format(request(intent = app)).contains("\"ask_intent\":\"$trained\""))
        }
        reject { PhoneLoraExplainerContract.format(request(intent = "unsupported")) }
    }
    @Test fun rejectsUnknownCitationInfluenceAndObservation() {
        reject { PhoneLoraExplainerContract.decode(validOutput().replace("[\"included_count\"]", "[\"consistent_count\"]"), request()) }
        reject { PhoneLoraExplainerContract.decode(validOutput().replace("[\"caffeine_timing\"]", "[\"guessed_cause\"]"), request()) }
        reject { PhoneLoraExplainerContract.decode(validOutput(next = "\"repeat_window_check\""), request()) }
        reject { PhoneLoraExplainerContract.decode(validOutput(next = "\"Record caffeine intake and the time covered.\""), request()) }
    }
    @Test fun rejectsDuplicateIdsAndDuplicateJsonKeys() {
        reject { PhoneLoraExplainerContract.decode(validOutput().replace("[\"included_count\"]", "[\"included_count\",\"included_count\"]"), request()) }
        reject { PhoneLoraExplainerContract.decode(validOutput().replace("[\"caffeine_timing\"]", "[\"caffeine_timing\",\"caffeine_timing\"]"), request()) }
        reject { PhoneLoraExplainerContract.decode(validOutput().replace("\"schema_version\":2", "\"schema_version\":2,\"schema_version\":2"), request()) }
        reject { PhoneLoraExplainerContract.format(request(influences = "[\"caffeine_timing\",\"caffeine_timing\"]")) }
    }
    @Test fun rejectsWrongSchemaUnexpectedKeysAndMissingRequiredKeys() {
        reject { PhoneLoraExplainerContract.decode(validOutput().replace("\"schema_version\":2", "\"schema_version\":3"), request()) }
        reject { PhoneLoraExplainerContract.decode(validOutput().replace("\"schema_version\":2", "\"schema_version\":2.0"), request()) }
        reject { PhoneLoraExplainerContract.decode(validOutput().replace("\"schema_version\":2", "\"schema_version\":2,\"finding_state\":\"supported\""), request()) }
        reject { PhoneLoraExplainerContract.decode(validOutput().replace("\"summary\":\"A limited comparison.\",", ""), request()) }
    }
    @Test fun rejectsTruncationThoughtTextFencesAndTrailingObjects() {
        for (raw in listOf(validOutput().dropLast(1), "<think>reasoning</think>" + validOutput(), "```json\n" + validOutput() + "\n```", validOutput() + "{}")) {
            reject { PhoneLoraExplainerContract.decode(raw, request()) }
        }
    }
    @Test fun rejectsEmptyOversizedAndIncorrectlyTypedParagraphs() {
        reject { PhoneLoraExplainerContract.decode(validOutput().replace("  Exactly 8 windows were compared.  ", ""), request()) }
        reject { PhoneLoraExplainerContract.decode(validOutput().replace("A limited comparison.", "x".repeat(181)), request()) }
        reject { PhoneLoraExplainerContract.decode(validOutput().replace("[\"included_count\"]", "[]"), request()) }
        reject { PhoneLoraExplainerContract.decode(validOutput().replace("\"text\":", "\"unknown\":0,\"text\":"), request()) }
    }
    @Test fun rejectsInvalidCoreNumericAndObservationBoundsWithoutImputation() {
        for (metrics in listOf("{}", "{\"included_count\":\"8\"}", "{\"included_count\":-1}", "{\"included_count\":1.5}", "{\"completeness\":85}", "{\"median_difference_bpm\":1e999}")) {
            reject { PhoneLoraExplainerContract.format(request(metrics = metrics)) }
        }
        reject { PhoneLoraExplainerContract.format(request(observations = listOf("same", "same"))) }
        reject { PhoneLoraExplainerContract.format(request(observations = listOf("x".repeat(181)))) }
        reject { PhoneLoraExplainerContract.format(request(observations = listOf("one", "two", "three", "four"))) }
    }
    @Test fun observationTextEscapesRoundTripWithoutRewriting() {
        val exact = "Log \"caffeine\"\nwith a time \\ note."
        val output = PhoneLoraExplainerContract.decode(validOutput(), request(observations = listOf(exact)))
        assertEquals(exact, output.approvedNextObservation)
        val prompt = PhoneLoraExplainerContract.format(request(observations = listOf(exact)))
        val bundle = BoundedJsonParser.parse(prompt.substringAfter("EvidenceBundle:\n").substringBefore("\nAllowed citation IDs:")) as JsonValue.ObjectValue
        assertEquals(JsonValue.StringValue(exact), (bundle.values["approved_next_observations"] as JsonValue.ObjectValue).values["observation_1"])
    }
    @Test fun grammarConstrainsContinuationNotAuthoritativePrefix() {
        val grammar = PhoneLoraExplainerContract.grammar(request())
        assertTrue(grammar.startsWith("root ::= json-char{1,180}"))
        assertFalse(grammar.contains("schema_version"))
        assertFalse(grammar.contains(PhoneLoraExplainerContract.ASSISTANT_PREFILL))
        assertTrue(grammar.contains("paragraph (ws \",\" ws paragraph){0,1}"))
        assertTrue(grammar.contains("citation-id){0,2}"))
        assertTrue(grammar.contains("json-char{1,280}"))
        assertTrue(grammar.contains("short-string ::= \"\\\"\" json-char{1,180}"))
        assertTrue(grammar.contains("ws ::= [ \\t\\n\\r]{0,3}"))
        assertFalse(grammar.contains("*"))
        assertTrue(grammar.length <= 16_384)
    }
    @Test fun grammarAllowListsContainOnlyAvailableIdsNotPrivateValuesOrTexts() {
        val privateObservation = "Private journal text must never enter grammar."
        val grammar = PhoneLoraExplainerContract.grammar(request(observations = listOf(privateObservation)))
        val citations = grammar.lineSequence().first { it.startsWith("citation-id ::=") }
        assertTrue(citations.contains("included_count"))
        assertTrue(citations.contains("positive_count"))
        assertFalse(citations.contains("consistent_count"))
        assertFalse(citations.contains("effect_range"))
        assertFalse(citations.contains("effect_lower_bpm"))
        assertFalse(grammar.contains(privateObservation))
        assertFalse(grammar.contains("0.8500"))
        assertFalse(grammar.contains("fixture-evidence-v1"))
        assertTrue(grammar.contains("observation_1"))
        assertFalse(grammar.contains("observation_2"))
        assertTrue(grammar.contains("caffeine_timing"))
        assertFalse(grammar.contains("recent_exercise"))
        assertTrue(grammar.contains("context_reference_id"))
    }
    @Test fun grammarHandlesEmptyAllowListsWithoutAnEmptyAlternativeOrInventedIds() {
        val grammar = PhoneLoraExplainerContract.grammar(request(influences = "[]", observations = emptyList()))
        assertTrue(grammar.contains("influences ::= \"[\" ws \"]\""))
        assertTrue(grammar.contains("next-observation ::= \"null\"\n"))
        assertFalse(grammar.contains("influence-id ::="))
        assertFalse(grammar.contains("observation_1"))
    }

    private fun request(
        intent: String = "why_promoted",
        state: String = "developing",
        metrics: String = "{\"included_count\":8,\"positive_count\":2,\"median_difference_bpm\":-7,\"completeness\":0.8500,\"finding_state\":1,\"unresolved_influences\":3,\"effect_lower_bpm\":5,\"effect_upper_bpm\":12}",
        influences: String = "{\"caffeine_timing\":\"Possible, not established.\"}",
        observations: List<String> = listOf("Record caffeine intake and the time covered."),
    ) = ExplainerRequest(
        schemaVersion = "explainer-v6",
        evidenceVersion = "fixture-evidence-v1",
        findingState = state,
        metricsJson = metrics,
        promotionGatesJson = "{}",
        exclusionsJson = "[]",
        counterevidenceJson = "{}",
        unresolvedInfluencesJson = influences,
        approvedNextObservations = observations,
        askIntent = intent,
    )
    private fun validOutput(next: String = "\"observation_1\"") = "{\"schema_version\":2,\"summary\":\"A limited comparison.\",\"paragraphs\":[{\"text\":\"  Exactly 8 windows were compared.  \",\"citations\":[\"included_count\"]}],\"uncertainty\":\"This cannot establish a cause.\",\"unresolved_influence_ids\":[\"caffeine_timing\"],\"context_reference_id\":null,\"next_observation_id\":$next}"
    private fun reject(block: () -> Unit) {
        try { block() } catch (_: IllegalArgumentException) { return } catch (_: IllegalStateException) { return }
        fail("Expected strict contract rejection")
    }
}
