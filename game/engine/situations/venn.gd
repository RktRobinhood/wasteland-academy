class_name VennSituation
extends RefCounted
## The `venn` situation (curriculum/question-types.json): two events in one sample space
## (FAL-725). Four whole numbers, the regions a (A only), i (both), b (B only) and o (neither),
## out of u, are everything: each probability is an exact Q. `style` says how they are shown:
##   dec    probabilities as decimals: u is 20, 50 or 100 on Paper 1, 1000 on Paper 2
##   frac   probabilities as fractions: Paper 1 only
##   count  numbers of people in a story, a diagram or a table
## Paper 1 answers are exact. Paper 2 counts are answered to 3 s.f. where they need rounding.
## ConditionalSituation draws its events here too.
##
## need.ask is the unknown (see VennViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx (an index into VennViews.CONTEXTS), style
##   a, i, b, o, u   the regions and the total, ints
##   pa, pb          the two probabilities for least-overlap and greatest-overlap, Q
##   x, ma, ca, mi, ci, mb, cb  x-from-total: each region is m x + c, with o the outside
##   cell            table-missing-entry: which entry is asked: "a", "b", "o", "na'" or "nb'"
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 4000
const EDGE := 0.03
const CONTEXTS := 8
const FRAC_U := [12, 15, 16, 18, 20, 24, 30, 36, 40]
const DEC_U := [20, 50, 100]
## P(A) + P(B) stays below 1 where adding them is a wrong option.
const SMALL := ["union-from-rule", "neither-from-rule", "union-from-regions", "union-from-table"]
const CELLS := ["a", "b", "o", "na'", "nb'"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "union-from-rule")
	var rep: String = need.get("rep", "equation")
	var paper: int = int(need.get("paper", 1))
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "ctx": rng.int_in(0, CONTEXTS - 1)}
		var ok := false
		match ask:
			"least-overlap", "greatest-overlap":
				ok = _overlap(rng, s)
			"x-from-total":
				ok = _x_total(rng, s)
			_:
				s.style = style(rng, rep, paper)
				ok = regions(rng, s, ask in SMALL) and _ask_clear(rng, s)
		if ok:
			return s
	return {}


## How a question on this paper and representation shows its numbers.
static func style(rng: Seeded, rep: String, paper: int) -> String:
	if rep in ["words", "table"]:
		return "count"
	if rep == "diagram":
		return "dec" if rng.chance(0.4) else "count"
	return "dec" if paper == 2 or rng.chance(0.6) else "frac"


## The total for a style and paper.
static func total(rng: Seeded, s: Dictionary) -> int:
	match s.style:
		"dec":
			return 1000 if s.paper == 2 else int(rng.pick(DEC_U))
		"frac":
			return int(rng.pick(FRAC_U))
	return rng.int_in(60, 300) if s.paper == 2 else rng.int_in(12, 40)


## Draws the four regions. `small` keeps P(A) + P(B) below 1.
static func regions(rng: Seeded, s: Dictionary, small: bool) -> bool:
	var u := total(rng, s)
	var i := rng.int_in(1, maxi(1, u / 4))
	var o := rng.int_in(1, maxi(1, u / 3))
	var rest := u - i - o
	if rest < 2:
		return false
	var a := rng.int_in(1, rest - 1)
	s.u = u
	s.a = a
	s.i = i
	s.b = rest - a
	s.o = o
	return not small or o > i


## A probability out of u, for the checks below.
static func p(s: Dictionary, n: int) -> Q:
	return Q.new(n, s.u)


## An answer is on a rounding edge only where it will be shown to 3 s.f.
static func fits(s: Dictionary, v: Q) -> bool:
	return s.style != "count" or s.paper == 1 or not Answer.needs_rounding(v) or Answer.rounds_clearly(v.to_float(), EDGE)


static func _ask_clear(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"table-missing-entry":
			s.cell = rng.pick(CELLS)
		"union-from-rule", "union-from-regions", "union-from-table":
			return fits(s, p(s, s.a + s.i + s.b)) and fits(s, p(s, s.a + s.b)) and fits(s, p(s, s.a + s.b + 2 * s.i))
		"intersection-from-rule":
			return fits(s, p(s, s.i))
		"neither-from-rule":
			return fits(s, p(s, s.o)) and fits(s, p(s, s.o - s.i)) and fits(s, p(s, s.a + s.b + s.i))
		"one-event-only":
			return fits(s, p(s, s.a)) and fits(s, p(s, s.a + s.i)) and fits(s, p(s, s.o))
		"exactly-one":
			return fits(s, p(s, s.a + s.b)) and fits(s, p(s, s.a + s.b + s.i))
	return true


## Two probabilities that must overlap, in steps of 0.05 on Paper 1 and 0.01 on Paper 2.
static func _overlap(rng: Seeded, s: Dictionary) -> bool:
	s.style = "dec"
	var step := 5 if s.paper == 1 else 1
	s.pa = Q.new(rng.int_in(6, 18) * 5 if s.paper == 1 else rng.int_in(30, 90), 100)
	s.pb = Q.new(rng.int_in(6, 18) * step if s.paper == 1 else rng.int_in(30, 90), 100)
	var sum: Q = s.pa.add(s.pb)
	return Q.new(1).lt(sum) and sum.lt(Q.new(19, 10)) and not s.pa.eq(s.pb)


## Each region of the diagram is m x + c, and they add to u.
static func _x_total(rng: Seeded, s: Dictionary) -> bool:
	s.style = "count"
	s.x = rng.int_in(2, 12) if s.paper == 1 else rng.int_in(6, 25)
	s.ma = rng.int_in(1, 3)
	s.ca = rng.int_in(0, 6)
	s.mi = 1
	s.ci = rng.int_in(0, 4)
	s.mb = rng.int_in(1, 3)
	s.cb = -rng.int_in(1, mini(4, s.x * s.mb - 1)) if rng.chance(0.4) else rng.int_in(0, 6)
	s.o = rng.int_in(2, 12)
	s.a = s.ma * s.x + s.ca
	s.i = s.mi * s.x + s.ci
	s.b = s.mb * s.x + s.cb
	s.u = s.a + s.i + s.b + s.o
	# Forgetting the outside must still give a whole number, or the option gives itself away.
	return s.b >= 1 and s.o % (s.ma + s.mi + s.mb) == 0


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
