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
        3,
        "explainer_system.txt",
        "16c71ebc5b2d9d7b8e253a1a00c562df674445f4ddfaba3842e3bd5ddb907ff8",
    ),
    "explorer_system": PromptSpec(
        "explorer_system",
        2,
        "explorer_system.txt",
        "de007e440d994145de6098f0d6b09f32b9682bd771f0cd7f8169bb84afa7eda3",
    ),
    "guard_repair_system": PromptSpec(
        "guard_repair_system",
        2,
        "guard_repair_system.txt",
        "abb7ff838a4609bb4e3ab6c099ddde5e6b257f42050385c22c791dc0db543df2",
    ),
    "pigeon_explainer_system": PromptSpec(
        "pigeon_explainer_system",
        2,
        "pigeon_explainer_system.txt",
        "9829011c4f8d147e311228352eaffd10463b31c18ca043cebf8d5634796733e8",
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
