#!/usr/bin/env bash
set -euo pipefail

# Fresh 1:55 app take for the expanded submission video. This take gives
# 49 seconds to MedGemma interpretation plus the actionable experiment.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ADB_BIN="${ADB_BIN:-/Users/rakesh/Library/Android/sdk/platform-tools/adb}"
SERIAL="${SERIAL:-emulator-5554}"
PACKAGE="com.vueniverse.vueniverse"
ACTIVITY="$PACKAGE/.MainActivity"
OUTPUT_DIR="$REPO_DIR/build/submission-video"
REMOTE_VIDEO="/sdcard/vueniverse-richer-insights-final-raw.mp4"
RAW_VIDEO="$OUTPUT_DIR/vueniverse-richer-insights-final-raw-20260720.mp4"
FINAL_VIDEO="$OUTPUT_DIR/vueniverse-richer-insights-final-app-1m55-20260720.mp4"
FOCUS_VIDEO="$OUTPUT_DIR/vueniverse-medgemma-experiment-focus-49s-20260720.mp4"

mkdir -p "$OUTPUT_DIR"

adb_cmd() {
  "$ADB_BIN" -s "$SERIAL" "$@"
}

tap() {
  adb_cmd shell input tap "$1" "$2"
}

swipe() {
  adb_cmd shell input swipe "$1" "$2" "$3" "$4" "$5"
}

swipe_up() {
  swipe 540 "$1" 540 "$2" "$3"
}

swipe_down() {
  swipe 540 "$1" 540 "$2" "$3"
}

back_touch() {
  tap 70 205
}

stop_recorder() {
  adb_cmd shell pkill -INT screenrecord >/dev/null 2>&1 || true
}

trap stop_recorder EXIT

curl -fsS http://127.0.0.1:8765/health >/dev/null
curl -fsS http://127.0.0.1:8765/ready >/dev/null
adb_cmd wait-for-device
adb_cmd shell pm clear "$PACKAGE" >/dev/null
adb_cmd reverse tcp:8765 tcp:8765
adb_cmd shell settings put system show_touches 1
adb_cmd shell settings put system pointer_location 0
adb_cmd shell settings put global window_animation_scale 0.5
adb_cmd shell settings put global transition_animation_scale 0.5
adb_cmd shell settings put global animator_duration_scale 0.5
adb_cmd shell rm -f "$REMOTE_VIDEO"
adb_cmd shell am start -W -n "$ACTIVITY" >/dev/null

LANDING_READY=false
for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
  UI_TREE="$(adb_cmd exec-out uiautomator dump /dev/tty 2>/dev/null || true)"
  if [[ "$UI_TREE" == *'content-desc="See how it works"'* ]]; then
    LANDING_READY=true
    break
  fi
  sleep 2
done
if [[ "$LANDING_READY" != true ]]; then
  echo "Landing screen did not become ready" >&2
  exit 1
fi

adb_cmd shell screenrecord \
  --bit-rate 12000000 \
  --time-limit 150 \
  "$REMOTE_VIDEO" &
RECORDER_PID=$!

# Two-second encoder lead-in; removed from delivered files.
sleep 2

# 1:00-1:07 — Landing, product loop, visible touch.
sleep 2
swipe_up 1850 1550 900
sleep 1
swipe_down 1550 1850 700
sleep 0.5
tap 540 1342
sleep 1.9

# 1:07-1:13 — Choose Snapshot.
sleep 4
tap 540 1166
sleep 2

# 1:13-1:22 — Today: trust, supported pattern, source action.
sleep 3
swipe_up 1900 1350 900
sleep 1.5
swipe_down 1350 1900 800
sleep 0.8
tap 540 700
sleep 2

# 1:22-1:32 — Observe: encryption receipt and data movement.
sleep 4
swipe_up 1950 900 1300
sleep 2
swipe_down 900 1950 1000
sleep 0.7
back_touch
sleep 1

# 1:32-1:43 — Pattern: hero metrics, chart, and evidence action.
tap 540 1600
sleep 1.5
sleep 4
swipe_up 2050 850 1200
sleep 1.5
tap 540 2030
sleep 2.8

# 1:43-1:53 — Evidence: deterministic numbers and comparison rules.
sleep 4
swipe_up 2100 700 1300
sleep 4.7
tap 540 2185

# 1:53-2:20 — Genuine MedGemma wait, result, hypotheses, test, receipt.
sleep 5.5
sleep 3
swipe_up 2100 600 1200
sleep 5
swipe_up 2100 600 1200
sleep 6
swipe_up 2100 850 1000
sleep 4.1

# 2:20-2:42 — Proposal plus the full actionable experiment protocol.
back_touch
sleep 0.5
back_touch
sleep 0.5
back_touch
sleep 0.5
tap 675 2245
sleep 1
sleep 3
tap 540 1335
sleep 1
sleep 3
swipe_up 2100 700 1200
sleep 2.5
swipe_up 2100 700 1200
sleep 2.5
swipe_up 2100 700 1200
sleep 2.5
back_touch
sleep 0.4
tap 135 2245
sleep 0.4
swipe_up 2050 500 600

# 2:42-2:51 — Guided measured result, with navigation kept concise.
tap 540 1140
sleep 0.8
for _ in 1 2 3 4 5 6; do
  swipe_up 1950 500 250
  sleep 0.1
done
tap 360 946
sleep 1.1
sleep 5

# 2:51-2:55 — Versioned proof and export receipt.
back_touch
sleep 0.4
tap 340 1560
sleep 3.6

# Let Android finish the file while the final proof screen stays visible.
sleep 30
wait "$RECORDER_PID" || true
trap - EXIT

adb_cmd pull "$REMOTE_VIDEO" "$RAW_VIDEO" >/dev/null

avconvert \
  --source "$RAW_VIDEO" \
  --preset PresetPassthrough \
  --output "$FINAL_VIDEO" \
  --start 2 \
  --duration 115 \
  --replace >/dev/null

avconvert \
  --source "$RAW_VIDEO" \
  --preset PresetPassthrough \
  --output "$FOCUS_VIDEO" \
  --start 55 \
  --duration 49 \
  --replace >/dev/null

printf '%s\n%s\n%s\n' "$RAW_VIDEO" "$FINAL_VIDEO" "$FOCUS_VIDEO"
