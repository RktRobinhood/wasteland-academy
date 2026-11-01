class_name QuadraticEquationSituation
extends RefCounted
## The `quadratic-equation` situation (curriculum/question-types.json), which extends
## `quadratic`: the quadratic set equal to zero, plain or wrapped in a context or a
## substitution that makes exactly one root unusable (FAL-414).
##
## The plain, surd and from-roots wrappers call QuadraticSituation.generate() and keep
## its parabola. The others pick their roots first and build the equation from them:
##   noconst   ax² + bx = 0 (or ax² = −bx): roots 0 and −b/a
##   context   a rectangle x by (x + d) with area A, or a right-angled triangle with
##             sides x, x + d and hypotenuse x + e. Paper 2 (when the method isn't
##             factorising): the area is not a product of whole numbers, so x needs the
##             formula and 3 s.f.
##   exp       b^(2x) + B·b^x + C = 0 with u-roots bⁿ and −bʲ (j ≥ 1): x = n. Paper 2:
##             the good u-root is not a power of b, so x = ln u/ln b to 3 s.f.
##   recip     x + c/x = t: roots r₁, r₂
##   log       ln x + ln(x + d) = ln c: roots r > 0 and −d − r, which makes ln x
##             undefined. Paper 2: c is not r(r + d), so x needs the formula and 3 s.f.
##   coef      x² + kx + c = 0 with one root given: k and the other root
##
## need.paper (1 or 2, from QuestionEngine) picks the paper for context, exp and log;
## without it a context is Paper 2 one time in four (never for factorising), and exp
## and log are Paper 1. Paper 1 numbers are drawn exactly as they were before.
##
## generate() returns the parabola's quantities (for plain, surd and fromroots) or:
##   wrapper, r1, r2 (Q roots, r1 the valid one where one is rejected), and the wrapper's
##   own numbers (d, e, area, base, n, j, t, c, paper, and on Paper 2 x, the root to
##   nine decimal places, and xneg, the rejected one)

const TRIPLES := [[3, 4, 5], [5, 12, 13], [6, 8, 10], [8, 15, 17], [9, 12, 15], [20, 21, 29], [7, 24, 25]]
const SCALE := 1000000000
const TRIES := 2000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var w: String = need.get("wrapper", "plain")
	for i in TRIES:
		var s := _draw(rng, w, need)
		if not s.is_empty():
			s.wrapper = w
			return s
	push_error("QuadraticEquationSituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, w: String, need: Dictionary) -> Dictionary:
	match w:
		"plain":
			return QuadraticSituation.generate(rng, {"mode": "rational", "graph": need.get("graph", false)})
		"surd":
			return QuadraticSituation.generate(rng, {"mode": "surd"})
		"fromroots":
			return QuadraticSituation.generate(rng, {"mode": ["rational", "surd", "surd"][rng.int_in(0, 2)]})
		"noconst":
			var a: int = [1, 2, 3, -1, -2][rng.int_in(0, 4)]
			var b := rng.int_in(-12, 12)
			if b == 0 or (b % a != 0 and rng.chance(0.7)):
				return {}
			return {"a": Q.new(a), "b": Q.new(b), "r1": Q.new(0), "r2": Q.new(-b, a), "form": ["zero", "moved"][rng.int_in(0, 1)]}
		"context":
			# The old draw is kept when the paper is given, so Paper 1 numbers don't move.
			var drawn: bool = need.get("angle", "") != "factorise" and rng.chance(0.25)
			var paper2: bool = int(need.paper) == 2 if need.has("paper") else drawn
			if rng.chance(0.5) and not paper2:
				var t: Array = TRIPLES[rng.int_in(0, TRIPLES.size() - 1)]
				var x: int = t[0]
				var d: int = t[1] - x
				var e: int = t[2] - x
				# x² + (x + d)² = (x + e)²  →  x² + (2d − 2e)x + d² − e² = 0
				var B := 2 * d - 2 * e
				var C := d * d - e * e
				return {"kind": "pyth", "d": Q.new(d), "e": Q.new(e), "B": Q.new(B), "C": Q.new(C), "r1": Q.new(x),
					"r2": Q.new(-B - x), "paper": 1}
			var d := rng.int_in(1, 9)
			if paper2:
				var area := rng.int_in(12, 90)
				var disc := d * d + 4 * area
				var root := int(round(sqrt(float(disc))))
				var x := (-d + sqrt(float(disc))) / 2.0
				if root * root == disc or not Answer.rounds_clearly(x, 0.05):
					return {}
				return {"kind": "rect", "d": Q.new(d), "area": Q.new(area), "B": Q.new(d), "C": Q.new(-area), "paper": 2,
					"x": Q.new(int(round(x * SCALE)), SCALE), "xneg": -d - x, "r1": null, "r2": null}
			var r := rng.int_in(2, 12)
			return {"kind": "rect", "d": Q.new(d), "area": Q.new(r * (r + d)), "B": Q.new(d), "C": Q.new(-r * (r + d)),
				"r1": Q.new(r), "r2": Q.new(-r - d), "paper": 1}
		"exp":
			if int(need.get("paper", 1)) == 2:
				return _exp_p2(rng)
			var base: int = [2, 2, 3][rng.int_in(0, 2)]
			var n := rng.int_in(0, 3 if base == 2 else 2)
			var j := rng.int_in(1, 3 if base == 2 else 2)
			var u1 := int(pow(base, n))
			var u2 := -int(pow(base, j))
			if u1 + u2 == 0:
				return {}
			return {"base": Q.new(base), "n": Q.new(n), "j": Q.new(j), "u1": Q.new(u1), "u2": Q.new(u2),
				"B": Q.new(-(u1 + u2)), "C": Q.new(u1 * u2), "r1": Q.new(n), "r2": null}
		"recip":
			var r1 := rng.int_in(-7, 7)
			var r2 := rng.int_in(-7, 7)
			if r1 == 0 or r2 == 0 or r1 == r2 or r1 + r2 == 0:
				return {}
			return {"t": Q.new(r1 + r2), "c": Q.new(r1 * r2), "r1": Q.new(mini(r1, r2)), "r2": Q.new(maxi(r1, r2))}
		"log":
			if int(need.get("paper", 1)) == 2:
				return _log_p2(rng)
			var r := rng.int_in(1, 8)
			var d := rng.int_in(-r + 1, 6)
			if d == 0:
				return {}
			return {"d": Q.new(d), "c": Q.new(r * (r + d)), "r1": Q.new(r), "r2": Q.new(-d - r)}
		"coef":
			var r := rng.int_in(-6, 6)
			var t := rng.int_in(-6, 6)
			if r == 0 or t == 0 or r == t or absi(r * t) > 24:
				return {}
			return {"c": Q.new(r * t), "k": Q.new(-(r + t)), "r1": Q.new(r), "r2": Q.new(t)}
	return {}


## A float as a Q to nine decimal places (a calculator's root, kept for marking).
static func approx(x: float) -> Q:
	return Q.new(roundi(x * SCALE), SCALE)


## Whether a Paper 2 answer x can be asked to 3 s.f.: clear of a rounding edge, and
## with a third figure that isn't 0 (2.30), where the 2 s.f. rounding trap would be
## the answer itself.
static func sf_clean(x: float) -> bool:
	return absf(x) >= 0.1 and Answer.rounds_clearly(x, 0.05) and not Fmt.sf(x).ends_with("0")


## Paper 2 exp: u-roots u₁ > 0 (not a power of b) and −bʲ, so x = ln u₁/ln b.
static func _exp_p2(rng: Seeded) -> Dictionary:
	var base: int = [2, 2, 3][rng.int_in(0, 2)]
	var u1 := rng.int_in(2, 12)
	var j := rng.int_in(1, 3 if base == 2 else 2)
	var u2 := -int(pow(base, j))
	var x := log(float(u1)) / log(float(base))
	if absf(x - roundf(x)) < 1e-9 or u1 + u2 == 0 or not sf_clean(x):
		return {}
	return {"base": Q.new(base), "j": Q.new(j), "u1": Q.new(u1), "u2": Q.new(u2), "B": Q.new(-(u1 + u2)),
		"C": Q.new(u1 * u2), "x": approx(x), "r1": null, "r2": null, "paper": 2}


## Paper 2 log: x(x + d) = c with no whole-number root, so x = (−d + √(d² + 4c))/2.
static func _log_p2(rng: Seeded) -> Dictionary:
	var d := rng.int_in(-5, 6)
	var c := rng.int_in(2, 40)
	var disc := d * d + 4 * c
	var root := int(round(sqrt(float(disc))))
	if d == 0 or root * root == disc:
		return {}
	var x := (-d + sqrt(float(disc))) / 2.0
	var other := (-d - sqrt(float(disc))) / 2.0
	if not sf_clean(x) or not sf_clean(other):
		return {}
	return {"d": Q.new(d), "c": Q.new(c), "disc": Q.new(disc), "x": approx(x), "xneg": approx(other), "r1": null, "r2": null,
		"paper": 2}


static func export(s: Dictionary) -> Dictionary:
	return QuadraticSituation.export(s)
