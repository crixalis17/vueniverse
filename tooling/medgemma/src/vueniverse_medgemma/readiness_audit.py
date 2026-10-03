"""Integrity and review-contract checks for app-derived development benchmarks."""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter
from pathlib import Path
from typing import Any


def _jsonl(path: Path) -> list[dict[str, Any]]:
    rows = [json.loads(line) for line in path.read_text().splitlines() if line.strip()]
    if any(not isinstance(row, dict) for row in rows):
        raise ValueError(f"Expected JSON objects in {path.name}")
    return rows


def audit_package(directory: Path, contract: Path) -> dict[str, Any]:
    manifest = json.loads((directory / "manifest.json").read_text())
    hashes = {
        "projection_sha256": directory / "app-projections.jsonl",
        "raw_timelines_sha256": directory / "raw-timelines.jsonl",
        "contract_sha256": contract,
    }
    for key, path in hashes.items():
        actual = hashlib.sha256(path.read_bytes()).hexdigest()
        if actual != manifest.get(key):
            raise ValueError(f"Hash mismatch: {key}")
    projections = _jsonl(directory / "app-projections.jsonl")
    raw = _jsonl(directory / "raw-timelines.jsonl")
    raw_ids = [row["case_id"] for row in raw]
    case_ids = [row["case_id"] for row in projections]
    if len(set(raw_ids)) != len(raw_ids) or len(set(case_ids)) != len(case_ids):
        raise ValueError("Duplicate timeline or projection case ID")
    if len(projections) != manifest["case_count"] or len(raw) != manifest["cluster_count"]:
        raise ValueError("Manifest case count mismatch")
    cluster_splits: dict[str, set[str]] = {}
    for row in projections:
        cluster = row["cluster_id"]
        if cluster not in raw_ids:
            raise ValueError("Projection has no backing raw timeline")
        backing = raw[raw_ids.index(cluster)]
        actual = hashlib.sha256(
            json.dumps(backing, separators=(",", ":"), ensure_ascii=False).encode()
        ).hexdigest()
        if actual != row["raw_input_sha256"]:
            raise ValueError("Projection/raw timeline mismatch")
        if row["schema_versions"] != manifest["schema_versions"]:
            raise ValueError("Mixed analytical versions")
        cluster_splits.setdefault(cluster, set()).add(row["split"])
    if any(len(splits) != 1 for splits in cluster_splits.values()):
        raise ValueError("Scenario cluster crosses splits")
    if manifest.get("final_evaluation") or any(
        row["split"] != "development" for row in projections
    ):
        raise ValueError("This inspected generator is development-only")
    return {
        "integrity": "passed",
        "cases": len(projections),
        "clusters": len(raw),
        "cluster_split_audit": "passed",
        "states": dict(Counter(row["expected_analytical_state"] for row in projections)),
        "deterministic_guard_passes": sum(
            bool(row["deterministic_baseline"]["guard_accepted"]) for row in projections
        ),
        "independent_review": "pending",
        "prior_training_semantic_overlap": "manual_audit_required",
        "final_evaluation": False,
        "release_ready": False,
    }


def validate_judgment(row: dict[str, Any]) -> None:
    for field in ("case_id", "blinded_output_id", "reviewer_id", "rationale"):
        if not isinstance(row.get(field), str) or not row[field].strip():
            raise ValueError(f"Missing judgment field: {field}")
    scores = [row.get(field) for field in ("grounding", "uncertainty", "safety", "usefulness")]
    if any(type(score) is not int or score not in (0, 1, 2) for score in scores):
        raise ValueError("Scores must be integers 0, 1 or 2")
    for field in ("evidence_references", "error_codes"):
        if not isinstance(row.get(field), list) or any(
            not isinstance(item, str) or not item.strip() for item in row[field]
        ):
            raise ValueError(f"Invalid judgment field: {field}")
    if not row["evidence_references"]:
        raise ValueError("A semantic judgment requires evidence references")
    expected = (
        "fail"
        if scores[0] == 0 or scores[2] == 0 or ("unusable_answer" in row["error_codes"])
        else "pass"
        if all(score == 2 for score in scores)
        else "needs_review"
    )
    if row.get("verdict") != expected:
        raise ValueError(f"Verdict inconsistent with rubric; expected {expected}")


def summarize_judgments(rows: list[dict[str, Any]]) -> dict[str, Any]:
    identities = set()
    for row in rows:
        validate_judgment(row)
        key = row["case_id"], row["blinded_output_id"], row["reviewer_id"]
        if key in identities:
            raise ValueError("Duplicate reviewer judgment")
        identities.add(key)
    verdicts = Counter(row["verdict"] for row in rows)
    return {
        "judgment_count": len(rows),
        "verdicts": dict(verdicts),
        "verdict_weighted_usefulness": (
            (verdicts["pass"] + 0.5 * verdicts["needs_review"]) / len(rows) if rows else None
        ),
        "clinical_accuracy": None,
        "release_ready": False,
        "note": "Summary is not independent adjudication or proof of final-set coverage.",
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--contract", type=Path, required=True)
    parser.add_argument("--judgments", type=Path)
    args = parser.parse_args()
    report = audit_package(args.directory, args.contract)
    if args.judgments:
        report["review_summary"] = summarize_judgments(_jsonl(args.judgments))
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
