class_name TrapezoidalViews
extends ExtensionViews
## The views on the `trapezoidal` situation (FAL-1000): one builder per unknown of
## t5-ai-trapezoidal (AI-SL5.8). From a function: the strip width, the estimate (from y = f(x),
## from the curve with its trapezia drawn, or from a table with one or two heights to work out),
## the percentage error against the GDC's integral, how to improve the estimate, whether it is
## over or under, and which of four curves the rule under- or overestimates (pick the graph).
## From measurements: an area from widths or depths (a table, or the shape drawn with its
## widths), a total from rates (a distance from speeds, a volume from flow rates, a flow through
## a channel), and a missing height from a given estimate.
##
## Every question is Paper 2, as every AI paper allows a GDC. A value is to 3 s.f. with the
## rounding trap; h and a missing height end, so they are exact. A reason is a picked `claim`.
## `given` holds the situation as plain data.

const TF := "AI-SL5.8.trapezoid-from-function#"
const TD := "AI-SL5.8.trapezoid-from-data#"
const CE := "AI-SL5.8.compare-with-exact#"
const OU := "AI-SL5.8.over-or-under-estimate#"
const MV := "AI-SL5.8.find-missing-value#"
const R_H_HEIGHTS := TF + "0"
const R_NO_DOUBLE := TF + "1"
const R_NO_HALF := TF + "2"
const R_X_AS_Y := TD + "0"
const R_UNITS := TD + "1"
const R_ENDS_DOUBLED := TD + "2"
const R_OVER_ESTIMATE := CE + "0"
const R_MORE_WORSE := CE + "1"
const R_SIGNED := CE + "2"
const R_RISES := OU + "0"
const R_ALWAYS_OVER := OU + "1"
const R_LINE_ERROR := OU + "2"
const R_INNER_ONCE := MV + "0"
const R_NO_H_HALF := MV + "1"
const R_SAME_WIDTH := "t5-ai-trapezoidal#14"
const S := preload("res://engine/situations/trapezoidal.gd")

const WHO := ["Juno", "Ash", "Vex", "Mara", "Rook", "Tess"]
const UNKNOWNS := ["strip-width", "function-estimate", "data-estimate", "accumulated-total", "percentage-error-of-estimate",
	"improve-estimate", "over-or-under", "pick-underestimate-graph", "missing-height"]
const IMPROVE := "Use more strips of smaller width: the chords then follow the curve more closely."


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


static func W7(x: float) -> String:
	return Fmt.work(x, 7)


static func who(s: Dictionary) -> String:
	return WHO[s.ctx]


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func sf_ans(label: String, v: Variant, unit: String = "") -> Dictionary:
	var q: Q = v if v is Q else GdcKit.qf(v)
	var ans := Answer.make("number", {"v": q}, {}, label, unit)
	ans.show = "sf"
	return ans


static func exact_ans(label: String, v: Q, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label, unit)
	ans.show = "dec"
	ans.exact = true
	return ans


## A value for an exact answer's option: as it is when it ends, else to 3 s.f.
static func ends_or_sf(v: Q) -> Q:
	return v if not D(v).contains("/") else GraphReadingSituation.sf_q(v, 3)


static func val(v: Variant) -> Dictionary:
	return {"v": v if v is Q else GdcKit.qf(v)}


static func pack(lines: Array, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary,
		graph: Variant = null, table: Variant = null) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {},
		"graph": graph, "table": table}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


static func powers(n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append(n - 1 - i)
	return out


## f(x) as the question writes it: "0.5x² − 2x + 3", "2√(x + 3)", "3e^(−0.4x)", "12/(x + 2)".
static func f_text(f: Dictionary) -> String:
	match f.fam:
		"sqrt":
			return GdcKit.lead(f.m) + ("√x" if f.c.is_zero() else "√(x + %s)" % D(f.c))
		"exp":
			return GdcKit.lead(f.m) + "e^(%sx)" % GdcKit.lead(f.k)
		"recip":
			return D(f.m) + "/" + ("x" if f.c.is_zero() else "(x + %s)" % D(f.c))
	return Fmt.terms(f.co, powers(f.co.size()), "x", true)


## f″(x), written out.
static func f2_text(f: Dictionary) -> String:
	var c: Q = f.get("c", Q.new(0))
	var base := "x" if c.is_zero() else "(x + %s)" % D(c)
	match f.fam:
		"sqrt":
			return "−" + GdcKit.lead(f.m.div(4)) + base + "^(−3/2)"
		"exp":
			return GdcKit.lead(f.m.mul(f.k).mul(f.k)) + "e^(%sx)" % GdcKit.lead(f.k)
		"recip":
			return D(f.m.mul(2)) + "/" + base + "³"
	var d := S.poly_d(S.poly_d(f.co))
	return Fmt.terms(d, powers(d.size()), "x", true) if not d.is_empty() else "0"


static func limits(s: Dictionary) -> String:
	return "from x = %s to x = %s" % [D(s.a), D(s.b)]


static func est_line(s: Dictionary) -> String:
	return "The area under the curve y = f(x) %s is estimated with the trapezoidal rule, using %d strips of equal width." % [limits(s), s.n]


static func joined(xs: Array) -> String:
	return " + ".join(xs)


## (h/2)[y₀ + yₙ + 2(y₁ + … + yₙ₋₁)] with the heights written in.
static func bracket(h: String, ys: Array) -> String:
	var mid := joined(ys.slice(1, -1))
	return "(%s/2)[%s + %s + 2(%s)]" % [h, ys[0], ys[-1], mid]


## Each strip's ½h(yᵢ + yᵢ₊₁), written and worked out.
static func strips(h: String, ys: Array, areas: Array) -> String:
	var parts: Array = []
	for i in areas.size():
		parts.append("½ × %s × (%s + %s) = %s" % [h, ys[i], ys[i + 1], areas[i]])
	return "; ".join(parts)


static func weights(n: int) -> String:
	var w: Array = ["1"]
	for i in n - 1:
		w.append("2")
	w.append("1")
	return "{%s}" % ", ".join(w)


# ── Figures ──────────────────────────────────────────────────

## A smooth curve through the points (Catmull–Rom), as [[x, y], ...].
static func smooth(pts: Array, per: int = 12) -> Array:
	var out: Array = []
	var n := pts.size()
	for i in n - 1:
		var p0: Vector2 = pts[maxi(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[mini(i + 2, n - 1)]
		for k in per:
			var t := float(k) / per
			var t2 := t * t
			var t3 := t2 * t
			var p := 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)
			out.append([p.x, p.y])
	out.append([pts[-1].x, pts[-1].y])
	return out


## The window round the curve on [a, b], whole units, the x-axis in view.
static func fn_window(s: Dictionary) -> Array:
	var lo: float = s.a.to_float()
	var hi: float = s.b.to_float()
	var sp := S.span(s, lo, hi)
	var top := ceili(sp[1] * 1.15 + 0.5)
	return [mini(0, floori(lo - 0.5)), ceili(hi + 0.6), -maxi(1, roundi(top * 0.06)), top]


## The curve on its window, sampled a little past [a, b] where f is defined.
static func fn_curve(s: Dictionary, win: Array) -> Array:
	var lo: float = s.a.to_float()
	var hi: float = s.b.to_float()
	var from := maxf(float(win[0]), lo - 0.4)
	if s.fam in ["sqrt", "recip"]:
		from = maxf(from, -s.c.to_float() + 0.3)
	return GdcKit.curve(func(x): return S.fx(s, x), from, minf(float(win[1]), hi + 0.4))


## The curve with the n trapezia of the rule drawn under it: shaded, with their sides and tops.
static func trapezia_graph(s: Dictionary) -> Dictionary:
	var win := fn_window(s)
	var xs: Array = S.xs_of(s).map(func(x): return x.to_float())
	var ys: Array = S.ys_of(s)
	var tops: Array = []
	var curves: Array = [fn_curve(s, win)]
	for i in xs.size():
		tops.append([xs[i], ys[i]])
		curves.append([[xs[i], 0.0], [xs[i], ys[i]]])
	curves.insert(1, tops)
	var g := Plot.spec(curves, [], win[0], win[1], win[2], win[3])
	g.sand_from = 1
	g.shade = [range(xs.size()).map(func(i): return [xs[i], 0.0, ys[i]])]
	return g


## The curve with the region under it on [a, b] shaded and the strip edges dashed.
static func strip_graph(s: Dictionary) -> Dictionary:
	var win := fn_window(s)
	var xs: Array = S.xs_of(s).map(func(x): return x.to_float())
	var g := Plot.spec([fn_curve(s, win)], [], win[0], win[1], win[2], win[3], [], xs.map(func(x): return [x, ""]))
	g.shade = [DefiniteIntegralViews.under(func(x): return S.fx(s, x), xs[0], xs[-1])]
	return g


## x against f(x), with the heights in `blank` written as letters.
static func fn_table(s: Dictionary, blank: Array = [], names: Array = []) -> Dictionary:
	var xs: Array = S.xs_of(s)
	var ys: Array = S.ys_exact(s)
	var row: Array = []
	for i in ys.size():
		var at := blank.find(i)
		row.append(names[at] if at >= 0 else D(ys[i]))
	return {"rows": [["x", xs.map(func(x): return D(x))], ["f(x)", row]]}


# ── Strip width ──────────────────────────────────────────────

func u_strip_width(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h: Q = s.h
	var L: Q = s.b.sub(s.a)
	var ans := exact_ans("h = ", h)
	var wr: Array = [wrong({"v": ends_or_sf(L.div(s.n + 1))}, R_H_HEIGHTS)]
	var fill: Array = [{"v": ends_or_sf(L.div(s.n - 1))}, {"v": h.div(2)}, {"v": L}]
	var lines: Array
	var asked: String
	var first: String
	if rep == "table":
		lines = ["f(x) = " + f_text(s), "The table gives the values of f(x) used in a trapezoidal estimate of the area under y = f(x) %s." % limits(s)]
		asked = "Write down the strip width h."
		first = "The table has %d x-values, from %s to %s: that is %d strips." % [s.n + 1, D(s.a), D(s.b), s.n]
	else:
		lines = ["f(x) = " + f_text(s), est_line(s)]
		asked = "Find the strip width h."
		first = "%d strips cover x = %s to x = %s, a width of %s − %s = %s." % [s.n, D(s.a), D(s.b), D(s.b), D(s.a), D(L)]
	var out := pack(lines, asked, ans, wr, fill, {
		"trapezoidal-formula": [first, "h = (b − a)/n = %s/%d = %s" % [D(L), s.n, D(h)], say(ans)],
	}, null, fn_table(s) if rep == "table" else null)
	return out


# ── The estimate of a function's area ────────────────────────

func u_function_estimate(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var vals := S.function_slips(s)
	var ans := sf_ans("estimate = ", vals[0])
	var wr: Array = rng.shuffled([wrong(val(vals[1]), R_H_HEIGHTS), wrong(val(vals[2]), R_NO_DOUBLE), wrong(val(vals[3]), R_NO_HALF)])
	var ys: Array = S.ys_of(s)
	var xs: Array = S.xs_of(s)
	var L: float = s.b.sub(s.a).to_float()
	var fill: Array = [val(L / 2.0 * (ys[0] + ys[-1])), val(vals[0] + s.h.to_float())]
	var H := D(s.h)
	var yt: Array = ys.map(func(y): return W(y))
	var t := W(vals[0])
	var areas: Array = []
	for i in s.n:
		areas.append(W(0.5 * s.h.to_float() * (ys[i] + ys[i + 1])))
	var hline := "h = (b − a)/n = (%s − %s)/%d = %s" % [D(s.b), D(s.a), s.n, H]
	var heights := "Heights: " + ", ".join(range(xs.size()).map(func(i): return "f(%s) = %s" % [D(xs[i]), yt[i]]))
	var lines: Array = ["f(x) = " + f_text(s), est_line(s)]
	var asked := "Use the trapezoidal rule to estimate the area under the curve %s." % limits(s)
	var graph: Variant = null
	var table: Variant = null
	var found := ""
	if rep == "graph":
		lines = ["The graph of y = %s is shown with the %d trapezia of the trapezoidal rule %s." % [f_text(s), s.n, limits(s)]]
		asked = "Use the trapezoidal rule with these %d strips to estimate the area under the curve %s." % [s.n, limits(s)]
		graph = trapezia_graph(s)
	elif rep == "table":
		var names: Array = ["p", "q"].slice(0, s.blank.size())
		table = fn_table(s, s.blank, names)
		lines = ["f(x) = " + f_text(s), "The table gives values of f(x) at equal steps; %s missing." % (" and ".join(names) + (" are" if names.size() > 1 else " is"))]
		asked = "Find %s, then use the trapezoidal rule with the values in the table to estimate the area under the curve %s." % [" and ".join(names), limits(s)]
		var ye: Array = S.ys_exact(s)
		found = ", ".join(range(names.size()).map(func(i): return "%s = f(%s) = %s" % [names[i], D(xs[s.blank[i]]), D(ye[s.blank[i]])]))
		heights = "The table's heights, with %s: %s" % [found, ", ".join(yt)]
	var gdc_first := "L₁ = {%s}, and L₂ = f(L₁) = {%s}" % [", ".join(xs.map(func(x): return D(x))), ", ".join(yt)]
	if found != "":
		gdc_first = "%s. L₂ = {%s}, the heights" % [found, ", ".join(yt)]
	var sum_w := S.rule(ys, 1.0, 2.0, 1.0, 1.0)
	var steps := {
		"trapezoidal-formula": [hline, heights, "T = %s = %s" % [bracket(H, yt), t], say(ans)],
		"sum-of-trapezia": [hline + (". " + found if found != "" else ""), "Strips: " + strips(H, yt, areas), "Total: %s = %s" % [joined(areas), t], say(ans)],
		"gdc-list": [gdc_first, "L₃ = %s, the weights: sum(L₂ × L₃) = %s" % [weights(s.n), W(sum_w)], "T = (%s/2) × %s = %s" % [H, W(sum_w), t], say(ans)],
	}
	return pack(lines, asked, ans, wr, fill, steps, graph, table)


# ── Percentage error ─────────────────────────────────────────

func u_percentage_error_of_estimate(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var vals := S.percentage_slips(s)
	var e: float = vals[0]
	var ans := sf_ans("percentage error = ", e, "%")
	var wr: Array = [wrong(val(vals[1]), R_OVER_ESTIMATE), wrong(val(vals[2]), R_H_HEIGHTS)]
	if vals.size() > 3:
		wr.append(wrong(val(vals[3]), R_SIGNED))
	wr = rng.shuffled(wr)
	var t := S.trap(s)
	var i := S.exact(s)
	var fill: Array = [val(e / 100.0), val(absf(t - i))]
	var H := D(s.h)
	var yt: Array = S.ys_of(s).map(func(y): return W(y))
	var T7 := W7(t)
	var I7 := W7(i)
	var eps := "ε = |%s − %s| ÷ %s × 100%% = %s%%" % [T7, I7, I7, W(e)]
	var gdc := "The GDC's ∫ from %s to %s of %s dx gives %s." % [D(s.a), D(s.b), f_text(s), I7]
	return pack(["f(x) = " + f_text(s), est_line(s)],
		"Find the percentage error in this estimate, against the exact area the GDC's integral gives.", ans, wr, fill, {
		"trapezoidal-formula": ["h = (%s − %s)/%d = %s" % [D(s.b), D(s.a), s.n, H], "T = %s = %s" % [bracket(H, yt), T7], gdc, eps, say(ans)],
		"gdc-integral": ["The rule with %d strips of width %s gives T = %s." % [s.n, H, T7], gdc, eps, say(ans)],
		"percentage-error-formula": ["Percentage error = |estimate − exact| ÷ exact × 100%.",
			"The estimate is T = %s (the rule, h = %s) and the exact value is %s (the GDC)." % [T7, H, I7], eps, say(ans)],
	})


# ── Improving the estimate ───────────────────────────────────

func u_improve_estimate(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t := S.trap(s)
	var t2 := S.trap(s, s.n * 2)
	var i := S.exact(s)
	var built := SamplingViews.claims(IMPROVE, [
		["Use fewer, wider strips: each strip adds an error of its own, so fewer strips give a better estimate.", R_MORE_WORSE],
		["Nothing: the strip width makes no difference, since the formula is the same.", R_SAME_WIDTH],
		["Round each height to 1 decimal place first: the bracket is then exact.", ""]])
	var lines: Array = ["f(x) = " + f_text(s),
		"%s estimates the area under y = f(x) %s with the trapezoidal rule, using %d strips, and gets %s. The GDC's integral gives %s." % [who(s), limits(s), s.n, W(t), W(i)]]
	var graph: Variant = trapezia_graph(s) if rep == "graph" else null
	if rep == "graph":
		lines.append("The graph shows the curve and the %d trapezia." % s.n)
	var h2 := D(s.h.div(2))
	var out := pack(lines, "How could the estimate be made more accurate, and why?", built.answer, built.wrongs, built.fillers, {
		"gdc-integral": ["With %d strips the rule gives %s against the GDC's %s: an error of %s." % [s.n, W(t), W(i), W(absf(t - i))],
			"With %d strips (h = %s) it gives %s: an error of %s, smaller, as the chords hug the curve." % [s.n * 2, h2, W(t2), W(absf(t2 - i))],
			"So: " + IMPROVE],
	}, graph)
	return out


# ── Over or under ────────────────────────────────────────────

static func over_claim(s: Dictionary) -> String:
	match s.bend:
		"up":
			return "Overestimate: the curve bends upwards (concave up), so the tops of the trapezia lie above it."
		"down":
			return "Underestimate: the curve bends downwards (concave down), so the tops of the trapezia lie below it."
	return "Neither: the graph is a straight line, so the tops of the trapezia lie along it and the estimate is exact."


func u_over_or_under(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := over_claim(s)
	var line: bool = s.bend == "line"
	var thing := "line" if line else "curve"
	var rising: bool = s.slope == "rises"
	var others: Array = []
	# Decided from the rise: over or under the other way from the right answer.
	if s.bend == "up" or (line and not rising):
		others.append(["Underestimate: the %s %s, so the tops of the trapezia lie below it." % [thing, s.slope], R_RISES])
	else:
		others.append(["Overestimate: the %s %s, so the tops of the trapezia lie above it." % [thing, s.slope], R_RISES])
	others.append(["Overestimate: the trapezoidal rule always gives an overestimate of an area.", R_ALWAYS_OVER])
	if line:
		others.append(["Underestimate: the rule is only an approximation, so even under a line it leaves gaps.", R_LINE_ERROR])
	else:
		others.append(["Neither: the trapezia fill the region under the curve exactly, so the estimate is exact.", ""])
	var built := SamplingViews.claims(right, others)
	var lines: Array = ["f(x) = %s, for %s ≤ x ≤ %s." % [f_text(s), D(s.a), D(s.b)], est_line(s)]
	var graph: Variant = null
	if rep == "graph":
		lines = ["The graph of y = %s is shown for %s ≤ x ≤ %s, with the region under it cut into %d strips of equal width." % [f_text(s), D(s.a), D(s.b), s.n],
			"The area of the region is estimated with the trapezoidal rule on these strips."]
		graph = strip_graph(s)
	var t := S.trap(s)
	var i := S.exact(s)
	var chords: Array
	if rep == "graph":
		var how := {"up": "bends upwards (concave up) all the way, so each chord lies above it and each trapezium holds a little more than its strip",
			"down": "bends downwards (concave down) all the way, so each chord lies below it and each trapezium holds a little less than its strip",
			"line": "is a straight line, so each chord lies along it and each trapezium is its strip exactly"}
		chords = ["Join the tops of neighbouring strip edges with straight chords.", ("The graph %s." if line else "The curve %s.") % how[s.bend], "So: " + right]
	else:
		var sign := {"up": "f″(x) > 0 on %s ≤ x ≤ %s: the curve bends upwards, so each chord lies above it." % [D(s.a), D(s.b)],
			"down": "f″(x) < 0 on %s ≤ x ≤ %s: the curve bends downwards, so each chord lies below it." % [D(s.a), D(s.b)],
			"line": "The graph is a straight line, so each chord lies along it."}
		var first := "f″(x) = %s" % f2_text(s)
		if line:
			first = "f′(x) = %s, a constant, so f″(x) = 0." % D(s.co[0])
		chords = [first, sign[s.bend], "So: " + right]
	var cmp: String
	if line:
		cmp = "The two are equal: the estimate is exact."
	elif t > i:
		cmp = "%s > %s: the estimate is too big." % [W7(t), W7(i)]
	else:
		cmp = "%s < %s: the estimate is too small." % [W7(t), W7(i)]
	return pack(lines, "Is the trapezoidal estimate an overestimate or an underestimate of the area? Give a reason.", built.answer, built.wrongs, built.fillers, {
		"chords-above-or-below": chords,
		"compare-with-gdc": ["The rule with %d strips gives T = %s, and the GDC's ∫ from %s to %s of f(x) dx gives %s." % [s.n, W7(t), D(s.a), D(s.b), W7(i)],
			cmp, "So: " + right],
	}, graph)


# ── Pick the graph ───────────────────────────────────────────

func u_pick_underestimate_graph(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var lo: float = s.a.to_float()
	var hi: float = s.b.to_float()
	var under: bool = s.target == "under"
	var win := [0, int(hi) + 1, -1, 10]
	var card := func(f: Dictionary) -> Dictionary:
		var fn := func(x): return S.fx(f, x)
		var g := GdcKit.card([GdcKit.curve(fn, lo, hi)], [], win)
		g.shade = [DefiniteIntegralViews.under(fn, lo, hi)]
		return g
	var right: Dictionary
	var wrongs: Array = []
	var other := "upwards" if under else "downwards"
	var rule_does := "overestimates" if under else "underestimates"
	for f in s.cards:
		match f.role:
			"right":
				right = card.call(f)
			"rises":
				wrongs.append({"graph": card.call(f), "mistake": "rises", "ref": R_RISES,
					"why": "it %s, but it bends %s, so its chords lie %s it and the rule %s its area" % ["falls" if under else "rises", other, "above" if under else "below", rule_does]})
			"line":
				wrongs.append({"graph": card.call(f), "mistake": "line", "ref": R_LINE_ERROR,
					"why": "it is a straight line, so the chords lie along it and the rule is exact"})
			_:
				wrongs.append({"graph": card.call(f), "mistake": "same-way", "ref": "",
					"why": "it bends %s, so its chords lie %s it and the rule %s its area" % [other, "above" if under else "below", rule_does]})
	var pk := GdcKit.pick(right, wrongs, rng)
	var ans: Dictionary = pk.answer
	var word := "an underestimate" if under else "an overestimate"
	var bend_word := "downwards" if under else "upwards"
	return {"asked": "The area under each curve from x = %s to x = %s is estimated with the trapezoidal rule. For which curve is the estimate %s?" % [D(s.a), D(s.b), word],
		"lines": ["Each graph shows a curve on %s ≤ x ≤ %s, with the region under it shaded." % [D(s.a), D(s.b)]],
		"answer": ans, "graphs": pk.graphs,
		"methods": {"chords-above-or-below": method([
			"Join points on each curve with chords: they lie below a curve that bends downwards, above one that bends upwards, and along a straight line.",
			"%s bends %s all the way from x = %s to x = %s, so its chords lie %s it and the rule gives %s." % [pk.letter, bend_word, D(s.a), D(s.b), "below" if under else "above", word],
			"So %s." % Answer.text(ans)], ans.values)}}


# ── Measurements ─────────────────────────────────────────────

static func shape_what(s: Dictionary) -> String:
	return {"field": "width", "lake": "width", "canal": "depth"}[s.kind]


static func shape_line(s: Dictionary) -> String:
	var H := D(s.h)
	match s.kind:
		"field":
			return "%s maps a salvage field that lies along a straight road, between two fences at right angles to it. Its width from the road is measured every %s m along the road." % [who(s), H]
		"lake":
			return "A toxic lake lies between two straight, parallel dams %s m apart. %s measures its width every %s m from one dam to the other, parallel to the dams." % [D(s.h.mul(s.n)), who(s), H]
	return "%s measures the depth of a flooded canal every %s m across it, from one wall to the other." % [who(s), H]


static func shape_table(s: Dictionary, k_at: int = -1) -> Dictionary:
	var xs: Array = []
	var ys: Array = []
	for i in s.n + 1:
		xs.append(D(s.h.mul(i)))
		ys.append("k" if i == k_at else D(s.ys[i]))
	return {"rows": [["distance (m)", xs], ["%s (m)" % shape_what(s), ys]]}


## The field, lake or canal drawn with its widths or depths at equal spacing, each labelled.
static func shape_graph(s: Dictionary) -> Dictionary:
	var h: float = s.h.to_float()
	var L: float = h * s.n
	var tops: Array = []
	var bottoms: Array = []
	for i in s.n + 1:
		var w: float = s.ys[i].to_float()
		var x: float = h * i
		match s.kind:
			"field":
				tops.append(Vector2(x, w))
				bottoms.append(Vector2(x, 0.0))
			"lake":
				tops.append(Vector2(x, w * s.split[i]))
				bottoms.append(Vector2(x, -w * (1.0 - s.split[i])))
			_:
				tops.append(Vector2(x, 0.0))
				bottoms.append(Vector2(x, -w))
	var curves: Array = []
	if s.kind != "canal":
		curves.append(smooth(tops))
	if s.kind != "field":
		curves.append(smooth(bottoms))
	var points: Array = []
	var ylo := 0.0
	var yhi := 0.0
	for i in s.n + 1:
		curves.append([[tops[i].x, bottoms[i].y], [tops[i].x, tops[i].y]])
		ylo = minf(ylo, bottoms[i].y)
		yhi = maxf(yhi, tops[i].y)
		points.append([tops[i].x, (tops[i].y + bottoms[i].y) / 2.0, D(s.ys[i]) + " m"])
	var pad := (yhi - ylo) * 0.12 + 0.5
	var g := Plot.spec(curves, points, floori(-0.25 * h), ceili(L + 0.9 * h), floori(ylo - pad), ceili(yhi + pad))
	for p in g.points:
		p.name = true
	g.sand_from = 2 if s.kind == "lake" else 1
	g.x_ticks = range(s.n + 1).map(func(i): return [h * i, D(s.h.mul(i))])
	g.y_bare = true
	g.x_name = ""
	g.y_name = ""
	return g


func u_data_estimate(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var vals := S.data_slips(s)
	var ans := sf_ans("area = ", vals[0], " m²")
	var wr: Array = rng.shuffled([wrong({"v": vals[1]}, R_X_AS_Y), wrong({"v": vals[2]}, R_ENDS_DOUBLED), wrong({"v": vals[3]}, R_NO_DOUBLE),
		wrong({"v": vals[4]}, R_NO_HALF)])
	var ys: Array = s.ys
	var L: Q = s.h.mul(s.n)
	var fill: Array = [{"v": L.mul(ys[0].add(ys[-1])).div(2)}, {"v": vals[0].add(s.h)}]
	var what := shape_what(s)
	var lines: Array = [shape_line(s)]
	var graph: Variant = null
	var table: Variant = null
	if rep == "diagram":
		lines.append("The diagram shows each measured %s, in metres." % what)
		graph = shape_graph(s)
	else:
		lines.append("The table gives the %ss." % what)
		table = shape_table(s)
	var region: String = {"field": "the field", "lake": "the lake", "canal": "the canal's cross-section"}[s.kind]
	var steps := data_steps(s, ys.map(func(y): return D(y)), D(vals[0]), ans, "Area")
	return pack(lines, "Use the trapezoidal rule to estimate the area of %s." % region, ans, wr, fill, steps, graph, table)


## The two methods on a table of heights: the formula and strip by strip. `head` names the
## result, `then` adds a last step before the answer (a flow speed), `h_line` says what h is.
static func data_steps(s: Dictionary, yt: Array, result: String, ans: Dictionary, head: String, then: Array = [],
		h_line: String = "", h_q: Variant = null) -> Dictionary:
	var hq: Q = s.h if h_q == null else h_q
	var H := D(hq)
	var hl := "The measurements are %s m apart, so h = %s." % [D(s.h), H] if h_line == "" else h_line
	var areas: Array = []
	for i in s.n:
		areas.append(D(hq.mul(s.ys[i].add(s.ys[i + 1])).div(2)))
	return {
		"formula-with-data": [hl, "%s ≈ %s = %s" % [head, bracket(H, yt), result]] + then + [say(ans)],
		"strip-by-strip": [hl + " Strips: " + strips(H, yt, areas), "%s ≈ %s = %s" % [head, joined(areas), result]] + then + [say(ans)],
	}


# ── Totals from rates ────────────────────────────────────────

static func total_parts(s: Dictionary) -> Dictionary:
	var unit := "minutes" if s.mix or s.kind == "pipe" else "seconds"
	match s.kind:
		"rover":
			return {"t": "t (%s)" % ("min" if s.mix else "s"), "y": "v (m/s)", "what": "speed", "every": unit,
				"line": "A scout rover's speed v m/s is recorded every %s %s as it crosses the dunes." % [D(s.h), unit],
				"asked": "Use the trapezoidal rule to estimate the distance the rover travels in these %s %s, in metres." % [D(s.h.mul(s.n)), unit],
				"label": "distance = ", "unit": " m", "rate": "m/s"}
		"pipe":
			var rate := "litres per second" if s.mix else "litres per minute"
			return {"t": "t (min)", "y": "r (litres/%s)" % ("s" if s.mix else "min"), "what": "rate", "every": unit,
				"line": "Water is pumped from a deep well into a tank. The rate of flow r, in %s, is recorded every %s minutes." % [rate, D(s.h)],
				"asked": "Use the trapezoidal rule to estimate the volume of water pumped in these %s minutes, in litres." % D(s.h.mul(s.n)),
				"label": "volume = ", "unit": " litres", "rate": rate}
	return {"t": "distance (m)", "y": "depth (m)", "what": "depth", "every": "m",
		"line": "A drainage channel is %s m wide. Its depth is measured every %s m across it, and the water flows through it at %s m/s." % [D(s.h.mul(s.n)), D(s.h), D(s.v)],
		"asked": "Use the trapezoidal rule to estimate the area of the channel's cross-section, and hence the volume of water that flows through it each second.",
		"label": "flow = ", "unit": " m³/s", "rate": "m"}


## The rover's speeds as dots on whole grid lines, joined by a smooth curve.
static func speed_graph(s: Dictionary) -> Dictionary:
	var pts: Array = []
	var top := 0.0
	for i in s.n + 1:
		pts.append(Vector2(s.h.to_float() * i, s.ys[i].to_float()))
		top = maxf(top, s.ys[i].to_float())
	var curve: Array = smooth(pts).map(func(p): return [p[0], maxf(p[1], 0.0)])
	var g := Plot.spec([curve], pts.map(func(p): return [p.x, p.y, ""]), 0, ceili(pts[-1].x + s.h.to_float() / 2.0), -1, ceili(top) + 3)
	g.x_name = "t"
	g.y_name = "v"
	return g


func u_accumulated_total(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := total_parts(s)
	var vals := S.total_slips(s)
	# Whole speeds read off a graph can give a total that ends: it is then exact.
	var ans := sf_ans(c.label, vals[0], c.unit) if Answer.needs_rounding(vals[0]) else exact_ans(c.label, vals[0], c.unit)
	var wr: Array = [wrong({"v": vals[1]}, R_NO_HALF), wrong({"v": vals[2]}, R_ENDS_DOUBLED), wrong({"v": vals[3]}, R_NO_DOUBLE)]
	if s.mix:
		wr.append(wrong({"v": vals[4]}, R_UNITS))
	wr = rng.shuffled(wr)
	var ys: Array = s.ys
	var yt: Array = ys.map(func(y): return D(y))
	var t := S.rule_q(ys, s.h)
	var fill: Array = [{"v": vals[0].mul(Q.new(3, 2))}]
	if s.kind == "channel":
		fill.push_front({"v": t})
	var lines: Array = [c.line]
	var graph: Variant = null
	var table: Variant = null
	var times: Array = range(s.n + 1).map(func(i): return D(s.h.mul(i)))
	match rep:
		"graph":
			lines.append("The graph shows the speeds plotted at t = %s seconds." % ", ".join(times))
			graph = speed_graph(s)
		"words":
			var at := "at distances %s m from one side" % ", ".join(times) if s.kind == "channel" else "at t = %s %s" % [", ".join(times), c.every]
			lines.append("The %ss %s are %s and %s, in %s." % [c.what, at, ", ".join(yt.slice(0, -1)), yt[-1], c.rate])
		_:
			lines.append("The table gives the %ss." % c.what)
			table = {"rows": [[c.t, times], [c.y, yt]]}
	var steps: Dictionary
	match s.kind:
		"channel":
			steps = data_steps(s, yt, D(t) + " m²", ans, "Area", ["Flow = area × speed = %s × %s = %s m³/s" % [D(t), D(s.v), D(vals[0])]])
		_:
			var unit := "s" if s.kind == "rover" and not s.mix else "min"
			var h_line := "h = %s %s." % [D(s.h), unit]
			var hq: Variant = null
			if s.mix:
				hq = s.h.mul(60)
				h_line = "The %ss are in %s and the times in minutes: h = %s min = %s s." % [c.what, "metres per second" if s.kind == "rover" else c.rate, D(s.h), D(hq)]
			var head := "Distance" if s.kind == "rover" else "Volume"
			steps = data_steps(s, yt, D(vals[0]) + c.unit, ans, head, [], h_line, hq)
	return pack(lines, c.asked, ans, wr, fill, steps, graph, table)


# ── A missing height ─────────────────────────────────────────

func u_missing_height(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var vals := S.missing_slips(s)
	var k: Q = vals[0]
	var ans := exact_ans("k = ", k)
	var wr: Array = []
	var inner := S.inner(s)
	if inner:
		wr.append(wrong({"v": vals[1]}, R_INNER_ONCE))
		wr.append(wrong({"v": ends_or_sf(vals[2])}, R_NO_H_HALF))
	else:
		wr.append(wrong({"v": ends_or_sf(vals[1])}, R_NO_H_HALF))
		wr.append(wrong({"v": vals[2]}, R_ENDS_DOUBLED))
	var area := S.rule_q(s.ys, s.h)
	var w := 2 if inner else 1
	var rest: Q = area.mul(2).div(s.h).sub(k.mul(w))
	var what := shape_what(s)
	var H := D(s.h)
	var yt: Array = []
	for i in s.n + 1:
		yt.append("k" if i == s.j else D(s.ys[i]))
	var expr := bracket(H, yt)
	var two_a := area.mul(2).div(s.h)
	var kw := "k" if w == 1 else "2k"
	var fill: Array = [{"v": k.add(Q.new(1))}, {"v": k.mul(3)}]
	return pack([shape_line(s), "The table gives the %ss, with one of them k. The trapezoidal rule with these %ss gives %s m² for the area." % [what, what, D(area)]],
		"Find the value of k.", ans, wr, fill, {
		"linear-equation": ["h = %s, and k is %s, so it counts %s: %s = %s." % [H, "an inner height" if inner else "an end height", "twice" if inner else "once", D(area), expr],
			"So %s + %s = %s × 2 ÷ %s = %s." % [D(rest), kw, D(area), H, D(two_a)],
			"%s = %s − %s = %s" % [kw, D(two_a), D(rest), D(two_a.sub(rest))], say(ans)],
		"gdc-solver": ["Enter %s = %s in the equation solver, with k as the unknown." % [expr, D(area)],
			"The solver gives k = %s." % D(k)],
	}, null, shape_table(s, s.j))
