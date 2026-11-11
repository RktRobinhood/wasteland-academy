class_name SolveExponentialSituation
extends RefCounted
## The `solve-exponential` situation (curriculum/question-types.json), for t1-solve-exponential
## (FAL-754): an exponential equation solved with logarithms. Two powers with different bases,
## an exponential to isolate first, and two growth models in a story. An exact answer (a quotient
## of two logs, or m ln r) can be asked on either paper, as no calculator is needed; a 3 s.f.
## answer is Paper 2, where every answer is kept clear of a rounding edge. The SymPy checker
## (tools/check_answers.py) finds each one again from the words.
##
## need.ask is the unknown (see SolveExponentialViews), need.rep the representation. generate()
## returns paper, ask, rep, ctx (a story or place) and shape, then by unknown:
##
##   two-bases-3sf, shift-base-exact, one-minus-exact
##     shift   a^(x + p) = b^x, p whole and either sign: x = p ln a/(ln b − ln a)
##     mirror  a^x = b^(c − x), c whole: x = c ln b/(ln a + ln b)
##     a, b, p, c   whole numbers;  x  the solution, a float
##   isolate-e-exact     k e^(mx) + d = c, with r = (c − d)/k: x = (1/m) ln r
##     root  r = a^m, so x = ln a;  over  r is no m-th power, so x = (ln r)/m
##     k, m, d, c, r, a  whole numbers
##   isolate-3sf         k e^(mx) + d = c (shape e, m a Q decimal) or k × a^x + d = c (shape base)
##   model-time-exact    A = A₀ e^(kt) reaches L: t = (1/k) ln(L/A₀);  A0, L whole, k a Q decimal
##   model-meet          A = A₀ e^(kt) and B = B₀ × g^t meet: t = ln(B₀/A₀)/(k − ln g)
##     A0, B0 whole, k and g Q decimals;  t  the meeting time, a float
##
## The clean limits below are the numbers behind the catalogue's constraints. The SymPy checker
## holds its own copy and fails on any breach.

const TRIES := 6000
const EXACT := ["shift-base-exact", "one-minus-exact", "isolate-e-exact", "model-time-exact"]
const BASES := [2, 3, 5, 6, 7]
const STORIES := 4
const PLACES := 6
## An answer is at least this far (a fraction of its last place) from a rounding edge.
const EDGE := 0.05
## The largest |x| a two-bases answer may have, exact or 3 s.f.
const MAX_X := 12.0
## The skill map's own examples, left out: 3^(x + 1) = 5^x, 2^x = 3^(1 − x), 5e^(2x) = 20 and
## P = 200e^(0.3t) reaching 1000.
const MAP_SHIFT := [3, 5, 1]
const MAP_MIRROR := [2, 3, 1]
const MAP_ISOLATE := [5, 2, 0, 20]
const MAP_MODEL := [200, 3, 1000]
## Rates in a model, as tenths and hundredths: k = RATES[i]/100.
const RATES := [5, 10, 20, 25, 40, 50]
const MEET_RATES := [20, 25, 30, 35, 40, 45, 50, 55, 60]
## A second model's factor each step, in hundredths.
const FACTORS := [105, 108, 110, 112, 115, 120, 125]
const STARTS := [12, 15, 20, 25, 30, 40, 50, 60, 80]
## Decimal rates in an isolated exponential, in tenths.
const POWERS := [2, 3, 4, 5, 6, 8, 12, 15, 25]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "two-bases-3sf")
	var rep: String = need.get("rep", "equation")
	var draws := SolveExponentialSituation.new()
	for i in TRIES:
		var paper: int = need.get("paper", 2) if ask in EXACT else 2
		var s := {"paper": paper, "ask": ask, "rep": rep, "ctx": rng.int_in(0, PLACES - 1), "shape": ""}
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
	if n < 1 or b < 2:
		return false
	while n % b == 0:
		n /= b
	return n == 1


## Whether n is a whole power (square, cube, ...) of a smaller whole number.
static func perfect_power(n: int) -> bool:
	for b in range(2, 40):
		var p := b * b
		while p <= n:
			if p == n:
				return true
			p *= b
	return false


## A 3 s.f. value clear of a rounding edge, whose third figure isn't a zero (so its 2 s.f. trap
## reads differently).
static func clean(x: float) -> bool:
	if not is_finite(x) or x == 0.0:
		return false
	var a := absf(x) / pow(10.0, floori(log(absf(x)) / log(10.0) + 1e-12))
	return Answer.rounds_clearly(x, EDGE) and not Fmt.sf(a).ends_with("0")


## A log rounded to 2 d.p., as a student rounds it too early.
static func early(v: float) -> float:
	return roundf(v * 100.0) / 100.0


## An early-rounded result is off in the third figure only: its first two match the answer's,
## its third doesn't, and it sits clear of an edge itself.
static func third_off(early_x: float, x: float) -> bool:
	return Fmt.sf(early_x, 2) == Fmt.sf(x, 2) and Fmt.sf(early_x) != Fmt.sf(x) and Answer.rounds_clearly(early_x, EDGE)


# ── Two bases ────────────────────────────────────────────────

## The solution of a^(x + p) = b^x or a^x = b^(c − x).
static func two_bases(s: Dictionary) -> float:
	var la := log(float(s.a))
	var lb := log(float(s.b))
	if s.shape == "shift":
		return s.p * la / (lb - la)
	return s.c * lb / (la + lb)


## The same with the logs rounded to 2 d.p. first.
static func two_bases_early(s: Dictionary) -> float:
	var la := early(log(float(s.a)))
	var lb := early(log(float(s.b)))
	if s.shape == "shift":
		return s.p * la / (lb - la)
	return s.c * lb / (la + lb)


static func _draw_bases(rng: Seeded, s: Dictionary) -> void:
	s.a = rng.pick(BASES)
	s.b = rng.pick(BASES)


static func _two_bases_3sf(rng: Seeded, s: Dictionary) -> bool:
	_draw_bases(rng, s)
	s.shape = rng.pick(["shift", "shift", "mirror"])
	s.p = ExtensionViews.nonzero(rng, -3, 3)
	s.c = rng.int_in(1, 3)
	if s.a == s.b or [s.a, s.b, s.p] == MAP_SHIFT and s.shape == "shift" or [s.a, s.b, s.c] == MAP_MIRROR and s.shape == "mirror":
		return false
	s.x = two_bases(s)
	if absf(s.x) < 0.2 or absf(s.x) > MAX_X or not clean(s.x) or not third_off(two_bases_early(s), s.x):
		return false
	if s.rep == "graph":
		var y := pow(float(s.b), s.x)
		return s.x > -6.0 and s.x < 8.0 and y >= 1.5 and y <= 600.0
	return true


## a^(x + p) = b^x with a < b, or a^(x − p) = b^x with a > b: either way x = ln(a^p)/ln(ratio),
## with the ratio above 1, so x is positive. a^p is at most 1000, and x at most MAX_X: close
## bases with a big shift (6^x = 7^(x − 3)) put the root near 38, no sensible exam answer.
static func _shift_base_exact(rng: Seeded, s: Dictionary) -> bool:
	_draw_bases(rng, s)
	s.shape = "shift"
	s.p = rng.int_in(1, 3)
	if s.a == s.b or ipow(s.a, s.p) > 1000:
		return false
	if s.a > s.b:
		s.p = -s.p
	if [s.a, s.b, s.p] == MAP_SHIFT:
		return false
	s.x = two_bases(s)
	return s.x > 0.0 and s.x <= MAX_X


## a^x = b^(c − x): x = ln(b^c)/ln(ab), with b^c at most 1000.
static func _one_minus_exact(rng: Seeded, s: Dictionary) -> bool:
	_draw_bases(rng, s)
	s.shape = "mirror"
	s.c = rng.int_in(1, 3)
	if s.a == s.b or ipow(s.b, s.c) > 1000 or [s.a, s.b, s.c] == MAP_MIRROR:
		return false
	s.x = two_bases(s)
	return true


# ── Isolate the exponential ──────────────────────────────────

## k e^(mx) + d = c: e^(mx) = r. root has r = a^m, so x = ln a; over has r no m-th power.
static func _isolate_e_exact(rng: Seeded, s: Dictionary) -> bool:
	s.shape = rng.pick(["root", "root", "over"])
	s.k = rng.int_in(2, 9)
	s.d = 0 if rng.chance(0.5) else ExtensionViews.nonzero(rng, -12, 15)
	if s.shape == "root":
		s.m = rng.int_in(1, 3)
		s.a = rng.int_in(2, 6)
		s.r = ipow(s.a, s.m)
		if s.r > 125:
			return false
	else:
		s.m = rng.int_in(2, 5)
		s.r = rng.int_in(2, 30)
		var root := roundi(pow(float(s.r), 1.0 / s.m))
		if ipow(root, s.m) == s.r or ipow(root + 1, s.m) == s.r:
			return false
	s.c = s.k * s.r + s.d
	if [s.k, s.m, s.d, s.c] == MAP_ISOLATE or s.c <= 0:
		return false
	s.x = log(float(s.r)) / s.m
	return true


## k e^(mx) + d = c (shape e, m in tenths) or k × a^x + d = c (shape base). r = (c − d)/k.
static func _isolate_3sf(rng: Seeded, s: Dictionary) -> bool:
	s.shape = rng.pick(["e", "e", "base"])
	s.k = rng.int_in(2, 9)
	s.d = 0 if rng.chance(0.4) else ExtensionViews.nonzero(rng, -10, 20)
	s.c = rng.int_in(maxi(s.d, 0) + s.k + 3, 300)
	s.r = Q.new(s.c - s.d, s.k)
	var r: float = s.r.to_float()
	if r < 1.3:
		return false
	if s.shape == "e":
		s.m = Q.new(rng.pick(POWERS), 10)
		s.a = 0
		s.x = log(r) / s.m.to_float()
		s.early = early(log(r)) / s.m.to_float()
	else:
		s.m = Q.new(1)
		s.a = rng.int_in(2, 7)
		if s.r.is_int() and is_power(int(s.r.to_float()), s.a):
			return false
		s.x = log(r) / log(float(s.a))
		s.early = early(log(r)) / early(log(float(s.a)))
	if s.x < 0.3 or s.x > 10.0 or not clean(s.x) or not third_off(s.early, s.x):
		return false
	return s.rep != "graph" or s.c <= 200


# ── Models ───────────────────────────────────────────────────

## A = A₀ e^(kt) reaches L = A₀ × ratio: t = (1/k) ln(ratio). The ratio is whole, or a half.
static func _model_time_exact(rng: Seeded, s: Dictionary) -> bool:
	s.story = rng.int_in(0, STORIES - 1)
	s.A0 = rng.pick(STARTS)
	s.kk = Q.new(rng.pick(RATES), 100)
	s.ratio = Q.new(rng.int_in(2, 9)) if rng.chance(0.75) else Q.new(rng.pick([3, 5, 7]), 2)
	var L: Q = s.ratio.mul(s.A0)
	if not L.is_int():
		return false
	s.L = int(L.to_float())
	if [s.A0, roundi(s.kk.to_float() * 10.0), s.L] == MAP_MODEL:
		return false
	s.t = log(s.ratio.to_float()) / s.kk.to_float()
	return s.t >= 1.0 and s.t <= 60.0


## A = A₀ e^(kt) starts smaller and grows faster than B = B₀ × g^t, so they meet once.
static func model_meet(s: Dictionary) -> float:
	return log(float(s.B0) / s.A0) / (s.kk.to_float() - log(s.g.to_float()))


static func _model_meet(rng: Seeded, s: Dictionary) -> bool:
	s.story = rng.int_in(0, STORIES - 1)
	s.A0 = rng.int_in(8, 40)
	s.B0 = rng.int_in(s.A0 + 10, 200)
	s.kk = Q.new(rng.pick(MEET_RATES), 100)
	s.g = Q.new(rng.pick(FACTORS), 100)
	var k: float = s.kk.to_float()
	var lg := log(s.g.to_float())
	# The percentage slip, k − (g − 1), stays positive, so its time is a time too.
	if k - lg < 0.05 or k - (s.g.to_float() - 1.0) < 0.03:
		return false
	s.t = model_meet(s)
	s.early = early(log(float(s.B0) / s.A0)) / (k - early(lg))
	return s.t >= 2.0 and s.t <= 40.0 and clean(s.t) and third_off(s.early, s.t)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
