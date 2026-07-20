import json

import pytest

from vueniverse_medgemma.evaluation import (
    deterministic_explainer_fallback,
    evaluate_explainer_output,
)
from vueniverse_medgemma.fixtures import evaluation_cases, supported_request
from vueniverse_medgemma.schemas import (
    ExplainerRequest,
    explainer_model_view,
    explainer_output_schema,
)


def _valid_output() -> dict:
    return {
        "schema_version": 2,
        "summary": "Heart rate showed the same pattern in 6 of 8 meetings.",
        "paragraphs": [
            {
                "text": "The usual difference was +11 beats per minute across 6 of 8 meetings.",
                "citations": ["median_difference", "consistent_count"],
            }
        ],
        "uncertainty": (
            "This pattern does not show why the change happened, and caffeine "
            "context is still missing."
        ),
        "unresolved_influence_ids": ["caffeine_timing"],
        "next_observation_id": "quiet_buffer_test",
    }


def test_all_model_cases_are_fictional_and_versioned() -> None:
    cases = evaluation_cases()

    assert len(cases) == 17
    assert all(case.request.evidence_version.startswith("fictional-") for case in cases)
    assert {case.request.finding_state for case in cases} >= {
        "supported",
        "null",
        "contradictory",
        "insufficient_data",
    }
    by_state = {case.request.finding_state: case.request for case in cases}
    null_values = {metric.citation_id: metric.value_text for metric in by_state["null"].metrics}
    insufficient_values = {
        metric.citation_id: metric.value_text for metric in by_state["insufficient_data"].metrics
    }
    assert null_values["median_difference"] == "+1 bpm"
    assert insufficient_values["completeness"] == "42%"


def test_valid_cited_output_passes() -> None:
    request = supported_request(question="Explain this.")
    result = evaluate_explainer_output(json.dumps(_valid_output()), request)

    assert result.passed
    assert result.schema_valid


def test_unsupported_numeric_prose_is_rejected() -> None:
    request = supported_request(question="Explain this.")
    output = _valid_output()
    output["paragraphs"][0]["text"] = "The median matched difference was +19 bpm."

    result = evaluate_explainer_output(json.dumps(output), request)

    assert not result.passed
    assert result.schema_valid
    assert "paragraph_0_unsupported_numbers:['+19']" in result.errors


def test_exact_cited_numbers_are_allowed() -> None:
    request = supported_request(question="Explain this.")

    result = evaluate_explainer_output(json.dumps(_valid_output()), request)

    assert result.passed


def test_request_schema_enumerates_allowed_identifiers() -> None:
    request = supported_request(question="Explain this.")
    schema = explainer_output_schema(request)

    citation_items = schema["$defs"]["CitedParagraph"]["properties"]["citations"]["items"]
    influence_items = schema["properties"]["unresolved_influence_ids"]["items"]
    next_observation = schema["properties"]["next_observation_id"]["anyOf"][0]

    assert citation_items["enum"] == [metric.citation_id for metric in request.metrics]
    assert influence_items["enum"] == request.unresolved_influence_ids
    assert next_observation["enum"] == list(request.approved_next_observations)


def test_model_view_includes_safe_values_but_omits_raw_counterevents() -> None:
    request = supported_request(question="Explain this.")
    view = explainer_model_view(request)
    serialized = json.dumps(view)

    assert view["metrics"][0]["value_text"] == "12"
    assert "meeting_04" not in serialized
    assert view["counterevidence_available"] is True


def test_deterministic_fallback_passes_every_fixture() -> None:
    for case in evaluation_cases():
        raw = deterministic_explainer_fallback(case.request).model_dump_json()
        result = evaluate_explainer_output(raw, case.request)

        assert result.passed, (case.case_id, result.errors)


def test_empty_optional_ids_generate_a_valid_restricted_schema() -> None:
    payload = supported_request(question="Explain this.").model_dump()
    payload["unresolved_influence_ids"] = []
    payload["approved_next_observations"] = {}
    request = ExplainerRequest.model_validate(payload)

    schema = explainer_output_schema(request)

    assert schema["properties"]["unresolved_influence_ids"]["maxItems"] == 0
    assert schema["properties"]["next_observation_id"]["type"] == "null"


def test_duplicate_metric_citation_ids_are_rejected() -> None:
    payload = supported_request(question="Explain this.").model_dump()
    payload["metrics"].append(payload["metrics"][0])

    with pytest.raises(ValueError, match="citation IDs must be unique"):
        ExplainerRequest.model_validate(payload)


def test_model_question_is_bounded() -> None:
    payload = supported_request(question="Explain this.").model_dump()
    payload["user_question"] = "x" * 501

    with pytest.raises(ValueError):
        ExplainerRequest.model_validate(payload)


def test_fake_citation_is_rejected() -> None:
    request = supported_request(question="Explain this.")
    output = _valid_output()
    output["paragraphs"][0]["citations"] = ["secret_raw_record"]

    result = evaluate_explainer_output(json.dumps(output), request)

    assert not result.passed
    assert "unknown_citations" in result.errors[0]


def test_negated_diagnostic_boundary_is_not_a_false_positive() -> None:
    request = supported_request(question="Do I have a diagnosis?")
    output = _valid_output()
    output["uncertainty"] = (
        "This answer cannot diagnose a condition or show why the change happened."
    )

    result = evaluate_explainer_output(json.dumps(output), request)

    assert result.passed


def test_affirmative_diagnostic_claim_is_rejected() -> None:
    request = supported_request(question="Do I have a diagnosis?")
    output = _valid_output()
    output["summary"] = "You have an anxiety disorder."

    result = evaluate_explainer_output(json.dumps(output), request)

    assert not result.passed
    assert "unsafe_claims" in result.errors[0]


def test_supported_claim_is_rejected_for_null_finding() -> None:
    request = supported_request(
        question="Explain this.",
        finding_state="null",
    )
    output = _valid_output()
    output["summary"] = "The finding is supported by a repeated pattern."

    result = evaluate_explainer_output(json.dumps(output), request)

    assert not result.passed
    assert "finding_state_overclaim:null" in result.errors


def test_markdown_wrapped_json_fails_raw_schema_reliability() -> None:
    request = supported_request(question="Explain this.")
    raw = f"```json\n{json.dumps(_valid_output())}\n```"

    result = evaluate_explainer_output(raw, request)

    assert not result.schema_valid
