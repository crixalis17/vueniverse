package com.vueniverse.vueniverse.medgemma

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ModelOutputStructureDiagnosticsTest {
    @Test
    fun incompleteStructureReportsOnlyMarkersAndCompletedValueLengths() {
        val diagnostic = ModelOutputStructureDiagnostics.describe(
            """{"summary":"secret","paragraphs":[{"text":"private paragraph"}],"uncertainty":"unfinished""",
        )
        assertTrue(diagnostic.contains("\"strict_json_valid\":false"))
        assertTrue(diagnostic.contains("\"known_schema_keys\":[]"))
        assertTrue(diagnostic.contains("\"lexical_markers_are_not_strict_schema\":true"))
        assertTrue(diagnostic.contains("\"summary\":[6]"))
        assertTrue(diagnostic.contains("\"text\":[17]"))
        assertFalse(diagnostic.contains("secret"))
        assertFalse(diagnostic.contains("private paragraph"))
        assertFalse(diagnostic.contains("unfinished"))
    }

    @Test
    fun validTrainingSchemaKeysAreExposedWithoutProse() {
        val diagnostic = ModelOutputStructureDiagnostics.describe(
            """{"summary":"private health prose","paragraphs":[],"schema_version":2,"unresolved_influence_ids":[],"next_observation_id":null,"context_reference_id":"private-id","uncertainty":"private uncertainty"}""",
        )
        assertTrue(diagnostic.contains("\"strict_json_valid\":true"))
        assertTrue(diagnostic.contains("\"paragraphs\""))
        assertFalse(diagnostic.contains("private"))
    }

    @Test
    fun unknownKeysAndMalformedThoughtNeverLeak() {
        val valid = ModelOutputStructureDiagnostics.describe("""{"private_contact_name":"private text"}""")
        assertTrue(valid.contains("\"unknown_key_count\":1"))
        assertFalse(valid.contains("private"))
        val malformed = ModelOutputStructureDiagnostics.describe("<|channel>thought secret medical reasoning")
        assertTrue(malformed.contains("\"strict_json_valid\":false"))
        assertTrue(malformed.contains("\"has_thought_control_marker\":true"))
        assertFalse(malformed.contains("secret"))
        assertFalse(malformed.contains("reasoning"))
    }
}
