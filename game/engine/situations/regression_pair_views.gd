class_name RegressionPairViews
extends ExtensionViews
## The views on the `regression-x-on-y` situation: one builder per unknown of
## t4-regression-x-on-y (FAL-725). A table, an estimate or a judgement is Paper 2; choosing a
## line, the mean point and a missing mean are on both papers, with exact numbers.
##
## Representations: "table" (the data, with a story line), "equation" (lines given), "words" (a
## story naming what is estimated) and "graph" (both lines drawn, crossing at the mean point).

const SKILL := "SL4.10."
const R_REARRANGED := SKILL + "x-on-y-line#0"
const R_NOT_SWAPPED := SKILL + "x-on-y-line#1"
const R_LINE_REARRANGE := SKILL + "choose-line#0"
const R_LINE_AXIS := SKILL + "choose-line#1"
const R_Y_IN_Y_ON_X := SKILL + "predict-x#0"
const R_EXTRAPOLATE := SKILL + "predict-x#1"
const R_WRONG_SLOT := SKILL + "mean-point-intersection#1"
const YBAR := "ȳ"

const P2_ONLY := ["x-on-y-line", "d-from-mean-point", "predict-x-from-data", "predict-x-from-lines", "judge-estimate"]
const UNKNOWNS := ["x-on-y-line", "d-from-mean-point", "choose-line", "predict-x-from-data", "predict-x-from-lines",
	"judge-estimate", "mean-point-from-lines", "mean-from-one-mean"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, angle: String) -> Array:
	if not has(unknown):
		return []
	return [2] if unknown in P2_ONLY or angle.begins_with("gdc-") else [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = RegressionPairSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func W(v: Variant) -> String:
	return RegressionViews.W(v)


static func sf_ans(label: String, v: Q) -> Dictionary:
	return RegressionViews.sf_ans(label, v)


static func exact_ans(label: String, v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	ans.show = "dec"
	ans.exact = true
	return ans


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## "y = 2.3x + 12.6", "x = −0.4y + 31".
static func line_of(left: String, right: String, m: Q, k: Q) -> String:
	return "%s = %s%s %s %s" % [left, D(m), right, "−" if k.sign() < 0 else "+", D(k.abs_q())]


static func yx(s: Dictionary) -> String:
	return line_of("y", "x", s.a, s.b)


static func xy(s: Dictionary) -> String:
	return line_of("x", "y", s.c, s.d)


static func both_lines(s: Dictionary) -> Array:
	return ["The regression line of y on x is %s." % yx(s), "The regression line of x on y is %s." % xy(s)]


static func story(s: Dictionary) -> Dictionary:
	return RegressionViews.CONTEXTS[s.ctx]


static func claim(tag: String, text: String) -> Dictionary:
	return {"form": tag, "vals": [], "text": text}


# ── The line of x on y ───────────────────────────────────────

func u_x_on_y_line(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("named", {"v0": s.c, "v1": s.d}, {"names": ["c", "d"]})
	ans.show = "sf"
	var out := RegressionViews.table_view(s)
	out.asked = "Find the equation of the regression line of x on y, in the form x = cy + d, with c and d to 3 s.f."
	out.answer = ans
	out.wrongs = [wrong({"v0": s.ra, "v1": s.rb}, R_REARRANGED), wrong({"v0": s.a, "v1": s.b}, R_NOT_SWAPPED)]
	out.generic = [{"v0": s.c, "v1": s.d.neg()}, {"v0": s.d, "v1": s.c}, {"v0": s.c.mul(Q.new(9, 10)), "v1": s.d}]
	out.methods = {"gdc-swap-lists": method(["Enter the y-values in L1 and the x-values in L2, and run LinReg (ax + b) with y as the independent variable.",
		"The GDC's a and b are c = %s and d = %s." % [W(s.c), W(s.d)], "Write the result with x as the subject: x = cy + d.", final_step(ans)], ans.values)}
	return out


func u_d_from_mean_point(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var d: Q = s.d
	var ans := sf_ans("d = ", d)
	var out := {"lines": ["The mean point of a set of data is (%s, %s)." % [D(s.mx), D(s.my)], "The regression line of x on y is x = %sy + d." % D(s.c)],
		"asked": "The line passes through the mean point. Find d.", "answer": ans, "table": null}
	out.wrongs = [wrong({"v": s.rx}, R_WRONG_SLOT)]
	out.generic = [{"v": s.mx.add(s.c.mul(s.my))}, {"v": s.mx.sub(s.c)}, {"v": s.mx.div(s.my)}, {"v": Q.new(0)}]
	var cy: Q = s.c.mul(s.my)
	out.methods = {"gradient-mean-point": method(["The line passes through (x̄, %s), so x̄ = c%s + d: %s = %s × %s + d." % [YBAR, YBAR, D(s.mx), D(s.c), D(s.my)],
		"d = %s − %s = %s" % [D(s.mx), D(cy) if cy.sign() >= 0 else "(%s)" % D(cy), W(d)], final_step(ans)], ans.values)}
	return out


# ── Choosing a line ──────────────────────────────────────────

func u_choose_line(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := story(s)
	var est_x: bool = s.dir == "x"
	var right := "The line of x on y, since x is being estimated" if est_x else "The line of y on x, since y is being estimated"
	var other := "The line of y on x, rearranged to make x the subject" if est_x else "The line of x on y, rearranged to make y the subject"
	var axis := "The line of y on x, since x is on the horizontal axis" if est_x else "The line of x on y, since y is on the vertical axis"
	var ans := Answer.make("claim", claim("right", right))
	var lines := both_lines(s)
	var asked := ""
	if rep == "equation":
		asked = "Which line should be used to estimate %s when %s = %d?" % ["x" if est_x else "y", "y" if est_x else "x", s.v]
	else:
		var wanted: String = c.x if est_x else c.y
		var known: String = c.y if est_x else c.x
		lines = ["The data are the %s (x) and the %s (y) for some %s." % [c.x, c.y, c.who]] + lines
		asked = "Which line should be used to estimate the %s when the %s is %d?" % [wanted, known, s.v]
	var why: String = xy(s) if est_x else yx(s)
	var given := "y = %d" % s.v if est_x else "x = %d" % s.v
	var out := {"lines": lines, "asked": asked, "answer": ans, "table": null,
		"wrongs": [wrong(claim("w0", other), R_LINE_REARRANGE), wrong(claim("w1", axis), R_LINE_AXIS), wrong(claim("w2", "Either line: both give the same estimate"))]}
	out.methods = {"predicted-on-left": method(["Name the variable being estimated: %s, from %s." % ["x" if est_x else "y", given],
		"Use the line that has it as its subject: %s." % why, "So: " + right + "."], ans.values)}
	return out


# ── Estimates ────────────────────────────────────────────────

func u_predict_x_from_data(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := sf_ans("x = ", s.x0)
	var out := RegressionViews.table_view(s)
	out.asked = "Use the appropriate regression line to estimate x when y = %d. Give your answer to 3 s.f." % s.y0
	out.answer = ans
	out.wrongs = [wrong({"v": s.xr}, R_Y_IN_Y_ON_X)]
	out.generic = [{"v": s.c.mul(Q.new(s.y0)).sub(s.d)}, {"v": s.d.mul(Q.new(s.y0)).add(s.c)}, {"v": s.x0.mul(Q.new(9, 10))}, {"v": s.x0.mul(Q.new(11, 10))}]
	out.methods = {"substitute-y": method(["x is being estimated, so use the line of x on y. Run LinReg with y as the independent variable: c = %s and d = %s." % [W(s.c), W(s.d)],
		"Substitute y = %d with the unrounded values: x = %s × %d + %s = %s" % [s.y0, W(s.c), s.y0, W(s.d), W(s.x0)], final_step(ans)], ans.values)}
	return out


func u_predict_x_from_lines(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := sf_ans("x = ", s.x0)
	var out := {"lines": both_lines(s), "asked": "Estimate x when y = %d. Give your answer to 3 s.f." % s.y0, "answer": ans, "table": null}
	out.wrongs = [wrong({"v": s.xr}, R_Y_IN_Y_ON_X)]
	out.generic = [{"v": s.c.mul(Q.new(s.y0)).sub(s.d)}, {"v": s.a.mul(Q.new(s.y0)).add(s.b)}, {"v": s.x0.mul(Q.new(9, 10))}, {"v": s.x0.mul(Q.new(11, 10))}]
	var sign_d: String = "%s %s" % ["−" if s.d.sign() < 0 else "+", D(s.d.abs_q())]
	out.methods = {"substitute-y": method(["x is being estimated, so use the line of x on y: %s." % xy(s),
		"x = %s × %d %s = %s" % [D(s.c), s.y0, sign_d, W(s.x0)], final_step(ans)], ans.values)}
	return out


func u_judge_estimate(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := story(s)
	var good := "Reliable: y is inside the data and the correlation is strong"
	var outside := "Not reliable: y is outside the range of the data"
	var weak := "Not reliable: the correlation is weak"
	var any_y := "Reliable: r is strong, so the line can be used for any y"
	var no_line := "Not reliable: a line of x on y can't be used to estimate x"
	var right: String = {"good": good, "outside": outside, "weak": weak}[s.case]
	var ans := Answer.make("claim", claim("right", right))
	var wrongs: Array = []
	if s.case == "outside":
		wrongs = [wrong(claim("w0", any_y), R_EXTRAPOLATE), wrong(claim("w1", weak)), wrong(claim("w2", good))]
	elif s.case == "weak":
		wrongs = [wrong(claim("w0", good)), wrong(claim("w1", outside)), wrong(claim("w2", no_line))]
	else:
		wrongs = [wrong(claim("w0", weak)), wrong(claim("w1", outside)), wrong(claim("w2", no_line))]
	var out := {"lines": ["For some %s, the %s (x) and the %s (y) have r = %s." % [c.who, c.x, c.y, D(s.rr)],
		"The values of y in the data run from %d to %d." % [s.ylo, s.yhi]],
		"asked": "The line of x on y is used to estimate x when y = %d. How reliable is this estimate?" % s.y0,
		"answer": ans, "table": null, "wrongs": wrongs}
	var inside: bool = s.y0 >= s.ylo and s.y0 <= s.yhi
	out.methods = {"reliability-check": method(["Is y inside the data? %d is %s %d to %d." % [s.y0, "inside" if inside else "outside", s.ylo, s.yhi],
		"Is the correlation strong? r = %s, so it is %s." % [D(s.rr), "strong" if s.case != "weak" else "weak"], "So: " + right + "."], ans.values)}
	return out


# ── The mean point ───────────────────────────────────────────

func u_mean_point_from_lines(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("point", {"x": s.mx, "y": s.my})
	ans.show = "dec"
	ans.exact = true
	var lines := both_lines(s)
	var out := {"lines": lines, "asked": "Find the mean point (x̄, %s)." % YBAR, "answer": ans, "table": null}
	if rep == "graph":
		lines[0] = "The diagram shows the regression line of y on x, %s." % yx(s)
		lines[1] = "It also shows the regression line of x on y, %s." % xy(s)
		out.graph = two_lines_graph(s)
	out.generic = [{"x": s.my, "y": s.mx}, {"x": s.mx.add(Q.new(1)), "y": s.my}, {"x": s.mx, "y": s.my.sub(Q.new(1))}, {"x": s.b, "y": s.d}]
	var ac: Q = s.a.mul(s.c)
	var left := Q.new(1).sub(ac)
	var right: Q = s.c.mul(s.b).add(s.d)
	out.methods = {"solve-simultaneously": method(["Both lines pass through the mean point, so substitute y = %sx %s %s into x = cy + d." % [D(s.a), "−" if s.b.sign() < 0 else "+", D(s.b.abs_q())],
			"x = %s(%sx %s %s) %s %s" % [D(s.c), D(s.a), "−" if s.b.sign() < 0 else "+", D(s.b.abs_q()), "−" if s.d.sign() < 0 else "+", D(s.d.abs_q())],
			"%sx = %s, so x = %s" % [D(left), D(right), D(s.mx)], "y = %s × %s %s %s = %s" % [D(s.a), D(s.mx), "−" if s.b.sign() < 0 else "+", D(s.b.abs_q()), D(s.my)],
			final_step(ans)], ans.values),
		"gdc-intersect": method(["Rearrange x = cy + d to y = (x − d) ÷ c, and graph it with the line of y on x.", "Use the intersect tool: x = %s and y = %s." % [D(s.mx), D(s.my)], final_step(ans)], ans.values)}
	return out


## Both lines across the window, with the mean point at the crossing.
static func two_lines_graph(s: Dictionary) -> Dictionary:
	var mx: float = s.mx.to_float()
	var my: float = s.my.to_float()
	var a: float = s.a.to_float()
	var b: float = s.b.to_float()
	var c: float = s.c.to_float()
	var d: float = s.d.to_float()
	var hi := int(ceilf(mx * 2.0)) + 2
	var top := int(ceilf(my * 2.0)) + 4
	var f := func(x: float) -> float: return a * x + b
	var g := func(x: float) -> float: return (x - d) / c
	var out := Plot.spec([Plot.sample(f, 0.0, float(hi)), Plot.sample(g, 0.0, float(hi))], [[mx, my, "M"]], 0, hi, 0, top)
	return out


func u_mean_from_one_mean(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var known_x: bool = s.known == "x"
	var want: Q = s.my if known_x else s.mx
	var have: Q = s.mx if known_x else s.my
	var ans := exact_ans(("%s = " % YBAR) if known_x else "x̄ = ", want)
	var name: String = "x̄" if known_x else YBAR
	var line: String = yx(s) if s.line == "yx" else xy(s)
	var kind: String = "y on x" if s.line == "yx" else "x on y"
	var out := {"lines": ["The regression line of %s is %s." % [kind, line], "%s = %s" % [name, D(have)]],
		"asked": "Find %s." % (YBAR if known_x else "x̄"), "answer": ans, "table": null}
	out.wrongs = [wrong({"v": s.rx}, R_WRONG_SLOT)]
	out.generic = [{"v": have}, {"v": want.add(Q.new(1))}, {"v": want.sub(Q.new(1))}, {"v": want.add(Q.new(2))}]
	var steps: Array = ["The regression line passes through (x̄, %s), so put x = x̄ and y = %s into it." % [YBAR, YBAR]]
	if known_x == (s.line == "yx"):
		var m: Q = s.a if s.line == "yx" else s.c
		var k: Q = s.b if s.line == "yx" else s.d
		steps.append("%s = %s × %s %s %s = %s" % [YBAR if known_x else "x̄", D(m), D(have), "−" if k.sign() < 0 else "+", D(k.abs_q()), D(want)])
	else:
		var m2: Q = s.c if s.line == "xy" else s.a
		var k2: Q = s.d if s.line == "xy" else s.b
		steps.append("%s = %s%s %s %s, so %s = %s" % [D(have), D(m2), YBAR if known_x else "x̄", "−" if k2.sign() < 0 else "+", D(k2.abs_q()), YBAR if known_x else "x̄", D(want)])
	steps.append(final_step(ans))
	out.methods = {"substitute-known-mean": method(steps, ans.values)}
	return out
