import pytest

from vueniverse_medgemma.prompt_catalog import (
    MAX_REPAIR_ATTEMPTS,
    PROMPTS,
    load_prompt,
    prompt_hash,
    prompt_metadata,
)


def test_prompt_ids_versions_and_hashes_are_unique_and_complete() -> None:
    assert set(PROMPTS) == {
        "explainer_system",
        "explorer_system",
        "guard_repair_system",
        "pigeon_explainer_system",
    }
    assert all(spec.version >= 1 for spec in PROMPTS.values())
    assert len({spec.sha256 for spec in PROMPTS.values()}) == len(PROMPTS)
    assert all(len(spec.sha256) == 64 for spec in PROMPTS.values())


@pytest.mark.parametrize("prompt_id", list(PROMPTS))
def test_committed_prompt_content_matches_versioned_hash(prompt_id) -> None:
    text = load_prompt(prompt_id)

    assert prompt_hash(text) == PROMPTS[prompt_id].sha256
    assert prompt_metadata(prompt_id)["prompt_version"] == PROMPTS[prompt_id].version


def test_prompt_safety_requirements_are_present() -> None:
    explainer = load_prompt("explainer_system").lower()
    repair = load_prompt("guard_repair_system").lower()
    pigeon = load_prompt("pigeon_explainer_system").lower()

    for requirement in ("json only", "cite", "uncertainty", "diagnos", "causality"):
        assert requirement in explainer
    for requirement in ("only repair attempt", "raw records", "allowed", "json only"):
        assert requirement in repair
    for requirement in (
        "pigeon",
        "citedparagraphsjson",
        "diagnos",
        "everyday words",
        "copy numbers exactly",
    ):
        assert requirement in pigeon
    assert MAX_REPAIR_ATTEMPTS == 1
