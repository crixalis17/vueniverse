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
        6,
        "explainer_system.txt",
        "ce061a0e5c6cbf049968df0e1da34d4e508d61dca1b80fce0e76a472563177d0",
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
        5,
        "pigeon_explainer_system.txt",
        "c96ac518e039148ec9f7ac496911e911fd1379d641d586503de3c9722c700ac7",
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
