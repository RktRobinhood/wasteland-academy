# Battle backdrops: day / night toolbox

Artist handoff for Codex and Claude. This directory is additive art, **not an implemented game clock**. Nothing replaces a live asset or changes a scene.

Each `<biome>/<region>/pair.json` points to a new day relief and the unmodified existing dark plate as `day.webp` and `night.webp`. Some dark plates depict dusk. Use the exact region ID, including the playable all-region dungeon fallback IDs, with the canonical path and source checksums in the manifest. A file pair is available only when all three files are present. See [the region index](regions.json) for scope and location.

- Formats: 1920 × 1080 opaque WebP; new day files capped at 150 KiB. Same 16:9 cover framing; protect the mobile center and the fight-question text below 30% height.
- Lighting: recommended wash per pair applies to both ends and during a transition. Values use the native game background and text colours and the exact final WebPs, sampled during a dissolve on desktop and the 600 px phone crop. Do not assume 55% passes for every day plate. The optional higher values are recommendations using the game's existing backdrop API, not a code change.
- Motion: painted relights preserve landmark identity, but these are not claimed pixel-registered. Prefer a brief tinted dip, swap the backdrop, then lift the tint, rather than a long bare crossfade with visible double edges. With reduced motion use an immediate swap. Leave the HUD, positions and input unaffected. Load only the visible region's current plate; if preloading the other, do it asynchronously and release it after the transition.
- Initial integration can choose at scene entry and defer any clock-triggered change until after an active question; the new art is useful without deciding the clock design. Do not couple brightness, skill tags or a time phase to correctness, spawn rates or difficulty. Keep failing loads on the existing dark plate.
- This directory covers battle and region-floor backdrops, not the separate overworld or Journey parallax art. Existing candidate assets elsewhere in the toolbox remain intact.
