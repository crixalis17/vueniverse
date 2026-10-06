# LoRA emulator diagnostic run — October 6, 2026

Run ID `semantic_20261006_v1`. This is an inspected development investigation,
not release approval, independent accuracy or a clinical evaluation.

## Before generation

`preflight.json` records vocabulary-only checks on the exact checksum-verified
LoRA GGUF and pinned llama.cpp revision. All fifteen prompts fit4096 tokens after
reserving512 output tokens; actual input counts1571–1694. All fifteen continuation
grammars initialize. No model tensors, context or inference were loaded in this
host-only phase. The script and helper hashes identify the exact executed sources.

`PLAN.md` predeclares scope and stop rules. `run-config.json` pins actual inputs,
APK/native library, source fingerprints and the newly isolated API34 emulator.
Model and staged request hashes were separately verified inside that emulator.
Old emulators and owner data are outside this run. Normal LoRA remains held.

## Generation and review status

The batch stopped after its first case on a conservative guard flag. The answer
was schema-valid but copied instructions and failed manual grounding/usefulness.
The14 remaining cases were not attempted or retried. The owned emulator is stopped.
See [OUTCOME.md](OUTCOME.md), `outcome.json`, `captured-results.json` and the separate
constrained `judgments.jsonl`. LoRA remains held; no model improvement is claimed.
`fixture-capture.log` retains the synthetic-only checksummed transport;
`instrumentation.log` retains the expected stopped-test assertion. No raw thinking
or owner data is present. Final normal-hold Android host suite passes68/68; a
negative configuration test confirms fixture opt-in rejects `lib/main.dart`.

The harness preserves complete parsed final DTOs even when the real guard rejects
them. Deterministic fallback is recorded separately as delivery **simulation**;
the full coordinator/DB/UI is not executed here. Native diagnostics are text-free
counts/timing/stop reasons. Raw thinking, owner API keys and user records are not
captured. Schema and automated guard checks are not semantic verdicts.

## Check and decode retained capture

From the repository root:

```bash
PYTHONPATH=tooling/medgemma/src .venv/bin/python \
  -m vueniverse_medgemma.emulator_semantic_capture \
  /private/tmp/vueniverse-semantic-replay-20261006-v1.log \
  --run-id semantic_20261006_v1 \
  --package experiments/readiness/emulator-semantic-v1
```

After `run_complete_event=true`, add `--output` with a new absolute report path
to seal decoded results without overwriting existing evidence. Missing chunks,
wrong checksums, duplicate records and mixed requests/runs are rejected. Score
actual captured answers in a separate `judgments.jsonl` using the constrained
grounding/uncertainty/safety/usefulness rubric, not the frozen pending template.

Raw local fixture-only logs: `/private/tmp/vueniverse-semantic-replay-20261006-v1.log`
and `/private/tmp/vueniverse-semantic-instrumentation-20261006-v1.log`; exact safe
copies are retained above. The runner
stops only its owned disposable emulator after instrumentation exits; its AVD files,
model copies and logs remain recoverable. Nothing in this run starts cloud compute.

## Scope limits

Five inspected scenario clusters are not fifteen independent samples. Only LoRA
Q4 is run; vanilla GGUF is not cached, no download/BF16 comparison is performed,
and quantization or training quality cannot be causally isolated. Host tokenization
must be compared with actual Android native diagnostics for attempted cases.
Emulator timings are not Nothing Phone2 performance measurements. Useful final
answers, manual semantic approval and full production acceptance remain distinct.
