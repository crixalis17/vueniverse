# First-person implementation record

October 3–5, 2026. This is implementation evidence, not physical-phone acceptance.
The owner workflow uses Ultrahuman plus manual check-ins. Calendar is optional;
the existing recurring-meeting research pipeline does not establish correlations
from health/manual data alone.

## Data and lifecycle

Onboarding offers collection without AI and separate model consent. The personal
Ultrahuman endpoint is called directly with a session-only credential. Only verified
heart-rate and timestamped sleep-stage shapes are normalized; HRV and steps are
not guessed. Report timezone is not a travel-history reconstruction. Provider-row
accounting separates retained observations, duplicates and rejected observations.

Imports bind the first successful credential through a local HMAC, not a saved
token. Switching ownership requires explicit deletion. Source generations and an
atomic persistence recheck prevent a delayed response from repopulating data after
pause/disconnect/delete. Partial imports retain completed days and safe receipts.
The local collection ledger exposes counts, ranges and receipts, not raw values,
check-in text or credentials. Older receipts with no counter details stay unknown.

Check-in deletion awaits storage success. Onboarding completion persists before
changing the visible completed state. No personal API fetch or upload is necessary
for the synthetic/in-memory regression tests.

Storage acknowledgements are separate from subsequent analysis/read failures.
A committed check-in or source change stays saved even if analysis cannot update;
the UI offers an analysis retry rather than repeating the write/import/deletion.
Deletion attempts clear dependent cached views; manual-source deletion also clears
cached check-in text before persistence, recovering only verified retained entries.
Failed post-commit updates hide old findings, answers, history and dashboard data.
Generation checks prevent older reads from restoring them after a source change.
Ultrahuman resume lifts pause without a keyless refresh or a fabricated sync time.
Reminder freshness reconciliation runs even when post-commit analysis fails.

The collection-first flow can review all saved manual check-ins directly from
Today or the manual source detail, without a supported finding or Calendar data.
The collection-neutral list shows its retained count and allows older reports to
be edited/deleted through existing commit acknowledgements and confirmation.
Non-caffeine reports are timestamped when saved; editing preserves the original
report time. This is not an exact exposure/event-start timestamp. Caffeine's
explicit coverage interval remains separate. Three dedicated widget regressions
verify both no-finding routes, older-entry editing/deletion and report-time bounds;
the focused 25-test UI suite passed with clean analysis on October 5.

The prior-finding query now selects only the latest version before reading a
single row. A regression reproduced the missing-limit failure before the fix and
verified a linear four-version history after it.

## Local verification

On October 4, the full Flutter suite passed **252 tests**, with clean static
analysis. The disposable `emulator-5582` aggregate suite passed **27 checks**:
mocked provider imports and UI/lifecycle checks plus real Android encrypted-store
tests. Separately, **one production-bootstrap integration test passed**, invoking
actual `main()`, ProviderScope and the store graph to save/edit/reopen a fabricated
manual check-in and inspect truthful collection history. Its final rerun included
the storage/analysis acknowledgement split; later lifecycle changes have local
unit regressions but were not included in that earlier emulator run.
October 5 native verification passed **59 tests per variant (LoRA and vanilla)**,
including candidate hold and exact state normalization. Eight invalid/unsafe build
configuration checks failed closed as intended; normal fixture flags remain off.

October 5 verification passed **254 Flutter tests and 110 Python tests**, with clean
static analysis. The latest actual-main production bootstrap also passed **1/1** on
the separate disposable `emulator-5580` against current sources, including lifecycle
changes. An immediate-input assertion proved injected text initially reached the
controller, then reverted while real IME was active during scrolling. Only fixture
typing/save now uses registered mock input, released before restarting actual main;
storage, controller, commit and encrypted-reopen assertions are unchanged. The earlier
failed attempts remain recorded. This is not physical-keyboard or live-account acceptance.

## Analytical changes: version 7

Recovery slots are half-open and anchored to the actual event-end second; a
preceding-minute reading cannot delay recovery. The version-6 matching and freshness
policy remains in force. Supported-only intervention eligibility is enforced in
both projections and the experiment repository, including persistence and scheduling
boundaries. Unresolved influences prevent intervention initiation.

Stale/ineligible protocol reminders are cancelled on reconciliation; historical
protocols and responses remain intact. This is not a claim that an OS alarm checks
database freshness while the app never runs. Actual device alarm/revocation behavior
remains a phone acceptance gate.

## Model and evidence limits

The selected LoRA BF16 v7 merged Q4_K_M artifact has an explicit Android variant,
distinct filename/revision and manifest. Default builds retain the vanilla pin.
Artifact identity participates in answer-cache validation. Native microbenchmarks
do not establish production-prompt compatibility; the separate contract test uses
the actual coordinator and guard and rejects fallback answers.

The retained candidate's three-intent emulator contract remains **not accepted**.
The baseline timed out on all three intents (roughly 123 seconds per delivered
fallback). Explicit native `-O3` optimization reduced completion to roughly
45 seconds, but all three raw outputs failed schema validation. A sampled-token
lifetime defect was then repaired; the optimized lifetime-safe rerun still had
**0/3 raw guard passes and 3/3 safe fallback passes**, with no native timeouts.
The repair is required decoder correctness hardening, not proof that the model
is aligned with the Android prompt. Cause analysis remains pending; these runs
do not establish a training failure or physical-phone performance.
Fixture-only reports are retained in
[the local acceptance package](../../experiments/readiness/first-person-local-v1/README.md).

Development-v1 remains preserved. Development-v2 records current analysis-version-7
projections and honest insufficient/developing responses. Neither package is an
independent final benchmark or a new fine-tuning dataset. Existing research scores,
datasets, adapters and cloud checkpoints are unchanged.

Physical runtime, owner onboarding, restart, revocation/deletion and live-import
acceptance are still required by FIRST-PERSON-MILESTONE.md. No public-readiness or
clinical-performance claim follows from local passing tests.

## Phone output-contract integration

The frozen training target and the Android v5 DTO had different shapes. The selected
LoRA path now projects an EvidenceBundle with metric arrays, retains exact app
citation IDs/number strings, continues an authoritative JSON prefix, and strictly
translates schema-2 paragraphs/known observation IDs into the app DTO. No recurring
context ID is invented when the projection supplies none. In particular, a count
of positive differences is not relabeled as a same-direction count, and absolute
material-effect bounds are not relabeled as a signed observed range.

Version-6 aligned checks still exhausted 384 and then 512 generated tokens without
complete JSON. Version 7 adds request-grounded bounded GBNF sampling using the pinned
llama.cpp API. It constrains JSON shape, text lengths and known IDs, not health facts
or semantic correctness. The strict decoder and unchanged Dart guard remain required;
grammar initialization fails closed. LoRA keeps a 512-token/120-second bound, while
vanilla retains its previous 384-token behavior and parser. Projection version 7
changes cache inputs, separate from the unchanged frozen v7 training dataset and
analysis policy version 7. Native/parser and real-intent results are recorded in
the local acceptance package; a constrained schema pass alone is not model quality.

The v7 three-intent run completed with three schema-valid responses, one automated
guard pass and two deterministic fallbacks, at roughly 56–59 seconds per intent on
the CPU emulator. Manual review rejected the accepted explanation: it claimed
“zero” consistency despite `0.75` in the evidence and another paragraph. Rejected
model prose was not retained and cannot be semantically scored. Grammar improved
completion, not factual grounding; no training failure or phone-performance verdict
is inferred from these integration findings.

The candidate is now fail-closed in normal builds: byte verification is not semantic
approval. Its state is `contractUnverified`, and explain/explore reject before native
load or inference. Accepted-cache reuse also requires current artifact availability,
preventing older candidate answers from bypassing the hold without deleting history.
An evaluation capability is permitted only for the exact debug fixture target; all
release builds force it off. Vanilla remains unchanged. The frozen research artifacts
are retained for a future explicitly scoped semantic investigation, not retraining
or activation during this collection milestone.

## Contract and collection follow-up: October 5

The initial contract-v8/guard-v6 app gate passed 287 tests, with clean analysis/formatting;
native suites pass 63 per variant, including 20 dedicated contract tests. A host
audit found all 168 developing training examples described scarce comparisons,
while the real app can remain developing with enough comparisons but unresolved
context. The phone previously omitted that gate and exclusion categories. See
[the audit](android-semantic-contract-audit-v1.md) for facts and unresolved hypotheses.

Phone prompt v8 preserves exact metrics, passed/failed/missing gate facts, exclusion
occurrence/category pairs and bounded possible-influence descriptions. It never
aliases positive counts to same-direction counts or invents a context identity.
Grammar, selected weights and inference bounds are unchanged. Projection v8 and
guard v6 prevent reuse of older acceptance; historical rows are retained. Finite
metric-role checks reject the recorded zero contradiction and cross-metric swaps,
but do not constitute general semantic understanding or candidate approval.

The test-only recording proxy captures parsed DTOs before guard rejection. Bounded
ASCII/base64 chunks carry a full-record hash; output buffers are flushed before
the test concludes. Raw thinking, malformed raw outputs and owner-store requests
are never captured. Older truncated records remain unavailable, not retroactively
recovered or scored. The new one-case diagnostic is separate development evidence.

The completed prompt-v8/guard-v6 `why_promoted` case took 71.995 seconds native and
72.738 seconds end to end on the CPU emulator. Its complete parsed DTO was recovered
with checksums. Numerical quantities matched, but instruction echo, fragments and
incorrect gate meaning caused manual rejection independently of automated flags.
The delivered deterministic fallback was grounded; it is not a LoRA pass. Exactly
one model call was made; no further generation followed this failure.

Guard v6 incorrectly read “zero point seven five” as zero. Guard v7 parses complete
finite cardinal/word-digit decimal quantities and refuses unsupported compound
prefixes. A focused 87-test regression run and a one-test replay of the retained DTO pass
without inference. The numerical false positive is removed; the existing lexical
causal flag in a negated definition remains a documented heuristic limitation.
Manual semantic rejection and original as-run flags/source hashes are preserved.

Final verification passes **325 Flutter tests and 110 Python tests**, with clean
analysis and formatting across 114 Dart files. The 63 native tests per variant
remain the separately recorded prompt-v8 verification. Projection v8/guard v7 reject
older acceptance reuse; candidate inference is still held in normal builds. The
latest APK verification is build-only, not another emulator or phone acceptance run.
