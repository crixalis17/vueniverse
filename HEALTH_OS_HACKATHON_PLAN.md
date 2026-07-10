# Private Health OS — Flutter-First Cross-Platform Plan

**Document status:** Hackathon implementation plan  
**Platforms:** Android and iOS  
**Primary UI and application language:** Dart / Flutter  
**Native edge languages:** Kotlin for Android; Swift for iOS  
**Privacy posture:** All personal data, analytics, feedback, and inference stay on-device by default.

---

## Executive summary

We will build a **Health OS**, not two separate mobile apps:

- **Flutter owns the product:** every screen, navigation path, state model, timeline, insight card, journal, settings screen, and shared business rule is written once in Dart.
- **Native code owns only the platform edge:** Android Health Connect, iOS HealthKit, calendar providers, background jobs, permission sheets, platform keys, and the low-level local model runtime.
- **A private canonical timeline joins the data:** the app converts sleep, heart rate, meetings, screen use, movement, location, and check-ins into one local event model with full provenance.
- **An evidence engine finds a pattern before MedGemma speaks:** deterministic analytics create an evidence card; MedGemma turns that evidence into a careful human explanation.
- **A contextual bandit provides safe on-device reinforcement learning:** it learns *when* and *how* to present insights, but never retrains LLM weights from a person’s private timeline.

For the one-week hackathon, the full architecture is real on both iOS and Android. The implementation proves it with the highest-value live paths:

1. Health data from Health Connect and HealthKit.
2. Calendar context from Android Calendar Provider and iOS EventKit.
3. Android app-usage context; iOS Screen Time is an entitlement/capability validation track.
4. Two evidence-backed insight types: late screen use -> sleep/recovery and recurring meetings -> pre-event physiological deviation.
5. A local MedGemma explanation pathway plus a local feedback learner.

> **Decision:** Use Flutter for UI and shared application logic; use typed native bridges for platform APIs; use FFI only for C/C++-shaped code such as a quantized local-model runtime.

---

## 1. Product definition

### 1.1 What is the Health OS?

A **Health OS** is a private personal-intelligence layer above data-producing apps and wearables. It does not compete with Ultrahuman, Apple Health, or Health Connect as a store of isolated measurements. It connects those measurements with the surrounding life context and helps the person understand patterns.

The central question is:

> **What changed in my body, what in my life may be connected to it, how certain is that pattern, and what is a safe small experiment to try?**

Example:

> “Across six comparable late nights, social-media use after 11:30 pm was associated with 48 fewer minutes of sleep and lower next-day recovery. This is a repeated association, not proof that the app caused the result. Try a 10:45 pm wind-down for three nights and compare.”

### 1.2 Product boundaries

The app is initially a wellness and self-understanding product.

- It does **not** diagnose a condition.
- It does **not** prescribe treatments or medication changes.
- It does **not** label a manager, friend, meeting, or app as the cause of stress.
- It does show the supporting data, alternatives, and uncertainty for every meaningful insight.

### 1.3 Primary product surfaces

| Flutter feature | Purpose |
|---|---|
| Home / Today | One or two useful, non-alarming observations with confidence and next action |
| Timeline | A merged view of health, schedule, activity, device behaviour, and check-ins |
| Insight detail | Observation, evidence, caveats, alternatives, and a reversible experiment |
| Evidence drawer | Exact time windows, baseline, repeat count, data sources, and data gaps |
| Health journal | Fast manual logs: mood, caffeine, illness, medication, alcohol, meals, life event |
| Sources centre | Per-source consent, supported fields, sync status, history window, revoke/delete |
| Experiments | Track a user-selected habit experiment against a personal outcome |
| Privacy centre | Export, delete, data locality, model version, and source provenance |

---

## 2. Flutter-first architecture

```mermaid
flowchart LR
    subgraph Flutter[Flutter / Dart: shared product]
        UI[Flutter UI and navigation]
        STATE[State and feature controllers]
        DOMAIN[Timeline, analytics, evidence, RL policy]
        STORE[Encrypted local data layer]
        API[Typed platform API contracts]
    end

    subgraph Android[Android host: Kotlin]
        AH[Health Connect]
        AC[Calendar Provider]
        AU[Usage Stats]
        AB[WorkManager, Keystore, sensors]
    end

    subgraph iOS[iOS host: Swift]
        IH[HealthKit]
        IC[EventKit]
        IM[Core Motion, Core Location]
        IB[Background tasks, Keychain, sensors]
    end

    AH & AC & AU & AB --> AN[Android native adapter]
    IH & IC & IM & IB --> IN[iOS native adapter]
    AN & IN <--> API
    API <--> STORE
    STORE <--> DOMAIN
    DOMAIN <--> STATE
    STATE <--> UI
```

### 2.1 What runs where?

| Layer | Language / runtime | Why it lives there |
|---|---|---|
| UI, navigation, state, product features | Flutter / Dart | One codebase and one product experience across iOS and Android |
| Canonical timeline, feature calculations, evidence logic, bandit policy | Dart | Shared deterministic behaviour and shared tests |
| App database schema, queries, repositories | Dart + platform database binding | One data model while retaining native encrypted storage support |
| Health, calendar, permissions, background, secure-key APIs | Kotlin or Swift through a Flutter plugin | These are operating-system APIs, not portable Dart APIs |
| Quantized model execution | C/C++ runtime through FFI, or native Kotlin/Swift runtime through a bridge | Local LLM runtimes are platform/hardware specific |

### 2.2 Flutter-native boundary rule

Use this decision rule for every capability:

1. **Flutter package with audited support exists:** use it behind our own adapter interface.
2. **The API is platform-specific but structured/high-level:** write a Kotlin/Swift plugin with **Pigeon** generated types.
3. **The API is a C/C++ inference or compute library:** use **Dart FFI**.
4. **The capability is impossible or prohibited on a platform:** return an explicit `unsupported` state; never fake parity.

The first two rules prevent Dart UI code from depending directly on Android or iOS details. The third prevents expensive serialization of high-throughput model data.

### 2.3 Recommended repository structure

```text
health_os/
  lib/
    app/                         # app shell, routing, theme, dependency wiring
    core/                        # errors, time, ids, privacy labels, utilities
    domain/                      # entities and pure business rules
    data/                        # database, repositories, source cache
    features/
      home/
      timeline/
      insights/
      journal/
      experiments/
      sources/
      privacy/
    platform_api/                # Dart interfaces and generated Pigeon APIs
  pigeon/                        # typed cross-platform API definitions
  test/                          # unit and integration tests for pure Dart logic
  integration_test/              # device-level tests
  android/app/src/main/kotlin/   # Android plugin implementations
  ios/Runner/                    # Swift plugin implementations and entitlements
  native/inference_runtime/      # optional C/C++ FFI package for local models
  docs/                          # plan, schemas, demo script, decisions
```

---

## 3. Definitions and glossary

| Term | Plain-English definition | Why it matters here |
|---|---|---|
| **Adapter / connector** | A small component that knows how to read one data source and convert it into our shared format. | HealthKit, Health Connect, EventKit, and Usage Stats each need a different adapter. |
| **Platform channel** | A message bridge between Dart and native Kotlin/Swift code. | Used for high-level OS APIs such as health permissions and calendar reads. |
| **Pigeon** | A Flutter tool that generates type-safe Dart, Kotlin, and Swift channel code from one API definition. | Prevents fragile `Map<String, dynamic>` contracts between Flutter and native code. |
| **FFI (Foreign Function Interface)** | A direct call from Dart into compiled C/C++ code. | Suitable for a local LLM runtime or other performance-critical native library. |
| **Canonical event** | One shared representation of an event regardless of where it came from. | A HealthKit sleep session and a Health Connect sleep session can be analysed by the same code. |
| **Ingestion** | Pulling external data into the app and storing it safely. | Includes permission, backfill, sync, validation, deduplication, and deletion handling. |
| **Backfill** | The first bounded import of historical data. | Lets the app establish personal baselines without requesting unlimited history by default. |
| **Delta sync** | Importing only records changed since the previous successful sync. | Reduces battery, latency, and duplicate records. |
| **Cursor / anchor / token** | A checkpoint supplied by a source that marks where the next delta sync should resume. | Health Connect uses change tokens; HealthKit can use anchors. |
| **Provenance** | Metadata describing where a value came from and when it was changed. | Required to explain and debug an insight; prevents silent source confusion. |
| **Feature** | A derived numeric or categorical signal such as “screen time in the two hours before bed.” | Features turn raw events into inputs for pattern detection. |
| **Personal baseline** | A user’s typical value under comparable conditions. | “High for you” is more meaningful than a population average. |
| **Matched control window** | A similar period used for comparison, such as the same weekday/hour without a meeting. | Reduces misleading correlations caused by time of day or activity. |
| **Evidence card** | A structured, machine-readable explanation of why a pattern passed the analytical threshold. | Grounds MedGemma and enables a user-visible evidence view. |
| **Inference** | Running a model to produce an output. | Here: turn an evidence card into a cautious explanation locally. |
| **Quantization** | Compressing a model’s numeric weights to use less memory and power. | Makes a 4B model more plausible on high-end phones. |
| **Contextual bandit** | A lightweight form of reinforcement learning that learns which action works best in a situation. | Learns insight timing/tone/action without retraining the LLM. |
| **Idempotent operation** | An operation that produces the same final result even if it runs more than once. | Essential for sync retries and crash recovery. |

---

## 4. Data sources and collection strategy

### 4.1 Unified source matrix

| Domain | Android source | iOS source | Example canonical events | Hackathon priority |
|---|---|---|---|---:|
| Health and wearables | Health Connect | HealthKit | sleep session, HR sample, HRV, workout, steps, SpO2, skin temperature | P0 |
| Ring data | Health Connect export or official vendor connector | HealthKit export or official vendor connector | vendor recovery score, sleep summary, activity summary | P0 if exported |
| Calendar | Calendar Provider | EventKit | meeting, travel, social event, recurring block | P0 |
| Screen / app use | UsageStatsManager | Screen Time validation track | app-category session, last-device-use time | P0 Android / P1 iOS |
| Motion and place | Activity Recognition and location | Core Motion and Core Location | walking, driving, commute, outdoor interval | P1 |
| Environment | sensors and on-device sound-level derivation | sensors and on-device sound-level derivation | noise bucket, light exposure proxy | P2 |
| Journal | Flutter form | Flutter form | caffeine, mood, illness, medication, alcohol, meal time | P0 |
| Medical records | Health Connect FHIR when available | HealthKit records when available | lab result, allergy, medication record | P2 |

### 4.2 Privacy-safe context policy

Allowed by default after explicit source consent:

- time, duration, recurrence, category, data origin, and approximate count/bucket;
- health measurements the person selected;
- coarse app category and duration rather than app content;
- user-entered journal facts.

Never ingest in v1:

- message bodies, email text, notification content, call audio, phone-call history, browser history, screen images, or social-feed content;
- raw calendar descriptions, attendee names, or locations unless a future specific feature requires it and the person opts in.

### 4.3 Ring integration rule

Ultrahuman is treated as a source, not as the centre of the architecture. Start with the platform health store. Add a direct Ultrahuman adapter only if a user-approved official interface provides a critical signal unavailable through Health Connect or HealthKit. Never reverse engineer ring Bluetooth traffic for the hackathon.

---

## 5. Unified ingestion and storage pipeline

```mermaid
flowchart LR
    P[Source choice and consent] --> R[Connector registry]
    R --> B[Initial bounded backfill]
    R --> D[Delta sync from source cursor]
    B --> RAW[Encrypted immutable raw records]
    D --> RAW
    RAW --> V[Validate, normalise, time-zone handling]
    V --> X[Deduplicate and reconcile sources]
    X --> T[Canonical timeline]
    T --> F[Derived features]
    F --> E[Evidence cards]
    E --> I[Insights and experiments]
```

### 5.1 Connector lifecycle

Each Flutter-facing source adapter exposes the same lifecycle:

```text
requestAccess(selectedDataTypes)
getAvailability()
initialBackfill(timeWindow)
readDelta(cursor)
normalise(nativeRecord)
revokeAccessAndPurge(scope)
```

**Implementation pattern:**

- Dart feature code calls a Pigeon-generated `HealthSourceApi` / `CalendarSourceApi`.
- The Android Kotlin implementation calls Health Connect, Calendar Provider, or Usage Stats.
- The iOS Swift implementation calls HealthKit, EventKit, or Core Motion.
- Both return the same typed DTOs to Dart.
- Dart validates and saves data inside a transaction.

### 5.2 Canonical data contract

```json
{
  "id": "evt_01J...",
  "type": "calendar.meeting",
  "startAt": "2026-07-10T10:00:00+05:30",
  "endAt": "2026-07-10T10:30:00+05:30",
  "value": {
    "category": "recurring_one_to_one",
    "attendeeCountBucket": "2"
  },
  "origin": {
    "platform": "ios",
    "provider": "EventKit",
    "externalId": "source-private-id"
  },
  "sourceModifiedAt": "2026-07-09T09:00:00+05:30",
  "privacyLevel": "sensitive",
  "schemaVersion": 1
}
```

### 5.3 Local tables

| Table | Data | Rule |
|---|---|---|
| `raw_records` | Original source payload and source metadata | Immutable; encrypted; do not silently overwrite |
| `canonical_events` | Normalized shared timeline events | Stable IDs and provenance preserved |
| `sync_cursors` | Change token/HealthKit anchor/checkpoint | Update only after a complete successful transaction |
| `derived_features` | Baselines, exposures, daily aggregates | Version by algorithm version |
| `evidence_cards` | Effect, repeats, controls, alternatives, confidence | Keep source-event references and computation version |
| `insights` | Rendered model output and safety result | Always reference an evidence-card version |
| `feedback_events` | Helpful, dismiss, snooze, action feedback | Local only; opt-out capable |

### 5.4 Storage and encryption

Recommended Flutter data layer:

- **Drift + SQLite** for typed, reactive local queries.
- **SQLCipher-compatible encrypted SQLite build** for database-at-rest protection.
- **flutter_secure_storage** only for wrapping/holding the database key, not for time-series data.
- Android key material from **Android Keystore**; iOS key material from **Keychain**.

Data should never be stored in ordinary preferences, plaintext JSON exports, app logs, analytics SDKs, or crash reports.

### 5.5 Sync correctness rules

1. Use source-origin IDs to deduplicate. If no source ID exists, use a stable hash of origin, type, start/end, and value.
2. Do not add two providers’ step counts together. Let the person choose a primary source per metric; retain alternatives for inspection.
3. Preserve source time zone and device metadata. Convert only for display/analysis.
4. Treat vendor “stress” and “recovery” as vendor-derived scores, not clinical measurements.
5. A source deletion or permission revocation cascades: raw record -> canonical event -> feature invalidation -> evidence/insight invalidation.
6. Every ingestion write is idempotent, so retrying after an interruption cannot create duplicate health events.

---

## 6. Analytics, evidence, and MedGemma inference

```mermaid
flowchart TD
    T[Canonical timeline] --> B[Personal baselines]
    B --> A[Deviation and change detection]
    A --> W[Event windows and lag analysis]
    W --> M[Matched comparable windows]
    M --> C[Confounder assessment]
    C --> E[Evidence card]
    E --> P[Safety and claim policy]
    P --> L[Local MedGemma gateway]
    L --> J[Validated structured insight]
    J --> U[Flutter insight UI]
```

### 6.1 The analysis engine: what it does

The non-LLM analysis engine is the core intelligence. It must calculate, not guess:

- personal hour-of-day and weekday baselines for resting HR, HRV, sleep duration, and recovery;
- deviations from those baselines;
- event windows: for example, 15/30/60 minutes before and after a recurring meeting;
- lagged patterns: late screen use -> sleep -> next-day recovery;
- matched controls: comparable hours/days without the event;
- confounders: workout, walking, caffeine, illness, travel, missing-data periods;
- confidence from repeat count, effect size, data quality, and conflicting evidence.

### 6.2 Evidence card contract

```json
{
  "claimType": "repeated_association",
  "claim": "Late social-media use is associated with shorter sleep",
  "occurrences": 6,
  "comparisonWindows": 14,
  "effect": {"metric": "sleep_duration_minutes", "delta": -48},
  "confidence": "moderate",
  "alternatives": ["late workout", "caffeine after 17:00"],
  "permittedLanguage": ["associated with", "may contribute"],
  "prohibitedLanguage": ["caused", "diagnosis", "treatment"]
}
```

### 6.3 MedGemma gateway

`LocalModelGateway` is a Dart interface:

```text
generateInsight(evidenceCard, tone, guidanceContext) -> InsightDraft
healthCheck() -> ModelRuntimeStatus
```

Its rules:

- It receives the evidence card, selected tone, and curated local guidance—not a raw dump of the timeline.
- It produces strict JSON: `observation`, `evidenceSummary`, `uncertainty`, `suggestedExperiment`, and `seekCareMessage` only when a deterministic safety flag permits it.
- Dart validates the JSON and claim wording before displaying it.
- It may not diagnose, prescribe, use causal language that the evidence card forbids, or invent values.

### 6.4 Local-model runtime path

| Need | Choice |
|---|---|
| Flutter app calls a high-level model method | Dart repository / `LocalModelGateway` |
| Health/permissions/model-host integration | Kotlin/Swift plugin via Pigeon |
| Quantized C/C++ model backend | Dart FFI package |
| Primary model experiment | Quantized MedGemma 4B instruction-tuned model on capable devices |
| Device fallback | Smaller local explanation model using the same evidence-card interface |
| Hackathon contingency | Clearly labelled local development-machine inference; no claim that it is phone-local |

Run a real device performance spike on Day 1. Measure memory, first-token latency, total generation time, thermals, battery, model-download size, and behaviour in background/foreground transitions before promising phone-local MedGemma to judges.

---

## 7. On-device reinforcement learning

Use reinforcement learning to optimise the **insight policy**, not to mutate a medical language model on every phone.

```mermaid
flowchart LR
    C[Local context: time, recovery, preference] --> A[Choose timing, insight, tone, experiment]
    A --> U[User response]
    U --> R[Reward signal]
    R --> B[Contextual bandit update]
    B --> A
```

### 7.1 Contextual bandit design

| Component | Design |
|---|---|
| Context | Current time, local quiet hours, insight confidence, recent recovery, source availability, past stated preference |
| Actions | Show now, evening reflection, weekly review, suppress; concise/detailed; reflection/experiment |
| Reward | Helpful, acted on suggestion, snoozed, dismissed; explicitly not “time in app” |
| Algorithm | Thompson Sampling first; LinUCB if feature space grows |
| Storage | `feedback_events` and policy parameters in encrypted local storage |
| User controls | Disable learning, reset learned preferences, inspect why an insight was shown |

### 7.2 Later LLM improvement

After the hackathon, improve MedGemma offline using this sequence:

1. **Supervised fine-tuning (SFT):** examples of excellent evidence-grounded insights.
2. **Preference training:** clinician/reviewer chooses a grounded, safe response over an overconfident response.
3. **GRPO:** reward generated outputs for schema validity, factual support, causal calibration, safety, clarity, and helpfulness.
4. Quantize and deploy a frozen model. Do not continuously train it on private phone timelines.

---

## 8. Privacy, safety, and compliance posture

### 8.1 Privacy guarantees for v1

- No personal health data, calendar context, feedback, prompts, or insights are sent to an app backend.
- No third-party product analytics or session replay SDK can see the data.
- Model downloads may use the network but contain no user health data.
- Users can toggle sources individually, choose import history depth, see provenance, export local data, delete local data, and revoke a source.

### 8.2 Safety policy

- Use “associated with,” “appears before,” and “may contribute” unless an evidence card supports an intervention-level conclusion.
- Never issue an LLM-generated urgent alert. Any future emergency path must come from clinically reviewed deterministic criteria.
- Never write a statement about a third party’s intent or a user’s mental-health diagnosis from wearables or calendar context.
- Avoid anxiety-producing push notifications about physiological changes. Prefer a deliberate reflection or weekly review.

### 8.3 Important reality check

On-device processing sharply reduces data exposure; it does **not** remove the need for consent, secure engineering, platform permission compliance, honest wellness positioning, or a medical-product review before clinical claims.

---

## 9. Seven-day implementation plan

### 9.1 Definition of hackathon success

By the demo, both Android and iOS apps must visibly share the same Flutter product UI and canonical data model. Each must ingest at least one live health source and one live context source. The app must create an evidence card, generate a safe explanation, and show local feedback adaptation.

### 9.2 Execution lanes and critical path

There are three parallel lanes. The first four gates are the **critical path**: if any one is missing, the final insight cannot be trusted or demonstrated.

```mermaid
flowchart LR
    D1[Day 1: Flutter shell + typed contracts] --> D2[Day 2: health data reaches Dart]
    D2 --> D3[Day 3: context data reaches Dart]
    D3 --> D4[Day 4: evidence cards]
    D4 --> D5[Day 5: model explanation]
    D5 --> D6[Day 6: local learning + polish]
    D6 --> D7[Day 7: reliable demo]

    A[Builder A: Flutter UI + Android] -.parallel.-> D1
    B[Builder B: domain + iOS] -.parallel.-> D1
    C[Codex: contracts, tests, scaffolding, prompts] -.support.-> D1
```

| Lane | Main owner | Deliverables | Must not do |
|---|---|---|---|
| **Flutter product lane** | Builder A | app shell, database, source screens, timeline, evidence/insight UI, feedback UI | wait for real health permissions before building the UI |
| **Data and reasoning lane** | Builder B | canonical contracts, ingest mapper, seed timeline, baseline logic, evidence cards, bandit policy | let the LLM calculate correlations |
| **Native edge lane** | Both, split by platform | Android Kotlin adapters; iOS Swift adapters; Pigeon bridge; local model runtime experiment | expose raw platform objects directly to Dart UI |
| **Codex support lane** | Codex | code scaffolding, bridge types, seed data, test cases, algorithm helpers, docs, prompts, demo script | become a dependency for a basic build/run loop |

### 9.3 Day 0 / first two hours: preflight

Do this before feature work. A hackathon loses more time to toolchain and device problems than algorithms.

| Check | Owner | Exact result required |
|---|---|---|
| Flutter toolchain | Builder A | `flutter doctor` is clean enough to build Android and iOS; one physical Android phone and one iPhone are developer-trusted |
| Apple setup | Builder B | Xcode opens the iOS Runner, signing team is selected, HealthKit capability is enabled, app launches on the iPhone |
| Android setup | Builder A | Android project builds on device; Health Connect availability screen can open |
| Repository baseline | Both | `main` opens the same seed timeline on Android and iOS before any native source work |
| Seed data | Codex + Builder B | One deterministic seven-day timeline produces both target insight examples offline |
| Model decision | Both | Choose a four-hour Day-1 spike: actual on-device MedGemma, smaller local model, or clearly labelled development-machine fallback |

#### Flutter packages and project choices

Use one simple stack; do not spend the week comparing state-management frameworks.

| Concern | Choice for this hackathon | Why |
|---|---|---|
| State | `flutter_riverpod` | predictable providers and easy test overrides for seed/live data |
| Routing | `go_router` | a small declarative route tree for Home, Timeline, Sources, Insight Detail, Journal, Privacy |
| Database | `drift` over SQLite | typed queries, migrations, and streams for a time-based local product |
| Database encryption | SQLCipher-compatible SQLite build | encrypt the timeline at rest; use normal SQLite only as a documented hackathon fallback |
| Secure key storage | `flutter_secure_storage` | stores/wraps the database key with Keychain/Keystore support |
| Native bridge | Pigeon | generated typed Dart/Kotlin/Swift contracts |
| Model runtime | separate `LocalModelGateway` | lets UI/analytics survive model-runtime uncertainty |

### 9.4 Build order: create these contracts before screens

Do **not** begin with a dashboard. First create these Dart models and repositories. Every UI screen and native adapter depends on them.

```text
lib/domain/models/
  canonical_event.dart
  raw_record.dart
  source_descriptor.dart
  sync_cursor.dart
  derived_feature.dart
  evidence_card.dart
  insight.dart
  feedback_event.dart

lib/domain/repositories/
  timeline_repository.dart
  source_repository.dart
  insight_repository.dart
  model_gateway.dart

lib/platform_api/
  health_source_api.dart
  calendar_source_api.dart
  device_context_api.dart
```

Minimum typed contracts:

```text
CanonicalEvent
  id, type, startAt, endAt, value, origin, sourceModifiedAt,
  privacyLevel, schemaVersion

EvidenceCard
  id, claimType, claim, inputEventIds, occurrences, comparisonWindows,
  effect, confidence, alternatives, permittedLanguage, algorithmVersion

Insight
  id, evidenceCardId, observation, evidenceSummary, uncertainty,
  suggestedExperiment, policyStatus, createdAt
```

#### Pigeon bridge shape

Keep Pigeon APIs coarse-grained. A Dart call should return a batch of normalized source records, not one callback per heart-rate point.

```text
HealthSourceHostApi
  getAvailability() -> SourceAvailability
  requestAccess(types) -> PermissionResult
  readInitial(startAt, endAt, types) -> NativeRecordBatch
  readChanges(cursor, types) -> NativeChangeBatch

CalendarSourceHostApi
  requestAccess() -> PermissionResult
  readEvents(startAt, endAt) -> NativeRecordBatch

DeviceContextHostApi
  getAvailability() -> SourceAvailability
  readUsageSummary(startAt, endAt) -> NativeRecordBatch
```

The Flutter layer owns `normalise()` and `saveBatchTransactionally()`. Android and iOS implementations should only retrieve the platform data and map it to the Pigeon transport DTO.

### 9.5 Detailed daily implementation playbook

#### Day 1 — Working Flutter product with deterministic seed data

**Goal:** Both phones run the same visual product before live integrations exist.

| Owner | Tasks | Files / modules | Definition of done |
|---|---|---|---|
| Builder A | Create Flutter application, theme, route shell, Home/Timeline/Sources placeholders, Riverpod providers. | `lib/app/`, `lib/features/home/`, `lib/features/timeline/` | Android and iOS show the same Flutter timeline UI. |
| Builder B | Implement `CanonicalEvent`, `EvidenceCard`, `Insight`, `TimelineRepository`, and a seeded in-memory repository. | `lib/domain/`, `lib/data/seed/` | Seven seeded days contain sleep, HR, two recurring meetings, late-screen events, and journal entries. |
| Builder A | Generate Pigeon project skeleton and register Android host APIs. | `pigeon/`, `android/.../HealthSourcePlugin.kt` | Flutter can call a fake `getAvailability()` on Android. |
| Builder B | Register the matching iOS Swift host APIs and HealthKit capability. | `ios/Runner/HealthSourcePlugin.swift`, Xcode capabilities | Flutter can call a fake `getAvailability()` on iOS. |
| Codex | Generate seed fixture, fixture tests, UI copy, route map, and bridge DTOs. | `test/fixtures/`, `pigeon/` | Seed data produces deterministic cards in test. |

**End-of-day demo:** Tap Timeline -> choose a day -> see body/schedule/device events. No permissions required.

**Fallback:** if Pigeon generation blocks progress, use a temporary `MethodChannel` with the exact same method names and replace it on Day 2. Do not block the Flutter UI.

#### Day 2 — Health ingestion into the shared Dart repository

**Goal:** One real health source per platform becomes a `CanonicalEvent` in the same local database.

| Owner | Tasks | Files / modules | Definition of done |
|---|---|---|---|
| Builder A | Implement Android availability/permission/read flow for selected Health Connect types: sleep, heart rate, HRV, steps/activity. | `android/.../HealthConnectAdapter.kt` | A button imports a bounded seven-day window and reports record count/source. |
| Builder B | Implement iOS HealthKit authorization/read flow for sleep, heart rate, HRV, steps/activity. | `ios/Runner/HealthKitAdapter.swift` | The equivalent button imports the same logical types from HealthKit. |
| Builder A | Add Drift migrations/tables; wrap ingestion in one transaction. | `lib/data/database/`, `lib/data/repositories/` | Closing/reopening app preserves imported events. |
| Builder B | Implement platform-record-to-Dart DTO normalisation and dedupe keys. | `lib/domain/mappers/` | Repeating import does not double the visible event count. |
| Codex | Write mapping tests and unsupported/denied permission UI states. | `test/domain/`, `lib/features/sources/` | User can tell “connected,” “denied,” “unsupported,” and “no data yet” apart. |

**Scope guard:** request only the data types needed by the two demo insights. Do not request glucose, medical records, nutrition, or every HealthKit type.

**End-of-day demo:** Connect a health source, import seven days, view real or seeded sleep/HR events in the same timeline.

#### Day 3 — Context ingestion and source provenance

**Goal:** Add life context without turning the product into surveillance.

| Owner | Tasks | Files / modules | Definition of done |
|---|---|---|---|
| Builder A | Implement Android `READ_CALENDAR`, bounded event query, local categorisation, and Usage Stats summary. | `android/.../CalendarAdapter.kt`, `UsageStatsAdapter.kt` | Flutter receives meeting intervals and category-level app-use sessions. |
| Builder B | Implement iOS EventKit full-access request and event query; add Core Motion only if EventKit is complete. | `ios/Runner/EventKitAdapter.swift` | Flutter receives the same meeting interval DTO. |
| Both | Implement on-device calendar categoriser: rule-based keywords/recurrence only; do not send title text to model. | `lib/domain/categorisation/` | Event detail shows `recurring_one_to_one` or `meeting`, not exposed raw title by default. |
| Builder A | Add provenance chip and source filter to Timeline. | `lib/features/timeline/` | Each displayed event has provider/origin and data-time detail. |
| Codex | Create seed data plus expected mapped calendar/device events. | `test/fixtures/` | The app operates identically when a source is unavailable. |

**Scope guard:** iOS Screen Time is not a blocker. Surface it as “requires device capability/approval” and keep the rest of the iOS demo complete.

**End-of-day demo:** Timeline contains health + calendar on both phones; Android additionally shows a category-level late-night app-use interval.

#### Day 4 — Make the product intelligent without an LLM

**Goal:** Generate evidence cards using transparent deterministic algorithms.

Implement exactly two algorithms, not a general causal-AI platform.

**Algorithm A: late screen use and sleep**

```text
For each night with a known sleep start:
  screenExposure = app-use duration in [sleepStart - 2 hours, sleepStart)
  isLateScreenNight = screenExposure >= 30 minutes after configured quiet hour
  nextSleepDuration = sleep end - sleep start

Compare late-screen nights with non-late nights.
Create an EvidenceCard only when:
  lateScreenNights >= 4
  sleep-duration difference >= 30 minutes
  data completeness >= 70 percent
```

**Algorithm B: recurring meeting and pre-event HR**

```text
For each matching recurring meeting category:
  preMeetingHr = median HR in [-15 minutes, event start)
  matchedHr = median HR at comparable weekday/time windows without meeting
  exclude a window if recent steps/activity exceed threshold

Create an EvidenceCard only when:
  comparable meetings >= 4
  average difference >= 8 bpm
  at least 60 percent of occurrences point in the same direction
```

| Owner | Tasks | Definition of done |
|---|---|---|
| Builder B | Implement baseline, windows, controls, effect, confidence, and evidence-card generator as pure Dart. | Unit tests pass against seeded expected evidence cards. |
| Builder A | Build Home insight card and Evidence Detail screen. | User can tap from natural-language claim to repetitions, effect, caveats, and source events. |
| Both | Add “not enough comparable data” result and never manufacture an insight. | Empty/partial live data produces a calm, honest empty state. |
| Codex | Write test cases for confounders, duplicate imports, data gaps, and malicious/overconfident claim wording. | Evidence logic is testable without a phone. |

**End-of-day demo:** With the model disabled, the app still demonstrates exactly why it believes an insight is present.

#### Day 5 — Add MedGemma through a safe, replaceable gateway

**Goal:** Convert an evidence card into a careful explanation without coupling product success to one runtime.

| Owner | Tasks | Definition of done |
|---|---|---|
| Builder A | Implement `LocalModelGateway`, `InsightRepository`, loading/error UI, and JSON-schema validator. | App accepts only validated `InsightDraft` JSON. |
| Builder B | Perform the real device runtime spike: load model, call one prompt, measure memory/latency/thermal result. | Written go/no-go decision by end of the day. |
| Both | Implement prompt template containing evidence JSON, prohibited claims, exact schema, and one allowed experiment. | Generated copy uses “associated with” rather than “caused.” |
| Codex | Create golden input/output fixtures, safety checks, and a transparent fallback response template driven by evidence card. | Model failure still leaves a useful, clearly labelled deterministic explanation. |

**Runtime decision ladder:**

1. Actual quantized MedGemma 4B executes on test phone: use it.
2. A smaller local model executes acceptably: use it only if hackathon rules permit and label the model accurately.
3. Local development machine runs MedGemma: use only as a clearly labelled demo fallback; the phone still owns all local data/evidence calculations.
4. No runtime works: demo the deterministic evidence card and explanation template; do not claim on-device LLM inference.

**End-of-day demo:** An EvidenceCard becomes a structured Insight with observation, evidence summary, caveat, and experiment.

#### Day 6 — Personalisation, privacy, and demo resilience

**Goal:** Make it feel like a Health OS, not a prototype screen.

| Owner | Tasks | Definition of done |
|---|---|---|
| Builder B | Implement deterministic Thompson Sampling policy with 3–4 actions and local feedback persistence. | Helpful/dismiss feedback changes the selected presentation after a few seeded/real interactions. |
| Builder A | Implement Journal, source toggles, provenance view, delete-local-data confirmation, and accessibility pass. | User can add a caffeine/mood log and disable a source without app failure. |
| Both | Add demo-mode switch that chooses seed or live repository at app launch. | A flaky permission, network, or wearable cannot break the presentation. |
| Codex | Draft pitch sequence, final wording, screenshots/recording checklist, error-state copy. | Recorded backup demo shows all major flows. |

**Bandit actions:** `show_now`, `include_in_evening_reflection`, `include_in_weekly_review`, `suppress`. The reward is `helpful`, `acted`, `snoozed`, or `dismissed`; never use time-in-app as a reward.

#### Day 7 — Stabilise, rehearse, and submit

**Goal:** A reliable story on both platforms.

| Owner | Tasks | Definition of done |
|---|---|---|
| Builder A | Android clean build, install, source/permission regression pass, screenshots. | Android demo works from fresh install with seed fallback. |
| Builder B | iOS clean build, install, entitlement/permission regression pass, screenshots. | iOS demo works from fresh install with seed fallback. |
| Both | Run the eight-step demo three times without editing code between runs. | One person narrates while the other watches for breakage. |
| Codex | Tighten submission text around privacy, evidence-first insight, cross-platform architecture, and local learning. | 60-second and 3-minute demos are scripted. |

### 9.6 Team split

| Owner | Primary responsibilities | Daily handoff rule |
|---|---|---|
| Builder A | Flutter UI shell, Drift data layer, timeline/insight/evidence screens, Android bridge/adapters, final Android QA | Commit an app that runs with seed data before handing over native changes. |
| Builder B | Dart analytics/contracts, iOS bridge/adapters, model gateway/runtime spike, bandit policy, final iOS QA | Every algorithm has a seed fixture and expected output before UI integration. |
| Codex | Scaffold, bridge contracts, schemas, seed fixtures, analytics/evidence tests, prompts, documentation, debugging, UI copy, demo narrative | Provide copy-pasteable isolated changes and keep a written decision log. |

### 9.7 Non-negotiable gates

1. **End of Day 1:** Android and iOS display the same seeded Flutter timeline.
2. **End of Day 2:** Android Health Connect and iOS HealthKit each write into the shared Dart data repository.
3. **End of Day 3:** Calendar events appear as canonical events on both platforms; Android usage data is additive.
4. **End of Day 4:** Two evidence cards are produced with no LLM involved.
5. **End of Day 5:** A valid evidence card becomes a schema-validated insight through the model gateway.
6. **End of Day 6:** Helpful/dismiss feedback changes future delivery locally.
7. **Start of Day 7:** The seed-data demo runs fully offline on both phones.

### 9.8 Risks and pre-decided responses

| Risk | Response |
|---|---|
| Ultrahuman data does not reach the health store | Use explicitly labelled seeded ring-compatible data; preserve generic health-store integration |
| iOS Screen Time route is unavailable | Expose the source as unsupported; demo HealthKit + EventKit + Core Motion, not fake app-usage data |
| MedGemma does not run acceptably on a test phone | Keep model gateway; use a clearly labelled local development fallback and demo the phone-local evidence engine |
| Health permissions take too long | Seed demo data remains first-class, not a last-minute mock |
| Data is incomplete or contradictory | Lower confidence and display “not enough comparable data”; do not force an insight |
| One native platform falls behind | Keep all Flutter UI and algorithms source-agnostic; use the seeded repository for that platform, but demo the other platform’s live adapter honestly |
| Pigeon setup blocks native work | Temporarily substitute a narrow `MethodChannel`; retain the same Dart interface and return to generated types after the demo |

---

## 10. Demo story

1. Launch the same Flutter Health OS on an Android phone and iPhone.
2. Open Sources and show health/calendar permission states.
3. Display a merged private timeline with source provenance labels.
4. Show an insight: late screen use is associated with shorter sleep, or recurring meeting windows are associated with elevated pre-event HR.
5. Open the evidence drawer: repeat count, matched comparison windows, effect, alternatives, and confidence.
6. Mark it Helpful or dismiss it.
7. Show a later recommendation with timing/tone adjusted by the on-device bandit.
8. End with the privacy promise: **“Your life data is used to help you, not to build a profile of you elsewhere.”**

---

## 11. Technical references

- Flutter’s official overview of platform-specific integration and custom plugins: <https://docs.flutter.dev/platform-integration>
- Flutter platform channels and Kotlin/Swift host support: <https://docs.flutter.dev/platform-integration/platform-channels>
- Flutter FFI and the recommended `package_ffi` template: <https://docs.flutter.dev/platform-integration/bind-native-code>
- Android Health Connect differential sync: <https://developer.android.com/health-and-fitness/health-connect/sync-data>
- Apple HealthKit anchored incremental queries: <https://developer.apple.com/documentation/healthkit/hkanchoredobjectquery>
- Apple HealthKit background delivery: <https://developer.apple.com/documentation/healthkit/executing-observer-queries>

---

## 12. Final implementation choice

**Use Flutter as the primary application platform.**

Write the Health OS UI and all product/domain logic once in Dart. Use Kotlin and Swift only where the operating systems require native access. Use Pigeon-generated platform channels for Health Connect, HealthKit, calendars, permissions, background behaviour, and secure keys. Use FFI only for a C/C++ local inference runtime or another genuinely performance-sensitive native module.

The first code artefact should be the typed `EvidenceCard` and `CanonicalEvent` contract. Once those are stable, every new wearable or app becomes an adapter addition—not a rewrite of the Health OS.
