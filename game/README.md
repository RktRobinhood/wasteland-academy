# Wasteland Academy (Godot)

The Godot 4.7.2 rebuild of Wasteland Academy, planned on FAL-274. It is played in the
browser as a web build, published at the main address, with the HTML game at
`/classic/`. All code is GDScript (C# can't export to the web), and it uses the Compatibility renderer.

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
├── scenes/explorer.tscn ← the engine explorer (ui/explorer.gd), at /?explore
├── engine/              ← the question engine: situations, views, marking, planner, save
├── engine/run.gd        ← a run: floors, fights, bosses, outcomes, lifelines, the hooks (see "Combat")
├── engine/dungeon.gd    ← floors by level, tiers, boss chains, start floors (see "The dungeon")
├── engine/map_link.gd   ← map links (#functions/quadratics), browser history, music by island
├── engine/progress.gd   ← a region's accuracy, best floor, coverage and weakest skills
├── engine/courses.gd    ← the student's IB course and what it covers (see "Courses")
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
├── tools/course_report.gd  ← used by ../tools/course-audit
├── tools/stress_questions.gd  ← used by ../tools/stress-questions
├── tools/feedback_check.gd    ← used by ../tools/feedback-check
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
| `tools/feedback-check [--seeds=12] [--rows=file.tsv] [--all]` | What a student reads after a wrong answer (see below). CI runs it in its own job |
| `tools/course-audit` | Where the engine stands for each IB course: skills, types and built questions (see below) |
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
  working. On Paper 2 the working shows four figures, or more where the next step
  worked from four would be off in its last place (FAL-412: h = 10.465, not 10.47, so
  ½ × 16 × h gives the 83.7 shown); `tools/check-answers` works out every step's
  arithmetic from the figures shown. Every cell makes both papers but the sine rule's angle, which is Paper 2 only.
  `t3-ambiguous-case` (FAL-412) is on the same situation, Paper 2 only. Its `ssa-two`
  givens fit two triangles (`second` on the situation), both inside the limits, and its
  questions ask both values of the angle or both lengths of the third side. The answer
  is the `measures` kind: two 3 s.f. measures in either order, each marked like
  `measure`, with an option that stops at one (`only`). Its diagram draws both triangles
  on one base line, lettered B₁ and B₂ (`second` in the diagram spec), with a measuring
  line under the base for each asked length. `largest-angle` uses `ssa-mix`, one triangle
  or two half and half, in words only since a drawing would show how many fit, so the
  student has to decide before answering: the acute angle is right only when the obtuse
  one has no room. The checker solves each question from the sine rule and from the
  cosine rule as a quadratic, and the two must agree.
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
- `engine/situations/binomial.gd` (FAL-695) is `t4-binomial`, the first type built from
  the course audit's list (SL4.8, on all four syllabuses): X ~ B(n, p), with n from 5 to 20
  (more for a mean) and p in steps of 0.05. Its views (`binomial_views.gd`) show it as
  X ~ B(12, 0.35) or as one of eight stories (seeds, filters, scans, cans, arrows,
  bridges, drone trips, batteries), and ask 12 unknowns: n and p from a story, P(X = k),
  at most / fewer than, at least / more than, between, E(X), Var(X), the standard
  deviation, n and p from E(X) and Var(X), the least n for P(X ≥ 1) > c, "the kth success
  is on trial m" and a conditional P(X = j | X ≥ 1). Every question is Paper 2 (every
  binomial part in the bank is): probabilities and the standard deviation are answered to
  3 s.f. with the rounding trap, E(X), Var(X), n and p exactly. Probabilities are floats,
  as a GDC computes them, and the working uses binompdf and binomcdf, nCr, the complement
  or a sum. Wrong options come from the SL4.8 misconceptions (no nCr, swapped powers, cdf
  for pdf, `1 − P(X ≤ k)` for at least k, `< k` read as `≤ k`, the wrong subtraction for
  a range, Var = np, σ = Var, E(X) rounded, n rounded down, p = Var ÷ E, a kth success
  read as k in m trials, a conditional multiplied). As every exam type, it offers no extra
  format (error-spot, method-pick, true-false-reason): `test_extension.gd` holds that rule.
- `engine/situations/binomial_expansion.gd` (FAL-728) is `t1-binomial-term` (SL1.9, on the AA
  courses): one bracket (ax^p + b)^n, or nCr alone, with every coefficient a whole number worked
  out exactly. Binomial expansion, not the distribution above. Its views
  (`binomial_expansion_views.gd`) show the bracket or nCr, or Pascal's triangle as a staggered
  grid with no row numbers (a table, as reading the row is the skill), and ask 28 unknowns: nCr by
  formula, from the triangle, by symmetry, at the edges and with n to find, nC2 as a polynomial,
  a row of the triangle, the next row and n from a row, the number of terms, full expansions
  (small n, (x + b)^n, a negative term, a number beside x, x², b/x), the first three terms, one
  coefficient in the same shapes, a coefficient in terms of a letter, the term in x^k, a coefficient
  left as a letter, and the term in a given place. The GDC's nCr is Paper 2 only; the other cells
  make both papers, with Paper 2 having the longer rows. A question that reads the triangle stays
  at row 7. An expansion is typed term by term, and a row without its ends. Wrong options come
  from the SL1.9 misconceptions and the type's own five (no r!, the negative root for n, n terms,
  the place taken as r, (1/x)^r read as falling by one power).
- `engine/situations/differentiation.gd` (FAL-723) is `t5-differentiation-rules` (SL5.6, AA only):
  one function to differentiate, with whole-number coefficients. Its views ask 18 unknowns:
  standard results and rational powers, the chain rule on a bracket, an exponential, a log, a
  trig function or a root, the product and quotient rules, each with a rewrite beside it where
  the map lists one, a derivative shown to take a given form, a gradient at a point (one unknown
  per rule, so each keeps its one route) and a derivative with the letter p left in, which is
  Paper 2 only. A derivative is a `form` answer (see `engine/answer.gd`): the student types the
  numbers into the expression and it is marked exactly; a wrong option in another shape carries
  `shape`, so it can be picked but never typed. A Paper 1 gradient is exact (a whole number, a
  fraction, or −2e³), and a Paper 2 gradient is at an x to 1 d.p., to 3 s.f.
- `engine/situations/derivative_meaning.gd` (FAL-723) is `t5-derivative-meaning` (SL5.1, on all
  four syllabuses): a quantity in one of eight stories, modelled by A + B e^(−kt) or A + B sin(wt),
  and rational functions with 0/0 at a point. Every question is Paper 2, as every bank part is.
  It asks a rate from the GDC, what a rate means, its units, a sentence in derivative notation,
  a comparison of two rates, the limit of a model or of its rate as t → ∞, and a limit from a
  table, from a graph with a gap and a dot, or by cancelling. A reading in words is a `claim`.
- `engine/situations/monotonic.gd` (FAL-723) is `t5-increasing-decreasing` (SL5.2, on all four
  syllabuses): a cubic built from whole-number turning points, a quadratic from whole-number
  roots, f′(x) = a + bx − c e^x on Paper 2, and a letter that keeps f′ on one side of the axis.
  An interval is a `form` answer with a between/outside pick and two typed ends in either order,
  so the shape isn't given away; the ends being open or closed isn't asked, except for a
  parameter, where the boundary is the point of the question.
- `engine/situations/concavity.gd` (FAL-723) is `t5-concavity` (SL5.7, AA only): second derivatives,
  f″ at a point, where a graph is concave up or down, and three matching questions played as
  pick the graph (f to f′, f′ to f″, and the signs of f′ and f″ to f). The Paper 2 value of f″ is
  at an x to 1 d.p.; f′(x) = a + bx − c e^x has b ≠ c, so ln(b/c) needs a calculator.
- `engine/situations/integration.gd` (FAL-724) is `t5-indefinite-integral` (SL5.5 and SL5.10):
  one integrand with whole-number coefficients. Its 18 unknowns ask sums of powers, the standard
  results, composites with ax + b (a is never ±1), the reverse chain rule, and integrands to
  rewrite first. An integral is a `form` answer and + C is part of it, so an option without it is
  wrong. Where two shapes are both right, (ax + b)³/(3a) or the expanded polynomial, and
  (k/2) sin² x or −(k/4) cos 2x, the method sets the shape and the other is never offered.
- `engine/situations/definite_integral.gd` (FAL-724) is `t5-definite-integral-area` (SL5.11 and
  SL5.5): 23 unknowns on exact values, areas with parts below the axis, an unknown limit or
  stretch, a region cut by a tangent or a line, and a rate in a story. A value is a `form` answer
  (`DefiniteIntegralViews.val`), so a wrong one can read differently, with + C or in rate units:
  exact on Paper 1, and 3 s.f. on Paper 2, which only the GDC methods ask. A region is shaded on
  its figure with the graph spec's `shade` (see `ui/graph_view.gd`).
- `engine/situations/motion.gd` (FAL-724) is `t5-kinematics-motion` (SL5.9): Paper 1 is
  v(t) = 3A(t − p)(t − q), with s(t) whole, and a cubic that touches 0 for a change of direction;
  Paper 2 is A t e^(−kt) − B, A sin(wt) + B or A e^(−kt) cos(wt), with rests and extremes found
  numerically. Graphs are in straight pieces with whole-number corners, on axes named t and v
  or s (`y_name`). The acceleration at maximum speed is only asked where that speed is at an end
  of the interval, as it is 0 at a turning point of v.
- `engine/situations/geometric_sequence.gd` (FAL-728) is `t1-geometric-sequence` (SL1.3, on all four
  syllabuses) and `t1-sum-to-infinity` (SL1.8), one situation for both. Paper 1 is whole numbers and
  simple fractions, marked exactly; Paper 2 is decimals that end, marked exactly when whole or within
  3 figures and otherwise to 3 s.f. Its views (`geometric_sequence_views.gd`) ask 21 and 19 unknowns:
  r, a term and uₙ (a `form` answer, where the method sets u₁r^(n − 1) or (u₁/r)r^n), r and u₁ from two
  terms, both signs for an even gap, a far term's sign, the terms between two terms, three terms in k,
  coefficients of (1 + hx)ⁿ, Sₙ by each map method, closed forms, a Σ read, evaluated and written, and
  a ball's distance to a landing; then whether S∞ exists (a `claim`), x from −1 < r < 1 (a `form`
  answer; a wrong option in another shape can be picked but not typed), S∞, u₁ or r from it, a log
  series, a quadratic in r with a root to reject, and a ball, a recurring block, nested squares, a
  shaded square, a running total against a target and the first amount for a target. GDC and
  partial-sums methods are Paper 2 only, and their working isn't shown on Paper 1. PlotView's
  `bounce` and `squares` draw the figures; a sequence's dots and the band −1 < y < 1 use GraphView.
- `engine/situations/regression.gd` (FAL-695) is `t4-regression-gdc` (SL4.4, on all four
  syllabuses): paired data, 6 to 9 whole-number points near a line (x from 1 to 20, y from 8
  to 99, 0.8 ≤ |r| ≤ 0.99, up or down as the story says), so the means, the regression line
  and every sum are exact `Q` and r is the one float. Its views (`regression_views.gd`)
  ask 6 unknowns, all Paper 2 with the GDC's LinReg: the line y = ax + b, r, the mean point,
  c in y = ax + c from a given mean point, an estimate at an x inside the data, and an
  estimate from a line given to 3 s.f. Answers are to 3 s.f. with the rounding trap (the
  line and the mean point have none), and the mean point is exact. Wrong options come from
  the SL4.4 misconceptions: the line of x on y for swapped lists, a and b rounded to 3 s.f.
  before the estimate, r² for r, c = 0 for a line forced through the origin, and the line
  rearranged for x. A table's heads are x and y with a story line above. The game's font
  has no precomposed ȳ, so the mean point is written y plus a combining macron, as x̄ is.
  As every exam type, it offers no extra format: `test_extension.gd` holds that rule.
- `engine/situations/regression_pair.gd` (FAL-725) is `t4-regression-x-on-y` (SL4.10, AA only):
  the same paired data, with both lines. Its views (`regression_pair_views.gd`) ask the line
  x = cy + d (a `named` answer: c and d), d from a mean point, which line to use (a `claim`), an
  estimate of x from data or from both lines, whether an estimate is reliable (a `claim`), the
  mean point from both lines (on the equations, or with both lines drawn) and one mean from the
  other. The table, the estimates and the judgement are Paper 2; choosing a line and the mean
  point are on both papers, with lines through a whole-number mean point and 0 < ac < 1.
- `engine/situations/normal_unknown.gd` (FAL-725) is `t4-normal-unknown-parameter` (SL4.12, AA only,
  all Paper 2): X is normal with something hidden. The student's facts stay clean (whole values,
  areas in hundredths), and the hidden parameter is whatever they force, so z and the answers are
  floats, from `SymmetrySituation.phi` and `inv_norm`. Its views (`normal_unknown_views.gd`) ask 11
  unknowns: k from an area, an event for Z (a `form` answer with the inequality picked and the
  bound typed), P(within kσ), σ or μ from a tail, σ from an interquartile range or a central
  area, μ and σ from two tails (a `named` answer), μ and σ from equal tails, and μ from two
  z-values. Representations are the equation, a story with percentages, and a shaded curve.
- `engine/situations/normal_probability.gd` (FAL-728) is `t4-normal-probability` (SL4.9, all Paper 2):
  X is normal with μ and σ known, and a region of it is asked for. It is a thin layer on
  `normal-unknown`: one normal distribution, the same stories and the same curve (its views extend
  `NormalUnknownViews`). Its views (`normal_probability_views.gd`) ask 13 unknowns: below, above,
  between and outside values, a percentage or proportion, an expected count, a rejection rule and
  its expected count, exactly k of a sample (the area as a binomial's p), a variable that can be
  negative, a variance written in place of σ, a value recorded to a rounding unit, and a middle
  from two given tails, which is exact. On a shaded curve the stem doesn't say the region again. A
  recorded value has no curve: its strip is too thin to read, and labelling it gives the half unit away.
- `engine/situations/venn.gd` (FAL-725) is `t4-venn-addition-rule` (SL4.6, on all four syllabuses):
  four regions out of a total, shown as decimals, fractions or counts in a story, a Venn diagram
  (PlotView's `venn`, rep `diagram`) or a two-way table (rep `table`, with heads and totals as
  rows). Its views (`venn_views.gd`) ask 12 unknowns: P(A ∪ B), P(A ∩ B), P(A′ ∩ B′), P(A ∩ B′),
  exactly one, a region of a diagram, x in a diagram of expressions, a table entry, and the least
  and greatest overlap. Paper 1 is exact; Paper 2 has decimals to 3 places or counts answered to
  3 s.f. An option that should be a probability is one: `build()` adds near values, because the
  engine's last-resort nudges add 1.
- `engine/situations/basic_probability.gd` (FAL-728) is `t4-probability-basic` (SL4.5): one chance
  set-up for each unknown. Its views (`basic_probability_views.gd`) ask 18 unknowns: a bag and a bag
  after a change, a two-way table (rep `table`, with totals), a list of data, a total on two dice or
  spinners in words or as a sample space table (rep `diagram`), a listed sample space, the complement
  of a given probability, table, count or two prize rules, at least one with a tree for two trials
  (PlotView's `tree`), a relative frequency from a table or bars (`bars`), a grouped table with no
  total, a long-run value from a running relative frequency (`cumfreq`, every point a real count),
  the more reliable of two tests, and a run of results. Paper 1 is exact; Paper 2 counts and
  products are answered to 3 s.f. Every option is a probability written as the answer is: a decimal
  question drops a slip that doesn't end, and `build()` adds near values.
- `engine/situations/conditional.gd` (FAL-725) is `t4-conditional-probability` (SL4.11, AA only). The
  events come from `VennSituation`; it also draws a two-stage tree (PlotView's `tree`), two draws
  without replacement, the multiplication rule, and normal, binomial and discrete conditionals.
  Its views (`conditional_views.gd`) ask 13 unknowns. A normal conditional on a curve shades the
  given and the wanted area, so the overlap shows darker. Answers are exact on Paper 1, in the
  numbers the question uses, and to 3 s.f. on Paper 2; normal and binomial ones are Paper 2 only.
- `engine/situations/sampling.gd` (FAL-726) is `t4-sampling` (SL4.1, on all four syllabuses): a
  population in named groups and a surveyor's method, on both papers, Paper 2 with larger numbers.
  Each group is the interval times its share of the sample, so numbers in proportion are whole.
  Its views (`sampling_views.gd`) ask 17 unknowns: the technique, a disadvantage (a wrong one is
  false of that technique), a systematic sample, its interval and a later pick, the best technique,
  whether a sample is simple random, a group's number in proportion, a shortfall, the most
  under-represented group, and why a sample is biased, which way it leans, what fixes it, what a
  larger sample can't do, why a random sample can miss the mix, how to improve reliability and why
  a source may not be reliable. A reading in words is a `claim`. Representations are a story and a
  table of the groups. The separate `t4-ext-stratified-numbers` still owns rounding to strata.
- `engine/situations/cumulative_frequency.gd` (FAL-726) is `t4-cumulative-frequency` (SL4.2, on all
  four syllabuses), Paper 1 only, as every bank part is. A curve is on a grid of 20 squares by 20
  (PlotView's `cumfreq`): a square up is n ÷ 20, so every 5% of n is a grid line, and a square
  across is set by the story. The curve goes through knots at grid corners, and every value a
  question reads, right or wrong, is a knot, so a reading has one value. Knots are joined by a
  cubic on each stretch whose gradients can't overshoot. Its views (`cumulative_frequency_views.gd`)
  ask 30 unknowns: the median, quartiles, IQR, percentiles and range from the curve or by
  interpolating a table; how many or what percentage lie below, above or between values, a cut-off
  for the top or a top percentage, a share of a limit, and a sample scaled to its whole group; a
  table's running totals and frequencies, p and q from the curve, the point plotted for a class,
  where the curve starts, and pick the curve (GraphView cards, with the points at midpoints or lower
  boundaries, or the frequencies in place of the totals). A table's classes are equal, its estimates
  end in at most one decimal, and its counts are whole.
- `engine/situations/arc_sector.gd` (FAL-726) is `t3-arc-sector` (SL3.4, AA only): one sector, with
  θ in radians, degrees or as a multiple of π. Paper 1 is exact: every value is a + bπ, kept as
  [a, b] and answered as a `form` whose slots follow its shape (`5π/6`, `12 + 3π`, `9π − 4.5`), and
  a wrong option in another shape can be picked but not typed. Paper 2 is to 3 s.f., and a worked-back
  r or θ comes from a given arc, area or perimeter to 1 d.p. Its views (`arc_sector_views.gd`) ask
  22 unknowns: conversions, arcs, perimeters, areas, r and θ back from each, major arcs and sectors,
  r in terms of θ, a bent strip, and a sector rolled into a cone. As the bank asks them, the curved
  strip between two circles and the plate with two segments cut away are Paper 2 only; the plate
  brings in `SL3.4.segment-shaded`, with θ found on the GDC. PlotView's `sector` draws the real
  angle, and `plate` the cut plate.
- `engine/situations/bearings_elevation.gd` (FAL-726) is `t3-bearings-elevation` (SL3.3, on all four
  syllabuses). Every question is Paper 2. Its views (`bearings_elevation_views.gd`) ask 19 unknowns:
  back bearings, angles from a bearing, two-leg journeys by the cosine rule or by components, due
  east and due west triangles, elevation and depression with an eye height, a chain or a speed, a
  route's time, connected triangles, and which rule to use (a `claim`). PlotView's `sketch` draws
  the real coordinates, with a north line at each bearing and each label clear of the others; the
  small angles of `time-from-depression` are marked not to scale. A bearing that is worked out stays
  at 100° or more, so its 3 s.f. are three figures.
- `engine/situations/trig_kit.gd` (FAL-727) holds what the exact trig types share: a value is
  [a, b, r], which is a + b√r, with the landmark table, the writing ("(1 + √3)/2", root on top)
  and the `form` answer whose slots follow the value's shape. `ui/plot_view.gd` adds `unit-circle`
  (points, an angle, a shaded quadrant, a dashed line y = k or x = k) and `straight-angle`, and a
  GraphView spec's `x_ticks` marks the across axis in multiples of π.
- `engine/situations/exact_trig.gd` (FAL-727) is `t3-exact-values` (SL3.5, AA only, all Paper 1): 11
  unknowns on landmark values, a number in front, sums, related angles past the first quadrant,
  negative or on the second turn, a ratio of π − θ, π + θ or −θ from a given ratio, and the unit
  circle (P's coordinates, sin, cos and tan from a point, signs by quadrant, why tan has no value).
  Representations are the written value, a special triangle or the unit circle, a wave, and a
  table of landmark values with one cell to fill. A reading in words is a `claim`.
- `engine/situations/trig_identity.gd` (FAL-727) is `t3-identity-values` (SL3.6, AA only, all Paper 1):
  13 unknowns on one ratio and a quadrant (the other ratio, tan, sin 2θ, cos 2θ, each with the map's
  methods), cos θ from cos 2θ, written or from a triangle's cosine rule, and expressions to rewrite
  (in sin x or cos x alone, as a cos bx, as a sin bx, a + b sin cx, and a maximum after rewriting).
- `engine/situations/algebraic_proof.gd` (FAL-728) is `t1-algebraic-proof` (SL1.6, AA only): 14
  unknowns on one statement to prove, an identity (a difference of squares, (x − a)² + b, a fraction
  to combine or split, a reciprocal difference, a Pythagorean triple in x) or a claim about integers
  (a multiple of m, a sum of consecutive terms, n² + an + b always even, a sum of squares never
  divisible). A phone can't read a written proof, so each unknown is one decision a proof turns on,
  typed in slots (a `form`) or picked (a `claim`): the simplified form, what both sides reach, a
  hidden line, the next line, the first wrong line and its correction, k in E = mk, the integer
  bracket, the greatest divisor, a remainder, the opening with two letters, or which of four
  arguments is a proof. `AlgebraicProofViews.chain()` writes every proof as lines from the numbers,
  and a slip is that chain with one wrong move carried on, so wrong options are what the slip gives.
  Identities are Paper 1 or 2 and integer proofs Paper 1, as in the bank.
- `engine/situations/trig_model.gd` (FAL-727) is `t3-trig-model-parameters` (SL3.7, AA only): 15
  unknowns on one wave from its turning points. Paper 1 has x in multiples of π and whole a, b and d;
  Paper 2 is a story in t, or a decimal phase, to 3 s.f., six parts in seven as in the bank. It also
  asks p sin kx + q cos kx as one cosine, a tan graph's a and b, the shift with b taken out, an
  image's equation, the transformations (a `claim`), p and q of f(x − p) + q, a wheel starting at
  the bottom, c from a rising crossing, and a level from the time above it.
- `engine/situations/trig_equation.gd` (FAL-727) is `t3-trig-equation` (SL3.8, AA only): 16 unknowns
  on one equation on an interval. Every solution comes from `solve()`, on the landmarks; each is a
  slot of a `form` answer in any order, and a wrong option with another count can be picked but not
  typed. Paper 2 is the two decimal unknowns only, as the GDC method needs one (4 cells in 100),
  so the type stays on the bank's Paper 1. Factorising, dividing to tan and rejecting a factor
  each have their own unknowns, with the lost solutions as their wrong options.
- `engine/situations/solid.gd` (FAL-726) is `t3-solid-volume-area` (SL3.1, on all four syllabuses):
  one solid, as a labelled sketch (PlotView's `solid`, rep `diagram`) or in words: a cone, pyramid,
  sphere, hemisphere, a composite of them, a hollow cylinder, a cylinder inside a sphere, or the flat
  sector that rolls into a cone. Its views (`solid_views.gd`) ask 32 unknowns: volumes and surface
  areas, a height from a slant height, slant height or slant edge, l and V from a total surface, r
  and h from a volume, the cost of painting a tank, r from a composite's volume with the GDC's
  solver (Paper 2 only), expressions in x or in r and h, and the sector's radius, angle and area.
  Paper 1 measures are whole, from Pythagorean triples where a slant comes in, and a multiple of π
  is a `form` answer with the multiple typed. Paper 2 measures have one decimal place and answers
  are to 3 s.f. Expressions are Paper 1 only, except S from a cylinder's volume.
- `engine/situations/standard_form.gd` (FAL-726) is `t1-standard-form` (SL1.1, on all four
  syllabuses): numbers a × 10^k with a an exact `Q` and k an int, so nothing has to fit a float. Its
  views (`standard_form_views.gd`) ask 19 unknowns: converting both ways, bringing a back between 1
  and 10, the largest or smallest of four mixed forms, a GDC display, p × q, p/q and p²q, and
  stories: how many times larger, a time, a total, a change of unit, a multiple of an amount and a
  volume π(a × 10^k). An answer a × 10^k is a `form` answer with a and k typed, so 64 × 10⁵ can be
  typed and is marked wrong, and a negative k is typed like any negative number. `form` has no
  rounding trap of its own, so the views set one, with a to 2 s.f. E-notation is an option that can
  be picked but never typed. The font draws every superscript digit and ⁻; `Fmt.sup` leaves a power
  of 1 out, so `StandardFormViews.ten` writes 10¹ and 10⁰ itself. The GDC methods are Paper 2 and
  the by-hand multiplying and dividing is Paper 1.
- `engine/situations/data_summary.gd` (FAL-695) is `t4-summary-statistics` (SL4.3, on all four
  syllabuses): one discrete data set, shown as a list in no particular order (rep `terms`)
  or as a frequency table, all exact (`Q`). Its views (`data_summary_views.gd`) ask 11
  unknowns: the mean, median, mode, range, quartiles (the median of each half, the median
  itself left out when n is odd) and interquartile range of the data; a missing value in a
  list or a missing frequency p in a table from a given mean; a combined mean of two
  groups; and, for eight measurements with one outlier, the best measure of the centre or
  the measure of spread it leaves alone (a `choice` answer). A cell says which papers it can
  make (`papers()`): the GDC working (`gdc-1var`) is Paper 2 only, the totals, combined
  mean and outlier questions are Paper 1 only, the rest make both. Paper 1 has small whole
  numbers and a mean ending in at most one decimal place; on Paper 2 a mean needs rounding
  and is answered to 3 s.f. with the rounding trap, and everything else stays exact. Wrong
  options come from the SL4.3 misconceptions (the middle of the unordered list, the position
  for the median, the count for the mode, Q₁ + Q₃ for the IQR, the quartiles of the
  unordered list, the mean of the two means, p left out of Σf, the mean or the mode as the
  best average) and never read as a fraction (`DataSummaryViews.tidy`). As every exam type, it
  offers no extra format: `test_extension.gd` holds that rule.
- `engine/situations/compound_interest.gd` (FAL-695) is `t1-compound-interest` (SL1.4, on all
  four syllabuses): money invested at a nominal annual rate r %, compounded 1, 2, 4 or 12
  times a year, for n years. Its views (`compound_interest_views.gd`) ask 6 unknowns, all
  Paper 2 with the formula or the GDC's TVM solver: the value after n years, the interest
  earned, the amount to invest now, the annual rate, the least whole number of years to pass a
  target, and how much more one account is worth than another (as a sentence or as a table).
  Values are floats, as a GDC computes them. Money is answered exactly to the cent, so every
  value, and every wrong option offered, leaves a fraction of a cent at least 0.15 from the
  rounding edge at 0.5 (`CompoundInterestSituation.cents_clear`). A rate is a quarter of a
  per cent and is answered to 3 s.f. with the rounding trap, found from the FV as shown (a hair
  off the quarter, so the trap's side is fixed); a time is the first whole number of years that
  passes the target. Wrong options come from the SL1.4 misconceptions: the annual rate over kn
  periods, simple interest, the total for the interest (and back), the root with no 1 taken
  off, the total growth shared over n years, the time rounded to nearest, the periods given as
  years, and two accounts compared on their nominal rates. As every exam type, it offers no
  extra format: `test_extension.gd` holds that rule.
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
  and uses the formula.
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
  catalogue's pick-the-graph unknowns on those situations play as four descriptions
  (from the equation) or four equations (from the graph).
- **The Graphs and key features region** (FAL-420) adds five exam situations, all but
  one Paper 2, whose numbers only a GDC finds. `engine/situations/gdc_kit.gd` is what
  they share: every zero of a function on an interval (a sign change on a sample grid,
  closed in by Brent's method, `engine/brent.gd`), turning points as the zeros of the
  derivative, the region's way of writing a function, and the pick-the-graph cards.
  Values are kept as Q to nine decimal places, shown to 6 s.f. in the working (as a GDC
  shows them) and asked to 3 s.f. `gdc_curve.gd` is one awkward curve on a closed
  domain (an exponential plus a line, a cubic, a bell curve, sine or cosine plus a line,
  a factorised product, an x-factor cubic, a log with its asymptote at one end, a bell
  form), for `fn-sketch-gdc` and `fn-gdc-features`. `gdc_two_curves.gd` is two curves
  that cross one to three times (a curve and a line, two models of time, f and f⁻¹, or
  one crossing past x = 10), for `fn-gdc-intersection`. `gdc_combined.gd` extends it
  with a function made from them (how far one town or drug is ahead, the distance from
  a point to a curve, the sum), for `fn-gdc-optimise-combined`. `gdc_context_equation.gd`
  is an equation that mixes families from a context (x = k sin x, a circle's segment, an
  exponential against a line, a first time, savings, two curves in two unknowns), for
  `fn-gdc-solve-equation`. `graph_from_features.gd` is Paper 1: exact features (a
  parabola, a model on an interval, a curve that levels off, sin or cos on 0 to 2π, a
  curve from conditions) and the sketch that shows them, for `fn-sketch-from-features`.
  Each recipe draws its family once and looks at 48 samples before it finds roots, so a
  question takes about 7 ms, about ten times the rest of the sweep; CI runs the sweep in
  four shards (`tools/stress-questions --shard=k/4`). New answer kinds: `xs` (a
  list of x-values, any order; options may have other counts), `pts` (a list of points,
  any order; a wrong option may give only the x-coordinates) and `graph` (pick the
  graph). A view's rounding trap can carry a misconception (`trap_ref`) where the
  catalogue's mistake is too few figures: picking it is a glancing hit that logs it.
  `Answer._sorted` and `_pairs` compare as floats, because Q.lt's cross-multiplying
  overflows on nine-decimal values. The crossing scan of `gdc-two-curves` also looks at
  every sample that sits lower than both neighbours on one side of the line (`_dips`):
  a curve that only just dips through it (two crossings 0.04 apart, 0.001 deep) has no sign
  change between samples, and the situation is turned down for the shallow angle, as the
  answer checker's finer grid would find them (FAL-695). The checker keeps a crossing exact
  when x is a rational root and y is rational (`gc_exact_point`), as the game does.
  The region's extension types: `fn-concept-solutions-as-intersections` is more views
  on `gdc-two-curves`; `gdc_inequality.gd` extends it with f(x) > g(x) or < g(x), solved
  from the crossings (`fn-ext-inequality-graphical`); `graph_reading.gd` is reading a
  grid and rounding (`fn-pre-graph-reading`); `graph_match.gd` matches y = a·bˣ + c or a
  factorised quadratic to its graph (`fn-ext-match-graph`; the match format isn't
  built, so matching several plays as picking one); `link_extremes.gd` is an extreme
  found several ways (a height model's top, a wave's range and first peak, a touching
  line, a closed interval, a cubic's turning points: `fn-link-extremes`); and
  `link_graph_algebra.gd` is an equation as two graphs that meet (`fn-link-graph-vs-algebra`).
  The two link types extend `extension_views.gd` and offer true-false-reason and
  method-pick; the concept type and graph-match offer true-false-reason. Not built yet:
  error-spot (fn-ext-inequality-graphical, fn-pre-graph-reading) and method-pick for
  fn-concept-solutions-as-intersections.
- **The Composite and inverse region** (FAL-422) adds three exam situations. `composite_pair.gd`
  is two rules chained, f and g, as `{"t", "co"}` polynomials (a line, x² + c, (x − h)², x³ + c,
  or sin x on Paper 2, with a generic quadratic for an outer rule to find), with modes for
  the forward composites and a value, a constant k from a value or from a stated coefficient,
  an equation (f∘g)(x) = t, f∘f, f∘g against g∘f, a chain of steps in words, a rule split in
  two, and the two reversed composites (find g given f and f∘g, find f given g and f∘g). Its
  views (`composite_pair_views.gd`) say each rule as f(x) = … or in steps ("double, then
  subtract 3"); an expression is the `poly` kind, k a `kvals` pair or a number, the solutions
  an `xs` list and the order-of-composition and decompose questions a pick of four sentences.
  The one Paper 2 value is (f∘g)(x₀) with f = sin x in radians, to 3 s.f. with the rounding
  trap, and a k from (a·x₀ + k)² = r with r not a square, to 3 s.f. `inverse_rule.gd` is a rule
  from a family with its domain: a line, (ax + b)/(cx + d) with whole-number asymptotes,
  √(px + q) + r, a quadratic on one side of its vertex, or b^x + q. Students can't type a
  function of x, so its views (`inverse_rule_views.gd`) offer an inverse, a domain, an
  asymptote pair or a reflection claim as four written options (the `choice` kind), and a
  constant, a value or a k as a number. The checker reads each option back with SymPy and
  tests it as maths, so the right one is the inverse and every wrong one is shown not to be.
  `graph_table.gd` is f (and g) at six consecutive whole numbers, drawn as dots joined by
  lines (so a one-to-one f is always rising or falling) or written as a table or a sentence
  of values, with a rule mode for the views that print the rule beside the graph. Its views
  (`graph_table_views.gd`) read a value, a composite, an inverse value, a domain or range,
  the matching points of f⁻¹ (the `pts` kind), every solution of f(x) = k on a graph that
  turns back, and why it has no inverse. The checker rebuilds f and g from the table, the
  graph's dots or the sentence, never from the engine's givens. Paper: the algebra of
  `fn-inverse-algebraic` is exact on both papers, so its Paper 2 questions (four in five, as
  the exam has them) have the same exact numbers and the calculator on offer; the graph and
  table readings are all Paper 1. A mini-boss on `fn-composite` asks the composite and then
  its value (`Tuning.CHAINS`); the other unknowns each need their own numbers, so they are
  single questions.
- **The Rational functions region** (FAL-423): `rational_function.gd` is one
  linear-over-linear function f(x) = (ax + b)/(cx + d) = A + B/(x − h), built from its asymptotes
  and stretch so its intercepts are never none (a, d ≠ 0) and ad − bc ≠ 0. Paper 1 keeps
  c = 1, 2 or 3 and intercepts that are whole numbers, halves or thirds; a graph or card needs c = 1
  with the asymptotes and both intercepts whole and inside the plot. Paper 2 (`papers()`) gives
  a, b, c, d that need a calculator, so the asymptotes and intercepts of `fn-rational-asymptotes-
  intercepts` are decimals that don't end, asked to 3 s.f. with the rounding trap, and `fn-rational-
  sketch`'s reciprocal of f is Paper 2 (as in the bank) with asymptotes between the grid lines. Its
  extras, asked by a view's need, are a line y = mx + n that meets f 0, 1 (a tangent) or 2 times, a
  parabola that meets it 1 to 3 times (a count by the cubic's discriminant, found again numerically;
  a restricted domain `x > 0` changes the count), a horizontal line y = k, k = A or not, a relation
  and a k (0, or a value whose boundary is whole) for an inequality, and the 1, 2 or 3 of y = k/x.
  `rational_cards.gd` draws every graph: a curve is a triple (A, B, h), drawn as two branches that
  run to the edge of the plot and stop, so **no line is drawn across x = h** (a card with such a
  line is the wrong one, `through`). The views (`rational_function_views.gd`) are 24 unknowns:
  asymptotes and intercepts are typed (`axis`, `xint`, `yint`, `named`, `number`), the rest are
  a pick of four written options (`choice`), a pick of four graphs (Q13) or a count. Each wrong
  graph changes one thing of the right one (`flipped`: B's sign, `zero-at-h`: the asymptote and the
  zero swapped, `through`, `mirrored`: x = −h, `swapped`: the asymptotes swapped), tagged with its
  misconception. `axis` answers honour `show` and a wrong option may be the number alone (var ""), the
  asymptote written as a number. The checker reads each card back as a triple from its dashed lines
  and its curve and tests it against the change it names, and finds every asymptote, intercept,
  solution set and count again with SymPy. `ui/graph_view.gd` draws a rational function's branches in
  one colour (`one_colour`) and a second curve (the line or the parabola) in the other
  (`sand_from`). The exam types offer no extra format.
  **The Rational functions extension types** (FAL-423): `fn-ext-transformed-reciprocal` is seven more
  unknowns on the same `rational-function` situation (mode `split`: f = A + k/(cx + d) with A and k
  whole and c = 2 or 3, for the scaled split), asked as `named` constants (A and B, A and k, or A, B and
  h read off a graph with one marked point), a pick of four translations ("3 right and 2 up"), of a
  stretch and a translation in order, or of single fractions. `algebraic_fraction.gd`
  (`fn-pre-algebraic-fractions`, the level-0 prior learning, so the dungeon's warm-ups can play it) is
  built from its answer: an excluded value, a fraction simplified by cancelling a factor (or one that
  can't be, where cancelling terms is the slip), a sum of two fractions, an equation a + k/(x − h) = c
  whose solution is whole and never excluded, and a missing numerator. The answers are written options
  (`choice`) checked as functions by SymPy, and an equation's solution is a typed number. Its
  misconceptions have no ref, so they are logged as `fn-pre-algebraic-fractions#<index>`.
  `asymptote_gallery.gd` (`fn-concept-asymptote-meaning`) is curves with asymptotes side by side: a
  linear-over-linear one, a curve that meets its horizontal asymptote (x/(x² + 1), x·e^(−x), A + x/(x²
  + 1)) or does not, (ax + b)/(cx + d) with ad = bc (a gap, not an asymptote) and a level that settles.
  What an asymptote means is an explanation, so each answer is one of four statements, and the
  type's true-false-reason format plays them as a student's claim. `rational_model.gd`
  (`fn-ext-rational-model`) is a model (αx + β)/(x + γ) in a context: an average cost
  (F + vn)/n, a mixture topped up (s + px)/(V + x) or a level that settles (Lt + P₀k)/(t + k), with an input
  where the value ends, a table, a whole input and its value, a target whose input is not whole (so the
  least whole number rounds up: rounding down and giving the output are the slips) and one data point
  for a constant. Every answer is exact (Paper 1): the catalogue's Paper 2 versions, to 3 s.f., and
  its `multipart` format are not built. Built formats of the extension types: error-spot on
  `split-to-form` and on `clear-and-solve` (the catalogue's one error-spot slip of each),
  true-false-reason on every unknown of the gallery and the model. Not built: method-pick, order-steps
  and match (see the formats above).
- **The Function basics region** (FAL-424): `basic_function.gd` is one rule (a polynomial, a root,
  an exponential, a rational or a model such as a falling ball, a cost, a population or a cooling
  drink) and its inputs and outputs. `fn-evaluate-function` and `fn-concept-function-notation` are
  on it, and two situations extend its rules: `basic_restricted.gd` (`fn-domain-range`: a rule with
  a stated domain, a reflection, a second function or an inverse, so the range has to be worked out)
  and `basic_one_to_one.gd` (`fn-inverse-reflection`: a one-to-one curve with key points on grid
  points, so the inverse comes from swapping coordinates). `basic_relation.gd` (`fn-ext-is-function`)
  is a relation that may or may not be a function, as a graph, a mapping or an equation, and
  `substitute.gd` is the level-0 `fn-pre-substitute`. The graph's `filled` and `open` points mark
  whether a domain's end is included. Paper 2 rules need a calculator; the extension types are Paper 1.
  Boss chains: `fn-evaluate-function`, `fn-domain-range` and `fn-inverse-reflection`.
- **The Lines region** (FAL-424): `line_conditions.gd` is a segment and a line built from it: the
  two points come first, then the gradient, the midpoint and a new line through a chosen point, so
  any of them can be hidden. `fn-line-from-conditions` and `fn-concept-gradient-meaning` are on it. The
  answer kind `gline` is ax + by + d = 0, right at any whole-number multiple with a > 0, and a `line`
  answer's text is y = mx + c. `line_crossing.gd` (`fn-ext-intersection-lines`) picks the meeting point
  first; a Paper 2 pair has one that needs the GDC, to 3 s.f. `line_model.gd` (`fn-ext-line-model`) is a
  fixed amount plus a steady rate. `linear_equation.gd` and `simultaneous.gd` are level-0, with the
  solution picked first. `link_rate.gd` (`fn-link-rate-of-change`) is one rate in four forms: a
  sequence's d, a line's m, a regression gradient and a derivative. Its `match-rate-kind` is a match in
  the catalogue, so it plays as one pick of the whole matching, A to D, until that format is built.
- **The Transformations region** (FAL-424): `transform_chain.gd` is a base graph and up to three
  moves, with the moves picked first and everything derived from them, so f, g, the moves or a point
  can each be hidden: f and the moves give g, f and g give the moves, g and the moves give f.
  `fn-transform-describe`, `fn-transform-apply` and `fn-concept-transform-order` share it, each with its
  own views file, and the sketch unknowns are a pick of four graphs (Q13). `link_transformations.gd`
  is one vector and factor in a parent graph, a data set, a normal curve or an area, and
  `link_vectors.gd` is one vector as a translation, a vertex, a wave's shift, a line's direction, a
  step in 3D or a time delay. The checker works every chain again from the base and the moves, reads
  each option back into a curve or a chain, and calls it right only if it is the same curve as the
  truth. A graph in straight pieces has no rule, so there the letter f stands for a cubic with no
  symmetry. Not built in these three regions: `match` and `order-steps` (the format isn't built
  yet), and error-spot on `fn-ext-intersection-lines`, `fn-concept-transform-order`, `fn-link-vectors`
  and the exam types.
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
  about a third of the time (`EXTRA_SHARE`). Exam types offer none. **pick-the-graph**
  (Q13, FAL-420; the catalogue calls it `graph-pick`) is built: students can't draw, so
  a sketch question shows four graphs, `q.graphs`, and asks which is right. A view
  whose answer is the `graph` kind plays it whatever format was asked
  (`GdcKit.pick()` shuffles and letters the cards). Each wrong card changes one thing,
  a typical mistake: its option's `ref` is the misconception (logged like any other),
  `mistake` names the change (the checker tests that change alone) and `why` says what
  is wrong, which the feedback shows as `reason`. The practice and fight screens draw
  the four cards in a 2 × 2 grid, each above its letter button, in GraphView's card
  mode (thinner lines, smaller dots, fewer numbers), so they read on a 360 px phone.
  `match`, `multipart` and `order-steps` are not built.
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
  exam frequency. It plans only from the cells the save's course covers (see "Courses").
- **Courses** (`engine/courses.gd`, FAL-397): the save's `course` is `aa-sl`, `aa-hl`,
  `ai-sl` or `ai-hl` (`SaveData.set_course()`, `Courses.of(save)`), and a course is a
  filter over the shared skills, not a separate game. `data/courses.json` lists the
  subtopics each course covers (written by `node tools/courses.mjs --write` from the
  `courses` on every subtopic), and a skill is in the subtopic of the first two parts of
  its id (`SL2.6.vertex` is in `SL2.6`). A cell is **covered** when every skill of its
  unknown is in the course and the method (angle) it asks by teaches a skill that is too
  (`QuestionEngine.covered()`); an unknown with no skills (prior-learning algebra) is
  covered by every course. `QuestionEngine.cells()`, `built_types()`, `probes()` and
  `angles_for()` take a course (`""` for none), and so do `Dungeon`'s floors, warm-ups,
  prior-learning steps, boss chains and link parts, `Planner`, `Progress` and the map's
  locked regions. A `Run` reads the course when it starts. AA SL and AA HL cover every
  question built so far, so for them nothing changes. AI SL and AI HL get fewer cells,
  about three in ten of the built ones at the time of writing: a cell needs every skill it
  tests in the course, and the AI guide shares only some of AA's subtopics (`SL2.6`
  quadratics and `SL2.9` exponentials and logs are AA's alone). The rest needs AI content
  built. Changing course keeps every cell record, so progress on shared skills is not lost.
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
  Version 5 (FAL-397): `course`, `aa-sl` for every save made before it.

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
  (above) into these calls: the run's region goes to its island's journey region
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

### Powers and answer boxes on the card

Questions are written with a caret (`e^(4x − 3)`, `a × 10^k`), as `tools/check_answers.py`
parses them back and Unicode has no superscript `.` or `/`. `UiTheme.math()` (FAL-743) cuts the
powers out with `Fmt.power_runs()` and draws them raised, in a `RichTextLabel` with a
`FontVariation` over the default font. Text with no power stays a plain `Label`. It is used for the
prompt, the question's lines, the worked solution and the explorer's versions. Options, the
text around an answer box and graph labels still show the caret: a `Button`, a `LineEdit`'s row
and `draw_string` can't take rich text.

An answer box starts 150 wide and grows as it's typed in, up to `Practice.SLOT_CHARS`, which still
fits the fight's card on a 360 px phone. It isn't sized from the answer, as that would give away
how long the answer is.

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
the value carried on. `&select=1` shows the floor select.

The map takes a hash: `/#functions/quadratics` opens that region's screen,
`/#functions` the island and `/#world` the world map (see "The map").

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
is live when the engine covers a built class for it (`Courses`, see "Courses"), whatever
the syllabus map's status: AA HL plays every class AA SL does, AI SL and AI HL the ones
whose skills they share, and a built class they don't cover is greyed out as "not in AI
SL". A course the engine doesn't list shows the syllabus note and asks nothing. Phones
show the choices and the question one at a time; landscape shows them side by side.

The URL follows the screen, so a state can be bookmarked:
`/?explore&view=<type>/<unknown>/<rep>/<angle>/<value|mcq>&seed=3`, plus
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
For the FAL-420 situations it reads the function (or both curves, the models, the
equation) back from the question's text with SymPy, scans a fine float grid for sign
changes and refines every zero, turning point and crossing to 30 digits with mpmath,
then compares each answer and option as the game writes it, to 3 s.f. (`GC_*`, `TC_*`,
`CB_*`, `CE_*`, `GF_*`). Each tagged misconception's value is worked out again, and
each card of a pick-the-graph question is tested: the right card is the function on
its domain with every feature marked, and each wrong card is exactly its named mistake
(−f, f past the domain, f with a turning point moved onto the axis, a V at the vertex,
and so on).
For the four FAL-723 situations it reads the function, model or graph back from the question
(`calc_expr`), differentiates with SymPy and compares every option with that at three points
at 30 digits; each tagged wrong option is worked out again from its misconception, a `form`
answer's slots must make the expression it shows, and a pick-the-graph card must be its named
mistake (`dr_*`, `dm_*`, `mo_*`, `co_*`).
For the three FAL-724 situations it reads the integrand, region, rate or motion back from the
question. An indefinite integral is checked by differentiating every option, and + C counts; a
definite integral or area is worked out again with SymPy, or mpmath for a model, split at the
roots it finds itself, and each shaded strip must be the region asked for; rests and extremes are
found again from v(t), exactly on Paper 1 (`check_integration`, `check_definite_integral`,
`check_motion`).
For the four FAL-725 situations it reads the facts back from the question: lines, percentages,
sentences, a Venn diagram, a tree or a table. It finds the regions, ratios and lines again with
exact rationals, and z and tail areas with mpmath at 40 digits. A σ or μ is checked by putting it
back into erf, and a shaded area must be the area given (`check_regression_pair`,
`check_normal_unknown`, `check_venn`, `check_conditional`).
For `basic-probability` it reads the story, table, bar chart, tree or curve back, counts the outcomes
again by listing every one, and checks that a curve is real counts settling on its answer
(`check_basic_probability`).
For `sampling` it runs the checklist on the surveyor's sentence (a fixed interval, groups filled,
a random draw) to find the technique, and holds each wrong disadvantage to being false of it. For
`cumulative-frequency` it reads every value off the curve in the figure, which must rise strictly
and meet the reading on a corner of the grid the scale line describes; a table's estimates come from
its written rows, and a pick-the-graph card must hold the points its mistake says
(`check_sampling`, `check_cumulative_frequency`).
For the two FAL-726 situations it reads r, θ, the arc, the area, bearings and lengths back from
the lines or the figure, and works each answer out from those, exactly with a + bπ on Paper 1, or
at 40 digits. A sector must be drawn to the question's angle, and each length and bearing on a
sketch must match the points drawn, to one scale. The working's arithmetic is checked from the
figures shown (`check_arc_sector`, `check_bearings`).
For the two FAL-726 situations it reads the measures back from a sketch's labels or the sentences,
and the numbers back from the text, and finds each answer again with exact rationals and π, a
composite's r from the roots of its cubic at 40 digits. Each number a × 10^k is normalised again
without leaving exact numbers. Every step of the working that is plain numbers is evaluated, and
its sides must agree to the figures shown (`check_solid`, `check_standard_form`).
Each cell also gets 10 questions made on its family's shared situation, and 20 in each
extra format it offers (`--per-format`). Every mini-boss and boss chain is exported too
(`--per-chain`, 50 seeds), each part as a question checked like the rest, and then as a
chain: one situation, and each part's `carried` value is the part before's answer. It
prints a table per type and per cell. SymPy is pinned in
`requirements.txt` and installed into a gitignored `.venv/` on first run. CI runs it in
six `answers-shard` jobs (`--shard=k/6`: every sixth cell and boss chain, each with all
its questions). Each leaves a `summary.json`, and the `answers` job merges them
(`tools/check-answers --merge dir`) and fails unless every shard is there once, passed,
and together they give every cell 50 questions and every type 1,000.

### The seed sweep

`tools/feedback-check` takes every wrong option with a misconception tag and fails if
its "Watch out" text shows a number the question doesn't, states the false belief as if it
were true (each string opens by naming the slip: "Assuming ...", "Using ..."), or has no
text. It also fails on an absurdly large option. So strings carry no numbers of their own:
one string serves every question with that tag. Whether a tag fits its option has to be
read: `--rows=file.tsv` writes one row per type, unknown, representation and tag. A new type
is enforced from its first commit; the older types in `REPORT_ONLY` are only counted.

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

### The course audit

`tools/course-audit` shows where the engine stands for each IB course, so the order of
the rollout comes from numbers (FAL-695). `tools/course_report.gd` exports what the
engine can ask each course (`Courses`), and `tools/course-audit.mjs` joins that with the
curriculum maps and `curriculum/question-types.json`. It prints, and keeps in
`_scratch/course-audit/report.md` (nothing tracked, since the numbers move with every
type that lands):

- per course and topic: the skills the course has, the skills a type in the catalogue
  lists (**catalogued**) and the skills a built question tests (**playable**);
- the subtopics no type lists at all, which is every AA HL-only and AI-only subtopic so
  far: their types have to be designed before a generator can be built;
- the catalogued types not built yet, ranked by the skills they would make playable in
  each course.

`tests/unit/course-audit.test.mjs` runs the second half on a faked report.

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
  that region. Above them is the **course picker** (FAL-397): one button per IB course
  (AA SL, AA HL, AI SL, AI HL), the save's pressed. Picking one stores it
  (`SaveData.set_course`, `Map.set_course`) and draws the screen again, so every number
  on it, the locked regions on the island and the next run follow the course (see
  "Courses"); the cell records stay. It sits on the region screen for now, a scrolling
  column that has room, until character setup gives it a place beside the class pick.

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
- `test_integration.gd`, `test_definite_integral.gd`, `test_motion.gd`: the three FAL-724 types:
  built with every cell and every skill, no extra format, four different options, GDC methods on
  Paper 2 only, + C on every integral, the method setting the shape, a shaded region on every
  figure, exact integrals and derivatives against hand values, and named axes.
- `test_binomial_expansion.gd`: t1-binomial-term built with every cell and all three skills, no
  extra format, four different options, the GDC on Paper 2 only, hand values, the bracket as the
  exam writes it, the staggered triangle, a term against a coefficient, a typed expansion and row,
  every misconception as an option, the three concept probes and AA courses only.
- `test_algebraic_proof.gd`: t1-algebraic-proof built with every cell, both SL1.6 skills and
  14 unknowns; every cell in both formats, with the answer ending the working; the bank's paper
  split; each statement against values worked out by hand; a hidden line and a spoiled line
  where the chain says; the fix typed on the wrong line marked wrong; a typed slip detected;
  the factors in either order; every misconception as an option; no statement with the exam's numbers.
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
- `test_solid.gd`, `test_standard_form.gd`: the two FAL-726 types: each built with every cell and
  all its skills, one right option on each paper it can make, sketches that label only what is
  given, a right triangle in every cone and a sector that rolls into its cone, a × 10^k typed with
  a negative k, the right value with a outside 1 to 10 marked wrong, E-notation never typed, the
  superscripts' glyphs, and every misconception as an option.
- `test_basic_probability.gd`: `t4-probability-basic`: every cell and skill, one right option on each
  paper, every option a probability, hand values, the figures drawn, a curve of real counts, a
  complement that differs from its event, and every misconception as an option.
- `test_regression_pair.gd`, `test_normal_unknown.gd`, `test_venn.gd`, `test_conditional.gd`: the four
  FAL-725 types: each built with every cell and all its skills, one right option on each paper,
  the numbers against hand values, the figures drawn, every misconception as an option, and the
  courses each is in.
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
  (AA SL and AA HL every built cell, AI SL inside AI HL); the save's `course`, its
  version 5 migration and `set_course()` keeping the cell records; and that the planner,
  a run's floors, warm-ups, prior learning, mini-bosses, bosses and links, and the map's
  counts only use cells the course covers.
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
  than 3 answers; the world map, the island and the region screen; the course picker
  storing the course and keeping the records; "Coming soon" for a
  region with nothing built, which can't start a run; a run started from the map; the
  island's loop in a run and the boss loop in a boss; Play opening the map; and every
  screen fitting 390x844 and 1280x800.
- `test_explorer.gd`: the engine explorer opens on a live class with no errors, plays
  each course's own classes (AA HL all of AA SL's, AI SL's inside AI HL's), counts
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
deploying. In `.github/workflows/test.yml` the `godot` job runs `./test.sh`, and the `web`
job runs the export and the browser screenshots and uploads the screenshots as an artifact.

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
