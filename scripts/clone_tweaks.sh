#!/usr/bin/env bash
set -euo pipefail

echo "==> INPUT_DEMC=${INPUT_DEMC:-false}"

clone_repo() {
  local dir="$1"
  local owner="$2"

  if [ ! -d "$dir" ]; then
    echo "==> Cloning $dir"
    git clone --quiet --depth=1 --recurse-submodules "https://github.com/${owner}/${dir}.git" "$dir"
  else
    echo "==> $dir already exists, updating submodules"
    git -C "$dir" submodule update --init --recursive
  fi
}

clone_group() {
  local owner="$1"; shift
  for repo in "$@"; do
    clone_repo "$repo" "$owner"
  done
}

# Repos by owner
clone_group Tonwalter888 YouMod YTUHD YouPiP YouMute YouChooseQuality YouGroupSettings YouSpeed
clone_group PoomSmart YTVideoOverlay

# DontEatMyContent
if [ "${INPUT_DEMC:-false}" = "true" ]; then
  clone_group therealFoxster DontEatMyContent
else
  echo "==> Skipping DontEatMyContent"
fi
