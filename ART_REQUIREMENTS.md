# WASTELAND ACADEMY — Art Requirements

> Generation briefs for all visual assets.  
> Style: Salvage Neon Bazaar — post-apocalyptic wasteland, dark base, vibrant neon accents.  
> Colour palette: Charcoal #1F2937 bg, Bazaar Magenta #FF3DA7, Scrap Teal #22D3C5, Rust Orange #FAA261, Dust Yellow #EACB74

---

## EXACT FILENAME CONVENTIONS (for the art agent)

The engine references assets by these exact paths. Drop files here with these exact names.

```
assets/
├── icons/
│   ├── icon-192.png          ← PWA app icon 192×192
│   ├── icon-512.png          ← PWA app icon 512×512
│   └── favicon-32.png        ← Browser tab icon 32×32, made from icon-512.png
│
├── avatars/
│   ├── avatar-female.png     ← Female Learner sprite 256×256
│   ├── avatar-male.png       ← Male Learner sprite 256×256
│   ├── avatar-spark.png      ← SPARK robot sprite 256×256
│   ├── spark-happy.png       ← SPARK expression 128×128
│   ├── spark-thinking.png    ← SPARK expression 128×128
│   ├── spark-surprised.png   ← SPARK expression 128×128
│   └── spark-sarcastic.png   ← SPARK expression 128×128
│
├── enemies/
│   ├── d1-scavenger.png      ← D1 enemy 256×256
│   ├── d2-raider.png         ← D2 enemy 256×256
│   ├── d3-enforcer.png       ← D3 mini-boss 256×256
│   ├── d4-warlord.png        ← D4 mini-boss 256×256
│   └── d5-overseer.png       ← D5 boss 256×256
│
├── ui/
│   ├── lifeline-fifty-on.png    ← 50-50 enabled 128×128
│   ├── lifeline-fifty-off.png   ← 50-50 disabled 128×128
│   ├── lifeline-freeze-on.png   ← Freeze enabled 128×128
│   ├── lifeline-freeze-off.png  ← Freeze disabled 128×128
│   ├── lifeline-hint-on.png     ← Hint enabled 128×128
│   ├── lifeline-hint-off.png    ← Hint disabled 128×128
│   ├── wanted-badge.png         ← WANTED poster badge 96×64
│   ├── question-card.png        ← Question card frame 360×400
│   ├── hp-frame-player.png      ← Player HP bar frame 320×48
│   ├── hp-frame-enemy.png       ← Enemy HP bar frame 320×48
│   ├── encounter/               ← Encounter and Field Notes UI, see ENCOUNTER UI below (FAL-359)
│   └── calculator/              ← The in-game calculator's casing and keys (game/assets/ui/), see CALCULATOR UI below (FAL-421)
│
└── map/
    ├── overworld.png                 ← Full world map background 1080×1920
    ├── island-scrap-fields.png       ← Island thumbnail 200×150
    ├── island-signal-tower.png       ← Island thumbnail 200×150
    ├── island-dry-flats.png          ← Island thumbnail 200×150
    ├── island-radio-spires.png       ← Island thumbnail 200×150
    ├── island-engine-core.png        ← Island thumbnail 200×150
    ├── thunderdome.png               ← Thunderdome thumbnail 200×150
    └── arena-bg.png                  ← Thunderdome arena background 1080×600

assets/classes/                            ← Godot game only (the HTML game doesn't use these)
├── class-scout.png                   ← Scout class badge 256×256
├── class-ranger.png                  ← Ranger class badge 256×256
├── class-tinker.png                  ← Tinker class badge 256×256
├── skill-second-look-on.png          ← Second Look ready 128×128
├── skill-second-look-off.png         ← Second Look recharging 128×128
├── skill-overwatch-on.png            ← Overwatch ready 128×128
├── skill-overwatch-off.png           ← Overwatch recharging 128×128
├── skill-scan-on.png                 ← Scan ready 128×128
└── skill-scan-off.png                ← Scan recharging 128×128
```

The engine gracefully degrades if any asset is missing — placeholder CSS fills in until the real art arrives. Priority order for generation: **icons first** (needed for PWA install), then **enemies + avatars** (seen every run), then **map assets**, then **UI chrome**.

---

## STYLE GUIDE SUMMARY

**World tone**: Desolate wasteland with pockets of vibrant, handmade life. Rusted metal, scrap, duct tape, neon tubes, painted signs. Coexistence of decay and hope.

**Character style**: Semi-realistic anime/comic hybrid. Expressive faces. Practical, worn gear. Goggles, scarves, utility belts. Pink/magenta crown motif as a recurring symbol.

**UI style**: Dark panels with visible metal rivets and worn edges. Neon-lit borders. Handwritten-feeling labels. Everything looks like it was built from salvage but works perfectly.

**Reference aesthetic**: The style sheets in this repository (Salvage Neon Bazaar panels) are the primary visual reference.

---

## AVATAR SPRITES

### Spec
- Format: PNG with transparent background
- Size: 256×256px (displayed at 96×96px in-game, higher res for crispness on retina)
- Style: Semi-realistic, slightly stylised, post-apocalyptic scavenger aesthetic
- Consistent lighting direction: top-left light source
- All three avatars must feel like they belong to the same universe/art style

### Avatar 1 — Tilly Redback (Female Learner)
- Young woman, late teens
- Dark hair pulled up with goggles resting on forehead
- Worn utility jacket or vest over a hoodie, pink/magenta scarf
- Scavenger pack on back
- Expression: determined and curious
- Crown motif somewhere subtle (patch on jacket, chalk mark)

### Avatar 2 — Banjo Brumby (Male Learner)
- Young man, late teens
- Short hair, practical cap or bandana
- Similar scavenger aesthetic — patched jacket, worn boots
- Holding something (a tool, a notebook) — resourceful feel
- Expression: focused, ready

### Avatar 3 — SPARK (Robot Companion)
- Small, round, WALL-E-ish robot
- Glowing cyan/teal eyes (expressive — can show emotions)
- Patchwork body — different materials welded together, pink crown graffiti on chest
- Utility arms, antenna
- Expression: curious and cheerful
- This is the character that delivers hints and worked solutions

---

## ENEMY SPRITES

### Spec
- Format: PNG with transparent background
- Size: 256×256px
- Must clearly communicate threat level — D1 looks manageable, D5 looks intimidating
- All enemies are humanoid-ish wasteland figures, not monsters
- Consistent art style across all 5

### D1 — Scavenger (Recruit)
- Scrappy, small, poorly equipped
- Torn clothes, makeshift weapon (a stick with nails)
- Looks nervous. Lowest threat.

### D2 — Raider (Operative)
- More confident, better gear
- Leather scraps, simple armour plates
- Carries a club or crude weapon

### D3 — Enforcer (Sergeant) — MINI-BOSS
- Larger, clearly armoured
- Mismatched plate armour welded together
- Carries something heavier — a modified tool as weapon
- Has a name plate / number on armour

### D4 — Warlord (Commander) — MINI-BOSS
- Imposing, clearly dangerous
- Full scrap armour, glowing details (neon tube accents)
- Commanding pose — this person is in charge of something

### D5 — OVERSEER (Boss)
- The final boss tier
- Massive presence — could be a person in powered armour, or a machine, or both
- Glowing magenta/teal power sources visible through armour
- Name rendered in the Bangers font on a plate on their chest
- Should feel like a genuine end-game encounter

---

## LIFELINE ICONS

### Spec
- Format: PNG with transparent background  
- Size: 128×128px
- Each icon needs TWO states: **Enabled** (full colour, glowing) and **Disabled** (greyscale, dimmed)
- Style: Chunky, icon-like, slightly hand-drawn/imperfect

### 50-50 Icon
- Visual concept: Two crossed-out options, two remaining — like a scrap of paper with choices X'd out
- Active colour: Bazaar Magenta #FF3DA7
- Label underneath: "50-50"

### Time Freeze Icon
- Visual concept: A cracked clock face, frozen, with a neon glow around it
- Active colour: Scrap Teal #22D3C5
- Label underneath: "FREEZE"

### Hint Icon
- Visual concept: SPARK's glowing eye / a lightbulb made from scrap with a neon filament
- Active colour: Dust Yellow #EACB74
- Label underneath: "HINT"

---

## CLASS BADGES AND ACTION SKILL ICONS (Godot game)

Class plan: FAL-291. Made on FAL-307 in the lifeline style. The game draws every name, so no image has text.

### Spec
- Format: PNG with transparent background
- Class badges: 256×256px. Shown large on the class-pick screen and at 48px in the HUD
- Skill icons: 128×128px, two states each like the lifelines: **on** (full colour, glowing) and **off** (greyscale, dimmed, shown while the skill recharges)
- The three classes differ in silhouette, not only colour, so colour-blind students can tell them apart

### Class badges
| File | Class | Colour | Shape |
|---|---|---|---|
| `class-scout.png` | Scout (streaks and pace) | Rust Orange #FAA261 | stacked speed chevrons, an arrowhead |
| `class-ranger.png` | Ranger (precise typed answers) | Scrap Teal #22D3C5 | a round scrap scope reticle |
| `class-tinker.png` | Tinker (learning from mistakes) | Dust Yellow #EACB74 | a wrench crossed with a circuit trace, SPARK's blue eye at the centre |

### Action skill icons
| Files | Skill | Colour | Shape |
|---|---|---|---|
| `skill-second-look-on.png`, `skill-second-look-off.png` | Second Look (Scout): one retry after a wrong answer | Rust Orange | an eye inside a circular back-arrow |
| `skill-overwatch-on.png`, `skill-overwatch-off.png` | Overwatch (Ranger): blocks the damage from one wrong answer | Scrap Teal | a scrap-metal shield with a reticle |
| `skill-scan-on.png`, `skill-scan-off.png` | Scan (Tinker): shows the first step of the solution | Dust Yellow | a scan beam sweeping across a page |

### Icon loops (FAL-323)
Short "ready" loops for the 3 class badges, the 3 skill **on** icons and the 3 lifeline **on** icons. The **off** states stay still. The still PNG is unchanged, and it is the fallback for the calm-motion setting.

- Folders: `assets/classes/anim/<name>/` and `assets/ui/anim/<name>/`, where `<name>` is the still's file name (for example `class-scout`, `lifeline-hint-on`). Each folder has `frames/frame_NN.png`, `sprite_sheet.png` (4 columns, 256-colour PNG with alpha, under 300 KB), `animation.json` (`fps`, `frames`, `loop`, frame size, columns, duration) and `preview.gif` (on the HUD colour #1F2937).
- 16 frames each, seamless: 10 fps (1.6 s) or 8 fps (2.0 s) for Ranger, Overwatch and Freeze.
- Method: light only, made on the CPU from the shipped pixels. Every frame keeps the still's alpha (the silhouette is identical), and only the glow inside the icon moves. sprite-animator (H3 image-to-video) was tried on Scout, Second Look and Hint. It rendered the icon at a quarter to half of its size, drifted from the shipped shape, and can't key the 50-50's magenta.
- Calm at 48 px: nothing flashes (the Hint bulb's flicker is the biggest change, 0.6 swings a second).

| Loop | Motion |
|---|---|
| `class-scout` | a neon pulse runs forward through the chevrons |
| `class-ranger` | the cyan ring breathes |
| `class-tinker` | the blue eye swells and a glint runs along the struts (the wrench doesn't rock: that would redraw its shape) |
| `skill-second-look-on` | light runs once round the arrow ring, and the iris glows |
| `skill-overwatch-on` | the reticle pulses |
| `skill-scan-on` | a scan line of light sweeps down the page, and the beam lights up as it passes |
| `lifeline-fifty-on` | the magenta X marks dip and glow twice |
| `lifeline-freeze-on` | a light "second hand" ticks round the clock face (8 ticks); the weakest at 48 px |
| `lifeline-hint-on` | the bulb flickers on, holds, and fades |

---

## PWA APP ICON

### Spec
- Format: PNG, no transparency (solid background)
- Sizes needed: 192×192px and 512×512px
- Must be recognisable at small sizes

### Design
- Background: Charcoal #1F2937 with subtle texture
- Foreground: The crown motif (pink/magenta) + "WA" or a stylised academy symbol
- Border: Faint rust/metal texture ring
- Should be distinctive on a dark phone home screen

---

## OVERWORLD MAP

### Spec
- Format: PNG or SVG
- Size: 1080×1920px (portrait, fills phone screen)
- This is the background — UI elements overlay it in code

### Design
- Wasteland aerial/top-down view — not photorealistic, more illustrated/painted
- 5 distinct zones visible with clear visual identities:
  - **The Scrap Fields** (NW): Junkyard, rusted metal piles — Numbers & Algebra
  - **The Signal Tower** (NE): Tall antennae, communication dishes — Functions
  - **The Dry Flats** (W): Desert with geometric rock formations, caves — Geometry & Trig
  - **Radio Spires** (E): Data towers, satellite dishes — Stats & Probability
  - **The Engine Core** (S): Industrial, machinery, gears — Calculus
  - **The Thunderdome** (Centre): Arena structure, neon-lit, clearly the hub
- Paths between zones (dotted lines, showing travel routes)
- Locked zones should visually appear dimmer / hazier
- Cleared zones should show a small crown or neon "CLEARED" marker

---

## HP BAR FRAMES

### Spec
- Format: PNG with transparency
- Two variants: **Player HP** (teal) and **Enemy HP** (magenta)
- Size: 320×48px
- Style: Industrial gauge frame — riveted metal casing with a clear "window" where the fill bar shows

### Player HP Bar
- Frame colour: Dark metal with teal accents
- Fill colour: Scrap Teal #22D3C5
- Depletes left to right as HP falls

### Enemy HP Bar
- Frame colour: Dark metal with magenta accents
- Fill colour: Bazaar Magenta #FF3DA7
- Depletes right to left as enemy takes damage

---

## QUESTION CARD FRAME

### Spec
- Format: PNG with transparency (frame only — content rendered in HTML inside)
- Size: 360×400px (frame that wraps the question text area)
- Style: Notice board / wanted poster aesthetic — worn paper or metal sheet inside a riveted frame
- Subtle scanline or paper texture inside
- Corner details: screw holes, tape patches, warning stripe border top

---

## WANTED POSTER BADGE

### Spec
- Format: PNG with transparency
- Size: 96×64px
- Style: Classic "WANTED" poster aesthetic, worn and aged, in the Salvage Neon Bazaar style
- Text: "WANTED" in a distressed serif font
- Colour: Rust Orange #FAA261 background, dark text
- Used as a small badge overlaid on flagged question cards and in the stats WANTED Board

---

## ENCOUNTER UI (FAL-359)

### Spec
- Folder: `assets/ui/encounter/`. PNG with transparency, no words in any image: code draws all text.
- `ui.json`: `images` gives each image's `width` and `height`; `nine_slice` gives each stretchable image its margins (`left`, `top`, `right`, `bottom`, in native px).
- Nine-slice: keep the corners fixed and stretch only the edges and centre. The unknown card is nine-sliced too, so its corners survive.
- The bubble tail is a separate image, placed over the speaker.
- Calm rule: no animated UI while a question is open.

| Files | Native size | Nine-slice L/T/R/B |
|---|---|---|
| bubble.png, bubble-spark.png | 96×64 | 12/12/12/12 |
| bubble-tail.png | 24×20 | none |
| stakes-chip.png | 64×24 | 10/8/10/8 |
| pip-on.png, pip-off.png | 24×24 | none |
| kind-meet.png, kind-deal.png, kind-standoff.png | 64×64 | none |
| field-notes-panel.png | 256×256 | 30/40/16/40 |
| field-note-card.png, field-note-unknown.png | 160×64 | 12/12/12/12 |
| dialogue-box.png | 192×96 | 14/14/14/14 |

Where it came from: local ComfyUI Qwen Image 2.1 int8 (text-to-image, 512², 25 steps Euler/simple, CFG 1, seed 35901) for the paper and metal textures and the three badge silhouettes. Pillow combined the textures with fixed frame geometry (frames, rivets, tails, pips) and resized the badges. Workflow, prompts and validation are on FAL-359.

---

## CALCULATOR UI (FAL-421)

### Spec
- Folder: `game/assets/ui/calculator/` (the Godot game). The sizes, file names and nine-slice margins are in `game/README.md`, "Calculator art"; the game draws all text on top.
- Every file is a nine-slice: rims, rivets and wear stay inside the margin, middles are plain.
- Colours: casing neon Scrap Teal #22D3C5, crown Bazaar Magenta #FF3DA7, screen face Charcoal #1F2937, digit keys worn off-white, function keys Rust Orange #FAA261, mode switch and EXE Bazaar Magenta #FF3DA7. Pressed keys sit lower and glow Scrap Teal.

| Files | Native size | Nine-slice margin |
|---|---|---|
| casing.webp | 1040×1800 | 72 |
| screen.png | 512×512 | 28 |
| key.png, key-pressed.png, key-fn.png, key-fn-pressed.png, key-mode.png, key-mode-pressed.png | 128×112 | 20 |

Where it came from: original work. Local ComfyUI Qwen Image 2.1 int8 (text-to-image, 1024², 25 steps Euler/simple, CFG 1) made two flat textures: the casing's gunmetal (seed 42101) and the keys' worn paint grain (seed 42101). Pillow and NumPy drew everything else over them from fixed geometry: the casing outline, bevel, chipped edges, rust, rivets, neon tube, maker's badge and crown, the screen bezel, and every key. Prompts, build script and checks are on FAL-421.

---

## ISLAND THUMBNAIL IMAGES (Nice to have)

### Spec
- Format: PNG
- Size: 200×150px each
- 5 images, one per island, showing a distinctive environmental scene
- Used as thumbnail cards on the overworld map overlay

| Island | Scene concept |
|--------|---------------|
| The Scrap Fields | Piles of rusted metal with math symbols scratched into them |
| The Signal Tower | Tall antenna tower at sunset with equation trails in the air |
| The Dry Flats | Geometric rock arch with triangle/angle carvings |
| Radio Spires | Data towers with graphs and charts on screens |
| The Engine Core | Massive gears and pistons with integral/derivative symbols |

---

## THUNDERDOME ARENA BACKGROUND

### Spec
- Format: PNG
- Size: 1080×600px (landscape banner used as combat scene backdrop)
- Style: Inside a ruined arena — crowd barriers, neon signs, battle-worn floor
- Central neon text: "THUNDERDOME" in Bangers style
- Atmospheric — bright neon against dark wasteland backdrop

---

## SPARK EXPRESSION VARIANTS

### Spec
- Format: PNG with transparency
- Size: 128×128px each
- 4 variants of SPARK's face/upper body showing different emotional states

| Variant | When used |
|---------|-----------|
| **Happy** | Correct answer, success state |
| **Thinking** | Hint being delivered, worked solution |
| **Surprised** | Boss encounter, big damage |
| **Sarcastic** | Wrong answer (gentle tease) |
