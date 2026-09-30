#!/usr/bin/env python3
"""Compare first-token logits for the NF4 base and saved QLoRA checkpoints."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Any

import torch
from peft import PeftModel, prepare_model_for_kbit_training
from transformers import AutoModelForImageTextToText, AutoProcessor, BitsAndBytesConfig

from vueniverse_medgemma.cloud_evaluation import (
    _assistant_json_prefill,
    _load_messages,
    _processor_messages,
    _request_from_messages,
)
from vueniverse_medgemma.settings import Settings


def _args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", type=Path, required=True)
    parser.add_argument("--training-run-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def _adapter_paths(run_dir: Path) -> list[tuple[str, Path]]:
    checkpoints = sorted(
        run_dir.glob("checkpoint-step-*"),
        key=lambda path: int(path.name.rsplit("-", 1)[-1]),
    )
    paths = [(path.name.replace("-", "_"), path) for path in checkpoints]
    paths.append(("final_adapter", run_dir / "adapter"))
    for _name, path in paths:
        if not path.is_dir():
            raise FileNotFoundError(path)
    return paths


def _distribution(processor: Any, logits: torch.Tensor) -> dict[str, Any]:
    probabilities = torch.softmax(logits.float(), dim=-1)
    values, indices = torch.topk(probabilities, k=8)
    selected_ids = {
        "pad": processor.tokenizer.pad_token_id,
        "eos": processor.tokenizer.eos_token_id,
        "end_of_turn": processor.tokenizer.convert_tokens_to_ids("<end_of_turn>"),
    }
    return {
        "top_tokens": [
            {
                "token_id": int(token_id),
                "token": processor.tokenizer.convert_ids_to_tokens(int(token_id)),
                "probability": round(float(probability), 8),
            }
            for probability, token_id in zip(values, indices, strict=True)
        ],
        "selected_token_probabilities": {
            name: {
                "token_id": int(token_id),
                "probability": round(float(probabilities[token_id]), 10),
            }
            for name, token_id in selected_ids.items()
        },
    }


def main() -> None:
    args = _args()
    settings = Settings.from_environment()
    messages = _load_messages(args.dataset)[0]
    request = _request_from_messages(messages)
    assistant_prefill = _assistant_json_prefill(request)
    processor = AutoProcessor.from_pretrained(
        settings.hf_dir,
        local_files_only=True,
        use_fast=False,
    )
    inputs = processor.apply_chat_template(
        _processor_messages(messages, assistant_prefill=assistant_prefill),
        add_generation_prompt=False,
        continue_final_message=True,
        tokenize=True,
        return_dict=True,
        return_tensors="pt",
    ).to("cuda")
    quantization = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_use_double_quant=True,
        bnb_4bit_compute_dtype=torch.bfloat16,
    )
    base = AutoModelForImageTextToText.from_pretrained(
        settings.hf_dir,
        local_files_only=True,
        quantization_config=quantization,
        device_map="auto",
    )
    base = prepare_model_for_kbit_training(base, use_gradient_checkpointing=False)
    adapters = _adapter_paths(args.training_run_dir)
    first_name, first_path = adapters[0]
    model = PeftModel.from_pretrained(base, first_path, adapter_name=first_name)
    for name, path in adapters[1:]:
        model.load_adapter(path, adapter_name=name)
    model.eval()

    records: list[dict[str, Any]] = []
    with torch.inference_mode(), model.disable_adapter():
        records.append(
            {
                "model": "nf4_base_adapter_disabled",
                **_distribution(processor, model(**inputs, use_cache=True).logits[0, -1]),
            }
        )
    for name, _path in adapters:
        model.set_adapter(name)
        with torch.inference_mode():
            logits = model(**inputs, use_cache=True).logits[0, -1]
        records.append({"model": name, **_distribution(processor, logits)})

    payload = {
        "dataset": args.dataset.name,
        "case_index": 0,
        "input_tokens": int(inputs["input_ids"].shape[-1]),
        "records": records,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    os.chmod(args.output, 0o600)
    print(args.output)


if __name__ == "__main__":
    main()
