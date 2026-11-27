#!/usr/bin/env bash
# Landscape art is not in the core pack, precache or mobile portrait request set.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
output="${1:?export directory}"
build="${2:?build id}"
[[ "$build" =~ ^[A-Za-z0-9._-]+$ && "$build" != "." && "$build" != ".." ]] || {
  echo "invalid map-art build id" >&2; exit 1;
}
[[ -d "$output" && "$output" != "/" ]] || { echo "invalid export directory" >&2; exit 1; }
stage="$(mktemp -d "$output/.map-art-XXXXXX")"
trap 'rm -rf -- "$stage"' EXIT
mkdir "$stage/$build"
cp -- "$root/game/assets/map/overworld-wide.webp" "$stage/$build/overworld.webp"
for key in algebra functions geometry stats calculus; do
  cp -- "$root/game/assets/map/$key/background-wide.webp" "$stage/$build/$key.webp"
done
rm -rf -- "$output/map-art"
mv -- "$stage" "$output/map-art"
echo "ok   six landscape map assets, served only on demand"
