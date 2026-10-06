# Vueniverse

> Know your why. Shape what's next.

Vueniverse is a private mobile system that turns health data into useful actions.
It brings wearable metrics, calendar events and personal check-ins into one
timeline, then looks across days and weeks for recurring patterns. Users can inspect
the evidence, ask what it means, and test a small change using their own data.

**View + Universe:** a clearer view of health from the information around each person.

The project combines an Android-first Flutter app with **MedGemma 1.5 4B**,
deterministic health analytics, and experiments in **LoRA/QLoRA fine-tuning on
realistic synthetic health-context data**. The selected research model is LoRA
BF16 v7, merged and quantized to **4-bit Q4_K_M** for local inference.

## Repository status

**Updated: October 6, 2026 · Android research prototype · Personal repository**

| Branch | Purpose |
| --- | --- |
| `main` | Default branch; Vueniverse application baseline and project overview |
| [`medgemma-experiments-roadmap`](https://github.com/crixalis17/vueniverse/tree/medgemma-experiments-roadmap) | Accumulated fine-tuning experiments, datasets, reports and recent analytical safeguards |

Use the experiment branch to reproduce the work described below. Original Git
history is preserved from `mvp-ing/medgemma`.

The app implements local data storage, evidence analysis, guarded explanations,
personal experiments and exports. Its current analytical workflow focuses on
**recurring one-to-one meetings and heart rate**. The selected fine-tuned model
has been evaluated in a desktop/cloud runtime. Android has an explicit `lora-v7`
candidate variant; default builds retain the original vanilla artifact. Actual
production-prompt compatibility and physical-phone measurements remain open.
The LoRA Android candidate is currently held: constrained decoding produced valid
JSON but manual review found an incorrect explanation that passed the automated
guard. A subsequent one-case prompt-v8 run also failed manual review, despite
correct numerical quantities; it delivered a deterministic fallback. Normal builds
block its inference and cache reuse; research weights remain
preserved, not retrained or activated.

The immediate milestone is an **emulator-verified prototype**, with collection
and model-semantic acceptance recorded separately in the
[emulator checklist](docs/finetuning/EMULATOR-PROTOTYPE-MILESTONE.md).
The ultimate target remains the owner's Nothing Phone 2 (8 GB RAM), using
**Ultrahuman and manual check-ins only**; physical acceptance is deferred, not removed.
Collection-first onboarding and a local collection ledger are implemented; live
acceptance and useful LoRA output are not yet verified. See the
[first-person checklist](docs/finetuning/FIRST-PERSON-MILESTONE.md),
[phone runbook](docs/finetuning/first-person-phone-runbook.md) and
[implementation record](docs/finetuning/first-person-implementation-v1.md).

The current direct Ultrahuman connector imports verified heart-rate samples and
supported sleep-stage intervals only. It does **not** guess HRV/steps schemas or
invent canonical events. Its daily date is explicitly chosen, and missing context
remains unknown. A read-only collection ledger separates retained records from
import throughput and repeat counts.

## From health numbers to personal understanding

Vueniverse combines heart rate, HRV, sleep, steps and workouts with privacy-safe
calendar categories and manual check-ins for mood, caffeine, illness, exercise
and travel. Rather than treating each number separately, it asks whether repeated
moments are associated with a consistent change in the person's health signals.

For example, a recurring one-to-one may coincide with a higher pre-meeting heart
rate. Vueniverse compares those occurrences with eligible periods at a similar
local time when the event did not happen. It keeps missing measurements, recorded
influences, exclusions and counterexamples visible alongside the result.

MedGemma explains the evidence already calculated by the app, expresses uncertainty
and answers bounded follow-up questions. When a verified phone model is available,
inference runs locally. The app can then help users predeclare a small change,
such as a breathing routine before a meeting, and inspect subsequent occurrences.
The evidence may become stronger, weaker or remain unclear; association and a
before/after comparison alone do not establish causation.

The synthetic research cases also explore screen time, calls, music, gaming,
journals and food/beverage context. Live connectors and analytical policies for
these additional sources are future work.

## How the system works

```text
Wearable / Health Connect + Calendar + manual check-ins
                           ↓
            Normalized records in encrypted local stores
                           ↓
       Deterministic comparisons, exclusions and versioned evidence
                           ↓
              Compact evidence projection → MedGemma
                           ↓
          Output validation → accepted explanation or fallback
                           ↓
               Follow-up questions, experiments and history
```

The analytics layer owns measurements, comparison windows and finding states.
The model explains that evidence rather than calculating new health facts.
Validation checks structured outputs, numeric grounding, citations and allowed
behavior before display or persistence. Rejected output receives a deterministic
fallback. Demo and Live use separate encrypted stores, and explanation reuse is
bound to the evidence and runtime identity.

Recent work on the experiment branch:

- Excludes all known calendar events from control windows, including events
  outside the selected analysis subset.
- Records caffeine amounts and explicit coverage periods. Blank or incomplete
  reporting remains unknown; absent logs never imply zero intake.
- Applies recorded illness, travel, exercise and workout recovery screening to
  both meeting and control periods.
- Versions analytical policy so the normal refresh can replace older evidence.
- Groups meetings by private recurring-series identity, keeping unrelated
  one-to-ones separate and excluding occurrences with missing identities.

Provider identity lifecycle, timezone/DST handling, control-allocation sensitivity
and complete dependent-artifact invalidation still need work.

## MedGemma fine-tuning

We developed synthetic examples representing plausible wearable trajectories and
everyday context, including repeated patterns, conflicting observations, sparse
data and uncertain explanations. Structured evidence inputs are paired with
grounded target responses. Stable context references connect repeated identities
across examples, while generation provenance stays outside model-facing text.
Ultrahuman data informed calibration; raw personal records are excluded from Git.

The experiments compared frozen vanilla MedGemma, QLoRA with an NF4 base, and
LoRA with a BF16 base. Adapter training freezes the original model weights and
updates low-rank parameters in selected attention projections. After selecting
LoRA v7, we merged the adapter into the base model, converted it to GGUF and
quantized it to Q4_K_M using a pinned `llama.cpp` revision.

### Development benchmark

The retained comparison uses **210 synthetic cases** with the same frozen test
projection. Semantic judgments assess raw model responses before fallback.

| Model | Pass | Needs review | Fail | Rubric-weighted usefulness |
| --- | ---: | ---: | ---: | ---: |
| Vanilla MedGemma BF16 | 3 | 170 | 37 | 41.9% |
| QLoRA NF4 v7 | 137 | 41 | 32 | 75.0% |
| **LoRA BF16 v7 — selected** | **129** | **65** | **16** | **76.9%** |

LoRA had the highest weighted usefulness and fewer semantic failures; QLoRA had
more strict passes. Both adapters had 203/210 guard-accepted raw outputs.
These are development results from synthetic cases and one assistant evaluator,
with repeated inspection informing experiment choices. They do not establish
clinical accuracy or independent real-user performance.

The selected Q4 artifact also completed a 17-case runtime check on an NVIDIA L4:
16/17 raw outputs passed the guard, and 17/17 delivered outputs passed after one
fallback. Mean generation time was 2.62 seconds on that GPU. Physical-phone
latency, memory, battery and thermal performance remain unmeasured.

### Research artifacts

The links below point to the experiment branch, including when reading from `main`.

| Resource | Contents |
| --- | --- |
| [Model tooling](https://github.com/crixalis17/vueniverse/tree/medgemma-experiments-roadmap/tooling/medgemma) | Dataset generation, training, inference and evaluation code |
| [Synthetic datasets](https://github.com/crixalis17/vueniverse/tree/medgemma-experiments-roadmap/experiments/datasets) | Versioned model-facing train/validation/test projections |
| [Benchmark reports](https://github.com/crixalis17/vueniverse/tree/medgemma-experiments-roadmap/experiments/reports) | Case judgments, comparison workbooks, plots and experiment outcomes |
| [Research paper](https://github.com/crixalis17/vueniverse/blob/medgemma-experiments-roadmap/experiments/research/vueniverse-medgemma-finetuning-research-report.pdf) | Consolidated methods, findings and limitations |
| [Experiment journal](https://github.com/crixalis17/vueniverse/blob/medgemma-experiments-roadmap/docs/finetuning/experiment-journal.md) | Provisioning, data revisions, training and subsequent app changes |
| [Recovery guide](https://github.com/crixalis17/vueniverse/blob/medgemma-experiments-roadmap/experiments/recovery/README.md) | Restore the selected model, adapters and checkpoints from the private archive |
| [Product roadmap](https://github.com/crixalis17/vueniverse/blob/medgemma-experiments-roadmap/docs/finetuning/PRODUCT-READINESS-ROADMAP.md) | Completed safeguards and remaining pilot-readiness work |

Model weights and checkpoints remain in the private Cloud Storage resurrection
bundle; they are not in Git or bundled into the APK. The last recorded experiment
handoff archived the artifacts and stopped the training VM. Resuming research
requires an explicit cloud session; the product does not require a permanent
hosted inference server. Historical reports describe their run-time state, and
some report scripts require adjusting their original workspace paths.

## Run the app

The recorded development toolchain is macOS on Apple silicon, Flutter 3.44.6 /
Dart 3.12.2, Android Studio Java 17, and Android SDK platforms 34 and 36. Android
is the implementation target; the generated iOS host is not a verified release.

```sh
git clone https://github.com/crixalis17/vueniverse.git
cd vueniverse
git switch medgemma-experiments-roadmap

flutter doctor -v
flutter config --jdk-dir "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
make setup
make android-bootstrap
make android-34
```

In another terminal, select the running device:

```sh
flutter devices
flutter run -d emulator-5554
```

`make android-36` launches the API 36 target on port 5556. Bootstrap preserves
existing AVDs. For a low-resource configuration, run:

```sh
VUENIVERSE_AVD_DISK_SIZE=1G VUENIVERSE_AVD_RAM_MB=2048 make android-bootstrap
```

Demo provides 30 days of fictional source records and labelled calculated,
lifecycle and illustrative scenarios. The app can use deterministic explanations
when a model is unavailable; the UI distinguishes fallback text from model output.
See the [Demo runbook](docs/demo-video-runbook.md) and
[physical-phone runbook](docs/physical-phone-adb-runbook.md).

### Optional phone model setup

Android uses a verified app-private GGUF artifact with resumable delivery and
size/hash checks. The default pin is the original vanilla Q4 model; explicit
`-PVUENIVERSE_MODEL_VARIANT=lora-v7` selects the archived LoRA candidate, also
approximately 2.49 GB. These are distinct identities and filenames. A configured
download URL must serve the selected pin and support byte ranges. Keep credentials
out of Git; do not use destructive integration tests on an owner's phone.

```sh
ORG_GRADLE_PROJECT_VUENIVERSE_MODEL_DOWNLOAD_URL='https://your-host.example/medgemma-1.5-4b-it-Q4_K_M.gguf' \
  flutter run -d emulator-5554
```

An unconfigured debug build can run with fallback behavior. Release configuration
requires a model URL. Consult the [model tooling guide](tooling/medgemma/README.md)
and [runtime checklist](docs/medgemma-subtasks/README.md) for artifact identity,
runtime acceptance and model distribution requirements.

## Development and project layout

```text
lib/app/           App state, navigation and theme
lib/domain/        Analytical policies, models and runtime contracts
lib/data/          Persistence, ingestion, evidence and runtime repositories
lib/features/      Screens and product flows
lib/platform/      Generated bridge clients
android/           Kotlin bridges, model delivery and native inference
pigeon/            Typed Dart/native API definitions
tooling/medgemma/   Model research tooling
experiments/       Synthetic datasets, reports, scripts and recovery guide
docs/              Architecture, runbooks and experiment documentation
```

The `experiments/` directory and latest safeguards are on the experiment branch.
To verify changes:

```sh
make check

python3 -m venv .venv
source .venv/bin/activate
python -m pip install -e './tooling/medgemma[dev]'
python -m pytest tooling/medgemma/tests -q
```

Latest experiment-branch verification: **357 Flutter tests** with clean analysis and
**128 Python tests**, including frozen-package/capture integrity. Android host
verification includes68 tests per variant in J-096; J-097 records replay follow-up.
These are host checks, not native model execution. An earlier disposable API-34 emulator passed **27 aggregate
integration checks**, plus a separate **actual-main encrypted onboarding/save/edit/reopen
journey**. Later collection-boundary changes have additional local regressions;
these counts are not a claim of physical-phone acceptance.
The October 5 production-bootstrap repeat passes after an evidenced, fixture-only
typing fix; production controllers, encrypted persistence and restart assertions
remain unchanged. This does not certify the physical phone's keyboard.
Native compatibility includes actual app prompts, not just a model-load test.
Bounded grammar completes JSON but the accepted answer failed manual grounding;
the LoRA candidate is blocked from normal use rather than silently served.
Emulator-first follow-up corrects negative-direction summaries, comparison-count
labels and the 15-minute pre-meeting window. Deterministic fallback v6 avoids
misreading positive counts as direction agreement; older fallback caches remain
historical instead of being served as current. The current emulator-prototype
verification is recorded separately in the
[acceptance checklist](docs/finetuning/EMULATOR-PROTOTYPE-MILESTONE.md); historical
27-check and model-generation records remain unchanged.
Native smoke also exposed stale manual-source status/counts after saving and a
legacy status mapping on reopen. Local source metadata now updates transactionally,
Sources refreshes before analysis, and scoped legacy read repair preserves operational
states. Late metadata-failure regressions prove save/delete rollback.
Live source projection also avoids copying Snapshot timestamps and completeness
into real source state; fresh sources cannot claim a sync that never happened.
The [semantic-contract audit](docs/finetuning/android-semantic-contract-audit-v1.md)
identified developing-state coverage drift and omitted gate/exclusion meaning.
Phone prompt v8 preserves those facts; guard v7 checks finite recognized numeric
metric roles, including complete word-decimal quantities. A retained-output replay
fixes a numeric false positive without rerunning inference; it is not a model pass.
Neither version changes the frozen v7 training dataset or establishes model readiness.
The [sealed semantic development package](experiments/readiness/emulator-semantic-v1/README.md)
now retains 15 actual pipeline requests, 30 exact production prompts and 15 LoRA
grammars. That immutable freeze retains zero model calls; new generation records
are separate. The [bounded LoRA diagnostic outcome](experiments/readiness/emulator-semantic-run-20261006-v1/OUTCOME.md)
records15 passing host tokenizer/grammar checks, then one Android answer in66.2s
that copied instructions and failed manual grounding/usefulness. The safety stop
left14 unattempted; the disposable emulator is stopped and LoRA stays held.
Actual input tokens match host/Android1606; EOS occurs after237 generated tokens,
not a timeout or cap. This points to further prompt/contract investigation, not
proof that rank or quantization caused the failure. No retraining was performed.
See the [separate compatibility reports](experiments/readiness/first-person-local-v1/README.md).
Emulator imports use mocked provider replies; actual-phone performance and live-account
acceptance remain pending.
Model training has additional GPU dependencies
and gated model access; follow the preserved configuration and recovery guide.

## Next milestones

1. Finish analytical correctness: provider identity lifecycle, timezone reconstruction,
   context coverage and stale scheduled-reminder handling. Global control allocation
   and non-destructive freshness gates are implemented; analysis v7 adds exact
   recovery boundaries and supported-only intervention checks.
2. Create a fresh independent benchmark through the real analytics pipeline.
3. Integrate the selected LoRA artifact and validate a physical Android workflow.
4. Verify live sources, privacy lifecycle, distribution and consent for a small pilot.
5. Observe a longitudinal pilot before expanding to additional context sources.

Vueniverse supports personal understanding and experimentation. It is a research
prototype, not a diagnostic or treatment system. See the
[roadmap](https://github.com/crixalis17/vueniverse/blob/medgemma-experiments-roadmap/docs/finetuning/PRODUCT-READINESS-ROADMAP.md)
for the complete readiness criteria.

The [current app-derived development snapshot](experiments/readiness/development-v2/README.md)
contains 30 cases across ten raw timeline families under a
[predeclared evaluation contract](docs/finetuning/readiness-evaluation-contract-v1.md).
All deterministic responses pass the guard; independent review, untouched final
evaluation and model comparisons are pending. These are pipeline checks, not an
update to the historical LoRA usefulness score.
