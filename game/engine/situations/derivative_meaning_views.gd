class_name DerivativeMeaningViews
extends ExtensionViews
## The views on the `derivative-meaning` situation: one builder per unknown of
## t5-derivative-meaning (FAL-723). Every question is Paper 2, as every bank part is. A
## reading in words is a multiple-choice `claim`; a rate is a number to 3 s.f. with its
## unit; a limit is a typed number, with "does not exist" as a wrong option.
##
## Representations: "equation" (the model or the limit), "words" (a story), "graph" (the
## curve, with the tangent or the gap marked) and "table" (values near the point).

const SI := "SL5.1.interpret-derivative#"
const SL := "SL5.1.estimate-limit#"
const R_VALUE := SI + "0"
const R_SIGN := SI + "1"
const R_UNITS := SI + "2"
const R_DNE := SL + "0"
const R_F_AT_A := SL + "1"
const R_ONE_SIDE := SL + "2"
## Above every plot: the height of the point that breaks a curve at its gap.
const BREAK_Y := 1000000.0

## The stories: sym names the quantity, what says what it is, y its units, per one unit of t.
const CONTEXTS := [
	{"sym": "V", "what": "volume of water in a tank", "y": "litres", "per": "minute", "time": "minutes"},
	{"sym": "H", "what": "temperature of a generator", "y": "°C", "per": "minute", "time": "minutes"},
	{"sym": "R", "what": "radiation reading at a checkpoint", "y": "microsieverts", "per": "hour", "time": "hours"},
	{"sym": "D", "what": "depth of water in a flooded canal", "y": "metres", "per": "hour", "time": "hours"},
	{"sym": "P", "what": "population of a settlement", "y": "people", "per": "year", "time": "years"},
	{"sym": "F", "what": "fuel in a convoy's tanks", "y": "litres", "per": "hour", "time": "hours"},
	{"sym": "L", "what": "length of a vine on the wall", "y": "cm", "per": "day", "time": "days"},
	{"sym": "C", "what": "charge in a battery bank", "y": "kilowatt-hours", "per": "hour", "time": "hours"},
]


func needs() -> Dictionary:
	var out := {}
	for u in ["rate-at-time", "interpret-value", "units-of-rate", "write-in-notation", "compare-rates", "limit-of-model",
			"limit-of-rate", "limit-from-table", "limit-from-graph"]:
		out[u] = {"ask": u}
	return out


## Every cell is Paper 2: every part of this type in the bank is.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = DerivativeMeaningSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func ctx(s: Dictionary) -> Dictionary:
	return CONTEXTS[s.ctx]


## The model as the question writes it: "40 + 75e^(−0.08t)", "20 + 3 sin(0.5t)".
static func model(s: Dictionary) -> String:
	if s.fam == "sin":
		return "%s + %s sin(%st)" % [Fmt.num(s.A), Fmt.num(s.B), Fmt.dec(s.w)]
	var mag: Q = s.B.abs_q()
	return "%s %s %se^(−%st)" % [Fmt.num(s.A), "−" if s.B.sign() < 0 else "+", Fmt.num(mag), Fmt.dec(s.k)]


static func story(s: Dictionary) -> String:
	var c := ctx(s)
	return "The %s, in %s, t %s after the start, is modelled by %s(t) = %s, t ≥ 0." % [c.what, c.y, c.time, c.sym, model(s)]


static func unit(c: Dictionary) -> String:
	return "%s per %s" % [c.y, c.per]


static func rising(r: float) -> String:
	return "increasing" if r > 0.0 else "decreasing"


## A graph of the model on 0 ≤ t ≤ top, with a point at t0 and its tangent.
static func model_graph(s: Dictionary, tangent: bool) -> Dictionary:
	var f := func(t: float) -> float: return DerivativeMeaningSituation.model_y(s, t)
	var top: int = maxi(14, s.t0 + 4)
	var lo := INF
	var hi := -INF
	var pts := GdcKit.curve(f, 0.0, float(top))
	for p in pts:
		lo = minf(lo, p[1])
		hi = maxf(hi, p[1])
	var curves: Array = [pts]
	var y0: float = s.v
	var points: Array = [[float(s.t0), y0, ""]]
	if tangent:
		var r: float = s.r
		var t0: float = s.t0
		var span := minf(2.5, (hi - lo + 1.0) / maxf(absf(r), 0.01) * 0.3)
		curves.append(GdcKit.curve(func(t: float) -> float: return y0 + r * (t - t0), t0 - span, t0 + span))
	var win := GdcKit.window(0.0, float(top), minf(lo, 0.0), hi, 0.0, 0.15)
	var g := Plot.spec(curves, points, 0, top, win[2], win[3])
	g.x_name = "t"
	return g


static func claim(tag: String, text: String) -> Dictionary:
	return {"form": tag, "vals": [], "text": text}


## Options 2 to 4 of a claim, each with the misconception it shows.
static func claim_answer(right: String, wrongs_in: Array) -> Dictionary:
	var ans := Answer.make("claim", claim("right", right))
	var ws: Array = []
	for i in wrongs_in.size():
		ws.append(wrong(claim("w%d" % i, wrongs_in[i][0]), wrongs_in[i][1]))
	return {"answer": ans, "wrongs": ws}


# ── A rate ───────────────────────────────────────────────────

func u_rate_at_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var r: float = s.r
	var ans := Answer.make("number", {"v": GdcKit.qf(r)}, {}, "d%s/dt = " % c.sym, " " + unit(c))
	ans.show = "sf"
	var asked: String = "Find the rate of change of the %s when t = %d, in %s." % [c.what, s.t0, unit(c)]
	var lines: Array = [story(s)]
	if rep == "equation":
		lines = ["%s(t) = %s, t ≥ 0" % [c.sym, model(s)]]
		asked = "Find %s′(%d), to 3 s.f." % [c.sym, s.t0]
		ans.unit = ""
		ans.label = "%s′(%d) = " % [c.sym, s.t0]
	var wr: Array = [wrong({"v": GdcKit.qf(s.v)}, R_VALUE), wrong({"v": GdcKit.qf(-r)}, R_SIGN)]
	return {"lines": lines, "asked": asked, "answer": ans, "wrongs": wr,
		"generic": [{"v": GdcKit.qf(r * 2.0)}, {"v": GdcKit.qf(r * 0.5)}, {"v": GdcKit.qf(r * 1.5)}, {"v": GdcKit.qf(r + 1.0)}],
		"methods": {"units-ratio": method([
			"The rate is the derivative: d%s/dt at t = %d, in %s." % [c.sym, s.t0, unit(c)],
			"GDC, dy/dx at t = %d: %s." % [s.t0, GdcKit.W(r)],
			Answer.text(ans)], ans.values)}}


# ── Reading a rate in words ──────────────────────────────────

func u_interpret_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var r: float = s.r
	var mag := Fmt.sf(absf(r))
	var word := rising(r)
	var other := rising(-r)
	var right := "At t = %d, the %s is %s at %s %s." % [s.t0, c.what, word, mag, unit(c)]
	var built := claim_answer(right, [
		["At t = %d, the %s is %s %s." % [s.t0, c.what, mag, c.y], R_VALUE],
		["At t = %d, the %s is %s at %s %s." % [s.t0, c.what, other, mag, unit(c)], R_SIGN],
		["At t = %d, the %s has %s by %s %s." % [s.t0, c.what, "gone up" if r > 0.0 else "gone down", mag, c.y], R_UNITS]])
	var lines: Array = [story(s), "%s′(%d) = %s, to 3 s.f." % [c.sym, s.t0, Fmt.sf(r)]]
	var out := {"lines": lines, "asked": "Which sentence says what %s′(%d) means here?" % [c.sym, s.t0], "answer": built.answer, "wrongs": built.wrongs, "generic": [],
		"methods": {"units-ratio": method([
			"%s′(t) is d%s/dt, so its units are %s." % [c.sym, c.sym, unit(c)],
			"It is a rate at one instant, not an amount.",
			right], built.answer.values),
		"sign-direction": method([
			"%s′(%d) is %s, so the %s is %s at that moment." % [c.sym, s.t0, "positive" if r > 0.0 else "negative", c.what, word],
			"Its size says how fast: %s %s." % [mag, unit(c)],
			right], built.answer.values),
		"tangent-picture": method([
			"Picture the tangent at t = %d: its gradient is %s." % [s.t0, Fmt.sf(r)],
			"A tangent going %s means the %s is %s." % ["up" if r > 0.0 else "down", c.what, word],
			right], built.answer.values)}}
	if rep == "graph":
		out.graph = model_graph(s, true)
		out.lines = lines + ["The graph shows %s against t, with the tangent at t = %d." % [c.sym, s.t0]]
	return out


func u_units_of_rate(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var right: String = unit(c)
	var built := claim_answer(right, [
		[c.y, R_UNITS],
		["%s per %s" % [c.per + "s", c.y.trim_suffix("s") if c.y.ends_with("s") else c.y], ""],
		["%s per %s²" % [c.y, c.per], ""]])
	return {"lines": ["The %s is %s, in %s, at time t %s." % [c.what, c.sym, c.y, c.time]],
		"asked": "Write down the units of d%s/dt." % c.sym, "answer": built.answer, "wrongs": built.wrongs, "generic": [],
		"methods": {"units-ratio": method([
			"d%s/dt is a change in %s divided by a change in t." % [c.sym, c.sym],
			"So its units are the units of %s per the units of t." % c.sym,
			right], built.answer.values)}}


func u_write_in_notation(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var n: int = s.n
	var mag := absi(n)
	var word := "increasing" if n > 0 else "decreasing"
	var right := "d%s/dt = %s" % [c.sym, Fmt.num(n)]
	var built := claim_answer(right, [
		["%s = %s" % [c.sym, Fmt.num(n)], R_VALUE],
		["d%s/dt = %s" % [c.sym, Fmt.num(-n)], R_SIGN],
		["dt/d%s = %s" % [c.sym, Fmt.num(n)], ""]])
	return {"lines": ["The %s is %s at %d %s." % [c.what, word, mag, unit(c)], "%s is measured in %s, and t in %s." % [c.sym, c.y, c.time]],
		"asked": "Write this using derivative notation.", "answer": built.answer, "wrongs": built.wrongs, "generic": [],
		"methods": {"sign-direction": method([
			"A rate is a derivative, here d%s/dt." % c.sym,
			"%s means it is %s." % [word.capitalize(), "positive" if n > 0 else "negative"],
			right], built.answer.values),
		"units-ratio": method([
			"%s has the units of %s per t, so it is d%s/dt, not %s." % [unit(c), c.sym, c.sym, c.sym],
			"The sign says the direction: %s." % word,
			right], built.answer.values)}}


func u_compare_rates(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var b: float = s.b
	var d: float = s.c
	var bt := Fmt.dec(Q.new(roundi(b * 10.0), 10))
	var dt := Fmt.dec(Q.new(roundi(d * 10.0), 10))
	var faster := "A" if absf(b) > absf(d) else "B"
	var slower := "B" if faster == "A" else "A"
	var move := func(p: float, q: float) -> String:
		return "A is %s and B is %s" % [rising(p), rising(q)]
	var right := "%s, and %s is changing faster." % [move.call(b, d), faster]
	var ignored := "Both are %s, and %s is changing faster." % [rising(-b) if b * d > 0.0 else "increasing", faster]
	var built := claim_answer(right, [
		[ignored, R_SIGN],
		["%s holds more than %s at t = %d." % [faster, slower, s.t0], R_VALUE],
		["%s, and %s is changing faster." % [move.call(b, d), slower], ""]])
	var lines: Array = ["A(t) and B(t) are two quantities, in %s, t %s after the start." % [c.y, c.time],
		"A′(%d) = %s and B′(%d) = %s" % [s.t0, bt, s.t0, dt]]
	var table: Variant = null
	if rep == "table":
		lines = ["A(t) and B(t) are two quantities, in %s, t %s after the start." % [c.y, c.time]]
		table = {"rows": [["", ["A", "B"]], ["rate at t = %d" % s.t0, [bt, dt]]]}
	return {"lines": lines, "table": table, "asked": "Compare the two rates at t = %d. Which sentence is true?" % s.t0, "answer": built.answer, "wrongs": built.wrongs, "generic": [],
		"methods": {"sign-direction": method([
			"The sign of each derivative gives the direction: %s." % move.call(b, d),
			"The size gives the speed: %s is larger in size than %s, so %s is changing faster." % [Fmt.dec(Q.new(roundi(maxf(absf(b), absf(d)) * 10.0), 10)), Fmt.dec(Q.new(roundi(minf(absf(b), absf(d)) * 10.0), 10)), faster],
			right], built.answer.values),
		"tangent-picture": method([
			"Picture each tangent at t = %d: gradients %s and %s." % [s.t0, bt, dt],
			"The steeper tangent, ignoring its direction, belongs to %s." % faster,
			right], built.answer.values)}}


# ── Limits ───────────────────────────────────────────────────

static func limit_ans(v: Q, label: String = "The limit is ") -> Dictionary:
	var ans := DifferentiationViews.form(label + Fmt.num(v), [label, {"slot": "v"}], {"v": v})
	ans.short = Fmt.num(v)
	return ans


static func lim_alt(v: Q, ref: String = "", label: String = "The limit is ") -> Dictionary:
	return DifferentiationViews.alt(label + Fmt.dec(v), ref, {"v": v})


static func dne(ref: String = R_DNE) -> Dictionary:
	return DifferentiationViews.alt("The limit does not exist", ref)


func u_limit_of_model(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var ans := limit_ans(s.A)
	var first: Q = s.A.add(s.B)
	var out := {"lines": ["%s(t) = %s, t ≥ 0" % [c.sym, model(s)]], "asked": "Find the limit of %s(t) as t → ∞." % c.sym, "answer": ans,
		"wrongs": [lim_alt(first, R_F_AT_A), dne()],
		"generic": [lim_alt(Q.new(0)).values, lim_alt(s.B).values, lim_alt(s.A.add(1)).values, lim_alt(s.A.sub(s.B)).values],
		"titles": {"graph-read": "Trace the graph as t grows" if rep == "graph" else "Follow the values as t grows"},
		"methods": {"graph-read": method([
			"Follow the curve to large t: it levels off." if rep == "graph" else "Let t grow large: the values level off.",
			"e^(−%st) gets closer and closer to 0, so the height it levels off at is %s." % [Fmt.dec(s.k), Fmt.num(s.A)],
			Answer.text(ans)], ans.values),
		"table-approach": method([
			"Make a table for large t: t = 100, 200, 300.",
			"The values settle towards %s, because e^(−%st) dies away." % [Fmt.num(s.A), Fmt.dec(s.k)],
			Answer.text(ans)], ans.values)}}
	if rep == "graph":
		out.lines = ["The graph shows %s(t) = %s, t ≥ 0." % [c.sym, model(s)]]
		out.graph = model_graph(s, false)
	elif rep == "table":
		var ts: Array = [10, 20, 40, 80, 160]
		out.lines = ["The table gives %s(t) as t grows." % c.sym]
		out.table = {"rows": [["t", ts.map(func(t): return str(t))], ["%s(t)" % c.sym, ts.map(func(t): return Fmt.sf(DerivativeMeaningSituation.model_y(s, t), 5))]]}
	return out


func u_limit_of_rate(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var ans := limit_ans(Q.new(0))
	var start: Q = s.B.mul(s.k).neg()
	return {"lines": ["%s(t) = %s, t ≥ 0" % [c.sym, model(s)]], "asked": "Find the limit of %s′(t) as t → ∞." % c.sym, "answer": ans,
		"wrongs": [lim_alt(s.A), dne()],
		"generic": [lim_alt(start).values, lim_alt(s.A.add(s.B)).values, lim_alt(s.k.neg()).values, lim_alt(Q.new(1)).values],
		"titles": {"graph-read": "Follow the values as t grows"},
		"methods": {"graph-read": method([
			"%s levels off at large t, so its rate of change dies away." % c.sym,
			"Something that has levelled off has gradient 0, whatever height it levels off at.",
			Answer.text(ans)], ans.values),
		"gdc-table": method([
			"%s′(t) = %s × e^(−%st). Make a table for t = 100, 200, 300." % [c.sym, Fmt.dec(start), Fmt.dec(s.k)],
			"The values shrink towards 0.",
			Answer.text(ans)], ans.values)}}


## "f(x) = (2x² − 2x − 12)/(x − 3)".
static func rational(s: Dictionary) -> String:
	var a: int = s.a
	if s.fam == "cubic":
		var cube: int = a * a * a
		return "f(x) = (x³%s)/(%s)" % [Fmt.plus(-cube), Fmt.poly([1, -a])]
	return "f(x) = (%s)/(%s)" % [Fmt.poly([s.m, -s.m * (a + s.rr), s.m * a * s.rr]), Fmt.poly([1, -a])]


func u_limit_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var xs: Array = [Q.new(a).sub(Q.new(1, 10)), Q.new(a).sub(Q.new(1, 100)), Q.new(a).add(Q.new(1, 100)), Q.new(a).add(Q.new(1, 10))]
	var ys: Array = xs.map(func(x): return DerivativeMeaningSituation.near(s, x))
	var lim := DerivativeMeaningSituation.limit_value(s)
	var ans := limit_ans(lim, "The limit is ")
	var dp: Q = ys[1]
	var table := {"rows": [["x", xs.map(func(x): return Fmt.dec(x))], ["f(x)", ys.map(func(y): return Fmt.dec(y))]]}
	var wr: Array = [dne(), DifferentiationViews.alt("The limit is " + Fmt.dec(dp), R_ONE_SIDE)]
	return {"lines": [rational(s), "f(%s) is not defined. The table gives f(x) close to x = %s." % [Fmt.num(a), Fmt.num(a)]], "table": table,
		"asked": "Estimate the limit of f(x) as x → %s." % Fmt.num(a), "answer": ans, "wrongs": wr,
		"generic": [lim_alt(lim.add(1)).values, lim_alt(lim.sub(1)).values, lim_alt(lim.mul(2)).values, lim_alt(Q.new(a)).values],
		"methods": {"table-approach": method([
			"Read the f(x) row from both ends towards x = %s." % Fmt.num(a),
			"From the left and from the right the values close in on %s." % Fmt.num(lim),
			Answer.text(ans)], ans.values),
		"gdc-table": method([
			"Put f in the GDC's table, with x = %s and %s, closer than the table's." % [Fmt.dec(Q.new(a).sub(Q.new(1, 1000))), Fmt.dec(Q.new(a).add(Q.new(1, 1000)))],
			"Both values are within 0.1 of %s." % Fmt.num(lim),
			Answer.text(ans)], ans.values)}}


func u_limit_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var f := func(x: float) -> float: return s.m * (x - s.rr)
	var lim := DerivativeMeaningSituation.limit_value(s)
	var y: int = s.y
	var left := GdcKit.curve(f, a - 6.0, a - 0.14)
	var right := GdcKit.curve(f, a + 0.14, a + 6.0)
	var lo: float = minf(minf(left[0][1], right[right.size() - 1][1]), y)
	var hi: float = maxf(maxf(left[0][1], right[right.size() - 1][1]), y)
	var ylo := maxi(floori(lo) - 1, lim.n - 8)
	var yhi := mini(ceili(hi) + 1, lim.n + 8)
	var clip := func(c: Array) -> Array:
		return c.filter(func(p): return p[1] >= ylo and p[1] <= yhi)
	# One curve, so one colour: a point off the plot breaks the line (GraphView) and leaves the gap.
	var line: Array = clip.call(left) + [[float(a), BREAK_Y]] + clip.call(right)
	var g := Plot.spec([line], [[float(a), float(y), "(%s, %s)" % [Fmt.num(a), Fmt.num(y)]]], a - 6, a + 6, mini(ylo, 0), maxi(yhi, 0))
	var ans := limit_ans(lim)
	return {"lines": ["The graph of y = f(x) has a gap at x = %s. The dot shows f(%s)." % [Fmt.num(a), Fmt.num(a)]], "graph": g,
		"asked": "Write down the limit of f(x) as x → %s." % Fmt.num(a), "answer": ans,
		"wrongs": [lim_alt(Q.new(y), R_F_AT_A), dne()],
		"generic": [lim_alt(Q.new(a)).values, lim_alt(lim.add(1)).values, lim_alt(lim.sub(1)).values, lim_alt(lim.neg()).values],
		"methods": {"graph-read": method([
			"Trace the curve towards x = %s from both sides; ignore the dot." % Fmt.num(a),
			"The curve heads for the gap at height %s, from the left and from the right." % Fmt.num(lim),
			Answer.text(ans)], ans.values)}}
