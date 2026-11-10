class_name TrigSketchSituation
extends RefCounted
## The `trig-sketch` situation (curriculum/question-types.json): one circular function on a given
## domain, to sketch, for t3-trig-sketch (SL3.7.sketch, FAL-754). A phone can't take a drawing, so
## the sketch itself is picked from four graphs, and the features a sketch must mark (its maximum and
## minimum points, its intercepts, tan's asymptotes, the five key points of a period) are typed.
##   Paper 1  y = a fn(bx) + d with whole a and d and b of 1, 2, 3 or 1/2, on a domain in multiples of
##            π, or in degrees. Every position is a Q of π (180° for a degree domain).
##   Paper 2  only the GDC's cells (gdc-transfer). A sketch keeps Paper 1's numbers; a maximum point
##            or an x-intercept is on y = A fn(Bx) + D with tenths, on a whole-number domain, to 3 s.f.
##
## need.ask is the unknown (see TrigSketchViews). generate() returns a Dictionary:
##   paper, ask, rep, angle, spin  (where a question's slips start, so every slip shows across seeds)
##   form        "pi" or "deg": how the domain and every position are written
##   kind        "x" (exact) or "dec" (Paper 2's tenths)
##   fn, a, b, d y = a fn(bx) + d: Qs; for "dec" a, b and d are tenths
##   lo, hi      the domain: Qs of π for "x", whole numbers for "dec"
##   xs          x-intercepts: the zeros on the domain, Qs of π (or floats' Qs for "dec")
##   blanks      key-points: the two places of the table left blank
##   tops, lows  "dec" max-min-points: the x of its one maximum and one minimum, floats

const TRIES := 600
const DEG_SHARE := 0.3
## b as [n, d].
const B_WAVE := [[1, 1], [2, 1], [3, 1], [1, 2]]
const B_TAN := [[1, 1], [2, 1], [1, 2]]
const B_ASYM := [[1, 1], [2, 1], [3, 1], [1, 2]]
const B_ZERO := [[1, 1], [2, 1], [1, 2]]
const B_DEC := [6, 7, 8, 9, 11, 12, 13, 14, 16, 17, 18, 19, 22, 24]
const PICKS := ["sketch-wave", "sketch-from-table", "sketch-reflected", "sketch-tan"]
const GDC := "gdc-transfer"


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "sketch-wave")
	var rep: String = need.get("rep", "equation")
	var angle: String = need.get("angle", "any")
	var paper: int = int(need.get("paper", 2 if angle == GDC else 1))
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "angle": angle, "form": "pi", "kind": "x", "spin": rng.int_in(0, 59),
			"fn": "sin", "a": Q.new(1), "b": Q.new(1), "d": Q.new(0), "lo": Q.new(0), "hi": Q.new(2)}
		# A GDC works in radians, and a table's x row stays in π.
		if angle != GDC and rep != "table" and rng.chance(DEG_SHARE):
			s.form = "deg"
		if new().call("_" + ask.replace("-", "_"), rng, s):
			return s
	return {}


static func bq(rng: Seeded, list: Array) -> Q:
	var p: Array = rng.pick(list)
	return Q.new(p[0], p[1])


## One period of sin or cos, 2/b of π; tan's is 1/b.
static func period(s: Dictionary) -> Q:
	return Q.new(1 if s.fn == "tan" else 2).div(s.b)


## A whole a or d that isn't 0, up to size n, negative with chance p.
static func signed(rng: Seeded, lo: int, hi: int, p: float) -> Q:
	var v := rng.int_in(lo, hi)
	return Q.new(-v if rng.chance(p) else v)


# ── The sketches (pick the graph) ────────────────────────────

## a fn(bx) + d with a > 0: two periods on 0 to 2π (b = 1), more for b = 2 or 3, and 0 to 4π for
## b = 1/2. A table gives one period, five key points.
static func _sketch_wave(rng: Seeded, s: Dictionary) -> bool:
	s.fn = rng.pick(["sin", "cos"])
	s.a = Q.new(rng.int_in(1, 4))
	s.b = bq(rng, B_WAVE)
	s.d = Q.new(rng.int_in(-3, 3) if rng.chance(0.75) else 0)
	s.hi = Q.new(4) if s.b.lt(1) else Q.new(2)
	return not (s.a.eq(1) and s.d.is_zero() and s.b.eq(1))


## The same wave over one period, given by its five key points.
static func _sketch_from_table(rng: Seeded, s: Dictionary) -> bool:
	_sketch_wave(rng, s)
	s.hi = period(s)
	return not s.d.is_zero() or not s.a.eq(1)


## −a fn(bx) + d: the reflection, −sin(2x) at its plainest.
static func _sketch_reflected(rng: Seeded, s: Dictionary) -> bool:
	s.fn = rng.pick(["sin", "cos"])
	s.a = Q.new(-rng.int_in(1, 3))
	s.b = bq(rng, B_WAVE)
	s.d = Q.new(0) if rng.chance(0.5) else Q.new(ExtensionViews.nonzero(rng, -3, 3))
	s.hi = Q.new(4) if s.b.lt(1) else Q.new(2)
	return true


## a tan(bx) + d over two periods, with its asymptotes.
static func _sketch_tan(rng: Seeded, s: Dictionary) -> bool:
	s.fn = "tan"
	s.a = signed(rng, 1, 3, 0.3)
	s.b = bq(rng, B_TAN)
	s.d = Q.new(0) if rng.chance(0.5) else Q.new(ExtensionViews.nonzero(rng, -2, 2))
	s.hi = period(s).mul(2)
	return true


# ── The features a sketch marks ──────────────────────────────

## One maximum and one minimum inside the domain: 0 to a period for sin, a quarter of a period
## earlier for cos, so neither sits on an end.
static func _max_min_points(rng: Seeded, s: Dictionary) -> bool:
	if s.paper == 2:
		return _dec_wave(rng, s) and _dec_turns(rng, s)
	s.fn = rng.pick(["sin", "cos"])
	s.a = signed(rng, 1, 5, 0.3)
	s.b = bq(rng, B_WAVE)
	s.d = Q.new(rng.int_in(-4, 4))
	var P := period(s)
	if s.fn == "sin":
		s.hi = P
	else:
		s.lo = P.div(4).neg()
		s.hi = P.mul(Q.new(3, 4))
	return not s.a.abs_q().eq(1) or not s.d.is_zero()


## (0, f(0)): mostly cos, whose y-intercept is a + d, and sin or tan, whose is d.
static func _y_intercept(rng: Seeded, s: Dictionary) -> bool:
	s.fn = ["cos", "cos", "cos", "sin", "tan"][rng.int_in(0, 4)]
	s.a = signed(rng, 1, 5, 0.35)
	s.b = bq(rng, B_TAN if s.fn == "tan" else B_WAVE)
	s.d = Q.new(rng.int_in(-4, 4))
	s.hi = period(s).mul(2) if s.fn == "tan" else Q.new(2)
	if s.fn != "cos" and s.d.is_zero():
		return false
	return not s.a.add(s.d).is_zero()


## a fn(bx) + d crosses the axis where fn(bx) = −d/a = ±1/2: twice in one period.
static func _x_intercepts(rng: Seeded, s: Dictionary) -> bool:
	if s.paper == 2:
		return _dec_wave(rng, s) and _dec_zeros(rng, s)
	s.fn = rng.pick(["sin", "cos"])
	var dd := rng.int_in(1, 3)
	s.d = Q.new(dd if rng.chance(0.5) else -dd)
	s.a = Q.new(2 * dd if rng.chance(0.6) else -2 * dd)
	s.b = bq(rng, B_ZERO)
	s.hi = period(s)
	s.xs = zeros_exact(s.fn, s.d.neg().div(s.a), s.b)
	return s.xs.size() == 2


## The angles θ in [0, 2π) with fn θ = k, k = ±1/2, divided by b: Qs of π, in order.
static func zeros_exact(fn: String, k: Q, b: Q) -> Array:
	var base: Array
	var up := k.sign() > 0
	if fn == "sin":
		base = [Q.new(1, 6), Q.new(5, 6)] if up else [Q.new(7, 6), Q.new(11, 6)]
	else:
		base = [Q.new(1, 3), Q.new(5, 3)] if up else [Q.new(2, 3), Q.new(4, 3)]
	return base.map(func(t): return t.div(b))


## tan's asymptotes on two periods: a quarter and three quarters of the way along.
static func _tan_asymptotes(rng: Seeded, s: Dictionary) -> bool:
	s.fn = "tan"
	s.a = signed(rng, 1, 4, 0.3)
	s.b = bq(rng, B_ASYM)
	s.d = Q.new(rng.int_in(-3, 3))
	s.hi = period(s).mul(2)
	return true


## One period's five key points in a table, two of the y-values left blank.
static func _key_points(rng: Seeded, s: Dictionary) -> bool:
	s.fn = rng.pick(["sin", "cos"])
	s.a = signed(rng, 2, 5, 0.3)
	s.b = bq(rng, B_WAVE)
	s.d = Q.new(ExtensionViews.nonzero(rng, -4, 4))
	s.hi = period(s)
	s.blanks = rng.pick([[1, 3], [0, 2], [0, 1], [1, 2], [2, 3], [3, 4], [0, 3], [1, 4]])
	# At least one blank is a turning point, so the pattern decides it.
	var pat: Array = TrigSketchViews.PATTERN[s.fn]
	return pat[s.blanks[0]] != 0 or pat[s.blanks[1]] != 0


# ── Paper 2: a wave with tenths, for the GDC ─────────────────

static func _dec_wave(rng: Seeded, s: Dictionary) -> bool:
	s.kind = "dec"
	s.form = "pi"
	s.fn = rng.pick(["sin", "cos"])
	var a := rng.int_in(15, 45)
	s.a = Q.new(-a if rng.chance(0.3) else a, 10)
	s.b = Q.new(rng.pick(B_DEC), 10)
	s.d = Q.new(ExtensionViews.nonzero(rng, -30, 30), 10)
	s.lo = Q.new(0 if s.fn == "sin" else rng.pick([-1, 1]))
	return true


static func value(s: Dictionary, x: float) -> float:
	var t: float = s.b.to_float() * x
	var f := sin(t) if s.fn == "sin" else (cos(t) if s.fn == "cos" else tan(t))
	return s.a.to_float() * f + s.d.to_float()


## The x of every maximum and minimum strictly inside (lo, hi): bx at a quarter or three quarters
## of a turn for sin, a whole or half turn for cos.
static func dec_turns(s: Dictionary, lo: float, hi: float) -> Dictionary:
	var b: float = s.b.to_float()
	var top_phase := (0.25 if s.fn == "sin" else 0.0) + (0.5 if s.a.sign() < 0 else 0.0)
	var out := {"tops": [], "lows": []}
	for k in range(-6, 12):
		var xt := TAU * (top_phase + k) / b
		var xl := TAU * (top_phase + 0.5 + k) / b
		if xt > lo and xt < hi:
			out.tops.append(xt)
		if xl > lo and xl < hi:
			out.lows.append(xl)
	return out


static func _dec_turns(rng: Seeded, s: Dictionary) -> bool:
	s.hi = Q.new(s.lo.n + rng.int_in(3, 9))
	var lo: float = s.lo.to_float()
	var hi: float = s.hi.to_float()
	var t := dec_turns(s, lo - 0.15, hi + 0.15)
	var inner := dec_turns(s, lo + 0.15, hi - 0.15)
	if t.tops.size() != 1 or t.lows.size() != 1 or inner.tops.size() != 1 or inner.lows.size() != 1:
		return false
	s.tops = t.tops
	s.lows = t.lows
	return Answer.rounds_clearly(t.tops[0], 0.03) and Answer.rounds_clearly(t.lows[0], 0.03) and absf(t.tops[0]) > 0.1 and absf(t.lows[0]) > 0.1


## Two zeros inside (0, hi), clear of the ends, of each other and of a rounding edge.
static func _dec_zeros(rng: Seeded, s: Dictionary) -> bool:
	s.lo = Q.new(0)
	var k: float = -s.d.to_float() / s.a.to_float()
	if absf(k) < 0.15 or absf(k) > 0.85:
		return false
	s.hi = Q.new(rng.int_in(3, 9))
	var hi: float = s.hi.to_float()
	var xs := dec_zeros(s, -0.15, hi + 0.15)
	if xs.size() != 2 or xs[0] < 0.15 or xs[1] > hi - 0.15 or xs[1] - xs[0] < 0.2:
		return false
	s.xs = xs.map(func(x): return GdcKit.qf(x))
	return xs.all(func(x): return Answer.rounds_clearly(x, 0.03))


## Every zero of the wave on (lo, hi), from where fn(bx) = −d/a, in order.
static func dec_zeros(s: Dictionary, lo: float, hi: float) -> Array:
	var b: float = s.b.to_float()
	var k: float = -s.d.to_float() / s.a.to_float()
	var base: Array
	if s.fn == "sin":
		var al := asin(k)
		base = [al, PI - al]
	else:
		var al := acos(k)
		base = [al, -al]
	var out: Array = []
	for k2 in range(-6, 12):
		for t in base:
			var x: float = (t + TAU * k2) / b
			if x > lo and x < hi:
				out.append(x)
	out.sort()
	return out


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
