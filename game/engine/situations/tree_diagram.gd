class_name TreeDiagramSituation
extends RefCounted
## The `tree-diagram` situation (curriculum/question-types.json): a multi-stage event on a tree,
## or draws from a tin (FAL-739). It extends `conditional`: fits() and the stories come from
## there, and the tree is PlotView's `tree`. Probabilities are exact Q, except where a normal
## variable sets a branch (floats, as a GDC gives them). The answer is exact on Paper 1 and to
## 3 s.f. on Paper 2, except a branch read straight off the tree, which is exact on both.
##
## need.ask is the unknown (see TreeDiagramViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx, style   style "frac" or "dec": how the question writes its numbers
##   n1, n2, first, second         a tree: the branches at the first fork and at each later fork
##   bag true, counts, mode, cols, thing   draws: a tin, with mode "wo" (no replacement), "w"
##                                 (put back) or "add" (put back with one more of that colour)
##   i, j                          the path asked: the first-stage branch and the second-stage one
##   stage                         the branch hidden: 1 at the first fork, 2 at a later one
##   c, a1, a2                     the multiples of k on a tree of unknowns
##   crates                        the counts [wanted, other] in each crate of a story
##   form                          which of an unknown's wordings is asked (see the builders)
##   draws, target                 the number of draws and the colour asked for
##   big, want, rest               the roster and draws in terms of n
##   p, k                          the chance on each try and the try it comes on
##   mu, sg, shares, lim           normal groups: mean, spread, shares and the limit
##   hi, lo, a, b, rounds, limit   a game: scores, their chances, and the total to beat
##   r0, n                         selections: the first count, and the selection the blue comes on
##   v                             the answer (Q, or a float for a normal)
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy. A few set-ups are left out because they are a past paper's own numbers: a crate of
## 7 with 4 or 5 of a colour, 10 of a colour in a tin of n, k = 1/3 with k/2, and 3 + 1 in a growing tin.

const TRIES := 6000
const CONTEXTS := 8
const P1_ONLY := ["branch-in-terms-of-k", "parameter-on-branch", "selections-find-n"]
const P2_ONLY := ["draws-in-terms-of-n", "total-from-normals", "rounds-exceed-total"]
const FRAC_FIRST := [4, 5, 6, 8]
const FRAC_SECOND := [3, 4, 5, 6]
## The first-branch multiples of k on a tree of unknowns, and the second.
const K_FIRST := [[1, 1], [2, 1], [1, 2]]
const K_SECOND := [[1, 2], [1, 3], [2, 1], [3, 1], [2, 3]]
const FAIR := [[1, 6], [1, 5], [1, 4], [1, 3], [2, 5], [3, 10], [1, 8]]
const MAKERS := [0, 1, 3, 4, 5, 7]
const HIGH := [6, 8, 10, 12, 20]
const NORMAL_MIN := 0.02
const NORMAL_MAX := 0.98


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "complete-branch")
	var rep: String = need.get("rep", "diagram")
	var paper: int = int(need.get("paper", 2))
	if ask in P1_ONLY:
		paper = 1
	elif ask in P2_ONLY:
		paper = 2
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "ctx": rng.int_in(0, CONTEXTS - 1), "style": "dec"}
		var ok := false
		match ask:
			"complete-branch":
				ok = _complete(rng, s)
			"branch-in-terms-of-k":
				ok = _in_k(rng, s)
			"branch-after-draw":
				ok = _after_draw(rng, s)
			"path-probability":
				ok = _path(rng, s)
			"total-over-paths":
				ok = _total(rng, s)
			"same-or-different":
				ok = _same_or_different(rng, s)
			"at-least-one":
				ok = _at_least_one(rng, s)
			"all-without-replacement":
				ok = _all_three(rng, s)
			"draws-in-terms-of-n":
				ok = _in_n(rng, s)
			"first-success-on-trial":
				ok = _first_success(rng, s)
			"total-from-normals":
				ok = _normals(rng, s)
			"parameter-on-branch":
				ok = _parameter(rng, s)
			"rounds-exceed-total":
				ok = _rounds(rng, s)
			"selections-find-n":
				ok = _find_n(rng, s)
		if ok:
			return s
	return {}


static func fits(s: Dictionary, v: Variant) -> bool:
	return ConditionalSituation.fits(s, v)


## parts whole numbers of at least low, adding to d.
static func _split(rng: Seeded, parts: int, d: int, low: int) -> Array:
	var out: Array = []
	var left := d
	for i in parts - 1:
		var v := rng.int_in(low, left - low * (parts - 1 - i))
		out.append(v)
		left -= v
	out.append(left)
	return rng.shuffled(out)


## A fork's branches as Q out of d.
static func _fork(rng: Seeded, parts: int, d: int, low: int) -> Array:
	return _split(rng, parts, d, low).map(func(x): return Q.new(x, d))


## A tree of n1 branches, then n2 at each later fork.
static func _tree(rng: Seeded, s: Dictionary, n1: int, n2: int) -> void:
	s.n1 = n1
	s.n2 = n2
	s.bag = false
	s.second = []
	if s.paper == 1 and rng.int_in(0, 1) == 0:
		s.style = "frac"
		var d1: int = rng.pick(FRAC_FIRST)
		s.first = _fork(rng, n1, d1, 1)
		for i in n1:
			s.second.append(_fork(rng, n2, rng.pick(FRAC_SECOND), 1) if n2 == 2 else _fork(rng, n2, rng.pick([4, 5, 6]), 1))
	elif s.paper == 1:
		s.first = _fork(rng, n1, 10, 1)
		for i in n1:
			s.second.append(_fork(rng, n2, 10, 1))
	else:
		s.first = _fork(rng, n1, 100, 12)
		for i in n1:
			s.second.append(_fork(rng, n2, 100, 12))


## A tin of cols colours. Paper 1 stays small, so its fractions can be done by hand.
static func _bag(rng: Seeded, s: Dictionary, cols: int, modes: Array, low: int = 2) -> bool:
	s.bag = true
	s.style = "frac"
	s.n1 = cols
	s.n2 = cols
	s.mode = rng.pick(modes)
	s.cols = rng.int_in(0, ConditionalViews.COLOURS.size() - 1)
	s.thing = rng.int_in(0, ConditionalViews.THINGS.size() - 1)
	s.counts = []
	for c in cols:
		s.counts.append(rng.int_in(low, 7) if s.paper == 1 else rng.int_in(maxi(low, 4), 15))
	for a in cols:
		for b in range(a + 1, cols):
			if s.counts[a] == s.counts[b]:
				return false
	bag_tree(s)
	return true


## The fractions a tin puts on its two-stage tree.
static func bag_tree(s: Dictionary) -> void:
	var t := total(s)
	s.first = s.counts.map(func(c): return Q.new(c, t))
	s.second = []
	for i in s.n1:
		var row: Array = []
		for j in s.n1:
			row.append(path(s, [i, j]).div(s.first[i]))
		s.second.append(row)


static func total(s: Dictionary) -> int:
	var t := 0
	for c in s.counts:
		t += c
	return t


## The probability of drawing these colours in this order.
static func path(s: Dictionary, colours: Array, mode: String = "") -> Q:
	var m: String = s.mode if mode == "" else mode
	var c: Array = s.counts.duplicate()
	var t := total(s)
	var p := Q.new(1)
	for i in colours:
		p = p.mul(Q.new(c[i], t))
		if m == "wo":
			c[i] -= 1
			t -= 1
		elif m == "add":
			c[i] += 1
			t += 1
	return p


## P(two draws have the same colour).
static func same_colour(s: Dictionary, mode: String = "") -> Q:
	var out := Q.new(0)
	for i in s.n1:
		out = out.add(path(s, [i, i], mode))
	return out


## The event over the tree's paths: every first branch into the second-stage outcome j.
static func into(s: Dictionary, j: int) -> Q:
	var out := Q.new(0)
	for i in s.n1:
		out = out.add(s.first[i].mul(s.second[i][j]))
	return out


# ── Filling in a branch ──────────────────────────────────────

static func _complete(rng: Seeded, s: Dictionary) -> bool:
	_tree(rng, s, rng.pick([2, 2, 3]), rng.pick([2, 2, 3]))
	s.stage = rng.int_in(1, 2)
	s.i = rng.int_in(0, s.n1 - 1)
	s.j = rng.int_in(0, s.n2 - 1)
	s.v = s.first[s.i] if s.stage == 1 else s.second[s.i][s.j]
	if s.stage == 2:
		return not s.v.eq(Q.new(1).sub(s.first[s.i]))
	return true


static func _in_k(rng: Seeded, s: Dictionary) -> bool:
	s.n1 = 2
	s.n2 = 2
	s.bag = false
	s.stage = rng.int_in(1, 2)
	var a: Array = rng.pick(K_FIRST)
	var c: Array = rng.pick(K_SECOND)
	s.a1 = Q.new(a[0], a[1])
	s.a2 = Q.new(c[0], c[1])
	return not s.a1.eq(s.a2)


static func _after_draw(rng: Seeded, s: Dictionary) -> bool:
	if not _bag(rng, s, 2, ["wo", "wo", "add"]):
		return false
	s.i = rng.int_in(0, 1)
	s.j = rng.int_in(0, 1)
	s.v = s.second[s.i][s.j]
	return fits(s, s.v)


# ── Paths ────────────────────────────────────────────────────

static func _path(rng: Seeded, s: Dictionary) -> bool:
	if s.rep == "words" or rng.int_in(0, 1) == 0:
		if not _bag(rng, s, rng.pick([2, 2, 3]), ["wo", "wo", "w"]):
			return false
	else:
		_tree(rng, s, rng.pick([2, 3]), rng.pick([2, 3]))
	s.i = rng.int_in(0, s.n1 - 1)
	s.j = rng.int_in(0, s.n2 - 1)
	if s.bag and s.counts[s.i] < 2:
		return false
	s.v = s.first[s.i].mul(s.second[s.i][s.j])
	var add: Q = s.first[s.i].add(s.second[s.i][s.j])
	return fits(s, s.v) and fits(s, add) and fits(s, s.second[s.i][s.j]) and not s.v.eq(s.second[s.i][s.j])


static func _total(rng: Seeded, s: Dictionary) -> bool:
	if s.rep == "words":
		s.n1 = rng.pick([2, 2, 3])
		s.n2 = 2
		s.bag = false
		s.style = "frac"
		s.crates = []
		s.second = []
		s.cols = rng.int_in(0, ConditionalViews.COLOURS.size() - 1)
		s.thing = rng.int_in(0, ConditionalViews.THINGS.size() - 1)
		if s.paper == 1:
			s.first = []
			for i in s.n1:
				s.first.append(Q.new(1, s.n1))
		else:
			s.first = _fork(rng, s.n1, 20, 3)
		for i in s.n1:
			var a := rng.int_in(2, 7) if s.paper == 1 else rng.int_in(3, 18)
			var b := rng.int_in(2, 7) if s.paper == 1 else rng.int_in(3, 18)
			if a + b == 7 and a in [4, 5]:
				return false
			s.crates.append([a, b])
			s.second.append([Q.new(a, a + b), Q.new(b, a + b)])
	else:
		_tree(rng, s, rng.pick([2, 3]), rng.pick([2, 2, 3]))
	s.j = rng.int_in(0, s.n2 - 1) if s.rep != "words" else 0
	s.v = into(s, s.j)
	var plain := Q.new(0)
	for i in s.n1:
		plain = plain.add(s.second[i][s.j])
	s.i = rng.int_in(0, s.n1 - 1)
	var one: Q = s.first[s.i].mul(s.second[s.i][s.j])
	return fits(s, s.v) and fits(s, one) and fits(s, plain) and not s.v.eq(one) and s.v.lt(Q.new(1))


static func _same_or_different(rng: Seeded, s: Dictionary) -> bool:
	if not _bag(rng, s, rng.pick([2, 2, 3]), ["wo", "wo", "w"]):
		return false
	s.form = rng.pick(["same", "diff"])
	var same := same_colour(s)
	s.v = same if s.form == "same" else Q.new(1).sub(same)
	var plain := same_colour(s, "w")
	var used: Q = plain if s.form == "same" else Q.new(1).sub(plain)
	s.i = 0
	s.j = 1
	return fits(s, s.v) and fits(s, Q.new(1).sub(s.v)) and fits(s, used) and fits(s, path(s, [0, 1]))


static func _at_least_one(rng: Seeded, s: Dictionary) -> bool:
	s.draws = 3 if s.rep == "words" else 2
	if not _bag(rng, s, 2, ["wo"], 3):
		return false
	s.target = rng.int_in(0, 1)
	var other: int = 1 - s.target
	var none := path(s, range(s.draws).map(func(_x): return other))
	s.v = Q.new(1).sub(none)
	return fits(s, s.v) and fits(s, none) and fits(s, Q.new(1).sub(path(s, range(s.draws).map(func(_x): return other), "w"))) and fits(s, exactly_one(s))


## P(exactly one of the draws is the target colour).
static func exactly_one(s: Dictionary) -> Q:
	var out := Q.new(0)
	var other: int = 1 - s.target
	for spot in s.draws:
		var seq: Array = []
		for k in s.draws:
			seq.append(s.target if k == spot else other)
		out = out.add(path(s, seq))
	return out


static func _all_three(rng: Seeded, s: Dictionary) -> bool:
	s.draws = 3
	s.bag = true
	s.style = "frac"
	s.mode = "wo"
	s.n1 = 3 if s.rep == "table" else 2
	s.n2 = s.n1
	s.cols = rng.int_in(0, ConditionalViews.COLOURS.size() - 1)
	s.thing = rng.int_in(0, ConditionalViews.THINGS.size() - 1)
	s.counts = []
	var hi := 9 if s.paper == 1 else (45 if s.rep == "table" else 18)
	for c in s.n1:
		s.counts.append(rng.int_in(3, hi))
	s.target = rng.int_in(0, s.n1 - 1)
	s.v = path(s, [s.target, s.target, s.target])
	return s.v.to_float() >= 0.005 and fits(s, s.v) and fits(s, path(s, [s.target, s.target, s.target], "w")) and s.counts[0] != s.counts[1]


static func _in_n(rng: Seeded, s: Dictionary) -> bool:
	s.bag = true
	s.style = "frac"
	s.thing = rng.int_in(0, ConditionalViews.THINGS.size() - 1)
	s.cols = rng.int_in(0, ConditionalViews.COLOURS.size() - 1)
	s.form = rng.pick(["one", "two", "two"])
	s.big = rng.int_in(5, 16)
	return s.big != 10


# ── One event, repeated ──────────────────────────────────────

static func _first_success(rng: Seeded, s: Dictionary) -> bool:
	s.form = rng.pick(["first", "only"])
	s.k = rng.int_in(3, 5) if s.paper == 2 else rng.int_in(2, 4)
	if s.paper == 2 and rng.int_in(0, 1) == 0:
		s.source = "normal"
		s.mu = rng.int_in(30, 300)
		s.sg = rng.int_in(3, 30)
		s.lim = s.mu + rng.int_in(-10, 14) * s.sg / 10
		var pf: float = 1.0 - SymmetrySituation.phi(float(s.lim - s.mu) / s.sg)
		if pf < 0.1 or pf > 0.85 or s.mu < 4 * s.sg or not fits(s, pf):
			return false
		s.pf = pf
		s.v = pow(1.0 - pf, s.k - 1) * pf
		return s.v >= 0.005 and fits(s, s.v) and fits(s, pow(pf, s.k - 1) * (1.0 - pf)) and fits(s, s.v * s.k) and fits(s, s.v * (1.0 - pf))
	s.source = "plain"
	if s.paper == 1:
		var f: Array = rng.pick(FAIR)
		s.p = Q.new(f[0], f[1])
		s.style = "frac"
	else:
		s.p = Q.new(rng.int_in(10, 70), 100)
	var q: Q = Q.new(1).sub(s.p)
	s.pf = s.p.to_float()
	s.v = power(q, s.k - 1).mul(s.p)
	var swap: Q = power(s.p, s.k - 1).mul(q)
	var orders: Q = s.v.mul(Q.new(s.k))
	var extra: Q = s.v.mul(q)
	return s.v.to_float() >= 0.005 and fits(s, s.v) and fits(s, swap) and fits(s, orders) and fits(s, extra) and orders.lt(Q.new(1)) and not swap.eq(s.v)


static func power(v: Q, n: int) -> Q:
	var out := Q.new(1)
	for i in n:
		out = out.mul(v)
	return out


static func area(s: Dictionary, g: int) -> float:
	return SymmetrySituation.phi(float(s.lim - s.mu[g]) / s.sg[g])


static func _normals(rng: Seeded, s: Dictionary) -> bool:
	s.ctx = rng.pick(MAKERS)
	s.form = rng.pick(["total", "total", "reverse"])
	s.share = Q.new(rng.int_in(5, 15) * 5, 100)
	var m := rng.int_in(40, 300)
	var d := rng.int_in(1, 4)
	s.mu = [m, m + d * rng.int_in(1, 4)]
	s.sg = [rng.int_in(3, 12), rng.int_in(3, 12)]
	if s.sg[0] == s.sg[1]:
		return false
	s.lim = m + rng.int_in(-10, 10)
	var a0 := area(s, 0)
	var a1 := area(s, 1)
	if a0 < NORMAL_MIN or a0 > NORMAL_MAX or a1 < NORMAL_MIN or a1 > NORMAL_MAX or m < 4 * s.sg[0] or s.mu[1] < 4 * s.sg[1]:
		return false
	var pa: float = s.share.to_float()
	s.path0 = pa * a0
	s.path1 = (1.0 - pa) * a1
	s.num = s.path0 + s.path1
	s.v = s.num if s.form == "total" else s.path0 / s.num
	var slips: Array = [s.path0, a0 + a1, a0] if s.form == "total" else [s.path0, a0, s.num]
	for x in slips:
		if not fits(s, x):
			return false
	return s.num >= 0.05 and s.v <= 0.95 and fits(s, s.v) and fits(s, a0)


# ── Equations ────────────────────────────────────────────────

static func _parameter(rng: Seeded, s: Dictionary) -> bool:
	s.n1 = 2
	s.n2 = 2
	s.bag = false
	s.style = "frac"
	var c: Array = rng.pick(K_SECOND)
	s.a2 = Q.new(c[0], c[1])
	var d := rng.int_in(2, 6)
	s.v = Q.new(rng.int_in(1, d - 1), d)
	var one := Q.new(1)
	var other: Q = s.a2.mul(s.v)
	if not s.v.lt(one) or not other.lt(one) or s.v.d != d or (s.a2.eq(Q.new(1, 2)) and s.v.eq(Q.new(1, 3))):
		return false
	s.r = one.sub(s.v).mul(one.sub(other))
	# The other root of a2 k² − (1 + a2) k + 1 − r = 0.
	s.other = one.add(s.a2).div(s.a2).sub(s.v)
	return s.r.to_float() >= 0.1 and (not s.other.lt(one) or not s.a2.mul(s.other).lt(one))


static func _rounds(rng: Seeded, s: Dictionary) -> bool:
	s.rounds = rng.int_in(3, 5)
	s.hi = rng.pick(HIGH)
	s.lo = rng.int_in(1, s.hi / 2)
	s.a = Q.new(rng.int_in(6, 14) * 5, 100)
	s.b = Q.new(rng.int_in(2, 8) * 5, 100)
	s.c = Q.new(1).sub(s.a).sub(s.b)
	if s.c.sign() <= 0:
		return false
	s.limit = (s.rounds - 1) * s.hi
	s.v = game_total(s, true)
	var top: Q = power(s.a, s.rounds)
	var no_orders: Q = top.add(power(s.a, s.rounds - 1).mul(s.b))
	var eq: Q = game_total(s, false)
	return s.v.to_float() >= 0.01 and fits(s, s.v) and fits(s, top) and fits(s, no_orders) and fits(s, eq) and not no_orders.eq(s.v) and s.v.lt(Q.new(1)) and eq.lt(Q.new(1))


## P(the total beats the limit), over every count of each score; `strict` false counts the limit too.
static func game_total(s: Dictionary, strict: bool) -> Q:
	var out := Q.new(0)
	for x in s.rounds + 1:
		for y in s.rounds + 1 - x:
			var z: int = s.rounds - x - y
			var sum: int = x * s.hi + y * s.lo
			if sum > s.limit or (not strict and sum == s.limit):
				var ways := roundi(BinomialSituation.comb(s.rounds, x) * BinomialSituation.comb(s.rounds - x, y))
				out = out.add(power(s.a, x).mul(power(s.b, y)).mul(power(s.c, z)).mul(Q.new(ways)))
	return out


static func _find_n(rng: Seeded, s: Dictionary) -> bool:
	s.bag = true
	s.style = "frac"
	s.cols = rng.int_in(0, ConditionalViews.COLOURS.size() - 1)
	s.thing = rng.int_in(0, ConditionalViews.THINGS.size() - 1)
	s.r0 = rng.pick([2, 4, 5, 6])
	s.n = rng.int_in(3, 8)
	s.v = s.n
	var m: int = s.r0 + s.n
	s.m = m
	s.chance = Q.new(s.r0, m * (m - 1))
	return true


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
