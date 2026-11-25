# Scrap Fields board: life pack (design)

Owner direction on FAL-1084 (#226): every zone board ships with its life pack. The design follows the
`ui/ambient_layer.gd` schema, as the Dry Flats', the Radio Spires' and the Engine Core's do (`intake/geometry/life-pack.md`,
`intake/stats/life-pack.md`, `intake/calculus/life-pack.md`). Positions are in pixels of the 1080 × 1920 portrait board
(`game/assets/map/algebra/background.webp`). The core is at y 420 to 1500, so a point in the core is `(x, y + 420)`
here. For the wide board, add 420 to x instead (`zones.json`).

**Technique A** (ART_REQUIREMENTS.md, "Making it feel alive: A or B"): the board stays one still painting, and every
piece below is a sprite or an effect laid over it.

**Status:** designed at intake (FAL-1613). Nothing moves yet. It waits on the same two things as the other zones
(FAL-1092): an `AmbientLayer` on the island board that reads `data/ambient.json` under `"algebra"`, with `spin` and
toys, and then the Artist cutting the sheets from this board.

## Pieces

The Scrap Fields is a working scrapyard, so most of its life is hanging metal swinging and machines moving scrap: the
balance's pans, the crane's claw, the crusher's conveyor, the gate's neon. Swings are slow. Nothing flashes faster
than once a second, and every piece holds a still frame or hides with reduced motion. "Inside a button" means the
piece sits inside a place's 300-unit square (160 for the relic, `SPOTS.algebra`), so it can move but can't be a toy.
Every toy sits in the top or bottom band, clear of every square.

| id | Piece | Where (board px) | Motion (schema) | Reduced motion | Toy | Inside a button |
|---|---|---|---|---|---|---|
| `scrap-balance-pans` | The balance's two pans on their chains: a slight swing, the beam level | 405, 565 · 685, 560 (pans), hung from 405, 470 · 685, 470 | `sway` 1.5°, 6 s, the two pans half a swing apart | still | none | yes (`proof`) |
| `scrap-crane-claw` | The crane's claw on its cable over the wreck mountain | 690, 720 (claw), hung from 690, 660 | `sway` 3°, 5 s | still | none | no (between `proof` and `all`) |
| `scrap-banners` | The torn red banners on the wreck mountain's poles | 340, 795 · 610, 700 · 690, 820 · 270, 860 · 610, 785 | `cycle`, 4 frames at 4 fps, staggered phases | still frame 0 | none | partly (the one at 690, 820, `all`) |
| `scrap-gate-neon` | The gate's teal side lamps and magenta strip | 468, 980 · 655, 980 (teal) · 560, 937 (magenta) | `pulse`, 3 s; the magenta strip `blink` once every 7 s (a dim flicker, not a flash) | still | none | yes (`all`) |
| `scrap-crusher-belt` | The crusher's conveyor carrying a cube up to the drop | 165, 1100 to 330, 1040 (belt) | `cycle`, 8 frames at 6 fps | still frame 0 | none | yes (`sequences`) |
| `scrap-cube-drop` | A crushed-car cube falling from the conveyor's end onto the column | 340, 1075 to 340, 1110 | `path`, 3 s, then a hold of 3 s | hidden | none | yes (`sequences`) |
| `scrap-crusher-jaw` | The crusher's teeth closing and opening | 95, 1180 | `cycle`, 6 frames at 4 fps, a pause each cycle | still frame 0 | none | yes (`sequences`) |
| `scrap-crusher-dust` | Dust from the hopper as the jaw closes | 95, 1100 | `rise`, 4 s, in step with the jaw | hidden | none | yes (`sequences`) |
| `scrap-glass-glint` | Glints on the crushed glass under the drum triangle | 760 to 1050, 700 to 770 (five points) | `blink`, 3 s, staggered phases | hidden | none | yes (`binomial`) |
| `scrap-vault-caps` | A glint running over the vault's piles of bottle caps | 800 to 930, 1050 to 1190 | `pulse`, 4 s | still | none | mostly (`finance`) |
| `scrap-oil-sheen` | The rainbow sheen on the black oil under the trucks | 650 to 1050, 1290 to 1350 | `drift` 20 px, 8 s, back and forth | still | none | partly (`finance`) |
| `scrap-shack-tv` | The TV in the shack: a little static now and then | 517, 1400 | `blink` | hidden | none | yes (`relic`) |
| `scrap-band-haze` | The warm heat haze along the far edges of both bands | 0, 0 to 1080, 160 · 0, 1760 to 1080, 1920 | `drift`, 30 s | hidden | none | no |
| `scrap-buzzard` | A scrap buzzard circling the top band | an oval loop round 540, 210, 600 wide and 280 tall | `path`, 22 s, `face: flip`, `bob` 3 | hidden | **flap**: a tap sends it off the top edge, and it comes back 20 s later | no (top band) |
| `scrap-tumble-wire` | A ball of tangled wire rolling slowly along the top band (a new small sprite) | from 120, 320 to 960, 290 and back | `path`, 26 s, rolling | hidden | **hop**: a tap bounces it up once and it rolls on | no (top band) |
| `scrap-hubcap-spinner` | A hubcap nailed to a post, turned by the wind (a new small sprite) | a clear spot of the bottom band, near 200, 1700 | `spin`, 12 s a turn | still frame 0 | **spin**: a tap spins it fast for 2 s, then it eases back | no (bottom band) |
| `scrap-drum-stack` | Three rusty drums stacked in a little pyramid, one wobbling (a new small sprite) | a clear spot of the bottom band, near 860, 1690 | `sway` 2° on the top drum, 5 s | still | **break**: three taps topple the stack with a clang and a puff of dust. It stays toppled and keeps a little life: one drum rocks on its side now and then | no (bottom band) |

One breakable toy, under the limit of two a map. The broken state is saved, like any toy that breaks.

`spin`, `blink`, `cycle` and the toys are the parts FAL-1092 adds to the schema (`MOTIONS` has `none`, `bob`,
`sway`, `drift`, `path`, `pulse` and `rise` today).

## Phone preview

The phone-size preview (270 × 480, with every piece marked) is posted on FAL-1613 with the Scrap Fields PR.
