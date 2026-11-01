class_name ExpModelSituation
extends RefCounted
## The `exp-model` situation (curriculum/question-types.json): one exponential model in
## a context (FAL-418). The start value, the growth factor (or rate k) and, for limited
## growth, the long-run value are picked; every value, time and rate is derived, so any
## of them can be hidden. Paper 2: answers that aren't whole are given to 3 s.f.
##
## generate() returns:
##   form   "factor" P₀(a)^t, "shift" P₀(a)^(t − t0), "cont" A·e^(kt) with k given,
##          "half" A·e^(kt) with k = ±ln 2/T (a half-life or doubling time T),
##          "data" A·e^(kt) with k from a reading (t1, P1), "limited" C + A·e^(−kt),
##          "log10" R = m·log₁₀(x/x₀), "two" two P₀(a)^t models that meet
##   ctx    the context: what (the sentence's subject), sym, time (plural), one (singular)
##   P0, r, a, t0     factor and shift: r a whole percentage, a = 1 + r/100 (Q)
##   A, k             cont (k a Q, 3 d.p.), half (k a float; T, dir "half"/"double"),
##                    data (k a float; t1, P1), limited (C; A signed; k a Q, or a float
##                    from the reading (t1, P1) when need.kpoint)
##   t2     a later time for a prediction
##   L, tL  a level strictly between the start and the long run, and when it is reached
##   t1, P1 a later reading: for factor, P1 is P(t1) to the nearest whole number
##   n      a number of whole periods (the change over n periods)
##   m, x0, R          log10: the reading R gives x = x₀·10^(R/m)
##   P0b, ab           two: the second model (P0 < P0b, a > ab)
##
## The clean limits are the checker's too (tools/check_answers.py, EM_*).

const TRIES := 3000
## The largest value a prediction may reach.
const MAX_VALUE := 100000.0
const STARTS := [100, 200, 250, 400, 500, 800, 1000, 1200, 1500, 2000, 2500, 5000]
const TABLE_STARTS := [1000, 2000, 4000, 5000]
const TABLE_RATES := [10, 20, 25, 30, 50, -10, -20, -40, -50]

const GROW := [
	{"what": "The population of a town", "sym": "P", "time": "years", "one": "year"},
	{"what": "The number of bacteria in a dish", "sym": "N", "time": "hours", "one": "hour"},
	{"what": "The value of an investment, in dollars,", "sym": "V", "time": "years", "one": "year"},
]
const DECAY := [
	{"what": "The value of a car, in dollars,", "sym": "V", "time": "years", "one": "year"},
	{"what": "The mass of a drug in a patient's blood, in mg,", "sym": "M", "time": "hours", "one": "hour"},
	{"what": "The mass of a radioactive sample, in grams,", "sym": "M", "time": "days", "one": "day"},
]
const COOL := [
	{"what": "The temperature of a cup of tea, in °C,", "sym": "T", "time": "minutes", "one": "minute"},
	{"what": "The temperature of a cooling oven, in °C,", "sym": "T", "time": "minutes", "one": "minute"},
]
const RISE := [
	{"what": "The number of words a student has learned", "sym": "W", "time": "days", "one": "day"},
	{"what": "The height of a sunflower, in cm,", "sym": "H", "time": "days", "one": "day"},
]
const LOGS := [
	{"what": "The loudness L of a sound, in decibels,", "sym": "L", "x": "the sound's intensity"},
	{"what": "The reading R on a sensor", "sym": "R", "x": "the strength of the signal"},
]
const TWO := {"what": "P(t) and Q(t) are the populations of two towns t years from now.", "sym": "P", "time": "years", "one": "year"}


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var form: String = need.get("form", "any")
	if form.begins_with("any"):
		form = ["factor", "shift", "cont", "limited"][rng.int_in(0, 3)]
	for i in TRIES:
		var s := _draw(rng, form, need)
		if not s.is_empty() and _clean(s, need):
			s.form = form
			return s
	push_error("ExpModelSituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, form: String, need: Dictionary) -> Dictionary:
	var s := {"form": form}
	match form:
		"factor", "shift":
			var grow: bool = rng.chance(0.55) and not need.get("decay", false)
			if need.get("table", false):
				s.P0 = Q.new(TABLE_STARTS[rng.int_in(0, TABLE_STARTS.size() - 1)])
				s.r = TABLE_RATES[rng.int_in(0, TABLE_RATES.size() - 1)]
				grow = s.r > 0
			else:
				s.P0 = Q.new(STARTS[rng.int_in(0, STARTS.size() - 1)])
				s.r = rng.int_in(2, 25) if grow else -rng.int_in(3, 30)
			s.a = Q.new(100 + s.r, 100)
			s.ctx = _ctx(rng, GROW if s.r > 0 else DECAY)
			s.t0 = rng.int_in(1, 5) if form == "shift" else 0
			s.t1 = rng.int_in(3, 12)
			s.P1 = Q.new(roundi(value(s, s.t1)))
			if s.P1.to_float() < 10.0:
				return {}
		"cont":
			var grow: bool = rng.chance(0.5) and not need.get("decay", false)
			s.A = Q.new(STARTS[rng.int_in(0, STARTS.size() - 1)])
			s.k = Q.new(rng.int_in(5, 60) * (1 if grow else -1), 200)
			s.ctx = _ctx(rng, GROW if grow else DECAY)
		"half":
			var grow := rng.chance(0.4)
			s.A = Q.new(STARTS[rng.int_in(0, STARTS.size() - 1)])
			s.T = rng.int_in(2, 10) if need.get("grid", false) else rng.int_in(2, 30)
			s.dir = "double" if grow else "half"
			s.k = (1.0 if grow else -1.0) * log(2.0) / s.T
			s.ctx = _ctx(rng, GROW if grow else DECAY)
			if need.get("grid", false):
				s.halvings = rng.int_in(1, 3)
				if s.halvings * s.T > 24:
					return {}
		"data":
			s.A = Q.new(STARTS[rng.int_in(0, STARTS.size() - 1)])
			s.t1 = rng.int_in(2, 10)
			var ratio := rng.int_in(12, 30) / 10.0 if rng.chance(0.5) else rng.int_in(30, 85) / 100.0
			s.P1 = Q.new(roundi(s.A.to_float() * ratio))
			if s.P1.eq(s.A) or s.P1.sign() <= 0:
				return {}
			s.k = log(s.P1.div(s.A).to_float()) / s.t1
			s.ctx = _ctx(rng, GROW if s.k > 0 else DECAY)
		"limited":
			var cool := rng.chance(0.5)
			if cool:
				s.C = Q.new(rng.int_in(15, 25))
				s.A = Q.new(rng.int_in(8, 16) * 5)
				s.ctx = _ctx(rng, COOL)
			else:
				s.C = Q.new(rng.int_in(4, 20) * 50)
				var start: float = rng.int_in(1, 6) * s.C.to_float() / 10.0
				s.A = Q.new(roundi(start - s.C.to_float()))
				s.ctx = _ctx(rng, RISE)
			if need.get("kpoint", false):
				s.t1 = rng.int_in(2, 12)
				var g := rng.int_in(20, 80) / 100.0
				s.P1 = Q.new(roundi(s.C.to_float() + s.A.to_float() * g))
				var frac: float = s.P1.sub(s.C).div(s.A).to_float()
				if frac <= 0.0 or frac >= 1.0:
					return {}
				s.k = -log(frac) / s.t1
			else:
				s.k = Q.new(rng.int_in(4, 60), 200)
		"log10":
			s.ctx = LOGS[rng.int_in(0, LOGS.size() - 1)]
			s.m = Q.new([1, 2, 5, 10, 20][rng.int_in(0, 4)])
			s.x0 = Q.new([2, 4, 5, 10, 20, 50][rng.int_in(0, 5)])
			var ratio := rng.int_in(12, 45) / 10.0
			s.R = Q.new(roundi(ratio * s.m.to_float() * 10.0), 10)
			if s.R.div(s.m).to_float() < 1.2 or s.R.div(s.m).to_float() > 4.5:
				return {}
			return s
		"two":
			s.ctx = TWO
			s.P0 = Q.new(STARTS[rng.int_in(0, 8)])
			s.P0b = Q.new(STARTS[rng.int_in(0, STARTS.size() - 1)])
			var r1 := rng.int_in(3, 15)
			var r2 := rng.int_in(-10, r1 - 2)
			if not s.P0.lt(s.P0b) or r2 == 0:
				return {}
			s.a = Q.new(100 + r1, 100)
			s.ab = Q.new(100 + r2, 100)
			s.tL = log(s.P0b.div(s.P0).to_float()) / log(s.a.div(s.ab).to_float())
			return s
	s.t2 = rng.int_in(3, 20)
	s.n = rng.int_in(2, 10)
	s.L = _level(rng, s)
	if s.L == null:
		return {}
	s.tL = time_at(s, s.L.to_float())
	return s


static func _ctx(rng: Seeded, pool: Array) -> Dictionary:
	return pool[rng.int_in(0, pool.size() - 1)]


## A level strictly between the start and the long-run value, as a whole number (a round
## one for large values), or null.
static func _level(rng: Seeded, s: Dictionary) -> Variant:
	var start := value(s, float(s.get("t0", 0)))
	var target: float
	match s.form:
		"limited":
			target = s.C.to_float() + s.A.to_float() * rng.int_in(15, 85) / 100.0
		"half":
			if s.has("halvings"):
				var exact := start * pow(2.0, s.halvings if s.dir == "double" else -s.halvings)
				return Q.new(roundi(exact)) if absf(exact - roundf(exact)) < 1e-9 else null
			target = start * (rng.int_in(130, 450) / 100.0 if s.dir == "double" else rng.int_in(10, 80) / 100.0)
		_:
			target = start * (rng.int_in(130, 450) / 100.0 if growing(s) else rng.int_in(15, 80) / 100.0)
	var step := 10 if absf(target) >= 200 else 1
	var lv := roundi(target / step) * step
	if lv <= 0 or lv == roundi(start):
		return null
	return Q.new(lv)


## Clear of a 3 s.f. rounding edge, with a margin over the checker's (0.02), so float
## and exact arithmetic can't land on opposite sides of it; and not next to a power of
## ten, where 999.6 or 1000.3 shows as "1000" and a near miss such as 997 reads as right.
static func rounds_clear(x: float) -> bool:
	if not is_finite(x) or x == 0.0:
		return false
	var mantissa := absf(x) / pow(10.0, floorf(log(absf(x)) / log(10.0)))
	return Answer.rounds_clearly(x, 0.025) and mantissa >= 1.02 and mantissa < 9.9


static func _clean(s: Dictionary, need: Dictionary) -> bool:
	match s.form:
		"log10":
			var x := log_x(s)
			return rounds_clear(x) and x < MAX_VALUE
		"two":
			return s.tL > 2.0 and s.tL < 40.0 and rounds_clear(s.tL)
	var t: float = s.tL
	var t0: int = s.get("t0", 0)
	if not is_finite(t) or t <= t0 + 0.5 or t > 60.0 or not rounds_clear(t):
		return false
	# Whole-period answers must not sit on a whole number.
	if s.form != "half" or not s.has("halvings"):
		var f := t - floorf(t)
		if f < 0.1 or f > 0.9:
			return false
	# A prediction stays a believable size (and well inside exact arithmetic).
	var later := value(s, s.t2)
	if not rounds_clear(later) or later > MAX_VALUE or later < 1.0:
		return false
	match s.form:
		"factor", "shift":
			if need.get("table", false):
				for i in range(1, 5):
					var v: Q = s.P0.mul(pow_q(s.a, i))
					if 100 % v.d != 0:
						return false
			if not rounds_clear(s.P1.to_float() / pow(s.a.to_float(), s.t1)):
				return false
			if not rounds_clear(absf(pow(s.a.to_float(), s.n) - 1.0) * 100.0):
				return false
		"data":
			if not rounds_clear(s.k):
				return false
		"limited":
			if need.get("kpoint", false) and (s.k < 0.02 or s.k > 0.6 or not rounds_clear(s.k)):
				return false
		"cont":
			if s.k.sign() < 0 and not rounds_clear(log(2.0) / absf(s.k.to_float())):
				return false
	return true


# ── The model ────────────────────────────────────────────────

## k as a float (cont and limited keep it as a Q).
static func kf(s: Dictionary) -> float:
	return s.k.to_float() if s.k is Q else float(s.k)


## The model's value at time t.
static func value(s: Dictionary, t: float) -> float:
	match s.form:
		"factor", "shift":
			return s.P0.to_float() * pow(s.a.to_float(), t - s.get("t0", 0))
		"cont", "half", "data":
			return s.A.to_float() * exp(kf(s) * t)
		"limited":
			return s.C.to_float() + s.A.to_float() * exp(-kf(s) * t)
	return NAN


## The value at t = 0, or at t0 for the shifted model.
static func start(s: Dictionary) -> float:
	return value(s, float(s.get("t0", 0)))


static func growing(s: Dictionary) -> bool:
	match s.form:
		"factor", "shift", "two":
			return s.a.to_float() > 1.0
		"limited":
			return s.A.sign() < 0
	return kf(s) > 0.0


## When the model equals lv.
static func time_at(s: Dictionary, lv: float) -> float:
	match s.form:
		"factor", "shift":
			return s.get("t0", 0) + log(lv / s.P0.to_float()) / log(s.a.to_float())
		"cont", "half", "data":
			return log(lv / s.A.to_float()) / kf(s)
		"limited":
			return -log((lv - s.C.to_float()) / s.A.to_float()) / kf(s)
	return NAN


## The log model's x for its reading R.
static func log_x(s: Dictionary) -> float:
	return s.x0.to_float() * pow(10.0, s.R.div(s.m).to_float())


static func pow_q(a: Q, n: int) -> Q:
	var out := Q.new(1)
	for i in n:
		out = out.mul(a)
	return out


static func export(s: Dictionary) -> Dictionary:
	var out := {}
	for key in s:
		var v = s[key]
		out[key] = v.key() if v is Q else (str(v) if v is float else v)
	return out
