class_name AiCompositeInverseViews
extends ExtensionViews
## The views on the `ai-composite-inverse` situation (FAL-1007): one builder per unknown of
## fn-ai-composite-inverse (AI-AHL2.7). Two models chained in a story: the composite's value (the
## inner model as a rule, a table or a graph), its rule in the first input, which order of a
## percentage and a fixed amount gives the lower or higher price, and the input that gives a
## target; then a model undone: its inverse (and, in words, what the inverse calculates), a value
## of the inverse, the least k that makes a quadratic one-to-one on x ≥ k, the domain or range of
## an inverse, (f∘f⁻¹)(a) or a from f⁻¹(a) = b, and the graph of f⁻¹ picked from four.
##
## Every question is Paper 2, as every AI paper allows a GDC: a value that ends within two
## decimal places is exact, any other is 3 s.f. with the rounding trap. A rule, a statement, a
## domain or a range is one of four written options (the `choice` kind); the graph of f⁻¹ is
## pick-the-graph.

const S := preload("res://engine/situations/ai_composite_inverse.gd")
const T := "fn-ai-composite-inverse"
const CC := "AI-AHL2.7.composite-context#"
const FI := "AI-AHL2.7.find-inverse#"
const RD := "AI-AHL2.7.restrict-domain#"
const II := "AI-AHL2.7.inverse-identity#"
const R_OUTER_FIRST := CC + "0"
const R_PRODUCT := CC + "1"
const R_ONE_X := CC + "2"
const R_SAME := CC + "3"
const R_RECIPROCAL := FI + "0"
const R_ORDER := FI + "1"
const R_F_OF_A := FI + "2"
const R_DOMAIN_OF_F := RD + "0"
const R_Y_INTERCEPT := RD + "2"
const R_ONE := II + "0"
const R_INV_OF_B := II + "1"
const R_AXIS := II + "2"
const R_VERTEX_Y := T + "#12"

const UNKNOWNS := ["composite-value", "composite-rule", "composite-order", "composite-equation", "inverse-rule",
	"inverse-value", "restrict-domain", "inverse-domain-range", "inverse-identity", "inverse-graph"]

## A composite story: the inner model g (its letter, its input's letter and unit), the outer f
## (its letter, the middle quantity it takes, its output's unit), and the sentences.
const STORY := {
	"filters": {"g": "n", "v": "t", "in": "hours", "f": "C", "mid": "filters", "out": "dollars",
		"g_line": "A workshop holds n(t) = %s water filters t hours after it opens.",
		"f_line": "Shipping n filters to the camp costs C(n) = %s dollars.",
		"g_about": "the number of water filters, n(t), a workshop holds t hours after it opens",
		"g_eq": "g(t) = %s is the number of filters a workshop holds t hours after it opens.",
		"f_eq": "f(x) = %s is the cost, in dollars, of shipping x filters.",
		"value": "Find the cost, in dollars, of shipping the filters the workshop holds %s hours after it opens.",
		"solve": "Find the time, in hours, after which shipping the filters the workshop holds costs %s dollars.",
		"rule": "Find a rule, in terms of t, for the cost in dollars of shipping the filters the workshop holds t hours after it opens."},
	"furnace": {"g": "T", "v": "m", "in": "minutes", "f": "F", "mid": "°C", "out": "°F",
		"g_line": "The temperature of a furnace m minutes after it is lit is T(m) = %s °C.",
		"f_line": "A temperature of T °C is F(T) = %s °F.",
		"g_about": "the temperature in °C, T(m), of a furnace m minutes after it is lit",
		"g_eq": "g(m) = %s is the temperature in °C of a furnace m minutes after it is lit.",
		"f_eq": "f(x) = %s is a temperature of x °C written in °F.",
		"value": "Find the temperature of the furnace, in °F, %s minutes after it is lit.",
		"solve": "Find the time, in minutes, after which the furnace is at %s °F.",
		"rule": "Find a rule, in terms of m, for the temperature of the furnace in °F, m minutes after it is lit."},
	"convoy": {"g": "d", "v": "t", "in": "hours", "f": "L", "mid": "km", "out": "litres",
		"g_line": "A convoy truck is d(t) = %s km from the depot t hours after it sets off.",
		"f_line": "When it is d km from the depot it has L(d) = %s litres of fuel left.",
		"g_about": "the distance in km, d(t), of a convoy truck from the depot t hours after it sets off",
		"g_eq": "g(t) = %s is the distance in km of a truck from the depot t hours after it sets off.",
		"f_eq": "f(x) = %s is the fuel left, in litres, when the truck is x km from the depot.",
		"value": "Find the fuel left in the truck, in litres, %s hours after it sets off.",
		"solve": "Find the time, in hours, after which the truck has %s litres of fuel left.",
		"rule": "Find a rule, in terms of t, for the fuel left in litres t hours after the truck sets off."},
	"scrap": {"g": "s", "v": "h", "in": "hours", "f": "K", "mid": "kg", "out": "caps",
		"g_line": "A salvage crew's cart holds s(h) = %s kg of scrap metal h hours after the crew sets out.",
		"f_line": "A trader pays K(s) = %s caps for s kg of scrap metal.",
		"g_about": "the mass in kg, s(h), of scrap metal in a salvage crew's cart h hours after the crew sets out",
		"g_eq": "g(h) = %s is the mass in kg of scrap metal in a crew's cart h hours after it sets out.",
		"f_eq": "f(x) = %s is what a trader pays, in caps, for x kg of scrap metal.",
		"value": "Find what the trader pays, in caps, for the scrap in the cart %s hours after the crew sets out.",
		"solve": "Find the time, in hours, after which the trader would pay %s caps for the scrap in the cart.",
		"rule": "Find a rule, in terms of h, for what the trader pays in caps for the scrap in the cart h hours after the crew sets out."},
}

## A model to undo: its letter, its input's letter, the rule's sentence (equation), the model
## in words, what f⁻¹(x) calculates and what f(x) does (a wrong meaning), the context question
## for a value of f⁻¹, and that value's unit.
const MODEL := {
	"taxi": {"f": "F", "v": "d", "eq": "F(d) = %s is the fare, in dollars, for a taxi journey of d km.",
		"words": "A taxi charges %s dollars plus %s dollars per km. F(d) is the fare, in dollars, for a journey of d km.",
		"means": "the distance, in km, of a journey with a fare of x dollars", "f_means": "the fare, in dollars, for a journey of x km",
		"ask": "Find the distance, in km, of a journey with a fare of %s dollars.", "unit": " km"},
	"celsius": {"f": "F", "v": "C", "eq": "F(C) = %s is a temperature of C °C written in °F.",
		"words": "To write a temperature of C °C in °F, multiply by %s, then add %s. The result is F(C).",
		"means": "the temperature in °C that is x °F", "f_means": "the temperature in °F that is x °C",
		"ask": "Find the temperature in °C that is %s °F.", "unit": " °C"},
	"copper": {"f": "P", "v": "m", "eq": "P(m) = %s is what a trader pays, in caps, for a load of m kg of copper.",
		"words": "A trader pays %s caps for each load of copper plus %s caps per kg. P(m) is what the trader pays, in caps, for a load of m kg.",
		"means": "the mass, in kg, of a load the trader pays x caps for", "f_means": "what the trader pays, in caps, for a load of x kg",
		"ask": "Find the mass, in kg, of a load of copper the trader pays %s caps for.", "unit": " kg"},
	"average": {"f": "A", "v": "n", "eq": "A(n) = %s is the average cost, in dollars, of each of n filters.",
		"words": "Setting up to make filters costs %s dollars, and each filter then costs %s dollars. A(n) is the average cost, in dollars, of each of n filters.",
		"means": "the number of filters made when the average cost is x dollars", "f_means": "the average cost, in dollars, of each of x filters",
		"ask": "Find the number of filters made when the average cost of each is %s dollars.", "unit": " filters"},
	"signal": {"f": "S", "v": "p", "eq": "S(p) = %s is the strength, in dB, of a radio signal from a transmitter of p watts.",
		"words": "The strength, S(p) dB, of a radio signal from a transmitter of p watts is found by taking the natural log of p, multiplying by %s, then adding %s.",
		"means": "the power, in watts, that gives a signal of x dB", "f_means": "the strength, in dB, of a signal from x watts",
		"ask": "Find the power, in watts, of a transmitter whose signal is %s dB.", "unit": " watts"},
	"tank": {"f": "V", "v": "h", "eq": "V(h) = %s is the volume, in m³, of water in a tank when its depth is h m.",
		"ask": "Find the depth, in m, of the water when the tank holds %s m³.", "unit": " m"},
	"pump": {"f": "C", "v": "x", "eq": "The cost, in dollars per hour, of running a pump at x litres per second is C(x) = %s"},
	"bridge": {"f": "h", "v": "x", "eq": "The height, in m, of a rope bridge x m from one end is h(x) = %s"},
	"profit": {"f": "P", "v": "x", "eq": "The profit, in caps, from selling x crates of water is P(x) = %s"},
	"tank-line": {"f": "V", "v": "t", "eq": "V(t) = %s, for %s ≤ t ≤ %s, is the volume, in litres, of water in a tank t minutes after a pump starts."},
	"fuel": {"f": "L", "v": "d", "eq": "L(d) = %s, for %s ≤ d ≤ %s, is the fuel left, in litres, after a truck has travelled d km."},
}


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
	out.given = AiCompositeInverseSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## A GDC screen value: 6 s.f.
static func W(x: Variant) -> String:
	return Fmt.work(x, 6)


## A number in a sum: bracketed when negative.
static func B(v: Variant) -> String:
	var t := D(v)
	return "(%s)" % t if t.begins_with("−") else t


## A polynomial's terms in the order they are written, [coefficient, power]: highest power
## first, but a falling line with a positive start is written start first ("80 − 0.12d").
static func pieces(co: Array) -> Array:
	var out: Array = []
	for p in range(co.size() - 1, -1, -1):
		if not Q.of(co[p]).is_zero():
			out.append([Q.of(co[p]), p])
	if out.size() == 2 and out[0][1] == 1 and out[1][1] == 0 and out[0][0].sign() < 0 and out[1][0].sign() > 0:
		out.reverse()
	return out


## The terms of co joined with their signs, each written by body(magnitude, power).
static func render(co: Array, body: Callable) -> String:
	var out := ""
	for pc in pieces(co):
		var c: Q = pc[0]
		var t: String = body.call(c.abs_q(), pc[1])
		if out == "":
			out = ("−" if c.sign() < 0 else "") + t
		else:
			out += (" − " if c.sign() < 0 else " + ") + t
	return out if out != "" else "0"


## A rule in v: "0.02n² + 3n + 150", "80 − 0.12d".
static func ptext(co: Array, v: String) -> String:
	return render(co, func(m: Q, p: int) -> String: return D(m) if p == 0 else ("" if m.eq(1) else D(m)) + v + Fmt.sup(p))


## A rule with a number put in: "2.5 × 125 + 400", "0.02 × 40² + 3 × 40 + 150".
static func pnum(co: Array, x: Variant) -> String:
	var xs := B(x)
	return render(co, func(m: Q, p: int) -> String: return D(m) if p == 0 else ("" if m.eq(1) else D(m) + " × ") + xs + Fmt.sup(p))


## A rule with an expression put in: "2.5(35t + 20) + 400".
static func pexpr(co: Array, inner: String) -> String:
	return render(co, func(m: Q, p: int) -> String: return D(m) if p == 0 else ("" if m.eq(1) else D(m)) + "(" + inner + ")" + Fmt.sup(p))


static func ev(co: Array, x: Variant) -> Q:
	return S.ev(co, x)


## A one-number answer: exact when it ends within two decimal places, else 3 s.f.
static func num_ans(label: String, v: Variant, unit: String = "") -> Dictionary:
	var x: float = v.to_float() if v is Q else float(v)
	var exact: bool = S.ends(v) if v is Q else S.ends_f(x)
	var val: Q = (v if v is Q else Q.new(roundi(x * 100.0), 100)) if exact else GdcKit.qf(x)
	var ans := Answer.make("number", {"v": val}, {}, label, unit)
	ans.show = "dec" if exact else "sf"
	ans.exact = exact
	return ans


static func num_wrong(v: Variant, ref: String) -> Dictionary:
	return wrong({"v": S.shown_q(v)}, ref)


static func num_fill(v: Variant) -> Dictionary:
	return {"v": S.shown_q(v)}


## A value in the working: exact when it ends, else the GDC's 6 s.f.
static func wv(v: Variant) -> String:
	if v is Q:
		return D(v) if S.ends(v) else W(v.to_float())
	return D(Q.new(roundi(float(v) * 100.0), 100)) if S.ends_f(float(v)) else W(v)


static func final_step(ans: Dictionary) -> String:
	return "So " + Fmt.stop(Answer.text(ans))


static func pack(lines: Array, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {}, "table": null}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


static func choice_pack(lines: Array, asked: String, right: String, tagged: Array, plain: Array, steps: Dictionary) -> Dictionary:
	var pick := InverseRuleViews.pick_of(right, tagged, plain)
	var out := {"lines": lines, "asked": asked, "answer": pick.answer, "wrongs": pick.wrongs, "fillers": pick.fillers, "methods": {}, "table": null}
	for m in steps:
		out.methods[m] = method(steps[m], pick.answer.values)
	return out


static func tag(text: String, ref: String) -> Dictionary:
	return InverseRuleViews.tag(text, ref)


# ── The composite stories ────────────────────────────────────

static func st(s: Dictionary) -> Dictionary:
	return STORY[s.story]


## "n(3)", "C(125)".
static func at(name: String, x: Variant) -> String:
	return "%s(%s)" % [name, D(x)]


## The graph of g from 0 to hi, with its points at 0 and at the inputs given marked.
static func g_graph(s: Dictionary, hi: int, marks: Array) -> Dictionary:
	var g: Array = s.g
	var y_hi := 0.0
	for x in range(0, hi + 1):
		y_hi = maxf(y_hi, ev(g, x).to_float())
	var top := Plot.nice_top(y_hi)
	var pts: Array = []
	for x in [Q.new(0)] + marks:
		var y := ev(g, x)
		pts.append([x.to_float(), y.to_float(), pt(x, y)])
	var fn := func(x: float) -> float: return ev(g, GdcKit.qf(x)).to_float()
	var gr := Plot.spec([Plot.sample(fn, 0.0, float(hi))], pts, 0, hi, 0, top)
	gr.one_colour = true
	return gr


## The inner model's rule read off its graph from two marked points.
static func g_from_graph(s: Dictionary, x2: Q) -> String:
	var c := st(s)
	var g: Array = s.g
	return "From the graph, %s = %s and %s = %s, so %s rises by %s each %s: %s(%s) = %s." % [
		at(c.g, 0), D(ev(g, 0)), at(c.g, x2), D(ev(g, x2)), c.g, D(g[1]), c["in"].trim_suffix("s"), c.g, c.v, ptext(g, c.v)]


## A point with its coordinates as decimals.
static func pt(x: Variant, y: Variant) -> String:
	return "(%s, %s)" % [D(x), D(y)]


# ── composite-value ──────────────────────────────────────────

func u_composite_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := st(s)
	var g: Array = s.g
	var f: Array = s.f
	var x0: Q = s.x0
	var gx := ev(g, x0)
	var v := ev(f, gx)
	var ans := num_ans("", v, " " + c.out)
	var lines: Array = []
	var read: String
	match rep:
		"table":
			lines = ["The table gives %s." % c.g_about, c.f_line % ptext(f, c.g)]
			read = "From the table, %s = %s." % [at(c.g, x0), D(gx)]
		"graph":
			lines = ["The graph shows %s." % c.g_about, c.f_line % ptext(f, c.g)]
			read = "From the graph, %s = %s." % [at(c.g, x0), D(gx)]
		_:
			lines = [c.g_line % ptext(g, c.v), c.f_line % ptext(f, c.g)]
	var wr: Array = [num_wrong(ev(f, x0).mul(gx), R_PRODUCT)]
	if rep == "words":
		wr.push_front(num_wrong(ev(g, ev(f, x0)), R_OUTER_FIRST))
	var fill: Array = [num_fill(gx), num_fill(ev(f, x0))]
	var done := "So %s(%s(%s)) = %s." % [c.f, c.g, D(x0), Answer.text(ans)]
	var inside: Array
	var gdc: Array
	if rep == "words":
		inside = ["%s = %s = %s." % [at(c.g, x0), pnum(g, x0), D(gx)],
			"%s = %s = %s." % [at(c.f, gx), pnum(f, gx), D(v)], done]
		gdc = ["Enter Y1 = %s for %s and Y2 = %s for %s." % [ptext(g, "X"), c.g, ptext(f, "X"), c.f],
			"Evaluate Y2(Y1(%s)) on the GDC: it gives %s." % [D(x0), D(v)], done]
	else:
		inside = [read, "%s = %s = %s." % [at(c.f, gx), pnum(f, gx), D(v)], done]
		gdc = [read, "Enter Y1 = %s for %s and evaluate Y1(%s) on the GDC: it gives %s." % [ptext(f, "X"), c.f, D(gx), D(v)], done]
	var out := pack(lines, c.value % D(x0), ans, wr, fill, {"inside-out": inside, "gdc-composite": gdc})
	if rep == "table":
		var xs: Array = range(0, 7)
		out.table = {"rows": [[c.v, xs.map(func(x): return str(x))], ["%s(%s)" % [c.g, c.v], xs.map(func(x): return D(ev(g, x)))]]}
	elif rep == "graph":
		out.graph = g_graph(s, 8, [x0, s.t2])
	return out


# ── composite-rule ───────────────────────────────────────────

func u_composite_rule(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := st(s)
	var g: Array = s.g
	var f: Array = s.f
	var v: String = c.v
	var h := S.comp(f, g)
	var right := ptext(h, v)
	var quad: bool = f.size() == 3
	var tagged: Array = [tag(ptext(S.comp(g, f), v), R_OUTER_FIRST)]
	var plain: Array = []
	var gb: Q = g[0]
	var ga: Q = g[1]
	if quad:
		var a: Q = f[2]
		var b: Q = f[1]
		var cc: Q = f[0]
		# a(pt + q)² put in, but b·t left with t in place of the inner expression.
		tagged.append(tag(ptext([a.mul(gb).mul(gb).add(cc), a.mul(ga).mul(gb).mul(2).add(b), a.mul(ga).mul(ga)], v), R_ONE_X))
		plain.append(ptext([a.mul(gb).mul(gb).add(b.mul(gb)).add(cc), b.mul(ga), a.mul(ga).mul(ga)], v))
		plain.append(ptext(CompositePairSituation.padd(f, g), v))
	else:
		plain.append(ptext([gb.add(f[0]), f[1].mul(ga)], v))
		plain.append(ptext(CompositePairSituation.padd(f, g), v))
	var lines: Array
	var asked: String
	var fn: String
	var gn: String
	if rep == "equation":
		lines = [c.g_eq % ptext(g, v), c.f_eq % ptext(f, "x")]
		asked = "Find (f∘g)(%s) as a rule in %s." % [v, v]
		fn = "f"
		gn = "g"
	else:
		lines = [c.g_line % ptext(g, v), c.f_line % ptext(f, c.g)]
		asked = c.rule
		fn = c.f
		gn = c.g
	var name := "%s(%s(%s))" % [fn, gn, v]
	var inner := ptext(g, v)
	var put := "%s = %s." % [name, pexpr(f, inner)]
	var expand: String
	if quad:
		var sq := S.comp([Q.new(0), Q.new(0), Q.new(1)], g)
		var rest := CompositePairSituation.padd(CompositePairSituation.pscale(sq, f[2]), [Q.new(0)])
		expand = "(%s)² = %s, so %s = %s%s." % [inner, ptext(sq, v), name, ptext(rest, v), _rest_text(f, g, v)]
	else:
		var f0 := Q.of(f[0])
		expand = "Multiply out the bracket: %s = %s%s." % [name, ptext(CompositePairSituation.pscale(g, f[1]), v), "" if f0.is_zero() else (" − " if f0.sign() < 0 else " + ") + D(f0.abs_q())]
	var done := "So %s = %s." % [name, right]
	var units: String
	if rep == "equation":
		units = "g takes %s %s to %s, and f takes %s to %s, so (f∘g)(%s) = f(g(%s)) gives %s from %s." % [v, c["in"], c.mid, c.mid, c.out, v, v, c.out, c["in"]]
	else:
		units = "%s takes %s %s to %s, and %s takes %s to %s, so the rule asked for is %s." % [gn, v, c["in"], c.mid, fn, c.mid, c.out, name]
	var out := choice_pack(lines, asked, right, tagged, plain, {
		"substitute-expression": [put, expand, done],
		"units-check": [units, put, expand, done]})
	return out


## The terms of f past the square, with the inner expression put in: " + 3(40t + 10) + 150", for
## the expand line, written out: " + 120t + 30 + 150".
static func _rest_text(f: Array, g: Array, v: String) -> String:
	var lin := CompositePairSituation.pscale(g, f[1])
	var out := ""
	for p in [1, 0]:
		var cq: Q = lin[p] if p < lin.size() else Q.new(0)
		if not cq.is_zero():
			out += (" − " if cq.sign() < 0 else " + ") + D(cq.abs_q()) + (v if p == 1 else "")
	var f0 := Q.of(f[0])
	if not f0.is_zero():
		out += (" − " if f0.sign() < 0 else " + ") + D(f0.abs_q())
	return out


# ── composite-order ──────────────────────────────────────────

func u_composite_order(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m := Q.new(100 - s.pct, 100)
	var price := Q.new(s.price)
	var cq := Q.new(s.c if s.kind == "fee" else -s.c)
	var L: String = "F" if s.kind == "fee" else "V"
	# (L∘D)(P): the percentage first; (D∘L)(P): the fixed amount first.
	var d1 := price.mul(m)
	var pd := d1.add(cq)
	var l1 := price.add(cq)
	var dp := l1.mul(m)
	var name_ld := "(%s∘D)(%d)" % [L, s.price]
	var name_dl := "(D∘%s)(%d)" % [L, s.price]
	var lower := pd.lt(dp)
	var want_ld: bool = lower == (s.want == "lower")
	var word: String = s.want
	var than := "lower than" if s.want == "lower" else "higher than"
	var claim := func(n1: String, v1: Q, n2: String, v2: Q) -> String:
		return "%s = %s caps, %s %s = %s caps" % [n1, D(v1), than, n2, D(v2)]
	var right: String = claim.call(name_ld, pd, name_dl, dp) if want_ld else claim.call(name_dl, dp, name_ld, pd)
	var best: Q = pd if want_ld else dp
	var tagged := [tag("Either order: both give %s caps" % D(best), R_SAME)]
	var plain: Array = [claim.call(name_dl, dp, name_ld, pd) if want_ld else claim.call(name_ld, pd, name_dl, dp),
		claim.call(name_ld, dp, name_dl, pd) if want_ld else claim.call(name_dl, pd, name_ld, dp)]
	var lines: Array = ["A trader takes %d%% off a price of x caps: D(x) = %sx." % [s.pct, D(m)],
		("A trading fee adds %d caps to a price of x caps: F(x) = x + %d." % [s.c, s.c]) if s.kind == "fee"
			else "A voucher takes %d caps off a price of x caps: V(x) = x − %d." % [s.c, s.c],
		"An item is priced at %d caps." % s.price]
	var asked := "Which order of D and %s gives the %s final price for the item, and what is it?" % [L, word]
	var sgn := "+" if s.kind == "fee" else "−"
	var d_first := "D first: D(%d) = %s × %d = %s, then %s(%s) = %s %s %d = %s, so %s = %s." % [s.price, D(m), s.price, D(d1), L, D(d1), D(d1), sgn, s.c, D(pd), name_ld, D(pd)]
	var l_first := "%s first: %s(%d) = %d %s %d = %s, then D(%s) = %s × %s = %s, so %s = %s." % [L, L, s.price, s.price, sgn, s.c, D(l1), D(l1), D(m), D(l1), D(dp), name_dl, D(dp)]
	var cmp := "%s %s %s, so %s gives the %s price." % [D(pd), "<" if lower else ">", D(dp), name_ld if want_ld else name_dl, word]
	var done := "So the answer is " + Fmt.stop(right)
	var shift := m.mul(cq)
	var units := ["Both functions take a price in caps to a price in caps, so either order makes sense; they differ in what the %d%% is taken from." % s.pct,
		"With %s first, the %d%% is also taken from the %d caps: (D∘%s)(x) = %s(x %s %d) = %sx %s %s, but (%s∘D)(x) = %sx %s %d." % [L, s.pct, s.c, L, D(m), sgn, s.c, D(m), sgn, D(shift.abs_q()), L, D(m), sgn, s.c],
		"At x = %d: %s = %s and %s = %s." % [s.price, name_dl, D(dp), name_ld, D(pd)], done]
	return choice_pack(lines, asked, right, tagged, plain, {"inside-out": [d_first, l_first, cmp, done], "units-check": units})


# ── composite-equation ───────────────────────────────────────

func u_composite_equation(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := st(s)
	var g: Array = s.g
	var f: Array = s.f
	var target: Q = s.target
	var t: Q = s.t
	var v: String = c.v
	var h := S.comp(f, g)
	var mid := target.sub(f[0]).div(f[1])
	var ans := num_ans("%s = " % v, t, " " + c["in"])
	var hw := S.comp(g, f)
	var slip := target.sub(hw[0]).div(hw[1])
	var wr: Array = [num_wrong(slip, R_OUTER_FIRST)] if slip.sign() > 0 else []
	var fill: Array = [num_fill(mid), num_fill(target.sub(g[0]).div(g[1]))]
	var lines: Array
	if rep == "graph":
		lines = ["The graph shows %s." % c.g_about, c.f_line % ptext(f, c.g)]
	else:
		lines = [c.g_line % ptext(g, v), c.f_line % ptext(f, c.g)]
	var done := final_step(ans)
	var outer_solve := "%s(%s) = %s gives %s = %s, so %s = (%s − %s) ÷ %s = %s." % [c.f, c.g, D(target), ptext(f, c.g), D(target), c.g, D(target), B(f[0]), B(f[1]), wv(mid)]
	var inner_solve: String
	if rep == "graph":
		inner_solve = "From the graph, %s(%s) = %s when %s = %s." % [c.g, v, D(mid), v, D(t)]
	else:
		inner_solve = "%s(%s) = %s gives %s = %s, so %s = (%s − %s) ÷ %s = %s." % [c.g, v, wv(mid), ptext(g, v), wv(mid), v, wv(mid), B(g[0]), B(g[1]), wv(t)]
	var read := g_from_graph(s, s.t2) if rep == "graph" else ""
	var name := "%s(%s(%s))" % [c.f, c.g, v]
	var built := "%s = %s = %s." % [name, pexpr(f, ptext(g, v)), ptext(h, v)]
	var solved := "%s = %s, so %s = (%s − %s) ÷ %s = %s." % [ptext(h, v), D(target), v, D(target), B(h[0]), B(h[1]), wv(t)]
	var gdc := ["Graph y = %s and y = %s on the GDC." % [pexpr(f, ptext(g, "x")), D(target)], "They meet where x = %s." % wv(t), done]
	var subst := [built, solved, done]
	if rep == "graph":
		subst.push_front(read)
		gdc.push_front(read)
	var out := pack(lines, c.solve % D(target), ans, wr, fill, {"inside-out": [outer_solve, inner_solve, done],
		"substitute-expression": subst, "gdc-composite": gdc})
	if rep == "graph":
		out.graph = g_graph(s, 8, [t, s.t2])
	return out


# ── Models to undo ───────────────────────────────────────────

static func md(s: Dictionary) -> Dictionary:
	return MODEL[s.story]


## The rule's right-hand side: "2.2d + 4", "2.5 + 600/n", "4 + 2.5 ln p", "0.2h³ + 1.5h".
static func rhs(s: Dictionary, v: String) -> String:
	match s.fam:
		"lin", "interval":
			return ptext([s.b, s.m], v)
		"rat":
			return "%s + %s/%s" % [D(s.c), D(s.k), v]
		"log":
			return "%s + %s ln %s" % [D(s.a), D(s.b), v]
		"cubic":
			return ptext([Q.new(0), s.c, Q.new(0), s.a], v)
		"quad":
			return ptext(S.quad_co(s), v)
	return "?"


## f⁻¹(x) written out, and the slips: the reciprocal, the steps undone in the original order,
## and two plain wrong rules.
static func inv_texts(s: Dictionary) -> Dictionary:
	match s.fam:
		"lin":
			var m := D(s.m)
			var b := D(s.b)
			return {"right": "(x − %s)/%s" % [b, m], "recip": "1/(%s)" % rhs(s, "x"), "order": "x/%s − %s" % [m, b],
				"plain": ["(x + %s)/%s" % [b, m], "(x − %s)/%s" % [m, b]]}
		"rat":
			var c := D(s.c)
			var k := D(s.k)
			return {"right": "%s/(x − %s)" % [k, c], "recip": "1/(%s)" % rhs(s, "x"), "order": "%s/x − %s" % [k, c],
				"plain": ["%s/(x + %s)" % [k, c], "(x − %s)/%s" % [c, k]]}
		"log":
			var a := D(s.a)
			var b2 := D(s.b)
			return {"right": "e^((x − %s)/%s)" % [a, b2], "recip": "1/(%s)" % rhs(s, "x"), "order": "(e^x − %s)/%s" % [a, b2],
				"plain": ["e^((x + %s)/%s)" % [a, b2], "ln((x − %s)/%s)" % [a, b2]]}
	return {}


## What f does, in order, and the same steps undone in reverse.
static func does(s: Dictionary) -> Array:
	match s.fam:
		"lin":
			return ["multiplies by %s, then adds %s" % [D(s.m), D(s.b)], "subtract %s, then divide by %s" % [D(s.b), D(s.m)]]
		"rat":
			return ["divides %s by %s, then adds %s" % [D(s.k), md(s).v, D(s.c)], "subtract %s, then divide %s by the result" % [D(s.c), D(s.k)]]
		"log":
			return ["takes the natural log, multiplies by %s, then adds %s" % [D(s.b), D(s.a)], "subtract %s, divide by %s, then raise e to that power" % [D(s.a), D(s.b)]]
	return ["", ""]


static func model_lines(rep: String, s: Dictionary) -> Array:
	var m := md(s)
	if rep == "words" and m.has("words"):
		match s.fam:
			"lin":
				return [m.words % ([D(s.m), D(s.b)] if s.story == "celsius" else [D(s.b), D(s.m)])]
			"rat":
				return [m.words % [D(s.k), D(s.c)]]
			"log":
				return [m.words % [D(s.b), D(s.a)]]
	return [m.eq % rhs(s, m.v)]


# ── inverse-rule ─────────────────────────────────────────────

func u_inverse_rule(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m := md(s)
	var F: String = m.f
	var tx := inv_texts(s)
	var words := rep == "words"
	var means: String = m.means
	var say := func(rule: String, what: String) -> String:
		return "%s⁻¹(x) = %s" % [F, rule] + (", %s" % what if words else "")
	var right: String = say.call(tx.right, means)
	var tagged := [tag(say.call(tx.recip, means), R_RECIPROCAL), tag(say.call(tx.order, means), R_ORDER)]
	var plain: Array = [say.call(tx.right, m.f_means)] if words else []
	plain.append_array(tx.plain.map(func(r): return say.call(r, means)))
	var asked := "Find %s⁻¹(x) and state what it calculates." % F if words else "Find %s⁻¹(x)." % F
	var y := "y = " + rhs(s, "x")
	var swap: Array
	match s.fam:
		"lin":
			swap = ["Write %s and swap x and y: x = %s." % [y, rhs(s, "y")],
				"Solve for y: %sy = x − %s, so y = %s." % [D(s.m), D(s.b), tx.right]]
		"rat":
			swap = ["Write %s and swap x and y: x = %s." % [y, rhs(s, "y")],
				"Then x − %s = %s/y, so y = %s." % [D(s.c), D(s.k), tx.right]]
		_:
			swap = ["Write %s and swap x and y: x = %s." % [y, rhs(s, "y")],
				"Then ln y = (x − %s)/%s, so y = %s." % [D(s.a), D(s.b), tx.right]]
	var undo: Array = ["%s %s." % [F, does(s)[0]], "Undo the steps in reverse order: %s. That gives %s." % [does(s)[1], tx.right]]
	if words:
		swap.push_front("From the words, %s(%s) = %s." % [F, m.v, rhs(s, m.v)])
		swap.append("%s⁻¹ takes an output of %s back to its input, so %s⁻¹(x) is %s." % [F, F, F, m.means])
		undo.append("Undoing %s takes its output back to its input, so %s⁻¹(x) is %s." % [F, F, m.means])
	var done := "So " + Fmt.stop(right)
	swap.append(done)
	undo.append(done)
	return choice_pack(model_lines(rep, s), asked, right, tagged, plain, {"swap-and-solve": swap, "undo-in-reverse": undo})


# ── inverse-value ────────────────────────────────────────────

func u_inverse_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m := md(s)
	var F: String = m.f
	var v: Q = s.v
	var x := S.finv(s, v.to_float())
	var exact: Variant = S.finv_q(s, v)
	var val: Variant = exact if exact != null else x
	var words := rep == "words"
	var ans := num_ans("" if words else "%s⁻¹(%s) = " % [F, D(v)], val, m.unit if words else "")
	var fv := S.fval(s, v.to_float())
	# 1/f(v) is a slip to show while it reads as a number (not 0.0000300).
	var wr: Array = ([num_wrong(1.0 / fv, R_RECIPROCAL)] if absf(1.0 / fv) >= 0.001 else []) + [num_wrong(fv, R_F_OF_A)]
	if s.fam != "cubic":
		wr.insert(1, num_wrong(S.wrong_order(s, v.to_float()), R_ORDER))
	var fill: Array = [num_fill(x * 2.0), num_fill(-x)]
	var lines := [m.eq % rhs(s, m.v)]
	var asked: String = m.ask % D(v) if words else "Find %s⁻¹(%s)." % [F, D(v)]
	var done := final_step(ans)
	var name := "%s⁻¹(%s)" % [F, D(v)]
	var steps := {}
	var eqn := "%s = %s" % [rhs(s, m.v), D(v)]
	steps["solve-for-value"] = ["%s is the %s with %s(%s) = %s: solve %s." % [name, m.v, F, m.v, D(v), eqn],
		"The GDC's solver (or the graph of y = %s meeting y = %s) gives %s = %s." % [rhs(s, "x"), D(v), m.v, wv(val)], done]
	if s.fam != "cubic":
		var undo: String
		match s.fam:
			"lin":
				var u1 := v.sub(s.b)
				undo = "Subtract %s: %s − %s = %s. Divide by %s: %s ÷ %s = %s." % [D(s.b), D(v), D(s.b), D(u1), D(s.m), D(u1), D(s.m), wv(val)]
			"rat":
				var u2 := v.sub(s.c)
				undo = "Subtract %s: %s − %s = %s. Divide %s by it: %s ÷ %s = %s." % [D(s.c), D(v), D(s.c), D(u2), D(s.k), D(s.k), D(u2), wv(val)]
			_:
				var u3 := v.sub(s.a)
				var u4 := u3.div(s.b)
				undo = "Subtract %s: %s − %s = %s. Divide by %s: %s. Raise e to it: e^%s = %s." % [D(s.a), D(v), D(s.a), D(u3), D(s.b), wv(u4), wv(u4), wv(val)]
		steps["undo-in-reverse"] = ["%s %s, so undo the steps in reverse order, starting from %s." % [F, does(s)[0], D(v)], undo, done]
	return pack(lines, asked, ans, wr, fill, steps)


# ── restrict-domain ──────────────────────────────────────────

static func quad_line(s: Dictionary, domain: bool = false) -> String:
	var m := md(s)
	return (m.eq % rhs(s, "x")) + (", for x ≥ %s." % D(s.qh) if domain else ".")


## "−(−6) ÷ (2 × 0.5) = 6": the vertex's x from −b ÷ 2a.
static func vertex_x(s: Dictionary) -> String:
	var co := S.quad_co(s)
	return "x = −b ÷ 2a = −%s ÷ (2 × %s) = %s" % [B(co[1]), B(co[2]), D(s.qh)]


func u_restrict_domain(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m := md(s)
	var F: String = m.f
	var h: Q = s.qh
	var k: Q = s.qk
	var co := S.quad_co(s)
	var ans := num_ans("k = ", h)
	var wr: Array = [num_wrong(Q.new(0), R_Y_INTERCEPT), num_wrong(k, R_VERTEX_Y)]
	var fill: Array = [num_fill(h.neg()), num_fill(h.mul(2))]
	var lines: Array = [quad_line(s)]
	var vertex: String
	if rep == "graph":
		lines.append("The graph of y = %s(x) is shown." % F)
		vertex = "From the graph, the vertex is at %s." % pt(h, k)
	else:
		vertex = "The vertex is at %s." % vertex_x(s)
	var side := "above" if s.qa.sign() > 0 else "below"
	var asked := "Find the least value of k for which %s has an inverse on the domain x ≥ k." % F
	var done := final_step(ans)
	var out := pack(lines, asked, ans, wr, fill, {
		"split-at-vertex": [vertex, "%s is one-to-one on each side of its vertex, and x ≥ %s is the largest domain of the form x ≥ k on one side." % [F, D(h)], done],
		"horizontal-line": [vertex, "A horizontal line just %s the vertex meets the graph twice, once on each side of x = %s; on x ≥ %s every horizontal line meets it at most once, and any smaller k takes in points on both sides." % [side, D(h), D(h)], done]})
	if rep == "graph":
		var hi := h.to_float() * 2.0 + 2.0
		var fn := func(x: float) -> float: return S.fval(s, x)
		var ys: Array = [S.fval(s, 0.0), S.fval(s, hi), k.to_float()]
		var lo_y: float = ys.min()
		var hi_y: float = ys.max()
		var pad := (hi_y - lo_y) * 0.1 + 1.0
		var y0 := floori(minf(lo_y - pad, 0.0))
		var y1 := ceili(maxf(hi_y + pad, 0.0))
		var gr := Plot.spec([Plot.sample(fn, 0.0, hi)], [[0, co[0].to_float(), pt(0, co[0])], [h.to_float(), k.to_float(), pt(h, k)]],
			0, ceili(hi), y0, y1)
		gr.one_colour = true
		out.graph = gr
	return out


# ── inverse-domain-range ─────────────────────────────────────

func u_inverse_domain_range(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m := md(s)
	var F: String = m.f
	var inv := F + "⁻¹"
	var right: String
	var tagged: Array = []
	var plain: Array = []
	var steps: Array = ["The domain of %s is the range of %s, and the range of %s is the domain of %s." % [inv, F, inv, F]]
	var domain: bool = s.want == "domain"
	if s.fam == "quad":
		var h: Q = s.qh
		var k: Q = s.qk
		var up: bool = s.qa.sign() > 0
		var rel := "≥" if up else "≤"
		var flip := "≤" if up else "≥"
		var co := S.quad_co(s)
		if domain:
			right = "x %s %s" % [rel, D(k)]
			tagged = [tag("x ≥ %s" % D(h), R_DOMAIN_OF_F)]
			plain = ["x %s %s" % [flip, D(k)], "x ≥ %s" % D(co[0]), "x %s %s" % [rel, D(h.add(k))]]
			steps.append("On x ≥ %s, %s has its %s value at the vertex, %s(%s) = %s, and %s without bound, so its range is y %s %s." % [
				D(h), F, "least" if up else "greatest", F, D(h), D(k), "rises" if up else "falls", rel, D(k)])
		else:
			right = "%s(x) ≥ %s" % [inv, D(h)]
			plain = ["%s(x) %s %s" % [inv, rel, D(k)], "%s(x) ≤ %s" % [inv, D(h)], "%s(x) ≥ 0" % inv]
			steps.append("The domain of %s is x ≥ %s." % [F, D(h)])
	else:
		var y0 := Q.new(roundi(S.fval(s, float(s.lo)) * 100.0), 100)
		var y1 := Q.new(roundi(S.fval(s, float(s.hi)) * 100.0), 100)
		var lo_y: Q = y0 if y0.lt(y1) else y1
		var hi_y: Q = y1 if y0.lt(y1) else y0
		if domain:
			right = "%s ≤ x ≤ %s" % [D(lo_y), D(hi_y)]
			tagged = [tag("%d ≤ x ≤ %d" % [s.lo, s.hi], R_DOMAIN_OF_F)]
			plain = ["x ≥ %s" % D(lo_y), "%d ≤ x ≤ %s" % [s.lo, D(hi_y)], "%s ≤ x ≤ %s" % [D(lo_y), D(hi_y.add(s.hi))]]
			steps.append("%s is a line, so its range runs between its values at the ends: %s(%d) = %s and %s(%d) = %s, so %s ≤ y ≤ %s." % [
				F, F, s.lo, D(y0), F, s.hi, D(y1), D(lo_y), D(hi_y)])
		else:
			right = "%d ≤ %s(x) ≤ %d" % [s.lo, inv, s.hi]
			plain = ["%s ≤ %s(x) ≤ %s" % [D(lo_y), inv, D(hi_y)], "%d ≤ %s(x) ≤ %s" % [s.lo, inv, D(hi_y)], "%s(x) ≥ %d" % [inv, s.lo]]
			steps.append("The domain of %s is %d ≤ %s ≤ %d." % [F, s.lo, m.v, s.hi])
	steps.append("So the %s of %s is %s." % [s.want, inv, right])
	var line: String = quad_line(s, true) if s.fam == "quad" else m.eq % [rhs(s, m.v), str(s.lo), str(s.hi)]
	return choice_pack([line], "Write down the %s of %s." % [s.want, inv], right, tagged, plain, {"swap-domain-range": steps})


# ── inverse-identity ─────────────────────────────────────────

func u_inverse_identity(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m := md(s)
	var F: String = m.f
	var inv := F + "⁻¹"
	var lines: Array = [m.eq % rhs(s, m.v)]
	var tx := inv_texts(s)
	if s.mode == "compose":
		var v: Q = s.v
		var ans := num_ans("(%s∘%s)(%s) = " % [F, inv, D(v)], v)
		var fi := S.finv(s, v.to_float())
		var wr: Array = [num_wrong(Q.new(1), R_ONE)]
		var fill: Array = [num_fill(S.fval(s, v.to_float())), num_fill(fi)]
		var simplify: String
		if s.fam == "lin":
			simplify = "%s(x) = %s, so %s(%s(x)) = %s × (x − %s)/%s + %s = x − %s + %s = x." % [inv, tx.right, F, inv, D(s.m), D(s.b), D(s.m), D(s.b), D(s.b), D(s.b)]
		else:
			simplify = "%s(x) = %s, so %s(%s(x)) = %s + %s ÷ (%s) = %s + (x − %s) = x." % [inv, tx.right, F, inv, D(s.c), D(s.k), tx.right, D(s.c), D(s.c)]
		var done := final_step(ans)
		return pack(lines, "Write down (%s∘%s)(%s)." % [F, inv, D(v)], ans, wr, fill, {
			"identity-property": ["%s undoes %s, so %s(%s(x)) = x for every x in the domain of %s." % [F, inv, F, inv, inv], done],
			"compose-and-simplify": [simplify, "Check with the number: %s(%s) = %s, and %s(%s) = %s." % [inv, D(v), wv(fi), F, wv(fi), D(v)], done]})
	var b: Q = s.bv
	var exact: Variant = ev([s.b, s.m], b) if s.fam == "lin" else s.c.add(s.k.div(b))
	var ans2 := num_ans("a = ", exact)
	var wr2: Array = [num_wrong(S.finv(s, b.to_float()), R_INV_OF_B)]
	var fill2: Array = [num_fill(b), num_fill(S.fval(s, b.to_float() + 1.0))]
	lines.append("%s(a) = %s, where a is a constant." % [inv, D(b)])
	var sub := "%s(%s) = %s = %s" % [F, D(b), pnum([s.b, s.m], b) if s.fam == "lin" else "%s + %s ÷ %s" % [D(s.c), D(s.k), D(b)], wv(exact)]
	var done2 := final_step(ans2)
	return pack(lines, "Find a.", ans2, wr2, fill2, {
		"identity-property": ["%s(a) = %s means %s takes a to %s, so %s takes %s back to a." % [inv, D(b), inv, D(b), F, D(b)], "a = " + sub + ".", done2],
		"compose-and-simplify": ["Apply %s to both sides of %s(a) = %s: %s(%s(a)) = %s(%s)." % [F, inv, D(b), F, inv, F, D(b)],
			"%s∘%s leaves its input unchanged, so a = %s." % [F, inv, sub], done2]})


# ── inverse-graph ────────────────────────────────────────────

func u_inverse_graph(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var cs: Dictionary = s.curve
	var pts := BasicOneToOneSituation.points(cs)
	var keys: Array = cs.keys.filter(func(k): return absi(k[0]) <= 8 and absi(k[1]) <= 8)
	# The working swaps two key points off y = x first, so the swap shows.
	var off: Array = keys.filter(func(k): return k[0] != k[1])
	var on: Array = keys.filter(func(k): return k[0] == k[1])
	var named: Array = off + on
	var card := func(fx: Callable) -> Dictionary:
		var g := GdcKit.card([pts.map(func(p): return fx.call(p))], keys.map(func(k): var c: Array = fx.call(k); return [c[0], c[1], ""]), BasicOneToOneSituation.WIN)
		g.one_colour = true
		return g
	var wrongs := [
		{"graph": card.call(func(p): return [p[0], -p[1]]), "ref": R_AXIS, "mistake": "x-axis", "why": "this reflects f in the x-axis, not in y = x"},
		{"graph": card.call(func(p): return [-p[0], p[1]]), "ref": R_AXIS, "mistake": "y-axis", "why": "this reflects f in the y-axis, not in y = x"},
		{"graph": card.call(func(p): return [-p[1], -p[0]]), "ref": "", "mistake": "y=-x", "why": "this reflects f in y = −x, so each point also changes sign"},
	]
	var picked := GdcKit.pick(card.call(func(p): return [p[1], p[0]]), wrongs, rng)
	var ans: Dictionary = picked.answer
	var a: Array = named[0]
	var b: Array = named[1]
	var swap := "The points %s and %s are on f, so %s and %s are on f⁻¹." % [Fmt.point(a[0], a[1]), Fmt.point(b[0], b[1]), Fmt.point(a[1], a[0]), Fmt.point(b[1], b[0])]
	var last := "So %s: the graph through the swapped points." % picked.letter
	var rule := BasicOneToOneViews.eqn(cs)
	var gdc_rule := BasicFunctionSituation.text(cs.f, "X") + (", for X ≥ %s" % D(cs.lo) if cs.get("form", "") == "half" else "")
	var plot := BasicOneToOneViews.plot(cs, keys.map(func(k): return BasicOneToOneViews.dot(k[0], k[1])))
	var out := {"asked": "Which graph shows y = f⁻¹(x)?", "lines": [rule, "The graph of y = f(x) is shown, with its key points marked."],
		"graph": plot, "answer": ans, "graphs": picked.graphs, "wrongs": [], "table": null}
	out.methods = {
		"reflect-in-y-equals-x": method(["f⁻¹ is the reflection of f in the line y = x, so each point's coordinates swap.", swap, last], ans.values),
		"gdc-inverse-draw": method(["Enter Y1 = %s on the GDC and use its draw-inverse tool." % gdc_rule,
			"The inverse it draws passes through %s and %s, the key points of f with their coordinates swapped." % [Fmt.point(a[1], a[0]), Fmt.point(b[1], b[0])], last], ans.values),
	}
	return out
