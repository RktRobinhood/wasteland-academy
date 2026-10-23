# Journey strip assets (FAL-293)

The side-view journey strip above the question card: the party walks right through a parallax region, and each
answer plays out as a beat (battle, obstacle, treasure). Art only gives poses. Code draws every movement and
effect (tweens, lunges, slashes, impacts, zaps, sparkles, damage numbers), as in the FAL-218 spec. Not wired into
the game yet: the Godot `JourneyStage` scene comes after Matt sees the reel (FAL-289 phase 3).

## How to draw a sheet

Each character or object is one atlas (`<name>.webp`, lossy WebP with alpha) plus `<name>.json`:

- `frames[i]`: `x, y, w, h` is the frame's rectangle in the atlas. `ox, oy` is the top-left of that rectangle
  relative to the **feet point** (the ground contact, x centred). Draw a frame at `feet + (ox, oy)`, so every frame of
  a sheet stands on the same point and nothing jumps when frames swap.
- `figure_height`: shipped px height of the idle frame. Scale a sheet by `display height / figure_height`.
- `anims`: `{name: {frames: [frame index, ...], fps, loop}}`.
- `facing`: the party faces `right`, enemies face `left`, objects `none`.

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

## Files

| File | Frames (w×h shipped px) | Anims (fps) | Anchors | Bytes |
|---|---|---|---|---|
| `party/learner-female.webp` + `learner-female.json` | walk1 107×215, walk2 81×220, walk3 65×220, walk4 105×216, walk5 81×220, walk6 75×220, idle 62×220, windup 107×230, strike 175×209, hurt 98×219, victory 73×232, defeated 149×188 | walk [walk1, walk2, walk3, walk4, walk5, walk6] (12), idle [idle] (1), attack [windup, windup, strike, strike, strike] (10, once), hurt [hurt, hurt, hurt] (8, once), victory [victory] (1, once), defeated [defeated] (1, once) | hand: walk1 (8.2, -94.5, 55°); walk2 (8.2, -98.5, 58°); walk3 (8.2, -99.5, 55°); walk4 (8.2, -95.5, 52°); walk5 (8.2, -98.5, 55°); walk6 (8.2, -99.5, 58°); idle (8.2, -99.5, 55°); windup (5.8, -223.0, 165°); strike (94.5, -154.3, 40°); hurt (-4.0, -105.5, 75°); victory (25.0, -225.0, 280°) | 125,897 |
| `party/spark.webp` + `spark.json` | idle 128×225, zap 202×211, hurt 189×185, happy 157×212 | idle [idle] (1), attack [zap] (1, once), hurt [hurt] (1, once), victory [happy] (1, once) | feet point | 66,292 |
| `signal-tower/cache-vending.webp` + `cache-vending.json` | closed 117×233, open 147×233 | – | feet point | 29,844 |
| `signal-tower/d1-scavenger.webp` + `d1-scavenger.json` | idle 143×230, step-a 161×225, step-b 144×229, step-c 155×228, attack 212×229, hurt 126×222, defeated 161×223 | idle [idle] (1), walk [step-a, step-b, step-c, idle] (8), attack [attack] (1, once), hurt [hurt] (1, once), defeated [defeated] (1, once) | feet point | 113,653 |
| `signal-tower/dishback.webp` + `dishback.json` | idle 227×192, step-a 227×191, step-b 210×193, attack 266×186, hurt 253×190, defeated 239×163 | idle [idle] (1), walk [step-a, idle, step-b, idle] (10), attack [attack] (1, once), hurt [hurt] (1, once), defeated [defeated] (1, once) | feet point | 132,810 |
| `signal-tower/far.webp` | layer 864×256, tiles | – | scroll 0.15 | 20,152 |
| `signal-tower/mid.webp` | layer 864×256, tiles | – | scroll 0.45 | 139,014 |
| `signal-tower/near.webp` | layer 896×98, tiles | – | scroll 1.0, feet row 15 | 33,236 |
| `signal-tower/layers.json` | the layer list | – | – | 314 |
| `signal-tower/loot.webp` + `loot.json` | bolt 50×50, cell 34×50, gear 50×45, crystal 34×47, tube 28×48, cap 41×31 | – | feet point | 10,939 |
| `signal-tower/obstacle-livewire.webp` + `obstacle-livewire.json` | armed 241×149, cleared 241×149 | – | feet point | 31,676 |
| `weapons/antenna-spear.png` + `antenna-spear.json` | weapon 128×31 | – | grip (15, 20) | 4,167 |
| `weapons/neon-blade.png` + `neon-blade.json` | weapon 112×26 | – | grip (8, 12) | 4,547 |
| `weapons/rebar.png` + `rebar.json` | weapon 104×9 | – | grip (10, 4) | 2,641 |

Total: 715,182 bytes (0.68 MB) of the 4 MB budget.

## Where it came from

All local (ComfyUI, Qwen Image 2.1 int8). The characters are FAL-206 reference-locked edits of the merged FAL-200
masters, drawn side-on. The new region art (Dishback, live wire, vending cache, weapons, loot, parallax) is
text-to-image in the same painted Salvage Neon Bazaar style. The walk is 6 key frames: the anchor plus "change only
the legs and feet" edits, as on FAL-279. Method, rounds, render count and the technique test are on FAL-293.
