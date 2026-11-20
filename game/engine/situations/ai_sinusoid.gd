class_name AiSinusoidSituation
extends RefCounted
## The `ai-sinusoid` situation (curriculum/question-types.json), FAL-1001: one sinusoidal model
## h(t) = a sin(bt) + d or a cos(bt) + d with bt in degrees, for fn-ai-sinusoidal-model
## (AI-SL2.5.sinusoidal-model). Every AI paper allows a GDC, so every question is Paper 2.
##
## A model is picked from its story: the amplitude |a| (a radius, a blade, half the tide's
## range), the principal axis d (the hub, the mean level), a whole-number period T and where it
## starts at t = 0 (start): "max" a cos(bt) + d, a > 0; "min" the same with a < 0 (a seat that
## boards at the bottom); "up" a sin(bt) + d, a > 0; "down" the same with a < 0. b = 360/T.
##
## need.ask is the unknown and need.rep its representation (see AiSinusoidViews). generate()
## returns a Dictionary:
##   paper, ask, rep, ctx     always 2; the unknown; the representation; the story (CONTEXTS)
##   start, fn, a, A, d, T, b the model: a signed and A = |a| (Q), d (Q), T (int), b = 360/T (Q)
##   wk                       how the words give the facts ("centre", "extremes", "radius",
##                            "other", "period", "gap"), where the unknown has a choice
##   which                    max-min: "greatest" or "least"
##   pick                     build-model in words: asked as pick the graph
##   t0                       value-at-time: the time (Q); first-time-level: the start time
##   L, above                 a level (Q) and whether the time above it is asked
##   total, span              count-cycles: the time in the model's units (int), and in words
##                            the span in the bigger unit (int)
##   change, T2, M2           changed-period-or-axis: "period" (the new period T2) or "axis"
##                            (the new greatest value M2, Q)
##   m2                       two-models-equal: the second model {start, fn, a, A, d, T, b}
##
## The numbers are drawn, not taken from any exam question. The SymPy checker
## (tools/check_answers.py, r3si_check) reads every value back from what the question shows and
## works it out again.

const TRIES := 3000
## A 3 s.f. answer is at least this far (a fraction of its last place) from a rounding edge.
const EDGE := 0.04

## Each story: what it measures, its letter and units, its periods (each gives b to at most
## one decimal place), other whole periods for b to 3 s.f., and its sizes in halves.
const CONTEXTS := [
	{"kind": "wheel", "thing": "the height of a seat on the salvage-yard wheel", "what": "height", "sym": "h", "unit": "m",
		"time": "minutes", "periods": [10, 12, 15, 16, 18, 20, 24, 30, 36, 40], "odd": [7, 11, 13, 14, 22, 26, 28],
		"amp": [8, 60], "lift": [2, 16], "big": ["hours", 60], "starts": ["min", "min", "min", "max", "up"]},
	{"kind": "tide", "thing": "the depth of water at the old harbour wall", "what": "depth", "sym": "D", "unit": "m",
		"time": "hours", "periods": [12, 15, 16, 18, 20, 24], "odd": [13, 14, 22, 25, 26],
		"amp": [3, 10], "lift": [4, 20], "big": ["days", 24], "starts": ["max", "min", "up", "down"]},
	{"kind": "temp", "thing": "the temperature inside the grain store", "what": "temperature", "sym": "T", "unit": "°C",
		"time": "hours", "periods": [12, 16, 18, 20, 24], "odd": [14, 22, 26, 28],
		"amp": [4, 18], "lift": [6, 40], "big": ["days", 24], "starts": ["max", "min", "up", "down"]},
	{"kind": "blade", "thing": "the height of the tip of a wind-turbine blade", "what": "height", "sym": "h", "unit": "m",
		"time": "seconds", "periods": [4, 5, 6, 8, 9, 10, 12], "odd": [7, 11, 13, 14],
		"amp": [20, 70], "lift": [10, 50], "big": ["minutes", 60], "starts": ["up", "max", "min", "down"]},
	{"kind": "buoy", "thing": "the height of a marker buoy above the seabed", "what": "height", "sym": "H", "unit": "m",
		"time": "seconds", "periods": [5, 6, 8, 9, 10, 12, 15], "odd": [7, 11, 13, 14],
		"amp": [3, 8], "lift": [8, 30], "big": ["minutes", 60], "starts": ["up", "down", "max", "min"]},
]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "amplitude")
	var rep: String = need.get("rep", "equation")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "rep": rep, "ctx": rng.int_in(0, CONTEXTS.size() - 1)}
		if _draw(rng, s):
			return s
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"amplitude":
			return _amplitude(rng, s)
		"period":
			return _period(rng, s)
		"b-from-period":
			return _b_from_period(rng, s)
		"principal-axis":
			return _principal_axis(rng, s)
		"max-min":
			return _max_min(rng, s)
		"build-model":
			return _build_model(rng, s)
		"value-at-time":
			return _value_at_time(rng, s)
		"first-time-level":
			return _first_time_level(rng, s)
		"time-above-level":
			return _time_above(rng, s)
		"count-cycles":
			return _count_cycles(rng, s)
		"changed-period-or-axis":
			return _changed(rng, s)
		"two-models-equal":
			return _two_models(rng, s)
	return false


# ── Small tools ──────────────────────────────────────────────

static func ctx(s: Dictionary) -> Dictionary:
	return CONTEXTS[s.ctx]


static func clear(x: float) -> bool:
	return Answer.rounds_clearly(x, EDGE)


## Every value is clear of a 3 s.f. edge and no two read the same.
static func distinct(xs: Array) -> bool:
	var seen := {}
	for x in xs:
		if not is_finite(x) or not clear(x):
			return false
		seen[Fmt.sf(x)] = true
	return seen.size() == xs.size()


## Exact values that are all different.
static func distinct_q(qs: Array) -> bool:
	var seen := {}
	for q in qs:
		seen[Q.of(q).key()] = true
	return seen.size() == qs.size()


## A value as it is when it ends, else to 3 s.f. (as a Q).
static func ends_or_sf(v: Q) -> Q:
	return v if not Fmt.dec(v).contains("/") else GraphReadingSituation.sf_q(v, 3)


static func ends(v: Q) -> bool:
	return not Fmt.dec(v).contains("/")


# ── The model ────────────────────────────────────────────────

## A model {start, fn, a, A, d, T, b} for the story, its period from `periods`.
static func model(rng: Seeded, c: Dictionary, periods: Array, start: String = "") -> Dictionary:
	var m := {}
	m.start = start if start != "" else rng.pick(c.starts)
	m.fn = "cos" if m.start in ["max", "min"] else "sin"
	m.A = Q.new(rng.int_in(c.amp[0], c.amp[1]), 2)
	m.a = m.A.neg() if m.start in ["min", "down"] else m.A
	m.d = m.A.add(Q.new(rng.int_in(c.lift[0], c.lift[1]), 2))
	m.T = int(rng.pick(periods))
	m.b = Q.new(360, m.T)
	return m


static func set_model(s: Dictionary, m: Dictionary) -> void:
	for k in m:
		s[k] = m[k]


static func draw(rng: Seeded, s: Dictionary, periods: Array = [], start: String = "") -> void:
	var c := ctx(s)
	set_model(s, model(rng, c, periods if not periods.is_empty() else c.periods, start))


## The model's value at t, with bt in degrees (or, for the radian-mode slip, in radians).
static func val(m: Dictionary, t: float, rad: bool = false) -> float:
	var u: float = m.b.to_float() * t
	if not rad:
		u = deg_to_rad(u)
	return m.a.to_float() * (sin(u) if m.fn == "sin" else cos(u)) + m.d.to_float()


## The same model with the other function: the sin/cos swap a filler shows.
static func swapped(m: Dictionary, t: float) -> float:
	var u: float = deg_to_rad(m.b.to_float() * t)
	return m.a.to_float() * (cos(u) if m.fn == "sin" else sin(u)) + m.d.to_float()


static func top(m: Dictionary) -> Q:
	return m.d.add(m.A)


static func low(m: Dictionary) -> Q:
	return m.d.sub(m.A)


## The first maximum at or after t = 0, and the minimum after it.
static func t_max(m: Dictionary) -> Q:
	var T := Q.new(m.T)
	match m.start:
		"min":
			return T.div(2)
		"up":
			return T.div(4)
		"down":
			return T.mul(3).div(4)
	return Q.new(0)


static func t_min(m: Dictionary) -> Q:
	return t_max(m).add(Q.new(m.T, 2))


## Every t in (lo, hi] where f crosses 0, in order, stepping by `step`.
static func roots(f: Callable, lo: float, hi: float, step: float) -> Array:
	var out: Array = []
	var xa := lo
	var fa: float = f.call(lo)
	while xa < hi - 1e-12:
		var xb := minf(xa + step, hi)
		var fb: float = f.call(xb)
		if fb == 0.0:
			out.append(xb)
		elif fa != 0.0 and signf(fa) != signf(fb):
			var r := Brent.root(f, xa, xb, 1e-13, 1e-15)
			if r.ok:
				out.append(r.x)
		xa = xb
		fa = fb
	return out


## The times after t0 (strictly) when the model is at the level L, up to t0 + span.
static func level_times(m: Dictionary, L: float, t0: float, span: float, rad: bool = false) -> Array:
	var per: float = m.T if not rad else TAU / m.b.to_float()
	var f := func(t: float) -> float: return val(m, t, rad) - L
	return roots(f, t0, t0 + span, per / 64.0)


## A level strictly between the least and greatest values, to 1 d.p., clear of the axis and
## the extremes.
static func level(rng: Seeded, m: Dictionary) -> Q:
	var r := float(rng.int_in(2, 8)) / 10.0 * (1.0 if rng.chance(0.5) else -1.0)
	var L := GraphReadingSituation.dp_q(GdcKit.qf(m.d.to_float() + m.A.to_float() * r), 1)
	return L


static func level_ok(m: Dictionary, L: Q) -> bool:
	var A: float = m.A.to_float()
	var off: float = absf(L.to_float() - m.d.to_float())
	return off >= 0.15 * A and off <= 0.85 * A


# ── Reading the parameters ───────────────────────────────────

static func _amplitude(rng: Seeded, s: Dictionary) -> bool:
	draw(rng, s)
	s.wk = rng.pick(["centre", "extremes"])
	return distinct_q([s.A, top(s), s.A.mul(2), s.d, low(s)])


static func _principal_axis(rng: Seeded, s: Dictionary) -> bool:
	draw(rng, s)
	s.wk = rng.pick(["centre", "extremes"])
	return distinct_q([s.d, s.A, top(s), low(s), s.A.mul(2)])


static func _max_min(rng: Seeded, s: Dictionary) -> bool:
	draw(rng, s)
	s.which = rng.pick(["greatest", "least"])
	s.wk = rng.pick(["radius", "other"])
	return distinct_q([top(s), low(s), s.d, s.A, s.d.add(s.A.mul(2))])


## [T, b as the period, the max-to-min time as the period].
static func period_slips(s: Dictionary) -> Array:
	return [Q.new(s.T), s.b, Q.new(s.T, 2)]


static func _period(rng: Seeded, s: Dictionary) -> bool:
	draw(rng, s)
	var v := period_slips(s)
	return distinct_q(v + [Q.new(2 * s.T), t_min(s)])


## [b, T/360 (upside down), 360/(T/2) (the half-period as the period)].
static func b_slips(T: int) -> Array:
	return [Q.new(360, T), Q.new(T, 360), Q.new(720, T)]


static func _b_from_period(rng: Seeded, s: Dictionary) -> bool:
	var c := ctx(s)
	s.wk = "gap" if s.rep == "graph" else rng.pick(["period", "gap"])
	draw(rng, s, c.periods + c.odd if s.wk == "period" and s.rep == "words" else c.periods)
	return clean_bs(b_slips(s.T) + [Q.new(180, s.T), Q.new(s.T)])


## The key and the two slips first: each that needs rounding is clear of an edge, and no two
## of the values read the same as they are shown.
static func clean_bs(raw: Array) -> bool:
	for i in 3:
		if not ends(raw[i]) and not clear(raw[i].to_float()):
			return false
	var seen := {}
	for q in raw:
		seen[Fmt.dec(ends_or_sf(q))] = true
	return seen.size() == raw.size()


static func _build_model(rng: Seeded, s: Dictionary) -> bool:
	var c := ctx(s)
	var periods: Array = c.periods.filter(func(T): return 3600 % int(T) == 0)
	draw(rng, s, periods, rng.pick(["max", "min", "min", "up"]))
	s.wk = "gap" if s.rep == "graph" else rng.pick(["period", "gap"])
	s.pick = s.rep == "words" and rng.chance(0.35)
	return distinct_q([s.A, top(s), s.d]) and not s.A.eq(s.d.sub(s.A))


# ── Using the model ──────────────────────────────────────────

## [h(t0), radian mode, sin and cos swapped, b left out].
static func value_slips(s: Dictionary) -> Array:
	var t: float = s.t0.to_float()
	var no_b := {"fn": s.fn, "a": s.a, "d": s.d, "b": Q.new(1)}
	return [val(s, t), val(s, t, true), swapped(s, t), val(no_b, t)]


static func _value_at_time(rng: Seeded, s: Dictionary) -> bool:
	draw(rng, s)
	var c := ctx(s)
	if s.rep == "words" and c.time == "hours":
		# A clock time on the quarter hour, from midnight.
		s.t0 = Q.new(rng.int_in(2, 92), 4)
	elif s.rep == "words" and c.time == "minutes":
		s.t0 = Q.new(rng.int_in(5, s.T * 8 - 1), 4)
	else:
		s.t0 = Q.new(rng.int_in(3, s.T * 15), 10) if c.time == "seconds" else Q.new(rng.int_in(1, 2 * s.T - 1))
	if s.t0.is_zero() or s.t0.mul(s.b).div(90).is_int():
		return false
	var v := value_slips(s)
	return distinct(v) and Answer.needs_rounding(GdcKit.qf(v[0]))


## The first crossing of the level after t = 0, after t0 (twice) and after t0 in radian mode.
static func first_slips(s: Dictionary) -> Dictionary:
	var L: float = s.L.to_float()
	var t0: float = s.t0.to_float()
	var all: Array = level_times(s, L, 0.0, t0 + 2.0 * s.T)
	var after: Array = all.filter(func(t): return t > t0)
	var before: Array = all.filter(func(t): return t < t0)
	var rad: Array = level_times(s, L, t0, 2.0 * TAU / s.b.to_float(), true)
	return {"after": after, "before": before, "rad": rad}


static func _first_time_level(rng: Seeded, s: Dictionary) -> bool:
	draw(rng, s)
	s.L = level(rng, s)
	if not level_ok(s, s.L):
		return false
	var c0: Array = level_times(s, s.L.to_float(), 0.0, float(s.T))
	if c0.is_empty() or c0[0] < 0.05 * s.T:
		return false
	s.t0 = Q.new(rng.int_in(ceili(c0[0] + 0.1 * s.T), floori(1.6 * s.T)))
	if s.t0.to_float() <= c0[0]:
		return false
	var f := first_slips(s)
	if f.after.size() < 3 or f.before.is_empty() or f.rad.is_empty():
		return false
	var key: float = f.after[0]
	# The start time is not on a crossing, so "after" is clear.
	if key - s.t0.to_float() < 0.04 * s.T or s.t0.to_float() - f.before[-1] < 0.04 * s.T:
		return false
	return distinct([key, f.before[0], f.rad[0], f.after[1]]) and distinct([key, f.after[2]])


## [c1, c2]: the two times in (0, T] when the model is at L.
static func period_crossings(s: Dictionary) -> Array:
	return level_times(s, s.L.to_float(), 0.0, float(s.T))


## [the time above (or below) L in one period, the other part, radian mode, the first crossing,
## half the period].
static func above_slips(s: Dictionary) -> Array:
	var c: Array = period_crossings(s)
	var inside: float = c[1] - c[0]
	var mid_above: bool = val(s, (c[0] + c[1]) / 2.0) > s.L.to_float()
	var key: float = inside if mid_above == s.above else s.T - inside
	return [key, s.T - key, key * PI / 180.0, c[0], s.T / 2.0]


static func _time_above(rng: Seeded, s: Dictionary) -> bool:
	draw(rng, s)
	s.L = level(rng, s)
	s.above = rng.chance(0.5)
	if not level_ok(s, s.L):
		return false
	var c: Array = period_crossings(s)
	if c.size() != 2:
		return false
	return distinct(above_slips(s)) and distinct(c)


## [complete cycles, b as the period, half-cycles, rounded up].
static func cycle_slips(s: Dictionary) -> Array:
	var q: float = float(s.total) / s.T
	return [floori(q), floori(float(s.total) / s.b.to_float()), floori(2.0 * q), ceili(q)]


static func _count_cycles(rng: Seeded, s: Dictionary) -> bool:
	draw(rng, s)
	var c := ctx(s)
	if s.rep == "words":
		s.span = rng.int_in(1, 7 if c.big[0] == "days" else 4)
		s.total = s.span * int(c.big[1])
	else:
		s.total = rng.int_in(2 * s.T, 12 * s.T)
	var q: float = float(s.total) / s.T
	var frac := q - floorf(q)
	if frac < 0.15 or frac > 0.9 or floori(q) < 2 or floori(q) > 40:
		return false
	var v := cycle_slips(s)
	if v[1] < 1:
		return false
	var seen := {}
	for x in v:
		seen[x] = true
	return seen.size() == v.size()


## [b after the change, T2/360 (upside down), b scaled the wrong way, b unchanged].
static func changed_b(s: Dictionary) -> Array:
	return [Q.new(360, s.T2), Q.new(s.T2, 360), s.b.mul(s.T2).div(s.T), s.b]


## [the new d, the new greatest value, the old d, the new least value].
static func changed_axis(s: Dictionary) -> Array:
	return [s.M2.sub(s.A), s.M2, s.d, s.M2.sub(s.A.mul(2))]


static func _changed(rng: Seeded, s: Dictionary) -> bool:
	draw(rng, s)
	s.change = "period" if rng.chance(0.6) else "axis"
	if s.change == "period":
		var k: Q = rng.pick([Q.new(2), Q.new(3), Q.new(1, 2), Q.new(3, 2), Q.new(2, 3), Q.new(4, 3), Q.new(3, 4)])
		var T2 := k.mul(s.T)
		if not T2.is_int() or T2.n < 3:
			return false
		s.T2 = T2.n
		return clean_bs(changed_b(s) + [Q.new(180, s.T2)])
	var step := Q.new(rng.int_in(2, 16), 2)
	s.M2 = top(s).add(step if rng.chance(0.6) else step.neg())
	if s.M2.sub(s.A.mul(2)).sign() <= 0:
		return false
	return distinct_q(changed_axis(s))


## The times in (0, span] when the two models are equal, in degree or radian mode.
static func meet_times(s: Dictionary, span: float, rad: bool = false) -> Array:
	var m2: Dictionary = s.m2
	var f := func(t: float) -> float: return val(s, t, rad) - val(m2, t, rad)
	var per: float = minf(s.T, m2.T)
	if rad:
		per = TAU / maxf(s.b.to_float(), m2.b.to_float())
	return roots(f, 0.0, span, per / 64.0)


## [the first time they are equal, radian mode, the second time, the first time model 1 is at
## model 2's principal axis].
static func meet_slips(s: Dictionary) -> Array:
	var deg := meet_times(s, 3.0 * maxf(s.T, s.m2.T))
	var rad := meet_times(s, 3.0 * TAU / minf(s.b.to_float(), s.m2.b.to_float()), true)
	var axis := level_times(s, s.m2.d.to_float(), 0.0, 2.0 * s.T)
	var out: Array = [deg[0] if deg.size() > 0 else NAN, rad[0] if rad.size() > 0 else NAN, deg[1] if deg.size() > 1 else NAN]
	out.append(axis[0] if axis.size() > 0 else NAN)
	return out


static func _two_models(rng: Seeded, s: Dictionary) -> bool:
	draw(rng, s)
	var c := ctx(s)
	var m2 := model(rng, c, c.periods)
	if m2.T == s.T and m2.A.eq(s.A):
		return false
	s.m2 = m2
	# They start apart, and their ranges overlap so they meet.
	var gap0 := absf(val(s, 0.0) - val(m2, 0.0))
	if gap0 < 0.1 * (s.A.to_float() + m2.A.to_float()):
		return false
	if not (low(s).lt(top(m2)) and low(m2).lt(top(s))):
		return false
	if not m2.d.sub(s.d).abs_q().lt(s.A) or m2.d.eq(s.d):
		return false
	var v := meet_slips(s)
	if not v.all(func(x): return is_finite(x)):
		return false
	# The first meeting is not a glancing touch: the curves cross clearly.
	var dt: float = 1e-3 * minf(s.T, m2.T)
	var g := func(t: float) -> float: return val(s, t) - val(m2, t)
	if absf(g.call(v[0] + dt) - g.call(v[0] - dt)) / (2.0 * dt) < 0.05 * (s.A.to_float() + m2.A.to_float()) / minf(s.T, m2.T):
		return false
	return distinct(v)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
