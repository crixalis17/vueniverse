# Vueniverse — Complete Android UI/UX Plan

## 1. Authority, Product Direction, and Scope

### Source-of-truth model

`health-os-plan.html` is the ground-truth product plan. It defines:

- What Vueniverse is.
- The core evidence-before-language architecture.
- Product terminology and safety language.
- Navigation and journeys.
- Source consent and privacy behavior.
- MedGemma’s role.
- Live, Demo, Preview, and Coming later semantics.
- The broader Health OS vision.

`health-os-engineering-plan.html` translates that product plan into:

- Runtime architecture.
- Data contracts.
- Persistence and provenance.
- Source-adapter behavior.
- Analytical gates.
- Model boundaries.
- Testing and acceptance requirements.

`health-os-winning-addendum.html` is an implementation and delivery override. It changes specific decisions:

- Build deeply for Android first.
- Implement every differentiated product feature rather than leaving it as a static preview.
- Use a focused operational source set.
- Keep iOS and difficult connectors as expansion work.
- Unite every feature through one versioned evidence lifecycle.
- Make Moment Fingerprint and Test This the primary differentiators.

Where the addendum explicitly conflicts with the product or engineering plan, the addendum wins. Everywhere else, `health-os-plan.html` remains authoritative.

### Final product direction

Vueniverse is a private personal-science engine:

**Observe → Fingerprint → Challenge → Explain → Test → Learn → Prove**

It is not:

- A generic wearable dashboard.
- A list of correlations.
- An unrestricted health chatbot.
- A diagnostic device.
- A single opaque wellness score.
- A catalogue of disconnected experiments and future concepts.

The complete experience must:

- Align health with repeated life events.
- Compare those events against matched personal controls.
- Show supporting signals, contradictions, exclusions, missingness, and null findings.
- Use bounded MedGemma only after deterministic evidence exists.
- Let the user test a reversible change.
- Update the original evidence from the measured result.
- Preserve a versioned Evidence Ledger.

### Platform and source scope

Operational platform:

- Android.
- Flutter owns all product UI and shared state.
- Kotlin owns Health Connect, Calendar Provider, permissions, secure keys, and Android scheduling.
- iOS remains an expansion platform behind the same interfaces.

Initial operational sources:

- Health Connect.
- Android Calendar.
- Manual Check-ins.
- Multimodal Journal.
- Demo Data.

Expansion sources:

- Device activity and call timing.
- Spotify.
- Strava.
- Coarse Discord/WhatsApp activity.
- Direct wearable/ring APIs.
- Smart Environment.
- FHIR/clinical records.
- iOS HealthKit/EventKit.

Expansion sources must never appear connected before their adapter passes the full source-compliance gate.

### Product-state labels

Use persistent, user-visible state labels:

- **LIVE** — real connected Android data.
- **DEMO** — fictional deterministic data.
- **LOCAL** — on-device operation.
- **FALLBACK** — deterministic model fallback.
- **LIMITED** — partial permission or missing signals.
- **PAUSED** — source is retained but not syncing.
- **STALE** — dependent evidence is outdated.
- **EXPERIMENTAL** — bounded scenario or model capability with explicit limitations.
- **EXPANSION** — adapter or platform is not operational.

Demo and live data remain separate. Demo Data may exercise implemented product features whose live expansion source is unavailable, but the DEMO label must remain visible.

## 2. Design System and Information Architecture

### Visual direction

Retain the Ultrahuman-inspired design direction while preserving Vueniverse’s identity:

- Near-black canvas.
- Graphite metric surfaces.
- Large tabular values.
- Segmented evidence and progress rings.
- Thin luminous charts.
- Lime, cyan, violet, coral, amber, and blue signals.
- Smooth reveal, pulse, scan, and trace motion.
- Dense but ordered health information.
- Floating dark navigation.

Do not copy third-party branding, artwork, copy, layouts, or proprietary score names.

Vueniverse rings represent factual values:

- Repeats.
- Completeness.
- Matched controls.
- Signal agreement.
- Source progress.
- Experiment progress.
- Model readiness.

They never represent an opaque health, stress, recovery, or safety score.

### Color tokens

Surfaces:

- Canvas: `#050707`
- Raised canvas: `#090C0B`
- Primary surface: `#101413`
- Secondary surface: `#161B19`
- Elevated surface: `#1C2220`
- Border: `#252B29`

Text:

- Primary: `#F4F7F4`
- Secondary: `#A6AFAA`
- Tertiary: `#747D78`
- Disabled: `#515854`

Signals:

- Verified: `#C7FF3F`
- Baseline: `#55D8FF`
- Recovery: `#5AF0BA`
- Context: `#9B7BFF`
- Measured effect: `#FF725E`
- Uncertainty: `#FFB547`
- Null/weakened: `#6F8CFF`
- Destructive/rejected: `#FF5D5D`

Never communicate state through color alone.

### Typography

- Hero metric: 56/60, tabular.
- Major progress: 44/48, tabular.
- Screen title: 28/34, semibold.
- Section title: 20/26, semibold.
- Card title: 17/22, semibold.
- Body: 15/22.
- Supporting: 13/19.
- Metric/state label: 11/14, uppercase, tracked.

Use system typography. Do not add remote fonts.

### Core UI components

- `EvidencePulseRing`
- `MomentFingerprintChart`
- `EvidenceHeroCard`
- `MetricStrip`
- `SignalAgreementMatrix`
- `InfluenceRow`
- `CounterEvidenceCard`
- `LifecycleRail`
- `EvidenceChip`
- `SourceConnectionCard`
- `ExperimentProgressRing`
- `ModelRuntimeBadge`
- `ProofHashRow`

### Motion

- Ring reveal: 650 ms, once on entry.
- Chart trace: baseline, repeated traces, then median.
- Metric transition: 280–360 ms.
- Source connection: scan ring followed by stable state ring.
- Evidence update: old result dims before the new version appears.
- Model processing: “Checking evidence,” not simulated thinking.
- Reduced motion replaces drawing and pulse with fades.

### Primary navigation

Use the product plan’s five destinations:

1. **Today**
2. **Timeline**
3. **Insights**
4. **Sources**
5. **More**

Destination ownership:

- Today: current insight, Fingerprint, experiment, readiness, digest.
- Timeline: Private Context Mapper, Replay, events, Bodyprint Library.
- Insights: lifecycle, challenge, Ask Vueniverse, Test This, What-if.
- Sources: consent, sync, minimization, pause, revoke, deletion.
- More: Evidence Ledger, Body Model, Digest, Quiet Intelligence, exports, analysis packs, model registry, privacy, proof.

### Key routes

- Onboarding and source setup.
- Today.
- Timeline, event detail, Fingerprint, and Replay.
- Insight detail and evidence challenge.
- Ask Vueniverse.
- Test This protocol, check-in, and result.
- Journal capture and review.
- Sources and consent.
- Evidence Ledger.
- Body Model.
- Weekly Digest.
- What-if Lab.
- Quiet Intelligence.
- Analysis Packs.
- Clinician Export.
- Privacy and Proof Mode.

## 3. Complete Product Journeys

### Onboarding

#### Welcome

Present:

- “Find the moments your body remembers.”
- Local and private.
- Evidence before explanation.
- Personal experiments, not medical advice.

Actions:

- Set up with my data.
- Explore Demo Data.

#### Privacy explanation

Visualize:

1. Sources.
2. Sanitized local timeline.
3. Deterministic evidence.
4. Bounded MedGemma.
5. Verified UI.

Explain:

- Personal records stay local.
- Calendar identity/content is discarded after categorization.
- GPT-5.6 is build-time only.
- No diagnosis, prescription, or clinical alerting is provided.

#### Scenario selection

Offer reusable scenario templates:

- Meetings.
- Shifts/on-call.
- Classes/exams.
- Performances/interviews.
- Workouts.
- Travel.
- Caregiving.
- Everyday routines.
- Creative/gaming sessions.
- Recurring wellness symptoms.

The selection configures relevant source and check-in suggestions. It does not generate a conclusion.

#### Mode selection

- LIVE AND LOCAL.
- DEMO DATA.

Demo must state:

- Fictional 30-day history.
- Separate storage.
- Never mixed with live data.
- Resettable.

#### Source setup

Operational cards:

- Health Connect.
- Android Calendar.
- Manual Check-ins.
- Multimodal Journal.
- Demo Data.

Each source explains:

- Why it helps.
- Fields retained.
- Fields discarded.
- Analysis packs unlocked.
- Permission state.

#### Initial synchronization

Show:

- Access.
- Read.
- Sanitize.
- Normalize.
- Deduplicate.
- Encrypt.
- Build event windows.
- Prepare evidence.

Support partial, denied, empty, interrupted, and retry states.

### Today

Header:

- Date selector.
- LIVE/DEMO.
- Last sync.
- Model/fallback state.
- Privacy and profile.

Primary Moment:

- “Your heart rate was usually higher before your recurring 1:1.”
- `+8–12 bpm`
- `6 of 8 meetings`
- Matched-control count.
- Recovery duration.
- Lifecycle.
- Caffeine unresolved.

Actions:

- Fingerprint.
- Challenge.
- Ask.
- Test This.

Supporting cards:

- Sleep, resting HR, HRV, activity, completeness.
- Active experiment.
- Check-in request.
- Weekly Digest.
- Null finding.
- Source/runtime readiness.

### Private Context Mapper and Timeline

Views:

- Day.
- Week.
- Context Map.
- Fingerprints.
- Experiment overlay.

Events:

- Sleep.
- HR/HRV.
- Activity/workout.
- Calendar category.
- Manual context.
- Journal fact.
- Experiment intervention/result.
- Missing-data interval.

Every event shows:

- Time/duration.
- Privacy-safe category.
- Source.
- Observed/derived/user-entered.
- Linked evidence.
- Exclusion state.

Event detail includes:

- Sanitized fields.
- Adapter and transform version.
- Consent receipt.
- Dedupe status.
- Evidence dependencies.
- Inclusion/exclusion reason.

### Moment Fingerprint

The Fingerprint is the signature experience.

Chart layers:

- Individual repeated traces.
- Repeated-event median.
- Matched personal baseline.
- Variability.
- Event start/end.
- Recovery duration.
- Missing gaps.
- Exclusions.
- Experiment before/after.

Summary:

- Repeats.
- Effect range.
- Matched controls.
- Consistency.
- Completeness.
- Recovery duration.

Actions:

- Challenge evidence.
- Ask Vueniverse.
- Test This.
- Open Replay.
- Open Evidence Ledger.

### Timeline Replay

- Scrub −30 minutes through +30 minutes.
- Snap to five-minute buckets.
- Compare event and baseline.
- Inspect individual occurrences.
- Show context annotations.
- Toggle experiment before/after.
- Preserve missing gaps and exclusions.
- Provide accessible text/table equivalents.
- Operate without MedGemma.

### Evidence Challenge

#### Signal Agreement

Signals include:

- HR.
- HRV.
- Activity.
- Sleep.
- Recovery duration.
- Pack-specific signals.

States:

- Supports.
- Contradicts.
- Missing.
- Excluded.
- Not required.

#### Influence Radar

Initial influences:

- Exercise.
- Caffeine.
- Illness.
- Travel.
- Sleep.
- Time of day.
- Meal timing.
- Missing data.

States:

- Observed.
- Absent.
- Unknown.
- Conflicting.

Users can add or correct context and recompute the evidence.

#### Counterevidence

Show:

- Events without the response.
- Controls with a similar response.
- Contradictory signals.
- Effects that disappear after exclusion.
- Missing contextual data.

#### Promotion gates

Expose:

- Minimum repeats.
- Consistency.
- Effect threshold.
- Completeness.
- Matched controls.
- Influence rules.

Candidate findings show progress rather than a model-written conclusion.

#### Null findings

Display:

- “No repeatable link yet.”
- Failed gate.
- Available data.
- Exclusions.
- Whether additional tracking is useful.

### Insight lifecycle

States:

1. Candidate.
2. Supported.
3. Testing.
4. Strengthened.
5. Weakened.
6. Unchanged.
7. Inconclusive.
8. Stale.
9. Expired.

Every transition records its evidence version, reason, sources, pack, experiment, and model version.

### MedGemma Explorer and Explainer

Explorer may select only reviewed investigations:

- Check matched controls.
- Check exercise.
- Check caffeine.
- Check Signal Agreement.
- Check recovery duration.
- Search for counterevidence.
- Compare experiment and baseline.

Explainer output:

- Observation.
- Supporting evidence.
- Counterevidence.
- Uncertainty.
- Low-risk next step.
- Evidence references.

The deterministic guard blocks:

- Unsupported numbers.
- Causality.
- Diagnosis.
- Prescription.
- Health verdict.
- Unsupported experiment.
- Missing uncertainty.

Rejected output falls back to a deterministic evidence summary.

### Ask Vueniverse

Ask Vueniverse is evidence-scoped.

Entry points:

- Fingerprint.
- Insight.
- Experiment result.
- Evidence Ledger version.

Scope panel:

- Evidence ID.
- Event.
- Time range.
- Repeats.
- Effect.
- Influences.
- Runtime/locality.

Starter questions:

- Could exercise explain this?
- What disagrees with this?
- How often did it happen?
- What is missing?
- What changed after the experiment?
- Why is it inconclusive?

Response structure:

- Direct answer.
- Supporting evidence.
- Counterevidence.
- Uncertainty.
- Optional next action.
- Evidence chips.

Sessions are ephemeral by default and remain local.

### Test This

Primary experiment:

- Observation: higher pre-meeting HR.
- Intervention: ten-minute quiet buffer.
- Events: next three recurring 1:1s.
- Outcome: pre-event HR and recovery duration.
- Comparison: matched events without the buffer.
- Context check-in: caffeine, exercise, illness, or none.

Builder steps:

1. Observation.
2. Hypothesis.
3. Intervention.
4. Outcome.
5. Event eligibility.
6. Schedule.
7. Adherence.
8. Analysis plan.
9. Review.

Active state:

- Progress.
- Next event.
- Reminder.
- Check-in.
- Completed/skipped/partial.
- Pause/stop.

Results:

- Strengthened.
- Weakened.
- Unchanged.
- Inconclusive.

The result creates:

- Updated Fingerprint.
- Updated Signal Agreement.
- New insight lifecycle state.
- New Evidence Ledger version.

### What-if Lab

- Starts from existing evidence.
- Keeps original result pinned.
- Allows bounded influence changes.
- Displays assumptions.
- Recomputes permitted observational estimates.
- Shows sample-size and completeness changes.
- Labels output OBSERVATIONAL SCENARIO.
- Can save or become a Test This protocol.
- Never appears measured or causal.

### Bodyprint Library and My Body Model

Consumer-facing name: **My Body Model**.

It is a versioned evidence library, not an unrestricted simulator.

Views:

- By moment.
- By signal.
- By influence.
- By experiment.
- Over time.

Contents:

- Fingerprint versions.
- Recovery-duration changes.
- Influences.
- Experiments.
- Confidence/completeness.
- Null findings.
- Stale/expired versions.

### Weekly Evidence Digest

Includes:

- Strongest new finding.
- Finding that weakened.
- Null result.
- Missing-data request.
- Experiment update.
- Source quality.
- Body Model changes.

Every statement links to the Evidence Ledger.

### Quiet Intelligence and Adaptive Presentation

May adapt:

- Timing.
- Concise/detailed presentation.
- Digest schedule.
- Allow-listed next action.

May not alter:

- Evidence.
- Thresholds.
- Claim level.
- Counterevidence.
- Uncertainty.
- Safety.

Users can inspect “Why was this shown?”, disable adaptation, reset it, and delete feedback.

### Evidence Ledger

Each entry includes:

- Evidence ID/version.
- Lifecycle.
- Sources.
- Counts.
- Effect/range.
- Exclusions.
- Missingness.
- Signal Agreement.
- Influences.
- Analysis-pack version.
- Model/runtime.
- Claim-guard result.
- Experiment relationship.
- Creation/invalidation time.

Users can compare versions and see exactly why a finding changed.

### Proof and Clinician Export

Proof export includes:

- Evidence.
- Sources.
- Counts.
- Exclusions.
- Completeness.
- Analysis version.
- Model/runtime.
- Safety result.
- Experiment.
- LIVE/DEMO label.

Clinician export supports:

1. Date range.
2. Fingerprints.
3. Insights/experiments.
4. Journal facts.
5. Provenance.
6. Redaction.
7. Preview.
8. Local document generation.
9. Android sharing.

It retains non-diagnostic language and uncertainty.

### Analysis Packs

Initial packs:

- Meeting → physiology.
- Late activity → sleep.

Every pack defines:

- Required/optional signals.
- Windows.
- Controls.
- Exclusions.
- Influences.
- Promotion gates.
- Safe language.
- Supported experiments.
- Evaluation.
- Version/rollback.

### Model registry and adaptation

Consumer UI shows:

- Active model.
- Local/fallback.
- Version.
- Runtime readiness.

Proof Mode shows:

- Base/adapted state.
- Grounding evaluation.
- Safety evaluation.
- Causal calibration.
- Schema validity.
- Device benchmark.
- Install/rollback/delete.

Personal records never train the model. An adapted model cannot ship without measurable improvement and no safety regression.

### Multimodal Journal

Flow:

1. Photo, voice, or manual capture.
2. Local extraction.
3. Proposed structured facts.
4. Required user review.
5. Edit/confirm.
6. Media-retention choice.
7. Canonical event creation.
8. Influence/experiment linking.

Unconfirmed extraction never enters analysis.

### Sources and Privacy

Every operational source supports:

- Consent.
- Field selection.
- Backfill.
- Delta sync.
- Provenance.
- Pause.
- Resume.
- Revoke.
- Delete.
- Failure recovery.

Calendar retains category, start, end, and recurrence while discarding unnecessary content and identity.

Deletion previews and invalidates:

- Events.
- Fingerprints.
- Evidence.
- Insights.
- Experiments.
- Digests.
- Chats.
- Exports.
- Body Model versions.

Deletion is not complete while dependent artifacts remain valid.

## 4. Architecture and Delivery

### Ground-truth core contracts

- `CanonicalEvent`
- `SourceAdapter`
- `EvidenceBundle`
- `InvestigationSpec`
- `ExperimentProtocol`
- `InsightLifecycle`
- `ModelResponse`

### Supporting contracts

Sources/privacy:

- `SourceDescriptor`
- `SourceConnection`
- `ConsentReceipt`
- `SyncCursor`
- `SourceDependency`
- `DeletionPlan`
- `ProvenanceRecord`

Evidence:

- `EventWindow`
- `MatchedControl`
- `MomentFingerprint`
- `RecoveryEstimate`
- `SignalAgreement`
- `InfluenceAssessment`
- `CounterEvidence`
- `PromotionGateResult`
- `AnalysisPack`

Insights/models:

- `Insight`
- `InsightVersion`
- `ClaimLevel`
- `InvestigationResult`
- `ExplanationDraft`
- `ClaimGuardResult`
- `ModelRegistryEntry`

Experiments/longitudinal:

- `ExperimentRun`
- `ExperimentCheckIn`
- `ExperimentResult`
- `BodyprintVersion`
- `WeeklyDigest`
- `LedgerEntry`
- `WhatIfScenario`
- `DeliveryDecision`
- `ExportBundle`

### Implementation rules

- Riverpod owns state and async transitions.
- GoRouter owns navigation and deep links.
- Drift/SQLCipher stores operational state.
- Android Keystore protects database secrets.
- Pigeon defines typed Flutter/Kotlin boundaries.
- Demo uses the same repositories but a separate profile/store.
- Widgets never construct evidence directly.
- Every number originates from deterministic analytics.
- Every model statement carries evidence references.
- Every source deletion uses dependency invalidation.

### Integration gates

#### Gate 0 — Contracts

Freeze schemas, repository interfaces, fixtures, migrations, design tokens, routes, and ownership.

#### Gate 1 — Reference spine

Demo Data → encrypted timeline → Fingerprint → challenge → evidence → checked explanation → Ledger.

#### Gate 2 — Source compliance

Every operational source passes consent, sanitization, normalization, provenance, dedupe, sync, pause, revoke, deletion, and failure tests.

#### Gate 3 — Analytical validity

Every pack passes positive, null, incomplete, confounded, contradictory, duplicate, time-zone, stale, and expired fixtures without a model.

#### Gate 4 — Model safety

Explorer allow-list, cited explanations, Ask Vueniverse, deterministic guard, safety routing, and fallback pass.

#### Gate 5 — Feature realization

Every committed feature is interactive, persisted, and connected to the same evidence lifecycle. No dead buttons or sample-only success paths.

#### Gate 6 — System integration

Live sources, Demo, Journal, Fingerprints, Ask, experiments, What-if, Body Model, Digest, Ledger, exports, model registry, deletion, migrations, and fallback work together.

#### Gate 7 — Android release

Clean install, upgrade, permission denial, offline, failures, accessibility, performance, memory, thermal, security, repeated demo, and reproducible APK pass.

## 5. Test and Acceptance Plan

### Required analytical scenarios

- Meeting/HR supported.
- Meeting/HR null.
- Meeting/HR insufficient.
- Late-activity/sleep supported.
- Late-activity/sleep null.
- Exercise confounder.
- Missing caffeine.
- Travel exclusion.
- HR/HRV contradiction.
- Duplicate event.
- Time-zone shift.
- Recovery-duration change.
- Stale evidence after deletion.

### Model scenarios

- Valid bounded investigation.
- Evidence-cited explanation.
- Supported skeptical question.
- Unsupported number.
- Causal language.
- Diagnosis.
- Prescription.
- Third-party intent.
- Prompt injection.
- Missing uncertainty.
- Deterministic fallback.

### Experiment scenarios

- Protocol creation.
- Event attachment.
- Reminder/check-in.
- Skipped/partial intervention.
- Strengthened.
- Weakened.
- Unchanged.
- Inconclusive.
- Fingerprint update.
- Ledger version creation.

### Source and privacy scenarios

- Full permission.
- Partial permission.
- Denied permission.
- Backfill.
- Incremental sync.
- Duplicate handling.
- Pause/resume.
- Revoke/delete.
- Failure recovery.
- Dependency invalidation.
- Demo/live isolation.

### Journal scenarios

- Photo capture.
- Voice capture.
- Local extraction.
- User correction.
- Confirmation requirement.
- Media retention/deletion.
- Evidence dependency invalidation.

### UI and accessibility

Golden/widget coverage:

- Onboarding.
- Today.
- Timeline.
- Context Map.
- Fingerprint.
- Replay.
- Challenge.
- Null finding.
- Ask.
- Experiment.
- Sources.
- Journal.
- Digest.
- Body Model.
- Ledger.
- What-if.
- Quiet Intelligence.
- Export.
- Proof Mode.
- All major failure states.

Test:

- Narrow Android phone.
- Standard phone.
- Large text.
- Reduced motion.
- High contrast.
- Screen-reader chart summaries.
- 48 px targets.
- Logical focus order.

### Acceptance criteria

Complete means:

- The ground-truth product plan remains intact.
- The addendum’s Android implementation overrides are applied only where explicit.
- The complete Observe → Fingerprint → Challenge → Explain → Test → Learn → Prove lifecycle works.
- All initial Android sources are operational and independently controllable.
- Every health number is deterministic and traceable.
- Every model claim cites evidence and passes the frozen guard.
- Positive, null, incomplete, contradictory, stale, and expired findings work.
- Experiments update the original Fingerprint and insight lifecycle.
- What-if remains observational.
- My Body Model is a versioned evidence library.
- Quiet Intelligence changes presentation only.
- Ledger and exports preserve provenance.
- Analysis/model updates are versioned and reversible.
- Source deletion invalidates every dependent artifact.
- No operational product feature is a dead button or static sample screen.

### Demo contract

- **0:00–0:20:** human meeting hook.
- **0:20–0:50:** repeated Moment Fingerprint and recovery.
- **0:50–1:20:** matched controls, Signal Agreement, influences, counterevidence, and null finding.
- **1:20–1:48:** Explorer, cited Explainer, and Ask Vueniverse.
- **1:48–2:18:** create ten-minute-buffer experiment.
- **2:18–2:38:** complete Demo occurrences and update the finding.
- **2:38–2:53:** Evidence Ledger, model-off fallback, export, and GPT-5.6/Codex proof.
- **2:53–3:00:** close on the complete evidence lifecycle.

### Assumptions

- `health-os-plan.html` remains the ground-truth product plan.
- The engineering plan is its technical implementation reference.
- The winning addendum overrides only explicit scope and delivery decisions.
- Android is operational first; iOS remains expansion work.
- Initial live sources remain intentionally focused.
- Differentiated product features are implemented, not left as static previews.
- Expansion connectors remain honest non-connected catalogue entries.
- Demo Data may exercise implemented features when a live expansion source is absent.
- Meeting/physiology remains the primary story.
- Late activity/sleep remains the secondary analysis.
- GPT-5.6 remains build-time only.
- Personal data never trains MedGemma.
- The app remains a wellness and personal-science product, not a diagnostic device.
- This response updates the plan only and does not authorize repository changes.
