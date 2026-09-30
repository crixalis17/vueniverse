# Dataset revision v6

## Purpose

Version 6 addresses the rank-16 adapter's finding-state collapse. The adapter produced
valid, grounded JSON but applied the supported-pattern framing to contradictory,
developing, insufficient-data, and null-pattern cases.

## Controlled change

- The v5 validation and test JSONL files are copied byte-for-byte into v6.
- Only the training split changes.
- The base model, prompt, context-reference boundary, metric schema, and runtime guard
  remain unchanged.
- The next rank-16 run can therefore be compared with the previous run on the same
  210-case validation benchmark.

## Training distribution

| Finding state | v5 rows | v6 rows |
| --- | ---: | ---: |
| supported | 168 | 168 |
| developing | 168 | 336 |
| null | 168 | 336 |
| contradictory | 168 | 336 |
| insufficient_data | 168 | 336 |
| **Total** | **840** | **1,512** |

Each of the six ask intents has 252 v6 training rows. Every assistant output is unique.

## Label changes

- Every summary retains an explicit state-specific conclusion.
- Each ask intent changes the response emphasis.
- Non-supported prompts receive two semantically equivalent label variants with a
  different evidence order and uncertainty wording.
- Promotion-gate examples explicitly distinguish findings that meet the repeated-pattern
  gate from those that do not.
- All 1,512 labels pass the existing runtime schema, grounding, terminology, and safety
  guard before the dataset is written.

## Verification

- Validation and test are byte-identical to v5.
- Context-reference split overlap: 0.
- Model-facing occurrences of the word `synthetic`: 0.
- Raw wearable records included: no.
- Raw canonical-event records included: no.
- Cloud projection contains only the `messages` field.

Generated artifacts:

```text
tooling/medgemma/outputs/finetuning/supervised-dataset-v6/
tooling/medgemma/outputs/finetuning/supervised-dataset-v6-cloud-preflight.json
tooling/medgemma/outputs/finetuning/supervised-dataset-v6-messages-projection/
```

## Next experiment

Retrain rank 16 / alpha 32 with the same QLoRA configuration. Do not change rank, alpha,
base model revision, inference protocol, or validation set in the same experiment. The
primary comparison is finding-state accuracy, followed by grounding, uncertainty,
safety, usefulness, and per-intent behavior.
