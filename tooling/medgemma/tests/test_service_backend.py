import json
import stat
from pathlib import Path

import pytest

from vueniverse_medgemma.service.backend import EXPLAINER_OUTPUT_SCHEMA, LlamaCppBackend
from vueniverse_medgemma.service.models import BackendFailure, DemoExplainEnvelope


class FakeProcess:
    def __init__(self, return_code=None) -> None:
        self.return_code = return_code
        self.terminated = False
        self.killed = False

    def poll(self):
        return self.return_code

    def terminate(self) -> None:
        self.terminated = True
        self.return_code = 0

    def kill(self) -> None:
        self.killed = True
        self.return_code = -9

    def wait(self, timeout=None):
        return self.return_code


class FakeResponse:
    status = 200

    def __init__(self, lines=()) -> None:
        self.lines = list(lines)
        self.closed = False

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.close()

    def __iter__(self):
        return iter(self.lines)

    def close(self) -> None:
        self.closed = True


def _request() -> DemoExplainEnvelope:
    return DemoExplainEnvelope.model_validate(
        {
            "schemaVersion": "vueniverse-model-service-v1",
            "store": "demo",
            "timeoutMillis": 1_000,
            "maxOutputTokens": 32,
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
    )


def _artifacts(tmp_path: Path) -> tuple[Path, Path]:
    tmp_path.mkdir(parents=True, exist_ok=True)
    binary = tmp_path / "llama-server"
    binary.write_text("fake")
    binary.chmod(binary.stat().st_mode | stat.S_IXUSR)
    model = tmp_path / "model.gguf"
    model.write_bytes(b"GGUF")
    return binary, model


def _backend(tmp_path: Path, *, urlopen, process=None) -> LlamaCppBackend:
    binary, model = _artifacts(tmp_path)
    fake_process = process or FakeProcess()
    return LlamaCppBackend(
        server_binary=binary,
        model_path=model,
        system_prompt="bounded",
        model_name="medgemma-test",
        model_revision="revision-test",
        process_factory=lambda *args, **kwargs: fake_process,
        urlopen=urlopen,
        port_provider=lambda: 8123,
        startup_timeout_seconds=0.05,
    )


def test_missing_binary_and_model_have_distinct_errors(tmp_path: Path) -> None:
    missing = tmp_path / "missing"
    backend = LlamaCppBackend(
        server_binary=missing,
        model_path=missing,
        system_prompt="bounded",
        model_name="test",
        model_revision="test",
    )
    with pytest.raises(BackendFailure, match="llama-server is missing") as binary_error:
        backend.start()
    assert binary_error.value.code == "missing_binary"

    binary, _ = _artifacts(tmp_path)
    backend = LlamaCppBackend(
        server_binary=binary,
        model_path=missing,
        system_prompt="bounded",
        model_name="test",
        model_revision="test",
    )
    with pytest.raises(BackendFailure, match="model is missing") as model_error:
        backend.start()
    assert model_error.value.code == "missing_model"


def test_startup_exit_is_reported_and_cleaned_up(tmp_path: Path) -> None:
    process = FakeProcess(return_code=17)
    backend = _backend(tmp_path, urlopen=lambda *args, **kwargs: FakeResponse(), process=process)

    with pytest.raises(BackendFailure) as error:
        backend.start()

    assert error.value.code == "startup_failure"
    assert not backend.ready


def test_successful_stream_returns_raw_output_and_metadata(tmp_path: Path) -> None:
    output = {
        "summary": "bounded",
        "citedParagraphsJson": '[{"text":"bounded","citations":["included_count"]}]',
        "uncertainty": "association only",
        "citedUnresolvedInfluences": [],
        "approvedNextObservation": None,
    }
    # Use two valid SSE events so JSON string escaping is exercised.
    raw = json.dumps(output)
    stream = [
        f"data: {json.dumps({'choices': [{'delta': {'content': raw[:25]}}]})}\n".encode(),
        f"data: {json.dumps({'choices': [{'delta': {'content': raw[25:]}}]})}\n".encode(),
        b"data: [DONE]\n",
    ]
    responses = iter([FakeResponse(), FakeResponse(stream)])
    backend = _backend(tmp_path, urlopen=lambda *args, **kwargs: next(responses))
    backend.start()

    result = backend.infer(_request())

    assert result.raw_output == raw
    assert result.schema_valid
    assert result.extra_metadata["quantization"] == "Q4_K_M"
    backend.close()


def test_llama_grammar_schema_uses_post_validation_for_string_bounds() -> None:
    assert "maxLength" not in json.dumps(EXPLAINER_OUTPUT_SCHEMA)


def test_output_validation_rejects_unknown_citations_and_next_observations() -> None:
    request = _request()
    valid = {
        "summary": "bounded",
        "citedParagraphsJson": '[{"text":"bounded","citations":[]}]',
        "uncertainty": "uncertain",
        "citedUnresolvedInfluences": [],
        "approvedNextObservation": None,
    }
    # Paragraph schema rejects an empty citation list before grounding runs.
    assert not LlamaCppBackend._output_is_valid(json.dumps(valid), request)

    valid["citedParagraphsJson"] = '[{"text":"bounded","citations":["unknown"]}]'
    assert not LlamaCppBackend._output_is_valid(json.dumps(valid), request)

    valid["citedParagraphsJson"] = '[{"text":"bounded","citations":["included_count"]}]'
    valid["approvedNextObservation"] = "not approved"
    assert not LlamaCppBackend._output_is_valid(json.dumps(valid), request)

    valid["approvedNextObservation"] = None
    assert LlamaCppBackend._output_is_valid(json.dumps(valid), request)


def test_timeout_and_disconnect_have_distinct_errors(tmp_path: Path) -> None:
    timeout_responses = iter([FakeResponse(), None])

    def timeout_open(*args, **kwargs):
        response = next(timeout_responses)
        if response is None:
            raise TimeoutError
        return response

    backend = _backend(tmp_path / "timeout", urlopen=timeout_open)
    backend.start()
    with pytest.raises(BackendFailure) as timeout_error:
        backend.infer(_request())
    assert timeout_error.value.code == "timeout"
    backend.close()

    disconnect_responses = iter([FakeResponse(), None])

    def disconnect_open(*args, **kwargs):
        response = next(disconnect_responses)
        if response is None:
            raise OSError("disconnected")
        return response

    backend = _backend(tmp_path / "disconnect", urlopen=disconnect_open)
    backend.start()
    with pytest.raises(BackendFailure) as disconnect_error:
        backend.infer(_request())
    assert disconnect_error.value.code == "backend_disconnect"
    backend.close()


def test_cancel_closes_active_response_and_close_stops_process(tmp_path: Path) -> None:
    process = FakeProcess()
    backend = _backend(
        tmp_path,
        urlopen=lambda *args, **kwargs: FakeResponse(),
        process=process,
    )
    backend.start()
    response = FakeResponse()
    backend._inference_lock.acquire()
    backend._active_response = response

    assert backend.cancel()
    assert response.closed
    backend._inference_lock.release()
    backend.close()
    assert process.terminated
