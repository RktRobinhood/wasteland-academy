# WASTELAND ACADEMY — Full Project Specification

> IB mathematics gamified review tool: AA SL in full, and the maths AA HL, AI SL and AI HL share with it  
> Status: Live. The Godot game is at the main address; last checked against it 2026-11-16 (#198)  
> Target: an app for PC, then Android and iOS (#199). GitHub Pages is the testing host

**How to read this.** This is the design specification. Where it and the Godot game differ, the game and `game/README.md` are right, and this file should be fixed. Sections or paragraphs marked **Legacy** describe the original HTML game, which isn't published for students (#197).

---

## 1. CONCEPT

A roguelite math review game for IB Mathematics, built first for Analysis and Approaches SL. Students navigate a post-apocalyptic wasteland overworld (Mario World structure), entering topic zones to battle math enemies and visiting a central **Thunderdome** for configurable exam-prep runs. The aesthetic is **Salvage Neon Bazaar** — dark, gritty wasteland punctuated by vibrant neon. Built as a Progressive Web App so students can install it to their phone home screen and play it like a native game.

**Core philosophy**: Productive struggle + flow state + spaced repetition. The game responds to the student's level, rewards being in the right difficulty zone, and circles back to weak spots with breathing room.

### Reusable mathematics engine direction

Owner direction, November 7, 2026: build the mathematics engine so it can serve
other IB educational tools, including a more academic interface for learners and
institutions who prefer that presentation. Wasteland Academy is the first
consumer. Its world, characters and combat should not be prerequisites for
using the mathematics.

- **Shared mathematics:** curriculum and course selection, seeded question
  generation, answer marking, worked solutions, misconception feedback, question
  planning and learning evidence belong behind a small reusable interface.
- **Presentation:** combat, rewards, characters, narrative, navigation and art
  belong to the game. Question wording and scenario context also need a seam so
  an academic presentation can use neutral contexts with the same mathematics.
- **Existing groundwork:** `game/engine/question_engine.gd` already exposes
  generation and marking to multiple screens. It is GDScript and uses Godot
  resources; `game/engine/` also holds game-specific rules. This is groundwork,
  not a completed standalone library or proof of reuse outside Godot.
- **Proof of reuse:** a minimal academic consumer should request, display and
  mark questions without combat or game scenes. The same mathematical request
  and seed must retain the same mathematics, marking and solution through both
  presentations. Choose the runtime and packaging when implementing this proof.
- **Separate question bank:** keep source exams and their authoring in the
  [question-bank repository](https://github.com/RktRobinhood/Math-AA---Question-Bank).
  Import reviewed metadata and question-type mappings to improve recipes and
  filtering across AA SL, AA HL, AI SL and AI HL as papers become available.
  Practice must continue to work offline with the reviewed runtime catalogue.

**Interface, version 1** (FAL-798): `MathsEngine` (`game/engine/maths_engine.gd`)
covers curriculum selection, generation, marking, worked solutions and learning
results, with a test that it reaches no game code. The practice and fight screens use
it, and so does a minimal academic study screen at `/?study`, which is checked to give
the same maths, marking and solution for the same request and seed. The interface, its
gaps (scenario wording, multi-part questions, planning) and the packaging options are
in [game/docs/MATHS-ENGINE.md](game/docs/MATHS-ENGINE.md).

This direction guides ongoing engine work. Packaging outside Godot, neutral scenario
wording and expanded bank ingestion remain open in
[#134](https://github.com/RktRobinhood/wasteland-academy/issues/134); the
[curriculum integration plan](curriculum/README.md#question-bank-integration-direction)
records the data requirements.

---

## 2. PLATFORM & TECHNICAL STACK

### Platforms
- **Now:** a Godot web build on GitHub Pages, at the main address. It is the testing host, and the build a class uses first (the `classroom-release` issues).
- **Next:** an app for PC (Windows first, then macOS and Linux), then Android and iOS (#199). Godot was chosen so one project exports to all of them.
- **Offline:** every file the game uses ships with it. On the web, `_takeover/service-worker.js` keeps a copy after one visit.

### Tech Stack
- **Godot 4.7.2**, all code in GDScript (C# can't export to the web), Compatibility renderer, portrait 1080×1920 base with "expand" stretch.
- **Question engine** in `game/engine/`: seeded recipes generate every question, marking and worked solution from `curriculum/question-types.json`. Reference: `game/docs/QUESTION-ENGINE.md`. Its reusable interface is `MathsEngine` (`game/docs/MATHS-ENGINE.md`).
- **Maths notation** is drawn by the game (`ui/math_box.gd`), and answers are typed in notation with stacked fractions, powers and roots (`ui/math_entry.gd`). No LaTeX.
- **Fonts:** Bangers (display) and Share Tech Mono (body), both OFL, plus a DejaVu subset for maths symbols, copied into `game/assets/fonts/`.
- **Saves:** `user://save.json` and `user://settings.cfg` (IndexedDB on the web). Per device, no accounts. Export and import are planned (#185); sync is for later (#202).
- **No network calls** beyond the site the game is served from (`PRIVACY.md`).
- **Checks:** a headless Godot test suite, an independent SymPy answer checker and a seed sweep run in CI on every PR (`README.md`, "Run, test and export").

### Legacy: the HTML game
The original game is vanilla JS with no build step, KaTeX for maths, CSS custom properties for the design tokens, and `localStorage` through `js/platform.js` for saves, with JSON export and import. Each question pack in `content/` registers itself with `WA.registerPack(pack)` (`CONTENT_SCHEMA.md`). The file layout is in `README.md`, "The legacy HTML game".

---

## 3. VISUAL DESIGN SYSTEM

### Aesthetic: Salvage Neon Bazaar
Post-apocalyptic wasteland world. Dark, desolate base punctuated by vibrant handmade neon. Rusted metal, scrap materials, duct tape and patches. Coexistence of decay and hope. Think: Borderlands meets WALL-E meets a student's bedroom.

### Colour Palette
```css
:root {
  /* Base */
  --col-bg:          #1F2937;   /* Charcoal — primary background */
  --col-surface:     #111827;   /* Deep dark — cards, panels */
  --col-border:      #374151;   /* Subtle dividers */

  /* Neon Accents */
  --col-magenta:     #FF3DA7;   /* Bazaar Magenta — primary CTA, enemy HP */
  --col-teal:        #22D3C5;   /* Scrap Teal — player HP, success states */
  --col-mint:        #9FF0E6;   /* Neon Mint — secondary highlight */

  /* Warm Accents */
  --col-rust:        #FAA261;   /* Rust Orange — warnings, timers */
  --col-dust:        #EACB74;   /* Dust Yellow — Scrap currency, gold states */
  --col-concrete:    #9CA3AF;   /* Concrete Grey — muted text, disabled */

  /* Semantic */
  --col-success:     #22D3C5;
  --col-danger:      #FF3DA7;
  --col-warning:     #FAA261;
  --col-scrap:       #EACB74;
  --col-math:        #9FF0E6;   /* KaTeX math tint */
}
```

The Godot game uses the same background and accent colours, with its own panel shades (`game/ui/ui_theme.gd`). **Legacy:** the CSS blocks below, the KaTeX tinting and the pixel sizes are the HTML game's.

### Typography
```css
/* Vendored fonts — vendor/fonts/fonts.css, linked once in index.html, precached by SW */

--font-display: 'Bangers', cursive;        /* Headings, boss names, alerts */
--font-body:    'Share Tech Mono', monospace; /* All UI text, questions, stats */
```

### KaTeX Math Tinting
```css
.katex { color: var(--col-math); }
.katex-display { color: var(--col-math); }
```

### Mobile-First Layout
- Base design: 390px wide (iPhone 14 reference)
- Fluid up to 600px, then centred with max-width cap
- Portrait orientation locked via manifest + CSS
- Safe area insets applied to all edge-touching elements:
  ```css
  padding-bottom: max(1rem, env(safe-area-inset-bottom));
  padding-top: max(1rem, env(safe-area-inset-top));
  ```
- No hover-dependent interactions — all states must work on touch
- Minimum tap target: 48×48px

---

## 4. GAME STRUCTURE

### 4.1 Overworld Map (Mario World)
A wasteland map, The Wasteland, showing 5 topic zones + the central Thunderdome. Players read each place's name, never "island" or "zone" (#203, `writing/glossary.md`).

**Zones**:
| Zone | Topic | IB Reference |
|--------|-------|-------------|
| The Scrap Fields | Numbers & Algebra | Topic 1 |
| The Signal Tower | Functions | Topic 2 |
| The Dry Flats | Geometry & Trigonometry | Topic 3 |
| Radio Spires | Statistics & Probability | Topic 4 |
| The Engine Core | Calculus | Topic 5 |

**Central Hub**: The Thunderdome — battle arena, always accessible

Zone states: **Locked** / **In Progress** / **Cleared** (boss defeated)  
Node states: **Locked** / **Available** / **Complete** / **WANTED** (has flagged questions)

### 4.2 Zone Structure (Node Map)
Zone maps are hubs (FAL-531): regions sit around the zone's tower, joined by branching roads, and open in any order. SPARK's pick (the untried, weakest or least-covered open region) gives guidance in place of gates. The floors inside a region stay in order. Players read a floor as a **mile** (`writing/glossary.md`).
Each zone contains 6–10 nodes arranged in a branching path:
- One **main branch** (linear, prerequisite-ordered)
- **Side branches** for alternative/advanced subtopics
- Node types: **Battle** (standard fight) / **Mini-Boss** / **Rest Point** (review worked solutions) / **Boss** (zone finale)
- Completing the zone boss marks the zone **Cleared** on the overworld

### 4.3 Thunderdome
Central arena, accessible from day one. Students configure their run before entering.

**Pre-run configuration screen**:
- Topic selector: toggle any/all of the 5 topics
- Difficulty filter: which difficulty tiers to include (D1–D5)
- Mode selector: **Endurance** or **Gauntlet**

**Endurance Mode**: Questions come endlessly, difficulty scales up over time. Run ends when player HP hits zero. Score = questions answered correctly before death.

**Gauntlet Mode**: Escalating waves. Wave 1 (D1/D2 questions) → Wave 2 (D2/D3 + Mini-Boss) → Wave 3 (D3/D4 + Mini-Boss) → Final Boss (D5). Succeed or die trying — no fixed question count.

Both modes: high score tracked per configuration, shown on Thunderdome entry screen.

---

## 5. COMBAT SYSTEM

### 5.1 Core Loop (Slay the Spire model)
1. **Enemy appears** — name, difficulty tier, HP bar, and **incoming damage value** shown
2. **Question displayed** — one question at a time
3. **Player answers** — via MCQ tap or calculator numpad
4. **Outcome resolved** — one of three results:
   - ✅ **Success**: Enemy takes full damage. Player earns full Scrap. No HP loss.
   - ⚡ **Success with Complication**: Enemy takes partial damage. Player takes chip damage. Partial Scrap earned. (Used for multi-part boss questions with partial marks.)
   - ❌ **Failure**: Player takes full incoming damage. No Scrap. Question flagged as WANTED.
5. **Next question or enemy defeated** — enemy HP depletes across multiple questions; when it hits zero, enemy is cleared and next enemy appears

### 5.2 Difficulty Tiers
| Tier | Name | IB Equivalent | Enemy Type | Incoming Damage | Scrap Reward | Timer |
|------|------|---------------|------------|-----------------|--------------|-------|
| D1 | Recruit | 1–2 mark recall | Scavenger | 8 HP | 30 Scrap | 60s |
| D2 | Operative | 3–4 mark procedural | Raider | 15 HP | 22 Scrap | 45s |
| D3 | Sergeant | 5–6 mark P1 style | Enforcer | 25 HP | 15 Scrap | 30s |
| D4 | Commander | 5–6 mark P2 style | Warlord | 35 HP | 10 Scrap | 25s |
| D5 | Overseer | 10+ mark synoptic | BOSS | 50 HP | 5 Scrap | 15s |

**Key design principle**: Harder questions give *less* Scrap. Incentivises staying in the productive struggle zone rather than grinding max difficulty. Risk (high incoming damage) is not rewarded with high Scrap — the reward is clearing the node/wave.

**Timer mechanic**: Answering in the last 20% of time = chip damage to player even on a correct answer (partial complication).

### 5.3 Player HP
- Starting HP: 100
- HP bar displayed at top of screen throughout a run
- HP does not regenerate mid-run (Rest Point nodes show worked solutions but do not heal)
- Run ends at 0 HP

### 5.4 Multi-Part Questions (Boss/Mini-Boss only)
- Presented as sequential parts (Part a, Part b, Part c)
- Each part resolved individually with the three-outcome system
- Total damage and Scrap calculated across all parts
- Getting Part a wrong does not skip Part b — student attempts all parts

---

## 6. QUESTION SYSTEM

### 6.1 Question Types

**MCQ** (majority of questions, all difficulty tiers)
- 4 options displayed as large tap targets
- Worked solution revealed after answer
- 50-50 lifeline available

**Value Input** (typed answers)
- On-screen keypad: digits, backspace, decimal point, negative, the fraction key, powers and roots, typed in notation
- Marked exactly on Paper 1 and to 3 s.f. on Paper 2, with equivalent answers accepted unless the question asks for a form (`TEACHERS.md`, "How typed answers are marked")
- 50-50 lifeline disabled
- Freeze lifeline available

### 6.2 Difficulty Calibration Reference
Use the Math AASL Question Bank repo (read-only reference) at:
`../Math AASL Question Bank/`

Calibration guide:
- D1: 1–2 mark questions, single step, direct recall
- D2: 3–4 mark questions, 2-step procedural
- D3: 5–6 mark P1 (no calculator) questions
- D4: 5–6 mark P2 (calculator allowed) questions  
- D5: 10+ mark synoptic, multi-topic questions; reserved for bosses

### 6.3 Content Coverage
Every question is generated: a recipe picks the numbers from a seed, and the engine writes the stem, the options, the marking and the worked solution. Every AA SL skill is playable, and so is most of the maths AA HL, AI SL and AI HL share with AA SL. [`curriculum/COVERAGE.md`](curriculum/COVERAGE.md) has the current count, generated from the engine.

**Legacy:** the HTML game used hand-written packs, about 3–5 questions per subtopic (`CONTENT_SCHEMA.md`).

Topic breakdown follows the course scheme of work:
- **Topic 1**: SL1.1–SL1.8 (Scientific notation, sequences, logs, proof)
- **Topic 2**: SL2.1–SL2.11 (Lines, functions, quadratics, rationals, transformations)
- **Topic 3**: SL3.1–SL3.8 (3D geometry, trig, unit circle, identities)
- **Topic 4**: SL4.1–SL4.6 (Statistics, probability, distributions)
- **Topic 5**: SL5.1–SL5.11 (Differentiation, integration, kinematics)

---

## 7. SPACED REPETITION ENGINE

In the Godot game the planner (`game/engine/planner.gd`) serves a question cell the student has never seen first, then one they got wrong recently but not within the last few questions, then one weighted by how often the IB asks its type. It has no WANTED board yet.

### Legacy: the HTML game's logic
- Questions answered with **Failure** are flagged as **WANTED**
- WANTED questions re-enter the pool with elevated priority
- **Breathing room rule**: A WANTED question will not resurface until at least 3–5 other questions have been answered first
- On re-attempt: **Success** removes the WANTED flag. **Failure** resets the breathing room counter.
- WANTED status persists across sessions (stored in localStorage)

### WANTED Display
- WANTED questions shown with a "WANTED" bounty poster marker in the stats screen
- During a run, if a WANTED question appears, a subtle "BOUNTY" indicator shows on the question card (not alarming — just a small badge)
- Player does not know exactly when a WANTED question will return — only that it will

---

## 8. LIFELINES (Who Wants to Be a Millionaire DNA)

Three lifelines per run, one charge of each. Once used, gone for that run. The Bazaar sells extra charges. Names as in `writing/glossary.md`.

| Lifeline | MCQ | Value Input | Effect |
|----------|-----|-------------|--------|
| **50-50** | ✅ Enabled | ❌ Disabled | Removes 2 incorrect MCQ options |
| **Freeze** | ✅ Enabled | ✅ Enabled | Stops the timer for 15 seconds |
| **Hint** | ✅ Enabled | ✅ Enabled | Reveals first step of worked solution without showing answer |

Lifeline icons: visually distinct, clear enabled/disabled state. See ART_REQUIREMENTS.md.

---

## 9. PROGRESSION & ECONOMY

### Scrap (Currency)
- Earned by answering questions correctly (amount varies by difficulty — lower tiers pay more)
- Spent in the **Bazaar** (between-run shop accessible from overworld)
- Bazaar items: refill lifelines, unlock cosmetic avatar gear, purchase run-start perks

### Perks (Run Modifiers)
Purchased/unlocked, activated at run start. Do not permanently upgrade stats — they modify the run.
Examples:
- *Field Manual*: Hints cost 0 Scrap this run
- *Scrap Armour*: Start with +20 HP
- *Lucky Find*: One extra lifeline charge this run
- *Focused*: Timer extended by 10s on all questions this run

### Mastery Gating (Zone Mode)
In the Godot game (FAL-531), zone maps are hubs: every built region opens in any order, and SPARK's pick gives guidance in place of the gates below. Only the floors inside a region stay sequential.
- Zone nodes unlock sequentially along the main branch
- Side branch nodes unlock when their prerequisite main-branch node is cleared
- Zone boss unlocks only when all main-branch nodes are cleared
- No minimum accuracy required to "pass" a node — students may always retry

---

## 10. PLAYER PROFILE & CHARACTERS

Character plan: FAL-939 (2026-11-15). Classes, traits, action skills and trees: FAL-291, with tree plan v2 from FAL-345.

### Profile Setup (first launch)

Not built yet. The Godot game has no name step and no character pick, and it asks for no name (#186 covers the first run). The plan below stands, but step 1 clashes with `PRIVACY.md`, which says the game asks for no name. Until that is decided, a callsign is a made-up handle, never a real name.

1. Enter name/callsign
2. Choose character. The character sets the class:

| Character | Class |
|---|---|
| **Tilly Redback** (Female Learner) | **Scout**: streaks and pace |
| **Banjo Brumby** (Male Learner) | **Ranger**: precise typed answers |
| **The cyber-dog** (name and breed from Writer) | **Tinker**: learning from mistakes |

3. Profile saved with the rest of the save

- Switching character in the hub between runs is free. Each character keeps its own skill tree.
- Lines never gender the player, and class tropes stay on branches, not on the player (TONE.md).
- Saved profiles with the old avatar `spark` load as the cyber-dog.

### The cyber-dog
An Australian working dog (kelpie or blue heeler) that Spark rebuilt, which is why the Tinker badge has Spark's blue eye in it. It talks through a scrap-built voice implant. The film *Up* is a reference only: no borrowed names, collar design or catchphrases. It uses the same Tinker mechanics as any other class.

### Character Sprites
3 base characters, each with cosmetic gear slots unlockable via Scrap.
See ART_REQUIREMENTS.md for pixel art specifications.

### SPARK as Companion
SPARK (the robot character) is not a pick. It is the companion of every character, drawn as a small robot floating beside the player on the journey scene and in combat:
- Delivers Hint lifeline content
- Shows worked solutions after questions
- Plays the explainer clips
- Brief flavour dialogue on boss encounters
- Tone: curious, helpful, slightly sarcastic, always believes in you

---

## 11. STATS & DEBRIEF SCREEN

**Legacy design.** The Godot game shows a run summary after each run and, on each topic's screen, accuracy, coverage and the three weakest skills (`game/engine/progress.gd`). The radar, trend panel and WANTED board below are not built in it.

Shown after every Thunderdome run and available from the overworld.

### Spider/Radar Diagram
- 5 axes: one per IB topic
- Toggle: **This Run** vs **Overall** (lifetime accuracy per topic)
- Rendered in canvas using the design token colour system

### Trend Panel
- Shows top 3 most-improved topics across recent runs
- **Hidden if**: fewer than 2 runs completed, or no topic shows improvement
- Positive framing only — never shows regression

### WANTED Board
- List of flagged questions grouped by topic
- Each entry shows: topic tag, difficulty tier, brief question stem
- Grows over time, cleared as bounties are completed
- Always visible regardless of data availability

---

## 12. ART ASSET CHECKLIST

See `ART_REQUIREMENTS.md` for full generation briefs.

**Needed before v1:**
- [ ] 3× character sprites (Tilly Redback, Banjo Brumby, the cyber-dog)
- [ ] SPARK companion sprite (small, floats beside the player)
- [ ] 5× enemy sprites (Scavenger, Raider, Enforcer, Warlord, Overseer/Boss)
- [ ] 3× lifeline icons × 2 states (enabled/disabled) = 6 icons
- [ ] PWA app icon 192×192 and 512×512
- [ ] Overworld map background
- [ ] HP bar frame (player + enemy variants)
- [ ] Question card frame
- [ ] WANTED poster badge

**Nice to have for v1:**
- [ ] Zone thumbnail images × 5 (shown on overworld map)
- [ ] Thunderdome arena background
- [ ] SPARK expression variants (happy, thinking, sarcastic)

---

## 13. CONTENT AUTHORING NOTES

**Legacy:** these notes are for the HTML game's hand-written packs. Godot questions come from recipes; how to add a type is in `game/docs/QUESTION-ENGINE.md` and `curriculum/README.md`.

- All question text written in plain English; LaTeX used only for math expressions
- Math wrapped in `$...$` (inline) or `$$...$$` (display block) — KaTeX renders on load
- Students never see raw LaTeX — numpad generates it invisibly for value-input questions
- Worked solutions should be step-by-step, written as SPARK's dialogue where possible
- Difficulty rating assigned per question using the calibration guide in Section 6.2
- See CONTENT_SCHEMA.md for the exact JS object format

---

## 14. OUT OF SCOPE (V1)

- Multiplayer / class leaderboards
- Teacher dashboard
- Accounts, and cloud save or sync between devices (export and import only, #185; sync later, #202)
- Telemetry, until the owner approves it (#133)

HL and AI content and generated questions were out of scope for v1 and have shipped. Music, sound effects and voiced explainers are in scope: see ROADMAP.md.
