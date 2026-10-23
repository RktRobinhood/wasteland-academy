# Godot MCP notes

Tested 2026-10-23 (FAL-321) with Godot 4.7.2, plugin `godot_mcp_toolkit` v1.0.4 (copied
from The Unruly Atlas) and bridge `@npgamedev/godot-mcp-server`
(`npx -y @npgamedev/godot-mcp-server`). The Atlas's `game/docs/MCP-NOTES.md` explains
how the plugin, registry and bridge fit together. This file covers what happened here.

## Status: working

The boot scene `scenes/main.tscn` was created, laid out, styled and saved through the
MCP, against a headless editor on this task's worktree. Reads and checks worked too.
About 20 minutes of MCP work in all.

## How

```bash
scripts/mcp-editor.sh start      # godot --headless --editor --path <checkout>/game --lsp-port 6025
python3 -I scripts/mcp_call.py --list
python3 -I scripts/mcp_call.py <tool> '<json args>' [<tool> '<json args>' ...]
scripts/mcp-editor.sh stop
```

`scripts/mcp_call.py` is the Atlas's stdio MCP client. Every call in one command shares
one MCP session, in order. The bridge listed 36 core tools.

## Tools used

| Tool | Used for | Result |
|---|---|---|
| `scene_create` | `res://scenes/main.tscn`, root `Control` named `Main` | worked |
| `scene_open` | open it for edits (needed in every new `mcp_call.py` run) | worked |
| `control_set_layout` | `PRESET_FULL_RECT` with `resize_mode: set_to_anchors` on Main, Background, Center | worked |
| `scene_create_node` | Background (ColorRect), Center (CenterContainer), Column (VBoxContainer), Spark (TextureRect), Title, Tagline, Status (Labels) | nodes made; typed `properties` failed, see below |
| `node_set_property` (`batch`) | colours, fonts, texture and minimum sizes, 12 properties in one call | worked |
| `editor_save_scene` | save | worked |
| `scene_get_tree`, `node_get_property`, `scene_query` | check the tree, the title text, the three labels | worked |
| `script_check` | `tests/run_tests.gd`, `tests/test_boot.gd`, `tests/test_project.gd` | all `valid: true` |
| `project_get_settings` | `rendering/renderer` prefix: `gl_compatibility` for all three platforms | worked |
| `editor_get_console` (`source: "buffer"`, errors and warnings, `since_id`) | read the editor console after each step | worked |

The scene was then checked outside the MCP: `./test.sh` (boot with no errors in the log,
layout at 390x844 and 1280x800), and screenshots of the web export in Chromium.

## What failed, and the fix

- **Typed values in `scene_create_node`'s `properties`.** Plain values were rejected,
  each with a clear error, and the node was still made:
  - `"color": "#1F2937"`: "expected type Color, got String".
  - `"custom_minimum_size": {"x": 420, "y": 420}`: "expected type Vector2, got Dictionary".
  - `"texture": "res://assets/avatars/avatar-spark.png"`: "expects a Resource, not a bare string path".
  - `"theme_override_fonts/font": "res://..."`: "reported no error but readback is null".

  The tagged forms work, in `scene_create_node` or `node_set_property`:
  `{"type":"Color","r":0.12,"g":0.16,"b":0.22,"a":1}`,
  `{"type":"Vector2","x":420,"y":420}`,
  `{"type":"Resource","path":"res://assets/fonts/bangers-latin.woff2"}`.
  Plain ints and enums (`font_size`, `horizontal_alignment`, `autowrap_mode`) and
  strings (`text`) work as they are.
- **Console noise in the headless editor.** While the fonts were being set and the scene
  saved, the console logged `Required object "rp_font" is null` twice and
  `Parameter "t" is null` twice. The saved scene is fine: the boot test loads and runs
  it with no errors logged, and it renders in the browser. Read these as headless-editor
  noise, but check a scene outside the editor before trusting it.
- **No pictures.** As in the Atlas, a headless editor can't screenshot. Use
  `./screenshot.sh` or `scripts/web-screenshot.mjs`.

## Rules (from the Atlas, plus what this repo changed)

- **Never 6550.** The plugin binds the first free port from 6550. If Matt's editor isn't
  running, an agent editor would take 6550. `scripts/mcp-editor.sh` sets
  `GODOT_MCP_EDITOR_PORT_MIN=6551`, so agent editors scan 6551-6560. This run got 6551.
  The bridge finds the port through the registry, so nothing else needs it.
- **One editor per folder, and no `godot --import` or export while it's up.** A second
  editor process on the same `game/` overwrites the registry entry and removes it when
  it exits. `./test.sh` skips its import when an editor is open, and `./export.sh`
  refuses to run. Running `./test.sh`'s `--script` alongside the editor was safe: it
  only added a runtime port (6570) to the registry.
- **A distinct `--lsp-port`.** This repo's editor uses 6025 (the Atlas's uses 6015,
  Matt's 6005). The registry still recorded `lsp_port: 6005` for this editor, so set
  `GODOT_MCP_LSP_PORT=6025` in the bridge's environment before trying the `lsp_*` tools.
  That is untested.
- **The editor and the bridge need the same `XDG_DATA_HOME`.** Both inherit the agent
  run's sandboxed one, so they find each other. Matt's editor is in a different one.
- **`GODOT_MCP_PROJECT_PATH` must be absolute.** `mcp_call.py` sets it to
  `<checkout>/game`.
- **Stale registry entry.** `scripts/mcp-editor.sh stop` kills the editor, which leaves
  its entry in `projects.json`. The next `start` replaces it, so this is harmless.
- **Own `user://`.** `config/name` is "Wasteland Academy", so the token and logs are
  under `app_userdata/Wasteland Academy/`, apart from the Atlas's.

## Recommendation

Use the MCP to build and inspect scenes (`scene_create_node` plus a `node_set_property`
batch with tagged values, then `editor_save_scene`), and `script_check` after writing a
script. Prove the result with `./test.sh` and a screenshot. Stop the editor before
`./export.sh` and before your run ends.
