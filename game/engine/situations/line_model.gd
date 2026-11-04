class_name LineModelSituation
extends RefCounted
## The `line-model` situation (curriculum/question-types.json): a fixed amount plus a steady
## rate, for fn-ext-line-model (FAL-424) and fn-concept-gradient-meaning's rate questions. The rate
## and the start come first, then the readings, the table and the predictions.
##
## generate() returns:
##   ctx            the context's index in CONTEXTS; m (signed, per unit), c (at input 0)
##   hi             the last input that makes sense where the tank fills or empties, or 0
##   x1, y1, x2, y2 two readings; xp, yp a prediction; xq, yq a reading to solve for its input
##   xbad, ybad     a prediction outside the domain (past hi, or at a negative input); bad_in
##                  (a quarter of the time) makes it one inside it instead
##   tx, ty, tstep, linear   a table at equal steps of tstep; linear false puts one entry off
##                  the line by half a step or more
##   ma, ca, mb, cb, xe     need.plans: two money plans equal at the whole input xe, with
##                  Plan A dearer at the start and cheaper after xe
##
## Inputs are whole, money ends in cents. The clean limits are the checker's too (LM_*).

const TRIES := 2000
## x: the input's letter; y: the output's; each: "km" as in "for each km"; unit: the output's unit
## ("" for money); dir: the sign of the rate; limit: "full", "empty" or "" (no end to the domain).
## story: %c the start, %m the rate. rate, total, start and swap say what a number means.
const CONTEXTS := [
	{"id": "taxi", "x": "d", "y": "C", "each": "km", "unit": "", "dir": 1, "limit": "", "rates": [15, 18, 20, 22, 25], "starts": [3, 4, 5, 6],
		"name": "the distance", "out": "the cost", "story": "A taxi charges a fixed %c, plus %m for each km.",
		"rate": "Each extra km adds %v to the cost", "total": "A whole trip costs %v", "start": "%v is the fixed charge, paid even for a trip of 0 km",
		"per": "dollars per km"},
	{"id": "phone", "x": "t", "y": "C", "each": "minute", "unit": "", "dir": 1, "limit": "", "rates": [5, 10, 15, 20], "den": 100, "scale": 10, "starts": [8, 10, 12, 15],
		"name": "the time on calls", "out": "the bill", "story": "A phone plan costs a fixed %c a month, plus %m for each minute of calls.",
		"rate": "Each extra minute adds %v to the bill", "total": "A whole month's bill is %v", "start": "%v is the monthly charge, paid even with no calls",
		"per": "dollars per minute"},
	{"id": "fill", "x": "t", "y": "V", "each": "minute", "unit": "litres", "dir": 1, "limit": "full", "rates": [20, 25, 30, 40, 50], "starts": [20, 30, 40, 60],
		"name": "the time", "out": "the volume", "story": "A tank holds %c and is being filled by %m each minute.",
		"rate": "Each minute adds %v to the tank", "total": "The tank holds %v in all", "start": "%v is in the tank at the start",
		"per": "litres per minute"},
	{"id": "drain", "x": "t", "y": "V", "each": "minute", "unit": "litres", "dir": -1, "limit": "empty", "rates": [20, 25, 30, 40, 50], "starts": [],
		"name": "the time", "out": "the volume", "story": "A tank holds %c and drains by %m each minute.",
		"rate": "Each minute takes %v out of the tank", "total": "The tank holds %v in all", "start": "%v is in the tank at the start",
		"per": "litres per minute"},
	{"id": "spring", "x": "w", "y": "L", "each": "kg", "unit": "cm", "dir": 1, "limit": "", "rates": [12, 15, 20, 25], "starts": [10, 12, 15, 20],
		"name": "the load", "out": "the length", "story": "A spring is %c long with no load and stretches by %m for each kg hung on it.",
		"rate": "Each extra kg adds %v to the length", "total": "The spring is %v long in all", "start": "%v is the length with no load",
		"per": "cm per kg"},
	{"id": "candle", "x": "t", "y": "H", "each": "hour", "unit": "cm", "dir": -1, "limit": "empty", "rates": [5, 10, 15, 20], "starts": [],
		"name": "the time", "out": "the height", "story": "A candle is %c tall and burns down by %m each hour.",
		"rate": "Each hour takes %v off the height", "total": "The candle is %v tall in all", "start": "%v is the height when it is lit",
		"per": "cm per hour"},
]
const MONEY := [0, 1]


static func pick(rng: Seeded, xs: Array) -> Variant:
	return xs[rng.int_in(0, xs.size() - 1)]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	for i in TRIES:
		var s := draw(rng, need)
		if not s.is_empty():
			s.paper = 1
			return s
	push_error("LineModelSituation: no clean situation for %s" % need)
	return {}


static func draw(rng: Seeded, need: Dictionary) -> Dictionary:
	var pool: Array = MONEY if need.get("plans", false) else range(CONTEXTS.size())
	var s := {"ctx": pick(rng, pool)}
	var ctx: Dictionary = CONTEXTS[s.ctx]
	var step: int = [1, 2, 5, 10][rng.int_in(0, 3)] if ctx.limit == "" else [5, 10][rng.int_in(0, 1)]
	step *= ctx.get("scale", 1)
	var rate: int = pick(rng, ctx.rates)
	s.m = Q.new(rate * ctx.dir, ctx.get("den", 10))
	s.hi = 0
	match ctx.limit:
		"empty":
			s.hi = step * rng.int_in(4, 8)
			s.c = s.m.neg().mul(s.hi)
		"full":
			s.hi = step * rng.int_in(4, 8)
			s.c = Q.new(pick(rng, ctx.starts))
		_:
			s.c = Q.new(pick(rng, ctx.starts))
	var at := func(x: Variant) -> Q: return s.m.mul(x).add(s.c)
	var top: int = 8 if s.hi > 0 else rng.int_in(5, 10)
	var i1 := rng.int_in(1, 2)
	var i2 := i1 + rng.int_in(1, 3)
	var ip := rng.int_in(1, top - 1)
	var iq := rng.int_in(1, top - 1)
	s.x1 = step * i1
	s.x2 = step * i2
	s.xp = step * ip
	s.xq = step * iq
	if s.hi > 0 and (s.x2 >= s.hi or s.xp >= s.hi or s.xq >= s.hi):
		return {}
	if s.xp == s.x1 or s.xp == s.x2 or s.xq == s.xp or s.xq == s.x1 or s.xq == s.x2:
		return {}
	s.y1 = at.call(s.x1)
	s.y2 = at.call(s.x2)
	s.yp = at.call(s.xp)
	s.yq = at.call(s.xq)
	if ctx.unit == "" and (s.yq.mul(100).d != 1 or s.yp.mul(100).d != 1):
		return {}
	# A prediction to judge, and where the domain ends.
	s.bad_in = rng.chance(0.25)
	s.xbad = s.xp if s.bad_in else (s.hi + step * rng.int_in(1, 3) if s.hi > 0 else -step * rng.int_in(1, 3))
	s.ybad = at.call(s.xbad)
	# A table at equal steps.
	s.tstep = step
	s.tx = range(0, 5).map(func(i): return step * i)
	s.ty = s.tx.map(func(x): return at.call(x))
	s.linear = rng.chance(0.6)
	if not s.linear:
		var bump := rng.int_in(1, 3)
		s.ty[bump] = s.ty[bump].add(s.m.abs_q().mul(step).mul(rng.int_in(1, 3)).div(2))
	if need.get("plans", false):
		var ma: int = pick(rng, [5, 10, 15, 20])
		var mb: int = ma + pick(rng, [5, 10, 15])
		s.xe = pick(rng, [10, 20, 30, 40]) * ctx.get("scale", 1)
		s.cb = Q.new(pick(rng, [2, 3, 4, 5, 6, 8]))
		s.ma = Q.new(ma, ctx.get("den", 10))
		s.mb = Q.new(mb, ctx.get("den", 10))
		s.ca = s.cb.add(s.mb.sub(s.ma).mul(s.xe))
	return s


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
