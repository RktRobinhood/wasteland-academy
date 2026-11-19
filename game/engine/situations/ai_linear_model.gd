class_name AiLinearModelSituation
extends RefCounted
## The `ai-linear-model` situation (curriculum/question-types.json), FAL-1001: a linear model of a
## charge (a fixed charge plus a rate per unit), a tariff in two pieces that meet at a change point,
## a tiered price whose band rate applies to the whole order, and two bills on one linear tariff,
## for fn-ai-piecewise-linear (AI-SL2.5.linear-model, AI-SL2.6.find-parameters). Every AI paper
## allows a GDC, so every question is Paper 2.
##
## need.ask is the unknown and need.rep its representation (see AiLinearModelViews). generate()
## returns a Dictionary:
##   paper, ask, rep, kind, ctx   always 2; the unknown; the representation; "line", "piece" or
##                                "tier"; the context's index in LINES, PIECES or TIERS
##   kind "line" (build-from-rate-start, evaluate-model, interpret-gradient, two-bills):
##     m, c      the rate per unit and the fixed charge (Q, money)
##     x         the input asked (whole); y = m x + c
##     xg, yg    a second marked point on the graph (evaluate-model, graph)
##     part      interpret-gradient: "m" (the gradient) or "c" (the intercept) is asked about
##     x1, y1, x2, y2   two-bills: the two bills, x1 < x2
##   kind "piece" (piecewise-value, piecewise-rule, piecewise-input):
##     c, m1     the start and the first rate (m1 = 0 for a plan with an allowance)
##     x0, c0    the change point and the cost there, c0 = c + m1 x0
##     m2        the rate past x0, not m1
##     xe, ye    the graph's last marked point, on the second piece
##     x, y      the input and its cost (piecewise-value: either piece; piecewise-input: past x0)
##     x1, y1    piecewise-rule, words: a second point on the second piece, for two points
##   kind "tier" (tier-band):
##     edges     the lower edge of each band, the first 1; rates: each band's price per item
##     n, band   the order and the band it falls in (0-based, never the first)
##
## Money is in cents throughout: rates to 2 d.p. at most, fixed charges round. The numbers are
## drawn, not taken from any exam question. The SymPy checker (tools/check_answers.py, r3li_check)
## reads every value back from what the question shows and works it out again.

const TRIES := 2000

## A linear charge. x: the input's letter; one, many: its unit; fee: what c is called; none: a
## phrase for an input of 0; each: what one unit of the rate buys; story: %c and %m. rates and
## starts are in cents; every rate's reciprocal ends, so a bill with its input and cost swapped
## gives numbers that end too. lo, hi: the inputs asked; mark: the graph's second point; bills:
## the two bills' inputs come from these.
const LINES := [
	{"id": "van", "x": "d", "one": "day", "many": "days", "fee": "fixed fee", "none": "for a hire of 0 days",
		"story": "A van hire company charges a fixed fee of %c, plus %m for each day of hire.", "each": "day of hire",
		"rates": [3200, 4000, 5000, 6250], "starts": [4000, 6000, 7500, 9000], "lo": 2, "hi": 14, "mark": 10, "bills": [2, 3, 4, 5, 6, 8, 10, 12]},
	{"id": "plumber", "x": "h", "one": "hour", "many": "hours", "fee": "call-out fee", "none": "before any work is done",
		"story": "A plumber charges a call-out fee of %c, plus %m for each hour of work.", "each": "hour of work",
		"rates": [4000, 5000, 6250, 8000], "starts": [5000, 6000, 7500, 8000], "lo": 2, "hi": 9, "mark": 10, "bills": [2, 3, 4, 5, 6, 7, 8]},
	{"id": "taxi", "x": "d", "one": "km", "many": "km", "fee": "fixed charge", "none": "for a trip of 0 km",
		"story": "A taxi charges a fixed %c, plus %m for each km travelled.", "each": "km travelled",
		"rates": [160, 200, 250, 320], "starts": [350, 400, 450, 500], "lo": 3, "hi": 40, "mark": 20, "bills": [4, 6, 8, 12, 15, 18, 24, 30]},
	{"id": "power", "x": "E", "one": "kWh", "many": "kWh", "fee": "monthly charge", "none": "with no electricity used",
		"story": "An electricity supplier charges a fixed %c a month, plus %m for each kWh used.", "each": "kWh used",
		"rates": [16, 20, 25, 32], "starts": [1200, 1500, 1800, 2400], "lo": 120, "hi": 650, "mark": 500, "bills": [150, 200, 240, 300, 320, 400, 450, 500, 600]},
	{"id": "gym", "x": "n", "one": "class", "many": "classes", "fee": "joining fee", "none": "before any classes",
		"story": "A climbing gym charges a joining fee of %c, plus %m for each class.", "each": "class",
		"rates": [800, 1250, 1600, 2000], "starts": [2500, 3000, 4000, 5000], "lo": 4, "hi": 30, "mark": 20, "bills": [4, 5, 8, 10, 12, 15, 20, 24]},
	{"id": "print", "x": "p", "one": "poster", "many": "posters", "fee": "set-up charge", "none": "before any posters are printed",
		"story": "A print shop charges a set-up charge of %c, plus %m for each poster printed.", "each": "poster printed",
		"rates": [40, 50, 80, 125], "starts": [1500, 2000, 2500, 3000], "lo": 30, "hi": 300, "mark": 200, "bills": [40, 50, 60, 80, 100, 120, 150, 200, 250]},
]

## A tariff in two pieces. allow: true for a fixed charge that covers everything up to x0 (m1 = 0).
## Rates and charges in cents. lo, hi: how far past x0 an input may go (whole units).
const PIECES := [
	{"id": "data", "allow": true, "x": "g", "one": "GB", "many": "GB", "what": "the data used, in GB",
		"starts": [1500, 2000, 2500, 3000], "x0s": [2, 3, 4, 5, 8, 10], "m2s": [350, 400, 450, 600, 750], "hi": 12},
	{"id": "parking", "allow": true, "x": "t", "one": "hour", "many": "hours", "what": "the time parked, in hours",
		"starts": [600, 800, 1000, 1200], "x0s": [2, 3, 4], "m2s": [250, 300, 350, 450], "hi": 8},
	{"id": "courier", "allow": true, "x": "w", "one": "kg", "many": "kg", "what": "the mass of the parcel, in kg",
		"starts": [900, 1200, 1500], "x0s": [2, 5], "m2s": [150, 225, 280], "hi": 15},
	{"id": "water", "allow": false, "x": "w", "one": "m³", "many": "m³", "what": "the water used, in m³",
		"starts": [1800, 2000, 2500, 3000], "m1s": [120, 145, 160, 180], "x0s": [20, 25, 30, 40], "m2s": [210, 235, 260, 290], "hi": 30},
	{"id": "taxi", "allow": false, "x": "d", "one": "km", "many": "km", "what": "the distance, in km",
		"starts": [300, 400, 500], "m1s": [240, 280, 320], "x0s": [8, 10, 12, 15], "m2s": [150, 175, 190, 200], "hi": 25},
	{"id": "power", "allow": false, "x": "E", "one": "kWh", "many": "kWh", "what": "the electricity used, in kWh",
		"starts": [1000, 1200, 1500], "m1s": [16, 18, 20], "x0s": [100, 150, 200], "m2s": [24, 27, 30], "hi": 300},
]

## A price per item set by the band the order falls in. edges: each band's lower edge; rates in cents.
const TIERS := [
	{"id": "paint", "item": "tin", "items": "tins", "what": "tins of paint", "edges": [[1, 20, 50], [1, 10, 40], [1, 25, 60]],
		"rates": [[2450, 2200, 1975], [2600, 2350, 2100], [1990, 1800, 1650]]},
	{"id": "shirts", "item": "T-shirt", "items": "T-shirts", "what": "printed T-shirts", "edges": [[1, 30, 100], [1, 50, 150], [1, 25, 75]],
		"rates": [[1450, 1275, 1100], [1600, 1380, 1250], [1350, 1200, 1090]]},
	{"id": "tickets", "item": "ticket", "items": "tickets", "what": "tickets for a group", "edges": [[1, 10, 30], [1, 12, 40], [1, 15, 50]],
		"rates": [[4800, 4250, 3900], [3500, 3150, 2800], [5600, 5000, 4550]]},
	{"id": "bricks", "item": "pallet", "items": "pallets", "what": "pallets of bricks", "edges": [[1, 5, 12], [1, 6, 15], [1, 4, 10]],
		"rates": [[38500, 36000, 34250], [41000, 38800, 36500], [36000, 34400, 32900]]},
]


static func cents(v: int) -> Q:
	return Q.new(v, 100)


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "evaluate-model")
	var rep: String = need.get("rep", "")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "rep": rep}
		if _draw(rng, s):
			return s
	push_error("AiLinearModelSituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"build-from-rate-start", "evaluate-model", "interpret-gradient":
			return _line(rng, s)
		"two-bills":
			return _bills(rng, s)
		"piecewise-value", "piecewise-rule", "piecewise-input":
			return _piece(rng, s)
		"tier-band":
			return _tier(rng, s)
	return false


# ── A linear charge ──────────────────────────────────────────

static func _line(rng: Seeded, s: Dictionary) -> bool:
	s.kind = "line"
	s.ctx = rng.int_in(0, LINES.size() - 1)
	var c: Dictionary = LINES[s.ctx]
	s.m = cents(rng.pick(c.rates))
	s.c = cents(rng.pick(c.starts))
	s.x = rng.int_in(c.lo, c.hi)
	s.y = s.m.mul(s.x).add(s.c)
	s.xg = c.mark
	s.yg = s.m.mul(s.xg).add(s.c)
	s.part = "m" if rng.chance(0.5) else "c"
	if s.x == s.xg or s.m.eq(s.c):
		return false
	# The swap and the scaled fillers all differ from the answer.
	var swap: Q = s.c.mul(s.x).add(s.m)
	return not swap.eq(s.y)


static func _bills(rng: Seeded, s: Dictionary) -> bool:
	s.kind = "line"
	s.ctx = rng.int_in(0, LINES.size() - 1)
	var c: Dictionary = LINES[s.ctx]
	s.m = cents(rng.pick(c.rates))
	s.c = cents(rng.pick(c.starts))
	var xs: Array = rng.shuffled(c.bills).slice(0, 2)
	xs.sort()
	s.x1 = xs[0]
	s.x2 = xs[1]
	s.y1 = s.m.mul(s.x1).add(s.c)
	s.y2 = s.m.mul(s.x2).add(s.c)
	# The swapped bills' line, (1/m, −c/m), and the plain slips differ from (m, c) and each other.
	var sm: Q = Q.new(1).div(s.m)
	return not s.m.eq(s.c) and not sm.eq(s.m) and s.x2 - s.x1 >= 2


# ── A tariff in two pieces ───────────────────────────────────

static func _piece(rng: Seeded, s: Dictionary) -> bool:
	s.kind = "piece"
	s.ctx = rng.int_in(0, PIECES.size() - 1)
	var c: Dictionary = PIECES[s.ctx]
	s.c = cents(rng.pick(c.starts))
	s.m1 = Q.new(0) if c.allow else cents(rng.pick(c.m1s))
	s.x0 = int(rng.pick(c.x0s))
	s.m2 = cents(rng.pick(c.m2s))
	if s.m2.eq(s.m1):
		return false
	s.c0 = s.c.add(s.m1.mul(s.x0))
	var step: int = maxi(1, int(c.hi) / 6)
	s.xe = s.x0 + step * rng.int_in(4, 6)
	s.ye = at(s, s.xe)
	# The input: past x0 for a rule or an input from a cost; either side for a value.
	var first: bool = s.ask == "piecewise-value" and rng.chance(0.3)
	if first:
		s.x = rng.int_in(maxi(1, s.x0 / 5), s.x0 - 1)
	else:
		s.x = s.x0 + rng.int_in(1, s.xe - s.x0 - 1)
	if s.x <= 0:
		return false
	s.y = at(s, s.x)
	s.x1 = s.x0 + step * rng.int_in(1, 3)
	s.y1 = at(s, s.x1)
	match s.ask:
		"piecewise-value":
			# The second rate on the whole input, and the other piece's rule across the corner.
			var whole: Q = s.c.add(s.m2.mul(s.x))
			var other: Q = s.c.add(s.m1.mul(s.x)) if not first else s.c0.add(s.m2.mul(s.x - s.x0))
			return _apart([s.y, whole, other]) and other.sign() > 0
		"piecewise-input":
			# x from (y − c)/m2 and, with a first rate, (y − c)/m1: positive and not x.
			var a: Q = s.y.sub(s.c).div(s.m2)
			if a.eq(s.x):
				return false
			if not c.allow:
				var b: Q = s.y.sub(s.c).div(s.m1)
				if b.eq(s.x) or b.eq(a) or Fmt.sf(b) == Fmt.sf(a):
					return false
			return true
		"piecewise-rule":
			# b = c0 − m2 x0, and the slip's c: apart and b not 0.
			var b2: Q = s.c0.sub(s.m2.mul(s.x0))
			return not b2.is_zero() and not b2.eq(s.c) and s.x1 != s.xe
	return true


## The tariff's cost at x.
static func at(s: Dictionary, x: Variant) -> Q:
	var q := Q.of(x)
	if q.to_float() <= float(s.x0) + 1e-9:
		return s.c.add(s.m1.mul(q))
	return s.c0.add(s.m2.mul(q.sub(s.x0)))


static func _apart(vals: Array) -> bool:
	var seen := {}
	for v in vals:
		seen[Fmt.money(v)] = true
	return seen.size() == vals.size()


# ── A tiered price ───────────────────────────────────────────

static func _tier(rng: Seeded, s: Dictionary) -> bool:
	s.kind = "tier"
	s.ctx = rng.int_in(0, TIERS.size() - 1)
	var c: Dictionary = TIERS[s.ctx]
	var k := rng.int_in(0, c.edges.size() - 1)
	s.edges = c.edges[k]
	s.rates = c.rates[k].map(func(r): return cents(r))
	s.band = rng.int_in(1, 2)
	var lo: int = s.edges[s.band]
	var hi: int = s.edges[s.band + 1] - 1 if s.band < 2 else lo * 2
	# A third of the time the order sits on the band's lower edge, where a wrong edge misleads.
	s.n = lo if rng.chance(0.3) else rng.int_in(lo + 1, hi)
	var key: Q = s.rates[s.band].mul(s.n)
	return _apart([key, marginal(s), s.rates[s.band - 1].mul(s.n)])


## Each band's rate on its own items only, as a tax is worked out.
static func marginal(s: Dictionary) -> Q:
	var t := Q.new(0)
	for b in s.band + 1:
		var lo: int = s.edges[b]
		var top: int = s.n if b == s.band else s.edges[b + 1] - 1
		t = t.add(s.rates[b].mul(top - lo + 1))
	return t


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
