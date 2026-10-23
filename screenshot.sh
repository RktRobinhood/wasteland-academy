#!/usr/bin/env bash
# Render a scene in a private Xvfb display (software OpenGL, no GPU, no window on
# the desktop) and save it as a 1080x1920 PNG.
#
#   ./screenshot.sh [out.png] [res://scenes/some.tscn] [--option=value ...]
#
# Options after the scene go to game/tools/screenshot.gd (pass "" as the scene to keep
# the default), for example --frames=30.
#
# Defaults: _scratch/screenshots/main.png and the project's main scene.
# Needs Xvfb: either on PATH, or extracted (no root) with
#   mkdir -p ~/.local/opt/xvfb && cd ~/.local/opt/xvfb && apt-get download xvfb && dpkg-deb -x xvfb_*.deb root
set -euo pipefail
source "$(dirname "$0")/scripts/godot-env.sh"
import_project >/dev/null

out="${1:-$ROOT/_scratch/screenshots/main.png}"
scene="${2:-}"
mkdir -p "$(dirname "$out")"
out="$(cd "$(dirname "$out")" && pwd)/$(basename "$out")"

XVFB="${XVFB:-$(command -v Xvfb 2>/dev/null || true)}"
for c in "$HOME/.local/opt/xvfb/root/usr/bin/Xvfb" /home/matt/.local/opt/xvfb/root/usr/bin/Xvfb; do
	if [ -z "$XVFB" ] && [ -x "$c" ]; then XVFB="$c"; fi
done
if [ -z "$XVFB" ]; then
	echo "Xvfb not found (see the header of this script)." >&2
	exit 127
fi

# Pick a free display number.
disp=99
while [ -e "/tmp/.X11-unix/X$disp" ] || [ -e "/tmp/.X$disp-lock" ]; do disp=$((disp + 1)); done
"$XVFB" ":$disp" -screen 0 1080x1920x24 -nolisten tcp >/dev/null 2>&1 &
xpid=$!
trap 'kill "$xpid" 2>/dev/null || true' EXIT
for _ in $(seq 50); do [ -e "/tmp/.X11-unix/X$disp" ] && break; sleep 0.1; done

args=(--out="$out")
[ -n "$scene" ] && args+=(--scene="$scene")
args+=("${@:3}")
# Wayland vars are cleared so Godot uses the Xvfb display, not the desktop session.
env -u WAYLAND_DISPLAY DISPLAY=":$disp" "$GODOT" --path "$GAME" \
	--display-driver x11 --rendering-driver opengl3 --resolution 1080x1920 --position 0,0 \
	--script res://tools/screenshot.gd -- "${args[@]}"
