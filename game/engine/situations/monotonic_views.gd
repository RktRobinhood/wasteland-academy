class_name MonotonicViews
extends ExtensionViews
## The views on the `monotonic` situation: one builder per unknown of
## t5-increasing-decreasing (FAL-723). An interval is a `form` answer: the student picks
## between or outside and types the two ends, so neither shape is given away. Whether the
## ends are in or out isn't asked: both are accepted in an exam, unless the question is about
## a boundary (a parameter), where the closed form is the answer.
##
## Representations: "equation", "words" (a curve in words), "graph" and "table".

const SI := "SL5.2.increasing-decreasing-intervals#"
const SG := "SL5.2.sign-from-graph#"
const SP := "SL5.2.parameter-for-monotonic#"
const R_Y_VALUES := SI + "0"
const R_F_NOT_DF := SI + "1"
const R_WAY_ROUND := SI + "2"
const R_BELOW_AXIS := SG + "0"
const R_INTERCEPTS := SG + "1"
const R_DISC_F := SP + "0"
const R_TWO_ROOTS := SP + "1"
const R_ONE_SIDE := SP + "2"
const SHAPES := ["between", "outside"]


func needs() -> Dictionary:
	var out := {}
	for u in ["interval-from-equation", "interval-from-table", "quadratic-interval", "interval-from-derivative-graph", "interval-gdc",
			"sign-at-points", "intervals-from-graph", "negative-and-increasing", "parameter-discriminant", "parameter-shift"]:
		out[u] = {"ask": u}
	return out


## The GDC methods are Paper 2. Reading f′'s graph makes both, so the type lands on the
## bank's share; the rest is Paper 1, as most of the bank is.
func papers(unknown: String, _rep: String, angle: String) -> Array:
	if not has(unknown):
		return []
	if unknown == "interval-gdc" or angle in ["gdc-turning-points", "gdc-slider"]:
		return [2]
	return [1, 2] if unknown == "interval-from-derivative-graph" else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = MonotonicSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func interval_text(shape: String, lo: Variant, hi: Variant, v: String = "x", sf: bool = false) -> String:
	var a: String = Fmt.sf(lo) if sf else Fmt.num(lo)
	var b: String = Fmt.sf(hi) if sf else Fmt.num(hi)
	return "%s < %s < %s" % [a, v, b] if shape == "between" else "%s < %s or %s > %s" % [v, a, v, b]


## An interval answer, or (ref) a wrong option like it.
static func interval(shape: String, lo: Variant, hi: Variant, sf: bool = false) -> Dictionary:
	var ql := GdcKit.qf(lo) if sf else Q.of(lo)
	var qh := GdcKit.qf(hi) if sf else Q.of(hi)
	var ans := DifferentiationViews.form(interval_text(shape, lo, hi, "x", sf),
		["x is ", {"pick": "shape", "options": SHAPES}, " ", {"slot": "lo"}, " and ", {"slot": "hi"}], {"shape": shape, "lo": ql, "hi": qh})
	ans.unordered = [["lo", "hi"]]
	ans.exact = not sf
	return ans


static func other(shape: String) -> String:
	return "outside" if shape == "between" else "between"


static func alt_iv(shape: String, lo: Variant, hi: Variant, ref: String = "", sf: bool = false) -> Dictionary:
	return wrong(interval(shape, lo, hi, sf).values, ref)


## "f′(x) = 3x² − 6x − 9", from the coefficients of f.
static func derivative(coeffs: Array) -> String:
	var n := coeffs.size() - 1
	var out: Array = []
	for i in n:
		out.append(Q.of(coeffs[i]).mul(n - i))
	return Fmt.poly(out)


static func fn_text(s: Dictionary) -> String:
	return Fmt.poly(s.coeffs)


static func dec_shape(s: Dictionary) -> String:
	## Where f falls: between the turning points when the leading coefficient is positive.
	var lead: int = s.coeffs[0]
	var between_falls: bool = lead > 0 if s.fam == "cubic" else false
	if s.want == "decreasing":
		return "between" if between_falls else "outside"
	return "outside" if between_falls else "between"


## f′ at a whole number x, with the sign of f′ written out.
static func df_at(s: Dictionary, x: int) -> Q:
	return Q.new(3 * s.A * (x - s.p) * (x - s.q))


static func sign_text(q: Q) -> String:
	return "positive" if q.sign() > 0 else ("negative" if q.sign() < 0 else "zero")


static func sign_rel(q: Q) -> String:
	return "> 0" if q.sign() > 0 else ("< 0" if q.sign() < 0 else "= 0")


## A window for a curve with these y-values.
static func graph_of(f: Callable, lo: float, hi: float, points: Array) -> Dictionary:
	var c := GdcKit.curve(f, lo, hi)
	var ylo := INF
	var yhi := -INF
	for p in c:
		ylo = minf(ylo, p[1])
		yhi = maxf(yhi, p[1])
	return Plot.spec([c], points, floori(lo), ceili(hi), mini(floori(ylo) - 1, -1), maxi(ceili(yhi) + 1, 1))


static func cubic_graph(s: Dictionary, labels: bool = true) -> Dictionary:
	var f := func(x: float) -> float:
		return s.A * x * x * x + float(s.coeffs[1]) * x * x + float(s.coeffs[2]) * x + s.d
	var yp := MonotonicSituation.f_at(s, Q.new(s.p))
	var yq := MonotonicSituation.f_at(s, Q.new(s.q))
	var pts: Array = [[float(s.p), yp.to_float(), Fmt.point(s.p, yp) if labels else ""], [float(s.q), yq.to_float(), Fmt.point(s.q, yq) if labels else ""]]
	return graph_of(f, s.p - 2.0, s.q + 2.0, pts)


static func quad_fn(s: Dictionary) -> Callable:
	return func(x: float) -> float: return float(s.a) * (x - s.r) * (x - s.s)


# ── An interval from the equation of a cubic ─────────────────

func u_interval_from_equation(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var A: int = s.A
	var mid: int = (p + q) / 2
	var shape := dec_shape(s)
	var f := fn_text(s)
	var df := derivative(s.coeffs)
	var ans := interval(shape, p, q)
	var word: String = s.want
	var yp := MonotonicSituation.f_at(s, Q.new(p))
	var yq := MonotonicSituation.f_at(s, Q.new(q))
	var wr: Array = [alt_iv(other(shape), p, q, R_WAY_ROUND if A < 0 else ""), alt_iv(shape, yp if yp.lt(yq) else yq, yq if yp.lt(yq) else yp, R_Y_VALUES)]
	var gen: Array = [alt_iv(shape, p - 1, q).values, alt_iv(shape, p, q + 1).values, alt_iv(other(shape), p - 1, q + 1).values, alt_iv(shape, -q, -p).values]
	var lines: Array
	var asked: String
	if rep == "words":
		lines = ["A curve has equation y = %s." % f]
		asked = "Find the set of values of x for which y %s as x increases." % ("increases" if word == "increasing" else "decreases")
	else:
		lines = ["f(x) = %s" % f]
		asked = "Find the values of x for which f is %s." % word
	var factored := "%s(x%s)(x%s)" % [Fmt.lead(3 * A), Fmt.plus(-p), Fmt.plus(-q)]
	var rel := "> 0" if word == "increasing" else "< 0"
	return {"lines": lines, "asked": asked, "answer": ans, "wrongs": wr, "generic": gen,
		"methods": {"solve-inequality": method([
			"f′(x) = %s = %s." % [df, factored],
			"f is %s where f′(x) %s." % [word, rel],
			"f′ is a parabola with roots %s and %s, opening %s, so f′(x) %s %s them." % [Fmt.num(p), Fmt.num(q), "up" if A > 0 else "down", rel, shape],
			Answer.text(ans)], ans.values),
		"sign-table": method([
			"f′(x) = %s, which is 0 at x = %s and x = %s." % [factored, Fmt.num(p), Fmt.num(q)],
			"Test each stretch: f′(%s) = %s, f′(%s) = %s, f′(%s) = %s." % [Fmt.num(p - 1), Fmt.num(df_at(s, p - 1)), Fmt.num(mid), Fmt.num(df_at(s, mid)), Fmt.num(q + 1), Fmt.num(df_at(s, q + 1))],
			"f is %s where the sign is %s." % [word, "positive" if word == "increasing" else "negative"],
			Answer.text(ans)], ans.values),
		"gdc-turning-points": method([
			"Graph f on the GDC: a local %s at x = %s and a local %s at x = %s." % ["maximum" if A > 0 else "minimum", Fmt.num(p), "minimum" if A > 0 else "maximum", Fmt.num(q)],
			"The graph goes %s between them, and the other way outside them." % ("down" if A > 0 else "up"),
			Answer.text(ans)], ans.values)}}


func u_interval_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var mid: int = (p + q) / 2
	var shape := dec_shape(s)
	var xs: Array = [p - 1, p, mid, q, q + 1]
	var ys: Array = xs.map(func(x): return df_at(s, x))
	var ans := interval(shape, p, q)
	var word: String = s.want
	return {"lines": ["The table gives values of f′(x). Its only zeros are the two shown."],
		"table": {"rows": [["x", xs.map(func(x): return Fmt.num(x))], ["f′(x)", ys.map(func(y): return Fmt.num(y))]]},
		"asked": "Find the values of x for which f is %s." % word, "answer": ans,
		"wrongs": [alt_iv(other(shape), p, q, R_WAY_ROUND if s.A < 0 else "")],
		"generic": [alt_iv(shape, p - 1, q + 1).values, alt_iv(other(shape), p - 1, q + 1).values, alt_iv(shape, p - 1, q).values, alt_iv(shape, p, q + 1).values],
		"methods": {"sign-table": method([
			"f′ changes sign at x = %s and x = %s." % [Fmt.num(p), Fmt.num(q)],
			"Between them f′ is %s; outside them it is %s." % [sign_text(ys[2]), sign_text(ys[0])],
			"f is %s where the sign is %s." % [word, "positive" if word == "increasing" else "negative"],
			Answer.text(ans)], ans.values)}}


# ── A quadratic ──────────────────────────────────────────────

static func side(rel: String, h: Variant) -> Dictionary:
	var ans := DifferentiationViews.form("x %s %s" % [rel, Fmt.num(h)], ["x ", {"pick": "rel", "options": ["<", ">"]}, " ", {"slot": "h"}], {"rel": rel, "h": Q.of(h)})
	return ans


func u_quadratic_interval(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var h: int = s.h
	var k: int = s.k
	var word: String = s.want
	var up_side: bool = (a > 0) == (word == "increasing")   # the right of the vertex
	var rel := ">" if up_side else "<"
	var flip := "<" if up_side else ">"
	var ans := side(rel, h)
	var df := Fmt.poly([2 * a, -2 * a * h])
	var wr: Array = [wrong(side(flip, h).values, R_WAY_ROUND if a < 0 else ""),
		DifferentiationViews.alt("y %s %s" % [rel, Fmt.num(k)], R_Y_VALUES),
		DifferentiationViews.alt(interval_text("between", s.r, s.s), R_F_NOT_DF if (a > 0) == (word == "decreasing") else "")]
	var r := "> 0" if word == "increasing" else "< 0"
	return {"lines": ["f(x) = %s" % Fmt.poly(s.coeffs)], "asked": "Find the values of x for which f is %s." % word, "answer": ans, "wrongs": wr,
		"generic": [side(rel, h + 1).values, side(rel, h - 1).values, side(rel, -h).values if h != 0 else side(rel, 2).values, side(flip, h + 1).values],
		"methods": {"vertex-shortcut": method([
			"The vertex is at x = −b/(2a) = %s." % Fmt.num(h),
			"A parabola opening %s %s on the right of its vertex." % ["up" if a > 0 else "down", "rises" if a > 0 else "falls"],
			Answer.text(ans)], ans.values),
		"solve-inequality": method([
			"f′(x) = %s." % df,
			"f′(x) %s gives %s %s." % [r, Fmt.poly([2 * a, 0]), ("> " if word == "increasing" else "< ") + Fmt.num(2 * a * h)],
			"Divide by %s%s." % [Fmt.num(2 * a), ", which turns the sign round" if a < 0 else ""],
			Answer.text(ans)], ans.values)}}


func u_interval_from_derivative_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: int = s.r
	var t: int = s.s
	var a: int = s.a
	# f′ is the parabola drawn. f rises where it is above the axis.
	var word: String = s.want
	var above := "outside" if a > 0 else "between"
	var shape: String = above if word == "increasing" else other(above)
	var ans := interval(shape, r, t)
	var g := graph_of(quad_fn(s), r - 2.0, t + 2.0, [[float(r), 0.0, Fmt.point(r, 0)], [float(t), 0.0, Fmt.point(t, 0)]])
	var yup: String = "above" if word == "increasing" else "below"
	return {"lines": ["The graph shows y = f′(x), the derivative of f."], "graph": g, "asked": "Find the values of x for which f is %s." % word, "answer": ans,
		"wrongs": [alt_iv(other(shape), r, t, R_WAY_ROUND if a < 0 else "")],
		"generic": [alt_iv(shape, r - 1, t).values, alt_iv(shape, r, t + 1).values, alt_iv(other(shape), r - 1, t + 1).values, alt_iv(shape, r - 1, t + 1).values],
		"methods": {"graph-of-derivative": method([
			"This is the graph of f′, so read the sign, not the slope: f is %s where f′ is %s the x-axis." % [word, yup],
			"The curve crosses the axis at x = %s and x = %s." % [Fmt.num(r), Fmt.num(t)],
			Answer.text(ans)], ans.values)}}


# ── Paper 2: f′ with an exponential ──────────────────────────

func u_interval_gdc(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r1: float = s.r1
	var r2: float = s.r2
	var word: String = s.want
	var shape := "between" if word == "increasing" else "outside"
	var ans := interval(shape, r1, r2, true)
	var line := "f′(x) = %d + %s − %se^x" % [s.a, DifferentiationViews.T(s.b, "x"), Fmt.lead(s.c)]
	var turn: float = log(float(s.b) / s.c)
	var gen: Array = [alt_iv(shape, r1 - 1.0, r2, "", true).values, alt_iv(shape, r1, r2 + 1.0, "", true).values, alt_iv(shape, turn, r2, "", true).values, alt_iv(other(shape), r1 - 1.0, r2 + 1.0, "", true).values]
	var text := Answer.text(ans)
	return {"lines": [line], "asked": "Find the values of x for which f is %s. Give the ends to 3 s.f." % word, "answer": ans,
		"wrongs": [alt_iv(other(shape), r1, r2, R_WAY_ROUND, true)], "generic": gen,
		"methods": {"gdc-turning-points": method([
			"f has its turning points where f′(x) = 0. GDC, zeros of f′: x = %s and x = %s." % [GdcKit.W(r1), GdcKit.W(r2)],
			"Because of the −%se^x term, f′ is positive between them and negative outside." % Fmt.lead(s.c),
			text], ans.values),
		"graph-of-derivative": method([
			"Graph y = f′(x) on the GDC. It crosses the axis at x = %s and x = %s." % [GdcKit.W(r1), GdcKit.W(r2)],
			"It is above the axis between them, so f is %s %s them." % [word, "between" if word == "increasing" else "outside"],
			text], ans.values)}}


# ── The sign of f′ from the graph of f ───────────────────────

func u_sign_at_points(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x1: int = s.x1
	var x2: int = s.x2
	var d1 := df_at(s, x1)
	var d2 := df_at(s, x2)
	var g := cubic_graph(s, false)
	var y1 := MonotonicSituation.f_at(s, Q.new(x1))
	var y2 := MonotonicSituation.f_at(s, Q.new(x2))
	g.points.append({"x": float(x1), "y": y1.to_float(), "label": "A"})
	g.points.append({"x": float(x2), "y": y2.to_float(), "label": "B"})
	var words := ["positive", "zero", "negative"]
	var w := func(a: String, b: String) -> String:
		return "f′(%s) is %s and f′(%s) is %s" % [Fmt.num(x1), a, Fmt.num(x2), b]
	var parts: Array = ["f′(%s) is " % Fmt.num(x1), {"pick": "s1", "options": words}, " and f′(%s) is " % Fmt.num(x2), {"pick": "s2", "options": words}]
	var s1 := sign_text(d1)
	var s2 := sign_text(d2)
	var ans := DifferentiationViews.form(w.call(s1, s2), parts, {"s1": s1, "s2": s2})
	var wr: Array = []
	var f1 := sign_text(y1)
	var f2 := sign_text(y2)
	if f1 != s1 or f2 != s2:
		wr.append(DifferentiationViews.alt(w.call(f1, f2), R_BELOW_AXIS, {"s1": f1, "s2": f2}))
	var gen: Array = []
	for a in words:
		for b in words:
			if a != s1 or b != s2:
				gen.append(DifferentiationViews.alt(w.call(a, b), "", {"s1": a, "s2": b}).values)
	var walk := func(d: Q) -> String:
		return "going up" if d.sign() > 0 else ("going down" if d.sign() < 0 else "flat, at a turning point")
	return {"lines": ["The graph shows y = f(x), with its turning points. A has x = %s and B has x = %s." % [Fmt.num(x1), Fmt.num(x2)]], "graph": g,
		"asked": "Write down the sign of f′ at A and at B.", "answer": ans, "wrongs": wr, "generic": gen,
		"methods": {"walk-the-curve": method([
			"Walk along the curve from left to right. At A you are %s." % walk.call(d1),
			"At B you are %s." % walk.call(d2),
			Answer.text(ans)], ans.values),
		"tangent-sketch": method([
			"Lay a ruler along the curve at A: its gradient is %s." % s1,
			"Do the same at B: its gradient is %s." % s2,
			Answer.text(ans)], ans.values),
		"sign-row": method([
			"Sign row for f′: it changes sign at the two turning points, x = %s and x = %s." % [Fmt.num(s.p), Fmt.num(s.q)],
			"f′ is %s before x = %s, %s between, and %s after." % [sign_text(df_at(s, s.p - 1)), Fmt.num(s.p), sign_text(df_at(s, (s.p + s.q) / 2)), sign_text(df_at(s, s.q + 1))],
			Answer.text(ans)], ans.values)}}


func u_intervals_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var h: int = s.h
	var k: int = s.k
	var r: int = s.r
	var t: int = s.s
	var neg: bool = s.want == "decreasing"
	var rel := ">" if (a > 0) != neg else "<"
	var flip := "<" if rel == ">" else ">"
	var ans := side(rel, h)
	var g := graph_of(quad_fn(s), r - 2.0, t + 2.0, [[float(h), float(k), Fmt.point(h, k)], [float(r), 0.0, Fmt.point(r, 0)], [float(t), 0.0, Fmt.point(t, 0)]])
	var below := interval_text("between", r, t) if a > 0 else interval_text("outside", r, t)
	var above := interval_text("outside", r, t) if a > 0 else interval_text("between", r, t)
	var bin := "< 0" if neg else "> 0"
	return {"lines": ["The graph shows y = f(x)."], "graph": g, "asked": "Write down the values of x for which f′(x) %s." % bin, "answer": ans,
		"wrongs": [DifferentiationViews.alt(below if neg else above, R_BELOW_AXIS), DifferentiationViews.alt(above if neg else below, R_INTERCEPTS), wrong(side(flip, h).values, "")],
		"generic": [side(rel, h + 1).values, side(rel, h - 1).values, side(flip, h + 1).values, side(rel, r).values],
		"methods": {"walk-the-curve": method([
			"f′(x) %s where the curve is going %s as you walk left to right." % [bin, "down" if neg else "up"],
			"It turns at the vertex, x = %s, not at the x-intercepts." % Fmt.num(h),
			Answer.text(ans)], ans.values),
		"sign-row": method([
			"Sign row for f′: 0 at the vertex, x = %s." % Fmt.num(h),
			"f′ is %s to the left and %s to the right." % ["negative" if a > 0 else "positive", "positive" if a > 0 else "negative"],
			Answer.text(ans)], ans.values)}}


func u_negative_and_increasing(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var r: int = s.r
	var t: int = s.s
	var h: int = s.h
	var word: String = "negative and increasing" if a > 0 else "positive and decreasing"
	var ans := DifferentiationViews.form(interval_text("between", h, t), ["", {"slot": "lo"}, " < x < ", {"slot": "hi"}], {"lo": Q.new(h), "hi": Q.new(t)})
	var sl := func(lo: int, hi: int, ref: String = "") -> Dictionary:
		return DifferentiationViews.alt(interval_text("between", lo, hi), ref, {"lo": Q.new(lo), "hi": Q.new(hi)})
	var bit: String = "negative" if a > 0 else "positive"
	var turn: String = "increasing" if a > 0 else "decreasing"
	return {"lines": ["f(x) = %s(x%s)(x%s)" % [Fmt.lead(a), Fmt.plus(-r), Fmt.plus(-t)]], "asked": "Find the values of x for which f is both %s." % word, "answer": ans,
		"wrongs": [sl.call(r, t, R_F_NOT_DF), sl.call(r, h)],
		"generic": [sl.call(h, t + 1).values, sl.call(h - 1, t).values, sl.call(r - 1, h).values, sl.call(h + 1, t + 1).values],
		"methods": {"sign-table": method([
			"f is %s between its roots: %s." % [bit, interval_text("between", r, t)],
			"f′(x) = %s, so f is %s for x > %s." % [Fmt.poly([2 * a, -2 * a * h]), turn, Fmt.num(h)],
			"Both hold on the overlap.",
			Answer.text(ans)], ans.values),
		"vertex-shortcut": method([
			"The vertex is halfway between the roots: x = %s." % Fmt.num(h),
			"Right of the vertex a parabola opening %s is %s, and it stays %s until the root x = %s." % ["up" if a > 0 else "down", turn, bit, Fmt.num(t)],
			Answer.text(ans)], ans.values)}}


# ── A parameter that keeps f rising ──────────────────────────

func u_parameter_discriminant(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var c: int = 3 * n * n
	var m: int = 3 * n
	var sgn: int = 1 if s.want == "increasing" else -1
	var f := "%sx³ + kx²%s%s" % ["" if sgn > 0 else "−", (" + " if sgn > 0 else " − ") + Fmt.lead(c) + "x", Fmt.plus(s.d) if s.d != 0 else ""]
	var box := func(lo: int, hi: int) -> String:
		return "%s ≤ k ≤ %s" % [Fmt.num(lo), Fmt.num(hi)]
	var ans := DifferentiationViews.form(box.call(-m, m), ["", {"slot": "lo"}, " ≤ k ≤ ", {"slot": "hi"}], {"lo": Q.new(-m), "hi": Q.new(m)})
	var sl := func(lo: int, hi: int) -> Dictionary:
		return DifferentiationViews.alt(box.call(lo, hi), "", {"lo": Q.new(lo), "hi": Q.new(hi)})
	var surd := "%s√3" % Fmt.lead(2 * n)
	var wr: Array = [DifferentiationViews.alt("−%s ≤ k ≤ %s" % [surd, surd], R_DISC_F),
		DifferentiationViews.alt("k < −%d or k > %d" % [m, m], R_TWO_ROOTS), DifferentiationViews.alt("k ≤ %d" % m, R_ONE_SIDE)]
	var dfp := "%sx² + 2kx%s" % [Fmt.lead(3 * sgn), (" + " if sgn > 0 else " − ") + Fmt.num(c)]
	var text := Answer.text(ans)
	return {"lines": ["f(x) = " + f], "asked": "Find the values of k for which f is %s for all x." % s.want, "answer": ans, "wrongs": wr,
		"titles": {"complete-square-condition": "Require the maximum of f′ to be ≤ 0"} if sgn < 0 else {},
		"generic": [sl.call(-m - 1, m + 1).values, sl.call(-c, c).values, sl.call(-m, m + 1).values],
		"methods": {"discriminant-condition": method([
			"f′(x) = %s. It must not change sign, so it has at most one root." % dfp,
			"Discriminant ≤ 0: (2k)² − 4(%s)(%s) ≤ 0, so 4k² ≤ %d." % [Fmt.num(3 * sgn), Fmt.num(c * sgn), 12 * c],
			"k² ≤ %d, which is −%d ≤ k ≤ %d." % [m * m, m, m],
			text], ans.values),
		"complete-square-condition": method([
			"f′(x) = %s(x %s k/%d)² %s, on completing the square." % [Fmt.lead(3 * sgn), "+" if sgn > 0 else "−", 3, "+ %d − k²/3" % c if sgn > 0 else "− %d + k²/3" % c],
			("Its turning value must be ≥ 0: %d − k²/3 ≥ 0." if sgn > 0 else "Its turning value must be ≤ 0: k²/3 − %d ≤ 0.") % c,
			"k² ≤ %d, which is −%d ≤ k ≤ %d." % [m * m, m, m],
			text], ans.values),
		"gdc-slider": method([
			"Graph y = f′(x) on the GDC with a slider for k.",
			"It stays on one side of the axis, touching it at k = %d and k = −%d, and crosses it for any k past those." % [m, m],
			text], ans.values)}}


func u_parameter_shift(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var h: int = s.h
	var k: int = s.k
	var line := "f(x) = %s(x%s)²%s" % [Fmt.lead(a), Fmt.plus(-h) if h != 0 else "", Fmt.plus(k)]
	if h == 0:
		line = "f(x) = %sx²%s" % [Fmt.lead(a), Fmt.plus(k)]
	var w := func(rel: String, v: int) -> String:
		return "d %s %s" % [rel, Fmt.num(v)]
	var rels := ["≤", "≥", "<", ">"]
	var parts := ["d ", {"pick": "rel", "options": rels}, " ", {"slot": "v"}]
	var ans := DifferentiationViews.form(w.call("≤", k), parts, {"rel": "≤", "v": Q.new(k)})
	var sl := func(rel: String, v: int, ref: String = "") -> Dictionary:
		return DifferentiationViews.alt(w.call(rel, v), ref, {"rel": rel, "v": Q.new(v)})
	return {"lines": [line, "A function g has derivative g′(x) = f(x) − d."], "asked": "Find the values of d for which g is an increasing function.", "answer": ans,
		"wrongs": [sl.call(">", k, R_TWO_ROOTS), sl.call("≥", k)],
		"generic": [sl.call("≤", -k).values, sl.call("≤", k + 1).values, sl.call("≤", h if h != k else k + 2).values, sl.call("≥", -k).values],
		"methods": {"complete-square-condition": method([
			"g is increasing when g′(x) ≥ 0 for all x.",
			"f is already in vertex form, so the least value of g′ is %s − d." % Fmt.num(k),
			"%s − d ≥ 0." % Fmt.num(k),
			Answer.text(ans)], ans.values),
		"discriminant-condition": method([
			"g′(x) = f(x) − d must have at most one root.",
			"Its discriminant is %s(d%s), which must be ≤ 0." % [Fmt.num(4 * a), Fmt.plus(-k)],
			"Since %s > 0, d%s ≤ 0." % [Fmt.num(4 * a), Fmt.plus(-k)],
			Answer.text(ans)], ans.values)}}
