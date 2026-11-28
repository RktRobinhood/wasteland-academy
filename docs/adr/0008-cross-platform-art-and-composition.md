# ADR-0008: Shared art, responsive composition

- Status: **Accepted**, 2026-11-27.
- Scope: visual presentation of the existing Godot game. This decision does not change map geography, progression, course eligibility, routes or saves ([ADR-0003](0003-map-runs-bounties.md)).

## Context

Desktop playtests exposed a portrait map floating in a wide window, persistent place labels covering the illustration, and scenery that looked static. Scaling that same arrangement down or up does not solve the problem. Subset Games kept the content of *Into the Breach* intact while redesigning touch interaction; Playdigious describes adapting the *Dead Cells* mobile interface and checking texture and memory costs separately. We take the same separation of content, layout, and input from those examples, not their particular layouts.

## Decision

1. **One Godot project and one source art library.** Reuse characters, props, icons, animation sheets and shareable environment layers. Make portrait and landscape compositions only where the camera materially changes what can be seen, starting with the title and maps. Choose by usable viewport aspect ratio, not device name. Reframe or extend scenery rather than stretching the painting or shrinking a desktop UI onto a touch screen.
2. **Keep interaction separate from illustration.** Register map anchors and hit areas to each composition. Controls and labels remain native Godot UI. Reveal names on mouse hover, keyboard focus or a first touch tap; keep touch confirmation and original routes. Do not draw persistent place labels or a last-location flash over the art. Preserve saved travel and the distinct suggested-activity indication.
3. **Animate the place, not the interface.** Use lightweight reusable layers such as a bird crossing the title or smoke drifting from a painted stack. Optional pointer or touch reactions must not capture taps, shift hit areas, affect play, or be required to understand the scene. Keep primary actions, captions and mathematics stable and legible. During a maths prompt the camera and scenery travel hold still, regardless of settings.
4. **Budget the first load separately.** Keep the on-demand landscape files out of the Web boot pack. Fetch a versioned same-origin landscape only when appropriate to the current map, cache valid responses, and retain a playable portrait fallback offline or when art fails. A portrait session does not fetch unused wides. Check native texture imports, package size and actual loading behavior before adding effects or high-resolution variants.

## Amendment: one animation experience (2026-11-27)

The owner chose a single modern 2D scrapyard-comic experience for the overworld and all five zones. Use distinct silhouettes, layered scenery and smoother movement; prove this in Dry Flats before reusing the approach. Retire the separate Reduced Motion setting and alternate presentation path rather than authoring, tuning or maintaining two versions. Keep one set of assets and one animation timeline for each scene.

The common treatment itself stays calm: no sustained camera shake or rapid flashing, and no travel or ambient foreground movement that competes with the question. Remove the legacy preference without invalidating older saves, disturbing other accessibility settings, or changing timing, grading or rewards. This amendment records the accepted decision, not completion of the cleanup.


## Review and consequences

- Test the exported game at short phone (320×568), tall phone (390×844), compact desktop (900×650), common landscape (1280×720 or 1440×900) and rotation when the scene supports it. Inspect actual framing, text contrast, target sizes, back navigation, animation cadence, and the transition into a quiet maths prompt. Test mouse, keyboard and touch; distinguish emulation from a physical-device check.
- For optional assets, verify cold loads, invalid or missing responses, and offline fallback. A playable preview is not a release: use the normal checks, merge to main, and confirm the exact deployed build.
- Different compositions add a registration and visual review cost. Prefer reuse until the picture or interaction actually requires a different layout. The current implementation work is tracked in [#226](https://github.com/RktRobinhood/wasteland-academy/issues/226), not marked as shipped by this ADR.

## Amendment: painted overworld landmarks (2026-11-28)

The owner chose the painted landmarks themselves as the overworld controls. Do not layer persistent dots, progress flags, locked icons, labels, or a last-location marker over them. Progress stays in the same card shown on hover, keyboard focus or first touch. The owner extended this to all five zone boards. Both world and zone paintings are free of persistent dots, rings, flags and locks. Suggestions and activity states are in the same on-demand cards; all registered click/tap areas are unchanged.

## Amendment: local daylight on artwork (2026-11-28)

The overworld, zone boards and fight scenery share a stylised device-local daylight palette. Dawn and dusk blend gradually. No location, network or save data is needed. Apply colour to the artwork only: keep labels, focus, hit regions, actors and the maths panel outside the grade. The overworld lights come from painted sources: furnace and lava, shop lanterns, a scrapyard gate and radio equipment. Register their shape and position independently on portrait and landscape art, share one cheap falloff texture, and use the same device-clock palette. Lava may breathe slowly, never flash. No light should read as a new map marker or take input.

Hold the scene grade while a fight question is open, then ease toward the current time after submission. Existing alternate Journey paintings are selected when a battle opens. This slice does not morph between those paintings during combat, add a new settings mode or promise distinct artwork for every region. Test dusk in the same open scene and after a fresh entry, as well as dark landmark activation on desktop and phone.

## References

- [Godot: Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html) and [Importing images](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html)
- [Subset Games: Into the Breach Advanced Edition and mobile](https://subsetgames.com/itb_ae.html)
- [Playdigious: How it ported Dead Cells to mobile](https://www.gamedeveloper.com/design/porting-i-dead-cells-i-to-mobile-an-in-depth-breakdown)


### Zone ambience and destination discovery

Each painted zone board gets one short visual cue belonging to that location: a low welding glow in Scrap Fields, a slow tower signal, wind over the Dry Flats salt, a circling scout over Radio Spires and interactive furnace smoke at Engine Core. Author the cue's anchor in both compositions; grade that layer with the artwork, keep it behind the landmark buttons and do not spend new boot bytes on duplicate textures. Use established movement and smoke-input handling, not per-zone UI or new game mechanics. On desktop, use the pointing-hand cursor only over actionable places; on touch, keep the first tap's place card before the second tap enters. Closed locations, keyboard focus, existing suggested activities and route/save IDs are unchanged.

If the viewport or asynchronously loaded composition changes during the zoom back to a map, settle at the new frame. An obsolete tween must not slide the new painting and hit areas off-centre.


### Object-source lighting stays 2D

Use a compact glow at each emitter and a separately shaped light footprint on the rock, sand or metal that receives it. Orient and size the footprint in each painting; fade it at the edges and leave the shadow side of the landmark alone. Gate, lantern, furnace and lava lights share the existing clock and blend; avoid a brighter global grade, point markers, real geometry or a second set of high-resolution map images. There is no decorative location dot on the no-art fallback either.


### Living light on painted maps

Keep the painted layers. Anchor each emitter in the image; animate light on its receiving surfaces, not the emitter's position or the whole screen. Furnace, lava and welding use smooth, irregular heat flicker; a radio lamp slowly sweeps its ground footprint; lanterns shift more gently and security doors stay steady. Reuse the same blend and daylight sampler for the world and all five boards. Do not add new art downloads, map markers, or rapid flashes. Do not apply this motion to the maths panel.
