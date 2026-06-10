#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PROJECT_NAME="GdeiAssistant-iOS"
PROJECT_FILE="${PROJECT_NAME}.xcodeproj"
SCHEME_NAME="GdeiAssistant-iOS"
BUNDLE_ID="${IOS_APP_BUNDLE_ID:-cn.gdeiassistant.GdeiAssistant-iOS}"
ARCHIVE_PATH="${IOS_ARCHIVE_PATH:-$RUNNER_TEMP/${PROJECT_NAME}.xcarchive}"
EXPORT_PATH="${IOS_EXPORT_PATH:-$RUNNER_TEMP/ios-export}"
EXPORT_OPTIONS_PLIST="${RUNNER_TEMP:-/tmp}/ExportOptions.plist"
KEYCHAIN_PATH="${RUNNER_TEMP:-/tmp}/ios-release.keychain-db"
CERTIFICATE_PATH="${RUNNER_TEMP:-/tmp}/ios-distribution.p12"
PROFILE_PATH="${RUNNER_TEMP:-/tmp}/ios-release.mobileprovision"
PROFILE_PLIST="${RUNNER_TEMP:-/tmp}/ios-release-profile.plist"
UPLOAD_TO_TESTFLIGHT="${IOS_UPLOAD_TO_TESTFLIGHT:-true}"
ORIGINAL_DEFAULT_KEYCHAIN=""
ORIGINAL_KEYCHAINS=""

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "::error::$name is required"
    exit 1
  fi
}

decode_base64() {
  if printf '' | base64 --decode >/dev/null 2>&1; then
    base64 --decode
  else
    base64 -D
  fi
}

require_env IOS_CERTIFICATE_P12_BASE64
require_env IOS_CERTIFICATE_PASSWORD
require_env IOS_PROVISIONING_PROFILE_BASE64
require_env IOS_DEVELOPMENT_TEAM
require_env IOS_VERSION_NAME
require_env IOS_BUILD_NUMBER

if [[ "$UPLOAD_TO_TESTFLIGHT" == "true" ]]; then
  require_env APP_STORE_CONNECT_API_KEY_ID
  require_env APP_STORE_CONNECT_ISSUER_ID
  require_env APP_STORE_CONNECT_API_KEY_BASE64
fi

cleanup() {
  if [[ -n "$ORIGINAL_DEFAULT_KEYCHAIN" ]]; then
    security default-keychain -d user -s "$ORIGINAL_DEFAULT_KEYCHAIN" >/dev/null 2>&1 || true
  fi
  if [[ -n "$ORIGINAL_KEYCHAINS" ]]; then
    # shellcheck disable=SC2086
    security list-keychains -d user -s $ORIGINAL_KEYCHAINS >/dev/null 2>&1 || true
  fi
  security delete-keychain "$KEYCHAIN_PATH" >/dev/null 2>&1 || true
}
trap cleanup EXIT

cd "$ROOT_DIR"

if [[ ! -d "${DEVELOPER_DIR:-}" ]]; then
  echo "::error::DEVELOPER_DIR must point to a full Xcode installation"
  exit 1
fi

xcodebuild -version

printf '%s' "$IOS_CERTIFICATE_P12_BASE64" | decode_base64 > "$CERTIFICATE_PATH"
printf '%s' "$IOS_PROVISIONING_PROFILE_BASE64" | decode_base64 > "$PROFILE_PATH"
security cms -D -i "$PROFILE_PATH" > "$PROFILE_PLIST"

PROFILE_UUID="$(/usr/libexec/PlistBuddy -c 'Print UUID' "$PROFILE_PLIST")"
PROFILE_NAME="$(/usr/libexec/PlistBuddy -c 'Print Name' "$PROFILE_PLIST")"
PROFILE_TEAM="$(/usr/libexec/PlistBuddy -c 'Print TeamIdentifier:0' "$PROFILE_PLIST")"

if [[ "$PROFILE_TEAM" != "$IOS_DEVELOPMENT_TEAM" ]]; then
  echo "::error::Provisioning profile team $PROFILE_TEAM does not match IOS_DEVELOPMENT_TEAM $IOS_DEVELOPMENT_TEAM"
  exit 1
fi

KEYCHAIN_PASSWORD="$(uuidgen)"
ORIGINAL_DEFAULT_KEYCHAIN="$(security default-keychain -d user | tr -d '"')"
ORIGINAL_KEYCHAINS="$(security list-keychains -d user | tr -d '"')"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security default-keychain -d user -s "$KEYCHAIN_PATH"
# shellcheck disable=SC2086
security list-keychains -d user -s "$KEYCHAIN_PATH" $ORIGINAL_KEYCHAINS
security import "$CERTIFICATE_PATH" \
  -k "$KEYCHAIN_PATH" \
  -P "$IOS_CERTIFICATE_PASSWORD" \
  -T /usr/bin/codesign \
  -T /usr/bin/security
security set-key-partition-list \
  -S apple-tool:,apple:,codesign: \
  -s \
  -k "$KEYCHAIN_PASSWORD" \
  "$KEYCHAIN_PATH"

mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
cp "$PROFILE_PATH" "$HOME/Library/MobileDevice/Provisioning Profiles/${PROFILE_UUID}.mobileprovision"

python3 - "$EXPORT_OPTIONS_PLIST" "$BUNDLE_ID" "$PROFILE_NAME" "$IOS_DEVELOPMENT_TEAM" <<'PY'
import plistlib
import sys

export_options_path, bundle_id, profile_name, team_id = sys.argv[1:5]
export_options = {
    "destination": "export",
    "method": "app-store-connect",
    "provisioningProfiles": {bundle_id: profile_name},
    "signingCertificate": "Apple Distribution",
    "signingStyle": "manual",
    "stripSwiftSymbols": True,
    "teamID": team_id,
    "uploadSymbols": True,
}

with open(export_options_path, "wb") as plist_file:
    plistlib.dump(export_options, plist_file)
PY

rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
mkdir -p "$EXPORT_PATH"

xcodebuild archive \
  -project "$PROJECT_FILE" \
  -scheme "$SCHEME_NAME" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$IOS_DEVELOPMENT_TEAM" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=YES \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  PROVISIONING_PROFILE_SPECIFIER="$PROFILE_NAME" \
  MARKETING_VERSION="$IOS_VERSION_NAME" \
  CURRENT_PROJECT_VERSION="$IOS_BUILD_NUMBER"

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

IPA_PATH="$(find "$EXPORT_PATH" -maxdepth 1 -name '*.ipa' -print -quit)"
if [[ -z "$IPA_PATH" ]]; then
  echo "::error::No IPA was exported to $EXPORT_PATH"
  exit 1
fi

echo "Exported IPA: $IPA_PATH"

if [[ "$UPLOAD_TO_TESTFLIGHT" != "true" ]]; then
  echo "Skipping TestFlight upload because IOS_UPLOAD_TO_TESTFLIGHT is not true."
  exit 0
fi

AUTH_KEY_DIR="$HOME/.appstoreconnect/private_keys"
AUTH_KEY_PATH="$AUTH_KEY_DIR/AuthKey_${APP_STORE_CONNECT_API_KEY_ID}.p8"
mkdir -p "$AUTH_KEY_DIR"
printf '%s' "$APP_STORE_CONNECT_API_KEY_BASE64" | decode_base64 > "$AUTH_KEY_PATH"
chmod 600 "$AUTH_KEY_PATH"

xcrun altool --upload-app \
  --type ios \
  --file "$IPA_PATH" \
  --apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
  --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" \
  --show-progress
