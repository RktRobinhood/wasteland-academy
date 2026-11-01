class_name RegressionSituation
extends RefCounted
## The `regression` situation (curriculum/question-types.json): paired data and the line
## fitted to it (FAL-695). The data are whole numbers, so every sum, mean and regression
## coefficient is an exact Q; r has a square root in it, so it is a float (Q to nine decimal
## places in the answer). The SymPy checker (tools/check_answers.py) reads the data back
## from the table shown and finds each answer again with exact rationals.
##
## need.ask is the unknown:
##   regression-line          the line y = ax + b from the table
##   correlation-coefficient  Pearson's r from the table
##   mean-point               (x-bar, y-bar), both ending within two decimal places
##   c-from-mean-point        y = ax + c passes through a given mean point: c
##   predict-from-data        y at x0 inside the data, from the unrounded line
##   predict-from-line        y at x0 from a line given to 3 s.f.
##
## generate() returns a Dictionary:
##   paper    2 (every regression part in the bank is Paper 2: the GDC does the work)
##   ask, ctx the unknown; the story (an index into RegressionViews.CONTEXTS)
##   n, xs, ys  the table: n points, x distinct and ascending, both whole numbers
##   mx, my   the means;  sxx, sxy, syy  the sums of squares and products;  a, b  the line
##   r        the correlation coefficient, a float
##   ay, by   the line of x on y written as y = ay x + by: what swapped lists give
##   x0       the x the line is used at;  y0  the estimate (a Q)
##   a3, b3   a and b to 3 s.f., what a student who rounds early uses;  y3  the estimate from them
##   xr       (x0 - b) / a, the line rearranged by mistake
##   c        the constant of the line through the mean point
##
## The clean limits below are the numbers behind the catalogue's `clean` text. The SymPy
## checker holds its own copy and fails on any breach.

const TRIES := 6000
## An answer is at least this far (in units of its 3rd figure) from a rounding edge.
const EDGE := 0.03
const CONTEXTS := 8
## +1 where the story's correlation is positive, -1 where it is negative.
const SIGNS := [1, 1, -1, 1, -1, -1, 1, -1]
const N_MIN := 6
const N_MAX := 9
const X_MAX := 20
const R_MIN := 0.8
const R_MAX := 0.99


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "regression-line")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "ctx": rng.int_in(0, CONTEXTS - 1), "n": 0, "x0": 0}
		var ok := false
		match ask:
			"c-from-mean-point":
				ok = _through_mean_point(rng, s)
			"predict-from-line":
				ok = _given_line(rng, s)
			_:
				ok = _data(rng, s) and _ask_clear(rng, s)
		if ok:
			return s
	return {}


# ── The data ─────────────────────────────────────────────────

## n points near a line: x from 1 to 20 (distinct, ascending), y whole numbers from 8 to 99.
static func _data(rng: Seeded, s: Dictionary) -> bool:
	var n := rng.int_in(N_MIN, N_MAX)
	var pool: Array = []
	for x in range(1, X_MAX + 1):
		pool.append(x)
	var xs: Array = rng.shuffled(pool).slice(0, n)
	xs.sort()
	var slope: float = rng.int_in(5, 40) / 10.0 * SIGNS[s.ctx]
	var noise := rng.int_in(2, 9)
	var raw: Array = []
	for x in xs:
		raw.append(slope * x + rng.int_in(-noise, noise))
	var lowest: float = raw.min()
	var shift := rng.int_in(8, 30) - lowest
	var ys: Array = raw.map(func(v): return roundi(v + shift))
	if ys.max() > 99 or ys.min() < 8:
		return false
	s.n = n
	s.xs = xs
	s.ys = ys
	stats(s)
	return absf(s.r) >= R_MIN and absf(s.r) <= R_MAX


## The sums, the means, the line and r of the table in s, written onto s.
static func stats(s: Dictionary) -> void:
	var n: int = s.n
	var sx := 0
	var sy := 0
	var sxx := 0
	var sxy := 0
	var syy := 0
	for i in n:
		var x: int = s.xs[i]
		var y: int = s.ys[i]
		sx += x
		sy += y
		sxx += x * x
		sxy += x * y
		syy += y * y
	s.mx = Q.new(sx, n)
	s.my = Q.new(sy, n)
	s.sxx = Q.new(n * sxx - sx * sx, n)
	s.sxy = Q.new(n * sxy - sx * sy, n)
	s.syy = Q.new(n * syy - sy * sy, n)
	s.a = s.sxy.div(s.sxx)
	s.b = s.my.sub(s.a.mul(s.mx))
	s.r = s.sxy.to_float() / sqrt(s.sxx.to_float() * s.syy.to_float())
	# The line of x on y, written as y = ay x + by: what swapped lists give.
	s.ay = s.sxy.div(s.syy)
	s.by = s.mx.sub(s.ay.mul(s.my))


## What each unknown needs of the data, besides being near a line.
static func _ask_clear(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"regression-line":
			# a and b are clear of a rounding edge, b is visible, and the swapped line reads differently.
			return clear(s.a) and clear(s.b) and absf(s.b.to_float()) >= 1.0 and clear(s.ay) and clear(s.by) \
					and Fmt.sf(s.a) != Fmt.sf(s.ay) and Fmt.sf(s.b) != Fmt.sf(s.by)
		"correlation-coefficient":
			return Answer.rounds_clearly(s.r, EDGE) and Answer.rounds_clearly(s.r * s.r, EDGE)
		"mean-point":
			return Q.new(100).mul(s.mx).is_int() and Q.new(100).mul(s.my).is_int()
		"predict-from-data":
			return _predict(rng, s)
	return false


## x0 is a whole number strictly inside the data and not in the table; the estimate and the
## one from a and b rounded to 3 s.f. (the early-rounding slip) are clear of a rounding
## edge and differ at 3 s.f.
static func _predict(rng: Seeded, s: Dictionary) -> bool:
	var lo: int = s.xs[0] + 1
	var hi: int = s.xs[s.n - 1] - 1
	if hi < lo:
		return false
	var x0 := rng.int_in(lo, hi)
	if x0 in s.xs:
		return false
	s.x0 = x0
	s.y0 = s.a.mul(Q.new(x0)).add(s.b)
	s.a3 = to_sf(s.a)
	s.b3 = to_sf(s.b)
	s.y3 = s.a3.mul(Q.new(x0)).add(s.b3)
	# The other slip: rearranging the line to find x from y = x0.
	s.xr = Q.new(x0).sub(s.b).div(s.a)
	return clear(s.y0) and clear(s.y3) and clear(s.xr) and Fmt.sf(s.y0) != Fmt.sf(s.y3) and Fmt.sf(s.y0) != Fmt.sf(s.xr) and s.y0.sign() > 0 \
			and Answer.needs_rounding(s.y0) and not is_3sf(s.a) and not is_3sf(s.b) and Fmt.sf(s.y3) != Fmt.sf(s.xr)


# ── Through a mean point, and a line given ───────────────────

## y = ax + c through (x-bar, y-bar): a to one decimal place, x-bar to one, y-bar to two.
static func _through_mean_point(rng: Seeded, s: Dictionary) -> bool:
	var tenths := rng.int_in(5, 49)
	# Not 1.0: "y = 1x + c" is not how a line is written.
	if tenths == 10:
		return false
	s.a = Q.new(tenths * (1 if rng.chance(0.5) else -1), 10)
	s.mx = Q.new(rng.int_in(20, 150), 10)
	s.my = Q.new(rng.int_in(2000, 9000), 100)
	s.c = s.my.sub(s.a.mul(s.mx))
	var big: float = absf(s.c.to_float())
	return big >= 1.0 and big <= 150.0 and clear(s.c)


## y = ax + b with a and b to 3 s.f. or fewer, and an estimate at a whole x0 that needs
## rounding: x0 from 5 to 40.
static func _given_line(rng: Seeded, s: Dictionary) -> bool:
	s.a = Q.new(rng.int_in(50, 999) * (1 if rng.chance(0.5) else -1), 100)
	s.b = Q.new(rng.int_in(15, 999) * (1 if rng.chance(0.5) else -1), 10)
	s.x0 = rng.int_in(5, 40)
	s.y0 = s.a.mul(Q.new(s.x0)).add(s.b)
	# The slip: rearranging the line to find x from y = x0.
	s.xr = Q.new(s.x0).sub(s.b).div(s.a)
	var y: float = s.y0.to_float()
	return y >= 5.0 and y <= 500.0 and Answer.needs_rounding(s.y0) and clear(s.y0) and clear(s.xr) and Fmt.sf(s.xr) != Fmt.sf(s.y0) \
			and Fmt.sf(s.a.mul(Q.new(s.x0)).sub(s.b)) != Fmt.sf(s.y0)


# ── The numbers ──────────────────────────────────────────────

## A value is clear of a 3 s.f. rounding edge.
static func clear(v: Q) -> bool:
	return v.is_zero() or Answer.rounds_clearly(v.to_float(), EDGE)


## True when v is already a number of at most three significant figures (3 s.f. changes nothing).
static func is_3sf(v: Q) -> bool:
	return not Answer.needs_rounding(v)


## v to 3 significant figures, as a Q.
static func to_sf(v: Q) -> Q:
	var r := Answer.parse_number(Fmt.sf(v).replace("−", "-"))
	return r.q


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
