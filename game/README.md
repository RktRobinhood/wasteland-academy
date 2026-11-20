# Wasteland Academy (Godot)

The Godot 4.7.2 game, planned on FAL-274. It is the game students play: a web build
published at the main address on GitHub Pages, which is also the testing host. App
builds come next, for PC first, then Android and iOS (#199). The legacy HTML game isn't
published for students (#197). All code is GDScript
(C# can't export to the web), and it uses the Compatibility renderer.

The toolchain is copied from The Unruly Atlas. The question engine has its own
reference, [`docs/QUESTION-ENGINE.md`](docs/QUESTION-ENGINE.md).

## Layout

```
game/
├── project.godot        ← portrait 1080x1920 base, "expand" stretch, Compatibility renderer
├── export_presets.cfg   ← one preset, "Web": no threads, no PWA
├── scenes/main.tscn     ← title screen (title, Spark, Play, Practice, Engine)
├── scenes/map.tscn      ← the map (ui/map.gd): world, zone, region screen (see "The map")
├── scenes/practice.tscn ← the practice screen (ui/practice.gd)
├── scenes/fight.tscn    ← the fight screen (ui/fight.gd), on the practice screen's card
├── scenes/explorer.tscn ← the engine explorer (ui/explorer.gd), at /?explore
├── scenes/explain.tscn  ← the explainer player on its own (ui/explain_screen.gd), at /?explain (see "Explainers")
├── ui/explainer.gd      ← the explainer player, an overlay any screen can open ("Watch it" on a worked solution)
├── ui/toys/             ← lesson toys (#217): LessonToy, the Toys registry, the relay (docs/TOYS.md)
├── scenes/toy.tscn      ← a toy on its own (ui/toy_screen.gd), at /?toy=relay
├── ui/lesson/           ← the lesson player (#218): plays a tutor lesson's script (docs/LESSONS.md)
├── scenes/lesson.tscn   ← a lesson on its own (ui/lesson_screen.gd), at /?lesson
├── data/explainers/     ← a copy of writing/explainers/ for the lesson player (tools/game-explainers.mjs)
├── engine/moves.gd, data/moves.json ← the explainer moves and the step map, tagged onto steps at runtime
├── scenes/study.tscn    ← the academic study screen (ui/study.gd), at /?study: MathsEngine only
├── engine/              ← the question engine: situations, views, marking, planner, save (docs/QUESTION-ENGINE.md)
├── engine/maths_engine.gd ← the reusable maths interface every screen asks (docs/MATHS-ENGINE.md)
├── engine/run.gd        ← a run: floors, fights, bosses, outcomes, lifelines, the hooks (see "Combat")
├── engine/dungeon.gd    ← floors by level, tiers, boss chains, start floors (see "The dungeon")
├── engine/map_link.gd   ← map links (#functions/quadratics), each region's zone, browser history, music by zone
├── engine/progress.gd   ← a region's accuracy, best floor, coverage and weakest skills
├── engine/courses.gd    ← the student's IB course and what it covers (see "Courses" in docs/QUESTION-ENGINE.md)
├── engine/tuning.gd     ← every combat number: timers, tiers, Scrap, stakes, lifelines, floors, chains, Bazaar prices
├── engine/bazaar.gd     ← the Bazaar's rules: upgrades, perks, cosmetics (see "The Bazaar")
├── engine/art_slots.gd  ← art by file name, with a fallback for each (see "Art slots")
├── engine/step.gd       ← a worked-solution step: a String, or {move, board} with a move tag (see docs/QUESTION-ENGINE.md)
├── engine/math_text.gd  ← cuts shown maths into text, powers, roots and stacked fractions (FAL-797)
├── ui/math_box.gd       ← maths as a box tree (row, text, fraction, power, root): layout, drawing, to_text() for Expr; ui/math_label.gd draws one and wraps it
├── ui/math_entry.gd     ← a box typed in notation (FAL-812, FAL-813): stacked fractions, powers, roots, ◀ ▶, text in the syntax Answer and Expr read
├── engine/expr.gd       ← the expression engine (TinyExpr port): the calculator and every typed answer
├── engine/brent.gd, graph_tools.gd ← Brent's root finder and minimiser (SciPy port); zeros, extrema, intersections
├── ui/calculator.gd     ← the in-game calculator (see "The calculator"); ui/calc_graph.gd its graph, ui/keypad.gd the keys
├── ui/credits.gd, data/credits.json ← the credits, from the title screen: third-party code, fonts, sound
├── data/bosses.json, enemies.json, frames.json ← boss names and taunts, the enemy pool, name-plate frames
├── scenes/bazaar.tscn   ← the Bazaar screen (ui/bazaar.gd); ui/name_plate.gd draws the plate
├── ui/                  ← screens and the graph view
├── data/catalogue.json  ← generated from curriculum/question-types.json (don't edit)
├── scenes/audio_hud.tscn ← the AudioHud autoload: speaker icon, gear, settings screen
├── scenes/settings.tscn ← the sound settings screen
├── audio/               ← the Audio autoload, the cue tables, the bus layout, the UI theme
├── data/courses.json    ← the four IB courses and their status, if present (FAL-393)
├── assets/              ← art and fonts copied from the repo's assets/ and vendor/fonts/
├── tests/               ← headless test runner and tests
├── tools/screenshot.gd  ← used by ../screenshot.sh
├── tools/export_questions.gd  ← used by ../tools/check-answers
├── tools/course_report.gd  ← used by ../tools/course-audit
├── tools/stress_questions.gd  ← used by ../tools/stress-questions
├── tools/feedback_check.gd    ← used by ../tools/feedback-check
├── tools/bazaar_sim.gd, bazaar_balance.gd  ← the Bazaar's balance check and price table
├── addons/godot_mcp_toolkit/  ← editor plugin for the Godot MCP (see docs/MCP-NOTES.md)
├── docs/QUESTION-ENGINE.md ← the question engine reference
├── docs/TOYS.md         ← the interface every lesson toy shares
├── docs/LESSONS.md      ← the lesson player: what it plays, the test page, the scripted run
└── docs/MCP-NOTES.md
```

`config/name` is "Wasteland Academy", so its `user://` folder is its own, not the Atlas's.

Art is imported with mipmaps on (`mipmaps/generate=true` in each `.import`) and drawn
with linear mipmap filtering, so it stays smooth at phone and PC sizes. New art imports
lossy too (see "Art slots"): `project.godot`'s `[importer_defaults]` give a new file
both, so let Godot write its `.import`.

## Sound

Two autoloads, added on FAL-385. `Audio` (`audio/audio.gd`) owns the music, the effects
and the four settings; `AudioHud` (`scenes/audio_hud.tscn`) is the speaker icon and the
gear that sit above every scene, with the settings screen behind the gear.

```gdscript
Audio.play_location("signal-tower")  # crossfade to that location's loop
Audio.play_sfx("correct")            # one short effect
Audio.sound_enabled = true           # what the speaker icon switches
```

- **Sound starts off**, on a fresh install and for every student in a classroom. Nothing
  is decoded or played until the speaker is tapped, which also satisfies the browser rule
  that audio needs a gesture first.
- The four settings (`sound_enabled`, `music_volume`, `sfx_volume`, `voice_volume`) save to
  `user://settings.cfg` the moment they change, and load at boot.
- Buses: Master, with **Music**, **SFX** and **Voice** under it (`audio/bus_layout.tres`).
  Each slider moves one bus; turning sound off mutes them all and stops the players.
  `Audio.play_voice(stream, speed)` plays Spark's explainer line on Voice and ducks the
  music 12 dB under it; a pitch shift on the bus keeps 0.75× and 1.5× at Spark's pitch.
- Which loop plays at which location, and the alternate seed waiting on Matt's listening
  pass, is the one table in `audio/music_tracks.gd`. The effect cues mirror the HTML
  game's `js/sfx.js` and live in `audio/sfx_cues.gd`.
- Every file in `assets/audio/` has its licence entry in `../assets/audio/CREDITS.md`.
  Nothing ships without one.
- The map and the runs choose the loop (FAL-417): the world map plays `overworld`, an
  zone and its runs play the zone's loop, and a mini-boss or boss its `-boss` loop
  (`MapLink.music_for`). Each of the five zones has its own pair (`MapLink.MUSIC`:
  `scrap-fields`, `signal-tower`, `dry-flats`, `radio-spires`, `engine-core`), and the
  Thunderdome's screen and runs play `thunderdome`, bosses too, so all twelve loops play
  somewhere (FAL-925). The settings screen has only the four settings.
- Fights play the effects (FAL-925, `ui/fight.gd`): `open` as a mini-boss or boss steps
  up, `correct` for a hit (right, glancing or late), `retry` for a miss or a timeout,
  `clear` when an enemy falls (in place of the hit's), `hint` for a lifeline, and
  `reward` when the summary banks Scrap. The settings screen and the HUD play `confirm`,
  and the Bazaar `reward` and `confirm`. With sound off nothing is heard;
  `Audio.last_sfx` still records the cue asked for, for tests.

## Explainers

FAL-429, on the move format from FAL-425/426. A worked solution plays like a video on a
chalkboard (`ui/explainer.gd`): one chapter per step, the chalk writing the step's board
while Spark says its move's line, a random one of its two takes
(`assets/audio/voice/spark/moves/<move>_1.ogg`, `_2.ogg`). Play and pause, a scrub bar with
a mark per step, replay this step, CC (on to start, since sound starts off) and 0.75×, 1×
and 1.5×. "New numbers" makes the same view on a new seed; "Your turn", at the end on the
practice screen, sets that view with new numbers. A step with no move plays silent under
its own chalk line as the caption.

- **Tagging.** `QuestionEngine._build` passes every solution's steps through `Moves.tag`,
  which looks up `type/unknown/angle` in `data/moves.json` with the solution's step count
  (`<rep>/<n>` first, then `<n>`) and the branches, and makes each mapped step
  `{"move", "board"}`. A method or step count the map doesn't have stays plain. The copy
  is generated: `node tools/game-moves.mjs --write` after changing `curriculum/moves.json`
  or `moves-map.json` (`tests/unit/game-moves.test.mjs` fails while it is stale).
- **Ways in.** "Watch it" under every worked solution with a tagged step, on the practice
  screen and the fight's card; `/?explain` on its own (a quadratic, or `&view=…&seed=…` as
  the practice screen takes; `&t=4.5` opens paused that far in, for screenshots). Any
  screen can open one: `add_child(Explainer.make(question, solution))`.
- **Look.** "Salvage Ink" (`tools/explainer-clips/lib/salvage-ink.js`): slate board,
  iron frame with bolts, chalk in the paper colour, Bangers and Share Tech Mono. The frame
  and board are drawn placeholders until there is art.
- `tests/test_explainer.gd` checks every move used exists and has both voice files, and
  prints how many built methods end up with a tagged step.

## Scripts (run from the repo root)

Godot is found on `PATH`, at `~/.local/bin/godot`, or from `GODOT=/path/to/godot`.

| Command | What it does |
|---|---|
| `./run.sh` | Opens the game in a 540x960 window |
| `./test.sh` | Headless import, then every `game/tests/test_*.gd`. Exits non-zero on any failure |
| `./export.sh [dir]` | Web export into `build/next/` (or `dir`). Fetches the Web export templates first if Godot can't find them |
| `./screenshot.sh [out.png] [scene]` | Renders a scene at 1080x1920 in a private Xvfb display |
| `node scripts/web-screenshot.mjs [export dir] [out dir] [name=?query ...]` | Serves an export at `/wasteland-academy/next/` and screenshots it in headless Chromium at 390x844 and 1280x800, plus each named deep link. Fails if the page logs an error |
| `tools/check-answers` | The SymPy answer checker (see docs/QUESTION-ENGINE.md) |
| `tools/stress-questions [--from=51] [--to=2250]` | The seed sweep (see docs/QUESTION-ENGINE.md) |
| `tools/feedback-check [--seeds=12] [--rows=file.tsv] [--all]` | What a student reads after a wrong answer (see docs/QUESTION-ENGINE.md). CI runs it in its own job |
| `tools/course-audit` | Where the engine stands for each IB course: skills, types and built questions (see docs/QUESTION-ENGINE.md). `--write` also rewrites `curriculum/COVERAGE.md` |
| `scripts/mcp-editor.sh start\|stop` | Headless editor on `game/` for the Godot MCP |
| `python3 -I scripts/mcp_call.py <tool> '<json>' ...` | Calls Godot MCP tools through that editor |

## Question engine

The full reference is [`docs/QUESTION-ENGINE.md`](docs/QUESTION-ENGINE.md): recipes, situations and views, answers and marking, courses, and every region's types. Its last part, "Checking the engine", covers the SymPy answer checker, the seed sweep, the feedback check and the course audit.

In short: the engine plans from situations and views on the catalogue in `curriculum/question-types.json`. The game reads a generated copy, `data/catalogue.json`: rerun `node tools/game-catalogue.mjs --write` after changing the catalogue. `engine/answer.gd` marks every answer, and `engine/expr.gd` reads what a student types.

## Combat

A run (`engine/run.gd`) takes a region, a start floor and a seed, and plays floors of
fights until the player's HP reaches 0 or they quit (see "The dungeon"). Each fight is
an enemy of tier D1 to D5 (the HTML game's `js/combat.js` table). Each question is the
planner's next cell from the floor's cells (`Planner.next(save, now, {"cells",
"prefer_types", "probes": false, "salt"})`). At the end, the summary shows the floor
reached, the bosses beaten, the questions right, the fights won, the Scrap earned and
the skills missed, and the Scrap goes into the save.

`Run` has no UI, so a test plays a whole run: `start()`, `tick(delta)`,
`answer(response)`, `next()`, `quit()`, and the lifelines `use_fifty()`, `use_hint()`
and `use_freeze()`. The fight screen (`ui/fight.gd`) extends the practice screen and
draws the run: the player's HP, the enemy in the scene, the timer bar, the lifelines, the card and the
summary, with the journey scene (FAL-331, below) at the top. The lifeline row
ends with the question's paper: "No calculator", or on Paper 2 the Calculator button.

- **One settings file.** Every number is in `engine/tuning.gd` (`Tuning`): HP, the
  tiers, Scrap, the timers, the late zone, the stakes table, the lifelines and "Another
  way". The dungeon (G4) and the Bazaar (G6) use it too.
- **Timers (Q6).** Seconds = marks × minutes per mark × 60, plus 15 for a typed answer,
  never under 45. Minutes per mark: 1.5 on floor 1, 1.25 on floor 2, 1.0 on floor 3,
  then 0.1 less a floor down to 0.6. The bar drains green, orange (under half), red
  (the last 20%, the late zone). Time Freeze stops it for 15 s.
- **Outcomes.** right, glancing, late (right in the late zone), wrong and timeout. Each
  goes through **one resolve step**, `Run.resolve(outcome, enemy, stakes, modifiers)`,
  with a **stakes table**: hits off the enemy, the share of the enemy's damage the player
  takes, flat extra damage, and the share of the tier's Scrap. `Tuning.STAKES` is today's
  table; encounters (FAL-349) pass their own.

  | Outcome | Enemy | You | Scrap |
  |---|---|---|---|
  | right | 1 hit (10 HP) | 0 | 100% |
  | glancing | ½ hit | 0 | 50% |
  | late | 1 hit | 25% of its damage | 60% |
  | wrong | 0 | its damage | 0 |
  | timeout | 0 | its damage + 10 | 0 |

- **Worked solutions (Q5).** After a wrong answer or a timeout the card shows the worked
  solution, with a tab per method, before the next question. Hint shows its first step.
- **"Another way" (FAL-310).** After a right answer on floor 2 or deeper, one time in 4
  (`Tuning.ANOTHER_WAY_CHANCE`), the next question is the same one (same numbers, made
  with the view's `same_angle`) asked by the next angle the type lists for that unknown,
  for bonus Scrap. Only where the unknown has more than one angle.
- **Modifiers (class plan phase 0, FAL-291).** Every damage, heal, Scrap and time value,
  the starting HP, each lifeline's starting charges and what one use costs, pass through
  `run.modifiers.apply(kind, value, ctx)` (`engine/modifiers.gd`), which returns it
  unchanged until something is added. The Bazaar (G6) and classes (FAL-308) add a
  Callable.
- **Fight slots (FAL-347).** `Run.slot_kind(seed, floor, fight)` says what a slot is:
  "fight", "encounter" or "cell". It always says "fight" until FAL-349. The run asks it
  for every slot, bosses too.

### The dungeon (FAL-415)

`engine/dungeon.gd` (`Dungeon`) holds the rules and no state; every number is in the
dungeon part of `Tuning`. Q4, Q6, Q9 and Q14 are on the FAL-274 plan.

- **Floors.** A floor is 10 fights: a mini-boss at fight 5 and a boss at fight 10.
  Beating the boss opens the next floor in the same run. Floor 1 serves levels 0 to 2,
  floor 2 levels 2 and 3, floor 3 levels 3 and 4, and floor 4 and deeper every level,
  0 to 5, and every type of the region. Link types (`kind: "link"`, the `fn-link-*`
  types) play as level 5: only on bosses and from floor 4.
- **Floor tables.** By levels alone every Quadratics exam type lands on floors 1, 2
  and 3, so `Tuning.FLOOR_TYPES` gives Quadratics Q4's floors: 1 the features type (axis
  and vertex), 2 the three forms, conditions and solving, 3 the discriminant,
  inequalities and the curve-and-line type. A table type keeps the floor's top level; a
  type new on a floor also brings its easier cells (floor 3 starts the discriminant at
  "how many roots"). A floor whose table types aren't built yet uses the level rule. A
  region without a table uses levels only.
- **Warm-ups.** The first fight of floor 1 opens with `Tuning.WARMUPS` (2) level-0
  questions (the `fn-pre-*` types). After a miss, the next question is a prior-learning
  type whose `supports` lists a skill of the missed unknown, where the region has one.
  Both wait for a region's `fn-pre-*` situations to be built.
- **The mix (Q14).** The planner is handed the floor's cells and the types not yet asked
  on the floor (`prefer_types`): while one is left, it picks among those, by its three
  rules. So every type on a floor appears on it (the test plays 200 floors). With
  "Exam-style only" on, exam frequency is the only rule, as before.
- **Tiers.** D1 or D2 for a normal fight, D3 for the mini-boss and D5 for the boss
  (`js/combat.js`), all one tier higher on floors 4 and 5, two on 6 and 7, three from 8,
  capped at D5. From floor 4 an enemy's damage also grows 10% a floor. The run's tier is
  the one `question_opened` sends, for the journey strip.
- **Timers.** `Tuning.seconds_for(marks, floor, typed)` with the floor being played, so
  the clock tightens as a run goes down.
- **Mini-bosses and bosses (Q9).** `Tuning.CHAINS` writes each type's catalogue `chain`
  as unknowns in order (a step may name another type on the same situation). A mini-boss
  asks 2 consecutive steps and a boss 3 or 4, by the seed, from a type on the floor
  weighted by its Section B count. `QuestionEngine.make_chain(steps, seed)` makes them
  all on one situation, generated once from all their needs together
  (`merge_needs`). Each part has its own clock from its own marks. A wrong part costs HP
  and shows the right value, and the next part carries it (`carried`: the part before's
  right answer, shown in a box above the question), whatever was answered. The enemy bar
  counts parts; surviving every part beats it. The result says so ("Part (a) done · 4 of 5
  parts to go"), a hit without enemy HP and a miss without a hit, and the floor line keeps
  the part answered until Next part (FAL-970). A boss ends with one link question where
  the region has one built (`Tuning.BOSS_LINK_PART`). A floor with no chain built has a
  normal fight at the boss's tier instead.
- **The "boss beaten" event.** The heal `Tuning.BOSS_HEAL` (0) goes through
  `modifiers.apply("boss_heal", ...)` with `ctx.boss` "mini" or "boss", then through
  `heal`, then `boss_beaten(floor, kind)` fires. Second Wind (G6) adds 20 there.
- **Start floor.** `Dungeon.start_floors(save, region)` is floor 1 and, for every floor
  N whose boss the player has beaten, floor N + 1. The fight screen opens on a floor select with those floors.
  The save keeps `dungeon[region] = {"best", "beaten"}`.
- **All regions.** Each zone's all-regions dungeon mixes every built type of its
  regions: `Dungeon.all_of(island)`, which is `"all"` (`Dungeon.ALL`) on the Functions
  zone, the id saves and links already had, and `"all-<island>"` on the others
  (`"all-calculus"`). The map's "All regions" spot is `#<island>/all` in every zone.
- **The Thunderdome** (FAL-925). Region `"thunderdome"` (`Dungeon.THUNDERDOME`) mixes
  every built type of every zone, with the same floors, tiers, bosses and records as a
  region. Its screen is `#thunderdome`, off the world map.
- **Bosses in every zone.** Only Functions types have chains so far (`Tuning.CHAINS`),
  so on the other zones the mini-boss and the boss are a single fight at their tier
  (D3 and D5, raised on deeper floors), named from `data/bosses.json` by zone (see "Art
  slots"). A type's chain makes them chained parts there with no other change.

### Journey strip events

The run emits six signals for views such as the journey strip (FAL-331). They are view
only: nothing in the run waits on them, and a run plays the same with none connected
(`test_combat.gd` checks).

| Signal | When |
|---|---|
| `run_started(region, avatar, seed)` | `start()`, before the first fight |
| `question_opened(fight, tier)` | each question opens, fight number from 1 |
| `answer_resolved(outcome)` | each answer or timeout: right, glancing, late, wrong or timeout |
| `run_ended(summary)` | death or quit, after the Scrap is banked |
| `floor_started(floor)` | a floor opens: the start floor, then each one after its boss falls |
| `boss_beaten(floor, kind)` | a mini-boss (`"mini"`) or boss (`"boss"`) falls, after its heal |

### The question card's frame

On the fight screen the question scrolls inside the reel's rusted metal frame
(`ui/card_frame.gd`, art `assets/ui/question-card.png`, copied to `game/assets/ui/`). It is
a 9-slice with 40 px slices and a transparent centre, drawn scaled over the card's colour:
50 base units thick on a phone, 80 on a wide window. The floor select and the summary
have no frame. A table wider than the card scrolls sideways by itself, and a word-choice
answer wider than `PICK_WIDE` wraps on its own line (`ui/practice.gd`).

On a touch screen a vertical swipe scrolls the card wherever it starts (FAL-735): anything
on the card that would stop a touch passes it on (`_let_swipes_through()`), and a touch
only counts as a swipe past `SWIPE_DEADZONE`, so a tap still picks. A Control that isn't a
button uses `_tapped()`, not a press, or a swipe would pick it. After an answer,
`_reveal_result()` scrolls to the result and Next; a result too tall to show with Next
keeps the result in view. `tests/test_swipe.gd` drives this with real touch events.

### The journey strip

The side-view scene at the top of the fight screen (FAL-331, plan on FAL-289): the
Learner walks right with Spark over the region's parallax, and each answer plays out as
a beat: Explore, Puzzle, Fight or Boss. It is a view only. It never sends anything back,
never takes input (`mouse_filter` is IGNORE), and every call reaches it deferred, so the
run plays the same with the strip on, off or broken (`test_journey.gd` checks all three).

- **The sheets.** `JourneyAssets.scan()` reads every atlas and JSON under
  `assets/journey/`, found by folder (`party/`, `enemies/`, `weapons/`, one folder per
  region), so a new sheet that follows `assets/journey/README.md` needs no code change.
  `scripts/godot-env.sh` copies `assets/journey/` into `game/assets/journey/` at import
  time (git ignores the copy), and the Web preset exports its JSON.
- **The calls** (`journey/journey_stage.gd`, `scenes/journey_stage.tscn`):

  | Call | When |
  |---|---|
  | `start_run(region, avatar, weapon, seed)` | the run starts; hides the strip if the avatar has no sheet |
  | `fight_ahead(fight, tier, questions)` | a fight is won: the next encounter starts past the right edge and comes on |
  | `fight_started(fight, tier, questions)` | a fight opens; tier 1 to 5 (0: none yet, taken as D1 to D2). Sets up the encounter if `fight_ahead` didn't |
  | `question_opened(index)` | a question opens: a walk stops where it is, a beat jumps to its end, then only idle loops play |
  | `answer_resolved(outcome, info)` | right, wrong, timeout, late or partial; `info.damage` sets the damage number |
  | `fight_ended()` | the fight is won or left: victory or retreat, then walk on |
  | `run_ended()` | death or quit |
  | `set_weapon(name)` | cosmetic; the Learner isn't redrawn |

- **Choosing the beat.** `JourneyBeats.encounter(seed, fight, tier, roster, questions)`
  is a pure function: D1 Explore, D2 a fight with 1 to 3 monsters half the time and
  otherwise Explore or Puzzle, D3 a fight with 1 to 2 monsters (now and then a Puzzle), D4 a fight (a bandit ambush or 2 to 3 monsters), D5 the boss.
  Fight 5 is the mini-boss and fight 10 the boss, whatever the tier. It uses only sheets
  that exist.
- **The fight screen.** `JourneyLink.attach(run, stage, save)` turns the run's signals
  (above) into these calls: the run's region goes to its zone's journey region
  (`functions` is `signal-tower`), a glancing hit is `partial`, and the avatar is the
  save's `profile.avatar` ("female" when there is none, as the HTML game does). A region
  with no journey art, or an avatar with no sheet, hides the strip. A won fight names
  the next one from `Dungeon.tier_for()`, which doesn't touch the run.
- **Nothing pops in.** An encounter starts past the right edge (`_width()`, not a fixed
  distance) and comes on with the ground at walking speed, a leg of about 6 s on a
  phone. A question stops the leg where it is. The next answer finishes it at
  `CATCH_UP` before its beat plays, and the next question can cut that short, so the
  strip never delays the run. The first encounter of a run opens the screen already in
  place. Raiders in an ambush drop from the top of the frame. With reduced motion the
  encounter stands in place.
- **Calm and reduced motion.** While a question is open only idle loops play. A hit
  gets one 80 ms flash, at most 3 a second. `reduced_motion` swaps poses and stops the
  scroll.
- **Jobs, not enemies.** On an Explore or Puzzle beat the fight screen talks about the
  job: the overlay, the button, the result lines and "Walk on" come from `label`, `verb`,
  `hit` and `done` in the prop's JSON, so a new prop needs no code. The screen gets them
  from `JourneyLink.job_words()`, which works out the encounter from the same inputs as
  the strip, so the strip sends nothing back. With no strip showing they read as a fight.
- **The demo.** `/?journey=demo` (desktop: `-- --journey=demo`) replays the FAL-293
  reel's script with a dummy question card under the strip (`ui/journey_demo.gd`).
  Add `&motion=reduced` for reduced motion, or `&avatar=learner-male` for that sheet (an
  avatar with no sheet hides the strip, as it does in a run).

### Powers, fractions and answer boxes on the card

Questions are written with a caret (`e^(4x − 3)`, `a × 10^k`) and a slash (`(x + 1)/(x − 1)`), as
`tools/check_answers.py` parses them back and Unicode has no superscript `.` or `/`.
`UiTheme.math()` draws them as on paper (FAL-743, FAL-797): `MathText` cuts the
text into powers, roots and fractions, `MathBox` lays them out, and a `MathLabel` draws them, with
powers raised, roots under a radical sign and fractions stacked over a bar. Text with none stays a
plain `Label`. A sign stays in front of the bar (−3/4), a bracket round a whole top or bottom goes,
fractions nest, a fraction in a power keeps the power's size, and units (m/s), P/Y and word pairs
(zero/root) are left as written; `test_fractions.gd` has the rules. Write a coefficient so it reads
one way: `(3/2)x` or `3x/2`, and `π²/4`, not `1/4π²`, which stacks as 1/(4π²).

It is used for the prompt, the question's lines and table, the text around an answer box, the
options, the word choices, the solution tabs, the worked steps, the feedback, the hint, the type
name above the question and a run's skills missed. `UiTheme.math_button()` puts maths on a button:
a `Button` can't draw it, so a `MathLabel` is drawn on it in the button's colours, and the button
is sized to it. Graph labels still show the caret, as `draw_string` draws them.

A `MathLabel` wraps at spaces, never inside a fraction or a power. A root too wide for its line is
written `√(…)` so it wraps. A line with a fraction is taller, so a few more fight cards need a swipe
at the `FitBox` floor (4.3% of cells at 390x844, from 3.6%); none is wider than its card. Before
a card scrolls, a control tagged `FitBox.LEAST` gives up height to that least, when that lets the
whole card fit: a curve graph (`GraphView`) gives up to a quarter, so a 4-option graph question
shows Attack whole on a 390x844 phone (FAL-970).

An answer box starts 150 wide and grows as it's typed in, up to `Practice.SLOT_CHARS`, which still
fits the fight's card on a 360 px phone. It isn't sized from the answer, as that would give away
how long the answer is.

An answer box is typed in notation, as on a TI-84 Plus CE in MathPrint mode (`ui/math_entry.gd`,
FAL-812): a `MathEntry` holds a `MathBox` tree and draws it with a cursor, so a typed fraction looks
like a shown one. The fraction key (or `/` on a keyboard) makes a number just before the cursor the
top and moves to the bottom; with no number there the fraction starts empty, cursor in the top. An
empty part shows a dashed box. ◀ ▶ (and the arrow keys) move through the top, then the bottom, then
out; ↑ ↓ move between top and bottom, and a tap puts the cursor where it lands. Del at the start of
an empty bottom removes the fraction and keeps the top. Minus shows as a true minus. Marking is
unchanged: `text` is the tree in the syntax `Answer.parse_number` reads, a fraction as `(n)/(d)`,
and setting `text` (tests, autoplay) builds the same tree, so `3/2` shows stacked.
`test_math_entry.gd` has the key sequences.

### Deep links

The practice screen takes deep links, for screenshots and for sending someone a
question: `/?view=<type>/<unknown>/<rep>/<angle>/<value|mcq>&seed=3`, or
`<type>/probe/<n>` for a concept probe. Add `&autoplay=right` (or `wrong`) to answer it
at once, and `&paper=1` or `2` for that paper where the cell can make it. On a Paper 2
question, `&calc=sci` or `&calc=graph` opens the calculator, with `&do=expr;expr` worked
out in Scientific mode, or `&y1=`, `&y2=`, `&win=xmin,xmax,ymin,ymax`,
`&tool=zero|max|min|intersect` and `&deg=1` in Graph mode (the screenshots use these).
The fight screen takes `/?play=quadratics&seed=3&floor=1`, with
`&autoplay=right`, `wrong`, or `lose` (wrong answers to the end, for the summary). `play`
is a region id or `all`. `floor` must be one the save may start on, else the run starts
on floor 1. `&fight=5` or `&fight=10` starts at the mini-boss or boss (such a run records
no floors), and `&autoplay=carry` answers its first part wrong and opens the next, to show
the value carried on. `&select=1` shows the floor select. `play` is any region id, an
zone's all-regions dungeon (`all`, `all-algebra`) or `thunderdome`.

The map takes a hash: `/#functions/quadratics` opens that region's screen,
`/#functions` the zone, `/#calculus/all` a zone's all-regions dungeon,
`/#thunderdome` the Thunderdome and `/#world` the world map (see "The map").

### The study screen

`/?study` (FAL-798, #134): the maths engine in a plain academic presentation, with no
game theme, art, sound controls, combat or rewards. It asks, marks and explains through
`MathsEngine` only, and keeps its evidence in `user://study.json`, apart from the game's
save. `/?study&view=<type>/<unknown>/<rep>/<angle>/<format>&seed=3` opens one question, and
`&autoplay=right` (or `wrong`) answers it at once.
See [docs/MATHS-ENGINE.md](docs/MATHS-ENGINE.md).

### The engine explorer

`/?explore`, or "Engine" on the title screen (FAL-391). Pick a course, a topic and
a question class, then "Asked for", "Shown as", "Method" and the format, and play the
question as on the practice screen. Nothing is saved. Question classes come from the
catalogue: a type is live when its situation is built, so a new situation shows up
with no change here, and the rest are listed greyed out. "New question" draws a random
seed; "Ask it another way" keeps the seed and the family's situation and asks the next
unknown of the family; "Show 10 versions" shows ten seeds with their answers. The class
size line counts `QuestionEngine.cells()` of the picked course. Courses come from
`data/courses.json` when it is there, and from a built-in list when it isn't. A course
is live when the engine covers a built class for it (`Courses`, see "Courses" in docs/QUESTION-ENGINE.md), whatever
the syllabus map's status: AA HL plays every class AA SL does, AI SL and AI HL the ones
whose skills they share, and a built class they don't cover is greyed out as "not in AI
SL". A course the engine doesn't list shows the syllabus note and asks nothing. Phones
show the choices and the question one at a time; landscape shows them side by side.

The URL follows the screen, so a state can be bookmarked:
`/?explore&view=<type>/<unknown>/<rep>/<angle>/<value|mcq>&seed=3`, plus
`&ten=1` for ten versions or `&autoplay=right` (or `wrong`).

## The calculator

Paper 2 questions get the in-game calculator (FAL-419), a backup for a forgotten
TI-Nspire: the Calculator button in the practice card's top row, or at the end of the
fight screen's lifeline row. Paper 1 questions show "No calculator" and can't open it.
The clock keeps running while it is open, it costs no lifeline and no Scrap, and a
Paper 1 question next closes it. The spec is on FAL-274 (Functions recipes, "In-game
calculator").

- **Scientific mode**: the keypad (the typed answers' keys, `ui/keypad.gd`, with the
  function rows above them), recent results (tap one to use it again), Ans, degrees or
  radians, and results to 6 significant figures (`engine/calc_format.gd`), so the
  student still rounds to 3 s.f.
- **Typed in notation** (FAL-813), as a TI-84 Plus CE in MathPrint mode: the input is a
  `MathEntry` (`ui/math_entry.gd`). The fraction key stacks a fraction (what is before
  the cursor, a number, Ans, π, a bracket or a power, becomes its top), `^` raises a
  power to type into and `√` puts a bar over what is typed under it; ◀ ▶ (or a `)` with
  no bracket open) leave them, and Del at the start of a power or root takes it away and
  keeps what is in it. A function or Ans is one key, which Del takes away whole. Each
  recent result shows what was typed, in notation, with the result to the right below
  it. An exact result that is a fraction (bottom under 10000) shows stacked; S⇔D
  switches the last result between the fraction and its decimal, and finds a fraction
  for a decimal that has one, as the TI's ►F◄►D. The input gives `Expr` the same text
  it read before: a fraction as `(n)/(d)`, a power `^(…)`, a root `√(…)`. The graph
  lines (y1, y2) stay one-line.
- **Graph mode**: y1 and y2 (`ui/calc_graph.gd`), drag to pan, wheel, pinch or + − to
  zoom, Std for −10 to 10, tap to trace. A curve has a gap where it jumps
  (`GraphTools.jumps`). Zero, Max, Min and Intersect find every one in the window with
  Brent's methods (`engine/brent.gd`, `engine/graph_tools.gd`), mark them in Dust Yellow
  and list them to 6 s.f.
- **The expression engine** (`engine/expr.gd`) is a port of TinyExpr: 2x is 2 × x,
  powers go right to left (2^3^2 = 512) and above a leading minus (−3^2 = −9), 1/2x is
  x/2, trig in degrees or radians, π, e, ln, log (base 10), √, abs, Ans. Names come from
  its own tables only, so nothing typed can reach the engine.
- **Licences**: TinyExpr (zlib) and SciPy (BSD-3-Clause), each notice at the top of the
  file that uses it and in the credits (`data/credits.json`, the title screen's
  "Credits"), with the fonts (OFL), the sound (CC0) and Godot's own licence.
- It fits a 360 px phone (1040 base units wide at most) and sits at the bottom of the
  screen, so the top of the question stays in sight.

### Calculator art

The look is drawn in code in the Salvage Neon Bazaar style (FAL-274's themed-look
table): a dark riveted casing with a Scrap Teal border and a stamped Bazaar Magenta
crown, a Charcoal `#1F2937` screen with the maths in mint `#9FF0E6`, worn keys that glow
Scrap Teal when pressed, Rust Orange `#FAA261` function keys and a Bazaar Magenta
`#FF3DA7` mode switch; y1 in Scrap Teal, y2 in Bazaar Magenta, marks in Dust Yellow
`#EACB74`; Share Tech Mono for numbers and Bangers for labels.

Artist's art (FAL-421) replaces it file by file from **`game/assets/ui/calculator/`**,
loaded by name like every art slot (`<name>.webp` or `.png`, lossy with mipmaps, under
300 KB, no text painted in). Each file is a **nine-slice**: the corners (the margin
below, in pixels, on every side) stay whole and the middle stretches, so draw the rim
inside the margin and keep the middle plain. With a file missing, that piece keeps the
coded look; with the casing there, the coded rivets and crown step aside.

| File | Size | Nine-slice margin | What it is |
|---|---|---|---|
| `casing` | 1040×1800, transparent outside the casing | 72 | The whole device behind everything: metal, rivets, worn edges, neon border, the crown stamped near the top left (the title "Field Calc" sits 34 px in from the top left) |
| `screen` | 512×512 | 28 | The display behind the results and the graph: a dark bezel around a Charcoal face |
| `key` | 128×112 | 20 | A digit key, up |
| `key-pressed` | 128×112 | 20 | A digit key, down, glowing Scrap Teal |
| `key-fn` | 128×112 | 20 | A function key (sin, ln, (, +, ...), up, Rust Orange |
| `key-fn-pressed` | 128×112 | 20 | The same, down |
| `key-mode` | 128×112 | 20 | The mode switch and EXE, up, Bazaar Magenta |
| `key-mode-pressed` | 128×112 | 20 | The same, down |

Key labels are drawn by the game on top, in dark ink (white on `key-mode`), so leave
each key's face plain.

## The map

`scenes/map.tscn` (`ui/map.gd`, FAL-417; Q3 and Q11 on the FAL-274 plan; the FAL-783
plan, FAL-790). "Play" on the title screen opens it. One scene with three layers, each a
closer look at the place picked on the one above:

- **The world map**: the overworld painting (`assets/map/overworld.png`) with an
  invisible button over each place. All five zones are open (FAL-925,
  `MapLink.OPEN_ISLANDS`): the Scrap Fields (`algebra`, topic 1), the Signal Tower
  (`functions`), the Dry Flats (`geometry`), the Radio Spires (`stats`) and the Engine
  Core (`calculus`); the id is the zone's link and its art folder. The **Thunderdome**
  is open too, a mixed run of every zone: it opens its own region screen
  (`#thunderdome`), whose back button goes to the world map. The Relic Library is
  locked; its card says it opens after the maths engine. The **Bazaar** is a place too,
  at zone centre (22, 70.75), 40 × 10.5 (% of the board, `BAZAAR_ZONE`), painted into the
  overworld (FAL-791, `BAZAAR_PAINTED`; while that's false a coded stall marker shows).
  It opens the Bazaar (see "The Bazaar"). There is no bar under the board: the Scrap
  there is to spend is in the header. It reads as a fast-travel map (FAL-988): each
  place has a pin in its state's colour (`STATE_COLOR`: a padlock when locked, a flag
  when cleared, a zone once its all-regions dungeon is cleared) and its name on a
  banner under the pin, always shown, and a click on the banner goes in like one on the
  place. A "you are here" marker stands by the pin of the place the player last went
  into from the world map (the save's `here`; a new save starts at the Bazaar); it
  pulses, and holds still with reduced motion. No roads or route lines.
- **A zone**: its regions (`MapLink.region_ids(island)`, in the catalogue's `order`:
  most-examined first), its all-regions dungeon and a locked Relic device spot, as places
  with no roads between them: any region in any order. Each catalogue region is on the
  zone of its syllabus topic (`MapLink.island_of`; "2.6" is Functions). A region whose
  types aren't built yet says "Coming soon" and can't start a run or Practice. That
  comes from the engine (`Progress.is_built`, which asks `Dungeon.region_types`), so a
  region opens when its situations merge, with no map change. SPARK's pick is among the
  zone's regions.
- **The region screen**, over the region's `backdrop` (see "Art slots"), or its zone's
  close-up on the overworld painting where it has none (`backdrop_for()`), cover-fitted
  under a 70% wash of the background colour (`REGION_WASH`), so its dimmest text keeps
  4.5:1 over every backdrop in `assets/regions/`. It reads as a close-up of the zone
  place, which is the place in its fight backdrop. It shows accuracy, best floor and coverage ("34 of 52 checked": the
  cells the save has seen against the catalogue's cells for the region, built or not),
  all following the "Exam-style only" switch, which the screen also carries. Then the 3
  weakest skills: the lowest accuracy among skills with at least 3 answers, where each
  answer counts for every skill its unknown lists (`Progress.weakest_skills`). Skill
  names come from `curriculum/aa-sl.json` via `catalogue.json`'s `skills`. Its buttons
  start floor 1, start after a beaten boss (`Dungeon.start_floors`) or open Practice on
  that region. Above them is the **course picker** (FAL-397): one button per IB course
  (AA SL, AA HL, AI SL, AI HL), the save's pressed. Picking one stores it
  (`SaveData.set_course`, `Map.set_course`) and draws the screen again, so every number
  on it, the locked regions in the zone and the next run follow the course (see
  "Courses"); the cell records stay. It sits on the region screen for now, a scrolling
  column that has room, until character setup gives it a place beside the class pick.

**Names on a card.** No name or state shows on a zone's board until a place is
hovered, focused or tapped (the world map names its places on banners, FAL-988, and
keeps the card for the second line). Then a card by the place shows its name and one line: the topic, the
progress line (`spot_line()`: "Floor 2 · 64%", "Not tried yet · SPARK's pick"), "Coming
soon" or "Locked"; the Bazaar's says "Bazaar · 120 Scrap". In a zone the card sits
beside its place, on the side with more room, its text shrunk to fit (down to
`CARD_NAME_LEAST`), because a column's places are closer together than a card is tall;
it covers the ground beside while it shows, never the place itself. On the world map it
goes above or below. With a mouse, hovering shows
the card and a click goes in. With a keyboard, Tab moves between places, focus shows the
card and Enter goes in; the first focus (SPARK's pick in the zone) shows none. On a
touch screen the first tap shows the card and lights the place, and a second tap on the
place or on the card goes in. A tap on a closed place shows its card. Every place keeps a
tooltip and an accessible name ("Quadratics: Floor 2 · 64%"). SPARK's beacon stays on.

**The zoom.** Going into a place scales the board into it (`ZOOM`, 0.4 s), then the next
layer fades in. Going back (the header's button, or the browser's) zooms the layer above
out of the place just left. With reduced motion it cuts: the save's
`settings.reduced_motion`, or `prefers-reduced-motion` in the browser. The Bazaar is its
own scene, so coming back from it doesn't zoom.

**Links and the back button.** On the web the hash is the route. Moving on the map
sets it, which makes a browser history entry, and a `hashchange` (back, forward, a
pasted link) sends the game there. Back from a run quits it, so its Scrap is banked.
An unknown link opens the world map and rewrites the address bar to `#world`. `#bazaar`
is the Bazaar: its own scene, but a map link like the others, so back leaves it. On the
desktop, `-- --map=functions/quadratics` does the same as the hash.

### Map art

Each zone loads its art by file name from its own folder, `game/assets/map/<island>/`:
`functions/` (the Signal Tower), `algebra/` (the Scrap Fields), `geometry/` (the Dry
Flats), `stats/` (the Radio Spires) and `calculus/` (the Engine Core). Each file is
optional: when one isn't there, that piece keeps the coded look (the zone's dusk
gradient, `ArtSlots.GROUND`, with the jetty as a dot, and a ring in the state's colour
with a short glyph, `GLYPHS`, for each place), so art can land one file at a time and an
zone's painting shows the moment it's dropped in, with no code change. Only
`functions/background.webp` is painted so far (FAL-791). Import each with mipmaps on,
like the rest of the art.

| File | Size | What it is |
|---|---|---|
| `background.webp` (or `.png`) | 1080x1920, opaque | The whole zone, portrait, one painting with every place painted in at its point in that zone's `SPOTS` table in `ui/map.gd` (% of the board), the jetty at (50, 97). No roads, no text. The FAL-783 plan has the Signal Tower's table of places; the other four zones' tables were laid out for the coded look on FAL-925, and a painting may follow them or move them (then update `SPOTS`). With it, a place with no landmark PNG draws nothing but its button: an invisible square of 300 board units round its point (the Relic device's 160). A place that can't be played yet gets a dark wash and a padlock chip, a cleared one a flag chip, both from the code, so one painting serves every state |
| `<spot>-locked.png` | 256x256, transparent | A spot's landmark before its questions are built |
| `<spot>-open.png` | 256x256, transparent | A spot's landmark once it can be played |
| `<spot>-cleared.png` | 256x256, transparent | A spot's landmark once floor 3's boss is beaten there |

`<spot>` is a region id of that zone (on the Signal Tower `quadratics`, `exp-log`,
`graphs-features`, `composite-inverse`, `rational`, `function-basics`, `lines`,
`transformations`; the other zones' ids are in `SPOTS` and in "Art slots" below),
`all` for the zone's all-regions dungeon in the middle, or `relic` for the Relic
device (only `relic-locked.png` is used for now). A landmark fills its place's square (300x300, the
Relic device's 160x160), kept square and centred, over the painting or the coded
ground. No name shows under it: the card does that. SPARK's pick (`Progress.suggest()`)
gets a pink beacon drawn round its place, art or not, so leave the place readable under
a ring.

The world map's places are areas of `assets/map/overworld.png` (`ISLANDS`,
`THUNDERDOME_ZONE`, `RELIC_LIBRARY_ZONE`, `BAZAAR_ZONE` in `ui/map.gd`), with a pin
point each (`pin` in `ISLANDS`, `THUNDERDOME_PIN`, `RELIC_LIBRARY_PIN`, `BAZAAR_PIN`),
measured from the painting on FAL-986 and trimmed where landmarks overlap so no two
zones do. `js/router.js` has the same zone and Thunderdome areas. When the
painting has the Bazaar's stalls painted in at its zone (FAL-791), set `BAZAAR_PAINTED`
to drop the coded marker.

Overworld painted by Matt Prokock with ChatGPT, 2026-11-16 (FAL-981); sky and dust bands extended locally with Qwen Image (FAL-986).

### Moving pieces (FAL-1075)

The world board has an ambient layer (`ui/ambient_layer.gd`, ported from The Unruly
Atlas) between the painting and the buttons: the crow, the Signal Tower beacon, the
Engine Core smoke, the Thunderdome neon and the Dry Flats dust (art from FAL-1074). Its
pieces are listed in `data/ambient.json` under `"map"`, bottom to top, in the schema at
the top of the script: a sheet, a board position and anchor, a frame mode and a motion.
A sheet is `assets/ambient/<id>-sheet.png` with the `<id>-sheet.json` frame map beside
it; the sources and rebuild commands are in `assets/ambient/src/`. The layer takes no
taps. With reduced motion each piece holds the frame in its `"still"`, or is hidden
without one.

The fight screen plays the same file's `"fight"` effects over the enemy's portrait,
scaled with it: the hit spark on a hit (`spark_hit()`, beside `flash_hurt()`) and the
dust burst at its feet while the portrait fades when it falls (`enemy_falls()`). They
don't play over the journey strip. With reduced motion there is no spark and a fallen
enemy just goes.

## Art slots

The game loads its art by file name (FAL-470, `engine/art_slots.gd`), so each art batch
(FAL-362) shows up in the game as soon as its PR merges, with no code change. **This
section is the contract for the art briefs.** Every file is optional: when one isn't
there, the game falls back to the art or the coded look it had before, and a region with
no art plays exactly as it did.

**Rules for every file**

- A slot's file is `<name>.webp` or `<name>.png` (WebP is looked for first), except the
  share card. Under 300 KB each.
- Lossy, with mipmaps: `compress/mode=1` (lossy, quality 0.8) and
  `mipmaps/generate=true` in its `.import`. `project.godot`'s importer defaults give a new
  file both, so let Godot write the `.import` (`./test.sh` does). `test_art.gd` fails on a
  file in these folders that imports lossless, because lossless costs about ten times the
  download (a 1920×1080 painting: 1.42 MB lossless, 152 KB lossy).
- Text is drawn by the game, never painted into the art.
- Names, taunts, the enemy pool and the frames are data in `game/data/`, so adding one is
  a row in a JSON file, not code.

**`assets/title/`**

| File | Size | Where it shows | With no file |
|---|---|---|---|
| `key-art` | 1920×1080, opaque | Behind the title screen in a landscape window (a PC). The title sits in the top 30% and the buttons in the lowest 20% | The plain title screen with Spark |
| `key-art-phone` | 1080×1920, opaque | The same in a portrait window (a phone). Title in the top 35%, buttons in the lowest 25% | The plain title screen with Spark |
| `share-card.png` (or `.jpg`) | 1200×630 | The link preview. `export.sh` copies it beside `index.html` and points the page's Open Graph and Twitter tags at it (`scripts/share-card.sh`). It stays out of the game download | No link-preview tags |

The title screen uses only the version for the window's shape, so with only one of the
two, the other shape keeps the plain look. Spark is in the key art, so the Spark image
steps aside when it shows.

**`assets/regions/<region-id>/`**, for every catalogue region (`all`, the Functions
all-regions dungeon, `all-<island>` for another zone's, and `thunderdome` work too):

- Scrap Fields (`algebra`): `sequences`, `finance`, `exponents-logs`, `binomial`, `proof`
- Signal Tower (`functions`): `quadratics`, `exp-log`, `graphs-features`,
  `composite-inverse`, `rational`, `function-basics`, `lines`, `transformations`
- Dry Flats (`geometry`): `triangles`, `trig-graphs`, `arcs-sectors`, `geometry-3d`,
  `trig-equations`, `unit-circle`
- Radio Spires (`stats`): `discrete-distributions`, `probability`, `normal-distribution`,
  `regression`, `conditional-probability`, `averages-spread`, `sampling-data`
- Engine Core (`calculus`): `kinematics`, `stationary-points`, `tangents-normals`,
  `definite-integrals`, `derivative-rules`, `derivative-basics`, `integration`

Only the Signal Tower's and the Scrap Fields' regions have backdrops so far. A region
with no `backdrop` shows a close-up of its zone cut from the overworld painting (the arena for the
Thunderdome) under the same wash (`backdrop_for()` in `ui/map.gd`), so it reads as that
zone rather than a blank screen.

| File | Size | Where it shows | With no file |
|---|---|---|---|
| `backdrop` | 1920×1080, opaque, dark | Behind the fight screen and its floor select, cover-fitted under a 55% wash of the background colour, and behind the map's region screen under a 70% wash. A phone held upright shows about the centre 500 px, so keep what matters in the centre 600 | A close-up of its zone on the overworld painting |
| `miniboss` | 512×512, transparent | Fight 5, the mini-boss, in the 190 px enemy box | The tier's enemy (see `enemies/`) |
| `miniboss-hurt` | 512×512, transparent: the same pose, size and place | Flashes for 80 ms when a hit lands | No flash |
| `boss` | 512×512, transparent | Fight 10, the boss | The tier's enemy |
| `boss-hurt` | 512×512, transparent: the same pose, size and place | Flashes for 80 ms when a hit lands | No flash |

Each mini-boss's and boss's name and one-line taunt are in `data/bosses.json`:
`{"<region-id>": {"miniboss": {"name", "taunt"}, "boss": {"name", "taunt"}}}`. The
name replaces the tier name over the HP bar, and the taunt opens the fight on the card.
A key may also be a zone id (`algebra`, `geometry`, `stats`, `calculus`) or
`thunderdome`: a region with no entry of its own uses its zone's (FAL-925), so every
region of the four newer zones, and each zone's all-regions dungeon, has its zone's
pair for now. With neither, it shows "Mini-boss Enforcer" and the like, as before, and
no taunt.

**`assets/enemies/`**: the shared pool of regular enemies

| File | Size | Where it shows | With no file |
|---|---|---|---|
| `<id>` | 512×512, transparent (`d1` to `d5` are 256×256) | A regular fight of its tier | Left out of the draw |
| `<id>-hurt` | The same box, pose and place | Flashes for 80 ms when a hit lands | No flash |

Each enemy is a row in `data/enemies.json`: `{"id", "name", "tier"}`, tier 1 to 5 (D1 to
D5; floors 1 to 3 fight D1 and D2, deeper floors higher tiers). A regular fight draws
from its tier's rows whose file is there, by the run's seed, floor and fight, so a run
replays the same. The five `d1` to `d5` enemies are rows too, so they stay in the draw.
The tier sets the numbers (HP, damage, Scrap); the pool only sets the name and the art.
With no row's file there, a fight shows the tier's own enemy from `Tuning.ENEMIES`.

**`assets/bazaar/`**

| File | Size | Where it shows | With no file |
|---|---|---|---|
| `stall` | 1920×1080, opaque, dark | Behind the Bazaar, cover-fitted under a 60% wash. Centre 600 px as for backdrops | The plain background |
| `shopkeeper` | 512×512, transparent | Under the Bazaar's title, at 360 px, beside the speech bubble | No shopkeeper |
| `shopkeeper-idle` | 512×512, transparent: the same pose, size and place | Swaps in for 0.6 s every 4 s | The portrait stays still |
| `scrap` | 128×128, transparent | Beside the Scrap count, at 96 px | The count alone |
| `upgrade-max-hp`, `upgrade-lifeline` | 128×128, transparent | Beside each upgrade, at 96 px | No icon |
| `perk-field-manual`, `perk-scrap-armour`, `perk-lucky-find`, `perk-second-wind`, `perk-field-watch` | 128×128, transparent | Beside each perk, at 96 px | No icon |
| `frame-<id>` | A nine-slice panel, any size | A name-plate frame on sale in the Bazaar | Not on sale |

A frame is a row in `data/frames.json`: `{"id", "name", "art": "bazaar/frame-<id>",
"margins": [left, top, right, bottom]}`, the nine-slice margins in pixels. Rows are
listed in the Bazaar in file order; a row whose art isn't there is left out.

**`assets/ui/run/`**

| File | Size | Where it shows | With no file |
|---|---|---|---|
| `banner-floor-cleared` | 1200×300, transparent. Keep the middle clear: the game writes "Floor 2 cleared" across it | After a floor's boss falls, above the result line | The result line alone, as before |
| `banner-boss-beaten` | 1200×300, transparent; the game writes "Mini-boss beaten" | After a mini-boss falls | The result line alone |
| `banner-run-over` | 1200×300, transparent; the game writes "Run over" or "You're down" | The heading of the run summary | The text heading |
| `medal-floor-1`, `medal-floor-2`, `medal-floor-3` | 256×256, transparent | Beside the region's best floor on the floor select and the run summary, at 120 px | The line alone |
| `medal-floor-4` | 256×256, transparent | The same, for a best floor of 4 or deeper | The line alone |

The store owner's lines are data: `data/shopkeeper.json` (see "The Bazaar").

Not here: the zone maps (`assets/map/<island>/`, see "Map art"), and the weak-skills
flag on the map, which has no slot yet.

## The Bazaar

Scrap banked from runs buys things at the Bazaar (G6, Q10). Its place on the world map
and a run's summary link to it (`#bazaar`), and its "World map" button goes back there. `engine/bazaar.gd` holds the rules and
no UI; `ui/bazaar.gd` draws them. Every price, cap and perk value is in the Bazaar
section of `engine/tuning.gd`.

- **Upgrades, kept for good and capped:** Max HP +10, up to 3 times (100 to 130), and
  +1 charge of a lifeline the player picks, up to 2 times in all.
- **One perk slot, for the next run only:** Field Manual (a Hint spends no charge),
  Scrap Armour (+20 HP), Lucky Find (+1 charge on a lifeline the player picks), Second
  Wind (+20 on G4's boss heal, after a boss but not a mini-boss) and Field Watch (+10 s
  on every question's clock, not Time Freeze). A second perk can't be bought while one
  waits. The run uses it up as it starts.
- **Cosmetics:** name-plate frames, listed in `data/frames.json` (the first three are
  the encounter UI art: Field Note, Signal Box, Brass Chip; see "Art slots") and colour tints from the Salvage Neon palette, for the plate over the
  player's HP bar and the bar itself. Looks only.
- **Through the modifiers only.** `Bazaar.equip(run, save)`, before `run.start()`, adds
  one modifier built from what was bought and empties the perk slot. Nothing in the
  Bazaar touches combat code.
- **A failed purchase changes nothing**, and says why: not enough Scrap, at its cap,
  owned already, the perk slot full, or no lifeline picked.
- **Prices** come from the Scrap a player who answers 70% right banks in a run
  (`Tuning.SCRAP_PER_RUN_70`): each upgrade level and cosmetic costs 2 to 3 runs of it,
  and a perk under one. `tools/bazaar_sim.gd` plays real runs and shops after each;
  `test_bazaar.gd` checks that such a player unlocks something every 2 or 3 runs. Print
  the price table with
  `godot --headless --path game --script res://tools/bazaar_balance.gd`.
- **The store owner talks** (FAL-790). `data/shopkeeper.json` is
  `{"name": "...", "lines": {"first_visit": [], "enter": [], "idle": [], "buy": [],
  "broke": [], "capped": [], "leave": []}}`, each line 90 characters at most (written on
  FAL-789). The line shows in a speech bubble beside the `shopkeeper` portrait:
  `first_visit` the first time (then `bazaar.met` is set in the save), `enter` after
  that, `buy` after a purchase, `broke` and `capped` when a purchase can't go through for
  want of Scrap or at a cap (a click on a disabled button counts), `idle` after 30 s with
  nothing said, and `leave` on the way out, 1.2 s before the world map (a second press
  goes at once). Never the same line twice in a row. No file means no bubble; no art
  means no portrait.
- Links: `/#bazaar` is its map link; `/?bazaar` opens it too, and
  `/?bazaar=demo` opens it on a sample save and stores nothing (screenshots).

## Tests

`game/tests/run_tests.gd` is a small runner with no third-party framework. It loads
each `test_*.gd`, which extends `test_case.gd`, and calls every method whose name starts
with `test_`. A test fails if it calls `fail()` or a `check*` helper that fails, or if a
script error happens while it runs. Run one file with
`godot --headless --path game --script res://tests/run_tests.gd -- --only=boot`.

- `test_boot.gd`: the main scene loads and runs a few frames with no errors in the log,
  and its column fits at 390x844 and 1280x800.
- `test_project.gd`: the settings the plan depends on (own `user://` name, portrait
  base, Compatibility renderer, Web preset with threads and PWA off).
- `test_sequences.gd`: every cell of `t1-arithmetic-sequence`, its misconceptions as
  options, the negative root offered when n is found from Sₙ, and exact marking.
- `test_engine.gd`: every catalogue cell of the three Quadratics types can be made,
  same seed same question, the format layer, wrong options, misconceptions, probes and
  the exam-only cells.
- `test_triangles.gd`: the two Topic 3 types on the triangle: built, every angle from
  20° to 140°, one triangle for the sine rule's angle, acute or obtuse said, 3 s.f.
  marking with no false failures, every misconception appears as an option; Paper 2
  answers need a calculator, Paper 1 answers are exact whole numbers or surds.
- `test_distributions.gd`: the three Topic 4 types on the distribution: built, every
  distribution adds to 1 inside its limits, k in a table, a formula and words, answers
  written as the question writes probabilities, exact or 3 s.f. marking, p and q as two
  slots, strict events, every misconception appears as an option (on Paper 2 too);
  Paper 2 has awkward decimals and 3 s.f. answers where a calculator gives them, with
  the rounding trap, and Paper 1's numbers are unchanged.
- `test_differentiation.gd`, `test_derivative_meaning.gd`, `test_monotonic.gd`, `test_concavity.gd`:
  the four FAL-723 types: built with every cell and every skill, no extra format, four
  different options, GDC methods on Paper 2 only, an expression marked by its numbers, an
  interval marked in either order, a limit graph with a gap, and matching as four graphs.
- `test_derivative_graph.gd` (FAL-754): t5-derivative-graph built with every cell and both skills, Paper 1
  only, no extra format; hand values, every root and turning point on a whole number, the areas given
  equal to the areas under the curve drawn, a figure on every graph cell, and every tag as an option.
- `test_motion_distance.gd`: t5-kinematics-distance built with every cell and both skills, four
  different options, GDC methods on Paper 2 and integrating by hand on Paper 1, the antiderivatives
  against v, a worked trip, graphs with a corner at each zero, and a return that goes both ways.
- `test_area_between.gd`: `t5-area-between-curves` (FAL-751): built with every cell and all four
  methods, four different options, the papers follow the curves, a figure shades the region between
  its curves, a diagram marks what fixes its equations, every slip shows up as an option, and the
  exact pieces and Simpson's rule against hand values.
- `test_integration.gd`, `test_definite_integral.gd`, `test_motion.gd`: the three FAL-724 types:
  built with every cell and every skill, no extra format, four different options, GDC methods on
  Paper 2 only, + C on every integral, the method setting the shape, a shaded region on every
  figure, exact integrals and derivatives against hand values, and named axes.
- `test_binomial_expansion.gd`: t1-binomial-term built with every cell and all three skills, no
  extra format, four different options, the GDC on Paper 2 only, hand values, the bracket as the
  exam writes it, the staggered triangle, a term against a coefficient, a typed expansion and row,
  every misconception as an option, the three concept probes and AA courses only.
- `test_binomial_constant_term.gd` and `test_binomial_product.gd` (FAL-779): the two binomial
  extension types built with every cell in every format they offer, the r found giving the power
  asked, the middle term only for symmetric powers, each product's answer as two pairs of terms
  multiplied out the long way, the skill map's examples left out, hand values, the exam type's
  cells untouched, and every tag shown.
- `test_prove_identity.gd` (FAL-753): `t3-prove-identity`: every cell on Paper 1, four different options, hand
  values, each chain reaching its right side, hidden and spoiled lines where they should be, no exam
  statement or HL ratio, typed slips detected, and every tag shown.
- `test_algebraic_proof.gd`: t1-algebraic-proof built with every cell, both SL1.6 skills and
  14 unknowns; every cell in both formats, with the answer ending the working; the bank's paper
  split; each statement against values worked out by hand; a hidden line and a spoiled line
  where the chain says; the fix typed on the wrong line marked wrong; a typed slip detected;
  the factors in either order; every misconception as an option; no statement with the exam's numbers.
- `test_trig_wave.gd`: t3-trig-read-features and t3-trig-model-use built with every cell, four
  different options, the GDC on Paper 2 only, a figure hiding its equation unless the GDC needs it, b
  written each way, first peaks and a model against hand values, degree mode and "only the first time"
  as options, and every misconception shown.
- `test_trig_model_equation.gd`: t3-trig-model-equation built with every cell, four different options,
  exact times on Paper 1 and a GDC or a story's level on Paper 2, counts, bands of k, exact times,
  stretches and a curve against a line against hand values, the map's own examples never asked, a
  touching line and degree mode as options, the figures, and every misconception shown.
- `test_binomial.gd`: t4-binomial built with every cell and all six SL4.8 skills; every
  cell in every format; Paper 2 only; the same seed giving the same question; the story
  and the model saying n and p; probabilities against hand values; every option a
  probability; the least n the first that works; n and p from E(X) and Var(X) exact;
  every misconception as an option; 3 s.f. marking with 2 s.f. a glancing hit; the three
  concept probes; and every course having every cell.
- `test_regression.gd`: t4-regression-gdc built with every cell and all four SL4.4 skills;
  every cell in both formats with 2 to 5 steps per worked solution; Paper 2 only; the sums,
  the line and r against hand values; the data near a line of the story's sign and the line
  through the mean point; exact means and c; an estimate inside the data, with the
  early-rounding and rearranged-line slips reading differently; a line written with its
  sign; 3 s.f. marking and an exact mean point; every misconception as an option; r² as an
  option and r never 1 or more; the three concept probes; and every course having every cell.
- `test_right_triangle.gd`: `t3-right-angle-trig` (FAL-739): every cell and skill, one right option
  in both formats, a figure for every elevation and depression, the horizontal at the top, a turned
  triangle keeps its right angle, exact answers stay exact, and every misconception is offered.
- `test_solid.gd`, `test_standard_form.gd`: the two FAL-726 types: each built with every cell and
  all its skills, one right option on each paper it can make, sketches that label only what is
  given, a right triangle in every cone and a sector that rolls into its cone, a × 10^k typed with
  a negative k, the right value with a outside 1 to 10 marked wrong, E-notation never typed, the
  superscripts' glyphs, and every misconception as an option.
- `test_sample_space.gd`: `t4-sample-space`: every cell, method and representation, one right option on
  each, Paper 1 exact and Paper 2 rounded, matching objects on every symmetry cell, "Another way" on the
  same numbers, grids that fit a phone, figures with the right sectors, and every misconception shown.
- `test_basic_probability.gd`: `t4-probability-basic`: every cell and skill, one right option on each
  paper, every option a probability, hand values, the figures drawn, a curve of real counts, a
  complement that differs from its event, and every misconception as an option.
- `test_geometric_context.gd`: t1-geometric-in-context built with every cell, both skills and every map method, the papers, "after t" against "in round n", a least n as the first past its target, a gap as the series' tail, a rival passing once, and the figures
- `test_regression_interpret.gd`: t4-regression-interpret built with every cell and both skills, Paper 2
  throughout, the given line is the table's to 3 s.f., each case stands apart (x = 0, strong or weak r,
  inside or outside the data), the scatter is the data, and every misconception shows up.
- `test_regression_pair.gd`, `test_normal_unknown.gd`, `test_venn.gd`, `test_conditional.gd`: the four
  FAL-725 types: each built with every cell and all its skills, one right option on each paper,
  the numbers against hand values, the figures drawn, every misconception as an option, and the
  courses each is in.
- `test_tree_diagram.gd` (FAL-739): `t4-tree-diagram`: every cell with one right option, its papers,
  forks that add to 1, a tree of each shape, a tin's branches as the recount, one valid k, n back from
  a growing tin, a game's two ways to win, past-paper set-ups left out and every misconception shown.
- `test_derivative_model.gd` (FAL-753): `t5-derivative-model-gdc`: every cell and method on Paper 2, the
  sums by hand, a time that has the rate asked for, a greatest rate that is the rate's top, and every tag.
- `test_trig_quadratic.gd` (FAL-753): `t3-trig-quadratic`: built with every cell and all three methods,
  four different options on the cell's one paper, the equation against hand values, a root out of range
  gives no solutions, the bank's and the map's equations are never drawn, and every slip shows up as an option.
- `test_inverse_normal.gd` (FAL-752): `t4-inverse-normal`: every cell and method, each on its one paper
  with one right option; a value has the area it was given, a central interval and a band hold theirs,
  a ratio's tails are in that ratio, Paper 1 is exact with no calculator word, and every slip comes up.
- `test_circular_motion.gd` (FAL-753): `t3-circular-motion`: every cell on Paper 2 with one right option,
  all three methods, sums done by hand, an exact chord's whole time, a found chord clear of a landmark
  cosine, the figure of each diagram cell, and every slip comes up.
- `test_normal_probability.gd` (FAL-728): `t4-normal-probability`: every cell on Paper 2 with one
  right option, the one normal distribution it shares with `normal-unknown`, regions that add up,
  bands wide enough for their labels, the shaded curve, the root of a variance, half a unit either
  side of a recorded value, exactly k of a sample, a middle from two tails, and every misconception
  as an option.
- `test_sampling.gd`, `test_cumulative_frequency.gd`: the two FAL-726 types: every cell and skill,
  one right option on each paper the type has, group sizes whole, a curve rising through grid corners
  with its class boundaries among them, a table's estimates ending, the figure drawn, every
  misconception as an option, and every course.
- `test_arc_sector.gd`, `test_bearings.gd`: the two FAL-726 types: built with every cell and skill,
  one right option on each paper, exact Paper 1 answers that keep π, a sector at its real angle, a
  north line at each bearing, every misconception as an option, and the courses each is in.
- `test_data_summary.gd`: t4-summary-statistics built with every cell and all four SL4.3
  skills; every cell in both formats with 2 to 5 steps per worked solution; the GDC cells
  Paper 2 and the by-hand unknowns Paper 1, and both papers where a cell can make both;
  every list shown out of order; the medians, quartiles and modes against hand values; a
  Paper 1 mean ending in one decimal place and a Paper 2 mean needing 3 s.f.; a unique mode
  that is not its own count; the missing value and frequency fitting their mean; a combined
  mean that is not the mean of the means; the outlier dragging the mean; every misconception
  as an option; exact and 3 s.f. marking; the three concept probes; and every course having
  every cell.
- `test_sequence_proof.gd`: t1-sequence-proof built with every cell and all four methods, Paper 1 only;
  four different options and working of 2 to 5 steps in each cell; linked terms, sums, a term from its sum,
  logs and terms in k match sums done by hand; the dot figures count what they say; a hidden or spoiled
  line is its own number; relations never use the exam's evenly spaced terms; every tag shows up.

- `test_log_equation.gd` (FAL-956): t1-log-equation built with every cell and all four skills, Paper 1
  only, four distinct options with one right and the answer in each working's last step; the rejected
  root is named in the working; a typed x is marked by its value; hand roots and factors; every tag shows up.
- `test_approximation.gd` (FAL-999): t1-ai-percentage-error and t1-ai-approx-bounds built with every
  cell and all five AI-SL1.6 skills, on the AI courses only, Paper 2 only; four distinct options with one
  right and the answer in each working's last step; every tag shows up; a rounded value keeps its zeros
  and rounding in stages carries; a typed value is marked by its value; bounds are half a unit away; the
  largest error is from the lower bound.
- `test_tvm.gd` (FAL-999): t1-ai-amortization and t1-ai-annuity built with every cell and all six
  AI-SL1.7 skills, on the AI courses only, Paper 2 only; four distinct options with one right; every tag
  shows up; the solver's sums against known values; a typed amount is marked to the cent; the cheaper of
  two loans has the higher payment.
- `test_log_technology.gd` (FAL-999): t1-ext-logs-with-technology built with every cell on all four
  courses, Paper 2; method-pick on every cell and error-spot on the two equations, with the slip on
  either line; every tag shows up; hand values of the logs.
<!-- R2-STATIONARY -->
- `test_ai_stationary.gd` (FAL-1000): t5-ai-stationary-points built with all 39 cells and all five
  AI-SL5.6 skills, on the AI courses only, Paper 2 only; four distinct options with one right and the answer
  in each working's last step; every tag shows up, and none is the derivative-graph type's SL5.7 one; the
  vertex working only on a quadratic story; a typed point or value is marked by its value; hand-worked
  stationary points, the constant-kept zeros, the reciprocal's minimum, k from f(x) = 0 and an end that
  beats the local maximum; the f′-graph unknowns draw DerivativeGraphSituation's curves.

<!-- R2-OPTIMISATION -->
- `test_ai_optimisation.gd` (FAL-1000): t5-ai-optimisation built with every cell and all four AI-SL5.7
  skills, on the AI courses only, Paper 2 only; four distinct options with one right and the answer in
  each working's last step; a figure on every diagram cell and a table on every table cell; every tag
  shows up; the vertex working only on a quadratic and calculus never on the angle model; the nearest
  whole number is never the best; a typed value is marked by its value; hand-worked values.

<!-- R2-TRAPEZOIDAL -->
- `test_trapezoidal.gd` (FAL-1000): t5-ai-trapezoidal built with every cell and all five AI-SL5.8 skills, on the AI courses
  only, Paper 2 only; four distinct options with one right and the answer in each working's last step; tables and figures shown;
  four cards for pick the graph; every tag shows up; typed values marked by value; the rule, the percentage error, the slips, a
  missing height and the bends against values worked by hand.
<!-- R3-LINEAR -->

<!-- R3-QUADRATIC -->

<!-- R3-EXPONENTIAL -->

<!-- R3-VARIATION -->

<!-- R3-CUBIC -->
- `test_ai_cubic_model.gd` (FAL-1001): fn-ai-cubic-model built with every cell and both skills (AI-SL2.5.cubic-model,
  AI-SL2.6.reasonable-domain), on the AI courses only, Paper 2 only; four distinct options with one right and the answer in
  each working's last step; the card and the graphs shown; four cards (and the card above them) for picking the domain; every
  tag shows up; typed values marked by value; the box, its turning points, the table's refining, a cubic's zeros and where it
  is negative against values worked by hand.

<!-- R3-SINUSOID -->

<!-- R3-FIT -->

<!-- R3-CHOOSE -->

<!-- R3-TEST -->
- `test_log_exp_form.gd` (FAL-753): t1-log-exp-form built with every cell, both skills and all six methods,
  exp-log-form on Paper 1 and log-context on Paper 2; hand values, clean 3 s.f. answers, standard form,
  figures, map strings with no numbers, and every tag as an option.
- `test_constant_change.gd` (FAL-754): t4-constant-changes built with every cell and unknown, Paper 1
  only, four distinct options with one right and no extra format; a box plot on its ticks and axis, the
  rules for a centre, a spread and the variance both ways, a list's statistics by hand, a changed list
  agreeing with the rules, a real stretch and shift for find-a-and-b, and every tag as an option.
- `test_rational_exponents.gd` (FAL-754): t1-rational-exponents built with every cell, one right
  option in every cell, Paper 1 only, marking by value, a typed slip logged, every tag as an
  option, the map's and the bank's examples left out, and hand values.
- `test_polynomial_conditions.gd`, `test_always_increasing.gd`, `test_hence_integral.gd`,
  `test_integral_gdc.gd` and `test_area_under_curve.gd` (FAL-776): the six calculus extension types
  built with every cell, each question on its paper, hand values for each family, every distractor
  tag shown, and the extra formats' rules (error-spot's bad line, method-pick's working method, the
  cards' shading).
- `test_tangent_meets.gd` (FAL-754): t5-normal-meets-curve built with every cell, Paper 2 only, no extra
  formats; f and f′ against hand values, the line really the tangent or the normal, A and B on their axes,
  Q on both the curve and the line, (x − x₀)² in a built cubic's curve minus tangent, the figure's curve
  and line, every tag as an option, and no wrong option or rounding trap that types as right.
- `test_solve_exponential.gd` (FAL-754): t1-solve-exponential built with every cell and all four methods;
  exact cells make Paper 1 on request with no calculator in the working, 3 s.f. cells Paper 2; hand values,
  clean answers, early rounding in the third figure only, exact two-bases answers within |x| ≤ 12, the
  crossing on each figure, and every tag.
- `test_trig_sketch.gd` (FAL-754): t3-trig-sketch built with every cell and all three methods, the GDC on
  Paper 2 and the rest by hand on Paper 1; the sketches pick-the-graph with four different cards on one
  window, no extra formats; hand values, figures with nothing marked, five-point tables, map strings with
  no numbers, and every tag as an option.
- `test_solid_angle.gd` (FAL-754): t3-3d-angle built with every cell and all six methods, landmark-angle
  on Paper 1 and exact, the rest Paper 2; hand values for every unknown, clean in-range 3 s.f. angles, the
  right angle at A or C, each figure marking what is asked, map strings with no numbers, and every tag.
- `test_depreciation.gd`: t1-depreciation built with every cell and both skills, Paper 2 only; the
  value, the rate, the price and the least time against hand values; every dollar answer clear of
  the half-dollar edge; a table exact to the cent; the figure's crossing; months and quarters
  converted; every tag appears as an option.
- `test_compound_interest.gd`: t1-compound-interest built with every cell and all four SL1.4
  skills; every cell in both formats with 2 to 5 steps per worked solution; Paper 2 only; the
  value, the doubling time and the rate against hand values; every money value clear of the
  half-cent edge; the least years the first that works; a rate a quarter of a per cent that
  reads differently from its two slips; two accounts that differ, with A worth 20 or more
  above B and rounding first changing nothing; the table and words versions; every
  misconception as an option; exact and 3 s.f. marking; the three concept probes; and every
  course having every cell.
- `test_quadratics.gd`: the four FAL-414 types: built with every cell, 2 to 5 steps per
  worked solution, every distractor misconception as an option (three that no answer
  shape can carry yet are listed with the reason), two rays typed as one interval caught
  as SL2.7.inequality#1, two points in either order, a tangent's point on both graphs,
  Paper 2 contexts (never for factorising), every cell with both papers exact on Paper 1
  and to 3 s.f. with calculator working on Paper 2, a quadratic model taking a forced
  paper, and "Another way" keeping the numbers for every fn-solve-quadratic unknown and
  pair of methods.
- `test_graphs.gd`: the Graphs and key features types (FAL-420): built with every cell
  on their situations, each on its paper, every distractor misconception as an option
  (one that the vertical asymptote can't show, and one that D's shape rules out, are
  listed with the reason), the same seed giving the same question, pick the graph as
  four lettered cards with each wrong card's mistake and misconception (and picking it
  logs it), zeros marked in any order to 3 s.f. with 2 s.f. a glancing hit, the 2 s.f.
  turning point as the trap that logs SL2.4.max-min#2, the greatest value at an
  endpoint, each boss chain on one situation and a true minus sign throughout. The
  extension types are in it too, with every cell built (a cubic's f(x) = 0 distractor
  in fn-link-extremes is listed with the reason). A curve that dips through a line between
  two samples is found, and a two-curves situation has every crossing a fine scan finds.
- `test_exp_log.gd`: the eight Exponentials and logs types (FAL-418): built with every
  cell on their situations, 2 to 5 steps per worked solution, every distractor
  misconception as an option (two that no exact option can show are listed with the
  reason), the same seed giving the same question, an exact k marked by value, a
  percentage change needing its direction, a model typed as decimals, a limited model's
  k to 3 s.f., whole time units rounded up, each boss chain on one situation, an inverse
  typed as its two shifts with 1/f(x) offered as f⁻¹, a true minus sign throughout, and
  the percent error-spot's first wrong line.
- `test_calculus.gd`: the four Topic 5 types on the cubic: built, every misconception
  appears as an option, two points in either order, nature as multiple choice, f′(x)
  marked exactly, the normal to 3 s.f.; Paper 2 needs a calculator (decimals, 3 s.f.
  answers that need rounding, GDC working, the rounding trap) and Paper 1 keeps its
  numbers.
- `test_answer.gd`: parsing and marking typed answers.
- `test_expr.gd`: the expression engine against a table of 65 expressions (2^3^2 = 512,
  −3^2 = −9, 2x at x = 3 is 6, sin 30° = 0.5, ln e = 1, ...), exact fractions for
  marking, no real value, and anything that isn't maths turned down; and no `Expression`
  in the game's code.
- `test_brent.gd`: Brent's root finder and minimiser, and the zeros, maxima, minima and
  intersections of 23 functions against SymPy's in `tests/fixtures/brent.json` to 6 s.f.
  (`tools/brent_reference.py` writes it), with poles neither zeros nor turning points.
- `test_paper.gd`: every question has a paper, a forced paper is given where the cell
  can make it, over 1,000 questions per type the Paper 2 share is within 5 points of the
  exam's, a boss chain is on one paper, and concept probes are Paper 1.
- `test_calculator.gd`: the Calculator button only on Paper 2, Scientific mode (keys,
  recent results, Ans, degrees), 6 s.f., the graph tools and their marks, pan, zoom and
  trace, the clock running and nothing spent in a fight, the art slots and the coded
  look, the licences in their files and the credits, and the fit at 360, 390 and 1280 px.
- `test_seeded.gd`: the seeded stream's first draw is as fair as every later one (chance,
  float, whole number, pick and weighted pick over 1000 seeds), the same text gives the
  same stream, and the first five draws of one key are pinned (FAL-460).
- `test_courses.gd`: the four courses; which skills, unknowns and methods each covers
  (AA HL every built cell, AA SL all but the HL-only types', AI SL inside AI HL); the save's `course`, its
  version 5 migration and `set_course()` keeping the cell records; and that the planner,
  a run's floors, warm-ups, prior learning, mini-bosses, bosses and links, and the map's
  counts only use cells the course covers.
- `test_counting.gd`: t1-ahl-counting built with every cell and four of AHL1.10's six
  skills; both formats, no extra one; on AA HL's list and no other course's; the planner
  serving it to an AA HL student and never to an AA SL one; the counts against hand values
  (4536 four-digit numbers, 150 and 315 committees, 240 and 480 rows); whole, positive
  counts and clean n from nP2; every misconception as an option; exact marking; a true
  minus; and the two probes.
- `test_complex_number.gd` (FAL-1004): t1-ahl-complex-cartesian built with every cell for the
  five AHL1.12 skills on AA HL only, and t1-ai-complex-cartesian with every cell for the six
  AI-AHL1.12 skills on AI HL only and Paper 2 throughout; four options with one right in both
  formats, no extra format; every misconception as an option; an Argand diagram with its axes
  named Re and Im and its points on it, and the parabola's vertex above the axis for
  quadratic-roots; and products, quotients, powers and arguments against hand values. Both
  types sit in the Exponents and log laws region (`exponents-logs`): a region of its own would
  be locked for AA SL, which the map does not handle yet.
<!-- R9-RATIONAL -->
- `test_rational_quadratic.gd` (FAL-1007): fn-ahl-rational-quadratic (AHL2.13) built with all 31 cells and all
  five skills, on AA HL only; a GDC method is Paper 2 and every other cell either paper, with exact turning values
  on Paper 1 and 3 s.f. ones on Paper 2; four distinct options with one right and the answer in each working's
  last step, and no GDC tab on Paper 1; every tag shows up, and only on the unknowns it lists; pick the graph draws
  every branch of the right card, an oblique asymptote dashed, and tags the missed-zero and lost-constant cards; the
  graph view shows its asymptotes; typed answers marked by value; hand-worked ranges, turning points and an oblique
  split. The map's AHL2.13 skills also list `match`, `order-steps` and `multipart`, which the engine doesn't build,
  and `true-false-reason`, `error-spot` and `method-pick`, which the type doesn't list, so none is offered.

<!-- R9-ODD-EVEN -->
- `test_odd_even.gd` (FAL-1007): fn-ahl-odd-even (AHL2.14) built with every cell for its three
  skills (odd-even-test, odd-even-graph, odd-even-combine) on AA HL only, every cell on both
  papers in the bank's ratio (no cell needs a calculator; an integral given from 0 to a may be a
  decimal on Paper 2 and is whole on Paper 1). The test checks four options with one right in
  both formats and no extra format, every misconception as an option, the counterexample asked
  only of a function that is neither and the sign rule only of a product, a typed k or integral
  marked by its value, and parities, counterexamples, combinations and integrals against hand
  values. The skills' match, error-spot and true-false-reason formats are not built for it (an
  exam type offers no extra format), and match is not in the engine.

<!-- R9-INVERSE -->
- `test_inverse_restricted.gd` (FAL-1007): fn-ahl-inverse-restricted built with every cell (30) and all three AHL2.14
  inverse skills, on AA HL only; a calculator method on Paper 2 and the rest on either paper, with no calculator working
  on Paper 1; four distinct options with one right and the answer in each working's last step; graphs shown; every tag
  shows up; a typed a or k marked by its value; inverses, rules, self-inverse values and meeting points against values
  worked by hand. The skills' multipart, order-steps, error-spot, graph-pick and method-pick formats are not built: the
  type lists value and mcq only.

<!-- R9-AI-COMPOSITE -->
- `test_ai_composite_inverse.gd` (FAL-1007): fn-ai-composite-inverse built with all 35 cells and all
  four AI-AHL2.7 skills, on AI HL only, Paper 2 only; four distinct options with one right and the
  answer in each working's last step, in both formats; a table on the table cell and a figure on every
  graph cell, and four cards on the graph of f⁻¹; every tag shows up; a typed time or value of f⁻¹ is
  marked by its value; the order slip of an equation is never a negative time; hand-worked composites,
  rules, inverses (a line, c + k/x, a + b ln x and the tank's cubic by the solver) and a vertex. The
  type's formats (value, mcq, graph-pick) are all built; its skills' multipart, match and order-steps
  formats are not built in the engine, and error-spot, method-pick and true-false-reason are not in
  the type's formats, so it offers none of them.
- `test_complex_polar.gd` (FAL-1005): the four types on the `complex_polar.gd` recipe, each
  with its own views. t1-ahl-complex-polar (AHL1.13), t1-ahl-de-moivre and
  t1-ahl-conjugate-roots (AHL1.14) are built with every cell for the eleven skills on AA HL
  only, and t1-ai-complex-polar with every cell for the five AI-AHL1.13 skills on AI HL only,
  Paper 2 throughout. On AA HL every cell makes both papers in the bank's ratio, except
  De Moivre's identities and induction proof, which are Paper 1. The test checks four options
  with one right in both formats and no extra format, every misconception as an option, an
  Argand diagram with its axes named Re and Im and its points on it, and De Moivre's
  identities and least powers against hand values. A proof line, a list of roots and an
  identity are claims, picked from four. The types sit in `exponents-logs` beside
  `test_complex_number.gd`'s.
- `test_planner.gd`: the planner's three rules, "Exam-style only", and the save, with
  the migration of a save without `class` and `trees`.
- `test_combat.gd`: a scripted run with a fixed seed and answers gives the same fights,
  results and save; timers on every floor; each outcome's damage and Scrap by tier, with
  and without Time Freeze; glancing hits and the rounding trap; lifelines; "Another
  way" on floor 2 and never on floor 1, and a follow-up that can be made for every cell
  with an extra format (FAL-695); a modifier that doubles Scrap; the stakes table;
  the slot picker; and the journey signals connected to nothing.
- `test_bazaar.gd`: each upgrade stops at its cap, each perk changes exactly its own
  value through the modifiers and is used up after one run, one perk slot, Scrap never
  goes negative and a failed purchase changes nothing, cosmetics, the save and its
  migration, the 70% player's runs per unlock, the screen, the plate and perk on the
  fight screen, the world map opening the Bazaar and leaving it going back there, and the
  store owner's lines on a fixture file (first visit then enter, buy, broke, capped,
  idle and leave, never the same line twice in a row, no file no bubble) and the real
  file's schema.
- `test_fight.gd`: the fight screen plays a miss with its worked solution, a hit, a
  timeout, the lifelines, quit and the summary, the floor select with beaten floors, a
  boss part with the value carried on, the sound effects it asks for (FAL-925), and fits
  at 360x780, 390x844 and 1280x800, with every region's title beside Quit.
- `test_dungeon.gd`: the same seed gives the same floors, fights and bosses; fight 5 is a
  2-part mini-boss and fight 10 a 3- or 4-part boss on one situation, following its chain;
  follow-through after a wrong part; floor 1 serves levels 0 to 2 and floor 4 includes
  level 5; Quadratics' floors match Q4; prior learning after a miss; every type on every
  floor over 200 floors; tiers and timers by floor; the start-floor rule and the save; the
  all-regions dungeon; the "boss beaten" event; and the balance check, which prints the
  average floor and Scrap per run for players who answer 50%, 70% and 90% right.
- `test_maths_engine.gd`: the `MathsEngine` interface reaches no game code (it follows
  class names and script paths from `maths_engine.gd`), the study screen calls only
  `MathsEngine`, and one request and seed give the same maths, marking, misconception
  and worked solution on the practice screen and the study screen.
- `test_practice.gd`: the practice screen plays every representation and format,
  records answers, and fits at 390x844 and 1280x800.
- `test_step.gd`: a worked-solution step as a String or a tagged `{move, board}`: the
  practice screen and Hint show the board, and the export writes text with the moves.
- `test_audio.gd`: a loop per location at the length the review measured, only the
  wired-in loops in `assets/audio/music/`, the effects mirrored from the HTML game, the
  two buses, sound off on a fresh install, settings that survive a reload, and the
  settings screen with the three settings and none of the old playtest rows.
- `test_art.gd`: every art slot loads its file when it's there and falls back when it
  isn't, on tiny fixture images (`tests/fixtures/art/`) and fixture data; the region's
  bosses with their names, taunts and hurt frames; the enemy pool; a region with no art
  playing exactly as before, and the same run with art giving the same results; the
  fight screen, title screen and Bazaar with art and without (the zone's close-up
  with no backdrop); every zone and the Thunderdome naming their bosses; and every
  file in the art folders importing lossy with mipmaps.
- `test_map.gd`: links for every region id on its own zone, every zone, the
  Thunderdome and junk; `island_of()` for every region; coverage against a
  hand count from the catalogue on a scripted save with the switch off and on;
  accuracy, best floor and cleared; the weakest skills leaving out skills with fewer
  than 3 answers; the world map, the zone and the region screen; the course picker
  storing the course and keeping the records; "Coming soon" for a
  region with nothing built, which can't start a run; a run started from the map; the
  zone's loop in a run and the boss loop in a boss; Play opening the map; every
  screen fitting 390x844 and 1280x800; and the FAL-783 layers: no road node and no
  footer, cards hidden until hover, focus or a tap, two taps on touch, the Bazaar as a
  world-map place, painted places on a fixture background, the zoom in and out (and the
  cut with reduced motion), and the region screen over its backdrop. Every zone
  (FAL-925): all five open on the world map, each laid out with no place overlapping
  and a card beside its place, every region and all-regions dungeon opening its screen,
  a run starting in a region of each zone, its all-regions dungeon and the
  Thunderdome, and each zone's loop and boss loop, so all twelve loops are reachable.
- `test_explorer.gd`: the engine explorer opens on a live class with no errors, plays
  each course's own classes (AA HL all of AA SL's, AI SL's inside AI HL's), counts
  the catalogue per topic, plays from its pickers, keeps the situation when it asks
  another way, works without `data/courses.json`, and fits at 390x844 and 1280x800.

## Web export and deploy

The "Web" preset uses the single-threaded template, because GitHub Pages can't send
the cross-origin isolation headers that threads need. Godot's PWA option is off. The
takeover switch has been on since November 4, so the site's root worker is
`_takeover/service-worker.js`, which keeps the export (`index.pck` holds the question
catalogue) for offline play after one visit (the root README, "Switching to Godot", and
`tests/takeover/takeover.spec.mjs`). With the switch off, the HTML game's service worker
covers the site instead and skips `next/` and `classic/` (`service-worker.js`, tested in
`tests/unit/service-worker.test.mjs`).

Export templates: `./export.sh` looks in `$GODOT_TEMPLATES`, then
`<data dir>/godot/export_templates/4.7.2.stable/` under `$XDG_DATA_HOME` and
`/home/matt/.local/share`. If none has `web_nothreads_release.zip`, it runs
`scripts/fetch_web_templates.py`, which pulls just the two Web templates (about 20 MB)
out of the 1.3 GB official archive with HTTP range requests, into
`_scratch/godot-data/`. It then runs the export with `XDG_DATA_HOME` set to that data
dir, for that command only. Then `scripts/share-card.sh` adds the link-preview tags
when there is a share card (see "Art slots"). It takes the page's address as its second
argument, for a build published somewhere other than `/next/`.

`.github/workflows/pages.yml` deploys on every push to `main`: the repo through
`actions/jekyll-build-pages`, plus the export, which `scripts/assemble-site.sh` puts at
the root with the switch on (and at `next/` with it off). Pull requests build it without
deploying. In `.github/workflows/test.yml` the `godot` job runs `./test.sh`, the `export` job
builds the export once, and the `web` job takes it for the browser screenshots and uploads
the screenshots as an artifact.

## Godot MCP

Start your own headless editor, call tools, stop it:

```bash
scripts/mcp-editor.sh start      # editor MCP port in 6551-6560, LSP on 6025
python3 -I scripts/mcp_call.py --list
python3 -I scripts/mcp_call.py scene_open '{"file_path":"res://scenes/main.tscn"}' scene_get_tree '{}'
scripts/mcp-editor.sh stop
```

Don't run `./export.sh` or `godot --import` while it is up (`./test.sh` skips its
import then, and `./export.sh` refuses). See `docs/MCP-NOTES.md` for what works, the
value formats the tools want, and the rules.
