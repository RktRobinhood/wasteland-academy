class_name GdcTwoCurvesViews
extends RefCounted
## The views on the `gdc-two-curves` situation: one builder per unknown of
## fn-gdc-intersection (FAL-420). Builders return what QuadraticViews' builders return
## (see quadratic_views.gd). Paper 2: every crossing is found with the GDC's intersect
## tool and answered to 3 s.f., with 6 s.f. in the working; each y is from the
## unrounded x.

const NEED := {
	"intersection-points": {"mode": "line", "far_ok": true},
	"solve-f-equals-g": {"mode": "line", "far_ok": true},
	"models-equal": {"mode": "context", "one_in": true, "far_ok": true},
	"function-and-inverse": {"mode": "inverse"},
	"distance-between-crossings": {"mode": "line", "crossings": 2},
	"count-crossings": {"mode": "line", "far_ok": true},
	"crossing-in-interval": {"mode": "line", "crossings": 2},
	"crossing-from-table": {"mode": "line", "table": true},
	"constant-from-crossing": {"mode": "line", "at0": true, "crossings": 2},
	# fn-concept-solutions-as-intersections (extension)
	"graphs-for-equation": {"mode": "line", "crossings": 2},
	"count-from-sketch": {"mode": "turns_or_far"},
	"x-not-y": {"mode": "line", "crossings": 2},
	"difference-picture": {"mode": "line", "crossings": 2},
	"same-solutions-after-rearranging": {"mode": "line", "crossings": 2},
	"k-for-count": {"mode": "turns"},
}

## The extension unknowns offer true-false-reason (a student's answer, from the options).
const TFR := ["graphs-for-equation", "count-from-sketch", "x-not-y", "same-solutions-after-rearranging", "k-for-count"]
const NS := "SL2.10.number-of-solutions"

const IN := "SL2.4.intersection"
const SG := "SL2.10.solve-gdc"


func has(unknown: String) -> bool:
	return NEED.has(unknown)


func need(unknown: String, _rep: String) -> Dictionary:
	return NEED[unknown].duplicate()


func formats(unknown: String) -> Array:
	return ["true-false-reason"] if unknown in TFR else []


## Two needs as one for a shared situation, or null: the far mode shares only with the
## other far views, and the line through f(0) only with itself (QuestionEngine.families()).
func merge_need(a: Dictionary, b: Dictionary) -> Variant:
	if a.get("far_ok", false) != b.get("far_ok", false) or a.get("at0", false) != b.get("at0", false):
		return null
	return QuestionEngine.merge_need(a, b)


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "wrongs", "generic"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "generic"] else null
	out.given = GdcTwoCurvesSituation.export(s)
	out.given.merge(out.get("check", {}), true)
	if not out.has("trap"):
		out.trap = GdcCurveViews.trap(out.answer) if out.answer.kind != "pts" else Answer.rounding_trap_all(out.answer)
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


## A 6 s.f. value, bracketed when negative: "(−1.93119)".
static func P(x: float) -> String:
	return "(%s)" % W(x) if x < 0.0 else W(x)


static func wrong(values: Dictionary, ref: String = "") -> Dictionary:
	return {"values": values, "ref": ref}


static func ft(s: Dictionary) -> String:
	return GdcTwoCurvesSituation.text(s.f, s.var)


static func gt(s: Dictionary) -> String:
	return GdcTwoCurvesSituation.text(s.g, s.var)


static func dom(s: Dictionary) -> String:
	return GdcTwoCurvesSituation.domain_text(s)


## The two functions as the equation shows them.
static func eq_lines(s: Dictionary) -> Array:
	if s.mode == "inverse":
		return ["f(x) = %s, and its inverse f⁻¹(x) = %s, for %s" % [ft(s), gt(s), dom(s)]]
	return ["f(x) = %s and g(x) = %s, for %s" % [ft(s), gt(s), dom(s)]]


## The context in words: two tanks or two populations.
static func words(s: Dictionary) -> String:
	var c: Dictionary = s.ctx
	if c.kind == "tanks":
		return "The depth of water in tank A is A(t) = %s m, and in tank B is B(t) = %s m, t hours after noon, for %s." % [ft(s), gt(s), dom(s)]
	return "Two towns grow: P(t) = %s and Q(t) = %s thousand people, t years after 2020, for %s." % [ft(s), gt(s), dom(s)]


static func pts_ans(ps: Array) -> Dictionary:
	var ans := Answer.make("pts", Answer.pts_of(ps.map(func(c): return [qf(c[0]), qf(c[1])])))
	ans.show = "sf"
	return ans


static func xs_ans(xs: Array) -> Dictionary:
	return GdcCurveViews.xs_ans(xs.map(func(x): return qf(x)))


static func num(x: float, label: String = "") -> Dictionary:
	return GdcCurveViews.num(x, label)


static func cross6(cs: Array) -> String:
	return Answer.xs_list(cs.map(func(c): return GdcKit.pt6(c[0], c[1]))).replace(" or ", " and ")


static func xs6(cs: Array) -> String:
	return Answer.xs_list(cs.map(func(c): return "x = " + W(c[0])))


## The crossings inside the standard window, −10 ≤ x, y ≤ 10.
static func in_window(cs: Array) -> Array:
	return cs.filter(func(c): return absf(c[0]) <= 10.0 and absf(c[1]) <= 10.0)


static func win(s: Dictionary) -> Array:
	var lo := GdcTwoCurvesSituation.lo_x(s)
	var hi: float = s.d2.to_float()
	var ys: Array = [0.0]
	for i in 33:
		var x := lo + (hi - lo) * i / 32.0
		ys.append(GdcTwoCurvesSituation.at(s.f, x))
		ys.append(GdcTwoCurvesSituation.at(s.g, x))
	var top: float = minf(ys.max(), ys.min() + 40.0)
	return GdcKit.window(s.d1.to_float(), hi, ys.min(), top)


static func win_step(s: Dictionary) -> String:
	var w := win(s)
	return "Graph y = %s and y = %s, with the window %s ≤ x ≤ %s and %s ≤ y ≤ %s." % [ft(s), gt(s), Fmt.num(w[0]), Fmt.num(w[1]),
		Fmt.num(w[2]), Fmt.num(w[3])]


## A GDC screen of both curves on the domain, crossings unmarked.
static func screen(s: Dictionary) -> Dictionary:
	var w := win(s)
	var lo := GdcTwoCurvesSituation.lo_x(s)
	var hi: float = s.d2.to_float()
	var f := func(x: float) -> float: return GdcTwoCurvesSituation.at(s.f, x)
	var g := func(x: float) -> float: return GdcTwoCurvesSituation.at(s.g, x)
	var vls: Array = [[s.d1.to_float(), ""]] if s.mode == "inverse" else []
	return Plot.spec([GdcKit.curve(f, lo, hi), GdcKit.curve(g, lo, hi)], [], w[0], w[1], w[2], w[3], [], vls)


static func diff_text(s: Dictionary) -> String:
	return "(%s) − (%s)" % [ft(s), gt(s)]


# ── fn-gdc-intersection ──────────────────────────────────────

func u_intersection_points(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var cs: Array = s.crossings
	var ans := pts_ans(cs)
	var final := "So the graphs meet at " + Answer.text(ans) + "."
	var only := Answer.pts_of(cs.map(func(c): return [qf(c[0]), qf(c[1])]))
	only.only_x = true
	var wrongs: Array = [wrong(only, IN + "#0")]
	var inside := in_window(cs)
	if inside.size() < cs.size() and not inside.is_empty():
		wrongs.append(wrong(Answer.pts_of(inside.map(func(c): return [qf(c[0]), qf(c[1])])), IN + "#1"))
	var gen: Array = [Answer.pts_of(cs.map(func(c): return [qf(c[1]), qf(c[0])])),
		Answer.pts_of(cs.map(func(c): return [qf(c[0]), qf(GdcTwoCurvesSituation.at(s.g, c[0]) + 1.0)])),
		Answer.pts_of(cs.map(func(c): return [qf(-c[0]), qf(c[1])]))]
	var out := {"asked": "Find the coordinates of every point where the graphs of f and g meet.", "lines": eq_lines(s), "answer": ans,
		"wrongs": wrongs, "generic": gen}
	if rep == "graph":
		out.lines = ["The graphs of " + eq_lines(s)[0] + " are shown."]
		out.graph = screen(s)
	var whole := "Set the x-window to the whole domain, %s, not the standard −10 to 10." % dom(s)
	out.methods = {"gdc-intersect": {"result": ans.values, "steps": [win_step(s), whole,
		"The intersect tool at each crossing gives %s; each y is from the unrounded x." % cross6(cs), final]}}
	return out


func u_solve_f_equals_g(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var cs: Array = s.crossings
	var ans := xs_ans(cs.map(func(c): return c[0]))
	var final := "So the solutions are " + Answer.text(ans) + "."
	var wrongs: Array = []
	var inside := in_window(cs)
	if inside.size() < cs.size() and not inside.is_empty():
		wrongs.append(wrong(Answer.xs_of(inside.map(func(c): return qf(c[0]))), SG + "#0"))
	var gen: Array = [Answer.xs_of(cs.map(func(c): return qf(c[1]))), Answer.xs_of(cs.map(func(c): return qf(-c[0]))),
		Answer.xs_of(cs.slice(1).map(func(c): return qf(c[0]))) if cs.size() > 1 else {"n": "1", "x0": qf(cs[0][0] + 1.0)}]
	var eq := "%s = %s" % [ft(s), gt(s)]
	var whole := "Use the whole domain, %s, not the standard window." % dom(s)
	return {
		"asked": "Solve %s, for %s." % [eq, dom(s)], "lines": [eq], "answer": ans, "wrongs": wrongs, "generic": gen,
		"methods": {
			"gdc-intersect": {"result": ans.values, "steps": [win_step(s), whole, "The intersect tool gives " + xs6(cs) + ".", final]},
			"zeros-of-difference": {"result": ans.values, "steps": ["Write it as one side equal to 0: %s = 0." % diff_text(s),
				"Graph the difference on %s and find its zeros: %s." % [dom(s), xs6(cs)], final]},
			"intersect-two-graphs": {"result": ans.values, "steps": [win_step(s), "They cross at " + xs6(cs) + ".", final]},
			"zero-of-difference": {"result": ans.values, "steps": ["The equation mixes families, so solve %s = 0 with the GDC's solver." % diff_text(s),
				"Over the whole domain it gives " + xs6(cs) + ".", final]},
		},
	}


func u_models_equal(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var cs: Array = s.crossings
	var c: Array = cs[0]
	var ctx: Dictionary = s.ctx
	var what: String = "the two tanks have the same depth" if ctx.kind == "tanks" else "the two towns have the same population"
	var a_eq := "%s(t) = %s(t): %s = %s" % [ctx.f, ctx.g, ft(s), gt(s)]
	if cs.size() > 1:
		# They meet twice: the second time is past the standard window's t = 10.
		var ans2 := Answer.make("xs", Answer.xs_of(cs.map(func(x): return qf(x[0]))), {"var": "t"})
		ans2.show = "sf"
		var final2 := "So %s when %s years." % [what, Answer.text(ans2)]
		var times := Answer.xs_list(cs.map(func(x): return "t = " + W(x[0])))
		return {
			"asked": "Find every time when %s." % what, "lines": [words(s)], "answer": ans2,
			"wrongs": [wrong(Answer.xs_of([qf(c[0])]), SG + "#0")],
			"generic": [Answer.xs_of(cs.map(func(x): return qf(x[1]))), Answer.xs_of([qf(cs[1][0])]),
				Answer.xs_of(cs.map(func(x): return qf(x[0] + 1.0)))],
			"methods": {
				"gdc-intersect": {"result": ans2.values, "steps": [a_eq + ".", "Graph both for the whole of %s, not just to t = 10." % dom(s),
					"The intersect tool gives " + times + ".", final2]},
				"zeros-of-difference": {"result": ans2.values, "steps": [a_eq + ", so %s = 0." % diff_text(s),
					"The GDC's solver on all of %s gives %s." % [dom(s), times], final2]},
				"intersect-two-graphs": {"result": ans2.values, "steps": ["Graph y = %s and y = %s for %s." % [ft(s), gt(s), dom(s)],
					"They cross twice: " + times + ".", final2]},
			},
		}
	var ans := num(c[0], "t = ")
	var final := "So %s when %s %s." % [what, Answer.text(ans), ctx.x_unit]
	var gen: Array = [{"v": qf(c[1])}, {"v": qf(c[0] + 1.0)}, {"v": qf(floorf(c[0]))}, {"v": qf(s.d2.to_float() - c[0])}]
	var out := {
		"asked": "Find when %s." % what, "lines": [words(s)], "answer": ans, "generic": gen,
		"methods": {
			"gdc-intersect": {"result": ans.values, "steps": [a_eq + ".", "Graph both for %s and use the intersect tool: t = %s." % [dom(s), W(c[0])], final]},
			"zeros-of-difference": {"result": ans.values, "steps": [a_eq + ", so %s = 0." % diff_text(s),
				"The GDC's solver on %s gives t = %s." % [dom(s), W(c[0])], final]},
			"intersect-two-graphs": {"result": ans.values, "steps": ["Graph y = %s and y = %s for %s." % [ft(s), gt(s), dom(s)],
				"They cross once, at t = %s." % W(c[0]), final]},
		},
	}
	# The time to 2 s.f. is the rounding trap, and its misconception (SL2.10.solve-gdc#1).
	out.trap_ref = SG + "#1"
	return out


func u_function_and_inverse(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var cs: Array = s.crossings
	var ans := pts_ans(cs)
	var final := "So f and f⁻¹ meet at " + Answer.text(ans) + "."
	var only := Answer.pts_of(cs.map(func(c): return [qf(c[0]), qf(c[1])]))
	only.only_x = true
	var gen: Array = [Answer.pts_of(cs.map(func(c): return [qf(c[0]), qf(-c[1])])),
		Answer.pts_of([[qf(cs[0][0]), qf(cs[0][1])]]), Answer.pts_of([[qf(cs[1][0]), qf(cs[1][1])]]),
		Answer.pts_of(cs.map(func(c): return [qf(c[0]), qf(GdcTwoCurvesSituation.at(s.f, c[0] + 1.0))]))]
	var out := {"asked": "Find the coordinates of the points where the graphs of f and f⁻¹ meet.", "lines": eq_lines(s), "answer": ans,
		"wrongs": [wrong(only, IN + "#0")], "generic": gen}
	if rep == "graph":
		out.lines = ["The graphs of " + eq_lines(s)[0] + " are shown."]
		out.graph = screen(s)
	var on_line := "f is increasing, so every crossing of f and f⁻¹ is on y = x: solve %s = x." % ft(s)
	out.methods = {
		"gdc-intersect": {"result": ans.values, "steps": [win_step(s), "The intersect tool gives %s." % cross6(cs), final]},
		"sketch-and-count": {"result": ans.values, "steps": [on_line,
			"A sketch of y = f(x) and y = x shows two crossings; the intersect tool gives %s." % cross6(cs), final]},
		"reflect-in-y-equals-x": {"result": ans.values, "steps": [
			"Reflecting in y = x shows where the graphs meet, but not the coordinates: this method fails for 3 s.f.",
			on_line + " The GDC gives " + cross6(cs) + ".", final]},
	}
	return out


func u_distance_between_crossings(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Array = s.crossings[0]
	var b: Array = s.crossings[1]
	var d := sqrt(pow(b[0] - a[0], 2) + pow(b[1] - a[1], 2))
	var ans := num(d)
	var final := "So the distance is " + Answer.text(ans) + "."
	var r := func(x: float) -> float: return float(Fmt.sf(x).replace("−", "-"))
	var rd := sqrt(pow(r.call(b[0]) - r.call(a[0]), 2) + pow(r.call(b[1]) - r.call(a[1]), 2))
	var gen: Array = [{"v": qf(absf(b[0] - a[0]))}, {"v": qf(absf(b[1] - a[1]))}, {"v": qf(absf(b[0] - a[0]) + absf(b[1] - a[1]))},
		{"v": qf(pow(b[0] - a[0], 2) + pow(b[1] - a[1], 2))}]
	return {
		"asked": "The graphs of f and g meet at A and B. Find the distance AB.", "lines": eq_lines(s), "answer": ans,
		"wrongs": [wrong({"v": qf(rd)}, IN + "#2")], "generic": gen,
		"methods": {"gdc-intersect": {"result": ans.values, "steps": [win_step(s),
			"Store the crossings: A%s and B%s." % [GdcKit.pt6(a[0], a[1]), GdcKit.pt6(b[0], b[1])],
			"AB = √((%s − %s)² + (%s − %s)²) = %s, from the stored values." % [W(b[0]), P(a[0]), W(b[1]), P(a[1]), W(d)], final]}},
	}


func u_count_crossings(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.crossings.size()
	var ans := Answer.make("number", {"v": Q.new(n)})
	ans.exact = true
	var inside: int = in_window(s.crossings).size()
	var final := "So the graphs meet %d time%s on the domain." % [n, "" if n == 1 else "s"]
	var out := {"asked": "How many times do the graphs of f and g meet on the domain?", "lines": eq_lines(s), "answer": ans,
		"wrongs": [wrong({"v": Q.new(inside)}, IN + "#1")] if inside != n else [],
		"generic": [{"v": Q.new(n + 1)}, {"v": Q.new(maxi(n - 1, 0))}, {"v": Q.new(n + 2)}, {"v": Q.new(0)}]}
	if rep == "graph":
		out.lines = ["The graphs of " + eq_lines(s)[0] + " are shown."]
		out.graph = screen(s)
	out.methods = {
		"zeros-of-difference": {"result": ans.values, "steps": ["The graphs meet where %s = 0." % diff_text(s),
			"Over the whole domain, %s, the difference has zeros at %s." % [dom(s), xs6(s.crossings)], final]},
		"sketch-and-count": {"result": ans.values, "steps": [win_step(s),
			"With the x-window over the whole domain, count the crossings: %s." % xs6(s.crossings), final]},
		"zero-of-difference": {"result": ans.values, "steps": ["Solve %s = 0 on the GDC over %s." % [diff_text(s), dom(s)],
			"It has %d solution%s: %s." % [n, "" if n == 1 else "s", xs6(s.crossings)], final]},
	}
	return out


func u_crossing_in_interval(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var cs: Array = s.crossings
	var i := rng.int_in(0, cs.size() - 1)
	var c: Array = cs[i]
	# Ends that hold this crossing only: whole numbers where they can, else halves.
	var prev: float = cs[i - 1][0] if i > 0 else -INF
	var next: float = cs[i + 1][0] if i < cs.size() - 1 else INF
	var ab := _ends(c[0], prev, next, 1.0, 0.1)
	if ab.is_empty():
		ab = _ends(c[0], prev, next, 0.5, 0.1)
	if ab.is_empty():
		# Crossings at least 0.5 apart always leave room on a grid of tenths.
		ab = _ends(c[0], prev, next, 0.1, 0.05)
	var a: Q = ab[0]
	var b: Q = ab[1]
	var ans := Answer.make("point", {"x": qf(c[0]), "y": qf(c[1])})
	ans.show = "sf"
	var final := "So the graphs meet at %s in that interval." % Answer.text(ans)
	var gen: Array = []
	for other in cs:
		if other != c:
			gen.append({"x": qf(other[0]), "y": qf(other[1])})
	gen.append_array([{"x": qf(c[1]), "y": qf(c[0])}, {"x": qf(c[0]), "y": qf(-c[1])}, {"x": qf(c[0]), "y": Q.new(0)}])
	return {
		"asked": "Find the coordinates of the point where the graphs of f and g meet for %s < x < %s." % [Fmt.dec(a), Fmt.dec(b)],
		"lines": eq_lines(s), "answer": ans, "generic": gen,
		"methods": {
			"gdc-intersect": {"result": ans.values, "steps": [win_step(s),
				"Move the cursor between x = %s and x = %s and use the intersect tool: %s." % [Fmt.dec(a), Fmt.dec(b), GdcKit.pt6(c[0], c[1])], final]},
			"intersect-two-graphs": {"result": ans.values, "steps": ["Graph y = %s and y = %s for %s ≤ x ≤ %s." % [ft(s), gt(s), Fmt.dec(a), Fmt.dec(b)],
				"They cross once there, at %s." % GdcKit.pt6(c[0], c[1]), final]},
		},
	}


## Ends on a grid of `unit` around x, at least 0.1 from it and clear of the crossings
## either side: [a, b] as Q, or [] if the grid can't.
static func _ends(x: float, prev: float, next: float, unit: float, gap: float) -> Array:
	var a := floorf((x - gap) / unit) * unit
	var b := ceilf((x + gap) / unit) * unit
	if a <= prev + gap or b >= next - gap:
		return []
	return [GdcTwoCurvesSituation.dq(a), GdcTwoCurvesSituation.dq(b)]


func u_crossing_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var tb: Dictionary = s.table
	var c: Array = s.crossings[s.crossings.size() - 1]
	var i := floori((c[0] - tb.xs[0].to_float()) / tb.step.to_float())
	var a: Q = tb.xs[i]
	var b: Q = tb.xs[i + 1]
	var ans := num(c[0], "x = ")
	var final := "So the largest crossing is at " + Answer.text(ans) + "."
	var gen: Array = [{"v": a}, {"v": b}, {"v": a.add(b).div(Q.new(2))}, {"v": qf(c[1])}]
	var rows := [["x", tb.xs.map(func(v): return Fmt.dec(v))], ["f(x)", tb.fs.map(func(v): return Fmt.sf(v))],
		["g(x)", tb.gs.map(func(v): return Fmt.sf(v))]]
	var sign := "f − g changes sign between x = %s and x = %s (f(%s) − g(%s) and f(%s) − g(%s) have opposite signs)." % [Fmt.dec(a), Fmt.dec(b),
		Fmt.dec(a), Fmt.dec(a), Fmt.dec(b), Fmt.dec(b)]
	return {
		"asked": "The table shows f(x) = %s and g(x) = %s, for %s. Find the interval holding the largest crossing of the graphs, then its x to 3 s.f." % [ft(s), gt(s), dom(s)],
		"lines": [], "table": {"rows": rows, "xs": tb.xs, "fs": tb.fs, "gs": tb.gs}, "answer": ans, "generic": gen,
		"methods": {"table-sign-change": {"result": ans.values, "steps": [sign,
			"Tabulate again from x = %s with a smaller step, and again, or use the intersect tool there: x = %s." % [Fmt.dec(a), W(c[0])], final]}},
	}


func u_constant_from_crossing(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: Q = s.g.c
	var m: Q = s.g.m
	var other: Array = s.crossings.filter(func(c): return absf(c[0]) > 1e-9)[0]
	var ans := Answer.make("named", {"v0": k, "v1": qf(other[0])}, {"names": ["k", "x"]})
	ans.show = "sf"
	var final := "So " + Answer.text(ans) + "."
	var line := "y = %s + k" % GdcKit.first(m, "x")
	var lines := ["The line %s meets the curve y = %s where x = 0." % [line, ft(s)]]
	if rep == "words":
		lines = ["A straight line with gradient %s passes through the point where the curve y = %s crosses the y-axis." % [Fmt.dec(m), ft(s)]]
	var gen: Array = [{"v0": k.neg(), "v1": qf(other[0])}, {"v0": k, "v1": qf(other[1])}, {"v0": m, "v1": qf(other[0])},
		{"v0": k, "v1": qf(-other[0])}]
	var sub := "At x = 0 the curve is at y = %s, so 0 + k = %s: k = %s." % [Fmt.dec(k), Fmt.dec(k), Fmt.dec(k)]
	return {
		"asked": "Find k, and the x-coordinate of the other point where the line meets the curve.", "lines": lines, "answer": ans, "generic": gen,
		"methods": {
			"gdc-intersect": {"result": ans.values, "steps": [sub,
				"Graph y = %s and y = %s; the intersect tool finds the other crossing at x = %s." % [ft(s), gt(s), W(other[0])], final]},
			"equate-and-solve": {"result": ans.values, "steps": [sub,
				"Then %s = %s mixes families, so the GDC solves it: x = 0 or x = %s." % [ft(s), gt(s), W(other[0])], final]},
		},
	}


# ── fn-concept-solutions-as-intersections ────────────────────

func u_graphs_for_equation(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var eq := "%s = %s" % [ft(s), gt(s)]
	var right := "Graph y = %s and y = %s, and read the x-coordinates where they meet." % [ft(s), gt(s)]
	var out := LogFunctionViews.choice(right, [], ["Graph y = %s and y = %s, and read the y-coordinates where they meet." % [ft(s), gt(s)],
		"Graph y = %s only, and read where it crosses the x-axis." % ft(s),
		"Graph y = %s − %s, and read where it crosses y = 1." % [ft(s), gt(s)]])
	var final: String = "So: " + right
	out.merge({
		"asked": "To solve %s with a GDC, which graphs do you draw, and what do you read off?" % eq, "lines": [eq],
		"methods": {
			"sketch-and-count": {"result": out.answer.values, "steps": ["Each side of the equation is a function of x: graph each one.",
				"A solution is an x where both sides are equal: an x-coordinate where the graphs meet.", final]},
			"intersect-two-graphs": {"result": out.answer.values, "steps": ["Graph both sides, then use intersect at each crossing.",
				"The solutions are the x-values it gives: %s." % xs6(s.crossings), final]},
		}})
	return out


func u_count_from_sketch(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int
	var wrongs: Array = []
	var lines: Array
	var asked: String
	var steps: Array
	if s.mode == "turns":
		var k: Q = s.g.c
		var top: Q = s.top
		var bottom: Q = s.bottom
		n = 1
		if k.to_float() < top.to_float() and k.to_float() > bottom.to_float():
			n = 3
		elif k.eq(top) or k.eq(bottom):
			n = 2
			wrongs.append(wrong({"v": Q.new(3)}, NS + "#0"))
		lines = ["The sketch shows y = %s, with turning points (%s, %s) and (%s, %s)." % [ft(s), N(s.p.neg()), N(_at_q(s, s.p.neg())),
			N(s.p), N(_at_q(s, s.p))]]
		asked = "How many solutions does %s = %s have?" % [ft(s), N(k)]
		steps = ["Draw the horizontal line y = %s across the sketch." % N(k),
			"It meets the curve %d time%s%s." % [n, "" if n == 1 else "s", ": it only touches at the turning point, which is one solution" if n == 2 else ""]]
	else:
		n = s.crossings.size()
		var inside := in_window(s.crossings).size()
		if inside != n:
			wrongs.append(wrong({"v": Q.new(inside)}, SG + "#0"))
		lines = ["The sketch shows y = %s and y = %s for %s." % [ft(s), gt(s), dom(s)]]
		asked = "How many solutions does %s = %s have for %s?" % [ft(s), gt(s), dom(s)]
		steps = ["Count every crossing over the whole domain, not just the standard window.", "They cross at " + xs6(s.crossings) + "."]
	var ans := Answer.make("number", {"v": Q.new(n)})
	ans.exact = true
	var final := "So there %s %d solution%s." % ["is" if n == 1 else "are", n, "" if n == 1 else "s"]
	return {
		"asked": asked, "lines": lines, "graph": _sketch(s), "answer": ans, "wrongs": wrongs,
		"generic": [{"v": Q.new(n + 1)}, {"v": Q.new(maxi(n - 1, 0))}, {"v": Q.new(n + 2)}, {"v": Q.new(0)}],
		"methods": {
			"sketch-and-count": {"result": ans.values, "steps": steps + [final]},
			"horizontal-line-sweep": {"result": ans.values, "steps": steps + [final]},
			"gdc-graph": {"result": ans.values, "steps": ["Graph both sides on the GDC with a window wide enough to see every crossing."] + steps.slice(1) + [final]},
		},
	}


## f at a whole-number x, exactly: the turns mode's turning values.
static func _at_q(s: Dictionary, x: Q) -> Q:
	return s.f.A.mul(x).mul(x).mul(x).add(s.f.m.mul(x)).add(s.f.c)


static func N(v: Variant) -> String:
	return Fmt.num(v)


## The sketch: both curves (the turns mode's cubic with its turning points marked).
static func _sketch(s: Dictionary) -> Dictionary:
	if s.mode != "turns":
		return screen(s)
	var p: float = s.p.to_float()
	var f := func(x: float) -> float: return GdcTwoCurvesSituation.at(s.f, x)
	var top: float = s.top.to_float()
	var bottom: float = s.bottom.to_float()
	var k: float = s.g.c.to_float()
	var w := GdcKit.window(-2.2 * p, 2.2 * p, minf(bottom, k) - 1.0, maxf(top, k) + 1.0, 0.0, 0.1)
	var pts := [[-p, f.call(-p), "(%s, %s)" % [N(s.p.neg()), N(_at_q(s, s.p.neg()))]], [p, f.call(p), "(%s, %s)" % [N(s.p), N(_at_q(s, s.p))]]]
	return Plot.spec([GdcKit.curve(f, -2.2 * p, 2.2 * p)], pts, w[0], w[1], w[2], w[3], [[k, "y = " + N(s.g.c)]])


func u_x_not_y(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var cs: Array = s.crossings
	var xs := "x = %s and x = %s" % [S(cs[0][0]), S(cs[1][0])]
	var pts := "(%s, %s) and (%s, %s)" % [S(cs[0][0]), S(cs[0][1]), S(cs[1][0]), S(cs[1][1])]
	var ys := "y = %s and y = %s" % [S(cs[0][1]), S(cs[1][1])]
	var out := LogFunctionViews.choice(xs, [wrong({"v": pts}, IN + "#0"), wrong({"v": ys}, IN + "#0")],
		["x = %s and x = %s" % [S(cs[0][1]), S(cs[1][1])]])
	var final: String = "So the solutions are " + xs + "."
	var lines := ["The graphs of y = %s and y = %s meet at %s." % [ft(s), gt(s), pts]]
	if rep == "words":
		lines = ["A student graphs y = %s and y = %s; the GDC shows they meet at %s." % [ft(s), gt(s), pts]]
	out.merge({
		"asked": "What are the solutions of %s = %s?" % [ft(s), gt(s)], "lines": lines, "graph": screen(s) if rep == "graph" else null,
		"methods": {
			"sketch-and-count": {"result": out.answer.values, "steps": ["An equation in x has values of x as its solutions.",
				"At each meeting point both sides are equal, so its x-coordinate solves it.", final]},
			"intersect-two-graphs": {"result": out.answer.values, "steps": ["The intersect tool gives the points %s." % pts,
				"Only the x-coordinates answer an equation in x.", final]},
		}})
	return out


func u_difference_picture(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var lo := GdcTwoCurvesSituation.lo_x(s)
	var hi: float = s.d2.to_float()
	var f := func(x: float) -> float: return GdcTwoCurvesSituation.at(s.f, x)
	var g := func(x: float) -> float: return GdcTwoCurvesSituation.at(s.g, x)
	var d := func(x: float) -> float: return f.call(x) - g.call(x)
	var su := func(x: float) -> float: return f.call(x) + g.call(x)
	var up := func(x: float) -> float: return f.call(x) - g.call(x) + 2.0
	var ys: Array = [0.0]
	for i in 33:
		var x := lo + (hi - lo) * i / 32.0
		ys.append(d.call(x))
	var w := GdcKit.window(lo, hi, ys.min(), ys.max())
	var cd := func(fn: Callable) -> Dictionary: return GdcKit.card([GdcKit.curve(fn, lo, hi)], [], w)
	var p := GdcKit.pick(cd.call(d), [
		{"graph": cd.call(su), "ref": "", "mistake": "sum", "why": "it is f + g, whose zeros are not where f and g meet"},
		{"graph": cd.call(up), "ref": "", "mistake": "lifted", "why": "it is f − g + 2: its zeros moved off the meeting points"},
		{"graph": cd.call(f), "ref": "", "mistake": "f-alone", "why": "it is f alone: its zeros are where f = 0, not where f = g"},
	], rng)
	var final: String = "So the graph of y = f(x) − g(x) is %s: it crosses the x-axis at %s." % [p.answer.values.v, xs6(s.crossings)]
	return {
		"asked": "The graphs of y = f(x) and y = g(x) are shown. Which graph is y = f(x) − g(x)?",
		"lines": ["f(x) = %s and g(x) = %s, for %s" % [ft(s), gt(s), dom(s)]], "graph": screen(s), "answer": p.answer, "graphs": p.graphs,
		"methods": {
			"zeros-of-difference": {"result": p.answer.values, "steps": ["f(x) − g(x) = 0 exactly where f(x) = g(x).",
				"So its graph crosses the x-axis at the meeting x-values, %s." % xs6(s.crossings), final]},
			"zero-of-difference": {"result": p.answer.values, "steps": ["Subtract the heights at each x: where f is above g, f − g is positive.",
				"Its zeros are the meeting x-values.", final]},
		},
	}


func u_same_solutions_after_rearranging(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := "%s = %s" % [ft(s), gt(s)]
	var b := "%s − (%s) = 0" % [ft(s), gt(s)]
	var right := "Yes: B is A with %s taken from both sides, so they have the same solutions." % gt(s)
	var out := LogFunctionViews.choice(right, [], ["No: B's solutions are where the graph of the difference meets y = %s." % gt(s),
		"No: rearranging an equation changes its solutions.", "Yes, but only when both sides are lines."])
	var final: String = "So: " + right
	var lines := ["Equation A: %s.  Equation B: %s." % [a, b]]
	if rep == "words":
		lines = ["A student says: \"Solving %s is the same as finding the zeros of y = %s − (%s).\"" % [a, ft(s), gt(s)]]
	out.merge({
		"asked": "Do equations A and B have the same solutions?" if rep == "equation" else "Is the student right?", "lines": lines,
		"methods": {
			"zeros-of-difference": {"result": out.answer.values, "steps": ["Subtracting the same thing from both sides keeps every solution and adds none.",
				"So the zeros of the difference are the meeting x-values: %s." % xs6(s.crossings), final]},
			"zero-of-difference": {"result": out.answer.values, "steps": ["Graph y = %s − (%s): it crosses the x-axis at %s." % [ft(s), gt(s), xs6(s.crossings)],
				"Those are where the two graphs of A meet.", final]},
		}})
	return out


func u_k_for_count(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var top: Q = s.top
	var bottom: Q = s.bottom
	var ans := Answer.make("range2", {"lo": bottom, "r1": "<", "r2": "<", "hi": top}, {"var": "k"})
	ans.exact = true
	var final := "So f(x) = k has three solutions for " + Answer.text(ans) + "."
	return {
		"asked": "For which values of k does %s = k have exactly three solutions?" % ft(s),
		"lines": ["The sketch shows y = %s, with turning points (%s, %s) and (%s, %s)." % [ft(s), N(s.p.neg()), N(_at_q(s, s.p.neg())),
			N(s.p), N(_at_q(s, s.p))]], "graph": _sketch(s), "answer": ans,
		"wrongs": [wrong({"lo": bottom, "r1": "≤", "r2": "≤", "hi": top}, NS + "#0")],
		"generic": [{"lo": bottom, "r1": "<", "r2": "≤", "hi": top}, {"lo": s.p.neg(), "r1": "<", "r2": "<", "hi": s.p},
			{"lo": bottom.sub(Q.new(1)), "r1": "<", "r2": "<", "hi": top.add(Q.new(1))}],
		"methods": {
			"horizontal-line-sweep": {"result": ans.values, "steps": ["Slide a line y = k up the sketch and count where it meets the curve.",
				"Between the turning values %s and %s it meets it three times; at either one it only touches there, so twice." % [N(bottom), N(top)], final]},
			"turning-point-boundaries": {"result": ans.values, "steps": ["The count changes only at the turning values, %s and %s." % [N(bottom), N(top)],
				"Strictly between them there are three solutions; at them, two.", final]},
		},
	}
