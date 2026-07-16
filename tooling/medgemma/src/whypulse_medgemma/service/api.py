"""Localhost-only HTTP boundary that rejects Live data before inference."""

from __future__ import annotations

import json
from dataclasses import dataclass
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from socketserver import TCPServer
from typing import Any

from pydantic import ValidationError

from whypulse_medgemma.service.models import (
    BackendFailure,
    DemoExplainEnvelope,
    InferenceBackend,
)

MAX_REQUEST_BYTES = 256 * 1024


class LocalThreadingHTTPServer(ThreadingHTTPServer):
    """HTTP server that avoids blocking reverse-DNS lookup during bind."""

    def server_bind(self) -> None:
        TCPServer.server_bind(self)
        host, port = self.server_address[:2]
        self.server_name = "localhost" if host in {"127.0.0.1", "::1"} else str(host)
        self.server_port = int(port)


@dataclass(frozen=True)
class ServiceConfig:
    host: str = "127.0.0.1"
    port: int = 8765

    def __post_init__(self) -> None:
        if self.host not in {"127.0.0.1", "localhost", "::1"}:
            raise ValueError("development service must bind to localhost")
        if not 0 <= self.port <= 65_535:
            raise ValueError("port must be between 0 and 65535")


def _error(code: str, message: str, *, retryable: bool = False) -> dict[str, Any]:
    return {
        "schemaVersion": "whypulse-model-service-error-v1",
        "error": {"code": code, "message": message, "retryable": retryable},
    }


class DemoOnlyService:
    def __init__(self, backend: InferenceBackend) -> None:
        self._backend = backend

    @property
    def ready(self) -> bool:
        return self._backend.ready

    def explain(self, raw_payload: object) -> tuple[HTTPStatus, dict[str, Any]]:
        try:
            envelope = DemoExplainEnvelope.model_validate(raw_payload)
        except ValidationError as error:
            return HTTPStatus.BAD_REQUEST, _error(
                "invalid_request",
                f"request failed schema validation ({error.error_count()} errors)",
            )

        if envelope.store != "demo":
            return HTTPStatus.FORBIDDEN, _error(
                "live_store_forbidden",
                "development-machine MedGemma accepts Demo requests only",
            )

        if not self._backend.ready:
            return HTTPStatus.SERVICE_UNAVAILABLE, _error(
                "backend_unavailable",
                "MedGemma backend is not ready",
                retryable=True,
            )

        try:
            result = self._backend.infer(envelope)
        except BackendFailure as error:
            status = {
                "cancelled": HTTPStatus.CONFLICT,
                "timeout": HTTPStatus.GATEWAY_TIMEOUT,
                "backend_unavailable": HTTPStatus.SERVICE_UNAVAILABLE,
            }.get(error.code, HTTPStatus.BAD_GATEWAY)
            return status, _error(error.code, error.message, retryable=error.retryable)
        except Exception:
            return HTTPStatus.INTERNAL_SERVER_ERROR, _error(
                "internal_error",
                "MedGemma inference failed",
                retryable=False,
            )

        return HTTPStatus.OK, {
            "schemaVersion": "whypulse-model-service-result-v1",
            "evidenceVersion": envelope.request.evidenceVersion,
            "rawOutput": result.raw_output,
            "metadata": {
                "runtime": "developmentMachine",
                "modelName": result.model_name,
                "promptVersion": result.prompt_version,
                "loadMillis": result.load_millis,
                "timeToFirstTokenMillis": result.time_to_first_token_millis,
                "latencyMillis": result.latency_millis,
                "schemaValid": result.schema_valid,
                **result.extra_metadata,
            },
        }

    def cancel(self) -> tuple[HTTPStatus, dict[str, Any]]:
        cancelled = self._backend.cancel()
        return HTTPStatus.OK, {
            "schemaVersion": "whypulse-model-service-cancel-v1",
            "cancelled": cancelled,
        }

    def close(self) -> None:
        self._backend.close()


def _handler_for(service: DemoOnlyService) -> type[BaseHTTPRequestHandler]:
    class Handler(BaseHTTPRequestHandler):
        server_version = "WhyPulseMedGemma/1"

        def _write(self, status: HTTPStatus, payload: dict[str, Any]) -> None:
            body = json.dumps(payload, separators=(",", ":")).encode("utf-8")
            self.send_response(status.value)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self) -> None:  # noqa: N802
            if self.path == "/health":
                self._write(HTTPStatus.OK, {"status": "ok"})
            elif self.path == "/ready":
                status = HTTPStatus.OK if service.ready else HTTPStatus.SERVICE_UNAVAILABLE
                self._write(status, {"status": "ready" if service.ready else "not_ready"})
            else:
                self._write(HTTPStatus.NOT_FOUND, _error("not_found", "endpoint not found"))

        def do_POST(self) -> None:  # noqa: N802
            if self.path == "/v1/cancel":
                status, payload = service.cancel()
                self._write(status, payload)
                return
            if self.path != "/v1/explain":
                self._write(HTTPStatus.NOT_FOUND, _error("not_found", "endpoint not found"))
                return
            content_type = self.headers.get_content_type()
            if content_type != "application/json":
                self._write(
                    HTTPStatus.UNSUPPORTED_MEDIA_TYPE,
                    _error("unsupported_media_type", "Content-Type must be application/json"),
                )
                return
            try:
                length = int(self.headers.get("Content-Length", "0"))
            except ValueError:
                length = -1
            if length < 1 or length > MAX_REQUEST_BYTES:
                self._write(
                    HTTPStatus.REQUEST_ENTITY_TOO_LARGE,
                    _error("invalid_content_length", "request body size is invalid"),
                )
                return
            try:
                payload = json.loads(self.rfile.read(length))
            except (UnicodeDecodeError, json.JSONDecodeError):
                self._write(HTTPStatus.BAD_REQUEST, _error("invalid_json", "body must be JSON"))
                return
            status, response = service.explain(payload)
            self._write(status, response)

        def log_message(self, format: str, *args: object) -> None:
            return

    return Handler


def create_server(
    service: DemoOnlyService,
    config: ServiceConfig | None = None,
) -> ThreadingHTTPServer:
    config = config or ServiceConfig()
    return LocalThreadingHTTPServer((config.host, config.port), _handler_for(service))
