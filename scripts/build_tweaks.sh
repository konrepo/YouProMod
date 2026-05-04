#!/usr/bin/env bash
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-$(pwd)}"

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
build_rootless "YTUHD" "ytuhd.deb"

build_rootless "tweaks/KhmerTopButton" "khmertopbutton.deb"

case "${INPUT_YOUPRO_VERSION:-beta3}" in
  beta1)
    build_rootless "tweaks/YouProLangFix" "youprolangfix.deb"
    ;;
  beta3)
    build_rootless "tweaks/YouProb2LangFix" "youprob2langfix.deb"
    ;;
  *)
    echo "::error::Invalid INPUT_YOUPRO_VERSION: ${INPUT_YOUPRO_VERSION:-}"
    exit 1
    ;;
esac

echo "==> Built packages"
ls -lh "$ROOT"/*.deb
