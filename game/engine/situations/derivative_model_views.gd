class_name DerivativeModelViews
extends ExtensionViews
## The views on the `derivative-model` situation: one builder per unknown of
## t5-derivative-model-gdc (FAL-753). Every question is Paper 2, as every bank part is. A model's
## rate or time is a GDC value to 3 s.f. with the rounding trap; a reading in words is a
## multiple-choice claim; a value from a table or from graphs is exact.
##
## Representations: "equation" (the model on its own line), "words" (a story), "graph" (the model
## with its tangent, the graph of the rate, or straight-line pieces to read) and "table".
## `given` holds what the student is shown.

const SI := "SL5.1.interpret-derivative#"
const SR := "SL5.6.rules-with-values#"
const R_VALUE := SI + "0"
const R_SIGN := SI + "1"
const R_UNITS := SI + "2"
const R_NEXT := SI + "3"
const R_PEAK := SI + "4"
const R_OLD_UNIT := SI + "5"
const R_INPUT := SR + "0"
const R_PRODUCT := SR + "1"
const R_DERIV_READ := SR + "2"
const R_DIVIDE := SR + "3"
const R_ORDER := SR + "4"
const R_NO_INNER := SR + "5"

## The stories, by family (DerivativeModelSituation): sym names the quantity, what says what it
## is, y its units, per one unit of t. A wave's story also names two of them for a comparison.
const CONTEXTS := [
	{"sym": "M", "what": "area of mould on a bunker wall", "y": "cm²", "per": "day", "time": "days"},
	{"sym": "R", "what": "number of rad-rats in the tunnels", "y": "rats", "per": "week", "time": "weeks"},
	{"sym": "X", "what": "radiation reading at the dump", "y": "microsieverts", "per": "hour", "time": "hours"},
	{"sym": "C", "what": "amount of coolant in a leaking tank", "y": "litres", "per": "minute", "time": "minutes"},
	{"sym": "P", "what": "population of a settlement", "y": "people", "per": "year", "time": "years"},
	{"sym": "V", "what": "area covered by a vine", "y": "m²", "per": "week", "time": "weeks"},
	{"sym": "T", "what": "number of traders on the new route", "y": "traders", "per": "year", "time": "years"},
	{"sym": "S", "what": "toxin level in a water filter", "y": "mg per litre", "per": "hour", "time": "hours"},
	{"sym": "K", "what": "smoke level in a shelter", "y": "parts per million", "per": "minute", "time": "minutes"},
	{"sym": "Q", "what": "pressure in a pipe after a surge", "y": "kilopascals", "per": "minute", "time": "minutes"},
	{"sym": "D", "what": "depth of water in a flooded canal", "y": "metres", "per": "hour", "time": "hours", "two": "two flooded canals", "measure": "depth"},
	{"sym": "H", "what": "height of a fungus tower", "y": "cm", "per": "day", "time": "days", "two": "two fungus towers", "measure": "height"},
	{"sym": "W", "what": "charge in a battery bank", "y": "kilowatt-hours", "per": "hour", "time": "hours", "two": "two battery banks", "measure": "charge"},
	{"sym": "L", "what": "length of a tunnel", "y": "metres", "per": "day", "time": "days"},
	{"sym": "G", "what": "height of a dune wall", "y": "metres", "per": "year", "time": "years"},
]
## The shorter unit each unit of time divides into.
const SHORTER := {"day": {"to": "hour", "div": 24}, "week": {"to": "day", "div": 7}, "hour": {"to": "minute", "div": 60},
	"minute": {"to": "second", "div": 60}, "year": {"to": "month", "div": 12}}
## A product's two things and their total: letters, what each is, and its units.
const PRODUCT_STORIES := [
	{"F": "N", "G": "w", "H": "C", "f": "number of trucks in a convoy", "g": "number of crates on each truck", "h": "total number of crates", "fu": "trucks", "gu": "crates", "hu": "crates", "per": "hour", "time": "hours"},
	{"F": "N", "G": "w", "H": "B", "f": "number of diggers on a site", "g": "number of buckets each digger fills in a shift", "h": "total number of buckets in a shift", "fu": "diggers", "gu": "buckets", "hu": "buckets", "per": "week", "time": "weeks"},
	{"F": "A", "G": "p", "H": "E", "f": "area of a solar field (m²)", "g": "power from each m² (watts)", "h": "total power", "fu": "m²", "gu": "watts", "hu": "watts", "per": "month", "time": "months"},
	{"F": "N", "G": "b", "H": "W", "f": "number of water carts in a caravan", "g": "number of barrels on each cart", "h": "total number of barrels", "fu": "carts", "gu": "barrels", "hu": "barrels", "per": "day", "time": "days"},
]
## A quotient's top and bottom, and what one divided by the other is.
const QUOTIENT_STORIES := [
	{"F": "W", "G": "N", "H": "S", "f": "water in a tank (litres)", "g": "number of settlers sharing it", "h": "amount of water for each settler", "fu": "litres", "gu": "settlers", "hu": "litres per settler", "per": "week", "time": "weeks"},
	{"F": "F", "G": "N", "H": "L", "f": "fuel in a depot (litres)", "g": "number of trucks sharing it", "h": "amount of fuel for each truck", "fu": "litres", "gu": "trucks", "hu": "litres per truck", "per": "day", "time": "days"},
	{"F": "C", "G": "N", "H": "R", "f": "number of crates of food in a store", "g": "number of families sharing them", "h": "number of crates for each family", "fu": "crates", "gu": "families", "hu": "crates per family", "per": "month", "time": "months"},
]
const UNKNOWNS := ["rate-at-time", "rate-with-units", "rate-other-unit", "time-at-rate", "greatest-rate", "time-of-greatest-rate", "rising-or-falling",
	"interpret-rate", "compare-models", "time-rate-greater", "steeper-tangent", "tangent-estimate", "product-from-table", "quotient-from-table",
	"chain-from-table", "composite-with-model", "rising-from-table", "product-from-graphs", "quotient-from-graphs", "chain-from-graphs"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## Every cell is Paper 2: every part of this type in the bank is.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.wrongs = rng.shuffled(out.wrongs)
	out.given = DerivativeModelSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func ctx(s: Dictionary) -> Dictionary:
	return CONTEXTS[s.ctx]


static func shorter(index: int) -> Dictionary:
	return SHORTER[CONTEXTS[index].per]


static func unit(c: Dictionary) -> String:
	return "%s per %s" % [c.y, c.per]


## "120e^(−0.05t)", "800/(1 + 19e^(−0.35t))", "40te^(−0.2t)", "25 + 0.8t + 3 cos(0.6t)", "10 + 15 ln(0.4t + 1)".
static func model(m: Dictionary) -> String:
	match m.fam:
		"exp":
			return "%se^(%st)" % [D(m.P), D(m.k)]
		"logistic":
			return "%s/(1 + %se^(−%st))" % [D(m.L), D(m.a), D(m.k)]
		"pulse":
			return "%ste^(−%st)" % [D(m.a), D(m.k)]
		"wave":
			return "%s + %st + %s cos(%st)" % [D(m.c), GdcKit.lead(m.m), D(m.B), GdcKit.lead(m.w)]
		"log":
			return "%s + %s ln(%st + 1)" % [D(m.c), D(m.a), GdcKit.lead(m.b)]
	return "%s + %st" % [D(m.c), GdcKit.lead(m.m)]


## The derivative as the working writes it.
static func derivative(m: Dictionary) -> String:
	match m.fam:
		"exp":
			return "%se^(%st)" % [D(m.P.mul(m.k)), D(m.k)]
		"logistic":
			return "%se^(−%st)/(1 + %se^(−%st))²" % [D(m.L.mul(m.a).mul(m.k)), D(m.k), D(m.a), D(m.k)]
		"pulse":
			return "%se^(−%st) − %ste^(−%st)" % [D(m.a), D(m.k), D(m.a.mul(m.k)), D(m.k)]
		"wave":
			return "%s − %s sin(%st)" % [D(m.m), D(m.B.mul(m.w)), GdcKit.lead(m.w)]
		"log":
			return "%s/(%st + 1)" % [D(m.a.mul(m.b)), GdcKit.lead(m.b)]
	return D(m.m)


## How the rule goes for this family.
static func rule_name(m: Dictionary) -> String:
	match m.fam:
		"exp":
			return "Chain rule on the exponential"
		"logistic":
			return "Chain rule on the bracket to the power −1"
		"pulse":
			return "Product rule on %st × e^(−%st)" % [D(m.a), D(m.k)]
		"wave":
			return "Term by term, with the chain rule on the cosine"
	return "Chain rule on the logarithm"


static func domain(s: Dictionary) -> String:
	return "0 ≤ t ≤ %d" % s.T


static func story(s: Dictionary) -> String:
	var c := ctx(s)
	return "The %s, in %s, t %s after the start, is modelled by %s(t) = %s, for %s." % [c.what, c.y, c.time, c.sym, model(s.mod), domain(s)]


static func bare(s: Dictionary) -> String:
	return "%s(t) = %s, for %s" % [ctx(s).sym, model(s.mod), domain(s)]


## The lines that say what the model is.
static func model_lines(rep: String, s: Dictionary) -> Array:
	return [bare(s)] if rep == "equation" else [story(s)]


## The model, and on the bare form what its letter stands for, where the question names the quantity.
static func named_lines(rep: String, s: Dictionary) -> Array:
	var c := ctx(s)
	var out := model_lines(rep, s)
	if rep == "equation":
		out.append("%s is the %s, in %s, and t is in %s." % [c.sym, c.what, c.y, c.time])
	return out


static func rising(r: float) -> String:
	return "rising" if r > 0.0 else "falling"


## A number to 3 s.f., and its label.
static func sf_answer(label: String, x: float, tail: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": GdcKit.qf(x)}, {}, label, tail)
	ans.show = "sf"
	return ans


## An exact number, as a decimal.
static func exact_answer(label: String, v: Variant, tail: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": Q.of(v)}, {}, label, tail)
	ans.show = "dec"
	ans.exact = true
	return ans


static func wv(x: float, ref: String = "") -> Dictionary:
	return wrong({"v": GdcKit.qf(x)}, ref)


static func gv(xs: Array) -> Array:
	return xs.filter(func(x): return is_finite(x) and x != 0.0).map(func(x): return {"v": GdcKit.qf(x)})


static func gx(xs: Array) -> Array:
	return xs.map(func(x): return {"v": Q.of(x)})


static func claim(tag: String, text: String) -> Dictionary:
	return {"form": tag, "vals": [], "text": text}


## The right sentence, and the wrong ones with their tags.
static func claims(right: String, wrongs_in: Array) -> Dictionary:
	var built := DerivativeMeaningViews.claim_answer(right, wrongs_in)
	return {"answer": built.answer, "wrongs": built.wrongs}


## The model on 0 ≤ t ≤ T, with a mark at each time, and its tangent there if asked.
static func model_graph(s: Dictionary, marks: Array, tangents: bool, name_points: Array = []) -> Dictionary:
	var m: Dictionary = s.mod
	var top: int = s.T
	var f := func(t: float) -> float: return DerivativeModelSituation.y(m, t)
	var pts := GdcKit.curve(f, 0.0, float(top))
	var lo := INF
	var hi := -INF
	for p in pts:
		lo = minf(lo, p[1])
		hi = maxf(hi, p[1])
	var curves: Array = [pts]
	var points: Array = []
	var lines: Array = []
	for i in marks.size():
		var t0: float = marks[i]
		var y0: float = f.call(t0)
		var r := DerivativeModelSituation.dy(m, t0)
		points.append([t0, y0, name_points[i] if i < name_points.size() else ""])
		if tangents:
			var span := minf(top * 0.22, 0.35 * (hi - lo + 1.0) / maxf(absf(r), 0.01))
			# One curve, so one colour: a point off the plot breaks the line (GraphView) between two tangents.
			if not lines.is_empty():
				lines.append([t0, DerivativeMeaningViews.BREAK_Y])
			lines.append_array(GdcKit.curve(func(t: float) -> float: return y0 + r * (t - t0), maxf(t0 - span, 0.0), minf(t0 + span, float(top))))
	if not lines.is_empty():
		curves.append(lines)
	return window_of(curves, points, top, minf(lo, 0.0), hi, ctx(s).sym)


static func window_of(curves: Array, points: Array, top: int, lo: float, hi: float, name: String) -> Dictionary:
	var win := GdcKit.window(0.0, float(top), lo, hi, 0.0, 0.15)
	var g := Plot.spec(curves, points, 0, top, win[2], win[3])
	g.x_name = "t"
	g.y_name = name
	return g


## y = S′(t), with the line y = k.
static func rate_graph(s: Dictionary, k: Q) -> Dictionary:
	var m: Dictionary = s.mod
	var pts := GdcKit.curve(func(t: float) -> float: return DerivativeModelSituation.dy(m, t), 0.0, float(s.T))
	var lo: float = minf(0.0, k.to_float())
	var hi: float = maxf(0.0, k.to_float())
	for p in pts:
		lo = minf(lo, p[1])
		hi = maxf(hi, p[1])
	var win := GdcKit.window(0.0, float(s.T), lo, hi, 0.0, 0.15)
	var g := Plot.spec([pts], [], 0, s.T, win[2], win[3], [[k.to_float(), "y = " + D(k)]])
	g.x_name = "t"
	g.y_name = ctx(s).sym + "′"
	return g


# ── A rate at a time ─────────────────────────────────────────

## The GDC's line for a rate at a time.
static func gdc_line(s: Dictionary) -> String:
	return "Use the GDC's dy/dx at t = %d: %s′(%d) = %s." % [s.t0, ctx(s).sym, s.t0, GdcKit.W(s.r)]


## The rule's lines for a rate at a time.
static func rule_lines(s: Dictionary) -> Array:
	var sym: String = ctx(s).sym
	return ["%s: %s′(t) = %s." % [rule_name(s.mod), sym, derivative(s.mod)],
		"Put t = %d into %s′(t): %s." % [s.t0, sym, GdcKit.W(s.r)]]


func u_rate_at_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var r: float = s.r
	var ans := sf_answer("%s′(%d) = " % [c.sym, s.t0], r)
	var asked := "Find %s′(%d), to 3 s.f." % [c.sym, s.t0]
	if rep != "equation":
		ans = sf_answer("d%s/dt = " % c.sym, r, " " + unit(c))
		asked = "Find the rate of change of the %s when t = %d, in %s, to 3 s.f." % [c.what, s.t0, unit(c)]
	var slips: Array = [wv(s.v, R_VALUE), wv(DerivativeModelSituation.next_change(s), R_NEXT)]
	if r < 0.0:
		slips.append(wv(-r, R_SIGN))
	slips.append_array(_rule_slips(s.mod, s.t0))
	var out := {"lines": model_lines(rep, s), "asked": asked, "answer": ans, "wrongs": slips,
		"generic": gv([-r, r * 2.0, r * 0.5, r * 1.5]),
		"methods": {"gdc-derivative": method(["The rate of change is the derivative.", gdc_line(s), Answer.text(ans)], ans.values),
			"rule-then-substitute": method(rule_lines(s) + [Answer.text(ans)], ans.values)}}
	if rep == "graph":
		out.graph = model_graph(s, [float(s.t0)], true)
		out.lines = [story(s), "The graph shows %s against t, with the tangent at t = %d." % [c.sym, s.t0]]
	return out


## The slips of each family's rule, in the same shape as the rate.
static func _rule_slips(m: Dictionary, t0: int) -> Array:
	if m.fam == "pulse":
		return [wv(DerivativeModelSituation.product_slip(m, t0), R_PRODUCT)]
	if m.fam in ["log", "wave"]:
		return [wv(DerivativeModelSituation.no_inner(m, t0), R_NO_INNER)]
	return []


func u_rate_with_units(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var r: float = s.r
	var right := "%s %s" % [Fmt.sf(r), unit(c)]
	var flip: Array = ["%s %s" % [Fmt.sf(-r), unit(c)], R_SIGN if r < 0.0 else ""]
	var built := claims(right, [["%s %s" % [Fmt.sf(r), c.y], R_UNITS], ["%s %s" % [Fmt.sf(s.v), unit(c)], R_VALUE], flip])
	var out := {"lines": [story(s)], "asked": "Find the rate of change of the %s when t = %d, with its units." % [c.what, s.t0],
		"answer": built.answer, "wrongs": built.wrongs, "generic": [],
		"methods": {"gdc-derivative": method([gdc_line(s), "The rate takes the units of %s per the units of t." % c.sym, right], built.answer.values),
			"units-ratio": method(["%s is in %s and t is in %s, so d%s/dt is in %s." % [c.sym, c.y, c.time, c.sym, unit(c)], gdc_line(s), right], built.answer.values)}}
	if rep == "graph":
		out.graph = model_graph(s, [float(s.t0)], true)
		out.lines = [story(s), "The graph shows %s against t, with the tangent at t = %d." % [c.sym, s.t0]]
	return out


func u_rate_other_unit(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var to := shorter(s.ctx)
	var div: int = to.div
	var r: float = s.r
	var ans := sf_answer("rate = ", r / div, " %s per %s" % [c.y, to.to])
	var line: String = "There are %d %ss in a %s, so divide by %d: %s ÷ %d = %s." % [div, to.to, c.per, div, GdcKit.W(r), div, GdcKit.W(r / div)]
	return {"lines": [story(s)], "asked": "Find the rate of change of the %s when t = %d, in %s per %s, to 3 s.f." % [c.what, s.t0, c.y, to.to],
		"answer": ans, "wrongs": [wv(r, R_OLD_UNIT), wv(s.v / div, R_VALUE)], "generic": gv([r * div, -r / div, r / (div * 2.0)]),
		"methods": {"gdc-derivative": method([gdc_line(s), line, Answer.text(ans)], ans.values),
			"units-ratio": method(["%s′(t) is in %s per %s, and a %s is the shorter unit." % [c.sym, c.y, c.per, to.to], gdc_line(s), line, Answer.text(ans)], ans.values)}}


# ── A time, and the greatest rate ────────────────────────────

func u_time_at_rate(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var k: Q = s.k
	var kf: float = k.to_float()
	var x: float = s.x
	var ans := sf_answer("t = ", x)
	var slips: Array = []
	var wrong_ts := DerivativeModelSituation.amount_times(s, absf(kf))
	if not wrong_ts.is_empty():
		slips.append(wv(wrong_ts[0], R_VALUE))
	if kf < 0.0:
		var other := DerivativeModelSituation.rate_times(s, -kf)
		if not other.is_empty():
			slips.append(wv(other[0], R_SIGN))
	var word := "first " if s.first else ""
	var asked := "Find the %stime at which the %s is %s at %s %s, to 3 s.f." % [word, c.what, "increasing" if kf > 0.0 else "decreasing", D(k.abs_q()), unit(c)]
	if rep == "equation":
		asked = "Find the %svalue of t for which %s′(t) = %s, to 3 s.f." % [word, c.sym, D(k)]
	var out := {"lines": model_lines(rep, s), "asked": asked, "answer": ans, "wrongs": slips, "generic": gv([x * 1.25, x * 0.75, x + 1.0, x + 0.5]),
		"methods": {"gdc-derivative": method(["The rate is %s, so %s′(t) = %s." % [D(k), c.sym, D(k)],
				"Graph y = %s′(t) and y = %s, and find where they first meet: t = %s." % [c.sym, D(k), GdcKit.W(x)], Answer.text(ans)], ans.values),
			"rule-then-substitute": method(["%s: %s′(t) = %s." % [rule_name(s.mod), c.sym, derivative(s.mod)],
				"Solve %s = %s with the GDC's solver: t = %s." % [derivative(s.mod), D(k), GdcKit.W(x)], Answer.text(ans)], ans.values)}}
	if rep == "graph":
		out.graph = rate_graph(s, k)
		out.lines = [story(s), "The graph shows %s′(t), with the line y = %s." % [c.sym, D(k)]]
	return out


func _greatest_lines(s: Dictionary, what: String) -> Array:
	var c := ctx(s)
	var kind := "minimum" if s.fall else "maximum"
	return ["Graph y = %s′(t) for %s: the rate is that curve's height." % [c.sym, domain(s)],
		"Its %s point is (%s, %s), which is %s." % [kind, GdcKit.W(s.top.t), GdcKit.W(-s.top.r if s.fall else s.top.r), what]]


func u_greatest_rate(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var r: float = s.top.r
	var p := DerivativeModelSituation.peak_of(s)
	var ans := sf_answer("rate = ", r, " " + unit(c))
	var asked := "Find the greatest rate at which the %s %s, in %s, to 3 s.f." % [c.what, "falls" if s.fall else "changes", unit(c)]
	var slips: Array = [wv(DerivativeModelSituation.y(s.mod, s.top.t), R_VALUE), wv(p.y, R_PEAK)]
	if s.mod.fam == "wave":
		slips.append(wv(s.mod.m.to_float() + s.mod.B.to_float(), R_NO_INNER))
	var out := {"lines": named_lines(rep, s), "asked": asked, "answer": ans, "wrongs": slips, "generic": gv([r * 2.0, r * 0.5, r * 1.5]),
		"methods": {"gdc-derivative": method(_greatest_lines(s, "the greatest size of the rate") + [Answer.text(ans)], ans.values)}}
	if rep == "graph":
		out.graph = model_graph(s, [], false)
		out.lines = [story(s), "The graph shows %s against t." % c.sym]
	return out


func u_time_of_greatest_rate(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var t: float = s.top.t
	var p := DerivativeModelSituation.peak_of(s)
	var ans := sf_answer("t = ", t)
	var asked := "Find the time at which the %s is %s fastest, to 3 s.f." % [c.what, "falling" if s.fall else "rising"]
	var out := {"lines": named_lines(rep, s), "asked": asked, "answer": ans, "wrongs": [wv(p.t, R_PEAK)], "generic": gv([t * 0.5, t * 1.5, t + 1.0, t - 0.5]),
		"methods": {"gdc-derivative": method(_greatest_lines(s, "where the model is steepest") + [Answer.text(ans)], ans.values)}}
	if rep == "graph":
		out.graph = model_graph(s, [], false)
		out.lines = [story(s), "The graph shows %s against t." % c.sym]
	return out


# ── Reading a rate ───────────────────────────────────────────

func u_rising_or_falling(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var r: float = s.r
	var mag := Fmt.sf(absf(r))
	var word := rising(r)
	var other := rising(-r)
	var right := "%s at %s %s" % [word.capitalize(), mag, unit(c)]
	var built := claims(right, [["%s at %s %s" % [other.capitalize(), mag, unit(c)], R_SIGN if r < 0.0 else ""],
		["%s at %s %s" % [word.capitalize(), Fmt.sf(s.v), unit(c)], R_VALUE],
		["%s by %s %s" % ["Up" if r > 0.0 else "Down", mag, c.y], R_UNITS]])
	var out := {"lines": named_lines(rep, s), "asked": "At t = %d, which way is the %s going, and how fast?" % [s.t0, c.what],
		"answer": built.answer, "wrongs": built.wrongs, "generic": [],
		"methods": {"gdc-derivative": method([gdc_line(s), "Its sign says %s; its size says how fast." % word, right], built.answer.values),
			"sign-direction": method(["The sign of %s′(%d) gives the direction: %s, so %s." % [c.sym, s.t0, GdcKit.W(r), word],
				"The size gives the speed, in %s." % unit(c), right], built.answer.values),
			"tangent-picture": method(["At t = %d the tangent has gradient %s." % [s.t0, GdcKit.W(r)],
				"A tangent going %s means the %s is %s." % ["up" if r > 0.0 else "down", c.what, word], right], built.answer.values)}}
	if rep == "graph":
		out.graph = model_graph(s, [float(s.t0)], true)
		out.lines = [story(s), "The graph shows %s against t, with the tangent at t = %d." % [c.sym, s.t0]]
	return out


func u_interpret_rate(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var r: float = s.r
	var mag := Fmt.sf(absf(r))
	var way := "going up" if r > 0.0 else "going down"
	var back := "going down" if r > 0.0 else "going up"
	var right := "At t = %d the %s is %s at %s %s." % [s.t0, c.what, way, mag, unit(c)]
	var built := claims(right, [["At t = %d the %s is %s %s." % [s.t0, c.what, mag, c.y], R_VALUE],
		["At t = %d the %s is %s at %s %s." % [s.t0, c.what, back, mag, unit(c)], R_SIGN if r < 0.0 else ""],
		["The %s has %s by %s %s since the start." % [c.what, "gone up" if r > 0.0 else "gone down", mag, c.y], R_UNITS],
		["In the next %s the %s %s by exactly %s %s." % [c.per, c.what, "goes up" if r > 0.0 else "goes down", mag, c.y], R_NEXT]])
	var out := {"lines": model_lines(rep, s), "asked": "Find %s′(%d). Which sentence says what it means here?" % [c.sym, s.t0],
		"answer": built.answer, "wrongs": built.wrongs, "generic": [],
		"methods": {"gdc-derivative": method([gdc_line(s), "It is a rate at one instant, not an amount.", right], built.answer.values),
			"units-ratio": method([gdc_line(s), "%s′(t) is in %s, at that instant." % [c.sym, unit(c)], right], built.answer.values),
			"sign-direction": method([gdc_line(s), "A %s value means the %s is %s." % ["positive" if r > 0.0 else "negative", c.what, way], right], built.answer.values)}}
	if rep == "graph":
		out.graph = model_graph(s, [float(s.t0)], true)
		out.lines = [story(s), "The graph shows %s against t, with the tangent at t = %d." % [c.sym, s.t0]]
	return out


## The two models as named in the question: the first is the hump unless it is flipped.
static func named(s: Dictionary) -> Dictionary:
	return {"A": s.mod2, "B": s.mod} if s.flip else {"A": s.mod, "B": s.mod2}


func u_compare_models(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var ms := named(s)
	var t0: int = s.t0
	var ra := DerivativeModelSituation.dy(ms.A, t0)
	var rb := DerivativeModelSituation.dy(ms.B, t0)
	var va := DerivativeModelSituation.y(ms.A, t0)
	var vb := DerivativeModelSituation.y(ms.B, t0)
	var fast := "A" if ra > rb else "B"
	var slow := "B" if fast == "A" else "A"
	var gap := Fmt.sf(absf(ra - rb))
	var nums := "A′(%d) = %s and B′(%d) = %s" % [t0, Fmt.sf(ra), t0, Fmt.sf(rb)]
	var right := "%s, so the %s is rising faster in model %s." % [nums, c.what, fast]
	var high := va if fast == "B" else vb
	var built := claims(right, [
		["The %s is rising faster in model %s, because that model is higher at t = %d (%s)." % [c.what, slow, t0, Fmt.sf(high)], R_VALUE],
		["%s, so the %s is rising faster in model %s." % [nums, c.what, slow], ""],
		["Model %s is %s %s ahead at t = %d." % [fast, gap, c.y, t0], ""]])
	var lines: Array = ["Two models of the %s, in %s, t %s after the start, for %s:" % [c.what, c.y, c.time, domain(s)],
		"A(t) = %s" % model(ms.A), "B(t) = %s" % model(ms.B)]
	var out := {"lines": lines, "asked": "Compare the two models at t = %d. Which sentence is true?" % t0,
		"answer": built.answer, "wrongs": built.wrongs, "generic": [],
		"methods": {"gdc-derivative": method(["Use the GDC's dy/dx at t = %d on each model: A′(%d) = %s and B′(%d) = %s." % [t0, t0, GdcKit.W(ra), t0, GdcKit.W(rb)],
				"The greater derivative rises faster, whichever model is higher.", right], built.answer.values),
			"sign-direction": method(["Both derivatives are positive, so both models rise; the size says how fast.",
				"The GDC gives the sizes, %s for A and %s for B." % [GdcKit.W(ra), GdcKit.W(rb)], right], built.answer.values)}}
	if rep == "graph":
		var fa := func(t: float) -> float: return DerivativeModelSituation.y(ms.A, t)
		var fb := func(t: float) -> float: return DerivativeModelSituation.y(ms.B, t)
		var pa := GdcKit.curve(fa, 0.0, float(s.T))
		var pb := GdcKit.curve(fb, 0.0, float(s.T))
		var hi := 0.0
		for p in pa + pb:
			hi = maxf(hi, p[1])
		out.graph = window_of([pa, pb], [[float(s.T), fa.call(float(s.T)), "A"], [float(s.T), fb.call(float(s.T)), "B"]], s.T, 0.0, hi, c.sym)
	return out


## "2.1 to 4.3 and 6.7 to 9": each stretch, to the working's figures.
static func pieces_text(pieces: Array) -> String:
	return " and ".join(pieces.map(func(p): return "%s to %s" % [GdcKit.W(p[0]), GdcKit.W(p[1])]))


func u_time_rate_greater(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var x: float = s.xs
	var ans := sf_answer("total time = ", x, " " + c.time if rep == "words" else "")
	var slips: Array = []
	if s.above > 0.0:
		slips.append(wv(s.above, R_VALUE))
	var a := model(s.mod)
	var b := model(s.mod2)
	var lines: Array = ["A(t) = %s" % a, "B(t) = %s" % b, "Both are for %s." % domain(s)]
	var asked := "Find the total time for which the rate of change of B is greater than the rate of change of A."
	if rep == "words":
		lines = ["The %ss of %s, in %s, t %s after the start, are A(t) = %s and B(t) = %s, for %s." % [c.measure, c.two, c.y, c.time, a, b, domain(s)]]
		asked = "Find the total time, in %s, for which the %s of B is changing at a greater rate than the %s of A." % [c.time, c.measure, c.measure]
	var cuts := "Find where y = A′(t) meets the line y = %s: t = %s." % [D(s.mod2.m), ", ".join(s.cross.map(func(t): return GdcKit.W(t)))]
	var parts := "A′(t) is below B′(t) from %s." % pieces_text(s.pieces)
	var sum := "Add the stretches: %s." % GdcKit.W(x)
	return {"lines": lines, "asked": asked, "answer": ans, "wrongs": slips, "generic": gv([s.T - x, x * 0.5, x * 1.5]),
		"methods": {"gdc-derivative": method(["Graph the two derivatives with the GDC: B′(t) is the line y = %s." % D(s.mod2.m), cuts, parts, sum, Answer.text(ans)], ans.values),
			"rule-then-substitute": method(["Differentiate: A′(t) = %s and B′(t) = %s." % [derivative(s.mod), D(s.mod2.m)],
				"Solve %s = %s on the domain: t = %s." % [derivative(s.mod), D(s.mod2.m), ", ".join(s.cross.map(func(t): return GdcKit.W(t)))], parts, sum, Answer.text(ans)], ans.values)}}


func u_steeper_tangent(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var m: Dictionary = s.mod
	# t1 rises faster; flip calls it Q.
	var fast := "Q" if s.flip else "P"
	var slow := "P" if s.flip else "Q"
	var marks: Array = [float(s.t1), float(s.t2)]
	var names: Array = [fast, slow]
	var ra := DerivativeModelSituation.dy(m, s.t1)
	var rb := DerivativeModelSituation.dy(m, s.t2)
	var right := "At %s, because its tangent has the greater gradient." % fast
	var built := claims(right, [["At %s, because %s is higher on the curve." % [slow, slow], R_VALUE],
		["At %s, because its tangent is the steeper one." % slow if s.opposite else "At %s, because its tangent has the greater gradient." % slow, R_SIGN if s.opposite else ""],
		["At neither: the rate is the same at both points.", ""]])
	var tp: float = s.t1 if not s.flip else s.t2
	var tq: float = s.t2 if not s.flip else s.t1
	return {"lines": [bare(s), "The graph shows %s against t, with the tangents at P (t = %d) and Q (t = %d)." % [c.sym, tp, tq]],
		"graph": model_graph(s, marks, true, names),
		"asked": "At which point is the %s rising faster?" % c.what, "answer": built.answer, "wrongs": built.wrongs, "generic": [],
		"methods": {"tangent-picture": method(["The gradient of each tangent is the rate there: %s at %s and %s at %s." % [Fmt.sf(ra), fast, Fmt.sf(rb), slow],
			"Rising faster means the greater gradient, with its sign, not the higher point.", right], built.answer.values)}}


func u_tangent_estimate(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var t1: float = s.t0 + s.h.to_float()
	var est: float = DerivativeModelSituation.estimate(s)
	var ans := sf_answer("%s ≈ " % c.sym, est)
	var slips: Array = []
	if s.r < 0.0:
		slips.append(wv(s.v - s.r * s.h.to_float(), R_SIGN))
	var line := "The tangent at t = %d passes through (%d, %s) with gradient %s." % [s.t0, s.t0, GdcKit.W(s.v), GdcKit.W(s.r)]
	var step := "At t = %s: %s + %s × %s = %s." % [D(Q.new(s.t0).add(s.h)), GdcKit.W(s.v), GdcKit.W(s.r), D(s.h), GdcKit.W(est)]
	var out := {"lines": model_lines(rep, s), "asked": "Use the tangent at t = %d to estimate %s when t = %s, to 3 s.f." % [s.t0, c.sym, D(Q.new(s.t0).add(s.h))],
		"answer": ans, "wrongs": slips, "generic": gv([DerivativeModelSituation.y(s.mod, t1), s.v + s.r, s.r * s.h.to_float(), est * 1.1, est * 0.9]),
		"methods": {"gdc-derivative": method(["With the GDC: %s(%d) = %s and %s′(%d) = %s." % [c.sym, s.t0, GdcKit.W(s.v), c.sym, s.t0, GdcKit.W(s.r)], step, Answer.text(ans)], ans.values),
			"tangent-picture": method([line, step, Answer.text(ans)], ans.values)}}
	if rep == "graph":
		out.graph = model_graph(s, [float(s.t0)], true)
		out.lines = [story(s), "The graph shows %s against t, with the tangent at t = %d." % [c.sym, s.t0]]
	return out


# ── Rules with values ────────────────────────────────────────

static func paren(v: int) -> String:
	return "(%s)" % Fmt.num(v) if v < 0 else Fmt.num(v)


## The table of four columns against t: the two quantities and their rates.
static func rule_table(s: Dictionary, F: String, G: String, letter: String = "t") -> Dictionary:
	var cols := func(col: Array) -> Array: return col.map(func(v): return Fmt.num(v))
	return {"rows": [[letter, cols.call(s.ts)], ["%s(%s)" % [F, letter], cols.call(s.f)], ["%s(%s)" % [G, letter], cols.call(s.g)],
		["%s′(%s)" % [F, letter], cols.call(s.df)], ["%s′(%s)" % [G, letter], cols.call(s.dg)]]}


## "rising at 2 trucks per hour", for a words question.
static func moving(v: int, what: String, per: String) -> String:
	var word := what
	if absi(v) == 1:
		word = "family" if what == "families" else what.trim_suffix("s")
	return "%s at %d %s per %s" % [rising(float(v)), absi(v), word, per]


func _rule_lines(rep: String, s: Dictionary, st: Dictionary, sign: String) -> Dictionary:
	var a: int = s.a
	var F: String = st.F
	var G: String = st.G
	var H: String = st.H
	var head := "%s(t) is the %s and %s(t) is the %s, t %s after the start." % [F, st.f, G, st.g, st.time]
	var def := "%s(t) = %s(t) %s %s(t) is the %s." % [H, F, sign, G, st.h]
	if rep == "table":
		return {"lines": [head, def, "The table gives their values and rates."], "table": rule_table(s, F, G)}
	var nf: int = DerivativeModelSituation.at(s.f, s)
	var ng: int = DerivativeModelSituation.at(s.g, s)
	return {"lines": [head, def, "When t = %d, %s = %d, %s; %s = %d, %s." % [a, F, nf, moving(DerivativeModelSituation.at(s.df, s), st.fu, st.per),
		G, ng, moving(DerivativeModelSituation.at(s.dg, s), st.gu, st.per)]], "table": null}


func u_product_from_table(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var st: Dictionary = PRODUCT_STORIES[s.story]
	var a: int = s.a
	var f := DerivativeModelSituation.at(s.f, s)
	var g := DerivativeModelSituation.at(s.g, s)
	var df := DerivativeModelSituation.at(s.df, s)
	var dg := DerivativeModelSituation.at(s.dg, s)
	var r := df * g + f * dg
	var ans := exact_answer("%s′(%d) = " % [st.H, a], r, " %s per %s" % [st.hu, st.per])
	var out := _rule_lines(rep, s, st, "×")
	out.asked = "Find the rate of change of the %s when t = %d, in %s per %s." % [st.h, a, st.hu, st.per]
	out.answer = ans
	out.wrongs = [wrong({"v": Q.new(df * dg)}, R_PRODUCT), wrong({"v": Q.new(df * dg + f * dg)}, R_DERIV_READ), wrong({"v": Q.new(f * g)}, R_VALUE)]
	out.generic = gx([df * g - f * dg, f * dg - df * g, r + 10, r - 10])
	out.methods = {"rule-then-substitute": method(["The product rule: %s′ = %s′%s + %s%s′." % [st.H, st.F, st.G, st.F, st.G],
		"At t = %d: %s = %d, %s = %d, %s′ = %s and %s′ = %s." % [a, st.F, f, st.G, g, st.F, Fmt.num(df), st.G, Fmt.num(dg)],
		"%s′(%d) = %s × %s + %s × %s = %s." % [st.H, a, paren(df), paren(g), paren(f), paren(dg), Fmt.num(r)], Answer.text(ans)], ans.values)}
	return out


func u_quotient_from_table(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var st: Dictionary = QUOTIENT_STORIES[s.story]
	var a: int = s.a
	var f := DerivativeModelSituation.at(s.f, s)
	var g := DerivativeModelSituation.at(s.g, s)
	var df := DerivativeModelSituation.at(s.df, s)
	var dg := DerivativeModelSituation.at(s.dg, s)
	var r: Q = DerivativeModelSituation.quotient(f, g, df, dg)
	var ans := exact_answer("%s′(%d) = " % [st.H, a], r, " %s per %s" % [st.hu, st.per])
	var out := _rule_lines(rep, s, st, "÷")
	out.asked = "Find the rate of change of the %s when t = %d, in %s per %s." % [st.h, a, st.hu, st.per]
	out.answer = ans
	out.wrongs = [wrong({"v": Q.new(df, dg)}, R_DIVIDE), wrong({"v": r.neg()}, R_ORDER), wrong({"v": Q.new(df * g - f * dg, g)}, "")]
	out.generic = gx([r.add(1), r.sub(1), r.mul(2)])
	out.methods = {"rule-then-substitute": method(["The quotient rule: %s′ = (%s′%s − %s%s′)/%s²." % [st.H, st.F, st.G, st.F, st.G, st.G],
		"At t = %d: %s = %d, %s = %d, %s′ = %s and %s′ = %s." % [a, st.F, f, st.G, g, st.F, Fmt.num(df), st.G, Fmt.num(dg)],
		"%s′(%d) = (%s × %s − %s × %s)/%s² = %s." % [st.H, a, paren(df), paren(g), paren(f), paren(dg), paren(g), D(r)], Answer.text(ans)], ans.values)}
	return out


func u_chain_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b := DerivativeModelSituation.at(s.g, s)
	var c := DerivativeModelSituation.at(s.dg, s)
	var fb: int = s.df[b - 1]
	var r := fb * c
	var ans := exact_answer("h′(%d) = " % a, r)
	return {"lines": ["h(x) = f(g(x)). The table gives values of f, g and their derivatives."], "table": rule_table(s, "f", "g", "x"),
		"asked": "Find h′(%d)." % a, "answer": ans,
		"wrongs": [wrong({"v": Q.new(s.df[a - 1] * c)}, R_INPUT), wrong({"v": Q.new(s.df[c - 1] * c)}, R_DERIV_READ), wrong({"v": Q.new(fb)}, R_NO_INNER)],
		"generic": gx([-r, r + 2, r - 2]),
		"methods": {"rule-then-substitute": method(["The chain rule: h′(x) = f′(g(x)) × g′(x).", "From the table, g(%d) = %d and g′(%d) = %d." % [a, b, a, c],
			"So h′(%d) = f′(%d) × %d = %s × %d = %s." % [a, b, c, paren(fb), c, Fmt.num(r)], Answer.text(ans)], ans.values)}}


## The outer function as the question writes h, and h′ as the rule writes it.
static func composite_text(s: Dictionary) -> Dictionary:
	match s.form:
		"exp":
			return {"h": "%se^(%sg(t))" % [D(s.A), D(s.c)], "dh": "%se^(%sg(t)) × g′(t)" % [D(s.A.mul(s.c)), D(s.c)]}
		"ln":
			return {"h": "%s ln(g(t))" % D(s.A), "dh": "%s/g(t) × g′(t)" % D(s.A)}
	return {"h": "%s√(g(t))" % D(s.A), "dh": "%s/(2√(g(t))) × g′(t)" % D(s.A)}


func u_composite_with_model(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var g := DerivativeModelSituation.at(s.g, s)
	var dg := DerivativeModelSituation.at(s.dg, s)
	var r := DerivativeModelSituation.composite(s, g, dg)
	var ans := sf_answer("h′(%d) = " % a, r)
	var txt := composite_text(s)
	var table := {"rows": [["t", s.ts.map(func(v): return Fmt.num(v))], ["g(t)", s.g.map(func(v): return Fmt.num(v))], ["g′(t)", s.dg.map(func(v): return Fmt.num(v))]]}
	var slips: Array = [wv(DerivativeModelSituation.composite(s, a, dg), R_INPUT), wv(DerivativeModelSituation.composite(s, g, 1.0), R_NO_INNER)]
	if dg > 0:
		slips.append(wv(DerivativeModelSituation.composite(s, dg, dg), R_DERIV_READ))
	return {"lines": ["h(t) = %s. The table gives values of g and g′." % txt.h], "table": table, "asked": "Find h′(%d), to 3 s.f." % a, "answer": ans, "wrongs": slips,
		"generic": gv([-r, r * 2.0, r * 0.5, r * 1.5]),
		"methods": {"rule-then-substitute": method(["The chain rule: h′(t) = %s." % txt.dh, "From the table, g(%d) = %d and g′(%d) = %s." % [a, g, a, Fmt.num(dg)],
			"Substitute: h′(%d) = %s." % [a, GdcKit.W(r)], Answer.text(ans)], ans.values)}}


func u_rising_from_table(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var st: Dictionary = PRODUCT_STORIES[s.story]
	var a: int = s.a
	var f := DerivativeModelSituation.at(s.f, s)
	var g := DerivativeModelSituation.at(s.g, s)
	var df := DerivativeModelSituation.at(s.df, s)
	var dg := DerivativeModelSituation.at(s.dg, s)
	var r := df * g + f * dg
	var rf := float(r)
	var u: String = "%s per %s" % [st.hu, st.per]
	var word := rising(rf)
	var other := rising(-rf)
	var right := "%s at %d %s" % [word.capitalize(), absi(r), u]
	var slip := df * dg
	var built := claims(right, [["%s at %d %s" % [other.capitalize(), absi(slip), u], R_PRODUCT],
		["%s at %d %s" % [word.capitalize(), f * g, u], R_VALUE],
		["%s at %d %s" % [other.capitalize(), absi(r), u], R_SIGN if r < 0 else ""]])
	var out := _rule_lines(rep, s, st, "×")
	out.asked = "When t = %d, which way is the %s going, and how fast?" % [a, st.h]
	out.answer = built.answer
	out.wrongs = built.wrongs
	out.generic = []
	var sum := "%s′(%d) = %s × %s + %s × %s = %s." % [st.H, a, paren(df), paren(g), paren(f), paren(dg), Fmt.num(r)]
	out.methods = {"rule-then-substitute": method(["The product rule: %s′ = %s′%s + %s%s′." % [st.H, st.F, st.G, st.F, st.G], sum, right], built.answer.values),
		"sign-direction": method([sum, "It is %s, so the total is %s." % ["positive" if r > 0 else "negative", word], right], built.answer.values)}
	return out


## f and g as straight pieces, with the name of each by its last point.
static func pieces_graph(s: Dictionary) -> Dictionary:
	var line := func(vs: Array) -> Array:
		var out: Array = []
		for i in 4:
			out.append([float(i * 2), float(vs[i])])
		return out
	var top: float = 0.0
	for v in s.fv + s.gv:
		top = maxf(top, v)
	var g := Plot.spec([line.call(s.fv), line.call(s.gv)], [[6.0, float(s.fv[3]), "f"], [6.0, float(s.gv[3]), "g"]], 0, 7, 0, ceili(top) + 1)
	return g


## What the working reads off the two graphs at x = a.
static func read_lines(a: int, f: int, g: int, df: int, dg: int) -> Array:
	return ["At x = %d read the heights: f(%d) = %d and g(%d) = %d." % [a, a, f, a, g],
		"Read the gradient of each piece: f′(%d) = %s and g′(%d) = %s." % [a, Fmt.num(df), a, Fmt.num(dg)]]


func u_product_from_graphs(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var f := DerivativeModelSituation.height(s.fv, a)
	var g := DerivativeModelSituation.height(s.gv, a)
	var df := DerivativeModelSituation.slope(s.fv, a)
	var dg := DerivativeModelSituation.slope(s.gv, a)
	var r := df * g + f * dg
	var ans := exact_answer("h′(%d) = " % a, r)
	return {"lines": ["The graph shows y = f(x) and y = g(x), each made of straight pieces.", "h(x) = f(x)g(x)"], "graph": pieces_graph(s), "asked": "Find h′(%d)." % a, "answer": ans,
		"wrongs": [wrong({"v": Q.new(df * dg)}, R_PRODUCT), wrong({"v": Q.new(df * dg + f * dg)}, R_DERIV_READ), wrong({"v": Q.new(f * g)}, R_VALUE)],
		"generic": gx([df * g - f * dg, r + 2, r - 2, -r]),
		"methods": {"read-from-graphs": method(read_lines(a, f, g, df, dg) + ["The product rule: h′(%d) = %s × %s + %s × %s = %s." % [a, paren(df), paren(g), paren(f), paren(dg), Fmt.num(r)], Answer.text(ans)], ans.values)}}


func u_quotient_from_graphs(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var f := DerivativeModelSituation.height(s.fv, a)
	var g := DerivativeModelSituation.height(s.gv, a)
	var df := DerivativeModelSituation.slope(s.fv, a)
	var dg := DerivativeModelSituation.slope(s.gv, a)
	var r: Q = DerivativeModelSituation.quotient(f, g, df, dg)
	var ans := exact_answer("h′(%d) = " % a, r)
	return {"lines": ["The graph shows y = f(x) and y = g(x), each made of straight pieces.", "h(x) = f(x)/g(x)"], "graph": pieces_graph(s), "asked": "Find h′(%d)." % a, "answer": ans,
		"wrongs": [wrong({"v": Q.new(df, dg)}, R_DIVIDE), wrong({"v": r.neg()}, R_ORDER)], "generic": gx([r.add(1), r.sub(1), r.mul(2), r.add(2)]),
		"methods": {"read-from-graphs": method(read_lines(a, f, g, df, dg) + ["The quotient rule: h′(%d) = (%s × %s − %s × %s)/%s² = %s." % [a, paren(df), paren(g), paren(f), paren(dg), paren(g), D(r)], Answer.text(ans)], ans.values)}}


func u_chain_from_graphs(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b := DerivativeModelSituation.height(s.gv, a)
	var c := DerivativeModelSituation.slope(s.gv, a)
	var fb := DerivativeModelSituation.slope(s.fv, b)
	var fa := DerivativeModelSituation.slope(s.fv, a)
	var r := fb * c
	var ans := exact_answer("h′(%d) = " % a, r)
	return {"lines": ["The graph shows y = f(x) and y = g(x), each made of straight pieces.", "h(x) = f(g(x))"], "graph": pieces_graph(s), "asked": "Find h′(%d)." % a, "answer": ans,
		"wrongs": [wrong({"v": Q.new(fa * c)}, R_INPUT), wrong({"v": Q.new(fb)}, R_NO_INNER)], "generic": gx([-r, r + 1, r - 1, r + 2]),
		"methods": {"read-from-graphs": method(["At x = %d read g: g(%d) = %d, and its gradient g′(%d) = %s." % [a, a, b, a, Fmt.num(c)],
			"Read the gradient of f where x = %d: f′(%d) = %s." % [b, b, Fmt.num(fb)],
			"The chain rule: h′(%d) = f′(%d) × g′(%d) = %s × %s = %s." % [a, b, a, paren(fb), paren(c), Fmt.num(r)], Answer.text(ans)], ans.values)}}
