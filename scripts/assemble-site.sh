#!/usr/bin/env bash
# Lays out the Pages site, for one position of the takeover switch (README,
# "Switching to Godot"). Changes the site folder in place.
#
#   scripts/assemble-site.sh <site dir> <export dir> <off|on>
#
# <site dir> is the HTML game as Jekyll built it, <export dir> the Godot web export.
#   off  the HTML game at the root, Godot at next/ (the site before the takeover)
#   on   Godot at the root, the HTML game at classic/, next/ a redirect to the root,
#        the root service-worker.js the retiring worker from _takeover/, and
#        classic/manifest.json the app id wasteland-academy-classic
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
for dir in next classic; do
	if [ -e "$site/$dir" ]; then echo "the repo already publishes a $dir/ path" >&2; exit 1; fi
done

case "$position" in
off)
	cp -r "$export_dir" "$site/next"
	;;
on)
	mkdir "$site/classic"
	find "$site" -mindepth 1 -maxdepth 1 ! -name classic -exec mv -t "$site/classic" {} +
	cp -r "$export_dir/." "$site/"
	if [ -e "$site/service-worker.js" ]; then echo "the Godot export has a service-worker.js" >&2; exit 1; fi
	cp "$takeover/service-worker.js" "$site/service-worker.js"
	mkdir "$site/next"
	cp "$takeover/next.html" "$site/next/index.html"
	# Godot's title screen shows its "Classic game" link only with this (game/ui/main.gd)
	sed -i 's|<head>|<head>\n<meta name="wa-classic" content="classic/">|' "$site/index.html"
	grep -q 'name="wa-classic"' "$site/index.html" || { echo "no <head> in the Godot index.html" >&2; exit 1; }
	# A new app id, so opening classic/ inside an app installed from the old root
	# doesn't move that app's start_url and scope to classic/
	sed -i 's|"id": "wasteland-academy"|"id": "wasteland-academy-classic"|' "$site/classic/manifest.json"
	grep -q '"id": "wasteland-academy-classic"' "$site/classic/manifest.json" || { echo "no \"id\": \"wasteland-academy\" in the HTML game's manifest.json" >&2; exit 1; }
	;;
*)
	echo "the takeover switch is \"$position\": it must be off or on" >&2
	exit 1
	;;
esac
echo "ok   site with the takeover switch $position -> $site"
