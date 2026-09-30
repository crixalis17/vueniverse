# Vueniverse MedGemma fine-tuning: authoritative seven-day plan

Status: active  
Started: 2026-09-12  
Learning budget: INR 17,000 monthly guardrail  
Available promotional credit confirmed by owner: INR 44,636.26  
Repository: `/Users/rakesh/Documents/repo/medgemma`

This file is the single source of truth for the learning build. Earlier schedules in
chat are superseded by this plan. Completed tasks are checked and struck through; a
task is completed only after its artifact or command output has been verified.

Mode: **model-only**. See `docs/finetuning/model-only-data-policy.md`.

## Fixed objective

Learn supervised fine-tuning end to end by running a controlled comparison of:

1. vanilla `google/medgemma-1.5-4b-it`;
2. the same checkpoint with a LoRA adapter; and
3. the same checkpoint with an adapter trained using QLoRA.

The behavioral target is evidence-grounded explanation of associations between
canonical life events and already-computed wearable health metrics. Each result carries
one opaque, stable context reference so the app can connect an explanation back to the
same private song, contact, routine, or log item without exposing it to the model. The
model does not calculate health statistics from raw sensor data, infer causality,
diagnose, or recommend treatment.

Accuracy leadership is not the goal. The week succeeds when the data, training,
adapter, inference, evaluation, and cost-control paths are understood and reproducible.

## Canonical-context expansion — fixed scope for the model experiment

The synthetic model dataset and its test holdout must cover all of these canonical
context families. They are inputs to deterministic comparison logic; MedGemma only
explains the resulting evidence.

| Family | Safe context representation for the synthetic learning dataset | Never place in model-facing training or cloud data |
| --- | --- | --- |
| Recurring meetings | opaque context reference, recurrence pattern, work/personal category, duration band, time block | titles, invitees, links, transcript, account IDs |
| Discord activity and games | opaque context reference, session type, game genre, solo/small-group flag, duration band, time block | Discord handle, server/channel, friend names, chat, real game-session history |
| Spotify listening | opaque context reference, listening window, energy or mood tag, genre/category, playback context | track/artist title, playlist title, Spotify account ID, listening history |
| Phone calls | opaque context reference, relationship category such as family, close contact, or work peer; duration and time band | phone number, contact name, recording, transcript, call-log identifier |
| Phone screen time | opaque context reference, aggregate duration band, time block, broad app-category mix | app contents, notification text, URLs, typed text, precise device timeline |
| Manual daily journal | opaque context reference and structured synthetic mood, stress, workload, social, and sleep-readiness tags | raw journal prose, names, locations, medical details, free-text identifiers |
| Food and beverage log | opaque context reference, meal or beverage category, timing band, caffeine/alcohol flag, and portion band | receipt, venue, brand, free-text note, precise intake history |

All current work remains **model-only**: the above contexts are fictional but designed
to resemble plausible real-world records. Real integrations can be added only after a
separate source-specific consent, redaction, retention, and deterministic-analytics
review. Adding more event families does not allow the model to say they caused a health
change; it may only explain a supplied repeated pattern and its limitations.

## Rules that do not change during the week

- Ultrahuman API data is the only wearable source for local calibration. Other wearable
  platforms are out of scope.
- No real canonical event source is connected in this model-only experiment.
- The model-facing training and holdout data is fully synthetic and labelled
  `synthetic_calibrated`. It contains both synthetic canonical events and synthetic
  wearable metrics, calibrated from local Ultrahuman aggregate patterns.
- Raw Ultrahuman data is never paired with fictional events, uploaded to GCP, or included
  in training or evaluation JSONL.
- Personal identifiers are removed locally before any cloud upload.
- The Ultrahuman API credential is supplied only through an ignored local environment
  file or GCP Secret Manager. It is never pasted into source, committed, included in
  generated datasets, or printed in logs.
- The synthetic evaluation holdout is frozen before label generation and never enters
  training.
- Data is split by time block or recurring-event group, not by randomly separating
  near-duplicate event windows.
- Each canonical-context family is represented in train, validation, and test. Split
  assignment keeps one opaque recurring-context reference in exactly one split.
- A local event occurrence ID supports ingestion deduplication; repeated occurrences of
  one private context resolve to its existing opaque context reference rather than
  creating a new one. Neither raw occurrence IDs nor the local reference mapping enters
  model-facing data or the cloud.
- The data generator must vary realistic combinations of event context, timing band,
  duration/quantity band, and missingness without inventing actual people, account
  activity, song titles, journal prose, or food history.
- Vanilla, LoRA, and QLoRA use the same checkpoint revision, prompt, inference
  settings, output schema, evaluator, and holdout.
- Deterministic code computes metrics and matches control windows. The LLM explains
  the evidence projection.
- Every number in an answer must be supported by supplied evidence.
- Raw model acceptance and post-fallback delivery acceptance are reported separately.
- No GPU is left running unattended; shutdown is verified after every session.
- No production or medical-safety claim will be made from this learning experiment.

## Day 1 — Freeze the experiment and establish the starting point

Goal: know exactly what is being compared and prove the current repository is healthy.

- [x] ~~Freeze the research question, model boundary, comparison controls, data rules,
  measurements, success criterion, and out-of-scope items.~~  
  Evidence: `docs/finetuning/day-1-experiment-contract.md`
- [x] ~~Preserve the pinned MedGemma checkpoint revision and identify the existing
  prompt, schema, guard, fixtures, and evaluation commands.~~
- [x] ~~Run the MedGemma Python tooling tests.~~  
  Result: 56 passed.
- [x] ~~Run Dart formatting and Flutter static analysis.~~  
  Result: 72 files checked with no formatting changes; no analysis issues.
- [x] ~~Run the Flutter unit and widget tests.~~  
  Result: 90 passed.
- [x] ~~Rerun the 17-case local Q4_K_M and Q5_K_M product regression benchmark.~~  
  Evidence: `docs/finetuning/vanilla-baseline-2026-09-12.md`
- [x] ~~Record the important baseline distinction: Q4 passed 17/17 raw guard checks;
  Q5 passed 3/17 and used 14 deterministic fallbacks despite 17/17 valid schemas.~~
- [x] ~~Create and verify a project-scoped INR 17,000 monthly GCP budget with current
  spend alerts at 25%, 50%, 75%, 90%, and 100%, plus a 75% forecast alert.~~  
  Budget ID: `39472973-148a-43a9-b0b8-5b4264c630dc`

Day 1 deliverables:

- frozen experiment contract;
- healthy repository baseline;
- local product-runtime benchmark; and
- cloud budget guardrail.

Important: the local GGUF Q4/Q5 benchmark is the product regression baseline. It is
not the final training comparison, because LoRA and QLoRA will initially be evaluated
through the Hugging Face/PyTorch checkpoint path. A matching vanilla PyTorch baseline
is captured on the cloud GPU before training.

## Day 2 — Audit and normalize the real data

Goal: calibrate a privacy-safe synthetic evidence generator and create a deterministic
evidence layer.

- [x] ~~Configure the Ultrahuman API credential through an ignored local environment
  file; verify that Git and command output cannot expose it.~~
- [x] ~~Make a minimal read-only Ultrahuman API request and record only the endpoint,
  response schema, and retrieval status—not the credential or sensitive values.~~
- [x] ~~Complete an initial seven-day Ultrahuman response-schema and availability audit
  without documenting raw measurements or timestamps.~~  
  Evidence: `docs/finetuning/ultrahuman-api-schema-audit.md`
- [x] ~~Audit the existing canonical event-source boundary and confirm that it uses
  Android Calendar recurring-event snapshots, not direct Google Meet content.~~  
  Evidence: `docs/finetuning/canonical-event-source-audit.md`
- [x] ~~Choose model-only mode: defer real calendar/Meet integration and prevent raw
  Ultrahuman data from being paired with fictional events.~~  
  Evidence: `docs/finetuning/model-only-data-policy.md`
- [x] ~~Calculate a local Ultrahuman calibration profile from 11 protected probe files,
  including sampling density, availability, and coarsened metric bands.~~
- [x] ~~Define synthetic recurring-event scenarios and recurrence patterns; label every
  event as synthetic rather than a real meeting.~~
- [x] ~~Produce a field-level privacy inventory without copying sensitive values into
  documentation or chat.~~
- [x] ~~Define local redaction rules for names, email addresses, phone numbers, meeting
  links, account IDs, precise locations, titles, raw readings, and timestamps.~~
- [x] ~~Mark real cross-source timestamp alignment as not applicable to model-only mode;
  synthetic records deliberately contain no timeline.~~
- [x] ~~Define the existing deterministic pre-event, recovery, and matched-control
  semantics for the synthetic aggregate contract.~~
- [x] ~~Define synthetic completeness, exclusion, counterevidence, and unresolved-
  influence rules.~~
- [x] ~~Create and validate the synthetic canonical evidence-record schema through the
  strict `ExplainerRequest` contract.~~
- [x] ~~Generate and validate a 60-case local-only synthetic calibrated sample with no
  timestamps or personal identifiers.~~
- [x] ~~Implement and test the calibration method without copying raw Ultrahuman
  timelines into synthetic training cases.~~  
  Evidence: `docs/finetuning/synthetic-evidence-contract.md`

Day 2 deliverables:

- data-source inventory;
- privacy/redaction specification;
- canonical evidence schema; and
- a validated local-only synthetic calibrated sample and calibration method.

## Day 3 — Build and review the training dataset

Goal: convert synthetic calibrated evidence records into natural, non-generic training
examples without leaking evaluation cases.

- [x] ~~Freeze synthetic holdout scenario groups before generating any assistant labels.~~
  Evidence: `tooling/medgemma/outputs/finetuning/supervised-dataset-v2/holdout-manifest.json`
- [x] ~~Create leakage-safe train, validation, and test assignments by time/event group.~~
  Result: 360 recurring-event groups have zero cross-split overlap.
- [x] ~~Implement the deterministic evidence-to-conversation JSONL builder.~~
  Evidence: `tooling/medgemma/src/vueniverse_medgemma/training_dataset.py`
- [x] ~~Define the system instruction and supervised assistant-output contract.~~
  Result: the unchanged production prompt plus a per-request JSON-schema user contract.
- [x] ~~Draft a small set of curated gold-response templates to establish tone and quality.~~
- [x] ~~Generate candidate responses from evidence without inventing facts or repetitive
  AI-style phrasing.~~
  Result: 360 guard-validated labels with zero exact duplicate assistant answers.
- [x] ~~Run automatic validation for schema, citations, numbers, identifiers, duplication,
  missingness, and split leakage.~~
  Evidence: `tooling/medgemma/outputs/finetuning/supervised-dataset-v2/dataset-quality.json`
- [x] ~~Review all state-by-intent label families and a stratified rendered sample; use the
  automatic guard to validate every row.~~
- [x] ~~Use a smaller clean 270/45/45 train/validation/test split rather than padding the
  current 360-group generator to the initial approximate 300/50/50 target.~~
- [x] ~~Add no extra synthetic cases to the initial meeting-only grid; the deliberate
  multi-context scope expansion is recorded separately in Day 3.1.~~
- [x] ~~Produce a dataset card with provenance, limitations, counts, and hashes.~~
  Evidence: `docs/finetuning/synthetic-dataset-card-v2.md`

Day 3 deliverables:

- validated JSONL splits;
- immutable holdout manifest;
- dataset-quality report; and
- dataset card.

## Day 3.1 — Expand the synthetic canonical-context dataset

Goal: replace the meeting-only training grid with a realistic, privacy-safe multi-context
grid before any cloud training begins.

- [x] ~~Define a versioned synthetic context schema for all seven canonical-context
  families above, including safe category fields, timing bands, duration or quantity
  bands, and explicit synthetic provenance.~~
- [x] ~~Add realistic, non-identifying variants for Discord/game sessions, music listening,
  phone calls, screen time, journals, and food/beverage logs alongside recurring meetings.~~
- [x] ~~Keep manual journal records structured and synthetic; do not use raw free-text in
  a model input or training label.~~
- [x] ~~Keep call and music context categorical; do not use actual contacts, phone numbers,
  song/artist titles, playlists, handles, or account identifiers.~~
- [x] ~~Produce deterministic synthetic evidence for each context family using the same
  matched-control semantics, completeness rules, counterexamples, and unresolved-context
  representation as the meeting cases.~~
- [x] ~~Extend the evidence projection so the model sees a clear synthetic event-context
  label and can cite it without being asked to infer statistics or causes.~~
- [x] ~~Freeze a new group-stratified holdout that contains every context family and every
  finding state before generating assistant labels.~~
  Evidence: `tooling/medgemma/outputs/finetuning/supervised-dataset-v3/holdout-manifest.json`
- [x] ~~Regenerate train, validation, and test JSONL with no overlap by event group and
  validate schema, grounding, safety, privacy markers, duplicates, and per-family split
  coverage.~~
  Result: 630 rows, zero split overlap, zero duplicate prompts, zero duplicate answers.
- [x] ~~Review every context-family by finding-state narrative pattern and representative
  question-intent variants; use the automatic guard to validate every row.~~
- [x] ~~Replace the Day 3 dataset card with a new version listing the taxonomy, counts,
  hashes, safe fields, exclusions, and limitations.~~
  Evidence: `docs/finetuning/synthetic-canonical-context-dataset-card-v3.md`

Day 3.1 deliverables:

- versioned synthetic canonical-context schema;
- multi-context train/validation/test JSONL;
- group-stratified immutable holdout; and
- updated dataset-quality report and dataset card.

## Day 3.2 — Separate experiment provenance from the model conversation

Goal: simulate user-style context in the chat messages without teaching MedGemma that the
fine-tuning corpus is synthetic, while preserving auditable provenance outside the model
boundary.

- [x] ~~Remove every model-facing `synthetic` notation from event labels, metric labels,
  definitions, sources, exclusion IDs, approved next observations, and assistant labels.~~
- [x] ~~Keep `synthetic_calibrated` and `synthetic_canonical` only in non-model metadata,
  manifests, reports, and documentation.~~
- [x] ~~Regenerate the dataset without changing split assignment, numerical values,
  output-schema contract, grounding guard, or privacy rules.~~
  Evidence: `tooling/medgemma/outputs/finetuning/supervised-dataset-v4/`
- [x] ~~Scan all 630 rendered chat-message triplets case-insensitively and fail the build
  if any model-facing `synthetic` marker remains.~~
  Result: 0 markers; all provenance remains in metadata only.
- [x] ~~Document the exact model-facing replacements and version 4 hashes.~~
  Evidence: `docs/finetuning/model-facing-provenance-separation-v4.md`

Day 3.2 deliverables:

- neutral user-style SFT messages;
- preserved non-model experiment provenance; and
- a complete zero-marker verification report.

## Day 3.3 — Add stable private-context references

Goal: make the evidence contract able to connect each explanation to one repeatable
private context without exposing source identifiers to MedGemma or the cloud.

- [x] ~~Add a typed `ContextReference` to the EvidenceBundle and a required matching
  `context_reference_id` to its structured model output.~~
- [x] ~~Implement local HMAC-derived references: the same source-local key and local
  secret resolve to the same opaque ID; a different key or secret resolves differently.~~
- [x] ~~Expand every canonical family to six non-identifying context variants and split
  by reference before rendering question-specific messages.~~
- [x] ~~Keep all six intent variants for one reference in one split, preventing a song,
  contact, routine, journal-tag pattern, or food item from crossing into the holdout.~~
- [x] ~~Regenerate the v5 train/validation/test corpus and verify reference reuse,
  reference-to-output matching, no cross-split references, privacy checks, and no
  model-facing provenance marker.~~
  Evidence: `tooling/medgemma/outputs/finetuning/supervised-dataset-v5/`
- [x] ~~Document the local resolver boundary, per-source stable-key rules, and v5 hashes.~~
  Evidence: `docs/finetuning/context-reference-contract-v5.md`

Day 3.3 deliverables:

- versioned context-reference schema and local derivation helper;
- v5 context-reference-stratified immutable holdout; and
- documented resolver and privacy boundary.

## Day 4 — Create the cloud environment and run controlled smoke tests

Goal: prove the exact base-model and training stack on one GPU before paying for a
longer run.

- [x] ~~Select `asia-south1` (Mumbai), verify the `g2-standard-4` / NVIDIA L4 catalog
  in all three zones, and verify unused regional L4 quota.~~
  Note: global and regional quota are now both 1 and unused. On 2026-09-14, all three
  Mumbai zones nevertheless returned temporary L4 capacity exhaustion; no VM was
  created. The user explicitly approved a `us-central1` fallback for this learning
  session, without strict bucket co-location. Do not silently substitute any further
  region, accelerator, or provisioning model.
- [x] ~~Obtain explicit approval to request `GPUS_ALL_REGIONS=1`; do not substitute a
  different accelerator or request a broader quota.~~ The approved global quota is 1;
  regional NVIDIA L4 quota remains 1 and unused.
- [x] ~~Create a least-privilege training service account.~~
  Evidence: `medgemma-trainer@vueniverse-508413.iam.gserviceaccount.com` has only
  bucket object access, log writing, and metric writing permissions.
- [x] ~~Store the Hugging Face access token in Secret Manager and grant access only to
  the training service account.~~ The token is not stored in source, datasets, logs,
  command arguments, or the experiment journal.
- [x] ~~Create a private, lifecycle-managed Cloud Storage bucket for redacted datasets,
  adapters, configurations, and evaluation reports.~~
  Evidence: `gs://vueniverse-508413-medgemma-training` in `asia-south1`, with uniform
  bucket-level access, public-access prevention, and versioned retention rules in
  `tooling/medgemma/cloud/gcs-lifecycle.json`.
- [x] ~~Create an isolated custom VPC, Mumbai subnet, and IAP-only SSH firewall rule.~~
  No VM is reachable from the public internet over SSH.
- [x] ~~Create an append-only experiment journal and immutable run-artifact/resume
  contract.~~
  Evidence: `docs/finetuning/experiment-journal.md`
- [x] ~~Implement and run the deterministic cloud-upload preflight gate for v5.~~
  It verifies hashes, privacy flags, context-reference split integrity, and that the
  trainer consumes `messages` rather than provenance metadata.
  Evidence: `tooling/medgemma/outputs/finetuning/supervised-dataset-v5-cloud-preflight.json`
- [x] ~~Provision one L4 24 GB training VM first; consider A100 only if an observed memory
  or runtime limitation justifies the additional cost and quota work.~~ Running as
  `medgemma-qlora-l4-01` in `us-central1-b` after all Mumbai zones were capacity-blocked.
- [x] ~~Use resource labels, a small persistent disk, automatic shutdown, and no broad
  public SSH exposure.~~ Verified: 100 GB balanced persistent disk, four-hour STOP
  limit, IAP-only tag/rule, OS Login, blocked project keys, and cost labels.
- [x] ~~Install and record the pinned Python, CUDA, PyTorch, Transformers, Accelerate,
  PEFT, TRL, Datasets, and bitsandbytes versions.~~ Python 3.12.14, CUDA 13.0 via
  PyTorch 2.11.0+cu130, and the full resolved environment freeze are stored at
  `configs/20260914-day4-smoke-us-central1b-01/` in the private bucket.
- [x] ~~Upload only the v5 synthetic calibrated data and verify bucket access boundaries.~~
  The private bucket and VM contain only the v5 `messages` projection and its hash
  manifest; the VM retrieved it through the trainer service account.
- [x] ~~Verify that the uploaded dataset contains only the approved synthetic canonical
  context categories and no raw journal text, contacts, phone numbers, track titles,
  Discord content, app content, account IDs, or wearable timelines.~~ All 1,260 rows
  were independently verified on the VM to contain only `messages`; model-facing
  provenance markers are zero.
- [x] ~~Run the matching vanilla Hugging Face/PyTorch evaluation on the immutable synthetic
  holdout.~~ All 210 frozen test cases ran with the messages-only v5 projection.
- [x] ~~Record vanilla outputs, evaluator results, latency, peak GPU memory, environment,
  configuration, and hashes.~~ Reports are in
  `reports/20260914-day4-smoke-us-central1b-01/`; configuration is in the matching
  `configs/` path in the private bucket.
- [x] ~~Perform an in-thread semantic review of every raw vanilla holdout output and
  publish a benchmark artifact.~~ All 210 raw generations leaked a thought trace and
  stopped before a final answer, so every verdict is `fail` and quality dimensions are
  `null` rather than fabricated as zero. The private run artifact is at
  `reports/20260914-day4-smoke-us-central1b-01/semantic-review/` and the local
  workbook is `outputs/vanilla-baseline-semantic-review-20260915/`.
- [x] ~~Rerun the frozen vanilla holdout under the corrected response protocol before
  comparing QLoRA.~~ All 210 cases completed with structural assistant prefill and no
  application output cap: 206/210 assembled schemas valid, 173/210 full guard accepted,
  and 37/210 fallbacks. The report distinguishes application-prefilled contract fields
  from MedGemma-generated semantic fields; the 192-token run remains an immutable
  historical diagnostic.
- [x] ~~Perform the in-thread semantic review of the corrected holdout and publish a
  separate benchmark artifact.~~ Verdicts: 3 pass, 170 review, 37 fail. Strict guard
  improvement does not establish semantic quality: accepted outputs often omit the held-
  out target's context, contradictory counts, or missing-context framing.
- [x] ~~Run one tiny QLoRA smoke job and verify loss, gradients, checkpoint saving,
  adapter reloading, and inference.~~ The v6 rank-16/alpha-32 smoke run completed three
  optimization steps with decreasing loss, wrote three checkpoints and a final adapter,
  then reloaded the adapter in a fresh process and produced schema-valid, guard-accepted
  JSON that reached native EOS.
- [x] ~~Stop the VM and verify its state and accumulated cost.~~ The VM ran from
  15:32:57Z to 16:56:59Z and is now `TERMINATED`; GPU and vCPU/RAM charges ended.
  Its 100 GB persistent boot disk remains for resume and charges only storage.

Resume operating rule: start all future interactive VM work inside a named `tmux`
session. Log the session name with the run identity, leave the session attached to the
training command, and provide the user the IAP SSH + `tmux attach` command so they can
observe it. This preserves the run if the SSH connection drops and makes the live
console inspectable without exposing credentials.

Day 4 deliverables:

- reproducible cloud environment;
- apples-to-apples vanilla PyTorch baseline; and
- reloadable QLoRA smoke adapter.

## Day 5 — Train and understand QLoRA

Goal: complete one small QLoRA experiment and understand every memory-saving component.

- [x] ~~Freeze the QLoRA configuration before the run: 4-bit NF4 base quantization,
  compute dtype, double quantization choice, LoRA rank/alpha/dropout, target modules,
  sequence length, batch size, accumulation, optimizer, scheduler, seed, and epochs.~~
- [x] ~~Calculate and record total, frozen, and trainable parameter counts.~~ Measured in
  the v6 smoke process: 2,502,121,840 total; 2,490,222,960 frozen; 11,898,880 trainable
  adapter parameters (approximately 0.476% of the total).
- [x] ~~Run the QLoRA training job with periodic validation and checkpointing.~~ The v6
  rank-16/alpha-32 run completed all 1,512 steps, wrote checkpoints every 100 steps plus
  the final step-1,512 checkpoint, saved the final adapter, and measured one-example
  validation loss `0.503885`.
- [x] ~~Complete the corrected v7 rank-16/alpha-32 run and its 30-cell sentinel gate.~~
  Run `20260917-qlora-r16-v7-full-02` completed 840 microsteps, accumulation 30,
  28 optimizer updates, and one exact state × intent example per accumulation window;
  final mean 30-cell validation loss was `0.114522`.
- [x] ~~Monitor GPU memory, utilization, loss, runtime, and estimated spend.~~
  Captured across QLoRA and LoRA training/evaluation logs; final account-level cost
  reconciliation remains an operations closeout task.
- [x] ~~Save only the adapter, tokenizer/configuration, logs, and reproducibility metadata.~~
- [x] ~~Reload the adapter in a fresh process and run inference.~~
- [x] ~~Evaluate QLoRA on both the synthetic calibrated holdout and the existing 17-case
  safety suite.~~ The frozen 210-case v7 test evaluation completed with 210/210 native
  EOS outputs, 203/210 raw guard acceptance, and 7 fallbacks. The QLoRA safety suite
  was completed separately.
- [x] ~~Review every raw holdout and safety-suite output with the in-thread semantic
  judge. For each output, compare its evidence bundle, expected analytical
  interpretation, deterministic-gate result, and generated text; save one
  constrained JSONL judgment record with `grounding`, `uncertainty`, `safety`,
  `usefulness`, `verdict`, and a concise evidence-backed rationale. Do not store
  hidden reasoning, raw personal data, or credentials. A deterministic hard-gate
  failure remains a failure even if the semantic review finds useful text. The complete
  v7 test review is finished at 76 pass, 102 review, and 32 fail; safety reviews are
  retained in the final benchmark artifacts.~~
- [x] ~~Publish aggregate semantic-judge scores and manually inspect the complete
  per-case judgment artifact for improvements and regressions before drawing any
  model-quality conclusion.~~ Completed for the 210-case validation set; the separate
  17-case safety-suite evaluation remains open under the preceding tasks.
- [x] ~~Stop the VM and verify its state and accumulated cost.~~ The final experiment VM
  `medgemma-qlora-l4-03` was verified `TERMINATED` after the complete private archive;
  GPU and vCPU/RAM billing ended. Final billing reconciliation remains a separate
  post-shutdown task.

Day 5 deliverables:

- QLoRA adapter;
- training and cost logs;
- QLoRA evaluation report; and
- written parameter/memory explanation tied to the actual run.

## Day 6 — Train LoRA and run the controlled comparison

Goal: understand the cost of keeping the base model at higher precision and compare
behavior under the same evaluation contract.

- [x] ~~Choose the highest-precision LoRA configuration that fits the selected GPU; if
  it does not fit, record the failed memory estimate/attempt instead of silently
  changing the comparison.~~ BF16 LoRA fit on the L4 and was retained as the selected
  candidate.
- [x] ~~Match QLoRA adapter targets, rank, data, seed, steps, prompt, and evaluator where
  technically possible.~~
- [x] ~~Calculate and record total, frozen, and trainable parameter counts.~~
- [x] ~~Train the LoRA adapter and monitor memory, utilization, loss, runtime, and spend.~~
- [x] ~~Save and reload the adapter in a fresh process.~~
- [x] ~~Evaluate vanilla, LoRA, and QLoRA with identical inference settings on the frozen
  synthetic calibrated holdout.~~ The frozen v7 benchmark selected LoRA BF16 v7.
- [x] ~~Run the existing 17-case safety regression for both adapters.~~ The final
  LoRA-v7 Q4 deployment regression delivered 17/17 guard-valid outputs.
- [x] ~~Compare schema validity, raw guard acceptance, grounding, safety failures,
  fallback rate, latency, memory, runtime, and cost.~~ Unified paper-style benchmark
  and final learning report are published in the experiment workspace.
- [x] ~~Stop the VM and verify its state and accumulated cost.~~ The final experiment VM
  `medgemma-qlora-l4-03` was verified `TERMINATED` after the complete private archive;
  GPU and vCPU/RAM billing ended. Final billing reconciliation remains a separate
  post-shutdown task.

Day 6 deliverables:

- LoRA adapter or a documented evidence-based feasibility result;
- LoRA evaluation report; and
- first controlled vanilla/LoRA/QLoRA comparison table.

## Day 7 — Error analysis, integration proof, and teardown

Goal: close the learning loop and leave a reproducible, understandable project.

- [x] ~~Review failures by category rather than relying on one aggregate score.~~
- [x] ~~Inspect cases that improved after tuning and cases that regressed.~~
- [x] ~~Check for memorization, style collapse, repeated phrasing, overconfidence, causal
  language, unsupported health claims, invented numbers, and citation failures.~~
- [x] ~~Run one synthetic end-to-end flow: canonical records to deterministic analytics to
  evidence projection to selected adapter to output guard to Vueniverse-facing response.~~
  Completed with the scheduled-meeting analytics fixture, selected LoRA v7 Q4 artifact,
  localhost-only output guard, and a 2.02-second end-to-end invocation on the L4.
- [ ] Run the end-to-end flow once for each canonical-context family and compare failure
  categories by source family, not only in aggregate.
- [x] ~~Document how the LoRA and QLoRA adapters alter the frozen model mathematically
  and how merging differs from adapter-based inference.~~
- [x] ~~Produce the final comparison and explain tradeoffs in learning terms, not as a
  clinical-performance claim.~~
- [ ] Record total GCP spend against the INR 17,000 guardrail and INR 44,636.26 credit.
- [ ] Download required adapters/reports, apply bucket lifecycle rules, stop/delete
  billable compute after explicit verification, and confirm that no GPU remains active.
- [x] ~~Write reproduction commands and known limitations.~~
- [x] ~~Choose the next experiment only after reviewing the evidence from this week.~~
  LoRA BF16 v7 is the retained deployment candidate; its deterministic output guard
  remains part of the product boundary.

Day 7 deliverables:

- end-to-end evaluation report;
- final comparison table;
- reproducibility guide;
- cost report; and
- verified cloud teardown.

## Planned experiment matrix

### Day 5 repair checkpoint — 2026-09-17

- [x] ~~Freeze v7-r2 dataset, seven resumable checkpoints, final adapter, evaluation,
  semantic review, producing code, and restore manifest in a lifecycle-exempt rollback
  prefix.~~
- [x] ~~Move `next_observation_id` ownership to a deterministic application policy
  while retaining the raw model value in evaluation reports.~~
- [x] ~~Generate v8 locally with state-invariant summaries, intent-specific grounded
  paragraphs, null model action targets, exact state × intent balance, and revised
  held-out expected answers over unchanged held-out evidence.~~
- [x] ~~Pass v8 label guards, privacy checks, ordering gates, and cloud-upload
  preflight.~~
- [x] ~~Run the complete tooling test suite in the pinned environment.~~ Passed 90/90
  on the training VM.
- [x] ~~Manually audit a stratified v8 sample from every state × intent cell.~~ The
  audit found and corrected three generic-template defects; `v8-r2` is canonical.
- [x] ~~Upload `v8-r2` only after the complete test suite passes; do not replace or
  delete v7.~~ Uploaded only the messages projection and sentinel; v7 remains intact.
- [x] ~~Run a cheap v8 smoke/sentinel gate before deciding whether a full retrain is
  justified.~~ Mechanical gates passed; the two-update response retained one expected
  grounding warning and was not counted as a semantic pass.
- [x] ~~Complete the active v8-r2 full epoch and verify all resumable checkpoints plus
  fresh adapter reload.~~ Completed 840/840 microsteps and 28/28 optimizer updates;
  seven checkpoints and guard-valid fresh reload verified.
- [x] ~~Complete the active 210-case frozen v8-r2 test evaluation, then perform the
  deterministic aggregate and case-by-case semantic review.~~ Completed and compared
  with v7; v7 was retained as the final dataset and LoRA deployment candidate.

| Condition | Base loading | Trainable weights | Primary purpose |
| --- | --- | --- | --- |
| Vanilla | unchanged checkpoint | none | apples-to-apples reference |
| LoRA | BF16 or best feasible higher precision | low-rank adapters | isolate adapter training without 4-bit base loading |
| QLoRA | frozen 4-bit NF4 base | low-rank adapters | learn memory-efficient adapter training |
| Q4/Q5 GGUF | quantized local runtime | none | preserve product/runtime safety regression |

## Budget policy

- Current GCP budget: INR 17,000 per month, project scoped, gross spend before credits.
- Promotional credit confirmed by owner: INR 44,636.26 remaining at plan start.
- L4 is the default learning GPU.
- A100 is optional and requires an evidence-based reason before provisioning.
- Check cost before and after every GPU session.
- Budget alerts notify; they do not automatically stop resources.
- VM shutdown is part of every GPU task's definition of done.

## Progress log

### 2026-09-12

- Froze the first experiment contract.
- Verified 56 Python tests and 90 Flutter tests.
- Verified formatting and static analysis.
- Captured a fresh local Q4/Q5 vanilla product baseline.
- Documented the Q5 grounding regression and Q4 clean baseline.
- Created and verified the INR 17,000 GCP training budget.
- Locked the wearable source to Ultrahuman API data only and added credential-handling
  and privacy-preserving derivation requirements.
- Verified protected Ultrahuman API access and initial seven-day availability.
- Verified Ultrahuman availability checkpoints at 30, 90, 180, and 365 days back.
- Audited the existing Android Calendar canonical-event boundary.
- Switched the first experiment to model-only mode: fully synthetic calibrated training
  data, with raw Ultrahuman data retained only for local calibration.
- Implemented and tested the local calibration and synthetic-evidence generator.
- Generated and validated the protected 60-case synthetic calibrated Day 2 sample.
