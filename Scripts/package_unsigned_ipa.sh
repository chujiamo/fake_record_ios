#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
DERIVED_DATA="${PROJECT_DIR}/build/DerivedData"
APP_PATH="${DERIVED_DATA}/Build/Products/Release-iphoneos/VoidCast.app"
APPEX_PATH="${APP_PATH}/PlugIns/VoidCastSink.appex"
ARTIFACT_DIR="${PROJECT_DIR}/artifacts"
IPA_PATH="${ARTIFACT_DIR}/VoidCast-unsigned.ipa"

echo "[1/4] Building the iPhoneOS Release product without code signing..."
/usr/bin/xcodebuild \
  -project "${PROJECT_DIR}/VoidCast.xcodeproj" \
  -scheme VoidCast \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "${DERIVED_DATA}" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY= \
  DEVELOPMENT_TEAM= \
  build

echo "[2/4] Checking the built app and broadcast extension..."
test -d "${APP_PATH}"
test -d "${APPEX_PATH}"
test "$(/usr/bin/plutil -extract CFBundlePackageType raw -o - "${APP_PATH}/Info.plist")" = "APPL"
test "$(/usr/bin/plutil -extract CFBundlePackageType raw -o - "${APPEX_PATH}/Info.plist")" = "XPC!"
test "$(/usr/bin/plutil -extract NSExtension.NSExtensionPointIdentifier raw -o - "${APPEX_PATH}/Info.plist")" = "com.apple.broadcast-services-upload"
test "$(/usr/bin/plutil -extract NSExtension.RPBroadcastProcessMode raw -o - "${APPEX_PATH}/Info.plist")" = "RPBroadcastProcessModeSampleBuffer"
test "$(/usr/bin/plutil -extract UIBackgroundModes.0 raw -o - "${APP_PATH}/Info.plist")" = "screen-capture"
test -n "$(/usr/bin/plutil -extract NSScreenCaptureUsageDescription raw -o - "${APP_PATH}/Info.plist")"
test "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.developer.screen-recording' "${PROJECT_DIR}/VoidCast/VoidCast.entitlements")" = "true"

HOST_BUNDLE_ID="$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "${APP_PATH}/Info.plist")"
EXTENSION_BUNDLE_ID="$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "${APPEX_PATH}/Info.plist")"
case "${EXTENSION_BUNDLE_ID}" in
  "${HOST_BUNDLE_ID}".*) ;;
  *)
    echo "Broadcast extension bundle ID must be a child of the host bundle ID." >&2
    exit 1
    ;;
esac

test ! -e "${APP_PATH}/embedded.mobileprovision"
test -z "$(/usr/bin/find "${APP_PATH}" \( -name _CodeSignature -o -name CodeResources \) -print -quit)"

if /usr/bin/codesign -d "${APP_PATH}" >/dev/null 2>&1; then
  echo "Unexpected signature on host app." >&2
  exit 1
fi

if /usr/bin/codesign -d "${APPEX_PATH}" >/dev/null 2>&1; then
  echo "Unexpected signature on broadcast extension." >&2
  exit 1
fi

echo "[3/4] Packaging Payload as an unsigned IPA..."
/bin/mkdir -p "${ARTIFACT_DIR}"
STAGE_DIR="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/voidcast-ipa.XXXXXX")"
VERIFY_DIR="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/voidcast-verify.XXXXXX")"
cleanup() {
  /bin/rm -rf "${STAGE_DIR}" "${VERIFY_DIR}"
}
trap cleanup EXIT

/bin/mkdir -p "${STAGE_DIR}/Payload"
/usr/bin/ditto "${APP_PATH}" "${STAGE_DIR}/Payload/VoidCast.app"
/bin/rm -f "${IPA_PATH}"
(
  cd "${STAGE_DIR}"
  /usr/bin/zip -qry -X "${IPA_PATH}" Payload
)

echo "[4/4] Verifying the final archive..."
/usr/bin/unzip -tq "${IPA_PATH}"
/usr/bin/unzip -q "${IPA_PATH}" -d "${VERIFY_DIR}"
test -d "${VERIFY_DIR}/Payload/VoidCast.app/PlugIns/VoidCastSink.appex"
test "$(/usr/bin/find "${VERIFY_DIR}/Payload" -maxdepth 1 -type d -name '*.app' | /usr/bin/wc -l | /usr/bin/tr -d ' ')" = "1"
test -z "$(/usr/bin/find "${VERIFY_DIR}/Payload/VoidCast.app" \( -name _CodeSignature -o -name CodeResources -o -name embedded.mobileprovision \) -print -quit)"

echo "Unsigned IPA ready: ${IPA_PATH}"
