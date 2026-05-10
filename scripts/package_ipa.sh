#!/usr/bin/env bash
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-$(pwd)}"

echo "==> Preparing tweak injection"
echo "==> INPUT_DEMC=${INPUT_DEMC:-false}"
echo "==> INPUT_YOUPRO_VERSION=${INPUT_YOUPRO_VERSION:-none}"

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

if [ -n "${INPUT_YOUPRO_VERSION:-}" ]; then
  DYLIB="$ROOT/tweaks/YouPro${INPUT_YOUPRO_VERSION^}.dylib"
  LANGFIX="$ROOT/tweaks/YouPro${INPUT_YOUPRO_VERSION^}LangFix.deb"

  if [ -f "$DYLIB" ]; then
    echo "==> Adding YouPro dylib: $DYLIB"
    inject_items+=("$DYLIB")
  else
    echo "::warning::YouPro dylib not found: $DYLIB (skipping)"
  fi

  if [ -f "$LANGFIX" ]; then
    echo "==> Adding YouPro LangFix: $LANGFIX"
    inject_items+=("$LANGFIX")
  else
    echo "::warning::YouPro LangFix not found: $LANGFIX (skipping)"
  fi
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
