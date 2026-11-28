#!/usr/bin/env bash
# Headless import, then the GDScript test suite. Exits non-zero on any failure.
set -euo pipefail
source "$(dirname "$0")/scripts/godot-env.sh"

# Each hosted run already has an isolated checkout. Use distinct log names for
# local serial shards too; shared .godot/import state is not safe for parallel runs.
suffix=""
for arg in "$@"; do
	case "$arg" in
		--shard=*)
			spec="${arg#--shard=}"
			if [[ "$spec" =~ ^[0-9]+/[0-9]+$ ]]; then
				suffix="-${spec/\//-}"
			fi
			;;
	esac
done
mkdir -p "$ROOT/_scratch"
log="$ROOT/_scratch/native-tests${suffix}.log"
(
	# An if/|| check around import_project would disable Bash errexit inside
	# its sync helpers. Keep their existing fail-fast behavior.
	(
		started=$SECONDS
		trap 'status=$?; echo "== import ended : $(( SECONDS - started )) s, exit $status =="; exit "$status"' EXIT
		echo "== import =="
		import_project
	)

	started=$SECONDS
	echo "== tests =="
	status=0
	"$GODOT" --headless --path "$GAME" --script res://tests/run_tests.gd -- "$@" || status=$?
	echo "== tests ended : $(( SECONDS - started )) s, exit $status =="
	exit "$status"
) 2>&1 | tee "$log"
