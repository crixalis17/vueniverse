# First-person Android milestone: Ultrahuman + manual check-ins

Target: the owner's Nothing Phone (2), reported 8 GB RAM. This is a supervised
personal prototype, not a clinical product or public-release claim. Real canonical
input starts with manual check-ins only. No Calendar, Discord, Spotify, calls or
screen permissions are required for this milestone.

**October 5 scope update:** the immediate deliverable is an emulator-verified
prototype. Use [EMULATOR-PROTOTYPE-MILESTONE.md](EMULATOR-PROTOTYPE-MILESTONE.md)
for its predeclared collection and separate model-semantic gates. The physical
procedures in this runbook remain reference-only until explicitly authorized;
phone acceptance is deferred, not deleted. An emulator collection pass cannot
substitute for a useful MedGemma answer or establish phone performance.

## Current state and exact model

The retained LoRA v7 candidate is **not yet the active Android pin**. Its manifest
is [phone-lora-v7-candidate-v1.json](../../experiments/readiness/phone-lora-v7-candidate-v1.json).
The exact candidate is MedGemma 1.5 4B, BF16-trained LoRA v7 merged into the base,
then quantized to Q4_K_M:

| Property | Candidate |
|---|---|
| Filename | `medgemma-1.5-4b-it-lora-v7-Q4_K_M.gguf` |
| Size | 2,489,893,568 bytes |
| SHA-256 | `dd9c2a212672a5bb18affbc344a4c0fcf4e9000b3b5155d6fdfe9a8104bad234` |
| Revision identity | `lora-v7-q4-dd9c2a212672a5bb` |
| Private bucket generation | `1789740897785051` |

Bucket metadata was read on 2026-10-03 without starting a VM or downloading the
large model. Size/generation are freshly verified metadata; the SHA comes from
retained deployment evidence and must be verified again after downloading.
The old active vanilla file is 2,489,894,976 bytes with SHA beginning `b31becdf`:
it is **not interchangeable**, despite nearly identical size and architecture.

## Activation gates before any phone install

1. Confirm one authorized physical serial, `arm64-v8a`, Android version, available
   storage and real reported RAM. No phone was attached at the Oct 3 preparation
   check. An emulator is not evidence of phone performance.
2. Use the coordinated selected-artifact configuration across native validation,
   download API/worker/files, benchmark and runtime metadata. Preserve the old
   vanilla filename for rollback. Download URL must point to the selected bytes;
   a LoRA pin paired with a vanilla URL must fail closed.
   The default is `vanilla`; explicit `-PVUENIVERSE_MODEL_VARIANT=lora-v7` selects
   the candidate. Unknown variants are rejected. A build selection is not a
   validation or public-rollout approval.
3. Download work and verification markers are scoped by candidate revision. Prevent
   old vanilla accepted explanations from satisfying a LoRA cache read; include
   artifact identity alongside evidence/request/guard/prompt versions. Keep
   historical explanations as history rather than deleting them.
   When the download API is used after upgrade/selection change, only unfinished
   jobs with this model module's tag and no matching artifact tag are canceled.
   Old queued workers also fail closed before touching files. This migration
   preserves partial/verified files and does not start a new download by itself.
4. Validate the actual Android prompt. Archived CUDA benchmarking used a snake-case
   output schema and an authoritative assistant JSON prefix. Android's old v5
   camel-case request/encoded-paragraph contract was not equivalent. The explicit
   LoRA bridge preserves trained JSON shapes, exact app citation IDs and approved
   observation lookup; phone contract v7 also constrains generation with bounded
   request-specific GBNF. Phone prompt v8 additionally preserves exact promotion
   gates, influence descriptions and exclusion categories. Vanilla retains its old
   parser. Current `explainer-v8` and Dart guard v7 version requests/acceptance and
   prevent older answers from satisfying the cache. The one adapted prompt-v8
   fixture was manually rejected; compatibility must be measured separately.
   Identical weights do not guarantee it.
5. Build/test the ARM64 app, then explicitly authorize install/staging. The
   updated `run_physical_benchmark.sh` accepts an explicit candidate variant and
   manifest; omitting them still selects vanilla. Do not substitute LoRA under
   the vanilla filename. The script verifies bytes before install and preserves
   the Live store, but its native synthetic benchmark alone is not the owner
   acceptance flow.

For representative native throughput, use the explicit
`-PVUENIVERSE_NATIVE_OPTIMIZATION=release-style` build flag. This applies `-O3`
without fast-math or weakening APK/debug/security settings; default debug native
builds are unoptimized and timed out in the initial emulator contract run.
`VUENIVERSE_CONTRACT_DIAGNOSTICS` defaults to `off`; its text-free diagnostic mode
is restricted to a Debug build of the exact disposable contract-test entry point.
Never distribute or restore that fixture APK as the owner's application.

## Safe host retrieval and staging reference

These are reference commands, **not executed during preparation**. Run from the
repo only after the activation gates and phone-install authorization. Keep the
model outside Git. Download uses existing owner credentials; do not make the
bucket public, embed credentials in an APK, or commit a signed URL.

The October 4 emulator preparation downloaded and independently verified a host
copy; reuse the ignored `tooling/medgemma/outputs/phone-models/` cache when present,
checking the exact bytes/hash again rather than redownloading. The download below
is a recovery reference, not an instruction to repeat completed transfers.

```sh
mkdir -p models
CLOUDSDK_STORAGE_USE_GCLOUD_CRC32C=false CLOUDSDK_STORAGE_CHECK_HASHES=always \
  gcloud storage cp 'gs://vueniverse-508413-medgemma-training/resurrection/20260918-lora-v7-final/workspace/deployment/medgemma-1.5-4b-it-lora-v7-Q4_K_M.gguf#1789740897785051' models/medgemma-1.5-4b-it-lora-v7-Q4_K_M.gguf
wc -c models/medgemma-1.5-4b-it-lora-v7-Q4_K_M.gguf
shasum -a 256 models/medgemma-1.5-4b-it-lora-v7-Q4_K_M.gguf
```

Stop unless both match the table above. Downloading can consume local disk and
cloud egress; it needs no GPU. Staging plus final private copy requires about
5 GB before app/build overhead; keep at least 6 GB free. File size is not process
RAM: KV cache, native buffers and Flutter also use memory. 8 GB device RAM is a
reasonable test target, not a guarantee of throughput or thermal behavior.

The command-scoped CRC settings avoid executing the macOS-blocked SDK helper;
they retain integrity checks through the alternate checksum implementation, which
can be slower. Do not remove quarantine, approve an unverified executable, or set
`check_hashes=never` to make a download appear successful. See the installed SDK
behavior and [Google's storage properties](https://docs.cloud.google.com/sdk/gcloud/reference/topic/configurations#storage).

```sh
source tooling/android/env.sh
adb devices -l
PHONE_SERIAL=REPLACE_WITH_EXACT_AUTHORIZED_PHYSICAL_SERIAL
adb -s "$PHONE_SERIAL" shell getprop ro.product.model
adb -s "$PHONE_SERIAL" shell getprop ro.product.cpu.abi
adb -s "$PHONE_SERIAL" shell getprop ro.build.version.sdk
adb -s "$PHONE_SERIAL" shell df -h /data
adb -s "$PHONE_SERIAL" shell cat /proc/meminfo
```

After a coordinated candidate build is approved, use `install -r`, not uninstall
or `pm clear`. Stage the candidate to `/data/local/tmp/` then copy under `run-as`
into `files/medgemma-models/` with its **candidate filename**. Force-stop first;
verify the private copy size/hash; only then remove that exact temporary copy.
Never clear the Live store merely to reset a model cache.

For an explicitly approved supervised benchmark run, the candidate invocation is:

```sh
PHONE_PYTHON=.venv/bin/python tooling/medgemma/scripts/run_physical_benchmark.sh \
  models/medgemma-1.5-4b-it-lora-v7-Q4_K_M.gguf \
  tooling/medgemma/reports/generated/nothing-phone-2-lora-v7-runtime-report.json \
  lora-v7 experiments/readiness/phone-lora-v7-candidate-v1.json
```

This command **does install/update the app and stage the model**. Do not run it
as a mere status check. It uses an artifact-specific build property, requires
exactly one authorized ARM64 physical phone, retains the existing app store,
checks the app-private model SHA and records runtime artifacts. It does not
connect Ultrahuman, enable optional permissions, or certify prompt compatibility.
Instrumentation is launched directly after `install -r` of app/test APKs, not
through Gradle's managed connected-test install/uninstall lifecycle. This avoids
an automatic app uninstall that could otherwise erase owner data after testing.

## Owner acceptance flow

### Production-prompt compatibility check (separate from the microbenchmark)

`integration_test/phone_lora_contract_test.dart` builds fixture evidence in a
fresh in-memory database, calls the actual phone runtime through the app's
coordinator and Dart guard, and tests `why_promoted`, `disagreement` and
`observe_next`. Every response must come from the selected LoRA revision with
no cache or deterministic fallback. It never opens the owner's Live database.
This checks one fixture's three intents, not a full independent semantic or
real-user benchmark. A pass does not mark the personal milestone complete.

**Do not use `flutter test -d <phone>` for this owner's app:** the installed
Flutter tooling can uninstall an existing package when its update installation
fails. Likewise, do not use Gradle `connectedDebugAndroidTest`, `adb uninstall`
or `pm clear`. Use explicit `install -r` and stop if it fails, preserving data.

First build and retain the production candidate APK locally, then compile the
test entrypoint and instrumentation APK. These build commands do not touch a
phone. Normal builds deliberately hold the unapproved LoRA candidate; downloaded
and hash-verified bytes do not imply explanation readiness. Never restore a
pre-hold APK. The fixture capability below is not production activation:

```sh
source tooling/android/env.sh
ORG_GRADLE_PROJECT_VUENIVERSE_MODEL_VARIANT=lora-v7 \
ORG_GRADLE_PROJECT_VUENIVERSE_NATIVE_OPTIMIZATION=release-style \
ORG_GRADLE_PROJECT_VUENIVERSE_CANDIDATE_EVALUATION=off \
ORG_GRADLE_PROJECT_VUENIVERSE_CONTRACT_DIAGNOSTICS=off \
  flutter build apk --debug --target-platform android-arm64 --target lib/main.dart
mkdir -p build/phone-contract
cp build/app/outputs/flutter-apk/app-debug.apk build/phone-contract/production-lora-v7-contract8-guard7-fallback6-prototype-freshness-held.apk
ORG_GRADLE_PROJECT_VUENIVERSE_MODEL_VARIANT=lora-v7 \
ORG_GRADLE_PROJECT_VUENIVERSE_NATIVE_OPTIMIZATION=release-style \
ORG_GRADLE_PROJECT_VUENIVERSE_CANDIDATE_EVALUATION=fixture \
ORG_GRADLE_PROJECT_VUENIVERSE_CONTRACT_DIAGNOSTICS=off \
  flutter build apk --debug --target-platform android-arm64 \
  --target integration_test/phone_lora_contract_test.dart
cp build/app/outputs/flutter-apk/app-debug.apk build/phone-contract/contract-lora-v7.apk
android/gradlew -p android :app:assembleDebugAndroidTest \
  -PVUENIVERSE_MODEL_VARIANT=lora-v7 \
  -PVUENIVERSE_NATIVE_OPTIMIZATION=release-style \
  -PVUENIVERSE_CANDIDATE_EVALUATION=fixture \
  -PVUENIVERSE_CONTRACT_DIAGNOSTICS=off \
  -Ptarget=integration_test/phone_lora_contract_test.dart
```

Only after explicit phone-install approval, a confirmed serial and staged
candidate size/SHA verification, run the following **mutating** commands. Stop
at any failure; never replace a failed update with an uninstall:

```sh
adb -s "$PHONE_SERIAL" shell am force-stop com.vueniverse.vueniverse
adb -s "$PHONE_SERIAL" install -r build/phone-contract/contract-lora-v7.apk
adb -s "$PHONE_SERIAL" install -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
adb -s "$PHONE_SERIAL" shell am instrument -w -r \
  -e class com.vueniverse.vueniverse.medgemma.PhoneLoraContractInstrumentationTest \
  -e runPhoneLoraContract true \
  com.vueniverse.vueniverse.test/androidx.test.runner.AndroidJUnitRunner
```

Require `OK (1 test)` from instrumentation and no Dart assertion failures.
The wrapper is skipped unless explicitly enabled; compiling it or running the
native microbenchmark does not execute this gate. The wrapper waits at most
12 minutes for the Dart test's bounded three inference calls; a timeout/fallback
is a failed compatibility check, not proof of completion.

#### Capture fixture-only diagnostics

Before launching instrumentation, open a second terminal and select the same
confirmed phone serial. This command stores **only** lines with the test's
explicit `VUENIVERSE_PHONE_CONTRACT` prefix; do not redirect unfiltered logcat,
collect a bug report, upload owner-wide logs, or clear the device log buffer.

```sh
source tooling/android/env.sh
PHONE_SERIAL=REPLACE_WITH_EXACT_AUTHORIZED_PHYSICAL_SERIAL
mkdir -p build/phone-contract
adb -s "$PHONE_SERIAL" logcat -v raw -T 1 flutter:I '*:S' \
  | rg --line-buffered '^VUENIVERSE_PHONE_CONTRACT_CHUNK ' \
  > build/phone-contract/phone-lora-contract-fixture-only.log
```

Leave capture running while executing the explicit instrumentation command in
the other terminal. Stop capture with Ctrl+C when the test finishes. Each line
contains a bounded ASCII chunk envelope for a bundled in-memory fixture. Group
records by capture_id, intent and kind; require one occurrence of every index
from zero through count minus one, an identical count and SHA-256 on every chunk,
strict base64 decoding, and a matching hash of the reconstructed UTF-8 JSON bytes.
Refuse missing, duplicated, mixed or truncated records; never infer omitted fields.
`model_attempt` records retain parsed DTO fields before the app guard, even if it
rejects them; `app_delivery` records retain timings, acceptance/fallback labels,
guard failures and exact fixture inputs. No raw reasoning/generation is captured.
The test uses no owner metrics or check-ins. A null delivery or fallback must not
be counted as a compatible LoRA answer.

Check that the capture contains this run's three distinct intents and the
expected model revision; `-T 1` can include the last buffered line, so do not
silently combine previous runs or count duplicates. If the test fails before
its first answer, the capture may be empty. The capture is diagnostic evidence,
not a replacement for the instrumentation pass/assertions or a full raw-output
semantic review. Keep the filtered file local; only publish a reviewed,
fixture-only excerpt. Never add a real-user log stream to Git.

Android truncated older long Flutter records at 1,023 characters. Their missing
fields remain unavailable, not null model outputs or implicit passes. The current
fixture-only transport uses 480-byte chunks with ASCII/base64 envelopes below that
limit and a full-record checksum. Host-only input reconstruction cannot recover
old missing generated prose. Invalid-schema outputs still have no parsed DTO and
must remain unreviewable rather than scored. Never broaden this capture to owner
data or log raw thinking to work around missing fields.

After success **or failure**, restore the retained production candidate APK:

```sh
adb -s "$PHONE_SERIAL" shell am force-stop com.vueniverse.vueniverse
adb -s "$PHONE_SERIAL" install -r build/phone-contract/production-lora-v7-contract8-guard7-fallback6-prototype-freshness-held.apk
adb -s "$PHONE_SERIAL" shell am start -n com.vueniverse.vueniverse/.MainActivity
```

Verify the ordinary onboarding opens, existing data remains and the selected
revision is unchanged. The restored main APK must have candidate evaluation and
contract diagnostics **off**, and the unapproved LoRA candidate must remain held.
If restore installation fails, leave files/data intact
and report the failure; do not uninstall. A test-entrypoint APK is not the normal
owner app and must not be left installed as the final milestone deliverable.

### Disposable-emulator checks: immediate collection-prototype gate

`integration_test/first_person_emulator_test.dart` checks the production
onboarding/ledger widgets, mocked Ultrahuman import lifecycle and actual Android
Keystore/SQLCipher isolation. It does **not** establish LoRA phone generation,
real Ultrahuman ingestion, owner-data continuity or physical-device usability.

Run it only on a separately verified **disposable emulator copy**, never the
Nothing Phone or an emulator containing data worth keeping. Real external
provider data remains out of scope: use the existing mocked fixtures, no owner
API key and no private data import. The source fixtures are read-only, but this
suite's local database tests deliberately erase/recreate the emulator's Live
and Demo stores. Its flags are consent gates, not an automatic check that the
target is actually an emulator. Both destructive suites additionally verify Android
and `ro.kernel.qemu=1` before deletion, but that identity check does not establish
that a particular emulator is disposable or contains no useful data.

After verifying the exact `emulator-*` serial, this is the explicit invocation:

```sh
source tooling/android/env.sh
adb devices -l
EMULATOR_SERIAL=REPLACE_WITH_VERIFIED_DISPOSABLE_EMULATOR_SERIAL
[[ "$EMULATOR_SERIAL" == emulator-* ]] || exit 1
adb -s "$EMULATOR_SERIAL" shell getprop ro.product.model
adb -s "$EMULATOR_SERIAL" shell getprop ro.kernel.qemu
flutter test integration_test/first_person_emulator_test.dart \
  -d "$EMULATOR_SERIAL" \
  --dart-define=VUENIVERSE_DISPOSABLE_EMULATOR=true \
  --dart-define=ALLOW_DESTRUCTIVE_STORE_TESTS=true
```

Require the expected suite to actually execute, not merely report a skipped
opt-in test. Omitting the destructive flag skips the encryption/erasure tests;
passing both flags to the owner's phone would be unsafe. Flutter's managed
installation lifecycle is acceptable only for this explicitly disposable copy.
Record an emulator pass against the exact executed collection scope in the
emulator checklist, not completion of the first-person physical-phone milestone.
It also does not complete the separate model-enabled prototype gate. The candidate
remains held because retained generated output failed manual semantic review;
a correct fallback is not a passing LoRA answer. The ordinary production bootstrap
is a separate check from this integration suite, and any mock-input accommodation
must remain explicit rather than counted as real-keyboard acceptance.

### Real owner data and everyday use

- Enter **Use my own data**, read the data boundary, connect/import Ultrahuman
  and inspect last successful sync, imported metrics, period and rejected/missing
  rows. API secrets must not appear in logs, reports or saved prompts.
- Add a manual check-in; review/edit/delete it and confirm
  the activity/data ledger reflects the change. Unknown caffeine or missing
  coverage must stay unknown, not become an assumed zero.
  Non-caffeine entries record when you save; editing preserves that report time.
  They do not capture an exact historical event/exposure start. Caffeine's explicit
  coverage interval is separate; do not interpret a report timestamp as that interval.
- Observe health summaries and explicitly uncertain explanations using only
  available evidence. Sparse owner data may legitimately yield no supported
  finding; that is not a failed onboarding.
- Do not manufacture meetings to claim a real association. Any future generated
  canonical events attached to real metric shapes belong in a separately marked
  development dataset, never the owner's Live store or a real-data validation.
- Test airplane mode, app restart, model cancellation, pending-data refresh,
  duplicate sync, consent withdrawal, and source/check-in deletion. No server
  inference or optional permission should be required for this flow.
- Collect timing/memory/thermal summaries and raw-vs-fallback labels for a small
  set of exact app projections. Restrict identifiable raw records to private
  local storage or an explicitly approved private export.

Do not mark the deferred physical milestone complete until the owner completes
this actual phone flow and the evidence records exact artifact/app versions and
unresolved limits. Immediate emulator collection and model-enabled acceptance
must instead be reported separately under the emulator checklist.
The archived L4 mean 2.62-second result is **not** a Nothing Phone benchmark.

## Rollback without losing data

Stop active generation and restore the previous validated artifact selector,
runtime metadata and cache identity. Keep the vanilla and LoRA files separately;
revalidate whichever is selected. Retain health metrics, check-ins, ledger and
historical explanations. Distinguish old responses by their recorded model;
never show them as newly generated LoRA results. If the model is unavailable,
use clearly labeled deterministic explanations only when the current evidence
passes the guard. Model rollback must not reset consent or the Live database.

## After this milestone

After emulator acceptance, proceed to the deferred, explicitly authorized phone
phase; emulator results alone do not authorize owner-data import or candidate activation.

Collect natural owner data before another iteration. Review coverage, rejected
rows, missing context, unsupported findings, correction/deletion behavior,
explanation grounding and usability before deciding whether an ingestion,
analysis, prompt, model or UI change is needed. Synthetic development cases are
useful stress tests but cannot establish that a real check-in caused a metric
change. Independent evaluation and public-release gates remain separate.
