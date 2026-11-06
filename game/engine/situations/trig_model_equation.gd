class_name TrigModelEquationSituation
extends RefCounted
## The `trig-model-equation` situation (curriculum/question-types.json), which extends `trig-wave`:
## one trig equation or inequality to solve for its times, or to count, for t3-trig-model-equation
## (SL3.8.graphical, FAL-752). There are four families, each with its own numbers:
##   exact   Paper 1. A fn(πt/k) + d in a story, with a level half way from the axis to the top or
##           the bottom, so fn(bracket) = ±1/2 and every time is exact.
##   story   Paper 2. The trig-wave model (TrigWaveSituation._model) and a level, over a window, a
##           part of a cycle or a span that isn't whole cycles.
##   wave    Either paper. y = a fn(bx) + d on an interval, for how many solutions f(x) = k has and
##           which k give how many. b is a kind, as in trig-wave: "x" (whole Paper 1 periods in π),
##           "pi" (πx/4, whole interval ends) or "dec" (1.3x on Paper 2, a whole end).
##   vs      Paper 2. A trig function against a line or a falling exponential: no algebra solves it.
##
## need.ask is the unknown (see TrigModelEquationViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx (an index into TrigModelViews.CONTEXTS), angle, spin (see Views.spun)
##   exact, story   the model's form, fn, A, C, d, a, top, low, period or bdec, T, B, tmax, tmin, and
##                  level, above, L, t_from, t_to, ratio
##   wave           kind, fn, a, d, bq, c, top, low, lo_x, hi_x (Qs, of π for kind "x"), k, big,
##                  which, n_sol, k_lo, k_hi, r1, r2
##   vs             vs ("line" or "exp"), fn, a, bq, m, e, origin, lo_x, hi_x

const TRIES := 2000
const EXACT_PERIODS := [6, 12, 24, 18, 30, 8, 10, 16, 20, 4]
const WHOLE_B := [[1, 1], [2, 1], [3, 1], [4, 1], [1, 2]]
const PI_B := [[1, 1], [1, 2], [1, 3], [1, 4], [1, 6], [2, 3]]
const DEC_B := [3, 4, 6, 7, 8, 9, 11, 12, 13, 14, 16, 17, 18, 19, 21, 22, 23, 24, 26, 27]
const NEG := 0.3


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "count-solutions")
	var rep: String = need.get("rep", "equation")
	var paper: int = int(need.get("paper", 2))
	var angle: String = need.get("angle", "any")
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "ctx": rng.int_in(0, TrigModelSituation.CONTEXTS - 1), "angle": angle, "fn": "cos", "spin": rng.int_in(0, 59)}
		var ok: bool
		if ask in TrigModelEquationViews.EXACT:
			ok = _exact_model(rng, s)
		elif ask in TrigModelEquationViews.STORY:
			ok = TrigWaveSituation._model(rng, s) and TrigWaveSituation._level(rng, s)
		elif ask in TrigModelEquationViews.WAVE:
			_x_wave(rng, s)
			ok = true
		else:
			ok = _vs(rng, s)
		if ok and new().call("_" + ask.replace("-", "_"), rng, s) and _clear(s):
			return s
	return {}


## Every 3 s.f. value the question turns on is clear of a rounding edge (`sfs` on the view).
static func _clear(s: Dictionary) -> bool:
	var out: Dictionary = TrigModelEquationViews.new().build_view(s.ask, s.rep, s.angle, s, null)
	var vals: Array = out.get("sfs", [])
	return vals.all(func(v): return absf(v) < 0.0005 or Answer.rounds_clearly(v, 0.03))


# ── Paper 1: exact times ─────────────────────────────────────

## A fn(πt/k) + d with level = d + A × (±1/2). A wheel's −A cos is one of them.
static func _exact_model(rng: Seeded, s: Dictionary) -> bool:
	s.form = rng.pick(["sin", "cos", "ncos"])
	s.fn = "sin" if s.form == "sin" else "cos"
	s.period = Q.new(rng.pick(EXACT_PERIODS))
	s.a = Q.new(rng.int_in(4, 40) * 2)
	if rng.chance(0.3):
		s.a = s.a.div(4)
	s.A = s.a.neg() if s.form == "ncos" else s.a
	s.d = s.a.add(rng.int_in(1, 24))
	s.C = Q.new(0)
	s.top = s.d.add(s.a)
	s.low = s.d.sub(s.a)
	s.T = s.period.to_float()
	s.B = TAU / s.T
	var ph := 0.25 if s.fn == "sin" else 0.0
	if s.A.sign() < 0:
		ph += 0.5
	s.tmax = TrigWaveSituation.after(ph * s.T, s.T)
	s.tmin = TrigWaveSituation.after((ph + 0.5) * s.T, s.T)
	s.ratio = Q.new(rng.pick([-1, 1]), 2)
	s.level = s.d.add(s.A.mul(s.ratio))
	return true


static func _exact_times_level(rng: Seeded, s: Dictionary) -> bool:
	s.L = s.period.mul(Q.new(rng.pick([1, 2, 3]))) if rng.chance(0.7) else s.period.mul(Q.new(3, 2))
	return s.L.is_int()


static func _time_at_least_exact(rng: Seeded, s: Dictionary) -> bool:
	s.above = rng.chance(0.6)
	return true


# ── Paper 2: a story and a level ─────────────────────────────

## Nothing sits at the ends of the span, where a crossing would be hard to place.
static func _clear_of_ends(xs: Array, from: float, to: float, T: float) -> bool:
	return xs.all(func(x): return absf(x - from) > 0.05 * T and absf(x - to) > 0.05 * T)


static func _times_in_window(rng: Seeded, s: Dictionary) -> bool:
	s.t_from = rng.int_in(1, maxi(2, ceili(s.T)))
	s.t_to = s.t_from + ceili(s.T * rng.pick([1.1, 1.4, 1.7, 2.1]))
	var all := TrigWaveViews.crossings(s, s.level.to_float(), s.t_to + s.T)
	var xs := all.filter(func(x): return x > s.t_from and x < s.t_to)
	return xs.size() >= 2 and xs.size() <= 4 and xs.size() < all.size() and _clear_of_ends(all, s.t_from, s.t_to, s.T)


## A span from 0 to L with `n` stretches past the level.
static func _span(rng: Seeded, s: Dictionary, n: int, whole_stretches: bool) -> bool:
	s.L = ceili(s.T * rng.pick([0.8, 1.1, 1.3, 1.6, 1.9, 2.3, 2.6]))
	if s.L < 3:
		return false
	var k: float = s.level.to_float()
	var xs := TrigWaveViews.crossings(s, k, s.L)
	var ps := TrigModelEquationViews.pieces(s, k, s.L, s.above)
	if ps.size() != n or xs.size() < 2 or not _clear_of_ends(xs, 0.0, s.L, s.T):
		return false
	return not whole_stretches or ps.all(func(p): return p[0] > 0.0 and p[1] < s.L)


static func _set_above_level(rng: Seeded, s: Dictionary) -> bool:
	s.above = true
	return _span(rng, s, 1, true)


static func _set_below_level(rng: Seeded, s: Dictionary) -> bool:
	s.above = false
	return _span(rng, s, 1, true)


static func _set_two_spans(rng: Seeded, s: Dictionary) -> bool:
	s.above = rng.chance(0.5)
	return _span(rng, s, 2, false)


## A span that isn't whole cycles, so the share of one cycle isn't the answer.
static func _part_span(rng: Seeded, s: Dictionary) -> bool:
	s.L = ceili(s.T * rng.pick([1.3, 1.6, 2.3, 2.6, 3.4, 3.7]))
	var f: float = s.L / s.T
	if absf(f - roundf(f)) < 0.15:
		return false
	var k: float = s.level.to_float()
	return _clear_of_ends(TrigWaveViews.crossings(s, k, s.L), 0.0, s.L, s.T)


static func _chance_above(rng: Seeded, s: Dictionary) -> bool:
	s.above = true
	return _part_span(rng, s)


static func _time_past_level(rng: Seeded, s: Dictionary) -> bool:
	s.above = rng.chance(0.6)
	return _part_span(rng, s)


# ── A wave on an interval ────────────────────────────────────

static func _x_wave(rng: Seeded, s: Dictionary) -> void:
	s.fn = rng.pick(["sin", "cos"])
	s.c = Q.new(0)
	var exact_ends: bool = s.ask in TrigModelEquationViews.EXACT_ENDS
	s.kind = rng.pick(["x", "pi"]) if s.paper == 1 or exact_ends else rng.pick(["x", "pi", "dec"])
	if s.paper == 1:
		s.a = Q.new(rng.int_in(1, 6))
		s.d = Q.new(ExtensionViews.nonzero(rng, -6, 9))
	else:
		s.a = Q.new(rng.int_in(12, 95), 10)
		s.d = Q.new(ExtensionViews.nonzero(rng, -60, 90), 10)
	if rng.chance(NEG):
		s.a = s.a.neg()
	match s.kind:
		"x":
			var p: Array = rng.pick(WHOLE_B)
			s.bq = Q.new(p[0], p[1])
		"pi":
			var p: Array = rng.pick(PI_B)
			s.bq = Q.new(p[0], p[1])
		"dec":
			s.bq = Q.new(rng.pick(DEC_B), 10)
	s.top = s.d.add(s.a.abs_q())
	s.low = s.d.sub(s.a.abs_q())
	s.lo_x = Q.new(0)
	s.hi_x = TrigWaveViews.per(s)


## The interval: m quarters of a period along, a whole end for kind "dec".
static func _ends(rng: Seeded, s: Dictionary, m: int, below_zero: int = 0) -> bool:
	if s.kind == "dec":
		s.hi_x = Q.new(ceili(TrigWaveViews.per(s).to_float() * m / 4.0))
		return true
	var quarter: Q = TrigWaveViews.per(s).div(4)
	s.hi_x = quarter.mul(m)
	s.lo_x = quarter.mul(-below_zero)
	return s.kind == "x" or (s.hi_x.is_int() and s.lo_x.is_int())


## A level well inside the range, on a half, at neither end's height.
static func _inside_level(rng: Seeded, s: Dictionary) -> bool:
	var f: float = rng.pick([-0.8, -0.6, -0.4, -0.2, 0.2, 0.4, 0.6, 0.8])
	s.k = Q.new(roundi(2.0 * (s.d.to_float() + s.a.abs_q().to_float() * f)), 2)
	var k: float = s.k.to_float()
	if not (s.low.to_float() < k - 0.01 and k + 0.01 < s.top.to_float()):
		return false
	return absf(k - s.d.to_float()) > 0.01 and _off_ends(s, k)


static func _off_ends(s: Dictionary, k: float) -> bool:
	var ns := TrigModelEquationViews.nodes(s)
	return absf(ns[0][1] - k) > 0.02 and absf(ns[ns.size() - 1][1] - k) > 0.02


static func _count_solutions(rng: Seeded, s: Dictionary) -> bool:
	var under: int = rng.pick([1, 2, 3, 4]) if rng.chance(0.3) else 0
	if not _ends(rng, s, rng.int_in(5, 13), under) or not _inside_level(rng, s):
		return false
	return TrigModelEquationViews.count_k(s, s.k.to_float()) >= 3


static func _count_at_extreme(rng: Seeded, s: Dictionary) -> bool:
	if not _ends(rng, s, rng.int_in(5, 15)):
		return false
	s.big = rng.chance(0.5)
	s.k = s.top if s.big else s.low
	return _off_ends(s, s.k.to_float()) and TrigModelEquationViews.count_k(s, s.k.to_float()) >= 2


## What y = k does as k rises through the heights the wave's ends and turning points are at, then
## a band of k with one count of solutions, closed where the count holds at its end.
static func _k_exactly_n(rng: Seeded, s: Dictionary) -> bool:
	if not _ends(rng, s, rng.int_in(2, 9)):
		return false
	var bs := TrigModelEquationViews.bands(s)
	if bs.is_empty():
		return false
	var counts: Array = []
	for b in bs:
		if b.n >= 2 and not counts.has(b.n):
			counts.append(b.n)
	var options := counts.filter(func(n): return _band(bs, n).size() > 0)
	if options.is_empty():
		return false
	s.n_sol = rng.pick(options)
	var b := _band(bs, s.n_sol)
	s.k_lo = b.lo
	s.k_hi = b.hi
	s.r1 = b.r1
	s.r2 = b.r2
	return not (b.lo.eq(s.low) and b.hi.eq(s.top) and b.r1 == "≤" and b.r2 == "≤")


## The one unbroken band of k with count n, with some width: {} if there is no such band.
static func _band(bs: Array, n: int) -> Dictionary:
	var at: Array = []
	for i in bs.size():
		if bs[i].n == n:
			at.append(i)
	if at.is_empty() or at[at.size() - 1] - at[0] != at.size() - 1:
		return {}
	var first: Dictionary = bs[at[0]]
	var last: Dictionary = bs[at[at.size() - 1]]
	if first.lo.eq(last.hi):
		return {}
	return {"lo": first.lo, "hi": last.hi, "r1": "≤" if first.lo.eq(first.hi) else "<", "r2": "≤" if last.lo.eq(last.hi) else "<"}


static func _full_cycle(rng: Seeded, s: Dictionary) -> bool:
	return _ends(rng, s, rng.int_in(5, 12))


static func _k_any_solution(rng: Seeded, s: Dictionary) -> bool:
	return _full_cycle(rng, s)


static func _k_no_solution(rng: Seeded, s: Dictionary) -> bool:
	return _full_cycle(rng, s)


## The line y = k touches the wave's peaks or troughs, and one letter of the wave is unknown.
static func _touch_find_constant(rng: Seeded, s: Dictionary) -> bool:
	s.big = rng.chance(0.5)
	s.which = rng.pick(["d", "a"])
	s.k = s.top if s.big else s.low
	if s.which == "a":
		s.a = s.a.abs_q()
	return _ends(rng, s, 8) and not s.k.is_zero()


## One cycle from the axis to the axis: k = top and k = low are the only single solutions.
static func _touch_one_solution(_rng: Seeded, s: Dictionary) -> bool:
	var quarter: Q = TrigWaveViews.per(s).div(4)
	if s.fn == "cos":
		s.lo_x = quarter
		s.hi_x = quarter.mul(5)
	else:
		s.lo_x = Q.new(0)
		s.hi_x = quarter.mul(4)
	return s.kind == "x" or (s.hi_x.is_int() and s.lo_x.is_int())


# ── A trig curve and another curve ───────────────────────────

const LINE_A := [[1, 1], [3, 2], [2, 1], [5, 2], [3, 1], [4, 1]]
const LINE_M := [10, 15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80]
const EXP_A := [[3, 5], [4, 5], [1, 1], [3, 2], [2, 1], [5, 2], [3, 1]]
const EXP_K := [[1, 5], [3, 10], [2, 5], [1, 2], [3, 5], [4, 5], [1, 1], [3, 2]]


static func _vs(rng: Seeded, s: Dictionary) -> bool:
	s.kind = "x"
	s.c = Q.new(0)
	s.d = Q.new(0)
	s.bq = Q.new(rng.pick([1, 1, 2]))
	return true


static func _line_setup(rng: Seeded, s: Dictionary) -> void:
	s.vs = "line"
	var p: Array = rng.pick(LINE_A)
	s.a = Q.new(p[0], p[1])
	s.m = Q.new(rng.pick(LINE_M), 100)
	s.fn = rng.pick(["sin", "sin", "cos"])
	s.origin = s.fn == "sin"


static func _solve_vs_line(rng: Seeded, s: Dictionary) -> bool:
	_line_setup(rng, s)
	# The map's own example stays the map's.
	if s.a.eq(1) and s.bq.eq(1) and s.m.eq(Q.new(3, 10)):
		return false
	s.hi_x = Q.new(rng.pick([1, 2, 3]))
	s.lo_x = s.hi_x.neg()
	var xs := TrigModelEquationViews.vs_roots(s)
	var need := 3 if s.origin else 2
	return xs.size() >= need and xs.size() <= 7 and TrigModelEquationViews.vs_clean(s, xs)


static func _solve_vs_exp(rng: Seeded, s: Dictionary) -> bool:
	s.vs = "exp"
	s.fn = rng.pick(["sin", "cos", "cos"])
	s.origin = false
	var p: Array = rng.pick(EXP_A)
	s.a = Q.new(p[0], p[1])
	var e: Array = rng.pick(EXP_K)
	s.e = Q.new(e[0], e[1])
	s.lo_x = Q.new(0)
	s.hi_x = Q.new(rng.pick([2, 2, 3, 4]))
	if s.a.eq(2) and s.e.eq(1) and s.bq.eq(1) and s.fn == "cos":
		return false
	var xs := TrigModelEquationViews.vs_roots(s)
	return xs.size() >= 2 and xs.size() <= 6 and TrigModelEquationViews.vs_clean(s, xs)


static func _count_vs_line(rng: Seeded, s: Dictionary) -> bool:
	_line_setup(rng, s)
	s.m = s.m.div(rng.pick([1, 2, 4]))
	s.hi_x = Q.new(rng.pick([2, 3, 4, 5, 6]))
	s.lo_x = s.hi_x.neg() if rng.chance(0.5) else Q.new(0)
	if s.a.eq(1) and s.bq.eq(1) and s.m.eq(Q.new(3, 10)):
		return false
	var xs := TrigModelEquationViews.vs_roots(s)
	return xs.size() >= 3 and xs.size() <= 16 and TrigModelEquationViews.vs_clean(s, xs)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
