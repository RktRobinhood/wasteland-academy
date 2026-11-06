class_name TrigWaveSituation
extends RefCounted
## The `trig-wave` situation (curriculum/question-types.json), which extends `trig-model`: one wave
## whose letters are known, to read or to use, for t3-trig-read-features and t3-trig-model-use
## (FAL-751). A figure and a Paper 2 story keep the base's _wave() and its graph. On top of that:
##   reading   y = a fn(bx) + d, or a fn(b(x − c)) + d for a first maximum, for sin, cos and tan,
##             with a negative a in three of ten. b is a `kind`: "x" (3x, x/2, whole Paper 1 periods
##             in π), "pi" (4πx, πx/6, a rational period) or "dec" (1.3x on Paper 2, the period to
##             3 s.f.). A base wave reads as kind "x" on Paper 1 and "plain" (a whole period) on
##             Paper 2. Every position is a Q: of π for "x", and a number for the others, a float
##             turned into a Q for "dec".
##   using     a story model A fn(B(t − C)) + d, in the forms the bank writes: A cos at a peak, A sin
##             a quarter of a period earlier, −A cos at a trough, or a decimal B. Paper 1 is
##             A fn(πt/k) + d at a whole t, exact with TrigKit.
##
## need.ask is the unknown (see TrigWaveViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx (an index into TrigModelViews.CONTEXTS), angle
##   reading: kind, fn, a, d, bq (b, of π for "pi"), c, top, low and, on a figure, the base's wave
##   using:   form, fn, A, C, d, a (A's size), top, low, period or bdec, T, B (floats), tmax, tmin
##            (the first times after 0) and what each unknown adds: level, t0, L, reach, which, up

const TRIES := 2000
const WHOLE_B := [[1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [1, 2], [1, 3], [1, 4], [2, 3], [3, 2]]
const PI_B := [[1, 1], [2, 1], [3, 1], [4, 1], [1, 2], [1, 3], [1, 4], [1, 6], [2, 3], [3, 4]]
const SHIFT_B := [2, 3, 4]
const LANDMARK := [[1, 6], [1, 4], [1, 3], [1, 2]]
## Asks that read as well with no vertical shift, as the bank's 6 cos(πx) does.
const NO_D := ["amplitude", "period", "amp-period", "tan-period", "first-max-x"]
const TAN := ["tan-period", "tan-features"]
const P1_PERIODS := [4, 6, 8, 12]
## The time unit up from a story's own, for a count over a longer span.
const UP := {"hours": ["days", 24], "minutes": ["hours", 60], "days": ["weeks", 7]}


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "amplitude")
	var rep: String = need.get("rep", "equation")
	var paper: int = int(need.get("paper", 2))
	var angle: String = need.get("angle", "any")
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "ctx": rng.int_in(0, TrigModelSituation.CONTEXTS - 1), "angle": angle, "fn": "cos"}
		var ok: bool
		if ask in TrigWaveViews.MU_UNKNOWNS:
			ok = _model(rng, s)
		else:
			ok = _reading(rng, s)
		if ok and new().call("_" + ask.replace("-", "_"), rng, s) and _clear(s):
			return s
	return {}


## Every 3 s.f. value offered is clear of a rounding edge.
static func _clear(s: Dictionary) -> bool:
	var out: Dictionary = TrigWaveViews.new().build_view(s.ask, s.rep, s.angle, s, null)
	if out.answer.get("show", "") != "sf":
		return true
	var vals: Array = out.answer.values.values().filter(func(v): return v is Q)
	return vals.all(func(v): return absf(v.to_float()) < 0.0005 or Answer.rounds_clearly(v.to_float(), 0.03))


# ── A wave to read ───────────────────────────────────────────

static func _reading(rng: Seeded, s: Dictionary) -> bool:
	s.c = Q.new(0)
	if s.ask == "wheel-a-b":
		return TrigModelSituation._wheel_model(rng, s)
	if s.rep == "words" or (s.rep == "graph" and not s.ask in TAN and s.ask != "intercept-gap"):
		TrigModelSituation._wave(rng, s)
		if s.paper == 1:
			s.kind = "x"
			s.bq = Q.new(s.w)
		else:
			s.kind = "plain"
		return s.d.sign() != 0 or s.ask in NO_D
	_equation_wave(rng, s)
	return true


static func _equation_wave(rng: Seeded, s: Dictionary) -> void:
	s.fn = "tan" if s.ask in TAN else rng.pick(["sin", "cos"])
	if s.angle == "gdc-graph":
		s.kind = "dec"
	elif s.paper == 1:
		s.kind = rng.pick(["x", "pi"])
	else:
		# A tan figure with no equation shows its period on a mark, so that has to end.
		s.kind = "pi" if s.rep == "graph" else rng.pick(["pi", "dec"])
	var neg := rng.chance(0.3)
	if s.paper == 1:
		s.a = Q.new(rng.int_in(1, 6))
		s.d = Q.new(ExtensionViews.nonzero(rng, -6, 9))
	else:
		s.a = Q.new(rng.int_in(12, 95), 10)
		s.d = Q.new(ExtensionViews.nonzero(rng, -60, 90), 10)
	if neg:
		s.a = s.a.neg()
	if s.ask in NO_D and rng.chance(0.3):
		s.d = Q.new(0)
	var shifted: bool = s.ask == "first-max-x" and rng.chance(0.6)
	match s.kind:
		"x":
			var p: Array = rng.pick(WHOLE_B)
			s.bq = Q.new(rng.pick(SHIFT_B)) if shifted else Q.new(p[0], p[1])
			if shifted:
				var l: Array = rng.pick(LANDMARK)
				s.c = Q.new(l[0], l[1])
		"pi":
			var p: Array = rng.pick(PI_B)
			s.bq = Q.new(rng.int_in(1, 4)) if shifted else Q.new(p[0], p[1])
			if shifted:
				s.c = Q.new(rng.pick([1, 3, 5]), rng.pick([1, 2, 4]))
		"dec":
			s.bq = Q.new(rng.pick([3, 4, 6, 7, 8, 9, 11, 12, 13, 14, 16, 17, 18, 19, 21, 22, 23, 24, 26, 27]), 10)
			if shifted:
				s.c = Q.new(rng.int_in(2, 30), 10)
	s.top = s.d.add(s.a.abs_q())
	s.low = s.d.sub(s.a.abs_q())


static func _amplitude(_rng: Seeded, _s: Dictionary) -> bool:
	return true


static func _period(_rng: Seeded, _s: Dictionary) -> bool:
	return true


static func _amp_period(_rng: Seeded, _s: Dictionary) -> bool:
	return true


static func _principal_axis(_rng: Seeded, s: Dictionary) -> bool:
	return s.d.sign() != 0


static func _max_value(_rng: Seeded, _s: Dictionary) -> bool:
	return true


static func _min_value(_rng: Seeded, _s: Dictionary) -> bool:
	return true


static func _range(_rng: Seeded, _s: Dictionary) -> bool:
	return true


static func _first_max_x(_rng: Seeded, _s: Dictionary) -> bool:
	return true


static func _tan_period(_rng: Seeded, _s: Dictionary) -> bool:
	return true


static func _tan_features(_rng: Seeded, _s: Dictionary) -> bool:
	return true


static func _b_from_graph(_rng: Seeded, _s: Dictionary) -> bool:
	return true


static func _a_d_from_graph(_rng: Seeded, s: Dictionary) -> bool:
	return s.d.sign() != 0


## sin(qx) crosses the axis at x = 0, n r and 2n r.
static func _intercept_gap(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.int_in(1, 4)
	s.fn = "sin"
	return true


static func _b_from_story(rng: Seeded, s: Dictionary) -> bool:
	s.period = Q.new(rng.pick([4, 6, 8, 10, 12, 16, 20, 24]))
	return true


static func _amp_axis_story(_rng: Seeded, s: Dictionary) -> bool:
	return s.low.sign() > 0


static func _wheel_a_b(_rng: Seeded, _s: Dictionary) -> bool:
	return true


# ── A model to use ───────────────────────────────────────────

## The smallest t + nT after 0.
static func after(t: float, T: float) -> float:
	var x := t
	while x <= 1e-9:
		x += T
	while x - T > 1e-9:
		x -= T
	return x


static func _model(rng: Seeded, s: Dictionary) -> bool:
	if s.paper == 1:
		s.form = rng.pick(["sin", "cos"])
		s.fn = s.form
		s.period = Q.new(rng.pick(P1_PERIODS))
		s.a = Q.new(rng.int_in(3, 12), 2)
		s.d = Q.new(rng.int_in(8, 30))
		s.A = s.a
		s.C = Q.new(0)
		s.top = s.d.add(s.a)
		s.low = s.d.sub(s.a)
	else:
		TrigModelSituation._wave(rng, s)
		s.form = rng.pick(["cos", "sin", "ncos", "dec"])
		if s.ask == "high-low-gap":
			s.form = "dec"
		elif s.ask == "first-max-time":
			s.form = rng.pick(["sin", "ncos"])
		elif s.ask == "duration-span":
			s.form = rng.pick(["cos", "sin", "ncos"])
		match s.form:
			"cos":
				s.fn = "cos"
				s.A = s.a
				s.C = s.xmax
			"sin":
				s.fn = "sin"
				s.A = s.a
				s.C = s.xmax.sub(s.period.div(4))
				if s.C.sign() < 0:
					return false
			"ncos":
				s.fn = "cos"
				s.A = s.a.neg()
				s.C = s.xmin if rng.chance(0.7) else Q.new(0)
			"dec":
				s.fn = rng.pick(["sin", "cos"])
				s.A = s.a.neg() if rng.chance(0.3) else s.a
				s.C = Q.new(rng.int_in(1, 9))
				s.bdec = Q.new(rng.pick([3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15]), 10)
				s.erase("period")
				s.erase("xmax")
				s.erase("xmin")
	s.T = float(TAU / s.bdec.to_float()) if s.has("bdec") else s.period.to_float()
	s.B = TAU / s.T
	# The phase of the first top and bottom, in cycles from C.
	var ph := 0.25 if s.fn == "sin" else 0.0
	if s.A.sign() < 0:
		ph += 0.5
	s.tmax = after(s.C.to_float() + ph * s.T, s.T)
	s.tmin = after(s.C.to_float() + (ph + 0.5) * s.T, s.T)
	return true


## A level well inside the range, on a half.
static func _level(rng: Seeded, s: Dictionary) -> bool:
	var r: float = rng.pick([-0.7, -0.6, -0.5, -0.4, -0.3, 0.3, 0.4, 0.5, 0.6, 0.7])
	s.level = Q.new(roundi(2.0 * (s.d.to_float() + s.a.to_float() * r)), 2)
	var f: float = absf(s.level.sub(s.d).to_float()) / s.a.to_float()
	return f > 0.15 and f < 0.85


static func _value_at_time(rng: Seeded, s: Dictionary) -> bool:
	s.t0 = rng.int_in(1, ceili(2.0 * s.T))
	return s.t0 != int(s.C.to_float())


## At a whole t past the first quadrant and off the axes, so the value's sign has to be worked out.
static func _exact_value(rng: Seeded, s: Dictionary) -> bool:
	s.t0 = rng.int_in(1, s.period.n - 1)
	var t: Q = Q.new(2).div(s.period).mul(s.t0)
	return Q.new(1, 2).lt(t) and not t.mul(2).is_int()


static func _first_time_level(rng: Seeded, s: Dictionary) -> bool:
	return _level(rng, s) and _not_on_crossing(s, 0.0)


static func _all_times(rng: Seeded, s: Dictionary) -> bool:
	if not _level(rng, s):
		return false
	s.L = ceili(s.T * rng.pick([1.25, 1.5, 1.75, 2.0]))
	var xs := TrigWaveViews.crossings(s, s.level.to_float(), s.L)
	return xs.size() >= 2 and xs.size() <= 4 and _not_on_crossing(s, s.L)


## No crossing sits at 0 or at the end of the interval.
static func _not_on_crossing(s: Dictionary, end: float) -> bool:
	var xs := TrigWaveViews.crossings(s, s.level.to_float(), 3.0 * s.T)
	return xs.all(func(x): return absf(x - end) > 0.05 * s.T and x > 0.03 * s.T)


static func _duration_above(rng: Seeded, s: Dictionary) -> bool:
	return _level(rng, s)


static func _duration_below(rng: Seeded, s: Dictionary) -> bool:
	return _level(rng, s)


static func _duration_span(rng: Seeded, s: Dictionary) -> bool:
	s.cycles = rng.int_in(2, 4)
	s.L = s.cycles * s.period.n
	return _level(rng, s)


static func _first_max_time(_rng: Seeded, s: Dictionary) -> bool:
	return absf(s.tmax - s.C.to_float()) > 0.01


static func _high_low_gap(_rng: Seeded, _s: Dictionary) -> bool:
	return true


## No peak sits on the end of the span, and dividing the span by T isn't always the answer.
static func _count_clear(from: float, span: float, T: float) -> bool:
	var f := (span - from) / T
	return absf(f - roundf(f)) > 0.08


static func _count_peaks(rng: Seeded, s: Dictionary) -> bool:
	s.L = ceili(s.T * rng.pick([3.3, 4.4, 5.6, 6.7, 7.8]))
	return _count_clear(s.tmax, s.L, s.T)


static func _count_lows(rng: Seeded, s: Dictionary) -> bool:
	var up: Array = UP[TrigModelViews.CONTEXTS[s.ctx].time]
	s.up = rng.int_in(1, 3)
	s.L = s.up * int(up[1])
	var n := floori((s.L - s.tmin) / s.T) + 1
	return n >= 2 and n <= 40 and _count_clear(s.tmin, s.L, s.T)


static func _interpret_extreme(rng: Seeded, s: Dictionary) -> bool:
	s.which = rng.pick(["max", "min"])
	return true


## A level near the top: half of the time it is out of reach.
static func _reaches_level(rng: Seeded, s: Dictionary) -> bool:
	s.reach = rng.chance(0.5)
	var f: float = rng.pick([0.2, 0.3, 0.4, 0.6])
	s.level = Q.new(roundi(2.0 * (s.top.to_float() + (-f if s.reach else f) * s.a.to_float())), 2)
	return not s.level.eq(s.top) and s.level.lt(s.top) == s.reach and s.d.lt(s.level)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
