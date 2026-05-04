#!/usr/bin/env bash
set -euo pipefail

echo "==> Extracting IPA for metadata"

rm -rf ytextracted original_ipa
unzip -q youtube.ipa -d ytextracted
unzip -q youtube.ipa -d original_ipa

PLIST="ytextracted/Payload/YouTube.app/Info.plist"

if [ ! -f "$PLIST" ]; then
  echo "::error::Info.plist not found"
  exit 1
fi

yt_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST" 2>/dev/null || echo "unknown")

echo "YT_VERSION=${yt_version}" >> "$GITHUB_ENV"

echo "==> YouTube version: $yt_version"

echo "==> Original app contents"
ls -la original_ipa/Payload/YouTube.app || true

echo "==> Original PlugIns"
ls -la original_ipa/Payload/YouTube.app/PlugIns || true

echo "==> Original Extensions"
ls -la original_ipa/Payload/YouTube.app/Extensions || true