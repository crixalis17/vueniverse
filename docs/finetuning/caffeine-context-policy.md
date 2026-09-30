# Meeting context policy — analysis v3 / promotion v2

Implemented 2026-09-25 as roadmap P1.2. This is a conservative engineering policy,
not a validated biological model of caffeine, statistical adjustment or causal test.

## Why the change was needed

The former gate `no_dominant_measured_alternative` was unconditionally true.
The input mapper discarded structured check-in amounts, treating a zero-serving
report like a positive-serving report. Missing logs were counted only on the event
side. Those checks could not support the gate's claim.

The replacement is explicitly narrower: `caffeine_context_reported_zero`.
It says only that each included event/control pair has qualifying zero-intake
self-reports. It does not establish absence of all competing explanations.

## Windows and states

The policy examines the four hours ending at meeting start (the pre-meeting
heart-rate comparison) and the four hours ending at the matched control window's
end. Four hours is a configurable-by-code heuristic inherited from the previous
lookback, not a claim about physiological clearance.

| State | Evidence required | Promotion effect |
| --- | --- | --- |
| `recordedExposure` | A relevant, provenanced, finite positive serving amount | Blocks this gate; possible competing influence only |
| `reportedZero` | An explicit zero report covering the entire window, with provenance and valid coverage completed before the report timestamp | Passes this window only |
| `unknown` | No report, category/free text only, unscoped zero, incomplete coverage, missing provenance or malformed amount | Blocks this gate |

Coverage uses `coverage_start_utc` and `coverage_end_utc` in the existing check-in
JSON. Timestamps require timezone information. A complete negative report must cover
the entire required window; separate partial zero reports are not combined. Future-
dated reports are ignored. Retrospective reports may be used only after their report
timestamp has arrived. A positive report wins over a contradictory zero report.
Malformed relevant reports prevent a zero conclusion.

Example completed-window check-in value:

```json
{
  "manual_id": "local-checkin-id",
  "detail": "No caffeine during this period",
  "servings": 0,
  "coverage_start_utc": "2026-09-25T06:00:00Z",
  "coverage_end_utc": "2026-09-25T10:00:00Z"
}
```

The containing record's timestamp must be at or after 10:00 UTC in this example.
Free text is never interpreted as a negative intake report. Existing positive
`servings` logs remain useful without interval coverage; existing unscoped zero
logs remain unknown.

## Finding and evidence behavior

Every included pair must pass both sides for the gate to pass. A previously supported
comparison becomes developing if this gate fails. Null, contradictory and insufficient
states retain their earlier meaning; they are not forced into supported or developing.
Exposure on both sides still blocks the gate: equal serving counts do not establish
equal timing, dose, physiological effects or adequate adjustment.

`caffeine_unknown_pair_count` and `caffeine_exposure_pair_count` are separate metrics.
They can overlap if a pair has an exposure on one side and unknown context on the
other. `unresolved_influence_count` counts their union, once per included pair.
Excluded occurrences do not inflate these counts. Relevant event and control
check-ins become evidence dependencies, including reports spanning midnight or
entered retrospectively.

The model receives aggregate metrics, the gate and bounded uncertainty text, not the
raw log. The deterministic explanation names unresolved context; the approved next
observation asks for logs on both sides instead of proposing a quiet-buffer experiment
while this context is unresolved. UI copy no longer says all influences were reviewed
when the caffeine check passes.

## Demo and experiment boundaries

The existing demo measurements and raw check-ins are unchanged. Its main meeting
finding is now developing, with the same +11 BPM median difference. Updated demo
expectations and visible copy reflect that result. The old scenario ID is retained
for compatibility; its name is not the current finding state. The demo engine selector
is retained for existing stores; authoritative analysis/promotion versions are 3/2.
Fresh validation checks the new expected result; reopening existing stores recomputes
under the current policy through the normal refresh path.

Frozen v7 training data, adapter weights, model benchmarks and the archived research
paper are unchanged. These application-policy changes require fresh end-to-end
evaluation before any release claim.

## Remaining work

- Completed 2026-09-26: the check-in form now captures explicit servings and an
  optional completed time period using local date/time pickers. UTC persistence and
  save/edit/reload preserve the fields. Blank remains unknown; zero is never assumed.
  Shared form/repository validation rejects invalid amounts and incomplete/future
  periods. Save failures retain the form and do not insert an unsaved state entry.
  Physical-device usability validation remains part of the hardware/pilot phase.
- Validate the reporting burden and calibrate the conservative policy; do not relax
  it solely to restore the demo's old supported label.
- Complete symmetric illness/travel/exercise screening, stable recurring identity,
  statistical validation and dependent-artifact invalidation under P1.3–P1.5.
- The policy does not prove a lack of sleep, stress, medication or other influences.

## Verification

Twelve new policy/engine tests cover absent logs, positive/zero distinctions, both
comparison sides, malformed/provenance failures, partial coverage, future reports,
four-hour boundaries, midnight/retrospective coverage, contradictions, dependencies
and preservation of null outcomes. The full Flutter suite passed 108 tests;
`flutter analyze --no-pub` reported no issues. Two old full-suite expectations were
updated after asserting the intentional status and next-observation changes.
