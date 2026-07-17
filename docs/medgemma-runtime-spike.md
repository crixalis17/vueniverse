# MedGemma 1.5 runtime spike

Date: 2026-07-16

## Scope

This spike replaces all conclusions from the older `google/medgemma-4b-it`
experiment. It uses only `google/medgemma-1.5-4b-it` and fictional WhyPulse
fixtures. No personal health, wearable, calendar, or raw event data was used.

The Explainer suite uses fictional repeated-meeting evidence and seventeen
cases: six supported product intents; diagnosis, prescription, causality,
generic chat, unrestricted timeline, prompt injection, invented-number, and
fake-citation boundaries; plus explicit null, contradictory, and
insufficient-data finding states.

## Reproducibility

- Source checkpoint: `google/medgemma-1.5-4b-it`
- Checkpoint revision: `91850547d9f0b2fdd21aa7c5f4f3d1a8a52c243b`
- llama.cpp revision: `5839ba352471b2a7b45e7ba401619a6896f10f8b`
- Host Python: 3.12.10
- Host runtime: llama.cpp with Metal on an Apple M4 Pro development machine
- Emulator: Android API 34, `arm64-v8a`, CPU-only llama.cpp
- Decoding: greedy, 4,096-token context, 384-token output ceiling
- Explainer prompt: version 2, SHA-256
  `575a1f5617dd6cce4695f06b08ae5deecd147d7abb93ff4daf7aff454b61e065`
- Pigeon runtime prompt: version 1, SHA-256
  `ed73f7103c8eebdfc80aa0cc8fc99fea8f52cb97be34a52bfa1f415c7f092095`
- Generated reports and model weights are local and ignored by Git

Artifacts:

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| F16 | 7,767,803,904 | `a765f81af049b1b08da974b4ed6977127af906e14e35be869af9bc920be4918d` |
| Q4_K_M | 2,489,894,144 | `4828aa086174fa34e570a6f289e9d17385542c21cdbbc7f0071d6d72d5c2774f` |
| Q5_K_M | 2,829,698,304 | `b85bbd8fb6b084b56bdd9dfe7abde958081e60c56888dbb135dc577dfb29df6e` |

The official BF16 Transformers checkpoint passed a text-only smoke test before
conversion. The CPU development-path run loaded in 1.49 seconds and generated
64 tokens in 8.57 seconds. It is a correctness baseline, not a mobile result.

## Safety and grounding contract

Explainer output schema v2 is deliberately deterministic-first:

- The model view omits exact metric values and raw counter-event IDs.
- The model may select only citation, unresolved-influence, and next-observation
  IDs enumerated by the current request's JSON schema.
- Generated prose containing a numeric value is rejected. The UI renders exact
  values by joining accepted citation IDs back to the EvidenceBundle.
- Schema, citation, grounding, or safety failure discards the generated output.
  There is no model repair call; a deterministic citation-backed fallback is
  delivered instead.

The fallback is part of the runtime contract. Raw model acceptance and final
delivered-output acceptance are reported separately.

The integrated versioned Pigeon contract now uses immediate deterministic
fallback after any schema, grounding, safety, or runtime failure. It does not
make a second model repair call, keeping latency bounded and preventing rejected
text from reaching the cache or UI. This integration decision has unified
ownership for the current task.

## Host comparison

Seventeen identical cases were run through each warm Metal-backed model instance.
RSS is host-process resident memory on a unified-memory Mac, not Android RAM or
dedicated VRAM.

| Measure | Q4_K_M | Q5_K_M |
| --- | ---: | ---: |
| Artifact size | 2.49 GB | 2.83 GB |
| Warm filesystem load | 1.68 s | 1.88 s |
| RSS after load | 2.82 GB | 2.84 GB |
| Mean time to first token | 0.98 s | 1.06 s |
| Mean total response | 2.49 s | 2.53 s |
| Raw JSON schema valid | 17/17 | 17/17 |
| Raw model passes all gates | 17/17 | 17/17 |
| Deterministic fallbacks | 0/17 | 0/17 |
| Delivered output passes all gates | 17/17 | 17/17 |

Prompt version 2 passed every expanded raw case for both variants. The injected
malformed, truncated, unsupported-number, fake-citation, timeout, cancellation,
and disconnect fixtures remain separate deterministic failure-path tests.

## Emulator result

The Q4_K_M artifact and pinned native `arm64-v8a` runtime were copied into the
API 34 emulator. The complete model loaded and began generation successfully.
A bounded probe reported:

- Model load: 14.68 seconds
- Prompt evaluation: 14 tokens in 14.28 seconds
- Prompt throughput: 0.98 tokens/second

A longer generation was interrupted after only a few tokens because CPU-only
emulator throughput is not representative or useful as a UX benchmark. This
is a compatibility pass only. Cold latency, steady-state generation speed,
peak Android memory, battery, and thermal behavior still require a physical
ARM64 phone.

The Wave 1 JNI runtime was subsequently compiled into the debug APK and tested
on the same API 34 ARM64 emulator. Its instrumentation suite validated the
exact Q4 byte count and SHA-256, loaded the model through JNI, and completed a
bounded greedy generation. The two-test JNI suite completed in 28.21 seconds.
This remains compatibility evidence, not a physical-phone performance result.

## Wave 2 runtime assembly

The localhost Demo service now owns the pinned llama.cpp process lifecycle and
exposes health, readiness, cancellation, and versioned explanation endpoints.
A real fictional Q4 request through the assembled boundary loaded in 0.63
seconds and completed in 2.13 seconds with schema-valid, grounded Pigeon-shaped
output. The service stayed on loopback and no cloud dependency was involved.

The Kotlin orchestrator validates the exact app-private Q4 artifact before its
first load, performs load and inference on an IO coroutine, serializes calls,
caches the loaded model, and maps cancellation, timeout, missing/corrupt model,
invalid output, and teardown into bounded result codes. On 2026-07-17 it was
registered in `MainActivity` against the versioned Explorer/Explainer Pigeon
contract. Dart now applies store-aware runtime selection, evidence/request-keyed
caching, the deterministic output guard, and labelled fallback before display.
The registration and runtime contract pass JVM tests; the updated app flow has
not yet been re-run on an emulator.

## Decision

Select Q4_K_M as the provisional Android integration candidate. It saves about
340 MB and was slightly faster on the controlled prompt-version-2 workload.
Both variants passed the same expanded evaluation matrix, so Q5 has no measured
quality advantage that justifies its mobile cost.

Next steps:

1. Complete the remaining MG-10 API 34 emulator flows when local resources
   permit.
2. Repeat latency, peak-memory, battery, and thermal measurements on a physical
   phone before declaring the runtime production-ready.
3. Introduce real health metrics only in the later integration phase, with
   mocked event data, minimum-field access, and de-identified local replays.
