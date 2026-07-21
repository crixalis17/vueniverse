#!/usr/bin/env bash
set -euo pipefail

# Records the 1:00–1:58 Vueniverse app section from a 1080x2400 Android
# emulator. The app is reset before every take so MedGemma inference is fresh.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ADB_BIN="${ADB_BIN:-/Users/rakesh/Library/Android/sdk/platform-tools/adb}"
SERIAL="${SERIAL:-emulator-5554}"
PACKAGE="com.vueniverse.vueniverse"
ACTIVITY="$PACKAGE/.MainActivity"
OUTPUT_DIR="$REPO_DIR/build/submission-video"
REMOTE_VIDEO="/sdcard/vueniverse-snapshot-dynamic-raw.mp4"
RAW_VIDEO="$OUTPUT_DIR/vueniverse-snapshot-dynamic-raw.mp4"
FINAL_VIDEO="$OUTPUT_DIR/vueniverse-snapshot-dynamic-app-take-v1.mp4"

mkdir -p "$OUTPUT_DIR"

adb_cmd() {
  "$ADB_BIN" -s "$SERIAL" "$@"
}

tap() {
  adb_cmd shell input tap "$1" "$2"
}

swipe_up() {
  adb_cmd shell input swipe 540 "$1" 540 "$2" "$3"
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

# A fresh encrypted store can take several seconds to open. Poll the actual
# landing control instead of guessing; this setup wait stays outside the take.
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

adb_cmd shell screenrecord \
  --bit-rate 12000000 \
  --time-limit 75 \
  "$REMOTE_VIDEO" &
RECORDER_PID=$!

# 1:00–1:04 — landing and visible touch into onboarding.
sleep 4
tap 540 1340
sleep 3

# 1:04–1:08 — choose Snapshot.
tap 540 1165
sleep 5

# 1:08–1:14 — Today, then source data.
sleep 3
tap 540 750
sleep 2

# 1:14–1:20 — Observe, touch-visible scroll, and back.
swipe_up 1850 1450 650
sleep 1
tap 70 205
sleep 0.5

# 1:20–1:28 — supported fingerprint, comparison chart, and evidence action.
tap 540 1600
sleep 3
swipe_up 1900 650 850
sleep 1
tap 540 2030
sleep 3.5

# 1:28–1:36 — metrics, comparison rules, exclusions, then Explain.
swipe_up 1950 650 850
sleep 0.75
swipe_up 1950 850 750
sleep 0.75
tap 540 2185

# 1:36–1:46 — preserve genuine local inference, then center its receipt.
sleep 4
swipe_up 1900 1350 550
sleep 0.5

# Return through Evidence and Fingerprint to Today with visible back touches.
tap 70 205
sleep 0.5
tap 70 205
sleep 0.5
tap 70 205
sleep 0.5

# 1:46–1:50 — reveal and open the guided Snapshot.
swipe_up 1900 550 800
sleep 0.5
tap 540 1400
sleep 0.5

# Move to the experiment/proof controls with continuous, human-like swipes.
for _ in 1 2 3 4 5 6; do
  swipe_up 1950 500 250
done
sleep 0.5

# 1:50–1:53 — reversible three-meeting setup.
tap 310 310
sleep 3

# 1:53–1:56 — completed result and measured improvement.
tap 70 205
sleep 0.4
tap 360 945
sleep 3.5

# 1:56–1:59 — final proof receipt.
tap 70 205
sleep 0.4
tap 340 1560
sleep 30

stop_recorder
wait "$RECORDER_PID" || true
trap - EXIT

adb_cmd pull "$REMOTE_VIDEO" "$RAW_VIDEO" >/dev/null

# Remove the one-second recorder lead-in and deliver an exact 58-second app
# section that can be placed at 1:00 in the two-minute master edit.
avconvert \
  --source "$RAW_VIDEO" \
  --preset PresetPassthrough \
  --output "$FINAL_VIDEO" \
  --start 1 \
  --duration 58 \
  --replace >/dev/null

echo "$FINAL_VIDEO"
