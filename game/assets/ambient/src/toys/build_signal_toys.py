"""Signal Tower zone-map toys (FAL-1725), for the bottom band of B5-2 (below y 1475, clear of every
place's square). Pillow + numpy, CPU only.  python3 build_signal_toys.py

  dust-devil       16 @10  idle: a small dust devil twisting. Cell 72x120, anchor (36, 110) = its foot
  dust-devil-stir  24 @8   stir (3 s): blows apart into a low haze, then winds itself back up; ends on idle 0
  relay-box         8 @8   idle: a relay box on a pole, its teal lamp breathing. Cell 120x140, anchor (60, 124)
  relay-box-spark   8 @10  break, tap 1: jolts, sparks off the aerial, lamp flares
  relay-box-hiss   10 @12  break, tap 2: shakes, smoke from the door seam, lamp flickers red
  relay-box-pop    16 @12  break, tap 3, once: flash, puff, lid thrown off; ends on husk frame 0
  relay-box-husk    8 @8   after: scorched open husk, bent aerial, thin wisp, a spark now and then. still 0
Colours are sampled from the board's own ground, rust and teal metal.
"""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from toylib import pack

# ---------------- dust devil ----------------
DW, DH, DAX, DAY = 72, 120, 36, 110
HT = 92
rng = np.random.default_rng(7)
NP = 700
P_H = rng.uniform(0, 1, NP) ** 0.8           # height 0-1 (more near the foot)
P_T = rng.uniform(0, 2 * math.pi, NP)
P_K = rng.choice([1, 2], NP)                 # whole turns per loop, so the loop closes
P_R = rng.uniform(0.75, 1.1, NP)
P_C = rng.uniform(0, 1, NP)


def devil(t, spread=0.0, cap=1.0, fade=1.0, haze=0.0):
    """t: 0-1 through the 16-frame loop. spread: 0 intact -> 1 blown apart. cap: how much of the
    column has wound up (0-1). haze: a low dust cloud at the foot (0-1)."""
    S = 3
    big = Image.new("RGBA", (DW * S, DH * S)); d = ImageDraw.Draw(big)
    if haze > 0:
        hz = Image.new("RGBA", big.size); ImageDraw.Draw(hz).ellipse(((DAX - 30) * S, (DAY - 12) * S, (DAX + 30) * S, (DAY + 6) * S), fill=(240, 200, 150, int(190 * haze)))
        big.alpha_composite(hz.filter(ImageFilter.GaussianBlur(5 * S)))
    for i in range(NP):
        h = P_H[i]
        if h > cap:
            continue
        y = DAY - h * HT * (1 - 0.5 * spread)
        r = (3 + 22 * h ** 1.4) * P_R[i] * (1 + 2.5 * spread)
        cx = DAX + 4 * math.sin(2 * math.pi * t + h * 3) * h
        th = P_T[i] + 2 * math.pi * P_K[i] * t
        x = cx + r * math.cos(th)
        y = y + r * 0.22 * math.sin(th)
        front = 0.55 + 0.45 * math.sin(th)
        col = np.array([250, 226, 186]) * P_C[i] + np.array([214, 160, 110]) * (1 - P_C[i])
        col = col * (0.8 + 0.2 * front)
        a = int(235 * front * fade * (1 - 0.6 * spread) * (0.6 + 0.4 * (1 - h)))
        rr = (1.5 + 1.6 * h) * S
        d.ellipse((x * S - rr, y * S - rr, x * S + rr, y * S + rr), fill=tuple(int(v) for v in col) + (a,))
    big = big.filter(ImageFilter.GaussianBlur(0.7 * S))
    return big.resize((DW, DH), Image.LANCZOS)


idle = [devil(k / 16) for k in range(16)]
pack(idle, "dust-devil", 10, colors=64)
stir = []
for k in range(24):
    t = (k % 16) / 16
    if k < 6:                       # blows apart
        f = (k + 1) / 6
        stir.append(devil(t, spread=f, fade=1 - 0.7 * f, haze=f))
    elif k < 11:                    # haze settles
        f = (k - 5) / 5
        stir.append(devil(t, spread=1, cap=0, fade=0, haze=1 - 0.5 * f))
    else:                           # winds back up from the ground
        f = (k - 10) / 14
        stir.append(devil((k - 24) / 16 % 1, cap=f, fade=0.4 + 0.6 * f, haze=0.5 * (1 - f)))
stir[-1] = idle[0]
pack(stir, "dust-devil-stir", 8, colors=64)

# ---------------- relay box ----------------
CW, CH, AX, AY = 120, 140, 60, 124
S = 4
INK = (42, 24, 18, 255)
FRONT, SIDE, TOP = (84, 138, 124), (56, 98, 92), (132, 176, 156)
RUST = (156, 84, 42)
WOOD = (118, 72, 40)


def P(x, y):
    return (x * S, y * S)


def shadow(im, w=26, a=80):
    s = Image.new("RGBA", (CW, CH)); ImageDraw.Draw(s).ellipse((AX - w, AY - 5, AX + w, AY + 6), fill=(70, 26, 12, a))
    im.alpha_composite(s.filter(ImageFilter.GaussianBlur(3)))


def box(dx=0, dy=0, burnt=False, lid=True, bend=0.0, lamp=None):
    """The relay box drawn at 4x and brought down. lamp: (rgb, 0-1) or None."""
    big = Image.new("RGBA", (CW * S, CH * S)); d = ImageDraw.Draw(big)
    ox, oy = dx, dy
    k = 0.55 if burnt else 1.0
    def c(col): return tuple(int(v * k + (18 if burnt else 0)) for v in col) + (255,)
    # pole
    d.polygon([P(AX - 3 + ox, AY), P(AX + 3 + ox, AY), P(AX + 3 + ox, 62 + oy), P(AX - 3 + ox, 62 + oy)], fill=c(WOOD), outline=INK, width=S)
    d.line([P(AX - 1 + ox, AY - 4), P(AX - 1 + ox, 70 + oy)], fill=c((150, 98, 58)), width=S)
    # box: front, side, top (isometric, matches the board's crates)
    x0, y0, w, h, sk = 42 + ox, 58 + oy, 28, 30, 8
    d.polygon([P(x0 + w, y0), P(x0 + w + sk, y0 - 5), P(x0 + w + sk, y0 + h - 5), P(x0 + w, y0 + h)], fill=c(SIDE), outline=INK, width=S)
    d.polygon([P(x0, y0), P(x0 + w, y0), P(x0 + w, y0 + h), P(x0, y0 + h)], fill=c(FRONT), outline=INK, width=S)
    if lid:
        d.polygon([P(x0, y0), P(x0 + sk, y0 - 5), P(x0 + w + sk, y0 - 5), P(x0 + w, y0)], fill=c(TOP), outline=INK, width=S)
    else:
        d.polygon([P(x0 + 1, y0), P(x0 + sk, y0 - 4), P(x0 + w + sk - 1, y0 - 4), P(x0 + w - 1, y0)], fill=(20, 12, 10, 255))
    # door seam, hinges, grille, rust streaks, warning sticker
    d.line([P(x0 + w / 2, y0 + 3), P(x0 + w / 2, y0 + h - 3)], fill=INK, width=S)
    for gy in (y0 + 8, y0 + 11, y0 + 14):
        d.line([P(x0 + 4, gy), P(x0 + 11, gy)], fill=INK, width=S - 1)
    for rx, ry, rl in ((x0 + 18, y0 + 16, 9), (x0 + 6, y0 + 20, 7), (x0 + w + 3, y0 + 4, 12)):
        d.line([P(rx, ry), P(rx + 1, ry + rl)], fill=c(RUST), width=S + 1)
    if burnt:
        d.polygon([P(x0 + w / 2, y0 + 4), P(x0 + w - 3, y0 + 6), P(x0 + w - 4, y0 + h - 4), P(x0 + w / 2, y0 + h - 3)], fill=(24, 14, 12, 255))
    else:
        d.polygon([P(x0 + 20, y0 + 5), P(x0 + 24, y0 + 12), P(x0 + 16, y0 + 12)], fill=(232, 192, 64, 255), outline=INK, width=2)
    # aerial
    bx, by = x0 + w + 3, y0 - 4
    tip = (bx + 4 + 10 * bend, by - 26 + 12 * bend)
    mid = (bx + 2 + 6 * bend, by - 13)
    d.line([P(bx, by), P(*mid), P(*tip)], fill=INK, width=S + 1)
    d.ellipse((tip[0] * S - 2 * S, tip[1] * S - 2 * S, tip[0] * S + 2 * S, tip[1] * S + 2 * S), fill=c((190, 120, 60)), outline=INK, width=2)
    im = big.resize((CW, CH), Image.LANCZOS)
    lx, ly = x0 + 5, y0 - 2
    if lamp:
        col, a = lamp
        g = Image.new("RGBA", (CW, CH)); gd = ImageDraw.Draw(g)
        gd.ellipse((lx - 7, ly - 7, lx + 7, ly + 7), fill=col + (int(150 * a),))
        im.alpha_composite(g.filter(ImageFilter.GaussianBlur(3)))
        g = Image.new("RGBA", (CW, CH)); ImageDraw.Draw(g).ellipse((lx - 2, ly - 2, lx + 2, ly + 2), fill=tuple(min(255, v + 90) for v in col) + (int(255 * (0.4 + 0.6 * a)),))
        im.alpha_composite(g)
    return im, tip


TEALL = (90, 240, 210)


def spark(im, cx, cy, n, length, seed, up=True):
    g = np.random.default_rng(seed); big = Image.new("RGBA", (CW * 2, CH * 2)); d = ImageDraw.Draw(big)
    for _ in range(n):
        a = g.uniform(-3.0, -0.1) if up else g.uniform(-math.pi, math.pi); l = g.uniform(0.4, 1) * length
        ex, ey = cx + l * math.cos(a), cy + l * math.sin(a)
        d.line([(2 * cx, 2 * cy), (2 * ex, 2 * ey)], fill=(255, 236, 150, 255), width=2)
        d.ellipse((2 * ex - 2, 2 * ey - 2, 2 * ex + 2, 2 * ey + 2), fill=(255, 252, 225, 255))
    im.alpha_composite(big.resize((CW, CH), Image.LANCZOS))


def puff(im, cx, cy, rad, a, col=(200, 186, 170)):
    p = Image.new("RGBA", (CW, CH)); ImageDraw.Draw(p).ellipse((cx - rad, cy - rad * 0.85, cx + rad, cy + rad * 0.85), fill=col + (int(a),))
    im.alpha_composite(p.filter(ImageFilter.GaussianBlur(rad * 0.35)))


def frame(**kw):
    im = Image.new("RGBA", (CW, CH)); shadow(im); b, tip = box(**kw); im.alpha_composite(b); return im, tip


idle = []
for k in range(8):
    im, _ = frame(lamp=(TEALL, 0.5 - 0.5 * math.cos(2 * math.pi * k / 8))); idle.append(im)
pack(idle, "relay-box", 8)

sp = []
for k, dx in enumerate([0, 2, -2, 1, -1, 1, 0, 0]):
    im, tip = frame(dx=dx, lamp=((235, 255, 250), 1.0) if k < 3 else (TEALL, 0.3 + 0.2 * (k % 2)))
    if k < 5:
        spark(im, *tip, 7 - k, 14 - k, k)
    sp.append(im)
pack(sp, "relay-box-spark", 10)

g = np.random.default_rng(4)
hiss = []
SEAM = (56, 76)
for k in range(10):
    im, tip = frame(dx=int(g.integers(-1, 2)), dy=int(g.integers(-1, 1)), lamp=((255, 70, 50), 1.0 if k % 3 else 0.15))
    for q in range(4):
        s = (k / 10 + q / 4) % 1
        puff(im, SEAM[0] + 4 + s * 26, SEAM[1] - s * 30, 2.5 + s * 9, 210 * (1 - s))
    if k % 4 == 1:
        spark(im, SEAM[0] + 2, SEAM[1], 5, 10, 40 + k)
    if k % 5 == 3:
        spark(im, *tip, 4, 9, 60 + k)
    hiss.append(im)
pack(hiss, "relay-box-hiss", 12)


def husk_base():
    im = Image.new("RGBA", (CW, CH))
    sc = Image.new("RGBA", (CW, CH)); ImageDraw.Draw(sc).ellipse((AX - 34, AY - 9, AX + 34, AY + 9), fill=(34, 18, 12, 120))
    im.alpha_composite(sc.filter(ImageFilter.GaussianBlur(5)))
    b, tip = box(burnt=True, lid=False, bend=1.0)
    im.alpha_composite(b)
    soot = Image.new("RGBA", (CW, CH)); sd = ImageDraw.Draw(soot)
    for (x, y, r) in ((50, 60, 7), (64, 56, 6), (70, 70, 5), (47, 78, 4), (73, 52, 5)):
        sd.ellipse((x - r, y - r, x + r, y + r), fill=(20, 12, 10, 150))
    soot = soot.filter(ImageFilter.GaussianBlur(2)); soot.putalpha(Image.fromarray((np.array(soot.getchannel("A")).astype(float) * (np.array(b.getchannel("A")) > 0)).astype(np.uint8)))
    im.alpha_composite(soot)
    d = ImageDraw.Draw(im)                       # the lid, landed on the ground, scorched
    d.polygon([(AX + 22, AY - 2), (AX + 34, AY - 5), (AX + 40, AY - 1), (AX + 28, AY + 2)], fill=(80, 96, 86, 255), outline=INK)
    return im, tip


HUSK, HTIP = husk_base()


def wisp(im, t):
    for q in range(3):
        s = (t + q / 3) % 1
        puff(im, 56 + 5 * math.sin(2 * math.pi * s + q), 52 - s * 40, 2 + s * 6, 170 * (1 - s) * min(1, s * 4), (150, 140, 132))


husk = []
for k in range(8):
    im = HUSK.copy()
    e = Image.new("RGBA", (CW, CH)); ImageDraw.Draw(e).ellipse((51, 52, 61, 58), fill=(255, 140, 50, 90 + int(60 * math.sin(2 * math.pi * k / 8))))
    im.alpha_composite(e.filter(ImageFilter.GaussianBlur(2)))
    wisp(im, k / 8)
    if k == 5:
        spark(im, *HTIP, 3, 7, 99)
    husk.append(im)
pack(husk, "relay-box-husk", 8)

pop = []
for k in range(16):
    im = Image.new("RGBA", (CW, CH))
    if k >= 4:
        h = HUSK.copy(); h.putalpha(h.getchannel("A").point(lambda v: int(v * min(1, (k - 3) / 4)))); im.alpha_composite(h)
    if k <= 2:
        b, _ = frame(lamp=((255, 250, 235), 1.0)); im.alpha_composite(b)
    if k <= 3:                                   # the flash
        fl = Image.new("RGBA", (CW, CH)); ImageDraw.Draw(fl).ellipse((56 - 30 + 6 * k, 70 - 26 + 5 * k, 56 + 30 - 6 * k, 70 + 26 - 5 * k), fill=(255, 238, 190, 230 - 40 * k))
        im.alpha_composite(fl.filter(ImageFilter.GaussianBlur(6)))
        spark(im, 56, 66, 16, 26 + 8 * k, 70 + k, up=False)
    if 1 <= k <= 13:                             # the smoke puff rising and thinning
        f = (k - 1) / 12
        for q, (ox, oy) in enumerate([(-8, 0), (8, -3), (0, -10), (-4, -16), (6, -20)]):
            puff(im, 56 + ox * (1 + f), 70 + oy * (1 + f) - 26 * f, 7 + 12 * f, 220 * (1 - f) ** 1.2, (110, 100, 96) if q % 2 else (150, 138, 128))
    if 1 <= k <= 9:                              # the lid, tumbling up and off to the right
        s = k
        lx, ly = 60 + 4 * s, 56 - 14 * s + 1.6 * s * s
        lid = Image.new("RGBA", (40, 40)); ImageDraw.Draw(lid).polygon([(6, 18), (12, 14), (34, 14), (28, 18)], fill=TOP + (255,), outline=INK)
        lid = lid.rotate(-35 * s, resample=Image.BICUBIC)
        im.alpha_composite(lid, (int(lx - 20), int(ly - 20)))
    if k >= 13:
        wisp(im, (k - 13) / 8)
    pop.append(im)
pop[-1] = husk[0]
pack(pop, "relay-box-pop", 12)
