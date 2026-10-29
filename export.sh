#!/usr/bin/env bash
# Web export of game/ (the "Web" preset: Compatibility renderer, no threads, no PWA)
# into build/next/, or the folder given. Fetches the Web export templates first if
# Godot can't find them.
#
#   ./export.sh [out dir]
#
# Templates are looked for in $GODOT_TEMPLATES, then the usual
# <data dir>/godot/export_templates/4.7.2.stable/ under $XDG_DATA_HOME and
# /home/matt/.local/share, then _scratch/godot-data/, where they are fetched to if
# missing. The export runs with XDG_DATA_HOME pointing at whichever has them.
set -euo pipefail
source "$(dirname "$0")/scripts/godot-env.sh"

out="${1:-$ROOT/build/next}"
mkdir -p "$out"
out="$(cd "$out" && pwd)"

# An export opens the project like an editor does, so the same rule as --import applies.
if editor_open; then
	echo "a Godot editor is open on $GAME; stop it first (scripts/mcp-editor.sh stop)" >&2
	exit 1
fi

TPL_SUBDIR="godot/export_templates/4.7.2.stable"
data=""
if [ -n "${GODOT_TEMPLATES:-}" ]; then
	[ -f "$GODOT_TEMPLATES/web_nothreads_release.zip" ] || { echo "no web_nothreads_release.zip in $GODOT_TEMPLATES" >&2; exit 1; }
	# Godot only takes a data dir, so link the given folder into one.
	data="$ROOT/_scratch/godot-templates-link"
	mkdir -p "$data/godot/export_templates"
	ln -sfn "$GODOT_TEMPLATES" "$data/$TPL_SUBDIR"
else
	for d in "${XDG_DATA_HOME:-$HOME/.local/share}" /home/matt/.local/share "$ROOT/_scratch/godot-data"; do
		if [ -f "$d/$TPL_SUBDIR/web_nothreads_release.zip" ]; then data="$d"; break; fi
	done
	if [ -z "$data" ]; then
		data="$ROOT/_scratch/godot-data"
		echo "== fetch web export templates =="
		python3 -I "$ROOT/scripts/fetch_web_templates.py" "$data/$TPL_SUBDIR"
	fi
fi

echo "== import =="
import_project

echo "== export =="
log="$ROOT/_scratch/export.log"
rm -f "$out"/index.*
if ! XDG_DATA_HOME="$data" "$GODOT" --headless --path "$GAME" --export-release Web "$out/index.html" >"$log" 2>&1; then
	cat "$log"
	echo "export failed" >&2
	exit 1
fi
if grep -E "(^|\s)(SCRIPT )?ERROR:" "$log" >/dev/null || [ ! -f "$out/index.pck" ]; then
	grep -v "^\[ *[0-9]*% \]" "$log"
	echo "export reported errors (above)" >&2
	exit 1
fi
# Link previews point at the share card, when there is one (FAL-470).
"$ROOT/scripts/share-card.sh" "$out"
ls -l "$out"
echo "ok   export -> $out"
