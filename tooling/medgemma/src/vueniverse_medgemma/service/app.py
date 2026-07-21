"""Assembly for the localhost-only Demo development runtime."""

from __future__ import annotations

from dataclasses import dataclass
from http.server import ThreadingHTTPServer
from pathlib import Path

from vueniverse_medgemma import MODEL_ID, MODEL_REVISION
from vueniverse_medgemma.prompt_catalog import PROMPTS, load_prompt
from vueniverse_medgemma.service.api import DemoOnlyService, ServiceConfig, create_server
from vueniverse_medgemma.service.backend import LlamaCppBackend


@dataclass(frozen=True)
class DemoRuntimeConfig:
    server_binary: Path
    model_path: Path
    host: str = "127.0.0.1"
    port: int = 8765
    model_name: str = MODEL_ID
    model_revision: str = MODEL_REVISION
    quantization: str = "Q4_K_M"
    context_tokens: int = 4_096

    def __post_init__(self) -> None:
        ServiceConfig(self.host, self.port)
        if not 512 <= self.context_tokens <= 8_192:
            raise ValueError("context_tokens must be between 512 and 8192")


class DemoRuntime:
    """Own the llama.cpp process, HTTP service, and deterministic teardown."""

    def __init__(self, config: DemoRuntimeConfig) -> None:
        prompt = load_prompt("pigeon_explainer_system")
        prompt_spec = PROMPTS["pigeon_explainer_system"]
        self.backend = LlamaCppBackend(
            server_binary=config.server_binary,
            model_path=config.model_path,
            system_prompt=prompt,
            model_name=config.model_name,
            model_revision=config.model_revision,
            quantization=config.quantization,
            prompt_version=prompt_spec.version,
            prompt_sha256=prompt_spec.sha256,
            context_tokens=config.context_tokens,
        )
        self.service = DemoOnlyService(self.backend)
        self._service_config = ServiceConfig(config.host, config.port)
        self.server: ThreadingHTTPServer | None = None
        self._started = False
        self._serving = False

    @property
    def address(self) -> tuple[str, int]:
        if self.server is None:
            return self._service_config.host, self._service_config.port
        host, port = self.server.server_address[:2]
        return str(host), int(port)

    def start(self) -> None:
        if self._started:
            return
        try:
            self.backend.start()
            self.server = create_server(self.service, self._service_config)
        except Exception:
            if self.server is not None:
                self.server.server_close()
                self.server = None
            self.backend.close()
            raise
        self._started = True

    def serve_forever(self) -> None:
        self.start()
        assert self.server is not None
        self._serving = True
        try:
            self.server.serve_forever()
        finally:
            self._serving = False
            self.server.server_close()
            self.server = None
            self.service.close()
            self._started = False

    def close(self) -> None:
        if self._serving and self.server is not None:
            self.server.shutdown()
        if self.server is not None:
            self.server.server_close()
            self.server = None
        self.service.close()
        self._started = False

    def __enter__(self) -> DemoRuntime:
        self.start()
        return self

    def __exit__(self, *_: object) -> None:
        self.close()
