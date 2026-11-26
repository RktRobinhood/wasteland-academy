"""Signal Tower zone-map life (FAL-1725), on Matt's B5-2 board (map/functions/background.webp,
1080 x 1920 portrait). Pillow + numpy, CPU only.  python3 build_signal.py

Ambient (registered on the painting: every glow is grown from the board's own lit pixels,
and the cloth pieces are the board's own pixels, warped):
  tower-lights   24 @8  half-res cells, scale 2. Beacon on the tallest needle, a light running
                        up the teal core, the gate's teal lamps breathing, its orange lamp dipping. still 0
  yards-lamps    24 @8  half-res, scale 2. Magenta and teal shed lamps breathing in turn. still 0
  pool-ripples   24 @8  half-res, scale 2. Rings round the pipe's legs and the steps, glints. hidden
  curve-flags     8 @8  the four pennants on the wire curve fluttering, staggered. still 0
  tower-banners   8 @8  the two magenta banners on the mesa poles rippling. still 0
Toys (bottom band, clear of every place's square):
  dust-devil      16 @10 a small twisting dust devil. hidden with reduced motion
  dust-devil-stir 24 @8  stir: blows apart into haze, then winds itself back up
  relay-box       8 @8   a relay box on a pole, its lamp breathing. still 0
  relay-box-spark 8 @10  break, tap 1: jolts, sparks off the aerial
  relay-box-hiss 10 @12  break, tap 2: shakes, smoke from the seam, lamp flickers red
  relay-box-pop  16 @12  break, tap 3 (once): flash, smoke, lid thrown; ends on the husk
  relay-box-husk  8 @8   after: scorched husk, bent aerial, a thin wisp and a spark now and then. still 0
"""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from toylib import ROOT, pack, sample

BOARD = Image.open(ROOT.parent / "map" / "functions" / "background.webp").convert("RGB")
BA = np.array(BOARD).astype(float)
R, G, B = BA[..., 0], BA[..., 1], BA[..., 2]
TEAL = (G > 190) & (B > 170) & (R < 170)
MAG = (R > 215) & (B > 150) & (G < 110)
N = 24


def blur(a, r):
    if r <= 0:
        return a
    im = Image.fromarray(np.clip(a * 255, 0, 255).astype(np.uint8))
    return np.array(im.filter(ImageFilter.GaussianBlur(r))).astype(float) / 255


def rgba(col, alpha):
    """A full-res RGBA float array: one colour (or per-pixel HxWx3) at alpha 0-1."""
    h, w = alpha.shape
    c = np.broadcast_to(np.array(col, float), (h, w, 3)) if np.ndim(col) == 1 else col
    return np.concatenate([c, np.clip(alpha, 0, 1)[..., None] * 255], -1)


def over(dst, src):
    """Alpha-composite float RGBA arrays (straight alpha)."""
    sa = src[..., 3:4] / 255; da = dst[..., 3:4] / 255
    oa = sa + da * (1 - sa)
    rgb = np.where(oa > 1e-4, (src[..., :3] * sa + dst[..., :3] * da * (1 - sa)) / np.maximum(oa, 1e-4), 0)
    return np.concatenate([rgb, oa * 255], -1)


def to_img(a, half=False):
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    return im.resize((im.width // 2, im.height // 2), Image.LANCZOS) if half else im


def radial(shape, cx, cy, r):
    yy, xx = np.mgrid[0:shape[0], 0:shape[1]].astype(float)
    return np.exp(-((xx - cx) ** 2 + (yy - cy) ** 2) / (2 * r * r))


def wave(t):
    return 0.5 - 0.5 * math.cos(2 * math.pi * t)


# ---------------- tower-lights ----------------
TX0, TY0, TX1, TY1 = 460, 540, 660, 1020
tm = TEAL[TY0:TY1, TX0:TX1].astype(float)
yy, xx = np.mgrid[TY0:TY1, TX0:TX1].astype(float)
core = tm * ((xx > 528) & (xx < 590) & (yy > 680) & (yy < 925))
gate = tm * (((xx < 525) | (xx > 605)) & (yy > 930) & (yy < 1015))
BEACON = (547 - TX0, 561 - TY0)
ORANGE = (573 - TX0, 957 - TY0)
frames = []
for k in range(N):
    s = k / N
    yc = 935 - s * 290                                    # a band climbs the column, 3 s a pass
    band = np.exp(-((yy - yc) / 24) ** 2)
    a = np.zeros(tm.shape + (4,))
    c_al = blur(core, 0.8) * (0.12 + 0.8 * band)
    a = over(a, rgba((90, 255, 215), blur(core * band, 9) * 0.55))
    a = over(a, rgba((215, 255, 245), c_al))
    g = 0.15 + 0.45 * wave(s)
    a = over(a, rgba((90, 255, 215), blur(gate, 7) * g * 0.8))
    a = over(a, rgba((210, 255, 240), blur(gate, 0.8) * g))
    o = 0.12 if k in (19, 20) else 0.55                  # the orange lamp dips once a loop
    a = over(a, rgba((255, 160, 60), radial(tm.shape, *ORANGE, 7) * o))
    p = 0.35 + 0.65 * wave(s + 0.5)                       # the beacon, a slow glow
    a = over(a, rgba((255, 90, 60), radial(tm.shape, *BEACON, 9) * p * 0.6))
    a = over(a, rgba((255, 225, 200), radial(tm.shape, *BEACON, 2.2) * (0.4 + 0.6 * p)))
    frames.append(to_img(a, half=True))
pack(frames, "tower-lights", 8)

# ---------------- yards-lamps ----------------
YX0, YY0, YX1, YY1 = 60, 470, 360, 640
mg = MAG[YY0:YY1, YX0:YX1].astype(float)
tl = TEAL[YY0:YY1, YX0:YX1].astype(float)
frames = []
for k in range(N):
    s = k / N
    m1 = 0.2 + 0.6 * wave(s); m2 = 0.2 + 0.6 * wave(s + 0.5)
    a = np.zeros(mg.shape + (4,))
    a = over(a, rgba((255, 60, 190), blur(mg, 10) * m1 * 0.9))
    a = over(a, rgba((255, 200, 240), blur(mg, 0.8) * m1))
    a = over(a, rgba((90, 255, 215), blur(tl, 8) * m2 * 0.8))
    a = over(a, rgba((215, 255, 245), blur(tl, 0.8) * m2 * 0.8))
    frames.append(to_img(a, half=True))
pack(frames, "yards-lamps", 8)

# ---------------- pool-ripples ----------------
PX0, PY0, PX1, PY1 = 640, 1150, 1080, 1310
pa = BA[PY0:PY1, PX0:PX1]
water = ((pa[..., 1] > pa[..., 0] + 15) & (pa[..., 2] > pa[..., 0] - 5)).astype(float)
water = blur(np.array(Image.fromarray((water * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(5))).astype(float) / 255, 1.5)
SOURCES = [(700, 1232), (742, 1234), (815, 1198), (850, 1184), (862, 1232), (905, 1220), (968, 1196), (1022, 1172)]
rng = np.random.default_rng(3)
GLINTS = [(rng.uniform(0, PX1 - PX0), rng.uniform(0, PY1 - PY0), rng.integers(0, N)) for _ in range(26)]
frames = []
for k in range(N):
    big = Image.new("L", ((PX1 - PX0) * 2, (PY1 - PY0) * 2)); d = ImageDraw.Draw(big)
    for i, (sx, sy) in enumerate(SOURCES):
        for ring in (0, 0.5):
            f = (k / N + i * 0.37 + ring) % 1
            r = 4 + 34 * f; al = int(235 * (1 - f) ** 1.2)
            cx, cy = (sx - PX0) * 2, (sy - PY0) * 2 + 6
            d.ellipse((cx - 2 * r, cy - 0.7 * r, cx + 2 * r, cy + 0.7 * r), outline=al, width=5)
    rings = np.array(big.resize((PX1 - PX0, PY1 - PY0), Image.LANCZOS)).astype(float) / 255
    gl = np.zeros_like(rings)
    for gx, gy, g0 in GLINTS:
        f = ((k - g0) % N) / 6
        if f < 1:
            gl += radial(gl.shape, gx, gy, 1.4) * math.sin(math.pi * f)
    a = rgba((225, 255, 245), np.clip(rings * 1.1 + gl * 1.0, 0, 0.95) * water)
    frames.append(to_img(a, half=True))
pack(frames, "pool-ripples", 8)


# ---------------- cloth: flags and banners (the board's own pixels, warped) ----------------
def inpaint(rgb, hole, n=60):
    """Diffuse the surrounding colour into the hole."""
    out = rgb.copy(); known = ~hole
    for _ in range(n):
        acc = np.zeros_like(out); cnt = np.zeros(hole.shape)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            sh = np.roll(np.roll(out, dy, 0), dx, 1); kn = np.roll(np.roll(known, dy, 0), dx, 1)
            acc += sh * kn[..., None]; cnt += kn
        fill = hole & (cnt > 0)
        out[fill] = acc[fill] / cnt[fill][:, None]
        known = known | fill
    return out


def cloth(rect, cloths, name, nf=8, fps=8):
    """cloths: (x0, y0, x1, y1, axis, phase) board boxes round each piece of cloth. axis 'x': a pennant
    flying right from its pole at x0 (rows wave up and down); 'y': a banner hanging from y0 (columns sway)."""
    X0, Y0, X1, Y1 = rect
    base = BA[Y0:Y1, X0:X1].copy()
    hsv = np.array(BOARD.crop(rect).convert("HSV")).astype(float)
    frames = [np.zeros((Y1 - Y0, X1 - X0, 4)) for _ in range(nf)]
    for (cx0, cy0, cx1, cy1, axis, ph) in cloths:
        sl = (slice(cy0 - Y0, cy1 - Y0), slice(cx0 - X0, cx1 - X0))
        p = base[sl]; hv = hsv[sl]
        pink = (hv[..., 0] > 205) & (hv[..., 1] > 110) & (hv[..., 2] > 110)
        if axis == "x":                                    # keep the pole: the cloth starts right of it
            cols = np.nonzero(pink.any(0))[0]; px0 = cols.min()
        else:
            rows = np.nonzero(pink.any(1))[0]; px0 = rows.min()
        m = Image.fromarray((pink * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5))
        m = np.array(m) > 0
        if axis == "x":
            m[:, :px0] = False
        else:
            m[:px0, :] = False
        bg = inpaint(p, m)
        h, w = m.shape
        yy, xx = np.mgrid[0:h, 0:w].astype(float)
        L = max(1, (w - px0) if axis == "x" else (h - px0))
        for k in range(nf):
            t = k / nf + ph
            if axis == "x":
                u = np.clip((xx - px0) / L, 0, 1)
                off = 1.8 * u * np.sin(2 * math.pi * ((xx - px0) / 13 - t))
                sx, sy = xx + 0.6 * u * np.sin(2 * math.pi * t), yy - off
            else:
                u = np.clip((yy - px0) / L, 0, 1)
                off = 1.6 * u * np.sin(2 * math.pi * ((yy - px0) / 22 - t))
                sx, sy = xx - off, yy
            src = np.concatenate([p, m[..., None] * 255.0], -1)
            warped = sample(src, sx, sy)
            piece = np.concatenate([bg, np.full((h, w, 1), 255.0)], -1)
            piece = over(piece, warped)
            # Fade the patch into the board round its edge (the patch is the board there anyway).
            d = np.minimum.reduce([xx, w - 1 - xx, yy, h - 1 - yy])
            piece[..., 3] *= np.clip(d / 4, 0, 1)
            fr = frames[k][sl]
            frames[k][sl] = over(fr, piece)
    pack([to_img(f) for f in frames], name, fps)


cloth((812, 720, 1072, 846), [(818, 764, 852, 791, "x", 0.0), (897, 792, 929, 822, "x", 0.25),
                              (958, 726, 992, 754, "x", 0.5), (1030, 808, 1068, 841, "x", 0.75)], "curve-flags")
cloth((382, 800, 696, 902), [(388, 806, 426, 896, "y", 0.0), (652, 804, 690, 886, "y", 0.5)], "tower-banners")
