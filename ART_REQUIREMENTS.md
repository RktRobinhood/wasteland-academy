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
│   ├── avatar-dog.png        ← Cyber-dog sprite 256×256
│   ├── spark-companion.png   ← SPARK floating companion, small
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
- Character plan: FAL-939. Each character has its own class (Tilly: Scout, Banjo: Ranger, the dog: Tinker). SPARK is not a pick; it is every character's companion

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

### Avatar 3 — The cyber-dog (Tinker)
- Australian working dog, kelpie or blue heeler (Writer settles name and breed on the character sheet)
- Rebuilt by SPARK: scrap cybernetic parts, a scrap-built voice implant at the throat, and a small blue eye light that matches SPARK's
- Four-legged silhouette, clearly different from the two Learners
- Expression: alert and eager
- The film *Up* is a reference only: no borrowed collar design
- Also needs a side-on journey sheet to match the FAL-208 sheets

### SPARK companion (not a pick)
- Small, round, WALL-E-ish robot
- Glowing cyan/teal eyes (expressive — can show emotions)
- Patchwork body — different materials welded together, pink crown graffiti on chest
- Utility arms, antenna
- Expression: curious and cheerful
- Drawn small, floating beside whichever character the player picks, on the journey scene and in combat
- Delivers hints, worked solutions and explainer clips

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

## MAP AND LEVEL ART FROM CHATGPT: PROMPT CARDS (#201)

Owner decision, 2026-11-16: local image generation isn't good enough for map and level art. That covers the
world map, the zone boards, fight backdrops and journey scenery. Matt makes this art in ChatGPT from prompt
cards that the Artist writes. Character and people art isn't covered by this decision.

**The loop**

1. The Artist writes one prompt card per piece and sends them in batches, in priority order, on one Paperclip
   card (#204). Each batch is also kept in the repo, in `assets/art/prompt-cards/`.
2. Matt runs each prompt in ChatGPT and attaches about five candidates per piece, sometimes with a comment.
   That's the end of his part.
3. The Artist picks one candidate per piece against the checklist below and records why on the task. A
   comment from Matt is a strong preference. If no candidate passes, the Artist replies with a revised
   prompt, not a silent retry.
4. Intake (below): measure, extend, resize, compress, name, and record the provenance and the prompt. Then
   phone and desktop screenshots. One zone is one PR.

Nothing in this loop is painted on the local GPU. The one exception is extending the edge bands at intake
(the FAL-986 method), which adds open ground or sky around Matt's picture and never repaints his pixels.

### The prompt card

A card stands on its own. Matt should be able to run it with nothing else open. Every card has these fields,
in this order:

| Field | What goes in it |
|---|---|
| **Piece and file** | What it is, the zone, and the file it becomes (for example `game/assets/map/calculus/background.webp`) |
| **Priority** | Its place in the batch |
| **Reference images** | What to attach in ChatGPT, by name, each linked on the card. Usually the world map (`game/assets/map/overworld.png`), as the style reference |
| **Size and aspect** | The aspect to pick in ChatGPT, and the size it becomes in the game |
| **The prompt** | The full prompt, ready to paste. It opens with the style words below and ends with the "must not appear" list |
| **Where things sit** | Each landmark's position, and the tap zone it becomes (the spot id). A layout picture for checking, posted on the card |
| **Keep clear** | Areas where nothing may stand: the label and chip space, edge margins and bands |
| **Must not appear** | Text, letters, numbers, symbols, logos, unwanted people, roads, and anything else the piece needs |
| **Fixable later / not fixable** | What the Artist can fix at intake and what needs a new candidate |
| **Candidates wanted** | About five unless the card says otherwise |

**The style words** are the same on every card. They come from `assets/style-guide/` (the tokens in its README)
and from the world map's look:

> a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching
> in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and
> bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes

The cards describe the look in words and don't name another game. The world map, attached as the
reference, carries the look. That keeps a commercial game's name out of the prompt and the record (see the
licence notes under "ChatGPT images in a paid release" below).

**Never attach a layout sketch to ChatGPT.** On FAL-975 a colour-blob layout guide made the model paint every
blob as its own raised disc. The layout picture on a card is for checking candidates. Positions go into the
prompt as words.

### Phone and PC: the square core (#199)

The game must fit a portrait phone (9:16) and a landscape PC window (16:9). A zone board is generated as
**one square picture, the core**, with every place inside it. At intake the core gets plain bands added on
two sides for each orientation:

- **Portrait phone board, 1080 × 1920:** the core at 1080 × 1080, centred, with a band of 420 above (sky
  haze and dust, under the header) and 420 below (open ground and dust).
- **Landscape PC board, 1920 × 1080:** the same core at 1080 × 1080, centred, with a band of 420 open
  ground on the left and on the right.

A place therefore has the same position inside the core in both orientations. Its zone is measured once in
core coordinates and converted to each board. In each orientation the places fill the screen's short side,
and the bands fill the rest.

Why not the other ways:

- **A wide 16:9 canvas with every place in a centre strip that also crops to 9:16.** ChatGPT's wide pictures
  are about 1536 to 2048 px across. A 9:16 strip of one is 576 to 768 px wide, well under the 1080 a phone
  board needs. On PC the places would sit in the middle third of the window.
- **Two paintings per zone, one per orientation.** That doubles Matt's work, and the landmarks would differ
  between the phone and the PC.

**What the core needs from the prompt**

- Square, 1:1.
- Ground fills the whole picture, with no horizon and no sky, so the bands extend it on any side.
- A plain margin of open ground about one-sixteenth of the width on all four edges, with nothing standing
  on it, so the band joins pass through plain ground.
- Places at the nine standard positions below, each about a quarter of the core wide, with open ground
  between them.

| Position | Centre in the core (% x, % y) | Used for |
|---|---|---|
| Centre | 50, 50 | The zone's biggest landmark, its all-regions dungeon (`all`) |
| Top left, top, top right | 20, 20 · 50, 16 · 80, 20 | Regions |
| Left, right | 16, 50 · 84, 50 | Regions |
| Bottom left, bottom right | 20, 80 · 80, 80 | Regions |
| Bottom | 50, 84 | A region, or the small relic shack (`relic`) when the zone has seven regions or fewer |

A tap zone is about 28 % of the core (300 of 1080 board units, `HIT` in `game/ui/map.gd`) round each point.
The Coder sets `SPOTS` from the measured places, and trims any zones that overlap, as on the world map. The
old jetty or buggy at the bottom edge (`LANDING`) isn't painted on the new boards. It was never a button.

**Keep clear on every board**

- The foot of each place, the bottom 20 % of its patch: plain ground. The game draws the padlock or flag chip
  there.
- The open ground between places: the place card opens beside the place it names, over the painting.
- The edge margin, as above.
- No names, banners or signs on the board. The game shows each name on its card.

**Fight backdrops** stay 1920 × 1080 (16:9). A phone held upright shows about the centre 500 px, so the
landmark sits in the centre 600 px (x 660 to 1260), and the lower 40 % is plain dark ground for the question
text. The rest of the rules are in `game/assets/regions/README.md`.

**The world map** has a portrait original, which shipped in PR #180. The landscape version for PC is a
separate wide card (16:9), with the same eight places in the same order. Matt makes it in the same ChatGPT
chat.

### Size budget (#183)

Every piece is shipped as opaque lossy WebP. These are the most each file may weigh. The Artist measures each
file at intake and records its size in the PR.

| Piece | File | Most it may weigh |
|---|---|---|
| Zone board, portrait | `game/assets/map/<zone>/background.webp`, 1080 × 1920 | 300 KB |
| Zone board, landscape | `game/assets/map/<zone>/background-wide.webp`, 1920 × 1080 | 300 KB |
| B layer: the empty board (clean plate) | `game/assets/map/<zone>/plate.webp` and `plate-wide.webp` | 250 KB each |
| B layer: one landmark cut-out | `game/assets/map/<zone>/<spot>.webp`, transparent, cropped to the landmark | 60 KB |
| Fight backdrop | `game/assets/regions/<region>/backdrop.webp`, 1920 × 1080 | 150 KB |
| World map, each orientation | `game/assets/map/overworld.webp`, `overworld-wide.webp` | 600 KB |

All map and level art together stays under 8 MB. Today it's 3 MB: `game/assets/map` and
`game/assets/regions` measure 1.5 MB each. If #183's budget for the whole pack ends up tighter, the
backdrops go to WebP quality 80 first. The world map on `main` is a 1.2 MB PNG, and moving it to WebP is
part of its landscape intake.

### The selection checklist

The Artist checks every candidate against this list and records the result on the task. A candidate passes
when every **must** holds. Among the ones that pass, Matt's comment decides first, then the **should** lines.

**Every piece, must**

1. **Style match.** Next to the world map at the same size, it reads as the same artist: ink outlines, cel
   shading, hatching, the palette, the hard sun. Shown side by side on the task.
2. **No stray text.** No letters, numbers, symbols, logos or sign writing, checked at 1:1. A stray mark that a
   small blur clears can be fixed at intake. Lettering that matters can't.
3. **No unwanted figures.** No people, animals or vehicles except the ones the card names.
4. **No roads or links.** No roads, paths, rails, bridges, channels or tracks join two places.

**Zone boards and the world map, must**

5. **Every place is there and reads as its maths.** Each place on the card is present and shows its idea
   without a name: the crate rows double, the dam floods only under the curve, and so on. A wrong count can be
   fixed at intake (crate rows, cube columns). A missing place, or one that doesn't show its maths, can't.
6. **Positions.** Each place's centre is within about 8 % of the core of its position on the card, and no two
   places' patches merge.
7. **Edges extend.** The margin on all four sides is plain ground with nothing cut off, so the bands can be
   added in both orientations.
8. **Legible at phone size.** On a mockup at 270 × 480 (a portrait phone) with the header, chips and a place
   card drawn on, each place is recognisable and the chip at its foot stays readable. The same mockup at
   960 × 540 for PC. Posted on the task.

**Fight backdrops, must**

5. **Landmark in the centre 600 px** of the 1920 × 1080 frame, and still recognisable in the centre 500 px.
6. **The lower 40 % is plain dark ground.**
7. **Dark enough for text.** Mean luma about 25 % at most. White text at its worst point keeps 4.5:1 after the
   game's 55 % wash, on phone and PC, measured with the FAL-474 script. Highlights can be rolled off at
   intake if they're small.
8. **The same place as on its board**, at ground level: the same structure, colours and ground.

**Should**

- Clean shapes that cut out well, where the piece is used for technique B (see below).
- Whatever Matt said in his comment.
- Fewer intake fixes.
- A smaller file at the same quality.

If no candidate passes, the reply on the card names the failed line for each candidate and gives a revised
prompt. Only the lines that change are marked.

### Intake

For each chosen piece, in the zone's PR:

1. **Keep the original.** Store Matt's file unchanged in `_scratch/<task>/source/`, with its SHA-256.
2. **Board: scale and extend.** Scale the core to 1080 × 1080 with LANCZOS, then add the bands for each
   orientation the FAL-986 way: outpaint only the band with a 24 px overlap, paste back only the band, and
   feather the overlap. Prove with a diff that no source pixel changed outside the 24 px joins.
3. **Measure the places** into `zones.json` in the FAL-986 format: `[centre x, centre y, width, height]` per
   spot and `pin = [x, y]`, in % of the core, with the portrait and landscape board versions beside them. The
   Coder sets `SPOTS` from this file.
4. **Backdrop:** crop or scale to 1920 × 1080, and measure luma and contrast with the FAL-474 script.
5. **Compress** to WebP, inside the size budget. Name the file as the size budget table shows.
6. **Record the provenance.** Add a line in `assets/art/CREDITS.md` for each file: the card id and the hash of
   its prompt, the candidate number, "Generated by Matt Prokock with ChatGPT", the date, every edit, and the
   SHA-256.
7. **Screenshots.** The piece in the game at phone size (portrait) and desktop size (landscape), posted on the
   task and the PR.

### Making it feel alive: A or B

Matt wants the maps to feel alive (#201). One zone, the Engine Core, gets both treatments, side by side. The
Artist then chooses, from the measurements, and records the result here.

- **A. A still painting plus engine effects:** dust layers drifting at the edges, cloud shadows, smoke
  particles from the stacks, and masked glows and lava with a churn shader. All of it stops with
  `reduced_motion()`. The plan is the FAL-981 research ([animation-research](/FAL/issues/FAL-981#document-animation-research)).
- **B. A layered painting:** the empty board (a clean plate, made by Matt in ChatGPT as an edit of the chosen
  board) under a cut-out of each landmark, so a landmark can be lit, animated or nudged on its own. The Artist
  cuts the landmarks from the chosen board itself, so they match it exactly.
- **C (a looping GIF or video)** is ruled out: ChatGPT GIFs have 4 to 16 frames and 256 colours, the
  landmarks drift between frames, and Godot can't play GIFs (FAL-981).

The comparison records each technique's file size, its frame time on a phone (the Coder's measurement), and
screenshots, and is posted on the task.

**Result:** not yet run. It waits on the Engine Core candidates.

### ChatGPT images in a paid release (#199)

Recorded 2026-11-16. The full note is in `assets/art/CREDITS.md`. In short, OpenAI's Terms of Use assign the
output to the user and allow commercial use, so nothing found blocks a paid release. There are two caveats.
Purely generated images get little or no copyright protection, so someone could copy the art. And Steam
asks for a disclosure of AI-generated content that players see.

---

## OVERWORLD MAP

> **Superseded for the art itself.** The world map is Matt's ChatGPT painting, shipped in PR #180 (FAL-986, FAL-988), with no routes between places. New map and level art follows "MAP AND LEVEL ART FROM CHATGPT" above. The original brief is kept below for its zone list.

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
