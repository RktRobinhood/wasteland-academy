class_name ArithmeticContextSituation
extends RefCounted
## The `arithmetic-context` situation (curriculum/question-types.json): an arithmetic sequence
## or series in a story, for t1-arithmetic-in-context. Every question is Paper 2, as every part
## of the type in the bank is. It extends ArithmeticSequenceSituation: `term` and `sum` do the
## sums, on whichever u₁ and d the story draws. The SymPy checker reads the story back from the
## text and holds its own copy of the limits.
##
## need.ask is the unknown, and it picks the story list:
##   STORIES  term-in-context, total-in-context, term-or-total, in-or-after, term-number,
##            zero-term, first-past, first-total-past, whole-n-test
##   STOCKS   value-after: an amount at the start, changed by the same amount each step
##   BANK     simple-interest: the same, with the step worked out from a rate
##   LINES    count-terms: first, last and gap
##   NET      peak-total: terms that fall past 0, so that the running total has a peak
##   DATA     estimate-d, fit-gradient, predict-from-gaps, predict-from-line, comment-validity:
##            a table that is nearly arithmetic
##   PILES    stack-total, stack-crates: a stack of rows, so that the count is a sum
##
## generate() returns a Dictionary:
##   paper, ask, rep, case, list (which list the story comes from), ctx (an index into it)
##   u1, d, n            the sequence and the term or number of terms asked about
##   v                   the value asked for, or a target value given
##   k                   the term number that is the answer, where n is asked
##   real                the n, not yet whole, where a target is met
##   X                   a target for a term or a running total
##   rate, I             simple interest: the rate in %, and the interest a year
##   gap, last           count-terms: the gap (d) and the last value
##   xs, ys, m           data: n = 1 to m
##   avg, d1             data: (last − first) ÷ gaps, and the first difference alone
##   a, b, r             data: the regression line, as RegressionSituation.stats gives it
##   N, pa, pl           data: the n of a prediction, from avg and from the line
##   cap                 comment-validity, case "capped": the story's limit (0 if it falls)
##   c, rowk             stack-crates: the crate size, and the first row that is a multiple of it
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its own copy.

const TRIES := 8000
const N_TERM := [8, 40]
const N_SUM := [6, 30]
## A target's n keeps EDGE from a whole number, so "first more than" is not a matter of rounding.
const EDGE := 0.1
const ROUNDS := [1000, 500, 100, 50, 10, 5, 1]
const CRATES := [10, 12, 15, 16, 20, 24, 25, 30]

## den: u1 and d are in units of 1/den. time: a story told in steps of time.
const STORIES := [
	{"step": "row", "on": "in", "unit": "seats", "sign": 1, "den": 1, "u1": [20, 60, 2], "d": [2, 3, 4, 5, 6], "time": false,
		"open": "The fight pit at the Bazaar has curved rows of seats. Row 1 has %s seats, and each row after it has %s more seats than the row before.",
		"show": "the number of seats in the first rows of the fight pit", "heads": ["Row", "Seats"],
		"term": "the number of seats in row %d", "sum": "the total number of seats in the first %d rows",
		"find": "Which row has %s seats?", "past": "Find the first row with more than %s seats.",
		"total": "Find the smallest number of rows that together hold more than %s seats.", "can": "Can a row have exactly %s seats?"},
	{"step": "year", "on": "in", "unit": "tokens", "sign": 1, "den": 1, "u1": [9000, 20000, 500], "d": [150, 200, 250, 300, 400, 500, 750], "time": true,
		"open": "The Scrap Guild pays a new scout %s tokens in year 1, and the pay goes up by %s tokens each year after that.",
		"show": "a scout's pay in the first years with the Scrap Guild", "heads": ["Year", "Pay"], "what": "scout's pay",
		"term": "the scout's pay in year %d", "sum": "the total pay over the first %d years",
		"find": "In which year is the pay %s tokens?", "past": "Find the first year in which the pay is more than %s tokens.",
		"total": "Find the first year by the end of which the total pay is more than %s tokens.", "can": "Can the pay in some year be exactly %s tokens?"},
	{"step": "week", "on": "in", "unit": "km", "sign": 1, "den": 10, "u1": [30, 70, 5], "d": [2, 3, 4, 5, 6, 8], "time": true,
		"open": "A courier's long run is %s km in week 1, and it is %s km longer each week after that.",
		"show": "the length of a courier's long run in the first weeks", "heads": ["Week", "km"], "what": "length of the long run",
		"term": "the length of the long run in week %d", "sum": "the total length of the long runs over the first %d weeks",
		"find": "In which week is the long run %s km?", "past": "Find the first week in which the long run is more than %s km.",
		"total": "Find the first week by the end of which the long runs total more than %s km.", "can": "Can the long run in some week be exactly %s km?"},
	{"step": "day", "on": "on", "unit": "kg", "sign": 1, "den": 2, "u1": [60, 180, 5], "d": [5, 7, 9, 15], "time": true,
		"open": "A salvage crew hauls %s kg of scrap on day 1, and %s kg more each day after that.",
		"show": "the scrap a salvage crew hauls on the first days", "heads": ["Day", "kg"], "what": "day's haul",
		"term": "the day's haul on day %d", "sum": "the total scrap hauled over the first %d days",
		"find": "On which day is the haul %s kg?", "past": "Find the first day on which the haul is more than %s kg.",
		"total": "Find the first day by the end of which the total haul is more than %s kg.", "can": "Can the haul on some day be exactly %s kg?"},
	{"step": "day", "on": "on", "unit": "litres", "sign": -1, "den": 1, "u1": [300, 640, 10], "d": [5, 6, 8, 10, 12, 15, 20], "time": true,
		"open": "A failing well gives %s litres on day 1, and %s litres less each day after that.",
		"show": "the water a failing well gives on the first days", "heads": ["Day", "Litres"], "what": "water the well gives",
		"term": "the water the well gives on day %d", "sum": "the total water from the well over the first %d days",
		"find": "On which day does the well give %s litres?", "past": "Find the first day on which the well gives less than %s litres.",
		"can": "Can the well give exactly %s litres on some day?", "zero": "On which day does the flow of the well reach 0 litres?"},
	{"step": "layer", "on": "in", "unit": "sandbags", "sign": -1, "den": 1, "u1": [60, 120, 2], "d": [2, 3, 4, 5], "time": false,
		"open": "Layer 1, the bottom layer of a barricade, has %s sandbags, and each layer above it has %s fewer sandbags than the layer below.",
		"show": "the sandbags in the first layers of a barricade, counted from the bottom", "heads": ["Layer", "Bags"],
		"term": "the number of sandbags in layer %d", "sum": "the total number of sandbags in the first %d layers",
		"find": "Which layer has %s sandbags?", "past": "Find the first layer with fewer than %s sandbags.",
		"can": "Can a layer have exactly %s sandbags?", "zero": "Which layer would have 0 sandbags, so that the barricade stops below it?"},
	{"step": "day", "on": "on", "unit": "km", "sign": -1, "den": 2, "u1": [240, 400, 10], "d": [3, 5, 7, 9, 12], "time": true,
		"open": "A convoy on worn tyres drives %s km on day 1, and %s km less each day after that.",
		"show": "the distance a convoy on worn tyres drives on the first days", "heads": ["Day", "km"], "what": "distance the convoy drives",
		"term": "the distance the convoy drives on day %d", "sum": "the total distance driven over the first %d days",
		"find": "On which day does the convoy drive %s km?", "past": "Find the first day on which the convoy drives less than %s km.",
		"can": "Can the convoy drive exactly %s km on some day?", "zero": "On which day does the convoy's distance for the day reach 0 km?"},
	{"step": "month", "on": "in", "unit": "kWh", "sign": -1, "den": 1, "u1": [200, 500, 10], "d": [4, 5, 6, 8, 10, 12, 15], "time": true,
		"open": "An old solar bank stores %s kWh in month 1, and %s kWh less each month after that.",
		"show": "the energy an old solar bank stores in the first months", "heads": ["Month", "kWh"], "what": "energy the bank stores",
		"term": "the energy the bank stores in month %d", "sum": "the total energy stored over the first %d months",
		"find": "In which month does the bank store %s kWh?", "past": "Find the first month in which the bank stores less than %s kWh.",
		"can": "Can the bank store exactly %s kWh in some month?", "zero": "In which month does the energy the bank stores reach 0 kWh?"},
]
const RISING := [0, 1, 2, 3]
const FALLING := [4, 5, 6, 7]
const TIMED := [1, 2, 3, 4, 6, 7]

const STOCKS := [
	{"step": "year", "unit": "cm", "sign": 1, "start": [40, 200, 10], "d": [12, 15, 18, 24, 30], "what": "height of the tree", "heads": ["Years passed", "Height"],
		"open": "A shade tree is %s cm tall when it is planted, and it grows %s cm each year.", "show": "the height of a newly planted shade tree"},
	{"step": "hour", "unit": "litres", "sign": 1, "start": [100, 600, 20], "d": [15, 25, 35, 40, 45], "what": "water in the tank", "heads": ["Hours passed", "Litres"],
		"open": "A tank holds %s litres when the pump starts, and the pump adds %s litres each hour.", "show": "the water in a tank once the pump starts"},
	{"step": "month", "unit": "tokens", "sign": -1, "start": [2000, 6000, 100], "d": [40, 60, 75, 90, 120], "what": "debt still owed", "heads": ["Months passed", "Tokens"],
		"open": "A scout owes the Bazaar %s tokens, and repays %s tokens each month.", "show": "the debt a scout still owes the Bazaar"},
	{"step": "week", "unit": "m", "sign": 1, "start": [20, 90, 5], "d": [3, 4, 6, 7, 9], "what": "depth of the shaft", "heads": ["Weeks passed", "Depth"],
		"open": "A mine shaft is %s m deep, and the crew digs it %s m deeper each week.", "show": "the depth of a mine shaft as the crew digs"},
	{"step": "week", "unit": "litres", "sign": -1, "start": [3000, 8000, 100], "d": [55, 70, 85, 110, 130], "what": "fuel in the depot", "heads": ["Weeks passed", "Litres"],
		"open": "A depot holds %s litres of fuel when winter starts, and it uses %s litres each week.", "show": "the fuel in a depot once winter starts"},
]

## Rates in steps of 0.5%.
const BANK := {"p": [400, 5000, 100], "rate": [4, 18]}

const LINES := [
	{"unit": "m", "thing": "marker posts", "one": "post", "head": "Post", "first": [5, 60], "gap": [4, 6, 8, 12, 15, 20],
		"open": "Marker posts stand along a pipeline, %s m apart. The first is %s m from the pump and the last is %s m from the pump.", "show": "where the first marker posts stand along a pipeline, in metres from the pump", "end": "The last post is %s m from the pump."},
	{"unit": "m", "thing": "lamps", "one": "lamp", "head": "Lamp", "first": [10, 80], "gap": [6, 7, 9, 11, 14, 25],
		"open": "Lamps hang along a tunnel, %s m apart. The first is %s m from the gate and the last is %s m from the gate.", "show": "where the first lamps hang along a tunnel, in metres from the gate", "end": "The last lamp is %s m from the gate."},
	{"unit": "cm", "thing": "rungs", "one": "rung", "head": "Rung", "first": [20, 45], "gap": [24, 25, 28, 30, 32],
		"open": "The rungs of a lookout's ladder are %s cm apart. The lowest is %s cm above the ground and the highest is %s cm above the ground.", "show": "the height of the lowest rungs of a lookout's ladder, in cm", "end": "The highest rung is %s cm above the ground."},
]

## Terms that fall past 0: a negative term takes away from the running total.
const NET := [
	{"step": "week", "unit": "litres", "den": 1, "u1": [60, 200, 10], "d": [4, 6, 7, 8, 9, 12], "heads": ["Week", "Litres gained"],
		"open": "An empty tank gains %s litres in week 1. Each week the gain is %s litres less than the week before, and once it is negative the tank is losing water.",
		"show": "what an empty tank gains in the first weeks, where a negative gain is a loss", "ask": "Find the greatest amount of water the tank holds."},
	{"step": "month", "unit": "tokens", "den": 1, "u1": [400, 1500, 50], "d": [40, 60, 70, 80, 90, 110], "heads": ["Month", "Profit"],
		"open": "A new trading post makes %s tokens of profit in month 1. Each month the profit is %s tokens less than the month before, and once it is negative the post is making a loss.",
		"show": "a new trading post's profit in the first months, where a negative profit is a loss", "ask": "Find the greatest total profit the post ever has."},
	{"step": "minute", "unit": "m", "den": 2, "u1": [80, 240, 10], "d": [5, 7, 9, 11, 15], "heads": ["Minute", "Metres climbed"],
		"open": "A survey drone climbs %s m in minute 1 from the ground. Each minute it climbs %s m less than the minute before, and once the climb is negative it is coming down.",
		"show": "how far a survey drone climbs from the ground in the first minutes, where a negative climb is a descent", "ask": "Find the greatest height the drone reaches."},
]

## cap: the limit a rising story states. y1 and d are the numbers behind the table.
const DATA := [
	{"step": "year", "unit": "caravans", "sign": 1, "y1": [40, 90], "d": [6, 14], "head": "Caravans", "what": "number of caravans",
		"open": "A gatekeeper counts the caravans through the Bazaar gate each year.", "cap": "The gate can pass at most %d caravans in a year."},
	{"step": "year", "unit": "cm", "sign": 1, "y1": [60, 110], "d": [7, 15], "head": "Height", "what": "height of the tree",
		"open": "A scout measures a shade tree at the end of each year, in cm.", "cap": "Trees of this kind stop growing at about %d cm."},
	{"step": "year", "unit": "settlers", "sign": 1, "y1": [70, 130], "d": [8, 16], "head": "Settlers", "what": "number of settlers",
		"open": "A clerk records the settlers at Last Well each year.", "cap": "The well can support at most %d settlers."},
	{"step": "year", "unit": "megalitres", "sign": -1, "y1": [170, 240], "d": [11, 20], "head": "Megalitres", "what": "water left",
		"open": "A warden records the water left in a reservoir at the end of each year, in megalitres.", "cap": ""},
	{"step": "year", "unit": "kWh", "sign": -1, "y1": [160, 220], "d": [10, 18], "head": "kWh", "what": "charge held",
		"open": "A mechanic records the charge a battery pack holds after each year of use, in kWh.", "cap": ""},
]
const DATA_RISING := [0, 1, 2]

const PILES := [
	{"thing": "fuel drums", "one": "drum", "open": "Fuel drums are stacked in rows. A stack with 1 row has %s drums. Each extra row goes under the stack and has %s more drums than the row above it.", "crate": "Drums come on full pallets of %d.", "pack": "pallets"},
	{"thing": "sandbags", "one": "sandbag", "open": "Sandbags are piled in rows. A pile with 1 row has %s sandbags. Each extra row goes under the pile and has %s more sandbags than the row above it.", "crate": "Sandbags come in full crates of %d.", "pack": "crates"},
	{"thing": "scrap beams", "one": "beam", "open": "Scrap beams are stacked in rows. A stack with 1 row has %s beams. Each extra row goes under the stack and has %s more beams than the row above it.", "crate": "Beams come in full bundles of %d.", "pack": "bundles"},
]


static func term(s: Dictionary, k: Variant) -> Q:
	return ArithmeticSequenceSituation.term(s, k)


static func total(s: Dictionary, k: Variant) -> Q:
	return ArithmeticSequenceSituation.sum(s, k)


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "term-in-context")
	var rep: String = need.get("rep", "words")
	# Picked once, so that an easy case gets no more than its share of the draws.
	var which: String = rng.pick(_cases(ask))
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "rep": rep, "case": which, "n": 0}
		if _draw(rng, s):
			return s
	push_error("ArithmeticContextSituation: no clean situation for %s" % ask)
	return {}


static func _cases(ask: String) -> Array:
	match ask:
		"term-or-total":
			return ["term", "total"]
		"in-or-after":
			return ["in", "after"]
		"whole-n-test":
			return ["yes", "no"]
		"comment-validity":
			return ["near", "far", "capped"]
	return ["any"]


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"term-in-context":
			return _story(rng, s, range(8)) and _at(rng, s, N_TERM)
		"total-in-context":
			return _story(rng, s, range(8)) and _at(rng, s, N_SUM)
		"term-or-total":
			return _story(rng, s, range(8)) and _at(rng, s, N_SUM)
		"in-or-after":
			return _story(rng, s, TIMED) and _at(rng, s, N_SUM)
		"term-number":
			return _story(rng, s, range(8)) and _find(rng, s)
		"zero-term":
			return _story(rng, s, FALLING) and _zero(rng, s)
		"first-past":
			return _story(rng, s, range(8)) and _past(rng, s)
		"first-total-past":
			return _story(rng, s, RISING) and _total_past(rng, s)
		"whole-n-test":
			return _story(rng, s, range(8)) and _whole(rng, s)
		"value-after":
			return _stock(rng, s)
		"simple-interest":
			return _bank(rng, s)
		"count-terms":
			return _line(rng, s)
		"peak-total":
			return _net(rng, s)
		"estimate-d", "fit-gradient":
			return _data(rng, s) and _gradients(s)
		"predict-from-gaps", "predict-from-line":
			return _data(rng, s) and _predict(rng, s)
		"comment-validity":
			return _data(rng, s) and _validity(rng, s)
		"stack-total":
			return _pile(rng, s) and _stack_total(rng, s)
		"stack-crates":
			return _pile(rng, s) and _crates(rng, s)
	return false


static func _range_pick(rng: Seeded, r: Array) -> int:
	return r[0] + r[2] * rng.int_in(0, (r[1] - r[0]) / r[2])


static func _story(rng: Seeded, s: Dictionary, pool: Variant) -> bool:
	s.list = "stories"
	s.ctx = rng.pick(Array(pool))
	var c: Dictionary = STORIES[s.ctx]
	s.u1 = Q.new(_range_pick(rng, c.u1), c.den)
	s.d = Q.new(c.sign * rng.pick(c.d), c.den)
	return true


## A term number in the range, with the story still positive one term past it.
static func _at(rng: Seeded, s: Dictionary, lim: Array) -> bool:
	s.n = rng.int_in(lim[0], lim[1])
	s.v = term(s, s.n)
	return term(s, s.n + 1).sign() > 0


static func _find(rng: Seeded, s: Dictionary) -> bool:
	s.k = rng.int_in(N_TERM[0], N_TERM[1])
	s.v = term(s, s.k)
	return s.v.sign() > 0


## u₁ is a whole number of steps from 0, so the term that reaches 0 is a whole n.
static func _zero(rng: Seeded, s: Dictionary) -> bool:
	var c: Dictionary = STORIES[s.ctx]
	s.k = rng.int_in(N_TERM[0], N_TERM[1])
	s.u1 = s.d.abs_q().mul(s.k - 1)
	s.v = Q.new(0)
	return s.u1.mul(c.den).is_int() and s.u1.to_float() >= c.u1[0] / float(c.den) and s.u1.to_float() <= c.u1[1] / float(c.den)


## A round number strictly between two neighbouring terms or totals, or null.
static func _round_between(a: Q, b: Q) -> Variant:
	var lo: Q = a if a.lt(b) else b
	var hi: Q = b if a.lt(b) else a
	for r in ROUNDS:
		var x := Q.new(int(floorf(hi.to_float() / r)) * r)
		if x.eq(hi):
			x = x.sub(r)
		if lo.lt(x) and x.lt(hi):
			return x
	return null


static func _clear_of_whole(x: float) -> bool:
	return absf(x - roundf(x)) >= EDGE


static func _past(rng: Seeded, s: Dictionary) -> bool:
	s.k = rng.int_in(N_TERM[0], N_TERM[1])
	var before := term(s, s.k - 1)
	var at := term(s, s.k)
	if at.sign() <= 0:
		return false
	var x: Variant = _round_between(before, at)
	if x == null or not x.sign() > 0:
		return false
	s.X = x
	s.v = at
	s.real = Q.new(1).add(x.sub(s.u1).div(s.d))
	return _clear_of_whole(s.real.to_float())


static func _total_past(rng: Seeded, s: Dictionary) -> bool:
	s.k = rng.int_in(N_SUM[0], N_SUM[1])
	var x: Variant = _round_between(total(s, s.k - 1), total(s, s.k))
	if x == null:
		return false
	s.X = x
	s.v = total(s, s.k)
	s.real = GdcKit.qf(ArithmeticSequenceSituation.sum_root(s, x))
	return _clear_of_whole(s.real.to_float())


## Does this decimal end within two places?
static func _ends(v: Q) -> bool:
	return v.mul(100).is_int()


## u₁ is not a multiple of d, so that "a multiple of d" is a false test both ways. "yes": the
## value is a term. "no": it is a multiple of d and no term, and n is a decimal that ends.
static func _whole(rng: Seeded, s: Dictionary) -> bool:
	var step: Q = s.d.abs_q()
	if s.u1.div(step).is_int():
		return false
	s.k = rng.int_in(N_TERM[0], N_TERM[1])
	var t := term(s, s.k)
	if t.sign() <= 0:
		return false
	if s.case == "yes":
		s.v = t
		s.real = Q.new(s.k)
		return true
	var v: Q = step.mul(int(floorf(t.div(step).to_float())))
	s.v = v
	s.real = Q.new(1).add(v.sub(s.u1).div(s.d))
	s.k = int(floorf(s.real.to_float()))
	return v.sign() > 0 and _ends(s.real) and s.k >= N_TERM[0] and _clear_of_whole(s.real.to_float())


static func _stock(rng: Seeded, s: Dictionary) -> bool:
	s.list = "stocks"
	s.ctx = rng.int_in(0, STOCKS.size() - 1)
	var c: Dictionary = STOCKS[s.ctx]
	s.u1 = Q.new(_range_pick(rng, c.start))
	s.d = Q.new(c.sign * rng.pick(c.d))
	s.n = rng.int_in(N_SUM[0], N_SUM[1])
	s.v = s.u1.add(s.d.mul(s.n))
	return s.v.sign() > 0 and term(s, s.n + 2).sign() > 0


static func _bank(rng: Seeded, s: Dictionary) -> bool:
	s.list = "bank"
	s.ctx = 0
	s.u1 = Q.new(_range_pick(rng, [BANK.p[0], BANK.p[1], BANK.p[2]]))
	s.rate = Q.new(rng.int_in(BANK.rate[0], BANK.rate[1]), 2)
	s.I = s.u1.mul(s.rate).div(100)
	s.d = s.I
	s.n = rng.int_in(N_SUM[0], 20)
	s.v = s.u1.add(s.I.mul(s.n))
	return _ends(s.I)


static func _line(rng: Seeded, s: Dictionary) -> bool:
	s.list = "lines"
	s.ctx = rng.int_in(0, LINES.size() - 1)
	var c: Dictionary = LINES[s.ctx]
	s.gap = rng.pick(c.gap)
	s.u1 = Q.new(rng.int_in(c.first[0], c.first[1]))
	s.d = Q.new(s.gap)
	s.k = rng.int_in(N_TERM[0], N_TERM[1])
	s.last = term(s, s.k)
	return s.u1.div(s.d).is_int() == false


static func _net(rng: Seeded, s: Dictionary) -> bool:
	s.list = "net"
	s.ctx = rng.int_in(0, NET.size() - 1)
	var c: Dictionary = NET[s.ctx]
	s.u1 = Q.new(_range_pick(rng, c.u1), c.den)
	s.d = Q.new(-rng.pick(c.d), c.den)
	# The last term above 0.
	var k := int(ceilf(1.0 - s.u1.div(s.d).to_float())) - 1
	while term(s, k + 1).sign() > 0:
		k += 1
	while term(s, k).sign() <= 0:
		k -= 1
	s.k = k
	s.v = total(s, k)
	return k >= N_SUM[0] and k <= N_TERM[1]


## A table of m years that is nearly arithmetic: no two changes need agree, but all have the
## story's sign. The line comes from RegressionSituation's sums.
static func _data(rng: Seeded, s: Dictionary) -> bool:
	s.list = "data"
	s.ctx = rng.int_in(0, DATA.size() - 1) if s.get("case", "") != "far" else rng.pick(DATA_RISING)
	var c: Dictionary = DATA[s.ctx]
	var m := rng.int_in(5, 8)
	var step := rng.int_in(c.d[0], c.d[1])
	var y1 := rng.int_in(c.y1[0], c.y1[1])
	var noise := maxi(1, step / 3)
	var ys: Array = []
	for i in m:
		ys.append(y1 + c.sign * step * i + (rng.int_in(-noise, noise) if i > 0 else 0))
	var xs: Array = range(1, m + 1)
	var same := true
	for i in range(1, m):
		var ch: int = ys[i] - ys[i - 1]
		if ch * c.sign <= 0:
			return false
		same = same and ch == ys[1] - ys[0]
	if same or ys.min() < 5:
		return false
	s.m = m
	s.n = m
	s.xs = xs
	s.ys = ys
	RegressionSituation.stats(s)
	s.avg = Q.new(ys[m - 1] - ys[0], m - 1)
	s.d1 = Q.new(ys[1] - ys[0])
	return RegressionSituation.clear(s.avg) and RegressionSituation.clear(s.a)


## Every value on a list reads differently to 3 s.f., and none is on a rounding edge.
static func _apart(vs: Array) -> bool:
	var seen := {}
	for v in vs:
		var t := Fmt.sf(v)
		if seen.has(t) or not RegressionSituation.clear(v):
			return false
		seen[t] = true
	return true


static func _gradients(s: Dictionary) -> bool:
	var whole := Q.new(s.ys[s.m - 1] - s.ys[0], s.m)
	return _apart([s.avg, s.a, s.d1, whole, s.avg.neg(), s.a.neg(), s.b])


static func _from_gaps(s: Dictionary, x: int) -> Q:
	return Q.new(s.ys[0]).add(s.avg.mul(x - 1))


static func _from_line(s: Dictionary, x: int) -> Q:
	return s.a.mul(x).add(s.b)


static func _predict(rng: Seeded, s: Dictionary) -> bool:
	var m: int = s.m
	s.N = m + rng.int_in(2, 6)
	s.pa = _from_gaps(s, s.N)
	s.pl = _from_line(s, s.N)
	var one := Q.new(s.ys[0]).add(s.d1.mul(s.N - 1))
	var from_last := Q.new(s.ys[m - 1]).add(s.avg.mul(s.N))
	# A falling table can run out: a prediction, or a slip on it, stays a possible amount.
	var amounts: Array = [s.pa, s.pl, s.pa.add(s.avg), from_last, one, s.pl.add(s.a)]
	return amounts.all(func(v): return v.sign() > 0) and _apart(amounts + [s.a.mul(s.N), s.pl.sub(s.a)])


## near: a year or two past the table. far: at least three spans past it, on a rising story, as
## a falling one runs out. capped: the story's limit, which both predictions are past.
static func _validity(rng: Seeded, s: Dictionary) -> bool:
	var c: Dictionary = DATA[s.ctx]
	var m: int = s.m
	s.cap = 0
	match s.case:
		"near":
			s.N = m + rng.int_in(1, 2)
		"far":
			s.N = m * 4 + rng.int_in(0, 6)
		"capped":
			if c.sign > 0:
				s.N = m + rng.int_in(3, 6)
			else:
				var ends := int(ceilf(-s.b.to_float() / s.a.to_float()))
				s.N = ends + rng.int_in(2, 5)
	s.pa = _from_gaps(s, s.N)
	s.pl = _from_line(s, s.N)
	if not _apart([s.pa, s.pl]):
		return false
	if s.case == "capped":
		if c.sign > 0:
			var low := minf(s.pa.to_float(), s.pl.to_float())
			var top: int = s.ys[m - 1]
			s.cap = roundi((top + low) / 20.0) * 10
			return s.cap > top and s.cap < low
		return s.pa.sign() < 0 and s.pl.sign() < 0
	return s.pa.sign() > 0 and s.pl.sign() > 0


static func _pile(rng: Seeded, s: Dictionary) -> bool:
	s.list = "piles"
	s.ctx = rng.int_in(0, PILES.size() - 1)
	s.u1 = Q.new(rng.int_in(2, 5))
	s.d = Q.new(rng.int_in(1, 3))
	return true


static func _stack_total(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.int_in(4, 12)
	s.v = total(s, s.n)
	return true


## The fewest rows, of at least 3, that use whole crates exactly.
static func _crates(rng: Seeded, s: Dictionary) -> bool:
	s.c = rng.pick(CRATES)
	s.k = 0
	for k in range(3, N_TERM[1] + 1):
		if total(s, k).n % s.c == 0:
			s.k = k
			break
	if s.k == 0 or total(s, 1).n % s.c == 0 or total(s, 2).n % s.c == 0:
		return false
	s.rowk = 0
	for k in range(1, N_TERM[1] + 1):
		if term(s, k).n % s.c == 0:
			s.rowk = k
			break
	s.v = total(s, s.k)
	return true


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
