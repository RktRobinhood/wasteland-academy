class_name BasicProbabilitySituation
extends RefCounted
## The `basic-probability` situation (curriculum/question-types.json): one chance set-up, for
## t4-probability-basic (SL4.5, FAL-728). Each unknown has its own: a bag, a two-way table, a list
## of data, two dice or two spinners, a small sample space, one event, independent trials, a
## results table or bar chart, a running relative frequency, two tests or a streak. `form` says how
## the answer is written:
##   frac   an exact fraction: Paper 1 counts
##   dec    a decimal that ends: the question writes decimals, or a graph is read
##   sf     Paper 2 counts and products, to 3 s.f. These answers need rounding, and sit at least
##          EDGE of a unit of the third figure from a rounding edge
## A Paper 2 label needs no GDC here: it gives bigger counts and awkward values, nothing more.
##
## need.ask is the unknown (see BasicProbabilityViews). generate() returns a Dictionary with paper,
## ask, rep, form and ctx (an index into a list of stories), and:
##   counts, cols, target, others   bags, frequency tables and bar charts
##   cells, r, c                    two-way-whole: 2 by 3 counts and the cell asked
##   vals, op, k                    list-data: the list, "more", "least" or "less", the boundary
##   kind, xs, ys, k                grids: the two sets of faces and the total asked
##   kind, ...                      list-then-count: coins, coin-die, pairs or cards
##   p, ps, n                       trials: the probability, or one each, and how many
##   curve, early, settle           rf-graph-estimate: [[trials, relative frequency], ...]
##   ns, hits, large                more-reliable: two tests and which is the larger
##   kind, streak, p                gamblers-fallacy
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 4000
const EDGE := 0.03
const CONTEXTS := 8
## Totals whose relative frequencies end, on Paper 1.
const P1_TOTALS := [20, 25, 40, 50, 80, 100, 200]
const NAMES := 6
const SMALL_N := [10, 20, 25, 40, 50]
const LARGE_N := [200, 250, 400, 500, 1000]
const CARD_DIGITS := [1, 2, 3, 4, 5, 6, 7, 8, 9]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "bag-counter")
	var rep: String = need.get("rep", "words")
	var paper: int = int(need.get("paper", 1))
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "ctx": rng.int_in(0, CONTEXTS - 1), "form": "sf" if paper == 2 else "frac"}
		var ok := false
		match ask:
			"bag-counter":
				ok = _bag(rng, s)
			"bag-after-removal":
				ok = _bag_after(rng, s)
			"two-way-whole":
				ok = _two_way(rng, s)
			"list-data":
				ok = _list_data(rng, s)
			"grid-total-equals":
				ok = _grid_equals(rng, s)
			"grid-total-at-least":
				ok = _grid_at_least(rng, s)
			"list-then-count":
				ok = _list_then_count(rng, s)
			"complement-given":
				ok = _complement_given(rng, s)
			"complement-table":
				ok = _complement_table(rng, s)
			"complement-count":
				ok = _complement_count(rng, s)
			"at-least-one-same":
				ok = _same_trials(rng, s)
			"at-least-one-different":
				ok = _different_trials(rng, s)
			"rf-from-table":
				ok = _rf_table(rng, s)
			"rf-total-to-find":
				ok = _rf_total(rng, s)
			"rf-graph-estimate":
				ok = _rf_graph(rng, s)
			"more-reliable":
				ok = _reliable(rng, s)
			"gamblers-fallacy":
				ok = _streak(rng, s)
		if ok:
			return s
	return {}


## An answer in `sf` form needs rounding and sits clear of a rounding edge.
static func clear(s: Dictionary, v: Q) -> bool:
	return s.form != "sf" or (Answer.needs_rounding(v) and Answer.rounds_clearly(v.to_float(), EDGE))


static func sum(xs: Array) -> int:
	var t := 0
	for x in xs:
		t += int(x)
	return t


static func _counts(rng: Seeded, k: int, lo: int, hi: int) -> Array:
	var out: Array = []
	for i in k:
		out.append(rng.int_in(lo, hi))
	return out


## k whole numbers from lo up that add to total, or [] if they can't.
static func _split(rng: Seeded, total: int, k: int, lo: int) -> Array:
	var left := total - k * lo
	if left < 0:
		return []
	var out: Array = []
	for i in k:
		out.append(lo)
	for i in 3 * k:
		var add := rng.int_in(0, left)
		out[rng.int_in(0, k - 1)] += add
		left -= add
	out[rng.int_in(0, k - 1)] += left
	return out


# ── Equally likely ───────────────────────────────────────────

static func _bag(rng: Seeded, s: Dictionary) -> bool:
	var k := rng.int_in(3, 4)
	s.counts = _counts(rng, k, 2, 9) if s.paper == 1 else _counts(rng, k, 5, 40)
	s.target = [rng.int_in(0, k - 1)]
	if k == 4 and rng.chance(0.4):
		s.target = [0, 1 + rng.int_in(0, 2)]
	s.cols = rng.shuffled(range(5)).slice(0, k)
	var n := 0
	for t in s.target:
		n += int(s.counts[t])
	return n * 2 < sum(s.counts) and not Q.new(n, sum(s.counts)).eq(Q.new(s.target.size(), k)) and clear(s, Q.new(n, sum(s.counts)))


static func _bag_after(rng: Seeded, s: Dictionary) -> bool:
	var k := rng.int_in(2, 3)
	s.counts = _counts(rng, k, 3, 10) if s.paper == 1 else _counts(rng, k, 6, 40)
	s.cols = rng.shuffled(range(5)).slice(0, k)
	s.removed = rng.int_in(0, k - 1)
	s.m = rng.int_in(1, 3)
	s.target = rng.int_in(0, k - 1)
	var left: int = int(s.counts[s.target]) - (s.m if s.target == s.removed else 0)
	return left >= 1 and left < sum(s.counts) - s.m and clear(s, Q.new(left, sum(s.counts) - s.m))


static func _two_way(rng: Seeded, s: Dictionary) -> bool:
	s.cells = [_counts(rng, 3, 2, 12), _counts(rng, 3, 2, 12)] if s.paper == 1 else [_counts(rng, 3, 6, 60), _counts(rng, 3, 6, 60)]
	s.r = rng.int_in(0, 1)
	s.c = rng.int_in(0, 2)
	var cell: int = int(s.cells[s.r][s.c])
	var total: int = sum(s.cells[0]) + sum(s.cells[1])
	return sum(s.cells[0]) != sum(s.cells[1]) and sum(s.cells[s.r]) != int(s.cells[0][s.c]) + int(s.cells[1][s.c]) and clear(s, Q.new(cell, total))


static func _list_data(rng: Seeded, s: Dictionary) -> bool:
	var n := rng.int_in(10, 15) if s.paper == 1 else rng.int_in(14, 24)
	s.vals = _counts(rng, n, 2, 12)
	s.op = rng.pick(["more", "least", "less"])
	s.k = rng.int_in(4, 10)
	if not s.k in s.vals:
		return false
	var hit := list_hits(s)
	var inside := 0
	var kinds := {}
	for v in s.vals:
		kinds[v] = true
	for v in kinds:
		if list_test(s.op, int(v), s.k):
			inside += 1
	return hit > 0 and hit < n and kinds.size() < n and not Q.new(hit, n).eq(Q.new(inside, kinds.size())) and clear(s, Q.new(hit, n))


static func list_test(op: String, v: int, k: int) -> bool:
	match op:
		"more":
			return v > k
		"least":
			return v >= k
	return v < k


static func list_hits(s: Dictionary) -> int:
	return s.vals.filter(func(v): return list_test(s.op, int(v), s.k)).size()


## Two dice, or two spinners of equal sectors: three on Paper 2's awkward grids, up to five.
static func _faces(rng: Seeded, s: Dictionary) -> void:
	if rng.chance(0.6):
		s.kind = "dice"
		s.xs = [1, 2, 3, 4, 5, 6]
		s.ys = [1, 2, 3, 4, 5, 6]
	else:
		s.kind = "spinners"
		s.xs = _sorted_pick(rng, range(1, 10), rng.int_in(3, 5))
		s.ys = _sorted_pick(rng, range(1, 10), rng.int_in(3, 5))


static func _sorted_pick(rng: Seeded, from: Array, n: int) -> Array:
	var out: Array = rng.shuffled(from).slice(0, n)
	out.sort()
	return out


## Every total of the grid, one per outcome.
static func totals(s: Dictionary) -> Array:
	var out: Array = []
	for x in s.xs:
		for y in s.ys:
			out.append(int(x) + int(y))
	return out


static func distinct(xs: Array) -> Array:
	var seen := {}
	for x in xs:
		seen[x] = true
	var out: Array = seen.keys()
	out.sort()
	return out


static func _grid_equals(rng: Seeded, s: Dictionary) -> bool:
	_faces(rng, s)
	var ts := totals(s)
	s.k = rng.pick(distinct(ts))
	var n: int = ts.count(s.k)
	return n >= 2 and not Q.new(n, ts.size()).eq(Q.new(1, distinct(ts).size())) and clear(s, Q.new(n, ts.size()))


static func _grid_at_least(rng: Seeded, s: Dictionary) -> bool:
	_faces(rng, s)
	var ts := totals(s)
	var ds := distinct(ts)
	s.k = rng.pick(ds)
	var n := ts.filter(func(t): return t >= s.k).size()
	var kinds := ds.filter(func(t): return t >= s.k).size()
	return n >= 3 and n < ts.size() - 2 and s.k in ts and n != ts.filter(func(t): return t > s.k).size() \
		and not Q.new(n, ts.size()).eq(Q.new(kinds, ds.size())) and clear(s, Q.new(n, ts.size()))


static func _list_then_count(rng: Seeded, s: Dictionary) -> bool:
	s.kind = rng.pick(["coins", "coin-die", "pairs", "cards"])
	var hit := 0
	var all := 1
	match s.kind:
		"coins":
			s.n = 3 if s.paper == 2 or rng.chance(0.6) else 2
			s.h = rng.int_in(1, s.n - 1)
			# Eighths end, so a coin question keeps its decimal on Paper 2.
			if s.paper == 2:
				s.form = "dec"
			return true
		"coin-die":
			s.side = rng.pick(["head", "tail"])
			s.cond = rng.pick(["even", "odd", "more"])
			s.m = rng.int_in(2, 4)
			all = 12
			hit = die_hits(s)
		"pairs":
			s.n = rng.int_in(4, 6)
			s.both = rng.chance(0.5)
			s.names = rng.shuffled(range(NAMES)).slice(0, s.n)
			all = s.n * (s.n - 1) / 2
			hit = 1 if s.both else s.n - 1
		"cards":
			s.digits = _sorted_pick(rng, CARD_DIGITS, 3)
			s.cond = rng.pick(["even", "above"])
			var a: int = s.digits[0]
			var b: int = s.digits[1]
			var c: int = s.digits[2]
			s.above = 100 * b + 10 * a + c
			all = 6
			hit = card_numbers(s).filter(func(x): return card_hit(s, x)).size()
	return hit >= 1 and hit < all and clear(s, Q.new(hit, all))


static func die_hits(s: Dictionary) -> int:
	match s.cond:
		"even", "odd":
			return 3
	return 6 - s.m


static func card_numbers(s: Dictionary) -> Array:
	var d: Array = s.digits
	var out: Array = []
	for i in 3:
		for j in 3:
			for k in 3:
				if i != j and j != k and i != k:
					out.append(100 * int(d[i]) + 10 * int(d[j]) + int(d[k]))
	out.sort()
	return out


static func card_hit(s: Dictionary, x: int) -> bool:
	return x % 2 == 0 if s.cond == "even" else x > s.above


# ── Complements ──────────────────────────────────────────────

static func _complement_given(rng: Seeded, s: Dictionary) -> bool:
	if s.paper == 2:
		s.form = "dec"
		s.p = Q.new(rng.int_in(101, 899), 1000)
	elif rng.chance(0.5):
		s.form = "dec"
		s.p = Q.new(rng.int_in(11, 89), 100)
	else:
		s.form = "frac"
		var d := rng.int_in(5, 12)
		s.p = Q.new(rng.int_in(1, d - 1), d)
	return not s.p.eq(Q.new(1, 2))


static func _complement_table(rng: Seeded, s: Dictionary) -> bool:
	var k := rng.int_in(3, 5)
	s.target = rng.int_in(0, k - 1)
	s.cols = rng.shuffled(range(5)).slice(0, k)
	s.kind = rng.pick(["count", "prob"])
	if s.kind == "prob":
		s.form = "dec"
		var unit := 20 if s.paper == 1 else 1000
		var lo := 1 if s.paper == 1 else 40
		s.counts = _split(rng, unit, k, lo)
		s.unit = unit
		return int(s.counts[s.target]) * 2 != unit
	s.counts = _counts(rng, k, 2, 12) if s.paper == 1 else _counts(rng, k, 8, 70)
	s.unit = sum(s.counts)
	return int(s.counts[s.target]) * 2 != s.unit and clear(s, Q.new(s.unit - int(s.counts[s.target]), s.unit))


static func _complement_count(rng: Seeded, s: Dictionary) -> bool:
	if s.rep == "diagram":
		_faces(rng, s)
		var ts := totals(s)
		s.k = rng.pick(distinct(ts))
		var n: int = ts.count(s.k)
		return n >= 2 and clear(s, Q.new(ts.size() - n, ts.size())) and not Q.new(n, ts.size()).eq(Q.new(1, distinct(ts).size()))
	s.big = rng.int_in(20, 60) if s.paper == 1 else rng.int_in(60, 200)
	s.m = rng.int_in(3, 9)
	var hits: int = s.big / s.m
	return s.big % s.m != 0 and clear(s, Q.new(s.big - hits, s.big))


# ── At least one ─────────────────────────────────────────────

static func none_of(ps: Array) -> Q:
	var out := Q.new(1)
	for p in ps:
		out = out.mul(Q.new(1).sub(p))
	return out


static func exactly_one(ps: Array) -> Q:
	var out := Q.new(0)
	for i in ps.size():
		var term: Q = ps[i]
		for j in ps.size():
			if j != i:
				term = term.mul(Q.new(1).sub(ps[j]))
		out = out.add(term)
	return out


static func total_of(ps: Array) -> Q:
	var out := Q.new(0)
	for p in ps:
		out = out.add(p)
	return out


## The trials are clean where the three numbers the options show are clear of a rounding edge.
static func _trials_clean(s: Dictionary, ps: Array) -> bool:
	var answer := Q.new(1).sub(none_of(ps))
	if not clear(s, answer):
		return false
	if s.form == "sf":
		for v in [exactly_one(ps), total_of(ps)]:
			if Answer.needs_rounding(v) and not Answer.rounds_clearly(v.to_float(), EDGE):
				return false
	return total_of(ps).lt(Q.new(1))


static func _same_trials(rng: Seeded, s: Dictionary) -> bool:
	s.n = 2 if s.rep == "diagram" or rng.chance(0.4) else 3
	if s.paper == 2:
		s.p = Q.new(rng.int_in(5, 31), 100)
	elif rng.chance(0.5):
		s.form = "dec"
		s.p = Q.new(rng.int_in(1, 4), 10)
	else:
		s.p = Q.new(1, rng.int_in(3, 6))
	var ps: Array = []
	for i in s.n:
		ps.append(s.p)
	return _trials_clean(s, ps)


static func _different_trials(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.int_in(2, 3)
	s.ps = []
	for i in s.n:
		s.ps.append(Q.new(rng.int_in(1, 5), 10) if s.paper == 1 else Q.new(rng.int_in(5, 45), 100))
	if s.paper == 1:
		s.form = "dec"
	return not s.ps[0].eq(s.ps[1]) and _trials_clean(s, s.ps)


# ── Relative frequency ───────────────────────────────────────

static func _rf_table(rng: Seeded, s: Dictionary) -> bool:
	var k := rng.int_in(4, 5)
	var total: int = int(rng.pick(P1_TOTALS)) if s.paper == 1 else rng.int_in(120, 900)
	s.form = "dec" if s.paper == 1 else "sf"
	s.counts = _split(rng, total, k, 2)
	s.target = rng.int_in(0, k - 1)
	if s.counts.is_empty():
		return false
	var f: int = s.counts[s.target]
	return f * 2 < total and clear(s, Q.new(f, total)) and not Q.new(f, total).eq(Q.new(1, k))


static func _rf_total(rng: Seeded, s: Dictionary) -> bool:
	var k := rng.int_in(4, 6)
	var total: int = int(rng.pick(P1_TOTALS)) if s.paper == 1 else rng.int_in(90, 500)
	s.form = "dec" if s.paper == 1 else "sf"
	s.counts = _split(rng, total, k, 3)
	if s.counts.is_empty():
		return false
	s.from_score = rng.int_in(1, k)
	s.least = rng.chance(0.4) and s.from_score > 1
	var f := rf_hits(s)
	return f * 2 < total and clear(s, Q.new(f, total))


static func rf_hits(s: Dictionary) -> int:
	if not s.least:
		return s.counts[s.from_score - 1]
	return sum(s.counts.slice(s.from_score - 1))


## A running relative frequency with a decaying wobble. Every point is a real count of hits:
## the hits only go up, and never by more than the trials added.
static func _rf_graph(rng: Seeded, s: Dictionary) -> bool:
	s.form = "dec"
	var step := 10 if s.paper == 1 else 25
	var settle := rng.int_in(10, 40) * 2
	if settle == 50:
		return false
	s.settle = Q.new(settle, 100)
	s.x1 = step * 40
	s.dx = 20 if s.paper == 1 else 50
	var sign := 1.0 if rng.chance(0.5) else -1.0
	var size := 0.14 + 0.02 * rng.int_in(0, 6)
	var turn := 0.8 + 0.1 * rng.int_in(0, 4)
	var hits := 0
	var trials := 0
	s.curve = []
	for i in range(1, 41):
		var f: float = float(settle) / 100.0 + sign * size * cos(turn * (i - 1)) / pow(float(i), 1.3)
		var now: int = roundi(f * step * i)
		if now < hits or now - hits > step:
			return false
		hits = now
		trials = step * i
		s.curve.append([trials, Q.new(hits, trials).to_float()])
	s.early = Q.new(roundi(float(s.curve[0][1]) * step), step)
	return absf(s.early.to_float() - float(settle) / 100.0) >= 0.12


static func _reliable(rng: Seeded, s: Dictionary) -> bool:
	s.form = "dec" if s.paper == 1 else "sf"
	var few: int = int(rng.pick(SMALL_N)) if s.paper == 1 else rng.int_in(12, 60)
	var many: int = int(rng.pick(LARGE_N)) if s.paper == 1 else rng.int_in(300, 1500)
	var hit_few := rng.int_in(2, few - 2)
	var hit_many := rng.int_in(many / 5, many * 4 / 5)
	s.large = rng.int_in(0, 1)
	s.ns = [few, many] if s.large == 1 else [many, few]
	s.hits = [hit_few, hit_many] if s.large == 1 else [hit_many, hit_few]
	s.names = rng.shuffled(range(NAMES)).slice(0, 2)
	var a := Q.new(hit_few, few)
	var b := Q.new(hit_many, many)
	var gap := absf(a.to_float() - b.to_float())
	return gap >= 0.02 and gap <= 0.3 and clear_or_end(s, a) and clear_or_end(s, b)


## A value shown but not answered: clear of a rounding edge, whether or not it is rounded.
static func clear_or_end(s: Dictionary, v: Q) -> bool:
	return s.form != "sf" or not Answer.needs_rounding(v) or Answer.rounds_clearly(v.to_float(), EDGE)


static func _streak(rng: Seeded, s: Dictionary) -> bool:
	s.kind = rng.pick(["coin", "die", "spinner"])
	s.streak = rng.int_in(5, 12)
	match s.kind:
		"coin":
			s.p = Q.new(1, 2)
			s.heads = rng.chance(0.5)
		"die":
			s.p = Q.new(1, 6)
			s.face = rng.int_in(1, 6)
		"spinner":
			s.sectors = rng.int_in(3, 8)
			s.p = Q.new(1, s.sectors)
	return true


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
