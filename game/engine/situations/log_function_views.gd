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

## fn-log-function-features's own slips (FAL-820).
const R_NO_DIVIDE := "fn-log-function-features#8"
const R_C_ASYM := "fn-log-function-features#9"
const R_PARENT := "fn-log-function-features#10"
const R_DEFINED := "fn-log-function-features#11"
const R_EDGE_IN := "fn-log-function-features#12"
const R_ZERO_IN := "fn-log-function-features#13"
const R_NO_SHIFT := "fn-log-function-features#14"
const R_FROM_ORIGIN := "fn-log-function-features#15"
const R_NO_TURN := "fn-log-function-features#16"
const R_LOG_VALUE := "fn-log-function-features#17"
const R_INPUT_VALUE := "fn-log-function-features#18"
const R_SHIFTS_SWAPPED := "fn-log-function-features#19"
const R_NOT_SWAPPED := "fn-log-function-features#20"
const R_NO_POWER := "fn-log-function-features#21"
const R_XINT_AS_N := "fn-log-function-features#22"
const R_SIGN := "SL2.9.log-graph#1"
## The map's restriction-rules method is the shared fn-domain-range one, "Apply the three
## restrictions"; a log has only the one (#193).
const ONE_RESTRICTION := {"restriction-rules": "Use the log's restriction: its input is positive"}


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
	# choice() is shared with other views and names its last list `generic`: here
	# every one of them is a filler, the slips being tagged wrongs (FAL-820).
	if out.has("generic"):
		out.fillers = out.generic
		out.erase("generic")
	# More slips than places: which three are offered is the stream's choice.
	if out.has("wrongs") and out.wrongs.size() > 3:
		out.wrongs = rng.shuffled(out.wrongs)
	for key in ["lines", "graph", "table", "wrongs", "fillers"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "fillers"] else null
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


## How x − h inside moves a graph: "2 right", "3 left" (h not 0).
static func h_move(h: Q) -> String:
	return "%s %s" % [N(h.abs_q()), "right" if h.sign() > 0 else "left"]


## How + c outside moves a graph: "3 up", "1 down" (c not 0).
static func c_move(c: int) -> String:
	return "%d %s" % [absi(c), "up" if c > 0 else "down"]


## The first step of translating the parent: what the inside's shift is (#193). A
## factorised inside m(x − x0) shows the shift x0; with m = 1 the bracket already does.
static func shift_step(s: Dictionary) -> String:
	var x0: Q = s.x0
	if s.n.is_zero():
		return "The inside %s has no constant term, so the graph is not moved sideways." % inside(s)
	if s.m == 1:
		return "The inside is %s, so the graph is moved %s." % [inside(s), h_move(x0)]
	return "Write the inside as %s(%s): the shift is %s, not %s." % [Fmt.lead(s.m), Answer.x_minus(x0), N(x0), N(s.n.neg())]


## Where y = log_b u takes the value e, from its key points (1, 0) and (b, 1): each
## factor b in u adds 1 to the log (#193).
static func key_value(b: int, e: int) -> String:
	var lb := Answer.log_name(b)
	var v := LogFunctionSituation.bpow(b, e)
	if e == 0:
		return "y = %s u passes through (1, 0), so %s u = 0 at u = 1" % [lb, lb]
	if e == 1:
		return "y = %s u passes through (1, 0) and (%d, 1), so %s u = 1 at u = %d" % [lb, b, lb, b]
	if e > 1:
		return "y = %s u passes through (1, 0) and (%d, 1), and each further factor %d in u adds 1, so %s u = %d at u = %s" % [lb, b, b, lb, e, N(v)]
	return "y = %s u passes through (1, 0) and (%d, 1), and each division of u by %d takes 1 off, so %s u = %d at u = %s" % [lb, b, b, lb, e, N(v)]


# ── fn-log-function-features ─────────────────────────────────

func u_asymptote_from_equation(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x0: Q = s.x0
	var n: Q = s.n
	var bad: Q = n.div(Q.new(s.m))
	var ws := [wrong({"v": "x = " + N(bad)}, "SL2.9.log-graph#1"), wrong({"v": N(x0)}, "SL2.4.asymptotes#0"), wrong({"v": "y = " + N(x0)}, "SL2.4.asymptotes#1"),
		wrong({"v": "y = %d" % s.c}, R_C_ASYM)]
	if s.m != 1:
		ws.append(wrong({"v": "x = " + N(n.neg())}, R_NO_DIVIDE))
	if not x0.is_zero():
		ws.append(wrong({"v": "x = 0"}, R_PARENT))
	var out := choice("x = " + N(x0), ws, ["x = " + N(n), "x = " + N(x0.add(Q.new(1)))])
	var right: String = out.answer.values.v
	var final := "So the asymptote is " + right + "."
	out.merge({
		"asked": "Write down the equation of the vertical asymptote of the graph.", "lines": [fn_text(s)],
		"methods": {
			"translate-parent": {"result": out.answer.values, "steps": [
				shift_step(s),
				"%s x has its asymptote at x = 0; this graph is moved so the input is 0 at x = %s." % [Answer.log_name(s.b), N(x0)], final]},
			"undefined-input": {"result": out.answer.values, "steps": undefined_steps(s) + [final]},
			"move-parent-asymptote": {"result": out.answer.values, "steps": [
				"The parent's asymptote is where its input is 0.", "Here the input %s is 0 at x = %s." % [inside(s), N(x0)], final]},
			"gdc-table": {"result": out.answer.values, "steps": [
				"A table of y has no values on one side of x = %s and %s next to it." % [N(x0), "plunges" if s.A > 0 else "shoots up"], "Solving %s = 0 gives the exact x = %s." % [inside(s), N(x0)], final]},
		}})
	return out


func u_sign_of_log_expression(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h: int = s.h
	var pw: int = s.pw
	var rel: String = s.rel
	var denom := "x" + Fmt.sup(pw)
	var expr := "f(x) = ln(%s)/%s" % [Answer.x_minus(h), denom]
	var ans: Dictionary
	var ws: Array
	var gen: Array
	if rel == ">":
		ans = Answer.make("bound", {"rel": ">", "v": Q.new(h + 1)}, {"var": "x"})
		ws = [wrong({"rel": ">", "v": Q.new(h)}, R_DEFINED), wrong({"rel": "≥", "v": Q.new(h + 1)}, R_ZERO_IN)]
		if h != 0:
			ws.append(wrong({"rel": ">", "v": Q.new(1)}, R_NO_SHIFT))
		gen = [{"rel": "<", "v": Q.new(h + 1)}]
	else:
		ans = Answer.make("range2", {"lo": Q.new(h), "r1": "<", "r2": "<", "hi": Q.new(h + 1)}, {"var": "x"})
		ws = [wrong({"lo": Q.new(h), "r1": "≤", "r2": "<", "hi": Q.new(h + 1)}, R_EDGE_IN), wrong({"lo": Q.new(h), "r1": "<", "r2": "≤", "hi": Q.new(h + 1)}, R_ZERO_IN)]
		if h != 0:
			ws.append(wrong({"lo": Q.new(0), "r1": "<", "r2": "<", "hi": Q.new(h + 1)}, R_FROM_ORIGIN))
		gen = [{"lo": Q.new(h), "r1": "<", "r2": "<", "hi": Q.new(h + 2)}]
	ans.exact = true
	var final := "So " + Answer.text(ans) + "."
	var sign := "positive" if rel == ">" else "negative"
	return {
		"asked": "Find the values of x for which f(x) %s 0." % rel, "lines": [expr + ", for x > %d" % h], "answer": ans, "wrongs": ws, "fillers": gen, "titles": ONE_RESTRICTION,
		"methods": {
			"key-points": {"result": ans.values, "steps": [
				"%s > 0 on the domain, so f has the sign of ln(%s)." % [denom, Answer.x_minus(h)],
				"ln y is %s when %s, and the input %s is 1 at x = %d." % [sign, "y > 1" if rel == ">" else "0 < y < 1", Answer.x_minus(h), h + 1], final]},
			"restriction-rules": {"result": ans.values, "steps": [
				("The log needs x > 0; %s is never 0 there." % denom) if h == 0 else "The log needs %s > 0, so x > %d; %s is never 0 there." % [Answer.x_minus(h), h, denom],
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
		"asked": "Find the largest possible domain.", "lines": lines, "answer": ans, "titles": ONE_RESTRICTION,
		"wrongs": ([wrong({"rel": ">", "v": Q.new(0)}, "SL2.2.domain#1")] if not s.x0.is_zero() or s.m < 0 else []) + [wrong({"rel": other, "v": s.x0}, R_EDGE_IN)]
			+ ([wrong({"rel": ">", "v": s.x0}, R_NO_TURN)] if s.m < 0 else []) + ([] if s.x0.is_zero() else [wrong({"rel": ans.values.rel, "v": s.x0.neg()}, R_SIGN)])
			+ ([] if s.m == 1 else [wrong({"rel": ans.values.rel, "v": s.n.neg()}, R_NO_DIVIDE)]),
		"fillers": [] if s.m < 0 else [{"rel": "<", "v": s.x0}],
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
	var ws := [wrong({"v": "all real values of y"}, "SL2.2.domain#2"), wrong({"v": "x %s %s" % ["≥" if s.m > 0 else "≤", N(s.x0)]}, R_EDGE_IN)]
	if not s.x0.is_zero() or s.m < 0:
		ws.append(wrong({"v": "x > 0"}, "SL2.2.domain#1"))
	var out := choice(right, ws, ["x %s %s" % ["<" if s.m > 0 else ">", N(s.x0)]])
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
	var ws := [wrong({"v": "y = " + N(x0)}, "SL2.4.asymptotes#1"), wrong({"v": "y = 0"}, "SL2.9.log-graph#0"), wrong({"v": "y = %d" % s.c}, R_C_ASYM)]
	if not x0.is_zero():
		ws += [wrong({"v": "x = " + N(x0.neg())}, R_SIGN), wrong({"v": "x = 0"}, R_PARENT)]
	var out := choice("x = " + N(x0), ws, ["x = " + N(x0.add(Q.new(1))), "x = %d" % s.c, "x = " + N(x0.sub(Q.new(1))), "y = %d" % (s.c + 1)])
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
		"wrongs": [wrong({"v": s.x0}, "SL2.9.log-graph#2"), wrong({"v": Q.new(e)}, R_LOG_VALUE)] + ([] if v.eq(xi) else [wrong({"v": v}, R_INPUT_VALUE)]),
		"fillers": [{"v": xi.neg()}, {"v": xi.add(Q.new(1))}]}
	if rep == "graph":
		out.lines = ["The graph of %s is shown." % fn_text(s)]
		out.graph = graph(s)
	var solve := "%s(%s) = %s, so %s = %d%s = %s" % [Answer.log_name(b), inside(s), N(Q.new(-s.c, s.A)), inside(s), b, sup_any(e), N(v)]
	out.methods = {
		"key-points": {"result": ans.values, "steps": ["Set y = 0: %s%s(%s) = %s" % [Fmt.lead(s.A), Answer.log_name(b), inside(s), N(-s.c)],
			("" if s.A == 1 else "%s(%s) = %d, and " % [Answer.log_name(b), inside(s), e]) + "%s, so %s = %s" % [key_value(b, e), inside(s), N(v)], final]},
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
		var ws := []
		if not h.is_zero():
			ws.append(wrong({"v": "y = %s(%s)%s" % [Answer.log_name(b), Answer.x_minus(h.neg()), Answer.plus_q(c)]}, R_SIGN))
		if not h.eq(Q.new(c)):
			ws.append(wrong({"v": "y = %s(%s)%s" % [Answer.log_name(b), Answer.x_minus(Q.new(c)), Answer.plus_q(h)]}, R_SHIFTS_SWAPPED))
		out = choice(right, ws, ["y = %s(%s)%s" % [Answer.log_name(b), Answer.x_minus(h), Answer.plus_q(-c - 1)],
			"y = %s(%s)%s" % [Answer.log_name(b + 1), Answer.x_minus(h), Answer.plus_q(c)],
			"y = %s(%s)%s" % [Answer.log_name(b), Answer.x_minus(h.add(Q.new(1))), Answer.plus_q(c)]])
		out.asked = "Which equation does the graph show?"
		out.lines = ["The graph of a function y = log_b(x − h) + c is shown."]
		out.graph = graph(s, [[h.to_float() + 1, c, p1], [h.to_float() + b, c + 1, p2]])
		final = "So it is " + out.answer.values.v + "."
	else:
		var say := func(asym: Q, a: String, bb: String, up: bool) -> String: return "asymptote x = %s, through %s and %s, %s" % [N(asym), a, bb, "increasing" if up else "decreasing"]
		var right: String = say.call(h, p1, p2, true)
		var ws := [wrong({"v": say.call(h, Fmt.point(h, 0), p2, true)}, "SL2.9.log-graph#2")]
		if not h.is_zero():
			ws.append(wrong({"v": say.call(h.neg(), Fmt.point(h.neg().add(Q.new(1)), c), Fmt.point(h.neg().add(Q.new(b)), c + 1), true)}, R_SIGN))
		out = choice(right, ws,
			[say.call(h, p1, p2, false), say.call(h, Fmt.point(h.add(Q.new(1)), c + 1), Fmt.point(h.add(Q.new(b)), c + 2), true)])
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
		"translate-parent": {"result": v, "steps": [translate_step(h, c),
			("The asymptote stays x = 0, and (1, 0) moves to %s." % p1 if h.is_zero() else "The asymptote x = 0 moves to x = %s, and (1, 0) to %s." % [N(h), p1]) if not (h.is_zero() and c == 0)
				else "The asymptote stays x = 0, and (1, 0) stays where it is.", final]},
		"gdc-transfer": {"result": v, "steps": [
			"Graph y = %s(%s)%s on the GDC." % [Answer.log_name(b), Answer.x_minus(h), Answer.plus_q(c)], "Its trace passes through %s and %s and climbs away from x = %s." % [p1, p2, N(h)], final]},
	}
	return out


## The moves in y = log_b(x − h) + c, each said once, with no zero shift (#193).
static func translate_step(h: Q, c: int) -> String:
	var parts: Array = []
	if not h.is_zero():
		parts.append("%s inside moves the graph %s" % [Answer.x_minus(h), h_move(h)])
	if c != 0:
		parts.append("%s outside moves %s %s" % [Answer.plus_q(c).strip_edges(), "the graph" if parts.is_empty() else "it", c_move(c)])
	if parts.is_empty():
		return "Nothing is added inside or outside, so the graph is not moved."
	return "; ".join(parts) + "."


func u_reflect_exponential(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var h: int = s.h
	var ans := Answer.make("point", {"x": Q.new(b), "y": Q.new(h + 1)})
	ans.exact = true
	var final := "So it is " + Answer.text(ans) + "."
	var ex := "y = %s" % Answer.fn_text("exp", b, h, 0)
	var out := {"asked": "The graph is reflected in the line y = x. Which point on the reflection matches (%d, %d)?" % [h + 1, b], "answer": ans,
		"wrongs": [wrong({"x": Q.new(h + 1), "y": Q.new(b)}, R_NOT_SWAPPED)],
		"fillers": [{"x": Q.new(-b), "y": Q.new(h + 1)}, {"x": Q.new(b), "y": Q.new(-h - 1)}, {"x": Q.new(1), "y": Q.new(h)}]}
	if rep == "graph":
		var f := func(x: float) -> float: return pow(float(b), x - h)
		out.lines = ["The graph of %s is shown, through (%d, 1) and (%d, %d)." % [ex, h, h + 1, b]]
		out.graph = Plot.spec([Plot.sample(f, h - 6.0, h + 3.0)], [[h, 1, Fmt.point(h, 1)], [h + 1, b, Fmt.point(h + 1, b)]], h - 6, h + 6, -2, 10)
	else:
		out.lines = ["The graph of %s passes through (%d, 1) and (%d, %d), with the asymptote y = 0." % [ex, h, h + 1, b]]
	out.methods = {
		"key-points": {"result": ans.values, "steps": [
			("The reflection is the inverse, y = %s x, with key points (1, 0) and (%d, 1)." % [Answer.log_name(b), b]) if h == 0
				else "The reflection is the inverse, y = %s x%s: the key points (1, 0) and (%d, 1) of %s x move %s, to (1, %d) and (%d, %d)." % [Answer.log_name(b), Answer.plus_q(h), b, Answer.log_name(b), c_move(h), h, b, h + 1],
			"(%d, %d) swaps to (%d, %d), the key point at x = %d." % [h + 1, b, b, h + 1, b], final]},
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
	# The map's asymptote-first method reads a horizontal asymptote; here it is the
	# vertical one, which gives the horizontal shift n (#193). The base comes before
	# n ± 1, so the fillers don't sit either side of the key.
	var out := {"asked": "Find n.", "answer": ans, "wrongs": ([wrong({"v": a.neg()}, "SL2.4.asymptotes#2")] if not a.is_zero() else [])
		+ ([] if a.eq(Q.new(c)) else [wrong({"v": Q.new(c)}, R_C_ASYM)]),
		"fillers": [{"v": Q.new(b)}, {"v": a.add(Q.new(1))}, {"v": a.sub(Q.new(1))}],
		"titles": {"asymptote-first": "Read the horizontal shift n from the vertical asymptote"}}
	# The x-intercept n + b^(−c) read as n: a real slip, so n ± 1 is rarely needed (#193).
	var xint := a.add(LogFunctionSituation.bpow(b, -c))
	if absi(c) <= 2 and absf(xint.to_float()) <= 40.0:
		out.wrongs.append(wrong({"v": xint}, R_XINT_AS_N))
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
	var ws: Array
	var gen: Array
	if rel in [">", "≥"]:
		ans = Answer.make("bound", {"rel": r2, "v": edge}, {"var": "x"})
		ws = [wrong({"rel": r2, "v": Q.new(k).sub(s.n).div(Q.new(m))}, R_NO_POWER)]
		gen = [{"rel": r2, "v": x0}, {"rel": r2, "v": edge.neg()}]
		if m < 0:
			ws.append(wrong({"rel": rel, "v": edge}, R_NO_TURN))
		else:
			gen.push_front({"rel": flip[rel], "v": edge})
	else:
		var lo: Q = x0 if m > 0 else edge
		var hi: Q = edge if m > 0 else x0
		var r_lo: String = "<" if m > 0 else ("<" if rel == "<" else "≤")
		var r_hi: String = ("<" if rel == "<" else "≤") if m > 0 else "<"
		ans = Answer.make("range2", {"lo": lo, "r1": r_lo, "r2": r_hi, "hi": hi}, {"var": "x"})
		var both := {"lo": lo, "r1": "≤", "r2": "≤", "hi": hi}
		var origin := {"lo": Q.new(0), "r1": r_lo, "r2": r_hi, "hi": hi}
		# Both ends closed is one slip only when the edge at k was already closed.
		ws = [wrong(both, R_EDGE_IN)] if rel == "≤" else []
		gen = [] if rel == "≤" else [both]
		# The edge at k in another place (#193): the input's value b^k left unsolved, or
		# k itself with no power taken. Each is kept only where the interval isn't empty.
		var at_edge := func(e: Q) -> Dictionary:
			return {"lo": x0, "r1": r_lo, "r2": r_hi, "hi": e} if m > 0 else {"lo": e, "r1": r_lo, "r2": r_hi, "hi": x0}
		var open_side := func(e: Q) -> bool: return x0.lt(e) if m > 0 else e.lt(x0)
		if not v.eq(edge) and open_side.call(v):
			ws.append(wrong(at_edge.call(v), R_INPUT_VALUE))
		var bare: Q = Q.new(k).sub(s.n).div(Q.new(m))
		if not bare.eq(edge) and open_side.call(bare):
			ws.append(wrong(at_edge.call(bare), R_NO_POWER))
		# The parent's edge x = 0 in place of x0 is a slip; in place of the edge at k it is not.
		if m > 0 and not x0.is_zero() and Q.new(0).lt(hi):
			ws.append(wrong(origin, R_FROM_ORIGIN))
		else:
			gen.append(origin)
		# An end moved by one is a last resort, after every slip.
		gen += [{"lo": lo.sub(Q.new(1)), "r1": r_lo, "r2": r_hi, "hi": hi}, {"lo": lo, "r1": r_lo, "r2": r_hi, "hi": hi.add(Q.new(1))}]
	ans.exact = true
	var final := "So " + Answer.text(ans) + "."
	var ineq := "%s(%s) %s %d" % [Answer.log_name(b), inside(s), rel, k]
	var out := {"asked": "Solve %s." % ineq, "lines": ["y = %s(%s)" % [Answer.log_name(b), inside(s)]], "answer": ans, "wrongs": ws, "fillers": gen, "titles": ONE_RESTRICTION}
	if rep == "graph":
		var t := s.duplicate()
		t.c = 0
		out.lines = ["The graph of y = %s(%s) and the line y = %d are shown." % [Answer.log_name(b), inside(s), k]]
		out.graph = graph(t, [], [[float(k), "y = %d" % k]])
	var power := "%s %s %d%s = %s" % [inside(s), rel, b, sup_any(k), N(v)]
	# The power solved for x, each move shown (#193).
	var mx := Fmt.poly([m, 0])
	var rhs: Q = v.sub(s.n)
	var solve := ""
	if m == 1:
		solve = ", so x %s %s" % [r2, N(edge)]
	elif s.n.is_zero():
		solve = ", so x %s %s" % [r2, N(edge)]
	else:
		solve = ", so %s %s %s" % [mx, rel, N(rhs)]
		solve += " and x %s %s" % [r2, N(edge)]
	if m != 1:
		solve += " (dividing by %d%s)" % [m, " turns it round" if m < 0 else ""]
	var dom := "the log needs %s > 0, so x %s %s." % [inside(s), ">" if m > 0 else "<", N(x0)]
	var above: bool = rel in [">", "≥"]
	var side := "right" if above == (m > 0) else "left"
	out.methods = {
		"key-points": {"result": ans.values, "steps": [
			"%s; %s = %s at x = %s." % [key_value(b, k), inside(s), N(v), N(edge)],
			"The graph %s, so it is %s %d to the %s of x = %s; " % ["rises" if m > 0 else "falls", "above" if above else "below", k, side, N(edge)] + "and " + dom, final]},
		"restriction-rules": {"result": ans.values, "steps": ["As a power: " + power + solve + ".", "Also " + dom, final]},
	}
	return out
