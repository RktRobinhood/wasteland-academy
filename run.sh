#!/usr/bin/env bash
# Launch the game in a 540x960 portrait window. Extra args go to Godot.
# Imports first (about 3 seconds), so this works from a fresh clone.
set -euo pipefail
source "$(dirname "$0")/scripts/godot-env.sh"
import_project >/dev/null
exec "$GODOT" --path "$GAME" "$@"
