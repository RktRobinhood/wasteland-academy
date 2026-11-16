class_name ShowThatSituation
extends RefCounted
## The `show-that-value` situation (curriculum/question-types.json): a numerical result to show, for
## t1-ext-numerical-show-that (FAL-780). Each draw makes the stated result true (exactly, or to the
## nearest cent for an investment), so the working that reaches it and the slips that only seem to
## are all known.
##
## need.ask is the unknown (see ShowThatViews). generate() returns ask, rep, paper and ctx, then:
##   log-difference      b, Q, k, P = Q × b^k:  log_b P − log_b Q = k
##   series-sum          u1, d, n, V = n/2 × (2u1 + (n − 1)d):  S_n = V
##   common-difference   p, q, A = u_p, B = u_q, D:  d = D
##   interest-value      pv, r (a Q, per cent), n, V (to the cent):  pv(1 + r/100)^n = V
##   verify-solution     a, r, s and b, c with a(x − r)(x − s) = ax² + bx + c:  x = r solves it
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its own
## copy.

const TRIES := 4000
const CENT_EDGE := 0.15


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "log-difference")
	var draws := ShowThatSituation.new()
	for i in TRIES:
		var s := {"ask": ask, "rep": need.get("rep", "equation"), "paper": 2 if ask == "interest-value" else int(need.get("paper", 1)), "ctx": rng.int_in(0, 3)}
		if draws.call("_" + ask.replace("-", "_"), rng, s):
			return s
	return {}


static func ipow(b: int, e: int) -> int:
	var r := 1
	for i in e:
		r *= b
	return r


## Q from 2 to 12 and not a power of b, b^k from 4 to 125.
static func _log_difference(rng: Seeded, s: Dictionary) -> bool:
	s.b = rng.pick([2, 3, 5])
	s.k = rng.int_in(2, 6)
	s.Q = rng.int_in(2, 12)
	var bk := ipow(s.b, s.k)
	if bk > 125 or SolveExponentialSituation.is_power(s.Q, s.b):
		return false
	s.P = s.Q * bk
	return true


static func _series_sum(rng: Seeded, s: Dictionary) -> bool:
	s.u1 = rng.int_in(1, 12)
	s.d = rng.int_in(2, 9)
	s.n = rng.int_in(8, 20)
	s.V = s.n * (2 * s.u1 + (s.n - 1) * s.d) / 2
	return s.n * (2 * s.u1 + (s.n - 1) * s.d) % 2 == 0


## The terms u_p and u_q of a sequence with first term u1 and difference D, q at least 3 after p.
static func _common_difference(rng: Seeded, s: Dictionary) -> bool:
	s.D = rng.int_in(2, 9)
	s.u1 = rng.int_in(-5, 15)
	s.p = rng.int_in(2, 6)
	s.q = rng.int_in(s.p + 3, 15)
	s.A = s.u1 + (s.p - 1) * s.D
	s.B = s.u1 + (s.q - 1) * s.D
	# The wrong divisor gives another value.
	return (s.B - s.A) % s.q != 0 or (s.B - s.A) / s.q != s.D


## pv a multiple of 100 from 500 to 5000, r from 2 to 9 in steps of 0.5, n from 3 to 8, and the
## value's leftover fraction of a cent clear of the edge, with cents that aren't 00.
static func _interest_value(rng: Seeded, s: Dictionary) -> bool:
	s.pv = rng.int_in(5, 50) * 100
	s.r = Q.new(rng.int_in(4, 18) * 5, 10)
	s.n = rng.int_in(3, 8)
	s.exact = s.pv * pow(1.0 + s.r.to_float() / 100.0, s.n)
	var c: float = s.exact * 100.0
	if absf(c - floorf(c) - 0.5) < CENT_EDGE:
		return false
	s.V = Q.new(roundi(c), 100)
	return not s.V.is_int()


static func _verify_solution(rng: Seeded, s: Dictionary) -> bool:
	s.a = rng.int_in(1, 3)
	s.r = ExtensionViews.nonzero(rng, -6, 6)
	s.s = ExtensionViews.nonzero(rng, -6, 6)
	if s.r == s.s:
		return false
	s.bb = -s.a * (s.r + s.s)
	s.cc = s.a * s.r * s.s
	# Leaving out c must leave something that isn't 0.
	return s.bb != 0 and s.a * s.r * s.r + s.bb * s.r != 0


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
