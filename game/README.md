# Wasteland Academy (Godot)

The Godot 4.7.2 rebuild of Wasteland Academy, planned on FAL-274. It is played in the
browser as a web build, published at `/next/` beside the HTML game. All code is
GDScript (C# can't export to the web), and it uses the Compatibility renderer.

The toolchain is copied from The Unruly Atlas.

## Layout

```
game/
├── project.godot        ← portrait 1080x1920 base, "expand" stretch, Compatibility renderer
├── export_presets.cfg   ← one preset, "Web": no threads, no PWA
├── scenes/main.tscn     ← title screen (title, Spark, Play, Practice, Engine)
├── scenes/map.tscn      ← the map (ui/map.gd): world, island, region screen (see "The map")
├── scenes/practice.tscn ← the practice screen (ui/practice.gd)
├── scenes/fight.tscn    ← the fight screen (ui/fight.gd), on the practice screen's card
├── scenes/explorer.tscn ← the engine explorer (ui/explorer.gd), at /next/?explore
├── engine/              ← the question engine: situations, views, marking, planner, save
├── engine/run.gd        ← a run: floors, fights, bosses, outcomes, lifelines, the hooks (see "Combat")
├── engine/dungeon.gd    ← floors by level, tiers, boss chains, start floors (see "The dungeon")
├── engine/map_link.gd   ← map links (#functions/quadratics), browser history, music by island
├── engine/progress.gd   ← a region's accuracy, best floor, coverage and weakest skills
├── engine/tuning.gd     ← every combat number: timers, tiers, Scrap, stakes, lifelines, floors, chains, Bazaar prices
├── engine/bazaar.gd     ← the Bazaar's rules: upgrades, perks, cosmetics (see "The Bazaar")
├── engine/art_slots.gd  ← art by file name, with a fallback for each (see "Art slots")
├── engine/step.gd       ← a worked-solution step: a String, or {move, board} with a move tag (see "Question engine")
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
├── tools/stress_questions.gd  ← used by ../tools/stress-questions
├── tools/bazaar_sim.gd, bazaar_balance.gd  ← the Bazaar's balance check and price table
├── addons/godot_mcp_toolkit/  ← editor plugin for the Godot MCP (see docs/MCP-NOTES.md)
└── docs/MCP-NOTES.md
```

`config/name` is "Wasteland Academy", so its `user://` folder is its own, not the Atlas's.

Art is imported with mipmaps on (`mipmaps/generate=true` in each `.import`) and drawn
with linear mipmap filtering, so it stays smooth at phone and PC sizes. New art imports
lossy too (see "Art slots"): `project.godot`'s `[importer_defaults]` give a new file
both, so let Godot write its `.import`.

## Sound

Two autoloads, added on FAL-385. `Audio` (`audio/audio.gd`) owns the music, the effects
and the three settings; `AudioHud` (`scenes/audio_hud.tscn`) is the speaker icon and the
gear that sit above every scene, with the settings screen behind the gear.

```gdscript
Audio.play_location("signal-tower")  # crossfade to that location's loop
Audio.play_sfx("correct")            # one short effect
Audio.sound_enabled = true           # what the speaker icon switches
```

- **Sound starts off**, on a fresh install and for every student in a classroom. Nothing
  is decoded or played until the speaker is tapped, which also satisfies the browser rule
  that audio needs a gesture first.
- The three settings (`sound_enabled`, `music_volume`, `sfx_volume`) save to
  `user://settings.cfg` the moment they change, and load at boot.
- Buses: Master, with **Music** and **SFX** under it (`audio/bus_layout.tres`). Each
  slider moves one bus; turning sound off mutes both and stops the players.
- Which loop plays at which location, and the alternate seed waiting on Matt's listening
  pass, is the one table in `audio/music_tracks.gd`. The effect cues mirror the HTML
  game's `js/sfx.js` and live in `audio/sfx_cues.gd`.
- Every file in `assets/audio/` has its licence entry in `../assets/audio/CREDITS.md`.
  Nothing ships without one.
- The map and the runs choose the loop (FAL-417): the world map plays `overworld`, an
  island and its runs play the island's loop, and a mini-boss or boss its `-boss` loop
  (`MapLink.music_for`). The settings screen has only the three settings.

## Scripts (run from the repo root)

Godot is found on `PATH`, at `~/.local/bin/godot`, or from `GODOT=/path/to/godot`.

| Command | What it does |
|---|---|
| `./run.sh` | Opens the game in a 540x960 window |
| `./test.sh` | Headless import, then every `game/tests/test_*.gd`. Exits non-zero on any failure |
| `./export.sh [dir]` | Web export into `build/next/` (or `dir`). Fetches the Web export templates first if Godot can't find them |
| `./screenshot.sh [out.png] [scene]` | Renders a scene at 1080x1920 in a private Xvfb display |
| `node scripts/web-screenshot.mjs [export dir] [out dir] [name=?query ...]` | Serves an export at `/wasteland-academy/next/` and screenshots it in headless Chromium at 390x844 and 1280x800, plus each named deep link. Fails if the page logs an error |
| `tools/check-answers` | The SymPy answer checker (see below) |
| `tools/stress-questions [--from=51] [--to=2250]` | The seed sweep (see below) |
| `scripts/mcp-editor.sh start\|stop` | Headless editor on `game/` for the Godot MCP |
| `python3 -I scripts/mcp_call.py <tool> '<json>' ...` | Calls Godot MCP tools through that editor |

## Question engine

The maths engine plans from situations and views (FAL-310 plan), on the catalogue in
`curriculum/question-types.json`. The game reads a generated copy,
`data/catalogue.json`, with every type of all five topics and the topic names: rerun `node tools/game-catalogue.mjs --write` after changing the
catalogue (`tests/unit/game-catalogue.test.mjs` fails while the copy is stale).

- A **recipe** (`engine/situations/quadratic.gd`) generates a **situation**: a, the
  roots, the vertex, b, c, Δ, an extra point and a table, consistent and inside the
  catalogue's `clean` limits, in one of its `modes` (rational roots, surd roots, no real
  roots). Situations that extend `quadratic` call its `generate()` and add their own
  quantities. `engine/situations/triangle.gd` is the Topic 3 situation: one triangle
  ABC, with whole-number givens for the view (two sides and the angle between them,
  three sides, two angles and a side, and so on), solved whole. Its views
  (`triangle_views.gd`) show it in words or as a labelled drawing (`ui/triangle_view.gd`),
  and on Paper 2 every answer is a measure to 3 s.f. (FAL-395), never a rational value
  that needs no calculator. Its Paper 1 version (FAL-419) gives angles of 30°, 45°, 60°,
  90°, 120° or 135° and sides chosen so the answer is exact: a whole number (3, 5, 7 with
  120°) or m√r (the `surd` kind), marked exactly, with the exact sines and cosines in the
  working. Every cell makes both papers but the sine rule's angle, which is Paper 2 only.
- `engine/situations/arithmetic_sequence.gd` (FAL-392) is the Topic 1
  situation: one arithmetic sequence with u₁, d, n, uₙ, Sₙ, two later terms and the
  first four terms, for `t1-arithmetic-sequence`. Its representations are `notation`
  (u₁ = 7,  d = 3), `terms` (7, 10, 13, 16, …), `table` (n against uₙ) and `words`,
  and its answers are marked exactly (`exact` on the answer), because Paper 1 wants a
  whole-number sum such as 1807, not 1810. Its Paper 2 version (FAL-419), in words only,
  is a savings plan in dollars and cents or a training plan in km with a decimal u₁ and
  d, worked with a GDC: a term or a sum (money to 2 d.p. or a decimal, still exact, since
  it ends), or the first week or day whose term or running total is more than a round
  threshold (a whole n). Any type with a `situation` gets a copy in
  `data/catalogue.json`, whatever its topic.
- `engine/situations/distribution.gd` (FAL-396) is the Topic 4 situation: one
  discrete random variable X with 3 to 5 values, its probabilities as multiples of k,
  a formula P(X = x) = k f(x) or decimals, or a game with prizes and a stake. Its views
  (`distribution_views.gd`) show it as a table, a formula or in words, and ask k, a
  missing probability, P(event), E(X), p and q from E(X), the fair stake, an expected
  number of occurrences or the number of trials. Every cell makes both papers (FAL-419):
  Paper 2 has awkward decimals to 3 d.p. (0.137), k beside them or in a reciprocal
  formula (k/x), and a lucky dip of 1000 tokens; k, E(X), an expected number and a
  formula's P(event) are then answered to 3 s.f. with the rounding trap, the stake to the
  nearest cent, and the rest exactly. Paper 1 keeps its numbers.
- The rest of the Quadratics region (FAL-414) is four more situations. Three extend
  `quadratic` by calling its `generate()`: `quadratic_parameter.gd` (a quadratic with a
  constant k, given directly or as a line meeting a curve, for `fn-discriminant`),
  `quadratic_equation.gd` (the quadratic = 0, plain or wrapped: a context, b^(2x), x + c/x,
  a sum of logs, for `fn-solve-quadratic`) and `quadratic_inequality.gd` (the parabola
  against a number, for `fn-quadratic-inequality`). `curve_line.gd` stands alone: it picks
  the meeting x-values first and builds the curve as the line plus a(x − x₁)(x − x₂), for
  `fn-curve-intersection-quadratic`. Their answers add kinds to `answer.gd`: `interval`
  (k is between or outside two numbers, with the ends left out or included), `bound`
  (k > 4), `kvals`, `delta_nature`, `quad_in` (Δ in k, or a quadratic in u), `kpoint`,
  `points2` (two points, either order), `surd` (m√r), `surd_roots`, `line`, `npoint`,
  `kroot`, `ineq_a` and `choice`. The graph view also draws a line (`graph.line`). The
  Paper 2 context (a length to 3 s.f.) is never for the factorising method:
  `QuestionEngine.make()` passes the method that made the numbers to the recipe as
  `need.angle`. That is the `same_angle` method for "Another way", so switching to
  factorising keeps a Paper 2 context, and the factorising working says it fails there
  and uses the formula. The seeded stream's first draw leans low, so these recipes spend it first.
  Paper 2 versions (FAL-419), chosen by `need.paper` with each views' `papers()`: in
  `fn-solve-quadratic` a context, b^(2x) (u not a power of b, so x = ln u/ln b) and a sum
  of logs (x(x + d) = c with no whole root), each x to 3 s.f.; in `fn-quadratic-inequality`
  against 0, against a constant and with a < 0, whole-number coefficients with irrational
  roots, the interval's ends to 3 s.f. (a Paper 2 graph marks no roots), and the
  largest-integer context is always Paper 2; in `fn-discriminant` equal roots (not on a
  sketch), an interval of k and "always positive" on the families whose Δ is a quadratic
  in k (b, grad, both) with irrational zeros, k to 3 s.f. `interval`, `bound` and `kvals`
  answers honour `show: "sf"`. `fn-ext-quadratic-model` picks its own paper, but takes a
  forced one (a ball with a = −4.9 on Paper 2; pens and tables are Paper 1).
- `engine/situations/cubic.gd` is the Topic 5 situation: a cubic built
  from f′(x) = 3a(x − p)(x − q), so its stationary points are on whole numbers, with a
  point x₀ for the gradient, tangent and normal (FAL-394). Its Paper 2 version
  (FAL-419) is a calculator cubic with decimal coefficients and irrational stationary
  points, x₀ a decimal: x for a gradient, the tangent, the normal, the stationary points
  and the local maximum are then asked to 3 s.f. with GDC working (`roots`, `line` and
  `points2` honour `show: "sf"`); the derivatives, k, the nature and the inflexion stay
  Paper 1.
- **The Quadratics extension types** (FAL-459) are seven more situations, one per
  type: `expand.gd`, `factorise.gd`, `surds.gd` and `linear_inequality.gd` (the
  `fn-pre-*` prior learning, which the dungeon's warm-ups and after-a-miss questions
  now play), `quadratic_model.gd` (a thrown ball or a fenced pen, Paper 2 with
  a = −4.9), `equivalent_forms.gd` and `symmetry.gd` (the two link types, which reach
  into log laws, cos 2x, negative powers, the normal curve, related angles and nCr).
  Their views extend `extension_views.gd`. Each is built from its answer, so the
  numbers stay clean. The `fn-pre-*` misconceptions have no catalogue ref, so they
  are logged as `<type id>#<index>` (`QuestionEngine.misconception_text`). The area
  grid of `fn-pre-expand` and `fn-pre-factorise` is a table, and `ui/plot_view.gd` draws
  the graphs that aren't a parabola: a number line, a shaded normal curve, sin x or
  cos x on [0, 2π], and the bars of a row of Pascal's triangle. Views whose context
  depends on the method (find-the-mirror: a parabola or nCr) define `build_view()`,
  which is told the method. New answer kinds: `poly` (powers fixed or typed),
  `named`, `pair`, `brackets`, `brackets2`, `common`, `pm_surd`, `range2`,
  `related`, `features` and `angles`. An answer can set `show: "sf"` (3 s.f.), and
  options of such an answer are told apart by their text.
- **The Exponentials and logs region** (FAL-418) adds four exam situations and three
  extension ones. `exp_model.gd` is one model in a context, Paper 2 (values and times to
  3 s.f.): growth or decay as P₀(a)ᵗ, shifted, continuous with k given or from a
  half-life or a reading, limited growth C + Ae^(−kt), a log₁₀ reading, or two models
  that meet. `exp_log_pair.gd` is an exponential and its log inverse, with modes for
  bases from one family, an e-equation, a composite inequality, a translation or stretch
  between exponentials, f∘g against g∘f and the log of a square; `fn-ext-exp-graph`
  shares it (A·b^(x − h) + c). Its Paper 2 version (FAL-419) asks g at an input whose
  inside is not a power of b, g⁻¹ at a decimal, log_b(x − h) + c = a decimal and
  e^(mx) + c = d, each to 3 s.f. with a GDC and the rounding trap; `fn-ext-exp-graph`
  stays Paper 1. `log_quadratic.gd` extends `quadratic`: a downward
  parabola whose top is a whole power of the log's base, so the maximum, the base and the
  surd zeros come out exact. `log_function.gd` extends `exp-log-pair`: A·log_b(mx + n) + c.
  The extension situations are `percent.gd` (`fn-pre-percent-multiplier`),
  `growth_patterns.gd` (`exp-growth-vs-linear`, extending `exp-model`) and
  `link_growth.gd` (`fn-link-multiplicative-growth`). `engine/plot.gd` makes graph specs
  of sampled curves with dashed asymptotes, which `ui/graph_view.gd` draws. New answer
  kinds: `lnq` (an exact k as m·ln r, marked by value, so (1/5) ln(1/2) is −(ln 2)/5),
  `pct` (a rise or fall of r%), `expmodel` (P₀(a)ᵗ), `limited` (C, A and k), `fn` (a
  function of x with its shifts typed; a wrong option may take another form, such as
  1/f(x) or (x − p)ᵇ + q), `logform` (log_b x = y) and `xpow` (xⁿ). `Answer.typable()`
  says whether an option could be typed into the answer's slots; a wrong option in
  another form can be picked but is never taken as a typed misconception. The
  catalogue's pick-the-graph unknowns play as four descriptions (from the equation) or
  four equations (from the graph) until that format is built.
- A **view** picks the unknown, the representation, the angle (method) and the format.
  `engine/situations/quadratic_views.gd` has one builder per unknown: what is shown,
  the answer, the wrong options (each catalogue misconception's `wrong` rule, tagged
  with its `ref`) and a worked solution for every method that suits the unknown.
- A **worked-solution step** (FAL-426) in `methods[angle].steps` is a String, or
  `{"move": "<move id>", "board": "<text>"}` when it carries a move tag for the
  explainers: the move is the general step from `curriculum/moves.json`, and the board
  is this question's text. Read steps with `Step.text(st)` (what is shown: the board,
  or the String) and `Step.move(st)` (the move id, or ""), never by type. The checker's
  export writes steps as text, with each solution's `moves` beside them (a move id or
  null per step).
- `QuestionEngine.make(view)` (`engine/question_engine.gd`) returns the question, its
  marking and its working for any explicit view and seed. The same view and seed always
  give the same question. `QuestionEngine.cells()` lists the coverage cells.
- **One situation, many questions**: each view sets its own `need`, so on its own each
  unknown gets its own numbers. `QuestionEngine.families(type, rep)` splits the
  unknowns that list a representation into families whose needs merge with no conflict
  (`merge_need()`: booleans or-ed, `"any"` gives way to a set value). A view with
  `"shared": true` is built on its family's situation, generated from the merged need,
  so every unknown of the family has the same numbers for the same seed. A situation's
  views can define their own `merge_need()` if the default doesn't suit them.
- **Formats**: the layer names all eight from the plan. `value` (slot inputs such as
  a(x − □)² + □) and `mcq` are built, and the concept probes play as a verdict
  (true or false; always, sometimes or never; the sign) and then the reason.
  Three more are built on a question's multiple-choice form (FAL-459), each as four
  options with a `reason` shown after the answer: **error-spot** (a student's four
  lines of working, from the catalogue's `error-spot` misconceptions; which line is
  the first wrong one), **method-pick** (which method works: the view's method against
  the catalogue's failing methods and the view's own `pick_wrongs`; never asked on a
  method the catalogue says fails) and **true-false-reason** (a student's answer,
  right or one of the wrong options; agreeing with a misconception logs it). A cell
  offers one only where its type's catalogue `formats` lists it and its views build it
  (`QuestionEngine.extra_formats()`), and the planner and a boss's link part ask one
  about a third of the time (`EXTRA_SHARE`). Exam types offer none. `match`,
  `multipart`, `order-steps` and `pick-the-graph` are not built.
- **Paper 1 or 2** (FAL-419): every question carries `paper`. Paper 1 numbers come out
  exact; Paper 2 numbers need a calculator, and only Paper 2 questions show the
  Calculator button (see "The calculator"). A type the IB asks on both papers makes
  both, in the ratio of its bank parts (`paper: {"p1", "p2"}` in `data/catalogue.json`,
  from `stats.paper`). Each situation's views say which papers a cell can make
  (`papers(unknown, rep, angle)`: `[1]`, `[2]` or `[1, 2]`); `QuestionEngine` draws the
  paper on its own seeded stream (so the numbers stream is untouched), boosting the
  cells that can make both so the type lands on the exam's share
  (`QuestionEngine.paper_chance`), and hands it to the recipe as `need.paper`. A
  situation that sets its own `paper` has the last word, so the badge always matches the
  numbers. A boss chain and a family's shared situation are on one paper. Extension types
  have no exam counts, so their recipes decide as before. Concept probes are Paper 1. A
  view may force one with `"paper": 1` or `2` (and a deep link with `&paper=2`).
- **Marking** (`engine/answer.gd`): exact or right to 3 s.f. More figures are right too
  when they are the value correctly rounded (12.35 for 12.3456). The right value with
  too few figures (2.3 for 2.347) is a **glancing hit** (Q7): `mark()` returns
  `glancing`, and combat does half damage with the note "The IB needs 3 s.f.". Only a
  value that needs rounding has one (1 is not a glancing ½), and an `exact` answer has none. An answer's `show` writes
  it as a decimal (0.35) or as money (2.50) instead of a fraction; probabilities are
  answered the way the question gives them. Typed numbers are read
  by the calculator's expression engine (`engine/expr.gd`), so 3/2, −1.5, 2(3) and 2^-1
  all work; the value must be a fraction of whole numbers (`Expr.eval_exact`), so exact
  marking stays exact, and √2 or ln 2 gets "Work that out to a number". Godot's
  `Expression` class is never used on what a student types (`test_expr.gd` checks).
- **Planner** (`engine/planner.gd`): never-seen cell, then a recently missed one, then
  exam frequency. "Exam-style only" (off by default) keeps exam cells only and follows
  exam frequency.
- **Rounding trap** (Q7), **a rule for every situation**: a view's builder returns
  `trap`, from `Answer.rounding_trap(answer)`. Where the answer is one number that
  needs rounding at 3 s.f., that is the number rounded to 2 s.f., and `_choices()`
  makes it one of the four options (shown as a decimal, tagged `trap`), first in line
  ahead of the misconceptions. Picking it is a glancing hit. Where it doesn't fit, it is
  `{}`. The `quadratic` views set it; every quadratic answer is exact today, so none has
  one yet. Situations whose answers are 3 s.f. measures (triangles, distributions) need
  a checker rule for the 2 s.f. text before they offer it.
- **Marks**: each question carries `marks`, the type's median marks in the exam bank
  (`stats.marks.median`, copied into the catalogue as `marks`), unless the view sets its
  own. The timer is built from it. Extension types have none and use `Tuning.DEFAULT_MARKS`.
- **Save** (`engine/save_data.gd`): versioned, with a migration step per version.
  Version 2 (FAL-413): `class` is null until classes exist, `trees` and `lessons` are
  empty, `scrap` is the Scrap banked from runs and `runs` totals them. A save without
  `class` or `trees` gets them on load. Version 3 (FAL-415): `dungeon` holds each
  region's best floor and the floors whose boss fell. Version 4 (FAL-416): `bazaar`,
  what the Bazaar sold; an older save gets a blank one and keeps its Scrap to spend.

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
draws the run: enemy and player HP, the timer bar, the lifelines, the card, and the
summary. It keeps room above the card for the journey strip (FAL-331). The lifeline row
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
  counts parts; surviving every part beats it. A boss ends with one link question where
  the region has one built (`Tuning.BOSS_LINK_PART`). A floor with no chain built has a
  normal fight at the boss's tier instead.
- **The "boss beaten" event.** The heal `Tuning.BOSS_HEAL` (0) goes through
  `modifiers.apply("boss_heal", ...)` with `ctx.boss` "mini" or "boss", then through
  `heal`, then `boss_beaten(floor, kind)` fires. Second Wind (G6) adds 20 there.
- **Start floor.** `Dungeon.start_floors(save, region)` is floor 1 and, for every floor
  N whose boss the player has beaten, floor N + 1. The fight screen opens on a floor select with those floors.
  The save keeps `dungeon[region] = {"best", "beaten"}`.
- **All regions.** Region `"all"` (`Dungeon.ALL`) mixes every built type of the island
  (every type with a region). The map's "All regions" spot is `#functions/all`.

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

The strip (FAL-331) isn't merged yet, so the fight screen keeps an empty
`JourneyStrip` box above the card for it.

### Deep links

The practice screen takes deep links, for screenshots and for sending someone a
question: `/next/?view=<type>/<unknown>/<rep>/<angle>/<value|mcq>&seed=3`, or
`<type>/probe/<n>` for a concept probe. Add `&autoplay=right` (or `wrong`) to answer it
at once, and `&paper=1` or `2` for that paper where the cell can make it. On a Paper 2
question, `&calc=sci` or `&calc=graph` opens the calculator, with `&do=expr;expr` worked
out in Scientific mode, or `&y1=`, `&y2=`, `&win=xmin,xmax,ymin,ymax`,
`&tool=zero|max|min|intersect` and `&deg=1` in Graph mode (the screenshots use these).
The fight screen takes `/next/?play=quadratics&seed=3&floor=1`, with
`&autoplay=right`, `wrong`, or `lose` (wrong answers to the end, for the summary). `play`
is a region id or `all`. `floor` must be one the save may start on, else the run starts
on floor 1. `&fight=5` or `&fight=10` starts at the mini-boss or boss (such a run records
no floors), and `&autoplay=carry` answers its first part wrong and opens the next, to show
the value carried on. `&select=1` shows the floor select.

The map takes a hash: `/next/#functions/quadratics` opens that region's screen,
`/next/#functions` the island and `/next/#world` the world map (see "The map").

### The engine explorer

`/next/?explore`, or "Engine" on the title screen (FAL-391). Pick a course, a topic and
a question class, then "Asked for", "Shown as", "Method" and the format, and play the
question as on the practice screen. Nothing is saved. Question classes come from the
catalogue: a type is live when its situation is built, so a new situation shows up
with no change here, and the rest are listed greyed out. "New question" draws a random
seed; "Ask it another way" keeps the seed and the family's situation and asks the next
unknown of the family; "Show 10 versions" shows ten seeds with their answers. The class
size line counts `QuestionEngine.cells()`. Courses come from `data/courses.json` when it
is there, and from a built-in list (AA SL live, the rest "syllabus mapping in
progress") when it isn't. Phones show the choices and the question one at a time;
landscape shows them side by side.

The URL follows the screen, so a state can be bookmarked:
`/next/?explore&view=<type>/<unknown>/<rep>/<angle>/<value|mcq>&seed=3`, plus
`&ten=1` for ten versions or `&autoplay=right` (or `wrong`).

### The SymPy answer checker

`tools/check-answers` exports questions from the engine with fixed seeds (at least 50
per coverage cell and 1,000 per type), then `tools/check_answers.py` solves each one
again with SymPy from its givens. It shares no code with the engine. It checks the
answer, the clean limits, that every option but one is wrong and that all four differ,
that every worked solution ends at the answer, and that the equations shown parse to
the givens. Each situation has its own checks (`SITUATION_CHECKS`, keyed by the
`situation_id` every question exports); the answer, option and working checks are
shared. For arithmetic sequences it reads u₁, d and n back from the notation line, the
terms, the table, the words and the question text, solves them with SymPy, and checks
they give the sequence in the givens. For the four FAL-414 situations it reads the
equations, sentences and sketches back, solves the unknown (Δ in k, the meeting points,
the valid root, the solution set) and works out each tagged misconception's wrong value
itself, and every worked solution must be 2 to 5 steps. For the seven FAL-459 situations
it does the same, with SymPy, mpmath and the catalogue's own method names: an error-spot
question's first wrong line is found again from the working (each line an identity, a
solution set or a surd claim), a method-pick question's wrong methods must not work, and
a true-false-reason question's student answer must be one of the question's options.
For the FAL-418 situations it reads the model or function back from the lines, works
out every value with SymPy (an inverse is checked by composing it with the original at
several points; domains, signs and inequalities with `solveset`), checks the curves and
marked points of each graph against the function, and keeps the clean limits (`EM_*`,
`LQ_*`, `LF_*`, `PC_*`, `LG_*`), including that no 3 s.f. answer sits on a rounding edge.
Each cell also gets 10 questions made on its family's shared situation, and 20 in each
extra format it offers (`--per-format`). Every mini-boss and boss chain is exported too
(`--per-chain`, 50 seeds), each part as a question checked like the rest, and then as a
chain: one situation, and each part's `carried` value is the part before's answer. It
prints a table per type and per cell. SymPy is pinned in
`requirements.txt` and installed into a gitignored `.venv/` on first run. CI runs it
as its own `answers` job.

### The seed sweep

The checker only exports seeds 1 to 50. `tools/stress-questions` makes every cell with
seeds 51 to 2250 (about 258,000 questions, a few minutes) and checks that each question
is made with four options (every fourth seed also on its family's shared situation, and
in each extra format the cell offers), that its own answer typed exactly and to 3 s.f. is marked
right, and that every wrong option typed in is marked wrong with its misconception. It
does the same for every boss chain with seeds 51 to 1050, and checks each part's carried
value. It fails on any script error, such as a failed assert in `Q`. CI runs it as its
own `stress` job. `--types=id,id` sweeps only those types. An exact answer (an exact k,
−(ln 2)/3) is only right exactly, so its 3 s.f. decimal is checked only where that
decimal is the exact value, and a wrong option that can't be typed (`Answer.typable`) is
not typed in.

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

`scenes/map.tscn` (`ui/map.gd`, FAL-417; Q3 and Q11 on the FAL-274 plan). "Play" on the
title screen opens it. One scene with three screens:

- **The world map**: the HTML game's overworld painting (`assets/map/overworld.png`)
  with a button over each island. The Signal Tower (Functions) is open; the other four
  say "Coming later". The Thunderdome stays locked until a second island opens
  (`MapLink.OPEN_ISLANDS`), and the Relic Library has a locked spot. A bar under the
  painting opens the Bazaar (see "The Bazaar") and shows the Scrap there is to spend.
- **The Functions island**: the 8 regions in the catalogue's `order`, the all-regions
  dungeon and a locked Relic device spot. A region whose types aren't built yet says
  "Coming soon" and can't start a run or Practice. That comes from the engine
  (`Progress.is_built`, which asks `Dungeon.region_types`), so a region opens when its
  situations merge, with no map change.
- **The region screen**: accuracy, best floor and coverage ("34 of 52 checked": the
  cells the save has seen against the catalogue's cells for the region, built or not),
  all following the "Exam-style only" switch, which the screen also carries. Then the 3
  weakest skills: the lowest accuracy among skills with at least 3 answers, where each
  answer counts for every skill its unknown lists (`Progress.weakest_skills`). Skill
  names come from `curriculum/aa-sl.json` via `catalogue.json`'s `skills`. Its buttons
  start floor 1, start after a beaten boss (`Dungeon.start_floors`) or open Practice on
  that region.

**Links and the back button.** On the web the hash is the route. Moving on the map
sets it, which makes a browser history entry, and a `hashchange` (back, forward, a
pasted link) sends the game there. Back from a run quits it, so its Scrap is banked.
An unknown link opens the world map and rewrites the address bar to `#world`. `#bazaar`
is the Bazaar: its own scene, but a map link like the others, so back leaves it. On the
desktop, `-- --map=functions/quadratics` does the same as the hash.

### Map art

The island map loads its art by file name from `game/assets/map/functions/`. Each file
is optional: when one isn't there, that piece keeps the coded look (a dusk gradient
with a dashed trail, and a numbered ring in the state's colour), so art can land one
file at a time. Import each with mipmaps on, like the rest of the art.

| File | Size | What it is |
|---|---|---|
| `background.png` | 1080x1920, opaque | The whole island, portrait. The spots sit on it at the places in `SPOTS` in `ui/map.gd` (% of the board), climbing from Quadratics at the bottom to the tower at the top |
| `<spot>-locked.png` | 256x256, transparent | A spot's landmark before its questions are built |
| `<spot>-open.png` | 256x256, transparent | A spot's landmark once it can be played |
| `<spot>-cleared.png` | 256x256, transparent | A spot's landmark once floor 3's boss is beaten there |

`<spot>` is a region id (`quadratics`, `exp-log`, `graphs-features`,
`composite-inverse`, `rational`, `function-basics`, `lines`, `transformations`), `all`
for the all-regions dungeon at the tower, or `relic` for the Relic device (only
`relic-locked.png` is used for now). A landmark is drawn in a 200x200 box, kept square
and centred, with the spot's name and progress line under it, so leave the bottom of
the background clear below each spot.

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

**`assets/regions/<region-id>/`**, for `quadratics`, `exp-log`, `graphs-features`,
`composite-inverse`, `rational`, `function-basics`, `lines` and `transformations`
(`all`, the all-regions dungeon, works too)

| File | Size | Where it shows | With no file |
|---|---|---|---|
| `backdrop` | 1920×1080, opaque, dark | Behind the fight screen and its floor select, cover-fitted under a 55% wash of the background colour. A phone held upright shows about the centre 500 px, so keep what matters in the centre 600 | The plain background |
| `miniboss` | 512×512, transparent | Fight 5, the mini-boss, in the 190 px enemy box | The tier's enemy (see `enemies/`) |
| `miniboss-hurt` | 512×512, transparent: the same pose, size and place | Flashes for 80 ms when a hit lands | No flash |
| `boss` | 512×512, transparent | Fight 10, the boss | The tier's enemy |
| `boss-hurt` | 512×512, transparent: the same pose, size and place | Flashes for 80 ms when a hit lands | No flash |

Each mini-boss's and boss's name and one-line taunt are in `data/bosses.json`:
`{"<region-id>": {"miniboss": {"name", "taunt"}, "boss": {"name", "taunt"}}}`. The
name replaces the tier name over the HP bar, and the taunt opens the fight on the card.
A region with no entry shows "Mini-boss Enforcer" and the like, as before, and no taunt.

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
| `shopkeeper` | 512×512, transparent | Beside the Bazaar's title, at 200 px | No shopkeeper |
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

Not here: the island map (`assets/map/functions/`, see "Map art"), and the weak-skills
flag on the map, which has no slot yet.

## The Bazaar

Scrap banked from runs buys things at the Bazaar (G6, Q10). The world map's bottom bar
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
- Links: `/next/#bazaar` is its map link; `/next/?bazaar` opens it too, and
  `/next/?bazaar=demo` opens it on a sample save and stores nothing (screenshots).

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
- `test_quadratics.gd`: the four FAL-414 types: built with every cell, 2 to 5 steps per
  worked solution, every distractor misconception as an option (three that no answer
  shape can carry yet are listed with the reason), two rays typed as one interval caught
  as SL2.7.inequality#1, two points in either order, a tangent's point on both graphs,
  Paper 2 contexts (never for factorising), every cell with both papers exact on Paper 1
  and to 3 s.f. with calculator working on Paper 2, a quadratic model taking a forced
  paper, and "Another way" keeping the numbers for every fn-solve-quadratic unknown and
  pair of methods.
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
- `test_planner.gd`: the planner's three rules, "Exam-style only", and the save, with
  the migration of a save without `class` and `trees`.
- `test_combat.gd`: a scripted run with a fixed seed and answers gives the same fights,
  results and save; timers on every floor; each outcome's damage and Scrap by tier, with
  and without Time Freeze; glancing hits and the rounding trap; lifelines; "Another
  way" on floor 2 and never on floor 1; a modifier that doubles Scrap; the stakes table;
  the slot picker; and the journey signals connected to nothing.
- `test_bazaar.gd`: each upgrade stops at its cap, each perk changes exactly its own
  value through the modifiers and is used up after one run, one perk slot, Scrap never
  goes negative and a failed purchase changes nothing, cosmetics, the save and its
  migration, the 70% player's runs per unlock, the screen, the plate and perk on the
  fight screen, and the world map opening the Bazaar and leaving it going back there.
- `test_fight.gd`: the fight screen plays a miss with its worked solution, a hit, a
  timeout, the lifelines, quit and the summary, the floor select with beaten floors, a
  boss part with the value carried on, and fits at 360x780, 390x844 and 1280x800.
- `test_dungeon.gd`: the same seed gives the same floors, fights and bosses; fight 5 is a
  2-part mini-boss and fight 10 a 3- or 4-part boss on one situation, following its chain;
  follow-through after a wrong part; floor 1 serves levels 0 to 2 and floor 4 includes
  level 5; Quadratics' floors match Q4; prior learning after a miss; every type on every
  floor over 200 floors; tiers and timers by floor; the start-floor rule and the save; the
  all-regions dungeon; the "boss beaten" event; and the balance check, which prints the
  average floor and Scrap per run for players who answer 50%, 70% and 90% right.
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
  fight screen, title screen and Bazaar with art and without; and every file in the art
  folders importing lossy with mipmaps.
- `test_map.gd`: links for every region id, the island and junk; coverage against a
  hand count from the catalogue on a scripted save with the switch off and on;
  accuracy, best floor and cleared; the weakest skills leaving out skills with fewer
  than 3 answers; the world map, the island and the region screen; "Coming soon" for a
  region with nothing built, which can't start a run; a run started from the map; the
  island's loop in a run and the boss loop in a boss; Play opening the map; and every
  screen fitting 390x844 and 1280x800.
- `test_explorer.gd`: the engine explorer opens on a live class with no errors, counts
  the catalogue per topic, plays from its pickers, keeps the situation when it asks
  another way, works without `data/courses.json`, and fits at 390x844 and 1280x800.

## Web export and deploy

The "Web" preset uses the single-threaded template, because GitHub Pages can't send
the cross-origin isolation headers that threads need. Godot's PWA option is off: the
HTML game's service worker covers the whole site, and it skips `next/` and `classic/`
(`service-worker.js`, tested in `tests/unit/service-worker.test.mjs`).

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
`actions/jekyll-build-pages` (the same build Pages' branch deploy runs, so the HTML
game's URLs don't change), plus the export at `next/`. Pull requests build it without
deploying. The `godot` job in `.github/workflows/test.yml` runs `./test.sh`, the export
and the browser screenshots, and uploads the screenshots as an artifact.

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
