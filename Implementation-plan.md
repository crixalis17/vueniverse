# WhyPulse Complete Two-Person Implementation Plan

## Ownership

### Person 1 — You: complete application implementation

Person 1 owns everything except the MedGemma model/runtime work:

- Flutter application architecture.
- Riverpod state.
- Drift databases and encryption integration.
- Demo/Live physical separation.
- Demo fixtures and import.
- Health Connect.
- Android Calendar Provider.
- Manual Check-ins.
- Observe source-data dashboard.
- Synchronization and deletion.
- Deterministic analytics.
- Evidence, provenance and UI.
- Deterministic output guard.
- Ask intent routing.
- Experiments.
- History and invalidation.
- PDF/JSON exports.
- Offline and restart behavior.
- Accessibility.
- Android release validation.
- Submission/demo preparation.

### Person 2 — MedGemma implementation only

Person 2 owns:

- MedGemma model acquisition and local setup.
- Model format conversion and quantization.
- Phone-local inference investigation.
- Phone-local MedGemma native runtime.
- Development-machine MedGemma server.
- Explorer and Explainer prompt templates.
- Structured-output reliability.
- Model-specific evaluation.
- Latency, memory and thermal benchmarking.
- Model/runtime documentation.
- Supporting Person 1 during guarded model integration.

Person 2 does not own:

- Drift or application data.
- Health Connect.
- Calendar.
- Manual Check-ins.
- Analytics.
- Evidence promotion.
- Experiments.
- History.
- Exports.
- Output safety decisions.
- Product UI.
- Release signing.

---

# Collaboration boundaries

## Branches and worktrees

Use separate worktrees:

- Person 1: one branch per phase, such as `codex/p1-data-spine`.
- Person 2: `codex/medgemma-runtime`.

Do not work in the same dirty worktree.

## File ownership

### Person 1 owns

- `lib/**`
- `assets/demo/**`
- `pigeons/source_api.dart`
- `pigeons/platform_security_api.dart`
- Drift schema and generated Drift files.
- `test/**`
- `integration_test/**`
- Health/Calendar native packages.
- Android manifests and permissions.
- `pubspec.yaml`
- Release configuration.
- Submission documentation outside model-specific documents.

### Person 2 owns

- `tooling/medgemma/**`
- `android/app/src/main/kotlin/com/whypulse/why_pulse/medgemma/**`
- Model runtime native tests.
- Converted-model tooling and scripts.
- Explorer/Explainer prompt templates.
- `docs/medgemma-runtime-spike.md`
- `docs/medgemma-evaluation/**`
- Model benchmark results.

### Shared model boundary

Person 1 defines:

- `pigeons/model_runtime_api.dart`
- `ExplorerRequest`
- `ExplorerDecision`
- `ExplainerRequest`
- `ExplainerOutput`
- `ModelRuntimeMetadata`
- `SafetyResult`
- `InferenceRuntime`

Person 2 implements the native/server side against the frozen contracts.

Generated Pigeon files must never be hand-edited.

Person 2 must not change the model contract without approval from Person 1. Person 1 must provide versioned fixture requests for Person 2 to test.

---

# Complete product definition

WhyPulse will contain two physically separate paths.

## Live

- Uses actual Health Connect records.
- Uses actual user-reviewed Android Calendar events.
- Persists real Manual Check-ins.
- Runs real deterministic analytics.
- Displays actual evidence when gates pass.
- Shows a repository-backed Observe dashboard of the canonical records currently on device.
- Displays honest insufficient, null, contradictory, stale, unavailable or invalidated states otherwise.
- Supports real experiments, History, deletion and exports.

## Demo

- Uses a separate encrypted database and encryption key.
- Imports a bundled fictional 30-day history.
- Uses the same normalization, analytics, evidence, experiment, History and export code as Live.
- Never queries, joins, copies or combines Live data.
- Provides the complete deterministic submission journey.
- Shows the same Observe dashboard from the isolated fictional store, clearly labelled Demo.

A feature is complete only when:

- Its actions mutate real repositories or Android integrations.
- It survives restart.
- Failure, denial, offline and deletion paths exist.
- Production screens contain no hard-coded analytical values.
- Automated tests pass.
- Native integrations are validated against actual Android providers.
- Demo uses production logic rather than alternate presentation code.

---

# Phase 1 — Encrypted Live and Demo stores

## Person 1 implementation

### Physical separation

Create:

- `whypulse_live.db`
- `whypulse_demo.db`

Each database must have:

- A separate random 256-bit passphrase.
- A separate Android Keystore wrapping-key alias.
- The same Drift schema and migrations.
- Independent source, sync, analysis, experiment, History and export records.

Use preferences only for:

- Onboarding completion.
- Active mode.
- Reduced-motion preference.
- Last navigation destination.

Never store evidence or source data in preferences.

Repositories are created with one concrete database. There is no repository capable of querying both databases.

Switching modes disposes the current repository graph and opens the other database. It never copies data.

### Encryption

Implement an Android platform-security bridge that:

1. Generates a random database passphrase.
2. Wraps it with a non-exportable Android Keystore AES-GCM key.
3. Stores only wrapped key material in no-backup preferences.
4. Places encrypted databases in the no-backup directory.
5. Returns the unwrapped passphrase only while Drift opens the database.
6. Fails closed if key retrieval or database decryption fails.
7. Never creates a plaintext fallback.

Missing Live key:

- Show local-store recovery UI.
- Require explicit Live-data deletion before recreation.

Missing Demo key:

- Offer explicit Demo reset.

### Drift schema

Implement:

- `store_metadata`
- `source_connections`
- `source_permissions`
- `sync_runs`
- `sync_cursors`
- `sync_seen_records`
- `raw_record_index`
- `signal_samples`
- `health_intervals`
- `context_events`
- `manual_checkins`
- `recompute_jobs`
- `analysis_runs`
- `event_windows`
- `control_matches`
- `window_metrics`
- `evidence_bundles`
- `evidence_metrics`
- `evidence_dependencies`
- `finding_versions`
- `explanations`
- `chat_sessions`
- `chat_messages`
- `experiment_protocols`
- `experiment_occurrences`
- `adherence_checkins`
- `experiment_results`
- `experiment_dependencies`
- `export_records`
- `deletion_audit`

Persist explicit versions for:

- Database schema.
- Normalization.
- Meeting analysis.
- Promotion policy.
- Demo fixture.
- Explorer/Explainer schema.
- Prompt.
- Output guard.
- Export schema.

### Domain types

Implement immutable typed models:

- `SourceRecordEnvelope`
- `CanonicalSignalSample`
- `CanonicalHealthInterval`
- `CanonicalContextEvent`
- `SourceProvenance`
- `SyncCheckpoint`
- `RecomputeRequest`
- `AnalysisRun`
- `EventWindow`
- `ControlMatch`
- `EvidenceBundle`
- `EvidenceMetric`
- `FindingVersion`
- `ExplanationRecord`
- `ExperimentProtocol`
- `ExperimentOccurrence`
- `AdherenceCheckIn`
- `ExperimentResult`
- `ExportRecord`

### Normalization

Normalize:

- Heart rate to bpm.
- HRV to milliseconds.
- Steps to integer counts.
- Durations to seconds.
- Time to UTC.
- Original UTC offset separately.
- Original local date separately.
- Sleep, workout and activity categories.
- Meeting and Manual Check-in categories.

Reject malformed, impossible and unsupported records with privacy-safe ingestion counts.

### Deduplication

Use:

- HMAC of stable source ID where available.
- Versioned canonical-payload hash otherwise.

A changed source record:

1. Replaces its canonical representation.
2. Marks affected evidence stale.
3. Enqueues recomputation.

### Recompute jobs

Persist:

- Dirty time range.
- Reason/source.
- Status.
- Retry count.
- Last checkpoint.
- Analysis version.

On restart:

- Convert abandoned running jobs to pending.
- Coalesce overlapping jobs.
- Resume before marking evidence current.

### Real Demo fixtures

Bundle:

- Fictional Health records.
- Fictional Calendar events.
- Fictional Manual Check-ins.
- Expected outputs.
- Fixture manifest.
- Virtual clock.

Include:

- 30 days of heart-rate data.
- Sleep.
- Steps/activity.
- Workouts.
- Recurring 1:1 events.
- Caffeine, exercise, illness, mood and travel.
- Positive, null, contradictory and missing-data cases.
- Time-zone changes.
- Duplicate and changed records.
- Source-deletion case.
- Strengthened experiment.
- Inconclusive experiment.

Create Demo adapters that produce the same DTOs as live source adapters.

`Reset Demo` must:

1. Close Demo repositories.
2. Delete only Demo database/export files.
3. Delete and recreate only the Demo key.
4. Open a newly encrypted Demo database.
5. Import fixtures through production normalizers.
6. Run production analytics.
7. Restore the Demo journey.

## Person 2 implementation

Person 2 does not modify app persistence.

During Phase 1, Person 2 prepares the model environment:

- Accept required MedGemma access/license terms locally.
- Document exact MedGemma checkpoint.
- Create an ignored model-cache location.
- Add model files and credentials to `.gitignore`.
- Create initial inference and benchmark scripts.
- Confirm development-machine hardware/runtime availability.
- Record baseline unquantized model loading behavior.
- Do not commit model weights.

## Phase 1 integration gate

- Live and Demo databases and keys differ.
- Neither database is readable as plaintext.
- Resetting Demo leaves Live unchanged.
- Deleting Live leaves Demo unchanged.
- Migrations preserve encrypted data.
- Duplicate imports are idempotent.
- Restart resumes jobs.
- Three Demo resets produce identical canonical hashes.
- Person 2 can load the official checkpoint or documents the precise blocker before Phase 2.

---

# Phase 2 — Health Connect, Calendar and Manual Check-ins

## Person 1 implementation

### Pigeon source bridge

Define typed APIs for:

- Health Connect availability.
- Feature availability.
- Permission snapshots.
- Permission requests.
- Initial paged reads.
- Change-token reads.
- Calendar permission.
- Recurring-series discovery.
- Calendar instance snapshots.
- Android settings.
- Native error/retry information.

### Health Connect

Read actual:

- Heart rate.
- Sleep sessions and useful stages.
- Steps.
- Exercise/workout sessions.
- Activity required for workout exclusions.
- HRV RMSSD when available.

Implement:

- Availability detection.
- Per-type permission state.
- Partial permission support.
- Initial rolling 30-day read.
- Pagination.
- Independent change tokens.
- Insert/update/delete handling.
- Expired-token recovery.
- Rate-limit backoff.
- App-resume sync.
- Manual refresh.
- Interrupted-sync recovery.

Cursor/token advancement occurs only after records are committed.

### Calendar

Request `READ_CALENDAR` only.

User-reviewed privacy flow:

1. Query recurring series.
2. Show title transiently.
3. Let the user categorize:
   - Recurring 1:1.
   - Team meeting.
   - Other recurring meeting.
4. HMAC raw Calendar identifiers.
5. Persist only:
   - Category.
   - Start.
   - End.
   - Recurrence key.
   - Original UTC offset.
   - Provenance.
6. Discard:
   - Title.
   - Description.
   - Location.
   - Organizer.
   - Attendees.
   - Calendar/account identity.

Calendar snapshot synchronization:

- Track seen instances during each sync.
- Upsert observed instances.
- Delete absent instances only after a complete snapshot.
- Leave the last completed snapshot intact if interrupted.
- Handle recurrence exceptions and cancelled events.

### Manual Check-ins

Persist real add/edit/delete for:

- Caffeine.
- Exercise.
- Illness.
- Mood.
- Travel.
- Reviewed custom category.

Every mutation schedules recomputation.

### Sources screen

Replace source toggles with real states:

- Unavailable.
- Permission required.
- Partially permitted.
- Syncing.
- Connected and empty.
- Connected with data.
- Paused.
- Error.
- Disconnected.
- Deleting.
- Stale.
- Demo fixture loaded.

Implement actual actions:

- Connect.
- Refresh.
- Request missing permissions.
- Pause.
- Resume.
- Open Settings.
- Disconnect.
- Delete source data.
- Reset Demo.

Demo mode:

- Live integrations say `Available in Live`.
- They cannot appear connected.
- Demo shows its fictional source streams and fixture version.

Live mode:

- No Demo records, findings, experiments or exports appear.

### Observe source-data dashboard

Implement `Observe` as a read-only screen opened from Today readiness. It is the beautiful source overview that precedes analysis; it is not a second findings screen and it does not make health claims.

Repository contract:

- Read only normalized canonical tables from the active repository graph: signal samples, health intervals, categorized context events and Manual Check-ins.
- Use the Demo virtual clock for Demo and the current device time for Live.
- Build a rolling 30-day snapshot with a client-side 7-day view option.
- Compute daily heart-rate median, sleep duration, step total, event count, check-in count and record coverage deterministically.
- Return only privacy-safe recent activity labels; never restore Calendar title, attendees, description, location, organizer or account identity.
- Never query both physical stores and never join Live with Demo.

Screen implementation:

- Hero summary: active days, exact local record count and active stream count.
- Switchable heart-rate, sleep and steps trend chart with daily average, low and high.
- Thirty-day `Data rhythm` strip where intensity represents how many data kinds are present, not whether the day was good or bad.
- Source-mix cards for health signals, rest/movement, categorized recurring events and Manual Check-ins.
- Privacy-safe recent records list.
- Clear Live/Demo, local/fictional and on-device labels.
- Loading, pull-to-refresh, refresh-failed-with-cached-snapshot, and no-data states.
- Direct route to Sources for connect, pause, disconnect and deletion controls.

Refresh Observe after:

- Source connect, refresh, resume or deletion.
- Calendar review save.
- Manual Check-in add, edit or delete.
- Live app resume sync.
- Demo reset or mode switch through repository-graph recreation.

Accessibility and tests:

- Charts expose TalkBack summaries with metric, recorded-day count and range.
- Color is never the only carrier of source, range or availability state.
- Repository tests assert canonical counts, rolling-window behavior and redacted event output.
- Widget tests cover the Today entry point, metric switching, source mix and recent records.

## Person 2 implementation

Continue MedGemma feasibility work only:

- Test supported model runtimes.
- Attempt text-only MedGemma inference.
- Record tokenizer/chat-template behavior.
- Measure initial development-machine latency and memory.
- Evaluate whether quantized mobile conversion is supported.
- Create a model fixture command that accepts a JSON prompt and prints raw output.
- Do not integrate with personal or Live data.

## Phase 2 integration gate

- Real Health Connect record imported.
- Actual recurring Calendar series selected.
- Actual Manual Check-in persisted.
- Observe summarizes those canonical records without exposing Calendar identity.
- All survive restart.
- Permission denial and recovery work.
- Pause/resume/delete work.
- Live and Demo remain physically isolated.
- Person 2 has a repeatable development-machine inference command.

---

# Phase 3 — Deterministic meeting analytics

## Person 1 implementation

### Windows

For each selected meeting:

- Pre-event: 15 minutes.
- During-event: full event duration.
- Primary recovery: 15 minutes.
- Recovery-search horizon: up to 60 minutes.
- Comparable no-meeting controls.

Rank controls by:

1. Local start-time distance.
2. Weekday similarity.
3. Calendar-day distance.
4. No selected-event overlap.
5. No workout overlap.
6. Adequate signal coverage.

Do not reuse controls within one run.

### Exclusions

Exclude:

- Workout overlap.
- Workout ending within 30 minutes before pre-event.
- Travel.
- Illness.
- Invalid event duration.
- Missing control.
- Under 75% heart-rate coverage.
- Missing provenance.

Caffeine and prior sleep remain unresolved influences unless deterministic subgroup analysis supports another treatment.

### Metrics

Calculate:

- Pre-event median.
- During-event median.
- Recovery median.
- Control median.
- Per-occurrence difference.
- Median difference.
- Effect range.
- Candidate count.
- Included count.
- Excluded count by reason.
- Counterevidence count.
- Consistency.
- Completeness.
- Recovery duration.
- Unresolved influence count.
- Provenance for every metric.

Completeness uses covered one-minute bins.

Recovery is the first five consecutive minute bins within `max(3 bpm, 5%)` of baseline, censored after 60 minutes.

### Promotion policy

Supported requires:

- At least four usable meetings.
- At least four controls.
- At least 75% completeness.
- Two-thirds consistent direction.
- Absolute median difference of at least 5 bpm.
- No dominant measured alternative influence.
- Complete provenance.

Persist:

- Supported.
- Developing.
- Null.
- Contradictory.
- Insufficient data.
- Stale.
- Invalidated.

Live must never use a Demo result when Live evidence is insufficient.

### Fixtures

Assert exact cases:

- Positive: 12 candidates, 8 analyzable, 6 positive, 2 counterevidence, 4 excluded, 12 controls, `+11 bpm`, range `+8–14 bpm`.
- Null.
- Contradictory.
- Missing data.
- Time-zone change.
- Duplicate replay.
- Changed record.
- Source deletion.
- Strengthened experiment inputs.
- Inconclusive experiment inputs.

### Rolling recomputation

On source/influence change:

1. Mark dependent outputs stale.
2. Rebuild affected windows.
3. Recalculate the current 30-day aggregate.
4. Create a new evidence version.
5. Create or supersede the finding version.
6. Commit atomically.
7. Clear stale only after completion.

## Person 2 implementation

### Model fixture preparation

Person 1 provides privacy-safe example `EvidenceBundle` JSON.

Person 2:

- Confirms no raw source records are needed.
- Builds initial Explorer prompts.
- Builds initial Explainer prompts.
- Tests positive, null, contradictory and missing-data evidence.
- Tests whether the model follows JSON-only output instructions.
- Records unsupported numbers, overclaims and schema failures.
- Begins prompt iteration without modifying Person 1’s evidence schema.

## Phase 3 integration gate

- All analytics pass with MedGemma disabled.
- Live produces real evidence or honest insufficiency.
- Demo fixtures match exact expected results.
- DST, travel, duplicates and deletion pass.
- Person 2 produces a model-output reliability report for the fixed evidence fixtures.

---

# Phase 4 — Repository-backed UI and phone-local model spike

## Person 1 implementation

### Remove production seed values

Replace all seeded values in:

- Today.
- Observe.
- Sources.
- Fingerprint.
- Evidence.
- History.
- Experiments.
- Proof.

Production screens must not import `seed_content.dart`.

Bind:

- Today to current finding.
- Observe to the active store's canonical records and virtual/device clock.
- Fingerprint to stored traces.
- Evidence to persisted metrics/gates.
- Sources to real permission/sync state.
- History to stored versions.
- Demo screens to Demo database.

### Provenance

Every number opens:

- Calculation definition.
- Analysis version.
- Input sources.
- Time range.
- Included windows.
- Exclusions.
- Completeness.
- Evidence/finding version.
- Privacy-safe record references.

Charts use persisted samples and expose TalkBack summaries. Observe remains descriptive: its coverage intensity and daily ranges never become evidence promotion or health scoring.

### Influence editing

Saving an influence:

1. Persists a Manual Check-in.
2. Marks evidence stale.
3. Shows recomputing.
4. Runs analysis.
5. Creates a new evidence version.
6. Updates UI from repository.
7. Invalidates explanation/export dependencies.

### Honest states

Implement:

- Live.
- Demo.
- Syncing.
- Recomputing.
- Cached offline.
- Stale.
- Invalidated.
- Insufficient data.
- Permission missing.
- Source unavailable.
- Model unavailable.
- Deterministic fallback.

## Person 2 implementation

### Phone-local spike

Attempt a supported quantized MedGemma 1.5 4B IT mobile artifact.

Implement model-only native code under the dedicated MedGemma package.

Measure on a physical phone:

- Model load time.
- Warm latency.
- Peak incremental RSS.
- JSON/schema reliability.
- Ten-call thermal behavior.
- Crash/OOM behavior.

Phone-local passes only if:

- No crash/OOM.
- Warm p95 is at most 8 seconds.
- Peak incremental RSS is at most 3.5 GB.
- At least 95% schema-valid output before repair.
- No severe thermal state over ten calls.

Do not bundle the original checkpoint in the APK.

### Development-machine server

Build a working local MedGemma service:

- Binds to localhost.
- Runs the approved checkpoint.
- Accepts versioned JSON requests.
- Returns raw structured model output.
- Is reachable using `adb reverse`.
- Contains no cloud dependency.
- Rejects Live requests.
- Is explicitly Demo-only.

## Phase 4 integration gate

- UI contains no production seed values.
- Every metric has provenance.
- Influence edits actually recompute.
- Stale data never shows Current.
- Person 2 publishes phone-runtime results.
- Development-machine server can answer a Demo fixture request.
- An explicit runtime decision is recorded.

---

# Phase 5 — MedGemma integration and output guard

## Shared interface

Person 1 freezes:

### Explorer

`ExplorerRequest` contains:

- Schema/version IDs.
- Compact daily/event summaries.
- Available category IDs.
- Available influence IDs.
- Allowed operations.

Allowed operations:

- Compare repeated event.
- Inspect recovery.
- Check logged influence.

`ExplorerDecision` selects one operation and known IDs.

### Explainer

`ExplainerRequest` contains:

- Evidence metrics keyed by citation.
- Finding state.
- Promotion gates.
- Exclusions.
- Counterevidence.
- Unresolved influences.
- Approved next observations.
- Scoped Ask intent.

`ExplainerOutput` contains:

- Summary.
- Cited paragraphs.
- Uncertainty.
- Cited unresolved influences.
- Optional approved next observation.

## Person 1 implementation

### Runtime adapters

Implement Dart-side:

- `PhoneMedGemmaRuntimeAdapter`
- `DevelopmentMachineMedGemmaRuntimeAdapter`
- `DeterministicExplanationRuntime`

The adapters send only the frozen schemas.

### Ask routing

Allow:

- Why was this shown?
- What weakens it?
- What is missing?
- What disagrees?
- What should I observe next?
- Why did the promotion gate pass/fail?

Reject generic chat and unrestricted timeline requests before inference.

### Deterministic output guard

Reject:

- Invented or altered numbers.
- Unknown citations.
- Unsupported sources/influences.
- Diagnosis.
- Treatment.
- Prescription.
- Medication advice.
- Causality.
- Healthy/unhealthy or safe/unsafe verdicts.
- Generic advice.
- Prompt injection.
- Prompt leakage.
- Calendar identity.
- Cross-store references.
- Invalid schema.
- Evidence-version mismatch.

Allow one constrained retry. A second failure uses deterministic fallback.

Persist:

- Evidence version.
- Runtime.
- Model name.
- Prompt version.
- Guard version.
- Latency.
- Accepted/rejected result.
- Safety failures.

### Deterministic fallback

Generate safe evidence language entirely from:

- Finding state.
- Approved metrics.
- Exclusions.
- Counterevidence.
- Unresolved influences.
- Promotion result.

It must remain fully functional without any model.

## Person 2 implementation

### Phone runtime

If the spike passed:

- Finalize phone-native MedGemma loading.
- Implement inference against the Pigeon model contract.
- Add cancellation and timeout.
- Use greedy decoding.
- Enforce output limit.
- Return runtime metadata.
- Handle missing/corrupt model assets.
- Provide model-installation/loading instructions.

### Development runtime

Finalize:

- Demo-only store enforcement.
- Schema validation before inference.
- Prompt formatting.
- Greedy decoding.
- Timeout.
- Runtime metadata.
- Clear error responses.
- Startup/health endpoint.
- `adb reverse` setup command.

### Prompts

Own:

- Explorer system template.
- Explainer system template.
- Guard-repair template.
- Prompt versioning.
- Few-shot examples using fictional evidence only.

Prompts must instruct the model to:

- Use supplied facts only.
- Emit JSON only.
- Cite every factual claim.
- Avoid diagnosis/treatment/causality.
- State uncertainty.
- Mention unresolved influences.
- Refuse generic chat.

### Model evaluation

Run:

- Positive.
- Null.
- Contradictory.
- Missing data.
- Invented number.
- Diagnosis.
- Prescription.
- Causality.
- Fake citation.
- Prompt injection.
- Generic chat.
- Full-timeline request.
- Malformed output.
- Timeout.

Provide raw model outputs and summary scores without personal data.

## Phase 5 integration gate

- At least one real MedGemma backend produces an accepted explanation.
- Phone-local is used only if it passes.
- Development machine receives Demo only.
- Live never leaves the phone unless scope changes explicitly.
- Unsafe outputs are rejected by Person 1’s guard.
- Model failure selects deterministic fallback.
- Model never calculates or promotes evidence.
- Runtime labels are exact and persisted.
- Evidence change invalidates the prior explanation.

---

# Phase 6 — Experiments, History, deletion, exports and offline use

## Person 1 implementation

### Experiment lifecycle

Implement the real protocol:

- Ten-minute quiet buffer before recurring 1:1.
- Tied to finding version and recurrence key.
- Three required eligible occurrences.
- Reminder before buffer.
- Post-meeting adherence check-in.
- Actual future Calendar instances in Live.
- Fixture future instances in Demo.

Occurrence states:

- Upcoming.
- Reminder scheduled.
- Due.
- Adhered.
- Partially adhered.
- Skipped.
- Missing check-in.
- Calendar cancelled.
- Ineligible.
- Stopped.

Experiment states:

- Draft.
- Active.
- Paused.
- Completed.
- Cancelled.
- Stopped.
- Invalidated.

### Notifications

Implement Android local notifications:

- Request notification permission.
- Schedule/update/cancel reminders.
- Restore after restart.
- React to Calendar occurrence changes.
- Do not block experiment if permission is denied.

### Experiment calculation

Use the same analytical windows, controls, exclusions and provenance.

Produce:

- Strengthened.
- Weakened.
- Unchanged.
- Inconclusive.

Every completed result appends a new finding version linked to the original.

### History

Persist:

- Every finding version.
- Every evidence version.
- Every experiment.
- Every result.
- Supersession.
- Stale state.
- Invalidation.

### Source deletion

Deleting a source:

1. Deletes raw and canonical records.
2. Invalidates dependent evidence/findings.
3. Deletes explanation/chat content.
4. Invalidates experiments/results.
5. Deletes generated export files.
6. Removes affected findings from Today.
7. Preserves only privacy-safe tombstones.
8. Recomputes remaining data.

### Real exports

Generate:

- Human-readable PDF.
- Canonical JSON evidence bundle.

Include:

- Live/Demo.
- Sources and sync timestamps.
- Included/excluded/counterevidence counts.
- Completeness.
- Influences.
- Versions.
- Model/runtime.
- Safety result.
- Experiment relationships.
- Current/stale/invalidated state.
- SHA-256 integrity hash.

PDF and JSON must display the same hash.

Implement Android share sheet and secure file-provider paths.

Clinician Report remains Preview.

### Offline/restart

Restore:

- Cached Today.
- Cached Observe snapshot and as-of time.
- History.
- Fingerprint.
- Evidence.
- Accepted explanation or deterministic fallback.
- Experiment state.
- Proof metadata.
- Valid exports.

Rules:

- Offline content shows as-of time.
- Pending recomputation means stale.
- Live sync older than 24 hours is outdated.
- Demo uses the fixture virtual clock.
- Interrupted jobs resume before Current returns.

## Person 2 implementation

Model-only support:

- Verify cached accepted explanation can be reopened without model.
- Verify unavailable model selects deterministic fallback.
- Verify evidence-version change prevents cached-output reuse.
- Verify development-machine server disconnect behavior.
- Supply final model/runtime metadata required by exports.
- Do not implement experiment, History or export behavior.

## Phase 6 integration gate

- Real Live experiment can start and restore.
- Actual Calendar occurrences schedule reminders.
- All occurrence failure states work.
- All four result outcomes work.
- Finding version is appended.
- Source deletion cascades correctly.
- Real PDF and JSON are generated.
- Hashes match.
- Offline restart restores valid cached state.
- Invalidated files are removed.
- Model absence does not break any core workflow.

---

# Phase 7 — Android release and submission validation

## Person 1 implementation

### API 34 and API 36

Validate:

- Live clean install.
- Demo clean install.
- Health Connect unavailable/empty/denied/partial/connected.
- Calendar denied/selected/changed/cancelled/deleted.
- Manual Check-in add/edit/delete.
- Pause/resume/disconnect/delete.
- Demo reset.
- Interrupted sync.
- Interrupted recomputation.
- Offline restart.
- Experiment reminder allowed/denied.
- Export generation/deletion.
- Live/Demo physical separation.
- Model success/failure/fallback.

### Accessibility

Validate:

- TalkBack order and labels.
- Observe and Fingerprint chart descriptions.
- Provenance actions.
- 200% font scaling.
- 48dp targets.
- Contrast.
- Reduced motion.
- Text/icon state indicators independent of color.

### Performance

Record:

- Database open.
- Live sync.
- Incremental sync.
- Demo import.
- Analysis/recomputation.
- App memory.
- Export duration/file size.
- Repeated-reset memory growth.
- Duplicate growth.
- Notification duplication.
- Export-file leaks.

### Release

- Replace debug signing.
- Use untracked upload keystore.
- Verify no real data, API key, credentials, model checkpoint or development endpoint is packaged.
- Generate third-party notices.
- Produce release APK metadata.

### Deterministic Demo runs

Run three complete clean Demo journeys.

Each must produce:

- 12 candidate meetings.
- 8 analyzable.
- 6 positive.
- 2 counterevidence.
- 4 excluded.
- 12 controls.
- `+11 bpm`.
- `+8–14 bpm`.
- Same evidence hash.
- Same strengthened result.
- Same History chain.

Any mismatch resets the consecutive count.

### Submission path

- Observe source dashboard.
- Today.
- Moment Fingerprint.
- Evidence.
- Provenance.
- Guarded explanation.
- Scoped Ask.
- Test This.
- Result.
- History.
- Actual Proof/Export.
- Safety test.

Capture a genuine failing-to-passing guard test.

## Person 2 implementation

### Final model validation

Provide:

- Exact model/checkpoint.
- Quantization.
- Runtime/backend.
- Model delivery method.
- Cold and warm latency.
- Peak memory.
- Thermal result.
- JSON validity rate.
- Guard acceptance rate.
- Known limitations.
- Phone-local pass/fail decision.
- Development-machine setup.
- Runtime labels used by the app.

Verify ten repeated model calls on the chosen physical device/runtime.

Ensure:

- No model checkpoint is accidentally packaged unless explicitly intended.
- Development-machine runtime cannot accept Live requests.
- Runtime instructions are reproducible.
- Submission claims exactly match measured deployment.

## Final completion criteria

- Live and Demo are separate encrypted databases and keys.
- Real Health Connect works.
- Real Android Calendar works.
- Real Manual Check-ins work.
- Observe accurately summarizes the active encrypted store, refreshes after source changes and never reveals retained Calendar identity.
- Demo uses production ingestion and analytics.
- No Live/Demo mixing.
- Deterministic analysis works without a model.
- Every number has provenance.
- At least one real MedGemma backend works.
- Unsafe output is blocked.
- Live remains functional without MedGemma.
- Experiments persist and produce versioned outcomes.
- History and deletion invalidation work.
- PDF and JSON exports are real.
- Offline/restart works.
- API 34 and API 36 pass.
- Three deterministic Demo runs match.
- The complete three-minute story requires no fake toggles, manual database changes or hard-coded analytical values.

# Locked scope

Included:

- Health Connect.
- Android Calendar Provider.
- Manual Check-ins.
- Repository-backed Observe source-data dashboard.
- Physically separate deterministic Demo.
- Phone-local or Demo-only development-machine MedGemma.
- Recurring meeting/heart-rate analysis.
- Explorer, Explainer and evidence-scoped Ask.
- Experiments, History and Proof/Export.

Excluded:

- Extra connectors.
- Screen-time analysis.
- FHIR.
- Multimodal Journal.
- Smart Environment.
- iOS.
- Generic chatbot.
- Personal Digital Twin.
- Model training or adaptation.
- Separate Replay, Influence or Signal screens.
