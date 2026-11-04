class_name CumulativeFrequencySituation
extends RefCounted
## The `cumulative-frequency` situation (curriculum/question-types.json): grouped data as a
## cumulative frequency curve or a table (FAL-726). Every question is Paper 1, as every bank part
## is, so every reading has one right value.
##
## A curve lives on a grid of 20 squares by 20. A square up is n ÷ 20 and a square across is dx, so
## each 5% of n is a grid line. The curve goes through knots at grid points, and every value a
## question reads off it, right or wrong, is a knot: the reader meets it on a corner of the grid.
## `curve` is the knots joined smoothly, without overshoot.
##
## A table has equal classes, and any estimate from it ends in at most one decimal.
##
## need.ask is the unknown (see CumulativeFrequencyViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx (an index into CumulativeFrequencyViews.CONTEXTS)
##   n, dx, dy      the total and one square across and up (dy on a curve only)
##   knots, curve   a curve's knots and its sample, [[x, y], ...]
##   bs, cf, fs     the class boundaries, each boundary's cumulative frequency after the first, and
##                  each class's frequency
##   q1, med, q3    a curve's quartiles and median
##   which          "Q1" or "Q3";  pct  a percentage asked;  top  how many at the top
##   v, v2          the values asked about;  r  how many times the sample the whole group is
##   j, j2          the classes asked about
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 4000
const SQUARES := 20
const SAMPLES := 8
## What a square across is, story by story (CumulativeFrequencyViews.CONTEXTS).
const DX := [2, 1, 5, 10, 2, 20, 5, 10, 20]
## The stories with a limit: the most any one of them can hold.
const LIMITED := [7, 8]
const TOTALS := [40, 60, 80, 100, 120, 160, 200, 240]
const TABLE_TOTALS := [40, 60, 80, 100, 120, 160, 200]
const SHARES := [60, 70, 75, 80, 90]
const TOP_SQUARES := [1, 2, 3, 4, 6, 8]
const TOP_PCTS := [5, 10, 15, 20, 30, 40]
const PERCENTS := [10, 20, 30, 40, 60, 70, 80, 90]
## Percentiles to read off a curve: on each total, k itself is a grid line for some of these.
const READ_PERCENTS := [10, 15, 20, 30, 40, 45, 60, 65, 70, 80, 90]
## A curve is no flatter or steeper than this between knots, in squares up per square across.
const SLOPE := [0.25, 6.0]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "median-from-graph")
	var rep: String = need.get("rep", "graph")
	for i in TRIES:
		var s := {"paper": 1, "ask": ask, "rep": rep, "ctx": rng.int_in(0, DX.size() - 1), "which": "Q1", "pct": 0, "top": 0,
			"v": 0, "v2": 0, "r": 0, "j": 0, "j2": 0, "dy": 0, "knots": [], "curve": [], "q1": 0, "med": 0, "q3": 0}
		if ask == "share-of-limit":
			s.ctx = rng.pick(LIMITED)
		s.dx = DX[s.ctx]
		if _graph(rng, s) if rep == "graph" else _table(rng, s):
			return s
	return {}


@warning_ignore("integer_division")
static func cut(a: int, b: int) -> int:
	return a / b


# ── A curve ──────────────────────────────────────────────────

static func _graph(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.pick(TOTALS)
	s.dy = cut(s.n, SQUARES)
	var levels: Array = [5, 10, 15, rng.int_in(1, 19), rng.int_in(1, 19), rng.int_in(1, 19)]
	var xs: Array = []
	match s.ask:
		"percentile-from-graph":
			if s.n == 100:
				return false
			var pcts: Array = READ_PERCENTS.filter(func(p): return p % s.dy == 0 and p < s.n)
			if pcts.is_empty():
				return false
			s.pct = rng.pick(pcts)
			levels.append_array([cut(s.pct, 5), cut(s.pct, s.dy)])
		"cutoff-top":
			var m: int = rng.pick(TOP_SQUARES)
			s.top = m * s.dy
			levels.append_array([SQUARES - m, m])
		"cutoff-percent":
			s.pct = rng.pick(TOP_PCTS)
			levels.append_array([SQUARES - cut(s.pct, 5), cut(s.pct, 5)])
		"share-of-limit":
			s.pct = rng.pick(SHARES)
			xs.append(cut(s.pct, 5))
	var knots := _knots(rng, levels, xs)
	if knots.is_empty():
		return false
	s.knots = knots.map(func(p): return [p[0] * s.dx, p[1] * s.dy])
	s.q1 = x_at(s, 5 * s.dy)
	s.med = x_at(s, 10 * s.dy)
	s.q3 = x_at(s, 15 * s.dy)
	if s.med == 10 * s.dx:
		return false
	s.curve = smooth(s.knots)
	return _classes(rng, s) and _graph_ask(rng, s)


## Grid points on an S shape, one at each level in `levels` and one at each square across in `xs`,
## rising strictly from the curve's start to its end. [] if they don't fit.
static func _knots(rng: Seeded, levels: Array, xs: Array) -> Array:
	var i0 := rng.int_in(0, 3)
	var i1 := rng.int_in(17, SQUARES)
	var mid := i0 + (i1 - i0) * rng.int_in(30, 70) / 100.0
	var spread := rng.int_in(12, 30) / 10.0
	var at := {i0: 0, i1: SQUARES}
	var used := {}
	for h in levels:
		if used.has(h):
			continue
		used[h] = true
		var t: float = h / float(SQUARES)
		var i := roundi(mid + spread * log(t / (1.0 - t)) + rng.int_in(-1, 1) * 0.5)
		if i <= i0 or i >= i1 or at.has(i):
			return []
		at[i] = h
	for i in xs:
		if at.has(i) or i <= i0 or i >= i1:
			continue
		var h := clampi(roundi(SQUARES / (1.0 + exp((mid - i) / spread))), 1, SQUARES - 1)
		if used.has(h):
			return []
		used[h] = true
		at[i] = h
	var keys: Array = at.keys()
	keys.sort()
	var out: Array = []
	for i in keys:
		out.append([i, at[i]])
	for i in range(1, out.size()):
		var rise: float = out[i][1] - out[i - 1][1]
		var slope: float = rise / (out[i][0] - out[i - 1][0])
		if rise <= 0.0 or slope < SLOPE[0] or slope > SLOPE[1]:
			return []
	for i in xs:
		if not at.has(i):
			return []
	return out


## The knots joined by a monotone curve: a cubic on each stretch, with gradients that can't
## overshoot. Every knot is a point of the sample.
static func smooth(knots: Array) -> Array:
	var m := knots.size()
	var sec: Array = []
	for i in m - 1:
		sec.append(float(knots[i + 1][1] - knots[i][1]) / (knots[i + 1][0] - knots[i][0]))
	var grad: Array = [sec[0] * 0.5]
	for i in range(1, m - 1):
		grad.append(2.0 * sec[i - 1] * sec[i] / (sec[i - 1] + sec[i]))
	grad.append(sec[m - 2] * 0.5)
	var out: Array = []
	for i in m - 1:
		var w: float = knots[i + 1][0] - knots[i][0]
		out.append([float(knots[i][0]), float(knots[i][1])])
		for k in range(1, SAMPLES):
			var t := float(k) / SAMPLES
			var y: float = (2.0 * t * t * t - 3.0 * t * t + 1.0) * knots[i][1] + (t * t * t - 2.0 * t * t + t) * w * grad[i] \
				+ (3.0 * t * t - 2.0 * t * t * t) * knots[i + 1][1] + (t * t * t - t * t) * w * grad[i + 1]
			out.append([knots[i][0] + t * w, y])
	out.append([float(knots[m - 1][0]), float(knots[m - 1][1])])
	return out


## The x of a knot at height y, or -1.
static func x_at(s: Dictionary, y: int) -> int:
	for p in s.knots:
		if p[1] == y:
			return p[0]
	return -1


## The height of a knot at x, or -1.
static func y_at(s: Dictionary, x: int) -> int:
	for p in s.knots:
		if p[0] == x:
			return p[1]
	return -1


## Classes along the curve: boundaries at its ends and at some knots, two squares apart or more.
static func _classes(rng: Seeded, s: Dictionary) -> bool:
	var inner: Array = s.knots.slice(1, -1)
	var picks: Array = []
	for p in rng.shuffled(inner):
		if picks.size() < 3 and picks.all(func(q): return absi(q[0] - p[0]) >= 2 * s.dx):
			picks.append(p)
	picks.sort_custom(func(a, b): return a[0] < b[0])
	var last: Array = s.knots[-1]
	var points: Array = picks + [last]
	s.bs = [s.knots[0][0]] + points.map(func(p): return p[0])
	s.cf = points.map(func(p): return p[1])
	s.fs = frequencies(s.cf)
	return picks.size() == 3 and s.bs[1] - s.bs[0] >= 2 * s.dx and s.bs[4] - s.bs[3] >= 2 * s.dx


static func frequencies(cf: Array) -> Array:
	var out: Array = [cf[0]]
	for i in range(1, cf.size()):
		out.append(cf[i] - cf[i - 1])
	return out


static func _graph_ask(rng: Seeded, s: Dictionary) -> bool:
	var inner: Array = s.knots.slice(1, -1)
	match s.ask:
		"quartile-from-graph":
			s.which = "Q1" if rng.chance(0.5) else "Q3"
		"count-below", "count-above", "percent-above", "percentile-of-value", "scale-to-population":
			s.v = rng.pick(inner)[0]
			s.r = rng.int_in(2, 6)
		"count-between":
			var a: Array = rng.shuffled(inner)
			s.v = mini(a[0][0], a[1][0])
			s.v2 = maxi(a[0][0], a[1][0])
		"share-of-limit":
			s.v = cut(s.pct * SQUARES * s.dx, 100)
			return y_at(s, s.v) > 0 and y_at(s, s.v) < s.n
		"frequency-from-graph":
			s.j = rng.int_in(1, s.fs.size() - 1)
		"p-q-from-graph":
			s.j = rng.int_in(0, 1)
			s.j2 = rng.int_in(s.j + 1, s.fs.size() - 1)
			return s.fs[s.j] != s.fs[s.j2]
	return true


# ── A table ──────────────────────────────────────────────────

static func _table(rng: Seeded, s: Dictionary) -> bool:
	s.n = rng.pick(TABLE_TOTALS)
	var w: int = 5 * s.dx
	var k := rng.int_in(4, 5)
	var first: int = rng.int_in(1, 2) * w if s.ask == "curve-start" or rng.chance(0.2) else 0
	var fs: Array = []
	var left: int = s.n
	var most := cut(2 * s.n, k)
	for i in k - 1:
		var f := rng.int_in(2, most)
		fs.append(f)
		left -= f
	if left < 2 or left > most:
		return false
	fs.append(left)
	s.fs = fs
	s.bs = []
	for i in k + 1:
		s.bs.append(first + i * w)
	s.cf = []
	var run := 0
	for f in fs:
		run += f
		s.cf.append(run)
	return _table_ask(rng, s)


## The value at cumulative frequency t, by straight lines through the classes.
static func interp(s: Dictionary, t: int) -> Q:
	for j in s.fs.size():
		if t <= s.cf[j]:
			var before: int = s.cf[j] - s.fs[j]
			return Q.new(s.bs[j]).add(Q.new((t - before) * (s.bs[j + 1] - s.bs[j]), s.fs[j]))
	return Q.new(s.bs[-1])


## The cumulative frequency at value v, by straight lines through the classes.
static func count_at(s: Dictionary, v: int) -> Q:
	for j in s.fs.size():
		if v <= s.bs[j + 1]:
			var before: int = s.cf[j] - s.fs[j]
			return Q.new(before).add(Q.new(s.fs[j] * (v - s.bs[j]), s.bs[j + 1] - s.bs[j]))
	return Q.new(s.n)


## An estimate ends in at most one decimal, and t is inside a class.
static func clean(s: Dictionary, t: int) -> bool:
	return t > 0 and t < s.n and not t in s.cf and Q.new(10).mul(interp(s, t)).is_int()


## A value inside a class, on a whole square of a curve's grid, with a whole count.
static func _value_in_class(rng: Seeded, s: Dictionary) -> int:
	var j := rng.int_in(0, s.fs.size() - 1)
	var v: int = s.bs[j] + rng.int_in(1, 4) * s.dx
	return v if count_at(s, v).is_int() else -1


static func _table_ask(rng: Seeded, s: Dictionary) -> bool:
	var n: int = s.n
	match s.ask:
		"median-from-table":
			return clean(s, cut(n, 2))
		"quartile-from-table":
			s.which = "Q1" if rng.chance(0.5) else "Q3"
			return clean(s, cut(n, 4) if s.which == "Q1" else 3 * cut(n, 4))
		"iqr-from-table":
			return clean(s, cut(n, 4)) and clean(s, 3 * cut(n, 4))
		"percentile-from-table":
			s.pct = rng.pick(PERCENTS)
			return n != 100 and clean(s, cut(s.pct * n, 100)) and s.pct < n and clean(s, s.pct)
		"count-below-table", "count-above-table":
			s.v = _value_in_class(rng, s)
			return s.v > 0
		"count-between-table":
			s.v = _value_in_class(rng, s)
			s.v2 = _value_in_class(rng, s)
			return s.v > 0 and s.v < s.v2
		"cutoff-table":
			s.top = rng.int_in(1, 7) * cut(n, 20)
			return clean(s, n - s.top) and clean(s, s.top) and s.top != cut(n, 2)
		"cf-entry", "frequency-from-cf", "plot-point":
			s.j = rng.int_in(1, s.fs.size() - 1)
		"last-frequency":
			s.j = rng.int_in(0, s.fs.size() - 1)
		"pick-curve":
			# A graph with its cumulative frequencies at the midpoints starts inside the window,
			# and the frequencies alone must stop short of n.
			return s.fs.size() == 4 and s.fs.max() < n - s.fs[0] and s.cf[0] > 2
	return true


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
