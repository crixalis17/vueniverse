"""GPU baseline evaluation for the model-only supervised holdout projection."""

from __future__ import annotations

import hashlib
import json
import os
import time
from collections import Counter
from pathlib import Path
from typing import Any

from pydantic import ValidationError

from vueniverse_medgemma.evaluation import (
    apply_next_observation_policy,
    deterministic_explainer_fallback,
    evaluate_explainer_output,
    has_only_action_policy_errors,
    sanitize_fictional_output,
    score_evaluation_records,
)
from vueniverse_medgemma.schemas import (
    ContextReference,
    EvidenceMetric,
    ExplainerOutput,
    ExplainerRequest,
)
from vueniverse_medgemma.settings import Settings


_MAX_GENERATION_SECONDS = 45


def _sha256_path(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _request_from_messages(messages: list[dict[str, Any]]) -> ExplainerRequest:
    """Rebuild the validator request from the model-facing EvidenceBundle only."""

    if [message.get("role") for message in messages[:2]] != ["system", "user"]:
        raise ValueError("expected system and user messages")
    user_content = messages[1].get("content")
    if not isinstance(user_content, str) or not user_content.startswith("EvidenceBundle:\n"):
        raise ValueError("user message does not start with an EvidenceBundle")
    decoder = json.JSONDecoder()
    evidence, _ = decoder.raw_decode(user_content.removeprefix("EvidenceBundle:\n"))
    if not isinstance(evidence, dict):
        raise ValueError("EvidenceBundle is not an object")
    context = evidence.get("context_reference")
    return ExplainerRequest(
        evidence_version="v5_messages_projection",
        finding_state=evidence["finding_state"],
        metrics=[EvidenceMetric.model_validate(metric) for metric in evidence["metrics"]],
        context_reference=ContextReference.model_validate(context) if context is not None else None,
        exclusion_ids=evidence["exclusion_ids"],
        counterevidence_ids=(
            ["counterevidence_available"] if evidence["counterevidence_available"] else []
        ),
        unresolved_influence_ids=evidence["unresolved_influence_ids"],
        approved_next_observations=evidence["approved_next_observations"],
        ask_intent=evidence["ask_intent"],
        user_question=evidence["user_question"],
    )


def _load_messages(path: Path) -> list[list[dict[str, Any]]]:
    records: list[list[dict[str, Any]]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        record = json.loads(line)
        if set(record) != {"messages"} or not isinstance(record["messages"], list):
            raise ValueError("cloud evaluation requires the messages-only projection")
        messages = record["messages"]
        if "synthetic" in json.dumps(messages, sort_keys=True).lower():
            raise ValueError("model-facing provenance marker found in cloud projection")
        records.append(messages)
    return records


def _processor_messages(
    messages: list[dict[str, Any]], *, assistant_prefill: str | None = None
) -> list[dict[str, Any]]:
    """Adapt string-content records to MedGemma's typed chat format."""

    formatted: list[dict[str, Any]] = []
    for message in messages[:2]:
        role = message.get("role")
        content = message.get("content")
        if not isinstance(role, str) or not isinstance(content, str):
            raise ValueError("cloud evaluation requires string-content chat messages")
        formatted.append({"role": role, "content": [{"type": "text", "text": content}]})
    if assistant_prefill is not None:
        formatted.append(
            {
                "role": "assistant",
                "content": [{"type": "text", "text": assistant_prefill}],
            }
        )
    return formatted


def _model_context_window(model: Any) -> int:
    """Return the model's advertised text context window without guessing a small cap."""

    config = getattr(model, "config", None)
    candidates = (getattr(config, "text_config", None), config)
    for candidate in candidates:
        value = getattr(candidate, "max_position_embeddings", None)
        if isinstance(value, int) and not isinstance(value, bool) and value > 0:
            return value
    raise RuntimeError(
        "could not determine the model context window; pass --max-new-tokens explicitly"
    )


def _resolve_max_new_tokens(
    model: Any,
    *,
    input_length: int,
    requested_max_new_tokens: int | None,
) -> tuple[int, str, int]:
    """Use an explicit override or all context still available to the model."""

    context_window = _model_context_window(model)
    if requested_max_new_tokens is not None:
        if requested_max_new_tokens < 1:
            raise ValueError("max_new_tokens must be positive when provided")
        return requested_max_new_tokens, "explicit_override", context_window
    remaining = context_window - input_length
    if remaining < 1:
        raise RuntimeError(
            f"input length {input_length} leaves no generation room in context window "
            f"{context_window}"
        )
    return remaining, "model_context_remaining", context_window


def _decode_assistant_response(processor: Any, completion_token_ids: Any) -> tuple[str, str]:
    """Prefer a processor-parsed final answer over any model thinking channel."""

    full_completion = processor.decode(completion_token_ids, skip_special_tokens=False)
    parse_response = getattr(processor, "parse_response", None)
    if callable(parse_response):
        parsed = parse_response(full_completion)
        if isinstance(parsed, dict) and isinstance(parsed.get("content"), str):
            return parsed["content"], "processor_parsed_final_answer"
    visible_token_ids = completion_token_ids
    terminal_tokens_removed: list[str] = []
    while len(visible_token_ids):
        token = processor.tokenizer.convert_ids_to_tokens(int(visible_token_ids[-1]))
        if token not in {"<end_of_turn>", "<eos>"}:
            break
        terminal_tokens_removed.append(token)
        visible_token_ids = visible_token_ids[:-1]
    mode = "decoded_completion"
    if terminal_tokens_removed:
        mode += "+removed_terminal_control_token"
    return processor.decode(visible_token_ids, skip_special_tokens=True), mode


def _completion_token_summary(processor: Any, completion_token_ids: Any) -> dict[str, Any]:
    """Record bounded token diagnostics without persisting private reasoning text."""

    token_ids = [int(token_id) for token_id in completion_token_ids.detach().cpu().tolist()]
    special_ids = set(processor.tokenizer.all_special_ids)
    counts = Counter(token_ids)
    return {
        "token_count": len(token_ids),
        "special_token_count": sum(token_id in special_ids for token_id in token_ids),
        "unique_token_count": len(counts),
        "most_common": [
            {
                "token_id": token_id,
                "token": processor.tokenizer.convert_ids_to_tokens(token_id),
                "count": count,
                "is_special": token_id in special_ids,
            }
            for token_id, count in counts.most_common(8)
        ],
        "last_token_ids": token_ids[-8:],
        "last_tokens": processor.tokenizer.convert_ids_to_tokens(token_ids[-8:]),
    }


def _assistant_json_prefill(request: ExplainerRequest) -> str:
    """Prefill structural fields the application already knows authoritatively."""

    fields = '{"schema_version":2'
    if request.context_reference is not None:
        fields += ",\"context_reference_id\":" + json.dumps(
            request.context_reference.context_reference_id
        )
    return fields + ',"summary":"'


def _normalize_terminal_fence(raw_output: str) -> tuple[str, str]:
    """Remove only a lone trailing Markdown fence after one complete JSON object."""

    stripped = raw_output.strip()
    try:
        payload, end = json.JSONDecoder().raw_decode(stripped)
    except json.JSONDecodeError:
        return raw_output, "not_json"
    if not isinstance(payload, dict):
        return raw_output, "not_json_object"
    trailing = stripped[end:].strip()
    if not trailing:
        return stripped, "exact_json"
    if trailing == "```":
        return stripped[:end], "removed_terminal_fence"
    return raw_output, "unexpected_trailing_text"


def _is_complete_json_object(raw_output: str) -> bool:
    """Return true only for one complete JSON object with no trailing content."""

    try:
        payload, end = json.JSONDecoder().raw_decode(raw_output.strip())
    except json.JSONDecodeError:
        return False
    return isinstance(payload, dict) and not raw_output.strip()[end:].strip()


def _is_complete_schema_valid_json(raw_output: str) -> bool:
    """Return true only for one complete response matching the output contract.

    Grounding, safety, and usefulness remain evaluation concerns after generation.
    """

    if not _is_complete_json_object(raw_output):
        return False
    try:
        ExplainerOutput.model_validate(json.loads(raw_output))
    except ValidationError:
        return False
    return True


def _generate_native_completion(
    model: Any,
    *,
    inputs: Any,
    max_new_tokens: int,
    generation_timeout_seconds: float | None = _MAX_GENERATION_SECONDS,
) -> tuple[Any, str]:
    """Use Transformers' native generation loop and decode only after it returns."""

    generation_options: dict[str, Any] = {
        "max_new_tokens": max_new_tokens,
        "do_sample": False,
        "use_cache": True,
    }
    if generation_timeout_seconds is not None:
        generation_options["max_time"] = generation_timeout_seconds

    started_at = time.perf_counter()
    generated = model.generate(**inputs, **generation_options)
    elapsed = time.perf_counter() - started_at

    eos_token_id = getattr(model.generation_config, "eos_token_id", None)
    eos_token_ids = (
        set(eos_token_id)
        if isinstance(eos_token_id, (list, tuple, set))
        else {eos_token_id}
    )
    ended_with_eos = int(generated[0, -1]) in eos_token_ids
    if ended_with_eos:
        return generated, "eos"
    if generation_timeout_seconds is not None and elapsed >= generation_timeout_seconds:
        return generated, "per_case_timeout"
    return generated, "context_boundary"


def _write_private_json(path: Path, payload: dict[str, Any]) -> None:
    """Atomically replace a private report without leaving a partial JSON file."""

    path.parent.mkdir(parents=True, exist_ok=True)
    os.chmod(path.parent, 0o700)
    temporary_path = path.with_suffix(path.suffix + ".partial")
    temporary_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    os.chmod(temporary_path, 0o600)
    temporary_path.replace(path)
    os.chmod(path, 0o600)


def _run_cloud_evaluation(
    settings: Settings,
    *,
    dataset_path: Path,
    output_path: Path,
    adapter_path: Path | None,
    max_new_tokens: int | None = None,
    limit: int | None = None,
    checkpoint_every: int = 10,
    generation_timeout_seconds: float | None = _MAX_GENERATION_SECONDS,
    adapter_base_precision: str = "nf4",
) -> dict[str, Any]:
    """Evaluate vanilla MedGemma or a saved LoRA-family adapter on one split."""

    import torch
    from transformers import AutoModelForImageTextToText, AutoProcessor, BitsAndBytesConfig

    if not torch.cuda.is_available():
        raise RuntimeError("cloud baseline evaluation requires a CUDA GPU")
    if not settings.hf_dir.is_dir():
        raise FileNotFoundError(f"Checkpoint not downloaded: {settings.hf_dir}")
    messages_by_case = _load_messages(dataset_path)
    if limit is not None:
        if limit < 1:
            raise ValueError("limit must be positive when provided")
        messages_by_case = messages_by_case[:limit]
    if checkpoint_every < 1:
        raise ValueError("checkpoint_every must be positive")
    if generation_timeout_seconds is not None and generation_timeout_seconds <= 0:
        raise ValueError("generation_timeout_seconds must be positive or None")

    device = "cuda"
    torch.cuda.reset_peak_memory_stats()
    load_started = time.perf_counter()
    processor = AutoProcessor.from_pretrained(
        settings.hf_dir,
        local_files_only=True,
        # Preserve the processor implementation used for every prior experiment.
        use_fast=False,
    )
    if adapter_path is None:
        model = AutoModelForImageTextToText.from_pretrained(
            settings.hf_dir,
            dtype=torch.bfloat16,
            local_files_only=True,
        ).to(device)
        model_variant = "vanilla_bf16"
        dtype = "bfloat16"
        adapter_metadata: dict[str, Any] | None = None
    else:
        if adapter_base_precision not in {"nf4", "bf16"}:
            raise ValueError("adapter_base_precision must be 'nf4' or 'bf16'")
        if not adapter_path.is_dir():
            raise FileNotFoundError(f"adapter not found: {adapter_path}")
        from peft import PeftModel, prepare_model_for_kbit_training

        load_options: dict[str, Any] = {
            "local_files_only": True,
            "device_map": "auto",
        }
        if adapter_base_precision == "nf4":
            quantization = BitsAndBytesConfig(
                load_in_4bit=True,
                bnb_4bit_quant_type="nf4",
                bnb_4bit_use_double_quant=True,
                bnb_4bit_compute_dtype=torch.bfloat16,
            )
            load_options["quantization_config"] = quantization
        else:
            load_options["torch_dtype"] = torch.bfloat16
        base_model = AutoModelForImageTextToText.from_pretrained(
            settings.hf_dir, **load_options
        )
        if adapter_base_precision == "nf4":
            # Match the numerically stable k-bit preparation used during QLoRA.
            base_model = prepare_model_for_kbit_training(
                base_model,
                use_gradient_checkpointing=False,
            )
        model = PeftModel.from_pretrained(base_model, adapter_path)
        if adapter_base_precision == "nf4":
            model_variant = "qlora_adapter_nf4"
            dtype = "4-bit NF4 base + bfloat16 adapter compute"
        else:
            model_variant = "lora_adapter_bf16"
            dtype = "bfloat16 base + bfloat16 adapter compute"
        config_path = adapter_path / "adapter_config.json"
        adapter_metadata = json.loads(config_path.read_text(encoding="utf-8"))
    model.eval()
    load_seconds = time.perf_counter() - load_started
    context_window = _model_context_window(model)

    records: list[dict[str, Any]] = []
    generation_limit_mode: str | None = None

    def checkpoint_payload(status: str, *, failure: str | None = None) -> dict[str, Any]:
        result: dict[str, Any] = {
            "schema_version": 1,
            "run_type": "cloud_holdout_evaluation",
            "run_status": status,
            "model_id": settings.model_id,
            "model_revision": settings.model_revision,
            "model_variant": model_variant,
            "adapter": adapter_metadata,
            "dataset_path": dataset_path.name,
            "dataset_sha256": _sha256_path(dataset_path),
            "case_count": len(messages_by_case),
            "completed_case_count": len(records),
            "checkpoint_every": checkpoint_every,
            "requested_max_new_tokens": max_new_tokens,
            "generation_limit_mode": generation_limit_mode,
            "completion_stopping_rule": "native_eos_or_optional_max_time",
            "max_generation_seconds_per_case": generation_timeout_seconds,
            "model_context_window_tokens": context_window,
            "generation_prompt_mode": "assistant_json_prefill",
            "evaluation_scope": {
                "assembled_output_guard": (
                    "Validates the complete response after the application prefilled "
                    "schema_version, context_reference_id, and the opening summary quote."
                ),
                "model_completion": (
                    "Contains only tokens generated by MedGemma; it is not an "
                    "independent standalone JSON response."
                ),
                "semantic_fields_evaluated": [
                    "summary_content",
                    "paragraphs",
                    "uncertainty",
                    "unresolved_influence_ids",
                    "next_observation_id",
                ],
            },
            "device": device,
            "dtype": dtype,
            "load_seconds": round(load_seconds, 3),
            "cuda_peak_memory_allocated_bytes": torch.cuda.max_memory_allocated(),
            "evaluation": score_evaluation_records(records).as_dict(),
            "records": records,
        }
        if failure is not None:
            result["failure"] = failure
        return result

    for case_index, messages in enumerate(messages_by_case):
        request = _request_from_messages(messages)
        assistant_prefill = _assistant_json_prefill(request)
        inputs = processor.apply_chat_template(
            _processor_messages(messages, assistant_prefill=assistant_prefill),
            add_generation_prompt=False,
            continue_final_message=True,
            tokenize=True,
            return_dict=True,
            return_tensors="pt",
        ).to(device)
        input_length = inputs["input_ids"].shape[-1]
        (
            resolved_max_new_tokens,
            resolved_generation_limit_mode,
            resolved_context_window,
        ) = (
            _resolve_max_new_tokens(
                model,
                input_length=input_length,
                requested_max_new_tokens=max_new_tokens,
            )
        )
        if generation_limit_mode is None:
            generation_limit_mode = resolved_generation_limit_mode
        elif generation_limit_mode != resolved_generation_limit_mode:
            raise RuntimeError("generation limit mode changed during evaluation")
        if resolved_context_window != context_window:  # pragma: no cover - model config is stable.
            raise RuntimeError("model context window changed during evaluation")
        generation_started = time.perf_counter()
        with torch.inference_mode():
            generated, completion_stop_reason = _generate_native_completion(
                model,
                inputs=inputs,
                max_new_tokens=resolved_max_new_tokens,
                generation_timeout_seconds=generation_timeout_seconds,
            )
        generation_seconds = time.perf_counter() - generation_started
        completion, response_parse_mode = _decode_assistant_response(
            processor, generated[0][input_length:]
        )
        completion_token_summary = _completion_token_summary(
            processor, generated[0][input_length:]
        )
        raw_output, normalization_mode = _normalize_terminal_fence(
            f"{assistant_prefill}{completion}"
        )
        raw_evaluation = evaluate_explainer_output(raw_output, request)
        action_only_failure = has_only_action_policy_errors(raw_evaluation)
        fallback_used = not raw_evaluation.passed and not action_only_failure
        delivery_base = (
            deterministic_explainer_fallback(request)
            if fallback_used
            else raw_evaluation.parsed
        )
        if delivery_base is None:  # pragma: no cover - failed output always uses fallback.
            raise RuntimeError("delivery output could not be constructed")
        delivered = apply_next_observation_policy(delivery_base, request)
        delivered_output = delivered.model_dump_json()
        model_next_observation_id = (
            raw_evaluation.parsed.next_observation_id if raw_evaluation.parsed else None
        )
        action_policy_overridden = (
            raw_evaluation.parsed is not None
            and model_next_observation_id != delivered.next_observation_id
        )
        delivery_evaluation = evaluate_explainer_output(delivered_output, request)
        records.append(
            {
                "case_index": case_index,
                "input_tokens": int(input_length),
                "generated_tokens": int(generated.shape[-1] - input_length),
                "resolved_max_new_tokens": resolved_max_new_tokens,
                "completion_stop_reason": completion_stop_reason,
                "completion_token_summary": completion_token_summary,
                "response_parse_mode": f"assistant_prefill+{response_parse_mode}",
                "response_normalization_mode": normalization_mode,
                "assistant_response_prefill": assistant_prefill,
                "application_prefilled_fields": [
                    "schema_version",
                    "context_reference_id",
                    "summary_opening_quote",
                ],
                "model_generated_fields": [
                    "summary_content",
                    "paragraphs",
                    "uncertainty",
                    "unresolved_influence_ids",
                    "next_observation_id",
                ],
                "generation_seconds": round(generation_seconds, 3),
                "model_completion": sanitize_fictional_output(completion),
                "raw_output": sanitize_fictional_output(raw_output),
                # This guard evaluates the assembled response. It verifies all
                # model-generated semantic fields, but the application supplied
                # the fixed contract prefix above.
                "assembled_output_evaluation": raw_evaluation.as_dict(),
                "model_evaluation": raw_evaluation.as_dict(),
                "fallback_used": fallback_used,
                "action_only_guard_failure": action_only_failure,
                "action_policy": {
                    "owner": "application",
                    "model_value": model_next_observation_id,
                    "delivered_value": delivered.next_observation_id,
                    "overridden": action_policy_overridden,
                },
                "delivered_output": delivered_output,
                "delivery_evaluation": delivery_evaluation.as_dict(),
            }
        )
        print(
            json.dumps(
                {
                    "event": "evaluation_case_complete",
                    "case_index": case_index,
                    "generated_tokens": int(generated.shape[-1] - input_length),
                    "generation_seconds": round(generation_seconds, 3),
                    "completion_stop_reason": completion_stop_reason,
                    "schema_valid": raw_evaluation.schema_valid,
                    "guard_accepted": raw_evaluation.passed,
                }
            ),
            flush=True,
        )
        if len(records) == 1 or len(records) % checkpoint_every == 0:
            _write_private_json(output_path, checkpoint_payload("running"))

    result = checkpoint_payload("complete")
    _write_private_json(output_path, result)
    return result


def run_vanilla_cloud_evaluation(
    settings: Settings,
    *,
    dataset_path: Path,
    output_path: Path,
    max_new_tokens: int | None = None,
    limit: int | None = None,
    checkpoint_every: int = 10,
    generation_timeout_seconds: float | None = _MAX_GENERATION_SECONDS,
) -> dict[str, Any]:
    """Evaluate frozen vanilla MedGemma on an immutable messages-only split."""

    return _run_cloud_evaluation(
        settings,
        dataset_path=dataset_path,
        output_path=output_path,
        adapter_path=None,
        max_new_tokens=max_new_tokens,
        limit=limit,
        checkpoint_every=checkpoint_every,
        generation_timeout_seconds=generation_timeout_seconds,
        adapter_base_precision="nf4",
    )


def run_lora_adapter_evaluation(
    settings: Settings,
    *,
    dataset_path: Path,
    adapter_path: Path,
    output_path: Path,
    max_new_tokens: int | None = None,
    limit: int | None = None,
    checkpoint_every: int = 10,
    generation_timeout_seconds: float | None = _MAX_GENERATION_SECONDS,
) -> dict[str, Any]:
    """Evaluate a saved LoRA adapter over the same BF16 base used in training."""

    return _run_cloud_evaluation(
        settings,
        dataset_path=dataset_path,
        output_path=output_path,
        adapter_path=adapter_path,
        max_new_tokens=max_new_tokens,
        limit=limit,
        checkpoint_every=checkpoint_every,
        generation_timeout_seconds=generation_timeout_seconds,
        adapter_base_precision="bf16",
    )


def run_qlora_adapter_evaluation(
    settings: Settings,
    *,
    dataset_path: Path,
    adapter_path: Path,
    output_path: Path,
    max_new_tokens: int | None = None,
    limit: int | None = None,
    checkpoint_every: int = 10,
    generation_timeout_seconds: float | None = _MAX_GENERATION_SECONDS,
) -> dict[str, Any]:
    """Evaluate a saved QLoRA adapter separately from the training process."""

    return _run_cloud_evaluation(
        settings,
        dataset_path=dataset_path,
        output_path=output_path,
        adapter_path=adapter_path,
        max_new_tokens=max_new_tokens,
        limit=limit,
        checkpoint_every=checkpoint_every,
        generation_timeout_seconds=generation_timeout_seconds,
    )
