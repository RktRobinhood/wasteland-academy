class_name AreaUnderCurveViews
extends ExtensionViews
## The views on the `area-under-curve` situation: one builder per unknown of
## t5-ext-area-under-curve (FAL-776). An integral to write is a pick of four written integrals;
## an area is DefiniteIntegralViews' `form` answer, exact on Paper 1 and to 3 s.f. on Paper 2;
## region-for-integral is pick the graph, four figures each shading one region. Every unknown
## also plays as true-false-reason.
##
## Representations: "graph" (the curve with R shaded, its edges marked), "words" (f(x) and the
## lines and axes that bound R) and "equation" (an integral written out, to match to its region).

const SE := "SL5.5.area-expression#"
const SP := "SL5.5.area-positive#"
const R_Y_LIMITS := SE + "0"
const R_SWAPPED := SE + "1"
const R_DERIVATIVE := SE + "2"
const R_UPPER_LOWER := SP + "0"
const R_FROM_ZERO := SP + "1"
const R_ROUNDED := SP + "2"
const UNKNOWNS := ["integral-from-graph", "integral-from-roots", "region-for-integral", "area-between-lines",
	"area-between-roots", "area-with-y-axis", "area-straight-edge", "area-gdc-limits"]
const S := preload("res://engine/situations/area_under_curve.gd")
const DV := preload("res://engine/situations/definite_integral_views.gd")
const DI := preload("res://engine/situations/definite_integral.gd")


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		if u != "region-for-integral":
			out[u] = ["true-false-reason"]
	return out


func papers(unknown: String, _rep: String, angle: String) -> Array:
	if not has(unknown):
		return []
	return [2] if angle.begins_with("gdc-") or unknown == "area-gdc-limits" else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = S.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func f_text(s: Dictionary) -> String:
	if s.fam == "wave":
		return DifferentiationViews.SUM([[s.c, ""], [1, "x e^(−x/2)"]])
	return Fmt.poly(s.coeffs)


static func fn(s: Dictionary) -> Callable:
	return S.wave(s) if s.fam == "wave" else S.poly_fn(s.coeffs)


static func I(s: Dictionary, lo: Variant, hi: Variant, f: String = "") -> String:
	return DV.integral_text(f_text(s) if f == "" else f, lo, hi)


## f′ written out, for the slip that integrates the derivative.
static func d_text(s: Dictionary) -> String:
	var co: Array = s.coeffs
	var n := co.size()
	var d: Array = []
	for i in n - 1:
		d.append(Q.of(co[i]).mul(n - 1 - i))
	return Fmt.poly(d)


## (−1, 0) style factor form of a hump: "−(x + 1)(x − 3)".
static func factored(s: Dictionary) -> String:
	return Fmt.lead(-s.a) + Fmt.factor(s.r) + Fmt.factor(s.t)


## The curve on a window that holds R and its roots, with R shaded and its edges marked.
static func figure(s: Dictionary, lo: float, hi: float, marks: Array = [], vlines: Array = []) -> Dictionary:
	var left: float = minf(lo, float(s.get("r", lo))) - 0.6
	var right: float = maxf(hi, float(s.get("t", hi))) + 0.6
	left = minf(left, -0.6)
	var g := DV.figure(fn(s), left, right, [[lo, hi]], marks)
	g.vlines = vlines.map(func(v): return {"at": float(v), "label": "x = %s" % N(v)})
	return g


static func pack(lines: Array, asked: String, ans: Dictionary, wr: Array, gen: Array, methods: Dictionary, graph: Variant = null) -> Dictionary:
	return DV.pack(lines, asked, ans, wr, gen, methods, graph)


static func area_ans(s: Dictionary, v: Variant) -> Dictionary:
	return DV.val(v, s.paper == 2)


static func W(x: Variant) -> String:
	return GdcKit.W(x)


## The givens: the graph with R shaded, or f(x) and what bounds R in words.
static func show(s: Dictionary, rep: String, lo: Variant, hi: Variant, bound: String, vlines: Array = [], marks: Array = []) -> Dictionary:
	if rep == "graph":
		return {"lines": ["The graph of y = %s is shown. R is shaded." % f_text(s)], "graph": figure(s, float(lo), float(hi), marks, vlines)}
	return {"lines": ["f(x) = %s" % f_text(s), "R is the region %s." % bound], "graph": null}


# ── Writing the integral ─────────────────────────────────────

func u_integral_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var right := I(s, p, q)
	var out := {"asked": "Which integral gives the area of R?", "lines": ["The graph of y = %s is shown. R is shaded." % f_text(s)],
		"graph": figure(s, float(p), float(q), [], [p, q])}
	out.merge(InverseRuleViews.choose(right, [InverseRuleViews.tag(I(s, S.at(s, p), S.at(s, q)), R_Y_LIMITS),
		InverseRuleViews.tag(I(s, q, p), R_SWAPPED), InverseRuleViews.tag(I(s, p, q, d_text(s)), R_DERIVATIVE)], [I(s, s.r, s.t)]))
	out.methods = {"read-boundaries": method(["R's left and right edges are the lines x = %s and x = %s." % [N(p), N(q)],
		"Its top is the curve y = %s and its bottom is the x-axis." % f_text(s), right + "."], {"v": right})}
	return out


func u_integral_from_roots(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := {"asked": "Which integral gives the area of R?", "lines": ["f(x) = %s" % f_text(s), "R is the region enclosed by the curve y = f(x) and the x-axis."]}
	if s.fam == "surd":
		var lo := GdcKit.S(s.r1)
		var hi := GdcKit.S(s.r2)
		var right := I(s, lo, hi)
		out.merge(InverseRuleViews.choose(right, [InverseRuleViews.tag(I(s, hi, lo), R_SWAPPED), InverseRuleViews.tag(I(s, lo, hi, d_text(s)), R_DERIVATIVE)],
			[I(s, 0, hi), I(s, lo, 0)]))
		out.methods = {"gdc-zeros": method(["Graph y = %s on the GDC and find its zeros: x = %s and x = %s." % [f_text(s), W(s.r1), W(s.r2)],
			"Between them the curve is above the x-axis, so R runs from one zero to the other.", right + "."], {"v": right})}
		return out
	var right := I(s, s.r, s.t)
	out.merge(InverseRuleViews.choose(right, [InverseRuleViews.tag(I(s, s.t, s.r), R_SWAPPED), InverseRuleViews.tag(I(s, s.r, s.t, d_text(s)), R_DERIVATIVE)],
		[I(s, 0, s.t), I(s, s.r, 0)]))
	out.methods = {"solve-for-roots": method(["f(x) = %s = 0, so x = %s or x = %s." % [factored(s), N(s.r), N(s.t)],
		"Between the roots the curve is above the x-axis, so R runs from x = %s to x = %s." % [N(s.r), N(s.t)], right + "."], {"v": right})}
	return out


func u_region_for_integral(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var card := func(lo: int, hi: int) -> Dictionary:
		var g := figure(s, float(lo), float(hi))
		g.card = true
		return g
	var wrongs := [
		{"graph": card.call(0, q), "mistake": "from-zero", "ref": "", "why": "it starts at x = 0, not at x = %s" % N(p)},
		{"graph": card.call(p, s.t), "mistake": "to-root", "ref": "", "why": "it runs on to the root at x = %s, past x = %s" % [N(s.t), N(q)]},
		{"graph": card.call(s.r, p), "mistake": "left-part", "ref": "", "why": "it is the part left of x = %s" % N(p)},
	]
	var pk := GdcKit.pick(card.call(p, q), wrongs, rng)
	var ans: Dictionary = pk.answer
	return {"asked": "Which graph shows the region whose area this integral gives?", "lines": [I(s, p, q)], "answer": ans, "graphs": pk.graphs,
		"methods": {"read-boundaries": method(["The limits are x = %s and x = %s, and the integrand is %s." % [N(p), N(q), f_text(s)],
			"So the region is under y = %s from x = %s to x = %s: %s." % [f_text(s), N(p), N(q), Answer.text(ans)]], ans.values)}}


# ── Finding the area ─────────────────────────────────────────

## F(x) = …, then F(hi) − F(lo).
static func by_hand(s: Dictionary, lo: int, hi: int, v: Q) -> Array:
	return ["F(x) = %s." % DV.anti(s.coeffs),
		"F(%s) − F(%s) = %s − %s = %s." % [N(hi), N(lo), N(S.area(s, 0, hi)), P(S.area(s, 0, lo)), N(v)]]


func u_area_between_lines(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var g := show(s, rep, float(p), float(q), "enclosed by the curve y = f(x), the x-axis and the lines x = %s and x = %s" % [N(p), N(q)], [p, q])
	if s.fam == "wave":
		var ans := DV.val(s.v, true)
		var gen: Array = DV.vals(ans, [s.v0]) if p > 0 else []
		return pack(g.lines, "Find the area of R.", ans, [DV.like(ans, -s.v, R_UPPER_LOWER)], gen,
			{"gdc-integral": ["Enter %s in the GDC's ∫dx template, from x = %d to x = %d." % [f_text(s), p, q], "The GDC gives %s." % W(s.v)]}, g.graph)
	var v := S.area(s, p, q)
	var ans := area_ans(s, v)
	var gen := DV.vals(ans, [S.area(s, 0, q), S.at(s, q).sub(S.at(s, p))])
	var methods := {"antiderivative-evaluate": by_hand(s, p, q, v)}
	if s.paper == 2:
		methods = {"gdc-integral": ["Enter %s in the GDC's ∫dx template, from x = %d to x = %d." % [f_text(s), p, q], "The GDC gives %s." % W(v)]}
	return pack(g.lines, "Find the area of R.", ans, [DV.like(ans, v.neg(), R_UPPER_LOWER)], gen, methods, g.graph)


func u_area_between_roots(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: int = s.r
	var t: int = s.t
	var g := show(s, rep, float(r), float(t), "enclosed by the curve y = f(x) and the x-axis", [], [[r, 0, "(%s, 0)" % N(r)], [t, 0, "(%s, 0)" % N(t)]])
	if rep == "graph":
		g.lines = ["The graph of y = %s is shown. R, between the curve and the x-axis, is shaded." % f_text(s)]
	var v := S.area(s, r, t)
	var ans := area_ans(s, v)
	var wr: Array = [DV.like(ans, v.neg(), R_UPPER_LOWER), DV.like(ans, S.area(s, 0, t), R_FROM_ZERO)]
	var methods := {"antiderivative-evaluate": ["f(x) = %s = 0 at x = %s and x = %s, so R runs from x = %s to x = %s." % [factored(s), N(r), N(t), N(r), N(t)]] + by_hand(s, r, t, v)}
	if s.paper == 2:
		methods = {"gdc-integral": ["The roots of f(x) = %s are x = %s and x = %s." % [factored(s), N(r), N(t)],
			"Enter %s in the GDC's ∫dx template, from x = %d to x = %d." % [f_text(s), r, t], "The GDC gives %s." % W(v)]}
	return pack(g.lines, "Find the area of R.", ans, wr, [], methods, g.graph)


func u_area_with_y_axis(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: int = s.t
	var g := show(s, rep, 0.0, float(t), "bounded by the curve y = f(x), the x-axis and the y-axis, where x ≥ 0", [], [[t, 0, "(%s, 0)" % N(t)]])
	var v := S.area(s, 0, t)
	var ans := area_ans(s, v)
	var methods := {"antiderivative-evaluate": ["R runs from the y-axis, x = 0, to the root x = %s." % N(t)] + by_hand(s, 0, t, v)}
	return pack(g.lines, "Find the area of R.", ans, [DV.like(ans, v.neg(), R_UPPER_LOWER)], DV.vals(ans, [S.area(s, s.r, t), S.area(s, s.r, 0)]), methods, g.graph)


func u_area_straight_edge(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var g := show(s, rep, float(p), float(q), "enclosed by the line y = f(x), the x-axis and the lines x = %s and x = %s" % [N(p), N(q)], [p, q])
	if rep == "graph":
		g.lines = ["The graph of the line y = %s is shown. R is shaded." % f_text(s)]
	var v := S.area(s, p, q)
	var ans := area_ans(s, v)
	var fp := S.at(s, p)
	var fq := S.at(s, q)
	var gen := DV.vals(ans, [fq.mul(q - p), fp.add(fq).mul(q - p), S.area(s, 0, q)])
	var methods := {
		"geometric-shapes": ["R is a trapezium: its parallel sides are f(%s) = %s and f(%s) = %s, a distance %d apart." % [N(p), N(fp), N(q), N(fq), q - p],
			"Area = ½ × (%s + %s) × %d = %s." % [N(fp), N(fq), q - p, N(v)]],
		"antiderivative-evaluate": by_hand(s, p, q, v),
	}
	return pack(g.lines, "Find the area of R.", ans, [], gen, methods, g.graph)


func u_area_gdc_limits(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := DV.val(s.v, true)
	var lines := ["f(x) = %s" % f_text(s), "R is the region enclosed by the curve y = f(x) and the x-axis."]
	var methods := {"gdc-integral": ["Graph y = %s on the GDC and find its zeros: x = %s and x = %s. Keep them stored, not rounded." % [f_text(s), W(s.r1), W(s.r2)],
		"∫ from the first zero to the second of f(x) dx on the GDC gives %s." % W(s.v)]}
	var f := S.poly_fn(s.coeffs)
	return pack(lines, "Find the area of R, to 3 s.f.", ans, [DV.like(ans, s.slip, R_ROUNDED)],
		DV.vals(ans, [DI.simpson(f, 0.0, s.r2), DI.simpson(f, s.r1, 0.0)]), methods)
