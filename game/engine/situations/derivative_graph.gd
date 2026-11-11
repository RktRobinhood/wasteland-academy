class_name DerivativeGraphSituation
extends RefCounted
## The `derivative-graph` situation (curriculum/question-types.json): a function read from
## the graph of its derivative, or the sign of f′ read from the graph of f (SL5.7, SL5.2,
## FAL-754). Every curve is built from whole-number roots, so each feature the question
## is about (a sign change, a touch, a turning point of f′, an end of a region) sits on a
## grid line. The SymPy checker (tools/check_answers.py) reads the curve back from the
## figure and works every feature out again.
##
## need.ask is the unknown. generate() returns a Dictionary with ask and paper (always 1), and
## by family:
##   touch  g(x) = k(x − a)(x − b)², with |b − a| = 3: g crosses the axis at a and touches it
##          at b; c = (2a + b)/3 is its other turning point. lo and hi are the ends drawn,
##          one past the roots. role says what g is: "fp" (f′), "fpp" (f″) or "f" (f itself,
##          shifted up by v for a turning point's gradient)
##   quad   g(x) = k(x − a)(x − b), a < b with b − a even, so the vertex h is whole
##   area   g(x) = k(x − a)(x − b) on [lo, hi]: two regions, [lo, m] and [m, hi], one on each
##          side of the axis, whose areas A1 and A2 are whole and differ. v is f(lo)

const TRIES := 400


static func touch(rng: Seeded, role: String = "fp") -> Dictionary:
	var left := rng.int_in(-3, 0)
	var s := {"fam": "touch", "role": role, "k": rng.pick([1, -1, 2, -2] if role != "f" else [1, -1]), "v": 0}
	if rng.chance(0.5):
		s.a = left
		s.b = left + 3
	else:
		s.a = left + 3
		s.b = left
	s.c = (2 * s.a + s.b) / 3
	s.lo = left - 1
	s.hi = left + 4
	return s


static func quad(rng: Seeded) -> Dictionary:
	var s := {"fam": "quad", "role": "fp", "k": rng.pick([1, -1, 2, -2]), "a": rng.int_in(-4, 0)}
	s.b = s.a + rng.pick([2, 4])
	s.h = (s.a + s.b) / 2
	s.lo = s.a - 1
	s.hi = s.b + 1
	return s


## Two regions with whole, different areas. Right side: [a, b] and [b, b + e];
## left side: [a − e, a] and [a, b].
static func area(rng: Seeded) -> Dictionary:
	for i in TRIES:
		var k: int = rng.pick([2, 3, 6])
		var d := rng.int_in(1, 4)
		var e := rng.int_in(1, 3)
		var inner := k * d * d * d
		var outer := k * (2 * e * e * e + 3 * d * e * e)
		if inner % 6 != 0 or outer % 6 != 0:
			continue
		var a1 := inner / 6
		var a2 := outer / 6
		var top := k * e * (d + e)
		if a1 == a2 or mini(a1, a2) < 4 or maxi(a1, a2) > 60 or top > 60 or k * d * d < 8 or maxi(a1, a2) > 8 * mini(a1, a2):
			continue
		var s := {"fam": "area", "role": "fp", "k": k * rng.pick([1, -1]), "a": rng.int_in(-3, 0), "side": rng.pick(["right", "left"])}
		s.b = s.a + d
		if s.side == "right":
			s.lo = s.a
			s.m = s.b
			s.hi = s.b + e
			s.A1 = a1
			s.A2 = a2
		else:
			s.lo = s.a - e
			s.m = s.a
			s.hi = s.b
			s.A1 = a2
			s.A2 = a1
		# The sign of g on each region: g has the sign of k outside its roots.
		s.s1 = signi(s.k) if s.side == "left" else -signi(s.k)
		s.s2 = -s.s1
		s.v = ExtensionViews.nonzero(rng, -9, 9)
		s.target = rng.pick(["hi", "m"])
		return s
	return {}


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "extremum-from-derivative")
	var s: Dictionary
	match ask:
		"extremum-from-derivative", "extremum-justified", "inflexion-from-derivative":
			s = touch(rng) if rng.chance(0.5) else quad(rng)
			s.want = rng.pick(["maximum", "minimum"])
		"touch-not-turning", "increasing-past-touch", "concave-up-from-cubic", "pick-f-from-derivative":
			s = touch(rng)
			s.want = rng.pick(["up", "down"])
		"inflexion-from-second":
			s = touch(rng, "fpp")
		"compare-from-areas", "value-from-areas":
			s = area(rng)
		"gradient-sign-statement", "gradient-negative-where":
			s = touch(rng, "f")
			s.want = rng.pick(["< 0", "> 0"])
			# A point where the sign of f′ is easy to mistake: the crossing, the turning
			# point off the axis, or a point where f and f′ have opposite signs.
			# With b right of a, f and f′ disagree between c and b; with b left of a, just left of b.
			s.x0 = rng.pick([s.a, s.c, s.c + 1 if s.b > s.a else s.b - 1])
		"gradient-at-turning-point":
			s = touch(rng, "f")
			s.v = rng.int_in(-3, 3)
			while s.v == -at(s, s.c) or s.c == at(s, s.c) + s.v:
				s.v += 1
	if s.is_empty():
		return {}
	s.ask = ask
	s.paper = 1
	return s


## g at a whole number x (the family's curve, without v).
static func at(s: Dictionary, x: int) -> int:
	if s.fam == "touch":
		return s.k * (x - s.a) * (x - s.b) * (x - s.b)
	return s.k * (x - s.a) * (x - s.b)


static func fn(s: Dictionary) -> Callable:
	var k := float(s.k)
	var a := float(s.a)
	var b := float(s.b)
	var v := float(s.get("v", 0)) if s.fam == "touch" else 0.0
	if s.fam == "touch":
		return func(x: float) -> float: return k * (x - a) * (x - b) * (x - b) + v
	return func(x: float) -> float: return k * (x - a) * (x - b)


## The gradient of g at a whole number x: 3k(x − b)(x − c) for a touch, k(2x − a − b) for a parabola.
static func slope(s: Dictionary, x: int) -> int:
	if s.fam == "touch":
		return 3 * s.k * (x - s.b) * (x - s.c)
	return s.k * (2 * x - s.a - s.b)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
