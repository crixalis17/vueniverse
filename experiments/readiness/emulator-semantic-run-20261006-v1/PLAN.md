# Bounded LoRA emulator development replay

Declared before generation, October 6, 2026. User approved proceeding after the
sealed package. No training, paid compute, downloads or owner data access.

- Run ID: `semantic_20261006_v1`; parent source commit `f53d68e` plus as-run source hashes.
- Runtime: LoRA v7 Q4_K_M only, exact SHA/size in the retained candidate manifest.
- Input: unchanged `emulator-semantic-v1`, 15 requests in its declared order;
  five correlated inspected-development families, not a hidden generalization set.
- At most one uncached call per request. No successful-answer search or retries.
- Production prompt8, authoritative JSON prefill, exact frozen GBNF, greedy sampling,
  output512/context4096/native120-second bounds unchanged. Cold model load is outside
  the inference bound. Outer instrumentation/test transport ceiling45 minutes.
- New isolated API34 ARM64 Google Play cached image; 8GB emulator RAM/4cores,
  headless, no snapshots. Existing WhyPulse emulators and owner stores untouched.
- Direct Pigeon runtime replay plus real Dart guard7. No analytical recomputation,
  ExplanationCoordinator, cache/database or UI route. Delivered fallback is a
  separately recorded **simulation**, never a model success or full app acceptance.
- Preserve complete final parsed DTOs even if rejected, all runtime metadata,
  failure, guard outcomes and native text-free token/timing/stop diagnostics.
  No raw generated reasoning, API key or user records are logged.
- Capture uses bounded16KiB checksum chunks and one unique capture identity per
  case; missing/oversize/corrupt capture is a failure, not truncated or completed text.
- Stop on runtime/artifact/context/grammar/capture failure, crash/OOM, contract
  identity mismatch or critical clinical/privacy guard flag. Ordinary incomplete
  or semantically weak outputs remain recorded failures, not retry triggers.
  Lexical causal flags need manual review because negation can trigger them.
- Review every captured output against the exact request with grounding,
  uncertainty, safety and usefulness scores0–2 and a constrained verdict/rationale.
  Report raw schema, guard, manual verdict, fallback and time separately. Record
  attempted/unattempted cases distinctly. All15 meaningful answers are needed for
  the small inspected model-enabled gate; passing does not establish medical utility.
- Normal candidate activation stays OFF; historical weights/datasets/reports unchanged.

Host vocabulary-only preflight passed15/15: actual tokens1571–1694, all fit after
reserving512; all15continuation grammars initialize. See `preflight.json` for real
token IDs, hashes, library/revision fingerprints and limitations. No tensors,
context or inference were loaded for that phase. All prompts are ASCII, so the
host UTF8 prompt bytes match JNI's modified-UTF8 conversion for these fixtures.
Android native diagnostic token counts must be checked against those host counts
for actual attempted cases; source equivalence alone is not Android execution proof.

Vanilla GGUF is not cached and is not evaluated/downloaded. The frozen vanilla
prompt v5 remains a known semantics/decoding confound, not a training-only ablation.
These records cannot determine whether quantization, rank or training itself is
the cause without further controlled evidence. Parallel workers prepared the
helper/harness but hit their account usage limit; root completed their verification.
