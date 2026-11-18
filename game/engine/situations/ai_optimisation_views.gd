class_name AiOptimisationViews
extends OptimisationViews
## The views on the `ai-optimisation` situation (FAL-1000): one builder per unknown of
## t5-ai-optimisation (AI-SL5.7). Every question is Paper 2, as every AI paper allows a GDC.
##
## A given model (a quadratic or cubic profit, a cost with a term in 1/x, or an angle model that
## only the GDC optimises): the best input, the optimum, why a suggested input is not optimal,
## and the best whole number of items. A price and the demand it gives: the best price or the
## greatest profit. The optimisation-model shapes (OptimisationSituation, the AA type's: a can,
## an open bin, a tray from a sheet, a pen or a paddock against a wall, a route off a road),
## written with OptimisationViews' stories, figures and lines: the second length from the
## constraint, the function in one variable, the best length, the optimum, the other length,
## the route's best point or least value, and the domain in context.
##
## Representations: "words" (a story), "equation" (the model first, one line on what it is),
## "diagram" (OptimisationViews' figure) and "table" (the model's values at whole numbers).
## `given` is the situation, for the SymPy checker, which reads every number from the text.

const G := "AI-SL5.7.optimise-given-model#"
const B := "AI-SL5.7.build-model-from-constraint#"
const C := "AI-SL5.7.optimise-container#"
const I := "AI-SL5.7.interpret-optimum-in-context#"
const OWN := "t5-ai-optimisation#"
const R_X_VALUE := G + "0"
const R_REVENUE := G + "1"
const R_OTHER_SP := G + "2"
const R_ONE_CUT_AI := B + "0"
const R_HALF_SIDE := B + "1"
const R_LID_AI := B + "2"
const R_ZERO_ROOT := C + "0"
const R_ROUND_FIRST := C + "1"
const R_STOP_R := C + "2"
const R_NEAREST := I + "0"
const R_NEG_LEN := I + "1"
const R_NO_UNIT_COST := OWN + "11"
const R_GRAD_PROFIT := OWN + "12"
const R_POSITIVE := OWN + "13"
const R_CLOSED := OWN + "14"
const R_ONE_SPEED := OWN + "15"
const R_BOX_LID := OWN + "16"
const R_CIRCUMFERENCE := OWN + "17"
const R_WALL_TOO := OWN + "18"
const R_SUM_AREA := OWN + "19"

const UNKNOWNS := ["optimal-input-given-model", "optimum-value-given-model", "profit-from-revenue-cost",
	"suggested-not-optimal", "constraint-second-length", "objective-one-variable", "container-optimal-dimension",
	"container-optimum-value", "container-other-dimension", "route-least-time", "whole-number-optimum", "context-domain"]

## The stories of a given model: the words' first line, the line before the model, the
## equation's one-line intro, and the unit of x.
const QUAD_PROFIT := [
	{"line": "A brewer in the ruins sells cactus beer at x scrap a jug.", "model": "Her weekly profit, P scrap, is modelled by",
		"intro": "The weekly profit, P scrap, from selling cactus beer at x scrap a jug is", "unit": " scrap"},
	{"line": "A smith charges x scrap to sharpen a blade.", "model": "His weekly profit, P scrap, is modelled by",
		"intro": "The weekly profit, P scrap, of a smith who charges x scrap a blade is", "unit": " scrap"},
	{"line": "A salvage crew sells copper wire at x scrap a metre.", "model": "Its daily profit, P scrap, is modelled by",
		"intro": "The daily profit, P scrap, from selling copper wire at x scrap a metre is", "unit": " scrap"},
]
const COST := [
	{"line": "A convoy crosses the salt flats at a steady x km/h.", "model": "The cost of the crossing, C scrap, is modelled by",
		"intro": "The cost, C scrap, of crossing the salt flats at x km/h is", "unit": " km/h"},
	{"line": "A pump lifts water from a deep well at x litres a minute.", "model": "The daily cost of running it, C scrap, is modelled by",
		"intro": "The daily cost, C scrap, of pumping water at x litres a minute is", "unit": " litres a minute"},
	{"line": "A kiln is fed x kg of charcoal an hour.", "model": "The cost of a firing, C scrap, is modelled by",
		"intro": "The cost, C scrap, of a firing fed x kg of charcoal an hour is", "unit": " kg an hour"},
]
const CUBIC := [
	{"line": "A workshop melts down x tonnes of scrap steel a week.", "model": "Its weekly profit, P scrap, is modelled by",
		"intro": "The weekly profit, P scrap, from melting down x tonnes of scrap steel is", "unit": " tonnes"},
	{"line": "A refinery cleans x hundred litres of old fuel a week.", "model": "Its weekly profit, P scrap, is modelled by",
		"intro": "The weekly profit, P scrap, from cleaning x hundred litres of old fuel is", "unit": " hundred litres"},
	{"line": "A seed bank sorts x kg of wild seed a day.", "model": "Its daily profit, P scrap, is modelled by",
		"intro": "The daily profit, P scrap, from sorting x kg of wild seed is", "unit": " kg"},
]
const CHANNEL := ["water channel", "rain gutter", "feeding trough"]
const WHOLE_COST := [
	["A camp flies x guard drones, where x is a whole number.", "The daily cost, C scrap, of running them and of what raiders take is modelled by"],
	["A caravan hires x outriders, where x is a whole number.", "The cost of a trip, C scrap, in their pay and in goods lost, is modelled by"],
	["A well is worked by x pumps, where x is a whole number.", "The daily cost, C scrap, of running them and of the water lost is modelled by"],
]
const WHOLE_PROFIT := [
	["A salvage boss sends out x crews a day, where x is a whole number.", "Her daily profit, P scrap, is modelled by"],
	["A market runs x food stalls, where x is a whole number.", "Its daily profit, P scrap, is modelled by"],
	["A ferry makes x river crossings a day, where x is a whole number.", "Its daily profit, P scrap, is modelled by"],
]
## [who, the goods, one of them, how often, what has a fixed cost].
const DEMAND := [
	["A trader", "water filters", "filter", "a week", "her stall"],
	["A cobbler", "pairs of boots", "pair", "a week", "his workshop"],
	["A tinker", "lamps", "lamp", "a month", "her cart"],
]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func need(unknown: String, rep: String) -> Dictionary:
	var n: Dictionary = needs()[unknown].duplicate()
	n.rep = rep
	return n


## Every AI paper allows a GDC: every cell is Paper 2.
func papers(unknown: String, _rep: String, _method_id: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = AiOptimisationSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func dec(v: Variant) -> String:
	return Fmt.dec(v)


## A coefficient in front of x: "" for 1, else its decimal.
static func lin(v: Q) -> String:
	return "" if v.eq(1) else Fmt.dec(v)


static func S3(v: float) -> String:
	return Fmt.sf(v)


## An answer to 3 s.f. (with the rounding trap).
static func sf_ans(label: String, x: float, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": GdcKit.qf(x)}, {}, label, unit)
	ans.show = "sf"
	return ans


## An exact answer, as a decimal.
static func ex_ans(label: String, v: Q, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label, unit)
	ans.show = "dec"
	ans.exact = true
	return ans


## A wrong value in the answer's shape.
static func lk(ans: Dictionary, v: Variant, ref: String = "") -> Dictionary:
	return wrong({"v": v if v is Q else GdcKit.qf(v)}, ref)


static func lks(ans: Dictionary, vs: Array) -> Array:
	return vs.map(func(v): return lk(ans, v).values)


## Plain wrong values from the answer: multiples of it.
static func multiples(ans: Dictionary, v: Variant) -> Array:
	var out: Array = []
	for f in [[2, 1], [1, 2], [3, 2], [2, 3], [3, 1]]:
		out.append(lk(ans, v.mul(Q.new(f[0], f[1])) if v is Q else v * f[0] / f[1]).values)
	return out


static func fin(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## A number the GDC shows: exact where it ends in a few places, else to 6 s.f.
static func shown(v: Variant) -> String:
	if v is Q:
		var t := Fmt.dec(v)
		if not t.contains("/") and t.length() <= 9:
			return t
		return W(v.to_float())
	return W(v)


# ── A given model ────────────────────────────────────────────

static func fname(s: Dictionary) -> String:
	if s.kind == "angle":
		return "A"
	return "P" if s.big else "C"


static func var_(s: Dictionary) -> String:
	return "θ" if s.kind == "angle" else "x"


## The model's right-hand side, in letter.
static func rhs(s: Dictionary, letter: String = "") -> String:
	var v := letter if letter != "" else var_(s)
	match s.kind:
		"quad", "cubic":
			return Fmt.terms(s.terms.map(func(t): return t[0]), s.terms.map(func(t): return t[1]), v, true)
		"recip":
			if s.big:
				return "%s − %s%s − %s/%s" % [dec(s.c), lin(s.a), v, dec(s.b), v]
			return "%s%s + %s/%s%s" % [lin(s.a), v, dec(s.b), v, "" if s.c.is_zero() else " + " + dec(s.c)]
		"angle":
			return "%s sin %s (%s + %s cos %s)" % [dec(s.k), v, dec(s.w), dec(s.k), v]
	return ""


static func model_text(s: Dictionary) -> String:
	return "%s(%s) = %s" % [fname(s), var_(s), rhs(s)]


static func dom_text(s: Dictionary) -> String:
	if s.ask == "whole-number-optimum":
		return "for whole numbers x from 1 to %d" % s.X
	match s.kind:
		"quad", "cubic":
			return "for 0 ≤ x ≤ %d" % s.X
		"angle":
			return "for 0° < θ < 90°"
	return "for x > 0"


static func dname(s: Dictionary) -> String:
	return fname(s) + "′"


static func deriv_rhs(s: Dictionary) -> String:
	if s.kind == "recip":
		if s.big:
			return "%s/x² − %s" % [dec(s.b), dec(s.a)]
		return "%s − %s/x²" % [dec(s.a), dec(s.b)]
	var ts: Array = s.terms.filter(func(t): return t[1] > 0)
	return Fmt.terms(ts.map(func(t): return t[0].mul(t[1])), ts.map(func(t): return t[1] - 1), "x", true)


static func deriv_text(s: Dictionary) -> String:
	return "%s(x) = %s" % [dname(s), deriv_rhs(s)]


static func story(s: Dictionary) -> Dictionary:
	match s.kind:
		"quad":
			return QUAD_PROFIT[s.ctx] if s.big else COST[s.ctx]
		"cubic":
			return CUBIC[s.ctx]
		"recip":
			return COST[s.ctx]
	var c: String = CHANNEL[s.ctx]
	return {"line": "A %s has a flat base %s m wide and two sides %s m long, each at θ° to the horizontal." % [c, dec(s.w), dec(s.k)],
		"model": "The area of its cross-section, A m², is", "intro": "The cross-section area, A m², of a %s with its sides at θ° to the horizontal is" % c, "unit": "°"}


func model_lines(rep: String, s: Dictionary) -> Array:
	var st := story(s)
	var line := "%s, %s." % [model_text(s), dom_text(s)]
	if rep == "equation":
		return [st.intro, line]
	return [st.line, st.model, line]


static func word_of(s: Dictionary) -> String:
	return "maximum" if s.big else "minimum"


static func what(s: Dictionary) -> String:
	if s.kind == "angle":
		return "the greatest cross-section area"
	return "the greatest profit" if s.big else "the least cost"


static func value_unit(s: Dictionary) -> String:
	return " m²" if s.kind == "angle" else " scrap"


static func x_label(s: Dictionary) -> String:
	return var_(s) + " = "


## The derivative's sign either side of x: the whole numbers below and above it.
static func sign_line(s: Dictionary) -> String:
	var d := dname(s)
	var change := "positive, then negative" if s.big else "negative, then positive"
	return "%s(%s) = %s and %s(%s) = %s: %s, so this is a %s." % [d, dec(Q.new(int(s.lo))), S3(s.dlo), d, dec(Q.new(int(s.hi))), S3(s.dhi), change, word_of(s)]


## dP/dx = 0, solved: one line, or two for a cubic.
static func solve_given(s: Dictionary) -> Array:
	var d := dname(s)
	match s.kind:
		"quad":
			var a: Q = s.terms[0][0]
			var b: Q = s.terms[1][0]
			return ["%s(x) = 0: %s = 0, so x = %s ÷ %s = %s." % [d, deriv_rhs(s), dec(b.abs_q()), dec(a.mul(2).abs_q()), W(s.x)]]
		"cubic":
			return ["%s(x) = 0 is a quadratic equation; the GDC's solver gives x = %s and x = %s." % [d, W(s.other), W(s.x)],
				"%s(%s) = %s and %s(%s) = %s: positive, then negative, so x = %s is the maximum, and x = %s is a local minimum." % [d, dec(Q.new(int(s.lo))), S3(s.dlo), d, dec(Q.new(int(s.hi))), S3(s.dhi), W(s.x), W(s.other)]]
		"recip":
			var r: Q = s.b.div(s.a)
			return ["%s(x) = 0: x² = %s ÷ %s = %s, so x = %s, as x > 0." % [d, dec(s.b), dec(s.a), shown(r), W(s.x)]]
	return []


static func value_line(s: Dictionary) -> String:
	return "%s(%s) = %s." % [fname(s), W(s.x), W(s.best)]


static func gdc_lines(s: Dictionary, value: bool) -> Array:
	var read := "x = %s, y = %s" % [W(s.x), W(s.best)] if value else "x = %s" % W(s.x)
	if s.kind == "angle":
		return ["Set the GDC to degrees and graph y = %s, for 0 < x < 90." % rhs(s, "x"),
			"The maximum tool gives %s." % read]
	var where := "for 0 ≤ x ≤ %d" % s.X if s.X > 0 else "for x > 0"
	return ["Graph y = %s on the GDC, %s." % [rhs(s, "x"), where], "The %s tool gives %s." % [word_of(s), read]]


static func vertex_lines(s: Dictionary) -> Array:
	var a: Q = s.terms[0][0]
	var b: Q = s.terms[1][0]
	var opens := "a = %s < 0, so its vertex is the maximum" % dec(a) if s.big else "a = %s > 0, so its vertex is the minimum" % dec(a)
	return ["%s(x) is a quadratic with %s." % [fname(s), opens],
		"x = −b/(2a) = −%s ÷ (2 × %s) = %s." % [P(b), P(a), W(s.x)]]


func _given_methods(s: Dictionary, ans: Dictionary, value: bool) -> Dictionary:
	var ms := {}
	if s.kind != "angle":
		var steps: Array = ["%s." % deriv_text(s)]
		steps += solve_given(s)
		if s.kind != "cubic":
			steps.append(sign_line(s))
		if value:
			steps.append(value_line(s))
		steps.append(fin(ans))
		ms["derivative-zero"] = method(steps, ans.values)
	ms["gdc-maximum"] = method(gdc_lines(s, value) + [fin(ans)], ans.values)
	# A cubic, reciprocal or angle model has no vertex formula (the catalogue's weak "fails").
	if s.kind == "quad":
		var vs := vertex_lines(s)
		if value:
			vs.append(value_line(s))
		ms["vertex-of-quadratic-model"] = method(vs + [fin(ans)], ans.values)
	return ms


func u_optimal_input_given_model(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var unit: String = story(s).unit
	var ans := sf_ans(x_label(s), s.x, unit)
	var ws: Array = []
	if s.kind == "cubic":
		ws.append(lk(ans, s.other, R_OTHER_SP))
	var fill: Array = lks(ans, [90.0 - s.x, 45.0, s.x / 2.0]) if s.kind == "angle" else multiples(ans, s.x)
	return {"lines": model_lines(rep, s), "asked": "Find the value of %s that gives %s." % [var_(s), what(s)],
		"answer": ans, "wrongs": ws, "fillers": fill, "methods": _given_methods(s, ans, false)}


func u_optimum_value_given_model(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var unit: String = story(s).unit
	var ans := sf_ans(fname(s) + " = ", s.best, value_unit(s))
	var ws: Array = [lk(ans, s.x, R_X_VALUE)]
	if s.kind == "cubic":
		ws.append(lk(ans, s.other_best, R_OTHER_SP))
	return {"lines": model_lines(rep, s), "asked": "Find %s." % what(s),
		"answer": ans, "wrongs": ws, "fillers": multiples(ans, s.best), "methods": _given_methods(s, ans, true)}


# ── A suggested value ────────────────────────────────────────

func u_suggested_not_optimal(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var lines := model_lines(rep, s)
	var p0 := dec(Q.new(s.p0))
	lines.append("It is suggested that x = %s gives the greatest profit." % p0)
	var d := "P′(%s) = %s" % [p0, dec(s.d0)]
	var at := "P(%s) = %s" % [p0, dec(s.v0)]
	var best := S3(s.x)
	var right := "%s ≠ 0, so P is not at its maximum at x = %s; the maximum is at x = %s" % [d, p0, best]
	var up: bool = s.d0.sign() > 0
	var built := DerivativeMeaningViews.claim_split(right, [
		["The profit at x = %s is %s scrap, so it is not the greatest profit" % [p0, d], R_GRAD_PROFIT],
		["%s > 0, so x = %s gives the greatest profit" % [at, p0], R_POSITIVE],
		["%s %s 0, so P is %s at x = %s; the maximum is at a %s value of x" % [d, ">" if up else "<", "decreasing" if up else "increasing", p0, "smaller" if up else "larger"], ""],
		["%s ≠ 0, so x = %s gives the least profit" % [d, p0], ""],
	])
	var ans: Dictionary = built.answer
	var dir := "positive" if up else "negative"
	var ms := {
		"derivative-zero": method(["%s." % deriv_text(s), "At x = %s: %s, which is %s, not 0, so P is still %s there." % [p0, d, dir, "rising" if up else "falling"],
			"%s(x) = 0 at x = %s, where %s changes from positive to negative: the maximum." % [dname(s), W(s.x), dname(s)], fin(ans)], ans.values),
		"gdc-maximum": method(["Graph y = %s on the GDC, for 0 ≤ x ≤ %d." % [rhs(s, "x"), s.X],
			"The maximum tool gives x = %s, not %s, and the gradient tool at x = %s gives dy/dx = %s." % [W(s.x), p0, p0, dec(s.d0)], fin(ans)], ans.values),
	}
	return {"lines": lines, "asked": "Which statement explains why x = %s does not give the greatest profit?" % p0,
		"answer": ans, "wrongs": built.wrongs, "fillers": built.fillers, "methods": ms}


# ── Whole items ──────────────────────────────────────────────

static func whole_story(s: Dictionary) -> Array:
	return WHOLE_PROFIT[s.ctx] if s.big else WHOLE_COST[s.ctx]


func u_whole_number_optimum(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var st := whole_story(s)
	var n: int = s.n
	var lines: Array = [st[0], st[1], "%s, %s." % [model_text(s), dom_text(s)]]
	var out := {"lines": lines}
	var xs: Array = [n - 1, n, n + 1, n + 2]
	var vals: Array = xs.map(func(x): return AiOptimisationSituation.exact(s, Q.new(x)))
	if rep == "table":
		lines.append("The table shows some of its values.")
		out.table = {"rows": [["x"] + xs.map(func(x): return str(x)), ["%s(x)" % fname(s)] + vals.map(func(v): return shown(v))]}
	var ans := ex_ans(fname(s) + " = ", s.at_up, " scrap")
	var f := fname(s)
	var better := "larger" if s.big else "smaller"
	out.asked = "Find %s." % what(s)
	out.answer = ans
	out.wrongs = [lk(ans, s.at_n, R_NEAREST), lk(ans, Q.new(n + 1), R_X_VALUE)]
	var fill: Array = [lk(ans, Q.new(roundi(s.best * 10.0), 10)).values]
	for v in [vals[0], vals[3]]:
		if not Fmt.dec(v).contains("/"):
			fill.append(lk(ans, v).values)
	out.fillers = fill
	out.methods = {
		"test-neighbouring-integers": method([
			"%s(x) = 0: x² = %s ÷ %s, so x = %s, which is not a whole number." % [dname(s), dec(s.b), dec(s.a), W(s.x)],
			"Test the whole numbers either side: %s(%d) = %s and %s(%d) = %s." % [f, n, shown(s.at_n), f, n + 1, shown(s.at_up)],
			"%s(%d) is the %s, so the best whole number is x = %d, not %d, the nearest whole number to %s." % [f, n + 1, better, n + 1, n, W(s.x)],
			fin(ans)], ans.values),
		"gdc-table": method([
			"Enter y = %s in the GDC's table, starting at x = 1, in steps of 1." % rhs(s, "x"),
			"Near the %s it shows %s." % [word_of(s), ", ".join(range(4).map(func(i): return "%s(%d) = %s" % [f, xs[i], shown(vals[i])]))],
			"The %s value in the column is at x = %d." % ["largest" if s.big else "smallest", n + 1], fin(ans)], ans.values),
	}
	return out


# ── A price and its demand ───────────────────────────────────

static func demand_text(s: Dictionary) -> String:
	return "%d − %dp" % [s.A, s.B]


static func profit_text(s: Dictionary) -> String:
	return "P(p) = (p − %d)(%s) − %d" % [s.cost, demand_text(s), s.F]


static func profit_poly(s: Dictionary) -> String:
	return Fmt.terms([Q.new(-s.B), Q.new(s.A + s.B * s.cost), Q.new(-(s.A * s.cost + s.F))], [2, 1, 0], "p", true)


func u_profit_from_revenue_cost(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Array = DEMAND[s.ctx]
	var lines: Array = ["%s sells %s at p scrap each. At that price, %s %s are sold %s." % [c[0], c[1], demand_text(s), c[1], c[3]],
		"Each %s costs %d scrap to make, and %s costs %d scrap %s." % [c[2], s.cost, c[4], s.F, c[3]]]
	var price: bool = s.target == "price"
	var ans := ex_ans("p = ", s.x, " scrap") if price else ex_ans("P = ", s.best, " scrap")
	var ws: Array = []
	var fill: Array = []
	if price:
		ws.append(lk(ans, Q.new(s.r), R_REVENUE))
		fill = [lk(ans, Q.new(s.cost)).values, lk(ans, Q.new(s.A, s.B)).values, lk(ans, s.x.add(s.cost)).values, lk(ans, s.x.mul(2)).values]
	else:
		ws = [lk(ans, s.revenue, R_REVENUE), lk(ans, s.no_cost, R_NO_UNIT_COST)]
		fill = [lk(ans, s.x).values] + multiples(ans, s.best)
	var top: Q = Q.new(s.A, s.B)
	var pline := "%s, where profit = (price − cost of one) × number sold − fixed cost." % profit_text(s)
	var dz: Array = ["%s = %s." % [profit_text(s), profit_poly(s)],
		"P′(p) = %s = 0, so p = %s ÷ %d = %s." % [Fmt.terms([Q.new(-2 * s.B), Q.new(s.A + s.B * s.cost)], [1, 0], "p", true), dec(Q.new(s.A + s.B * s.cost)), 2 * s.B, dec(s.x)],
		"P′(p) is positive below p = %s and negative above it, so this is the maximum." % dec(s.x)]
	var gd: Array = [pline, "Graph it on the GDC, for %d ≤ p ≤ %s, where the demand is not negative." % [s.cost, dec(top)],
		"The maximum tool gives p = %s, P = %s." % [dec(s.x), dec(s.best)]]
	if not price:
		dz.append("P(%s) = %s." % [dec(s.x), dec(s.best)])
	return {"lines": lines, "asked": ("Find the price that gives the greatest profit." if price else "Find the greatest possible profit %s." % c[3]),
		"answer": ans, "wrongs": ws, "fillers": fill,
		"methods": {"derivative-zero": method(dz + [fin(ans)], ans.values), "gdc-maximum": method(gd + [fin(ans)], ans.values)}}


# ── A second length from the constraint ──────────────────────

## The AA builder's wrong options on this type: a slip that means the same keeps an AI ref,
## the rest become fillers.
static func retag(out: Dictionary, map: Dictionary) -> void:
	var ws: Array = []
	var fill: Array = []
	for w in out.wrongs:
		var ref: String = map.get(w.ref, "")
		if ref != "":
			ws.append(wrong(w.values, ref))
		else:
			fill.append(w.values)
	out.wrongs = ws
	out.fillers = fill + out.get("fillers", [])


func _constraint_label(s: Dictionary) -> Array:
	match s.fam:
		"pen":
			return ["Label the diagram: the %d sections at right angles to the wall are x m each, and the one along the wall is y m." % s.n,
				"The fence adds up to %d m: %dx + y = %d." % [s.F, s.n, s.F]]
		"paddock":
			return ["Label the plot x m from the wall and y m along it.", "Its area is length × width: xy = %d." % s.P]
		"can":
			return ["Label the radius r and the height h on the cylinder.", "The volume is the area of the base, πr², times the height: πr²h = %d." % s.V]
	return ["Label the square base x by x, and each of the 4 side faces x by h; there is no lid.",
		"The faces' areas add up to the metal used: x² + 4xh = %d." % s.P]


func u_constraint_second_length(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := u_constraint_rearrange(rep, s, rng)
	retag(out, {R_LID: R_BOX_LID, R_CIRC: R_CIRCUMFERENCE, R_WALL: R_WALL_TOO, R_AREA_SUM: R_SUM_AREA})
	var ans: Dictionary = out.answer
	var sub: Dictionary = out.methods["constraint-substitution"]
	out.methods = {"substitute-constraint": sub, "label-the-diagram": method(_constraint_label(s) + [say(ans)], ans.values)}
	return out


# ── The function in one variable ─────────────────────────────

func _objective_label(s: Dictionary) -> Array:
	match s.fam:
		"pen":
			return ["Label the diagram: %d sections of x m at right angles to the wall, and y m along it." % s.n,
				"The fence gives %dx + y = %d, so y = %d − %sx, and the area is A = xy." % [s.n, s.F, s.F, Fmt.lead(s.n)],
				"A = x(%d − %sx) = %dx − %sx²." % [s.F, Fmt.lead(s.n), s.F, Fmt.lead(s.n)]]
		"paddock":
			return ["Label the plot x m from the wall and y m along it: the fence is L = %sx + y." % Fmt.lead(s.n),
				"Its area gives xy = %d, so y = %d/x." % [s.P, s.P], "L = %sx + %d/x." % [Fmt.lead(s.n), s.P]]
		"can":
			var o := obj(s)
			var flat := "%sπr²" % Fmt.lead(s.e)
			var ends := "the two flat ends" if s.ends == 2 else "the base"
			var rate := "" if not s.cost else ", each m² of it costing %d scrap" % s.rate_end
			return ["Label r and h: %s give %s%s, and the curved side, a rectangle 2πr by h, gives 2πrh." % [ends, flat, rate],
				"The volume gives πr²h = %d, so h = %d/(πr²)." % [s.V, s.V], "%s = %s + 2πr × %d/(πr²) = %s + %d/r, where %d/r is the term in 1/r." % [o, flat, s.V, flat, 2 * s.V, 2 * s.V]]
		"bin":
			return ["Label the base x by x and each of the 4 side faces x by h; there is no lid.",
				"The metal gives x² + 4xh = %d, so h = (%d − x²)/(4x)." % [s.P, s.P], "V = x²h = x²(%d − x²)/(4x) = (%dx − x³)/4." % [s.P, s.P]]
	return ["Label the diagram: after the corners are cut out, the base is (%d − 2x) cm by (%d − 2x) cm." % [s.w, s.h],
		"Folding up the sides makes the tray x cm deep, and its volume is length × width × height."]


func u_objective_one_variable(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary
	var sub: Array
	if s.fam == "box":
		out = u_build_objective(rep, s, rng)
		out.erase("titles")
		retag(out, {R_ONE_CUT: R_ONE_CUT_AI})
		sub = ["The sheet is %d cm by %d cm, and a square of side x cm comes off each end of each side: the base is (%d − 2x) by (%d − 2x)." % [s.w, s.h, s.w, s.h],
			"The height is x, so substitute the three lengths into V = length × width × height."]
	else:
		out = u_show_objective(rep, s, rng)
		var map := {R_SIDE: R_HALF_SIDE}
		# Two flat ends on a can with no lid: a lid counted. One on a closed can is no AI slip.
		if s.fam == "can" and s.ends == 1:
			map[R_ENDS] = R_LID_AI
		retag(out, map)
		sub = out.methods["constraint-substitution"].steps.slice(0, -1)
	var ans: Dictionary = out.answer
	out.methods = {"substitute-constraint": method(sub + [fin(ans)], ans.values),
		"label-the-diagram": method(_objective_label(s) + [fin(ans)], ans.values)}
	return out


# ── The best length, the optimum, the other length ───────────

## The objective as this type writes it: a bin's as (Px − x³)/4, the rest as the AA type does.
static func obj_text(s: Dictionary) -> String:
	if s.fam == "bin":
		return "V = (%dx − x³)/4" % s.P
	return f_text(s)


static func d_shape(s: Dictionary) -> String:
	if s.fam == "bin":
		return "dV/dx = (%d − 3x²)/4" % s.P
	return d_text(s)


## Its domain, with a tray's end as a decimal.
static func dom_shape(s: Dictionary) -> String:
	if s.fam == "box":
		return "for 0 < x < %s" % dec(Q.new(mini(s.w, s.h), 2))
	return domain(s)


## The objective in the free length alone, from the constraint or the sheet.
static func build_line(s: Dictionary) -> String:
	match s.fam:
		"box":
			return "The base is (%d − 2x) by (%d − 2x) and the height x, so V = x(%d − 2x)(%d − 2x) = %s." % [s.w, s.h, s.w, s.h, show(OptimisationSituation.terms(s), "x")]
		"can":
			return "%s = %sπr² + 2πrh, and h = %d/(πr²), so the curved side 2πrh is %d/r, the term in 1/r: %s." % [obj(s), Fmt.lead(s.e), s.V, 2 * s.V, f_text(s)]
		"bin":
			return "V = x²h, and x² + 4xh = %d gives h = (%d − x²)/(4x), so %s." % [s.P, s.P, obj_text(s)]
	return _one_variable_line(s)


## dO/dx = 0, solved, in one line (two for the tray, which has a root to reject).
static func solve_shape(s: Dictionary) -> Array:
	var x_ := W(s.x)
	match s.fam:
		"paddock":
			return ["%s = 0: x² = %d ÷ %d, so x = %s, as x > 0." % [d_text(s), s.P, s.n, x_]]
		"can":
			return ["%s = 0: r³ = %d ÷ (%dπ), so r = %s." % [d_text(s), s.V, s.e, x_]]
		"bin":
			return ["%s = 0: x² = %d ÷ 3, so x = %s, as x > 0." % [d_shape(s), s.P, x_]]
	return ["%s = 0 has the roots x = %s and x = %s." % [d_text(s), x_, W(s.other)],
		"The shorter side is %d cm, so x < %s and x = %s." % [mini(s.w, s.h), dec(Q.new(mini(s.w, s.h), 2)), x_]]


static func shape_sign(s: Dictionary) -> String:
	var change := "positive, then negative" if s.big else "negative, then positive"
	return "%s = %s at %s = %s and %s at %s = %s: %s, so this is a %s." % [d_name(s), S3(s.dlo), vr(s), W(s.lo), S3(s.dhi), vr(s), W(s.hi), change, word(s)]


static func shape_gdc(s: Dictionary, value: bool) -> String:
	var read := "%s = %s, %s = %s" % [vr(s), W(s.x), obj(s), W(s.best)] if value else "%s = %s" % [vr(s), W(s.x)]
	return "Graph %s on the GDC, %s: the %s tool gives %s." % [obj_text(s), dom_shape(s), word(s), read]


## What the shape's best length gives.
static func goal(s: Dictionary) -> String:
	match s.fam:
		"paddock":
			return "the least length of fence"
		"can":
			return "the least cost" if s.cost else "the least surface area"
	return "the greatest volume"


func u_container_optimal_dimension(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := setup(rep, s)
	if s.fam != "box":
		out.lines = out.lines + [name_line(s)]
	var v := vr(s)
	out.asked = "Find the value of %s that gives %s." % [v, goal(s)]
	var ans := sf_ans(v + " = ", s.x, " " + unit(s))
	var ws: Array = []
	match s.fam:
		"box":
			var short := mini(s.w, s.h)
			ws = [lk(ans, 2.0 * s.x, R_ONE_CUT_AI), lk(ans, Q.new(short, 2), R_ZERO_ROOT), lk(ans, s.other, R_NEG_LEN)]
		"bin":
			ws = [lk(ans, sqrt(s.P / 6.0), R_BOX_LID)]
		"can":
			ws = [lk(ans, pow(s.V / (2.0 * s.e * PI), 1.0 / 3.0), R_HALF_SIDE)]
			if s.ends == 1:
				ws.append(lk(ans, pow(s.V / (2.0 * s.rate_end * PI), 1.0 / 3.0), R_LID_AI))
	out.answer = ans
	# A slip is offered only where it reads clearly at 3 s.f.
	out.wrongs = ws.filter(func(wr): return AiOptimisationSituation.clear(wr.values.v.to_float()))
	out.fillers = [lk(ans, _no_root(s)).values] + multiples(ans, s.x)
	if s.fam == "bin":
		out.fillers.push_front(lk(ans, sqrt(float(s.P))).values)
	var calc: Array = [build_line(s)] + solve_shape(s) + [shape_sign(s), fin(ans)]
	out.methods = {"calculus-route": method(calc, ans.values),
		"gdc-graph-route": method([build_line(s), shape_gdc(s, false), fin(ans)], ans.values)}
	return out


func u_container_optimum_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := setup(rep, s)
	out.lines = out.lines + ["%s, %s." % [obj_text(s), dom_shape(s)]]
	var o := obj(s)
	out.asked = "Find the %s value of %s." % [word(s), o]
	var ans := sf_ans(o + " = ", s.best, value_tail(s))
	var ws: Array = [lk(ans, s.x, R_STOP_R if s.fam == "can" else R_X_VALUE)]
	out.answer = ans
	out.wrongs = ws
	out.fillers = multiples(ans, s.best)
	var steps: Array = solve_shape(s)
	steps.append(shape_sign(s))
	steps.append(_sub_line(s))
	steps.append(fin(ans))
	out.methods = {"calculus-route": method(steps, ans.values), "gdc-graph-route": method([shape_gdc(s, true), fin(ans)], ans.values)}
	return out


func u_container_other_dimension(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := setup(rep, s)
	out.lines = out.lines + [name_line(s)]
	var w := second(s)
	out.asked = "Find the value of %s that gives %s." % [w, goal(s)]
	var ans := sf_ans(w + " = ", s.y, " " + unit(s))
	var ws: Array = []
	var fill: Array = [lk(ans, s.x).values]
	# r rounded before h is found: the catalogue's slip is about a can's r and h.
	if AiOptimisationSituation.apart(s.rounded, s.y):
		if s.fam == "can":
			ws.append(lk(ans, s.rounded, R_ROUND_FIRST))
		else:
			fill.append(lk(ans, s.rounded).values)
	out.answer = ans
	out.wrongs = ws
	out.fillers = fill + multiples(ans, s.y)
	var calc: Array = [build_line(s)] + solve_shape(s) + [shape_sign(s), _y_line(s), fin(ans)]
	out.methods = {"calculus-route": method(calc, ans.values),
		"gdc-graph-route": method([build_line(s), shape_gdc(s, false), _y_line(s), fin(ans)], ans.values)}
	return out


# ── The route ────────────────────────────────────────────────

func u_route_least_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := setup(rep, s)
	var o := obj(s)
	var point: bool = s.target == "point"
	var what_ := "total cost" if s.cost else "total time"
	out.asked = ("Find the value of x that makes the %s as small as possible." % what_) if point else ("Find the least possible %s." % what_)
	var ans := sf_ans("x = ", s.x, " km") if point else sf_ans(o + " = ", s.best, value_tail(s))
	var b := float(s.b)
	# Both legs at one speed is a time's slip: a cable's two costs are no speeds.
	var one_ref := "" if s.cost else R_ONE_SPEED
	if point:
		out.wrongs = [lk(ans, b, one_ref)]
		out.fillers = [lk(ans, b - s.x).values] + multiples(ans, s.x)
	else:
		out.wrongs = [lk(ans, s.x, R_X_VALUE), lk(ans, AiOptimisationSituation.one_speed(s), one_ref)]
		out.fillers = [lk(ans, OptimisationSituation.route_value(s, b)).values] + multiples(ans, s.best)
	out.fillers = out.wrongs.filter(func(wr): return wr.ref == "").map(func(wr): return wr.values) + out.fillers
	out.wrongs = out.wrongs.filter(func(wr): return wr.ref != "")
	out.answer = ans
	var rt := route_text(s)
	var legs := "By Pythagoras MD = √(%d² + x²) = √(%d + x²) km, and DB = (%d − x) km." % [s.a, s.a * s.a, s.b]
	var how := "Multiply each length by its cost per km, and add: %s." % rt if s.cost else "Time = distance ÷ speed on each part, and the times add: %s." % rt
	var read := "x = %s, %s = %s" % [W(s.x), o, W(s.best)]
	out.methods = {
		"substitute-constraint": method([legs, how, "The GDC's minimum tool on this function, for 0 ≤ x ≤ %d, gives %s." % [s.b, read], fin(ans)], ans.values),
		"derivative-zero": method(["%s, for 0 ≤ x ≤ %d." % [rt, s.b],
			"Graph its derivative with the GDC's d/dx: d%s/dx = 0 at x = %s." % [o, W(s.x)],
			"d%s/dx goes from negative to positive there, so %s is least: %s = %s." % [o, o, o, W(s.best)], fin(ans)], ans.values),
		"gdc-maximum": method(["%s, for 0 ≤ x ≤ %d." % [rt, s.b], "Graph it on the GDC: the minimum tool gives %s." % read, fin(ans)], ans.values),
	}
	return out


# ── The domain in context ────────────────────────────────────

static func span(lo: Variant, hi: Variant, shape: String = "between", ends: String = "left out") -> Dictionary:
	return {"shape": shape, "lo": Q.of(lo), "hi": Q.of(hi), "ends": ends}


func u_context_domain(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := setup(rep, s)
	var top: Q
	var steps: Array
	var ws: Array
	var fill: Array
	if s.fam == "box":
		var short := mini(s.w, s.h)
		var long_ := maxi(s.w, s.h)
		top = Q.new(short, 2)
		out.lines = out.lines + ["V = x(%d − 2x)(%d − 2x), where V cm³ is the volume of the tray." % [s.w, s.h]]
		out.asked = "Find the domain of V in this context."
		ws = [wrong(span(0, short), R_NEG_LEN), wrong(span(0, top, "above"), R_NEG_LEN), wrong(span(0, top, "between", "included"), R_CLOSED)]
		fill = [span(0, long_), span(0, 2 * short)]
		steps = ["x is the side of a square cut from each corner, so x > 0.",
			"The base sides %d − 2x and %d − 2x must be positive: %d − 2x > 0 needs x < %s, and then %d − 2x > 0 too." % [s.w, s.h, short, D(top), long_],
			"At x = 0 and at x = %s the volume is 0: there is no tray, so both ends are left out." % D(top)]
	else:
		top = Q.new(s.F, s.n)
		out.lines = out.lines + ["%s, where A m² is the area of the %s." % [f_text(s), PEN[s.ctx][1]]]
		out.asked = "Find the domain of A in this context."
		ws = [wrong(span(0, s.F), R_NEG_LEN), wrong(span(0, top, "above"), R_NEG_LEN), wrong(span(0, top, "between", "included"), R_CLOSED)]
		fill = [span(0, top.mul(2)), span(0, top.mul(3))]
		steps = ["x is a length of fence, so x > 0.", "The section along the wall is y = %d − %sx m, which must be positive: x < %s." % [s.F, Fmt.lead(s.n), D(top)],
			"At x = 0 and at x = %s the area is 0: there is no %s, so both ends are left out." % [D(top), PEN[s.ctx][1]]]
	var ans := Answer.make("interval", span(0, top), {"var": "x"})
	ans.exact = true
	out.answer = ans
	out.wrongs = ws
	out.fillers = fill
	out.methods = {"check-domain-ends": method(steps + ["So the domain is %s." % Answer.text(ans)], ans.values)}
	return out
