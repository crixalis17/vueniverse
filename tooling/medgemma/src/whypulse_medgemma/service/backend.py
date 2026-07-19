"""Reusable lifecycle wrapper around the pinned local llama.cpp server."""

from __future__ import annotations

import json
import socket
import subprocess
import threading
import time
import urllib.error
import urllib.request
from collections.abc import Callable
from pathlib import Path
from typing import Any

from whypulse_medgemma.service.models import (
    BackendFailure,
    BackendInferenceResult,
    DemoExplainEnvelope,
    ServiceExplainerOutput,
)

EXPLAINER_OUTPUT_SCHEMA: dict[str, Any] = {
    "type": "object",
    "additionalProperties": False,
    "required": [
        "summary",
        "citedParagraphsJson",
        "uncertainty",
        "citedUnresolvedInfluences",
        "approvedNextObservation",
    ],
    "properties": {
        # The pinned llama.cpp grammar compiler rejects JSON Schema maxLength.
        # ServiceExplainerOutput enforces string bounds after generation.
        "summary": {"type": "string", "minLength": 1},
        "citedParagraphsJson": {"type": "string", "minLength": 2},
        "uncertainty": {"type": "string", "minLength": 1},
        "citedUnresolvedInfluences": {
            "type": "array",
            "maxItems": 3,
            "items": {"type": "string", "minLength": 1},
        },
        "approvedNextObservation": {
            "anyOf": [
                {"type": "string", "minLength": 1},
                {"type": "null"},
            ]
        },
    },
}


def _available_port() -> int:
    with socket.socket() as server:
        server.bind(("127.0.0.1", 0))
        return int(server.getsockname()[1])


class LlamaCppBackend:
    """Own one local llama-server process and serialize inference through it."""

    def __init__(
        self,
        *,
        server_binary: Path,
        model_path: Path,
        system_prompt: str,
        model_name: str,
        model_revision: str,
        quantization: str = "Q4_K_M",
        prompt_version: int = 1,
        prompt_sha256: str | None = None,
        context_tokens: int = 4_096,
        startup_timeout_seconds: float = 90,
        process_factory: Callable[..., Any] = subprocess.Popen,
        urlopen: Callable[..., Any] = urllib.request.urlopen,
        port_provider: Callable[[], int] = _available_port,
    ) -> None:
        self.server_binary = server_binary
        self.model_path = model_path
        self.system_prompt = system_prompt
        self.model_name = model_name
        self.model_revision = model_revision
        self.quantization = quantization
        self.prompt_version = prompt_version
        self.prompt_sha256 = prompt_sha256
        self.context_tokens = context_tokens
        self.startup_timeout_seconds = startup_timeout_seconds
        self._process_factory = process_factory
        self._urlopen = urlopen
        self._port_provider = port_provider
        self._process: Any | None = None
        self._port: int | None = None
        self._load_millis: int | None = None
        self._inference_lock = threading.Lock()
        self._state_lock = threading.Lock()
        self._cancel_event = threading.Event()
        self._active_response: Any | None = None

    @property
    def ready(self) -> bool:
        return self._process is not None and self._process.poll() is None and self._port is not None

    def _validate_local_artifacts(self) -> None:
        if not self.server_binary.is_file():
            raise BackendFailure(
                "missing_binary",
                f"llama-server is missing: {self.server_binary}",
                retryable=False,
            )
        if not self.server_binary.stat().st_mode & 0o111:
            raise BackendFailure(
                "binary_not_executable",
                f"llama-server is not executable: {self.server_binary}",
                retryable=False,
            )
        if not self.model_path.is_file():
            raise BackendFailure(
                "missing_model",
                f"model is missing: {self.model_path}",
                retryable=False,
            )

    def start(self) -> None:
        with self._state_lock:
            if self.ready:
                return
            self._validate_local_artifacts()
            port = self._port_provider()
            started = time.monotonic()
            try:
                process = self._process_factory(
                    [
                        str(self.server_binary),
                        "--model",
                        str(self.model_path),
                        "--host",
                        "127.0.0.1",
                        "--port",
                        str(port),
                        "--ctx-size",
                        str(self.context_tokens),
                        "--parallel",
                        "1",
                        "--threads",
                        "8",
                        "--n-gpu-layers",
                        "all",
                        "--flash-attn",
                        "on",
                        "--no-webui",
                        "--log-disable",
                    ],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            except OSError as error:
                raise BackendFailure(
                    "startup_failure", "llama-server could not start", retryable=False
                ) from error

            self._process = process
            self._port = port
            try:
                self._wait_until_ready(self.startup_timeout_seconds)
            except BackendFailure:
                self._stop_process(process)
                self._process = None
                self._port = None
                raise
            self._load_millis = round((time.monotonic() - started) * 1_000)

    def _wait_until_ready(self, timeout_seconds: float) -> None:
        deadline = time.monotonic() + timeout_seconds
        assert self._process is not None
        assert self._port is not None
        while time.monotonic() < deadline:
            return_code = self._process.poll()
            if return_code is not None:
                raise BackendFailure(
                    "startup_failure",
                    f"llama-server exited during startup ({return_code})",
                    retryable=False,
                )
            try:
                with self._urlopen(f"http://127.0.0.1:{self._port}/health", timeout=1) as response:
                    if response.status == 200:
                        return
            except (OSError, TimeoutError, urllib.error.URLError):
                time.sleep(0.1)
        raise BackendFailure(
            "startup_timeout",
            "llama-server did not become ready",
            retryable=True,
        )

    def _prompt(self, request: DemoExplainEnvelope) -> str:
        metrics = json.loads(request.request.metricsJson)
        citation_ids = sorted(metrics) if isinstance(metrics, dict) else []
        influences = json.loads(request.request.unresolvedInfluencesJson)
        influence_ids = (
            sorted(influences)
            if isinstance(influences, dict)
            else influences
            if isinstance(influences, list)
            else []
        )
        output_contract = {
            "summary": "one or two short plain-language sentences using exact supplied numbers",
            "citedParagraphsJson": (
                "a JSON-encoded array of one or two {text,citations} objects"
            ),
            "uncertainty": "one uncertainty sentence",
            "citedUnresolvedInfluences": "only IDs supplied in unresolvedInfluencesJson",
            "approvedNextObservation": (
                "one exact supplied approvedNextObservations value, or null"
            ),
        }
        return (
            "ExplainerRequest:\n"
            + request.request.model_dump_json(indent=2)
            + "\nRuntime ExplainerOutput fields:\n"
            + json.dumps(output_contract, indent=2)
            + "\nAllowed citation IDs: "
            + json.dumps(citation_ids)
            + "\nAllowed unresolved influence IDs: "
            + json.dumps(influence_ids)
            + "\nAllowed approved next observations: "
            + json.dumps(request.request.approvedNextObservations)
            + "\nThe runtime field names and supplied JSON schema are authoritative. "
            + "Return only that constrained JSON object."
        )

    def infer(self, request: DemoExplainEnvelope) -> BackendInferenceResult:
        if not self.ready:
            raise BackendFailure("backend_unavailable", "llama-server is not ready", retryable=True)
        if not self._inference_lock.acquire(blocking=False):
            raise BackendFailure("backend_busy", "another inference is active", retryable=True)

        self._cancel_event.clear()
        started = time.monotonic()
        first_token_at: float | None = None
        pieces: list[str] = []
        try:
            assert self._port is not None
            payload = {
                "messages": [
                    {"role": "system", "content": self.system_prompt},
                    {"role": "user", "content": self._prompt(request)},
                ],
                "temperature": 0,
                "seed": 0,
                "max_tokens": request.maxOutputTokens,
                "stream": True,
                "response_format": {
                    "type": "json_schema",
                    "json_schema": {
                        "name": "whypulse_explainer_output",
                        "strict": True,
                        "schema": EXPLAINER_OUTPUT_SCHEMA,
                    },
                },
            }
            http_request = urllib.request.Request(
                f"http://127.0.0.1:{self._port}/v1/chat/completions",
                data=json.dumps(payload).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            timeout_seconds = request.timeoutMillis / 1_000
            try:
                response = self._urlopen(http_request, timeout=timeout_seconds)
                with self._state_lock:
                    self._active_response = response
                with response:
                    for raw_line in response:
                        if self._cancel_event.is_set():
                            raise BackendFailure(
                                "cancelled", "inference was cancelled", retryable=True
                            )
                        if time.monotonic() - started > timeout_seconds:
                            raise BackendFailure("timeout", "inference timed out", retryable=True)
                        line = raw_line.decode("utf-8").strip()
                        if not line.startswith("data: "):
                            continue
                        data = line.removeprefix("data: ")
                        if data == "[DONE]":
                            break
                        event = json.loads(data)
                        choices = event.get("choices") or []
                        if not choices:
                            continue
                        content = choices[0].get("delta", {}).get("content")
                        if content:
                            first_token_at = first_token_at or time.monotonic()
                            pieces.append(content)
            except BackendFailure:
                raise
            except TimeoutError as error:
                raise BackendFailure("timeout", "inference timed out", retryable=True) from error
            except urllib.error.HTTPError as error:
                raise BackendFailure(
                    "backend_http_error",
                    f"llama-server returned HTTP {error.code}",
                    retryable=error.code >= 500,
                ) from error
            except (OSError, urllib.error.URLError) as error:
                if self._cancel_event.is_set():
                    raise BackendFailure(
                        "cancelled", "inference was cancelled", retryable=True
                    ) from error
                raise BackendFailure(
                    "backend_disconnect",
                    "llama-server disconnected during inference",
                    retryable=True,
                ) from error
            except (UnicodeDecodeError, json.JSONDecodeError, KeyError, TypeError) as error:
                raise BackendFailure(
                    "malformed_backend_response",
                    "llama-server returned malformed streaming data",
                    retryable=False,
                ) from error

            raw_output = "".join(pieces)
            schema_valid = self._output_is_valid(raw_output, request)
            finished = time.monotonic()
            return BackendInferenceResult(
                raw_output=raw_output,
                model_name=self.model_name,
                prompt_version=self.prompt_version,
                load_millis=self._load_millis,
                time_to_first_token_millis=(
                    round((first_token_at - started) * 1_000) if first_token_at else None
                ),
                latency_millis=round((finished - started) * 1_000),
                schema_valid=schema_valid,
                extra_metadata={
                    "modelRevision": self.model_revision,
                    "quantization": self.quantization,
                    "contextTokens": self.context_tokens,
                    "maxOutputTokens": request.maxOutputTokens,
                    "decoding": "greedy",
                    **(
                        {"promptSha256": self.prompt_sha256}
                        if self.prompt_sha256 is not None
                        else {}
                    ),
                },
            )
        finally:
            with self._state_lock:
                self._active_response = None
            self._inference_lock.release()

    @staticmethod
    def _output_is_valid(raw_output: str, request: DemoExplainEnvelope) -> bool:
        try:
            output = ServiceExplainerOutput.model_validate_json(raw_output)
            paragraphs = json.loads(output.citedParagraphsJson)
            metrics = json.loads(request.request.metricsJson)
            allowed_citations = set(metrics) if isinstance(metrics, dict) else set()
            if any(
                citation not in allowed_citations
                for paragraph in paragraphs
                for citation in paragraph["citations"]
            ):
                return False
            influences = json.loads(request.request.unresolvedInfluencesJson)
            allowed_influences = (
                set(influences)
                if isinstance(influences, (dict, list))
                else set()
            )
            if not set(output.citedUnresolvedInfluences) <= allowed_influences:
                return False
            return (
                output.approvedNextObservation is None
                or output.approvedNextObservation in request.request.approvedNextObservations
            )
        except (KeyError, TypeError, ValueError):
            return False

    def cancel(self) -> bool:
        active = self._inference_lock.locked()
        if not active:
            return False
        self._cancel_event.set()
        with self._state_lock:
            response = self._active_response
        if response is not None:
            response.close()
        return True

    @staticmethod
    def _stop_process(process: Any) -> None:
        if process.poll() is not None:
            return
        process.terminate()
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)

    def close(self) -> None:
        self.cancel()
        with self._state_lock:
            process = self._process
            self._process = None
            self._port = None
            self._active_response = None
        if process is not None:
            self._stop_process(process)

    def __enter__(self) -> LlamaCppBackend:
        self.start()
        return self

    def __exit__(self, *_: object) -> None:
        self.close()
