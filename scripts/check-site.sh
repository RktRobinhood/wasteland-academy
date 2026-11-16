#!/usr/bin/env bash
# Fails if a repository document or source folder is on the assembled Pages site
# (#197). scripts/assemble-site.sh lays the site out, and this checks what it left.
#
#   scripts/check-site.sh <site dir>
#
# Fails on any *.md, on any game/, services/, writing/, tools/ or curriculum/ folder,
# on a classic/ folder (the HTML game isn't published there), and on the page Jekyll
# makes of any Markdown file in the repository (ROADMAP.md is also ROADMAP.html).
# .github/workflows/pages.yml runs it before the deploy, and tools/takeover-dry-run
# for both positions of the switch.
set -euo pipefail

site="${1:?site dir}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ -d "$site" ] || { echo "no site at $site" >&2; exit 1; }

found="$(
	cd "$site"
	find . -type f -name '*.md'
	find . -type d \( -name game -o -name services -o -name writing -o -name tools -o -name curriculum -o -name classic \)
	git -C "$ROOT" ls-files '*.md' | while IFS= read -r md; do
		[ -e "${md%.md}.html" ] && echo "./${md%.md}.html"
	done
	true
)"
if [ -n "$found" ]; then
	echo "repository documents or source on the site at $site:" >&2
	echo "$found" | sort | head -50 >&2
	exit 1
fi
echo "ok   no repository document or source on the site at $site"
