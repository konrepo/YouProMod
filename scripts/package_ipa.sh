#!/usr/bin/env bash
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-$(pwd)}"

echo "==> Preparing tweak injection"

case "${INPUT_YOUPRO_VERSION:-beta3}" in
  beta1)
    YOUPRO_DYLIB="$ROOT/tweaks/YouProBeta1.dylib"
    LANGFIX_DEB="$ROOT/youprolangfix.deb"
    ;;
  beta3)
    YOUPRO_DYLIB="$ROOT/tweaks/YouProBeta3.dylib"
    LANGFIX_DEB="$ROOT/youprob2langfix.deb"
    ;;
  *)
    echo "::error::Invalid YouPro version: ${INPUT_YOUPRO_VERSION:-}"
    exit 1
    ;;
esac

YOUPRO_BUNDLE="$ROOT/tweaks/YouPro.bundle"

required_files=(
  "$ROOT/youmod.deb"
  "$ROOT/ytvideooverlay.deb"
  "$YOUPRO_DYLIB"
  "$YOUPRO_BUNDLE"
  "$ROOT/khmertopbutton.deb"
  "$LANGFIX_DEB"
)

for item in "${required_files[@]}"; do
  if [ ! -e "$item" ]; then
    echo "::error::Missing required item: $item"
    exit 1
  fi
done

tweaks="OpenYouTubeSafariExtension.appex"
tweaks="$tweaks $ROOT/youmod.deb"
tweaks="$tweaks $ROOT/ytvideooverlay.deb"
tweaks="$tweaks $YOUPRO_DYLIB"
tweaks="$tweaks $YOUPRO_BUNDLE"
tweaks="$tweaks $ROOT/khmertopbutton.deb"
tweaks="$tweaks $LANGFIX_DEB"

echo "==> Injecting:"
echo "$tweaks"

OUTPUT_NAME="YouProMod-${INPUT_YOUPRO_VERSION}-${GITHUB_RUN_NUMBER}.ipa"

cyan -i youtube.ipa -o "$OUTPUT_NAME" -uwef $tweaks -n "${INPUT_DISPLAY_NAME}" -b "${INPUT_BUNDLE_ID}"

echo "==> Output IPA: $OUTPUT_NAME"
