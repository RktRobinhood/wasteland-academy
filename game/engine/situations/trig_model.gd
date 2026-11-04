class_name TrigModelSituation
extends RefCounted
## The `trig-model` situation (curriculum/question-types.json): one wave a sin(b(x − c)) + d or
## a cos(b(x − c)) + d, for t3-trig-model-parameters (FAL-727). The student's facts stay clean, and
## the parameters are what they force.
##   Paper 1  x is a multiple of π: `xmax`, `xmin` and c are Qs of π, b is whole, the top and bottom
##            are whole. The figures are exact.
##   Paper 2  a story in t, with a whole or half top and bottom and a period T in hours, minutes or
##            days: b = 2π/T is a float, and answers are to 3 s.f.
##
## need.ask is the unknown (see TrigModelViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx (an index into TrigModelViews.CONTEXTS)
##   top, low            the maximum and minimum values
##   a, d                half the range and the mean, Qs
##   period, b           the period and b: Qs, or b a Q of π⁻¹ per unit on Paper 2 (see bq())
##   xmax, xmin          where the first maximum and the next minimum are
##   fn                  sin or cos, for a form of the model
##   and what each unknown adds: phi, k, y0, p, q0, r, t1, level, width, h, v, m, z, ...

const TRIES := 2000
const CONTEXTS := 6
const PERIODS := [12, 24, 16, 20, 30, 8, 10, 40, 60]
const LANDMARK := [[1, 6], [1, 4], [1, 3], [1, 2], [2, 3], [3, 4], [5, 6]]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "amp-axis")
	var rep: String = need.get("rep", "equation")
	var paper: int = int(need.get("paper", 2))
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "ctx": rng.int_in(0, CONTEXTS - 1), "fn": "cos"}
		_wave(rng, s)
		if new().call("_" + ask.replace("-", "_"), rng, s) and _clear(s):
			return s
	return {}


## Every 3 s.f. value offered is clear of a rounding edge.
static func _clear(s: Dictionary) -> bool:
	if s.paper == 1:
		return true
	var out: Dictionary = TrigModelViews.new().build(s.ask, s.rep, s, null)
	var vals: Array = []
	if out.answer.get("show", "") == "sf":
		vals = out.answer.values.values().filter(func(v): return v is Q)
	return vals.all(func(v): return absf(v.to_float()) < 0.0005 or Answer.rounds_clearly(v.to_float(), 0.03))


## A wave: top and bottom, then where it peaks. Paper 1 is in multiples of π.
static func _wave(rng: Seeded, s: Dictionary) -> void:
	if s.paper == 1:
		var low := rng.int_in(-6, 4)
		var a := rng.int_in(1, 5)
		s.low = Q.new(low)
		s.top = Q.new(low + 2 * a)
		s.w = rng.int_in(1, 4)
		var p: Array = rng.pick(LANDMARK)
		var step := Q.new(1, s.w)
		s.xmax = Q.new(p[0], p[1]).mul(step)
		s.xmin = s.xmax.add(step)
		s.b = Q.new(s.w)
	else:
		var low := rng.int_in(2, 40)
		s.low = Q.new(low, 2 if rng.chance(0.3) else 1)
		s.top = s.low.add(Q.new(rng.int_in(4, 40)))
		s.period = Q.new(rng.pick(PERIODS))
		s.xmax = Q.new(rng.int_in(1, s.period.n - 1))
		s.xmin = s.xmax.add(s.period.div(2))
	s.a = s.top.sub(s.low).div(2)
	s.d = s.top.add(s.low).div(2)


static func _amp_axis(_rng: Seeded, _s: Dictionary) -> bool:
	return true


static func _b_from_period(_rng: Seeded, _s: Dictionary) -> bool:
	return true


static func _c_cos_from_max(_rng: Seeded, _s: Dictionary) -> bool:
	return true


static func _c_sine_shift(_rng: Seeded, s: Dictionary) -> bool:
	s.fn = "sin"
	if s.paper == 1:
		return s.xmax.sub(Q.new(1, 2 * s.w)).sign() > 0
	return s.xmax.sub(s.period.div(4)).sign() > 0


static func _all_four(_rng: Seeded, _s: Dictionary) -> bool:
	return true


## f(x) = p sin(x + φ) + q on Paper 1, where the minimum fixes q.
static func _q_from_minimum(rng: Seeded, s: Dictionary) -> bool:
	s.p = rng.int_in(2, 6)
	s.m = rng.int_in(-8, 4)
	s.phi = Q.new(rng.pick([1, 1, 1, 2, 3, 5]), 6) if rng.chance(0.5) else Q.new(rng.pick([1, 3]), 4)
	s.q0 = s.m + s.p
	s.fn = rng.pick(["sin", "cos"])
	return true


## h(x) = p sin kx + q cos kx: a cos(b(x − c)) with a = √(p² + q²).
static func _sum_as_cos(rng: Seeded, s: Dictionary) -> bool:
	s.p = rng.int_in(1, 7)
	s.q0 = rng.int_in(1, 7)
	s.k = rng.int_in(1, 3)
	return Q.gcd(s.p, s.q0) == 1


## f(x) = a tan(bx): its first zero to the right of 0 and one point on it.
static func _tan_two_points(rng: Seeded, s: Dictionary) -> bool:
	s.z = Q.new(rng.int_in(4, 24), 2)
	s.h = Q.new(rng.int_in(2, 9), 2)
	s.v = Q.new(rng.int_in(2, 40), 2)
	return s.h.lt(s.z.div(2).sub(Q.new(1, 2)))


## y = a fn(bx + φ) + d: the bracket as Paper 1 writes it. φ is a Q of π, or a decimal.
static func _phase(rng: Seeded, s: Dictionary) -> void:
	s.fn = rng.pick(["sin", "cos"])
	s.bw = rng.int_in(2, 4)
	if s.paper == 1:
		var p: Array = rng.pick([[1, 6], [1, 4], [1, 3], [1, 2], [2, 3]])
		s.phi = Q.new(p[0], p[1])
	else:
		s.phi = Q.new(rng.int_in(2, 30), 10)
	s.right = rng.chance(0.6)
	s.amp = rng.int_in(2, 6)
	s.lift = ExtensionViews.nonzero(rng, -5, 5)


static func _shift_from_bracket(rng: Seeded, s: Dictionary) -> bool:
	_phase(rng, s)
	return true


static func _image_equation(rng: Seeded, s: Dictionary) -> bool:
	_phase(rng, s)
	s.kind = rng.pick(["translate", "stretch"])
	s.mv = s.phi
	s.up = ExtensionViews.nonzero(rng, -4, 4)
	s.sf = rng.pick([2, 3])
	return s.lift + s.up != 0


static func _describe_transformations(rng: Seeded, s: Dictionary) -> bool:
	_phase(rng, s)
	return true


static func _pq_from_translation(rng: Seeded, s: Dictionary) -> bool:
	_phase(rng, s)
	s.up = ExtensionViews.nonzero(rng, -6, 6)
	return true


## h(t) = a cos(bt) + d starting at the lowest point: a is negative.
static func _wheel_model(rng: Seeded, s: Dictionary) -> bool:
	var dia := rng.int_in(10, 60) * 2
	s.base = rng.int_in(1, 8)
	s.dia = dia
	s.period = Q.new(rng.pick([10, 12, 15, 20, 24, 30]))
	s.a = Q.new(dia, 2)
	s.d = s.a.add(s.base)
	s.top = s.d.add(s.a)
	s.low = Q.new(s.base)
	return true


## y = a sin(b(t − c)) + d rising through a level at t1.
static func _c_from_crossing(rng: Seeded, s: Dictionary) -> bool:
	s.fn = "sin"
	s.t1 = Q.new(rng.int_in(1, 6))
	s.level = s.d.add(s.a.mul(Q.new(rng.int_in(-7, 7), 10)))
	return s.a.sign() > 0 and absf(s.level.sub(s.d).to_float()) > 0.05


## h(t) = a cos(b(t − c)) + d above a level for w in each period.
static func _level_from_duration(rng: Seeded, s: Dictionary) -> bool:
	s.width = Q.new(rng.int_in(1, 4), 5).mul(s.period)
	return s.width.is_int()


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
