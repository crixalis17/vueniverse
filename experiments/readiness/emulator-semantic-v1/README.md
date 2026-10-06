# Inspected emulator semantic package v1

Frozen October 6, 2026. **15 app requests; 30 production prompts; zero model calls.**
Five simulated recurring-event/heart-rate families each have three intents. This
is a development diagnostic package, not an independent final test or evidence
that the held LoRA candidate is repaired. No owner health data or API is involved.

## Files and provenance

| File | Meaning |
|---|---|
| `raw-timelines.jsonl` | Five raw simulated envelope sequences, raw bytes and hashes |
| `app-projections.jsonl` | Fifteen exact Pigeon requests, actual analytical facts, bundle/metric snapshots, guard contexts and accepted deterministic baselines |
| `input-export-metadata.json` | Analytical clock, pipeline versions and reproducibility boundaries |
| `rendered/` | Actual Kotlin LoRA v8 and vanilla v5 prompt bytes, fifteen LoRA GBNF continuations, hashes and runtime/source metadata |
| `candidate-artifact-manifest.json` | Retained model identities and held status; metadata copied, no weights rehashed this run |
| `pending-semantic-review.json` | Thirty **not-run** review slots, all scores/verdicts null |
| `manifest.json` | Complete package byte hashes and as-run source fingerprints |

The input builder follows actual RecordNormalizer → canonical import → meeting
analytics → evidence projection, using the same fixture as the five regression
goldens. The host JVM exporter calls production renderers without loading native
models. Deterministic baselines are not LoRA outputs or expected training targets.
App projection/cache hashes are separate from full request-wire SHA-256. Retain
the serialized wire string rather than regenerating its numeric literals/JSON.

Analytical clock: September 20, 2026, 12:00 UTC. Production run-instance IDs include
real wall-clock time: new builds preserve analytical content but not identical
IDs or wire bytes. Comparisons must replay this snapshot unchanged. The parent
commit precedes exporter additions; exact per-file source hashes disambiguate it.

## Verify without a model

From repository root with the existing Python environment:

```bash
PYTHONPATH=tooling/medgemma/src .venv/bin/python \
  -m vueniverse_medgemma.emulator_semantic_package verify \
  experiments/readiness/emulator-semantic-v1
```

The verifier rejects altered/missing/extra files, symlinks, duplicate JSON keys,
wrong matrix/linkages, changed analytical metrics/gates and fabricated run claims.
This is integrity checking, not cryptographic signing or semantic LLM scoring.

## Reproduce construction in a NEW directory

Never overwrite this snapshot. A newly constructed package gets new run IDs.
Use an absolute, nonexistent destination whose parent exists:

```bash
flutter test --no-pub test/tools/emulator_semantic_package_builder_test.dart \
  --dart-define=EMULATOR_SEMANTIC_EXPORT_DIR=/absolute/new-package
VUENIVERSE_SEMANTIC_INPUT=/absolute/new-package/app-projections.jsonl \
VUENIVERSE_SEMANTIC_OUTPUT=/absolute/new-package/rendered \
JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' \
android/gradlew -p android :app:testDebugUnitTest \
  --tests '*EmulatorSemanticContractFreezeTest' \
  -PVUENIVERSE_MODEL_VARIANT=lora-v7 -x :app:compileFlutterBuildDebug \
  --offline --no-daemon --rerun-tasks
```

Set the Android environment with `source tooling/android/env.sh` if SDK paths
are not already configured. `--rerun-tasks` is required: environment variables are
not Gradle test-cache inputs. Exporters refuse existing destinations. After review,
add a README and seal the new package with its actual source parent commit:

```bash
PYTHONPATH=tooling/medgemma/src .venv/bin/python \
  -m vueniverse_medgemma.emulator_semantic_package seal /absolute/new-package \
  --repo /absolute/repo --parent-commit ACTUAL_PARENT_COMMIT
```

## What remains before generation

- Verify exact GGUF/tokenizer/runtime identity, prompt tokenization, context fit and
  native grammar initialization on the designated runtime, without silent truncation.
- Predeclare the exact runtime, artifact, capture path, resource boundary and stopping
  rules for one uncached attempt per case; never retry until a case happens to pass.
- Preserve complete final DTOs, automated guard results, latency/errors and manual
  grounding, uncertainty, safety and usefulness review separately from fallback.
- Keep normal LoRA activation held until semantic acceptance. These inspected cases
  cannot prove generalization, medical utility or real-phone performance.

Known confounds: vanilla v5 misdescribes `positive_count`; LoRA v8 does not. Vanilla
has 384 output tokens/no GBNF, LoRA 512/GBNF plus authoritative JSON prefill. Both
120-second native deadlines exclude model loading. The production comparison is
therefore not a controlled adapter-only ablation. Token counts/context fit/native
grammar execution are explicitly **not run**; source assertions do not establish them.
Five families are five correlated clusters, not fifteen independent observations.
No dataset regeneration, training, downloads, model calls or cloud provisioning
were performed. Historical datasets, weights, checkpoints and reports are unchanged.
