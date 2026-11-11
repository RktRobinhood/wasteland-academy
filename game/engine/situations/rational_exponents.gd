class_name RationalExponentsSituation
extends RefCounted
## The `rational-exponents` situation (curriculum/question-types.json): one power with a
## rational exponent, for t1-rational-exponents (FAL-754). A number to evaluate, a base to find
## from x^(m/n) = k, a root or a product of powers of x to write as one power, a bracket to
## simplify, or a quotient to split into powers of x. Paper 1 only, so every number is drawn as
## a perfect power first and everything comes out exactly with Q.
##
## need.ask is the unknown (see RationalExponentsViews). generate() returns a Dictionary:
##   ask      the unknown
##   shape    the draw's variant, named in each function
##   val      the exact answer, Q, where the answer is a number
##   the rest are the draw's own numbers, named in each function
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy. The skill map's examples and the bank's numbers are left out.

const TRIES := 4000
## Bases whose powers are drawn: each a power of one prime, so prime-base always works.
const BASES := [2, 3, 4, 5, 7, 8, 9]
## The most a number shown may be, and the most a power-then-root working may reach.
const MOST := 1024
const BIG := 2000000
const PRIMES := [2, 3, 5]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "value-fraction")
	for i in TRIES:
		var s := {"paper": 1, "ask": ask, "shape": "", "val": Q.new(0)}
		if _draw(rng, s):
			return s
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"value-fraction":
			return _value(rng, s, 1)
		"value-negative":
			return _value(rng, s, -1)
		"value-fraction-base":
			return _fraction_base(rng, s)
		"solve-base":
			return _solve_base(rng, s)
		"root-as-power":
			return _root_as_power(rng, s)
		"root-product-as-power":
			return _root_product(rng, s)
		"bracket-power":
			return _bracket(rng, s)
		"product-x":
			return _product_x(rng, s)
		"quotient-x":
			return _quotient_x(rng, s)
		"product-numbers":
			return _product_numbers(rng, s)
		"split-two":
			return _split(rng, s, 2)
		"split-three":
			return _split(rng, s, 3)
	return false


# ── Small tools ──────────────────────────────────────────────

static func ipow(b: int, e: int) -> int:
	var r := 1
	for i in e:
		r *= b
	return r


## A rational power of a rational number that is known to be exact: (u/v)^(e), e whole.
static func qpow(v: Q, e: int) -> Q:
	var out := Q.new(1)
	for i in absi(e):
		out = out.mul(v)
	return Q.new(1).div(out) if e < 0 else out


## The prime a base is a power of, and that power: 8 is [2, 3].
static func prime_of(b: int) -> Array:
	for p in [2, 3, 5, 7]:
		var k := 0
		var n := b
		while n % p == 0:
			n /= p
			k += 1
		if n == 1 and k > 0:
			return [p, k]
	return [b, 1]


## m and n with no common factor, n from the list, m from 1 to top, m/n not whole.
static func pick_frac(rng: Seeded, ns: Array, top: int) -> Array:
	var n: int = rng.pick(ns)
	var m := rng.int_in(1, top)
	if Q.gcd(m, n) != 1 or m % n == 0:
		return []
	return [m, n]


# ── Values ───────────────────────────────────────────────────

## a^(sign m/n) with a = b^n. The value is b^m, or 1/b^m.
static func _value(rng: Seeded, s: Dictionary, sgn: int) -> bool:
	var f := pick_frac(rng, [2, 2, 3, 3, 4, 5], 5)
	if f.is_empty():
		return false
	s.m = f[0]
	s.n = f[1]
	s.sgn = sgn
	s.b = rng.pick(BASES)
	s.a = ipow(s.b, s.n)
	if s.m == 1:
		return false
	if s.a > MOST or ipow(s.b, s.m) > MOST or float(s.a) ** s.m > BIG:
		return false
	# The map's examples: 8^(2/3) and 27^(−1/3).
	if (s.a == 8 and s.m == 2 and s.n == 3 and sgn > 0) or (s.a == 27 and s.m == 1 and s.n == 3 and sgn < 0):
		return false
	var p: Array = prime_of(s.b)
	s.p = p[0]
	s.k = p[1]
	s.e = Q.new(sgn * s.m, s.n)
	s.val = qpow(Q.new(s.b), sgn * s.m)
	return true


## (c/d)^(sign m/n) with c = u^n and d = v^n. The value is (u/v)^m, or (v/u)^m.
static func _fraction_base(rng: Seeded, s: Dictionary) -> bool:
	var f := pick_frac(rng, [2, 2, 3, 3, 4], 3)
	if f.is_empty():
		return false
	s.m = f[0]
	s.n = f[1]
	s.sgn = -1 if rng.chance(0.6) else 1
	s.u = rng.int_in(1, 5)
	s.v = rng.int_in(2, 5)
	if s.m == 1 or s.u == s.v or Q.gcd(s.u, s.v) != 1:
		return false
	s.c = ipow(s.u, s.n)
	s.d = ipow(s.v, s.n)
	if s.c > 625 or s.d > 625 or float(maxi(s.c, s.d)) ** s.m > BIG:
		return false
	s.e = Q.new(s.sgn * s.m, s.n)
	s.val = qpow(Q.new(s.u, s.v), s.sgn * s.m)
	return true


## x^(sign m/n) = k, x > 0, with x = b^n and k = b^m (or 1/b^m). The answer is x = b^n.
static func _solve_base(rng: Seeded, s: Dictionary) -> bool:
	var f := pick_frac(rng, [2, 3, 3, 4, 5], 4)
	if f.is_empty():
		return false
	s.m = f[0]
	s.n = f[1]
	s.sgn = -1 if rng.chance(0.3) else 1
	s.b = rng.pick(BASES)
	s.x = ipow(s.b, s.n)
	var km := ipow(s.b, s.m)
	if s.x > 100000 or km > MOST or float(km) ** s.n > 20000000.0 or s.m == 1:
		return false
	# The bank's equation: a^(2/3) = 4.
	if s.m == 2 and s.n == 3 and s.b == 2:
		return false
	var p: Array = prime_of(s.b)
	s.p = p[0]
	s.k = p[1]
	s.e = Q.new(s.sgn * s.m, s.n)
	s.rhs = qpow(Q.new(s.b), s.sgn * s.m)
	s.val = Q.new(s.x)
	return true


# ── Powers of x ──────────────────────────────────────────────

## inside ⁿ√(x^m), outside (ⁿ√x)^m, recip 1/ⁿ√(x^m), with n 2 or 3. pw is the power of x.
static func _root_as_power(rng: Seeded, s: Dictionary) -> bool:
	s.shape = rng.pick(["inside", "outside", "recip", "recip"])
	s.n = rng.pick([2, 3])
	s.m = rng.int_in(1, 5)
	if s.m % s.n == 0 or (s.shape == "outside" and s.m == 1):
		return false
	# √x and 1/√x are the map's and the bank's.
	if s.n == 2 and s.m == 1:
		return false
	s.pw = Q.new(-s.m if s.shape == "recip" else s.m, s.n)
	return true


## times x^k ⁿ√x, under 1/(x^k ⁿ√x), over ⁿ√x/x^k, top x^k/ⁿ√x.
static func _root_product(rng: Seeded, s: Dictionary) -> bool:
	s.shape = rng.pick(["times", "under", "over", "top"])
	s.n = rng.pick([2, 3])
	s.k = rng.int_in(1, 3)
	# 1/(x√x) is the map's.
	if s.shape == "under" and s.k == 1 and s.n == 2:
		return false
	var r := Q.new(1, s.n)
	match s.shape:
		"times":
			s.pw = r.add(s.k)
		"under":
			s.pw = r.add(s.k).neg()
		"over":
			s.pw = r.sub(s.k)
		"top":
			s.pw = Q.new(s.k).sub(r)
	return true


## (c x^q)^(sign m/n), c = b^n. The answer is C x^P: C = b^(sign m), P = q × sign m/n.
static func _bracket(rng: Seeded, s: Dictionary) -> bool:
	var f := pick_frac(rng, [2, 2, 3, 3, 4], 3)
	if f.is_empty():
		return false
	s.m = f[0]
	s.n = f[1]
	s.sgn = -1 if rng.chance(0.3) else 1
	s.b = rng.pick(BASES)
	s.c = ipow(s.b, s.n)
	s.q = rng.int_in(1, 8)
	if s.m == 1 or s.c > 625 or float(s.c) ** s.m > BIG or ipow(s.b, s.m) > 512:
		return false
	# The map's example: (16x⁴)^(3/4).
	if s.c == 16 and s.q == 4 and s.m == 3 and s.n == 4:
		return false
	var p: Array = prime_of(s.b)
	s.p = p[0]
	s.k = p[1]
	s.e = Q.new(s.sgn * s.m, s.n)
	s.co = qpow(Q.new(s.b), s.sgn * s.m)
	s.pw = s.e.mul(s.q)
	return true


## A fraction power for x: numerator from −5 to 5, not 0, denominator 2 to 6, not whole.
static func x_power(rng: Seeded) -> Q:
	var d: int = rng.pick([2, 3, 4, 5, 6])
	var n := 0
	while n == 0 or n % d == 0:
		n = rng.int_in(-5, 5)
	return Q.new(n, d)


## (a1 x^e1) × (a2 x^e2). The coefficients are both 1 or both whole, from 2 to 6.
static func _product_x(rng: Seeded, s: Dictionary) -> bool:
	s.e1 = x_power(rng)
	s.e2 = x_power(rng)
	s.shape = "coef" if rng.chance(0.4) else "plain"
	s.a1 = rng.int_in(2, 6) if s.shape == "coef" else 1
	s.a2 = rng.int_in(2, 6) if s.shape == "coef" else 1
	s.pw = s.e1.add(s.e2)
	s.co = Q.new(s.a1 * s.a2)
	if s.pw.is_zero() or s.e1.eq(s.e2) or s.e1.mul(s.e2).eq(s.pw):
		return false
	# The map's x^(1/2) × x^(1/3).
	if (s.e1.eq(Q.new(1, 2)) and s.e2.eq(Q.new(1, 3))) or (s.e1.eq(Q.new(1, 3)) and s.e2.eq(Q.new(1, 2))):
		return false
	return s.e1.d != s.e2.d or rng.chance(0.3)


## (A x^e1)/(B x^e2) with A = B r. The answer is r x^(e1 − e2).
static func _quotient_x(rng: Seeded, s: Dictionary) -> bool:
	s.e1 = x_power(rng)
	s.e2 = x_power(rng)
	s.B = rng.pick([1, 1, 2, 3, 4])
	s.r = rng.int_in(1, 6)
	s.A = s.B * s.r
	s.pw = s.e1.sub(s.e2)
	s.co = Q.new(s.r)
	if s.pw.is_zero() or s.e1.eq(s.e2) or s.e2.is_zero() or s.e1.div(s.e2).eq(s.pw) or (s.A == 1 and s.B == 1 and rng.chance(0.5)):
		return false
	return true


## A^r op B^s with A = p^i and B = p^j, neither power whole on its own, and the result p^T
## with T whole. op is "×" or "÷".
static func _product_numbers(rng: Seeded, s: Dictionary) -> bool:
	s.p = rng.pick(PRIMES)
	s.i = rng.int_in(1, 6)
	s.j = rng.int_in(1, 6)
	s.A = ipow(s.p, s.i)
	s.B = ipow(s.p, s.j)
	if s.i == s.j or s.A > 729 or s.B > 729:
		return false
	s.op = "÷" if rng.chance(0.4) else "×"
	s.r = x_power(rng)
	s.s = x_power(rng)
	var ri: Q = s.r.mul(s.i)
	var sj: Q = s.s.mul(s.j)
	if ri.is_int() or sj.is_int() or s.r.d > 4 or s.s.d > 4:
		return false
	var t: Q = ri.add(sj) if s.op == "×" else ri.sub(sj)
	if not t.is_int() or t.is_zero() or t.n < -3 or t.n > 6 or ipow(s.p, absi(t.n)) > 1000:
		return false
	s.ri = ri
	s.sj = sj
	s.T = t.n
	s.val = qpow(Q.new(s.p), t.n)
	return true


## The denominator of a split: its power and how it is written.
const DENOMS := [[1, 2, "√x"], [1, 3, "∛x"], [3, 2, "x√x"], [2, 3, "∛(x²)"]]


## (A x^m + B)/(k D) for two terms, (A x² + B x + C)/(k D) for three; D is a root of x.
## tops: [[coefficient, power]], from the highest power down. The answer is Σ (c/k) x^(p − d).
static func _split(rng: Seeded, s: Dictionary, count: int) -> bool:
	var den: Array = rng.pick(DENOMS) if count == 2 else rng.pick(DENOMS.slice(0, 2))
	s.dpow = Q.new(den[0], den[1])
	s.dtext = den[2]
	s.k = rng.pick([1, 1, 1, 2])
	var tops: Array = []
	if count == 2:
		tops = [[rng.pick([1, 1, 2, 3, 4, 5]), rng.int_in(1, 4)], [ExtensionViews.nonzero(rng, -9, 9), 0]]
	else:
		var hi := rng.int_in(2, 3)
		var mid := rng.int_in(1, hi - 1)
		tops = [[rng.pick([1, 1, 2, 3]), hi], [ExtensionViews.nonzero(rng, -8, 8), mid], [ExtensionViews.nonzero(rng, -9, 9), 0]]
	s.tops = tops
	if s.k > 1:
		var all_even := true
		for t in tops:
			if t[0] % s.k != 0:
				all_even = false
		# A 2 under every coefficient that it divides would be cancelled first.
		if all_even:
			return false
	# The map's (x² − 2)/√x.
	if count == 2 and s.k == 1 and tops[0][0] == 1 and tops[0][1] == 2 and tops[1][0] == -2 and s.dtext == "√x":
		return false
	var cs: Array = []
	var ps: Array = []
	for t in tops:
		cs.append(Q.new(t[0], s.k))
		ps.append(Q.new(t[1]).sub(s.dpow))
	s.cs = cs
	s.ps = ps
	return true


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
