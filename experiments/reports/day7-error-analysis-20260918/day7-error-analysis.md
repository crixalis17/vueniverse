# Day 7 v7 error analysis

## Pairwise movement

| Comparison | Improved | Regressed | Tied |
| --- | ---: | ---: | ---: |
| Vanilla BF16 → QLoRA NF4 | 140 | 31 | 39 |
| Vanilla BF16 → LoRA BF16 | 140 | 16 | 54 |
| QLoRA NF4 → LoRA BF16 | 33 | 33 | 144 |

## Error categories

| Model | Pass | Incomplete/neighboring | Finding-state error | Hard guard | Other semantic |
| --- | ---: | ---: | ---: | ---: | ---: |
| Vanilla BF16 | 3 | 170 | 0 | 37 | 0 |
| QLoRA NF4 | 137 | 41 | 22 | 7 | 3 |
| LoRA BF16 | 129 | 65 | 9 | 7 | 0 |

## Canonical-source weighted useful score

| Context family | Vanilla | QLoRA | LoRA |
| --- | ---: | ---: | ---: |
| discord_game_session | 38.3% | 71.7% | 66.7% |
| food_beverage_log | 38.3% | 88.3% | 80.0% |
| manual_journal | 33.3% | 78.3% | 73.3% |
| phone_call | 46.7% | 68.3% | 75.0% |
| recurring_meeting | 48.3% | 73.3% | 85.0% |
| screen_time | 45.0% | 75.0% | 81.7% |
| spotify_listening | 43.3% | 70.0% | 76.7% |

## Findings

- Both adapters improve substantially over vanilla across the paired frozen cases.
- LoRA's advantage over QLoRA comes from fewer failures, not from more strict passes.
- Remaining LoRA errors are concentrated in finding-state wording: supported cases can be weakened, while developing or null cases can sound too repeatable.
- Deterministic fallbacks protect delivery but remain raw-model failures in this analysis.
- Template diagnostics are descriptive checks for style collapse, not proof of memorization. A real memorization audit requires canary or nearest-neighbor testing against the training set.
