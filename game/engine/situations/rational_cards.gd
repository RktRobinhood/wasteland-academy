class_name RationalCards
extends RefCounted
## The graphs of the Rational functions region (FAL-423): a linear-over-linear curve is
## drawn as two branches with a gap at its vertical asymptote, so no line is drawn across
## it. A curve is described by its triple (A, B, h): y = A + B/(x − h), asymptotes x = h
## and y = A. The checker draws each one again from the triple the question's text gives.
##
## Each graph is a pick-the-graph card (GdcKit.card) in one window, with the asymptotes
## dashed and the intercepts marked. A wrong card changes one thing:
##   flipped   B's sign: the branches sit in the other two corners (SL2.8.sketch-rational#0)
##   zero-at-h the asymptote and the zero swap places: it crosses the x-axis at x = h
##             (SL2.8.sketch-rational#1)
##   through   the same curve with a line drawn across the vertical asymptote (#2)
##   mirrored  the asymptote at x = −h
##   swapped   the asymptotes swapped: x = A and y = h

const WIN := [-8, 8, -8, 8]
const SAMPLES := 140


## The triple (A, B, h) of (ax + b)/(cx + d): [A, B, h] as floats.
static func triple(a: float, b: float, c: float, d: float) -> Array:
	return [a / c, (b * c - a * d) / (c * c), -d / c]


static func triple_of(s: Dictionary) -> Array:
	return triple(s.a, s.b, s.c, s.d)


static func y_at(t: Array, x: float) -> float:
	return t[0] + t[1] / (x - t[2])


## The x-intercept and y-intercept of a triple, as [x or null, y or null].
static func intercepts(t: Array) -> Array:
	var xi: Variant = t[2] - t[1] / t[0] if absf(t[0]) > 1e-12 else null
	var yi: Variant = t[0] - t[1] / t[2] if absf(t[2]) > 1e-12 else null
	return [xi, yi]


## The two branches of the curve inside the window: [[left points], [right points]], each
## running right up to the edge of the plot where it leaves, so nothing is drawn across
## x = h. With across, one curve joined over the gap (a wrong card).
static func branches(t: Array, across: bool = false, win: Array = WIN) -> Array:
	var A: float = t[0]
	var B: float = t[1]
	var h: float = t[2]
	var lo: float = win[2]
	var hi: float = win[3]
	var left: Array = []
	var right: Array = []
	for left_side in [true, false]:
		var x0: float = float(win[0]) if left_side else maxf(h, float(win[0]))
		var x1: float = minf(h, float(win[1])) if left_side else float(win[1])
		if x1 - x0 <= 1e-9:
			continue
		var pts: Array = []
		for i in SAMPLES + 1:
			var x := x0 + (x1 - x0) * float(i) / SAMPLES
			if absf(x - h) < 1e-9:
				continue
			var y := A + B / (x - h)
			if y >= lo and y <= hi:
				pts.append([x, y])
		# Where it meets the top or bottom of the plot next to x = h: y = hi or lo, so
		# x = h + B/(y − A). Left of h the curve runs off down when B > 0, right of it up.
		var up: bool = (B > 0.0) != left_side
		var yb: float = hi if up else lo
		var xb := h + B / (yb - A)
		if xb >= win[0] and xb <= win[1] and (xb < h) == left_side:
			if left_side:
				pts.append([xb, yb])
			else:
				pts.insert(0, [xb, yb])
		if left_side:
			left = pts
		else:
			right = pts
	if across and not left.is_empty() and not right.is_empty():
		return [left + right]
	return [left, right].filter(func(c): return c.size() > 1)


## A card: the curve with its asymptotes dashed and its intercepts marked (unlabelled: the
## grid is what the student reads them from).
static func card(t: Array, across: bool = false) -> Dictionary:
	var pts: Array = []
	var ic := intercepts(t)
	for p in [[ic[0], 0.0], [0.0, ic[1]]]:
		if p[0] != null and p[1] != null and absf(p[0]) <= WIN[1] and absf(p[1]) <= WIN[3]:
			pts.append([p[0], p[1], ""])
	var g := GdcKit.card(branches(t, across), pts, WIN, [[t[2], ""]], [[t[0], ""]])
	g.one_colour = true
	return g


## The graph a question shows (not a card): the curve, with the asymptotes dashed unless
## `asymptotes` is false, and the points given [[x, y, label]].
static func plot(t: Array, points: Array = [], asymptotes: bool = true, hlines: Array = []) -> Dictionary:
	var hl: Array = ([[t[0], ""]] if asymptotes else []) + hlines
	var g := Plot.spec(branches(t), points, WIN[0], WIN[1], WIN[2], WIN[3], hl, [[t[2], ""]] if asymptotes else [])
	g.one_colour = true
	return g


## The card of the mistake `mk` on the triple t.
static func wrong_triple(t: Array, mk: String) -> Array:
	match mk:
		"flipped":
			return [t[0], -t[1], t[2]]
		"zero-at-h":
			return [t[0], -t[1], t[2] - t[1] / t[0]]
		"mirrored":
			return [t[0], t[1], -t[2]]
		"swapped":
			return [t[2], t[1], t[0]]
		"negated":
			return [-t[0], -t[1], t[2]]
	return t
