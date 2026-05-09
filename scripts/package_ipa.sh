#!/usr/bin/env bash
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-$(pwd)}"

echo "==> Preparing tweak injection"
echo "==> INPUT_DEMC=${INPUT_DEMC:-false}"

inject_items=(
  "OpenYouTubeSafariExtension.appex"
  "$ROOT/youmod.deb"
  "$ROOT/ytvideooverlay.deb"
  "$ROOT/ytuhd.deb"
  "$ROOT/youpip.deb"
  "$ROOT/youmute.deb"
  "$ROOT/youchoosequality.deb"
  "$ROOT/yougroupsettings.deb"
  "$ROOT/youspeed.deb"
)

if [ "${INPUT_DEMC:-false}" = "true" ]; then
  inject_items+=("$ROOT/donteatmycontent.deb")
fi

inject_items+=(
  "$ROOT/khmertopbutton.deb"
)

for item in "${inject_items[@]}"; do
  if [[ "$item" != "OpenYouTubeSafariExtension.appex" && ! -e "$item" ]]; then
    echo "::error::Missing required item: $item"
    exit 1
  fi
done

OUTPUT_NAME="YouProMod-${GITHUB_RUN_NUMBER}.ipa"

echo "==> Injecting:"
printf '%s\n' "${inject_items[@]}"

cyan -i youtube.ipa \
  -o "$OUTPUT_NAME" \
  -uwef "${inject_items[@]}" \
  -n "${INPUT_DISPLAY_NAME}" \
  -b "${INPUT_BUNDLE_ID}"

echo "==> Output IPA: $OUTPUT_NAME"
