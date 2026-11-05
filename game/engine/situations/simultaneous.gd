class_name SimultaneousSituation
extends RefCounted
## The `fn-pre-simultaneous` situation (curriculum/question-types.json): two linear equations
## with a known solution, for the prior-learning type fn-pre-simultaneous (FAL-424). The pair
## (X, Y) comes first, then two equations through it.
##
## generate() returns, by need.form, the pair a1 x + b1 y = k1, a2 x + b2 y = k2 and X, Y:
##   "matching"  b1 = 1, b2 = ±1 (same is b2 = 1)
##   "one"       a2 = 1, a1 = t (2 or 3): one equation to scale
##   "both"      neither x coefficient divides the other: u, w scale them to L, the common one
##   "word"      as "one" with whole positive prices, ctx in CONTEXTS
##   "special"   (2) is t × (1) on the left; many: on the right too (Y, X unset), else d is the gap
##   "missing"   as "one", with on = "x" or "y" the coefficient of (1) that is hidden
## plus paper (always 1).
##
## The clean limits are the checker's too (tools/check_answers.py, SM_*).

const TRIES := 4000
const LIM := 9
const CONTEXTS := [
	["adult ticket", "adult tickets", "child ticket", "child tickets"],
	["notebook", "notebooks", "pen", "pens"],
	["coffee", "coffees", "muffin", "muffins"],
	["burger", "burgers", "drink", "drinks"],
]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var form: String = need.get("form", "matching")
	for i in TRIES:
		var s := _draw(rng, form)
		if not s.is_empty():
			s.form = form
			s.paper = 1
			return s
	push_error("SimultaneousSituation: no clean situation for %s" % need)
	return {}


static func _pair(rng: Seeded, s: Dictionary, a1: int, b1: int, a2: int, b2: int) -> Dictionary:
	var x := ExtensionViews.nonzero(rng, -6, 6)
	var y := ExtensionViews.nonzero(rng, -6, 6)
	if x == y or a1 * b2 == a2 * b1:
		return {}
	return _fill(s, x, y, a1, b1, a2, b2)


static func _fill(s: Dictionary, x: int, y: int, a1: int, b1: int, a2: int, b2: int) -> Dictionary:
	s.X = Q.new(x)
	s.Y = Q.new(y)
	s.a1 = a1
	s.b1 = b1
	s.a2 = a2
	s.b2 = b2
	s.k1 = a1 * x + b1 * y
	s.k2 = a2 * x + b2 * y
	# A right side of 0 can't show a scaling slip, and 0 is a poor pair of numbers to scale.
	return s if s.k1 != 0 and s.k2 != 0 else {}


## Coefficients of the second y term: one scaled, staying within the limit.
static func _one(rng: Seeded, s: Dictionary) -> Dictionary:
	var t: int = rng.pick([2, 3])
	var b1 := ExtensionViews.nonzero(rng, -LIM, LIM)
	var b2 := ExtensionViews.nonzero(rng, -4, 4)
	if absi(t * b2) > LIM:
		return {}
	s.t = t
	return _pair(rng, s, t, b1, 1, b2)


static func _draw(rng: Seeded, form: String) -> Dictionary:
	var s := {}
	match form:
		"matching":
			var sg: int = -1 if rng.chance(0.4) else 1
			return _pair(rng, s, rng.int_in(1, 4), 1, rng.int_in(1, 4), sg)
		"one":
			return _one(rng, s)
		"both":
			var a1 := rng.int_in(2, 7)
			var a2 := rng.int_in(2, 7)
			if a1 % a2 == 0 or a2 % a1 == 0:
				return {}
			s.L = a1 * a2 / Q.gcd(a1, a2)
			s.u = s.L / a1
			s.w = s.L / a2
			var b1: int = rng.pick([-7, -5, -4, -3, -2, 2, 3, 4, 5, 7])
			var b2: int = rng.pick([-7, -5, -4, -3, -2, 2, 3, 4, 5, 7])
			return _pair(rng, s, a1, b1, a2, b2)
		"word":
			var t := rng.int_in(2, 5)
			var b1 := rng.int_in(1, 5)
			var b2 := rng.int_in(1, 5)
			var x := rng.int_in(2, 12)
			var y := rng.int_in(2, 12)
			if x == y or t * b2 == b1:
				return {}
			s.t = t
			s.ctx = rng.int_in(0, CONTEXTS.size() - 1)
			return _fill(s, x, y, t, b1, 1, b2)
		"special":
			var a := rng.int_in(1, 4)
			var b := ExtensionViews.nonzero(rng, -4, 4)
			var k := ExtensionViews.nonzero(rng, -9, 9)
			var t: int = rng.pick([2, 3])
			s.many = rng.chance(0.5)
			s.a1 = a
			s.b1 = b
			s.k1 = k
			s.t = t
			s.a2 = t * a
			s.b2 = t * b
			s.d = 0 if s.many else ExtensionViews.nonzero(rng, -5, 5)
			s.k2 = t * k + s.d
			return s
		"missing":
			var made := _one(rng, s)
			if not made.is_empty():
				made.on = rng.pick(["x", "y"])
			return made
	return {}


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
