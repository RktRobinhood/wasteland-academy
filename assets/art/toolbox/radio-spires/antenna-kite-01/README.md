# Antenna Kite

Original biomechanical flyer candidate. Separate near and far root/tip articulation. Calm 2 s idle at 8 fps; optional one-shot 0.67 s dodge at 12 fps; static fallback. Common origin (141,212) in the virtual 320×232 pose canvas; packed rects use individual offsets, facing left, 80 strip units; scale is fixed using maximum idle wing span. Calm idle or still only while a question is open. Does not include attack, hurt or defeated. Phone GIF uses an existing background crop and is not a game screenshot.

[Export](exports/antenna-kite.webp) · [Animated WebP preview](previews/idle-and-dodge.webp) · [Manifest](manifest.json)

Source: [pinned game tree](https://github.com/RktRobinhood/wasteland-academy/tree/d987d5f634c1dee1bb1b6b60a2b26e836cfc0b2d). Nothing wired or deployed.

**Runtime:** use the single-image WebP atlas and JSON; it imported and sliced through Godot 4.7.2. Animated WebP and the older GIF are previews only. Neither imported as animation in the same isolated native test.

Packed atlas: 676×615, about 77% fewer texture pixels than the original 1920×928 grid. Keep one texture with the per-frame JSON rectangles and origins; the 16-frame idle and 8-frame one-shot timings, alpha and placement do not change. [Same-size image comparison](previews/atlas-comparison.jpg). This is a texture-footprint improvement, not an in-game FPS claim.
