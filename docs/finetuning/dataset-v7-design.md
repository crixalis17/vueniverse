# Dataset v7 design: state- and intent-conditioned explanation

Status: local balanced/interleaved corpus and shuffle safeguards implemented; GPU pilot not started  
Scope: model-facing evidence explanations for Vueniverse; no diagnosis or causal claim

## Incident finding

The v6 failure was not evidence that rank 16 was too small. It exposed a training-order
defect and an incomplete learning objective.

The v6 train file contains exactly five contiguous state runs:

```text
contradictory       336 rows
developing          336 rows
insufficient_data   336 rows
null                336 rows
supported           168 rows
```

The custom trainer reads this file in order, uses microbatch size one, performs an
optimizer update after every row, and never shuffles. The supported block is always last.
Large loss resets appear at the state boundaries, and the final adapter emits the last
state's “stands out” behavior for every validation state. This is sequential forgetting,
not a shortage of examples.

The training-time validation loss also used only the first validation row. It could not
measure the 5 × 6 finding-state/intent grid and therefore could not detect either state
collapse or intent collapse.

## What established practice says

- Google's Gemma tuning guidance describes tuning data as input/expected-response pairs
  with multiple variations of the target task, and recommends success, failure, and
  boundary tests on requests not used for training.
- Hugging Face TRL supports conversational prompt-completion datasets and completion-only
  or assistant-only loss. Prompt tokens should not dominate the objective.
- LIMA, AlpaGasus, and Llama 2's SFT report all emphasize carefully curated, high-quality
  instruction examples over simply adding more noisy or repetitive rows.
- Research on instruction-tuning diversity reports that both quality and diversity matter,
  including worst-case performance rather than aggregate counts alone.
- Preference trainers such as DPO use explicit prompt/chosen/rejected triples. This is a
  suitable second stage for hard negative responses, but it is not a substitute for a
  correct SFT dataset and sampler.

Primary references:

- Google Gemma fine-tuning: https://ai.google.dev/gemma/docs/tune
- TRL SFT trainer: https://huggingface.co/docs/trl/sft_trainer
- TRL dataset formats: https://huggingface.co/docs/trl/dataset_formats
- LIMA: https://arxiv.org/abs/2305.11206
- AlpaGasus: https://arxiv.org/abs/2307.08701
- Llama 2 SFT: https://arxiv.org/abs/2307.09288
- Data Diversity Matters for Robust Instruction Tuning: https://arxiv.org/abs/2311.14736
- TRL DPO trainer: https://huggingface.co/docs/trl/dpo_trainer

## Product boundary

The deterministic analytics engine owns the correlation calculation and finding state.
MedGemma does not discover whether a pattern is supported from raw wearable events. It
receives a validated EvidenceBundle and explains that state in bounded language.

Application-owned fields:

- schema version;
- opaque context reference;
- analytics finding state;
- allowed citations, unresolved influences, and next observations;
- final schema validation and deterministic fallback.

Model-owned fields:

- state-faithful plain-language explanation;
- evidence selection appropriate to the question;
- non-causal uncertainty wording;
- an allowed next observation only when the intent calls for one.

This division prevents a generative model from silently overriding the analytical engine.

## v7 record design

Use an explicit conversational prompt-completion record. Compute loss only on the
assistant completion. Keep provenance outside the model-facing prompt.

```json
{
  "prompt": [
    {"role": "system", "content": "<versioned instruction>"},
    {"role": "user", "content": "<EvidenceBundle and response contract>"}
  ],
  "completion": [
    {
      "role": "assistant",
      "content": {
        "finding_state": "contradictory",
        "answer_focus": "what_disagrees",
        "summary": "The windows moved in different directions, so this is not a repeated pattern.",
        "paragraphs": [],
        "uncertainty": "This comparison does not establish why heart rate changed.",
        "unresolved_influence_ids": [],
        "next_observation_id": null
      }
    }
  ]
}
```

`finding_state` and `answer_focus` are explicit auxiliary targets at the start of the
completion. They make state and intent independently measurable. The narrative remains
required; the task is not reduced to structured classification.

## Balanced factorial design

The core dataset is a balanced 5 × 6 factorial grid:

- states: supported, contradictory, developing, insufficient_data, null;
- intents: explain, what_weakens, what_is_missing, what_disagrees, observe_next,
  promotion_gate;
- canonical context families: all seven supported families;
- at least four distinct safe context references per family;
- equal row count in every state × intent cell.

Start with 28 examples per cell: 840 high-quality rows total. Do not duplicate rows merely
to change class weight. If a cell needs more weight, create a genuinely different evidence
configuration and response, or use an explicit sampler weight recorded in the run config.

## Counterfactual twin groups

At least half of v7 must be organized into contrast sets. A contrast set holds context,
question wording, and non-decisive details stable while changing the decisive evidence:

| Twin | Decisive evidence | Required interpretation |
| --- | --- | --- |
| Supported | high consistent count, material repeated effect | repeated pattern stands out |
| Contradictory | matched supporting and counter windows | directions disagree |
| Developing | consistent direction but too few repeats | early; more windows needed |
| Insufficient | too few usable windows or low completeness | cannot compare fairly |
| Null | adequate data but small/inconsistent effect | no clear repeated pattern |

For each evidence configuration, create only the six real user intents. The expected
answer must visibly change with intent, not just append a short suffix to an otherwise
identical template.

## Intent-specific answer contract

| Intent | Required answer focus | Next observation rule |
| --- | --- | --- |
| explain | state and strongest evidence | null unless state policy requires it |
| what_weakens | exclusions, counterevidence, and limitations | normally null |
| what_is_missing | missing coverage or comparable windows | allowed when it resolves the gap |
| what_disagrees | opposing windows/evidence | normally null |
| observe_next | one approved observation | required |
| promotion_gate | whether the deterministic gate is met and why | required only when more evidence is the reason |

Each intent needs a distinct answer rubric and required/forbidden evidence fields. A label
fails preflight if it answers a different intent even when its numbers are grounded.

## Response variation without semantic drift

For each state × intent cell, use multiple human-reviewed phrasings, but keep a stable
semantic skeleton:

1. direct answer to the requested intent;
2. state-faithful evidence paragraph;
3. data-quality/counterevidence paragraph when relevant;
4. non-causal uncertainty;
5. allowed next observation only under the intent rule.

No phrase may appear as the opening interpretation in more than 10% of a state. Avoid a
single universal sentence such as “it stands out here.” Numbers, citations, and state
language must be derived from the same EvidenceBundle.

## Split and leakage policy

- Split by context reference and scenario group, never by individual row.
- Keep all six intents and all contrast twins for a reference in one split.
- Hold out complete reference groups and evidence configurations, not merely paraphrases.
- Maintain separate validation and final test sets. Never use test outcomes to revise v7.
- Validation and test must each contain every state × intent × context-family slice where
  sample size permits.

## Training sampler and objective

The training file order must not define the curriculum.

1. Create a deterministic seeded permutation and record its hash.
2. Build stratified macro-batches containing every state × intent cell before an optimizer
   update. With microbatch size one, use gradient accumulation across the 30 cells.
3. Reshuffle contrast groups for every epoch without splitting a group across train/holdout.
4. Use completion-only/assistant-only loss and verify the token mask in a unit test.
5. Start at LoRA learning rate `1e-4`, not `2e-4`; choose the final rate using the gated
   pilot rather than one-example loss.
6. Log microstep, optimizer step, epoch, state, intent, loss, gradient norm, and learning
   rate separately.

The initial experiment remains rank 16, alpha 32, dropout 0.05, and q/k/v/o targets. This
isolates the data and sampler change.

## Validation during training

One scalar loss is insufficient. Use a fixed 30-case sentinel set with one case for each
state × intent cell and report:

- exact `finding_state` accuracy;
- exact `answer_focus` accuracy;
- state confusion matrix;
- next-observation policy accuracy;
- schema and deterministic guard acceptance;
- per-cell completion loss;
- worst-cell accuracy, not just average accuracy.

Evaluate the sentinel at the initial adapter, after each checkpoint, and at the end. Stop
early if the worst-cell metric degrades for two checkpoints or any predicted state exceeds
50% of all sentinel outputs.

## Cost-control ladder

No full run is allowed before these gates:

### Gate A — local static audit (no GPU)

- exact 5 × 6 balance;
- zero group/reference leakage;
- zero exact duplicate completions;
- all labels pass schema, citation, number, state, intent, and next-action checks;
- maximum contiguous same-state run after ordering: two;
- every macro-batch contains all 30 state × intent cells;
- assistant-token mask verified on examples from every state;
- full manual review of the small gold core and stratified review of generated variants.

### Gate B — tiny GPU pilot

- 60 examples: two balanced macro-batches;
- train 10–20 optimizer steps;
- evaluate the 30-case sentinel;
- require at least 80% state accuracy and no predicted-state collapse;
- stop immediately if one state exceeds 50% of predictions.

### Gate C — medium pilot

- 300–420 examples, still exactly balanced;
- evaluate at each checkpoint;
- require state accuracy at least 90%, intent accuracy at least 85%, worst state at least
  80%, safety 100%, and deterministic guard at least 98%.

### Gate D — full v7 run

Run the 840-row full dataset only after Gate C passes. Evaluate the frozen validation set
before touching test. A failed gate changes data or sampling locally; it does not trigger
another blind full run.

## Optional preference stage

Do not begin with DPO. If balanced SFT passes state classification but still produces the
wrong narrative preference, build explicit hard-negative pairs:

```text
prompt:     contradictory EvidenceBundle + what_disagrees request
chosen:     mixed-direction explanation with counterevidence
rejected:   the observed “pattern stands out” collapsed response
```

Use actual failed generations as rejected responses. This teaches the exact preference
boundary and follows TRL's explicit prompt/chosen/rejected format. It requires a separate
pilot and cost approval.

## Definition of ready to retrain

Another paid training run is authorized only when the repository contains:

- v7 dataset and hashes;
- contrast-set manifest;
- balance and ordering report;
- label semantic audit report;
- token-mask unit tests;
- seeded stratified sampler tests;
- 30-case sentinel set and state/intent evaluator;
- a dry-run report proving every gate can fail correctly;
- an estimated pilot and full-run cost ceiling.

## Implementation checkpoint — 2026-09-17

Implemented locally:

- canonical dataset revision `supervised-dataset-v7-r2` built from clean v5 rather than
  duplicated v6;
- 840/210/210 train/validation/test rows;
- 30 state × intent cells with exactly 28 train rows each;
- deterministic dataset interleave with maximum same-state run of one;
- independent seeded trainer-side stratified shuffle, so file order cannot recreate v6;
- training-start audit containing the consumed-order SHA-256, cell counts, and maximum
  same-state run;
- v7 cloud whitelist with unchanged privacy, hash, reference, split, and projection gates;
- messages-only projection and frozen validation/test hashes;
- complete MedGemma tooling suite: 76 tests passed.

Canonical messages-only train SHA-256:
`c93692d78017134a29635e2a9376359a2defe6086a2ded028da67d1182a79463`.

Still required before a paid full run: add the 30-case semantic sentinel and its state,
intent, next-action, confusion-matrix, and worst-cell gates; then run only the tiny Gate B
pilot.
