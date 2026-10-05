# First-person Android milestone

Agreed October 3, 2026. Device: Nothing Phone 2, 8 GB RAM.
Initial sources: personal Ultrahuman metrics and manual check-ins only.
Calendar permission and invented contextual events are not prerequisites.

Completion means a verified workflow on the owner's actual phone, not just a build
or emulator: onboard, explicitly connect/import, inspect retained data and receipt
history, save/edit a check-in, refresh, reopen with encrypted data retained, inspect
coverage and a grounded explanation or honest insufficient-data state, and exercise
pause/delete/retry. Selected LoRA identity and actual runtime behavior must be
verified; a fallback cannot be reported as a successful LoRA answer.

## Locally verified implementation (not milestone completion)

- [x] ~~Collection-first onboarding; no required Calendar or model download.~~
- [x] ~~Session-only credential form and explicitly requested provider dates.~~
- [x] ~~Strict supported health shapes, truthful receipt counters and no invented context.~~
- [x] ~~Pause/disconnect/delete races blocked at atomic import persistence.~~
- [x] ~~Collection ledger with safe metadata, pagination and unknown legacy counters.~~
- [x] ~~Manual check-in persistence failures surfaced; Android encrypted save/edit/reopen/delete.~~
- [x] ~~Model-identity-aware cache and explicit retained LoRA artifact variant.~~
- [x] ~~Disposable Android aggregate flow: 27 checks passed on October 4, 2026.~~
- [x] ~~Separate actual-production bootstrap: one save/edit/reopen and ledger test passed.~~
- [x] ~~Local storage/analysis acknowledgement, partial-delete privacy and keyless-resume regressions.~~

Current local verification: **254 Flutter tests passed; static analysis clean**.
Also verified: **110 Python tests and 59 native tests per variant (LoRA/vanilla)**.
The 27-check aggregate run
and separate production-bootstrap test used disposable `emulator-5582`; later
source-lifecycle fixes were verified by local regressions, not a new emulator run.
The latest October 5 actual-main bootstrap also passed on disposable `emulator-5580`,
including current lifecycle changes. Fixture text input was scoped to a mock because
real-IME/test-injection interaction restored stale text; actual production controllers,
encrypted save/edit/reopen and ledger assertions stayed intact. Physical-keyboard
acceptance remains pending.

The emulator run used mocked provider replies, not the owner's credential/live API.
It also verified Android Keystore encryption/isolation and reopening. Emulator
testing does not satisfy real-device performance, live-account or longitudinal gates.

The exact LoRA emulator contract remains open. After native lifetime repair and
trained-schema alignment, bounded grammar produced **3/3 schema-valid responses,
1/3 automated guard passes and two fallbacks**. Manual review rejected the accepted
answer because “zero” contradicted input consistency `0.75`. The other two model
texts were rejected and not retained for semantic scoring. Schema completion is not
grounding, and CPU-emulator timings are not phone performance. Normal builds now
hold the candidate before native inference; historical cache entries cannot bypass
that hold. Keep the candidate unapproved until semantic acceptance is established.

## Actual-phone acceptance (still pending)

- [ ] Clear onboarding with a collection-first route, separate model-download consent
  and no suggestion that unchecked sources are already connected.
- [ ] Session-only Ultrahuman credential entry; direct personal API, bounded imports,
  no token in logs, preferences, source configuration, exports or repository.
- [ ] Faithful health normalization with explicit timezone/schema limitations;
  no imputation of missing measurements, no invented context in Live.
- [ ] Manual check-in save/edit/delete with visible persistence failures.
- [ ] Local collection ledger: source/type counts, observation range, import receipts,
  rejected records and retained/deleted-data distinction, separate from model findings.
- [ ] Coverage and source freshness visible; no causal or recurring-event claim from
  health-only data. Manual reports are context, not verified exposures or event timing.
- [ ] Exact LoRA artifact staging, prompt compatibility and rollback/cache identity.
- [ ] Physical-phone functionality, latency/memory/storage/cancellation verification.
- [ ] Restart/pause/revocation/deletion checks on the actual phone.
- [ ] Preserve a local, privacy-conscious diagnostic record for later iteration.

Post-milestone analysis is a separate phase: review collected-data coverage, rejected
imports, missing context, misleading findings and runtime failures before deciding
whether analytical policy, onboarding or fine-tuning needs to change. Do not upload
personal health/check-in data or train on it merely because it was collected.

Current external gate: the phone is identified but not connected over ADB. No
physical-device gate is satisfied yet. Calendar-based research benchmarks remain
development evidence; they do not validate this new health/manual workflow.
