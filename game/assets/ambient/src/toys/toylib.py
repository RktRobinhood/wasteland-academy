"""Shared helpers for the world-map tap toys (FAL-1724). Pillow + numpy only, CPU.

pack(frames, name, fps): writes ../../<name>-sheet.png + .json (TexturePacker frames, like
the AniCraft sheets), max 8 cells a row, quantised to a 256-colour RGBA palette to keep
the sheets small. Every cell's outer pixel row is faded to alpha 0 (check_edges.py).
"""
import json
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]          # game/assets/ambient
WORLD = ROOT.parent / "map" / "overworld-wide.webp"


def world():
    return Image.open(WORLD).convert("RGB")


def sample(arr, xs, ys):
    """Bilinear sample of an HxWxC float array at float coords (edge-clamped, alpha 0 outside)."""
    h, w = arr.shape[:2]
    x0 = np.floor(xs).astype(int); y0 = np.floor(ys).astype(int)
    fx = (xs - x0)[..., None]; fy = (ys - y0)[..., None]
    out = 0
    for dx, dy, wt in ((0, 0, (1 - fx) * (1 - fy)), (1, 0, fx * (1 - fy)), (0, 1, (1 - fx) * fy), (1, 1, fx * fy)):
        xi = x0 + dx; yi = y0 + dy
        inside = ((xi >= 0) & (xi < w) & (yi >= 0) & (yi < h))[..., None]
        v = arr[np.clip(yi, 0, h - 1), np.clip(xi, 0, w - 1)] * inside
        out = out + v * wt
    return out


def premul(rgba):
    a = rgba[..., 3:4] / 255.0
    return np.concatenate([rgba[..., :3] * a, rgba[..., 3:4]], -1)


def unpremul(p):
    a = np.clip(p[..., 3:4], 0, 255)
    rgb = np.where(a > 0.5, p[..., :3] * 255.0 / np.maximum(a, 1e-3), 0)
    return np.clip(np.concatenate([rgb, a], -1), 0, 255).astype(np.uint8)


def edge_fade(img, px=1):
    a = np.array(img.getchannel("A")).astype(float)
    h, w = a.shape
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.minimum.reduce([xx + 0.5, w - xx - 0.5, yy + 0.5, h - yy - 0.5])
    t = np.clip((d - 0.5) / max(px, 1), 0, 1)   # outer pixel row -> 0
    a = a * (t * t * (3 - 2 * t))
    img = img.copy(); img.putalpha(Image.fromarray(a.astype(np.uint8)))
    return img


def pack(frames, name, fps, colors=256, feather=2):
    frames = [edge_fade(f, feather) for f in frames]
    w, h = frames[0].size
    cols = min(8, len(frames)); rows = -(-len(frames) // cols)
    sheet = Image.new("RGBA", (cols * w, rows * h), (0, 0, 0, 0))
    meta = {}
    for i, f in enumerate(frames):
        x, y = (i % cols) * w, (i // cols) * h
        sheet.paste(f, (x, y))
        meta[f"{name}-sheet_{i + 1:04d}"] = {"duration": round(1000 / fps), "frame": {"h": h, "w": w, "x": x, "y": y},
            "rotated": False, "sourceSize": {"h": h, "w": w}, "spriteSourceSize": {"h": h, "w": w, "x": 0, "y": 0}, "trimmed": False}
    # Zero RGB under alpha 0 first, so the palette isn't spent on invisible colour.
    arr = np.array(sheet); arr[arr[..., 3] == 0] = 0; sheet = Image.fromarray(arr)
    if colors:
        sheet = sheet.quantize(colors=colors, method=Image.Quantize.LIBIMAGEQUANT, dither=Image.Dither.FLOYDSTEINBERG)
    png = ROOT / f"{name}-sheet.png"
    sheet.save(png, optimize=True)
    (ROOT / f"{name}-sheet.json").write_text(json.dumps({"frames": meta, "meta": {"app": "FAL-1724 toylib (Pillow)",
        "format": "RGBA8888", "frameRate": float(fps), "image": png.name, "scale": "1",
        "size": {"h": sheet.height, "w": sheet.width}, "version": "1"}}, indent=1, sort_keys=True))
    print(f"{name}-sheet.png  {len(frames)} x {w}x{h}  {png.stat().st_size/1024:.1f} KB")
    return frames
