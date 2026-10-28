class_name QuadraticEquationViews
extends RefCounted
## The views on the `quadratic-equation` situation: one builder per unknown of
## fn-solve-quadratic (FAL-414). Builders return what QuadraticViews' builders return
## (see quadratic_views.gd). Exponentials are written b^x, as on a GDC.

const NEED := {
	"solve-factorisable": {"wrapper": "plain"},
	"solve-no-constant": {"wrapper": "noconst"},
	"solve-surd": {"wrapper": "surd"},
	"solve-in-context": {"wrapper": "context"},
	"solve-hidden-exponential": {"wrapper": "exp"},
	"choose-substitution": {"wrapper": "exp"},
	"solve-hidden-reciprocal": {"wrapper": "recip"},
	"solve-hidden-log": {"wrapper": "log"},
	"equation-from-roots": {"wrapper": "fromroots"},
	"coefficient-from-root": {"wrapper": "coef"},
}


func has(unknown: String) -> bool:
	return NEED.has(unknown)


func need(unknown: String, rep: String) -> Dictionary:
	var n: Dictionary = NEED[unknown].duplicate()
	if rep == "graph":
		n.graph = true
	return n


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "wrongs", "generic"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "generic"] else null
	return out


static func N(v: Variant) -> String:
	return Fmt.num(v)


static func wrong(values: Dictionary, ref: String = "") -> Dictionary:
	return {"values": values, "ref": ref}


## (x − r), with "x" for r = 0.
static func fx(r: Q) -> String:
	return Fmt.factor(r)


static func roots_ans(r1: Q, r2: Q) -> Dictionary:
	return Answer.make("roots", {"r1": r1, "r2": r2})


## b^x written for a GDC: "2^x", and b^(2x) as "4^x" style is avoided: "2^(2x)".
static func bx(b: Q) -> String:
	return "%s^x" % N(b)


static func exp_line(s: Dictionary) -> String:
	var mid := ""
	if not s.B.is_zero():
		mid = (" − " if s.B.sign() < 0 else " + ") + ("" if s.B.abs_q().eq(1) else N(s.B.abs_q()) + " × ") + bx(s.base)
	return "%s^(2x)%s%s = 0" % [N(s.base), mid, Fmt.plus(s.C)]


# ── fn-solve-quadratic ───────────────────────────────────────

func u_solve_factorisable(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := roots_ans(s.p, s.q)
	var final := "So " + Answer.text(ans) + "."
	var eq := Fmt.general(s.a, s.b, s.c) + " = 0"
	var out := {"answer": ans, "given": {"a": s.a.key(), "b": s.b.key(), "c": s.c.key()}, "asked": "Solve the equation.", "lines": [eq]}
	if rep == "graph":
		out.graph = QuadraticViews.graph(s, [])
		out.lines = [eq, "The graph of y = %s is shown." % Fmt.general(s.a, s.b, s.c)]
	var fs := QuadraticViews.formula_steps(s.a, s.b, s.c)
	var res: Dictionary = ans.values
	out.wrongs = [wrong({"r1": s.p.neg(), "r2": s.q.neg()}, "SL2.7.solve-equation#1")]
	out.generic = [{"r1": s.p, "r2": s.q.neg()}, {"r1": s.p.neg(), "r2": s.q}, {"r1": s.p.mul(s.a), "r2": s.q.mul(s.a)}, {"r1": s.p.add(1), "r2": s.q.add(1)}]
	out.methods = {
		"factorise": {"result": res, "steps": ["Factorise: " + Fmt.factorised(s.a, s.p, s.q) + " = 0",
			"A product is 0 when a factor is 0: x = %s or x = %s" % [N(s.p), N(s.q)], final]},
		"quadratic-formula": {"result": res, "steps": [fs.steps[0], fs.steps[1], fs.steps[2], final]},
	}
	return out


func u_solve_no_constant(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := roots_ans(s.r1, s.r2)
	var final := "So " + Answer.text(ans) + "."
	var eq := ""
	var st: Array = []
	if s.form == "zero":
		eq = Fmt.poly([s.a, s.b, 0]) + " = 0"
	else:
		eq = Fmt.poly([s.a, 0, 0]) + " = " + Fmt.poly([s.b.neg(), 0])
		st.append("Bring everything to one side (don't divide by x, or the root x = 0 is lost): %s = 0" % Fmt.poly([s.a, s.b, 0]))
	st.append("Take out x: x(%s) = 0" % Fmt.poly([s.a, s.b]))
	st.append("x = 0 or %s = 0, so x = %s" % [Fmt.poly([s.a, s.b]), N(s.r2)])
	st.append(final)
	return {
		"asked": "Solve the equation.", "lines": [eq], "given": {"a": s.a.key(), "b": s.b.key(), "form": s.form}, "answer": ans,
		"generic": [{"r1": Q.new(0), "r2": s.r2.neg()}, {"r1": s.r2, "r2": s.r2.neg()}, {"r1": Q.new(0), "r2": s.b}, {"r1": Q.new(0), "r2": s.a.div(s.b).neg()}],
		"methods": {"factorise": {"result": ans.values, "steps": st}},
	}


func u_solve_surd(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("surd_roots", {"h": s.h, "d": s.surd})
	var final := "So " + Answer.text(ans) + "."
	var a: Q = s.a
	var disc: Q = s.disc
	var two_a := a.mul(2)
	var res: Dictionary = ans.values
	return {
		"asked": "Solve the equation, giving the exact roots in the form x = h ± √d.", "lines": [Fmt.general(a, s.b, s.c) + " = 0"],
		"given": {"a": a.key(), "b": s.b.key(), "c": s.c.key()}, "answer": ans,
		"generic": [{"h": s.h.neg(), "d": s.surd}, {"h": s.h, "d": disc}, {"h": s.h, "d": s.surd.mul(4)}, {"h": s.h.mul(2), "d": s.surd}],
		"methods": {
			"quadratic-formula": {"result": res, "steps": [
				"Δ = b² − 4ac = %s² − 4 × %s × %s = %s" % [Fmt.paren(s.b), Fmt.paren(a), Fmt.paren(s.c), N(disc)],
				"√%s = √(%s × %s) = %s√%s" % [N(disc), N(two_a.sq()), N(s.surd), N(two_a.abs_q()) if not two_a.abs_q().eq(1) else "", N(s.surd)],
				"x = (%s ± %s√%s)/%s = %s ± √%s" % [N(s.b.neg()), N(two_a.abs_q()) if not two_a.abs_q().eq(1) else "", N(s.surd), Fmt.paren(two_a), N(s.h), N(s.surd)],
				final]},
			"complete-square": {"result": res, "steps": [
				"Complete the square: %s = 0" % Fmt.vertex(a, s.h, s.k),
				"%s² = %s" % [Fmt.factor(s.h), N(s.surd)],
				"x%s = ±√%s" % [Fmt.plus(s.h.neg()), N(s.surd)], final]},
		},
	}


func u_solve_in_context(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var unit := " m" if s.kind == "rect" else " cm"
	var line := ""
	var eq := Fmt.general(1, s.B, s.C) + " = 0"
	var setup := ""
	if s.kind == "rect":
		line = "A rectangular yard is x m wide and (x + %s) m long. Its area is %s m²." % [N(s.d), N(s.area)]
		setup = "Area: x(x + %s) = %s, so %s" % [N(s.d), N(s.area), eq]
	else:
		line = "A right-angled triangle has shorter sides x cm and (x + %s) cm, and its hypotenuse is (x + %s) cm." % [N(s.d), N(s.e)]
		setup = "Pythagoras: x² + (x + %s)² = (x + %s)², which simplifies to %s" % [N(s.d), N(s.e), eq]
	var given := {"kind": s.kind, "d": s.d.key(), "paper": s.paper}
	if s.kind == "rect":
		given.area = s.area.key()
	else:
		given.e = s.e.key()
	if s.paper == 2:
		var x: Q = s.x
		var ans := Answer.make("measure", {"v": x}, {}, "x = ", unit)
		var final := "So " + Answer.text(ans) + "."
		var disc: Q = s.B.sq().sub(s.C.mul(4))
		var res: Dictionary = ans.values
		var other := Fmt.sf(s.xneg)
		return {
			"asked": "Find x, correct to 3 significant figures.", "lines": [line], "given": given, "answer": ans,
			"wrongs": [wrong({"v": x.add(s.d)}, "SL2.7.solve-equation#1")],
			"generic": [{"v": x.mul(2)}, {"v": x.add(1)}, {"v": Q.new(int(round(sqrt(float(s.area.n))) * SCALE_I), SCALE_I)}, {"v": x.div(2)}],
			"methods": {
				"factorise": {"result": res, "steps": [setup,
					"Δ = %s is not a square number, so there are no whole-number factors: factorising fails here." % N(disc),
					"Use the formula instead: x = (−%s ± √%s)/2 = %s or %s; a length can't be negative." % [N(s.B), N(disc), Fmt.sf(x), other], final]},
				"quadratic-formula": {"result": res, "steps": [setup,
					"x = (−%s ± √%s)/2" % [N(s.B), N(disc)],
					"x = %s or x = %s; a length can't be negative." % [Fmt.sf(x), other], final]},
				"gdc-solver": {"result": res, "steps": [setup,
					"The GDC's polynomial solver gives x = %s and x = %s; a length can't be negative." % [Fmt.sf(x), other], final]},
			},
		}
	var ans := Answer.make("number", {"v": s.r1}, {}, "x = ", unit)
	ans.exact = true
	var final := "So " + Answer.text(ans) + "."
	var res: Dictionary = ans.values
	var reject := "x = %s or x = %s; a length can't be negative, so reject x = %s." % [N(s.r1), N(s.r2), N(s.r2)]
	var fs := QuadraticViews.formula_steps(Q.new(1), s.B, s.C)
	return {
		"asked": "Find x.", "lines": [line], "given": given, "answer": ans,
		"wrongs": [wrong({"v": s.r2.neg()}, "SL2.7.solve-equation#1")],
		"generic": [{"v": s.r2}, {"v": s.r1.mul(2)}, {"v": s.r1.add(1)}, {"v": s.r1.sub(1)}],
		"methods": {
			"factorise": {"result": res, "steps": [setup, "(x%s)(x%s) = 0" % [Fmt.plus(s.r1.neg()), Fmt.plus(s.r2.neg())], reject, final]},
			"quadratic-formula": {"result": res, "steps": [setup, fs.steps[0] + ", " + fs.steps[1], reject, final]},
			"gdc-solver": {"result": res, "steps": [setup, "The GDC's polynomial solver gives " + reject, final]},
		},
	}


const SCALE_I := 1000000000


func u_solve_hidden_exponential(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("number", {"v": s.n}, {}, "x = ")
	var final := "So " + Answer.text(ans) + "."
	var res: Dictionary = ans.values
	var wrongs: Array = [wrong({"v": s.j.neg()}, "SL2.7.hidden-quadratic#1")]
	if not s.u1.eq(s.n):
		wrongs.push_front(wrong({"v": s.u1}, "SL2.7.hidden-quadratic#0"))
	return {
		"asked": "Solve the equation.", "lines": [exp_line(s)],
		"given": {"base": s.base.key(), "B": s.B.key(), "C": s.C.key()}, "answer": ans, "wrongs": wrongs,
		"generic": [{"v": s.u2}, {"v": s.n.add(1)}, {"v": s.j}, {"v": s.n.neg()}],
		"methods": {
			"substitution": {"result": res, "steps": [
				"%s^(2x) = (%s)², so let u = %s: %s = 0" % [N(s.base), bx(s.base), bx(s.base), Fmt.poly([1, s.B, s.C]).replace("x", "u")],
				"(u%s)(u%s) = 0, so u = %s or u = %s" % [Fmt.plus(s.u1.neg()), Fmt.plus(s.u2.neg()), N(s.u1), N(s.u2)],
				"%s = %s has no solution, since %s > 0 for every x; %s = %s gives x = %s" % [bx(s.base), N(s.u2), bx(s.base), bx(s.base), N(s.u1), N(s.n)],
				final]},
			"gdc-intersect": {"result": res, "steps": [
				"Graph y = %s on the GDC: it crosses the x-axis once." % exp_line(s).trim_suffix(" = 0"),
				"The zero is at x = %s. Check: %s^(%s) = %s, and u = %s is a root of the quadratic in u." % [N(s.n), N(s.base), N(s.n), N(s.u1), N(s.u1)],
				final]},
		},
	}


func u_choose_substitution(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("quad_in", {"B": s.B, "C": s.C}, {"A": Q.new(1), "var": "u", "tail": " = 0"}, "With u = %s: " % bx(s.base))
	var final := "So " + Answer.text(ans) + "."
	return {
		"asked": "Choose a substitution u that turns the equation into a quadratic, and write the quadratic in u.",
		"lines": [exp_line(s)], "given": {"base": s.base.key(), "B": s.B.key(), "C": s.C.key()}, "answer": ans,
		"generic": [{"B": s.B.neg(), "C": s.C}, {"B": s.B, "C": s.C.neg()}, {"B": s.C, "C": s.B}, {"B": s.B.mul(2), "C": s.C}],
		"methods": {"substitution": {"result": ans.values, "steps": [
			"%s^(2x) = (%s^x)², so the equation is in %s and its square." % [N(s.base), N(s.base), bx(s.base)],
			"Let u = %s; then %s^(2x) = u²." % [bx(s.base), N(s.base)], final]}},
	}


func u_solve_hidden_reciprocal(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := roots_ans(s.r1, s.r2)
	var final := "So " + Answer.text(ans) + "."
	var cterm := ("x − %s/x" % N(s.c.abs_q())) if s.c.sign() < 0 else ("x + %s/x" % N(s.c))
	return {
		"asked": "Solve the equation.", "lines": ["%s = %s" % [cterm, N(s.t)]], "given": {"c": s.c.key(), "t": s.t.key()}, "answer": ans,
		"generic": [{"r1": s.r1.neg(), "r2": s.r2.neg()}, {"r1": s.r1, "r2": s.r2.neg()}, {"r1": s.t, "r2": s.c}, {"r1": s.r1.add(1), "r2": s.r2.add(1)}],
		"methods": {"clear-or-combine": {"result": ans.values, "steps": [
			"Multiply by x (x ≠ 0): x²%s = %sx" % [Fmt.plus(s.c), N(s.t) if not s.t.abs_q().eq(1) else ("" if s.t.eq(1) else "−")],
			"%s = 0, so (x%s)(x%s) = 0" % [Fmt.poly([1, s.t.neg(), s.c]), Fmt.plus(s.r1.neg()), Fmt.plus(s.r2.neg())],
			"Neither root is 0, so both are solutions.", final]}},
	}


func u_solve_hidden_log(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("number", {"v": s.r1}, {}, "x = ")
	var final := "So " + Answer.text(ans) + "."
	var xd := "x" + Fmt.plus(s.d)
	var res: Dictionary = ans.values
	return {
		"asked": "Solve the equation.", "lines": ["ln x + ln(%s) = ln %s" % [xd, N(s.c)]], "given": {"d": s.d.key(), "c": s.c.key()}, "answer": ans,
		"wrongs": [wrong({"v": s.r2}, "SL2.7.hidden-quadratic#1")],
		"generic": [{"v": s.r1.neg()}, {"v": s.c}, {"v": s.r1.add(1)}, {"v": s.r2.neg()}],
		"methods": {
			"clear-or-combine": {"result": res, "steps": [
				"ln x + ln(%s) = ln(x(%s)), so x(%s) = %s" % [xd, xd, xd, N(s.c)],
				"%s = 0, so (x%s)(x%s) = 0" % [Fmt.poly([1, s.d, s.c.neg()]), Fmt.plus(s.r1.neg()), Fmt.plus(s.r2.neg())],
				"x = %s would make ln x undefined, so reject it." % N(s.r2), final]},
			"gdc-intersect": {"result": res, "steps": [
				"Graph y = ln x + ln(%s) and y = ln %s: they meet once, at x = %s." % [xd, N(s.c), N(s.r1)],
				"The quadratic's other root x = %s is outside the domain x > 0." % N(s.r2), final]},
		},
	}


func u_equation_from_roots(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var surd: bool = s.mode == "surd"
	var b: Q
	var c: Q
	var said := ""
	var given := {}
	var st: Array = []
	if surd:
		b = s.h.mul(-2)
		c = s.h.sq().sub(s.surd)
		said = "%s ± √%s" % [N(s.h), N(s.surd)]
		given = {"h": s.h.key(), "d": s.surd.key()}
		st = ["x = %s means x%s = ±√%s" % [said, Fmt.plus(s.h.neg()), N(s.surd)], "Square both sides: %s² = %s" % [Fmt.factor(s.h), N(s.surd)]]
	else:
		b = s.p.add(s.q).neg()
		c = s.p.mul(s.q)
		said = "%s and %s" % [N(s.p), N(s.q)]
		given = {"roots": [s.p.key(), s.q.key()]}
		var h: Q = s.p.add(s.q).div(2)
		var half: Q = s.q.sub(s.p).div(2)
		st = ["The roots are %s ± %s, so x%s = ±%s" % [N(h), N(half), Fmt.plus(h.neg()) if not h.is_zero() else "", N(half)],
			"Square both sides: %s² = %s" % [Fmt.factor(h), N(half.sq())]]
	var ans := Answer.make("quad_in", {"B": b, "C": c}, {"A": Q.new(1), "var": "x", "tail": " = 0"})
	var final := "So " + Answer.text(ans) + "."
	st.append("Expand and collect: " + Answer.text(ans))
	st.append(final)
	var lines := ["The roots of a quadratic equation are x = %s." % said] if rep == "equation" else ["A quadratic equation has roots %s." % (said.replace(" ± ", " + ") + " and " + said.replace(" ± ", " − ") if surd else said)]
	return {
		"asked": "Find a quadratic equation x² + bx + c = 0 with these roots and integer coefficients.", "lines": lines,
		"given": given, "answer": ans,
		"generic": [{"B": b.neg(), "C": c}, {"B": b, "C": c.neg()}, {"B": b, "C": c.add(s.surd.mul(2)) if surd else c.add(1)}, {"B": b.div(2), "C": c}],
		"methods": {"complete-square": {"result": ans.values, "steps": st}},
	}


func u_coefficient_from_root(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("kroot", {"k": s.k, "r": s.r2})
	var final := "So " + Answer.text(ans) + "."
	var eq := "x² + kx%s = 0" % Fmt.plus(s.c)
	var lines := [eq, "One root is x = %s." % N(s.r1)] if rep == "equation" else ["The equation %s has x = %s as one of its roots." % [eq, N(s.r1)]]
	return {
		"asked": "Find k and the other root.", "lines": lines, "given": {"c": s.c.key(), "root": s.r1.key()}, "answer": ans,
		"generic": [{"k": s.k.neg(), "r": s.r2}, {"k": s.k, "r": s.r2.neg()}, {"k": s.k.neg(), "r": s.r2.neg()}, {"k": s.k, "r": s.c}],
		"methods": {"factorise": {"result": ans.values, "steps": [
			"x = %s is a root: %s² + %sk%s = 0, so k = %s" % [N(s.r1), Fmt.paren(s.r1), Fmt.paren(s.r1), Fmt.plus(s.c), N(s.k)],
			"The product of the roots is %s, so the other root is %s ÷ %s = %s" % [N(s.c), N(s.c), Fmt.paren(s.r1), N(s.r2)],
			"Check: %s = (x%s)(x%s)" % [Fmt.poly([1, s.k, s.c]), Fmt.plus(s.r1.neg()), Fmt.plus(s.r2.neg())], final]}},
	}
