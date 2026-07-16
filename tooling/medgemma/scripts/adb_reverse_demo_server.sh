#!/usr/bin/env bash
set -euo pipefail

PORT="${MEDGEMMA_DEMO_PORT:-8765}"
ADB="${ADB:-${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}/platform-tools/adb}"

if [[ ! "$PORT" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then
  echo "MEDGEMMA_DEMO_PORT must be between 1 and 65535" >&2
  exit 1
fi
if [[ ! -x "$ADB" ]]; then
  echo "Set ADB or ANDROID_SDK_ROOT to an Android SDK containing platform-tools/adb" >&2
  exit 1
fi

"$ADB" reverse "tcp:$PORT" "tcp:$PORT"
"$ADB" reverse --list
