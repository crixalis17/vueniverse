# First-person local acceptance record

October 4–5, 2026. Source: experiment-branch implementation following `3572c3d`;
see journal J-090 for integration/failure history. This package contains no personal
health records or credentials. Detailed fixture tests remain executable source.

| Check | Outcome | Scope |
|---|---|---|
| Flutter regressions | 325 pass | Collection review, state/database/analytics, guard-v7 finite metric roles, retained-DTO replay and cache history |
| Static analysis | Clean | Application and integration sources |
| Python tooling | 110 pass | Artifact/evaluation/reproduction tooling and bounded optimized native token-lifetime regression |
| Android native unit tests | 63 pass per variant | LoRA and vanilla; candidate hold, prompt-v8 gate facts, strict bridge/grammar and artifact/download protocols |
| API 34 aggregate emulator integration | 27 pass | Mocked provider; real native encryption/reopen |
| Separate production-bootstrap integration | 1 pass | Actual main/ProviderScope/store graph; fabricated manual save/edit/reopen and ledger |
| Latest production-bootstrap rerun | 1 pass on October 5 | Current actual-main graph; fixture-only mock typing; production persistence/reopen/ledger real |
| Development-v2 integrity/guard | 30 cases / 10 clusters; all pass | Not independently adjudicated |
| Personal API / actual phone | Not run | No actual-phone readiness claim |

Collection emulator: isolated `WhyPulse_API_34`, serial `emulator-5582`, ARM64, read-only,
no snapshot saved. Store-erasure tests affected only the disposable running copy,
not the original AVD or owner's phone. Tests exercise UI, safe ledger pagination,
provider date/key handling, partial imports, repeat accounting and revocation races.
Native storage test verifies non-plaintext headers, distinct Demo/Live keys,
reopening, and manual check-in save/edit/reopen/delete. It does not establish
longitudinal analytical validity or LoRA quality.

The separate production-bootstrap test ran against the post-commit acknowledgement
split. Later source-lifecycle changes have local regressions, not a new aggregate
emulator pass: partial deletion cannot retain cached manual text, failed analysis
hides stale dependent views, older reads cannot overwrite a changed source, and
Ultrahuman resume neither requests data without a key nor advances its sync time.
Reminder freshness is reconciled despite post-commit analysis failure. The
missing-limit prior-finding query has a before-failure/after-pass regression.

The October 5 production-bootstrap repeat uses disposable `emulator-5580`, not the
earlier aggregate copy. Immediate injection reached the controller but real IME
restored old composing text during scrolling. Scoped fixture-only mock typing fixed
the harness conflict without weakening the pre-save, persisted edit, encrypted reopen
or receipt checks. Mock input is released before actual-main restart and in teardown.
The two failures and diagnostic rerun remain journaled. Physical keyboard is untested.

## Retained LoRA Android contract experiments

These are fixture-only native-runtime comparisons on disposable `emulator-5580`,
not the collection suite or the owner's phone. Three intents use the bundled
Snapshot in a new in-memory database; no personal API or owner store is accessed.

| Run | Outcome | Interpretation |
|---|---|---|
| [Baseline](phone-lora-contract-report.json) | Three timeouts; roughly 123 seconds per delivered fallback | CPU emulator/runtime limit, not a training-failure conclusion |
| [Native optimization](phone-lora-contract-optimized-report.json) | Roughly 45 seconds per intent; 0/3 raw schema passes | Faster generation, still invalid output; sampled-token lifetime defect made this run unsafe for model-quality inference |
| [Optimized, lifetime-safe](phone-lora-contract-optimized-safe-report.json) | No native timeouts; 0/3 raw guard passes, 3/3 safe fallback passes | Decoder lifetime hardened; actual Android model contract still not accepted |
| [Aligned v6, 384 tokens](phone-lora-contract-aligned-single-report.json) | 1 case; incomplete JSON; 60.494 seconds total | Training/app shape aligned, but no raw accepted answer |
| [Aligned v6, 512 tokens](phone-lora-contract-aligned-512-report.json) | 1 case; incomplete JSON; 67.630 seconds total | Increased bounded allowance did not establish valid output |
| [Bounded grammar v7, one intent](phone-lora-contract-grammar-single-report.json) | EOS; schema/automated guard accepted; 55.302 seconds total | Structural completion, not semantic acceptance |
| [Bounded grammar v7, all three intents](phone-lora-contract-grammar-aligned-report.json) | 3/3 schema valid; 1/3 automated guard accepted; 2 fallbacks; about 56–59 seconds | The accepted answer was manually rejected; candidate remains held |
| [Prompt v8, one controlled intent](phone-lora-contract8-single-report.json) | 1 `why_promoted`; schema valid; guard-v6 rejected; fallback; 72.738 seconds total | Complete parsed output manually rejected for instruction echo and wrong gate meaning; numerical quantities correct |

The stable sampled-token repair prevents a borrowed decode pointer outliving its
token storage. Its focused optimized regression passed with UBSan; no ASan pass
is claimed. LoRA-only phone contract version 7 adds request-grounded bounded GBNF
sampling; a real native literal/malformed-grammar check passed (2.491-second test
body), separate from the actual app-intent compatibility check. Grammar controls
structure, lengths and known IDs, never truthfulness or semantic usefulness. A safe
fallback is not a LoRA answer, and emulator timings are not phone benchmarks.

Manual review found the accepted answer said the same-direction share was “zero”
despite input consistency `0.75` and a later paragraph reporting `0.75`. It also
misrepresented unresolved caffeine context as a lack of usable comparisons. The
digit-based guard missed that spelled-out contradiction. Only recovered accepted
prose was semantically reviewed; rejected model prose was not captured and is not
silently scored. The full three-intent report preserves this distinction and the
as-built APK/contract hashes. No weights or training datasets were changed.

Normal `lora-v7` builds now report `contractUnverified` / `candidate_not_approved`
and cannot load/infer this held candidate. Prior accepted candidate cache rows are
preserved but cannot bypass current readiness. Explicitly restricted debug fixture
builds may evaluate it; default vanilla behavior remains separate and unchanged.

Reproduction requires an explicitly disposable emulator, never a physical owner
device. See [runbook](../../../docs/finetuning/first-person-phone-runbook.md).
Retained LoRA real-prompt acceptance remains open as recorded above; physical-phone
and live-account acceptance remain separate pending gates.

## Final local verification and safe retained build

[October 5 acceptance record](first-person-local-acceptance-20261005.json) separates
local tests, the current bootstrap journey, original aggregate checks and remaining
gates. [Native/build verification](final-native-production-hold-verification.json)
records 59 tests per variant, eight rejected unsafe configurations and a newly built
normal-main APK with both fixture capabilities off. It was update-installed and
opened only on disposable emulator 5580, then the clone and captures were stopped.
The ignored retained file is `build/phone-contract/production-lora-v7-held.apk`, SHA
`0eff1338f0c6015961345b1befec04f9ccf94f194c34131ee06684babe68b4b6`.
Do not restore the older pre-hold APK. No model inference, owner-store access or cloud
activity occurred in this final build/launch verification.

## Contract-v8 follow-up and build-only handoff

The prompt-v8 single-case report preserves complete checksummed parsed model output,
app delivery, input facts and constrained manual judgments. No raw thinking or owner
data was captured. Its guard-v6 flags include two documented heuristic false
positives; the manual rejection is independent of those flags. Guard v7 repairs
word-decimal parsing, and a model-free replay removes the numeric mismatch while
retaining the existing lexical causal flag. This is not a successful model result
or a new independent benchmark. The research model and datasets are unchanged.

The [prompt-v8/guard-v6 restoration record](phone-contract8-production-hold-verification.json)
describes the earlier disposable-emulator main launch and teardown, not guard v7.
The separate [guard-v7 build-only record](phone-contract8-guard7-build-only-verification.json)
records the new normal-main APK with fixture capabilities off and candidate still
held. It was **not installed, launched or used for inference**. Neither record
satisfies physical-phone, live-account or model-semantic acceptance.
