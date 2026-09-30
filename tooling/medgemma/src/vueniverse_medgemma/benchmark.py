"""Benchmark constrained Explainer output through the pinned llama.cpp server."""

from __future__ import annotations

import json
import platform
import socket
import subprocess
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import psutil

from vueniverse_medgemma.evaluation import (
    apply_next_observation_policy,
    deterministic_explainer_fallback,
    evaluate_explainer_output,
    has_only_action_policy_errors,
)
from vueniverse_medgemma.fixtures import evaluation_cases
from vueniverse_medgemma.prompt_catalog import load_prompt, prompt_metadata
from vueniverse_medgemma.schemas import explainer_model_view, explainer_output_schema
from vueniverse_medgemma.settings import Settings


@dataclass(frozen=True)
class StreamResult:
    text: str
    time_to_first_token_seconds: float | None
    total_seconds: float
    usage: dict[str, Any]
    timings: dict[str, Any]


def _available_port() -> int:
    with socket.socket() as server:
        server.bind(("127.0.0.1", 0))
        return int(server.getsockname()[1])


def _health_url(port: int) -> str:
    return f"http://127.0.0.1:{port}/health"


def _wait_until_ready(process: subprocess.Popen[bytes], port: int, timeout: float) -> None:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise RuntimeError(f"llama-server exited with status {process.returncode}")
        try:
            with urllib.request.urlopen(_health_url(port), timeout=1) as response:
                if response.status == 200:
                    return
        except (urllib.error.URLError, TimeoutError):
            pass
        time.sleep(0.2)
    raise TimeoutError("llama-server did not become ready")


def _stream_completion(port: int, payload: dict[str, Any]) -> StreamResult:
    request = urllib.request.Request(
        f"http://127.0.0.1:{port}/v1/chat/completions",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    started = time.perf_counter()
    first_token_at: float | None = None
    pieces: list[str] = []
    usage: dict[str, Any] = {}
    timings: dict[str, Any] = {}
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            for raw_line in response:
                line = raw_line.decode("utf-8").strip()
                if not line.startswith("data: "):
                    continue
                data = line.removeprefix("data: ")
                if data == "[DONE]":
                    break
                event = json.loads(data)
                usage = event.get("usage") or usage
                timings = event.get("timings") or timings
                choices = event.get("choices") or []
                if not choices:
                    continue
                content = choices[0].get("delta", {}).get("content")
                if content:
                    if first_token_at is None:
                        first_token_at = time.perf_counter()
                    pieces.append(content)
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"llama-server request failed ({error.code}): {detail}") from error

    finished = time.perf_counter()
    return StreamResult(
        text="".join(pieces),
        time_to_first_token_seconds=(first_token_at - started if first_token_at else None),
        total_seconds=finished - started,
        usage=usage,
        timings=timings,
    )


def _model_path(settings: Settings, variant: str) -> Path:
    paths = {"Q4_K_M": settings.q4_gguf, "Q5_K_M": settings.q5_gguf}
    return paths[variant]


def _run_variant(
    settings: Settings,
    *,
    server_binary: Path,
    system_prompt: str,
    variant: str,
    max_tokens: int,
) -> dict[str, Any]:
    model_path = _model_path(settings, variant)
    if not model_path.is_file():
        raise FileNotFoundError(f"Missing {variant} artifact: {model_path}")

    port = _available_port()
    process_started = time.perf_counter()
    server = subprocess.Popen(
        [
            str(server_binary),
            "--model",
            str(model_path),
            "--host",
            "127.0.0.1",
            "--port",
            str(port),
            "--ctx-size",
            "4096",
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
    try:
        _wait_until_ready(server, port, 90)
        load_seconds = time.perf_counter() - process_started
        server_process = psutil.Process(server.pid)
        rss_after_load = server_process.memory_info().rss
        records: list[dict[str, Any]] = []
        for case in evaluation_cases():
            allowed_citations = [metric.citation_id for metric in case.request.metrics]
            payload = {
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {
                        "role": "user",
                        "content": (
                            "EvidenceBundle:\n"
                            + json.dumps(explainer_model_view(case.request), indent=2)
                            + "\nAllowed citation IDs: "
                            + json.dumps(allowed_citations)
                            + "\nAllowed unresolved influence IDs: "
                            + json.dumps(case.request.unresolved_influence_ids)
                            + "\nAllowed next observation IDs: "
                            + json.dumps(list(case.request.approved_next_observations))
                        ),
                    },
                ],
                "temperature": 0,
                "seed": 0,
                "max_tokens": max_tokens,
                "stream": True,
                "stream_options": {"include_usage": True},
                "response_format": {
                    "type": "json_schema",
                    "json_schema": {
                        "name": "vueniverse_explainer_output",
                        "strict": True,
                        "schema": explainer_output_schema(case.request),
                    },
                },
            }
            streamed = _stream_completion(port, payload)
            model_evaluation = evaluate_explainer_output(streamed.text, case.request)
            action_only_failure = has_only_action_policy_errors(model_evaluation)
            fallback_used = not model_evaluation.passed and not action_only_failure
            delivery_base = (
                deterministic_explainer_fallback(case.request)
                if fallback_used
                else model_evaluation.parsed
            )
            if delivery_base is None:  # pragma: no cover - failed output uses fallback.
                raise RuntimeError("delivery output could not be constructed")
            delivered = apply_next_observation_policy(delivery_base, case.request)
            delivered_output = delivered.model_dump_json()
            delivery_evaluation = evaluate_explainer_output(delivered_output, case.request)
            records.append(
                {
                    "case_id": case.case_id,
                    "description": case.description,
                    "time_to_first_token_seconds": streamed.time_to_first_token_seconds,
                    "total_seconds": streamed.total_seconds,
                    "usage": streamed.usage,
                    "timings": streamed.timings,
                    "rss_bytes": server_process.memory_info().rss,
                    "fallback_used": fallback_used,
                    "action_only_guard_failure": action_only_failure,
                    "action_policy": {
                        "owner": "application",
                        "model_value": (
                            model_evaluation.parsed.next_observation_id
                            if model_evaluation.parsed
                            else None
                        ),
                        "delivered_value": delivered.next_observation_id,
                        "overridden": (
                            model_evaluation.parsed is not None
                            and model_evaluation.parsed.next_observation_id
                            != delivered.next_observation_id
                        ),
                    },
                    "model_evaluation": model_evaluation.as_dict(),
                    "delivery_evaluation": delivery_evaluation.as_dict(),
                    "raw_output": streamed.text,
                    "delivered_output": delivered_output,
                }
            )

        model_schema_valid = sum(record["model_evaluation"]["schema_valid"] for record in records)
        model_passed = sum(record["model_evaluation"]["passed"] for record in records)
        delivery_passed = sum(record["delivery_evaluation"]["passed"] for record in records)
        total = len(records)
        ttft_values = [
            record["time_to_first_token_seconds"]
            for record in records
            if record["time_to_first_token_seconds"] is not None
        ]
        return {
            "variant": variant,
            "model_path": str(model_path),
            "artifact_bytes": model_path.stat().st_size,
            "server_load_seconds": load_seconds,
            "rss_after_load_bytes": rss_after_load,
            "model_schema_valid_count": model_schema_valid,
            "model_passed_count": model_passed,
            "fallback_count": total - model_passed,
            "delivery_passed_count": delivery_passed,
            "case_count": total,
            "model_schema_valid_rate": model_schema_valid / total,
            "model_passed_rate": model_passed / total,
            "delivery_passed_rate": delivery_passed / total,
            "mean_ttft_seconds": sum(ttft_values) / len(ttft_values) if ttft_values else None,
            "mean_total_seconds": sum(record["total_seconds"] for record in records) / total,
            "cases": records,
        }
    finally:
        server.terminate()
        try:
            server.wait(timeout=10)
        except subprocess.TimeoutExpired:
            server.kill()
            server.wait(timeout=5)


def benchmark_gguf_variants(
    settings: Settings,
    *,
    llama_cpp_dir: Path,
    variants: tuple[str, ...],
    max_tokens: int = 384,
) -> dict[str, Any]:
    if max_tokens < 1:
        raise ValueError("max_tokens must be positive")
    server_binary = llama_cpp_dir / "build" / "bin" / "llama-server"
    if not server_binary.is_file():
        raise FileNotFoundError(f"llama-server not built: {server_binary}")
    system_prompt = load_prompt("explainer_system")
    return {
        "schema_version": 1,
        "created_at_utc": datetime.now(UTC).isoformat(),
        "model_id": settings.model_id,
        "model_revision": settings.model_revision,
        "runtime": "llama.cpp server (local benchmark only)",
        "llama_cpp_revision": subprocess.check_output(
            ["git", "-C", str(llama_cpp_dir), "rev-parse", "HEAD"], text=True
        ).strip(),
        "host": platform.platform(),
        "context_tokens": 4096,
        "max_output_tokens": max_tokens,
        "decoding": "greedy with JSON-schema grammar",
        **prompt_metadata("explainer_system"),
        "variants": [
            _run_variant(
                settings,
                server_binary=server_binary,
                system_prompt=system_prompt,
                variant=variant,
                max_tokens=max_tokens,
            )
            for variant in variants
        ],
    }
