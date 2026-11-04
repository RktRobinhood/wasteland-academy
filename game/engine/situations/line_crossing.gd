class_name LineCrossingSituation
extends RefCounted
## The `line-crossing` situation (curriculum/question-types.json): two lines and where they
## meet, for fn-ext-intersection-lines (FAL-424). The meeting point comes first, then two lines
## through it, so the answer is clean; a Paper 2 pair (GDC intersect only) has decimal
## coefficients or an awkward determinant, and a meeting point to 3 s.f.
##
## generate() returns, by need:
##   X, Y                   the meeting point
##   m1, c1, m2, c2         the lines as y = mx + c (need.form "sl")
##   a1, b1, k1, b2, k2     the lines as a₁x + b₁y = k₁ and x + b₂y = k₂ (need.form "gen")
##   n, tx, ty, by_point    a third line through (X, Y): gradient n, through T when by_point
##   px, py, on             a point to test; on is "both", "one", "two" or "none"
##   rel                    mode "mix": "one" (they meet), "para" (never) or "same" (one line),
##                          with L₂ as a2x + b2y = k2 (a2 > 0) and through (qx, qy), (rx, ry)
##   paper                  2 only for the GDC intersect method
##
## The clean limits are the checker's too (tools/check_answers.py, LX_*).

const TRIES := 4000
const LIM := 6
const WIN := [-10, 10, -10, 10]
const GRADIENTS := [[1, 1], [2, 1], [3, 1], [-1, 1], [-2, 1], [-3, 1], [1, 2], [-1, 2], [3, 2], [-3, 2], [4, 1], [-4, 1]]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var p2: bool = need.get("angle", "") == "gdc-intersect"
	for i in TRIES:
		var s := _draw(rng, need, p2)
		if not s.is_empty():
			s.paper = 2 if p2 else 1
			s.mode = need.get("mode", "one")
			return s
	push_error("LineCrossingSituation: no clean situation for %s" % need)
	return {}


static func _gradient(rng: Seeded) -> Q:
	var g: Array = GRADIENTS[rng.int_in(0, GRADIENTS.size() - 1)]
	return Q.new(g[0], g[1])


## Whether a Paper 2 value needs a calculator and rounds cleanly.
static func hard(v: Q) -> bool:
	return Answer.needs_rounding(v) and Answer.rounds_clearly(v.to_float()) and v.abs_q().to_float() < 8.0 and v.abs_q().to_float() > 0.2


static func _draw(rng: Seeded, need: Dictionary, p2: bool) -> Dictionary:
	var s := {}
	var form: String = need.get("form", "sl")
	if need.get("mode", "one") == "mix":
		return _mix(rng, s)
	if p2:
		if form == "sl":
			s.m1 = Q.new(ExtensionViews.nonzero(rng, -25, 25), 10)
			s.m2 = Q.new(ExtensionViews.nonzero(rng, -25, 25), 10)
			s.c1 = Q.new(rng.int_in(-50, 50), 10)
			s.c2 = Q.new(rng.int_in(-50, 50), 10)
			if s.m1.eq(s.m2) or s.m1.is_int() or s.m2.is_int() or s.c1.is_int() or s.c2.is_int():
				return {}
			s.X = s.c2.sub(s.c1).div(s.m1.sub(s.m2))
			s.Y = s.m1.mul(s.X).add(s.c1)
		else:
			_general(rng, s)
			s.k1 = ExtensionViews.nonzero(rng, -30, 30)
			s.k2 = ExtensionViews.nonzero(rng, -12, 12)
			var det: int = s.a1 * s.b2 - s.b1
			if det == 0:
				return {}
			s.Y = Q.new(s.a1 * s.k2 - s.k1, det)
			s.X = Q.new(s.k2).sub(s.Y.mul(s.b2))
		return s if hard(s.X) and hard(s.Y) else {}
	s.X = Q.new(ExtensionViews.nonzero(rng, -LIM, LIM))
	s.Y = Q.new(ExtensionViews.nonzero(rng, -LIM, LIM))
	if s.X.eq(s.Y):
		return {}
	s.m1 = _gradient(rng)
	s.m2 = _gradient(rng)
	s.c1 = s.Y.sub(s.m1.mul(s.X))
	s.c2 = s.Y.sub(s.m2.mul(s.X))
	if s.m1.eq(s.m2) or not s.c1.is_int() or not s.c2.is_int() or s.c1.abs_q().to_float() > 15.0 or s.c2.abs_q().to_float() > 15.0:
		return {}
	_general(rng, s)
	s.k1 = s.X.mul(s.a1).add(s.Y.mul(s.b1)).n
	s.k2 = s.X.add(s.Y.mul(s.b2)).n
	if s.a1 * s.b2 - s.b1 == 0 or Q.gcd(Q.gcd(absi(s.a1), absi(s.b1)), absi(s.k1)) != 1:
		return {}
	# A third line through the meeting point: a gradient, or a second point.
	s.by_point = rng.chance(0.5)
	s.n = _gradient(rng)
	s.tx = s.X.add(s.n.d * ExtensionViews.nonzero(rng, -2, 2))
	s.ty = s.n.mul(s.tx.sub(s.X)).add(s.Y)
	s.c3 = s.Y.sub(s.n.mul(s.X))
	# A point to test.
	var d: int = 2 * ExtensionViews.nonzero(rng, -2, 2)
	s.on = ["both", "one", "two", "none"][rng.int_in(0, 3)]
	match s.on:
		"both":
			s.px = s.X
			s.py = s.Y
		"one":
			s.px = s.X.add(d)
			s.py = s.m1.mul(s.px).add(s.c1)
		"two":
			s.px = s.X.add(d)
			s.py = s.m2.mul(s.px).add(s.c2)
		_:
			s.px = s.X.add(1)
			s.py = s.Y.add(1)
			if s.m1.eq(1) or s.m2.eq(1):
				s.py = s.Y.sub(1)
			if s.m1.eq(-1) or s.m2.eq(-1):
				return {}
	return s


## a₁x + b₁y with a₁ from 2 to 6, and x + b₂y, so substitution stays whole.
static func _general(rng: Seeded, s: Dictionary) -> void:
	s.a1 = rng.int_in(2, 6)
	s.b1 = ExtensionViews.nonzero(rng, -6, 6)
	s.b2 = ExtensionViews.nonzero(rng, -5, 5)


static func _mix(rng: Seeded, s: Dictionary) -> Dictionary:
	s.rel = ["one", "para", "para", "same"][rng.int_in(0, 3)]
	s.m1 = _gradient(rng)
	s.c1 = Q.new(ExtensionViews.nonzero(rng, -9, 9))
	s.m2 = s.m1
	s.c2 = s.c1
	if s.rel == "para":
		s.c2 = Q.new(ExtensionViews.nonzero(rng, -9, 9))
		if s.c2.eq(s.c1):
			return {}
	elif s.rel == "one":
		s.m2 = _gradient(rng)
		s.c2 = Q.new(ExtensionViews.nonzero(rng, -9, 9))
		if s.m2.eq(s.m1):
			return {}
		s.X = s.c2.sub(s.c1).div(s.m1.sub(s.m2))
		s.Y = s.m1.mul(s.X).add(s.c1)
	# L₂ as a whole-number line with a > 0, scaled so it doesn't look like L₁.
	var t := rng.int_in(1, 3)
	var sg := -1 if s.m2.n > 0 else 1
	s.a2 = sg * -s.m2.n * t
	s.b2 = sg * s.m2.d * t
	s.k2 = s.c2.mul(sg * s.m2.d * t).n
	# And as two points.
	var step: int = s.m2.d
	s.qx = Q.new(step * rng.int_in(-2, 1))
	s.qy = s.m2.mul(s.qx).add(s.c2)
	s.rx = s.qx.add(step * rng.int_in(1, 2))
	s.ry = s.m2.mul(s.rx).add(s.c2)
	return s


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
