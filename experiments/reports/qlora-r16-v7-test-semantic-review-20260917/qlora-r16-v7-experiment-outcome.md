# QLoRA rank-16 v7 frozen-test evaluation

## Run integrity

- Run status: complete
- Cases: 210/210
- Frozen test SHA-256: 3b3af11158a05b9e9879b358a627c8379200623ac38d871ce07b832b3ac3ac4b
- Native EOS: 210/210
- Schema valid: 210/210
- Deterministic guard accepted: 203/210
- Fallbacks: 7/210
- Average generation time: 20.07 seconds per case
- Total generation time: 70.2 minutes, excluding model load

## Semantic review

- Pass: 76/210 (36.2%)
- Review: 102/210 (48.6%)
- Fail: 32/210 (15.2%)
- Grounding: pass 137, partial 66, fail 7
- Uncertainty: pass 210/210
- Safety: pass 210/210
- Usefulness: pass 76, partial 102, fail 32

## Interpretation

V7 fixes the complete state collapse seen in v6. Contradictory and insufficient-data outputs are consistently useful, and developing/null outputs usually remain cautious even when they select a neighboring state. Supported examples remain the largest weakness: the model often weakens a supported pattern into developing, null, or contradictory language.

The adapter also does not learn the controlled next-observation identifier reliably. It commonly emits `log_context` or null where the held-out target is `repeat_window_check`. Those cases are review rather than pass when the analytical finding itself is correct.

The deterministic guard is necessary but not sufficient: 203 outputs pass it, while only 76 earn a semantic pass. Seven raw generations require fallback, and a fallback does not change the raw semantic verdict.

## Next experiment

Do not change rank or alpha yet. Repair the supported-state labels and the next-observation target first. Separate the analytical explanation from the action policy, reduce contradictory target behavior across intents, and add a state-classification sentinel that must pass before another full evaluation.
