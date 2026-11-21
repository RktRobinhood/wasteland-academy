#!/usr/bin/env bash
# Lays out the Pages site, for one position of the takeover switch (README,
# "Switching to Godot"). Changes the site folder in place.
#
#   scripts/assemble-site.sh <site dir> <export dir> <off|on>
#
# <site dir> is the HTML game as Jekyll built it, <export dir> the Godot web export.
#   off  the HTML game at the root, Godot at next/ (the site before the takeover)
#   on   Godot at the root and next/ a redirect to the root. The HTML game isn't
#        published (#197: one game, one save). The root service-worker.js is Godot's
#        offline worker from _takeover/ (it also retires the HTML game's worker and
#        caches), registered from the Godot index.html.
#
# Jekyll publishes the whole repository, so either way only the HTML game's own
# files are kept from it (HTML_GAME below), less any *.md and the page Jekyll made
# of it. scripts/check-site.sh then checks no repository document is left.
#
# .github/workflows/pages.yml runs this. tools/takeover-dry-run runs it for both
# positions and checks each in Chromium.
set -euo pipefail

site="${1:?site dir}"
export_dir="${2:?export dir}"
position="${3:?off or on}"
takeover="$(cd "$(dirname "$0")/../_takeover" && pwd)"

[ -f "$site/index.html" ] || { echo "no index.html in $site" >&2; exit 1; }
[ -f "$export_dir/index.pck" ] || { echo "no Godot export (index.pck) in $export_dir" >&2; exit 1; }
for dir in next; do
	if [ -e "$site/$dir" ]; then echo "the repo already publishes a $dir/ path" >&2; exit 1; fi
done
case "$position" in off|on) ;; *)
	echo "the takeover switch is \"$position\": it must be off or on" >&2
	exit 1
	;;
esac

# The legacy HTML game's own files, at the site root: everything else Jekyll built
# (ROADMAP.md, game/, services/, writing/, tools/, curriculum/ and the rest) goes
HTML_GAME=(index.html js css content vendor assets manifest.json service-worker.js)
keep=()
for f in "${HTML_GAME[@]}"; do keep+=(! -name "$f"); done
find "$site" -mindepth 1 -maxdepth 1 "${keep[@]}" -exec rm -rf {} +
# A Markdown file there (assets/audio/CREDITS.md) and the page Jekyll made of it
find "$site" -type f -name '*.md' -print0 | while IFS= read -r -d '' md; do
	rm -f "$md" "${md%.md}.html"
done

case "$position" in
off)
	cp -r "$export_dir" "$site/next"
	;;
on)
	find "$site" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
	cp -r "$export_dir/." "$site/"
	if [ -e "$site/service-worker.js" ]; then echo "the Godot export has a service-worker.js" >&2; exit 1; fi
	# The build id names the worker's cache, and changes the file, so the browser updates it (#184)
	sed "s/__BUILD_ID__/$("$(dirname "$0")/build-id.sh")/" "$takeover/service-worker.js" > "$site/service-worker.js"
	grep -q "const BUILD_ID = '" "$site/service-worker.js" || { echo "no BUILD_ID in the worker" >&2; exit 1; }
	mkdir "$site/next"
	cp "$takeover/next.html" "$site/next/index.html"
	# The page registers the root worker, so it plays offline after one visit
	sed -i "/<meta charset=/r $takeover/register-worker.html" "$site/index.html"
	grep -q "register('service-worker.js')" "$site/index.html" || { echo "no <meta charset> in the Godot index.html, for the worker registration" >&2; exit 1; }
	;;
esac
echo "ok   site with the takeover switch $position -> $site"
