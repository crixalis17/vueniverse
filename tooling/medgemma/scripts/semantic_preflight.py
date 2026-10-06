#!/usr/bin/env python3
"""Verify frozen LoRA prompts with the exact pinned llama.cpp vocabulary and grammar API.

Host-only, CPU vocabulary load; no tensor load, context creation, inference or downloads.
The output is exclusive and does not alter the frozen input package.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import subprocess
import sys
import tempfile
from datetime import UTC, datetime
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO / "tooling/medgemma/src"))
from vueniverse_medgemma.emulator_semantic_package import verify  # noqa: E402

REVISION = "5839ba352471b2a7b45e7ba401619a6896f10f8b"
MODEL_SHA = "dd9c2a212672a5bb18affbc344a4c0fcf4e9000b3b5155d6fdfe9a8104bad234"
MODEL_BYTES = 2489893568


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def command(args: list[str], **kwargs: object) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, check=True, capture_output=True, text=True, **kwargs)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--model", type=Path, required=True)
    args = parser.parse_args()
    for path in (args.package, args.output, args.model):
        if not path.is_absolute():
            parser.error("all paths must be absolute")
    if args.output.exists() or args.output.is_symlink() or not args.output.parent.is_dir():
        parser.error("output must be new and its parent must already exist")
    verify(args.package)
    if not args.model.is_file() or args.model.is_symlink():
        parser.error("model must be a regular non-symlink file")
    if args.model.stat().st_size != MODEL_BYTES or digest(args.model) != MODEL_SHA:
        parser.error("cached LoRA artifact does not match the exact pinned SHA and size")
    llama = REPO / "tooling/medgemma/.cache/llama.cpp"
    actual_revision = command(["git", "-C", str(llama), "rev-parse", "HEAD"]).stdout.strip()
    dirty = command(["git", "-C", str(llama), "status", "--porcelain"]).stdout
    if actual_revision != REVISION or dirty:
        parser.error("llama.cpp source must be clean at the exact pinned revision")
    build = llama / "build"
    library_dir = build / "bin"
    build_metadata = build / "llama-config.cmake"
    if f"set(LLAMA_BUILD_COMMIT {REVISION[:8]})" not in build_metadata.read_text():
        parser.error("cached build commit metadata does not match source")
    source = REPO / "tooling/medgemma/native-tests/semantic_preflight.cpp"
    rendered = args.package / "rendered"
    rows = [
        json.loads(line)
        for line in (rendered / "rendered-contracts.jsonl").read_text().splitlines()
    ]
    if len(rows) != 15:
        parser.error("expected exactly 15 frozen cases")
    argv_inputs: list[str] = []
    for row in rows:
        contract = row["lora_v7"]
        if contract["max_output_tokens"] != 512:
            parser.error("LoRA output reservation changed")
        argv_inputs.extend(
            [
                row["case_id"],
                str(rendered / contract["prompt_file"]),
                str(rendered / contract["grammar_file"]),
            ]
        )
    with tempfile.TemporaryDirectory(prefix="vueniverse-semantic-preflight-") as temp:
        binary = Path(temp) / "semantic-preflight"
        compile_args = [
            "/usr/bin/c++",
            "-std=c++17",
            "-O2",
            str(source),
            "-I",
            str(llama / "include"),
            "-I",
            str(llama / "ggml/include"),
            "-L",
            str(library_dir),
            f"-Wl,-rpath,{library_dir}",
            "-lllama",
            "-o",
            str(binary),
        ]
        command(compile_args, timeout=60)
        environment = dict(os.environ)
        environment["DYLD_LIBRARY_PATH"] = str(library_dir)
        started = datetime.now(UTC)
        result = command([str(binary), str(args.model), *argv_inputs], env=environment, timeout=60)
        elapsed = (datetime.now(UTC) - started).total_seconds()
        native = json.loads(result.stdout)
        helper_binary_sha = digest(binary)
    if [row["case_id"] for row in native["cases"]] != [row["case_id"] for row in rows]:
        parser.error("native preflight case matrix differs")
    cases = []
    for frozen, actual in zip(rows, native["cases"], strict=True):
        ids = actual["token_ids"]
        if len(ids) != actual["prompt_tokens"] or not all(isinstance(i, int) for i in ids):
            parser.error("token count or token IDs malformed")
        token_json = json.dumps(ids, separators=(",", ":")).encode()
        cases.append(
            {
                **actual,
                "token_ids_sha256": hashlib.sha256(token_json).hexdigest(),
                "token_ids_hash_encoding": "UTF-8 compact JSON integer array, no newline",
                "prompt_sha256": frozen["lora_v7"]["prompt_sha256"],
                "grammar_sha256": frozen["lora_v7"]["grammar_sha256"],
                "add_special": True,
                "parse_special": True,
                "reserved_output_tokens": 512,
                "max_context_tokens": 4096,
                "context_fit": len(ids) + 512 <= 4096,
                "context_headroom_tokens": 4096 - len(ids) - 512,
                "assistant_prefill_in_prompt": frozen["lora_v7"]["assistant_prefill"],
                "grammar_root": "root",
                "grammar_scope": (
                    "Generated continuation only; prompt/prefill not accepted into grammar"
                ),
            }
        )
    report = {
        "schema": "emulator-semantic-native-preflight-v1",
        "created_at_utc": datetime.now(UTC).isoformat(),
        "environment": "macOS arm64 host; not Android/emulator runtime execution",
        "platform": platform.platform(),
        "variant": "lora_v7",
        "package_manifest_sha256": digest(args.package / "manifest.json"),
        "artifact": {"sha256": MODEL_SHA, "size_bytes": MODEL_BYTES, "fresh_hash_verified": True},
        "llama_cpp_revision": actual_revision,
        "llama_cpp_source_clean": True,
        "cached_build_commit_metadata_sha256": digest(build_metadata),
        "cached_build_commit_metadata": REVISION[:8],
        "helper_source_sha256": digest(source),
        "helper_binary_sha256": helper_binary_sha,
        "orchestrator_source_sha256": digest(Path(__file__)),
        "runtime_source_sha256": digest(REPO / "android/app/src/main/cpp/medgemma_jni.cpp"),
        "header_sha256": digest(llama / "include/llama.h"),
        "library_sha256": {
            file.name: digest(file)
            for file in sorted(library_dir.glob("*.dylib"))
            if not file.is_symlink()
        },
        "native_stderr_sha256": hashlib.sha256(result.stderr.encode()).hexdigest(),
        "native_stderr_confirms_vocabulary_only": "vocab only - skipping tensors" in result.stderr,
        "elapsed_seconds_vocabulary_preflight": elapsed,
        "vocab_only": native["vocab_only"],
        "weights_loaded": native["weights_loaded"],
        "context_created": native["context_created"],
        "inference_performed": native["inference_performed"],
        "model_attempts": 0,
        "normal_candidate_activation": False,
        "case_count": len(cases),
        "all_passed": all(case["context_fit"] and case["grammar_initialized"] for case in cases),
        "limitations": [
            "Host vocabulary and grammar initialization, not Android binary or execution proof.",
            "No context created: fit replicates production prompt-plus-output token inequality.",
            "Grammar initialization is not semantic correctness or successful model generation.",
            "No vanilla artifact/tokenizer verified or evaluated in this batch.",
            "Cached dylib fingerprinted; build metadata matches; no clean rebuild performed.",
        ],
        "cases": cases,
    }
    with args.output.open("x") as stream:
        json.dump(report, stream, indent=2)
        stream.write("\n")
    print(
        json.dumps(
            {
                "case_count": len(cases),
                "all_passed": report["all_passed"],
                "model_attempts": 0,
                "min_prompt_tokens": min(case["prompt_tokens"] for case in cases),
                "max_prompt_tokens": max(case["prompt_tokens"] for case in cases),
                "elapsed_seconds": elapsed,
            }
        )
    )
    if not report["all_passed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
