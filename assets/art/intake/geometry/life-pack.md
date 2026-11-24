# Dry Flats board: life pack (design)

Owner direction on FAL-1084 (#226): every zone board ships with its life pack, so the board feels alive. The
design follows the `ui/ambient_layer.gd` schema. Positions are in pixels of the 1080 × 1920 portrait board
(`game/assets/map/geometry/background.webp`). The core is at y 420 to 1500, so a point in the core is
`(x, y + 420)` here. For the wide board, add 420 to x instead (`zones.json`).

**Status:** designed at intake (FAL-1034). Nothing moves yet. Two things are needed first:

1. **The Artist** cuts the sheets from the board itself (`assets/ambient/<sheet>-sheet.png` and its `.json`),
   so each piece matches the painting exactly.
2. **The Coder:**
   - **(a)** Build an `AmbientLayer` on the island board, as `map.gd` does on the world board. It goes between
     the painting and the buttons, reads `data/ambient.json` under the island's id (`"geometry"`), and follows
     `reduced_motion()`.
   - **(b)** Add a `spin` motion: a steady turn at `period` seconds per turn, with an optional `speed_up` for a toy.
   - **(c)** Add toys. A toy is a piece with a `toy` reaction that takes a tap, but only outside every
     place's button. The layer takes no taps today.

## Pieces

Busy places get the quiet motion. Nothing flashes faster than once a second, and every piece either holds a still
frame or hides with reduced motion. "Inside a button" means the piece sits inside a place's 300-unit square
(`SPOTS.geometry`), so it can move but can't be a toy.

| id | Piece | Where (board px) | Motion (schema) | Reduced motion | Toy | Inside a button |
|---|---|---|---|---|---|---|
| `flats-windwheel` | The windwheel's rotor at the start of the wave ridge, cut out | 566, 1125 (hub) | `spin`, 6 s a turn | still frame 0 | **spin**: a tap spins it fast for 2 s, then it eases back | no: clear of every square |
| `flats-wave-flags` | The three red flags on the wave wall | 175, 510 · 285, 517 · 390, 515 | `sway` 4°, 1.6 s, phases 0, 0.3, 0.6 | still | none | yes (`trig-equations`) |
| `flats-level-line` | The teal level line on the flood pan | 90 to 440, 610 | `cycle`, 3 frames of shimmer, 4 fps | still frame 0 | none | yes (`trig-equations`) |
| `flats-ring-plumb` | The magenta plumb line from the arm's tip | 967, 570 (top of the line) | `sway` 2°, 3 s (a pendulum) | still | none | yes (`unit-circle`) |
| `flats-pie-rim` | The magenta neon on the lifted wedge's rim | 230, 810 | `blink` | still frame 0 | none | yes (`arcs-sectors`) |
| `flats-mason-rod` | The teal rod's glow inside the girder box | 935, 860 | `pulse`, 3 s | still | none | yes (`geometry-3d`) |
| `flats-gate-neon` | The two magenta tubes beside the gate | 473, 995 · 585, 995 | `blink`, phases 0 and 0.5 | still frame 0 | none | yes (`all`) |
| `flats-ramp-plumb` | The magenta plumb line on the ramp | 302, 1155 | `sway` 2°, 2.6 s | still | none | yes (`triangles`) |
| `flats-tv` | The dead TV in the shack wall: a little static now and then | 518, 1380 | `blink` | hidden | none | yes (`relic`) |
| `flats-dust-devil-1` | A small dust devil crossing the salt between the mesa and the stone ring | from 640, 760 to 700, 650 | `path`, 12 s, there and back | hidden | **stir**: a tap scatters it into a puff, and it forms again 4 s later | no, but its path is checked against every square |
| `flats-dust-devil-2` | A second, smaller one in the dunes of the bottom band | from 120, 1600 to 420, 1680 | `path`, 16 s | hidden | **stir** | no (bottom band) |
| `flats-buzzard` | A buzzard circling high over the top band | loop round 540, 220, radius 180 | `path`, 18 s, `face: flip`, `bob` 4 | hidden | **flap**: a tap sends it off the top edge, and it comes back 20 s later | no (top band) |
| `flats-band-dust` | Thin dust drifting along the top and bottom bands | 0, 0 to 1080, 420 · 0, 1500 to 1080, 1920 | `drift`, 30 s | hidden | none | no |
| `flats-hoodoo` | A balanced rock on an outcrop in the bottom band (a new small sprite) | in a clear spot of the bottom band, chosen when the band is final | `none` | still | **break**: three taps tip it over in a puff of dust. It stays down and keeps a little life: a trickle of sand runs off it now and then | no (bottom band) |

One breakable toy, under the limit of two a map. The broken state is saved, like any toy that breaks.

## Phone preview

The phone-size preview (270 × 480, with every piece marked) is posted on FAL-1034 with the Dry Flats PR.
