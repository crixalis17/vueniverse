# WhyPulse Demo video runbook

Use Demo mode as one complete evidence-to-action story. The recurring 1:1 and
heart-rate result is the hero story because its numbers are recalculated from
the canonical Demo store. Other cards are useful supporting shots, but their
labels must remain visible so a calculated result is never confused with a
seeded receipt or roadmap preview.

## Before recording

1. Open **Settings → Demo Data → Reset deterministic demo** to load fixture
   v4.
2. Return to **Today** and confirm **DEMO** is visible.
3. Open **Run the guided Demo**. Its actions provide the recording order.
4. If a model runtime is available, let the runtime receipt identify it. If it
   is unavailable, keep the deterministic backup explanation on screen; never
   describe backup text as MedGemma output.

Fixture v4 contains 30 consecutive populated days and 2,990 canonical records:

- 2,800 heart-rate samples, including 44 ambient readings per day alongside
  three daily anchors and the minute-level analytical windows;
- 30 HRV samples, 30 step samples, and 30 sleep intervals;
- 10 workouts and 30 activity intervals;
- 30 privacy-safe past Calendar events—12 analytical recurring 1:1s and 18
  contextual events—plus 30 detailed manual check-ins;
- 2 completed Demo experiment protocols with occurrence/result receipts.

## Primary 90-second story

| Time | Screen | What to show | Voice-over point |
| --- | --- | --- | --- |
| 0:00–0:10 | Observe | Thirty days, 2,990 records, ambient and minute-level heart rate, daily activity and check-ins, and redacted Calendar context | The story begins with inspectable local source data. |
| 0:10–0:24 | Moment Fingerprint | Eight included traces against matched no-meeting controls | Similar moments are aligned before they are compared. |
| 0:24–0:38 | Evidence | 12 candidates, 8 included, 6 positive, 2 counterexamples, and four explicit exclusions | The analytical engine keeps disagreement and leaves out travel, illness, and workout-confounded windows. |
| 0:38–0:54 | Explanation | Citations, uncertainty, model name, latency, and actual runtime receipt | MedGemma may narrate the checked evidence; it cannot change the numbers or evidence state. |
| 0:54–1:06 | Ask WhyPulse | Ask **Which meetings do not match?** and **What data is missing?** | Answers stay within the current evidence bundle; medical or prompt-injection requests are blocked. |
| 1:06–1:20 | Test This | Quiet-buffer protocol, eligibility, consent, and three-meeting plan | A finding becomes a small, reversible personal test rather than advice. |
| 1:20–1:30 | Proof & Export | Evidence fingerprint, analytical version, runtime state, and local export controls | End on provenance and a receipt another person can inspect. |

The hero result must remain exact: 12 meetings checked, 8 fairly compared, 6
showing the pattern, 2 counterexamples, a median difference of +11 bpm, an
effect range of +8 to +14 bpm, and 42-minute recovery.

## Optional outcome montage

The scenario library contains 16 cards. Five are executed against canonical
records by the recurring-meeting heart-rate engine:

1. **Recurring 1:1 and heart rate — Supported:** the hero 12/8/6/2 result.
2. **Two meetings stayed near baseline — Null finding:** two usable windows,
   median −1.5 bpm.
3. **Mixed meeting response — Mixed:** one +14 bpm window and one −2 bpm
   counterexample.
4. **Early recurring-meeting signal — Developing:** two consistent windows,
   median +9 bpm, but the four-repeat gate is not met.
5. **Travel-confounded meeting — Needs data:** travel excludes the only event,
   leaving zero usable meetings.

Use the null, mixed, developing, and excluded cases as a fast montage after the
hero story. Together they show that the engine does not force every dataset
into a positive pattern.

The remaining cards have explicit boundaries:

- two **Lifecycle** receipts show Expired and Weakened history states;
- two **Demo Test** receipts show Strengthened and Inconclusive experiment
  outcomes backed by seeded protocols, occurrences, and results;
- seven **Illustrative** cards cover future sleep, activity, workout, HRV,
  illness-recovery, and coverage detectors. They are populated-data roadmap
  examples and never appear as current evidence or History calculations.

## What Flutter verification proves

Flutter tests verify deterministic fixture import and reopening, exact scenario
outputs, History truth labels, experiment persistence, bounded Ask routing,
output guarding, cache/evidence-version behavior, development-runtime envelope
validation, cancellation, timeout, and fallback behavior.

They do not prove physical-phone MedGemma generation, model-download completion,
latency, memory, battery, or thermal acceptance. Record those mobile gates
later on the target phone; do not turn a deterministic fallback or a Flutter
test into a phone-runtime pass.
