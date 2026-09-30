# Vueniverse MedGemma v7 rollback manifest

- Backup ID: `v7-r2-r16a32-20260917`
- Created: 2026-09-17
- Bucket prefix: `gs://vueniverse-508413-medgemma-training/rollback/v7-r2-r16a32-20260917/`
- Retention: lifecycle-exempt under the current bucket rules; delete only by an explicit manual operation.
- Verified inventory before subsequent changes: 124 objects, 589,179,517 bytes (561.89 MiB).

## Preserved artifacts

- `canonical-dataset/`: canonical v7-r2 train, validation, test, quality report, and manifest.
- `model-facing-dataset/`: exact projected JSONL used by the trainer and evaluator.
- `sentinel/`: fixed sentinel-validation split.
- `training/`: complete training directory, console log, metrics, final adapter, and seven resumable checkpoints at optimizer steps 1, 5, 10, 15, 20, 25, and 28. Each checkpoint includes adapter, tokenizer, and optimizer state.
- `evaluation/`: complete held-out evaluation output and logs.
- `semantic-review/`: manual semantic judgments, experiment outcome, workbook, previews, and source output.
- `code-and-notes/`: the exact pipeline code and experiment documentation captured after v7 evaluation.

## Integrity anchors

- Canonical final adapter: `3962a62a6fbaf26c222dd8af658d23aab82e87f2014c5367a77d73d4744e4cc1`
- QLoRA training report: `fa7fce83e93e91355ca34d27c94db0a26938132ec3f69bf9a4fb99deddbb6e51`
- Held-out evaluation report: `858dd3c59403ea54ba048eba53040fb2a8543139499cf0073b7021a374b0ea9e`
- Model-facing train JSONL: `c93692d78017134a29635e2a9376359a2defe6086a2ded028da67d1182a79463`
- Model-facing validation JSONL: `b23a515c598cc337e3af388e61beb1aab167df3b6f6058d8efb67baed7c1f6d9`
- Model-facing test JSONL: `3b3af11158a05b9e9879b358a627c8379200623ac38d871ce07b832b3ac3ac4b`
- Sentinel JSONL: `c18cac5f3186c5229f41f6a8ba6fac88a424487236e43fa61ec1acc045ccc26d`

Hashes are SHA-256 values recorded by the producing pipeline. Verify restored files before resuming or comparing runs.

## Restore outline

Restore into a new directory; do not overwrite a newer run in place.

```bash
gcloud storage rsync --recursive \
  gs://vueniverse-508413-medgemma-training/rollback/v7-r2-r16a32-20260917/ \
  ./restored-v7-r2-r16a32-20260917/
```

For a training resume, select one of the preserved `training/checkpoint-optimizer-step-*` directories and retain its optimizer state. For inference only, use the final adapter in `training/final-adapter/`.
