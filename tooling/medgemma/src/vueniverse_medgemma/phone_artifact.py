"""Verified identities for supervised phone staging, without downloading bytes."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

PINS = {
    "vanilla": {
        "filename": "medgemma-1.5-4b-it-Q4_K_M.gguf",
        "size_bytes": 2489894976,
        "sha256": "b31becdf4f39561800505514cce67681604fe449d04dd35c8c92fd7848c6d7bd",
        "revision": "1fe03a2916e0a4ed250fdeedc3e56a94f3bf2a30",
    },
    "lora-v7": {
        "filename": "medgemma-1.5-4b-it-lora-v7-Q4_K_M.gguf",
        "size_bytes": 2489893568,
        "sha256": "dd9c2a212672a5bb18affbc344a4c0fcf4e9000b3b5155d6fdfe9a8104bad234",
        "revision": "lora-v7-q4-dd9c2a212672a5bb",
    },
}


def selected_pin(variant: str, manifest: Path | None = None) -> dict:
    """A manifest cannot authorize arbitrary model bytes or override a pinned hash."""
    if variant not in PINS:
        raise ValueError("unknown phone model variant")
    if variant == "lora-v7" and manifest is None:
        raise ValueError("LoRA phone staging requires an explicit candidate manifest")
    pin = PINS[variant].copy()
    if manifest is not None:
        candidate = json.loads(manifest.read_text())["artifact"]
        for key, value in pin.items():
            if candidate.get(key) != value:
                raise ValueError(f"candidate manifest differs from pinned {key}")
    return pin


def verify_file(path: Path, pin: dict) -> None:
    if path.stat().st_size != pin["size_bytes"]:
        raise ValueError("model byte count does not match selected artifact")
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    if digest.hexdigest() != pin["sha256"]:
        raise ValueError("model SHA-256 does not match selected artifact")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("model", type=Path)
    parser.add_argument("--variant", choices=PINS, default="vanilla")
    parser.add_argument("--manifest", type=Path)
    args = parser.parse_args()
    pin = selected_pin(args.variant, args.manifest)
    verify_file(args.model, pin)
    print(f"{pin['filename']}\t{pin['size_bytes']}\t{pin['sha256']}")


if __name__ == "__main__":
    main()
