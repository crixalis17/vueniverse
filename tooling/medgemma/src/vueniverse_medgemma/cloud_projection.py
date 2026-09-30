"""Export the model-only view of the approved supervised dataset for cloud training."""

from __future__ import annotations

import hashlib
import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from vueniverse_medgemma.cloud_preflight import inspect_cloud_upload_dataset

TRAINING_PROJECTION_SCHEMA = "vueniverse-cloud-training-projection-v1"
_SPLITS = ("train", "validation", "test")


@dataclass(frozen=True)
class CloudTrainingProjection:
    output_dir: Path
    record_counts: dict[str, int]
    hashes: dict[str, str]
    manifest_path: Path


def _sha256_path(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _messages_only(record: dict[str, Any]) -> dict[str, Any]:
    messages = record.get("messages")
    if not isinstance(messages, list):
        raise ValueError("preflight-approved record has no messages list")
    return {"messages": messages}


def write_cloud_training_projection(dataset_dir: Path, output_dir: Path) -> CloudTrainingProjection:
    """Write immutable JSONL splits containing only model-facing chat messages.

    The full dataset first passes the local cloud-upload gate.  The resulting files have
    no metadata keys, so the cloud VM and its trainer cannot consume provenance or
    local-only canonical event fields accidentally.
    """

    preflight = inspect_cloud_upload_dataset(dataset_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    os.chmod(output_dir, 0o700)

    counts: dict[str, int] = {}
    hashes: dict[str, str] = {}
    for split in _SPLITS:
        source_path = dataset_dir / f"{split}.jsonl"
        target_path = output_dir / f"{split}.jsonl"
        projected_lines: list[str] = []
        for line in source_path.read_text(encoding="utf-8").splitlines():
            record = json.loads(line)
            projected_lines.append(
                json.dumps(_messages_only(record), sort_keys=True, separators=(",", ":"))
            )
        target_path.write_text("\n".join(projected_lines) + "\n", encoding="utf-8")
        os.chmod(target_path, 0o600)
        counts[split] = len(projected_lines)
        hashes[target_path.name] = _sha256_path(target_path)

    manifest = {
        "schema_version": TRAINING_PROJECTION_SCHEMA,
        "dataset_version": preflight.dataset_version,
        "training_projection": "messages",
        "metadata_sent_to_model": False,
        "record_counts": counts,
        "source_dataset_sha256": preflight.hashes,
        "projection_sha256": dict(sorted(hashes.items())),
    }
    manifest_path = output_dir / "projection-manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    os.chmod(manifest_path, 0o600)
    return CloudTrainingProjection(output_dir, counts, hashes, manifest_path)
