---
name: explainer-clip
description: Make a short voiced explainer clip (a maths idea on a chalkboard in the Salvage Ink look, rendered to video) or change the clip style kit. Use when asked for an explainer clip, a topic intro video, or work in tools/explainer-clips.
---

# Explainer clip

Read `tools/explainer-clips/README.md` first. It is the guide; this is the order of work.

Run end to end without asking anyone. Reviewing roles check the output files afterwards.

1. Read the issue and the topic's entry in `curriculum/`. Pick one idea and three to five beats. Just the maths: no characters on screen.
2. Pick the teacher from `tools/explainer-clips/teachers.json` and write one line per beat in their voice (`writing/voice-sheets.md`). Check every number and equation by hand.
3. Copy `styles/shift-graph.js` to `styles/<id>.js` and rebuild the content, timing, `VOICE`, `BEATS`, objects and `sound(k)`. Build with the kit and `PAL` only. Do not edit `lib/stage.js` or `lib/sound.js`; change the look only in `lib/salvage-ink.js`, and only when the issue asks for a style change.
4. `node render.mjs <id> storyboard`. Open each `out/<id>/beat-N.png`, compare with `reference/`, and fix anything cropped, overlapping or too small to read on a phone. Repeat until right.
5. Hand `out/<id>/voice-script.json` to the Audio Designer, or record the lines yourself if that is your role, saving each at the path it lists.
6. `node render.mjs <id> video`. If it exits non-zero, fix what it lists and render again.
7. Look at `first.png`, `last.png` and a few frames of the `.mp4` (`ffmpeg -ss <t> -i <id>.mp4 -frames:v 1 f.png`).
8. Attach `storyboard.html`, the `.mp4` and `report.json` to the issue and list what you assumed. The clip is done when the report says `"ready": true`.

Never commit `out/`.
