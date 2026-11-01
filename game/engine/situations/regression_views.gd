class_name RegressionViews
extends ExtensionViews
## The views on the `regression` situation: one builder per unknown of t4-regression-gdc
## (FAL-695). Every question is Paper 2 and works with the GDC: LinReg (ax + b) with
## diagnostics on gives a, b and r. Answers are to 3 s.f. (show "sf", with the rounding trap
## where the answer is one number), except the mean point, which is exact.
##
## Representations: "table" (the data, with a story line above), "equation" (a line given, or
## a mean point and a gradient given). `given` holds what the student is shown.

const SKILL := "SL4.4."
const R_SWAPPED_LISTS := SKILL + "regression-y-on-x#0"
const R_EARLY_ROUNDING := SKILL + "regression-y-on-x#1"
const R_R_SQUARED := SKILL + "pearson-r#0"
const R_THROUGH_ORIGIN := SKILL + "mean-point#0"
const R_REARRANGED := SKILL + "predict#1"

## The stories: x and y in a phrase each, and what the n rows are.
const CONTEXTS := [
	{"x": "hours of study per week", "y": "test score out of 100", "who": "students"},
	{"x": "daily temperature in °C", "y": "number of cans of lemonade sold", "who": "days"},
	{"x": "age of a car in years", "y": "value in hundreds of dollars", "who": "cars"},
	{"x": "hours of sunshine in a day", "y": "litres of water collected", "who": "days"},
	{"x": "height above sea level in hundreds of metres", "y": "air temperature in °C", "who": "weather stations"},
	{"x": "minutes of exercise per day", "y": "resting heart rate in beats per minute", "who": "adults"},
	{"x": "number of workers on a repair crew", "y": "repairs finished in a week", "who": "crews"},
	{"x": "distance from the city in km", "y": "house price in tens of thousands of dollars", "who": "houses"},
]

const UNKNOWNS := ["regression-line", "correlation-coefficient", "mean-point", "c-from-mean-point", "predict-from-data", "predict-from-line"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## Every cell is Paper 2: every regression part in the bank is.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = RegressionSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## A value to 6 significant figures with no trailing zeros: a GDC's screen.
static func W(v: Variant) -> String:
	var t := Fmt.sf(v, 6)
	if t.contains("."):
		t = t.rstrip("0").rstrip(".")
	return t


static func qf(x: float) -> Q:
	return GdcKit.qf(x)


## The story line and the table: x against y.
static func table_view(s: Dictionary) -> Dictionary:
	var c: Dictionary = CONTEXTS[s.ctx]
	return {"lines": ["The table shows the %s (x) and the %s (y) for %d %s." % [c.x, c.y, s.n, c.who]],
		"table": {"rows": [["x", s.xs.map(func(x): return str(x))], ["y", s.ys.map(func(y): return str(y))]]}}


## A number answer to 3 s.f.
static func sf_ans(label: String, v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	ans.show = "sf"
	return ans


## The wrong options that are well-formed numbers: not zero and clear of the answer at 3 s.f.
static func vs(xs: Array) -> Array:
	return xs.map(func(x): return {"v": x})


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## The line as it is written in the question: "y = 2.34x + 12.6" or "y = −0.55x − 3.1".
static func line_text(a: Q, b: Q) -> String:
	var t := "y = " + D(a) + "x"
	return t + (" − " if b.sign() < 0 else " + ") + D(b.abs_q())


# ── The line, r and the mean point ───────────────────────────

func u_regression_line(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("line", {"m": s.a, "c": s.b})
	ans.show = "sf"
	var out := table_view(s)
	out.asked = "Find the equation of the regression line of y on x, in the form y = ax + b, with a and b to 3 s.f."
	out.answer = ans
	out.wrongs = [wrong({"m": s.ay, "c": s.by}, R_SWAPPED_LISTS)]
	# A sign slip in b, and a and b the wrong way round.
	out.generic = [{"m": s.a, "c": s.b.neg()}, {"m": s.b, "c": s.a}, {"m": s.a.mul(Q.new(9, 10)), "c": s.b}, {"m": s.a, "c": s.b.mul(Q.new(11, 10))}]
	out.methods = {"gdc-linreg": method(["Enter the x-values in list L1 and the y-values in L2, and run LinReg (ax + b) with x as the independent variable.",
		"a = %s and b = %s" % [W(s.a), W(s.b)], final_step(ans)], ans.values)}
	return out


func u_correlation_coefficient(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: float = s.r
	var ans := sf_ans("r = ", qf(r))
	var out := table_view(s)
	out.asked = "Find the value of r, Pearson's product-moment correlation coefficient, to 3 s.f."
	out.answer = ans
	out.wrongs = [wrong({"v": qf(r * r)}, R_R_SQUARED)]
	out.generic = vs([qf(-r), qf(r * 0.9), qf(r * 0.8), qf(signf(r) * (1.0 + absf(r)) / 2.0)])
	out.methods = {"gdc-linreg": method(["Enter the x-values in L1 and the y-values in L2, turn diagnostics on and run LinReg (ax + b).",
		"r = %s (and r² = %s)" % [W(qf(r)), W(qf(r * r))], final_step(ans)], ans.values)}
	return out


func u_mean_point(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("point", {"x": s.mx, "y": s.my})
	ans.show = "dec"
	ans.exact = true
	var out := table_view(s)
	out.asked = "Write down the coordinates of the mean point."
	out.answer = ans
	out.wrongs = []
	out.generic = [{"x": s.my, "y": s.mx}, {"x": s.mx, "y": s.my.add(Q.new(1))}, {"x": s.mx.sub(Q.new(1)), "y": s.my}, {"x": s.mx.add(Q.new(1)), "y": s.my.sub(Q.new(1))}]
	var sx := 0
	var sy := 0
	for i in s.n:
		sx += int(s.xs[i])
		sy += int(s.ys[i])
	out.methods = {"mean-coordinates": method(["Add the x-values and the y-values: Σx = %d and Σy = %d, with n = %d." % [sx, sy, s.n],
		"x̄ = %d ÷ %d = %s and ȳ = %d ÷ %d = %s" % [sx, s.n, D(s.mx), sy, s.n, D(s.my)], final_step(ans)], ans.values)}
	return out


# ── c from a mean point ──────────────────────────────────────

func u_c_from_mean_point(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Q = s.c
	var ans := Answer.make("number", {"v": c}, {}, "c = ")
	if Answer.needs_rounding(c):
		ans.show = "sf"
	else:
		ans.show = "dec"
		ans.exact = true
	var out := {"lines": ["The mean point of a set of data is (%s, %s)." % [D(s.mx), D(s.my)], "The regression line of y on x is y = %sx + c." % D(s.a)],
		"asked": "The regression line passes through the mean point. Find c.", "answer": ans, "table": null}
	# The slips: forcing the line through the origin, and the sign of ax going the wrong way.
	out.wrongs = [wrong({"v": Q.new(0)}, R_THROUGH_ORIGIN)]
	out.generic = [{"v": s.my.add(s.a.mul(s.mx))}, {"v": s.my.sub(s.a)}, {"v": s.my.div(s.mx)}, {"v": s.my.sub(s.mx)}]
	var ax: Q = s.a.mul(s.mx)
	var shown_c: String = D(c) if ans.show == "dec" else W(c)
	var sub_mean := ["The line passes through the mean point, so ȳ = ax̄ + c: %s = %s × %s + c." % [D(s.my), D(s.a), D(s.mx)],
		"c = %s − %s = %s" % [D(s.my), D(ax) if ax.sign() >= 0 else "(%s)" % D(ax), shown_c], final_step(ans)]
	var grad_pt := ["The line is y − ȳ = a(x − x̄), so y − %s = %s(x − %s)." % [D(s.my), D(s.a), D(s.mx)],
		"y = %sx + %s, so c = %s − %s = %s" % [D(s.a), D(s.my), D(s.my), D(ax) if ax.sign() >= 0 else "(%s)" % D(ax), shown_c], final_step(ans)]
	out.methods = {"substitute-mean-point": method(sub_mean, ans.values), "gradient-and-mean-point": method(grad_pt, ans.values)}
	return out


# ── Predictions ──────────────────────────────────────────────

func u_predict_from_data(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x0: int = s.x0
	var ans := sf_ans("y = ", s.y0)
	var out := table_view(s)
	out.asked = "Use the regression line of y on x to estimate y when x = %d. Give your answer to 3 s.f." % x0
	out.answer = ans
	out.wrongs = [wrong({"v": s.y3}, R_EARLY_ROUNDING), wrong({"v": s.xr}, R_REARRANGED)]
	out.generic = [{"v": s.a.mul(Q.new(x0)).sub(s.b)}, {"v": s.b.mul(Q.new(x0)).add(s.a)}, {"v": s.y0.mul(Q.new(9, 10))}, {"v": s.y0.mul(Q.new(11, 10))}]
	out.methods = {"substitute": method(["Enter the data in lists and run LinReg (ax + b): a = %s and b = %s." % [W(s.a), W(s.b)],
		"Substitute x = %d with the unrounded a and b: y = %s × %d + %s = %s" % [x0, W(s.a), x0, W(s.b), W(s.y0)], final_step(ans)], ans.values)}
	return out


func u_predict_from_line(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x0: int = s.x0
	var ans := sf_ans("y = ", s.y0)
	var out := {"lines": ["The regression line of y on x is %s." % line_text(s.a, s.b)],
		"asked": "Use the line to estimate y when x = %d. Give your answer to 3 s.f." % x0, "answer": ans, "table": null}
	out.wrongs = [wrong({"v": s.xr}, R_REARRANGED)]
	out.generic = [{"v": s.a.mul(Q.new(x0)).sub(s.b)}, {"v": s.b.mul(Q.new(x0)).add(s.a)}, {"v": s.y0.mul(Q.new(9, 10))}, {"v": s.y0.mul(Q.new(11, 10))}]
	var b_text: String = ("+ %s" % D(s.b)) if s.b.sign() >= 0 else ("− %s" % D(s.b.abs_q()))
	out.methods = {"substitute": method(["Substitute x = %d into %s." % [x0, line_text(s.a, s.b)],
		"y = %s × %d %s = %s" % [D(s.a), x0, b_text, W(s.y0)], final_step(ans)], ans.values)}
	return out
