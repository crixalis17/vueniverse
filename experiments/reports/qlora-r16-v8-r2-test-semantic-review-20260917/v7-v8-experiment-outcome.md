# V7 vs v8-r2 frozen-test comparison

## Integrity

- V8-r2 cases: 210/210; native EOS: 210/210.
- V8-r2 schema valid: 207/210.
- V8-r2 raw guard accepted: 183/210.
- V8-r2 fallbacks: 27/210.
- V8-r2 average generation time: 14.22 seconds.

## Action-neutral semantic comparison

- V7: pass 137, review 41, fail 32.
- V8-r2: pass 101, review 73, fail 36.

V7 was re-expressed without penalties that arose only from its model-owned action field. V8-r2 action overrides are reported separately and do not change raw semantic verdicts.

## Interpretation

V8-r2 materially improves supported-state behavior: the model usually preserves strong repeated patterns instead of weakening every supported case. Insufficient-data and contradictory cases remain broadly useful. Developing cases still drift toward mixed, null, or superficially supported wording, so their central conclusion often requires review.

The main regression is deterministic grounding reliability. V8-r2 has 183 raw guard passes versus 203 for v7, mostly because generated prose mentions candidate, excluded, or completeness numbers without citing the matching metric. Three v8-r2 outputs are not schema-valid.

Safety and causal restraint remain strong in all parseable outputs. The next experiment should fix citation composition and developing-state summaries before changing rank or alpha.
