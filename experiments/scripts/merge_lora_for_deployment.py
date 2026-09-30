"""Merge the retained BF16 LoRA adapter into the pinned MedGemma base."""

from __future__ import annotations

import hashlib
import json
import os
import shutil
import sys
from datetime import UTC, datetime
from pathlib import Path

import torch
from peft import PeftModel
from transformers import AutoModelForImageTextToText, AutoProcessor


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main(base_arg: str, adapter_arg: str, output_arg: str) -> None:
    base = Path(base_arg).resolve()
    adapter = Path(adapter_arg).resolve()
    output = Path(output_arg).resolve()
    if output.exists():
        raise FileExistsError(f"refusing to overwrite deployment output: {output}")
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA is required for the controlled merge")
    output.mkdir(parents=True, mode=0o700)
    try:
        model = AutoModelForImageTextToText.from_pretrained(
            base,
            local_files_only=True,
            dtype=torch.bfloat16,
            device_map={"": "cuda:0"},
            low_cpu_mem_usage=True,
        )
        peft_model = PeftModel.from_pretrained(model, adapter, is_trainable=False)
        merged = peft_model.merge_and_unload(safe_merge=True)
        merged.save_pretrained(output, safe_serialization=True, max_shard_size="5GB")
        AutoProcessor.from_pretrained(base, local_files_only=True, use_fast=False).save_pretrained(output)
        config = json.loads((output / "config.json").read_text())
        if config.get("model_type") != "gemma3":
            raise RuntimeError(f"unexpected merged model_type: {config.get('model_type')}")
        weights = sorted(output.glob("*.safetensors"))
        if not weights:
            raise RuntimeError("merged model wrote no safetensors")
        manifest = {
            "schema_version": 1,
            "created_at_utc": datetime.now(UTC).isoformat(),
            "base_path": str(base),
            "adapter_path": str(adapter),
            "dtype": "bfloat16",
            "merge": "peft.merge_and_unload(safe_merge=True)",
            "torch_version": torch.__version__,
            "cuda_device": torch.cuda.get_device_name(0),
            "files": {
                path.name: {"bytes": path.stat().st_size, "sha256": sha256(path)}
                for path in sorted(output.iterdir())
                if path.is_file()
            },
        }
        (output / "deployment-merge-manifest.json").write_text(
            json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        os.chmod(output / "deployment-merge-manifest.json", 0o600)
        print(json.dumps({"output": str(output), "weight_files": len(weights), "weight_bytes": sum(p.stat().st_size for p in weights)}))
    except Exception:
        shutil.rmtree(output, ignore_errors=True)
        raise


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("usage: merge_lora_for_deployment.py BASE ADAPTER OUTPUT")
    main(*sys.argv[1:])
