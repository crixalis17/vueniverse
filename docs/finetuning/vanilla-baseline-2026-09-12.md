# Vanilla MedGemma baseline — 2026-09-12

This is the Day 1 pre-training baseline for the first LoRA/QLoRA learning
experiment. The generated report remains local because raw model outputs are
intentionally ignored by Git.

## Reproduction

From the repository root:

```sh
.venv/bin/vueniverse-medgemma benchmark \
  --llama-cpp-dir tooling/medgemma/.cache/llama.cpp \
  --variants Q4_K_M Q5_K_M
```

Generated report:

```text
tooling/medgemma/reports/generated/gguf-benchmark.json
```

Report SHA-256:

```text
6c489c4e9f1c790522e4552c751f27e1a7e086ebccf7152652064c840ded6b20
```

## Frozen configuration

- Model: `google/medgemma-1.5-4b-it`
- Model revision: `91850547d9f0b2fdd21aa7c5f4f3d1a8a52c243b`
- Prompt version: 6
- Decoding: greedy with JSON-schema grammar
- Cases: 17 fictional safety and grounding cases per variant

## Results

| Measure | Q4_K_M | Q5_K_M |
| --- | ---: | ---: |
| Cases | 17 | 17 |
| Raw schema valid | 17 | 17 |
| Raw guard accepted | 17 | 3 |
| Delivered accepted | 17 | 17 |
| Deterministic fallbacks | 0 | 14 |
| Mean time to first token | 1.00 s | 0.95 s |
| Mean total response | 3.02 s | 4.69 s |
| RSS after load | 2.64 GiB | 2.94 GiB |

## Interpretation

Q4_K_M is the clean vanilla regression baseline for this prompt and evaluator:
all 17 raw responses passed without fallback.

Q5_K_M produced valid JSON in every case, but only three raw responses passed
the grounding guard. Most rejected responses introduced unsupported `75` and
`86` values; the null case used disallowed technical language, and two other
cases contained unsupported numbers. The deterministic fallback made all 17
delivered responses valid.

This difference is useful evidence for the fine-tuning experiment: schema
validity alone does not imply grounded behavior. Adapter comparisons must report
both raw model acceptance and post-fallback delivery acceptance.

## Repository verification

- MedGemma Python tooling: 56 tests passed.
- Dart formatting: 72 files checked, zero changes required.
- Flutter static analysis: no issues found.
- Flutter unit/widget suite: 90 tests passed.

The pre-existing modification to
`docs/submission-video-script-expanded-2m55.md` was preserved and is unrelated
to this experiment.
