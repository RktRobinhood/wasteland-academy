# Warden Apex: Journey idle positioning study

The first left-facing, planted-foot standing pose for the existing named Quadratics boss, derived from our original Warden portrait. Use this to check silhouette, placement, and whether the tall radio-peak silhouette belongs in the Signal Tower strip. No replacement for the shared D5 sprite and no finale designation.

- **Preferred cutout:** [WebP atlas](exports/warden-journey-idle.webp), 179 by 356 pixels, 28,538 bytes, and [metadata](exports/warden-journey-idle.json). A lossless [PNG](exports/warden-journey-idle.png) and unaltered generated [master](masters/warden-journey-idle-original.png) are included.
- **Native check:** Godot 4.7.2 loaded the WebP as a transparent Texture2D in an isolated probe, extracted the rectangle, checked the foot-plane anchor and accepted the 124-unit display-height field. This is a static frame, not a GIF or a playback performance measurement.
- **Visual check:** [44 px / 88 px study](previews/warden-journey-placement.jpg) over the actual staged Signal Tower layers. The radio silhouette and instrument read better in open skyline; the torso blends into dense silhouettes at the smaller height. Trial foreground separation or a clearer camera position before shipping. These are simulated display sizes, not a captured phone session.
- **Do not wire as an enemy yet.** No walk, attack, hurt, defeated or phase sheets. The current Journey roster requires combat states, and this metadata intentionally exposes only non-looping idle. Keep reduced-motion still available. If chosen, use this anchor as the reference for the remaining state family and verify the correct per-region route.

Pinned [main](https://github.com/RktRobinhood/wasteland-academy/tree/0c71165191802645ca30357d2b783a2c569722a6). No integration or change to shipped art.
