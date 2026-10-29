#!/usr/bin/env bash
# Start or stop a headless Godot editor on this checkout's game/, for the Godot MCP.
#
#   scripts/mcp-editor.sh start   # waits until the MCP plugin has registered
#   scripts/mcp-editor.sh stop
#
# The editor runs in the background (pid and log in _scratch/). Its GDScript language
# server uses LSP_PORT (default 6025) so it doesn't fight Matt's editor for 6005, and
# its MCP server scans 6551-6560, so it never takes 6550, which is Matt's editor's.
set -euo pipefail
source "$(dirname "$0")/godot-env.sh"
pidfile="$ROOT/_scratch/mcp-editor.pid"
log="$ROOT/_scratch/mcp-editor.log"
mkdir -p "$ROOT/_scratch"

case "${1:-}" in
start)
	if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
		echo "already running (pid $(cat "$pidfile"))"
		exit 0
	fi
	sync_journey
	GODOT_MCP_EDITOR_PORT_MIN="${GODOT_MCP_EDITOR_PORT_MIN:-6551}" GODOT_MCP_EDITOR_PORT_MAX="${GODOT_MCP_EDITOR_PORT_MAX:-6560}" \
		setsid nohup "$GODOT" --headless --editor --path "$GAME" --lsp-port "${LSP_PORT:-6025}" >"$log" 2>&1 &
	echo $! >"$pidfile"
	for _ in $(seq 60); do
		if grep -q "\[MCPRegistry\] registered" "$log"; then
			grep -E "\[MCPServer\] listening|\[MCPRegistry\] registered" "$log"
			exit 0
		fi
		kill -0 "$(cat "$pidfile")" 2>/dev/null || break
		sleep 1
	done
	echo "editor did not register; see $log" >&2
	exit 1
	;;
stop)
	if [ -f "$pidfile" ]; then
		kill "$(cat "$pidfile")" 2>/dev/null || true
		rm -f "$pidfile"
	fi
	;;
*)
	echo "usage: $0 start|stop" >&2
	exit 2
	;;
esac
