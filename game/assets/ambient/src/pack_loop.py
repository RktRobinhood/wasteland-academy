# Packs EffectCraft PNG frames into one sprite sheet + JSON frame map (same layout as
# AniCraft's export). With --loop N it takes 2N frames rendered after the warm-up and
# crossfades them, out[i] = (i/N)*F[i] + (1-i/N)*F[N+i], so the last frame runs straight
# into the first and no particle pops at the seam. --scale 0.5 halves each cell (soft
# effects only; the engine scales them back up). --fade K ramps the last K frames out.
# Run: python3 pack_loop.py <frames-dir> <out-sheet.png> <columns> <fps> [--loop N] [--scale S] [--fade K]
import glob, json, os, sys
from PIL import Image
args = sys.argv[1:]
src, out, cols, fps = args[0], args[1], int(args[2]), float(args[3])
loop = int(args[args.index("--loop") + 1]) if "--loop" in args else 0
scale = float(args[args.index("--scale") + 1]) if "--scale" in args else 1.0
F = [Image.open(p).convert("RGBA") for p in sorted(glob.glob(os.path.join(src, "*.png")))]
if loop:
    assert len(F) >= 2 * loop, f"need {2 * loop} frames, have {len(F)}"
    F = [Image.blend(F[loop + i], F[i], i / loop) for i in range(loop)]
fade = int(args[args.index("--fade") + 1]) if "--fade" in args else 0
for k in range(fade):  # one-shot effects: ramp the last `fade` frames down to nothing
    f = F[len(F) - fade + k]
    f.putalpha(f.getchannel("A").point(lambda v, a=1 - (k + 1) / fade: int(v * a)))
if scale != 1.0:
    F = [f.resize((round(f.width * scale), round(f.height * scale)), Image.LANCZOS) for f in F]
W, H = F[0].size
rows = -(-len(F) // cols)
sheet = Image.new("RGBA", (W * cols, H * rows), (0, 0, 0, 0))
name = os.path.basename(out)[:-4]
frames = {}
for i, f in enumerate(F):
    x, y = (i % cols) * W, (i // cols) * H
    sheet.paste(f, (x, y))
    frames["%s_%04d" % (name, i + 1)] = {"frame": {"x": x, "y": y, "w": W, "h": H}, "duration": round(1000 / fps),
        "rotated": False, "trimmed": False, "sourceSize": {"w": W, "h": H}}
sheet.quantize(256, method=Image.Quantize.FASTOCTREE).save(out, optimize=True)
json.dump({"frames": frames, "meta": {"image": os.path.basename(out), "size": {"w": sheet.width, "h": sheet.height}, "fps": fps}},
          open(out[:-4] + ".json", "w"), indent=1)
print(out, len(F), "frames", W, "x", H, os.path.getsize(out), "bytes")
