class_name BinomialSituation
extends RefCounted
## The `binomial` situation (curriculum/question-types.json): X ~ B(n, p) in a context
## (FAL-695). Probabilities are floats, as a GDC computes them (C(20, 10) p^10 q^10 would
## overflow a Q); the answers keep nine decimal places. The SymPy checker re-solves each
## one exactly from the givens.
##
## need.ask is the unknown, and decides what is drawn besides n and p:
##   n-and-p-from-words        n, p
##   exact-probability         k: P(X = k)
##   at-most-probability       form "le" (X <= k) or "lt" (X < k)
##   at-least-probability      form "ge" (X >= k) or "gt" (X > k)
##   between-probability       form "in" (a <= X <= b) or "lo-open" (a < X <= b)
##   mean-from-parameters, variance-from-parameters, std-deviation
##   n-and-p-from-mean-variance   E(X) = np and Var(X) = npq, both exact
##   least-trials              c: the least n with P(X >= 1) > c
##   kth-success-trial         k and m: the kth success is on trial m
##   conditional-probability   j: P(X = j) given X >= 1
##
## generate() returns a Dictionary:
##   paper    2 (every binomial part in the bank is Paper 2)
##   ask      the unknown;  ctx  the story (an index into BinomialViews.CONTEXTS)
##   n        the trials;  p, q  Q, the probability of success and 1 - p
##   form     the event's form (see above), "" if none
##   k, a, b  the counts the question gives (k for exact, at most, at least, kth, j for
##            a conditional; a and b for between), 0 if none
##   lo, hi   the event as inclusive bounds on X: P(lo <= X <= hi)
##   m        the trial of the kth success;  c  the target (Q);  nn  the least n
##   mean, variance  E(X) and Var(X) as Q (the mean/variance questions and n-and-p)
##
## The clean limits below are the numbers behind the catalogue's `clean` text. The SymPy
## checker (tools/check_answers.py) holds its own copy and fails on any breach.

const CONTEXTS := 8
const TRIES := 3000
## Probabilities asked are at least this, and this far (in units of the 3rd figure) from a
## rounding edge: Answer.rounds_clearly.
const P_MIN := 0.005
const EDGE := 0.03
const N_MIN := 5
const N_MAX := 20
const N_BIG := 60
const TERMS_MAX := 6
## p in hundredths: steps of 0.05, or of 0.1 where a variance has to come out exact.
const P_FINE := [10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90]
const P_TENTHS := [10, 20, 30, 40, 50, 60, 70, 80, 90]
const P_LEAST := [5, 10, 15, 20, 25, 30, 40, 50]
const TARGETS := [90, 95, 99]
const LEAST_MAX := 60
const LEAST_GAP := 0.1


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "exact-probability")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "ctx": rng.int_in(0, CONTEXTS - 1), "form": "", "k": 0, "a": 0, "b": 0, "lo": 0, "hi": 0, "m": 0}
		var ok := false
		match ask:
			"n-and-p-from-words":
				_np(rng, s, N_MIN + 1, 30, P_FINE)
				ok = true
			"exact-probability":
				ok = _exact(rng, s)
			"at-most-probability":
				ok = _at_most(rng, s)
			"at-least-probability":
				ok = _at_least(rng, s)
			"between-probability":
				ok = _between(rng, s)
			"mean-from-parameters":
				_np(rng, s, 10, N_BIG, P_FINE)
				s.mean = s.p.mul(Q.new(s.n))
				ok = true
			"variance-from-parameters", "std-deviation":
				_np(rng, s, 10, N_BIG, P_TENTHS)
				s.variance = s.p.mul(s.q).mul(Q.new(s.n))
				s.mean = s.p.mul(Q.new(s.n))
				ok = ask == "variance-from-parameters" or Answer.rounds_clearly(sqrt(s.variance.to_float()), EDGE)
			"n-and-p-from-mean-variance":
				_np(rng, s, 8, 40, P_TENTHS)
				s.mean = s.p.mul(Q.new(s.n))
				s.variance = s.p.mul(s.q).mul(Q.new(s.n))
				ok = true
			"least-trials":
				ok = _least(rng, s)
			"kth-success-trial":
				ok = _kth(rng, s)
			"conditional-probability":
				ok = _conditional(rng, s)
		if ok:
			return s
	return {}


## n and p. p is x / 100 for one of `ps`.
static func _np(rng: Seeded, s: Dictionary, n_lo: int, n_hi: int, ps: Array) -> void:
	s.n = rng.int_in(n_lo, n_hi)
	s.p = Q.new(int(ps[rng.int_in(0, ps.size() - 1)]), 100)
	s.q = Q.new(1).sub(s.p)


static func _exact(rng: Seeded, s: Dictionary) -> bool:
	_np(rng, s, N_MIN, N_MAX, P_FINE)
	s.k = rng.int_in(1, s.n - 1)
	s.lo = s.k
	s.hi = s.k
	return clear(prob(s), 0.01, 0.4)


static func _at_most(rng: Seeded, s: Dictionary) -> bool:
	_np(rng, s, N_MIN, N_MAX, P_FINE)
	s.form = "le" if rng.chance(0.5) else "lt"
	s.k = rng.int_in(1, 5) if s.form == "le" else rng.int_in(2, 6)
	if s.k >= s.n:
		return false
	s.lo = 0
	s.hi = s.k if s.form == "le" else s.k - 1
	return clear(prob(s), 0.02, 0.98)


static func _at_least(rng: Seeded, s: Dictionary) -> bool:
	_np(rng, s, N_MIN, N_MAX, P_FINE)
	s.form = "ge" if rng.chance(0.5) else "gt"
	s.k = rng.int_in(1, s.n - 1)
	s.lo = s.k if s.form == "ge" else s.k + 1
	s.hi = s.n
	return clear(prob(s), 0.02, 0.98)


static func _between(rng: Seeded, s: Dictionary) -> bool:
	_np(rng, s, N_MIN + 3, N_MAX, P_FINE)
	s.form = "in" if rng.chance(0.5) else "lo-open"
	s.a = rng.int_in(1, s.n - 3)
	s.b = s.a + rng.int_in(3 if s.form == "lo-open" else 2, 6)
	if s.b >= s.n:
		return false
	s.lo = s.a if s.form == "in" else s.a + 1
	s.hi = s.b
	# The working adds the terms; there are at most TERMS_MAX of them.
	return s.hi - s.lo + 1 <= TERMS_MAX and clear(prob(s), 0.05, 0.95)


static func _least(rng: Seeded, s: Dictionary) -> bool:
	s.p = Q.new(int(P_LEAST[rng.int_in(0, P_LEAST.size() - 1)]), 100)
	s.q = Q.new(1).sub(s.p)
	s.c = Q.new(int(TARGETS[rng.int_in(0, TARGETS.size() - 1)]), 100)
	var x := least_x(s)
	var frac := x - floorf(x)
	if frac < LEAST_GAP or frac > 1.0 - LEAST_GAP:
		return false
	s.nn = int(ceilf(x))
	s.n = s.nn
	return s.nn >= 3 and s.nn <= LEAST_MAX


## ln(1 - c) / ln(1 - p): P(X >= 1) > c exactly when n is greater than this.
static func least_x(s: Dictionary) -> float:
	return log(1.0 - s.c.to_float()) / log(s.q.to_float())


static func _kth(rng: Seeded, s: Dictionary) -> bool:
	_np(rng, s, N_MIN, N_MAX, P_FINE)
	s.k = rng.int_in(2, 4)
	s.m = s.k + rng.int_in(2, 8)
	s.n = s.m
	return clear(kth_prob(s), 0.01, 0.4)


static func _conditional(rng: Seeded, s: Dictionary) -> bool:
	_np(rng, s, N_MIN, N_MAX, P_FINE)
	s.k = rng.int_in(1, s.n - 1)
	var at_least_one := 1.0 - pow(s.q.to_float(), s.n)
	# Dividing by P(X >= 1) has to matter.
	return at_least_one <= 0.97 and clear(cond_prob(s), 0.02, 0.6)


# ── The numbers ──────────────────────────────────────────────

## nCk as a float.
static func comb(n: int, k: int) -> float:
	if k < 0 or k > n:
		return 0.0
	var r := 1.0
	for i in range(1, k + 1):
		r = r * (n - k + i) / i
	return r


static func pmf(n: int, p: float, k: int) -> float:
	if k < 0 or k > n:
		return 0.0
	return comb(n, k) * pow(p, k) * pow(1.0 - p, n - k)


## P(X <= k), 0 below 0 and 1 from n.
static func cdf(n: int, p: float, k: int) -> float:
	var t := 0.0
	for r in range(0, mini(k, n) + 1):
		t += pmf(n, p, r)
	return t


## P(lo <= X <= hi) for the situation's event.
static func prob(s: Dictionary) -> float:
	var p: float = s.p.to_float()
	return cdf(s.n, p, s.hi) - cdf(s.n, p, s.lo - 1)


## P(the kth success is on trial m) = C(m - 1, k - 1) p^k q^(m - k).
static func kth_prob(s: Dictionary) -> float:
	var p: float = s.p.to_float()
	return comb(s.m - 1, s.k - 1) * pow(p, s.k) * pow(1.0 - p, s.m - s.k)


## P(X = k | X >= 1) = P(X = k) / (1 - q^n).
static func cond_prob(s: Dictionary) -> float:
	var p: float = s.p.to_float()
	return pmf(s.n, p, s.k) / (1.0 - pow(1.0 - p, s.n))


## A probability the answer can be read to 3 s.f.: between lo and hi, and clear of a
## rounding edge.
static func clear(x: float, lo: float = P_MIN, hi: float = 0.995) -> bool:
	return x >= lo and x <= hi and Answer.rounds_clearly(x, EDGE)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
