# Thunderdome neon flicker. neon.sh (PhotoCraft) cuts the magenta ring out of the overworld;
# PhotoCraft's PNG comes out flattened on black, so this treats any non-black pixel as the
# tube mask, then re-lights the painted tubes, adds a soft Bazaar Magenta (#FF3DA7) glow and
# writes 24 frames (12 fps, 2 s) of a steady hum with one double stutter.
# Cell = board rect (375,690)-(705,830). Run: python3 build_neon.py
import json
from PIL import Image, ImageChops, ImageFilter
cut = Image.open("neon-cut.png").convert("RGB")
mask = cut.convert("L").point(lambda v: 255 if v > 40 else 0).crop((15, 30, 345, 170))
W, H = mask.size
glow = mask.filter(ImageFilter.GaussianBlur(7)).point(lambda v: min(255, v * 3))
# The tubes themselves: the painting's own pixels, brightened, on a softened mask.
src = Image.open("../../../map/overworld.png").convert("RGB").crop((375, 690, 705, 830))
lit = src.point(lambda v: min(255, int(v * 1.35 + 20)))
soft = mask.filter(ImageFilter.GaussianBlur(0.8))
halo = mask.filter(ImageFilter.GaussianBlur(2.5)).point(lambda v: min(255, v * 2))
def frame(k):
    f = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for layer, col, a in ((glow, (255, 61, 167), 0.5), (halo, (255, 61, 167), 0.45)):
        solid = Image.new("RGBA", (W, H), col + (0,))
        solid.putalpha(layer.point(lambda v: int(v * a * k)))
        f.alpha_composite(solid)
    tubes = lit.copy()
    tubes.putalpha(soft.point(lambda v: int(v * 0.85 * k)))
    f.alpha_composite(tubes)
    return f
levels = [1.0, 0.95, 0.9, 0.95, 1.0, 0.95, 0.9, 0.95, 1.0, 0.95, 0.9, 0.95,
          1.0, 0.95, 0.15, 0.85, 0.1, 0.0, 0.6, 1.0, 1.0, 0.95, 0.9, 0.95]
cols = 6
sheet = Image.new("RGBA", (W * cols, H * (len(levels) // cols)), (0, 0, 0, 0))
frames = {}
for i, k in enumerate(levels):
    x, y = (i % cols) * W, (i // cols) * H
    sheet.paste(frame(k), (x, y))
    frames["dome-neon_%04d" % (i + 1)] = {"frame": {"x": x, "y": y, "w": W, "h": H}, "duration": 83,
        "rotated": False, "trimmed": False, "sourceSize": {"w": W, "h": H}}
# 256-colour palette with alpha keeps the sheet under the 500 KB overlay budget.
sheet.quantize(256, method=Image.Quantize.FASTOCTREE).save("../../dome-neon-sheet.png", optimize=True)
json.dump({"frames": frames, "meta": {"image": "dome-neon-sheet.png", "size": {"w": sheet.width, "h": sheet.height}, "fps": 12}},
          open("../../dome-neon-sheet.json", "w"), indent=1)
