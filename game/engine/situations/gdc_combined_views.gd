class_name GdcCombinedViews
extends RefCounted
## The views on the `gdc-combined` situation: one builder per unknown of
## fn-gdc-optimise-combined (FAL-420). Builders return what QuadraticViews' builders
## return (see quadratic_views.gd). Paper 2: values from the GDC to 3 s.f.

const NEED := {
	"form-difference": {"mode": "difference"},
	"max-difference": {"mode": "difference"},
	"difference-zero": {"mode": "difference", "kind": "towns", "zero": true},
	"least-distance": {"mode": "distance"},
	"closest-point": {"mode": "distance"},
	"sum-graph": {"mode": "sum"},
	"sum-zeros": {"mode": "sum"},
	"interpret-extreme": {"mode": "difference"},
	"first-whole-day": {"mode": "difference", "kind": "towns", "zero": true},
}

const MM := "SL2.4.max-min"
const SD := "SL2.3.sum-difference"
const CA := "SL2.10.context-apply"


func has(unknown: String) -> bool:
	return NEED.has(unknown)


func need(unknown: String, rep: String) -> Dictionary:
	var n: Dictionary = NEED[unknown].duplicate()
	if unknown == "first-whole-day" and rep == "table":
		n.table = true
	return n


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "wrongs", "generic"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "generic"] else null
	out.given = GdcCombinedSituation.export(s)
	if not out.has("trap"):
		out.trap = GdcCurveViews.trap(out.answer) if out.answer.kind != "named" else Answer.rounding_trap_all(out.answer)
	out.wrongs = out.wrongs.filter(func(w): return GdcCurveViews.clear(w.values))
	out.generic = out.generic.filter(func(g): return GdcCurveViews.clear(g))
	return out


# ── Helpers ──────────────────────────────────────────────────

static func S(x: Variant) -> String:
	return GdcKit.S(x)


static func W(x: Variant) -> String:
	return GdcKit.W(x)


static func qf(x: float) -> Q:
	return GdcKit.qf(x)


static func wrong(values: Dictionary, ref: String = "") -> Dictionary:
	return {"values": values, "ref": ref}


static func ft(s: Dictionary) -> String:
	return GdcTwoCurvesSituation.text(s.f, s.var)


static func gt(s: Dictionary) -> String:
	return GdcTwoCurvesSituation.text(s.g, s.var)


static func dom(s: Dictionary) -> String:
	return "%s ≤ %s ≤ %s" % [Fmt.num(s.d1), s.var, Fmt.num(s.d2)]


## The two models as written, in function notation or in words.
static func models(s: Dictionary, rep: String) -> String:
	var c: Dictionary = s.ctx
	if c.kind == "towns":
		if rep == "words":
			return "Town P has P(t) = %s thousand people and town Q has Q(t) = %s thousand people, t years after 2020, for %s." % [ft(s), gt(s), dom(s)]
		return "P(t) = %s and Q(t) = %s, for %s" % [ft(s), gt(s), dom(s)]
	if rep == "words":
		return "Two drugs are taken at t = 0. Their concentrations in the blood are A(t) = %s and B(t) = %s mg/l, t hours later, for %s." % [ft(s), gt(s), dom(s)]
	return "A(t) = %s and B(t) = %s, for %s" % [ft(s), gt(s), dom(s)]


## D(t) the right way round: how far Q is ahead of P, or how much higher A is than B.
static func d_meaning(s: Dictionary) -> String:
	return "how far town Q's population is ahead of town P's" if s.kind == "towns" else "how much higher drug A's concentration is than drug B's"


static func d_text(s: Dictionary) -> String:
	if s.kind == "towns":
		return "%s − %s" % [gt(s), ft(s)]
	return "%s − %s" % [ft(s), gt(s)]


static func d_step(s: Dictionary) -> String:
	return "D(t) = %s, %s." % [d_text(s), d_meaning(s)]


# ── fn-gdc-optimise-combined ─────────────────────────────────

func u_form_difference(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := "D(t) = " + d_text(s)
	var gen: Array
	if s.kind == "towns":
		# −(q + rt) written out, a sign slip and the sum.
		var q: Dictionary = s.g
		gen = ["D(t) = %s − %s" % [ft(s), gt(s)], "D(t) = %s − %s%s" % [ft(s), GdcKit.first(q.m, "t"), GdcKit.join(q.c, "")],
			"D(t) = %s + %s" % [ft(s), gt(s)], "D(t) = %s − %s" % [gt(s), GdcKit.first(s.f.A, "t")]]
	else:
		var dk: Q = s.f.A.sub(s.g.A)
		gen = ["D(t) = %s − %s" % [gt(s), ft(s)], "D(t) = %s + %s" % [ft(s), gt(s)],
			"D(t) = %s" % GdcTwoCurvesSituation.text(GdcTwoCurvesSituation.curve("texp", {"A": dk if not dk.is_zero() else Q.new(1), "k": s.f.k.sub(s.g.k).abs_q()}), "t")]
	var out := LogFunctionViews.choice(right, [], gen)
	var final: String = "So " + out.answer.values.v + "."
	out.merge({
		"asked": "Write down an expression for D(t), %s." % d_meaning(s), "lines": [models(s, rep)],
		"methods": {"simplify-first": {"result": out.answer.values, "steps": [
			"The one that is ahead comes first: %s." % ("Q(t) − P(t)" if s.kind == "towns" else "A(t) − B(t)"),
			"Substitute each model in brackets, then drop the brackets with care: %s." % d_text(s), final]}}})
	return out


func u_max_difference(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var e: Dictionary = s.ext
	var ans := Answer.make("named", {"v0": qf(e.x), "v1": qf(e.y)}, {"names": ["t", "D"]})
	ans.show = "sf"
	var final := "So " + Answer.text(ans) + ": the greatest difference is %s, at t = %s." % [S(e.y), S(e.x)]
	var wrongs: Array = [wrong({"v0": qf(e.y), "v1": qf(e.x)}, MM + "#0")]
	if s.kind == "drugs":
		var tm: float = 1.0 / s.f.co[4]
		wrongs.append(wrong({"v0": qf(tm), "v1": qf(GdcCombinedSituation.at(s, tm))}, SD + "#2"))
	var gen: Array = [{"v0": qf(e.x), "v1": qf(GdcTwoCurvesSituation.at(s.f, e.x))}, {"v0": qf(e.x + 1.0), "v1": qf(e.y)},
		{"v0": qf(e.x), "v1": qf(-e.y)}]
	var tool := "The maximum tool gives (%s, %s)." % [W(e.x), W(e.y)]
	return {
		"asked": "Find the greatest value of D(t), %s, and the time when it happens." % d_meaning(s), "lines": [models(s, rep)],
		"answer": ans, "wrongs": wrongs, "generic": gen,
		"methods": {
			"gdc-combine": {"result": ans.values, "steps": [d_step(s), "Graph y = D(t) on %s, as one function." % dom(s), tool, final]},
			"gdc-max-min": {"result": ans.values, "steps": [d_step(s), "Graph it and use the maximum tool, not the maximum of either model.", tool, final]},
			"derivative-zero": {"result": ans.values, "steps": [d_step(s),
				"D′(t) = 0 mixes families, so solve it on the GDC: t = %s." % W(e.x), "Then D(%s) = %s." % [W(e.x), W(e.y)], final]},
		},
	}


func u_difference_zero(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z: float = s.zeros[0]
	var out_z: float = s.outside
	var ans := Answer.make("xs", Answer.xs_of([qf(z)]), {"var": "t"})
	ans.show = "sf"
	var final := "So D(t) = 0 at " + Answer.text(ans) + ", the only time in the domain."
	var gen: Array = [Answer.xs_of([qf(-z)]), Answer.xs_of([qf(s.ext.x)]), Answer.xs_of([qf(z + 1.0)])]
	var both := "On the whole real line D(t) = 0 at t = %s and t = %s; only t = %s is in %s." % [W(out_z), W(z), W(z), dom(s)]
	return {
		"asked": "Find when D(t), %s, is zero." % d_meaning(s), "lines": [models(s, rep)], "answer": ans,
		"wrongs": [wrong(Answer.xs_of([qf(out_z), qf(z)]), CA + "#1")], "generic": gen,
		"methods": {
			"gdc-combine": {"result": ans.values, "steps": [d_step(s), "Graph y = D(t) and use the zero tool.", both, final]},
			"gdc-intersect": {"result": ans.values, "steps": ["D(t) = 0 where the models are equal: graph y = %s and y = %s." % [ft(s), gt(s)],
				both, final]},
			"analytic-logs": {"result": ans.values, "steps": ["%s = %s mixes an exponential and a line, so taking logs can't solve it: this method fails." % [ft(s), gt(s)],
				both, final]},
		},
	}


func u_least_distance(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var e: Dictionary = s.ext
	var ans := GdcCurveViews.num(e.y)
	var final := "So the least distance is " + Answer.text(ans) + "."
	var c: Array = s.closest
	var out := _distance(s, ans, final, e, c)
	out.asked = "Find the least distance from P to the curve."
	out.wrongs = [wrong({"v": qf(c[0])}, MM + "#0")]
	out.generic = [{"v": qf(e.y * e.y)}, {"v": qf(absf(c[1]))}, {"v": qf(GdcCombinedSituation.at(s, s.d1.to_float()))}]
	# The distance to 2 s.f. is the rounding trap, and its misconception.
	out.trap_ref = MM + "#2"
	return out


func u_closest_point(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var e: Dictionary = s.ext
	var c: Array = s.closest
	var ans := Answer.make("point", {"x": qf(c[0]), "y": qf(c[1])})
	ans.show = "sf"
	var final := "So the closest point is " + Answer.text(ans) + "."
	var out := _distance(s, ans, final, e, c)
	out.asked = "Find the coordinates of the point on the curve closest to P."
	out.generic = [{"x": qf(c[0]), "y": qf(e.y)}, {"x": qf(c[1]), "y": qf(c[0])}, {"x": Q.new(0), "y": qf(GdcTwoCurvesSituation.at(s.f, 0.0))},
		{"x": qf(c[0]), "y": qf(-c[1])}]
	return out


func _distance(s: Dictionary, ans: Dictionary, final: String, e: Dictionary, c: Array) -> Dictionary:
	var px := Fmt.num(s.P[0])
	var py := Fmt.num(s.P[1])
	var dx := "x" if s.P[0] == 0 else "x %s %s" % ["−" if s.P[0] > 0 else "+", Fmt.num(absi(s.P[0]))]
	var fy := "f(x)" if s.P[1] == 0 else "f(x) %s %s" % ["−" if s.P[1] > 0 else "+", Fmt.num(absi(s.P[1]))]
	var d := "d(x) = √((%s)² + (%s)²)" % [dx, fy]
	var tool := "The minimum tool gives x = %s, where d = %s; the point is %s." % [W(e.x), W(e.y), GdcKit.pt6(c[0], c[1])]
	return {
		"lines": ["f(x) = %s, for %s, and the point P(%s, %s)" % [ft(s), "%s ≤ x ≤ %s" % [Fmt.num(s.d1), Fmt.num(s.d2)], px, py]],
		"answer": ans, "wrongs": [], "generic": [],
		"methods": {
			"gdc-combine": {"result": ans.values, "steps": ["The distance from P to the point (x, f(x)) is " + d + ".",
				"Graph y = d(x) on the domain.", tool, final]},
			"gdc-max-min": {"result": ans.values, "steps": [d + ". Minimising d² gives the same x.", tool, final]},
			"derivative-zero": {"result": ans.values, "steps": [d + ".",
				"d′(x) = 0 has no algebraic solution here, so the GDC solves it: x = %s." % W(e.x), tool, final]},
		},
	}


func u_sum_graph(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var lo: float = s.d1.to_float()
	var hi: float = s.d2.to_float()
	var f := func(x: float) -> float: return GdcTwoCurvesSituation.at(s.f, x)
	var g := func(x: float) -> float: return GdcTwoCurvesSituation.at(s.g, x)
	var sum := func(x: float) -> float: return f.call(x) + g.call(x)
	var ys: Array = []
	for i in 33:
		var x := lo + (hi - lo) * i / 32.0
		ys.append_array([f.call(x), g.call(x), sum.call(x)])
	var w := GdcKit.window(lo, hi, ys.min(), ys.max())
	var card := func(fn: Callable) -> Dictionary: return GdcKit.card([GdcKit.curve(fn, lo, hi)], [], w)
	var side := func(x: float) -> float: return f.call(x + g.call(x))
	var diff := func(x: float) -> float: return f.call(x) - g.call(x)
	var g0: float = g.call(0.0)
	var lift := func(x: float) -> float: return f.call(x) + g0
	var p := GdcKit.pick(card.call(sum), [
		{"graph": card.call(side), "ref": SD + "#0", "mistake": "sideways", "why": "it adds g to x, not to y, so the curve is pushed sideways instead of lifted"},
		{"graph": card.call(diff), "ref": "", "mistake": "difference", "why": "it is f − g, not f + g"},
		{"graph": card.call(lift), "ref": "", "mistake": "constant-lift", "why": "it lifts f by g(0) everywhere, but g changes with x"},
	], rng)
	var final: String = "So the graph of f + g is %s." % p.answer.values.v
	var shown := Plot.spec([GdcKit.curve(f, lo, hi), GdcKit.curve(g, lo, hi)], [], w[0], w[1], w[2], w[3])
	return {
		"asked": "The graphs of y = f(x) and y = g(x) are shown. Which graph is y = f(x) + g(x)?",
		"lines": ["f(x) = %s and g(x) = %s, for %s ≤ x ≤ %s" % [ft(s), gt(s), Fmt.num(s.d1), Fmt.num(s.d2)]], "graph": shown,
		"answer": p.answer, "graphs": p.graphs,
		"methods": {"add-ordinates": {"result": p.answer.values, "steps": [
			"At each x, add the heights: the new height is f(x) + g(x).",
			"For example at x = %s: %s + %s = %s." % [Fmt.num(s.d1), S(f.call(lo)), S(g.call(lo)), S(sum.call(lo))], final]}},
	}


func u_sum_zeros(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := GdcCurveViews.xs_ans(s.zeros.map(func(z): return qf(z)))
	var final := "So f(x) + g(x) = 0 at " + Answer.text(ans) + "."
	var both: Array = s.f_zeros + s.g_zeros
	both.sort()
	var gen: Array = [Answer.xs_of(s.f_zeros.map(func(z): return qf(z))), Answer.xs_of(s.zeros.map(func(z): return qf(-z))),
		Answer.xs_of(s.zeros.map(func(z): return qf(z + 1.0)))]
	var out := {"asked": "Find the zeros of f(x) + g(x).", "lines": ["f(x) = %s and g(x) = %s, for %s ≤ x ≤ %s" % [ft(s), gt(s), Fmt.num(s.d1), Fmt.num(s.d2)]],
		"answer": ans, "wrongs": [wrong(Answer.xs_of(both.map(func(z): return qf(z))), SD + "#1")], "generic": gen}
	if rep == "graph":
		out.lines = ["The graphs of " + out.lines[0] + " are shown."]
		var lo: float = s.d1.to_float()
		var hi: float = s.d2.to_float()
		var f := func(x: float) -> float: return GdcTwoCurvesSituation.at(s.f, x)
		var g := func(x: float) -> float: return GdcTwoCurvesSituation.at(s.g, x)
		var ys: Array = []
		for i in 33:
			var x := lo + (hi - lo) * i / 32.0
			ys.append_array([f.call(x), g.call(x)])
		var w := GdcKit.window(lo, hi, ys.min(), ys.max())
		out.graph = Plot.spec([GdcKit.curve(f, lo, hi), GdcKit.curve(g, lo, hi)], [], w[0], w[1], w[2], w[3])
	var zs := Answer.xs_list(s.zeros.map(func(z): return "x = " + W(z)))
	out.methods = {"gdc-combine": {"result": ans.values, "steps": [
		"Enter y = %s + %s as one function: the zeros of the sum, not of each part." % [ft(s), gt(s)],
		"The zero tool gives " + zs + ".", final]}}
	return out


func u_interpret_extreme(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var e: Dictionary = s.ext
	var right: String
	var lead: String
	var gen: Array
	if s.kind == "towns":
		right = "It is %s years after 2020 that town Q is furthest ahead of town P." % S(e.x)
		lead = "Town Q's greatest lead over town P is %s thousand people." % S(e.y)
		gen = ["It is %s years after 2020 that town P overtakes town Q." % S(e.x), "It is %s years after 2020 that town Q's population is greatest." % S(e.x)]
	else:
		right = "It is %s hours after the drugs are taken that A's concentration is furthest above B's." % S(e.x)
		lead = "The greatest amount by which A's concentration is above B's is %s mg/l." % S(e.y)
		gen = ["It is %s hours after the drugs are taken that A's concentration is greatest." % S(e.x),
			"It is %s hours after the drugs are taken that the concentrations are equal." % S(e.x)]
	var out := LogFunctionViews.choice(right, [wrong({"v": lead}, CA + "#2")], gen)
	var final: String = "So: " + out.answer.values.v
	out.merge({
		"asked": "D(t) is %s. The graph of D has its maximum point at (%s, %s). What does %s tell you?" % [d_meaning(s), S(e.x), S(e.y), S(e.x)],
		"lines": [models(s, "words")],
		"methods": {"graph-read": {"result": out.answer.values, "steps": [
			"The first coordinate of a point on D's graph is a time t; the second is the size of D then.",
			"At the maximum, %s is the time and %s is the greatest value of D." % [S(e.x), S(e.y)], final]}}})
	return out


func u_first_whole_day(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z: float = s.zeros[0]
	var n := ceili(z)
	var ans := Answer.make("number", {"v": Q.new(n)}, {}, "t = ")
	ans.exact = true
	var final := "So the first whole number of years is " + Answer.text(ans) + "."
	var gen: Array = [{"v": Q.new(n + 1)}, {"v": Q.new(roundi(s.ext.x))}, {"v": Q.new(maxi(n - 2, 0))}]
	var out := {"asked": "Find the first whole number of years t after 2020 at which town P has more people than town Q.",
		"lines": [models(s, "words")], "answer": ans, "wrongs": [wrong({"v": Q.new(floori(z))}, CA + "#0")], "generic": gen}
	if rep == "table":
		var tb: Dictionary = s.table
		out.lines = ["The table shows the populations of town P, P(t) = %s, and town Q, Q(t) = %s, in thousands, t years after 2020." % [ft(s), gt(s)]]
		out.table = {"rows": [["t", tb.xs.map(func(v): return Fmt.num(v))], ["P(t)", tb.fs.map(func(v): return Fmt.sf(v))],
			["Q(t)", tb.gs.map(func(v): return Fmt.sf(v))]], "xs": tb.xs, "fs": tb.fs, "gs": tb.gs}
	out.methods = {
		"gdc-intersect": {"result": ans.values, "steps": ["Graph y = %s and y = %s; they cross at t = %s." % [ft(s), gt(s), W(z)],
			"P is ahead after the crossing, so round up, not down: the first whole year is %d." % n, final]},
		"table-search": {"result": ans.values, "steps": [
			"Tabulate P(t) − Q(t) at whole years: at t = %d it is %s, at t = %d it is %s." % [n - 1, S(-GdcCombinedSituation.at(s, n - 1.0)),
				n, S(-GdcCombinedSituation.at(s, float(n)))],
			"It turns positive between them, so the first whole year with P ahead is %d." % n, final]},
	}
	return out
