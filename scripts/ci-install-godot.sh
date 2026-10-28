#!/usr/bin/env bash
# CI: install Godot 4.7.2 for Linux (checksum checked) and put its path in $GODOT for
# later steps. Used by .github/workflows/test.yml and pages.yml.
#
#   scripts/ci-install-godot.sh [install dir]
set -euo pipefail
VERSION=4.7.2
# From https://github.com/godotengine/godot/releases/download/4.7.2-stable/SHA512-SUMS.txt
SHA512=9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65
dir="${1:-$HOME/.local/opt/godot/$VERSION}"
bin="$dir/Godot_v${VERSION}-stable_linux.x86_64"
if [ ! -x "$bin" ]; then
	mkdir -p "$dir"
	zip="$dir/godot.zip"
	curl -fsSL -o "$zip" "https://github.com/godotengine/godot/releases/download/${VERSION}-stable/Godot_v${VERSION}-stable_linux.x86_64.zip"
	echo "$SHA512  $zip" | sha512sum -c -
	unzip -q -o "$zip" -d "$dir"
	rm "$zip"
fi
"$bin" --headless --version
if [ -n "${GITHUB_ENV:-}" ]; then echo "GODOT=$bin" >>"$GITHUB_ENV"; fi
