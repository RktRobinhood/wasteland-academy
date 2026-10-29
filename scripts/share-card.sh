#!/usr/bin/env bash
# Link previews for the web export (FAL-470). When the share card is there, copies it
# next to the export's index.html and points the page's link-preview tags (Open Graph
# and Twitter) at it. With no share card the page gets no tags, as before. Running it
# again replaces the tags, so it can be rerun with another page address.
#
#   scripts/share-card.sh <export dir> [page url] [share card]
#
# page url is where the export is published, ending in /: a link preview needs the
# image's full address. The default is the /next/ address on GitHub Pages. share card
# defaults to game/assets/title/share-card.png (or .jpg), 1200x630.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:?usage: scripts/share-card.sh <export dir> [page url] [share card]}"
url="${2:-https://rktrobinhood.github.io/wasteland-academy/next/}"
card="${3:-}"
if [ -z "$card" ]; then
	for ext in png jpg; do
		if [ -f "$ROOT/game/assets/title/share-card.$ext" ]; then card="$ROOT/game/assets/title/share-card.$ext"; break; fi
	done
fi
page="$out/index.html"
[ -f "$page" ] || { echo "no $page" >&2; exit 1; }

# Drop the tags a run before added.
sed -i '/data-share-card/d' "$page"
if [ -z "$card" ] || [ ! -f "$card" ]; then
	echo "ok   no share card: no link-preview tags"
	exit 0
fi

name="share-card.${card##*.}"
cp "$card" "$out/$name"
tags="<meta property=\"og:title\" content=\"Wasteland Academy\" data-share-card>\\
<meta property=\"og:description\" content=\"Same math. Different world.\" data-share-card>\\
<meta property=\"og:type\" content=\"website\" data-share-card>\\
<meta property=\"og:url\" content=\"$url\" data-share-card>\\
<meta property=\"og:image\" content=\"$url$name\" data-share-card>\\
<meta property=\"og:image:width\" content=\"1200\" data-share-card>\\
<meta property=\"og:image:height\" content=\"630\" data-share-card>\\
<meta name=\"twitter:card\" content=\"summary_large_image\" data-share-card>\\
<meta name=\"twitter:image\" content=\"$url$name\" data-share-card>"
sed -i "s#</head>#$tags\\
</head>#" "$page"
echo "ok   share card -> $url$name"
