# Explainer clips

Short voiced 3D motion graphics in the game's look, built in code and rendered to video with nobody watching. One clip explains one idea in 8 to 20 seconds: a chalkboard, Spark, a few objects, and three or four beats where the picture does the telling.

This is a prototype pipeline with one clip, `shift-graph`. It was started from the "Ink and Toon" style prompt on Futurepedia (see Provenance) and restyled to the Salvage Neon Bazaar palette.

## How this fits with the explainer player

The approved plan (FAL-375, FAL-429) is an explainer that is really the question engine: it replays any question's worked steps on a chalkboard, and a student can change a number and watch it redraw. Clips don't replace that. A clip is fixed video, so it can't follow a question's numbers. Use clips for the idea behind a topic, where the same picture serves every question: a lesson's demonstrate step, a topic intro, a "why this works" beside a worked solution.

Clips reuse what the player already has. Spark's voice comes from the existing move recordings in `game/assets/audio/voice/spark/moves/`, so Spark still never says a number and the board shows them. The renderer writes a caption file with Spark's words exactly as `curriculum/moves.json` has them.

three.js does not run inside Godot. A clip is rendered here and shipped as a video file. Godot's `VideoStreamPlayer` plays Ogg Theora only, so the renderer writes an `.ogv` next to the `.mp4`.

## Files

| Path | What it is |
|---|---|
| `lib/stage.js`, `lib/sound.js` | The rendering kit and the sound-effect kit, unchanged from the source prompt. Do not edit. |
| `lib/salvage-ink.js` | The house look: palette, fonts, fill and outline materials, lettering, caption slips, print finish. Change the look here and nowhere else. |
| `styles/shift-graph.js` | The prototype clip. Copy it to start a new one. |
| `styles/ink-toon.reference.js` | The original coffee example, kept as a reference for technique. It is not runnable with the house kit. |
| `player.html` | Plays a clip live with a scrub bar: `player.html?clip=<id>`. |
| `render.mjs` | Renders stills, video, sound, captions and a check report. |
| `out/<clip>/` | Render output. Not committed. |

## Make a clip

Nothing here waits for a person. Each step ends in files and an exit code that the next role checks.

1. **Pick the idea and the moves.** One idea, three to five beats. Choose the Spark lines from `curriculum/moves.json` that fit the beats, one line per beat at most. If no existing move fits a beat, leave that beat silent. Don't write new lines here: new lines go through the Writer and the Audio Designer as in FAL-427 and FAL-428.
2. **Write `styles/<id>.js`** from a copy of `styles/shift-graph.js`. Keep its structure: content block, timing table `T` on the 15-per-second grid, `VOICE`, `BEATS`, `build(S)` returning `update(t)`, then `sound(k)`. The rules that matter:
   - `update(t)` sets the whole scene for time `t`. Nothing builds up between calls. No `Math.random`, `Date` or timers; use `K.rng(seed)`.
   - Props move on twos, on the times in `T`. The camera alone moves every frame. Sounds use the same `T` times as the picture.
   - Build objects with the kit (`fill`, `solid`, `mark`, `lettering`, `caption`) and colours from `PAL`. No downloaded models, images or textures.
   - Size labels with `label(...)`: width is a share of the frame, so text stays readable on a phone. Keep everything that matters inside the frame in every beat.
   - Every number and equation on screen is checked by hand before the clip ships, as `writing/voice-sheets.md` requires.
   - A voice line starts at least 0.2 s after the last one ends and finishes before the last half second.
3. **Storyboard.** `node render.mjs <id> storyboard` writes one finished still per beat and `out/<id>/storyboard.html` with each beat's text, Spark's line, what changes, the camera and the sound. Look at the stills yourself and fix framing, overlap and legibility before going on. This takes about half a minute.
4. **Render.** `node render.mjs <id> video` writes `<id>.mp4` (for review), `<id>.ogv` (for Godot), `<id>.vtt` (captions) and `report.json`. A 14-second clip takes about ten minutes on a machine without a GPU.
5. **Checks.** The renderer exits non-zero and lists the problem in `report.json` when a page error occurs, a voice file is missing or doesn't match `moves.json`, lines overlap or run into the end, the first frame is empty, the duration is outside 5 to 30 seconds, or loudness is more than 1.5 LUFS from −15.
6. **Hand over.** Attach `storyboard.html`, the `.mp4` and `report.json` to the issue. The reviewing roles check the maths, the tone and the look from those files.

## Setup

```bash
npm ci
```

```bash
cd tools/explainer-clips && npm install
```

The first command, at the repo root, provides Playwright. The second provides three.js 0.187.0. `ffmpeg` must be on the path. Set `CHROMIUM_PATH` if Playwright's own browser is not installed.

## Not decided yet

- **Where clips play in the game.** The prototype is 1080×1350 so it sits above captions and controls on the 1080×1920 screen. Nothing in `game/` plays it yet.
- **Theora on the web export.** The `.ogv` has not been tried in the Godot web build. Check playback and file size there before making more clips; the alternative on the web is an HTML `<video>` over the canvas.
- **Where finished clips live.** Video is large for a repository. Decide between `game/assets/video/`, Git LFS or a release asset before the first clip ships.
- **Licence.** See Provenance.

## Provenance

`lib/stage.js`, `lib/sound.js` and `styles/ink-toon.reference.js` were copied on 2026-11-14 from the "Ink and Toon" style prompt on Futurepedia's AI motion style library, which hands them out for building animations in that style. The page states no licence. Rendered clips are our own work; whether the kit source itself may be redistributed in this repository is unconfirmed, so settle that before the repository or these files are made public. `lib/salvage-ink.js` is derived from the reference style's `inkKit`.
