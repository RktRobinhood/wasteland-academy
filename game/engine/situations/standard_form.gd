class_name StandardFormSituation
extends RefCounted
## The `standard-form` situation (curriculum/question-types.json): numbers a × 10^k and what is
## done with them (FAL-726). Every a is an exact Q and every k an int, so a number never has to
## fit a float. Paper 1 values come from NICE, so a product or quotient has at most three
## figures and can be done by hand. Paper 2 has three-figure values, and an answer that needs
## it is to 3 s.f.
##
## need.ask is the unknown (see StandardFormViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx (an index into the views' stories)
##   a, m     the first number, a × 10^m
##   b, n     the second number, b × 10^n
##   r, k     the answer, r × 10^k, with 1 ≤ r < 10. r is exact: the views round it
##   j        renormalise: the number is shown as (r × 10^j) × 10^(k − j)
##   f        scale-value: the whole number the first number is multiplied by
##   shift    unit-shift: the change of unit's power of ten
##   list     order-mixed: four [a, k, how] numbers, how being "form", "plain", "over" or "under"
##   big      order-mixed: true for the largest, false for the smallest
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 6000
const EDGE := 0.03
const CONTEXTS := 6
## Tenths: a Paper 1 value's a.
const NICE := [12, 15, 16, 20, 24, 25, 30, 32, 40, 45, 50, 60, 75, 80, 90]
const SQUARES := [12, 15, 20, 25, 30, 40, 50, 60]
## Diameters, in tenths, whose (4/3)π(d/2)³ ends.
const DIAMETERS := [12, 18, 24, 30, 48, 60, 90]
const SHIFTS := [-3, 3, -3, 3, 3, -3]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "to-form-large")
	var rep: String = need.get("rep", "equation")
	var paper: int = int(need.get("paper", 1))
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "ctx": rng.int_in(0, CONTEXTS - 1), "m": 0, "n": 0}
		if _draw(rng, s):
			return s
	return {}


## a × 10^e with 1 ≤ a < 10: [a, k].
static func norm(v: Q, e: int) -> Array:
	var a := v
	var k := e
	while not a.lt(Q.new(10)):
		a = a.div(10)
		k += 1
	while a.lt(Q.new(1)):
		a = a.mul(10)
		k -= 1
	return [a, k]


static func nice(rng: Seeded) -> Q:
	return Q.new(rng.pick(NICE), 10)


## A value with three figures, on 1 to 10.
static func three(rng: Seeded) -> Q:
	return Q.new(rng.int_in(101, 999), 100)


static func value(rng: Seeded, s: Dictionary) -> Q:
	return nice(rng) if s.paper == 1 else three(rng)


## r has at most three figures, written exactly.
static func short(r: Q) -> bool:
	return r.mul(100).is_int()


## A Paper 2 answer needs rounding, clear of an edge, and doesn't round up to 10.
static func clear(r: Q) -> bool:
	var x := r.to_float()
	return Answer.rounds_clearly(x, EDGE) and Answer.needs_rounding(r) and x < 9.9


## Sets the answer from v × 10^e, on this paper's limits.
static func answer(s: Dictionary, v: Q, e: int) -> bool:
	var pair := norm(v, e)
	s.r = pair[0]
	s.k = pair[1]
	if absi(s.k) < 2:
		return false
	return short(s.r) if s.paper == 1 else clear(s.r)


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"to-form-large", "to-form-small":
			return _to_form(rng, s)
		"to-ordinary-large", "to-ordinary-small":
			s.r = Q.new(rng.int_in(101, 999), 100)
			s.k = rng.int_in(3, 6) if s.ask == "to-ordinary-large" else rng.int_in(-6, -2)
			return true
		"renormalise":
			s.r = Q.new(rng.int_in(11, 99), 10)
			s.j = rng.pick([1, 2, -1, -2])
			s.k = rng.int_in(3, 9) if rng.chance(0.6) else rng.int_in(-8, -3)
			return true
		"order-mixed":
			return _order(rng, s)
		"display-to-form":
			s.r = three(rng)
			s.k = rng.pick([rng.int_in(4, 12), rng.int_in(-9, -3)])
			return true
		"multiply", "multiply-renormalise":
			return _pair(rng, s, true)
		"divide", "divide-renormalise":
			return _pair(rng, s, false)
		"power-product":
			return _power(rng, s)
		"times-larger":
			s.a = value(rng, s)
			s.b = value(rng, s)
			s.m = rng.int_in(7, 12)
			s.n = rng.int_in(2, 5)
			return answer(s, s.a.div(s.b), s.m - s.n)
		"time-from-rate", "rate-unit-shift":
			return _rate(rng, s)
		"total-from-unit":
			s.a = value(rng, s)
			s.b = value(rng, s)
			s.m = rng.int_in(5, 9)
			s.n = rng.int_in(-7, -3)
			return answer(s, s.a.mul(s.b), s.m + s.n)
		"unit-shift":
			s.a = Q.new(rng.int_in(101, 999), 100)
			s.m = rng.pick([rng.int_in(4, 9), rng.int_in(-8, -4)])
			s.shift = SHIFTS[s.ctx]
			s.r = s.a
			s.k = s.m + s.shift
			return absi(s.k) >= 2
		"scale-value":
			return _scale(rng, s)
		"sphere-volume-pi":
			return _sphere(rng, s)
	return false


## Paper 1 a number with two or three figures, Paper 2 one with five, rounded in the answer.
static func _to_form(rng: Seeded, s: Dictionary) -> bool:
	s.r = Q.new(rng.int_in(101, 999), 100) if s.paper == 1 else Q.new(rng.int_in(10111, 99499), 10000)
	s.k = rng.int_in(4, 9) if s.ask == "to-form-large" else rng.int_in(-7, -3)
	return s.paper == 1 or clear(s.r)


## Four numbers near each other, each written its own way.
static func _order(rng: Seeded, s: Dictionary) -> bool:
	var k: int = rng.pick([rng.int_in(3, 5), rng.int_in(-4, -3)])
	var tenths := {}
	while tenths.size() < 4:
		tenths[rng.int_in(11, 99)] = true
	var ten: Array = tenths.keys()
	s.big = rng.chance(0.5)
	s.list = [[Q.new(ten[0], 10), k, "form"], [Q.new(ten[1], 10), k, "plain"], [Q.new(ten[2], 10), k, "over"], [Q.new(ten[3], 10), k, "under"]]
	var best: Array = s.list[0]
	for row in s.list:
		if row[0].lt(best[0]) != s.big and not row[0].eq(best[0]):
			best = row
	s.r = best[0]
	s.k = k
	return true


## Two numbers multiplied or divided. The unknown says whether the result needs moving: it does
## on -renormalise, where a product reaches 10 or a quotient falls below 1.
static func _pair(rng: Seeded, s: Dictionary, times: bool) -> bool:
	s.a = value(rng, s)
	s.b = value(rng, s)
	s.m = rng.int_in(-4, 6)
	s.n = rng.int_in(-4, 6)
	if s.m == 0 or s.n == 0 or s.m == s.n:
		return false
	var carries: bool = s.ask.ends_with("-renormalise")
	var v: Q = s.a.mul(s.b) if times else s.a.div(s.b)
	var moved: bool = not v.lt(Q.new(10)) if times else v.lt(Q.new(1))
	if moved != carries or s.m * s.n == s.m + s.n:
		return false
	return answer(s, v, s.m + s.n if times else s.m - s.n)


## (a × 10^m)² × (b × 10^n).
static func _power(rng: Seeded, s: Dictionary) -> bool:
	s.a = Q.new(rng.pick(SQUARES), 10) if s.paper == 1 else three(rng)
	s.b = value(rng, s)
	s.m = rng.int_in(-4, 5)
	s.n = rng.int_in(-5, 5)
	if s.m == 0 or s.n == 0:
		return false
	return answer(s, s.a.mul(s.a).mul(s.b), 2 * s.m + s.n)


## A speed a × 10^m m/s over a distance b × 10^n, in metres or kilometres: the time.
static func _rate(rng: Seeded, s: Dictionary) -> bool:
	s.a = value(rng, s)
	s.b = value(rng, s)
	s.m = rng.int_in(6, 8)
	s.n = rng.int_in(9, 13) if s.ask == "time-from-rate" else rng.int_in(6, 10)
	return answer(s, s.b.div(s.a), s.n - s.m + (3 if s.ask == "rate-unit-shift" else 0))


## A number times a small whole number. On Paper 1 it may be a plain power of ten.
static func _scale(rng: Seeded, s: Dictionary) -> bool:
	s.a = Q.new(1) if s.paper == 1 and rng.chance(0.4) else value(rng, s)
	s.m = rng.pick([rng.int_in(3, 8), rng.int_in(-8, -3)])
	s.f = rng.int_in(2, 9)
	return answer(s, s.a.mul(s.f), s.m)


static func _sphere(rng: Seeded, s: Dictionary) -> bool:
	s.a = Q.new(rng.pick(DIAMETERS), 10) if s.paper == 1 else three(rng)
	s.m = rng.int_in(2, 6)
	var cube: Q = s.a.mul(s.a).mul(s.a).div(6)
	var pair := norm(cube, 3 * s.m)
	s.r = pair[0]
	s.k = pair[1]
	return s.paper == 1 or clear(s.r)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
