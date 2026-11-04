class_name DefiniteIntegralViews
extends ExtensionViews
## The views on the `definite-integral` situation: one builder per unknown of
## t5-definite-integral-area (FAL-724). A value is a `form` answer, so a wrong option can
## read differently (with + C, or in rate units): exact on Paper 1, and 3 s.f. on Paper 2,
## which only the GDC methods ask. A region is shaded on its figure (GraphView's `shade`),
## with its corners marked.
##
## Representations: "equation", "graph" (the curve, with the region) and "words" (a story).

const SE := "SL5.11.evaluate-definite#"
const SN := "SL5.11.area-with-negative-regions#"
const SK := "SL5.11.unknown-limit-or-parameter#"
const SR := "SL5.11.composite-region-area#"
const SS := "SL5.5.total-change-from-rate#"
const R_FLIPPED := SE + "0"
const R_LOWER_ZERO := SE + "1"
const R_PLUS_C := SE + "2"
const R_CANCEL := SN + "0"
const R_NEGATIVE := SN + "1"
const R_AT_TURN := SN + "2"
const R_OTHER_ROOT := SK + "0"
const R_NO_LOWER := SK + "1"
const R_CURVE_END := SR + "0"
const R_ADDED := SR + "1"
const R_SAME_LOWER := SR + "2"
const R_AT_END := SS + "0"
const R_NO_START := SS + "1"
const R_RATE_UNITS := SS + "2"
static var HYPHEN := RegEx.create_from_string("(?<![A-Za-z])-(?=[0-9])")
const UNKNOWNS := ["evaluate-polynomial", "evaluate-roots", "evaluate-trig", "evaluate-log", "evaluate-exp", "evaluate-odd-even",
	"evaluate-linear", "area-above-axis", "area-below-axis", "area-across-root", "area-gdc", "area-symmetry",
	"unknown-upper-limit", "unknown-limit-log", "unknown-limit-trig", "unknown-stretch", "region-tangent", "region-line-curve",
	"total-from-rate", "amount-with-start", "total-from-rate-graph", "time-to-reach", "interpret-integral"]

## The stories: a rate per unit of time, and what it adds up to.
const CONTEXTS := [
	{"say": "Water flows into a tank", "what": "water", "where": "in the tank", "y": "litres", "per": "minute", "time": "minutes"},
	{"say": "Fuel is pumped into a convoy's tanker", "what": "fuel", "where": "in the tanker", "y": "litres", "per": "minute", "time": "minutes"},
	{"say": "A solar array charges a battery bank", "what": "charge", "where": "in the bank", "y": "kilowatt-hours", "per": "hour", "time": "hours"},
	{"say": "Grain is poured into a silo", "what": "grain", "where": "in the silo", "y": "kilograms", "per": "minute", "time": "minutes"},
]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## The GDC methods are Paper 2, and every other cell is Paper 1, as most of the bank is.
func papers(unknown: String, _rep: String, angle: String) -> Array:
	if not has(unknown):
		return []
	return [2] if angle.begins_with("gdc-") else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = DefiniteIntegralSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func SUM(terms: Array) -> String:
	return DifferentiationViews.SUM(terms)


static func T(c: Variant, body: String) -> String:
	return DifferentiationViews.T(c, body)


## A value as a typed answer: exact, or to 3 s.f. on Paper 2.
static func val(v: Variant, sf: bool, head: String = "", tail: String = "") -> Dictionary:
	var q: Q = GdcKit.qf(v) if v is float else Q.of(v)
	var shown: String = Fmt.sf(q) if sf else Fmt.num(q)
	var ans := DifferentiationViews.form(head + shown + tail, [head, {"slot": "v"}, tail], {"v": q})
	ans.exact = not sf
	return ans


## A wrong value in the answer's own shape.
static func like(ans: Dictionary, v: Variant, ref: String = "") -> Dictionary:
	var sf: bool = not ans.exact
	var parts: Array = ans.template
	return wrong(val(v, sf, parts[0], parts[2]).values, ref)


static func other(text: String, ref: String = "") -> Dictionary:
	return DifferentiationViews.alt(text, ref)


static func vals(ans: Dictionary, list: Array) -> Array:
	return list.map(func(v): return like(ans, v).values)


## "∫ from 1 to 4 of (x² + 1) dx".
static func integral_text(f: String, lo: Variant, hi: Variant) -> String:
	return "∫ from %s to %s of %s dx" % [lo if lo is String else N(lo), hi if hi is String else N(hi), IntegrationViews.wrapped(f)]


## An antiderivative of a polynomial, term by term.
static func anti(coeffs: Array, letter: String = "x") -> String:
	var terms: Array = []
	var n := coeffs.size()
	for i in n:
		var p: int = n - i
		terms.append([Q.of(coeffs[i]).div(p), letter + (Fmt.sup(p) if p > 1 else "")])
	return SUM(terms)


## A curve on a window that holds it, with these regions shaded, each [a, b] or a list of
## strips, and these points.
static func figure(f: Callable, lo: float, hi: float, regions: Array, points: Array, extra: Array = []) -> Dictionary:
	var c := GdcKit.curve(f, lo, hi)
	var ylo := 0.0
	var yhi := 0.0
	for p in c:
		ylo = minf(ylo, p[1])
		yhi = maxf(yhi, p[1])
	var g := Plot.spec([c] + extra, points, floori(lo), ceili(hi), floori(ylo - 0.1 * (yhi - ylo)) - 1, ceili(yhi + 0.1 * (yhi - ylo)) + 1)
	g.shade = regions.map(func(r): return under(f, r[0], r[1]))
	return g


## Strips between the x-axis and f on [a, b].
static func under(f: Callable, a: float, b: float) -> Array:
	var out: Array = []
	for i in 81:
		var x := a + (b - a) * i / 80.0
		var y: float = f.call(x)
		out.append([x, minf(y, 0.0), maxf(y, 0.0)])
	return out


static func poly_fn(coeffs: Array) -> Callable:
	return func(x: float) -> float:
		var y := 0.0
		for c in coeffs:
			y = y * x + float(c)
		return y


## The last step.
static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## A minus sign in place of the hyphen %d writes before a number.
static func minus(t: String) -> String:
	return HYPHEN.sub(t, "−", true)


static func pack(lines: Array, asked: String, ans: Dictionary, wr: Array, gen: Array, methods: Dictionary, graph: Variant = null) -> Dictionary:
	var ms := {}
	for id in methods:
		ms[id] = method(methods[id].map(minus) + [say(ans)], ans.values)
	var more: Array = []
	if ans.values.has("v"):
		var v: Q = ans.values.v
		more = vals(ans, [v.add(1), v.sub(1), v.add(2), v.mul(3)])
	return {"lines": lines.map(minus), "asked": minus(asked), "answer": ans, "wrongs": wr, "generic": gen + more, "methods": ms, "graph": graph}


# ── Evaluate a definite integral ─────────────────────────────

func u_evaluate_polynomial(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var co: Array = s.coeffs
	var f := Fmt.poly(co)
	var v := DefiniteIntegralSituation.integral(co, s.lo, s.hi)
	var hi_only := DefiniteIntegralSituation.integral(co, 0, s.hi)
	var p2: bool = s.paper == 2
	var ans := val(v, p2)
	var gen := vals(ans, [hi_only, v.add(DefiniteIntegralSituation.at(co, s.lo)), DefiniteIntegralSituation.at(co, s.hi).sub(DefiniteIntegralSituation.at(co, s.lo)), v.mul(2), v.add(1)])
	var asked := "Find the value of the integral%s." % (", to 3 s.f" if p2 else "")
	return pack([integral_text(f, s.lo, s.hi)], asked, ans, [like(ans, v.neg(), R_FLIPPED)], gen,
		{"antiderivative-substitute": [
			"F(x) = %s." % anti(co),
			"F(%s) = %s and F(%s) = %s." % [N(s.hi), N(hi_only), N(s.lo), N(DefiniteIntegralSituation.integral(co, 0, s.lo))],
			"Upper minus lower: %s." % N(v)],
		"gdc-check": [
			"Enter f(x) = %s and the limits %s and %s in the GDC's ∫dx template." % [f, N(s.lo), N(s.hi)],
			"The GDC gives %s." % GdcKit.W(v)]})


func u_evaluate_roots(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var m: int = s.m
	var n: int = s.n
	var lo := m * m
	var hi := n * n
	var f := SUM([[a, "√x"], [b, "/√x"]])
	var c0 := Q.new(2 * a, 3)
	var up := c0.mul(n * n * n).add(2 * b * n)
	var dn := c0.mul(m * m * m).add(2 * b * m)
	var v := up.sub(dn)
	var ans := val(v, false)
	return pack([integral_text(f, lo, hi)], "Find the exact value of the integral.", ans, [like(ans, v.neg(), R_FLIPPED)],
		vals(ans, [up, Q.new(a * (n - m)).add(b * (hi - lo)), c0.mul(hi).add(2 * b * n).sub(dn), v.add(2 * b), v.add(1)]),
		{"antiderivative-substitute": [
			"Write the terms as powers: %s." % SUM([[a, "x^(1/2)"], [b, "x^(−1/2)"]]),
			"F(x) = %s." % SUM([[c0, "x^(3/2)"], [2 * b, "x^(1/2)"]]),
			"F(%d) = %s and F(%d) = %s, using √%d = %d and √%d = %d." % [hi, N(up), lo, N(dn), hi, n, lo, m],
			"Upper minus lower: %s." % N(v)]})


func u_evaluate_trig(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var sn: bool = s.fam == "sin"
	var top: int = s.top                  # the upper limit is π/top
	var c0 := Q.new(a, top)
	var trig := "sin x" if sn else "cos x"
	var c1: int = (b if sn and top == 2 else 2 * b) if sn else b
	var bad: int = 0 if top == 2 else b   # F(0) left out: sin gives −b cos(upper) alone
	var word := "π/2" if top == 2 else "π"
	var mk := func(p: Variant, r: Variant) -> Dictionary:
		var ans := DifferentiationViews.form(SUM([[p, "π"], [r, ""]]), [{"slot": "c0"}, "π + ", {"slot": "c1"}], {"c0": Q.of(p), "c1": Q.of(r)})
		return ans
	var ans: Dictionary = mk.call(c0, c1)
	var wr: Array = []
	if sn:
		wr.append(wrong(mk.call(c0, bad).values, R_LOWER_ZERO))
	var f := SUM([[a, ""], [b, trig]])
	var F := SUM([[a, "x"], [-b if sn else b, "cos x" if sn else "sin x"]])
	return pack([integral_text(f, 0, word)], "Find the exact value of the integral.", ans, wr,
		[mk.call(c0, -c1).values, mk.call(c0.neg(), c1).values, mk.call(Q.of(a), c1).values, mk.call(c0, c1 + 1).values, mk.call(c0.mul(2), c1).values],
		{"antiderivative-substitute": [
			"F(x) = %s." % F,
			"F(%s) = %s." % [word, SUM([[c0, "π"], [(0 if top == 2 else b) if sn else b, ""]])],
			"F(0) = %s, %s." % [N(-b) if sn else "0", "since cos 0 = 1, not 0" if sn else "since sin 0 = 0"],
			"Upper minus lower: %s." % SUM([[c0, "π"], [c1, ""]])]})


func u_evaluate_log(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var c: int = s.c
	var lo: int = s.lo
	var hi: int = s.hi
	var m := Q.new(hi + c, lo + c)
	var head: String = T(k, "ln(")
	var mk := func(v: Q) -> Dictionary:
		return DifferentiationViews.form(head + v.text() + ")", [head, {"slot": "m"}, ")"], {"m": v})
	var ans: Dictionary = mk.call(m)
	return pack([integral_text("%s/(x%s)" % [N(k), Fmt.plus(c)], lo, hi)], "Find the exact value of the integral.", ans,
		[wrong(mk.call(Q.new(lo + c, hi + c)).values, R_FLIPPED), other(head + m.text() + ") + C", R_PLUS_C)],
		[mk.call(Q.new(hi + c)).values, mk.call(Q.new(hi - lo)).values, mk.call(m.add(1)).values, mk.call(Q.new(hi + c + lo + c)).values],
		{"antiderivative-substitute": [
			"F(x) = %s." % T(k, "ln|x%s|" % Fmt.plus(c)),
			"Upper minus lower: %s(ln %d − ln %d)." % [Fmt.lead(k), hi + c, lo + c],
			"Combine the logs: ln a − ln b = ln(a/b).",
			]})


func u_evaluate_exp(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var a: int = s.a
	var n: int = s.n
	var top: int = a * n
	var c0 := Q.new(k, a)
	var br := "(%s − 1)" % DifferentiationViews.EN(top)
	var mk := func(c: Variant) -> Dictionary:
		return DifferentiationViews.form(T(c, br), [{"slot": "c"}, br], {"c": Q.of(c)})
	var ans: Dictionary = mk.call(c0)
	var f := T(k, DifferentiationViews.E(a))
	return pack([integral_text(f, 0, n)], "Find the exact value of the integral.", ans,
		[wrong(mk.call(c0.neg()).values, R_FLIPPED), other(T(c0, DifferentiationViews.EN(top)), R_LOWER_ZERO)],
		[mk.call(k).values, mk.call(k * a).values, mk.call(c0.mul(2)).values, mk.call(c0.add(1)).values],
		{"antiderivative-substitute": [
			"F(x) = %s." % T(c0, DifferentiationViews.E(a)),
			"F(%d) = %s, and F(0) = %s since e⁰ = 1, not 0." % [n, T(c0, DifferentiationViews.EN(top)), c0.text()],
			"Upper minus lower: %s." % T(c0, br)]})


func u_evaluate_odd_even(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var co: Array = [s.p, s.q, s.r, s.t]
	var f := Fmt.poly(co)
	var half := DefiniteIntegralSituation.integral([s.q, 0, s.t], 0, a)
	var v := half.mul(2)
	var ans := val(v, false)
	return pack([integral_text(f, -a, a)], "Find the value of the integral.", ans, [],
		vals(ans, [0, half, v.add(DefiniteIntegralSituation.integral([s.p, 0, s.r, 0], 0, a).mul(2)), v.neg(), v.mul(2), v.add(1)]),
		{"odd-even-symmetry": [
			"The odd terms, %s, cancel from −%d to %d: their areas on the two sides are equal and opposite." % [SUM([[s.p, "x³"], [s.r, "x"]]), a, a],
			"The even terms, %s, give twice the integral from 0 to %d." % [SUM([[s.q, "x²"], [s.t, ""]]), a],
			"2 × %s = %s." % [N(half), N(v)]],
		"antiderivative-substitute": [
			"F(x) = %s." % anti(co),
			"F(%d) = %s and F(−%d) = %s." % [a, N(DefiniteIntegralSituation.integral(co, 0, a)), a, N(DefiniteIntegralSituation.integral(co, 0, -a))],
			"Upper minus lower: %s." % N(v)]})


func u_evaluate_linear(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var co: Array = [s.m, s.c]
	var lo: int = s.lo
	var hi: int = s.hi
	var v := DefiniteIntegralSituation.integral(co, lo, hi)
	var ans := val(v, false)
	var y0: int = s.m * lo + s.c
	var y1: int = s.m * hi + s.c
	return pack([integral_text(Fmt.poly(co), lo, hi)], "Find the value of the integral.", ans,
		[like(ans, v.neg(), R_FLIPPED), other(N(v) + " + C", R_PLUS_C)],
		vals(ans, [DefiniteIntegralSituation.integral(co, 0, hi), Q.new(y1 - y0), Q.new(y1 * (hi - lo)), Q.new(y0 * (hi - lo)), v.add(1)]),
		{"geometric-area": [
			"The line is above the axis here, so the integral is the area of a trapezium.",
			"Its parallel sides are %d and %d, and its width is %d." % [y0, y1, hi - lo],
			"Area = (1/2)(%d + %d) × %d = %s." % [y0, y1, hi - lo, N(v)]],
		"antiderivative-substitute": [
			"F(x) = %s." % anti(co),
			"F(%d) = %s and F(%d) = %s." % [hi, N(DefiniteIntegralSituation.integral(co, 0, hi)), lo, N(DefiniteIntegralSituation.integral(co, 0, lo))],
			"Upper minus lower: %s." % N(v)]})


# ── Areas ────────────────────────────────────────────────────

static func region_lines(rep: String, f: String, text: String) -> Array:
	return ["The diagram shows part of the curve y = %s. %s" % [f, text]] if rep == "graph" else ["The curve y = %s. %s" % [f, text]]


func u_area_above_axis(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _one_side(rep, s)


func u_area_below_axis(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _one_side(rep, s)


func _one_side(rep: String, s: Dictionary) -> Dictionary:
	var a: int = s.a
	var r: int = s.r
	var t: int = s.t
	var co := DefiniteIntegralSituation.quad(a, r, t)
	var f := Fmt.poly(co)
	var v := DefiniteIntegralSituation.integral(co, r, t)
	var area := v.abs_q()
	var ans := val(area, false, "Area = ")
	var g: Variant = null
	if rep == "graph":
		g = figure(poly_fn(co), r - 1.0, t + 1.0, [[float(r), float(t)]], [[r, 0, Fmt.point(r, 0)], [t, 0, Fmt.point(t, 0)]])
	var txt := "The shaded region is enclosed by the curve and the x-axis." if rep == "graph" else "A region is enclosed by the curve and the x-axis."
	var asked := "Find the area of the region."
	var gen: Array = vals(ans, [area.mul(2), DefiniteIntegralSituation.integral(co, 0, t).abs_q().add(1), area.add(1), Q.new(absi(a) * (t - r) * (t - r))])
	var fx := "F(x) = %s." % anti(co)
	var ends := "F(%d) − F(%d) = %s." % [t, r, N(v)]
	if s.ask == "area-above-axis":
		return pack(region_lines(rep, f, txt), asked, ans, [], gen, {"antiderivative-substitute": [
			"The curve meets the x-axis at x = %d and x = %d, and it is above the axis between them." % [r, t],
			fx, ends], }, g)
	return pack(region_lines(rep, f, txt), asked, ans, [like(ans, v, R_NEGATIVE)], gen, {"negate-below": [
		"The curve meets the x-axis at x = %d and x = %d, and it is below the axis between them." % [r, t],
		fx, ends,
		"An area is positive, so take −(%s) = %s." % [N(v), N(area)]]}, g)


func u_area_across_root(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var r: int = s.r
	var t: int = s.t
	var hi: int = s.hi
	var co := DefiniteIntegralSituation.quad(a, r, t)
	var f := Fmt.poly(co)
	var p1 := DefiniteIntegralSituation.integral(co, r, t)
	var p2 := DefiniteIntegralSituation.integral(co, t, hi)
	var area := p1.abs_q().add(p2.abs_q())
	var net := p1.add(p2)
	var h := (r + t) / 2
	var bad := DefiniteIntegralSituation.integral(co, r, h).abs_q().add(DefiniteIntegralSituation.integral(co, h, hi).abs_q())
	var sf: bool = s.paper == 2
	var ans := val(area, sf, "Area = ")
	var g: Variant = null
	if rep == "graph":
		g = figure(poly_fn(co), r - 1.0, hi + 1.0, [[float(r), float(t)], [float(t), float(hi)]],
			[[r, 0, Fmt.point(r, 0)], [t, 0, Fmt.point(t, 0)], [hi, DefiniteIntegralSituation.at(co, hi).to_float(), Fmt.point(hi, DefiniteIntegralSituation.at(co, hi))]])
	var txt := "The shaded regions lie between the curve, the x-axis and the line x = %d." % hi if rep == "graph" else "Two regions lie between the curve, the x-axis and the line x = %d, from x = %d." % [hi, r]
	var asked := "Find the total area of the regions%s." % (", to 3 s.f" if sf else "")
	var wr: Array = [like(ans, net.abs_q(), R_CANCEL), like(ans, bad, R_AT_TURN)]
	return pack(region_lines(rep, f, txt), asked, ans, wr, vals(ans, [area.add(1), area.mul(2), p1.abs_q(), p2.abs_q(), area.sub(1)]),
		{"split-at-roots": [
			"The curve crosses the x-axis at x = %d, so split the integral there." % t,
			"∫ from %d to %d gives %s." % [r, t, N(p1)],
			"∫ from %d to %d gives %s." % [t, hi, N(p2)],
			"Add their sizes: %s + %s = %s." % [N(p1.abs_q()), N(p2.abs_q()), N(area)]],
		"gdc-absolute": [
			"Enter |%s| in the GDC's ∫dx template, from %d to %d." % [f, r, hi],
			"The modulus counts the part below the axis as positive. The GDC gives %s." % GdcKit.W(area)]}, g)


func u_area_gdc(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: String
	if s.fam == "wave":
		f = "%d sin(%sx)e^(−%sx)" % [s.A, Fmt.dec(s.w), Fmt.dec(s.k)]
	else:
		f = "%sx + %d − %se^(%sx)" % [Fmt.lead(s.a), s.b, Fmt.lead(s.c), Fmt.dec(s.p)]
	var fn := DefiniteIntegralSituation.curve(s)
	var lo: int = s.lo
	var hi: int = s.hi
	var z: float = s.z
	var ans := val(s.area, true, "Area = ")
	var g := figure(fn, float(lo), float(hi), [[float(lo), z], [z, float(hi)]], [[z, 0, "(" + Fmt.sf(z) + ", 0)"]])
	var lines: Array = ["The diagram shows the curve y = %s, for %d ≤ x ≤ %d. The shaded regions lie between the curve and the x-axis." % [f, lo, hi]]
	var a1 := DefiniteIntegralSituation.simpson(fn, float(lo), z)
	return pack(lines, "Find the total area of the shaded regions, to 3 s.f.", ans, [like(ans, s.net, R_CANCEL)],
		vals(ans, [absf(a1), s.area - absf(a1), s.area * 2.0, s.area + 1.0, s.area * 0.5]),
		{"gdc-absolute": [
			"Part of the curve is below the x-axis, so integrate |f(x)|, not f(x).",
			"Enter |%s| in the GDC's ∫dx template, from %d to %d." % [f, lo, hi],
			"The GDC gives %s." % GdcKit.W(s.area)]}, g)


func u_area_symmetry(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	if s.fam == "sin":
		var k: int = s.k
		var fn := func(x: float) -> float: return k * sin(x)
		var ans := val(4 * k, false, "Area = ")
		var g := figure(fn, 0.0, 7.0, [[0.0, PI], [PI, TAU]], [[PI, 0, "π"], [TAU, 0, "2π"]])
		return pack(["The diagram shows the curve y = %s, for 0 ≤ x ≤ 2π. The shaded regions lie between the curve and the x-axis." % T(k, "sin x")],
			"Find the total area of the shaded regions.", ans, [like(ans, 0, R_CANCEL)],
			vals(ans, [2 * k, k, 8 * k, 4 * k + 1, 2 * k + 2]),
			{"symmetry-shortcut": [
				"The two humps are congruent, so the area is 2 × ∫ from 0 to π of %s dx." % T(k, "sin x"),
				"∫ from 0 to π of sin x dx = [−cos x] = 1 − (−1) = 2.",
				"2 × %d × 2 = %d." % [k, 4 * k]],
			"split-at-roots": [
				"The curve crosses the axis at x = π, so split there.",
				"∫ from 0 to π gives %d, and ∫ from π to 2π gives −%d." % [2 * k, 2 * k],
				"Add their sizes: %d + %d = %d." % [2 * k, 2 * k, 4 * k]]}, g)
	var k2: int = s.k
	var a: int = s.a
	var co: Array = [k2, 0, -k2 * a * a, 0]
	var fc := poly_fn(co)
	var one := DefiniteIntegralSituation.integral(co, -a, 0)
	var area := one.mul(2)
	var ans2 := val(area, false, "Area = ")
	var g2 := figure(fc, float(-a) - 1.0, float(a) + 1.0, [[float(-a), 0.0], [0.0, float(a)]], [[-a, 0, Fmt.point(-a, 0)], [a, 0, Fmt.point(a, 0)]])
	var fs := SUM([[k2, "x³"], [-k2 * a * a, "x"]])
	return pack(["The diagram shows the curve y = %s. The shaded regions lie between the curve and the x-axis." % fs],
		"Find the total area of the shaded regions.", ans2, [like(ans2, 0, R_CANCEL)],
		vals(ans2, [one, area.mul(2), area.add(1), one.add(1)]),
		{"symmetry-shortcut": [
			"f is odd, so the two regions are congruent: the area is 2 × ∫ from −%d to 0." % a,
			"∫ from −%d to 0 of %s dx = %s." % [a, fs, N(one)],
			"2 × %s = %s." % [N(one), N(area)]],
		"split-at-roots": [
			"The curve crosses the axis at x = 0, so split there.",
			"∫ from −%d to 0 gives %s, and ∫ from 0 to %d gives %s." % [a, N(one), a, N(one.neg())],
			"Add their sizes: %s + %s = %s." % [N(one), N(one), N(area)]]}, g2)


# ── An unknown limit or stretch ──────────────────────────────

func u_unknown_upper_limit(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var p: int = s.p
	var k: int = s.k
	var co: Array = [a, b]
	var total := DefiniteIntegralSituation.integral(co, p, k)
	var other_root := -2 * b / a - k
	var ans := val(k, false, "k = ")
	var c0: int = a / 2
	var low := DefiniteIntegralSituation.integral(co, 0, p)
	var wr: Array = [like(ans, other_root, R_OTHER_ROOT)]
	var disc := Q.of(b * b).add(total.mul(4 * c0))
	if disc.is_int() and disc.n >= 0:
		var rt := roundi(sqrt(float(disc.n)))
		if rt * rt == disc.n and (rt - b) % (2 * c0) == 0:
			wr.append(like(ans, (rt - b) / (2 * c0), R_NO_LOWER))
	var gen: Array = vals(ans, [k + 1, k - 1, -k, k + 2])
	var eq := "%s = %s" % [Fmt.poly([c0, b, low.neg().sub(total)]), "0"]
	return pack(["%s = %s, where k > %d." % [integral_text(Fmt.poly(co), p, "k"), N(total), p]], "Find the value of k.", ans, wr, gen,
		{"integrate-then-solve": [
			"F(x) = %s, so F(k) − F(%d) = %s." % [anti(co), p, N(total)],
			"That is the quadratic %s, in k." % eq,
			"Its roots are %d and %d, and only %d is above %d." % [k, other_root, k, p]],
		"gdc-solve": [
			"Graph y = %s against k, and the line y = %s." % [SUM([[c0, "x²"], [b, "x"], [low.neg(), ""]]), N(total)],
			"They meet at %d and %d, and only %d is above %d." % [other_root, k, k, p]]})


func u_unknown_limit_log(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var k: int = s.k
	var top: int = k * k + a
	var m := Q.new(top, a)
	var ans := val(k, false, "k = ")
	var wr: Array = []
	var bad := m.sub(a)
	if bad.is_int() and bad.n > 0:
		var rt := roundi(sqrt(float(bad.n)))
		if rt * rt == bad.n and rt != k:
			wr.append(like(ans, rt, R_NO_LOWER))
	return pack(["%s = (1/2) ln(%s), where k > 0." % [integral_text("x/(%s)" % IntegrationViews.quad(a), 0, "k"), m.text()]], "Find the value of k.", ans, wr,
		vals(ans, [top, k * k, k + 1, 2 * k, k + 2]),
		{"integrate-then-solve": [
			"F(x) = (1/2) ln(%s), by the reverse chain rule." % IntegrationViews.quad(a),
			"F(k) − F(0) = (1/2)(ln(k² + %d) − ln %d) = (1/2) ln((k² + %d)/%d)." % [a, a, a, a],
			"So (k² + %d)/%d = %s, which gives k² = %d." % [a, a, m.text(), k * k],
			"k > 0, so k = %d." % k]})


func u_unknown_limit_trig(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var d: int = s.d
	var n: int = s.n
	var sq: Q = {6: Q.new(1, 4), 4: Q.new(1, 2), 3: Q.new(3, 4)}[d]     # sin² m
	var power := Q.new(1)
	for i in (n + 1) / 2:
		power = power.mul(sq)
	var odd := (n + 1) % 2 == 1
	# n + 1 is odd only for m = π/6, where sin m is a plain 1/2.
	if odd:
		power = power.mul(Q.new(1, 2))
	var v := power.div(n + 1)
	var mk := func(c: int) -> Dictionary:
		return DifferentiationViews.form("m = π/%d" % c, ["m = π/", {"slot": "d"}], {"d": Q.new(c)})
	var ans: Dictionary = mk.call(d)
	var f := "cos x sin%s x" % Fmt.sup(n) if n > 1 else "cos x sin x"
	var sn: String = {6: "1/2", 4: "√2/2", 3: "√3/2"}[d]
	var gen: Array = []
	for c in [2, 12, 3, 4, 6, 8]:
		if c != d:
			gen.append(mk.call(c).values)
	return pack(["%s = %s, where 0 < m < π/2." % [integral_text(f, 0, "m"), v.text()]], "Find the value of m.", ans, [], gen,
		{"integrate-then-solve": [
			"F(x) = %s, by the reverse chain rule." % T(Q.new(1, n + 1), "sin%s x" % Fmt.sup(n + 1)),
			"F(m) − F(0) = (1/%d) sin%s m, as sin 0 = 0." % [n + 1, Fmt.sup(n + 1)],
			"So sin%s m = %s, which gives sin m = %s." % [Fmt.sup(n + 1), v.mul(n + 1).text(), sn],
			"m is in the first quadrant, so m = π/%d." % d]})


func u_unknown_stretch(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var lo: int = s.lo
	var hi: int = s.hi
	var unit := Q.new(hi * hi * hi - lo * lo * lo, 3)
	var area := unit.mul(k)
	var ans := val(k, false, "k = ")
	var g: Variant = null
	if rep == "graph":
		var fn := func(x: float) -> float: return k * x * x
		g = figure(fn, 0.0, hi + 1.0, [[float(lo), float(hi)]], [[lo, 0, Fmt.point(lo, 0)], [hi, 0, Fmt.point(hi, 0)]])
	var wr: Array = []
	if lo != 0:
		wr.append(like(ans, area.mul(3).div(hi * hi * hi), R_NO_LOWER))
	var where := "The shaded region lies" if rep == "graph" else "A region lies"
	var lines: Array = ["%s between y = kx², where k > 0, the x-axis and the lines x = %d and x = %d. Its area is %s." % [where, lo, hi, N(area)]]
	return pack(lines, "Find the value of k.", ans, wr, vals(ans, [area, area.div(hi), area.div(hi * hi), Q.new(k + 1), Q.new(k + 2)]),
		{"integrate-then-solve": [
			"∫ from %d to %d of kx² dx = k[x³/3] = %s k." % [lo, hi, unit.text()],
			"Set that equal to %s and solve." % N(area),
			"k = %s ÷ %s = %d." % [N(area), P(unit), k]],
		"area-scaling": [
			"With k = 1 the area is %s." % N(unit),
			"k is a vertical stretch, so it multiplies the area by k.",
			"k = %s ÷ %s = %d." % [N(area), P(unit), k]]}, g)


# ── A region with a tangent or a line ────────────────────────

func u_region_tangent(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var r: int = s.r
	var p: int = s.p
	var px: int = r + p
	var py: int = a * p * p
	var qx: int = r + p / 2
	var co: Array = [a, -2 * a * r, a * r * r]
	var m: int = 2 * a * p
	var curve_area := Q.new(a * p * p * p, 3)
	var tri := Q.new(p * py, 4)
	var area := curve_area.sub(tri)
	var sf: bool = s.paper == 2
	var ans := val(area, sf, "Area = ")
	var f := func(x: float) -> float: return a * (x - r) * (x - r)
	var line := func(x: float) -> float: return m * (x - qx) * 1.0
	var g := figure(f, r - 1.0, px + 1.0, [], [[r, 0, "R"], [qx, 0, "Q"], [px, py, "P" + Fmt.point(px, py)]],
		[GdcKit.curve(line, float(qx) - 0.5, px + 0.6)])
	var strips: Array = []
	for i in 81:
		var x: float = r + float(p) * i / 80.0
		strips.append([x, maxf(0.0, line.call(x)), f.call(x)])
	g.shade = [strips]
	var eq := Fmt.poly(co)
	var lines: Array = ["The curve y = %s touches the x-axis at R. The tangent at P meets the x-axis at Q." % eq]
	var wr: Array = [like(ans, Q.new(a * p * p * p, 3).sub(Q.new(p * py, 2)).abs_q(), R_CURVE_END), like(ans, curve_area.add(tri), R_ADDED), like(ans, curve_area, R_SAME_LOWER)]
	var y_at := func(x: int) -> String: return N(m * (x - qx))
	return pack(lines, "Find the area of the shaded region%s." % (", to 3 s.f" if sf else ""), ans, wr, vals(ans, [tri, area.mul(2), area.add(1)]),
		{"integral-plus-triangle": [
			"The tangent has gradient %d, so it reaches the x-axis at x = %d." % [m, qx],
			"Under the curve from x = %d to x = %d: %s." % [r, px, N(curve_area)],
			"The triangle under the tangent has base %s and height %d: its area is %s." % [N(Q.new(p, 2)), py, N(tri)],
			"Subtract: %s − %s = %s." % [N(curve_area), N(tri), N(area)]],
		"piecewise-top-minus-bottom": [
			"From x = %d to x = %d the bottom edge is the x-axis: %s." % [r, qx, N(Q.new(a * p * p * p, 24))],
			"From x = %d to x = %d the bottom edge changes to the tangent, y = %s(x%s), at height %s at P." % [qx, px, N(m), Fmt.plus(-qx), y_at.call(px)],
			"Curve minus tangent gives %s." % N(area.sub(Q.new(a * p * p * p, 24))),
			"Add the pieces: %s." % N(area)],
		"gdc-pieces": [
			"The tangent at P meets the axis at x = %d: y = 0 in its equation." % qx,
			"GDC: ∫ of the curve from x = %d to x = %d is %s." % [r, qx, GdcKit.W(Q.new(a * p * p * p, 24))],
			"GDC: ∫ of curve minus tangent from x = %d to x = %d is %s." % [qx, px, GdcKit.W(area.sub(Q.new(a * p * p * p, 24)))],
			"Add the pieces: %s." % GdcKit.W(area)]}, g)


func u_region_line_curve(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var m: int = s.m
	var q2: int = s.q
	var k: int = m * p * p
	var tri := Q.new(k, 2)
	var r := Q.new(q2, p)
	var sf: bool = s.paper == 2
	var value: float = tri.to_float() + k * log(r.to_float())
	var mk := func(c: Variant, d: Variant, u: Q) -> Dictionary:
		var t := "%s + %s" % [N(c), T(d, "ln(%s)" % u.text())]
		return DifferentiationViews.form(t, [{"slot": "c"}, " + ", {"slot": "d"}, " ln(", {"slot": "r"}, ")"], {"c": Q.of(c), "d": Q.of(d), "r": u})
	var ans: Dictionary = val(value, true, "Area = ") if sf else mk.call(tri, k, r)
	var wr: Array
	var gen: Array
	if sf:
		wr = [like(ans, k * log(r.to_float()) - tri.to_float(), R_ADDED)]
		gen = vals(ans, [k * log(r.to_float()), tri.to_float() + k * log(float(q2)), value + 1.0, value * 2.0])
	else:
		wr = [other("%s + %s" % [N(tri.neg()), T(k, "ln(%s)" % r.text())], R_ADDED)]
		gen = [mk.call(tri, k, Q.new(q2)).values, mk.call(k, k, r).values, mk.call(tri, m, r).values, mk.call(tri.add(1), k, r).values, mk.call(tri, k, r.add(1)).values, mk.call(tri.sub(1), k, r).values]
	var f := func(x: float) -> float: return float(k) / x
	var line := func(x: float) -> float: return float(m) * x
	var py := m * p
	var strips: Array = []
	for i in 121:
		var x: float = float(q2) * i / 120.0
		strips.append([x, 0.0, line.call(x) if x <= p else f.call(x)])
	var g := figure(f, float(p) * 0.5, q2 + 1.0, [], [[p, py, "P" + Fmt.point(p, py)], [q2, 0, Fmt.point(q2, 0)]], [GdcKit.curve(line, 0.0, p + 0.5)])
	g.x0 = 0
	g.shade = [strips]
	var eqs := "The line y = %s and the curve y = %d/x, for x > 0, meet at P." % [T(m, "x"), k]
	var ln := T(k, "ln(%s)" % r.text())
	var tail: String = Answer.text(ans) if sf else "%s + %s" % [N(tri), ln]
	return pack([eqs + " The shaded region lies under the line from O to P, then under the curve as far as x = %d." % q2],
		"Find the area of the shaded region%s." % (", to 3 s.f" if sf else ", in the form a + b ln c"), ans, wr, gen,
		{"integral-plus-triangle": [
			"The part under the line is a triangle with base %d and height %d: its area is %s." % [p, py, N(tri)],
			"Under the curve: ∫ from %d to %d of %d/x dx = %s." % [p, q2, k, ln],
			"Add them: %s." % tail],
		"piecewise-top-minus-bottom": [
			"The top edge changes at P, so split at x = %d." % p,
			"∫ from 0 to %d of %s dx = %s." % [p, T(m, "x"), N(tri)],
			"∫ from %d to %d of %d/x dx = %s." % [p, q2, k, ln],
			"Add them: %s." % tail],
		"gdc-pieces": [
			"P is where the line meets the curve: x = %d." % p,
			"GDC: ∫ from 0 to %d of %s dx is %s." % [p, T(m, "x"), N(tri)],
			"GDC: ∫ from %d to %d of %d/x dx is %s." % [p, q2, k, GdcKit.W(k * log(r.to_float()))],
			"Add them: %s." % GdcKit.W(value)]}, g)


# ── A rate in a story ────────────────────────────────────────

static func ctx(s: Dictionary) -> Dictionary:
	return CONTEXTS[s.ctx]


static func rate_unit(c: Dictionary) -> String:
	return "%s per %s" % [c.y, c.per]


## "r(t) = 3t² + 2t + 5", or a model.
static func rate_text(s: Dictionary) -> String:
	if s.fam == "poly":
		return Fmt.poly(s.coeffs, "t")
	if s.fam == "sin":
		return "%d + %d sin(%st)" % [s.A, s.B, Fmt.dec(s.w)]
	return "%de^(−%st) + %d" % [s.A, Fmt.dec(s.w), s.B]


## An antiderivative of a Paper 2 model.
static func rate_anti(s: Dictionary) -> String:
	var r: Q = Q.of(s.B).div(s.w) if s.fam == "sin" else Q.of(s.A).div(s.w)
	if s.fam == "sin":
		return "%dt − %s cos(%st)" % [s.A, Fmt.dec(r), Fmt.dec(s.w)]
	return "−%se^(−%st) + %dt" % [Fmt.dec(r), Fmt.dec(s.w), s.B]


static func story(s: Dictionary) -> String:
	var c := ctx(s)
	return "%s at a rate of r(t) %s, t %s after the start, where r(t) = %s." % [c.say, rate_unit(c), c.time, rate_text(s)]


func u_total_from_rate(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var T_: int = s.T
	var p2: bool = s.paper == 2
	var total: Q = GdcKit.qf(s.total) if p2 else DefiniteIntegralSituation.integral(s.coeffs, 0, T_)
	var end: Q = GdcKit.qf(s.end) if p2 else DefiniteIntegralSituation.at(s.coeffs, T_)
	var words: bool = rep == "words"
	var tail: String = " " + c.y if words else ""
	var ans := val(total, p2, "", tail)
	var shown := Fmt.sf(total) if p2 else N(total)
	var endt := Fmt.sf(end) if p2 else N(end)
	var wr: Array = []
	if words:
		wr = [other("%s %s" % [endt, rate_unit(c)], R_AT_END), other("%s %s" % [shown, rate_unit(c)], R_RATE_UNITS)]
	else:
		wr = [like(ans, end, R_AT_END)]
	var gen := vals(ans, [total.mul(2), total.add(1), end.mul(T_), total.sub(end), total.add(end)])
	var lines: Array = [story(s)] if words else ["r(t) = %s" % rate_text(s)]
	var asked: String = "Find the amount of %s added in the first %d %s" % [c.what, T_, c.time] if words else "Find %s" % integral_text("r(t)", 0, T_).replace(" dx", " dt")
	asked += ", to 3 s.f." if p2 else "."
	var by_hand: String = anti(s.coeffs, "t") if not p2 else rate_anti(s)
	var res := {"gdc-integrate-rate": [
			"The total is the integral of the rate, from 0 to %d." % T_,
			"Enter %s in the GDC's ∫dx template. It gives %s." % [rate_text(s), GdcKit.W(total)]],
		"antiderivative-of-rate": [
			"The total is the integral of the rate, from 0 to %d." % T_,
			"An antiderivative is %s." % by_hand,
			"Subtract its value at t = 0 from its value at t = %d: %s." % [T_, GdcKit.W(total) if p2 else N(total)]]}
	return pack(lines, asked, ans, wr, gen, res)


func u_amount_with_start(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var T_: int = s.T
	var total := DefiniteIntegralSituation.integral(s.coeffs, 0, T_)
	var start: int = s.start
	var v := total.add(start)
	var ans := val(v, false, "", " " + c.y)
	return pack([story(s), "At t = 0 there are %d %s of %s %s." % [start, c.y, c.what, c.where]],
		"Find the amount of %s %s at t = %d." % [c.what, c.where, T_], ans, [like(ans, total, R_NO_START)],
		vals(ans, [DefiniteIntegralSituation.at(s.coeffs, T_).add(start), total.sub(start).abs_q(), v.add(1), v.mul(2)]),
		{"antiderivative-of-rate": [
			"The change is the integral of the rate, from 0 to %d." % T_,
			"An antiderivative is %s, which gives %s." % [anti(s.coeffs, "t"), N(total)],
			"Add the start: %d + %s = %s." % [start, N(total), N(v)]]})


func u_total_from_rate_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var ts: Array = s.ts
	var ys: Array = s.ys
	var pts: Array = []
	var pieces: Array = []
	var total := Q.new(0)
	var strips: Array = []
	for i in ts.size():
		pts.append([float(ts[i]), float(ys[i])])
		if i > 0:
			var bit := Q.new((ys[i - 1] + ys[i]) * (ts[i] - ts[i - 1]), 2)
			total = total.add(bit)
			pieces.append(N(bit))
		strips.append([float(ts[i]), 0.0, float(ys[i])])
	var T_: int = ts[-1]
	var points: Array = []
	for i in ts.size():
		points.append([ts[i], ys[i], Fmt.point(ts[i], ys[i])])
	var top: int = ys.max()
	var g := Plot.spec([pts], points, 0, T_ + 1, 0, top + 2)
	g.merge({"x_name": "t", "y_name": "r", "shade": [strips]})
	var ans := val(total, false, "", " " + c.y)
	var peak := Q.new(top * T_)
	return pack(["%s. The graph shows the rate r, in %s, t %s after the start." % [c.say, rate_unit(c), c.time]],
		"Find the amount of %s added in the first %d %s." % [c.what, T_, c.time], ans, [other("%s %s" % [N(total), rate_unit(c)], R_RATE_UNITS)],
		vals(ans, [peak, Q.new(ys[-1] * T_), total.add(2), total.mul(2), total.sub(2)]),
		{"area-under-rate-graph": [
			"The total is the area under the rate graph.",
			"Split it at the corners into trapezia. Their areas are %s." % ", ".join(pieces),
			"Add them: %s." % N(total)]}, g)


func u_time_to_reach(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var a: int = s.a
	var b: int = s.b
	var T_: int = s.T
	var co: Array = [a, b]
	var total := DefiniteIntegralSituation.integral(co, 0, T_)
	var ans := val(T_, false, "t = ", " " + c.time)
	var flat := total.div(b)
	var root: int = -2 * b / a - T_ if (2 * b) % a == 0 else 0
	return pack(["%s at a rate of r(t) %s, t %s after the start, where r(t) = %s. At t = 0 no %s has been added." % [c.say, rate_unit(c), c.time, Fmt.poly(co, "t"), c.what]],
		"Find the time when %s %s have been added." % [N(total), c.y], ans, [],
		vals(ans, [flat, Q.new(T_ + 1), Q.new(T_ + 2), total.div(a + b), Q.new(T_ * 2), Q.new(T_ - 1)]),
		{"antiderivative-of-rate": [
			"The amount added by time T is %s." % anti(co, "T"),
			"Set that equal to %s and solve the quadratic." % N(total),
			"Its positive root is %d%s." % [T_, " (the other, %d, is before the start)" % root if root != 0 and root < 0 else ""]]})


func u_interpret_integral(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var T_: int = s.T
	var total: Q = GdcKit.qf(s.total) if s.paper == 2 else DefiniteIntegralSituation.integral(s.coeffs, 0, T_)
	var v: String = Fmt.sf(total) if s.paper == 2 else N(total)
	var built := DerivativeMeaningViews.claim_answer("%s %s of %s were added in the first %d %s." % [v, c.y, c.what, T_, c.time], [
		["At t = %d, %s was being added at %s %s." % [T_, c.what, v, rate_unit(c)], R_RATE_UNITS],
		["At t = %d, there were exactly %s %s of %s %s, whatever the start." % [T_, v, c.y, c.what, c.where], ""],
		["On average, %s %s of %s were added in each of the first %d %s." % [v, c.y, c.what, T_, c.time], ""]])
	return {"lines": [story(s), "%s = %s" % [integral_text("r(t)", 0, T_).replace(" dx", " dt"), v]],
		"asked": "Which sentence says what this integral means here?", "answer": built.answer, "wrongs": built.wrongs, "generic": [],
		"methods": {"area-under-rate-graph": method([
			"The integral is the area under the graph of the rate, from t = 0 to t = %d." % T_,
			"Rate × time is an amount, so the area is the %s added, in %s, not a rate." % [c.what, c.y],
			"It says nothing about what was there at the start.",
			Answer.text(built.answer)], built.answer.values)}}
