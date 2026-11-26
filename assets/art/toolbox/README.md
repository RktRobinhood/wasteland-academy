# Wasteland Academy art toolbox

An art-only shelf. The integration team can select, adapt, crop, animate or leave any item here. **Do not merge this branch or import the whole folder.** Bring only the selected exports into a normal issue-linked game PR. Masters and previews do not belong in the shipped build.

## Pick a piece

| Zone / set | What is available | Where to start |
|---|---|---|
| Scrap Fields · Living map 01 | Separately layered rotor and fixed post, canonical phone/desktop placement previews, full-resolution masters. An extra crusher cube is kept as a candidate. | [Kit instructions](scrap-fields/kit-01/README.md) · [Asset manifest](scrap-fields/kit-01/manifest.json) · [Phone preview](scrap-fields/kit-01/previews/scrap-fields-phone-proof.png) |
| Scrap Fields · Journey lane | Next production set: far salvage skyline, mid Sequences crusher and stacks, quiet treadable near edge. Status is tracked below; no incomplete strip is marked importable. | [Pipeline and zone coverage](coverage.md) |

**Ready to integrate** means the artwork and individual files passed visual/file review. It does not mean the interaction is wired, reviewed in Godot or live. **Art candidate** means do not import before the noted art check passes. A preview never becomes a runtime file.

## Hand-off contract

1. Pick the intended asset and its exact export, not the flattened proof or master. Check the per-kit placement, pivots, alpha, size, source and current dependency.
2. Preserve working stories, places, hotspots, curriculum eligibility and controls. Do not add a puzzle, route or reward to make a decorative overlay useful.
3. Fit in Godot at phone and desktop size, test pointer/touch/keyboard where applicable, reduced motion, focus conflicts and export size. Existing approved board and fallback stay intact until the imported slice is reviewed.
4. If another layer or pose is needed, leave the concrete brief on the linked resource issue. Art production provides the image; the integration workflow can handle slicing, optimizing and wiring. Prefer reusing this shelf over commissioning a new scene when the existing art works.

Source basis: repository main `1423ce06030f61fa9ae7563c9d8cd1946b134d32`, [Art Requirements](https://github.com/RktRobinhood/wasteland-academy/blob/1423ce0/ART_REQUIREMENTS.md), [ADR-0003](https://github.com/RktRobinhood/wasteland-academy/blob/1423ce0/docs/adr/0003-map-runs-bounties.md) and [ADR-0006](https://github.com/RktRobinhood/wasteland-academy/blob/1423ce0/docs/adr/0006-event-driven-villains-and-regional-story.md). The shelf has no effect on the student game or release.
