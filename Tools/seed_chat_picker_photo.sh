#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: seed_chat_picker_photo.sh <simulator-udid> [output-directory]" >&2
  exit 2
fi

SIMULATOR_UDID="$1"
OUTPUT_DIRECTORY="${2:-ChatPickerFixture}"
SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$OUTPUT_DIRECTORY"

# Use one concrete simulator. Do not reset a developer's Photos library or seed a clone.
SIMULATOR_STATE=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin).get("devices", {})
device = next((d for group in devices.values() for d in group if d["udid"] == sys.argv[1]), None)
if device is None:
    sys.exit("The requested simulator is unavailable")
print(device["state"])
' "$SIMULATOR_UDID")

case "$SIMULATOR_STATE" in
  Booted) ;;
  Shutdown) xcrun simctl boot "$SIMULATOR_UDID" ;;
  *) echo "Unexpected simulator state: $SIMULATOR_STATE" >&2; exit 1 ;;
esac

xcrun simctl bootstatus "$SIMULATOR_UDID" -b
python3 "$SCRIPT_DIRECTORY/make_chat_picker_photo.py" "$OUTPUT_DIRECTORY/chat-picker-photo.png"
xcrun simctl addmedia "$SIMULATOR_UDID" "$OUTPUT_DIRECTORY/chat-picker-photo.png"
printf '%s\n' "$SIMULATOR_UDID" > "$OUTPUT_DIRECTORY/simulator-udid.txt"
echo "Seeded synthetic PhotosPicker asset on simulator $SIMULATOR_UDID"
