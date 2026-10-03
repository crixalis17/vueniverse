# Control allocation and evidence freshness — analysis v6

Only eligible event windows participate in baseline allocation. Calendar context,
recorded influences, provenance and event coverage are checked before assignment,
so excluded events cannot consume scarce controls. The engine builds all valid
candidate windows and applies deterministic maximum-cardinality, minimum-total-cost
bipartite matching. Cost is calendar-day distance then weekday match; it never uses
heart-rate effect size or model output. Controls are unique. Distinct assigned
windows that overlap because meeting start times shift are both rejected as a
conservative fallback; reoptimizing under interval conflicts remains future work.

Recorded offsets partition measurements. Mixed-offset event windows are excluded;
mixed-offset controls are rejected. Cross-offset baselines are not invented without
reliable timezone identity. This safely handles observed transitions by abstaining,
but does not implement IANA/DST reconstruction. Sub-minute boundaries are half-open:
samples before start or at/after end are excluded. Nonfinite/nonpositive samples do
not contribute to measurement or coverage.

The main demo now has 8 usable pairs, 6 positive differences and 2 contrary
observations, with median +11 bpm, positive range +8–14 bpm and recovery 42 minutes.
There are 8 matched controls, because the four excluded meetings reserve none.
Historical v4/v5 descriptions record their actual earlier allocations and are not
rewritten. The raw fixture and training datasets remain unchanged.

## Non-destructive invalidation

EvidenceValidityRepository is the shared read-only freshness boundary. Current use
requires non-stale/non-invalidated evidence, a completed analysis with current
analysis/promotion versions, the same canonical-input hash and an active finding.
New records can change control choice or cohort ranking even when they were not
dependencies of the previous selected windows, so the full canonical hash is checked.
This conservatively refreshes even for changes outside the analysis window.

Live evidence reads, Explorer/Explainer projections, replay, cached answers and
post-inference delivery use the check. Experiment starts resolve the series from
the backing evidence's included event windows. Stale protocols are exposed as
invalidated without erasing them; resume, adherence updates and result writes are
blocked. New exports require current evidence, and canShare refuses old snapshots
after their evidence changes. Historical files and conversations remain retained.

Recomputation hashes canonical inputs into the evidence payload and reuses only the
active finding with matching policy/input versions. A nonce separates replacement
runs even when the app's demo clock is fixed. Superseded evidence is not resurrected
through a historical same-hash cache lookup.

An initial broad-delete proposal was rejected by automatic approval review. The
implemented design uses fail-closed read/use checks instead and deletes no historical
chats, explanations, experiments or exports. Existing source-deletion behavior is
unchanged. Already exported external copies cannot be revoked by the app. Automatic
cancellation of already scheduled reminders and source-deletion hardware checks
remain separate readiness tasks.

The development pipeline also caught two deterministic fallback defects. A safe
phrase containing "treated" triggered the treatment substring guard; wording was
changed rather than relaxing the guard. The `observe_next` summary formerly copied
intervention parameters into measured numeric prose. Parameters now remain in the
exact-approved observation field, with a nonnumeric summary. All 30 generated
development cases pass the unchanged guard; no semantic safety claim follows.
