#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

API="${1:-36}"
MODE="${2:-quick}"

case "$API" in
  34) AVD="Vueniverse_API_34"; PORT=5554 ;;
  36) AVD="Vueniverse_API_36"; PORT=5556 ;;
  *) echo "Usage: $0 {34|36} [quick|cold]" >&2; exit 2 ;;
esac

require_tool "$EMULATOR"
require_tool "$ADB"

SERIAL="emulator-$PORT"

# ADB can briefly keep a just-closed emulator registered without an AVD name.
# Wait for that stale transport to disappear before deciding the port is busy.
for _ in {1..30}; do
  if ! "$ADB" -s "$SERIAL" get-state >/dev/null 2>&1; then
    break
  fi
  RUNNING_AVD="$("$ADB" -s "$SERIAL" emu avd name 2>/dev/null | head -1 | tr -d '\r')"
  if [[ -n "$RUNNING_AVD" ]]; then
    break
  fi
  sleep 1
done

if "$ADB" -s "$SERIAL" get-state >/dev/null 2>&1; then
  RUNNING_AVD="$("$ADB" -s "$SERIAL" emu avd name 2>/dev/null | head -1 | tr -d '\r')"
  if [[ "$RUNNING_AVD" != "$AVD" ]]; then
    echo "$SERIAL is already occupied by $RUNNING_AVD" >&2
    exit 1
  fi
else
  FLAGS=(-avd "$AVD" -port "$PORT" -no-audio -netdelay none -netspeed full)
  if [[ "$MODE" == "cold" ]]; then
    FLAGS+=(-no-snapshot-load)
  fi
  "$EMULATOR" "${FLAGS[@]}" >"/tmp/${AVD}.log" 2>&1 &
fi

"$ADB" -s "$SERIAL" wait-for-device
for _ in {1..180}; do
  BOOT_COMPLETED="$("$ADB" -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
  if [[ "$BOOT_COMPLETED" == "1" ]]; then
    "$ADB" -s "$SERIAL" shell input keyevent 82 >/dev/null
    "$ADB" -s "$SERIAL" shell settings put global window_animation_scale 0
    "$ADB" -s "$SERIAL" shell settings put global transition_animation_scale 0
    "$ADB" -s "$SERIAL" shell settings put global animator_duration_scale 0
    echo "$AVD is ready as $SERIAL"
    exit 0
  fi
  sleep 1
done

echo "$AVD did not finish booting; inspect /tmp/${AVD}.log" >&2
exit 1
