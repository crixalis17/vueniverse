# Day 1 fine-tuning experiment contract

Status: frozen for the first learning experiment

## Purpose

Learn the complete supervised fine-tuning workflow by comparing the same MedGemma
checkpoint in three conditions:

1. Vanilla `google/medgemma-1.5-4b-it`.
2. The checkpoint with a LoRA adapter.
3. The checkpoint with a QLoRA-trained adapter.

The first experiment is not an attempt to maximize a medical accuracy score or teach
the model new clinical facts. It tests whether adaptation improves how consistently
MedGemma explains Vueniverse's already-computed, privacy-safe evidence.

## Frozen research question

> Can MedGemma explain associations between recurring meeting context and wearable
> heart-rate changes more consistently than vanilla MedGemma, while staying grounded
> in supplied evidence and avoiding causal or diagnostic claims?

## Model boundary

The model receives only the evidence projection defined by the existing MedGemma
tooling. Deterministic application code remains responsible for:

- joining calendar events to wearable samples;
- calculating before, during, after, and matched-control metrics;
- deciding exclusions and data completeness;
- assigning the finding state; and
- enforcing the output schema and safety guard.

Fine-tuning is therefore for evidence-grounded explanation behavior. The model will
not calculate health metrics from raw sensor samples and will not diagnose, prescribe,
or claim that a meeting caused a physiological change.

## Comparison controls

All three conditions must use:

- checkpoint revision `91850547d9f0b2fdd21aa7c5f4f3d1a8a52c243b`;
- the same system prompt and output schema;
- the same decoding configuration;
- the same immutable evaluation cases;
- the same evaluator and guard versions; and
- the same maximum output length.

Only the adapter/training method may change between conditions. Hyperparameters and
software versions must be recorded with each run.

## Evaluation families

The immutable evaluation set must include:

- supported repeated associations;
- null and contradictory findings;
- insufficient or incomplete wearable data;
- meetings that do not follow the apparent pattern;
- exclusion conditions such as exercise, illness, or travel;
- requests for diagnosis, medication, or causal certainty;
- requests to invent numbers or cite unavailable evidence; and
- requests outside the supported product intent.

The checked-in 17 fictional Wave 1 cases remain a permanent safety regression suite.
A separate anonymized real-data holdout will be created before training and must never
be included in the training examples.

## Measurements

For each model condition, record:

- output-schema validity;
- output-guard acceptance;
- citation and numeric grounding;
- unsupported causal, diagnostic, or medication claims;
- correct handling of null, contradictory, and insufficient evidence;
- deterministic fallback rate;
- latency and peak GPU memory; and
- a short categorized review of explanation usefulness.

These measurements describe behavior on this small experiment. They are not medical
validation and are not evidence of clinical safety.

## Data rules

- Use live wearable and canonical event data only after local anonymization.
- Do not upload names, email addresses, phone numbers, meeting links, account IDs,
  precise locations, or raw personal meeting titles.
- Preserve provenance and missingness; never replace missing values with zero.
- Split by time block or recurring-event group before generating training examples to
  prevent near-duplicate leakage.
- Freeze and hash the real-data evaluation holdout before producing training labels.
- Synthetic cases may supplement rare safety failures, but may not replace the real
  association cases that define the project's central experiment.

## Success criterion for the learning week

The week succeeds when the vanilla, LoRA, and QLoRA paths can be reproduced and their
outputs compared through one end-to-end evaluation loop. LoRA or QLoRA does not need
to beat vanilla on every metric; understanding why a run changed model behavior is the
primary objective.

## Out of scope for experiment 1

- medical diagnosis or treatment recommendations;
- causal inference from observational data;
- training directly on raw sensor streams;
- multimodal image fine-tuning;
- multiple users or population-level conclusions;
- production deployment; and
- replacing deterministic analytics with an LLM.
