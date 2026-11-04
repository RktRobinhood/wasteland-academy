class_name IntegrationSituation
extends RefCounted
## The `integration` situation (curriculum/question-types.json): one function to integrate,
## with whole-number coefficients (FAL-724). The SymPy checker (tools/check_answers.py) reads
## the integrand back from the question, differentiates every option and compares.
##
## need.ask is the unknown. generate() returns a Dictionary with ask, paper and fam, and
## a, b, c, k, n, p, q as that unknown's builder reads them (see integration_views.gd).


static func nz(rng: Seeded, lo: int, hi: int) -> int:
	return ExtensionViews.nonzero(rng, lo, hi)


## A linear inside ax + b: a is never ±1, so dividing by it matters.
static func _inside(rng: Seeded, s: Dictionary, with_b: bool = true) -> void:
	s.a = rng.pick([2, 2, 3, 3, 4, 5, -2, -3])
	s.b = rng.int_in(-5, 5) if with_b else 0


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "power-polynomial")
	var s := {"ask": ask, "paper": int(need.get("paper", 1)), "fam": ""}
	match ask:
		"power-polynomial":
			s.a = nz(rng, -5, 9)
			s.b = nz(rng, -9, 9)
			s.c = nz(rng, -9, 9)
		"power-negative":
			s.a = nz(rng, -8, 8)
			s.b = nz(rng, -7, 7)
			s.n = rng.pick([2, 2, 3, 4])
		"power-product":
			s.p = nz(rng, -6, 6)
			s.q = nz(rng, -6, 6)
			if s.p + s.q == 0:
				s.q += 1 if s.q != -1 else 2
		"standard-exp-trig":
			s.a = nz(rng, -6, 6)
			s.b = nz(rng, -6, 6)
			s.c = nz(rng, -6, 6)
		"standard-reciprocal", "rewrite-fraction":
			s.a = rng.pick([1, 1, 2, 3, 4, -1, -2, 6])
			s.b = nz(rng, -7, 7)
			s.c = nz(rng, -6, 6)
		"standard-roots":
			s.fam = rng.pick(["sqrt", "sqrt", "cbrt"])
			s.a = 3 * rng.int_in(1, 3) * (2 if s.fam == "cbrt" else 1)
			s.b = nz(rng, -5, 5) * 2
		"linear-exp":
			_inside(rng, s)
			s.c = nz(rng, -7, 7)
		"linear-trig":
			_inside(rng, s, rng.chance(0.5))
			if s.b == 0:
				s.a = absi(s.a)
			s.k = nz(rng, -6, 6)
			s.fam = rng.pick(["cos", "sin"])
		"linear-reciprocal":
			_inside(rng, s)
			if s.b == 0:
				s.b = 1
			s.k = rng.pick([1, 1, 3, 4, 5, 6, -2])
		"linear-power":
			_inside(rng, s)
			if s.b == 0:
				s.b = 3
			s.n = rng.int_in(3, 6)
			s.k = rng.pick([1, 1, 2, 3])
		"linear-square":
			_inside(rng, s)
			if s.b == 0:
				s.b = -1
		"inspection-power":
			s.fam = rng.pick(["top", "bottom"])
			s.a = rng.int_in(1, 7)
			s.n = rng.int_in(2, 4)
			s.k = 2 * rng.pick([1, 2, 3, 4, 5, 6])
		"inspection-exp":
			s.a = rng.int_in(-3, 5)
			s.k = 2 * rng.pick([1, 2, 3, 4, -1, -2])
		"inspection-log":
			s.a = rng.int_in(1, 9)
			s.k = 2 * rng.pick([1, 2, 3, 4, 5, -1])
		"inspection-trig":
			s.fam = rng.pick(["sincos", "cossin"])
			s.n = rng.int_in(2, 6)
			s.k = rng.pick([1, 1, 2, 3, -1])
		"rewrite-square":
			s.fam = rng.pick(["root", "exp"])
			s.a = 3 * rng.int_in(1, 3) if s.fam == "root" else nz(rng, -5, 5)
		"rewrite-trig-product":
			s.k = 2 * rng.pick([1, 1, 2, 3, 4, 5])
	return s


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
