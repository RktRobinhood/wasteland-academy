# ADR-0008: Shared art, responsive composition

- Status: **Accepted**, 2026-11-27.
- Scope: visual presentation of the existing Godot game. This decision does not change map geography, progression, course eligibility, routes or saves ([ADR-0003](0003-map-runs-bounties.md)).

## Context

Desktop playtests exposed a portrait map floating in a wide window, persistent place labels covering the illustration, and scenery that looked static. Scaling that same arrangement down or up does not solve the problem. Subset Games kept the content of *Into the Breach* intact while redesigning touch interaction; Playdigious describes adapting the *Dead Cells* mobile interface and checking texture and memory costs separately. We take the same separation of content, layout, and input from those examples, not their particular layouts.

## Decision

1. **One Godot project and one source art library.** Reuse characters, props, icons, animation sheets and shareable environment layers. Make portrait and landscape compositions only where the camera materially changes what can be seen, starting with the title and maps. Choose by usable viewport aspect ratio, not device name. Reframe or extend scenery rather than stretching the painting or shrinking a desktop UI onto a touch screen.
2. **Keep interaction separate from illustration.** Register map anchors and hit areas to each composition. Controls and labels remain native Godot UI. Reveal names on mouse hover, keyboard focus or a first touch tap; keep touch confirmation and original routes. On the overworld, the painted landmarks are the click targets: no permanent dots, progress pins, labels or last-location flash over the art. Reveal progress in the same interaction card. Regional activity indicators are unchanged. Preserve saved travel and the distinct suggested-activity indication.
3. **Animate the place, not the interface.** Use lightweight reusable layers such as a bird crossing the title or smoke drifting from a painted stack. Optional pointer or touch reactions must not capture taps, shift hit areas, affect play, or be required to understand the scene. Reduced motion must still show an intentional static composition. Keep primary actions, captions and mathematics stable and legible.
4. **Budget the first load separately.** Keep the on-demand landscape files out of the Web boot pack. Fetch a versioned same-origin landscape only when appropriate to the current map, cache valid responses, and retain a playable portrait fallback offline or when art fails. A portrait session does not fetch unused wides. Check native texture imports, package size and actual loading behavior before adding effects or high-resolution variants.

## Review and consequences

- Test the exported game at short phone (320×568), tall phone (390×844), compact desktop (900×650), common landscape (1280×720 or 1440×900) and rotation when the scene supports it. Inspect actual framing, text contrast, target sizes, back navigation and reduced motion. Test mouse, keyboard and touch; distinguish emulation from a physical-device check.
- For optional assets, verify cold loads, invalid or missing responses, and offline fallback. A playable preview is not a release: use the normal checks, merge to main, and confirm the exact deployed build.
- Different compositions add a registration and visual review cost. Prefer reuse until the picture or interaction actually requires a different layout. The current implementation work is tracked in [#226](https://github.com/RktRobinhood/wasteland-academy/issues/226), not marked as shipped by this ADR.

## References

- [Godot: Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html) and [Importing images](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html)
- [Subset Games: Into the Breach Advanced Edition and mobile](https://subsetgames.com/itb_ae.html)
- [Playdigious: How it ported Dead Cells to mobile](https://www.gamedeveloper.com/design/porting-i-dead-cells-i-to-mobile-an-in-depth-breakdown)
