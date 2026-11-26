# Antenna Kite

Original biomechanical flyer candidate. Separate near and far root/tip articulation. Calm 2 s idle at 8 fps; optional one-shot 0.67 s dodge at 12 fps; static fallback. Shared placement origin (141,212) per 320×232 cell, facing left, 80 strip units; scale is fixed using maximum idle wing span. Calm idle or still only while a question is open. Does not include attack, hurt or defeated. Phone GIF uses an existing background crop and is not a game screenshot.

[Export](exports/antenna-kite.webp) · [Animated WebP preview](previews/idle-and-dodge.webp) · [Manifest](manifest.json)

Source: [pinned game tree](https://github.com/RktRobinhood/wasteland-academy/tree/d987d5f634c1dee1bb1b6b60a2b26e836cfc0b2d). Nothing wired or deployed.

**Runtime:** use the single-image WebP atlas and JSON; it imported and sliced through Godot 4.7.2. Animated WebP and the older GIF are previews only. Neither imported as animation in the same isolated native test.
