#!/usr/bin/env bash
set -euo pipefail

OUTPUT_NAME="YouProMod-${INPUT_YOUPRO_VERSION}-${GITHUB_RUN_NUMBER}.ipa"

echo "==> Restoring original PlugIns and Extensions"

test -f "$OUTPUT_NAME" || { echo "::error::$OUTPUT_NAME not found"; exit 1; }

rm -rf patched_ipa
unzip -q "$OUTPUT_NAME" -d patched_ipa

rm -rf patched_ipa/Payload/YouTube.app/PlugIns
if [ -d "original_ipa/Payload/YouTube.app/PlugIns" ]; then
  cp -R original_ipa/Payload/YouTube.app/PlugIns patched_ipa/Payload/YouTube.app/PlugIns
fi

rm -rf patched_ipa/Payload/YouTube.app/Extensions
if [ -d "original_ipa/Payload/YouTube.app/Extensions" ]; then
  cp -R original_ipa/Payload/YouTube.app/Extensions patched_ipa/Payload/YouTube.app/Extensions
fi

if [ -d "OpenYouTubeSafariExtension.appex" ]; then
  mkdir -p patched_ipa/Payload/YouTube.app/PlugIns
  cp -R OpenYouTubeSafariExtension.appex patched_ipa/Payload/YouTube.app/PlugIns/
fi

echo "Restored PlugIns:"
ls -la patched_ipa/Payload/YouTube.app/PlugIns || true

echo "Restored Extensions:"
ls -la patched_ipa/Payload/YouTube.app/Extensions || true

cd patched_ipa
zip -qry "../$OUTPUT_NAME" Payload
cd ..

test -f "$OUTPUT_NAME" || { echo "::error::Final IPA was not created"; exit 1; }

echo "==> Restore complete: $OUTPUT_NAME"