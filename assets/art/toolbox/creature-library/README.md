# Five-biome creature library

This shelf holds **30 new distinct creature designs** in addition to **five earlier families**: **35 total**, seven per biome. Shapes, animals, biomechanical bodies and motion roles differ. The names are working labels, not new lore, stats, encounters, quests or runtime replacements.

Pick a biome/species in [roster.json](roster.json). Each new kit has one left-facing static cutout, a source master and a light/dark scale proof. For runtime, select only `exports/idle.webp` (640×420 opaque subject with transparency around it), use the footprint/hover anchor in `manifest.json`, and test readability over both lighting phases of the real encounter. Native Godot loaded all 30 visible cutouts at the expected size and detected transparency. Source and proofs are not build assets.

Flyer silhouettes and mechanical designs should not implicitly share one animation or combat state. The STATIC label applies unless a separate figure's native idle/dodge proof is explicitly linked. Existing [creature notes](../creature-roster.md), [battle scenery](../day-night/README.md), and [navigation art](../navigation-day-night/README.md) remain separate.
