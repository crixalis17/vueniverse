"""Private calibration and synthetic evidence generation for fine-tuning experiments.

This module deliberately keeps Ultrahuman payloads local. Calibration outputs contain
only coarsened aggregate bands, and generated records contain no real timestamps,
identifiers, titles, or raw readings.
"""

from __future__ import annotations

import json
import math
import os
import random
from collections import defaultdict
from collections.abc import Iterable, Mapping
from pathlib import Path
from typing import Any

from vueniverse_medgemma.schemas import EvidenceMetric, ExplainerRequest, FindingState

PRIVATE_PROFILE_SCHEMA = "vueniverse-ultrahuman-calibration-v1"
SYNTHETIC_CASE_SCHEMA = "vueniverse-synthetic-evidence-case-v1"
GENERATOR_VERSION = 3

_METRIC_COARSENING = {
    "hr": 5.0,
    "hrv": 5.0,
    "night_rhr": 5.0,
    "spo2": 1.0,
    "temp": 0.2,
    "steps": 50.0,
}
_STATES: tuple[FindingState, ...] = (
    "supported",
    "developing",
    "null",
    "contradictory",
    "insufficient_data",
)
_INTENTS = (
    "explain",
    "what_weakens",
    "what_is_missing",
    "what_disagrees",
    "observe_next",
    "promotion_gate",
)


def _percentile(values: list[float], fraction: float) -> float:
    if not values:
        raise ValueError("cannot calculate a percentile for an empty sequence")
    if not 0 <= fraction <= 1:
        raise ValueError("percentile fraction must be between zero and one")
    ordered = sorted(values)
    position = (len(ordered) - 1) * fraction
    lower = math.floor(position)
    upper = math.ceil(position)
    if lower == upper:
        return ordered[lower]
    return ordered[lower] + (ordered[upper] - ordered[lower]) * (position - lower)


def _coarsen(value: float, increment: float) -> float:
    rounded = round(value / increment) * increment
    return round(rounded, 1 if increment < 1 else 0)


def _payloads(input_dir: Path) -> Iterable[Mapping[str, Any]]:
    for path in sorted(input_dir.glob("probe-*.json")):
        payload = json.loads(path.read_text(encoding="utf-8"))
        if isinstance(payload, Mapping):
            yield payload


def _records(payload: Mapping[str, Any]) -> Iterable[Mapping[str, Any]]:
    data = payload.get("data")
    if not isinstance(data, Mapping):
        return
    metrics = data.get("metrics")
    if not isinstance(metrics, Mapping):
        return
    for day_records in metrics.values():
        if not isinstance(day_records, list):
            continue
        for record in day_records:
            if isinstance(record, Mapping):
                yield record


def calibrate_ultrahuman_directory(input_dir: Path) -> dict[str, Any]:
    """Create a private, coarsened profile from local Ultrahuman response files."""

    input_file_count = 0
    sample_counts: dict[str, list[int]] = defaultdict(list)
    values_by_metric: dict[str, list[float]] = defaultdict(list)
    days_present: dict[str, int] = defaultdict(int)

    for payload in _payloads(input_dir):
        input_file_count += 1
        seen_in_payload: set[str] = set()
        for record in _records(payload):
            metric = record.get("type")
            body = record.get("object")
            if not isinstance(metric, str) or not isinstance(body, Mapping):
                continue
            seen_in_payload.add(metric)
            rows = body.get("values")
            if not isinstance(rows, list):
                continue
            numeric_values = [
                float(item["value"])
                for item in rows
                if isinstance(item, Mapping)
                and isinstance(item.get("value"), (int, float))
                and math.isfinite(float(item["value"]))
            ]
            sample_counts[metric].append(len(numeric_values))
            values_by_metric[metric].extend(numeric_values)
        for metric in seen_in_payload:
            days_present[metric] += 1

    if input_file_count == 0:
        raise ValueError(f"no Ultrahuman probe files found in {input_dir}")
    if not values_by_metric.get("hr"):
        raise ValueError("Ultrahuman probe files contain no numeric heart-rate values")

    metric_profiles: dict[str, dict[str, Any]] = {}
    for metric in sorted(values_by_metric):
        values = values_by_metric[metric]
        increment = _METRIC_COARSENING.get(metric, 1.0)
        counts = sample_counts[metric]
        metric_profiles[metric] = {
            "days_present": days_present[metric],
            "sample_count_band": {
                "low": int(round(_percentile([float(count) for count in counts], 0.1))),
                "typical": int(round(_percentile([float(count) for count in counts], 0.5))),
                "high": int(round(_percentile([float(count) for count in counts], 0.9))),
            },
            "value_band": {
                "low": _coarsen(_percentile(values, 0.1), increment),
                "typical": _coarsen(_percentile(values, 0.5), increment),
                "high": _coarsen(_percentile(values, 0.9), increment),
            },
        }

    return {
        "schema_version": PRIVATE_PROFILE_SCHEMA,
        "generator_version": GENERATOR_VERSION,
        "input_file_count": input_file_count,
        "metric_profiles": metric_profiles,
        "privacy": {
            "contains_raw_measurements": False,
            "contains_timestamps": False,
            "contains_source_filenames": False,
            "coarsening": "quantile bands are rounded before storage",
        },
    }


def _write_private_json(path: Path, payload: Mapping[str, Any]) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    os.chmod(path.parent, 0o700)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.chmod(path, 0o600)
    return path


def write_calibration_profile(input_dir: Path, output_path: Path) -> Path:
    return _write_private_json(output_path, calibrate_ultrahuman_directory(input_dir))


def load_calibration_profile(path: Path) -> Mapping[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, Mapping) or payload.get("schema_version") != PRIVATE_PROFILE_SCHEMA:
        raise ValueError("calibration profile has an unsupported schema version")
    if not isinstance(payload.get("metric_profiles"), Mapping):
        raise ValueError("calibration profile has no metric profiles")
    return payload


def _signed(value: int) -> str:
    return f"{value:+d}"


def _range_text(center: int, spread: int) -> str:
    lower = center - spread
    upper = center + spread
    return f"{_signed(lower)} to {_signed(upper)} bpm"


def _sampling_variability(calibration: Mapping[str, Any]) -> float:
    metric_profiles = calibration.get("metric_profiles")
    if not isinstance(metric_profiles, Mapping):
        raise ValueError("calibration profile has no metric profiles")
    heart_rate = metric_profiles.get("hr")
    if not isinstance(heart_rate, Mapping):
        raise ValueError("calibration profile has no heart-rate profile")
    counts = heart_rate.get("sample_count_band")
    if not isinstance(counts, Mapping):
        raise ValueError("heart-rate profile has no sample-count band")
    low = counts.get("low")
    high = counts.get("high")
    if not isinstance(low, (int, float)) or not isinstance(high, (int, float)):
        raise ValueError("heart-rate sample-count band must be numeric")
    return min(1.0, max(0.0, (float(high) - float(low)) / max(1.0, float(high))))


def _scenario_values(
    state: FindingState, rng: random.Random, sampling_variability: float
) -> dict[str, int | float]:
    candidates = rng.randint(6, 12)
    availability_penalty = int(round(sampling_variability * rng.randint(0, 2)))
    if state == "supported":
        included = rng.randint(4, max(4, candidates - availability_penalty))
        consistent = max(4, math.ceil(included * rng.uniform(0.72, 0.9)))
        median_difference = rng.choice((-1, 1)) * rng.randint(5, 14)
        completeness = rng.randint(78, 96)
    elif state == "developing":
        included = rng.randint(2, 3)
        consistent = included
        median_difference = rng.choice((-1, 1)) * rng.randint(5, 11)
        completeness = rng.randint(75, 92)
    elif state == "null":
        included = rng.randint(4, max(4, candidates - availability_penalty))
        consistent = rng.randint(max(1, included // 2 - 1), max(1, included // 2 + 1))
        median_difference = rng.randint(-2, 2)
        completeness = rng.randint(76, 95)
    elif state == "contradictory":
        included = rng.randint(4, max(4, candidates - availability_penalty))
        consistent = included // 2
        median_difference = rng.choice((-1, 1)) * rng.randint(1, 4)
        completeness = rng.randint(76, 94)
    elif state == "insufficient_data":
        included = rng.randint(1, 2)
        consistent = rng.randint(0, included)
        median_difference = rng.choice((-1, 1)) * rng.randint(3, 10)
        completeness = rng.randint(35, 70)
    else:  # pragma: no cover - FindingState is closed, but preserves a clear failure.
        raise ValueError(f"unsupported synthetic state: {state}")

    return {
        "candidate_count": candidates,
        "included_count": included,
        "consistent_count": consistent,
        "counter_count": included - consistent,
        "excluded_count": candidates - included,
        "control_count": included if state != "insufficient_data" else rng.randint(1, 2),
        "median_difference": median_difference,
        "completeness": completeness,
    }


def _metric(citation_id: str, label: str, value_text: str, definition: str) -> EvidenceMetric:
    return EvidenceMetric(
        citation_id=citation_id,
        label=label,
        value_text=value_text,
        definition=definition,
        source="Synthetic analytics",
    )


def _question(intent: str, state: FindingState) -> str:
    questions = {
        "explain": "Explain this result in plain language.",
        "what_weakens": "What makes this result less clear?",
        "what_is_missing": "What information is still missing?",
        "what_disagrees": "Which parts of the result do not match?",
        "observe_next": "What should be observed next?",
        "promotion_gate": "Why is this result not ready, or why did it pass the checks?",
    }
    return questions[intent] if state != "supported" else questions[intent]


def _request_for_case(
    case_index: int, seed: int, sampling_variability: float
) -> ExplainerRequest:
    rng = random.Random(seed)
    state = _STATES[case_index % len(_STATES)]
    intent = _INTENTS[case_index % len(_INTENTS)]
    values = _scenario_values(state, rng, sampling_variability)
    difference = int(values["median_difference"])
    spread = rng.randint(2, 6)
    metrics = [
        _metric(
            "candidate_count",
            "Meetings checked",
            str(values["candidate_count"]),
            "Synthetic repeats reviewed",
        ),
        _metric(
            "included_count",
            "Meetings compared",
            str(values["included_count"]),
            "Synthetic repeats with enough data",
        ),
        _metric(
            "consistent_count",
            "Meetings showing the pattern",
            f"{values['consistent_count']} of {values['included_count']}",
            "Same synthetic direction",
        ),
        _metric(
            "counter_count",
            "Meetings not matching",
            str(values["counter_count"]),
            "Synthetic repeats in another direction",
        ),
        _metric(
            "excluded_count",
            "Meetings left out",
            str(values["excluded_count"]),
            "Synthetic repeats with missing or unreliable data",
        ),
        _metric(
            "control_count",
            "Similar times compared",
            str(values["control_count"]),
            "Synthetic no-event comparison windows",
        ),
        _metric(
            "median_difference",
            "Usual heart-rate difference",
            f"{_signed(difference)} bpm",
            "Synthetic event window compared with a synthetic control window",
        ),
        _metric(
            "effect_range",
            "Range seen in the data",
            _range_text(difference, spread),
            "Synthetic lowest to highest repeated difference",
        ),
        _metric(
            "completeness",
            "Data available",
            f"{values['completeness']}%",
            "Synthetic share of needed data present",
        ),
    ]
    return ExplainerRequest(
        evidence_version="synthetic-calibrated-v1",
        finding_state=state,
        metrics=metrics,
        exclusion_ids=["synthetic_low_coverage"],
        counterevidence_ids=["synthetic_counter_window"],
        unresolved_influence_ids=["caffeine_timing", "recent_exercise", "unusual_stress"],
        approved_next_observations={
            "repeat_window_check": (
                "Compare the next three synthetic eligible windows using the same rules."
            ),
            "log_context": "Record synthetic context consistently before the next comparison.",
        },
        ask_intent=intent,
        user_question=_question(intent, state),
    )


def generate_synthetic_evidence_cases(
    calibration: Mapping[str, Any], *, count: int, seed: int
) -> list[dict[str, Any]]:
    """Return deterministic synthetic cases; calibration is validated but never copied out."""

    if calibration.get("schema_version") != PRIVATE_PROFILE_SCHEMA:
        raise ValueError("calibration profile has an unsupported schema version")
    if count < 1:
        raise ValueError("count must be positive")
    sampling_variability = _sampling_variability(calibration)

    cases: list[dict[str, Any]] = []
    for index in range(count):
        case_seed = seed + index
        request = _request_for_case(index, case_seed, sampling_variability)
        context_rng = random.Random(case_seed ^ 0x5F3759DF)
        cases.append(
            {
                "schema_version": SYNTHETIC_CASE_SCHEMA,
                "case_id": f"synthetic_{index + 1:04d}",
                "metadata": {
                    "source": "synthetic_calibrated",
                    "generator_version": GENERATOR_VERSION,
                    "calibration_mode": "coarsened_sampling_variability",
                    "seed": case_seed,
                    "scenario": request.finding_state,
                    "split": "unassigned",
                    "synthetic_event_context": {
                        "category": "recurring_one_to_one",
                        "recurrence_pattern": context_rng.choice(
                            ("weekly", "biweekly", "weekday_sequence")
                        ),
                        "duration_minutes": context_rng.choice((25, 30, 45, 60)),
                    },
                },
                "request": request.model_dump(),
            }
        )
    return cases


def write_synthetic_cases(
    calibration_path: Path, output_path: Path, *, count: int, seed: int
) -> Path:
    calibration = load_calibration_profile(calibration_path)
    cases = generate_synthetic_evidence_cases(calibration, count=count, seed=seed)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    os.chmod(output_path.parent, 0o700)
    output_path.write_text(
        "".join(json.dumps(case, sort_keys=True) + "\n" for case in cases), encoding="utf-8"
    )
    os.chmod(output_path, 0o600)
    return output_path
