from pathlib import Path

from whypulse_medgemma import MODEL_ID, MODEL_REVISION
from whypulse_medgemma.settings import Settings


def test_defaults_are_latest_model_and_ignored_repo_paths() -> None:
    settings = Settings.from_environment()

    assert settings.model_id == MODEL_ID == "google/medgemma-1.5-4b-it"
    assert settings.model_revision == MODEL_REVISION
    assert settings.hf_dir.parts[-2:] == ("models", "medgemma-1.5-4b-it")
    assert settings.q4_gguf.name.endswith("Q4_K_M.gguf")
    assert settings.q5_gguf.name.endswith("Q5_K_M.gguf")
    assert isinstance(settings.report_dir, Path)
