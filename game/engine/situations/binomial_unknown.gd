class_name BinomialUnknownSituation
extends RefCounted
## The `binomial-unknown` situation (curriculum/question-types.json): an expansion with something
## missing, for t1-binomial-find-unknown (FAL-740). t1-binomial-term gives the bracket and asks for
## a coefficient. This runs it backwards: the coefficient is given, and a letter in the bracket, or
## n, or x itself, is found. The letter's value is drawn first and every given is worked out from
## it, exactly, with Q, so the answer is known to come out.
##
## need.ask is the unknown (see BinomialUnknownViews). generate() returns a Dictionary:
##   paper, ask, rep, angle
##   n         the power
##   letter    the letter to find, k or a
##   shape     1kx (1 + kx), ckx (c + kx), xk (x + k), cxk (cx + k)
##   flip      the number is written the other way round: (k + 2x)
##   c         the number in the bracket (1 in 1kx and xk)
##   p         the power of x in the bracket, 1 or 2 (or 3 in two-brackets)
##   e         the power of the letter in the term
##   m         the power of x in the term
##   mult      the term's number: nCe × c^(n − e)
##   val       the letter's value, Q; 0 when it's a surd
##   d         the letter is ±√d, so val isn't a Q; else 0
##   coef      the coefficient given, Q
##   both      two values are asked for; else one
##   positive  the question says the letter is positive
##   j         the lower power of x, for n-from-coefficient and the equal and ratio unknowns
##   k         the number in the bracket when n is found, a whole number or Q (see each draw)
##   ratio     the coefficient of x^(j + 1) ÷ the coefficient of x^j, Q
##   N, shift  n-from-power-bracket: the bracket's power is n + shift = N
##   n2, t, a, b, v1, v2  two-brackets: (ax^p + b)^n and ^n2 have v1 and v2 at x^(p·t)
##   t, top, a, R, c  quotient-coefficient: (ax + 1)^n ÷ (cx^p) has R·a^(t − 1) at x^(t − p)
##   r, x1, x2  term-mean: terms r and r + 2 of (x + c)^n, counting from 0, have mean term r + 1
##
## Paper 1 stays by hand: coefficients to 20000 and surds written exactly. Paper 2 goes to
## 200000000 and n = 12, a surd is to 3 s.f., and the GDC methods are there and nowhere else.
## The bank's own brackets, and the skill's worked examples, are left out (see BANK).
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 4000
const HAND := 20000
const MOST := 200000000
## Square-free, so ±√d is as simple as it goes.
const SURDS := [2, 3, 5, 6, 7, 10]
const FRACTIONS := [[1, 2], [3, 2], [1, 3], [2, 3], [5, 2], [3, 4], [4, 3]]
## [n, r] where the mean of terms r − 1 and r + 1 gives a quadratic with rational roots.
const MEAN_EXACT := [[7, 2], [7, 5], [8, 1], [8, 4], [14, 5]]
## [shape, c, n, e], the bank's brackets and the skill's examples.
const BANK := [["xk", 1, 7, 2], ["xk", 1, 11, 4], ["cxk", 2, 10, 4], ["1kx", 1, 8, 2], ["ckx", 2, 5, 3]]
const GDC := "gdc-search"


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	for i in TRIES:
		var s := {"paper": int(need.get("paper", 1)), "ask": need.get("ask", "k-both-signs"), "rep": need.get("rep", "equation"),
			"angle": need.get("angle", ""), "n": 0, "letter": "k", "shape": "1kx", "flip": false, "c": 1, "p": 1, "e": 0, "m": 0,
			"mult": Q.new(1), "val": Q.new(0), "d": 0, "coef": Q.new(0), "both": false, "positive": false, "j": 0, "k": Q.new(0),
			"ratio": Q.new(0), "N": 0, "shift": 0, "n2": 0, "t": 0, "top": 0, "a": Q.new(0), "b": Q.new(0), "v1": Q.new(0),
			"v2": Q.new(0), "R": Q.new(0), "r": 0, "x1": Q.new(0), "x2": Q.new(0)}
		if _draw(rng, s):
			return s
	return {}


# ── The numbers ──────────────────────────────────────────────

static func ncr(n: int, r: int) -> int:
	return BinomialExpansionSituation.ncr(n, r)


static func power(v: int, e: int) -> int:
	return BinomialExpansionSituation.power(v, e)


static func qpow(v: Q, e: int) -> Q:
	var out := Q.new(1)
	for i in e:
		out = out.mul(v)
	return out


static func int_root(v: int, e: int) -> int:
	var r := roundi(pow(float(v), 1.0 / e))
	for t in [r - 1, r, r + 1]:
		if t >= 0 and power(t, e) == v:
			return t
	return -1


## The positive e-th root of a positive Q when it is a Q, else null.
static func exact_root(v: Q, e: int) -> Variant:
	if v.sign() <= 0:
		return null
	var a := int_root(v.n, e)
	var b := int_root(v.d, e)
	return Q.new(a, b) if a >= 0 and b > 0 else null


static func limit(s: Dictionary) -> int:
	return HAND if s.paper == 1 else MOST


static func small(s: Dictionary, v: Q) -> bool:
	return absf(v.to_float()) <= limit(s) and v.d <= 100


static func fraction(rng: Seeded) -> Q:
	var f: Array = rng.pick(FRACTIONS)
	return Q.new(f[0], f[1])


## How many numbers the term of the letter is, in (c + kx)^n and in (cx + k)^n alike.
static func fill(s: Dictionary) -> void:
	s.mult = Q.new(ncr(s.n, s.e) * power(s.c, s.n - s.e))
	s.m = s.p * (s.e if s.shape in ["1kx", "ckx"] else s.n - s.e)
	s.coef = s.mult.mul(Q.new(power(s.d, s.e / 2))) if s.d > 0 else s.mult.mul(qpow(s.val, s.e))


static func in_bank(s: Dictionary) -> bool:
	return BANK.any(func(b): return b[0] == s.shape and b[1] == s.c and b[2] == s.n and b[3] == s.e)


## The letter's place, and its power e. n is drawn past e.
static func _bracket(rng: Seeded, s: Dictionary, shapes: Array, e: int) -> bool:
	s.shape = rng.pick(shapes)
	s.c = 1 if s.shape in ["1kx", "xk"] else rng.int_in(2, 3 if s.paper == 1 else 4)
	s.flip = s.shape in ["ckx", "cxk"] and rng.chance(0.25)
	s.e = e
	s.n = rng.int_in(4, 8) if s.paper == 1 else rng.int_in(6, 12)
	return s.n > e and not in_bank(s)


# ── Drawing ──────────────────────────────────────────────────

static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"k-odd-power":
			return _k_odd(rng, s)
		"k-both-signs":
			return _k_even(rng, s, true)
		"k-surd-both-signs":
			return _k_surd(rng, s, true)
		"k-positive-condition":
			s.positive = true
			return _k_surd(rng, s, false) if rng.chance(0.5) else _k_even(rng, s, false)
		"a-in-bracket":
			return _a_in_bracket(rng, s)
		"n-from-coefficient":
			return _n_from_coefficient(rng, s)
		"n-from-power-bracket":
			return _n_from_power(rng, s)
		"n-and-k-from-expansion":
			return _n_and_k(rng, s)
		"n-and-k-two-coefficients":
			return _two_coefficients(rng, s)
		"equal-find-k":
			return _equal_k(rng, s)
		"equal-find-n":
			return _equal_n(rng, s)
		"ratio-find-k":
			return _ratio_k(rng, s)
		"ratio-find-n":
			return _ratio_n(rng, s)
		"two-brackets":
			return _two_brackets(rng, s)
		"quotient-coefficient":
			return _quotient(rng, s)
		"term-mean":
			return _term_mean(rng, s)
	return false


static func _k_odd(rng: Seeded, s: Dictionary) -> bool:
	if not _bracket(rng, s, ["1kx", "ckx", "xk", "cxk"], rng.pick([3] if s.paper == 1 else [3, 3, 5])):
		return false
	var size: int = rng.int_in(2, 3 if s.paper == 1 else 4)
	s.val = Q.new(-size if rng.chance(0.4) else size)
	fill(s)
	return small(s, s.coef)


static func _k_even(rng: Seeded, s: Dictionary, both: bool) -> bool:
	if not _bracket(rng, s, ["1kx", "ckx", "xk", "cxk"], rng.pick([2, 2, 4])):
		return false
	s.both = both
	s.val = Q.new(rng.int_in(2, 4 if s.paper == 1 else 5))
	fill(s)
	return small(s, s.coef)


## k² = d, so the answer has a root in it. The bank asks this of (x + k), so it's the main case.
static func _k_surd(rng: Seeded, s: Dictionary, both: bool) -> bool:
	if not _bracket(rng, s, ["xk", "xk", "1kx", "cxk"], rng.pick([2, 2, 4])):
		return false
	s.both = both
	s.d = rng.pick(SURDS)
	fill(s)
	return small(s, s.coef)


## a is drawn as a fraction or a whole number, and is said to be positive.
static func _a_in_bracket(rng: Seeded, s: Dictionary) -> bool:
	s.letter = "a"
	if not _bracket(rng, s, ["ckx", "cxk"], rng.int_in(2, 3)):
		return false
	s.positive = true
	s.p = rng.pick([1, 1, 2])
	s.val = fraction(rng) if rng.chance(0.6) else Q.new(rng.int_in(2, 4))
	fill(s)
	return small(s, s.coef)


## nC2 k² on paper; the GDC may also meet nC3 k³, where the working by hand is a cubic.
static func _n_from_coefficient(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.int_in(4, 10 if s.paper == 1 else 12)
	var k: int = rng.int_in(2, 4)
	s.k = Q.new(-k if rng.chance(0.3) else k)
	s.j = 3 if s.angle == GDC and rng.chance(0.4) else 2
	s.coef = Q.new(ncr(s.n, s.j)).mul(qpow(s.k, s.j))
	return small(s, s.coef) and s.n > s.j and not (s.n == 8 and k == 2)


## (c + x^p)^(n + shift): n is in the power of c too, so no algebra solves it.
static func _n_from_power(rng: Seeded, s: Dictionary) -> bool:
	s.N = rng.int_in(5, 9)
	s.c = rng.int_in(2, 5)
	s.p = rng.int_in(1, 2)
	s.shift = rng.pick([1, 1, 2, -1])
	s.n = s.N - s.shift
	s.coef = Q.new(ncr(s.N, 2) * power(s.c, s.N - 2))
	return small(s, s.coef) and not (s.c == 3 and s.N == 8)


## 1 + (nk)x + (nC2)k²x² + ...: the k² is left as a letter, so nC2 can be read off.
static func _n_and_k(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.int_in(5, 12)
	var k: Q = fraction(rng) if rng.chance(0.7) else Q.new(rng.int_in(2, 3))
	s.k = k.neg() if rng.chance(0.25) else k
	s.coef = Q.new(s.n).mul(s.k)
	var plain: bool = (s.n == 8 and s.coef.eq(12)) or (s.n == 6 and s.coef.eq(Q.new(9, 2)))
	return s.coef.d <= 2 and absi(s.coef.n) >= 2 and not plain


static func _two_coefficients(rng: Seeded, s: Dictionary) -> bool:
	s.letter = "a"
	s.n = rng.int_in(4, 12)
	var a: Q = fraction(rng) if rng.chance(0.5) else Q.new(rng.int_in(2, 4))
	s.a = a.neg() if rng.chance(0.25) else a
	s.v1 = Q.new(s.n).mul(s.a)
	s.v2 = Q.new(ncr(s.n, 2)).mul(s.a.sq())
	return s.v1.is_int() and s.v2.is_int() and not (s.n == 6 and a.eq(2)) and absi(s.v1.n) >= 2 and small(s, s.v2)


static func _equal_k(rng: Seeded, s: Dictionary) -> bool:
	s.j = rng.int_in(1, 3)
	s.n = rng.int_in(s.j + 2, 12)
	s.k = Q.new(s.j + 1, s.n - s.j)
	return not s.k.eq(1) and not (s.n == 6 and s.j == 1)


## (1 + kx)^n or (c + x)^n, where n − j = (j + 1) ÷ k or c(j + 1).
static func _equal_n(rng: Seeded, s: Dictionary) -> bool:
	s.j = rng.int_in(1, 5)
	if rng.chance(0.5):
		s.shape = "1kx"
		s.k = Q.new(rng.int_in(2, 3))
		s.n = s.j + Q.new(s.j + 1).div(s.k).n
		return Q.new(s.j + 1).div(s.k).is_int() and s.n >= 5 and s.n <= 14
	s.shape = "cx"
	s.c = rng.int_in(2, 3)
	s.n = s.j + s.c * (s.j + 1)
	return s.n >= 5 and s.n <= 14


static func _ratio(s: Dictionary) -> bool:
	s.ratio = Q.new(s.n - s.j, s.j + 1).mul(s.k)
	return not s.ratio.eq(1) and s.ratio.n <= 40 and s.ratio.d <= 40


static func _ratio_k(rng: Seeded, s: Dictionary) -> bool:
	s.j = rng.int_in(1, 3)
	s.n = rng.int_in(s.j + 2, 12)
	s.k = fraction(rng) if rng.chance(0.4) else Q.new(rng.int_in(2, 5))
	return _ratio(s)


static func _ratio_n(rng: Seeded, s: Dictionary) -> bool:
	s.j = rng.int_in(1, 3)
	s.n = rng.int_in(s.j + 2, 12)
	s.k = Q.new(rng.int_in(2, 5))
	return _ratio(s)


## (ax^p + b)^n and (ax^p + b)^n2: the same term has a^t in both, so dividing leaves b.
static func _two_brackets(rng: Seeded, s: Dictionary) -> bool:
	s.letter = "a"
	s.a = rng.pick([Q.new(1, 2), Q.new(1, 3), Q.new(2), Q.new(3)])
	s.b = Q.new(rng.int_in(2, 4))
	s.t = rng.int_in(2, 3)
	s.p = rng.int_in(2, 3)
	s.n = rng.int_in(s.t + 2, 8)
	s.n2 = s.n + rng.int_in(1, 2)
	s.v1 = Q.new(ncr(s.n, s.t)).mul(qpow(s.a, s.t)).mul(qpow(s.b, s.n - s.t))
	s.v2 = Q.new(ncr(s.n2, s.t)).mul(qpow(s.a, s.t)).mul(qpow(s.b, s.n2 - s.t))
	var plain: bool = s.n == 8 and s.n2 == 10 and s.t == 2 and s.p == 3
	return s.v1.is_int() and s.v2.is_int() and small(s, s.v1) and small(s, s.v2) and not plain


## (ax + 1)^n ÷ (cx^p): the term at x^m comes from x^(m + p) on top. c divides its nCr.
static func _quotient(rng: Seeded, s: Dictionary) -> bool:
	s.letter = "a"
	s.n = rng.int_in(6, 12)
	s.p = rng.int_in(2, 3)
	s.t = rng.int_in(4, s.n - 1)
	s.m = s.t - s.p
	s.flip = rng.chance(0.3)
	var top: int = ncr(s.n, s.t)
	var cs: Array = range(2, 41).filter(func(c): return top % c == 0)
	if cs.is_empty():
		return false
	s.c = rng.pick(cs)
	s.top = top / s.c
	s.a = fraction(rng) if rng.chance(0.7) else Q.new(rng.int_in(2, 3))
	s.R = Q.new(s.top).mul(s.a)
	return not (s.n == 9 and s.c == 21) and s.R.d <= 30 and s.R.n <= 400


static func _term_mean(rng: Seeded, s: Dictionary) -> bool:
	s.c = rng.int_in(1, 3)
	var A: int
	var B: int
	var D: int
	if s.paper == 1:
		var pair: Array = rng.pick(MEAN_EXACT)
		s.n = pair[0]
		s.r = pair[1]
		if s.n == 7 and s.r == 2 and s.c == 1:
			return false
	else:
		s.n = rng.int_in(5, 12)
		s.r = rng.int_in(1, s.n - 2)
	A = ncr(s.n, s.r - 1)
	B = ncr(s.n, s.r)
	D = ncr(s.n, s.r + 1)
	var disc: int = B * B - A * D
	if disc <= 0 or ncr(s.n, s.r) * power(s.c, s.r + 1) > limit(s):
		return false
	var root := sqrt(float(disc))
	var lo: float = s.c * (B - root) / A
	var hi: float = s.c * (B + root) / A
	if s.paper == 1:
		var rt := int_root(disc, 2)
		s.x1 = Q.new(s.c * (B - rt), A)
		s.x2 = Q.new(s.c * (B + rt), A)
		return true
	s.x1 = GdcKit.qf(lo)
	s.x2 = GdcKit.qf(hi)
	return Answer.rounds_clearly(lo) and Answer.rounds_clearly(hi) and Fmt.sf(lo) != Fmt.sf(hi) and lo > 0.05


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
