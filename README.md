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

**Updated: September 30, 2026 · Android research prototype · Personal repository**

| Branch | Purpose |
| --- | --- |
| `main` | Default branch; Vueniverse application baseline and project overview |
| [`medgemma-experiments-roadmap`](https://github.com/crixalis17/vueniverse/tree/medgemma-experiments-roadmap) | Accumulated fine-tuning experiments, datasets, reports and recent analytical safeguards |

Use the experiment branch to reproduce the work described below. Original Git
history is preserved from `mvp-ing/medgemma`.

The app implements local data storage, evidence analysis, guarded explanations,
personal experiments and exports. Its current analytical workflow focuses on
**recurring one-to-one meetings and heart rate**. The selected fine-tuned model
has been evaluated in a desktop/cloud runtime; Android still pins the original
vanilla artifact. Integrating the selected LoRA artifact and measuring it on a
physical phone remain open tasks.

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

Recurring-event identity, timezone/DST handling, control-allocation sensitivity
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
size/hash checks. The current pin is the original vanilla Q4 model, approximately
2.49 GB, not the selected LoRA v7 artifact. A configured download URL must serve
that exact pinned identity and support byte ranges. Keep credentials out of Git.

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

Latest experiment-branch verification: **123 Flutter tests**, **90 Python tests**,
and clean Flutter static analysis. Model training has additional GPU dependencies
and gated model access; follow the preserved configuration and recovery guide.

## Next milestones

1. Finish analytical correctness: recurring identity, time handling, control
   selection and stale-artifact invalidation.
2. Create a fresh independent benchmark through the real analytics pipeline.
3. Integrate the selected LoRA artifact and validate a physical Android workflow.
4. Verify live sources, privacy lifecycle, distribution and consent for a small pilot.
5. Observe a longitudinal pilot before expanding to additional context sources.

Vueniverse supports personal understanding and experimentation. It is a research
prototype, not a diagnostic or treatment system. See the
[roadmap](https://github.com/crixalis17/vueniverse/blob/medgemma-experiments-roadmap/docs/finetuning/PRODUCT-READINESS-ROADMAP.md)
for the complete readiness criteria.
