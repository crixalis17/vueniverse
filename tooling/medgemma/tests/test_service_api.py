import json
import threading
import urllib.error
import urllib.request

import pytest

from vueniverse_medgemma.service.api import DemoOnlyService, ServiceConfig, create_server
from vueniverse_medgemma.service.models import BackendFailure, BackendInferenceResult


class FakeBackend:
    def __init__(self, *, ready: bool = True, failure: BackendFailure | None = None) -> None:
        self._ready = ready
        self.failure = failure
        self.calls = 0
        self.cancelled = False
        self.closed = False

    @property
    def ready(self) -> bool:
        return self._ready

    def infer(self, request):
        self.calls += 1
        if self.failure:
            raise self.failure
        return BackendInferenceResult(
            raw_output='{"summary":"bounded"}',
            model_name="fake-medgemma",
            prompt_version=1,
            load_millis=5,
            time_to_first_token_millis=10,
            latency_millis=20,
            schema_valid=True,
        )

    def cancel(self) -> bool:
        self.cancelled = True
        return True

    def close(self) -> None:
        self.closed = True


def _request_payload(store: str = "demo") -> dict:
    return {
        "schemaVersion": "vueniverse-model-service-v1",
        "store": store,
        "request": {
            "schemaVersion": "explainer-v1",
            "evidenceVersion": "evidence-v1",
            "findingState": "supported",
            "metricsJson": '{"included_count":8}',
            "promotionGatesJson": "{}",
            "exclusionsJson": "[]",
            "counterevidenceJson": "[]",
            "unresolvedInfluencesJson": "[]",
            "approvedNextObservations": [],
            "askIntent": "why_shown",
        },
    }


def test_live_is_rejected_before_backend() -> None:
    backend = FakeBackend()
    status, payload = DemoOnlyService(backend).explain(_request_payload("live"))

    assert status == 403
    assert payload["error"]["code"] == "live_store_forbidden"
    assert backend.calls == 0


def test_invalid_schema_and_embedded_json_never_reach_backend() -> None:
    backend = FakeBackend()
    payload = _request_payload()
    payload["request"]["metricsJson"] = "not-json"

    status, response = DemoOnlyService(backend).explain(payload)

    assert status == 400
    assert response["error"]["code"] == "invalid_request"
    assert backend.calls == 0


def test_demo_request_returns_versioned_raw_result() -> None:
    backend = FakeBackend()
    status, payload = DemoOnlyService(backend).explain(_request_payload())

    assert status == 200
    assert payload["schemaVersion"] == "vueniverse-model-service-result-v1"
    assert payload["evidenceVersion"] == "evidence-v1"
    assert payload["metadata"]["runtime"] == "developmentMachine"
    assert backend.calls == 1


def test_backend_failure_is_bounded() -> None:
    backend = FakeBackend(failure=BackendFailure("timeout", "inference timed out", retryable=True))

    status, payload = DemoOnlyService(backend).explain(_request_payload())

    assert status == 504
    assert payload["error"] == {
        "code": "timeout",
        "message": "inference timed out",
        "retryable": True,
    }


def test_service_config_rejects_non_loopback_bind() -> None:
    try:
        ServiceConfig(host="0.0.0.0")
    except ValueError as error:
        assert "localhost" in str(error)
    else:
        raise AssertionError("non-loopback host should be rejected")


def test_http_health_ready_and_demo_request() -> None:
    backend = FakeBackend()
    service = DemoOnlyService(backend)
    try:
        server = create_server(service, ServiceConfig(port=0))
    except PermissionError:
        pytest.skip("test sandbox does not allow loopback sockets")
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    base = f"http://127.0.0.1:{server.server_port}"
    try:
        with urllib.request.urlopen(f"{base}/health", timeout=2) as response:
            assert json.load(response) == {"status": "ok"}

        request = urllib.request.Request(
            f"{base}/v1/explain",
            data=json.dumps(_request_payload()).encode(),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(request, timeout=2) as response:
            body = json.load(response)
            assert response.status == 200
            assert body["rawOutput"] == '{"summary":"bounded"}'

        backend._ready = False
        try:
            urllib.request.urlopen(f"{base}/ready", timeout=2)
        except urllib.error.HTTPError as error:
            assert error.code == 503
            assert json.load(error) == {"status": "not_ready"}
        else:
            raise AssertionError("not-ready backend should produce HTTP 503")
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=2)
