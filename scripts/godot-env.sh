# Sourced by run.sh, test.sh, export.sh, screenshot.sh and scripts/mcp-editor.sh. Finds the Godot binary.
# Override with GODOT=/path/to/godot.
if [ -z "${GODOT:-}" ]; then
	for c in "$(command -v godot 2>/dev/null)" "$HOME/.local/bin/godot" /home/matt/.local/bin/godot; do
		if [ -n "$c" ] && [ -x "$c" ]; then GODOT="$c"; break; fi
	done
fi
if [ -z "${GODOT:-}" ]; then
	echo "Godot 4.7.2 not found. Set GODOT=/path/to/godot." >&2
	exit 127
fi
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GAME="$ROOT/game"

# Headless import, so a fresh clone (no game/.godot/) and newly landed art both work.
# Takes about 3 seconds. --import can exit 0 even when a resource or script fails, so
# the log is checked too. Skipped when a Godot editor is already open on game/ (an
# agent's MCP editor): a second editor there overwrites the open one's MCP registry
# entry and deletes it on exit, and the open editor keeps imports current anyway.
editor_open() {
	pgrep -u "$(id -u)" -f -- "--path $GAME( |$)" | xargs -r ps -o args= -p | grep -q -- "--editor"
}

# The journey strip's sheets live once, in the repo's assets/journey/ (FAL-331). They are
# copied into game/assets/journey/ (gitignored) before every import, export and editor
# start, so a new sheet needs no code change and git holds no second copy. Each image
# gets a "keep" import file: the export ships the original WebP or PNG bytes, which
# the game decodes itself (journey/journey_assets.gd), instead of re-encoding them.
sync_journey() {
	local src="$ROOT/assets/journey" dst="$GAME/assets/journey" rel
	[ -d "$src" ] || return 0
	mkdir -p "$dst"
	# Drop copies whose source has gone (FAL-208 moved sheets between folders).
	while IFS= read -r -d '' rel; do
		rel="${rel#"$dst"/}"
		case "$rel" in *.import) [ -e "$src/${rel%.import}" ] || rm -f "$dst/$rel" ;; *) [ -e "$src/$rel" ] || rm -f "$dst/$rel" ;; esac
	done < <(find "$dst" -type f -print0)
	find "$dst" -mindepth 1 -type d -empty -delete
	while IFS= read -r -d '' rel; do
		rel="${rel#"$src"/}"
		mkdir -p "$dst/$(dirname "$rel")"
		cmp -s "$src/$rel" "$dst/$rel" || cp "$src/$rel" "$dst/$rel"
		case "$rel" in
			*.webp|*.png) [ -e "$dst/$rel.import" ] || printf '[remap]\n\nimporter="keep"\n' >"$dst/$rel.import" ;;
		esac
	done < <(find "$src" -type f \( -name '*.json' -o -name '*.webp' -o -name '*.png' \) -print0)
}

import_project() {
	sync_journey
	if editor_open; then
		echo "skip import: a Godot editor is already open on $GAME"
		return 0
	fi
	local log="$ROOT/_scratch/import.log"
	mkdir -p "$(dirname "$log")"
	if ! "$GODOT" --headless --path "$GAME" --import >"$log" 2>&1; then
		cat "$log"
		echo "import failed" >&2
		return 1
	fi
	if grep -E "(^|\s)(SCRIPT )?ERROR:" "$log" >/dev/null; then
		grep -v "^\[ *[0-9]*% \]" "$log"
		echo "import reported errors (above)" >&2
		return 1
	fi
	echo "ok   import"
}
