#!/bin/bash
# Archive and upload PréviCA for iOS to TestFlight
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
SCHEME=PréviCA+
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXPORT_PLIST="$SCRIPT_DIR/ExportOptions.plist"

AUTH_FLAGS=(-allowProvisioningUpdates \
  -authenticationKeyPath "$KEY_PATH" \
  -authenticationKeyID "$KEY_ID" \
  -authenticationKeyIssuerID "$ISSUER_ID")

rm -rf "$EXPORT_DIR"

# --- Bump build number once for all archives ---

cd "$SCRIPT_DIR"
CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" weatherlr/Info.plist)
NEW_BUILD=$((CURRENT_BUILD + 1))
echo "=== Bumping build number: $CURRENT_BUILD → $NEW_BUILD ==="
for plist in weatherlr/Info.plist "watch Extension/Info.plist" watch/Info.plist "weatherlr Widget/Info.plist"; do
  if [ -f "$plist" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD" "$plist"
  fi
done

# --- Archive ---

echo "=== Archiving iOS ==="
xcodebuild archive -project "$PROJECT" -scheme "$SCHEME" \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_DIR/PreviCAPlus-iOS.xcarchive" \
  "${AUTH_FLAGS[@]}"

# --- Export (sign for distribution) ---

echo "=== Exporting iOS ==="
mkdir -p "$EXPORT_DIR/iOS"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_DIR/PreviCAPlus-iOS.xcarchive" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  -exportPath "$EXPORT_DIR/iOS" \
  "${AUTH_FLAGS[@]}"

# --- Upload to TestFlight ---

echo "=== Uploading to TestFlight ==="
ARTIFACT=$(find "$EXPORT_DIR/iOS" \( -name "*.ipa" -o -name "*.pkg" \) -print -quit)
if [ -z "$ARTIFACT" ]; then
  echo "ERROR: No IPA found in $EXPORT_DIR/iOS"
  exit 1
fi

xcrun altool --upload-app \
  -f "$ARTIFACT" \
  -t ios \
  --apiKey "$KEY_ID" \
  --apiIssuer "$ISSUER_ID"

echo "=== Archived and uploaded to TestFlight ==="
