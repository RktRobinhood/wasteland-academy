class_name GraphMatchViews
extends RefCounted
## The views on the `graph-match` situation: one builder per unknown of
## fn-ext-match-graph (FAL-420). Builders return what QuadraticViews' builders return
## (see quadratic_views.gd). Graphs are matched by their intercepts, a test point and
## end behaviour; the catalogue's match format isn't built, so matching several plays
## as picking one graph (or one equation) of several.

const NEED := {
	"graph-from-equation": {"fam": "any"},
	"equation-from-graph": {"fam": "any"},
	"match-several": {"fam": "quad", "a_neg": true},
	"rule-out-graph": {"fam": "any"},
	"signs-from-graph": {"fam": "any"},
	"graph-from-facts": {"fam": "exp", "decay": true},
}
const MG := "SL2.3.match-graph"
const WIN := [-5, 5, -8, 10]


func has(unknown: String) -> bool:
	return NEED.has(unknown)


func need(unknown: String, _rep: String) -> Dictionary:
	return NEED[unknown].duplicate()


func formats(unknown: String) -> Array:
	return ["true-false-reason"] if unknown in ["equation-from-graph", "signs-from-graph"] else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "wrongs", "generic"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "generic"] else null
	out.given = GraphMatchSituation.export(s)
	out.trap = {}
	return out


static func N(v: Variant) -> String:
	return Fmt.num(v)


static func wrong(v: String, ref: String = "") -> Dictionary:
	return {"values": {"v": v}, "ref": ref}


## A copy of s with some numbers changed.
static func with(s: Dictionary, changes: Dictionary) -> Dictionary:
	var t := s.duplicate()
	t.erase("others")
	t.merge(changes, true)
	return t


static func fn(s: Dictionary) -> Callable:
	return func(x: float) -> float: return GraphMatchSituation.y_at(s, x)


static func curve(s: Dictionary) -> Array:
	return GdcKit.curve(fn(s), WIN[0], WIN[1])


static func card(s: Dictionary) -> Dictionary:
	return GdcKit.card([curve(s)], [[0.0, GraphMatchSituation.y0_q(s).to_float(), ""]], WIN, [], _asym(s))


static func _asym(s: Dictionary) -> Array:
	return [[s.c.to_float(), ""]] if s.fam == "exp" else []


static func plot(s: Dictionary, label: bool = true) -> Dictionary:
	var y0 := GraphMatchSituation.y0_q(s)
	return Plot.spec([curve(s)], [[0.0, y0.to_float(), Fmt.point(0, y0) if label else ""]], WIN[0], WIN[1], WIN[2], WIN[3], _asym(s))


## The other shape of the same family: a growth curve for a decay, or a parabola flipped.
static func swapped(s: Dictionary) -> Dictionary:
	if s.fam == "exp":
		return with(s, {"b": Q.new(1).div(s.b)})
	return with(s, {"a": s.a.neg()})


## The same shape through another y-intercept.
static func lifted(s: Dictionary) -> Dictionary:
	if s.fam == "exp":
		return with(s, {"c": s.c.add(Q.new(2))})
	return with(s, {"a": s.a.mul(Q.new(2))})


static func moved(s: Dictionary) -> Dictionary:
	if s.fam == "exp":
		return with(s, {"a": s.a.neg(), "c": s.c})
	return with(s, {"p": s.p.add(Q.new(1)), "q": s.q.add(Q.new(1))})


static func facts(s: Dictionary) -> String:
	var y0 := GraphMatchSituation.y0_q(s)
	if s.fam == "exp":
		return "it crosses the y-axis at %s, has the asymptote y = %s and %s" % [Fmt.point(0, y0), N(s.c),
			"rises" if (s.a.sign() > 0) == (s.b.to_float() > 1.0) else "falls"]
	return "it crosses the x-axis at %s and %s, the y-axis at %s, and opens %s" % [N(s.p), N(s.q), Fmt.point(0, y0),
		"upwards" if s.a.sign() > 0 else "downwards"]


func u_graph_from_equation(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var sw := swapped(s)
	var p := GdcKit.pick(card(s), [
		{"graph": card(lifted(s)), "ref": MG + "#0", "mistake": "lifted", "why": "its shape is right but its y-intercept is wrong"},
		{"graph": card(sw), "ref": MG + "#1" if s.fam == "exp" else "", "mistake": "swapped",
			"why": "it %s, but the equation's %s" % ["grows" if s.fam == "exp" and sw.b.to_float() > 1.0 else ("decays" if s.fam == "exp" else "opens the other way"),
				"base is %s" % N(s.b) if s.fam == "exp" else "leading coefficient is %s" % N(s.a)]},
		{"graph": card(moved(s)), "ref": "", "mistake": "moved", "why": "it is reflected or shifted: its intercepts don't fit"},
	], rng)
	var final: String = "So the graph is %s." % p.answer.values.v
	return {
		"asked": "Which graph is %s?" % GraphMatchSituation.text(s), "lines": [GraphMatchSituation.text(s)], "answer": p.answer, "graphs": p.graphs,
		"methods": {
			"test-intercepts": {"result": p.answer.values, "steps": ["Put x = 0: y = %s, so the graph crosses the y-axis at %s." % [N(GraphMatchSituation.y0_q(s)),
				Fmt.point(0, GraphMatchSituation.y0_q(s))], "Check that against each graph.", final]},
			"end-behaviour": {"result": p.answer.values, "steps": ["The graph: " + facts(s) + ".", final]},
			"gdc-plot": {"result": p.answer.values, "steps": ["Plot %s on the GDC and compare its shape and intercepts." % GraphMatchSituation.text(s).trim_prefix("y = "), final]},
		},
	}


func u_equation_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := GraphMatchSituation.text(s)
	var out := LogFunctionViews.choice(right, [wrong(GraphMatchSituation.text(lifted(s)), MG + "#0")],
		[GraphMatchSituation.text(swapped(s)), GraphMatchSituation.text(moved(s))])
	var final: String = "So the equation is " + right + "."
	var y0 := GraphMatchSituation.y0_q(s)
	out.merge({
		"asked": "Which equation does the graph show?", "lines": ["The graph is shown, with its y-intercept marked."], "graph": plot(s),
		"methods": {
			"test-intercepts": {"result": out.answer.values, "steps": ["The graph crosses the y-axis at %s." % Fmt.point(0, y0),
				"Only %s gives y = %s at x = 0 and has this shape." % [right, N(y0)], final]},
			"test-point": {"result": out.answer.values, "steps": ["Test a point on the graph, x = 1: y = %s." % Fmt.dec(GdcKit.qf(GraphMatchSituation.y_at(s, 1.0))),
				"Only %s gives it." % right, final]},
		}})
	return out


func u_match_several(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: Dictionary = s.others[0]
	var b: Dictionary = s.others[1]
	if rep == "graph":
		var out := LogFunctionViews.choice(GraphMatchSituation.text(s), [wrong(GraphMatchSituation.text(swapped(s)), MG + "#2")],
			[GraphMatchSituation.text(a), GraphMatchSituation.text(b), GraphMatchSituation.text(moved(s)), GraphMatchSituation.text(lifted(s))])
		var final: String = "So the graph is " + out.answer.values.v + "."
		out.merge({
			"asked": "Which of the equations goes with the graph?", "lines": ["The graph is shown, with its y-intercept marked."], "graph": plot(s),
			"methods": {
				"test-intercepts": {"result": out.answer.values, "steps": ["The graph: " + facts(s) + ".", "Match the intercepts to each equation.", final]},
				"end-behaviour": {"result": out.answer.values, "steps": ["It opens downwards, so its leading coefficient is negative.", final]},
				"gdc-plot": {"result": out.answer.values, "steps": ["Plot each equation on the GDC and compare.", final]},
			}})
		return out
	var p := GdcKit.pick(card(s), [
		{"graph": card(swapped(s)), "ref": MG + "#2", "mistake": "swapped", "why": "it opens upwards, but the leading coefficient is negative"},
		{"graph": card(a), "ref": "", "mistake": "other-a", "why": "it is the graph of " + GraphMatchSituation.text(a)},
		{"graph": card(b), "ref": "", "mistake": "other-b", "why": "it is the graph of " + GraphMatchSituation.text(b)},
	], rng)
	var final: String = "So %s is %s." % [GraphMatchSituation.text(s), p.answer.values.v]
	return {
		"asked": "Three equations: %s, %s and %s. Which graph is %s?" % [GraphMatchSituation.text(a), GraphMatchSituation.text(s), GraphMatchSituation.text(b),
			GraphMatchSituation.text(s)], "lines": [GraphMatchSituation.text(s)], "answer": p.answer, "graphs": p.graphs,
		"methods": {
			"test-intercepts": {"result": p.answer.values, "steps": [GraphMatchSituation.text(s) + ": " + facts(s) + ".", final]},
			"end-behaviour": {"result": p.answer.values, "steps": ["Its leading coefficient is negative, so it opens downwards.", final]},
			"gdc-plot": {"result": p.answer.values, "steps": ["Plot it on the GDC and compare.", final]},
		},
	}


func u_rule_out_graph(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var shown := lifted(s)
	var y0 := GraphMatchSituation.y0_q(s)
	var y1 := GraphMatchSituation.y0_q(shown)
	var right := "It crosses the y-axis at %s, but the equation gives %s at x = 0." % [Fmt.point(0, y1), Fmt.point(0, y0)]
	var out := LogFunctionViews.choice(right, [], ["Its shape is wrong for this kind of equation.",
		"It has no %s." % ("asymptote" if s.fam == "exp" else "roots"), "Nothing: it could be the graph of the equation."])
	var final: String = "So: " + right
	out.merge({
		"asked": "A student says the graph shown is %s. Why can't it be?" % GraphMatchSituation.text(s), "lines": [GraphMatchSituation.text(s)],
		"graph": plot(shown), "check": {"shown": GraphMatchSituation.export(shown)},
		"methods": {
			"test-intercepts": {"result": out.answer.values, "steps": ["Put x = 0 in the equation: y = %s." % N(y0), "The graph crosses at y = %s instead." % N(y1), final]},
			"test-point": {"result": out.answer.values, "steps": ["Test the point where the graph meets the y-axis, (0, %s)." % N(y1),
				"The equation gives y = %s there, not %s." % [N(y0), N(y1)], final]},
		}})
	return out


func u_signs_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var opts: Array
	var right: String
	var flip: String
	if s.fam == "exp":
		var combos := func(apos: bool, bbig: bool) -> String: return "a %s 0 and %s" % [">" if apos else "<", "b > 1" if bbig else "0 < b < 1"]
		var ap: bool = s.a.sign() > 0
		var bb: bool = s.b.to_float() > 1.0
		right = combos.call(ap, bb)
		flip = combos.call(ap, not bb)
		opts = [combos.call(not ap, bb), combos.call(not ap, not bb)]
	else:
		var combos := func(apos: bool, cpos: bool) -> String: return "a %s 0 and the y-intercept is %s" % [">" if apos else "<", "positive" if cpos else "negative"]
		var ap: bool = s.a.sign() > 0
		var cp: bool = GraphMatchSituation.y0_q(s).sign() > 0
		right = combos.call(ap, cp)
		flip = combos.call(not ap, cp)
		opts = [combos.call(ap, not cp), combos.call(not ap, not cp)]
	var out := LogFunctionViews.choice(right, [wrong(flip, MG + ("#1" if s.fam == "exp" else "#2"))], opts)
	var final: String = "So " + right + "."
	var form := "y = a·b^x + c" if s.fam == "exp" else "y = a(x − p)(x − q)"
	out.merge({
		"asked": "The graph is %s. What are the signs?" % form, "lines": ["The graph of %s is shown." % form], "graph": plot(s, false),
		"methods": {"end-behaviour": {"result": out.answer.values, "steps": ["The graph: " + facts(s) + ".",
			("A growth curve has b > 1 and a decay 0 < b < 1, flipped when a < 0." if s.fam == "exp" else "Opening upwards means a > 0."), final]}}})
	return out


func u_graph_from_facts(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var y0 := GraphMatchSituation.y0_q(s)
	var p := GdcKit.pick(card(s), [
		{"graph": card(swapped(s)), "ref": "", "mistake": "swapped", "why": "it grows instead of decaying"},
		{"graph": card(lifted(s)), "ref": "", "mistake": "lifted", "why": "it levels off at y = %s, not y = %s" % [N(s.c.add(Q.new(2))), N(s.c)]},
		{"graph": card(moved(s)), "ref": "", "mistake": "moved", "why": "it comes up from below the level instead of down onto it"},
	], rng)
	var final: String = "So the graph is %s." % p.answer.values.v
	return {
		"asked": "A curve decays towards the line y = %s and passes through %s. Which graph is it?" % [N(s.c), Fmt.point(0, y0)],
		"lines": ["It decays towards y = %s from %s." % [N(s.c), Fmt.point(0, y0)]], "answer": p.answer, "graphs": p.graphs,
		"methods": {"end-behaviour": {"result": p.answer.values, "steps": ["Decaying: it falls as x increases, and levels off at y = %s." % N(s.c),
			"It starts at %s on the y-axis, above the level." % Fmt.point(0, y0), final]}},
	}
