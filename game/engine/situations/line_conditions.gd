class_name LineConditionsSituation
extends RefCounted
## The `line-conditions` situation (curriculum/question-types.json): a segment and a line built
## from it, for fn-line-from-conditions and fn-concept-gradient-meaning (FAL-424). The two points
## come first, then the gradient, the midpoint and a new line through a chosen point, so any of
## them can be hidden.
##
## generate() returns, by mode (need.mode):
##   line / any-two   ax, ay, bx, by (A and B), dx, dy (B − A), m, c0 (the line AB), a0, b0, d0 (AB as
##            a0x + b0y + d0 = 0), rel ("para" or "perp"), n (the new gradient), px, py (P on the
##            new line), c, ga, gb, gd (the new line as ax + by + d = 0), xi (its x-intercept),
##            area (its triangle with the axes), fx, fy (a further point), hide ("x" or "y", which
##            of them is asked), form ("sl" or "gen", how an equation is asked), gform (how a
##            given line is written), rel2 (check-perpendicular: "para", "perp", "neither", "swap")
##   intercepts / intercepts-eq   the same with A = (p, 0) and B = (0, q), both on the grid, and
##            the new line AB itself
##   bisector   the same with P = M, rel = "perp"
##   midline    tx, ty (the origin or another point) and the new line through M and T; hx, hy (the
##            point half the differences gives, the slip)
## mx, my is the midpoint, whole where need.mid or a mode asks it.
## Paper 2 (any-two and intercepts-eq only): the gradient's denominator is more than 5 and its
## decimal doesn't end, with whole grid points on a graph and one decimal place elsewhere, so the
## gradient and the equation are answered to 3 s.f.
##
## need: mode, rel ("para", "perp" or "any"), mid, frac (a fractional new gradient), c_nz (the new
## line misses the origin), rep, paper. The clean limits are the checker's too (LC_*).

const TRIES := 4000
const WIN := [-10, 10, -10, 10]
const LIM := 9


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var mode: String = need.get("mode", "line")
	for i in TRIES:
		var s := _draw(rng, mode, need)
		if not s.is_empty():
			s.mode = mode
			s.paper = int(need.get("paper", 1)) if mode in ["any-two", "intercepts-eq"] else 1
			return s
	push_error("LineConditionsSituation: no clean situation for %s" % need)
	return {}


static func _nonzero(rng: Seeded, lo: int, hi: int) -> int:
	var v := 0
	while v == 0:
		v = rng.int_in(lo, hi)
	return v


## Whether the decimal of q ends.
static func terminates(q: Q) -> bool:
	var d := q.d
	while d % 2 == 0:
		d /= 2
	while d % 5 == 0:
		d /= 5
	return d == 1


## y = nx + c as [a, b, d], whole with no common factor and a > 0 (or a = 0, b > 0).
static func gen(n: Q, c: Q) -> Array:
	var den := n.d * c.d / Q.gcd(n.d, c.d)
	var a := -n.n * (den / n.d)
	var b := den
	var d := -c.n * (den / c.d)
	var g := Q.gcd(Q.gcd(absi(a), absi(b)), absi(d))
	var sgn := -1 if a < 0 else 1
	return [sgn * a / g, sgn * b / g, sgn * d / g]


## "2x − 3y + 6 = 0"; "x + 2y = 0" when d is 0.
static func gen_text(a: Variant, b: Variant, d: Variant) -> String:
	return Answer.gline_text(a, b, d)


static func _draw(rng: Seeded, mode: String, need: Dictionary) -> Dictionary:
	var graph: bool = need.get("rep", "") == "graph"
	var p2: bool = int(need.get("paper", 1)) == 2 and mode in ["any-two", "intercepts-eq"]
	var s := {}
	if mode.begins_with("intercepts"):
		var p := _nonzero(rng, -8, 8)
		var q := _nonzero(rng, -8, 8)
		if p2:
			p = [7, -7, 9, -9][rng.int_in(0, 3)]
		s.ax = Q.new(p)
		s.ay = Q.new(0)
		s.bx = Q.new(0)
		s.by = Q.new(q)
		s.m = Q.new(-q, p)
		if absi(p) == absi(q) and rng.chance(0.7):
			return {}
		if not p2 and s.m.d > 5 or p2 and (s.m.d <= 5 or terminates(s.m)):
			return {}
	elif p2:
		var sc := 1 if graph else 10
		var lo := (-LIM if graph else -60)
		var hi := (LIM if graph else 60)
		s.ax = Q.new(rng.int_in(lo, hi), sc)
		s.ay = Q.new(rng.int_in(lo, hi), sc)
		s.bx = Q.new(rng.int_in(lo, hi), sc)
		s.by = Q.new(rng.int_in(lo, hi), sc)
		if s.ax.eq(s.bx) or s.ay.eq(s.by):
			return {}
		s.m = s.by.sub(s.ay).div(s.bx.sub(s.ax))
		if s.m.d <= 5 or terminates(s.m) or s.m.abs_q().to_float() < 0.1 or s.m.abs_q().to_float() > 9.0:
			return {}
		if not Answer.rounds_clearly(s.m.to_float()):
			return {}
		# A decimal point shows only on a question that isn't on the grid.
		if not graph and (s.ax.is_int() or s.ay.is_int() or s.bx.is_int() or s.by.is_int()):
			return {}
	else:
		var q: int = [1, 1, 1, 2, 2, 3, 3, 4, 5][rng.int_in(0, 8)]
		var p := _nonzero(rng, -5, 5)
		if Q.gcd(absi(p), q) != 1:
			return {}
		var k: int = 2 if need.get("mid", false) or mode in ["bisector", "midline"] else [1, 1, 2][rng.int_in(0, 2)]
		var ax := rng.int_in(-LIM, LIM)
		var ay := rng.int_in(-LIM, LIM)
		var bx := ax + k * q
		var by := ay + k * p
		if absi(bx) > LIM or absi(by) > LIM:
			return {}
		if rng.chance(0.5):
			var tx := ax
			var ty := ay
			ax = bx
			ay = by
			bx = tx
			by = ty
		s.ax = Q.new(ax)
		s.ay = Q.new(ay)
		s.bx = Q.new(bx)
		s.by = Q.new(by)
		s.m = Q.new(by - ay, bx - ax)
	s.dx = s.bx.sub(s.ax)
	s.dy = s.by.sub(s.ay)
	s.mx = s.ax.add(s.bx).div(2)
	s.my = s.ay.add(s.by).div(2)
	s.c0 = s.ay.sub(s.m.mul(s.ax))
	s.form = "gen" if not p2 and rng.chance(0.35) else "sl"
	s.gform = "gen" if not p2 and rng.chance(0.5) else "sl"
	var g0 := gen(s.m, s.c0)
	s.a0 = g0[0]
	s.b0 = g0[1]
	s.d0 = g0[2]
	if p2:
		# Only the line AB is asked.
		s.n = s.m
		s.c = s.c0
		s.rel = "para"
		s.px = s.ax
		s.py = s.ay
		if not Answer.rounds_clearly(s.c.to_float()):
			return {}
		return s
	var rel: String = need.get("rel", "any")
	if rel == "any":
		rel = "perp" if rng.chance(0.5) else "para"
	if mode == "bisector":
		rel = "perp"
	s.rel = rel
	if mode.begins_with("intercepts"):
		s.rel = "para"
		s.n = s.m
		s.px = s.ax
		s.py = s.ay
		s.c = s.c0
	elif mode == "midline":
		var origin := rng.chance(0.6)
		s.tx = Q.new(0 if origin else rng.int_in(-LIM, LIM))
		s.ty = Q.new(0 if origin else rng.int_in(-LIM, LIM))
		if s.mx.eq(s.tx) or s.my.eq(s.ty) or not s.mx.is_int() or not s.my.is_int():
			return {}
		s.n = s.my.sub(s.ty).div(s.mx.sub(s.tx))
		if s.n.d > 5:
			return {}
		s.hx = s.bx.sub(s.ax).div(2)
		s.hy = s.by.sub(s.ay).div(2)
		s.px = s.mx
		s.py = s.my
		s.c = s.py.sub(s.n.mul(s.px))
		s.rel = "para"
	else:
		s.n = s.m if rel == "para" else Q.new(-1).div(s.m)
		if mode == "bisector":
			s.px = s.mx
			s.py = s.my
		else:
			s.px = Q.new(_nonzero(rng, -LIM, LIM))
			s.py = Q.new(rng.int_in(-LIM, LIM))
		s.c = s.py.sub(s.n.mul(s.px))
		# Parallel through a point of AB would be AB itself.
		if rel == "para" and s.c.eq(s.c0):
			return {}
	if s.n.d > 5 or (need.get("frac", false) and s.n.is_int()):
		return {}
	if need.get("c_nz", false) and s.c.is_zero():
		return {}
	if s.c.abs_q().to_float() > 20.0:
		return {}
	if need.get("mid", false) and not (s.mx.is_int() and s.my.is_int()):
		return {}
	var g := gen(s.n, s.c)
	s.ga = g[0]
	s.gb = g[1]
	s.gd = g[2]
	s.xi = s.c.neg().div(s.n)
	s.area = s.c.abs_q().mul(s.xi.abs_q()).div(2)
	# The further point: whole, on the new line, not P.
	var t := _nonzero(rng, -3, 3)
	s.fx = s.px.add(t * s.n.d)
	s.fy = s.n.mul(s.fx).add(s.c)
	if not s.fy.is_int() or not s.fx.is_int() or s.fx.abs_q().to_float() > 20.0 or s.fy.abs_q().to_float() > 25.0:
		return {}
	s.hide = "y" if rng.chance(0.6) else "x"
	# check-perpendicular's second line: parallel, perpendicular, or neither (a reciprocal or
	# a sign change, which is where a student goes wrong, or another gradient).
	s.rel2 = ["para", "perp", "neither", "swap"][rng.int_in(0, 3)]
	if s.rel2 == "swap" and s.n.abs_q().eq(1):
		s.rel2 = "neither"
	s.k_b = _nonzero(rng, -4, 4)
	s.k_para = rng.chance(0.3)
	return s


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
