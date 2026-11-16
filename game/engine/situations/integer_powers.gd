class_name IntegerPowersSituation
extends RefCounted
## The `integer-powers` situation (curriculum/question-types.json): numbers and terms with
## whole-number exponents, some zero or negative, for t1-ext-exponent-laws (FAL-780). Every value is
## an exact Q and every exponent an int, so nothing has to fit a float.
##
## need.ask is the unknown (see IntegerPowersViews). generate() returns ask, paper (1: nothing needs a
## calculator), then by unknown:
##   negative-power      shape "whole": b^(−n) = 1/bⁿ;  shape "frac": (s/t)^(−n) = tⁿ/sⁿ
##   zero-and-negative   c⁰ + b^(−n) = 1 + 1/bⁿ
##   to-index-form       shape "top": c/xⁿ = cx^(−n);  shape "bottom": 1/(cxⁿ) = (1/c)x^(−n)
##   power-of-product    (axᵐ)ᵖ × bxⁿ = (aᵖb)x^(mp + n), with mp ≤ 12, mp + n ≤ 10 and aᵖb ≤ 250
##   two-letter-quotient (a^p b^q)/(a^r b^s) = a^(p − r) b^(q − s); ea and eb are those exponents
##   single-prime-power  A^m × B^n or A^m ÷ B^n (op "×" or "÷"), A = t^i, B = t^j: t^k
## and v, the answer: a Q for a value, else the exponents it needs.
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its own
## copy.

const TRIES := 4000
const PRIMES := [2, 3, 5]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "negative-power")
	var draws := IntegerPowersSituation.new()
	for i in TRIES:
		var s := {"ask": ask, "paper": int(need.get("paper", 1))}
		if draws.call("_" + ask.replace("-", "_"), rng, s):
			return s
	return {}


static func ipow(b: int, e: int) -> int:
	var r := 1
	for i in e:
		r *= b
	return r


## b^e for any whole e, as a Q.
static func qpow(b: Variant, e: int) -> Q:
	var base := Q.of(b)
	var r := Q.new(1)
	for i in absi(e):
		r = r.mul(base)
	return r if e >= 0 else Q.new(1).div(r)


static func _negative_power(rng: Seeded, s: Dictionary) -> bool:
	s.shape = "whole" if rng.chance(0.55) else "frac"
	if s.shape == "whole":
		s.b = rng.int_in(2, 6)
		s.n = rng.int_in(1, 3)
		if ipow(s.b, s.n) > 216:
			return false
		s.base = Q.new(s.b)
	else:
		var p: int = rng.int_in(2, 5)
		var q: int = rng.int_in(2, 5)
		if Q.gcd(p, q) != 1:
			return false
		s.base = Q.new(p, q)
		s.n = rng.int_in(2, 3)
	s.v = qpow(s.base, -s.n)
	return true


## c⁰ + b^(−n): c from 2 to 9, b from 2 to 6, bⁿ from 4 to 216, and c ≠ b.
static func _zero_and_negative(rng: Seeded, s: Dictionary) -> bool:
	s.c = rng.int_in(2, 9)
	s.b = rng.int_in(2, 6)
	s.n = rng.int_in(1, 3)
	var bn := ipow(s.b, s.n)
	if bn > 216 or bn < 4 or s.c == s.b:
		return false
	s.v = Q.new(1).add(Q.new(1, bn))
	return true


static func _to_index_form(rng: Seeded, s: Dictionary) -> bool:
	s.shape = "top" if rng.chance(0.5) else "bottom"
	s.c = rng.int_in(2, 9)
	s.n = rng.int_in(1, 4)
	s.a = Q.new(s.c) if s.shape == "top" else Q.new(1, s.c)
	s.p = -s.n
	return true


## (axᵐ)ᵖ × bxⁿ: aᵖ at most 125, the exponent e = mp + n not 0 or 1, and every slip's term different
## from the answer's.
static func _power_of_product(rng: Seeded, s: Dictionary) -> bool:
	s.a = rng.int_in(2, 5)
	s.m = rng.int_in(2, 5)
	s.pp = rng.int_in(2, 3)
	s.b = rng.int_in(1, 4)
	s.n = ExtensionViews.nonzero(rng, -7, 4)
	if ipow(s.a, s.pp) > 125:
		return false
	s.C = ipow(s.a, s.pp) * s.b
	s.e = s.m * s.pp + s.n
	# Small enough that substituting x = 2 checks it by hand.
	if s.m * s.pp > 12 or s.e > 10 or s.C > 250:
		return false
	return s.e != 0 and s.e != 1 and s.m + s.pp + s.n != s.e


## (a^p b^q)/(a^r b^s): each exponent from −4 to 5 and not 0, at least one negative; a^(p − r) and
## b^(q − s) have opposite signs, so the answer is a fraction with one letter on each line.
static func _two_letter_quotient(rng: Seeded, s: Dictionary) -> bool:
	s.ex = [0, 1, 2, 3].map(func(_i): return ExtensionViews.nonzero(rng, -4, 5))
	var ex: Array = s.ex
	s.ea = ex[0] - ex[2]
	s.eb = ex[1] - ex[3]
	if s.ea * s.eb >= 0 or not ex.any(func(v): return v < 0):
		return false
	# Adding instead gives exponents of its own, never the answer's or the wrong way round's.
	var add := [ex[0] + ex[2], ex[1] + ex[3]]
	return add != [s.ea, s.eb] and add != [-s.ea, -s.eb] and absi(s.ea) <= 9 and absi(s.eb) <= 9


## A^m op B^n with A = tⁱ and B = tʲ different, each at least t² and at most 125, m and n from −3 to 4 and
## not 0, so that k = im ± jn is from −20 to 20 and not 0.
static func _single_prime_power(rng: Seeded, s: Dictionary) -> bool:
	s.t = rng.pick(PRIMES)
	s.i = rng.int_in(1, 4)
	s.j = rng.int_in(1, 4)
	s.op = "×" if rng.chance(0.6) else "÷"
	s.m = ExtensionViews.nonzero(rng, -3, 4)
	s.n = ExtensionViews.nonzero(rng, -3, 4)
	s.A = ipow(s.t, s.i)
	s.B = ipow(s.t, s.j)
	if s.i == s.j or mini(s.i, s.j) < 2 or maxi(s.A, s.B) > 125:
		return false
	var sign := 1 if s.op == "×" else -1
	s.k = s.i * s.m + sign * s.j * s.n
	# The slip that drops the prime's powers, m ± n, must read differently from k.
	if s.k == 0 or absi(s.k) > 20 or s.m + sign * s.n == s.k:
		return false
	# A × B combined, its exponents added, must not be the answer's value by chance.
	return s.op == "÷" or not _same_value(s)


static func _same_value(s: Dictionary) -> bool:
	var e: int = s.m + s.n
	return qpow(s.A * s.B, e).eq(qpow(s.t, s.k))


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
