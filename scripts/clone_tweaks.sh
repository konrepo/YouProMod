#!/usr/bin/env bash
set -euo pipefail

echo "==> INPUT_DEMC=${INPUT_DEMC:-false}"

clone_repo() {
  local dir="$1"
  local owner="$2"

  if [ ! -d "$dir" ]; then
    echo "==> Cloning $dir"
    git clone --quiet --depth=1 "https://github.com/${owner}/${dir}.git" "$dir"
  else
    echo "==> $dir already exists, skipping clone"
  fi
}

clone_group() {
  local owner="$1"; shift
  for repo in "$@"; do
    clone_repo "$repo" "$owner"
  done
}

# Repos by owner
clone_group Tonwalter888 YouMod
clone_group PoomSmart YTVideoOverlay YouPiP YouMute YouChooseQuality YouGroupSettings YouSpeed

# DontEatMyContent
if [ "${INPUT_DEMC:-false}" = "true" ]; then
  clone_group therealFoxster DontEatMyContent
else
  echo "==> Skipping DontEatMyContent"
fi
