class_name AreaUnderCurveSituation
extends RefCounted
## The `area-under-curve` situation (curriculum/question-types.json): a region R above the x-axis
## under one curve, for t5-ext-area-under-curve (FAL-776).
##
## Families:
##   hump    f(x) = −a(x − r)(x − t): whole roots r < t, and whole edges r < p < q < t where R is cut
##           by two vertical lines. Exact, Paper 1 (or Paper 2 by the GDC).
##   wave    f(x) = c + x·e^(−x/2) on [p, q] with 0 ≤ p: Paper 2, by the GDC.
##   line    f(x) = mx + c on [p, q], positive there: a trapezium.
##   surd    f(x) = −a·x² + b·x + c with a discriminant that is not a square: roots only the GDC
##           gives (area-gdc-limits, and integral-from-roots by the GDC's zero finder).
##
## generate() returns ask, paper, fam, coeffs (Q, highest power first, except wave), r, t, p, q, a, c,
## and for surd the float roots r1, r2. The clean limits are the checker's too (E13AU_*).

const TRIES := 400


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "area-between-lines")
	var gdc := str(need.get("angle", "")).begins_with("gdc-")
	for i in TRIES:
		var s := _try(ask, gdc, rng)
		if not s.is_empty():
			s.ask = ask
			s.paper = 2 if gdc else 1
			return s
	push_error("AreaUnderCurveSituation: no clean situation for %s" % need)
	return {}


static func hump(rng: Seeded, need_inside: bool) -> Dictionary:
	var a: int = rng.pick([1, 1, 2])
	var r := rng.int_in(-3, 2)
	var t := r + rng.int_in(3 if need_inside else 2, 6)
	var s := {"fam": "hump", "a": a, "r": r, "t": t, "coeffs": [Q.new(-a), Q.new(a * (r + t)), Q.new(-a * r * t)]}
	if need_inside:
		s.p = rng.int_in(r + 1, t - 2)
		s.q = rng.int_in(s.p + 1, t - 1)
	return s


static func at(s: Dictionary, x: Variant) -> Q:
	return DefiniteIntegralSituation.at(s.coeffs, x)


static func area(s: Dictionary, lo: Variant, hi: Variant) -> Q:
	return DefiniteIntegralSituation.integral(s.coeffs, lo, hi)


static func _try(ask: String, gdc: bool, rng: Seeded) -> Dictionary:
	match ask:
		"integral-from-graph":
			var s := hump(rng, true)
			return s if not at(s, s.p).eq(at(s, s.q)) and at(s, s.p).is_int() else {}
		"integral-from-roots":
			if gdc:
				return _surd(rng)
			var s := hump(rng, false)
			return s if s.r != 0 and s.t != 0 else {}
		"region-for-integral":
			var s := hump(rng, true)
			return s if s.r < 0 and s.p > 0 else {}
		"area-between-lines":
			if gdc:
				var w := {"fam": "wave", "c": rng.int_in(1, 4), "p": rng.int_in(0, 2), "coeffs": []}
				w.q = w.p + rng.int_in(1, 3)
				w.v = DefiniteIntegralSituation.simpson(wave(w), float(w.p), float(w.q))
				w.v0 = DefiniteIntegralSituation.simpson(wave(w), 0.0, float(w.q))
				return w if GdcKit.fair(w.v) and (w.p == 0 or GdcKit.fair(w.v0)) else {}
			return hump(rng, true)
		"area-between-roots":
			var s := hump(rng, false)
			if s.r == 0 or area(s, 0, s.t).is_zero():
				return {}
			if gdc and (not GdcKit.fair(area(s, s.r, s.t).to_float()) or not GdcKit.fair(absf(area(s, 0, s.t).to_float()))):
				return {}
			return s
		"area-with-y-axis":
			var s := hump(rng, false)
			return s if s.r < 0 and s.t > 0 else {}
		"area-straight-edge":
			var m: int = ExtensionViews.nonzero(rng, -3, 3)
			var p := rng.int_in(0, 3)
			var q := p + rng.int_in(1, 4)
			var c := rng.int_in(1, 9)
			var s := {"fam": "line", "coeffs": [Q.new(m), Q.new(c)], "p": p, "q": q, "a": m, "c": c}
			return s if at(s, p).sign() > 0 and at(s, q).sign() > 0 else {}
		"area-gdc-limits":
			return _surd(rng)
	return {}


## −a·x² + b·x + c with irrational roots, and the area between them to 3 s.f.; the slip rounds the
## roots to 1 d.p. first, and must change the answer at 3 s.f.
static func _surd(rng: Seeded) -> Dictionary:
	var a: int = rng.pick([1, 2, 3])
	var b := rng.int_in(-4, 6)
	var c := rng.int_in(1, 7)
	var d := b * b + 4 * a * c
	var root := roundi(sqrt(float(d)))
	if root * root == d:
		return {}
	var s := {"fam": "surd", "a": a, "coeffs": [Q.new(-a), Q.new(b), Q.new(c)]}
	s.r1 = (b - sqrt(float(d))) / (2.0 * a)
	s.r2 = (b + sqrt(float(d))) / (2.0 * a)
	var f := poly_fn(s.coeffs)
	s.v = DefiniteIntegralSituation.simpson(f, s.r1, s.r2)
	s.slip = DefiniteIntegralSituation.simpson(f, snappedf(s.r1, 0.1), snappedf(s.r2, 0.1))
	if not GdcKit.fair(s.v) or not GdcKit.fair(s.slip) or Fmt.sf(s.v) == Fmt.sf(s.slip):
		return {}
	if not GdcKit.fair(absf(s.r1)) or not GdcKit.fair(s.r2) or absf(s.r1) < 0.1:
		return {}
	return s


## A polynomial with Q coefficients, highest power first, as a float function.
static func poly_fn(coeffs: Array) -> Callable:
	var cs: Array = coeffs.map(func(c): return Q.of(c).to_float())
	return func(x: float) -> float:
		var y := 0.0
		for c in cs:
			y = y * x + c
		return y


static func wave(s: Dictionary) -> Callable:
	var c := float(s.c)
	return func(x: float) -> float: return c + x * exp(-x / 2.0)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
