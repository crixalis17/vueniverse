package com.vueniverse.vueniverse.medgemma

/** No response text or unknown keys may leave this structural fixture diagnostic. */
internal object ModelOutputStructureDiagnostics {
    private val publicSchemaKeys = setOf(
        "summary", "uncertainty", "schema_version", "paragraphs",
        "context_reference_id", "next_observation_id", "unresolved_influence_ids",
        "citedParagraphsJson", "citedUnresolvedInfluences", "approvedNextObservation",
    )

    fun describe(raw: String): String {
        val parsed = runCatching { BoundedJsonParser.parse(raw) }.getOrNull()
        val keys = (parsed as? JsonValue.ObjectValue)?.values?.keys.orEmpty()
        val safeKeys = keys.intersect(publicSchemaKeys).sorted()
            .joinToString(",") { "\"$it\"" }
        // Lexical markers can exist in incomplete output; never equate them
        // with parsed top-level keys or accepted schema.
        val markers = publicSchemaKeys.filter { key ->
            Regex("\"${Regex.escape(key)}\"\\s*:").containsMatchIn(raw)
        }.sorted().joinToString(",") { "\"$it\"" }
        val lengths = listOf("summary", "uncertainty", "text").joinToString(",") { key ->
            val values = Regex("\"${Regex.escape(key)}\"\\s*:\\s*(\"(?:\\\\.|[^\"\\\\])*\")")
                .findAll(raw).take(32).mapNotNull { match ->
                    (runCatching { BoundedJsonParser.parse(match.groupValues[1]) }.getOrNull()
                        as? JsonValue.StringValue)?.value?.length
                }.joinToString(",")
            "\"$key\":[$values]"
        }
        val trimmed = raw.trim()
        return "{\"strict_json_valid\":${parsed != null}," +
            "\"root_object\":${parsed is JsonValue.ObjectValue}," +
            "\"known_schema_keys\":[$safeKeys]," +
            "\"known_schema_key_lexical_markers\":[$markers]," +
            "\"lexical_markers_are_not_strict_schema\":true," +
            "\"completed_string_value_character_lengths\":{$lengths}," +
            "\"unknown_key_count\":${keys.count { it !in publicSchemaKeys }}," +
            "\"output_characters\":${raw.length}," +
            "\"starts_object\":${trimmed.startsWith("{")}," +
            "\"ends_object\":${trimmed.endsWith("}")}," +
            "\"has_markdown_fence\":${raw.contains("```")}," +
            "\"has_thought_control_marker\":${raw.contains("<|channel>thought")}," +
            "\"has_turn_control_marker\":${raw.contains("<start_of_turn>") || raw.contains("<end_of_turn>")}}"
    }
}
