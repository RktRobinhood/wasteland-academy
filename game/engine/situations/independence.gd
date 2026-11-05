class_name IndependenceSituation
extends RefCounted
## The `independence` situation (curriculum/question-types.json): two events, either known to be
## independent or to be tested (FAL-739). Everything is exact: a Q, or a count out of u. A test
## draws P(A) and P(B) first, so that P(A) × P(B) is exact, and only then decides the overlap.
## Not independent moves the overlap off that product by a little and keeps P(A) and P(B), so
## neither the numbers nor the wording tell the two cases apart: `indep` is a fair coin, drawn
## before anything else. classify-events does the same with three cases.
##
## need.ask is the unknown (see IndependenceViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx
##   style          dec, frac, count (as VennSituation) or pct (a story in percentages, u = 100)
##   indep          a test: whether A and B are independent
##   kind           classify-events: "excl", "indep" or "neither"
##   form           how a test or classification is given: inter, union, pct, share, regions
##   a, i, b, o, u  the regions, as VennSituation (the event tests)
##   pa, pb, pi, pu P(A), P(B), P(A ∩ B) and P(A ∪ B), Q
##   pba, pbn       P(B | A) and P(B | A′), Q
##   g1, n1, g2, n2 test-from-tree: the good ones and the size of each source
##   k              ratio-from-union: P(A) = k P(B)
##   only_a, only_b overlap-from-only-regions: P(A ∩ B′) and P(A′ ∩ B); pi is the double root
##   region         one-region-from-independence: "A′ ∩ B", "A ∩ B′" or "A′ ∩ B′"
##   want, cond     conditional-from-independence: P(want | cond)
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 8000
const EDGE := 0.03
## Two values compared on Paper 2 stay this far apart, so 3 s.f. can't hide the difference.
const GAP := 0.002
const KINDS := ["excl", "indep", "neither"]
const REGIONS := ["A′ ∩ B", "A ∩ B′", "A′ ∩ B′"]
const PICKS := [[3, 10], [1, 2], [1, 3], [2, 3], [1, 4], [3, 4], [1, 5], [2, 5], [3, 5], [4, 5], [1, 6], [5, 6]]
const TENTHS := [[1, 10], [1, 5], [3, 10], [2, 5], [1, 2], [3, 5], [7, 10], [4, 5], [9, 10], [1, 4], [3, 4]]
const SHARE_A := [20, 25, 40, 50, 60, 75, 80]
const TREE_P1 := [[1, 2], [1, 2], [1, 3], [1, 4]]
const TREE_P2 := [[1, 2], [2, 5], [3, 10], [3, 5], [7, 10]]
const P1_DEN := 200


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "both-from-probabilities")
	var rep: String = need.get("rep", "equation")
	var paper: int = int(need.get("paper", 2))
	# Drawn once, so a filter below can't favour one case.
	var indep := rng.chance(0.5)
	var kind: String = rng.pick(KINDS)
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "ctx": rng.int_in(0, 7), "indep": indep, "kind": kind, "form": ""}
		var ok := false
		match ask:
			"both-from-probabilities", "union-from-independence":
				ok = _pair(rng, s)
			"one-region-from-independence":
				s.region = rng.pick(REGIONS)
				ok = _pair(rng, s)
			"conditional-from-independence":
				ok = _given_rule(rng, s)
			"unknown-from-union":
				ok = _pair(rng, s) and fits(s, s.pu.sub(s.pa)) and fits(s, s.pu)
			"ratio-from-union":
				ok = _ratio(rng, s)
			"overlap-from-only-regions":
				ok = _only_regions(rng, s)
			"test-from-probabilities":
				if rep == "words":
					s.form = rng.pick(["pct", "share"])
				else:
					s.form = rng.pick(["inter", "union"])
				ok = _regions(rng, s) and _test_clear(s)
			"test-from-venn", "test-from-table":
				ok = _regions(rng, s) and _test_clear(s)
			"test-from-tree":
				ok = _sources(rng, s) and _test_clear(s)
			"test-from-conditional":
				ok = _given_conditional(rng, s) and _test_clear(s)
			"classify-events":
				s.form = {"words": "pct", "diagram": "regions"}.get(rep, "union")
				ok = _classify(rng, s)
		if ok:
			return s
	return {}


## A value shown to 3 s.f. is clear of a rounding edge.
static func fits(s: Dictionary, v: Q) -> bool:
	return s.paper == 1 or v.is_zero() or Answer.rounds_clearly(v.to_float(), EDGE)


## How a question writes a probability it works out: 3 s.f. on Paper 2, else as its givens.
static func H(s: Dictionary, v: Q) -> String:
	if s.paper == 2:
		return Fmt.sf(v)
	return Fmt.dec(v) if s.style in ["dec", "pct"] else Fmt.num(v)


static func _set_events(s: Dictionary) -> void:
	s.pa = Q.new(s.a + s.i, s.u)
	s.pb = Q.new(s.b + s.i, s.u)
	s.pi = Q.new(s.i, s.u)
	s.pu = Q.new(s.a + s.i + s.b, s.u)
	s.pba = Q.new(s.i, s.a + s.i)
	s.pbn = Q.new(s.b, s.b + s.o)


## P(A) and P(B), for an event that is known to be independent.
static func _pair(rng: Seeded, s: Dictionary) -> bool:
	if s.paper == 2:
		s.style = "dec"
		s.pa = Q.new(rng.int_in(5, 95), 100)
		s.pb = Q.new(rng.int_in(5, 95), 100)
	else:
		s.style = "dec" if rng.chance(0.6) else "frac"
		var pool: Array = TENTHS if s.style == "dec" else PICKS
		var x: Array = rng.pick(pool)
		var y: Array = rng.pick(pool)
		s.pa = Q.new(x[0], x[1])
		s.pb = Q.new(y[0], y[1])
	s.pi = s.pa.mul(s.pb)
	s.pu = s.pa.add(s.pb).sub(s.pi)
	var one := Q.new(1)
	return not s.pa.eq(s.pb) and fits(s, s.pi) and fits(s, s.pu) and fits(s, one.sub(s.pa).mul(s.pb)) and fits(s, s.pa.mul(one.sub(s.pb))) \
			and fits(s, one.sub(s.pa).mul(one.sub(s.pb))) and s.pu.lt(one)


## P(B) and P(A ∩ B) of an independent pair, and the conditional asked.
static func _given_rule(rng: Seeded, s: Dictionary) -> bool:
	if not _pair(rng, s):
		return false
	s.want = rng.pick(["A′", "A"])
	s.cond = rng.pick(["B′", "B"])
	var v: Q = Q.new(1).sub(s.pa) if s.want == "A′" else s.pa
	return not s.pa.eq(Q.new(1, 2)) and not s.pb.eq(Q.new(1, 2)) and fits(s, v) and fits(s, s.pa)


## P(A) = k P(B) and P(A ∪ B), with P(B) a whole number of hundredths. The other root of the
## quadratic is always above 1, so one value is left.
static func _ratio(rng: Seeded, s: Dictionary) -> bool:
	s.style = "dec"
	s.k = rng.int_in(2, 5)
	s.pb = Q.new(rng.int_in(5, 45), 100)
	s.pa = s.pb.mul(Q.new(s.k))
	s.pi = s.pa.mul(s.pb)
	s.pu = s.pa.add(s.pb).sub(s.pi)
	return s.pa.lt(Q.new(9, 10)) and Q.new(1, 5).lt(s.pu) and not s.pb.eq(Q.new(1, 5)) and fits(s, s.pb) and fits(s, s.pa) \
			and fits(s, s.pu.div(Q.new(s.k + 1))) and fits(s, s.pu.div(Q.new(s.k)))


## P(A ∩ B′) = t² and P(A′ ∩ B) = (1 − t)²: the one pair that gives a double root, x = t(1 − t).
static func _only_regions(rng: Seeded, s: Dictionary) -> bool:
	s.style = "dec"
	var h := rng.int_in(15, 85)
	if h in [40, 50, 60]:
		return false
	var t := Q.new(h, 100)
	var r := Q.new(100 - h, 100)
	s.pa = t
	s.pb = r
	s.only_a = t.mul(t)
	s.only_b = r.mul(r)
	s.pi = t.mul(r)
	return fits(s, s.pi) and fits(s, s.only_a.mul(s.only_b)) and fits(s, s.only_a.add(s.only_b)) and fits(s, Q.new(1).sub(s.only_a).sub(s.only_b))


## The regions of a test or a classification. P(A) and P(B) always have an exact product in
## counts; the overlap is that count, or that count moved by d. Both must fit, in both cases.
static func _draw_margins(rng: Seeded, s: Dictionary) -> bool:
	if s.get("form", "") in ["pct", "share"]:
		s.style = "pct"
		s.u = 100
	else:
		s.style = VennSituation.style(rng, s.rep, s.paper)
		s.u = VennSituation.total(rng, s)
	var u: int = s.u
	var step := 10 if u == 1000 else 1
	s.na = rng.int_in(u / 5 / step, u * 4 / 5 / step) * step
	s.nb = rng.int_in(u / 5 / step, u * 4 / 5 / step) * step
	if s.form == "share":
		s.na = rng.pick(SHARE_A)
	if s.na == s.nb or (s.na * s.nb) % u != 0:
		return false
	s.base = s.na * s.nb / u
	s.d = rng.int_in(1, 10) * 5 if u == 1000 else rng.int_in(1, maxi(1, u / 20))
	if rng.chance(0.5):
		s.d = -s.d
	return true


static func _fill(s: Dictionary, i: int) -> void:
	s.i = i
	s.a = s.na - i
	s.b = s.nb - i
	s.o = s.u - s.na - s.nb + i
	_set_events(s)


static func _regions(rng: Seeded, s: Dictionary) -> bool:
	if not _draw_margins(rng, s):
		return false
	var moved: int = s.base + s.d
	for i in [s.base, moved]:
		if i < 1 or s.na - i < 1 or s.nb - i < 1 or s.u - s.na - s.nb + i < 1:
			return false
	if s.form == "share" and (moved * 100) % s.na != 0:
		return false
	_fill(s, s.base if s.indep else moved)
	return true


## Three cases on one set of margins: disjoint, the product, or neither.
static func _classify(rng: Seeded, s: Dictionary) -> bool:
	if not _draw_margins(rng, s):
		return false
	var moved: int = s.base + s.d
	if s.na + s.nb >= s.u or moved < 1 or moved >= mini(s.na, s.nb) or s.base >= mini(s.na, s.nb):
		return false
	match s.kind:
		"excl":
			_fill(s, 0)
		"indep":
			_fill(s, s.base)
		_:
			_fill(s, moved)
	s.indep = s.kind == "indep"
	var product: Q = s.pa.mul(s.pb)
	return fits(s, s.pi) and fits(s, product) and fits(s, s.pu) and absf(Q.new(moved, s.u).sub(product).to_float()) >= GAP \
			and H(s, Q.new(moved, s.u)) != H(s, product)


## Two sources of different sizes. B has the same share in both, or one item more or fewer.
static func _sources(rng: Seeded, s: Dictionary) -> bool:
	var w := rng.int_in(3, 6) if s.paper == 1 else rng.int_in(3, 10)
	var t := rng.int_in(1, w - 1)
	if Q.new(t, w).d != w:
		return false
	var hi := 4 if s.paper == 1 else 8
	var k1 := rng.int_in(1, hi)
	var k2 := rng.int_in(1, hi)
	if k1 == k2:
		return false
	var dg := 1 if rng.chance(0.5) else -1
	s.n1 = k1 * w
	s.n2 = k2 * w
	s.g1 = k1 * t
	s.g2 = k2 * t
	var moved: int = s.g2 + dg
	# Two of each at least, so the story never says "1 dead fuses".
	for g in [s.g1, s.g2, moved]:
		if g < 2:
			return false
	if s.n1 - s.g1 < 2 or s.n2 - s.g2 < 2 or s.n2 - moved < 2:
		return false
	if not s.indep:
		s.g2 = moved
	var p: Array = rng.pick(TREE_P1 if s.paper == 1 else TREE_P2)
	s.style = "frac" if s.paper == 1 else "dec"
	s.pa = Q.new(p[0], p[1])
	s.pba = Q.new(s.g1, s.n1)
	s.pbn = Q.new(s.g2, s.n2)
	s.pi = s.pa.mul(s.pba)
	s.pb = s.pi.add(Q.new(1).sub(s.pa).mul(s.pbn))
	s.pu = s.pa.add(s.pb).sub(s.pi)
	return true


## P(A), P(B | A) and P(A ∪ B). P(B) is P(B | A) or another value, both of which must fit.
static func _given_conditional(rng: Seeded, s: Dictionary) -> bool:
	var pool: Array = PICKS if s.paper == 1 else []
	s.style = "frac" if s.paper == 1 else "dec"
	var other: Q
	if s.paper == 1:
		var x: Array = rng.pick(pool)
		var y: Array = rng.pick(pool)
		var z: Array = rng.pick(pool)
		s.pa = Q.new(x[0], x[1])
		s.pba = Q.new(y[0], y[1])
		other = Q.new(z[0], z[1])
	else:
		s.pa = Q.new(rng.int_in(3, 17) * 5, 100)
		s.pba = Q.new(rng.int_in(3, 17) * 5, 100)
		other = s.pba.add(Q.new(rng.int_in(1, 3) * (1 if rng.chance(0.5) else -1), 20))
	s.pi = s.pa.mul(s.pba)
	for pb: Q in [s.pba, other]:
		if not (s.pi.lt(pb) and s.pi.lt(s.pa) and pb.lt(Q.new(1))):
			return false
		var pu: Q = s.pa.add(pb).sub(s.pi)
		if not (pu.lt(Q.new(1)) and pu.d <= 120):
			return false
	if other.eq(s.pba):
		return false
	s.pb = s.pba if s.indep else other
	s.pu = s.pa.add(s.pb).sub(s.pi)
	s.pbn = s.pb.sub(s.pi).div(Q.new(1).sub(s.pa))
	return true


## Every pair a test compares: equal when independent, and on Paper 2 apart at 3 s.f. if not.
static func _test_clear(s: Dictionary) -> bool:
	var pairs: Array = [[s.pi, s.pa.mul(s.pb)], [s.pi.div(s.pb), s.pa], [s.pba, s.pb], [s.pba, s.pbn]]
	for pair in pairs:
		var l: Q = pair[0]
		var r: Q = pair[1]
		if l.eq(r) != bool(s.indep):
			return false
		if s.paper == 1 and (l.d > P1_DEN or r.d > P1_DEN):
			return false
		if not fits(s, l) or not fits(s, r):
			return false
		if not s.indep and (H(s, l) == H(s, r) or absf(l.to_float() - r.to_float()) < GAP):
			return false
	return true


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
