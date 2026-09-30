import json
from collections import Counter

import pytest

from vueniverse_medgemma.cloud_training import (
    _request_from_messages,
    _stratified_training_order,
    _training_order_audit,
)
from vueniverse_medgemma.context_references import derive_context_reference
from vueniverse_medgemma.finetuning import (
    PRIVATE_PROFILE_SCHEMA,
    SYNTHETIC_CASE_SCHEMA,
    calibrate_ultrahuman_directory,
    generate_synthetic_evidence_cases,
    load_calibration_profile,
    write_calibration_profile,
    write_synthetic_cases,
)
from vueniverse_medgemma.schemas import ExplainerRequest
from vueniverse_medgemma.training_dataset import (
    build_application_action_training_revision,
    build_conditioned_training_revision,
    build_rebalanced_training_revision,
    build_supervised_dataset,
    explainer_training_user_message,
    freeze_group_assignments,
    write_state_intent_sentinel,
)


def test_v8_keeps_state_summary_fixed_and_model_action_null(tmp_path) -> None:
    profile, _ = _profile(tmp_path)
    base = build_supervised_dataset(profile, output_dir=tmp_path / "v5", seed=22)
    revised = build_application_action_training_revision(
        base.output_dir, output_dir=tmp_path / "v8", seed=91
    )
    records = [json.loads(line) for line in revised.train_path.read_text().splitlines()]
    summaries: dict[str, set[str]] = {}
    paragraphs: dict[str, set[str]] = {}
    for record in records:
        group_id = record["metadata"]["group_id"]
        output = json.loads(record["messages"][2]["content"])
        summaries.setdefault(group_id, set()).add(output["summary"])
        paragraphs.setdefault(group_id, set()).add(output["paragraphs"][0]["text"])
        assert output["next_observation_id"] is None

    quality = json.loads(revised.quality_report_path.read_text())
    assert revised.split_counts == {"train": 840, "validation": 210, "test": 210}
    assert all(len(values) == 1 for values in summaries.values())
    assert all(len(values) > 1 for values in paragraphs.values())
    assert quality["state_invariant_summary_violation_count"] == 0
    assert quality["model_owned_action_target_count"] == 0
    assert quality["passed"] is True


def test_v7_dataset_is_balanced_and_state_interleaved(tmp_path) -> None:
    profile, _ = _profile(tmp_path)
    base = build_supervised_dataset(profile, output_dir=tmp_path / "v5", seed=22)
    first = build_conditioned_training_revision(
        base.output_dir,
        output_dir=tmp_path / "v7-first",
        seed=91,
    )
    second = build_conditioned_training_revision(
        base.output_dir,
        output_dir=tmp_path / "v7-second",
        seed=91,
    )
    records = [json.loads(line) for line in first.train_path.read_text().splitlines()]
    cells = Counter(
        (record["metadata"]["scenario"], record["metadata"]["ask_intent"]) for record in records
    )
    quality = json.loads(first.quality_report_path.read_text())

    assert first.split_counts == {"train": 840, "validation": 210, "test": 210}
    assert len(cells) == 30
    assert set(cells.values()) == {28}
    assert quality["passed"] is True
    assert quality["max_contiguous_same_state_run"] == 1
    assert first.train_path.read_bytes() == second.train_path.read_bytes()
    assert first.validation_path.read_bytes() == base.validation_path.read_bytes()
    assert first.test_path.read_bytes() == base.test_path.read_bytes()


def test_cloud_training_reorders_state_blocked_projection_deterministically(tmp_path) -> None:
    profile, _ = _profile(tmp_path)
    base = build_supervised_dataset(profile, output_dir=tmp_path / "v5", seed=22)
    records = [json.loads(line) for line in base.train_path.read_text().splitlines()]
    blocked = sorted(
        records,
        key=lambda record: (
            record["metadata"]["scenario"],
            record["metadata"]["ask_intent"],
        ),
    )
    messages = [record["messages"] for record in blocked]

    first = _stratified_training_order(messages.copy(), seed=77)
    second = _stratified_training_order(messages.copy(), seed=77)
    states = [_request_from_messages(item).finding_state for item in first]

    assert first == second
    assert first != messages
    assert len(first) == len(messages)
    assert all(left != right for left, right in zip(states, states[1:], strict=False))
    audit = _training_order_audit(first, accumulation_steps=30)
    assert audit["max_contiguous_same_state_run"] == 1
    assert len(audit["state_intent_counts"]) == 30
    assert set(audit["state_intent_counts"].values()) == {28}
    assert set(audit["accumulation_window_unique_cell_counts"]) == {30}
    assert audit["all_accumulation_windows_have_unique_cells"] is True
    assert len(audit["training_order_sha256"]) == 64


def test_state_intent_sentinel_has_exactly_one_case_per_cell(tmp_path) -> None:
    profile, _ = _profile(tmp_path)
    base = build_supervised_dataset(profile, output_dir=tmp_path / "v5", seed=22)

    result = write_state_intent_sentinel(base.output_dir, tmp_path / "sentinel")
    rows = [
        json.loads(line) for line in (tmp_path / "sentinel/sentinel.jsonl").read_text().splitlines()
    ]
    cells = {(case["finding_state"], case["ask_intent"]) for case in result["cases"]}

    assert result["case_count"] == 30
    assert result["state_count"] == 5
    assert result["intent_count"] == 6
    assert len(rows) == 30
    assert len(cells) == 30
    assert all(set(row) == {"messages"} for row in rows)


def test_rebalanced_training_revision_preserves_holdouts_and_strengthens_states(tmp_path) -> None:
    profile, _ = _profile(tmp_path)
    base = build_supervised_dataset(profile, output_dir=tmp_path / "v5", seed=22)
    revised = build_rebalanced_training_revision(
        base.output_dir,
        output_dir=tmp_path / "v6",
        non_supported_multiplier=2,
    )

    assert revised.split_counts == {"train": 1512, "validation": 210, "test": 210}
    assert revised.validation_path.read_bytes() == base.validation_path.read_bytes()
    assert revised.test_path.read_bytes() == base.test_path.read_bytes()
    records = [json.loads(line) for line in revised.train_path.read_text().splitlines()]
    scenarios = Counter(record["metadata"]["scenario"] for record in records)
    assert scenarios == {
        "supported": 168,
        "developing": 336,
        "null": 336,
        "contradictory": 336,
        "insufficient_data": 336,
    }
    summaries = {
        record["metadata"]["scenario"]: json.loads(record["messages"][2]["content"])["summary"]
        for record in records
        if record["metadata"]["ask_intent"] == "promotion_gate"
    }
    assert "meets the repeated-pattern gate" in summaries["supported"]
    assert "does not meet the pattern gate" in summaries["developing"]
    assert "does not meet the pattern gate" in summaries["null"]
    assert "does not meet the pattern gate" in summaries["contradictory"]
    assert "does not meet the pattern gate" in summaries["insufficient_data"]


def _payload() -> dict:
    return {
        "status": 200,
        "error": None,
        "data": {
            "latest_time_zone": "private/timezone",
            "metrics": {
                "private-date": [
                    {
                        "type": "hr",
                        "object": {
                            "values": [
                                {"timestamp": 1_700_000_000, "value": 61},
                                {"timestamp": 1_700_000_060, "value": 73},
                                {"timestamp": 1_700_000_120, "value": 82},
                            ]
                        },
                    },
                    {
                        "type": "hrv",
                        "object": {
                            "values": [
                                {"timestamp": 1_700_000_000, "value": 31},
                                {"timestamp": 1_700_000_060, "value": 47},
                            ]
                        },
                    },
                ]
            },
        },
    }


def _profile(tmp_path):
    private_dir = tmp_path / "private"
    private_dir.mkdir()
    for index in range(2):
        (private_dir / f"probe-{index}.json").write_text(json.dumps(_payload()), encoding="utf-8")
    return calibrate_ultrahuman_directory(private_dir), private_dir


def test_calibration_coarsens_private_payloads_without_exporting_timeline(tmp_path) -> None:
    profile, _ = _profile(tmp_path)

    assert profile["schema_version"] == PRIVATE_PROFILE_SCHEMA
    assert profile["input_file_count"] == 2
    assert profile["metric_profiles"]["hr"]["days_present"] == 2
    serialized = json.dumps(profile)
    assert "private-date" not in serialized
    assert "private/timezone" not in serialized
    assert "1700000000" not in serialized


def test_synthetic_cases_are_deterministic_and_validate_against_request_schema(tmp_path) -> None:
    profile, _ = _profile(tmp_path)

    first = generate_synthetic_evidence_cases(profile, count=12, seed=11)
    second = generate_synthetic_evidence_cases(profile, count=12, seed=11)

    assert first == second
    assert len({case["case_id"] for case in first}) == 12
    assert {case["metadata"]["scenario"] for case in first} >= {
        "supported",
        "null",
        "contradictory",
        "insufficient_data",
    }
    assert all(case["schema_version"] == SYNTHETIC_CASE_SCHEMA for case in first)
    assert all(case["metadata"]["source"] == "synthetic_calibrated" for case in first)
    assert all(
        case["metadata"]["calibration_mode"] == "coarsened_sampling_variability" for case in first
    )
    assert all(
        case["metadata"]["synthetic_event_context"]["category"] == "recurring_one_to_one"
        for case in first
    )
    for case in first:
        request = ExplainerRequest.model_validate(case["request"])
        assert request.evidence_version == "synthetic-calibrated-v1"
        assert "Ultrahuman" not in json.dumps(case)
        assert "timestamp" not in json.dumps(case)


def test_private_and_synthetic_outputs_are_written_and_reloaded(tmp_path) -> None:
    _, private_dir = _profile(tmp_path)
    profile_path = tmp_path / "outputs" / "calibration.json"
    cases_path = tmp_path / "outputs" / "cases.jsonl"

    write_calibration_profile(private_dir, profile_path)
    assert load_calibration_profile(profile_path)["schema_version"] == PRIVATE_PROFILE_SCHEMA
    write_synthetic_cases(profile_path, cases_path, count=3, seed=9)

    records = [json.loads(line) for line in cases_path.read_text(encoding="utf-8").splitlines()]
    assert len(records) == 3


def test_calibration_requires_heart_rate_series(tmp_path) -> None:
    private_dir = tmp_path / "private"
    private_dir.mkdir()
    (private_dir / "probe-1.json").write_text(json.dumps({"data": {"metrics": {}}}))

    with pytest.raises(ValueError, match="heart-rate"):
        calibrate_ultrahuman_directory(private_dir)


def test_supervised_dataset_freezes_grouped_splits_and_validates_all_labels(tmp_path) -> None:
    profile, _ = _profile(tmp_path)
    assignments = freeze_group_assignments(seed=22)

    assert len(assignments) == 1260
    assert {assignment["split"] for assignment in assignments} == {
        "train",
        "validation",
        "test",
    }
    assert {assignment["scenario"] for assignment in assignments} == {
        "supported",
        "developing",
        "null",
        "contradictory",
        "insufficient_data",
    }
    assert {assignment["canonical_context"]["context_family"] for assignment in assignments} == {
        "recurring_meeting",
        "discord_game_session",
        "spotify_listening",
        "phone_call",
        "screen_time",
        "manual_journal",
        "food_beverage_log",
    }
    references_by_split = {}
    for assignment in assignments:
        context_reference = assignment["canonical_context"]["context_reference_id"]
        references_by_split.setdefault(context_reference, set()).add(assignment["split"])
    assert all(len(splits) == 1 for splits in references_by_split.values())
    assert len(references_by_split) == 210

    result = build_supervised_dataset(profile, output_dir=tmp_path / "dataset", seed=22)

    assert result.split_counts == {"test": 210, "train": 840, "validation": 210}
    report = json.loads(result.quality_report_path.read_text(encoding="utf-8"))
    manifest = json.loads(result.holdout_manifest_path.read_text(encoding="utf-8"))
    assert report["passed"] is True
    assert report["group_split_overlap_count"] == 0
    assert report["context_reference_split_overlap_count"] == 0
    assert report["context_reference_count"] == 210
    assert report["records_per_context_reference"] == [6]
    assert report["duplicate_prompt_count"] == 0
    assert report["duplicate_assistant_output_count"] == 0
    assert report["model_facing_synthetic_marker_count"] == 0
    assert report["canonical_context_counts_by_split"]["test"] == {
        "discord_game_session": 30,
        "food_beverage_log": 30,
        "manual_journal": 30,
        "phone_call": 30,
        "recurring_meeting": 30,
        "screen_time": 30,
        "spotify_listening": 30,
    }
    assert manifest["frozen_before_label_generation"] is True

    serialized = "".join(
        path.read_text(encoding="utf-8")
        for path in (result.train_path, result.validation_path, result.test_path)
    )
    assert "Ultrahuman" not in serialized
    assert "timestamp" not in serialized
    assert "phone_number" not in serialized
    assert "song_title" not in serialized
    assert "journal_text" not in serialized
    all_records = [
        json.loads(line)
        for path in (result.train_path, result.validation_path, result.test_path)
        for line in path.read_text(encoding="utf-8").splitlines()
    ]
    assert all("synthetic" not in json.dumps(record["messages"]).lower() for record in all_records)
    assert all(record["metadata"]["source"] == "synthetic_calibrated" for record in all_records)
    assert len({record["metadata"]["case_id"] for record in all_records}) == len(all_records)
    supported = next(
        record for record in all_records if record["metadata"]["scenario"] == "supported"
    )
    normal = next(record for record in all_records if record["metadata"]["scenario"] == "null")
    supported_output = json.loads(supported["messages"][2]["content"])
    normal_output = json.loads(normal["messages"][2]["content"])
    assert "stands out" in supported_output["summary"]
    assert "canonical_context" in supported_output["paragraphs"][0]["citations"]
    assert (
        supported_output["context_reference_id"]
        == supported["metadata"]["canonical_context"]["context_reference_id"]
    )
    assert "no clear repeated" in normal_output["summary"]
    first_record = json.loads(result.train_path.read_text(encoding="utf-8").splitlines()[0])
    request = ExplainerRequest.model_validate(
        {
            "evidence_version": "synthetic-calibrated-v1",
            "finding_state": first_record["metadata"]["scenario"],
            "metrics": [
                {
                    "citation_id": "count",
                    "label": "Count",
                    "value_text": "1",
                    "definition": "Synthetic count",
                    "source": "Synthetic",
                }
            ],
            "exclusion_ids": [],
            "counterevidence_ids": [],
            "unresolved_influence_ids": [],
            "approved_next_observations": {},
            "ask_intent": first_record["metadata"]["ask_intent"],
            "user_question": "placeholder",
        }
    )
    # The message builder is reusable for training and later PyTorch evaluation; it
    # includes the constrained output schema that the serving benchmark supplies out
    # of band through JSON grammar.
    assert "Required JSON schema" in explainer_training_user_message(request)


def test_context_references_are_stable_but_scoped_to_the_local_secret() -> None:
    secret = b"reference-test-secret-is-long-enough"
    first = derive_context_reference(
        context_family="spotify_listening",
        stable_source_key="private-track-id",
        secret=secret,
    )
    repeated = derive_context_reference(
        context_family="spotify_listening",
        stable_source_key="private-track-id",
        secret=secret,
    )
    changed = derive_context_reference(
        context_family="spotify_listening",
        stable_source_key="another-private-track-id",
        secret=secret,
    )
    other_secret = derive_context_reference(
        context_family="spotify_listening",
        stable_source_key="private-track-id",
        secret=b"different-reference-secret-key",
    )

    assert first == repeated
    assert first != changed
    assert first != other_secret
    assert first.startswith("ctx_")
    assert "private-track-id" not in first
