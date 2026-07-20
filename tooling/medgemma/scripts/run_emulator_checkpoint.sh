#!/usr/bin/env bash
set -euo pipefail

MODEL_PATH="${1:-}"
if [[ -z "$MODEL_PATH" || ! -f "$MODEL_PATH" ]]; then
  echo "Usage: $0 /absolute/path/medgemma-1.5-4b-it-Q4_K_M.gguf" >&2
  exit 2
fi

EXPECTED_BYTES=2489894976
EXPECTED_SHA256=b31becdf4f39561800505514cce67681604fe449d04dd35c8c92fd7848c6d7bd
ACTUAL_BYTES=$(wc -c < "$MODEL_PATH" | tr -d ' ')
ACTUAL_SHA256=$(shasum -a 256 "$MODEL_PATH" | awk '{print $1}')
[[ "$ACTUAL_BYTES" == "$EXPECTED_BYTES" ]] || {
  echo "Wrong Q4 byte count: $ACTUAL_BYTES" >&2
  exit 3
}
[[ "$ACTUAL_SHA256" == "$EXPECTED_SHA256" ]] || {
  echo "Wrong Q4 SHA-256: $ACTUAL_SHA256" >&2
  exit 3
}

SERIAL=$(adb devices | awk '$2 == "device" && $1 ~ /^emulator-/ {print $1}')
[[ $(printf '%s\n' "$SERIAL" | sed '/^$/d' | wc -l | tr -d ' ') == 1 ]] || {
  echo "Connect exactly one Android emulator." >&2
  exit 4
}
API_LEVEL=$(adb -s "$SERIAL" shell getprop ro.build.version.sdk | tr -d '\r')
ABI=$(adb -s "$SERIAL" shell getprop ro.product.cpu.abi | tr -d '\r')
[[ "$API_LEVEL" == 34 ]] || {
  echo "MG-10 requires API 34; detected API $API_LEVEL." >&2
  exit 4
}
[[ "$ABI" == "arm64-v8a" ]] || {
  echo "MG-10 requires arm64-v8a; detected $ABI." >&2
  exit 4
}

flutter build apk --debug
adb -s "$SERIAL" install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s "$SERIAL" push "$MODEL_PATH" /data/local/tmp/medgemma-1.5-4b-it-Q4_K_M.gguf
adb -s "$SERIAL" shell run-as com.vueniverse.vueniverse mkdir -p files/medgemma-models
adb -s "$SERIAL" shell run-as com.vueniverse.vueniverse cp \
  /data/local/tmp/medgemma-1.5-4b-it-Q4_K_M.gguf \
  files/medgemma-models/medgemma-1.5-4b-it-Q4_K_M.gguf

JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
  android/gradlew -p android :app:connectedDebugAndroidTest \
  -Pandroid.testInstrumentationRunnerArguments.class=com.vueniverse.vueniverse.medgemma.NativeMedGemmaSmokeTest \
  -Pandroid.testInstrumentationRunnerArguments.requireRealModel=true

echo "MG-10 API 34 ARM64 checkpoint completed without an optional-model skip."
