#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

API="${1:-34}"
"$SCRIPT_DIR/launch.sh" "$API" quick

case "$API" in
  34) SERIAL="emulator-5554" ;;
  36) SERIAL="emulator-5556" ;;
  *) echo "Usage: $0 {34|36}" >&2; exit 2 ;;
esac

DEVICES_OUTPUT="$(flutter devices)"
if ! grep -Fq "$SERIAL" <<<"$DEVICES_OUTPUT"; then
  echo "$DEVICES_OUTPUT" >&2
  echo "Flutter did not discover $SERIAL" >&2
  exit 1
fi
flutter build apk --debug
"$ADB" -s "$SERIAL" install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null
"$ADB" -s "$SERIAL" shell am force-stop com.vueniverse.vueniverse
"$ADB" -s "$SERIAL" shell am start -n com.vueniverse.vueniverse/.MainActivity >/dev/null

for _ in {1..30}; do
  if "$ADB" -s "$SERIAL" shell pidof com.vueniverse.vueniverse | grep -Eq '[0-9]'; then
    echo "Vueniverse smoke test passed on $SERIAL"
    exit 0
  fi
  sleep 1
done

echo "Vueniverse did not remain running on $SERIAL" >&2
exit 1
