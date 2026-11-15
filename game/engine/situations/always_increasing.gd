class_name AlwaysIncreasingSituation
extends RefCounted
## The `always-increasing` situation (curriculum/question-types.json): a function whose derivative
## never changes sign, for t5-ext-always-increasing (FAL-776). f′ is built first, so it has one sign
## for every x, and f follows by integrating:
##   quadratic-derivative, decreasing-quadratic   f′(x) = sg·(3a(x − h)² + k), k > 0, sg = ±1
##   sum-of-terms     f′(x) = 3p·x² + q + rs·e^(sx), every term positive or 0
##   inverse-exists   f(x) = a·x² + b·ln x on x > 0, so f′(x) = 2ax + b/x
##   gdc-minimum      f′(x) = A·e^x − m·x + n, whose least value v (at x = ln(m/A)) is above 0
##
## generate() returns ask and paper (2 for gdc-minimum, else 1), the letters above, and for
## gdc-minimum xm and v (floats). The clean limits are the checker's too (E13AI_*).

const TRIES := 400


static func nz(rng: Seeded, lo: int, hi: int) -> int:
	return ExtensionViews.nonzero(rng, lo, hi)


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "quadratic-derivative")
	for i in TRIES:
		var s := _try(ask, rng)
		if not s.is_empty():
			s.ask = ask
			s.paper = 2 if ask == "gdc-minimum" else 1
			return s
	push_error("AlwaysIncreasingSituation: no clean situation for %s" % need)
	return {}


static func _try(ask: String, rng: Seeded) -> Dictionary:
	match ask:
		"quadratic-derivative", "decreasing-quadratic":
			return {"a": rng.pick([1, 1, 2]), "h": nz(rng, -3, 3), "k": rng.int_in(1, 9), "d": nz(rng, -9, 9),
				"sg": -1 if ask == "decreasing-quadratic" else 1, "x1": rng.pick([0, 1, -1])}
		"sum-of-terms":
			return {"p": rng.int_in(1, 3), "q": rng.int_in(1, 9), "r": rng.int_in(1, 4), "s": rng.pick([1, 2, 3])}
		"inverse-exists":
			return {"a": rng.int_in(1, 4), "b": rng.int_in(1, 9)}
		"gdc-minimum":
			var s := {"A": rng.pick([1, 2, 3]), "m": rng.pick([2, 4, 6]), "n": rng.int_in(-3, 5)}
			if s.m == s.A:
				return {}
			s.xm = log(float(s.m) / s.A)
			s.v = fp(s, s.xm)
			if s.v < 0.1 or s.v > 6.0 or not GdcKit.fair(s.v) or not GdcKit.fair(s.xm) or absf(s.xm) < 0.05:
				return {}
			# The two values a student might test, both positive, and f′(0) is not the least value.
			if fp(s, 0.0) <= 0.0 or fp(s, 1.0) <= 0.0 or not GdcKit.fair(fp(s, 1.0)) or Fmt.sf(fp(s, 0.0)) == Fmt.sf(s.v):
				return {}
			return s
	return {}


## f′(x) on gdc-minimum.
static func fp(s: Dictionary, x: float) -> float:
	return s.A * exp(x) - s.m * x + s.n


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
