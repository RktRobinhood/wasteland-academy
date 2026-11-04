class_name LineConditionsViews
extends ExtensionViews
## The views on the `line-conditions` situation: one builder per unknown of
## fn-line-from-conditions and fn-concept-gradient-meaning (FAL-424). A gradient or a coordinate is
## a typed number, an equation is the `line` kind (y = mx + c) or the `gline` kind (ax + by + d = 0,
## as the situation's `form` says), and a reason is a pick of four written statements (`choice`).
## Paper 1 is exact. Paper 2 is the gradient and the equation of a line through two points, to
## 3 s.f.; GDC regression only makes Paper 2 (`papers()`).

const R_RUN_RISE := "SL2.1.gradient#0"
const R_ORDER := "SL2.1.gradient#1"
const R_COEF := "SL2.1.gradient#2"
const R_PLUS := "SL2.1.equation-of-line#0"
const R_OTHER_M := "SL2.1.equation-of-line#2"
const R_YINT_POINT := "SL2.1.intercepts#0"
const R_SWAP_INT := "SL2.1.intercepts#1"
const R_YINT_D := "SL2.1.intercepts#2"
const R_PERP := "SL2.1.parallel-perpendicular#0"
const R_PRODUCT_1 := "SL2.1.parallel-perpendicular#1"
const R_BISECT := "SL2.1.parallel-perpendicular#2"
const R_MID := "SL3.1.midpoint-3d#0"
const R_TOTAL := "SL2.1.line-model#0"
const GDC_ONLY := ["equation-two-points", "equation-from-intercepts"]


func needs() -> Dictionary:
	return {
		"gradient-from-two-points": {"mode": "any-two"},
		"gradient-from-general": {"mode": "line"},
		"gradient-from-graph": {"mode": "any-two"},
		"missing-coordinate-from-gradient": {"mode": "line"},
		"perpendicular-gradient": {"mode": "line", "rel": "perp"},
		"equation-point-gradient": {"mode": "line"},
		"equation-two-points": {"mode": "any-two"},
		"midpoint-then-line": {"mode": "midline"},
		"equation-from-intercepts": {"mode": "intercepts-eq"},
		"parallel-through-point": {"mode": "line", "rel": "para"},
		"perpendicular-through-point": {"mode": "line", "rel": "perp"},
		"perpendicular-bisector": {"mode": "bisector"},
		"unknown-coordinate": {"mode": "line", "c_nz": true},
		"general-form": {"mode": "line", "frac": true},
		"intercepts-from-equation": {"mode": "line", "c_nz": true},
		"triangle-area": {"mode": "line", "c_nz": true},
		"check-perpendicular": {"mode": "line"},
		"k-for-perpendicular": {"mode": "line"},
	}


## A graph's intercepts sit on grid points.
func need(unknown: String, rep: String) -> Dictionary:
	var n := super.need(unknown, rep)
	if unknown in ["intercepts-from-equation", "triangle-area"] and rep == "graph":
		n.mode = "intercepts"
	return n


## Paper 2 is a line through two points. GDC regression needs a calculator.
func papers(unknown: String, _rep: String, angle: String) -> Array:
	if unknown in GDC_ONLY and angle == "gdc-regression":
		return [2]
	if unknown in ["gradient-from-two-points", "equation-two-points"]:
		return [1, 2]
	return [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = LineConditionsSituation.export(s)
	return out


static func N(v: Variant) -> String:
	return Fmt.num(v)


## A coordinate: a whole number, or one decimal place on Paper 2.
static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func P(v: Variant) -> String:
	var q := Q.of(v)
	return "(%s)" % D(q) if q.sign() < 0 else D(q)


static func PF(v: Variant) -> String:
	return Fmt.paren(v)


static func pt(x: Variant, y: Variant) -> String:
	return "(%s, %s)" % [D(x), D(y)]


static func yeq(m: Variant, c: Variant) -> String:
	return "y = " + Fmt.poly([m, c])


static func gtext(a: Variant, b: Variant, d: Variant) -> String:
	return Answer.gline_text(a, b, d)


## A worked value: exact on Paper 1, six figures on Paper 2.
static func G(s: Dictionary, v: Variant) -> String:
	return Fmt.sf(v, 6) if s.paper == 2 else N(v)


static func line_text(form: String, n: Q, c: Q) -> String:
	if form == "sl":
		return yeq(n, c)
	var g := LineConditionsSituation.gen(n, c)
	return gtext(g[0], g[1], g[2])


## The line AB as the question gives it.
static func given_ab(s: Dictionary) -> String:
	return line_text(s.gform, s.m, s.c0)


## The new line as the question gives it.
static func given_new(s: Dictionary) -> String:
	return line_text(s.gform, s.n, s.c)


# ── Answers ──────────────────────────────────────────────────

static func exactly(s: Dictionary, ans: Dictionary) -> Dictionary:
	if s.paper == 2:
		ans.show = "sf"
	else:
		ans.exact = true
	return ans


static func number(s: Dictionary, v: Variant, label: String) -> Dictionary:
	return exactly(s, Answer.make("number", {"v": Q.of(v)}, {}, label))


static func eq_values(form: String, n: Q, c: Q) -> Dictionary:
	if form == "sl":
		return {"m": n, "c": c}
	var g := LineConditionsSituation.gen(n, c)
	return {"a": Q.new(g[0]), "b": Q.new(g[1]), "d": Q.new(g[2])}


static func eq_answer(s: Dictionary, n: Q, c: Q, form: String = "") -> Dictionary:
	var f: String = s.form if form == "" else form
	return exactly(s, Answer.make("line" if f == "sl" else "gline", eq_values(f, n, c)))


static func form_ask(form: String) -> String:
	if form == "sl":
		return " Give it in the form y = mx + c."
	return " Give it in the form ax + by + d = 0, where a, b and d are integers and a > 0."


static func fin(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## A wrong line through (x, y) with gradient n, tagged.
static func through(s: Dictionary, n: Q, x: Q, y: Q, ref: String = "") -> Dictionary:
	return wrong(eq_values(s.form, n, y.sub(n.mul(x))), ref)


static func pick(right: String, bad: Array, plain: Array) -> Dictionary:
	return InverseRuleViews.choose(right, bad, plain)


static func tag(text: String, ref: String) -> Dictionary:
	return InverseRuleViews.tag(text, ref)


# ── Showing a line ───────────────────────────────────────────

static func curve(m: Q, c: Q) -> Array:
	var mf := m.to_float()
	var cf := c.to_float()
	return Plot.sample(func(x: float) -> float: return mf * x + cf, -10.0, 10.0)


## A graph of lines ([[m, c], ...]) with marked points ([[x, y, label], ...]).
static func plot(lines: Array, points: Array, vlines: Array = []) -> Dictionary:
	var w: Array = LineConditionsSituation.WIN
	return Plot.spec(lines.map(func(l): return curve(l[0], l[1])), points.map(func(p): return [p[0].to_float(), p[1].to_float(), p[2]]),
		w[0], w[1], w[2], w[3], [], vlines)


## A and B in words, on a grid or in a table with a third point of the line.
static func show_ab(out: Dictionary, rep: String, s: Dictionary) -> void:
	match rep:
		"graph":
			out.lines = ["The line through A and B is drawn on the grid."]
			out.graph = plot([[s.m, s.c0]], [[s.ax, s.ay, "A" + pt(s.ax, s.ay)], [s.bx, s.by, "B" + pt(s.bx, s.by)]])
		"table":
			var cx: Q = s.bx.add(s.dx)
			var cy: Q = s.by.add(s.dy)
			out.lines = ["The table lists points A, B and C on a straight line."]
			out.table = {"rows": [["", ["A", "B", "C"]], ["x", [s.ax, s.bx, cx].map(func(v): return D(v))], ["y", [s.ay, s.by, cy].map(func(v): return D(v))]]}
		_:
			out.lines = ["A is the point %s and B is the point %s." % [pt(s.ax, s.ay), pt(s.bx, s.by)]]


static func two_point_steps(s: Dictionary) -> Array:
	return ["Take (x₁, y₁) = %s and (x₂, y₂) = %s." % [pt(s.ax, s.ay), pt(s.bx, s.by)],
		"m = (y₂ − y₁)/(x₂ − x₁) = (%s − %s)/(%s − %s) = %s/%s = %s." % [D(s.by), P(s.ay), D(s.bx), P(s.ax), D(s.dy), P(s.dx), G(s, s.m)]]


static func rise_steps(s: Dictionary) -> Array:
	return ["From A to B the run is %s and the rise is %s." % [D(s.dx), D(s.dy)], "m = rise ÷ run = %s ÷ %s = %s." % [D(s.dy), P(s.dx), G(s, s.m)]]


## The steps of y − y₁ = m(x − x₁) to the answer.
static func pg_steps(s: Dictionary, x: Q, y: Q, n: Q, c: Q, ans: Dictionary) -> Array:
	var head := "y − %s = %s(x − %s)" % [P(y), Fmt.lead(n), P(x)]
	return ["Put the point %s and the gradient %s into y − y₁ = m(x − x₁): %s." % [pt(x, y), G(s, n), head],
		"Expand and collect: %s." % yeq(n, c), fin(ans)]


static func c_steps(s: Dictionary, x: Q, y: Q, n: Q, c: Q, ans: Dictionary) -> Array:
	return ["Put %s into y = %sx + c: %s = %s × %s + c." % [pt(x, y), Fmt.lead(n), D(y), PF(n), P(x)], "So c = %s, and the line is %s." % [G(s, c), yeq(n, c)], fin(ans)]


static func move_steps(x: Q, y: Q, n: Q, c: Q, ans: Dictionary) -> Array:
	return ["Start from y = %sx, the line through the origin with this gradient." % Fmt.lead(n),
		"Move it by the vector (%s, %s), so x becomes x − %s and y becomes y − %s." % [D(x), D(y), P(x), P(y)], "That gives %s." % yeq(n, c), fin(ans)]


# ── Gradients ────────────────────────────────────────────────

func u_gradient_from_two_points(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := number(s, s.m, "m = ")
	var out := {"asked": "Find the gradient of the line through A and B.", "answer": ans}
	show_ab(out, rep, s)
	out.wrongs = [wrong({"v": s.dx.div(s.dy)}, R_RUN_RISE), wrong({"v": s.m.neg()}, R_ORDER)]
	out.generic = [{"v": s.dy}, {"v": s.dx}, {"v": s.dy.add(s.dx)}]
	out.methods = {
		"two-point-formula": method(two_point_steps(s) + [fin(ans)], ans.values),
		"rise-over-run": method(rise_steps(s) + [fin(ans)], ans.values),
	}
	return out


func u_gradient_from_general(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a0
	var b: int = s.b0
	var d: int = s.d0
	var ans := number(s, s.m, "m = ")
	var out := {"asked": "Find the gradient of the line.", "answer": ans, "lines": [gtext(a, b, d)]}
	out.wrongs = [wrong({"v": Q.new(a)}, R_COEF), wrong({"v": Q.new(-a)}, R_COEF), wrong({"v": Q.new(b)}, R_COEF)]
	out.generic = [{"v": Q.new(b, a)}, {"v": Q.new(d, b)}, {"v": Q.new(a, b)}]
	out.methods = {
		"rearrange-to-slope-intercept": method(["Keep the y term alone: %sy = %s." % [Fmt.lead(b), Fmt.poly([-a, -d])], "Divide by %s: %s." % [N(b), yeq(s.m, s.c0)], fin(ans)], ans.values),
		"coefficient-shortcut": method(["For ax + by + d = 0 the gradient is −a/b. Here a = %s and b = %s." % [N(a), N(b)], "m = −%s/%s = %s." % [P(a), P(b), N(s.m)], fin(ans)], ans.values),
	}
	return out


func u_gradient_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := number(s, s.m, "m = ")
	var out := {"asked": "Find the gradient of the line.", "answer": ans, "lines": ["The line is drawn on the grid, with two grid points marked."]}
	out.graph = plot([[s.m, s.c0]], [[s.ax, s.ay, ""], [s.bx, s.by, ""]])
	out.wrongs = [wrong({"v": s.dx.div(s.dy)}, R_RUN_RISE), wrong({"v": s.m.neg()}, R_ORDER)]
	out.generic = [{"v": s.dy}, {"v": s.dx}, {"v": s.dy.add(s.dx)}]
	out.methods = {"rise-over-run": method(["Count from one marked point to the other: %s across and %s up." % [D(s.dx), D(s.dy)], "m = rise ÷ run = %s ÷ %s = %s." % [D(s.dy), P(s.dx), G(s, s.m)], fin(ans)], ans.values)}
	return out


func u_missing_coordinate_from_gradient(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Q = s.m
	var hidden_y: bool = s.hide == "y" or rep == "graph"
	var v: Q = s.by if hidden_y else s.bx
	var ans := number(s, v, "t = ")
	var b_text := "(%s, t)" % D(s.bx) if hidden_y else "(t, %s)" % D(s.by)
	var out := {"asked": "The line through A and B has gradient %s. Find t." % N(m), "answer": ans}
	if rep == "graph":
		out.lines = ["A is marked. B%s is somewhere on the dashed line." % b_text]
		out.graph = plot([], [[s.ax, s.ay, "A" + pt(s.ax, s.ay)]], [[s.bx.to_float(), "x = " + D(s.bx)]])
	else:
		out.lines = ["A is the point %s and B is the point %s." % [pt(s.ax, s.ay), b_text]]
	if hidden_y:
		out.wrongs = [wrong({"v": s.ay.add(s.dx.div(m))}, R_RUN_RISE), wrong({"v": s.ay.sub(m.mul(s.dx))}, R_ORDER)]
		out.generic = [{"v": m.mul(s.dx)}, {"v": s.ay.add(m)}, {"v": v.neg()}]
	else:
		out.wrongs = [wrong({"v": s.ax.add(s.dy.mul(m))}, R_RUN_RISE), wrong({"v": s.ax.sub(s.dy.div(m))}, R_ORDER)]
		out.generic = [{"v": s.dy.div(m)}, {"v": s.ax.add(m)}, {"v": v.neg()}]
	var change: String = ("rise = %s × %s = %s" % [N(m), P(s.dx), N(s.dy)]) if hidden_y else ("run = %s ÷ %s = %s" % [D(s.dy), PF(m), D(s.dx)])
	out.methods = {
		"two-point-formula": method([("%s = (t − %s)/(%s − %s)" % [N(m), P(s.ay), D(s.bx), P(s.ax)]) if hidden_y else ("%s = (%s − %s)/(t − %s)" % [N(m), D(s.by), P(s.ay), P(s.ax)]), "Solve: %s, so t = %s." % [change, D(v)], fin(ans)], ans.values),
		"rise-over-run": method(["From A to B the %s." % change, "Add it to A's coordinate: t = %s + %s = %s." % [D(s.ay if hidden_y else s.ax), P(s.dy if hidden_y else s.dx), D(v)], fin(ans)], ans.values),
	}
	return out


func u_perpendicular_gradient(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Q = s.m
	var n: Q = s.n
	var ans := number(s, n, "m = ")
	var out := {"answer": ans}
	var two: Array
	if rep == "words":
		out.asked = "Line L is perpendicular to AB. Find the gradient of L."
		out.lines = ["A is the point %s and B is the point %s." % [pt(s.ax, s.ay), pt(s.bx, s.by)]]
		two = two_point_steps(s)
	else:
		out.asked = "Line L₂ is perpendicular to L₁. Find the gradient of L₂."
		out.lines = ["L₁: " + given_ab(s)]
		two = ["Two points on L₁ are %s and %s." % [pt(s.ax, s.ay), pt(s.bx, s.by)], "m = (%s − %s)/(%s − %s) = %s." % [D(s.by), P(s.ay), D(s.bx), P(s.ax), N(m)]]
	out.wrongs = [wrong({"v": m.neg()}, R_PERP), wrong({"v": Q.new(1).div(m)}, R_PERP)]
	out.generic = [{"v": m}, {"v": n.add(1)}, {"v": m.add(1)}]
	var flip := "Flip %s and change the sign: %s." % [N(m), N(n)]
	var first := "The gradient of the first line is %s." % N(m)
	var run: Q = s.dx
	var up: Q = s.dy
	out.methods = {
		"two-point-formula": method(two + ["Perpendicular gradients multiply to −1, so %s." % ("m = −1 ÷ %s = %s" % [PF(m), N(n)]), fin(ans)], ans.values),
		"negative-reciprocal": method([first, flip, fin(ans)], ans.values),
		"rotate-direction": method(["A step along the first line is (%s, %s)." % [D(run), D(up)], "A quarter-turn sends (a, b) to (−b, a), so the step becomes (%s, %s), a gradient of %s ÷ %s = %s." % [D(up.neg()), D(run), D(run), P(up.neg()), N(n)], fin(ans)], ans.values),
	}
	return out


# ── Equations ────────────────────────────────────────────────

func u_equation_point_gradient(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: Q = s.n
	var c: Q = s.c
	var ans := eq_answer(s, n, c)
	var out := {"asked": "Find the equation of the line." + form_ask(s.form), "answer": ans,
		"lines": ["A line passes through %s and has gradient %s." % [pt(s.px, s.py), N(n)]]}
	out.wrongs = [through(s, n, s.px.neg(), s.py, R_PLUS)]
	out.generic = [through(s, n, s.py, s.px).values, through(s, n.neg(), s.px, s.py).values, eq_values(s.form, n, s.py)]
	out.methods = {
		"point-gradient": method(pg_steps(s, s.px, s.py, n, c, ans), ans.values),
		"solve-for-c": method(c_steps(s, s.px, s.py, n, c, ans), ans.values),
		"translate-origin-line": method(move_steps(s.px, s.py, n, c, ans), ans.values),
	}
	return out


func u_equation_two_points(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Q = s.m
	var c: Q = s.c0
	var ans := eq_answer(s, m, c)
	var out := {"asked": "Find the equation of the line through A and B." + form_ask(s.form), "answer": ans}
	show_ab(out, rep, s)
	out.wrongs = [through(s, m.neg(), s.ax, s.ay, R_ORDER), through(s, s.dx.div(s.dy), s.ax, s.ay, R_RUN_RISE)]
	out.generic = [eq_values(s.form, m, c.neg()), through(s, m, s.bx, s.ax).values, through(s, m, s.ay, s.ax).values]
	var form_step := fin(ans)
	var g_m: String = G(s, m)
	var g_c: String = G(s, c)
	out.methods = {
		"two-point-formula": method(two_point_steps(s) + ["Then c = y₁ − mx₁ = %s − %s × %s = %s." % [D(s.ay), g_m, P(s.ax), g_c], form_step], ans.values),
		"point-gradient": method(["The gradient is %s." % g_m, "y − %s = %s(x − %s)." % [P(s.ay), g_m, P(s.ax)], "Expand and collect: %s." % (yeq(m, c) if s.paper == 1 else "y = " + Answer.sf_line(m, c)), form_step], ans.values),
		"solve-for-c": method(["The gradient is %s." % g_m, "Put A into y = mx + c: %s = %s × %s + c, so c = %s." % [D(s.ay), g_m, P(s.ax), g_c], form_step], ans.values),
		"gdc-regression": method(["Put the x-values into L1 and the y-values into L2.", "LinReg(ax + b) gives a = %s and b = %s." % [g_m, g_c], form_step], ans.values),
	}
	return out


func u_midpoint_then_line(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: Q = s.n
	var c: Q = s.c
	var ans := eq_answer(s, n, c)
	var t_text := "the origin" if s.tx.is_zero() and s.ty.is_zero() else "T" + pt(s.tx, s.ty)
	var out := {"asked": "M is the midpoint of AB. Find the equation of the line through M and %s." % t_text + form_ask(s.form), "answer": ans}
	if rep == "graph":
		out.lines = ["A and B are marked on the grid."]
		var pts: Array = [[s.ax, s.ay, "A" + pt(s.ax, s.ay)], [s.bx, s.by, "B" + pt(s.bx, s.by)]]
		if t_text != "the origin":
			pts.append([s.tx, s.ty, t_text])
		out.graph = plot([], pts)
	else:
		out.lines = ["A is the point %s and B is the point %s." % [pt(s.ax, s.ay), pt(s.bx, s.by)]]
	out.wrongs = []
	if not s.hx.eq(s.tx):
		var hn: Q = s.hy.sub(s.ty).div(s.hx.sub(s.tx))
		out.wrongs.append(through(s, hn, s.hx, s.hy, R_MID))
	out.generic = [through(s, s.m, s.tx, s.ty).values, eq_values(s.form, n, c.neg()), through(s, n, s.ax, s.ay).values, through(s, n.neg(), s.mx, s.my).values]
	var mid := "M = ((%s + %s)/2, (%s + %s)/2) = %s." % [D(s.ax), P(s.bx), D(s.ay), P(s.by), pt(s.mx, s.my)]
	var grad := "The gradient from M to %s is (%s − %s)/(%s − %s) = %s." % [pt(s.tx, s.ty), D(s.my), P(s.ty), D(s.mx), P(s.tx), N(n)]
	out.methods = {
		"point-gradient": method([mid, grad, "y − %s = %s(x − %s), so %s." % [P(s.my), Fmt.lead(n), P(s.mx), yeq(n, c)], fin(ans)], ans.values),
		"average-coordinates": method(["Average each coordinate of A and B: %s" % mid, grad, "Then c = %s − %s × %s = %s, so %s." % [D(s.my), PF(n), P(s.mx), N(c), yeq(n, c)], fin(ans)], ans.values),
	}
	return out


func u_equation_from_intercepts(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Q = s.m
	var c: Q = s.c0
	var p: Q = s.ax
	var q: Q = s.by
	var ans := eq_answer(s, m, c)
	var out := {"asked": "Find the equation of the line." + form_ask(s.form), "answer": ans}
	if rep == "graph":
		out.lines = ["The line crosses the axes at the two marked points."]
		out.graph = plot([[m, c]], [[p, Q.new(0), ""], [Q.new(0), q, ""]])
	else:
		out.lines = ["A line crosses the x-axis at x = %s and the y-axis at y = %s." % [N(p), N(q)]]
	out.wrongs = [through(s, m.neg(), Q.new(0), q, R_ORDER), through(s, p.div(q).neg(), Q.new(0), p, R_SWAP_INT)]
	out.generic = [eq_values(s.form, m, p), through(s, p.div(q), Q.new(0), q).values, eq_values(s.form, m, q.neg())]
	var g_m: String = G(s, m)
	var g_c: String = G(s, c)
	var points := "The line goes through (%s, 0) and (0, %s)." % [N(p), N(q)]
	var slope := "m = (%s − 0)/(0 − %s) = %s." % [N(q), P(p), g_m]
	out.methods = {
		"two-point-formula": method([points, slope, "The y-intercept is %s." % N(q), fin(ans)], ans.values),
		"gdc-regression": method([points, "Put 0 and %s into L1 and %s and 0 into L2: LinReg(ax + b) gives a = %s and b = %s." % [N(p), N(q), g_m, g_c], fin(ans)], ans.values),
		"cover-up": method(["With intercepts p and q the line is x/p + y/q = 1: x/%s + y/%s = 1." % [PF(p), PF(q)], "Multiply by %s: %s." % [PF(p.mul(q)), gtext(q, p, p.mul(q).neg())], "Rearranged, that is %s." % yeq(m, c), fin(ans)], ans.values),
		"read-graph": method(["Read the crossing points: (%s, 0) and (0, %s). The y-intercept is c = %s." % [N(p), N(q), N(q)], "From (%s, 0) to (0, %s): run %s, rise %s, so m = %s." % [N(p), N(q), N(p.neg()), N(q), g_m], fin(ans)], ans.values),
	}
	return out


func _new_through(out: Dictionary, s: Dictionary, ans: Dictionary, names: Array, extra: Dictionary) -> void:
	out.methods = extra
	for a in names:
		match a:
			"point-gradient":
				out.methods[a] = method(pg_steps(s, s.px, s.py, s.n, s.c, ans), ans.values)
			"solve-for-c":
				out.methods[a] = method(c_steps(s, s.px, s.py, s.n, s.c, ans), ans.values)
			"translate-origin-line":
				out.methods[a] = method(move_steps(s.px, s.py, s.n, s.c, ans), ans.values)


## The first line, then its gradient: said for a given equation or for the points.
static func first_gradient(rep: String, s: Dictionary) -> String:
	if rep == "words":
		return "The gradient of AB is (%s − %s)/(%s − %s) = %s." % [D(s.by), P(s.ay), D(s.bx), P(s.ax), N(s.m)]
	return "L₁ rearranges to %s, so its gradient is %s." % [yeq(s.m, s.c0), N(s.m)]


## The new line from the old one's coefficients: k = ax + by at P for a parallel; b and −a
## swapped for a perpendicular.
static func coef_steps(s: Dictionary, ans: Dictionary) -> Array:
	var a: int = s.a0
	var b: int = s.b0
	var d: int = s.d0
	var para: bool = s.rel == "para"
	var a2: int = a if para else b
	var b2: int = b if para else -a
	var k: Q = Q.new(a2).mul(s.px).add(Q.new(b2).mul(s.py))
	var head := "The first line is %s." % gtext(a, b, d)
	var keep := ("A parallel line keeps a and b: %sx%s = k." % [Fmt.lead(a2), Fmt.term(Q.new(b2), 1, false, "y")]) if para else ("A perpendicular line swaps a and b and changes one sign: %sx%s = k." % [Fmt.lead(a2), Fmt.term(Q.new(b2), 1, false, "y")])
	return [head, keep, "Put in P: k = %s × %s + %s × %s = %s." % [N(a2), P(s.px), P(b2), P(s.py), N(k)], "Rearranged, that is %s." % yeq(s.n, s.c), fin(ans)]


func u_parallel_through_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: Q = s.n
	var ans := eq_answer(s, n, s.c)
	var out := {"answer": ans}
	var name := "P" + pt(s.px, s.py)
	if rep == "words":
		out.asked = "Line L is parallel to AB and passes through %s. Find the equation of L." % name + form_ask(s.form)
		out.lines = ["A is the point %s and B is the point %s." % [pt(s.ax, s.ay), pt(s.bx, s.by)]]
	else:
		out.asked = "Line L₂ is parallel to L₁ and passes through %s. Find the equation of L₂." % name + form_ask(s.form)
		out.lines = ["L₁: " + given_ab(s)]
	var perp := Q.new(-1).div(n)
	out.wrongs = [through(s, perp, s.px, s.py, R_OTHER_M), through(s, n, s.px.neg(), s.py, R_PLUS)]
	out.generic = [eq_values(s.form, n, s.c0), through(s, n.neg(), s.px, s.py).values, through(s, n, s.py, s.px).values]
	var first := first_gradient(rep, s)
	var extra := {
		"rearrange-to-slope-intercept": method([first, "The new line has the same gradient: y = %sx + c." % Fmt.lead(n), "Put in P: c = %s − %s × %s = %s." % [D(s.py), PF(n), P(s.px), N(s.c)], fin(ans)], ans.values),
		"negative-reciprocal": method([first, "Flipping and changing the sign is for a perpendicular line. Parallel lines keep the gradient %s." % N(n), "Through P: c = %s − %s × %s = %s." % [D(s.py), PF(n), P(s.px), N(s.c)], fin(ans)], ans.values),
		"keep-coefficients": method(coef_steps(s, ans), ans.values),
	}
	_new_through(out, s, ans, ["point-gradient", "solve-for-c", "translate-origin-line"], extra)
	return out


func u_perpendicular_through_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: Q = s.n
	var ans := eq_answer(s, n, s.c)
	var out := {"answer": ans}
	var name := "P" + pt(s.px, s.py)
	match rep:
		"words":
			out.asked = "Line L is perpendicular to AB and passes through %s. Find the equation of L." % name + form_ask(s.form)
			out.lines = ["A is the point %s and B is the point %s." % [pt(s.ax, s.ay), pt(s.bx, s.by)]]
		"graph":
			out.asked = "Line L is perpendicular to the line drawn and passes through P. Find the equation of L." + form_ask(s.form)
			out.lines = ["The line through A and B is drawn on the grid, with P marked."]
			out.graph = plot([[s.m, s.c0]], [[s.ax, s.ay, "A" + pt(s.ax, s.ay)], [s.bx, s.by, "B" + pt(s.bx, s.by)], [s.px, s.py, name]])
		_:
			out.asked = "Line L₂ is perpendicular to L₁ and passes through %s. Find the equation of L₂." % name + form_ask(s.form)
			out.lines = ["L₁: " + given_ab(s)]
	out.wrongs = [through(s, s.m, s.px, s.py, R_OTHER_M), through(s, s.m.neg(), s.px, s.py, R_PERP), through(s, Q.new(1).div(s.m), s.px, s.py, R_PERP)]
	out.generic = [through(s, n, s.px.neg(), s.py).values, through(s, n, s.py, s.px).values, eq_values(s.form, n, s.c.neg())]
	var first := first_gradient("words" if rep != "equation" else rep, s)
	var extra := {
		"negative-reciprocal": method([first, "Flip it and change the sign: the new gradient is %s." % N(n), "Through P: c = %s − %s × %s = %s." % [D(s.py), PF(n), P(s.px), N(s.c)], fin(ans)], ans.values),
		"keep-coefficients": method(coef_steps(s, ans), ans.values),
		"point-gradient": method([first, "The new gradient is −1 ÷ %s = %s." % [PF(s.m), N(n)], "y − %s = %s(x − %s), so %s." % [P(s.py), Fmt.lead(n), P(s.px), yeq(n, s.c)], fin(ans)], ans.values),
	}
	out.methods = extra
	return out


func u_perpendicular_bisector(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: Q = s.n
	var ans := eq_answer(s, n, s.c)
	var out := {"asked": "Find the equation of the perpendicular bisector of AB." + form_ask(s.form), "answer": ans}
	show_ab(out, rep, s)
	out.wrongs = [through(s, s.m, s.mx, s.my, R_BISECT), through(s, n, s.ax, s.ay, R_BISECT)]
	out.generic = [through(s, s.m.neg(), s.mx, s.my).values, through(s, Q.new(1).div(s.m), s.mx, s.my).values, eq_values(s.form, n, s.c.neg())]
	var mid := "The midpoint is M = ((%s + %s)/2, (%s + %s)/2) = %s." % [D(s.ax), P(s.bx), D(s.ay), P(s.by), pt(s.mx, s.my)]
	var slope := "The gradient of AB is (%s − %s)/(%s − %s) = %s." % [D(s.by), P(s.ay), D(s.bx), P(s.ax), N(s.m)]
	var perp := "The perpendicular gradient is %s." % N(n)
	var thru := "Through M: c = %s − %s × %s = %s." % [D(s.my), PF(n), P(s.mx), N(s.c)]
	out.methods = {
		"two-point-formula": method([slope, perp, mid, thru, fin(ans)], ans.values),
		"point-gradient": method([mid, slope + " " + perp, "y − %s = %s(x − %s), so %s." % [P(s.my), Fmt.lead(n), P(s.mx), yeq(n, s.c)], fin(ans)], ans.values),
		"negative-reciprocal": method([slope, "Flip it and change the sign: %s." % N(n), mid, thru, fin(ans)], ans.values),
		"rotate-direction": method(["The step from A to B is (%s, %s). A quarter-turn makes it (%s, %s), a gradient of %s." % [D(s.dx), D(s.dy), D(s.dy.neg()), D(s.dx), N(n)], mid, thru, fin(ans)], ans.values),
		"average-coordinates": method(["Average each coordinate of A and B: M = %s." % pt(s.mx, s.my), slope + " " + perp, thru, fin(ans)], ans.values),
	}
	return out


func u_unknown_coordinate(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: Q = s.n
	var c: Q = s.c
	var hide: String = s.hide
	var on_axis := angle == "set-zero"
	var x: Q = Q.new(0) if on_axis and hide == "y" else (s.xi if on_axis else s.fx)
	var y: Q = n.mul(x).add(c) if hide == "y" else (Q.new(0) if on_axis else s.fy)
	var v: Q = y if hide == "y" else x
	var ans := number(s, v, "t = ")
	var q_text := "Q(%s, t)" % N(x) if hide == "y" else "Q(t, %s)" % N(y)
	var out := {"asked": "The point %s lies on the line. Find t." % q_text, "answer": ans}
	out.lines = ["L: " + given_new(s)] if rep == "equation" else ["A line L passes through %s and has gradient %s." % [pt(s.px, s.py), N(n)]]
	if hide == "y":
		out.wrongs = []
		out.generic = [{"v": n.mul(x).sub(c)}, {"v": c.sub(n.mul(x))}, {"v": x.div(n).add(c)}, {"v": n.mul(x)}, {"v": c}]
	else:
		out.wrongs = []
		out.generic = [{"v": y.add(c).div(n)}, {"v": n.mul(y).add(c)}, {"v": y.sub(c)}, {"v": v.neg()}, {"v": y.sub(c).mul(n)}]
	var the_line := "The line is %s." % yeq(n, c) if rep == "equation" else "c = %s − %s × %s = %s, so the line is %s." % [D(s.py), PF(n), P(s.px), N(c), yeq(n, c)]
	var sub: String
	if hide == "y":
		sub = "Put x = %s into it: t = %s × %s%s = %s." % [N(x), PF(n), P(x), Fmt.plus(c), N(v)]
	else:
		sub = "Put y = %s into it: %s = %sx%s, so t = %s." % [N(y), N(y), Fmt.lead(n), Fmt.plus(c), N(v)]
	out.methods = {
		"solve-for-c": method([the_line, sub, fin(ans)], ans.values),
		"set-zero": method([the_line, ("Q is on the y-axis, so x = 0. " if hide == "y" else "Q is on the x-axis, so y = 0. ") + sub if on_axis else sub, fin(ans)], ans.values),
	}
	return out


func u_general_form(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: Q = s.n
	var c: Q = s.c
	var ans := eq_answer(s, n, c, "gen")
	var a: int = s.ga
	var b: int = s.gb
	var d: int = s.gd
	var out := {"asked": "Write the line in the form ax + by + d = 0, where a, b and d are integers and a > 0.", "answer": ans}
	out.lines = [yeq(n, c)] if rep == "equation" else ["A line passes through %s and has gradient %s." % [pt(s.px, s.py), N(n)]]
	var scale: int = s.gb
	out.generic = [{"a": Q.new(a), "b": Q.new(b), "d": Q.new(-d)}, {"a": Q.new(a), "b": Q.new(-b), "d": Q.new(d)}, {"a": Q.new(a), "b": Q.new(-b), "d": Q.new(-d)}, {"a": Q.new(a), "b": Q.new(b), "d": Q.new(d + 1)}]
	var first := "The line is %s." % yeq(n, c) if rep == "equation" else "y − %s = %s(x − %s), so the line is %s." % [P(s.py), Fmt.lead(n), P(s.px), yeq(n, c)]
	out.methods = {"point-gradient": method([first, "Multiply every term by %s to clear the fractions: %sy = %s." % [N(scale), Fmt.lead(scale), Fmt.poly([n.mul(scale), c.mul(scale)])], "Move every term to one side, with a > 0.", fin(ans)], ans.values)}
	return out


# ── Intercepts and areas ─────────────────────────────────────

static func on_show(out: Dictionary, rep: String, s: Dictionary, shown: String) -> void:
	out.lines = [shown] if rep == "equation" else ["The graph shows the line %s." % shown]
	if rep == "graph":
		out.graph = plot([[s.n, s.c]], [])


## The equation is y = mx + c for read-c, ax + by + d = 0 for the cover-up.
func _form_for(s: Dictionary) -> String:
	match angle:
		"read-c":
			return "sl"
		"cover-up":
			return "gen"
	return s.gform


func u_intercepts_from_equation(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: Q = s.n
	var c: Q = s.c
	var x: Q = s.xi
	var a: int = s.ga
	var b: int = s.gb
	var d: int = s.gd
	var ans := Answer.make("points2", {"x1": x, "y1": Q.new(0), "x2": Q.new(0), "y2": c})
	ans.exact = true
	var form := _form_for(s)
	var shown := line_text(form, n, c)
	var out := {"asked": "Find where the line crosses the x-axis and the y-axis.", "answer": ans}
	on_show(out, rep, s, shown)
	var pp := func(x1: Q, y1: Q, x2: Q, y2: Q) -> Dictionary: return {"x1": x1, "y1": y1, "x2": x2, "y2": y2}
	var zero := Q.new(0)
	out.wrongs = [wrong(pp.call(x, zero, c, zero), R_YINT_POINT), wrong(pp.call(c, zero, zero, x), R_SWAP_INT)]
	if form == "gen":
		out.wrongs.append(wrong(pp.call(x, zero, zero, Q.new(d)), R_YINT_D))
	out.generic = [pp.call(x.neg(), zero, zero, c), pp.call(x, zero, zero, c.neg()), pp.call(x.neg(), zero, zero, c.neg())]
	var the_line := "The line is %s." % yeq(n, c)
	var fin_t := "So it crosses at %s." % Answer.text(ans)
	out.methods = {
		"set-zero": method(["Set x = 0: y = %s." % N(c), "Set y = 0: %s, so x = %s." % ["0 = %sx%s" % [Fmt.lead(n), Fmt.plus(c)], N(x)], fin_t], ans.values),
		"read-c": method([the_line + " Read c: the y-intercept is %s." % N(c), "Set y = 0: x = %s." % N(x), fin_t], ans.values),
		"cover-up": method(["Write the line as %sx%s = %s." % [Fmt.lead(a), Fmt.term(Q.new(b), 1, false, "y"), N(-d)], "Cover the y term: x = %s ÷ %s = %s. Cover the x term: y = %s ÷ %s = %s." % [N(-d), PF(a), N(x), N(-d), PF(b), N(c)], fin_t], ans.values),
	}
	return out


func u_triangle_area(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: Q = s.n
	var c: Q = s.c
	var x: Q = s.xi
	var a: int = s.ga
	var b: int = s.gb
	var d: int = s.gd
	var area: Q = s.area
	var ans := Answer.make("number", {"v": area}, {}, "Area = ")
	ans.exact = true
	var shown := line_text("gen" if angle == "cover-up" else s.gform, n, c)
	var out := {"asked": "Find the area of the triangle the line makes with the axes.", "answer": ans}
	on_show(out, rep, s, shown)
	out.wrongs = [wrong({"v": x.abs_q().mul(x.abs_q()).div(2)}, R_SWAP_INT)]
	out.generic = [{"v": area.mul(2)}, {"v": x.abs_q().add(c.abs_q()).div(2)}, {"v": area.div(2)}, {"v": x.abs_q().add(c.abs_q())}]
	var area_step := "The triangle has legs %s and %s, so its area is ½ × %s × %s = %s." % [N(x.abs_q()), N(c.abs_q()), N(x.abs_q()), N(c.abs_q()), N(area)]
	var fin_t := fin(ans)
	out.methods = {
		"set-zero": method(["Set x = 0: y = %s. Set y = 0: x = %s." % [N(c), N(x)], area_step, fin_t], ans.values),
		"cover-up": method(["Write the line as %sx%s = %s. Cover each term in turn: x = %s and y = %s." % [Fmt.lead(a), Fmt.term(Q.new(b), 1, false, "y"), N(-d), N(x), N(c)], area_step, fin_t], ans.values),
	}
	return out


# ── Two lines ────────────────────────────────────────────────

func u_check_perpendicular(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Q = s.n
	var rel: String = s.rel2
	var m2: Q
	match rel:
		"para":
			m2 = m
		"perp":
			m2 = Q.new(-1).div(m)
		"swap":
			m2 = Q.new(1).div(m)
		_:
			m2 = m.add(1) if not m.add(1).is_zero() else m.add(3)
	var c2: Q = s.c.add(3)
	var l1 := line_text("gen", m, s.c)
	var l2 := line_text(s.gform, m2, c2)
	var perp := "Perpendicular: the gradients multiply to −1"
	var para := "Parallel: the gradients are equal"
	var none := "Neither: the gradients are not equal and do not multiply to −1"
	var one := "Perpendicular: the gradients multiply to 1"
	var right: String = {"para": para, "perp": perp, "neither": none, "swap": none}[rel]
	var bad: Array = [tag(one, R_PRODUCT_1)] if rel == "swap" else []
	var plain: Array = [para, perp, none, one, "Neither: the lines have different y-intercepts"]
	var out := {"asked": "Are the two lines parallel, perpendicular or neither?", "lines": ["L₁: " + l1, "L₂: " + l2]}
	out.merge(pick(right, bad, plain))
	var g1 := "L₁ rearranges to %s, so its gradient is %s." % [yeq(m, s.c), N(m)]
	var g2 := "L₂ has gradient %s." % N(m2)
	var prod := m.mul(m2)
	var fin_t := "So: %s." % right
	var cf := LineConditionsSituation.gen(m, s.c)
	out.methods = {
		"rearrange-to-slope-intercept": method([g1, g2, fin_t], {"v": right}),
		"coefficient-shortcut": method(["For L₁, −a/b = −%s/%s = %s." % [N(cf[0]), P(cf[1]), N(m)], g2, fin_t], {"v": right}),
		"product-minus-one": method([g1 + " " + g2, "The product is %s × %s = %s." % [PF(m), PF(m2), N(prod)], fin_t], {"v": right}),
	}
	return out


func u_k_for_perpendicular(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Q = s.n
	var b2: int = s.k_b
	var para: bool = s.k_para
	# kx + b₂y + e = 0 has gradient −k/b₂.
	var k: Q = m.mul(b2).neg() if para else Q.new(b2).div(m)
	var wrong_k: Q = Q.new(b2).div(m).neg() if not para else m.mul(b2)
	var e: int = [3, -3, 5, -5][absi(b2) % 4]
	var word := "parallel" if para else "perpendicular"
	var ans := number(s, k, "k = ")
	var l2 := "kx%s%s = 0" % [Fmt.term(Q.new(b2), 1, false, "y"), Fmt.plus(e)]
	var out := {"asked": "Find k so that L₁ and L₂ are %s." % word, "answer": ans}
	out.lines = ["L₁: " + line_text("gen", m, s.c), "L₂: " + l2] if rep == "equation" else ["L₁ passes through %s and has gradient %s." % [pt(s.px, s.py), N(m)], "L₂: " + l2]
	out.wrongs = [wrong({"v": wrong_k}, R_PRODUCT_1)] if not para else []
	out.generic = [{"v": m.mul(b2)} if not para else {"v": Q.new(b2).div(m)}, {"v": Q.new(b2).div(m).neg()}, {"v": m.mul(b2).neg()}, {"v": k.neg()}, {"v": k.add(1)}]
	var g2 := "The gradient of L₂ is −k/%s." % PF(b2)
	var cond := ("So −k/%s = %s." % [PF(b2), N(m)]) if para else ("So %s × (−k/%s) = −1." % [PF(m), PF(b2)])
	var cf := LineConditionsSituation.gen(m, s.c)
	out.methods = {
		"coefficient-shortcut": method(["The gradient of L₁ is %s." % N(m), g2, cond, "So k = %s." % N(k), fin(ans)], ans.values),
		"product-minus-one": method(["The gradient of L₁ is %s and of L₂ is −k/%s." % [N(m), PF(b2)], cond if not para else "Equal gradients are the condition here, not a product: " + cond, "So k = %s." % N(k), fin(ans)], ans.values),
		"keep-coefficients": method(["Write L₁ as %s." % gtext(cf[0], cf[1], cf[2]), ("Parallel lines have a : b the same, so k/%s = %s/%s." % [PF(b2), N(cf[0]), PF(cf[1])]) if para else ("Perpendicular lines have aa′ + bb′ = 0, so %s·k + %s × %s = 0." % [PF(cf[0]), PF(cf[1]), PF(b2)]), "So k = %s." % N(k), fin(ans)], ans.values),
	}
	return out
