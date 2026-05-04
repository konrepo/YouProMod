#!/usr/bin/env bash
set -euo pipefail

clone_repo() {
  local dir="$1"
  local url="$2"

  if [ ! -d "$dir" ]; then
    echo "==> Cloning $dir"
    git clone --quiet --depth=1 "$url" "$dir"
  else
    echo "==> $dir already exists, skipping clone"
  fi
}

clone_repo "YouMod" "https://github.com/Tonwalter888/YouMod.git"