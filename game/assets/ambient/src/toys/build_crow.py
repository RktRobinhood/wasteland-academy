"""The crow perched on the Scrap Fields crane jib (FAL-1724), drawn in the flat ink of
crow-sheet (31,41,55), 4x supersampled.  python3 build_crow.py

  crow-perch    8 cells @8 fps: sits, bobs its head, flicks its tail. Anchor = feet (36, 52).
  crow-takeoff  8 cells @12 fps: startle, crouch, wings up, leaps up and right. The last
                cell's body sits at +14, -22 from the feet; hand over to crow (flight) there.
  crow-land     crow-takeoff played backwards (same cells), for coming back to the perch.
"""
import math
from PIL import Image, ImageDraw
from toylib import pack

INK = (31, 41, 55, 255)
EYE = (214, 190, 120, 255)
W, H, S = 72, 60, 4
FEET = (36, 52)


def P(x, y):
    return (x * S, y * S)


def crow(head=0.0, tail=0.0, crouch=0.0, wing=None, lift=(0, 0), tilt=0.0):
    """wing: None (folded) or the wing angle in degrees above level (both wings, 3/4 view)."""
    im = Image.new("RGBA", (W * S, H * S)); d = ImageDraw.Draw(im)
    fx, fy = FEET[0] + lift[0], FEET[1] + lift[1]
    by = fy - 8 + 2 * crouch                       # body centre
    bx = fx
    if lift == (0, 0) or lift[1] > -3:             # legs on the jib
        d.line([P(fx - 2, fy), P(fx - 1, by + 3)], fill=INK, width=S + 1)
        d.line([P(fx + 2, fy), P(fx + 1, by + 3)], fill=INK, width=S + 1)
    else:                                          # legs tucked back
        d.line([P(bx - 3, by + 3), P(bx - 7, by + 6)], fill=INK, width=S + 1)
    t = math.radians(tilt)
    def rot(x, y):
        x, y = x - bx, y - by
        return P(bx + x * math.cos(t) - y * math.sin(t), by + x * math.sin(t) + y * math.cos(t))
    d.ellipse([P(bx - 8, by - 5), P(bx + 7, by + 5)], fill=INK)           # body
    tl = 3 * tail
    d.polygon([rot(-6, -2), rot(-17, 1 - tl), rot(-16, 4 - tl), rot(-5, 4)], fill=INK)   # tail
    hx, hy = bx + 7 + head * 1.5, by - 6 + 2 * crouch * 0.5 + abs(head) * 1.2
    d.ellipse([P(hx - 4, hy - 4), P(hx + 4, hy + 4)], fill=INK)           # head
    d.polygon([P(hx + 3, hy - 1.5), P(hx + 9 + head, hy + 0.5), P(hx + 3, hy + 2)], fill=INK)  # beak
    d.ellipse([P(hx + 0.6, hy - 1.6), P(hx + 2.2, hy)], fill=EYE)
    if wing is None:
        d.polygon([rot(-4, -4), rot(6, -4), rot(2, 2), rot(-12, 2)], fill=(24, 32, 44, 255))
    else:
        for side, span in ((-1, 26), (1, 20)):
            a = math.radians(wing)
            tipx, tipy = bx + side * span * math.cos(a) * 0.9, by - 2 - span * math.sin(a)
            midx, midy = bx + side * span * 0.5 * math.cos(a), by - 3 - span * 0.55 * math.sin(a)
            d.polygon([P(bx - 4 * side, by - 3), P(midx, midy - 2), P(tipx, tipy), P(midx + side * 2, midy + 3), P(bx + 3 * side, by + 2)], fill=INK)
    return im.resize((W, H), Image.LANCZOS)


perch = [crow(), crow(), crow(head=0.6), crow(head=1.0), crow(head=0.6), crow(), crow(tail=1), crow(tail=0.4)]
pack(perch, "crow-perch", 8)
take = [crow(head=-0.5, tail=1), crow(crouch=1.5, tail=1, wing=10), crow(crouch=2, wing=60),
        crow(wing=75, lift=(2, -4), tilt=-10), crow(wing=-20, lift=(5, -9), tilt=-14),
        crow(wing=50, lift=(8, -14), tilt=-10), crow(wing=-10, lift=(11, -18), tilt=-6), crow(wing=30, lift=(14, -22), tilt=-4)]
pack(take, "crow-takeoff", 12)
pack(take[::-1], "crow-land", 12)
