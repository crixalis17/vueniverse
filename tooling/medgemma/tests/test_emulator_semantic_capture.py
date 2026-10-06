"""Transport-only mocks; these are not inferred answers or scored model cases."""

import base64
import json
from pathlib import Path

import pytest

from vueniverse_medgemma.emulator_semantic_capture import CHUNK, EVENT, decode_capture
from vueniverse_medgemma.emulator_semantic_package import digest, rows

PACKAGE = Path(__file__).resolve().parents[3] / "experiments/readiness/emulator-semantic-v1"
RUN = "transport_mock"


def chunk(payload, kind):
    data = json.dumps(payload).encode()
    envelope = {
        "capture_id": RUN + "-0",
        "intent": "why_promoted",
        "kind": kind,
        "index": 0,
        "count": 1,
        "sha256": digest(data),
        "data_b64": base64.b64encode(data).decode(),
    }
    return CHUNK + json.dumps(envelope)


def fixture_log(complete=True):
    frozen = rows(PACKAGE / "app-projections.jsonl")[0]
    identity = {
        "run_id": RUN,
        "case_id": frozen["case_id"],
        "variant": "lora_v7",
        "request_wire_sha256": frozen["request_wire_sha256"],
    }
    dto = {
        "evidenceVersion": frozen["pigeon_request"]["evidenceVersion"],
        "output": None,
        "failure": "invalid_model_output",
        "metadata": {
            "runtime": "phoneMedGemma",
            "promptVersion": 8,
            "modelName": "transport-mock@lora-v7-q4-dd9c2a212672a5bb",
            "schemaValid": False,
        },
    }
    model = {
        **identity,
        "raw_dto": dto,
        "from_cache": False,
        "elapsed_ms": 12,
        "guard_result": {"accepted": False, "failures": ["invalid_schema"]},
    }
    delivery = {
        **identity,
        "delivery_is_simulation": True,
        "coordinator_executed": False,
        "from_cache": False,
        "fallback": True,
        "delivery_mode": "deterministic",
    }
    lines = [
        EVENT + json.dumps({"event": "run_start", "run_id": RUN}),
        EVENT + json.dumps({"event": "case_start", **identity}),
        '{"prompt_tokens":1600,"generated_tokens":512,"stop_reason":"max_output_tokens"}',
        chunk(model, "model_attempt"),
        chunk(delivery, "app_delivery"),
        EVENT + json.dumps({"event": "case_end", **identity}),
    ]
    if complete:
        lines.append(
            EVENT
            + json.dumps(
                {
                    "event": "run_complete",
                    "run_id": RUN,
                    "attempted_cases": 1,
                    "unattempted_cases": 14,
                }
            )
        )
    return "\n".join(lines)


def test_stopped_capture_is_not_model_success():
    report = decode_capture(fixture_log(), RUN, PACKAGE)
    assert report["run_complete_event"]
    assert report["attempted_cases"] == 1 and report["unattempted_cases"] == 14
    assert report["schema_valid_count"] == report["automated_guard_accepted_count"] == 0
    assert report["semantic_review"] == "pending"


def test_in_progress_capture_is_not_finalized():
    assert not decode_capture(fixture_log(False), RUN, PACKAGE)["run_complete_event"]


def test_duplicate_chunks_rejected():
    log = fixture_log()
    duplicate = next(line for line in log.splitlines() if line.startswith(CHUNK))
    with pytest.raises(ValueError, match="Duplicate"):
        decode_capture(log + "\n" + duplicate, RUN, PACKAGE)


def test_checksum_mismatch_rejected():
    lines = fixture_log().splitlines()
    position = next(index for index, line in enumerate(lines) if line.startswith(CHUNK))
    envelope = json.loads(lines[position][len(CHUNK) :])
    envelope["data_b64"] = base64.b64encode(b"{}").decode()
    lines[position] = CHUNK + json.dumps(envelope)
    with pytest.raises(ValueError, match="checksum"):
        decode_capture("\n".join(lines), RUN, PACKAGE)


def test_completed_missing_delivery_is_capture_failure():
    lines = [
        line
        for line in fixture_log().splitlines()
        if not (line.startswith(CHUNK) and '"kind": "app_delivery"' in line)
    ]
    with pytest.raises(ValueError, match="lost capture"):
        decode_capture("\n".join(lines), RUN, PACKAGE)


def test_mixed_runs_rejected():
    with pytest.raises(ValueError, match="Mixed"):
        decode_capture(
            fixture_log().replace('"run_id": "transport_mock"', '"run_id": "wrong"', 1),
            RUN,
            PACKAGE,
        )
