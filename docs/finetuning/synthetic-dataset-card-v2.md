# Synthetic calibrated supervised dataset card, v2

Status: Day 3 complete  
Dataset location: `tooling/medgemma/outputs/finetuning/supervised-dataset-v2/` (ignored, owner-only local files)  
Dataset schema: `vueniverse-supervised-explainer-dataset-v1`  
Dataset version: 2

## Purpose

This is a small learning dataset for supervised fine-tuning of the Vueniverse explanation
task with LoRA and QLoRA. It teaches an instruction-tuned model to turn a pre-computed,
synthetic result into grounded JSON. It does not teach the model to calculate wearable
statistics, join calendar data, diagnose, identify causes, or give treatment advice.

## Provenance and privacy boundary

- Every record is labelled `synthetic_calibrated`.
- Local Ultrahuman data influenced only coarsened sampling-variability behavior in the
  generator. No raw readings, time series, dates, timestamps, source filenames, account
  IDs, or personal canonical events appear in this dataset.
- Synthetic recurring meetings are fictional. Their recurrence and duration are split
  grouping metadata, not real-calendar data.
- The training files contain the existing synthetic evidence projection, not raw sensor
  windows. The model only sees counts, supplied metric strings, allowed identifiers, and
  an output schema.

## Format

Each JSONL row has a `messages` array compatible with Transformers chat templates and
TRL supervised fine-tuning:

1. the unchanged production `explainer_system` prompt (version 6, SHA-256
   `ce061a0e5c6cbf049968df0e1da34d4e508d61dca1b80fce0e76a472563177d0`);
2. a synthetic `EvidenceBundle`, allowed IDs, and the exact per-request JSON schema; and
3. a curated JSON assistant answer validated by the repository's production grounding
   and safety guard.

The system prompt remains the production prompt. The user message explicitly carries the
output schema because the training rows do not have the llama.cpp JSON-grammar channel
that the local product benchmark uses. Day 4's PyTorch baseline must use this same user
message renderer for a fair fine-tuning comparison.

## Split and holdout design

There are 360 distinct synthetic recurring-event groups:

```text
5 finding states × 6 question intents × 3 recurrence patterns × 4 durations
```

Groups were assigned with a stable SHA-256 order separately within each finding state,
before any assistant labels were rendered. A group can occur in exactly one split.

| Split | Records | Per finding state |
| --- | ---: | ---: |
| Train | 270 | 54 |
| Validation | 45 | 9 |
| Test (immutable holdout) | 45 | 9 |

This is intentionally smaller than the initial 300/50/50 target. The 270/45/45 result
uses every clean group in the current grid rather than padding the set with near-duplicate
windows.

## Labels and review

Labels use curated state-and-intent response templates with twelve safe uncertainty
variants. Each answer copies numeric strings only from supplied metrics, cites every
paragraph, uses only allowed IDs, avoids medical and causal claims, and is checked with
`evaluate_explainer_output` during construction.

The initial review covered all 30 state-by-intent label families plus representative
rendered records. Automated validation covered all 360 rows for strict JSON schema,
citation and number grounding, approved identifiers, prohibited private-data markers,
duplicate prompts, duplicate answers, and group split leakage.

## Quality result

The `dataset-quality.json` report passed with:

- 360 valid rows;
- zero group split overlaps;
- zero duplicate prompts;
- zero duplicate assistant answers; and
- no detected private-data markers.

## Reproducibility hashes

| File | SHA-256 |
| --- | --- |
| `train.jsonl` | `b13e0f99c029fc96b54d4ec93c8ae483633493912fd0fa4c5536b287bffe0f11` |
| `validation.jsonl` | `653f7ad3a1984886c216b8328bc403e607815ee407b41251d4180bb226ce81a2` |
| `test.jsonl` | `cbfcc54f2cabf8666bb58d98fd15d971709d5993be06fc85b62c345e49c8fe4e` |
| `holdout-manifest.json` | `01f8e842eb172c5ad466a1a358a912b824874ba79b1b3560c39060dcbf84cfe0` |
| `dataset-quality.json` | `fd9f41547d2ab800c5a89b42a434f0e3fb4a0dd49f10f6bf56a921245a9c877b` |

## Limitations

- The examples are synthetic, template-authored, and narrow. They are a learning asset,
  not a claim of real-world health performance.
- A held-out synthetic group tests generalization to unseen synthetic combinations, not
  clinical generalization or real calendar-to-wearable correlation.
- The small data volume may cause style learning more than broad reasoning improvement.
  Day 7 must explicitly inspect for template imitation, overconfidence, invented values,
  and safety regressions.
- The adapter must remain behind the existing output guard. Fine-tuning does not replace
  deterministic analytics, privacy controls, or safety validation.
