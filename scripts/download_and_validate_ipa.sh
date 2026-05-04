#!/usr/bin/env bash
set -euo pipefail

echo "==> Downloading IPA"

if [ -z "${INPUT_IPA_URL:-}" ]; then
  echo "::error::INPUT_IPA_URL is empty"
  exit 1
fi

wget "${INPUT_IPA_URL}" --quiet --no-verbose -O youtube.ipa

if [ ! -s youtube.ipa ]; then
  echo "::error::Downloaded IPA is missing or empty"
  exit 1
fi

file_type=$(file --mime-type -b youtube.ipa)
echo "Detected MIME type: ${file_type}"

if [[ "$file_type" != "application/x-ios-app" && "$file_type" != "application/zip" ]]; then
  echo "::error::Validation failed: The downloaded file is not a valid IPA. Detected type: $file_type"
  exit 1
fi

echo "==> IPA downloaded successfully"