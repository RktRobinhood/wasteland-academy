class_name ArithmeticSequenceSituation
extends RefCounted
## The `arithmetic-sequence` situation (curriculum/question-types.json): one arithmetic
## sequence with its sums, every value a whole number.
##
## generate() returns a Dictionary of Q values (and arrays of them):
##   u1, d        first term and common difference (d ≠ 0, can be negative)
##   n, un, sn    a term number, that term and the sum of the first n terms
##   p, q, up, uq two later terms u_p and u_q, p < q (when need.two_terms)
##   ns, us       the first four terms as a table: n = 1..4 and u_n
##   other        the second root of dn² + (2u₁ − d)n − 2Sₙ = 0 (when need.sum_root)
##
## need (all optional):
##   n          "term" (n from N_TERM) or "sum" (n from N_SUM, the default)
##   two_terms  pick p and q
##   sum_root   the quadratic in n has a negative whole second root
##
##   paper      1 or 2 (FAL-419). Paper 2 draws a context instead (see _draw_p2): savings
##              in dollars and cents, or a training plan in km, with a decimal u₁ and d,
##              and a round threshold: Y for the first term over it (need.n "term"), X
##              for the first sum over it ("sum"). Paper 1 draws exactly as before.
##
##   sigma      t1-ext-sigma-arithmetic (FAL-779): the sequence as Σ (r = a to b) (pr + q), with
##              d = p and u₁ = pa + q (see _draw_sigma). "count", "one" (a = 1), "shifted"
##              (a > 1), "write" (a = 1, shown as a series) or "upper" (Σ (r = 1 to k) = T, k
##              found). It adds p, q, lower and upper, and for "upper" the other root.
##
## The clean limits below are the numbers behind the catalogue's `clean` text. The
## SymPy checker (tools/check_answers.py) holds its own copy and fails on any breach.

const U1_MAX := 40         ## |u₁| ≤ 40, u₁ ≠ 0
const D_MAX := 12          ## |d| ≤ 12, d ≠ 0
const N_TERM := [6, 60]    ## n for a term
const N_SUM := [5, 30]     ## n for a sum
const UN_MAX := 400
const SN_MAX := 4000
const P_RANGE := [2, 12]   ## p, the first of two given terms
const GAP_RANGE := [2, 8]  ## q − p
const Q_MAX := 20
const TERMS := 4           ## the first terms shown as a list or a table
const TRIES := 4000
## Paper 2 limits, in hundredths (cents, or hundredths of a km): u₁ and d, each not
## whole, and the threshold's step. A threshold's crossing point (where uₙ or Sₙ
## equals it, as a real n) keeps EDGE from a whole n, so "first more than" is clear.
const P2 := {
	"money": {"u1": [500, 4000, 5], "d": [15, 250, 5], "step_term": 100, "step_sum": 1000},
	"km": {"u1": [200, 800, 10], "d": [10, 50, 5], "step_term": 100, "step_sum": 500},
}
const EDGE := 0.15
## Σ limits: the lower limit of a shifted sum or a count, and how far past it the upper one is.
const SIGMA_LOWER := {"count": [2, 20], "shifted": [2, 12]}
const SIGMA_SPAN := {"count": [5, 60], "shifted": [5, 30]}
const SIGMA_N := [8, 40]
const SIGMA_K := [5, 30]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var paper: int = need.get("paper", 0)
	for i in TRIES:
		var s: Dictionary
		if need.has("sigma"):
			s = _draw_sigma(rng, need.sigma)
		else:
			s = _draw_p2(rng, need) if paper == 2 else _draw(rng, need)
		if not s.is_empty():
			if paper > 0:
				s.paper = paper
			return s
	push_error("ArithmeticSequenceSituation: no clean situation for %s" % need)
	return {}


## u₁ + (k − 1)d
static func term(s: Dictionary, k: Variant) -> Q:
	return s.u1.add(s.d.mul(Q.of(k).sub(1)))


## k/2 (2u₁ + (k − 1)d)
static func sum(s: Dictionary, k: Variant) -> Q:
	var kq := Q.of(k)
	return kq.mul(s.u1.mul(2).add(s.d.mul(kq.sub(1)))).div(2)


static func _draw(rng: Seeded, need: Dictionary) -> Dictionary:
	# Mostly positive first terms and rising sequences, as on Paper 1.
	var u1 := rng.int_in(1, U1_MAX) if rng.chance(0.8) else -rng.int_in(1, 30)
	var d := rng.int_in(1, D_MAX) if rng.chance(0.7) else -rng.int_in(1, D_MAX)
	var lim: Array = N_TERM if need.get("n", "sum") == "term" else N_SUM
	var n := rng.int_in(lim[0], lim[1])
	var s := {"u1": Q.new(u1), "d": Q.new(d), "n": Q.new(n), "p": null, "q": null, "up": null, "uq": null, "other": null}
	s.un = term(s, n)
	s.sn = sum(s, n)
	if absi(s.un.n) > UN_MAX or absi(s.sn.n) > SN_MAX or s.sn.is_zero():
		return {}
	var ns := []
	var us := []
	for k in range(1, TERMS + 1):
		ns.append(Q.new(k))
		us.append(term(s, k))
	s.ns = ns
	s.us = us
	if need.get("two_terms", false):
		var p := rng.int_in(P_RANGE[0], P_RANGE[1])
		var q := p + rng.int_in(GAP_RANGE[0], GAP_RANGE[1])
		if q > Q_MAX:
			return {}
		s.p = Q.new(p)
		s.q = Q.new(q)
		s.up = term(s, p)
		s.uq = term(s, q)
		if absi(s.up.n) > UN_MAX or absi(s.uq.n) > UN_MAX:
			return {}
	if need.get("sum_root", false):
		# n + other = 1 − 2u₁/d, so other is whole exactly when d divides 2u₁.
		if (2 * u1) % d != 0:
			return {}
		var other := 1 - (2 * u1) / d - n
		if other >= 0:
			return {}
		s.other = Q.new(other)
	return s


## Σ (r = a to b) (pr + q): p mostly positive, q never 0, and u₁ = pa + q, d = p, n = b − a + 1,
## uₙ = pb + q and Sₙ as for any arithmetic sequence. The skill map's examples are left out. For
## "upper", p > 0 divides 2q, so pk² + (p + 2q)k − 2T = 0 has a negative whole second root.
static func _draw_sigma(rng: Seeded, kind: String) -> Dictionary:
	var p := rng.int_in(1, 9) if kind == "upper" or rng.chance(0.85) else -rng.int_in(1, 5)
	var q := ExtensionViews.nonzero(rng, -9, 12)
	var a := 1
	var b: int
	if kind in SIGMA_LOWER:
		a = rng.int_in(SIGMA_LOWER[kind][0], SIGMA_LOWER[kind][1])
		b = a + rng.int_in(SIGMA_SPAN[kind][0], SIGMA_SPAN[kind][1])
	elif kind == "upper":
		b = rng.int_in(SIGMA_K[0], SIGMA_K[1])
	else:
		b = rng.int_in(SIGMA_N[0], SIGMA_N[1])
	var s := {"u1": Q.new(p * a + q), "d": Q.new(p), "n": Q.new(b - a + 1), "p": Q.new(p), "q": Q.new(q),
		"lower": Q.new(a), "upper": Q.new(b), "up": null, "uq": null, "other": null, "sigma": kind}
	s.un = Q.new(p * b + q)
	s.sn = sum(s, b - a + 1)
	# A count needs no sum, so only its terms are held to the limits.
	if absi(s.un.n) > UN_MAX or absi(s.u1.n) > UN_MAX or s.u1.is_zero() or (kind != "count" and (absi(s.sn.n) > SN_MAX or s.sn.is_zero())):
		return {}
	match kind:
		"one":
			if [p, q, b] == [3, 2, 20]:
				return {}
		"count":
			if [a, b] == [5, 30]:
				return {}
		"write":
			if [p, q, b] == [3, 1, 20]:
				return {}
		"upper":
			if (2 * q) % p != 0 or s.sn.sign() <= 0 or [p, q, s.sn.n] == [2, -1, 225]:
				return {}
			var other: int = -(p + 2 * q) / p - b
			if other >= 0:
				return {}
			s.other = Q.new(other)
	return s


## A whole number of hundredths in [lo, hi] in steps of `by`, not a whole number.
static func _hundredths(rng: Seeded, lim: Array) -> Q:
	var v: int = rng.int_in(lim[0] / lim[2], lim[1] / lim[2]) * lim[2]
	return Q.new(v, 100) if v % 100 != 0 else null


## Paper 2: a context with a decimal u₁ and d (both positive), and the threshold its
## view asks about. Every value ends (cents, or hundredths of a km).
static func _draw_p2(rng: Seeded, need: Dictionary) -> Dictionary:
	var ctx := "money" if rng.chance(0.5) else "km"
	var lim: Dictionary = P2[ctx]
	var u1 = _hundredths(rng, lim.u1)
	var d = _hundredths(rng, lim.d)
	var is_term: bool = need.get("n", "sum") == "term"
	var nl: Array = N_TERM if is_term else N_SUM
	var n := rng.int_in(nl[0], nl[1])
	if u1 == null or d == null:
		return {}
	var s := {"u1": u1, "d": d, "n": Q.new(n), "p": null, "q": null, "up": null, "uq": null, "other": null,
		"ctx": ctx, "Y": null, "X": null}
	s.un = term(s, n)
	s.sn = sum(s, n)
	if s.un.to_float() > UN_MAX or s.sn.to_float() > SN_MAX:
		return {}
	var ns := []
	var us := []
	for k in range(1, TERMS + 1):
		ns.append(Q.new(k))
		us.append(term(s, k))
	s.ns = ns
	s.us = us
	if is_term:
		# Y: a whole number of dollars (or km) between uₙ₋₁ and uₙ.
		var step: int = lim.step_term
		var y: int = (s.un.mul(100).n / step) * step
		var real := 1.0 + (y / 100.0 - u1.to_float()) / d.to_float()
		if real <= n - 1 + EDGE or real >= n - EDGE:
			return {}
		s.Y = Q.new(y, 100)
	else:
		# X: a round total between Sₙ₋₁ and Sₙ.
		var step: int = lim.step_sum
		var x: int = (s.sn.mul(100).n / step) * step
		var real := sum_root(s, Q.new(x, 100))
		if x <= 0 or real <= n - 1 + EDGE or real >= n - EDGE:
			return {}
		s.X = Q.new(x, 100)
		s.other = null
	return s


## The real n where Sₙ = v: the positive root of (d/2)n² + (u₁ − d/2)n − v = 0, or
## the negative one (positive = false).
static func sum_root(s: Dictionary, v: Q, positive: bool = true) -> float:
	var a: float = s.d.to_float() / 2.0
	var b: float = s.u1.to_float() - a
	var disc := b * b + 4.0 * a * v.to_float()
	return (-b + sqrt(disc)) / (2.0 * a) if positive else (-b - sqrt(disc)) / (2.0 * a)


## The situation as plain strings, for the answer export.
static func export(s: Dictionary) -> Dictionary:
	var out := {}
	for key in s:
		var v = s[key]
		if v is Q:
			out[key] = v.key()
		elif v is Array:
			out[key] = v.map(func(e): return e.key())
		else:
			out[key] = v
	return out
