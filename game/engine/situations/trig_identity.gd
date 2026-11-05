class_name TrigIdentitySituation
extends RefCounted
## The `trig-identity` situation (curriculum/question-types.json): one angle θ fixed by a ratio and
## a quadrant, or one expression to rewrite with an identity, for t3-identity-values (FAL-727).
## Every question is Paper 1, as every bank part is.
##
## need.ask is the unknown (see TrigIdentityViews). generate() returns a Dictionary:
##   paper, ask, rep
##   fn, top, n, q     the given ratio is ±√top/n, fn of θ, and θ is in quadrant q
##   rise, run         the given tan θ is ±rise/run (cos-from-tan)
##   b, c, a           the sides of a triangle with the angle 2θ between b and c (cos-from-cos2)
##   src, base, p, m, k the expression: p·src + m·(sin x or cos x) + k (rewrite-in-sin)
##   k, w              the size and the inner multiple: k cos 2wx, or k sin 2wx (single-cos and on)
##   minus, d          the sign in (sin x ± cos x)², and a number added

const TRIES := 400
## √top/n: rationals, then surds. n² − top is positive.
const GIVEN := [[9, 5], [16, 5], [25, 13], [144, 13], [64, 17], [225, 17], [1, 3], [4, 3], [1, 4], [9, 4], [4, 5], [1, 5], [4, 7], [9, 7],
	[5, 3], [7, 4], [3, 4], [2, 3], [5, 6], [7, 5]]
const COS2 := [[1, 3], [1, 5], [3, 5], [7, 25], [1, 9], [5, 9], [7, 9], [1, 4], [1, 2], [7, 8], [2, 3]]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "cos-from-sin")
	var s := {"paper": 1, "ask": ask, "rep": need.get("rep", "equation")}
	for i in TRIES:
		if new().call("_" + ask.replace("-", "_"), rng, s):
			return s
	return {}


static func _ratio(rng: Seeded, s: Dictionary, fn: String) -> bool:
	var g: Array = rng.pick(GIVEN)
	s.top = g[0]
	s.n = g[1]
	s.q = rng.int_in(1, 4)
	s.fn = fn
	return true


static func _cos_from_sin(rng: Seeded, s: Dictionary) -> bool:
	return _ratio(rng, s, "sin")


static func _sin_from_cos(rng: Seeded, s: Dictionary) -> bool:
	return _ratio(rng, s, "cos")


static func _tan_from_ratio(rng: Seeded, s: Dictionary) -> bool:
	return _ratio(rng, s, rng.pick(["sin", "cos"]))


static func _cos_from_tan(rng: Seeded, s: Dictionary) -> bool:
	s.rise = rng.int_in(1, 9)
	s.run = rng.int_in(1, 9)
	s.q = rng.int_in(1, 4)
	return s.rise != s.run and Q.gcd(s.rise, s.run) == 1


static func _sin2_from_ratio(rng: Seeded, s: Dictionary) -> bool:
	return _ratio(rng, s, rng.pick(["sin", "cos"]))


static func _cos2_from_sin(rng: Seeded, s: Dictionary) -> bool:
	return _ratio(rng, s, "sin")


static func _cos2_from_cos(rng: Seeded, s: Dictionary) -> bool:
	return _ratio(rng, s, "cos")


## cos 2θ, with θ acute: a fraction, or the sides of a triangle whose cosine rule gives it.
static func _cos_from_cos2(rng: Seeded, s: Dictionary) -> bool:
	if s.rep == "equation":
		var c: Array = rng.pick(COS2)
		s.cos2 = Q.new(c[0], c[1]) if rng.chance(0.7) else Q.new(-c[0], c[1])
		return true
	s.b = rng.int_in(3, 10)
	s.c = rng.int_in(3, 10)
	s.a = rng.int_in(2, 14)
	if not (s.a < s.b + s.c and s.b < s.a + s.c and s.c < s.a + s.b):
		return false
	s.cos2 = Q.new(s.b * s.b + s.c * s.c - s.a * s.a, 2 * s.b * s.c)
	return not s.cos2.is_zero()


static func _rewrite_in_sin(rng: Seeded, s: Dictionary) -> bool:
	s.base = rng.pick(["sin", "cos"])
	s.src = rng.pick(["sq", "double"])
	s.p = rng.int_in(2, 6)
	s.m = ExtensionViews.nonzero(rng, -5, 5)
	s.k = rng.int_in(-5, 5)
	return true


static func _single_cos(rng: Seeded, s: Dictionary) -> bool:
	s.k = rng.int_in(2, 9)
	s.w = rng.int_in(1, 3)
	s.from = rng.pick(["sin", "cos"])
	return true


static func _product_sine(rng: Seeded, s: Dictionary) -> bool:
	s.k = rng.int_in(1, 7)
	s.w = rng.int_in(1, 3)
	return true


static func _expand_square(rng: Seeded, s: Dictionary) -> bool:
	s.k = rng.int_in(1, 5)
	s.minus = rng.chance(0.5)
	return true


static func _max_after_rewrite(rng: Seeded, s: Dictionary) -> bool:
	s.k = rng.int_in(1, 7)
	s.w = rng.int_in(1, 3)
	s.d = rng.int_in(-5, 9)
	return true


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
