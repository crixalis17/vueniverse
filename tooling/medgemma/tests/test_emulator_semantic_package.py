"""Integrity regression tests over the committed, inspected (not model) package."""

import json
import shutil
from pathlib import Path

import pytest

from vueniverse_medgemma.emulator_semantic_package import parse, seal, validate_inputs, verify

PACKAGE = Path(__file__).resolve().parents[3] / "experiments/readiness/emulator-semantic-v1"


@pytest.fixture
def copy(tmp_path):
    target = tmp_path / "package"
    shutil.copytree(PACKAGE, target)
    return target


def test_committed_package_has_no_inference():
    assert verify(PACKAGE) == {
        "verified": True,
        "requests": 15,
        "rendered_prompts": 30,
        "model_attempts": 0,
    }


@pytest.mark.parametrize("mutation", ("prompt", "extra", "missing", "symlink"))
def test_tampering_fails(copy, mutation):
    prompt = next((copy / "rendered").glob("*.prompt.txt"))
    if mutation == "prompt":
        prompt.write_bytes(prompt.read_bytes() + b"changed")
    elif mutation == "extra":
        (copy / "personal.json").write_text("{}")
    elif mutation == "missing":
        prompt.unlink()
    else:
        (copy / "unsafe").symlink_to(prompt)
    with pytest.raises(ValueError):
        verify(copy)


def test_resealing_refuses_before_writing(copy):
    before = (copy / "manifest.json").read_bytes()
    with pytest.raises(ValueError, match="Already sealed"):
        seal(copy, copy, "not-a-commit")
    assert (copy / "manifest.json").read_bytes() == before


def test_duplicate_keys_rejected():
    with pytest.raises(ValueError, match="Duplicate"):
        parse('{"case_id":"a","case_id":"b"}')


@pytest.mark.parametrize("mutation", ("case", "wire", "identity", "gate", "context_claim"))
def test_semantic_linkage_checks_independent_of_manifest(copy, mutation):
    path = copy / "app-projections.jsonl"
    entries = [json.loads(line) for line in path.read_text().splitlines()]
    row = entries[0]
    if mutation == "case":
        row["case_id"] = entries[1]["case_id"]
    elif mutation == "wire":
        row["request_wire_json"] += " "
    elif mutation == "identity":
        row["evidence_bundle_id"] = "0" * 64
    elif mutation == "gate":
        row["expected_analytics"]["promotion_gates"]["completeness"] = False
    else:
        hostpath = copy / "rendered/host-export-metadata.json"
        host = json.loads(hostpath.read_text())
        host["context_fit_verified"] = True
        hostpath.write_text(json.dumps(host))
    path.write_text("\n".join(json.dumps(row) for row in entries) + "\n")
    with pytest.raises(ValueError):
        validate_inputs(copy)
