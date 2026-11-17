"""Report the max alpha on the outer 1 px row of every cell of every sheet (FAL-1074).

    python3 check_edges.py [limit]     # from this folder; exits 1 if any cell is over the limit (default 8)
"""
import json, sys
from pathlib import Path
from PIL import Image

limit = int(sys.argv[1]) if len(sys.argv) > 1 else 8
bad = 0
for js in sorted(Path(__file__).resolve().parent.parent.glob("*-sheet.json")):
    a = Image.open(js.with_suffix(".png")).convert("RGBA").getchannel("A")
    worst = {"T": 0, "R": 0, "B": 0, "L": 0}
    over = []
    for name, f in sorted(json.loads(js.read_text())["frames"].items()):
        r = f["frame"]
        c = a.crop((r["x"], r["y"], r["x"] + r["w"], r["y"] + r["h"]))
        w, h = c.size
        e = {"T": c.crop((0, 0, w, 1)).getextrema()[1], "B": c.crop((0, h - 1, w, h)).getextrema()[1],
             "L": c.crop((0, 0, 1, h)).getextrema()[1], "R": c.crop((w - 1, 0, w, h)).getextrema()[1]}
        for k, v in e.items():
            worst[k] = max(worst[k], v)
        if max(e.values()) > limit:
            over.append(name)
    ok = not over
    bad += not ok
    print(f"{'ok  ' if ok else 'FAIL'} {js.stem:24} max edge alpha T{worst['T']:>3} R{worst['R']:>3} "
          f"B{worst['B']:>3} L{worst['L']:>3}" + (f"  over {limit}: {', '.join(over)}" if over else ""))
sys.exit(1 if bad else 0)
