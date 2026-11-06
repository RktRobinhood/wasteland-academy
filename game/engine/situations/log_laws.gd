class_name LogLawsSituation
extends RefCounted
## The `log-laws` situation (curriculum/question-types.json): a log expression to evaluate, combine,
## expand or rewrite in another base, for t1-log-laws (FAL-751). Numbers are drawn so the laws land
## on an exact value, and each one is worked out exactly with Q.
##
## need.ask is the unknown (see LogLawsViews). generate() returns a Dictionary:
##   paper, ask, shape   the unknown's form (see each draw); paper is 2 only for a calculator cell
##   b, L     the log's base (0 for e, 10 for log) and how it is written: ln, log, log₁₀, log₂
##   val      the exact answer, Q, where the answer is a number
##   the rest are the draw's own numbers, named in each function
##
## Every number comes out by hand on Paper 1. Paper 2 is only the GDC check, the log-base template
## and the 3 s.f. value. The bank's own numbers, and the skill map's examples, are left out.
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its own
## copy.

const TRIES := 4000
const MOST := 1000
const EDGE := 0.06
const PRIMES := [2, 3, 5]
const BASES := [2, 3, 4, 5, 6, 7, 10]
const COMPOSITE := [6, 10, 12, 14, 15, 18, 20]
## The value given for a log.
const GIVEN := [[1, 2], [2, 3], [3, 2], [1, 4], [3, 4], [2, 5], [5, 2], [2, 1], [3, 1]]
const AB_GIVEN := [[2, 1], [4, 1], [5, 1], [-1, 1], [-2, 1], [-3, 1], [1, 2], [3, 4], [2, 3]]
const LETTERS := [["a", "b"], ["c", "d"], ["p", "q"], ["u", "v"]]
const PAIRS := [[2, 3], [2, 5], [3, 5], [2, 7], [3, 7], [5, 7]]
const LOG_PLAIN := 1
const LOG_E := 0


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "value-difference")
	for i in TRIES:
		var s := {"paper": 2 if ask == "value-3sf" else int(need.get("paper", 1)), "ask": ask, "shape": "", "b": 10, "L": "log", "val": Q.new(0)}
		if _draw(rng, s):
			return s
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"value-difference":
			return _value_difference(rng, s)
		"value-hidden":
			return _value_hidden(rng, s)
		"value-quotient":
			return _value_quotient(rng, s)
		"single-ln-k":
			return _single_k(rng, s)
		"single-log-letters":
			return _single_letters(rng, s)
		"expand-letters":
			return _expand_letters(rng, s)
		"expand-numbers":
			return _expand_numbers(rng, s)
		"show-number":
			return _show_number(rng, s)
		"given-log-laws":
			return _given_laws(rng, s)
		"ab-base-value":
			return _ab_value(rng, s)
		"ab-base-hence":
			return _ab_hence(rng, s)
		"evaluate-single":
			return _evaluate_single(rng, s)
		"log-of-root":
			return _log_of_root(rng, s)
		"cob-common-base":
			return _cob_common(rng, s)
		"cob-in-p-q":
			return _cob_pq(rng, s)
		"given-log-base":
			return _given_base(rng, s)
		"base-power-letter":
			return _base_power(rng, s)
		"value-3sf":
			return _value_sf(rng, s)
	return false


# ── Small tools ──────────────────────────────────────────────

static func ipow(b: int, e: int) -> int:
	var r := 1
	for i in e:
		r *= b
	return r


## Whether n is a whole power of b.
static func is_power(n: int, b: int) -> bool:
	if n < 1 or b < 2:
		return false
	while n % b == 0:
		n /= b
	return n == 1


## The largest e with b^e at most top.
static func top_power(b: int, top: int) -> int:
	var e := 0
	while ipow(b, e + 1) <= top:
		e += 1
	return e


## log_b written for a base; 0 is ln, and LOG_PLAIN is log with no base shown.
static func log_of(b: int) -> String:
	if b == LOG_E:
		return "ln"
	return "log" if b == LOG_PLAIN else Answer.log_name(b)


static func pick_log(rng: Seeded, s: Dictionary, names: Array) -> void:
	var n: int = rng.pick(names)
	s.L = log_of(n)
	s.b = 10 if n == LOG_PLAIN else n


static func set_base(s: Dictionary, b: int) -> void:
	s.b = b
	s.L = log_of(b)


## log to base b of x, as a float, for a GDC's screen.
static func lg(b: int, x: float) -> float:
	return log(x) if b == 0 else log(x) / log(float(b))


# ── The laws ─────────────────────────────────────────────────

## log_b m ± log_b n: both are powers of b, i and j. shape is "+" or "−".
static func _value_difference(rng: Seeded, s: Dictionary) -> bool:
	var b: int = rng.pick(BASES)
	if b == 10:
		pick_log(rng, s, [LOG_PLAIN, 10])
	else:
		set_base(s, b)
	s.shape = "−" if rng.chance(0.6) else "+"
	s.i = rng.int_in(1, top_power(b, MOST))
	s.j = rng.int_in(1, top_power(b, MOST))
	s.m = ipow(b, s.i)
	s.n = ipow(b, s.j)
	if s.shape == "−" and s.i <= s.j:
		return false
	if b == 3 and s.m == 81 and s.n == 9:
		return false
	s.val = Q.new(s.i - s.j if s.shape == "−" else s.i + s.j)
	return true


## A value that only the combined log shows. sum log_b A + log_b B, diff log_b A − log_b B,
## coef 2 log_b c + log_b B, split log_b(A + B) with A + B a power of b. k is the value.
static func _value_hidden(rng: Seeded, s: Dictionary) -> bool:
	s.shape = rng.pick(["sum", "diff", "coef", "split"])
	s.k = rng.int_in(1, 3)
	s.c = 0
	var b: int
	match s.shape:
		"sum":
			b = rng.pick(COMPOSITE)
			var p := ipow(b, s.k)
			if p > 8000:
				return false
			s.A = rng.int_in(2, 60)
			if p % s.A != 0:
				return false
			s.B = p / s.A
			if s.B > 400 or s.A == s.B or s.B < 2:
				return false
		"diff":
			b = rng.pick([2, 3, 5, 6, 10])
			s.B = rng.int_in(2, 9)
			s.A = s.B * ipow(b, s.k)
			if s.A > MOST:
				return false
		"coef":
			b = rng.pick([6, 10, 12, 18, 20])
			s.k = rng.int_in(1, 2)
			var p := ipow(b, s.k)
			s.c = rng.int_in(2, 9)
			if p % (s.c * s.c) != 0:
				return false
			s.A = s.c * s.c
			s.B = p / s.A
			if s.B < 2:
				return false
		"split":
			b = rng.pick([2, 3, 5, 6, 10])
			s.k = rng.int_in(2, 3)
			var p := ipow(b, s.k)
			if p < 8 or p > 200:
				return false
			s.A = rng.int_in(2, p - 2)
			s.B = p - s.A
			if s.A <= s.B:
				return false
	if is_power(s.A, b) or is_power(s.B, b):
		return false
	if b == 10:
		pick_log(rng, s, [LOG_PLAIN, 10])
	else:
		set_base(s, b)
	s.val = Q.new(s.k)
	return true


## L m / L n, with m = p^a and n = p^e, and a fraction left.
static func _value_quotient(rng: Seeded, s: Dictionary) -> bool:
	pick_log(rng, s, [LOG_E, LOG_PLAIN, 10])
	s.p = rng.pick(PRIMES)
	s.a = rng.int_in(2, top_power(s.p, MOST))
	s.e = rng.int_in(2, top_power(s.p, MOST))
	if s.a % s.e == 0 or s.a == s.e:
		return false
	s.m = ipow(s.p, s.a)
	s.n = ipow(s.p, s.e)
	s.val = Q.new(s.a, s.e)
	return true


## An expression to write as L k. sum L u + L v, power c L u, neg −L(1/u), diff L u − L v,
## root (1/c) L u, mix c L u + L v. k is the whole number.
static func _single_k(rng: Seeded, s: Dictionary) -> bool:
	pick_log(rng, s, [LOG_E, LOG_E, LOG_PLAIN, 10])
	s.shape = rng.pick(["sum", "power", "neg", "diff", "root", "mix"])
	s.u = 0
	s.v = 0
	s.c = 0
	match s.shape:
		"sum":
			s.u = rng.int_in(2, 9)
			s.v = rng.int_in(2, 9)
			s.k = s.u * s.v
			if s.u == s.v or s.u * s.v == 12:
				return false
		"power":
			s.c = rng.int_in(2, 4)
			s.u = rng.int_in(2, 7)
			s.k = ipow(s.u, s.c)
			if s.k > MOST or (s.c == 3 and s.u == 2):
				return false
		"neg":
			s.u = rng.int_in(3, 12)
			s.k = s.u
		"diff":
			s.v = rng.int_in(2, 9)
			s.k = rng.int_in(3, 12)
			s.u = s.v * s.k
		"root":
			s.c = rng.int_in(2, 3)
			s.k = rng.int_in(2, 9)
			s.u = ipow(s.k, s.c)
		"mix":
			s.c = rng.int_in(2, 3)
			s.u = rng.int_in(2, 6)
			s.v = rng.int_in(2, 9)
			s.k = ipow(s.u, s.c) * s.v
			if s.k > MOST or s.u == s.v:
				return false
	return true


## An expression with letters to write as one log.
## one  c L x + L m − L n;  two  c L x − d L y + L m;  root  L m + (1/2) L x − d L y.
## cx, cy are x and y for the GDC check.
static func _single_letters(rng: Seeded, s: Dictionary) -> bool:
	pick_log(rng, s, [LOG_E, LOG_PLAIN, 2, 3, 5, 10])
	s.shape = rng.pick(["one", "two", "root"])
	s.c = rng.int_in(2, 4)
	s.d = rng.int_in(1, 3)
	s.m = rng.int_in(2, 9)
	s.n = rng.int_in(2, 9)
	s.cx = rng.pick([2, 3, 5, 7])
	s.cy = rng.pick([2, 3, 5, 7])
	if s.shape == "one":
		s.co = Q.new(s.m, s.n)
		if s.m == s.n or (s.c == 2 and s.m == 5 and s.n == 2):
			return false
	else:
		s.co = Q.new(s.m)
	return s.cx != s.cy


## L of a product of powers of x and y, with p = L x and q = L y. i and j are the powers (Q).
## mul x^i y^j, div x^i/y^j, mulroot x^i √y, divroot x^i/√y, rootdiv √x/y^j, rootall √(x y^j),
## const b x^i/y^j, where b is the log's base.
static func _expand_letters(rng: Seeded, s: Dictionary) -> bool:
	pick_log(rng, s, [LOG_E, LOG_PLAIN, 2, 3, 5, 10])
	s.shape = rng.pick(["mul", "div", "mulroot", "divroot", "rootdiv", "rootall", "const"])
	if s.shape == "const" and s.b == 0:
		return false
	s.i = rng.int_in(1, 4)
	s.j = rng.int_in(1, 4)
	s.k = 0
	match s.shape:
		"mul":
			s.u = Q.new(s.i)
			s.v = Q.new(s.j)
			if s.i == 1 and s.j == 1:
				return false
		"div":
			s.u = Q.new(s.i)
			s.v = Q.new(-s.j)
		"mulroot":
			s.u = Q.new(s.i)
			s.v = Q.new(1, 2)
		"divroot":
			s.u = Q.new(s.i)
			s.v = Q.new(-1, 2)
			if s.i == 2:
				return false
		"rootdiv":
			s.u = Q.new(1, 2)
			s.v = Q.new(-s.j)
		"rootall":
			s.u = Q.new(1, 2)
			s.v = Q.new(s.j, 2)
		"const":
			s.u = Q.new(s.i)
			s.v = Q.new(-s.j)
			s.k = 1
	s.cx = rng.pick([2, 3, 5, 7])
	s.cy = rng.pick([2, 3, 5, 7])
	return s.cx != s.cy


## L N with L c = p and L d = q. N = c^i d^j. mul N is whole, div a fraction c^i/d^j, root √N;
## ten log N with N = 10 × 2^i 3^j, so k = 1 and i can be −1 (5 × 3^j).
static func _expand_numbers(rng: Seeded, s: Dictionary) -> bool:
	pick_log(rng, s, [LOG_E, LOG_PLAIN, 10])
	var pair: Array = rng.pick(PAIRS)
	s.p1 = pair[0]
	s.p2 = pair[1]
	s.shape = rng.pick(["mul", "div", "root", "ten"])
	s.k = 0
	if s.b == 10 and s.p1 == 2 and s.p2 == 5:
		return false
	match s.shape:
		"mul":
			s.i = rng.int_in(1, 4)
			s.j = rng.int_in(1, 4)
			s.N = ipow(s.p1, s.i) * ipow(s.p2, s.j)
			s.u = Q.new(s.i)
			s.v = Q.new(s.j)
			if s.N > MOST or (s.p1 == 2 and s.p2 == 3 and s.N == 24):
				return false
		"div":
			s.i = rng.int_in(1, 4)
			s.j = rng.int_in(1, 3)
			s.N = 0
			s.u = Q.new(s.i)
			s.v = Q.new(-s.j)
			if ipow(s.p1, s.i) > 100 or ipow(s.p2, s.j) > 100:
				return false
		"root":
			s.i = rng.int_in(1, 3)
			s.j = rng.int_in(1, 3)
			s.N = ipow(s.p1, s.i) * ipow(s.p2, s.j)
			s.u = Q.new(s.i, 2)
			s.v = Q.new(s.j, 2)
			if s.N > 200 or (s.i % 2 == 0 and s.j % 2 == 0):
				return false
		"ten":
			if s.b != 10 or s.p1 != 2 or s.p2 != 3:
				return false
			s.i = rng.int_in(-1, 3)
			s.j = rng.int_in(0, 2)
			s.k = 1
			s.N = Q.new(10 * ipow(2, maxi(s.i, 0)) * ipow(3, s.j), 2 if s.i < 0 else 1).n
			s.u = Q.new(s.i)
			s.v = Q.new(s.j)
			if s.N > MOST or (s.i == 0 and s.j == 0):
				return false
	return true


## L top ∓ L low = k L c. diff: top = low c^k. sum: top = c^i, low = c^j, i + j = k.
static func _show_number(rng: Seeded, s: Dictionary) -> bool:
	pick_log(rng, s, [LOG_E, LOG_PLAIN])
	s.c = rng.pick(PRIMES)
	s.k = rng.int_in(2, 5)
	s.shape = rng.pick(["diff", "diff", "sum"])
	if s.shape == "diff":
		s.low = rng.int_in(2, 9)
		s.top = s.low * ipow(s.c, s.k)
		if s.low % s.c == 0 or s.top > MOST or (s.top == 12 and s.low == 3 and s.c == 2):
			return false
	else:
		s.i = rng.int_in(1, s.k - 1)
		s.top = ipow(s.c, s.i)
		s.low = ipow(s.c, s.k - s.i)
		if s.top * s.low > 20000:
			return false
	s.val = Q.new(s.k)
	return true


## L a = m is given. recip L(1/a), pow L(a^r), root L(a^(1/r)), scale L(ba), over L(b/a),
## scalepow L(a^r/b), with b the log's base.
static func _given_laws(rng: Seeded, s: Dictionary) -> bool:
	s.base = rng.pick([2, 3, 5, 10])
	if s.base == 10:
		pick_log(rng, s, [LOG_PLAIN, 10])
	else:
		set_base(s, s.base)
	var f: Array = rng.pick(GIVEN)
	s.m = Q.new(f[0], f[1])
	s.r = rng.int_in(2, 3)
	s.shape = rng.pick(["recip", "pow", "root", "scale", "over", "scalepow"])
	match s.shape:
		"recip":
			s.val = s.m.neg()
		"pow":
			s.val = s.m.mul(s.r)
		"root":
			s.val = s.m.div(s.r)
		"scale":
			s.val = s.m.add(1)
		"over":
			s.val = Q.new(1).sub(s.m)
		"scalepow":
			s.val = s.m.mul(s.r).sub(1)
	return not s.val.is_zero()


## log_ab a = m: find log_ab b = 1 − m.
static func _ab_value(rng: Seeded, s: Dictionary) -> bool:
	var f: Array = rng.pick(AB_GIVEN)
	s.m = Q.new(f[0], f[1])
	var names: Array = rng.pick(LETTERS)
	s.l1 = names[0]
	s.l2 = names[1]
	s.val = Q.new(1).sub(s.m)
	return true


## log_ab a = m, and log_ab (a^e1 / b^e2) to find. root: e1 and e2 are 1/r and 1/t, pow: r and t.
static func _ab_hence(rng: Seeded, s: Dictionary) -> bool:
	var f: Array = rng.pick(AB_GIVEN)
	s.m = Q.new(f[0], f[1])
	var names: Array = rng.pick(LETTERS)
	s.l1 = names[0]
	s.l2 = names[1]
	s.shape = rng.pick(["root", "root", "pow"])
	s.r = rng.int_in(2, 3)
	s.t = rng.int_in(2, 3)
	if s.r == s.t:
		return false
	if s.shape == "root" and s.r == 3 and s.t == 2 and s.m.eq(3):
		return false
	s.e1 = Q.new(1, s.r) if s.shape == "root" else Q.new(s.r)
	s.e2 = Q.new(1, s.t) if s.shape == "root" else Q.new(s.t)
	s.mb = Q.new(1).sub(s.m)
	s.val = s.e1.mul(s.m).sub(s.e2.mul(s.mb))
	return not s.val.is_zero()


# ── Change of base ───────────────────────────────────────────

## One log to evaluate, by the powers of a prime p: base p^e, number p^t.
## whole e = 1;  recip the number is 1/p^t;  frac e > 1 and a fraction left;  surd base √p.
static func _evaluate_single(rng: Seeded, s: Dictionary) -> bool:
	s.shape = rng.pick(["whole", "recip", "frac", "frac", "surd"])
	s.p = rng.pick([2, 3, 5, 7])
	s.e = 1
	s.t = rng.int_in(2, top_power(s.p, MOST))
	match s.shape:
		"whole":
			if s.p == 3 and s.t == 4:
				return false
			set_base(s, s.p)
			s.val = Q.new(s.t)
		"recip":
			if s.p == 2 and s.t == 4:
				return false
			set_base(s, s.p)
			s.val = Q.new(-s.t)
		"frac":
			s.e = rng.int_in(2, 3)
			s.t = rng.int_in(1, 6)
			if ipow(s.p, s.e) > 32 or ipow(s.p, s.t) > 625 or s.t % s.e == 0:
				return false
			if (s.p == 3 and s.e == 2 and s.t == 1) or (s.p == 2 and s.e == 2 and s.t == 3):
				return false
			set_base(s, ipow(s.p, s.e))
			s.val = Q.new(s.t, s.e)
		"surd":
			if s.p == 3 and s.t == 4:
				return false
			s.b = s.p
			s.L = "log base √%d of" % s.p
			s.val = Q.new(2 * s.t)
	return true


## log_B of a root of p^t, with B = p^e: the root is 2 or 3. The value is t/(root × e).
## direct writes the log; function gives f(x) = B^x and asks f⁻¹.
static func _log_of_root(rng: Seeded, s: Dictionary) -> bool:
	s.shape = rng.pick(["direct", "function"])
	s.p = rng.pick([2, 3, 5])
	s.e = rng.int_in(2, 5)
	s.t = rng.int_in(1, 7)
	s.root = rng.pick([2, 2, 3])
	s.base = ipow(s.p, s.e)
	s.n = ipow(s.p, s.t)
	if s.base > 32 or s.n > 500 or s.n < 2 or s.t % s.root == 0:
		return false
	if s.base == 8 and s.n == 32 and s.root == 2:
		return false
	set_base(s, s.base)
	s.val = Q.new(s.t, s.root * s.e)
	return true


## log_c N in terms of H d and H c, with N = d^k. H is ln or log.
static func _cob_common(rng: Seeded, s: Dictionary) -> bool:
	pick_log(rng, s, [LOG_E, LOG_PLAIN])
	s.c = rng.pick([3, 5, 7, 11])
	s.d = rng.pick([2, 3, 5])
	s.k = rng.int_in(2, 5)
	s.N = ipow(s.d, s.k)
	return s.c != s.d and s.N <= MOST and not (s.N == 8 and s.c in [3, 5])


## log_B N in terms of p = H c and q = H d. plain B = d, N = c^k;  square B = d², N = c^k;
## mix B = d, N = c^k d^j. Over the same two logs.
static func _cob_pq(rng: Seeded, s: Dictionary) -> bool:
	pick_log(rng, s, [LOG_E, LOG_PLAIN, 10])
	var pair: Array = rng.pick(PAIRS)
	var flip := rng.chance(0.5)
	s.c = pair[1] if flip else pair[0]
	s.d = pair[0] if flip else pair[1]
	s.k = rng.int_in(2, 4)
	s.j = rng.int_in(1, 2)
	s.shape = rng.pick(["plain", "plain", "square", "mix"])
	if s.b == 10 and (s.c * s.d == 10):
		return false
	s.N = ipow(s.c, s.k) * (ipow(s.d, s.j) if s.shape == "mix" else 1)
	s.base = ipow(s.d, 2) if s.shape == "square" else s.d
	s.co = Q.new(s.k, 2) if s.shape == "square" else Q.new(s.k)
	if s.shape != "mix":
		s.j = 0
	return s.N <= MOST and not (s.shape == "plain" and s.N == 8 and s.d == 3)


## log_B a = m is given, for a base B, and log_(B^k) a^r is asked: r m / k.
static func _given_base(rng: Seeded, s: Dictionary) -> bool:
	s.base = rng.pick([2, 3, 5, 10])
	s.k = rng.int_in(2, 4)
	s.big = ipow(s.base, s.k)
	s.r = rng.pick([1, 1, 2, 3])
	var f: Array = rng.pick(GIVEN)
	s.m = Q.new(f[0], f[1])
	if s.big > MOST or (s.base == 10 and s.k == 3 and s.r == 1):
		return false
	set_base(s, s.base)
	s.big_L = log_of(s.big)
	s.val = s.m.mul(s.r).div(s.k)
	return true


## log_(b^k) x^r in terms of log_b x: r/k.
static func _base_power(rng: Seeded, s: Dictionary) -> bool:
	s.base = rng.pick([2, 3, 5, 7])
	s.k = rng.int_in(2, 3)
	s.r = rng.int_in(1, 3)
	s.big = ipow(s.base, s.k)
	if s.big > 125 or s.r == s.k or (s.base == 3 and s.k == 2 and s.r == 1):
		return false
	set_base(s, s.base)
	s.big_L = log_of(s.big)
	s.val = Q.new(s.r, s.k)
	return true


## log_base N to 3 s.f., on Paper 2.
static func _value_sf(rng: Seeded, s: Dictionary) -> bool:
	s.base = rng.pick([2, 3, 5, 6, 7, 9, 11, 12])
	s.N = rng.int_in(7, 200)
	s.over = rng.pick(["log", "ln"])
	set_base(s, s.base)
	if is_power(s.N, s.base) or (s.base == 3 and s.N == 20) or s.N == s.base:
		return false
	s.v = log(float(s.N)) / log(float(s.base))
	s.val = GdcKit.qf(s.v)
	return Answer.rounds_clearly(s.v, EDGE) and s.v < 9.0


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
