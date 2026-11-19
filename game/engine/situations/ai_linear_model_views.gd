class_name AiLinearModelViews
extends ExtensionViews
## The views on the `ai-linear-model` situation (FAL-1001): one builder per unknown of
## fn-ai-piecewise-linear (AI-SL2.5.linear-model, AI-SL2.6.find-parameters). A linear charge: the
## model from its rate and fixed charge (m and c, typed as two numbers), a cost from the model, the
## story or the line drawn, and what its gradient or intercept means (a picked statement). A tariff
## in two pieces (in words, as a rule with its intervals, or drawn with its corner): a cost in
## either piece, the rule for the second piece (a and b of C = ax + b), and the input for a cost.
## A tiered price (a table of bands, or in words): the cost of an order. Two bills on one linear
## tariff (in words or a table): m and c.
##
## Every question is Paper 2, as every AI paper allows a GDC. Money ends in cents and inputs are
## whole, so every answer is exact; a slip's input that doesn't end is shown to 3 s.f.
## `given` holds the situation as plain data.

const R_SWAP := "AI-SL2.5.linear-model#0"
const R_WHOLE := "AI-SL2.5.linear-model#2"
const R_CORNER := "AI-SL2.5.linear-model#3"
const R_XY := "AI-SL2.6.find-parameters#1"
const T := "fn-ai-piecewise-linear#"
const R_EXCESS := T + "4"
const R_NEIGHBOUR := T + "5"
const R_OTHER := T + "6"
const S := preload("res://engine/situations/ai_linear_model.gd")
const UNKNOWNS := ["build-from-rate-start", "evaluate-model", "interpret-gradient", "piecewise-value", "piecewise-rule",
	"piecewise-input", "tier-band", "two-bills"]

## What each linear context's input is, after "where x is".
const MEANS := {"van": "the number of days of hire", "plumber": "the time worked, in hours", "taxi": "the distance travelled, in km",
	"power": "the electricity used in the month, in kWh", "gym": "the number of classes", "print": "the number of posters printed"}
## What the cost is of, for a linear context.
const COST_OF := {"van": "hiring the van", "plumber": "a job", "taxi": "a trip", "power": "a month's electricity",
	"gym": "a membership", "print": "a print job"}
## The tariff in words, for each two-piece context: %c, %m1, %m2, %x0.
const PIECE_STORY := {
	"data": "A phone plan costs %c a month, which includes %x0 GB of data. Each GB used over %x0 GB costs %m2.",
	"parking": "A car park charges %c for a stay of up to %x0 hours. Each hour after that costs %m2.",
	"courier": "A courier charges %c to send a parcel of up to %x0 kg, plus %m2 for each kg over %x0 kg.",
	"water": "A water company charges a fixed %c a quarter, plus %m1 for each m³ of the first %x0 m³ used and %m2 for each m³ after that.",
	"taxi": "A taxi charges a fixed %c, plus %m1 for each km of the first %x0 km and %m2 for each km after that.",
	"power": "An electricity plan charges a fixed %c a month, plus %m1 for each kWh of the first %x0 kWh and %m2 for each kWh after that.",
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
	out.given = S.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## An amount of money as the stem writes it: "$40", "$2.50".
static func cash(v: Variant) -> String:
	return "$" + Fmt.money(v)


## An amount with its cents always: "22.00", for a price table.
static func cents2(v: Variant) -> String:
	var c := roundi(Q.of(v).to_float() * 100.0)
	return "%d.%02d" % [c / 100, c % 100]


## A number in a product, bracketed when negative.
static func B(v: Variant) -> String:
	return "(%s)" % D(v) if Q.of(v).sign() < 0 else D(v)


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func line_ctx(s: Dictionary) -> Dictionary:
	return S.LINES[s.ctx]


static func piece_ctx(s: Dictionary) -> Dictionary:
	return S.PIECES[s.ctx]


static func tier_ctx(s: Dictionary) -> Dictionary:
	return S.TIERS[s.ctx]


static func units(n: Variant, one: String, many: String) -> String:
	return "%s %s" % [D(n), one if Q.of(n).eq(1) else many]


static func money_ans(label: String, v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	ans.show = "money"
	ans.exact = true
	return ans


static func exact_ans(label: String, v: Q, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label, unit)
	ans.show = "dec"
	ans.exact = true
	return ans


## Two numbers typed: m and c, or a and b.
static func two(names: Array, p: Q, q: Q) -> Dictionary:
	var ans := Answer.make("named", {"v0": p, "v1": q}, {"names": names})
	ans.show = "dec"
	ans.exact = true
	return ans


static func pq(p: Q, q: Q) -> Dictionary:
	return {"v0": p, "v1": q}


## A value for an exact answer's option: as it is when it ends, else to 3 s.f.
static func ends_or_sf(v: Q) -> Q:
	return v if not D(v).contains("/") else GraphReadingSituation.sf_q(v, 3)


static func pack(lines: Array, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary,
		graph: Variant = null, table: Variant = null) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {},
		"graph": graph, "table": table}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


# ── A linear charge ──────────────────────────────────────────

static func model(s: Dictionary) -> String:
	return "C = " + Fmt.terms([s.m, s.c], [1, 0], line_ctx(s).x, true)


static func gdc_line(s: Dictionary) -> String:
	return "y = " + Fmt.terms([s.m, s.c], [1, 0], "x", true)


static func line_story(s: Dictionary) -> String:
	return line_ctx(s).story.replace("%c", cash(s.c)).replace("%m", cash(s.m))


## "where C is the cost in dollars and d is the number of days of hire"
static func line_where(s: Dictionary) -> String:
	var c := line_ctx(s)
	return "where C is the cost in dollars and %s is %s" % [c.x, MEANS[c.id]]


## The line from x = 0, with (0, c) and the second point marked.
static func line_graph(s: Dictionary) -> Dictionary:
	var c := line_ctx(s)
	var top: int = int(ceil(maxf(float(s.xg), float(s.x)) * 1.2))
	var y_top: float = s.m.mul(top).add(s.c).to_float()
	var pts := [[0.0, s.c.to_float(), "(0, %s)" % D(s.c)], [float(s.xg), s.yg.to_float(), "(%d, %s)" % [s.xg, D(s.yg)]]]
	var g := Plot.spec([[[0.0, s.c.to_float()], [float(top), y_top]]], pts, 0, top, 0, Plot.nice_top(y_top))
	g.x_name = c.x
	g.y_name = "C"
	return g


func u_build_from_rate_start(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := line_ctx(s)
	var ans := two(["m", "c"], s.m, s.c)
	var asked := "Write down a model for the cost C dollars in the form C = m%s + c, where %s is %s. Give m and c." % [c.x, c.x, MEANS[c.id]]
	return pack([line_story(s)], asked, ans, [wrong(pq(s.c, s.m), R_SWAP)], [pq(s.m, s.c.mul(2)), pq(s.m.mul(2), s.c)], {
		"rate-and-start": ["The charge for each %s is the rate, the gradient: m = %s." % [c.each, D(s.m)],
			"The %s is paid even %s: it is C when %s = 0, the intercept, so c = %s." % [c.fee, c.none, c.x, D(s.c)], say(ans)],
	})


func u_evaluate_model(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := line_ctx(s)
	var ans := money_ans("C = $", s.y)
	var lines: Array
	var graph: Variant = null
	match rep:
		"graph":
			lines = ["The graph shows the cost C dollars of %s against %s, %s." % [COST_OF[c.id], c.x, MEANS[c.id]]]
			graph = line_graph(s)
		"words":
			lines = [line_story(s)]
		_:
			lines = ["The cost of %s is modelled by %s, %s." % [COST_OF[c.id], model(s), line_where(s)]]
	var asked := "Find the cost C, in dollars, when %s = %d." % [c.x, s.x]
	if rep == "words":
		asked = "Find the cost C, in dollars, when %s = %d, where %s is %s." % [c.x, s.x, c.x, MEANS[c.id]]
	var calc := "C = %s × %d + %s = %s." % [D(s.m), s.x, D(s.c), D(s.y)]
	var steps := {}
	if rep == "graph":
		var rise := "(%s − %s)/%d = %s" % [D(s.yg), D(s.c), s.xg, D(s.m)]
		steps["rate-and-start"] = ["The line meets the C-axis at (0, %s), so c = %s, and from there to (%d, %s) it rises %s for each %s, so m = %s." % [D(s.c), D(s.c), s.xg, D(s.yg), rise, c.one, D(s.m)],
			calc, say(ans)]
		steps["read-graph"] = ["Go up from %s = %d to the line, then across to the C-axis." % [c.x, s.x],
			"The line rises %s for each %s from (0, %s), so the reading is %s + %s × %d = %s." % [rise, c.one, D(s.c), D(s.c), D(s.m), s.x, D(s.y)], say(ans)]
	else:
		var first := "The model is %s." % model(s) if rep == "equation" else "The rate is %s for each %s and the %s is %s, so %s." % [cash(s.m), c.each, c.fee, cash(s.c), model(s)]
		steps["rate-and-start"] = [first, calc, say(ans)]
		steps["read-graph"] = ["Graph %s on the GDC, with x for %s and y for C." % [gdc_line(s), c.x],
			"Trace along the line to x = %d: y = %s." % [s.x, D(s.y)], say(ans)]
	var half := GraphReadingSituation.dp_q(s.y.mul(Q.new(3, 2)), 2)
	return pack(lines, asked, ans, [wrong({"v": s.c.mul(s.x).add(s.m)}, R_SWAP)], [{"v": s.y.mul(2)}, {"v": half}], steps, graph)


static func rate_says(s: Dictionary, v: Q) -> String:
	return "The cost goes up by %s for each extra %s" % [cash(v), line_ctx(s).each]


static func start_says(s: Dictionary, v: Q) -> String:
	var c := line_ctx(s)
	return "%s is the %s, paid even %s" % [cash(v), c.fee, c.none]


func u_interpret_gradient(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := line_ctx(s)
	var is_m: bool = s.part == "m"
	var v: Q = s.m if is_m else s.c
	var right: String = rate_says(s, v) if is_m else start_says(s, v)
	var other: String = start_says(s, v) if is_m else rate_says(s, v)
	var built := SamplingViews.claims(right, [[other, R_OTHER], ["%s is the total cost, whatever the value of %s" % [cash(v), c.x], ""],
		["%s is the most the cost can ever be" % cash(v), ""]])
	var lines: Array = [line_story(s), "The model is %s, %s." % [model(s), line_where(s)]] if rep == "words" else ["The cost of %s is modelled by %s, %s." % [COST_OF[c.id], model(s), line_where(s)]]
	var asked := "What does the %s in the model mean, in context?" % D(v)
	var why: String
	if is_m:
		why = "In %s, %s multiplies %s: it is the gradient, the change in C for each 1 added to %s, in dollars per %s." % [model(s), D(s.m), c.x, c.x, c.one]
	else:
		why = "In %s, %s is the intercept: the value of C when %s = 0, %s." % [model(s), D(s.c), c.x, c.none]
	return pack(lines, asked, built.answer, built.wrongs, built.fillers, {"rate-and-start": [why, "So: " + right + "."]})


# ── Two bills ────────────────────────────────────────────────

func u_two_bills(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := line_ctx(s)
	var ans := two(["m", "c"], s.m, s.c)
	var lines: Array = ["The cost of %s follows one linear model, C = m%s + c, %s." % [COST_OF[c.id], c.x, line_where(s)]]
	var table: Variant = null
	if rep == "table":
		lines.append("The table shows two bills.")
		table = {"rows": [[c.x, [str(s.x1), str(s.x2)]], ["C ($)", [cents2(s.y1), cents2(s.y2)]]]}
	else:
		lines.append("A bill for %s is %s, and a bill for %s is %s." % [units(s.x1, c.one, c.many), "$" + cents2(s.y1), units(s.x2, c.one, c.many), "$" + cents2(s.y2)])
	var asked := "Find the rate m and the fixed charge c."
	var e1 := "%s%s + c = %s" % [s.x1, "m", D(s.y1)]
	var e2 := "%s%s + c = %s" % [s.x2, "m", D(s.y2)]
	var dx: int = s.x2 - s.x1
	var dy: Q = s.y2.sub(s.y1)
	var inv := Q.new(1).div(s.m)
	var fill: Array = [pq(dy, s.c), pq(s.m, s.y1)]
	return pack(lines, asked, ans, [wrong(pq(s.c, s.m), R_SWAP), wrong(pq(inv, s.c.neg().div(s.m)), R_XY)], fill, {
		"two-points": ["The bills are the points (%d, %s) and (%d, %s) on the line." % [s.x1, D(s.y1), s.x2, D(s.y2)],
			"m = (%s − %s)/(%d − %d) = %s." % [D(s.y2), D(s.y1), s.x2, s.x1, D(s.m)],
			"c = %s − %s × %d = %s." % [D(s.y1), D(s.m), s.x1, D(s.c)], say(ans)],
		"simultaneous-gdc": ["Each bill gives an equation: %s and %s." % [e1, e2],
			"Enter them in the GDC's simultaneous equation solver, with m and c as the unknowns: it gives m = %s and c = %s." % [D(s.m), D(s.c)], say(ans)],
		"eliminate": ["Each bill gives an equation: %s and %s." % [e1, e2],
			"Take the first from the second: %dm = %s, so m = %s." % [dx, D(dy), D(s.m)],
			"Put m = %s into the first: c = %s − %s = %s." % [D(s.m), D(s.y1), D(s.m.mul(s.x1)), D(s.c)], say(ans)],
	}, null, table)


# ── A tariff in two pieces ───────────────────────────────────

static func piece_story(s: Dictionary) -> String:
	var t: String = PIECE_STORY[piece_ctx(s).id]
	return t.replace("%c", cash(s.c)).replace("%m1", cash(s.m1)).replace("%m2", cash(s.m2)).replace("%x0", str(s.x0))


## The first piece's right side: "20", "25 + 1.45w".
static func p1(s: Dictionary, x: String = "") -> String:
	var v: String = piece_ctx(s).x if x == "" else x
	return D(s.c) if s.m1.is_zero() else "%s + %s%s" % [D(s.c), D(s.m1), v]


## The second piece's right side: "20 + 4.5(g − 5)".
static func p2(s: Dictionary, x: String = "") -> String:
	var v: String = piece_ctx(s).x if x == "" else x
	return "%s + %s(%s − %d)" % [D(s.c0), D(s.m2), v, s.x0]


static func piece_where(s: Dictionary) -> String:
	var c := piece_ctx(s)
	return "where C is the cost in dollars and %s is %s" % [c.x, c.what]


## The tariff drawn: the two pieces joined at the corner, with the start, the corner and a later
## point marked.
static func piece_graph(s: Dictionary) -> Dictionary:
	var c := piece_ctx(s)
	var top: int = int(ceil(float(s.xe) * 1.12))
	var y_top: float = s.ye.to_float()
	var pts := [[0.0, s.c.to_float(), "(0, %s)" % D(s.c)], [float(s.x0), s.c0.to_float(), "(%d, %s)" % [s.x0, D(s.c0)]],
		[float(s.xe), y_top, "(%d, %s)" % [s.xe, D(s.ye)]]]
	var curve := [[0.0, s.c.to_float()], [float(s.x0), s.c0.to_float()], [float(s.xe), y_top]]
	var g := Plot.spec([curve], pts, 0, top, 0, Plot.nice_top(y_top))
	g.x_name = c.x
	g.y_name = "C"
	return g


## ", where g is the data used, in GB": the input's letter, said where only words show the tariff.
static func piece_def(s: Dictionary, rep: String) -> String:
	return ", where %s is %s" % [piece_ctx(s).x, piece_ctx(s).what] if rep == "words" else ""


## The lines a tariff question shows, by representation.
static func piece_lines(s: Dictionary, rep: String) -> Array:
	var c := piece_ctx(s)
	match rep:
		"graph":
			return ["The graph shows the cost C dollars against %s, %s. It is made of two straight pieces." % [c.x, c.what]]
		"equation":
			return ["The cost is given by the rule below, %s." % piece_where(s),
				"C = %s, for 0 ≤ %s ≤ %d" % [p1(s), c.x, s.x0], "C = %s, for %s > %d" % [p2(s), c.x, s.x0]]
	return [piece_story(s)]


## The second piece's rate as the graph shows it: "(65 − 20)/(15 − 5) = 4.5".
static func rise2(s: Dictionary) -> String:
	return "(%s − %s)/(%d − %d) = %s" % [D(s.ye), D(s.c0), s.xe, s.x0, D(s.m2)]


## The first piece's rate as the graph shows it.
static func rise1(s: Dictionary) -> String:
	return "(%s − %s)/%d = %s" % [D(s.c0), D(s.c), s.x0, D(s.m1)]


## Where the second piece starts, worked from the tariff: "at w = 30, C = 25 + 1.45 × 30 = 68.5".
static func corner(s: Dictionary) -> String:
	var x: String = piece_ctx(s).x
	if s.m1.is_zero():
		return "at %s = %d, C = %s" % [x, s.x0, D(s.c0)]
	return "at %s = %d, C = %s + %s × %d = %s" % [x, s.x0, D(s.c), D(s.m1), s.x0, D(s.c0)]


## Both pieces, as the graph's points or the tariff give them.
static func both_pieces(s: Dictionary, rep: String) -> String:
	var x: String = piece_ctx(s).x
	var pieces := "piece 1 is C = %s for 0 ≤ %s ≤ %d, and piece 2 is C = %s for %s > %d" % [p1(s), x, s.x0, p2(s), x, s.x0]
	match rep:
		"graph":
			var r1 := "level at %s" % D(s.c) if s.m1.is_zero() else "rising %s" % rise1(s)
			return "From the graph: piece 1 starts at (0, %s), %s per %s to (%d, %s); piece 2 rises %s per %s. So %s." % [D(s.c), r1, piece_ctx(s).one, s.x0, D(s.c0), rise2(s), piece_ctx(s).one, pieces]
		"equation":
			return "The rule's pieces: %s." % pieces
	return "From the tariff, %s: %s." % [corner(s), pieces]


func u_piecewise_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := piece_ctx(s)
	var x: String = c.x
	var first: bool = s.x <= s.x0
	var ans := money_ans("C = $", s.y)
	var whole: Q = s.c.add(s.m2.mul(s.x))
	var other: Q = s.c.add(s.m1.mul(s.x)) if not first else s.c0.add(s.m2.mul(s.x - s.x0))
	var wr: Array = [wrong({"v": whole}, R_WHOLE), wrong({"v": other}, R_CORNER)]
	var asked := "Find the cost C, in dollars, when %s = %d%s." % [x, s.x, piece_def(s, rep)]
	var calc1 := "C = %s + %s × %d = %s." % [D(s.c), D(s.m1), s.x, D(s.y)] if not s.m1.is_zero() else "C = %s." % D(s.y)
	var calc2 := "C = %s + %s × (%d − %d) = %s." % [D(s.c0), D(s.m2), s.x, s.x0, D(s.y)]
	var calc := calc1 if first else calc2
	var where := "%s = %d is in piece 1, since %d ≤ %d." % [x, s.x, s.x, s.x0] if first else "%s = %d is in piece 2, since %d > %d." % [x, s.x, s.x, s.x0]
	var rs: String
	if rep == "graph":
		if first:
			rs = "From the graph, the first piece starts at (0, %s) and %s." % [D(s.c), "is level" if s.m1.is_zero() else "rises %s per %s" % [rise1(s), c.one]]
		else:
			rs = "From the graph, the second piece starts at the corner (%d, %s) and rises %s per %s." % [s.x0, D(s.c0), rise2(s), c.one]
	elif first:
		rs = "%s = %d is within the first %d %s: the start is %s and the rate there is %s per %s." % [x, s.x, s.x0, c.many, cash(s.c), cash(s.m1), c.one]
	else:
		rs = "The second piece starts %s; past %d %s each %s adds %s, and %d is %d − %d = %d past it." % [corner(s), s.x0, c.many, c.one, cash(s.m2), s.x, s.x, s.x0, s.x - s.x0]
	var steps := {
		"rate-and-start": [rs, calc, say(ans)],
		"piece-by-piece": [both_pieces(s, rep), where, calc, say(ans)],
	}
	if rep == "graph":
		var reading: String
		if first:
			reading = "The first piece is level at C = %s, so the reading across is %s." % [D(s.c), D(s.y)] if s.m1.is_zero() else "The first piece rises %s per %s from (0, %s), so the reading across on the C-axis is %s + %s × %d = %s." % [rise1(s), c.one, D(s.c), D(s.c), D(s.m1), s.x, D(s.y)]
		else:
			reading = "The second piece rises %s per %s from (%d, %s), so the reading across on the C-axis is %s + %s × (%d − %d) = %s." % [rise2(s), c.one, s.x0, D(s.c0), D(s.c0), D(s.m2), s.x, s.x0, D(s.y)]
		steps["read-graph"] = ["Go up from %s = %d to the graph: it meets the %s piece, %s the corner at (%d, %s)." % [x, s.x, "first" if first else "second", "before" if first else "past", s.x0, D(s.c0)], reading, say(ans)]
	else:
		steps["read-graph"] = ["Graph the tariff on the GDC: y = %s for 0 ≤ x ≤ %d, and y = %s for x > %d." % [p1(s, "x"), s.x0, p2(s, "x"), s.x0],
			"Trace to x = %d, on the %s piece: y = %s." % [s.x, "first" if first else "second", D(s.y)], say(ans)]
	return pack(piece_lines(s, rep), asked, ans, wr, [{"v": s.y.mul(2)}], steps, piece_graph(s) if rep == "graph" else null)


func u_piecewise_rule(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := piece_ctx(s)
	var x: String = c.x
	var b: Q = s.c0.sub(s.m2.mul(s.x0))
	var ans := two(["a", "b"], s.m2, b)
	var asked := "Find the rule for the cost when %s > %d, in the form C = a%s + b%s. Give a and b." % [x, s.x0, x, piece_def(s, rep)]
	var form := Fmt.terms([s.m2, b], [1, 0], x, true)
	var pts: String
	var xb: int
	var yb: Q
	if rep == "graph":
		xb = s.xe
		yb = s.ye
		pts = "Two points on the second piece, from the graph: (%d, %s) and (%d, %s)." % [s.x0, D(s.c0), s.xe, D(s.ye)]
	else:
		xb = s.x1
		yb = s.y1
		pts = "Two points on the second piece: %s; at %s = %d, C = %s + %s × %d = %s." % [corner(s), x, s.x1, D(s.c0), D(s.m2), s.x1 - s.x0, D(s.y1)]
	var start: String
	if rep == "graph":
		start = "From the graph, the second piece starts at (%d, %s) and rises %s per %s: C = %s." % [s.x0, D(s.c0), rise2(s), c.one, p2(s)]
	else:
		start = "Past %s = %d the cost is the cost there plus %s for each %s over %d; %s, so C = %s." % [x, s.x0, D(s.m2), c.one, s.x0, corner(s), p2(s)]
	return pack(piece_lines(s, rep), asked, ans, [wrong(pq(s.m2, s.c), R_WHOLE)], [pq(s.m2, b.neg()), pq(s.m2, s.c0.add(s.m2.mul(s.x0)))], {
		"two-points": [pts, "a = (%s − %s)/(%d − %d) = %s." % [D(yb), D(s.c0), xb, s.x0, D(s.m2)],
			"b = %s − %s × %d = %s." % [D(s.c0), D(s.m2), s.x0, D(b)], say(ans)],
		"piece-by-piece": [start, "Expand: C = %s%s − %s × %d = %s." % [D(s.m2), x + " + " + D(s.c0), D(s.m2), s.x0, form], say(ans)],
	}, piece_graph(s) if rep == "graph" else null)


func u_piecewise_input(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := piece_ctx(s)
	var x: String = c.x
	var ans := exact_ans("%s = " % x, Q.new(s.x), " " + c.many)
	var wr: Array = [wrong({"v": ends_or_sf(s.y.sub(s.c).div(s.m2))}, R_WHOLE)]
	if not s.m1.is_zero():
		wr.append(wrong({"v": ends_or_sf(s.y.sub(s.c).div(s.m1))}, R_CORNER))
	var asked := "Find %s when the cost is %s%s." % [x, "$" + cents2(s.y), piece_def(s, rep)]
	var at0 := "The cost at %s = %d is %s" % [x, s.x0, D(s.c0)]
	if rep == "words" and not s.m1.is_zero():
		at0 = "The cost at %s = %d is %s + %s × %d = %s" % [x, s.x0, D(s.c), D(s.m1), s.x0, D(s.c0)]
	var ex: Q = s.y.sub(s.c0).div(s.m2)
	return pack(piece_lines(s, rep), asked, ans, wr, [{"v": Q.new(s.x * 2)}, {"v": Q.new(s.x + s.x0)}], {
		"piece-by-piece": ["%s, and %s > %s, so %s is past %d: use C = %s." % [at0, D(s.y), D(s.c0), x, s.x0, p2(s)],
			"%s = %s, so %s − %d = (%s − %s)/%s = %s." % [p2(s), D(s.y), x, s.x0, D(s.y), D(s.c0), D(s.m2), D(ex)],
			"%s = %d + %s = %d." % [x, s.x0, D(ex), s.x], say(ans)],
	})


# ── A tiered price ───────────────────────────────────────────

## A band's edges in words: "20 to 49", "50 or more".
static func band_text(s: Dictionary, b: int) -> String:
	return "%d or more" % s.edges[b] if b == s.edges.size() - 1 else "%d to %d" % [s.edges[b], s.edges[b + 1] - 1]


func u_tier_band(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := tier_ctx(s)
	var k: int = s.band
	var rate: Q = s.rates[k]
	var key: Q = rate.mul(s.n)
	var ans := money_ans("cost = $", key)
	var lines: Array = ["A supplier sells %s. The price of each %s is set by the size of the order, and that price is paid for every %s in the order." % [c.what, c.item, c.item]]
	var table: Variant = null
	if rep == "table":
		lines.append("The table shows the price for each size of order.")
		var sizes: Array = []
		for b in s.edges.size():
			sizes.append(band_text(s, b))
		table = {"rows": [["%s in the order" % (c.items.left(1).to_upper() + c.items.substr(1)), sizes],
			["Price per %s ($)" % c.item, s.rates.map(func(r): return cents2(r))]]}
	else:
		var parts: Array = []
		for b in s.edges.size():
			parts.append("an order of %s %s costs $%s for each %s" % [band_text(s, b), c.items, cents2(s.rates[b]), c.item])
		lines.append("%s, %s, and %s." % ["A" + parts[0].substr(1), parts[1], parts[2]])
	var wr: Array = [wrong({"v": S.marginal(s)}, R_EXCESS), wrong({"v": s.rates[k - 1].mul(s.n)}, R_NEIGHBOUR)]
	if k + 1 < s.rates.size():
		wr.append(wrong({"v": s.rates[k + 1].mul(s.n)}, R_NEIGHBOUR))
	var fill: Array = [{"v": s.rates[0].mul(s.n)}, {"v": key.mul(2)}]
	return pack(lines, "Find the cost of an order of %d %s." % [s.n, c.items], ans, wr, fill, {
		"piece-by-piece": ["%d %s is in the band %s, so the price is $%s for each %s." % [s.n, c.items, band_text(s, k), cents2(rate), c.item],
			"That price is paid for the whole order: cost = %d × %s = %s." % [s.n, D(rate), D(key)], say(ans)],
	}, null, table)
