# Vueniverse v0.0.1

**Release date:** 21 July 2026

**Platform:** Android preview

Vueniverse v0.0.1 is the first evidence-to-action preview: a private health
timeline that helps people inspect recurring patterns, understand the evidence
behind them, and test small changes without turning AI output into medical
advice.

## Highlights

- Explore a complete 30-day Snapshot built from isolated fictional data, or
  connect Live sources when permissions and device support are available.
- Review heart rate, HRV, sleep, steps, exercise, active calories, calendar
  categories, and manual check-ins in a local-first timeline and Observe
  dashboard.
- Inspect deterministic findings with matched comparisons, effect ranges,
  completeness, exclusions, uncertainty, and counterevidence.
- Replay repeated event windows with Moment Fingerprint, correct possible
  influences, and recompute affected results.
- Ask Vueniverse for a bounded MedGemma explanation grounded only in the
  evidence already calculated by the app.
- Predeclare small personal experiments, track adherence, review the result,
  and preserve prior versions in History.
- Export a proof receipt containing the result, sources, evidence fingerprint,
  analytical version, and the runtime that produced the explanation.

## Private and evidence-first by design

- Live and Snapshot records stay in separate encrypted, app-private stores.
- Calendar details are reduced to reviewed category and timing fields; titles,
  attendees, descriptions, locations, and organizers are not retained.
- The deterministic evidence engine calculates every finding before MedGemma
  can explain it. Generated text cannot create, promote, or modify evidence.
- Model responses must pass schema, evidence-matching, and safety checks before
  they can be shown or cached. Vueniverse uses checked fallback wording when a
  model response is unavailable or rejected.
- Editing or deleting source data invalidates dependent findings,
  explanations, experiments, and exports so stale results are not presented as
  current.

## On-device MedGemma delivery

Vueniverse does not bundle model weights in the APK. Onboarding downloads the
2.49 GB MedGemma 1.5 4B Q4 model over unmetered Wi-Fi, supports resumable
background transfer, checks the pinned file size, and installs the artifact in
app-private storage before Snapshot or Live can continue. SHA-256 enforcement
is temporarily disabled in the hackathon build and must be restored before
production release.

The Android downloader can receive a short-lived signed URL through Firebase
Remote Config, refresh it after an authorization failure, and resume the same
partial artifact. A native Gradle property remains available for controlled
development builds. Credentials and durable signed URLs must never be embedded
in the app.

## Known limitations

- This preview targets Android only; iOS is outside the v0.0.1 release scope.
- A valid, authorized model-download URL, sufficient free storage, and an
  unmetered connection are required to complete onboarding. The bare private
  GCS object URL is not sufficient on its own.
- Full real-model delivery acceptance on the API 34 ARM64 emulator and the
  physical-phone latency, memory, battery, and thermal benchmark remain release
  gates. Until they pass, phone-local MedGemma performance is unverified.
- Vueniverse supports personal understanding only. It does not diagnose,
  recommend treatment, or replace professional medical care.

## Validation and setup

Developers can use the [release validation commands](README.md#validate-the-release)
and the [journey-ordered manual integration runbook](docs/manual-integration-test-runbook.md)
to verify the app, privacy boundaries, source flows, experiments, exports, and
device-specific MedGemma gates.
