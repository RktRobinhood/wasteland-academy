# Region art

Art for each region of the Functions island, the Scrap Fields and the Dry Flats, loaded by file name (`engine/art_slots.gd`; the contract is the
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
| `sequences/backdrop.webp` | Crusher yard, columns one cube taller each | 124,808 | 12.3% | 4.9% | 10.6% | 6.9:1 | 7.7:1 |
| `finance/backdrop.webp` | Pawn strongroom, open vault, trucks decaying in a row | 116,702 | 11.6% | 6.1% | 8.7% | 6.2:1 | 6.6:1 |
| `exponents-logs/backdrop.webp` | Crate pyramid, rows of 1, 2, 4, 8, notched pole | 72,908 | 9.2% | 3.2% | 8.9% | 10.5:1 | 10.7:1 |
| `binomial/backdrop.webp` | Drum triangle, yellow edge drums | 85,242 | 13.0% | 5.6% | 10.5% | 6.3:1 | 6.6:1 |
| `proof/backdrop.webp` | Assay house, crane-arm balance dead level | 57,996 | 11.3% | 4.2% | 9.6% | 10.1:1 | 10.2:1 |
| `all-algebra/backdrop.webp` | The foot of the wreck mountain, its gate | 156,960 | 12.2% | 5.9% | 12.9% | 8.9:1 | 8.8:1 |
| `triangles/backdrop.webp` | Wedge quarry: a right-angled ramp, its ladder, notch and plumb line | 146,818 | 13.8% | 5.2% | 13.3% | 5.52:1 | 6.06:1 |
| `trig-graphs/backdrop.webp` | Wave rocks: a sandstone ridge of four equal crests, a windwheel at its start | 87,106 | 15.0% | 4.9% | 12.1% | 6.45:1 | 6.69:1 |
| `arcs-sectors/backdrop.webp` | Sundial floor: a round floor in wedges, one lifted out beside its slot | 116,796 | 16.3% | 7.4% | 17.3% | 4.66:1 | 4.81:1 |
| `geometry-3d/backdrop.webp` | Mason's yard: an open girder box with a teal rod corner to corner, a pyramid and a cone | 148,254 | 12.3% | 6.8% | 10.5% | 4.69:1 | 4.84:1 |
| `trig-equations/backdrop.webp` | Flooded wave canyon: a wave wall, a teal level line, a flag where they meet | 99,378 | 13.5% | 7.0% | 14.4% | 4.65:1 | 4.71:1 |
| `unit-circle/backdrop.webp` | Stone ring: a pivot arm to the ring's edge, a magenta plumb line from its tip | 104,086 | 14.6% | 6.0% | 15.0% | 5.18:1 | 5.29:1 |
| `all-geometry/backdrop.webp` | The foot of the stepped mesas, the arch above, the gate in the middle | 146,578 | 10.8% | 4.8% | 10.5% | 5.75:1 | 6.68:1 |

Signal Tower batch total: 777,386 bytes. Scrap Fields batch total: 614,616 bytes. Dry Flats batch total: 849,016 bytes.

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

The Scrap Fields backdrops (FAL-963) were made the same way, with FAL-474's style text: one round of 18 renders
(6 backdrops × 3 seeds), each prompt describing its place from the FAL-963 place table (the island painting was dropped on FAL-972). A
second round of 3 tried to re-stack the crate pyramid by masked repaint and wasn't used. Two came out with the wrong counts
(crate rows, crusher columns), so Pillow cleared them and re-stacked the render's own crates and cubes: rows of 1, 2, 4, 8 and
columns of 1 to 6. Method, counters and review sheets are on FAL-963.

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
| `sequences/backdrop.webp` | Round 1 #2 | 96502 | `b36fb4e0` | Columns cleared (row-wise plate, `plate_fill.py`) and rebuilt from four of its own cubes as columns of exactly 1 to 6; two small pink lamps (one shaped like !) blurred to a plain glow |
| `finance/backdrop.webp` | Round 1 #6 | 96503 | `5f047ad6` | Highlights above 40% luma rolled off by half (coins in the text zone; 4.6:1 to 6.2:1) |
| `exponents-logs/backdrop.webp` | Round 1 #9 | 96503 | `62897dec` | Its 1-2-4-7 pyramid cleared (row-wise plate) and rebuilt from its own crate face in rows of exactly 1, 2, 4, 8 |
| `binomial/backdrop.webp` | Round 1 #11 | 96502 | `032c5906` | Highlights above 40% luma rolled off by half (4.7:1 to 6.3:1); a small R-like mark on one drum end blurred to a plain smudge |
| `proof/backdrop.webp` | Round 1 #14 | 96502 | `18a8c1b5` | None |
| `all-algebra/backdrop.webp` | Round 1 #17 | 96502 | `f8411e99` | None |

### The Dry Flats (FAL-1034)

Made by Matt Prokock in ChatGPT from the Artist's prompt cards (`assets/art/prompt-cards/batch-1.md`, #201), on
2026-11-16 and 2026-11-17, with the world map attached as the style reference. Nothing was painted locally. The
Artist picked one candidate per card against the checklist in `ART_REQUIREMENTS.md`; the reasons are on FAL-1034.
Each original is 1672 x 941. Pillow scaled it to 1920 x 1081 (LANCZOS), trimmed the bottom row, applied the edits
below and encoded WebP at quality 90 (89 where 90 went over the 150 KB budget). Provenance and SHA-256 for each
file are in `assets/art/CREDITS.md`.

Two lines of the brief are looser here than for the local renders. ChatGPT draws a place wider than the centre
600 px (most span 45 to 65 % of the width), so on an upright phone each keeps its maths in the centre 500 px but
not always the whole place. And the worst-point text contrast is lower (4.7:1 to 6.7:1 rather than 6 to 11:1),
still over WCAG AA's 4.5:1 everywhere. The roll-off pulls only the brightest highlights (lamp cores, neon, the
glowing rod) toward the limit, so they stay lit.

| File | Card and candidate | Prompt (sha256, first 8) | Edits (Pillow) |
|---|---|---|---|
| `triangles/backdrop.webp` | DF1-2 | `add8ce47` | None (q89) |
| `trig-graphs/backdrop.webp` | DF2-1 | `a605915d` | None |
| `arcs-sectors/backdrop.webp` | DF3-3 | `03840982` | Highlight roll-off on 1.06 % of pixels (lamp cores and neon), 4.04:1 to 4.66:1 on phone |
| `geometry-3d/backdrop.webp` | DF4r-1 (the rerun of DF4) | `e74edfe9` | Highlight roll-off on 0.34 % of pixels (the rod's white core turns solid teal), 3.4:1 to 4.69:1 on phone; q89 |
| `trig-equations/backdrop.webp` | DF5-5 | `4520f260` | Highlight roll-off on 0.68 % of pixels (the level line and its reflections), 3.5:1 to 4.65:1 on phone |
| `unit-circle/backdrop.webp` | DF6-5 | `c8034e34` | None |
| `all-geometry/backdrop.webp` | DF7-4 | `7e438e6c` | None |
