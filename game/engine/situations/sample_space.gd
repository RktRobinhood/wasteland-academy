class_name SampleSpaceSituation
extends RefCounted
## The `sample-space` situation (curriculum/question-types.json): two dice or spinners, an m × n
## grid of outcomes, and what follows from it (FAL-752). t4-sample-space is built on it. A pair of
## objects is fair, or biased with its probabilities in a table, a figure or a sentence, or has a
## face or a probability left as a letter. Everything is exact: a count is an int and a probability
## a Q. A number on two faces is two cells of the grid, because the faces are the outcomes.
##
## need.ask is the unknown (see SampleSpaceViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx (an index into STORIES)
##   form          how a probability is written: "frac", "dec" (exact) or "sf" (Paper 2)
##   kind          "dice", "mixed" (a die and a spinner), "spinners", or for one biased object
##                 "die" or "spinner"
##   xs, ys        the faces, sorted, one entry per face; a biased object has ys = xs
##   rule          "sum", "product", "difference" or "max"
##   event         what passes(): "score" (rel, k), "prop" (prop), "higher", "points" (d, case)
##   rel, k, mirror  "=", ">=", ">", "<=" or "<", the score it is tested against, and k's reflection
##   prop          "even", "odd", "mult3", "mult4", "prime" or "square"
##   hit, all      the cells in the event, and all the cells
##   hide          fill-cell: [row, column] of the hidden cell
##   hi, mid, d, case   p-rule-points: the points, the difference that earns mid, and "mid" or "some"
##   px            a biased object's probabilities, Q, one per face of xs
##   goal, score, rolls  weighted-target: the total to reach, the total so far, the rolls so far
##   c, a, b, t    the face problems: the second die is c, a, a, b; t is the sum a fact is about
##   count, u      how many cells have sum t, and how many of those are in the c and b columns
##   qy, ry, pa    the win problems: P(Y = y) is qy on each face but the last, which has ry, and
##                 pa is P(X < Y)
##   gs, cq, cr    P(X < y) for each y, and the numbers of cq q + cr r = pa
##   tie_q         the q that P(X ≤ Y) = pa would give, the ties slip
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its own copy.

const TRIES := 6000
## At most this many cells in an event, so a worked solution can list them.
const MAX_LISTED := 16
## The same for a biased object, whose working multiplies out every cell.
const MAX_WEIGHTED := 8
const SIDES_1 := {"die": [4, 6], "spinner": [3, 4, 5, 6]}
const SIDES_2 := {"die": [6, 8], "spinner": [5, 6, 8]}
const RULES := ["sum", "product", "difference", "max"]
const RELS := [">=", ">", "<=", "<"]
const PROPS := ["even", "odd", "mult3", "mult4", "prime", "square"]
const PRIMES := [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61]
const SQUARES := [1, 4, 9, 16, 25, 36, 49, 64, 81]
## The first die of a face problem, with a repeat as in a die with unusual faces.
const ODD_DICE := [[1, 2, 2, 3], [1, 1, 2, 3], [1, 2, 3, 3], [2, 3, 3, 4], [1, 3, 3, 4], [0, 1, 1, 2]]
## The most different sums a distribution table may have, to fit a phone.
const MAX_SUMS := 7
## P(X < Y) in the win problems stays a fraction a student can write.
const MAX_WIN_DEN := 60
const DENS := [4, 5, 6, 8, 10]
const Q_DENS := [4, 5, 6, 8, 10, 12]

## How each game opens: "<story> <the objects>."
const STORIES := [
	"At a Bazaar stall, a game uses",
	"The gate guards pass the night with a game that uses",
	"At the depot, the scavengers settle who cooks with a game that uses",
	"A salt trader offers travellers a game that uses",
	"The convoy drivers kill time with a game that uses",
	"Around the camp fire, the medics play a game that uses",
]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "p-score")
	var rep: String = need.get("rep", "table")
	var paper := int(need.get("paper", 1))
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "ctx": rng.int_in(0, STORIES.size() - 1),
			"form": "sf" if paper == 2 else "frac"}
		if _draw(rng, s):
			return s
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"fill-cell":
			return _fair(rng, s) and _hide(rng, s)
		"total-outcomes":
			return _fair(rng, s)
		"count-event":
			return _fair(rng, s) and _event(rng, s, ["=", ">="] + RELS)
		"p-score":
			return _fair(rng, s) and _event(rng, s, ["="])
		"p-at-least":
			return _fair(rng, s) and _event(rng, s, RELS)
		"p-complement":
			return _fair(rng, s) and _event(rng, s, ["="])
		"p-property":
			return _fair(rng, s) and _property(rng, s)
		"p-compare":
			return _fair(rng, s) and _compare(s)
		"p-mirror-score":
			return _matching(rng, s, [4, 6, 8]) and _mirror(rng, s, "=")
		"p-mirror-at-least":
			return _matching(rng, s, [4, 6, 8]) and _mirror(rng, s, ">=")
		"p-rule-points":
			return _matching(rng, s, SIDES_2.spinner if s.paper == 2 else [4, 5, 6]) and _points(rng, s)
		"weighted-sum", "weighted-target":
			return _biased(rng, s)
		"face-from-largest", "face-from-grid":
			return _odd_faces(rng, s)
		"weight-from-win", "expected-from-win":
			return _win(rng, s)
	return false


# ── Faces ────────────────────────────────────────────────────

## The faces of a fair object: 1 to n, or usually so, and sometimes unusual ones with a repeat.
static func _faces(rng: Seeded, n: int) -> Array:
	var out: Array = range(1, n + 1)
	if rng.chance(0.35):
		out = rng.shuffled(range(0, 10)).slice(0, n - 1)
		out.append(out[0])
		out.sort()
	return out


static func _sides(s: Dictionary, what: String) -> Array:
	return (SIDES_2 if s.paper == 2 else SIDES_1)[what]


static func _fair(rng: Seeded, s: Dictionary) -> bool:
	s.kind = rng.pick(["dice", "mixed", "spinners"])
	var first := "spinner" if s.kind == "spinners" else "die"
	var second := "die" if s.kind == "dice" else "spinner"
	s.xs = _faces(rng, rng.pick(_sides(s, first)))
	s.ys = _faces(rng, rng.pick(_sides(s, second)))
	s.rule = rng.pick(RULES)
	s.all = s.xs.size() * s.ys.size()
	return true


## Two matching fair objects numbered 1 to n, added.
static func _matching(rng: Seeded, s: Dictionary, sides: Array) -> bool:
	s.kind = rng.pick(["dice", "spinners"])
	var n: int = rng.pick(sides)
	if s.kind == "dice" and not n in [4, 6, 8]:
		s.kind = "spinners"
	s.xs = range(1, n + 1)
	s.ys = range(1, n + 1)
	s.rule = "sum"
	s.all = n * n
	return true


static func score(rule: String, a: int, b: int) -> int:
	match rule:
		"sum":
			return a + b
		"product":
			return a * b
		"difference":
			return absi(a - b)
	return maxi(a, b)


## Every cell's score, row by row.
static func scores(s: Dictionary) -> Array:
	var out: Array = []
	for x in s.xs:
		for y in s.ys:
			out.append(score(s.rule, x, y))
	return out


static func distinct(values: Array) -> Array:
	var seen := {}
	for v in values:
		seen[v] = true
	var out: Array = seen.keys()
	out.sort()
	return out


## How many different scores the grid has.
static func kinds(s: Dictionary) -> int:
	return distinct(scores(s)).size()


static func compare(rel: String, v: int, k: int) -> bool:
	match rel:
		"=":
			return v == k
		">=":
			return v >= k
		">":
			return v > k
		"<=":
			return v <= k
	return v < k


static func has_property(prop: String, v: int) -> bool:
	match prop:
		"even":
			return v % 2 == 0
		"odd":
			return v % 2 != 0
		"mult3":
			return v % 3 == 0
		"mult4":
			return v % 4 == 0
		"prime":
			return v in PRIMES
	return v in SQUARES


## Whether the cell (a, b) is in the question's event.
static func passes(s: Dictionary, a: int, b: int) -> bool:
	match s.event:
		"score":
			return compare(s.rel, score(s.rule, a, b), s.k)
		"prop":
			return has_property(s.prop, score(s.rule, a, b))
		"higher":
			return a > b
		"points":
			return absi(a - b) == s.d or (s.case == "some" and a == b)
	return false


## The cells in the event as [a, b], one entry per cell: a repeated face comes up twice.
static func hits(s: Dictionary) -> Array:
	var out: Array = []
	for x in s.xs:
		for y in s.ys:
			if passes(s, x, y):
				out.append([x, y])
	return out


## Whether both objects have every face different, so a pair names one cell.
static func all_different(s: Dictionary) -> bool:
	return distinct(s.xs).size() == s.xs.size() and distinct(s.ys).size() == s.ys.size()


## The cells left when a pair and its reverse are counted once.
static func merged(pairs: Array) -> int:
	var seen := {}
	for p in pairs:
		seen["%d,%d" % [mini(p[0], p[1]), maxi(p[0], p[1])]] = true
	return seen.size()


## A Paper 2 probability is a real rounding, clear of an edge; a Paper 1 one is exact.
static func clean(s: Dictionary, v: Q) -> bool:
	return s.paper != 2 or (Answer.needs_rounding(v) and Answer.rounds_clearly(v.to_float(), 0.03))


# ── Events on a fair grid ────────────────────────────────────

static func _hide(rng: Seeded, s: Dictionary) -> bool:
	s.hide = [rng.int_in(0, s.xs.size() - 1), rng.int_in(0, s.ys.size() - 1)]
	var a: int = s.xs[s.hide[0]]
	var b: int = s.ys[s.hide[1]]
	# The other operations and the next cell along all read differently from the answer.
	return a >= 2 and b >= 2 and a != b and s.ys.size() >= 2


static func _event(rng: Seeded, s: Dictionary, rels: Array) -> bool:
	s.event = "score"
	s.rel = rng.pick(rels)
	s.k = rng.pick(distinct(scores(s)))
	s.hit = hits(s).size()
	if s.hit < 2 or s.hit > MAX_LISTED or s.hit >= s.all:
		return false
	var v := Q.new(s.hit, s.all)
	if s.ask == "p-complement":
		v = Q.new(s.all - s.hit, s.all)
	return clean(s, v)


static func _property(rng: Seeded, s: Dictionary) -> bool:
	s.rule = rng.pick(["sum", "product"])
	s.event = "prop"
	s.prop = rng.pick(PROPS)
	s.hit = hits(s).size()
	var zero := false
	for v in scores(s):
		zero = zero or v == 0
	return not zero and s.hit >= 2 and s.hit <= MAX_LISTED and s.hit < s.all and clean(s, Q.new(s.hit, s.all))


## The first object's number is higher than the second's, with ties in the grid and the two
## sides different, so each slip gives its own value.
static func _compare(s: Dictionary) -> bool:
	s.event = "higher"
	s.hit = hits(s).size()
	var ties := 0
	var other := 0
	for x in s.xs:
		for y in s.ys:
			ties += 1 if x == y else 0
			other += 1 if x < y else 0
	return s.hit >= 2 and s.hit <= MAX_LISTED and ties > 0 and other != s.hit and s.hit * 2 != s.all \
			and clean(s, Q.new(s.hit, s.all))


## A sum above the middle, so the mirror of it is a sum on the lower side.
static func _mirror(rng: Seeded, s: Dictionary, rel: String) -> bool:
	var n: int = s.xs.size()
	s.event = "score"
	s.rel = rel
	s.k = rng.int_in(n + 2, 2 * n - 1)
	s.mirror = 2 * n + 2 - s.k
	s.hit = hits(s).size()
	return s.hit >= 2 and s.hit <= MAX_LISTED


static func _points(rng: Seeded, s: Dictionary) -> bool:
	s.event = "points"
	s.d = rng.pick([1, 2])
	s.case = rng.pick(["mid", "some"])
	s.hi = rng.pick([6, 8, 10, 12])
	s.mid = rng.pick([2, 3, 4, 5])
	s.hit = hits(s).size()
	return s.hit >= 2 and s.hit <= MAX_LISTED and s.hit * 2 != s.all and clean(s, Q.new(s.hit, s.all))


# ── One biased die, two rolls ────────────────────────────────

## n positive whole numbers adding to total, not all equal, each at least low.
static func _split(rng: Seeded, n: int, total: int, low: int) -> Array:
	var out: Array = []
	var left := total
	for i in n - 1:
		var most := left - low * (n - 1 - i)
		if most < low:
			return []
		var v := rng.int_in(low, mini(most, low + (total / n) * 2))
		out.append(v)
		left -= v
	out.append(left)
	return rng.shuffled(out)


static func _biased(rng: Seeded, s: Dictionary) -> bool:
	s.kind = "spinner" if s.rep == "diagram" else rng.pick(["die", "spinner"])
	var n: int = rng.pick([3, 4] if s.paper == 1 else [4, 5])
	s.form = "sf" if s.paper == 2 else "dec"
	s.xs = range(1, n + 1)
	s.ys = s.xs
	s.rule = "sum"
	s.all = n * n
	var parts := _split(rng, n, 100 if s.paper == 2 else 10, 11 if s.paper == 2 else 1)
	if parts.is_empty() or distinct(parts).size() == 1:
		return false
	s.px = parts.map(func(p): return Q.new(p, 100 if s.paper == 2 else 10))
	s.event = "score"
	s.rel = ">=" if s.ask == "weighted-target" else rng.pick([">=", "="])
	s.k = rng.int_in(3, 2 * n - 1)
	var pairs := hits(s)
	s.hit = pairs.size()
	if s.hit < 2 or s.hit > MAX_WEIGHTED or s.hit >= s.all:
		return false
	# A pair and its reverse are both in the event, so counting them once changes the answer.
	if merged(pairs) == s.hit:
		return false
	if s.ask == "weighted-target":
		s.rolls = rng.int_in(2, 4)
		s.score = rng.int_in(s.rolls, s.rolls * n - 1)
		s.goal = s.score + s.k
	return clean(s, weighted(s, pairs))


## P(X = a) for a face of a biased object.
static func p_of(s: Dictionary, a: int) -> Q:
	return s.px[s.xs.find(a)]


## The chance of a list of cells, each P(a) × P(b).
static func weighted(s: Dictionary, pairs: Array) -> Q:
	var out := Q.new(0)
	for p in pairs:
		out = out.add(p_of(s, p[0]).mul(p_of(s, p[1])))
	return out


# ── A face to find ───────────────────────────────────────────

## How many cells of xs against the faces have this sum.
static func sum_count(xs: Array, faces: Array, t: int) -> int:
	var out := 0
	for x in xs:
		for y in faces:
			out += 1 if x + y == t else 0
	return out


## Every sum of xs against the faces, sorted.
static func sums_of(xs: Array, faces: Array) -> Array:
	var out: Array = []
	for x in xs:
		for y in faces:
			out.append(x + y)
	return distinct(out)


## The second object is c, a, a, b with c < a < b. A sum t is picked that only one whole a between
## c and b gives the right count at, with a row of the first object behind it.
static func _odd_faces(rng: Seeded, s: Dictionary) -> bool:
	s.kind = "dice"
	s.xs = rng.pick(ODD_DICE)
	s.c = rng.int_in(1, 2)
	s.a = s.c + rng.int_in(1, 3)
	s.b = s.a + rng.int_in(1, 3)
	s.ys = [s.c, s.a, s.a, s.b]
	s.all = s.xs.size() * 4
	s.rule = "sum"
	var sums := sums_of(s.xs, s.ys)
	if sums.size() > MAX_SUMS or s.b - s.c < 3:
		return false
	for t in rng.shuffled(sums):
		var count := sum_count(s.xs, s.ys, t)
		var alone := true
		for other in range(s.c + 1, s.b):
			if other != s.a and sum_count(s.xs, [s.c, other, other, s.b], t) == count:
				alone = false
		var u := sum_count(s.xs, [s.c, s.b], t)
		if alone and count > u:
			s.t = t
			s.count = count
			s.u = u
			return true
	return false


# ── Two biased dice, a chance to find ────────────────────────

static func _win(rng: Seeded, s: Dictionary) -> bool:
	var n: int = rng.pick([3, 4])
	s.kind = "dice"
	s.xs = range(1, n + 1)
	s.ys = s.xs
	var den: int = rng.pick(DENS)
	var parts := _split(rng, n, den, 1)
	if parts.is_empty() or distinct(parts).size() == 1:
		return false
	s.px = parts.map(func(p): return Q.new(p, den))
	var qd: int = rng.pick(Q_DENS)
	s.qy = Q.new(rng.int_in(1, qd - 1), qd)
	s.ry = Q.new(1).sub(s.qy.mul(Q.new(n - 1)))
	if s.ry.sign() <= 0 or s.ry.eq(s.qy):
		return false
	s.gs = lows(s.xs, s.px, 0)
	var line := _win_line(s.gs, n)
	if line.coef.is_zero():
		return false
	s.cq = line.cq
	s.cr = line.cr
	s.pa = line.cq.mul(s.qy).add(line.cr.mul(s.ry))
	if s.pa.sign() <= 0 or Q.new(1).sub(s.pa).sign() <= 0 or s.pa.d > MAX_WIN_DEN:
		return false
	# Counting ties in the event, and the other wrong answers, have to make a real die.
	s.tie_q = _tie_q(s, n)
	return s.tie_q != null and not s.tie_q.eq(s.qy)


## P(X < y) for each y of the faces; with `tie` 1, P(X ≤ y).
static func lows(xs: Array, px: Array, tie: int) -> Array:
	var out: Array = []
	for y in xs:
		var g := Q.new(0)
		for i in xs.size():
			if xs[i] < y + tie:
				g = g.add(px[i])
		out.append(g)
	return out


## cq q + cr r = P, and with r = 1 − (n − 1)q, coef q + cr = P.
static func _win_line(gs: Array, n: int) -> Dictionary:
	var cq := Q.new(0)
	for i in n - 1:
		cq = cq.add(gs[i])
	var cr: Q = gs[n - 1]
	return {"cq": cq, "cr": cr, "coef": cq.sub(cr.mul(Q.new(n - 1)))}


## The q that the same P gives if the ties are counted in, or null if no die has it.
static func _tie_q(s: Dictionary, n: int) -> Variant:
	var line := _win_line(lows(s.xs, s.px, 1), n)
	if line.coef.is_zero():
		return null
	var q: Q = s.pa.sub(line.cr).div(line.coef)
	if q.sign() <= 0 or Q.new(1).sub(q.mul(Q.new(n - 1))).sign() <= 0:
		return null
	return q


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
