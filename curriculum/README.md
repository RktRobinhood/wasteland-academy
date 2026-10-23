# Curriculum

The single source of truth for what Wasteland Academy covers: the full **IB Mathematics: Analysis and Approaches SL** syllabus (guide for first assessment 2021), in official guide numbering.

| File | What it is |
|---|---|
| `aa-sl.json` | Every subtopic (SL1.1 to SL5.11), broken into **skills**: the distinct question types IB examines. Each skill lists its difficulty range, paper (calculator or not), question formats, representations, **solution methods**, common misconceptions and **concept threads**. `legacyMap` ties the v1 question IDs to skills. |
| `threads.json` | The concept threads: big ideas that recur across islands (transformations, vectors, rates of change, inverses and so on), with link-question blueprints. |
| `COVERAGE.md` | Generated. How much of the map the content packs cover, subtopic by subtopic. |
| `THREADS.md` | Generated. Every place each thread appears, in student-facing language. |
| `question-types.json` | Every part of the AA SL past-paper bank ([Math-AA question bank](https://github.com/RktRobinhood/Math-AA---Question-Bank)) assigned to an exam **question type**, the pattern a recipe generates numbers for. Functions types carry the full recipe brief; other topics are catalogue level for now. |
| `QUESTION_TYPES.md` | Generated from `question-types.json`. Readable summary, Section A versus B, and coverage per syllabus statement. |
| `PEDAGOGY_GAPS.md` | Generated from `question-types.json`. What the exam leaves out, region by region: unknowns, representations, methods, concept probes, misconceptions and extension types. |

Regenerate the reports after changing the map or any content pack:

```sh
node tools/coverage.mjs --check   # validate the map only
node tools/coverage.mjs --write   # rewrite COVERAGE.md and THREADS.md
node tools/question-types.mjs --bank ../Math-AA---Question-Bank --write   # check the type catalogue, rewrite QUESTION_TYPES.md
node tools/pedagogy.mjs --write   # check situations, views and extension types, rewrite PEDAGOGY_GAPS.md
```

## How the pieces fit

- **Skill** is the unit of coverage. A question belongs to exactly one skill (`skill: "SL2.11.translate-vector"` in content schema v2; older questions are mapped through `legacyMap`).
- **Methods** are the different ways to tackle a skill. Questions should show more than one where the map lists more than one, so students see that maths usually has several routes to the same answer.
- **Threads** link skills across topics. A question tagged with a thread is a concept-link question: it makes the student notice that, for example, a translation vector, vertex form and z = (x − μ)/σ are the same move.

The subtopic table in `CONTENT_SCHEMA.md` predates this map and does not follow guide numbering. Use the IDs here.

## Courses and IDs

The game will serve four IB courses from this one map: AA SL now, AA HL next, then AI SL and AI HL as a stretch goal. A course is a filter over the shared skills, not a separate game. The five islands are the five syllabus topics, which all four courses share.

- **IDs are permanent once they are on `main`.** Saves, spaced repetition and student reports all point at them. Never rename or reuse a subtopic, skill, question or template ID. To drop one, mark it `"retired": true`.
- **AA numbering is the base.** Subtopics use the AA guide's numbers: `SL1.1` to `SL5.11`, and the HL-only subtopics as the guide numbers them (`AHL1.10` and so on).
- **AI-only content takes an `AI-` prefix**, for example `AI-SL1.6` and `AI-AHL1.9`. Where an AI subtopic's guide text matches the AA one, AI reuses the AA ID instead of making a copy.
- **Courses live on subtopics, not questions.** Each subtopic will list its `courses` (for example `["aa-sl", "aa-hl"]`), and a question's course follows from its skill. Until another course is mapped, every subtopic in `aa-sl.json` belongs to both `aa-sl` and `aa-hl`.
- **One file per added layer.** HL-only subtopics go in `aa-hl.json`, and AI-only ones in `ai.json`. That way `aa-sl.json` stays exactly the AA SL syllabus.

## Situations and views (question-types.json)

The question engine plans from situations and views (FAL-310). Every type has a `source`: `exam` (from the bank) or `extension` (a gap the exam leaves). The "Exam-style only" switch keeps exam types and only their `exam: true` unknowns and representations.

- **`situations`** (top level): what a recipe generates. Each lists its `quantities` (name, meaning, how to pick or derive it), `modes` and `clean` limits. `extends` means "that situation plus these quantities". `sharesSituation` on a type names the other types built on the same base, so the base is built once.
- **`unknowns`**: one per sensible question on the situation: `given`, `asked`, `level` (0 to 5, see `levels`), `exam`, the representations (`reps`) the givens can be shown in, and the `skills` it tests.
- **`representations`**: equation, graph, table or words, each marked with whether the exam uses it.
- **`angles`**: methods from this map (`skill` + `method`) and the unknowns each suits. `weak` marks where a method is slow or fails, which seeds method-pick questions.
- **`concepts`**: 1 to 3 probes: true-false-reason, always-sometimes-never, interpret-parameter or predict-check.
- **`misconceptions`**: `ref` is `skill#index` into this map's misconceptions; `wrong` says how the wrong option is made.
- **Extension `kind`**: `skill` (a map skill no exam type covers), `prior-learning` (level 0 algebra, with `supports` naming the skills that need it), `concept`, or `link` (a concept thread, with the `blueprints` it builds on).
- **Coverage cell**: one unknown in one representation by one angle that suits it.

