class_name TrigEquationSituation
extends RefCounted
## The `trig-equation` situation (curriculum/question-types.json): one trig equation on a finite
## interval, for t3-trig-equation (FAL-727). Paper 1 has landmark values, so every solution is
## exact; a decimal k on Paper 2 is the only route to the GDC method. An angle is a Q, the multiple
## of π, whichever way it is written.
##
## need.ask is the unknown (see TrigEquationViews). generate() returns a Dictionary:
##   paper, ask, rep, form    "pi" or "deg"
##   fn, b, phi               the left side is fn(bx + phi·π)
##   k                        a value [a, b, r] (TrigKit) on Paper 1, a Q on Paper 2
##   lo, hi, open_hi          the interval, lo ≤ x ≤ hi (x < hi if open_hi), as multiples of π
##   shape                    how the equation is written (TrigEquationViews.equation)
##   m, f1, f2                the number and the ratios of a factorised equation
##   xs                       the solutions: Qs, in order

const TRIES := 800
const VALUES := {"sin": [[1, 2], [2, 2], [3, 2], [1, 1]], "cos": [[1, 2], [2, 2], [3, 2], [1, 1]]}
const MAX_SOLUTIONS := 8
## Every landmark on the first turn.
const TURN := [[0, 1], [1, 6], [1, 4], [1, 3], [1, 2], [2, 3], [3, 4], [5, 6], [1, 1], [7, 6], [5, 4], [4, 3], [3, 2], [5, 3], [7, 4], [11, 6]]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "basic-exact")
	var rep: String = need.get("rep", "equation")
	for i in TRIES:
		var s := {"paper": int(need.get("paper", 1)), "ask": ask, "rep": rep, "form": "pi", "b": Q.new(1), "phi": Q.new(0), "lo": Q.new(0), "hi": Q.new(2), "open_hi": false, "shape": rng.int_in(0, 1)}
		if new().call("_" + ask.replace("-", "_"), rng, s) and _clean(s):
			return s
	return {}


static func _clean(s: Dictionary) -> bool:
	var n: int = s.xs.size()
	if s.paper == 2:
		return n >= 1 and n <= MAX_SOLUTIONS and s.xs.all(func(x): return Answer.rounds_clearly(x.to_float(), 0.03) and absf(x.to_float()) > 0.05)
	return n >= 1 and n <= MAX_SOLUTIONS


## Every multiple of π that fn(bx + φπ) = k gives on the interval.
static func solve(fn: String, k: Array, b: Q, phi: Q, lo: Q, hi: Q, open_hi: bool = false) -> Array:
	var seen := {}
	for p in TURN:
		var u := Q.new(p[0], p[1])
		var v := TrigKit.of(fn, u)
		if v.is_empty() or not TrigKit.same(v, k):
			continue
		for n in range(-12, 13):
			var x: Q = u.add(n * 2).sub(phi).div(b)
			if not x.lt(lo) and (x.lt(hi) or (x.eq(hi) and not open_hi)):
				seen[x.key()] = x
	var out: Array = seen.values()
	out.sort_custom(func(a, c): return a.lt(c))
	return out


## A landmark value for a sine or a cosine.
static func value(rng: Seeded, zero: bool = true) -> Array:
	var pick: Array = rng.pick([[0, 1, 1], [1, 2, 1], [1, 2, 2], [1, 2, 3], [1, 1, 1]] if zero else [[1, 2, 1], [1, 2, 2], [1, 2, 3]])
	var v := TrigKit.V(Q.new(pick[0], pick[1])) if pick[2] == 1 else TrigKit.V(0, Q.new(pick[0], pick[1]), pick[2])
	return v if rng.chance(0.5) else TrigKit.neg(v)


## A landmark value for tan.
static func tan_value(rng: Seeded) -> Array:
	var v: Array = rng.pick([TrigKit.V(1), TrigKit.V(0, 1, 3), TrigKit.V(0, Q.new(1, 3), 3)])
	return v if rng.chance(0.5) else TrigKit.neg(v)


static func _pick_k(rng: Seeded, fn: String, zero: bool = true) -> Array:
	return tan_value(rng) if fn == "tan" else value(rng, zero)


static func _solve(s: Dictionary) -> void:
	s.xs = solve(s.fn, s.k, s.b, s.phi, s.lo, s.hi, s.open_hi)


static func _basic_exact(rng: Seeded, s: Dictionary) -> bool:
	s.fn = rng.pick(["sin", "cos"] if s.rep == "diagram" else TrigKit.FNS)
	s.k = _pick_k(rng, s.fn)
	s.open_hi = rng.chance(0.3)
	_solve(s)
	return true


static func _wide_interval(rng: Seeded, s: Dictionary) -> bool:
	s.fn = rng.pick(TrigKit.FNS)
	s.k = _pick_k(rng, s.fn)
	var w: Array = rng.pick([[-1, 1], [0, 4], [-2, 2], [-1, 2]])
	s.lo = Q.new(w[0])
	s.hi = Q.new(w[1])
	_solve(s)
	return true


static func _basic_degrees(rng: Seeded, s: Dictionary) -> bool:
	s.form = "deg"
	s.fn = rng.pick(TrigKit.FNS)
	s.k = _pick_k(rng, s.fn, false)
	var w: Array = rng.pick([[0, 2], [-1, 1]])
	s.lo = Q.new(w[0])
	s.hi = Q.new(w[1])
	_solve(s)
	return true


static func _multiple_angle(rng: Seeded, s: Dictionary) -> bool:
	s.fn = rng.pick(TrigKit.FNS)
	s.k = _pick_k(rng, s.fn, false)
	s.b = Q.new(rng.int_in(2, 4))
	s.hi = Q.new(rng.pick([1, 2]))
	s.xs = solve(s.fn, s.k, s.b, s.phi, s.lo, s.hi)
	return s.xs.size() >= 2


static func _shifted_angle(rng: Seeded, s: Dictionary) -> bool:
	s.fn = rng.pick(TrigKit.FNS)
	s.k = _pick_k(rng, s.fn, false)
	var p: Array = rng.pick([[1, 6], [1, 4], [1, 3], [1, 2]])
	s.phi = Q.new(p[0] * (1 if rng.chance(0.5) else -1), p[1])
	_solve(s)
	return s.xs.size() >= 2


static func _least_positive(rng: Seeded, s: Dictionary) -> bool:
	s.fn = rng.pick(["sin", "cos"])
	s.k = _pick_k(rng, s.fn, false)
	s.b = Q.new(rng.pick([1, 2, 1]), rng.pick([1, 2, 1]))
	if s.b.d == 2 and s.b.n == 2:
		s.b = Q.new(1)
	var p: Array = rng.pick([[1, 6], [1, 4], [1, 3]])
	s.phi = Q.new(p[0] * (1 if rng.chance(0.7) else -1), p[1])
	s.hi = Q.new(8)
	var all := solve(s.fn, s.k, s.b, s.phi, Q.new(0), s.hi).filter(func(x): return x.sign() > 0)
	if all.is_empty():
		return false
	s.xs = [all[0]]
	s.all = all
	return true


static func _degree_compound(rng: Seeded, s: Dictionary) -> bool:
	s.form = "deg"
	s.fn = rng.pick(TrigKit.FNS)
	s.k = _pick_k(rng, s.fn, false)
	s.b = Q.new(rng.int_in(2, 3))
	s.phi = Q.new(5 * ExtensionViews.nonzero(rng, -6, 6), 180)
	s.hi = Q.new(rng.pick([1, 2]))
	_solve(s)
	return s.xs.size() >= 2 and s.xs.all(func(x): return x.mul(180).is_int())


static func _tan_compound(rng: Seeded, s: Dictionary) -> bool:
	s.fn = "tan"
	s.k = tan_value(rng)
	s.b = Q.new(rng.int_in(1, 3))
	s.hi = Q.new(rng.pick([1, 2]))
	_solve(s)
	return s.xs.size() >= 2 and s.b.n > 1


static func _k_cos_to_tan(rng: Seeded, s: Dictionary) -> bool:
	s.fn = "tan"
	s.k = tan_value(rng)
	_solve(s)
	return true


## sin 2x = m cos x, or sin 2x = m sin x: m is twice a landmark value.
static func _double_equals_cos(rng: Seeded, s: Dictionary) -> bool:
	s.k = value(rng, false)
	s.m = TrigKit.times(s.k, 2)
	s.fn = "sin"
	s.xs = _merge(solve("cos", TrigKit.V(0), Q.new(1), Q.new(0), s.lo, s.hi), solve("sin", s.k, Q.new(1), Q.new(0), s.lo, s.hi))
	return true


static func _double_equals_sin(rng: Seeded, s: Dictionary) -> bool:
	s.k = value(rng, false) if rng.chance(0.4) else TrigKit.V(Q.new(1, 2))
	s.m = TrigKit.times(s.k, 2)
	s.fn = "cos"
	s.open_hi = rng.chance(0.3)
	s.xs = _merge(solve("sin", TrigKit.V(0), Q.new(1), Q.new(0), s.lo, s.hi, s.open_hi), solve("cos", s.k, Q.new(1), Q.new(0), s.lo, s.hi, s.open_hi))
	return true


static func _product_zero(rng: Seeded, s: Dictionary) -> bool:
	s.f1 = rng.pick(["sin", "cos"])
	s.f2 = "cos" if s.f1 == "sin" else "sin"
	s.fn = s.f2
	s.k = value(rng, false)
	s.xs = _merge(solve(s.f1, TrigKit.V(0), Q.new(1), Q.new(0), s.lo, s.hi), solve(s.f2, s.k, Q.new(1), Q.new(0), s.lo, s.hi))
	return true


## a cos²x − b sin²x = 0, with tan²x = a/b.
static func _squares_to_tan(rng: Seeded, s: Dictionary) -> bool:
	var p: Array = rng.pick([[1, 3], [3, 1], [1, 1]])
	var scale: int = rng.int_in(1, 3)
	s.ca = p[0] * scale
	s.cb = p[1] * scale
	s.fn = "tan"
	s.k = TrigKit.sqrt_q(Q.new(p[0], p[1]))
	s.hi = Q.new(rng.pick([1, 2]))
	s.xs = _merge(solve("tan", s.k, Q.new(1), Q.new(0), s.lo, s.hi), solve("tan", TrigKit.neg(s.k), Q.new(1), Q.new(0), s.lo, s.hi))
	return true


## sin²θ = m sin θ cos θ on 0 < θ < π: tan θ = m.
static func _factor_reject(rng: Seeded, s: Dictionary) -> bool:
	var m: Array = rng.pick([[1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [1, 2], [3, 2], [2, 3], [1, 3], [3, 4]])
	s.m = Q.new(m[0] * (1 if rng.chance(0.7) else -1), m[1])
	s.xs = [Q.new(1)]
	return true


static func _basic_decimal(rng: Seeded, s: Dictionary) -> bool:
	s.fn = rng.pick(TrigKit.FNS)
	s.k = Q.new(ExtensionViews.nonzero(rng, -19, 19) * 5 if s.fn == "tan" else ExtensionViews.nonzero(rng, -9, 9) * 10, 100)
	if s.k.mul(100).n % 50 == 0 and s.fn != "tan":
		return false
	s.xs = _numeric(s)
	return true


static func _compound_decimal(rng: Seeded, s: Dictionary) -> bool:
	s.fn = rng.pick(["sin", "cos"])
	s.k = Q.new(ExtensionViews.nonzero(rng, -9, 9) * 10, 100)
	s.b = Q.new(rng.int_in(2, 3))
	s.phi = Q.new(0)
	s.hi = Q.new(rng.pick([1, 2]))
	if s.k.mul(100).n % 50 == 0:
		return false
	s.xs = _numeric(s)
	return s.xs.size() >= 2


## The solutions of fn(bx) = k in radians, for a decimal k: Qs of the x itself, not of π.
static func _numeric(s: Dictionary) -> Array:
	var f: Callable = (func(x: float) -> float: return sin(s.b.to_float() * x) - s.k.to_float()) if s.fn == "sin" else ((func(x: float) -> float: return cos(s.b.to_float() * x) - s.k.to_float()) if s.fn == "cos" else (func(x: float) -> float: return tan(x) - s.k.to_float()))
	var hi: float = s.hi.to_float() * PI
	if s.fn == "tan":
		var out: Array = []
		for n in range(-1, 4):
			var x := atan(s.k.to_float()) + n * PI
			if x >= 0.0 and x <= hi:
				out.append(GdcKit.qf(x))
		return out
	return GdcKit.zeros(f, 0.0, hi).map(func(z): return GdcKit.qf(z))


static func _merge(a: Array, c: Array) -> Array:
	var seen := {}
	for x in a + c:
		seen[x.key()] = x
	var out: Array = seen.values()
	out.sort_custom(func(p, q): return p.lt(q))
	return out


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
