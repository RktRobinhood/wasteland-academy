# The lesson player

Plays a tutor lesson from its script (#218). The scripts and their format are in
`writing/explainers/` (format 3, #216); the toys a lesson hosts are in `docs/TOYS.md`.

## The pieces

| File | What it is |
|---|---|
| `ui/lesson/lesson.gd` | `Lesson`: a script loaded, and the rules that need no screen: the recall version, the `back_to` group for a call, typed marking, not-yet lines, reactions |
| `ui/lesson/lesson_player.gd` | `LessonPlayer`: the board, captions, the player's actions, the toy, the part controls |
| `ui/lesson/scripted_run.gd` | `ScriptedRun`: answers every action as a player would, for the tests and the capture |
| `ui/lesson_screen.gd`, `scenes/lesson.tscn` | A lesson on its own, at `/?lesson` |
| `data/explainers/` | A copy of the scripts, `callbacks.json` and `reactions.json`. `node tools/game-explainers.mjs --write` after changing them; `tests/unit/game-explainers.test.mjs` fails while it is stale |
| `tests/test_lesson_player.gd` | The rules, a full scripted run of the exemplar at a 390 px phone, touch, the part controls, both recall versions, and every script played to its end |

## Opening a lesson

The draft lesson archive is not linked from the normal student map. The test build
offers one worked-example pilot as a **Lesson preview** at `/?teacher`, or directly
at `/?lesson-preview` (desktop: `-- --lesson-preview`). It uses Rook's original
Signal Tower worked example and a separate, optional engine-generated Try question.
Closing either returns to the choice. It never writes a watched record or run result.

- Test site: `/?lesson` plays the exemplar, One In, One Out. `/?lesson=<script id>` plays
  another. `&recall=watched` or `&recall=not_watched` forces a recall version.
  `&auto` lets the scripted run play it, and `&speed=1.5` starts faster.
- Editor: run `res://scenes/lesson.tscn` (F6 on the open scene).
- Command line: `godot --path game res://scenes/lesson.tscn -- --lesson --auto`. Add
  `--quit` to quit at the end without touching the save, as the capture does:
  `godot --path game --write-movie run.avi --fixed-fps 30 --resolution 540x960 res://scenes/lesson.tscn -- --lesson --auto --quit`.

## What it plays

Each section is a part, shown as its act and "part 3 of 10". A part can be replayed (its
board goes back to how the part began) or skipped (its board is written in full, so later
parts still read). Speed is 0.75×, 1× or 1.5×, and captions can be turned off.

| Beat | What the player does |
|---|---|
| A line | Shows its caption (with a `cue` in brackets), writes its board items, plays its clip. With no clip it holds about 0.36 s a word. `clear` wipes the board first. |
| A board item | Written in chalk. `strike` crosses out the keyed line. A `figure` shows its `alt` text, as figures aren't drawn yet. |
| `use` | The callback line from `callbacks.json`. |
| `predict` | A typed box with the keypad, a dial or a choice. The call is stored, never marked. |
| `back_to` | The group for the stored call: `match`, the value's, or `other` (also for a skipped call). |
| `ask` | Choices, or for `tap-line` the keyed board lines light up to be tapped. A slip plays the not-yet line and asks again (format 2 lessons move on). |
| `toy` | Hosted through `docs/TOYS.md`, one task at a time, each task's `then` after it. A free send can get an ack; a miss gets a slip. An `optional` toy offers "Try it" or "Skip". |
| `build` | Three tiles, shuffled. The right one goes on the board. A wrong one sparks off and goes grey, a slip plays, then its not-yet line, and the player picks again. |
| `typed` | A typed box. Right plays `right`. A slip plays a reaction, then the not-yet line for the wrong answer's misconception or the neutral one, and asks again. |
| A turn | An engine turn asks one live question of its cell, in its answer boxes, and marks it with `QuestionEngine.mark`. A fallback turn asks its parts in order, each marked on the first number in its answer. Right shows "Signal's out." in teal, writes the working and plays a right line. A slip shows "Static." in rust, plays the not-yet line for the mark's misconception (or a neutral one) and asks again. After a slip, "Show me" writes the working and moves on. |

Reactions follow `writing/explainers/README.md` ("Reactions"): a slip only on an item's
first miss, and an ack on every other free send or right tile. Each tutor's `ack` and
`slip` lines come from a shuffle bag kept for the session (FAL-1134): no line plays again
until every other line of its kind in that set has, and a refilled bag never starts with
the line that played last. There is no fail state and no score.

At the end the lesson's id goes in the save's `watched` list, which picks the recall
version next time.

## Audio

Rook's **One In, One Out** has existing takes; all 11 other draft scripts can play on
captions alone. Stock callbacks and reactions have their own takes. A line with a valid
clip holds for its length. The web build fetches its separate audio pack after sound is
enabled; captions continue to work before that or if the pack is unavailable.

`node tools/game-explainers.mjs --write` generates `data/explainers/voice-index.json`
from the source script, its accepted manifest and the SHA-256 of the OGG on disk. A
changed spoken line or missing or mismatched take never plays from its old filename.
Caption-only edits do not invalidate the recording. No new voice generation or spend
is part of this pilot.
