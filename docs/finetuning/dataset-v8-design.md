# Dataset v8-r2: state-invariant explanations and application-owned actions

## Why v8 exists

V7 repaired the v6 state collapse, but the 210-case semantic review still found two
systematic failures: supported cases were often weakened into cautious neighboring
states, and all 35 `observe_next` outputs selected the wrong action. The second failure
is an architecture problem: a language model should explain evidence, not choose a
deterministic UI action from an allow-list.

## Ownership boundary

The model owns explanatory prose, citations, uncertainty, and unresolved-influence
references. The application owns `next_observation_id`. It resolves that value from the
already-known finding state, ask intent, and approved-action map after generation.

Evaluation keeps both layers visible:

- raw model output is scored without correction;
- fallback remains a separate recorded event;
- delivered output applies the deterministic action policy;
- reports retain the model value, delivered value, and whether an override occurred.

This prevents a delivery correction from being counted as a model-quality gain.

## Label contract

Each recurring context still has six intent variants. Across those variants:

1. The summary is identical and states only the analytical finding state.
2. The paragraph answers the requested intent using cited values.
3. The uncertainty statement remains non-causal and non-diagnostic.
4. `next_observation_id` is always `null` in the model target.
5. Context references remain split-isolated and opaque.

The held-out evidence inputs are inherited from v5. Validation and test expected
assistant outputs are revised to this contract, so the evidence remains comparable
while semantic judging uses the intended answer.

## Dataset and gates

- Train / validation / test: 840 / 210 / 210.
- Training cells: 30 state × intent combinations, 28 examples each.
- Maximum contiguous same-state run: 1.
- Guard-valid labels: 1,260 / 1,260.
- State-invariant summary violations: 0.
- Non-null model action targets: 0.
- Context-reference split overlap: 0.
- Model-facing provenance markers: 0.
- Cloud preflight: passed.

The first local v8 draft passed structural gates, but a manual 30-cell review found
three semantically awkward generic templates: zero excluded windows described as a
limitation, complete inclusion described as missing data, and zero counter-windows
described as disagreement. V8-r2 replaces those with state-specific intent answers.
The first draft remains local but is superseded and must not be uploaded.

V8-r2 SHA-256:

- Train: `2ece6644d1ec7f5f782dd1749ae320b3f0d95bcb17f976afac3b41b091f290d5`
- Validation: `efff0efb8d20698d2520f14fcf938c601a3efa8088ae07e96b6ee74d0705f94a`
- Test: `f3fc362f8a358dadbb7ff8576cf649a172f3c4f1553d4094b965390ddd9002a9`
- Holdout manifest: `0de766c7505702d3a20d89e829a8137f95636b2035bc8118e19021e9deff86f9`
- Quality report: `ab2cb1008e7187455f49b7d19743ddddb3d6d149a62051c84f5ec94a9aed04dc`

## Before another paid run

Run the full pinned test suite, then inspect at least one example from every state ×
intent cell. Only after those gates pass should the messages-only v8 projection be
uploaded. A tiny smoke run and 30-cell sentinel evaluation must pass before a full
one-epoch experiment is authorized.
