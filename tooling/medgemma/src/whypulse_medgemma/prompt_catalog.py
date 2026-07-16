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
        2,
        "explainer_system.txt",
        "575a1f5617dd6cce4695f06b08ae5deecd147d7abb93ff4daf7aff454b61e065",
    ),
    "explorer_system": PromptSpec(
        "explorer_system",
        2,
        "explorer_system.txt",
        "de007e440d994145de6098f0d6b09f32b9682bd771f0cd7f8169bb84afa7eda3",
    ),
    "guard_repair_system": PromptSpec(
        "guard_repair_system",
        1,
        "guard_repair_system.txt",
        "9ebc79510020025b8cf2f28b25c5542e153ee21ffde80f86ec7f539fd76b7994",
    ),
    "pigeon_explainer_system": PromptSpec(
        "pigeon_explainer_system",
        1,
        "pigeon_explainer_system.txt",
        "ed73f7103c8eebdfc80aa0cc8fc99fea8f52cb97be34a52bfa1f415c7f092095",
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
