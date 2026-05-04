#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing cyan"
pipx install --force https://github.com/asdfzxcvbn/pyzule-rw/archive/main.zip

echo "==> Installing tbd"
curl -L --fail "https://github.com/inoahdev/tbd/releases/download/2.2/tbd-mac" -o /usr/local/bin/tbd
chmod +x /usr/local/bin/tbd
/usr/local/bin/tbd --version || true

echo "==> Cloning OpenYouTubeSafariExtension"
rm -rf OpenYouTubeSafariExtension OpenYouTubeSafariExtension.appex
git clone --quiet -n --depth=1 --filter=tree:0 https://github.com/BillyCurtis/OpenYouTubeSafariExtension.git
cd OpenYouTubeSafariExtension
git sparse-checkout set --no-cone OpenYouTubeSafariExtension.appex
git checkout
mv *.appex "${GITHUB_WORKSPACE}"
cd "${GITHUB_WORKSPACE}"

echo "==> Cloning YouTubeHeader"
rm -rf "$THEOS/include/YouTubeHeader"
git clone --quiet --depth=1 https://github.com/PoomSmart/YouTubeHeader.git "$THEOS/include/YouTubeHeader"

echo "==> Cloning PSHeader"
rm -rf "$THEOS/include/PSHeader"
git clone --quiet --depth=1 https://github.com/PoomSmart/PSHeader.git "$THEOS/include/PSHeader"