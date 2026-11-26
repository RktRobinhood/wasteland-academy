# The Compounder: neutral and hurt portraits

This pair fills both art states for one canonical named Scrap Fields boss, if selected. Start with [the registered comparison](previews/compounder-neutral-and-hurt.jpg): coat, gear wheel and hat stay seated while the expression reacts. Very subtle at 72 px; intended for the larger fight portrait, not a mini animated strip. Same canvas, no translation on swap, no graphic injury or baked flash.

Use [neutral PNG](exports/compounder.png) and [hurt PNG](exports/compounder-hurt.png) together; compact WebPs also provided. See [manifest](manifest.json). Preserve original art masters. In the current game, name/taunt may inherit from the algebra zone, but portrait lookup is by actual fight region; pick the intended region explicitly and verify it displays the named boss. Slot names are boss and boss-hurt in that region. Do not replace shared ranks or create a stage encounter just for the art. [Pinned resolver](https://github.com/RktRobinhood/wasteland-academy/blob/d987d5f634c1dee1bb1b6b60a2b26e836cfc0b2d/game/engine/art_slots.gd#L86-L115).

Alpha overlap 98.48% at the half-alpha threshold, verified neutral/hurt at native and phone scale, file import in isolated Godot; no game integration or runtime effects tested.
