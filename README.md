# WhyPulse

Android-first Flutter implementation of the WhyPulse evidence-to-action experience described in [`health-os-plan.html`](health-os-plan.html).

The current build contains the complete interactive UI/UX journey: onboarding, standalone source management, Today, History, Moment Fingerprint, Evidence, directly discoverable bounded Ask WhyPulse, experiments, all four result outcomes, Proof/Export, Settings, honest Preview surfaces, and the Later expansion catalogue. Deterministic supported, null, contradictory, and missing-data cases keep the entire demonstration repeatable while native ingestion, encrypted persistence, and MedGemma runtime work remain separate engineering layers.

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

- `WhyPulse_API_34` — Android 14 baseline
- `WhyPulse_API_36` — primary current Android target

The previous `Pixel_6_Pro_API_33` AVD is preserved but is not an acceptance target.

AVDs default to an 8 GB data partition. On a low-disk development machine, choose a smaller local partition without changing the checked-in setup:

```sh
WHY_PULSE_AVD_DISK_SIZE=1G WHY_PULSE_AVD_RAM_MB=2048 make android-bootstrap
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

Person 2's model work targets only `google/medgemma-1.5-4b-it` at the pinned
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
- API 34 ARM64 emulator compatibility and real Demo-service request testing.
  Model weights, credentials, and generated reports remain outside Git and the
  APK.
- Offline, fallback, invalid-output, cancellation, and model-invalidation test
  evidence across the Python and Android layers.

The Kotlin runtime is intentionally not registered in `MainActivity` yet. That
Flutter/native integration is the coordinated MG-10 checkpoint with Person 1.
Physical-phone latency, memory, battery, and thermal measurements (MG-12) and
the final runtime decision (MG-13) also remain open; emulator results are
compatibility evidence only.

See the [model tooling guide](tooling/medgemma/README.md), the
[execution checklist](docs/medgemma-subtasks/README.md), and the
[runtime spike](docs/medgemma-runtime-spike.md) for commands, ownership, and
measured results.

## Emulator recovery

- Cold boot: `tooling/android/launch.sh 34 cold` or `tooling/android/launch.sh 36 cold`.
- Wipe data only when an AVD is corrupt: Android Studio → Device Manager → device menu → **Wipe Data**.
- Reset a stuck emulator: `adb -s emulator-5554 emu kill` and launch it again.
- Port 5554 is reserved for API 34; port 5556 is reserved for API 36. The launcher stops if another AVD occupies either port.
- Logs are written to `/tmp/WhyPulse_API_34.log` and `/tmp/WhyPulse_API_36.log`.
- If startup reports insufficient space for `userdata`, free disk space or use the low-resource bootstrap command above. Google Play images still require several gigabytes for first boot. Existing AVDs are preserved; only their configuration is updated.

## Current truth

- Working now: complete navigable UI/UX, deterministic Demo and live-setup journeys, source management states, evidence lifecycle and edge-case screens, evidence-cited bounded Ask responses, experiment lifecycle and four result states, proof surfaces, Preview/Later truth labels, widget journey tests, API 34 integration smoke test, Android debug build, API 34/36 AVD setup, and the isolated MedGemma 1.5 development/runtime layers described above.
- Deferred engineering layers: production Health Connect and Calendar reads, encrypted Drift persistence, background recomputation, export file generation, coordinated Flutter registration of the MedGemma runtime, and physical-device model acceptance. The UI uses an explicitly guarded deterministic explanation fallback and never requires those layers for the demo journey.
