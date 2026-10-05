# Android semantic-contract audit: retained LoRA v7

October 5, 2026. Offline inspection of preserved synthetic research inputs and the
bundled Android development fixture. No owner data, new model generation, training
or cloud operation is required for this audit. This is diagnosis and development
evidence, not an independent final benchmark.

## Finding

The strongest established defect is training-to-app contract drift. The word
`developing` covers different evidence conditions in research and live analytics,
while the phone bridge omitted information needed to distinguish those conditions.
The failing output also invented a zero consistency value; no source mapping supplied
that zero. These observations do not prove training failed or isolate quantization.

| Aspect | Frozen v7 research developing examples | Actual Android development fixture |
|---|---|---|
| Count | 168 training; 42 test examples | One inspected fixture, three intents |
| Comparable windows | 2 or 3 | 8 |
| Disagreements | 0 | 2 |
| Direction agreement | `2 of 2` or `3 of 3` | Fraction `0.75` |
| Completeness | 75–92%, formatted as a percentage | Fraction `1.0` |
| Why developing | Targets uniformly say more comparable windows are needed | Comparison-quality gates pass; caffeine-context gate fails |
| Model input vocabulary | Ten legacy metric IDs, including `consistent_count`, `counter_count`, `median_difference` | App metric IDs and bare numeric values; no fabricated same-direction count |

The frozen training projection contains 840 rows. Its SHA-256 still matches the
[manifest](../../experiments/datasets/supervised-dataset-v7-r2-messages-projection/projection-manifest.json):
`c93692d78017134a29635e2a9376359a2defe6086a2ded028da67d1182a79463`.
The inspected developing held-out examples repeat the same narrow condition, so the
earlier research comparison did not test this context-blocked developing subtype.

## Established causes of information loss

The app's [promotion policy](../../lib/domain/analytics/meeting_analytics_engine.dart)
can produce developing results with enough comparisons when another promotion gate
fails. Its consistency is the fraction agreeing with the median direction, not the
count of positive differences. The bridge correctly forwarded `0.75`; renaming
`positive_count` as a same-direction count would be wrong for negative patterns.

The old phone bridge filtered out numeric gate flags and validated, but did not
present, the promotion-gate envelope. It retained influence IDs but dropped their
descriptions. It reduced the projection's exclusion map to occurrence keys such as
`exclusion_1`, losing workout/travel/illness reasons. These are meaningful omissions,
not evidence that more adapter rank or epochs would resolve them.

The [training target generator](../../tooling/medgemma/src/vueniverse_medgemma/training_dataset.py)
uses a single developing-state explanation family: scarce comparable windows.
That is appropriate for its generated inputs, but does not represent every condition
the app's analytical policy calls developing. The narrow label/template coverage is
not fixed merely by shuffling those examples.

## Generated contradiction and uncertainty

The [retained three-intent run](../../experiments/readiness/first-person-local-v1/phone-lora-contract-grammar-aligned-report.json)
has three schema-valid responses, one automated guard pass and two fallbacks. The
accepted explanation says both “zero” and `0.75` for the same-direction share.
The summary also confuses unresolved context with absent usable comparisons.
Manual review rejects it. Rejected model prose was not retained and is not scored.

Hypothesis: the narrow learned state template, unfamiliar metric presentation and
missing blocking reason encourage the incorrect scarce-data narrative. The specific
zero invention is not causally explained by this audit. Quantization, grammar and
decoding effects remain unisolated; no accuracy claim or retraining decision follows.

## Lowest-cost corrective sequence

1. Preserve exact app facts in phone contract v8: explicit passed/failed supplied
   gates, meaningful exclusion reasons and bounded influence descriptions. Missing
   gate data remains unknown; state alone never implies too few comparisons.
2. Add host-only golden tests for context-blocked developing, genuinely sparse
   developing, negative patterns, unknown/invalid gates and absent context identity.
   Do not relabel unavailable statistics or invent event identities.
3. Strengthen guard v6 with finite metric-role checks for explicit numerical
   assertions, including the observed zero paraphrase. An unrelated gate zero or
   window count cannot authorize another metric's number. This remains a bounded
   deterministic safeguard, not a semantic evaluator.
4. Preserve old accepted rows but prevent guard-5/prompt-7 cache reuse. Keep normal
   candidate inference held. Frozen datasets, adapters and historical reports stay
   unchanged; phone contract v8 is not training dataset v8.
5. After golden tests pass, consider one controlled development-fixture generation:
   unchanged weights, quantization, grammar and inference bounds, recording the new
   input/contract hashes and both automated and manual outcomes. Passing this adapted
   fixture would not establish fresh-set or actual-phone acceptance.

If input-contract repair is insufficient, first specify a development set covering
multiple developing subtypes and negative/contradictory cases. Independent held-out
evaluation, baseline comparison and explicit compute authorization must precede a
new training experiment. Do not start another paid run from this single failure.

## Sources and limits

Sources are the frozen messages-projection train/test files, projection manifest,
target generator, real analytical state logic, phone bridge and retained fixture
report linked above. Coverage counts were obtained by an offline bounded dataset
audit; they describe this preserved corpus, not real users. The original benchmark
remains inspected development evidence. No physical phone is connected, and no
personal API request or owner-store inspection occurred in this continuation.

## Implemented development checks

Phone prompt v8 and 20 dedicated contract tests preserve exact metrics, all seven
supplied gate facts, exclusion occurrence/category distinctions and bounded influence
descriptions. Full native suites passed 63 tests per variant. Missing gates are
explicitly unknown; conflicting status or invalid/unknown gate values fail closed.
The grammar, selected weights, quantization and 512-token/120-second bounds did not
change. Input hashes/projection version distinguish this contract from earlier runs.

The guard-v6 step introduced exact primary metric values for finite affirmative English
role/value assertions, rather than allowing a different cited metric's number to
authorize the claim. Nine pre-fix regression expectations failed; their positive
controls and the fixed suite pass. This closes recognized zero/cross-metric cases,
not every paraphrase or inaccurate conclusion. Conditional and negated zero,
one-to-one wording and missing-log caveats are not blanket-banned. Guard-5 rows are
retained but cannot satisfy the current cache; a regression verifies this.

The initial contract-v8/guard-v6 local app gate passed 287 tests with clean static
analysis and formatting; this historical count precedes the guard-v7 follow-up.
Collection-only UI checks also verify all saved reports remain accessible without
a finding, and distinguish non-caffeine report/save timestamps from event start times.
A bounded, checksummed fixture-only transport makes parsed accepted/rejected model
prose reviewable without long-log truncation; it never records raw thinking or owner
data. A subsequent one-case controlled generation is development evidence only and
must be reported separately, not added to the historical benchmark denominator.

## Controlled call and manual outcome

The [one-case prompt-v8 report](../../experiments/readiness/first-person-local-v1/phone-lora-contract8-single-report.json)
records exactly one `why_promoted` generation on the disposable CPU emulator:
71.995 seconds native generation and 72.738 seconds end to end. The weights,
quantization, grammar and inference bounds were unchanged. Checksummed capture
recovered the complete parsed model DTO and app delivery, with no owner data or
raw thinking. No second model call was made after the failure.

The output was schema-valid but manually **rejected** for instruction echo,
mid-clause fragments, internal gate-name leakage and a wrong qualitative claim
about the passed same-direction gate. Its numerical quantities were correct;
the earlier invented-zero contradiction did not recur. The delivered deterministic
fallback correctly described unresolved caffeine context, but is not a LoRA pass.
This remains one adapted development case, not a new benchmark or evidence that
the selected model is ready for users.

The as-run guard-v6 flags included two heuristic false positives: it read the
prefix of “zero point seven five” as zero, and matched “causes” inside the negated
phrase “not a count of distinct causes.” Manual rejection is independent of those
flags. The report retains the original guard version, flags and source hashes.

Guard v7 fixes complete finite word-quantity parsing: cardinals zero through
nineteen, optionally followed by `point` and up to nine word digits. Unsupported
compound quantities remain unknown instead of being read as their prefix. Exact
metric-role comparisons tolerate floating-point noise, not different supplied
values. The focused regression run passes 87 checks; a separate retained-DTO
replay passes without inference and no longer reports the numerical mismatch.
The existing lexical causal flag remains a documented false positive, not proof
of asserted causation. Finite recognizers do not verify arbitrary paraphrases,
qualitative conclusions or causal reasoning. Candidate activation remains blocked.

Next: define analytical goldens covering multiple developing subtypes, sparse and
negative patterns, and contradictory context before any further model experiment.
Use equivalent recorded contracts for baseline/candidate comparisons and keep
fresh final cases separate from these inspected development fixtures. Do not
retrain or increase adapter rank solely on the basis of this single call.
