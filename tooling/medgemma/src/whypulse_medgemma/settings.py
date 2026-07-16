"""Resolved, ignored paths for the MedGemma development pipeline."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from whypulse_medgemma import MODEL_ID, MODEL_REVISION


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def _path_from_env(name: str, default: str) -> Path:
    value = Path(os.environ.get(name, default)).expanduser()
    if value.is_absolute():
        return value
    return _repo_root() / value


@dataclass(frozen=True)
class Settings:
    model_id: str
    model_revision: str
    hf_dir: Path
    f16_gguf: Path
    q4_gguf: Path
    q5_gguf: Path
    report_dir: Path

    @property
    def tool_dir(self) -> Path:
        return _repo_root() / "tooling" / "medgemma"

    @classmethod
    def from_environment(cls) -> Settings:
        return cls(
            model_id=os.environ.get("MEDGEMMA_MODEL_ID", MODEL_ID),
            model_revision=os.environ.get("MEDGEMMA_MODEL_REVISION", MODEL_REVISION),
            hf_dir=_path_from_env("MEDGEMMA_HF_DIR", "models/medgemma-1.5-4b-it"),
            f16_gguf=_path_from_env("MEDGEMMA_F16_GGUF", "models/medgemma-1.5-4b-it-f16.gguf"),
            q4_gguf=_path_from_env("MEDGEMMA_Q4_GGUF", "models/medgemma-1.5-4b-it-Q4_K_M.gguf"),
            q5_gguf=_path_from_env("MEDGEMMA_Q5_GGUF", "models/medgemma-1.5-4b-it-Q5_K_M.gguf"),
            report_dir=_path_from_env("MEDGEMMA_REPORT_DIR", "tooling/medgemma/reports/generated"),
        )

    def ensure_local_directories(self) -> None:
        self.hf_dir.parent.mkdir(parents=True, exist_ok=True)
        self.report_dir.mkdir(parents=True, exist_ok=True)
