# Journey strip assets (FAL-293, FAL-208)

The side-view journey strip above the question card: the party walks right through a parallax region, and each
answer plays out as a beat (battle, obstacle, treasure). Art only gives poses. Code draws every movement and
effect (tweens, lunges, slashes, impacts, zaps, sparkles, damage numbers, beams), as in the FAL-218 spec. The Godot
strip that draws them is FAL-331.

Folders: `party/` (the Learners and Spark), `enemies/` (the D1-D5 ranks, which appear on every island),
`weapons/`, and one folder per island for its own creatures, obstacles, treasure and parallax (`signal-tower/`).

## How to draw a sheet

Each character or object is one atlas (`<name>.webp`, lossy WebP with alpha) plus `<name>.json`:

- `frames[i]`: `x, y, w, h` is the frame's rectangle in the atlas. `ox, oy` is the top-left of that rectangle
  relative to the **feet point** (the ground contact, x centred). Draw a frame at `feet + (ox, oy)`, so every frame of
  a sheet stands on the same point and nothing jumps when frames swap.
- `figure_height`: shipped px height of the idle frame. Scale a sheet by `display height / figure_height`.
- `anims`: `{name: {frames: [frame index, ...], fps, loop}}`.
- `facing`: the party faces `right`, enemies face `left`, objects `none`.
- `stages` (bosses only): one entry per boss stage, `{idle, attack}`, naming the anims to play in that stage.

**Weapon slot (the Learner).** Frames that hold a weapon have `hand: {x, y, angle}` (relative to the feet, shipped
px; `angle` in degrees clockwise from +x with y down, the direction the weapon tip points) and `overlay`: the fist,
cut from the same pixels. Draw order: body frame, then the weapon PNG rotated by `angle` about its grip with the grip
on `hand`, then the overlay, so the handle passes into the fist. Weapons (`weapons/<name>.png` + `.json`) are drawn
horizontal, grip on the left, tip to the right; `grip` is the pixel the fist closes on. A weapon swap never redraws
the avatar. During the attack, code tweens `angle` (the reel swings it 290° to 400°).

**Parallax** (`signal-tower/layers.json`). Every layer tiles left to right with no seam (its two ends were
crossfaded). `scroll` is the layer's speed as a fraction of the ground speed. `far` is opaque (sky and skyline),
`mid` and `near` have alpha. `near.feet_y` is the row of `near` the characters stand on. The ground speed that matches
the walk cycle with no foot slide: the planted boot moves 36 px per walk frame on an 880 px figure, so
`speed = 36 / 880 × display figure height × walk fps` (45 px/s for a 92 px Learner at 12 fps).

**Calm rule.** While a question is open, play only idle loops (code breathing, scale 1 to 1.02 over 2.4 s). The beat
plays after the answer. Hits use at most one 80 ms white flash, so never more than 3 flashes a second. With reduced
motion, swap poses only and stop the scroll.

**Enemies and bosses** (`enemies/`). Every rank has `idle`, `walk` (the walk-in: step-a, step-b, step-c, idle),
`attack`, `hurt` and `defeated`. The mini-bosses D3 and D4 have 2 stages and the Overseer D5 has 3 (FAL-218 spec). A
later stage is a stage-look frame (`s2`, `s3`) with its own attack frame, listed in `stages`:

| Sheet | Stage 1 | Stage 2 | Stage 3 |
|---|---|---|---|
| `d3-enforcer` | `idle`, `attack` (wrench slam) | `s2-idle` (enraged: cracked visor, glowing seams), `s2-attack` (shoulder charge) | – |
| `d4-warlord` | `idle`, `attack` (command strike) | `s2-idle` (enraged: neon tubes flaring), `s2-attack` (neon-tube whip) | – |
| `d5-overseer` | `idle`, `attack` (iron fist) | `s2-idle` (Breached: plates torn off, core exposed), `s2-attack` (core aimed forward) | `s3-idle` (Overdrive: stripped to the frame, core blazing), `s3-attack` (arms flung wide) |

Bosses walk in only in stage 1. `hurt` is drawn in the stage 1 look: in a later stage, play hurt as the shake and
flash on the current stage image so the damage never seems to undo itself. `defeated` is drawn in the last stage
look (the enraged look for D3 and D4, Overdrive for D5). Stage change: flash white, shake, and swap to the next
stage's idle at the flash peak. Stage looks are in-place edits of the idle, so the swap does not move the figure.

**Strip heights.** The previews on FAL-208 draw the enemies at D1's scale: D1 80 px, D2 92, D3 104, D4 108,
D5 124 (the Learner is 92). Each sheet ships at about the same pixel height (`figure_height`), so set the display
height per sheet.

**Signal Tower cache** (`signal-tower/cache-vending`): `closed`, `open` (treasure), `empty` (broken open, nothing
inside, the neon dead) and `mimic` (the machine turns on you; code does its lunge). All four stand on one feet point.

## Files

| File | Frames (w×h shipped px) | Anims (fps) | Anchors | Bytes |
|---|---|---|---|---|
| `enemies/d1-scavenger.webp` + `d1-scavenger.json` | idle 143×230, step-a 161×225, step-b 144×229, step-c 155×228, attack 212×229, hurt 126×222, defeated 161×223 | idle [idle] (1), walk [step-a, step-b, step-c, idle] (8), attack [attack] (1, once), hurt [hurt] (1, once), defeated [defeated] (1, once) | feet point | 113,653 |
| `enemies/d2-raider.webp` + `d2-raider.json` | idle 130×244, step-a 141×241, step-b 131×245, step-c 131×242, attack 276×251, hurt 151×221, defeated 228×182 | idle [idle] (1), walk [step-a, step-b, step-c, idle] (8), attack [attack] (1, once), hurt [hurt] (1, once), defeated [defeated] (1, once) | feet point | 105,533 |
| `enemies/d3-enforcer.webp` + `d3-enforcer.json` | idle 174×240, step-a 180×238, step-b 174×239, step-c 176×239, attack 178×273, hurt 221×229, s2 174×239, s2-attack 166×223, defeated 198×210 | idle [idle] (1), walk [step-a, step-b, step-c, idle] (8), attack [attack] (1, once), hurt [hurt] (1, once), defeated [defeated] (1, once), s2-idle [s2] (1), s2-attack [s2-attack] (1, once) | feet point | 151,218 |
| `enemies/d4-warlord.webp` + `d4-warlord.json` | idle 202×241, step-a 202×240, step-b 202×235, step-c 202×241, attack 223×247, hurt 224×237, s2 202×241, s2-attack 243×221, defeated 241×169 | idle [idle] (1), walk [step-a, step-b, step-c, idle] (8), attack [attack] (1, once), hurt [hurt] (1, once), defeated [defeated] (1, once), s2-idle [s2] (1), s2-attack [s2-attack] (1, once) | feet point | 160,467 |
| `enemies/d5-overseer.webp` + `d5-overseer.json` | idle 175×236, step-a 193×239, step-b 205×238, step-c 176×238, attack 230×228, hurt 193×235, s2 169×227, s2-attack 212×235, s3 167×226, s3-attack 218×225, defeated 209×197 | idle [idle] (1), walk [step-a, step-b, step-c, idle] (8), attack [attack] (1, once), hurt [hurt] (1, once), defeated [defeated] (1, once), s2-idle [s2] (1), s2-attack [s2-attack] (1, once), s3-idle [s3] (1), s3-attack [s3-attack] (1, once) | feet point | 192,915 |
| `party/learner-female.webp` + `learner-female.json` | walk1 107×215, walk2 81×220, walk3 65×220, walk4 105×216, walk5 81×220, walk6 75×220, idle 62×220, windup 107×230, strike 175×209, hurt 98×219, victory 73×232, defeated 149×188 | walk [walk1, walk2, walk3, walk4, walk5, walk6] (12), idle [idle] (1), attack [windup, windup, strike, strike, strike] (10, once), hurt [hurt, hurt, hurt] (8, once), victory [victory] (1, once), defeated [defeated] (1, once) | hand: walk1 (8.2, -94.5, 55°); walk2 (8.2, -98.5, 58°); walk3 (8.2, -99.5, 55°); walk4 (8.2, -95.5, 52°); walk5 (8.2, -98.5, 55°); walk6 (8.2, -99.5, 58°); idle (8.2, -99.5, 55°); windup (5.8, -223.0, 165°); strike (94.5, -154.3, 40°); hurt (-4.0, -105.5, 75°); victory (25.0, -225.0, 280°) | 125,897 |
| `party/learner-male.webp` + `learner-male.json` | walk1 125×219, walk2 85×221, walk3 73×222, walk4 125×220, walk5 79×222, walk6 73×221, idle 66×220, windup 116×232, strike 179×218, hurt 113×215, victory 95×252, defeated 103×149 | walk [walk1, walk2, walk3, walk4, walk5, walk6] (12), idle [idle] (1), attack [windup, windup, strike, strike, strike] (10, once), hurt [hurt, hurt, hurt] (8, once), victory [victory] (1, once), defeated [defeated] (1, once) | hand: walk1 (-4.0, -98.0, 55°); walk2 (-4.0, -99.5, 58°); walk3 (-4.0, -100.0, 55°); walk4 (-4.0, -98.5, 52°); walk5 (-4.0, -100.0, 55°); walk6 (-4.0, -100.0, 58°); idle (-4.0, -100.0, 55°); windup (23.2, -223.5, 165°); strike (92.2, -154.0, 40°); hurt (-64.5, -119.3, 75°); victory (-8.6, -244.4, 280°) | 118,716 |
| `party/spark.webp` + `spark.json` | idle 128×225, zap 202×211, hurt 189×185, happy 157×212 | idle [idle] (1), attack [zap] (1, once), hurt [hurt] (1, once), victory [happy] (1, once) | feet point | 66,292 |
| `signal-tower/cache-vending.webp` + `cache-vending.json` | closed 117×233, open 147×233, empty 137×233, mimic 127×232 | – | feet point | 59,376 |
| `signal-tower/dishback.webp` + `dishback.json` | idle 228×194, step-a 229×191, step-b 209×195, attack 259×181, hurt 243×183, defeated 239×163 | idle [idle] (1), walk [step-a, idle, step-b, idle] (10), attack [attack] (1, once), hurt [hurt] (1, once), defeated [defeated] (1, once) | feet point | 130,182 |
| `signal-tower/far.webp` | layer 864×256, tiles | – | scroll 0.15 | 20,152 |
| `signal-tower/mid.webp` | layer 864×256, tiles | – | scroll 0.45 | 139,014 |
| `signal-tower/near.webp` | layer 896×98, tiles | – | scroll 1.0, feet row 15 | 33,236 |
| `signal-tower/layers.json` | the layer list | – | – | 314 |
| `signal-tower/loot.webp` + `loot.json` | bolt 50×50, cell 34×50, gear 50×45, crystal 34×47, tube 28×48, cap 41×31 | – | feet point | 10,939 |
| `signal-tower/obstacle-livewire.webp` + `obstacle-livewire.json` | armed 241×149, cleared 241×149 | – | feet point | 31,676 |
| `weapons/antenna-spear.png` + `antenna-spear.json` | weapon 106×31 | – | grip (15, 20) | 3,979 |
| `weapons/neon-blade.png` + `neon-blade.json` | weapon 112×26 | – | grip (8, 12) | 4,547 |
| `weapons/rebar.png` + `rebar.json` | weapon 104×9 | – | grip (10, 4) | 2,641 |

Total: 1,470,747 bytes (1.40 MB) of the 4 MB budget.

## Where it came from

All local (ComfyUI, Qwen Image 2.1 int8). The characters are FAL-206 reference-locked edits of the merged FAL-200
masters, drawn side-on. The new region art (Dishback, live wire, vending cache, weapons, loot, parallax) is
text-to-image in the same painted Salvage Neon Bazaar style. The walk is 6 key frames: the anchor plus "change only
the legs and feet" edits, as on FAL-279. Method, rounds, render count and the technique test are on FAL-293.

FAL-208 added the Male Learner, D2-D5 with the boss stages (stage looks are in-place edits of the side idle, so a
stage change only changes the armour), and the cache `empty` and `mimic` states. It moved D1 from `signal-tower/` to
`enemies/`, shortened the antenna spear's shaft by 22 px so its tip clears the road in every walk, idle and hurt
frame of both Learners (grip unchanged, so no hand data changed), re-placed the Dishback's step-b, attack, hurt and
defeated frames on its shell (each was 8-38 px off the idle; now within 2.2 px, and within 2 px in size), and put
the cache's `open` frame on the same feet point as `closed` (it sat 14 px to the right). Method, rounds and render
count are on FAL-208.
