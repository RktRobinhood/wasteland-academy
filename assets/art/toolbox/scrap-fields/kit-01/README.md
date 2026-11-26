# Wasteland Academy • Scrap Fields • Living map kit 01

**Status:** art handoff and visual prototype, not imported or enabled in game. Reviewed against Wasteland Academy main `1423ce06030f61fa9ae7563c9d8cd1946b134d32`.

## 1. Hubcap spinner — first integration candidate

The published Scrap Fields life-pack describes a handmade spinner roughly at (200, 1700) on the 1080 × 1920 map. This is the same placement, with the foot at (200, 1700), visual pivot at (200, 1577), and the rotor overlapping a fixed post. The files are independently layered:

| Asset | Source px | Suggested map size | Origin / placement |
|---|---:|---:|---|
| `scrap-hubcap-post-512.png` | 36 × 512 | about 13 × 186 | top-left (194, 1514); fixed |
| `scrap-hubcap-rotor-256.png` | 256 × 256 | 96 × 96 | centre (200, 1577); rotate only this layer |

Both are original RGBA artwork. No baked labels, player instructions or prizes. The yellow wedge shows rotation; the round wheel and straight post identify the object without relying on colour. Render the rotor above the post. Test a minimal foot contact shadow separately if needed; do not brighten this into a competing progression marker.

The cue is cosmetic only. Suggested one focus/tap target, a 156 × 156 logical minimum centred on the wheel (about 45 px if the 1080 px board fits a 320 px width); inspect actual window scaling before treating this as sufficient. Keep it outside the Sequences/Relic/navigation hit areas, no overlap with native focus, and don't attach any curriculum, reward or progress flag. The intake proposes a slow idle turn and a brief sped-up turn on tap; respect reduced motion, with a still rotor and an instant optional pose change instead of animation. Subject to current map-life wiring (#226 / FAL-1092) and actual Godot pointer, touch and keyboard checks.

## 2. Sequences crusher — candidate layer, not ready to wire as-is

`scrap-crusher-cube-256.png` is 256 × 233 px with alpha. Its silhouette echoes the board's crushed car and stacked arithmetic pattern (one more block per stack). Reference: AA SL 1.2, existing Sequences spot, and Mags' seating-row context in the written arithmetic-sequence explainer. This is environment storytelling, not a canonical new quest. Existing life-pack suggests a passive path near (340, 1075) to (340, 1110); validate against the actual landing point. **The published painting already includes a falling cube.** Do not stack this sprite over the baked cube or ship it until there is an independently reviewed clean patch/placement; do not intercept the Sequences hotspot. The static painted board is the continuity fallback.

## 3. Proof and next step

- `scrap-fields-phone-proof.png`: board framed at 390 px with the new hubcap.
- `scrap-fields-spin-detail.png`: second rotor pose on the same board.
- `scrap-fields-desktop-proof.png`: inset board scale; the margins represent available desktop space, not an interface redesign.
- These are compositions over the *actual* canonical background, not Godot runtime screenshots. No project code or live build was changed.
- Original source masters included for reuse; ship only the small RGBA sprite exports that pass visual/input/reduced-motion checks. Preserve the world map, labels and routes.
- Next useful expansion: first non-Functions Journey strip, starting with a Scrap Fields landscape pass. Preserve the authoring boundaries in ADR-0003/0006 and don't put sequence-specific puzzle props into the general Algebra pool without skill gating.

Sources: `assets/art/intake/algebra/life-pack.md`, `game/ui/map.gd` (algebra spots), `game/assets/map/algebra/background.webp`, `game/assets/regions/sequences/backdrop.webp`, `writing/explainers/ex.algebra.arithmetic-sequence.json`, `assets/journey/README.md`, ADR-0003 and ADR-0006. New prop art generated for this project with the public repository's board as visual reference; existing board belongs to the project and is present only in proof images.
