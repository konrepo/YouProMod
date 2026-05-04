#!/usr/bin/env bash
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-$(pwd)}"

build_rootless() {
  local dir="$1"
  local out="$2"

  echo "==> Building $dir"
  cd "$ROOT/$dir"

  make clean package DEBUG=0 FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless

  rm -f "$ROOT/$out"
  mv packages/*.deb "$ROOT/$out"
}

build_rootless "YouMod" "youmod.deb"
build_rootless "YTVideoOverlay" "ytvideooverlay.deb"
build_rootless "YouPiP" "youpip.deb"

echo "==> Building KhmerTopButton"
cd "$ROOT/tweaks/KhmerTopButton"
make clean package DEBUG=0 FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
rm -f "$ROOT/khmertopbutton.deb"
mv packages/*.deb "$ROOT/khmertopbutton.deb"

case "${INPUT_YOUPRO_VERSION:-beta3}" in
  beta1)
    echo "==> Building YouProLangFix"
    cd "$ROOT/tweaks/YouProLangFix"
    make clean package DEBUG=0 FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
    rm -f "$ROOT/youprolangfix.deb"
    mv packages/*.deb "$ROOT/youprolangfix.deb"
    ;;

  beta3)
    echo "==> Building YouProb2LangFix"
    cd "$ROOT/tweaks/YouProb2LangFix"
    make clean package DEBUG=0 FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
    rm -f "$ROOT/youprob2langfix.deb"
    mv packages/*.deb "$ROOT/youprob2langfix.deb"
    ;;

  *)
    echo "::error::Invalid INPUT_YOUPRO_VERSION: ${INPUT_YOUPRO_VERSION:-}"
    exit 1
    ;;
esac

echo "==> Built packages"
ls -lh "$ROOT"/*.deb
