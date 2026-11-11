class_name ConstantChangeSituation
extends RefCounted
## The `constant-change` situation (curriculum/question-types.json): a data set's summary
## statistics, and every value put through y = x + b, y = ax or y = ax + b (FAL-754). The original
## statistics are drawn first and the new ones worked out of them exactly, so on Paper 1 every
## number ends within two decimal places. A question asks a new statistic, or runs the change
## backwards and asks the original one from the new.
##
## need.ask is the unknown (see ConstantChangeViews.UNKNOWNS). generate() returns a Dictionary:
##   paper      1 (every part in the bank is Paper 1)
##   ask, rep   the unknown and its representation
##   op         "add" (y = x + b), "mul" (y = ax) or "lin" (y = ax + b)
##   a, b       the change, Q: a > 0 (1 for "add"), b ≠ 0 (0 for "mul")
##   ctx        the story, an index into STORIES (words and graph), or -1 (equation and terms)
##   back       true when the new statistics are shown and the original ones asked
##   asked      the statistics asked, in order (names from STATS)
##   shown      the statistics told, in order: the asked ones, or others where the unknown says
##   old, new   statistic name -> Q, before and after the change
##   xs         terms: the data, in order (Q), and ys the new values in the same order
##   box        graph: the five numbers drawn ("min", "q1", "med", "q3", "max"), Q
##   tick, x0, x1   graph: the axis of the figure drawn
##   given_var  find-a-and-b: the variances are told, not the standard deviations
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 6000
## Every statistic, and what a change does to it.
const STATS := ["mean", "median", "mode", "lower quartile", "upper quartile", "standard deviation", "variance", "interquartile range", "range"]
const LOCATION := ["mean", "median", "mode", "lower quartile", "upper quartile"]
const SPREAD := ["standard deviation", "interquartile range", "range"]
## The five numbers of a box plot, and the statistics read from them.
const FIVE := ["min", "q1", "med", "q3", "max"]
const SPAN := 25
const EVERY := 5
const MIN_GAP := 2
const TICKS := [1, 2, 5, 10, 20, 50, 100]

## The factors and constants of a change written as an equation.
const EQ_A := [[2, 1], [3, 1], [4, 1], [5, 1], [10, 1], [1, 2], [3, 2], [5, 2]]
const EQ_A_LIN := [[2, 1], [3, 1], [4, 1], [5, 1], [1, 2], [3, 2]]
const EQ_B := [1, 20]

## The stories. Each changes its data one way (op): `change` is the sentence, with {a} and {b} for
## the numbers (a "down" story writes b without its minus sign). `a` lists the factors it can take
## and `b` the range of b; lo to hi is where a measure of centre of the data lies, in its unit.
## A story with `graph` false is never drawn as a box plot (its new values are off the ticks).
const STORIES := [
	{"op": "add", "what": "the masses of the crates in the depot", "new": "the masses of the crates on their pallets",
		"old": "the masses of the crates without their pallets", "unit": "kg", "unit2": "kg", "axis": "mass (kg)", "axis2": "mass on a pallet (kg)",
		"change": "Each crate in the depot is set on a wooden pallet that weighs {b} kg.", "a": [[1, 1]], "b": [2, 9], "lo": 12, "hi": 60, "graph": true},
	{"op": "add", "what": "the times the scouts took to cross the salt flat", "new": "the crossing times in the storm",
		"old": "the crossing times before the storm", "unit": "minutes", "unit2": "minutes", "axis": "time (minutes)", "axis2": "time in the storm (minutes)",
		"change": "A dust storm adds {b} minutes to every scout's crossing time.", "a": [[1, 1]], "b": [3, 15], "lo": 20, "hi": 90, "graph": true},
	{"op": "add", "what": "the prices on a market stall", "new": "the prices with the gate tax", "old": "the prices before the gate tax",
		"unit": "caps", "unit2": "caps", "axis": "price (caps)", "axis2": "price with the tax (caps)",
		"change": "The gate tax adds {b} caps to every price on the stall.", "a": [[1, 1]], "b": [1, 8], "lo": 6, "hi": 40, "graph": true},
	{"op": "add", "what": "the depths of water in the camp's wells", "new": "the depths in the dry season", "old": "the depths before the dry season",
		"unit": "m", "unit2": "m", "axis": "depth (m)", "axis2": "depth in the dry season (m)",
		"change": "In the dry season the water in every well drops by {b} m.", "a": [[1, 1]], "b": [-6, -1], "lo": 10, "hi": 30, "graph": true},
	{"op": "add", "what": "the battery lives of the radios", "new": "the battery lives in the cold", "old": "the battery lives in warm weather",
		"unit": "hours", "unit2": "hours", "axis": "battery life (hours)", "axis2": "battery life in the cold (hours)",
		"change": "In the cold, every radio's battery lasts {b} hours less.", "a": [[1, 1]], "b": [-8, -2], "lo": 16, "hi": 60, "graph": true},
	{"op": "mul", "what": "the heights of the bean plants", "new": "the heights in millimetres", "old": "the heights in centimetres",
		"unit": "cm", "unit2": "mm", "axis": "height (cm)", "axis2": "height (mm)",
		"change": "Every height is then written in millimetres (1 cm = 10 mm).", "a": [[10, 1]], "b": [0, 0], "lo": 10, "hi": 80, "graph": true},
	{"op": "mul", "what": "the prices on a market stall", "new": "the winter prices", "old": "the prices before winter",
		"unit": "caps", "unit2": "caps", "axis": "price (caps)", "axis2": "winter price (caps)",
		"change": "For the winter market, every price on the stall is multiplied by {a}.", "a": [[2, 1], [3, 1], [4, 1], [3, 2], [5, 2]], "b": [0, 0],
		"lo": 4, "hi": 30, "graph": true},
	{"op": "mul", "what": "the water rations of the scouts", "new": "the rations for the long march", "old": "the everyday rations",
		"unit": "litres", "unit2": "litres", "axis": "ration (litres)", "axis2": "march ration (litres)",
		"change": "Before the long march, every scout's ration is multiplied by {a}.", "a": [[2, 1], [3, 1], [3, 2], [1, 2]], "b": [0, 0],
		"lo": 2, "hi": 12, "graph": true},
	{"op": "mul", "what": "the lengths of the cables in the store", "new": "the lengths in centimetres", "old": "the lengths in metres",
		"unit": "m", "unit2": "cm", "axis": "length (m)", "axis2": "length (cm)",
		"change": "Every length is then written in centimetres (1 m = 100 cm).", "a": [[100, 1]], "b": [0, 0], "lo": 2, "hi": 12, "graph": true},
	{"op": "lin", "what": "the masses of scrap the scavengers brought in", "new": "the amounts the scavengers are paid", "old": "the masses of scrap",
		"unit": "kg", "unit2": "caps", "axis": "scrap (kg)", "axis2": "pay (caps)",
		"change": "Each scavenger is paid {b} caps for turning up and {a} caps for every kg of scrap: pay = {a}m + {b}.",
		"a": [[2, 1], [3, 1], [4, 1], [5, 1], [3, 2]], "b": [2, 20], "lo": 4, "hi": 30, "graph": true, "letters": true},
	{"op": "lin", "what": "the noon temperatures at the outpost", "new": "the temperatures in °F", "old": "the temperatures in °C",
		"unit": "°C", "unit2": "°F", "axis": "temperature (°C)", "axis2": "temperature (°F)",
		"change": "Every temperature is converted to °F with F = 1.8C + 32.", "a": [[9, 5]], "b": [32, 32], "lo": 5, "hi": 35, "graph": false},
	{"op": "lin", "what": "the recruits' scores on the scouting test", "new": "the rescaled scores", "old": "the old scores",
		"unit": "", "unit2": "", "axis": "score", "axis2": "rescaled score",
		"change": "The quartermaster rescales every score with S = {a}T + {b}, where T is the old score.",
		"a": [[2, 1], [3, 1], [3, 2], [1, 2]], "b": [5, 30], "lo": 20, "hi": 80, "graph": true, "letters": true},
	{"op": "lin", "what": "the lengths of the caravan trips", "new": "the costs of the trips", "old": "the lengths of the trips",
		"unit": "km", "unit2": "caps", "axis": "trip (km)", "axis2": "cost (caps)",
		"change": "Each trip costs {b} caps to set out plus {a} caps per km: cost = {a}d + {b}.",
		"a": [[2, 1], [3, 1], [4, 1], [5, 1]], "b": [5, 25], "lo": 10, "hi": 60, "graph": true, "letters": true},
]

## unknown -> the ops it can use, whether it runs backwards, and what it asks: "asked" lists the pairs
## it can ask, or "pick" draws one measure of centre and one of spread for the representation.
const SPEC := {
	"add-mean-sd": {"ops": ["add"], "asked": [["mean", "standard deviation"]]},
	"add-mean-variance": {"ops": ["add"], "asked": [["mean", "variance"]]},
	"add-centre-spread": {"ops": ["add"], "pick": true},
	"multiply-mean": {"ops": ["mul"], "asked": [["mean"]], "shown": ["mean", "standard deviation"]},
	"multiply-variance": {"ops": ["mul"], "asked": [["variance"]], "shown": ["mean", "variance"]},
	"multiply-centre-spread": {"ops": ["mul"], "pick": true},
	"linear-mean-iqr": {"ops": ["lin"], "asked": [["mean", "interquartile range"]]},
	"linear-sd-variance": {"ops": ["lin"], "asked": [["standard deviation", "variance"]], "shown": ["standard deviation"]},
	"linear-centre-spread": {"ops": ["lin"], "pick": true},
	"original-mean-sd": {"ops": ["add", "mul", "lin"], "back": true, "asked": [["mean", "standard deviation"]]},
	"original-variance": {"ops": ["mul", "lin"], "back": true, "asked": [["variance"]]},
	"original-centre-spread": {"ops": ["add", "mul", "lin"], "back": true, "pick": true},
	"find-a-and-b": {"ops": ["lin"], "asked": [["mean", "standard deviation"]]},
	"factor-from-variance": {"ops": ["mul"], "asked": [["variance"]]},
	"effect-statement": {"ops": ["add", "mul"], "pick": true},
}

## The measures a "pick" unknown draws from, by representation: [centre, spread].
const PICKS := {
	"words": [["median", "mode", "lower quartile", "upper quartile"], ["interquartile range", "range", "standard deviation"]],
	"graph": [["median", "lower quartile", "upper quartile"], ["interquartile range", "range"]],
	"terms": [["mean", "median", "mode", "lower quartile", "upper quartile"], ["range", "interquartile range"]],
	"equation": [["mean", "median"], ["standard deviation", "variance", "interquartile range", "range"]],
}


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "add-mean-sd")
	var rep: String = need.get("rep", "words")
	var spec: Dictionary = SPEC[ask]
	for i in TRIES:
		var s := {"paper": 1, "ask": ask, "rep": rep, "back": spec.get("back", false), "ctx": -1, "given_var": false, "xs": [], "ys": [], "box": {}}
		s.op = rng.pick(spec.ops)
		if ask == "effect-statement":
			s.op = rng.pick(["add", "add", "mul"]) if rep == "words" else rng.pick(spec.ops)
		_change(rng, s)
		_pick_asked(rng, s, spec)
		var ok := false
		match rep:
			"terms":
				ok = _terms(rng, s)
			"graph":
				ok = _graph(rng, s)
			_:
				ok = _summary(rng, s)
		if ok and ask == "find-a-and-b":
			s.given_var = rng.chance(0.4)
			if s.given_var:
				s.shown = ["mean", "variance"]
				s.old.variance = s.old["standard deviation"].sq()
				s.new.variance = s.new["standard deviation"].sq()
		if ok and _clean(s):
			return s
	return {}


# ── The change ───────────────────────────────────────────────

static func _q(p: Array) -> Q:
	return Q.new(int(p[0]), int(p[1]))


## a and b, from a story (words and graph) or as an equation.
static func _change(rng: Seeded, s: Dictionary) -> void:
	if s.rep in ["words", "graph"]:
		var pool: Array = []
		for i in STORIES.size():
			var st: Dictionary = STORIES[i]
			if st.op != s.op or (s.rep == "graph" and not st.graph):
				continue
			if s.ask == "find-a-and-b" and not st.get("letters", false):
				continue
			if s.ask == "factor-from-variance" and st.a.size() < 2:
				continue
			pool.append(i)
		s.ctx = rng.pick(pool)
		var st: Dictionary = STORIES[s.ctx]
		s.a = _q(rng.pick(st.a))
		s.b = Q.new(rng.int_in(st.b[0], st.b[1]))
		return
	s.a = Q.new(1)
	s.b = Q.new(0)
	if s.op != "add":
		s.a = _q(rng.pick(EQ_A if s.op == "mul" else EQ_A_LIN))
	if s.op != "mul":
		s.b = Q.new(ExtensionViews.nonzero(rng, -EQ_B[1], EQ_B[1]))
	# A story's numbers stay positive; an equation's b of find-a-and-b may be either sign.


static func _pick_asked(rng: Seeded, s: Dictionary, spec: Dictionary) -> void:
	if spec.has("asked"):
		s.asked = (rng.pick(spec.asked) as Array).duplicate()
		s.shown = spec.get("shown", s.asked).duplicate()
		return
	var pools: Array = PICKS[s.rep]
	var spreads: Array = pools[1]
	if s.op == "add" and s.ask != "effect-statement":
		spreads = spreads.filter(func(n): return n != "standard deviation")
	if s.ask == "effect-statement":
		s.asked = [rng.pick(["mean", "median"]), rng.pick(SPREAD + ["variance"])]
	else:
		s.asked = [rng.pick(pools[0]), rng.pick(spreads)]
	s.shown = s.asked.duplicate()


# ── The statistics ───────────────────────────────────────────

## A statistic after the change.
static func forward(name: String, v: Q, a: Q, b: Q) -> Q:
	if name in LOCATION or name in FIVE:
		return a.mul(v).add(b)
	if name == "variance":
		return a.mul(a).mul(v)
	return a.mul(v)


## The statistic before the change, from the one after it.
static func backward(name: String, v: Q, a: Q, b: Q) -> Q:
	if name in LOCATION or name in FIVE:
		return v.sub(b).div(a)
	if name == "variance":
		return v.div(a.mul(a))
	return v.div(a)


## The statistics the question needs, told only: summary numbers in a sentence or an equation.
static func _summary(rng: Seeded, s: Dictionary) -> bool:
	var lo := 5
	var hi := 60
	if s.ctx >= 0:
		lo = STORIES[s.ctx].lo
		hi = STORIES[s.ctx].hi
	var width := hi - lo
	var old := {}
	for name in STATS:
		old[name] = _draw(rng, name, lo, hi, width)
	old.variance = old["standard deviation"].sq()
	if s.ask == "factor-from-variance" or s.ask == "multiply-variance" or s.ask == "add-mean-variance" or s.ask == "original-variance":
		# A variance told on its own is a square of halves, or a whole number.
		if rng.chance(0.3):
			old.variance = Q.new(rng.int_in(2, 40))
	s.old = old
	s.new = {}
	for name in STATS:
		s.new[name] = forward(name, old[name], s.a, s.b)
	return true


## One statistic of a story's data: a measure of centre between lo and hi in halves, a standard
## deviation in halves up to a third of the spread, an IQR or range a whole number.
static func _draw(rng: Seeded, name: String, lo: int, hi: int, width: int) -> Q:
	if name in LOCATION:
		return Q.new(rng.int_in(lo * 2, hi * 2), 2) if rng.chance(0.5) else Q.new(rng.int_in(lo, hi))
	if name == "standard deviation":
		return Q.new(rng.int_in(2, maxi(3, width * 2 / 5)), 2)
	if name == "interquartile range":
		return Q.new(rng.int_in(2, maxi(3, width / 2)))
	if name == "range":
		return Q.new(rng.int_in(maxi(4, width / 3), maxi(5, width)))
	return Q.new(1)


## A short list of whole numbers with one value twice, so the mode is one value.
static func _terms(rng: Seeded, s: Dictionary) -> bool:
	var n := rng.int_in(7, 9)
	var seen := {}
	var xs: Array = []
	while xs.size() < n - 1:
		var x := rng.int_in(1, 40)
		if not seen.has(x):
			seen[x] = true
			xs.append(x)
	xs.append(xs[rng.int_in(0, xs.size() - 1)])
	xs.sort()
	s.xs = xs.map(func(x): return Q.new(x))
	s.old = list_stats(s.xs)
	s.ys = s.xs.map(func(x): return forward("mean", x, s.a, s.b))
	s.new = list_stats(s.ys)
	# The working changes every value, so they stay whole or end in one decimal place.
	for y: Q in s.ys:
		if not ends(y, 1) or y.sign() <= 0:
			return false
	for name in s.asked:
		if not s.new[name].eq(forward(name, s.old[name], s.a, s.b)):
			return false
	return true


## The statistics of a list in order: the mode is the value that appears most (one value), the
## quartiles the medians of the two halves, leaving out the median when n is odd.
static func list_stats(xs: Array) -> Dictionary:
	var n := xs.size()
	var sum := Q.new(0)
	var sq := Q.new(0)
	for x: Q in xs:
		sum = sum.add(x)
		sq = sq.add(x.mul(x))
	var mean := sum.div(Q.new(n))
	var qs := DataSummarySituation.quartiles(xs)
	var mode: Dictionary = DataSummarySituation.mode_of(xs, [])
	var out := {"mean": mean, "median": DataSummarySituation.median_of(xs), "mode": mode.value, "lower quartile": qs[0], "upper quartile": qs[1],
		"range": xs[n - 1].sub(xs[0]), "variance": sq.div(Q.new(n)).sub(mean.mul(mean))}
	out["interquartile range"] = qs[1].sub(qs[0])
	out["standard deviation"] = Q.new(0)
	return out


## The five numbers of a box plot on whole ticks, at least MIN_GAP ticks apart. Forwards the
## figure shows the data; backwards it shows the new values, which must fall on its ticks too.
static func _graph(rng: Seeded, s: Dictionary) -> bool:
	var st: Dictionary = STORIES[s.ctx]
	var t: int = rng.pick([1, 2, 5]) if st.hi >= 30 else 1
	var start := rng.int_in(maxi(0, st.lo / t - 4), maxi(1, st.lo / t))
	var at := [start]
	for i in 4:
		at.append(at[i] + rng.int_in(MIN_GAP, 7))
	if at[4] - at[0] > SPAN - 4:
		return false
	var old := {}
	for i in 5:
		old[FIVE[i]] = Q.new(at[i] * t)
	if old.min.sign() <= 0:
		return false
	var new := {}
	for k in FIVE:
		new[k] = forward(k, old[k], s.a, s.b)
	if new.min.sign() <= 0:
		return false
	var drawn: Dictionary = new if s.back else old
	if not axis_over(s, drawn):
		return false
	s.box = drawn
	s.old = box_stats(old)
	s.new = box_stats(new)
	return true


static func box_stats(f: Dictionary) -> Dictionary:
	return {"median": f.med, "lower quartile": f.q1, "upper quartile": f.q3, "interquartile range": f.q3.sub(f.q1), "range": f.max.sub(f.min),
		"min": f.min, "max": f.max}


## The figure's axis: the first tick that puts every one of the five numbers on a tick, at least
## MIN_GAP ticks apart, within SPAN ticks from a multiple of EVERY ticks.
static func axis_over(s: Dictionary, f: Dictionary) -> bool:
	for t: int in TICKS:
		var tq := Q.new(t)
		var on := true
		for k in FIVE:
			if not f[k].div(tq).is_int():
				on = false
		if not on:
			continue
		var gaps := true
		for i in 4:
			if f[FIVE[i + 1]].sub(f[FIVE[i]]).lt(tq.mul(MIN_GAP)):
				gaps = false
		if not gaps:
			return false
		var big := t * EVERY
		var k0 := floori(f.min.to_float() / big)
		if f.min.eq(Q.new(k0 * big)) and k0 > 0:
			k0 -= 1
		var x0 := Q.new(k0 * big)
		var x1 := x0.add(Q.new(t * SPAN))
		if x1.lt(f.max.add(tq)):
			continue
		s.tick = tq
		s.x0 = x0
		s.x1 = x1
		return true
	return false


# ── Clean numbers ────────────────────────────────────────────

## Ends within `places` decimal places.
static func ends(v: Q, places: int) -> bool:
	var scale := 1
	for i in places:
		scale *= 10
	return v.mul(Q.new(scale)).is_int()


## Every number told or asked ends within two decimal places and is positive (a measure of spread
## more than 0), and the change does something to every statistic asked.
static func _clean(s: Dictionary) -> bool:
	for name in s.shown + s.asked:
		for side in [s.old, s.new]:
			var v: Q = side[name]
			if not ends(v, 2) or v.sign() <= 0:
				return false
	if s.ask == "find-a-and-b":
		# The standard deviations alone fix a, and the means then fix b.
		return not s.a.eq(Q.new(1)) and not s.b.is_zero()
	if s.ask == "factor-from-variance":
		return not s.old.variance.eq(s.new.variance)
	# A told measure of centre is not the spread it is told with, so no option can read both ways.
	if s.asked.size() == 2:
		for side in [s.old, s.new]:
			if side[s.asked[0]].eq(side[s.asked[1]]):
				return false
	if s.rep == "terms":
		# The mean of a list is whole or ends in one decimal place.
		return ends(s.old.mean, 1) and ends(s.new.mean, 1)
	return true


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
