class_name RationalFunctionViews
extends ExtensionViews
## The views on the `rational-function` situation (FAL-423): one builder per unknown of
## fn-rational-asymptotes-intercepts and fn-rational-sketch (the two exam types).
## Builders return what QuadraticViews' builders return (see quadratic_views.gd).
##
## Paper 1 numbers come out exact: every asymptote and intercept is a whole number, a half
## or a third, marked exactly. Paper 2 (papers()) gives a, b, c, d that need a calculator,
## so the vertical and horizontal asymptotes and both intercepts are decimals that don't
## end, asked to 3 s.f. with the rounding trap; fn-rational-sketch's reciprocal of f is
## Paper 2 in the bank, with asymptotes between the grid lines. Students can't draw, so
## a sketch is "which of four graphs" (GdcKit.pick): each wrong graph changes one thing
## (RationalCards), and the wrong options of the written answers (an asymptote, an
## interval, a count) are the type's misconceptions.

const T1 := "fn-rational-asymptotes-intercepts"
const T2 := "fn-rational-sketch"
const R_VA_SIGN := "SL2.8.asymptotes#0"
const R_HA_RATIO := "SL2.8.asymptotes#1"
const R_NUMBER := "SL2.4.asymptotes#0"
const R_SWAP := "SL2.4.asymptotes#1"
const R_ZERO_YINT := "SL2.4.zeros-intercepts#0"
const R_ZERO_SIGN := "SL2.4.zeros-intercepts#1"
const R_RANGE_INCL := "SL2.2.range#1"
const R_RANGE_X := "SL2.2.range#2"
const R_CORNERS := "SL2.8.sketch-rational#0"
const R_ZERO_AT_H := "SL2.8.sketch-rational#1"
const R_ACROSS := "SL2.8.sketch-rational#2"
const R_INEQ_POINTS := "SL2.10.inequality-graphical#0"
const R_INEQ_BELOW := "SL2.10.inequality-graphical#1"
const R_INEQ_ONE := "SL2.10.inequality-graphical#2"
const R_TANGENT := "SL2.10.number-of-solutions#0"
const R_DOMAIN := "SL2.10.number-of-solutions#1"
const R_ASYMPTOTE_SOLVES := "SL2.10.number-of-solutions#2"
const R_SELF_PRODUCT := "SL2.8.reciprocal#0"
const R_PARENT_AXES := "SL2.8.reciprocal#1"
const R_PARENT_QUADRANTS := "SL2.8.reciprocal#2"
const R_VECTOR_SIGN := "SL2.8.transformed-reciprocal#0"
const R_NO_STRETCH := "SL2.8.transformed-reciprocal#1"
const R_SPLIT_WRONG := "SL2.8.transformed-reciprocal#2"


func needs() -> Dictionary:
	return {
		# fn-rational-asymptotes-intercepts
		"va-from-equation": {"mode": "any"},
		"ha-from-equation": {"mode": "any"},
		"asymptotes-with-letters": {"mode": "monic"},
		"x-intercept": {"mode": "any"},
		"y-intercept": {"mode": "any"},
		"features-from-graph": {"graph": true},
		"asymptotes-from-table": {"mode": "monic"},
		"constants-from-asymptotes": {"mode": "monic"},
		"constant-from-intercept": {"mode": "monic", "no_origin": true},
		"equation-from-features": {"graph": true},
		"range-from-asymptote": {"mode": "any"},
		# fn-rational-sketch
		"sketch-from-equation": {"card": true},
		"sketch-from-transformed": {"card": true},
		"sketch-from-description": {"card": true},
		"branch-corners": {"graph": true},
		"equation-from-sketch": {"card": true},
		"inequality-from-sketch": {"ineq": true},
		"count-with-horizontal": {"graph": true, "hline": true},
		"k-for-no-solution": {"mode": "monic"},
		"count-with-line": {"line": true},
		"count-with-curve": {"curve": true},
		"reciprocal-of-f": {"card": true},
		"parent-reciprocal": {"parent": true},
		"reciprocal-self-inverse": {"parent": true},
		# fn-ext-transformed-reciprocal (the extra skill "Transformed reciprocal graphs")
		"split-to-form": {"mode": "monic"},
		"split-scaled": {"mode": "split"},
		"translation-vector": {"mode": "monic"},
		"transformation-sequence": {"mode": "monic"},
		"combine-to-single": {"mode": "monic"},
		"form-from-graph": {"graph": true},
		"form-from-words": {"mode": "monic"},
	}


## A graph needs whole asymptotes and intercepts on grid lines (RationalFunctionSituation).
## So does a table of values near x = h, and an inequality that has a graph shown.
func need(unknown: String, rep: String) -> Dictionary:
	var n := super.need(unknown, rep)
	if rep in ["graph", "table", "words"] and unknown not in ["parent-reciprocal", "reciprocal-self-inverse"]:
		n.graph = true
		if unknown == "inequality-from-sketch":
			n.k_zero = true
	if unknown == "reciprocal-of-f":
		n.erase("card")
		n.graph = true
	return n


## The extra formats the views build: error-spot where a view has a `spot`. Extension types
## only; the exam types offer none. method-pick and true-false-reason are not built for this
## region (see game/README.md).
func extra() -> Dictionary:
	return {"split-to-form": ["error-spot"]}


## The papers a cell can be asked on (QuestionEngine.cell_papers).
func papers(unknown: String, rep: String, _angle: String) -> Array:
	if unknown in ["va-from-equation", "ha-from-equation", "x-intercept", "y-intercept"] and rep == "equation":
		return [1, 2]
	if unknown == "reciprocal-of-f":
		return [2]
	return [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	# The situation's numbers, and whatever else the view says it gave (a point, which intercept).
	var own: Dictionary = out.get("given", {}) if out.get("given") != null else {}
	out.given = RationalFunctionSituation.export(s)
	out.given.merge(ExtensionViews.export(own), true)
	return out


# ── Helpers ──────────────────────────────────────────────────

static func p2(s: Dictionary) -> bool:
	return s.get("paper", 1) == 2


static func fx(s: Dictionary) -> String:
	return "f(x) = " + RationalFunctionSituation.text(s)


## A number as the working shows it: exact in Paper 1; in Paper 2 the fraction and its
## decimal "−7/9 = −0.778" (the answer is to 3 s.f.).
static func work(q: Variant, paper2: bool) -> String:
	var t := Fmt.num(q)
	if paper2 and not Q.of(q).is_int():
		return "%s = %s (3 s.f.)" % [t, Fmt.sf(q)]
	return t


## An exact (Paper 1) or 3 s.f. (Paper 2) asymptote "x = 2": var is "x" or "y".
static func axis_ans(v: String, q: Q, paper2: bool) -> Dictionary:
	var ans := Answer.make("axis", {"var": v, "h": q})
	if paper2:
		ans.show = "sf"
	else:
		ans.exact = true
	return ans


static func _axis(v: String, q: Variant) -> Dictionary:
	return {"var": v, "h": Q.of(q)}


static func _num_ans(label: String, q: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": q}, {}, label)
	ans.exact = true
	return ans


## The text of the answer, as the last step states it.
static func final(prefix: String, ans: Dictionary) -> String:
	return "%s %s." % [prefix, Answer.text(ans)]


## The denominator and numerator as written in f.
static func den(s: Dictionary) -> String:
	return Fmt.poly([s.c, s.d])


static func num_(s: Dictionary) -> String:
	return Fmt.poly([s.a, s.b])


## f(x) at a large x, for the table method, to 4 decimal places.
static func at(s: Dictionary, x: float) -> String:
	return Fmt.dec(Q.new(roundi(RationalFunctionSituation.y_at(s, x) * 10000.0), 10000)).replace("-", "−")


## "A + B/(x − h)" for a monic f, or a general description when c ≠ 1.
static func split_text(s: Dictionary) -> String:
	if s.c == 1:
		return "f(x) = " + RationalFunctionSituation.split(s.A, s.B, s.h)
	return "f(x) = %s + a fraction whose denominator is %s" % [Fmt.num(s.A), den(s)]


# ── fn-rational-asymptotes-intercepts ────────────────────────

func u_va_from_equation(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pp := p2(s)
	var h: Q = s.h
	var ans := axis_ans("x", h, pp)
	var d := den(s)
	var fin := final("So the vertical asymptote is", ans)
	var solved := "x = %s" % work(h, pp)
	return {
		"asked": "Write down the equation of the vertical asymptote of the graph of y = f(x).", "lines": [fx(s)], "answer": ans,
		"wrongs": [wrong(_axis("x", h.neg()), R_VA_SIGN), wrong(_axis("y", h), R_SWAP), wrong(_axis("", h), R_NUMBER)],
		"generic": [_axis("x", s.xi), _axis("x", s.A)],
		"methods": {
			"zero-denominator-and-ratio": method(["The vertical asymptote is where the denominator is zero.", "%s = 0, so %s." % [d, solved], fin], ans.values),
			"divide-out": method(["Divide out: %s." % split_text(s), "The fraction is undefined where its denominator is zero: %s = 0, so %s." % [d, solved], fin], ans.values),
			"undefined-input": method(["f(x) is undefined where %s = 0." % d, "That is %s, and the graph has a vertical asymptote there." % solved, fin], ans.values),
		},
	}


func u_ha_from_equation(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pp := p2(s)
	var A: Q = s.A
	var ans := axis_ans("y", A, pp)
	var fin := final("So the horizontal asymptote is", ans)
	var ratio := "y = a/c = %s/%s = %s" % [Fmt.num(s.a), Fmt.num(s.c), work(A, pp)] if s.c != 1 else "y = a/c = %s" % Fmt.num(A)
	var far := "f(1000) = %s and f(−1000) = %s" % [at(s, 1000.0), at(s, -1000.0)]
	return {
		"asked": "Write down the equation of the horizontal asymptote of the graph of y = f(x).", "lines": [fx(s)], "answer": ans,
		"wrongs": [wrong(_axis("y", Q.new(s.b, s.d)), R_HA_RATIO), wrong(_axis("x", A), R_SWAP), wrong(_axis("", A), R_NUMBER)],
		"generic": [_axis("y", s.h), _axis("y", s.B)],
		"methods": {
			"zero-denominator-and-ratio": method(["The horizontal asymptote is the ratio of the x-coefficients.", ratio, fin], ans.values),
			"divide-out": method(["Divide out: %s." % split_text(s), "The fraction tends to 0 for large x, so f(x) tends to %s." % work(A, pp), fin], ans.values),
			"large-x-limit": method(["For large x the constants don't matter: f(x) ≈ %sx/%sx." % [Fmt.num(s.a), Fmt.num(s.c)], "%s." % ratio, fin], ans.values),
			"gdc-table": method(["Make a table of f on the GDC and look at large x: %s." % far, "The values settle at %s." % work(A, pp), fin], ans.values),
			"large-x-behaviour": method(["Look at f for large x: %s." % far, "The values get close to %s, so the curve levels off there." % work(A, pp), fin], ans.values),
			"move-parent-asymptote": method(["Write f as a moved y = B/x: %s." % split_text(s), "y = B/x has the asymptote y = 0, and the move shifts it to y = %s." % work(A, pp), fin], ans.values),
		},
	}


func u_asymptotes_with_letters(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	# k stands in for c (in the denominator) or for a (in the numerator).
	var in_den := rng.chance(0.5)
	var va: String
	var ha: String
	var shown: String
	var wrong_ha: String
	var swapped: String
	var wrong_va: String
	var why_va: String
	var why_ha: String
	var ratio := func(n: Variant, letter: String) -> String:
		var q := Q.of(n)
		return "%s/%s" % [q.text(), letter] if not q.eq(1) else "1/" + letter
	if in_den:
		# f(x) = (ax + b)/(kx + d): x = −d/k, y = a/k
		shown = "f(x) = (%s)/(kx %s %d)" % [num_(s), "+" if s.d > 0 else "−", absi(s.d)]
		va = "x = " + ratio.call(-s.d, "k")
		ha = "y = " + ratio.call(s.a, "k")
		wrong_va = "x = " + ratio.call(s.d, "k")
		wrong_ha = "y = " + Fmt.num(Q.new(s.b, s.d))
		swapped = "x = %s and y = %s" % [ratio.call(s.a, "k"), ratio.call(-s.d, "k")]
		why_va = "kx + d = 0, so x = −d/k = %s" % ratio.call(-s.d, "k")
		why_ha = "y = a/c = %s" % ratio.call(s.a, "k")
	else:
		# f(x) = (kx + b)/(cx + d): x = −d/c, y = k/c
		var cx := Fmt.poly([s.c, s.d])
		shown = "f(x) = (kx %s %d)/(%s)" % ["+" if s.b > 0 else "−", absi(s.b), cx] if s.b != 0 else "f(x) = kx/(%s)" % cx
		va = "x = " + Fmt.num(s.h)
		ha = "y = k" if s.c == 1 else "y = k/%d" % s.c
		wrong_va = "x = " + Fmt.num(s.h.neg())
		wrong_ha = "y = " + Fmt.num(Q.new(s.b, s.d))
		swapped = "x = %s and y = %s" % [("k" if s.c == 1 else "k/%d" % s.c), Fmt.num(s.h)]
		why_va = "%s = 0, so x = %s" % [cx, Fmt.num(s.h)]
		why_ha = ha
	var right := "%s and %s" % [va, ha]
	var wrongs := [
		{"values": {"v": "%s and %s" % [wrong_va, ha]}, "ref": R_VA_SIGN},
		{"values": {"v": "%s and %s" % [va, wrong_ha]}, "ref": R_HA_RATIO},
		{"values": {"v": swapped}, "ref": R_SWAP},
	]
	var out := LogFunctionViews.choice(right, wrongs, ["%s and %s" % [ha, va]])
	var fin := "So the asymptotes are %s." % right
	var letters := "k"
	out.merge({
		"asked": "Write down the equations of both asymptotes, in terms of %s." % letters, "lines": [shown],
		"given": {"form": "den" if in_den else "num", "a": s.a, "b": s.b, "c": s.c, "d": s.d},
		"methods": {
			"zero-denominator-and-ratio": method(["The vertical asymptote is where the denominator is zero: %s." % why_va, "The horizontal asymptote is the ratio of the x-coefficients: %s." % why_ha, fin], out.answer.values),
			"large-x-limit": method(["For large x the constants don't matter, so the ratio of the x-terms gives the horizontal asymptote: %s." % why_ha, "The vertical asymptote is where the denominator is zero: %s." % why_va, fin], out.answer.values),
			"undefined-input": method(["f is undefined where the denominator is zero: %s, a vertical asymptote." % why_va, "For large x, f(x) tends to the ratio of the x-coefficients: %s." % why_ha, fin], out.answer.values),
		}})
	return out


func u_x_intercept(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pp := p2(s)
	var xi: Q = s.xi
	var ans := Answer.make("xint", {"x": xi})
	if pp:
		ans.show = "sf"
	else:
		ans.exact = true
	var fin := final("So the x-intercept is", ans)
	var n := num_(s)
	var solved := "x = %s" % work(xi, pp)
	return {
		"asked": "Find the x-intercept of the graph of y = f(x).", "lines": [fx(s)], "answer": ans,
		"wrongs": [wrong({"x": s.yi}, R_ZERO_YINT), wrong({"x": Q.new(s.b, s.a)}, R_ZERO_SIGN)],
		"generic": [{"x": s.h}, {"x": Q.new(-s.b)}],
		"methods": {
			"set-equal-zero": method(["The graph crosses the x-axis where f(x) = 0, that is where the numerator is zero.", "%s = 0, so %s." % [n, solved], fin], ans.values),
			"gdc-zero": method(["Graph y = f(x) on the GDC and use its zero finder.", "It gives %s." % solved, fin], ans.values),
		},
	}


func u_y_intercept(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pp := p2(s)
	var yi: Q = s.yi
	var ans := Answer.make("yint", {"y": yi})
	if pp:
		ans.show = "sf"
	else:
		ans.exact = true
	var fin := final("So the y-intercept is", ans)
	var sub := "f(0) = %s/%s = %s" % [Fmt.num(s.b), Fmt.num(s.d), work(yi, pp)]
	return {
		"asked": "Find the y-intercept of the graph of y = f(x).", "lines": [fx(s)], "answer": ans,
		"wrongs": [wrong({"y": s.xi}, R_ZERO_YINT)],
		"generic": [{"y": Q.new(s.b)}, {"y": s.A}, {"y": s.yi.neg()}],
		"methods": {
			"set-equal-zero": method(["The graph crosses the y-axis where x = 0.", "Put x = 0: %s." % sub, fin], ans.values),
		},
	}


## "asymptotes x = 2 and y = 3; x-intercept (1, 0), y-intercept (0, −1)".
static func features_text(h: Variant, A: Variant, xi: Variant, yi: Variant) -> String:
	return "asymptotes x = %s and y = %s; x-intercept %s, y-intercept %s" % [Fmt.num(h), Fmt.num(A), Fmt.point(xi, 0), Fmt.point(0, yi)]


func u_features_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := features_text(s.h, s.A, s.xi, s.yi)
	var wrongs := [
		{"values": {"v": features_text(s.A, s.h, s.xi, s.yi)}, "ref": R_SWAP},
		{"values": {"v": features_text(s.h, s.A, s.yi, s.xi)}, "ref": R_ZERO_YINT},
		{"values": {"v": features_text(s.h.neg(), s.A, s.xi, s.yi)}, "ref": R_VA_SIGN},
	]
	var out := LogFunctionViews.choice(right, wrongs, [features_text(s.h, s.A.neg(), s.xi, s.yi), features_text(s.h, s.A, s.xi.neg(), s.yi), features_text(s.h, s.A, s.xi, s.yi.add(Q.new(1)))])
	var t := RationalCards.triple_of(s)
	var fin := "So the graph shows %s." % right
	out.merge({
		"asked": "The graph of a rational function is shown, with its asymptotes dashed. Write down the equations of its asymptotes and the coordinates of its intercepts.",
		"lines": ["The graph of y = f(x) is shown."],
		"graph": RationalCards.plot(t, [[s.xi.to_float(), 0.0, ""], [0.0, s.yi.to_float(), ""]]),
		"methods": {"graph-read": method(["The dashed vertical line is x = %s and the dashed horizontal line is y = %s." % [Fmt.num(s.h), Fmt.num(s.A)],
			"The curve crosses the x-axis at %s and the y-axis at %s." % [Fmt.point(s.xi, 0), Fmt.point(0, s.yi)], fin], out.answer.values)}})
	return out


func u_asymptotes_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h: Q = s.h
	var A: Q = s.A
	var right := "x = %s and y = %s" % [Fmt.num(h), Fmt.num(A)]
	var wrongs := [
		{"values": {"v": "x = %s and y = %s" % [Fmt.num(A), Fmt.num(h)]}, "ref": R_SWAP},
		{"values": {"v": "x = %s and y = %s" % [Fmt.num(h.neg()), Fmt.num(A)]}, "ref": R_VA_SIGN},
	]
	var out := LogFunctionViews.choice(right, wrongs, ["x = 0 and y = %s" % Fmt.num(A), "x = %s and y = %s" % [Fmt.num(h), Fmt.num(A.add(Q.new(1)))]])
	var xs: Array = [Q.new(10 * h.n - 1, 10), Q.new(100 * h.n - 1, 100), Q.new(100 * h.n + 1, 100), Q.new(10 * h.n + 1, 10), Q.new(-1000), Q.new(1000)]
	var xt: Array = []
	var yt: Array = []
	for x in xs:
		xt.append(Fmt.dec(x))
		yt.append(at(s, x.to_float()))
	var fin := "So the asymptotes are %s." % right
	out.merge({
		"asked": "The table shows values of f(x), for x close to one value and for large x. Write down the equations of the asymptotes.",
		"lines": ["The table shows values of f."],
		"table": {"rows": [["x", xt], ["f(x)", yt]]},
		"methods": {
			"gdc-table": method(["Next to x = %s the values jump from one very large number to another: f is not defined there." % Fmt.num(h), "For x = ±1000 the values are close to %s." % Fmt.num(A), fin], out.answer.values),
			"large-x-behaviour": method(["For large x (±1000) the values are close to %s, so y = %s." % [Fmt.num(A), Fmt.num(A)],
				"The values change sign and size either side of x = %s, so x = %s is the vertical asymptote." % [Fmt.num(h), Fmt.num(h)], fin], out.answer.values),
		}})
	return out


## The named answer "a = 3, d = −2".
static func named_ans(names: Array, values: Array) -> Dictionary:
	var v := {}
	for i in names.size():
		v["v%d" % i] = Q.of(values[i])
	var ans := Answer.make("named", v, {"names": names})
	ans.exact = true
	return ans


func u_constants_from_asymptotes(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h: Q = s.h
	var A: Q = s.A
	var ans := named_ans(["a", "d"], [A, Q.new(s.d)])
	var shown := "f(x) = (ax %s %d)/(x + d)" % ["+" if s.b > 0 else "−", absi(s.b)] if s.b != 0 else "f(x) = ax/(x + d)"
	var said := "its vertical asymptote is x = %s and its horizontal asymptote is y = %s" % [Fmt.num(h), Fmt.num(A)]
	var lines: Array = [shown]
	var out := {"answer": ans, "wrongs": [
		wrong({"v0": A, "v1": h}, R_VA_SIGN), wrong({"v0": h, "v1": A.neg()}, R_SWAP)],
		"generic": [{"v0": A, "v1": Q.new(s.d * 2)}, {"v0": Q.new(s.b), "v1": Q.new(s.d)}]}
	match rep:
		"equation":
			lines.append("The graph of f has the vertical asymptote x = %s and the horizontal asymptote y = %s." % [Fmt.num(h), Fmt.num(A)])
		"words":
			lines.append("In words: " + said + ".")
		"graph":
			lines.append("Its graph is shown, with its asymptotes dashed.")
			out.graph = RationalCards.plot(RationalCards.triple_of(s))
	var fin := "So " + Answer.text(ans) + "."
	out.merge({
		"asked": "Find the constants a and d.", "lines": lines,
		"methods": {
			"zero-denominator-and-ratio": method(["The vertical asymptote is where x + d = 0, so x = −d. Here x = %s, so d = %s." % [Fmt.num(h), Fmt.num(Q.new(s.d))],
				"The horizontal asymptote is y = a/1 = a, so a = %s." % Fmt.num(A), fin], ans.values),
			"move-parent-asymptote": method(["y = B/x has asymptotes x = 0 and y = 0; x + d moves the vertical one to x = −d, so d = %s." % Fmt.num(Q.new(s.d)),
				"The horizontal asymptote is y = a, so a = %s." % Fmt.num(A), fin], ans.values),
		}})
	return out


func u_constant_from_intercept(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var by_y := rng.chance(0.5)
	var k := Q.new(s.b)
	var ans := _num_ans("k = ", k)
	var shown := "f(x) = (%sx + k)/(%s)" % [Fmt.lead(s.a), den(s)]
	var given: String
	var wrong_k: Q
	var step_given: String
	var step_solve: String
	if by_y:
		given = "crosses the y-axis at %s" % Fmt.point(0, s.yi)
		wrong_k = Q.new(-s.a).mul(s.yi)
		step_given = "The graph crosses the y-axis at %s, so f(0) = %s." % [Fmt.point(0, s.yi), Fmt.num(s.yi)]
		step_solve = "f(0) = k/%s = %s, so k = %s × %s = %s." % [Fmt.num(Q.new(s.d)), Fmt.num(s.yi), Fmt.num(s.yi), Fmt.num(Q.new(s.d)), Fmt.num(k)]
	else:
		given = "crosses the x-axis at %s" % Fmt.point(s.xi, 0)
		wrong_k = s.xi.mul(Q.new(s.d))
		step_given = "The graph crosses the x-axis at %s, so f(%s) = 0." % [Fmt.point(s.xi, 0), Fmt.num(s.xi)]
		step_solve = "The numerator is zero there: %s + k = 0, so k = %s." % ["%s × %s" % [Fmt.num(Q.new(s.a)), Fmt.paren(s.xi)], Fmt.num(k)]
	var lines: Array = [shown]
	if rep == "equation":
		lines.append("The graph of f %s." % given)
	else:
		lines = ["A function is f(x) = (%sx + k)/(%s), and its graph %s." % [Fmt.lead(s.a), den(s), given]]
	var fin := "So " + Answer.text(ans) + "."
	return {
		"asked": "Find the value of k.", "lines": lines, "answer": ans,
		"wrongs": [wrong({"v": wrong_k}, R_ZERO_YINT)], "generic": [{"v": k.neg()}, {"v": k.add(Q.new(1))}],
		"given": {"by": "y" if by_y else "x"},
		"methods": {"set-equal-zero": method([step_given, step_solve, fin], ans.values)},
	}


## Whether (ax + b)/(x + d) is a real rational function (ad − b ≠ 0), not a constant.
static func eq_ok(a: Variant, b: Variant, d: Variant) -> bool:
	return not Q.of(a).is_zero() and not Q.of(a).mul(Q.of(d)).eq(Q.of(b))


## The options of a pick of equations (or single fractions): [a, b, d] triples that are real
## rational functions, written by `write`, each with its misconception ref.
static func wrong_eqs(cands: Array, write: Callable) -> Array:
	var out: Array = []
	for c in cands:
		if eq_ok(c[0], c[1], c[2]):
			out.append({"values": {"v": write.call(c[0], c[1], c[2])}, "ref": c[3]})
	return out


## "y = (3x − 2)/(x − 2)".
static func eq_text(a: Variant, b: Variant, d: Variant) -> String:
	return "y = " + RationalFunctionSituation.frac(a, b, 1, d)


func u_equation_from_features(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var h: Q = s.h
	var A: Q = s.A
	var B: Q = s.B
	var by_y := rng.chance(0.5)
	var right := eq_text(s.a, s.b, s.d)
	var flipped_b: Q = A.mul(h).neg().sub(B)
	var wrongs := wrong_eqs([[s.a, s.b, -s.d, R_VA_SIGN], [s.a, B, s.d, ""], [s.a, flipped_b, s.d, ""]], eq_text)
	var generic: Array = []
	for g in [[-s.a, s.b, s.d], [s.a, s.b + 1, s.d], [s.a + 1, s.b, s.d], [s.a, s.b + 2, s.d], [s.a + 2, s.b, s.d]]:
		if eq_ok(g[0], g[1], g[2]):
			generic.append(eq_text(g[0], g[1], g[2]))
	var out := LogFunctionViews.choice(right, wrongs, generic)
	var given_pt := Fmt.point(0, s.yi) if by_y else Fmt.point(s.xi, 0)
	var feat := "vertical asymptote x = %s, horizontal asymptote y = %s, and it crosses the %s-axis at %s" % [Fmt.num(h), Fmt.num(A), "y" if by_y else "x", given_pt]
	var lines: Array = []
	if rep == "words":
		lines = ["A rational function f(x) = (ax + b)/(x + d) has a %s." % feat]
	else:
		lines = ["The graph of f(x) = (ax + b)/(x + d) is shown, with its asymptotes dashed. It crosses the %s-axis at %s." % ["y" if by_y else "x", given_pt]]
	var fin := "So the equation is %s." % right
	var step_b := "At the intercept %s: %s." % [given_pt, ("f(0) = b/%s = %s, so b = %s" % [Fmt.num(Q.new(s.d)), Fmt.num(s.yi), Fmt.num(Q.new(s.b))]) if by_y
		else ("%s × %s + b = 0, so b = %s" % [Fmt.num(Q.new(s.a)), Fmt.paren(s.xi), Fmt.num(Q.new(s.b))])]
	var res: Dictionary = out.answer.values
	out.merge({
		"asked": "Find the equation of f.", "lines": lines,
		"given": {"by": "y" if by_y else "x"},
		"methods": {
			"zero-denominator-and-ratio": method(["The vertical asymptote x = %s means x + d = 0 there, so d = %s. The horizontal asymptote y = %s means a = %s." % [Fmt.num(h), Fmt.num(Q.new(s.d)), Fmt.num(A), Fmt.num(A)], step_b, fin], res),
			"divide-out": method(["Write f as %s with the asymptotes x = %s and y = %s." % ["A + B/(x − h)", Fmt.num(h), Fmt.num(A)], "Use the intercept %s to find B = %s." % [given_pt, Fmt.num(B)], "Combine into one fraction. " + fin], res),
			"move-parent-asymptote": method(["y = B/x moved to the asymptotes x = %s and y = %s is y = %s + B/(x − %s)." % [Fmt.num(h), Fmt.num(A), Fmt.num(A), Fmt.num(h)], "The intercept %s gives B = %s." % [given_pt, Fmt.num(B)], "As one fraction: " + fin], res),
			"set-equal-zero": method(["The asymptotes give a = %s and d = %s." % [Fmt.num(A), Fmt.num(Q.new(s.d))], step_b, fin], res),
		}})
	if rep == "graph":
		out.graph = RationalCards.plot(RationalCards.triple_of(s), [[(0.0 if by_y else s.xi.to_float()), (s.yi.to_float() if by_y else 0.0), given_pt]])
	return out


func u_range_from_asymptote(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h := Fmt.num(s.h)
	var A := Fmt.num(s.A)
	var right := "domain x ≠ %s, range y ≠ %s" % [h, A]
	var wrongs := [
		{"values": {"v": "domain x ≠ %s, range x ≠ %s" % [h, A]}, "ref": R_RANGE_X},
		{"values": {"v": "domain x ≠ %s, range all real y" % h}, "ref": R_RANGE_INCL},
	]
	var out := LogFunctionViews.choice(right, wrongs, ["domain x ≠ %s, range y ≠ %s" % [A, h], "domain all real x, range y ≠ %s" % A])
	var fin := "So the %s." % right
	var lines: Array = [fx(s)] if rep == "equation" else ["The graph of y = f(x) is shown, with its asymptotes dashed."]
	out.merge({
		"asked": "Write down the domain and the range of f.", "lines": lines,
		"methods": {
			"vertex-or-asymptote": method(["The vertical asymptote is x = %s: f is not defined there, so the domain is x ≠ %s." % [h, h],
				"The horizontal asymptote is y = %s, which the curve never reaches, so the range is y ≠ %s." % [A, A], fin], out.answer.values),
			"graph-height": method(["The curve has a gap at x = %s, so x ≠ %s." % [h, h],
				"Its branches cover every height except the asymptote's, y = %s, so y ≠ %s." % [A, A], fin], out.answer.values),
		}})
	if rep == "graph":
		out.graph = RationalCards.plot(RationalCards.triple_of(s))
	return out


# ── fn-rational-sketch ───────────────────────────────────────

## The three wrong cards of a sketch question: each changes one thing of the triple t
## (RationalCards.wrong_triple). The flipped one is always there (SL2.8.sketch-rational#0);
## two of the others come with it, drawn from `pool`.
func _wrong_cards(t: Array, rng: Seeded, pool: Array = ["zero-at-h", "through", "mirrored", "swapped"]) -> Array:
	var names := ["flipped"] + rng.shuffled(pool).slice(0, 2)
	var h := Fmt.num(Q.of(_nice(t[2])))
	var out: Array = []
	for mk in names:
		var why: String
		var ref := ""
		var across := false
		match mk:
			"flipped":
				ref = R_CORNERS
				why = "its branches are in the other two corners: the stretch has the wrong sign"
			"zero-at-h":
				ref = R_ZERO_AT_H
				why = "it crosses the x-axis at x = %s, where the denominator is zero" % h
			"through":
				ref = R_ACROSS
				why = "a line is drawn across the vertical asymptote, x = %s" % h
				across = true
			"mirrored":
				why = "its vertical asymptote is x = %s, not x = %s" % [Fmt.num(Q.of(_nice(-t[2]))), h]
			"swapped":
				why = "its asymptotes are the wrong way round: x = %s and y = %s" % [Fmt.num(Q.of(_nice(t[0]))), h]
		var wt := RationalCards.wrong_triple(t, mk)
		out.append({"graph": RationalCards.card(wt, across), "ref": ref, "mistake": mk, "why": why})
	return out


## A float that is a whole number, half or third as the Q it stands for (for text).
static func _nice(x: float) -> Variant:
	for den in [1, 2, 3, 4, 5, 6, 7, 8, 9]:
		if absf(x * den - roundf(x * den)) < 1e-9:
			return Q.new(roundi(x * den), den)
	return Q.new(roundi(x * 1000.0), 1000)


func _sketch(asked: String, lines: Array, s: Dictionary, rng: Seeded, methods: Dictionary, table: Variant = null) -> Dictionary:
	var t := RationalCards.triple_of(s)
	var p := GdcKit.pick(RationalCards.card(t), _wrong_cards(t, rng), rng)
	var fin := "So the graph is %s." % p.answer.values.v
	var out := {"asked": asked, "lines": lines, "answer": p.answer, "graphs": p.graphs, "table": table, "methods": {}}
	for a in methods:
		var steps: Array = methods[a].duplicate()
		steps.append(fin)
		out.methods[a] = method(steps, p.answer.values)
	return out


## Steps shared by the sketch methods.
static func feature_steps(s: Dictionary) -> Array:
	return ["The vertical asymptote is x = %s and the horizontal asymptote is y = %s." % [Fmt.num(s.h), Fmt.num(s.A)],
		"It crosses the x-axis at %s and the y-axis at %s." % [Fmt.point(s.xi, 0), Fmt.point(0, s.yi)]]


static func split_steps(s: Dictionary) -> Array:
	var corners := "top right and bottom left" if s.B.sign() > 0 else "top left and bottom right"
	return ["Write f as %s." % split_text(s).trim_prefix("f(x) = "),
		"It is y = 1/x stretched by %s and moved to the asymptotes x = %s, y = %s, with the branches in the %s corners." % [Fmt.num(s.B), Fmt.num(s.h), Fmt.num(s.A), corners]]


func u_sketch_from_equation(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var methods := {
		"asymptotes-and-intercepts": feature_steps(s) + ["Only one graph has those asymptotes and intercepts."],
		"transform-reciprocal": split_steps(s),
		"gdc-transfer": ["Graph y = f(x) on the GDC (no GDC on Paper 1, so this is a check).", "It shows the two branches with the asymptotes %s and %s. The GDC may join the branches with a steep line: ignore it." % ["x = " + Fmt.num(s.h), "y = " + Fmt.num(s.A)]],
	}
	return _sketch("Which graph is y = %s?" % RationalFunctionSituation.text(s), [fx(s)], s, rng, methods)


func u_sketch_from_transformed(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var form := RationalFunctionSituation.split(s.A, s.B, s.h)
	var methods := {"transform-reciprocal": split_steps(s) + ["Its zero is at %s and it meets the y-axis at %s." % [Fmt.num(s.xi), Fmt.num(s.yi)]]}
	return _sketch("Which graph is y = %s?" % form, ["f(x) = " + form], s, rng, methods)


## Values of f at x = h ± 2, ± 1, ± 0.5 as a table (exact: B is a whole number).
func _near_table(s: Dictionary) -> Dictionary:
	var xs: Array = []
	var ys: Array = []
	for off in [Q.new(-2), Q.new(-1), Q.new(-1, 2), Q.new(1, 2), Q.new(1), Q.new(2)]:
		var x: Q = s.h.add(off)
		xs.append(Fmt.dec(x))
		ys.append(Fmt.dec(s.A.add(s.B.div(off))))
	return {"rows": [["x", xs], ["f(x)", ys]]}


func u_sketch_from_description(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var methods := {"asymptotes-and-intercepts": ["Mark the asymptotes x = %s and y = %s, and the intercepts %s and %s." % [Fmt.num(s.h), Fmt.num(s.A), Fmt.point(s.xi, 0), Fmt.point(0, s.yi)],
		"Only one graph has the branches through those points."]}
	if rep == "table":
		methods["asymptotes-and-intercepts"] = ["The values blow up either side of x = %s, so x = %s is the vertical asymptote." % [Fmt.num(s.h), Fmt.num(s.h)],
			"The values get close to %s one way, so y = %s is the horizontal asymptote, and the signs show which corners the branches are in." % [Fmt.num(s.A), Fmt.num(s.A)]]
		return _sketch("The table shows values of a rational function f. Which graph is it?", ["The table shows values of f."], s, rng, methods, _near_table(s))
	var lines := ["A rational function has the vertical asymptote x = %s and the horizontal asymptote y = %s. Its graph crosses the axes at %s and %s." % [Fmt.num(s.h), Fmt.num(s.A), Fmt.point(s.xi, 0), Fmt.point(0, s.yi)]]
	return _sketch("Which graph is it?", lines, s, rng, methods)


## The corners the branches sit in, from one point of the curve (px, py) and the asymptotes.
static func corners(s: Dictionary, px: Q, py: Q) -> String:
	var right := px.lt(s.h) == false
	var top: bool = s.A.lt(py)
	return "top right and bottom left" if right == top else "top left and bottom right"


func u_branch_corners(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var px := Q.new(0)
	var py: Q = s.yi
	var lines: Array = [fx(s)]
	var table: Variant = null
	var look := "the y-intercept %s" % Fmt.point(0, s.yi)
	match rep:
		"words":
			var tt: int = [-1, 1, 2, -2][rng.int_in(0, 3)]
			if s.B.n % tt != 0:
				tt = 1 if rng.chance(0.5) else -1
			px = s.h.add(Q.new(tt))
			py = s.A.add(s.B.div(Q.new(tt)))
			lines = ["A rational function has the vertical asymptote x = %s and the horizontal asymptote y = %s. Its graph passes through %s." % [Fmt.num(s.h), Fmt.num(s.A), Fmt.point(px, py)]]
			look = "the point %s" % Fmt.point(px, py)
		"table":
			lines = ["The table shows values of f. The asymptotes are x = %s and y = %s." % [Fmt.num(s.h), Fmt.num(s.A)]]
			table = _near_table(s)
			px = s.h.add(Q.new(1))
			py = s.A.add(s.B)
			look = "the point %s in the table" % Fmt.point(px, py)
	var right := corners(s, px, py)
	var other := "top left and bottom right" if right == "top right and bottom left" else "top right and bottom left"
	var wrongs := [{"values": {"v": other}, "ref": R_CORNERS}]
	var out := LogFunctionViews.choice(right, wrongs, ["top left and top right", "bottom left and bottom right"])
	var side := "right of" if not px.lt(s.h) else "left of"
	var vert := "above" if s.A.lt(py) else "below"
	var fin := "So the branches are in the %s corners." % right
	var res: Dictionary = out.answer.values
	out.merge({
		"asked": "The asymptotes split the plane into four corners. In which two corners are the branches of the graph?", "lines": lines, "table": table,
		"given": {"px": px, "py": py},
		"methods": {
			"asymptotes-and-intercepts": method(["Use %s: it is %s the vertical asymptote and %s the horizontal asymptote." % [look, side, vert],
				"A branch passes through that corner, and the other branch is in the opposite one.", fin], res),
			"transform-reciprocal": method(["f is a stretched and moved y = 1/x: %s." % split_text(s), "The stretch is %s, which is %s, so the branches are in the %s corners." % [Fmt.num(s.B), "positive" if s.B.sign() > 0 else "negative", right], fin], res),
		}})
	return out


## An equation of a monic function from its triple of whole numbers: y = (ax + b)/(x + d).
static func eq_of(A: float, B: float, h: float) -> String:
	return eq_text(roundi(A), roundi(B - A * h), roundi(-h))


func u_equation_from_sketch(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var t := RationalCards.triple_of(s)
	var right := eq_of(t[0], t[1], t[2])
	var names := ["flipped", "zero-at-h", "mirrored"]
	var refs := {"flipped": R_CORNERS, "zero-at-h": R_ZERO_AT_H, "mirrored": ""}
	var wrongs: Array = []
	for mk in names:
		var wt := RationalCards.wrong_triple(t, mk)
		wrongs.append({"values": {"v": eq_of(wt[0], wt[1], wt[2])}, "ref": refs[mk]})
	var out := LogFunctionViews.choice(right, wrongs, [eq_of(t[0], t[1], t[2] + 1.0)])
	var fin := "So the equation is %s." % right
	var res: Dictionary = out.answer.values
	var by_y := rng.chance(0.5)
	var mark := [0.0, s.yi.to_float(), Fmt.point(0, s.yi)] if by_y else [s.xi.to_float(), 0.0, Fmt.point(s.xi, 0)]
	out.merge({
		"asked": "Which equation does the graph show?", "lines": ["The graph is of the form y = (ax + b)/(x + d). Its asymptotes are dashed, and one intercept is marked."],
		"graph": RationalCards.plot(t, [mark]), "given": {"by": "y" if by_y else "x"},
		"methods": {"asymptotes-and-intercepts": method(["The dashed lines are x = %s and y = %s, so d = %s and a = %s." % [Fmt.num(s.h), Fmt.num(s.A), Fmt.num(Q.new(s.d)), Fmt.num(s.A)],
			"The marked point %s gives b = %s." % [mark[2], Fmt.num(Q.new(s.b))], fin], res)}})
	return out


## f(x) = A + B/(x − h) as a Q.
static func f_q(s: Dictionary, x: Q) -> Q:
	return s.A.add(s.B.div(x.sub(s.h)))


## The solution set of f(x) rel k: its pieces as written, and the boundary x-values in
## order. f(x) − k has the sign of (A − k)(x − xk)/(x − h): the middle part is one sign and
## the outer parts the other.
static func ineq_set(s: Dictionary, rel: String) -> Array:
	var k: Q = s.k
	var xk: Q = s.h.add(s.B.div(k.sub(s.A)))
	var lo: Q = xk if xk.lt(s.h) else s.h
	var hi: Q = s.h if xk.lt(s.h) else xk
	var strict := rel.replace("≥", ">").replace("≤", "<")
	var inc := rel in ["≥", "≤"]
	var test: Q = lo.sub(Q.new(1))
	var fv := f_q(s, test)
	var outer: bool = fv.lt(k) if strict == "<" else k.lt(fv)
	var lo_in := inc and lo.eq(xk)
	var hi_in := inc and hi.eq(xk)
	if outer:
		return ["x %s %s" % ["≤" if lo_in else "<", Fmt.num(lo)], "x %s %s" % ["≥" if hi_in else ">", Fmt.num(hi)]]
	return ["%s %s x %s %s" % [Fmt.num(lo), "≤" if lo_in else "<", "≤" if hi_in else "<", Fmt.num(hi)]]


static func ineq_text(pieces: Array) -> String:
	return " or ".join(pieces)


func u_inequality_from_sketch(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rel: String = s.rel
	var k: Q = s.k
	var xk: Q = s.h.add(s.B.div(k.sub(s.A)))
	var lo: Q = xk if xk.lt(s.h) else s.h
	var hi: Q = s.h if xk.lt(s.h) else xk
	var pieces := ineq_set(s, rel)
	var right := ineq_text(pieces)
	var flip: String = {">": "<", "<": ">", "≥": "≤", "≤": "≥"}[rel]
	var below := ineq_text(ineq_set(s, flip))
	var wrongs: Array = [
		{"values": {"v": "x = %s or x = %s" % [Fmt.num(lo), Fmt.num(hi)]}, "ref": R_INEQ_POINTS},
		{"values": {"v": below}, "ref": R_INEQ_BELOW},
	]
	if pieces.size() == 2:
		wrongs.append({"values": {"v": pieces[1]}, "ref": R_INEQ_ONE})
	var out := LogFunctionViews.choice(right, wrongs, ["x ≠ %s" % Fmt.num(s.h), "x > %s" % Fmt.num(lo), "x < %s" % Fmt.num(hi)])
	var kt := Fmt.num(k)
	var what := "f(x) %s %s" % [rel, kt]
	var fin := "So the solution is %s." % right
	var res: Dictionary = out.answer.values
	var lines: Array = [fx(s)]
	if rep == "graph":
		lines = [fx(s), "Its graph is shown, with the asymptotes dashed."]
	var bound := "f(x) = %s at x = %s, and f is not defined at x = %s" % [kt, Fmt.num(xk), Fmt.num(s.h)]
	var three := "These two values split the x-axis into three parts. Testing a point in each shows where f(x) %s %s." % [rel, kt]
	out.merge({
		"asked": "Solve the inequality %s." % what, "lines": lines,
		"methods": {
			"asymptotes-and-intercepts": method(["The boundaries are %s." % bound, "On the sketch the curve is on the %s side of %s where %s." % ["right" if pieces.size() == 2 else "correct", "y = " + kt, what], fin], res),
			"intersections-then-read": method(["Draw y = %s on the sketch: it meets the curve at x = %s, and the curve has its gap at x = %s." % [kt, Fmt.num(xk), Fmt.num(s.h)], "Read off where the curve is %s the line: %s." % ["above" if strict_gt(rel) else "below", right], fin], res),
			"analytic-boundary": method(["Solve f(x) = %s: x = %s. The asymptote x = %s is a boundary too: f is not defined there." % [kt, Fmt.num(xk), Fmt.num(s.h)], three, fin], res),
		}})
	if rep == "graph":
		out.graph = RationalCards.plot(RationalCards.triple_of(s))
	return out


static func strict_gt(rel: String) -> bool:
	return rel in [">", "≥"]


func u_count_with_horizontal(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: Q = s.hk
	var count := 0 if s.hequal else 1
	var ans := _count_ans(count)
	var wrongs: Array = []
	var generic: Array = []
	if s.hequal:
		wrongs.append(wrong({"v": Q.new(1)}, R_ASYMPTOTE_SOLVES))
		generic = [{"v": Q.new(2)}, {"v": Q.new(3)}]
	else:
		generic = [{"v": Q.new(0)}, {"v": Q.new(2)}, {"v": Q.new(3)}]
	var fin := "So " + Answer.text(ans) + "."
	var steps := ["Draw the line y = %s across the graph." % Fmt.num(k)]
	if s.hequal:
		steps.append("It is the horizontal asymptote, y = %s: the curve gets as close as it likes to it but never meets it." % Fmt.num(s.A))
	else:
		steps.append("It is not the asymptote y = %s, so it cuts exactly one branch once." % Fmt.num(s.A))
	steps.append(fin)
	return {
		"asked": "The graph of y = f(x) is shown with the line y = %s. How many solutions does f(x) = %s have?" % [Fmt.num(k), Fmt.num(k)],
		"lines": ["The graph of y = f(x) and the line y = %s are shown." % Fmt.num(k)], "answer": ans, "wrongs": wrongs, "generic": generic,
		"graph": RationalCards.plot(RationalCards.triple_of(s), [], true, [[k.to_float(), "y = " + Fmt.num(k)]]) if not s.hequal else RationalCards.plot(RationalCards.triple_of(s), [], false, [[k.to_float(), "y = " + Fmt.num(k)]]),
		"methods": {"horizontal-line-sweep": method(steps, ans.values)},
	}


static func _count_ans(n: int) -> Dictionary:
	var ans := Answer.make("number", {"v": Q.new(n)}, {}, "number of solutions = ")
	ans.exact = true
	return ans


func u_k_for_no_solution(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A := Fmt.num(s.A)
	var right := "k = " + A
	var wrongs := [{"values": {"v": "no value of k: every horizontal line meets the graph, even y = %s" % A}, "ref": R_ASYMPTOTE_SOLVES}]
	var out := LogFunctionViews.choice(right, wrongs, ["k = " + Fmt.num(s.h), "k = " + Fmt.num(s.yi), "k = " + Fmt.num(s.xi), "k = " + Fmt.num(s.A.neg()), "k = 0", "k = " + Fmt.num(s.A.add(Q.new(1)))])
	var fin := "So f(x) = k has no solution when %s." % right
	var res: Dictionary = out.answer.values
	var lines: Array = [fx(s)] if rep == "equation" else ["The graph of y = f(x) is shown, with its asymptotes dashed."]
	out.merge({
		"asked": "For which value of k does f(x) = k have no solution?", "lines": lines,
		"methods": {
			"horizontal-line-sweep": method(["Slide the line y = k up and down: it cuts the graph once at every height except one.", "The curve never reaches its horizontal asymptote y = %s, so the line y = %s misses it." % [A, A], fin], res),
			"turning-point-boundaries": method(["f has no turning points, so no value of k is a boundary of that kind.", "The only value f never takes is its horizontal asymptote, y = %s." % A, fin], res),
		}})
	if rep == "graph":
		out.graph = RationalCards.plot(RationalCards.triple_of(s))
	return out


## The line y = mx + n as written: "y = −x + 3", "y = 2x".
static func line_text(m: int, n: int) -> String:
	return "y = " + Fmt.poly([m, n])


## A curve sampled across the plot: [[x, y], ...] (drawn in the second colour).
static func _sampled(fn: Callable) -> Array:
	return Plot.sample(fn, RationalCards.WIN[0], RationalCards.WIN[1])


func u_count_with_line(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: int = s.m
	var n: int = s.n
	var count: int = s.lcount
	var ans := _count_ans(count)
	var qa: int = m * s.c
	var qb: int = m * s.d + n * s.c - s.a
	var qc: int = n * s.d - s.b
	var disc := qb * qb - 4 * qa * qc
	var wrongs: Array = []
	var generic: Array = []
	match count:
		1:
			wrongs.append(wrong({"v": Q.new(2)}, R_TANGENT))
			generic = [{"v": Q.new(0)}, {"v": Q.new(3)}]
		2:
			generic = [{"v": Q.new(1)}, {"v": Q.new(0)}, {"v": Q.new(3)}]
		_:
			generic = [{"v": Q.new(1)}, {"v": Q.new(2)}, {"v": Q.new(3)}]
	var fin := "So " + Answer.text(ans) + "."
	var verdict := "Δ > 0: two meeting points" if count == 2 else ("Δ = 0: the line touches the curve once, a tangent" if count == 1 else "Δ < 0: no meeting points")
	var quad := "%s = 0" % Fmt.poly([qa, qb, qc])
	var fn_line := func(x: float) -> float: return m * x + n
	var lines: Array = [fx(s)]
	var graph: Variant = null
	if rep == "graph":
		lines = ["The graph of y = f(x) is shown, with the line %s." % line_text(m, n)]
		graph = RationalCards.plot(RationalCards.triple_of(s))
		graph.curves = graph.curves + [_sampled(fn_line)]
		graph.sand_from = graph.curves.size() - 1
	var methods := {
		"discriminant": method(["Put the line equal to the curve and clear the fraction: (%s)(%s) = %s, which is %s." % [Fmt.poly([m, n]), den(s), num_(s), quad],
			"Δ = %s² − 4(%s)(%s) = %s." % [Fmt.num(Q.new(qb)), Fmt.num(Q.new(qa)), Fmt.num(Q.new(qc)), Fmt.num(Q.new(disc))], verdict + ".", fin], ans.values),
		"gdc-graph": method(["Graph y = f(x) and %s on the GDC." % line_text(m, n), "Count the points where the line meets the curve, not across the gap at x = %s." % Fmt.num(s.h), fin], ans.values),
	}
	return {
		"asked": "How many times does the line %s meet the graph of y = f(x)?" % line_text(m, n), "lines": lines, "answer": ans,
		"wrongs": wrongs, "generic": generic, "graph": graph, "methods": methods,
	}


func u_count_with_curve(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var r: int = s.r
	var count: int = s.ccount
	var dom: String = s.dom
	var ans := _count_ans(count)
	var wrongs: Array = []
	var generic: Array = []
	if dom != "":
		wrongs.append(wrong({"v": Q.new(s.count_all)}, R_DOMAIN))
	for n in [0, 1, 2, 3]:
		if n != count and not (dom != "" and n == s.count_all):
			generic.append({"v": Q.new(n)})
	var curve := "y = " + Fmt.poly([p, q, r])
	var fn_curve := func(x: float) -> float: return p * x * x + q * x + r
	var where := " for %s" % dom if dom != "" else ""
	var lines: Array = [fx(s)]
	var graph: Variant = null
	if rep == "graph":
		lines = ["The graph of y = f(x) is shown, with the curve %s." % curve]
		graph = RationalCards.plot(RationalCards.triple_of(s))
		graph.curves = graph.curves + [_sampled(fn_curve)]
		graph.sand_from = graph.curves.size() - 1
	var fin := "So " + Answer.text(ans) + "."
	var steps := ["Graph y = f(x) and %s on the GDC." % curve,
		"Use the intersection tool, or read the graphs: the curves meet %d time%s%s." % [s.count_all, "" if s.count_all == 1 else "s", ", and %d of them have %s" % [count, dom] if dom != "" else ""], fin]
	return {
		"asked": "How many times does the parabola %s meet the graph of y = f(x)%s?" % [curve, where], "lines": lines, "answer": ans,
		"wrongs": wrongs, "generic": generic, "graph": graph,
		"methods": {"gdc-graph": method(steps, ans.values)},
	}


func u_reciprocal_of_f(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var pp := p2(s)
	var tf := RationalCards.triple_of(s)
	var tg := RationalCards.triple(s.c, s.d, s.a, s.b)
	var pool := [
		{"graph": RationalCards.card(tf), "ref": "", "mistake": "same", "why": "it is the graph of f itself, not of 1/f"},
		{"graph": RationalCards.card(RationalCards.wrong_triple(tg, "negated")), "ref": "", "mistake": "negated", "why": "it is −1/f: the branches are in the wrong corners"},
		{"graph": RationalCards.card(tg, true), "ref": R_ACROSS, "mistake": "through", "why": "a line is drawn across its vertical asymptote"},
	]
	var p := GdcKit.pick(RationalCards.card(tg), pool, rng)
	var fin := "So the graph is %s." % p.answer.values.v
	var rec := RationalFunctionSituation.frac(s.c, s.d, s.a, s.b)
	var vas := work(s.xi, pp)
	var lines: Array = [fx(s)]
	var graph: Variant = null
	if rep == "graph":
		lines = ["The graph of y = f(x) is shown, with its asymptotes dashed."]
		graph = RationalCards.plot(tf)
	var res: Dictionary = p.answer.values
	return {
		"asked": "Which graph is y = 1/f(x)?", "lines": lines, "answer": p.answer, "graphs": p.graphs, "graph": graph,
		"methods": {
			"asymptotes-and-intercepts": method(["1/f has a vertical asymptote where f = 0: x = %s. It has a zero where f has its asymptote, x = %s." % [vas, work(s.h, pp)],
				"Its horizontal asymptote is y = 1/%s, and 1/f = %s." % [work(s.A, pp), rec], fin], res),
			"gdc-transfer": method(["Graph y = f(x) and y = 1/f(x) on the GDC.", "The GDC can join the two branches with a steep line that is not part of the curve: ignore it. 1/f has the vertical asymptote x = %s." % vas, fin], res),
		},
	}


func u_parent_reciprocal(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var k: int = s.pk
	var t: Array = [0.0, float(k), 0.0]
	var names := ["negated"] + rng.shuffled(["through", "touching", "other-k"]).slice(0, 2)
	var wrongs: Array = []
	for mk in names:
		match mk:
			"negated":
				wrongs.append({"graph": RationalCards.card([0.0, -float(k), 0.0]), "ref": R_PARENT_QUADRANTS, "mistake": "negated", "why": "its branches are in the second and fourth quadrants: that is y = −%s/x" % str(k) if k != 1 else "its branches are in the second and fourth quadrants: that is y = −1/x"})
			"through":
				wrongs.append({"graph": RationalCards.card(t, true), "ref": R_PARENT_AXES, "mistake": "through", "why": "the branches are joined across the y-axis"})
			"touching":
				var bell := func(x: float) -> float: return k / (x * x + 1.0)
				var g := GdcKit.card([GdcKit.curve(bell, -8.0, 8.0)], [], RationalCards.WIN, [], [])
				g.one_colour = true
				wrongs.append({"graph": g, "ref": R_PARENT_AXES, "mistake": "touching", "why": "the curve meets the y-axis, but y = %d/x never does" % k})
			"other-k":
				wrongs.append({"graph": RationalCards.card([0.0, float(5 - k), 0.0]), "ref": "", "mistake": "other-k", "why": "it is the graph of y = %d/x, a different stretch" % (5 - k)})
	var p := GdcKit.pick(RationalCards.card(t), wrongs, rng)
	var name := "y = %d/x" % k
	var fin := "So the graph is %s." % p.answer.values.v
	var table: Variant = null
	var asked := "Which graph is %s?" % name
	var lines: Array = []
	if rep == "table":
		var xs := [-4, -2, -1, 1, 2, 4]
		table = {"rows": [["x", xs.map(func(x): return Fmt.num(x))], ["y", xs.map(func(x): return Fmt.dec(Q.new(k, x)))]]}
		asked = "The table shows y = k/x for a whole number k. Which graph is it?"
		lines = ["The table shows values of y = k/x."]
	else:
		lines = [name]
	var res: Dictionary = p.answer.values
	return {
		"asked": asked, "lines": lines, "answer": p.answer, "graphs": p.graphs, "table": table,
		"given": {"k": k},
		"methods": {"table-of-values": method(["Make a table of values: x and −x give y of opposite signs, so the branches are in the first and third quadrants.", "y gets large near x = 0 and small for large x, but is never 0: the curve never meets the axes.", fin], res)},
	}


func u_reciprocal_self_inverse(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.pk
	var kx := "%d/x" % k if k != 1 else "1/x"
	var right := "f⁻¹(x) = %s, because swapping x and y gives the same equation" % kx
	var wrongs := [
		{"values": {"v": "f⁻¹(x) = %s, because (%s) × x = %d" % [kx, kx, k]}, "ref": R_SELF_PRODUCT},
		{"values": {"v": "f⁻¹(x) = −%s, because the inverse has the opposite sign" % kx}, "ref": ""},
	]
	var out := LogFunctionViews.choice(right, wrongs, ["f⁻¹(x) = x/%d, because dividing undoes multiplying" % k if k != 1 else "f⁻¹(x) = x, because dividing undoes multiplying"])
	var fin := "So " + right + "."
	var res: Dictionary = out.answer.values
	var name := "f(x) = " + kx
	var lines: Array = [name] if rep == "equation" else ["The graph of f(x) = %s is shown." % kx]
	out.merge({
		"asked": "Find the inverse of f(x) = %s, and say why." % kx, "lines": lines, "given": {"k": k},
		"methods": {
			"reflect-in-y-equals-x": method(["The inverse is the reflection of the graph in the line y = x, which swaps x and y.", "The graph of y = %s is symmetrical in the line y = x, so it does not change." % kx, fin], res),
			"swap-and-solve": method(["Swap x and y: x = %d/y." % k, "Solve for y: y = %s, the same function." % kx, fin], res),
		}})
	if rep == "graph":
		out.graph = RationalCards.plot([0.0, float(k), 0.0], [], false)
	return out


# ── fn-ext-transformed-reciprocal ────────────────────────────

## "3 right and 2 up", "1 left and 4 down": the translation (h, A).
static func vec_text(h: Variant, A: Variant) -> String:
	var hq := Q.of(h)
	var aq := Q.of(A)
	return "%s %s and %s %s" % [hq.abs_q().text(), "right" if hq.sign() > 0 else "left", aq.abs_q().text(), "up" if aq.sign() > 0 else "down"]


## The right-hand side of a split numerator: "3(x − 2) + 4".
static func numerator_split(A: Variant, h: Variant, B: Variant) -> String:
	return Fmt.lead(A) + Fmt.factor(h) + Fmt.plus(B)


func u_split_to_form(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A: Q = s.A
	var B: Q = s.B
	var h: Q = s.h
	var ans := named_ans(["A", "B"], [A, B])
	var fin := "So " + Answer.text(ans) + "."
	var b := Q.new(s.b)
	var res: Dictionary = ans.values
	var form := RationalFunctionSituation.split(A, B, h)
	var bad := numerator_split(A, h, b)
	var spot := {
		"lines": ["%s = %s" % [num_(s), bad], "%s = %s" % [RationalFunctionSituation.text(s), "%s/%s" % [RationalFunctionSituation._wrap(Fmt.lead(A) + Fmt.factor(h) + Fmt.plus(b)), RationalFunctionSituation._wrap(den(s))]],
			"%s/%s = %s" % [RationalFunctionSituation._wrap(Fmt.lead(A) + Fmt.factor(h) + Fmt.plus(b)), RationalFunctionSituation._wrap(den(s)), RationalFunctionSituation.split(A, b, h)],
			"so A = %s and B = %s" % [Fmt.num(A), Fmt.num(b)]],
		"bad": 0, "ref": R_SPLIT_WRONG, "why": "%s = %s, so the constant is %s, not %s" % [num_(s), numerator_split(A, h, B), Fmt.num(B), Fmt.num(b)]}
	return {
		"asked": "Write f(x) in the form A + B/(x − h): find A and B.", "lines": [fx(s)], "answer": ans, "spot": spot,
		"wrongs": [wrong({"v0": A, "v1": b}, R_SPLIT_WRONG)], "generic": [{"v0": A, "v1": B.neg()}, {"v0": B, "v1": A}],
		"methods": {
			"split-numerator": method(["Write the numerator using the denominator: %s = %s." % [num_(s), numerator_split(A, h, B)], "So f(x) = %s." % form, fin], res),
			"compare-coefficients": method(["Let (%s)/(%s) = A + B/(x − h) = (A(x − h) + B)/(x − h)." % [num_(s), den(s)],
				"The x terms give A = %s, and the constants give −Ah + B = %s, so B = %s." % [Fmt.num(A), Fmt.num(b), Fmt.num(B)], fin], res),
			"read-asymptotes": method(["The horizontal asymptote y = %s gives A = %s, and the vertical x = %s gives h = %s." % [Fmt.num(A), Fmt.num(A), Fmt.num(h), Fmt.num(h)],
				"B needs a point: f(0) = %s, and A + B/(0 − %s) = %s gives B = %s." % [Fmt.num(s.yi), Fmt.paren(h), Fmt.num(s.yi), Fmt.num(B)], fin], res),
		},
	}


func u_split_scaled(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A: Q = s.A
	var k: Q = s.kk
	var ans := named_ans(["A", "k"], [A, k])
	var fin := "So " + Answer.text(ans) + "."
	var res: Dictionary = ans.values
	var form := "%s%s/(%s)" % [Fmt.num(A), Fmt.plus(k), den(s)]
	var b := Q.new(s.b)
	return {
		"asked": "Write f(x) in the form A + k/(%s): find A and k." % den(s), "lines": [fx(s)], "answer": ans,
		"wrongs": [wrong({"v0": A, "v1": b}, R_SPLIT_WRONG)], "generic": [{"v0": A, "v1": k.neg()}, {"v0": Q.new(s.a), "v1": k}],
		"methods": {
			"split-numerator": method(["Write the numerator using the denominator: %s = %s(%s) %s." % [num_(s), Fmt.num(A), den(s), Fmt.plus(k).strip_edges()], "So f(x) = %s." % form, fin], res),
			"compare-coefficients": method(["Let (%s)/(%s) = A + k/(%s) = (A(%s) + k)/(%s)." % [num_(s), den(s), den(s), den(s), den(s)],
				"The x terms give %s A = %s, so A = %s. The constants give %s A + k = %s, so k = %s." % [Fmt.num(Q.new(s.c)), Fmt.num(Q.new(s.a)), Fmt.num(A), Fmt.num(Q.new(s.d)), Fmt.num(b), Fmt.num(k)], fin], res),
		},
	}


func u_translation_vector(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := vec_text(s.h, s.A)
	var wrongs := [{"values": {"v": vec_text(s.h.neg(), s.A)}, "ref": R_VECTOR_SIGN}]
	var out := LogFunctionViews.choice(right, wrongs, [vec_text(s.A, s.h), vec_text(s.h, s.A.neg()), vec_text(s.h.neg(), s.A.neg())])
	var form := RationalFunctionSituation.split(s.A, s.B, s.h)
	var lines: Array = ["f(x) = " + form]
	if rep == "words":
		lines = ["f is the graph of y = %s/x moved so that its asymptotes are x = %s and y = %s." % [Fmt.num(s.B), Fmt.num(s.h), Fmt.num(s.A)]]
	var fin := "So the translation is %s." % right
	out.merge({
		"asked": "Describe the translation that maps y = %s/x onto the graph of f." % Fmt.num(s.B), "lines": lines,
		"methods": {"read-asymptotes": method(["y = %s/x has the asymptotes x = 0 and y = 0." % Fmt.num(s.B), "f has the asymptotes x = %s and y = %s, so the graph has moved %s." % [Fmt.num(s.h), Fmt.num(s.A), right], fin], out.answer.values)}})
	return out


static func stretch_text(B: Variant, h: Variant, A: Variant) -> String:
	return "stretch by factor %s in the y-direction, then translate %s" % [Fmt.num(B), vec_text(h, A)]


func u_transformation_sequence(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := stretch_text(s.B, s.h, s.A)
	var wrongs := [
		{"values": {"v": "translate %s only, with no stretch" % vec_text(s.h, s.A)}, "ref": R_NO_STRETCH},
		{"values": {"v": stretch_text(s.B, s.h.neg(), s.A)}, "ref": R_VECTOR_SIGN},
	]
	var out := LogFunctionViews.choice(right, wrongs, ["translate %s, then stretch by factor %s in the y-direction" % [vec_text(s.h, s.A), Fmt.num(s.B)], stretch_text(s.B, s.A, s.h)])
	var lines: Array = [fx(s)]
	if rep == "words":
		lines = ["f has the vertical asymptote x = %s and the horizontal asymptote y = %s, and its graph passes through %s." % [Fmt.num(s.h), Fmt.num(s.A), Fmt.point(0, s.yi)]]
	var form := RationalFunctionSituation.split(s.A, s.B, s.h)
	var fin := "So %s." % right
	var steps := ["Write f as %s." % form, "Compared with y = 1/x, the numerator %s stretches it, and x − h and A move it." % Fmt.num(s.B), fin]
	if rep == "words":
		steps = ["The asymptotes are x = %s and y = %s, so f(x) = %s + B/%s." % [Fmt.num(s.h), Fmt.num(s.A), Fmt.num(s.A), Fmt.factor(s.h)],
			"Use %s: B = %s." % [Fmt.point(0, s.yi), Fmt.num(s.B)], fin]
	out.merge({
		"asked": "Describe a stretch and a translation, in order, that map y = 1/x onto the graph of f.", "lines": lines,
		"methods": {"split-numerator": method(steps, out.answer.values)}})
	return out


## (Ax + b)/(x − h) as one fraction: "(3x − 4)/(x − 2)".
static func single_text(a: Variant, b: Variant, d: Variant) -> String:
	return RationalFunctionSituation.frac(a, b, 1, d)


func u_combine_to_single(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A: Q = s.A
	var B: Q = s.B
	var h: Q = s.h
	var right := single_text(s.a, s.b, s.d)
	var wrongs := wrong_eqs([[s.a, B, s.d, ""], [s.a, B.sub(A.mul(h)), s.d, ""], [s.a, B.add(A.mul(h)), s.d, ""]], single_text)
	var generic: Array = [RationalFunctionSituation._wrap(Fmt.num(A.add(B))) + "/(" + den(s) + ")"]
	for g in [[s.a, s.b + 1, s.d], [s.a + 1, s.b, s.d], [-s.a, s.b, s.d], [s.a, s.b + 2, s.d], [s.a + 2, s.b, s.d]]:
		if eq_ok(g[0], g[1], g[2]):
			generic.append(single_text(g[0], g[1], g[2]))
	var out := LogFunctionViews.choice(right, wrongs, generic)
	var form := RationalFunctionSituation.split(A, B, h)
	var fin := "So f(x) = %s." % right
	out.merge({
		"asked": "Write f(x) = %s as a single fraction (ax + b)/(x − h)." % form, "lines": ["f(x) = " + form],
		"methods": {"compare-coefficients": method(["Use the common denominator: %s = (%s(%s) %s)/(%s)." % [form, Fmt.num(A), den(s), Fmt.plus(B).strip_edges(), den(s)],
			"Expand the numerator: %s(%s) %s = %s." % [Fmt.num(A), den(s), Fmt.plus(B).strip_edges(), num_(s)], fin], out.answer.values)}})
	return out


func u_form_from_graph(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var A: Q = s.A
	var B: Q = s.B
	var h: Q = s.h
	var ans := named_ans(["A", "B", "h"], [A, B, h])
	var tt: int = [-1, 1, 2, -2][rng.int_in(0, 3)]
	if B.n % tt != 0:
		tt = 1 if rng.chance(0.5) else -1
	var px: Q = h.add(Q.new(tt))
	var py: Q = A.add(B.div(Q.new(tt)))
	var fin := "So " + Answer.text(ans) + "."
	return {
		"asked": "The graph of y = f(x) is shown, with its asymptotes dashed and one point marked. Write f in the form A + B/(x − h): find A, B and h.",
		"lines": ["The graph of y = f(x) is shown."], "answer": ans, "given": {"px": px, "py": py},
		"wrongs": [wrong({"v0": A, "v1": Q.new(1), "v2": h}, R_NO_STRETCH), wrong({"v0": A, "v1": B, "v2": h.neg()}, R_VECTOR_SIGN)],
		"generic": [{"v0": A, "v1": B.neg(), "v2": h}, {"v0": h, "v1": B, "v2": A}],
		"graph": RationalCards.plot(RationalCards.triple_of(s), [[px.to_float(), py.to_float(), Fmt.point(px, py)]]),
		"methods": {"read-asymptotes": method(["The dashed lines are x = %s and y = %s, so h = %s and A = %s." % [Fmt.num(h), Fmt.num(A), Fmt.num(h), Fmt.num(A)],
			"The marked point %s is on f: %s = %s + B/(%s − %s), so B = %s." % [Fmt.point(px, py), Fmt.num(py), Fmt.num(A), Fmt.num(px), Fmt.paren(h), Fmt.num(B)], fin], ans.values)},
	}


func u_form_from_words(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A: Q = s.A
	var B: Q = s.B
	var h: Q = s.h
	var right := single_text(s.a, s.b, s.d)
	var wrongs := wrong_eqs([[s.a, Q.new(1).sub(A.mul(h)), s.d, R_NO_STRETCH], [s.a, B.add(A.mul(h)), s.d, R_VECTOR_SIGN]], single_text)
	var generic: Array = []
	for g in [[s.a, B, s.d], [s.a, B.sub(A.mul(h)), -s.d], [s.a, s.b + 1, s.d], [s.a + 1, s.b, s.d], [s.a, s.b + 2, s.d], [s.a + 2, s.b, s.d]]:
		if eq_ok(g[0], g[1], g[2]):
			generic.append(single_text(g[0], g[1], g[2]))
	var out := LogFunctionViews.choice(right, wrongs, generic)
	var fin := "So f(x) = %s." % right
	var form := RationalFunctionSituation.split(A, B, h)
	out.merge({
		"asked": "Write f as a single fraction (ax + b)/(x − h).",
		"lines": ["The graph of y = 1/x is stretched by factor %s in the y-direction, then translated %s to give f." % [Fmt.num(B), vec_text(h, A)]],
		"methods": {"compare-coefficients": method(["f(x) = %s." % form, "Over the common denominator: (%s(%s) %s)/(%s) = %s." % [Fmt.num(A), den(s), Fmt.plus(B).strip_edges(), den(s), right], fin], out.answer.values)}})
	return out
