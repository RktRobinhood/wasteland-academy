# Region art

Art for each region of the Functions island, loaded by file name (`engine/art_slots.gd`; the contract is the
"Art slots" section of `game/README.md`). Every file is optional.

## Fight backdrops

One per region, plus `all` for the all-regions dungeon, behind the fight screen and its floor select. All are
1920×1080, opaque, lossy WebP (quality 90). The game cover-fits each one under a 55% wash of the background
colour. A phone held upright shows about the centre 500 px, so each region's landmark sits in the centre 600 px
(x 660 to 1260). The lower 40% is plain dark ground. There is no text, numeral or character in any of them.

| File | Place | Bytes | Mean luma | Spread (sd) | Lower 40% mean | White text, worst point, phone | White text, worst point, PC |
|---|---|---|---|---|---|---|---|
| `quadratics/backdrop.webp` | Shell-crater yard, arched ramps | 135,682 | 11.7% | 4.8% | 9.3% | 10.8:1 | 10.4:1 |
| `exp-log/backdrop.webp` | Drowned vault district, spiral pipe | 108,386 | 11.3% | 6.8% | 7.0% | 8.6:1 | 9.3:1 |
| `graphs-features/backdrop.webp` | Surveyor's flat, empty plotting frames | 74,156 | 13.0% | 5.3% | 9.1% | 8.2:1 | 8.7:1 |
| `composite-inverse/backdrop.webp` | Mirrored rail yards, magenta and teal | 107,250 | 9.6% | 5.4% | 6.8% | 11.2:1 | 8.3:1 |
| `rational/backdrop.webp` | Ration depot, one gap in the wall | 70,406 | 10.1% | 4.0% | 10.6% | 9.8:1 | 10.2:1 |
| `function-basics/backdrop.webp` | Switching yard, wall of sockets | 73,086 | 7.0% | 3.8% | 6.0% | 7.1:1 | 9.1:1 |
| `lines/backdrop.webp` | Salt plain, road and rail to the vanishing point | 44,966 | 13.1% | 7.2% | 6.5% | 9.4:1 | 9.4:1 |
| `transformations/backdrop.webp` | Tailor's market, plain hanging cloth | 93,516 | 9.6% | 3.8% | 8.0% | 9.6:1 | 10.1:1 |
| `all/backdrop.webp` | The foot of the Signal Tower | 69,938 | 9.2% | 4.6% | 5.6% | 10.0:1 | 9.9:1 |

Batch total: 777,386 bytes.

How these were measured (a Pillow script run on the files above; it and the review panels are on FAL-474):

- **Luma** is Rec.709 luma of the sRGB values, 0 to 100%. The brief's limit is a mean of about 25% with a small
  spread.
- **White text, worst point.** The fight screen has no card panel, so question text sits straight on the washed
  backdrop from about 30% of the height down. This is the WCAG contrast of the game's text colour against the
  brightest 0.1% of that zone after the 55% wash. Phone means the centre 600 px; PC means the full width. WCAG AA
  needs 4.5:1.

## Where it came from

Everything was rendered locally in ComfyUI with Qwen Image 2.1 (int8, `qwen21_t2i_opaque`): 1696×960, 25 steps,
euler/simple, cfg 1. Pillow then scaled each pick to 1920×1080 (LANCZOS) and encoded it. Two rounds were used: 24
renders in round 1 (8 regions × 3 seeds), and 15 in round 2, which re-rendered only the regions round 1 didn't
settle and added `all`. Method, counters and review notes are on FAL-474 and FAL-521.

The finish matches the Signal Tower parallax layers (`assets/journey/signal-tower/`) and the Cell backdrop
(`assets/journey/encounters/cell/backdrop.webp`). Each region's colour lead is from the FAL-474 brief.

| File | Render | Seed | Prompt (sha256, first 8) | Edits (Pillow) |
|---|---|---|---|---|
| `quadratics/backdrop.webp` | Round 1 #2 | 52102 | `088e45c3` | A small pink neon sign at the far left (shaped like a 2) blurred to a plain glow |
| `exp-log/backdrop.webp` | Round 1 #5 | 52102 | `749aeabc` | Relief scribble on one crate plate softened (blur 2.5 px) |
| `graphs-features/backdrop.webp` | Round 2 #2 | 52202 | `ea66eb30` | None |
| `composite-inverse/backdrop.webp` | Round 1 #11 | 52102 | `b501d4f1` | A small pink neon sign at the far left blurred to a plain glow |
| `rational/backdrop.webp` | Round 2 #4 | 52201 | `64b52fe3` | None |
| `function-basics/backdrop.webp` | Round 1 #16 | 52101 | `bd73a6dd` | A swirl mark on the mint panel (read as a 6) blurred to a plain glow |
| `lines/backdrop.webp` | Round 2 #9 | 52203 | `23ade5fe` | Bottom 38% eased to a 3.5 px blur and 85% brightness, to quiet the rail ties behind the question text |
| `transformations/backdrop.webp` | Round 2 #11 | 52202 | `4488de88` | None |
| `all/backdrop.webp` | Round 2 #15 | 52203 | `22e46766` | None |
