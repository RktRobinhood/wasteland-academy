class_name AiCompositeInverseSituation
extends RefCounted
## The `ai-composite-inverse` situation (curriculum/question-types.json): composite and inverse
## functions in context, for fn-ai-composite-inverse (AI-AHL2.7, FAL-1007). Every AI paper allows a
## GDC, so every question is Paper 2.
##
## need.ask is the unknown (see AiCompositeInverseViews), need.rep its representation. generate()
## returns a Dictionary with ask, rep and paper (2), and by unknown:
##   composite-*   story (STORIES: filters, furnace, convoy, scrap): an inner model g, from the
##                 input (hours, minutes) to a middle quantity (filters, °C, km, kg), and an outer
##                 model f from that quantity to the output (dollars, °F, litres, caps). g and f
##                 are polynomials, low power first, as Q (CompositePairSituation's form): g is
##                 always a line, f a line or (composite-rule, mostly) a quadratic. Then x0 (value),
##                 or target and t (equation: f(g(t)) = target), and t2, a second point of g to mark
##   composite-order  price, pct (% off: D(x) = (1 − pct/100)x), c and kind ("voucher": V(x) = x − c,
##                 "fee": V(x) = x + c), want ("lower" or "higher")
##   inverse-rule, inverse-value, inverse-identity  fam with its model:
##       lin   story (taxi, celsius, copper): m·x + b, m and b as Q
##       rat   story average: c + k/x
##       log   story signal: a + b·ln x
##       cubic story tank: a·x³ + c·x, increasing (inverse-value by the GDC only)
##     and v (the output an inverse is taken of), or for inverse-identity mode ("compose": (f∘f⁻¹)(v)
##     or "solve": f⁻¹(a) = b, with b)
##   restrict-domain, inverse-domain-range  fam quad: qa(x − qh)² + qk, story (pump, bridge,
##     profit), or (domain-range) fam interval: a line m·x + b on lo ≤ x ≤ hi, story (tank, fuel);
##     want "domain" or "range" (of f⁻¹)
##   inverse-graph  curve: a BasicOneToOneSituation curve (a line, a root, 2^x or half a parabola
##     with whole key points), so its reflections stay on the window
##
## The numbers are drawn, not taken from any exam question. The SymPy checker
## (tools/check_answers.py, r9ac_check) reads every model back from the text and works it out again.

const TRIES := 3000
## A 3 s.f. answer is at least this far (a fraction of its last place) from a rounding edge.
const EDGE := 0.04

## The composite stories: inner letter, its input letter, outer letter.
const STORIES := ["filters", "furnace", "convoy", "scrap"]
const LIN_STORIES := ["taxi", "celsius", "copper"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "composite-value")
	var rep: String = need.get("rep", "words")
	var angle: String = str(need.get("angle", ""))
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "rep": rep}
		if _draw(rng, s, angle):
			return s
	push_error("AiCompositeInverseSituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, s: Dictionary, angle: String) -> bool:
	match s.ask:
		"composite-value":
			return _value(rng, s)
		"composite-rule":
			return _rule(rng, s)
		"composite-order":
			return _order(rng, s)
		"composite-equation":
			return _equation(rng, s)
		"inverse-rule":
			return _inverse_rule(rng, s)
		"inverse-value":
			return _inverse_value(rng, s, angle)
		"restrict-domain":
			return _restrict(rng, s)
		"inverse-domain-range":
			return _domain_range(rng, s)
		"inverse-identity":
			return _identity(rng, s)
		"inverse-graph":
			var c := BasicOneToOneSituation.generate(rng, {"kind": "curve"})
			if c.is_empty():
				return false
			s.curve = c
			return true
	return false


# ── Numbers ──────────────────────────────────────────────────

static func q(n: int, d: int = 1) -> Q:
	return Q.new(n, d)


static func ev(co: Array, x: Variant) -> Q:
	return CompositePairSituation.peval(co, Q.of(x))


## outer(inner(x)), low power first.
static func comp(outer: Array, inner: Array) -> Array:
	return CompositePairSituation.pcompose(outer, inner)


## x to 3 s.f., as a Q.
static func q3(x: float) -> Q:
	var r := Answer.parse_number(Fmt.sf(x).replace("−", "-"))
	return r.q if r.ok else GdcKit.qf(x)


## Whether a value is written exactly: it has at most two decimal places.
static func ends(v: Q) -> bool:
	return v.mul(100).is_int() and v.abs_q().lt(1000000)


## Whether a float is a value with at most two decimal places.
static func ends_f(x: float) -> bool:
	return absf(x * 100.0 - roundf(x * 100.0)) < 1e-7 and absf(x) < 1e6


## Whether a value is fit to show: exact (two decimal places at most), or clear of a 3 s.f.
## rounding edge and not within a whisker of a two-place value.
static func fair(x: float) -> bool:
	if not is_finite(x) or x == 0.0:
		return false
	if ends_f(x):
		return true
	if absf(x) >= 0.1 and absf(x * 100.0 - roundf(x * 100.0)) < 0.05:
		return false
	return Answer.rounds_clearly(x, EDGE)


## The texts of a list of values as the options show them, all different.
static func distinct(vals: Array) -> bool:
	var seen := {}
	for v in vals:
		var t := Fmt.sf(v) if v is float else Fmt.sf(Q.of(v).to_float())
		if seen.has(t):
			return false
		seen[t] = true
	return true


## A value as an option holds it: exact when it has two decimal places at most, else its 3 s.f.
static func shown_q(v: Variant) -> Q:
	if v is Q:
		return v if ends(v) else q3(v.to_float())
	var x: float = float(v)
	return Q.new(roundi(x * 100.0), 100) if ends_f(x) else q3(x)


# ── Composites ───────────────────────────────────────────────

## g (inner) and f (outer, a line) for a story, with any constraint the story has.
static func _pair(rng: Seeded, s: Dictionary, quadratic: bool = false) -> bool:
	s.story = rng.pick(["filters", "scrap"] if quadratic else STORIES)
	match s.story:
		"filters":
			s.g = [q(rng.int_in(0, 6) * 5), q(rng.int_in(12, 40))]
			if quadratic:
				s.g = [q(rng.int_in(1, 4) * 5), q(rng.pick([10, 20, 25, 30, 40]))]
				s.f = [q(rng.int_in(5, 30) * 10), q(rng.int_in(1, 6)), q(rng.pick([1, 2, 5]), 100)]
			else:
				s.f = [q(rng.int_in(5, 40) * 10), q(rng.pick([150, 200, 225, 250, 320, 400, 450, 600]), 100)]
		"furnace":
			s.g = [q(rng.int_in(10, 25)), q(rng.int_in(5, 40))]
			s.f = [q(32), q(18, 10)]
		"convoy":
			s.g = [q(rng.int_in(0, 4) * 5), q(rng.int_in(8, 18) * 5)]
			s.f = [q(rng.int_in(6, 12) * 10), q(-rng.pick([5, 8, 10, 12, 15]), 100)]
		"scrap":
			s.g = [q(rng.int_in(0, 10)), q(rng.int_in(5, 20))]
			if quadratic:
				s.g = [q(rng.int_in(1, 10)), q(rng.int_in(4, 15))]
				s.f = [q(rng.int_in(2, 10) * 5), q(rng.int_in(1, 4)), q(rng.pick([2, 4, 5, 10]), 100)]
			else:
				s.f = [q(rng.int_in(2, 10) * 5), q(rng.pick([250, 300, 350, 400, 450, 500]), 100)]
	return true


## The input where the story stops making sense: fuel running out.
static func ok_at(s: Dictionary, x: Q) -> bool:
	return ev(s.f, ev(s.g, x)).sign() > 0


## g at a few whole inputs, for a graph or a table: none but x0 (or t) is required.
static func _value(rng: Seeded, s: Dictionary) -> bool:
	_pair(rng, s)
	var hi := 6 if s.rep == "table" else 8
	s.x0 = q(rng.int_in(1, hi - 1) if s.rep != "words" else rng.int_in(2, 9))
	if not ok_at(s, s.x0) or (s.story == "convoy" and not ok_at(s, q(hi))):
		return false
	s.t2 = q(rng.int_in(1, hi))
	if s.t2.eq(s.x0):
		return false
	var v := ev(s.f, ev(s.g, s.x0))
	var vals: Array = [v, ev(s.f, s.x0).mul(ev(s.g, s.x0)), ev(s.g, s.x0), ev(s.f, s.x0)]
	if s.rep == "words":
		vals.append(ev(s.g, ev(s.f, s.x0)))
	return distinct(vals.map(func(x): return x.to_float())) and vals.all(func(x): return absf(x.to_float()) < 1e6)


static func _rule(rng: Seeded, s: Dictionary) -> bool:
	var quad := rng.chance(0.75)
	_pair(rng, s, quad)
	var right := comp(s.f, s.g)
	var swapped := comp(s.g, s.f)
	return not CompositePairSituation.same(right, swapped)


static func _order(rng: Seeded, s: Dictionary) -> bool:
	s.price = rng.int_in(4, 40) * 5
	s.pct = rng.pick([10, 15, 20, 25, 30, 40])
	s.c = rng.int_in(2, 15)
	s.kind = "voucher" if rng.chance(0.6) else "fee"
	s.want = rng.pick(["lower", "higher"])
	return s.price > 3 * s.c


## f(g(t)) = target: on the graph, t is a whole number of hours and g(t) a whole value; in words
## the target is round, so t is usually a GDC value.
static func _equation(rng: Seeded, s: Dictionary) -> bool:
	_pair(rng, s)
	var h := comp(s.f, s.g)
	if s.rep == "graph":
		s.t = q(rng.int_in(2, 7))
		s.target = ev(h, s.t)
		s.t2 = q(rng.int_in(1, 8))
		if s.t2.eq(s.t):
			return false
	else:
		var tt := rng.int_in(25, 95) / 10.0
		var raw := ev(h, GdcKit.qf(tt)).to_float()
		var step := 10.0 if absf(raw) < 400.0 else 50.0
		s.target = q(roundi(raw / step) * roundi(step))
		s.t = s.target.sub(h[0]).div(h[1])
	var t: Q = s.t
	if t.to_float() <= 0.5 or not ok_at(s, t) or not fair(t.to_float()) or s.target.sign() <= 0:
		return false
	# The order slip: g(f(t)) = target.
	var hw := comp(s.g, s.f)
	var target: Q = s.target
	var slip := target.sub(hw[0]).div(hw[1])
	var mid := target.sub(s.f[0]).div(s.f[1])
	var ginv := target.sub(s.g[0]).div(s.g[1])
	# A negative time from the other order is no option a student would keep: it is left out.
	var vals: Array = [t, mid, ginv] + ([slip] if slip.sign() > 0 else [])
	return vals.all(func(x): return fair(x.to_float()) and absf(x.to_float()) < 1e6) and distinct(vals.map(func(x): return x.to_float()))


# ── Inverses ─────────────────────────────────────────────────

static func _model(rng: Seeded, s: Dictionary, fams: Array) -> void:
	s.fam = rng.pick(fams)
	match s.fam:
		"lin":
			s.story = rng.pick(LIN_STORIES)
			match s.story:
				"taxi":
					s.m = q(rng.pick([160, 180, 220, 240, 275, 350]), 100)
					s.b = q(rng.pick([30, 35, 40, 45, 50, 60]), 10)
				"celsius":
					s.m = q(18, 10)
					s.b = q(32)
				_:
					s.m = q(rng.pick([15, 25, 35, 45, 60, 75]), 10)
					s.b = q(rng.int_in(2, 9) * 5)
		"rat":
			s.story = "average"
			s.c = q(rng.pick([15, 20, 25, 30, 45]), 10)
			s.k = q(rng.int_in(4, 18) * 50)
		"log":
			s.story = "signal"
			s.a = q(rng.int_in(2, 6))
			s.b = q(rng.pick([20, 25, 30, 40, 50]), 10)
		"cubic":
			s.story = "tank"
			s.a = q(rng.pick([1, 2, 5]), 10)
			s.c = q(rng.pick([10, 15, 20, 30]), 10)


## f(x) for the inverse families, as a float.
static func fval(s: Dictionary, x: float) -> float:
	match s.fam:
		"lin", "interval":
			return s.m.to_float() * x + s.b.to_float()
		"rat":
			return s.c.to_float() + s.k.to_float() / x
		"log":
			return s.a.to_float() + s.b.to_float() * log(x)
		"cubic":
			return s.a.to_float() * x * x * x + s.c.to_float() * x
		"quad":
			return s.qa.to_float() * (x - s.qh.to_float()) * (x - s.qh.to_float()) + s.qk.to_float()
	return NAN


## f⁻¹(y), as a float (the cubic by Brent's root finder, as a GDC solver would).
static func finv(s: Dictionary, y: float) -> float:
	match s.fam:
		"lin", "interval":
			return (y - s.b.to_float()) / s.m.to_float()
		"rat":
			return s.k.to_float() / (y - s.c.to_float())
		"log":
			return exp((y - s.a.to_float()) / s.b.to_float())
		"cubic":
			var fn := func(x: float) -> float: return fval(s, x) - y
			var r := Brent.root(fn, 0.0, 100.0)
			return r.x if r.ok else NAN
	return NAN


## f⁻¹(y) exactly, where it is a fraction (lin, rat), else null.
static func finv_q(s: Dictionary, y: Q) -> Variant:
	match s.fam:
		"lin", "interval":
			return y.sub(s.b).div(s.m)
		"rat":
			return null if y.eq(s.c) else s.k.div(y.sub(s.c))
	return null


## The steps of f undone in the original order (the slip): lin (y/m) − b, rat k/y − c,
## log (e^y − a)/b. NAN for the cubic.
static func wrong_order(s: Dictionary, y: float) -> float:
	match s.fam:
		"lin":
			return y / s.m.to_float() - s.b.to_float()
		"rat":
			return s.k.to_float() / y - s.c.to_float()
		"log":
			return (exp(y) - s.a.to_float()) / s.b.to_float()
	return NAN


static func _inverse_rule(rng: Seeded, s: Dictionary) -> bool:
	_model(rng, s, ["lin", "lin", "rat", "log"])
	return true


## v: an output with f⁻¹(v) a fair value; the slips 1/f(v), the steps undone in the wrong order
## and f(v), each different at 3 s.f.
static func _inverse_value(rng: Seeded, s: Dictionary, angle: String) -> bool:
	var fams := ["lin", "lin", "rat", "log"]
	if angle == "solve-for-value":
		fams.append_array(["cubic", "cubic"])
	_model(rng, s, fams)
	match s.fam:
		"lin":
			var x := rng.int_in(20, 150) / 10.0 if s.story != "celsius" else float(rng.int_in(-15, 45))
			s.v = GdcKit.qf(fval(s, x)) if s.story == "celsius" else q(roundi(fval(s, x) * 10.0), 10)
		"rat":
			# A whole number of filters, with an average cost that ends.
			var n := rng.int_in(20, 400)
			var k: Q = s.k
			if (k.n * 100) % n != 0:
				return false
			s.v = s.c.add(k.div(n))
		"log":
			s.v = s.a.add(q(rng.int_in(20, 80), 10))
		"cubic":
			s.v = q(rng.int_in(4, 30) * 5)
	var v: Q = s.v
	var ans := finv(s, v.to_float())
	if not fair(ans) or ans <= 0.0:
		return false
	var vals: Array = [ans, 1.0 / fval(s, v.to_float()), fval(s, v.to_float())]
	if s.fam != "cubic":
		var w := wrong_order(s, v.to_float())
		if not is_finite(w) or absf(w) > 1e6:
			return false
		vals.append(w)
	return vals.all(func(x): return fair(x)) and distinct(vals)


# ── Restricting a quadratic ──────────────────────────────────

const QUAD_STORIES := ["pump", "bridge", "profit"]


## qa(x − qh)² + qk: a pump's hourly cost and a bridge's height (minima), a profit (a maximum).
static func _quad(rng: Seeded, s: Dictionary) -> bool:
	s.fam = "quad"
	s.story = rng.pick(QUAD_STORIES)
	match s.story:
		"pump":
			s.qa = q(rng.pick([25, 50, 100, 150, 200]), 100)
			s.qh = q(rng.int_in(3, 12))
			s.qk = q(rng.int_in(4, 30))
		"bridge":
			s.qa = q(rng.pick([2, 4, 5, 8, 10]), 100)
			s.qh = q(rng.int_in(5, 15))
			s.qk = q(rng.int_in(10, 40), 10)
		_:
			s.qa = q(-rng.pick([1, 2, 3, 4]))
			s.qh = q(rng.int_in(6, 20))
			s.qk = q(rng.int_in(10, 60) * 10)
	return true


## The quadratic's coefficients [c, b, a], low power first.
static func quad_co(s: Dictionary) -> Array:
	var a: Q = s.qa
	var h: Q = s.qh
	return [a.mul(h).mul(h).add(s.qk), a.mul(h).mul(-2), a]


static func _restrict(rng: Seeded, s: Dictionary) -> bool:
	_quad(rng, s)
	var co := quad_co(s)
	var h: Q = s.qh
	# x ≥ 0 (the y-intercept) and x ≥ the vertex's y are the slips: each different from h.
	var vals: Array = [h, q(0), s.qk, h.neg(), h.mul(2)]
	return not co[0].is_zero() and distinct(vals.map(func(x): return x.to_float())) and s.qk.abs_q().lt(1000)


static func _domain_range(rng: Seeded, s: Dictionary) -> bool:
	s.want = "domain" if rng.chance(0.65) else "range"
	if rng.chance(0.55):
		_quad(rng, s)
		var co := quad_co(s)
		return not co[0].eq(s.qk) and not co[0].is_zero() and not s.qk.eq(s.qh) and not s.qk.eq(s.qh.neg())
	s.fam = "interval"
	s.story = rng.pick(["tank-line", "fuel"])
	s.lo = 0
	if s.story == "tank-line":
		s.m = q(rng.pick([15, 20, 25, 30, 40, 45]), 10)
		s.b = q(rng.int_in(2, 12) * 5)
		s.hi = rng.int_in(4, 12) * 5
	else:
		s.m = q(-rng.pick([5, 8, 10, 12, 15]), 100)
		s.b = q(rng.int_in(6, 12) * 10)
		s.hi = rng.int_in(4, 16) * 25
		if fval(s, float(s.hi)) < 5.0:
			return false
	var y0 := q(roundi(fval(s, float(s.lo)) * 100.0), 100)
	var y1 := q(roundi(fval(s, float(s.hi)) * 100.0), 100)
	return not y0.eq(y1) and not y1.eq(s.hi) and not y0.eq(s.hi)


# ── f∘f⁻¹ ────────────────────────────────────────────────────

static func _identity(rng: Seeded, s: Dictionary) -> bool:
	_model(rng, s, ["lin", "lin", "lin", "rat"])
	s.mode = "compose" if rng.chance(0.5) else "solve"
	if s.mode == "compose":
		# (f∘f⁻¹)(v): v in the range of f, with f⁻¹(v) and f(v) shown exactly or to 3 s.f.
		if s.fam == "rat":
			s.v = s.c.add(q(rng.int_in(1, 30), 10))
		elif s.story == "celsius":
			s.v = q(rng.int_in(40, 110))
		else:
			# Above the fixed charge, so f⁻¹(v) is a distance or a mass.
			s.v = s.b.add(q(rng.int_in(2, 60)))
		var v: Q = s.v
		var vals: Array = [v.to_float(), 1.0, fval(s, v.to_float()), finv(s, v.to_float())]
		return vals.all(func(x): return fair(x)) and distinct(vals)
	# f⁻¹(a) = b: a = f(b).
	s.bv = q(rng.int_in(2, 30)) if s.story != "celsius" else q(rng.int_in(5, 40))
	var b: Q = s.bv
	var a := fval(s, b.to_float())
	var vals2: Array = [a, finv(s, b.to_float()), b.to_float(), fval(s, b.to_float() + 1.0)]
	if s.fam == "rat" and b.eq(s.c):
		return false
	return vals2.all(func(x): return fair(x) and x > 0.0) and distinct(vals2)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
