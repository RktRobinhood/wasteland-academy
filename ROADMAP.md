# Roadmap

The order of work and the target dates. The Paperclip tasks named in each row hold the detail. Dates are targets, and each one is checked at the milestone before it.

Last updated 2026-10-23 (FAL-325).

## Now to November 15: the Functions island in Godot

Matt asked for the Godot rebuild after the student trial (GitHub issue #8, planned on FAL-274). The HTML game stays live at the main address until the takeover.

| By | What | Task |
|---|---|---|
| Oct 28 | Godot project live at `/next/`. The recipe engine, the SymPy answer checker and the Quadratics region | FAL-321, FAL-322 |
| Nov 4 | Exponentials and logs, Graphs and key features with the in-game calculator, Composite and inverse, Rational functions | FAL-274 |
| Nov 8 | Progress check. It decides whether class phase 1 makes the November 15 build | FAL-291 |
| Nov 11 | Function basics, Lines and Transformations, the calculator skin, then the 9 extra skills | FAL-274 |
| Nov 13 | Takeover decision: does the Godot build replace the HTML game at the main address? | FAL-274 |
| Nov 15 | The Functions island in Godot, for mid-term review | FAL-274 |

Art runs alongside: icon animation loops (FAL-323) and a one-region slice of the side-scrolling journey scene (FAL-289, FAL-293).

## After November 15

Two tracks run side by side: the four remaining islands, and The Relic lessons below. Class skill trees (FAL-291, phases 2 and 3) and the journey scene (FAL-289) fit around them. The island order and the split between the tracks are set at the November 13 decision.

### The Relic: playable lessons

Matt's spec is GitHub issue #13 (FAL-325). Players find salvaged CRT and VR machines in the world. Each one opens a short lesson: a character has a broken machine, shows the problem, and hands the player the controls. The player learns the idea by fixing the machine, then solves a related problem alone.

| When | Step | Who |
|---|---|---|
| Now | **L0 Design down.** Work back from the exam question types to the ideas and prior skills students need, and group them into a lesson map. Functions first. | Curriculum Author |
| Nov 16–22 | **L1 Architecture.** The lesson state machine (setup, demonstrate, interact, react, apply, complete), the lesson file format, the interaction parts, and lesson progress in the save. | Coder |
| Nov 23 – Dec 6 | **L2 Pilot: The Broken Conveyor** (SL2.11, graph transformations), with placeholder art. | Coder |
| Dec 7–20 | **L3 Presentation.** B0-LT as a cutout character, local narration with subtitles, and the CRT and salvaged-VR look. | Coder, Artist |
| Jan 4–17, 2027 | **L4 A second lesson that plays differently,** to prove the lesson engine isn't built around one lesson. Plus a first Relic Library terminal. | Coder |
| From Jan 18, 2027 | **L5 Scale up** from the lesson map, island by island, in the order the islands ship. | Coder, Curriculum Author, Artist |

The spec's rule stands: build and test two lessons before making more.

### Room for lessons in what we build now

No lesson code is written before November 15. The Godot build leaves these places for lessons, so nothing has to be torn out later.

- **Save:** an empty `lessons` record next to `class` and `trees`. It keeps lesson progress (discovered, explored, completed, mastered) apart from question results (FAL-322).
- **Engine:** any screen can ask for a question by type, unknown, representation, angle and seed, not only a run. A lesson's apply step uses the same recipes and answer checker as runs, so no lesson question is written by hand (FAL-322).
- **Mistakes:** when a wrong answer matches a multiple-choice distractor, the save records which misconception it was. Lesson feedback uses this, and later the planner can suggest the lesson for that mistake (FAL-322).
- **One explanation per mistake:** lesson feedback comes from the same `misconceptions` entries in `curriculum/question-types.json` as the distractors, so a mistake is explained the same way everywhere.
- **Map:** each island map keeps a spot for a Relic device, and the overworld keeps a spot for the Relic Library.
- **IDs:** lesson IDs follow the curriculum rule (`curriculum/README.md`). They're permanent once they're on `main`.

### Where the lessons live

The spec's six themed locations become Relic stations inside our five islands. The islands' names, art and IDs stay as they are.

| Island | Relic station | Character |
|---|---|---|
| The Scrap Fields (Number and algebra) | Trader's Caravan | A paranoid wasteland accountant |
| The Signal Tower (Functions) | Scrapworks | B0-LT, a malfunctioning scrap robot |
| The Dry Flats (Geometry and trigonometry) | Broken Observatory | An eccentric signal engineer |
| Radio Spires (Statistics and probability) | Signal Bunker | A conspiracy-minded radio operator |
| The Engine Core (Calculus) | Engine Graveyard and Flooded Reservoir | A reckless mechanic, and an ancient water-system caretaker |

### Material from other courses

The maths is much the same in the IB, A-level, GCSE and US high school courses (Common Core, AP Precalculus and AP Calculus), so the lesson map draws on all of them.

- **Question types and teaching ideas can come from any course.** Recipes write their own numbers and wording, so nothing is copied.
- **Text, diagrams and videos are copied only when the licence allows a paid release,** such as CC BY. Non-commercial licences (CC BY-NC) are out, and so are exam board papers. This keeps a later Android, iOS or Steam release open.
