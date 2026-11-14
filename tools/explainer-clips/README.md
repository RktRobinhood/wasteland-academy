# Explainer clips: guide and kit

Short voiced motion graphics that explain one maths idea on a wasteland chalkboard. They are built in code with three.js and rendered to video with nobody watching. This folder holds the guide, the reusable style kit, one worked example (`shift-graph`) and the renderer.

![The four beats of the example clip](reference/shift-graph-storyboard.png)

## What a clip is

- **Just the maths.** A board, a graph or working, labels. No characters on screen, so nothing needs rigging. A talking head, if wanted, is separate art placed beside the video in the game.
- **One idea, 10 to 25 seconds, three to five beats.** Each beat is one change on the board and one teacher line.
- **Narrated by a teacher.** The voice belongs to a teacher character from `teachers.json`, recorded with the local voice model. A clip is fixed video, so the teacher can say this clip's numbers.
- **Fixed video.** three.js does not run inside Godot. The renderer writes an `.ogv` (Godot's `VideoStreamPlayer` plays Ogg Theora only), an `.mp4` for review and a `.vtt` caption file.

Clips sit beside the explainer player (FAL-375, FAL-429); they don't replace it. The player replays any question's worked steps and redraws when a number changes. A clip can't follow a question's numbers, so use it for the idea behind a topic, where one picture serves every question.

## The look: Salvage Ink

Everything that makes the style is in `lib/salvage-ink.js`. A clip that builds its objects with the kit comes out consistent without anyone tuning it.

| Part | Rule |
|---|---|
| Colour | Only `PAL` from the kit: the style guide's seven colours, each with a hand-picked shadow partner. Teal is the live curve or current object. Magenta marks the change (arrows, the key point, the number that matters). Dust is what was there before (ghosts, old positions). Paper is chalk: axes, labels, plain points. |
| Line | Every solid gets the ink outline (`solid`). Chalk marks on the board are flat strokes (`mark`, `strokes`). |
| Board | Slate slab in a rust frame on a charcoal dotted ground, lit by one hard sun. It fills the frame. Copy the board block from the example. |
| Type | Bangers for the one big word of a beat (`lettering`). Share Tech Mono on paper slips for equations and results (`caption`), and for chalk labels on the board. Fonts come from `game/assets/fonts/`. |
| Finish | The print filter (`ink.print()`): a teal ruled panel on a charcoal margin, wandering edges, paper tooth. No blur, bloom or grain. |
| Motion | Props move on twos (15 drawings a second) and snap between held poses with an overshoot. The camera alone moves on every frame: it drifts during a beat and whips to the next framing in a third of a second. |
| Frame | 1080×1350, so the video sits above captions and controls on the 1080×1920 game screen. |
| Text size | Labels are sized as a share of the frame width with `label(...)`. A slip is 0.4 to 0.65 of the width. At most two slips and one big word on screen at once. |

## Files

| Path | What it is |
|---|---|
| `lib/salvage-ink.js` | The house look. Change the look here and nowhere else. |
| `lib/stage.js`, `lib/sound.js` | The rendering kit and the sound-effect kit, unchanged from the source. Do not edit. |
| `styles/shift-graph.js` | The worked example. Copy it to start a clip. |
| `styles/ink-toon.reference.js` | The original coffee example, kept for technique (pouring, squash, steam). It does not run with the house kit. |
| `teachers.json` | Who can narrate, and where their voice sheet and brief are. |
| `player.html` | Plays a clip live with a scrub bar: `player.html?clip=<id>`. |
| `render.mjs` | Renders stills, video, sound, captions, the voice script and a check report. |
| `reference/` | Stills of the example, to compare a new clip against. |
| `out/<clip>/` | Render output. Not committed. |

## Make a clip

Nothing here waits for a person. Each stage ends in files and an exit code for the next role.

1. **Script.** Pick one idea and three to five beats. Write one teacher line per beat in that teacher's voice (`writing/voice-sheets.md`): 8 to 12 words, numbers allowed, and no "just", "easy", "simple", "obvious" or "guess". Check every number and equation by hand.
2. **Build.** Copy `styles/shift-graph.js` to `styles/<id>.js` and keep its structure: content block, timing table `T`, `VOICE`, `BEATS`, `build(S)` returning `update(t)`, then `sound(k)`.
   - `update(t)` sets the whole scene for time `t`. Nothing builds up between calls. No `Math.random`, `Date` or timers; use `K.rng(seed)`.
   - Every event time sits on the 15-per-second grid in `T`, and `sound(k)` uses the same times.
   - Give each line a `slot` (the longest its recording may run): about 0.4 s per word. Leave 0.2 s between slots and half a second clear at the end.
   - Build everything in code from the kit. No downloaded models, images or textures.
3. **Storyboard.** `node render.mjs <id> storyboard` writes one still per beat, `storyboard.html` and `voice-script.json`. Open the stills, compare them with `reference/`, and fix anything cropped, overlapping or too small. About half a minute.
4. **Voice.** The Audio Designer records each line in `voice-script.json` with the teacher's brief and saves it at the path given there (`game/assets/audio/voice/<teacher>/clips/<id>/01.ogg`, …). A take longer than its slot fails the check: record it shorter or re-time the beat.
5. **Render.** `node render.mjs <id> video` writes `<id>.mp4`, `<id>.ogv`, `<id>.vtt` and `report.json`. It mixes whatever recordings exist over the effects at −15 LUFS. Before the voice is recorded it still renders, and the report says `voicePending`.
6. **Hand over.** Attach `storyboard.html`, the `.mp4` and `report.json` to the issue. A clip is done when `report.json` says `"ready": true` and the reviewing roles have passed the maths, the tone and the look.

The renderer exits non-zero and lists the problem when the page throws an error, a line uses a ruled-out word, slots overlap or run into the end, a recording is longer than its slot, the teacher is not in `teachers.json`, the first frame is empty, the duration is outside 5 to 30 seconds, or loudness is more than 1.5 LUFS from −15.

## Teachers

`teachers.json` lists who can narrate. It holds Gear Mira, the one teacher with a voice sheet and a voice brief today. To give a location its own teacher, write the character's sheet and brief first, then add an entry with the regions they cover. The Australian wasteland teacher voice has no sheet or brief yet, so it is not listed.

## Setup

```bash
npm ci
```

```bash
cd tools/explainer-clips && npm install
```

The first command, at the repo root, provides Playwright. The second provides three.js 0.187.0. `ffmpeg` must be on the path. Set `CHROMIUM_PATH` if Playwright's own browser is not installed.

## Not decided yet

- **Playing clips in the game.** Nothing in `game/` plays a clip yet, and the `.ogv` has not been tried in the Godot web build. Check playback and file size there before making many clips; on the web the fallback is an HTML `<video>` over the canvas.
- **Where finished clips live.** Video is large for a repository. Choose between `game/assets/video/`, Git LFS and a release asset before the first clip ships.
- **Teacher voices.** The example's four lines are drafts in Gear Mira's voice and are not recorded.
- **Licence.** See Provenance.

## Provenance

`lib/stage.js`, `lib/sound.js` and `styles/ink-toon.reference.js` were copied on 2026-11-14 from the "Ink and Toon" style prompt in Futurepedia's motion style library, which hands them out for building animations in that style. The page states no licence. Rendered clips are our own work; whether the kit source may be redistributed in this repository is unconfirmed, so settle that before these files are made public. `lib/salvage-ink.js` is derived from the reference style's `inkKit`.
