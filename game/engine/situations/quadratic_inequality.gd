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
##   paper   1 or 2. Paper 2 (need.paper = 2, for zero, const and nega): whole-number
##           coefficients whose roots are irrational, so the ends need a calculator and
##           are given to 3 s.f.; p and q are then the roots to six decimal places
##           (few enough that products of Qs stay inside 64 bits). The
##           largest-integer context is Paper 2 (its boundary needs a calculator);
##           the rest are Paper 1.

const RELS := ["<", "≤", ">", "≥"]
const TRIES := 2000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var form: String = need.get("form", "zero")
	var p2: bool = int(need.get("paper", 1)) == 2 and form in P2_FORMS
	for i in TRIES:
		var s := _draw_p2(rng, form, need) if p2 else _draw(rng, form, need)
		if not s.is_empty():
			s.form = form
			if not s.has("rel"):
				s.rel = RELS[rng.int_in(0, 3)]
			if not s.has("paper"):
				s.paper = 2 if form == "largest" else 1
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


## The forms with a Paper 2 version whose roots need a calculator.
const P2_FORMS := ["zero", "const", "nega"]
const SCALE := 1000000


## Paper 2: a·x² + b·x + c with whole numbers and Δ > 0 not a square, so the roots are
## irrational. Each root is clear of a 3 s.f. rounding edge.
static func _draw_p2(rng: Seeded, form: String, need: Dictionary) -> Dictionary:
	var a: int = [1, 1, 2, 3, -1, -2][rng.int_in(0, 5)]
	if form == "nega":
		a = -absi(a)
	elif form == "zero" and a < 0 and rng.chance(0.6):
		return {}
	var b := rng.int_in(-9, 9)
	var c := rng.int_in(-12, 12)
	var disc := b * b - 4 * a * c
	var root := int(round(sqrt(float(maxi(disc, 0)))))
	if c == 0 or disc <= 0 or root * root == disc:
		return {}
	var r1 := (-b - sqrt(float(disc))) / (2.0 * a)
	var r2 := (-b + sqrt(float(disc))) / (2.0 * a)
	var lo := minf(r1, r2)
	var hi := maxf(r1, r2)
	for x in [lo, hi]:
		if absf(x) < 0.1 or absf(x) > 12.0 or not Answer.rounds_clearly(x, 0.05):
			return {}
	var s := {"a": Q.new(a), "b": Q.new(b), "c": Q.new(c), "disc": Q.new(disc), "h": Q.new(-b, 2 * a),
		"p": Q.new(roundi(lo * SCALE), SCALE), "q": Q.new(roundi(hi * SCALE), SCALE), "rhs": Q.new(0), "paper": 2, "mode": "irrational"}
	s.k = s.c.sub(s.b.sq().div(s.a.mul(4)))
	if need.get("graph", false) and (absi(c) > QuadraticSituation.GRAPH_Y_MAX or absf(s.k.to_float()) > QuadraticSituation.GRAPH_Y_MAX):
		return {}
	if form == "const":
		var d := rng.int_in(-9, 9)
		if d == 0 or absi(c + d) > QuadraticSituation.C_MAX:
			return {}
		s.rhs = Q.new(d)
	return s


static func export(s: Dictionary) -> Dictionary:
	return QuadraticSituation.export(s)
