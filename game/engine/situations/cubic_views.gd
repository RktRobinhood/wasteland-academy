class_name CubicViews
extends RefCounted
## The views on the `cubic` situation: one builder per unknown of the four Topic 5
## types built on it (t5-differentiate-polynomial, t5-tangent-normal-equation,
## t5-tangent-condition and t5-stationary-points in curriculum/question-types.json).
##
## A builder returns the same fields as the quadratic builders (quadratic_views.gd):
## asked, lines, given, answer, wrongs, generic and methods. The equation
## representation uses function notation (f(x), f′(x)); the words representation says
## "the curve y = …", "dy/dx" and "the tangent is parallel to the line …".

const NEED := {
	"derivative": {},
	"derivative-from-fraction": {},
	"gradient-at-point": {"x0": true},
	"tangent-at-point": {"x0": true},
	"normal-at-point": {"x0": true},
	"read-from-tangent": {"x0": true},
	"x-for-gradient": {"gradient": true},
	"coefficient-from-tangent": {"x0": true, "hide": true},
	"stationary-points": {},
	"nature": {},
	"inflexion-point": {"even": true},
	"max-value": {},
}

const MAX := "local maximum"
const MIN := "local minimum"


func has(unknown: String) -> bool:
	return NEED.has(unknown)


func need(unknown: String, _rep: String) -> Dictionary:
	return NEED[unknown].duplicate()


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "wrongs", "generic"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "generic"] else null
	return out


# ── Helpers ──────────────────────────────────────────────────

static func N(v: Variant) -> String:
	return Fmt.num(v)


static func P(v: Variant) -> String:
	return Fmt.paren(v)


static func coeffs(s: Dictionary) -> Array:
	return [s.a, s.b, s.c, s.d]


static func d_coeffs(s: Dictionary) -> Array:
	return [s.a.mul(3), s.b.mul(2), s.c]


static func cubic(s: Dictionary) -> String:
	return Fmt.poly(coeffs(s))


static func deriv(s: Dictionary) -> String:
	return Fmt.poly(d_coeffs(s))


## The function as the representation shows it.
static func f_lines(rep: String, s: Dictionary) -> Array:
	if rep == "words":
		return ["A curve has equation y = %s." % cubic(s)]
	return ["f(x) = " + cubic(s)]


## "f′(x)" in function notation, "dy/dx" in words.
static func dname(rep: String) -> String:
	return "dy/dx" if rep == "words" else "f′(x)"


static func given(s: Dictionary) -> Dictionary:
	return {"f": [s.a.key(), s.b.key(), s.c.key(), s.d.key()]}


## Coefficients (highest power first) with x put in: "2(−1)³ − 3(−1)² + 4".
static func subst(cs: Array, x: Variant) -> String:
	var out := ""
	var power := cs.size() - 1
	for c in cs:
		var q := Q.of(c)
		if not q.is_zero():
			var sup: String = ["", "", "²", "³", "⁴"][power]
			var body := q.abs_q().text() if power == 0 else Fmt.lead(q.abs_q()) + "(%s)%s" % [N(x), sup]
			if out == "":
				out = ("−" if q.sign() < 0 else "") + body
			else:
				out += (" − " if q.sign() < 0 else " + ") + body
		power -= 1
	return out if out != "" else "0"


static func value(cs: Array, x: Variant) -> Q:
	var out := Q.new(0)
	for c in cs:
		out = out.mul(Q.of(x)).add(c)
	return out


## "f(2) = (2)³ − 3(2)² − 9(2) + 4 = −18", or in words
## "When x = 2, y = (2)³ − 3(2)² − 9(2) + 4 = −18". name is f, f′ or f″.
static func eval_step(name: String, cs: Array, x: Variant, rep: String = "equation") -> String:
	if rep == "words":
		var w: String = {"f": "y", "f′": "dy/dx", "f″": "d²y/dx²"}[name]
		return "When x = %s, %s = %s = %s" % [N(x), w, subst(cs, x), N(value(cs, x))]
	return "%s(%s) = %s = %s" % [name, N(x), subst(cs, x), N(value(cs, x))]


static func d2name(rep: String) -> String:
	return "d²y/dx²" if rep == "words" else "f″(x)"


## Term by term: "x³ → 3x²,  −3x² → −6x,  −9x → −9,  4 → 0".
static func power_rule_steps(cs: Array) -> Array:
	var parts: PackedStringArray = []
	var power := cs.size() - 1
	for c in cs:
		var q := Q.of(c)
		if not q.is_zero():
			var after := "0" if power == 0 else Fmt.term(q.mul(power), power - 1, true)
			parts.append("%s → %s" % [Fmt.term(q, power, true), after])
		power -= 1
	return ["Multiply each term by its power, then lower the power by 1. A constant gives 0.", ",  ".join(parts)]


## Solving 3ax² + 2bx + c = rhs by dividing by 3a and factorising. The roots are
## whole numbers r1 < r2 by construction.
static func solve_steps(s: Dictionary, rhs: Q, r1: Q, r2: Q) -> Array:
	var dc := d_coeffs(s)
	var st: Array = []
	if rhs.is_zero():
		st.append("%s = 0" % Fmt.poly(dc))
	else:
		st.append("%s = %s" % [Fmt.poly(dc), N(rhs)])
		st.append("%s = 0" % Fmt.poly([dc[0], dc[1], dc[2].sub(rhs)]))
	st.append("Divide by %s: %s = 0" % [N(dc[0]), Fmt.poly([1, r1.add(r2).neg(), r1.mul(r2)])])
	# x(x − 4), not (x − 4)x
	var fs := [Fmt.factor(r1), Fmt.factor(r2)] if not r2.is_zero() else [Fmt.factor(r2), Fmt.factor(r1)]
	st.append("%s%s = 0" % fs)
	st.append("x = %s or x = %s" % [N(r1), N(r2)])
	return st


## "y − (−18) = −9(x − 2)"
static func point_gradient(x0: Q, y0: Q, m: Q) -> String:
	return "y − %s = %s(x − %s)" % [P(y0), N(m) if m.is_int() else P(m), P(x0)]


static func wrong(values: Dictionary, ref: String = "") -> Dictionary:
	return {"values": values, "ref": ref}


static func exact(ans: Dictionary) -> Dictionary:
	ans.exact = true
	return ans


# ── t5-differentiate-polynomial ──────────────────────────────

func u_derivative(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var dc := d_coeffs(s)
	var ans := exact(Answer.make("deriv", {"u2": dc[0], "u1": dc[1], "u0": dc[2]}, {}, dname(rep) + " = "))
	var st := power_rule_steps(coeffs(s))
	st.append("So " + Answer.text(ans) + ".")
	return {
		"asked": "Find %s." % dname(rep),
		"lines": f_lines(rep, s), "given": given(s), "answer": ans,
		"wrongs": [
			wrong({"u2": s.a.sub(1), "u1": s.b.sub(1), "u0": s.c.sub(1)}, "SL5.3.power-rule#0"),
			wrong({"u2": dc[0], "u1": dc[1], "u0": s.c.add(s.d)}, "SL5.3.power-rule#2"),
		],
		"generic": [{"u2": s.a, "u1": s.b, "u0": s.c}, {"u2": dc[0], "u1": dc[1], "u0": Q.new(0)}, {"u2": dc[0], "u1": s.b, "u0": s.c}],
		"methods": {"power-rule": {"steps": st, "result": ans.values}},
	}


func u_derivative_from_fraction(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var dc := d_coeffs(s)
	var ans := exact(Answer.make("deriv", {"u2": dc[0], "u1": dc[1], "u0": dc[2]}))
	var top := Fmt.poly([s.a, s.b, s.c, s.d, 0])
	var st: Array = ["Divide every term of the top by x: f(x) = " + cubic(s)]
	st.append_array(power_rule_steps(coeffs(s)))
	st.append("So " + Answer.text(ans) + ".")
	return {
		"asked": "Find f′(x).",
		"lines": ["f(x) = (%s)/x,  x ≠ 0" % top], "given": given(s).merged({"fraction": true}), "answer": ans,
		"wrongs": [wrong({"u2": s.a.add(s.b).mul(3), "u1": s.c.mul(2), "u0": s.d}, "SL5.3.negative-powers#2")],
		"generic": [{"u2": s.a.mul(4), "u1": s.b.mul(3), "u0": s.c.mul(2)}, {"u2": s.a, "u1": s.b, "u0": s.c}, {"u2": dc[0], "u1": dc[1], "u0": s.c.add(s.d)}],
		"methods": {"split-fraction": {"steps": st, "result": ans.values}},
	}


func u_gradient_at_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var label := "dy/dx = " if rep == "words" else "f′(%s) = " % N(s.x0)
	var ans := Answer.make("number", {"v": s.m0}, {}, label)
	var asked := "Find f′(%s)." % N(s.x0)
	if rep == "words":
		asked = "Find the gradient of the curve at the point where x = %s." % N(s.x0)
	var st: Array = ["%s = %s" % [dname(rep), deriv(s)]]
	st.append(eval_step("f′", d_coeffs(s), s.x0, rep))
	st.append("So %s at x = %s." % [Answer.text(ans), N(s.x0)])
	var wrongs: Array = [wrong({"v": s.y0}, "SL5.3.gradient-at-point#0"), wrong({"v": Q.new(0)}, "SL5.3.gradient-at-point#1")]
	if s.x0.sign() < 0:
		wrongs.append(wrong({"v": s.a.mul(3).mul(s.x0.sq()).neg().add(s.b.mul(2).mul(s.x0)).add(s.c)}, "SL5.3.gradient-at-point#2"))
	return {
		"asked": asked, "lines": f_lines(rep, s), "given": given(s).merged({"x0": s.x0.key()}), "answer": ans,
		"wrongs": wrongs,
		"generic": [{"v": CubicSituation.f1(s, s.x0.neg())}, {"v": CubicSituation.f2(s, s.x0)}, {"v": value([s.a, s.b, s.c], s.x0)}],
		"methods": {"differentiate-substitute": {"steps": st, "result": ans.values}},
	}


# ── t5-tangent-normal-equation ───────────────────────────────

## The point of contact and the gradient there, the start of every tangent and normal.
static func contact_steps(rep: String, s: Dictionary) -> Array:
	return [
		eval_step("f", coeffs(s), s.x0, rep) + ", so the point is " + Fmt.point(s.x0, s.y0),
		"%s = %s" % [dname(rep), deriv(s)],
		eval_step("f′", d_coeffs(s), s.x0, rep) + ", the gradient of the tangent",
	]


func u_tangent_at_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Q = s.m0
	var c: Q = s.y0.sub(m.mul(s.x0))
	var ans := Answer.make("line", {"m": m, "c": c})
	var asked := "Find the equation of the tangent to the graph of f at x = %s. Give it in the form y = mx + c." % N(s.x0)
	if rep == "words":
		asked = "Find the equation of the tangent to the curve at the point where x = %s, in the form y = mx + c." % N(s.x0)
	var pg := contact_steps(rep, s)
	pg.append(point_gradient(s.x0, s.y0, m))
	pg.append("So the tangent is %s." % Answer.text(ans))
	var fc := contact_steps(rep, s)
	fc.append("Put the point into y = %sx + c: %s = %s × %s + c" % [Fmt.lead(m) if m.is_int() else P(m), N(s.y0), P(m), P(s.x0)])
	fc.append("c = %s − %s = %s" % [N(s.y0), P(m.mul(s.x0)), N(c)])
	fc.append("So the tangent is %s." % Answer.text(ans))
	var mn := Q.new(-1).div(m)
	return {
		"asked": asked, "lines": f_lines(rep, s), "given": given(s).merged({"x0": s.x0.key()}), "answer": ans,
		"wrongs": [
			wrong({"m": m, "c": m.sub(m.mul(s.x0))}, "SL5.4.tangent-equation#1"),
			wrong({"m": mn, "c": s.y0.sub(mn.mul(s.x0))}, "SL5.4.tangent-equation#2"),
		],
		"generic": [{"m": m, "c": s.y0.add(m.mul(s.x0))}, {"m": m, "c": s.y0}, {"m": s.y0, "c": c}],
		"methods": {
			"point-gradient": {"steps": pg, "result": ans.values},
			"find-c": {"steps": fc, "result": ans.values},
		},
	}


func u_normal_at_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Q = s.m0
	var mn := Q.new(-1).div(m)
	var c: Q = s.y0.sub(mn.mul(s.x0))
	var ans := Answer.make("line", {"m": mn, "c": c})
	var asked := "Find the equation of the normal to the graph of f at x = %s. Give it in the form y = mx + c." % N(s.x0)
	if rep == "words":
		asked = "Find the equation of the normal to the curve at the point where x = %s, in the form y = mx + c." % N(s.x0)
	var nr := contact_steps(rep, s)
	if m.is_int() and m.sign() > 0:
		nr.append("The normal is perpendicular to the tangent, so its gradient is −1/%s" % N(m))
	else:
		nr.append("The normal is perpendicular to the tangent, so its gradient is −1/%s = %s" % [P(m), N(mn)])
	nr.append(point_gradient(s.x0, s.y0, mn))
	nr.append("So the normal is %s." % Answer.text(ans))
	var rf := contact_steps(rep, s)
	var yf := Fmt.factor(s.y0).replace("x", "y")
	if yf == "y":
		yf = "(y)"
	rf.append("The normal through (x₀, y₀) with tangent gradient m is (x − x₀) + m(y − y₀) = 0:")
	rf.append("%s + %s%s = 0" % [Fmt.factor(s.x0) if not s.x0.is_zero() else "x", P(m), yf])
	rf.append("%s%s = %s" % [P(m), yf, Fmt.poly([-1, s.x0])])
	rf.append("y%s = %s" % [Fmt.plus(s.y0.neg()) if not s.y0.is_zero() else "", Fmt.poly([mn, s.x0.div(m)])])
	rf.append("So the normal is %s." % Answer.text(ans))
	var ct: Q = s.y0.sub(m.mul(s.x0))
	return {
		"asked": asked, "lines": f_lines(rep, s), "given": given(s).merged({"x0": s.x0.key()}), "answer": ans,
		"wrongs": [
			wrong({"m": m.neg(), "c": s.y0.add(m.mul(s.x0))}, "SL5.4.normal-equation#0"),
			wrong({"m": Q.new(1).div(m), "c": s.y0.sub(s.x0.div(m))}, "SL5.4.normal-equation#0"),
			wrong({"m": mn, "c": ct}, "SL5.4.normal-equation#1"),
		],
		"generic": [{"m": m, "c": ct}, {"m": mn, "c": s.y0}],
		"methods": {
			"negative-reciprocal": {"steps": nr, "result": ans.values},
			"rearranged-form": {"steps": rf, "result": ans.values},
		},
	}


func u_read_from_tangent(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Q = s.m0
	var c: Q = s.y0.sub(m.mul(s.x0))
	var line := "y = " + Fmt.poly([m, c])
	var ans := Answer.make("tangent_read", {"m": m, "y": s.y0}, {"x0": s.x0})
	var lines: Array = ["L: " + line]
	var asked := "The line L is the tangent to the graph of y = f(x) at x = %s. Write down f′(%s) and find f(%s)." % [N(s.x0), N(s.x0), N(s.x0)]
	if rep == "words":
		lines = ["The tangent to the curve y = f(x) at the point where x = %s has equation %s." % [N(s.x0), line]]
		asked = "Write down the gradient of the curve at that point, f′(%s), and find its y-coordinate, f(%s)." % [N(s.x0), N(s.x0)]
	var st: Array = [
		"The tangent has the curve's gradient at the point of contact, so f′(%s) = %s, the gradient of %s." % [N(s.x0), N(m), "the tangent" if rep == "words" else "L"],
		"The tangent touches the curve at x = %s, so f(%s) is the tangent's y-value there:" % [N(s.x0), N(s.x0)],
		"f(%s) = %s = %s" % [N(s.x0), subst([m, c], s.x0), N(s.y0)],
		"So " + Answer.text(ans) + ".",
	]
	return {
		"asked": asked, "lines": lines, "given": {"x0": s.x0.key(), "line": [m.key(), c.key()], "f": given(s).f}, "answer": ans,
		"wrongs": [wrong({"m": m, "y": c}, "SL5.4.read-from-tangent#0"), wrong({"m": s.y0, "y": m}, "SL5.4.read-from-tangent#1")],
		"generic": [{"m": c, "y": s.y0}, {"m": m, "y": m.add(c)}, {"m": m.neg(), "y": s.y0}],
		"methods": {"substitute-point": {"steps": st, "result": ans.values}},
	}


# ── t5-tangent-condition ─────────────────────────────────────

func u_x_for_gradient(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var g: Q = s.g
	var ans := Answer.make("roots", {"r1": s.r1, "r2": s.r2})
	var asked := "Find the values of x for which f′(x) = %s." % N(g)
	var lines := f_lines(rep, s)
	var given_q := given(s).merged({"g": g.key()})
	var why := "The gradient of the graph at x is f′(x), so solve f′(x) = %s." % N(g)
	if rep == "words":
		var k := Q.new(rng.int_in(1, 9) * (1 if rng.chance(0.5) else -1))
		var line := "y = " + Fmt.poly([g, k])
		asked = "Find the x-coordinates of the points on the curve where the tangent is parallel to the line %s." % line
		given_q.line = [g.key(), k.key()]
		why = "Parallel lines have equal gradients, so the tangent's gradient is %s, the gradient of %s." % [N(g), line]
	var sf: Array = ["%s = %s" % [dname(rep), deriv(s)]]
	if rep == "words":
		sf.append("The gradient of the curve is dy/dx, so solve dy/dx = %s." % N(g))
	else:
		sf.append(why)
	sf.append_array(solve_steps(s, g, s.r1, s.r2))
	sf.append("So " + Answer.text(ans) + ".")
	var mg: Array = [why, "%s = %s" % [dname(rep), deriv(s)]]
	mg.append_array(solve_steps(s, g, s.r1, s.r2))
	mg.append("So " + Answer.text(ans) + ".")
	return {
		"asked": asked, "lines": lines, "given": given_q, "answer": ans,
		"generic": [{"r1": s.p, "r2": s.q}, {"r1": s.r1.neg(), "r2": s.r2.neg()}, {"r1": s.r1, "r2": s.r2.neg()}, {"r1": s.r1.neg(), "r2": s.r2}],
		"methods": {
			"solve-f-prime": {"steps": sf, "result": ans.values},
			"match-gradients": {"steps": mg, "result": ans.values},
		},
	}


## f(x) with the hidden coefficient written as k: "x³ + kx² − 9x + 4".
static func with_k(s: Dictionary) -> String:
	var out := Fmt.term(s.a, 3, true)
	out += " + kx²" if s.hidden == "b" else Fmt.term(s.b, 2, false) if not s.b.is_zero() else ""
	out += " + kx" if s.hidden == "c" else Fmt.term(s.c, 1, false) if not s.c.is_zero() else ""
	if not s.d.is_zero():
		out += Fmt.term(s.d, 0, false)
	return out


## coef·k + rest: "4k + 3", "−k − 6", "k".
static func lin_k(coef: Q, rest: Q) -> String:
	var out := Fmt.lead(coef) + "k"
	return out + (Fmt.plus(rest) if not rest.is_zero() else "")


func u_coefficient_from_tangent(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var g: Q = s.m0
	var x0: Q = s.x0
	var hid: String = s.hidden
	var k: Q = s[hid]
	var ans := exact(Answer.make("number", {"v": k}, {}, "k = "))
	var lines: Array = ["f(x) = " + with_k(s)]
	var asked := "The tangent to the graph of f at x = %s has gradient %s. Find k." % [N(x0), N(g)]
	var given_q := {"f": given(s).f, "hidden": hid, "x0": x0.key(), "g": g.key()}
	var cond := "The gradient of the tangent at x = %s is f′(%s), so f′(%s) = %s." % [N(x0), N(x0), N(x0), N(g)]
	if rep == "words":
		var tc: Q = s.y0.sub(g.mul(x0))
		var lc := Q.new(rng.int_in(1, 9) * (1 if rng.chance(0.5) else -1))
		if lc.eq(tc):
			lc = lc.add(1) if not lc.add(1).is_zero() else lc.add(2)
		var line := "y = " + Fmt.poly([g, lc])
		lines = ["A curve has equation y = %s, where k is a constant." % with_k(s)]
		asked = "The tangent to the curve at the point where x = %s is parallel to the line %s. Find k." % [N(x0), line]
		given_q.line = [g.key(), lc.key()]
		cond = "Parallel lines have equal gradients, so dy/dx = %s at x = %s." % [N(g), N(x0)]
	# f′(x) with k, and f′(x0) as coef·k + rest.
	var d_k := ""
	var coef: Q
	var rest: Q
	var dname_ := dname(rep)
	if hid == "b":
		d_k = Fmt.term(s.a.mul(3), 2, true) + " + 2kx" + (Fmt.term(s.c, 0, false) if not s.c.is_zero() else "")
		coef = x0.mul(2)
		rest = s.a.mul(3).mul(x0.sq()).add(s.c)
	else:
		d_k = Fmt.poly([s.a.mul(3), s.b.mul(2), 0]) + " + k"
		coef = Q.new(1)
		rest = s.a.mul(3).mul(x0.sq()).add(s.b.mul(2).mul(x0))
	var at := "%s(%s)" % ["f′" if rep != "words" else "dy/dx at x = ", N(x0)]
	if rep == "words":
		at = "At x = %s, dy/dx" % N(x0)
	var st: Array = [
		"%s = %s" % [dname_, d_k],
		cond,
		"%s = %s" % [at, lin_k(coef, rest)],
		"%s = %s" % [lin_k(coef, rest), N(g)],
	]
	if not coef.eq(1):
		st.append("%sk = %s" % [Fmt.lead(coef), N(g.sub(rest))])
	st.append("So " + Answer.text(ans) + ".")
	var wrongs: Array = []
	# Using f(x0) = g instead of f′(x0) = g.
	var pw := 2 if hid == "b" else 1
	var xp := x0.sq() if pw == 2 else x0
	if not xp.is_zero():
		var others: Q = s.a.mul(x0.sq().mul(x0)).add(s.d)
		others = others.add(s.c.mul(x0)) if hid == "b" else others.add(s.b.mul(x0.sq()))
		wrongs.append(wrong({"v": g.sub(others).div(xp)}, "SL5.3.point-with-given-gradient#0"))
	var generic: Array = []
	if hid == "b":
		generic.append({"v": g.sub(rest).div(x0)})
	else:
		generic.append({"v": g.sub(s.a.mul(3).mul(x0.sq())).sub(s.b.mul(x0))})
	generic.append({"v": k.neg()})
	generic.append({"v": g.sub(rest)})
	return {
		"asked": asked, "lines": lines, "given": given_q, "answer": ans,
		"wrongs": wrongs, "generic": generic,
		"methods": {"gradient-match": {"steps": st, "result": ans.values}},
	}


# ── t5-stationary-points ─────────────────────────────────────

## f′ = 0 and the y-coordinates: the start of every stationary-point question.
static func stationary_steps(rep: String, s: Dictionary) -> Array:
	var st: Array = ["%s = %s" % [dname(rep), deriv(s)], "Stationary points are where the gradient is 0:"]
	st.append_array(solve_steps(s, Q.new(0), s.p, s.q))
	return st


func u_stationary_points(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("points2", {"x1": s.p, "y1": s.fp, "x2": s.q, "y2": s.fq})
	var asked := "Find the coordinates of the stationary points of the graph of f."
	if rep == "words":
		asked = "Find the coordinates of the two stationary points on the curve."
	var st := stationary_steps(rep, s)
	st.append(eval_step("f", coeffs(s), s.p, rep))
	st.append(eval_step("f", coeffs(s), s.q, rep))
	st.append("So the stationary points are " + Answer.text(ans) + ".")
	return {
		"asked": asked, "lines": f_lines(rep, s), "given": given(s), "answer": ans,
		"wrongs": [wrong({"x1": s.p, "y1": Q.new(0), "x2": s.q, "y2": Q.new(0)}, "SL5.8.find-stationary-points#2")],
		"generic": [{"x1": s.p, "y1": s.fq, "x2": s.q, "y2": s.fp}, {"x1": s.p.neg(), "y1": s.fp, "x2": s.q.neg(), "y2": s.fq},
			{"x1": s.p, "y1": s.fp.neg(), "x2": s.q, "y2": s.fq.neg()}],
		"methods": {"solve-f-prime-zero": {"steps": st, "result": ans.values}},
	}


func u_nature(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var up: bool = s.a.sign() > 0
	var k1 := MAX if up else MIN
	var k2 := MIN if up else MAX
	var ans := Answer.make("natures", {"k1": k1, "k2": k2}, {"p": s.p, "q": s.q})
	var lines := f_lines(rep, s)
	var asked := "The graph of f has stationary points at x = %s and x = %s. Determine the nature of each." % [N(s.p), N(s.q)]
	if rep == "words":
		asked = "The curve has stationary points where x = %s and x = %s. Is each one a local maximum or a local minimum?" % [N(s.p), N(s.q)]
	var last := "So " + Answer.text(ans) + "."
	var sd: Array = ["%s = %s" % [dname(rep), deriv(s)], "%s = %s" % [d2name(rep), Fmt.poly([s.a.mul(6), s.b.mul(2)])]]
	for pair in [[s.p, k1], [s.q, k2]]:
		var v := CubicSituation.f2(s, pair[0])
		sd.append("%s %s 0, so x = %s is a %s" % [eval_step("f″", [s.a.mul(6), s.b.mul(2)], pair[0], rep), "<" if v.sign() < 0 else ">", N(pair[0]), pair[1]])
	sd.append(last)
	var mid: Q = s.p.add(s.q).div(2)
	var tests: Array = [s.p.sub(1), mid, s.q.add(1)]
	var sign := func(x: Q) -> String: return "+" if CubicSituation.f1(s, x).sign() > 0 else "−"
	var ft: Array = ["%s = %s" % [dname(rep), deriv(s)], "Test the sign of the gradient either side of each point:"]
	for x in tests:
		var v := CubicSituation.f1(s, x)
		ft.append("%s, %s" % [eval_step("f′", d_coeffs(s), x, rep), "positive" if v.sign() > 0 else "negative"])
	ft.append("At x = %s the gradient goes %s to %s: a %s" % [N(s.p), sign.call(tests[0]), sign.call(tests[1]), k1])
	ft.append("At x = %s the gradient goes %s to %s: a %s" % [N(s.q), sign.call(tests[1]), sign.call(tests[2]), k2])
	ft.append(last)
	var cs: Array = []
	if up:
		cs.append("The x³ coefficient is %s, which is positive, so the graph rises, falls, then rises again." % N(s.a))
		cs.append("So the left stationary point is a local maximum and the right one a local minimum.")
	else:
		cs.append("The x³ coefficient is %s, which is negative, so the graph falls, rises, then falls again." % N(s.a))
		cs.append("So the left stationary point is a local minimum and the right one a local maximum.")
	cs.append("x = %s is on the left and x = %s on the right." % [N(s.p), N(s.q)])
	cs.append(last)
	return {
		"asked": asked, "lines": lines, "given": given(s).merged({"xs": [s.p.key(), s.q.key()]}), "answer": ans,
		"wrongs": [wrong({"k1": k2, "k2": k1}, "SL5.8.classify-stationary-points#0")],
		"generic": [{"k1": MAX, "k2": MAX}, {"k1": MIN, "k2": MIN}],
		"methods": {
			"second-derivative-test": {"steps": sd, "result": ans.values},
			"first-derivative-sign-table": {"steps": ft, "result": ans.values},
			"cubic-shape": {"steps": cs, "result": ans.values},
		},
	}


func u_inflexion_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("point", {"x": s.xi, "y": s.yi})
	var asked := "Find the coordinates of the point of inflexion of the graph of f."
	if rep == "words":
		asked = "Find the coordinates of the point of inflexion on the curve."
	var f2c: Array = [s.a.mul(6), s.b.mul(2)]
	var sc: Array = ["%s = %s" % [dname(rep), deriv(s)], "%s = %s" % [d2name(rep), Fmt.poly(f2c)]]
	sc.append("%s = 0: %s = 0, so x = %s" % [d2name(rep), Fmt.poly(f2c), N(s.xi)])
	sc.append("%s is a straight line with gradient %s, not 0, so it changes sign at x = %s." % [d2name(rep).trim_suffix("(x)"), N(f2c[0]), N(s.xi)])
	sc.append(eval_step("f", coeffs(s), s.xi, rep))
	sc.append("So the point of inflexion is " + Answer.text(ans) + ".")
	var cm := stationary_steps(rep, s)
	cm.append("A cubic's point of inflexion is midway between its stationary points: x = (%s + %s)/2 = %s" % [N(s.p), P(s.q), N(s.xi)])
	cm.append(eval_step("f", coeffs(s), s.xi, rep))
	cm.append("So the point of inflexion is " + Answer.text(ans) + ".")
	return {
		"asked": asked, "lines": f_lines(rep, s), "given": given(s), "answer": ans,
		"generic": [{"x": s.xi, "y": CubicSituation.f1(s, s.xi)}, {"x": s.xi, "y": Q.new(0)}, {"x": s.xi, "y": s.d},
			{"x": s.xi.neg(), "y": CubicSituation.f(s, s.xi.neg())}],
		"methods": {
			"second-derivative-sign-change": {"steps": sc, "result": ans.values},
			"cubic-midpoint": {"steps": cm, "result": ans.values},
		},
	}


func u_max_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var up: bool = s.a.sign() > 0
	var xm: Q = s.p if up else s.q
	var xn: Q = s.q if up else s.p
	var ym := CubicSituation.f(s, xm)
	var label := "y = " if rep == "words" else "local maximum = "
	var ans := Answer.make("number", {"v": ym}, {}, label)
	var asked := "Find the local maximum value of f."
	if rep == "words":
		asked = "Find the y-coordinate of the local maximum point on the curve."
	var st := stationary_steps(rep, s)
	var f2c: Array = [s.a.mul(6), s.b.mul(2)]
	st.append("%s = %s" % [d2name(rep), Fmt.poly(f2c)])
	st.append("%s < 0, so x = %s is the local maximum" % [eval_step("f″", f2c, xm, rep), N(xm)])
	st.append(eval_step("f", coeffs(s), xm, rep))
	st.append("So %s." % Answer.text(ans))
	return {
		"asked": asked, "lines": f_lines(rep, s), "given": given(s), "answer": ans,
		"wrongs": [wrong({"v": xm}, "SL5.8.optimise-given-function#0")],
		"generic": [{"v": CubicSituation.f(s, xn)}, {"v": s.d}, {"v": ym.neg()}],
		"methods": {"derivative-zero-and-test": {"steps": st, "result": ans.values}},
	}
