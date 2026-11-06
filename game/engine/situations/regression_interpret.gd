class_name RegressionInterpretSituation
extends RefCounted
## The `regression-interpret` situation (curriculum/question-types.json): what a regression
## line means in its story, and whether an estimate from it can be trusted. It extends
## RegressionSituation: `stats` does the sums, so a, b and r come from a real table, but the
## stories carry units, their x-values have their own range, and the correlation can be weak.
## Every line given to 3 s.f., with its r and its range, comes from a table drawn here. The
## SymPy checker reads the numbers back from what is shown and judges every statement from them.
##
## need.ask is the unknown:
##   interpret-gradient   what a means in the story
##   expected-change      the change in y for k more of x
##   interpret-intercept  what b means in the story
##   intercept-sensible   case "sensible" (x = 0 is in the data), "far" or "negative" (x = 0 is
##                        far outside the data, and in "negative" b is an impossible amount too)
##   judge-prediction     case "good", "outside" or "weak": is an estimate reliable?
##   flawed-estimate      case "outside" (x0 outside the data) or "rearranged" (y on x solved for x)
##   read-estimate        y read from the drawn line, to the nearest 5
##
## generate() returns a Dictionary:
##   paper, ask, rep, case, ctx (an index into STORIES)
##   n, xs, ys, mx, my, sxx, sxy, syy, a, b, r, ay, by  as RegressionSituation
##   a3, b3   a and b to 3 s.f.;  rr  r to 2 d.p.;  lo, hi  the lowest and highest x
##   ua, ub   the a and b the question works with: a3 and b3, or the exact a on a table's
##            expected change, which the GDC gives unrounded
##   k, ch, p the extra x, the change ua × k, and the x a two-predictions route starts from
##   x0, y0   the x an estimate is made at, and the estimate
##   given_y, xr, xc  the y known, the line solved for x (the slip), and the line of x on y's x
##   read     y0 to the nearest 5;  near  the same for the plotted point closest to x0;
##   across   the slip of reading across from y = x0, to the nearest 5
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its own copy.

const TRIES := 12000
const N_MIN := 6
const N_MAX := 9
const Y_MIN := 8
const Y_MAX := 99
## The two bands of r, with a gap between them, so that strong and weak are never in doubt.
const STRONG_MIN := 0.9
const STRONG_MAX := 0.99
const WEAK_MIN := 0.2
const WEAK_MAX := 0.5
const STEP := 5.0
## How far a line may pass from the nearest multiple of STEP, for a reading to be fair.
const READ_NEAR := 1.0
const EXTRAS := [2, 3, 4, 5, 6, 8, 10]

## The stories. sign: of the correlation. lo, hi: the x-values to draw from; lo = 0 puts x = 0 in
## the table, and a story with lo above 0 always has x = 0 far outside its data.
## x, y: the variable in a phrase; xl, yl: with its units; per: one more of x; up: k more of x.
const STORIES := [
	{"who": "water filters", "x": "time in use", "ux": "days", "xl": "time in use in days", "per": "extra day in use", "up": "the time in use is %d days longer",
		"y": "flow rate", "uy": "litres per hour", "uy1": "litre per hour", "yl": "flow rate in litres per hour", "sign": -1, "lo": 0, "hi": 20, "zero": "a new filter"},
	{"who": "solar panels", "x": "age", "ux": "years", "xl": "age in years", "per": "extra year of age", "up": "the age is %d years greater",
		"y": "power output", "uy": "watts", "uy1": "watt", "yl": "power output in watts", "sign": -1, "lo": 0, "hi": 20, "zero": "a new panel"},
	{"who": "water tanks", "x": "pumping time", "ux": "hours", "xl": "pumping time in hours", "per": "extra hour of pumping", "up": "the pumping time is %d hours longer",
		"y": "water in the tank", "uy": "litres", "uy1": "litre", "yl": "water in the tank in litres", "sign": 1, "lo": 0, "hi": 20, "zero": "the moment the pump starts"},
	{"who": "grain stores", "x": "time since the last delivery", "ux": "days", "xl": "time since the last delivery in days", "per": "extra day since the last delivery", "up": "the time since the last delivery is %d days longer",
		"y": "grain in store", "uy": "kg", "uy1": "kg", "yl": "grain in store in kg", "sign": -1, "lo": 0, "hi": 20, "zero": "the day of a delivery"},
	{"who": "convoys", "x": "fuel carried", "ux": "litres", "xl": "fuel carried in litres", "per": "extra litre of fuel carried", "up": "the fuel carried is %d litres more",
		"y": "distance driven", "uy": "km", "uy1": "km", "yl": "distance driven in km", "sign": 1, "lo": 30, "hi": 70, "zero": ""},
	{"who": "wind turbines", "x": "wind speed", "ux": "m/s", "xl": "wind speed in m/s", "per": "extra 1 m/s of wind speed", "up": "the wind speed is %d m/s higher",
		"y": "power output", "uy": "kW", "uy1": "kW", "yl": "power output in kW", "sign": 1, "lo": 8, "hi": 20, "zero": ""},
	{"who": "cargo trucks", "x": "load carried", "ux": "kg", "xl": "load carried in kg", "per": "extra kg of load carried", "up": "the load carried is %d kg more",
		"y": "top speed", "uy": "km/h", "uy1": "km/h", "yl": "top speed in km/h", "sign": -1, "lo": 30, "hi": 80, "zero": ""},
	{"who": "water stalls", "x": "price of a can", "ux": "tokens", "xl": "price of a can in tokens", "per": "extra token on the price", "up": "the price of a can is %d tokens higher",
		"y": "number of cans sold in a day", "uy": "cans", "uy1": "can", "yl": "number of cans sold in a day", "sign": -1, "lo": 20, "hi": 60, "zero": ""},
]
const FROM_ZERO := [0, 1, 2, 3]
const FAR_FROM_ZERO := [4, 5, 6, 7]
const FAR_RISING := [4, 5]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "interpret-gradient")
	var rep: String = need.get("rep", "table")
	# Picked once, so that an easy case gets no more than its share of the draws.
	var which: String = rng.pick(_cases(ask))
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "rep": rep, "case": which, "n": 0, "ctx": _story(rng, which)}
		if _draw(rng, s, which == "weak") and _ask_clear(rng, s):
			return s
	return {}


static func _cases(ask: String) -> Array:
	match ask:
		"intercept-sensible":
			return ["sensible", "far", "negative"]
		"judge-prediction":
			return ["good", "outside", "weak"]
		"flawed-estimate":
			return ["outside", "rearranged"]
	return ["any"]


static func _story(rng: Seeded, which: String) -> int:
	match which:
		"sensible":
			return rng.pick(FROM_ZERO)
		"far":
			return rng.pick(FAR_FROM_ZERO)
		"negative":
			return rng.pick(FAR_RISING)
	return rng.int_in(0, STORIES.size() - 1)


# ── The data ─────────────────────────────────────────────────

## n points near a line of the story's sign, as strong or as weak as asked.
static func _draw(rng: Seeded, s: Dictionary, weak: bool) -> bool:
	var c: Dictionary = STORIES[s.ctx]
	var n := rng.int_in(8 if weak else N_MIN, N_MAX)
	var pool: Array = []
	for x in range(c.lo, c.hi + 1):
		pool.append(x)
	var xs: Array = rng.shuffled(pool).slice(0, n)
	if c.lo == 0 and not 0 in xs:
		xs[0] = 0
	xs.sort()
	var span: int = xs[n - 1] - xs[0]
	var rise := rng.int_in(10, 30) if weak else rng.int_in(20, 75)
	var noise := rng.int_in(20, 35) if weak else rng.int_in(2, 9)
	var slope: float = float(rise) / span * c.sign
	var raw: Array = []
	for x in xs:
		raw.append(slope * x + rng.int_in(-noise, noise))
	var lowest: float = raw.min()
	var shift := rng.int_in(Y_MIN, 30) - lowest
	var ys: Array = raw.map(func(v): return roundi(v + shift))
	if ys.max() > Y_MAX or ys.min() < Y_MIN:
		return false
	s.n = n
	s.xs = xs
	s.ys = ys
	RegressionSituation.stats(s)
	var strength: float = absf(s.r)
	if s.a.sign() != c.sign or strength < (WEAK_MIN if weak else STRONG_MIN) or strength > (WEAK_MAX if weak else STRONG_MAX):
		return false
	s.a3 = RegressionSituation.to_sf(s.a)
	s.b3 = RegressionSituation.to_sf(s.b)
	s.rr = Q.new(roundi(s.r * 100.0), 100)
	s.lo = xs[0]
	s.hi = xs[n - 1]
	s.ua = s.a if s.ask == "expected-change" and s.rep == "table" else s.a3
	s.ub = s.b3
	var a_text := Fmt.sf(s.a3.abs_q())
	return RegressionSituation.clear(s.a) and RegressionSituation.clear(s.b) and absf(s.b.to_float()) >= 1.0 \
			and a_text != Fmt.sf(s.b3.abs_q()) and not s.a3.is_zero() and not s.b3.is_zero()


## What each unknown needs of the data, besides being near a line.
static func _ask_clear(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"interpret-gradient":
			# The gradient read backwards is a different number from a.
			var back := Q.new(1).div(s.a3).abs_q()
			return Fmt.sf(s.a3.abs_q()) != Fmt.sf(back) and Fmt.sf(s.a3.abs_q()) != Fmt.sf(s.sxy.div(s.syy).abs_q())
		"expected-change":
			return _extra(rng, s)
		"interpret-intercept":
			var cross: Q = s.b3.neg().div(s.a3)
			return Fmt.sf(s.b3) != Fmt.sf(cross) and Fmt.sf(s.b3) != Fmt.sf(s.my)
		"intercept-sensible":
			return _sensible(s)
		"judge-prediction":
			if s.case == "outside":
				return _outside(rng, s)
			return _inside(rng, s)
		"flawed-estimate":
			if s.case == "outside":
				return _outside(rng, s)
			return _solved_for_x(rng, s)
		"read-estimate":
			return _reading(rng, s)
	return false


## k more of x stays within the spread of the data, and the change needs rounding.
static func _extra(rng: Seeded, s: Dictionary) -> bool:
	var k: int = rng.pick(EXTRAS)
	if s.lo + k > s.hi:
		return false
	s.k = k
	s.p = s.lo
	s.ch = s.ua.mul(Q.new(k))
	var cross: Q = s.ua.mul(Q.new(k)).add(s.ub)
	return RegressionSituation.clear(s.ch) and Answer.needs_rounding(s.ch) and RegressionSituation.clear(s.ub.mul(Q.new(k))) \
			and RegressionSituation.clear(cross) and RegressionSituation.clear(s.ua) and Fmt.sf(cross) != Fmt.sf(s.ch)


static func _sensible(s: Dictionary) -> bool:
	if s.case == "sensible":
		return s.lo == 0 and s.b3.sign() > 0 and not s.b3.key() in s.ys.map(func(y): return Q.new(y).key())
	var far: bool = s.lo * 2 >= s.hi - s.lo
	return far and ((s.b3.sign() < 0) == (s.case == "negative"))


## An x strictly inside the data and not in the table.
static func _inside(rng: Seeded, s: Dictionary) -> bool:
	var x0 := rng.int_in(s.lo + 1, s.hi - 1) if s.hi - s.lo >= 2 else 0
	if x0 == 0 or x0 in s.xs:
		return false
	return _estimate(s, x0)


## An x at least half the data's spread beyond it, above it or, where x has room, below it.
static func _outside(rng: Seeded, s: Dictionary) -> bool:
	var span: int = s.hi - s.lo
	var gap := rng.int_in(ceili(span / 2.0), span)
	var x0: int = s.hi + gap if s.lo == 0 or rng.chance(0.6) else s.lo - gap
	if x0 < 1:
		return false
	return _estimate(s, x0)


static func _estimate(s: Dictionary, x0: int) -> bool:
	s.x0 = x0
	s.y0 = s.ua.mul(Q.new(x0)).add(s.ub)
	return s.y0.sign() > 0 and s.y0.to_float() >= 1.0 and RegressionSituation.clear(s.y0)


## A y strictly inside the data's y-values and not in the table, with the line of y on x solved
## for x (the slip) inside the data too, and reading differently from the line of x on y.
static func _solved_for_x(rng: Seeded, s: Dictionary) -> bool:
	var low: int = s.ys.min()
	var high: int = s.ys.max()
	if high - low < 2:
		return false
	var y := rng.int_in(low + 1, high - 1)
	if y in s.ys:
		return false
	s.given_y = y
	s.xr = Q.new(y).sub(s.ub).div(s.ua)
	var c: Q = s.sxy.div(s.syy)
	s.xc = c.mul(Q.new(y)).add(s.mx.sub(c.mul(s.my)))
	var x: float = s.xr.to_float()
	return x > s.lo and x < s.hi and RegressionSituation.clear(s.xr) and RegressionSituation.clear(s.xc) and Fmt.sf(s.xr) != Fmt.sf(s.xc)


## y at x0 is close to a multiple of 5, so a reading from the graph has one fair answer.
static func _reading(rng: Seeded, s: Dictionary) -> bool:
	if not _inside(rng, s):
		return false
	var y: float = s.y0.to_float()
	var read := roundi(y / STEP) * int(STEP)
	if absf(y - read) > READ_NEAR or read < 10:
		return false
	s.read = read
	var best: int = 0
	for i in s.n:
		if absi(s.xs[i] - s.x0) < absi(s.xs[best] - s.x0):
			best = i
	s.near = roundi(s.ys[best] / STEP) * int(STEP)
	s.across = roundi(Q.new(s.x0).sub(s.ub).div(s.ua).to_float() / STEP) * int(STEP)
	return true


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
