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
## t1-ext-common-base (FAL-780) asks the same situation with both sides powers of one prime t, so
## the exponents can be equated and x is a whole number or a fraction (x, a Q):
##   whole-power, reciprocal-power   b^x = N or b^x = 1/N, with N = b^j: x = j or −j
##   fraction-power                  A^x = R, A = t^i, R = t^j: x = j/i
##   linear-exponents, meet-on-graph A^(x + c) = B^(kx + e), A = t^i, B = t^j:
##                                   i(x + c) = j(kx + e), so x = (je − ic)/(i − jk); k = 1 on a graph
##
## t1-ext-hidden-quadratic (FAL-779) asks the same situation as a b^(2x) + B b^x + C = 0, a quadratic in
## u = b^x whose roots u (the Array u, of Q) are drawn first, so B and C are whole numbers:
##   two-powers       both roots whole powers of b (or one is 1/b, with a = b): x, an Array of two Q
##   reject-negative  a power b^m and a negative −r, r = b^k: x = [m], k the slip's
##   zero-root        a b^(2x) − c b^x = 0 (or = c b^x): u = 0 and c/a = b^m, x = [m]
##   exact-ln         e^(2x) + Be^x + C = 0, roots p and q from 3 to 9: x = ln p, ln q
##   exact-log-base   a root r that is no power of b and a negative −s: x = ln r/ln b
##   solution-count   roots two, double, mixed or none (shape): n, the number of real solutions
## b is 0 for e; sq writes b^(2x) as (b²)^x; a is the leading coefficient.
##
## The clean limits below are the numbers behind the catalogue's constraints. The SymPy checker
## holds its own copy and fails on any breach.

const TRIES := 6000
const EXACT := ["shift-base-exact", "one-minus-exact", "isolate-e-exact", "model-time-exact"]
## t1-ext-common-base's unknowns: exact, and Paper 1 unless a calculator method asks for Paper 2.
const COMMON := ["whole-power", "reciprocal-power", "fraction-power", "linear-exponents", "meet-on-graph"]
const CB_BASES := [2, 3, 4, 5, 6, 7, 9, 10]
## t1-ext-hidden-quadratic's unknowns: exact, Paper 1 unless the GDC's graph asks for Paper 2.
const HIDDEN := ["two-powers", "reject-negative", "zero-root", "exact-ln", "exact-log-base", "solution-count"]
const HQ_BASES := [2, 3, 4, 5]
## The skill map's examples, as [b, u₁, u₂] (b = 0 for e), left out.
const MAP_HIDDEN := [[2, 2, 4], [0, 2, 3], [3, 1, 3]]
const PRIMES := [2, 3, 5]
## The skill map's example, 2^x = 32, left out.
const MAP_WHOLE := [2, 5]
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
		if ask in COMMON or ask in HIDDEN:
			paper = need.get("paper", 1)
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


# ── A common base (t1-ext-common-base) ──────────────────────

## b^x = N with N = b^j a whole power: j from 2, N at most 1000, and N ÷ b never j itself.
static func _whole_power(rng: Seeded, s: Dictionary) -> bool:
	s.b = rng.pick(CB_BASES)
	s.j = rng.int_in(2, 9)
	s.N = ipow(s.b, s.j)
	if s.N > 1000 or [s.b, s.j] == MAP_WHOLE or s.N / s.b == s.j:
		return false
	s.x = Q.new(s.j)
	return true


static func _reciprocal_power(rng: Seeded, s: Dictionary) -> bool:
	if not _whole_power(rng, s):
		return false
	s.x = Q.new(-s.j)
	return true


## A^x = R: A = t^i is 4, 8, 9, 25 or 27, R = t^j at most 243, and j/i is not whole.
static func _fraction_power(rng: Seeded, s: Dictionary) -> bool:
	s.t = rng.pick(PRIMES)
	s.i = rng.int_in(2, 3)
	s.j = rng.int_in(1, 5)
	s.A = ipow(s.t, s.i)
	s.R = ipow(s.t, s.j)
	if s.j % s.i == 0 or s.A > 27 or s.R > 243:
		return false
	s.x = Q.new(s.j, s.i)
	return true


## A^(x + c) = B^(kx + e): A = t^i and B = t^j with i ≠ j and no common factor, both at most 81.
## D = i − jk is from −7 to 7 and not 0, and x = (je − ic)/D is not 0. The slip that multiplies only
## the x terms gives (e − c)/D, which must differ; on a graph (k = 1) x is whole, from −3 to 4, and
## the curves cross at a height from 2 to 600.
static func _linear_exponents(rng: Seeded, s: Dictionary) -> bool:
	var graph: bool = s.ask == "meet-on-graph"
	s.t = rng.pick(PRIMES)
	s.i = rng.int_in(1, 4)
	s.j = rng.int_in(1, 4)
	s.k = 1 if graph else rng.int_in(1, 3)
	s.c = ExtensionViews.nonzero(rng, -3, 3)
	s.e = ExtensionViews.nonzero(rng, -3, 3)
	if s.i == s.j or Q.gcd(s.i, s.j) != 1 or ipow(s.t, maxi(s.i, s.j)) > 81:
		return false
	s.A = ipow(s.t, s.i)
	s.B = ipow(s.t, s.j)
	var D: int = s.i - s.j * s.k
	var top: int = s.j * s.e - s.i * s.c
	if D == 0 or absi(D) > 7 or top == 0 or (s.e - s.c) == top:
		return false
	s.x = Q.new(top, D)
	if graph:
		if not s.x.is_int() or s.x.to_float() < -3.0 or s.x.to_float() > 4.0:
			return false
		var h: int = s.i * (int(s.x.to_float()) + s.c)
		s.y = Q.new(ipow(s.t, h)) if h >= 0 else Q.new(1, ipow(s.t, -h))
		return s.y.to_float() >= 2.0 and s.y.to_float() <= 600.0
	return true


static func _meet_on_graph(rng: Seeded, s: Dictionary) -> bool:
	return _linear_exponents(rng, s)


# ── A hidden quadratic (t1-ext-hidden-quadratic) ─────────────

## The roots' a u² + B u + C, with a, B and C whole: s.u holds the roots, s.a the leading
## coefficient, which clears a root's denominator.
static func set_quadratic(s: Dictionary) -> void:
	var a := Q.new(s.a)
	var u1: Q = s.u[0]
	var u2: Q = s.u[1]
	s.B = int(a.mul(u1.add(u2)).neg().to_float())
	s.C = int(a.mul(u1.mul(u2)).to_float())


## Whether the equation is one of the skill map's examples, or one with a root's sign flipped.
static func map_hidden(s: Dictionary) -> bool:
	# A root's sign flipped is the example too, near enough: e^(2x) + 5e^x + 6 echoes it.
	var us: Array = s.u.map(func(v): return absf(v.to_float()))
	us.sort()
	for e in MAP_HIDDEN:
		if s.b == e[0] and s.a == 1 and is_equal_approx(us[0], e[1]) and is_equal_approx(us[1], e[2]):
			return true
	return false


static func _hq_base(rng: Seeded, s: Dictionary) -> void:
	s.b = rng.pick(HQ_BASES)
	s.a = 1
	s.sq = s.b <= 5 and rng.chance(0.4)


static func _two_powers(rng: Seeded, s: Dictionary) -> bool:
	_hq_base(rng, s)
	s.shape = "frac" if rng.chance(0.3) else "whole"
	var m: int
	var n: int
	if s.shape == "whole":
		m = rng.int_in(0, 3)
		n = rng.int_in(m + 1, 4)
		s.u = [Q.new(ipow(s.b, m)), Q.new(ipow(s.b, n))]
	else:
		m = -1
		n = rng.int_in(1, 3)
		s.a = s.b
		s.u = [Q.new(1, s.b), Q.new(ipow(s.b, n))]
	if s.u[1].to_float() > 81.0 or map_hidden(s):
		return false
	set_quadratic(s)
	s.x = [Q.new(m), Q.new(n)]
	return true


static func _reject_negative(rng: Seeded, s: Dictionary) -> bool:
	s.b = rng.pick([2, 3, 4, 5, 7])
	s.a = 1
	s.sq = s.b <= 5 and rng.chance(0.4)
	var m := rng.int_in(1, 3)
	s.k = rng.int_in(0, 2)
	if s.k == m or ipow(s.b, m) > 64 or ipow(s.b, s.k) > 25:
		return false
	s.u = [Q.new(ipow(s.b, m)), Q.new(-ipow(s.b, s.k))]
	set_quadratic(s)
	s.x = [Q.new(m)]
	return not map_hidden(s)


static func _zero_root(rng: Seeded, s: Dictionary) -> bool:
	_hq_base(rng, s)
	s.shape = "equal" if rng.chance(0.4) else "zero"
	var m := ExtensionViews.nonzero(rng, -2, 3)
	if ipow(s.b, absi(m)) > 64:
		return false
	var top := ipow(s.b, m) if m > 0 else 1
	s.a = 1 if m > 0 else ipow(s.b, -m)
	s.c = top
	s.u = [Q.new(0), Q.new(top, s.a)]
	set_quadratic(s)
	s.x = [Q.new(m)]
	return true


static func _exact_ln(rng: Seeded, s: Dictionary) -> bool:
	s.b = 0
	s.a = 1
	s.sq = false
	var p := rng.int_in(3, 8)
	var q := rng.int_in(p + 1, 9)
	s.u = [Q.new(p), Q.new(q)]
	set_quadratic(s)
	# e^(2x) read as 2e^x: (2 + B)u + C = 0.
	s.slip = Q.new(-s.C, 2 + s.B)
	return true


static func _exact_log_base(rng: Seeded, s: Dictionary) -> bool:
	s.b = rng.pick([2, 3, 5, 7])
	s.a = 1
	s.sq = s.b <= 5 and rng.chance(0.4)
	var r := rng.int_in(3, 20)
	var sn := rng.int_in(2, 9)
	if is_power(r, s.b) or r == sn or r * sn > 120:
		return false
	s.r = r
	s.sn = sn
	s.u = [Q.new(r), Q.new(-sn)]
	set_quadratic(s)
	return true


static func _solution_count(rng: Seeded, s: Dictionary) -> bool:
	s.b = rng.pick([2, 3, 5, 0])
	s.a = 1
	s.sq = s.b != 0 and rng.chance(0.4)
	s.shape = rng.pick(["two", "two", "double", "mixed", "mixed", "none"])
	var r := rng.int_in(2, 9)
	var t := rng.int_in(2, 9)
	match s.shape:
		"two":
			if rng.chance(0.5):
				s.a = rng.int_in(2, 3)
				s.u = [Q.new(1, s.a), Q.new(mini(r, 6))]
				s.frac = true
			else:
				if r == t:
					return false
				s.u = [Q.new(mini(r, t)), Q.new(maxi(r, t))]
				s.frac = false
			s.n = 2
		"double":
			s.u = [Q.new(r), Q.new(r)]
			s.n = 1
		"mixed":
			if r == t:
				return false
			s.u = [Q.new(r), Q.new(-t)]
			s.n = 1
		"none":
			if r == t:
				return false
			s.u = [Q.new(-mini(r, t)), Q.new(-maxi(r, t))]
			s.n = 0
	set_quadratic(s)
	return absi(s.C) <= 81 and not map_hidden(s)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
