#!/usr/bin/env bash
set -euo pipefail

echo "==> INPUT_DEMC=${INPUT_DEMC:-false}"

clone_repo() {
  local dir="$1"
  local owner="$2"

  if [ ! -d "$dir/.git" ]; then
    echo "==> Cloning $dir"
    rm -rf "$dir"
    git clone --quiet --depth=1 --recurse-submodules "https://github.com/${owner}/${dir}.git" "$dir"
  else
    echo "==> $dir already exists, updating repo"
    git -C "$dir" fetch --depth=1 origin
    git -C "$dir" reset --hard origin/HEAD
    git -C "$dir" submodule sync --recursive
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
clone_group Tonwalter888 YouMod YTUHD
clone_group PoomSmart YTVideoOverlay YouPiP YouMute YouChooseQuality YouGroupSettings YouSpeed

# DontEatMyContent
if [ "${INPUT_DEMC:-false}" = "true" ]; then
  clone_group therealFoxster DontEatMyContent
else
  echo "==> Skipping DontEatMyContent"
fi
