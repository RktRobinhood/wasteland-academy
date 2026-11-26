# Scrap Fields · Copper Mite 01

One original local creature candidate, not a replacement for an existing D1–D5 enemy. Its broad copper shell, four rubber feet and single small teal eye give Scrap Fields distinctive salvage life without adding story or a curriculum gate. The art is compatible with the Scrap Fields Journey palette; it makes no claim about arithmetic sequences, rewards, or who the player must fight.

| Use | File | Status |
|---|---|---|
| Journey actor | [alpha WebP atlas](exports/copper-mite.webp) + [frame/animation JSON](exports/copper-mite.json) | Ready for isolated art trial; integration decision still needed |
| Compact encounter/card cutout | [256×256 PNG](exports/copper-mite-portrait.png) | Optional; no canonical portrait slot or D-rank mapping |
| Visual reference | [Desktop Journey proof](previews/journey-desktop.jpg) · [390-px contrast proof](previews/phone-contrast.png) | Static composites, not runtime/screenshots |
| Production | [Manifest](manifest.json) · [Exact prompts](PROMPTS.md) · [Checksums](SHA256SUMS) | Two unchanged original ImageGen masters |

The atlas has a wary idle, planted shove, recoil and shell-down pose. The last is visually nonviolent. All face left. Rectangles are trimmed from four 512×256 staging cells (overall atlas 2048×256); offsets align their grounded foot point to cell coordinate **(270, 244)**. The last solid-row contact is **243** for all four poses. The 228 px idle figure evaluates to 80 px on a Journey strip, with no alignment tween. Dark legs have less contrast on charcoal than on sand; the handheld proof shows this honestly.

There is no walk cycle, glow or baked shadow, and no hit/motion FX. Use explicit one-pose held states for an art trial; don't describe translation as a finished gait. The exact Godot loader scans, decodes, validates and classifies the sheet as a regional creature in isolation. Merely copying an attack sheet into a live region can place it in the candidate roster; do not copy it into the runtime until the integration owner opts in. Existing scenery/region mapping, supported skill gates and safe no-scroll/reduced-motion cues still require runtime review.

Reference: exact main `24e0fa4c390bfb7889fce048b32108e18a1fbf6f`, [Journey contract](https://github.com/RktRobinhood/wasteland-academy/blob/24e0fa4/assets/journey/README.md), [art direction](https://github.com/RktRobinhood/wasteland-academy/blob/24e0fa4/ART_REQUIREMENTS.md), [world map constraints](https://github.com/RktRobinhood/wasteland-academy/blob/24e0fa4/docs/adr/0003-map-runs-bounties.md). Current canonical shipped art remains untouched; masters and previews stay out of shipped builds.
