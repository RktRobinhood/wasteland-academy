"""Fade alpha to 0 at the edges of every cell of a sheet, in place (FAL-1074).

    python3 feather_edges.py <sheet.png> <px> [--sides TRBL]   # linear ramp on the named sides
    python3 feather_edges.py <sheet.png> <px> --radial         # round fade: full inside r-px, 0 at the cell's half-width
"""
import argparse, json, math
from pathlib import Path
from PIL import Image, ImageChops

ap = argparse.ArgumentParser()
ap.add_argument("sheet")
ap.add_argument("px", type=int)
ap.add_argument("--sides", default="TRBL")
ap.add_argument("--radial", action="store_true")
o = ap.parse_args()

sheet = Path(o.sheet)
src = Image.open(sheet)
img = src.convert("RGBA")
frames = json.loads(sheet.with_suffix(".json").read_text())["frames"]
w0, h0 = next(iter(frames.values()))["frame"]["w"], next(iter(frames.values()))["frame"]["h"]

mask = Image.new("L", (w0, h0))
px = mask.load()
for y in range(h0):
    for x in range(w0):
        if o.radial:
            r = math.hypot(x + 0.5 - w0 / 2, y + 0.5 - h0 / 2)
            t = (min(w0, h0) / 2 - r) / o.px
        else:
            d = []
            if "L" in o.sides: d.append(x + 0.5)
            if "R" in o.sides: d.append(w0 - x - 0.5)
            if "T" in o.sides: d.append(y + 0.5)
            if "B" in o.sides: d.append(h0 - y - 0.5)
            t = min(d) / o.px if d else 1
        t = max(0.0, min(1.0, t))
        px[x, y] = round(255 * t * t * (3 - 2 * t))  # smoothstep

alpha = img.getchannel("A")
for f in frames.values():
    r = f["frame"]
    box = (r["x"], r["y"], r["x"] + r["w"], r["y"] + r["h"])
    alpha.paste(ImageChops.multiply(alpha.crop(box), mask), box)
img.putalpha(alpha)
if src.mode == "P":  # keep palette sheets small; clear colour under alpha 0 first
    img = Image.composite(img, Image.new("RGBA", img.size), alpha.point(lambda v: 255 if v else 0))
    img = img.quantize(256, method=Image.Quantize.FASTOCTREE)
img.save(sheet, optimize=True)
