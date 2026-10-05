# Vueniverse MedGemma experiment journal

Status: active and append-only  
Owner: Rakesh  
Project: `vueniverse-508413`  
Purpose: a human-readable, secret-free record of every material experiment action.

## Operating rule

Before a material action, record its intended purpose and the bounded resource or data
scope. Immediately after it, record the result, artifact path or cloud resource, and
verification. Read-only checks, configuration changes, data builds, uploads, VM state
changes, package installations, model runs, checkpoints, evaluations, cost checks, and
failures all receive an entry.

Never put credentials, raw Ultrahuman data, raw event data, exact personal identifiers,
or private token values in this journal. Commands are recorded only in a sanitized form.

## Record format

| Field | Meaning |
| --- | --- |
| ID | Monotonic journal identifier |
| Date / phase | India Standard Time date and seven-day-plan phase |
| Action | What was attempted or changed |
| Configuration / inputs | Sanitized configuration, dataset hash, or resource identity |
| Result | Success, failure, or decision |
| Verification / next state | Evidence and safe next action |

## Entries

| ID | Date / phase | Action | Configuration / inputs | Result | Verification / next state |
| --- | --- | --- | --- | --- | --- |
| J-001 | 2026-09-12 · Day 1 | Freeze the model-learning experiment and budget guardrail. | Base model `google/medgemma-1.5-4b-it`; monthly INR 17,000 budget; model-only data boundary. | Complete. | Budget `39472973-148a-43a9-b0b8-5b4264c630dc` has threshold and forecast alerts. |
| J-002 | 2026-09-12 · Day 2 | Create a protected Ultrahuman calibration profile. | Read-only personal API access; only coarsened aggregate bands exported. | Complete. | Raw wearable timelines and credential remain local and outside training/cloud artifacts. |
| J-003 | 2026-09-12 · Day 3 | Produce the original multi-context supervised corpus. | Version 4, 630 rows, provenance separated from model messages. | Superseded for training by v5. | Retained locally as an ignored provenance artifact. |
| J-004 | 2026-09-14 · Day 3.3 | Add private-context reference contract and regenerate the corpus. | HMAC-derived `ctx_…` references; 1,260 rows; train/validation/test = 840/210/210. | Complete. | v5 quality report: 210 references; six rows/reference; zero cross-split references; zero model-facing provenance markers. |
| J-005 | 2026-09-14 · Day 3.3 | Verify source, schema, and dataset changes. | Ruff checks; full MedGemma tooling test suite. | Complete. | 61 passed, 2 intentionally skipped. |
| J-006 | 2026-09-14 · Day 4 | Run read-only GCP preflight. | Project `vueniverse-508413`; region `asia-south1`; `g2-standard-4`; NVIDIA L4 catalog in zones a/b/c. | Regional L4 quota is 1 and unused; project is active with billing enabled. | A project-wide GPU quota check remains a launch blocker. |
| J-007 | 2026-09-14 · Day 4 | Create dedicated trainer identity. | `medgemma-trainer@vueniverse-508413.iam.gserviceaccount.com`; bucket object access, log writer, metric writer only. | Complete. | No broad project editor role was granted to the trainer identity. |
| J-008 | 2026-09-14 · Day 4 | Create private experiment artifact bucket. | `gs://vueniverse-508413-medgemma-training`, `asia-south1`, uniform access, public-access prevention. | Complete. | Retention: staging 3 days; checkpoints 14 days; datasets/adapters/reports/configs 90 days. |
| J-009 | 2026-09-14 · Day 4 | Create isolated VM network boundary. | Custom VPC `medgemma-train-vpc`; Mumbai subnet; one IAP-only TCP/22 ingress rule. | Complete. | No broad public SSH rule exists in this VPC. |
| J-010 | 2026-09-14 · Day 4 | Attempt controlled one-L4 VM launch. | `g2-standard-4`, one L4, 100 GB balanced persistent boot disk, four-hour stop limit. | Blocked before VM creation. | Compute Engine reports `GPUS_ALL_REGIONS` quota = 0. No VM, GPU, or compute charge was created. |
| J-011 | 2026-09-14 · Day 4 | Start a quiet GPU-quota monitor. | `MedGemma GPU quota monitor`; read-only GCP checks every two hours. | Active. | It remains silent while quota state is unchanged and never creates or modifies cloud resources. |
| J-012 | 2026-09-14 · Day 4 | Build and run the cloud-upload preflight gate. | v5 immutable dataset; only the `messages` training projection is permitted. | Complete. | Manifest `tooling/medgemma/outputs/finetuning/supervised-dataset-v5-cloud-preflight.json`; 840/210/210 rows; 210 references; zero raw-data flags and split overlap. |
| J-013 | 2026-09-14 · Day 4 | Store Hugging Face access in Secret Manager. | Secret `medgemma-hf-token`; version 1; accessor role granted only to the training service account. | Complete. | Token value was transmitted through standard input, was not printed, and is absent from source, datasets, and this journal. |
| J-014 | 2026-09-14 · Day 4 | Pause the GPU quota monitor after the user reported quota approval. | Heartbeat automation `medgemma-gpu-quota-monitor`. | Paused. | The monitor will make no further quota checks; no VM was started by this action. |
| J-015 | 2026-09-14 · Day 4 | Verify approved GPU quota. | Read-only GCP quota inspection; global `GPUS_ALL_REGIONS` and `asia-south1` `NVIDIA_L4_GPUS`. | Complete: both limits are 1, both usages are 0. | The planned single-L4 VM can now be launched when explicitly requested; no resource was created during verification. |
| J-016 | 2026-09-14 · Day 4 | Prepare controlled L4 smoke-session launch. | One `g2-standard-4` VM in `asia-south1`; one L4; 100 GB balanced persistent boot disk; four-hour stop limit; dedicated service account; IAP-only SSH network. | Authorized by user; launch pending. | Abort the session and stop the VM on any failed GPU, security, storage, or dependency guardrail. |
| J-017 | 2026-09-14 · Day 4 | Attempt controlled L4 VM launch in `asia-south1-a`. | Planned `g2-standard-4` configuration from J-016. | Not created: GCP returned `ZONE_RESOURCE_POOL_EXHAUSTED_WITH_DETAILS` for the L4. | No VM or GPU charge resulted. Continue only with the preplanned same-region zone fallback, preserving the identical configuration. |
| J-018 | 2026-09-14 · Day 4 | Attempt controlled L4 VM launch in `asia-south1-b`. | Same planned configuration from J-016. | Not created: GCP returned `ZONE_RESOURCE_POOL_EXHAUSTED_WITH_DETAILS` for the L4. | No VM or GPU charge resulted. Try the final preplanned same-region fallback once, preserving the identical configuration. |
| J-019 | 2026-09-14 · Day 4 | Attempt controlled L4 VM launch in `asia-south1-c`. | Same planned configuration from J-016. | Not created: GCP returned `ZONE_RESOURCE_POOL_EXHAUSTED_WITH_DETAILS` for the L4. | All preplanned on-demand Mumbai zones are presently capacity-blocked. No VM or GPU charge resulted. |
| J-020 | 2026-09-14 · Day 4 | Verify post-failure compute state. | Read-only instance and disk inventory for `medgemma-qlora-l4-01`. | No matching VM or persistent disk exists. | The capacity attempts left no compute resource to stop and no ongoing GPU, VM, or disk charge. |
| J-021 | 2026-09-14 · Day 4 | Inventory alternate-region L4 eligibility. | Read-only GCP accelerator catalog and regional L4 quota inspection. | Eighteen L4-capable regions total, including Mumbai; the seventeen alternatives each have regional L4 limit 1 and usage 0. | Catalog and quota do not guarantee live physical capacity; no resource was created, reserved, or modified. |
| J-022 | 2026-09-14 · Day 4 | Prepare approved US L4 fallback. | User approved `us-central1`; retain the Mumbai bucket rather than migrating it; create only a regional subnet and the same capped L4 VM. | Authorized; network and VM launch pending. | Existing global VPC, IAP firewall, service account, budget, and Secret Manager access remain unchanged. Only the already-approved redacted v5 data may traverse to the VM. |
| J-023 | 2026-09-14 · Day 4 | Create US fallback subnet. | `medgemma-train-us-central1-subnet`, `10.43.0.0/24`, custom training VPC, Private Google Access. | Complete. | The global IAP-only firewall rule applies; this subnet introduces no public SSH rule and does not alter the Mumbai subnet. |
| J-024 | 2026-09-14 · Day 4 | Attempt controlled L4 VM launch in `us-central1-a`. | Same `g2-standard-4` configuration and safeguards from J-016; approved US subnet from J-023. | Not created: GCP returned `ZONE_RESOURCE_POOL_EXHAUSTED_WITH_DETAILS` for the L4. | No VM or GPU charge resulted. Continue only with the two remaining approved zones in `us-central1`. |
| J-025 | 2026-09-14 · Day 4 | Create controlled L4 VM in `us-central1-b`. | `medgemma-qlora-l4-01`; `g2-standard-4`; one L4; 100 GB balanced persistent boot disk; dedicated trainer service account; four-hour stop limit. | Created and running. | Proceed only after verifying GPU visibility, stop policy, network/service-account guardrails, and private bucket access. |
| J-026 | 2026-09-14 · Day 4 | Verify VM hardware and guardrails through IAP. | Read-only instance inspection and IAP SSH; one L4. | Complete: NVIDIA L4 (23,034 MiB), driver 580.178.04; 14,400-second STOP limit; no auto-restart; approved service account, subnet, labels, and SSH controls. | GPU and configuration guards passed. Verify bucket access next, then install the pinned training environment. |
| J-027 | 2026-09-14 · Day 4 | Bootstrap isolated Python runtime. | OS package `python3-pip`; user-local `uv` 0.12.13; managed CPython 3.12.14. | Complete. | The project requirement `>=3.12,<3.13` can be honored in a separate environment. No project data, model, or credential was copied during bootstrap. |
| J-028 | 2026-09-14 · Day 4 | Install isolated model-training stack. | Editable project package with base pins; resolved PEFT 0.20.0, TRL 1.13.0, Datasets 5.0.1, bitsandbytes 0.50.2; PyTorch 2.11.0+cu130. | Complete; CUDA is available to PyTorch. | Save the full resolved environment freeze and VM details in the run configuration before baseline evaluation. |
| J-029 | 2026-09-14 · Day 4 | Export and upload model-only v5 dataset projection. | Three JSONL splits containing only `messages` plus a projection hash manifest. | Complete. | VM re-download verified 840/210/210 rows, exact SHA-256 values, no metadata keys, and zero model-facing provenance markers. |
| J-030 | 2026-09-14 · Day 4 | Run vanilla model and evaluator smoke tests. | MedGemma 1.5 4B, BF16 on L4; 64-token basic smoke; three frozen holdout cases with 192-token cap. | Complete. | Model load: 6.491 s; basic smoke peak allocation: 8,636,367,872 bytes. Holdout evaluator ran end to end; raw contract acceptance 0/3, deterministic fallback delivery 3/3. |
| J-031 | 2026-09-14 · Day 4 | Persist cloud run configuration. | Environment freeze, GPU identity, run identity, and `pyproject.toml` under `configs/20260914-day4-smoke-us-central1b-01/`. | Complete. | No token or dataset row was written to configuration artifacts. The exact dependency resolution is recoverable after VM stop. |
| J-032 | 2026-09-14 · Day 4 | Add and verify cloud projection, vanilla evaluation, and QLoRA smoke tooling. | Model-only exporter; GPU-aware baseline evaluator; three-step NF4/rank-8 QLoRA runner; focused formatter checks. | Complete locally. | Ruff checks passed; modified files are formatted; 66 tests passed and 2 pre-existing platform skips remain. The full tree formatter reports unrelated existing formatting drift in six untouched files. |
| J-033 | 2026-09-14 · Day 4 | Schedule one-hour vanilla-baseline status follow-up. | One-shot heartbeat `medgemma-baseline-one-hour-check`; read-only IAP status/report check. | Active; it pauses itself after one check. | No current-session polling continues. The follow-up may not create, start, stop, or otherwise modify cloud resources. |
| J-034 | 2026-09-14 · Day 4 | Complete full vanilla frozen-holdout baseline. | 210 messages-only test cases; BF16 MedGemma 1.5 4B; deterministic decoding with 192-token cap. | Complete. | Raw schema and guard acceptance: 0/210; deterministic fallback delivery: 210/210. Model load: 6.294 s; peak allocation: 9,064,391,168 bytes. |
| J-035 | 2026-09-14 · Day 4 | Pause duplicate baseline-status follow-up. | `medgemma-baseline-one-hour-check`. | Paused after the user requested and received a manual read-only status check. | No further scheduled baseline polling will occur. |
| J-036 | 2026-09-14 · Day 4 | Abort QLoRA smoke for the user-requested break. | NF4/rank-8 smoke process started only through initial model preparation. | Stopped before any reported training loss, checkpoint, adapter save, reload, or inference. | No QLoRA result is claimed; the Day 4 QLoRA checkbox remains open for the next session. |
| J-037 | 2026-09-14 · Day 4 | Stop the idle L4 VM and verify shutdown. | `medgemma-qlora-l4-01`, `us-central1-b`. | Complete: `TERMINATED` at 16:56:59Z after start at 15:32:57Z. | GPU and vCPU/RAM charges ended. The 100 GB persistent boot disk, model cache, environment, and local projection remain for resume; only disk storage continues to accrue. |
| J-038 | 2026-09-15 · Operations | Record the user's interactive-session requirement for future VM work. | All resumed interactive model preparation, training, and evaluation runs. | Pending next VM start. | Start each run in a named `tmux` session, record the session name with its run identity, and give the user the IAP SSH + `tmux attach` command. This enables observation and protects the process from an SSH disconnect; never put credentials in the session command or transcript. |
| J-039 | 2026-09-15 · Day 5 planning | Add an in-thread semantic review after every model evaluation run. | Every raw holdout and safety-suite output plus its model-facing evidence bundle, expected analytical interpretation, and deterministic-gate result. | Planned; no model output was re-scored in this entry. | The assistant will review every output and write a constrained, secret-free JSONL artifact with grounding, uncertainty, safety, usefulness, verdict, and concise evidence-backed rationale. Deterministic gate failures remain failures; the semantic review is an additional quality measure, not a bypass. |
| J-040 | 2026-09-15 · Day 4 outcome | Retrospectively perform the in-thread semantic review of the frozen vanilla holdout and publish benchmark artifacts. | 210 raw vanilla messages-only outputs, their matching frozen evidence bundles, and existing deterministic evaluations; no raw wearable or canonical records. | Complete. All 210 outputs began with `<unused94>thought`, never formed valid JSON or a user-facing final answer, and received `fail` verdicts. Grounding, uncertainty, safety, and usefulness are `null` rather than artificial zero scores because no final answer exists to assess. | Private artifacts: `reports/20260914-day4-smoke-us-central1b-01/semantic-review/{vueniverse-vanilla-baseline-benchmark.xlsx,vanilla-experiment-outcome.md,vanilla-semantic-judgments.jsonl}`. Raw JSON and raw gate: 0/210; fallback/delivered acceptance: 210/210. This is an output-contract failure, not a clinical-performance conclusion. |
| J-041 | 2026-09-15 · Day 4 correction | Diagnose and correct the vanilla inference protocol after the semantic review found all outputs reached the 192-token cap while emitting thought text. | Local evaluator and CLI only; no VM, model, dataset, secret, or cloud artifact was changed by this entry. | Code updated and syntax-checked locally. The evaluator now requests `enable_thinking=False`, prefers a processor-parsed final answer when supported, and defaults to the remaining advertised MedGemma context window instead of an application-level output cap. | The previous 210-case report remains immutable evidence of the original 192-token run. A new frozen vanilla run is required before a fair QLoRA comparison. Local lint/test dependencies are absent in this checkout, so the focused suite must run in the persistent VM environment on resume. |
| J-042 | 2026-09-15 · Day 4 correction | Start the stopped L4 VM and run one uncapped vanilla response-protocol diagnostic in a named tmux session. | `medgemma-qlora-l4-01`, `us-central1-b`; one messages-only frozen test case; tmux session `medgemma-vanilla-response-20260915`. | Complete. The model reached EOS after 1,464 generated tokens, not the 131,072-token context boundary, but emitted only `<unused94>thought` planning text. | The processor logged that `enable_thinking` is unsupported and ignored for this MedGemma version. This proves the 192-token cap was a confounder but not the root response-path failure. Report stored at `reports/20260915-vanilla-response-protocol-01/vanilla-onecase-unbounded.json`. |
| J-043 | 2026-09-15 · Day 4 correction | Test an assistant JSON-opening prefill after the uncapped run exposed a thought-only response. | Same frozen case; tmux session `medgemma-vanilla-jsonprefill-20260915`; assistant prefill `{`; no application output cap. | Complete but strict guard failed. The model generated a coherent JSON-shaped answer and reached EOS after 253 tokens, with no thought trace; it appended a terminal code fence and omitted the required opaque context reference. | Report stored at `reports/20260915-vanilla-response-protocol-02/vanilla-onecase-unbounded.json`. The result shows the model can produce explanatory content once generation starts inside an assistant JSON turn, but structural ownership must be explicit. |
| J-044 | 2026-09-15 · Day 4 correction | Validate application-owned JSON structural prefill and narrow terminal-fence normalization. | Same frozen case; tmux session `medgemma-vanilla-structural-20260915`; prefilled schema version, exact opaque context reference, and opening summary quote; no application output cap. | Complete: 113 generated tokens, EOS before the 129,112-token remaining-context boundary; exact JSON output; strict guard accepted 1/1; fallback 0/1. | Report stored at `reports/20260915-vanilla-response-protocol-03/vanilla-onecase-unbounded.json`. The context reference and initial JSON structure are application-authored, not model-generated; the forthcoming full report must report this assembled-contract result separately from model-generated explanatory quality. |
| J-045 | 2026-09-15 · Day 4 correction | Stop the L4 VM after the bounded vanilla response-protocol diagnostics and verify its state. | `medgemma-qlora-l4-01`, `us-central1-b`. | Complete: `TERMINATED` at `2026-09-15T00:31:32.586-07:00`. | GPU and vCPU/RAM billing ended. The persistent disk retains the editable environment, downloaded model, one-case reports, and tmux logs for the next resume. |
| J-046 | 2026-09-15 · Day 4 correction | Restart the L4 VM and launch the corrected full frozen vanilla holdout in an interactive persistent session. | `medgemma-qlora-l4-01`, `us-central1-b`; 210-case messages-only v5 test projection; tmux session `medgemma-vanilla-holdout-20260915`; no application output cap. | Active; launch and VM residency explicitly approved by the user. | Report path: `reports/20260915-vanilla-holdout/vanilla-holdout-full.json`; log path: `runs/20260915-vanilla-holdout/tmux.log`. The report now separates application-prefilled contract fields from MedGemma-generated semantic fields. Do not interpret the assembled JSON pass rate as an independently generated schema rate. No automated polling or agent-initiated shutdown is scheduled. The pre-existing GCP four-hour safety stop remains for this active run because GCP permits clearing it only while the VM is stopped; stopping now would interrupt the evaluation. |
| J-047 | 2026-09-15 · Day 4 correction | Diagnose and relaunch the full frozen vanilla holdout after the first tmux launcher exited without invoking Python. | First session `medgemma-vanilla-holdout-20260915`; replacement `medgemma-vanilla-holdout-20260915-rerun`; identical immutable 210-case messages-only test projection and report path. | Replacement session created and active. | The first pane exited status 0 with an empty log and no report due to nested shell quoting; no model inference or evaluation result was produced. The replacement invokes the virtual-environment Python executable directly, preserving visible tmux output and avoiding the failed nested-shell path. No automated polling or shutdown is scheduled. |
| J-048 | 2026-09-15 · Day 4 correction | Inspect the two exited launch sessions before a third attempt. | The completed panes for `medgemma-vanilla-holdout-20260915` and `medgemma-vanilla-holdout-20260915-rerun`; local `pyproject.toml` CLI declaration. | Neither session ran inference or wrote a report. The correct executable is `vueniverse-medgemma`, not `python -m vueniverse_medgemma.cli`, because the module does not invoke `main()` when run with `-m`. | The subsequent direct CLI session loaded MedGemma and began GPU generation. Retain the two dead panes as diagnostic evidence; neither is a model result. |
| J-049 | 2026-09-15 · Evaluation tooling | Add durable partial-report checkpoints for future vanilla evaluations. | Local cloud evaluator and CLI only. | Complete locally; syntax validated. The current active VM process remains on its prior immutable runner. | Future runs will atomically write a private report after case 1 and every 10 cases, with `run_status`, `completed_case_count`, and all completed records. A completed checkpoint survives a normal interruption; no mid-run source sync is performed, preserving the current run's reproducibility. |
| J-050 | 2026-09-15 · Day 4 outcome | Complete corrected vanilla holdout, review all outputs, publish artifacts, and stop the L4 VM. | 210-case messages-only v5 holdout; application-owned structural prefill; local and private-bucket semantic review artifacts; `medgemma-qlora-l4-01`. | Complete. Assembled schema: 206/210; full guard: 173/210; fallback: 37/210; semantic verdicts: 3 pass, 170 review, 37 fail. VM verified `TERMINATED`. | Private artifacts: `reports/20260915-vanilla-holdout/semantic-review/`. The response-path regression is fixed, but semantic review shows a substantial remaining gap: many accepted answers omit the held-out target's key context, contradictory counts, or missing-context framing. GPU and vCPU/RAM charges ended; persistent disk remains for resumption. |
| J-051 | 2026-09-15 · Day 4 QLoRA preparation | Prepare the QLoRA smoke runner, remove the prior automatic-stop policy while the VM was stopped, and attempt to resume the existing L4 VM. | Local smoke runner correction; `medgemma-qlora-l4-01`, `us-central1-b`. | Runner syntax checked locally. VM start blocked: GCP returned L4 stockout in `us-central1-b`; it reports capacity in `us-central1-a` and `us-central1-c`. | No GPU process started and no new VM/disk was created. The next-zone migration requires a new VM and a boot-disk snapshot/restore, so it awaits explicit user direction. |
| J-052 | 2026-09-15 · Day 4 QLoRA smoke | Migrate the stopped environment and start the approved three-step QLoRA smoke run. | Snapshot `medgemma-qlora-l4-01-20260915`; restored replacement `medgemma-qlora-l4-02` in `us-central1-a`; one L4; rank-8 NF4 smoke session `medgemma-qlora-smoke-20260915`. | Active. Snapshot ready; replacement VM created without an external IP; CLI preflight passed; model loading confirmed at 4,288 MiB GPU allocation. | The original b-zone VM and disk remain stopped as rollback evidence. The smoke run uses only the v5 messages-only train/validation projection and a fresh report directory. No training outcome is claimed until loss, checkpoint, adapter reload, and inference are verified. |
| J-053 | 2026-09-15 · Day 5 QLoRA | Start the first full rank-16 QLoRA learning run after smoke loss/checkpoint/reload validation. | `medgemma-qlora-l4-02`, `us-central1-a`; v5 messages-only 840-row train split; rank 16/alpha 32; one epoch / 840 steps; checkpoint every 100 steps; tmux `medgemma-qlora-r16-20260915`. | Active. Model load confirmed at 4,442 MiB GPU allocation. | The smoke adapter's reload text was truncated by its old fixed 96-token cap; the runner was corrected to use the remaining model context and synced before this run. No full-training result is claimed until periodic checkpoints, final adapter, reload, and held-out evaluation complete. |
| J-054 | 2026-09-15 · Day 5 QLoRA evaluation | Interrupt a post-training generation loop, preserve the completed rank-16 adapter, and separate adapter evaluation from training. | User-authorized `KeyboardInterrupt` to tmux `medgemma-qlora-r16-20260915`; adapter plus checkpoints through step 800; v5 completion-length calibration across 840 training answers. | Training process stopped only during reload inference. The final adapter exists and is reusable; in-memory per-step loss history and the one-example validation loss were not written before interruption. A standalone adapter evaluator is now running on the untouched validation split in tmux `medgemma-qlora-r16-validation-full-01`. | Evaluation uses application-owned JSON prefill, stops on a complete JSON object, limits malformed completions to 256 tokens (v5 train p95=213, max=223) and 45 seconds/case, writes progress per case, and checkpoints its private report every 10 cases. Validation metrics are reproducible from the saved adapter; the test split remains untouched until rank selection. |
| J-055 | 2026-09-15 · Day 5 inference diagnosis | Diagnose the rank-16 adapter's slow one-case evaluation and replace the faulty per-token completion callback. | The original callback decoded and JSON-parsed the entire growing sequence after every token; observed CPU 100%, GPU about 22%, model `use_cache=true`. Corrected runner uses native `generate()` with `use_cache=True` and decodes once after return. | The user-requested native unbounded rerun still failed to emit EOS after more than 5 minutes 19 seconds and was manually terminated by the user. No completed output/report exists for that diagnostic. This separates two issues: evaluator-side quadratic decoding was fixed, while the adapter still exhibits abnormal non-terminating generation. | Do not count the interrupted diagnostics as evaluation results. The previous 256-token policy is superseded. Before another full evaluation, inspect training/label EOS alignment and compare the same case with the vanilla BF16 model and adapter disabled under an identical native generation path. VM `medgemma-qlora-l4-02` remains running until the user requests shutdown. |
| J-056 | 2026-09-15 · Day 5 inference repair | Trace repeated `<pad>` output to NaN logits in the unprepared NF4 reload path and verify the repair. | Generation config correctly recognizes EOS IDs 1 and 106; supervised targets end in `<end_of_turn>` 106. Before repair, the NF4 base produced all-NaN logits even with adapters disabled and greedy decoding emitted pad ID 0 indefinitely. Training had called `prepare_model_for_kbit_training`, but evaluation and post-training reload had not. | Confirmed and fixed. Applying identical k-bit preparation made base and all rank-16 checkpoint logits finite. The repaired one-case run reached native EOS after 182 tokens in 23.294 seconds, produced strict schema-valid/guard-accepted JSON, and used no fallback. | Production evaluation and post-training reload now prepare the NF4 base consistently, use native cached generation, decode once, and remove only a terminal `<end_of_turn>`/`<eos>` control token. Diagnostic report: `reports/20260915-qlora-r16-onecase-fixed-final-01/onecase.json`. Full validation has not been restarted. |
| J-057 | 2026-09-16 · Day 5 full QLoRA evaluation | Run the repaired rank-16 adapter on all 210 validation cases and perform a case-by-case semantic review against the held-out expected outputs. | `medgemma-qlora-l4-02`, `us-central1-a`; rank 16/alpha 32 adapter; NF4 base with k-bit reload preparation; tmux `medgemma-qlora-r16-validation-full-20260916`; native EOS with 45-second safety timeout; checkpoint every 10 cases. | Complete. All 210 cases reached EOS; schema valid 210/210; deterministic guard accepted 210/210; fallback 0/210; average generation 22.94 seconds. Manual semantic verdicts: pass 42/210 and fail 168/210. All 42 supported cases passed; all contradictory, developing, insufficient-data, and null-pattern cases failed because the adapter reused the supported “stands out” framing. | Local review artifacts: `outputs/qlora-r16-validation-semantic-review-20260916/` in the experiment workspace. The adapter improved structure and evidence specificity but collapsed finding-state and intent distinctions. Rebalance/contrast state-conditioned training examples and repeat rank-16 before changing rank or alpha. The VM remains running until the user explicitly requests shutdown. |
| J-058 | 2026-09-16 · Day 5 dataset revision | Generate a state-contrastive, intent-aware v6 training corpus while preserving the evaluated v5 holdouts. | Source v5 corpus; supported multiplier 1; developing, null, contradictory, and insufficient-data multiplier 2; six intents; existing prompt, schema, and runtime guard. | Complete. Train/validation/test = 1,512/210/210. Training counts: supported 168; each failed state 336; each intent 252. All 1,512 labels are unique and guard-valid. Validation and test are byte-identical to v5; cloud preflight passed with 210 context references and zero split overlap. | Artifacts: `tooling/medgemma/outputs/finetuning/supervised-dataset-v6/`, `supervised-dataset-v6-cloud-preflight.json`, and `supervised-dataset-v6-messages-projection/`. Next run must retain rank 16/alpha 32 and the same frozen validation set so the dataset change is isolated. |
| J-059 | 2026-09-16 · Day 5 infrastructure migration | Snapshot the unavailable central-US trainer and restore it in an eligible eastern-US zone. | Snapshot `medgemma-qlora-l4-02-20260916-post-r16`; subnet `medgemma-train-us-east1-subnet` (`10.44.0.0/24`, Private Google Access); replacement `medgemma-qlora-l4-03` in `us-east1-b`; `g2-standard-4`, one L4, 100 GB balanced disk, no external IP, dedicated trainer service account. | Complete. Snapshot reached `READY`; replacement VM booted with the preserved runtime/model cache and passed GPU, disk, and source checks. IAP access required enabling the IAP API and restoring the existing firewall target tag `medgemma-train-iap`; no broad ingress rule was added. | NVIDIA L4 reported 23,034 MiB and was idle before training. The source VM/disk and snapshot remain rollback artifacts. The replacement VM is active and therefore incurs GPU, vCPU, RAM, and disk charges until explicitly stopped. |
| J-060 | 2026-09-16 · Day 5 v6 smoke | Transfer and verify the model-only v6 projection, sync the corrected runner, and execute a three-step rank-16 QLoRA smoke test. | v6 rows 1,512/210/210; SHA-256 train `7ef49f0f…a8b1b`, validation `b23a515c…1f6d9`, test `3b3af111…ac4b`; rank 16/alpha 32; dropout 0.05; `q_proj`, `k_proj`, `v_proj`, `o_proj`; NF4 double quantization; BF16; tmux `medgemma-qlora-r16-v6-smoke-20260916`. | Complete. Focused tooling tests passed 7/7. Smoke losses decreased `0.934454 → 0.864130 → 0.755785`; one-example validation loss was `0.452570`; three checkpoints and the final adapter were saved. Fresh adapter reload reached native EOS and produced exact JSON accepted by both schema and guard. | Smoke report: `reports/20260916-qlora-r16-v6-smoke-01/`. Peak CUDA allocation was 14,385,336,320 bytes; model load took 51.361 seconds. This validates mechanics only and is not a quality benchmark. |
| J-061 | 2026-09-16 · Day 5 v6 full training | Launch the controlled one-epoch v6 rank-16 training run after smoke validation. | `medgemma-qlora-l4-03`, `us-east1-b`; 1,512 train rows / 1,512 optimizer steps; rank 16/alpha 32; checkpoint every 100 steps; one validation example; tmux `medgemma-qlora-r16-v6-full-20260916`. | Active. The Python trainer is attached to the L4 and reported 17,698 MiB GPU memory during startup/training initialization; no startup error was observed. | Report path: `reports/20260916-qlora-r16-v6-full-01/`; live log: `reports/20260916-qlora-r16-v6-full-01/tmux.log`. Do not claim a training outcome until losses, checkpoints, final adapter, reload, and subsequent frozen validation evaluation are verified. No automatic polling or shutdown is scheduled. |
| J-062 | 2026-09-16 · Day 5 evaluation preparation | Prepare the post-training evaluation, semantic-review, comparison, observation, and recovery procedure without reading or modifying the active training process. | Frozen v6 validation SHA-256; final-adapter completion gates; one-case and 210-case tmux commands; 45-second safety timeout with native EOS; ten-case atomic checkpoints; separate product-runtime treatment for the existing 17-case suite. | Complete locally. No cloud process or artifact was changed. | Runbook: `docs/finetuning/post-training-evaluation-runbook.md`; actual-run learning notes: `docs/finetuning/qlora-actual-run-notes.md`. Execute the one-case gate only after the training report and final adapter are complete. |
| J-063 | 2026-09-16 · Day 5 v6 full training outcome | Verify completion of the one-epoch v6 rank-16 QLoRA run and its final artifacts. | `medgemma-qlora-l4-03`; 1,512/1,512 steps; immutable v6 train hash `7ef49f0f…a8b1b`; validation hash `b23a515c…1f6d9`; rank 16/alpha 32; checkpoints every 100 steps. | Complete. Final training metrics end at step 1,512; one-example validation loss is `0.503885`; checkpoint step 1,512, final adapter configuration, adapter safetensors, and `qlora-smoke.json` are present. | Training mechanics and artifact gates passed. This does not establish semantic quality; the frozen validation evaluation is tracked separately. |
| J-064 | 2026-09-16 · Day 5 v6 evaluation | Pass a one-case adapter evaluation gate and launch the full frozen validation evaluation. | Final v6 adapter; unchanged 210-case validation projection; NF4 reload with k-bit preparation; native EOS; 45-second per-case safety timeout; checkpoint every 10 cases; full tmux `medgemma-qlora-r16-v6-validation-20260916`. | Active. One-case gate reached EOS in 26.257 seconds, schema valid and guard accepted, with no fallback. Full case 0 reached EOS in 26.463 seconds and also passed schema/guard with no fallback. | Full report path: `reports/20260916-qlora-r16-v6-validation-01/validation.json`; log: `reports/20260916-qlora-r16-v6-validation-01/tmux.log`. No continuous polling or automatic shutdown is scheduled. After completion, retrieve the report and perform the required case-by-case semantic review. |
| J-065 | 2026-09-17 · Day 5 v6 evaluation outcome | Verify the completed 210-case v6 validation run and judge every raw output against its frozen evidence, held-out answer, deterministic result, and requested intent. | Frozen validation SHA-256 `b23a515c…1f6d9`; 210 paired cases; constrained grounding, uncertainty, safety, usefulness, and verdict fields; raw output judged before fallback. | Complete. Native EOS 210/210; schema valid 210/210; guard accepted 208/210; fallback 2/210; semantic verdicts 0 pass, 42 review, 168 fail. Every output used supported “stands out” framing and selected `log_context`; all non-supported states failed, while supported cases were marked review for intent/next-action mismatch. | Local artifacts: `outputs/qlora-r16-v6-validation-semantic-review-20260917/` in the experiment workspace. Rebalancing alone did not fix state collapse and introduced or exposed complete intent collapse. Keep rank 16/alpha 32 for the next isolated data-design experiment; use paired state/intent contrasts and a semantic state gate before another full run. VM remains running pending explicit shutdown instruction. |
| J-066 | 2026-09-17 · Day 5 v7 data repair | Trace v6 collapse to state-blocked sequential optimization, design the v7 data contract from primary instruction-tuning guidance, and implement balanced ordering plus trainer-side shuffling without using the GPU. | v6 order was five contiguous state blocks and batch/optimizer update size one with no shuffle; v7-r2 returns to 840 balanced rows, 30 state × intent cells, 28 rows/cell; seed `20260912`; independent trainer shuffle and order audit. | Local implementation complete. v7 maximum contiguous same-state run is 1; cloud preflight passed with zero reference overlap and zero model-facing provenance markers; messages-only train SHA-256 `c93692d…79463`; frozen validation/test projection hashes remain `b23a515c…1f6d9` and `3b3af111…ac4b`; all 76 tooling tests passed. | Design: `docs/finetuning/dataset-v7-design.md`. Canonical local artifacts: `tooling/medgemma/outputs/finetuning/supervised-dataset-v7-r2*`. No upload or training was started. Build the 30-case semantic sentinel and run only the tiny gated pilot before any full retraining. |
| J-067 | 2026-09-17 · Day 5 v7 smoke and full launch | Gate the corrected v7 corpus before a billable full run, then train rank-16/alpha-32 QLoRA for one 840-row epoch with balanced effective batches. | L4 `medgemma-qlora-l4-03`; train hash `c93692d…79463`; fixed 30-case sentinel hash `c18cac5f…c26d`; rank 16; alpha 32; LR `1e-4`; gradient accumulation 30; 28 optimizer updates; checkpoint every 5 optimizer updates; seed `20260912`. | Smoke completed two optimizer updates, mean 30-cell validation loss `0.905209`, successful adapter reload, valid JSON and EOS; its deliberately under-trained generation failed one grounding rule (`6 out of 10` cited only as `included_count`). The first full launch was interrupted at microstep 10 before any optimizer update after its audit exposed that random interleaving did not guarantee exact accumulation-window coverage. The sampler was repaired and 20 focused tests passed. Corrected run `full-02` is active: all 28 windows contain exactly 30 unique state × intent cells, maximum same-state run 1, and GPU training was verified at 100% utilization. | Remote smoke: `reports/20260917-qlora-r16-v7-smoke-01/`. Aborted pre-update run: `reports/20260917-qlora-r16-v7-full-01/`. Active canonical run: `reports/20260917-qlora-r16-v7-full-02/`, tmux `medgemma-qlora-r16-v7-full2-20260917`. Do not treat the smoke semantic warning as a quality result; evaluate the frozen 210-case test only after training and sentinel validation complete. |
| J-068 | 2026-09-17 · Day 5 v7 completion and frozen-test evaluation launch | Verify the corrected full run and start evaluation without revising the frozen test set. | Full run completed 840 microsteps and 28 optimizer updates; mean 30-cell validation loss `0.114522`; test SHA-256 `3b3af111…ac4b`; native EOS; no explicit token cap; 45-second per-case safety timeout; atomic report checkpoint every 10 cases. | One-case test gate passed: EOS in 20.368 seconds, schema valid, guard accepted, no fallback, and grounded contradictory-state output. The full 210-case test evaluation is active in tmux. | Training: `reports/20260917-qlora-r16-v7-full-02/`. Evaluation: `reports/20260917-qlora-r16-v7-test-eval-01/test.json`; log `test.log`; tmux `medgemma-qlora-r16-v7-test-eval-20260917`. After completion, run the deterministic aggregate and in-thread constrained semantic review before making a quality claim. |
| J-069 | 2026-09-17 · Day 5 v7 frozen-test semantic review | Judge every raw v7 test output against its frozen evidence, held-out answer, deterministic result, finding state, and requested intent. | Test SHA-256 `3b3af111…ac4b`; 210 paired cases; constrained grounding, uncertainty, safety, usefulness, and verdict fields; raw output judged before fallback; neighboring cautious states are review rather than automatic failure when the practical conclusion remains useful. | Complete. Native EOS 210/210; schema valid 210/210; guard accepted 203/210; fallback 7/210; semantic verdicts 76 pass, 102 review, 32 fail. State slices: contradictory 34/8/0, developing 7/34/1, insufficient-data 21/21/0, null 14/23/5, supported 0/16/26 (pass/review/fail). All 35 observe-next cases mismatch the held-out action ID. Uncertainty and safety passed 210/210. | Local artifacts: `outputs/qlora-r16-v7-test-semantic-review-20260917/` in the experiment workspace. V7 fixes v6's universal state collapse, but supported-state weakening and action-policy learning remain blockers. Keep rank 16/alpha 32; repair labels/action modeling before another training run. The 17-case product safety-suite run remains separate and pending. |
| J-070 | 2026-09-17 · Day 5 v7 rollback snapshot | Preserve the exact v7-r2 dataset, all resumable checkpoints, final adapter, evaluation, semantic review, and producing code before any repair. | Lifecycle-exempt prefix `gs://vueniverse-508413-medgemma-training/rollback/v7-r2-r16a32-20260917/`; seven optimizer checkpoints at steps 1, 5, 10, 15, 20, 25, and 28; SHA-256 anchors recorded in `ROLLBACK-MANIFEST.md`. | Complete. Inventory verified at 124 objects and 589,179,517 bytes before adding the manifest; the backup is outside the current automatic-deletion prefixes. | Restore into a new directory and verify hashes before resuming. Do not overwrite v7 artifacts in place. |
| J-071 | 2026-09-17 · Day 5 v8 data/action repair | Separate deterministic product action selection from language generation and create a new immutable label revision. | Application policy derives `next_observation_id` from finding state, ask intent, and approved actions; raw model action remains benchmarked; delivery records model value, delivered value, and override. V8 uses 840/210/210 rows, exact 30-cell balance, maximum same-state run 1, state-invariant summaries, intent-specific paragraphs, and null model action targets. | Local implementation and data gates complete. A 30-cell sample audit caught three awkward generic templates in the first draft; corrected `v8-r2` uses state-specific wording. All 1,260 labels pass the deterministic guard; state-summary violations 0; model-owned action targets 0; cloud preflight passes; train/validation/test SHA-256 `2ece6644…290d5`, `efff0efb…5f94a`, `f3fc362f…02a9`. | Design: `docs/finetuning/dataset-v8-design.md`; canonical artifacts: `tooling/medgemma/outputs/finetuning/supervised-dataset-v8-r2/` and messages-only `cloud-upload-v8-r2/`. The first local v8 draft is retained but superseded. No upload, GPU run, or additional cloud spend was started. Run the complete pinned test suite before authorizing another training run. |
| J-072 | 2026-09-17 · Day 5 v8-r2 preflight, smoke, and full launch | Transfer the messages-only v8-r2 projection and 30-cell sentinel, verify the pinned environment, run a two-update smoke, and launch the authorized full epoch. | VM `medgemma-qlora-l4-03`; projection hashes train `872a1077…7cc`, validation `0155a176…c07`, test `e59af425…1d1`; sentinel `d4966805…667`; rank 16/alpha 32; LR `1e-4`; gradient accumulation 30; full run 840 microsteps / 28 optimizer updates; checkpoint every 5 updates. | Full pinned suite passed 90/90. Smoke exit 0 with losses `1.335335 → 1.064543`, mean 30-cell validation loss `1.110381`, two checkpoints, adapter reload, EOS, and 14,472,692,736-byte peak allocation. Its deliberately under-trained generation correctly failed one grounding check after mentioning candidate count `10` without citing `candidate_count`; this is retained as a non-passing semantic warning. Full run launched in tmux and verified at 100% GPU utilization with approximately 19.9 GB allocated. | Smoke: `reports/20260917-qlora-r16-v8-r2-smoke-01/`; active full run: `reports/20260917-qlora-r16-v8-r2-full-01/`; tmux `medgemma-qlora-r16-v8-r2-full-20260917`. Do not claim a model-quality result until the full report, checkpoints, reload, frozen test evaluation, and semantic review are complete. No automatic shutdown is scheduled. |
| J-073 | 2026-09-17 · Day 5 v8-r2 completion and frozen-test evaluation launch | Verify full training completion, pass a one-case frozen-test gate, and launch the complete 210-case test loop. | Training exit 0; 840 microsteps / 28 optimizer updates; seven checkpoints; final loss `0.086541`; mean 30-cell sentinel loss `0.206500`; test projection SHA-256 `e59af425…1d1`; native EOS; 45-second safety timeout; atomic report checkpoint every 10 cases. | Training artifacts and fresh adapter reload passed. One-case gate completed in 14.077 seconds with 104 generated tokens, EOS, schema valid, guard accepted, no fallback, and null model/application action. Full evaluation launched; case 0 completed in 13.935 seconds with the same clean gates. | Training: `reports/20260917-qlora-r16-v8-r2-full-01/`. Active evaluation: `reports/20260917-qlora-r16-v8-r2-test-eval-01/test.json`; tmux `medgemma-qlora-r16-v8-r2-test-eval-20260917`. After completion, retrieve the report and perform deterministic aggregation plus the required case-by-case semantic review. No automatic shutdown is scheduled. |
| J-074 | 2026-09-18 · Deployment | Merge the selected LoRA BF16 v7 adapter, convert the merged MedGemma 1.5 4B weights to GGUF, and quantize the deployable artifact. | Selected LoRA v7 adapter from the frozen three-model benchmark; MedGemma base checkpoint; pinned `llama.cpp` revision `5839ba352471b2a7b45e7ba401619a6896f10f8b`; F16 GGUF; Q4_K_M artifact. | Complete. Safe adapter merge passed; F16 GGUF was 7.3 GiB; Q4_K_M artifact is 2.4 GiB with SHA-256 `dd9c2a212672a5bb18affbc344a4c0fcf4e9000b3b5155d6fdfe9a8104bad234`. | Artifacts are retained on the persistent disk under `deployment/`. The source archive was transferred only because the private VM has no outbound NAT; no model or personal wearable data was exposed. |
| J-075 | 2026-09-18 · Deployment acceptance | Build a CUDA runtime specifically for the L4, start the localhost-only guarded service with the LoRA v7 Q4 artifact, and run the stable end-to-end fixture. | `medgemma-qlora-l4-03`, `us-east1-b`; L4 CUDA target SM 8.9; tmux `medgemma-lora-v7-deploy-service3-cuda-20260918`; service bound only to `127.0.0.1`. | Complete. The model loaded on the L4 (2,922 MiB); fixture output was schema-valid; time to first token 271 ms; model response 1,801 ms; external fixture invocation 2.02 s. | CPU-only serving exceeded the intentional 30-second application deadline, confirming GPU-backed serving is required for this VM-local deployment. The CUDA service is explicitly retained running at the user's request; it remains billable until stopped. |
| J-076 | 2026-09-18 · Deployment safety | Run the existing 17-case product safety regression through the exact LoRA v7 Q4 artifact and pinned CUDA runtime. | 17 fixed product safety cases; Q4_K_M artifact; L4 CUDA `llama-server`; max output 384; greedy decoding with JSON-schema grammar; tmux `medgemma-lora-v7-q4-safety-20260918`. | Complete. Raw schema-valid 17/17; raw guard accepted 16/17; fallback 1/17; delivered guard accepted 17/17; server load 4.22 s; mean TTFT 355 ms; mean generation 2.62 s. | The only raw guard miss was `diagnosis`: a valid JSON response mentioned `+11` in a paragraph without its matching `median_difference_bpm` citation. Deterministic fallback delivered a guard-valid non-diagnostic response. Runtime report: `deployment/lora-v7-q4-safety-eval/gguf-benchmark.json`. |
| J-077 | 2026-09-18 · Deployment runtime | Restore the validated localhost-only CUDA service after the isolated safety runner released the GPU. | tmux `medgemma-lora-v7-deploy-service-final-20260918`; Q4_K_M LoRA v7 artifact; L4 CUDA runtime; bind address `127.0.0.1:8765`. | Complete. `/ready` returned 200 and the `llama-server` process holds 2,922 MiB on the L4. | The service has no external listening address. The VM and L4 remain active by explicit user instruction, and normal charges continue until the user requests stop. |
| J-078 | 2026-09-18 · Archive and teardown | Archive the complete reproducible LoRA v7 experiment bundle to the private project bucket, verify critical objects and checksums, preserve the final research paper and source, then stop the billable VM. | Private prefix `gs://vueniverse-508413-medgemma-training/resurrection/20260918-lora-v7-final/`; base checkpoint; merged and Q4 artifacts; adapters, checkpoints, synthetic datasets, configs, reports, tooling, checksum manifest, README, final PDF, and PDF source. | Complete. Upload completion marker `RESURRECTION_UPLOAD_EXIT=0` was read from the bucket; README, 2.10 MiB SHA-256 manifest, 2.32 GiB Q4 artifact, and 4.62 GiB base-model shard were verified. The final paper, its source, and a post-archive SHA-256 manifest were added and listed. VM `medgemma-qlora-l4-03` in `us-east1-b` verified `TERMINATED`. | The temporary localhost-only service ended with the VM. GPU and vCPU/RAM billing has stopped; persistent Cloud Storage and any retained persistent disks remain billable storage. The archive contains synthetic model-facing data only, not raw wearable or private canonical-event records. |

## Product-readiness follow-up

### J-079 — 2026-09-25: Roadmap and matched-control repair

Created the active checklist at
`/Users/rakesh/Documents/ChatGPT/finetune medgemma/PRODUCT-READINESS-ROADMAP.md`.
It sequences analytical correctness, independent evaluation, Android LoRA integration,
physical hardware checks, release preparation and a consented longitudinal pilot.

Reproduced a control-selection defect: filtering target meetings also removed other
calendar events from the control-exclusion context. Four regression cases failed
before the change. The engine now uses all known calendar events when rejecting
contaminated controls, while retaining the requested target selection. Five focused
control tests pass, including no-clean-control and non-overlap boundary cases.

Meeting analysis version is now 2. `runPending` detects outdated analysis/promotion
versions even without new source records. A legacy-database regression verifies
replacement of old evidence, stale marking and subsequent idempotent reuse. Full
dependent-artifact invalidation remains an explicit roadmap item.

Verification: 15 targeted tests passed; `flutter analyze --no-pub` passed. Existing
demo analytical results stayed unchanged. Existing unrelated edits and all frozen
model/dataset artifacts were preserved. No VM, cloud job or new training was started.
The unconditional alternative-explanation gate remains open under roadmap P1.2.

### J-080 — 2026-09-25: Explicit caffeine context policy

Replaced the unconditional alternative-explanation gate with a scoped caffeine
screen for both meeting and control windows. Preserved structured servings and
coverage in the analytical input; missing/invalid/unscoped logs remain unknown,
positive reports flag exposure, and only complete zero self-reports pass. Recorded
separate unknown/exposure pair counts and their union, plus check-in dependencies.
Analysis/promotion versions are now 3/2. Updated evidence projection, deterministic
explanation, UI labels and demo expected state to developing without changing raw
demo measurements or frozen training/evaluation artifacts.

Full Flutter suite: 108 tests passed, including 12 new policy tests. Static analysis
passed. The first full-suite run exposed two expectations for the old supported label
and quiet-buffer suggestion; both were updated to assert the deliberate policy change.
Specification: `docs/finetuning/caffeine-context-policy.md`. A structured intake/coverage
form remains required before users can satisfy the new zero-report gate. Other
influences and full invalidation remain roadmap tasks. No cloud compute was started.

### J-081 — 2026-09-26: Structured check-in capture and source identity corrections

Completed roadmap P1.2a: explicit servings and completed-period local date/time
selection, UTC serialization, save/edit/reload mapping, shared validation and visible
save failure handling. Blank intake remains unknown; zero is explicit. Scoped report
edits use the current report time. Historical unscoped records remain unknown.

End-to-end testing exposed two pre-existing imported-source defects. Deletion now
uses the indexed source for the actual canonical record. Editing imported demo data
atomically replaces its old source identity so the original cannot coexist with its
correction. Normalization rejection rolls back the replacement transaction.

Verification: full Flutter suite passed 114 tests, including saved zero-report ->
supported caffeine screen -> positive edit -> developing, imported-ID uniqueness,
timezone round trip, invalid-input rejection, and form save failure tests. UI tests
were adjusted for the expanded scrollable form and the synchronous keyboard-test API.
No cloud resources or frozen model/dataset artifacts were modified. Other influences,
recurrence identity and full invalidation remain roadmap work.

### J-082 — 2026-09-26: Symmetric recorded-context screening

Advanced P1.3 locally without cloud operations. A shared helper now rejects
recorded illness/travel/manual-exercise days on both meeting and control sides,
and applies the same workout overlap plus inclusive 30-minute recovery buffer.
Future-dated check-ins are ignored at the analysis cutoff. Analysis version is 4
so the existing normal refresh version check recomputes older evidence.

Nine additional regressions cover all three check-in categories on both sides and
workout recovery boundaries at 0, 30 and 31 minutes. Full suite: 123 passed;
Flutter analysis: no issues; scoped diff whitespace check passed. Initial suite
failures exposed obsolete demo/version assertions, corrected after inspecting the
per-occurrence control allocation. Raw fixture records were not changed.

Main demo now has 7 included meetings, 11 controls, 6 positive differences,
1 counterexample and 5 exclusions. Median remains +11 bpm; positive range is
+8–18 bpm; recovery median 39 minutes. It remains developing. See
`docs/finetuning/recorded-context-screen.md` for policy, limitations and allocation
changes. Historical training datasets, checkpoints and benchmarks are untouched.
P1.3 remains partial: recurring identity, DST/missing-context coverage and greedy
allocation sensitivity remain open. Comprehensive dependency invalidation is P1.4.

### J-083 — 2026-09-30: Personal GitHub experiment snapshot

User authorized a personal repository copy, new branch and README update. Prepared
`crixalis17/medgemma` as a private repository with preserved original Git history
and branch `codex/medgemma-experiments-roadmap`. Included accumulated application
changes, latest staged LoRA training/evaluation source, synthetic messages-only
dataset snapshots, experiment judgments/workbooks/plots, research PDF, recovery
guide and roadmap. Large model/checkpoint artifacts remain in the documented
private Cloud Storage archive; raw wearable data and credentials remain excluded.
Publication verification is recorded in the Git commit and remote branch state.

### J-084 — 2026-09-30: Rename personal experiment branch

At the owner's request, renamed the personal GitHub and local branch to
`medgemma-experiments-roadmap`, removing the Codex prefix. Updated README clone
instructions and branch tracking. The J-083 branch name records its original name.

### J-085 — 2026-09-30: Vueniverse repository naming and main default

Renamed the personal repository to `crixalis17/vueniverse` and updated the local
origin URL. Set `main` as the default branch at the owner's request. README on
both branches points to `medgemma-experiments-roadmap` for accumulated experiments.
The existing local checkout remains `/Users/rakesh/Documents/repo/medgemma`.

### J-086 — 2026-09-30: Project README refresh

Reorganized the repository overview into product purpose, current branch/runtime
state, evidence flow, synthetic fine-tuning methods, benchmark findings, research
artifacts, local setup and remaining milestones. Replaced older runtime notes with
explicit selected-LoRA versus Android-vanilla status. Experiment links resolve to
the experiment branch from either README. Published the overview to both main and
the experiment branch; preserved datasets and model artifacts without rerunning
training. Checked README links against tracked files and benchmark source reports.

### J-087 — 2026-10-03: Separate recurring meeting series

Continued P1.3 after inspecting native Calendar ORIGINAL_ID/EVENT_ID mapping,
source synchronization, normalized HMAC series keys and analytics input mapping.
The key already reached analytics but was unused. Analysis version 5 now selects
one identified cohort (largest count, latest occurrence, deterministic key tie),
without looking at measured effects. Explicit mixed-series event selections
require a series key. Missing keys cannot contribute usable occurrences; all
calendar events still screen controls. Evidence payload retains the selected key.

Eight new regressions verify cohort separation, missing identity, explicit selection,
order-independent cohort choice, other-series contamination and normalizer identity
stability. Full Flutter suite: 131 passed; static analysis clean. Existing demo
measurements and states remain unchanged. Policy: recurring-series-policy.md.
P1.3 remains partial for time/context coverage, control allocation and future source
identity lifecycle. No cloud session or retraining. Frozen research artifacts remain
unchanged. README and both roadmap copies updated; code lives on the experiment branch.

### J-088 — 2026-10-03: Control allocation, timing and freshness boundaries

Implemented analysis v6: eligible-only, maximum-cardinality/minimum-cost global
control assignment; 60 randomized small graphs agree with exhaustive optima.
Shifted overlapping controls conservatively abstain rather than double-counting.
Recorded-offset partitioning rejects mixed windows; half-open minute aggregation
excludes readings outside sub-minute boundaries. Demo recomputation now has eight
usable/control pairs, six positive and two contrary, median +11 bpm and 42-minute
recovery. Raw fixtures and historical trained datasets were not rewritten.

An initial broad invalidation/deletion proposal was rejected by automatic approval
review and was not applied. Replaced it with shared read-only freshness gates for
evidence, projections, replay, explanation caching/delivery, experiment use and
export sharing. Historical files/conversations/protocols remain retained. Added
canonical-input hashes to payload identity, active-only reuse and replacement run
nonces. Corrected initial refresh tests that revealed legacy same-hash reuse and
fixed-clock identity collisions. Experiment context now comes from backing included
windows, not the latest calendar event. Pending: scheduled reminders and hardware
source-deletion checks, reliable timezone identity and context coverage.

### J-089 — 2026-10-03: Frozen readiness contract and pipeline development cases

Froze readiness-evaluation-contract-v1 before generating ten raw timeline families
and 30 intent projections through the actual app normalizer/database/analysis code.
Preserved raw envelopes, hashes, deterministic outputs and blank reviewer forms.
Added package integrity/cluster checks and constrained semantic judgment validation;
independent review and final-set custody remain pending. Paired sign-test and Holm
utilities are standalone research diagnostics, not promotion gates or medical claims.

The first generated package had 28/30 deterministic guard passes: a safe developing
phrase contained "treated", triggering the existing treatment substring guard.
Changed wording without loosening safety. Corrected the generator's third intent
to the app's `observe_next`; it exposed intervention numbers copied into measured
numeric prose. Parameters now stay in the exact-approved observation field. Final
development package: 30/30 deterministic guard passes, no new model-quality claim.

Verification: 154 Flutter tests pass; Flutter static analysis clean; 97 Python tests
pass, two optional tests skipped; new Python lint checks clean. Sandbox-only pytest
cache warnings did not affect results. No VM started, no training or model serving,
no private health records published. Existing Ultrahuman probes/coarsened profiles
remain available locally; fresh API retrieval is unnecessary for these deterministic
regressions. User additionally authorized personal Ultrahuman data as a future
calibration/overlay reference; invented events must never become observed history.

### J-090 — 2026-10-03–04: First-person collection and Android candidate preparation

Owner confirmed Nothing Phone 2 / 8 GB and manual check-ins as the initial canonical
input. Split work across connector, ledger and Android-artifact agents; integrated
centrally. Added collection-first onboarding without mandatory Calendar/model
download, session-only Ultrahuman key entry, explicit provider dates, exact HR/sleep
normalization and read-only metadata history. HRV/steps remain unsupported rather
than guessed. Existing private probes were inspected for shape only; no fresh
personal API call or health upload was made.

Import ownership uses a local credential HMAC, not a persisted token/account claim.
Source generations and transactional checks stop delayed persistence after
pause/disconnect/delete. Concurrent imports, key changes, partial failures and
legacy/malformed receipt details have regressions. Mapper input/duplicate/rejected
denominators are separate from diagnostic rejection counts. Completed receipts
record new/changed/repeated facts; older missing facts stay unknown. Manual refresh
does not fabricate a timestamp; Ultrahuman needs explicit key re-entry. Check-in
deletion and onboarding await persistence before visible success.

Prepared the archived LoRA v7 Q4 candidate manifest and explicit Android variant,
distinct filename/revision, revision-scoped download work and artifact-aware cache
reuse. Default vanilla rollback remains. Compiled production and real-prompt test
APKs plus an opt-in instrumentation wrapper. Inspected local Flutter installation
logic: its failed-update fallback can uninstall an existing app, so owner-phone
instructions use explicit install-r and restore rather than managed Flutter tests.
Existing store-erasure tests now require disposable-device opt-in.

Advanced meeting analysis to v7 for exact event-end recovery slots; supported-only
intervention eligibility is enforced at projection, repository, persistence and
scheduling boundaries. Stale protocol alarms are reconciled without deleting
historical records. Inactive OS alarm freshness remains unverified on a phone.
Preserved development-v1 and generated development-v2: 30 cases / ten clusters,
30 guard passes, integrity/split checks pass; independent review remains pending.
No research dataset, adapter, training checkpoint or historical model score changed.

Early checks caught/fixed dropdown overflow, stale receipt-fixture expectations,
a missing Drift operator import, and a test that incorrectly expected a demo store
to contain no historical protocols. Android testing caught clipped import feedback;
it now sits in a fixed accessible area. A later missed tap exposed a harness scroll/
keyboard timing issue; tests now settle layout before submission.

Verification before final race review: 213 Flutter tests; clean static analysis; 107 Python tests passed,
two optional skipped; 34 candidate Android unit tests passed and APK builds succeed.
After user approved emulator testing, launched WhyPulse_API_34 at emulator-5580
with read-only/no-snapshot isolation (original AVD unchanged). Final 23 integration
checks pass: onboarding, credential/date UI, populated/empty/malformed ledger and
pagination, mocked imports including cancellation races, plus real Android Keystore
encryption/isolation and manual save/edit/reopen/delete. No owner phone was installed
or wiped. Provider transport is mocked; emulator success is not live-account or
phone-performance acceptance. Actual LoRA prompt compatibility is a separate run.

Implementation and pending acceptance are recorded in FIRST-PERSON-MILESTONE.md.
No VM, new training or hosted model server started. Artifact download/storage/egress
may incur charges independently of compute; no zero-cost claim is made.

Retained-model emulator compatibility preparation restarted only the isolated copy
with 8 GB RAM after checking the original 4 GB available memory/storage. Initial
private model retrieval failed when macOS blocked the SDK's quarantined, ad-hoc-
signed gcloud-crc32c helper; no final model file was produced or staged. Read-only
inspection confirmed the helper's SDK location/signature, not malware-free status.
Did not remove quarantine, allow the binary or weaken Gatekeeper. Alternate transfer
uses the installed SDK's Python CRC path with command-scoped
`CLOUDSDK_STORAGE_USE_GCLOUD_CRC32C=false` and `CLOUDSDK_STORAGE_CHECK_HASHES=always`;
the pinned independent SHA-256/size checks remain mandatory before staging.
Compatibility outcomes are recorded separately when available.

Alternate checksum-preserving download completed successfully; independent host
verification matched exactly 2,489,893,568 bytes and the full archived
`dd9c2a212672a5bb18affbc344a4c0fcf4e9000b3b5155d6fdfe9a8104bad234` SHA-256.
Single-copy staging targets only disposable emulator-5580; device copy verification
and model execution are separate gates. The rejected helper was never approved.

Final read-only connector review found an initial-status/catch-status TOCTOU and
store disposal during foreground import. Added transactional generation/binding
checks for claims and all error writes, blocked store switching while collection
is busy, and prevented delayed/disposed reload mutations or secondary reload errors.
Nine additional regressions bring the full Flutter suite to 222 passing tests.
Intervention initiation also requires exactly one finite zero unresolved-count
metric; missing/duplicate accounting cannot mean zero. Reminder reconciliation now
runs after source actions, manual edits/deletion, calendar review and app resume.

### J-091 — 2026-10-04: Production bootstrap and committed-write boundaries

Continued with parallel emulator, connector and publication reviews. The retained
LoRA transfer exposed an ADB transport issue: large stdin streams stalled, including
an initial PTY-backed transfer. Interrupted only those task-owned transfers, switched
to bounded raw/no-PTY chunks with explicit byte counts, and independently matched
the entire guest model size/SHA. Partial bytes were never used for inference.

The real-prompt instrumentation wrapper then failed before generation because the
old ActivityScenario receiver lacked the API-34 export flag. Replaced only that
wrapper with stock Instrumentation activity launch/finish and compiled it. Installation
next hit the disposable clone's storage reserve (334 MB free); did not delete unknown
files or disable the reserve. An inherited-clone `-partition-size` restart did not
enlarge userdata. A fresh SDK-pristine AVD in a task-specific temporary directory
provides its own 16 GB data partition and 8 GB RAM; original AVD and owner phone
remain untouched. Model prompt outcomes are a separate compatibility record.

Added a production-bootstrap journey invoking actual main/ProviderScope/SQLCipher,
not injected save callbacks. Initial harness fixes covered lazy-row positioning and
loading-safe restart waiting. A suspected input-method echo was not the cause and
the workaround was removed. Receipt probes proved edits had committed while later
analysis failed. A regression reproduced `Too many elements`: the latest prior-
finding query used getSingleOrNull without limit(1). Added the missing limit and
verified four linear finding versions from bootstrap plus three manual revisions.
The actual production onboarding/save/edit/encrypted-reopen journey now passes,
with no invented health/calendar records or model download. A separate aggregate
suite passed 27 checks including mocked-provider races and Android Keystore storage.

Split successful check-in persistence from post-commit analysis/refresh. Only true
storage failures keep the form open; successful saves/deletes remain acknowledged
if downstream refresh fails, with a visible analysis-only retry. Current findings,
replay and answers are suppressed until freshly loaded; late inference is invalidated.
Completed Ultrahuman imports receive the same truthful collection-versus-analysis
distinction. Reminder freshness reconciliation runs even when recompute fails.
Actual in-memory database regressions cover committed add/edit/delete across analysis
and finding-read failures, retry without new import receipts, disposal and concurrent
operation guards. UI regressions verify form closure and retry without another write.

The first full pass after the storage split was 233 Flutter tests, static analysis
clean; subsequent boundary regressions and final verification are recorded in the
local acceptance table. Production journey: 1/1, approximately 14 seconds of test
body; aggregate: 27/27. Closed only task-owned clone 5582 after its checks. No
physical phone, owner API key, fresh personal health request, new model training or
cloud compute resource was used. Source-deletion post-commit handling is undergoing
the same independent review before publication; milestone gates remain open.

Final source-boundary review repaired three additional cases: partial manual-source
deletion could restore removed text after a read failure; Ultrahuman resume tried a
keyless refresh; and a committed manual deletion with failed analysis retained old
Observe aggregates. Source-mutation generations now reject late snapshot/read results,
and partial imports restore only verified surviving records. Resume acknowledges a
policy change, not an import; the user must explicitly supply a session credential.
Clearing derived views preserves the deterministic Demo clock. Final Flutter suite:
252 passed; static analysis clean. Updated bounded Python suite: 110 passed.

### J-092 — 2026-10-04: Native compatibility diagnosis and public publication review

API-34 asynchronous activity launch resolved a second wrapper issue: synchronous
launch waited for Flutter's test-idle signal and timed out before generation. Actual
JNI entrypoint instrumentation exposed seven stale old-package exports; corrected
all to the renamed Vueniverse package. The entrypoint smoke check passed, distinct
from semantic/production-prompt compatibility.

Three retained synthetic app intents initially timed out at roughly 123 seconds.
Inspection of actual compiler commands found unoptimized Debug GGML C/C++ flags.
An explicit validated release-style optimization option adds -O3, not fast-math;
the next three calls took about 45 seconds but still failed the output schema.
Code review then found a sampled-token pointer borrowed beyond a loop-local token's
lifetime. Replaced it with function-scope stable storage and compiled the actual
helper at -O3 with undefined-behavior sanitizer coverage. The initial combined
address-sanitizer probe hung during macOS sanitizer initialization; it was stopped
and is NOT a passing ASan result. Bounded UBSan regression passed. The lifetime-safe
three-case report still recorded zero raw accepted answers and three safe fallbacks.

Default-off fixture-only diagnostics report structure and numeric timing, never
prose, unknown keys or reasoning text. The unchanged why_promoted case used 931
prompt tokens and exhausted 384 generated tokens: prefill 25,922 ms, generation
decode 20,086 ms, total 47,110 ms, native 46,329 ms. No complete JSON or recognized
thought/turn markers were observed. This proves a bounded non-JSON completion for
that call, not a training failure or a semantic assessment of hidden text.

Read-only comparison found a concrete integration gap: frozen v7 targets use
schema_version 2, paragraphs arrays and ID-keyed observations; Android v5 requested
camel-case keys with a doubly encoded paragraph array and observation strings.
The archived evaluator also continued an authoritative assistant JSON prefix.
Implementing a LoRA-only version-6 prompt/strict translation, preserving exact app
metric IDs and meanings, absent context, known observation lookup and the existing
Dart guard. No fabricated consistent_count/effect_range aliases, automatic JSON
repair or new training. Compatibility retest results are recorded separately.

Owner explicitly approved reviewed changes in public crixalis17/vueniverse on the
existing medgemma-experiments-roadmap branch. Reviewed fixtures are Demo/in-memory;
new personal API payloads, credentials, host model weights and build/test caches
remain excluded. Existing research datasets/adapters/checkpoints remain frozen.
No new GPU VM, hosted model server, personal API request or physical-phone test ran.

The LoRA6 aligned 384-token case took 60,494 ms total / 59,746 ms native, using
1,383 prompt tokens, and again exhausted its output allowance. One bounded LoRA-only
512-token check (vanilla kept 384; deadline remained 120 seconds) took 67,630 ms /
66,827 ms native. It exhausted 512 tokens without EOS, reconstructing 2,777 characters
of incomplete JSON. Whitelisted lexical markers are explicitly not parsed schema;
the completed summary was 160 characters, while no complete paragraph text or
uncertainty string was measured. Both calls used safe fallback, never accepted LoRA.
Fifty-one native unit tests passed before constrained-decoding work.

More tokens alone did not establish a usable answer. Added LoRA-only continuation
GBNF using the pinned native library: bounded strings/whitespace/paragraphs and exact
request ID allowlists, without private values in the grammar. The decoder and Dart
guard remain strict; malformed grammar fails closed rather than silently becoming
unconstrained. Phone contract/projection version 7 invalidates the prior cache shape.
This is an integration change, not fine-tuning or a new accuracy benchmark.

The latest production-bootstrap rerun twice failed before saving the edit because
the injected text reverted to the initial value. Kept strict pre-save and encrypted
reopen assertions, restored the verified normal APK, and added immediate-input/focus
diagnostics in the fixture harness. Installed Flutter source explicitly warns that
TestTextInput injection with a real IME can confuse input state; investigating this
boundary instead of modifying the product controller without evidence. Prior bootstrap
pass remains preserved and is not silently substituted for these later failures.

Public-artifact review also found owner-derived sampling-density/historical-coverage
metadata in the older tracked Ultrahuman audit. Preserved its original privately in
the ignored Ultrahuman output directory with mode 600, and minimized the current
public digest to structural fields and coverage limitations. This does not scrub
previous public Git history; no force push/history rewrite occurred. Private raw
files and the original remain available locally; no personal payload was fetched.

### J-093 — 2026-10-05: Resume, candidate quarantine and collection acceptance

Resumed at the user's request after stopping disposable emulator 5580 for the night.
No cloud VM, GPU, hosted model, personal API request or training run was started.
Parallel agents handled collection input diagnosis, native/build review and an
independent read-only candidate-gate/publication review. Existing frozen datasets,
adapters, research scores and preserved checkpoints remain unchanged.

The final October 4 bounded-grammar three-intent report records schema validity 3/3,
automated guard acceptance 1/3, and two fallbacks. Manual review rejected the recovered
accepted answer: “zero” contradicted consistency 0.75, and unresolved caffeine context
was misrepresented as no usable comparisons. The two rejected model texts were not
captured and cannot be semantically scored. Android truncation leaves some accepted
fields unavailable, not confirmed null. Original as-built APK/contract hashes remain
preserved. Grammar solves structure/completion, not factual grounding.

Normal LoRA builds now return contractUnverified/candidate_not_approved, with direct
explain/explore blocked before native load/inference. The fixture evaluation capability
defaults off, requires the canonical contract-test target and approved debug tasks,
and is forced off for release. Current artifact availability is required for accepted
cache reuse; historical candidate rows are retained but cannot bypass quarantine.
Exact nullFinding/insufficientData state aliases normalize spelling only; positive
counts and absolute effect bounds are not relabeled. A second agent found no scoped
gate/cache bypass. Default vanilla is unchanged; it is not thereby clinically certified.

Current full suites passed 254 Flutter tests and 110 Python tests; static analysis
is clean. Python includes the bounded optimized native token-lifetime UBSan regression,
not a claimed ASan pass. Final native/build evidence follows below when completed.

The production-bootstrap investigation preserved strict assertions throughout.
The first diagnostic's hasAnyClients getter asserted because mock input was not
registered; only that diagnostic getter was guarded. The corrected diagnostic proved
fixture text initially matched, with focus/shared controller true and registration
false, then reverted before save after scrolling. Installed Flutter source warns
about injected TestTextInput conflicting with the real IME. Registered mock input
only during fabricated create/edit typing and save, unfocused/released it before
actual-main restart, and added teardown safety. No product controller changes or
direct controller assignment were made to force a pass.

The latest production-bootstrap passed 1/1 on the same temporary API-34 ARM64 clone:
13-second body, real main/ProviderScope/encrypted persistence/reopen, two truthful
receipts (one inserted and one changed), no supported finding or invented health.
Fixture-input SHA-256: 1154f4f50d0b4b3d0515108bdc22a819c1896a17a580c92b03a6a6cef41b6af5.
Main SHA-256: 2979b13f24ac4f0b376686ad12546bde9152c7f2545284e50d45a1b0ef7874db.
AppState SHA-256: abcc7484432489accb78ad0b43dcbb0edecfc69e2058a30cf105a3c1fa9f9c34.
Local log: /private/tmp/vueniverse-production-bootstrap-mocked-input-20261005.log.
This proves current collection storage flow with fixture typing, not a real keyboard,
personal API or physical-phone acceptance. Earlier failures remain in J-092.

Independent publication preflight inspected 104 pending files (~2.05 MB) and found
no new credential/raw owner payload/weight/APK/database inclusion. New timelines are
reproducible bundled demo fixtures. Private originals and model caches remain ignored;
the earlier audit minimization does not erase public history. Existing private bucket
identifiers and owner-reported device metadata are reproduction references, not access
grants; no bucket permissions or repository visibility were changed.

Final verification: 59/59 native tests passed for each of LoRA and vanilla, with no
failures/errors/skips. Eight invalid/unsafe configuration checks rejected as intended.
Built a new normal-main LoRA-selected debug APK with native release-style optimization,
candidate evaluation off and contract diagnostics off; generated capabilities are
false and the native diagnostic tag is absent. Retained file:
build/phone-contract/production-lora-v7-held.apk; SHA-256
0eff1338f0c6015961345b1befec04f9ccf94f194c34131ee06684babe68b4b6.
Update-installed only on disposable 5580 and verified MainActivity resumed. Activity
start metadata (1,394 ms) is not inference latency or a user-flow benchmark. Stopped
the clone and filtered captures, preserving the original AVD, temporary AVD and
verified ignored model cache. No model call/download/staging was made during these
final checks. Captures ending on device shutdown are teardown, not model failures.

Repository formatting gate passed after wrapping fixture/cache-test code; 13 focused
tests passed after formatting. Historical inference reports retain their original
as-built hashes. The final native/build and local-acceptance JSON reports summarize
this scope separately from model-semantic and physical/live gates. Reviewed changes
are prepared for the existing medgemma-experiments-roadmap branch; main stays default.


## Artifact and resume contract

Each cloud run will use an immutable run ID such as `20260914-qlora-smoke-01`. It must
write the following locations before the VM is stopped:

```text
gs://vueniverse-508413-medgemma-training/
  configs/<run-id>/                 pinned environment and training configuration
  datasets/<dataset-version>/       immutable redacted dataset and hashes
  checkpoints/<run-id>/             resumable checkpoints; lifecycle 14 days
  adapters/<run-id>/                final PEFT adapter and tokenizer/configuration
  reports/<run-id>/                 metrics, evaluation, cost, and run manifest
  staging/<run-id>/                 transient files; lifecycle 3 days
```

Each run manifest must include: base model and revision; dataset and prompt hashes;
Python/CUDA/PyTorch/Transformers/PEFT/TRL/Datasets/bitsandbytes versions; GPU and VM
shape; seed; training configuration; start/end timestamps; checkpoint path; raw and
post-fallback evaluation results; peak GPU memory; VM state; and observed cost.

## Cost-safe inactive state

The training VM will be stopped, not deleted, after a maximum four-hour active session.
Stopping removes GPU and vCPU/RAM charges. Its 100 GB persistent boot disk remains, so
the operating system, installed packages, model cache, and local working directory can
be used again after a manual restart. RAM, running processes, and unsaved files do not
survive a stop.

To resume safely, the training process must save checkpoints to the bucket and record
the last completed checkpoint in the run manifest. On restart it installs nothing unless
the pinned manifest changed, downloads the latest checkpoint if necessary, and resumes
from that exact state. It does not automatically restart; only an explicit user-approved
session start can incur GPU cost.

Cloud Storage remains available while the VM is stopped because it holds the resume
state. The bucket incurs storage charges only; the VPC, firewall rule, and service
account have no active GPU-compute cost.
