#!/usr/bin/env bash
set -euo pipefail

get_hash() {
  git ls-remote "$1" HEAD | cut -f1
}

echo "==> Fetching tweak hashes"

youmod=$(get_hash https://github.com/Tonwalter888/YouMod.git)

echo "youmod=$youmod" >> "$GITHUB_OUTPUT"

cat <<EOF > tweak_hashes.txt
youmod:$youmod
EOF

echo "==> Hashes saved"
cat tweak_hashes.txt