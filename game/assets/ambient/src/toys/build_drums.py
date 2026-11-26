"""Fuel-drum stack, the world map's break toy (FAL-1724). The stack is cut out of Matt's
Scrap Fields board (map/algebra/background-wide.webp) and set on the empty ground between
Scrap Fields and Signal Tower on W1-4. Tap 1 wobbles it, tap 2 makes it hiss and spark,
tap 3 blows it up; the wreck smoulders and stays.  python3 build_drums.py

All cells 200x170, anchor (100, 150) = the middle of the stack's foot, at scale 1.
  fuel-drums         8 @8 fps   idle: a glint runs over the drums. still = 0
  fuel-drums-wobble  8 @10 fps  warning 1: rocks on its foot, top drum rattles
  fuel-drums-hiss   10 @12 fps  warning 2: a seam spits steam and sparks, trembling
  fuel-drums-blast  16 @12 fps  plays once: flash, fireball, drums thrown, smoke, ends on the wreck
  fuel-drums-wreck   8 @8 fps   after: charred bottom row, two drums rolled off, embers and a thin smoulder. still = 0
"""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance, ImageChops
from toylib import ROOT, pack

CW, CH, AX, AY = 200, 170, 100, 150
SRC = ROOT.parent / "map" / "algebra" / "background-wide.webp"
crop = Image.open(SRC).convert("RGB").crop((1180, 80, 1460, 340))           # 280x260
POLY = [(112, 62), (118, 45), (140, 37), (165, 37), (173, 50), (189, 80), (209, 115), (213, 140), (229, 165),
        (251, 190), (263, 205), (263, 240), (240, 250), (30, 250), (17, 236), (21, 200), (45, 170), (60, 148),
        (70, 120), (90, 90), (110, 70)]
m = Image.new("L", crop.size); ImageDraw.Draw(m).polygon(POLY, fill=255)
m = m.filter(ImageFilter.GaussianBlur(1.2))
# The teal scrap the stack stands in: a soft ellipse, minus the orange ground showing through.
e = Image.new("L", crop.size); ImageDraw.Draw(e).ellipse((10, 214, 272, 258), fill=255)
e = np.array(e.filter(ImageFilter.GaussianBlur(7))).astype(float)
hsv = np.array(crop.convert("HSV")).astype(float)
groundish = (hsv[..., 0] < 22) & (hsv[..., 1] > 150)
e = e * np.where(groundish, 0.25, 1.0)
alpha = np.maximum(np.array(m).astype(float), e)
cut = crop.copy(); cut.putalpha(Image.fromarray(alpha.astype(np.uint8)))
SC = 0.40
stack = cut.resize((round(280 * SC), round(260 * SC)), Image.LANCZOS)        # 112x104
FOOT = (round(140 * SC), round(240 * SC))                                    # foot in stack px


def blank():
    return Image.new("RGBA", (CW, CH))


def place(im, spr, foot, dx=0, dy=0):
    im.alpha_composite(spr, (AX - foot[0] + round(dx), AY - foot[1] + round(dy)))


def rotated(spr, foot, deg):
    """Rotate about the foot."""
    big = Image.new("RGBA", (spr.width * 2, spr.height * 2)); off = (spr.width - foot[0], spr.height - foot[1])
    big.alpha_composite(spr, off)
    big = big.rotate(deg, resample=Image.BICUBIC, center=(spr.width, spr.height))
    return big, (spr.width, spr.height)


# Contact shadow under the stack, drawn into every intact frame.
def shadow(im, w=58, a=70):
    s = Image.new("RGBA", (CW, CH)); ImageDraw.Draw(s).ellipse((AX - w, AY - 6, AX + w, AY + 7), fill=(60, 20, 10, a))
    im.alpha_composite(s.filter(ImageFilter.GaussianBlur(4)))


def glint(im, t):
    """A soft white glint sliding across the drum tops."""
    g = Image.new("RGBA", (CW, CH)); d = ImageDraw.Draw(g)
    pts = [(-28, -82), (-12, -66), (6, -50), (22, -34), (-34, -40), (-10, -24)]
    x, y = pts[t % len(pts)]
    if t < len(pts):
        d.ellipse((AX + x - 3, AY + y - 2, AX + x + 3, AY + y + 2), fill=(255, 250, 230, 200))
    im.alpha_composite(g.filter(ImageFilter.GaussianBlur(1.2)))


idle = []
for t in range(8):
    im = blank(); shadow(im); place(im, stack, FOOT); glint(im, t); idle.append(im)
pack(idle, "fuel-drums", 8)

# Warning 1: wobble. The top three drums are a separate layer that rattles a bit more.
top_mask = Image.new("L", stack.size); ImageDraw.Draw(top_mask).rectangle((0, 0, stack.width, round(108 * SC)), fill=255)
top = Image.new("RGBA", stack.size); top.paste(stack, (0, 0), ImageChops.multiply(stack.getchannel("A"), top_mask))
lower = stack.copy(); la = ImageChops.subtract(stack.getchannel("A"), top_mask); lower.putalpha(la)
wob = []
for k, (deg, tdx) in enumerate([(0, 0), (2.5, -1), (-2.2, 2), (1.8, -2), (-1.6, 1), (1.0, -1), (-0.6, 1), (0, 0)]):
    im = blank(); shadow(im)
    r, f = rotated(lower, FOOT, deg); place(im, r, f)
    r, f = rotated(top, FOOT, deg * 1.6); place(im, r, f, dx=tdx)
    wob.append(im)
pack(wob, "fuel-drums-wobble", 10)

# Warning 2: hiss + sparks from a seam on the right-hand pink drum.
rng = np.random.default_rng(11)
SEAM = (AX + 26, AY - 40)


def puff(im, cx, cy, rad, a):
    p = Image.new("RGBA", (CW, CH)); ImageDraw.Draw(p).ellipse((cx - rad, cy - rad * 0.8, cx + rad, cy + rad * 0.8), fill=(236, 226, 210, a))
    im.alpha_composite(p.filter(ImageFilter.GaussianBlur(rad * 0.35)))


def spark_burst(im, cx, cy, n, length, seed):
    g = np.random.default_rng(seed); big = Image.new("RGBA", (CW * 2, CH * 2)); d = ImageDraw.Draw(big)
    for _ in range(n):
        a = g.uniform(-2.6, -0.2); l = g.uniform(0.4, 1) * length
        d.line([(2 * cx, 2 * cy), (2 * (cx + l * math.cos(a)), 2 * (cy + l * math.sin(a)))], fill=(255, 230, 140, 255), width=2)
        d.ellipse((2 * (cx + l * math.cos(a)) - 2, 2 * (cy + l * math.sin(a)) - 2, 2 * (cx + l * math.cos(a)) + 2, 2 * (cy + l * math.sin(a)) + 2), fill=(255, 250, 220, 255))
    im.alpha_composite(big.resize((CW, CH), Image.LANCZOS))


hiss = []
for k in range(10):
    im = blank(); shadow(im)
    j = (rng.integers(-1, 2), rng.integers(-1, 1))
    place(im, stack, FOOT, *j)
    for q in range(4):                                    # a jet of steam blowing out right and up
        s = (k + q * 2.5) % 10 / 10
        puff(im, SEAM[0] + 6 + s * 50, SEAM[1] - 4 - s * 26 + 3 * math.sin(k + q), 3 + s * 12, round(220 * (1 - s)))
    if k % 3 != 2:
        spark_burst(im, SEAM[0], SEAM[1], 4 + k % 3, 10 + 3 * (k % 2), k)
    hiss.append(im)
pack(hiss, "fuel-drums-hiss", 12)

# --- The wreck: bottom row only, charred; a torn drum; two drums rolled off; scorch. ---
row_mask = Image.new("L", stack.size); ImageDraw.Draw(row_mask).polygon(
    [(0, round(196 * SC)), (round(80 * SC), round(178 * SC)), (round(200 * SC), round(178 * SC)), (stack.width, round(200 * SC)), (stack.width, stack.height), (0, stack.height)], fill=255)
row_mask = row_mask.filter(ImageFilter.GaussianBlur(1.5))
wreck_row = stack.copy(); wreck_row.putalpha(ImageChops.multiply(stack.getchannel("A"), row_mask))
rgb = wreck_row.convert("RGB")
rgb = ImageEnhance.Color(rgb).enhance(0.6); rgb = ImageEnhance.Brightness(rgb).enhance(0.72)
rgb = Image.blend(rgb, Image.new("RGB", rgb.size, (60, 34, 24)), 0.18)
char = rgb.convert("RGBA"); char.putalpha(wreck_row.getchannel("A"))
# One whole drum from the original stack (row 2, left), charred, to roll off to each side.
drum = stack.crop((round(102 * SC), round(150 * SC), round(158 * SC), round(212 * SC)))
dm = Image.new("L", drum.size); ImageDraw.Draw(dm).ellipse((0, 0, drum.width - 1, drum.height - 1), fill=255)
drum.putalpha(ImageChops.multiply(drum.getchannel("A"), dm.filter(ImageFilter.GaussianBlur(0.8))))
drum = ImageEnhance.Brightness(drum).enhance(0.75)


def ember(im, x, y, r, a):
    p = Image.new("RGBA", (CW, CH)); ImageDraw.Draw(p).ellipse((x - r, y - r, x + r, y + r), fill=(255, 150, 60, a))
    im.alpha_composite(p.filter(ImageFilter.GaussianBlur(r * 0.6)))


def wreck_base():
    im = blank()
    sc = Image.new("RGBA", (CW, CH)); ImageDraw.Draw(sc).ellipse((AX - 76, AY - 14, AX + 76, AY + 12), fill=(40, 20, 14, 105))
    im.alpha_composite(sc.filter(ImageFilter.GaussianBlur(6)))
    place(im, char, FOOT)
    d = ImageDraw.Draw(im)                                  # torn-open drum mouth in the middle of the row
    d.polygon([(AX - 8, AY - 22), (AX - 3, AY - 27), (AX + 2, AY - 23), (AX + 7, AY - 28), (AX + 9, AY - 19), (AX + 1, AY - 15), (AX - 6, AY - 17)], fill=(18, 10, 8, 255))
    r1 = drum.rotate(70, expand=True, resample=Image.BICUBIC); im.alpha_composite(r1, (AX - 78, AY - r1.height + 4))
    r2 = drum.rotate(-35, expand=True, resample=Image.BICUBIC); im.alpha_composite(r2, (AX + 44, AY - r2.height + 8))
    return im


WRECK = wreck_base()


def wisp(im, t, n=8):
    for q in range(3):
        s = ((t / n) + q / 3) % 1
        puff(im, AX + 2 + 6 * math.sin(2 * math.pi * s + q), AY - 26 - s * 48, 3 + s * 7, round(170 * (1 - s) * min(1, s * 4)))


wreck = []
for t in range(8):
    im = WRECK.copy()
    ember(im, AX - 2, AY - 20, 4, 110 + round(60 * math.sin(2 * math.pi * t / 8)))
    ember(im, AX - 30, AY - 8, 2.5, 80 + round(50 * math.sin(2 * math.pi * t / 8 + 2)))
    wisp(im, t); wreck.append(im)
pack(wreck, "fuel-drums-wreck", 8)

# --- Blast: 16 frames. ---
yy, xx = np.mgrid[0:CH, 0:CW].astype(float)
nz = np.random.default_rng(5)
noise = np.array(Image.fromarray((nz.random((CH // 8 + 1, CW // 8 + 1)) * 255).astype(np.uint8)).resize((CW, CH), Image.BICUBIC)).astype(float) / 255
CX, CY = AX, AY - 44


PUFFS = [(nz.uniform(-math.pi, 0.2), nz.uniform(0.2, 1.0), nz.uniform(0.55, 1.0)) for _ in range(16)]


def cloud(k):
    """The fireball as a cluster of shaded puffs: white-hot, then orange, then brown smoke."""
    e = 1 - (1 - min(1, k / 5)) ** 2
    heat = max(0.0, 1 - k / 4); smoke = min(1.0, max(0.0, (k - 4) / 4))
    fade = 1 if k < 9 else max(0.0, 1 - (k - 9) / 6)
    big = Image.new("RGBA", (CW * 2, CH * 2))
    for i, (a, dist, rf) in enumerate(PUFFS):
        cx = CX + math.cos(a) * dist * (6 + 44 * e); cy = CY + math.sin(a) * dist * (4 + 30 * e) - 2.4 * k
        r = rf * (6 + 20 * e)
        fire = np.array([235, 92, 28]) * (1 - heat) + np.array([255, 214, 90]) * heat
        base = fire * (1 - smoke) + np.array([96, 80, 70]) * smoke
        lite = np.minimum(base * 1.25 + 20, 255)
        p = Image.new("RGBA", (CW * 2, CH * 2)); d = ImageDraw.Draw(p)
        d.ellipse((2 * (cx - r), 2 * (cy - r), 2 * (cx + r), 2 * (cy + r)), fill=tuple(int(v) for v in base) + (int(235 * fade),), outline=tuple(int(v * 0.5) for v in base) + (int(235 * fade),), width=2)
        d.ellipse((2 * (cx - r * 0.75), 2 * (cy - r * 0.95), 2 * (cx + r * 0.45), 2 * (cy + r * 0.2)), fill=tuple(int(v) for v in lite) + (int(235 * fade),))
        big.alpha_composite(p.filter(ImageFilter.GaussianBlur(max(1.0, r * 0.12))))
    return big.resize((CW, CH), Image.LANCZOS)


FR = []
debris = [(-1.9, 3.2, "d"), (-1.2, 4.0, "c"), (-0.4, 3.6, "d"), (-2.6, 2.8, "c"), (-0.9, 4.4, "c"), (-2.2, 3.9, "d")]
for k in range(16):
    im = blank()
    if k == 0:
        shadow(im); place(im, stack, FOOT); ember(im, CX, CY + 10, 30, 255); ember(im, CX, CY + 10, 14, 255)
    else:
        if k >= 4:
            ww = WRECK.copy(); ww.putalpha(ww.getchannel("A").point(lambda v: v * min(1, (k - 3) / 4))); im.alpha_composite(ww)
        if k <= 2:
            place(im, stack, FOOT)
        t = k / 15
        rad = 18 + 70 * (1 - (1 - min(1, k / 6)) ** 2)
        im.alpha_composite(cloud(k))
        dd = ImageDraw.Draw(im)
        if 1 <= k <= 10:                                  # thrown drum pieces on arcs
            for i, (a, v, kind) in enumerate(debris):
                s = k * 0.9
                x = CX + math.cos(a) * v * s * 6; y = CY + math.sin(a) * v * s * 6 + 0.9 * s * s * 2.2
                if y > AY + 6: continue
                col = (235, 70, 170) if i % 3 == 0 else ((40, 190, 180) if i % 3 == 1 else (120, 60, 30))
                ang = k * 0.8 + i
                pts = [(x + 4 * math.cos(ang + q * 2.1), y + 3 * math.sin(ang + q * 2.1)) for q in range(3)]
                dd.polygon(pts, fill=col + (255,), outline=(30, 20, 20, 255))
        if 1 <= k <= 3:
            spark_burst(im, CX, CY, 14, 40 + 14 * k, 30 + k)
        if k >= 13:
            wisp(im, k - 13)
    FR.append(im)
FR[-1] = wreck[0]
pack(FR, "fuel-drums-blast", 12)
