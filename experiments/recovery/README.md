# Vueniverse MedGemma LoRA v7 Resurrection Guide

This bundle preserves the selected **LoRA BF16 v7** experiment and its private,
localhost-only Q4 runtime. It is a research artifact, not a clinical system and not a
public model service.

## Canonical bundle

Bucket prefix:

```text
gs://vueniverse-508413-medgemma-training/resurrection/20260918-lora-v7-final/
```

The bundle contains:

```text
workspace/
  configs/       pinned run configuration and environment evidence
  datasets/      synthetic, messages-only train/validation/test projections
  docs/          experiment notes and plans
  models/        pinned base MedGemma model files
  reports/       training reports, adapters, checkpoints, evaluations, and logs
  runs/          tmux/run logs and execution metadata
  tooling/       Vueniverse MedGemma source and tests
  deployment/    merged Hugging Face model, F16 GGUF, Q4_K_M GGUF, pinned llama.cpp,
                 build logs, and the 17-case runtime report
  source-scripts/ root-level training, comparison, merge, and safety scripts
manifest/        file inventory, checksums, and this guide
```

The bundle intentionally excludes `.venv/`. It was a machine-specific 5.1 GiB Python
environment rather than an experiment artifact. Its dependency evidence is preserved in
`workspace/configs/` and the project configuration under `workspace/tooling/`.

No raw Ultrahuman, wearable, or personal canonical-event records are included. The
datasets are the approved synthetic model-only projections.

## Verify before use

Download the prefix to a controlled local directory or a private VM:

```bash
gcloud storage rsync \
  gs://vueniverse-508413-medgemma-training/resurrection/20260918-lora-v7-final \
  ./medgemma-resurrection
```

Check the bundle manifest before running any model command:

```bash
cd ./medgemma-resurrection
sha256sum -c manifest/SHA256SUMS
```

The expected deployable artifact is:

```text
workspace/deployment/medgemma-1.5-4b-it-lora-v7-Q4_K_M.gguf
SHA-256: dd9c2a212672a5bb18affbc344a4c0fcf4e9000b3b5155d6fdfe9a8104bad234
```

## Resume research evaluation

1. Create a private GPU VM. An L4 is sufficient for Q4 runtime inference and was used
   for the final acceptance run.
2. Create a Python 3.12 environment.
3. Install the preserved project from `workspace/tooling/medgemma` using its pinned
   project metadata and the saved environment configuration.
4. Set paths explicitly; do not rely on a previous machine's paths.

```bash
export MEDGEMMA_Q4_GGUF="$PWD/workspace/deployment/medgemma-1.5-4b-it-lora-v7-Q4_K_M.gguf"
export LLAMA_CPP_DIR="$PWD/workspace/deployment/llama.cpp-pinned"
export MEDGEMMA_REPORT_DIR="$PWD/new-reports"
```

5. Build `llama.cpp` from the preserved pinned source revision
   `5839ba352471b2a7b45e7ba401619a6896f10f8b`. Build CUDA for the selected GPU; the
   original L4 build used `-DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=89`.
6. Run the 17-case Q4 regression before treating the runtime as usable. Compare against
   `workspace/deployment/lora-v7-q4-safety-eval/gguf-benchmark.json`.

## Resume adapter-based work

The merged model is useful for Q4 serving; it is not the only research checkpoint.
For Hugging Face/PEFT experiments, use the unmerged final LoRA adapter and matching
base model preserved under `workspace/reports/` and `workspace/models/`. Start a fresh
run directory. Never overwrite the frozen v7 reports, checkpoint directories, or
evaluation outputs.

The selected candidate was LoRA BF16 v7, based on the frozen v7 comparison:

| Model | Semantic useful rate | Notes |
| --- | ---: | --- |
| Vanilla MedGemma | 41.9% | generic output baseline |
| QLoRA v7 | 75.0% | more memory-efficient training path |
| LoRA BF16 v7 | 76.9% | selected candidate |

These are experimental benchmark outcomes, not clinical-performance metrics.

## Runtime boundary

The final service was deliberately bound to `127.0.0.1` only. If a future product
integration is needed, add authenticated application access, authorization, audit
logging, privacy review, and release gating before exposing any endpoint. Keep the
deterministic output guard enabled: the deployed Q4 safety suite delivered 17/17
accepted outputs, but one raw model response required fallback because of a citation
mismatch.

## Cost-safe resume and teardown

Start work in a named `tmux` session. Stop the VM after a verified report/checkpoint
upload. A stopped VM preserves its persistent disk but removes GPU and vCPU/RAM charges;
Cloud Storage retains the resurrection bundle and incurs storage charges only.
