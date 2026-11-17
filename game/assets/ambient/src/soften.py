# Soft edges for AniCraft sheets: Gaussian-blurs each cell of a sheet on its own (so nothing
# bleeds across cells). AniCraft's blur filter only takes movie-clip instances, and a motion
# tween makes a graphic symbol, so this runs after the export.
# Run: python3 soften.py <sheet.png> <radius>
import json, sys
from PIL import Image, ImageFilter
path, r = sys.argv[1], float(sys.argv[2])
sheet = Image.open(path).convert("RGBA")
for fr in json.load(open(path[:-4] + ".json"))["frames"].values():
    f = fr["frame"]; box = (f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"])
    # Blur premultiplied ("RGBa"): blurring straight RGBA pulls the black of transparent
    # pixels into the edges and leaves a dark ring round every puff.
    sheet.paste(sheet.crop(box).convert("RGBa").filter(ImageFilter.GaussianBlur(r)).convert("RGBA"), box)
sheet.save(path, optimize=True)
