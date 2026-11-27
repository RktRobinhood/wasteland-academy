# Enemy defeat · reusable Godot 4.7 AnimationLibrary

A non-gory, one-shot JRPG-style effect. `enemy-defeat.tres` contains:

| Clip | Duration | Visual behavior |
|---|---:|---|
| `defeat` | 0.72 s | Shake the art only (±6 design pixels) through 0.22 s. Settle and darken at full opacity through 0.40 s, then briefly hold an almost-black silhouette. Fade it to zero alpha from 0.435 s. No flash, rotation, or scale change. |
| `fade_only` | 0.50 s | Reduced-motion alternative. Keep the original color and position; fade only the art’s opacity. |
| `reset_visual` | instant first key | Restore zero local offset and white/opaque modulation, including after interruption. |

## Integration

Use the game’s existing defeated result and reduced-motion setting. Do not tie answers, rewards or screen transitions to the effect. Do not let a separate legacy fade, hit flash or movement tween write to the same wrapper.

```text
EnemyArtAnchor                  # existing permanent layout/ground pivot
├── EnemyDefeatVisual           # Node2D (or unmanaged Control), local position 0,0
│   └── EnemyArt                # original sprite/portrait keeps its anchor & color
└── DefeatPlayer                # AnimationPlayer, root_node = ".."

HUD / combat labels / HP bar     # remain outside EnemyDefeatVisual
```

If the authored subtree already has offsets or modulate values, keep them on its existing child or outer holder. Reset assumes the newly dedicated receiver has neutral transform, not that the art has neutral tint. Never animate a layout-managed Container child that continuously overwrites position. The library’s only tracks are `EnemyDefeatVisual:position` and `EnemyDefeatVisual:modulate`. It never changes `visible` or takes input.

```gdscript
# Bind once in the consuming scene.
var lib := preload("res://assets/art/toolbox/effects/defeat/enemy-defeat.tres")
$EnemyArtAnchor/DefeatPlayer.add_animation_library(&"defeat_fx", lib)

# On defeat (choose exactly one):
player.play(&"defeat_fx/fade_only" if motion_is_reduced else &"defeat_fx/defeat")

# Before showing another enemy or cancelling an interrupted transition:
player.play(&"defeat_fx/reset_visual")
player.advance(0.0)
player.stop(true)  # keep the reset values
visual.show()      # only needed if the consuming scene hid the receiver
```

The project’s art-shelf source may live outside the built Godot project; mirror the resource to the runtime asset folder using its existing build flow if needed. Do not bundle the preview WebP into the game export unless wanted. Its display clips use numerical transforms emitted by native Godot AnimationPlayer against the existing Windvane Skitter and Dry Flats day art; the preview loop's sudden restart is not part of the game effect.

Verified with Godot 4.7.2 Compatibility/headless. The pack changes no existing art, scenes, code, HUD or combat behavior by itself.
