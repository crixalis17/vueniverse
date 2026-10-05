import hashlib
import json
from pathlib import Path

import pytest

from vueniverse_medgemma.phone_artifact import PINS, selected_pin, verify_file


def test_default_remains_vanilla_and_lora_requires_explicit_manifest():
    assert selected_pin("vanilla") == PINS["vanilla"]
    with pytest.raises(ValueError, match="explicit candidate manifest"):
        selected_pin("lora-v7")
    with pytest.raises(ValueError, match="unknown"):
        selected_pin("surprise")


def test_candidate_and_rollback_have_separate_identity(tmp_path):
    manifest = tmp_path / "candidate.json"
    manifest.write_text(json.dumps({"artifact": PINS["lora-v7"]}))
    assert selected_pin("lora-v7", manifest) == PINS["lora-v7"]
    assert PINS["vanilla"]["filename"] != PINS["lora-v7"]["filename"]
    assert PINS["vanilla"]["revision"] != PINS["lora-v7"]["revision"]
    with pytest.raises(ValueError, match="differs"):
        selected_pin("vanilla", manifest)


def test_repository_candidate_manifest_matches_both_retained_pins():
    manifest = (
        Path(__file__).resolve().parents[3]
        / "experiments/readiness/phone-lora-v7-candidate-v1.json"
    )
    payload = json.loads(manifest.read_text())
    assert selected_pin("lora-v7", manifest) == PINS["lora-v7"]
    for key, value in PINS["vanilla"].items():
        assert payload["rollback"][key] == value
    assert payload["runtime_contract"]["android_prompt_compatibility_verified"] is False
    assert payload["target_device"]["physically_verified"] is False


@pytest.mark.parametrize("key", ["filename", "size_bytes", "sha256", "revision"])
def test_manifest_cannot_override_pinned_identity(tmp_path, key):
    artifact = PINS["lora-v7"].copy()
    artifact[key] = "wrong"
    manifest = tmp_path / "candidate.json"
    manifest.write_text(json.dumps({"artifact": artifact}))
    with pytest.raises(ValueError, match="differs"):
        selected_pin("lora-v7", manifest)


def test_verify_streamed_bytes_checks_size_and_digest(tmp_path):
    model = tmp_path / "fixture.gguf"
    model.write_bytes(b"fixture")
    pin = {"size_bytes": 7, "sha256": hashlib.sha256(b"fixture").hexdigest()}
    verify_file(model, pin)
    with pytest.raises(ValueError, match="byte count"):
        verify_file(model, {**pin, "size_bytes": 8})
    with pytest.raises(ValueError, match="SHA-256"):
        verify_file(model, {**pin, "sha256": "0" * 64})
