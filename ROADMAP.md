# Roadmap

The order of work and the milestones. The GitHub issues named in each row hold the detail, and `AGENTS.md`, "Work while the owner is away", holds the decisions already made. No target dates are set: a milestone is done when its issues are closed.

Last updated 2026-11-16 (owner decisions on #199, #18, #197 and #203; review on #198).

## Where things stand

The Godot game took over the main address on November 4 (FAL-721). All five zones are open, with the Thunderdome, the Bazaar and Practice. Every AA SL skill is playable, and AA HL, AI SL and AI HL play the maths they share with AA SL ([`curriculum/COVERAGE.md`](curriculum/COVERAGE.md)). The explainer player is built (FAL-429), Spark's move lines are in, and the sound system plays a loop in every zone with sound off by default (FAL-385, FAL-925).

## Milestones

### 1. Classroom release: the web build a class can use

Everything labelled [`classroom-release`](https://github.com/RktRobinhood/wasteland-academy/labels/classroom-release). The web build at GitHub Pages is what a class uses first.

| Issue | What |
|---|---|
| #183 | Cut the first load (music on demand, drop the dev addon, a size budget) |
| #184 | A pinned build for students, a cache-first worker and a build id |
| #185 | Saves: never wipe an unreadable save, write atomically, export and import |
| #186 | First run: course choice, a short "how a fight works", student wording |
| #187 | Test on Safari and iPhone with real taps, plus a device pass |
| #192 | Play only verified seeds; the stress sweep runs nightly and gates releases |
| #193 | Question defects found in review |
| #194 | Typed answers: decimal comma, exact-answer hints, large whole numbers |
| #197 | `/classic/` isn't published, and no repository document is on the site |
| #203 | Wording: places by name, no "islands", the exam switch, every label |

### 2. Explainers ready to record

Labelled [`explainers`](https://github.com/RktRobinhood/wasteland-academy/labels/explainers): #188 to #191, the script format and how maths is spoken. Voices are Gemini text-to-speech with a cost cap, and casting is finished (#18). The approved voice, model and direction for each tutor and character are in `tools/explainer-clips/teachers.json`. No line is generated until the owner approves the cap, which is the card on FAL-1035.

### 3. PC

The first platform after the classroom release (#199): the Windows export in CI, a landscape layout, and full keyboard play. Then macOS and Linux from the same work.

### 4. Android and iOS

After PC (#199): export presets and CI builds, layouts for phones and tablets with safe areas, touch entry against the system keyboard, and store readiness (signing, icons, age rating, a privacy policy, the rules for school apps used by under-18s). Every platform keeps one save format with export and import. Sync between devices is for later (#202).

The umbrella issue #199 closes when each platform has a release build from CI, a recorded test on a real device, and a written release procedure.

### Alongside

- #195: feedback lines for the 78 question types whose wrong options have none.
- #196: accessibility: an extra-time timer, reduced motion in fights, text size.
- #198: these documents.
- #201: map and level art from the owner through ChatGPT, from prompt cards the agents write. The Artist chooses.
- #62: stacked fractions and symbol coverage in maths notation.

## Owner direction: engine reuse and question-bank expansion

Confirmed November 7, 2026: preserve a reusable mathematics engine beneath the
game so future IB educational tools can offer an academic presentation using the
same generation, marking, explanations and curriculum selection. The
[specification](SPEC.md#reusable-mathematics-engine-direction) records the split;
[#134](https://github.com/RktRobinhood/wasteland-academy/issues/134) tracks the
remaining implementation and proof with a second consumer.

The owner plans to add higher-level exams and available exams for all four IB
mathematics courses to the separate
[question bank](https://github.com/RktRobinhood/Math-AA---Question-Bank). Extend
the existing catalogue connection to ingest and filter that metadata, then use
it to identify missing question types and improve recipes. Adding source papers
does not itself build or validate generators. See the
[integration plan](curriculum/README.md#question-bank-integration-direction).

The November 6 sequencing in
[#13](https://github.com/RktRobinhood/wasteland-academy/issues/13) stands: complete the
mathematics engine, roll out question content for the other courses, then implement
playable lessons. No delivery date for an academic interface or expanded bank ingestion
is set.

## The Relic: playable lessons

Matt's spec is GitHub issue #13 (FAL-325). Players find salvaged CRT and VR machines in the world. Each one opens a short lesson: a character has a broken machine, shows the problem, and hands the player the controls. The player learns the idea by fixing the machine, then solves a related problem alone. Lessons come after the engine and the other courses' content (#13).

| Step | What | Who |
|---|---|---|
| L0 | **Design down,** done for Functions. Work back from the exam question types to the ideas and prior skills students need, and group them into a lesson map: [`curriculum/LESSONS.md`](curriculum/LESSONS.md). | Curriculum Author |
| L1 | **Architecture.** The lesson state machine (setup, demonstrate, interact, react, apply, complete), the lesson file format, the interaction parts, and lesson progress in the save. | Coder |
| L2 | **Pilot: The Broken Conveyor** (SL2.11, graph transformations), with placeholder art. Its demonstrate step uses the explainer player. | Coder |
| L3 | **Presentation.** B0-LT as a cutout character and the CRT and salvaged-VR look. | Coder, Artist |
| L4 | **A second lesson that plays differently,** to prove the lesson engine isn't built around one lesson, plus a first Relic Library terminal. | Coder |
| L5 | **Scale up** from the lesson map, zone by zone. | Coder, Curriculum Author, Artist |

The spec's rule stands: build and test two lessons before making more.

### Room for lessons in what is built now

No lesson code is written yet. The Godot build leaves these places for lessons, so nothing has to be torn out later.

- **Save:** an empty `lessons` record next to `class` and `trees`. It keeps lesson progress (discovered, explored, completed, mastered) apart from question results (FAL-322).
- **Engine:** any screen can ask for a question by type, unknown, representation, angle and seed, not only a run. A lesson's apply step uses the same recipes and answer checker as runs, so no lesson question is written by hand (FAL-322).
- **Mistakes:** when a wrong answer matches a multiple-choice distractor, the save records which misconception it was. Lesson feedback uses this, and later the planner can suggest the lesson for that mistake (FAL-322).
- **One explanation per mistake:** lesson feedback comes from the same `misconceptions` entries in `curriculum/question-types.json` as the distractors, so a mistake is explained the same way everywhere.
- **Map:** each zone's map keeps a spot for a Relic device, and the overworld keeps a spot for the Relic Library.
- **IDs:** lesson IDs follow the curriculum rule (`curriculum/README.md`). They're permanent once they're on `main`.

### Where the lessons live

The spec's six themed locations become Relic stations inside the five zones. The zones' names, art and IDs stay as they are.

| Zone | Relic station | Character |
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

## Soundtrack and sound effects

Matt's ask is FAL-357, and the plan there is approved: lo-fi study music with a techno layer that fades in when the scene's stakes rise, and sound effects. The sound system is built (FAL-385): the Music, Sound effects and Voice settings, a loop for every zone and the Thunderdome, and the fight effects (FAL-925). Still to come: the tension layer (`set_tension`), a title theme and stingers.

These rules hold for every step:

- **One grid at 120 BPM.** The calm layers play half-time, so they feel like study music. The techno layer plays full-time on the same grid, so it can fade in at any moment.
- **The music follows the scene, never a miss.** Bosses, encounters and timed questions raise it. A wrong answer or low HP never does (TONE.md).
- **Sound starts off,** on a fresh install and for every student in a classroom (`game/audio/audio.gd`). The speaker icon turns it on, and the game remembers the choice on that device.
- **Licences keep a paid release open.** ACE-Step 1.5 is MIT. MusicGen is out because its model files are CC BY-NC. Sound effects come mostly from CC0 packs and generated retro blips.
