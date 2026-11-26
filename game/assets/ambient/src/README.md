# Ambient pack sources (FAL-1074)

Sources for the sheets one folder up. Godot skips this folder (`.gdignore`). Every tool runs
headless on the CPU. Run each step from the piece's own folder.

| Sheet | Tool | Rebuild |
|---|---|---|
| `crow-sheet` | AniCraft | `anicraft-cli new --out base.anicraft --width 72 --height 44 --fps 10 && anicraft-cli run base.anicraft crow.json --save crow.anicraft` |
| `engine-smoke-sheet` | AniCraft + `soften.py` | `python3 build_smoke.py`, `anicraft-cli new --out base.anicraft --width 150 --height 160 --fps 12`, `anicraft-cli run base.anicraft smoke.json --save smoke.anicraft`, then `python3 ../soften.py ../../engine-smoke-sheet.png 3` |
| `signal-beacon-sheet` | AniCraft + `soften.py` | `anicraft-cli new --out base.anicraft --width 40 --height 40 --fps 10`, `anicraft-cli run base.anicraft beacon.json --save beacon.anicraft`, then `python3 ../soften.py ../../signal-beacon-sheet.png 1.5` |
| `dome-neon-sheet` | PhotoCraft + Pillow | `./neon.sh` (colour-range cut of the ring), then `python3 build_neon.py` |
| `flats-dust-sheet` | EffectCraft | `effectcraft-cli run --commands dust.jsonl --empty --save-as dust.ecproj`, `./dust-set.sh`, render `--start 4 --end 8` to `seq/`, then `python3 ../pack_loop.py dust/seq ../flats-dust-sheet.png 6 12 --loop 24 --scale 0.5` from this folder |
| `hit-spark-sheet` | EffectCraft | `spark.jsonl`, `./spark-set.sh`, render `--start 0.083 --end 0.75`, then `pack_loop.py ... 4 12` |
| `dust-burst-sheet` | EffectCraft | `burst.jsonl`, `./burst-set.sh`, render `--start 0.083 --end 1.17`, then `pack_loop.py ... 7 12 --fade 4` |
| `world-smoke-plate`, `world-smoke`, `world-smoke-stir` | Pillow + numpy (FAL-1724) | `cd toys && python3 build_smoke.py` (cuts W1-4's Engine Core plumes, paints the ground behind them, idle billow + stir) |
| `crow-perch`, `crow-takeoff`, `crow-land` | Pillow (FAL-1724) | `cd toys && python3 build_crow.py` |
| `signal-beacon-overload` | Pillow + numpy (FAL-1724) | `cd toys && python3 build_beacon.py` |
| `fuel-drums`, `-wobble`, `-hiss`, `-blast`, `-wreck` | Pillow + numpy (FAL-1724) | `cd toys && python3 build_drums.py` (the stack is cut from `map/algebra/background-wide.webp`) |
| `tower-lights`, `yards-lamps`, `pool-ripples`, `curve-flags`, `tower-banners` | Pillow + numpy (FAL-1725) | `cd toys && python3 build_signal.py` (Signal Tower B5-2: glows grown from the board's lit pixels, flags and banners are the board's own pixels warped) |
| `dust-devil`, `-stir`; `relay-box`, `-spark`, `-hiss`, `-pop`, `-husk` | Pillow + numpy (FAL-1725) | `cd toys && python3 build_signal_toys.py` |
| `strip-mast-lamps`, `strip-mid-lamps`, `strip-ruin-smoke` | Pillow + numpy (FAL-1726) | `cd toys && python3 build_strip.py` (Signal Tower journey strip: glows on the `far`/`mid` layers' own lamps, smoke off a far ruin; placed in layer pixels) |

With `anicraft-cli run ... --save`, delete the old `.anicraft` first, because saving over it is refused.

**Edge feather (after packing).** No cell may touch its own edge, or Godot shows a hard straight cut. These ran on the packed sheets:

```
python3 feather_edges.py ../hit-spark-sheet.png 24 --radial
python3 feather_edges.py ../flats-dust-sheet.png 16
python3 feather_edges.py ../engine-smoke-sheet.png 16 --sides R
python3 feather_edges.py ../dome-neon-sheet.png 4 --sides B
python3 check_edges.py        # the toys/ builders fade their own cell edges (toylib.edge_fade); every cell's outer 1 px row must read alpha <= 8; exits 1 otherwise
```
