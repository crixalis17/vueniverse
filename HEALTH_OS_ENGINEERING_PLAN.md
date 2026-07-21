# Vueniverse — Focused Build Week Engineering Plan

**Category:** Apps for Your Life

**Deadline:** July 21, 2026 at 5:00 PM Pacific Time

**Platforms:** Android and iOS through Flutter

**Document purpose:** Technical companion for architecture, analytics, model boundaries, and delivery
**Presentation companion:** [Vueniverse Focused Build Week Plan](HEALTH_OS_HACKATHON_PLAN.md)

---

## Engineering summary

Vueniverse will ship one complete loop:

> **Collect health and context data locally → align health around meaningful events → compare repeated windows → create verified evidence → let MedGemma investigate and explain it → show a careful daily insight.**

The hackathon build will not attempt to implement the entire Health OS. It will:

1. Connect essential sources: Health Connect or HealthKit, Calendar, Manual Check-ins, and Demo Data.
2. Convert health readings and context into one private timeline.
3. Run a daily local job over a rolling history, not just the current day.
4. Slice health signals before, during, and after events.
5. Calculate summaries, matched comparisons, repetition, completeness, and possible influences with deterministic code.
6. Let MedGemma select from a small list of permitted investigations and explain only evidence that the analytical engine has verified.
7. Check MedGemma’s final wording before displaying it.
8. Show one strong working insight flow on Android and iOS.

All broader features remain visible in the app as clearly labelled **Preview** or **Coming later** screens. The UI communicates the full Health OS vision without implying that unfinished integrations or algorithms work.

Vueniverse reports:

- within your usual range;
- different from your usual range;
- a developing pattern;
- a repeated association;
- no repeatable association yet;
- insufficient data;
- another influence may explain the difference.

It does **not** label a person, meeting, app, or behaviour as simply “healthy” or “unhealthy.”

---

## Engineering terminology lens

The scope and commitments are identical to the presentation plan. Use the terms below during implementation and technical review; keep the simpler terms in the consumer UI.

| Product phrase | Engineering phrase | Meaning |
|---|---|---|
| Private timeline | Canonical temporal store | Source-normalized, time-indexed health and context records with provenance |
| Event window | Event-conditioned physiological window | Bounded pre-event, during-event, and recovery observations |
| Similar period | Matched control window | A non-event period selected under explicit comparability rules |
| Difference | Effect estimate | Robust event-versus-control summary with an uncertainty range |
| Possible influence | Candidate confounder | A measured factor that may account for part of an observed association |
| Evidence | Evidence provenance record | Counts, estimates, exclusions, missingness, source lineage, and analytical version |
| Enough evidence | Promotion gate | Deterministic minimums for repetition, consistency, completeness, and effect magnitude |
| MedGemma Explorer | Bounded analytical planner | Selects from an allow-listed analytical capability catalogue |
| MedGemma Explainer | Evidence-conditioned generator | Produces schema-constrained language from verified aggregate evidence |
| Output guard | Deterministic claim-validation gate | Verifies numeric entailment, causal calibration, prohibited content, and safe actions |
| Daily analysis | Incremental rolling recomputation | Updates only data-dependent windows across the fixed 30-day horizon |
| Delete source data | Dependency invalidation and purge | Removes source records and marks dependent analytical outputs stale |

Implementation-level class, enum, and schema names stay in source code and tests rather than this plan.

---

## 1. Honest scope

### 1.1 SHIP — what must work

| Working capability | One-week result |
|---|---|
| Source consent | Health, Calendar, Manual Check-ins, and Demo Data can be enabled independently. |
| Local ingestion | New health and calendar records enter an encrypted local timeline with source and time provenance. |
| Daily rolling analysis | A background or foreground job processes new records and updates the previous 30 days. |
| Event-aligned windows | Health is summarized before, during, and after a contextual event. |
| Matched comparisons | Event windows are compared with similar non-event periods from the user’s own history. |
| Two analyses | Recurring meeting → pre-event heart rate works with live or seed data; late digital activity → sleep works with seed data. |
| Evidence view | The user sees repetitions, effect range, comparison windows, exclusions, missing data, and possible influences. |
| MedGemma investigation | MedGemma chooses only among approved questions that the local analytical engine knows how to calculate. |
| MedGemma explanation | MedGemma turns verified evidence into understandable, cautious language. |
| Output guard | Unsupported numbers, diagnoses, prescriptions, and causal claims are rejected. |
| Daily insight | Today shows one high-value insight or an honest “not enough repeatable evidence yet” state. |
| Demo resilience | The complete flow works from deterministic demo data if permissions, sync, or local model inference fail. |

### 1.2 STRETCH — UI preview first

These features receive complete navigation, realistic sample content, and an explanation of how they will work, but do not need a live backend during the hackathon:

- Ask Vueniverse conversation;
- personal experiments and “Test this”;
- animated Timeline Replay and Temporal Bodyprint;
- editable Influence Radar;
- weekly pattern digest;
- notification coaching and quiet intelligence;
- negative findings and insight lifecycle;
- Spotify, Strava, phone-session, Discord, WhatsApp, and screen-time connectors;
- proof/export view;
- model-personalization controls.

### 1.3 DESIGN — Coming later

These appear in the feature gallery as **Coming later** and never pretend to be functional:

- direct partner wearable SDKs beyond health stores;
- iOS Screen Time entitlement integration;
- FHIR and clinical-record imports;
- clinician export;
- smart-home and environment connectors;
- What-if Lab;
- federated detector packs;
- multimodal meal or symptom capture;
- personal digital twin;
- actual MedGemma weight training.

### 1.4 UI truth rule

Every feature uses one of three labels:

| Label | Meaning | Allowed interaction |
|---|---|---|
| **Available / SHIP** | Implemented and tested in the hackathon build | Uses live or explicitly selected demo data |
| **Preview / STRETCH** | Designed interaction using deterministic sample content; implemented only after the core is stable | Opens a complete mock screen with a Preview banner |
| **Coming later / DESIGN** | Product direction only | Opens an explanation; never requests permission or shows a fake success state |

There must be no dead buttons, fake connector toggles, or unlabeled sample results.

---

## 2. Core product flow

~~~mermaid
flowchart TD
    H[Health data] --> N[Sanitize and normalize locally]
    C[Calendar and context events] --> N
    M[Manual check-ins] --> N
    N --> T[Private canonical timeline]
    T --> W[Build health windows around events]
    W --> A[Calculate summaries and matched comparisons]
    A --> G[Check repetition, completeness, and possible influences]
    G --> E[Verified evidence bundle]
    E --> X[MedGemma explains the supported finding]
    X --> V[Deterministic output check]
    V --> I[Daily insight]
~~~

The analytical engine calculates the pattern. MedGemma does not calculate correlations, query the raw database, or decide medical truth.

### 2.1 Daily run, rolling history

“Daily” describes when the pipeline runs. It does not mean the app judges one day in isolation.

Each run:

1. Imports records added since the last successful sync.
2. Sanitizes contextual events and discards content or identity that is unnecessary.
3. Updates the local timeline.
4. Rebuilds only the event windows affected by new or changed records.
5. Recalculates the rolling 30-day analysis.
6. Runs the two reviewed analyses.
7. Lets MedGemma propose a permitted investigation from the same bounded analytical catalogue.
8. Promotes only repeatable findings with sufficient data.
9. Generates or updates the daily explanation.
10. Marks dependent findings stale if a source is revoked or deleted.

The architecture may later support 14-, 30-, or 45-day windows. The hackathon uses one fixed 30-day window to avoid unnecessary settings and branching.

---

## 3. Data sources and ingestion

### 3.1 Essential sources

| Source | Android | iOS | What is retained |
|---|---|---|---|
| Health | Health Connect | HealthKit | Sleep, heart rate, HRV when available, activity/steps, workouts required by the demo |
| Calendar | Calendar Provider | EventKit | Event category, start, end, recurrence; raw title discarded after local categorization |
| Manual Check-ins | Flutter UI | Flutter UI | User-selected caffeine, exercise, illness, mood, or custom note category |
| Demo Data | Bundled fictional timeline | Bundled fictional timeline | Reproducible judge and development scenario, visibly labelled |

### 3.2 Future source rule

Every future connector must reduce its input to privacy-safe event metadata before entering analysis.

Examples:

- a call becomes a communication session with timing and duration, not a phone number;
- Discord or WhatsApp becomes late social activity with timing and duration, not message content or identity;
- Spotify becomes a media session or listening category, not an unrestricted listening history;
- Strava becomes a route-free workout event unless the user explicitly enables more detail.

### 3.3 Ingestion path

~~~mermaid
flowchart LR
    S[Enabled source] --> P[Platform permission]
    P --> R[Bounded incremental read]
    R --> Q[Remove unnecessary identity and content]
    Q --> Z[Normalize units, time zone, and category]
    Z --> D[Deduplicate]
    D --> L[Encrypted local timeline]
    L --> B[Daily analysis job]
~~~

Core ingestion rules:

- ask for only the fields needed by the working analyses;
- read a bounded history rather than an unlimited archive;
- retain source and sync provenance;
- make partial permissions visible;
- treat pause, disconnect, and delete as different actions;
- never mix Demo Data with live data without an obvious mode label.

---

## 4. Analytical generation

### 4.1 Event slicing

For a meeting from 11:00 to 11:30, the analytical engine can create:

- 10:45–11:00: pre-event physiology;
- 11:00–11:30: during-event physiology;
- 11:30–11:45: recovery;
- similar no-meeting windows: personal comparison periods.

The same mechanism can later support calls, workouts, late social activity, commutes, meals, and sleep-related contexts.

### 4.2 What deterministic code calculates

- median and range of the health signal;
- change from the user’s personal baseline;
- event and comparison-window counts;
- consistency across repeated events;
- data completeness;
- activity, illness, caffeine, or other possible influences;
- whether the finding passes the minimum evidence gate;
- source and time provenance for every displayed number.

These calculations happen before MedGemma receives anything.

### 4.3 Working analysis A: recurring meeting → heart rate

Minimum evidence for the demo:

- at least four recurring meeting windows;
- comparable no-meeting windows at a similar time of day;
- active workout windows excluded;
- visible repeat count and effect range;
- missing caffeine or illness data shown as unresolved;
- careful language such as “usually higher before recurring meetings.”

### 4.4 Working analysis B: late digital activity → sleep

For the hackathon, this uses deterministic Demo Data unless Android screen-time ingestion is stable after the core is complete.

The analysis compares:

- late digital-activity duration in the two hours before sleep;
- sleep start and total sleep duration;
- repeated late-use nights against similar lower-use nights;
- exercise, illness, travel, and missing data.

The result may say:

> “Your sleep was 48 minutes shorter after six late digital-activity sessions.”

It must not say:

> “Discord is unhealthy for you.”

### 4.5 Promotion gate

A finding becomes a daily insight only when:

- the minimum number of repeated windows exists;
- the difference is large enough to be useful;
- direction is reasonably consistent;
- data completeness is acceptable;
- major known influences are excluded or clearly marked unresolved;
- every number can be traced to the local evidence.

Otherwise, Today shows “developing pattern,” “no repeatable association yet,” or “insufficient data.”

---

## 5. MedGemma, model improvement, and output safety

### 5.1 Exact role of MedGemma

MedGemma has two bounded jobs:

| Role | What MedGemma does | What it does not do |
|---|---|---|
| **Explorer** | Reviews compact daily summaries and chooses a question from a small approved investigation catalogue, such as meeting timing versus pre-event heart rate | Does not access raw health history, generate database queries, invent new calculations, or promote a result |
| **Explainer** | Converts verified evidence into clear language, states uncertainty, mentions unresolved influences, and suggests a low-risk next observation | Does not diagnose, prescribe, label something healthy/unhealthy, or change analytical thresholds |

Both roles use bounded summaries. The local analytical engine performs every calculation and decides whether enough evidence exists.

### 5.2 Two analysis lanes

~~~mermaid
flowchart TD
    D[Two reviewed analyses] --> A[Deterministic analytical engine]
    S[Compact daily summary] --> M[MedGemma Explorer]
    M --> Q[Approved investigation choice]
    Q --> A
    A --> E[Verified evidence]
    E --> P[MedGemma Explainer]
    P --> C[Deterministic wording and number check]
    C --> U[User-facing insight]
~~~

The reviewed lane guarantees a reliable demo. The Explorer lane demonstrates dynamic investigation without giving the model unrestricted control.

### 5.3 What MedGemma receives

Only compact, privacy-safe evidence such as:

- event category;
- time window;
- occurrence and comparison counts;
- summary differences and ranges;
- consistency;
- excluded and unresolved influences;
- data completeness;
- permitted wording and low-risk next steps.

It does not receive calendar titles, contact identities, message text, phone numbers, arbitrary raw records, or the complete timeline.

### 5.4 Model improvement during the hackathon

Do not attempt reinforcement learning or MedGemma weight training this week.

Improve quality through a small build-time evaluation loop:

1. Create fictional evidence examples covering normal, missing-data, contradictory, and safety cases.
2. Ask MedGemma to investigate or explain them.
3. Check unsupported numbers, causal overstatement, diagnosis, treatment advice, missing uncertainty, and clarity.
4. Improve prompts, permitted investigation choices, and the deterministic output checker.
5. Rerun the same fictional evaluation set and preserve results in the repository.

Actual fine-tuning or preference optimization remains a future design item and is not part of the hackathon claim.

### 5.5 Runtime fallback

Use this order:

1. Phone-local MedGemma if the measured runtime is stable.
2. Clearly labelled local-development-machine MedGemma using only Demo Data if phone inference is not viable.
3. Deterministic evidence summary if no MedGemma runtime is reliable.

Never silently substitute another model or imply phone-local inference when it is not running on the phone.

---

## 6. Exact role of GPT-5.6 and Codex

GPT-5.6 is a **build-time engineering and synthetic evaluation tool**. It is not part of the mobile inference pipeline.

### GPT-5.6 is used to

1. Turn generic, non-personal health hypotheses into analytical test plans for the two working patterns.
2. Generate fictional health and context timelines with expected outcomes.
3. Create adversarial cases: duplicates, time-zone changes, missing values, misleading influences, unsupported model numbers, causal overreach, diagnosis requests, and prompt injection.
4. Evaluate MedGemma responses on fictional evidence using a fixed grounding and safety rubric.
5. Help Codex implement, debug, test, and document the Flutter, Kotlin, Swift, and Python work.

### GPT-5.6 never receives

- real health values;
- real calendar events;
- contacts or communication records;
- personal evidence or insights;
- production database exports;
- user conversations.

### GPT-5.6 never ships in the app

The mobile release contains no OpenAI key, OpenAI SDK, GPT endpoint, or runtime GPT request path.

### Judge-visible proof

Show one short sequence:

1. a fictional edge case created with GPT-5.6;
2. a failing analytical or MedGemma-output test;
3. the Codex-assisted fix;
4. the passing test;
5. the primary Codex feedback session ID.

This proves meaningful GPT-5.6 and Codex usage without sending personal data.

---

## 7. Minimal privacy and trust requirements

Keep this section intentionally small. These are the only non-negotiable guarantees for the hackathon:

1. **Local personal data:** health, context, analysis, and MedGemma runtime inputs stay on the user’s device.
2. **Minimum context:** content and identity are discarded before contextual events reach the timeline.
3. **Explicit source choice:** each source is independently enabled, paused, disconnected, or deleted.
4. **Evidence before language:** deterministic analytics establish the numbers; MedGemma only investigates permitted questions and explains verified results.
5. **No diagnosis or healthy/unhealthy verdict:** the app reports personal deviations, repeated associations, uncertainty, and missing data.
6. **Traceability:** every visible number opens the evidence that produced it.
7. **Honest runtime labels:** the UI identifies Demo Data, live data, phone-local inference, fallback generation, and Preview screens.

This is a wellness insight product, not a diagnostic device. Clinical alerting would require a separate reviewed safety-rule system and is outside the hackathon scope.

---

## 8. App UI: complete vision with honest mockups

### 8.1 Navigation

Use five destinations:

1. **Today** — daily insight and data-readiness state.
2. **Timeline** — health and context events; working event-window view.
3. **Insights** — current, developing, and past patterns.
4. **Sources** — enabled essentials and future connector catalogue.
5. **More** — Preview Lab, Privacy, runtime status, and Demo Mode.

### 8.2 Surface plan

| Surface | Hackathon state | What the user sees |
|---|---|---|
| Onboarding | Available | Privacy promise, Live or Demo choice, individual Health and Calendar setup |
| Today | Available | One daily insight, evidence readiness, sync/runtime status |
| Timeline | Available | Health and event rows with filters and source provenance |
| Event Window | Available | Before/during/after summary and personal comparison |
| Insight Detail | Available | Explanation, evidence, missing data, possible influences |
| Sources | Available | Health, Calendar, Manual Check-ins, Demo Data; pause/disconnect/delete |
| Connector Catalogue | Preview / Coming later | Spotify, Strava, phone sessions, Discord, WhatsApp, screen time, rings, environment |
| Ask Vueniverse | Preview | Evidence-scoped conversation mock with sample questions and cited evidence chips |
| Test This | Preview | Three-day personal experiment setup and sample result |
| Timeline Replay | Preview | Animated event-window concept using deterministic sample data |
| Influence Radar editor | Preview | Add caffeine, exercise, illness, or travel and preview how evidence may change |
| Weekly Digest | Preview | Strongest pattern, negative finding, missing-data request |
| Quiet Intelligence | Preview | Notification timing and tone controls |
| Adaptive presentation | Preview | Model-personalization controls for timing and detail, with a clear “not active yet” message |
| Signal agreement | Coming later | Cross-metric agreement concept for HR, HRV, activity, and sleep |
| What-if Lab | Coming later | Observational scenario explanation with strong limitation copy |
| Privacy & Data | Available | Per-source state, local-data explanation, deletion, Live/Demo and model-runtime status |
| Proof / Export | Preview | Data sources, model/runtime, evidence provenance, export concept |
| Health Records & Clinician Export | Coming later | FHIR import and reviewed shareable report concept |
| Multimodal Journal | Coming later | Photo/voice-assisted meal, symptom, and context capture concept |
| Smart Environment | Coming later | Bedroom, air quality, light, temperature, and home-context concept |
| Shared Analysis Packs | Coming later | Reviewed future analysis packs without showing them as installed |
| Model Adaptation | Coming later | Future MedGemma improvement explanation; no training controls or claims |
| Personal Digital Twin | Coming later | Product vision explanation only |

### 8.3 Today mockup

~~~text
┌──────────────────────────────────────────┐
│ Vueniverse                         Live ●  │
│ Good evening                             │
├──────────────────────────────────────────┤
│ TODAY'S PATTERN                          │
│ Your heart rate was usually higher       │
│ before your recurring 1:1.               │
│                                          │
│ +8–12 bpm · 6 of 8 meetings              │
│ Exercise unlikely · caffeine unresolved  │
│                                          │
│ [See evidence]              [Why this?]   │
├──────────────────────────────────────────┤
│ Data ready: Health ✓  Calendar ✓         │
│ Last analysis: 8:10 PM · 30-day window   │
└──────────────────────────────────────────┘
~~~

For the hackathon, **Why this?** can open the Ask Vueniverse Preview. It must be labelled Preview unless the evidence-scoped conversation is actually completed and tested.

### 8.4 Feature gallery mockup

~~~text
Preview Lab

[Preview] Ask Vueniverse
Ask follow-up questions grounded in one insight.

[Preview] Test This
Turn a repeated association into a personal experiment.

[Preview] Timeline Replay
Watch physiology change around repeated events.

[Coming later] What-if Lab
Explore a bounded observational scenario.

[Coming later] Personal Digital Twin
See the long-term Health OS direction.
~~~

Build previews with one reusable Flutter template so keeping the full UI vision does not consume the implementation week.

---

## 9. Recommended stack

| Layer | Choice | Purpose |
|---|---|---|
| Cross-platform app | Flutter + Dart | UI, navigation, state, timeline, analytics, evidence, previews, and most tests |
| Android edge | Kotlin | Health Connect, Calendar Provider, permissions, background work, secure key access |
| iOS edge | Swift | HealthKit, EventKit, permissions, background work, secure key access |
| Native bridge | Pigeon-generated platform channels | Typed Flutter-to-native calls |
| Local storage | Drift + encrypted SQLite/SQLCipher | Timeline, sync state, event windows, evidence, and deletion |
| State management | Riverpod | Source state, daily job, analysis, runtime, and Demo Mode |
| Local inference | Proven mobile MedGemma runtime selected by the Day-1 spike | Explorer and explanation generation |
| Build-time evaluation | Python + OpenAI API | Synthetic GPT-5.6 generation and MedGemma evaluation only |
| Tests | Flutter test, native unit tests, Python tests | Analytics, mappings, permissions, privacy boundary, output guard, and seed flow |

Avoid adding a cloud backend, vector database, remote analytics service, custom reinforcement-learning service, or multiple state-management frameworks.

---

## 10. Seven-day implementation plan

### Day 1 — Freeze scope and make the entire UI navigable

**Builder A**

- Build Flutter navigation and reusable Available / Preview / Coming later components.
- Implement Today, Timeline, Insights, Sources, and More shells.
- Create all preview screens from Section 8 using deterministic sample content.

**Builder B**

- Create the fictional 30-day timeline and expected results for both demo analyses.
- Complete Android/iOS native project checks.
- Run the MedGemma phone-runtime spike and record the honest fallback decision.

**GPT-5.6 + Codex**

- Generate fictional normal and adversarial histories.
- Scaffold analytical tests and record decisions in the build log.

**Done:** both phones navigate through the full Health OS vision; every screen has an honest state label; the core seed story is visible.

### Day 2 — Essential sources and encrypted local timeline

**Builder A**

- Implement Android Health Connect and Calendar permission/read paths.
- Build shared source consent, sync, partial-access, pause, disconnect, and delete UI.

**Builder B**

- Implement iOS HealthKit and EventKit equivalents.
- Add local storage, normalization, deduplication, provenance, and incremental sync.

**Done:** at least one live health and one live calendar record appear in the same Flutter timeline on both platforms.

### Day 3 — Daily rolling pipeline and event windows

- Implement sync cursor and daily/foreground analysis trigger.
- Use a fixed rolling 30-day window.
- Build before/during/after health slices around calendar events.
- Create matched no-event windows.
- Recompute only affected windows.
- Test time zones, duplicates, missing samples, source revocation, and Demo/Live separation.

**Done:** selecting a meeting opens its event window and comparison summary without an LLM.

### Day 4 — Deterministic evidence generation

- Implement the recurring meeting → pre-event heart-rate analysis.
- Implement late digital activity → sleep from Demo Data.
- Calculate repetitions, effect range, consistency, completeness, exclusions, and possible influences.
- Build Insight Detail and evidence drill-down.
- Show insufficient-data and no-repeatable-association states.

**Done:** the app can produce or reject both findings with MedGemma disabled.

### Day 5 — MedGemma Explorer and Explainer

- Give Explorer a small approved investigation catalogue.
- Pass only compact daily summaries to Explorer.
- Execute Explorer’s choice with deterministic analytics.
- Pass verified evidence to the Explainer.
- Validate every number and block diagnosis, prescription, healthy/unhealthy labels, and causal overstatement.
- Run the fictional GPT-5.6 evaluation set and improve prompts/checks.

**Done:** one verified finding becomes a careful MedGemma explanation; a hostile or unsupported response falls back to the deterministic summary.

### Day 6 — Integrate, polish previews, and harden the demo

- Connect Today, Timeline, Event Window, Insight Detail, and Sources end-to-end.
- Add visible Live/Demo, sync, model-runtime, and Preview labels.
- Polish the reusable preview template for every future feature.
- Test denied permissions, offline mode, model failure, partial data, deletion, relaunch, and slow devices.
- Finish README, setup steps, sample data, architecture image, GPT-5.6/Codex build log, and third-party notices.

**Done:** the core works from live or seed data; every other planned feature is discoverable as a polished mockup.

### Day 7 — Rehearse and submit

- Run clean Android and iOS installs.
- Complete three uninterrupted demo rehearsals.
- Record the under-three-minute public video.
- Show Codex and GPT-5.6 usage clearly.
- Capture the primary feedback session ID.
- Submit at least two hours before the deadline.

---

## 11. Three-minute demo

| Time | Demo action | Judge takeaway |
|---|---|---|
| 0:00–0:20 | Open Today on “Your heart rate was usually higher before your recurring 1:1.” | Immediate human value |
| 0:20–0:38 | Flash Sources: Health and Calendar independently enabled; data stays local | Real ingestion and consent |
| 0:38–1:00 | Open Timeline and the meeting’s before/during/after event window | Refined architecture is visible |
| 1:00–1:25 | Show repetitions, matched periods, effect range, exclusions, and unresolved caffeine | Evidence before AI |
| 1:25–1:50 | Show MedGemma’s careful explanation and the output check | Medical model has a bounded role |
| 1:50–2:08 | Show “not healthy/unhealthy” language and deterministic fallback | Trust and honesty |
| 2:08–2:25 | Flash Preview Lab with Ask, Experiment, Replay, connectors, and future vision | Full Health OS remains visible |
| 2:25–2:48 | Show the fictional GPT-5.6 edge case and Codex failing-to-passing test | Meaningful Build Week usage |
| 2:48–3:00 | Show Android + iOS and close | Working cross-platform product |

**Closing line:**

> “Vueniverse does not ask an AI to guess from raw health data. It aligns your health with the moments around it, verifies the pattern locally, and uses MedGemma to explain what the evidence actually supports.”

---

## 12. Final cut rules

If time is short, preserve work in this order:

1. Demo Data end-to-end flow.
2. Meeting → heart-rate event windows and evidence.
3. One live health and calendar source on each platform.
4. MedGemma explanation or honest deterministic fallback.
5. MedGemma Explorer over the approved investigation catalogue.
6. GPT-5.6 synthetic edge case and Codex test proof.
7. Polished preview screens.
8. Anything else.

Cut first:

- live screen-time ingestion;
- Ask Vueniverse implementation;
- experiments;
- animated Replay;
- editable Influence Radar;
- notifications;
- local reinforcement learning;
- fine-tuning;
- additional connectors.

### Hackathon definition of done

- Android and iOS run the same Flutter UI.
- Health and Calendar are independently consented.
- A daily rolling analysis creates event-aligned health windows.
- Deterministic analytics produce one inspectable repeated association.
- MedGemma investigates only permitted questions and explains only verified evidence.
- No output declares a user or context healthy/unhealthy.
- GPT-5.6 is proven as a synthetic build-time tool with no personal-data path.
- Every non-core feature remains visible as Preview or Coming later.
- The full demo succeeds three consecutive times.

This focused plan replaces the previous assumption that every novel feature must be implemented. The full Health OS remains visible; only the evidence-to-explanation loop must be real.
