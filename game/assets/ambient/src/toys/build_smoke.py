"""Engine Core smoke on W1-4 (FAL-1724): the three painted plumes cut out of
overworld-wide.webp, a ground plate that hides the painted copy, an idle drift loop
and a stir (swirl apart, settle back).  python3 build_smoke.py

  world-smoke-plate   1 cell, full res: ground with the plumes painted out. Under the plume.
  world-smoke         12 cells @10 fps, half res (scale 2): slow billow, loops.
  world-smoke-stir    14 cells @12 fps, half res: swirls apart, settles to world-smoke frame 0.
"""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from toylib import world, sample, premul, unpremul, pack

X0, Y0, X1, Y1 = 800, 578, 1216, 722          # board box of the piece
W, H = X1 - X0, Y1 - Y0
# Rough hulls round each plume (piece pixels), and each chimney mouth (the plume's root).
HULLS = [[(8, 134), (14, 96), (55, 60), (108, 44), (156, 54), (148, 92), (84, 114), (44, 140)],
         [(172, 80), (182, 40), (218, 18), (268, 12), (280, 40), (234, 64), (206, 84)],
         [(232, 110), (236, 74), (288, 38), (330, 16), (400, 16), (414, 50), (372, 78), (300, 94), (264, 114)]]
ROOTS = [(25, 128), (195, 74), (252, 104)]

src = world().crop((X0, Y0, X1, Y1))
rgb = np.array(src).astype(float)
hsv = np.array(src.convert("HSV")).astype(float)
hull = Image.new("L", (W, H)); d = ImageDraw.Draw(hull)
for p in HULLS: d.polygon(p, fill=255)
hull = np.array(hull.filter(ImageFilter.GaussianBlur(3))) / 255.0
s, v = hsv[..., 1], hsv[..., 2]
soft = np.clip((165 - s) / 40, 0, 1) * np.clip((v - 135) / 40, 0, 1) * hull
# Close the speckle into puffs: grow, blur, re-cut, then feather.
m = Image.fromarray((soft * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(2.5))
m = np.clip((np.array(m) / 255.0 - 0.15) / 0.5, 0, 1) * hull
alpha = (m * 255).astype(np.uint8)

# Plate: fill where the smoke is by diffusing the surrounding ground in, then add the
# ground's own grain back so it doesn't read as a smudge.
# Rust, wood and chimney metal (dark and saturated) is never painted over.
# ...but only on the chimneys and the arena wall; elsewhere dark pixels are smoke outline.
zone = Image.new("L", (W, H)); dz = ImageDraw.Draw(zone)
for r in [(8, 120, 44, H), (178, 64, 214, H), (234, 94, 274, H), (100, 0, 340, 20)]: dz.rectangle(r, fill=255)
keep = (s > 110) & (v < 150) & (np.array(zone) > 0)
keep = np.array(Image.fromarray((keep * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3))) > 0
hole = (np.array(Image.fromarray(alpha).filter(ImageFilter.MaxFilter(7))) > 20) & ~keep
fill = rgb.copy(); known = ~hole & ~keep
f = fill * known[..., None]; k = known.astype(float)
for r in (24, 12, 6, 3):
    for _ in range(6):
        fb = np.array(Image.fromarray(np.clip(f, 0, 255).astype(np.uint8)).filter(ImageFilter.BoxBlur(r))).astype(float)
        kb = np.array(Image.fromarray((k * 255).astype(np.uint8)).filter(ImageFilter.BoxBlur(r))).astype(float) / 255
        est = fb / np.maximum(kb[..., None], 1e-3)
        f = np.where(known[..., None], rgb, est); k = np.ones_like(k)
        f = f * 1.0
# Ground grain: soft speckle plus a few dark flecks, like the painted sand.
g = np.random.default_rng(3)
speck = np.array(Image.fromarray((g.random((H, W)) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))).astype(float) - 128
fleck = (g.random((H, W)) > 0.985) * -40.0
shift = ((speck * 0.35 + fleck)[..., None]) * np.array([1.0, 0.8, 0.6])
plate_rgb = np.where(hole[..., None], f + shift, rgb)
pa = np.array(Image.fromarray((hole * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(3)))
plate = np.dstack([np.clip(plate_rgb, 0, 255), pa]).astype(np.uint8)
pack([Image.fromarray(plate)], "world-smoke-plate", 10, feather=2)

plume = premul(np.dstack([rgb, alpha]).astype(float))
yy, xx = np.mgrid[0:H, 0:W].astype(float)
# Distance from the nearest chimney mouth: 0 at the mouth, so the root stays put.
dist = np.min([np.hypot(xx - rx, yy - ry) for rx, ry in ROOTS], axis=0)
reach = np.clip(dist / 60, 0, 1)


def billow(t, n):
    """Frame t of an n-frame loop: two copies drifting up-right, cross-faded."""
    out = 0
    for k, wgt in ((t / n, 1 - t / n), (t / n - 1, t / n)):
        dx = 3 * k * reach + 1.6 * np.sin(yy / 9 + 2 * np.pi * t / n) * reach
        dy = -2.5 * k * reach + 1.3 * np.cos(xx / 11 + 2 * np.pi * t / n) * reach
        out = out + sample(plume, xx - dx, yy - dy) * wgt
    return out


def half(p):
    im = Image.fromarray(unpremul(p))
    return im.resize((W // 2, H // 2), Image.LANCZOS)


N = 12
pack([half(billow(t, N)) for t in range(N)], "world-smoke", 10)

# Stir: swirl round each plume's middle and push outward, alpha breaks into puffs, then back.
rng = np.random.default_rng(7)
noise = np.array(Image.fromarray((rng.random((H // 6 + 1, W // 6 + 1)) * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)) / 255.0
mids = [(80, 85), (230, 42), (330, 55)]
frames = []
S = 14
for t in range(S):
    e = np.sin(np.pi * min(t / 6, 1) / 2) if t <= 6 else 0.5 + 0.5 * np.cos(np.pi * (t - 6) / (S - 1 - 6))
    sx, sy = xx.copy(), yy.copy()
    for mx, my in mids:
        r = np.hypot(xx - mx, yy - my); fall = np.exp(-(r / 55) ** 2)
        ang = -1.3 * e * fall * reach
        grow = 1 + 0.35 * e * fall
        ox, oy = (xx - mx) / grow, (yy - my) / grow
        c, s_ = np.cos(ang), np.sin(ang)
        sx = np.where(fall > 0.02, mx + c * ox - s_ * oy, sx)
        sy = np.where(fall > 0.02, my + s_ * ox + c * oy, sy)
    p = sample(plume, sx, sy)
    holes = np.clip(1 - e * 1.6 * np.clip(noise - 0.35, 0, 1) * 2 * reach, 0.25, 1)
    p = p * (holes * (1 - 0.35 * e * reach))[..., None]
    frames.append(half(p if t not in (0, S - 1) else billow(0, N)))
pack(frames, "world-smoke-stir", 12)
