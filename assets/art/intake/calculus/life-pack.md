# Engine Core board: life pack (design)

Owner direction on FAL-1084 (#226): every zone board ships with its life pack. The design follows the
`ui/ambient_layer.gd` schema, as the Dry Flats' and the Radio Spires' do (`intake/geometry/life-pack.md`,
`intake/stats/life-pack.md`). Positions are in pixels of the 1080 × 1920 portrait board
(`game/assets/map/calculus/background.webp`). The core is at y 420 to 1500, so a point in the core is `(x, y + 420)`
here. For the wide board, add 420 to x instead (`zones.json`).

**Technique A** (ART_REQUIREMENTS.md, "Making it feel alive: A or B"): the board stays one still painting, and every
piece below is a sprite or an effect laid over it.

**Status:** designed at intake (FAL-1612). Nothing moves yet. It waits on the same two things as the other zones
(FAL-1092): an `AmbientLayer` on the island board that reads `data/ambient.json` under `"calculus"`, with `spin` and
toys, and then the Artist cutting the sheets from this board.

## Pieces

The Engine Core is a working machine, so most of its life is heat and turning metal: smoke from the stacks, lava
churning in the crater, gears turning, steam from the coaster's vents. Gears turn slowly. Nothing flashes faster
than once a second, and every piece holds a still frame or hides with reduced motion. "Inside a button" means the
piece sits inside a place's 300-unit square (`SPOTS.calculus`), so it can move but can't be a toy. Every toy sits in
the top or bottom band, clear of every square.

| id | Piece | Where (board px) | Motion (schema) | Reduced motion | Toy | Inside a button |
|---|---|---|---|---|---|---|
| `core-stack-smoke` | Black smoke from the engine's three stacks, drifting right | 458, 743 · 495, 750 · 533, 758, rising to about 700, 600 | `rise`, 6 s, phases 0, 0.33, 0.66 | hidden | none | no (above the `all` square) |
| `core-crater-lava` | The molten floor and walls of the crater: a slow churn | 585, 1080, the crater's glowing ring | `pulse`, 4 s, with a churn shader on a masked glow | still | none | yes (`all`) |
| `core-gate-glow` | The furnace gate's two lit windows | 445, 1035 · 720, 1035 | `pulse`, 3 s, phases 0, 0.5 | still | none | yes (`all`) |
| `core-engine-gear` | The big gear on the engine | 645, 885 (hub) | `spin`, 24 s a turn | still frame 0 | none | yes (`all`) |
| `core-gear-train` | The gear train: the big gear and the two smaller ones, meshed | 120, 578 · 210, 585 · 330, 578 (hubs) | `spin`, the big gear 18 s a turn, the others faster by their size, opposite ways | still frame 0 | none | yes (`derivative-rules`) |
| `core-gear-chain` | The chain from the last gear | 260 to 330, 545 to 575 | `cycle`, 8 frames at 6 fps, in step with the gears | still frame 0 | none | yes (`derivative-rules`) |
| `core-chute-flow` | Molten metal running down the four chutes into the tank | 470 to 600, 440 to 640 | `cycle`, 8 frames at 8 fps (the glow slides down) | still frame 0 | none | yes (`integration`) |
| `core-plates` | The tilting plates on the curved ramp: a slight rock, each in turn | 825 to 1035, 510 to 690 (seven plates) | `sway` 2°, 4 s, staggered phases | still | none | yes, mostly (`derivative-basics`) |
| `core-dam-pool` | The lava pool between the dam's gates | 900, 915 | `pulse`, 5 s, with the churn shader | still | none | yes (`definite-integrals`) |
| `core-rail-lamp` | A lamp at the top of the rail's post | 203, 765 | `pulse`, 3 s | still | none | yes (`tangents-normals`) |
| `core-rocket-flame` | The rocket cart's exhaust flame | 173, 1163 | `cycle`, 4 frames at 10 fps | still frame 0 | none | yes (`kinematics`) |
| `core-rocket-dust` | The dust trail behind the rocket | 50 to 140, 1120 to 1200 | `drift` 30 px, 6 s, back and forth | still | none | yes (`kinematics`) |
| `core-post-lamps` | The magenta lamps on the marker posts | 323 to 495, 1160 to 1200 (six) | `blink`, 2 s, staggered phases | still frame 0 | none | partly (the first posts, `kinematics`) |
| `core-coaster-steam` | Steam from the coaster's three vents | 645, 1163 · 893, 1125 · 863, 1253 | `rise`, 5 s, phases 0, 0.4, 0.7 | hidden | none | partly (the two right vents, `stationary-points`) |
| `core-level-glow` | The green glow of the two spirit levels | 833, 1068 · 1002, 1155 | `pulse`, 3 s, phases 0, 0.5 | still | none | yes (`stationary-points`) |
| `core-shack-tv` | The TV in the shack: a little static now and then | 563, 1373 | `blink` | hidden | none | yes (`relic`) |
| `core-band-haze` | The warm heat haze along the far edges of both bands | 0, 0 to 1080, 160 · 0, 1760 to 1080, 1920 | `drift`, 30 s | hidden | none | no |
| `core-buzzard` | A scrap buzzard circling the top band | an oval loop round 540, 210, 600 wide and 280 tall | `path`, 22 s, `face: flip`, `bob` 3 | hidden | **flap**: a tap sends it off the top edge, and it comes back 20 s later | no (top band) |
| `core-dust-devil` | A small dust devil wandering the top band | from 140, 300 to 400, 260 | `path`, 16 s | hidden | **stir**: a tap scatters it, and it spins up again 5 s later | no (top band) |
| `core-wind-gear` | A lone small gear on a post, turned by the wind (a new small sprite) | a clear spot of the bottom band, near 220, 1700 | `spin`, 12 s a turn | still frame 0 | **spin**: a tap spins it fast for 2 s, then it eases back | no (bottom band) |
| `core-steam-valve` | A rusty steam valve on a stub pipe, hissing (a new small sprite) | a clear spot of the bottom band, near 860, 1680 | `rise` (a puff every 4 s) | still | **break**: three taps blow the valve off in a burst of steam. It stays broken and keeps a little life: a thin wisp of steam now and then | no (bottom band) |

One breakable toy, under the limit of two a map. The broken state is saved, like any toy that breaks.

`spin`, `blink`, `cycle` and the toys are the parts FAL-1092 adds to the schema (`MOTIONS` has `none`, `bob`,
`sway`, `drift`, `path`, `pulse` and `rise` today); the churn shader on the lava is the plan in FAL-981.

## Phone preview

The phone-size preview (270 × 480, with every piece marked) is posted on FAL-1612 with the Engine Core PR.
