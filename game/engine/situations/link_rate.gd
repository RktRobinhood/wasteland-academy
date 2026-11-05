class_name LinkRateSituation
extends RefCounted
## The `fn-link-rate-of-change` situation (curriculum/question-types.json): one rate m in four
## forms, for the link type fn-link-rate-of-change (FAL-424). The rate and the start come first,
## then the sequence, the line, the regression line or the curve.
##
## generate() returns, by need.kind (plus kind and paper):
##   "seq"     m, u1, c (= u1 − m); p < q two positions with up, uq (u_p and u_q)
##   "kinds"   as "seq", with m > 0, b the regression line's intercept and a the instant
##   "reg"     ctx in REG, a (the gradient), b
##   "deriv"   ctx in DERIV, at (the time), k (the rate there)
##   "curve"   x0, and the curve: quadratic y = kx² (A = 2kx0, B = k), or on Paper 2 the cubic
##             y = px³ + qx (A = 3px0² + q, B = 3px0, C = p). The chord from x0 to x0 + h
##             has gradient A + Bh + Ch² and the tangent has gradient A
##   "const"   m, x0, y0, c (= y0 − m·x0)
##
## Paper 2 is the GDC's dy/dx (need.angle gdc-dydx), on a cubic with decimals, its gradient
## to 3 s.f.; everything else is Paper 1. The clean limits are the checker's too (LR_*).

const TRIES := 4000
## The regression stories. each: a step of x; up, down: y's change; total, exact: the two slips.
const REG := [
	{"x": "the distance driven", "xu": "km", "y": "the fuel used", "yu": "litres", "n": "trips", "as": [6, 7, 8, 9], "den": 100, "bs": [12, 15, 24],
		"each": "km", "up": "litres more fuel", "total": "The total fuel used is %v litres", "exact": "Each extra km adds exactly %v litres of fuel, every time"},
	{"x": "the time spent revising", "xu": "hours", "y": "the test score", "yu": "marks", "n": "students", "as": [35, 42, 55, 60], "den": 10, "bs": [320, 410, 480],
		"each": "hour of revising", "up": "marks more", "total": "The total score is %v marks", "exact": "Each extra hour of revising adds exactly %v marks, every time"},
	{"x": "the temperature", "xu": "°C", "y": "sales", "yu": "drinks a day", "n": "days", "as": [25, 32, 45], "den": 10, "bs": [120, 150, 200],
		"each": "degree", "up": "more iced drinks", "total": "The total sold is %v iced drinks", "exact": "Each extra degree sells exactly %v more iced drinks, every time"},
	{"x": "the age of a car", "xu": "years", "y": "its value", "yu": "thousand dollars", "n": "cars", "as": [-12, -18, -25], "den": 10, "bs": [180, 220, 250],
		"each": "year of age", "up": "thousand dollars less value", "total": "The car is worth %v thousand dollars in all", "exact": "Each extra year takes exactly %v thousand dollars off, every time"},
]
## The derivative stories: the letter, the quantity, its unit, the rate's unit, the time's unit.
const DERIV := [
	{"f": "V", "of": "the volume of water", "in": "the volume of water in a tank", "u": "litres", "per": "litres per minute", "t": "minutes", "after": "a valve opens"},
	{"f": "h", "of": "the height of the ball", "in": "the height of a ball", "u": "metres", "per": "metres per second", "t": "seconds", "after": "it is thrown"},
	{"f": "T", "of": "the temperature of the coffee", "in": "the temperature of a cup of coffee", "u": "°C", "per": "°C per minute", "t": "minutes", "after": "it is poured"},
	{"f": "A", "of": "the area of the oil slick", "in": "the area of an oil slick", "u": "cm²", "per": "cm² per second", "t": "seconds", "after": "it starts to spread"},
]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var kind: String = need.get("kind", "seq")
	var p2: bool = need.get("angle", "") == "gdc-dydx"
	for i in TRIES:
		var s := _draw(rng, kind, p2)
		if not s.is_empty():
			s.kind = kind
			s.paper = 2 if p2 else 1
			return s
	push_error("LinkRateSituation: no clean situation for %s" % need)
	return {}


static func _seq(rng: Seeded, s: Dictionary, up: bool) -> Dictionary:
	s.m = rng.int_in(2, 6) if up else ExtensionViews.nonzero(rng, -6, 6)
	s.u1 = ExtensionViews.nonzero(rng, -5, 12)
	s.c = s.u1 - s.m
	if s.c == 0:
		return {}
	s.p = rng.int_in(2, 6)
	s.q = s.p + rng.int_in(2, 8)
	s.up = s.u1 + (s.p - 1) * s.m
	s.uq = s.u1 + (s.q - 1) * s.m
	return s


static func hard(v: Q) -> bool:
	return Answer.needs_rounding(v) and Answer.rounds_clearly(v.to_float()) and absf(v.to_float()) > 0.2


static func _draw(rng: Seeded, kind: String, p2: bool) -> Dictionary:
	var s := {}
	match kind:
		"seq":
			return _seq(rng, s, false)
		"kinds":
			if _seq(rng, s, true).is_empty():
				return {}
			s.b = Q.new(rng.int_in(11, 95), 10)
			s.a = rng.int_in(2, 9)
			return s
		"reg":
			s.ctx = rng.int_in(0, REG.size() - 1)
			var r: Dictionary = REG[s.ctx]
			s.a = Q.new(r.as[rng.int_in(0, r.as.size() - 1)], r.den)
			s.b = Q.new(r.bs[rng.int_in(0, r.bs.size() - 1)], 10)
			return s
		"deriv":
			s.ctx = rng.int_in(0, DERIV.size() - 1)
			s.at = rng.int_in(2, 9)
			s.k = rng.int_in(2, 9) * (-1 if rng.chance(0.7) else 1)
			return s
		"curve":
			if p2:
				var p := Q.new(rng.int_in(2, 9), 10)
				var q := Q.new(ExtensionViews.nonzero(rng, -39, 39), 10)
				var x0 := Q.new(rng.int_in(11, 29), 10)
				if x0.is_int() or q.is_int():
					return {}
				s.p = p
				s.q = q
				s.x0 = x0
				s.A = p.mul(3).mul(x0).mul(x0).add(q)
				s.B = p.mul(3).mul(x0)
				s.C = p
				s.cubic = true
				return s if hard(s.A) else {}
			s.k = rng.int_in(1, 3)
			s.x0 = Q.new(ExtensionViews.nonzero(rng, -3, 3))
			s.A = s.x0.mul(2 * s.k)
			s.B = Q.new(s.k)
			s.C = Q.new(0)
			s.cubic = false
			return s
		"const":
			s.m = ExtensionViews.nonzero(rng, -9, 9)
			s.x0 = ExtensionViews.nonzero(rng, -6, 6)
			s.y0 = ExtensionViews.nonzero(rng, -20, 20)
			s.c = s.y0 - s.m * s.x0
			if s.c == 0 or absi(s.m) == 1 or s.c == s.y0:
				return {}
			return s
	return {}


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
