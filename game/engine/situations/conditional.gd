class_name ConditionalSituation
extends RefCounted
## The `conditional` situation (curriculum/question-types.json): a probability given something
## (FAL-725). The events are VennSituation's regions, so those probabilities are exact Q; a tree
## and two draws are exact too; a normal or a binomial conditional is a ratio of floats, as a GDC
## gives them. The answer is exact on Paper 1 and to 3 s.f. on Paper 2.
##
## need.ask is the unknown (see ConditionalViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx
##   style, a, i, b, o, u   the regions, as VennSituation (the event questions)
##   rows                   unknown-from-conditional: t the row total hidden share: see _unknown_n
##   pa, pba, pbn           the tree: P(A), P(B | A), P(B | A′), Q
##   r, g                   two draws: the first colour and the second
##   pc, pb, pa             the multiplication rule: P(A | B), P(B), P(A), Q
##   mu, sg, lo, hi, form   a normal conditional: "gt" P(X > hi | X > lo), "lt" P(X < lo | X < hi),
##                          "mid" P(X < hi | X > lo)
##   n, p, k, j, form       a binomial conditional: "le" P(X <= k | X >= 1), "eq" P(X = k | X >= j),
##                          "ge" P(X >= k | X >= j)
##   xs, ps, a1, b1         a distribution table: P(X >= a1 | X < b1)
##   num, den, mid          the two probabilities and the region between, for the floats
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 6000
const EDGE := 0.03
const P_GIVEN_MIN := 0.1
const SMALL_DEN := [2, 3, 4, 5]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "conditional-from-probabilities")
	var rep: String = need.get("rep", "equation")
	var paper: int = int(need.get("paper", 2))
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "ctx": rng.int_in(0, 7)}
		var ok := false
		match ask:
			"conditional-from-probabilities", "conditional-from-venn", "conditional-from-table", "conditional-complement":
				s.style = VennSituation.style(rng, rep, paper)
				ok = VennSituation.regions(rng, s, false) and _regions_clear(s)
			"unknown-from-conditional":
				ok = _unknown_n(rng, s)
			"reverse-from-tree":
				ok = _tree(rng, s)
			"reverse-two-draws":
				ok = _draws(rng, s)
			"intersection-from-conditional", "union-from-conditional", "marginal-from-union":
				ok = _rule(rng, s)
			"conditional-normal":
				ok = _normal(rng, s)
			"conditional-binomial":
				ok = _binomial(rng, s)
			"conditional-discrete":
				ok = _discrete(rng, s)
		if ok:
			return s
	return {}


## A value shown to 3 s.f. is clear of a rounding edge.
static func fits(s: Dictionary, v: Variant) -> bool:
	var x: float = v.to_float() if v is Q else v
	return s.paper == 1 or x == 0.0 or Answer.rounds_clearly(x, EDGE)


## The ratio is a real one: the given event isn't small, and A and B do differ in size.
static func _regions_clear(s: Dictionary) -> bool:
	var given: int = s.b + s.o if s.ask == "conditional-complement" else s.i + s.b
	var top: int = s.o if s.ask == "conditional-complement" else s.i
	var v := Q.new(top, given)
	var other := Q.new(top, s.a + s.o) if s.ask == "conditional-complement" else Q.new(top, s.a + s.i)
	return float(given) / s.u >= P_GIVEN_MIN and fits(s, v) and fits(s, other) and fits(s, Q.new(top, s.u)) and not v.eq(other)


## A table with one hidden entry n, from a stated P(A′ | B′) = t/w: n = t k and the row total w k.
static func _unknown_n(rng: Seeded, s: Dictionary) -> bool:
	var w: int = rng.pick(SMALL_DEN) + 1
	var t := rng.int_in(1, w - 1)
	if Q.new(t, w).d != w:
		return false
	var k := rng.int_in(2, 6) if s.paper == 1 else rng.int_in(6, 20)
	s.nn = t * k
	s.a = (w - t) * k
	s.i = rng.int_in(3, 20) if s.paper == 1 else rng.int_in(20, 80)
	s.b = rng.int_in(3, 20) if s.paper == 1 else rng.int_in(20, 80)
	s.t = t
	s.w = w
	return s.i != s.b


static func _tree(rng: Seeded, s: Dictionary) -> bool:
	var d := 10 if s.paper == 1 else 100
	var lo := 1 if s.paper == 1 else 5
	var hi := 9 if s.paper == 1 else 95
	s.pa = Q.new(rng.int_in(lo, hi), d)
	s.pba = Q.new(rng.int_in(lo, hi), d)
	s.pbn = Q.new(rng.int_in(lo, hi), d)
	var both: Q = s.pa.mul(s.pba)
	var pb: Q = both.add(Q.new(1).sub(s.pa).mul(s.pbn))
	s.v = both.div(pb)
	return pb.to_float() >= P_GIVEN_MIN and fits(s, s.v) and fits(s, both) and not s.pba.eq(s.pbn) and not s.v.eq(s.pba) and not s.v.eq(both)


static func _draws(rng: Seeded, s: Dictionary) -> bool:
	s.style = "frac"
	s.r = rng.int_in(3, 9) if s.paper == 1 else rng.int_in(5, 15)
	s.g = rng.int_in(3, 9) if s.paper == 1 else rng.int_in(5, 15)
	var top: int = s.r * (s.r - 1)
	var rest: int = s.g * (s.g - 1)
	var t: int = s.r + s.g
	s.v = Q.new(top, top + rest)
	return s.r != s.g and fits(s, s.v) and fits(s, Q.new(top, t * (t - 1))) and fits(s, Q.new(s.r * s.r, s.r * s.r + s.g * s.g))


## P(B) and P(A | B) in steps that give an exact overlap, and an A that fits round it.
static func _rule(rng: Seeded, s: Dictionary) -> bool:
	var d := 10 if s.paper == 1 else 100
	s.pb = Q.new(rng.int_in(2, 8) if s.paper == 1 else rng.int_in(15, 85), d)
	s.pc = Q.new(rng.int_in(1, 9) if s.paper == 1 else rng.int_in(10, 90), d)
	s.pi = s.pc.mul(s.pb)
	s.pa = Q.new(rng.int_in(2, 8) if s.paper == 1 else rng.int_in(15, 85), d)
	s.pu = s.pa.add(s.pb).sub(s.pi)
	return s.pi.lt(s.pa) and s.pu.lt(Q.new(1)) and not s.pa.eq(s.pb) and fits(s, s.pi) and fits(s, s.pu) and fits(s, s.pb) \
			and fits(s, s.pa.add(s.pb).sub(s.pc)) and fits(s, s.pc.div(s.pb)) and s.pa.add(s.pb).sub(s.pc).lt(Q.new(1))


static func nphi(s: Dictionary, x: float) -> float:
	return SymmetrySituation.phi((x - s.mu) / s.sg)


static func _normal(rng: Seeded, s: Dictionary) -> bool:
	s.mu = rng.int_in(30, 300)
	s.sg = rng.int_in(3, 30)
	s.form = rng.pick(["gt", "lt", "mid"])
	s.lo = s.mu + rng.int_in(-20, 12) * s.sg / 10
	s.hi = s.lo + rng.int_in(4, 18) * s.sg / 10
	if s.hi <= s.lo or s.mu < 4 * s.sg:
		return false
	var below_lo := nphi(s, s.lo)
	var below_hi := nphi(s, s.hi)
	s.mid = below_hi - below_lo
	match s.form:
		"gt":
			s.num = 1.0 - below_hi
			s.den = 1.0 - below_lo
		"lt":
			s.num = below_lo
			s.den = below_hi
		_:
			s.num = s.mid
			s.den = 1.0 - below_lo
	s.v = s.num / s.den
	return s.den >= P_GIVEN_MIN and s.den <= 0.9 and s.num >= 0.02 and s.v <= 0.95 and fits(s, s.v) and fits(s, s.num) and fits(s, s.num * s.den) and fits(s, s.mid)


static func bprob(s: Dictionary, lo: int, hi: int) -> float:
	var p: float = s.p.to_float()
	return BinomialSituation.cdf(s.n, p, hi) - BinomialSituation.cdf(s.n, p, lo - 1)


static func _binomial(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.int_in(5, 15)
	s.p = Q.new(rng.int_in(2, 18) * 5, 100)
	s.form = rng.pick(["le", "eq", "ge"])
	match s.form:
		"le":
			s.j = 1
			s.k = rng.int_in(2, 4)
			s.num = bprob(s, 1, s.k)
		"eq":
			s.j = rng.int_in(1, 2)
			s.k = s.j + rng.int_in(1, 3)
			s.num = bprob(s, s.k, s.k)
		"ge":
			s.j = rng.int_in(1, 3)
			s.k = s.j + rng.int_in(1, 3)
			s.num = bprob(s, s.k, s.n)
	s.den = bprob(s, s.j, s.n)
	s.v = s.num / s.den if s.den > 0.0 else 0.0
	return s.k < s.n and s.den >= P_GIVEN_MIN and s.den <= 0.97 and s.num >= 0.02 and s.v <= 0.95 and fits(s, s.v) and fits(s, s.num) and fits(s, s.num * s.den)


static func _discrete(rng: Seeded, s: Dictionary) -> bool:
	var n := rng.int_in(4, 6)
	var d := 10 if s.paper == 1 else 100
	var left := d
	s.xs = range(1, n + 1)
	s.ps = []
	for i in n - 1:
		var hi := left - (n - 1 - i)
		var v := rng.int_in(1, maxi(1, mini(hi, d * 2 / n)))
		s.ps.append(Q.new(v, d))
		left -= v
	if left < 1:
		return false
	s.ps.append(Q.new(left, d))
	s.a1 = rng.int_in(2, n - 1)
	s.b1 = rng.int_in(s.a1 + 1, n)
	var num := Q.new(0)
	var den := Q.new(0)
	for i in n:
		if s.xs[i] < s.b1:
			den = den.add(s.ps[i])
			if s.xs[i] >= s.a1:
				num = num.add(s.ps[i])
	s.num = num
	s.den = den
	s.v = num.div(den)
	return den.to_float() >= P_GIVEN_MIN and fits(s, s.v) and fits(s, num) and not s.v.eq(num)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
