class_name Plot
extends RefCounted
## Graph specs for curves that aren't parabolas (FAL-418): exponential models, log
## functions and the log of a quadratic. ui/graph_view.gd draws a spec with "curves"
## as sampled polylines, plus dashed asymptotes. Marked points are as the quadratic
## graph has them: {"x", "y", "label"}.

const SAMPLES := 160


## A curve sampled at SAMPLES + 1 points from x0 to x1: [[x, y], ...]. Points where f
## is not finite (outside a log's domain) are left out.
static func sample(f: Callable, x0: float, x1: float) -> Array:
	var out: Array = []
	for i in SAMPLES + 1:
		var x := x0 + (x1 - x0) * float(i) / SAMPLES
		var y: float = f.call(x)
		if is_finite(y):
			out.append([x, y])
	return out


## A graph spec. curves: sampled curves; points: [[x, y, label], ...]; hlines and vlines:
## [[at, label], ...] drawn dashed. The window is [x0, x1] × [y0, y1] in whole units.
static func spec(curves: Array, points: Array, x0: int, x1: int, y0: int, y1: int, hlines: Array = [], vlines: Array = [],
		caption: String = "") -> Dictionary:
	return {
		"curves": curves,
		"points": points.map(func(p): return {"x": float(p[0]), "y": float(p[1]), "label": p[2]}),
		"hlines": hlines.map(func(h): return {"at": float(h[0]), "label": h[1]}),
		"vlines": vlines.map(func(v): return {"at": float(v[0]), "label": v[1]}),
		"x0": x0, "x1": x1, "y0": y0, "y1": y1, "caption": caption,
	}


## A round top for a window that holds y_max: 1, 2 or 5 times a power of ten, with room.
static func nice_top(y_max: float) -> int:
	var target := y_max * 1.15
	var p := 1
	while p * 10 <= target:
		p *= 10
	for m in [1, 2, 5, 10]:
		if m * p >= target:
			return m * p
	return 10 * p
