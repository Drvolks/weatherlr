#!/bin/bash
# Archive and upload PréviCA and PréviCA+ for iOS to TestFlight
# (watchOS app is embedded in the iOS archive)
#
# Requirements:
#   App Store Connect API key (.p8 file)
#   Apple Distribution certificate in local Keychain
#   Set these environment variables or edit the values below:
#     ASC_KEY_ID       - API Key ID
#     ASC_ISSUER_ID    - Issuer ID
#     ASC_KEY_PATH     - Path to AuthKey_XXXX.p8 file

set -e

# App Store Connect API key config
KEY_ID="${ASC_KEY_ID:?Set ASC_KEY_ID environment variable}"
ISSUER_ID="${ASC_ISSUER_ID:?Set ASC_ISSUER_ID environment variable}"
KEY_PATH="${ASC_KEY_PATH:?Set ASC_KEY_PATH environment variable}"

ARCHIVE_DIR=~/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)
EXPORT_DIR=/tmp/PreviCA-export
PROJECT=weatherlr.xcodeproj
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXPORT_PLIST="$SCRIPT_DIR/ExportOptions.plist"

AUTH_FLAGS=(-allowProvisioningUpdates \
  -authenticationKeyPath "$KEY_PATH" \
  -authenticationKeyID "$KEY_ID" \
  -authenticationKeyIssuerID "$ISSUER_ID")

rm -rf "$EXPORT_DIR"

# --- Derive build number from git commit count ---

cd "$SCRIPT_DIR"
BUILD_NUMBER=$(git rev-list HEAD --count)
echo "=== Build number (git commit count): $BUILD_NUMBER ==="

TAG="build-$BUILD_NUMBER"
echo "=== Tagging commit as $TAG ==="
git tag "$TAG"
git push origin "$TAG"

# Stamp CFBundleVersion into all Info.plist files inside an xcarchive
stamp_build_number() {
  local archive="$1"
  echo "  Stamping build $BUILD_NUMBER in $archive"
  # App and extension Info.plist files
  find "$archive/Products" -name "Info.plist" -print0 | while IFS= read -r -d '' plist; do
    if /usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$plist" &>/dev/null; then
      /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$plist"
    fi
  done
  # Archive-level metadata
  if /usr/libexec/PlistBuddy -c "Print ApplicationProperties:CFBundleVersion" "$archive/Info.plist" &>/dev/null; then
    /usr/libexec/PlistBuddy -c "Set :ApplicationProperties:CFBundleVersion $BUILD_NUMBER" "$archive/Info.plist"
  fi
}

# --- PréviCA+ (plus) ---

echo "=== Archiving PréviCA+ ==="
xcodebuild archive -project "$PROJECT" -scheme "PréviCA+" \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_DIR/PreviCAPlus-iOS.xcarchive" \
  "${AUTH_FLAGS[@]}"

stamp_build_number "$ARCHIVE_DIR/PreviCAPlus-iOS.xcarchive"

echo "=== Exporting PréviCA+ ==="
mkdir -p "$EXPORT_DIR/Plus"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_DIR/PreviCAPlus-iOS.xcarchive" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  -exportPath "$EXPORT_DIR/Plus" \
  "${AUTH_FLAGS[@]}"

echo "=== Uploading PréviCA+ to TestFlight ==="
ARTIFACT=$(find "$EXPORT_DIR/Plus" \( -name "*.ipa" -o -name "*.pkg" \) -print -quit)
if [ -z "$ARTIFACT" ]; then
  echo "ERROR: No IPA found in $EXPORT_DIR/Plus"
  exit 1
fi
xcrun altool --upload-app \
  -f "$ARTIFACT" \
  -t ios \
  --apiKey "$KEY_ID" \
  --apiIssuer "$ISSUER_ID"

# --- PréviCA (free) ---

echo "=== Archiving PréviCA ==="
xcodebuild archive -project "$PROJECT" -scheme "weatherlr" \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_DIR/PreviCA-iOS.xcarchive" \
  "${AUTH_FLAGS[@]}"

stamp_build_number "$ARCHIVE_DIR/PreviCA-iOS.xcarchive"

echo "=== Exporting PréviCA ==="
mkdir -p "$EXPORT_DIR/Free"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_DIR/PreviCA-iOS.xcarchive" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  -exportPath "$EXPORT_DIR/Free" \
  "${AUTH_FLAGS[@]}"

echo "=== Uploading PréviCA to TestFlight ==="
ARTIFACT=$(find "$EXPORT_DIR/Free" \( -name "*.ipa" -o -name "*.pkg" \) -print -quit)
if [ -z "$ARTIFACT" ]; then
  echo "ERROR: No IPA found in $EXPORT_DIR/Free"
  exit 1
fi
xcrun altool --upload-app \
  -f "$ARTIFACT" \
  -t ios \
  --apiKey "$KEY_ID" \
  --apiIssuer "$ISSUER_ID"

echo "=== Both apps archived and uploaded to TestFlight ==="
