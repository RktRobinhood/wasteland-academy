"""Signal Tower beacon overload (FAL-1724): tap the red light on the tallest spire and it
surges white-teal, spits sparks, cuts out twice and comes back red.  python3 build_beacon.py

  signal-beacon-overload  10 cells 64x64 @12 fps, anchor (32, 32). Ends on a plain red glow,
                          so the idle signal-beacon loop picks up from it.
"""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from toylib import pack

N = 64
yy, xx = np.mgrid[0:N, 0:N] + 0.5
r = np.hypot(xx - 32, yy - 32)
RED, HOT, TEAL, WHITE = (232, 84, 60), (255, 214, 150), (120, 255, 230), (255, 255, 245)


def glow(radius, core, col, ccol=WHITE, amt=1.0):
    a = np.clip(np.exp(-(r / max(radius, 0.1)) ** 2) * 1.1, 0, 1) * amt
    c = np.clip(1 - r / max(core, 0.1), 0, 1)
    rgb = np.array(col)[None, None] * (1 - c[..., None]) + np.array(ccol)[None, None] * c[..., None]
    alpha = np.maximum(a, c * amt)
    return Image.fromarray(np.dstack([rgb, alpha * 255]).astype(np.uint8))


def sparks(im, n, seed, length):
    g = np.random.default_rng(seed); big = im.resize((N * 4, N * 4), Image.LANCZOS); d = ImageDraw.Draw(big)
    for _ in range(n):
        a = g.uniform(0, 2 * math.pi); r0 = g.uniform(4, 8); r1 = r0 + g.uniform(0.6, 1) * length
        pts = [(128 + 4 * r0 * math.cos(a), 128 + 4 * r0 * math.sin(a)), (128 + 4 * r1 * math.cos(a) + g.normal(0, 6), 128 + 4 * r1 * math.sin(a) + g.normal(0, 6))]
        d.line(pts, fill=(255, 250, 210, 255), width=5)
    return big.filter(ImageFilter.GaussianBlur(1.2)).resize((N, N), Image.LANCZOS)


frames = [
    glow(7, 2, RED, HOT),                     # 0 normal
    glow(12, 4, TEAL, WHITE),                 # 1 surge
    glow(4, 1.5, RED, HOT, 0.5),              # 2 dip
    sparks(glow(17, 6, TEAL, WHITE), 9, 1, 20),   # 3 overload
    glow(2.5, 1, RED, HOT, 0.35),             # 4 out
    sparks(glow(13, 5, TEAL, WHITE), 6, 2, 14),   # 5 second jolt
    glow(1.5, 0.8, RED, HOT, 0.2),            # 6 out
    glow(5, 2, RED, HOT, 0.6),                # 7 sputter
    glow(2, 1, RED, HOT, 0.3),                # 8 out
    glow(7, 2, RED, HOT),                     # 9 back
]
pack(frames, "signal-beacon-overload", 12, feather=3)
