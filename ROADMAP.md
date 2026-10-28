# Roadmap

The order of work and the target dates. The Paperclip tasks named in each row hold the detail. Dates are targets, and each one is checked at the milestone before it.

Last updated 2026-10-24 (FAL-365).

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

Two tracks run side by side: the four remaining islands, and The Relic lessons below. Class skill trees (FAL-291, phases 2 and 3), the journey scene (FAL-289) and encounters, the rare talking events on the road (FAL-347, code in FAL-349), fit around them, and so does the soundtrack below. The island order and the split between the tracks are set at the November 13 decision. From November 16, Codex builds the Male Learner two ways, as a 3D model and as a 2D cut-out rig, and CEO compares them at strip size (FAL-368). The result decides how new characters are posed, including B0-LT's cutout in L3.

### The Relic: playable lessons

Matt's spec is GitHub issue #13 (FAL-325). Players find salvaged CRT and VR machines in the world. Each one opens a short lesson: a character has a broken machine, shows the problem, and hands the player the controls. The player learns the idea by fixing the machine, then solves a related problem alone.

| When | Step | Who |
|---|---|---|
| Done for Functions | **L0 Design down.** Work back from the exam question types to the ideas and prior skills students need, and group them into a lesson map. Functions first. The Functions map: [`curriculum/LESSONS.md`](curriculum/LESSONS.md). | Curriculum Author |
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

### Soundtrack and sound effects

Matt's ask is FAL-357, and the plan there is approved. The game gets lo-fi study music with a techno layer that fades in when the scene's stakes rise, a toggle to turn it off, and sound effects. It's icing on the cake, so it ships at launch or just after. Nothing is built before November 15.

| When | Step | Who |
|---|---|---|
| Nov 16–22 | **S0 Spike, about a day.** Install ACE-Step 1.5 in ComfyUI, render about 30 candidates for the Signal Tower set, cut the loops, build a listening page, and test three synced layers in a web build (FAL-364). | Codex, and Matt listens |
| Dec 7–20 | **S1 Sound system, alongside L3,** which needs the same Voice bus and ducking. Audio buses, the Music, Sound effects and Voice toggles, `set_tension`, about 15 sound effects, and the Signal Tower set in the game. | Coder |
| As each island ships | **S2 One music set per island,** plus a title theme and stingers. Ready by launch or just after. | Codex, and Matt listens |

These rules hold for every step:

- **One grid at 120 BPM.** The calm layers play half-time, so they feel like study music. The techno layer plays full-time on the same grid, so it can fade in at any moment.
- **The music follows the scene, never a miss.** Bosses, encounters and timed questions raise it. A wrong answer or low HP never does (TONE.md).
- **Music starts on at half volume** after the first tap. A speaker icon on the main screen turns it off, and the game remembers the choice on that device.
- **Licences keep a paid release open.** ACE-Step 1.5 is MIT. MusicGen is out because its model files are CC BY-NC. Sound effects come mostly from CC0 packs and generated retro blips.
