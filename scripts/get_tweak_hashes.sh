#!/usr/bin/env bash
set -euo pipefail

echo "==> INPUT_DEMC=${INPUT_DEMC:-false}"

get_hash() {
  git ls-remote "$1" HEAD | cut -f1
}

fetch_group() {
  local owner="$1"; shift
  for repo in "$@"; do
    local hash
    hash=$(get_hash "https://github.com/${owner}/${repo}.git")

    key=$(echo "$repo" | tr '[:upper:]' '[:lower:]')

    echo "$key=$hash" >> "$GITHUB_OUTPUT"
    echo "$key:$hash" >> tweak_hashes.txt
  done
}

echo "==> Fetching tweak hashes"
: > tweak_hashes.txt

# Core
fetch_group Tonwalter888 YouMod YTUHD YouMute
fetch_group PoomSmart YTVideoOverlay YouPiP YouChooseQuality YouGroupSettings YouSpeed

# DontEatMyContent
if [ "${INPUT_DEMC:-false}" = "true" ]; then
  fetch_group therealFoxster DontEatMyContent
else
  echo "==> Skipping DontEatMyContent hash"
fi

echo "==> Hashes saved"
cat tweak_hashes.txt
