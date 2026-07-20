#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

require_tool "$SDKMANAGER"
require_tool "$AVDMANAGER"

AVD_DISK_SIZE="${VUENIVERSE_AVD_DISK_SIZE:-8G}"
if [[ ! "$AVD_DISK_SIZE" =~ ^[1-9][0-9]*[GM]$ ]]; then
  echo "VUENIVERSE_AVD_DISK_SIZE must look like 8G or 4096M" >&2
  exit 2
fi

AVD_RAM_MB="${VUENIVERSE_AVD_RAM_MB:-4096}"
if [[ ! "$AVD_RAM_MB" =~ ^[1-9][0-9]*$ ]]; then
  echo "VUENIVERSE_AVD_RAM_MB must be a whole number of megabytes" >&2
  exit 2
fi

PACKAGES=(
  "cmdline-tools;latest"
  "platform-tools"
  "emulator"
  "platforms;android-34"
  "platforms;android-36"
  "build-tools;36.0.0"
  "system-images;android-34;google_apis_playstore;arm64-v8a"
  "system-images;android-36;google_apis_playstore;arm64-v8a"
)

"$SDKMANAGER" --licenses
"$SDKMANAGER" "${PACKAGES[@]}"

create_avd() {
  local name="$1"
  local package="$2"
  if "$EMULATOR" -list-avds | grep -Fxq "$name"; then
    echo "$name already exists; preserving it."
  else
    printf 'no\n' | "$AVDMANAGER" create avd \
      --name "$name" \
      --package "$package" \
      --device "pixel_8"
  fi

  local config="$HOME/.android/avd/$name.avd/config.ini"
  upsert_property "$config" "PlayStore.enabled" "yes"
  upsert_property "$config" "hw.ramSize" "$AVD_RAM_MB"
  upsert_property "$config" "disk.dataPartition.size" "$AVD_DISK_SIZE"
  upsert_property "$config" "hw.gpu.enabled" "yes"
  upsert_property "$config" "hw.gpu.mode" "auto"
  upsert_property "$config" "fastboot.forceColdBoot" "no"
  upsert_property "$config" "fastboot.forceFastBoot" "yes"
}

upsert_property() {
  local config="$1"
  local key="$2"
  local value="$3"
  awk -F= -v key="$key" '
    {
      existing_key = $1
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", existing_key)
      if (existing_key != key) print
    }
  ' "$config" >"$config.tmp"
  printf '%s=%s\n' "$key" "$value" >>"$config.tmp"
  mv "$config.tmp" "$config"
}

create_avd "Vueniverse_API_34" "system-images;android-34;google_apis_playstore;arm64-v8a"
create_avd "Vueniverse_API_36" "system-images;android-36;google_apis_playstore;arm64-v8a"

echo "Android emulator setup complete. Existing AVDs were not deleted."
