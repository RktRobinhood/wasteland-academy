class_name LineModelViews
extends ExtensionViews
## The views on the `line-model` situation: one builder per unknown of fn-ext-line-model
## (FAL-424). A model is typed as its two numbers (`named`, m and c); an output or an input is a
## typed number, money as money; a meaning is a pick of four written statements. Every unknown
## also plays as true-false-reason. Numbers end, so a model needs no calculator and no rounding.

const R_TOTAL := "SL2.1.line-model#0"
const R_SWAP := "SL2.1.line-model#1"
const R_DOMAIN := "SL2.1.line-model#2"
const R_OUTPUT := "SL2.2.function-model#2"
const CTX := LineModelSituation.CONTEXTS


func needs() -> Dictionary:
	return {
		"build-from-words": {}, "build-from-two-points": {}, "interpret-gradient": {}, "interpret-intercept": {}, "predict": {},
		"input-for-output": {}, "check-linear-table": {}, "domain-sense": {}, "compare-plans": {"plans": true},
	}


func need(unknown: String, rep: String) -> Dictionary:
	var n := super.need(unknown, rep)
	n.erase("rep")
	return n


func extra() -> Dictionary:
	var out := {}
	for u in needs():
		out[u] = ["true-false-reason"]
	return out


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = LineModelSituation.export(s)
	if rep != "words":
		out.titles = {"rate-and-start": "Read the rate and the starting value"}
	return out


static func ctx(s: Dictionary) -> Dictionary:
	return CTX[s.ctx]


static func D(v: Variant) -> String:
	return Fmt.dec(v)


## An output in its unit: "$2.50", "12 litres".
static func amount(s: Dictionary, v: Variant) -> String:
	var c := ctx(s)
	if c.unit == "":
		return ("−$" if Q.of(v).sign() < 0 else "$") + Fmt.money(Q.of(v).abs_q())
	return "%s %s" % [D(v), c.unit]


static func model(s: Dictionary) -> String:
	return "%s = %s" % [ctx(s).y, Fmt.terms([s.m, s.c], [1, 0], ctx(s).x, true)]


static func story(s: Dictionary) -> String:
	return ctx(s).story.replace("%c", amount(s, s.c)).replace("%m", amount(s, s.m.abs_q()))


static func say(s: Dictionary, key: String, v: Variant) -> String:
	return ctx(s)[key].replace("%v", amount(s, v))


## The input with its unit: "20 km", "1 minute".
static func input(s: Dictionary, x: int) -> String:
	var each: String = ctx(s).each
	return "%d %s" % [x, each if each == "km" or each == "kg" or absi(x) == 1 else each + "s"]


## m and c, typed.
static func two(s: Dictionary, m: Q, c: Q) -> Dictionary:
	var ans := Answer.make("named", {"v0": m, "v1": c}, {"names": ["m", "c"]})
	ans.show = "dec"
	ans.exact = true
	return ans


static func mc(m: Q, c: Q) -> Dictionary:
	return {"v0": m, "v1": c}


## An output or an input, typed.
static func number(s: Dictionary, v: Variant, is_output: bool) -> Dictionary:
	var c := ctx(s)
	var ans: Dictionary
	if is_output and c.unit == "":
		ans = Answer.make("number", {"v": Q.of(v)}, {}, "%s = $" % c.y)
		ans.show = "money"
	else:
		ans = Answer.make("number", {"v": Q.of(v)}, {}, (c.y if is_output else c.x) + " = ", " " + c.unit if is_output else "")
		ans.show = "dec"
	ans.exact = true
	return ans


static func fin(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func two_form(s: Dictionary) -> String:
	return "%s = m%s + c" % [ctx(s).y, ctx(s).x]


## The line on axes from input 0, with marked points [[x, y], ...].
static func plot(s: Dictionary, marks: Array) -> Dictionary:
	var top_x: int = s.hi if s.hi > 0 else s.tstep * 10
	var hi_y: float = maxf(s.c.to_float(), s.m.mul(top_x).add(s.c).to_float())
	var m: float = s.m.to_float()
	var c: float = s.c.to_float()
	var curve := Plot.sample(func(x: float) -> float: return m * x + c, 0.0, float(top_x))
	var pts: Array = marks.map(func(p): return [Q.of(p[0]).to_float(), Q.of(p[1]).to_float(), "(%s, %s)" % [D(p[0]), D(p[1])]])
	return Plot.spec([curve], pts, 0, top_x, 0, Plot.nice_top(hi_y))


## The model shown as an equation, or drawn with two marked points.
static func show_model(out: Dictionary, s: Dictionary, rep: String) -> void:
	var c := ctx(s)
	var units := "%s is %s in %s and %s is %s" % [c.x, c.name, c.each + ("" if c.each in ["km", "kg"] else "s"), c.y, c.out + (" in dollars" if c.unit == "" else " in %s" % c.unit)]
	match rep:
		"graph":
			out.lines = ["The graph shows the model, where %s." % units]
			out.graph = plot(s, [[0, s.c], [s.x2, s.y2]])
		"words":
			out.lines = [story(s), "The model is %s." % model(s)]
		_:
			out.lines = [model(s) + ", where %s." % units]


func u_build_from_words(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := two(s, s.m, s.c)
	var out := {"asked": "Write the model in the form %s. Give m and c." % two_form(s), "answer": ans, "lines": [story(s)]}
	out.wrongs = [wrong(mc(s.c, s.m), R_SWAP)]
	out.generic = [mc(s.m.neg(), s.c), mc(s.m, s.c.neg()), mc(s.m.neg(), s.c.neg())]
	var say_m := "The steady change is %s for each %s%s, so m = %s." % [amount(s, s.m.abs_q()), ctx(s).each, ", downwards" if s.m.sign() < 0 else "", D(s.m)]
	out.methods = {"rate-and-start": method([say_m, "The amount at %s = 0 is %s, so c = %s." % [ctx(s).x, amount(s, s.c), D(s.c)], fin(ans)], ans.values)}
	return out


func u_build_from_two_points(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var ans := two(s, s.m, s.c)
	var out := {"asked": "The model is straight. Write it in the form %s. Give m and c." % two_form(s), "answer": ans}
	var ask := "When %s = %d, %s = %s. When %s = %d, %s = %s."
	if rep == "table":
		out.lines = ["The table gives two readings of %s against %s." % [c.out, c.name]]
		out.table = {"rows": [[c.x, [str(s.x1), str(s.x2)]], [c.y, [D(s.y1), D(s.y2)]]]}
	else:
		out.lines = [ask % [c.x, s.x1, c.y, D(s.y1), c.x, s.x2, c.y, D(s.y2)]]
	var dy: Q = s.y2.sub(s.y1)
	var dx: int = s.x2 - s.x1
	out.generic = [mc(s.m, s.y1), mc(s.m.neg(), s.y1.add(s.m.mul(s.x1))), mc(dy, s.c), mc(s.m, s.y2)]
	var c_step := "Then c = %s − %s × %d = %s." % [D(s.y1), _p(s.m), s.x1, D(s.c)]
	out.methods = {
		"two-points-context": method(["m = (%s − %s)/(%d − %d) = %s." % [D(s.y2), D(s.y1), s.x2, s.x1, D(s.m)], c_step, fin(ans)], ans.values),
		"table-differences": method(["%s goes up by %d and %s changes by %s." % [c.x, dx, c.y, D(dy)], "That is %s for each step of 1, so m = %s." % [D(s.m), D(s.m)], c_step, fin(ans)], ans.values),
	}
	return out


## Four statements about one number v: the right one, then tagged or plain slips.
func u_interpret_gradient(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v: Q = s.m.abs_q()
	var right := say(s, "rate", v)
	var out := {"asked": "What does the gradient of the line mean?" if rep == "graph" else "What does the %s in the model mean?" % D(s.m)}
	show_model(out, s, rep)
	out.merge(InverseRuleViews.choose(right, [InverseRuleViews.tag(say(s, "total", v), R_TOTAL)], [say(s, "start", v), "%s is the most it can ever reach" % amount(s, v), "%s is how much the output is at %s = 1" % [amount(s, v), ctx(s).x]]))
	out.methods = {"rate-and-start": method(["%s is the number multiplying %s, so it is the change in %s for each %s, in %s." % [D(s.m), ctx(s).x, ctx(s).out, ctx(s).each, ctx(s).per], right + "."], {"v": right})}
	return out


func u_interpret_intercept(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := say(s, "start", s.c)
	var out := {"asked": "What does the %s in the model mean?" % D(s.c) if rep == "equation" else "What does the point where the line meets the vertical axis mean?"}
	show_model(out, s, rep)
	out.merge(InverseRuleViews.choose(right, [InverseRuleViews.tag(say(s, "rate", s.c), R_SWAP)], ["%s is the total after %s" % [amount(s, s.c), input(s, s.x2)], "%s is where the model stops working" % amount(s, s.c), "%s is the average over the whole model" % amount(s, s.c)]))
	out.methods = {"rate-and-start": method(["The number on its own is the value when %s = 0, before anything has changed." % ctx(s).x, right + "."], {"v": right})}
	return out


func u_predict(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var ans := number(s, s.yp, true)
	var out := {"asked": "Find %s when %s = %d." % [c.y, c.x, s.xp], "answer": ans}
	show_model(out, s, rep)
	var mx: Q = s.m.mul(s.xp)
	out.generic = [{"v": mx}, {"v": s.m.mul(s.xp + 1).add(s.c)}, {"v": s.c.mul(s.xp).add(s.m)}, {"v": s.yp.add(s.c)}, {"v": Q.new(s.xp).add(s.c)}]
	var first := "The model is %s." % model(s) if rep == "equation" else "From the graph, c = %s and m = (%s − %s)/%d = %s." % [D(s.c), D(s.y2), D(s.c), s.x2, D(s.m)]
	out.methods = {"substitute-interpret": method([first, "%s = %s × %d + %s = %s." % [c.y, _p(s.m), s.xp, _p(s.c), D(s.yp)], fin(ans)], ans.values)}
	return out


static func _p(v: Q) -> String:
	return "(%s)" % D(v) if v.sign() < 0 else D(v)


func u_input_for_output(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var ans := number(s, s.xq, false)
	var out := {"asked": "Find %s when %s = %s." % [c.x, c.y, amount(s, s.yq)], "answer": ans}
	show_model(out, s, rep)
	if rep == "words":
		out.lines = [story(s)]
		out.asked = "Find the input %s when %s is %s, using the model %s." % [c.x, c.out, amount(s, s.yq), two_form(s)]
	out.wrongs = [wrong({"v": s.yq}, R_OUTPUT)]
	# Only slips that land on an input a student could believe.
	var slips: Array = [s.yq.add(s.c).div(s.m), s.yq.div(s.m), s.yq.sub(s.c), Q.new(s.xq + s.tstep), Q.new(s.xq * 2), Q.new(s.xq + 2 * s.tstep)]
	out.generic = slips.filter(func(v): return v.is_int() and v.sign() > 0).map(func(v): return {"v": v})
	var first := "%s = %s." % [D(s.yq), Fmt.terms([s.m, s.c], [1, 0], c.x, true)]
	if rep == "graph":
		first = "From the graph, c = %s and m = (%s − %s)/%d = %s. So %s" % [D(s.c), D(s.y2), D(s.c), s.x2, D(s.m), first]
	out.methods = {"solve-model": method([first, "Take off the start: %s = %s." % [Fmt.terms([s.m], [1], c.x, true), D(s.yq.sub(s.c))], "Divide by %s: %s = %d." % [_p(s.m), c.x, s.xq], fin(ans)], ans.values)}
	return out


func u_check_linear_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var ys: Array = s.ty
	var out := {"asked": "Does a straight line fit this table? If so, what is its rate?", "lines": ["The table shows %s against %s." % [c.out, c.name]]}
	out.table = {"rows": [[c.x, s.tx.map(func(x): return str(x))], [c.y, ys.map(func(y): return D(y))]]}
	var diffs: Array = []
	for i in ys.size() - 1:
		diffs.append(ys[i + 1].sub(ys[i]))
	var list := ", ".join(diffs.map(func(d): return D(d)))
	var yes := func(r: Q) -> String: return "Yes: %s %s" % [D(r), ctx(s).per]
	var no := "No: the outputs do not change by equal amounts"
	var right: String = yes.call(s.m) if s.linear else no
	var plain: Array = [no, yes.call(s.m), yes.call(s.m.mul(s.tstep)) if s.tstep != 1 else yes.call(s.m.add(1)), yes.call(s.m.neg()), yes.call(s.c)]
	out.merge(InverseRuleViews.choose(right, [], plain))
	var verdict: String = "They are all equal, so a line fits." if s.linear else "They are not all equal, so no line fits."
	var ending: String = right + "."
	var rate_step: String = "Each step of %d in %s gives %s, so the rate is %s ÷ %d = %s." % [s.tstep, c.x, D(diffs[0]), D(diffs[0]), s.tstep, D(s.m)] if s.linear else verdict
	out.methods = {
		"table-differences": method(["The differences in %s are %s." % [c.y, list], verdict, rate_step + " " + ending if s.linear else ending], {"v": right}),
		"two-points-context": method(["From the first two rows the rate would be %s ÷ %d = %s." % [D(diffs[0]), s.tstep, D(diffs[0].div(s.tstep))], "Check each pair the same way: the differences are %s." % list, verdict + " " + ending], {"v": right}),
	}
	return out


func u_domain_sense(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var dom: String = "0 ≤ %s ≤ %d" % [c.x, s.hi] if s.hi > 0 else "%s ≥ 0" % c.x
	var pred := "%s = %s" % [c.x, str(s.xbad).replace("-", "−")]
	var lines := [story(s), "The model is %s." % model(s)]
	# A tank being filled ends where it is full: the student needs its capacity to see that.
	if c.limit == "full":
		lines.append("The tank is full at %s." % amount(s, s.m.mul(s.hi).add(s.c)))
	var out := {"asked": "The model is used at %s. Does the prediction make sense? What is the sensible domain?" % pred, "lines": lines}
	var got := "%s = %s" % [c.y, amount(s, s.ybad)]
	var yes := "Yes: it gives %s, and the sensible domain is %s" % [got, dom]
	var reason: String
	if s.hi > 0 and s.xbad > s.hi:
		reason = "the tank is empty after %d minutes" % s.hi if c.id == "drain" else ("the candle is gone after %d hours" % s.hi if c.id == "candle" else "the tank is full after %d minutes" % s.hi)
	else:
		reason = "%s cannot be negative" % c.x
	var no := "No: %s, so the sensible domain is %s" % [reason, dom]
	var right: String = yes if s.bad_in else no
	var trust := "Yes: the model works for every value of %s" % c.x
	var bad: Array = [] if s.bad_in else [InverseRuleViews.tag(yes, R_DOMAIN)]
	out.merge(InverseRuleViews.choose(right, bad, [trust, no, "No: a model only holds at the readings it was built from", "No: %s is too large to use, whatever the context" % c.y]))
	var first := "%s gives %s." % [pred, got]
	var limit: String = "%s must stay in %s, where the model still describes something real." % [c.x, dom]
	out.methods = {"substitute-interpret": method([first, limit, right + "."], {"v": right})}
	return out


func u_compare_plans(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var x: String = c.x
	var text := func(q: Q, v: int, who: String) -> String: return "Equal at %s = %d, then Plan %s is cheaper" % [x, v, who]
	var right: String = text.call(s.ma, s.xe, "A")
	var unit: String = c.each
	var out := {"asked": "When do the two plans cost the same, and which is cheaper after that?"}
	if rep == "words":
		out.lines = ["Plan A costs %s, plus %s for each %s." % [amount(s, s.ca), amount(s, s.ma), unit], "Plan B costs %s, plus %s for each %s." % [amount(s, s.cb), amount(s, s.mb), unit]]
	else:
		out.lines = ["Plan A: C = %s" % Fmt.terms([s.ma, s.ca], [1, 0], x, true), "Plan B: C = %s" % Fmt.terms([s.mb, s.cb], [1, 0], x, true)]
	var dm: Q = s.mb.sub(s.ma)
	var dc: Q = s.ca.sub(s.cb)
	var off: int = roundi(s.ca.add(s.cb).div(dm).to_float())
	if off == s.xe:
		off = s.xe * 2
	out.merge(InverseRuleViews.choose(right, [], [text.call(s.ma, s.xe, "B"), text.call(s.ma, off, "A"), text.call(s.ma, off, "B")]))
	var eq := "%s = %s" % [Fmt.terms([s.ma, s.ca], [1, 0], x, true), Fmt.terms([s.mb, s.cb], [1, 0], x, true)]
	var solve := "So %s = %s, and %s = %d." % [Fmt.terms([dm], [1], x, true), D(dc), x, s.xe]
	var after := "Plan A has the smaller rate, %s against %s, so it is cheaper after that." % [D(s.ma), D(s.mb)]
	out.methods = {
		"equate-y": method(["Set the plans equal: %s." % eq, solve, after, right + "."], {"v": right}),
		"rate-and-start": method(["Plan B starts %s lower, and Plan A catches up by %s for each %s." % [amount(s, dc), amount(s, dm), unit], "%s ÷ %s = %d, so they are equal at %s = %d." % [D(dc), D(dm), s.xe, x, s.xe], after, right + "."], {"v": right}),
	}
	return out
