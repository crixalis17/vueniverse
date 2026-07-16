"""Artifact hashing and provenance manifests."""

from __future__ import annotations

import hashlib
import json
import platform
import subprocess
import sys
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(8 * 1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def git_revision(repository: Path) -> str:
    result = subprocess.run(
        ["git", "-C", str(repository), "rev-parse", "HEAD"],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def artifact_record(path: Path) -> dict[str, Any]:
    resolved = path.resolve()
    return {
        "path": str(resolved),
        "bytes": resolved.stat().st_size,
        "sha256": sha256_file(resolved),
    }


def write_manifest(
    output: Path,
    *,
    model_id: str,
    model_revision: str,
    llama_cpp_dir: Path,
    artifacts: list[Path],
) -> None:
    missing = [str(path) for path in artifacts if not path.is_file()]
    if missing:
        raise FileNotFoundError(f"Missing artifacts: {missing}")

    document = {
        "schema_version": 1,
        "created_at_utc": datetime.now(UTC).isoformat(),
        "model_id": model_id,
        "model_revision": model_revision,
        "llama_cpp_revision": git_revision(llama_cpp_dir),
        "python": sys.version.split()[0],
        "platform": platform.platform(),
        "artifacts": [artifact_record(path) for path in artifacts],
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(document, indent=2) + "\n", encoding="utf-8")
