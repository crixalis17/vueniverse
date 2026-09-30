"""Small, checkpointed QLoRA smoke run for the messages-only cloud projection."""

from __future__ import annotations

import hashlib
import json
import os
import random
import time
from pathlib import Path
from typing import Any

from vueniverse_medgemma.cloud_evaluation import (
    _assistant_json_prefill,
    _decode_assistant_response,
    _generate_native_completion,
    _normalize_terminal_fence,
    _processor_messages,
    _request_from_messages,
    _resolve_max_new_tokens,
)
from vueniverse_medgemma.evaluation import evaluate_explainer_output, sanitize_fictional_output
from vueniverse_medgemma.settings import Settings

QLORA_SMOKE_SCHEMA = "vueniverse-qlora-smoke-v1"
_TARGET_MODULES = ("q_proj", "k_proj", "v_proj", "o_proj")


def _sha256_path(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _read_projection(path: Path, *, limit: int) -> list[list[dict[str, Any]]]:
    if limit < 1:
        raise ValueError("limit must be positive")
    messages_by_case: list[list[dict[str, Any]]] = []
    for line in path.read_text(encoding="utf-8").splitlines()[:limit]:
        record = json.loads(line)
        if set(record) != {"messages"} or not isinstance(record["messages"], list):
            raise ValueError("QLoRA smoke requires a messages-only projection")
        messages = record["messages"]
        if [message.get("role") for message in messages] != ["system", "user", "assistant"]:
            raise ValueError("QLoRA smoke requires system/user/assistant chat records")
        messages_by_case.append(messages)
    return messages_by_case


def _stratified_training_order(
    messages_by_case: list[list[dict[str, Any]]], *, seed: int
) -> list[list[dict[str, Any]]]:
    """Shuffle deterministically into state/intent-complete accumulation blocks."""

    strata: dict[tuple[str, str], list[list[dict[str, Any]]]] = {}
    for messages in messages_by_case:
        request = _request_from_messages(messages)
        strata.setdefault((request.finding_state, request.ask_intent), []).append(messages)
    rng = random.Random(seed)
    for rows in strata.values():
        rng.shuffle(rows)
    ordered: list[list[dict[str, Any]]] = []
    last_state: str | None = None
    while any(strata.values()):
        keys_by_state: dict[str, list[tuple[str, str]]] = {}
        for key, rows in strata.items():
            if rows:
                keys_by_state.setdefault(key[0], []).append(key)
        states = list(keys_by_state)
        rng.shuffle(states)
        if len(states) > 1 and states[0] == last_state:
            states = states[1:] + states[:1]
        for keys in keys_by_state.values():
            rng.shuffle(keys)
        while any(keys_by_state.values()):
            for state in states:
                keys = keys_by_state[state]
                if not keys:
                    continue
                key = keys.pop()
                ordered.append(strata[key].pop())
                last_state = state
    return ordered


def _training_order_audit(
    messages_by_case: list[list[dict[str, Any]]], *, accumulation_steps: int
) -> dict[str, Any]:
    """Describe the exact shuffled order without retaining model-facing payloads."""

    keys: list[str] = []
    cells: list[str] = []
    cell_counts: dict[str, int] = {}
    longest_state_run = 0
    current_state: str | None = None
    current_run = 0
    for messages in messages_by_case:
        request = _request_from_messages(messages)
        reference = (
            request.context_reference.context_reference_id
            if request.context_reference is not None
            else "no_context_reference"
        )
        key = f"{reference}|{request.finding_state}|{request.ask_intent}"
        keys.append(key)
        cell = f"{request.finding_state}|{request.ask_intent}"
        cells.append(cell)
        cell_counts[cell] = cell_counts.get(cell, 0) + 1
        if request.finding_state == current_state:
            current_run += 1
        else:
            current_state = request.finding_state
            current_run = 1
        longest_state_run = max(longest_state_run, current_run)
    window_cell_counts = [
        len(set(cells[offset : offset + accumulation_steps]))
        for offset in range(0, len(cells), accumulation_steps)
    ]
    return {
        "training_order_sha256": hashlib.sha256("\n".join(keys).encode()).hexdigest(),
        "state_intent_counts": dict(sorted(cell_counts.items())),
        "max_contiguous_same_state_run": longest_state_run,
        "accumulation_window_unique_cell_counts": window_cell_counts,
        "all_accumulation_windows_have_unique_cells": all(
            count == accumulation_steps for count in window_cell_counts
        ),
    }


def _completion_example(processor: Any, messages: list[dict[str, Any]]) -> dict[str, Any]:
    """Tokenize a chat record while masking its system and user prompt tokens."""

    prompt_inputs = processor.apply_chat_template(
        _processor_messages(messages),
        add_generation_prompt=True,
        tokenize=True,
        return_dict=True,
        return_tensors="pt",
    )
    full_messages = _processor_messages(messages[:2]) + _processor_messages(messages[2:])
    full_inputs = processor.apply_chat_template(
        full_messages,
        add_generation_prompt=False,
        tokenize=True,
        return_dict=True,
        return_tensors="pt",
    )
    input_ids = full_inputs["input_ids"][0].clone()
    attention_mask = full_inputs["attention_mask"][0].clone()
    prompt_length = int(prompt_inputs["input_ids"].shape[-1])
    if prompt_length >= input_ids.shape[-1]:
        raise ValueError("assistant completion was not tokenized after the prompt")
    labels = input_ids.clone()
    labels[:prompt_length] = -100
    return {
        "input_ids": input_ids,
        "attention_mask": attention_mask,
        "labels": labels,
    }


def _batch(example: dict[str, Any], device: str) -> dict[str, Any]:
    return {name: value.unsqueeze(0).to(device) for name, value in example.items()}


def _parameter_counts(model: Any) -> dict[str, int]:
    total = sum(parameter.numel() for parameter in model.parameters())
    trainable = sum(
        parameter.numel() for parameter in model.parameters() if parameter.requires_grad
    )
    return {"total": total, "frozen": total - trainable, "trainable": trainable}


def _append_durable_metric(path: Path, payload: dict[str, Any]) -> None:
    """Append one flushed metric so an interrupted run retains completed steps."""

    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(payload, sort_keys=True) + "\n")
        handle.flush()
        os.fsync(handle.fileno())
    os.chmod(path, 0o600)


def _load_adapter_model(
    settings: Settings, *, adapter_rank: int, base_precision: str
) -> tuple[Any, Any, Any]:
    import torch
    from peft import LoraConfig, TaskType, get_peft_model, prepare_model_for_kbit_training
    from transformers import AutoModelForImageTextToText, AutoProcessor, BitsAndBytesConfig

    if base_precision not in {"nf4", "bf16"}:
        raise ValueError("base_precision must be 'nf4' or 'bf16'")
    quantization = None
    if base_precision == "nf4":
        quantization = BitsAndBytesConfig(
            load_in_4bit=True,
            bnb_4bit_quant_type="nf4",
            bnb_4bit_use_double_quant=True,
            bnb_4bit_compute_dtype=torch.bfloat16,
        )
    processor = AutoProcessor.from_pretrained(
        settings.hf_dir,
        local_files_only=True,
        # Keep training and evaluation tokenization stable across Transformers upgrades.
        use_fast=False,
    )
    load_options: dict[str, Any] = {
        "local_files_only": True,
        "device_map": "auto",
    }
    if quantization is not None:
        load_options["quantization_config"] = quantization
    else:
        load_options["torch_dtype"] = torch.bfloat16
    base_model = AutoModelForImageTextToText.from_pretrained(
        settings.hf_dir, **load_options
    )
    module_names = {name.rsplit(".", 1)[-1] for name, _ in base_model.named_modules()}
    missing = set(_TARGET_MODULES) - module_names
    if missing:
        raise ValueError(f"MedGemma is missing expected LoRA target modules: {sorted(missing)}")
    base_model.config.use_cache = False
    if base_precision == "nf4":
        prepared = prepare_model_for_kbit_training(base_model)
    else:
        # BF16 LoRA keeps the base frozen but retains activation gradients through it.
        base_model.enable_input_require_grads()
        base_model.gradient_checkpointing_enable(
            gradient_checkpointing_kwargs={"use_reentrant": False}
        )
        prepared = base_model
    lora = LoraConfig(
        r=adapter_rank,
        lora_alpha=adapter_rank * 2,
        lora_dropout=0.05,
        bias="none",
        target_modules=list(_TARGET_MODULES),
        task_type=TaskType.CAUSAL_LM,
    )
    return get_peft_model(prepared, lora), processor, quantization


def run_qlora_smoke(
    settings: Settings,
    *,
    train_dataset: Path,
    validation_dataset: Path,
    output_dir: Path,
    max_steps: int = 3,
    train_limit: int = 4,
    validation_limit: int = 1,
    adapter_rank: int = 8,
    checkpoint_every: int = 100,
    learning_rate: float = 2e-4,
    gradient_accumulation_steps: int = 1,
    seed: int = 20260912,
    base_precision: str = "nf4",
) -> dict[str, Any]:
    """Train a LoRA adapter over an NF4 or BF16 base, then reload and infer."""

    import torch
    from bitsandbytes.optim import PagedAdamW8bit
    from peft import PeftModel, prepare_model_for_kbit_training
    from transformers import AutoModelForImageTextToText

    training_method = "QLoRA" if base_precision == "nf4" else "LoRA"
    if not torch.cuda.is_available():
        raise RuntimeError(f"{training_method} training requires a CUDA GPU")
    if not settings.hf_dir.is_dir():
        raise FileNotFoundError(f"Checkpoint not downloaded: {settings.hf_dir}")
    if max_steps < 1:
        raise ValueError("max_steps must be positive")
    if checkpoint_every < 1:
        raise ValueError("checkpoint_every must be positive")
    if gradient_accumulation_steps < 1:
        raise ValueError("gradient_accumulation_steps must be positive")
    if max_steps % gradient_accumulation_steps:
        raise ValueError("max_steps must be divisible by gradient_accumulation_steps")
    torch.manual_seed(seed)
    train_messages = _stratified_training_order(
        _read_projection(train_dataset, limit=train_limit), seed=seed
    )
    training_order_audit = _training_order_audit(
        train_messages, accumulation_steps=gradient_accumulation_steps
    )
    validation_messages = _read_projection(validation_dataset, limit=validation_limit)
    output_dir.mkdir(parents=True, exist_ok=True)
    os.chmod(output_dir, 0o700)
    adapter_dir = output_dir / "adapter"
    if adapter_dir.exists():
        raise FileExistsError(
            f"{training_method} output directory already contains an adapter or checkpoint"
        )

    torch.cuda.reset_peak_memory_stats()
    metrics_path = output_dir / "training-metrics.jsonl"
    _append_durable_metric(
        metrics_path,
        {
            "event": "training_started",
            "training_method": training_method,
            "base_precision": base_precision,
            "max_steps": max_steps,
            "adapter_rank": adapter_rank,
            "adapter_alpha": adapter_rank * 2,
            "learning_rate": learning_rate,
            "seed": seed,
            "gradient_accumulation_steps": gradient_accumulation_steps,
            "planned_optimizer_steps": max_steps // gradient_accumulation_steps,
            **training_order_audit,
        },
    )
    load_started = time.perf_counter()
    model, processor, quantization = _load_adapter_model(
        settings, adapter_rank=adapter_rank, base_precision=base_precision
    )
    load_seconds = time.perf_counter() - load_started
    parameter_counts = _parameter_counts(model)
    train_examples = [_completion_example(processor, messages) for messages in train_messages]
    validation_examples = [
        _completion_example(processor, messages) for messages in validation_messages
    ]
    optimizer = PagedAdamW8bit(
        (parameter for parameter in model.parameters() if parameter.requires_grad),
        lr=learning_rate,
    )
    losses: list[float] = []
    checkpoint_paths: list[str] = []
    model.train()
    optimizer.zero_grad(set_to_none=True)
    optimizer_step = 0
    for step in range(1, max_steps + 1):
        outputs = model(**_batch(train_examples[(step - 1) % len(train_examples)], "cuda"))
        loss = outputs.loss
        if loss is None or not torch.isfinite(loss):
            raise RuntimeError(f"non-finite QLoRA loss at step {step}")
        (loss / gradient_accumulation_steps).backward()
        optimizer_updated = step % gradient_accumulation_steps == 0
        if optimizer_updated:
            optimizer.step()
            optimizer.zero_grad(set_to_none=True)
            optimizer_step += 1
        losses.append(round(float(loss.detach().cpu()), 6))
        _append_durable_metric(
            metrics_path,
            {
                "event": "training_step",
                "microstep": step,
                "optimizer_step": optimizer_step,
                "optimizer_updated": optimizer_updated,
                "loss": losses[-1],
            },
        )
        should_checkpoint = optimizer_updated and (
            optimizer_step == 1 or optimizer_step % checkpoint_every == 0 or step == max_steps
        )
        if should_checkpoint:
            checkpoint_dir = output_dir / f"checkpoint-optimizer-step-{optimizer_step}"
            checkpoint_dir.mkdir(parents=True, exist_ok=False)
            model.save_pretrained(checkpoint_dir, safe_serialization=True)
            processor.save_pretrained(checkpoint_dir)
            torch.save(
                {
                    "microstep": step,
                    "optimizer_step": optimizer_step,
                    "optimizer": optimizer.state_dict(),
                    "seed": seed,
                },
                checkpoint_dir / "optimizer.pt",
            )
            checkpoint_paths.append(str(checkpoint_dir))

    model.eval()
    validation_losses: list[float] = []
    validation_loss_by_state_intent: dict[str, float] = {}
    with torch.inference_mode():
        for messages, example in zip(validation_messages, validation_examples, strict=True):
            loss = model(**_batch(example, "cuda")).loss
            if loss is None or not torch.isfinite(loss):
                raise RuntimeError("finite validation loss was not returned")
            value = float(loss.detach().cpu())
            validation_losses.append(value)
            request = _request_from_messages(messages)
            validation_loss_by_state_intent[
                f"{request.finding_state}|{request.ask_intent}"
            ] = round(value, 6)
    validation_loss = sum(validation_losses) / len(validation_losses)
    _append_durable_metric(
        metrics_path,
        {
            "event": "validation_loss",
            "validation_examples": len(validation_examples),
            "loss": round(validation_loss, 6),
            "loss_by_state_intent": validation_loss_by_state_intent,
        },
    )
    model.save_pretrained(adapter_dir, safe_serialization=True)
    processor.save_pretrained(adapter_dir)

    inference_messages = validation_messages[0]
    request = _request_from_messages(inference_messages)
    assistant_prefill = _assistant_json_prefill(request)
    del model
    del optimizer
    torch.cuda.empty_cache()
    reload_options: dict[str, Any] = {
        "local_files_only": True,
        "device_map": "auto",
    }
    if quantization is not None:
        reload_options["quantization_config"] = quantization
    else:
        reload_options["torch_dtype"] = torch.bfloat16
    base_for_reload = AutoModelForImageTextToText.from_pretrained(
        settings.hf_dir, **reload_options
    )
    if quantization is not None:
        base_for_reload = prepare_model_for_kbit_training(
            base_for_reload,
            use_gradient_checkpointing=False,
        )
    reloaded = PeftModel.from_pretrained(base_for_reload, adapter_dir)
    reloaded.eval()
    inputs = processor.apply_chat_template(
        _processor_messages(inference_messages, assistant_prefill=assistant_prefill),
        add_generation_prompt=False,
        continue_final_message=True,
        tokenize=True,
        return_dict=True,
        return_tensors="pt",
    ).to("cuda")
    input_length = inputs["input_ids"].shape[-1]
    resolved_max_new_tokens, generation_limit_mode, _ = _resolve_max_new_tokens(
        reloaded,
        input_length=input_length,
        requested_max_new_tokens=None,
    )
    with torch.inference_mode():
        generated, completion_stop_reason = _generate_native_completion(
            reloaded,
            inputs=inputs,
            max_new_tokens=resolved_max_new_tokens,
        )
    completion, response_parse_mode = _decode_assistant_response(
        processor, generated[0][input_length:]
    )
    raw_output, normalization_mode = _normalize_terminal_fence(f"{assistant_prefill}{completion}")
    reload_evaluation = evaluate_explainer_output(raw_output, request)

    result = {
        "schema_version": QLORA_SMOKE_SCHEMA,
        "model_id": settings.model_id,
        "model_revision": settings.model_revision,
        "train_dataset_sha256": _sha256_path(train_dataset),
        "validation_dataset_sha256": _sha256_path(validation_dataset),
        "configuration": {
            "training_method": training_method,
            "base_quantization": "4-bit NF4" if base_precision == "nf4" else "none",
            "double_quantization": base_precision == "nf4",
            "compute_dtype": "bfloat16",
            "adapter_rank": adapter_rank,
            "adapter_alpha": adapter_rank * 2,
            "adapter_dropout": 0.05,
            "target_modules": list(_TARGET_MODULES),
            "learning_rate": learning_rate,
            "seed": seed,
            "max_steps": max_steps,
            "train_limit": train_limit,
            "validation_limit": validation_limit,
            "checkpoint_every": checkpoint_every,
            "gradient_accumulation_steps": gradient_accumulation_steps,
            "optimizer_steps": optimizer_step,
        },
        "parameter_counts": parameter_counts,
        "load_seconds": round(load_seconds, 3),
        "training_losses": losses,
        "validation_loss": round(validation_loss, 6),
        "validation_loss_by_state_intent": validation_loss_by_state_intent,
        "checkpoint_paths": checkpoint_paths,
        "training_metrics_path": str(metrics_path),
        "adapter_path": str(adapter_dir),
        "reload_inference": {
            "response_parse_mode": f"assistant_prefill+{response_parse_mode}",
            "response_normalization_mode": normalization_mode,
            "generation_limit_mode": generation_limit_mode,
            "resolved_max_new_tokens": resolved_max_new_tokens,
            "completion_stop_reason": completion_stop_reason,
            "application_prefilled_fields": [
                "schema_version",
                "context_reference_id",
                "summary_opening_quote",
            ],
            "raw_output": sanitize_fictional_output(raw_output),
            "evaluation": reload_evaluation.as_dict(),
        },
        "cuda_peak_memory_allocated_bytes": torch.cuda.max_memory_allocated(),
    }
    result_path = output_dir / f"{training_method.lower()}-training.json"
    result_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    os.chmod(result_path, 0o600)
    return result
