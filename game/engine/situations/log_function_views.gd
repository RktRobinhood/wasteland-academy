class_name LogFunctionViews
extends RefCounted
## The views on the `log-function` situation: one builder per unknown of
## fn-log-function-features (FAL-418). Builders return what QuadraticViews' builders
## return (see quadratic_views.gd). Paper 1: every answer is exact.
##
## The catalogue's pick-graph asks which sketch a function is. The pick-the-graph
## format isn't built, so the view offers four descriptions of the graph (from the
## equation) or four equations (from the graph), each wrong one a typical mistake.

const NEED := {
	"asymptote-from-equation": {},
	"sign-of-log-expression": {"ratio": true},
	"domain-from-equation": {},
	"domain-from-graph": {},
	"asymptote-from-graph": {},
	"x-intercept": {"intercept": true},
	"pick-graph": {"m1": true, "a1": true},
	"reflect-exponential": {"m1": true, "a1": true},
	"n-from-asymptote": {"m1": true, "a1": true},
	"log-inequality": {"a1": true, "ineq": true},
}


func has(unknown: String) -> bool:
	return NEED.has(unknown)


func need(unknown: String, _rep: String) -> Dictionary:
	return NEED[unknown].duplicate()


## Two needs as one for a shared situation (QuestionEngine.families()), or null: the
## ratio ln(x − h)/x^p is not a linear-inside log, so it shares with nothing else.
func merge_need(a: Dictionary, b: Dictionary) -> Variant:
	if a.get("ratio", false) != b.get("ratio", false):
		return null
	return QuestionEngine.merge_need(a, b)


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "wrongs", "generic"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "generic"] else null
	out.given = LogFunctionSituation.export(s)
	out.trap = {}
	out.asked = M(out.asked)
	out.lines = out.lines.map(func(l): return M(l))
	for a in out.methods:
		out.methods[a].steps = out.methods[a].steps.map(func(st): return Step.map_text(st, M))
	return out


# ── Helpers ──────────────────────────────────────────────────

static func N(v: Variant) -> String:
	return Fmt.num(v)


static func M(text: String) -> String:
	return ExpLogPairViews.M(text)


static func wrong(values: Dictionary, ref: String = "") -> Dictionary:
	return {"values": values, "ref": ref}


## A choice answer whose options are the right text and the wrong ones (minus signs fixed).
static func choice(right: String, wrongs: Array, generic: Array) -> Dictionary:
	var opts: Array = [M(right)]
	for w in wrongs:
		w.values.v = M(w.values.v)
	for o in wrongs.map(func(w): return w.values.v) + generic.map(func(g): return M(g)):
		if not o in opts:
			opts.append(o)
	var ans := Answer.make("choice", {"v": opts[0]}, {"options": opts})
	return {"answer": ans, "wrongs": wrongs, "generic": generic.map(func(g): return {"v": M(g)})}


## Any whole power as a superscript: "¹", "⁰", "⁻¹".
static func sup_any(e: int) -> String:
	var out := ""
	for ch in str(e):
		out += Fmt.SUPS[ch]
	return out


static func inside(s: Dictionary) -> String:
	return Fmt.poly([s.m, s.n])


## y = A·log_b(mx + n) + c as written: "y = 2log₃(2x − 6) + 1".
static func fn_text(s: Dictionary) -> String:
	return "y = %s%s(%s)%s" % [Fmt.lead(s.A), Answer.log_name(s.b), inside(s), Answer.plus_q(s.c)]


## The domain as a bound: x > x0 for m > 0, x < x0 for m < 0.
static func domain_text(s: Dictionary) -> String:
	return "x %s %s" % [">" if s.m > 0 else "<", N(s.x0)]


static func graph(s: Dictionary, points: Array = [], hlines: Array = []) -> Dictionary:
	var f := func(x: float) -> float: return LogFunctionSituation.at(s, x)
	var x0: float = s.x0.to_float()
	var lo := floori(x0) - 2 if s.m > 0 else floori(x0) - 10
	var hi := lo + 12
	var from := x0 + 0.0005 if s.m > 0 else float(lo)
	var to := float(hi) if s.m > 0 else x0 - 0.0005
	var c: int = s.c
	return Plot.spec([Plot.sample(f, from, to)], points, lo, hi, c - 6, c + 6, hlines, [[x0, "x = %s" % N(s.x0)]])


static func undefined_steps(s: Dictionary) -> Array:
	return ["The log is undefined where its input is 0: %s = 0." % inside(s), "So x = %s." % N(s.x0)]


# ── fn-log-function-features ─────────────────────────────────

func u_asymptote_from_equation(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x0: Q = s.x0
	var n: Q = s.n
	var bad: Q = n.div(Q.new(s.m))
	var out := choice("x = " + N(x0), [wrong({"v": "x = " + N(bad)}, "SL2.9.log-graph#1"), wrong({"v": N(x0)}, "SL2.4.asymptotes#0")],
		["x = " + N(n.neg()), "y = " + N(x0), "x = " + N(n), "x = " + N(x0.add(Q.new(1))), "y = %d" % s.c, "x = 0"])
	var right: String = out.answer.values.v
	var final := "So the asymptote is " + right + "."
	out.merge({
		"asked": "Write down the equation of the vertical asymptote of the graph.", "lines": [fn_text(s)],
		"methods": {
			"translate-parent": {"result": out.answer.values, "steps": [
				"Write the inside as %s(%s) first: the shift is not the number in the bracket." % [N(s.m), Answer.x_minus(x0)],
				"%s x has its asymptote at x = 0; this graph is moved so the input is 0 at x = %s." % [Answer.log_name(s.b), N(x0)], final]},
			"undefined-input": {"result": out.answer.values, "steps": undefined_steps(s) + [final]},
			"move-parent-asymptote": {"result": out.answer.values, "steps": [
				"The parent's asymptote is where its input is 0.", "Here the input %s is 0 at x = %s." % [inside(s), N(x0)], final]},
			"gdc-table": {"result": out.answer.values, "steps": [
				"A table of y has no values on one side of x = %s and plunges next to it." % N(x0), "Solving %s = 0 gives the exact x = %s." % [inside(s), N(x0)], final]},
		}})
	return out


func u_sign_of_log_expression(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h: int = s.h
	var pw: int = s.pw
	var rel: String = s.rel
	var denom := "x" + Fmt.sup(pw)
	var expr := "f(x) = ln(%s)/%s" % [Answer.x_minus(h), denom]
	var ans: Dictionary
	var gen: Array
	if rel == ">":
		ans = Answer.make("bound", {"rel": ">", "v": Q.new(h + 1)}, {"var": "x"})
		gen = [{"rel": ">", "v": Q.new(h)}, {"rel": "≥", "v": Q.new(h + 1)}, {"rel": "<", "v": Q.new(h + 1)}, {"rel": ">", "v": Q.new(1)}]
	else:
		ans = Answer.make("range2", {"lo": Q.new(h), "r1": "<", "r2": "<", "hi": Q.new(h + 1)}, {"var": "x"})
		gen = [{"lo": Q.new(0), "r1": "<", "r2": "<", "hi": Q.new(h + 1)}, {"lo": Q.new(h), "r1": "≤", "r2": "<", "hi": Q.new(h + 1)},
			{"lo": Q.new(h), "r1": "<", "r2": "<", "hi": Q.new(h + 2)}, {"lo": Q.new(h), "r1": "<", "r2": "≤", "hi": Q.new(h + 1)}]
	ans.exact = true
	var final := "So " + Answer.text(ans) + "."
	var sign := "positive" if rel == ">" else "negative"
	return {
		"asked": "Find the values of x for which f(x) %s 0." % rel, "lines": [expr + ", for x > %d" % h], "answer": ans, "generic": gen,
		"methods": {
			"key-points": {"result": ans.values, "steps": [
				"%s > 0 on the domain, so f has the sign of ln(%s)." % [denom, Answer.x_minus(h)],
				"ln y is %s when %s, and the input %s is 1 at x = %d." % [sign, "y > 1" if rel == ">" else "0 < y < 1", Answer.x_minus(h), h + 1], final]},
			"restriction-rules": {"result": ans.values, "steps": [
				"The log needs %s > 0, so x > %d; %s is never 0 there." % [Answer.x_minus(h), h, denom],
				"f(x) %s 0 when ln(%s) %s 0: %s." % [rel, Answer.x_minus(h), rel, "x > %d" % (h + 1) if rel == ">" else "%d < x < %d" % [h, h + 1]], final]},
		},
	}


func u_domain_from_equation(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("bound", {"rel": ">" if s.m > 0 else "<", "v": s.x0}, {"var": "x"})
	ans.exact = true
	var final := "So the domain is " + Answer.text(ans) + "."
	var lines := [fn_text(s)] if rep == "equation" else ["The function f is given by f(x) = %s%s(%s)%s, for as many real x as possible." % [Fmt.lead(s.A), Answer.log_name(s.b), inside(s), Answer.plus_q(s.c)]]
	var other := "≥" if s.m > 0 else "≤"
	return {
		"asked": "Find the largest possible domain.", "lines": lines, "answer": ans,
		"wrongs": [wrong({"rel": ">", "v": Q.new(0)}, "SL2.2.domain#1")] if not s.x0.is_zero() or s.m < 0 else [],
		"generic": [{"rel": other, "v": s.x0}, {"rel": "<" if s.m > 0 else ">", "v": s.x0}, {"rel": ans.values.rel, "v": s.x0.neg()}, {"rel": ans.values.rel, "v": s.n.neg()}],
		"methods": {
			"restriction-rules": {"result": ans.values, "steps": [
				"A log needs a positive input: %s > 0." % inside(s),
				("Divide by %s%s: " % [N(s.m), " (a negative number turns the inequality round)" if s.m < 0 else ""] if s.m != 1 else "So ") + Answer.text(ans), final]},
			"graph-extent": {"result": ans.values, "steps": [
				"The graph exists only on one side of its asymptote x = %s." % N(s.x0),
				"It runs to the %s, where %s > 0." % ["right" if s.m > 0 else "left", inside(s)], final]},
		},
	}


func u_domain_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := domain_text(s)
	var out := choice(right, [wrong({"v": "all real values of y"}, "SL2.2.domain#2")],
		["x %s %s" % ["≥" if s.m > 0 else "≤", N(s.x0)], "x %s %s" % ["<" if s.m > 0 else ">", N(s.x0)], "x > 0"])
	var final: String = "So the domain is " + out.answer.values.v + "."
	out.merge({
		"asked": "Write down the domain of the function whose graph is shown.", "lines": ["The graph of %s is shown." % fn_text(s)],
		"graph": graph(s),
		"methods": {"graph-extent": {"result": out.answer.values, "steps": [
			"The graph is only to the %s of its asymptote x = %s, and never touches it." % ["right" if s.m > 0 else "left", N(s.x0)],
			"The domain is the x-values it covers.", final]}}})
	return out


func u_asymptote_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x0: Q = s.x0
	var out := choice("x = " + N(x0), [wrong({"v": "y = " + N(x0)}, "SL2.4.asymptotes#1"), wrong({"v": "y = 0"}, "SL2.9.log-graph#0")],
		["x = " + N(x0.neg()), "x = 0", "y = %d" % s.c, "x = " + N(x0.add(Q.new(1))), "x = %d" % s.c,
			"x = " + N(x0.sub(Q.new(1))), "y = %d" % (s.c + 1)])
	var final: String = "So the asymptote is " + out.answer.values.v + "."
	out.merge({
		"asked": "Write down the equation of the asymptote of the graph shown.", "lines": ["The graph of %s is shown." % fn_text(s)],
		"graph": graph(s),
		"methods": {"move-parent-asymptote": {"result": out.answer.values, "steps": [
			"A log graph has one vertical asymptote, where its input is 0: here x = %s." % N(x0), "It is a vertical line, so its equation is x = ….", final]}}})
	return out


func u_x_intercept(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var xi: Q = s.xi
	var e: int = s.e
	var ans := Answer.make("number", {"v": xi}, {}, "x = ")
	ans.exact = true
	var final := "So " + Answer.text(ans) + "."
	var b: int = s.b
	var v := LogFunctionSituation.bpow(b, e)
	var out := {"asked": "Find where the graph crosses the x-axis.", "lines": [fn_text(s)], "answer": ans,
		"wrongs": [wrong({"v": s.x0}, "SL2.9.log-graph#2")],
		"generic": [{"v": xi.neg()}, {"v": Q.new(e)}, {"v": xi.add(Q.new(1))}, {"v": v}]}
	if rep == "graph":
		out.lines = ["The graph of %s is shown." % fn_text(s)]
		out.graph = graph(s)
	var solve := "%s(%s) = %s, so %s = %d%s = %s" % [Answer.log_name(b), inside(s), N(Q.new(-s.c, s.A)), inside(s), b, sup_any(e), N(v)]
	out.methods = {
		"key-points": {"result": ans.values, "steps": ["Set y = 0: %s%s(%s) = %s" % [Fmt.lead(s.A), Answer.log_name(b), inside(s), N(-s.c)], solve, final]},
		"gdc-transfer": {"result": ans.values, "steps": [
			"Graph %s and find where it crosses y = 0: x = %s." % [fn_text(s), String.num(xi.to_float(), 4)], "Exactly: " + solve, final]},
	}
	return out


func u_pick_graph(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var h: Q = s.x0
	var c: int = s.c
	var p1 := Fmt.point(h.add(Q.new(1)), c)
	var p2 := Fmt.point(h.add(Q.new(b)), c + 1)
	var out: Dictionary
	var final := ""
	if rep == "graph":
		var right := "y = %s(%s)%s" % [Answer.log_name(b), Answer.x_minus(h), Answer.plus_q(c)]
		out = choice(right, [], ["y = %s(%s)%s" % [Answer.log_name(b), Answer.x_minus(h.neg()), Answer.plus_q(c)],
			"y = %s(%s)%s" % [Answer.log_name(b), Answer.x_minus(h), Answer.plus_q(-c - 1)],
			"y = %s(%s)%s" % [Answer.log_name(b), Answer.x_minus(Q.new(c)), Answer.plus_q(h)],
			"y = %s(%s)%s" % [Answer.log_name(b + 1), Answer.x_minus(h), Answer.plus_q(c)],
			"y = %s(%s)%s" % [Answer.log_name(b), Answer.x_minus(h.add(Q.new(1))), Answer.plus_q(c)]])
		out.asked = "Which equation does the graph show?"
		out.lines = ["The graph of a function y = log_b(x − h) + c is shown."]
		out.graph = graph(s, [[h.to_float() + 1, c, p1], [h.to_float() + b, c + 1, p2]])
		final = "So it is " + out.answer.values.v + "."
	else:
		var say := func(asym: Q, a: String, bb: String, up: bool) -> String: return "asymptote x = %s, through %s and %s, %s" % [N(asym), a, bb, "increasing" if up else "decreasing"]
		var right: String = say.call(h, p1, p2, true)
		out = choice(right, [wrong({"v": say.call(h, Fmt.point(h, 0), p2, true)}, "SL2.9.log-graph#2")],
			[say.call(h.neg(), Fmt.point(h.neg().add(Q.new(1)), c), Fmt.point(h.neg().add(Q.new(b)), c + 1), true),
			say.call(h, p1, p2, false), say.call(h, Fmt.point(h.add(Q.new(1)), c + 1), Fmt.point(h.add(Q.new(b)), c + 2), true)])
		out.asked = "Which description matches the graph of %s?" % ("y = %s(%s)%s" % [Answer.log_name(b), Answer.x_minus(h), Answer.plus_q(c)])
		out.lines = ["y = %s(%s)%s" % [Answer.log_name(b), Answer.x_minus(h), Answer.plus_q(c)]]
		final = "So it is: " + out.answer.values.v + "."
	var v: Dictionary = out.answer.values
	out.methods = {
		"key-points": {"result": v, "steps": [
			"y = %s x has asymptote x = 0 and passes through (1, 0) and (%d, 1)." % [Answer.log_name(b), b],
			"Moving by (%s, %d) gives asymptote x = %s, %s and %s; a log with b > 1 increases." % [N(h), c, N(h), p1, p2], final]},
		"reflect-exponential": {"result": v, "steps": [
			"y = %d^x passes through (0, 1) and (1, %d); reflected in y = x, %s x passes through (1, 0) and (%d, 1)." % [b, b, Answer.log_name(b), b],
			"Then translate by (%s, %d): %s and %s, asymptote x = %s." % [N(h), c, p1, p2, N(h)], final]},
		"translate-parent": {"result": v, "steps": [
			"x − %s inside moves the graph %s right; + %d outside moves it %d up." % [N(h), N(h), c, c], "The asymptote x = 0 moves to x = %s, and (1, 0) to %s." % [N(h), p1], final]},
		"gdc-transfer": {"result": v, "steps": [
			"Graph y = %s(%s)%s on the GDC." % [Answer.log_name(b), Answer.x_minus(h), Answer.plus_q(c)], "Its trace passes through %s and %s and climbs away from x = %s." % [p1, p2, N(h)], final]},
	}
	return out


func u_reflect_exponential(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var h: int = s.h
	var ans := Answer.make("point", {"x": Q.new(b), "y": Q.new(h + 1)})
	ans.exact = true
	var final := "So it is " + Answer.text(ans) + "."
	var ex := "y = %s" % Answer.fn_text("exp", b, h, 0)
	var out := {"asked": "The graph is reflected in the line y = x. Which point on the reflection matches (%d, %d)?" % [h + 1, b], "answer": ans,
		"generic": [{"x": Q.new(h + 1), "y": Q.new(b)}, {"x": Q.new(-b), "y": Q.new(h + 1)}, {"x": Q.new(b), "y": Q.new(-h - 1)}, {"x": Q.new(1), "y": Q.new(h)}]}
	if rep == "graph":
		var f := func(x: float) -> float: return pow(float(b), x - h)
		out.lines = ["The graph of %s is shown, through (%d, 1) and (%d, %d)." % [ex, h, h + 1, b]]
		out.graph = Plot.spec([Plot.sample(f, h - 6.0, h + 3.0)], [[h, 1, Fmt.point(h, 1)], [h + 1, b, Fmt.point(h + 1, b)]], h - 6, h + 6, -2, 10)
	else:
		out.lines = ["The graph of %s passes through (%d, 1) and (%d, %d), with the asymptote y = 0." % [ex, h, h + 1, b]]
	out.methods = {
		"key-points": {"result": ans.values, "steps": [
			"The reflection is the inverse, y = %s x%s." % [Answer.log_name(b), Answer.plus_q(h)],
			"Reflecting in y = x swaps the coordinates: (%d, %d) goes to (%d, %d)." % [h + 1, b, b, h + 1], final]},
		"reflect-exponential": {"result": ans.values, "steps": [
			"Reflect in y = x: every (p, q) becomes (q, p), and the asymptote y = 0 becomes x = 0.", "(%d, %d) becomes (%d, %d)." % [h + 1, b, b, h + 1], final]},
	}
	return out


func u_n_from_asymptote(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Q = s.x0
	var b: int = s.b
	var c: int = s.c
	var ans := Answer.make("number", {"v": a}, {}, "n = ")
	ans.exact = true
	var final := "So " + Answer.text(ans) + "."
	var shown := "y = %s(x − n)%s" % [Answer.log_name(b), Answer.plus_q(c)]
	var out := {"asked": "Find n.", "answer": ans, "wrongs": [wrong({"v": a.neg()}, "SL2.4.asymptotes#2")] if not a.is_zero() else [],
		"generic": [{"v": Q.new(c)}, {"v": a.add(Q.new(1))}, {"v": a.sub(Q.new(1))}, {"v": Q.new(b)}]}
	if rep == "graph":
		out.lines = ["The graph of %s is shown, with its vertical asymptote." % shown]
		out.graph = graph(s)
	else:
		out.lines = ["The graph of %s has the vertical asymptote x = %s." % [shown, N(a)]]
	out.methods = {
		"translate-parent": {"result": ans.values, "steps": [
			"x − n inside moves y = %s x by n to the right, asymptote and all." % Answer.log_name(b), "The asymptote moved from x = 0 to x = %s." % N(a), final]},
		"undefined-input": {"result": ans.values, "steps": ["The log is undefined where x − n = 0, at x = n.", "That is the asymptote, x = %s." % N(a), final]},
		"asymptote-first": {"result": ans.values, "steps": [
			"Read the asymptote first: x = %s." % N(a), "The input x − n is 0 on the asymptote: %s − n = 0." % N(a), final]},
	}
	return out


func u_log_inequality(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var m: int = s.m
	var k: int = s.k
	var rel: String = s.rel
	var v := LogFunctionSituation.bpow(b, k)
	var edge: Q = v.sub(s.n).div(Q.new(m))
	var flip := {"<": ">", ">": "<", "≤": "≥", "≥": "≤"}
	var r2: String = flip[rel] if m < 0 else rel
	var x0: Q = s.x0
	var ans: Dictionary
	var gen: Array
	if rel in [">", "≥"]:
		ans = Answer.make("bound", {"rel": r2, "v": edge}, {"var": "x"})
		gen = [{"rel": rel if m < 0 else flip[rel], "v": edge}, {"rel": r2, "v": Q.new(k).sub(s.n).div(Q.new(m))}, {"rel": r2, "v": x0}, {"rel": r2, "v": edge.neg()}]
	else:
		var lo: Q = x0 if m > 0 else edge
		var hi: Q = edge if m > 0 else x0
		var r_lo: String = "<" if m > 0 else ("<" if rel == "<" else "≤")
		var r_hi: String = ("<" if rel == "<" else "≤") if m > 0 else "<"
		ans = Answer.make("range2", {"lo": lo, "r1": r_lo, "r2": r_hi, "hi": hi}, {"var": "x"})
		gen = [{"lo": lo, "r1": "≤", "r2": "≤", "hi": hi}, {"lo": lo.sub(Q.new(1)), "r1": r_lo, "r2": r_hi, "hi": hi},
			{"lo": lo, "r1": r_lo, "r2": r_hi, "hi": hi.add(Q.new(1))}, {"lo": Q.new(0), "r1": r_lo, "r2": r_hi, "hi": hi}]
	ans.exact = true
	var final := "So " + Answer.text(ans) + "."
	var ineq := "%s(%s) %s %d" % [Answer.log_name(b), inside(s), rel, k]
	var out := {"asked": "Solve %s." % ineq, "lines": ["y = %s(%s)" % [Answer.log_name(b), inside(s)]], "answer": ans, "generic": gen}
	if rep == "graph":
		var t := s.duplicate()
		t.c = 0
		out.lines = ["The graph of y = %s(%s) and the line y = %d are shown." % [Answer.log_name(b), inside(s), k]]
		out.graph = graph(t, [], [[float(k), "y = %d" % k]])
	var power := "%s %s %d%s = %s" % [inside(s), rel, b, sup_any(k), N(v)]
	var dom := "the log needs %s > 0, so x %s %s." % [inside(s), ">" if m > 0 else "<", N(x0)]
	out.methods = {
		"key-points": {"result": ans.values, "steps": [
			"%s(%s) = %d where %s = %s, at x = %s." % [Answer.log_name(b), inside(s), k, inside(s), N(v), N(edge)],
			"The graph %s, so it is %s %d on one side of x = %s; " % ["rises" if m > 0 else "falls", "above" if rel in [">", "≥"] else "below", k, N(edge)] + "and " + dom, final]},
		"restriction-rules": {"result": ans.values, "steps": ["As a power: " + power + ("" if m > 0 else " (dividing by %d turns it round)" % m), "Also " + dom, final]},
	}
	return out
