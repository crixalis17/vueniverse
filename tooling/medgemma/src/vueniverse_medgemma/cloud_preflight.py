"""Validate the immutable supervised corpus before a cloud upload.

This is deliberately a data-boundary gate, not an uploader.  It verifies that the
dataset passed local quality checks and that the future trainer consumes only the chat
``messages`` projection.  No cloud credential or raw source data is used here.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
from collections import Counter, defaultdict
from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from vueniverse_medgemma.training_dataset import (
    APPLICATION_ACTION_DATASET_VERSION,
    CONDITIONED_DATASET_VERSION,
    DATASET_VERSION,
    REBALANCED_DATASET_VERSION,
)

CLOUD_UPLOAD_PREFLIGHT_SCHEMA = "vueniverse-cloud-upload-preflight-v1"
_SPLITS = ("train", "validation", "test")
_EXPECTED_COUNTS_BY_VERSION = {
    DATASET_VERSION: {"train": 840, "validation": 210, "test": 210},
    REBALANCED_DATASET_VERSION: {"train": 1512, "validation": 210, "test": 210},
    CONDITIONED_DATASET_VERSION: {"train": 840, "validation": 210, "test": 210},
    APPLICATION_ACTION_DATASET_VERSION: {"train": 840, "validation": 210, "test": 210},
}
_FORBIDDEN_MARKERS = ("ultrahuman", "timestamp", "phone_number", "song_title", "journal_text")
_CONTEXT_REFERENCE = re.compile(r"^ctx_[0-9a-f]{16}$")


@dataclass(frozen=True)
class CloudUploadPreflightResult:
    dataset_dir: Path
    dataset_version: int
    record_counts: dict[str, int]
    hashes: dict[str, str]
    context_reference_count: int
    context_reference_split_overlap_count: int
    manifest: dict[str, Any]


def _sha256_path(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _load_jsonl(path: Path) -> list[dict[str, Any]]:
    try:
        return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]
    except json.JSONDecodeError as error:
        raise ValueError(f"invalid JSONL in {path.name}: {error.msg}") from error


def inspect_cloud_upload_dataset(dataset_dir: Path) -> CloudUploadPreflightResult:
    """Reject any dataset that is not an approved cloud-training projection."""

    quality_path = dataset_dir / "dataset-quality.json"
    if not quality_path.is_file():
        raise ValueError("dataset-quality.json is missing")
    quality = json.loads(quality_path.read_text(encoding="utf-8"))
    if not isinstance(quality, Mapping):
        raise ValueError("dataset-quality.json is not an object")
    dataset_version = quality.get("dataset_version")
    if dataset_version not in _EXPECTED_COUNTS_BY_VERSION:
        raise ValueError("dataset version is not approved for cloud upload")
    expected_counts = _EXPECTED_COUNTS_BY_VERSION[int(dataset_version)]
    if quality.get("passed") is not True:
        raise ValueError("dataset quality report did not pass")
    if quality.get("raw_wearable_data_included") is not False:
        raise ValueError("dataset reports raw wearable data")
    if quality.get("raw_canonical_events_included") is not False:
        raise ValueError("dataset reports raw canonical events")
    if quality.get("model_facing_synthetic_marker_count") != 0:
        raise ValueError("dataset has a model-facing provenance marker")
    if quality.get("context_reference_split_overlap_count") != 0:
        raise ValueError("dataset has a context-reference split overlap")

    records_by_split: dict[str, list[dict[str, Any]]] = {}
    hashes: dict[str, str] = {}
    references_by_split: dict[str, set[str]] = defaultdict(set)
    references_per_split: Counter[str] = Counter()
    for split in _SPLITS:
        path = dataset_dir / f"{split}.jsonl"
        if not path.is_file():
            raise ValueError(f"{path.name} is missing")
        hashes[path.name] = _sha256_path(path)
        expected_hashes = quality.get("sha256")
        if (
            not isinstance(expected_hashes, Mapping)
            or expected_hashes.get(path.name) != hashes[path.name]
        ):
            raise ValueError(f"{path.name} hash does not match its quality report")
        records = _load_jsonl(path)
        if len(records) != expected_counts[split]:
            raise ValueError(f"{path.name} has an unexpected record count")
        records_by_split[split] = records

        for record in records:
            messages = record.get("messages")
            metadata = record.get("metadata")
            if not isinstance(messages, list) or not isinstance(metadata, Mapping):
                raise ValueError(f"{path.name} contains an invalid record shape")
            if [message.get("role") for message in messages] != ["system", "user", "assistant"]:
                raise ValueError(f"{path.name} contains invalid chat roles")
            model_text = json.dumps(messages, sort_keys=True).lower()
            if "synthetic" in model_text:
                raise ValueError(f"{path.name} has a model-facing provenance marker")
            serialized = json.dumps(record, sort_keys=True).lower()
            if any(marker in serialized for marker in _FORBIDDEN_MARKERS):
                raise ValueError(f"{path.name} has a forbidden privacy marker")
            context = metadata.get("canonical_context")
            if not isinstance(context, Mapping):
                raise ValueError(f"{path.name} has no canonical context")
            reference = context.get("context_reference_id")
            if not isinstance(reference, str) or not _CONTEXT_REFERENCE.fullmatch(reference):
                raise ValueError(f"{path.name} has an invalid context reference")
            references_by_split[reference].add(split)
            references_per_split[reference] += 1
            try:
                output = json.loads(str(messages[2].get("content", "")))
            except json.JSONDecodeError as error:
                raise ValueError(f"{path.name} has invalid assistant JSON") from error
            if output.get("context_reference_id") != reference:
                raise ValueError(f"{path.name} has an assistant context-reference mismatch")

    overlapping_references = [
        reference for reference, splits in references_by_split.items() if len(splits) > 1
    ]
    if overlapping_references:
        raise ValueError("context reference crossed a cloud-training split")
    allowed_reference_counts = (
        {6}
        if dataset_version
        in {DATASET_VERSION, CONDITIONED_DATASET_VERSION, APPLICATION_ACTION_DATASET_VERSION}
        else {6, 12}
    )
    if any(count not in allowed_reference_counts for count in references_per_split.values()):
        raise ValueError("context reference has an unexpected number of training records")

    manifest = {
        "schema_version": CLOUD_UPLOAD_PREFLIGHT_SCHEMA,
        "dataset_version": dataset_version,
        "training_projection": "messages",
        "metadata_sent_to_model": False,
        "record_counts": {split: len(records_by_split[split]) for split in _SPLITS},
        "context_reference_count": len(references_by_split),
        "context_reference_split_overlap_count": len(overlapping_references),
        "privacy": {
            "raw_wearable_data_included": False,
            "raw_canonical_events_included": False,
            "model_facing_synthetic_marker_count": 0,
        },
        "sha256": dict(sorted(hashes.items())),
    }
    return CloudUploadPreflightResult(
        dataset_dir=dataset_dir,
        dataset_version=int(dataset_version),
        record_counts=dict(manifest["record_counts"]),
        hashes=dict(manifest["sha256"]),
        context_reference_count=len(references_by_split),
        context_reference_split_overlap_count=len(overlapping_references),
        manifest=manifest,
    )


def write_cloud_upload_preflight(
    dataset_dir: Path, output_path: Path
) -> CloudUploadPreflightResult:
    """Write an owner-only manifest once the dataset passes the cloud boundary gate."""

    result = inspect_cloud_upload_dataset(dataset_dir)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    os.chmod(output_path.parent, 0o700)
    output_path.write_text(
        json.dumps(result.manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    os.chmod(output_path, 0o600)
    return result
