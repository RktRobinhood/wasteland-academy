class_name AiExpModelSituation
extends RefCounted
## The `ai-exp-model` situation (curriculum/question-types.json), FAL-1001: an exponential
## model ka^t + c or ke^(rt) + c in a story, for fn-ai-exponential-model (AI-SL2.5). Every AI
## paper allows a GDC, so every question is Paper 2.
##
## need.ask is the unknown and need.rep its representation (see AiExpModelViews). generate()
## returns a Dictionary:
##   paper, ask, rep   always 2; the unknown; the representation
##   m      the model: {"form": "a" or "e", "k": Q (signed), "a": Q (form a) or "r": Q
##          (form e, 3 d.p.), "c": Q, "ctx": an index into CTX}
##   kind   the story's kind: "cool" (k > 0, falling to c), "rise" (k < 0, rising to c),
##          "grow" (k > 0, a > 1) or "decay" (k > 0, a < 1, c = 0)
##   value-at-time: tau, the time in the model's unit (Q); n, the time as the question gives
##          it (Q); conv, true when n is in another unit (the context's `alt`)
##   time-to-level, whole-units-to-level: L, the level (Q); tL, when it is reached (float)
##   long-run-meaning: say, "meaning" or "never"; L, a level past the asymptote (never)
##   two-models-equal: m2, the second model; story, an index into TWO; tL, when they meet
##
## The numbers are drawn, not taken from any exam question. The SymPy checker
## (tools/check_answers.py, r3ex_check) reads every value back from what the question shows and
## works it out again.

const TRIES := 4000
## A 3 s.f. answer is at least this far (a fraction of its last place) from a rounding edge.
const EDGE := 0.04
## The largest value an option may have.
const MAX_VALUE := 900000.0

## The stories. kind: see above. alt: another unit of time a question may give, with `per`
## model units in one of it (Q as [n, d]); amounts: what the question may give in it.
const CTX := [
	{"kind": "cool", "what": "The temperature of a pot of cactus soup, in °C,", "after": "it is taken off the stove", "sym": "T",
		"time": "minutes", "one": "minute", "qty": "the temperature of the soup", "c": [15, 25, 1], "k": [40, 75, 1],
		"limit": "the temperature of the kitchen", "unit": " °C",
		"alt": {"time": "seconds", "per": [1, 60], "amounts": [30, 45, 90, 150, 210, 270]}},
	{"kind": "cool", "what": "The temperature of a rover's engine, in °C,", "after": "it is switched off", "sym": "E",
		"time": "minutes", "one": "minute", "qty": "the temperature of the engine", "c": [20, 35, 1], "k": [50, 90, 1],
		"limit": "the temperature of the air around the rover", "unit": " °C",
		"alt": {"time": "seconds", "per": [1, 60], "amounts": [30, 90, 150, 210, 270, 330]}},
	{"kind": "cool", "what": "The reading on a Geiger counter in a scrubbed bunker, in counts per minute,", "after": "the scrubbing ends",
		"sym": "R", "time": "days", "one": "day", "qty": "the reading on the counter", "c": [20, 60, 5], "k": [200, 900, 50],
		"limit": "the background level of radiation in the bunker", "unit": " counts per minute",
		"alt": {"time": "weeks", "per": [7, 1], "amounts": [2, 3, 4]}},
	{"kind": "cool", "what": "The level of toxin in Grey Lake, in parts per million,", "after": "the dumping stops", "sym": "P",
		"time": "years", "one": "year", "qty": "the level of toxin in the lake", "c": [2, 12, 1], "k": [40, 200, 5],
		"limit": "the lake's natural level of toxin", "unit": " parts per million",
		"alt": {"time": "months", "per": [1, 12], "amounts": [6, 9, 18, 30, 42, 54]}},
	{"kind": "rise", "what": "The number of settlers in Dustwater who have heard a news broadcast", "after": "it is first broadcast",
		"sym": "N", "time": "hours", "one": "hour", "qty": "the number of settlers who have heard the news", "c": [800, 2400, 100],
		"start": [5, 30], "limit": "the number of settlers in Dustwater", "unit": "",
		"alt": {"time": "minutes", "per": [1, 60], "amounts": [30, 45, 90, 150, 210, 270]}},
	{"kind": "rise", "what": "The temperature of a water barrel left in the sun, in °C,", "after": "it is filled", "sym": "W",
		"time": "hours", "one": "hour", "qty": "the temperature of the water", "c": [30, 42, 1], "start": [8, 16],
		"limit": "the temperature the sun warms the barrel to", "unit": " °C",
		"alt": {"time": "minutes", "per": [1, 60], "amounts": [30, 45, 90, 150, 210]}},
	{"kind": "grow", "what": "The number of scrap beetles in a junkyard colony", "after": "it is first counted", "sym": "B",
		"time": "days", "one": "day", "qty": "the number of beetles", "c": [20, 120, 10], "k": [40, 300, 10], "pct": [2, 9],
		"unit": "", "alt": {"time": "weeks", "per": [7, 1], "amounts": [2, 3, 4]}},
	{"kind": "grow", "what": "The number of solar panels working across the Rim", "after": "the repair programme starts", "sym": "S",
		"time": "years", "one": "year", "qty": "the number of working solar panels", "c": [50, 400, 50], "k": [200, 1500, 50],
		"pct": [4, 15], "unit": "", "alt": {"time": "months", "per": [1, 12], "amounts": [6, 9, 18, 30, 42]}},
	{"kind": "decay", "what": "The mass of a fuel isotope in a sealed reactor cell, in grams,", "after": "the cell is sealed", "sym": "M",
		"time": "years", "one": "year", "qty": "the mass of the isotope", "k": [200, 900, 10], "pct": [3, 15], "unit": "",
		"alt": {"time": "months", "per": [1, 12], "amounts": [6, 9, 18, 30, 42]}},
	{"kind": "decay", "what": "The number of working generators in Old Harbour", "after": "the last repair crew leaves", "sym": "G",
		"time": "years", "one": "year", "qty": "the number of working generators", "k": [400, 1200, 20], "pct": [5, 30], "unit": "",
		"alt": {"time": "months", "per": [1, 12], "amounts": [6, 18, 30]}},
]

## Two models that meet once, A(t) and B(t).
const TWO := [
	{"what": "Two pots of soup cool in the same kitchen. Their temperatures, in °C, t minutes after they are taken off the stove are",
		"time": "minutes", "one": "minute", "things": "the two temperatures"},
	{"what": "Two scrap beetle colonies are counted every day. The numbers of beetles in them t days after the first count are",
		"time": "days", "one": "day", "things": "the two colonies"},
	{"what": "The number of settlers in Ashford is growing and the number in Brack is falling. t years from now, their numbers are",
		"time": "years", "one": "year", "things": "the two settlements"},
]

const NICE_STEP := 10


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "initial-value")
	var rep: String = need.get("rep", "")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "rep": rep}
		if _draw(rng, s):
			return s
	push_error("AiExpModelSituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"initial-value":
			return _initial(rng, s)
		"value-at-time":
			return _value(rng, s)
		"percent-change":
			return _percent(rng, s)
		"asymptote":
			return _asymptote(rng, s)
		"long-run-meaning":
			return _long_run(rng, s)
		"time-to-level", "whole-units-to-level":
			return _level(rng, s)
		"two-models-equal":
			return _two(rng, s)
	return false


# ── Small tools ──────────────────────────────────────────────

static func clear(x: float) -> bool:
	return is_finite(x) and Answer.rounds_clearly(x, EDGE)


## Every value is clear of a 3 s.f. edge and no two read the same.
static func distinct(xs: Array) -> bool:
	var seen := {}
	for x in xs:
		if not is_finite(x) or not clear(x):
			return false
		seen[Fmt.sf(x)] = true
	return seen.size() == xs.size()


static func step_in(rng: Seeded, r: Array) -> int:
	return rng.int_in(int(r[0]) / int(r[2]), int(r[1]) / int(r[2])) * int(r[2])


static func ctx_of(s: Dictionary) -> Dictionary:
	return CTX[s.m.ctx]


static func kind(s: Dictionary) -> String:
	return CTX[s.m.ctx].kind


## The contexts of the given kinds, as indices.
static func of_kinds(kinds: Array) -> Array:
	var out: Array = []
	for i in CTX.size():
		if CTX[i].kind in kinds:
			out.append(i)
	return out


## A model in one of the contexts: form a or e, k, the factor and c, as the story's kind
## needs. with_c: c is drawn (cool and rise always have one; grow has one when asked).
static func model(rng: Seeded, ci: int, with_c: bool, form: String = "") -> Dictionary:
	var c: Dictionary = CTX[ci]
	var m := {"ctx": ci, "form": form if form != "" else ("a" if rng.chance(0.6) else "e")}
	match c.kind:
		"cool":
			m.c = Q.new(step_in(rng, c.c))
			m.k = Q.new(step_in(rng, c.k))
		"rise":
			m.c = Q.new(step_in(rng, c.c))
			# A large total starts at a share of it (a round ten); a temperature at a whole number.
			var first := rng.int_in(c.start[0], c.start[1])
			if m.c.to_float() >= 500.0:
				first = roundi(m.c.to_float() * first / 1000.0) * 10
			m.k = Q.new(first).sub(m.c)
		"grow":
			m.k = Q.new(step_in(rng, c.k))
			m.c = Q.new(step_in(rng, c.c)) if with_c else Q.new(0)
		_:
			m.k = Q.new(step_in(rng, c.k))
			m.c = Q.new(0)
	var up: bool = c.kind == "grow"
	if m.form == "a":
		if c.has("pct"):
			var p := rng.int_in(c.pct[0], c.pct[1])
			m.a = Q.new(100 + p if up else 100 - p, 100)
		else:
			m.a = Q.new(rng.int_in(60, 95), 100)
	else:
		if up:
			m.r = Q.new(rng.int_in(15, 120), 1000)
		else:
			m.r = Q.new(-rng.int_in(40, 400), 1000)
	return m


## The model's value at time t.
static func value(m: Dictionary, t: float) -> float:
	if m.form == "a":
		return m.k.to_float() * pow(m.a.to_float(), t) + m.c.to_float()
	return m.k.to_float() * exp(m.r.to_float() * t) + m.c.to_float()


## The varying part's factor over one unit of time: a, or e^r.
static func factor(m: Dictionary) -> float:
	return m.a.to_float() if m.form == "a" else exp(m.r.to_float())


static func start(m: Dictionary) -> Q:
	return m.k.add(m.c)


## When the model equals lv, or NAN.
static func time_at(m: Dictionary, lv: float) -> float:
	var ratio: float = (lv - m.c.to_float()) / m.k.to_float()
	if ratio <= 0.0:
		return NAN
	return log(ratio) / log(factor(m))


## The time the linear slip gives: the first unit's change added every unit.
static func linear_time(m: Dictionary, lv: float) -> float:
	var d := value(m, 1.0) - value(m, 0.0)
	return (lv - start(m).to_float()) / d


# ── Unknowns ─────────────────────────────────────────────────

static func _initial(rng: Seeded, s: Dictionary) -> bool:
	var ci: int = rng.pick(of_kinds(["cool", "grow"]))
	s.m = model(rng, ci, true)
	var k: Q = s.m.k
	var c: Q = s.m.c
	return not k.eq(c) and not k.eq(c.mul(2)) and not c.eq(k.mul(2))


## A time in the model's unit: given in another unit 60% of the time.
static func _value(rng: Seeded, s: Dictionary) -> bool:
	var ci: int = rng.pick(of_kinds(["cool", "rise", "grow", "decay"]))
	var c: Dictionary = CTX[ci]
	s.m = model(rng, ci, rng.chance(0.7))
	s.conv = rng.chance(0.6)
	if s.conv:
		s.n = Q.new(int(rng.pick(c.alt.amounts)))
		s.tau = s.n.mul(Q.new(c.alt.per[0], c.alt.per[1]))
	else:
		s.n = Q.new(rng.int_in(2, 12))
		s.tau = s.n
	var tau: float = s.tau.to_float()
	var x := value(s.m, tau)
	var key := GdcKit.qf(x)
	if x <= 0.0 or x > MAX_VALUE or not Answer.needs_rounding(key):
		return false
	# The key and every value a slip or filler gives read differently.
	var vals: Array = [x]
	if not s.m.c.is_zero():
		vals.append(x - s.m.c.to_float())
	if s.conv:
		var y := value(s.m, s.n.to_float())
		if y > MAX_VALUE or y < 1.0:
			return false
		vals.append(y)
	vals.append(value(s.m, 2.0 * tau))
	if vals.any(func(v): return v <= 0.0 or v > MAX_VALUE):
		return false
	if not distinct(vals):
		return false
	return not Fmt.sf(start(s.m)) in vals.map(func(v): return Fmt.sf(v))


static func _percent(rng: Seeded, s: Dictionary) -> bool:
	var ci: int = rng.pick(of_kinds(["grow", "decay"]))
	s.m = model(rng, ci, false, "a")
	return true


static func _asymptote(rng: Seeded, s: Dictionary) -> bool:
	# The graph's cards need a start above the asymptote (k > 0), to draw a curve that starts at k.
	var kinds := ["cool"] if s.rep == "graph" else ["cool", "rise"]
	var ci: int = rng.pick(of_kinds(kinds))
	s.m = model(rng, ci, true)
	var k: Q = s.m.k
	var c: Q = s.m.c
	if k.abs_q().eq(c) or start(s.m).eq(c) or start(s.m).sign() <= 0:
		return false
	if s.rep == "graph":
		# The start-at-k card starts clearly apart from the right card and above the asymptote.
		return k.to_float() >= 1.6 * c.to_float() and c.to_float() >= 0.15 * k.to_float()
	return true


static func _long_run(rng: Seeded, s: Dictionary) -> bool:
	var ci: int = rng.pick(of_kinds(["cool", "rise"]))
	s.m = model(rng, ci, true)
	var c: Q = s.m.c
	var st: Q = start(s.m)
	if st.sign() <= 0 or st.eq(c):
		return false
	s.say = "never" if rng.chance(0.5) else "meaning"
	if s.say == "never":
		# A level past the asymptote, on the far side from the start.
		var gap := c.to_float() * rng.int_in(10, 30) / 100.0
		var step := 100 if c.to_float() >= 500 else 1
		var lv := c.to_float() + (gap if s.m.k.sign() < 0 else -gap)
		lv = roundf(lv / step) * step
		if lv <= 0.0 or is_equal_approx(lv, c.to_float()):
			return false
		s.L = Q.new(int(lv))
		# The linear slip's time, for the claim that it gets there.
		var tl := linear_time(s.m, lv)
		if not (tl > 1.0 and tl < 200.0 and clear(tl)):
			return false
	return true


## A level strictly between the start and the asymptote (or above the start for growth),
## a whole number (a round one for large values), and when it is reached.
static func _level(rng: Seeded, s: Dictionary) -> bool:
	var ci: int = rng.pick(of_kinds(["cool", "rise", "grow", "decay"]))
	s.m = model(rng, ci, rng.chance(0.6))
	var m: Dictionary = s.m
	var st: float = start(m).to_float()
	var target: float
	if kind(s) == "grow":
		target = st * rng.int_in(130, 450) / 100.0
	else:
		target = m.c.to_float() + m.k.to_float() * rng.int_in(15, 85) / 100.0
	var step := NICE_STEP if absf(target) >= 200 else 1
	var lv := roundi(target / step) * step
	if lv <= 0 or lv == roundi(st) or lv == int(m.c.to_float()):
		return false
	s.L = Q.new(lv)
	var t := time_at(m, lv)
	s.tL = t
	if not is_finite(t) or t <= 0.5 or t > 60.0 or not clear(t):
		return false
	var tl := linear_time(m, lv)
	if not is_finite(tl) or tl <= 0.0 or not clear(tl):
		return false
	if s.ask == "whole-units-to-level":
		var f := t - floorf(t)
		if f < 0.1 or f > 0.9 or t < 3.1:
			return false
		# The slips' whole numbers differ from the key: rounded down is one less; the linear one
		# is checked in the views.
		if ceili(tl) == ceili(t) or ceili(tl) == floori(t) or ceili(tl) <= 0:
			return false
		# The values the table shows either side of the crossing are clear.
		return clear(value(m, floorf(t))) and clear(value(m, ceilf(t)))
	# The answer and the slips read differently.
	var vals: Array = [t, tl, t * 2.0, t / 2.0]
	var noc := _no_c_time(m, lv)
	if is_finite(noc) and noc > 0.0:
		vals.append(noc)
	return distinct(vals)


## The time with c left out: ka^t = L.
static func _no_c_time(m: Dictionary, lv: float) -> float:
	if m.c.is_zero():
		return NAN
	var ratio: float = lv / m.k.to_float()
	if ratio <= 0.0:
		return NAN
	return log(ratio) / log(factor(m))


static func _two(rng: Seeded, s: Dictionary) -> bool:
	s.story = rng.int_in(0, TWO.size() - 1)
	var form1 := "a" if rng.chance(0.6) else "e"
	var form2 := "a" if rng.chance(0.6) else "e"
	match s.story:
		0:
			var c := rng.int_in(15, 25)
			s.m = {"ctx": 0, "form": form1, "k": Q.new(rng.int_in(60, 80)), "c": Q.new(c)}
			s.m2 = {"ctx": 0, "form": form2, "k": Q.new(rng.int_in(35, 55)), "c": Q.new(c)}
			_set_factor(rng, s.m, 70, 88)
			_set_factor(rng, s.m2, 89, 97)
		1:
			s.m = {"ctx": 6, "form": form1, "k": Q.new(rng.int_in(4, 15) * 10), "c": Q.new(0)}
			s.m2 = {"ctx": 6, "form": form2, "k": Q.new(rng.int_in(20, 50) * 10), "c": Q.new(0)}
			_set_factor(rng, s.m, 110, 125)
			_set_factor(rng, s.m2, 102, 108)
		_:
			s.m = {"ctx": 7, "form": form1, "k": Q.new(rng.int_in(8, 20) * 100), "c": Q.new(0)}
			s.m2 = {"ctx": 7, "form": form2, "k": Q.new(rng.int_in(15, 40) * 100), "c": Q.new(rng.int_in(2, 8) * 100)}
			_set_factor(rng, s.m, 103, 112)
			_set_factor(rng, s.m2, 80, 95)
	if s.m.k.eq(s.m2.k):
		return false
	var t := meet(s)
	s.tL = t
	if not is_finite(t) or t < 2.0 or t > 40.0 or not clear(t):
		return false
	var f := t - floorf(t)
	if f < 0.05 or f > 0.95:
		return false
	var common := value(s.m, t)
	var vals: Array = [t, common, t * 2.0, t / 2.0]
	var noc := no_c_meet(s)
	if is_finite(noc) and noc > 0.0:
		vals.append(noc)
	if common > MAX_VALUE or not distinct(vals):
		return false
	# The fine table's bracket ends round to the answer's figures.
	var br := bracket(t)
	return Fmt.sf(br[0]) == Fmt.sf(t) and Fmt.sf(br[1]) == Fmt.sf(t)


static func _set_factor(rng: Seeded, m: Dictionary, lo: int, hi: int) -> void:
	var p := rng.int_in(lo, hi)
	if m.form == "a":
		m.a = Q.new(p, 100)
	else:
		# The continuous rate closest to the same factor, to 3 d.p.
		m.r = Q.new(roundi(log(p / 100.0) * 1000.0), 1000)
		if m.r.is_zero():
			m.r = Q.new(1 if p > 100 else -1, 1000)


## Where A(t) = B(t): a sign change of A − B on a fine grid from 0 to 60, then bisection.
## NAN unless there is exactly one.
static func meet(s: Dictionary) -> float:
	var d := func(t: float) -> float: return value(s.m, t) - value(s.m2, t)
	var found: Array = []
	var n := 1200
	var prev: float = d.call(0.0)
	for i in range(1, n + 1):
		var t := 60.0 * i / n
		var cur: float = d.call(t)
		if (prev < 0.0) != (cur < 0.0):
			found.append([60.0 * (i - 1) / n, t])
		prev = cur
	if found.size() != 1:
		return NAN
	var lo: float = found[0][0]
	var hi: float = found[0][1]
	var neg: bool = d.call(lo) < 0.0
	for i in 80:
		var mid := (lo + hi) / 2.0
		if (d.call(mid) < 0.0) == neg:
			lo = mid
		else:
			hi = mid
	return (lo + hi) / 2.0


## Where the varying parts alone are equal (both c's left out), or NAN.
static func no_c_meet(s: Dictionary) -> float:
	if s.m.c.is_zero() and s.m2.c.is_zero():
		return NAN
	var ratio: float = s.m2.k.to_float() / s.m.k.to_float()
	var lf := log(factor(s.m)) - log(factor(s.m2))
	if ratio <= 0.0 or lf == 0.0:
		return NAN
	return log(ratio) / lf


## A GDC table's fine bracket round t: one figure past the answer's 3 s.f.
static func bracket(t: float) -> Array:
	var e := floori(log(t) / log(10.0) + 1e-12)
	var st := pow(10.0, e - 3)
	var lo := floorf(t / st) * st
	return [lo, lo + st]


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
