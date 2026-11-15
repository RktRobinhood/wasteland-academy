class_name IntegralGdcSituation
extends RefCounted
## The `integral-gdc` situation (curriculum/question-types.json): a definite integral only the GDC
## can evaluate, for t5-ext-integral-gdc (FAL-776). Every question is Paper 2.
##
## Families, each with the slip its entry invites:
##   esin    e^x sin x on [0, b]          trig: degree mode
##   sinx2   sin(x²) on [0, b]            trig: degree mode
##   eshift  e^(x + c) on [0, b]          brackets: e^x + c
##   sqrt    √(x³ + c) on [0, b]          brackets: √(x³) + c
##   lnq     ln(x² + c) on [1, b]         brackets: ln(x²) + c
##   recip   1/(x² + c) on [1, b]         brackets: 1/x² + c
##   poly    a cubic on [a, b] (polynomial-check), worked exactly as well
## generate() returns ask, paper (2), fam, c, a, b, v (the value), deg and slip (the slip's value),
## and for poly the coefficients (Q). Every value is fair to 3 s.f. and differs from the others.

const TRIG := ["esin", "sinx2"]
const BRACKETS := ["eshift", "sqrt", "lnq", "recip"]
const TRIES := 400


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "gdc-value")
	for i in TRIES:
		var s := _try(ask, rng)
		if not s.is_empty():
			s.ask = ask
			s.paper = 2
			return s
	push_error("IntegralGdcSituation: no clean situation for %s" % need)
	return {}


static func _try(ask: String, rng: Seeded) -> Dictionary:
	if ask == "polynomial-check":
		var lo := rng.int_in(-1, 2)
		var s := {"fam": "poly", "coeffs": [Q.new(ExtensionViews.nonzero(rng, -3, 3)), Q.new(rng.int_in(-6, 6)), Q.new(rng.int_in(-9, 9)), Q.new(rng.int_in(-9, 9))],
			"a": lo, "b": lo + rng.int_in(1, 3), "c": 0}
		var v := DefiniteIntegralSituation.integral(s.coeffs, s.a, s.b)
		s.v = v.to_float()
		if not GdcKit.fair(s.v) or not GdcKit.fair(absf(s.v)) or Fmt.sf(s.v) == Fmt.sf(-s.v):
			return {}
		return s
	var fam: String = rng.pick(TRIG + BRACKETS)
	var s := {"fam": fam, "c": rng.int_in(1, 5), "a": 0, "b": rng.int_in(1, 3)}
	match fam:
		"sinx2":
			s.b = rng.pick([1, 2])
		"lnq":
			s.a = 1
			s.b = rng.int_in(2, 4)
		"recip":
			s.a = 1
			s.b = rng.int_in(2, 4)
	s.v = DefiniteIntegralSituation.simpson(f(s), float(s.a), float(s.b))
	s.deg = DefiniteIntegralSituation.simpson(f(s, true), float(s.a), float(s.b)) if fam in TRIG else 0.0
	s.slip = DefiniteIntegralSituation.simpson(slipped(s), float(s.a), float(s.b)) if fam in BRACKETS else 0.0
	var vals: Array = [s.v, -s.v] + ([s.deg] if fam in TRIG else [s.slip])
	var seen := {}
	for x in vals:
		if not GdcKit.fair(absf(x)) or seen.has(Fmt.sf(x)):
			return {}
		seen[Fmt.sf(x)] = true
	return s


## The integrand; with deg, as a GDC in degree mode works it out.
static func f(s: Dictionary, deg: bool = false) -> Callable:
	var c := float(s.c)
	var k := PI / 180.0 if deg else 1.0
	match s.fam:
		"esin":
			return func(x: float) -> float: return exp(x) * sin(k * x)
		"sinx2":
			return func(x: float) -> float: return sin(k * x * x)
		"eshift":
			return func(x: float) -> float: return exp(x + c)
		"sqrt":
			return func(x: float) -> float: return sqrt(x * x * x + c)
		"lnq":
			return func(x: float) -> float: return log(x * x + c)
		_:
			return func(x: float) -> float: return 1.0 / (x * x + c)


## The integrand entered with its bracket closed too soon: the + c falls outside.
static func slipped(s: Dictionary) -> Callable:
	var c := float(s.c)
	match s.fam:
		"eshift":
			return func(x: float) -> float: return exp(x) + c
		"sqrt":
			return func(x: float) -> float: return sqrt(x * x * x) + c
		"lnq":
			return func(x: float) -> float: return log(x * x) + c
		_:
			return func(x: float) -> float: return 1.0 / (x * x) + c


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
