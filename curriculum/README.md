# Curriculum

The single source of truth for what Wasteland Academy covers: the full **IB Mathematics: Analysis and Approaches SL** syllabus (guide for first assessment 2021), in official guide numbering.

| File | What it is |
|---|---|
| `aa-sl.json` | Every subtopic (SL1.1 to SL5.11), broken into **skills**: the distinct question types IB examines. Each skill lists its difficulty range, paper (calculator or not), question formats, representations, **solution methods**, common misconceptions and **concept threads**. `legacyMap` ties the v1 question IDs to skills. |
| `threads.json` | The concept threads: big ideas that recur across islands (transformations, vectors, rates of change, inverses and so on), with link-question blueprints. |
| `COVERAGE.md` | Generated. How much of the map the content packs cover, subtopic by subtopic. |
| `THREADS.md` | Generated. Every place each thread appears, in student-facing language. |

Regenerate the reports after changing the map or any content pack:

```sh
node tools/coverage.mjs --check   # validate the map only
node tools/coverage.mjs --write   # rewrite COVERAGE.md and THREADS.md
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
