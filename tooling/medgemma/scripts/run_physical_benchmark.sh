#!/usr/bin/env bash
set -euo pipefail

MODEL_PATH="${1:-}"
REPORT_PATH="${2:-tooling/medgemma/reports/generated/physical-runtime-report.json}"
VARIANT="${3:-vanilla}"
MANIFEST="${4:-}"
if [[ -z "$MODEL_PATH" || ! -f "$MODEL_PATH" ]]; then
  echo "Usage: $0 /absolute/path/model.gguf [report.json] [vanilla|lora-v7] [candidate-manifest.json]" >&2
  exit 2
fi

PHONE_PYTHON="${PHONE_PYTHON:-python3}"
PIN_ARGS=("$MODEL_PATH" --variant "$VARIANT")
[[ -z "$MANIFEST" ]] || PIN_ARGS+=(--manifest "$MANIFEST")
PIN=$(PYTHONPATH=tooling/medgemma/src "$PHONE_PYTHON" -m vueniverse_medgemma.phone_artifact "${PIN_ARGS[@]}")
IFS=$'\t' read -r MODEL_FILENAME EXPECTED_BYTES EXPECTED_SHA256 <<< "$PIN"

# This script installs/updates the app and stages large bytes. The caller must
# explicitly approve those phone mutations; it never runs during preparation.
source tooling/android/env.sh

SERIAL=$(adb devices -l | awk '$2 == "device" && $1 !~ /^emulator-/ {print $1}')
[[ $(printf '%s\n' "$SERIAL" | sed '/^$/d' | wc -l | tr -d ' ') == 1 ]] || {
  echo "Connect exactly one authorized physical Android phone." >&2
  exit 4
}
ABI=$(adb -s "$SERIAL" shell getprop ro.product.cpu.abi | tr -d '\r')
[[ "$ABI" == "arm64-v8a" ]] || {
  echo "MG-12 requires arm64-v8a; detected $ABI." >&2
  exit 4
}
AVAILABLE_KB=$(adb -s "$SERIAL" shell df -Pk /data | awk 'NR == 2 {print $4}' | tr -d '\r')
[[ "$AVAILABLE_KB" =~ ^[0-9]+$ ]] && (( AVAILABLE_KB * 1024 >= EXPECTED_BYTES * 2 + 536870912 )) || {
  echo "Insufficient or unknown phone storage for staged and private copies; no install started." >&2
  exit 4
}

ORG_GRADLE_PROJECT_VUENIVERSE_MODEL_VARIANT="$VARIANT" flutter build apk --debug --target-platform android-arm64
android/gradlew -p android :app:assembleDebugAndroidTest \
  -PVUENIVERSE_MODEL_VARIANT="$VARIANT"
TEST_APK=build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
[[ -f "$TEST_APK" ]] || {
  echo "Expected instrumentation APK missing; no phone install started." >&2
  exit 5
}
adb -s "$SERIAL" install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s "$SERIAL" install -r "$TEST_APK"
adb -s "$SERIAL" shell am force-stop com.vueniverse.vueniverse
adb -s "$SERIAL" push "$MODEL_PATH" "/data/local/tmp/$MODEL_FILENAME"
adb -s "$SERIAL" shell run-as com.vueniverse.vueniverse mkdir -p files/medgemma-models
adb -s "$SERIAL" shell run-as com.vueniverse.vueniverse cp \
  "/data/local/tmp/$MODEL_FILENAME" \
  "files/medgemma-models/$MODEL_FILENAME"
PRIVATE_SHA=$(adb -s "$SERIAL" shell run-as com.vueniverse.vueniverse sha256sum "files/medgemma-models/$MODEL_FILENAME" | awk '{print $1}')
PRIVATE_BYTES=$(adb -s "$SERIAL" shell run-as com.vueniverse.vueniverse stat -c %s "files/medgemma-models/$MODEL_FILENAME" | tr -d '\r')
[[ "$PRIVATE_SHA" == "$EXPECTED_SHA256" && "$PRIVATE_BYTES" == "$EXPECTED_BYTES" ]] || {
  echo "Private model copy SHA mismatch; retained for inspection, benchmark not started." >&2
  exit 3
}
adb -s "$SERIAL" shell rm "/data/local/tmp/$MODEL_FILENAME"

mkdir -p "$(dirname "$REPORT_PATH")"
# Run directly, not connectedDebugAndroidTest: managed test install/uninstall
# lifecycles must not remove the owner's app or its Live data after a benchmark.
adb -s "$SERIAL" shell am instrument -w -r \
  -e class com.vueniverse.vueniverse.medgemma.MedGemmaPhysicalBenchmarkTest \
  -e requirePhysicalBenchmark true \
  com.vueniverse.vueniverse.test/androidx.test.runner.AndroidJUnitRunner \
  | tee "$REPORT_PATH.instrumentation.log"
rg -q '^OK \([1-9][0-9]* tests?\)' "$REPORT_PATH.instrumentation.log" || {
  echo "Physical benchmark did not pass; no previous report will be scored." >&2
  exit 5
}
adb -s "$SERIAL" shell run-as com.vueniverse.vueniverse \
  cat files/medgemma-benchmark/runtime-report.json > "$REPORT_PATH"

PYTHONPATH=tooling/medgemma/src "$PHONE_PYTHON" -c \
  'from vueniverse_medgemma.cli import main; main()' runtime-score "$REPORT_PATH"
echo "MG-12 report: $REPORT_PATH"
