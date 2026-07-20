import json
import threading
import urllib.error
import urllib.request
from pathlib import Path

import pytest

import vueniverse_medgemma.service.app as app_module
from vueniverse_medgemma.service.app import DemoRuntime, DemoRuntimeConfig
from vueniverse_medgemma.service.cli import fictional_demo_payload
from vueniverse_medgemma.service.models import BackendFailure, BackendInferenceResult


def _fixture_payload(store: str = "demo") -> dict:
    return {
        "schemaVersion": "vueniverse-model-service-v1",
        "store": store,
        "timeoutMillis": 30_000,
        "maxOutputTokens": 384,
        "request": {
            "schemaVersion": "explainer-v1",
            "evidenceVersion": "fictional-wave2-v1",
            "findingState": "supported",
            "metricsJson": json.dumps(
                {"included_count": 8, "median_difference_bpm": 11},
                separators=(",", ":"),
            ),
            "promotionGatesJson": '{"minimum_observations":true}',
            "exclusionsJson": '["recent_workout"]',
            "counterevidenceJson": '["meeting_04"]',
            "unresolvedInfluencesJson": '["caffeine_missing_two_days"]',
            "approvedNextObservations": [
                "Log caffeine before the next similar meeting."
            ],
            "askIntent": "why_promoted",
        },
    }


class RecordingBackend:
    instances: list["RecordingBackend"] = []
    failure: BackendFailure | None = None

    def __init__(self, **kwargs) -> None:
        self.configuration = kwargs
        self.started = False
        self.calls = 0
        self.closed = False
        self.__class__.instances.append(self)

    @property
    def ready(self) -> bool:
        return self.started and not self.closed

    def start(self) -> None:
        self.started = True

    def infer(self, request) -> BackendInferenceResult:
        self.calls += 1
        if self.failure is not None:
            raise self.failure
        raw = json.dumps(
            {
                "summary": "The pattern appeared in the meetings checked.",
                "citedParagraphsJson": json.dumps(
                    [
                        {
                            "text": "Vueniverse used the meetings with reliable data.",
                            "citations": ["included_count", "median_difference_bpm"],
                        }
                    ],
                    separators=(",", ":"),
                ),
                "uncertainty": "Missing context could change this result.",
                "citedUnresolvedInfluences": ["caffeine_missing_two_days"],
                "approvedNextObservation": (
                    "Log caffeine before the next similar meeting."
                ),
            },
            separators=(",", ":"),
        )
        return BackendInferenceResult(
            raw_output=raw,
            model_name=self.configuration["model_name"],
            prompt_version=self.configuration["prompt_version"],
            load_millis=12,
            time_to_first_token_millis=20,
            latency_millis=40,
            schema_valid=True,
            extra_metadata={"decoding": "greedy"},
        )

    def cancel(self) -> bool:
        return False

    def close(self) -> None:
        self.closed = True


@pytest.fixture(autouse=True)
def _fake_backend(monkeypatch):
    RecordingBackend.instances.clear()
    RecordingBackend.failure = None
    monkeypatch.setattr(app_module, "LlamaCppBackend", RecordingBackend)


def _runtime(tmp_path: Path) -> DemoRuntime:
    return DemoRuntime(
        DemoRuntimeConfig(
            server_binary=tmp_path / "llama-server",
            model_path=tmp_path / "medgemma-q4.gguf",
            port=0,
        )
    )


def _post(url: str, payload: dict) -> tuple[int, dict]:
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=2) as response:
            return response.status, json.load(response)
    except urllib.error.HTTPError as error:
        return error.code, json.load(error)


def test_runtime_wires_verified_prompt_and_pinned_model(tmp_path: Path) -> None:
    runtime = _runtime(tmp_path)
    backend = RecordingBackend.instances[-1]

    assert backend.configuration["prompt_version"] == 3
    assert len(backend.configuration["prompt_sha256"]) == 64
    assert backend.configuration["quantization"] == "Q4_K_M"
    assert backend.configuration["model_revision"] == (
        "91850547d9f0b2fdd21aa7c5f4f3d1a8a52c243b"
    )
    runtime.close()


def test_cli_fixture_is_demo_only_and_fictional() -> None:
    payload = fictional_demo_payload()

    assert payload["store"] == "demo"
    assert payload["request"]["evidenceVersion"] == "fictional-wave2-v1"


def test_fictional_demo_request_crosses_real_http_boundary(tmp_path: Path) -> None:
    runtime = _runtime(tmp_path)
    try:
        runtime.start()
    except PermissionError:
        pytest.skip("test sandbox does not allow loopback sockets")
    assert runtime.server is not None
    thread = threading.Thread(target=runtime.server.serve_forever, daemon=True)
    thread.start()
    base = f"http://127.0.0.1:{runtime.address[1]}"
    try:
        status, response = _post(f"{base}/v1/explain", _fixture_payload())
        assert status == 200
        assert response["schemaVersion"] == "vueniverse-model-service-result-v1"
        assert response["evidenceVersion"] == "fictional-wave2-v1"
        assert json.loads(response["rawOutput"])["summary"].startswith("The fictional")
        assert response["metadata"]["runtime"] == "developmentMachine"
        assert response["metadata"]["decoding"] == "greedy"

        status, response = _post(f"{base}/v1/explain", _fixture_payload("live"))
        assert status == 403
        assert response["error"]["code"] == "live_store_forbidden"
        assert RecordingBackend.instances[-1].calls == 1
    finally:
        assert runtime.server is not None
        runtime.server.shutdown()
        thread.join(timeout=2)
        runtime.close()


@pytest.mark.parametrize(
    ("code", "expected_status"),
    [("backend_disconnect", 502), ("timeout", 504), ("backend_unavailable", 503)],
)
def test_backend_failures_are_bounded(tmp_path: Path, code: str, expected_status: int) -> None:
    runtime = _runtime(tmp_path)
    backend = RecordingBackend.instances[-1]
    backend.started = True
    backend.failure = BackendFailure(code, "bounded failure", retryable=True)

    status, response = runtime.service.explain(_fixture_payload())

    assert status == expected_status
    assert response == {
        "schemaVersion": "vueniverse-model-service-error-v1",
        "error": {"code": code, "message": "bounded failure", "retryable": True},
    }
    runtime.close()
