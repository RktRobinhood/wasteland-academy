class_name LinearInequalitySituation
extends RefCounted
## The `fn-pre-linear-inequalities` situation (curriculum/question-types.json): a linear
## inequality, for the prior-learning type fn-pre-linear-inequalities (FAL-459). It is
## built from its solution, so the answer is clean.
##
## generate() returns:
##   form   "one" ax + b rel c, "two" c1 rel1 ax + b rel2 c2, "line" a solution drawn on a
##          number line, "count" a two-sided one whose ends need not be whole
##   a, b         the expression ax + b (a is never 0 or ±1)
##   one:   rel, c, and the solution x sol_rel v
##   two, count:  c1, c2, rel1, rel2 as shown, and the solution lo r1 x r2 hi
##   line:  sided ("one" or "two") and the solution, as for one or two
##   count: also n, the number of whole numbers in the solution

const RELS := ["<", "≤", ">", "≥"]
const FLIP := {"<": ">", ">": "<", "≤": "≥", "≥": "≤"}
const TRIES := 1000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var form: String = need.get("form", "one")
	for i in TRIES:
		var s := _draw(rng, form)
		if not s.is_empty():
			s.form = form
			return s
	push_error("LinearInequalitySituation: no clean situation for %s" % need)
	return {}


static func _coef(rng: Seeded) -> int:
	return rng.pick([-5, -4, -3, -2, 2, 3, 4, 5])


static func _draw(rng: Seeded, form: String) -> Dictionary:
	match form:
		"one":
			var a := _coef(rng)
			var b := ExtensionViews.nonzero(rng, -9, 9)
			var v := rng.int_in(-9, 9)
			var rel: String = rng.pick(RELS)
			return {"a": Q.new(a), "b": Q.new(b), "c": Q.new(a * v + b), "rel": rel, "v": Q.new(v),
				"sol_rel": rel if a > 0 else FLIP[rel]}
		"two":
			var a := _coef(rng)
			var b := ExtensionViews.nonzero(rng, -9, 9)
			var lo := rng.int_in(-8, 7)
			var hi := rng.int_in(lo + 1, mini(lo + 9, 9))
			return _two(a, b, Q.new(lo), Q.new(hi), rng.pick(["<", "≤"]), rng.pick(["<", "≤"]))
		"line":
			if rng.chance(0.5):
				var v := rng.int_in(-6, 6)
				return {"sided": "one", "sol_rel": rng.pick(RELS), "v": Q.new(v)}
			var lo := rng.int_in(-6, 5)
			var hi := rng.int_in(lo + 1, mini(lo + 7, 6))
			return {"sided": "two", "lo": Q.new(lo), "hi": Q.new(hi), "r1": rng.pick(["<", "≤"]), "r2": rng.pick(["<", "≤"])}
		"count":
			# The ends of the solution need not be whole: count the whole numbers between.
			var a := _coef(rng)
			var b := ExtensionViews.nonzero(rng, -9, 9)
			var c1 := rng.int_in(-25, 20)
			var c2 := rng.int_in(c1 + 2, c1 + 30)
			var r1: String = rng.pick(["<", "≤"])
			var r2: String = rng.pick(["<", "≤"])
			var x1 := Q.new(c1 - b, a)
			var x2 := Q.new(c2 - b, a)
			var s := _two_shown(a, b, Q.new(c1), Q.new(c2), r1, r2)
			var n := 0
			for x in range(floori(s.lo.to_float()) - 1, ceili(s.hi.to_float()) + 2):
				if holds(s, Q.new(x)):
					n += 1
			if n < 2 or n > 12 or (x1.is_int() and x2.is_int()):
				return {}
			s.n = Q.new(n)
			return s
	return {}


## The two-sided inequality shown for the solution lo r1 x r2 hi: dividing by a
## negative a turns the signs round, so its ends swap.
static func _two(a: int, b: int, lo: Q, hi: Q, r1: String, r2: String) -> Dictionary:
	var s := {"a": Q.new(a), "b": Q.new(b), "lo": lo, "hi": hi, "r1": r1, "r2": r2}
	if a > 0:
		s.c1 = lo.mul(a).add(b)
		s.c2 = hi.mul(a).add(b)
		s.rel1 = r1
		s.rel2 = r2
	else:
		s.c1 = hi.mul(a).add(b)
		s.c2 = lo.mul(a).add(b)
		s.rel1 = r2
		s.rel2 = r1
	return s


## The solution of c1 rel1 ax + b rel2 c2 as shown.
static func _two_shown(a: int, b: int, c1: Q, c2: Q, rel1: String, rel2: String) -> Dictionary:
	var s := {"a": Q.new(a), "b": Q.new(b), "c1": c1, "c2": c2, "rel1": rel1, "rel2": rel2}
	if a > 0:
		s.lo = c1.sub(b).div(a)
		s.hi = c2.sub(b).div(a)
		s.r1 = rel1
		s.r2 = rel2
	else:
		s.lo = c2.sub(b).div(a)
		s.hi = c1.sub(b).div(a)
		s.r1 = rel2
		s.r2 = rel1
	return s


## Whether x is in lo r1 x r2 hi.
static func holds(s: Dictionary, x: Q) -> bool:
	var left: bool = s.lo.lt(x) or (s.r1 == "≤" and s.lo.eq(x))
	var right: bool = x.lt(s.hi) or (s.r2 == "≤" and s.hi.eq(x))
	return left and right


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
