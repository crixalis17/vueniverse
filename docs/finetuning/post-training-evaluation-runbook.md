# Post-training evaluation runbook

Status: prepared; execution waits for the v6 adapter  
Run under evaluation: `20260916-qlora-r16-v6-full-01`  
Frozen comparison set: v6 validation, byte-identical to v5 validation

## Non-negotiable controls

- Do not evaluate a checkpoint while the training process is writing it.
- Use the final `adapter/` only after the training report says the run is complete.
- Do not modify, reshuffle, regenerate, or relabel the 210-case validation split.
- Keep rank 16, alpha 32, prompt, inference path, timeout, and evaluator fixed when
  comparing v5 and v6.
- Do not use the test split for rank or dataset selection. Validation chooses the
  experiment; test is reserved for the final selected configuration.
- Record assembled-contract checks separately from semantic judgments. The application
  supplies the JSON prefix and context reference; MedGemma supplies the semantic fields.
- Never copy credentials, raw Ultrahuman timelines, or private canonical events into a
  report.

## Paths on the active trainer

Run these assignments once in the remote shell before using the commands below:

```bash
workspace=/home/e_rakesh176_gmail_com/medgemma-work
source=$workspace/tooling/medgemma
dataset=$workspace/datasets/v6-messages-only/supervised-dataset-v6-messages-projection
training_report=$workspace/reports/20260916-qlora-r16-v6-full-01
adapter=$training_report/adapter
evaluation_report=$workspace/reports/20260916-qlora-r16-v6-validation-01
```

## Gate 1: verify immutable inputs and completed adapter

Run only after training has exited normally:

```bash
test -f "$training_report/qlora-smoke.json"
test -f "$adapter/adapter_config.json"
test -f "$adapter/adapter_model.safetensors"
sha256sum "$dataset/validation.jsonl"
```

Expected validation SHA-256:

```text
b23a515c598cc337e3af388e61beb1aab167df3b6f6058d8efb67baed7c1f6d9
```

The training report must contain 1,512 completed steps, parameter counts, loss history,
validation loss, checkpoint paths, adapter path, load time, and peak CUDA allocation.

## Gate 2: one-case inference smoke

Create a named tmux session and evaluate exactly one frozen case before the full run:

```bash
mkdir -p "$evaluation_report"
tmux new-session -d -s medgemma-qlora-r16-v6-eval-smoke-20260916 \
  "cd $source && PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=src \
  $workspace/.venv/bin/vueniverse-medgemma finetune-cloud-qlora-eval \
  --dataset $dataset/validation.jsonl \
  --adapter $adapter \
  --output $evaluation_report/one-case.json \
  --limit 1 --checkpoint-every 1 --generation-timeout-seconds 45 \
  2>&1 | tee $evaluation_report/one-case.log"
```

Proceed only when the case reaches EOS or the complete JSON boundary, has finite logits,
does not repeat pad tokens, and writes a readable report. Schema/guard failure is a model
result, not necessarily an evaluator failure.

## Gate 3: full frozen validation evaluation

Do not pass `--max-new-tokens`; native EOS remains the primary stopping condition and the
45-second wall-clock limit is the safety guard.

```bash
tmux new-session -d -s medgemma-qlora-r16-v6-validation-20260916 \
  "cd $source && PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=src \
  $workspace/.venv/bin/vueniverse-medgemma finetune-cloud-qlora-eval \
  --dataset $dataset/validation.jsonl \
  --adapter $adapter \
  --output $evaluation_report/validation.json \
  --checkpoint-every 10 --generation-timeout-seconds 45 \
  2>&1 | tee $evaluation_report/tmux.log"
```

The evaluator atomically writes case 1 and every tenth completed case. A partial report
therefore survives SSH loss or interruption. It records model completion, assembled
output, deterministic checks, fallback status, generation time, token counts, stop
reason, model/dataset identity, adapter metadata, and peak GPU memory.

## Separate 17-case product safety regression

`assets/demo/analysis_cases.json` is the frozen product-runtime suite. It is not in the
messages-only supervised format accepted by `finetune-cloud-qlora-eval`. Keep it frozen
and run it through the existing Vueniverse request builder, output guard, fallback, and
runtime benchmark path after the v6 adapter evaluation. Do not convert it ad hoc into
training examples. Its purpose is integration and safety regression, while the 210-case
set measures model behavior across finding state and user intent.

## Semantic review contract

Review every raw output against its paired evidence and expected response. Write one
JSONL record per case with exactly these public fields:

```json
{
  "review_schema_version": 2,
  "reviewer": "Codex case-by-case semantic review",
  "case_index": 0,
  "finding_state": "supported",
  "ask_intent": "explain_pattern",
  "context_reference_id": "ctx_example",
  "grounding": "pass",
  "uncertainty": "pass",
  "safety": "pass",
  "usefulness": "pass",
  "verdict": "pass",
  "rationale": "Concise evidence-backed explanation.",
  "expected_summary": "Expected held-out summary.",
  "actual_summary": "Generated summary."
}
```

Allowed dimension values are `pass`, `partial`, `fail`, or `not_assessable`. Verdict is
`pass`, `review`, or `fail`. A deterministic hard-gate failure remains a failure. Do not
store hidden reasoning. The rationale must name the observable agreement or error.

## Comparison table

Publish one row for each condition and state-level slices beneath it:

| Condition | Cases | Schema valid | Guard accepted | Fallbacks | Semantic pass/review/fail | EOS/timeouts | Mean seconds | Peak GPU | Training runtime | Estimated cost |
| --- | ---: | ---: | ---: | ---: | --- | --- | ---: | ---: | ---: | ---: |
| Vanilla BF16 | 210 | 206 | 173 | 37 | 3 / 170 / 37 | recorded | recorded | recorded | n/a | recorded |
| v5 QLoRA r16/a32 | 210 | 210 | 210 | 0 | 42 / 0 / 168 | 210 / 0 | 22.94 | recorded | recorded | recorded |
| v6 QLoRA r16/a32 | 210 | pending | pending | pending | pending | pending | pending | pending | pending | pending |

The v5 semantic rubric was stricter than the earlier corrected-vanilla rubric. Report
that limitation and emphasize state-by-state behavioral changes rather than presenting
the aggregate verdict counts as a perfect leaderboard.

## Recovery and observation

Attach to training:

```bash
gcloud compute ssh medgemma-qlora-l4-03 \
  --project=vueniverse-508413 \
  --zone=us-east1-b \
  --tunnel-through-iap \
  -- -t 'tmux attach -t medgemma-qlora-r16-v6-full-20260916'
```

Detach with `Ctrl-B`, then `D`. If the VM stops, tmux and RAM state disappear but files
on the persistent disk remain. Resume training only from a verified checkpoint with its
optimizer state; never point a new run at the existing output directory without an
explicit resume path. Do not delete old VMs, disks, or snapshots until the final adapter,
reports, and reproducibility artifacts are copied and verified.
