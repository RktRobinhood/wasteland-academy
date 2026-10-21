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
│   └── hp-frame-enemy.png       ← Enemy HP bar frame 320×48
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

### Avatar 1 — Female Learner
- Young woman, late teens
- Dark hair pulled up with goggles resting on forehead
- Worn utility jacket or vest over a hoodie, pink/magenta scarf
- Scavenger pack on back
- Expression: determined and curious
- Crown motif somewhere subtle (patch on jacket, chalk mark)

### Avatar 2 — Male Learner
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
