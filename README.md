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

Vueniverse. Know your why. Shape what's next.

## What Vueniverse does

Vueniverse supports the full path from raw records to a personal learning loop:

1. **Observe:** Review retained health, activity, event, and check-in data
   before it becomes a finding.
2. **Discover:** Identify recurring patterns using deterministic comparisons,
   explicit minimums, and visible uncertainty.
3. **Replay:** Inspect repeated traces and compare them with matched baseline
   windows.
4. **Challenge:** Review counts, exclusions, missing context,
   counterevidence, and possible influences.
5. **Explain:** Receive a bounded, plain-language explanation grounded only in
   the evidence already calculated by the app.
6. **Test:** Predeclare a small personal experiment and evaluate what changed.
7. **Preserve:** Keep versioned findings and experiments in History or export
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

- `Vueniverse_API_34`: Android 14 compatibility target
- `Vueniverse_API_36`: Primary Android target

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

## On-device MedGemma

Vueniverse does not bundle model weights in the APK. During onboarding, Android
downloads the 2.49 GB MedGemma model from a short-lived signed URL, supports
resumable background transfer, checks the pinned file size, and installs the
artifact in app-private storage. SHA-256 enforcement is temporarily disabled in
the hackathon build and must be restored before production release.

Firebase Remote Config supplies the current signed URL, with a native Gradle
property available for controlled development builds. Remote Config values are
not secrets: use short-lived, read-only URLs and never embed service-account
credentials in the app. See the
[model delivery guide](docs/medgemma-subtasks/model-delivery.md) and
[runtime checklist](docs/medgemma-subtasks/README.md) for full setup, security,
licensing, and validation instructions.

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

- **MG-10 (full model delivery acceptance):** Provision an approved stable URL,
  complete the 2.49 GB artifact transfer, and run the unskipped bounded Q4
  generation suite on the API 34 ARM64 environment.
- **MG-12 (physical-phone benchmark):** Record latency, peak memory, battery,
  and thermal measurements on a supported ARM64 Android phone.
- **MG-13 (final runtime decision):** Accept or revise the phone-local runtime
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
