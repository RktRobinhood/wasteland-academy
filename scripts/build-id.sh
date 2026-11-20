#!/usr/bin/env bash
# Prints this build's id (#184): $WA_BUILD_ID if set (CI sets the release tag, or
# main-<commit> for the preview), else `git describe --tags --always`, else "dev".
# export.sh writes it into the game and scripts/assemble-site.sh into the service worker.
set -euo pipefail
if [ -n "${WA_BUILD_ID:-}" ]; then printf '%s\n' "$WA_BUILD_ID"; exit 0; fi
git -C "$(dirname "$0")/.." describe --tags --always 2>/dev/null || echo dev
