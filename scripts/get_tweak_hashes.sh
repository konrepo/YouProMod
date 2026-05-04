#!/usr/bin/env bash
set -euo pipefail

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

fetch_group Tonwalter888 YouMod
fetch_group PoomSmart YTVideoOverlay YouPiP

echo "==> Hashes saved"
cat tweak_hashes.txt
