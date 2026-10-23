# WASTELAND ACADEMY — Full Project Specification

> IB Math AA SL Gamified Review Tool  
> Status: Pre-production | Version: 1.0  
> Target: Static GitHub Pages PWA, mobile-first

---

## 1. CONCEPT

A roguelite math review game for IB Mathematics: Analysis and Approaches SL. Students navigate a post-apocalyptic wasteland overworld (Mario World structure), entering topic islands to battle math enemies and visiting a central **Thunderdome** for configurable exam-prep runs. The aesthetic is **Salvage Neon Bazaar** — dark, gritty wasteland punctuated by vibrant neon. Built as a Progressive Web App so students can install it to their phone home screen and play it like a native game.

**Core philosophy**: Productive struggle + flow state + spaced repetition. The game responds to the student's level, rewards being in the right difficulty zone, and circles back to weak spots with breathing room.

---

## 2. PLATFORM & TECHNICAL STACK

### Hosting
- Static GitHub Pages site (no server, no backend)
- HTTPS provided by GitHub Pages (required for PWA)

### PWA Requirements
- `manifest.json` — app name, icons, theme colour (#1F2937), display: standalone, orientation: portrait-primary
- `service-worker.js` — caches all HTML/CSS/JS/fonts/KaTeX assets on first load; works fully offline after one visit
- App icons: 192×192 and 512×512 PNG (see ART_REQUIREMENTS.md)
- "Add to Home Screen" prompt on first visit

### Tech Stack
- **Vanilla JS (ES Modules)** — no framework, no bundler, no build step
- **CSS Custom Properties** — full design token system, all colours/spacing as variables
- **KaTeX** 0.16.9 (vendored in `vendor/katex/`, precached by Service Worker) — math rendering
- **Fonts**: Bangers (display/headings) + Share Tech Mono (body/UI), from Google Fonts, vendored in `vendor/fonts/` (OFL)
- No CDN and no remote URLs: every file is in the repo, by relative path, so the same files can ship in a store app
- **localStorage**, through `js/platform.js` — all save data, player stats, spaced repetition state. Saves carry a format version and are migrated, never wiped
- Export/Import save as JSON file (manual backup, and moving progress to another device or an app build)

### Module System
Each content file registers itself via a global `WA.registerPack(pack)` call. The engine discovers packs dynamically — no hardcoded imports needed. New topic packs can be added by dropping a JS file in `/content/` and adding a `<script>` tag to `index.html`.

### File Structure
```
/
├── index.html              ← Single entry point
├── manifest.json           ← PWA manifest
├── service-worker.js       ← Offline caching
├── SPEC.md                 ← This file
├── ART_REQUIREMENTS.md     ← Asset generation brief
├── CONTENT_SCHEMA.md       ← Question format reference
│
├── css/
│   ├── tokens.css          ← Design system variables
│   ├── base.css            ← Reset, typography, safe areas
│   ├── screens.css         ← Screen-level layouts
│   ├── combat.css          ← Battle UI components
│   ├── map.css             ← Overworld + island map
│   └── stats.css           ← Stats/debrief screen
│
├── js/
│   ├── engine.js           ← Core game loop, state management
│   ├── router.js           ← Screen navigation
│   ├── combat.js           ← Battle mechanics, damage calc
│   ├── spaced-rep.js       ← Spaced repetition engine
│   ├── stats.js            ← Performance tracking, spider diagram
│   ├── pwa.js              ← Service worker registration, install prompt
│   ├── platform.js         ← The only file touching browser storage, links, files
│   └── katex-render.js     ← Math rendering wrapper
│
├── vendor/                 ← KaTeX + fonts, copied in (vendor/LICENSES.md)
│
├── content/
│   ├── topic-1-algebra.js
│   ├── topic-2-functions.js
│   ├── topic-3-geometry.js
│   ├── topic-4-stats.js
│   └── topic-5-calculus.js
│
└── assets/
    ├── icons/              ← PWA icons (192, 512)
    ├── avatars/            ← Player avatar sprites
    ├── enemies/            ← Enemy sprites per difficulty tier
    ├── ui/                 ← Lifeline icons, HP bar frames, buttons
    └── map/                ← Overworld map, island backgrounds
```

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
A wasteland map showing 5 topic islands + the central Thunderdome.

**Islands** (topic zones):
| Island | Topic | IB Reference |
|--------|-------|-------------|
| The Scrap Fields | Numbers & Algebra | Topic 1 |
| The Signal Tower | Functions | Topic 2 |
| The Dry Flats | Geometry & Trigonometry | Topic 3 |
| Radio Spires | Statistics & Probability | Topic 4 |
| The Engine Core | Calculus | Topic 5 |

**Central Hub**: The Thunderdome — battle arena, always accessible

Island states: **Locked** / **In Progress** / **Cleared** (boss defeated)  
Node states: **Locked** / **Available** / **Complete** / **WANTED** (has flagged questions)

### 4.2 Island Structure (Node Map)
Each island contains 6–10 nodes arranged in a branching path:
- One **main branch** (linear, prerequisite-ordered)
- **Side branches** for alternative/advanced subtopics
- Node types: **Battle** (standard fight) / **Mini-Boss** / **Rest Point** (review worked solutions) / **Boss** (island finale)
- Completing the island boss marks the island **Cleared** on the overworld

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

**Value Input** (clean integer or simple fraction answers)
- Calculator-style numpad: digits 0–9, backspace, decimal, negative, fraction (a/b button)
- LaTeX generated behind the scenes, student never sees it
- 50-50 lifeline disabled
- Time Freeze lifeline available

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
Full IB AA SL curriculum, thin coverage (~3–5 questions per subtopic), expandable over time.
See CONTENT_SCHEMA.md for the question data format.

Topic breakdown follows the course scheme of work:
- **Topic 1**: SL1.1–SL1.8 (Scientific notation, sequences, logs, proof)
- **Topic 2**: SL2.1–SL2.11 (Lines, functions, quadratics, rationals, transformations)
- **Topic 3**: SL3.1–SL3.8 (3D geometry, trig, unit circle, identities)
- **Topic 4**: SL4.1–SL4.6 (Statistics, probability, distributions)
- **Topic 5**: SL5.1–SL5.11 (Differentiation, integration, kinematics)

---

## 7. SPACED REPETITION ENGINE

### Logic
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

Three lifelines per run. Once used, gone for that run. Spent Scrap to refill between runs.

| Lifeline | MCQ | Value Input | Effect |
|----------|-----|-------------|--------|
| **50-50** | ✅ Enabled | ❌ Disabled | Removes 2 incorrect MCQ options |
| **Time Freeze** | ✅ Enabled | ✅ Enabled | Doubles remaining time for this question |
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

### Mastery Gating (Island Mode)
- Island nodes unlock sequentially along the main branch
- Side branch nodes unlock when their prerequisite main-branch node is cleared
- Island boss unlocks only when all main-branch nodes are cleared
- No minimum accuracy required to "pass" a node — students may always retry

---

## 10. PLAYER PROFILE & AVATARS

### Profile Setup (first launch)
1. Enter name/callsign
2. Choose avatar: **Female Learner** / **Male Learner** / **SPARK** (robot)
3. Profile saved to localStorage

### Avatar Sprites
3 base avatars, each with cosmetic gear slots unlockable via Scrap.
See ART_REQUIREMENTS.md for pixel art specifications.

### SPARK as Companion
SPARK (the robot character) appears as the hint-giver throughout the game:
- Delivers Hint lifeline content
- Shows worked solutions after questions
- Brief flavour dialogue on boss encounters
- Tone: curious, helpful, slightly sarcastic, always believes in you

---

## 11. STATS & DEBRIEF SCREEN

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
- [ ] 3× avatar sprites (Female Learner, Male Learner, SPARK)
- [ ] 5× enemy sprites (Scavenger, Raider, Enforcer, Warlord, Overseer/Boss)
- [ ] 3× lifeline icons × 2 states (enabled/disabled) = 6 icons
- [ ] PWA app icon 192×192 and 512×512
- [ ] Overworld map background
- [ ] HP bar frame (player + enemy variants)
- [ ] Question card frame
- [ ] WANTED poster badge

**Nice to have for v1:**
- [ ] Island thumbnail images × 5 (shown on overworld map)
- [ ] Thunderdome arena background
- [ ] SPARK expression variants (happy, thinking, sarcastic)

---

## 13. CONTENT AUTHORING NOTES

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
- HL content
- Procedurally generated questions
- Music and sound effects (local voiced narration with subtitles is planned for L3; see ROADMAP.md)
- Animated sprite movement
- Cloud save / cross-device sync (localStorage only)
