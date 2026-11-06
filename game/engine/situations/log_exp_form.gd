class_name LogExpFormSituation
extends RefCounted
## The `log-exp-form` situation (curriculum/question-types.json), for t1-log-exp-form (FAL-753): a
## log and its exponential form, and the log scales of the wasteland. Paper 1 changes form and
## evaluates exactly, with Q; Paper 2 works a scale or a log model in floats, as a GDC does, and
## every answer is kept clear of a 3 s.f. rounding edge. The SymPy checker
## (tools/check_answers.py) finds each one again from the words.
##
## need.ask is the unknown (see LogExpFormViews), need.rep the representation. generate() returns:
##   paper, ask, rep, ctx   the paper, the unknown, the representation, the story's place and things
##
## Paper 1, by unknown:
##   b, e, x   x = b^e, Q e and x, for a form to change or a value to find. shape is whole,
##             negative or fraction (an e/ln shape has b = 0, and a base-10 log b = 10)
##   val       the exact answer, Q
##   the rest are the draw's own numbers, named in each function
##
## Paper 2. A scale is y = d + A log(x × K), with
##   scale     HOWL, RUMBLE, GLARE, RAD or BITE
##   A, d      Q, the multiplier and the constant;  nat  true for a natural log
##   ten, over K as written: x × 10^ten (a power of ten) or x/over
##   x         an amount, {"m": Q, "k": int}, m × 10^k
##   y, y2     readings, Q in tenths (or found, as floats, where they are the answer)
##   rows      the other amounts of a table
##   m         a factor;  delta  a rise in the reading
## A model is h = p + q ln(rt + 1): p, q, r (Q), t or T (the time, or the level).
##
## The clean limits below are the numbers behind the catalogue's constraints. The SymPy checker
## holds its own copy and fails on any breach.

const TRIES := 8000
const PAPER_1 := ["to-exponential-form", "to-log-form", "solve-exp-as-log", "value-whole-power", "value-negative-power",
	"value-fractional-power", "log-of-power", "power-of-log", "solve-log-x", "solve-log-linear", "solve-log-square", "solve-log-base", "no-real-log"]
const HOWL := 0
const RUMBLE := 1
const GLARE := 2
const RAD := 3
const BITE := 4
const PLACES := 6
const MODELS := 4
const BASES := [2, 3, 4, 5, 6, 7, 8, 9, 10]
## Bases that are powers of a prime, with a smaller power of it to take the log of: [p, j].
const FAMILIES := [[2, 2], [2, 3], [2, 4], [3, 2], [3, 3], [5, 2]]
const TOP := 1000
## Factors an amount is multiplied by.
const FACTORS := ["3/2", "5/2", "2", "3", "4", "5", "6", "7", "8"]
## An answer is at least this far (a fraction of its last place) from a rounding edge.
const EDGE := 0.05
## A power of the base is at least this far from a whole number, so the answer needs rounding.
const WHOLE_GAP := 0.02
## Inside this an amount is written as a number, outside it in standard form.
const PLAIN_LOW := 0.01
const PLAIN_HIGH := 100000.0


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "to-exponential-form")
	var rep: String = need.get("rep", "equation")
	var draws := LogExpFormSituation.new()
	for i in TRIES:
		var s := {"paper": 1 if ask in PAPER_1 else 2, "ask": ask, "rep": rep, "ctx": rng.int_in(0, PLACES - 1), "shape": ""}
		if draws.call("_" + ask.replace("-", "_"), rng, s):
			return s
	return {}


# ── Small tools ──────────────────────────────────────────────

static func ipow(b: int, e: int) -> int:
	var r := 1
	for i in e:
		r *= b
	return r


static func is_power(n: int, b: int) -> bool:
	if n < 1:
		return false
	while n % b == 0:
		n /= b
	return n == 1


static func squarefree(n: int) -> bool:
	for p in range(2, 12):
		if n % (p * p) == 0:
			return false
	return true


## b^e for a whole e, either sign.
static func qpow(b: int, e: int) -> Q:
	return Q.new(ipow(b, e)) if e >= 0 else Q.new(1, ipow(b, -e))


## The largest e with b^e at most TOP.
static func top_power(b: int) -> int:
	var e := 0
	while ipow(b, e + 1) <= TOP:
		e += 1
	return e


## b, e and x = b^e. A fraction's base is a power of a prime, so the root comes out.
static func _power(rng: Seeded, s: Dictionary, shape: String) -> bool:
	s.shape = shape
	match shape:
		"whole":
			s.b = rng.pick(BASES)
			var e := rng.int_in(2, top_power(s.b))
			s.e = Q.new(e)
			s.x = qpow(s.b, e)
		"negative":
			s.b = rng.pick(BASES)
			var e := rng.int_in(1, top_power(s.b))
			s.e = Q.new(-e)
			s.x = qpow(s.b, -e)
		"fraction":
			var f: Array = rng.pick(FAMILIES)
			var i := rng.int_in(1, 6)
			if i % f[1] == 0 or ipow(f[0], i) > 200:
				return false
			s.b = ipow(f[0], f[1])
			s.e = Q.new(i, f[1])
			s.x = Q.new(ipow(f[0], i))
	return true


# ── Paper 1: changing form ───────────────────────────────────

static func _to_exponential_form(rng: Seeded, s: Dictionary) -> bool:
	return _power(rng, s, rng.pick(["whole", "negative", "fraction"]))


## Negative and fractional powers: a whole power is the exp-log-pair's write-log-form.
static func _to_log_form(rng: Seeded, s: Dictionary) -> bool:
	return _power(rng, s, rng.pick(["negative", "fraction"]))


## a^x = r, or k × a^x = kr, with r no power of a. b is 0 for e, and a story is a whole base.
static func _solve_exp_as_log(rng: Seeded, s: Dictionary) -> bool:
	var words: bool = s.rep == "words"
	s.b = rng.pick([2, 3, 5, 6, 7]) if words else rng.pick([0, 2, 3, 5, 6, 7, 10])
	s.r = rng.int_in(3, 40)
	s.k = rng.int_in(2, 6) if words or rng.chance(0.5) else 1
	s.shape = "plain" if s.k == 1 else "scaled"
	return s.b == 0 or not is_power(s.r, s.b)


# ── Paper 1: exact values ────────────────────────────────────

static func _value_whole_power(rng: Seeded, s: Dictionary) -> bool:
	if not _power(rng, s, "whole"):
		return false
	s.val = s.e
	return true


static func _value_negative_power(rng: Seeded, s: Dictionary) -> bool:
	if not _power(rng, s, "negative"):
		return false
	s.val = s.e
	return true


## family  log_(p^j) p^i;  root  log_a of √a, a√a or 1/√a.
static func _value_fractional_power(rng: Seeded, s: Dictionary) -> bool:
	if rng.chance(0.6):
		if not _power(rng, s, "fraction"):
			return false
		s.shape = "family"
		s.val = s.e
		return true
	s.shape = rng.pick(["half", "more", "under"])
	s.b = rng.pick([2, 3, 5, 6, 7, 10])
	s.val = {"half": Q.new(1, 2), "more": Q.new(3, 2), "under": Q.new(-1, 2)}[s.shape]
	return true


## log_b(b^k), with b = 0 for ln(e^k). k is whole, negative or a fraction.
static func _log_of_power(rng: Seeded, s: Dictionary) -> bool:
	s.b = rng.pick([0, 2, 3, 5, 7, 10])
	s.shape = rng.pick(["whole", "negative", "fraction"])
	match s.shape:
		"whole":
			s.k = Q.new(rng.int_in(2, 9))
		"negative":
			s.k = Q.new(-rng.int_in(1, 9))
		"fraction":
			s.k = Q.new(rng.int_in(1, 9), rng.int_in(2, 5))
			if s.k.is_int():
				return false
	s.val = s.k
	return true


## plain  b^(log_b x);  minus  b^(−log_b x);  times  b^(k log_b x), which needs the power law.
static func _power_of_log(rng: Seeded, s: Dictionary) -> bool:
	s.b = rng.pick([0, 2, 3, 5, 7, 10])
	s.shape = rng.pick(["plain", "plain", "minus", "times"])
	s.x = Q.new(rng.int_in(2, 15))
	s.k = rng.int_in(2, 3)
	match s.shape:
		"plain":
			s.val = s.x
		"minus":
			s.val = Q.new(1).div(s.x)
		"times":
			s.x = Q.new(rng.int_in(2, 6))
			s.val = Q.new(ipow(s.x.n, s.k))
	return s.x.n != s.b


# ── Paper 1: solving ─────────────────────────────────────────

## log_b x = c. b is 0 for ln x = c, whose answer stays a power of e.
static func _solve_log_x(rng: Seeded, s: Dictionary) -> bool:
	if s.rep == "equation" and rng.chance(0.2):
		s.b = 0
		s.shape = "natural"
		s.e = Q.new(rng.int_in(-4, 5))
		return not s.e.is_zero()
	return _power(rng, s, rng.pick(["whole", "negative", "fraction"]))


## log_b(px + q) = c, so x = (b^c − q)/p.
static func _solve_log_linear(rng: Seeded, s: Dictionary) -> bool:
	s.b = rng.pick(BASES)
	s.c = rng.int_in(-1, top_power(s.b))
	s.p = rng.int_in(1, 5)
	s.q = ExtensionViews.nonzero(rng, -9, 9)
	s.val = qpow(s.b, s.c).sub(Q.new(s.q)).div(Q.new(s.p))
	return not s.val.is_zero()


## log_b(x² − k) = c for x > √k, so x = √(b^c + k). b is 0 for ln, with c = 0. A graph has c = 0
## and a whole √k, as its asymptote is drawn.
static func _solve_log_square(rng: Seeded, s: Dictionary) -> bool:
	s.b = rng.pick([0, 0, 2, 3, 5, 10])
	if s.rep == "graph":
		s.c = 0
		s.h = rng.pick([2, 3, 5, 6, 7])
		s.k = s.h * s.h
	else:
		s.c = 0 if s.b == 0 else rng.int_in(1, 2)
		s.k = rng.int_in(2, 30)
	s.r = (1 if s.b == 0 else ipow(s.b, s.c)) + s.k
	return squarefree(s.r) and s.r >= 3


## log_x n = c, so x = n^(1/c). x is whole, or a unit fraction for a negative power. A graph is
## y = log_b x through (n, c), and c is positive there.
static func _solve_log_base(rng: Seeded, s: Dictionary) -> bool:
	if not _power(rng, s, rng.pick(["whole", "fraction"] if s.rep == "graph" else ["whole", "fraction", "negative"])):
		return false
	if s.shape == "negative":
		# log_x n = −c: the base is 1/b and the number b^c.
		s.val = Q.new(1, s.b)
		s.c = s.e
		s.n = Q.new(ipow(s.b, -int(s.e.to_float())))
		return s.n.to_float() <= 200.0 and s.e.to_float() <= -1.0
	s.val = Q.new(s.b)
	s.c = s.e
	s.n = s.x
	return s.rep != "graph" or (s.n.to_float() <= 64.0 and s.c.to_float() >= 1.0)


## Four logs, one of them unlike the rest. none: which has no real value (the argument is zero or
## negative). real: which has one (the others have zero or a negative argument).
static func _no_real_log(rng: Seeded, s: Dictionary) -> bool:
	s.shape = rng.pick(["none", "real"])
	s.b = rng.pick([2, 3, 4, 5, 10])
	s.j = rng.int_in(1, 2)
	s.top = ipow(s.b, s.j)
	s.gap = rng.int_in(1, 8)
	s.neg = rng.int_in(2, 30)
	return true


# ── Paper 2: scales ──────────────────────────────────────────

static func _set_scale(rng: Seeded, s: Dictionary, which: int) -> void:
	s.scale = which
	s.nat = which == RAD
	s.A = Q.new(1)
	s.d = Q.new(0)
	s.ten = 0
	s.over = 1
	match which:
		HOWL:
			s.A = Q.new(int(rng.pick([8, 12, 15, 20])))
			s.ten = rng.pick([7, 8, 9, 11])
		RUMBLE:
			s.d = Q.new(rng.int_in(1, 3))
		GLARE:
			s.A = Q.new(rng.pick([-2, -3, -4]))
			s.d = Q.new(rng.int_in(6, 9))
		RAD:
			s.A = Q.new(int(rng.pick([5, 6, 8, 12])))
			s.over = rng.pick([10, 20, 25, 40, 50])
		BITE:
			s.A = Q.new(-1)


## The log of the scale, in floats.
static func lg(s: Dictionary, v: float) -> float:
	return log(v) if s.nat else log(v) / log(10.0)


## The base of the scale's log: what undoes it.
static func base(s: Dictionary) -> float:
	return exp(1.0) if s.nat else 10.0


static func inner(s: Dictionary, x: float) -> float:
	return x * pow(10.0, s.ten) / s.over


## y = d + A log(x × K)
static func reading(s: Dictionary, x: float) -> float:
	return s.d.to_float() + s.A.to_float() * lg(s, inner(s, x))


## What the log of the inside comes to at a reading.
static func power_at(s: Dictionary, y: float) -> float:
	return (y - s.d.to_float()) / s.A.to_float()


## The amount at a reading.
static func amount(s: Dictionary, y: float) -> float:
	return pow(base(s), power_at(s, y)) / (pow(10.0, s.ten) / s.over)


## What a rise of dy in the reading multiplies the amount by.
static func factor(s: Dictionary, dy: float) -> float:
	return pow(base(s), dy / s.A.to_float())


static func value(x: Dictionary) -> float:
	return x.m.to_float() * pow(10.0, x.k)


## An amount with two figures, drawn so its reading suits the scale.
static func _amount(rng: Seeded, s: Dictionary) -> Dictionary:
	var m := Q.new(rng.int_in(11, 99), 10)
	match s.scale:
		HOWL:
			return {"m": m, "k": rng.int_in(1 - s.ten, 5 - s.ten)}
		RUMBLE:
			return {"m": m, "k": rng.int_in(0, 4)}
		GLARE:
			return {"m": m, "k": rng.int_in(-2, 2)}
		RAD:
			return {"m": Q.new(s.over * rng.int_in(3, 40), 100), "k": 2}
	return {"m": m, "k": rng.int_in(-9, -2)}


## A reading in tenths, near the one an amount gives.
static func _reading_of(s: Dictionary, x: Dictionary) -> Q:
	return Q.new(roundi(reading(s, value(x)) * 10.0), 10)


## A 3 s.f. value that is clear of an edge, and that isn't its own 2 s.f. trap: its third figure
## isn't a zero, however big the value is.
static func clean(x: float) -> bool:
	var a := x / pow(10.0, floori(log(x) / log(10.0) + 1e-12))
	return Answer.rounds_clearly(x, EDGE) and not Fmt.sf(a).ends_with("0")


## The power of the base isn't whole, so the amount really needs rounding.
static func unround(u: float) -> bool:
	return absf(u - roundf(u)) >= WHOLE_GAP


static func _reading_from_value(rng: Seeded, s: Dictionary) -> bool:
	_set_scale(rng, s, rng.pick([HOWL, RUMBLE, GLARE, RAD]))
	s.x = _amount(rng, s)
	s.rows = [_amount(rng, s), _amount(rng, s)]
	s.y = reading(s, value(s.x))
	return s.y > 0.0 and clean(s.y) and s.rows.all(func(r): return reading(s, value(r)) > 0.0 and not value(r) == value(s.x))


## The first amount is a power of ten, so its reading is exact and can be given.
static func _start_power(rng: Seeded, s: Dictionary) -> bool:
	_set_scale(rng, s, rng.pick([HOWL, RUMBLE, GLARE]))
	s.x = {"m": Q.new(1), "k": rng.int_in(-s.ten + 1, -s.ten + 4) if s.scale == HOWL else rng.pick([-1, 1, 2, 3])}
	s.y = s.d.add(s.A.mul(Q.new(s.x.k + s.ten)))
	return s.y.sign() > 0


static func _reading_after_multiple(rng: Seeded, s: Dictionary) -> bool:
	if not _start_power(rng, s):
		return false
	s.m = Answer.parse_number(rng.pick(FACTORS)).q
	s.y2 = s.y.to_float() + s.A.to_float() * lg(s, s.m.to_float())
	return s.y2 > 0.0 and clean(s.y2)


static func _value_from_reading(rng: Seeded, s: Dictionary) -> bool:
	_set_scale(rng, s, RAD if s.rep == "graph" else rng.pick([HOWL, RUMBLE, GLARE, RAD]))
	s.y = _reading_of(s, _amount(rng, s))
	s.rows = [_reading_of(s, _amount(rng, s)), _reading_of(s, _amount(rng, s))]
	var x := amount(s, s.y.to_float())
	return s.y.sign() > 0 and clean(x) and unround(power_at(s, s.y.to_float())) and s.rows.all(func(r): return r.sign() > 0 and not r.eq(s.y))


static func _acid_reading(rng: Seeded, s: Dictionary) -> bool:
	_set_scale(rng, s, BITE)
	s.x = _amount(rng, s)
	s.rows = [_amount(rng, s), _amount(rng, s)]
	s.y = reading(s, value(s.x))
	return clean(s.y) and not s.x.m.eq(1) and s.rows.all(func(r): return value(r) != value(s.x))


static func _acid_value(rng: Seeded, s: Dictionary) -> bool:
	_set_scale(rng, s, BITE)
	s.y = _reading_of(s, _amount(rng, s))
	s.rows = [_reading_of(s, _amount(rng, s)), _reading_of(s, _amount(rng, s))]
	return clean(amount(s, s.y.to_float())) and unround(s.y.to_float()) and s.rows.all(func(r): return not r.eq(s.y))


## Two readings, the second belonging to the larger amount; a table has a third, not asked about.
static func _ratio_two_readings(rng: Seeded, s: Dictionary) -> bool:
	_set_scale(rng, s, rng.pick([HOWL, RUMBLE, GLARE, RAD, BITE]))
	s.y = _reading_of(s, _amount(rng, s))
	s.y2 = _reading_of(s, _amount(rng, s))
	s.rows = [_reading_of(s, _amount(rng, s))]
	if s.y.sign() <= 0 or s.y2.sign() <= 0 or s.rows[0].sign() <= 0 or s.rows[0].eq(s.y) or s.rows[0].eq(s.y2):
		return false
	if amount(s, s.y.to_float()) > amount(s, s.y2.to_float()):
		var y = s.y
		s.y = s.y2
		s.y2 = y
	var u: float = s.y2.sub(s.y).to_float() / s.A.to_float()
	var f: float = factor(s, s.y2.sub(s.y).to_float())
	return unround(u) and f >= 1.2 and f <= 2.0e7 and clean(f)


static func _rise_for_factor(rng: Seeded, s: Dictionary) -> bool:
	_set_scale(rng, s, rng.pick([HOWL, GLARE, RAD]))
	s.m = Q.new(rng.int_in(2, 30)) if rng.chance(0.7) else Answer.parse_number(rng.pick(FACTORS)).q
	return not s.m.eq(1) and clean(absf(s.A.to_float()) * lg(s, s.m.to_float())) and unround(lg(s, s.m.to_float()))


## A rise in the reading from a known amount. A falling reading on the Glare class is a brighter beacon.
static func _value_after_steps(rng: Seeded, s: Dictionary) -> bool:
	if not _start_power(rng, s):
		return false
	s.delta = Q.new(rng.int_in(3, 40), 2 if s.scale == GLARE else 1) if s.scale != RUMBLE else Q.new(rng.int_in(3, 19), 10)
	var u: float = s.delta.to_float() / s.A.to_float()
	s.y2 = s.y.add(s.delta)
	return unround(u) and absf(u) <= 2.5 and clean(value(s.x) * factor(s, s.delta.to_float()))


static func _percent_rise(rng: Seeded, s: Dictionary) -> bool:
	_set_scale(rng, s, rng.pick([HOWL, RUMBLE, RAD]))
	s.delta = Q.new(rng.int_in(2, 9), 10) if s.scale == RUMBLE else Q.new(rng.int_in(1, 12))
	s.y = Q.new(rng.int_in(4, 12) * int(absf(s.A.to_float())), 2) if s.scale != RUMBLE else Q.new(rng.int_in(25, 70), 10)
	var f: float = factor(s, s.delta.to_float())
	return f >= 1.2 and f <= 9.0 and clean(100.0 * (f - 1.0)) and clean(100.0 * f) and unround(lg(s, f))


## The multiplier is hidden: k = y ÷ log(x × K). A table has a second row, from the same k.
static func _find_scale_constant(rng: Seeded, s: Dictionary) -> bool:
	_set_scale(rng, s, rng.pick([HOWL, RAD]))
	s.x = _amount(rng, s)
	var hidden: float = rng.int_in(70, 240) / 10.0
	s.y = Q.new(roundi(hidden * lg(s, inner(s, value(s.x))) * 10.0), 10)
	s.rows = [_amount(rng, s)]
	if s.y.sign() <= 0:
		return false
	s.found = s.y.to_float() / lg(s, inner(s, value(s.x)))
	return clean(s.found) and value(s.rows[0]) != value(s.x) and inner(s, value(s.rows[0])) > 1.5 and inner(s, value(s.x)) > 1.5


# ── Paper 2: a model in time ─────────────────────────────────

static func _set_model(rng: Seeded, s: Dictionary) -> void:
	s.model = rng.int_in(0, MODELS - 1)
	s.p = Q.new(rng.int_in(2, 12), 2)
	s.q = Q.new(rng.int_in(3, 12), 2)
	s.r = Q.new(rng.int_in(1, 4))


## h = p + q ln(rt + 1)
static func level(s: Dictionary, t: float) -> float:
	return s.p.to_float() + s.q.to_float() * log(s.r.to_float() * t + 1.0)


static func time_to(s: Dictionary, h: float) -> float:
	return (exp((h - s.p.to_float()) / s.q.to_float()) - 1.0) / s.r.to_float()


static func _model_value(rng: Seeded, s: Dictionary) -> bool:
	_set_model(rng, s)
	s.t = rng.int_in(2, 30)
	s.rows = [s.t + rng.int_in(2, 8), s.t + rng.int_in(9, 20)]
	return clean(level(s, s.t))


static func _model_time(rng: Seeded, s: Dictionary) -> bool:
	_set_model(rng, s)
	s.T = Q.new(rng.int_in(4, 90) * 2, 10).add(s.p)
	var t := time_to(s, s.T.to_float())
	return t >= 1.0 and t <= 120.0 and clean(t) and unround(s.T.sub(s.p).div(s.q).to_float())


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
