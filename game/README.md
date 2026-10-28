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
├── scenes/main.tscn     ← title screen (title, Spark, Practice)
├── scenes/practice.tscn ← the practice screen (ui/practice.gd)
├── engine/              ← the question engine: situations, views, marking, planner, save
├── ui/                  ← screens and the graph view
├── data/catalogue.json  ← generated from curriculum/question-types.json (don't edit)
├── assets/              ← art and fonts copied from the repo's assets/ and vendor/fonts/
├── tests/               ← headless test runner and tests
├── tools/screenshot.gd  ← used by ../screenshot.sh
├── tools/export_questions.gd  ← used by ../tools/check-answers
├── tools/stress_questions.gd  ← used by ../tools/stress-questions
├── addons/godot_mcp_toolkit/  ← editor plugin for the Godot MCP (see docs/MCP-NOTES.md)
└── docs/MCP-NOTES.md
```

`config/name` is "Wasteland Academy", so its `user://` folder is its own, not the Atlas's.

Art is imported with mipmaps on (`mipmaps/generate=true` in each `.import`) and drawn
with linear mipmap filtering, so it stays smooth at phone and PC sizes. When you add
art, set the same in its `.import` file.

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
`data/catalogue.json`: rerun `node tools/game-catalogue.mjs --write` after changing the
catalogue (`tests/unit/game-catalogue.test.mjs` fails while the copy is stale).

- A **recipe** (`engine/situations/quadratic.gd`) generates a **situation**: a, the
  roots, the vertex, b, c, Δ, an extra point and a table, consistent and inside the
  catalogue's `clean` limits, in one of its `modes` (rational roots, surd roots, no real
  roots). Situations that extend `quadratic` call its `generate()` and add their own
  quantities. `engine/situations/cubic.gd` is the Topic 5 situation: a cubic built
  from f′(x) = 3a(x − p)(x − q), so its stationary points are on whole numbers, with a
  point x₀ for the gradient, tangent and normal (FAL-394).
- A **view** picks the unknown, the representation, the angle (method) and the format.
  `engine/situations/quadratic_views.gd` has one builder per unknown: what is shown,
  the answer, the wrong options (each catalogue misconception's `wrong` rule, tagged
  with its `ref`) and a worked solution for every method that suits the unknown.
- `QuestionEngine.make(view)` (`engine/question_engine.gd`) returns the question, its
  marking and its working for any explicit view and seed. The same view and seed always
  give the same question. `QuestionEngine.cells()` lists the coverage cells.
- **Formats**: the layer names all eight from the plan. `value` (slot inputs such as
  a(x − □)² + □) and `mcq` are built, and the concept probes play as a verdict
  (true or false; always, sometimes or never; the sign) and then the reason.
- **Marking** (`engine/answer.gd`): exact or right to 3 s.f. Typed numbers are parsed
  by hand (whole numbers, decimals, fractions); nothing is evaluated as an expression.
- **Planner** (`engine/planner.gd`): never-seen cell, then a recently missed one, then
  exam frequency. "Exam-style only" (off by default) keeps exam cells only and follows
  exam frequency.
- **Save** (`engine/save_data.gd`): versioned, with a migration step per version, and
  empty `class`, `trees` and `lessons`.

The practice screen takes deep links, for screenshots and for sending someone a
question: `/next/?view=<type>/<unknown>/<rep>/<angle>/<value|mcq>&seed=3`, or
`<type>/probe/<n>` for a concept probe. Add `&autoplay=right` (or `wrong`) to answer it
at once.

### The SymPy answer checker

`tools/check-answers` exports questions from the engine with fixed seeds (at least 50
per coverage cell and 1,000 per type), then `tools/check_answers.py` solves each one
again with SymPy from its givens. It shares no code with the engine. It checks the
answer, the clean limits, that every option but one is wrong and that all four differ,
that every worked solution ends at the answer, and that the equations shown parse to
the givens. It prints a table per type and per cell. SymPy is pinned in
`requirements.txt` and installed into a gitignored `.venv/` on first run. CI runs it
next to `./test.sh`.

### The seed sweep

The checker only exports seeds 1 to 50. `tools/stress-questions` makes every cell with
seeds 51 to 2250 (about 207,000 questions, a few minutes) and checks that each question
is made with four options, that its own answer typed exactly and to 3 s.f. is marked
right, and that every wrong option typed in is marked wrong with its misconception. It
fails on any script error, such as a failed assert in `Q`. CI runs it as its own
`stress` job.

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
- `test_engine.gd`: every catalogue cell of the three Quadratics types can be made,
  same seed same question, the format layer, wrong options, misconceptions, probes and
  the exam-only cells.
- `test_calculus.gd`: the four Topic 5 types on the cubic: built, every misconception
  appears as an option, two points in either order, nature as multiple choice, f′(x)
  marked exactly, the normal to 3 s.f.
- `test_answer.gd`: parsing and marking typed answers.
- `test_planner.gd`: the planner's three rules, "Exam-style only", and the save.
- `test_practice.gd`: the practice screen plays every representation and format,
  records answers, and fits at 390x844 and 1280x800.

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
dir, for that command only.

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
