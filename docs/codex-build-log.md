# Codex build log

## 2026-07-14 — Android-first project setup

- Upgraded Flutter from 3.13.3 to 3.44.6 and selected Android Studio Java 17.
- Refreshed Android/iOS templates and moved Android Gradle files to Kotlin DSL.
- Installed Android SDK/API 34 and 36, current emulator tooling, and Google Play ARM64 system images.
- Created `WhyPulse_API_34` and `WhyPulse_API_36` without modifying the existing API 33 AVD.
- Fixed the root Python `.gitignore` that accidentally excluded Flutter's `lib/` directory.
- Added the planned dependency baseline and empty architecture directories.
- Kept application code intentionally minimal; product and health features are deferred.

Verification commands:

```sh
make check
make android-smoke
make android-smoke-36
```
