# WhyPulse

Android-first Flutter project foundation for the private Health OS described in [`health-os-plan.html`](health-os-plan.html).

This repository is intentionally at **setup stage**. It contains the Android/iOS Flutter hosts, dependency baseline, empty architecture boundaries, two reproducible Android emulators, and a minimal launch screen. Health Connect reads, product screens, detectors, storage, GPT tooling, and MedGemma are not implemented yet.

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

The empty directories under `lib/` reserve the architecture from the plan:

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

Only `lib/main.dart` contains application code today. The package baseline already includes Riverpod, GoRouter, Drift, JSON serialization, Pigeon, and integration testing so feature work can begin without another scaffold migration.

## Emulator recovery

- Cold boot: `tooling/android/launch.sh 34 cold` or `tooling/android/launch.sh 36 cold`.
- Wipe data only when an AVD is corrupt: Android Studio → Device Manager → device menu → **Wipe Data**.
- Reset a stuck emulator: `adb -s emulator-5554 emu kill` and launch it again.
- Port 5554 is reserved for API 34; port 5556 is reserved for API 36. The launcher stops if another AVD occupies either port.
- Logs are written to `/tmp/WhyPulse_API_34.log` and `/tmp/WhyPulse_API_36.log`.
- If startup reports insufficient space for `userdata`, free disk space or use the low-resource bootstrap command above. Google Play images still require several gigabytes for first boot. Existing AVDs are preserved; only their configuration is updated.

## Current truth

- Working now: Flutter/Android scaffold, package configuration, API 34/36 AVD setup, minimal app, unit/integration smoke tests, Android CI.
- Deferred: Health Connect permissions/data, Calendar Provider, SQLCipher schema, seed product flow, MedGemma, detector analytics, and GPT-5.6 tooling.
