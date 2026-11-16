# Prompt cards, batch 1 (FAL-1034, #201)

Written 2026-11-16 by the Artist. The format, the checklist and the square-core rule are in `ART_REQUIREMENTS.md`, under "MAP AND LEVEL ART FROM CHATGPT". Matt runs these in ChatGPT and attaches about five candidates per card on FAL-1034. The Artist picks one per card.

## How to run them

1. Open the ChatGPT chat where you made the world map, or start a new one and upload the world map first: "Use this as the style reference for every image in this chat."
2. Paste one prompt per image. Do each card about five times. Pick the aspect each card names; if ChatGPT gives a slightly different one, that's fine.
3. Attach the images on FAL-1034, named by card and number: `B1-1.png` to `B1-5.png`, and so on. A comment is welcome; I treat it as a strong preference.
4. Go in order and stop wherever you like. Whatever you haven't run stays here for the next sitting.

Don't attach the layout pictures to ChatGPT. They're for checking the results, and on FAL-975 a layout sketch made the model paint every place on its own raised disc.

## Order

| # | Card | Piece | Candidates |
|---|---|---|---|
| 1 | B1 | Scrap Fields board | about 5 |
| 2 | B2 | Dry Flats board | about 5 |
| 3 | B3 | Radio Spires board | about 5 |
| 4 | B4 | Engine Core board | about 5 |
| 5 | B4P | Engine Core board, emptied (for technique B), one per B4 image | about 5 |
| 6 | B5 | Signal Tower board (replaces the local painting on `main`) | about 5 |
| 7 | W1 | World map, landscape for PC | about 5 |
| 8 | DF1 to DF7 | Dry Flats fight backdrops (7) | about 5 each |
| 9 | RS1 to RS8 | Radio Spires fight backdrops (8) | about 5 each |
| 10 | EC1 to EC8 | Engine Core fight backdrops (8) | about 5 each |

The Scrap Fields and Signal Tower fight backdrops on `main` were painted locally. They come back as batch 2, once the new boards have set the look.

## Zone boards

Every board is one square picture (the core). At intake I add plain bands of ground and sky to make a 1080 × 1920 phone board and a 1920 × 1080 PC board from the same picture, so the places sit in the same spot in both.

### B1. Scrap Fields board (Numbers and algebra)

| Field | |
|---|---|
| Becomes | `game/assets/map/algebra/background.webp` (1080 × 1920) and `background-wide.webp` (1920 × 1080) |
| Reference | [`overworld.png`](../../../game/assets/map/overworld.png), the world map (on the Paperclip card as `ref-01-world-map.png`) |
| Aspect | Square, 1:1 (scaled to 1080 × 1080 at intake) |
| Layout picture | `B1-layout-scrap-fields.png` on the card, for checking only |
| Where things sit (tap zones) | Centre → `all`; Top → `proof`; Top left → `exponents-logs`; Top right → `binomial`; Bottom left → `sequences`; Bottom right → `finance`; Bottom → `relic` |
| Keep clear | A plain margin round all four edges; the ground at the foot of each place, where the game draws its padlock or flag; open ground between places for the name card |
| Must not appear | Text, letters, numbers, symbols or logos; people or animals; roads, paths, rails or tracks between places; sky or a horizon |
| Fixable at intake | A wrong count (crates, cubes, drums), a stray mark, a thin edge |
| Not fixable | A missing place, a place that doesn't show its maths, a road between places, a place cut off by the edge |
| Prompt hash | `c00f7bdf` |

**Prompt**

    Use the attached world map as the style reference and match its look exactly: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Use the same high three-quarter overhead camera as the map, but much closer in. Square picture, 1:1.

    This is a close-up of the Scrap Fields from that map: rust-red badlands around a mountain of wrecks. The ground fills the whole picture, with no horizon and no sky. It is one continuous stretch of ground, painted as a single picture. There are no roads, paths, bridges, rails, tracks or lines of any kind joining the places: open ground, dunes and rock outcrops lie between them. Each place stands on its own clear patch of ground, about a quarter of the picture wide and well apart from the others, and each patch's ground colour fades into the shared ground. The ground just in front of each place is plain. A strip of plain open ground runs round all four edges of the picture, about one-sixteenth of its width, with nothing standing on it and nothing cut off by the edge.

    The places:
    - Centre: the biggest landmark: the wreck mountain, a mountain of stacked wrecked trucks and buses with a big yellow lattice crane on top and a heavy gate at its foot.
    - Top: a giant balance built from a crane arm, its two scrap pans hanging dead level, each pan holding a different-looking heap, on dark flattened tyre rubber.
    - Top left: a stepped pyramid of crates, with one crate on top, two below it, four below that and eight on the bottom row, and a tall pole beside it notched once per row, on cracked red clay.
    - Top right: a triangle of oil drums stacked row on row, each drum resting on the two below it, with the drums down both edges painted one bright colour, on glinting crushed glass.
    - Bottom left: a crusher yard with a row of six columns of crushed-car cubes, each column exactly one cube taller than the one before, like a staircase, and a conveyor dropping the next cube on the end, on rust gravel.
    - Bottom right: an open vault door with bottle-cap coins spilling onto three stacked shelves, the heap clearly bigger on each shelf, and beside it a short row of the same truck, each one more rusted and stripped than the one before, on black oil mud.
    - Bottom: a small half-buried, boarded-up shack with a dead TV screen in its wall, much smaller than the other places.
    - Left: nothing, just open ground.
    - Right: nothing, just open ground.

    Nothing else stands on the ground: no other buildings, no vehicles except those named, no people and no animals. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

### B2. Dry Flats board (Geometry and trigonometry)

| Field | |
|---|---|
| Becomes | `game/assets/map/geometry/background.webp` (1080 × 1920) and `background-wide.webp` (1920 × 1080) |
| Reference | [`overworld.png`](../../../game/assets/map/overworld.png), the world map (on the Paperclip card as `ref-01-world-map.png`) |
| Aspect | Square, 1:1 (scaled to 1080 × 1080 at intake) |
| Layout picture | `B2-layout-dry-flats.png` on the card, for checking only |
| Where things sit (tap zones) | Centre → `all`; Top left → `trig-equations`; Top right → `unit-circle`; Left → `arcs-sectors`; Right → `geometry-3d`; Bottom left → `triangles`; Bottom right → `trig-graphs`; Bottom → `relic` |
| Keep clear | A plain margin round all four edges; the ground at the foot of each place, where the game draws its padlock or flag; open ground between places for the name card |
| Must not appear | Text, letters, numbers, symbols or logos; people or animals; roads, paths, rails or tracks between places; sky or a horizon |
| Fixable at intake | A wrong count (crates, cubes, drums), a stray mark, a thin edge |
| Not fixable | A missing place, a place that doesn't show its maths, a road between places, a place cut off by the edge |
| Prompt hash | `21edcc86` |

**Prompt**

    Use the attached world map as the style reference and match its look exactly: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Use the same high three-quarter overhead camera as the map, but much closer in. Square picture, 1:1.

    This is a close-up of the Dry Flats from that map: a white cracked salt flat with sandstone mesas and arches. The ground fills the whole picture, with no horizon and no sky. It is one continuous stretch of ground, painted as a single picture. There are no roads, paths, bridges, rails, tracks or lines of any kind joining the places: open ground, dunes and rock outcrops lie between them. Each place stands on its own clear patch of ground, about a quarter of the picture wide and well apart from the others, and each patch's ground colour fades into the shared ground. The ground just in front of each place is plain. A strip of plain open ground runs round all four edges of the picture, about one-sixteenth of its width, with nothing standing on it and nothing cut off by the edge.

    The places:
    - Centre: the biggest landmark: stepped sandstone mesas with a natural sandstone arch, standing on the salt flat, with a cave-mouth gate at their foot.
    - Top left: a wavy rock wall standing in a flat, shallow flood pan, with the dead-level waterline crossing the wave at several evenly spaced points and a small flag staked at each crossing.
    - Top right: a ring of standing stones on cracked white salt, with one long arm pivoting from a post at the ring's centre out to its edge, and a plumb line hanging straight down from the arm's tip.
    - Left: a round stone floor cut into pie wedges like a cake, with one wedge lifted out and propped up on its edge, and a curved metal rim along its arc, on pale sandstone.
    - Right: a mason's yard of giant cut stone solids on plinths: a pyramid, a cone and a box, with a metal rod braced corner to corner through the box, on gravel.
    - Bottom left: a giant right-angled ramp cut out of a red rock mesa, with a ladder laid along its long sloping side, a square notch carved at the right angle and a plumb line hanging from the top.
    - Bottom right: a long sandstone ridge that rises and falls in an even, repeating wave across rippled dunes, with a scrap windwheel at its start.
    - Bottom: a small half-buried, boarded-up shack with a dead TV screen in its wall, much smaller than the other places.
    - Top: nothing, just open ground.

    Nothing else stands on the ground: no other buildings, no vehicles except those named, no people and no animals. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

### B3. Radio Spires board (Statistics and probability)

| Field | |
|---|---|
| Becomes | `game/assets/map/stats/background.webp` (1080 × 1920) and `background-wide.webp` (1920 × 1080) |
| Reference | [`overworld.png`](../../../game/assets/map/overworld.png), the world map (on the Paperclip card as `ref-01-world-map.png`) |
| Aspect | Square, 1:1 (scaled to 1080 × 1080 at intake) |
| Layout picture | `B3-layout-radio-spires.png` on the card, for checking only |
| Where things sit (tap zones) | Centre → `all`; Top → `sampling-data`; Top left → `conditional-probability`; Top right → `averages-spread`; Left → `normal-distribution`; Right → `regression`; Bottom left → `discrete-distributions`; Bottom right → `probability`; Bottom → `relic` |
| Keep clear | A plain margin round all four edges; the ground at the foot of each place, where the game draws its padlock or flag; open ground between places for the name card |
| Must not appear | Text, letters, numbers, symbols or logos; people or animals; roads, paths, rails or tracks between places; sky or a horizon |
| Fixable at intake | A wrong count (crates, cubes, drums), a stray mark, a thin edge |
| Not fixable | A missing place, a place that doesn't show its maths, a road between places, a place cut off by the edge |
| Prompt hash | `3969a442` |

**Prompt**

    Use the attached world map as the style reference and match its look exactly: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Use the same high three-quarter overhead camera as the map, but much closer in. Square picture, 1:1.

    This is a close-up of the Radio Spires from that map: dark basalt ground, black glass sand and grey ash. The ground fills the whole picture, with no horizon and no sky. It is one continuous stretch of ground, painted as a single picture. There are no roads, paths, bridges, rails, tracks or lines of any kind joining the places: open ground, dunes and rock outcrops lie between them. Each place stands on its own clear patch of ground, about a quarter of the picture wide and well apart from the others, and each patch's ground colour fades into the shared ground. The ground just in front of each place is plain. A strip of plain open ground runs round all four edges of the picture, about one-sixteenth of its width, with nothing standing on it and nothing cut off by the edge.

    The places:
    - Centre: the biggest landmark: the twin spires, dark basalt spires with radar dishes and a cold blue-violet glow, with a heavy gate at their base.
    - Top: a big heap of mixed, multicoloured scrap, with a crane grab lifting one small scoop out of it and a few small sorted bins beside it, on black glass sand.
    - Top left: a pipe that forks in two, then each branch forks in two again, with a valve on every branch and one path lit teal from the root to one end, on cable mats.
    - Top right: a long freight container on stilts, lying on its side, with a bulkhead across it off-centre and a long boom sticking straight out from each end, on grey ash with teal puddles.
    - Left: a tall board of pegs pouring ball bearings into a bell-shaped heap, high in the middle and low at both sides, on grey ash.
    - Right: short masts scattered loosely up a rising slope, with one long, straight, taut cable strung through the middle of them, on green copper-oxide crust.
    - Bottom left: a row of separate radio masts of stepped, uneven heights, standing side by side with gaps between them like the bars of a bar chart, on cracked basalt.
    - Bottom right: a huge pair of scrap dice with pips only, and a spinner wheel cut into coloured wedges with a pointer, on black glass sand.
    - Bottom: a small half-buried, boarded-up shack with a dead TV screen in its wall, much smaller than the other places.

    Nothing else stands on the ground: no other buildings, no vehicles except those named, no people and no animals. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

### B4. Engine Core board (Calculus)

| Field | |
|---|---|
| Becomes | `game/assets/map/calculus/background.webp` (1080 × 1920) and `background-wide.webp` (1920 × 1080) |
| Reference | [`overworld.png`](../../../game/assets/map/overworld.png), the world map (on the Paperclip card as `ref-01-world-map.png`) |
| Aspect | Square, 1:1 (scaled to 1080 × 1080 at intake) |
| Layout picture | `B4-layout-engine-core.png` on the card, for checking only |
| Where things sit (tap zones) | Centre → `all`; Top → `integration`; Top left → `derivative-rules`; Top right → `derivative-basics`; Left → `tangents-normals`; Right → `definite-integrals`; Bottom left → `kinematics`; Bottom right → `stationary-points`; Bottom → `relic` |
| Keep clear | A plain margin round all four edges; the ground at the foot of each place, where the game draws its padlock or flag; open ground between places for the name card |
| Must not appear | Text, letters, numbers, symbols or logos; people or animals; roads, paths, rails or tracks between places; sky or a horizon |
| Fixable at intake | A wrong count (crates, cubes, drums), a stray mark, a thin edge |
| Not fixable | A missing place, a place that doesn't show its maths, a road between places, a place cut off by the edge |
| Prompt hash | `942d8ff4` |

**Prompt**

    Use the attached world map as the style reference and match its look exactly: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Use the same high three-quarter overhead camera as the map, but much closer in. Square picture, 1:1.

    This is a close-up of the Engine Core from that map: an industrial crater of coal slag, rust and brass, lit by molten orange glow. The ground fills the whole picture, with no horizon and no sky. It is one continuous stretch of ground, painted as a single picture. There are no roads, paths, bridges, rails, tracks or lines of any kind joining the places: open ground, dunes and rock outcrops lie between them. Each place stands on its own clear patch of ground, about a quarter of the picture wide and well apart from the others, and each patch's ground colour fades into the shared ground. The ground just in front of each place is plain. A strip of plain open ground runs round all four edges of the picture, about one-sixteenth of its width, with nothing standing on it and nothing cut off by the edge.

    The places:
    - Centre: the biggest landmark: the engine, with smokestacks, a giant gear and molten orange glow, and a furnace-door gate at its foot.
    - Top: a stack of identical curved chutes, all the same shape, each one set higher than the last, feeding a tank, on coal slag and brass.
    - Top left: a train of linked gears, a big middle gear driving smaller ones, and a chain from the last gear to another pair, on riveted brass plate.
    - Top right: a curved ramp lined with small tilting plates on posts, each plate set to the ramp's slope at its post: flat at the top, steep on the side, on rust.
    - Left: a big curved steel rail with one straight girder touching it at a single point, and a post standing out square from the curve at that same point, on iron filings.
    - Right: a curved dam crest with two upright gates, where only the space under the curve between the two gates is flooded with glowing coolant, on black oil.
    - Bottom left: a short straight test rail inside its patch with a rocket cart mid-run, a row of marker posts beside it spaced further and further apart, and a dust trail behind, on coal slag.
    - Bottom right: a scrap rollercoaster track with one hill and one dip, a cart resting flat on the very top of the hill and another at the bottom of the dip, each beside a spirit level, on steam-wet mud.
    - Bottom: a small half-buried, boarded-up shack with a dead TV screen in its wall, much smaller than the other places.

    Nothing else stands on the ground: no other buildings, no vehicles except those named, no people and no animals. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

### B4P. Engine Core board, emptied (for technique B)

Run this right after each B4 image, in the same chat, so each Engine Core board comes back as a pair: `B4-1.png` and `B4-1-empty.png`. I use the empty one under cut-outs of the landmarks, so a gear can turn or a place can light up on its own. That's the B side of the A-or-B comparison, run on the Engine Core.

| Field | |
|---|---|
| Becomes | `game/assets/map/calculus/plate.webp` and `plate-wide.webp` (only if B wins) |
| Reference | The B4 image just made, in the same chat |
| Aspect | Square, 1:1, the same as the B4 image |
| Must not appear | Any of the places, or any new object; text; people |
| Passes when | Laid over its B4 image, the ground outside the places lines up: same edges, same colours, same light |
| Prompt hash | `64898476` |

**Prompt**

    Edit the Engine Core picture you just made. Remove every place from it: the engine with its smokestacks and gear, the stack of chutes, the gear train, the ramp of tilting plates, the curved rail and girder, the dam, the test rail and rocket cart, the rollercoaster and the shack. Where each one stood, paint only the open ground that would lie under it, in the same ground colour its patch had, so the picture shows the same ground with nothing on it. Keep everything else exactly as it was: the same camera, the same light and shadow direction, the same colours and the same edges, at the same square size. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos. No people.

### B5. Signal Tower board (Functions)

| Field | |
|---|---|
| Becomes | `game/assets/map/functions/background.webp` (1080 × 1920) and `background-wide.webp` (1920 × 1080) |
| Reference | [`overworld.png`](../../../game/assets/map/overworld.png), the world map (on the Paperclip card as `ref-01-world-map.png`) |
| Aspect | Square, 1:1 (scaled to 1080 × 1080 at intake) |
| Layout picture | `B5-layout-signal-tower.png` on the card, for checking only |
| Where things sit (tap zones) | Centre → `all`; Top → `lines`; Top left → `composite-inverse`; Top right → `transformations`; Left → `function-basics`; Right → `graphs-features`; Bottom left → `quadratics`; Bottom right → `exp-log`; Bottom → `rational`; Far left, between the left place and the bottom-left place → `relic` |
| Keep clear | A plain margin round all four edges; the ground at the foot of each place, where the game draws its padlock or flag; open ground between places for the name card |
| Must not appear | Text, letters, numbers, symbols or logos; people or animals; roads, paths, rails or tracks between places; sky or a horizon |
| Fixable at intake | A wrong count (crates, cubes, drums), a stray mark, a thin edge |
| Not fixable | A missing place, a place that doesn't show its maths, a road between places, a place cut off by the edge |
| Prompt hash | `305990c4` |

**Prompt**

    Use the attached world map as the style reference and match its look exactly: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Use the same high three-quarter overhead camera as the map, but much closer in. Square picture, 1:1.

    This is a close-up of the Signal Tower from that map: one continuous wasteland plateau around the tower. The ground fills the whole picture, with no horizon and no sky. It is one continuous stretch of ground, painted as a single picture. There are no roads, paths, bridges, rails, tracks or lines of any kind joining the places: open ground, dunes and rock outcrops lie between them. Each place stands on its own clear patch of ground, about a quarter of the picture wide and well apart from the others, and each patch's ground colour fades into the shared ground. The ground just in front of each place is plain. A strip of plain open ground runs round all four edges of the picture, about one-sixteenth of its width, with nothing standing on it and nothing cut off by the edge.

    The places:
    - Centre: the biggest landmark: the Signal Tower, a tall lattice antenna tower with satellite dishes and a teal glow, on its mesa, with a heavy gate at its foot.
    - Top: a white salt pan with one short, dead-straight rail line that starts and ends inside the patch at buffer stops, and a tilted slope-marker post beside it.
    - Top left: two small mirror-image train yards, one lit magenta and one lit teal, reflected across a diagonal line, with a short train in each, one heading in and one heading out; their short tracks stay inside the patch.
    - Top right: a tailor's market, a row of stalls with the same patterned banner on each: shifted along, then stretched, then flipped upside down.
    - Left: a machine with a chute going in at the top, a big lever, a chute coming out, and a wall of sockets behind it.
    - Right: a surveyor's flat with two giant girders meeting at a right angle, staked into the ground like graph axes, and a bent wire curve across them, with small flags on the curve's peaks and where it crosses the girders.
    - Bottom left: a shell crater with a huge parabola-shaped arch spanning it, and a ramp under the arch that rises and falls.
    - Bottom right: a drowned vault district with a spiral pipe that coils tighter and taller, beside flooded steps that double in height each step.
    - Bottom: a ration depot where two long walls run toward each other and nearly meet but never touch, leaving a narrow gap.
    - Far left, between the left place and the bottom-left place: a small half-buried, boarded-up shack with a dead TV screen in its wall, much smaller than the other places.

    Nothing else stands on the ground: no other buildings, no vehicles except those named, no people and no animals. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

## W1. World map, landscape for PC (#199, FAL-1049)

| Field | |
|---|---|
| Becomes | `game/assets/map/overworld-wide.webp`, 1920 × 1080 |
| Reference | [`overworld.png`](../../../game/assets/map/overworld.png), the world map (on the Paperclip card as `ref-01-world-map.png`). Best run in the chat where you made it |
| Aspect | Wide, 16:9 |
| Where things sit | Three rows, left to right: Scrap Fields, Signal Tower / Dry Flats, Thunderdome, Radio Spires / Bazaar, Engine Core, Relic Library. The game puts a name banner and a pin on each, measured from the picture |
| Keep clear | The top eighth (the header and banners); every place well inside the edges |
| Must not appear | Text, letters, numbers, symbols or logos; people; roads or tracks between places |
| Not fixable | A missing place, or one that a player of the tall map wouldn't recognise |
| Prompt hash | `8687db54` |

**Prompt**

    Use the attached world map. Make the same map again as a wide landscape picture, 16:9, in exactly the same look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Use the same high three-quarter overhead camera, with sky haze along the top. Keep all eight places and their looks from the attached map, so that a player who knows the tall map recognises every one, and spread them across the width in the same order:
    - Top row, left: the Scrap Fields, a mountain of wrecked trucks and buses with a yellow lattice crane on top.
    - Top row, right: the Signal Tower, a lattice antenna tower with satellite dishes and a teal glow, on its mesa.
    - Middle row, left: the Dry Flats, a white cracked salt flat with sandstone mesas and arches.
    - Middle row, centre: the Thunderdome, a round scrap arena with a magenta neon ring.
    - Middle row, right: the Radio Spires, jagged dark basalt spires with radar dishes and a blue-violet glow.
    - Bottom row, left: the Bazaar, a junk caravan of trucks and market stalls with a windwheel.
    - Bottom row, centre: the Engine Core, a crater with smokestacks, a giant gear and molten orange lava.
    - Bottom row, right: the Relic Library, a half-buried concrete bunker with a round vault door.
    One continuous desert with dunes, cracked earth and rock outcrops between the places, and dust storms soft at the far left and right edges. There are no roads, paths, bridges or tracks between the places. Keep the top eighth of the picture calm sky haze with nothing in it, and keep every place well inside the picture, clear of the edges. No people. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

## Fight backdrops

Each backdrop is the same place as on its board, seen from ground level, behind the fight screen. The game washes it darker and puts the question text over the lower part, so it has to be dark and quiet there. A phone held upright shows only the middle third, so the place must fit there.

Every backdrop card has the same fields:

| Field | |
|---|---|
| Becomes | `game/assets/regions/<region>/backdrop.webp`, 1920 × 1080 |
| Reference | [`overworld.png`](../../../game/assets/map/overworld.png), the world map (on the Paperclip card as `ref-01-world-map.png`) |
| Aspect | Wide, 16:9 |
| Where things sit | The place in the middle third (x 660 to 1260 of 1920), its base about halfway down |
| Keep clear | The bottom two-fifths: plain dark ground for the question text |
| Must not appear | Text, letters, numbers, symbols or logos; people, animals or characters; bright lights in the bottom two-fifths |
| Fixable at intake | A small bright spot (rolled off), a stray mark, a crop to 16:9 |
| Not fixable | The place outside the middle third, a busy or bright lower part, a place that doesn't show its maths |

### Dry Flats

#### DF1. Wedge quarry (`triangles`)

Becomes `game/assets/regions/triangles/backdrop.webp`. Prompt hash `add8ce47`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Dry Flats from that map (a white cracked salt flat with sandstone mesas and arches), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: a giant right-angled ramp cut out of a red rock mesa, with a ladder laid along its long sloping side, a square notch carved at the right angle and a plumb line hanging from the top, on red rock. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### DF2. Wave rocks (`trig-graphs`)

Becomes `game/assets/regions/trig-graphs/backdrop.webp`. Prompt hash `a605915d`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Dry Flats from that map (a white cracked salt flat with sandstone mesas and arches), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: a long sandstone ridge that rises and falls in an even, repeating wave across rippled dunes, with a scrap windwheel at its start. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### DF3. Sundial floor (`arcs-sectors`)

Becomes `game/assets/regions/arcs-sectors/backdrop.webp`. Prompt hash `03840982`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Dry Flats from that map (a white cracked salt flat with sandstone mesas and arches), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: a round stone floor cut into pie wedges like a cake, with one wedge lifted out and propped up on its edge and a curved metal rim along its arc, on pale sandstone slabs. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### DF4. Mason's yard (`geometry-3d`)

Becomes `game/assets/regions/geometry-3d/backdrop.webp`. Prompt hash `86e9f71c`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Dry Flats from that map (a white cracked salt flat with sandstone mesas and arches), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: giant cut stone solids on stone plinths: a pyramid, a cone and a box, with a metal rod braced corner to corner through the box, on gravel. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### DF5. Flooded wave canyon (`trig-equations`)

Becomes `game/assets/regions/trig-equations/backdrop.webp`. Prompt hash `4520f260`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Dry Flats from that map (a white cracked salt flat with sandstone mesas and arches), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: a wavy rock wall standing in a flat, shallow flood pan, with the dead-level waterline crossing the wave at several evenly spaced points and a small flag staked at each crossing. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### DF6. Stone ring (`unit-circle`)

Becomes `game/assets/regions/unit-circle/backdrop.webp`. Prompt hash `c8034e34`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Dry Flats from that map (a white cracked salt flat with sandstone mesas and arches), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: a ring of standing stones on a cracked white salt pan, with one long arm pivoting from a post at the ring's centre out to its edge and a plumb line hanging straight down from the arm's tip. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### DF7. The foot of the mesas (`all-geometry`)

Becomes `game/assets/regions/all-geometry/backdrop.webp`. Prompt hash `faa295b8`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Dry Flats from that map (a white cracked salt flat with sandstone mesas and arches), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: the foot of the stepped sandstone mesas, with a natural sandstone arch above and a cave-mouth gate in the middle. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

### Radio Spires

#### RS1. Mast row (`discrete-distributions`)

Becomes `game/assets/regions/discrete-distributions/backdrop.webp`. Prompt hash `16f63e00`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Radio Spires from that map (dark basalt ground, black glass sand and grey ash), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: a row of separate radio masts of stepped, uneven heights, standing side by side with gaps between them like the bars of a bar chart, on cracked basalt. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### RS2. Gambling den (`probability`)

Becomes `game/assets/regions/probability/backdrop.webp`. Prompt hash `a9393294`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Radio Spires from that map (dark basalt ground, black glass sand and grey ash), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: a huge pair of scrap dice with pips only, and a spinner wheel cut into coloured wedges with a pointer, on black glass sand. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### RS3. Ball mill (`normal-distribution`)

Becomes `game/assets/regions/normal-distribution/backdrop.webp`. Prompt hash `84cab582`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Radio Spires from that map (dark basalt ground, black glass sand and grey ash), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: a tall board of pegs pouring ball bearings into a bell-shaped heap, high in the middle and low at both sides, on grey ash. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### RS4. Antenna field (`regression`)

Becomes `game/assets/regions/regression/backdrop.webp`. Prompt hash `025ebeff`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Radio Spires from that map (dark basalt ground, black glass sand and grey ash), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: short masts scattered loosely up a rising slope, with one long, straight, taut cable strung through the middle of them, on green copper-oxide crust. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### RS5. Valve tree (`conditional-probability`)

Becomes `game/assets/regions/conditional-probability/backdrop.webp`. Prompt hash `17609778`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Radio Spires from that map (dark basalt ground, black glass sand and grey ash), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: a pipe that forks in two, then each branch forks in two again, with a valve on every branch and one path lit teal from the root to one end, on cable mats. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### RS6. Box on stilts (`averages-spread`)

Becomes `game/assets/regions/averages-spread/backdrop.webp`. Prompt hash `46b8d2bc`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Radio Spires from that map (dark basalt ground, black glass sand and grey ash), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: a long freight container on stilts, lying on its side, with a bulkhead across it off-centre and a long boom sticking straight out from each end, on grey ash with teal puddles. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### RS7. Sorting yard (`sampling-data`)

Becomes `game/assets/regions/sampling-data/backdrop.webp`. Prompt hash `c59cb688`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Radio Spires from that map (dark basalt ground, black glass sand and grey ash), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: a big heap of mixed, multicoloured scrap, with a crane grab lifting one small scoop out of it and a few small sorted bins beside it, on black glass sand. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### RS8. The foot of the twin spires (`all-stats`)

Becomes `game/assets/regions/all-stats/backdrop.webp`. Prompt hash `fa32949e`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Radio Spires from that map (dark basalt ground, black glass sand and grey ash), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: the base of the twin dark basalt spires, with radar dishes high above, a cold blue-violet glow and a heavy gate in the middle, on cable mats and ash. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

### Engine Core

#### EC1. Test rail (`kinematics`)

Becomes `game/assets/regions/kinematics/backdrop.webp`. Prompt hash `7e639c7a`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Engine Core from that map (an industrial crater of coal slag, rust and brass, lit by molten orange glow), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: a short straight test rail with a rocket cart mid-run, a row of marker posts beside it spaced further and further apart, and a dust trail behind, on coal slag. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### EC2. Coaster (`stationary-points`)

Becomes `game/assets/regions/stationary-points/backdrop.webp`. Prompt hash `e0e6306c`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Engine Core from that map (an industrial crater of coal slag, rust and brass, lit by molten orange glow), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: a scrap rollercoaster track with one hill and one dip, a cart resting flat on the very top of the hill and another at the bottom of the dip, each beside a spirit level, on steam-wet mud. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### EC3. Bending yard (`tangents-normals`)

Becomes `game/assets/regions/tangents-normals/backdrop.webp`. Prompt hash `9a904530`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Engine Core from that map (an industrial crater of coal slag, rust and brass, lit by molten orange glow), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: a big curved steel rail with one straight girder touching it at a single point, and a post standing out square from the curve at that same point, on iron filings. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### EC4. Sluice (`definite-integrals`)

Becomes `game/assets/regions/definite-integrals/backdrop.webp`. Prompt hash `c588e463`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Engine Core from that map (an industrial crater of coal slag, rust and brass, lit by molten orange glow), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: a curved dam crest with two upright gates, where only the space under the curve between the two gates is flooded with glowing coolant, on black oil. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### EC5. Gearbox (`derivative-rules`)

Becomes `game/assets/regions/derivative-rules/backdrop.webp`. Prompt hash `1a9fcfb4`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Engine Core from that map (an industrial crater of coal slag, rust and brass, lit by molten orange glow), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: a train of linked gears, a big middle gear driving smaller ones, and a chain from the last gear to another pair, on riveted brass plate. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### EC6. Slope gauges (`derivative-basics`)

Becomes `game/assets/regions/derivative-basics/backdrop.webp`. Prompt hash `bbd0684c`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Engine Core from that map (an industrial crater of coal slag, rust and brass, lit by molten orange glow), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: a curved ramp lined with small tilting plates on posts, each plate set to the ramp's slope at its post: flat at the top, steep on the side, on rust. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### EC7. Chute stack (`integration`)

Becomes `game/assets/regions/integration/backdrop.webp`. Prompt hash `de9fc727`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Engine Core from that map (an industrial crater of coal slag, rust and brass, lit by molten orange glow), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: a stack of identical curved chutes, all the same shape, each one set higher than the last, feeding a tank, on coal slag and brass. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.

#### EC8. The furnace gate (`all-calculus`)

Becomes `game/assets/regions/all-calculus/backdrop.webp`. Prompt hash `86cee9ca`.

    Use the attached world map as the style reference and match its look: a detailed hand-inked comic illustration with crisp dark outlines, painted cel shading with fine hatching in the shadows, a hard high sun, a sun-baked palette of rust orange and dust yellow with scrap-teal and bazaar-magenta accents; post-apocalyptic but hopeful, everything built from scrap, rust and neon tubes. Wide landscape picture, 16:9.

    A view from ground level of one place in the Engine Core from that map (an industrial crater of coal slag, rust and brass, lit by molten orange glow), at late dusk under a dark sky. The light is low and dim, so the whole picture is dark, and the place's own lights are the only bright spots. The place: the foot of the engine, with smokestacks rising above, a giant gear and molten orange glow, and a furnace-door gate in the middle. It stands in the middle third of the picture, small enough that all of it fits inside that middle third, with its base about halfway down the picture. The bottom two-fifths of the picture is plain, dark, open ground with nothing on it: flat, quiet colour, no rocks, tracks, lights or detail. The left and right thirds hold only quiet, dim background: distant dunes, rock and dark sky.

    No people, no animals and no characters. No roads or paths. No text, letters, numbers or symbols anywhere, not even on signs, crates or machines, and no logos.
