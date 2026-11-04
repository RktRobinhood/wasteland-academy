class_name LinkTransformationsSituation
extends RefCounted
## The `fn-link-transformations` situation (curriculum/question-types.json): a vector (a, b)
## and a factor m picked first, then one setting for them (FAL-424). Each setting is its own
## need.kind, as a parent graph, a data set, a normal curve and an area share nothing but
## the move.
##
## generate() returns, by need.kind, with kind and paper:
##   "graph"   fam (sq, recip, exp, sin), a, b, as Q
##   "family"  pn (2 or 3), pc, pr (F(x) = pc·x^pn + pr·x), c1, c2 (two members), px, py (a
##             point on F + c), c, as whole numbers
##   "data"    xs (5 to 8 whole numbers, ascending, as Q), mean, median, sd, iqr, k. The
##             mean and the standard deviation are whole numbers, by way of DEVIATIONS
##   "stats"   mean, sd, then m, k (× m, then + k) and, for change-from-statistics, form
##             ("add" or "times"), with k or m the change. Halves stay whole
##   "normal"  mu, sigma, x, rel ("<" or ">"), p: bounds whose z ends in 2 d.p.
##   "area"    pw (n in F(x) = xⁿ, or 0 for f(x) = x³), p, q, area, a, b, m
## Standardising bounds is Paper 2 (its needs set paper, for the GDC's probability); the rest
## is Paper 1. tools/check_answers.py (check_link_transformations) reads every setting back
## from what the student sees.

const PARENTS := ["sq", "recip", "exp", "sin"]
const STRETCH := [[2, 1], [3, 1], [1, 2]]
const SIGMA := [2, 4, 5, 10, 20, 25]
## Sorted deviations with sum 0 and a whole standard deviation of at least 2, whose median
## isn't 0 and whose IQR isn't the standard deviation, so the four statistics read apart.
const DEVIATIONS := [[-8, -5, 1, 3, 9], [-7, -1, 1, 2, 5], [-9, -5, 3, 4, 7], [-5, -2, -1, 1, 7], [-6, -3, 1, 3, 5],
	[-9, -3, -1, 5, 8], [-5, -3, -1, 3, 6], [-7, -4, -3, 5, 9], [-3, -3, -3, -1, 2, 8], [-7, -3, 0, 2, 3, 5],
	[-8, -5, -3, 1, 6, 9], [-9, -5, -2, 3, 4, 9], [-6, -3, -1, 0, 5, 5], [-7, -2, -2, -2, 5, 8], [-6, -5, 1, 3, 3, 4],
	[-4, -4, 1, 1, 2, 4], [-6, -3, -2, -1, 1, 5, 6], [-7, -7, -4, -2, 6, 7, 7], [-8, -7, -3, -1, 4, 7, 8],
	[-5, -5, -3, 2, 2, 3, 6], [-5, -3, -2, -1, -1, 6, 6], [-8, -8, -1, -1, 4, 5, 9], [-7, -2, -2, -1, 2, 5, 5],
	[-2, -2, -1, -1, 1, 1, 4], [-9, -6, -5, 3, 4, 6, 7], [-4, -1, -1, 1, 1, 2, 2], [-8, -4, -2, -1, -1, 1, 7, 8],
	[-9, -8, -8, 0, 2, 7, 7, 9], [-5, -3, -1, -1, 0, 2, 4, 4], [-6, -5, -3, 0, 2, 3, 3, 6],
	[-7, -6, -5, -4, 0, 7, 7, 8], [-4, -3, -3, -1, 2, 2, 2, 5], [-8, -8, 0, 0, 2, 4, 4, 6]]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var kind: String = need.get("kind", "graph")
	var s: Dictionary
	match kind:
		"family":
			s = _family(rng)
		"data":
			s = _data(rng)
		"stats":
			s = _stats(rng, need.get("rep", "words"))
		"normal":
			s = _normal(rng, need.get("rep", "words") == "graph")
		"area":
			s = _area(rng)
		_:
			s = {"fam": rng.pick(PARENTS), "a": Q.new(ExtensionViews.nonzero(rng, -4, 4)), "b": Q.new(ExtensionViews.nonzero(rng, -5, 5))}
	if s.is_empty():
		return {}
	s.kind = kind
	s.paper = int(need.get("paper", 1))
	return s


static func _family(rng: Seeded) -> Dictionary:
	for i in 500:
		var pn := rng.int_in(2, 3)
		var pc := rng.int_in(1, 3)
		var pr := rng.int_in(-4, 4)
		var c1 := ExtensionViews.nonzero(rng, -6, 8)
		var c2 := ExtensionViews.nonzero(rng, -6, 8)
		var px := ExtensionViews.nonzero(rng, -2, 3)
		var c := ExtensionViews.nonzero(rng, -7, 9)
		var s := {"pn": pn, "pc": pc, "pr": pr, "c1": c1, "c2": c2, "px": px, "c": c}
		var fx := F(s, px)
		if c1 == c2 or c1 + c2 == 0 or fx == 0 or absi(fx + c) > 40:
			continue
		s.py = fx + c
		return s
	return {}


## F(x) at a whole number.
static func F(s: Dictionary, x: int) -> int:
	return s.pc * int(pow(x, s.pn)) + s.pr * x


## F′(x) at a whole number.
static func dF(s: Dictionary, x: int) -> int:
	return s.pn * s.pc * int(pow(x, s.pn - 1)) + s.pr


static func _data(rng: Seeded) -> Dictionary:
	var dev: Array = rng.pick(DEVIATIONS)
	var flip := rng.chance(0.5)
	var mean := rng.int_in(12, 30)
	var ints: Array = dev.map(func(d): return mean + (-d if flip else d))
	ints.sort()
	var xs: Array = ints.map(func(v): return Q.new(v))
	var q := DataSummarySituation.quartiles(xs)
	return {"xs": xs, "mean": Q.new(mean), "median": DataSummarySituation.median_of(xs), "sd": Q.new(roundi(DataSummarySituation.sd_of(xs))),
		"iqr": q[1].sub(q[0]), "k": Q.new(rng.int_in(2, 9))}


## The mean and standard deviation are halved only when they are even.
static func _stats(rng: Seeded, _rep: String) -> Dictionary:
	var pick: Array = rng.pick(STRETCH)
	var m := Q.new(pick[0], pick[1])
	var mean := rng.int_in(6, 24) * 2
	var sd := rng.int_in(1, 5) * 2
	return {"mean": Q.new(mean), "sd": Q.new(sd), "m": m, "k": Q.new(rng.int_in(2, 9)), "form": "add" if rng.chance(0.5) else "times"}


## A curve on a graph keeps mu and sigma small enough to share axes with N(0, 1).
static func _normal(rng: Seeded, drawn: bool) -> Dictionary:
	for i in 500:
		var sigma: int = rng.pick([2, 3]) if drawn else rng.pick(SIGMA)
		var mu: int = rng.int_in(3, 8) if drawn else 5 * rng.int_in(8, 24)
		var d := ExtensionViews.nonzero(rng, -2 * sigma, 2 * sigma)
		var rel: String = "<" if rng.chance(0.5) else ">"
		var z := float(d) / sigma
		var p: float = NormalUnknownSituation.phi(z) if rel == "<" else 1.0 - NormalUnknownSituation.phi(z)
		if absi(d) == sigma or not Answer.rounds_clearly(p):
			continue
		return {"mu": mu, "sigma": sigma, "x": mu + d, "rel": rel, "p": p}
	return {}


static func _area(rng: Seeded) -> Dictionary:
	var pw: int = rng.pick([2, 3, 4, 0])
	var p: int = 0 if rng.chance(0.5) else rng.int_in(1, 2)
	var q: int = p + rng.int_in(1, 2)
	if pw == 0:
		p = 2 * rng.int_in(0, 1)
		q = p + 2
	var fp := int(pow(p, pw)) if pw != 0 else int(pow(p, 4) / 4.0)
	var fq := int(pow(q, pw)) if pw != 0 else int(pow(q, 4) / 4.0)
	var area := fq - fp
	var pick: Array = rng.pick(STRETCH if area % 2 == 0 else [[2, 1], [3, 1]])
	var a := ExtensionViews.nonzero(rng, -4, 5)
	return {"pw": pw, "p": p, "q": q, "area": area, "a": Q.new(a), "b": Q.new(ExtensionViews.nonzero(rng, -3, 5)), "m": Q.new(pick[0], pick[1])}


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
