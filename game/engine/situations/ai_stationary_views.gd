class_name AiStationaryViews
extends ExtensionViews
## The views on the `ai-stationary` situation (FAL-1000): one builder per unknown of
## t5-ai-stationary-points (AI-SL5.6). Where the gradient is zero (from f, or from f′ given),
## a coefficient k from a stationary point, the coordinates of a local maximum or minimum (from
## the equation, or with f drawn on a GDC window that one end of the curve leaves), the greatest or
## least value of a story's model, the nature of a stationary point with its reason (a claim),
## the greatest or least value on a domain and why a local maximum is not the greatest; and three
## views of the graph of f′, built by DerivativeGraphViews and re-tagged with this type's slips.
##
## Every question is Paper 2, as every AI paper allows a GDC: GDC values are 3 s.f., with the
## rounding trap where the answer is one number, and whole-number answers are exact.
## Representations: "equation" (f or f′ written out), "words" (a story), "graph" (f on a GDC
## window or a domain, or f′ on a grid) and "table" (f and f′ either side of a point).

const SZ := "AI-SL5.6.solve-gradient-zero#"
const LE := "AI-SL5.6.locate-local-extrema#"
const CS := "AI-SL5.6.classify-by-gradient-sign#"
const GD := "AI-SL5.6.greatest-least-on-domain#"
const RG := "AI-SL5.6.read-from-gradient-graph#"
const TT := "t5-ai-stationary-points#"
const R_F_ROOTS := SZ + "0"
const R_CONSTANT := SZ + "1"
const R_POSITIVE := SZ + "2"
const R_Y_ZERO := LE + "0"
const R_X_ONLY := LE + "1"
const R_WINDOW := LE + "2"
const R_REVERSED := CS + "0"
const R_F_SIGN := CS + "1"
const R_BEYOND := CS + "2"
const R_LOCAL := GD + "0"
const R_OUTSIDE := GD + "1"
const R_NO_ENDS := GD + "2"
const R_FP_TURN := RG + "0"
const R_WAY_ROUND := RG + "1"
const R_TOUCH := RG + "2"
const R_FP_RISES := TT + "15"
const R_INPUT := TT + "16"
const R_END := TT + "17"

const UNKNOWNS := ["gradient-zero-x", "gradient-zero-given-derivative", "coefficient-from-stationary",
	"local-extremum-point", "extremum-value-in-context", "classify-stationary", "greatest-on-domain",
	"local-not-greatest", "extremum-from-gradient-graph", "increasing-from-gradient-graph", "pick-f-from-gradient-graph"]

## A story: [its function's letter, the input's letter, the output's unit, the sentence before the
## formula, what the output is, the input's unit].
const STORY := {
	"still": ["T", "t", "°C", "A still in the camp is lit at dawn. Its temperature, T °C, t hours after it is lit, is modelled by", "temperature", "hours"],
	"track": ["h", "x", "m", "A track leaves the camp and crosses a dry valley. Its height above the valley floor, h metres, x km from the camp, is modelled by", "height", "km"],
	"turbine": ["P", "v", "kW", "A salvaged wind turbine gives P kW of power in a wind of v m/s, where", "power", "m/s"],
	"reservoir": ["D", "t", "m", "The depth of water in a reservoir, D metres, t weeks after the rains begin, is modelled by", "depth", "weeks"],
	"flare": ["h", "t", "m", "A flare is fired upwards from a watchtower. Its height above the ground, h metres, t seconds after it is fired, is modelled by", "height", "seconds"],
	"drone": ["F", "v", "ml", "A scout drone flying at v km/h uses F millilitres of fuel per km, where", "fuel used per km", "km/h"],
}

var _dg := DerivativeGraphViews.new()


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
	out.given = AiStationarySituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

const S := preload("res://engine/situations/ai_stationary.gd")


static func D(v: Variant) -> String:
	return Fmt.dec(v)


## A GDC screen value: 6 s.f.
static func W(x: float) -> String:
	return Fmt.work(x, 6)


## A value as an option shows it: exact, or 3 s.f.
static func V(x: float, exact: bool) -> String:
	return Fmt.dec(Q.new(roundi(x))) if exact else Fmt.sf(x)


## The value an answer or option holds: the whole number, or the GDC value (an answer) or its
## 3 s.f. (an option).
static func qv(x: float, exact: bool, option: bool = false) -> Q:
	if exact:
		return Q.new(roundi(x))
	return S.q3(x) if option else GdcKit.qf(x)


static func is_whole(x: float) -> bool:
	return absf(x - roundf(x)) < 1e-9


static func letter(s: Dictionary) -> String:
	return STORY[s.model][1] if s.fam == "model" else "x"


static func fsym(s: Dictionary) -> String:
	return STORY[s.model][0] if s.fam == "model" else "f"


## "f(x)", "T(t)".
static func fname(s: Dictionary) -> String:
	return "%s(%s)" % [fsym(s), letter(s)]


## "f′(x)", "dT/dt".
static func dname(s: Dictionary) -> String:
	return "%s′(%s)" % [fsym(s), letter(s)] if s.fam != "model" else "d%s/d%s" % [fsym(s), letter(s)]


## A polynomial's coefficients, highest power first, written with decimals.
static func poly(co: Array, v: String) -> String:
	var n := co.size()
	var powers: Array = []
	for i in n:
		powers.append(n - 1 - i)
	return Fmt.terms(co, powers, v, true)


## The function's right-hand side: "2x³ − 9x² + 12x − 4", "2x + 18/x − 5".
static func f_rhs(s: Dictionary) -> String:
	if s.fam == "recip":
		return "%sx + %d/x%s" % [Fmt.lead(s.ra), s.rb, Fmt.plus(s.rc)]
	return poly(s.co, letter(s))


static func d_rhs(s: Dictionary) -> String:
	if s.fam == "recip":
		return "%d − %d/x²" % [s.ra, s.rb]
	return poly(S.dco(s.co), letter(s))


static func f_line(s: Dictionary) -> String:
	if s.fam == "model":
		return "%s %s = %s, for %s ≤ %s ≤ %s." % [STORY[s.model][3], fname(s), f_rhs(s), Fmt.num(s.lo), letter(s), Fmt.num(s.hi)]
	if s.fam == "recip":
		return "f(x) = %s, for x > 0." % f_rhs(s)
	if s.has("lo") and s.ask in ["greatest-on-domain", "local-not-greatest"]:
		return "f(x) = %s, for %s ≤ x ≤ %s." % [f_rhs(s), Fmt.num(s.lo), Fmt.num(s.hi)]
	return "f(x) = %s" % f_rhs(s)


static func fval(s: Dictionary, x: float) -> float:
	return S.rv(s, x) if s.fam == "recip" else S.fv(s.co, x)


## "f(2)", "T(3.38)": the function at x, as a step names it.
static func at(s: Dictionary, x: float, exact: bool) -> String:
	return "%s(%s)" % [fsym(s), V(x, exact) if not exact else Fmt.num(roundi(x))]


## Each value in a list, joined: "1 and 3", "−1.29 and 2.12".
static func list_and(xs: Array, f: Callable) -> String:
	return " and ".join(xs.map(func(x): return f.call(x)))


## An xs answer (several values, any order): exact when every value is whole.
static func xs_ans(xs: Array, v: String) -> Dictionary:
	var exact: bool = xs.all(func(x): return is_whole(x))
	var ans := Answer.make("xs", Answer.xs_of(xs.map(func(x): return qv(x, exact))), {"var": v})
	if exact:
		ans.show = "dec"
		ans.exact = true
	else:
		ans.show = "sf"
	return ans


## A wrong xs option: its values as the options show them.
static func xs_wrong(xs: Array, exact: bool, ref: String) -> Dictionary:
	return wrong(Answer.xs_of(xs.map(func(x): return qv(x, false, true) if not (exact and is_whole(x)) else Q.new(roundi(x)))), ref)


## A one-number answer: exact when whole, else 3 s.f.
static func num_ans(label: String, x: float, unit: String = "", exact: bool = false) -> Dictionary:
	var ex := exact or is_whole(x)
	var ans := Answer.make("number", {"v": qv(x, ex)}, {}, label, unit)
	ans.show = "dec" if ex else "sf"
	ans.exact = ex
	return ans


static func num_wrong(x: float, exact: bool, ref: String) -> Dictionary:
	return wrong({"v": qv(x, exact and is_whole(x), true)}, ref)


static func num_fill(x: float, exact: bool) -> Dictionary:
	return {"v": qv(x, exact and is_whole(x), true)}


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func pack(lines: Array, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {}, "table": null}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


## How f′ = 0 is solved by hand: factorised, ± a square root, or by the quadratic formula.
static func solve_line(s: Dictionary, xs: Array, exact: bool) -> String:
	var v := letter(s)
	if s.fam == "recip":
		var r := float(s.rb) / float(s.ra)
		return "%d − %d/x² = 0 gives x² = %d ÷ %d = %s, and x = %s since x > 0." % [s.ra, s.rb, s.rb, s.ra, W(r), V(xs[0], exact)]
	var dc: Array = S.dco(s.co)
	if dc.size() == 2:
		return "%s = 0 gives %s = %s." % [poly(dc, v), v, V(xs[0], exact)]
	var A: Q = dc[0]
	var B: Q = dc[1]
	var C: Q = dc[2]
	if B.is_zero():
		var r2 := C.neg().div(A)
		return "%s = 0 gives %s² = %s, so %s = ±%s." % [poly(dc, v), v, D(r2) if r2.mul(1000).is_int() else W(r2.to_float()), v, V(xs[1], exact) if exact else W(xs[1])]
	if exact:
		return "%s = %s = 0, so %s = %s or %s = %s." % [poly(dc, v), factored(s, xs), v, Fmt.num(roundi(xs[0])), v, Fmt.num(roundi(xs[1]))]
	var disc := B.mul(B).sub(A.mul(C).mul(4))
	var two_a := D(A.mul(2)) if A.sign() > 0 else "(" + D(A.mul(2)) + ")"
	return "By the quadratic formula, %s = (%s ± √%s) ÷ %s = %s or %s." % [v, D(B.neg()), D(disc), two_a, W(xs[0]), W(xs[1])]


## "(x − 1)(x − 3)" written cleanly from whole zeros.
static func factored(s: Dictionary, xs: Array) -> String:
	var dc: Array = S.dco(s.co)
	var A: Q = dc[0]
	return "%s%s%s" % [Fmt.lead(A), Fmt.factor(roundi(xs[0])), Fmt.factor(roundi(xs[1]))]


# ── Where the gradient is zero ───────────────────────────────

func u_gradient_zero_x(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := letter(s)
	var xs: Array = S.answer_xs(s)
	var ans := xs_ans(xs, v)
	var exact: bool = ans.exact if ans.has("exact") else false
	var slips := S.zero_slips(s)
	var wr: Array = []
	if slips.has("roots"):
		wr.append(xs_wrong(slips.roots, exact, R_F_ROOTS))
	if slips.has("kept"):
		wr.append(xs_wrong(slips.kept, exact, R_CONSTANT))
	if slips.has("pos"):
		wr.append(xs_wrong(slips.pos, exact, R_POSITIVE))
	var fill: Array = []
	if xs.size() == 2:
		fill.append(xs_wrong([-xs[0], -xs[1]], exact, "").values)
		fill.append(xs_wrong([xs[0]], exact, "").values)
	else:
		fill.append(xs_wrong([-xs[0], xs[0]], exact, "").values)
		fill.append(xs_wrong([xs[0] * 2.0], exact, "").values)
	fill.append(xs_wrong(xs.map(func(x): return x + 1.0), exact, "").values)
	var lines: Array = [f_line(s)]
	var asked: String
	if s.fam == "model":
		asked = "Find the %s of %s at which the rate of change of %s is zero." % ["values" if xs.size() > 1 else "value", v, fsym(s)]
	else:
		asked = "Find the %s of x where the gradient of the graph of f is zero." % ("values" if xs.size() > 1 else "value")
	var dl := "%s = %s" % [dname(s), d_rhs(s)]
	var shown_xs := list_and(xs, func(x): return V(x, exact) if exact else W(x))
	var steps := {
		"differentiate-and-solve": ["Differentiate term by term: %s." % dl, solve_line(s, xs, exact), final_step(ans)],
		"gdc-equation-solver": [
			"Differentiate: %s." % dl,
			("Enter %s = 0 in the equation solver, with a positive first guess, as x > 0." % d_rhs(s)) if s.fam == "recip"
				else ("Enter %s = 0 in the equation solver." % d_rhs(s)) if S.dco(s.co).size() == 2
				else "Enter the coefficients %s of %s into the polynomial solver (degree %d)." % [", ".join(S.dco(s.co).map(func(c): return D(c))), dname(s), S.dco(s.co).size() - 1],
			"The solver shows %s = %s." % [v, shown_xs],
			final_step(ans)],
		"zeros-of-derivative-graph": [
			"Graph y = %s on the GDC (typed in, or as the derivative of %s)." % [d_rhs(s).replace(v, "x") if v != "x" else d_rhs(s), fname(s)],
			"Its zero tool gives where it crosses the x-axis%s: %s = %s." % [" for x > 0" if s.fam == "recip" else "", v, shown_xs],
			final_step(ans)],
	}
	return pack(lines, asked, ans, wr, fill, steps)


## f′ given, in words or as an equation: the x (or t) of the local maximum or minimum.
func u_gradient_zero_given_derivative(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := letter(s)
	var st: Array = S.stat(s.co)
	var want: String = s.want
	var x := S.extremum_x(s.co, want)
	var o: float = st[0] if x == st[1] else st[1]
	var exact := is_whole(st[0]) and is_whole(st[1])
	var ans := num_ans("%s = " % v, x, "", exact)
	var wr: Array = []
	if s.fam == "cubic" and s.mode == "sym":
		wr.append(num_wrong(o, exact, R_POSITIVE))
	else:
		wr.append(num_wrong(o, exact, R_REVERSED))
	var dc: Array = S.dco(s.co)
	var A: float = dc[0].to_float()
	var B: float = dc[1].to_float()
	var vertex := -B / (2.0 * A)
	var fill: Array = []
	if absf(vertex - x) > 0.01 and absf(vertex - o) > 0.01:
		fill.append(num_fill(vertex, exact))
	fill.append(num_fill(-x, exact))
	fill.append(num_fill(x + 1.0, exact))
	var lines: Array
	var asked: String
	if s.fam == "model":
		lines = ["%s %s = %s." % [_rate_story(s), dname(s), d_rhs(s)]]
		asked = "Find the value of %s at which %s has a local %s." % [v, fsym(s), want]
	else:
		lines = ["f′(x) = %s" % d_rhs(s)]
		asked = "Find the x-coordinate of the local %s of f." % want
	var l_sign := "positive" if want == "maximum" else "negative"
	var r_sign := "negative" if want == "maximum" else "positive"
	var both := list_and(st, func(t): return V(t, exact) if exact else W(t))
	var change := "%s changes from %s to %s at %s = %s, so that is the local %s; at %s = %s it changes the other way." % [dname(s), l_sign, r_sign, v, V(x, exact) if exact else W(x), want, v, V(o, exact) if exact else W(o)]
	var steps := {
		"gdc-equation-solver": ["Enter the coefficients %s of %s into the polynomial solver (degree 2)." % [", ".join(dc.map(func(c): return D(c))), dname(s)],
			"It shows %s = %s." % [v, both], change, final_step(ans)],
		"zeros-of-derivative-graph": ["Graph y = %s on the GDC and find its zeros: %s = %s." % [d_rhs(s).replace(v, "x") if v != "x" else d_rhs(s), v, both],
			"The graph crosses the axis from %s to %s at %s = %s, so %s changes from %s to %s there: the local %s of %s." % ["above" if want == "maximum" else "below", "below" if want == "maximum" else "above", v, V(x, exact) if exact else W(x), dname(s), l_sign, r_sign, want, fsym(s)],
			final_step(ans)],
	}
	return pack(lines, asked, ans, wr, fill, steps)


## The story's first sentence, with the formula left out.
static func _rate_story(s: Dictionary) -> String:
	var v := letter(s)
	match s.model:
		"still":
			return "A still in the camp is lit at dawn. Its temperature is T °C, t hours after it is lit, for %d ≤ t ≤ %d. The rate of change of T is" % [s.lo, s.hi]
		"track":
			return "A track leaves the camp and crosses a dry valley. Its height above the valley floor is h metres, x km from the camp, for %d ≤ x ≤ %d. The rate of change of h is" % [s.lo, s.hi]
		"turbine":
			return "A salvaged wind turbine gives P kW of power in a wind of v m/s, for %d ≤ v ≤ %d. The rate of change of P is" % [s.lo, s.hi]
	return "The depth of water in a reservoir is D metres, t weeks after the rains begin, for %d ≤ %s ≤ %d. The rate of change of D is" % [s.lo, v, s.hi]


# ── A coefficient from a stationary point ────────────────────

func u_coefficient_from_stationary(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var co: Array = s.co
	var k: Q = s.k
	var x: int = s.xk
	var X := Fmt.num(x)
	var a: Q = co[0]
	# f with k in place of its coefficient, and f′.
	var f_text: String
	var d_text: String
	var coef_k: int
	var const_k: Q
	if s.kat == 2:
		f_text = Fmt.terms([a], [3], "x", true) + " + kx²" + Fmt.terms([co[2], co[3]], [1, 0], "x", true).insert(0, " + ").replace(" + −", " − ")
		d_text = Fmt.terms([a.mul(3)], [2], "x", true) + " + 2kx" + _joined(co[2], "")
		coef_k = 2 * x
		const_k = a.mul(3 * x * x).add(co[2])
	else:
		f_text = Fmt.terms([a, co[1]], [3, 2], "x", true) + " + kx" + _joined(co[3], "")
		d_text = Fmt.terms([a.mul(3), Q.of(co[1]).mul(2)], [2, 1], "x", true) + " + k"
		coef_k = 1
		const_k = a.mul(3 * x * x).add(Q.of(co[1]).mul(2 * x))
	f_text = f_text.replace(" + −", " − ")
	var ans := Answer.make("number", {"v": k}, {}, "k = ")
	ans.show = "dec"
	ans.exact = true
	var slip := S.root_slip_k(s)
	var wr: Array = [num_wrong(slip, false, R_F_ROOTS)]
	var fill: Array = [{"v": k.neg()}, {"v": k.add(1)}, {"v": k.mul(2)}]
	var eq := Fmt.terms([Q.new(coef_k), const_k], [1, 0], "k", true) + " = 0"
	var sub := d_text.replace("x", "(%s)" % X)
	var lines: Array = ["f(x) = %s, where k is a constant." % f_text, "The graph of f has a stationary point where x = %s." % X]
	return pack(lines, "Find the value of k.", ans, wr, fill, {
		"differentiate-and-solve": ["f′(x) = %s" % d_text,
			"At the stationary point f′(%s) = %s = 0, which gives %s." % [X, sub, eq],
			("k = %s." % D(k)) if coef_k == 1 else "%s = %s, so k = %s." % [Fmt.terms([Q.new(coef_k)], [1], "k", true), D(const_k.neg()), D(k)]],
		"gdc-equation-solver": ["f′(x) = %s, and f′(%s) = 0 at the stationary point." % [d_text, X],
			"Enter %s = 0 in the equation solver and solve for k." % sub,
			"The solver shows k = %s." % D(k)],
	})


## " + 3", " − 2.5", "" for 0: a number joined on, as a decimal.
static func _joined(v: Variant, body: String) -> String:
	var q := Q.of(v)
	if q.is_zero():
		return ""
	return (" − " if q.sign() < 0 else " + ") + D(q.abs_q()) + body


# ── A local maximum or minimum point ─────────────────────────

static func point_ans(x: float, y: float) -> Dictionary:
	var exact := is_whole(x) and is_whole(y)
	var ans := Answer.make("point", {"x": qv(x, exact), "y": qv(y, exact)})
	ans.show = "dec" if exact else "sf"
	ans.exact = exact
	return ans


static func point_wrong(x: float, y: float, exact: bool, ref: String, alone: bool = false) -> Dictionary:
	var v := {"x": qv(x, exact and is_whole(x), true), "y": qv(y, exact and is_whole(y), true)}
	if alone:
		v.alone = true
	return wrong(v, ref)


func u_local_extremum_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var want: String = s.want
	var x: float
	var st: Array
	if s.fam == "recip":
		x = S.rmin(s)
		st = [x]
	else:
		st = S.stat(s.co)
		x = S.extremum_x(s.co, want)
	var y := fval(s, x)
	var ans := point_ans(x, y)
	var exact: bool = ans.exact
	var wr: Array = [point_wrong(x, 0.0, exact, R_Y_ZERO), point_wrong(x, y, exact, R_X_ONLY, true)]
	var lines: Array = [f_line(s)]
	var g: Variant = null
	var edge: Array = []
	if rep == "graph":
		var win: Array = s.win
		var a_pos: bool = Q.of(s.co[0]).sign() > 0
		var ex: float = float(win[1]) if a_pos == (want == "maximum") else float(win[0])
		edge = [ex, fval(s, ex)]
		wr.append(point_wrong(ex, edge[1], exact, R_WINDOW))
		var fn := func(t: float) -> float: return S.fv(s.co, t)
		g = Plot.spec([GdcKit.curve(fn, float(win[0]), float(win[1]))], [], win[0], win[1], win[2], win[3])
		lines.append("The GDC shows the graph of y = f(x) in the window %s ≤ x ≤ %s, %s ≤ y ≤ %s." % [Fmt.num(win[0]), Fmt.num(win[1]), Fmt.num(win[2]), Fmt.num(win[3])])
	var fill: Array = [point_wrong(x, -y, exact, "").values, point_wrong(y, x, exact, "").values]
	if st.size() == 2:
		var o: float = st[0] if x == st[1] else st[1]
		fill.push_front(point_wrong(o, fval(s, o), exact, "").values)
	var X := V(x, true) if exact else W(x)
	var Y := V(y, true) if exact else W(y)
	var dl := "f′(x) = %s" % d_rhs(s)
	var find: String
	if s.fam == "recip":
		find = solve_line(s, [x], exact)
	elif exact:
		find = "f′(x) = %s = 0 at x = %s and x = %s; f′ changes from %s to %s at x = %s." % [factored(s, st), Fmt.num(roundi(st[0])), Fmt.num(roundi(st[1])),
			"positive" if want == "maximum" else "negative", "negative" if want == "maximum" else "positive", X]
	else:
		find = "The GDC solver gives f′(x) = 0 at x = %s and x = %s; f′ changes from %s to %s at x = %s." % [W(st[0]), W(st[1]),
			"positive" if want == "maximum" else "negative", "negative" if want == "maximum" else "positive", X]
	var window := "a window that shows the turning point"
	if rep == "graph":
		window = "the window shown"
	var steps := {
		"solve-then-substitute": [dl + ".", find, "Substitute into f, not f′: f(%s) = %s." % [X, Y], final_step(ans)],
		"gdc-max-min": ["Graph y = f(x) on the GDC in %s, and use the %s tool near x = %s." % [window, "maximum" if want == "maximum" else "minimum", V(x, exact) if exact else Fmt.sf(x)],
			"It shows x = %s, y = %s.%s" % [X, Y, "" if edge.is_empty() else " The curve leaves the window at x = %s, but that is the edge of the screen, not a turning point." % Fmt.num(roundi(edge[0]))],
			final_step(ans)],
	}
	var asked := "Find the coordinates of the local %s point of the graph of f." % want
	var out := pack(lines, asked, ans, wr, fill, steps)
	out.graph = g
	return out


# ── The greatest or least value of a model ───────────────────

## "T = ", " °C": the label and unit of a model's value.
static func value_label(s: Dictionary) -> Array:
	return ["%s = " % fsym(s), " " + STORY[s.model][2]]


func u_extremum_value_in_context(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := letter(s)
	var big: bool = s.want == "greatest"
	var kind := "maximum" if big else "minimum"
	var x := S.extremum_x(s.co, kind)
	var y := S.fv(s.co, x)
	var lu := value_label(s)
	var ans := num_ans(lu[0], y, lu[1])
	var y_end := S.fv(s.co, float(s.hi))
	var y_lo := S.fv(s.co, float(s.lo))
	var wr: Array = [num_wrong(x, false, R_X_ONLY if not big else R_INPUT), num_wrong(y_end, false, R_END)]
	var fill: Array = [num_fill(y_lo, false), num_fill(y * 1.1, false), num_fill(y * 0.9, false)]
	var what: String = STORY[s.model][4]
	var asked := "Find the %s %s." % [s.want, what] if s.model != "drone" else "Find the least fuel used per km."
	var dl := "%s = %s" % [dname(s), d_rhs(s)]
	var st: Array = S.stat(s.co)
	var quad: bool = st.size() == 1
	var zero: String
	if quad:
		zero = "%s = 0 gives %s = %s." % [d_rhs(s), v, W(x)]
	else:
		zero = "The GDC solver gives %s = 0 at %s = %s and %s = %s; it changes from %s to %s at %s = %s, the local %s." % [dname(s), v, W(st[0]), v, W(st[1]),
			"positive" if big else "negative", "negative" if big else "positive", v, W(x), kind]
	var ends := "The ends give %s = %s and %s = %s, both %s." % [at(s, float(s.lo), true), W(y_lo), at(s, float(s.hi), true), W(y_end), "lower" if big else "higher"]
	var steps := {
		"solve-then-substitute": [dl + ".", zero, "%s(%s) = %s. %s" % [fsym(s), W(x), W(y), ends], final_step(ans)],
		"gdc-max-min": ["Graph %s for %s ≤ %s ≤ %s on the GDC and use the %s tool." % [fname(s), Fmt.num(s.lo), v, Fmt.num(s.hi), kind],
			"It shows the %s at %s = %s, %s = %s; the ends of the graph are %s." % [kind, v, W(x), fsym(s), W(y), "lower" if big else "higher"],
			final_step(ans)],
	}
	if quad:
		var A: Q = s.co[1]
		var B: Q = s.co[2]
		steps["vertex-of-quadratic"] = [
			"%s is a quadratic with %s² coefficient %s, %s 0, so its one stationary point, the vertex, is its %s." % [fname(s), v, D(A), "less than" if A.sign() < 0 else "more than", kind],
			"%s = −b ÷ 2a = %s ÷ (2 × %s) = %s" % [v, D(B.neg()), "(" + D(A) + ")" if A.sign() < 0 else D(A), W(x)],
			"%s(%s) = %s" % [fsym(s), W(x), W(y)], final_step(ans)]
	return pack([f_line(s)], asked, ans, wr, fill, steps)


# ── Classify a stationary point ──────────────────────────────

static func rel(x: float) -> String:
	return ">" if x > 0.0 else "<"


static func q_dec(x: float) -> String:
	return Fmt.dec(Q.new(roundi(x * 10.0), 10))


func u_classify_stationary(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var co: Array = s.co
	var st: Array = S.stat(co)
	var p: float = st[s.at]
	var other: float = st[1 - s.at]
	var h := 0.1 if rep == "table" else 1.0
	var tl := p - h
	var tr := p + h
	var P0 := Fmt.num(roundi(p))
	var TL := q_dec(tl)
	var TR := q_dec(tr)
	var kind := S.nature(co, p)
	var other_kind := "minimum" if kind == "maximum" else "maximum"
	var dl := S.dv(co, tl)
	var dr := S.dv(co, tr)
	var evidence := "f′(%s) %s 0 and f′(%s) %s 0" % [TL, rel(dl), TR, rel(dr)]
	var change := "so f′ changes from %s to %s at x = %s" % [DerivativeGraphViews.sign_word(int(signf(dl))), DerivativeGraphViews.sign_word(int(signf(dr))), P0]
	var right := "Local %s: %s, %s" % [kind, evidence, change]
	var fl := S.fv(co, tl)
	var fr := S.fv(co, tr)
	var f_claim: String
	if signf(fl) == signf(fr):
		f_claim = "Neither: f(%s) %s 0 and f(%s) %s 0, so f does not change sign at x = %s" % [TL, rel(fl), TR, rel(fr), P0]
	else:
		f_claim = "Local %s: f(%s) %s 0 and f(%s) %s 0, so f changes from %s to %s at x = %s" % ["maximum" if fl > 0.0 else "minimum", TL, rel(fl), TR, rel(fr),
			DerivativeGraphViews.sign_word(int(signf(fl))), DerivativeGraphViews.sign_word(int(signf(fr))), P0]
	var u := roundi(minf(p, other)) - 1
	var w := roundi(maxf(p, other)) + 1
	var du := S.dv(co, float(u))
	var dw := S.dv(co, float(w))
	var beyond := "Neither: f′(%s) %s 0 and f′(%s) %s 0, so f′ does not change sign at x = %s" % [Fmt.num(u), rel(du), Fmt.num(w), rel(dw), P0]
	var built := SamplingViews.claims(right, [
		["Local %s: %s, %s" % [other_kind, evidence, change], R_REVERSED],
		[f_claim, R_F_SIGN],
		[beyond, R_BEYOND],
		["Neither: f′(%s) = 0, so the graph is flat at x = %s" % [P0, P0], ""],
		["Local %s: f(%s) = %s" % [kind, P0, Fmt.num(roundi(S.fv(co, p)))], ""]])
	var lines: Array = [f_line(s), "The graph of f has stationary points at x = %s and x = %s." % [Fmt.num(roundi(st[0])), Fmt.num(roundi(st[1]))]]
	var table: Variant = null
	if rep == "table":
		var xs := [tl, p, tr]
		table = {"rows": [["x", xs.map(func(t): return q_dec(t))],
			["f(x)", xs.map(func(t): return Fmt.dec(Q.new(roundi(S.fv(co, t) * 1000.0), 1000)))],
			["f′(x)", xs.map(func(t): return Fmt.dec(Q.new(roundi(S.dv(co, t) * 1000.0), 1000)))]]}
		lines.append("The table gives f(x) and f′(x) near x = %s." % P0)
	var a: Q = co[0]
	var left_kind := "maximum" if a.sign() > 0 else "minimum"
	var fpl := Fmt.dec(Q.new(roundi(dl * 1000.0), 1000))
	var fpr := Fmt.dec(Q.new(roundi(dr * 1000.0), 1000))
	var first: String
	if rep == "table":
		first = "From the table, f′(%s) = %s and f′(%s) = %s." % [TL, fpl, TR, fpr]
	else:
		first = "f′(x) = %s = %s, so f′(%s) = %s and f′(%s) = %s." % [d_rhs(s), factored(s, st), TL, fpl, TR, fpr]
	var steps := {
		"gradient-sign-either-side": [first,
			"Neither test point is past the other stationary point, x = %s, so these are the signs of f′ just either side of x = %s." % [Fmt.num(roundi(other)), P0],
			"So: %s." % right],
		"gdc-graph-shape": ["Graph y = f(x) on the GDC for %s ≤ x ≤ %s." % [Fmt.num(roundi(st[0]) - 2), Fmt.num(roundi(st[1]) + 2)],
			"Near x = %s the curve %s, so the point is a local %s." % [P0, "rises to the point and then falls" if kind == "maximum" else "falls to the point and then rises", kind],
			"So: %s." % right],
		"cubic-shape": ["The x³ coefficient of f is %s, which is %s, and f has two stationary points." % [D(a), "positive" if a.sign() > 0 else "negative"],
			"So the left one, x = %s, is the local %s and the right one, x = %s, the local %s." % [Fmt.num(roundi(st[0])), left_kind, Fmt.num(roundi(st[1])), "minimum" if left_kind == "maximum" else "maximum"],
			"So: %s." % right],
	}
	var out := pack(lines, "Determine the nature of the stationary point at x = %s. Which answer is fully justified?" % P0, built.answer, built.wrongs, built.fillers, steps)
	out.table = table
	return out


# ── The greatest or least value on a domain ──────────────────

func u_greatest_on_domain(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var words: bool = s.fam == "model"
	var exact := not words
	var big: bool = s.want == "greatest"
	var cands: Array = S.candidates(s)
	var b: Array = S.best(s, cands)
	var lu: Array = value_label(s) if words else ["%s value = " % s.want, ""]
	var ans := num_ans(lu[0], b[1], lu[1], exact)
	var slips := S.domain_slips(s)
	var wr: Array = []
	var fill: Array = []
	if slips.has("local"):
		# #0 speaks of a maximum and the greatest value; on a least value, the ends left out (#2).
		wr.append(num_wrong(slips.local, exact, R_LOCAL if big and rng.chance(0.5) else R_NO_ENDS))
	if slips.has("out"):
		wr.append(num_wrong(slips.out, exact, R_OUTSIDE))
	if slips.has("inside"):
		wr.append(num_wrong(slips.inside, exact, R_NO_ENDS))
	if slips.has("end"):
		fill.append(num_fill(slips.end, exact))
	fill.append(num_fill(-b[1], exact))
	fill.append(num_fill(b[1] + (1.0 if exact else b[1] * 0.1), exact))
	var v := letter(s)
	var st: Array = S.stat(s.co)
	var Vf := func(t: float) -> String: return Fmt.num(roundi(t)) if exact else W(t)
	var inside: Array = st.filter(func(t): return t > float(s.lo) and t < float(s.hi))
	var outside: Array = st.filter(func(t): return not (t > float(s.lo) and t < float(s.hi)))
	var zero: String
	if exact:
		zero = "%s = %s = 0 at x = %s and x = %s." % [dname(s), factored(s, st), Fmt.num(roundi(st[0])), Fmt.num(roundi(st[1]))]
	else:
		zero = "The GDC solver gives %s = 0 at %s = %s and %s = %s." % [dname(s), v, W(st[0]), v, W(st[1])]
	if not outside.is_empty():
		zero += " Only %s = %s is in the domain." % [v, Vf.call(inside[0])] if not inside.is_empty() else ""
	var vals: Array = []
	for c in cands:
		vals.append("%s(%s) = %s" % [fsym(s), Vf.call(c[0]), Vf.call(c[1])])
	var where: String = "an end of the domain" if b[2] == "end" else "the stationary point"
	var steps := {
		"compare-endpoints": [zero,
			"Compare the values at the stationary points in the domain and at both ends: %s." % ", ".join(vals),
			"The %s is %s(%s) = %s, at %s." % [s.want, fsym(s), Vf.call(b[0]), Vf.call(b[1]), where], final_step(ans)],
		"gdc-graph-on-domain": ["Set the GDC window to %s ≤ %s ≤ %s and graph y = %s." % [Fmt.num(s.lo), v, Fmt.num(s.hi), fname(s)],
			"The %s point of the graph is at %s, %s = %s, where %s = %s%s." % ["highest" if big else "lowest", where, v, Vf.call(b[0]), fsym(s), Vf.call(b[1]),
				"" if b[2] != "end" else ", %s than the local %s" % ["higher" if big else "lower", "maximum" if big else "minimum"]],
			final_step(ans)],
	}
	if b[2] == "end" and slips.has("local") == false:
		steps["gdc-graph-on-domain"][1] = "The %s point of the graph is at %s, %s = %s, where %s = %s." % ["highest" if big else "lowest", where, v, Vf.call(b[0]), fsym(s), Vf.call(b[1])]
	var asked := "Find the %s value of %s for %s ≤ %s ≤ %s." % [s.want, fname(s) if not words else fsym(s), Fmt.num(s.lo), v, Fmt.num(s.hi)]
	return pack([f_line(s)], asked, ans, wr, fill, steps)


# ── The local maximum is not the greatest ────────────────────

func u_local_not_greatest(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var words: bool = s.fam == "model"
	var exact := not words
	var v := letter(s)
	var want: String = s.want
	var big: bool = want == "maximum"
	var x := S.extremum_x(s.co, want)
	var y := S.fv(s.co, x)
	var e: Array = S.far_end(s)
	var other_end: float = float(s.hi) if e[0] == float(s.lo) else float(s.lo)
	var yo := S.fv(s.co, other_end)
	var Vf := func(t: float) -> String: return Fmt.num(roundi(t)) if exact or is_whole(t) else Fmt.sf(t)
	var fx := func(t: float) -> String: return "%s(%s)" % [fsym(s), Vf.call(t)]
	var zero_at := "%s = 0 at %s = %s" % [dname(s), v, Vf.call(x)] if words else "f′(%s) = 0" % Vf.call(x)
	var more := "greater" if big else "less"
	var right := "No: %s = %s is %s than the local %s, %s = %s" % [fx.call(e[0]), Vf.call(e[1]), more, want, fx.call(x), Vf.call(y)]
	var wrongs: Array = [["Yes: the local %s, %s = %s, is the %s value, because %s" % [want, fx.call(x), Vf.call(y), "greatest" if big else "least", zero_at], R_LOCAL if big else R_NO_ENDS],
		["No: %s = %s is %s than the local %s, %s = %s" % [fx.call(other_end), Vf.call(yo), more, want, fx.call(x), Vf.call(y)], ""],
		["Yes: %s = %s is %s than %s = %s" % [fx.call(x), Vf.call(y), more, fx.call(other_end), Vf.call(yo)], ""]]
	var built := SamplingViews.claims(right, wrongs)
	var lines: Array = [f_line(s)]
	var g: Variant = null
	if rep == "graph":
		var fn := func(t: float) -> float: return S.fv(s.co, t)
		g = MonotonicViews.graph_of(fn, float(s.lo), float(s.hi), [[x, y, ""], [float(e[0]), float(e[1]), ""], [other_end, yo, ""]])
		lines.append("The graph of y = f(x) is shown. f has a local %s at x = %s." % [want, Vf.call(x)])
	else:
		lines.append("%s has a local %s at %s = %s." % [fsym(s), want, v, Vf.call(x)])
	var asked := "Is the local %s value the %s value of %s for %s ≤ %s ≤ %s? Which answer is fully justified?" % [want, "greatest" if big else "least", fsym(s), Fmt.num(s.lo), v, Fmt.num(s.hi)]
	var W6 := func(t: float) -> String: return Fmt.num(roundi(t)) if exact else W(t)
	var out := pack(lines, asked, built.answer, built.wrongs, built.fillers, {
		"compare-endpoints": ["The %s value on a domain is at a local %s or at an end, so compare all three." % ["greatest" if big else "least", want],
			"%s(%s) = %s, %s(%s) = %s and %s(%s) = %s." % [fsym(s), W6.call(x), W6.call(y), fsym(s), W6.call(s.lo), W6.call(S.fv(s.co, float(s.lo))), fsym(s), W6.call(s.hi), W6.call(S.fv(s.co, float(s.hi)))],
			"So: %s." % right],
		"gdc-graph-on-domain": ["Graph y = %s for %s ≤ %s ≤ %s on the GDC." % [fname(s), Fmt.num(s.lo), v, Fmt.num(s.hi)],
			"The end of the graph at %s = %s is %s than its local %s at %s = %s." % [v, Vf.call(e[0]), "higher" if big else "lower", want, v, Vf.call(x)],
			"So: %s." % right],
	})
	out.graph = g
	return out


# ── The graph of f′ (DerivativeGraphViews, re-tagged) ────────

## The derivative-graph slips that mean the same here, by its ref; any other is dropped to a filler.
const RETAG := {"SL5.7.f-from-derivative-graph#0": R_FP_TURN, "SL5.7.f-from-derivative-graph#1": R_TOUCH,
	"SL5.7.f-from-derivative-graph#5": R_TOUCH, "SL5.7.f-from-derivative-graph#11": R_WAY_ROUND}
const METHODS := {"sign-change-of-f-prime": "sign-of-gradient-graph", "sign-diagram": "sketch-f-from-signs"}


static func _retag(out: Dictionary, kind: String) -> void:
	var keep: Array = []
	var fill: Array = out.get("fillers", [])
	for w in out.get("wrongs", []):
		var ref: String = RETAG.get(w.ref, "")
		# A maximum read at the other crossing: the slip of #1 only when a maximum is asked.
		if ref == R_WAY_ROUND and kind != "maximum":
			ref = ""
		if ref == "":
			fill.append(w.values)
		else:
			keep.append(wrong(w.values, ref))
	for g in out.get("generic", []):
		fill.append(g)
	out.wrongs = keep
	out.fillers = fill
	out.generic = []
	var ms := {}
	for m in out.methods:
		ms[METHODS.get(m, m)] = out.methods[m]
	out.methods = ms


func u_extremum_from_gradient_graph(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = _dg.u_extremum_from_derivative("graph", s, rng)
	_retag(out, DerivativeGraphViews.extremum(s).kind)
	return out


func u_increasing_from_gradient_graph(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = _dg.u_increasing_past_touch("graph", s, rng)
	_retag(out, "")
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var tsg := DerivativeGraphViews.left_sign(s, b)
	var up: bool = tsg > 0
	var word := "increasing" if up else "decreasing"
	# Where the graph of f′ rises (or falls): f″ = 3k(x − b)(x − c) has the sign of k outside c and b.
	var lo := mini(b, c)
	var hi := maxi(b, c)
	var rises_outside: bool = s.k > 0
	var shape := "outside" if rises_outside == up else "between"
	var rises := MonotonicViews.interval_text(shape, lo, hi)
	var ref := R_FP_RISES if up else ""
	if ref != "":
		out.wrongs.append(DifferentiationViews.alt(rises, ref))
	else:
		out.fillers.append(DifferentiationViews.alt(rises).values)
	var ans: Dictionary = out.answer
	var on_right: bool = b > a
	out.methods["sign-of-gradient-graph"] = method([
		"f is %s where the graph of f′ is %s the x-axis, whether the graph is rising or falling there." % [word, "above" if up else "below"],
		"The graph is %s the axis for %s, touching it at x = %s only, and %s it on the other side of x = %s." % ["above" if up else "below", "x > %s" % Fmt.num(a) if on_right else "x < %s" % Fmt.num(a), Fmt.num(b), "below" if up else "above", Fmt.num(a)],
		Answer.text(ans)], ans.values)
	return out


func u_pick_f_from_gradient_graph(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = _dg.u_pick_f_from_derivative("graph", s, rng)
	var by_mistake := {"copy": "", "flipped": R_WAY_ROUND, "touch-turn": R_TOUCH, "peak": R_FP_TURN}
	for g in out.graphs:
		if not g.correct:
			g.ref = by_mistake.get(g.mistake, "")
	var ms := {}
	var ans: Dictionary = out.answer
	ms["sign-of-gradient-graph"] = out.methods["sign-change-of-f-prime"]
	var kind := DerivativeGraphViews.nature(s, s.a)
	var rise := func(sg: int) -> String: return "rises" if sg > 0 else "falls"
	var cuts: Array = [s.a, s.b]
	cuts.sort()
	var f := DerivativeGraphSituation.fn(s)
	var parts: Array = [rise.call(int(signf(f.call(cuts[0] - 0.5)))), rise.call(int(signf(f.call((cuts[0] + cuts[1]) / 2.0)))), rise.call(int(signf(f.call(cuts[1] + 0.5))))]
	ms["sketch-f-from-signs"] = method([
		"Sign row of f′: %s." % DerivativeGraphViews.sign_row(s, cuts),
		"So f has one turning point, the local %s at x = %s where f′ changes sign; at x = %s it %s on both sides, flat for an instant but not turning." % [kind, Fmt.num(s.a), Fmt.num(s.b), parts[0] if s.b == cuts[0] else parts[2]],
		Answer.text(ans)], ans.values)
	out.methods = ms
	return out
