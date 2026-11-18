#!/bin/sh
# Cuts the Thunderdome's magenta neon ring out of the overworld with PhotoCraft (board rect
# x 360-720, y 660-860), as a transparent layer: colour-range select on the magentas, layer
# via copy, drop the painting. Run from this folder.
set -e
photocraft-cli run ../../../map/overworld.png \
  --cmd image.crop --params '{"x":360,"y":660,"width":360,"height":200}' \
  --cmd select.colorRange --params '{"select":"sampledColors","colors":["#FF3DA7","#F040E0","#FF80F0"],"fuzziness":60}' \
  --cmd layer.new.layerViaCopy \
  --cmd layer.delete --params '{"layer":"Background"}' \
  --out neon-cut.png
