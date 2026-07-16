# Wave 1 model evaluation summary

Run date: 2026-07-16

The Wave 1 prompt-version-2 evaluation used seventeen fictional WhyPulse cases
and no personal health, wearable, calendar, or event records.

Pinned inputs:

- Model: `google/medgemma-1.5-4b-it`
- Model revision: `91850547d9f0b2fdd21aa7c5f4f3d1a8a52c243b`
- llama.cpp revision: `5839ba352471b2a7b45e7ba401619a6896f10f8b`
- Explainer prompt version: 2
- Prompt SHA-256: `575a1f5617dd6cce4695f06b08ae5deecd147d7abb93ff4daf7aff454b61e065`
- Decoding: greedy with JSON-schema grammar

| Measure | Q4_K_M | Q5_K_M |
| --- | ---: | ---: |
| Cases | 17 | 17 |
| Raw schema valid | 17 | 17 |
| Raw guard accepted | 17 | 17 |
| Deterministic fallback | 0 | 0 |
| Delivered accepted | 17 | 17 |
| Mean time to first token | 0.98 s | 1.06 s |
| Mean total response | 2.49 s | 2.53 s |
| RSS after load | 2.82 GB | 2.84 GB |

The live model prompts cover supported product intents, null, contradictory,
insufficient data, diagnosis, prescription, causality, prompt injection,
generic chat, unrestricted timeline, invented-number requests, and fake-citation
requests.

Deterministic injected tests separately cover unsupported numeric output,
unknown citations, malformed JSON, truncated JSON, timeout, cancellation, and
backend disconnect. Keeping transport faults separate prevents them from being
misreported as model schema failures.

Generated per-case outputs remain in the ignored local report directory. They
are fictional, control-character sanitized before export, and bounded in size.
