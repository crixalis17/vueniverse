"""Command-line entry point for the model artifact pipeline."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

from vueniverse_medgemma.artifacts import write_manifest
from vueniverse_medgemma.benchmark import benchmark_gguf_variants
from vueniverse_medgemma.cloud_evaluation import (
    run_lora_adapter_evaluation,
    run_qlora_adapter_evaluation,
    run_vanilla_cloud_evaluation,
)
from vueniverse_medgemma.cloud_preflight import write_cloud_upload_preflight
from vueniverse_medgemma.cloud_projection import write_cloud_training_projection
from vueniverse_medgemma.cloud_training import run_qlora_smoke
from vueniverse_medgemma.finetuning import write_calibration_profile, write_synthetic_cases
from vueniverse_medgemma.pipeline import (
    convert_to_f16,
    download_checkpoint,
    quantize,
    run_bf16_smoke,
    write_json,
)
from vueniverse_medgemma.runtime_metrics import RuntimeBenchmark, summarize_runtime
from vueniverse_medgemma.settings import Settings
from vueniverse_medgemma.training_dataset import (
    build_conditioned_training_revision,
    build_rebalanced_training_revision,
    write_state_intent_sentinel,
    write_supervised_dataset,
)


def _llama_cpp_dir(value: str | None) -> Path:
    configured = value or os.environ.get("LLAMA_CPP_DIR")
    if not configured:
        raise SystemExit("Set --llama-cpp-dir or LLAMA_CPP_DIR")
    return Path(configured).expanduser().resolve()


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Vueniverse MedGemma 1.5 tooling")
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

    calibrate = commands.add_parser("finetune-calibrate")
    calibrate.add_argument("--ultrahuman-dir", type=Path, required=True)
    calibrate.add_argument("--output", type=Path, required=True)

    synthetic = commands.add_parser("finetune-generate-cases")
    synthetic.add_argument("--profile", type=Path, required=True)
    synthetic.add_argument("--output", type=Path, required=True)
    synthetic.add_argument("--count", type=int, default=60)
    synthetic.add_argument("--seed", type=int, default=20260912)

    dataset = commands.add_parser("finetune-build-dataset")
    dataset.add_argument("--profile", type=Path, required=True)
    dataset.add_argument("--output-dir", type=Path, required=True)
    dataset.add_argument("--seed", type=int, default=20260912)

    rebalance = commands.add_parser("finetune-rebalance-dataset")
    rebalance.add_argument("--base-dataset-dir", type=Path, required=True)
    rebalance.add_argument("--output-dir", type=Path, required=True)
    rebalance.add_argument("--non-supported-multiplier", type=int, default=2)

    conditioned = commands.add_parser("finetune-build-v7-dataset")
    conditioned.add_argument("--base-dataset-dir", type=Path, required=True)
    conditioned.add_argument("--output-dir", type=Path, required=True)
    conditioned.add_argument("--seed", type=int, default=20260912)

    sentinel = commands.add_parser("finetune-build-sentinel")
    sentinel.add_argument("--dataset-dir", type=Path, required=True)
    sentinel.add_argument("--output-dir", type=Path, required=True)

    upload_preflight = commands.add_parser("finetune-cloud-preflight")
    upload_preflight.add_argument("--dataset-dir", type=Path, required=True)
    upload_preflight.add_argument("--output", type=Path, required=True)

    projection = commands.add_parser("finetune-cloud-project")
    projection.add_argument("--dataset-dir", type=Path, required=True)
    projection.add_argument("--output-dir", type=Path, required=True)

    cloud_eval = commands.add_parser("finetune-cloud-vanilla-eval")
    cloud_eval.add_argument("--dataset", type=Path, required=True)
    cloud_eval.add_argument("--output", type=Path, required=True)
    cloud_eval.add_argument(
        "--max-new-tokens",
        type=int,
        help=(
            "Optional explicit output cap. Omit to generate until MedGemma emits EOS "
            "or fills its remaining context window."
        ),
    )

    qlora_eval = commands.add_parser("finetune-cloud-qlora-eval")
    qlora_eval.add_argument("--dataset", type=Path, required=True)
    qlora_eval.add_argument("--adapter", type=Path, required=True)
    qlora_eval.add_argument("--output", type=Path, required=True)
    qlora_eval.add_argument("--max-new-tokens", type=int)
    qlora_eval.add_argument("--limit", type=int)
    qlora_eval.add_argument(
        "--generation-timeout-seconds",
        type=float,
        default=45,
        help="Per-case wall-clock guard; pass 0 only for an explicitly unbounded diagnostic.",
    )
    lora_eval = commands.add_parser("finetune-cloud-lora-eval")
    lora_eval.add_argument("--dataset", type=Path, required=True)
    lora_eval.add_argument("--adapter", type=Path, required=True)
    lora_eval.add_argument("--output", type=Path, required=True)
    lora_eval.add_argument("--max-new-tokens", type=int)
    lora_eval.add_argument("--limit", type=int)
    lora_eval.add_argument(
        "--generation-timeout-seconds",
        type=float,
        default=45,
    )
    lora_eval.add_argument("--checkpoint-every", type=int, default=10)
    qlora_eval.add_argument(
        "--checkpoint-every",
        type=int,
        default=10,
        help="Atomically save a partial report after this many completed cases.",
    )
    cloud_eval.add_argument("--limit", type=int)
    cloud_eval.add_argument(
        "--checkpoint-every",
        type=int,
        default=10,
        help="Atomically save a partial report after this many completed cases.",
    )

    qlora_smoke = commands.add_parser("finetune-cloud-qlora-smoke")
    qlora_smoke.add_argument("--train-dataset", type=Path, required=True)
    qlora_smoke.add_argument("--validation-dataset", type=Path, required=True)
    qlora_smoke.add_argument("--output-dir", type=Path, required=True)
    qlora_smoke.add_argument("--max-steps", type=int, default=3)
    qlora_smoke.add_argument("--train-limit", type=int, default=4)
    qlora_smoke.add_argument("--validation-limit", type=int, default=1)
    qlora_smoke.add_argument("--adapter-rank", type=int, default=8)
    qlora_smoke.add_argument("--checkpoint-every", type=int, default=100)
    qlora_smoke.add_argument("--learning-rate", type=float, default=2e-4)
    qlora_smoke.add_argument("--gradient-accumulation-steps", type=int, default=1)
    lora_smoke = commands.add_parser("finetune-cloud-lora-smoke")
    lora_smoke.add_argument("--train-dataset", type=Path, required=True)
    lora_smoke.add_argument("--validation-dataset", type=Path, required=True)
    lora_smoke.add_argument("--output-dir", type=Path, required=True)
    lora_smoke.add_argument("--max-steps", type=int, default=3)
    lora_smoke.add_argument("--train-limit", type=int, default=4)
    lora_smoke.add_argument("--validation-limit", type=int, default=1)
    lora_smoke.add_argument("--adapter-rank", type=int, default=8)
    lora_smoke.add_argument("--checkpoint-every", type=int, default=100)
    lora_smoke.add_argument("--learning-rate", type=float, default=2e-4)
    lora_smoke.add_argument("--gradient-accumulation-steps", type=int, default=1)
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
    elif args.command == "finetune-calibrate":
        print(write_calibration_profile(args.ultrahuman_dir, args.output))
    elif args.command == "finetune-generate-cases":
        print(
            write_synthetic_cases(
                args.profile,
                args.output,
                count=args.count,
                seed=args.seed,
            )
        )
    elif args.command == "finetune-build-dataset":
        result = write_supervised_dataset(
            args.profile,
            output_dir=args.output_dir,
            seed=args.seed,
        )
    elif args.command == "finetune-rebalance-dataset":
        result = build_rebalanced_training_revision(
            args.base_dataset_dir,
            output_dir=args.output_dir,
            non_supported_multiplier=args.non_supported_multiplier,
        )
        print(
            json.dumps(
                {
                    "output_dir": str(result.output_dir),
                    "split_counts": result.split_counts,
                    "sha256": result.hashes,
                },
                indent=2,
            )
        )
    elif args.command == "finetune-build-v7-dataset":
        result = build_conditioned_training_revision(
            args.base_dataset_dir,
            output_dir=args.output_dir,
            seed=args.seed,
        )
        print(
            json.dumps(
                {
                    "output_dir": str(result.output_dir),
                    "split_counts": result.split_counts,
                    "sha256": result.hashes,
                },
                indent=2,
            )
        )
    elif args.command == "finetune-build-sentinel":
        print(
            json.dumps(
                write_state_intent_sentinel(args.dataset_dir, args.output_dir),
                indent=2,
            )
        )
    elif args.command == "finetune-cloud-preflight":
        result = write_cloud_upload_preflight(args.dataset_dir, args.output)
        print(json.dumps(result.manifest, indent=2))
    elif args.command == "finetune-cloud-project":
        result = write_cloud_training_projection(args.dataset_dir, args.output_dir)
        print(
            json.dumps(
                {
                    "output_dir": str(result.output_dir),
                    "record_counts": result.record_counts,
                    "sha256": result.hashes,
                    "manifest": str(result.manifest_path),
                },
                indent=2,
            )
        )
    elif args.command == "finetune-cloud-vanilla-eval":
        result = run_vanilla_cloud_evaluation(
            settings,
            dataset_path=args.dataset,
            output_path=args.output,
            max_new_tokens=args.max_new_tokens,
            limit=args.limit,
            checkpoint_every=args.checkpoint_every,
        )
        print(
            json.dumps(
                {
                    "output": str(args.output),
                    "case_count": result["case_count"],
                    "evaluation": result["evaluation"],
                },
                indent=2,
            )
        )
    elif args.command == "finetune-cloud-qlora-smoke":
        result = run_qlora_smoke(
            settings,
            train_dataset=args.train_dataset,
            validation_dataset=args.validation_dataset,
            output_dir=args.output_dir,
            max_steps=args.max_steps,
            train_limit=args.train_limit,
            validation_limit=args.validation_limit,
            adapter_rank=args.adapter_rank,
            checkpoint_every=args.checkpoint_every,
            learning_rate=args.learning_rate,
            gradient_accumulation_steps=args.gradient_accumulation_steps,
        )
        print(
            json.dumps(
                {
                    "output_dir": str(args.output_dir),
                    "parameter_counts": result["parameter_counts"],
                    "training_losses": result["training_losses"],
                    "validation_loss": result["validation_loss"],
                    "checkpoint_paths": result["checkpoint_paths"],
                    "adapter_path": result["adapter_path"],
                },
                indent=2,
            )
        )
    elif args.command == "finetune-cloud-lora-smoke":
        result = run_qlora_smoke(
            settings,
            train_dataset=args.train_dataset,
            validation_dataset=args.validation_dataset,
            output_dir=args.output_dir,
            max_steps=args.max_steps,
            train_limit=args.train_limit,
            validation_limit=args.validation_limit,
            adapter_rank=args.adapter_rank,
            checkpoint_every=args.checkpoint_every,
            learning_rate=args.learning_rate,
            gradient_accumulation_steps=args.gradient_accumulation_steps,
            base_precision="bf16",
        )
        print(
            json.dumps(
                {
                    "output_dir": str(args.output_dir),
                    "training_method": result["configuration"]["training_method"],
                    "parameter_counts": result["parameter_counts"],
                    "training_losses": result["training_losses"],
                    "validation_loss": result["validation_loss"],
                    "checkpoint_paths": result["checkpoint_paths"],
                    "adapter_path": result["adapter_path"],
                },
                indent=2,
            )
        )
    elif args.command == "finetune-cloud-lora-eval":
        result = run_lora_adapter_evaluation(
            settings,
            dataset_path=args.dataset,
            adapter_path=args.adapter,
            output_path=args.output,
            max_new_tokens=args.max_new_tokens,
            limit=args.limit,
            checkpoint_every=args.checkpoint_every,
            generation_timeout_seconds=(
                None if args.generation_timeout_seconds == 0 else args.generation_timeout_seconds
            ),
        )
        print(
            json.dumps(
                {
                    "output": str(args.output),
                    "case_count": result["case_count"],
                    "evaluation": result["evaluation"],
                },
                indent=2,
            )
        )
    elif args.command == "finetune-cloud-qlora-eval":
        result = run_qlora_adapter_evaluation(
            settings,
            dataset_path=args.dataset,
            adapter_path=args.adapter,
            output_path=args.output,
            max_new_tokens=args.max_new_tokens,
            limit=args.limit,
            checkpoint_every=args.checkpoint_every,
            generation_timeout_seconds=(
                None if args.generation_timeout_seconds == 0 else args.generation_timeout_seconds
            ),
        )
        print(
            json.dumps(
                {
                    "output": str(args.output),
                    "case_count": result["case_count"],
                    "evaluation": result["evaluation"],
                },
                indent=2,
            )
        )
