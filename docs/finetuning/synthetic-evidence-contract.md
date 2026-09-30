# Synthetic calibrated evidence contract

Generator version: 3  
Status: Day 2 complete

## Purpose

This contract produces private, reproducible model inputs for the model-only LoRA and
QLoRA experiment. It teaches MedGemma to explain an already-computed Vueniverse result;
it does not ask the model to analyze raw wearable streams or establish a real-world
meeting-to-health relationship.

## Private calibration boundary

The local Ultrahuman probe files are reduced into a protected calibration profile using:

- 11 local response files: seven consecutive days plus four historical checkpoints;
- metric availability and sample-count bands for `hr`, `hrv`, `night_rhr`, `spo2`,
  `steps`, and `temp`; and
- coarsened value quantile bands retained only in the local owner-only profile.

The profile has no raw measurements, timestamps, file names, event data, titles, or
account identifiers. The synthetic generator uses only coarsened heart-rate sampling
variability to vary synthetic exclusions and data-completeness cases. It does not copy
raw Ultrahuman physiology or timelines into a generated case.

## Synthetic case record

Each line in the generated JSONL has this shape:

```text
case_id
metadata
├── source = synthetic_calibrated
├── generator_version = 3
├── seed
├── scenario
├── calibration_mode = coarsened_sampling_variability
└── synthetic_event_context
    ├── category = recurring_one_to_one
    ├── recurrence_pattern = weekly | biweekly | weekday_sequence
    └── duration_minutes = 25 | 30 | 45 | 60
request
└── ExplainerRequest schema version 1
```

`request` is validated through the repository's existing strict Pydantic
`ExplainerRequest` contract. It contains only aggregated evidence metrics, exclusion
identifiers, counterevidence availability, unresolved context identifiers, allowed next
observations, a supported intent, and a question.

## Synthetic scenarios

The initial sample balances five states:

| Scenario | Meaning |
| --- | --- |
| `supported` | Four or more comparable synthetic repeats with a consistent material difference |
| `developing` | A material pattern appears in fewer than four comparable repeats |
| `null` | Comparable repeats show no material repeated difference |
| `contradictory` | Comparable repeats show mixed directions |
| `insufficient_data` | Too few comparable repeats or low synthetic completeness |

Synthetic aggregate metrics follow the application’s established interpretation:

- a pre-event window is compared with a matched no-event control window;
- the existing product engine defines pre-event as 15 minutes, primary recovery as 15
  minutes, a recovery horizon of 60 minutes, and minimum heart-rate coverage of 75%; and
- the model sees only the resulting counts, differences, ranges, and completeness—not
  underlying windows or samples.

## Privacy and integrity checks

- Generated records contain no `Ultrahuman` label, timestamps, real event titles,
  names, email addresses, meeting links, source IDs, or raw sensor values.
- Every record is deterministic for its seed.
- Every generated request passes `ExplainerRequest` validation.
- Every record is marked `synthetic_calibrated`; it cannot be mistaken for a real
  personal observation.
- The profile and generated JSONL remain in the ignored `tooling/medgemma/outputs/`
  directory with owner-only file permissions.

## Current artifact

The validated Day 2 sample is local-only:

```text
tooling/medgemma/outputs/finetuning/synthetic-evidence-sample-v3.jsonl
```

It contains 60 unlabeled evidence cases. Day 3 will create training labels, split cases
by synthetic scenario family to prevent leakage, validate all final JSONL, and produce
the immutable evaluation holdout.
