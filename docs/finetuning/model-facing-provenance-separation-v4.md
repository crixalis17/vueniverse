# Model-facing provenance separation, v4

Status: superseded as the training candidate by dataset version 5; retained as a provenance record  
Dataset location: `tooling/medgemma/outputs/finetuning/supervised-dataset-v4/` (ignored, owner-only local files)  
Dataset version: 4

The current training candidate is version 5. It preserves this model-facing provenance
separation and additionally adds opaque context references; see
`docs/finetuning/context-reference-contract-v5.md`.

## Decision

The model must not learn to describe a person's context as `synthetic`. The dataset still
needs reliable provenance for the experiment. Version 4 therefore separates the two
boundaries:

- **Model-facing `messages`:** neutral, user-style context and analytics language only.
- **Non-model metadata, manifest, quality report, and documentation:** retain
  `synthetic_calibrated` and `synthetic_canonical` provenance.

The SFT chat template consumes the `messages` field. The metadata is not part of the
conversation supplied to MedGemma.

## Every model-facing replacement

| Earlier model-facing wording | Version 4 model-facing wording |
| --- | --- |
| `Synthetic evening alcohol intake entries` | `Evening alcohol intake entries` |
| `Synthetic canonical context` | `Canonical context` |
| `Synthetic analytics` | `Vueniverse analytics` |
| `Synthetic canonical` | `Vueniverse context` |
| `synthetic_low_coverage` | `low_coverage` |
| `Compare the next three synthetic eligible windows` | `Compare the next three eligible windows` |

Metric definitions were also rewritten to neutral terms such as `Event windows with
enough data` and `Matched no-event comparison windows`. Existing numerical values,
split assignments, model-output schema, and safety rules did not change.

## Complete-row verification

The version 4 builder scans every rendered system, user, and assistant message before it
writes a dataset. Any case-insensitive occurrence of `synthetic` in `messages` fails the
build. The resulting quality report confirms:

- 630 rows scanned;
- 0 model-facing `synthetic` markers;
- 630 metadata rows retaining `synthetic_calibrated` provenance;
- 0 group split overlaps;
- 0 duplicate prompts; and
- 0 duplicate assistant answers.

## Reproducibility hashes

| File | SHA-256 |
| --- | --- |
| `train.jsonl` | `845db7a4f4e8500c9bfd0e650ba805eaada9014d57f7f05e351bd728a1e60ecb` |
| `validation.jsonl` | `97e7fb001c53da469fdeafec053f198b33dcd2f3ee4d12e740b0a4896a0f73ec` |
| `test.jsonl` | `cda8a0fff9df13e69cd476180938e0887ec37828113e8339db2e3ec96f993cd4` |
| `holdout-manifest.json` | `ec3be6bdaa9a22fd037a7f6e79c98fc9ca049b2e62e50e548433fce6921e96a9` |
| `dataset-quality.json` | `4913b9898959230333aa418c22ead620956accbcf0beda6d9e3392993b38f58e` |

## Scope reminder

Neutral model language does not turn the records into personal data or real observations.
The dataset remains fully fictional and is valid only for the fine-tuning learning
experiment. Its provenance remains available outside the model conversation so it cannot
be mistaken for a production dataset.
