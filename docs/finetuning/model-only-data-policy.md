# Model-only data policy

Decision date: 2026-09-12

## Decision

The first fine-tuning experiment is a model-learning track. It will not connect an
Android phone, Google Calendar, Google Meet, or another canonical live-data source.

Ultrahuman remains the sole wearable source, but its raw data is used locally only to
calibrate plausible sampling density, missingness, heart-rate/HRV variation, sleep
context, and time-of-day patterns. It is not paired with fictional meetings, uploaded
to GCP, or included in training or evaluation JSONL.

## Training and evaluation data

All model-facing examples for this experiment are synthetic, privacy-safe evidence
bundles. Each bundle records `source=synthetic_calibrated` and includes a deterministic
seed and generator version. It contains synthetic canonical event timing and synthetic
wearable metrics calibrated from the local Ultrahuman profile.

Synthetic events must never be described as the user's real meetings. The training task
is to explain an already-computed evidence bundle, not to establish whether a real
meeting caused a real physiological change.

## What this validates

- LoRA and QLoRA training mechanics;
- adapter saving, loading, and inference;
- evidence-grounded structured explanation behavior;
- output-schema and safety-guard regression behavior; and
- reproducible evaluation and cost control.

## What this does not validate

- Vueniverse's real-world meeting-to-wearable correlation;
- calendar ingestion or Android permissions;
- calendar/Ultrahuman time alignment on a real timeline;
- clinical usefulness or safety; and
- behavior on another person's data.

Real Android Calendar integration remains a future product-integration experiment. It
must use the privacy-reduced flow documented in `canonical-event-source-audit.md` and
requires a real user-authorized event source.
