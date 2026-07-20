# Person 2 remaining MedGemma subtasks

This document converts the remaining Person 2 work in
[`Implementation-plan.md`](../../Implementation-plan.md) into bounded work packets.
Each packet has one primary output, an isolated file boundary, and a verification
command. Packets in the same parallel wave may be implemented concurrently.

## Current baseline

Already complete and excluded from the remaining work:

- MedGemma access, local environment, and ignored model cache.
- Exact `google/medgemma-1.5-4b-it` checkpoint pinning.
- BF16 smoke inference and F16 GGUF conversion.
- Q4_K_M and Q5_K_M quantization with artifact hashes.
- Host Q4/Q5 comparison and provisional Q4_K_M selection.
- API 34 ARM64 emulator compatibility smoke test.
- Versioned Explorer, Explainer, and constrained repair prompts.
- Seventeen-case fictional Explainer evaluation and deterministic fallback.
- Reproducibility and runtime-spike documentation.

The Demo-only Vueniverse service and Wave 2 orchestrator are assembled. The
Kotlin/JNI core is registered with Flutter, wrapped by the Dart runtime policy,
and covered by JVM integration tests. The newly integrated app flow has not
been re-run on an emulator. Earlier emulator results remain compatibility
evidence and do not count as the required physical-phone benchmark.

## Remaining execution checklist

Wave 1 packets have no subtask dependencies:

- [x] MG-01 — Demo-only service boundary
- [x] MG-02 — llama.cpp inference backend
- [x] MG-03 — Complete the model evaluation matrix
- [x] MG-04 — Prompt versioning and repair template
- [x] MG-05 — Android model artifact manager
- [x] MG-06 — JNI llama.cpp core
- [x] MG-07 — Runtime benchmark harness

Wave 2 packets integrate completed foundations:

- [x] MG-08 — Assemble the Demo-only development runtime
- [x] MG-09 — Kotlin phone-runtime orchestrator
- [ ] MG-10 — Emulator runtime integration checkpoint
- [x] MG-11 — Offline, fallback, and invalidation support evidence

Wave 3 requires hardware and completed runtime paths:

- [ ] MG-12 — Physical-phone benchmark
- [ ] MG-13 — Final runtime decision and handoff

## Coordination rules

These rules remain for independently assigned model packets. MG-10 application
integration uses the unified ownership override in `Implementation-plan.md`.

- Work only on `codex/medgemma-runtime` or a branch created from it.
- Do not commit model weights, raw personal data, tokens, or generated reports.
- Use fictional or de-identified replay fixtures only. Event data remains mock.
- Person 2 owns `tooling/medgemma/**`, the Android `medgemma/**` package, and
  model-specific documents and tests.
- Do not hand-edit generated Pigeon Dart or Kotlin files.
- Do not modify Person 1's `lib/**`, Pigeon definitions, app tests, persistence,
  analytics, UI, or safety policy inside an independent packet.
- A task that needs `MainActivity.kt`, `pubspec.yaml`, or another Person 1 file
  must wait for the named integration checkpoint.
- Preserve Q4_K_M as the candidate until physical-device measurements justify a
  different runtime decision.

For an independently assigned packet:

1. Create a branch named `codex/mg-XX-short-name` from the latest
   `codex/medgemma-runtime`.
2. Change only the packet's owned paths.
3. Run the packet verification plus the existing fast model tests.
4. Record assumptions and measured results without checking in generated model
   output.
5. Hand off the commit hash, verification output, known limitations, and any
   new dependency. Do not mark a dependent packet complete implicitly.

## Status key

- `READY`: can start from the current branch without another subtask.
- `COMPLETE`: implementation and packet verification passed.
- `PARTIAL`: some reusable work exists, but the acceptance criteria are unmet.
- `BLOCKED`: requires listed predecessor packets or external hardware.

## Parallel wave 1: independent foundation packets

All wave 1 packets can be executed independently.

### MG-01 — Demo-only service boundary

**Status:** `COMPLETE`
**Size:** Medium

Build the Vueniverse HTTP boundary with an injected fake backend. Do not couple it
to llama.cpp in this packet.

Owned paths:

- `tooling/medgemma/src/vueniverse_medgemma/service/api.py`
- `tooling/medgemma/src/vueniverse_medgemma/service/models.py`
- `tooling/medgemma/tests/test_service_api.py`

Deliverables:

- Localhost-only server configuration.
- Versioned request and response envelopes.
- Mandatory store discriminator with Demo accepted and Live rejected before the
  backend is called.
- `/health` and `/ready` endpoints.
- Stable JSON errors for invalid schema, forbidden store, backend unavailable,
  timeout, cancellation, and internal failure.
- Dependency-injected backend protocol so tests never load the model.

Acceptance:

- Live requests receive a deterministic forbidden response and invoke the fake
  backend zero times.
- Invalid payloads never reach the backend.
- Demo fixture requests return a versioned response.
- The server binds to `127.0.0.1` by default.

Verification:

```sh
.venv/bin/pytest -q tooling/medgemma/tests/test_service_api.py
```

### MG-02 — llama.cpp inference backend

**Status:** `COMPLETE`
**Size:** Medium

Extract model execution from the benchmark into a reusable backend. Do not add
HTTP routing in this packet.

Owned paths:

- `tooling/medgemma/src/vueniverse_medgemma/service/backend.py`
- `tooling/medgemma/tests/test_service_backend.py`

Reusable inputs:

- Pinned llama.cpp server binary.
- Q4_K_M artifact and manifest.
- Existing streaming and process-lifecycle code in `benchmark.py`.

Deliverables:

- Explicit `start`, `infer`, `cancel`, `health`, and `close` lifecycle.
- Greedy decoding and bounded output tokens.
- Configurable startup and inference timeouts.
- One in-flight request by default.
- Raw structured output plus load, time-to-first-token, total-latency, model,
  quantization, and backend metadata.
- Model process cleanup after success, failure, cancellation, and test teardown.

Acceptance:

- Unit tests use a fake subprocess or fake local server.
- Missing binary, missing model, startup failure, timeout, and disconnect have
  distinct errors.
- Cancellation terminates the active request without orphaning a process.
- A local Q4 smoke test can be enabled explicitly but is not part of fast tests.

Verification:

```sh
.venv/bin/pytest -q tooling/medgemma/tests/test_service_backend.py
```

### MG-03 — Complete the model evaluation matrix

**Status:** `COMPLETE`
**Size:** Medium

Extend model-specific evaluation without changing Person 1's output guard.

Owned paths:

- `tooling/medgemma/src/vueniverse_medgemma/fixtures.py`
- `tooling/medgemma/src/vueniverse_medgemma/evaluation.py`
- `tooling/medgemma/tests/test_evaluation_matrix.py`
- `docs/medgemma-evaluation/**`

Deliverables:

- Explicit cases for invented numbers, fake citations, malformed JSON, truncated
  output, inference timeout, cancellation, and backend disconnect.
- Existing positive, null, contradictory, insufficient-data, diagnosis,
  prescription, causality, prompt-injection, generic-chat, and full-timeline
  cases retained.
- Separate measurements for raw schema validity, raw guard acceptance, fallback
  use, and final delivered acceptance.
- Sanitized raw fictional outputs and a machine-readable score summary.

Acceptance:

- Every required Phase 5 case has a stable case ID.
- No fixture contains personal health or calendar data.
- Evaluation distinguishes model failure from delivery failure.
- Fast tests do not require model weights.

Verification:

```sh
.venv/bin/pytest -q tooling/medgemma/tests/test_evaluation.py tooling/medgemma/tests/test_evaluation_matrix.py
```

### MG-04 — Prompt versioning and repair template

**Status:** `COMPLETE`
**Size:** Small

Complete the owned prompt package without changing application contracts or
safety policy.

Owned paths:

- `tooling/medgemma/prompts/explorer_system.txt`
- `tooling/medgemma/prompts/explainer_system.txt`
- `tooling/medgemma/prompts/guard_repair_system.txt`
- `tooling/medgemma/src/vueniverse_medgemma/prompt_catalog.py`
- `tooling/medgemma/tests/test_prompt_catalog.py`

Deliverables:

- Immutable prompt identifiers and versions.
- SHA-256 prompt hashes included in benchmark/runtime metadata.
- One constrained JSON repair template.
- Fictional few-shot examples covering supported and non-supported findings.
- Tests that prevent missing versions, duplicate IDs, or accidental prompt
  changes without a version bump.

Acceptance:

- Prompts require supplied facts, JSON-only output, citations, uncertainty, and
  refusal of generic chat, diagnosis, treatment, and causality.
- Repair receives only the rejected output, schema error summary, and allowed
  identifiers; it receives no raw records.
- The repair path is capped at one attempt.

Verification:

```sh
.venv/bin/pytest -q tooling/medgemma/tests/test_prompt_catalog.py
```

### MG-05 — Android model artifact manager

**Status:** `COMPLETE`
**Size:** Medium

Implement model discovery and integrity checks independently of JNI inference.

Owned paths:

- `android/app/src/main/kotlin/com/vueniverse/vueniverse/medgemma/ModelArtifactManager.kt`
- `android/app/src/test/kotlin/com/vueniverse/vueniverse/medgemma/ModelArtifactManagerTest.kt`
- `docs/medgemma-subtasks/model-delivery.md`

Deliverables:

- External/app-private model path policy.
- Expected model ID, revision, quantization, size, and SHA-256 metadata.
- Streaming checksum verification.
- Clear missing, unreadable, size-mismatch, and checksum-mismatch results.
- Installation instructions that do not package the original checkpoint or
  quantized weights into the APK.

Acceptance:

- Valid Q4 metadata passes without loading the model.
- Missing and corrupt test artifacts fail deterministically.
- No model file appears under Flutter or Android asset declarations.

Verification:

```sh
android/gradlew -p android :app:testDebugUnitTest
```

### MG-06 — JNI llama.cpp core

**Status:** `COMPLETE`
**Size:** Large

Turn the existing ARM64 llama.cpp build knowledge into a JNI library. Do not
register it with Flutter or edit `MainActivity.kt` in this packet.

Owned paths:

- `android/app/src/main/cpp/medgemma/**`
- `android/app/src/main/kotlin/com/vueniverse/vueniverse/medgemma/NativeMedGemma.kt`
- `android/app/src/androidTest/kotlin/com/vueniverse/vueniverse/medgemma/NativeMedGemmaSmokeTest.kt`
- `tooling/medgemma/scripts/build_android_jni.sh`

Deliverables:

- ARM64 CMake/JNI build using the pinned llama.cpp revision.
- Native `load`, `infer`, `cancel`, and `close` functions.
- Greedy decoding, context bound, output-token bound, and stop handling.
- Native error codes for missing/corrupt model, allocation failure, invalid
  prompt, cancellation, timeout, and internal error.
- Thread-safe ownership with idempotent teardown.

Acceptance:

- Native library builds for the emulator ABI.
- A bounded Q4 prompt loads and begins generation in the API 34 emulator.
- Cancel and close do not crash or leak a reusable native context.
- No original model checkpoint is packaged.

Verification:

```sh
flutter build apk --debug
flutter test integration_test
```

### MG-07 — Runtime benchmark harness

**Status:** `COMPLETE`
**Size:** Medium

Create one machine-readable benchmark format usable by host, emulator, and
physical-phone runs. This packet records measurements; it does not decide the
runtime.

Owned paths:

- `tooling/medgemma/src/vueniverse_medgemma/runtime_metrics.py`
- `tooling/medgemma/tests/test_runtime_metrics.py`
- `docs/medgemma-evaluation/benchmark-schema.json`

Deliverables:

- Versioned records for artifact identity, device/runtime identity, cold load,
  warm latency distribution, time to first token, peak incremental RSS,
  schema validity, guard acceptance, fallback, cancellation, crash/OOM, and
  thermal state.
- Aggregate p50/p95 calculations and ten-call summary.
- Explicit distinction among host, emulator, and physical-device evidence.

Acceptance:

- Empty, partial, interrupted, and failed runs serialize deterministically.
- Emulator measurements cannot be marked as a phone-local pass.
- The pass evaluator enforces warm p95 at most eight seconds, peak incremental
  RSS at most 3.5 GB, raw schema validity at least 95%, no crash/OOM, and no
  severe thermal state over ten calls.

Verification:

```sh
.venv/bin/pytest -q tooling/medgemma/tests/test_runtime_metrics.py
```

## Parallel wave 2: integration packets

Wave 2 packets are individually bounded, but start only after their named wave
1 predecessors are complete.

### MG-08 — Assemble the Demo-only development runtime

**Status:** `COMPLETE`
**Size:** Medium

Owned paths:

- `tooling/medgemma/src/vueniverse_medgemma/service/app.py`
- `tooling/medgemma/src/vueniverse_medgemma/service/cli.py`
- `tooling/medgemma/tests/test_service_integration.py`
- `tooling/medgemma/scripts/run_demo_server.sh`
- `tooling/medgemma/scripts/adb_reverse_demo_server.sh`

Deliverables:

- Wire the validated HTTP boundary to the llama.cpp backend.
- Startup and health commands.
- Schema prevalidation, prompt formatting, greedy decoding, timeout, runtime
  metadata, and stable errors.
- Reproducible `adb reverse` setup.
- One real fictional Demo fixture request returning raw structured model output.

Acceptance:

- Live requests are rejected before inference.
- A Demo request succeeds from the emulator through `adb reverse`.
- Backend failure and disconnect return bounded errors.
- The service contains no cloud dependency.

Verification:

```sh
.venv/bin/pytest -q tooling/medgemma/tests/test_service_integration.py
```

### MG-09 — Kotlin phone-runtime orchestrator

**Status:** `COMPLETE`
**Size:** Large

Implement the native side of the existing Pigeon runtime contract. Contract
changes remain out of scope.

Owned paths:

- `android/app/src/main/kotlin/com/vueniverse/vueniverse/medgemma/MedGemmaRuntime.kt`
- `android/app/src/main/kotlin/com/vueniverse/vueniverse/medgemma/MedGemmaRuntimeResultMapper.kt`
- `android/app/src/test/kotlin/com/vueniverse/vueniverse/medgemma/MedGemmaRuntimeTest.kt`

Deliverables:

- Background load and inference outside the Flutter UI thread.
- Serialized inference, cancellation, timeout, output limit, and teardown.
- Artifact validation before native loading.
- Runtime metadata and bounded failure mapping.
- Deterministic handling for unavailable or corrupt model files.

Acceptance:

- Tests use fake artifact and native adapters.
- Cancellation, timeout, missing model, corrupt model, and successful inference
  each produce distinct bounded results.
- No Flutter UI or persistence code is modified.

Verification:

```sh
android/gradlew -p android :app:testDebugUnitTest
```

### MG-10 — Emulator runtime integration checkpoint

**Status:** `INTEGRATED; DEVICE VERIFICATION DEFERRED` — registration, teardown,
Pigeon contracts, Dart coordination, guard, cache, UI, and JVM tests are complete.
The emulator flow was intentionally not run during this integration because of
local machine performance.
**Size:** Medium

This integration packet has unified ownership. The earlier Person 1/Person 2
path split does not apply to this task.

Owned paths:

- `android/app/src/main/kotlin/com/vueniverse/vueniverse/medgemma/**`
- `android/app/src/androidTest/kotlin/com/vueniverse/vueniverse/medgemma/**`
- A coordinated, minimal registration edit in `MainActivity.kt`

Deliverables:

- Register and unregister the existing Pigeon host API.
- Select the permitted runtime in Dart and guard every result before cache or
  display.
- Persist accepted/rejected metadata while discarding rejected model prose.
- Run load, infer, cancel, timeout, close, missing-model, and corrupt-model flows
  on the API 34 ARM64 emulator.
- Confirm UI-thread responsiveness and bounded teardown.

Acceptance:

- Flutter analysis and all existing tests remain green.
- Debug APK builds without bundling model weights.
- Emulator test results are labelled compatibility-only.

Verification:

```sh
make check
flutter build apk --debug
tooling/medgemma/scripts/run_emulator_checkpoint.sh \
  /absolute/path/medgemma-1.5-4b-it-Q4_K_M.gguf
```

The checkpoint script requires exactly one API 34 ARM64 emulator, validates the
full artifact hash and size, installs it into the debug app-private model
directory, and sets `requireRealModel=true`. A missing model therefore fails
the run instead of producing an optional-test skip.

Current verification completed without an emulator:

```sh
flutter analyze
flutter test
JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' \
  android/gradlew -p android :app:testDebugUnitTest
```

### MG-11 — Offline, fallback, and invalidation support evidence

**Status:** `COMPLETE`
**Size:** Small

Person 1 owns the application behavior. Person 2 supplies backend failure modes,
metadata, fixtures, and evidence needed for Person 1's tests.

Owned paths:

- `tooling/medgemma/tests/test_runtime_support_cases.py`
- `docs/medgemma-evaluation/runtime-support-cases.md`

Deliverables:

- Reproducible unavailable-model response.
- Reproducible backend-disconnect response.
- Evidence-version mismatch fixture.
- Accepted-output metadata fixture suitable for cache/export tests.
- Written expected behavior for reopening cached output without a model.

Acceptance:

- Support fixtures contain no app database or personal data.
- Person 1 can consume them without running MedGemma.
- No experiment, History, export, or persistence code is implemented here.

Verification:

```sh
.venv/bin/pytest -q tooling/medgemma/tests/test_runtime_support_cases.py
```

## Wave 3: hardware and release decision

### MG-12 — Physical-phone benchmark

**Status:** `BLOCKED` by access to a supported ARM64 phone
**Size:** Medium

Run Q4_K_M on the chosen physical device using the MG-07 benchmark schema.

Deliverables:

- Cold load and warm p50/p95 latency.
- Peak incremental RSS.
- Raw JSON validity and guard-acceptance rates.
- Ten repeated calls with thermal state and crash/OOM observations.
- Battery level and temperature samples across the repeated calls.
- Cancellation and teardown result.
- Device, OS/API level, ABI, model hash, and runtime revision.

Acceptance:

- No crash/OOM.
- Warm p95 is at most eight seconds.
- Peak incremental RSS is at most 3.5 GB.
- Raw schema validity before repair is at least 95%.
- No severe thermal state over ten calls.

If any threshold fails, record phone-local as failed and use the Demo-only
development runtime. Do not tune the conclusion or substitute emulator values.

The collection and scoring path is implemented. It refuses emulators, validates
the exact model artifact, records ten calls plus cancellation, writes the MG-07
JSON report, and scores it without substituting host data:

```sh
tooling/medgemma/scripts/run_physical_benchmark.sh \
  /absolute/path/medgemma-1.5-4b-it-Q4_K_M.gguf
```

### MG-13 — Final runtime decision and handoff

**Status:** `BLOCKED` by MG-12
**Size:** Small

Owned paths:

- `docs/medgemma-runtime-spike.md`
- `docs/medgemma-evaluation/final-runtime-decision.md`
- `tooling/medgemma/README.md`

Deliverables:

- Exact checkpoint, quantization, backend, and model-delivery method.
- Cold/warm latency, peak memory, thermal result, JSON validity, guard
  acceptance, and known limitations.
- Explicit phone-local pass/fail decision.
- Reproducible development-machine setup and runtime labels.
- Verification that model weights are not accidentally packaged.
- Claims aligned exactly with measured host, emulator, and physical-device data.

Acceptance:

- At least one real MedGemma backend works for a fictional Demo request.
- Development runtime cannot accept Live requests.
- Runtime instructions reproduce from a clean environment with local model
  access.
- Documentation clearly separates measured results from provisional decisions.

## Dependency map

```text
MG-01 service boundary -----+
                            +--> MG-08 Demo runtime --------+
MG-02 llama backend --------+                              |
                                                           +--> MG-13 final handoff
MG-03 evaluation matrix -----------------------------------|
MG-04 prompt package --------------------------------------|
MG-05 artifact manager ----+                               |
                            +--> MG-09 phone runtime --> MG-10 emulator integration
MG-06 JNI core ------------+                         |     |
                                                      +--> MG-11 support evidence
MG-07 benchmark schema ------------------------------+     |
                                                            |
MG-09 + physical phone --> MG-12 physical benchmark --------+
```

## Recommended execution order

1. Run MG-01 through MG-07 in parallel where capacity allows.
2. Assemble the Demo runtime with MG-08 as soon as MG-01 and MG-02 pass.
3. Assemble the phone runtime with MG-09 after MG-05 and MG-06 pass.
4. Perform the coordinated emulator checkpoint in MG-10.
5. Supply support fixtures through MG-11.
6. Run MG-12 only when a physical phone is available.
7. Record the final deployment decision in MG-13.

The Demo-only development runtime is the reliable delivery path while the
phone-local path remains conditional on physical-device thresholds.
