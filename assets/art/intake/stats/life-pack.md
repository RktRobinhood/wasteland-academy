# Radio Spires board: life pack (design)

Owner direction on FAL-1084 (#226): every zone board ships with its life pack. The design follows the
`ui/ambient_layer.gd` schema, as the Dry Flats' does (`intake/geometry/life-pack.md`). Positions are in pixels of the
1080 × 1920 portrait board (`game/assets/map/stats/background.webp`). The core is at y 420 to 1500, so a point in
the core is `(x, y + 420)` here. For the wide board, add 420 to x instead (`zones.json`).

**Status:** designed at intake (FAL-1611). Nothing moves yet. It waits on the same two things as the Dry Flats
(FAL-1092): an `AmbientLayer` on the island board that reads `data/ambient.json` under `"stats"`, with `spin` and
toys, and then the Artist cutting the sheets from this board.

## Pieces

The Radio Spires is a zone of signals, so most of its life is light: lamps, neon and glow that pulse slowly. Nothing
flashes faster than once a second, and every piece holds a still frame or hides with reduced motion. "Inside a
button" means the piece sits inside a place's 300-unit square (`SPOTS.stats`), so it can move but can't be a toy.
Every toy sits in the top or bottom band, clear of every square.

| id | Piece | Where (board px) | Motion (schema) | Reduced motion | Toy | Inside a button |
|---|---|---|---|---|---|---|
| `spires-crystals` | The blue-violet veins in the twin spires | 600, 810 · 470, 900 · 640, 960 | `pulse`, 4 s, phases 0, 0.33, 0.66 | still | none | yes (`all`) |
| `spires-gate-neon` | The violet neon bar over the gate | 533, 1020 | `pulse`, 3 s | still | none | yes (`all`) |
| `spires-dish` | The big dish on the left spire | 435, 803 | `sway` 3°, 8 s (a slow scan) | still | none | yes (`all`) |
| `spires-crane-hook` | The crane's hook over the scrap heap | 693, 518 | `sway` 3°, 2.8 s | still | none | yes (`sampling-data`) |
| `spires-heap-pennants` | The red pennants on the scrap heap | 360, 510 · 450, 505 · 600, 530 | `sway` 4°, 1.8 s, phases 0, 0.3, 0.6 | still | none | yes (`sampling-data`) |
| `spires-valve-glow` | The teal lit path in the valve tree | 180, 660 | `pulse`, 3 s | still | none | yes (`conditional-probability`) |
| `spires-box-pennants` | The two pennants on the box on stilts | 855, 532 · 938, 532 | `sway` 4°, 1.6 s, phases 0, 0.5 | still | none | yes (`averages-spread`) |
| `spires-peg-ball` | One ball dropping through the peg board onto the heap | from 142, 780 to 165, 960 | `path`, 2.5 s, with a 4 s rest | hidden | none | yes (`normal-distribution`) |
| `spires-field-lamps` | The teal lamps on the antenna-field masts | 785, 862 · 840, 840 · 878, 825 · 945, 818 · 998, 788 · 1035, 765 | `blink`, 2 s, staggered phases | still frame 0 | none | yes (`regression`) |
| `spires-mast-lamps` | The teal lamps on the mast row | 98 to 293, 1105 to 1125 (seven) | `blink`, 2.4 s, staggered phases | still frame 0 | none | yes (`discrete-distributions`) |
| `spires-spinner` | The spinner's wheel | 945, 1290 (hub) | `spin`, 20 s a turn, stopping on a wedge each lap | still frame 0 | none | yes (`probability`) |
| `spires-tv` | The TV in the shack: a little static now and then | 533, 1395 | `blink` | hidden | none | yes (`relic`) |
| `spires-band-haze` | The violet haze along the far edges of both bands | 0, 0 to 1080, 160 · 0, 1760 to 1080, 1920 | `drift`, 30 s | hidden | none | no |
| `spires-drone` | A small survey drone patrolling the top band | loop round 540, 220, radius 220 | `path`, 20 s, `face: flip`, `bob` 3 | hidden | **flap**: a tap sends it off the top edge, and it comes back 20 s later | no (top band) |
| `spires-dish-post` | A lone small dish on a post in the top band (a new small sprite) | a clear spot of the top band, near 860, 250 | `sway` 5°, 6 s | still | **spin**: a tap spins the dish fast for 2 s, then it eases back | no (top band) |
| `spires-static` | A crackle of radio static, a few violet sparks, drifting over the bottom band | from 150, 1650 to 450, 1720 | `path`, 14 s | hidden | **stir**: a tap scatters the sparks, and they gather again 4 s later | no (bottom band) |
| `spires-junction-box` | A sparking junction box on a stub post in the bottom band (a new small sprite) | a clear spot of the bottom band, near 820, 1700 | `blink` (a spark every 3 s) | still | **break**: three taps short it out in a puff of smoke. It stays dead and keeps a little life: a thin wisp of smoke now and then | no (bottom band) |

One breakable toy, under the limit of two a map. The broken state is saved, like any toy that breaks.

## Phone preview

The phone-size preview (270 × 480, with every piece marked) is posted on FAL-1611 with the Radio Spires PR.
