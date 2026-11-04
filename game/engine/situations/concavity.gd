class_name ConcavitySituation
extends RefCounted
## The `concavity` situation (curriculum/question-types.json): a function, its second
## derivative and the shape of its graph (SL5.7, FAL-723). The SymPy checker
## (tools/check_answers.py) reads the function back from the question, differentiates it
## twice and solves the inequality itself.
##
## need.ask is the unknown. generate() returns a Dictionary with ask, paper and fam, and:
##   second-derivative        fam poly, exp, ln, sin, cos: a to e (see f_text in the views)
##   second-derivative-value  Paper 1 a polynomial at a whole x, or f′ given;  Paper 2 e^(cx) + ax²
##                            or x² ln x, at x to 1 d.p.
##   concave-interval         a cubic (MonotonicSituation.cubic), or a quartic whose f″ has
##                            whole-number roots p and q
##   concave-exponential      f″(x) = (ax + b)e^(cx)
##   concave-gdc              f′(x) = a + bx − c e^x, with two zeros
##   concave-from-derivative-graph  f′, a parabola with whole-number vertex and roots
##   concave-at-point         a cubic at a whole x, away from its point of inflexion
##   match-*                  a cubic, with turning points p < q

const TRIES := 800
## f′ on Paper 2 stays below this, so (f′)², a wrong option, is a number a student can type.
const FIRST_MAX := 300.0


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "second-derivative")
	var paper := int(need.get("paper", 1))
	var s := {}
	match ask:
		"second-derivative":
			s = {"fam": rng.pick(["poly", "exp", "ln", "sin", "cos"]), "a": ExtensionViews.nonzero(rng, -5, 5), "b": ExtensionViews.nonzero(rng, -6, 6),
				"c": ExtensionViews.nonzero(rng, -7, 7), "d": ExtensionViews.nonzero(rng, -9, 9), "e": rng.int_in(2, 4), "name": rng.pick(["f", "y"])}
		"second-derivative-value":
			s = _value(rng, paper)
		"concave-interval":
			if rng.chance(0.5):
				s = MonotonicSituation.cubic(rng)
			else:
				s = {"fam": "quartic", "A": rng.pick([1, 1, -1]), "p": rng.int_in(-3, 1), "d": rng.int_in(-6, 6), "e": rng.int_in(-5, 5)}
				s.q = s.p + 2 * rng.int_in(1, 2)
				s.coeffs = [s.A, -2 * s.A * (s.p + s.q), 6 * s.A * s.p * s.q, s.e, s.d]
			s.want = rng.pick(["up", "down"])
		"concave-exponential":
			s = {"fam": "exp", "a": rng.pick([1, 2, 3, 4, -1, -2, -3]), "c": ExtensionViews.nonzero(rng, -3, 3), "want": rng.pick(["up", "down"])}
			s.b = s.a * ExtensionViews.nonzero(rng, -5, 5)
		"concave-gdc":
			for i in TRIES:
				s = MonotonicSituation._gdc(rng)
				if s.is_empty():
					return {}
				if GdcKit.fair(log(float(s.b) / s.c)):
					break
			s.want = rng.pick(["up", "down"])
		"concave-from-derivative-graph":
			s = MonotonicSituation.quad(rng)
			s.want = rng.pick(["up", "down"])
		"concave-at-point":
			for i in TRIES:
				s = MonotonicSituation.cubic(rng)
				s.k = rng.int_in(s.p - 2, s.q + 2)
				if s.k != (s.p + s.q) / 2 and s.k != s.p and s.k != s.q:
					break
		_:
			s = MonotonicSituation.cubic(rng)
			s.A = absi(s.A)
			s.q = s.p + 4
			s.coeffs = [s.A, -3 * s.A * (s.p + s.q) / 2, 3 * s.A * s.p * s.q, s.d]
	s.ask = ask
	s.paper = paper
	return s


## A value of f″: exact on Paper 1, a fair GDC value on Paper 2.
static func _value(rng: Seeded, paper: int) -> Dictionary:
	if paper == 1:
		return {"fam": rng.pick(["cubic", "quartic", "given-prime"]), "a": ExtensionViews.nonzero(rng, -4, 4), "b": ExtensionViews.nonzero(rng, -6, 6),
			"c": ExtensionViews.nonzero(rng, -7, 7), "k": ExtensionViews.nonzero(rng, -3, 3)}
	for i in TRIES:
		var s := {"fam": rng.pick(["exp", "ln"]), "a": rng.int_in(1, 5), "c": rng.int_in(1, 2), "k": Q.new(rng.int_in(11, 29), 10)}
		if s.k.is_int() or absf(first_value(s)) > FIRST_MAX:
			continue
		if GdcKit.fair(second_value(s)):
			return s
	return {}


## f″(k) for the Paper 2 families.
static func second_value(s: Dictionary) -> float:
	var x: float = s.k.to_float()
	if s.fam == "exp":
		return s.c * s.c * exp(s.c * x) + 2.0 * s.a
	return 2.0 * log(x) + 3.0


static func first_value(s: Dictionary) -> float:
	var x: float = s.k.to_float()
	if s.fam == "exp":
		return s.c * exp(s.c * x) + 2.0 * s.a * x
	return 2.0 * x * log(x) + x


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
