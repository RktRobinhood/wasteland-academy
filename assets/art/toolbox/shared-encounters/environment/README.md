# Wasteland Academy · Zone encounters: environment set 01

Five newly authored, **biome-specific** transparent environment props. These are asset intake candidates, not installed mechanics or a duplicate of the people/creature/vehicle libraries. The ordinary encounter, maths, difficulty, hitboxes, timers, resolved state, activation and rewards remain controlled by the existing encounter content and Godot owners.

| Biome / actual game folder | Prop | State and visual tell | Candidate setting |
|---|---|---|---|
| Scrap Fields / `algebra` | Jammed salvage roller | **Blocked.** Low rust beam and immobile teal cylinder span the way. | `sequences`; existing obstacle/disarm presentation if already supported. |
| Signal Tower / `functions` | Offline relay kiosk | **Offline.** Narrow utility silhouette; dark damaged lavender screen vs small locator. | `graphs-features`; repair/breakdown candidate. Not a replacement for Wynn's Live Wires encounter. |
| Dry Flats / `geometry` | Collapsed survey arch | **Blocked.** Pale angular sandstone wedges and survey prism; broad low blocked passage. | `geometry-3d`; obstacle/wayfinding candidate. |
| Radio Spires / `stats` | Toppled relay dish | **Offline.** Broken diagonal dish mast, lilac/charcoal salvage. | `sampling-data`; repair/breakdown candidate, distinct from Up the Mast or a flying enemy. |
| Engine Core / `calculus` | Blocked heat sluice | **Hot, blocked.** Thick refractory enclosure and a single contained amber band. | `definite-integrals`; fictional environmental hazard candidate. No operating information. |

## Install and present
- Copy only the chosen biome subdirectories into the existing toolbox. Stage images are straight-alpha 512×512 PNG with common canvas registration and ground anchor [256,442] (px from upper left), 0.5,0.86328125 normalized. Scale uniformly, never stretch; start at 112 screen px for a portrait/board excerpt. Keep layer behind interaction hitbox/labels; do not create a click target from image size.
- Each image portrays one authored active state. There is no fake loop, no pixels masquerading as a repaired alternate, and no code or new mechanics. If the existing content already exposes a resolved state, use its regular hide/fade or existing badge. Keep the matching ground anchor if a repaired alternate is later painted. Shape communicates the state independently of the hue.
- Only assets and handoff live in this folder. The day/night preview proves contrast/context by placing the same 112×112 scaled sprite on the exact documented source pair; coordinates are advisory proof, not a map or encounter placement. Nothing in the generator signposts real trap mechanisms, construction or disassembly.
- All five images were generated separately for this pack with OpenAI built-in ImageGen. One owned board per image was a material/palette reference, not an edit target. Cropping, registration and scaling only on delivery. See manifest.json for exact source/export digests and board identifiers. The QA contact sheet is separate from the runtime ZIP.
