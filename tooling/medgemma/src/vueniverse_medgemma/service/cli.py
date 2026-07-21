"""CLI for running and probing the Demo-only development runtime."""

from __future__ import annotations

import argparse
import json
import os
import urllib.error
import urllib.request
from pathlib import Path

from vueniverse_medgemma.service.app import DemoRuntime, DemoRuntimeConfig
from vueniverse_medgemma.settings import Settings


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Vueniverse Demo-only MedGemma service")
    commands = parser.add_subparsers(dest="command", required=True)

    serve = commands.add_parser("serve")
    serve.add_argument("--llama-server", type=Path)
    serve.add_argument("--model", type=Path)
    serve.add_argument("--host", default="127.0.0.1")
    serve.add_argument("--port", type=int, default=8765)

    for name in ("health", "ready"):
        probe = commands.add_parser(name)
        probe.add_argument("--port", type=int, default=8765)
    fixture = commands.add_parser("fixture")
    fixture.add_argument("--port", type=int, default=8765)
    return parser


def _resolved_binary(value: Path | None) -> Path:
    if value is not None:
        return value.expanduser().resolve()
    configured = os.environ.get("LLAMA_SERVER_BINARY")
    if configured:
        return Path(configured).expanduser().resolve()
    tool_dir = Settings.from_environment().tool_dir
    return tool_dir / ".cache" / "llama.cpp" / "build" / "bin" / "llama-server"


def _probe(path: str, port: int) -> int:
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/{path}", timeout=3) as response:
            print(json.dumps(json.load(response), separators=(",", ":")))
            return 0 if response.status == 200 else 1
    except urllib.error.HTTPError as error:
        print(error.read().decode("utf-8", errors="replace"))
        return 1
    except (OSError, TimeoutError, urllib.error.URLError) as error:
        print(json.dumps({"status": "unreachable", "reason": type(error).__name__}))
        return 1


def fictional_demo_payload() -> dict[str, object]:
    """Return the stable, invented integration request; never load personal data here."""
    return {
        "schemaVersion": "vueniverse-model-service-v1",
        "store": "demo",
        "timeoutMillis": 30_000,
        "maxOutputTokens": 384,
        "request": {
            "schemaVersion": "explainer-v1",
            "evidenceVersion": "fictional-wave2-v1",
            "findingState": "supported",
            "metricsJson": '{"included_count":8,"median_difference_bpm":11}',
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


def _post_fixture(port: int) -> int:
    request = urllib.request.Request(
        f"http://127.0.0.1:{port}/v1/explain",
        data=json.dumps(fictional_demo_payload()).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=40) as response:
            print(json.dumps(json.load(response), indent=2))
            return 0
    except urllib.error.HTTPError as error:
        print(error.read().decode("utf-8", errors="replace"))
        return 1
    except (OSError, TimeoutError, urllib.error.URLError) as error:
        print(json.dumps({"status": "unreachable", "reason": type(error).__name__}))
        return 1


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    if args.command in {"health", "ready"}:
        return _probe(args.command, args.port)
    if args.command == "fixture":
        return _post_fixture(args.port)

    settings = Settings.from_environment()
    runtime = DemoRuntime(
        DemoRuntimeConfig(
            server_binary=_resolved_binary(args.llama_server),
            model_path=(args.model or settings.q4_gguf).expanduser().resolve(),
            host=args.host,
            port=args.port,
            model_name=settings.model_id,
            model_revision=settings.model_revision,
        )
    )
    runtime.start()
    host, port = runtime.address
    print(f"Vueniverse Demo MedGemma listening on http://{host}:{port}", flush=True)
    try:
        runtime.serve_forever()
    except KeyboardInterrupt:
        runtime.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
