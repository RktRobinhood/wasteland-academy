# The maths engine interface

Step 1 of [#134](https://github.com/RktRobinhood/wasteland-academy/issues/134) (FAL-798),
following the [reusable engine direction](../../SPEC.md#reusable-mathematics-engine-direction).
Wasteland Academy is one presentation of the maths. This page sets out what any
presentation can ask the engine for, and what stays with the game.

The interface is `MathsEngine` in `game/engine/maths_engine.gd`, version 1
(`MathsEngine.VERSION`). It has only static functions. It needs no scene and no save
file, and it covers five things:

| Area | Calls |
|---|---|
| Curriculum selection | `courses()`, `topics()`, `types(course, exam_only)`, `requests(course, exam_only, type_ids)`, `topic_of`, `asked`, `method_name`, `skill_name` |
| Generation | `generate(request)`, `prompt(question)`, `is_choice(question)` |
| Marking | `mark(question, response)`, `model_response(question, right)` |
| Worked solutions | `worked_solutions(question)`, `answer_sentence(question)` |
| Learning results | `blank_evidence()`, `record(evidence, question, result, now)`, `results(evidence, course, exam_only, type_ids)`, plus `coverage`, `accuracy`, `skill_stats` and `weakest_skills` over any list of requests |

## The data

- **Request**: `{"type", "unknown", "rep", "angle", "format", "seed"}`, plus an optional
  `"paper"` (1 or 2). `requests()` lists the first four for every coverage cell a course
  covers. Add a format (`value`, `mcq`, `error-spot`, `method-pick`,
  `true-false-reason`) and a seed. A concept probe is `{"type", "probe": n, "format":
  "probe"}`. **The same request always gives the same question**, whichever screen
  asks for it.
- **Question**: a Dictionary. A screen reads `prompt(question)`, `lines`, `table`,
  `graph`, `diagram` and `graphs` (what to draw), `answer.template` (the answer boxes:
  text, `{"slot"}` to type into, `{"pick", "options"}` to choose from), `choices[].text`
  (`options` on a probe), `paper`, `marks`, `level`, `exam` and `type_name`. `cell` is
  the key that evidence is recorded under. The other fields belong to the engine:
  pass the question back as it came.
- **Response**: `{"choice": i}` for a choice question or a probe. Otherwise it is box id
  → typed text, and pick id → the option chosen.
- **Result** (`mark`): `{"correct", "complete", "glancing", "errors", "misconception"}`.
  An incomplete response has `errors` saying what is missing. `glancing` means the
  right value at the wrong accuracy, or the rounding trap. `misconception` is the
  catalogue ref of the mistake a wrong answer matches.
- **Worked solution**: `[{"angle", "name", "steps": [text], "result"}]`, with the method
  that was asked first. Every step is plain text.
- **Evidence**: `{"cells", "probes", "history"}`. Each cell holds `{"seen", "right",
  "wrong", "last", "last_result", "misconceptions", "last_misconception"}`. The game's
  save is evidence, with the game's own fields alongside. The study screen keeps its
  own evidence in `user://study.json`.

## What is behind it, and what is not

Behind the interface is the maths: `question_engine.gd`, the situations and their
views, `answer.gd`, `expr.gd`, `q.gd`, `courses.gd`, `step.gd`, `fmt.gd`, `plot.gd`,
`seeded.gd` and `brent.gd`, all in `game/engine/`. That is 259 scripts in all, counting
the situations.

These belong to the game, even though they sit in `game/engine/`: `run.gd` (combat),
`dungeon.gd`, `tuning.gd`, `bazaar.gd`, `modifiers.gd`, `map_link.gd`, `art_slots.gd`,
`progress.gd` (the map's region numbers), `planner.gd` (it plans by dungeon region) and
`save_data.gd` (the save and its game fields). The screens in `ui/`, `audio/` and
`journey/` are the game too.

`tests/test_maths_engine.gd` enforces the split. It follows every class name and
script path from `maths_engine.gd`, skipping comments and strings, and fails if any
of them leads to game code. It runs the same check on the study screen, which may
call only `MathsEngine` (and `Fmt`, for numbers in a table).

The game now goes through the interface. The practice screen generates, marks and
records through `MathsEngine`. So does the fight screen, through `run.gd`. The
region numbers in `Progress` are `MathsEngine` learning results over a region's cells,
and `SaveData.record` is `MathsEngine.record_key`.

## The study screen

`/?study` (desktop: `-- --study`) opens `ui/study.gd`. It is a plain, academic screen:
Godot's own controls on a light page, with no game theme, art, sound controls,
characters, combat, rewards or map. You pick a course, a topic, a question type, what
is asked and a seed. Then you answer, mark it, and read the worked solution. Your
record on the course is shown below the question. A link can name a question:
`/?study&view=<type>/<unknown>/<rep>/<angle>/<format>&seed=3`.

It does not draw graphs or diagrams yet. Its question list offers the representations
it can show: equations, words, notation, terms and tables. A question that also carries
a graph says so.

**The seed check**: `test_one_request_gives_the_same_maths_on_both_screens` puts six
requests through the practice screen and the study screen. They are value, multiple
choice, a table and a probe, each answered right and then wrong. Each screen answers
through its own controls. The test checks that both screens show the same prompt,
lines, table, options, paper, marks, answer and worked solutions, and that both record
the same marking and misconception.

## Not in version 1

- **Scenario wording.** The engine adds no game wording of its own. HP, enemies,
  "Missed" and Scrap are all written by `fight.gd` and `run.gd`. But the scenarios
  inside some questions are set in the game's world. 36 situation files mention the
  bazaar, caravans, scrap, settlers, raiders or bunkers ("A lucky dip at the bazaar holds
  1000 tokens…"), and both screens show that text as it is. The planned seam is a
  context pack chosen per request. It would swap only the nouns of a scenario after
  the numbers are generated, so the maths cannot change. It is not built yet.
- **Multi-part questions.** `QuestionEngine.make_chain` builds the linked parts of a
  boss or a link question. The fight screen still calls it directly.
- **Planning.** `Planner.next` picks the next question from the evidence, but it
  plans by dungeon region, so it is game code for now. To join the interface it would
  take a list of requests instead of a region.
- **Developer tools.** The engine explorer and the answer, stress and feedback checks
  (`tools/`) still call `QuestionEngine` directly. They test the engine itself and are
  not presentations.

## Packaging outside Godot (options only, not chosen)

The engine is GDScript and runs inside Godot. #134 leaves the packaging to be chosen
later. The options:

1. **A second Godot project or export** that includes only the maths files above. The
   dependency test already defines that set. This is the least work, but it is still
   Godot, and on the web it is still a WebAssembly build.
2. **A headless Godot service or batch export** that writes questions as JSON.
   `tools/export_questions.gd` already does this for the answer checker. It suits
   question banks and printed worksheets, not live marking.
3. **A port to TypeScript or Python** that reads the same catalogue. The existing
   question export would be the conformance test: the same request and seed must give
   the same question. This costs the most, and it keeps two engines in step.
