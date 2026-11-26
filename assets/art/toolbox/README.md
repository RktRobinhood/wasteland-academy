# Wasteland Academy art toolbox

An art-only shelf. The integration team can select, adapt, crop, animate or leave any item here. **Do not merge this branch or import the whole folder.** Bring only the selected exports into a normal issue-linked game PR. Masters and previews do not belong in the shipped build.

## Pick a piece

| Zone / set | What is available | Where to start |
|---|---|---|
| Scrap Fields · Living map 01 | Separately layered rotor and fixed post, canonical phone/desktop placement previews, full-resolution masters. An extra crusher cube is kept as a candidate. | [Kit instructions](scrap-fields/kit-01/README.md) · [Asset manifest](scrap-fields/kit-01/manifest.json) · [Phone preview](scrap-fields/kit-01/previews/scrap-fields-phone-proof.png) |
| Scrap Fields · Journey lane | Complete three-layer scenery kit with editable masters, exports and a proposed layer manifest. Ready for an isolated import trial, not wired. | [Journey kit](scrap-fields/journey-01/README.md) · [Preview](scrap-fields/journey-01/previews/journey-full.png) |
| Scrap Fields · Copper Mite | Original left-facing creature, four grounded poses, optional cutout, measured alpha atlas. Ready for art trial, not wired. | [Monster kit](scrap-fields/copper-mite-01/README.md) · [390 px proof](scrap-fields/copper-mite-01/previews/phone-contrast.png) |
| Radio Spires · Regression battle | Original daylight alternate paired with the existing night reference. Not registered for animation. | [Battle kit](radio-spires/battle-regression-01/README.md) · [Comparison](radio-spires/battle-regression-01/previews/night-then-day.jpg) |

[Creature roster and named art audit](creature-roster.md) · [Antenna Kite flight preview](radio-spires/antenna-kite-01/previews/idle-and-dodge.webp) · [Kettle Runner map proof](scrap-fields/kettle-runner-01/previews/kettle-runner-phone-map.jpg)

[The Compounder portrait pair](scrap-fields/compounder-01/README.md) · [Dry Flats Glassback Lizard](dry-flats/glassback-lizard-01/README.md)

[Machine-readable inventory](inventory.json) · [Priorities and gaps](coverage.md)

**Ready to integrate** means the artwork and individual files passed visual/file review. It does not mean the interaction is wired, reviewed in Godot or live. **Art candidate** means do not import before the noted art check passes. A preview never becomes a runtime file.

## Hand-off contract

1. Pick the intended asset and its exact export, not the flattened proof or master. Check the per-kit placement, pivots, alpha, size, source and current dependency.
2. Preserve working stories, places, hotspots, curriculum eligibility and controls. Do not add a puzzle, route or reward to make a decorative overlay useful.
3. Fit in Godot at phone and desktop size, test pointer/touch/keyboard where applicable, reduced motion, focus conflicts and export size. Existing approved board and fallback stay intact until the imported slice is reviewed.
4. If another layer or pose is needed, leave the concrete brief on the linked resource issue. Art production provides the image; the integration workflow can handle slicing, optimizing and wiring. Prefer reusing this shelf over commissioning a new scene when the existing art works.

Source basis: repository main `1423ce06030f61fa9ae7563c9d8cd1946b134d32`, [Art Requirements](https://github.com/RktRobinhood/wasteland-academy/blob/1423ce0/ART_REQUIREMENTS.md), [ADR-0003](https://github.com/RktRobinhood/wasteland-academy/blob/1423ce0/docs/adr/0003-map-runs-bounties.md) and [ADR-0006](https://github.com/RktRobinhood/wasteland-academy/blob/1423ce0/docs/adr/0006-event-driven-villains-and-regional-story.md). The shelf has no effect on the student game or release.
