class_name ApproximationSituation
extends RefCounted
## The `approximation` situation (curriculum/question-types.json): a measured, estimated or
## calculated value and how accurate it is, for the AI SL 1.6 types t1-ai-percentage-error and
## t1-ai-approx-bounds (FAL-999). Every paper allows a GDC, so every question is Paper 2.
##
## need.ask is the unknown (see ApproximationViews). generate() returns a Dictionary:
##   paper, ask, ctx   always 2; the unknown; the story (an index into a views list)
##   round-figures     v (Q, 7 figures), mode "dp", "sf" or "small", n: the places or figures
##   round-context     V, p (Q, two places each), w (the wastage %), item: the cost V × p × (1 + w/100)
##   whole-items       mode "buy" (area A, cover c, extra w %) or "fit" (length L m, item a cm)
##   percentage-error  va, ve (Q): the estimate and the exact value
##   error-of-rounding ve (Q, 7 figures), unit (Q): the value rounded to that unit is va
##   exact-from-error  va (Q), p (the most the error can be, %), side "largest" or "smallest"
##   estimate-1sf      a, b, c (Q): a × b ÷ c, each rounded to 1 s.f. as A, B, C
##   reasonable-answer d, area (whole): x(x + d) = area, roots r1 > 0 > r2
##   measurement-bound v (Q), mode "dp", "nearest" or "sf", unit (Q), side "lower" or "upper"
##   calc-bound        shape, the measured values xs (Q) and their unit u (Q), side
##   quotient-bound    kind "speed" or "density", top and bottom (Q) with units ut and ub, side
##   max-percentage-error  shape, x (Q), u (Q)
##
## The numbers are drawn, not taken from any one exam question. The SymPy checker
## (tools/check_answers.py) reads every value back from the text and works it out again.

const TRIES := 4000
const WHO := 6
## A 3 s.f. answer is at least this far (a fraction of its last place) from a rounding edge.
const EDGE := 0.04
## A money value's leftover fraction of a cent is at least this far from 0.5.
const CENT_EDGE := 0.15


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "percentage-error")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "ctx": rng.int_in(0, WHO - 1)}
		if _draw(rng, s):
			return s
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"round-figures":
			return _round_figures(rng, s)
		"round-context":
			return _round_context(rng, s)
		"whole-items":
			return _whole_items(rng, s)
		"percentage-error":
			return _percentage_error(rng, s)
		"error-of-rounding":
			return _error_of_rounding(rng, s)
		"exact-from-error":
			return _exact_from_error(rng, s)
		"estimate-1sf":
			return _estimate_1sf(rng, s)
		"reasonable-answer":
			return _reasonable_answer(rng, s)
		"measurement-bound":
			return _measurement_bound(rng, s)
		"calc-bound":
			return _calc_bound(rng, s)
		"quotient-bound":
			return _quotient_bound(rng, s)
		"max-percentage-error":
			return _max_percentage_error(rng, s)
	return false


# ── Small tools ──────────────────────────────────────────────

static func ipow(b: int, e: int) -> int:
	var r := 1
	for i in e:
		r *= b
	return r


## 10^p as a Q, for any whole p.
static func ten(p: int) -> Q:
	return Q.new(ipow(10, p)) if p >= 0 else Q.new(1, ipow(10, -p))


## v (positive) rounded half up to the multiple of 10^-places: places may be negative.
static func round_to(v: Q, places: int) -> Q:
	var u := ten(-places)
	var k := v.div(u)
	# floor(k + 1/2) in whole numbers
	return Q.new(floori(float(2 * k.n + k.d) / float(2 * k.d))).mul(u)


## v cut off (not rounded) after the multiple of 10^-places.
static func cut_to(v: Q, places: int) -> Q:
	var u := ten(-places)
	var k := v.div(u)
	return Q.new(floori(float(k.n) / float(k.d))).mul(u)


## The place of v's first significant figure: 2 for 345.6, −3 for 0.00456.
static func lead(v: Q) -> int:
	return floori(log(absf(v.to_float())) / log(10.0) + 1e-9)


## The decimal places that n significant figures of v keep.
static func sf_places(v: Q, n: int) -> int:
	return n - 1 - lead(v)


## Rounding in stages: one place at a time, from the last digit of v back to `places`.
static func staged(v: Q, from: int, places: int) -> Q:
	var r := v
	var p := from - 1
	while p >= places:
		r = round_to(r, p)
		p -= 1
	return r


## The decimal places v is written with (at most 9).
static func places_of(v: Q) -> int:
	var p := 0
	while not v.mul(ten(p)).is_int() and p < 9:
		p += 1
	return p


static func rounds_clearly(x: float) -> bool:
	return Answer.rounds_clearly(x, EDGE)


static func cents_clear(x: float) -> bool:
	if not is_finite(x) or x <= 0.0:
		return false
	var c := x * 100.0
	return absf(c - floorf(c) - 0.5) >= CENT_EDGE


## A decimal with `digits` significant figures, its first in the place `at`: a Q.
static func draw(rng: Seeded, digits: int, at: int) -> Q:
	var m := rng.int_in(ipow(10, digits - 1), ipow(10, digits) - 1)
	return Q.new(m).mul(ten(at - digits + 1))


# ── Rounding ─────────────────────────────────────────────────

## v to n places (dp), n figures (sf) or n figures of a small value (small, 3 figures). With
## chance 0.4 the digit after the cut is a 4 and the next one 5 or more, so rounding in stages
## would carry into it.
static func _round_figures(rng: Seeded, s: Dictionary) -> bool:
	s.mode = rng.pick(["dp", "dp", "sf", "sf", "small"])
	var at: int
	match s.mode:
		"dp":
			s.n = rng.int_in(1, 3)
			at = rng.int_in(0, 2)
		"sf":
			s.n = rng.int_in(2, 4)
			at = rng.int_in(-1, s.n - 1)
		_:
			s.n = 3
			at = -3
	var v := draw(rng, 7, at)
	var keep: int = s.n if s.mode == "dp" else s.n - 1 - at
	if rng.chance(0.4) and places_of(v) >= keep + 3:
		# Set the digits after the cut to 4 and then 5 to 9.
		var cut := cut_to(v, keep + 2)
		var tail := cut.sub(cut_to(v, keep))
		var four := Q.new(40 + rng.int_in(5, 9)).mul(ten(-keep - 2))
		v = cut.sub(tail).add(four).add(v.sub(cut))
	if keep < 0 or places_of(v) <= keep + 1:
		return false
	s.v = v
	s.keep = keep
	s.from = places_of(v)
	var r := round_to(v, keep)
	return not r.is_zero() and lead(r) == lead(v)


## A cost: V × p, with w % more, to the nearest cent. Neither the cost nor a slip ends in a
## whole number of cents, and none of them sits on a rounding edge.
static func _round_context(rng: Seeded, s: Dictionary) -> bool:
	s.item = rng.int_in(0, 5)
	s.V = Q.new(rng.int_in(150, 2400), 100)
	s.p = Q.new(rng.int_in(1200, 18000), 100)
	s.w = rng.pick([5, 8, 10, 12, 15, 20])
	# Worked exactly: V and p have two places, so the cost has at most six.
	var exact: Q = s.V.mul(s.p).mul(Q.new(100 + s.w, 100))
	var cost: float = exact.to_float()
	var bare: float = s.V.to_float() * s.p.to_float()
	if cost < 100.0 or cost > 99999.0 or not cents_clear(cost) or not cents_clear(bare):
		return false
	var c: Q = exact.mul(100)
	# The digits after the cent matter: cutting off and rounding give different cents.
	var f: float = c.sub(Q.new(floori(c.to_float()))).to_float()
	return f > 0.5 + CENT_EDGE + 0.01 and f < 0.999


## buy: tins to cover A m² with w % extra, c m² a tin, rounded up; the ratio's fraction is under
## 0.5 so the nearest whole number is too few. fit: items a cm long along L m, rounded down;
## the fraction is over 0.5, so the nearest whole number is one too many.
static func _whole_items(rng: Seeded, s: Dictionary) -> bool:
	s.mode = "buy" if rng.chance(0.55) else "fit"
	s.item = rng.int_in(0, 3)
	if s.mode == "buy":
		s.A = rng.int_in(40, 600)
		s.c = rng.pick([6, 8, 10, 12, 15, 16, 20, 25])
		s.w = rng.pick([5, 8, 10, 15, 20])
		var x: float = s.A * (1.0 + s.w / 100.0) / s.c
		var plain: float = float(s.A) / s.c
		var f := x - floorf(x)
		s.n = int(ceilf(x))
		return f > 0.12 and f < 0.38 and int(ceilf(plain)) != s.n and s.n >= 3
	s.L = Q.new(rng.int_in(25, 150), 10)
	s.a = rng.pick([12, 15, 18, 22, 24, 28, 35, 45])
	var y: float = s.L.to_float() * 100.0 / s.a
	var g := y - floorf(y)
	s.n = int(floorf(y))
	return g > 0.62 and g < 0.88 and s.n >= 4


# ── Percentage error ─────────────────────────────────────────

## An estimate va of an exact value ve, off by 2% to 25%, either way. The error and each slip
## (over va, not × 100, the sign kept) are clear of a 3 s.f. edge.
static func _percentage_error(rng: Seeded, s: Dictionary) -> bool:
	s.item = rng.int_in(0, 5)
	s.ve = draw(rng, 4, rng.int_in(1, 2))
	var off := rng.int_in(2, 25) * (1 if rng.chance(0.5) else -1)
	s.va = round_to(s.ve.mul(Q.new(100 + off, 100)), rng.int_in(-1, 0) if s.ve.to_float() > 100.0 else 0)
	if s.va.eq(s.ve) or s.va.sign() <= 0:
		return false
	var e := error_of(s.va, s.ve)
	var over_a: float = absf(s.va.to_float() - s.ve.to_float()) / s.va.to_float() * 100.0
	return rounds_clearly(e) and rounds_clearly(over_a) and Fmt.sf(e) != Fmt.sf(over_a) and Answer.needs_rounding(GdcKit.qf(e))


## |va − ve| ÷ |ve| × 100
static func error_of(va: Q, ve: Q) -> float:
	return absf(va.to_float() - ve.to_float()) / absf(ve.to_float()) * 100.0


## A GDC value ve with 7 figures, rounded to a whole unit (1, 0.1 or 10) as va. The error, the
## error over va and the error against ve to 3 s.f. read differently.
static func _error_of_rounding(rng: Seeded, s: Dictionary) -> bool:
	s.item = rng.int_in(0, 5)
	var p: int = rng.pick([0, 0, 1, -1])
	s.unit = ten(-p)
	s.ve = draw(rng, 7, rng.int_in(1, 2) if p >= 0 else 2)
	s.va = round_to(s.ve, p)
	if s.va.eq(s.ve):
		return false
	var e := error_of(s.va, s.ve)
	var over_a: float = absf(s.va.to_float() - s.ve.to_float()) / s.va.to_float() * 100.0
	var ve3 := GraphReadingSituation.sf_q(s.ve, 3)
	if ve3.eq(s.va):
		return false
	var early := error_of(s.va, ve3)
	return e > 0.01 and rounds_clearly(e) and rounds_clearly(over_a) and rounds_clearly(early) \
			and Fmt.sf(e) != Fmt.sf(over_a) and Fmt.sf(early) != Fmt.sf(e) and Fmt.sf(early) != Fmt.sf(over_a)


## A measurement va with a percentage error of at most p %: the largest exact value is
## va ÷ (1 − p/100), the smallest va ÷ (1 + p/100).
static func _exact_from_error(rng: Seeded, s: Dictionary) -> bool:
	s.item = rng.int_in(0, 5)
	s.va = draw(rng, 3, rng.int_in(1, 2))
	s.p = rng.pick([2, 3, 4, 5, 6, 8, 10, 12, 15])
	s.side = "largest" if rng.chance(0.5) else "smallest"
	var vals := exact_slips(s)
	for x in vals:
		if not rounds_clearly(x):
			return false
	return Fmt.sf(vals[0]) != Fmt.sf(vals[1]) and Fmt.sf(vals[0]) != Fmt.sf(vals[2]) and Fmt.sf(vals[1]) != Fmt.sf(vals[2])


## [the answer, the percentage applied to va, the other end].
static func exact_slips(s: Dictionary) -> Array:
	var a: float = s.va.to_float()
	var f: float = s.p / 100.0
	if s.side == "largest":
		return [a / (1.0 - f), a * (1.0 + f), a / (1.0 + f)]
	return [a / (1.0 + f), a * (1.0 - f), a / (1.0 - f)]


# ── Estimation ───────────────────────────────────────────────

## a × b ÷ c with each rounded to 1 s.f. as A, B, C, and A × B ÷ C a whole number. c is under 1
## half the time, so multiplying by it is a slip that reads differently.
static func _estimate_1sf(rng: Seeded, s: Dictionary) -> bool:
	s.a = draw(rng, 3, rng.int_in(1, 2))
	s.b = draw(rng, 3, rng.int_in(0, 1))
	s.c = draw(rng, 3, -1 if rng.chance(0.5) else 0)
	var A := GraphReadingSituation.sf_q(s.a, 1)
	var B := GraphReadingSituation.sf_q(s.b, 1)
	var C := GraphReadingSituation.sf_q(s.c, 1)
	if A.eq(s.a) or B.eq(s.b) or C.eq(s.c) or C.eq(1) or lead(A) != lead(s.a) or lead(B) != lead(s.b) or lead(C) != lead(s.c):
		return false
	var est := A.mul(B).div(C)
	if not est.is_int() or est.n > 100000:
		return false
	s.A = A
	s.B = B
	s.C = C
	s.est = est
	var exact: Q = s.a.mul(s.b).div(s.c)
	# The exact value is near the estimate but not it.
	var ratio := exact.to_float() / est.to_float()
	return ratio > 0.6 and ratio < 1.6 and Fmt.sf(exact, 3) != Fmt.dec(est)


## x(x + d) = area, with one positive and one negative root to 3 s.f., neither a whole number.
static func _reasonable_answer(rng: Seeded, s: Dictionary) -> bool:
	s.d = rng.int_in(2, 12)
	s.area = rng.int_in(20, 200)
	var disc := float(s.d * s.d + 4 * s.area)
	var r := sqrt(disc)
	if absf(r - roundf(r)) < 1e-9:
		return false
	s.r1 = (-s.d + r) / 2.0
	s.r2 = (-s.d - r) / 2.0
	return rounds_clearly(s.r1) and rounds_clearly(s.r2)


# ── Bounds ───────────────────────────────────────────────────

## A value given to 1 or 2 d.p., a count to the nearest 10, 100 or 1000, or a count to 2 or 3 s.f.
## that ends in zeros.
static func _measurement_bound(rng: Seeded, s: Dictionary) -> bool:
	s.mode = rng.pick(["dp", "dp", "nearest", "sf"])
	s.side = "lower" if rng.chance(0.5) else "upper"
	s.item = rng.int_in(0, 5)
	match s.mode:
		"dp":
			s.dp = rng.int_in(1, 2)
			s.unit = ten(-s.dp)
			s.v = Q.new(rng.int_in(11, 999)).mul(s.unit)
			if s.v.mul(ten(s.dp - 1)).is_int():
				return false
		"nearest":
			s.unit = ten(rng.int_in(1, 3))
			s.v = Q.new(rng.int_in(12, 99)).mul(s.unit)
			if s.v.div(s.unit.mul(10)).is_int():
				return false
		_:
			s.sf = rng.int_in(2, 3)
			s.v = Q.new(rng.int_in(ipow(10, s.sf - 1) + 1, ipow(10, s.sf) - 1)).mul(ten(rng.int_in(1, 2)))
			s.unit = ten(lead(s.v) - s.sf + 1)
			if s.v.div(s.unit).n % 10 == 0:
				return false
	return true


## The bounds of v, rounded to unit u.
static func bound(v: Q, u: Q, side: String) -> Q:
	return v.sub(u.div(2)) if side == "lower" else v.add(u.div(2))


const SHAPES := ["rectangle", "circle", "sphere", "cylinder", "route"]


## A shape's measurements, each rounded to u; the least or greatest value of what is worked out.
static func _calc_bound(rng: Seeded, s: Dictionary) -> bool:
	s.shape = rng.pick(SHAPES)
	s.side = "lower" if rng.chance(0.5) else "upper"
	match s.shape:
		"rectangle", "cylinder":
			# A tank measured to the nearest metre would hold millions of m³: 1 d.p. only.
			s.u = Q.new(1, 10) if s.shape == "cylinder" else rng.pick([Q.new(1, 10), Q.new(1)])
			s.xs = [Q.new(rng.int_in(21, 150)).mul(s.u), Q.new(rng.int_in(11, 99)).mul(s.u)]
			if s.xs[0].eq(s.xs[1]):
				return false
		"circle", "sphere":
			s.u = Q.new(1, 10)
			s.xs = [Q.new(rng.int_in(21, 150)).mul(s.u)]
		"route":
			s.u = Q.new(1)
			var xs: Array = []
			for i in rng.int_in(4, 6):
				xs.append(Q.new(rng.int_in(3, 40)))
			s.xs = xs
	var vals := calc_slips(s)
	if s.shape == "route":
		return true
	for x in vals:
		if not rounds_clearly(x):
			return false
	var texts := {}
	for x in vals:
		texts[Fmt.sf(x)] = true
	return texts.size() == vals.size()


## The value of the shape from its measurements: area of a rectangle a × b or a circle πr², the
## volume of a sphere from its diameter πd³/6 or a cylinder πr²h, or a route's total length.
static func calc(shape: String, xs: Array) -> float:
	var f: Array = xs.map(func(x): return x.to_float())
	match shape:
		"rectangle":
			return f[0] * f[1]
		"circle":
			return PI * f[0] * f[0]
		"sphere":
			return PI * pow(f[0], 3) / 6.0
		"cylinder":
			return PI * f[0] * f[0] * f[1]
	var t := 0.0
	for x in f:
		t += x
	return t


## [the answer, a whole unit instead of half, the measured values, mixed bounds (two measures)].
static func calc_slips(s: Dictionary) -> Array:
	var lo: bool = s.side == "lower"
	var half: Array = s.xs.map(func(x): return bound(x, s.u, s.side))
	var whole: Array = s.xs.map(func(x): return x.sub(s.u) if lo else x.add(s.u))
	var out: Array = [calc(s.shape, half), calc(s.shape, whole), calc(s.shape, s.xs)]
	if s.xs.size() == 2 and s.shape != "route":
		var other := "upper" if lo else "lower"
		out.append(calc(s.shape, [half[0], bound(s.xs[1], s.u, other)]))
	return out


## A speed d/t or a density m/V, both rounded; the greatest or least value.
static func _quotient_bound(rng: Seeded, s: Dictionary) -> bool:
	s.kind = "speed" if rng.chance(0.6) else "density"
	s.side = "lower" if rng.chance(0.5) else "upper"
	if s.kind == "speed":
		s.ut = rng.pick([Q.new(1), Q.new(10)])
		s.top = Q.new(rng.int_in(12, 95)).mul(s.ut)
		s.ub = Q.new(1, 10)
		s.bottom = Q.new(rng.int_in(25, 400)).mul(s.ub)
	else:
		s.ut = Q.new(1)
		s.top = Q.new(rng.int_in(40, 900))
		s.ub = Q.new(1)
		s.bottom = Q.new(rng.int_in(15, 300))
	var vals := quotient_slips(s)
	var texts := {}
	for x in vals:
		if not rounds_clearly(x):
			return false
		texts[Fmt.sf(x)] = true
	return texts.size() == vals.size()


## [the answer, the same bound top and bottom, the measured values, the other extreme].
static func quotient_slips(s: Dictionary) -> Array:
	var up: bool = s.side == "upper"
	var t_up := bound(s.top, s.ut, "upper").to_float()
	var t_lo := bound(s.top, s.ut, "lower").to_float()
	var b_up := bound(s.bottom, s.ub, "upper").to_float()
	var b_lo := bound(s.bottom, s.ub, "lower").to_float()
	var most := t_up / b_lo
	var least := t_lo / b_up
	return [most if up else least, t_up / b_up if up else t_lo / b_lo, s.top.to_float() / s.bottom.to_float(), least if up else most]


## A length x rounded to u: the side of a square or cube, the radius of a circle or sphere.
const POWER_SHAPES := {"square": 2, "cube": 3, "circle": 2, "sphere": 3}


static func _max_percentage_error(rng: Seeded, s: Dictionary) -> bool:
	s.shape = rng.pick(POWER_SHAPES.keys())
	s.u = rng.pick([Q.new(1, 10), Q.new(1)])
	s.x = Q.new(rng.int_in(12, 99)).mul(s.u)
	var vals := max_error_slips(s)
	var texts := {}
	for x in vals:
		if not rounds_clearly(x):
			return false
		texts[Fmt.sf(x)] = true
	return texts.size() == vals.size()


## [the answer, the length's own error, the upper bound only]: the measured value against the
## lower bound is the largest error, ((x/lo)^k − 1) × 100.
static func max_error_slips(s: Dictionary) -> Array:
	var k: int = POWER_SHAPES[s.shape]
	var x: float = s.x.to_float()
	var lo := bound(s.x, s.u, "lower").to_float()
	var hi := bound(s.x, s.u, "upper").to_float()
	return [(pow(x / lo, k) - 1.0) * 100.0, (x / lo - 1.0) * 100.0, (1.0 - pow(x / hi, k)) * 100.0]


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
