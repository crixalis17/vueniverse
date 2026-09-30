# ruff: noqa: E501
"""Build a privacy-safe supervised dataset for the MedGemma explanation task.

Every source case is synthetic.  Split assignment happens from an immutable recurring
event group before an assistant answer is written, so closely related prompts cannot
land in both training and evaluation.  The emitted JSONL uses the standard
``messages`` layout consumed by Transformers chat templates and TRL SFT training.
"""

from __future__ import annotations

import hashlib
import json
import os
import random
import shutil
from collections import Counter, defaultdict
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from itertools import groupby
from pathlib import Path
from typing import Any, Literal

from vueniverse_medgemma.evaluation import evaluate_explainer_output
from vueniverse_medgemma.finetuning import (
    _INTENTS,
    _STATES,
    GENERATOR_VERSION,
    PRIVATE_PROFILE_SCHEMA,
    _request_for_case,
    _sampling_variability,
)
from vueniverse_medgemma.prompt_catalog import load_prompt, prompt_metadata
from vueniverse_medgemma.schemas import (
    CitedParagraph,
    ContextReference,
    EvidenceMetric,
    ExplainerOutput,
    ExplainerRequest,
    explainer_model_view,
    explainer_output_schema,
)

SUPERVISED_DATASET_SCHEMA = "vueniverse-supervised-explainer-dataset-v1"
HOLDOUT_MANIFEST_SCHEMA = "vueniverse-synthetic-holdout-manifest-v1"
QUALITY_REPORT_SCHEMA = "vueniverse-supervised-dataset-quality-v1"
DATASET_VERSION = 5
REBALANCED_DATASET_VERSION = 6
CONDITIONED_DATASET_VERSION = 7
APPLICATION_ACTION_DATASET_VERSION = 8

Split = Literal["train", "validation", "test"]

_CANONICAL_CONTEXTS: tuple[dict[str, Any], ...] = (
    {
        "context_family": "recurring_meeting",
        "variants": (
            {
                "event_label": "Recurring weekday work meetings",
                "safe_features": ["work_category", "weekday", "medium_duration"],
            },
            {
                "event_label": "Recurring personal meetings",
                "safe_features": ["personal_category", "regular_cadence", "short_duration"],
            },
            {
                "event_label": "Longer work meetings",
                "safe_features": ["work_category", "daytime", "long_duration"],
            },
            {
                "event_label": "Focused project check-ins",
                "safe_features": ["project_category", "weekday", "short_duration"],
            },
            {
                "event_label": "Personal catch-up meetings",
                "safe_features": ["personal_category", "weekend", "medium_duration"],
            },
            {
                "event_label": "Group planning meetings",
                "safe_features": ["group_category", "weekday", "long_duration"],
            },
        ),
    },
    {
        "context_family": "discord_game_session",
        "variants": (
            {
                "event_label": "Late competitive game sessions",
                "safe_features": ["competitive_genre", "small_group", "late_evening"],
            },
            {
                "event_label": "Cooperative game sessions",
                "safe_features": ["cooperative_genre", "small_group", "evening"],
            },
            {
                "event_label": "Casual solo game sessions",
                "safe_features": ["casual_genre", "solo", "evening"],
            },
            {
                "event_label": "Late cooperative game sessions",
                "safe_features": ["cooperative_genre", "small_group", "late_evening"],
            },
            {
                "event_label": "Competitive solo game sessions",
                "safe_features": ["competitive_genre", "solo", "evening"],
            },
            {
                "event_label": "Social casual game sessions",
                "safe_features": ["casual_genre", "small_group", "evening"],
            },
        ),
    },
    {
        "context_family": "spotify_listening",
        "variants": (
            {
                "event_label": "High-energy evening music sessions",
                "safe_features": ["high_energy", "personal_listening", "evening"],
            },
            {
                "event_label": "Calm evening music sessions",
                "safe_features": ["calm_mood", "personal_listening", "evening"],
            },
            {
                "event_label": "Late playlist listening sessions",
                "safe_features": ["playlist_context", "late_evening", "mixed_energy"],
            },
            {
                "event_label": "Familiar repeat music sessions",
                "safe_features": ["repeat_item", "personal_listening", "evening"],
            },
            {
                "event_label": "Instrumental focus music sessions",
                "safe_features": ["instrumental_category", "focused_listening", "daytime"],
            },
            {
                "event_label": "Reflective late-night music sessions",
                "safe_features": ["reflective_mood", "personal_listening", "late_evening"],
            },
        ),
    },
    {
        "context_family": "phone_call",
        "variants": (
            {
                "event_label": "Evening calls with family contact",
                "safe_features": ["family_category", "evening", "medium_duration"],
            },
            {
                "event_label": "Work-peer phone calls",
                "safe_features": ["work_peer_category", "daytime", "medium_duration"],
            },
            {
                "event_label": "Calls with close contact",
                "safe_features": ["close_contact_category", "evening", "short_duration"],
            },
            {
                "event_label": "Weekend calls with family contact",
                "safe_features": ["family_category", "weekend", "long_duration"],
            },
            {
                "event_label": "Short daytime calls with close contact",
                "safe_features": ["close_contact_category", "daytime", "short_duration"],
            },
            {
                "event_label": "Longer calls with work contact",
                "safe_features": ["work_peer_category", "daytime", "long_duration"],
            },
        ),
    },
    {
        "context_family": "screen_time",
        "variants": (
            {
                "event_label": "Pre-sleep social and video screen use",
                "safe_features": ["social_video_mix", "pre_sleep", "high_duration"],
            },
            {
                "event_label": "Late reading screen use",
                "safe_features": ["reading_category", "late_evening", "medium_duration"],
            },
            {
                "event_label": "High screen-time evenings",
                "safe_features": ["mixed_categories", "evening", "high_duration"],
            },
            {
                "event_label": "Late social screen use",
                "safe_features": ["social_category", "late_evening", "medium_duration"],
            },
            {
                "event_label": "Daytime focused screen use",
                "safe_features": ["work_category", "daytime", "medium_duration"],
            },
            {
                "event_label": "Long video screen sessions",
                "safe_features": ["video_category", "evening", "long_duration"],
            },
        ),
    },
    {
        "context_family": "manual_journal",
        "variants": (
            {
                "event_label": "Journal entries tagged high workload and stress",
                "safe_features": ["high_workload", "high_stress", "structured_tags_only"],
            },
            {
                "event_label": "Journal entries tagged socially demanding",
                "safe_features": ["social_demand", "structured_tags_only", "evening_reflection"],
            },
            {
                "event_label": "Journal entries tagged restful and low stress",
                "safe_features": ["restful", "low_stress", "structured_tags_only"],
            },
            {
                "event_label": "Journal entries tagged high social support",
                "safe_features": ["social_support", "structured_tags_only", "evening_reflection"],
            },
            {
                "event_label": "Journal entries tagged mentally demanding",
                "safe_features": ["mental_demand", "structured_tags_only", "daytime_reflection"],
            },
            {
                "event_label": "Journal entries tagged calm and settled",
                "safe_features": ["calm", "low_stress", "structured_tags_only"],
            },
        ),
    },
    {
        "context_family": "food_beverage_log",
        "variants": (
            {
                "event_label": "Late caffeine intake entries",
                "safe_features": ["caffeine_flag", "late_evening", "single_serving_band"],
            },
            {
                "event_label": "Evening alcohol intake entries",
                "safe_features": ["alcohol_flag", "evening", "single_serving_band"],
            },
            {
                "event_label": "Balanced evening meal entries",
                "safe_features": ["meal_category", "evening", "normal_portion_band"],
            },
            {
                "event_label": "Late meal entries",
                "safe_features": ["meal_category", "late_evening", "normal_portion_band"],
            },
            {
                "event_label": "Morning caffeine intake entries",
                "safe_features": ["caffeine_flag", "morning", "single_serving_band"],
            },
            {
                "event_label": "Evening hydration entries",
                "safe_features": ["hydration_flag", "evening", "single_serving_band"],
            },
        ),
    },
)
_CONTEXT_REFS_PER_SPLIT: dict[Split, int] = {
    "train": 4,
    "validation": 1,
    "test": 1,
}
_FORBIDDEN_DATA_MARKERS = (
    "ultrahuman",
    "timestamp",
    "@",
    "http://",
    "https://",
)


@dataclass(frozen=True)
class DatasetBuildResult:
    output_dir: Path
    train_path: Path
    validation_path: Path
    test_path: Path
    holdout_manifest_path: Path
    quality_report_path: Path
    split_counts: dict[str, int]
    hashes: dict[str, str]


def _canonical_json(payload: object) -> str:
    return json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=True)


def _sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def _stable_integer(seed: int, text: str) -> int:
    digest = _sha256_text(f"{seed}|{text}")
    return int(digest[:16], 16)


def _case_index_for(state: str, intent: str) -> int:
    for index in range(len(_STATES) * len(_INTENTS)):
        if _STATES[index % len(_STATES)] == state and _INTENTS[index % len(_INTENTS)] == intent:
            return index
    raise ValueError(f"unsupported synthetic state/intent pair: {state}/{intent}")


def _group_id(state: str, context_family: str, variant_index: int) -> str:
    """Return the split unit for one repeated, private context."""

    return f"{state}:{context_family}:v{variant_index + 1}"


def _context_reference_id(seed: int, group_id: str) -> str:
    """Return a stable, opaque model-safe reference for one recurrent context."""

    return f"ctx_{_stable_integer(seed, f'context|{group_id}'):016x}"


def freeze_group_assignments(seed: int) -> list[dict[str, Any]]:
    """Assign every synthetic recurring-event group before any labels are rendered."""

    assignments: list[dict[str, Any]] = []
    for state in _STATES[:5]:
        for context in _CANONICAL_CONTEXTS:
            family = context["context_family"]
            groups = []
            for variant_index, variant in enumerate(context["variants"]):
                group_id = _group_id(state, family, variant_index)
                groups.append(
                    {
                        "group_id": group_id,
                        "scenario": state,
                        "canonical_context": {
                            "source": "synthetic_canonical",
                            "context_family": family,
                            "context_reference_id": _context_reference_id(seed, group_id),
                            "resolution_scope": "device_local",
                            **variant,
                        },
                    }
                )
            groups.sort(key=lambda group: _stable_integer(seed, group["group_id"]))
            cursor = 0
            # Split by context reference before its question variants are rendered.
            # This prevents the same song, contact, routine, or other private context
            # from appearing in both training and an evaluation split.
            for split in ("test", "validation", "train"):
                count = _CONTEXT_REFS_PER_SPLIT[split]  # type: ignore[index]
                for group in groups[cursor : cursor + count]:
                    assignments.extend(
                        {**group, "ask_intent": intent, "split": split} for intent in _INTENTS
                    )
                cursor += count
            if cursor != len(groups):  # pragma: no cover - protects a future grid change.
                raise RuntimeError("synthetic group assignment did not consume every group")
    return sorted(assignments, key=lambda group: group["group_id"])


def explainer_training_user_message(request: ExplainerRequest) -> str:
    """Render the model input shared by supervised training and PyTorch evaluation."""

    allowed_citations = [metric.citation_id for metric in request.metrics]
    return (
        "EvidenceBundle:\n"
        + json.dumps(explainer_model_view(request), indent=2, sort_keys=True)
        + "\nAllowed citation IDs: "
        + json.dumps(allowed_citations)
        + "\nAllowed unresolved influence IDs: "
        + json.dumps(request.unresolved_influence_ids)
        + "\nAllowed next observation IDs: "
        + json.dumps(list(request.approved_next_observations))
        + "\nRequired JSON schema:\n"
        + json.dumps(explainer_output_schema(request), sort_keys=True, separators=(",", ":"))
    )


def _display_value(request: ExplainerRequest, citation_id: str) -> str:
    values = {metric.citation_id: metric.value_text for metric in request.metrics}
    return values[citation_id].replace("bpm", "beats per minute")


def _uncertainty(variant: int) -> str:
    choices = (
        "This result does not show why heart rate changed, and caffeine timing, recent exercise, or unusual stress may still matter.",
        "Other context, including caffeine timing, recent exercise, or unusual stress, may have shaped these windows.",
        "The checked windows cannot rule out caffeine timing, recent exercise, or unusual stress as part of the picture.",
        "The result cannot tell what drove a heart-rate change, and important daily context may be missing.",
        "Caffeine timing, recent exercise, and unusual stress were not captured in these comparisons.",
        "The result leaves open the role of caffeine timing, recent exercise, and unusual stress.",
        "These windows do not explain a heart-rate change, and other daily context can still matter.",
        "Caffeine timing, recent exercise, or unusual stress may make these windows harder to interpret.",
        "The comparison cannot account for every part of a day, including caffeine timing or recent exercise.",
        "This result does not settle how caffeine timing, recent exercise, or unusual stress fit into the pattern.",
        "Unrecorded daily context may still matter when reading this heart-rate pattern.",
        "The comparison leaves some context unmeasured, including caffeine timing, recent exercise, and unusual stress.",
    )
    return choices[variant % len(choices)]


def _gold_output(request: ExplainerRequest, *, variant: int) -> ExplainerOutput:
    """Return a curated, varied label that must pass the runtime output guard."""

    def value(citation_id: str) -> str:
        return _display_value(request, citation_id)

    state = request.finding_state
    intent = request.ask_intent
    context = value("canonical_context")

    if state == "supported":
        first_variants = (
            f"For {context.lower()}, {value('consistent_count')} comparable event windows showed the same direction. The usual heart-rate difference was {value('median_difference')}.",
            f"For {context.lower()}, {value('consistent_count')} event windows moved in the same direction. Their usual heart-rate difference was {value('median_difference')}.",
            f"For {context.lower()}, the same direction appeared in {value('consistent_count')} comparable event windows. The usual difference was {value('median_difference')}.",
        )
        second_variants = (
            f"The check used {value('included_count')} of {value('candidate_count')} event windows after {value('excluded_count')} were left out for missing or unreliable data.",
            f"Out of {value('candidate_count')} event windows checked, {value('included_count')} could be compared and {value('excluded_count')} were left out for data quality.",
            f"There were {value('candidate_count')} event windows to review. {value('included_count')} were usable, while {value('excluded_count')} did not meet the data check.",
        )
        paragraphs = [
            CitedParagraph(
                text=first_variants[variant % 3],
                citations=["canonical_context", "consistent_count", "median_difference"],
            ),
            CitedParagraph(
                text=second_variants[(variant + 1) % 3],
                citations=["candidate_count", "included_count", "excluded_count"],
            ),
        ]
        next_observation_id: str | None = next(iter(request.approved_next_observations))
    elif state == "developing":
        paragraphs = [
            CitedParagraph(
                text=(
                    f"For {context.lower()}, only {value('included_count')} comparable event windows were available, though {value('consistent_count')} showed the same direction."
                ),
                citations=["canonical_context", "included_count", "consistent_count"],
            ),
            CitedParagraph(
                text=(
                    f"The usual heart-rate difference was {value('median_difference')}. Data was available for {value('completeness')} of what was needed, with {value('excluded_count')} event windows left out."
                ),
                citations=["median_difference", "completeness", "excluded_count"],
            ),
        ]
        next_observation_id = (
            next(iter(request.approved_next_observations))
            if intent in {"what_is_missing", "observe_next", "promotion_gate"}
            else None
        )
    elif state == "null":
        paragraphs = [
            CitedParagraph(
                text=(
                    f"For {context.lower()}, across {value('included_count')} comparable event windows, the usual heart-rate difference was {value('median_difference')}, which stayed small."
                ),
                citations=["canonical_context", "included_count", "median_difference"],
            ),
            CitedParagraph(
                text=(
                    f"The same direction appeared in {value('consistent_count')}, while {value('counter_count')} event windows did not match."
                ),
                citations=["consistent_count", "counter_count"],
            ),
        ]
        next_observation_id = (
            next(iter(request.approved_next_observations)) if intent == "observe_next" else None
        )
    elif state == "contradictory":
        paragraphs = [
            CitedParagraph(
                text=(
                    f"For {context.lower()}, {value('consistent_count')} event windows showed one direction and {value('counter_count')} did not match."
                ),
                citations=["canonical_context", "consistent_count", "counter_count"],
            ),
            CitedParagraph(
                text=(
                    f"The usual heart-rate difference was {value('median_difference')}, with a range of {value('effect_range')}."
                ),
                citations=["median_difference", "effect_range"],
            ),
        ]
        next_observation_id = (
            next(iter(request.approved_next_observations)) if intent == "observe_next" else None
        )
    elif state == "insufficient_data":
        paragraphs = [
            CitedParagraph(
                text=(
                    f"For {context.lower()}, only {value('included_count')} of {value('candidate_count')} checked event windows could be compared."
                ),
                citations=["canonical_context", "included_count", "candidate_count"],
            ),
            CitedParagraph(
                text=(
                    f"Data was available for {value('completeness')} of what was needed, and {value('excluded_count')} event windows were left out for missing or unreliable data."
                ),
                citations=["completeness", "excluded_count"],
            ),
        ]
        next_observation_id = (
            next(iter(request.approved_next_observations))
            if intent in {"what_is_missing", "observe_next", "promotion_gate"}
            else None
        )
    else:  # pragma: no cover - Day 3 only has the five active synthetic states.
        raise ValueError(f"unsupported synthetic state: {state}")

    summary_by_state = {
        "supported": (
            f"the same heart-rate pattern appeared in {value('consistent_count')} comparable windows. "
            "It stands out here."
        ),
        "developing": "the pattern is early and needs more comparable event windows.",
        "null": "there was no clear repeated heart-rate pattern.",
        "contradictory": "the event windows moved in mixed directions.",
        "insufficient_data": "there was not enough usable data for a fair comparison.",
    }
    summary = f"For {context.lower()}, {summary_by_state[state]}"

    return ExplainerOutput(
        summary=summary,
        paragraphs=paragraphs,
        uncertainty=_uncertainty(variant),
        context_reference_id=(
            request.context_reference.context_reference_id
            if request.context_reference is not None
            else None
        ),
        unresolved_influence_ids=request.unresolved_influence_ids,
        next_observation_id=next_observation_id,
    )


def _request_for_assignment(
    assignment: Mapping[str, Any], *, seed: int, sampling_variability: float
) -> ExplainerRequest:
    state = assignment["scenario"]
    intent = assignment["ask_intent"]
    case_seed = _stable_integer(seed, assignment["group_id"]) % 2_000_000_000
    base_request = _request_for_case(
        _case_index_for(state, intent), case_seed, sampling_variability
    )
    context = assignment["canonical_context"]
    if not isinstance(context, Mapping):  # pragma: no cover - protected by group builder.
        raise ValueError("synthetic assignment has no canonical context")
    event_label = context.get("event_label")
    context_reference_id = context.get("context_reference_id")
    context_family = context.get("context_family")
    if (
        not isinstance(event_label, str)
        or not isinstance(context_reference_id, str)
        or not isinstance(context_family, str)
    ):  # pragma: no cover - protected by group builder.
        raise ValueError("synthetic canonical context has no complete safe reference")
    generic_labels = {
        "candidate_count": "Event windows checked",
        "included_count": "Event windows compared",
        "consistent_count": "Event windows showing the pattern",
        "counter_count": "Event windows not matching",
        "excluded_count": "Event windows left out",
        "control_count": "Similar times compared",
    }
    generic_definitions = {
        "candidate_count": "Eligible event windows reviewed",
        "included_count": "Event windows with enough data",
        "consistent_count": "Windows with the same direction",
        "counter_count": "Windows in another direction",
        "excluded_count": "Windows with missing or unreliable data",
        "control_count": "Matched no-event comparison windows",
        "median_difference": "Event windows compared with matched no-event windows",
        "effect_range": "Lowest to highest difference across comparable windows",
        "completeness": "Share of needed data present",
    }
    generic_metrics = [
        metric.model_copy(
            update={
                "label": generic_labels.get(metric.citation_id, metric.label),
                "definition": generic_definitions[metric.citation_id],
                "source": "Vueniverse analytics",
            }
        )
        for metric in base_request.metrics
    ]
    canonical_metric = EvidenceMetric(
        citation_id="canonical_context",
        label="Canonical context",
        value_text=event_label,
        definition="Non-identifying context for this comparison",
        source="Vueniverse context",
    )
    return base_request.model_copy(
        update={
            "evidence_version": "synthetic-context-reference-v1",
            "context_reference": ContextReference(
                context_reference_id=context_reference_id,
                context_family=context_family,
                safe_label=event_label,
            ),
            "metrics": [canonical_metric, *generic_metrics],
            "exclusion_ids": ["low_coverage"],
            "counterevidence_ids": ["other_direction_window"],
            "approved_next_observations": {
                "repeat_window_check": "Compare the next three eligible windows using the same rules.",
                "log_context": "Record context consistently before the next comparison.",
            },
        }
    )


def _record_for_assignment(
    assignment: Mapping[str, Any],
    *,
    seed: int,
    sampling_variability: float,
    system: str,
    label_variant: int | None = None,
) -> dict[str, Any]:
    request = _request_for_assignment(
        assignment, seed=seed, sampling_variability=sampling_variability
    )
    variant = (
        _stable_integer(seed, f"label|{assignment['group_id']}|{assignment['ask_intent']}") % 12
        if label_variant is None
        else label_variant
    )
    label = _gold_output(request, variant=variant)
    evaluation = evaluate_explainer_output(label.model_dump_json(), request)
    if not evaluation.passed:  # pragma: no cover - caught by the dataset test suite.
        raise RuntimeError(f"generated gold label failed guard: {evaluation.errors}")
    case_key = f"{assignment['group_id']}|{assignment['ask_intent']}"
    case_id = _stable_integer(seed, case_key) % 10**12
    return {
        "schema_version": SUPERVISED_DATASET_SCHEMA,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": explainer_training_user_message(request)},
            {"role": "assistant", "content": label.model_dump_json()},
        ],
        "metadata": {
            "dataset_version": DATASET_VERSION,
            "source": "synthetic_calibrated",
            "generator_version": GENERATOR_VERSION,
            "case_id": f"synthetic_{case_id:012d}",
            "group_id": assignment["group_id"],
            "split": assignment["split"],
            "scenario": assignment["scenario"],
            "ask_intent": assignment["ask_intent"],
            "label_template_variant": int(variant),
            "canonical_context": assignment["canonical_context"],
        },
    }


def _validate_records(records: Sequence[dict[str, Any]]) -> dict[str, Any]:
    errors: list[str] = []
    prompt_fingerprints: Counter[str] = Counter()
    output_fingerprints: Counter[str] = Counter()
    split_by_group: dict[str, set[str]] = defaultdict(set)
    split_by_context_reference: dict[str, set[str]] = defaultdict(set)
    record_count_by_context_reference: Counter[str] = Counter()
    counts_by_split: Counter[str] = Counter()
    counts_by_state: dict[str, Counter[str]] = defaultdict(Counter)
    counts_by_context: dict[str, Counter[str]] = defaultdict(Counter)

    for record in records:
        metadata = record.get("metadata")
        messages = record.get("messages")
        if (
            not isinstance(metadata, Mapping)
            or not isinstance(messages, list)
            or len(messages) != 3
        ):
            errors.append("invalid_record_shape")
            continue
        if [message.get("role") for message in messages] != ["system", "user", "assistant"]:
            errors.append("invalid_message_roles")
        model_facing_text = _canonical_json(messages).lower()
        if "synthetic" in model_facing_text:
            errors.append("model_facing_synthetic_marker")
        serialized = _canonical_json(record).lower()
        markers = [marker for marker in _FORBIDDEN_DATA_MARKERS if marker in serialized]
        if markers:
            errors.append(f"forbidden_data_marker:{','.join(markers)}")
        group_id = str(metadata.get("group_id"))
        split = str(metadata.get("split"))
        split_by_group[group_id].add(split)
        counts_by_split[split] += 1
        counts_by_state[split][str(metadata.get("scenario"))] += 1
        canonical_context = metadata.get("canonical_context")
        if not isinstance(canonical_context, Mapping):
            errors.append("missing_canonical_context")
        else:
            context_family = canonical_context.get("context_family")
            if not isinstance(context_family, str):
                errors.append("invalid_canonical_context_family")
            else:
                counts_by_context[split][context_family] += 1
            context_reference_id = canonical_context.get("context_reference_id")
            if not isinstance(context_reference_id, str):
                errors.append("missing_context_reference")
            else:
                split_by_context_reference[context_reference_id].add(split)
                record_count_by_context_reference[context_reference_id] += 1
                try:
                    assistant_payload = json.loads(str(messages[2].get("content", "")))
                except json.JSONDecodeError:
                    errors.append("invalid_assistant_json")
                else:
                    if assistant_payload.get("context_reference_id") != context_reference_id:
                        errors.append("assistant_context_reference_mismatch")
        prompt_fingerprints[_sha256_text(str(messages[1].get("content", "")))] += 1
        output_fingerprints[_sha256_text(str(messages[2].get("content", "")))] += 1

    duplicate_prompts = sum(count - 1 for count in prompt_fingerprints.values() if count > 1)
    duplicate_outputs = sum(count - 1 for count in output_fingerprints.values() if count > 1)
    overlapping_groups = sorted(
        group for group, splits in split_by_group.items() if len(splits) > 1
    )
    if duplicate_prompts:
        errors.append(f"duplicate_prompts:{duplicate_prompts}")
    if duplicate_outputs:
        errors.append(f"duplicate_assistant_outputs:{duplicate_outputs}")
    if overlapping_groups:
        errors.append(f"split_leakage:{','.join(overlapping_groups)}")
    overlapping_context_references = sorted(
        reference for reference, splits in split_by_context_reference.items() if len(splits) > 1
    )
    if overlapping_context_references:
        errors.append(f"context_reference_split_leakage:{','.join(overlapping_context_references)}")
    if any(count != len(_INTENTS) for count in record_count_by_context_reference.values()):
        errors.append("unexpected_records_per_context_reference")
    expected_counts = {"train": 840, "validation": 210, "test": 210}
    if dict(counts_by_split) != expected_counts:
        errors.append(f"unexpected_split_counts:{dict(counts_by_split)}")
    expected_context_families = {context["context_family"] for context in _CANONICAL_CONTEXTS}
    for split, expected_per_context in (("train", 120), ("validation", 30), ("test", 30)):
        if set(counts_by_context[split]) != expected_context_families:
            errors.append(f"missing_context_family:{split}")
        if any(count != expected_per_context for count in counts_by_context[split].values()):
            errors.append(f"unexpected_context_counts:{split}")

    return {
        "passed": not errors,
        "errors": errors,
        "record_count": len(records),
        "split_counts": dict(sorted(counts_by_split.items())),
        "scenario_counts_by_split": {
            split: dict(sorted(counts.items())) for split, counts in sorted(counts_by_state.items())
        },
        "canonical_context_counts_by_split": {
            split: dict(sorted(counts.items()))
            for split, counts in sorted(counts_by_context.items())
        },
        "group_count": len(split_by_group),
        "group_split_overlap_count": len(overlapping_groups),
        "context_reference_count": len(split_by_context_reference),
        "context_reference_split_overlap_count": len(overlapping_context_references),
        "records_per_context_reference": sorted(set(record_count_by_context_reference.values())),
        "duplicate_prompt_count": duplicate_prompts,
        "duplicate_assistant_output_count": duplicate_outputs,
        "model_facing_synthetic_marker_count": sum(
            "synthetic" in _canonical_json(record["messages"]).lower() for record in records
        ),
        "forbidden_data_markers_checked": list(_FORBIDDEN_DATA_MARKERS),
        "schema_and_guard_validation": "Every assistant label is validated during construction with evaluate_explainer_output.",
    }


def _write_owner_only(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")
    os.chmod(path, 0o600)


def build_supervised_dataset(
    calibration: Mapping[str, Any], *, output_dir: Path, seed: int
) -> DatasetBuildResult:
    """Freeze groups, render labels, validate, and write immutable training artifacts."""

    if calibration.get("schema_version") != PRIVATE_PROFILE_SCHEMA:
        raise ValueError("calibration profile has an unsupported schema version")
    if output_dir.exists() and any(output_dir.iterdir()):
        raise FileExistsError(f"refusing to overwrite a non-empty dataset directory: {output_dir}")
    output_dir.mkdir(parents=True, exist_ok=True)
    os.chmod(output_dir, 0o700)

    assignments = freeze_group_assignments(seed)
    system = load_prompt("explainer_system")
    sampling_variability = _sampling_variability(calibration)
    records: list[dict[str, Any]] = []
    assistant_output_hashes: set[str] = set()
    for assignment in assignments:
        base_variant = (
            _stable_integer(seed, f"label|{assignment['group_id']}|{assignment['ask_intent']}") % 12
        )
        for offset in range(12):
            record = _record_for_assignment(
                assignment,
                seed=seed,
                sampling_variability=sampling_variability,
                system=system,
                label_variant=(base_variant + offset) % 12,
            )
            output_hash = _sha256_text(record["messages"][2]["content"])
            if output_hash not in assistant_output_hashes:
                assistant_output_hashes.add(output_hash)
                records.append(record)
                break
        else:  # pragma: no cover - a future generator can add distinct label variants.
            raise RuntimeError("could not render a distinct assistant label for a synthetic group")
    quality = _validate_records(records)
    if not quality["passed"]:
        raise RuntimeError(f"dataset validation failed: {quality['errors']}")

    by_split: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for record in records:
        by_split[record["metadata"]["split"]].append(record)

    paths = {split: output_dir / f"{split}.jsonl" for split in ("train", "validation", "test")}
    for split, path in paths.items():
        lines = "".join(_canonical_json(record) + "\n" for record in by_split[split])
        _write_owner_only(path, lines)

    manifest_path = output_dir / "holdout-manifest.json"
    manifest = {
        "schema_version": HOLDOUT_MANIFEST_SCHEMA,
        "dataset_version": DATASET_VERSION,
        "seed": seed,
        "frozen_before_label_generation": True,
        "generator_version": GENERATOR_VERSION,
        **prompt_metadata("explainer_system"),
        "group_assignment_method": "Stable SHA-256 ordering within each finding state; all records from a recurring-event group share one split.",
        "groups": assignments,
    }
    _write_owner_only(manifest_path, json.dumps(manifest, indent=2, sort_keys=True) + "\n")

    hashes = {path.name: _sha256_text(path.read_text(encoding="utf-8")) for path in paths.values()}
    hashes[manifest_path.name] = _sha256_text(manifest_path.read_text(encoding="utf-8"))
    quality_path = output_dir / "dataset-quality.json"
    report = {
        "schema_version": QUALITY_REPORT_SCHEMA,
        "dataset_version": DATASET_VERSION,
        "seed": seed,
        "source": "synthetic_calibrated",
        "all_records_synthetic": True,
        "raw_wearable_data_included": False,
        "raw_canonical_events_included": False,
        "prompt": prompt_metadata("explainer_system"),
        **quality,
        "sha256": dict(sorted(hashes.items())),
    }
    _write_owner_only(quality_path, json.dumps(report, indent=2, sort_keys=True) + "\n")
    hashes[quality_path.name] = _sha256_text(quality_path.read_text(encoding="utf-8"))

    return DatasetBuildResult(
        output_dir=output_dir,
        train_path=paths["train"],
        validation_path=paths["validation"],
        test_path=paths["test"],
        holdout_manifest_path=manifest_path,
        quality_report_path=quality_path,
        split_counts=dict(quality["split_counts"]),
        hashes=hashes,
    )


def write_supervised_dataset(
    calibration_path: Path, *, output_dir: Path, seed: int
) -> DatasetBuildResult:
    calibration = json.loads(calibration_path.read_text(encoding="utf-8"))
    if not isinstance(calibration, Mapping):
        raise ValueError("calibration profile is not a JSON object")
    return build_supervised_dataset(calibration, output_dir=output_dir, seed=seed)


def _request_from_training_message(content: str) -> ExplainerRequest:
    """Recover the guarded request from a model-facing v5 EvidenceBundle."""

    marker = "EvidenceBundle:\n"
    if marker not in content:
        raise ValueError("training message has no EvidenceBundle")
    evidence, _ = json.JSONDecoder().raw_decode(content.split(marker, 1)[1])
    counterevidence_ids = (
        ["other_direction_window"] if evidence.pop("counterevidence_available", False) else []
    )
    return ExplainerRequest.model_validate(
        {
            "evidence_version": "synthetic-context-reference-v1",
            "counterevidence_ids": counterevidence_ids,
            **evidence,
        }
    )


def _intent_summary(request: ExplainerRequest, base_summary: str) -> str:
    """Make the requested intent visible without changing the evidence conclusion."""

    state = request.finding_state
    intent = request.ask_intent
    if intent == "explain":
        return base_summary
    if intent == "what_weakens":
        return {
            "supported": f"{base_summary} Some windows were excluded.",
            "developing": f"{base_summary} Only a few windows were comparable.",
            "null": f"{base_summary} The difference stayed small.",
            "contradictory": f"{base_summary} Other windows moved differently.",
            "insufficient_data": f"{base_summary} Too few windows were usable.",
        }[state]
    if intent == "what_is_missing":
        return f"{base_summary} More comparable windows are needed."
    if intent == "what_disagrees":
        return {
            "supported": f"{base_summary} Excluded windows remain a limit.",
            "developing": f"{base_summary} The evidence is still early.",
            "null": f"{base_summary} Several windows moved differently.",
            "contradictory": f"{base_summary} The counter-windows disagree.",
            "insufficient_data": f"{base_summary} Missing windows prevent comparison.",
        }[state]
    if intent == "observe_next":
        return f"{base_summary} Repeat the same check next."
    return {
        "supported": f"{base_summary} It meets the repeated-pattern gate.",
        "developing": f"{base_summary} It does not meet the pattern gate yet.",
        "null": f"{base_summary} It does not meet the pattern gate.",
        "contradictory": f"{base_summary} It does not meet the pattern gate.",
        "insufficient_data": f"{base_summary} It does not meet the pattern gate.",
    }[state]


def _rebalanced_gold_output(
    request: ExplainerRequest, *, variant: int, replica: int
) -> ExplainerOutput:
    """Create a state-contrastive label with intent-specific wording."""

    base = _gold_output(request, variant=variant)
    paragraphs = list(base.paragraphs)
    if replica % 2:
        paragraphs.reverse()
    return base.model_copy(
        update={
            "summary": _intent_summary(request, base.summary),
            "paragraphs": paragraphs,
            "uncertainty": _uncertainty(variant + replica * 5),
        }
    )


def _application_action_gold_output(
    request: ExplainerRequest, *, variant: int
) -> ExplainerOutput:
    """Keep the evidence conclusion stable and answer intent in grounded detail."""
    base = _gold_output(request, variant=variant)

    def value(citation_id: str) -> str:
        return _display_value(request, citation_id)

    intent = request.ask_intent
    state = request.finding_state
    if intent == "explain":
        paragraphs = base.paragraphs
    elif intent == "what_weakens":
        text, citations = {
            "supported": (
                f"The result is limited to {value('included_count')} of {value('candidate_count')} checked event windows, with usable data covering {value('completeness')} of what was needed.",
                ["included_count", "candidate_count", "completeness"],
            ),
            "developing": (
                f"Only {value('included_count')} event windows were comparable, while {value('excluded_count')} were left out.",
                ["included_count", "excluded_count"],
            ),
            "null": (
                f"Although {value('consistent_count')} moved in the same direction, the usual difference was only {value('median_difference')}.",
                ["consistent_count", "median_difference"],
            ),
            "contradictory": (
                f"The split between {value('consistent_count')} in one direction and {value('counter_count')} moving differently prevents a clear result.",
                ["consistent_count", "counter_count"],
            ),
            "insufficient_data": (
                f"Only {value('included_count')} of {value('candidate_count')} checked event windows were usable, with {value('completeness')} of the needed data available.",
                ["included_count", "candidate_count", "completeness"],
            ),
        }[state]
        paragraphs = [CitedParagraph(text=text, citations=citations)]
    elif intent == "what_is_missing":
        text = {
            "supported": f"The check used {value('included_count')} of {value('candidate_count')} event windows and left out {value('excluded_count')}. Future comparable windows would test whether the pattern continues.",
            "developing": f"Only {value('included_count')} of {value('candidate_count')} event windows could be compared. More comparable windows are needed.",
            "null": f"The check used {value('included_count')} of {value('candidate_count')} event windows. More future windows would test whether the small difference persists.",
            "contradictory": f"The check has {value('consistent_count')} in one direction and {value('counter_count')} moving differently. More matched context is needed to separate those groups.",
            "insufficient_data": f"Only {value('included_count')} of {value('candidate_count')} event windows could be compared. More usable windows are needed.",
        }[state]
        citations = (
            ["consistent_count", "counter_count"]
            if state == "contradictory"
            else (
                ["included_count", "candidate_count", "excluded_count"]
                if state == "supported"
                else ["included_count", "candidate_count"]
            )
        )
        paragraphs = [CitedParagraph(text=text, citations=citations)]
    elif intent == "what_disagrees":
        text = {
            "supported": f"No compared window moved differently: {value('counter_count')} disagreed, while {value('consistent_count')} showed the same direction.",
            "developing": f"None of the usable windows moved differently: {value('counter_count')} disagreed, but only {value('included_count')} windows were comparable.",
            "null": f"The same direction appeared in {value('consistent_count')}, while {value('counter_count')} event windows moved differently.",
            "contradictory": f"The same direction appeared in {value('consistent_count')}, while {value('counter_count')} event windows moved differently.",
            "insufficient_data": f"No usable window moved differently: {value('counter_count')} disagreed, but only {value('included_count')} windows could be compared.",
        }[state]
        citations = (
            ["consistent_count", "counter_count"]
            if state in {"supported", "null", "contradictory"}
            else ["counter_count", "included_count"]
        )
        paragraphs = [CitedParagraph(text=text, citations=citations)]
    elif intent == "observe_next":
        paragraphs = [CitedParagraph(
            text=f"The current check used {value('included_count')} comparable event windows. Repeating the same comparison is the next useful check.",
            citations=["included_count"],
        )]
    else:
        gate_text = {
            "supported": f"The repeated-pattern check is met because {value('consistent_count')} comparable windows moved in the same direction.",
            "developing": f"The check is not met yet because only {value('included_count')} comparable event windows were available.",
            "null": f"The check is not met because the usual difference was {value('median_difference')} and stayed small.",
            "contradictory": f"The check is not met because {value('counter_count')} event windows moved differently.",
            "insufficient_data": f"The check is not met because usable data covered only {value('completeness')} of what was needed.",
        }[state]
        gate_citations = {
            "supported": ["consistent_count"],
            "developing": ["included_count"],
            "null": ["median_difference"],
            "contradictory": ["counter_count"],
            "insufficient_data": ["completeness"],
        }[state]
        paragraphs = [CitedParagraph(text=gate_text, citations=gate_citations)]

    return base.model_copy(update={
        "summary": base.summary,
        "paragraphs": paragraphs,
        "uncertainty": _uncertainty(variant),
        "next_observation_id": None,
    })


def build_rebalanced_training_revision(
    base_dataset_dir: Path,
    *,
    output_dir: Path,
    non_supported_multiplier: int = 2,
) -> DatasetBuildResult:
    """Create a v6 training revision while preserving v5 holdouts byte-for-byte."""

    if non_supported_multiplier < 1:
        raise ValueError("non_supported_multiplier must be at least 1")
    if output_dir.exists() and any(output_dir.iterdir()):
        raise FileExistsError(f"refusing to overwrite a non-empty dataset directory: {output_dir}")
    output_dir.mkdir(parents=True, exist_ok=True)
    os.chmod(output_dir, 0o700)

    base_paths = {
        split: base_dataset_dir / f"{split}.jsonl" for split in ("train", "validation", "test")
    }
    for path in base_paths.values():
        if not path.is_file():
            raise FileNotFoundError(path)

    base_train = [
        json.loads(line) for line in base_paths["train"].read_text(encoding="utf-8").splitlines()
    ]
    revised_train: list[dict[str, Any]] = []
    counts_by_state: Counter[str] = Counter()
    intent_counts: Counter[str] = Counter()
    for record in base_train:
        metadata = record["metadata"]
        state = str(metadata["scenario"])
        replicas = 1 if state == "supported" else non_supported_multiplier
        request = _request_from_training_message(record["messages"][1]["content"])
        base_variant = int(metadata["label_template_variant"])
        for replica in range(replicas):
            label = _rebalanced_gold_output(
                request,
                variant=(base_variant + replica * 3) % 12,
                replica=replica,
            )
            evaluation = evaluate_explainer_output(label.model_dump_json(), request)
            if not evaluation.passed:
                raise RuntimeError(
                    f"rebalanced label failed guard for {metadata['case_id']}: {evaluation.errors}"
                )
            updated = json.loads(json.dumps(record))
            updated["messages"][2]["content"] = label.model_dump_json()
            updated["metadata"].update(
                {
                    "dataset_version": REBALANCED_DATASET_VERSION,
                    "source_dataset_version": DATASET_VERSION,
                    "rebalance_replica": replica,
                    "training_weight_class": "baseline"
                    if state == "supported"
                    else "state_recovery",
                }
            )
            updated["metadata"]["case_id"] = f"{metadata['case_id']}_r{replica + 1}"
            revised_train.append(updated)
            counts_by_state[state] += 1
            intent_counts[str(metadata["ask_intent"])] += 1

    train_path = output_dir / "train.jsonl"
    _write_owner_only(
        train_path, "".join(_canonical_json(record) + "\n" for record in revised_train)
    )
    validation_path = output_dir / "validation.jsonl"
    test_path = output_dir / "test.jsonl"
    shutil.copyfile(base_paths["validation"], validation_path)
    shutil.copyfile(base_paths["test"], test_path)
    os.chmod(validation_path, 0o600)
    os.chmod(test_path, 0o600)

    base_manifest_path = base_dataset_dir / "holdout-manifest.json"
    base_manifest_hash = _sha256_text(base_manifest_path.read_text(encoding="utf-8"))
    manifest_path = output_dir / "holdout-manifest.json"
    manifest = {
        "schema_version": HOLDOUT_MANIFEST_SCHEMA,
        "dataset_version": REBALANCED_DATASET_VERSION,
        "source_dataset_version": DATASET_VERSION,
        "training_revision": "state-contrastive-intent-aware-v1",
        "non_supported_multiplier": non_supported_multiplier,
        "validation_and_test_inherited_byte_for_byte": True,
        "source_holdout_manifest_sha256": base_manifest_hash,
    }
    _write_owner_only(manifest_path, json.dumps(manifest, indent=2, sort_keys=True) + "\n")

    hashes = {
        path.name: _sha256_text(path.read_text(encoding="utf-8"))
        for path in (train_path, validation_path, test_path, manifest_path)
    }
    quality_path = output_dir / "dataset-quality.json"
    quality = {
        "schema_version": QUALITY_REPORT_SCHEMA,
        "dataset_version": REBALANCED_DATASET_VERSION,
        "source_dataset_version": DATASET_VERSION,
        "passed": True,
        "training_record_count": len(revised_train),
        "validation_record_count": len(
            base_paths["validation"].read_text(encoding="utf-8").splitlines()
        ),
        "test_record_count": len(base_paths["test"].read_text(encoding="utf-8").splitlines()),
        "training_scenario_counts": dict(sorted(counts_by_state.items())),
        "training_intent_counts": dict(sorted(intent_counts.items())),
        "non_supported_multiplier": non_supported_multiplier,
        "validation_sha256_matches_source": hashes["validation.jsonl"]
        == _sha256_text(base_paths["validation"].read_text(encoding="utf-8")),
        "test_sha256_matches_source": hashes["test.jsonl"]
        == _sha256_text(base_paths["test"].read_text(encoding="utf-8")),
        "all_training_labels_guard_validated": True,
        "state_contrastive_summaries": True,
        "intent_specific_summaries": True,
        "context_reference_split_overlap_count": 0,
        "model_facing_synthetic_marker_count": 0,
        "raw_wearable_data_included": False,
        "raw_canonical_events_included": False,
        "sha256": dict(sorted(hashes.items())),
    }
    _write_owner_only(quality_path, json.dumps(quality, indent=2, sort_keys=True) + "\n")
    hashes[quality_path.name] = _sha256_text(quality_path.read_text(encoding="utf-8"))

    return DatasetBuildResult(
        output_dir=output_dir,
        train_path=train_path,
        validation_path=validation_path,
        test_path=test_path,
        holdout_manifest_path=manifest_path,
        quality_report_path=quality_path,
        split_counts={"train": len(revised_train), "validation": 210, "test": 210},
        hashes=hashes,
    )


def _state_intent_interleave(
    records: Sequence[dict[str, Any]], *, seed: int
) -> list[dict[str, Any]]:
    """Return a deterministic round-robin order across state and intent cells."""

    cells: defaultdict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for record in records:
        metadata = record["metadata"]
        cells[(str(metadata["scenario"]), str(metadata["ask_intent"]))].append(record)
    expected_cells = {(state, intent) for state in _STATES for intent in _INTENTS}
    if set(cells) != expected_cells:
        missing = sorted(expected_cells - set(cells))
        extra = sorted(set(cells) - expected_cells)
        raise ValueError(f"state/intent grid is incomplete; missing={missing}, extra={extra}")
    rng = random.Random(seed)
    for rows in cells.values():
        rng.shuffle(rows)
    states = list(_STATES)
    intents = list(_INTENTS)
    rng.shuffle(states)
    rng.shuffle(intents)
    cell_sizes = {len(rows) for rows in cells.values()}
    if len(cell_sizes) != 1:
        raise ValueError(f"state/intent cells must be exactly balanced: {sorted(cell_sizes)}")
    ordered: list[dict[str, Any]] = []
    rows_per_cell = next(iter(cell_sizes))
    for row_index in range(rows_per_cell):
        for intent_index, intent in enumerate(intents):
            # Rotate the state sequence between intents and rounds so neighboring
            # records never form the state blocks that caused the v6 collapse.
            offset = (row_index + intent_index) % len(states)
            for state_index in range(len(states)):
                state = states[(state_index + offset) % len(states)]
                ordered.append(cells[(state, intent)][row_index])
    return ordered


def build_conditioned_training_revision(
    base_dataset_dir: Path,
    *,
    output_dir: Path,
    seed: int = 20260912,
) -> DatasetBuildResult:
    """Create balanced, intent-aware v7 labels in a state-interleaved train order."""

    if output_dir.exists() and any(output_dir.iterdir()):
        raise FileExistsError(f"refusing to overwrite a non-empty dataset directory: {output_dir}")
    output_dir.mkdir(parents=True, exist_ok=True)
    os.chmod(output_dir, 0o700)
    base_paths = {
        split: base_dataset_dir / f"{split}.jsonl" for split in ("train", "validation", "test")
    }
    for path in base_paths.values():
        if not path.is_file():
            raise FileNotFoundError(path)

    base_train = [
        json.loads(line) for line in base_paths["train"].read_text(encoding="utf-8").splitlines()
    ]
    revised: list[dict[str, Any]] = []
    for record in base_train:
        metadata = record["metadata"]
        request = _request_from_training_message(record["messages"][1]["content"])
        label = _rebalanced_gold_output(
            request,
            variant=int(metadata["label_template_variant"]),
            replica=0,
        )
        evaluation = evaluate_explainer_output(label.model_dump_json(), request)
        if not evaluation.passed:
            raise RuntimeError(
                f"v7 label failed guard for {metadata['case_id']}: {evaluation.errors}"
            )
        updated = json.loads(json.dumps(record))
        updated["messages"][2]["content"] = label.model_dump_json()
        updated["metadata"].update(
            {
                "dataset_version": CONDITIONED_DATASET_VERSION,
                "source_dataset_version": DATASET_VERSION,
                "training_revision": "balanced-state-intent-interleaved-v1",
            }
        )
        revised.append(updated)

    ordered = _state_intent_interleave(revised, seed=seed)
    train_path = output_dir / "train.jsonl"
    _write_owner_only(train_path, "".join(_canonical_json(record) + "\n" for record in ordered))
    validation_path = output_dir / "validation.jsonl"
    test_path = output_dir / "test.jsonl"
    shutil.copyfile(base_paths["validation"], validation_path)
    shutil.copyfile(base_paths["test"], test_path)
    os.chmod(validation_path, 0o600)
    os.chmod(test_path, 0o600)

    counts = Counter(
        (str(record["metadata"]["scenario"]), str(record["metadata"]["ask_intent"]))
        for record in ordered
    )
    state_runs: list[int] = []
    previous_state: str | None = None
    for record in ordered:
        state = str(record["metadata"]["scenario"])
        if state == previous_state:
            state_runs[-1] += 1
        else:
            state_runs.append(1)
            previous_state = state
    manifest_path = output_dir / "holdout-manifest.json"
    manifest = {
        "schema_version": HOLDOUT_MANIFEST_SCHEMA,
        "dataset_version": CONDITIONED_DATASET_VERSION,
        "source_dataset_version": DATASET_VERSION,
        "training_revision": "balanced-state-intent-interleaved-v1",
        "ordering_seed": seed,
        "validation_and_test_inherited_byte_for_byte": True,
        "source_holdout_manifest_sha256": _sha256_text(
            (base_dataset_dir / "holdout-manifest.json").read_text(encoding="utf-8")
        ),
    }
    _write_owner_only(manifest_path, json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    hashes = {
        path.name: _sha256_text(path.read_text(encoding="utf-8"))
        for path in (train_path, validation_path, test_path, manifest_path)
    }
    quality_path = output_dir / "dataset-quality.json"
    quality = {
        "schema_version": QUALITY_REPORT_SCHEMA,
        "dataset_version": CONDITIONED_DATASET_VERSION,
        "source_dataset_version": DATASET_VERSION,
        "passed": len(set(counts.values())) == 1 and max(state_runs) <= 1,
        "training_record_count": len(ordered),
        "validation_record_count": len(validation_path.read_text().splitlines()),
        "test_record_count": len(test_path.read_text().splitlines()),
        "state_intent_cell_count": len(counts),
        "records_per_state_intent_cell": sorted(set(counts.values())),
        "max_contiguous_same_state_run": max(state_runs),
        "ordering_seed": seed,
        "all_training_labels_guard_validated": True,
        "validation_sha256_matches_source": hashes["validation.jsonl"]
        == _sha256_text(base_paths["validation"].read_text(encoding="utf-8")),
        "test_sha256_matches_source": hashes["test.jsonl"]
        == _sha256_text(base_paths["test"].read_text(encoding="utf-8")),
        "context_reference_split_overlap_count": 0,
        "model_facing_synthetic_marker_count": 0,
        "raw_wearable_data_included": False,
        "raw_canonical_events_included": False,
        "sha256": dict(sorted(hashes.items())),
    }
    _write_owner_only(quality_path, json.dumps(quality, indent=2, sort_keys=True) + "\n")
    hashes[quality_path.name] = _sha256_text(quality_path.read_text(encoding="utf-8"))
    if not quality["passed"]:
        raise RuntimeError(f"v7 dataset quality gate failed: {quality}")
    return DatasetBuildResult(
        output_dir=output_dir,
        train_path=train_path,
        validation_path=validation_path,
        test_path=test_path,
        holdout_manifest_path=manifest_path,
        quality_report_path=quality_path,
        split_counts={"train": len(ordered), "validation": 210, "test": 210},
        hashes=hashes,
    )


def build_application_action_training_revision(
    base_dataset_dir: Path,
    *,
    output_dir: Path,
    seed: int = 20260912,
) -> DatasetBuildResult:
    """Create v8 with state-invariant summaries and application-owned actions."""
    if output_dir.exists() and any(output_dir.iterdir()):
        raise FileExistsError(f"refusing to overwrite a non-empty dataset directory: {output_dir}")
    output_dir.mkdir(parents=True, exist_ok=True)
    os.chmod(output_dir, 0o700)
    base_paths = {
        split: base_dataset_dir / f"{split}.jsonl" for split in ("train", "validation", "test")
    }
    for path in base_paths.values():
        if not path.is_file():
            raise FileNotFoundError(path)

    revised_by_split: dict[str, list[dict[str, Any]]] = {}
    summaries_by_group: defaultdict[str, set[str]] = defaultdict(set)
    for split, path in base_paths.items():
        revised: list[dict[str, Any]] = []
        for record in (json.loads(line) for line in path.read_text().splitlines()):
            metadata = record["metadata"]
            request = _request_from_training_message(record["messages"][1]["content"])
            label = _application_action_gold_output(
                request, variant=int(metadata["label_template_variant"])
            )
            evaluation = evaluate_explainer_output(label.model_dump_json(), request)
            if not evaluation.passed:
                raise RuntimeError(
                    f"v8 label failed guard for {metadata['case_id']}: {evaluation.errors}"
                )
            updated = json.loads(json.dumps(record))
            updated["messages"][2]["content"] = label.model_dump_json()
            updated["metadata"].update({
                "dataset_version": APPLICATION_ACTION_DATASET_VERSION,
                "source_dataset_version": DATASET_VERSION,
                "training_revision": "state-invariant-application-action-v1",
            })
            revised.append(updated)
            summaries_by_group[str(metadata["group_id"])].add(label.summary)
        revised_by_split[split] = revised

    revised_by_split["train"] = _state_intent_interleave(revised_by_split["train"], seed=seed)
    paths: dict[str, Path] = {}
    for split in ("train", "validation", "test"):
        paths[split] = output_dir / f"{split}.jsonl"
        _write_owner_only(
            paths[split],
            "".join(_canonical_json(record) + "\n" for record in revised_by_split[split]),
        )

    summary_violation_count = sum(len(summaries) != 1 for summaries in summaries_by_group.values())
    action_target_count = sum(
        json.loads(record["messages"][2]["content"])["next_observation_id"] is not None
        for records in revised_by_split.values()
        for record in records
    )
    counts = Counter(
        (str(record["metadata"]["scenario"]), str(record["metadata"]["ask_intent"]))
        for record in revised_by_split["train"]
    )
    states = [str(record["metadata"]["scenario"]) for record in revised_by_split["train"]]
    max_state_run = max((sum(1 for _ in run) for _, run in groupby(states)), default=0)
    manifest_path = output_dir / "holdout-manifest.json"
    manifest = {
        "schema_version": HOLDOUT_MANIFEST_SCHEMA,
        "dataset_version": APPLICATION_ACTION_DATASET_VERSION,
        "source_dataset_version": DATASET_VERSION,
        "training_revision": "state-invariant-application-action-v1",
        "ordering_seed": seed,
        "holdout_evidence_inputs_inherited": True,
        "holdout_expected_assistant_outputs_revised": True,
        "model_owns_next_observation_id": False,
        "source_holdout_manifest_sha256": _sha256_text(
            (base_dataset_dir / "holdout-manifest.json").read_text()
        ),
    }
    _write_owner_only(manifest_path, json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    hashes = {
        path.name: _sha256_text(path.read_text()) for path in (*paths.values(), manifest_path)
    }
    quality_path = output_dir / "dataset-quality.json"
    quality = {
        "schema_version": QUALITY_REPORT_SCHEMA,
        "dataset_version": APPLICATION_ACTION_DATASET_VERSION,
        "source_dataset_version": DATASET_VERSION,
        "passed": len(set(counts.values())) == 1 and max_state_run <= 1 and summary_violation_count == 0 and action_target_count == 0,
        "training_record_count": len(revised_by_split["train"]),
        "validation_record_count": len(revised_by_split["validation"]),
        "test_record_count": len(revised_by_split["test"]),
        "state_intent_cell_count": len(counts),
        "records_per_state_intent_cell": sorted(set(counts.values())),
        "max_contiguous_same_state_run": max_state_run,
        "state_invariant_summary_violation_count": summary_violation_count,
        "model_owned_action_target_count": action_target_count,
        "all_labels_guard_validated": True,
        "context_reference_split_overlap_count": 0,
        "model_facing_synthetic_marker_count": 0,
        "raw_wearable_data_included": False,
        "raw_canonical_events_included": False,
        "sha256": dict(sorted(hashes.items())),
    }
    _write_owner_only(quality_path, json.dumps(quality, indent=2, sort_keys=True) + "\n")
    hashes[quality_path.name] = _sha256_text(quality_path.read_text())
    if not quality["passed"]:
        raise RuntimeError(f"v8 dataset quality gate failed: {quality}")
    return DatasetBuildResult(
        output_dir=output_dir,
        train_path=paths["train"],
        validation_path=paths["validation"],
        test_path=paths["test"],
        holdout_manifest_path=manifest_path,
        quality_report_path=quality_path,
        split_counts={split: len(records) for split, records in revised_by_split.items()},
        hashes=hashes,
    )


def write_state_intent_sentinel(dataset_dir: Path, output_dir: Path) -> dict[str, Any]:
    """Write one privacy-safe validation case for every state and intent cell."""

    if output_dir.exists() and any(output_dir.iterdir()):
        raise FileExistsError(f"refusing to overwrite a non-empty sentinel directory: {output_dir}")
    validation_path = dataset_dir / "validation.jsonl"
    if not validation_path.is_file():
        raise FileNotFoundError(validation_path)
    records = [json.loads(line) for line in validation_path.read_text().splitlines()]
    selected: dict[tuple[str, str], dict[str, Any]] = {}
    for record in records:
        metadata = record["metadata"]
        key = (str(metadata["scenario"]), str(metadata["ask_intent"]))
        selected.setdefault(key, record)
    expected = {(state, intent) for state in _STATES for intent in _INTENTS}
    if set(selected) != expected:
        raise ValueError("validation split does not cover the complete state/intent grid")
    output_dir.mkdir(parents=True, exist_ok=True)
    os.chmod(output_dir, 0o700)
    ordered = [selected[(state, intent)] for state in _STATES for intent in _INTENTS]
    messages_path = output_dir / "sentinel.jsonl"
    _write_owner_only(
        messages_path,
        "".join(_canonical_json({"messages": record["messages"]}) + "\n" for record in ordered),
    )
    cases = []
    for index, record in enumerate(ordered):
        output = json.loads(record["messages"][2]["content"])
        metadata = record["metadata"]
        cases.append(
            {
                "case_index": index,
                "case_id": metadata["case_id"],
                "finding_state": metadata["scenario"],
                "ask_intent": metadata["ask_intent"],
                "context_reference_id": output["context_reference_id"],
                "expected_next_observation_id": output["next_observation_id"],
                "expected_summary": output["summary"],
            }
        )
    manifest = {
        "schema_version": "vueniverse-state-intent-sentinel-v1",
        "case_count": len(cases),
        "state_count": len(_STATES),
        "intent_count": len(_INTENTS),
        "messages_sha256": _sha256_text(messages_path.read_text()),
        "cases": cases,
    }
    manifest_path = output_dir / "sentinel-manifest.json"
    _write_owner_only(manifest_path, json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    return {"messages": str(messages_path), "manifest": str(manifest_path), **manifest}
