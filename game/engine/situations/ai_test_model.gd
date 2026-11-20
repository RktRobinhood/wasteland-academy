class_name AiTestModelSituation
extends RefCounted
## The `ai-test-model` situation (curriculum/question-types.json), FAL-1001: a fitted model in
## context, tested against what was recorded and used, for fn-ai-test-model (AI-SL2.6.test-model,
## AI-SL2.6.use-model). Every AI paper allows a GDC, so every question is Paper 2.
##
## need.ask is the unknown and need.rep its representation (see AiTestModelViews). generate()
## returns a Dictionary:
##   paper, ask, rep   always 2; the unknown; the representation
##   ctx    the story (an index in CTX): 0 a settlement's population (exponential, a cap from its
##          wells), 1 a mug of tea cooling in a room (linear, the room's temperature a floor),
##          2 a signal flare fired from a tower (quadratic, the ground a floor), 3 a salvage truck's
##          value (linear, $0 a floor), 4 solar panels on the city's roofs (linear, a cap from the
##          roof space), 5 traders at a night market (quadratic, 0 a floor)
##   fam    "lin" c0 + c1·t, "quad" qa·t² + qb·t + qc, "exp" A·b^t; each parameter a Q
##   y0     the start year, where t counts years (ctx 0, 3, 4, 5)
##   level  the cap or the floor the context sets (a Q); cross: when the model reaches it (float)
##   percentage-error: ts, ys  readings (Q); tt  the test input (a Q, one of ts); obs  its reading
##   compare-two-models: the linear model c0, c1 and the exponential A, b both pass through the
##          readings at t = 0 and t = 2 (y_a, y_b); tt the test input, obs the reading there, better
##          "A" (the linear model) or "B" (the exponential one)
##   reject-from-value: tb  an input past cross, where the model gives an impossible value
##   limitation: t1  the second reading the model was fitted to (the first is at t = 0)
##   year-to-t: tp  the input of the predicted year (the year is y0 + tp)
##   interpolate-or-extrapolate: ts, ys  readings every 2 years; t_in, t_out  the two inputs;
##          in_first  whether the inside one is named first
##   interpret-parameter: which  "rate" (c1, or b) or "start" (c0, or A)
##
## The numbers are drawn, not taken from any exam question. The SymPy checker
## (tools/check_answers.py, r3te_check) reads every value back from what the question shows and
## works it out again.

const TRIES := 4000
## A 3 s.f. value is at least this far (a fraction of its last place) from a rounding edge.
const EDGE := 0.04
## The stories whose t counts years from a start year.
const YEARS := [0, 3, 4, 5]
## The stories whose context sets a cap (the rest set a floor).
const CAPS := [0, 4]
## The stories each unknown draws from.
const STORIES := {
	"percentage-error": [0, 1, 2, 3, 4, 5],
	"compare-two-models": [0, 3, 4],
	"reject-from-value": [0, 1, 2, 3, 4, 5],
	"limitation": [0, 1, 2, 3, 4],
	"year-to-t": [3, 4, 5],
	"interpolate-or-extrapolate": [0, 3, 4, 5],
	"interpret-parameter": [0, 1, 3, 4],
}


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "percentage-error")
	var rep: String = need.get("rep", "")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "rep": rep}
		if _draw(rng, s):
			return s
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	draw_model(rng, s, rng.pick(STORIES[s.ask]))
	match s.ask:
		"percentage-error":
			return _percentage(rng, s)
		"compare-two-models":
			return _compare(rng, s)
		"reject-from-value":
			return _reject(rng, s)
		"limitation":
			return _limitation(rng, s)
		"year-to-t":
			return _year(rng, s)
		"interpolate-or-extrapolate":
			return _range(rng, s)
		"interpret-parameter":
			s.which = "rate" if rng.chance(0.5) else "start"
			return true
	return false


# ── Small tools ──────────────────────────────────────────────

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


static func tenths(rng: Seeded, lo: int, hi: int) -> Q:
	return Q.new(rng.int_in(lo, hi), 10)


# ── The model ────────────────────────────────────────────────

static func draw_model(rng: Seeded, s: Dictionary, ctx: int) -> void:
	s.ctx = ctx
	match ctx:
		0:
			s.fam = "exp"
			s.A = Q.new(rng.int_in(12, 48) * 100)
			s.b = Q.new(100 + rng.pick([2, 3, 4, 5, 6, 8]), 100)
		1:
			s.fam = "lin"
			s.c0 = Q.new(rng.pick([80, 82, 85, 88, 90, 92, 95]))
			s.c1 = Q.new(-rng.pick([3, 4, 5, 6, 7, 8]), 2)
			s.level = Q.new(rng.pick([18, 19, 20, 21, 22, 24]))
		2:
			s.fam = "quad"
			s.qa = Q.new(-49, 10)
			s.qb = tenths(rng, 120, 300)
			s.qc = Q.new(rng.pick([15, 20, 25, 30, 50, 80, 100, 120]), 10)
			s.level = Q.new(0)
		3:
			s.fam = "lin"
			s.c0 = Q.new(rng.int_in(24, 60) * 500)
			s.c1 = Q.new(-rng.int_in(16, 50) * 50)
			s.level = Q.new(0)
		4:
			s.fam = "lin"
			s.c0 = Q.new(rng.int_in(12, 60) * 10)
			s.c1 = Q.new(rng.int_in(15, 60))
		5:
			s.fam = "quad"
			s.qa = Q.new(-rng.pick([1, 2, 3, 4, 5]), 2)
			s.qb = Q.new(rng.int_in(8, 30))
			s.qc = Q.new(rng.int_in(6, 30) * 10)
			s.level = Q.new(0)
	if ctx in YEARS:
		s.y0 = rng.int_in(2005, 2016)
	if ctx in CAPS:
		# A round cap the model passes between t = 15 and t = 40.
		var at := float(rng.int_in(15, 40))
		var step := 1000 if ctx == 0 else 100
		s.level = Q.new(maxi(1, roundi(value(s, at) / step)) * step)
	s.cross = cross(s)


static func value(s: Dictionary, t: float) -> float:
	match s.fam:
		"exp":
			return s.A.to_float() * pow(s.b.to_float(), t)
		"quad":
			return (s.qa.to_float() * t + s.qb.to_float()) * t + s.qc.to_float()
	return s.c0.to_float() + s.c1.to_float() * t


## The model's value exactly, at a Q input (linear and quadratic, and exponential at a whole t).
static func value_q(s: Dictionary, t: Q) -> Q:
	match s.fam:
		"exp":
			var v: Q = s.A
			for i in int(t.to_float()):
				v = v.mul(s.b)
			return v
		"quad":
			return s.qa.mul(t).add(s.qb).mul(t).add(s.qc)
	return s.c0.add(s.c1.mul(t))


## The model's value as the question works it: exact where it can be, else a float.
static func at(s: Dictionary, t: Variant) -> Variant:
	if s.fam == "exp":
		return value(s, Q.of(t).to_float())
	return value_q(s, Q.of(t))


## The first t > 0 where the model reaches the context's level, or -1.
static func cross(s: Dictionary) -> float:
	var L: float = s.level.to_float()
	match s.fam:
		"exp":
			return log(L / s.A.to_float()) / log(s.b.to_float())
		"quad":
			var a: float = s.qa.to_float()
			var b: float = s.qb.to_float()
			var c: float = s.qc.to_float() - L
			var disc := b * b - 4.0 * a * c
			if disc < 0.0:
				return -1.0
			return (-b - sqrt(disc)) / (2.0 * a)
	if s.c1.is_zero():
		return -1.0
	return (L - s.c0.to_float()) / s.c1.to_float()


## The crossing exactly, for a linear model.
static func cross_q(s: Dictionary) -> Q:
	return s.level.sub(s.c0).div(s.c1)


## Whether a linear model's crossing ends within two decimal places: it is then written exactly.
static func cross_exact(s: Dictionary) -> bool:
	return s.fam == "lin" and 100 % cross_q(s).d == 0


## The model's start value, at t = 0.
static func start(s: Dictionary) -> Q:
	match s.fam:
		"exp":
			return s.A
		"quad":
			return s.qc
	return s.c0


## A recorded value near the model's at t: a 1.5% to 8% miss either way, to 1 d.p. for the tea
## and the flare, else whole.
static func reading(rng: Seeded, s: Dictionary, t: float) -> Q:
	var miss := rng.int_in(15, 80) / 1000.0 * (1.0 if rng.chance(0.5) else -1.0)
	var v := value(s, t) * (1.0 + miss)
	if s.ctx in [1, 2]:
		return Q.new(roundi(v * 10.0), 10)
	return Q.new(roundi(v))


# ── Percentage error ─────────────────────────────────────────

static func _percentage(rng: Seeded, s: Dictionary) -> bool:
	var step: Q = Q.new(1, 2) if s.ctx == 2 else Q.new(rng.pick([1, 2]))
	var n := rng.int_in(4, 6)
	var ts: Array = []
	for i in n:
		ts.append(step.mul(i))
	if ts[-1].to_float() >= s.cross * 0.9:
		return false
	s.ts = ts
	s.ys = ts.map(func(t): return reading(rng, s, t.to_float()))
	var j := rng.int_in(1, n - 1)
	s.tt = ts[j]
	s.obs = s.ys[j]
	if s.obs.sign() <= 0:
		return false
	var vals := percentage_slips(s)
	var e: float = vals[0]
	if e < 0.5 or e > 15.0 or not Answer.needs_rounding(GdcKit.qf(e)):
		return false
	# The error from the 7 figures the working shows is the same to 3 s.f.
	var m7 := float(Fmt.sf(value(s, s.tt.to_float()), 7).replace("−", "-"))
	var o: float = s.obs.to_float()
	if Fmt.sf(absf(m7 - o) / o * 100.0) != Fmt.sf(e):
		return false
	return distinct(vals)


## [the error over the actual value, over the model's value, the error not divided].
static func percentage_slips(s: Dictionary) -> Array:
	var m := value(s, s.tt.to_float())
	var o: float = s.obs.to_float()
	return [absf(m - o) / o * 100.0, absf(m - o) / m * 100.0, absf(m - o)]


# ── Two models ───────────────────────────────────────────────

static func _compare(rng: Seeded, s: Dictionary) -> bool:
	match s.ctx:
		0:
			s.A = Q.new(rng.int_in(10, 50) * 100)
			s.b = Q.new(100 + rng.pick([4, 5, 6, 8, 10, 12]), 100)
		3:
			s.A = Q.new(rng.int_in(24, 60) * 500)
			s.b = Q.new(100 - rng.pick([8, 10, 12, 15, 20]), 100)
		4:
			s.A = Q.new(rng.int_in(10, 40) * 20)
			s.b = Q.new(100 + rng.pick([5, 6, 8, 10, 12, 15]), 100)
	s.fam = "exp"
	var yb: Q = s.A.mul(s.b).mul(s.b)
	if not yb.is_int():
		return false
	s.y_a = s.A
	s.y_b = yb
	s.c0 = s.A
	s.c1 = yb.sub(s.A).div(2)
	s.tt = Q.new(rng.int_in(5, 10))
	var t: float = s.tt.to_float()
	var pa: float = s.c0.add(s.c1.mul(s.tt)).to_float()
	var pb: float = s.A.to_float() * pow(s.b.to_float(), t)
	if pa <= 0.0 or absf(pb - pa) / pa < 0.08:
		return false
	s.better = "A" if rng.chance(0.5) else "B"
	var best := pa if s.better == "A" else pb
	var worst := pb if s.better == "A" else pa
	var gap := absf(pb - pa)
	var off := gap * rng.int_in(4, 30) / 100.0
	# Most of the time the reading lies between the two; sometimes past the better one.
	var toward := signf(worst - best) if rng.chance(0.7) else -signf(worst - best)
	s.obs = Q.new(roundi(best + toward * off))
	var o: float = s.obs.to_float()
	if o <= 0.0 or absf(o - best) > 0.4 * absf(o - worst):
		return false
	var ps := [pa, pb]
	if not distinct(ps) or Fmt.sf(pa) == Fmt.sf(o) or Fmt.sf(pb) == Fmt.sf(o):
		return false
	return true


static func pred_a(s: Dictionary) -> float:
	return s.c0.add(s.c1.mul(s.tt)).to_float()


static func pred_b(s: Dictionary) -> float:
	return s.A.to_float() * pow(s.b.to_float(), s.tt.to_float())


# ── An impossible value ──────────────────────────────────────

static func _reject(rng: Seeded, s: Dictionary) -> bool:
	if s.cross <= 0.0 or s.cross > 60.0:
		return false
	var first := ceili(s.cross + 0.05)
	s.tb = Q.new(rng.int_in(first, first + (2 if s.ctx == 2 else 8)))
	var v: Variant = at(s, s.tb)
	var x: float = Q.of(v).to_float() if v is Q else v
	var L: float = s.level.to_float()
	match s.ctx:
		0, 4:
			return x > L * 1.03 and (v is Q or clear(x))
		1:
			# Colder than the room, but not below 0 °C.
			return x > 0.5 and x < L - 0.5
		_:
			return x < -0.5 and absf(x) < 1e7
	return false


# ── A limitation ─────────────────────────────────────────────

static func _limitation(rng: Seeded, s: Dictionary) -> bool:
	if s.cross < 3.0 or s.cross > 60.0:
		return false
	s.t1 = Q.new(1) if s.ctx == 2 else Q.new(rng.pick([1, 2, 4]) if s.fam == "lin" else rng.pick([1, 2]))
	if s.t1.to_float() >= s.cross * 0.6:
		return false
	var y1: Q = value_q(s, s.t1)
	# The model passes exactly through the two readings it was fitted to.
	if not (y1.mul(10).is_int() if s.ctx in [1, 2] else y1.is_int()) or y1.sign() <= 0:
		return false
	return cross_exact(s) or clear(s.cross)


# ── A prediction for a year ──────────────────────────────────

static func _year(rng: Seeded, s: Dictionary) -> bool:
	if s.cross < 8.0:
		return false
	s.tp = Q.new(rng.int_in(4, mini(20, floori(s.cross) - 2)))
	var key: Q = value_q(s, s.tp)
	var slip: Q = value_q(s, Q.new(s.y0 + int(s.tp.to_float())))
	if key.sign() <= 0 or absf(slip.to_float()) >= 1e8:
		return false
	return Fmt.dec(key) != Fmt.dec(slip)


# ── Inside or outside the data ───────────────────────────────

static func _range(rng: Seeded, s: Dictionary) -> bool:
	var n := rng.int_in(4, 6)
	if 2.0 * n >= s.cross * 0.9:
		return false
	var ts: Array = []
	for i in n + 1:
		ts.append(Q.new(2 * i))
	s.ts = ts
	s.ys = ts.map(func(t): return reading(rng, s, t.to_float()))
	if s.ys.any(func(y): return y.sign() <= 0):
		return false
	s.t_in = Q.new(2 * rng.int_in(0, n - 1) + 1)
	s.t_out = Q.new(2 * n + rng.int_in(10, 25))
	s.in_first = rng.chance(0.5)
	return true


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
