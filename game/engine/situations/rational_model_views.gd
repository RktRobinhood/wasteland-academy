class_name RationalModelViews
extends ExtensionViews
## The views on the `rational-model` situation: one builder per unknown of
## fn-ext-rational-model (FAL-423). A model (an average cost, a mixture topped up, a level
## that settles) is told by its formula or, for the first two, in words; a table or a graph
## shows it. Values, inputs and constants are typed numbers, exact; what a long-run value or
## a vertical asymptote means, and the model itself, are four written statements (the `choice`
## kind). Everything is Paper 1: the Paper 2 versions, to 3 s.f., are not built.

const R_REACHES := "SL2.8.rational-model#0"
const R_ROUND_DOWN := "SL2.8.rational-model#1"
const R_REAL_VALUE := "SL2.8.rational-model#2"
const R_OUTPUT := "SL2.2.function-model#2"


func needs() -> Dictionary:
	return {
		"evaluate-model": {"ctx": "any"},
		"long-run-value": {"ctx": "any"},
		"least-n-for-target": {"ctx": "any"},
		"input-for-value": {"ctx": "any"},
		"build-model": {"ctx": "any", "words": true},
		"interpret-vertical-asymptote": {"ctx": "any"},
		"parameters-from-data": {"ctx": "any"},
	}


func need(unknown: String, rep: String) -> Dictionary:
	var n := super.need(unknown, rep)
	if rep == "words":
		n.words = true
	return n


func extra() -> Dictionary:
	return {"evaluate-model": ["true-false-reason"], "long-run-value": ["true-false-reason"], "least-n-for-target": ["true-false-reason"],
		"input-for-value": ["true-false-reason"], "build-model": ["true-false-reason"], "interpret-vertical-asymptote": ["true-false-reason"],
		"parameters-from-data": ["true-false-reason"]}


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = RationalModelSituation.export(s)
	return out


static func N(v: Variant) -> String:
	return Fmt.num(v)


static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func pick(right: String, bad: Array, plain: Array) -> Dictionary:
	return InverseRuleViews.choose(right, bad, plain)


static func tag(text: String, ref: String) -> Dictionary:
	return InverseRuleViews.tag(text, ref)


# ── The context in words and symbols ─────────────────────────

static func fn(s: Dictionary) -> String:
	return {"cost": "A", "mix": "C", "settle": "P"}[s.ctx]


static func var_(s: Dictionary) -> String:
	return {"cost": "n", "mix": "x", "settle": "t"}[s.ctx]


## The unit after a value or an input: " dollars per item", " items".
static func unit(s: Dictionary) -> String:
	return {"cost": " dollars per item", "mix": " g per litre", "settle": s.get("story", ["", "", ""])[1] if s.ctx == "settle" else ""}[s.ctx]


static func input_unit(s: Dictionary) -> String:
	return {"cost": " items", "mix": " litres", "settle": " " + s.get("story", ["", "", ""])[2] if s.ctx == "settle" else ""}[s.ctx]


## The model's right-hand side: "(600 + 4n)/n", "(200 + 10x)/(20 + x)", "(800t + 800)/(t + 4)".
static func rhs(s: Dictionary) -> String:
	match s.ctx:
		"cost":
			return "(%d + %dn)/n" % [s.F, s.v]
		"mix":
			return "(%d + %dx)/(%d + x)" % [s.s, s.p, s.V]
	return "(%dt + %d)/(t + %d)" % [s.L, s.P0 * s.k, s.k]


static func model(s: Dictionary) -> String:
	return "%s(%s) = %s" % [fn(s), var_(s), rhs(s)]


## The model told as a sentence, with its formula.
static func about(s: Dictionary) -> String:
	match s.ctx:
		"cost":
			return "A factory makes items. The average cost per item of n items is %s dollars." % model(s)
		"mix":
			return "Salt water is added to a tank. After x litres are added, the concentration is %s grams per litre." % model(s)
	var st: Array = s.story
	return "%s is modelled by %s, where t is in %s." % [st[0].substr(0, 1).to_upper() + st[0].substr(1), model(s), st[2]]


## The model told in words only (cost and mix), with no formula.
static func in_words(s: Dictionary) -> String:
	if s.ctx == "cost":
		return "A factory has a fixed cost of %d dollars, and each item costs %d dollars to make. The average cost per item is the total cost divided by the number of items." % [s.F, s.v]
	return "A tank holds %d litres of water with %d grams of salt dissolved in it. Salt water at %d grams per litre is then added. The concentration is the total salt divided by the total volume." % [s.V, s.s, s.p]


static func lines_for(s: Dictionary, rep: String) -> Array:
	return [in_words(s)] if rep == "words" else [about(s)]


## The long-run value as a sentence about the context.
static func long_run(s: Dictionary, reaches: bool) -> String:
	var tail := "reaches it" if reaches else "never reaches it"
	var al := N(s.al)
	match s.ctx:
		"cost":
			return "The average cost per item reaches %s dollars once enough items are made." % al if reaches else "The average cost per item gets closer and closer to %s dollars, the cost of making one more item, but never reaches it." % al
		"mix":
			return "The concentration reaches %s g per litre after enough litres are added." % al if reaches else "The concentration gets closer and closer to %s g per litre, the strength of the water added, but never reaches it." % al
	var st: Array = s.story
	var cap: String = st[0].substr(0, 1).to_upper() + st[0].substr(1)
	return "%s reaches %s%s after enough %s." % [cap, al, st[1], st[2]] if reaches else "In the long run %s gets closer and closer to %s%s, but %s." % [st[0], al, st[1], tail]


## A table of the model at some inputs: [[var, [..]], [fn, [..]]].
static func table(s: Dictionary, xs: Array) -> Dictionary:
	var f := fn(s) + "(" + var_(s) + ")"
	return {"rows": [[var_(s), xs.map(func(x): return N(x))], [f, xs.map(func(x): return D(RationalModelSituation.at(s, x)))]]}


## The graph of the model, with its horizontal asymptote dashed and optionally y = target.
static func graph(s: Dictionary, target: Variant = null) -> Dictionary:
	var xmax: int = {"cost": 100, "mix": 100, "settle": 20}[s.ctx]
	var top := float(s.al) * 1.4
	var ymax: int
	match s.ctx:
		"cost":
			top = float(s.al) + s.F / 10.0
		"mix":
			top = float(s.p) * 1.3
		_:
			top = float(s.L) * 1.2
	ymax = Plot.nice_top(top)
	var f := func(x: float) -> float: return (s.al * x + s.be) / (x + s.ga)
	var hl: Array = [[s.al, ""]]
	if target != null:
		hl.append([Q.of(target).to_float(), "y = " + D(target)])
	var g := Plot.spec([Plot.sample(f, 0.01 if s.ctx == "cost" else 0.0, float(xmax))], [], 0, xmax, 0, ymax, hl)
	g.x_name = var_(s)
	g.one_colour = true
	return g


## "4n + 500 = 12 × n": the model set equal to a value, the bottom cleared.
static func equal_line(s: Dictionary, T: Variant) -> String:
	var v := var_(s)
	var bottom := v if s.ga == 0 else "(%s + %d)" % [v, s.ga]
	return "%s%s + %d = %s × %s" % [N(s.al), v, s.be, D(T), bottom]


## "(4 − 12)n = 12 × 0 − 500": the input terms collected on one side.
static func collect_line(s: Dictionary, T: Variant) -> String:
	return "(%s − %s)%s = %s × %d − %d" % [N(s.al), D(T), var_(s), D(T), s.ga, s.be]


# ── The unknowns ─────────────────────────────────────────────

func u_evaluate_model(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x0: int = s.x0
	var val := RationalModelSituation.at(s, x0)
	var f := "%s(%d)" % [fn(s), x0]
	var ans := Answer.make("number", {"v": val}, {}, f + " = ", unit(s))
	ans.exact = true
	ans.show = "dec"
	var out := {"asked": "Find %s." % f, "lines": lines_for(s, rep), "answer": ans, "wrongs": [],
		"generic": [{"v": Q.new(s.be + s.al * x0)}, {"v": Q.new(s.al)}, {"v": val.add(Q.new(1))}, {"v": Q.new(s.be).div(Q.new(x0 + s.ga))}]}
	if rep == "table":
		out.table = table(s, s.xs)
	var top := "%d + %d × %d" % [s.be, s.al, x0] if s.ctx != "settle" else "%d × %d + %d" % [s.al, x0, s.be]
	var fin := "So " + Answer.text(ans) + "."
	var sub := "%s = (%s)/(%s)" % [f, top, "%d" % (x0 + s.ga)] if s.ctx != "cost" else "%s = (%s)/%d" % [f, top, x0]
	var mid := "%s = %s/%d = %s" % [f, N(s.be + s.al * x0), x0 + s.ga, D(val)]
	out.methods = {
		"substitute-interpret": method(["Put %s = %d into the model: %s." % [var_(s), x0, sub], mid, fin], ans.values),
		"direct-substitution": method(["Replace %s by %d in %s." % [var_(s), x0, rhs(s)], mid, fin], ans.values),
	}
	return out


func u_long_run_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := long_run(s, false)
	var out := {"asked": "What happens to %s in the long run, and is that value ever reached?" % {"cost": "the average cost per item", "mix": "the concentration", "settle": "the level"}[s.ctx],
		"lines": [about(s)] if rep == "equation" else [about(s), "The graph of the model is shown, with its horizontal asymptote dashed."]}
	var plain: Array = []
	match s.ctx:
		"cost":
			plain = ["The average cost per item gets closer and closer to %s dollars, the fixed cost, but never reaches it." % N(s.F), "The average cost per item rises without limit as more items are made."]
		"mix":
			plain = ["The concentration gets closer and closer to %s g per litre, the strength it started at, but never reaches it." % N(s.c0), "The concentration rises without limit as more is added."]
		_:
			plain = ["The level gets closer and closer to %s%s, the level it started at, but never reaches it." % [N(s.P0), s.story[1]], "The level rises without limit."]
	out.merge(pick(right, [tag(long_run(s, true), R_REACHES)], plain))
	if rep == "graph":
		out.graph = graph(s)
	var fin := "So " + right
	out.methods = {"interpret-asymptote": method(["For large %s the constants matter little: f ≈ %s%s/%s = %s." % [var_(s), N(s.al), var_(s), var_(s), N(s.al)],
		"The model is %s minus a positive fraction, so it is always a little off %s and never equals it." % [N(s.al), N(s.al)], fin], {"v": right})}
	return out


func u_least_n_for_target(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var T: Q = s.tgt
	var v := var_(s)
	var ans := Answer.make("number", {"v": Q.new(n)}, {}, "%s = " % v, input_unit(s))
	ans.exact = true
	ans.show = "dec"
	var down := int(floor(s.nstar.to_float()))
	var at_n := RationalModelSituation.at(s, n)
	var asked := ""
	match s.ctx:
		"cost":
			asked = "How many items must be made for the average cost per item to be less than %s dollars?" % D(T)
		"mix":
			asked = "How many litres must be added for the concentration to be at least %s g per litre?" % D(T)
		_:
			asked = "How many %s are needed for the level to be at least %s%s?" % [s.story[2], D(T), s.story[1]]
	var shown := Q.new(roundi(at_n.to_float() * 100.0), 100)
	var out := {"asked": asked, "lines": lines_for(s, rep), "answer": ans,
		"wrongs": [{"values": {"v": Q.new(down)}, "ref": R_ROUND_DOWN}, {"values": {"v": shown}, "ref": R_OUTPUT}],
		"generic": [{"v": Q.new(n + 1)}, {"v": Q.new(n * 2)}, {"v": Q.new(down - 1)}]}
	var fin := "So " + Answer.text(ans) + "."
	var near := Fmt.dec(Q.new(roundi(s.nstar.to_float() * 100.0), 100))
	var rounded := "%s = %s (to 2 d.p.), which is not whole: at %d the value has not passed %s, so round up to %d." % [v, near, down, D(T), n]
	out.methods = {
		"solve-algebraically": method(["Set the model equal to the target: %s." % equal_line(s, T), "Collect the %s terms: %s." % [v, collect_line(s, T)], rounded, fin], ans.values),
		"gdc-intersect": method(["Graph y = %s(%s) and y = %s on the GDC and find where they meet." % [fn(s), v, D(T)], "They meet at %s = %s (to 2 d.p.)." % [v, near], "Round up to the next whole number, %d, so the condition holds." % n, fin], ans.values),
	}
	return out


func u_input_for_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var xs_: int = s.xstar
	var T: Q = s.tstar
	var v := var_(s)
	var ans := Answer.make("number", {"v": Q.new(xs_)}, {}, "%s = " % v, input_unit(s))
	ans.exact = true
	ans.show = "dec"
	var f := fn(s)
	var out := {"asked": "For which %s is %s(%s) = %s?" % [v, f, v, D(T)], "lines": lines_for(s, "equation") if rep != "words" else [about(s)], "answer": ans, "wrongs": [],
		"generic": [{"v": Q.new(xs_ + 10)}, {"v": T}, {"v": Q.new(maxi(xs_ - 10, 1))}, {"v": Q.new(xs_ * 2)}]}
	if rep == "table":
		out.table = table(s, s.xs)
	if rep == "graph":
		out.graph = graph(s, T)
		out.lines = [about(s), "The graph of the model is shown, with the line y = %s." % D(T)]
	var fin := "So " + Answer.text(ans) + "."
	out.methods = {
		"solve-algebraically": method(["Set the model equal to the value: %s." % equal_line(s, T), "Collect the %s terms: %s, so %s = %d." % [v, collect_line(s, T), v, xs_], fin], ans.values),
		"gdc-intersect": method(["Graph y = %s(%s) and y = %s on the GDC and find where they meet." % [f, v, D(T)], "They meet at %s = %d." % [v, xs_], fin], ans.values),
	}
	return out


func u_build_model(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := model(s)
	var out := {"asked": "Write the model for %s." % {"cost": "the average cost per item of n items, A(n)", "mix": "the concentration after x litres are added, C(x)"}[s.ctx], "lines": [in_words(s)]}
	var plain: Array
	var bad: Array
	match s.ctx:
		"cost":
			bad = [tag("A(n) = %d + %dn" % [s.F, s.v], "")]
			plain = ["A(n) = %d/n + %dn" % [s.F, s.v], "A(n) = (%dn + %d)/n" % [s.F, s.v], "A(n) = (%d + %dn)/%d" % [s.F, s.v, s.F]]
		_:
			bad = [tag("C(x) = %d + %dx" % [s.s, s.p], "")]
			plain = ["C(x) = (%d + %dx)/x" % [s.s, s.p], "C(x) = (%d + %d)/(%d + x)" % [s.s, s.p, s.V], "C(x) = (%d + %dx)/%d" % [s.s, s.p, s.V]]
	out.merge(pick(right, bad, plain))
	var fin := "So " + right + "."
	var total := "total cost = %d + %dn" % [s.F, s.v] if s.ctx == "cost" else "total salt = %d + %dx grams, total volume = %d + x litres" % [s.s, s.p, s.V]
	out.methods = {"substitute-interpret": method(["Write the total: %s." % total, "Divide by %s to get the %s." % ["the number of items n" if s.ctx == "cost" else "the volume", "average cost per item" if s.ctx == "cost" else "concentration"], fin], {"v": right})}
	return out


func u_interpret_vertical_asymptote(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := var_(s)
	var at_ := "%s = %s" % [v, N(-s.ga)]
	var right: String
	var bad: Array
	var plain: Array
	match s.ctx:
		"cost":
			right = "n = 0 is outside the sensible domain: with no items made the average cost is not defined."
			bad = [tag("n = 0 is a real production level: making 0 items gives the highest average cost.", R_REAL_VALUE)]
			plain = ["n = 0 is where the average cost reaches %s dollars." % N(s.al), "n = 0 shows the fixed cost is paid first."]
		"mix":
			right = "x = %s is outside the sensible domain: a negative number of litres can't be added." % N(-s.ga)
			bad = [tag("x = %s is a real amount: adding %s litres gives the strongest mixture." % [N(-s.ga), N(-s.ga)], R_REAL_VALUE)]
			plain = ["x = %s is where the concentration reaches %s g per litre." % [N(-s.ga), N(s.al)], "x = %s is the amount of water that must be added first." % N(-s.ga)]
		_:
			right = "t = %s is outside the sensible domain: the model starts at t = 0, so a negative time is never used." % N(-s.ga)
			bad = [tag("t = %s is a real time: the level is largest %s %s before the start." % [N(-s.ga), N(s.ga), s.story[2]], R_REAL_VALUE)]
			plain = ["t = %s is where the level reaches %s%s." % [N(-s.ga), N(s.al), s.story[1]], "t = %s is the time the level starts to settle." % N(-s.ga)]
	var out := {"asked": "The graph has a vertical asymptote at %s. What does it mean in this context?" % at_,
		"lines": [about(s)] if rep == "equation" else [about(s), "The graph of the model is shown."]}
	out.merge(pick(right, bad, plain))
	if rep == "graph":
		out.graph = graph(s)
	var fin := "So " + right
	out.methods = {"interpret-asymptote": method(["The denominator is 0 at %s, so the model is undefined there: that is the vertical asymptote." % at_, "Ask whether that input can happen here: %s." % ("a number of items can't be 0 for an average" if s.ctx == "cost" else "inputs can't be negative"), fin], {"v": right})}
	return out


func u_parameters_from_data(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x1: int = s.x1
	var y1: Q = s.y1
	var name: String
	var val: Q
	var u_text: String
	var shown: String
	var point := "%s(%d) = %s" % [fn(s), x1, D(y1)]
	match s.ctx:
		"cost":
			name = "F"
			val = Q.new(s.F)
			u_text = " dollars"
			shown = "A(n) = (F + %dn)/n" % s.v
		"mix":
			name = "s"
			val = Q.new(s.s)
			u_text = " grams"
			shown = "C(x) = (s + %dx)/(%d + x)" % [s.p, s.V]
		_:
			name = "k"
			val = Q.new(s.k)
			u_text = " " + s.story[2]
			shown = "P(t) = (%dt + %dk)/(t + k)" % [s.L, s.P0]
	var ans := Answer.make("number", {"v": val}, {}, name + " = ", u_text)
	ans.exact = true
	ans.show = "dec"
	var lines: Array = [shown + ", where %s is a constant." % name]
	var out := {"asked": "Find the value of %s." % name, "answer": ans, "wrongs": [],
		"generic": [{"v": val.add(Q.new(1))}, {"v": val.neg()}, {"v": y1}, {"v": val.mul(Q.new(2))}]}
	if rep == "words":
		lines.append("The model gives %s." % point.replace(" = ", " as "))
		match s.ctx:
			"cost":
				lines = ["The average cost per item of n items is %s dollars. In the long run it tends to %d dollars, and for %d items it is %s dollars." % [shown, s.v, x1, D(y1)]]
			"mix":
				lines = ["The concentration after x litres are added is %s g per litre. For large x it tends to %d g per litre, and after %d litres it is %s g per litre." % [shown, s.p, x1, D(y1)]]
			_:
				lines = ["%s is modelled by %s. It starts at %d%s and settles at %d%s, and after %d %s it is %s%s." % [s.story[0].substr(0, 1).to_upper() + s.story[0].substr(1), shown, s.P0, s.story[1], s.L, s.story[1], x1, s.story[2], D(y1), s.story[1]]]
	else:
		lines.append("The table shows values of the model.")
		var cols: Array = [x1]
		for x in s.xs:
			if cols.size() < 3 and x != x1:
				cols.append(x)
		cols.sort()
		out.table = table(s, cols)
	out.lines = lines
	var fin := "So " + Answer.text(ans) + "."
	var work: String
	match s.ctx:
		"cost":
			work = "%s = (%s + %d × %d)/%d, so %s + %d = %s × %d" % [D(y1), name, s.v, x1, x1, name, s.v * x1, D(y1), x1]
		"mix":
			work = "%s = (%s + %d × %d)/(%d + %d), so %s + %d = %s × %d" % [D(y1), name, s.p, x1, s.V, x1, name, s.p * x1, D(y1), s.V + x1]
		_:
			work = "%s = (%d × %d + %d%s)/(%d + %s)" % [D(y1), s.L, x1, s.P0, name, x1, name]
	out.methods = {
		"interpret-asymptote": method(["The long-run value fixes the x-coefficient of the model; the data point gives the constant.", "Put in the point: %s." % work, fin], ans.values),
		"solve-algebraically": method(["Substitute the point %s into the model." % point, "%s." % work, fin], ans.values),
	}
	return out
