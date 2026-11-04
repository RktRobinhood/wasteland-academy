class_name DerivativeMeaningSituation
extends RefCounted
## The `derivative-meaning` situation (curriculum/question-types.json): a quantity that
## changes with time, its rate of change and the limits it approaches (SL5.1, FAL-723).
## Every part in the bank is Paper 2, so the rates are GDC values, floats to 3 s.f.; the
## SymPy checker (tools/check_answers.py) reads the model back from the line shown,
## differentiates it and finds each value again.
##
## need.ask is the unknown. generate() returns a Dictionary with ask, paper (always 2), ctx
## (a story, an index into DerivativeMeaningViews.CONTEXTS), and by ask:
##   a model: fam "exp" A + B e^(−kt), or "sin" A + B sin(wt): A, B, k or w (Q), t0
##     and the value and rate at t0, v and r (floats);  rate-at-time, interpret-value,
##     limit-of-model and limit-of-rate use this
##   n  a whole-number rate, for write-in-notation
##   b, c  two rates and p, q two values, for compare-rates
##   a, rr, m  f(x) = m(x − a)(x − rr)/(x − a), for limit-cancel and limit-from-graph;
##     fam "cubic" for f(x) = (x³ − a³)/(x − a), in limit-from-table;  y the value drawn at x = a

const TRIES := 600
const CONTEXTS := 8
## |r| is a fair GDC value and at least this far from nothing.
const RATE_MIN := 0.05


static func model_y(s: Dictionary, t: float) -> float:
	var a: float = s.A.to_float()
	var b: float = s.B.to_float()
	if s.fam == "sin":
		return a + b * sin(s.w.to_float() * t)
	return a + b * exp(-s.k.to_float() * t)


static func model_dy(s: Dictionary, t: float) -> float:
	var b: float = s.B.to_float()
	if s.fam == "sin":
		var w: float = s.w.to_float()
		return b * w * cos(w * t)
	var k: float = s.k.to_float()
	return -b * k * exp(-k * t)


static func _model(s: Dictionary, rng: Seeded, allow_sin: bool = true) -> bool:
	for i in TRIES:
		s.fam = "sin" if allow_sin and rng.chance(0.35) else "exp"
		s.A = Q.new(rng.int_in(4, 18) * 5)
		s.B = Q.new(rng.pick([1, 1, -1]) * rng.int_in(3, 12) * 5) if s.fam == "exp" else Q.new(rng.int_in(2, 9))
		if s.fam == "exp" and s.A.add(s.B).sign() <= 0:
			continue
		s.k = Q.new(rng.int_in(4, 40), 100)
		s.w = Q.new(rng.int_in(2, 9), 10)
		s.t0 = rng.int_in(2, 12)
		s.v = model_y(s, s.t0)
		s.r = model_dy(s, s.t0)
		if absf(s.r) >= RATE_MIN and GdcKit.fair(s.r) and GdcKit.fair(s.v) and not is_equal_approx(absf(s.r), s.v):
			return true
	return false


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "rate-at-time")
	var s := {"ask": ask, "paper": 2, "ctx": rng.int_in(0, CONTEXTS - 1), "fam": "", "A": Q.new(0), "B": Q.new(0), "k": Q.new(0), "w": Q.new(0),
		"t0": 0, "v": 0.0, "r": 0.0, "n": 0, "b": 0.0, "c": 0.0, "p": 0.0, "q": 0.0, "a": 0, "rr": 0, "m": 1, "y": 0}
	match ask:
		"rate-at-time", "interpret-value":
			if not _model(s, rng):
				return {}
		"limit-of-model", "limit-of-rate":
			if not _model(s, rng, false):
				return {}
		"units-of-rate":
			pass
		"write-in-notation":
			s.n = rng.pick([1, 1, -1, -1]) * rng.int_in(2, 40)
		"compare-rates":
			for i in TRIES:
				s.b = rng.pick([1, -1]) * rng.int_in(12, 95) / 10.0
				s.c = rng.pick([1, -1]) * rng.int_in(12, 95) / 10.0
				if absi(roundi(absf(s.b) * 10.0) - roundi(absf(s.c) * 10.0)) >= 6:
					break
			s.t0 = rng.int_in(2, 12) * 5
			s.p = float(rng.int_in(20, 60) * 10)
			s.q = float(rng.int_in(20, 60) * 10 + 5)
		"limit-cancel", "limit-from-graph", "limit-from-table":
			s.fam = "cubic" if ask == "limit-from-table" and rng.chance(0.5) else "quad"
			s.a = ExtensionViews.nonzero(rng, -4, 4)
			s.m = rng.pick([1, 1, 2, 3, -1, -2])
			s.rr = s.a
			while s.rr == s.a or s.rr == 0 or s.m * (s.a - s.rr) == 0:
				s.rr = rng.int_in(-5, 5)
			s.y = limit_value(s).n + rng.pick([-3, -2, 2, 3, 4])
	return s


## The limit of f at a, exactly.
static func limit_value(s: Dictionary) -> Q:
	if s.fam == "cubic":
		return Q.new(3 * s.a * s.a)
	return Q.new(s.m * (s.a - s.rr))


## f(x) near a: m(x − rr), or x² + ax + a².
static func near(s: Dictionary, x: Q) -> Q:
	if s.fam == "cubic":
		return x.mul(x).add(x.mul(s.a)).add(s.a * s.a)
	return x.sub(s.rr).mul(s.m)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
