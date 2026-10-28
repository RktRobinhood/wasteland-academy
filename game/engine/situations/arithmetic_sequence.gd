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


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	for i in TRIES:
		var s := _draw(rng, need)
		if not s.is_empty():
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
