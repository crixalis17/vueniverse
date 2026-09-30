# Vueniverse

## Personal repository and experiment branch

Personal repository: [crixalis17/medgemma](https://github.com/crixalis17/medgemma).
The accumulated app changes and MedGemma experiments are on
**`medgemma-experiments-roadmap`**. This copy preserves the original Git
history from `mvp-ing/medgemma`.

```sh
git clone --branch medgemma-experiments-roadmap https://github.com/crixalis17/medgemma.git
cd medgemma
```

## MedGemma fine-tuning experiments

We fine-tuned **MedGemma 1.5 4B** using LoRA and QLoRA on realistic synthetic
wearable-health and contextual-event data. Training cases include calendar,
screen activity, calls, music, gaming, journals and food/beverage context;
the current live app workflow is narrower and focuses on calendar/heart-rate
analysis plus manual check-ins.

The selected research candidate is **LoRA BF16 v7**, subsequently merged and
quantized to **Q4_K_M**. Across the 210-case synthetic development benchmark,
rubric-weighted usefulness was 41.9% for vanilla, 75.0% for QLoRA and 76.9% for
LoRA. These are development judgments, not clinical accuracy measurements.
Android currently retains its original vanilla model pin; selected-LoRA phone
integration and physical-device acceptance remain roadmap tasks.

| Artifact | Location |
| --- | --- |
| Training, dataset generation and inference code | [`tooling/medgemma`](tooling/medgemma/README.md) |
| Synthetic model-facing dataset snapshots | [`experiments/datasets`](experiments/datasets) |
| Reports, judgments, benchmark workbooks and plots | [`experiments/reports`](experiments/reports) |
| Research paper | [PDF](experiments/research/vueniverse-medgemma-finetuning-research-report.pdf) |
| Experiment scripts | [`experiments/scripts`](experiments/scripts) |
| Resume models/checkpoints from the private archive | [Recovery README](experiments/recovery/README.md) |
| Experiment journal | [Journal](docs/finetuning/experiment-journal.md) |
| Product readiness and remaining work | [Roadmap](docs/finetuning/PRODUCT-READINESS-ROADMAP.md) |

Large model weights, adapters and checkpoints remain in the private Cloud Storage
resurrection bundle documented in the recovery guide. Credentials, raw Ultrahuman
data and local caches are excluded from Git. Some historical report scripts retain
the original workspace paths; use the preserved reports directly or adjust paths
before regenerating them. No permanent hosted inference service is required.

Recent analytical changes prevent known calendar events from contaminating controls,
add structured caffeine amount/coverage capture and screen recorded illness, travel,
exercise and workout recovery on both meeting and control sides. These safeguards
preserve uncertainty rather than interpreting missing logs as absent influences.

**Vueniverse = View + Universe:** a different view of health, built by bringing
together the universe of data around each person.

Android-first Flutter implementation of the Vueniverse evidence-to-action experience described in [`health-os-plan.html`](health-os-plan.html).

The current build contains the complete interactive UI/UX journey plus native source bridges, encrypted Drift stores, deterministic evidence generation, and a guarded MedGemma integration. Deterministic supported, null, contradictory, and missing-data cases keep the demonstration repeatable when no model runtime is accepted or available.

## Required toolchain

- macOS on Apple silicon
- Flutter `3.44.6` / Dart `3.12.2`
- Android Studio Java 17
- Android SDK platforms 34 and 36
- Android Emulator with ARM64 Google Play images
- Xcode is retained for the generated iOS host, but iOS is not a setup gate

Verify the local baseline:

```sh
flutter --version
flutter doctor -v
```

Flutter should use Android Studio's JDK:

```sh
flutter config --jdk-dir "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
```

## First-time setup

Install Dart dependencies and create the Android emulators:

```sh
make setup
make android-bootstrap
```

The bootstrap script is idempotent. It creates these AVDs without deleting existing devices:

- `Vueniverse_API_34` — Android 14 baseline
- `Vueniverse_API_36` — primary current Android target

The previous `Pixel_6_Pro_API_33` AVD is preserved but is not an acceptance target.

AVDs default to an 8 GB data partition. On a low-disk development machine, choose a smaller local partition without changing the checked-in setup:

```sh
VUENIVERSE_AVD_DISK_SIZE=1G VUENIVERSE_AVD_RAM_MB=2048 make android-bootstrap
```

## Run

Launch an emulator:

```sh
make android-34
# or
make android-36
```

In another terminal:

```sh
flutter run -d emulator-5554  # API 34
flutter run -d emulator-5556  # API 36
```

For a USB-connected physical Android phone, follow the serial-pinned build,
install, private-model copy, and validation procedure in
[`docs/physical-phone-adb-runbook.md`](docs/physical-phone-adb-runbook.md).

Live builds obtain the on-device model from a native Gradle property. No URL or
access token is committed. For a local debug run, inject the future stable
direct HTTPS object URL through the process environment:

```sh
ORG_GRADLE_PROJECT_VUENIVERSE_MODEL_DOWNLOAD_URL='https://your-host.example/medgemma-1.5-4b-it-Q4_K_M.gguf' \
  flutter run -d emulator-5554
```

Debug builds may omit the property and report **Not configured**. Release
configuration fails when the property is absent. For local development, the
currently pinned artifact is Unsloth's `medgemma-1.5-4b-it-Q4_K_M.gguf` at
revision `1fe03a2916e0a4ed250fdeedc3e56a94f3bf2a30` (`2489894976` bytes,
SHA-256 `b31becdf4f39561800505514cce67681604fe449d04dd35c8c92fd7848c6d7bd`).
A future hosted object must match that identity and support `Content-Length`,
`ETag`, and byte `Range` requests. Confirm that distributing the derived GGUF
complies with the MedGemma access terms before provisioning it.

The technical download flow is **not** by itself redistribution clearance.
Google's current HAI-DEF terms treat sharing a modified/quantized model as
distribution of a Model Derivative. Before setting a real URL, the release
owner must arrange an enforceable downstream agreement containing the use
restrictions, provide recipients the HAI-DEF agreement, add a prominent
modification notice and required `Notice` text, and complete any applicable
regulatory review. Keep release URL provisioning blocked until that legal
package has been approved.

Run the setup smoke checks:

```sh
make check
make android-smoke
make android-smoke-36
```

## Project boundaries

The implementation follows these architecture boundaries:

```text
lib/app/           Flutter shell, routing, theme
lib/domain/        Health-independent contracts and rules
lib/data/          Local database and repository implementations
lib/features/      Product screens and feature state
lib/platform_api/  Generated/native bridge clients
pigeon/            Typed Dart/Kotlin/Swift bridge declarations
detectors/         Reviewed DetectorSpec assets
tooling/gpt_lab/   Future synthetic-only development tooling
```

The interactive product state and screens currently use deterministic local presentation models. The package baseline includes Riverpod, GoRouter, Drift, JSON serialization, Pigeon, and integration testing for the next persistence and native-source layers.

## MedGemma 1.5 runtime status

The model runtime targets only `google/medgemma-1.5-4b-it` at the pinned
checkpoint revision recorded in
[`tooling/medgemma/.env.example`](tooling/medgemma/.env.example). Older
MedGemma experiment results are not used for the runtime decision.

Completed work includes:

- BF16 smoke inference, F16 GGUF conversion, and reproducible Q4_K_M/Q5_K_M
  quantization with hashes and manifests.
- A 17-case fictional safety and grounding evaluation on both quantizations,
  with Q4_K_M retained as the provisional mobile candidate.
- A loopback-only Demo development service backed by pinned `llama.cpp`, with
  Live-store rejection, lifecycle handling, cancellation, and stable errors.
- Android model delivery and integrity checks, JNI/native runtime integration,
  a Kotlin runtime orchestrator, and benchmark/result metadata.
- Versioned Explorer and Explainer Pigeon contracts, `MainActivity`
  registration/teardown, runtime inspection, and shared cancellation.
- Dart runtime selection for phone-local, Demo-only loopback development, and
  deterministic fallback paths. Live and Demo automatically prefer the phone
  runtime as soon as the verified artifact is available; debug Demo builds can
  then use the loopback development service, which accepts fictional Demo data
  only.
- A deterministic output guard before persistence or display, exact
  evidence/request cache keys, rejection metadata with discarded unsafe text,
  evidence-version invalidation, bounded Ask routing, and exact runtime labels.
- A bounded Explorer projection over compact event summaries with allow-listed
  operations, category IDs, and influence IDs. Invalid decisions fall back to
  a reviewed deterministic selection.
- API 34 ARM64 emulator compatibility and real Demo-service request testing.
  Model weights, credentials, and generated reports remain outside Git and the
  APK.
- Offline, fallback, invalid-output, cancellation, and model-invalidation test
  evidence across the Python and Android layers.
- Demo fixture v4 with 2,990 canonical records across 30 consecutive days:
  2,800 heart-rate samples, 30 each of HRV, steps, and sleep, 10 workouts,
  30 activity intervals, 30 privacy-safe Calendar events, and 30 detailed
  manual check-ins. Each day adds 44 ambient heart-rate readings around the
  preserved minute-level meeting and matched-control windows.
- Sixteen truth-labelled Demo scenarios: five engine-calculated meeting
  outcomes, two lifecycle receipts, two seeded completed experiments, and
  seven explicitly illustrative future detectors.
  The guided 90-second path shows evidence preparation, the runtime actually
  selected, claim validation, model name, and latency; it never labels
  deterministic backup text as model output or exposes private chain-of-thought.

The Kotlin runtime and model-download Pigeon APIs are registered in
`MainActivity`. The WorkManager downloader resumes into an app-private partial,
verifies exact size and SHA-256, and atomically promotes only a valid final
artifact. Its interrupted small-fixture resume test passes on the API 34 ARM64
emulator. Full MG-10 remains open until a real stable URL is supplied and the
2.49 GB artifact completes the unskipped bounded Q4 generation suite. The
physical-phone latency/memory/battery/thermal measurements (MG-12) and final
runtime decision (MG-13) also remain open.

See the [model tooling guide](tooling/medgemma/README.md), the
[execution checklist](docs/medgemma-subtasks/README.md), and the
[runtime spike](docs/medgemma-runtime-spike.md) for commands, historical work
packets, and measured results. Use the
[Demo video runbook](docs/demo-video-runbook.md) for the recording order,
scenario boundaries, and exact fixture expectations.

## Emulator recovery

- Cold boot: `tooling/android/launch.sh 34 cold` or `tooling/android/launch.sh 36 cold`.
- Wipe data only when an AVD is corrupt: Android Studio → Device Manager → device menu → **Wipe Data**.
- Reset a stuck emulator: `adb -s emulator-5554 emu kill` and launch it again.
- Port 5554 is reserved for API 34; port 5556 is reserved for API 36. The launcher stops if another AVD occupies either port.
- Logs are written to `/tmp/Vueniverse_API_34.log` and `/tmp/Vueniverse_API_36.log`.
- If startup reports insufficient space for `userdata`, free disk space or use the low-resource bootstrap command above. Google Play images still require several gigabytes for first boot. Existing AVDs are preserved; only their configuration is updated.

## Current truth

- Working now: complete navigable UI/UX, isolated encrypted Demo/Live stores, source synchronization and source-data views, deterministic analysis/evidence, experiments and exports, registered MedGemma contracts, guarded/cached explanations, bounded Ask, deterministic fallback, and the reviewed Explorer boundary.
- Verification now: Flutter analysis, unit/widget tests, Android JVM protocol tests, and an API 34 ARM64 interrupted/resumed fixture download with verified atomic promotion.
- Still open: the real-URL/real-model part of MG-10, MG-12 physical-phone benchmarks, and the MG-13 phone-local acceptance decision. Live remains deterministic while the model is unavailable.
