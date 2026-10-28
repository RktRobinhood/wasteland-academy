# Curriculum

The single source of truth for what Wasteland Academy covers: the four IB Mathematics courses (guides for first assessment 2021), in official guide numbering. **AA SL** is mapped in full and live. **AA HL**, **AI SL** and **AI HL** are mapped (FAL-393): every subtopic is in place, with skills ready for question generators.

| File | What it is |
|---|---|
| `aa-sl.json` | Every subtopic (SL1.1 to SL5.11), broken into **skills**: the distinct question types IB examines. Each skill lists its difficulty range, paper (calculator or not), question formats, representations, **solution methods**, common misconceptions and **concept threads**. `legacyMap` ties the v1 question IDs to skills. |
| `aa-hl.json` | The AA HL-only layer: every AHL subtopic (AHL1.10 to AHL5.19), with skills in the same shape as `aa-sl.json`. AA HL is `aa-sl.json` plus this file. |
| `ai.json` | The AI layer: every AI SL and AI AHL subtopic whose content is not shared with AA (`AI-SL1.6`, `AI-AHL1.9` and so on), plus `shared`, the list of AA subtopics AI reuses. |
| `COURSES.md` | Generated. Each course by topic (subtopics, skills, hours), what AA HL adds to AA SL, how much AI shares with AA, and how deep the map is. The same counts go to `game/data/courses.json` for the course picker. |
| `threads.json` | The concept threads: big ideas that recur across islands (transformations, vectors, rates of change, inverses and so on), with link-question blueprints. |
| `COVERAGE.md` | Generated. How much of the map the content packs cover, subtopic by subtopic. |
| `THREADS.md` | Generated. Every place each thread appears, in student-facing language. |
| `question-types.json` | Every part of the AA SL past-paper bank ([Math-AA question bank](https://github.com/RktRobinhood/Math-AA---Question-Bank)) assigned to an exam **question type**, the pattern a recipe generates numbers for. Functions types carry the full recipe brief; other topics are catalogue level for now. |
| `QUESTION_TYPES.md` | Generated from `question-types.json`. Readable summary, Section A versus B, and coverage per syllabus statement. |
| `PEDAGOGY_GAPS.md` | Generated from `question-types.json`. What the exam leaves out, region by region: unknowns, representations, methods, concept probes, misconceptions and extension types. |
| `lessons.json` | The Relic lesson map: short playable lessons designed down from the exam question types, each teaching one idea (GitHub issue #13). Functions in full; the other islands as big ideas only. |
| `LESSONS.md` | Generated from `lessons.json`. Each region's lesson ladder, the build order, and which lessons sit behind each exam type. |

Regenerate the reports after changing the map or any content pack:

```sh
node tools/coverage.mjs --check   # validate the map only
node tools/coverage.mjs --write   # rewrite COVERAGE.md and THREADS.md
node tools/courses.mjs --check    # validate the three course layers; fails if the course index is stale
node tools/courses.mjs --write    # rewrite game/data/courses.json and COURSES.md
node tools/question-types.mjs --bank ../Math-AA---Question-Bank --write   # check the type catalogue, rewrite QUESTION_TYPES.md
node tools/pedagogy.mjs --write   # check situations, views and extension types, rewrite PEDAGOGY_GAPS.md
node tools/lessons.mjs --write    # check the lesson map, refresh its priorities, rewrite LESSONS.md
```

## How the pieces fit

- **Skill** is the unit of coverage. A question belongs to exactly one skill (`skill: "SL2.11.translate-vector"` in content schema v2; older questions are mapped through `legacyMap`).
- **Methods** are the different ways to tackle a skill. Questions should show more than one where the map lists more than one, so students see that maths usually has several routes to the same answer.
- **Threads** link skills across topics. A question tagged with a thread is a concept-link question: it makes the student notice that, for example, a translation vector, vertex form and z = (x − μ)/σ are the same move.

The subtopic table in `CONTENT_SCHEMA.md` predates this map and does not follow guide numbering. Use the IDs here.

## Courses and IDs

The game serves four IB courses from this one map: AA SL (live), and AA HL, AI SL and AI HL (mapped). A course is a filter over the shared skills, not a separate game. The five islands are the five syllabus topics, which all four courses share.

- **IDs are permanent once they are on `main`.** Saves, spaced repetition and student reports all point at them. Never rename or reuse a subtopic, skill, question or template ID. To drop one, mark it `"retired": true`.
- **AA numbering is the base.** Subtopics use the AA guide's numbers: `SL1.1` to `SL5.11`, and the HL-only subtopics as the guide numbers them (`AHL1.10` to `AHL5.19`).
- **AI-only content takes an `AI-` prefix**, for example `AI-SL1.6` and `AI-AHL1.9`. Where an AI subtopic's guide text matches the AA one, AI reuses the AA ID instead of making a copy.
- **Courses live on subtopics, not questions.** Each subtopic lists its `courses` (for example `["aa-sl", "aa-hl"]`), and a question's course follows from its skill.
- **One file per added layer.** HL-only subtopics go in `aa-hl.json`, and AI-only ones in `ai.json`. That way `aa-sl.json` stays exactly the AA SL syllabus.

### Which courses a subtopic lists

| File | Subtopics | `courses` |
|---|---|---|
| `aa-sl.json` | `SL1.1` to `SL5.11` | always `aa-sl` and `aa-hl`; also `ai-sl` and/or `ai-hl` when AI shares it |
| `aa-hl.json` | `AHL1.10` to `AHL5.19` | `aa-hl` |
| `ai.json` | `AI-SL…` | `ai-sl` and `ai-hl` |
| `ai.json` | `AI-AHL…` | `ai-hl` |

### How AI shares with AA

A subtopic is shared only where the AI content statement says the same as the AA one. Then the AA subtopic adds the AI course to its `courses`, and `shared` in `ai.json` records the AI guide number it stands for. For example, `{"ai": "AHL1.11", "id": "SL1.8", "courses": ["ai-hl"]}` says that AI HL's 1.11 (infinite geometric series) is AA's SL1.8. AI SL shares 26 AA SL subtopics this way, and AI HL shares 3 more (SL1.8, SL2.11 and SL5.9).

Where AI covers part of an AA statement, or covers it differently (AI SL3.4 is in degrees, for example, and AI AHL5.9 bundles derivatives that AA spreads over SL5.6 and AHL5.14), the AI subtopic gets its own `AI-` ID and an **`overlaps`** list naming the AA subtopics it touches. `overlaps` is information for authors (reuse a generator, or compare depth). It does not share skills.

A shared subtopic keeps its AA prerequisites, so a few point outside the AI course (SL5.9 kinematics needs SL5.6, which AI HL covers as AI-AHL5.9). `COURSES.md` lists them. Treat a prerequisite outside the student's course as met.

### Other fields

- **`hours`** on each topic are the guide's recommended teaching hours for that topic's content. In `aa-sl.json` they are the SL hours and in `aa-hl.json` the AHL hours, so AA HL is the sum. In `ai.json` they are `{"sl": …, "ahl": …}` for the whole AI topic, shared subtopics included. Totals: SL 120 and HL 210 for both AA and AI.
- **`paper`** means calculator or not: `p1` no calculator, `p2` calculator, `either`. Every AI paper allows a GDC, so every AI skill is `p2`. AA HL Paper 3 allows a calculator.
- **Thin skills.** A skill needs `id`, `name` and `paper`. One without `difficulty`, `formats`, `representations`, `methods` or `misconceptions` counts as thin, and `COURSES.md` lists it.
- `tools/coverage.mjs` and `COVERAGE.md` still measure the content packs against AA SL only.

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

## Lessons (lessons.json)

A Relic lesson is a 3 to 6 minute playable episode: a character shows a broken machine, the player takes the controls, the character reacts to what the player did, the recipe engine sets an independent task, and a debrief turns the machine into notation. **A lesson teaches one idea, not one question type.** One idea usually serves several types, and one type usually needs several ideas.

- **`id`** is `lesson.<island>.<idea>`, with the island prefix `num`, `fn`, `geo`, `stat` or `calc` for topics 1 to 5. Lesson IDs are permanent once they are on `main`, like every other ID here: saves will record lesson progress against them.
- **`objective`** is one sentence a student would understand. **`idea`** is the principle underneath it.
- **`region`**, **`topic`** and **`station`** place the lesson: a Functions region from `question-types.json`, and the Relic station from `ROADMAP.md` (`scrapworks` for Functions).
- **`skills`** are skill IDs from this map. **`assumes`** lists skills the lesson needs that another island teaches, such as log laws.
- **`supports`** are the question-type IDs the lesson prepares students for. **`unknowns`** lists, for each supported type, the unknowns it prepares for; every exam type in `supports` needs an entry.
- **`levels`** is the level range the lesson teaches towards (0 to 5, as in `question-types.json`). Level 0 lessons are prior learning: they apply a `prior-learning` type and have no skills of their own.
- **`prerequisites`** are lesson IDs. The check rejects cycles.
- **`misconceptions`** are the mistakes the react stage answers: `skill#index` into this map, or `type#index` for a prior-learning type's own misconceptions. Lesson feedback and multiple-choice distractors use the same entries.
- **`interaction`** is one of the 8 kinds in `interactions`. **`scenario`** is 2 or 3 sentences: the character, the machine, what the player controls, what success looks like, and the notation the debrief brings in.
- **`apply`** is what the engine generates for the independent task: a `type`, its `unknowns`, and optionally the `reps` to show the givens in.
- **`alignment`** is the IB subtopic plus Common Core, AP Precalculus, GCSE and A level references. Every code must be listed in `sources`, which records where it was checked. Leave a code out rather than guess one.
- **`materials`** are open resources worth borrowing from. Only licences that allow a paid release are accepted (CC BY, CC BY-SA, CC0 and similar). Check the licence on the source itself: OpenStax 2e books and PhET simulations are now non-commercial, for example. Adapting CC BY-SA material makes the adapted asset CC BY-SA too. OpenStax's book pages also say the books may not be fed to AI tools without permission, so agents take ideas from them, not text.
- **`priority`** is computed: `parts` is the exam parts the lesson supports, weighted by the share of each type's exam unknowns it lists, and `rank` is the build order. `--write` refreshes both.
- **`gaps`** lists any Functions exam type with no lesson, with the reason. The check fails if an exam type has neither.

