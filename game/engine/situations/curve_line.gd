class_name CurveLineSituation
extends RefCounted
## The `curve-and-line` situation (curriculum/question-types.json): a curve and a line
## that meet (FAL-414). The meeting x-values are picked first and the curve is built as
## the line plus a multiple of (x − x₁)(x − x₂), so the equated quadratic is known in
## advance:
##   y = mx + n + a(x − x₁)(x − x₂)  =  Ax² + Bx + C
##
## generate() returns Q values:
##   mode      "int" (whole-number meeting x), "surd" (h ± √d), "tangent" (one point),
##             "none" (no meeting point) or "normal" (the line is the normal at P)
##   a, m, n   the stretch, and the line y = mx + n
##   A, B, C   the curve y = Ax² + Bx + C
##   x1, x2, y1, y2   the meeting points, x1 < x2 (int and normal modes); in normal
##             mode P is (px, py) and the other point Q is (qx, qy)
##   h, d      the midpoint and the surd: x = h ± √d (surd mode; tangent and none use h)
##
## need: mode ("int" by default, or "count" for two, tangent or none), m_not_zero.

const A_CHOICES := [1, -1, 2, -2]
const X_MAX := 5
const N_MAX := 6
const COEF_MAX := 24
const SURDS := [2, 3, 5, 6, 7]
const TRIES := 4000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var mode: String = need.get("mode", "int")
	for i in TRIES:
		var md := mode
		if md == "count":
			md = ["int", "int", "tangent", "none"][rng.int_in(0, 3)]
		var s := _draw(rng, md)
		if not s.is_empty() and _clean(s):
			return s
	push_error("CurveLineSituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, mode: String) -> Dictionary:
	var a := Q.new(A_CHOICES[rng.int_in(0, A_CHOICES.size() - 1)])
	var m := Q.new(rng.int_in(-3, 3))
	var n := Q.new(rng.int_in(-N_MAX, N_MAX))
	if m.is_zero():
		return {}
	var s := {"mode": mode, "a": a, "m": m, "n": n, "x1": null, "x2": null, "y1": null, "y2": null, "h": null, "d": null,
		"px": null, "py": null, "qx": null, "qy": null}
	# The curve minus the line, a·x² + e·x + g, then the curve is that plus the line.
	var e := Q.new(0)
	var g := Q.new(0)
	match mode:
		"int", "normal":
			var x1 := rng.int_in(-X_MAX, X_MAX)
			var x2 := rng.int_in(-X_MAX, X_MAX)
			if mode == "normal":
				# The normal at P has gradient m = ±1: the curve's gradient there is −1/m.
				m = Q.new([1, -1][rng.int_in(0, 1)])
				s.m = m
				var gap := Q.new(1).div(m).add(m).div(a)   # x2 − x1 so that m(m + a(x1 − x2)) = −1
				x2 = x1 + gap.n
				if absi(x2) > X_MAX + 2:
					return {}
			if x1 == x2:
				return {}
			var p := mini(x1, x2)
			var q := maxi(x1, x2)
			if mode == "normal":
				s.px = Q.new(x1)
				s.qx = Q.new(x2)
			s.x1 = Q.new(p)
			s.x2 = Q.new(q)
			e = a.mul(-(p + q))
			g = a.mul(p * q)
		"surd":
			var h := rng.int_in(-4, 4)
			var d: int = SURDS[rng.int_in(0, SURDS.size() - 1)]
			s.h = Q.new(h)
			s.d = Q.new(d)
			e = a.mul(-2 * h)
			g = a.mul(h * h - d)
		"tangent":
			var h := rng.int_in(-4, 4)
			s.h = Q.new(h)
			s.x1 = Q.new(h)
			s.x2 = Q.new(h)
			e = a.mul(-2 * h)
			g = a.mul(h * h)
		"none":
			var h := rng.int_in(-4, 4)
			s.h = Q.new(h)
			e = a.mul(-2 * h)
			g = a.mul(h * h + rng.int_in(1, 4))
	s.A = a
	s.B = e.add(m)
	s.C = g.add(n)
	if s.x1 != null:
		s.y1 = m.mul(s.x1).add(n)
		s.y2 = m.mul(s.x2).add(n)
	if s.px != null:
		s.py = m.mul(s.px).add(n)
		s.qy = m.mul(s.qx).add(n)
	return s


static func _clean(s: Dictionary) -> bool:
	if absi(s.B.n) > COEF_MAX or absi(s.C.n) > COEF_MAX:
		return false
	# The curve's own roots and vertex don't matter, but its y-intercept is not the line's
	# (so the two graphs are told apart at x = 0).
	return not s.C.eq(s.n)


## y on the curve.
static func curve_at(s: Dictionary, x: Variant) -> Q:
	var xq := Q.of(x)
	return s.A.mul(xq.sq()).add(s.B.mul(xq)).add(s.C)


static func export(s: Dictionary) -> Dictionary:
	return QuadraticSituation.export(s)
