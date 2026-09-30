# Corrected vanilla MedGemma evaluation

- Cases: 210
- Assembled JSON valid: 206/210 (98.1%)
- Full deterministic guard accepted: 173/210 (82.4%)
- Fallback used: 37/210 (17.6%)
- Semantic reviewer verdicts: pass 3, review 170, fail 37

## Interpretation

The corrected assistant-prefill protocol solved the thought-token and parseability failure. It does not by itself establish semantic quality: many accepted responses state a metric range while omitting the context label, contradictory counts, or missing-context framing that the held-out target emphasizes. The QLoRA comparison should therefore report both the assembled-contract guard and these semantic judgments.
