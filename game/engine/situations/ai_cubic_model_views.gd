class_name AiCubicModelViews
extends ExtensionViews
## The views on the `ai-cubic-model` situation (FAL-1001): one builder per unknown of
## fn-ai-cubic-model (AI-SL2.5.cubic-model, AI-SL2.6.reasonable-domain). An open box folded from
## a card with squares of side x cut from its corners: its volume V(x) (an expression typed by
## its numbers), the possible values of x (an interval, or pick the graph of V on its domain),
## and the best x or the greatest volume from the GDC (its maximum tool or a table refined to
## hundredths). A cubic model of a profit, a temperature or a flow: its value at an input, its
## positive zero (the least input with no loss) and the total time it is negative.
##
## Every question is Paper 2, as every AI paper allows a GDC. A value is to 3 s.f. with the
## rounding trap; the domain is exact. `given` holds the situation as plain data.

const CM := "AI-SL2.5.cubic-model#"
const R_ONE_CUT := CM + "0"
const R_HALF_LONG := CM + "1"
const R_OTHER_TURN := CM + "2"
const R_WHOLE_SIDE := "AI-SL2.6.reasonable-domain#1"
const TYPE := "fn-ai-cubic-model#"
const R_OTHER_COORD := TYPE + "4"
const R_WRONG_ZERO := TYPE + "5"
const R_ONE_STRETCH := TYPE + "6"
const S := preload("res://engine/situations/ai_cubic_model.gd")

const WHO := ["Juno", "Ash", "Vex", "Mara", "Rook", "Tess"]
const SHEET := ["card", "sheet of tin", "sheet of plastic", "panel of card", "sheet of foil", "sheet of board"]
const GOODS := ["water filters", "solar lamps", "ration packs", "rain catchers", "wind chimes", "boot soles"]
const UNKNOWNS := ["box-volume", "box-domain", "box-max", "evaluate", "positive-zero", "negative-total"]


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


static func who(s: Dictionary) -> String:
	return WHO[s.ctx]


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func sf_ans(label: String, v: float, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": GdcKit.qf(v)}, {}, label, unit)
	ans.show = "sf"
	return ans


static func val(v: float) -> Dictionary:
	return {"v": GdcKit.qf(v)}


static func pack(lines: Array, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary,
		graph: Variant = null) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {},
		"graph": graph, "table": null}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


# ── The open box ─────────────────────────────────────────────

static func v_text(s: Dictionary) -> String:
	return "x(%d − 2x)(%d − 2x)" % [s.L, s.W]


static func v_expanded(s: Dictionary) -> String:
	return Fmt.terms(S.box_co(s), [3, 2, 1, 0], "x", true)


static func half_w(s: Dictionary) -> String:
	return D(Q.new(s.W, 2))


static func domain_text(s: Dictionary) -> String:
	return "0 < x < " + half_w(s)


## The story of the card, with the diagram or in words.
static func box_lines(rep: String, s: Dictionary) -> Array:
	if rep == "diagram":
		return ["%s cuts a square of side x cm from each corner of the rectangular %s in the diagram, then folds up the sides to make an open box." % [who(s), SHEET[s.ctx]]]
	return ["%s cuts a square of side x cm from each corner of a rectangular %s that measures %d cm by %d cm, then folds up the sides to make an open box." % [who(s), SHEET[s.ctx], s.L, s.W]]


## The card from above, its corner squares marked x: OptimisationViews' sheet, L along the bottom.
static func card_figure(s: Dictionary) -> Dictionary:
	return OptimisationViews.new()._sheet_figure({"w": s.W, "h": s.L})


static func build_step(s: Dictionary) -> String:
	return "A square comes off both ends of each side, so the base is (%d − 2x) cm by (%d − 2x) cm, and the sides fold up to a height of x cm: V = %s." % [s.L, s.W, v_text(s)]


## V drawn on [lo, hi], in a window that holds `ys` too.
static func box_window(s: Dictionary, x_hi: float, lo_y: float) -> Array:
	var step := 100 if s.v1 > 400.0 else 10
	var top := ceili(s.v1 * 1.15 / step) * step
	var bottom := mini(-step, floori(lo_y * 1.1 / step) * step)
	return [0, ceili(x_hi) + 1, bottom, top]


static func box_graph(s: Dictionary) -> Dictionary:
	var win := box_window(s, s.W / 2.0, 0.0)
	var g := Plot.spec([GdcKit.curve(func(x): return S.vol(s.L, s.W, x), 0.0, s.W / 2.0)], [], win[0], win[1], win[2], win[3])
	g.x_name = "x"
	g.y_name = "V"
	return g


func u_box_volume(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var L: int = s.L
	var Wd: int = s.W
	var text := func(a: int, b: int, c: int, d: int) -> String:
		return "V = x(%d − %sx)(%d − %sx)" % [a, Fmt.lead(b), c, Fmt.lead(d)]
	var ans := DifferentiationViews.form(text.call(L, 2, Wd, 2), ["V = x(", {"slot": "a"}, " − ", {"slot": "b"}, "x)(", {"slot": "c"}, " − ", {"slot": "d"}, "x)"],
		{"a": Q.new(L), "b": Q.new(2), "c": Q.new(Wd), "d": Q.new(2)})
	ans.pairs = [["a", "b"], ["c", "d"]]
	var sl := func(a: int, b: int, c: int, d: int, ref: String = "") -> Dictionary:
		return DifferentiationViews.alt(text.call(a, b, c, d), ref, {"a": Q.new(a), "b": Q.new(b), "c": Q.new(c), "d": Q.new(d)})
	var one: Dictionary = sl.call(L, 1, Wd, 1, R_ONE_CUT)
	var fill: Array = [sl.call(L, 4, Wd, 4).values, DifferentiationViews.alt("V = (%d − 2x)(%d − 2x)" % [L, Wd]).values, sl.call(L, 3, Wd, 3).values]
	var out := pack(box_lines(rep, s), "Write down an expression for V, the volume of the box in cm³, in terms of x.", ans, [one], fill, {
		"build-from-diagram": ["A square of side x cm comes off both ends of every side, so each side loses 2x: the base is (%d − 2x) cm by (%d − 2x) cm." % [L, Wd],
			"The sides fold up to a height of x cm, and volume = length × width × height.", say(ans)],
	}, card_figure(s) if rep == "diagram" else null)
	return out


static func span_of(lo: Variant, hi: Variant, ends: String = "left out") -> Dictionary:
	return {"shape": "between", "lo": Q.of(lo), "hi": Q.of(hi), "ends": ends}


func u_box_domain(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: int = s.L
	var Wd: int = s.W
	var top := Q.new(Wd, 2)
	var lines := box_lines(rep, s)
	var steps := {
		"build-from-diagram": ["The base is (%d − 2x) cm by (%d − 2x) cm, and both lengths must be positive." % [L, Wd],
			"%d − 2x > 0 gives x < %s, and %d − 2x > 0 gives x < %s: the shorter side runs out first, so x < %s." % [Wd, D(top), L, D(Q.new(L, 2)), D(top)],
			"The height x must be positive too, so x > 0."],
		"physical-limits": ["x is the side of a square, a length, so x > 0, and the box needs some height.",
			"Two squares of side x come off the %d cm side, so 2x < %d: x < %s. The %d cm side is longer, so it has room." % [Wd, Wd, D(top), L],
			"At x = 0 or x = %s there is no box, so both ends are left out." % D(top)],
	}
	if s.pick:
		return _box_domain_pick(s, lines, steps, rng, rep == "diagram")
	var ans := Answer.make("interval", span_of(0, top), {"var": "x"})
	ans.exact = true
	var ws: Array = [wrong(span_of(0, Q.new(L, 2)), R_HALF_LONG), wrong(span_of(0, Wd), R_WHOLE_SIDE)]
	var fill: Array = [span_of(0, top, "included"), span_of(0, L)]
	for m in steps:
		steps[m] = steps[m] + [say(ans)]
	return pack(lines, "Write down the possible values of x.", ans, ws, fill, steps, card_figure(s) if rep == "diagram" else null)


## Pick the graph: V on its domain, against V run on to half the longer side, to the whole
## shorter side, and from a negative x.
func _box_domain_pick(s: Dictionary, lines: Array, steps: Dictionary, rng: Seeded, diagram: bool) -> Dictionary:
	var L: int = s.L
	var Wd: int = s.W
	var f := func(x): return S.vol(L, Wd, x)
	var neg := -maxf(1.0, roundf(Wd / 10.0))
	var lo_y := minf(minf(s.v2, S.vol(L, Wd, neg)), 0.0)
	var hi_x := maxf(L / 2.0, Wd)
	var win := box_window(s, hi_x, lo_y)
	win[0] = int(neg) - 1
	# The whole-shorter-side card rises again past x = L/2: the window holds it.
	win[3] = maxi(win[3], ceili(S.vol(L, Wd, Wd) * 1.1 / 100.0) * 100)
	var card := func(a: float, b: float) -> Dictionary:
		var g := GdcKit.card([GdcKit.curve(f, a, b)], [], win)
		g.x_name = "x"
		g.y_name = "V"
		return g
	var right: Dictionary = card.call(0.0, Wd / 2.0)
	var wrongs: Array = [
		{"graph": card.call(0.0, L / 2.0), "mistake": "half-longer", "ref": R_HALF_LONG,
			"why": "it runs on to x = %s, half the longer side, but past x = %s the %d cm side has nothing left and V is negative" % [D(Q.new(L, 2)), half_w(s), Wd]},
		{"graph": card.call(0.0, float(Wd)), "mistake": "whole-shorter", "ref": R_WHOLE_SIDE,
			"why": "it runs on to x = %d, the whole shorter side, but two squares of side x must fit along it" % Wd},
		{"graph": card.call(neg, Wd / 2.0), "mistake": "negative", "ref": "",
			"why": "it starts at x = %s, but x is the side of a square, so it is positive" % D(neg)},
	]
	var pk := GdcKit.pick(right, wrongs, rng)
	var ans: Dictionary = pk.answer
	var methods := {}
	for m in steps:
		methods[m] = method(steps[m] + ["So the graph drawn for %s only is %s." % [domain_text(s), Answer.text(ans)]], ans.values)
	return {"asked": "Which graph shows V = %s for the possible values of x?" % v_text(s),
		"lines": lines + ["The volume of the box is V cm³. Each graph shows the curve y = %s on a different set of values of x." % v_text(s)],
		"answer": ans, "graphs": pk.graphs, "methods": methods, "graph": card_figure(s) if diagram else null}


func u_box_max(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var vals := S.box_max_vals(s)
	var is_x: bool = s.target == "x"
	var ans := sf_ans("x = ", vals[0], " cm") if is_x else sf_ans("V = ", vals[0], " cm³")
	var ws: Array = [wrong(val(vals[1]), R_OTHER_TURN), wrong(val(vals[2]), R_OTHER_COORD)]
	if rep == "diagram":
		ws.append(wrong(val(vals[3]), R_ONE_CUT))
	var fill: Array = [val(s.W / 2.0), val(s.L / 2.0)] if is_x else [val(s.L * s.W * s.x1), val(s.v1 / 2.0)]
	var lines: Array
	var graph: Variant = null
	var shown := v_text(s)
	if rep == "diagram":
		lines = box_lines(rep, s)
		graph = card_figure(s)
	elif rep == "graph":
		lines = ["%s folds an open box from a %d cm by %d cm %s, with squares of side x cm cut from its corners." % [who(s), s.L, s.W, SHEET[s.ctx]],
			"Its volume is V = %s cm³, for %s. The graph of V is shown." % [shown, domain_text(s)]]
		graph = box_graph(s)
	else:
		if s.expanded:
			shown = v_expanded(s)
		lines = ["%s folds an open box from a %d cm by %d cm %s, with squares of side x cm cut from its corners." % [who(s), s.L, s.W, SHEET[s.ctx]],
			"Its volume is V = %s cm³, for %s." % [shown, domain_text(s)]]
	var asked := "Find the value of x that gives the box its greatest volume." if is_x else "Find the greatest possible volume of the box."
	var first := build_step(s) + " The domain is %s." % domain_text(s) if rep == "diagram" else \
		"Only %s makes a box. The other turning point of V, at x = %s, lies outside it, where V = %s is negative." % [domain_text(s), W(s.x2), W(s.v2)]
	var read := "x = %s, V = %s" % [W(s.x1), W(s.v1)]
	var tb := S.table_steps(s)
	var n: float = tb[0]
	var steps := {
		"gdc-max": [first, "Graph V = %s on the GDC for %s and use the maximum tool: %s." % [shown, domain_text(s), read], say(ans)],
		"gdc-table": [first, "Tabulate V = %s from x = 1 in steps of 1: the greatest is V(%s) = %s." % [shown, D(GdcKit.qf(n)), W(tb[1])],
			"Steps of 0.1 from x = %s to x = %s: the greatest is V(%s) = %s." % [D(GdcKit.qf(n - 1.0)), D(GdcKit.qf(n + 1.0)), D(GdcKit.qf(tb[2])), W(tb[3])],
			"Steps of 0.01 from x = %s to x = %s: the greatest is V(%s) = %s." % [D(GdcKit.qf(tb[2] - 0.1)), D(GdcKit.qf(tb[2] + 0.1)), D(GdcKit.qf(tb[4])), W(tb[5])],
			say(ans)],
	}
	return pack(lines, asked, ans, ws, fill, steps, graph)


# ── A cubic model ────────────────────────────────────────────

static func letter(s: Dictionary) -> String:
	return "x" if s.kind == "profit" else "t"


static func fname(s: Dictionary) -> String:
	return {"profit": "P", "temp": "T", "flow": "F"}[s.kind]


static func poly(s: Dictionary) -> String:
	return Fmt.terms(s.co, [3, 2, 1, 0], letter(s), true)


static func model_eq(s: Dictionary) -> String:
	return "%s(%s) = %s, for 0 ≤ %s ≤ %d" % [fname(s), letter(s), poly(s), letter(s), s.hi]


static func model_lines(s: Dictionary) -> Array:
	match s.kind:
		"profit":
			return ["%s sells x hundred %s a week. The weekly profit, P thousand scrap, is modelled by %s." % [who(s), GOODS[s.ctx], model_eq(s)]]
		"temp":
			return ["The temperature in %s's desert camp t hours after midnight is T °C, modelled by %s." % [who(s), model_eq(s)]]
	return ["%s opens a valve on a water tank at t = 0. Water flows into the tank at F litres per minute, modelled by %s, where t is in minutes." % [who(s), model_eq(s)],
		"A negative value of F means that water flows out of the tank."]


static func unit(s: Dictionary) -> String:
	return {"profit": " thousand scrap", "temp": " °C", "flow": " litres per minute"}[s.kind]


static func model_graph(s: Dictionary) -> Dictionary:
	var sp := S.span(s.co, 0.0, s.hi)
	var top := ceili(maxf(sp[1], 0.0) * 1.15 + 0.5)
	var bottom := floori(minf(sp[0], 0.0) * 1.15 - 0.5)
	var g := Plot.spec([GdcKit.curve(func(x): return S.value(s, x), 0.0, float(s.hi))], [], 0, s.hi, bottom, top)
	g.x_name = letter(s)
	g.y_name = fname(s)
	return g


## The input in words: "260 water filters", "4 hours 36 minutes after midnight", "6 minutes
## 30 seconds after the valve opens".
static func input_words(s: Dictionary) -> String:
	var k: int = s.x0.mul(10).n
	match s.kind:
		"profit":
			return "%d %s" % [k * 10, GOODS[s.ctx]]
		"temp":
			return "%d hours %d minutes after midnight" % [k / 10, (k % 10) * 6]
	return "%d minutes %d seconds after the valve opens" % [k / 10, (k % 10) * 6]


static func input_step(s: Dictionary) -> String:
	var k: int = s.x0.mul(10).n
	match s.kind:
		"profit":
			return "%d %s is %s hundred, so x = %s." % [k * 10, GOODS[s.ctx], D(s.x0), D(s.x0)]
		"temp":
			return "%d minutes is %d/60 = %s of an hour, so t = %s." % [(k % 10) * 6, (k % 10) * 6, D(Q.new(k % 10, 10)), D(s.x0)]
	return "%d seconds is %d/60 = %s of a minute, so t = %s." % [(k % 10) * 6, (k % 10) * 6, D(Q.new(k % 10, 10)), D(s.x0)]


func u_evaluate(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var vals := S.evaluate_vals(s)
	var F := fname(s)
	var X := D(s.x0)
	var ans := sf_ans(F + " = ", vals[0], unit(s)) if rep == "words" else sf_ans("%s(%s) = " % [F, X], vals[0])
	var fill: Array = [val(vals[1]), val(vals[2]), val(vals[3])]
	var lines: Array
	var asked: String
	var steps: Array = []
	if rep == "words":
		lines = model_lines(s)
		match s.kind:
			"profit":
				asked = "Find the weekly profit when %s sells %s." % [who(s), input_words(s)]
			"temp":
				asked = "Find the temperature %s." % input_words(s)
			_:
				asked = "Find the rate of flow %s." % input_words(s)
		steps.append(input_step(s))
	else:
		lines = [model_eq(s) + "."]
		asked = "Find the value of %s(%s)." % [F, X]
	steps += ["In the GDC's table, enter Y1 = %s, with X for %s." % [poly(s), letter(s)],
		"Start the table at X = %s and read its first row: Y1 = %s." % [X, W(vals[0])], say(ans)]
	return pack(lines, asked, ans, [], fill, {"gdc-table": steps})


func u_positive_zero(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var vals := S.positive_zero_vals(s)
	var ans := sf_ans("x = ", vals[0])
	var ws: Array = [wrong(val(vals[1]), R_WRONG_ZERO), wrong(val(vals[2]), R_WRONG_ZERO)]
	var fill: Array = [val(vals[3])]
	var lines := model_lines(s)
	var graph: Variant = null
	if rep == "graph":
		lines = lines + ["The graph of P is shown."]
		graph = model_graph(s)
	var z: Array = s.zeros
	return pack(lines, "Find the least value of x for which %s makes no loss." % who(s), ans, ws, fill, {
		"gdc-zero": ["Graph P = %s on the GDC and use the zero tool: P = 0 at x = %s, x = %s and x = %s." % [poly(s), W(z[0]), W(z[1]), W(z[2])],
			"x = %s is negative, outside the domain. P(0) = %s < 0 is a loss, and P first reaches 0 at x = %s, where the loss ends; at x = %s P falls back to a loss." % [W(z[0]), D(s.co[3]), W(z[1]), W(z[2])],
			say(ans)],
	}, graph)


func u_negative_total(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var vals := S.negative_total_vals(s)
	var temp: bool = s.kind == "temp"
	var ans := sf_ans("total time = ", vals[0], " hours" if temp else " minutes")
	var ws: Array = [wrong(val(vals[1]), R_ONE_STRETCH), wrong(val(vals[2]), R_ONE_STRETCH)]
	var fill: Array = [val(vals[3]), val(vals[4])]
	var lines := model_lines(s)
	var graph: Variant = null
	if rep == "graph":
		lines = lines + ["The graph of %s is shown." % fname(s)]
		graph = model_graph(s)
	var asked := "Find the total time, in hours, for which the temperature is below 0 °C." if temp else \
		"Find the total time, in minutes, for which water flows out of the tank."
	var z: Array = s.zeros
	var F := fname(s)
	# The total of the figures the working shows (the same to 3 s.f., AiCubicModelSituation).
	var shown := 0.0
	for st in S.negative_parts(s):
		shown += S.w6(st[1]) - S.w6(st[0])
	var where: String
	var sum: String
	if s.sign > 0:
		where = "%s(0) = %s < 0, so %s < 0 for 0 ≤ t < %s and again for %s < t < %s." % [F, D(s.co[3]), F, W(z[0]), W(z[1]), W(z[2])]
		sum = "Total: %s + (%s − %s) = %s." % [W(z[0]), W(z[2]), W(z[1]), W(shown)]
	else:
		where = "%s(0) = %s > 0, so %s < 0 for %s < t < %s and again for %s < t ≤ %d." % [F, D(s.co[3]), F, W(z[0]), W(z[1]), W(z[2]), s.hi]
		sum = "Total: (%s − %s) + (%d − %s) = %s." % [W(z[1]), W(z[0]), s.hi, W(z[2]), W(shown)]
	return pack(lines, asked, ans, ws, fill, {
		"gdc-zero": ["Graph %s = %s on the GDC for 0 ≤ t ≤ %d and use the zero tool: %s = 0 at t = %s, t = %s and t = %s." % [F, poly(s), s.hi, F, W(z[0]), W(z[1]), W(z[2])],
			where, sum, say(ans)],
	}, graph)
