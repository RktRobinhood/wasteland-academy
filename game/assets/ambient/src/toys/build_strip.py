"""Signal Tower journey-strip life (FAL-1726), on assets/journey/signal-tower/far.webp and
mid.webp (864 x 256 each, tiled by journey_stage.gd). Pillow + numpy, CPU only.
python3 build_strip.py

Slow pieces only, because the question card sits over the strip. No toys: the strip is
view-only (JourneyStage.mouse_filter IGNORE).

  strip-mast-lamps  24 @8  far, half-res cells, scale 2. The big mast's lamps breathing:
                           beacon at the top, teal and magenta at the foot, in turn. still 0
  strip-mid-lamps   24 @8  mid, half-res cells, scale 2. The seven painted lamps on the mid
                           towers breathing, each on its own phase. still 0
  strip-ruin-smoke  24 @8  far. A slow smoke trail off the middle ruin's roof, leaning right.
                           still 0

Every glow is centred on a lamp found in the layer's own pixels (magenta R>160 B>110 G<110,
teal G>140 B>110 R<140) and takes that lamp's colour. Peaks stay low (alpha <= 0.5), with
3 s breaths, so nothing flashes.
"""
import math
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter
from toylib import ROOT, pack

STRIP = ROOT.parents[2] / "assets" / "journey" / "signal-tower"
N = 24
MAG = (236, 92, 214)
TEAL = (110, 236, 210)


def layer(name):
    return np.array(Image.open(STRIP / f"{name}.webp").convert("RGBA")).astype(float)


def breathe(t):
    """0..1..0 over one loop, eased, with a long low tail (a breath, not a blink)."""
    return (0.5 - 0.5 * math.cos(2 * math.pi * t)) ** 1.6


def glow_frame(w, h, lamps, s, half=True):
    """lamps: (x, y, colour, phase, radius, peak) in cell px at full res."""
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    acc = np.zeros((h, w, 4))
    for x, y, col, ph, r, peak in lamps:
        b = 0.25 + 0.75 * breathe((s + ph) % 1.0)
        d2 = (xx - x) ** 2 + (yy - y) ** 2
        halo = np.exp(-d2 / (2 * r * r)) * peak * b
        core = np.exp(-d2 / (2 * (r * 0.28) ** 2)) * 0.35 * b
        a = np.clip(halo + core, 0, 1)
        c = np.array(col, float)
        # the core whitens a touch, the halo stays the lamp's colour
        rgb = c[None, None, :] * (1 - core[..., None] * 0.5) + 255 * core[..., None] * 0.5
        sa = a[..., None]; da = acc[..., 3:4]
        oa = sa + da * (1 - sa)
        acc[..., :3] = np.where(oa > 1e-4, (rgb * sa + acc[..., :3] * da * (1 - sa)) / np.maximum(oa, 1e-4), 0)
        acc[..., 3:4] = oa
    out = np.concatenate([acc[..., :3], acc[..., 3:4] * 255], -1)
    im = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA")
    return im.resize((w // 2, h // 2), Image.LANCZOS) if half else im


# ---------------- strip-mast-lamps (far) ----------------
# Cell covers far x 248..312, y 36..196 (full res); lamps at (296,60) (268,162) (277,171).
MX, MY, MW, MH = 248, 36, 64, 160
mast = [(296 - MX, 60 - MY, MAG, 0.00, 7, 0.45),
        (268 - MX, 162 - MY, TEAL, 0.50, 6, 0.40),
        (277 - MX, 171 - MY, MAG, 0.15, 5, 0.35)]
pack([glow_frame(MW, MH, mast, k / N) for k in range(N)], "strip-mast-lamps", 8)

# ---------------- strip-mid-lamps (mid) ----------------
# One cell across the whole mid tile, y 80..256, so it tiles with the layer.
LX, LY, LW, LH = 0, 80, 864, 176
mid_lamps = [(13, 121, TEAL), (129, 131, MAG), (128, 203, MAG), (172, 240, TEAL),
             (237, 100, TEAL), (508, 159, TEAL), (632, 185, MAG), (760, 116, MAG)]
lamps = [(x - LX, y - LY, c, (i * 0.37) % 1.0, 7, 0.42) for i, (x, y, c) in enumerate(mid_lamps)]
pack([glow_frame(LW, LH, lamps, k / N) for k in range(N)], "strip-mid-lamps", 8, colors=128)

# ---------------- strip-ruin-smoke (far) ----------------
# Rises off the middle ruin's roof at far (752, 112); cell 64 x 112, source at (14, 104).
FAR = layer("far")
SW, SH, SX, SY = 64, 112, 14, 104
SMOKE = np.array([78, 58, 64], float)       # darker than the dusk haze, a little violet


def smoke_frame(s):
    yy, xx = np.mgrid[0:SH, 0:SW].astype(float)
    a = np.zeros((SH, SW))
    puffs = 7
    for i in range(puffs):
        age = (s + i / puffs) % 1.0                     # one loop = one puff's life
        rise = age * 92
        cy = SY - rise
        cx = SX + rise * 0.40 + 2.5 * math.sin(2 * math.pi * (age * 1.3 + i * 0.21))
        r = 3.5 + age * 12
        env = (0.55 + 0.45 * min(1.0, age * 10)) * (1 - age) ** 1.1   # thick at the roof, thinning as it climbs
        a += np.exp(-((xx - cx) ** 2 + (yy - cy) ** 2) / (2 * r * r)) * env * 0.58
    a += np.exp(-((xx - SX - 1) ** 2 + (yy - SY + 2) ** 2) / (2 * 3.2 ** 2)) * 0.45   # the stem on the roof
    # wisps that scroll up with the smoke; whole cycles per loop, so the loop is seamless
    u = yy / SH
    tex = 0.5 + 0.25 * np.sin(2 * math.pi * (2 * u + 2 * s) + xx * 0.31) \
        + 0.25 * np.sin(2 * math.pi * (3 * u + 3 * s) - xx * 0.23 + 1.0)
    a = np.clip(a * (0.6 + 0.8 * tex), 0, 0.62)
    rgb = np.broadcast_to(SMOKE, (SH, SW, 3))
    return Image.fromarray(np.concatenate([rgb, a[..., None] * 255], -1).astype(np.uint8), "RGBA")


pack([smoke_frame(k / N) for k in range(N)], "strip-ruin-smoke", 8, colors=64, feather=3)
