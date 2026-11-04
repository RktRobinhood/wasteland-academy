class_name MonotonicSituation
extends RefCounted
## The `monotonic` situation (curriculum/question-types.json): a function and the intervals
## on which it rises or falls (SL5.2, FAL-723). A cubic is built from its turning points,
## so f′(x) = 3A(x − p)(x − q) with p and q whole numbers, and a quadratic from its roots.
## The SymPy checker (tools/check_answers.py) reads the function back from the question,
## differentiates it and solves the inequality itself.
##
## need.ask is the unknown. generate() returns a Dictionary with ask and paper, and by ask:
##   cubic   A, p, q (p < q, q − p even), d, coeffs [A, B, C, d];  a cubic's f at p and q is
##           whole.  want is "increasing" or "decreasing", the one that is asked
##   quad    a, r, s (r < s, r + s even), coeffs [a, b, c], h, k the vertex
##   gdc     f′(x) = a + bx − c e^x, with r1 < r2 its zeros (floats)
##   param   k bound m = 3n: f(x) = ±x³ + kx² ± 3n²x + d, increasing or decreasing everywhere
##   shift   g′(x) = a(x − h)² + k − e, with a > 0

const TRIES := 800


static func cubic(rng: Seeded) -> Dictionary:
	var s := {"fam": "cubic", "want": rng.pick(["increasing", "decreasing"])}
	s.A = rng.pick([1, 1, 2, -1, -1, -2])
	s.p = rng.int_in(-4, 2)
	s.q = s.p + rng.pick([2, 4])
	s.d = rng.int_in(-6, 6)
	s.coeffs = [s.A, -3 * s.A * (s.p + s.q) / 2, 3 * s.A * s.p * s.q, s.d]
	return s


static func f_at(s: Dictionary, x: Q) -> Q:
	var out := Q.new(0)
	for c in s.coeffs:
		out = out.mul(x).add(c)
	return out


static func quad(rng: Seeded) -> Dictionary:
	var s := {"fam": "quad", "want": rng.pick(["increasing", "decreasing"])}
	s.a = rng.pick([1, 1, 2, 3, -1, -1, -2])
	s.r = rng.int_in(-6, 3)
	s.s = s.r + 2 * rng.int_in(1, 4)
	s.h = (s.r + s.s) / 2
	s.k = s.a * (s.h - s.r) * (s.h - s.s)
	s.coeffs = [s.a, -s.a * (s.r + s.s), s.a * s.r * s.s]
	return s


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "interval-from-equation")
	var s: Dictionary
	match ask:
		"interval-from-equation", "interval-from-table", "sign-at-points":
			s = cubic(rng)
		"interval-from-derivative-graph", "quadratic-interval", "intervals-from-graph":
			s = quad(rng)
		"negative-and-increasing":
			s = quad(rng)
			s.want = "negative" if s.a > 0 else "positive"
		"interval-gdc":
			s = _gdc(rng)
		"parameter-discriminant":
			s = {"fam": "param", "want": rng.pick(["increasing", "decreasing"]), "n": rng.int_in(1, 4), "d": rng.int_in(-9, 9)}
		"parameter-shift":
			s = quad(rng)
			s.fam = "shift"
			s.a = rng.int_in(1, 4)
			s.h = rng.int_in(-5, 5)
			s.k = ExtensionViews.nonzero(rng, -9, 9)
	if s.is_empty():
		return {}
	s.ask = ask
	s.paper = int(need.get("paper", 1))
	if ask == "sign-at-points":
		# One point in each of two of the three stretches, or on a turning point.
		var mid: int = (s.p + s.q) / 2
		s.x1 = s.p - rng.int_in(1, 2)
		s.x2 = rng.pick([mid, s.q, s.q + 1])
	return s


static func _gdc(rng: Seeded) -> Dictionary:
	for i in TRIES:
		var a := rng.int_in(3, 9)
		var b := rng.int_in(1, 4)
		var c := rng.int_in(1, 3)
		var f := func(x: float) -> float: return a + b * x - c * exp(x)
		var zs := GdcKit.zeros(f, -14.0, 6.0)
		if zs.size() != 2 or not GdcKit.fair(zs[0]) or not GdcKit.fair(zs[1]):
			continue
		return {"fam": "gdc", "a": a, "b": b, "c": c, "r1": zs[0], "r2": zs[1], "want": rng.pick(["increasing", "decreasing"])}
	return {}


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
