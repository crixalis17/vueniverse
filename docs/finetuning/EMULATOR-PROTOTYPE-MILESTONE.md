# Emulator prototype milestone

Agreed October 5, 2026. The immediate deliverable is an emulator-verified
prototype with Ultrahuman-shaped health imports and manual check-ins. The ultimate
goal remains use on the owner's Nothing Phone 2 (8 GB RAM); physical-device
acceptance is deferred, not removed.

This checklist is declared before the next verification run. Passing collection
checks establishes **collection-prototype acceptance**, not a working, approved
MedGemma prototype. Model-enabled acceptance is a separate required gate below.
Known failures must remain visible; neither a green test count nor a fallback
can stand in for a useful model answer.

## Safe verification boundary

- Use one identified, disposable emulator copy with no owner data. Confirm its
  exact serial and emulator identity before installing or resetting anything.
- Use bundled synthetic fixtures and mocked Ultrahuman replies only. Do not read
  or import an owner API key or personal health/check-in data for this gate.
- Restrict destructive encryption/reset tests to that isolated copy. Preserve the
  original emulator and historical reports; do not erase an existing useful store.
- Retain the normal production entry point with candidate evaluation and contract
  diagnostics off. LoRA stays held until its separate semantic gate passes.
- Record app/source versions, test scope, actual executed counts, skipped tests,
  failures and final emulator state. Do not turn an unavailable test into a pass.

## A. Collection-prototype acceptance — verified paths, with limits

- [x] ~~Onboarding reaches the collection-first route without required Calendar
  permission or model download; consent and disconnected source states are clear.~~
- [x] ~~Supported mocked health replies produce faithful metric counts, ranges and
  receipts; rejected, missing and unknown fields remain visible rather than invented.~~
  Supported HR/sleep mock fixtures only; unsupported provider shapes are not guessed.
- [x] ~~Manual check-ins can be saved, reviewed, edited and deleted, including older
  entries beyond the Today preview and entries when there is no supported finding.~~
- [x] ~~Saved report time is distinguished from historical event/exposure timing;
  editing preserves report time and caffeine coverage remains explicitly separate.~~
  Native mood edit/restart retains report time; caffeine form labels were inspected,
  but complete native caffeine time-picker entry/save/restart is not certified here.
- [x] ~~Collection history reflects retained/deleted records and receipts, with source
  freshness and coverage distinguishable from model findings.~~
- [x] ~~Mocked retry, duplicate import, pause, resume, disconnect/revocation and deletion
  regression cases prevent unauthorized late replies and check truthful status.~~
  These are mocked service/race tests and an encrypted service lifecycle, not the
  entire native source-action UI with a successful provider request.
- [x] ~~Encrypted Android persistence survives reopen/restart in the disposable copy;
  isolated reset/deletion removes the intended records without cross-store leakage.~~
  SQLCipher close/reopen is automated; OS force-stop/reopen is separately checked
  for native manual data, not successful health-import recovery or crash injection.
- [x] ~~Real production bootstrap reaches the intended screens and persists/reopens
  data. Any test-only input substitution or untested real keyboard behavior is named.~~
  Automated suites use scoped fixture TestTextInput. A separate normal-main smoke
  uses native Android key events with no TestTextInput; it is not a physical keyboard
  or gesture/prediction test.
- [x] ~~Sparse or health-only evidence yields an honest no-finding/insufficient-data
  state; it does not fabricate meetings, recurring events or causal relationships.~~
- [x] ~~Held/unavailable model, stale-cache and fallback paths are clearly distinguishable
  from an accepted generated answer; a held candidate cannot be activated by cache.~~
  Hold/cache behavior is host/native unit evidence, not an inferred model response.
- [x] ~~Known collection regressions are fixed and rechecked; unresolved issues and
  explicitly untested cases are listed.~~

This is bounded acceptance of the tested collection prototype, not proof that the
emulator has no possible issues. Complete native health-import/source-action and
caffeine-picker flows, health-import cold-start recovery, crash injection, accessibility
and different Android versions remain untested in this pass. Real endpoint/account
and physical-device checks are deferred separately.

Use the disposable-emulator and production-bootstrap procedures in the
[runbook](first-person-phone-runbook.md). Mocked integration verifies app behavior,
not the real provider endpoint, live credentials or real user data coverage.

## B. Model-enabled prototype acceptance — open

The latest prompt-v8 synthetic fixture produced schema-valid output, but manual
review rejected instruction echo and incorrect interpretation of evidence gates.
Normal builds hold LoRA; grounded deterministic fallback is a safety behavior,
not evidence that this model works. Do not declare the full model-enabled prototype
complete solely because section A or fallback checks pass.

- [ ] Diagnose the known instruction-echo and gate-meaning failures with retained
  inputs/outputs and controlled comparisons before deciding on retraining.
- [x] ~~Predeclare representative intent/evidence cases and semantic criteria before
  additional generation: exact quantities and references, correct gate interpretation,
  meaningful uncertainty, useful readable prose and no unsupported causal/medical claim.~~
  [Five families × three intents](emulator-semantic-cases-v1.md) are specified;
  none of the 15 model calls has run.
- [x] ~~Freeze the 15 actual raw-pipeline requests, both production rendered
  prompts and LoRA grammars with distinct byte/content hashes and version metadata.~~
  [Sealed inspected-development package](../../experiments/readiness/emulator-semantic-v1/README.md):
  30 prompts, five scenario clusters, zero model attempts. This is preparation,
  not model acceptance; native tokenization/context fit/grammar execution remain open.
- [ ] Verify the selected artifact and exact app prompt/projection/guard versions;
  evaluate uncached generated answers separately from deterministic fallback.
- [ ] Retain complete fixture-only outputs and manually review meaning, not just
  schema/keyword acceptance; record failed cases and the limits of the test set.
- [ ] Verify completion/cancellation/error recovery in the emulator. Record emulator
  timings and memory only as emulator observations, not Nothing Phone estimates.
- [ ] Activate only a candidate that meets the declared semantic acceptance criteria;
  retain a fail-safe hold and rollback when those criteria are not met.

This checklist does not authorize new paid training, cloud deployment, downloads,
owner-data access or unlimited repeated model calls. Any additional run must have
a bounded, explicit purpose and preserve the prior run's record.

## Evidence before this verification pass

Prior local verification: **325 Flutter tests, 110 Python tests, 63 native tests
per variant (LoRA/vanilla)**. These are historical executed totals, not new results.
Prior disposable aggregate: 27 checks. Prior actual-production bootstrap: one
check, with a documented test-injected/real-IME interaction and scoped mock text
input. Existing reports remain unchanged.

Current known semantic result: the single prompt-v8 fixture completed in
72.738 seconds, passed schema validation and failed manual review; the app
delivered fallback. Model-free guard-v7 replay repaired a word-decimal false
positive without changing that manual rejection or performing another inference.

## Current emulator-first follow-up

The final October 6 full host gate passes **347 Flutter tests**, clean analysis and unchanged
formatting across 119 files. The final API-34 aggregate executes **37/37** with no
skips (11-second body, 23.151 seconds total); strengthened production bootstrap separately passes
**1/1** (8-second body, 19.715 seconds total). These are separate suite denominators,
not independent users, episodes or model answers. Python/native results above were
not rerun for this follow-up.

Five actual raw-pipeline goldens check positive/negative supported, scarce-complete,
unknown-caffeine and mixed-direction families across three fallback intents. Four
widget tests cover sign-correct Today/Fingerprint/Evidence/Weekly rendering and
neutral Developing history. A zero-difference supported widget is defensive rendering,
not a promoted analytical zero. Fallback v6 removes the misuse of `positive_count`
as agreement; a cache regression preserves older rows without serving their prose.
Both AppState backup and shared fallback use comparison count and signed median.
These checks do not establish individualized explanations for every possible failed
gate or prove any LLM is repaired.

The new mocked encrypted lifecycle imports one HR sample and two sleep intervals,
checks duplicates, paused refusal, explicit resume without keyless import, an empty
day and source deletion that retains a manual report. Native normal-main smoke
separately checks offline keyboard create/edit, exact text, original report time,
OS force-stop/reopen, deletion and truthful ledger counters. Two singular count labels
discovered there were fixed and rechecked. Final build/teardown evidence is recorded
in the [local report package](../../experiments/readiness/first-person-local-v1/README.md).
Prior reports and APKs remain unchanged; no owner data, real API, model generation,
model download, new training or cloud provisioning occurred in this follow-up.

A later native check exposed stale Manual source status/counts after a save and
incorrect `Disconnected` on reopen despite one retained report. Both failures remain
recorded. Manual save/delete now update source metadata in the same transaction;
manual connected-family read repair derives data/empty from retained counts without
altering operational states. AppState refreshes Sources after commit and before
analytics. Six host regressions cover legacy status, save/edit/delete with/without
analysis failure, failed persistence and late metadata-failure rollback. Final
source-fix emulator evidence is separate from the earlier 37-check/normal APK stage
(23.550-second label aggregate/20.581-second original bootstrap, followed by
25.085-second status aggregate/19.815-second status bootstrap). The
[host verification](../../experiments/readiness/first-person-local-v1/emulator-prototype-host-verification-20261006.json)
preserves exact source hashes and regression history; the report index links native
build/smoke/teardown evidence separately.
Two additional production-projection tests ensure Live does not inherit Snapshot
timestamps, completeness or status details. Fresh source last sync stays absent
until persisted local write/import metadata exists; source count is not completeness.
The [final native/build/teardown report](../../experiments/readiness/first-person-local-v1/emulator-prototype-acceptance-20261006.json)
verifies fresh zero/no-sync → native save one → OS reopen one → delete zero with
consistent source state on the final normal build. Native editing is earlier-build
evidence; current production bootstrap checks editing with scoped fixture typing.
Only the owned disposable emulator was stopped; original AVDs/phone remain untouched.

## Deferred and excluded claims

- Physical-device install, real keyboard, performance, memory suitability, battery
  and heat remain in [FIRST-PERSON-MILESTONE.md](FIRST-PERSON-MILESTONE.md).
- Live Ultrahuman endpoint/account verification and owner-data continuity are not
  established by fixtures. They require separate consent and private-data handling.
- Broader longitudinal health/context correlation, independent generalization,
  clinical efficacy, causal identification and public readiness are not established
  by this prototype. The current analytical focus is meeting/heart-rate evidence;
  manual collection alone does not create a validated general-purpose correlation engine.

After collection and model-enabled emulator gates, move to the deferred physical
phase, then review naturally collected data before choosing another iteration.
