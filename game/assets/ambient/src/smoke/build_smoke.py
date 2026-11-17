# Builds smoke.json: puffs leaving the three Engine Core stacks, two per stack half a loop
# apart. Canvas = board rect (470,860)-(620,1020). Run: python3 build_smoke.py
import json
OX, OY, N = 470, 860, 24
stacks = [(490, 982), (526, 1000), (553, 1011)]
s = [{"cmd": "file.new", "params": {"width": 150, "height": 160, "fps": 12}}]
lerp = lambda a, b, t: a + (b - a) * t
def state(x0, y0, x1, y1, t):
    a = 90 * min(1, t / 0.15) * (1 - max(0, (t - 0.3) / 0.7))
    return {"x": lerp(x0, x1, t ** 0.8), "y": lerp(y0, y1, t), "scale_x": 100 + 170 * t,
            "scale_y": 100 + 170 * t, "alpha": a}
first = True
for (bx, by) in stacks:
    x0, y0 = bx - OX, by - OY - 4
    x1, y1 = x0 + 55, y0 - 75   # along the painted plume, which leans right
    for half in (0, 1):
        if not first:
            s.append({"cmd": "layer.new", "params": {}})
        spans = [(0, N - 1, 0.0, 1.0)] if half == 0 else [(0, 11, 0.5, 1.0), (12, N - 1, 0.0, 0.5)]
        for i, (f0, f1, t0, t1) in enumerate(spans):
            s.append({"cmd": "timeline.goto", "params": {"frame": f0}})
            if f0 > 0:
                s.append({"cmd": "timeline.insert_blank_keyframe", "params": {"frame": f0}})
            s.append({"cmd": "draw.ellipse", "params": {"x": x0 - 7, "y": y0 - 7, "w": 14, "h": 14,
                      "fill": "#7A7068", "stroke": "#7A706800", "object": True}})
            if first:
                s.append({"cmd": "timeline.insert_frame", "params": {"frame": N - 1}})
                first = False
        for (f0, f1, t0, t1) in spans:
            s.append({"cmd": "timeline.create_motion_tween", "params": {"frame": f0}})
            keys = [(f0, t0), (f1, t1)]
            if t0 < 0.15 < t1:
                keys.append((round(f0 + (0.15 - t0) / (t1 - t0) * (f1 - f0)), 0.15))
            if t0 < 0.3 < t1:
                keys.append((round(f0 + (0.3 - t0) / (t1 - t0) * (f1 - f0)), 0.3))
            for f, t in keys:
                for k, v in state(x0, y0, x1, y1, t).items():
                    s.append({"cmd": "motion.set_key", "params": {"property": k, "value": round(v, 1), "frame": f}})
s.append({"cmd": "file.export_sprite_sheet", "params": {"path": "../../engine-smoke-sheet.png", "columns": 6, "background": False, "confirm": True}})
json.dump(s, open("smoke.json", "w"), indent=0)
