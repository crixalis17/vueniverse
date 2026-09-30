# QLoRA rank-16 v6 validation evaluation

## Run integrity

- Run status: complete
- Cases: 210/210
- Frozen validation SHA-256: b23a515c598cc337e3af388e61beb1aab167df3b6f6058d8efb67baed7c1f6d9
- Native EOS: 210/210
- Schema valid: 210/210
- Deterministic guard accepted: 208/210
- Fallbacks: 2/210
- Average generation time: 26.76 seconds per case
- Total generation time: 93.7 minutes, excluding model load

## Case-by-case semantic judgment

- Pass: 0/210
- Review: 42/210
- Fail: 168/210
- Grounding: pass 42, partial 168
- Uncertainty: pass 210
- Safety: pass 210
- Usefulness: partial 42, fail 168

## Main findings

The v6 adapter still predicts the supported “stands out” framing for all 210 cases. It therefore fails all 168 contradictory, developing, insufficient-data, and null cases. Those outputs often preserve the context and several numbers, but reverse the central analytical meaning.

The 42 supported cases preserve the main finding and evidence, but all 210 outputs select log_context regardless of ask_intent. The supported cases are marked review rather than pass because the response does not follow the requested intent or held-out next-observation target.

Two insufficient-data cases also fail the deterministic number-grounding guard. Both claim that 2 of 6 windows were used even though their own first paragraph says 1 of 1 was comparable. The deterministic fallback repaired delivery, but the raw model outputs remain failures.

## Comparison with v5

The v6 rebalancing did not correct state collapse. Like v5, it produced supported framing for every state. It also exhibits intent collapse: the next action is log_context in every case. Changing rank or alpha is not yet justified; the training labels and sampling strategy must make finding_state and ask_intent impossible to ignore.

## Recommended next experiment

Build paired contrastive examples that keep the same context and similar numbers while changing only finding_state or ask_intent. Add direct state and intent targets to the loss-bearing answer, reduce repeated supported phrasing, and add a validation gate that classifies the generated semantic state before another full run. Keep rank 16 and alpha 32 so the data change remains isolated.
