class_name GrowthPatternsViews
extends ExtensionViews
## The views on the `exp-growth-vs-linear` situation: one builder per unknown of
## fn-concept-growth-patterns (FAL-418). A linear pattern adds the same amount each
## step; an exponential one multiplies by the same factor.

const LIN := "linear: the differences are constant"
const EXP := "exponential: the ratios are constant"
const NEITHER := "neither: the differences and the ratios both change"


func needs() -> Dictionary:
	return {"classify-table": {}, "classify-words": {}, "classify-graph": {}, "next-values": {}, "interpret-d-and-r": {},
		"when-overtakes": {}}


func extra() -> Dictionary:
	var tfr := ["true-false-reason"]
	return {"classify-table": ["true-false-reason", "method-pick"], "classify-words": tfr, "classify-graph": tfr,
		"next-values": tfr, "interpret-d-and-r": tfr, "when-overtakes": ["true-false-reason", "method-pick"]}


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = GrowthPatternsSituation.export(s)
	return out


static func D(v: Variant) -> String:
	return Fmt.dec(v)


## A value as a decimal to at most 2 places: "4050", "1366.88". Powers of the factor
## are kept as floats: exactly, 1000·1.1²⁵ overflows a fraction.
static func V(x: float) -> String:
	return String.num(snappedf(x, 0.01)).replace("-", "−")


## The pattern's value at step t, exactly: linear, exponential or (neither) a quadratic.
static func value(s: Dictionary, kind: String, t: int) -> Q:
	match kind:
		"lin":
			return s.Q0.add(s.d.mul(Q.new(t)))
		"exp":
			return s.P0.mul(GrowthPatternsSituation.pow_q(s.a, t))
	return s.P0.add(s.d.mul(Q.new(t * t)))


func u_classify_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var kind: String = s.kind
	var vals: Array = range(5).map(func(t): return value(s, kind, t))
	var right: String = {"lin": LIN, "exp": EXP, "neither": NEITHER}[kind]
	var opts := [right] + [LIN, EXP, NEITHER].filter(func(o): return o != right) + ["linear: the values go up"]
	var ans := Answer.make("choice", {"v": right}, {"options": opts})
	var diffs: Array = range(4).map(func(i): return D(vals[i + 1].sub(vals[i])))
	var ratios: Array = range(4).map(func(i): return D(vals[i + 1].div(vals[i])))
	var final := "So it is " + right + "."
	return {"asked": "Is the pattern in the table linear, exponential or neither?", "lines": ["The table shows a quantity at equal steps."],
		"table": {"rows": [["t", ["0", "1", "2", "3", "4"]], ["y", vals.map(func(v): return D(v))]]}, "answer": ans,
		"generic": opts.slice(1).map(func(o): return {"v": o}),
		"methods": {
			"table-differences": method(["Differences: %s." % ", ".join(diffs), "Ratios: %s." % ", ".join(ratios), final], ans.values),
			"repeated-multiplication": method(["Divide each value by the one before: %s." % ", ".join(ratios), "Subtract instead: %s." % ", ".join(diffs), final], ans.values),
		},
		"pick_wrongs": [{"name": "Read the first and last values only", "why": "two values fit a line and an exponential alike"},
			{"name": "Check that the values go up", "why": "linear and exponential growth both go up"},
			{"name": "Look for a curve on a sketch", "why": "a few points can't prove a constant ratio"}]}


func u_classify_words(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var P0: Q = s.P0
	var exp_kind := rng.chance(0.5)
	var right := ""
	var lines: Array = []
	var wrongs: Array = []
	var gen: Array = []
	if exp_kind:
		var r: Q = s.r
		lines = ["A colony starts with %s cells and grows by %s%% each hour." % [D(P0), D(r)]]
		right = "exponential: N = %s(%s)ᵗ" % [D(P0), D(s.a)]
		wrongs = [wrong({"v": "exponential: N = %s(%s)ᵗ" % [D(P0), D(r.div(Q.new(100)))]}, "SL2.9.exp-model#0"),
			wrong({"v": "linear: N = %s + %st" % [D(P0), D(P0.mul(r).div(Q.new(100)))]}, "SL2.9.exp-model#1")]
		gen = ["linear: N = %s + %st" % [D(P0), D(r)], "exponential: N = %s(%s)ᵗ" % [D(r), D(P0)]]
	else:
		var d: Q = s.d
		lines = ["A tank holds %s litres and gains %s litres each hour." % [D(P0), D(d)]]
		right = "linear: N = %s + %st" % [D(P0), D(d)]
		wrongs = [wrong({"v": "linear: N = %s + %st" % [D(d), D(P0)]}, "SL2.1.line-model#1")]
		gen = ["exponential: N = %s(%s)ᵗ" % [D(P0), D(d)], "exponential: N = %s(%s)ᵗ" % [D(P0), D(Q.new(1).add(d.div(Q.new(100))))],
			"linear: N = %st" % D(d)]
	var opts: Array = [right] + wrongs.map(func(w): return w.values.v) + gen
	var ans := Answer.make("choice", {"v": right}, {"options": opts})
	var final := "So it is " + right + "."
	return {"asked": "Is it linear or exponential growth? Choose the model, with t in hours.", "lines": lines, "answer": ans, "wrongs": wrongs,
		"generic": gen.map(func(o): return {"v": o}),
		"methods": {"rate-and-start": method([
			"It starts at %s." % D(P0),
			("Growing by a percentage multiplies by the same factor, %s, each hour." % D(s.a)) if exp_kind else "Gaining the same amount adds %s each hour." % D(s.d),
			final], ans.values)}}


func u_classify_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var kind: String = "exp" if s.kind == "neither" else s.kind
	var right := EXP if kind == "exp" else LIN
	var opts := [right, LIN if kind == "exp" else EXP, NEITHER, "linear: it goes up"]
	var ans := Answer.make("choice", {"v": right}, {"options": opts})
	var f := func(t: float) -> float: return GrowthPatternsSituation.E(s, t) if kind == "exp" else GrowthPatternsSituation.L(s, t)
	var top := maxf(f.call(0.0), f.call(6.0))
	var pts: Array = [0, 1, 2, 3].map(func(t): return [t, value(s, kind, t).to_float(), Fmt.point(t, value(s, kind, t))])
	var final := "So it is " + right + "."
	return {"asked": "Is the growth shown linear or exponential?", "lines": ["The graph shows a quantity y against time t."], "answer": ans,
		"graph": Plot.spec([Plot.sample(f, 0.0, 6.0)], pts, 0, 6, 0, Plot.nice_top(top)),
		"generic": opts.slice(1).map(func(o): return {"v": o}),
		"methods": {"base-comparison": method([
			"Read the marked points: %s." % ", ".join(pts.map(func(p): return p[2])),
			("Each step multiplies y by %s: the curve gets steeper." % D(s.a)) if kind == "exp" else "Each step adds %s: a straight line." % D(s.d), final], ans.values)}}


func u_next_values(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v0: Q = s.P0
	var v1: Q = s.P0.mul(s.a)
	var lin := v1.add(v1.sub(v0))
	var ex := v1.mul(v1).div(v0)
	var ans := Answer.make("named", {"v0": lin, "v1": ex}, {"names": ["linear", "exponential"]})
	ans.show = "dec"
	ans.exact = true
	var final := "So " + Answer.text(ans) + "."
	return {"asked": "Find the next value if the pattern is linear, and if it is exponential.", "lines": ["The first two values are %s and %s." % [D(v0), D(v1)]],
		"table": {"rows": [["t", ["0", "1", "2"]], ["y", [D(v0), D(v1), "?"]]]}, "answer": ans,
		"generic": [{"v0": ex, "v1": lin}, {"v0": lin, "v1": v1.mul(Q.new(2))}, {"v0": v1.add(v0), "v1": ex}, {"v0": lin, "v1": v1.add(v1.sub(v0).mul(s.a))}],
		"methods": {
			"table-differences": method(["The difference is %s − %s = %s, so linear gives %s + %s = %s." % [D(v1), D(v0), D(v1.sub(v0)), D(v1), D(v1.sub(v0)), D(lin)],
				"The ratio is %s ÷ %s = %s, so exponential gives %s × %s = %s." % [D(v1), D(v0), D(s.a), D(v1), D(s.a), D(ex)], final], ans.values),
			"repeated-multiplication": method(["Exponential: multiply by %s again: %s × %s = %s." % [D(s.a), D(v1), D(s.a), D(ex)],
				"Linear: add %s again: %s." % [D(v1.sub(v0)), D(lin)], final], ans.values),
		}}


func u_interpret_d_and_r(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var d: Q = s.d
	var a: Q = s.a
	var right := "each step L gains %s and E is multiplied by %s" % [D(d), D(a)]
	var w0 := "L gains %s in total and E is multiplied by %s each step" % [D(d), D(a)]
	var opts := [right, w0, "each step L is multiplied by %s and E gains %s" % [D(d), D(a)], "each step L gains %s and E gains %s" % [D(d), D(a)]]
	var ans := Answer.make("choice", {"v": right}, {"options": opts})
	var lines: Array = ["L(t) = %s + %st" % [D(s.Q0), D(d)], "E(t) = %s(%s)ᵗ" % [D(s.P0), D(a)]] if rep == "equation" \
		else ["Two savings plans: L starts at %s and gains %s a year; E starts at %s and grows by %s%% a year." % [D(s.Q0), D(d), D(s.P0), D(s.r)]]
	return {"asked": "What do d and a mean for each step?", "lines": lines, "answer": ans, "wrongs": [wrong({"v": w0}, "SL2.1.line-model#0")],
		"generic": [{"v": opts[2]}, {"v": opts[3]}],
		"methods": {"rate-and-start": method(["L adds d = %s every step: a rate per step, not a total." % D(d), "E multiplies by a = %s every step." % D(a), "So " + right + "."], ans.values)}}


func u_when_overtakes(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var nneg: float = s.nneg
	var ans := Answer.make("number", {"v": Q.new(n)}, {}, "t = ")
	ans.exact = true
	var e_n := GrowthPatternsSituation.E(s, n)
	var l_n := GrowthPatternsSituation.L(s, n)
	var e_b := GrowthPatternsSituation.E(s, n - 1)
	var l_b := GrowthPatternsSituation.L(s, n - 1)
	var check := "At t = %d: E = %s, L = %s; at t = %d: E = %s > L = %s." % [n - 1, V(e_b), V(l_b), n, V(e_n), V(l_n)]
	var final := "So " + Answer.text(ans) + "."
	var out := {"asked": "Find the first whole number of steps t after which E stays ahead of L.", "answer": ans,
		"lines": ["L(t) = %s + %st" % [D(s.Q0), D(s.d)], "E(t) = %s(%s)ᵗ" % [D(s.P0), D(s.a)]],
		"wrongs": [wrong({"v": Q.new(roundi(nneg))}, "SL2.1.line-model#2")],
		"generic": [{"v": Q.new(n - 1)}, {"v": Q.new(n + 1)}, {"v": Q.new(n + 2)}],
		"pick_wrongs": [{"name": "Set the rates equal", "why": "a ratio and a difference are not the same kind of rate"},
			{"name": "Compare the starting values", "why": "L starts ahead; what matters is when that changes"},
			{"name": "Solve a linear equation", "why": "E is not linear, so there is no single linear equation to solve"}],
		"methods": {
			"repeated-multiplication": method(["Step on from t = 0, multiplying E by %s and adding %s to L." % [D(s.a), D(s.d)], check, final], ans.values),
			"gdc-intersect": method(["Graph both: they cross at t ≈ %s (and before the start, at t ≈ %s, outside the model)." % [Fmt.sf(_cross(s), 3), Fmt.sf(nneg, 3)], check, final], ans.values),
			"logs-for-unknown": method(["%s(%s)ᵗ = %s + %st mixes a power and a linear term, so logs can't isolate t." % [D(s.P0), D(s.a), D(s.Q0), D(s.d)],
				"Use a table instead: " + check, final], ans.values),
		}}
	if rep == "table":
		out.table = {"rows": [["t"] + [range(n - 2, n + 2).map(func(t): return str(t))],
			["L(t)", range(n - 2, n + 2).map(func(t): return D(s.Q0.add(s.d.mul(Q.new(t)))))],
			["E(t)", range(n - 2, n + 2).map(func(t): return V(GrowthPatternsSituation.E(s, t)))]]}
	elif rep == "graph":
		var fe := func(t: float) -> float: return GrowthPatternsSituation.E(s, t)
		var fl := func(t: float) -> float: return GrowthPatternsSituation.L(s, t)
		out.graph = Plot.spec([Plot.sample(fe, 0.0, n + 2.0), Plot.sample(fl, 0.0, n + 2.0)], [], 0, n + 2, 0, Plot.nice_top(maxf(fe.call(n + 2.0), fl.call(n + 2.0))))
	return out


## The crossing ahead of the start, as a float.
static func _cross(s: Dictionary) -> float:
	var lo := 0.0
	var hi := float(s.n)
	for i in 60:
		var mid := (lo + hi) / 2.0
		if GrowthPatternsSituation.E(s, mid) > GrowthPatternsSituation.L(s, mid):
			hi = mid
		else:
			lo = mid
	return (lo + hi) / 2.0
