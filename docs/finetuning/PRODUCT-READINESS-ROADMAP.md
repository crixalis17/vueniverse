# Vueniverse: prototype to a real-user pilot

Updated: 2026-10-06. Owner: Rakesh. Status: tested emulator collection paths verified; model-enabled prototype gate open; ultimate physical-phone phase deferred.

## Objective and scope

Immediate agreed milestone: an emulator-verified prototype with collection-first
onboarding, Ultrahuman-shaped imports, manual check-ins and a local receipt ledger.
See EMULATOR-PROTOTYPE-MILESTONE.md for separate collection and model-semantic gates.
Fixture imports do not verify the real provider endpoint. Useful model outputs are
still required before claiming a working model-enabled prototype; fallback is not
a LoRA pass. No known failure is waived by replacing hardware with an emulator.
The owner's Nothing Phone 2 (8 GB), live Ultrahuman and manual-only physical phase
remain in FIRST-PERSON-MILESTONE.md, deferred rather than removed. Calendar is not
required; an honest insufficient-data state is appropriate until an analytical
policy supports the collected contexts. Emulator acceptance does not prove real
phone performance, longitudinal correlations or public readiness.

Current local record: 357 Flutter tests, clean static analysis and complete Python
suite128 tests including frozen-package/capture integrity. Host-only Android JVM
checks pass68 per variant in J-096; replay follow-up is recorded in J-097.
Earlier emulator evidence includes 27 integration checks and a separate actual-main
encrypted collection journey. The latest actual-main bootstrap also passed on a
separate disposable emulator with scoped fixture typing; physical-keyboard
acceptance remains pending. Source commit acknowledgements are separate from
analysis refresh failures, with safe retry and removal of stale views. Ultrahuman remains
session-key only; no owner API import or physical-phone verification occurred.
The retained LoRA model is byte-verified. Native lifetime repair, trained-schema
alignment and bounded grammar produced 3/3 schema-valid intent outputs, but only
one automated guard pass, and manual review rejected that answer's “zero” versus
`0.75` contradiction. The other two model texts were rejected and not retained
for semantic scoring. Normal builds now hold candidate inference/cache reuse;
fixture-only debug evaluation remains separate. No retraining occurred.
Offline diagnosis identified developing-state coverage drift and dropped gate/exclusion
meaning. Phone contract v8 preserves those facts; guard v7 rejects finite recognized numeric
role contradictions and prevents old-guard cache reuse. A full saved-check-in list is
now accessible without a finding. These changes do not establish semantic approval;
the single prompt-v8 fixture completed in 72.738 seconds but failed manual review
for instruction echo and incorrect gate meaning. It delivered a grounded fallback,
not an accepted LoRA answer. Guard-v7 retained-output replay removes only a numeric
false positive without another model call; historical as-run records are unchanged.
See android-semantic-contract-audit-v1.md for the outcome and next development gates.
The emulator-first follow-up corrects negative-direction UI/fallback narratives,
positive-count mislabeling, the pre-event window description and Developing history.
Five raw-pipeline analytical goldens cover positive, negative, scarce-complete,
context-blocked and contradictory evidence across three intents. Deterministic
fallback v6 and its cache-version regression preserve historical v5 rows without
reusing incorrect prose. These are host/app checks, not new model generations.
Current-source API-34 aggregate passes 37/37 without skips; actual-main bootstrap
separately passes 1/1. Normal-main native key-event smoke checks manual save/edit,
original report time, force-stop/reopen, deletion and ledger. Mocked encrypted HR/sleep
service lifecycle is not full successful-import UI or health-import cold-start proof.
See EMULATOR-PROTOTYPE-MILESTONE.md for bounded scope and remaining emulator checks.
Five analytical families × three intents are predeclared in emulator-semantic-cases-v1.md;
their exact app inputs and both production prompts are now frozen and hash-verified
in experiments/readiness/emulator-semantic-v1. LoRA GBNF/prefill and copied artifact
identities are retained; native tokenization/context fit/grammar execution remain
unverified. Vanilla v5 mislabels positive_count unlike LoRA v8; preserve that
confound rather than claiming a controlled adapter-only comparison.
The subsequent bounded LoRA replay stops afterone captured, manually failed
instruction-echo answer in66.169s;14 are unattempted, not retried. Host/native
tokenization both1606, native EOS237tokens, no timeout/cap. See the separate
emulator-semantic-run-20261006-v1 outcome, not the immutable freeze's pending slots.
Lexical clinical flags were negated copied instructions, not affirmative advice;
manual safety2 does not rescue grounding0/usefulness0. Candidate approval remains
open; the disposable emulator is stopped. Next smallest correction is a separately
frozen training-aligned prompt, before any paid dataset/rank iteration.
Native manual-source status/count mismatch was reproduced and fixed: transactional
local metadata updates, connected-family legacy read repair limited to manual source,
and Sources refresh before analysis. Six host regressions include late-metadata
save/delete rollback without lost data, receipts or recompute work.
Two production-projection regressions also remove Snapshot freshness/completeness
from Live metadata; fresh sources have no last sync until a real local write/import.
Reviewed code and synthetic reports may be published publicly; private health,
credentials and weights remain excluded. See the local acceptance record and
FIRST-PERSON-MILESTONE.md; none of these checks completes the actual-phone gate.

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
  Progress 2026-10-03: version 6 uses global maximum-cardinality/minimum-cost
  unique-control assignment, rejects conflicting shifted baselines and mixed-offset
  measurements, and enforces half-open sub-minute sample boundaries. Read-only
  freshness gates cover projections, replay, cached/post-inference delivery,
  experiment use and export sharing. Historical records remain retained.
  Reminder cancellation, IANA/DST reconstruction, missing-context coverage and
  provider identity lifecycle remain open; see control-and-freshness-policy-v6.md.
  Analysis v7 adds exact-end recovery slots and supported-only intervention gating.
  Reminder reconciliation now cancels unavailable protocol alarms without deleting
  history; OS delivery while the app is inactive remains an actual-device gate.
- [ ] P1.5 Test null and adversarial timelines; document thresholds as heuristics.
  Define uncertainty estimates and how many-pattern searches will control false
  discoveries. Validate on future observations before promoting confidence.
  Progress 2026-10-03: null/adversarial pipeline regressions, exhaustive-reference
  matching checks, exact paired sign-test and Holm utilities added. Statistical
  utilities are research diagnostics only, not connected to promotion. Independent
  future observations, dependence-aware effect intervals and multiplicity scope
  remain open.

Exit: known wrong-control cases fail safely; no unconditional confidence gate;
analytical policy documented and targeted/integration regressions passing.

## Phase 2 — Independent evaluation (3–5 working days)

- [x] ~~P2.1 Freeze an evaluation contract before creating new cases. Historical v7
  results remain development benchmarks because repeated inspection guided choices.~~
  Completed 2026-10-03: readiness-evaluation-contract-v1.md frozen before generation.
- [ ] P2.2 Generate raw timelines and run the real analytics/projection code to make
  model inputs. Include sparse measurements, competing influences, missing logs,
  unfamiliar phrasing and timing; independently review expected analytical outcomes.
  Partial 2026-10-03: 30 development cases across ten timeline clusters pass through
  the real normalizer/database/analytics/projection; all deterministic guard checks
  pass. Raw inputs, request hashes and blank review forms are preserved. Independent
  analytical adjudication and unfamiliar phrasing coverage remain open.
- [ ] P2.3 Split by person/pattern/template/time as appropriate, audit leakage, and
  create a fresh final set that is not used for label or hyperparameter changes.
  Partial: package integrity/cluster split checks implemented. Semantic training
  overlap audit, external final-set custody and a fresh final benchmark remain open.
- [ ] P2.4 Compare deterministic explanations, vanilla, retained LoRA and the exact
  quantized release candidate under recorded equivalent input/output contracts.
- [ ] P2.5 Independently human-review critical cases with a blinded rubric. Report
  disagreement, raw versus fallback results, state errors and uncertainty. Document
  that earlier semantic judgments came from one assistant evaluator.
- [x] ~~P2.6 Set release criteria before running the fresh final evaluation. A guard
  pass is not a semantic safety judgment; include paraphrases and false positives.~~
  Completed 2026-10-03: proposed pilot criteria predeclared in the contract. Meeting
  those thresholds, independent review and actual phone measurements remain open.

Exit: fresh benchmark and adjudicated errors justify the selected runtime. Retrain
only if targeted evidence indicates that model learning is the appropriate fix.

## Phase 3 — Android LoRA integration and hardware (3–5 days with a phone)

- [ ] P3.1 Add a versioned artifact manifest for the archived selected LoRA Q4
  model (hash `dd9c2a212672a5bb18affbc344a4c0fcf4e9000b3b5155d6fdfe9a8104bad234`).
  Android currently pins the older vanilla hash; preserve rollback and update
  model identity, prompt/guard compatibility and cache invalidation together.
  Implementation prepared: versioned candidate manifest, explicit lora-v7 variant,
  distinct file/revision, obsolete-download isolation and model-aware cache checks.
  Default vanilla rollback is retained. Byte validation does not authorize the
  held candidate; current readiness is checked before cached-answer reuse.
  Actual semantic/artifact/phone acceptance is pending.
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
