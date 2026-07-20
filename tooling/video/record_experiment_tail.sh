#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ADB_BIN="${ADB_BIN:-/Users/rakesh/Library/Android/sdk/platform-tools/adb}"
SERIAL="${SERIAL:-emulator-5554}"
REMOTE_VIDEO="/sdcard/vueniverse-snapshot-experiment-tail.mp4"
OUTPUT_VIDEO="$REPO_DIR/build/submission-video/vueniverse-snapshot-experiment-tail.mp4"

adb_cmd() {
  "$ADB_BIN" -s "$SERIAL" "$@"
}

tap() {
  adb_cmd shell input tap "$1" "$2"
}

adb_cmd shell rm -f "$REMOTE_VIDEO"
adb_cmd shell screenrecord \
  --bit-rate 12000000 \
  --time-limit 45 \
  "$REMOTE_VIDEO" &
RECORDER_PID=$!

# Give Android's encoder its measured startup lead-in, then record only real
# touch navigation from the already staged guided controls.
sleep 12
tap 310 310
sleep 2.5
tap 70 205
sleep 0.4
tap 360 945
sleep 3
tap 70 205
sleep 0.4
tap 340 1560

# Let screenrecord end naturally so its final proof frames are flushed.
wait "$RECORDER_PID"
adb_cmd pull "$REMOTE_VIDEO" "$OUTPUT_VIDEO" >/dev/null
echo "$OUTPUT_VIDEO"
