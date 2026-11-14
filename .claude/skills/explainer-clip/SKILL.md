---
name: explainer-clip
description: Make a short voiced explainer clip (3D motion graphic in the Salvage Ink look, rendered to video) for one maths idea. Use when asked for an explainer clip, a topic intro video, or a new clip in tools/explainer-clips.
---

# Explainer clip

Read `tools/explainer-clips/README.md` first. It is the full process; this is the order of work.

Run it end to end without asking anyone. Reviewing roles check the output files afterwards.

1. Read the issue, the topic's entry in `curriculum/`, and `curriculum/moves.json`. Pick one idea, three to five beats, and at most one existing Spark move line per beat.
2. Copy `tools/explainer-clips/styles/shift-graph.js` to `styles/<id>.js` and rebuild the content, objects, timing, `VOICE`, `BEATS` and `sound(k)` for the new idea. Keep `lib/` unchanged; colours come from `PAL` in `lib/salvage-ink.js`.
3. Check every number and equation on screen by hand.
4. `node render.mjs <id> storyboard`, open each `out/<id>/beat-N.png`, and fix anything cropped, overlapping or too small to read on a phone. Repeat until the stills are right.
5. `node render.mjs <id> video`. If it exits non-zero, fix what `report.json` lists and render again.
6. Look at `first.png`, `last.png` and a few frames from the `.mp4` (`ffmpeg -ss <t> -i <id>.mp4 -frames:v 1 f.png`).
7. Attach `storyboard.html`, the `.mp4` and `report.json` to the issue, and list in the report what you assumed.

Do not write new voice lines, edit `lib/stage.js` or `lib/sound.js`, or commit `out/`.
