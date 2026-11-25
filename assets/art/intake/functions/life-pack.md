# Signal Tower board: life pack (design)

Owner direction on FAL-1084 (#226): every zone board ships with its life pack. The design follows the
`ui/ambient_layer.gd` schema, as the other four zones' do (`intake/geometry/life-pack.md`, `intake/stats/life-pack.md`,
`intake/calculus/life-pack.md`, `intake/algebra/life-pack.md`). Positions are in pixels of the 1080 × 1920 portrait
board (`game/assets/map/functions/background.webp`, Matt's B5-2). The core is at y 420 to 1500, so a point in the core is
`(x, y + 420)` here. For the wide board, add 420 to x instead (`zones.json`).

This replaces the Signal Tower plan that FAL-1091 drew up on the old painting (FAL-791's local board). Its zone-map
pieces now come from B5-2: the old painting's places and landmarks are gone.

**Technique A** (ART_REQUIREMENTS.md, "Making it feel alive: A or B"): the board stays one still painting, and every
piece below is a sprite or an effect laid over it.

**Status:** designed at intake (FAL-1614). Nothing moves yet. It waits on the same two things as the other zones
(FAL-1092): an `AmbientLayer` on the island board that reads `data/ambient.json` under `"functions"`, with `spin` and
toys, and then the Artist cutting the sheets from this board.

## Pieces

The Signal Tower is a broadcast station in the desert, so most of its life is signal: the tower's teal core and lamps,
the dishes, the beacon at the top, and flags and banners in the wind. Two pieces carry the maths a little: the two
trains in the mirror yards shunt as mirror images of each other, and a bead rides the wire curve between the flags.
Nothing flashes faster than once a second, and every piece holds a still frame or hides with reduced motion. "Inside a
button" means the piece sits inside a place's 300-unit square (160 for the relic, `SPOTS.functions`), so it can move but
can't be a toy. Every toy sits in the top band (above y 330) or the bottom band (below y 1475), clear of every square.

| id | Piece | Where (board px) | Motion (schema) | Reduced motion | Toy | Inside a button |
|---|---|---|---|---|---|---|
| `tower-beacon` | The lamp on the tower's tallest needle | 560, 605 | `pulse`, 2.5 s (a slow glow, not a flash) | still (lit) | none | no (above `all`) |
| `tower-core` | The teal light column inside the tower's frame | 567, 700 to 567, 930 | `pulse`, 4 s, a light running up the column | still | none | partly (`all`) |
| `tower-gate-lamps` | The gate's two teal side lamps and its orange warning lamp | 513, 993 · 640, 993 (teal) · 573, 957 (orange) | `pulse`, 3 s; the orange lamp `blink` once every 6 s (a dim flicker) | still | none | yes (`all`) |
| `tower-dishes` | The three dishes, turning slightly to track a signal | 500, 675 · 445, 820 · 620, 760 | `sway` 4°, 9 s, each dish a third of a swing apart | still | none | partly (`all`) |
| `tower-banners` | The magenta banners on the mesa's poles | 403, 850 · 675, 855 | `cycle`, 4 frames at 4 fps, staggered | still frame 0 | none | partly (`all`) |
| `yards-shunt` | The magenta and teal trains inching forward and back, always as mirror images | 173, 573 (magenta) · 280, 620 (teal) | `path` 24 px along each track, 10 s, the teal one the mirror of the magenta | still | none | yes (`composite-inverse`) |
| `yards-lamps` | The shed lamps: magenta over one track, teal over the other | 140, 535 · 167, 535 · 200, 530 (magenta) · 313, 573 (teal) | `pulse`, 3.5 s | still | none | yes (`composite-inverse`) |
| `market-awnings` | The three chevron awnings and the hanging cloth stirring | 775, 560 · 880, 560 · 985, 560 · 713, 630 | `cycle`, 4 frames at 3 fps, staggered | still frame 0 | none | yes (`transformations`) |
| `curve-flags` | The four pennants on the wire curve | 830, 775 · 912, 805 · 975, 738 · 1043, 825 | `cycle`, 4 frames at 4 fps, staggered | still frame 0 | none | yes (`graphs-features`) |
| `curve-bead` | A brass bead riding the wire curve end to end, slowing at the peaks and troughs | along the wire, 805, 860 to 1035, 840 | `path`, 12 s, there and back | hidden | none | yes (`graphs-features`) |
| `machine-lever` | The machine's lever rocking, and a block sliding down the out-chute | 190, 790 (lever) · 230, 900 (chute) | `sway` 6° on the lever, 5 s; the block a `path` down the chute, 5 s, in step | still | none | yes (`function-basics`) |
| `salt-shimmer` | Heat shimmer over the white salt pan | 400 to 730, 450 to 620 | `drift`, 20 s | hidden | none | yes (`lines`) |
| `spiral-trickle` | Water trickling out of the spiral pipe's mouth into the pool | 800, 1227 | `cycle`, 6 frames at 6 fps | still frame 0 | none | yes (`exp-log`) |
| `pool-ripples` | Rings spreading on the teal pool round the pipe's legs and the steps | 670 to 1060, 1160 to 1300 | `pulse`, 5 s, staggered rings | hidden | none | yes (`exp-log`) |
| `wall-gap-dust` | A thin stream of dust blown through the gap between the two walls | 540, 1310 to 540, 1400 | `rise`, 6 s | hidden | none | yes (`rational`) |
| `shack-tv` | The TV in the shack: a little static now and then | 130, 1005 | `blink` | hidden | none | yes (`relic`) |
| `band-haze` | The warm heat haze along the far edges of both bands | 0, 0 to 1080, 160 · 0, 1760 to 1080, 1920 | `drift`, 30 s | hidden | none | no |
| `scout-drone` | A small survey drone with a blinking teal light, tracing a slow loop over the top band (a new small sprite) | an oval loop round 540, 200, 640 wide and 220 tall | `path`, 24 s, `face: flip`, `bob` 3 | hidden | **flap**: a tap sends it zipping off the top edge, and it comes back 20 s later | no (top band) |
| `wind-vane` | A cup anemometer on a short mast, the station's weather vane (a new small sprite) | a clear spot of the top band, near 900, 300 | `spin`, 8 s a turn | still frame 0 | **spin**: a tap spins it fast for 2 s, then it eases back | no (top band) |
| `dust-devil` | A small dust devil wandering the bottom band | from 180, 1700 to 880, 1720 and back | `path`, 30 s, its column a `cycle` of 6 frames | hidden | **stir**: a tap scatters it into a puff, and it winds itself back up over 4 s | no (bottom band) |
| `relay-box` | A rusty relay box on a pole with a short aerial, humming (a new small sprite) | a clear spot of the bottom band, near 860, 1640 | `blink` on its little lamp, 4 s | still | **break**: three taps, with sparks after the first and a hiss after the second, pop the box with a flash and a puff of smoke. It stays a scorched husk and keeps a little life: a thin wisp of smoke and a spark now and then | no (bottom band) |

One breakable toy, under the limit of two a map. The broken state is saved, like any toy that breaks.

`spin`, `blink`, `cycle` and the toys are the parts FAL-1092 adds to the schema (`MOTIONS` has `none`, `bob`,
`sway`, `drift`, `path`, `pulse` and `rise` today).

## Phone preview

The phone-size preview (270 × 480, with every piece marked) is posted on FAL-1614 with the Signal Tower PR.
