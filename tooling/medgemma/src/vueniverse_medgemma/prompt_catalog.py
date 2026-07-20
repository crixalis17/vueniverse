"""Immutable prompt versions and integrity metadata."""

from __future__ import annotations

import hashlib
from dataclasses import dataclass
from pathlib import Path
from typing import Literal

PromptId = Literal[
    "explainer_system",
    "explorer_system",
    "guard_repair_system",
    "pigeon_explainer_system",
]
MAX_REPAIR_ATTEMPTS = 1


@dataclass(frozen=True)
class PromptSpec:
    prompt_id: PromptId
    version: int
    filename: str
    sha256: str


PROMPTS: dict[PromptId, PromptSpec] = {
    "explainer_system": PromptSpec(
        "explainer_system",
        4,
        "explainer_system.txt",
        "6a31e4ea14cd7bca6e48eb0c12350bc3922122aa5c5401ebdae14bbf69eb4890",
    ),
    "explorer_system": PromptSpec(
        "explorer_system",
        3,
        "explorer_system.txt",
        "4cde402b7972f7501cf0d5c0844a338d1ff74bd38721c45c51ba4eba00f0535d",
    ),
    "guard_repair_system": PromptSpec(
        "guard_repair_system",
        3,
        "guard_repair_system.txt",
        "b2f49065203523227d2a558c8488826dd0626c79bded94a72bb4462f00595a5c",
    ),
    "pigeon_explainer_system": PromptSpec(
        "pigeon_explainer_system",
        3,
        "pigeon_explainer_system.txt",
        "536c170dfcb98c5109dff019eacc2627b443306a8232d51b5b3f4f3be9811f25",
    ),
}


def prompt_directory() -> Path:
    return Path(__file__).resolve().parents[2] / "prompts"


def prompt_hash(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def load_prompt(prompt_id: PromptId, *, verify: bool = True) -> str:
    spec = PROMPTS[prompt_id]
    text = (prompt_directory() / spec.filename).read_text(encoding="utf-8")
    actual = prompt_hash(text)
    if verify and actual != spec.sha256:
        raise RuntimeError(
            f"prompt {prompt_id} changed without a version/hash update: "
            f"expected {spec.sha256}, got {actual}"
        )
    return text


def prompt_metadata(prompt_id: PromptId) -> dict[str, str | int]:
    spec = PROMPTS[prompt_id]
    load_prompt(prompt_id)
    return {
        "prompt_id": spec.prompt_id,
        "prompt_version": spec.version,
        "prompt_sha256": spec.sha256,
    }
