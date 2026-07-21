# Vueniverse

> A private, evidence-first health timeline that helps you understand recurring
> patterns and test small changes.

**Current release:** v0.1.0 for Android

Vueniverse means **View + Universe**: a clearer view of health built from the
universe of information around each person. It brings health signals, recurring
events, and personal context into one local timeline, then turns repeated
patterns into evidence you can inspect, question, and act on.

Vueniverse is designed for personal understanding. It does not diagnose,
recommend treatment, or replace professional medical care.

## What Vueniverse does

Vueniverse supports the full path from raw records to a personal learning loop:

1. **Observe** — review retained health, activity, event, and check-in data
   before it becomes a finding.
2. **Discover** — identify recurring patterns using deterministic comparisons,
   explicit minimums, and visible uncertainty.
3. **Replay** — inspect repeated traces and compare them with matched baseline
   windows.
4. **Challenge** — review counts, exclusions, missing context,
   counterevidence, and possible influences.
5. **Explain** — receive a bounded, plain-language explanation grounded only in
   the evidence already calculated by the app.
6. **Test** — predeclare a small personal experiment and evaluate what changed.
7. **Preserve** — keep versioned findings and experiments in History or export
   their supporting proof.

## Release highlights

- **Local-first health timeline** backed by encrypted SQLCipher/Drift stores.
- **Android Health Connect** ingestion for heart rate, HRV, sleep, steps,
  exercise, and active calories.
- **Privacy-aware Calendar review** that retains event category and timing, not
  titles, attendees, descriptions, locations, or organizers.
- **Manual check-ins** for caffeine, exercise, illness, mood, travel, and
  reviewed custom context.
- **Observe dashboard** with 7-day and 30-day trends, source coverage, source
  mix, recent records, refresh, and empty states.
- **Deterministic evidence engine** with matched comparisons, completeness,
  effect ranges, exclusions, and honest supported, mixed, null, weakened, and
  expired states.
- **Moment Fingerprint and Replay** for repeated event windows and matched
  controls.
- **Evidence challenge flow** for correcting influences and recomputing affected
  results.
- **Personal experiments** with predeclared outcomes, reminders, and preserved
  result history.
- **Proof export** with sources, analytical version, evidence state, and runtime
  provenance.
- **Bounded Ask and explanation flows** with deterministic safety checks,
  evidence citations, exact cache keys, cancellation, and safe fallback text.
- **On-device MedGemma integration** with verified private model storage,
  resumable background delivery, integrity checks, and offline inference
  contracts.
- **Fictional-data experience** containing 30 days of isolated records for
  exploring the complete product without granting personal-data permissions.

## How evidence and AI work together

Vueniverse never asks a language model to invent the health result.

```text
Health Connect + Calendar + Check-ins
                  ↓
       Encrypted local timeline
                  ↓
     Deterministic evidence engine
                  ↓
      Versioned evidence bundle
                  ↓
 Guarded MedGemma explanation or checked fallback
                  ↓
      Challenge → Test → History
```

The evidence engine calculates the comparison, counts, range, completeness,
exclusions, and uncertainty first. MedGemma can then narrate that bounded
evidence on the device. Every generated response passes an output guard before
it can be displayed or cached. If the model is unavailable or its output is
invalid, Vueniverse uses reviewed deterministic wording instead.

## Privacy by design

- Personal records stay in an encrypted, app-private local database.
- Personal and fictional data are held in isolated stores and are never mixed.
- Calendar content is reduced to privacy-safe category and timing fields after
  review.
- Generated text cannot become evidence or change a calculated result.
- Deleting or editing source data invalidates and recomputes affected findings.
- Model weights, credentials, and generated evaluation reports are not included
  in Git or packaged directly in the APK.

## Run Vueniverse on Android

### Requirements

- macOS on Apple silicon
- Flutter `3.44.6` / Dart `3.12.2`
- Android Studio Java 17
- Android SDK platforms 34 and 36
- Android Emulator with ARM64 Google Play images

The generated iOS host remains in the repository, but iOS is not part of this
release.

Verify the local toolchain:

```sh
flutter --version
flutter doctor -v
flutter config --jdk-dir "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
```

Install dependencies and create the Android virtual devices:

```sh
make setup
make android-bootstrap
```

The bootstrap command is idempotent and preserves existing devices. It creates:

- `Vueniverse_API_34` — Android 14 compatibility target
- `Vueniverse_API_36` — primary Android target

For a smaller local data partition:

```sh
VUENIVERSE_AVD_DISK_SIZE=1G VUENIVERSE_AVD_RAM_MB=2048 make android-bootstrap
```

Launch a device:

```sh
make android-34
# or
make android-36
```

Run the app in another terminal:

```sh
flutter run -d emulator-5554  # API 34
flutter run -d emulator-5556  # API 36
```

For a USB-connected Android phone, follow the
[physical phone runbook](docs/physical-phone-adb-runbook.md).

## On-device model configuration

Android builds receive the private model URL through the native Gradle property
`VUENIVERSE_MODEL_DOWNLOAD_URL`. URLs and access tokens must not be committed.

For a local debug run:

```sh
ORG_GRADLE_PROJECT_VUENIVERSE_MODEL_DOWNLOAD_URL='https://your-host.example/medgemma-1.5-4b-it-Q4_K_M.gguf' \
  flutter run -d emulator-5554
```

Debug builds may omit the property and report **Not configured**. Release builds
require it. The pinned local artifact is Unsloth's
`medgemma-1.5-4b-it-Q4_K_M.gguf` at revision
`1fe03a2916e0a4ed250fdeedc3e56a94f3bf2a30`:

```text
Size:    2,489,894,976 bytes
SHA-256: b31becdf4f39561800505514cce67681604fe449d04dd35c8c92fd7848c6d7bd
```

The host must provide `Content-Length`, `ETag`, and byte `Range` support. Model
distribution also requires an approved downstream agreement, the applicable
HAI-DEF agreement and notices, use restrictions, and any required regulatory
review. A working URL alone is not redistribution clearance.

See the [model tooling guide](tooling/medgemma/README.md),
[execution checklist](docs/medgemma-subtasks/README.md), and
[runtime notes](docs/medgemma-runtime-spike.md) for reproducible conversion,
evaluation, delivery, and validation commands.

## Validate the release

Run the complete repository checks:

```sh
make check
make android-smoke
make android-smoke-36
```

`make check` verifies formatting, static analysis, and the Flutter test suite.
The Android smoke targets verify the installed app on the API 34 and API 36
ARM64 environments. The
[manual integration runbook](docs/manual-integration-test-runbook.md) covers the
journey-ordered product, privacy, source, experiment, export, and runtime
acceptance checks.

## Project structure

```text
lib/app/             App shell, routing, theme, preferences, and state
lib/domain/          Evidence, analytics, experiment, and runtime rules
lib/data/            Encrypted storage, repositories, sources, and exports
lib/features/        Product screens and user journeys
lib/platform_api/    Generated bridge clients
pigeons/             Typed Dart/Kotlin bridge declarations
android/             Android host, source bridges, model delivery, and JNI
tooling/android/     Reproducible emulator setup and smoke checks
tooling/medgemma/    Model conversion, evaluation, and runtime tooling
```

The app uses Flutter, Riverpod, GoRouter, Drift, SQLCipher, Pigeon, WorkManager,
Kotlin, JNI, and `llama.cpp`. The product architecture follows the canonical
[Vueniverse product plan](health-os-plan.html).

## What's next

### Work in progress

- **MG-10 — full model delivery acceptance:** provision an approved stable URL,
  complete the 2.49 GB artifact transfer, and run the unskipped bounded Q4
  generation suite on the API 34 ARM64 environment.
- **MG-12 — physical-phone benchmark:** record latency, peak memory, battery,
  and thermal measurements on a supported ARM64 Android phone.
- **MG-13 — final runtime decision:** accept or revise the phone-local runtime
  based on the physical measurements and product thresholds.

Until those gates close, deterministic evidence and checked fallback
explanations remain the reliable path whenever the phone model is unavailable.

### Future scope

- Additional source connectors and direct wearable integrations.
- FHIR import for portable clinical records.
- A multimodal personal journal and smart-environment context.
- Shared analysis packs and quiet, opt-in background intelligence.
- Adaptive presentation and accessibility refinements.
- An iOS release after the Android experience and runtime are fully accepted.

Expansion features will use the same local-first source contract, evidence
boundaries, privacy rules, and truthful availability states as the current
release.
