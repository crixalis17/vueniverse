"""Deterministic grounding and safety checks for Explainer output."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from typing import Any

from pydantic import ValidationError

from vueniverse_medgemma.schemas import CitedParagraph, ExplainerOutput, ExplainerRequest

NUMBER_PATTERN = re.compile(r"(?<![A-Za-z])[-+]?\d+(?:\.\d+)?")
UNSAFE_PATTERNS = (
    re.compile(r"\byou have\b", re.IGNORECASE),
    re.compile(r"\b(?:this|the evidence|the data) proves?\b", re.IGNORECASE),
    re.compile(r"\b(?:is|was|were|definitely) caused by\b", re.IGNORECASE),
    re.compile(r"\b(?:start|stop|take|avoid) (?:a )?(?:drug|medication|medicine)\b", re.IGNORECASE),
    re.compile(r"\b(?:diagnosis|treatment) is\b", re.IGNORECASE),
    re.compile(r"\b(?:safe|unsafe|healthy|unhealthy) for you\b", re.IGNORECASE),
)
SUPPORTED_FINDING_PATTERNS = (
    re.compile(r"\bsupports an association\b", re.IGNORECASE),
    re.compile(r"\bsupported association\b", re.IGNORECASE),
    re.compile(r"\bfinding is supported\b", re.IGNORECASE),
)
HARD_TO_READ_PATTERNS = (
    re.compile(r"\bevidence bundle\b", re.IGNORECASE),
    re.compile(r"\bcounterevidence\b", re.IGNORECASE),
    re.compile(r"\bpromoted direction\b", re.IGNORECASE),
    re.compile(r"\bevidence completeness\b", re.IGNORECASE),
    re.compile(r"\bunresolved influence", re.IGNORECASE),
    re.compile(r"\bassociation\b", re.IGNORECASE),
    re.compile(r"\bdeterministic\b", re.IGNORECASE),
    re.compile(r"\binference\b", re.IGNORECASE),
    re.compile(r"\bcausality\b", re.IGNORECASE),
    re.compile(r"\bconfidence interval\b", re.IGNORECASE),
    re.compile(r"\bstatistically significant\b", re.IGNORECASE),
)


@dataclass(frozen=True)
class EvaluationResult:
    passed: bool
    schema_valid: bool
    errors: tuple[str, ...]
    parsed: ExplainerOutput | None

    def as_dict(self) -> dict[str, Any]:
        return {
            "passed": self.passed,
            "schema_valid": self.schema_valid,
            "errors": list(self.errors),
            "parsed": self.parsed.model_dump() if self.parsed else None,
        }


@dataclass(frozen=True)
class EvaluationScore:
    case_count: int
    raw_schema_valid_count: int
    raw_guard_accepted_count: int
    fallback_count: int
    delivered_accepted_count: int

    def as_dict(self) -> dict[str, int | float]:
        denominator = self.case_count or 1
        return {
            "case_count": self.case_count,
            "raw_schema_valid_count": self.raw_schema_valid_count,
            "raw_schema_valid_rate": self.raw_schema_valid_count / denominator,
            "raw_guard_accepted_count": self.raw_guard_accepted_count,
            "raw_guard_accepted_rate": self.raw_guard_accepted_count / denominator,
            "fallback_count": self.fallback_count,
            "fallback_rate": self.fallback_count / denominator,
            "delivered_accepted_count": self.delivered_accepted_count,
            "delivered_accepted_rate": self.delivered_accepted_count / denominator,
        }


def _numbers(text: str) -> set[str]:
    return set(NUMBER_PATTERN.findall(text))


def evaluate_explainer_output(raw: str, request: ExplainerRequest) -> EvaluationResult:
    errors: list[str] = []
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as error:
        return EvaluationResult(False, False, (f"invalid_json:{error.msg}",), None)

    try:
        output = ExplainerOutput.model_validate(payload)
    except ValidationError as error:
        return EvaluationResult(False, False, (f"invalid_schema:{error.error_count()}",), None)

    metric_by_id = {metric.citation_id: metric for metric in request.metrics}
    known_citations = set(metric_by_id)
    all_metric_numbers = set().union(*(_numbers(metric.value_text) for metric in request.metrics))

    summary_unknown = _numbers(output.summary) - all_metric_numbers
    if summary_unknown:
        errors.append(f"unsupported_summary_numbers:{sorted(summary_unknown)}")

    for index, paragraph in enumerate(output.paragraphs):
        citations = set(paragraph.citations)
        unknown = citations - known_citations
        if unknown:
            errors.append(f"paragraph_{index}_unknown_citations:{sorted(unknown)}")
            continue
        cited_numbers = set().union(
            *(_numbers(metric_by_id[item].value_text) for item in citations)
        )
        unsupported = _numbers(paragraph.text) - cited_numbers
        if unsupported:
            errors.append(f"paragraph_{index}_unsupported_numbers:{sorted(unsupported)}")

    unknown_influences = set(output.unresolved_influence_ids) - set(
        request.unresolved_influence_ids
    )
    if unknown_influences:
        errors.append(f"unknown_influences:{sorted(unknown_influences)}")

    if (
        output.next_observation_id is not None
        and output.next_observation_id not in request.approved_next_observations
    ):
        errors.append(f"unknown_next_observation:{output.next_observation_id}")

    combined_text = " ".join(
        [output.summary, *(paragraph.text for paragraph in output.paragraphs), output.uncertainty]
    )
    if _numbers(output.uncertainty):
        errors.append("numeric_uncertainty_not_allowed")
    if request.finding_state != "supported" and any(
        pattern.search(combined_text) for pattern in SUPPORTED_FINDING_PATTERNS
    ):
        errors.append(f"finding_state_overclaim:{request.finding_state}")
    unsafe = [pattern.pattern for pattern in UNSAFE_PATTERNS if pattern.search(combined_text)]
    if unsafe:
        errors.append(f"unsafe_claims:{unsafe}")
    hard_to_read = [
        pattern.pattern for pattern in HARD_TO_READ_PATTERNS if pattern.search(combined_text)
    ]
    if hard_to_read:
        errors.append(f"technical_language:{hard_to_read}")

    return EvaluationResult(not errors, True, tuple(errors), output)


def deterministic_explainer_fallback(request: ExplainerRequest) -> ExplainerOutput:
    """Return plain, data-backed copy when generated output fails a check."""
    metric_ids = {metric.citation_id for metric in request.metrics}
    metric_values = {
        metric.citation_id: metric.value_text.replace("bpm", "beats per minute")
        for metric in request.metrics
    }

    def value(citation_id: str, fallback: str) -> str:
        return metric_values.get(citation_id, fallback)

    copy_by_state = {
        "supported": (
            (
                "Heart rate showed the same pattern in "
                f"{value('consistent_count', 'the meetings checked')}. "
                "The usual difference was "
                f"{value('median_difference', 'available in the result')}."
            ),
            (
                f"Vueniverse checked {value('candidate_count', 'the available')} "
                "meetings and used "
                f"{value('included_count', 'the reliable ones')} after leaving out "
                f"{value('excluded_count', 'meetings with missing data')}."
            ),
        ),
        "developing": (
            (
                "The pattern has appeared more than once, but more similar events "
                "are needed for a clear result."
            ),
            (
                f"Vueniverse could use {value('included_count', 'the available')} "
                "meetings, with "
                f"{value('completeness', 'some')} of the needed data available."
            ),
        ),
        "null": (
            (
                f"Across {value('included_count', 'the available')} meetings, the "
                "usual difference was "
                f"{value('median_difference', 'small')}, so there was no clear "
                "repeated pattern."
            ),
            (
                "The same direction appeared in "
                f"{value('consistent_count', 'only some meetings')}."
            ),
        ),
        "contradictory": (
            "Some meetings showed the pattern and others did not, so there is no clear result yet.",
            (
                "The pattern appeared in "
                f"{value('consistent_count', 'some meetings')}, while "
                f"{value('counter_count', 'others')} did not match."
            ),
        ),
        "insufficient_data": (
            (
                f"Only {value('completeness', 'part')} of the needed data is "
                "available, so there is not enough for a fair result."
            ),
            (
                f"Vueniverse could use {value('included_count', 'a few')} of "
                f"{value('candidate_count', 'the')} meetings checked."
            ),
        ),
        "stale": (
            "This older result is no longer current.",
            "Vueniverse needs to check the latest data before showing the pattern again.",
        ),
        "invalidated": (
            "This older result is no longer available.",
            (
                "The data it depended on changed or was removed, so Vueniverse "
                "stopped showing it as current."
            ),
        ),
    }
    preferred_by_state = {
        "supported": ["candidate_count", "included_count", "excluded_count"],
        "developing": ["included_count", "completeness", "excluded_count"],
        "null": ["median_difference", "consistent_count", "completeness"],
        "contradictory": ["consistent_count", "counter_count", "effect_range"],
        "insufficient_data": ["included_count", "candidate_count", "completeness"],
        "stale": ["included_count", "completeness", "excluded_count"],
        "invalidated": ["included_count", "counter_count", "excluded_count"],
    }
    preferred = preferred_by_state[request.finding_state]
    citations = [citation_id for citation_id in preferred if citation_id in metric_ids]
    if not citations:
        citations = [metric.citation_id for metric in request.metrics[:1]]

    next_observation_id = None
    if request.ask_intent == "observe_next" and request.approved_next_observations:
        next_observation_id = next(iter(request.approved_next_observations))

    summary, paragraph_text = copy_by_state[request.finding_state]
    return ExplainerOutput(
        summary=summary,
        paragraphs=[
            CitedParagraph(
                text=paragraph_text,
                citations=citations,
            )
        ],
        uncertainty=(
            "This pattern in your data does not show why the change happened, "
            "and missing context may still matter."
        ),
        unresolved_influence_ids=request.unresolved_influence_ids,
        next_observation_id=next_observation_id,
    )


def score_evaluation_records(records: list[dict[str, Any]]) -> EvaluationScore:
    """Aggregate model and delivery outcomes without retaining raw output."""
    return EvaluationScore(
        case_count=len(records),
        raw_schema_valid_count=sum(
            bool(record.get("model_evaluation", {}).get("schema_valid")) for record in records
        ),
        raw_guard_accepted_count=sum(
            bool(record.get("model_evaluation", {}).get("passed")) for record in records
        ),
        fallback_count=sum(bool(record.get("fallback_used")) for record in records),
        delivered_accepted_count=sum(
            bool(record.get("delivery_evaluation", {}).get("passed")) for record in records
        ),
    )


def sanitize_fictional_output(raw: str, *, max_chars: int = 4_096) -> str:
    """Bound control characters and size before saving fictional raw output."""
    if max_chars < 1:
        raise ValueError("max_chars must be positive")
    printable = "".join(
        character for character in raw if character in "\n\t" or character.isprintable()
    )
    if len(printable) <= max_chars:
        return printable
    return printable[: max_chars - 1] + "…"
