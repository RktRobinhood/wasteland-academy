class_name QuadraticInequalitySituation
extends RefCounted
## The `quadratic-inequality` situation (curriculum/question-types.json), which extends
## `quadratic`: the parabola compared with a number (FAL-414). It calls
## QuadraticSituation.generate() and adds the sign, a right-hand side to move across
## first, and the solution set; the largest-integer context and x² against n² pick their
## own numbers.
##
## generate() returns the parabola's quantities plus:
##   form    "zero", "const", "nega", "none", "fromsol", "square" or "largest"
##   rel     "<", "≤", ">" or "≥"
##   rhs     the number f(x) is compared with (0 unless form is "const")
##   n       x² compared with n² (square); d and T for n(n + d) ≤ T (largest)

const RELS := ["<", "≤", ">", "≥"]
const TRIES := 2000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	# The stream's first draw leans low (chance(0.25) is true for every seed), so it is
	# spent before anything is picked. Seeded itself is left alone: changing it would
	# change every other situation's questions.
	rng.int_in(0, 1)
	var form: String = need.get("form", "zero")
	for i in TRIES:
		var s := _draw(rng, form, need)
		if not s.is_empty():
			s.form = form
			if not s.has("rel"):
				s.rel = RELS[rng.int_in(0, 3)]
			return s
	push_error("QuadraticInequalitySituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, form: String, need: Dictionary) -> Dictionary:
	match form:
		"zero", "const", "nega", "fromsol":
			var s := QuadraticSituation.generate(rng, {"mode": "rational", "graph": need.get("graph", false)})
			if s.is_empty():
				return {}
			if form == "nega" and s.a.sign() > 0:
				return {}
			if form == "zero" and s.a.sign() < 0 and rng.chance(0.6):
				return {}
			s.rhs = Q.new(0)
			if form == "const":
				var d := rng.int_in(-9, 9)
				if d == 0 or absi(s.c.n + d * s.c.d) > QuadraticSituation.C_MAX * s.c.d:
					return {}
				s.rhs = Q.new(d)
			if form == "fromsol":
				s.a = Q.new(1)
				s.b = s.p.add(s.q).neg()
				s.c = s.p.mul(s.q)
				s.h = s.p.add(s.q).div(2)
				s.k = QuadraticSituation.f(s, s.h)
			return s
		"none":
			var s := QuadraticSituation.generate(rng, {"mode": "none", "graph": need.get("graph", false)})
			if not s.is_empty():
				s.rhs = Q.new(0)
			return s
		"square":
			var n := rng.int_in(1, 9)
			return {"n": Q.new(n), "a": Q.new(1), "b": Q.new(0), "c": Q.new(-n * n), "p": Q.new(-n), "q": Q.new(n), "rhs": Q.new(n * n)}
		"largest":
			var d := rng.int_in(1, 9)
			var t := rng.int_in(30, 400)
			var disc := d * d + 4 * t
			var root := int(round(sqrt(float(disc))))
			if root * root == disc:
				return {}
			var x := (-d + sqrt(float(disc))) / 2.0
			# Far enough from a whole number that rounding the root to 3 s.f. can't mislead.
			if absf(x - round(x)) < 0.05:
				return {}
			return {"d": Q.new(d), "T": Q.new(t), "root": x, "best": Q.new(floori(x)), "rel": "≤"}
	return {}


static func export(s: Dictionary) -> Dictionary:
	return QuadraticSituation.export(s)
