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

import_project() {
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
