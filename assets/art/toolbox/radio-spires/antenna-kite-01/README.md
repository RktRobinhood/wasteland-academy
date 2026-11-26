# Antenna Kite

Original biomechanical flyer candidate. Separate near and far root/tip articulation. Calm 2 s idle at 8 fps; optional one-shot 0.67 s dodge at 12 fps; static fallback. Common origin (141,212) in the virtual 320×232 pose canvas; packed rects use individual offsets, facing left, 80 strip units; scale is fixed using maximum idle wing span. Calm idle or still only while a question is open. Does not include attack, hurt or defeated. Phone GIF uses an existing background crop and is not a game screenshot.

[Export](exports/antenna-kite.webp) · [Animated WebP preview](previews/idle-and-dodge.webp) · [Manifest](manifest.json)

Source: [pinned game tree](https://github.com/RktRobinhood/wasteland-academy/tree/d987d5f634c1dee1bb1b6b60a2b26e836cfc0b2d). Nothing wired or deployed.

**Runtime:** use the single-image WebP atlas and JSON; it imported and sliced through Godot 4.7.2. Animated WebP and the older GIF are previews only. Neither imported as animation in the same isolated native test.

Packed atlas: 676×615, about 77% fewer texture pixels than the original 1920×928 grid. Keep one texture with the per-frame JSON rectangles and origins; the 16-frame idle and 8-frame one-shot timings, alpha and placement do not change. [Same-size image comparison](previews/atlas-comparison.jpg). This is a texture-footprint improvement, not an in-game FPS claim.

## First Journey trial (handoff, not gameplay code)

**Recommended first use: a quiet ambient fly-by in a supported strip.** On [audited main](https://github.com/RktRobinhood/wasteland-academy/tree/d987d5f634c1dee1bb1b6b60a2b26e836cfc0b2d), the [regional creature loader](https://github.com/RktRobinhood/wasteland-academy/blob/d987d5f634c1dee1bb1b6b60a2b26e836cfc0b2d/game/journey/journey_assets.gd#L125-L130) requires an attack animation, and the [ordinary idle draw](https://github.com/RktRobinhood/wasteland-academy/blob/d987d5f634c1dee1bb1b6b60a2b26e836cfc0b2d/game/journey/journey_stage.gd#L609-L622) picks the first atlas frame and adds scale breathing. Copying the current art to a regional combat folder will not show the articulated idle. Do not rename dodge to attack or replace a shared rank sheet. If the approved use is combat instead, request distinct attack, hurt and defeated art before wiring the roster.

In one actual student run on a representative school phone or browser:
1. With a maths question open, advance the quiet wing loop on the same anchor at the intended strip size. Keep question/key focus undisturbed. Do not add scale pulsing over the authored movement.
2. If the selected encounter already has a suitable authored beat, exercise dodge once on that beat; otherwise leave it unwired. It must not recur while the learner reads.
3. Repeat in reduced motion: hold the same static pose, no dodge. Visually check first-frame placement, no clipping, no flashes or unreadable text.
4. Compare first appearance and question-open frame timing in the same scene, then check whether textures accumulate when switching biomes. The packed texture is about **2.11 MiB** versus **9.06 MiB** for the old grid under RGBA8 including the full mip chain; these are per-texture estimates, not measured browser or device memory. Avoid eagerly loading all future creature atlases.

This asset-only branch does not change scene behavior. A quiet, stable first integration should establish the convention before producing many more flying sets.
