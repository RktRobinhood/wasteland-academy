# Map life: three salvage vehicles

**Art-toolbox candidates only.** No scripted encounters, player vehicle, camera changes, map changes or live wiring. These are small moving background details for the quiet approaches, not destinations or clickable objects.

| Sprite | Silhouette | Suggested use |
|---|---|---|
| Scrap buggy | A low, open orange cage and weathered teal nose | Crossing below Scrap Fields |
| Caravan runner | A taller yellow van, indigo shutters and a red roof roll | Bazaar foreground |
| Flats survey truck | Blue pickup carrying a folded dish | Dry Flats' outer ridge |

## Intake

- Each vehicle has one 640×112 transparent PNG atlas with four untrimmed 160×112 cells and same-stem TexturePacker JSON. The frames are ordered 00–03 at a gentle 6–7 fps. The near-side wheel hubs move without redrawing the chassis. Right-facing art; the existing layer mirrors left-facing travel. Separate lossless WebP masters, body cutouts and small contact-shadow PNGs are included for editing. Runtime uses the combined atlas only (one Sprite2D/texture reference per vehicle; no GIF/video decoder or per-frame image generation).
- The unmodified native `game/ui/ambient_layer.gd` expects `<sheet>-sheet.png` and matching JSON under `game/assets/ambient/`. If approved, copy the chosen pair there and merge only its entry from `portrait-routes.json` into the existing `game/data/ambient.json` map array. Do not replace other entries. The contact point is (80, 99) cell pixels. Mount below pins and destination buttons; the existing layer passes pointer/touch through. The recipe hides cosmetic traffic in reduced-motion mode. Use only one or two vehicles at once if a scene is already busy.
- Candidate routes use the exact 1080×1920 portrait board with the checked-in placement shown in the QA pair. They are not wide variants or an assumed latest-main layout: recheck the current hotspot coordinates and art before wiring, especially if the desktop board uses another crop. Wheels and routes work slowly on both matched day and night artwork. These assets do not detect clock time or tint the scene.

## Provenance

Three original vehicle illustrations were produced with the built-in ImageGen from separately authored prompts using the supplied Wasteland overworld solely as reference for perspective and ink/color style. There are no borrowed franchise designs, logos, characters or lettering. The game backgrounds are not included in this intake. Hub and shadow layers are local transforms for game use. Exact inputs, runtime atlas hashes and motion metadata are in `vehicle-inventory.json`.
