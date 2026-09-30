# Vanilla MedGemma baseline: experiment outcome

Run ID: `20260914-day4-smoke-us-central1b-01`  
Model: `google/medgemma-1.5-4b-it` at revision `91850547d9f0b2fdd21aa7c5f4f3d1a8a52c243b`  
Holdout: 210 messages-only records, SHA-256 `3b3af11158a05b9e9879b358a627c8379200623ac38d871ce07b832b3ac3ac4b`  
Hardware: NVIDIA L4, BF16; maximum new tokens: 192.

## Executive result

Vanilla MedGemma completed all 210 generations but produced no valid user-facing contract responses. Every raw output began with `<unused94>thought`, exposed planning text, and ended before a final JSON answer. This is an output-contract failure, not evidence of medical quality.

## Deterministic evaluation

| Metric | Result |
| --- | ---: |
| Raw JSON valid | 0 / 210 (0.0%) |
| Raw deterministic-gate accepted | 0 / 210 (0.0%) |
| Fallback used | 210 / 210 (100.0%) |
| Delivered result accepted | 210 / 210 (100.0%) |
| Peak GPU allocation | 8.44 GiB |
| Model-load time | 6.294 s |
| Mean generation time | 13.706 s |
| Mean generated tokens | 192.0 |

## In-thread semantic review

The assistant reviewed every raw output against its own evidence bundle and the deterministic outcome. No response reached a user-facing final answer, so grounding, uncertainty, safety, and usefulness are deliberately recorded as `null` rather than converted into artificial zero scores. Every case receives a `fail` verdict because there is no answer to evaluate.

| Semantic-review measure | Result |
| --- | ---: |
| Final answers available for semantic scoring | 0 / 210 |
| Thought traces leaked | 210 / 210 |
| Fail verdicts | 210 / 210 |
| Mean grounding / uncertainty / safety / usefulness | n.a. — no final answers |

## Slice consistency

| Slice | Value | Cases | Raw JSON valid | Semantic scoreable | Fail verdicts |
| --- | --- | ---: | ---: | ---: | ---: |
| Finding state | contradictory | 42 | 0 | 0 | 42 |
| Finding state | developing | 42 | 0 | 0 | 42 |
| Finding state | insufficient_data | 42 | 0 | 0 | 42 |
| Finding state | null | 42 | 0 | 0 | 42 |
| Finding state | supported | 42 | 0 | 0 | 42 |
| Ask intent | explain | 35 | 0 | 0 | 35 |
| Ask intent | observe_next | 35 | 0 | 0 | 35 |
| Ask intent | promotion_gate | 35 | 0 | 0 | 35 |
| Ask intent | what_disagrees | 35 | 0 | 0 | 35 |
| Ask intent | what_is_missing | 35 | 0 | 0 | 35 |
| Ask intent | what_weakens | 35 | 0 | 0 | 35 |
| Context family | discord_game_session | 30 | 0 | 0 | 30 |
| Context family | food_beverage_log | 30 | 0 | 0 | 30 |
| Context family | manual_journal | 30 | 0 | 0 | 30 |
| Context family | phone_call | 30 | 0 | 0 | 30 |
| Context family | recurring_meeting | 30 | 0 | 0 | 30 |
| Context family | screen_time | 30 | 0 | 0 | 30 |
| Context family | spotify_listening | 30 | 0 | 0 | 30 |

## Interpretation

1. The L4 runtime, model checkpoint, data projection, evaluator, and fallback path all worked.
2. The raw baseline does not satisfy the Vueniverse response protocol, so it cannot be benchmarked for explanation quality yet.
3. QLoRA should be compared on this exact frozen holdout and generation configuration. Any increase in valid user-facing answers becomes the first prerequisite for semantic-quality scoring.
4. The next semantic review must score raw QLoRA outputs separately from fallback-delivered responses.

## Limit

This report evaluates model behavior on the project’s model-facing experiment data. It does not establish clinical validity or causal effects between canonical events and health metrics.
