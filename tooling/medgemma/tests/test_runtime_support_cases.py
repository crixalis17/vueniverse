import json
import re
from pathlib import Path


def _fixtures() -> list[dict]:
    repository = Path(__file__).resolve().parents[3]
    document = (
        repository / "docs" / "medgemma-evaluation" / "runtime-support-cases.md"
    ).read_text(encoding="utf-8")
    return [json.loads(block) for block in re.findall(r"```json\n(.*?)\n```", document, re.DOTALL)]


def test_support_fixture_set_is_complete_and_versioned() -> None:
    fixtures = _fixtures()

    assert {fixture["caseId"] for fixture in fixtures} == {
        "phone_model_unavailable",
        "development_backend_disconnect",
        "evidence_version_mismatch",
        "accepted_cached_output",
    }
    assert all(fixture["schemaVersion"] == "vueniverse-runtime-support-v1" for fixture in fixtures)
    assert all(fixture["requestEvidenceVersion"].startswith("fictional-") for fixture in fixtures)


def test_failures_and_cache_actions_are_deterministic() -> None:
    fixtures = {fixture["caseId"]: fixture for fixture in _fixtures()}

    unavailable = fixtures["phone_model_unavailable"]
    assert unavailable["result"]["failure"] == "missing_model"
    assert unavailable["expectedAction"] == "deterministic_fallback"

    disconnect = fixtures["development_backend_disconnect"]
    assert disconnect["serviceError"]["error"] == {
        "code": "backend_disconnect",
        "message": "llama-server disconnected during inference",
        "retryable": True,
    }

    mismatch = fixtures["evidence_version_mismatch"]
    assert mismatch["requestEvidenceVersion"] != mismatch["cachedEvidenceVersion"]
    assert mismatch["expectedAction"] == "invalidate_cached_output"

    accepted = fixtures["accepted_cached_output"]
    assert accepted["requestEvidenceVersion"] == accepted["cachedEvidenceVersion"]
    assert accepted["result"]["safety"] == {"accepted": True, "failures": []}
    assert accepted["expectedAction"] == "reopen_cached_output_without_inference"


def test_support_fixtures_contain_no_personal_or_app_persistence_data() -> None:
    serialized = json.dumps(_fixtures()).lower()
    forbidden = (
        "databasepath",
        "calendaraccount",
        "contactname",
        "emailaddress",
        "accesstoken",
        "refreshtoken",
        "ultrahuman",
    )

    assert not any(value in serialized for value in forbidden)
