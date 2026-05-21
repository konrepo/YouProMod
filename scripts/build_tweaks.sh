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

  echo "==> Patching YTLocalQueue SDK target"
  perl -0pi -e 's/TARGET\s*:?=\s*iphone:clang:[0-9.]+:[0-9.]+/TARGET := iphone:clang:18.6:14.0/' "$ROOT/YTLocalQueue/Makefile"

  echo "==> YTLocalQueue TARGET after patch:"
  grep -o 'TARGET[[:space:]]*:=[[:space:]]*iphone:clang:[^[:space:]]*' "$ROOT/YTLocalQueue/Makefile" || true

  echo "==> Patching YTLocalQueue button type issue"
  perl -0pi -e 's/UIButton(Configuration)? \*btn = \[act button\];/id btn = [act button];/g' "$ROOT/YTLocalQueue/Tweak.xm"
  perl -0pi -e 's/title = btn\.currentTitle;/title = [(UIButton *)btn currentTitle];/g' "$ROOT/YTLocalQueue/Tweak.xm"

  echo "==> YTLocalQueue button lines after patch:"
  grep -n "btn = \\[act button\\]\\|currentTitle" "$ROOT/YTLocalQueue/Tweak.xm" || true

  build_rootless "YTLocalQueue" "ytlocalqueue.deb"
fi

build_rootless "tweaks/KhmerTopButton" "khmertopbutton.deb"
build_rootless "tweaks/YouProb2LangFix" "youprob2langfix.deb"

echo "==> Built packages"
ls -lh "$ROOT"/*.deb
