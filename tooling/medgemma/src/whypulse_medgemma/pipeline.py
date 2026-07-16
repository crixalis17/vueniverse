"""Download, smoke-test, convert, and quantize MedGemma 1.5."""

from __future__ import annotations

import json
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

from huggingface_hub import snapshot_download

from whypulse_medgemma.settings import Settings


def download_checkpoint(settings: Settings) -> Path:
    settings.ensure_local_directories()
    snapshot_download(
        repo_id=settings.model_id,
        revision=settings.model_revision,
        local_dir=settings.hf_dir,
        ignore_patterns=["*.h5", "*.msgpack", "*.onnx", "*.tflite"],
    )
    return settings.hf_dir


def run_bf16_smoke(settings: Settings, *, max_new_tokens: int = 128) -> dict[str, Any]:
    import psutil
    import torch
    from transformers import AutoModelForImageTextToText, AutoProcessor

    if not settings.hf_dir.is_dir():
        raise FileNotFoundError(f"Checkpoint not downloaded: {settings.hf_dir}")

    device = "mps" if torch.backends.mps.is_available() else "cpu"
    process = psutil.Process()
    rss_before = process.memory_info().rss
    load_started = time.perf_counter()
    processor = AutoProcessor.from_pretrained(settings.hf_dir, local_files_only=True)
    model = AutoModelForImageTextToText.from_pretrained(
        settings.hf_dir,
        dtype=torch.bfloat16,
        local_files_only=True,
    ).to(device)
    load_seconds = time.perf_counter() - load_started
    rss_after_load = process.memory_info().rss

    messages = [
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": (
                        'Return JSON only: {"status":"ok","scope":"fictional_evidence_only"}.'
                    ),
                }
            ],
        }
    ]
    inputs = processor.apply_chat_template(
        messages,
        add_generation_prompt=True,
        tokenize=True,
        return_dict=True,
        return_tensors="pt",
    ).to(device, dtype=torch.bfloat16)
    input_length = inputs["input_ids"].shape[-1]

    generation_started = time.perf_counter()
    with torch.inference_mode():
        generated = model.generate(
            **inputs,
            max_new_tokens=max_new_tokens,
            do_sample=False,
        )
    generation_seconds = time.perf_counter() - generation_started
    decoded = processor.decode(generated[0][input_length:], skip_special_tokens=True)

    return {
        "schema_version": 1,
        "model_id": settings.model_id,
        "model_revision": settings.model_revision,
        "device": device,
        "dtype": "bfloat16",
        "load_seconds": round(load_seconds, 3),
        "generation_seconds": round(generation_seconds, 3),
        "rss_before_bytes": rss_before,
        "rss_after_load_bytes": rss_after_load,
        "prompt_tokens": input_length,
        "generated_tokens": int(generated.shape[-1] - input_length),
        "response": decoded,
    }


def _run(command: list[str]) -> None:
    subprocess.run(command, check=True)


def convert_to_f16(settings: Settings, *, llama_cpp_dir: Path) -> Path:
    converter = llama_cpp_dir / "convert_hf_to_gguf.py"
    if not converter.is_file():
        raise FileNotFoundError(f"llama.cpp converter not found: {converter}")
    settings.f16_gguf.parent.mkdir(parents=True, exist_ok=True)
    _run(
        [
            sys.executable,
            str(converter),
            str(settings.hf_dir),
            "--outfile",
            str(settings.f16_gguf),
            "--outtype",
            "f16",
        ]
    )
    return settings.f16_gguf


def quantize(
    settings: Settings,
    *,
    llama_cpp_dir: Path,
    variants: tuple[str, ...] = ("Q4_K_M", "Q5_K_M"),
) -> list[Path]:
    quantizer = llama_cpp_dir / "build" / "bin" / "llama-quantize"
    if not quantizer.is_file():
        raise FileNotFoundError(f"llama-quantize not built: {quantizer}")
    outputs = {
        "Q4_K_M": settings.q4_gguf,
        "Q5_K_M": settings.q5_gguf,
    }
    selected: list[Path] = []
    for variant in variants:
        if variant not in outputs:
            raise ValueError(f"Unsupported quantization: {variant}")
        output = outputs[variant]
        _run([str(quantizer), str(settings.f16_gguf), str(output), variant])
        selected.append(output)
    return selected


def write_json(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")
