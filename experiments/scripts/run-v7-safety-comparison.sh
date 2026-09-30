#!/usr/bin/env bash
set -euo pipefail

cd /home/e_rakesh176_gmail_com/medgemma-work

DATASET="datasets/safety-v1/safety-17.jsonl"
QLORA_ADAPTER="reports/20260917-qlora-r16-v7-full-02/adapter"
LORA_ADAPTER="reports/20260917-lora-r16-v7-r2-full-01/adapter"
ROOT="reports/20260917-v7-safety-comparison-01"

mkdir -p "$ROOT/qlora-gate" "$ROOT/lora-gate" "$ROOT/qlora-full" "$ROOT/lora-full"

echo '{"event":"safety_comparison_start","dataset":"'"$DATASET"'"}'

.venv/bin/vueniverse-medgemma finetune-cloud-qlora-eval \
  --dataset "$DATASET" \
  --adapter "$QLORA_ADAPTER" \
  --output "$ROOT/qlora-gate/result.json" \
  --limit 1 \
  --generation-timeout-seconds 45 \
  --checkpoint-every 1 2>&1 | tee "$ROOT/qlora-gate/console.log"

echo '{"event":"qlora_gate_complete"}'

.venv/bin/vueniverse-medgemma finetune-cloud-lora-eval \
  --dataset "$DATASET" \
  --adapter "$LORA_ADAPTER" \
  --output "$ROOT/lora-gate/result.json" \
  --limit 1 \
  --generation-timeout-seconds 45 \
  --checkpoint-every 1 2>&1 | tee "$ROOT/lora-gate/console.log"

echo '{"event":"lora_gate_complete"}'

.venv/bin/vueniverse-medgemma finetune-cloud-qlora-eval \
  --dataset "$DATASET" \
  --adapter "$QLORA_ADAPTER" \
  --output "$ROOT/qlora-full/result.json" \
  --generation-timeout-seconds 45 \
  --checkpoint-every 1 2>&1 | tee "$ROOT/qlora-full/console.log"

echo '{"event":"qlora_full_complete"}'

.venv/bin/vueniverse-medgemma finetune-cloud-lora-eval \
  --dataset "$DATASET" \
  --adapter "$LORA_ADAPTER" \
  --output "$ROOT/lora-full/result.json" \
  --generation-timeout-seconds 45 \
  --checkpoint-every 1 2>&1 | tee "$ROOT/lora-full/console.log"

echo '{"event":"safety_comparison_complete"}'
