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


func _angles(unknown: String) -> Array:
	var t := QuestionEngine.type_of(T)
	var out: Array = []
	for a in t.get("angles", []):
		if unknown in a.suits and not out.has(a.method):
			out.append(a.method)
	return out


## One working per method of the unknown: the same steps worded for the method.
func _methods(unknown: String, texts: Dictionary, default_steps: Array, result: Dictionary) -> Dictionary:
	var out := {}
	for a in _angles(unknown):
		out[a] = method(texts.get(a, default_steps), result)
	return out


# ── Reading a value ──────────────────────────────────────────

func u_read_value(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: int = s.xs[rng.int_in(0, s.xs.size() - 1)]
	var v := y_of(s, "f", a)
	var ans := number("f(%s) = " % N(a), v)
	var words_inputs := [a, s.xs[(s.xs.find(a) + 2) % s.xs.size()], s.xs[(s.xs.find(a) + 4) % s.xs.size()]]
	var out := {"asked": "Find f(%s)." % N(a), "answer": ans, "wrongs": [], "generic": [{"v": Q.new(a)}, {"v": Q.new(-v)}, {"v": Q.new(v + 1)}, {"v": Q.new(v - 1)}]}
	out.merge(show(rep, s, words_inputs))
	var final := "So %s." % Answer.text(ans)
	var where := "Find x = %s in the sentence" % N(a) if rep == "words" else ("Find x = %s in the top row of the table" % N(a) if rep == "table" else "Find x = %s on the horizontal axis" % N(a))
	var how := "Read the value beside it: f(%s) = %s" % [N(a), N(v)] if rep != "graph" else "Read the height of the graph there: f(%s) = %s" % [N(a), N(v)]
	var up := "Go up from x = %s to the graph, then across to the y-axis: f(%s) = %s" % [N(a), N(a), N(v)] if rep == "graph" else how
	out.methods = _methods("read-value", {"vertical-read": [where, up, final]}, [where, how, final], ans.values)
	return out


func u_value_from_rule(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: int = s.xs[rng.int_in(1, s.xs.size() - 2)]
	var v := rule_at(s, a)
	var ans := number("f(%s) = " % N(a), v)
	var rule := "f(x) = %s" % poly_text(s.co)
	var out := {"asked": "Find f(%s)." % N(a), "answer": ans, "lines": [rule], "wrongs": [], "generic": [{"v": Q.new(a)}, {"v": Q.new(-v)}, {"v": Q.new(s.co[0].n)}, {"v": Q.new(v + 1)}]}
	# The sign of the squared term lost: −x² read as (−x)² (or the other way round).
	if a != 0 and s.co[2].n != 0:
		var slip: int = s.co[0].n + s.co[1].n * a - s.co[2].n * a * a
		out.wrongs.append(wrong({"v": Q.new(slip)}, R_NOTATION_RULE))
	if rep == "graph":
		var curve := Plot.sample(func(x): return float(s.co[0].n) + s.co[1].n * x + s.co[2].n * x * x, -4.0, 4.0)
		var top := maxi(8, s.fy.max() + 1)
		out.graph = Plot.spec([curve], [], -4, 4, mini(-2, s.fy.min() - 1), mini(top, 14))
		out.lines = [rule, "The graph of y = f(x) is shown."]
	var putin := put(s.co, a)
	var final := "So %s." % Answer.text(ans)
	var subst := ["Put x = %s into the rule: f(%s) = %s" % [N(a), N(a), putin], "Work it out: f(%s) = %s" % [N(a), N(v)], final]
	out.methods = _methods("value-from-rule", {
		"vertical-read": ["Go up from x = %s to the curve, then across to the y-axis" % N(a), "The graph shows f(%s) = %s, which the rule confirms: %s" % [N(a), N(v), putin], final],
		"gdc-trace": ["Enter y1 = %s on the calculator" % poly_text(s.co), "Use the table or trace at x = %s: y1 = %s" % [N(a), N(v)], final]}, subst, ans.values)
	return out


func u_self_composite_read(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans: Dictionary
	var out: Dictionary
	var a: int
	var mid: int
	var v: int
	if s.mode == "rule":
		a = _rule_input(s, rng)
		mid = rule_at(s, a)
		v = rule_at(s, mid)
	else:
		var ins: Array = []
		for i in s.xs.size():
			if s.fy[i] in s.xs:
				ins.append(s.xs[i])
		a = ins[rng.int_in(0, ins.size() - 1)]
		mid = y_of(s, "f", a)
		v = y_of(s, "f", mid)
	ans = number("(f∘f)(%s) = " % N(a), v)
	out = {"asked": "Find (f∘f)(%s)." % N(a), "answer": ans, "wrongs": [wrong({"v": Q.new(mid * mid)}, R_PRODUCT)],
		"generic": [{"v": Q.new(mid)}, {"v": Q.new(a)}, {"v": Q.new(-v)}, {"v": Q.new(v + 1)}]}
	if s.mode == "rule":
		out.lines = ["f(x) = %s" % poly_text(s.co)]
		if rep == "graph":
			out.graph = graph_of(s)
			out.lines.append("The graph of f is shown. Each dot is on a grid point.")
		elif rep == "table":
			out.table = table_of(s, false)
			out.lines.append("The table gives f.")
	else:
		out.merge(show(rep, s, [a, mid, s.xs[0]]))
	var final := "So %s." % Answer.text(ans)
	var first := "f(%s) = %s" % [N(a), N(mid)]
	var second := "f(%s) = %s" % [N(mid), N(v)]
	var chain := ["Work from the inside out: %s" % first, "Then apply f again: %s" % second, final]
	out.methods = _methods("self-composite-read", {
		"read-graph-table": ["Read f(%s) from the %s: %s" % [N(a), "graph" if rep == "graph" else "table", first], "Read f(%s) the same way: %s" % [N(mid), second], final],
		"vertical-read": ["Go up from x = %s to the graph and across: %s" % [N(a), first], "Go up from x = %s and across: %s" % [N(mid), second], final],
		"direct-substitution": ["f(%s) = %s = %s" % [N(a), put(s.co, a), N(mid)], "f(%s) = %s = %s" % [N(mid), put(s.co, mid), N(v)], final] if s.mode == "rule" else chain,
		"chain-readings": chain, "inside-out": chain}, chain, ans.values)
	return out


## An input of a rule whose f(a) is small and whose f(f(a)) is not large.
func _rule_input(s: Dictionary, rng: Seeded) -> int:
	var ok: Array = []
	for a in range(-3, 4):
		var m := rule_at(s, a)
		if absi(m) <= 6 and absi(rule_at(s, m)) <= 99:
			ok.append(a)
	return ok[rng.int_in(0, ok.size() - 1)] if not ok.is_empty() else 0


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
	var a: int = ins[rng.int_in(0, ins.size() - 1)]
	var mid := y_of(s, inner, a)
	var v := y_of(s, outer, mid)
	var lab := "(%s∘%s)" % [outer, inner]
	var ans := number("%s(%s) = " % [lab, N(a)], v)
	var out := {"asked": "Find %s(%s)." % [lab, N(a)], "answer": ans, "wrongs": [], "generic": []}
	out.merge(show(rep, s, [], true))
	# The other order, the product and one function twice.
	if has_x(s, y_of(s, outer, a)):
		out.wrongs.append(wrong({"v": Q.new(y_of(s, inner, y_of(s, outer, a)))}, R_ORDER))
	out.wrongs.append(wrong({"v": Q.new(y_of(s, "f", a) * y_of(s, "g", a))}, R_PRODUCT))
	if has_x(s, y_of(s, inner, a)):
		out.wrongs.append(wrong({"v": Q.new(y_of(s, inner, y_of(s, inner, a)))}, R_TWICE))
	out.generic = [{"v": Q.new(mid)}, {"v": Q.new(v + 1)}, {"v": Q.new(-v)}]
	var final := "So %s." % Answer.text(ans)
	var steps := ["Start inside: %s(%s) = %s" % [inner, N(a), N(mid)], "Now apply %s to that: %s(%s) = %s" % [outer, outer, N(mid), N(v)], final]
	out.methods = _methods("composite-from-table", {}, steps, ans.values)
	return out


# ── Solving for an input ─────────────────────────────────────

func u_solve_from_table(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var i := rng.int_in(0, s.xs.size() - 1)
	var a: int = s.xs[i]
	var k: int = s.fy[i]
	var ans := Answer.make("xval", {"v": Q.new(a)})
	ans.exact = true
	var out := {"asked": "Solve f(x) = %s." % N(k), "answer": ans, "wrongs": [], "generic": []}
	out.merge(show(rep, s, [a, s.xs[(i + 1) % s.xs.size()], s.xs[(i + 3) % s.xs.size()]]))
	# f(k), the output at input k, when k is an input.
	# (A sentence lists only some values, so the slip is offered only from a table or a graph.)
	if rep != "words" and has_x(s, k) and k != a:
		out.wrongs.append(wrong({"v": Q.new(y_of(s, "f", k))}, R_SOLVE_AS_VALUE))
	out.generic = [{"v": Q.new(k)}, {"v": Q.new(a + 1)}, {"v": Q.new(a - 1)}]
	var final := "So %s." % Answer.text(ans)
	var where := "the %s" % ("graph" if rep == "graph" else "table" if rep == "table" else "sentence")
	out.methods = _methods("solve-from-table", {
		"horizontal-line": ["Draw the line y = %s across the graph" % N(k) if rep == "graph" else "Look along the f(x) values for %s" % N(k), "It meets f at x = %s" % N(a), final],
		"solve-for-input": ["We need the input whose output is %s, so look for %s in the f(x) values of %s" % [N(k), N(k), where], "f(%s) = %s, so x = %s" % [N(a), N(k), N(a)], final]},
		[], ans.values)
	return out


# ── Inverse readings ─────────────────────────────────────────

func _output_in_inputs(s: Dictionary, rng: Seeded) -> int:
	var both: Array = s.fy.filter(func(y): return y in s.xs)
	var pool: Array = both if not both.is_empty() else s.fy
	return pool[rng.int_in(0, pool.size() - 1)]


func u_inverse_value_read(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var b := _output_in_inputs(s, rng)
	var a: int = s.xs[s.fy.find(b)]
	var ans := number("f⁻¹(%s) = " % N(b), a)
	var out := {"asked": "Find f⁻¹(%s)." % N(b), "answer": ans, "wrongs": [], "generic": [{"v": Q.new(b)}, {"v": Q.new(-a)}, {"v": Q.new(a + 1)}]}
	out.merge(show(rep, s, [a, s.xs[(s.xs.find(a) + 1) % s.xs.size()], s.xs[(s.xs.find(a) + 3) % s.xs.size()]]))
	if rep != "words" and has_x(s, b):
		out.wrongs.append(wrong({"v": Q.new(y_of(s, "f", b))}, R_VALUE_NOT_INVERSE))
		if y_of(s, "f", b) != 0:
			out.wrongs.append(wrong({"v": Q.new(1).div(Q.new(y_of(s, "f", b)))}, R_RECIPROCAL))
	var final := "So %s." % Answer.text(ans)
	out.methods = _methods("inverse-value-read", {
		"horizontal-line": ["Start on the y-axis at %s and go across to the graph" % N(b) if rep == "graph" else "Find %s in the f(x) values" % N(b), "Read down to the x-axis: the input is %s" % N(a), final],
		"swap-coordinates": ["f(%s) = %s is a point of f, so (%s, %s) is a point of f⁻¹" % [N(a), N(b), N(a), N(b)], "Swap the coordinates: f⁻¹(%s) = %s" % [N(b), N(a)], final],
		"solve-f-equals": ["f⁻¹(%s) is the x with f(x) = %s" % [N(b), N(b)], "Find %s among the f(x) values: it is at x = %s" % [N(b), N(a)], final]}, [], ans.values)
	return out


func u_inverse_domain_read(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var lo: int = s.fy.min()
	var hi: int = s.fy.max()
	var ans := Answer.make("range2", {"lo": Q.new(lo), "r1": "≤", "r2": "≤", "hi": Q.new(hi)}, {"var": "x"})
	var out := {"asked": "Write down the domain of f⁻¹.", "answer": ans, "wrongs": [wrong({"lo": Q.new(s.xs.min()), "r1": "≤", "r2": "≤", "hi": Q.new(s.xs.max())}, R_DOMAIN_OF_F)], "generic": []}
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
	var ans := Answer.make("range2", {"lo": Q.new(lo), "r1": "≤", "r2": "≤", "hi": Q.new(hi)}, {"var": "y"})
	var out := {"asked": "Write down the range of f⁻¹.", "answer": ans, "wrongs": [wrong({"lo": Q.new(s.fy.min()), "r1": "≤", "r2": "≤", "hi": Q.new(s.fy.max())}, R_DOMAIN_OF_F)], "generic": []}
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
	var x := rng.int_in(-4, 4)
	var q := fc - p * x
	var ans := Answer.make("xval", {"v": Q.new(x)})
	ans.exact = true
	var out := {"asked": "Solve f⁻¹(%s) = %s." % [Fmt.poly([p, q]), N(c)], "answer": ans, "wrongs": [], "generic": [{"v": Q.new(c)}, {"v": Q.new(fc)}, {"v": Q.new(x + 1)}]}
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
	var out := {"asked": "Given that f(k) = 0, find f(k + 1).", "answer": ans, "wrongs": [wrong({"v": Q.new(1)}, R_SHIFTED)],
		"generic": [{"v": Q.new(k)}, {"v": Q.new(y_of(s, "f", k - 1) if has_x(s, k - 1) else v + 2)}, {"v": Q.new(-v)}]}
	out.merge(show(rep, s, [k, k + 1, s.xs[0] if s.xs[0] != k else s.xs[2]]))
	var final := "So %s." % Answer.text(ans)
	out.methods = _methods("value-at-shifted-input", {
		"solve-for-input": ["f(k) = 0 means k is the input whose output is 0: k = %s" % N(k), "Then k + 1 = %s, and f(%s) = %s" % [N(k + 1), N(k + 1), N(v)], final]},
		["Find where f is 0: x = %s, so k = %s" % [N(k), N(k)], "k + 1 = %s, so read f(%s) = %s" % [N(k + 1), N(k + 1), N(v)], final], ans.values)
	return out


# ── Two functions ────────────────────────────────────────────

func u_mixed_inverse_composite(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var b: int = s.gy[rng.int_in(0, s.gy.size() - 1)]
	var a: int = s.xs[s.gy.find(b)]
	var v := y_of(s, "f", a)
	var ans := number("(f∘g⁻¹)(%s) = " % N(b), v)
	var out := {"asked": "Find (f∘g⁻¹)(%s)." % N(b), "answer": ans, "wrongs": [], "generic": [{"v": Q.new(a)}, {"v": Q.new(b)}, {"v": Q.new(-v)}, {"v": Q.new(v + 1)}]}
	out.merge(show(rep, s, [], true))
	if has_x(s, b):
		out.wrongs.append(wrong({"v": Q.new(y_of(s, "f", y_of(s, "g", b)) if has_x(s, y_of(s, "g", b)) else y_of(s, "f", b))}, R_VALUE_NOT_INVERSE))
	var final := "So %s." % Answer.text(ans)
	var steps := ["First g⁻¹(%s): find %s in the g row, it is at x = %s, so g⁻¹(%s) = %s" % [N(b), N(b), N(a), N(b), N(a)], "Then f(%s) = %s" % [N(a), N(v)], final]
	out.methods = _methods("mixed-inverse-composite", {"swap-coordinates": ["g(%s) = %s, so g⁻¹(%s) = %s (swap the coordinates)" % [N(a), N(b), N(b), N(a)], "Then f(%s) = %s" % [N(a), N(v)], final]}, steps, ans.values)
	return out


func u_missing_entry(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ins: Array = s.xs.filter(func(x): return y_of(s, "g", x) in s.xs)
	var a: int = ins[rng.int_in(0, ins.size() - 1)]
	var ga := y_of(s, "g", a)
	var v := y_of(s, "f", ga)
	var ans := number("g(%s) = " % N(a), ga)
	var out := {"asked": "The table has one entry missing. Given that (f∘g)(%s) = %s, find g(%s)." % [N(a), N(v), N(a)], "answer": ans, "wrongs": [],
		"generic": [{"v": Q.new(v)}, {"v": Q.new(a)}, {"v": Q.new(-ga)}, {"v": Q.new(ga + 1)}]}
	out.table = table_of(s, true, a)
	out.lines = ["The table gives f and g, but g(%s) is missing." % N(a)]
	var final := "So %s." % Answer.text(ans)
	var steps := ["(f∘g)(%s) = f(g(%s)) = %s, so f of the missing entry is %s" % [N(a), N(a), N(v), N(v)], "In the f row, f(%s) = %s, so the missing entry is %s" % [N(ga), N(v), N(ga)], final]
	out.methods = _methods("missing-entry", {"swap-coordinates": ["f(g(%s)) = %s, so g(%s) = f⁻¹(%s)" % [N(a), N(v), N(a), N(v)], "Swap f's coordinates: f(%s) = %s gives f⁻¹(%s) = %s" % [N(ga), N(v), N(v), N(ga)], final]}, steps, ans.values)
	return out


func u_inverse_points(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var picks: Array = [rng.int_in(0, 2), rng.int_in(3, 5)]
	var vals := {"n": Q.new(2)}
	var wrong_axis := {"n": Q.new(2)}
	for j in 2:
		var i: int = picks[j]
		vals["x%d" % j] = Q.new(s.fy[i])
		vals["y%d" % j] = Q.new(s.xs[i])
		wrong_axis["x%d" % j] = Q.new(s.xs[i])
		wrong_axis["y%d" % j] = Q.new(-s.fy[i])
	var ans := Answer.make("pts", vals, {})
	var out := {"asked": "Two points on the graph of f are labelled A and B. Write down the matching points on the graph of f⁻¹.", "answer": ans,
		"wrongs": [wrong(wrong_axis, R_AXIS)], "generic": []}
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
		"wrongs": [wrong({"n": Q.new(1), "x0": Q.new(p + d)}, R_ONE_CROSSING)], "generic": [{"n": Q.new(2), "x0": Q.new(p - d), "x1": Q.new(p + d + 1)}, {"n": Q.new(2), "x0": Q.new(-p - d), "x1": Q.new(-p + d)}]}
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
	var plain := ["It has no inverse because f(x) is not defined for x < %s" % N(s.xs.min()),
		"It has no inverse because it has a maximum" if s.up else "It has no inverse because it has a minimum",
		"It is not one-to-one: f(%s) = f(%s) = %s, so f⁻¹(%s) would have two values" % [N(p - d), N(p + d), N(k + 1), N(k + 1)]]
	var opts: Array = [right, every] + plain
	var ans := Answer.make("choice", {"v": right}, {"options": opts.slice(0, 4)})
	var out := {"asked": "Explain why f has no inverse on the domain shown.", "answer": ans, "wrongs": [wrong({"v": every}, R_EVERY_INVERSE)],
		"generic": plain.map(func(t): return {"v": t})}
	out.merge(show("graph", s, []))
	out.lines = ["The graph of f turns back at x = %s." % N(p)]
	var final := right + "."
	out.methods = _methods("why-no-inverse", {"horizontal-line-test": ["A function has an inverse only if every horizontal line meets its graph at most once", "The line y = %s meets this graph at x = %s and x = %s" % [N(k), N(p - d), N(p + d)], final]},
		["Draw the horizontal line y = %s" % N(k), "It meets the graph at x = %s and x = %s, so two inputs share the output %s" % [N(p - d), N(p + d), N(k)], final], ans.values)
	return out


func u_restrict_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var ans := number("k = ", p)
	var out := {"asked": "Find the largest value of k for which f has an inverse on the domain x ≤ k.", "answer": ans,
		"wrongs": [wrong({"v": Q.new(0)}, R_Y_INTERCEPT)], "generic": [{"v": Q.new(p + 1)}, {"v": Q.new(-p)}, {"v": Q.new(p - 1)}]}
	out.merge(show("graph", s, []))
	out.lines = ["The graph of f is shown, for %s ≤ x ≤ %s." % [N(s.xs.min()), N(s.xs.max())]]
	var final := "So %s." % Answer.text(ans)
	var steps := ["On x ≤ k the graph must never turn back, or a horizontal line would meet it twice", "The graph turns at x = %s, the turning point, so the domain can run up to it" % N(p), final]
	out.methods = _methods("restrict-from-graph", {}, steps, ans.values)
	return out
