#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXPECTED_DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
LOG_FILE="${BUILD_LOG_PATH:-build-simulator.log}"

if [[ ! -d "$EXPECTED_DEVELOPER_DIR" ]]; then
  echo "未找到完整的 Xcode.app：$EXPECTED_DEVELOPER_DIR"
  exit 1
fi

ACTIVE_DEVELOPER_DIR="$(xcode-select -p 2>/dev/null || true)"
if [[ "$ACTIVE_DEVELOPER_DIR" != "$EXPECTED_DEVELOPER_DIR" ]]; then
  echo "检测到当前 xcode-select 指向：${ACTIVE_DEVELOPER_DIR:-<empty>}"
  echo "本次构建将显式使用：$EXPECTED_DEVELOPER_DIR"
fi

export DEVELOPER_DIR="$EXPECTED_DEVELOPER_DIR"

cd "$ROOT_DIR"

XCODEBUILD_ARGS=(
  -project GdeiAssistant-iOS.xcodeproj
  -scheme GdeiAssistant-iOS
  -configuration Debug
  -sdk iphonesimulator
  -destination "generic/platform=iOS Simulator"
)

if [[ -n "${CI_XCCONFIG:-}" ]]; then
  XCODEBUILD_ARGS+=(-xcconfig "$CI_XCCONFIG")
fi

set -o pipefail
xcodebuild \
  "${XCODEBUILD_ARGS[@]}" \
  build \
  CODE_SIGNING_ALLOWED=NO \
  | tee "$LOG_FILE"
