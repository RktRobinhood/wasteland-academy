# Local visual and engine checks

The atlas imports and renders as four native AtlasTexture regions per vehicle on Godot 4.7.2. Tested the existing cached project AmbientLayer (unmodified), not a new emulator: frames advance, holders drive at least 15 board px, horizontal facing flips on return, and reduced motion hides incidental vehicles. The layer does not take touch or mouse input.

Sampled each full 160×112 footprint over 240 equally spaced points through its optional portrait route, including both travel directions. None entered the 8 cached destination keepouts (including an extra 8 board px margin). This was a local compatibility check against the exact matching portrait day/night boards and cached 1423ce0 navigation zone rectangles, not a test of current live layout.

All three RGB/alpha edge silhouettes were checked on sand and on the matching night board. The authored warm art stays legible at ~60–74 board px, but the nighttime palette is intentionally not baked into the common atlas. If a later implementation already has a night environment shader, consider a gentle existing modulate on its vehicle art; no time or lighting behavior is part of this handoff.
