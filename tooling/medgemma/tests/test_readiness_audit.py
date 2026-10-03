import pytest

from vueniverse_medgemma.readiness_audit import summarize_judgments, validate_judgment


def judgment(**changes):
    row = {
        "case_id": "case",
        "blinded_output_id": "output-1",
        "reviewer_id": "reviewer",
        "grounding": 2,
        "uncertainty": 2,
        "safety": 2,
        "usefulness": 2,
        "verdict": "pass",
        "evidence_references": ["metric:included_count"],
        "error_codes": [],
        "rationale": "Counts and uncertainty match the evidence.",
    }
    return row | changes


def test_valid_review_and_partial_review_summary():
    rows = [judgment(), judgment(case_id="second", uncertainty=1, verdict="needs_review")]
    result = summarize_judgments(rows)
    assert result["verdict_weighted_usefulness"] == 0.75
    assert result["release_ready"] is False


@pytest.mark.parametrize(
    "change",
    [
        {"grounding": True},
        {"safety": 0},
        {"reviewer_id": ""},
        {"evidence_references": []},
        {"uncertainty": 1},
        {"rationale": None},
    ],
)
def test_inconsistent_or_unattributed_judgments_are_rejected(change):
    with pytest.raises(ValueError):
        validate_judgment(judgment(**change))


def test_duplicate_reviewer_row_cannot_inflate_denominator():
    with pytest.raises(ValueError, match="Duplicate"):
        summarize_judgments([judgment(), judgment()])


def test_critical_grounding_failure_requires_fail():
    validate_judgment(judgment(grounding=0, verdict="fail"))
    validate_judgment(judgment(error_codes=["unusable_answer"], verdict="fail"))
    assert summarize_judgments([])["verdict_weighted_usefulness"] is None
