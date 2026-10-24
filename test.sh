#!/usr/bin/env bash
# Headless import, then the GDScript test suite. Exits non-zero on any failure.
set -euo pipefail
source "$(dirname "$0")/scripts/godot-env.sh"

echo "== import =="
import_project

echo "== tests =="
"$GODOT" --headless --path "$GAME" --script res://tests/run_tests.gd
