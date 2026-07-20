# Vueniverse MedGemma tooling

Person 2's model-only workspace for `google/medgemma-1.5-4b-it`, pinned to the
exact revision recorded in `.env.example`. Upgrading the checkpoint is an
explicit experiment change, not an implicit pull from mutable `main`.

The remaining independently executable work packets and their dependency map
are maintained in
[`docs/medgemma-subtasks/README.md`](../../docs/medgemma-subtasks/README.md).

The tooling is deliberately separate from application persistence and source
ingestion. It accepts fictional, privacy-safe fixtures only. Model weights,
tokens, generated raw outputs, and local caches are ignored by Git.

The schemas in this tooling directory are provisional evaluation contracts;
they do not replace or modify Person 1's frozen Pigeon application contract.

Explainer evaluation schema v2 allows only exact values supplied by the current
result. The model must pair each number with the metric ID that supports it;
unknown or altered numbers are rejected. This keeps explanations concrete
without letting the model calculate health values.

The model-facing projection includes privacy-safe metric labels and values, but
still omits raw counter-event IDs and source records. Full evidence stays
available to deterministic validation outside the model boundary.

The current benchmark does not repair output with a second model call. Any
schema, grounding, citation, or safety failure is discarded and replaced by a
compact deterministic fallback. The app plan currently permits one constrained
retry; the versioned repair template is available, while retry orchestration is
deferred to the Wave 2 runtime.

## Environment

From the repository root:

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -e './tooling/medgemma[dev]'
```

Authenticate without placing a token in the repository:

```sh
hf auth login
hf auth whoami
```

## Local paths

Copy `tooling/medgemma/.env.example` to a local `.env` only if environment
variables are useful for the current shell. Never commit `.env`.

The default ignored paths are:

- Hugging Face checkpoint: `models/medgemma-1.5-4b-it/`
- F16 GGUF: `models/medgemma-1.5-4b-it-f16.gguf`
- Q4_K_M GGUF: `models/medgemma-1.5-4b-it-Q4_K_M.gguf`
- Q5_K_M GGUF: `models/medgemma-1.5-4b-it-Q5_K_M.gguf`
- Generated reports: `tooling/medgemma/reports/generated/`

All paths and the checkpoint revision can be overridden through environment
variables documented in `.env.example`.

## Experiment order

1. Download the official checkpoint at the pinned revision.
2. Run the BF16 text-only smoke test with greedy decoding.
3. Convert to F16 GGUF with a pinned llama.cpp revision.
4. Quantize to Q4_K_M and Q5_K_M.
5. Run identical fictional Explainer safety fixtures on both.
6. Select the mobile candidate from measured grounding, safety, schema, memory,
   and latency results.

No result from the older `google/medgemma-4b-it` checkpoint is treated as a
MedGemma 1.5 result.

Bootstrap and build the pinned conversion/runtime tools before steps 3 and 4:

```sh
tooling/medgemma/scripts/bootstrap_llama_cpp.sh
tooling/medgemma/scripts/build_host_tools.sh
tooling/medgemma/scripts/build_android_cli.sh
tooling/medgemma/scripts/build_android_jni.sh
```

The Android script reads `ANDROID_SDK_ROOT`, then `ANDROID_HOME`, then the
ignored `android/local.properties`; it contains no developer-specific path.

The Android build is an `arm64-v8a` emulator/runtime smoke artifact. It does
not substitute for latency, memory, battery, or thermal measurements on a
physical phone.

Run the local, Metal-backed comparison through the exact pinned llama.cpp
server build (the server is benchmark orchestration only, not the mobile
architecture):

```sh
vueniverse-medgemma benchmark \
  --llama-cpp-dir tooling/medgemma/.cache/llama.cpp \
  --variants Q4_K_M Q5_K_M
```

Full artifact sequence:

```sh
vueniverse-medgemma download
vueniverse-medgemma bf16-smoke
vueniverse-medgemma convert \
  --llama-cpp-dir tooling/medgemma/.cache/llama.cpp
vueniverse-medgemma quantize \
  --llama-cpp-dir tooling/medgemma/.cache/llama.cpp
vueniverse-medgemma manifest \
  --llama-cpp-dir tooling/medgemma/.cache/llama.cpp
vueniverse-medgemma runtime-schema
```

Run the strict API 34 ARM64 emulator checkpoint with a locally available Q4
artifact. This path fails when the real-model test cannot run, so a skipped
model test cannot be reported as MG-10 completion:

```sh
tooling/medgemma/scripts/run_emulator_checkpoint.sh \
  /absolute/path/medgemma-1.5-4b-it-Q4_K_M.gguf
```

Run and score the physical-phone MG-12 collection with:

```sh
tooling/medgemma/scripts/run_physical_benchmark.sh \
  /absolute/path/medgemma-1.5-4b-it-Q4_K_M.gguf
```

## Demo-only development service

The Wave 2 service binds only to loopback, starts the pinned llama.cpp server,
rejects Live requests before inference, and returns raw structured output. It
has no cloud dependency.

Start it from the repository root:

```sh
tooling/medgemma/scripts/run_demo_server.sh
```

Override the default ignored Q4 path or server binary when needed:

```sh
tooling/medgemma/scripts/run_demo_server.sh \
  --llama-server tooling/medgemma/.cache/llama.cpp/build/bin/llama-server \
  --model models/medgemma-1.5-4b-it-Q4_K_M.gguf
```

Probe it and send the versioned fictional fixture:

```sh
.venv/bin/python -m vueniverse_medgemma.service.cli health
.venv/bin/python -m vueniverse_medgemma.service.cli ready
.venv/bin/python -m vueniverse_medgemma.service.cli fixture
```

Make the same loopback port reachable from a connected emulator without
opening a LAN listener:

```sh
ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" \
  tooling/medgemma/scripts/adb_reverse_demo_server.sh
```

Debug Flutter builds enable this Demo runtime by default. Demo first uses a
verified on-device MedGemma artifact when one is installed, then this loopback
runtime, and finally the checked deterministic backup. Release builds require
an explicit `--dart-define=VUENIVERSE_DEVELOPMENT_MEDGEMMA=true` to enable the
development runtime. The explanation and Ask screens show which path actually
ran, plus the model name and measured latency for accepted model output.

The phone runtime is registered through `MainActivity` and becomes selectable
only after the app-private artifact passes size and checksum verification. Its
native result metadata reports output guard version `0`; the Dart output guard
remains the sole safety-policy owner and records the accepted guard version.
