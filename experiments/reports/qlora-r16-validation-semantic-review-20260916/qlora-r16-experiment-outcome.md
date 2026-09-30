# QLoRA rank-16 validation evaluation

## Run result

- Cases: 210
- Schema-valid: 210/210
- Guard-accepted: 210/210
- Fallbacks: 0
- Natural EOS completions: 210/210
- Average generation time: 22.94 seconds per case
- Generation time: 80.3 minutes, excluding model load

## Manual semantic review

- Pass: 42/210 (20.0%)
- Fail: 168/210 (80.0%)
- Grounding: pass 42, partial 168
- Uncertainty: pass 210
- Safety: pass 210
- Usefulness: pass 42, fail 168

## Main finding

The adapter learned a clean, grounded response template but collapsed the finding-state distinction. It correctly handles all 42 supported cases. In all 168 contradictory, developing, insufficient-data, and null-pattern cases, it reuses the supported framing and says the pattern “stands out.” The numerical facts are mostly preserved, but the central interpretation is wrong. This is a semantic failure that the deterministic schema and guard checks do not detect.

## Vanilla comparison

The earlier vanilla review recorded pass 3, review 170, and fail 37. That review used a more permissive evidence-overlap rubric, so its verdict counts are not a strict apples-to-apples leaderboard. The reliable comparison is behavioral: QLoRA eliminates schema/guard/fallback failures and produces much more specific answers, but it overfits to the supported-answer template and loses state calibration.

## Recommendation

Do not increase LoRA rank yet. First rebalance or restructure training so finding_state and ask_intent visibly control the target response. Add contrastive examples that share the same context and numbers but differ only in state, upweight non-supported states, and add a semantic state-consistency check to evaluation. Then retrain the same rank-16 configuration before changing rank or alpha.
