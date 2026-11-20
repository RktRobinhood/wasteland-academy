class_name AiFitModelViews
extends ExtensionViews
## The views on the `ai-fit-model` situation (FAL-1001): one builder per unknown of
## fn-ai-fit-model (AI-SL2.6.find-parameters). The factor a of k·a^t (or the rate r of k·e^(rt))
## from a later value, the start k of k·a^t from one value, k and c of k·a^t + c from the start
## and one more value, a quadratic through three points (GDC), a quadratic from its y-intercept,
## axis of symmetry and a point, a cubic with its constant term known through three points (GDC),
## and a and c of a sin(bt) + c from two readings, in degrees.
##
## Every question is Paper 2, as every AI paper allows a GDC. A factor, rate or start value is to
## 3 s.f. with the rounding trap; coefficients drawn to end are exact. The check-point method shows
## a further point and checks the model there. `given` holds the situation as plain data.

const FP := "AI-SL2.6.find-parameters#"
const R_START := FP + "0"
const R_SWAP := FP + "1"
const R_X_NOT_X2 := FP + "2"
const R_NO_ROOT := "fn-ai-fit-model#3"
const R_ONCE := "fn-ai-fit-model#4"
const R_B_SIGN := "fn-ai-fit-model#5"
const R_ORDER := "fn-ai-fit-model#6"
const R_RADIANS := "fn-ai-fit-model#7"
const S := preload("res://engine/situations/ai_fit_model.gd")

const UNKNOWNS := ["exp-factor-from-point", "exp-start-from-point", "exp-two-constants", "quadratic-three-points",
	"quadratic-from-symmetry", "cubic-through-points", "sinusoid-two-points"]

const GROW := [
	{"what": "The number of rad-moths in a colony", "sym": "N", "time": "weeks", "start": "the colony is found"},
	{"what": "The number of settlers on a radio net", "sym": "P", "time": "months", "start": "the net opens"},
	{"what": "The area of a fungus mat, in m²,", "sym": "A", "time": "days", "start": "it is first measured"},
]
const DECAY := [
	{"what": "The mass of a salvaged isotope, in grams,", "sym": "M", "time": "days", "start": "it is dug up"},
	{"what": "The water left in a leaking tank, in litres,", "sym": "W", "time": "hours", "start": "the leak starts"},
	{"what": "The charge left in a scavenged battery, in mAh,", "sym": "C", "time": "hours", "start": "it is unplugged"},
]
const TWO := [
	{"what": "The temperature of an ingot, in °C,", "sym": "T", "time": "minutes", "start": "it leaves the forge"},
	{"what": "The temperature of a coolant tank, in °C,", "sym": "H", "time": "minutes", "start": "the reactor is shut down"},
	{"what": "The number of scrap-drones in a fleet", "sym": "D", "time": "months", "start": "the depot opens"},
]
const QUAD := [
	"The arch of a scrap-metal gate is modelled by y = ax² + bx + c, where y m is the height of the arch x m from the left post.",
	"The path of a signal flare is modelled by y = ax² + bx + c, where y m is its height when it is x m across the valley floor.",
	"A cable hangs between two towers. Its height above the river, y m, x m from the left tower, is modelled by y = ax² + bx + c.",
]
const CUBIC := [
	"The height of a hover-rail above the ground, y m, x km from the depot, is modelled by y = %s.",
	"The depth of sand in a dune trench, y cm, x m along it, is modelled by y = %s.",
	"The power output of a salvaged generator, y kW, x hours after it is started, is modelled by y = %s.",
]
const SIN := [
	{"line": "The depth of water at a salvage jetty, d m, t hours after midnight, is modelled by d(t) = a sin(30t) + c, where 30t is in degrees.", "sym": "d", "t": "t (hours)"},
	{"line": "The temperature in a greenhouse dome, T °C, t hours after 06:00, is modelled by T(t) = a sin(15t) + c, where 15t is in degrees.", "sym": "T", "t": "t (hours)"},
	{"line": "The water level in a reservoir, L m, t days after it is first measured, is modelled by L(t) = a sin(10t) + c, where 10t is in degrees.", "sym": "L", "t": "t (days)"},
]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## Every AI paper allows a GDC: every cell is Paper 2.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = S.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## A GDC's screen: 6 significant figures.
static func W(x: float) -> String:
	return Fmt.work(x, 6)


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func sf_ans(label: String, x: float) -> Dictionary:
	var ans := Answer.make("number", {"v": GdcKit.qf(x)}, {}, label)
	ans.show = "sf"
	return ans


## Named exact values: "a = −0.5, b = 4, c = 10".
static func named_ans(names: Array, vals: Array) -> Dictionary:
	var ans := Answer.make("named", named_vals(vals), {"names": names})
	ans.show = "dec"
	ans.exact = true
	return ans


static func named_vals(vals: Array) -> Dictionary:
	var out := {}
	for i in vals.size():
		out["v%d" % i] = vals[i]
	return out


static func val(x: float) -> Dictionary:
	return {"v": GdcKit.qf(x)}


static func pack(lines: Array, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary,
		graph: Variant = null, table: Variant = null) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {},
		"graph": graph, "table": table}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


static func pt(x: Variant, y: Variant) -> String:
	return "(%s, %s)" % [D(x), D(y)]


## A linear combination of letters: lin([4, 2, 1], ["a", "b", "c"]) is "4a + 2b + c".
static func lin(coeffs: Array, letters: Array) -> String:
	var out := ""
	for i in coeffs.size():
		var c := Q.of(coeffs[i])
		if c.is_zero():
			continue
		var mag := c.abs_q()
		var body: String = ("" if mag.eq(1) else D(mag)) + letters[i]
		if out == "":
			out = ("−" if c.sign() < 0 else "") + body
		else:
			out += (" − " if c.sign() < 0 else " + ") + body
	return out if out != "" else "0"


## A number times a value in brackets when negative: "3 × (−2)".
static func times(a: Variant, b: Variant) -> String:
	return "%s × %s" % [D(a), P(b) if Q.of(b).sign() < 0 else D(b)]


static func P(v: Variant) -> String:
	var q := Q.of(v)
	return "(%s)" % D(q) if q.sign() < 0 else D(q)


static func power(base: String, n: int) -> String:
	return "%s^%d" % [base, n]


## The window round some points and a curve f on [lo, hi]: whole units, the x-axis in view.
static func window(f: Callable, lo: float, hi: float, pts: Array) -> Array:
	var ytop := 0.0
	var ybot := 0.0
	for i in 41:
		var y: float = f.call(lo + (hi - lo) * i / 40.0)
		ytop = maxf(ytop, y)
		ybot = minf(ybot, y)
	for p in pts:
		ytop = maxf(ytop, p[1])
	var pad := maxf(1.0, (ytop - ybot) * 0.12)
	return [floori(lo), ceili(hi), floori(ybot - (pad if ybot < 0.0 else 0.0)), ceili(ytop + pad)]


## A polynomial (coefficients highest power first, as Q) as a float function.
static func fx_of(co: Array) -> Callable:
	var cf: Array = co.map(func(v): return v.to_float())
	return func(x: float) -> float:
		var y := 0.0
		for c in cf:
			y = y * x + c
		return y


static func points_graph(f: Callable, lo: float, hi: float, pts: Array, vlines: Array = [], x_name: String = "x", y_name: String = "y") -> Dictionary:
	var win := window(f, lo, hi, pts)
	var g := Plot.spec([GdcKit.curve(f, lo, hi)], pts.map(func(p): return [p[0], p[1], pt(p[2], p[3])]), win[0], win[1], win[2], win[3], [], vlines)
	g.x_name = x_name
	g.y_name = y_name
	return g


# ── The factor or rate of an exponential ─────────────────────

static func exp_ctx(s: Dictionary) -> Dictionary:
	return (GROW if s.grow else DECAY)[s.ctx]


static func exp_story(s: Dictionary, model: String) -> String:
	var c := exp_ctx(s)
	return "%s t %s after %s, is modelled by %s(t) = %s." % [lead(c.what), c.time, c.start, c.sym, model]


## The story's subject with the comma before "t": "The mass ..., in grams," is already followed by one.
static func lead(what: String) -> String:
	return what if what.ends_with(",") else what + ","


static func reading(s: Dictionary, t: int, v: Q) -> String:
	var c := exp_ctx(s)
	return "After %d %s, %s = %s." % [t, c.time, c.sym, D(v)]


func u_exp_factor_from_point(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var cont: bool = s.form == "cont"
	var letter := "r" if cont else "a"
	var vals := S.factor_slips(s)
	var ans := sf_ans(letter + " = ", vals[0])
	var wr: Array = rng.shuffled([wrong(val(vals[1]), R_NO_ROOT), wrong(val(vals[2]), R_SWAP)])
	var fill: Array = S.factor_fillers(s).map(func(x): return val(x))
	var c := exp_ctx(s)
	var check: bool = angle == "check-point"
	var K := D(s.k)
	var model := K + ("e^(rt)" if cont else "a^t")
	var lines: Array = [exp_story(s, model)]
	var table: Variant = null
	if rep == "table":
		lines.append("The table gives values of %s(t)." % c.sym)
		var ts: Array = [0, s.T] + ([s.T2] if check else [])
		ts.sort()
		var vs: Array = ts.map(func(t): return D(s.k) if t == 0 else (D(s.V) if t == s.T else D(s.V2)))
		table = {"rows": [["t (%s)" % c.time, ts.map(func(t): return str(t))], ["%s(t)" % c.sym, vs]]}
	else:
		lines.append(reading(s, s.T, s.V))
		if check:
			lines.append(reading(s, s.T2, s.V2))
	var asked := "Find the value of %s." % letter
	if check:
		asked = "Find the value of %s from the value at t = %d, and check it against the value at t = %d." % [letter, s.T, s.T2]
	var ratio: Q = s.V.div(s.k)
	var rt := D(ratio) if S.ends_within(ratio) else W(ratio.to_float())
	var key := W(vals[0])
	var steps := {}
	if cont:
		var lnr := log(ratio.to_float())
		steps["eliminate"] = ["At t = %d: %se^(%dr) = %s." % [s.T, K, s.T, D(s.V)],
			"Divide by %s: e^(%dr) = %s ÷ %s = %s, so %dr = ln %s = %s." % [K, s.T, D(s.V), K, rt, s.T, rt, W(lnr)],
			"r = %s ÷ %d = %s" % [W(lnr), s.T, key], say(ans)]
	else:
		steps["eliminate"] = ["At t = %d: %sa^%d = %s." % [s.T, K, s.T, D(s.V)],
			"Divide by %s: a^%d = %s ÷ %s = %s." % [K, s.T, D(s.V), K, rt],
			"a = %s^(1/%d) = %s" % [rt, s.T, key], say(ans)]
	if check:
		var v2: float = s.k.to_float() * pow(S.model_factor(s), s.T2)
		var first := ("From t = %d: %se^(%dr) = %s, so r = ln(%s ÷ %s) ÷ %d = %s." % [s.T, K, s.T, D(s.V), D(s.V), K, s.T, key]) if cont \
			else ("From t = %d: %sa^%d = %s, so a = (%s ÷ %s)^(1/%d) = %s." % [s.T, K, s.T, D(s.V), D(s.V), K, s.T, key])
		var model_at := ("%se^(%s × %d)" % [K, key, s.T2]) if cont else ("%s × %s^%d" % [K, key, s.T2])
		steps["check-point"] = [first,
			"Check at t = %d: %s(%d) = %s = %s, which rounds to %s, the value given." % [s.T2, c.sym, s.T2, model_at, Fmt.work(v2, 6), D(s.V2)],
			say(ans)]
	return pack(lines, asked, ans, wr, fill, steps, null, table)


# ── The start value of an exponential ────────────────────────

func u_exp_start_from_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var vals := S.start_slips(s)
	var ans := sf_ans("k = ", vals[0])
	var wr: Array = [wrong(val(vals[1]), R_ONCE)]
	var fill: Array = S.start_fillers(s).map(func(x): return val(x))
	var c := exp_ctx(s)
	var A := D(s.a)
	var model := "k(%s)^t" % A
	var lines: Array
	if rep == "equation":
		lines = ["%s(t) = %s, where t is in %s." % [c.sym, model, c.time], "%s(%d) = %s" % [c.sym, s.T, D(s.V)]]
	else:
		lines = [exp_story(s, model), reading(s, s.T, s.V)]
	var aT := pow(s.a.to_float(), s.T)
	var steps := {"initial-condition": [
		"At t = %d: k(%s)^%d = %s." % [s.T, A, s.T, D(s.V)],
		"(%s)^%d = %s, so k = %s ÷ %s = %s" % [A, s.T, W(aT), D(s.V), W(aT), W(vals[0])],
		"k is the start value: at t = 0, (%s)^0 = 1, so %s(0) = k." % [A, c.sym],
		say(ans)]}
	return pack(lines, "Find the value of k.", ans, wr, fill, steps)


# ── Both constants of k·a^t + c ──────────────────────────────

func u_exp_two_constants(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var opts := S.two_options(s)
	var ans := named_ans(["k", "c"], opts[0])
	var wr: Array = [wrong(named_vals(opts[1]), R_START)]
	var fill: Array = [named_vals(opts[2]), named_vals(opts[3])]
	var c: Dictionary = TWO[s.ctx]
	var A := D(s.a)
	var story := "%s t %s after %s, is modelled by %s(t) = k(%s)^t + c." % [lead(c.what), c.time, c.start, c.sym, A]
	var lines: Array = [story]
	var graph: Variant = null
	if rep == "graph":
		lines.append("The graph of the model passes through the two labelled points.")
		var f := func(t): return s.k.to_float() * pow(s.a.to_float(), t) + s.c.to_float()
		graph = points_graph(f, 0.0, s.T + 2.0, [[0.0, s.P0.to_float(), 0, s.P0], [float(s.T), s.V.to_float(), s.T, s.V]], [], "t", c.sym)
	else:
		lines.append("At t = 0, %s = %s, and after %d %s, %s = %s." % [c.sym, D(s.P0), s.T, c.time, c.sym, D(s.V)])
	var aT := S.qpow(s.a, s.T)
	var one := Q.new(1).sub(aT)
	var P0 := D(s.P0)
	var V := D(s.V)
	var K := D(s.k)
	var C := D(s.c)
	var steps := {
		"initial-condition": [
			"At t = 0, (%s)^0 = 1: k + c = %s, so c = %s − k." % [A, P0, P0],
			"At t = %d, (%s)^%d = %s: %s + c = %s." % [s.T, A, s.T, D(aT), lin([aT], ["k"]), V],
			"Put c = %s − k in: %s + %s − k = %s, so %s = %s and k = %s." % [P0, lin([aT], ["k"]), P0, V, lin([aT.sub(1)], ["k"]), D(s.V.sub(s.P0)), K],
			"c = %s − %s = %s" % [P0, K, C], say(ans)],
		"eliminate": [
			"k + c = %s (at t = 0) and %s + c = %s (at t = %d)." % [P0, lin([aT], ["k"]), V, s.T],
			"Take the second from the first: %s = %s − %s, so k = %s." % [lin([one], ["k"]), P0, V, K],
			"c = %s − %s = %s" % [P0, K, C], say(ans)],
	}
	return pack(lines, "Find the values of k and c.", ans, wr, fill, steps, graph)


# ── A quadratic through three points ─────────────────────────

static func quad_eq(x: Q, y: Q) -> String:
	return "%s = %s" % [lin([x.mul(x), x, Q.new(1)], ["a", "b", "c"]), D(y)]


static func quad_text(co: Array) -> String:
	return Fmt.terms(co, [2, 1, 0], "x", true)


func u_quadratic_three_points(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var opts := S.quad_three_options(s)
	var ans := named_ans(["a", "b", "c"], opts[0])
	var wr: Array = [wrong(named_vals(opts[1]), R_SWAP)]
	var fill: Array = [named_vals(opts[2]), named_vals(opts[3])]
	var check: bool = angle == "check-point"
	var xs: Array = s.xs
	var ys := S.ys_of(s)
	var y4 := S.horner(s.co, s.x4)
	var pts: Array = []
	for i in 3:
		pts.append(pt(xs[i], ys[i]))
	var lines: Array = [QUAD[s.ctx]]
	var graph: Variant = null
	var table: Variant = null
	var shown_x: Array = xs + ([s.x4] if check else [])
	var shown_y: Array = ys + ([y4] if check else [])
	match rep:
		"table":
			lines.append("The table gives %s points on it." % ("four" if check else "three"))
			table = {"rows": [["x", shown_x.map(func(x): return D(x))], ["y", shown_y.map(func(y): return D(y))]]}
		"graph":
			lines.append("The graph shows the model through %s labelled points." % ("four" if check else "three"))
			var f := fx_of(s.co)
			var lo: float = minf(0.0, shown_x.map(func(x): return x.to_float()).min())
			var hi: float = shown_x.map(func(x): return x.to_float()).max() + 1.0
			var marks: Array = []
			for i in shown_x.size():
				marks.append([shown_x[i].to_float(), shown_y[i].to_float(), shown_x[i], shown_y[i]])
			graph = points_graph(f, lo, hi, marks)
		_:
			var said := "It passes through the points %s, %s and %s." % pts
			if check:
				said = "It passes through the points %s, %s, %s and %s." % (pts + [pt(s.x4, y4)])
			lines.append(said)
	var asked := "Find the values of a, b and c."
	if check:
		asked = "Find the values of a, b and c from the points %s, %s and %s, then check the model at %s." % (pts + [pt(s.x4, y4)])
	var eqs: Array = []
	for i in 3:
		eqs.append(quad_eq(xs[i], ys[i]))
	var subst := "Each point gives one equation in a, b and c: %s, %s and %s." % eqs
	var solver := "Enter the three equations in the GDC's simultaneous-equation solver, with unknowns a, b and c: it gives %s." % Answer.text(ans)
	var model := "So %s: the model is y = %s." % [Answer.text(ans), quad_text(s.co)]
	var steps := {"simultaneous-gdc": [subst, solver, model]}
	if check:
		var x4: Q = s.x4
		var co: Array = s.co
		steps["check-point"] = [subst, solver,
			"Check at %s: %s + %s + %s = %s, as given." % [pt(x4, y4), times(co[0], x4.mul(x4)), times(co[1], x4), D(co[2]), D(y4)], model]
	return pack(lines, asked, ans, wr, fill, steps, graph, table)


# ── A quadratic from its symmetry ────────────────────────────

func u_quadratic_from_symmetry(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var opts := S.quad_sym_options(s)
	var ans := named_ans(["a", "b", "c"], opts[0])
	var wr: Array = rng.shuffled([wrong(named_vals(opts[1]), R_X_NOT_X2), wrong(named_vals(opts[2]), R_B_SIGN)])
	var fill: Array = [named_vals(opts[3])]
	var co: Array = s.co
	var a: Q = co[0]
	var b: Q = co[1]
	var c: Q = co[2]
	var p := Q.new(s.p)
	var q := S.horner(co, p)
	var h: int = s.h
	var lines: Array = [QUAD[s.ctx]]
	var graph: Variant = null
	if rep == "graph":
		lines.append("The graph shows the curve with its axis of symmetry, x = %d, and two labelled points." % h)
		var f := fx_of(co)
		var hi := maxf(float(s.p), 2.0 * h) + 1.0
		graph = points_graph(f, 0.0, hi, [[0.0, c.to_float(), 0, c], [float(s.p), q.to_float(), p, q]], [[h, "x = %d" % h]])
	else:
		lines.append("The curve meets the y-axis at %s, its axis of symmetry is x = %d, and it passes through %s." % [pt(0, c), h, pt(p, q)])
	var P2 := p.mul(p)
	var k2 := P2.sub(p.mul(2 * h))
	var bk := -2 * h
	var steps := {
		"initial-condition": [
			"At x = 0, y = c: the curve meets the y-axis at %s, so c = %s." % [pt(0, c), D(c)],
			"The axis of symmetry is x = −b/(2a) = %d, so b = %s." % [h, lin([bk], ["a"])],
			"At %s: %s + %s = %s. With b = %s: %s = %s, so a = %s." % [pt(p, q), lin([P2, p], ["a", "b"]), D(c), D(q), lin([bk], ["a"]), lin([k2], ["a"]), D(q.sub(c)), D(a)],
			"b = %s = %s" % [times(bk, a), D(b)], say(ans)],
		"eliminate": [
			"Three equations: c = %s (the y-intercept), %s = 0 (from −b/(2a) = %d) and %s + c = %s (the point %s)." % [D(c), lin([2 * h, 1], ["a", "b"]), h, lin([P2, p], ["a", "b"]), D(q), pt(p, q)],
			"Put c = %s in the third: %s = %s. Take %s times the second away: %s = %s, so a = %s." % [D(c), lin([P2, p], ["a", "b"]), D(q.sub(c)), D(p), lin([k2], ["a"]), D(q.sub(c)), D(a)],
			"Then b = %s = %s" % [times(bk, a), D(b)], say(ans)],
	}
	return pack(lines, "Find the values of a, b and c.", ans, wr, fill, steps, graph)


# ── A cubic through three points ─────────────────────────────

func u_cubic_through_points(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var opts := S.cubic_options(s)
	var ans := named_ans(["a", "b", "c"], opts[0])
	var wr: Array = rng.shuffled([wrong(named_vals(opts[1]), R_ORDER), wrong(named_vals(opts[2]), R_ORDER)])
	var fill: Array = [named_vals(opts[3])]
	var co: Array = s.co
	var d: Q = co[3]
	var xs: Array = s.xs
	var ys: Array = xs.map(func(x): return S.horner(co, x))
	var form := "ax³ + bx² + cx + %s" % D(d)
	var lines: Array = [CUBIC[s.ctx] % form]
	var table: Variant = null
	var pts: Array = []
	for i in 3:
		pts.append(pt(xs[i], ys[i]))
	if rep == "table":
		lines.append("The table gives three values of y.")
		table = {"rows": [["x", xs.map(func(x): return D(x))], ["y", ys.map(func(y): return D(y))]]}
	else:
		lines.append("It passes through the points %s, %s and %s." % pts)
	var eqs: Array = []
	for i in 3:
		var x: Q = xs[i]
		eqs.append("%s = %s" % [lin([x.mul(x).mul(x), x.mul(x), x], ["a", "b", "c"]), D(ys[i].sub(d))])
	var full := "y = " + Fmt.terms(co, [3, 2, 1, 0], "x", true)
	var steps := {"simultaneous-gdc": [
		"The constant term is d = %s. Each point gives one equation: put x and y in and take %s from both sides." % [D(d), D(d)],
		"%s, %s and %s." % eqs,
		"Enter them in the GDC's simultaneous-equation solver with the unknowns in the order a, b, c (the powers x³, x², x): it gives %s." % Answer.text(ans),
		"So %s: the model is %s." % [Answer.text(ans), full]]}
	return pack(lines, "Find the values of a, b and c.", ans, wr, fill, steps, null, table)


# ── a and c of a sinusoid ────────────────────────────────────

func u_sinusoid_two_points(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var opts := S.sin_options(s)
	var ans := named_ans(["a", "c"], opts[0])
	var wr: Array = rng.shuffled([wrong(named_vals(opts[1]), R_RADIANS), wrong(named_vals(opts[2]), R_SWAP)])
	var fill: Array = [named_vals(opts[3])]
	var c: Dictionary = SIN[s.ctx]
	var ys := S.sin_ys(s)
	var ts: Array = s.ts
	var lines: Array = [c.line]
	var table: Variant = null
	if rep == "table":
		lines.append("The table gives two readings.")
		table = {"rows": [[c.t, ts.map(func(t): return str(t))], ["%s(t)" % c.sym, ys.map(func(y): return D(y))]]}
	else:
		lines.append("At t = %d, %s = %s, and at t = %d, %s = %s." % [ts[0], c.sym, D(ys[0]), ts[1], c.sym, D(ys[1])])
	var s1: Q = S.nice_sin(s.b, ts[0])
	var s2: Q = S.nice_sin(s.b, ts[1])
	var sines := "In degree mode, sin(%d × %d) = sin(%d°) = %s and sin(%d × %d) = sin(%d°) = %s." % [s.b, ts[0], s.b * ts[0], D(s1), s.b, ts[1], s.b * ts[1], D(s2)]
	var e1 := "%s = %s" % [lin([s1, 1], ["a", "c"]), D(ys[0])]
	var e2 := "%s = %s" % [lin([s2, 1], ["a", "c"]), D(ys[1])]
	var steps := {
		"simultaneous-gdc": [sines, "So %s and %s." % [e1, e2],
			"Enter the two equations in the GDC's simultaneous-equation solver, with unknowns a and c: it gives %s." % Answer.text(ans), say(ans)],
		"eliminate": [sines,
			"%s and %s. Take the second from the first: %s." % [e1, e2, ("a = %s" % D(s.amp)) if s1.sub(s2).eq(1)
				else "%s = %s, so a = %s" % [lin([s1.sub(s2)], ["a"]), D(ys[0].sub(ys[1])), D(s.amp)]],
			"c = %s − %s × %s = %s" % [D(ys[0]), P(s1), D(s.amp), D(s.mid)], say(ans)],
	}
	return pack(lines, "Find the values of a and c.", ans, wr, fill, steps, null, table)
