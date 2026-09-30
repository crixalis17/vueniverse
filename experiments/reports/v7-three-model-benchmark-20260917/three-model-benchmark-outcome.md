# MedGemma v7-r2 three-model benchmark

## Integrity

All models used frozen test SHA-256 `3b3af11158a05b9e9879b358a627c8379200623ac38d871ce07b832b3ac3ac4b` and 210 cases. Judgments use raw outputs, not deterministic fallbacks. Action selection is application-owned and therefore excluded from semantic verdicts.

## Results

| Model | Pass | Review | Fail | Weighted useful score | Guard accepted | Fallbacks | Avg seconds |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Vanilla BF16 | 3 | 170 | 37 | 41.9% | 173 | 37 | 7.39 |
| QLoRA NF4 | 137 | 41 | 32 | 75.0% | 203 | 7 | 20.07 |
| LoRA BF16 | 129 | 65 | 16 | 76.9% | 203 | 7 | 15.50 |

## Interpretation

LoRA has the strongest balanced result: its weighted useful score is 76.9%, narrowly above QLoRA at 75.0%, and it halves semantic failures from 32 to 16. QLoRA still has more strict passes (137 versus 129) and lower memory use. Vanilla is fastest but usually ignores the requested state/intent emphasis.

LoRA and QLoRA tie on deterministic grounding at 203 guard-accepted outputs and 7 fallbacks. LoRA's remaining weakness is state wording: developing and null cases often use "same pattern appeared" language, while nine supported cases are weakened into no-clear-pattern wording.

No parseable output in the new LoRA review supplied diagnosis or treatment advice, and causal restraint remained intact.
