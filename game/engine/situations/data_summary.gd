class_name DataSummarySituation
extends RefCounted
## The `data-summary` situation (curriculum/question-types.json): one discrete data set,
## shown as a list or as a frequency table, and the numbers that summarise it (FAL-695).
## Everything is exact: the data are whole numbers (one decimal for the outlier stories),
## so a mean, a median and a quartile are Q, never a float. The SymPy checker reads the
## data back from what is shown and finds each one again.
##
## need.ask is the unknown, need.rep "terms" (a list) or "table" (a frequency table) where
## the unknown has both, need.paper 1 or 2:
##   mean-of-data          Paper 1: the mean ends in at most one decimal. Paper 2: it needs
##                         rounding (3 s.f.), clear of a rounding edge
##   median-of-data        an odd or an even number of values
##   mode-of-data          one mode, strictly the most frequent, and not equal to its count
##   range-of-data         largest minus smallest
##   quartiles-of-data     Q1 and Q3, each the median of its half (the median itself left out
##                         when n is odd); Q1 < Q3
##   iqr-of-data           Q3 - Q1
##   missing-value-from-mean   rep "terms" or "words": the mean of n values is M; one is k
##   missing-frequency-from-mean   rep "table": the mean of the data is M; one frequency is p
##   combined-mean         two groups of different sizes and different means
##   choose-average        a list with a high outlier: the best measure of the centre
##   choose-spread         the same list: the measure of spread the outlier leaves alone
##
## generate() returns a Dictionary:
##   paper, ask, rep
##   xs     the values as shown: a list (unordered) or a table's values (ascending)
##   fs     the table's frequencies as ints (the unknown one is still its value), [] for a list
##   data   every value, ascending (a table's expanded)
##   n      how many values;  mean, median, q1, q3  Q;  mode, mode_count  for mode-of-data
##   k      the missing value, p the missing frequency (Q);  at  the index of the missing one
##   ctx    the story (an index into DataSummaryViews.CONTEXTS / GROUPS / SPREADS)
##   n1, m1, n2, m2  the two groups of a combined mean
##
## The clean limits below are the numbers behind the catalogue's `clean` text. The SymPy
## checker (tools/check_answers.py) holds its own copy and fails on any breach.

const TRIES := 4000
## A Paper 2 mean is at least this far (in units of its 3rd figure) from a rounding edge:
## Answer.rounds_clearly.
const EDGE := 0.03
const CONTEXTS := 6
const GROUPS := 5
const OUTLIERS := 6
## What a paper's data look like. A list: [n_lo, n_hi, v_lo, v_hi]. A table: [values_lo,
## values_hi, v_lo, v_hi, f_max, total_lo, total_hi]. Paper 1 has small whole numbers a
## student adds by hand; Paper 2 has larger ones for the GDC.
const LIST_1 := [5, 10, 1, 15]
const LIST_2 := [10, 16, 10, 60]
const TABLE_1 := [4, 6, 1, 15, 7, 8, 24]
const TABLE_2 := [5, 8, 10, 60, 12, 25, 60]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "mean-of-data")
	var rep: String = need.get("rep", "terms")
	var paper: int = int(need.get("paper", 1))
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "ctx": 0, "xs": [], "fs": [], "data": [], "n": 0, "at": 0}
		var ok := false
		match ask:
			"mean-of-data":
				ok = _mean(rng, s)
			"median-of-data":
				ok = _dataset(rng, s, 5 if paper == 1 else 11, 11 if paper == 1 else 18)
			"mode-of-data":
				ok = _mode(rng, s)
			"range-of-data":
				ok = _dataset(rng, s) and range_of(s.data).sign() > 0
			"quartiles-of-data", "iqr-of-data":
				ok = _quartiles(rng, s)
			"missing-value-from-mean":
				ok = _missing_value(rng, s)
			"missing-frequency-from-mean":
				ok = _missing_frequency(rng, s)
			"combined-mean":
				ok = _combined(rng, s)
			"choose-average", "choose-spread":
				ok = _outlier(rng, s)
		if ok:
			return s
	return {}


# ── The data ─────────────────────────────────────────────────

static func Qi(v: int) -> Q:
	return Q.new(v)


## A list of n whole numbers from lo to hi, in a shuffled order.
static func _list(rng: Seeded, s: Dictionary, n: int, lo: int, hi: int) -> void:
	var xs: Array = []
	for i in n:
		xs.append(Qi(rng.int_in(lo, hi)))
	s.xs = xs
	s.fs = []
	s.data = sorted(xs)
	s.n = n


## A table of m distinct whole numbers from lo to hi, ascending, with frequencies 1 to f_max.
static func _table(rng: Seeded, s: Dictionary, m: int, lo: int, hi: int, f_max: int) -> void:
	var pool: Array = []
	for v in range(lo, hi + 1):
		pool.append(v)
	var picks: Array = rng.shuffled(pool).slice(0, m)
	picks.sort()
	var xs: Array = []
	var fs: Array = []
	for v in picks:
		xs.append(Qi(v))
		fs.append(rng.int_in(1, f_max))
	s.xs = xs
	s.fs = fs
	s.data = expand(xs, fs)
	s.n = s.data.size()


## The list or table for the rep and paper (LIST_1 .. TABLE_2). n_lo and n_hi override a
## list's size, v_hi its largest value (a smaller range makes a mode likelier).
static func _dataset(rng: Seeded, s: Dictionary, n_lo: int = -1, n_hi: int = -1, v_hi: int = -1) -> bool:
	var p2: bool = s.paper == 2
	if s.rep == "table":
		var t: Array = TABLE_2 if p2 else TABLE_1
		_table(rng, s, rng.int_in(t[0], t[1]), t[2], v_hi if v_hi > 0 else t[3], t[4])
		return s.n >= t[5] and s.n <= t[6]
	var l: Array = LIST_2 if p2 else LIST_1
	_list(rng, s, rng.int_in(n_lo if n_lo > 0 else l[0], n_hi if n_hi > 0 else l[1]), l[2], v_hi if v_hi > 0 else l[3])
	return _unsorted(s)


## A list shown in an order other than ascending, so putting it in order is a step.
static func _unsorted(s: Dictionary) -> bool:
	if s.rep == "table":
		return true
	for i in s.xs.size():
		if not s.xs[i].eq(s.data[i]):
			return true
	return false


static func _mean(rng: Seeded, s: Dictionary) -> bool:
	var p2: bool = s.paper == 2
	if not _dataset(rng, s, 5 if not p2 else 10, 10 if not p2 else 16):
		return false
	s.mean = mean_of(s.data)
	if p2:
		return Answer.needs_rounding(s.mean) and Answer.rounds_clearly(s.mean.to_float(), EDGE)
	return ends_in_one_place(s.mean)


static func _mode(rng: Seeded, s: Dictionary) -> bool:
	var p2: bool = s.paper == 2
	if not _dataset(rng, s, 7 if not p2 else 12, 11 if not p2 else 16, 12 if not p2 else 40):
		return false
	var m := mode_of(s.xs, s.fs)
	if not m.unique or m.count < 2 or Qi(m.count).eq(m.value):
		return false
	s.mode = m.value
	s.mode_count = m.count
	return true


static func _quartiles(rng: Seeded, s: Dictionary) -> bool:
	var p2: bool = s.paper == 2
	if not _dataset(rng, s, 7 if not p2 else 11, 11 if not p2 else 17):
		return false
	var qs := quartiles(s.data)
	s.q1 = qs[0]
	s.q3 = qs[1]
	return s.q1.lt(s.q3)


## k is the missing value in a list whose mean is M, M ending in at most one decimal.
static func _missing_value(rng: Seeded, s: Dictionary) -> bool:
	var n := rng.int_in(4, 7)
	var xs: Array = []
	for i in n:
		xs.append(Qi(rng.int_in(2, 40)))
	s.at = rng.int_in(0, n - 1)
	s.k = xs[s.at]
	s.xs = xs
	s.fs = []
	s.data = sorted(xs)
	s.n = n
	s.mean = mean_of(xs)
	s.ctx = rng.int_in(0, CONTEXTS - 1)
	# k differs from the mean, so the deviations balance round something; no two values
	# are alike enough to make the story read oddly.
	return ends_in_one_place(s.mean) and not s.k.eq(s.mean)


## The table has one frequency p (an unknown), and the mean of the data is M.
static func _missing_frequency(rng: Seeded, s: Dictionary) -> bool:
	var m := rng.int_in(4, 5)
	var first := rng.int_in(1, 6)
	var xs: Array = []
	var fs: Array = []
	for i in m:
		xs.append(Qi(first + i))
		fs.append(rng.int_in(2, 9))
	s.at = rng.int_in(0, m - 1)
	var p: int = rng.int_in(2, 9)
	fs[s.at] = p
	s.p = Qi(p)
	s.xs = xs
	s.fs = fs
	s.data = expand(xs, fs)
	s.n = s.data.size()
	s.mean = mean_of(s.data)
	# M is between the least and greatest value and not the value of the missing column
	# (that would make p anything), and the whole table stays small.
	return ends_in_one_place(s.mean) and not s.mean.eq(xs[s.at]) and s.n <= 40 and s.mean.lt(xs[m - 1]) and xs[0].lt(s.mean)


static func _combined(rng: Seeded, s: Dictionary) -> bool:
	s.n1 = rng.int_in(6, 30)
	s.n2 = rng.int_in(6, 30)
	s.m1 = rng.int_in(10, 90)
	s.m2 = rng.int_in(10, 90)
	s.ctx = rng.int_in(0, GROUPS - 1)
	s.n = s.n1 + s.n2
	if s.n1 == s.n2 or s.m1 == s.m2:
		return false
	s.mean = combined_mean(s)
	return ends_in_one_place(s.mean)


## A list of eight lengths with one far above the rest: the mean is well above the median.
## The values have one decimal and no two alike, so there is no mode worth the name.
static func _outlier(rng: Seeded, s: Dictionary) -> bool:
	var xs: Array = []
	var seen := {}
	while xs.size() < 7:
		var t := rng.int_in(40, 120)
		if not seen.has(t):
			seen[t] = true
			xs.append(Q.new(t, 10))
	var big := rng.int_in(300, 600)
	if seen.has(big):
		return false
	xs.append(Q.new(big, 10))
	s.xs = rng.shuffled(xs)
	s.fs = []
	s.data = sorted(xs)
	s.n = 8
	s.ctx = rng.int_in(0, OUTLIERS - 1)
	s.mean = mean_of(xs)
	s.median = median_of(s.data)
	# The outlier drags the mean at least 40% above the median, and the range is more than
	# double the interquartile range.
	var qs := quartiles(s.data)
	s.q1 = qs[0]
	s.q3 = qs[1]
	return s.mean.to_float() >= 1.4 * s.median.to_float() and range_of(s.data).to_float() > 2.0 * s.q3.sub(s.q1).to_float() \
			and _unsorted(s)


# ── The numbers ──────────────────────────────────────────────

## The values in ascending order.
static func sorted(xs: Array) -> Array:
	var out := xs.duplicate()
	out.sort_custom(func(a, b): return a.lt(b))
	return out


## A table's values, each repeated by its frequency, in ascending order.
static func expand(xs: Array, fs: Array) -> Array:
	var out: Array = []
	for i in xs.size():
		for j in int(fs[i]):
			out.append(xs[i])
	return out


static func total_of(xs: Array) -> Q:
	var t := Qi(0)
	for x in xs:
		t = t.add(x)
	return t


static func mean_of(xs: Array) -> Q:
	return total_of(xs).div(Qi(xs.size()))


## n / 2, rounded down.
@warning_ignore("integer_division")
static func half(n: int) -> int:
	return n / 2


## The median of values already in ascending order.
static func median_of(sorted_xs: Array) -> Q:
	var n := sorted_xs.size()
	if n % 2 == 1:
		return sorted_xs[half(n)]
	return sorted_xs[half(n) - 1].add(sorted_xs[half(n)]).div(Qi(2))


## [Q1, Q3] of values in ascending order: the median of each half, the median left out
## when n is odd. This is the method the IB's GDCs use.
static func quartiles(sorted_xs: Array) -> Array:
	var n := sorted_xs.size()
	var h := half(n)
	var lower := sorted_xs.slice(0, h)
	var upper := sorted_xs.slice(h + (n % 2), n)
	return [median_of(lower), median_of(upper)]


static func range_of(sorted_xs: Array) -> Q:
	return sorted_xs[sorted_xs.size() - 1].sub(sorted_xs[0])


## {"value", "count", "unique"}: the most frequent value of a list (fs empty) or a table.
static func mode_of(xs: Array, fs: Array) -> Dictionary:
	var counts: Dictionary = {}
	var order: Array = []
	for i in xs.size():
		var key: String = xs[i].key()
		if not counts.has(key):
			counts[key] = 0
			order.append(xs[i])
		counts[key] += int(fs[i]) if not fs.is_empty() else 1
	var best: Q = order[0]
	var best_count: int = counts[best.key()]
	var unique := true
	for v in order.slice(1):
		var c: int = counts[v.key()]
		if c > best_count:
			best = v
			best_count = c
			unique = true
		elif c == best_count:
			unique = false
	return {"value": best, "count": best_count, "unique": unique}


## The mean of two groups: (n1 m1 + n2 m2) / (n1 + n2).
static func combined_mean(s: Dictionary) -> Q:
	return Qi(s.n1 * s.m1 + s.n2 * s.m2).div(Qi(s.n1 + s.n2))


## The standard deviation of the data, as a float (the population one, as a GDC's σx).
static func sd_of(xs: Array) -> float:
	var m := mean_of(xs).to_float()
	var t := 0.0
	for x in xs:
		t += (x.to_float() - m) * (x.to_float() - m)
	return sqrt(t / xs.size())


## True when v is a whole number or ends in one decimal place: a mean a Paper 1 can reach
## by hand.
static func ends_in_one_place(v: Q) -> bool:
	return Qi(10).mul(v).is_int()


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
