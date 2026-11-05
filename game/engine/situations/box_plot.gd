class_name BoxPlotSituation
extends RefCounted
## The `box-plot` situation (curriculum/question-types.json): one or two data sets, summarised by
## the five numbers of a box plot, and the 1.5 × IQR outlier rule on them (FAL-740). t4-box-plot
## and t4-outlier-rule share it. Everything is exact, so a quartile or a fence is a Q.
##
## A figure lives on an axis of 25 ticks, labelled every fifth tick (PlotView's `box`), and every
## number read from it is on a tick. A list or a frequency table follows data_summary's
## convention: Q1 and Q3 are the medians of the two halves, and the median is left out of both
## when n is odd (DataSummarySituation.quartiles).
##
## A test of a value (`outl`, a fair coin drawn before anything else) puts the value just beyond a
## fence or just inside it, on the same quartiles, so nothing but the test tells them apart. The
## plain figure draws the whisker to the value in both cases.
##
## need.ask is the unknown (see BoxPlotViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx
##   tick, x0, x1      the figure's axis (Q); `x0` is a multiple of five ticks
##   a, b              a group's five numbers {min, q1, med, q3, max}, Q, and `out`, its crosses
##   which             the box asked about (0 or 1), or "Q1"/"Q3", or "U"/"L"
##   two               whether the figure shows two boxes
##   n                 how many values;  ka, kb  the two marks of a share (0 to 4 of the five)
##   share             value-at-share: [words, "below" or "above", the mark]
##   sym, skew         could-be-normal and mean-against-median: the shape
##   ma, mb, sa, sb, ta, tb   compare-summary: the means, standard deviations and maxima
##   claim             claim-from-box-plots: the group the claim favours (0 or 1)
##   xs, fs, data      a list as shown or a table's values, its frequencies, and every value in order
##   x, side, outl     the value tested, "up" or "down", and whether it is an outlier
##   iqr, lo_f, hi_f   the IQR and the two fences
##   limit, error      keep-or-remove: the most the story allows, and whether x is past it
##   pair              which-measure-moves: "centre" (mean, median) or "spread" (range, IQR)
##   rows              a pick: [{five, ref, mistake}], right first
##   iqr_given         quartile-from-no-outliers: the stated IQR
##   knots, curve, dx, dy   five-number-from-cumfreq: as CumulativeFrequencySituation
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 8000
const EDGE := 0.03
const SPAN := 25
const EVERY := 5
const MIN_GAP := 2
const STORIES := 8
const LIMITS := 6
## The ticks that suit each story (BoxPlotViews.STORIES), so a well is never 0.3 m deep. A tick of 1
## or more is whole; only Paper 2 uses the rest.
const TICKS := [[[1, 5], [1, 2], [1, 1]], [[1, 50], [1, 10], [1, 1], [2, 1], [5, 1], [10, 1]], [[1, 1], [2, 1], [5, 1], [10, 1]],
	[[1, 2], [1, 1], [2, 1], [5, 1]], [[1, 1], [2, 1], [5, 1], [10, 1]], [[1, 1], [2, 1], [5, 1], [10, 1]],
	[[1, 2], [1, 1], [2, 1], [5, 1]], [[1, 10], [1, 2], [1, 1], [2, 1]]]
const PAIRS := [[0, 1], [1, 2], [2, 3], [3, 4], [0, 2], [1, 3], [2, 4], [0, 3], [1, 4]]
const SHARES := [["Half", "below", "med"], ["Half", "above", "med"], ["A quarter", "below", "q1"], ["A quarter", "above", "q3"],
	["Three quarters", "below", "q3"], ["Three quarters", "above", "q1"]]
const LIST := {1: [9, 13, 6, 30], 2: [11, 17, 20, 70]}
const TABLE := {1: [4, 6, 1, 15, 7], 2: [5, 7, 10, 60, 12]}
const LOOKS_FAR := 1.0


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "read-median")
	var rep: String = need.get("rep", "graph")
	var paper: int = int(need.get("paper", 2))
	# Drawn once, so a filter below can't favour one case.
	var outl := rng.chance(0.5)
	var sym := rng.chance(0.5)
	var up := rng.chance(0.5)
	var hi_first := rng.chance(0.5)
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "ctx": rng.int_in(0, STORIES - 1), "two": false, "which": 0, "out": [],
			"outl": outl, "sym": sym, "skew": "up" if up else "down", "side": "up" if up else "down", "n": 0, "xs": [], "fs": [], "data": []}
		var ok := false
		match ask:
			"read-median", "read-iqr", "read-median-iqr":
				ok = _read(rng, s)
				s.two = ok and rng.chance(0.4)
				if s.two:
					ok = _second(rng, s)
			"read-quartile":
				ok = _read(rng, s)
				s.which = rng.pick(["Q1", "Q3"])
			"read-range":
				ok = _read(rng, s) and (not outl or _cross(rng, s))
			"count-in-section", "percent-in-section":
				ok = _section(rng, s)
			"value-at-share":
				s.share = rng.pick(SHARES)
				ok = _read(rng, s)
			"five-number-from-data":
				ok = _data(rng, s)
			"pick-box-from-data":
				ok = _data(rng, s) and _pick_from_data(rng, s)
			"pick-box-with-outlier":
				s.outl = true
				s.side = "up"
				ok = _list_test(rng, s) and _pick_with_outlier(s)
			"five-number-from-cumfreq":
				ok = _cumfreq(rng, s)
			"could-be-normal":
				ok = _shape(rng, s, "sym" if sym else s.skew)
			"mean-against-median":
				ok = _shape(rng, s, s.skew)
			"compare-box-plots":
				ok = _groups(rng, s, false, hi_first)
			"claim-from-box-plots":
				s.claim = 0 if outl else 1
				ok = _groups(rng, s, true, hi_first)
			"compare-summary":
				ok = _summary(rng, s, hi_first)
			"find-fences", "largest-not-outlier":
				ok = _list_test(rng, s) if rep == "terms" else _read(rng, s)
				ok = ok and _fences(s) and s.lo_f.sign() > 0
			"smallest-outlier":
				ok = _read(rng, s, true) and _fences(s) and s.lo_f.sign() > 0
			"decide-outlier":
				ok = _list_test(rng, s) if rep == "terms" else _box_test(rng, s)
			"show-max-outlier":
				s.outl = true
				s.side = "up"
				ok = _list_test(rng, s) if rep == "terms" else _box_test(rng, s)
			"quartile-from-no-outliers":
				s.which = rng.pick(["U", "U", "L"])
				ok = _no_outliers(rng, s)
			"outliers-in-data":
				ok = _count(rng, s)
			"keep-or-remove":
				ok = _keep(rng, s)
			"effect-of-removing", "which-measure-moves":
				s.pair = rng.pick(["centre", "spread"])
				ok = _effect(rng, s)
		if ok:
			return s
	return {}


# ── The axis and a box ───────────────────────────────────────

static func _axis(rng: Seeded, s: Dictionary, whole: bool = false) -> void:
	var pool: Array = TICKS[s.ctx]
	if whole or s.paper == 1:
		pool = pool.filter(func(p): return p[1] == 1)
	var t: Array = rng.pick(pool)
	s.tick = Q.new(t[0], t[1])
	s.x0 = s.tick.mul(Q.new(EVERY * rng.int_in(0, 6)))
	s.x1 = s.x0.add(s.tick.mul(Q.new(SPAN)))


static func at(s: Dictionary, i: float) -> Q:
	return s.x0.add(s.tick.mul(Q.new(roundi(i * 2.0), 2)))


## The axis of a figure drawn from data: the first tick size that fits lo to hi.
static func _axis_over(s: Dictionary, lo: Q, hi: Q) -> bool:
	for d in [[1, 10], [1, 5], [1, 2], [1, 1], [2, 1], [5, 1], [10, 1]]:
		var t := Q.new(d[0], d[1])
		var big := t.mul(Q.new(EVERY))
		var k := floori(lo.to_float() / big.to_float())
		if k > 0 and lo.eq(big.mul(Q.new(k))):
			k -= 1
		var x0 := big.mul(Q.new(k))
		if x0.add(t.mul(Q.new(SPAN))).lt(hi.add(t)):
			continue
		s.tick = t
		s.x0 = x0
		s.x1 = x0.add(t.mul(Q.new(SPAN)))
		return true
	return false


static func five(mn: Q, q1: Q, med: Q, q3: Q, mx: Q, out: Array = []) -> Dictionary:
	return {"min": mn, "q1": q1, "med": med, "q3": q3, "max": mx, "out": out}


## Five positions on the axis: the gaps of a shape.
static func _gaps(rng: Seeded, shape: String) -> Array:
	var g: Array
	match shape:
		"sym":
			var b := rng.int_in(2, 4)
			var w := rng.int_in(b + 1, 7)
			g = [w, b, b, w]
		"up":
			var b1 := rng.int_in(2, 3)
			var w1 := rng.int_in(2, 3)
			g = [w1, b1, b1 + rng.int_in(2, 4), w1 + rng.int_in(3, 7)]
		"down":
			var b2 := rng.int_in(2, 3)
			var w2 := rng.int_in(2, 3)
			g = [w2 + rng.int_in(3, 7), b2 + rng.int_in(2, 4), b2, w2]
		_:
			g = [rng.int_in(2, 7), rng.int_in(2, 6), rng.int_in(2, 6), rng.int_in(2, 7)]
			if g[1] == g[2] or g[0] == g[3] or g[0] + g[1] == g[2] + g[3]:
				return []
	var total: int = g[0] + g[1] + g[2] + g[3]
	if total > SPAN - 2:
		return []
	var i := rng.int_in(1, SPAN - 1 - total)
	return [i, i + g[0], i + g[0] + g[1], i + g[0] + g[1] + g[2], i + total]


static func _box(s: Dictionary, p: Array) -> Dictionary:
	return five(at(s, p[0]), at(s, p[1]), at(s, p[2]), at(s, p[3]), at(s, p[4]))


## How many values a plot stands for, in a story.
static func _size(rng: Seeded) -> int:
	return rng.pick([40, 60, 80, 120, 160, 200, 240, 400])


static func _read(rng: Seeded, s: Dictionary, whole: bool = false) -> bool:
	_axis(rng, s, whole)
	var p := _gaps(rng, "free")
	if p.is_empty():
		return false
	s.a = _box(s, p)
	s.n = _size(rng)
	return true


## The second box of a figure. Either box may be asked about.
static func _second(rng: Seeded, s: Dictionary) -> bool:
	var p := _gaps(rng, "free")
	if p.is_empty():
		return false
	s.b = _box(s, p)
	s.which = rng.int_in(0, 1)
	return not s.a.med.eq(s.b.med) and not s.a.q3.sub(s.a.q1).eq(s.b.q3.sub(s.b.q1))


## An outlier drawn as a cross, past the whisker, on the same axis.
static func _cross(rng: Seeded, s: Dictionary) -> bool:
	if not _fences(s) or s.hi_f.lt(s.a.max) or s.a.min.lt(s.lo_f):
		return false
	var i := rng.int_in(1, 4)
	var x: Q = s.hi_f.add(s.tick.mul(Q.new(i)))
	x = at(s, ceilf(x.sub(s.x0).div(s.tick).to_float()))
	if s.x1.lt(x) or x.eq(s.x1):
		return false
	s.a.out = [x]
	return true


## The two marks of a share. n is 4 × the plot's length in ticks × a whole number, so a quarter
## and the slip that goes by length both come out whole.
static func _section(rng: Seeded, s: Dictionary) -> bool:
	if not _read(rng, s):
		return false
	var pk: Array = rng.pick(PAIRS)
	s.ka = pk[0]
	s.kb = pk[1]
	var names := ["min", "q1", "med", "q3", "max"]
	var len: Q = s.a[names[s.kb]].sub(s.a[names[s.ka]])
	var full: Q = s.a.max.sub(s.a.min)
	var ticks := roundi(full.div(s.tick).to_float())
	if s.ask == "percent-in-section":
		var pct := len.div(full).mul(Q.new(100))
		return pct.is_int() and not pct.eq(Q.new(25 * (s.kb - s.ka)))
	s.n = 4 * ticks * rng.int_in(1, 6)
	return s.n != 100 and not len.div(full).eq(Q.new(s.kb - s.ka, 4))


static func _shape(rng: Seeded, s: Dictionary, shape: String) -> bool:
	_axis(rng, s)
	var p := _gaps(rng, shape)
	if p.is_empty():
		return false
	s.a = _box(s, p)
	s.n = _size(rng)
	return true


## Two groups on one axis: the medians and the IQRs differ by two ticks or more, and the group with
## the lower median has the higher maximum, so the ends alone mislead. With `larger`, the group
## with the higher median also has the larger IQR. hi_first says which group has the higher median.
static func _groups(rng: Seeded, s: Dictionary, larger: bool, hi_first: bool) -> bool:
	_axis(rng, s)
	var pa := _gaps(rng, "free")
	var pb := _gaps(rng, "free")
	if pa.is_empty() or pb.is_empty():
		return false
	var high: Array = pa if pa[2] > pb[2] else pb
	var low: Array = pb if pa[2] > pb[2] else pa
	var ih: int = high[3] - high[1]
	var il: int = low[3] - low[1]
	if high[2] - low[2] < MIN_GAP or absi(ih - il) < MIN_GAP or low[4] <= high[4] or (larger and ih <= il):
		return false
	s.a = _box(s, high if hi_first else low)
	s.b = _box(s, low if hi_first else high)
	s.two = true
	return true


static func _summary(rng: Seeded, s: Dictionary, hi_first: bool) -> bool:
	var ml := rng.int_in(200, 700)
	var mh := ml + rng.int_in(20, 120)
	var sh := rng.int_in(20, 120)
	var sl := rng.int_in(20, 120)
	if absi(sh - sl) < 10:
		return false
	# The group with the lower mean has the higher maximum.
	var th := mh + rng.int_in(15, 25) * sh / 10
	var tl := th + rng.int_in(5, 60)
	if tl - ml < 15 * sl / 10:
		return false
	var d := Q.new(1, 10)
	var hi := [Q.new(mh).mul(d), Q.new(sh).mul(d), Q.new(th).mul(d)]
	var lo := [Q.new(ml).mul(d), Q.new(sl).mul(d), Q.new(tl).mul(d)]
	var first: Array = hi if hi_first else lo
	var second: Array = lo if hi_first else hi
	s.ma = first[0]
	s.sa = first[1]
	s.ta = first[2]
	s.mb = second[0]
	s.sb = second[1]
	s.tb = second[2]
	s.two = true
	return true


# ── Data ─────────────────────────────────────────────────────

static func _quartiles_of(data: Array) -> Dictionary:
	var qs := DataSummarySituation.quartiles(data)
	return five(data[0], qs[0], DataSummarySituation.median_of(data), qs[1], data[data.size() - 1])


## A list or a frequency table, with a box of its own.
static func _data(rng: Seeded, s: Dictionary) -> bool:
	if s.rep == "table":
		var t: Array = TABLE[s.paper]
		DataSummarySituation._table(rng, s, rng.int_in(t[0], t[1]), t[2], t[3], t[4])
		if s.n < (8 if s.paper == 1 else 25) or s.n > (24 if s.paper == 1 else 60):
			return false
	else:
		var l: Array = LIST[s.paper]
		var xs: Array = []
		for i in rng.int_in(l[0], l[1]):
			xs.append(Q.new(rng.int_in(l[2], l[3])))
		s.data = DataSummarySituation.sorted(xs)
		s.n = xs.size()
		# Paper 1 shows the list in order, for a by-hand summary; Paper 2 shows it as it came.
		s.xs = s.data if s.paper == 1 else xs
		if s.paper == 2 and _same(xs, s.data):
			return false
	s.a = _quartiles_of(s.data)
	return s.a.min.lt(s.a.q1) and s.a.q1.lt(s.a.med) and s.a.med.lt(s.a.q3) and s.a.q3.lt(s.a.max) and _axis_over(s, s.a.min, s.a.max)


## Four boxes for the same data: the right one, then the wrong ones (see rows).
static func _pick_from_data(_rng: Seeded, s: Dictionary) -> bool:
	s.rows = [{"five": s.a, "ref": "right", "mistake": ""}]
	var a: Dictionary = s.a
	var cands: Array = []
	if s.n % 2 == 1:
		cands.append(["keep-median", keep_median(s.data)])
	cands.append(["positions", positions(s.data)])
	if s.rep == "table":
		cands.append(["no-frequency", _quartiles_of(s.xs)])
	elif s.paper == 2:
		cands.append(["unsorted", unsorted(s.xs)])
	cands.append(["box-middle", five(a.min, a.q1, a.q1.add(a.q3).div(Q.new(2)), a.q3, a.max)])
	var near: Array = s.data.filter(func(v): return a.q3.lt(v) and v.lt(a.max))
	if not near.is_empty():
		cands.append(["short-whisker", five(a.min, a.q1, a.med, a.q3, near[0])])
	var seen := [five_key(a)]
	for c in cands:
		var f: Dictionary = c[1]
		if s.rows.size() < 4 and valid(f) and not five_key(f) in seen:
			seen.append(five_key(f))
			s.rows.append({"five": f, "ref": c[0], "mistake": c[0]})
	return s.rows.size() == 4


static func _same(a: Array, b: Array) -> bool:
	for i in a.size():
		if not a[i].eq(b[i]):
			return false
	return true


static func valid(f: Dictionary) -> bool:
	return f.min.lt(f.q1) and f.q1.lt(f.med) and f.med.lt(f.q3) and f.q3.lt(f.max)


static func five_key(f: Dictionary) -> String:
	return "%s %s %s %s %s" % [f.min.key(), f.q1.key(), f.med.key(), f.q3.key(), f.max.key()]


## The slip of keeping the median in both halves, when n is odd.
static func keep_median(data: Array) -> Dictionary:
	var n := data.size()
	var h := DataSummarySituation.half(n)
	return five(data[0], DataSummarySituation.median_of(data.slice(0, h + 1)), DataSummarySituation.median_of(data),
		DataSummarySituation.median_of(data.slice(h, n)), data[n - 1])


## The slip of taking the quartiles at the n/4th and 3n/4th values, rounded up.
static func positions(data: Array) -> Dictionary:
	var n := data.size()
	return five(data[0], data[ceili(n / 4.0) - 1], DataSummarySituation.median_of(data), data[ceili(3.0 * n / 4.0) - 1], data[n - 1])


## The slip of using the list as it is shown, unsorted.
static func unsorted(xs: Array) -> Dictionary:
	var qs := DataSummarySituation.quartiles(xs)
	return five(xs[0], qs[0], DataSummarySituation.median_of(xs), qs[1], xs[xs.size() - 1])


static func _fences(s: Dictionary) -> bool:
	var a: Dictionary = s.a
	s.iqr = a.q3.sub(a.q1)
	var d: Q = s.iqr.mul(Q.new(3, 2))
	s.lo_f = a.q1.sub(d)
	s.hi_f = a.q3.add(d)
	return s.iqr.sign() > 0


## What a test needs of x: each of the two slips on the fence gives one verdict, so two options
## end in each whatever the right one is.
static func _slips_fit(s: Dictionary, x: Q) -> bool:
	var a: Dictionary = s.a
	var d: Q = s.iqr.mul(Q.new(3, 2))
	if s.side == "up":
		return a.med.add(d).lt(x) and not a.q3.mul(Q.new(3, 2)).lt(x) and not x.sub(a.q3).eq(d)
	return x.lt(a.med.sub(d)) and x.sign() > 0 and not a.q1.sub(x).eq(d)


## A plain figure with the value at the end of a whisker.
static func _box_test(rng: Seeded, s: Dictionary) -> bool:
	_axis(rng, s)
	var b1 := rng.int_in(2, 4)
	var b2 := rng.int_in(2, 4)
	var w := rng.int_in(2, 4)
	var b := b1 + b2
	var up: bool = s.side == "up"
	# The box and the whisker on the other side, placed so the value can fall on the axis.
	var q1 := rng.int_in(w + 1, 12) if up else rng.int_in(13, SPAN - b - w - 1)
	var q3 := q1 + b
	var p := [q1 - w, q1, q1 + b1, q3, q3 + w]
	s.a = _box(s, p)
	_fences(s)
	# The fence in ticks, on the far side, from which x moves one or two ticks either way.
	var f: float = q3 + 1.5 * b if up else q1 - 1.5 * b
	var ins := rng.int_in(1, 2)
	var far := rng.int_in(1, 2)
	var i_in: float = floorf(f - 0.25) - (ins - 1) if up else ceilf(f + 0.25) + (ins - 1)
	var i_out: float = ceilf(f + 0.25) + (far - 1) if up else floorf(f - 0.25) - (far - 1)
	var i_x: float = i_out if s.outl else i_in
	var inside := absf(i_in - (q3 if up else q1))
	if i_out < 1 or i_out > SPAN - 1 or i_in < 1 or i_in > SPAN - 1 or inside < 3:
		return false
	var x_in := at(s, i_in)
	var x_out := at(s, i_out)
	if not _slips_fit(s, x_in) or not _slips_fit(s, x_out):
		return false
	s.x = at(s, i_x)
	if up:
		s.a.max = s.x
	else:
		s.a.min = s.x
	s.n = _size(rng)
	return true


## A list whose extreme value is tested. The rest of the list has no outlier; the value sits
## just past a fence or just inside it, and moving it doesn't move the quartiles.
static func _list_test(rng: Seeded, s: Dictionary) -> bool:
	var l: Array = LIST[s.paper]
	var unit := Q.new(1, 10) if s.paper == 2 and rng.chance(0.4) else Q.new(1)
	var count := rng.int_in(l[0], l[1])
	var rest: Array = []
	for i in count - 1:
		rest.append(Q.new(rng.int_in(l[2], l[3])).mul(unit))
	rest = DataSummarySituation.sorted(rest)
	var up: bool = s.side == "up"
	var edge: Q = rest[rest.size() - 1].add(unit) if up else rest[0].sub(unit)
	var data: Array = rest + [edge] if up else [edge] + rest
	s.a = _quartiles_of(data)
	s.n = count
	if not _fences(s) or not s.a.q1.lt(s.a.med) or not s.a.med.lt(s.a.q3):
		return false
	for v in rest:
		if v.lt(s.lo_f) or s.hi_f.lt(v):
			return false
	var f: Q = s.hi_f if up else s.lo_f
	var units := f.div(unit).to_float()
	var i_in: float = (ceilf(units) - 1.0 - rng.int_in(0, 1)) if up else (floorf(units) + 1.0 + rng.int_in(0, 1))
	var i_out: float = (floorf(units) + 1.0 + rng.int_in(0, 1)) if up else (ceilf(units) - 1.0 - rng.int_in(0, 1))
	var x_in: Q = Q.new(roundi(i_in)).mul(unit)
	var x_out: Q = Q.new(roundi(i_out)).mul(unit)
	# The value stays the extreme either way, and clear of the rest.
	if up and not (edge.lt(x_in) or edge.eq(x_in)):
		return false
	if not up and not (x_in.lt(edge) or x_in.eq(edge)):
		return false
	if not _slips_fit(s, x_in) or not _slips_fit(s, x_out):
		return false
	var x: Q = x_out if s.outl else x_in
	s.x = x
	data = rest + [x] if up else [x] + rest
	s.data = data
	s.xs = data if s.paper == 1 else rng.shuffled(data)
	if s.paper == 2 and _same(s.xs, s.data):
		return false
	if up:
		s.a.max = x
	else:
		s.a.min = x
	return _axis_over(s, s.a.min, s.a.max)


## Each row of a pick with an outlier: the box is the same, and what is done with the value differs.
static func _pick_with_outlier(s: Dictionary) -> bool:
	var a: Dictionary = s.a
	var inside: Q = s.data[s.data.size() - 2]
	if inside.eq(s.hi_f) or not a.q3.lt(inside):
		return false
	s.rows = [{"five": five(a.min, a.q1, a.med, a.q3, inside, [s.x]), "ref": "right", "mistake": ""},
		{"five": five(a.min, a.q1, a.med, a.q3, s.x), "ref": "whisker", "mistake": "whisker"},
		{"five": five(a.min, a.q1, a.med, a.q3, s.hi_f, [s.x]), "ref": "fence", "mistake": "fence"},
		{"five": five(a.min, a.q1, a.med, a.q3, inside), "ref": "", "mistake": "dropped"}]
	return true


## From a cumulative frequency curve. The curve's own situation draws it, with its start or its end
## inside the axis so that the ends have to be read.
static func _cumfreq(rng: Seeded, s: Dictionary) -> bool:
	var c := CumulativeFrequencySituation.generate(rng, {"ask": "median-from-graph", "rep": "graph"})
	if c.is_empty():
		return false
	var first: int = c.knots[0][0]
	var last: int = c.knots[-1][0]
	if first == 0 or last == CumulativeFrequencySituation.SQUARES * c.dx:
		return false
	for k in ["ctx", "dx", "dy", "knots", "curve", "n"]:
		s[k] = c[k]
	s.a = five(Q.new(first), Q.new(c.q1), Q.new(c.med), Q.new(c.q3), Q.new(last))
	return true


# ── Backwards from the rule ──────────────────────────────────

## max, the IQR and no outliers bound U from below, and then L. The IQR is even so the bound is a
## whole number of units, and the bounds leave room for the median between them.
static func _no_outliers(rng: Seeded, s: Dictionary) -> bool:
	var unit := Q.new(1, 10) if s.paper == 2 and rng.chance(0.4) else Q.new(1)
	var k := rng.int_in(3, 12)
	var i_u := rng.int_in(20, 60)
	var i_l := i_u - 2 * k
	var i_max := i_u + 3 * k
	var i_min := i_l - rng.int_in(2, 2 * k)
	var i_med := rng.int_in(i_l + 2, i_u - 2)
	if i_min <= 0 or i_l - 3 * k > i_min or i_med == i_l + k:
		return false
	s.a = five(Q.new(i_min).mul(unit), Q.new(i_l).mul(unit), Q.new(i_med).mul(unit), Q.new(i_u).mul(unit), Q.new(i_max).mul(unit))
	s.iqr_given = Q.new(2 * k).mul(unit)
	return true


# ── Counting outliers ────────────────────────────────────────

static func count_beyond(data: Array, lo: Q, hi: Q) -> int:
	return data.filter(func(v): return v.lt(lo) or hi.lt(v)).size()


## A list or a table with 1 to 3 outliers, or none, and one value that looks far but is inside
## the fences.
static func _count(rng: Seeded, s: Dictionary) -> bool:
	if not _data(rng, s):
		return false
	var hi := rng.int_in(0, 2)
	var q3: Q = s.a.q3
	var iq: Q = q3.sub(s.a.q1)
	var extras: Array = []
	for i in hi:
		extras.append(Q.new(ceili(q3.add(iq.mul(Q.new(rng.int_in(18, 30), 10))).to_float())))
	extras.append(Q.new(floori(q3.add(iq.mul(Q.new(rng.int_in(11, 14), 10))).to_float())))
	if s.rep == "table":
		extras.sort_custom(func(p, q): return p.lt(q))
		for e in extras:
			if s.xs.any(func(v): return v.eq(e)):
				return false
			s.xs.append(e)
			s.fs.append(rng.int_in(1, 2))
		if s.xs.size() > 8:
			return false
		var at: Array = range(s.xs.size())
		at.sort_custom(func(i, j): return s.xs[i].lt(s.xs[j]))
		s.fs = at.map(func(i): return s.fs[i])
		s.xs = at.map(func(i): return s.xs[i])
		s.data = DataSummarySituation.expand(s.xs, s.fs)
		s.n = s.data.size()
	else:
		var xs: Array = s.xs.duplicate()
		xs.append_array(extras)
		s.data = DataSummarySituation.sorted(xs)
		s.n = xs.size()
		s.xs = s.data if s.paper == 1 else rng.shuffled(xs)
	s.a = _quartiles_of(s.data)
	if not _fences(s) or not s.a.q1.lt(s.a.q3):
		return false
	s.k = count_beyond(s.data, s.lo_f, s.hi_f)
	var a: Dictionary = s.a
	var d: Q = s.iqr.mul(Q.new(3, 2))
	s.k_q = count_beyond(s.data, s.lo_f, a.q3.mul(Q.new(3, 2)))
	s.k_m = count_beyond(s.data, a.med.sub(d), a.med.add(d))
	# The value that looks far: inside the fence, more than one IQR past Q3.
	var far: Array = s.data.filter(func(v): return a.q3.add(s.iqr.mul(Q.new(LOOKS_FAR))).lt(v) and not s.hi_f.lt(v))
	for v in s.data:
		if v.eq(s.lo_f) or v.eq(s.hi_f):
			return false
	return s.k <= 3 and not far.is_empty()


# ── Keeping or removing, and what removing does ──────────────

static func _keep(rng: Seeded, s: Dictionary) -> bool:
	s.ctx = rng.int_in(0, LIMITS - 1)
	var q1 := rng.int_in(4, 20)
	var iq := 2 * rng.int_in(2, 6)
	var q3 := q1 + iq
	var f: int = q3 + 3 * iq / 2
	var lim := f + rng.int_in(3, 12)
	s.a = five(Q.new(q1 - 2), Q.new(q1), Q.new(q1 + iq / 2), Q.new(q3), Q.new(q3))
	_fences(s)
	s.limit = Q.new(lim)
	s.error = s.outl
	s.x = Q.new(lim + rng.int_in(2, 9) if s.error else rng.int_in(f + 1, lim - 1))
	s.n = rng.pick([12, 16, 20, 24, 30])
	return true


static func _effect(rng: Seeded, s: Dictionary) -> bool:
	var p1: bool = s.paper == 1
	var m := rng.int_in(6, 9) if p1 else rng.int_in(9, 13)
	var rest: Array = []
	for i in m:
		rest.append(Q.new(rng.int_in(10, 30)))
	rest = DataSummarySituation.sorted(rest)
	var up: bool = s.side == "up"
	var x := Q.new(rest[m - 1].n + rng.int_in(20, 45)) if up else Q.new(rng.int_in(1, maxi(1, rest[0].n - 8)))
	if not up and rest[0].n < 16:
		return false
	var data: Array = rest + [x] if up else [x] + rest
	s.data = data
	s.xs = data if p1 else rng.shuffled(data)
	s.n = data.size()
	s.x = x
	s.a = _quartiles_of(data)
	if not _fences(s) or not (x.lt(s.lo_f) or s.hi_f.lt(x)):
		return false
	s.mean0 = DataSummarySituation.mean_of(data)
	s.mean1 = DataSummarySituation.mean_of(rest)
	s.med0 = s.a.med
	s.med1 = DataSummarySituation.median_of(rest)
	s.b = _quartiles_of(rest)
	s.iqr1 = s.b.q3.sub(s.b.q1)
	s.rest = rest
	var dm: float = absf(s.mean0.sub(s.mean1).to_float())
	var dd: float = absf(s.med0.sub(s.med1).to_float())
	var dr: float = absf(s.a.max.sub(s.a.min).sub(s.b.max.sub(s.b.min)).to_float())
	var di: float = absf(s.iqr.sub(s.iqr1).to_float())
	if s.med0.eq(s.med1) or dm < 3.0 * dd or dr < 3.0 * di or dr <= 0.0:
		return false
	if p1:
		# Every mean an option shows ends too, so a slip's mean is no fraction.
		return DataSummarySituation.ends_in_one_place(s.mean1) and DataSummarySituation.ends_in_one_place(s.mean0) \
				and DataSummarySituation.ends_in_one_place(DataSummarySituation.total_of(rest).div(Q.new(s.n)))
	return Answer.rounds_clearly(s.mean1.to_float(), EDGE)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
