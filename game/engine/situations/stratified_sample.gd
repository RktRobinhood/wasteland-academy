class_name StratifiedSampleSituation
extends RefCounted
## The `stratified-sample` situation (curriculum/question-types.json): a population in three groups
## and a stratified sample from it, for t4-ext-stratified-numbers (FAL-778). The stories are
## SamplingViews.CONTEXTS. A group's number in the sample is G × n ÷ N.
##
## generate() returns ask, paper, ctx, G (the three group sizes), N, n, g (the group asked about)
## and, by unknown:
##   stratum-count, sample-size-from-stratum  every share whole (G = k q, N = k n)
##   stratum-count-rounded   the asked share at least 0.1 from a half; more often rounding up
##   last-stratum            g = 2; the three rounded shares don't add to n
##   stratum-from-percent    pct, the groups as whole percentages, and n a multiple of 20
## Every group size is different, and so is every share.

const TRIES := 4000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "stratum-count")
	var paper := int(need.get("paper", 1))
	for i in TRIES:
		var s := {"ask": ask, "paper": paper, "ctx": rng.int_in(0, SamplingViews.CONTEXTS.size() - 1), "g": rng.int_in(0, 2), "pct": []}
		var ok := false
		match ask:
			"stratum-count", "sample-size-from-stratum":
				ok = _whole(rng, s)
			"stratum-count-rounded":
				ok = _rounded(rng, s, rng.chance(0.65))
			"last-stratum":
				s.g = 2
				ok = _off_by_one(rng, s)
			"stratum-from-percent":
				ok = _percent(rng, s)
		if ok:
			return s
	push_error("StratifiedSampleSituation: no clean situation for %s" % need)
	return {}


## Three different group sizes and a sample size.
static func _groups(rng: Seeded, s: Dictionary, lo: int, hi: int) -> void:
	s.G = [rng.int_in(lo, hi), rng.int_in(lo, hi), rng.int_in(lo, hi)]
	s.N = s.G[0] + s.G[1] + s.G[2]


static func _distinct(xs: Array) -> bool:
	return xs[0] != xs[1] and xs[1] != xs[2] and xs[0] != xs[2]


## A group's share of the sample, exactly.
static func share(s: Dictionary, i: int) -> Q:
	return Q.new(s.G[i] * s.n, s.N)


## Rounded to the nearest whole number (a share is never exactly a half here).
static func rounded(x: Q) -> int:
	return floori(x.to_float() + 0.5)


## How far the decimal part of x is from a half.
static func from_half(x: Q) -> float:
	var f := x.to_float() - floorf(x.to_float())
	return absf(f - 0.5)


static func _whole(rng: Seeded, s: Dictionary) -> bool:
	var n: int = rng.int_in(10, 40) if s.paper == 1 else rng.int_in(40, 120)
	var k: int = rng.int_in(4, 12) if s.paper == 1 else rng.int_in(5, 20)
	var a := rng.int_in(2, n - 4)
	var b := rng.int_in(2, n - a - 2)
	var q := [a, b, n - a - b]
	if not _distinct(q) or q.min() < 2:
		return false
	s.n = n
	s.G = q.map(func(x): return x * k)
	s.N = n * k
	if s.G.max() > (400 if s.paper == 1 else 3000):
		return false
	# An equal split is a whole number only if n divides by 3; it must not be the answer.
	return not (n % 3 == 0 and n / 3 == q[s.g])


static func _rounded(rng: Seeded, s: Dictionary, up: bool) -> bool:
	if s.paper == 1:
		_groups(rng, s, 30, 400)
		s.n = rng.int_in(12, 60)
	else:
		_groups(rng, s, 200, 3000)
		s.n = rng.int_in(40, 150)
	if not _distinct(s.G):
		return false
	var x := share(s, s.g)
	var f := x.to_float() - floorf(x.to_float())
	if x.is_int() or from_half(x) < 0.1 or (f > 0.5) != up or x.to_float() < 1.0:
		return false
	var r: Array = [0, 1, 2].map(func(i): return rounded(share(s, i)))
	return _distinct(r) and _not_third(s, rounded(x))


## n ÷ 3 rounded is the equal split's option: it must differ from the answer.
static func _not_third(s: Dictionary, answer: int) -> bool:
	return floori(s.n / 3.0 + 0.5) != answer


static func _off_by_one(rng: Seeded, s: Dictionary) -> bool:
	if not _rounded(rng, s, rng.chance(0.5)):
		return false
	var r: Array = [0, 1, 2].map(func(i): return rounded(share(s, i)))
	if r[0] + r[1] + r[2] == s.n:
		return false
	for i in 3:
		if from_half(share(s, i)) < 0.1:
			return false
	return s.n - r[0] - r[1] > 0


static func _percent(rng: Seeded, s: Dictionary) -> bool:
	var a := rng.int_in(2, 15) * 5
	var b := rng.int_in(2, 15) * 5
	var pct := [a, b, 100 - a - b]
	if pct[2] < 10 or not _distinct(pct):
		return false
	s.pct = pct
	s.n = rng.int_in(1, 4) * 20 if s.paper == 1 else rng.int_in(3, 8) * 20
	if s.n == 100:
		return false
	s.N = 0
	s.G = []
	var ans: int = pct[s.g] * s.n / 100
	return _not_third(s, ans) and ans > 0


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
