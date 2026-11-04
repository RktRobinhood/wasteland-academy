class_name BasicFunctionViews
extends ExtensionViews
## The views on the `basic-function` situation (FAL-424): one builder per unknown of
## fn-evaluate-function and of fn-concept-function-notation. A value is typed; a meaning, a
## comparison or an expression to pick is one of four sentences (the `choice` kind).
##
## Paper 1 outputs are whole numbers or simple fractions, marked exactly. On Paper 2 (the
## exam's six parts in seven) rules and inputs have decimals and answers are to 3 s.f. with
## the rounding trap. A view that reads a graph or a table stays on whole numbers on both
## papers: the calculator has nothing to add to a reading.

const T := "fn-evaluate-function"
const R_SQUARE := "SL2.2.evaluate-notation#1"
const R_SHIFT := "SL2.2.evaluate-notation#2"
const R_NOTHING := "SL2.2.function-model#0"
const R_NEGATIVE := "SL2.2.function-model#1"
const R_OUTPUT := "SL2.2.function-model#2"
const R_ZERO_YINT := "SL2.4.zeros-intercepts#0"
const R_ZERO_SIGN := "SL2.4.zeros-intercepts#1"
const R_RANGE_DOMAIN := "SL2.2.domain#2"
const R_TIMES := "SL2.2.evaluate-notation#0"
const R_RECIPROCAL := "SL2.2.inverse-undo#0"


func needs() -> Dictionary:
	return {
		"value-at-zero": {"kind": "model"},
		"value-at-input": {"kind": "any"},
		"y-intercept": {"kind": "roots"},
		"above-or-below": {"kind": "plain"},
		"read-from-table": {"kind": "grid"},
		"read-from-graph": {"kind": "grid"},
		"interpret-value": {"kind": "model"},
		"input-from-output": {"kind": "levels"},
		"expression-input": {"kind": "expression"},
		"zeros": {"kind": "roots"},
		"time-for-target": {"kind": "model"},
		"model-domain": {"kind": "model"},
		# fn-concept-function-notation
		"inside-or-outside-shift": {"kind": "notation"},
		"inside-or-outside-scale": {"kind": "notation"},
		"inverse-or-reciprocal": {"kind": "inverse"},
		"match-expressions": {"kind": "inverse"},
		"when-equal": {"kind": "inverse"},
	}


## Words mean a context, and a graph or a table of roots stays on grid points.
func need(unknown: String, rep: String) -> Dictionary:
	var n := super.need(unknown, rep)
	if unknown == "value-at-input" and rep == "words":
		n.kind = "model"
	if rep != "equation" and unknown in ["y-intercept", "input-from-output", "zeros"]:
		n.grid = true
	return n


func extra() -> Dictionary:
	return {"inside-or-outside-shift": ["true-false-reason"], "inside-or-outside-scale": ["true-false-reason", "error-spot"],
		"inverse-or-reciprocal": ["true-false-reason"]}


## Paper 2 for a calculator's method, Paper 1 for reading a factorised rule, and either
## for the rest. Extension types get no paper from the engine.
func papers(_unknown: String, _rep: String, method_id: String) -> Array:
	if method_id.begins_with("gdc-"):
		return [2]
	if method_id == "factorised-read":
		return [1]
	return [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	if out.trap.is_empty():
		out.trap = Answer.rounding_trap_all(out.answer)
	var own: Dictionary = out.get("given", {}) if out.get("given") != null else {}
	out.given = BasicFunctionSituation.export(s)
	out.given.merge(ExtensionViews.export(own), true)
	return out


# ── Helpers ──────────────────────────────────────────────────

static func p2(s: Dictionary) -> bool:
	return s.get("paper", 1) == 2


## How a value is written and marked: exact on Paper 1; on Paper 2 as a decimal when it
## ends in 3 figures, else to 3 s.f.
static func style(ans: Dictionary, v: Variant, s: Dictionary) -> Dictionary:
	if s.get("ctx", "") == "cost":
		ans.show = "money"
		ans.exact = true
	elif p2(s):
		ans.show = "sf" if Answer.needs_rounding(Q.of(v)) else "dec"
	else:
		ans.exact = true
	return ans


static func value(label: String, v: Q, s: Dictionary, unit: String = "") -> Dictionary:
	return style(Answer.make("number", {"v": v}, {}, label, unit), v, s)


## A number in the working: up to 6 figures, without trailing zeros.
static func W(v: Variant) -> String:
	var q := Q.of(v)
	if not Answer.needs_rounding(q):
		return Fmt.dec(q) if q.d != 3 else Fmt.num(q)
	var t := Fmt.sf(q, 6)
	if t.contains("."):
		t = t.rstrip("0").rstrip(".")
	return t


## A number as an option says it: 3 s.f. on Paper 2, exact on Paper 1.
static func say(v: Variant, s: Dictionary) -> String:
	if s.get("ctx", "") == "cost":
		return Fmt.money(v)
	if not p2(s):
		return Fmt.num(v)
	return Fmt.sf(v) if Answer.needs_rounding(Q.of(v)) else Fmt.dec(v)


static func call_at(s: Dictionary, x: Variant) -> String:
	return "%s(%s)" % [s.name, Fmt.dec(x)]


## The rule with an input written in: "−5(3)² + 15(3) + 20".
static func put_in(s: Dictionary, x: Variant) -> String:
	return BasicFunctionSituation.text(s.f, s.v).replace(s.v, "(%s)" % Fmt.dec(x))


static func ways(steps: Dictionary, last: String, ans: Dictionary) -> Dictionary:
	var out := {}
	for a in steps:
		out[a] = method(steps[a] + [last], ans.values)
	return out


static func final(ans: Dictionary) -> String:
	return "So %s." % Answer.text(ans)


static func choose(right: String, bad: Array, plain: Array) -> Dictionary:
	return InverseRuleViews.choose(right, bad, plain)


static func tag(text: String, ref: String) -> Dictionary:
	return InverseRuleViews.tag(text, ref)


## Wrong numbers as generic options, leaving out any that read as `right` does.
static func nums(vals: Array, right: Variant = null) -> Array:
	var kept := vals if right == null else vals.filter(func(v): return Fmt.sf(v) != Fmt.sf(right))
	return kept.map(func(v): return {"v": v})


## The graph of f, in a window round it, with its dots and the axes' names.
static func graph_of(s: Dictionary, lo: float, hi: float, points: Array = [], hlines: Array = []) -> Dictionary:
	var pts := Plot.sample(func(x): return BasicFunctionSituation.fl(s.f, x), lo, hi)
	var ys: Array = pts.map(func(p): return p[1])
	var win := GdcKit.window(lo, hi, minf(ys.min(), 0.0), maxf(ys.max(), 0.0))
	var g := Plot.spec([pts], points, win[0], win[1], win[2], win[3], hlines)
	g.one_colour = true
	if s.v != "x":
		g.x_name = s.v
		g.y_name = s.name
	return g


# ── fn-evaluate-function ─────────────────────────────────────

func u_value_at_zero(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y: Q = s.y_int
	var head := call_at(s, 0)
	var sub := "Put %s = 0 into the rule: %s = %s" % [s.v, head, say(y, s)]
	if rep == "words":
		var right := BasicFunctionSituation.start(s, say(y, s))
		var wrongs := [tag("There is nothing yet at the start", R_NOTHING)]
		var plain := [BasicFunctionSituation.said(s, say(y, s), "0"), "The value goes up by %s in each step of %s" % [say(y, s), s.v],
			"The value can never go below %s" % say(y, s)]
		var out := {"asked": "What is the value of %s, and what does it mean here?" % head, "lines": [BasicFunctionSituation.setup(s)]}
		out.merge(choose(right, wrongs, plain))
		var last := "So %s = %s: %s." % [head, say(y, s), right]
		out.methods = ways({"direct-substitution": [sub], "substitute-interpret": [sub, "%s = 0 is the moment it starts, so this is the start value" % s.v]}, last, out.answer)
		return out
	var ans := value(head + " = ", y, s)
	var out2 := {"asked": "Find %s." % head, "lines": [BasicFunctionSituation.setup(s)], "answer": ans,
		"wrongs": [wrong({"v": Q.new(0)}, R_NOTHING)], "generic": nums([BasicFunctionSituation.at(s.f, s.x0), y.add(1), y.neg()], y)}
	out2.methods = ways({"direct-substitution": [sub], "substitute-interpret": [sub, "%s = 0 is the start, so this is the start value" % s.v]}, final(ans), ans)
	return out2


func u_value_at_input(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x0: Q = s.x0
	var y0: Q = s.y0
	var head := call_at(s, x0)
	var ans := value(head + " = ", y0, s)
	var lines: Array = [BasicFunctionSituation.setup(s)] if s.has("ctx") else ["%s" % BasicFunctionSituation.eqn(s)]
	var wrongs: Array = []
	var f: Dictionary = s.f
	# −x² at x = −3 taken as +9: the square's sign is lost.
	if f.fam == "poly" and x0.sign() < 0 and f.co[2].sign() < 0:
		wrongs.append(wrong({"v": y0.sub(f.co[2].mul(x0.sq()).mul(2))}, R_SQUARE))
	var plain: Array = [s.y_int, y0.neg(), y0.add(1)]
	if not is_nan(BasicFunctionSituation.fl(f, x0.neg().to_float())):
		plain.push_front(BasicFunctionSituation.at(f, x0.neg()))
	var out := {"asked": "Find %s." % head, "lines": lines, "answer": ans, "wrongs": wrongs, "generic": nums(plain, y0)}
	var sub := "Replace each %s with (%s): %s = %s" % [s.v, Fmt.dec(x0), head, put_in(s, x0)]
	var work := "Work it out: %s = %s" % [head, W(y0)]
	var mean: Array = ["In context: " + BasicFunctionSituation.said(s, Fmt.dec(x0), say(y0, s))] if s.has("ctx") else ["That is the height of the graph at %s = %s" % [s.v, Fmt.dec(x0)]]
	out.methods = ways({"direct-substitution": [sub, work], "gdc-value": ["Enter the rule on the calculator as %s" % BasicFunctionSituation.text(f, s.v), "Evaluate it at %s = %s: %s" % [s.v, Fmt.dec(x0), W(y0)]],
		"substitute-interpret": [sub, work] + mean, "gdc-table-trace": ["Table the rule on the calculator, with %s = %s among the inputs" % [s.v, Fmt.dec(x0)], "Read the row for %s: %s" % [Fmt.dec(x0), W(y0)]]}, final(ans), ans)
	return out


func u_y_intercept(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y: Q = s.y_int
	var ans := style(Answer.make("yint", {"y": y}), y, s)
	# A zero as an option, written as this answer writes its number.
	var zs: Array = s.zs.filter(func(z): return not z.eq(y)).map(func(z): return Answer.parse_number(Fmt.sf(z).replace("−", "-")).q)
	var plain := [{"y": y.add(1)}, {"y": y.neg()}, {"y": s.f.co[1]}, {"y": s.f.co[2]}]
	var out := {"asked": "Find the y-intercept of the graph of y = f(x).", "answer": ans, "generic": plain,
		"wrongs": [wrong({"y": zs[0]}, R_ZERO_YINT)] if not zs.is_empty() else []}
	var read := "Read where the curve meets the y-axis: the height there is %s" % say(y, s)
	if rep == "graph":
		out.lines = ["The graph of y = f(x) is shown."]
		var lo: float = s.zs[0].to_float() - 2.0
		var hi: float = s.zs[1].to_float() + 2.0
		out.graph = graph_of(s, minf(lo, -1.0), maxf(hi, 1.0))
		var at0 := "The y-axis is where x = 0, so the intercept is the point (0, f(0))"
		out.methods = ways({"direct-substitution": [at0, read], "set-equal-zero": ["Set x = 0, not y = 0: that finds the y-axis", read], "graph-read": [read, "Its x-coordinate is 0"]}, final(ans), ans)
		return out
	out.lines = [BasicFunctionSituation.eqn(s)]
	var sub := "Put x = 0: f(0) = %s = %s" % [put_in(s, 0), say(y, s)]
	out.methods = ways({"direct-substitution": ["The y-axis is where x = 0", sub], "set-equal-zero": ["Set x = 0, not y = 0: y = 0 would give the zeros", sub], "graph-read": ["Plot the curve and find where it meets the y-axis, at x = 0", sub]}, final(ans), ans)
	return out


func u_above_or_below(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var x0: Q = s.x0
	var y0: Q = s.y0
	var yf := y0.to_float()
	var py: Q
	if p2(s):
		py = Q.new(roundi(yf * 10.0) + rng.pick([-3, -2, -1, 1, 2, 3]), 10)
	else:
		py = Q.new(roundi(yf) + rng.pick([-2, -1, 1, 2]))
	if py.to_float() == yf:
		py = py.add(1)
	var above := py.to_float() > yf
	var head := call_at(s, x0)
	var v := W(y0)
	var size := "less" if above else "more"
	var other := "more" if above else "less"
	var right := "%s: %s = %s, which is %s than %s" % ["Above" if above else "Below", head, v, size, Fmt.dec(py)]
	var plain := ["%s: %s = %s, which is %s than %s" % ["Below" if above else "Above", head, v, size, Fmt.dec(py)],
		"%s: %s = %s, which is %s than %s" % ["Above" if above else "Below", head, v, other, Fmt.dec(py)],
		"On the graph: %s = %s, which is close to %s" % [head, v, Fmt.dec(py)]]
	var pt := "(%s, %s)" % [Fmt.dec(x0), Fmt.dec(py)]
	var out := {"asked": "Is the point %s above, below or on the graph of y = f(x)?" % pt, "lines": [BasicFunctionSituation.eqn(s)], "given": {"px": x0, "py": py}}
	out.merge(choose(right, [], plain))
	var cmp := "Compare heights: the point is at %s, and the graph is at %s" % [Fmt.dec(py), v]
	out.methods = ways({"direct-substitution": ["Find the graph's height at x = %s: %s = %s = %s" % [Fmt.dec(x0), head, put_in(s, x0), v], cmp],
		"gdc-value": ["Evaluate the rule on the calculator at x = %s: %s" % [Fmt.dec(x0), v], cmp]}, "So: %s." % right, out.answer)
	return out


## A table of f at five or six whole inputs round x0.
static func table_of(s: Dictionary, xs: Array) -> Dictionary:
	return {"rows": [["x", xs.map(func(x): return Fmt.num(x))], ["f(x)", xs.map(func(x): return Fmt.num(BasicFunctionSituation.at(s.f, x)))]]}


func u_read_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x0: int = s.x0.n
	var xs: Array = range(x0 - 2, x0 + 3)
	var ans := Answer.make("number", {"v": s.y0}, {}, "f(%s) = " % Fmt.num(x0))
	ans.exact = true
	var out := {"asked": "Find f(%s)." % Fmt.num(x0), "lines": ["The table gives values of f."], "table": table_of(s, xs), "answer": ans, "wrongs": [],
		"generic": nums([BasicFunctionSituation.at(s.f, x0 + 1), BasicFunctionSituation.at(s.f, x0 - 1), Q.new(x0), s.y0.add(1)])}
	out.methods = ways({"read-graph-table": ["Find %s in the x row" % Fmt.num(x0), "Read the f(x) entry under it: %s" % Fmt.num(s.y0)]}, final(ans), ans)
	return out


func u_read_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x0: int = s.x0.n
	var ans := Answer.make("number", {"v": s.y0}, {}, "f(%s) = " % Fmt.num(x0))
	ans.exact = true
	var out := {"asked": "Find f(%s)." % Fmt.num(x0), "lines": ["The graph of y = f(x) is shown."], "graph": graph_of(s, x0 - 3.0, x0 + 3.0, []), "answer": ans, "wrongs": [],
		"generic": nums([Q.new(x0), BasicFunctionSituation.at(s.f, x0 + 1), BasicFunctionSituation.at(s.f, x0 - 1), s.y0.add(1)])}
	out.methods = ways({"read-graph-table": ["Go along the x-axis to x = %s" % Fmt.num(x0), "Go up or down to the curve, and across to the y-axis: %s" % Fmt.num(s.y0)]}, final(ans), ans)
	return out


func u_interpret_value(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var at_zero := rng.chance(0.5)
	var x: Q = Q.new(0) if at_zero else s.x0
	var y: Q = s.y_int if at_zero else s.y0
	var head := call_at(s, x)
	var right: String = BasicFunctionSituation.start(s, say(y, s)) if at_zero else BasicFunctionSituation.said(s, Fmt.dec(x), say(y, s))
	var wrongs: Array = [tag("There is nothing yet at the start", R_NOTHING)] if at_zero else []
	var plain: Array = [BasicFunctionSituation.said(s, say(y, s), Fmt.dec(x)), "%s changes by %s for each step of %s" % [s.name, say(y, s), s.v],
		"%s is multiplied by %s" % [s.v, say(y, s)], "%s is %s when %s reaches its largest value" % [s.name, say(y, s), s.v]]
	var out := {"asked": "What does %s = %s mean here?" % [head, say(y, s)], "lines": [BasicFunctionSituation.setup(s)]}
	out.merge(choose(right, wrongs, plain))
	out.methods = ways({"substitute-interpret": ["The number in the brackets is the input: %s = %s" % [s.v, Fmt.dec(x)], "The value is the output: %s = %s" % [s.name, say(y, s)]]}, "So: %s." % right, out.answer)
	return out


func u_input_from_output(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: Q = s.k
	var zs: Array = s.zs
	var ans := style(Answer.make("xs", Answer.xs_of(zs)), zs[0], s)
	var out := {"asked": "Find every value of x for which f(x) = %s." % Fmt.num(k), "answer": ans,
		"wrongs": [wrong(Answer.xs_of([k]), R_OUTPUT)],
		# An option as long as the answer comes first, so a typed answer has a wrong one to match.
		"generic": [Answer.xs_of([zs[0].neg(), zs[1].neg()]), Answer.xs_of([zs[0].add(1), zs[1].add(1)]), Answer.xs_of([zs[0]]), Answer.xs_of([zs[1]]), Answer.xs_of([s.f.co[0]])]}
	var solve := "Solve f(x) = %s: %s = %s" % [Fmt.num(k), BasicFunctionSituation.text(s.f), Fmt.num(k)]
	var read := "Look for %s in the outputs and read the inputs that give it" % Fmt.num(k)
	var vals := "They are x = %s and x = %s" % [W(zs[0]), W(zs[1])]
	var steps := {"read-graph-table": [read, vals], "solve-for-input": [solve, "Bring the %s over to the left and solve the quadratic" % Fmt.num(k), vals]}
	if rep == "table":
		var xs: Array = range(s.p.n - 1, s.q.n + 2)
		out.lines = ["The table gives values of f."]
		out.table = table_of(s, xs)
	elif rep == "graph":
		out.lines = ["The graph of y = f(x) is shown, with the line y = %s dashed." % Fmt.num(k)]
		out.graph = graph_of(s, s.zs[0].to_float() - 2.0, s.zs[1].to_float() + 2.0, [], [[k.to_float(), ""]])
		steps["read-graph-table"] = ["Find where the curve meets the dashed line y = %s" % Fmt.num(k), "Read down to the x-axis: " + vals.to_lower()]
	else:
		out.lines = [BasicFunctionSituation.eqn(s)]
	out.methods = ways(steps, final(ans), ans)
	return out


func u_expression_input(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c: Array = s.f.co
	var a2: Q = c[2]
	var a1: Q = c[1]
	var a0: Q = c[0]
	var mode: int = rng.int_in(0, 2)
	var h: int = rng.int_in(1, 3)
	var head: String
	var inner: String
	var v: Dictionary
	var bad: Dictionary
	match mode:
		0:
			head = "f(x + %d)" % h
			inner = "x + %d" % h
			v = {"A": a2, "B": a2.mul(2 * h).add(a1), "C": a2.mul(h * h).add(a1.mul(h)).add(a0)}
			bad = {"A": a2, "B": a1, "C": a0.add(h)}
		1:
			head = "f(2x)"
			inner = "2x"
			v = {"A": a2.mul(4), "B": a1.mul(2), "C": a0}
			bad = {"A": a2.mul(2), "B": a1.mul(2), "C": a0.mul(2)}
		_:
			head = "f(−x)"
			inner = "−x"
			v = {"A": a2, "B": a1.neg(), "C": a0}
			bad = {"A": a2.neg(), "B": a1.neg(), "C": a0.neg()}
	var ans := Answer.make("quad_in", v, {}, head + " = ")
	ans.exact = true
	var wrongs: Array = [wrong(bad, R_SHIFT if mode == 0 else "")]
	var sub := Fmt.poly([a2, a1, a0]).replace("x", "(%s)" % inner)
	var out := {"asked": "Write %s in the form Ax² + Bx + C." % head, "lines": [BasicFunctionSituation.eqn(s)], "answer": ans, "wrongs": wrongs,
		"generic": [{"A": v.A, "B": v.B.add(1), "C": v.C}, {"A": v.A, "B": v.B, "C": v.C.add(2)}, {"A": a2, "B": a1, "C": a0}]}
	out.methods = ways({"direct-substitution": ["Replace each x with (%s): %s = %s" % [inner, head, sub], "Expand the brackets and collect like terms"]}, final(ans), ans)
	return out


func u_zeros(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var zs: Array = s.zs
	var ans := style(Answer.make("xs", Answer.xs_of(zs)), zs[0], s)
	var flipped: Array = zs.map(func(z): return z.neg())
	var out := {"asked": "Find the zeros of f.", "answer": ans,
		"wrongs": [wrong(Answer.xs_of(flipped), R_ZERO_SIGN), wrong(Answer.xs_of([s.y_int]), R_ZERO_YINT)],
		# An option as long as the answer comes first, so a typed answer has a wrong one to match.
		"generic": [Answer.xs_of(zs.map(func(z): return z.add(1))), Answer.xs_of(zs.slice(0, zs.size() - 1)), Answer.xs_of(zs.slice(1))]}
	var has_form: bool = s.has("a") or s.fam == "cubic"
	var form := "f(x) = " + BasicFunctionSituation.factorised(s) if has_form else ""
	var vals := "The zeros are x = %s" % ", ".join(zs.map(func(z): return W(z)))
	var solve := "Set f(x) = 0: %s = 0" % BasicFunctionSituation.text(s.f)
	var rd := "Read where the curve crosses the x-axis, where y = 0"
	var fact: Array
	if has_form:
		fact = ["The rule in factors is %s" % form, "A product is 0 when a factor is 0; each bracket x − p gives x = p, so read the sign flipped", vals]
	else:
		fact = ["These zeros are not whole numbers, so f has no factors to read: use the formula on %s = 0" % BasicFunctionSituation.text(s.f), vals]
	if s.fam == "cubic":
		fact = fact.slice(0, 1) + ["Each factor gives a zero: x alone gives x = 0, and each bracket x − p gives x = p", vals]
	var steps := {"set-equal-zero": [solve, "Factorise or use the formula" if s.fam != "cubic" else "Take out x: this keeps the zero x = 0", vals],
		"factorised-read": fact, "gdc-zero": ["Graph y = %s on the calculator" % BasicFunctionSituation.text(s.f), "Use its zero tool at each crossing", vals], "graph-read": [rd, vals]}
	if rep == "graph":
		out.lines = ["The graph of y = f(x) is shown."]
		out.graph = graph_of(s, zs[0].to_float() - 2.0, zs[-1].to_float() + 2.0)
	elif angle == "factorised-read" and has_form:
		out.lines = [form]
	else:
		out.lines = [BasicFunctionSituation.eqn(s)]
	out.methods = ways(steps, final(ans), ans)
	return out


func u_time_for_target(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: Q = s.tstar
	var goal: Q = s.target
	var unit: String = {"ball": " s", "cost": "", "pop": " h", "cool": " min"}[s.ctx]
	var ans := value("%s = " % s.v, t, s, unit)
	if s.ctx == "cost":
		ans.erase("show")
	var wrongs: Array = [wrong({"v": goal}, R_OUTPUT)]
	if s.ctx == "ball":
		wrongs.push_front(wrong({"v": s.tneg}, R_NEGATIVE))
	var ask: String = {"ball": "At what time does the ball reach a height of %s m on its way down?", "cost": "How many T-shirts can be ordered for exactly $%s?",
		"pop": "When does the colony reach %s bacteria?", "cool": "When does the drink reach %s °C?"}[s.ctx]
	var target_text := Fmt.money(goal) if s.ctx == "cost" else say(goal, {"paper": 1}) if goal.is_int() else Fmt.dec(goal)
	var out := {"asked": ask % target_text, "answer": ans, "wrongs": wrongs,
		"generic": nums([GdcKit.qf(t.to_float() + 1.0), s.x0, GdcKit.qf(t.to_float() + 2.0)], t)}
	if rep == "graph":
		out.lines = [BasicFunctionSituation.setup(s), "Its graph is shown, with the target dashed."]
		var hi: float = s.dom_end.to_float() if s.ctx == "ball" else t.to_float() * 1.3
		out.graph = graph_of(s, 0.0, hi, [], [[goal.to_float(), ""]])
	else:
		out.lines = [BasicFunctionSituation.setup(s)]
	var solve := "Set the rule equal to the target: %s = %s" % [BasicFunctionSituation.text(s.f, s.v), Fmt.dec(goal)]
	var val := "This gives %s = %s" % [s.v, W(t)]
	var reject: String = "The other root, %s = %s, is before the throw, so reject it" % [s.v, W(s.tneg)] if s.ctx == "ball" else "%s has to be 0 or more, and %s is" % [s.v, W(t)]
	out.methods = ways({"gdc-table-trace": ["Table the rule on the calculator", "Find the entry that reaches %s" % Fmt.dec(goal), val], "solve-model": [solve, val, reject], "solve-for-input": [solve, val, reject],
		"context-domain": ["The context needs %s ≥ 0" % s.v, solve, reject, val], "gdc-zero": ["Graph y = %s − %s" % [BasicFunctionSituation.text(s.f, s.v), Fmt.dec(goal)], "Use the zero tool for the zero with %s ≥ 0" % s.v, val]}, final(ans), ans)
	return out


func u_model_domain(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right: String
	var bad: Array = []
	var plain: Array
	var why: String
	var v: String = s.v
	match s.ctx:
		"ball":
			var end := say(s.dom_end, s)
			var top: float = -s.f.co[1].to_float() * s.f.co[1].to_float() / (4.0 * s.f.co[2].to_float()) + s.f.co[0].to_float()
			right = "0 ≤ t ≤ %s" % end
			bad = [tag("0 ≤ h ≤ %s" % say(GdcKit.qf(top), s), R_RANGE_DOMAIN)]
			plain = ["t ≥ 0", "t ≤ %s" % end, "all real numbers"]
			why = "The time starts at 0 and ends when the ball lands, when h(t) = 0, at t = %s" % end
		"cost":
			right = "n = 0, 1, 2, 3, ..."
			bad = [tag("C ≥ %s" % Fmt.money(s.y_int), R_RANGE_DOMAIN)]
			plain = ["n ≥ 0, with any decimal allowed", "all real numbers", "n ≥ 1, with any decimal allowed"]
			why = "n counts T-shirts, so it is a whole number, and 0 or more"
		_:
			right = "%s ≥ 0" % v
			bad = [tag("%s ≥ %s" % [s.name, say(s.y_int, s)] if s.ctx == "pop" else "%s ≤ %s" % [s.name, say(s.y_int, s)], R_RANGE_DOMAIN)]
			plain = ["all real numbers", "%s > 0, leaving out the start" % v, "%s ≤ 0" % v]
			why = "Time starts at 0, when it is first measured, and carries on"
	var out := {"asked": "State a sensible domain for %s." % s.name, "lines": [BasicFunctionSituation.setup(s)]}
	out.merge(choose(right, bad, plain))
	out.methods = ways({"context-domain": ["The domain is the inputs, here the values of %s, not the outputs" % v, why]}, "So %s." % right, out.answer)
	return out


# ── fn-concept-function-notation ─────────────────────────────

static func named(names: Array, a: Variant, b: Variant) -> Dictionary:
	var ans := Answer.make("named", {"v0": Q.of(a), "v1": Q.of(b)}, {"names": names})
	ans.exact = true
	return ans


static func concept_lines(rep: String, s: Dictionary, xs: Array) -> Dictionary:
	if rep == "table":
		return {"lines": ["The table gives values of f."], "table": table_of(s, xs)}
	return {"lines": [BasicFunctionSituation.eqn(s)]}


func u_inside_or_outside_shift(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a.n
	var inner := BasicFunctionSituation.at(s.f, a + 1)
	var outer: Q = s.y0.add(1)
	var ans := named(["f(%d + 1)" % a, "f(%d) + 1" % a], inner, outer)
	var out := concept_lines(rep, s, range(0, 7))
	out.merge({"asked": "Find f(%d + 1) and f(%d) + 1." % [a, a], "answer": ans,
		"wrongs": [wrong({"v0": outer, "v1": outer}, R_SHIFT)], "generic": [{"v0": outer, "v1": inner}, {"v0": inner, "v1": inner}, {"v0": inner, "v1": s.y0}]})
	var solo := "f(%d + 1) = f(%d) = %s: the 1 is added to the input, before f" % [a, a + 1, Fmt.num(inner)]
	var twin := "f(%d) + 1 = %s + 1 = %s: the 1 is added to the output, after f" % [a, Fmt.num(s.y0), Fmt.num(outer)]
	out.methods = ways({"direct-substitution": [solo, twin], "read-graph-table": ["Read f(%d) = %s and f(%d) = %s" % [a, Fmt.num(s.y0), a + 1, Fmt.num(inner)], solo, twin]}, final(ans), ans)
	return out


func u_inside_or_outside_scale(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a.n
	var inner := BasicFunctionSituation.at(s.f, 2 * a)
	var outer: Q = s.y0.mul(2)
	var ans := named(["f(2 × %d)" % a, "2f(%d)" % a], inner, outer)
	var out := concept_lines(rep, s, range(0, 7))
	out.merge({"asked": "Find f(2 × %d) and 2f(%d)." % [a, a], "answer": ans,
		"wrongs": [wrong({"v0": outer, "v1": outer}, R_TIMES)], "generic": [{"v0": outer, "v1": inner}, {"v0": inner, "v1": inner}, {"v0": inner, "v1": s.y0}]})
	var solo := "f(2 × %d) = f(%d) = %s: the input is doubled" % [a, 2 * a, Fmt.num(inner)]
	var twin := "2f(%d) = 2 × %s = %s: the output is doubled" % [a, Fmt.num(s.y0), Fmt.num(outer)]
	out.methods = ways({"direct-substitution": [solo, twin], "read-graph-table": ["Read f(%d) = %s and f(%d) = %s" % [a, Fmt.num(s.y0), 2 * a, Fmt.num(inner)], solo, twin]}, final(ans), ans)
	out.spot = {"lines": ["f(%d) = %s" % [a, Fmt.num(s.y0)], "f(2 × %d) = 2 × f(%d)" % [a, a], "= 2 × %s" % Fmt.paren(s.y0), "= %s" % Fmt.num(outer)],
		"bad": 1, "ref": R_TIMES, "why": "f( ) is not a multiplication: the 2 is inside, on the input, so this is f(%d) = %s" % [2 * a, Fmt.num(inner)]}
	return out


func u_inverse_or_reciprocal(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a.n
	var k: Q = s.inv
	var rec := Q.new(1).div(s.y0)
	var ans := named(["f⁻¹(%d)" % a, "1/f(%d)" % a], k, rec)
	var xs: Array = range(mini(k.n, a) - 1, maxi(k.n, a) + 2)
	var out := concept_lines(rep, s, xs)
	out.merge({"asked": "Find f⁻¹(%d) and 1/f(%d)." % [a, a], "answer": ans,
		"wrongs": [wrong({"v0": rec, "v1": rec}, R_RECIPROCAL)], "generic": [{"v0": s.y0, "v1": rec}, {"v0": k, "v1": s.y0}, {"v0": rec, "v1": k}]})
	var rcp := "1/f(%d) = 1/%s = %s: one over the output" % [a, Fmt.paren(s.y0), Fmt.num(rec)]
	var hit := "f(%s) = %d, so f⁻¹(%d) = %s" % [Fmt.num(k), a, a, Fmt.num(k)]
	var sv := "Solve f(x) = %d: %s = %d gives x = %s" % [a, BasicFunctionSituation.text(s.f), a, Fmt.num(k)]
	out.methods = ways({"read-graph-table": ["f⁻¹(%d) asks which input gives the output %d" % [a, a], hit, rcp], "solve-f-equals": [sv, rcp],
		"swap-coordinates": ["(%s, %d) is on f, so (%d, %s) is on f⁻¹" % [Fmt.num(k), a, a, Fmt.num(k)], hit, rcp]}, final(ans), ans)
	return out


func u_match_expressions(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: int = s.a.n
	var y: Q = s.y0
	var all := [["f(%d)" % (a + 1), BasicFunctionSituation.at(s.f, a + 1)], ["f(%d) + 1" % a, y.add(1)], ["2f(%d)" % a, y.mul(2)], ["f(%d)" % (2 * a), BasicFunctionSituation.at(s.f, 2 * a)],
		["f⁻¹(%d)" % a, s.inv], ["1/f(%d)" % a, Q.new(1).div(y)]]
	var pick: Array = rng.pick(all)
	var val: Q = pick[1]
	var others: Array = rng.shuffled(all.filter(func(e): return not e[1].eq(val))).map(func(e): return e[0])
	var out := {"asked": "Which expression has the value %s?" % Fmt.num(val)}
	match rep:
		"table":
			out.lines = ["The table gives values of f."]
			var xs := {}
			for x in [s.inv.n, a, a + 1, 2 * a, 0]:
				xs[x] = true
			var ks: Array = xs.keys()
			ks.sort()
			out.table = table_of(s, ks)
		"graph":
			out.lines = ["The graph of f, a straight line, is shown."]
			var dots: Array = []
			for x in [s.inv.n, a, a + 1, 2 * a]:
				var yy := BasicFunctionSituation.at(s.f, x)
				dots.append([x, yy.to_float(), Fmt.point(x, yy)])
			out.graph = graph_of(s, mini(s.inv.n, 0) - 1.0, 2.0 * a + 1.0, dots)
		_:
			out.lines = [BasicFunctionSituation.eqn(s)]
	out.merge(choose(pick[0], [], others))
	var vals := "f(%d) = %s, f(%d) = %s, f(%d) = %s" % [a, Fmt.num(y), a + 1, Fmt.num(BasicFunctionSituation.at(s.f, a + 1)), 2 * a, Fmt.num(BasicFunctionSituation.at(s.f, 2 * a))]
	var inv := "f(%s) = %d, so f⁻¹(%d) = %s" % [Fmt.num(s.inv), a, a, Fmt.num(s.inv)]
	out.methods = ways({"direct-substitution": ["Work out the values: " + vals, "Then 2f(%d) = %s and f(%d) + 1 = %s" % [a, Fmt.num(y.mul(2)), a, Fmt.num(y.add(1))], inv],
		"swap-coordinates": [inv + ": swap the coordinates of a point on f", "The values of f itself: " + vals]}, "The value %s is %s. So %s." % [Fmt.num(val), pick[0], pick[0]], out.answer)
	return out


func u_when_equal(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c: Q = s.y_int
	var h: int = rng.int_in(2, 4)
	var d: int = ExtensionViews.nonzero(rng, -5, 7)
	if d == h:
		d = h + 1
	var m := Q.new(d, h)
	var ans := Answer.make("number", {"v": m}, {}, "m = ")
	ans.exact = true
	var out := {"asked": "For which value of m is f(x + %d) = f(x) %s for every x?" % [h, ("+ %d" % d) if d > 0 else ("− %d" % -d)],
		"lines": ["f(x) = mx%s" % Fmt.plus(c)], "answer": ans, "wrongs": [], "generic": nums([Q.new(h, d), Q.new(d - h), Q.new(1), Q.new(d)]), "given": {"h": h, "d": d}}
	out.methods = ways({"direct-substitution": ["Write out the left side: f(x + %d) = m(x + %d)%s = mx + %dm%s" % [h, h, Fmt.plus(c), h, Fmt.plus(c)],
		"The right side is mx%s%s" % [Fmt.plus(c), Fmt.plus(d)], "The mx and the constant %s cancel, which leaves %dm = %s" % [Fmt.num(c), h, Fmt.num(d)]]}, final(ans), ans)
	return out
