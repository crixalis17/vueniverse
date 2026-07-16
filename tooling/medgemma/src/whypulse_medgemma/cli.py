"""Command-line entry point for the model artifact pipeline."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

from whypulse_medgemma.artifacts import write_manifest
from whypulse_medgemma.benchmark import benchmark_gguf_variants
from whypulse_medgemma.pipeline import (
    convert_to_f16,
    download_checkpoint,
    quantize,
    run_bf16_smoke,
    write_json,
)
from whypulse_medgemma.runtime_metrics import RuntimeBenchmark, summarize_runtime
from whypulse_medgemma.settings import Settings


def _llama_cpp_dir(value: str | None) -> Path:
    configured = value or os.environ.get("LLAMA_CPP_DIR")
    if not configured:
        raise SystemExit("Set --llama-cpp-dir or LLAMA_CPP_DIR")
    return Path(configured).expanduser().resolve()


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="WhyPulse MedGemma 1.5 tooling")
    commands = parser.add_subparsers(dest="command", required=True)

    commands.add_parser("paths")
    commands.add_parser("download")

    smoke = commands.add_parser("bf16-smoke")
    smoke.add_argument("--max-new-tokens", type=int, default=128)

    convert = commands.add_parser("convert")
    convert.add_argument("--llama-cpp-dir")

    quantize_command = commands.add_parser("quantize")
    quantize_command.add_argument("--llama-cpp-dir")
    quantize_command.add_argument(
        "--variants", nargs="+", choices=["Q4_K_M", "Q5_K_M"], default=["Q4_K_M", "Q5_K_M"]
    )

    manifest = commands.add_parser("manifest")
    manifest.add_argument("--llama-cpp-dir")

    benchmark = commands.add_parser("benchmark")
    benchmark.add_argument("--llama-cpp-dir")
    benchmark.add_argument(
        "--variants", nargs="+", choices=["Q4_K_M", "Q5_K_M"], default=["Q4_K_M", "Q5_K_M"]
    )
    benchmark.add_argument("--max-tokens", type=int, default=384)

    runtime_schema = commands.add_parser("runtime-schema")
    runtime_schema.add_argument("--output", type=Path)

    runtime_score = commands.add_parser("runtime-score")
    runtime_score.add_argument("report", type=Path)
    return parser


def main() -> None:
    args = _parser().parse_args()
    settings = Settings.from_environment()

    if args.command == "paths":
        print(json.dumps({key: str(value) for key, value in vars(settings).items()}, indent=2))
    elif args.command == "download":
        print(download_checkpoint(settings))
    elif args.command == "bf16-smoke":
        result = run_bf16_smoke(settings, max_new_tokens=args.max_new_tokens)
        output = settings.report_dir / "bf16-smoke.json"
        write_json(output, result)
        print(output)
    elif args.command == "convert":
        print(convert_to_f16(settings, llama_cpp_dir=_llama_cpp_dir(args.llama_cpp_dir)))
    elif args.command == "quantize":
        for output in quantize(
            settings,
            llama_cpp_dir=_llama_cpp_dir(args.llama_cpp_dir),
            variants=tuple(args.variants),
        ):
            print(output)
    elif args.command == "manifest":
        output = settings.report_dir / "artifact-manifest.json"
        write_manifest(
            output,
            model_id=settings.model_id,
            model_revision=settings.model_revision,
            llama_cpp_dir=_llama_cpp_dir(args.llama_cpp_dir),
            artifacts=[settings.f16_gguf, settings.q4_gguf, settings.q5_gguf],
        )
        print(output)
    elif args.command == "benchmark":
        output = settings.report_dir / "gguf-benchmark.json"
        result = benchmark_gguf_variants(
            settings,
            llama_cpp_dir=_llama_cpp_dir(args.llama_cpp_dir),
            variants=tuple(args.variants),
            max_tokens=args.max_tokens,
        )
        write_json(output, result)
        print(output)
    elif args.command == "runtime-schema":
        schema = RuntimeBenchmark.model_json_schema()
        if args.output:
            write_json(args.output, schema)
            print(args.output)
        else:
            print(json.dumps(schema, indent=2))
    elif args.command == "runtime-score":
        report = RuntimeBenchmark.model_validate_json(args.report.read_text(encoding="utf-8"))
        print(summarize_runtime(report).model_dump_json(indent=2))
