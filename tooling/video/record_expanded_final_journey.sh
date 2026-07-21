#!/usr/bin/env bash
set -euo pipefail

# Records the expanded 1:55 app section for the final 2:55 submission master.
# The illustrated 0:00-1:00 pitch is intentionally not recorded here.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ADB_BIN="${ADB_BIN:-/Users/rakesh/Library/Android/sdk/platform-tools/adb}"
SERIAL="${SERIAL:-emulator-5554}"
PACKAGE="com.vueniverse.vueniverse"
ACTIVITY="$PACKAGE/.MainActivity"
OUTPUT_DIR="$REPO_DIR/build/submission-video"
REMOTE_VIDEO="/sdcard/vueniverse-expanded-final-raw.mp4"
RAW_VIDEO="$OUTPUT_DIR/vueniverse-expanded-final-raw.mp4"
FINAL_VIDEO="$OUTPUT_DIR/vueniverse-expanded-final-app-1m55.mp4"

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

stop_recorder() {
  adb_cmd shell pkill -INT screenrecord >/dev/null 2>&1 || true
}

trap stop_recorder EXIT

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

sleep 1

# Record beyond the scripted journey and trim after pulling. Waiting for the
# recorder's natural end avoids losing its final encoder buffer.
adb_cmd shell screenrecord \
  --bit-rate 12000000 \
  --time-limit 150 \
  "$REMOTE_VIDEO" &
RECORDER_PID=$!

# Two-second encoder lead-in, removed from the delivered file.
sleep 2

# 1:00-1:07 — Landing: brand, product loop, visible touch.
sleep 2
swipe_up 1850 1550 900
sleep 1
swipe_down 1550 1850 700
sleep 1
tap 540 1340
sleep 2

# 1:07-1:13 — Choose Snapshot.
sleep 4
tap 540 1165
sleep 2

# 1:13-1:23 — Today: status, supported pattern, source-data action.
sleep 3
swipe_up 1900 1350 900
sleep 2
swipe_down 1350 1900 800
sleep 1
tap 540 750
sleep 2

# 1:23-1:37 — Observe: encryption receipt, signals, and events lane.
sleep 5
swipe_up 1950 950 1500
sleep 3
swipe_down 950 1950 1200
sleep 1
tap 70 205
sleep 2

# 1:37-1:53 — Moment Fingerprint: metrics, chart, evidence action.
tap 540 1600
sleep 2
sleep 5
swipe_up 1950 650 1500
sleep 3
tap 540 2030
sleep 4.5

# 1:53-2:09 — Evidence: metrics, rules, counterexamples, exclusions.
sleep 3
swipe_up 1950 650 1500
sleep 2
swipe_up 1950 850 1500
sleep 8
tap 540 2185

# 2:09-2:25 — Preserve the genuine wait, explanation, and runtime receipt.
# The model usually responds faster than five seconds; the remaining time is
# spent holding the accepted answer before slowly centering its receipt.
sleep 5
swipe_up 1900 1150 1500
sleep 9.5

# 2:25-2:36 — Guided Snapshot and reversible quiet-buffer protocol.
tap 70 205
sleep 0.4
tap 70 205
sleep 0.4
tap 70 205
sleep 0.4
swipe_up 1900 550 800
sleep 0.4
tap 540 1400
sleep 0.6
for _ in 1 2 3 4 5 6; do
  swipe_up 1950 500 250
done
sleep 0.4
tap 310 310
sleep 6.1

# 2:36-2:47 — Completed experiment result.
tap 70 205
sleep 0.5
tap 360 945
sleep 10.5

# 2:47-2:55 — Snapshot receipt and export proof.
tap 70 205
sleep 0.5
tap 340 1560
sleep 7.5

# Give screenrecord time to flush while holding the final proof screen.
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

echo "$FINAL_VIDEO"
