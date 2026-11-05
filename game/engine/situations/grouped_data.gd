class_name GroupedDataSituation
extends RefCounted
## The `grouped-data` situation (curriculum/question-types.json): a frequency table, grouped into
## classes or of single values, a small list, or the sizes and means of a few groups (FAL-740).
## The table comes first and everything else is worked out of it, so a mean, a variance and a
## missing frequency are exact Q. Only a standard deviation that is not a perfect square is a
## long decimal (`root`), written to 3 s.f. A mid-interval value stands in for its class.
##
## need.ask is the unknown (see GroupedDataViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx
##   lo, hi       a grouped table's class boundaries, ints; closed "lo" or "hi" says which end
##                is ≤ ("lo": lo ≤ t < hi)
##   xs           the mid-interval values, or a discrete table's or a list's values, Q
##   fs           the frequencies, Q (tenths when `thousands`, a head in thousands)
##   at, at2      the row that is missing, or asked about
##   p, q         the missing frequencies; k the missing value
##   n, fx, fx2   Σf, Σfx and Σfx²;  mean, variance  Q
##   sd           the standard deviation: exact if it is, else `root`
##   big          a modal question: the row of the greatest frequency
##   mid          a modal question: the row of the class that holds the median, or -1
##   p_top        modal-class-after-frequency: whether the missing frequency is the greatest,
##                a fair coin drawn before anything else
##   total_row    a table shows its total in a row of its own, else in a line
##   step         a discrete table's gap between values
##   cut          missing-frequency-from-median: the median is halfway between rows cut, cut + 1
##   sizes, means the groups of a mean-of-groups question;  whole  the whole group's mean
##   old, new     new-value-from-new-mean: the mean before and after;  count  the values before
##   sd1, sd2, m1, m2, first   interpret-sd: the two groups; `first` is the one with the larger sd
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 12000
const EDGE := 0.03
## The class widths each story can take, so a rat is never two metres long.
const WIDTHS := [[10, 20, 50], [5], [5, 10, 20], [5, 10], [10, 20, 50], [5, 10, 20]]
const P1_TOTALS := [10, 20, 25, 40, 50, 100]
const P1_RANGE := [10, 40]
const P2_RANGE := [30, 150]
## Paper 2's grouped tables may run in thousands, one decimal place, as a very big count would.
const THOUSANDS_CHANCE := 0.3
const STEPS := [1, 1, 2, 5]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "estimate-mean")
	var rep: String = need.get("rep", "table")
	var paper: int = int(need.get("paper", 1))
	# Drawn once, so a filter below can't favour one case.
	var p_top := rng.chance(0.5)
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "ctx": rng.int_in(0, 5), "at": 0, "at2": 0, "p_top": p_top, "thousands": false,
			"total_row": rng.chance(0.5), "closed": "lo"}
		var ok := false
		match ask:
			"modal-class":
				ok = _modal(rng, s)
			"modal-class-after-frequency":
				ok = _modal_missing(rng, s)
			"mid-interval-value":
				ok = _mid_one(rng, s)
			"mid-interval-list":
				ok = _mid_list(rng, s)
			"estimate-mean":
				ok = _estimate(rng, s)
			"estimate-why":
				ok = _estimate(rng, s)
			"estimate-sd", "estimate-variance":
				ok = _estimate_spread(rng, s)
			"sd-from-table", "variance-from-table":
				ok = _spread_table(rng, s)
			"sd-of-small-set":
				ok = _small(rng, s, true)
			"variance-of-small-set":
				ok = _small(rng, s, false)
			"variance-from-sd":
				ok = _variance_from_sd(rng, s)
			"sd-from-variance":
				ok = _sd_from_variance(rng, s)
			"interpret-sd":
				ok = _interpret(rng, s)
			"missing-frequency-from-total":
				ok = _missing_total(rng, s)
			"missing-frequency-from-estimate":
				ok = _missing_estimate(rng, s)
			"two-frequencies-from-mean":
				ok = _two_frequencies(rng, s)
			"missing-frequency-from-median":
				ok = _missing_median(rng, s)
			"missing-value-from-table-mean":
				ok = _missing_value(rng, s)
			"new-value-from-new-mean":
				ok = _new_value(rng, s)
			"whole-mean-from-groups":
				ok = _whole_mean(rng, s)
			"whole-total-from-groups":
				ok = _whole_total(rng, s)
			"group-mean-from-whole":
				ok = _group_mean(rng, s)
		if ok:
			return s
	return {}


# ── Numbers ──────────────────────────────────────────────────

## Ends within `places` decimal places.
static func ends(v: Q, places: int) -> bool:
	var scale := 1
	for i in places:
		scale *= 10
	return v.mul(Q.new(scale)).is_int()


## Exact as written, or to 3 s.f. clear of a rounding edge.
static func fits(v: Q) -> bool:
	return not Answer.needs_rounding(v) or Answer.rounds_clearly(v.to_float(), EDGE)


static func int_root(n: int) -> int:
	var r := roundi(sqrt(float(n)))
	return r if n >= 0 and r * r == n else -1


## √v: exact where v is a square, else to 8 decimal places, which is only ever shown to 3 s.f.
static func root(v: Q) -> Q:
	var a := int_root(v.n)
	var b := int_root(v.d)
	if a >= 0 and b > 0:
		return Q.new(a, b)
	return Q.new(roundi(sqrt(v.to_float()) * 100000000.0), 100000000)


## Two values that a 3 s.f. reader can tell apart.
static func apart(a: Q, b: Q) -> bool:
	return Fmt.sf(a) != Fmt.sf(b)


## Σf, Σfx, Σfx², the mean and the variance of the table.
static func stats(s: Dictionary) -> void:
	var n := Q.new(0)
	var fx := Q.new(0)
	var fx2 := Q.new(0)
	for i in s.xs.size():
		var f: Q = s.fs[i]
		var x: Q = s.xs[i]
		n = n.add(f)
		fx = fx.add(f.mul(x))
		fx2 = fx2.add(f.mul(x).mul(x))
	s.n = n
	s.fx = fx
	s.fx2 = fx2
	s.mean = fx.div(n)
	s.variance = fx2.div(n).sub(s.mean.mul(s.mean))
	s.sd = root(s.variance)


## The standard deviation with the frequencies as a sample's: Sx, which divides by n − 1.
static func sample_sd(s: Dictionary) -> Q:
	return root(sample_variance(s))


static func sample_variance(s: Dictionary) -> Q:
	return s.variance.mul(s.n).div(s.n.sub(Q.new(1)))


## σ of `xs` taken once each: the mid-interval values or values with the frequencies left out.
static func flat_variance(xs: Array) -> Q:
	var sum := Q.new(0)
	var sq := Q.new(0)
	for x: Q in xs:
		sum = sum.add(x)
		sq = sq.add(x.mul(x))
	var k := Q.new(xs.size())
	var m := sum.div(k)
	return sq.div(k).sub(m.mul(m))


# ── The tables ───────────────────────────────────────────────

## k classes from a start that is a multiple of the width. Unequal classes are one or two widths.
static func _classes(rng: Seeded, s: Dictionary, equal: bool, k_lo: int = 4, k_hi: int = 5) -> bool:
	var k := rng.int_in(k_lo, k_hi)
	var w: int = rng.pick(WIDTHS[s.ctx])
	var a := w * rng.int_in(1, 4)
	s.closed = rng.pick(["lo", "hi"])
	var lo: Array = []
	var hi: Array = []
	var xs: Array = []
	var seen := {}
	for i in k:
		var width := w * 2 if not equal and rng.chance(0.5) else w
		seen[width] = true
		lo.append(a)
		hi.append(a + width)
		xs.append(Q.new(2 * a + width, 2))
		a += width
	s.lo = lo
	s.hi = hi
	s.xs = xs
	return equal or seen.size() == 2


## Frequencies that add to the total, each at least lowest.
static func _share(rng: Seeded, s: Dictionary, total: int, lowest: int = 1) -> bool:
	var k: int = s.xs.size()
	var fs: Array = []
	var left := total
	for i in k - 1:
		var most := left - lowest * (k - 1 - i)
		if most < lowest:
			return false
		var f := rng.int_in(lowest, mini(most, total * 2 / k))
		fs.append(Q.new(f))
		left -= f
	if left < lowest:
		return false
	fs.append(Q.new(left))
	s.fs = rng.shuffled(fs)
	return true


static func _total(rng: Seeded, s: Dictionary) -> int:
	if s.paper == 1:
		return rng.pick(P1_TOTALS)
	return rng.int_in(P2_RANGE[0], P2_RANGE[1])


## A table of single values: consecutive, or a step apart.
static func _discrete(rng: Seeded, s: Dictionary, m_lo: int = 5, m_hi: int = 6, step_given: int = 0) -> void:
	var m := rng.int_in(m_lo, m_hi)
	s.step = step_given if step_given > 0 else rng.pick(STEPS)
	var a: int = rng.int_in(1, 4) * s.step
	var xs: Array = []
	for i in m:
		xs.append(Q.new(a + i * s.step))
	s.xs = xs
	s.lo = []
	s.hi = []


## The row of the strictly greatest frequency, or -1.
static func top_row(fs: Array) -> int:
	var best := -1
	var tied := false
	for i in fs.size():
		if best < 0 or fs[best].lt(fs[i]):
			best = i
			tied = false
		elif fs[i].eq(fs[best]):
			tied = true
	return -1 if tied else best


## The row of the class that holds the median, or -1 if the two middle values split across rows.
static func median_row(fs: Array) -> int:
	var total := 0
	for f: Q in fs:
		total += f.n
	var low := (total + 1) / 2
	var high := (total + 2) / 2
	var run := 0
	for i in fs.size():
		var next: int = run + fs[i].n
		if low > run and low <= next:
			return i if high <= next else -1
		run = next
	return -1


static func _modal(rng: Seeded, s: Dictionary) -> bool:
	if not _classes(rng, s, true) or not _share(rng, s, _total(rng, s)):
		return false
	s.big = top_row(s.fs)
	s.mid = median_row(s.fs)
	stats(s)
	return s.big >= 0 and s.mid >= 0 and s.big != s.mid


## One frequency missing, found from the total. On a coin it is the greatest, and the class it
## hides is the modal one; otherwise the known rows hold the modal class.
static func _modal_missing(rng: Seeded, s: Dictionary) -> bool:
	if not _classes(rng, s, true) or not _share(rng, s, _total(rng, s)):
		return false
	s.big = top_row(s.fs)
	s.mid = median_row(s.fs)
	if s.big < 0:
		return false
	if s.p_top:
		s.at = s.big
		var rest: Array = s.fs.duplicate()
		rest[s.at] = Q.new(0)
		s.known_top = top_row(rest)
		if s.known_top < 0:
			return false
	else:
		s.at = rng.int_in(0, s.fs.size() - 1)
		s.known_top = s.big
		if s.at == s.big:
			return false
	s.p = s.fs[s.at]
	stats(s)
	return true


static func _mid_one(rng: Seeded, s: Dictionary) -> bool:
	if not _classes(rng, s, rng.chance(0.4)) or not _share(rng, s, _total(rng, s)):
		return false
	s.at = rng.int_in(0, s.xs.size() - 1)
	stats(s)
	return true


## Unequal classes, so stepping along by the first width goes wrong.
static func _mid_list(rng: Seeded, s: Dictionary) -> bool:
	if not _classes(rng, s, false) or not _share(rng, s, _total(rng, s)):
		return false
	_maybe_thousands(rng, s)
	stats(s)
	return s.hi[1] - s.lo[1] != s.hi[0] - s.lo[0] or s.hi[2] - s.lo[2] != s.hi[0] - s.lo[0]


## Paper 2 only: the frequencies become tenths, as a head in thousands.
static func _maybe_thousands(rng: Seeded, s: Dictionary) -> void:
	if s.paper == 2 and rng.chance(THOUSANDS_CHANCE):
		s.thousands = true
		s.fs = s.fs.map(func(f): return f.mul(Q.new(rng.int_in(5, 13), 10)))


static func _estimate(rng: Seeded, s: Dictionary) -> bool:
	if not _classes(rng, s, rng.chance(0.5)) or not _share(rng, s, _total(rng, s)):
		return false
	_maybe_thousands(rng, s)
	stats(s)
	if s.paper == 1:
		return ends(s.mean, 2)
	return Answer.needs_rounding(s.mean) and fits(s.mean)


static func _estimate_spread(rng: Seeded, s: Dictionary) -> bool:
	if not _classes(rng, s, rng.chance(0.5)) or not _share(rng, s, _total(rng, s)):
		return false
	_maybe_thousands(rng, s)
	stats(s)
	if s.thousands:
		return Answer.needs_rounding(s.mean) and fits(s.mean) and fits(s.variance) and fits(s.sd)
	return fits(s.mean) and fits(s.variance) and fits(s.sd) and apart(s.sd, sample_sd(s)) and apart(s.variance, sample_variance(s))


static func _spread_table(rng: Seeded, s: Dictionary) -> bool:
	_discrete(rng, s)
	if not _share(rng, s, rng.int_in(13, 40)):
		return false
	stats(s)
	return Answer.needs_rounding(s.mean) and fits(s.mean) and fits(s.variance) and fits(s.sd) and apart(s.sd, sample_sd(s)) \
			and apart(s.variance, sample_variance(s))


## A small list with a whole mean. On Paper 1 the sd is whole, or the variance ends.
static func _small(rng: Seeded, s: Dictionary, want_sd: bool) -> bool:
	var count := rng.int_in(4, 6) if s.paper == 1 else rng.int_in(5, 8)
	var m := rng.int_in(6, 18)
	var ds: Array = []
	var sum := 0
	for i in count - 1:
		var d := rng.int_in(-6, 6)
		ds.append(d)
		sum += d
	ds.append(-sum)
	var sq := 0
	var seen := {}
	for d in ds:
		if m + d < 1 or absi(d) > 9:
			return false
		sq += d * d
		seen[d] = true
	if seen.size() < 3:
		return false
	s.xs = rng.shuffled(ds).map(func(d): return Q.new(m + d))
	s.fs = s.xs.map(func(_x): return Q.new(1))
	stats(s)
	if s.paper == 1:
		if want_sd:
			return s.sd.is_int() and not s.sd.is_zero() and s.variance.d == 1
		return ends(s.variance, 2)
	return fits(s.variance) and fits(s.sd) and (Answer.needs_rounding(s.sd) if want_sd else true)


static func _variance_from_sd(rng: Seeded, s: Dictionary) -> bool:
	if s.paper == 1:
		s.sd = Q.new(rng.int_in(12, 95), 10)
	else:
		s.sd = Q.new(rng.int_in(120, 2500), 100)
	s.variance = s.sd.mul(s.sd)
	if s.paper == 2:
		return not s.sd.is_int() and Answer.needs_rounding(s.variance) and fits(s.variance)
	return not s.sd.is_int()


static func _sd_from_variance(rng: Seeded, s: Dictionary) -> bool:
	if s.paper == 1:
		s.sd = Q.new(rng.int_in(3, 26) * 5, 10)
		s.variance = s.sd.mul(s.sd)
		return ends(s.variance, 2)
	s.variance = Q.new(rng.int_in(150, 9000), 10)
	s.sd = root(s.variance)
	return Answer.needs_rounding(s.sd) and fits(s.sd)


## Two groups. The one with the larger sd has the smaller mean, so the two can't be confused.
static func _interpret(rng: Seeded, s: Dictionary) -> bool:
	s.ctx = rng.int_in(0, 3)
	var low := rng.int_in(20, 60)
	var high := low + rng.int_in(4, 30)
	var small := rng.int_in(2, 9)
	var large := small + rng.int_in(3, 12)
	s.first = rng.chance(0.5)
	if s.first:
		s.m1 = low
		s.sd1 = large
		s.m2 = high
		s.sd2 = small
	else:
		s.m1 = high
		s.sd1 = small
		s.m2 = low
		s.sd2 = large
	return true


static func _missing_total(rng: Seeded, s: Dictionary) -> bool:
	if not _classes(rng, s, rng.chance(0.5)) or not _share(rng, s, _total(rng, s)):
		return false
	s.at = rng.int_in(0, s.xs.size() - 1)
	s.p = s.fs[s.at]
	stats(s)
	# The sum of the known rows and the answer must read differently.
	return not s.n.sub(s.p).eq(s.p)


static func _missing_estimate(rng: Seeded, s: Dictionary) -> bool:
	if not _classes(rng, s, rng.chance(0.5), 4, 4) or not _share(rng, s, _total(rng, s)):
		return false
	s.at = rng.int_in(0, s.xs.size() - 1)
	s.p = s.fs[s.at]
	stats(s)
	return ends(s.mean, 1 if s.paper == 1 else 2) and not s.mean.eq(s.xs[s.at]) and s.p.n >= 2


static func _two_frequencies(rng: Seeded, s: Dictionary) -> bool:
	_discrete(rng, s, 5, 6, 1)
	if not _share(rng, s, rng.int_in(12, 30)):
		return false
	var m: int = s.xs.size()
	s.at = rng.int_in(0, m - 2)
	s.at2 = rng.int_in(s.at + 1, m - 1)
	s.p = s.fs[s.at]
	s.q = s.fs[s.at2]
	stats(s)
	return ends(s.mean, 1) and not s.p.eq(s.q) and not s.xs[s.at].eq(s.mean) and not s.xs[s.at2].eq(s.mean)


static func _missing_median(rng: Seeded, s: Dictionary) -> bool:
	_discrete(rng, s, 5, 6)
	var m: int = s.xs.size()
	s.cut = rng.int_in(1, m - 3)
	var fs: Array = []
	for i in m:
		fs.append(Q.new(rng.int_in(1, 8)))
	var low := 0
	var high := 0
	for i in m:
		if i <= s.cut:
			low += fs[i].n
		else:
			high += fs[i].n
	# The row with x sits on the side that needs it, with another known row beside it.
	var upper := rng.chance(0.7)
	s.at = rng.int_in(s.cut + 1, m - 1) if upper else rng.int_in(0, s.cut)
	var side: int = m - s.cut - 1 if upper else s.cut + 1
	var x: int = (low - (high - fs[s.at].n)) if upper else (high - (low - fs[s.at].n))
	if side < 2 or x < 1 or x > 15:
		return false
	fs[s.at] = Q.new(x)
	s.fs = fs
	s.p = Q.new(x)
	stats(s)
	s.median = s.xs[s.cut].add(s.xs[s.cut + 1]).div(Q.new(2))
	return true


static func _missing_value(rng: Seeded, s: Dictionary) -> bool:
	_discrete(rng, s, 4, 5)
	if not _share(rng, s, rng.int_in(10, 24), 2):
		return false
	s.at = rng.int_in(0, s.xs.size() - 1)
	s.k = s.xs[s.at]
	stats(s)
	return ends(s.mean, 1) and not s.k.eq(s.mean) and s.fs[s.at].n >= 2


static func _new_value(rng: Seeded, s: Dictionary) -> bool:
	s.count = rng.int_in(4, 12)
	s.old = Q.new(rng.int_in(60, 300), 5)
	s.k = Q.new(rng.int_in(5, 90))
	s.new = s.old.mul(Q.new(s.count)).add(s.k).div(Q.new(s.count + 1))
	return ends(s.new, 1) and ends(s.old, 1) and not s.new.eq(s.old)


## Group sizes and means, sizes all different and means all different.
static func _groups(rng: Seeded, s: Dictionary, k: int) -> bool:
	var sizes: Array = []
	var means: Array = []
	var total := Q.new(0)
	for i in k:
		sizes.append(rng.int_in(5, 40) if s.paper == 2 else rng.int_in(1, 8) * 5)
		means.append(Q.new(rng.int_in(20, 180), 2))
		total = total.add(means[i].mul(Q.new(sizes[i])))
	for i in k:
		for j in i:
			if sizes[i] == sizes[j] or means[i].eq(means[j]):
				return false
	s.sizes = sizes
	s.means = means
	s.n = Q.new(sizes.reduce(func(a, b): return a + b, 0))
	s.total = total
	s.whole = total.div(s.n)
	return true


static func _whole_mean(rng: Seeded, s: Dictionary) -> bool:
	if not _groups(rng, s, 3 if s.rep == "table" else 2):
		return false
	var flat := Q.new(0)
	for m: Q in s.means:
		flat = flat.add(m)
	flat = flat.div(Q.new(s.means.size()))
	if flat.eq(s.whole):
		return false
	return ends(s.whole, 2) if s.paper == 1 else Answer.needs_rounding(s.whole) and fits(s.whole) and apart(flat, s.whole)


static func _whole_total(rng: Seeded, s: Dictionary) -> bool:
	if not _groups(rng, s, 3):
		return false
	return s.total.is_int()


static func _group_mean(rng: Seeded, s: Dictionary) -> bool:
	if not _groups(rng, s, 2):
		return false
	if not ends(s.whole, 1):
		return false
	return s.means[1].sign() > 0


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
