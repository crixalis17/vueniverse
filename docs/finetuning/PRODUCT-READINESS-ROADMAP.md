# Vueniverse: prototype to a real-user pilot

Updated: 2026-09-25. Owner: Rakesh. Status: implementation started.

## Objective and scope

Deliver a small consented Android pilot of recurring-meeting / heart-rate analysis,
manual context, and understandable evidence explanations. Retain LoRA BF16 v7 as
the research candidate. The first milestone is dependable analytical evidence and
phone feasibility; further training follows measured errors. Expand to the other
six synthetic context families only after the first live workflow is validated.

Cloud resources remain stopped during local implementation. Any later training,
deployment, distribution, or participant-data collection needs a concrete execution
plan and the appropriate authorization. Existing experiment artifacts remain frozen.

Estimates below are engineering effort, not promises; hardware access, provider
eligibility, and longitudinal observations can extend calendar time.

## Phase 1 — Analytical correctness (3–5 working days)

- [x] ~~P1.1 Prevent all known calendar events from contaminating matched controls,
  even when only a selected event subset is analyzed. Reproduce with regression tests.~~
  Completed 2026-09-25; all five new control-selection tests pass.
- [x] ~~P1.2 Replace `no_dominant_measured_alternative: true` with an explicit,
  evidence-backed influence policy. Represent unmeasured/unknown context honestly;
  absence of a log is not proof of no exposure. Version the policy and audit fixtures.~~
  Completed 2026-09-25 as a deliberately narrow caffeine screen for both sides of
  each comparison, with reported-zero/exposure/unknown states. Analysis/promotion
  versions 3/2; specification in repository `docs/finetuning/caffeine-context-policy.md`.
- [x] ~~P1.2a Add structured caffeine intake/coverage capture to the check-in form and
  save/edit/reload flow. Legacy free text or unscoped zero cannot satisfy the new gate.
  Validate complete-window reporting without automatically assuming zero intake.~~
  Implemented 2026-09-26 with explicit servings and local start/end pickers, UTC
  persistence, shared form/repository validation and save-failure handling.
- [ ] P1.3 Audit illness, travel, caffeine, workouts and coverage on BOTH event and
  control windows. Verify time zones, recovery buffers, overlapping events and
  stable event identity. Do not pool different recurring people/events by category.
  Partial 2026-09-26: shared recorded illness/travel/manual-exercise day screening
  and timed-workout overlap/30-minute recovery screening now apply to both sides.
  Analysis version 4. Stable recurring identity, DST handling, missing-context
  coverage and order-sensitive control allocation remain open; do not mark complete.
  Progress 2026-10-03: analysis version 5 groups by private recurring-series key,
  selects one cohort without effect-based ranking and rejects ambiguous mixed-series
  requests. Missing identities cannot contribute usable occurrences. Recurrence
  normalization stability verified. DST, context coverage, allocation sensitivity
  and future-provider identity lifecycle remain open.
- [ ] P1.4 Verify all analysis-version changes invalidate existing evidence and
  dependent explanations, experiments and exports before reuse.
- [ ] P1.5 Test null and adversarial timelines; document thresholds as heuristics.
  Define uncertainty estimates and how many-pattern searches will control false
  discoveries. Validate on future observations before promoting confidence.

Exit: known wrong-control cases fail safely; no unconditional confidence gate;
analytical policy documented and targeted/integration regressions passing.

## Phase 2 — Independent evaluation (3–5 working days)

- [ ] P2.1 Freeze an evaluation contract before creating new cases. Historical v7
  results remain development benchmarks because repeated inspection guided choices.
- [ ] P2.2 Generate raw timelines and run the real analytics/projection code to make
  model inputs. Include sparse measurements, competing influences, missing logs,
  unfamiliar phrasing and timing; independently review expected analytical outcomes.
- [ ] P2.3 Split by person/pattern/template/time as appropriate, audit leakage, and
  create a fresh final set that is not used for label or hyperparameter changes.
- [ ] P2.4 Compare deterministic explanations, vanilla, retained LoRA and the exact
  quantized release candidate under recorded equivalent input/output contracts.
- [ ] P2.5 Independently human-review critical cases with a blinded rubric. Report
  disagreement, raw versus fallback results, state errors and uncertainty. Document
  that earlier semantic judgments came from one assistant evaluator.
- [ ] P2.6 Set release criteria before running the fresh final evaluation. A guard
  pass is not a semantic safety judgment; include paraphrases and false positives.

Exit: fresh benchmark and adjudicated errors justify the selected runtime. Retrain
only if targeted evidence indicates that model learning is the appropriate fix.

## Phase 3 — Android LoRA integration and hardware (3–5 days with a phone)

- [ ] P3.1 Add a versioned artifact manifest for the archived selected LoRA Q4
  model (hash `dd9c2a212672a5bb18affbc344a4c0fcf4e9000b3b5155d6fdfe9a8104bad234`).
  Android currently pins the older vanilla hash; preserve rollback and update
  model identity, prompt/guard compatibility and cache invalidation together.
- [ ] P3.2 Test verified/resumable delivery, corrupted downloads, storage shortage,
  cancellation and startup failure using the real artifact.
- [ ] P3.3 Run MG-12 on physical ARM64 hardware: cold/warm p50/p95, RAM, battery,
  thermals, ten repeated calls, cancellation and OOM. Existing initial targets:
  warm p95 <=8 seconds, incremental RSS <=3.5 GB, raw schema validity >=95%,
  no crash/OOM or severe thermal state. Document supported device requirements.
- [ ] P3.4 Run the full semantic benchmark plus safety cases through the actual
  Android runtime; record quality changes from quantization and decoding.

Exit: one complete real-phone workflow passes. L4 latency is never substituted
for phone performance. No permanent hosted model server is required by this plan.

## Phase 4 — Pilot release preparation (3–5 working days)

- [ ] P4.1 Verify the full Live path from supported wearable/Health Connect data and
  Calendar to evidence. Ultrahuman calibration access alone is not live-app integration.
- [ ] P4.2 Verify permissions, encryption/key lifecycle, source deletion, revocation,
  cache invalidation and exports on physical hardware. Inspect logs for private data.
- [ ] P4.3 Complete model distribution notices/terms, privacy disclosures, applicable
  app-store health declarations and permission requirements for the chosen channels.
- [ ] P4.4 Add clear insufficient-data onboarding, source freshness, explanation
  provenance and a way to report misleading findings. Define updates and rollback.
- [ ] P4.5 Obtain appropriate consent for a small pilot; choose recruitment scope
  and success criteria before collection. Do not infer permission to upload health data.

Exit: a reviewable pilot build, distribution package and support/rollback procedure.

## Phase 5 — Longitudinal pilot (at least 2–4 weeks of observation)

- [ ] P5.1 Measure usable evidence coverage, time to first useful finding, false or
  misleading findings, comprehension, fallback rate, crashes and repeat usage.
- [ ] P5.2 Review findings with participants, including null and contradictory cases;
  collect only consented information needed for evaluation.
- [ ] P5.3 Evaluate prospective personal experiments with adherence and alternative
  explanations recorded. Before/after changes alone do not establish causation.
- [ ] P5.4 Decide whether to expand, revise, or stop based on documented outcomes.

## Later expansion — one family at a time

Add journals/food, screen time, music, calls and gaming only after checking data
access feasibility. Build stable local identity mappings (separate event occurrences
from recurring identities), source connectors, analytical policies and complete
tests for each. Call-log permission eligibility and third-party API access are
external constraints. Specific contact/song analysis changes the original broad-
category privacy design and must be reflected in consent and data handling.

## Resume evidence

Already defensible: prototype architecture; LoRA/QLoRA experiments; 210-case synthetic
benchmark; guard/fallback design; Q4 conversion; reproducible artifacts. Label the
41.9% -> 76.9% result as rubric-weighted usefulness, not medical accuracy. Add phone
performance, user outcomes and production claims only after their respective gates.

## Execution journal

### 2026-09-25 — Session 1

- Inspected analytics, existing tests, versioning and current Android artifact identity.
- Confirmed the control selector receives only the analyzed subset of one-to-one
  events. Other known calendar events can therefore contaminate control windows.
- Added regression cases for all three calendar categories, no-clean-control
  fallback, and a non-overlapping event boundary. Four failed before the repair;
  all five pass after passing the complete calendar context to control selection.
- Bumped meeting analysis version to 2 and made `runPending` detect analysis/promotion
  version mismatches. Verified replacement and stale marking of legacy evidence
  without a source edit, plus idempotent reuse on the next refresh. Full dependent-
  artifact invalidation and every direct-read path remain part of P1.4.
- Final verification: 15 targeted regression/integration tests passed; Flutter
  analysis reports no issues. Historical demo measurements remained unchanged.
- The first upgrade-test fixture incorrectly reused current-version IDs while
  changing version metadata; corrected it to seed distinct legacy records. No
  production identity logic was changed to accommodate the test.
- Existing unrelated repository changes are preserved. No cloud compute started.
- Next: P1.2 influence-policy design and tests, followed by symmetric control/event
  screening. No new model-quality or real-user readiness claim follows from this fix.

### 2026-09-25 — Session 2

- Completed P1.2. Removed the unconditional gate and preserved structured caffeine
  amount/coverage in the analytical input. Screened both event and control periods.
- Recorded unknown and exposure counts independently; counted unresolved pairs once.
  Added check-in dependencies and advanced analysis/promotion versions to 3/2.
- Demo's main comparison is now developing with unchanged raw measurements and
  +11 BPM median difference. Updated explanation, UI labels and expected fixture
  state rather than inventing missing zero-intake reports.
- Twelve new policy tests and affected integration checks pass. Final full Flutter
  suite: 108 passed. `flutter analyze --no-pub`: no issues.
- Added explicit pilot blocker P1.2a: users need a structured coverage form. Full
  screening of other influences and artifact invalidation remain open. Archived v7
  training/evaluation artifacts and cloud resources were not modified.
- Next: P1.2a, then the remaining symmetric screening in P1.3.

### 2026-09-26 — Session 3

- Completed structured caffeine entry, editing and reload through UI/state/repository
  mapping. Blank remains unknown; zero is explicit; period boundaries require
  completed coverage. New coverage reports use the current report timestamp.
- Added validation for nonfinite/negative amounts, missing endpoints, missing amounts
  for scoped reports, reversed periods, and future coverage. Times persist in UTC.
- Saving now waits for persistence and leaves the form open on failure without adding
  an unsaved entry to state. Imported demo edits replace the old source identity
  atomically; deletion resolves the record's actual source rather than assuming it.
- End-to-end test verifies stored zero reports can pass the narrow caffeine gate,
  a positive edit blocks it, and imported record edits do not create duplicates.
- Added form tests for zero editing/coverage preservation, invalid input and storage
  failure, and repository round-trip/timezone tests. Full suite: 114 tests passed.
- No cloud operations or model retraining. P1.3 (other influences and stable recurring
  identities) and P1.4 (all dependent artifacts/read paths) remain open.
