import json

import pytest

from vueniverse_medgemma.cloud_evaluation import (
    _assistant_json_prefill,
    _decode_assistant_response,
    _is_complete_json_object,
    _is_complete_schema_valid_json,
    _normalize_terminal_fence,
    _processor_messages,
    _request_from_messages,
    _resolve_max_new_tokens,
)
from vueniverse_medgemma.cloud_preflight import (
    CLOUD_UPLOAD_PREFLIGHT_SCHEMA,
    inspect_cloud_upload_dataset,
    write_cloud_upload_preflight,
)
from vueniverse_medgemma.cloud_projection import (
    TRAINING_PROJECTION_SCHEMA,
    write_cloud_training_projection,
)
from vueniverse_medgemma.cloud_training import _read_projection
from vueniverse_medgemma.finetuning import PRIVATE_PROFILE_SCHEMA
from vueniverse_medgemma.training_dataset import (
    build_application_action_training_revision,
    build_conditioned_training_revision,
    build_supervised_dataset,
)


def test_cloud_preflight_accepts_v8_application_owned_actions(tmp_path) -> None:
    base = build_supervised_dataset(_profile(), output_dir=tmp_path / "v5", seed=41)
    v8 = build_application_action_training_revision(
        base.output_dir, output_dir=tmp_path / "v8", seed=91
    )

    preflight = inspect_cloud_upload_dataset(v8.output_dir)

    assert preflight.dataset_version == 8
    assert preflight.record_counts == {"train": 840, "validation": 210, "test": 210}


def _profile() -> dict:
    return {
        "schema_version": PRIVATE_PROFILE_SCHEMA,
        "metric_profiles": {
            "hr": {
                "sample_count_band": {"low": 5, "typical": 7, "high": 10},
                "value_band": {"low": 55, "typical": 65, "high": 80},
            }
        },
    }


def test_cloud_preflight_accepts_only_the_messages_projection(tmp_path) -> None:
    dataset_dir = tmp_path / "dataset"
    build_supervised_dataset(_profile(), output_dir=dataset_dir, seed=41)

    result = inspect_cloud_upload_dataset(dataset_dir)
    output_path = tmp_path / "preflight.json"
    written = write_cloud_upload_preflight(dataset_dir, output_path)
    manifest = json.loads(output_path.read_text(encoding="utf-8"))

    assert result.record_counts == {"train": 840, "validation": 210, "test": 210}
    assert written.context_reference_count == 210
    assert manifest["schema_version"] == CLOUD_UPLOAD_PREFLIGHT_SCHEMA
    assert manifest["training_projection"] == "messages"
    assert manifest["metadata_sent_to_model"] is False


def test_cloud_preflight_accepts_balanced_v7_and_projection(tmp_path) -> None:
    base = build_supervised_dataset(_profile(), output_dir=tmp_path / "v5", seed=41)
    v7 = build_conditioned_training_revision(
        base.output_dir,
        output_dir=tmp_path / "v7",
        seed=91,
    )

    preflight = inspect_cloud_upload_dataset(v7.output_dir)
    projection = write_cloud_training_projection(v7.output_dir, tmp_path / "projection")

    assert preflight.dataset_version == 7
    assert preflight.record_counts == {"train": 840, "validation": 210, "test": 210}
    assert projection.record_counts == preflight.record_counts


def test_cloud_preflight_rejects_a_model_facing_privacy_marker(tmp_path) -> None:
    dataset_dir = tmp_path / "dataset"
    result = build_supervised_dataset(_profile(), output_dir=dataset_dir, seed=41)
    train_path = result.train_path
    records = [json.loads(line) for line in train_path.read_text(encoding="utf-8").splitlines()]
    records[0]["messages"][1]["content"] += " synthetic"
    train_path.write_text(
        "".join(json.dumps(record, sort_keys=True) + "\n" for record in records),
        encoding="utf-8",
    )

    with pytest.raises(ValueError, match="hash does not match"):
        inspect_cloud_upload_dataset(dataset_dir)


def test_cloud_projection_exports_messages_without_metadata(tmp_path) -> None:
    dataset_dir = tmp_path / "dataset"
    build_supervised_dataset(_profile(), output_dir=dataset_dir, seed=41)

    result = write_cloud_training_projection(dataset_dir, tmp_path / "projection")
    projection = json.loads(result.manifest_path.read_text(encoding="utf-8"))
    first_record = json.loads((result.output_dir / "train.jsonl").read_text().splitlines()[0])

    assert result.record_counts == {"train": 840, "validation": 210, "test": 210}
    assert projection["schema_version"] == TRAINING_PROJECTION_SCHEMA
    assert projection["training_projection"] == "messages"
    assert projection["metadata_sent_to_model"] is False
    assert set(first_record) == {"messages"}
    assert "synthetic" not in json.dumps(first_record).lower()


def test_cloud_evaluation_rebuilds_request_from_model_view_only(tmp_path) -> None:
    dataset_dir = tmp_path / "dataset"
    build_supervised_dataset(_profile(), output_dir=dataset_dir, seed=41)
    projection = write_cloud_training_projection(dataset_dir, tmp_path / "projection")
    first_record = json.loads((projection.output_dir / "test.jsonl").read_text().splitlines()[0])

    request = _request_from_messages(first_record["messages"])

    assert request.evidence_version == "v5_messages_projection"
    assert request.context_reference is not None
    assert request.context_reference.context_reference_id.startswith("ctx_")
    assert request.ask_intent in {
        "explain",
        "what_weakens",
        "what_is_missing",
        "what_disagrees",
        "observe_next",
        "promotion_gate",
    }
    assert _processor_messages(first_record["messages"])[1]["content"] == [
        {"type": "text", "text": first_record["messages"][1]["content"]}
    ]
    assert _processor_messages(first_record["messages"], assistant_prefill="{")[-1] == {
        "role": "assistant",
        "content": [{"type": "text", "text": "{"}],
    }


def test_qlora_smoke_reads_only_messages_projection(tmp_path) -> None:
    dataset_dir = tmp_path / "dataset"
    build_supervised_dataset(_profile(), output_dir=dataset_dir, seed=41)
    projection = write_cloud_training_projection(dataset_dir, tmp_path / "projection")

    messages_by_case = _read_projection(projection.output_dir / "train.jsonl", limit=2)

    assert len(messages_by_case) == 2
    assert all(
        [message["role"] for message in messages] == ["system", "user", "assistant"]
        for messages in messages_by_case
    )


class _FakeTextConfig:
    max_position_embeddings = 8192


class _FakeModelConfig:
    text_config = _FakeTextConfig()


class _FakeModel:
    config = _FakeModelConfig()


class _ParsedResponseProcessor:
    def decode(self, _token_ids, *, skip_special_tokens: bool) -> str:
        if not skip_special_tokens:
            return '<thought>private planning</thought>{"summary":"final"}'
        return "visible fallback"

    def parse_response(self, _completion: str) -> dict[str, str]:
        return {"content": '{"summary":"final"}'}


def test_cloud_evaluation_uses_remaining_model_context_without_an_arbitrary_default() -> None:
    generated, mode, window = _resolve_max_new_tokens(
        _FakeModel(), input_length=312, requested_max_new_tokens=None
    )

    assert (generated, mode, window) == (7880, "model_context_remaining", 8192)
    assert _resolve_max_new_tokens(
        _FakeModel(), input_length=312, requested_max_new_tokens=512
    ) == (512, "explicit_override", 8192)


def test_cloud_evaluation_prefers_a_parsed_final_answer_over_thought_tokens() -> None:
    response, mode = _decode_assistant_response(_ParsedResponseProcessor(), [1, 2, 3])

    assert response == '{"summary":"final"}'
    assert mode == "processor_parsed_final_answer"


def test_cloud_evaluation_prefills_authoritative_fields_and_normalizes_only_a_terminal_fence(
    tmp_path,
) -> None:
    dataset_dir = tmp_path / "dataset"
    build_supervised_dataset(_profile(), output_dir=dataset_dir, seed=41)
    projection = write_cloud_training_projection(dataset_dir, tmp_path / "projection")
    first_record = json.loads((projection.output_dir / "test.jsonl").read_text().splitlines()[0])
    request = _request_from_messages(first_record["messages"])

    assert _assistant_json_prefill(request).startswith(
        '{"schema_version":2,"context_reference_id":"ctx_'
    )
    assert _normalize_terminal_fence('{"summary":"complete"}\n```') == (
        '{"summary":"complete"}',
        "removed_terminal_fence",
    )
    assert _normalize_terminal_fence('{"summary":"complete"}\nextra') == (
        '{"summary":"complete"}\nextra',
        "unexpected_trailing_text",
    )


def test_schema_completion_stop_requires_one_complete_output_contract() -> None:
    valid = {
        "schema_version": 2,
        "context_reference_id": "ctx_test",
        "summary": "A concise summary.",
        "paragraphs": [{"text": "A cited observation.", "citations": ["hr"]}],
        "uncertainty": "This is only an observation.",
        "unresolved_influence_ids": [],
        "next_observation_id": None,
    }

    rendered = json.dumps(valid)
    assert _is_complete_json_object(rendered)
    assert _is_complete_schema_valid_json(rendered)
    assert not _is_complete_schema_valid_json(rendered[:-1])
    assert not _is_complete_schema_valid_json(rendered + " trailing")
    assert _is_complete_json_object('{"summary":"wrong contract"}')
    assert not _is_complete_schema_valid_json('{"summary":"incomplete contract"}')
