# App-derived readiness development benchmark

Generated October 3, 2026 under the [frozen evaluation contract](../../../docs/finetuning/readiness-evaluation-contract-v1.md).
This is **inspected development data**, not an independent final test or a training dataset.
Historical v7 datasets, adapters and benchmark reports are unchanged.

Ten raw timeline families produce 30 cases: explanation, disagreement and next
observation for each. They cover null/repeated/mixed effects, missing context,
sparse coverage, workout/illness exclusions, separated recurring identities,
missing identity and incompatible recorded offsets. Each timeline goes through
the production normalizer, database, analysis repository and evidence projection.
Input and contract hashes are recorded in `manifest.json`.

| File | Purpose |
|---|---|
| raw-timelines.jsonl | Simulated provider record envelopes; no personal records |
| app-projections.jsonl | Actual app request contract, expected analytical state, deterministic answer and research diagnostics |
| review-template.jsonl | Blank reviewer judgments; not completed or independent reviews |
| manifest.json | Counts, versions, hashes and explicit development-only status |

All 30 deterministic responses pass the guard. This establishes only contract/guard
compatibility, **not semantic correctness or clinical accuracy**. Expected analytical
states were authored and inspected by the same implementation agent. Independent
adjudication, semantic training-overlap audit, fresh final-set custody and model
comparisons remain pending. Correlated intents are ten clusters, not 30 independent
observations. Sign-test diagnostics do not authorize inferential claims.

Rebuild from repository root:

```sh
flutter test test/tools/readiness_evaluation_builder_test.dart \
  --dart-define=READINESS_EXPORT_DIR=experiments/readiness/development-v1 \
  --reporter expanded
PYTHONPATH=tooling/medgemma/src .venv/bin/python -m vueniverse_medgemma.readiness_audit \
  experiments/readiness/development-v1 \
  --contract docs/finetuning/readiness-evaluation-contract-v1.md
```

Do not rebuild a designated final set. This generator may rebuild development
files; replacement evidence/run identifiers mean projection byte hashes change
between builds. Keep the manifest with each recorded snapshot. These requests use
the current app contract, not the historical Python fine-tuning schema; a versioned
adapter is required before comparing archived models on them.
