# Scrap Fields Journey · scenery kit 01

**Ready for an isolated scenery import trial. Not wired or live.** These are original hand-inked parallax layers, with cropped lossless WebP exports and editable source PNGs. The canonical steep crusher and ascending car stacks carry the identity of the Sequences landmark into a side-on working scrapyard. The stacks are scenery, not a labelled exercise or a new interaction. No story, reward or skill eligibility changes.

| Layer | Native export | Fit and purpose |
|---|---:|---|
| Far | 864 × 256, opaque | Quiet slate sky and a low-contrast salvage skyline; scroll ×0.15 |
| Mid | 864 × 256, alpha | Painted crusher, stacks and salvage. Content stays clear of both repeat edges; scroll ×0.45 |
| Near | 896 × 98, alpha | Quiet walkable hardpan, ground row 15; scroll ×1.0 |

[Full composition](previews/journey-full.png) · [390 px crop](previews/journey-phone-crop.png) · [Proposed layer manifest](exports/layers.json). Preview is a compositing proof, not a screenshot of the game. The source PNGs are for adapting/cutting individual layers; only the three exports and manifest are candidates to import. Total export art around 0.4 MB before Godot compression; remeasure the actual web build.

## Claude / integration hand-off

- Current main only resolves Functions to Signal Tower. This scenery has no effect until the integration owner elects to stage the chosen exports at the existing Journey asset discovery destination, adds an explicit Algebra-to-Scrap-Fields mapping (or a narrower path if warranted), and has the relevant avatar sheet. Follow the documented format and preserve the existing fallback.
- In the ordinary Sequences route, check the ground contact while walking at unchanged pace, scrolling across the wrap, no forced movement with reduced motion, readable sprites/feedback at phone and desktop widths, and no texture-size regression. Fit the view before adjusting layers; the still preview is not a layout spec.
- Do not make the crusher a scored obstacle or add a sequence-specific background trigger to other lessons without an intentional skill gate. This set requests no new plot. No art generation needed on the integration side.

References: canonical Scrap Fields board and Sequences backdrop at 1423ce06030f61fa9ae7563c9d8cd1946b134d32, assets/art/intake/algebra/life-pack.md, assets/journey/README.md, ADR-0003/0006 and AA SL 1.2.

## Art QA

All six exported images across the Journey and living-map kits imported and loaded as Texture2D in a clean Godot 4.7.2 test project. The scenery dimensions, alpha, 390 px crop and 864 px composition were checked. Across the wrap, the far edge matches and the near edge differs by at most 5/255 in any channel; mid runs out to transparent on both edges. The near layer has clear alpha before the walk surface and ground begins on the intended feet band. No live-game behavior or on-device contrast is claimed by this check.
