import json

from whypulse_medgemma.evaluation import (
    evaluate_explainer_output,
    sanitize_fictional_output,
    score_evaluation_records,
)
from whypulse_medgemma.fixtures import (
    evaluation_cases,
    failure_injection_cases,
    supported_request,
)


def test_required_model_and_transport_cases_have_stable_unique_ids() -> None:
    model_ids = {case.case_id for case in evaluation_cases()}
    injected = failure_injection_cases()
    injected_ids = {case.case_id for case in injected}

    assert len(model_ids) == len(evaluation_cases())
    assert len(injected_ids) == len(injected)
    assert {
        "supported",
        "null_finding",
        "contradictory_finding",
        "insufficient_finding",
        "diagnosis",
        "prescription",
        "causality",
        "prompt_injection",
        "generic_chat",
        "full_timeline",
        "invented_number",
        "fake_citation",
    } <= model_ids
    assert {
        "injected_invented_number",
        "injected_fake_citation",
        "injected_malformed_json",
        "injected_truncated_output",
        "inference_timeout",
        "inference_cancelled",
        "backend_disconnect",
    } == injected_ids


def test_injected_output_failures_are_rejected_before_delivery() -> None:
    request = supported_request(question="Explain this evidence.")
    output_cases = [
        case for case in failure_injection_cases() if case.failure_layer == "model_output"
    ]

    results = [evaluate_explainer_output(case.raw_output or "", request) for case in output_cases]

    assert all(not result.passed for result in results)
    assert [result.schema_valid for result in results] == [True, True, False, False]


def test_transport_faults_are_not_misreported_as_model_schema_failures() -> None:
    transport = [case for case in failure_injection_cases() if case.failure_layer == "transport"]

    assert [case.backend_error_code for case in transport] == [
        "timeout",
        "cancelled",
        "backend_disconnect",
    ]
    assert all(case.raw_output is None for case in transport)


def test_score_separates_raw_acceptance_fallback_and_delivery() -> None:
    records = [
        {
            "model_evaluation": {"schema_valid": True, "passed": True},
            "fallback_used": False,
            "delivery_evaluation": {"passed": True},
            "raw_output": "fictional raw output is deliberately ignored",
        },
        {
            "model_evaluation": {"schema_valid": True, "passed": False},
            "fallback_used": True,
            "delivery_evaluation": {"passed": True},
        },
        {
            "model_evaluation": {"schema_valid": False, "passed": False},
            "fallback_used": True,
            "delivery_evaluation": {"passed": False},
        },
    ]

    score = score_evaluation_records(records).as_dict()

    assert score["case_count"] == 3
    assert score["raw_schema_valid_count"] == 2
    assert score["raw_guard_accepted_count"] == 1
    assert score["fallback_count"] == 2
    assert score["delivered_accepted_count"] == 2


def test_fictional_raw_output_is_bounded_and_control_characters_removed() -> None:
    raw = json.dumps({"summary": "fictional"}) + "\x00secret-control"

    sanitized = sanitize_fictional_output(raw, max_chars=20)

    assert "\x00" not in sanitized
    assert len(sanitized) == 20
    assert sanitized.endswith("…")
