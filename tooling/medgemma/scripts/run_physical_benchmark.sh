#!/usr/bin/env bash
set -euo pipefail

MODEL_PATH="${1:-}"
REPORT_PATH="${2:-tooling/medgemma/reports/generated/physical-runtime-report.json}"
if [[ -z "$MODEL_PATH" || ! -f "$MODEL_PATH" ]]; then
  echo "Usage: $0 /absolute/path/medgemma-1.5-4b-it-Q4_K_M.gguf [report.json]" >&2
  exit 2
fi

EXPECTED_BYTES=2489894144
EXPECTED_SHA256=4828aa086174fa34e570a6f289e9d17385542c21cdbbc7f0071d6d72d5c2774f
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

flutter build apk --debug
adb -s "$SERIAL" install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s "$SERIAL" push "$MODEL_PATH" /data/local/tmp/medgemma-1.5-4b-it-Q4_K_M.gguf
adb -s "$SERIAL" shell run-as com.whypulse.why_pulse mkdir -p files/medgemma-models
adb -s "$SERIAL" shell run-as com.whypulse.why_pulse cp \
  /data/local/tmp/medgemma-1.5-4b-it-Q4_K_M.gguf \
  files/medgemma-models/medgemma-1.5-4b-it-Q4_K_M.gguf

JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
  android/gradlew -p android :app:connectedDebugAndroidTest \
  -Pandroid.testInstrumentationRunnerArguments.class=com.whypulse.why_pulse.medgemma.MedGemmaPhysicalBenchmarkTest \
  -Pandroid.testInstrumentationRunnerArguments.requirePhysicalBenchmark=true

mkdir -p "$(dirname "$REPORT_PATH")"
adb -s "$SERIAL" shell run-as com.whypulse.why_pulse \
  cat files/medgemma-benchmark/runtime-report.json > "$REPORT_PATH"

PYTHONPATH=tooling/medgemma/src python3 -c \
  'from whypulse_medgemma.cli import main; main()' runtime-score "$REPORT_PATH"
echo "MG-12 report: $REPORT_PATH"
