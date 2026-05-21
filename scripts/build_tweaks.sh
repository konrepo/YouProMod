#!/usr/bin/env bash
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-$(pwd)}"

echo "==> INPUT_DEMC=${INPUT_DEMC:-false}"
echo "==> INPUT_YTLOCALQUEUE=${INPUT_YTLOCALQUEUE:-false}"

build_rootless() {
  local dir="$1"
  local out="$2"

  echo "==> Building $dir"

  pushd "$ROOT/$dir" >/dev/null
  make clean package DEBUG=0 FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
  popd >/dev/null

  rm -f "$ROOT/$out"
  mv "$ROOT/$dir"/packages/*.deb "$ROOT/$out"
}

build_rootless "YouMod" "youmod.deb"
build_rootless "YTVideoOverlay" "ytvideooverlay.deb"
build_rootless "YouPiP" "youpip.deb"
build_rootless "YouMute" "youmute.deb"
build_rootless "YouChooseQuality" "youchoosequality.deb"
build_rootless "YouGroupSettings" "yougroupsettings.deb"
build_rootless "YouSpeed" "youspeed.deb"
build_rootless "YTUHD" "ytuhd.deb"

# DontEatMyContent
if [ "${INPUT_DEMC:-false}" = "true" ]; then
  build_rootless "DontEatMyContent" "donteatmycontent.deb"
fi

# YTLocalQueue
if [ "${INPUT_YTLOCALQUEUE:-false}" = "true" ]; then
  mkdir -p "$ROOT/YTLocalQueue/Headers"
  rm -rf "$ROOT/YTLocalQueue/Headers/YouTubeHeader"
  ln -sf "$THEOS/include/YouTubeHeader" "$ROOT/YTLocalQueue/Headers/YouTubeHeader"

  build_rootless "YTLocalQueue" "ytlocalqueue.deb"
fi

build_rootless "tweaks/KhmerTopButton" "khmertopbutton.deb"
build_rootless "tweaks/YouProb2LangFix" "youprob2langfix.deb"

echo "==> Built packages"
ls -lh "$ROOT"/*.deb
