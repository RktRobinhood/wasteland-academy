class_name RegressionPairSituation
extends RefCounted
## The `regression-x-on-y` situation (curriculum/question-types.json): paired data with both
## regression lines (FAL-725). It draws the data with RegressionSituation, so every sum and
## coefficient is an exact Q. Where both lines are given they are built through a whole-number
## mean point, so the point is exact. The SymPy checker reads everything back from what is shown.
##
## need.ask is the unknown:
##   x-on-y-line            the line x = cy + d from the table
##   d-from-mean-point      d of x = cy + d through a given mean point
##   choose-line            which line to use: dir "x" (estimate x) or "y"
##   predict-x-from-data    x at y0 inside the data, from the unrounded line
##   predict-x-from-lines   x at y0, both lines given to 3 s.f.
##   judge-estimate         case "good", "outside" or "weak": is the estimate reliable?
##   mean-point-from-lines  the point both lines pass through
##   mean-from-one-mean     known "x" or "y", line "yx" (y = ax + b) or "xy" (x = cy + d)
##
## generate() returns a Dictionary:
##   paper, ask, ctx (an index into RegressionViews.CONTEXTS)
##   n, xs, ys, mx, my, sxx, sxy, syy, a, b, r  as RegressionSituation
##   c, d     the line x = cy + d (ay and by on the table's situation)
##   ra, rb   y = ax + b rearranged for x: x = ra y + rb
##   y0, x0   the y the line is used at, and the estimate
##   xr       (y0 - b) / a, y put into the line of y on x by mistake
##   rx       the mean a slip gives
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 8000
const EDGE := 0.03
const AC_MAX := 0.95
const WEAK_R := [30, 35, 40, 45]
const STRONG_R := [90, 92, 94, 96, 97, 98]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "x-on-y-line")
	var paper: int = int(need.get("paper", 2))
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "ctx": rng.int_in(0, RegressionSituation.CONTEXTS - 1), "n": 0}
		var ok := false
		match ask:
			"x-on-y-line":
				ok = RegressionSituation._data(rng, s) and _table_line(s)
			"predict-x-from-data":
				ok = RegressionSituation._data(rng, s) and _predict_data(rng, s)
			"d-from-mean-point":
				ok = _through_mean(rng, s)
			"choose-line":
				ok = _two_lines(rng, s)
				s.dir = "x" if rng.chance(0.6) else "y"
				s.v = roundi(s.my.to_float()) + rng.int_in(1, 4) if s.dir == "x" else roundi(s.mx.to_float()) + rng.int_in(1, 3)
			"predict-x-from-lines":
				ok = _predict_lines(rng, s)
			"judge-estimate":
				ok = _judge(rng, s)
			"mean-point-from-lines":
				ok = _two_lines(rng, s)
			"mean-from-one-mean":
				ok = _two_lines(rng, s) and _one_mean(rng, s)
		if ok:
			return s
	return {}


static func clear(v: Q) -> bool:
	return RegressionSituation.clear(v)


static func differs(a: Q, b: Q) -> bool:
	return Fmt.sf(a) != Fmt.sf(b)


## The line of x on y from the table; rearranged, unswapped and right all read differently.
static func _table_line(s: Dictionary) -> bool:
	s.c = s.ay
	s.d = s.by
	s.ra = Q.new(1).div(s.a)
	s.rb = s.b.neg().div(s.a)
	return clear(s.c) and clear(s.d) and clear(s.ra) and clear(s.rb) and clear(s.a) and clear(s.b) and absf(s.d.to_float()) >= 0.5 \
			and differs(s.c, s.ra) and differs(s.d, s.rb) and differs(s.c, s.a) and differs(s.d, s.b) and differs(s.ra, s.a) and differs(s.rb, s.b)


## y0 is a whole number strictly inside the y-values and not in the table.
static func _predict_data(rng: Seeded, s: Dictionary) -> bool:
	s.c = s.ay
	s.d = s.by
	var lo: int = s.ys.min() + 1
	var hi: int = s.ys.max() - 1
	if hi < lo:
		return false
	var y0 := rng.int_in(lo, hi)
	if y0 in s.ys:
		return false
	s.y0 = y0
	s.x0 = s.c.mul(Q.new(y0)).add(s.d)
	s.xr = Q.new(y0).sub(s.b).div(s.a)
	return s.x0.sign() > 0 and s.xr.sign() > 0 and clear(s.x0) and clear(s.xr) and Answer.needs_rounding(s.x0) and differs(s.x0, s.xr)


## x = cy + d through (x-bar, y-bar): c in hundredths, the means to one decimal place.
static func _through_mean(rng: Seeded, s: Dictionary) -> bool:
	s.c = Q.new(rng.int_in(12, 195) * RegressionSituation.SIGNS[s.ctx], 100)
	s.mx = Q.new(rng.int_in(20, 150), 10)
	s.my = Q.new(rng.int_in(20, 900), 10)
	s.d = s.mx.sub(s.c.mul(s.my))
	# The slip: x-bar put in where y goes, and y-bar where x goes.
	s.rx = s.my.sub(s.c.mul(s.mx))
	var big: float = absf(s.d.to_float())
	return big >= 1.0 and big <= 900.0 and Answer.needs_rounding(s.d) and clear(s.d) and not s.rx.is_zero() and clear(s.rx) and differs(s.d, s.rx)


## y = ax + b and x = cy + d through a whole-number mean point: a and c to one decimal place,
## of one sign, with 0 < ac < 1.
static func _two_lines(rng: Seeded, s: Dictionary) -> bool:
	var sg: int = RegressionSituation.SIGNS[s.ctx]
	s.a = Q.new(rng.int_in(2, 30) * sg, 10)
	s.c = Q.new(rng.int_in(1, 20) * sg, 10)
	s.mx = Q.new(rng.int_in(3, 20))
	s.my = Q.new(rng.int_in(5, 60))
	var ac: float = s.a.mul(s.c).to_float()
	if ac <= 0.0 or ac > AC_MAX:
		return false
	s.b = s.my.sub(s.a.mul(s.mx))
	s.d = s.mx.sub(s.c.mul(s.my))
	# Written with a sign in front of them, so neither constant may be 0.
	return not s.b.is_zero() and not s.d.is_zero() and not s.a.eq(Q.new(1)) and not s.c.eq(Q.new(1)) and not s.a.eq(Q.new(-1)) and not s.c.eq(Q.new(-1))


## Both lines to 3 s.f., and an estimate at a whole y that needs rounding.
static func _predict_lines(rng: Seeded, s: Dictionary) -> bool:
	var sg: int = RegressionSituation.SIGNS[s.ctx]
	s.a = Q.new(rng.int_in(21, 299) * sg, 100)
	s.c = Q.new(rng.int_in(11, 199) * sg, 100)
	var ac: float = s.a.mul(s.c).to_float()
	if ac <= 0.0 or ac > AC_MAX:
		return false
	var mx := Q.new(rng.int_in(30, 200), 10)
	var my := Q.new(rng.int_in(50, 600), 10)
	s.b = RegressionSituation.to_sf(my.sub(s.a.mul(mx)))
	s.d = RegressionSituation.to_sf(mx.sub(s.c.mul(my)))
	if s.b.is_zero() or s.d.is_zero():
		return false
	s.y0 = roundi(my.to_float()) + rng.int_in(-4, 4)
	s.x0 = s.c.mul(Q.new(s.y0)).add(s.d)
	s.xr = Q.new(s.y0).sub(s.b).div(s.a)
	return s.y0 > 0 and s.x0.sign() > 0 and s.xr.sign() > 0 and Answer.needs_rounding(s.x0) and clear(s.x0) and clear(s.xr) and differs(s.x0, s.xr)


static func _judge(rng: Seeded, s: Dictionary) -> bool:
	s.case = rng.pick(["good", "outside", "weak"])
	s.ylo = rng.int_in(8, 40)
	s.yhi = s.ylo + rng.int_in(20, 50)
	var hundredths: int = int(rng.pick(WEAK_R if s.case == "weak" else STRONG_R))
	s.rr = Q.new(hundredths * RegressionSituation.SIGNS[s.ctx], 100)
	s.y0 = s.yhi + rng.int_in(5, 20) if s.case == "outside" else rng.int_in(s.ylo + 3, s.yhi - 3)
	return true


## One mean is given, with the one line that needs it.
static func _one_mean(rng: Seeded, s: Dictionary) -> bool:
	s.known = rng.pick(["x", "y"])
	s.line = rng.pick(["yx", "xy"])
	# The slip: the mean put into the line as the other variable.
	var v: Q = s.mx if s.known == "x" else s.my
	if s.line == "yx":
		s.rx = v.sub(s.b).div(s.a) if s.known == "x" else s.a.mul(v).add(s.b)
	else:
		s.rx = s.c.mul(v).add(s.d) if s.known == "x" else v.sub(s.d).div(s.c)
	var want: Q = s.my if s.known == "x" else s.mx
	return not s.rx.eq(want) and s.rx.sign() > 0 and Q.new(1000).mul(s.rx).is_int()


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
