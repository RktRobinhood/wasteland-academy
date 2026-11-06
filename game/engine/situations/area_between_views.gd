class_name AreaBetweenViews
extends ExtensionViews
## The views on the `area-between` situation: one builder per unknown of t5-area-between-curves
## (FAL-751). Paper 1 is exact: a `form` answer in DefiniteIntegralViews' shape, with π, a surd or
## e where the curves have them. Paper 2 is a `number` to 3 s.f. with the rounding trap, on curves
## that need a GDC. A figure shades the region in GraphView's `shade`, between the two curves.
##
## Representations: "equation" (the two curves), "graph" (the curves named f and g, with the
## region shaded) and "diagram" (no equations: a parabola and a line to find from marked points).

const AB := "SL5.11.area-between-curves#"
const R_NEGATIVE := AB + "0"
const R_X_INTERCEPTS := AB + "1"
const R_NO_SPLIT := AB + "2"
const R_Y_VALUES := AB + "3"
const R_ADDED := AB + "4"
const R_BRACKET := AB + "5"
const R_ONE_PIECE := AB + "6"
const R_ADD_CURVES := AB + "7"
const R_ONE_SIDE := AB + "8"
const R_NO_WIDTH := AB + "9"
const R_CUBE := AB + "10"
const R_NO_HALF := AB + "11"
const R_RISE_FALL := AB + "12"
const R_NO_DOUBLE := AB + "13"
const R_ONE_TOP := AB + "14"
const R_MULT_K := "SL5.10.linear-composites#0"
const R_LOWER_ZERO := "SL5.11.evaluate-definite#1"

const UNKNOWNS := ["meeting-limits", "integral-expression", "split-expression", "area-line-curve", "area-two-parabolas",
	"area-split-cubic", "area-split-bounded", "area-trig", "area-trig-split", "area-exp-lines", "find-shift", "find-parameter",
	"derivative-areas", "gdc-meeting-limits", "gdc-area", "gdc-area-split", "inverse-area", "region-two-lines"]
## These curves need a GDC, as these parts of the bank do.
const P2_ONLY := ["gdc-meeting-limits", "gdc-area", "gdc-area-split", "inverse-area", "region-two-lines"]
const AREA := "Area = "
const AV := "Area = ∫ from "


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## A GDC method is Paper 2 and so is every pair of curves that needs one. The rest is Paper 1.
func papers(unknown: String, _rep: String, method_id: String) -> Array:
	if not has(unknown):
		return []
	return [2] if method_id.begins_with("gdc-") or unknown in P2_ONLY else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = AreaBetweenSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func SUM(terms: Array) -> String:
	return DifferentiationViews.SUM(terms)


static func T(c: Variant, body: String) -> String:
	return DifferentiationViews.T(c, body)


static func ex(v: Variant) -> Dictionary:
	return DefiniteIntegralViews.val(v, false, AREA)


## An area on Paper 2, to 3 s.f. with the rounding trap.
static func sf(v: float, label: String = AREA) -> Dictionary:
	var ans := Answer.make("number", {"v": GdcKit.qf(v)}, {}, label)
	ans.show = "sf"
	return ans


## A wrong value in the answer's own shape.
static func like(ans: Dictionary, v: Variant, ref: String = "") -> Dictionary:
	if ans.kind == "number":
		return wrong({"v": GdcKit.qf(v) if v is float else Q.of(v)}, ref)
	return DefiniteIntegralViews.like(ans, v, ref)


static func vals(ans: Dictionary, list: Array) -> Array:
	return list.map(func(v): return like(ans, v).values)


static func alt(text: String, ref: String = "") -> Dictionary:
	return DifferentiationViews.alt(text, ref)


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func fp(co: Array) -> String:
	return Fmt.poly(co)


static func anti(co: Array) -> String:
	return DefiniteIntegralViews.anti(co)


static func integral(body: String, lo: Variant, hi: Variant) -> String:
	return DefiniteIntegralViews.integral_text(body, lo, hi)


## "(x − 1)(x + 2)", with the number in front.
static func factors(k: Variant, p: Variant, q: Variant) -> String:
	return Fmt.lead(k) + _bracket(p) + _bracket(q)


static func _bracket(p: Variant) -> String:
	return "x" if Q.of(p).is_zero() else "(%s)" % Answer.x_minus(p)


## The lines of a pair: equations, and what they say about the region. On a graph the curves are
## named f and g.
static func two(rep: String, f: String, g: String, eq_tail: String, graph_tail: String) -> Array:
	if rep == "equation":
		return ["y = " + f, "y = " + g, eq_tail]
	return ["f(x) = " + f, "g(x) = " + g, graph_tail]


static func pack(lines: Array, asked: String, ans: Dictionary, wr: Array, gen: Array, methods: Dictionary, graph: Variant = null, titles: Dictionary = {}) -> Dictionary:
	var ms := {}
	for id in methods:
		ms[id] = method(methods[id].map(DefiniteIntegralViews.minus) + [say(ans)], ans.values)
	var out := {"lines": lines.map(DefiniteIntegralViews.minus), "asked": DefiniteIntegralViews.minus(asked), "answer": ans, "wrongs": wr,
		"generic": gen, "methods": ms, "graph": graph}
	if not titles.is_empty():
		out.titles = titles
	return out


## Strips between two curves on [a, b]: [x, lower, upper].
static func strips(f: Callable, g: Callable, a: float, b: float) -> Array:
	var out: Array = []
	for i in 81:
		var x := a + (b - a) * i / 80.0
		var u: float = f.call(x)
		var v: float = g.call(x)
		out.append([x, minf(u, v), maxf(u, v)])
	return out


## A figure: the curves on [lo, hi], the regions ([f, g, a, b] each) shaded, the points, and each
## curve's name written on it where there is room.
static func figure(fns: Array, lo: float, hi: float, regions: Array, points: Array, names: Array = [], clip: Array = []) -> Dictionary:
	var shade: Array = regions.map(func(r): return strips(r[0], r[1], r[2], r[3]))
	var ylo := 0.0
	var yhi := 0.0
	for r in shade:
		for st in r:
			ylo = minf(ylo, st[1])
			yhi = maxf(yhi, st[2])
	for p in points:
		ylo = minf(ylo, float(p[1]))
		yhi = maxf(yhi, float(p[1]))
	var span := maxf(yhi - ylo, 1.0)
	var wy0 := floori(ylo - 0.25 * span)
	var wy1 := ceili(yhi + 0.25 * span)
	var marks: Array = points.duplicate()
	for i in names.size():
		var spot := _name_spot(fns, i, lo, hi, float(wy0), float(wy1))
		if not spot.is_empty():
			marks.append([spot[0], spot[1], names[i]])
	var cs: Array = []
	for i in fns.size():
		var a: float = clip[i][0] if not clip.is_empty() else lo
		var b: float = clip[i][1] if not clip.is_empty() else hi
		cs.append(GdcKit.curve(fns[i], a, b))
	var g := Plot.spec(cs, marks, floori(lo), ceili(hi), wy0, wy1)
	g.shade = shade
	for i in range(points.size(), marks.size()):
		g.points[i].name = true
	return g


## A place on curve i inside the window and clear of the other curves, near an end if it can be.
static func _name_spot(fns: Array, i: int, lo: float, hi: float, y0: float, y1: float) -> Array:
	var f: Callable = fns[i]
	var room := (y1 - y0) * 0.1
	var best: Array = []
	for t in [0.93, 0.07, 0.86, 0.14, 0.78, 0.22, 0.7, 0.3]:
		var x: float = lo + (hi - lo) * t
		var y: float = f.call(x)
		if not is_finite(y) or y < y0 + room * 0.5 or y > y1 - room * 0.5:
			continue
		if best.is_empty():
			best = [x, y]
		var clear := true
		for j in fns.size():
			if j != i and absf(float(fns[j].call(x)) - y) < room:
				clear = false
		if clear:
			return [x, y]
	return best


static func poly_fn(co: Array) -> Callable:
	return DefiniteIntegralViews.poly_fn(co.map(func(c): return Q.of(c).to_float()))


## A value c0 + c1√r, scaled.
static func sv(v: Array, k: int = 1) -> Array:
	return [q_of(v[0]).mul(k), q_of(v[1]).mul(k), v[2]]


static func q_of(c: Variant) -> Q:
	return Q.new(c[0], c[1]) if c is Array else Q.of(c)


static func sv_text(v: Array) -> String:
	return SUM([[v[1], "√%d" % v[2]], [v[0], ""]])


## An exact area with a surd in it: typed by its numbers, whatever shape the value has.
static func sv_ans(v: Array) -> Dictionary:
	if v[1].is_zero():
		return ex(v[0])
	var text: String = AREA + sv_text(v)
	var root := "√%d" % v[2]
	if v[0].is_zero():
		return DifferentiationViews.form(text, [AREA, {"slot": "s"}, root], {"s": v[1]})
	return DifferentiationViews.form(text, [AREA, {"slot": "s"}, root + " + ", {"slot": "w"}], {"s": v[1], "w": v[0]})


## A wrong value beside an exact area with a surd: a typed one if it has the answer's shape.
static func sv_like(ans: Dictionary, v: Array, ref: String = "") -> Dictionary:
	var other: Dictionary = sv_ans(v)
	if str(other.template.size()) == str(ans.template.size()):
		return wrong(other.values, ref)
	return alt(AREA + sv_text(v), ref)


## nπ/d as it reads: "π/4", "5π/6", "π", "0".
static func angle_text(a: Array) -> String:
	if a[0] == 0:
		return "0"
	var top: String = "π" if a[0] == 1 else "%dπ" % a[0]
	return top if a[1] == 1 else "%s/%d" % [top, a[1]]


static func angle_val(a: Array) -> float:
	return PI * a[0] / a[1]


## A trig curve at A = 1: "sin x", "cos(2x)".
static func trig_fn(text: String, A: int) -> Callable:
	var w := 2.0 if text.contains("2x") else 1.0
	if text.begins_with("sin"):
		return func(x: float) -> float: return A * sin(w * x)
	return func(x: float) -> float: return A * cos(w * x)


static func trig_text(text: String, A: int) -> String:
	return T(A, text)


# ── The limits ───────────────────────────────────────────────

func u_meeting_limits(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var f := fp(s.par)
	var g := fp(s.line)
	var gap := AreaBetweenSituation.minus(s.par, s.line)
	var ans := Answer.make("roots", {"r1": Q.new(p), "r2": Q.new(q)})
	ans.exact = true
	var yp := AreaBetweenSituation.at(s.line, p)
	var yq := AreaBetweenSituation.at(s.line, q)
	var lim := func(a: Variant, b: Variant, ref: String = "") -> Dictionary: return wrong({"r1": Q.of(a), "r2": Q.of(b)}, ref)
	var wr: Array = [lim.call(s.r, s.t, R_X_INTERCEPTS)]
	if not yp.eq(yq):
		wr.append(lim.call(yp, yq, R_Y_VALUES))
	var gen: Array = [lim.call(-p, -q).values, lim.call(p, q + 1).values, lim.call(p - 1, q).values, lim.call(p + 1, q + 1).values]
	var g_spec: Variant = null
	if rep == "graph":
		g_spec = _line_curve_figure(s, [[p, yp.to_float(), "A"], [q, yq.to_float(), "B"]])
	return pack(two(rep, f, g, "The curve and the line meet at A and B.", "The diagram shows the graphs of f and g, which enclose the shaded region. They meet at A and B."),
		"Find the x-coordinates of A and B.", ans, wr, gen,
		{"top-minus-bottom": [
			"At a meeting point the two heights are equal: %s = %s." % [f, g],
			"Collect the terms on one side: %s = 0." % fp(gap),
			"Factorise: %s = 0." % factors(s.a, p, q)]}, g_spec,
		{"top-minus-bottom": "Set the curves equal, as the first step of top minus bottom"})


func u_gdc_meeting_limits(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z: Array = s.z
	var f := AreaBetweenSituation.text(s.cf)
	var g := AreaBetweenSituation.text(s.cg)
	var dom := "for %s ≤ x ≤ %s" % [W(s.lo), W(s.hi)]
	var ans := Answer.make("roots", {"r1": GdcKit.qf(z[0]), "r2": GdcKit.qf(z[1])})
	ans.show = "sf"
	var lim := func(a: float, b: float, ref: String = "") -> Dictionary: return wrong({"r1": GdcKit.qf(a), "r2": GdcKit.qf(b)}, ref)
	var wr: Array = []
	if s.has("roots"):
		wr.append(lim.call(float(s.roots[0]), float(s.roots[1]), R_X_INTERCEPTS))
	wr.append(lim.call(s.yz[0], s.yz[1], R_Y_VALUES))
	var gen: Array = [lim.call(z[0], z[1] + 1.0).values, lim.call(z[0] - 1.0, z[1]).values, lim.call(-z[0], z[1]).values, lim.call(z[0] + 0.5, z[1] + 0.5).values]
	var g_spec: Variant = null
	if rep == "graph":
		g_spec = _gdc_figure(s, [[z[0], s.yz[0], "A"], [z[1], s.yz[1], "B"]])
	return pack(two(rep, f, g, "The curves meet twice, at A and B, %s." % dom, "The diagram shows the graphs of f and g, %s. They meet at A and B." % dom),
		"Find the x-coordinates of A and B, to 3 s.f.", ans, wr, gen,
		{"gdc-abs-difference": [
			"Graph both curves on the GDC, with the window set to the domain.",
			"The intersect tool gives x = %s and x = %s." % [GdcKit.W(z[0]), GdcKit.W(z[1])]]}, g_spec,
		{"gdc-abs-difference": "GDC: the intersect tool, as the first step of ∫ |f − g| dx"})


## The integrand and limits typed by their numbers.
static func expr_form(lo: int, hi: int, co: Array) -> Dictionary:
	var text := "%s%s to %s of (%s) dx" % [AV, N(lo), N(hi), fp(co)]
	return DifferentiationViews.form(text, [AV, {"slot": "lo"}, " to ", {"slot": "hi"}, " of (", {"slot": "c2"}, "x² + ", {"slot": "c1"}, "x + ", {"slot": "c0"}, ") dx"],
		{"lo": Q.new(lo), "hi": Q.new(hi), "c2": Q.of(co[0]), "c1": Q.of(co[1]), "c0": Q.of(co[2])})


func u_integral_expression(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var gap: Array = s.gap
	var neg: Array = gap.map(func(c): return Q.of(c).neg())
	var ans := expr_form(p, q, gap)
	var wr: Array = [wrong(expr_form(p, q, neg).values, R_NEGATIVE), wrong(expr_form(s.r, s.t, gap).values, R_X_INTERCEPTS)]
	var bump: Array = [gap[0], gap[1], Q.of(gap[2]).add(1)]
	var gen: Array = [expr_form(p, q + 1, gap).values, expr_form(p - 1, q, gap).values, expr_form(p, q, bump).values, expr_form(p - 1, q + 1, gap).values]
	var graph: Variant = null
	var lines: Array
	var first: Array = []
	if rep == "diagram":
		graph = _diagram(s)
		lines = _diagram_lines()
		first = _diagram_steps(s)
	else:
		if rep == "graph":
			graph = _line_curve_figure(s, _corners(s))
		lines = two(rep, fp(s.par), fp(s.line), "The curve and the line enclose a region.", "The diagram shows the graphs of f and g, and the region they enclose is shaded.")
	var who: String = "curve" if s.par_top else "line"
	var steps: Array = first + [
		"They meet at x = %d and x = %d, which are the limits, and the %s is on top between them." % [p, q, who],
		"Top minus bottom is (%s) − (%s) = %s." % [fp(s.par if s.par_top else s.line), fp(s.line if s.par_top else s.par), fp(gap)]]
	return pack(lines, "Write down an integral expression for the area of the region. Do not evaluate it.", ans, wr, gen, {"top-minus-bottom": steps}, graph)


func u_split_expression(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	if s.paper == 2:
		return _split_expression_gdc(rep, s)
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var f_first: bool = s.p1.sign() > 0
	var one := "(f(x) − g(x))" if f_first else "(g(x) − f(x))"
	var two_ := "(g(x) − f(x))" if f_first else "(f(x) − g(x))"
	var mk := func(l1: int, h1: int, l2: int, h2: int, u: String, v: String) -> Dictionary:
		var text := "%s%s to %s of %s dx + ∫ from %s to %s of %s dx" % [AV, N(l1), N(h1), u, N(l2), N(h2), v]
		return DifferentiationViews.form(text, [AV, {"slot": "l1"}, " to ", {"slot": "h1"}, " of %s dx + ∫ from " % u, {"slot": "l2"}, " to ", {"slot": "h2"}, " of %s dx" % v],
			{"l1": Q.new(l1), "h1": Q.new(h1), "l2": Q.new(l2), "h2": Q.new(h2)})
	var ans: Dictionary = mk.call(a, b, b, c, one, two_)
	var wr: Array = [alt("%s%s to %s of %s dx" % [AV, N(a), N(c), one], R_NO_SPLIT), alt(ans.values.text.replace(one, "@").replace(two_, one).replace("@", two_), R_NEGATIVE)]
	var gen: Array = [mk.call(a, c, b, c, one, two_).values, mk.call(a, b, a, c, one, two_).values, mk.call(b, c, a, b, one, two_).values, mk.call(a, b + 1, b + 1, c, one, two_).values]
	var graph: Variant = null
	if rep == "graph":
		graph = _swap_figure(s, float(a), float(c), [float(a), float(b), float(c)], [a, b, c])
	var lines: Array = ["f(x) = " + fp(s.f), "g(x) = " + fp(s.g),
		("The diagram shows the graphs of f and g, and the two regions between them are shaded." if rep == "graph" else "The graphs of f and g meet at three points and enclose two regions.")]
	var top1 := "f" if f_first else "g"
	var top2 := "g" if f_first else "f"
	return pack(lines, "Write down an expression, with no modulus, for the total area of the two regions. Do not evaluate it.", ans, wr, gen,
		{"split-at-crossings": [
			"f(x) − g(x) = %s, so the graphs meet at x = %d, x = %d and x = %d." % [_cubic_factors(s), a, b, c],
			"%s is on top from x = %d to x = %d, and %s from x = %d to x = %d." % [top1, a, b, top2, b, c],
			"Each piece is top minus bottom, so each integral is positive."]}, graph)


func _split_expression_gdc(rep: String, s: Dictionary) -> Dictionary:
	var z: Array = s.z
	var body := "|f(x) − g(x)|"
	var mk := func(a: float, b: float) -> Dictionary:
		var ans := DifferentiationViews.form("%s%s to %s of %s dx" % [AV, Fmt.sf(a), Fmt.sf(b), body], [AV, {"slot": "lo"}, " to ", {"slot": "hi"}, " of %s dx" % body],
			{"lo": GdcKit.qf(a), "hi": GdcKit.qf(b)})
		ans.exact = false
		return ans
	var ans: Dictionary = mk.call(z[0], z[2])
	var wr: Array = [alt("%s%s to %s of (f(x) − g(x)) dx" % [AV, Fmt.sf(z[0]), Fmt.sf(z[2])], R_NO_SPLIT), wrong(mk.call(z[0], z[1]).values, R_ONE_PIECE)]
	var gen: Array = [mk.call(z[1], z[2]).values, mk.call(s.lo, s.hi).values, mk.call(z[0], z[2] + 1.0).values, mk.call(z[0] - 1.0, z[2]).values]
	var graph: Variant = null
	if rep == "graph":
		graph = _gdc_swap_figure(s)
	var lines: Array = ["f(x) = " + AreaBetweenSituation.text(s.cf), "g(x) = " + AreaBetweenSituation.text(s.cg),
		"%s, for %s ≤ x ≤ %s." % ["The diagram shows the graphs of f and g, and the two regions between them are shaded" if rep == "graph" else "The graphs of f and g meet at three points and enclose two regions", W(s.lo), W(s.hi)]]
	return pack(lines, "Write down one integral for the total area of the two regions, with its limits to 3 s.f. Do not evaluate it.", ans, wr, gen,
		{"gdc-abs-difference": [
			"The intersect tool gives x = %s, x = %s and x = %s." % [GdcKit.W(z[0]), GdcKit.W(z[1]), GdcKit.W(z[2])],
			"The modulus makes every strip positive, whichever curve is on top, so one integral covers both regions.",
			"Its limits are the outer meeting points."]}, graph)


# ── Paper 1: a parabola and a line, two parabolas ────────────

static func _par_line_fns(s: Dictionary) -> Array:
	return [poly_fn(s.par), poly_fn(s.line)]


static func _corners(s: Dictionary) -> Array:
	return [[s.p, AreaBetweenSituation.at(s.line, s.p).to_float(), Fmt.point(s.p, AreaBetweenSituation.at(s.line, s.p))],
		[s.q, AreaBetweenSituation.at(s.line, s.q).to_float(), Fmt.point(s.q, AreaBetweenSituation.at(s.line, s.q))]]


static func _line_curve_figure(s: Dictionary, points: Array) -> Dictionary:
	var fs := _par_line_fns(s)
	var lo := float(mini(s.p, s.r)) - 1.0
	var hi := float(maxi(s.q, s.t)) + 1.0
	return figure(fs, lo, hi, [[fs[0], fs[1], float(s.p), float(s.q)]], points, ["f", "g"])


## The marked points of a figure with no equations: the parabola's roots and the meeting points.
static func _diagram(s: Dictionary) -> Dictionary:
	var marks: Array = [[s.r, 0, Fmt.point(s.r, 0)], [s.t, 0, Fmt.point(s.t, 0)]]
	for p in _corners(s):
		if int(p[0]) != s.r and int(p[0]) != s.t:
			marks.append(p)
	var g := _line_curve_figure(s, marks)
	return g


static func _diagram_lines() -> Array:
	return ["The diagram shows the graph of a quadratic function f and a straight line g, which meet at the two ends of the shaded region. The coordinates of the marked points are shown."]


## The two equations, from the marked points.
static func _diagram_steps(s: Dictionary) -> Array:
	var x0: int = s.p if s.p != s.r and s.p != s.t else s.q
	var y0 := AreaBetweenSituation.at(s.par, x0)
	return ["The roots give f(x) = a(%s)(%s), and (%d, %s) gives a = %d, so f(x) = %s." % [Answer.x_minus(s.r), Answer.x_minus(s.t), x0, N(y0), s.a, fp(s.par)],
		"The line through the ends of the region has gradient %d, so g(x) = %s." % [s.line[0], fp(s.line)]]


func u_area_line_curve(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var gap: Array = s.gap
	var v := AreaBetweenSituation.integ(gap, p, q)
	var ans := ex(v)
	var wr: Array = [like(ans, v.neg(), R_NEGATIVE)]
	var side := AreaBetweenSituation.integ(gap, s.r, s.t).abs_q()
	if not side.is_zero() and not side.eq(v):
		wr.append(like(ans, side, R_X_INTERCEPTS))
	var under_par := AreaBetweenSituation.integ(s.par, p, q)
	var under_line := AreaBetweenSituation.integ(s.line, p, q)
	wr.append(like(ans, under_par.add(under_line), R_ADDED))
	var graph: Variant = null
	var lines: Array
	var first: Array = []
	if rep == "diagram":
		graph = _diagram(s)
		lines = _diagram_lines()
		first = _diagram_steps(s)
	else:
		if rep == "graph":
			graph = _line_curve_figure(s, _corners(s))
		lines = two(rep, fp(s.par), fp(s.line), "The curve and the line enclose a region.", "The diagram shows the graphs of f and g, and the region they enclose is shaded.")
	var who: String = "curve" if s.par_top else "line"
	var meet: String = "They meet at x = %d and x = %d, and the %s is on top between them" % [p, q, who]
	var yp := AreaBetweenSituation.at(s.line, p)
	var yq := AreaBetweenSituation.at(s.line, q)
	var trap := "Under the line is a trapezium with parallel sides %s and %s and width %d: its area is %s." % [N(yp), N(yq), q - p, N(under_line)]
	var curve := "Under the curve: %s = %s." % [integral(fp(s.par), p, q), N(under_par)]
	var big: Q = under_par if s.par_top else under_line
	var small: Q = under_line if s.par_top else under_par
	var ti := "Area = %s." % integral(fp(gap), p, q)
	var ff := "The antiderivative is %s, and upper minus lower gives %s." % [anti(gap), N(v)]
	var diff := "Top minus bottom: %s − %s = %s." % [N(big), P(small), N(v)]
	var by_int: Array
	var by_diff: Array
	if rep == "diagram":
		by_int = first + [meet + ". " + ti, ff]
		by_diff = first + [meet + ". " + trap, curve + " " + diff]
	else:
		by_int = [meet + ", so top minus bottom is %s." % fp(gap), ti, ff]
		by_diff = [meet + ".", trap, curve, diff]
	return pack(lines, "Find the area of the region.", ans, wr, vals(ans, [v.mul(2), v.add(1), v.div(2), v.add(2)]),
		{"top-minus-bottom": by_int, "difference-of-areas": by_diff}, graph)


func u_area_two_parabolas(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var gap: Array = s.gap
	var v := AreaBetweenSituation.integ(gap, p, q)
	var ans := ex(v)
	var wr: Array = [like(ans, v.neg(), R_NEGATIVE)]
	var side := AreaBetweenSituation.integ(gap, s.e, s.g).abs_q()
	if not side.is_zero() and not side.eq(v):
		wr.append(like(ans, side, R_X_INTERCEPTS))
	var bot: Array = s.bot
	var slip: Array = [Q.of(s.top[0]).sub(bot[0]), Q.of(s.top[1]).add(bot[1]), Q.of(s.top[2]).add(bot[2])]
	var bad := AreaBetweenSituation.integ(slip, p, q)
	if not bad.eq(v) and not bad.is_zero():
		wr.append(like(ans, bad, R_BRACKET))
	var graph: Variant = null
	var fs: Array = [poly_fn(s.top), poly_fn(s.bot)]
	var yp := AreaBetweenSituation.at(s.top, p)
	var yq := AreaBetweenSituation.at(s.top, q)
	if rep == "graph":
		graph = figure(fs, float(p) - 1.0, float(q) + 1.0, [[fs[0], fs[1], float(p), float(q)]],
			[[p, yp.to_float(), Fmt.point(p, yp)], [q, yq.to_float(), Fmt.point(q, yq)]], ["f", "g"])
	var lines := two(rep, fp(s.top), fp(s.bot), "The two curves enclose a region.", "The diagram shows the graphs of f and g, and the region they enclose is shaded.")
	return pack(lines, "Find the area of the region.", ans, wr, vals(ans, [v.mul(2), v.add(1), v.div(2), v.add(2)]),
		{"top-minus-bottom": [
			"Set them equal: %s = 0, so they meet at x = %d and x = %d." % [fp(gap), p, q],
			"Bracket the lower curve, as every term of it is taken away: (%s) − (%s) = %s." % [fp(s.top), fp(s.bot), fp(gap)],
			"Area = %s." % integral(fp(gap), p, q),
			"The antiderivative is %s, and upper minus lower gives %s." % [anti(gap), N(v)]]}, graph)


# ── Curves that swap over ────────────────────────────────────

static func _cubic_factors(s: Dictionary) -> String:
	return Fmt.lead(s.k) + _bracket(s.a) + _bracket(s.b) + _bracket(s.c)


static func _swap_figure(s: Dictionary, a: float, c: float, cuts: Array, ints: Array) -> Dictionary:
	var f := poly_fn(s.f)
	var g := poly_fn(s.g)
	var regions: Array = []
	for i in cuts.size() - 1:
		regions.append([f, g, cuts[i], cuts[i + 1]])
	var points: Array = []
	for x in ints:
		var y := AreaBetweenSituation.at(s.g, x)
		points.append([x, y.to_float(), Fmt.point(x, y)])
	return figure([f, g], a - 1.0, c + 1.0, regions, points, ["f", "g"])


func _split_area(rep: String, s: Dictionary, lo: int, cut: int, hi: int, lines: Array, graph: Variant) -> Dictionary:
	var p1: Q = s.p1
	var p2: Q = s.p2
	var area := p1.abs_q().add(p2.abs_q())
	var net := p1.add(p2).abs_q()
	var ans := ex(area)
	var wr: Array = [like(ans, net, R_NO_SPLIT), like(ans, p1.abs_q(), R_ONE_PIECE), like(ans, area.neg(), R_NEGATIVE)]
	var gap: Array = s.gap
	var diff: String = "The curve minus the line" if rep == "equation" else "f − g"
	return pack(lines, "Find the total area of the two regions.", ans, wr, vals(ans, [area.mul(2), area.add(1), area.add(2), p2.abs_q()]),
		{"split-at-crossings": [
			"The curve and the line swap over at x = %d, so each side gets its own integral." % cut,
			"%s is %s, with antiderivative %s." % [diff, fp(gap), anti(gap)],
			"∫ from %d to %d gives %s, and ∫ from %d to %d gives %s." % [lo, cut, N(p1), cut, hi, N(p2)],
			"Add their sizes: %s + %s = %s." % [N(p1.abs_q()), N(p2.abs_q()), N(area)]]}, graph)


func u_area_split_cubic(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var graph: Variant = null
	if rep == "graph":
		graph = _swap_figure(s, float(s.a), float(s.c), [float(s.a), float(s.b), float(s.c)], [s.a, s.b, s.c])
	var f_ := fp(s.f)
	var g_ := fp(s.g)
	var lines := two(rep, f_, g_, "The curve and the line meet at x = %d, x = %d and x = %d, and enclose two regions." % [s.a, s.b, s.c],
		"The diagram shows the graphs of f and g, and the two regions between them are shaded.")
	return _split_area(rep, s, s.a, s.b, s.c, lines, graph)


func u_area_split_bounded(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var graph: Variant = null
	if rep == "graph":
		graph = _swap_figure(s, float(s.lo), float(s.hi), [float(s.lo), float(s.u), float(s.hi)], [s.u])
	var lines := two(rep, fp(s.f), fp(s.g), "Two regions lie between the two curves and the lines x = %d and x = %d." % [s.lo, s.hi],
		"The diagram shows the graphs of f and g. The shaded regions lie between them and the lines x = %d and x = %d." % [s.lo, s.hi])
	return _split_area(rep, s, s.lo, s.u, s.hi, lines, graph)


# ── Paper 1: trig and e ──────────────────────────────────────

static func _trig_ticks(angles: Array) -> Array:
	var out: Array = []
	for a in angles:
		if a[0] != 0:
			out.append([angle_val(a), angle_text(a)])
	return out


func u_area_trig(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pr: Dictionary = s.pair
	var A: int = s.A
	var top := trig_text(pr.top, A)
	var bot := trig_text(pr.bot, A)
	var lo: String = angle_text(pr.lo)
	var hi: String = angle_text(pr.hi)
	var fhi := sv(pr.Fhi, A)
	var flo := sv(pr.Flo, A)
	var v := [fhi[0].sub(flo[0]), fhi[1].sub(flo[1]), fhi[2] if not fhi[1].is_zero() else flo[2]]
	var ans := sv_ans(v)
	var wr: Array = [sv_like(ans, [v[0].neg(), v[1].neg(), v[2]], R_NEGATIVE)]
	var w := sv(pr.wrong, A)
	if not (w[0].eq(v[0]) and w[1].eq(v[1])):
		wr.append(alt(AREA + sv_text(w), R_X_INTERCEPTS))
	var gen: Array = [sv_like(ans, [v[0].mul(2), v[1].mul(2), v[2]]).values, sv_like(ans, [v[0].add(1), v[1], v[2]]).values,
		sv_like(ans, [v[0].div(2), v[1].div(2), v[2]]).values, sv_like(ans, [v[0].add(2), v[1], v[2]]).values]
	var graph: Variant = null
	var fa := trig_fn(pr.top, A)
	var fb := trig_fn(pr.bot, A)
	if rep == "graph":
		var a := angle_val(pr.lo)
		var b := angle_val(pr.hi)
		graph = figure([fa, fb], 0.0, maxf(b + 0.6, PI + 0.2), [[fa, fb, a, b]], [[a, fa.call(a), "A"], [b, fa.call(b), "B"]], ["f", "g"])
		graph.x_ticks = _trig_ticks([pr.lo, pr.hi])
	var word := "They meet at A, where x = %s, and at B, where x = %s." % [lo, hi]
	var lines := two(rep, top, bot, word + " The region between A and B is enclosed by the two curves.", word + " The shaded region is enclosed by the two graphs between A and B.")
	var head := "(%s) − (%s)" % [top, bot]
	var FA: String = T(A, "(%s)" % pr.F) if A != 1 else pr.F
	return pack(lines, "Find the exact area of the region.", ans, wr, gen,
		{"top-minus-bottom": [
			"%s is on top between A and B, so integrate %s." % [top, head],
			"The antiderivative is %s." % FA,
			"At x = %s it is %s, and at x = %s it is %s." % [hi, sv_text(fhi), lo, sv_text(flo)],
			"Upper minus lower: %s." % sv_text(v)]}, graph)


func u_area_trig_split(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pr: Dictionary = s.pair
	var A: int = s.A
	var one := trig_text(pr.one, A)
	var two_ := trig_text(pr.two, A)
	var lo: String = angle_text(pr.lo)
	var hi: String = angle_text(pr.hi)
	var cut: String = angle_text(pr.cross)
	var v := sv(pr.total, A)
	var p1 := sv(pr.p1, A)
	var p2 := sv(pr.p2, A)
	var net := sv(pr.net, A)
	var ans := sv_ans(v)
	var wr: Array = [alt(AREA + sv_text(net), R_NO_SPLIT), sv_like(ans, [v[0].neg(), v[1].neg(), v[2]], R_NEGATIVE)]
	wr.append(sv_like(ans, p1, R_ONE_PIECE) if not (p1[0].eq(p2[0]) and p1[1].eq(p2[1])) else sv_like(ans, [p1[0], p1[1], p1[2]], R_ONE_PIECE))
	var gen: Array = [sv_like(ans, [v[0].mul(2), v[1].mul(2), v[2]]).values, sv_like(ans, [v[0].add(1), v[1], v[2]]).values, sv_like(ans, [v[0].add(2), v[1], v[2]]).values]
	var graph: Variant = null
	var fa := trig_fn(pr.one, A)
	var fb := trig_fn(pr.two, A)
	if rep == "graph":
		var a := angle_val(pr.lo)
		var c := angle_val(pr.cross)
		var b := angle_val(pr.hi)
		graph = figure([fa, fb], 0.0, b + 0.5, [[fa, fb, a, c], [fa, fb, c, b]], [[c, fa.call(c), "P"]], ["f", "g"])
		graph.x_ticks = _trig_ticks([pr.cross, pr.hi])
	var word := "They cross once between x = %s and x = %s, at x = %s." % [lo, hi, cut]
	var lines := two(rep, one, two_, word + " Two regions lie between the curves on that interval.", word + " The shaded regions lie between the two graphs.")
	return pack(lines, "Find the exact total area of the regions.", ans, wr, gen,
		{"split-at-crossings": [
			"The curves swap at x = %s, so the area needs two integrals." % cut,
			"From %s to %s, %s is on top: top minus bottom gives %s." % [lo, cut, one, sv_text(p1)],
			"From %s to %s, %s is on top: top minus bottom gives %s." % [cut, hi, two_, sv_text(p2)],
			"Add them: %s." % sv_text(v)]}, graph)


func u_area_exp_lines(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A: int = s.A
	var B: int = s.B
	var k: int = s.k
	var m: int = s.m
	var n: int = s.n
	var en := DifferentiationViews.EN(k * n)
	var em: String = "1" if m == 0 else DifferentiationViews.EN(k * m)
	var br := "(%s − %s)" % [en, em]
	var c := Q.new(A + B, k)
	var mk := func(cv: Variant) -> Dictionary:
		return DifferentiationViews.form(AREA + T(cv, br), [AREA, {"slot": "c"}, br], {"c": Q.of(cv)})
	var ans: Dictionary = mk.call(c)
	var wr: Array = [wrong(mk.call(c.neg()).values, R_NEGATIVE)]
	if A != B:
		wr.append(wrong(mk.call(Q.new(A - B, k)).values, R_ADD_CURVES))
	else:
		wr.append(alt(AREA + "0", R_ADD_CURVES))
	if k > 1:
		wr.append(wrong(mk.call(Q.new((A + B) * k)).values, R_MULT_K))
	if m == 0:
		wr.append(alt(AREA + T(c, en), R_LOWER_ZERO))
	var gen: Array = [mk.call(c.mul(2)).values, mk.call(c.add(1)).values, mk.call(Q.new(A)).values, mk.call(c.add(2)).values]
	var e := DifferentiationViews.E(k)
	var top := T(A, e)
	var bot := T(-B, e)
	var graph: Variant = null
	var fa := func(x: float) -> float: return A * exp(k * x)
	var fb := func(x: float) -> float: return -B * exp(k * x)
	if rep == "graph":
		graph = figure([fa, fb], float(m) - 1.0, float(n) + 1.0, [[fa, fb, float(m), float(n)]], [], ["f", "g"])
	var lines := two(rep, top, bot, "A region is enclosed by the two curves and the lines x = %d and x = %d." % [m, n],
		"The shaded region is enclosed by the graphs of f and g and the lines x = %d and x = %d." % [m, n])
	return pack(lines, "Find the exact area of the region.", ans, wr, gen,
		{"top-minus-bottom": [
			"Every height of the upper curve is positive and every height of the lower is negative, so the upper is on top.",
			"Top minus bottom is (%s) − (%s) = %s." % [top, bot, T(A + B, e)],
			"The antiderivative is %s." % T(c, e),
			"Upper minus lower: %s." % T(c, br)]}, graph)


# ── A shift or a letter from the area ────────────────────────

func _shift_text(s: Dictionary) -> String:
	match s.fam:
		"poly":
			return fp([1, s.x, s.y])
		"exp":
			return SUM([[s.z, "e^x"], [s.y, ""]])
	return "%dx/(x² + %d)²" % [s.z, absi(s.y)]


func u_find_shift(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: Q = s.k
	var w: int = s.hi - s.lo
	var area: Q = s.area
	var mk := func(c: Variant) -> Dictionary:
		var t: String = N(c)
		return DifferentiationViews.form("g(x) = f(x) + %s or g(x) = f(x) − %s" % [t, t], ["g(x) = f(x) ± ", {"slot": "k"}], {"k": Q.of(c)})
	var ans: Dictionary = mk.call(k)
	var wr: Array = [alt("g(x) = f(x) + %s" % N(k), R_ONE_SIDE), wrong(mk.call(area).values, R_NO_WIDTH)]
	var gen: Array = [mk.call(k.mul(2)).values, mk.call(k.add(1)).values, mk.call(k.div(2)).values, mk.call(k.add(2)).values]
	var lines: Array = ["f(x) = " + _shift_text(s), "A function g has g′(x) = f′(x) for all x. The region enclosed by the graphs of f and g and the lines x = %d and x = %d has area %s." % [s.lo, s.hi, N(area)]]
	var same := "g′ = f′, so g(x) = f(x) + c for a constant c: the two graphs are the same shape, c apart."
	return pack(lines, "Find the two possible expressions for g(x), in terms of f(x).", ans, wr, gen,
		{"top-minus-bottom": [
			same,
			"Top minus bottom is |c| at every x, so the area is ∫ from %d to %d of |c| dx = %d|c|." % [s.lo, s.hi, w],
			"%d|c| = %s gives |c| = %s, and g can be above f or below it." % [w, N(area), N(k)]],
		"difference-of-areas": [
			same,
			"The area under the upper graph minus the area under the lower one is a band of height |c| and width %d." % w,
			"Its area is %d|c| = %s, so |c| = %s, and g can be above f or below it." % [w, N(area), N(k)]]})


func u_find_parameter(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var a: int = s.a
	var area: Q = s.area
	var ans := DefiniteIntegralViews.val(k, false, "k = ")
	var cube := Q.new(k * k * k)
	var wr: Array = [like(ans, cube, R_CUBE)]
	var gen: Array = vals(ans, [k + 1, k + 2, 2 * k, area.mul(3), k + 3])
	var slope: bool = s.fam == "slope"
	var par := T(a, "x²")
	var line: String = "kx" if slope else (T(a, "k²"))
	var word := "where k > 0, enclose a region of area %s." % N(area)
	var graph: Variant = null
	if rep == "graph":
		var f := func(x: float) -> float: return a * x * x
		var hi: float = float(k) / a if slope else float(k)
		var lo: float = 0.0 if slope else -float(k)
		var top: float = float(k) * k / a if slope else float(a * k * k)
		var g := func(x: float) -> float: return float(k) * x / 1.0 if slope else top
		graph = figure([f, g], lo - 0.5 * (hi - lo) * 0.5, hi + 0.5 * (hi - lo) * 0.5, [[f, g, lo, hi]], [], ["f", "g"])
		graph.y_bare = true
		graph.x_ticks = [[hi, "k/%d" % a if slope and a > 1 else "k"]] if slope else [[-float(k), "−k"], [hi, "k"]]
	var lines: Array = (["y = " + par, "y = " + line, "These two graphs, " + word] if rep == "equation"
		else ["f(x) = " + par, "g(x) = " + line, "The two graphs, " + word + " The region is shaded."])
	var over: Q = Q.new(1, 6 * a * a) if slope else Q.new(4 * a, 3)
	var cubed := "k³ = %s ÷ %s = %d, and its cube root is %d." % [N(area), P(over), k * k * k, k]
	var steps: Array
	if slope:
		var lim: String = "k" if a == 1 else "k/%d" % a
		steps = ["They meet where %s = kx, at x = 0 and x = %s, and the line is on top." % [par, lim],
			"Area = ∫ from 0 to %s of (kx − %s) dx = %s." % [lim, par, T(over, "k³")],
			cubed]
	else:
		steps = ["They meet where %s = %s, at x = −k and x = k, and the line is on top." % [par, line],
			"Area = ∫ from −k to k of (%s − %s) dx = %s." % [line, par, T(over, "k³")],
			cubed]
	return pack(lines, "Find the value of k.", ans, wr, gen, {"top-minus-bottom": steps}, graph)


func u_derivative_areas(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var name_: String = s.name
	var a1: Q = s.a1
	var a2: Q = s.a2
	var mid: int = s.mid
	var up: bool = s.sign > 0
	var total := a1.add(a2)
	var fp_ := poly_fn(s.co)
	var zero := func(_x: float) -> float: return 0.0
	var g := figure([fp_], float(s.a) - 0.6, float(s.c) + 0.6, [[fp_, zero, float(s.a), float(s.b)], [fp_, zero, float(s.b), float(s.c)]],
		[[s.a, 0, "p"], [s.b, 0, "q"], [s.c, 0, "r"]], [name_ + "′"])
	g.y_bare = true
	g.x_ticks = [[float(s.a), ""], [float(s.b), ""], [float(s.c), ""]]
	var f_p: Q = Q.new(mid).sub(a1) if up else Q.new(mid).add(a1)
	var f_r: Q = Q.new(mid).sub(a2) if up else Q.new(mid).add(a2)
	var here := "above" if up else "below"
	var there := "below" if up else "above"
	var head := "The diagram shows the graph of %s′, the derivative of %s. It crosses the x-axis at x = p, x = q and x = r, and it is %s the axis from p to q." % [name_, name_, here]
	if s.fam == "sum":
		var sum_ := f_p.add(f_r)
		var ans := DefiniteIntegralViews.val(mid, false, "%s(q) = " % name_)
		var wr: Array = [like(ans, sum_.add(total), R_NO_HALF) if up else like(ans, sum_.sub(total), R_NO_HALF),
			like(ans, (sum_.sub(total) if up else sum_.add(total)).div(2), R_RISE_FALL)]
		var chg := "%s(q) − %s(p) = %s%s and %s(r) − %s(q) = %s%s" % [name_, name_, "" if up else "−", "A₁", name_, name_, "−" if up else "", "A₂"]
		var add: String = "2%s(q) − %s = %s, as A₁ + A₂ = %s" % [name_, P(sum_), ("" if up else "−") + N(total), N(total)]
		return pack([head, "The two regions between the graph and the x-axis have total area %s, and %s(p) + %s(r) = %s." % [N(total), name_, name_, N(sum_)]],
			"Find the value of %s(q)." % name_, ans, wr, vals(ans, [total, sum_.div(2), Q.new(mid + 1), Q.new(mid + 2), sum_]),
			{"split-at-crossings": [
				"The graph of %s′ crosses the axis at x = q, so split there. Call the two areas A₁ and A₂." % name_,
				"The integral of %s′ is the change in %s: %s." % [name_, name_, chg],
				"Take the second from the first: %s." % add]}, g)
	var ans2 := DefiniteIntegralViews.val(f_r, false, "%s(r) = " % name_)
	var d1 := a1 if up else a1.neg()
	var d2 := a2.neg() if up else a2
	var wr2: Array = [like(ans2, f_p.add(d1).add(d2.neg()), R_RISE_FALL)]
	return pack([head, "The region from p to q has area %s, the region from q to r has area %s, and %s(p) = %s." % [N(a1), N(a2), name_, N(f_p)]],
		"Find the value of %s(r)." % name_, ans2, wr2, vals(ans2, [f_p.add(a1).add(a2), a1.add(a2), f_p.add(d1), f_r.add(1), f_r.add(2)]),
		{"split-at-crossings": [
			"The graph of %s′ crosses the axis at x = q, so split there." % name_,
			"From p to q it is %s the axis, so %s changes by %s." % [here, name_, N(d1)],
			"From q to r it is %s the axis, so %s changes by %s." % [there, name_, N(d2)],
			"%s + %s + %s = %s." % [N(f_p), P(d1), P(d2), N(f_r)]]}, g)


# ── Paper 2: curves that need a GDC ──────────────────────────

static func _gdc_figure(s: Dictionary, points: Array) -> Dictionary:
	var f := AreaBetweenSituation.fn(s.cf)
	var g := AreaBetweenSituation.fn(s.cg)
	return figure([f, g], float(s.lo), float(s.hi), [[f, g, s.z[0], s.z[1]]], points, ["f", "g"])


static func _gdc_swap_figure(s: Dictionary) -> Dictionary:
	var f := AreaBetweenSituation.fn(s.cf)
	var g := AreaBetweenSituation.fn(s.cg)
	return figure([f, g], float(s.lo), float(s.hi), [[f, g, s.z[0], s.z[1]], [f, g, s.z[1], s.z[2]]], [], ["f", "g"])


func u_gdc_area(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z: Array = s.z
	var area: float = s.area
	var f := AreaBetweenSituation.text(s.cf)
	var g := AreaBetweenSituation.text(s.cg)
	var top: String = f if s.f_top else g
	var bot: String = g if s.f_top else f
	var dom := "for %s ≤ x ≤ %s" % [W(s.lo), W(s.hi)]
	var ans := sf(area)
	var wr: Array = [like(ans, -area, R_NEGATIVE), like(ans, s.int_f + s.int_g, R_ADDED)]
	if s.xint > 0.0 and absf(s.xint - area) > 0.01 * area:
		wr.append(like(ans, s.xint, R_X_INTERCEPTS))
	var graph: Variant = null
	if rep == "graph":
		graph = _gdc_figure(s, [[z[0], s.yz[0], "A"], [z[1], s.yz[1], "B"]])
	var meet := "The intersect tool gives x = %s and x = %s." % [GdcKit.W(z[0]), GdcKit.W(z[1])]
	var big: float = s.int_f if s.f_top else s.int_g
	var low: float = s.int_g if s.f_top else s.int_f
	return pack(two(rep, f, g, "The curves meet twice, %s, and enclose a region." % dom, "The diagram shows the graphs of f and g, %s, and the region they enclose is shaded." % dom),
		"Find the area of the region, to 3 s.f.", ans, wr, vals(ans, [area * 2.0, area + 1.0, area * 0.5, area + 2.0]),
		{"gdc-abs-difference": [
			meet,
			"Enter ∫ from %s to %s of |(%s) − (%s)| dx in the GDC: %s." % [GdcKit.W(z[0]), GdcKit.W(z[1]), f, g, GdcKit.W(area)]],
		"top-minus-bottom": [
			meet,
			"Between them y = %s is on top." % top,
			"The GDC's integral of (%s) − (%s) between them is %s." % [top, bot, GdcKit.W(area)]],
		"difference-of-areas": [
			meet,
			"The GDC gives %s = %s for the top curve." % [integral(top, GdcKit.W(z[0]), GdcKit.W(z[1])), GdcKit.W(big)],
			"It gives %s for the bottom curve, y = %s." % [GdcKit.W(low), bot],
			"Subtract: %s − %s = %s." % [GdcKit.W(big), "(%s)" % GdcKit.W(low) if low < 0.0 else GdcKit.W(low), GdcKit.W(area)]]}, graph)


func u_gdc_area_split(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z: Array = s.z
	var area: float = s.area
	var f := AreaBetweenSituation.text(s.cf)
	var g := AreaBetweenSituation.text(s.cg)
	var dom := "for %s ≤ x ≤ %s" % [W(s.lo), W(s.hi)]
	var ans := sf(area)
	var a1 := absf(s.p1)
	var a2 := absf(s.p2)
	var wr: Array = [like(ans, s.net, R_NO_SPLIT), like(ans, a1, R_ONE_PIECE)]
	var graph: Variant = null
	if rep == "graph":
		graph = _gdc_swap_figure(s)
	var meet := "The intersect tool gives x = %s, x = %s and x = %s." % [GdcKit.W(z[0]), GdcKit.W(z[1]), GdcKit.W(z[2])]
	return pack(two(rep, f, g, "The curves cross three times, %s, and enclose two regions." % dom, "The diagram shows the graphs of f and g, %s, and the two regions they enclose are shaded." % dom),
		"Find the total area of the two regions, to 3 s.f.", ans, wr, vals(ans, [a2, area * 2.0, area + 1.0, area * 0.5]),
		{"gdc-abs-difference": [
			meet,
			"The modulus keeps both pieces positive: ∫ from %s to %s of |(%s) − (%s)| dx." % [GdcKit.W(z[0]), GdcKit.W(z[2]), f, g],
			"The GDC gives %s." % GdcKit.W(area)],
		"split-at-crossings": [
			meet,
			"From the first to the second, top minus bottom gives %s." % GdcKit.W(a1),
			"From the second to the third, top minus bottom gives %s." % GdcKit.W(a2),
			"Add them: %s." % GdcKit.W(area)]}, graph)


func u_inverse_area(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z: Array = s.z
	var area: float = s.area
	var f := AreaBetweenSituation.text(s.cf)
	var inv := AreaBetweenSituation.text(s.cg)
	var dom: String = "x ≥ %s" % N(Q.new(-s.cf.b, s.cf.a)) if s.fam == "root" else "x ≠ %s" % N(-s.cf.c)
	var ans := sf(area)
	var wr: Array = [like(ans, s.half, R_NO_DOUBLE), like(ans, -area, R_NEGATIVE)]
	var graph: Variant = null
	var ff := AreaBetweenSituation.fn(s.cf)
	var gg := AreaBetweenSituation.fn(s.cg)
	if rep == "graph":
		var lo: float = maxf(z[0] - 0.4, float(-s.cf.b) / s.cf.a if s.fam == "root" else float(-s.cf.c) + 0.2)
		var hi: float = z[1] + 0.4 if s.fam == "root" else minf(z[1] + 0.4, float(s.cf.a) - 0.2)
		graph = figure([ff, gg], lo, hi, [[ff, gg, z[0], z[1]]], [[z[0], z[0], "A"], [z[1], z[1], "B"]], ["f", "f⁻¹"])
	var top: String = f if s.f_top else inv
	var bot: String = inv if s.f_top else f
	var meet := "f and f⁻¹ meet on y = x. The GDC's intersect tool gives x = %s and x = %s." % [GdcKit.W(z[0]), GdcKit.W(z[1])]
	var lines: Array = ["f(x) = %s, for %s" % [f, dom],
		"The graphs of f and its inverse f⁻¹ meet at A and B%s." % (", and the region they enclose is shaded" if rep == "graph" else " and enclose a region")]
	return pack(lines, "Find the area of the region, to 3 s.f.", ans, wr, vals(ans, [area * 2.0, area + 1.0, area + 2.0, area * 0.25]),
		{"gdc-abs-difference": [
			"Swap x and y and rearrange: f⁻¹(x) = %s." % inv,
			meet,
			"Enter ∫ from %s to %s of |(%s) − (%s)| dx: %s." % [GdcKit.W(z[0]), GdcKit.W(z[1]), f, inv, GdcKit.W(area)]],
		"top-minus-bottom": [
			"Swap x and y and rearrange: f⁻¹(x) = %s." % inv,
			meet,
			"Between them y = %s is on top, and top minus bottom has integral %s on the GDC." % [top, GdcKit.W(area)],
			"The mirror line y = x cuts the region in half: 2 × %s agrees." % GdcKit.W(s.half)]}, graph)


func u_region_two_lines(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var area: float = s.area
	var f := AreaBetweenSituation.text(s.cf)
	var lm := AreaBetweenSituation.text(s.cm)
	var ll := AreaBetweenSituation.text(s.cl)
	var ans := sf(area)
	var wr: Array = [like(ans, s.whole, R_ONE_TOP), like(ans, s.p2, R_ONE_PIECE)]
	var ff := AreaBetweenSituation.fn(s.cf)
	var fm := AreaBetweenSituation.fn(s.cm)
	var fl := AreaBetweenSituation.fn(s.cl)
	var xr: float = s.xr
	var xp: float = s.xp
	var xq: float = s.xq
	var g := figure([ff, fm, fl], 0.0, xq + 1.0, [[fm, fl, xr, xp], [ff, fl, xp, xq]],
		[[xr, fm.call(xr), "R"], [xp, fm.call(xp), "P"], [xq, fl.call(xq), "Q"]], ["f", "M", "L"])
	var corners := "The intersect tool gives R at x = %s, P at x = %s and Q at x = %s." % [GdcKit.W(xr), GdcKit.W(xp), GdcKit.W(xq)]
	var lines: Array = ["f(x) = " + f, "M: y = " + lm, "L: y = " + ll,
		"The diagram shows the graph of f and the lines L and M. The shaded region, with corners P, Q and R, is enclosed by all three."]
	return pack(lines, "Find the area of the shaded region, to 3 s.f.", ans, wr, vals(ans, [area * 2.0, s.p1, area + 1.0, area + 2.0]),
		{"split-at-crossings": [
			corners,
			"The top edge changes at P, so split there: M is on top before P and f after it, and L is below both.",
			"M minus L from R to P gives %s, and f minus L from P to Q gives %s." % [GdcKit.W(s.p1), GdcKit.W(s.p2)],
			"Add them: %s." % GdcKit.W(area)],
		"gdc-abs-difference": [
			corners,
			"Enter ∫ of |M − L| from R to P: %s." % GdcKit.W(s.p1),
			"Enter ∫ of |f − L| from P to Q: %s." % GdcKit.W(s.p2),
			"The modulus doesn't remove the split, as the top edge is a different curve on each side of P. Add them: %s." % GdcKit.W(area)]}, g)


## A whole number or a decimal end of a domain.
static func W(v: Variant) -> String:
	return Fmt.dec(Q.of(int(v))) if float(v) == floorf(float(v)) else GdcKit.W(v)
