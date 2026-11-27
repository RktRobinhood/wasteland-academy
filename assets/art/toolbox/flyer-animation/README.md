# In-place wing motion and dodge previews

Three starter motion kits for existing creature families, not new families: Pulley Wasp, Dune Cutwing and Canvas Ray. These are separate from the [35-family roster](../creature-library/roster.json). The earlier Antenna Kite art trial remains in its own kit.

Import `atlas.webp` and the relative `sprite-frames.tres` together into a candidate Godot scene. Each atlas has four deliberately drawn poses: neutral, upstroke, downstroke and bank. `hover` is a gentle approximately one-second loop at the same center anchor; `dodge` is a half-second single banking gesture that returns to neutral. 640×420 cells, left-facing, 320×210 hover pivot, no particles or extra draw calls. Keep the static neutral pose as the reduced-motion or low-quality fallback.

All three completed actual native Godot upstroke, downstroke, bank, recovery and re-loop tests, and a reimport after moving the assets. Use the separate `preview.webp` to inspect sequences outside Godot only. No changes to game timing, hit boxes, map positions or encounters.
