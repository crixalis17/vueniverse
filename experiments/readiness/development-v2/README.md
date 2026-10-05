# App-derived readiness development snapshot: analysis v7

This inspected development snapshot preserves 30 projections from ten simulated
timeline families under the frozen readiness-evaluation-v1 contract. It updates
recovery boundaries and deterministic observation/insufficient-data wording; v1
is retained separately. No personal records, training changes or independent final
evaluation are included.

`manifest.json` records actual input/projection/contract hashes and versions.
`raw-timelines.jsonl` contains provider envelopes, `app-projections.jsonl` contains
actual pipeline requests/answers, and `review-template.jsonl` remains blank.
Guard compatibility is not semantic correctness or clinical accuracy. Independent
adjudication, training-overlap audit and a fresh final evaluation remain pending.

Reproduce only into a new development snapshot directory:

```sh
flutter test test/tools/readiness_evaluation_builder_test.dart \
  --dart-define=READINESS_EXPORT_DIR=experiments/readiness/development-v2
PYTHONPATH=tooling/medgemma/src .venv/bin/python -m vueniverse_medgemma.readiness_audit \
  experiments/readiness/development-v2 \
  --contract docs/finetuning/readiness-evaluation-contract-v1.md
```

Run identifiers can change projection byte hashes on regeneration. Preserve each
manifest with its snapshot; do not overwrite a designated final set.
