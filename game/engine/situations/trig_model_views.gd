class_name TrigModelViews
extends ExtensionViews
## The views on the `trig-model` situation: one builder per unknown of t3-trig-model-parameters
## (FAL-727). Paper 1 is exact, with x in multiples of π, and an answer is a `named` number or a
## `form` with π in it. Paper 2 is a story in t, answered to 3 s.f. with the rounding trap.
##
## Representations: "equation" (written out), "graph" (the wave with its turning points marked)
## and "words" (a story).

const R_PERIOD_GAP := "SL3.7.equation-from-graph#0"
const R_NO_HALF := "SL3.7.equation-from-graph#1"
const R_C_SIGN := "SL3.7.equation-from-graph#2"
const R_SHIFT_B := "SL3.7.transformations#0"
const R_STRETCH := "SL3.7.transformations#1"
const R_RIGHT := "SL3.7.transformations#2"
const R_DEGREES := "SL3.7.model-context#0"
const R_PERIOD_B := "SL3.7.model-context#2"

## What each story measures, its unit of height and of time, and its name for the wave.
const CONTEXTS := [
	{"thing": "The depth of water at the old harbour wall", "sym": "D", "unit": "m", "time": "hours"},
	{"thing": "The temperature inside the grain store", "sym": "T", "unit": "°C", "time": "hours"},
	{"thing": "The height of a seat on the salvage-yard wheel", "sym": "h", "unit": "m", "time": "minutes"},
	{"thing": "The water level behind the dam", "sym": "L", "unit": "m", "time": "days"},
	{"thing": "The power draw of the generator shed", "sym": "P", "unit": "kW", "time": "minutes"},
	{"thing": "The length of a mooring rope", "sym": "R", "unit": "m", "time": "hours"},
]
const UNKNOWNS := ["amp-axis", "b-from-period", "c-cos-from-max", "c-sine-shift", "all-four", "q-from-minimum", "sum-as-cos", "tan-two-points",
	"shift-from-bracket", "image-equation", "describe-transformations", "pq-from-translation", "wheel-model", "c-from-crossing", "level-from-duration"]
const P1_ONLY := ["q-from-minimum"]
const P2_ONLY := ["sum-as-cos", "tan-two-points", "wheel-model", "c-from-crossing", "level-from-duration"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## A wave on the GDC needs Paper 2, and a story is in hours, not multiples of π.
func papers(unknown: String, rep: String, method_id: String) -> Array:
	if not has(unknown):
		return []
	if unknown in P1_ONLY:
		return [1]
	if unknown in P2_ONLY or rep == "words" or method_id in ["gdc-check", "gdc-overlay"]:
		return [2]
	return [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = TrigModelSituation.export(s)
	return out


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func D(v: Variant) -> String:
	return Fmt.dec(v)


## b as a float: 2π ÷ the period, or the whole w of Paper 1.
static func bf(s: Dictionary) -> float:
	return float(s.w) if s.paper == 1 else TAU / s.period.to_float()


## The letter across: x on Paper 1, t in a story.
static func L(s: Dictionary) -> String:
	return "x" if s.paper == 1 else "t"


## A place on the across axis: a multiple of π, or a number.
static func X(s: Dictionary, v: Q) -> String:
	return Fmt.pi(v) if s.paper == 1 else D(v)


static func ctx(s: Dictionary) -> Dictionary:
	return CONTEXTS[s.ctx]


static func pt(s: Dictionary, x: Q, y: Q) -> String:
	return "(%s, %s)" % [X(s, x), D(y)]


## The wave as a graph spec, with its first maximum and next minimum marked.
static func graph_of(s: Dictionary) -> Dictionary:
	var b := bf(s)
	var a: float = s.a.to_float()
	var d: float = s.d.to_float()
	var xm: float = s.xmax.to_float() * (PI if s.paper == 1 else 1.0)
	var low := minf(0.0, s.low.to_float() - 1.0)
	var high: float = s.top.to_float() + 1.0
	var f := func(x: float) -> float: return a * cos(b * (x - xm)) + d
	if s.paper == 1:
		var tick := Q.new(1, s.w * (2 if s.w == 1 else 1) * 2) if s.w < 3 else Q.new(1, 2)
		var hi: Q = s.xmin.add(Q.new(1, s.w))
		if hi.lt(Q.new(2)):
			hi = Q.new(2)
		var g := TrigKit.wave(f, Q.new(0), hi, floori(low), ceili(high), tick,
			[[xm, s.top.to_float(), "max " + pt(s, s.xmax, s.top)], [s.xmin.to_float() * PI, s.low.to_float(), "min " + pt(s, s.xmin, s.low)]])
		return g
	var span: int = ceili(s.xmin.to_float() + s.period.to_float() / 4.0)
	var g := Plot.spec([Plot.sample(f, 0.0, float(span))], [[xm, s.top.to_float(), "max " + pt(s, s.xmax, s.top)], [s.xmin.to_float(), s.low.to_float(), "min " + pt(s, s.xmin, s.low)]], 0, span, floori(low), ceili(high))
	g.x_name = "t"
	g.y_name = ctx(s).sym
	return g


## The facts of the wave, in the shape of the representation.
static func show(rep: String, s: Dictionary, facts: String) -> Dictionary:
	var f: String = "f" if s.paper == 1 else ctx(s).sym
	if rep == "graph":
		return {"lines": ["The graph shows part of %s(%s) = %s." % [f, L(s), facts]], "graph": graph_of(s)}
	if rep == "words":
		var c := ctx(s)
		return {"lines": ["%s is modelled by %s(t) = %s, with t in %s." % [c.thing, c.sym, facts, c.time],
			"Its largest value is %s %s, at t = %s, and its next smallest value is %s %s, at t = %s." % [D(s.top), c.unit, D(s.xmax), D(s.low), c.unit, D(s.xmin)]], "graph": null}
	return {"lines": ["%s(%s) = %s" % [f, L(s), facts], "A maximum is at %s and the next minimum at %s." % [pt(s, s.xmax, s.top), pt(s, s.xmin, s.low)]], "graph": null}


static func num_ans(s: Dictionary, label: String, v: Variant) -> Dictionary:
	var ans := Answer.make("number", {"v": Q.of(v)}, {}, label)
	ans.exact = Q.of(v).d <= 1000
	ans.show = "dec"
	return ans


static func fnum(label: String, x: float) -> Dictionary:
	var ans := Answer.make("number", {"v": GdcKit.qf(x)}, {}, label)
	ans.show = "sf"
	return ans


static func named(names: Array, vals: Array, sf: bool) -> Dictionary:
	var v := {}
	for i in vals.size():
		v["v%d" % i] = vals[i] if vals[i] is Q else GdcKit.qf(vals[i])
	var ans := Answer.make("named", v, {"names": names})
	if sf:
		ans.show = "sf"
	else:
		ans.show = "dec"
		ans.exact = true
	return ans


static func named_vals(vals: Array) -> Dictionary:
	var v := {}
	for i in vals.size():
		v["v%d" % i] = vals[i] if vals[i] is Q else GdcKit.qf(vals[i])
	return v


func u_amp_axis(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := named(["a", "d"], [s.a, s.d], false)
	var v := show(rep, s, "a cos(b(%s − c)) + d, a > 0" % L(s))
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "asked": "Find a and d."}
	out.wrongs = [wrong(named_vals([s.top.sub(s.low), s.d]), R_NO_HALF)]
	out.generic = [named_vals([s.a, s.top]), named_vals([s.d, s.a]), named_vals([s.a, s.low]), named_vals([s.a, s.d.add(1)])]
	var r := "a = (max − min) ÷ 2 = (%s − %s) ÷ 2 = %s" % [D(s.top), P(s.low), D(s.a)]
	var m := "d = (max + min) ÷ 2 = (%s + %s) ÷ 2 = %s" % [D(s.top), P(s.low), D(s.d)]
	out.methods = {"max-min-averages": method([r, m, say(a)], a.values)}
	return out


func u_b_from_period(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := show(rep, s, "a cos(b(%s − c)) + d, b > 0" % L(s))
	var out := {"lines": v.lines, "graph": v.graph}
	if s.paper == 1:
		var a := num_ans(s, "b = ", s.w)
		out.answer = a
		out.asked = "Find b."
		out.wrongs = [wrong({"v": Q.new(2 * s.w)}, R_PERIOD_GAP)]
		out.generic = [{"v": Q.new(s.w + 1)}, {"v": Q.new(3 * s.w)}, {"v": Q.new(1, 2).mul(s.w)}, {"v": Q.new(s.w).add(Q.new(1, 2))}].filter(func(g): return not g.v.eq(s.w))
		out.methods = {"max-min-averages": method(["The gap from a maximum to the next minimum is %s, half a period." % Fmt.pi(s.xmin.sub(s.xmax)), "The period is %s, so b = 2π ÷ %s = %d" % [Fmt.pi(Q.new(2, s.w)), Fmt.pi(Q.new(2, s.w)), s.w], say(a)], a.values)}
		return out
	var T: float = s.period.to_float()
	var a := fnum("b = ", TAU / T)
	out.answer = a
	out.asked = "Find b, to 3 significant figures."
	out.wrongs = [wrong({"v": GdcKit.qf(TAU / (T / 2.0))}, R_PERIOD_GAP), wrong({"v": GdcKit.qf(T)}, R_PERIOD_B)]
	out.generic = [{"v": GdcKit.qf(PI / T / 2.0)}, {"v": GdcKit.qf(T / TAU)}, {"v": GdcKit.qf(TAU / T + 0.2)}]
	out.methods = {"max-min-averages": method(["The gap from a maximum to the next minimum is %s, half a period." % D(s.period.div(2)), "The period is %s, so b = 2π ÷ %s = %s" % [D(s.period), D(s.period), GdcKit.W(TAU / T)], say(a)], a.values)}
	return out


## c as an answer: a Q of π on Paper 1 (a `form`), a number on Paper 2.
static func c_ans(s: Dictionary, v: Q) -> Dictionary:
	if s.paper == 1:
		return ArcSectorViews.ans_of({"paper": 1}, "c = ", ArcSectorViews.ab(0, v))
	return num_ans(s, "c = ", v)


static func c_like(a: Dictionary, s: Dictionary, v: Q, ref: String = "") -> Array:
	if s.paper == 1:
		return [DifferentiationViews.alt("c = " + Fmt.pi(v), ref, {"b": v} if v.sign() > 0 and a.shape == "p" else {})]
	return [wrong({"v": v}, ref)]


static func c_others(a: Dictionary, s: Dictionary, vs: Array) -> Array:
	var out: Array = []
	for v in vs:
		for w in c_like(a, s, v):
			out.append(w.values)
	return out


func u_c_cos_from_max(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Q = s.xmax
	var a := c_ans(s, c)
	var v := show(rep, s, "%s cos(%s(%s − c)) + %s" % [D(s.a), b_text(s), L(s), D(s.d)])
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "asked": "Find the smallest positive value of c."}
	out.wrongs = c_like(a, s, c.neg(), R_C_SIGN)
	out.generic = c_others(a, s, [s.xmin, c.mul(2), c.add(s.xmin), c.div(2), s.xmin.sub(c)])
	var at := X(s, c)
	out.methods = {"cos-at-max": method(["cos is largest at 0, so a cos(b(%s − c)) + d has a maximum at %s = c." % [L(s), L(s)], "The first maximum is at %s = %s." % [L(s), at], say(a)], a.values),
		"substitute-point": method(["Put in the maximum: %s = %s cos(%s(%s − c)) + %s" % [D(s.top), D(s.a), b_text(s), at, D(s.d)], "So cos(%s(%s − c)) = 1, and the bracket is 0." % [b_text(s), at], say(a)], a.values)}
	return out


## b as the equation writes it: a whole number on Paper 1, 2π/T in a story.
static func b_text(s: Dictionary) -> String:
	if s.paper == 1:
		return str(s.w)
	return "π/%s" % D(s.period.div(2)) if s.period.div(2).is_int() else "2π/%s" % D(s.period)


func u_c_sine_shift(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var quarter: Q = Q.new(1, 2 * s.w) if s.paper == 1 else s.period.div(4)
	var c: Q = s.xmax.sub(quarter)
	var a := c_ans(s, c)
	var v := show(rep, s, "%s sin(%s(%s − c)) + %s" % [D(s.a), b_text(s), L(s), D(s.d)])
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "asked": "Find the smallest positive value of c."}
	out.wrongs = c_like(a, s, quarter.sub(s.xmax), R_C_SIGN)
	out.generic = c_others(a, s, [s.xmax, s.xmax.add(quarter), quarter, c.mul(2), s.xmin.sub(quarter), s.xmin.sub(s.xmax)])
	var at := X(s, s.xmax)
	var bt := b_text(s)
	var q := X(s, quarter)
	out.methods = {"substitute-point": method(["Put in the maximum: sin(%s(%s − c)) = 1." % [bt, at], "So %s(%s − c) = π/2, which is %s − c = %s." % [bt, at, at, q], say(a)], a.values),
		"solve-analytically": method(["sin is largest at π/2, a quarter of a period after it crosses the axis going up.", "A quarter of a period is %s, so c = %s − %s." % [q, at, q], say(a)], a.values)}
	return out


## a, b, c and d, as Paper 1's `form` or Paper 2's `named`.
static func four_ans(s: Dictionary) -> Dictionary:
	if s.paper == 2:
		return named(["a", "b", "c", "d"], [s.a, TAU / s.period.to_float(), s.xmax, s.d], true)
	var text := four_text(s.a, Q.new(s.w), s.xmax, s.d)
	return DifferentiationViews.form(text, ["a = ", {"slot": "a"}, ", b = ", {"slot": "b"}, ", c = ", {"slot": "c"}, "π, d = ", {"slot": "d"}], {"a": s.a, "b": Q.new(s.w), "c": s.xmax, "d": s.d})


static func four_text(a: Q, b: Q, c: Q, d: Q) -> String:
	return "a = %s, b = %s, c = %s, d = %s" % [D(a), D(b), Fmt.pi(c), D(d)]


static func four_like(s: Dictionary, a: Q, bv: Variant, c: Q, d: Q, ref: String = "") -> Dictionary:
	if s.paper == 2:
		return wrong(named_vals([a, bv, c, d]), ref)
	return DifferentiationViews.alt(four_text(a, bv, c, d), ref, {"a": a, "b": bv, "c": c, "d": d})


func u_all_four(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := four_ans(s)
	var v := show(rep, s, "a cos(b(%s − c)) + d" % L(s))
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "asked": ("Find a, b, c and d, with a, b > 0 and c the first maximum." if s.paper == 1 else "Find a, b, c and d, with a, b > 0 and c the first maximum. Give each to 3 significant figures.")}
	var b: Variant = Q.new(s.w) if s.paper == 1 else TAU / s.period.to_float()
	var b2: Variant = b.mul(2) if s.paper == 1 else b * 2.0
	out.wrongs = [four_like(s, s.top.sub(s.low), b, s.xmax, s.d, R_NO_HALF), four_like(s, s.a, b2, s.xmax, s.d, R_PERIOD_GAP), four_like(s, s.a, b, s.xmax.neg(), s.d, R_C_SIGN)]
	out.generic = [four_like(s, s.a, b, s.xmin, s.d).values, four_like(s, s.d, b, s.xmax, s.a).values]
	var gap := X(s, s.xmin.sub(s.xmax))
	var per := X(s, s.xmin.sub(s.xmax).mul(2))
	var first := "a = (%s − %s) ÷ 2 = %s, d = (%s + %s) ÷ 2 = %s" % [D(s.top), P(s.low), D(s.a), D(s.top), P(s.low), D(s.d)]
	var second := "The gap to the next minimum is %s, so the period is %s and b = 2π ÷ %s = %s" % [gap, per, per, str(s.w) if s.paper == 1 else GdcKit.W(b)]
	var third := "c is the first maximum: c = %s" % X(s, s.xmax)
	out.methods = {"max-min-averages": method([first, second, third, say(a)], a.values),
		"cos-at-max": method(["Use cosine, so c is simply the x-coordinate of the maximum: c = %s." % X(s, s.xmax), first, second, say(a)], a.values),
		"gdc-check": method([first, second, third, "Graph the model: it passes through both turning points.", say(a)], a.values)}
	return out


## x + φ, with φ a multiple of π.
static func bracket_text(s: Dictionary) -> String:
	return "x + %s" % Fmt.pi(s.phi)


func u_q_from_minimum(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var fn: String = s.fn
	var v := TrigKit.plus(TrigKit.times(TrigKit.of(fn, s.phi), s.p), TrigKit.V(s.q0))
	var a := TrigKit.ans("f(0) = ", v)
	var eq := "f(x) = %d %s(%s) + q" % [s.p, fn, bracket_text(s)]
	var out := {"answer": a, "lines": [eq, "The minimum value of f is %s." % N(s.m)], "asked": "Find the exact value of the y-intercept of the graph of f."}
	if rep == "graph":
		var size: float = float(s.p)
		var q0: float = s.q0
		var ph: float = s.phi.to_float() * PI
		var f := func(x: float) -> float: return size * (sin(x + ph) if fn == "sin" else cos(x + ph)) + q0
		var g := TrigKit.wave(f, Q.new(0), Q.new(2), mini(-1, s.m - 1), s.q0 + s.p + 1, Q.new(1, 2), [])
		g.hlines = [{"at": float(s.m), "label": "y = " + N(s.m)}]
		out.lines = [eq, "The graph of f has its lowest points on the dashed line y = %s." % N(s.m)]
		out.graph = g
	var wrong_q := TrigKit.plus(TrigKit.times(TrigKit.of(fn, s.phi), s.p), TrigKit.V(s.m))
	out.wrongs = TrigKit.like(a, wrong_q)
	out.generic = TrigKit.others(a, [TrigKit.plus(TrigKit.neg(TrigKit.times(TrigKit.of(fn, s.phi), s.p)), TrigKit.V(s.q0)), TrigKit.plus(TrigKit.of(fn, s.phi), TrigKit.V(s.q0)), TrigKit.V(s.q0), TrigKit.plus(v, TrigKit.V(1)), TrigKit.plus(v, TrigKit.V(2))])
	var first := "The minimum of f is q − %d, so q − %d = %s and q = %s." % [s.p, s.p, N(s.m), N(s.q0)]
	var at0 := "f(0) = %d %s(%s) + %s" % [s.p, fn, Fmt.pi(s.phi), P(s.q0)]
	out.methods = {"max-min-averages": method([first, "The y-intercept is f(0): %s = %s" % [at0, TrigKit.text(v)], say(a)], a.values),
		"substitute-point": method(["q is the midline, %d above the minimum: q = %s + %d = %s." % [s.p, N(s.m), s.p, N(s.q0)], "Put x = 0: %s = %s" % [at0, TrigKit.text(v)], say(a)], a.values)}
	return out


func u_sum_as_cos(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: float = s.p
	var q: float = s.q0
	var k: float = s.k
	var amp := sqrt(p * p + q * q)
	var c := atan2(p, q) / k
	var a := named(["a", "b", "c"], [amp, Q.new(s.k), c], true)
	var eq := "g(x) = %d sin %sx + %d cos %sx" % [s.p, _k(s), s.q0, _k(s)]
	var out := {"answer": a, "lines": [eq], "asked": "Write g(x) in the form a cos(b(x − c)), with a, b > 0 and c the first maximum to the right of 0. Give a and c to 3 significant figures."}
	if rep == "graph":
		var f := func(x: float) -> float: return p * sin(k * x) + q * cos(k * x)
		var span := ceili(TAU / k + 1.0)
		var g := Plot.spec([Plot.sample(f, 0.0, float(span))], [[c, amp, "max (%s, %s)" % [GdcKit.S(c), GdcKit.S(amp)]]], 0, span, -ceili(amp) - 1, ceili(amp) + 1)
		out.lines = [eq, "The graph of y = g(x) is shown, with its first maximum marked."]
		out.graph = g
	out.wrongs = [wrong(named_vals([2.0 * amp, Q.new(s.k), c]), R_NO_HALF), wrong(named_vals([amp, Q.new(s.k), -c]), R_C_SIGN)]
	out.generic = [named_vals([amp, Q.new(2 * s.k), c]), named_vals([p + q, Q.new(s.k), c]), named_vals([amp, Q.new(s.k), c + 0.5])]
	var f1 := "On a GDC, the maximum of g is at (%s, %s)." % [GdcKit.W(c), GdcKit.W(amp)]
	var f2 := "g has the period of sin %sx, 2π ÷ %d, so b = %d." % [_k(s), s.k, s.k]
	out.methods = {"max-min-averages": method([f1, "The range is symmetric about 0, so a is the maximum value: a = %s" % GdcKit.W(amp), f2, say(a)], a.values),
		"cos-at-max": method([f1, "In a cos(b(x − c)), c is where the maximum is: c = %s" % GdcKit.W(c), f2, say(a)], a.values),
		"gdc-check": method([f1, f2, "Graph both forms: they lie on top of each other.", say(a)], a.values)}
	return out


## A GDC value in the working, in brackets where it is negative.
static func PW(x: float) -> String:
	return "(%s)" % GdcKit.W(x) if x < 0.0 else GdcKit.W(x)


static func _k(s: Dictionary) -> String:
	return "" if s.k == 1 else str(s.k)


func u_tan_two_points(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: float = PI / s.z.to_float()
	var av: float = s.v.to_float() / tan(b * s.h.to_float())
	var a := named(["a", "b"], [av, b], true)
	var eq := "f(x) = a tan(bx), with a, b > 0."
	var zt := "(%s, 0)" % D(s.z)
	var pt_ := "(%s, %s)" % [D(s.h), D(s.v)]
	var out := {"answer": a, "lines": [eq, "The graph passes through %s, and %s is the first x-intercept to the right of the origin." % [pt_, zt]], "asked": "Find a and b, to 3 significant figures."}
	if rep == "graph":
		var f := func(x: float) -> float:
			var y: float = av * tan(b * x)
			return y if absf(y) <= 2.2 * s.v.to_float() else NAN
		var span: int = ceili(s.z.to_float() * 1.4)
		var top: int = ceili(2.2 * s.v.to_float()) + 1
		var g := Plot.spec(TrigKit.branches(Plot.sample(f, 0.0, float(span))), [[s.h.to_float(), s.v.to_float(), pt_], [s.z.to_float(), 0.0, zt]], 0, span, -top, top)
		out.lines = [eq, "The graph of f is shown, with two points on it. The point on the x-axis is the first x-intercept to the right of the origin."]
		out.graph = g
	out.wrongs = [wrong(named_vals([s.v.to_float() / tan(TAU / s.z.to_float() * s.h.to_float()), TAU / s.z.to_float()]))]
	var deg: float = s.v.to_float() / tan(deg_to_rad(b * s.h.to_float()))
	out.generic = [named_vals([s.v.to_float() / s.h.to_float(), b]), named_vals([av, b * 2.0 + 0.1]), named_vals([av + 1.0, b]), named_vals([deg, b])]
	var f1 := "tan has period π, and the first x-intercept is one period along: π ÷ b = %s, so b = %s" % [D(s.z), GdcKit.W(b)]
	var f2 := "Put in %s: %s = a tan(%s × %s), so a = %s" % [pt_, D(s.v), GdcKit.W(b), D(s.h), GdcKit.W(av)]
	out.methods = {"substitute-point": method([f1, f2, say(a)], a.values),
		"gdc-check": method([f1, f2, "Graph y = %s tan(%s x): it passes through both points." % [GdcKit.S(av), GdcKit.S(b)], say(a)], a.values)}
	return out


# ── Transformations ──────────────────────────────────────────

## φ as the bracket writes it.
static func ph(s: Dictionary, v: Q) -> String:
	return Fmt.pi(v) if s.paper == 1 else D(v)


## "2x − π/3" or "2x + 1.2".
static func raw_bracket(s: Dictionary) -> String:
	return "%dx %s %s" % [s.bw, "−" if s.right else "+", ph(s, s.phi)]


static func lifted(amp: int, fn: String, inner: String, lift: int) -> String:
	return "%d %s(%s) %s %d" % [amp, fn, inner, "+" if lift > 0 else "−", absi(lift)]


func u_shift_from_bracket(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Q = s.phi.div(s.bw)
	if not s.right:
		c = c.neg()
	var a := _signed_c(s, c)
	var eq := "y = " + lifted(s.amp, s.fn, raw_bracket(s), s.lift)
	var out := {"answer": a, "lines": [eq, "This is y = a %s(b(x − c)) + d." % s.fn], "asked": "Find c."}
	out.wrongs = _signed_like(a, s, s.phi if s.right else s.phi.neg(), R_SHIFT_B) + _signed_like(a, s, c.neg(), R_RIGHT)
	out.generic = _signed_others(a, s, [c.mul(2), c.div(2), s.phi.mul(s.bw), c.add(Q.new(1, 2))])
	var fac := "Take %d out of the bracket: %dx %s %s = %d(x %s %s)" % [s.bw, s.bw, "−" if s.right else "+", ph(s, s.phi), s.bw, "−" if s.right else "+", ph(s, c.abs_q())]
	out.methods = {"factor-b-first": method([fac, say(a)], a.values),
		"translation-vector": method([fac, "The shift is %s to the %s, so it is c = %s in x − c." % [ph(s, c.abs_q()), "right" if s.right else "left", ph(s, c)], say(a)], a.values)}
	return out


## c with its sign, typed: a Q of π on Paper 1, a number on Paper 2.
static func _signed_c(s: Dictionary, c: Q) -> Dictionary:
	if s.paper == 2:
		var ans := Answer.make("number", {"v": c}, {}, "c = ")
		ans.exact = true
		ans.show = "dec"
		return ans
	var ans := DifferentiationViews.form("c = " + Fmt.pi(c), ["c = ", {"slot": "c"}, "π"], {"c": c})
	return ans


static func _signed_like(_a: Dictionary, s: Dictionary, v: Q, ref: String = "") -> Array:
	if s.paper == 2:
		return [wrong({"v": v}, ref)]
	return [DifferentiationViews.alt("c = " + Fmt.pi(v), ref, {"c": v})]


static func _signed_others(a: Dictionary, s: Dictionary, vs: Array) -> Array:
	var out: Array = []
	for v in vs:
		for w in _signed_like(a, s, v):
			out.append(w.values)
	return out


## "3 sin(2(x − π/6)) + 1", as the image reads.
static func image_text(s: Dictionary, amp: int, fn: String, b: int, c: Q, lift: int) -> String:
	var inner := "x" if c.is_zero() else "x %s %s" % ["−" if c.sign() > 0 else "+", ph(s, c.abs_q())]
	var head := "%d %s(%s)" % [amp, fn, inner if b == 1 else "%d(%s)" % [b, inner]]
	if b != 1 and c.is_zero():
		head = "%d %s(%dx)" % [amp, fn, b]
	return head + ("" if lift == 0 else " %s %d" % ["+" if lift > 0 else "−", absi(lift)])


func u_image_equation(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f := "f(x) = %d %s(%dx) %s %d" % [s.amp, s.fn, s.bw, "+" if s.lift > 0 else "−", absi(s.lift)]
	var fn: String = s.fn
	var parts: Array
	var text: String
	var vals: Dictionary
	var wrongs_in: Array = []
	var line: String
	var steps: Array
	var tracked: Array
	var q_label := "g(x) = "
	var c: Q = s.mv
	if s.kind == "translate":
		text = image_text(s, s.amp, fn, s.bw, c, s.lift + s.up)
		parts = [q_label, {"slot": "a"}, " %s(" % fn, {"slot": "b"}, "(x − ", {"slot": "c"}] + (["π"] if s.paper == 1 else []) + [")) + ", {"slot": "d"}]
		vals = {"a": Q.new(s.amp), "b": Q.new(s.bw), "c": c, "d": Q.new(s.lift + s.up)}
		line = "The graph of f is translated by the vector (%s, %s) to give the graph of g." % [ph(s, c), N(s.up)]
		if rep == "words":
			line = "The graph of f is moved %s to the right and %s to give the graph of g." % [ph(s, c), "%d up" % s.up if s.up > 0 else "%d down" % -s.up]
		wrongs_in.append([image_text(s, s.amp, fn, s.bw, c.neg(), s.lift + s.up), {"a": Q.new(s.amp), "b": Q.new(s.bw), "c": c.neg(), "d": Q.new(s.lift + s.up)}, R_RIGHT])
		steps = ["A move right by %s replaces x with x − %s." % [ph(s, c), ph(s, c)], "A move of %s up adds %s to the whole function." % [N(s.up), P(s.up)]]
		tracked = ["Track a maximum of f: it moves %s right and %s up." % [ph(s, c), N(s.up)], "So x − %s goes in the bracket and the outside number becomes %s." % [ph(s, c), N(s.lift + s.up)]]
	else:
		text = image_text(s, s.amp, fn, s.bw * s.sf, Q.new(0), s.lift)
		parts = [q_label, {"slot": "a"}, " %s(" % fn, {"slot": "b"}, "x) + ", {"slot": "d"}]
		vals = {"a": Q.new(s.amp), "b": Q.new(s.bw * s.sf), "d": Q.new(s.lift)}
		line = "The graph of f is stretched horizontally with scale factor 1/%d to give the graph of g." % s.sf
		if rep == "words":
			line = "The graph of f is squeezed towards the y-axis to 1/%d of its width to give the graph of g." % s.sf
		var d: Q = Q.new(s.bw, s.sf)
		wrongs_in.append([image_text(s, s.amp, fn, 1, Q.new(0), s.lift).replace("(x)", "(%sx)" % ("(%s)" % Fmt.num(d) if not d.is_int() else Fmt.num(d))), {"a": Q.new(s.amp), "b": d, "d": Q.new(s.lift)}, R_STRETCH])
		steps = ["A horizontal stretch with scale factor 1/%d replaces x with %dx." % [s.sf, s.sf], "So %dx becomes %dx, and the outside numbers stay." % [s.bw, s.bw * s.sf]]
		tracked = ["Track a zero of the wave: its x-value divides by %d." % s.sf, "So the wave runs %d times as fast, and b becomes %d." % [s.sf, s.bw * s.sf]]
	var a := DifferentiationViews.form(q_label + text, parts, vals)
	var out := {"answer": a, "lines": [f, line], "asked": "Write down g(x)."}
	out.wrongs = wrongs_in.map(func(w): return DifferentiationViews.alt(q_label + w[0], w[2], w[1]))
	var gens: Array = []
	var bump := func(k: String, dv: Variant, shown: String) -> void:
		var nv := vals.duplicate()
		nv[k] = Q.of(vals[k]).add(dv)
		gens.append(DifferentiationViews.alt(q_label + shown, "", nv).values)
	if s.kind == "translate":
		bump.call("d", 1, image_text(s, s.amp, fn, s.bw, c, s.lift + s.up + 1))
		bump.call("d", -2 * s.up, image_text(s, s.amp, fn, s.bw, c, s.lift - s.up))
		bump.call("a", 1, image_text(s, s.amp + 1, fn, s.bw, c, s.lift + s.up))
		bump.call("b", 1, image_text(s, s.amp, fn, s.bw + 1, c, s.lift + s.up))
	else:
		bump.call("a", 1, image_text(s, s.amp + 1, fn, s.bw * s.sf, Q.new(0), s.lift))
		bump.call("d", 1, image_text(s, s.amp, fn, s.bw * s.sf, Q.new(0), s.lift + 1))
		bump.call("b", 1, image_text(s, s.amp, fn, s.bw * s.sf + 1, Q.new(0), s.lift))
	out.generic = gens
	out.methods = {"translation-vector": method(steps + [say(a)], a.values), "track-key-points": method(tracked + [say(a)], a.values)}
	return out


func u_describe_transformations(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Q = s.phi.div(s.bw)
	var signed_c: Q = c if s.right else c.neg()
	var eq := "y = " + lifted(s.amp, s.fn, raw_bracket(s), s.lift)
	var sentence := func(sf: String, vec: String) -> String:
		return "A vertical stretch with scale factor %d, a horizontal stretch with scale factor %s, then a translation by %s" % [s.amp, sf, vec]
	var vec := func(v: Q) -> String: return "(%s, %s)" % [ph(s, v), N(s.lift)]
	var cl := DerivativeMeaningViews.claim_answer(sentence.call("1/%d" % s.bw, vec.call(signed_c)), [
		[sentence.call("1/%d" % s.bw, vec.call(s.phi if s.right else s.phi.neg())), R_SHIFT_B],
		[sentence.call(str(s.bw), vec.call(signed_c)), R_STRETCH],
		[sentence.call("1/%d" % s.bw, vec.call(signed_c.neg())), R_RIGHT]])
	var a: Dictionary = cl.answer
	var out := {"answer": a, "wrongs": cl.wrongs, "lines": [eq], "asked": "Which transformations map y = %s x onto this graph?" % s.fn}
	if rep == "graph":
		var amp: float = s.amp
		var w: float = s.bw
		var ph_: float = s.phi.to_float() * (PI if s.paper == 1 else 1.0) * (-1.0 if s.right else 1.0)
		var lift: float = s.lift
		var fnn: String = s.fn
		var f := func(x: float) -> float: return amp * (sin(w * x + ph_) if fnn == "sin" else cos(w * x + ph_)) + lift
		var g := TrigKit.wave(f, Q.new(0), Q.new(2), mini(-2, s.lift - s.amp - 1), maxi(2, s.lift + s.amp + 1), Q.new(1, 2))
		g.curves.append(Plot.sample(sin if s.fn == "sin" else cos, 0.0, TAU))
		out.lines = [eq, "The graph shows it with y = %s x." % s.fn]
		out.graph = g
	var fac := "Take %d out of the bracket: %s = %d(x %s %s)" % [s.bw, raw_bracket(s), s.bw, "−" if s.right else "+", ph(s, c)]
	var right: String = "So " + a.values.text + "."
	out.methods = {"factor-b-first": method([fac, "So the stretches are %d up and 1/%d across, and the shift is %s across, %s up." % [s.amp, s.bw, ph(s, signed_c), N(s.lift)], right], a.values),
		"track-key-points": method(["Track the point at x = 0: the stretches leave it, and %s sends it to x = %s." % [raw_bracket(s), ph(s, signed_c)], "The height of the wave is multiplied by %d, and the whole wave moves %s up." % [s.amp, N(s.lift)], right], a.values)}
	return out


func u_pq_from_translation(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Q = s.phi.div(s.bw)
	var p: Q = c if s.right else c.neg()
	var q: int = s.up
	var head := "f(x) = %d %s(%dx)" % [s.amp, s.fn, s.bw]
	var gx := "g(x) = " + lifted(s.amp, s.fn, raw_bracket(s), q)
	var out := {"lines": [head, gx, "g(x) = f(x − p) + q"]}
	var a: Dictionary
	if s.paper == 1:
		a = DifferentiationViews.form("p = %s, q = %s" % [Fmt.pi(p), N(q)], ["p = ", {"slot": "p"}, "π, q = ", {"slot": "q"}], {"p": p, "q": Q.new(q)})
	else:
		a = named(["p", "q"], [p, Q.new(q)], false)
	out.answer = a
	out.asked = "Find p and q."
	if rep == "graph":
		var amp: float = s.amp
		var w: float = s.bw
		var ph_: float = s.phi.to_float() * (PI if s.paper == 1 else 1.0) * (-1.0 if s.right else 1.0)
		var up: float = q
		var fnn: String = s.fn
		var g := TrigKit.wave(func(x: float) -> float: return amp * (sin(w * x + ph_) if fnn == "sin" else cos(w * x + ph_)) + up, Q.new(0), Q.new(2), mini(-1, q - s.amp) - 1, maxi(s.amp, q + s.amp) + 1, Q.new(1, 2))
		g.curves.append(Plot.sample(func(x: float) -> float: return amp * (sin(w * x) if fnn == "sin" else cos(w * x)), 0.0, TAU))
		out.lines = [head, gx, "g(x) = f(x − p) + q. The graphs of f and g are shown."]
		out.graph = g
	var alt := func(pv: Q, qv: int, ref: String = "") -> Dictionary:
		if s.paper == 2:
			return wrong(named_vals([pv, Q.new(qv)]), ref)
		return DifferentiationViews.alt("p = %s, q = %s" % [Fmt.pi(pv), N(qv)], ref, {"p": pv, "q": Q.new(qv)})
	out.wrongs = [alt.call(s.phi if s.right else s.phi.neg(), q, R_SHIFT_B), alt.call(p.neg(), q, R_RIGHT)]
	out.generic = [alt.call(p, -q).values, alt.call(p.mul(2), q).values, alt.call(p.div(2), q).values, alt.call(p, q + 1).values]
	var fac := "Take %d out of the bracket: %s = %d(x %s %s)" % [s.bw, raw_bracket(s), s.bw, "−" if s.right else "+", ph(s, c)]
	out.methods = {"translation-vector": method([fac, "So x − p has p = %s, and the outside number gives q = %s." % [ph(s, p), N(q)], say(a)], a.values),
		"gdc-overlay": method([fac, "Graph f(x − p) + q with p = %s and q = %s: it lies on the graph of g." % [ph(s, p), N(q)], say(a)], a.values)}
	return out


# ── Models from a story ──────────────────────────────────────

func u_wheel_model(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var T: float = s.period.to_float()
	var b := TAU / T
	var a_v: Q = s.a.neg()
	var a := named(["a", "b", "d"], [a_v, b, s.d], true)
	var story := "A wheel of diameter %d m turns once every %s minutes. Its lowest seat passes %d m above the ground, and a seat starts at the lowest point at t = 0." % [s.dia, D(s.period), s.base]
	var eq := "h(t) = a cos(bt) + d gives the height of the seat in metres, t minutes later."
	var out := {"answer": a, "lines": [story, eq], "asked": "Find a, b and d, to 3 significant figures."}
	if rep == "graph":
		var f := func(t: float) -> float: return a_v.to_float() * cos(b * t) + s.d.to_float()
		var top: int = ceili(s.top.to_float()) + 2
		var g := Plot.spec([Plot.sample(f, 0.0, T * 1.25)], [[0.0, s.low.to_float(), "(0, %s)" % D(s.low)], [T / 2.0, s.top.to_float(), "(%s, %s)" % [D(s.period.div(2)), D(s.top)]]], 0, ceili(T * 1.25), 0, top)
		g.x_name = "t"
		g.y_name = "h"
		out.lines = [eq, "The graph shows the height of a seat for just over one turn of the wheel."]
		out.graph = g
	out.wrongs = [wrong(named_vals([a_v, T, s.d]), R_PERIOD_B), wrong(named_vals([a_v, TAU / (T / 2.0), s.d]), R_PERIOD_GAP)]
	out.generic = [named_vals([s.a, b, s.d]), named_vals([a_v, b, s.a]), named_vals([s.a.mul(2).neg(), b, s.d]), named_vals([a_v, b, s.d.add(s.base)])]
	var first := "The height runs from %s to %s, so a = −%s, negative as it starts at the bottom, and d = %s." % [D(s.low), D(s.top), D(s.a), D(s.d)]
	var second := "One turn is %s minutes, so b = 2π ÷ %s = %s" % [D(s.period), D(s.period), GdcKit.W(b)]
	out.methods = {"max-min-averages": method([first, second, say(a)], a.values),
		"substitute-evaluate": method([first, second, "Check t = 0: h = −%s + %s = %s, the lowest point." % [D(s.a), D(s.d), D(s.low)], say(a)], a.values)}
	return out


func u_c_from_crossing(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b := bf(s)
	var r: float = s.level.sub(s.d).div(s.a).to_float()
	var c: float = s.t1.to_float() - asin(r) / b
	var a := fnum("c = ", c)
	var cc := ctx(s)
	var eq := "%s(t) = %s sin(%s(t − c)) + %s" % [cc.sym, D(s.a), b_text(s), D(s.d)]
	var out := {"answer": a, "asked": "Find c, to 3 significant figures, taking the crossing nearest to c."}
	var head := "%s is modelled by %s, with t in %s." % [cc.thing, eq, cc.time]
	var when := "It reaches %s %s, while rising, at t = %s." % [D(s.level), cc.unit, D(s.t1)]
	out.lines = [head, when] if rep == "words" else [eq, "%s(%s) = %s, with %s rising at t = %s." % [cc.sym, D(s.t1), D(s.level), cc.sym, D(s.t1)]]
	out.wrongs = [wrong({"v": GdcKit.qf(s.t1.to_float() - rad_to_deg(asin(r)) / b)}, R_DEGREES)]
	out.generic = [{"v": GdcKit.qf(s.t1.to_float() + asin(r) / b)}, {"v": GdcKit.qf(asin(r) / b)}, {"v": GdcKit.qf(s.t1.to_float() - r / b)}, {"v": GdcKit.qf(c + s.period.to_float() / 4.0)}]
	var first := "sin(%s(%s − c)) = (%s − %s) ÷ %s = %s" % [b_text(s), D(s.t1), D(s.level), D(s.d), D(s.a), GdcKit.W(r)]
	out.methods = {"solve-analytically": method([first, "Rising, so take sin⁻¹: %s(%s − c) = %s" % [b_text(s), D(s.t1), GdcKit.W(asin(r))], "c = %s − %s = %s" % [D(s.t1), PW(asin(r) / b), GdcKit.W(c)], say(a)], a.values),
		"gdc-intersection": method(["Graph y = %s sin(%s x) + %s and y = %s: they cross, going up, at x = %s." % [D(s.a), b_text(s), D(s.d), D(s.level), GdcKit.W(asin(r) / b)], "That graph is the model moved back by c, so c = %s − %s = %s" % [D(s.t1), PW(asin(r) / b), GdcKit.W(c)], say(a)], a.values)}
	return out


func u_level_from_duration(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b := bf(s)
	var half: float = s.width.to_float() / 2.0
	var lv: float = s.a.to_float() * cos(b * half) + s.d.to_float()
	var cc := ctx(s)
	var a := fnum("k = ", lv)
	var eq := "%s(t) = %s cos(%s(t − %s)) + %s" % [cc.sym, D(s.a), b_text(s), D(s.xmax), D(s.d)]
	var out := {"answer": a, "lines": ["%s is modelled by %s, with t in %s." % [cc.thing, eq, cc.time], "In each cycle it is above the level k for %s %s." % [D(s.width), cc.time]], "asked": "Find k, to 3 significant figures."}
	if rep == "graph":
		var g := graph_of(s)
		out.lines = [eq, "The graph is shown. In each cycle the curve is above the level k for %s %s." % [D(s.width), cc.time]]
		out.graph = g
	out.wrongs = [wrong({"v": GdcKit.qf(s.a.to_float() * cos(deg_to_rad(b * half)) + s.d.to_float())}, R_DEGREES)]
	out.generic = [{"v": GdcKit.qf(s.a.to_float() * cos(b * s.width.to_float()) + s.d.to_float())}, {"v": GdcKit.qf(s.d.to_float() - s.a.to_float() * cos(b * half))}, {"v": GdcKit.qf(s.a.to_float() * sin(b * half) + s.d.to_float())}, {"v": GdcKit.qf(lv + 1.0)}]
	var hw := D(s.width.div(2))
	var f1 := "The wave is symmetric about its peak, so it is above k from %s before the peak to %s after it." % [hw, hw]
	var f2 := "k = %s cos(%s × %s) + %s = %s" % [D(s.a), b_text(s), hw, D(s.d), GdcKit.W(lv)]
	out.methods = {"symmetry-duration": method([f1, f2, say(a)], a.values),
		"solve-analytically": method(["Above k from t₁ to t₂: t₂ − t₁ = %s, and the peak is halfway between them." % D(s.width), "So t₂ is %s after the peak, and the height there is k." % hw, f2, say(a)], a.values)}
	return out
