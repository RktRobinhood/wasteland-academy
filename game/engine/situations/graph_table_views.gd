class_name GraphTableViews
extends ExtensionViews
## The views on the `composite-graph-table` situation: one builder per unknown of
## fn-graph-table-composite-inverse (FAL-422). f and g are read from a graph (grid points
## joined by lines, shown unlabelled so a reading is a reading), a table, a sentence of
## values or, for the rule views, an equation. Every answer is a whole number, a list of
## them, a pair of bounds or one of four sentences, marked exactly (Paper 1).

const T := "fn-graph-table-composite-inverse"
const R_NOTATION_RULE := "SL2.2.evaluate-notation#1"
const R_SHIFTED := "SL2.2.evaluate-notation#2"
const R_SOLVE_AS_VALUE := "SL2.3.read-graph#0"
const R_ONE_CROSSING := "SL2.3.read-graph#1"
const R_ORDER := "SL2.5.composite-value#0"
const R_PRODUCT := "SL2.5.composite-value#1"
const R_TWICE := "SL2.5.composite-value#2"
const R_RECIPROCAL := "SL2.2.inverse-undo#0"
const R_AXIS := "SL2.2.inverse-undo#1"
const R_VALUE_NOT_INVERSE := "SL2.2.inverse-undo#2"
const R_SOLVE_INVERSE := "SL2.5.identity#1"
const R_DOMAIN_OF_F := "SL2.5.inverse-domain-range#0"
const R_Y_INTERCEPT := "SL2.5.inverse-domain-range#1"
const R_EVERY_INVERSE := "SL2.5.inverse-domain-range#2"
## fn-graph-table-composite-inverse's own slips (FAL-820).
const R_INPUT := "fn-graph-table-composite-inverse#16"
const R_INNER := "fn-graph-table-composite-inverse#17"
const R_FC := "fn-graph-table-composite-inverse#18"
const R_K := "fn-graph-table-composite-inverse#19"
const R_BACK := "fn-graph-table-composite-inverse#20"
const R_COMPOSITE := "fn-graph-table-composite-inverse#21"
## The methods that read values off a graph or table: on the equation rep the rule is
## printed beside its graph for them, and with neither shown they have no working.
const READINGS := ["read-graph-table", "vertical-read", "chain-readings"]


func needs() -> Dictionary:
	return {
		"read-value": {"mode": "read"},
		"value-from-rule": {"mode": "rule"},
		"self-composite-read": {"mode": "self"},
		"composite-from-table": {"mode": "pair"},
		"solve-from-table": {"mode": "read"},
		"inverse-value-read": {"mode": "read"},
		"inverse-domain-read": {"mode": "read"},
		"inverse-range-read": {"mode": "read"},
		"solve-inverse-equation": {"mode": "read"},
		"value-at-shifted-input": {"mode": "zero"},
		"mixed-inverse-composite": {"mode": "pair"},
		"missing-entry": {"mode": "pair"},
		"inverse-points": {"mode": "read"},
		"count-solutions": {"mode": "turn"},
		"why-no-inverse": {"mode": "turn"},
		"restrict-from-graph": {"mode": "turn"},
	}


## The recipe is told the rep and the method too, for the rule views: a rule-based f for
## the equation rep and for direct substitution (see GraphTableSituation).
func need(unknown: String, rep: String) -> Dictionary:
	var n: Dictionary = super.need(unknown, rep)
	if unknown == "self-composite-read" and rep == "equation":
		n.mode = "rule"
		n.self = true
	if unknown == "value-from-rule":
		n.mode = "rule"
	# Solving f(x) = k and f⁻¹(b) need a value that is an input too, so their slip f(k)
	# (or f(b)) is there to offer and is not the answer.
	if unknown in ["solve-from-table", "inverse-value-read"]:
		n.back = true
	return n


func build_view(unknown: String, rep: String, method_id: String, s: Dictionary, rng: Seeded) -> Dictionary:
	angle = method_id
	return build(unknown, rep, s, rng)


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = GraphTableSituation.export(s)
	return out


# ── Helpers ──────────────────────────────────────────────────

static func N(v: Variant) -> String:
	return Fmt.num(v)


static func y_of(s: Dictionary, name: String, x: int) -> int:
	var ys: Array = s.fy if name == "f" else s.gy
	return ys[s.xs.find(x)]


static func has_x(s: Dictionary, x: int) -> bool:
	return x in s.xs


static func number(label: String, v: Variant) -> Dictionary:
	var ans := Answer.make("number", {"v": Q.of(v)}, {}, label)
	ans.exact = true
	return ans


static func wrongs_of(pairs: Array) -> Array:
	return pairs.map(func(p): return ExtensionViews.wrong({"v": Q.of(p[0])}, p[1]))


## The table of f (and g), with an optional blank "?" at one input of one row.
static func table_of(s: Dictionary, with_g: bool, blank_g: Variant = null) -> Dictionary:
	var xs: Array = s.xs
	var rows: Array = [["x", xs.map(func(x): return N(x))], ["f(x)", s.fy.map(func(y): return N(y))]]
	if with_g:
		rows.append(["g(x)", s.gy.map(func(y): return "?" if blank_g != null and xs[s.gy.find(y)] == blank_g else N(y))])
	return {"rows": rows}


## The graph of f: grid points joined by lines, in a window with a margin.
static func graph_of(s: Dictionary, ys: Array = []) -> Dictionary:
	var vals: Array = s.fy if ys.is_empty() else ys
	var pts: Array = []
	var curve: Array = []
	for i in s.xs.size():
		pts.append([s.xs[i], vals[i], ""])
		curve.append([float(s.xs[i]), float(vals[i])])
	var lo: int = mini(s.xs.min(), vals.min()) - 1
	var hi: int = maxi(s.xs.max(), vals.max()) + 1
	return Plot.spec([curve], pts, s.xs.min() - 1, s.xs.max() + 1, mini(lo, -1), maxi(hi, 1))


## "f(1) = 3, f(3) = 6 and f(6) = 2." for the chosen inputs, in order.
static func words_of(s: Dictionary, inputs: Array, name: String = "f") -> String:
	var xs: Array = inputs.duplicate()
	xs.sort()
	var parts: Array = xs.map(func(x): return "%s(%s) = %s" % [name, N(x), N(y_of(s, name, x))])
	return (", ".join(parts.slice(0, parts.size() - 1)) + " and " + parts[parts.size() - 1] if parts.size() > 1 else parts[0]) + "."


## The lines, graph and table a view shows for a rep (graph, table or words) of f.
static func show(rep: String, s: Dictionary, words_inputs: Array, with_g: bool = false, blank_g: Variant = null) -> Dictionary:
	match rep:
		"graph":
			var out := {"lines": ["The graph of f is shown. Each dot is on a grid point."], "graph": graph_of(s)}
			if with_g:
				out.lines = ["The graph of f is shown, and the table gives g.", ]
				out.table = table_of(s, true, blank_g)
				out.table.rows = [out.table.rows[0], out.table.rows[2]]
			return out
		"table":
			return {"lines": ["The table gives f%s." % (" and g" if with_g else "")], "table": table_of(s, with_g, blank_g)}
	var lines: Array = [words_of(s, words_inputs)]
	if with_g:
		lines.append(words_of(s, words_inputs, "g"))
	return {"lines": lines}


static func poly_text(co: Array) -> String:
	return Fmt.poly([co[2], co[1], co[0]])


## The rule with an expression put in for x, in brackets: "(x² + 1)² − 2(x² + 1) + 3".
static func put_expr(co: Array, e: String) -> String:
	var out := ""
	for power in [2, 1, 0]:
		var c: int = co[power].n
		if c == 0:
			continue
		var mag := absi(c)
		var body: String = str(mag) if power == 0 else ("" if mag == 1 else str(mag)) + "(%s)" % e + ("²" if power == 2 else "")
		out += ("−" if c < 0 else "") + body if out == "" else (" − " if c < 0 else " + ") + body
	return out if out != "" else "0"


## The rule with a number put in: "−(1)² + 1", "2(−3) + 4": a bracket round a negative, a square or a multiplied number.
static func put(co: Array, a: int) -> String:
	var out := ""
	for power in [2, 1, 0]:
		var c: int = co[power].n
		if c == 0:
			continue
		var mag := absi(c)
		var body: String
		if power == 0:
			body = str(mag)
		else:
			var x := "(%s)" % N(a) if (a < 0 or power == 2 or mag != 1) else N(a)
			body = ("" if mag == 1 else str(mag)) + x + ("²" if power == 2 else "")
		out += ("−" if c < 0 else "") + body if out == "" else (" − " if c < 0 else " + ") + body
	return out if out != "" else "0"


static func rule_at(s: Dictionary, x: int) -> int:
	return s.co[0].n + s.co[1].n * x + s.co[2].n * x * x


static func spread(vals: Array, avoid: Array) -> Array:
	var out: Array = []
	for v in vals:
		if not out.has(v) and not avoid.has(v):
			out.append(v)
	return out


## Fillers {"v": n} for the numbers given, in order; a null (a reading off the shown
## inputs) is left out. The engine drops any that repeat the key or an earlier option.
static func fill(vals: Array) -> Array:
	return vals.filter(func(v): return v != null).map(func(v): return {"v": Q.of(v)})


## The numbers of vals that are inputs (others null, for fill() to leave out).
static func inputs_of(s: Dictionary, vals: Array) -> Array:
	return vals.map(func(x): return x if x != null and has_x(s, x) else null)


## f (or g) at each of xs, null off the shown inputs.
static func values_at(s: Dictionary, xs: Array, name: String = "f") -> Array:
	return xs.map(func(x): return GraphTableSituation.at(s.xs, s.fy if name == "f" else s.gy, x) if x != null else null)


## An interval answer's values, both ends included unless told.
static func interval(lo: int, hi: int, r1: String = "≤", r2: String = "≤") -> Dictionary:
	return {"lo": Q.new(lo), "r1": r1, "r2": r2, "hi": Q.new(hi)}


## The intervals whose low end is below the high end (a mix of two ends can cross).
static func proper(intervals: Array) -> Array:
	return intervals.filter(func(v): return v.lo.n < v.hi.n)


## One item of the first pool that isn't empty (a pool of the best picks first).
static func pick_from(rng: Seeded, pools: Array) -> Variant:
	for p in pools:
		if not p.is_empty():
			return p[rng.int_in(0, p.size() - 1)]
	return null


## From x = a on the axis to the graph, where f(a) = y: up to a point above the axis,
## down to one below, and across to the y-axis from there.
static func vertical(a: int, y: int, across: String = ", then across to the y-axis", to: String = "graph") -> String:
	if y == 0:
		return "At x = %s the %s is on the x-axis" % [N(a), to]
	return "Go %s from x = %s to the %s%s" % ["up" if y > 0 else "down", N(a), to, across]


## Three inputs for a sentence of values: a, then `extra` where it is another input (the
## value a slip reads), then others from xs, `steps` along from a first.
static func sentence_inputs(s: Dictionary, a: int, extra: Variant, steps: Array) -> Array:
	var out: Array = [a]
	if extra != null and has_x(s, extra) and extra != a:
		out.append(extra)
	var i: int = s.xs.find(a)
	for d in steps + [1, 2, 3, 4, 5]:
		var x: int = s.xs[(i + d) % s.xs.size()]
		if out.size() < 3 and not out.has(x):
			out.append(x)
	return out


func _angles(unknown: String) -> Array:
	var t := QuestionEngine.type_of(T)
	var out: Array = []
	for a in t.get("angles", []):
		if unknown in a.suits and not out.has(a.method):
			out.append(a.method)
	return out


## One working per method of the unknown: the same steps worded for the method. A method
## in `skip` has no working on what the question shows (a reading with no graph or table,
## a substitution with no rule), so it gets no tab.
func _methods(unknown: String, texts: Dictionary, default_steps: Array, result: Dictionary, skip: Array = []) -> Dictionary:
	var out := {}
	for a in _angles(unknown):
		if not a in skip:
			out[a] = method(texts.get(a, default_steps), result)
	return out


# ── Reading a value ──────────────────────────────────────────

func u_read_value(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	# Not where f(a) = a: there the input given back (R_INPUT) would be the answer.
	var a: int = pick_from(rng, [s.xs.filter(func(x): return y_of(s, "f", x) != x), s.xs])
	var v := y_of(s, "f", a)
	var ans := number("f(%s) = " % N(a), v)
	var words_inputs := [a, s.xs[(s.xs.find(a) + 2) % s.xs.size()], s.xs[(s.xs.find(a) + 4) % s.xs.size()]]
	# Other readings: the input whose output is a (read across from the y-axis instead of
	# up from x), the sign lost, and the outputs at the other inputs shown (the next grid
	# line or column, or the sentence's other values).
	var near: Array = words_inputs.slice(1) if rep == "words" else [a + 1, a - 1, a + 2, a - 2]
	var fillers: Array = [GraphTableSituation.where(s.xs, s.fy, a) if rep != "words" else null, -v]
	fillers += near.map(func(x): return GraphTableSituation.at(s.xs, s.fy, x))
	var out := {"asked": "Find f(%s)." % N(a), "answer": ans, "wrongs": [wrong({"v": Q.new(a)}, R_INPUT)], "fillers": fill(fillers + [-a])}
	out.merge(show(rep, s, words_inputs))
	var final := "So %s." % Answer.text(ans)
	var where := "Find x = %s in the sentence" % N(a) if rep == "words" else ("Find x = %s in the top row of the table" % N(a) if rep == "table" else "Find x = %s on the horizontal axis" % N(a))
	var how := "Read the value given for it: f(%s) = %s" % [N(a), N(v)] if rep == "words" else ("Read the value below it: f(%s) = %s" % [N(a), N(v)] if rep == "table" else "Read the height of the graph there: f(%s) = %s" % [N(a), N(v)])
	var up := vertical(a, v) + ": f(%s) = %s" % [N(a), N(v)] if rep == "graph" else how
	# Off a graph there is no going up: a table is read down its column, a sentence as it stands.
	if rep == "table":
		out.titles = {"vertical-read": "Read down from x to f(x)"}
	elif rep == "words":
		out.titles = {"vertical-read": "Read the value given for x", "read-graph-table": "Read the output from the sentence"}
	out.methods = _methods("read-value", {"vertical-read": [where, up, final]}, [where, how, final], ans.values)
	return out


func u_value_from_rule(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	# Not 0: f(0) is the constant term alone, and the squared term's sign slip needs a ≠ 0.
	var a: int = pick_from(rng, [s.xs.slice(1, s.xs.size() - 1).filter(func(x): return x != 0), s.xs])
	var v := rule_at(s, a)
	var c0: int = s.co[0].n
	var c1: int = s.co[1].n
	var c2: int = s.co[2].n
	var ans := number("f(%s) = " % N(a), v)
	var rule := "f(x) = %s" % poly_text(s.co)
	# Other slips: the input's sign lost (f(−a)), a² taken as 2a, the constant term left
	# out or alone, the input given back, the answer's sign lost, and last the rule put
	# in at the next whole number either side.
	var out := {"asked": "Find f(%s)." % N(a), "answer": ans, "lines": [rule], "wrongs": [],
		"fillers": fill([rule_at(s, -a), c0 + c1 * a + 2 * c2 * a, v - c0, c0, a, -v, rule_at(s, a + 1), rule_at(s, a - 1)])}
	# The sign of the squared term lost: −x² read as (−x)² (or the other way round).
	if a != 0 and c2 != 0:
		var slip: int = c0 + c1 * a - c2 * a * a
		out.wrongs.append(wrong({"v": Q.new(slip)}, R_NOTATION_RULE))
	# The equation rep prints the rule beside its graph when the method reads the graph.
	var graph: bool = rep == "graph" or angle == "vertical-read"
	if graph:
		var curve := Plot.sample(func(x): return float(c0) + c1 * x + c2 * x * x, -4.0, 4.0)
		var top := maxi(8, s.fy.max() + 1)
		out.graph = Plot.spec([curve], [], -4, 4, mini(-2, s.fy.min() - 1), mini(top, 14))
		out.lines = [rule, "The graph of y = f(x) is shown."]
	var putin := put(s.co, a)
	var final := "So %s." % Answer.text(ans)
	var subst := ["Put x = %s into the rule: f(%s) = %s" % [N(a), N(a), putin], "Work it out: f(%s) = %s" % [N(a), N(v)], final]
	out.methods = _methods("value-from-rule", {
		"vertical-read": [vertical(a, v, ", then across to the y-axis", "curve"), "The graph shows f(%s) = %s, which the rule confirms: %s = %s" % [N(a), N(v), putin, N(v)], final],
		"gdc-trace": ["Enter y1 = %s on the calculator" % poly_text(s.co), "Use the table or trace at x = %s: y1 = %s" % [N(a), N(v)], final]},
		subst, ans.values, [] if graph else ["vertical-read"])
	return out


func u_self_composite_read(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var rule: bool = s.mode == "rule"
	# a, f(a) and f(f(a)) all different, and f(f(a)) not f(a)², with f(a) a shown input: no
	# fixed point or 2-cycle gives back the input or a slip as the answer, and every reading
	# is on the grid (GraphTableSituation.self_inputs). Best with f(a) not 0 or 1, where
	# f(a)² is f(a) and the two named slips are one.
	var on_grid: Array = (range(-3, 4) if rule else s.xs).filter(func(x): return GraphTableSituation.f_at(s, x) in s.xs)
	var ins := GraphTableSituation.self_inputs(s)
	var a: int = pick_from(rng, [ins.filter(func(x): return not GraphTableSituation.f_at(s, x) in [0, 1]), ins, on_grid])
	var mid: int = GraphTableSituation.f_at(s, a)
	var v: int = GraphTableSituation.f_at(s, mid)
	var ans := number("(f∘f)(%s) = " % N(a), v)
	# Other slips: the input given back, f applied a third time, the input whose output is
	# a (read backwards), the answer's sign lost, f(a) + f(a), f(2a) or f(a²) for
	# f(f(a)), and last the second reading one grid line off.
	var out := {"asked": "Find (f∘f)(%s)." % N(a), "answer": ans, "wrongs": [wrong({"v": Q.new(mid * mid)}, R_PRODUCT), wrong({"v": Q.new(mid)}, R_INNER)],
		"fillers": fill([a, GraphTableSituation.at(s.xs, s.fy, v), GraphTableSituation.where(s.xs, s.fy, a), -v, 2 * mid] + values_at(s, [2 * a, a * a, mid + 1, mid - 1]))}
	# A reading needs a graph or table: the equation rep prints the rule beside its graph
	# when the method reads, and shows the rule alone otherwise.
	var graph: bool = rep == "graph" or (rep == "equation" and angle in READINGS)
	var table: bool = rep == "table"
	if rule:
		out.lines = ["f(x) = %s" % poly_text(s.co)]
		if graph:
			out.graph = graph_of(s)
			out.lines.append("The graph of f is shown. Each dot is on a grid point.")
		elif table:
			out.table = table_of(s, false)
			out.lines.append("The table gives f.")
	else:
		out.merge(show(rep, s, [a, mid, s.xs[0]]))
	var final := "So %s." % Answer.text(ans)
	var first := "f(%s) = %s" % [N(a), N(mid)]
	var second := "f(%s) = %s" % [N(mid), N(v)]
	var chain := ["Work from the inside out: %s" % first, "Then apply f again: %s" % second, final]
	var texts := {"chain-readings": chain}
	var skip: Array = []
	# One function here, so the composite built first is f(f(x)).
	out.titles = {"build-then-substitute": "Find f(f(x)) first, then substitute"}
	if graph or table:
		texts["read-graph-table"] = ["Read f(%s) from the %s: %s" % [N(a), "graph" if graph else "table", first], "Read f(%s) the same way: %s" % [N(mid), second], final]
	else:
		skip += ["read-graph-table", "chain-readings"]
	if graph:
		texts["vertical-read"] = [vertical(a, mid, " and across") + ": " + first, vertical(mid, v, " and across") + ": " + second, final]
	elif table:
		# A table is read down its column, not up to a graph.
		texts["vertical-read"] = ["Find x = %s in the top row and read down: %s" % [N(a), first], "Find x = %s in the top row and read down: %s" % [N(mid), second], final]
		out.titles["vertical-read"] = "Read down from x to f(x)"
	else:
		skip.append("vertical-read")
	if rule:
		texts["direct-substitution"] = ["f(%s) = %s = %s" % [N(a), put(s.co, a), N(mid)], "f(%s) = %s = %s" % [N(mid), put(s.co, mid), N(v)], final]
		texts["build-then-substitute"] = ["Put f(x) in place of x in the rule: f(f(x)) = %s" % put_expr(s.co, poly_text(s.co)),
			"Put x = %s: the bracket is %s = %s, so f(f(%s)) = %s = %s" % [N(a), put(s.co, a), N(mid), N(a), put(s.co, mid), N(v)], final]
		if not (graph or table):
			texts["inside-out"] = ["Work from the inside out: f(%s) = %s = %s" % [N(a), put(s.co, a), N(mid)], "Then apply f again: f(%s) = %s = %s" % [N(mid), put(s.co, mid), N(v)], final]
	else:
		skip += ["direct-substitution", "build-then-substitute"]
	out.methods = _methods("self-composite-read", texts, chain, ans.values, skip)
	return out


# ── Composites from a table ──────────────────────────────────

func u_composite_from_table(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var f_first := rng.chance(0.5)   # (f∘g)(a): g first
	var inner := "g" if f_first else "f"
	var outer := "f" if f_first else "g"
	var ins: Array = []
	for x in s.xs:
		var m := y_of(s, inner, x)
		if m in s.xs:
			ins.append(x)
	# Not an input whose answer is the input itself or the inner value (R_INNER).
	var a: int = pick_from(rng, [GraphTableSituation.composite_inputs(s, inner, outer), ins])
	var mid := y_of(s, inner, a)
	var v := y_of(s, outer, mid)
	var lab := "(%s∘%s)" % [outer, inner]
	var ans := number("%s(%s) = " % [lab, N(a)], v)
	var out := {"asked": "Find %s(%s)." % [lab, N(a)], "answer": ans, "wrongs": [], "fillers": []}
	out.merge(show(rep, s, [], true))
	# The other order, the product and one function twice.
	if has_x(s, y_of(s, outer, a)):
		out.wrongs.append(wrong({"v": Q.new(y_of(s, inner, y_of(s, outer, a)))}, R_ORDER))
	out.wrongs.append(wrong({"v": Q.new(y_of(s, "f", a) * y_of(s, "g", a))}, R_PRODUCT))
	if has_x(s, y_of(s, inner, a)):
		out.wrongs.append(wrong({"v": Q.new(y_of(s, inner, y_of(s, inner, a)))}, R_TWICE))
	out.wrongs.append(wrong({"v": Q.new(mid)}, R_INNER))
	# The outer function twice is the same slip.
	if has_x(s, y_of(s, outer, a)):
		out.wrongs.append(wrong({"v": Q.new(y_of(s, outer, y_of(s, outer, a)))}, R_TWICE))
	# Other slips: the outer function alone, the input given back, the sum f(a) + g(a),
	# the answer's sign lost, and last the second reading one column off.
	out.fillers = fill([y_of(s, outer, a), a, y_of(s, "f", a) + y_of(s, "g", a), -v] + values_at(s, [mid + 1, mid - 1], outer))
	var final := "So %s." % Answer.text(ans)
	var steps := ["Start inside: %s(%s) = %s" % [inner, N(a), N(mid)], "Now apply %s to that: %s(%s) = %s" % [outer, outer, N(mid), N(v)], final]
	out.methods = _methods("composite-from-table", {}, steps, ans.values)
	return out


# ── Solving for an input ─────────────────────────────────────

func u_solve_from_table(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.xs.size()
	var all_i: Array = range(n)
	# k an input too, so f(k), solving read as evaluating, is a slip to offer; and not
	# one that is the answer (f(k) = a), nor k the answer itself (f(a) = a).
	var good: Array = all_i.filter(func(j): return s.fy[j] in s.xs and s.fy[j] != s.xs[j] and y_of(s, "f", s.fy[j]) != s.xs[j])
	var i: int = pick_from(rng, [good, all_i.filter(func(j): return s.fy[j] != s.xs[j]), all_i])
	var a: int = s.xs[i]
	var k: int = s.fy[i]
	var ans := Answer.make("xval", {"v": Q.new(a)})
	ans.exact = true
	var out := {"asked": "Solve f(x) = %s." % N(k), "answer": ans, "wrongs": [], "fillers": []}
	# A sentence lists f(k) too, where k is an input, so the slip can be made from it.
	out.merge(show(rep, s, sentence_inputs(s, a, k, [1, 3])))
	# f(k), the output at input k, when k is an input.
	if has_x(s, k) and k != a:
		out.wrongs.append(wrong({"v": Q.new(y_of(s, "f", k))}, R_SOLVE_AS_VALUE))
	# Other slips: k itself, the input where f is −k (k's sign lost), the answer's sign
	# lost, and last the inputs beside the answer (the next column read).
	out.fillers = fill([k, GraphTableSituation.where(s.xs, s.fy, -k), -a] + inputs_of(s, [a + 1, a - 1, a + 2, a - 2, a + 3, a - 3]))
	var final := "So %s." % Answer.text(ans)
	var where := "the %s" % ("graph" if rep == "graph" else "table" if rep == "table" else "sentence")
	var look := "Draw the line y = %s across the graph" % N(k) if rep == "graph" else ("Look along the f(x) row for %s" % N(k) if rep == "table" else "Find the value %s in the sentence" % N(k))
	var meet := "It meets f at x = %s" % N(a) if rep == "graph" else "It is the value at x = %s: f(%s) = %s" % [N(a), N(a), N(k)]
	# Off a graph there is no line to draw: the value is found among the outputs.
	if rep != "graph":
		out.titles = {"horizontal-line": "Find the output, then read off its x"}
	out.methods = _methods("solve-from-table", {
		"horizontal-line": [look, meet, final],
		"solve-for-input": ["We need the input whose output is %s, so look for %s in the f(x) values of %s" % [N(k), N(k), where], "f(%s) = %s, so x = %s" % [N(a), N(k), N(a)], final]},
		[], ans.values)
	return out


# ── Inverse readings ─────────────────────────────────────────

## An output b for f⁻¹(b) whose answer is neither b nor f(b) (GraphTableSituation.
## inverse_outputs), an input too where one is, so f(b) is a slip to offer.
func _output_in_inputs(s: Dictionary, rng: Seeded) -> int:
	var outs := GraphTableSituation.inverse_outputs(s)
	var moving: Array = s.fy.filter(func(y): return y != s.xs[s.fy.find(y)])
	return pick_from(rng, [outs.filter(func(y): return y in s.xs), outs, moving, s.fy])


func u_inverse_value_read(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var b := _output_in_inputs(s, rng)
	var a: int = s.xs[s.fy.find(b)]
	var ans := number("f⁻¹(%s) = " % N(b), a)
	# Other slips: b itself, the input where f is −b (b's sign lost), the answer's sign
	# lost, and last the inputs beside the answer (the next column read).
	var out := {"asked": "Find f⁻¹(%s)." % N(b), "answer": ans, "wrongs": [],
		"fillers": fill([b, GraphTableSituation.where(s.xs, s.fy, -b), -a] + inputs_of(s, [a + 1, a - 1, a + 2, a - 2, a + 3, a - 3]))}
	# A sentence lists f(b) too, where b is an input, so the slips can be made from it.
	out.merge(show(rep, s, sentence_inputs(s, a, b, [1, 3])))
	if has_x(s, b):
		out.wrongs.append(wrong({"v": Q.new(y_of(s, "f", b))}, R_VALUE_NOT_INVERSE))
		if y_of(s, "f", b) != 0:
			out.wrongs.append(wrong({"v": Q.new(1).div(Q.new(y_of(s, "f", b)))}, R_RECIPROCAL))
	var final := "So %s." % Answer.text(ans)
	# On the graph: across from the y-axis, then down (or up) to the x-axis. Off it, b is
	# found among the outputs and its x read off.
	var go: String = "Start on the y-axis at %s and go across to the graph" % N(b) if rep == "graph" else ("Find %s in the f(x) row" % N(b) if rep == "table" else "Find the value %s in the sentence" % N(b))
	var back: String
	if rep != "graph":
		back = "Read off its x: the input is %s" % N(a)
		out.titles = {"horizontal-line": "Find the output, then read off its x"}
	elif b == 0:
		back = "The line meets the graph on the x-axis: the input is %s" % N(a)
	else:
		back = "Go %s to the x-axis: the input is %s" % ["down" if b > 0 else "up", N(a)]
	out.methods = _methods("inverse-value-read", {
		"horizontal-line": [go, back, final],
		"swap-coordinates": ["f(%s) = %s, so (%s, %s) is on f and (%s, %s) is on f⁻¹" % [N(a), N(b), N(a), N(b), N(b), N(a)], "Swap the coordinates: f⁻¹(%s) = %s" % [N(b), N(a)], final],
		"solve-f-equals": ["f⁻¹(%s) is the x with f(x) = %s" % [N(b), N(b)], "Find %s among the f(x) values: it is at x = %s" % [N(b), N(a)], final]}, [], ans.values)
	return out


func u_inverse_domain_read(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var lo: int = s.fy.min()
	var hi: int = s.fy.max()
	var ans := Answer.make("range2", interval(lo, hi), {"var": "x"})
	# Other slips: one end of f's domain kept with the other end of its range (where that
	# is an interval at all), both ends left out, one end left out.
	var out := {"asked": "Write down the domain of f⁻¹.", "answer": ans, "wrongs": [wrong(interval(s.xs.min(), s.xs.max()), R_DOMAIN_OF_F)],
		"fillers": proper([interval(lo, s.xs.max()), interval(s.xs.min(), hi), interval(lo, hi, "<", "<"), interval(lo, hi, "≤", "<")])}
	out.merge(show("graph", s, []))
	out.lines = ["The graph of f is shown, for %s ≤ x ≤ %s." % [N(s.xs.min()), N(s.xs.max())]]
	var final := "So the domain of f⁻¹ is %s." % Answer.text(ans)
	out.methods = _methods("inverse-domain-read", {
		"reflect-in-y-equals-x": ["Reflect the graph in y = x: the heights of f become the widths of f⁻¹", "f runs from %s to %s in height, so f⁻¹ runs from x = %s to x = %s" % [N(lo), N(hi), N(lo), N(hi)], final],
		"swap-domain-range": ["The domain of f⁻¹ is the range of f", "The lowest value of f is %s and the highest is %s" % [N(lo), N(hi)], final]}, [], ans.values)
	return out


func u_inverse_range_read(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var lo: int = s.xs.min()
	var hi: int = s.xs.max()
	var ans := Answer.make("range2", interval(lo, hi), {"var": "y"})
	# Other slips: one end of f's range kept with the other end of its domain (where that
	# is an interval at all), both ends left out, one end left out.
	var out := {"asked": "Write down the range of f⁻¹.", "answer": ans, "wrongs": [wrong(interval(s.fy.min(), s.fy.max()), R_DOMAIN_OF_F)],
		"fillers": proper([interval(s.fy.min(), hi), interval(lo, s.fy.max()), interval(lo, hi, "<", "<"), interval(lo, hi, "≤", "<")])}
	out.merge(show("graph", s, []))
	out.lines = ["The graph of f is shown, for %s ≤ x ≤ %s." % [N(lo), N(hi)]]
	var final := "So the range of f⁻¹ is %s." % Answer.text(ans)
	out.methods = _methods("inverse-range-read", {}, ["The range of f⁻¹ is the domain of f", "The graph of f starts at x = %s and ends at x = %s" % [N(lo), N(hi)], final], ans.values)
	return out


func u_solve_inverse_equation(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var i := rng.int_in(0, s.xs.size() - 1)
	var c: int = s.xs[i]
	var fc: int = s.fy[i]
	var p: int = [2, 3, 4, -2, -3][rng.int_in(0, 4)]
	# Not 0 (px = f(c) − q and −x would be the answer too), nor f(c) (stopping at f(c),
	# R_FC, would be).
	var x: int = pick_from(rng, [range(-4, 5).filter(func(t): return t != 0 and t != fc)])
	var q := fc - p * x
	var ans := Answer.make("xval", {"v": Q.new(x)})
	ans.exact = true
	# Other slips: px = f(c) − q not divided by p, c itself, q moved without its sign
	# changing, c used for f(c) (each where it is whole), the answer's sign lost, and
	# px + q worked out at x = c.
	var out := {"asked": "Solve f⁻¹(%s) = %s." % [Fmt.poly([p, q]), N(c)], "answer": ans, "wrongs": [wrong({"v": Q.new(fc)}, R_FC)],
		"fillers": fill([fc - q, c, (fc + q) / p if (fc + q) % p == 0 else null, (c - q) / p if (c - q) % p == 0 else null, -x, p * c + q])}
	out.merge(show(rep, s, [c, s.xs[(i + 1) % s.xs.size()], s.xs[(i + 2) % s.xs.size()]]))
	# px + q = f⁻¹(c) instead of f(c): needs f⁻¹(c), when c is an output.
	if c in s.fy:
		var back: int = s.xs[s.fy.find(c)]
		var slip := Q.new(back - q).div(Q.new(p))
		out.wrongs.append(wrong({"v": slip}, R_SOLVE_INVERSE))
	var final := "So %s." % Answer.text(ans)
	var line := "f⁻¹(%s) = %s means %s = f(%s)" % [Fmt.poly([p, q]), N(c), Fmt.poly([p, q]), N(c)]
	out.methods = _methods("solve-inverse-equation", {
		"solve-f-equals": [line, "Read f(%s) = %s, so %s = %s" % [N(c), N(fc), Fmt.poly([p, q]), N(fc)], "%sx = %s, so x = %s" % [Fmt.lead(p), N(fc - q), N(x)], final],
		"identity-property": ["Apply f to both sides: f(f⁻¹(%s)) = f(%s), and f undoes f⁻¹" % [Fmt.poly([p, q]), N(c)], "So %s = f(%s) = %s" % [Fmt.poly([p, q]), N(c), N(fc)], "%sx = %s, so x = %s" % [Fmt.lead(p), N(fc - q), N(x)], final]},
		[], ans.values)
	return out


func u_value_at_shifted_input(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var v := y_of(s, "f", k + 1)
	var ans := number("f(k + 1) = ", v)
	# Other slips: two steps on, f(k + 2); the input k + 1 given back; the answer's sign
	# lost; two steps back, f(k − 2); the input k − 1.
	var out := {"asked": "Given that f(k) = 0, find f(k + 1).", "answer": ans, "wrongs": [wrong({"v": Q.new(1)}, R_SHIFTED), wrong({"v": Q.new(k)}, R_K)],
		"fillers": fill([GraphTableSituation.at(s.xs, s.fy, k + 2), k + 1, -v, GraphTableSituation.at(s.xs, s.fy, k - 2), k - 1])}
	if has_x(s, k - 1):
		out.wrongs.append(wrong({"v": Q.new(y_of(s, "f", k - 1))}, R_BACK))
	out.merge(show(rep, s, [k, k + 1, s.xs[0] if s.xs[0] != k else s.xs[2]]))
	var final := "So %s." % Answer.text(ans)
	out.methods = _methods("value-at-shifted-input", {
		"solve-for-input": ["f(k) = 0 means k is the input whose output is 0: k = %s" % N(k), "Then k + 1 = %s, and f(%s) = %s" % [N(k + 1), N(k + 1), N(v)], final]},
		["Find where f is 0: x = %s, so k = %s" % [N(k), N(k)], "k + 1 = %s, so read f(%s) = %s" % [N(k + 1), N(k + 1), N(v)], final], ans.values)
	return out


# ── Two functions ────────────────────────────────────────────

func u_mixed_inverse_composite(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	# Not an output whose answer is b itself or g⁻¹(b) (R_INNER).
	var b: int = pick_from(rng, [GraphTableSituation.mixed_outputs(s), s.gy])
	var a: int = s.xs[s.gy.find(b)]
	var v := y_of(s, "f", a)
	var ans := number("(f∘g⁻¹)(%s) = " % N(b), v)
	# Other slips: f(b), g left out; g⁻¹(f(b)), the order swapped; b given back; the
	# answer's sign lost; g(b), f left out and g for g⁻¹; and last f read one column off.
	var fb = y_of(s, "f", b) if has_x(s, b) else null
	var out := {"asked": "Find (f∘g⁻¹)(%s)." % N(b), "answer": ans, "wrongs": [wrong({"v": Q.new(a)}, R_INNER)],
		"fillers": fill([fb, GraphTableSituation.where(s.xs, s.gy, fb) if fb != null else null, b, -v] + values_at(s, [b], "g") + values_at(s, [a + 1, a - 1]))}
	out.merge(show(rep, s, [], true))
	# g used for g⁻¹: f(g(b)), where g(b) is an input of f.
	if has_x(s, b) and has_x(s, y_of(s, "g", b)):
		out.wrongs.append(wrong({"v": Q.new(y_of(s, "f", y_of(s, "g", b)))}, R_VALUE_NOT_INVERSE))
	var final := "So %s." % Answer.text(ans)
	var steps := ["First g⁻¹(%s): find %s in the g row, it is at x = %s, so g⁻¹(%s) = %s" % [N(b), N(b), N(a), N(b), N(a)], "Then f(%s) = %s" % [N(a), N(v)], final]
	out.methods = _methods("mixed-inverse-composite", {"swap-coordinates": ["g(%s) = %s, so g⁻¹(%s) = %s (swap the coordinates)" % [N(a), N(b), N(b), N(a)], "Then f(%s) = %s" % [N(a), N(v)], final]}, steps, ans.values)
	return out


func u_missing_entry(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ins: Array = s.xs.filter(func(x): return y_of(s, "g", x) in s.xs)
	# Not an a whose g(a) is a itself, or whose (f∘g)(a) is g(a) (R_COMPOSITE) or f's
	# value there (R_VALUE_NOT_INVERSE).
	var a: int = pick_from(rng, [GraphTableSituation.missing_inputs(s), ins])
	var ga := y_of(s, "g", a)
	var v := y_of(s, "f", ga)
	var ans := number("g(%s) = " % N(a), ga)
	# Other slips: f read at a, a given back, the answer's sign lost, and last an entry
	# of g beside the blank copied.
	var out := {"asked": "The table has one entry missing. Given that (f∘g)(%s) = %s, find g(%s)." % [N(a), N(v), N(a)], "answer": ans, "wrongs": [],
		"fillers": fill([y_of(s, "f", a), a, -ga] + values_at(s, [a + 1, a - 1], "g"))}
	out.wrongs.append(wrong({"v": Q.new(v)}, R_COMPOSITE))
	# f(v) for f⁻¹(v): f applied to the composite's value instead of undone.
	if has_x(s, v):
		out.wrongs.append(wrong({"v": Q.new(y_of(s, "f", v))}, R_VALUE_NOT_INVERSE))
	out.table = table_of(s, true, a)
	out.lines = ["The table gives f and g, but g(%s) is missing." % N(a)]
	var final := "So %s." % Answer.text(ans)
	var steps := ["(f∘g)(%s) = f(g(%s)) = %s, so f of the missing entry is %s" % [N(a), N(a), N(v), N(v)], "In the f row, f(%s) = %s, so the missing entry is %s" % [N(ga), N(v), N(ga)], final]
	out.methods = _methods("missing-entry", {"swap-coordinates": ["f(g(%s)) = %s, so g(%s) = f⁻¹(%s)" % [N(a), N(v), N(a), N(v)], "Swap f's coordinates: f(%s) = %s gives f⁻¹(%s) = %s" % [N(ga), N(v), N(v), N(ga)], final]}, steps, ans.values)
	return out


func u_inverse_points(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	# Neither point on y = x (its image would be itself), and A the one lower down, so the
	# answer, which lists its points by x, reads A's image, then B's.
	var off_line := func(i): return s.fy[i] != s.xs[i]
	var picks: Array = [pick_from(rng, [[0, 1, 2].filter(off_line), [0, 1, 2]]), pick_from(rng, [[3, 4, 5].filter(off_line), [3, 4, 5]])]
	if s.fy[picks[0]] > s.fy[picks[1]]:
		picks.reverse()
	var vals := {"n": Q.new(2)}
	# The slips: each point reflected in the x-axis (p, −q) or the y-axis (−p, q); and
	# as fillers, the points of f left as they are, and reflected in y = −x.
	var x_axis := {"n": Q.new(2)}
	var y_axis := {"n": Q.new(2)}
	var same := {"n": Q.new(2)}
	var minus := {"n": Q.new(2)}
	for j in 2:
		var i: int = picks[j]
		vals["x%d" % j] = Q.new(s.fy[i])
		vals["y%d" % j] = Q.new(s.xs[i])
		x_axis["x%d" % j] = Q.new(s.xs[i])
		x_axis["y%d" % j] = Q.new(-s.fy[i])
		y_axis["x%d" % j] = Q.new(-s.xs[i])
		y_axis["y%d" % j] = Q.new(s.fy[i])
		same["x%d" % j] = Q.new(s.xs[i])
		same["y%d" % j] = Q.new(s.fy[i])
		minus["x%d" % j] = Q.new(-s.fy[i])
		minus["y%d" % j] = Q.new(-s.xs[i])
	var ans := Answer.make("pts", vals, {})
	var out := {"asked": "Two points on the graph of f are labelled A and B. Write down the matching points on the graph of f⁻¹.", "answer": ans,
		"wrongs": [wrong(x_axis, R_AXIS), wrong(y_axis, R_AXIS)], "fillers": [same, minus]}
	var g := graph_of(s)
	g.points = g.points.map(func(p): return p)
	for j in 2:
		for p in g.points:
			if int(p.x) == s.xs[picks[j]]:
				p.label = "%s %s" % ["AB"[j], Fmt.point(p.x, p.y)]
	out.graph = g
	out.lines = ["The graph of f is shown, with the points A and B."]
	var final := "So the points are %s." % Answer.text(ans)
	var pa := "A(%s, %s) swaps to (%s, %s)" % [N(s.xs[picks[0]]), N(s.fy[picks[0]]), N(s.fy[picks[0]]), N(s.xs[picks[0]])]
	var pb := "B(%s, %s) swaps to (%s, %s)" % [N(s.xs[picks[1]]), N(s.fy[picks[1]]), N(s.fy[picks[1]]), N(s.xs[picks[1]])]
	out.methods = _methods("inverse-points", {
		"swap-coordinates": ["Each point (p, q) of f gives the point (q, p) of f⁻¹", pa, pb, final],
		"reflect-in-y-equals-x": ["Reflecting in the line y = x swaps the x and y coordinates", pa, pb, final]}, [], ans.values)
	return out


# ── Graphs that turn back ────────────────────────────────────

func u_count_solutions(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var d := rng.int_in(1, 3)
	var p: int = s.p
	var k: int = s.c - d * d if s.up else -s.c + d * d
	var vals := {"n": Q.new(2), "x0": Q.new(p - d), "x1": Q.new(p + d)}
	var ans := Answer.make("xs", vals, {"var": "x"})
	ans.exact = true
	var out := {"asked": "Find every solution of f(x) = %s." % N(k), "answer": ans,
		# Other slips: the turning point's x for the crossing, both crossings' signs lost,
		# and k read as x.
		"wrongs": [wrong({"n": Q.new(1), "x0": Q.new(p + d)}, R_ONE_CROSSING)],
		"fillers": [{"n": Q.new(1), "x0": Q.new(p)}, {"n": Q.new(2), "x0": Q.new(-p - d), "x1": Q.new(-p + d)}, {"n": Q.new(1), "x0": Q.new(k)}]}
	out.merge(show("graph", s, []))
	out.lines = ["The graph of f turns back at x = %s." % N(p)]
	var final := "So %s." % Answer.text(ans)
	out.methods = _methods("count-solutions", {}, ["Draw the line y = %s across the graph" % N(k), "It crosses the graph twice, at x = %s and at x = %s" % [N(p - d), N(p + d)], final], ans.values)
	return out


func u_why_no_inverse(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var d := rng.int_in(1, 3)
	var p: int = s.p
	var k: int = s.c - d * d if s.up else -s.c + d * d
	var right := "It is not one-to-one: f(%s) = f(%s) = %s, so f⁻¹(%s) would have two values" % [N(p - d), N(p + d), N(k), N(k)]
	var every := "It has one: reflect the graph in y = x"
	# A near miss that names one-to-one too, with the height misread one grid line in from
	# x = p − d (a false statement), and a reason that is plainly no reason at all.
	var misread: int = GraphTableSituation.at(s.xs, s.fy, p - d + 1)
	var plain := ["It is not one-to-one: f(%s) = f(%s) = %s, so f⁻¹(%s) would have two values" % [N(p - d), N(p + d), N(misread), N(misread)],
		"It has no inverse because its graph is not a straight line",
		"It has no inverse because f(x) is not defined for x < %s" % N(s.xs.min())]
	var opts: Array = [right, every] + plain
	var ans := Answer.make("choice", {"v": right}, {"options": opts.slice(0, 4)})
	var out := {"asked": "Explain why f has no inverse on the domain shown.", "answer": ans, "wrongs": [wrong({"v": every}, R_EVERY_INVERSE)],
		"fillers": plain.map(func(t): return {"v": t})}
	out.merge(show("graph", s, []))
	out.lines = ["The graph of f turns back at x = %s." % N(p)]
	var final := right + "."
	out.methods = _methods("why-no-inverse", {"horizontal-line-test": ["A function has an inverse only if every horizontal line meets its graph at most once", "The line y = %s meets this graph at x = %s and x = %s" % [N(k), N(p - d), N(p + d)], final]},
		["Draw the horizontal line y = %s" % N(k), "It meets the graph at x = %s and x = %s, so two inputs share the output %s" % [N(p - d), N(p + d), N(k)], final], ans.values)
	return out


func u_restrict_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var ans := number("k = ", p)
	var lo: int = s.xs.min()
	# Other slips: the turning point's height for its x, the right end of the graph (the
	# whole domain), the turning point's sign lost.
	var out := {"asked": "Find the largest value of k for which f has an inverse on the domain %s ≤ x ≤ k." % N(lo), "answer": ans,
		"wrongs": [wrong({"v": Q.new(0)}, R_Y_INTERCEPT)], "fillers": fill([y_of(s, "f", p), s.xs.max(), -p])}
	out.merge(show("graph", s, []))
	out.lines = ["The graph of f is shown, for %s ≤ x ≤ %s." % [N(lo), N(s.xs.max())]]
	var final := "So %s." % Answer.text(ans)
	var steps := ["On %s ≤ x ≤ k the graph must never turn back, or a horizontal line would meet it twice" % N(lo), "The graph turns at x = %s, the turning point, so the domain can run up to it" % N(p), final]
	out.methods = _methods("restrict-from-graph", {}, steps, ans.values)
	return out
