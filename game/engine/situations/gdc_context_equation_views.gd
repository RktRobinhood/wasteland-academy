class_name GdcContextEquationViews
extends RefCounted
## The views on the `gdc-context-equation` situation: one builder per unknown of
## fn-gdc-solve-equation (FAL-420). Builders return what QuadraticViews' builders
## return (see quadratic_views.gd). Paper 2: every root from the GDC to 3 s.f.

const NEED := {
	"solve-mixed-equation": {"form": "mixed"},
	"form-and-solve": {"form": "sector"},
	"root-in-interval": {"form": "expline", "neg": true},
	"simultaneous-nonlinear": {"form": "simul"},
	"first-time": {"form": "height"},
	"count-roots": {"form": "expline", "far_ok": true},
	"constant-from-root": {"form": "ksin", "root0": true},
	"smallest-whole-number": {"form": "savings"},
	"reject-a-root": {"form": "expline", "neg": true},
}

const SG := "SL2.10.solve-gdc"
const CA := "SL2.10.context-apply"


func has(unknown: String) -> bool:
	return NEED.has(unknown)


func need(unknown: String, rep: String) -> Dictionary:
	var n: Dictionary = NEED[unknown].duplicate()
	if unknown == "smallest-whole-number" and rep == "table":
		n.table = true
	return n


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "wrongs", "generic"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "generic"] else null
	out.given = GdcContextEquationSituation.export(s)
	if not out.has("trap"):
		out.trap = GdcCurveViews.trap(out.answer)
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


static func D(q: Q) -> String:
	return Fmt.dec(q)


static func wrong(values: Dictionary, ref: String = "") -> Dictionary:
	return {"values": values, "ref": ref}


static func num(x: float, label: String = "x = ") -> Dictionary:
	return GdcCurveViews.num(x, label)


## The equation as written, in x or t: "x = 2.5sin x", "e^(0.5x) = 2x + 3".
static func eq(s: Dictionary, v: String = "x") -> String:
	var n: Array = s.nums
	var out: String
	match s.form:
		"ksin":
			out = "x = %ssin x" % D(n[0])
		"sector":
			return "%s(θ − sin θ) = %s" % [Fmt.dec(n[0].mul(n[0]).div(Q.new(2))), D(n[1])]
		"expline":
			out = "e^(%sx) = %s" % [GdcKit.lead(n[0]), GdcKit.first(n[1], "x") + GdcKit.join(n[2], "")]
		"height":
			out = "%sxe^(−%sx) = %s" % [Fmt.num(n[0]), GdcKit.lead(n[1]), D(n[2])]
		"simul":
			out = "e^(%sx)%s = %s − x²" % [GdcKit.lead(n[0]), GdcKit.join(n[1], ""), Fmt.num(n[2])]
	return out.replace("x", v) if v != "x" else out


static func roots6(rs: Array, v: String = "x") -> String:
	return Answer.xs_list(rs.map(func(r): return "%s = %s" % [v, W(r)]))


static func screen(s: Dictionary, lo: float, hi: float) -> Dictionary:
	var f := func(x: float) -> float: return GdcContextEquationSituation.h(s, x)
	var ys: Array = [0.0]
	for i in 33:
		ys.append(f.call(lo + (hi - lo) * i / 32.0))
	var w := GdcKit.window(lo, hi, maxf(ys.min(), -15.0), minf(ys.max(), 15.0))
	return Plot.spec([GdcKit.curve(f, lo, hi)], [], w[0], w[1], w[2], w[3])


static func both_sides(s: Dictionary, v: String = "x") -> String:
	var parts := eq(s, v).split(" = ")
	return "Graph y = %s and y = %s" % [parts[0], parts[1]]


# ── fn-gdc-solve-equation ────────────────────────────────────

func u_solve_mixed_equation(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.want
	var ans := num(x)
	var final := "So " + Answer.text(ans) + "."
	var rs: Array = s.roots
	var asked: String
	var wrongs: Array = []
	var gen: Array = [{"v": qf(-x)}, {"v": qf(x / 2.0)}]
	if s.form == "ksin":
		asked = "Find the positive solution of %s." % eq(s)
		gen.append({"v": qf(GdcContextEquationSituation.k_of(s))})
	else:
		asked = "Find the largest solution of %s." % eq(s)
		wrongs.append(wrong({"v": qf(rs[0])}, SG + "#0"))
		gen.append({"v": qf(rs[0] + 1.0)})
	var lo := -3.0 if s.form == "ksin" else -5.0
	var hi := 4.0 if s.form == "ksin" else 20.0
	var win := "with the x-window from %s to %s, so no solution is off screen" % [Fmt.num(roundi(lo)), Fmt.num(roundi(hi))]
	return {
		"asked": asked, "lines": [eq(s)], "answer": ans, "wrongs": wrongs, "generic": gen,
		"methods": {
			"intersect-two-graphs": {"result": ans.values, "steps": ["%s, %s." % [both_sides(s), win],
				"They cross at " + roots6(rs) + ".", final]},
			"zero-of-difference": {"result": ans.values, "steps": [
				"The equation mixes families, so rearrange it to one side equal to 0 and use the GDC's solver.",
				"Over a wide window, %s, the zeros are %s." % [win.trim_prefix("with "), roots6(rs)], final]},
		},
	}


func u_form_and_solve(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: Q = s.nums[0]
	var area: Q = s.nums[1]
	var th: float = s.want
	var arc: float = r.to_float() * th
	var ans := Answer.make("number", {"v": qf(arc)}, {}, "", " cm")
	ans.show = "sf"
	var final := "So the arc is " + Answer.text(ans) + " long."
	var th2 := float(Fmt.sf(th, 2).replace("−", "-"))
	var gen: Array = [{"v": qf(th)}, {"v": qf(r.to_float() * th / 2.0)}, {"v": qf(r.to_float() * (th - sin(th)))}]
	var e := eq(s)
	return {
		"asked": "A chord cuts off a segment of a circle of radius %s cm. The segment's area is %s cm², and the angle at the centre is θ radians. Find the length of the segment's arc." % [Fmt.num(r), D(area)],
		"lines": ["Circle radius %s cm, segment area %s cm²." % [Fmt.num(r), D(area)]], "answer": ans,
		"wrongs": [wrong({"v": qf(r.to_float() * th2)}, SG + "#1")], "generic": gen,
		"methods": {
			"intersect-two-graphs": {"result": ans.values, "steps": [
				"Segment area = sector − triangle = ½r²θ − ½r² sin θ, so %s." % e,
				"Graph y = %s(θ − sin θ) and y = %s: they cross at θ = %s." % [Fmt.dec(r.mul(r).div(Q.new(2))), D(area), W(th)],
				"Arc = rθ = %s × %s = %s, from the unrounded θ." % [Fmt.num(r), W(th), W(arc)], final]},
			"gdc-intersect": {"result": ans.values, "steps": [
				"½r²(θ − sin θ) = %s gives %s." % [D(area), e],
				"The intersect tool gives θ = %s (between 0 and π)." % W(th),
				"Arc = rθ = %s, from the stored θ." % W(arc), final]},
		},
	}


func u_root_in_interval(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rs: Array = s.roots
	var v := "t" if rep == "words" else "x"
	var ans := num(s.want, v + " = ")
	var final := "So " + Answer.text(ans) + "."
	var lines := [eq(s)]
	var asked := "Solve %s for x > 0." % eq(s)
	if rep == "words":
		lines = ["Two quantities are modelled by e^(%st) and %s, where t is the time in hours since noon." % [GdcKit.lead(s.nums[0]),
			GdcKit.first(s.nums[1], "t") + GdcKit.join(s.nums[2], "")]]
		asked = "Find the time after noon when the two quantities are equal."
	var gen: Array = [{"v": qf(-s.want)}, {"v": qf(s.want + 1.0)}, {"v": qf(rs[0] + rs[1])}]
	var keep := "Only %s = %s is in %s > 0; %s = %s is not." % [v, W(s.want), v, v, W(rs[0])]
	return {
		"asked": asked, "lines": lines, "answer": ans, "wrongs": [wrong({"v": qf(rs[0])}, CA + "#1")], "generic": gen,
		"methods": {
			"intersect-two-graphs": {"result": ans.values, "steps": ["%s and find where they cross." % both_sides(s, v),
				"They cross at " + roots6(rs, v) + ".", keep, final]},
			"zero-of-difference": {"result": ans.values, "steps": ["Solve %s = 0 on the GDC." % ("e^(%s%s) − (%s)" % [GdcKit.lead(s.nums[0]), v,
				GdcKit.first(s.nums[1], v) + GdcKit.join(s.nums[2], "")]), "Its zeros are " + roots6(rs, v) + ".", keep, final]},
			"gdc-intersect": {"result": ans.values, "steps": ["%s; the intersect tool finds %s." % [both_sides(s, v), roots6(rs, v)], keep, final]},
		},
	}


func u_simultaneous_nonlinear(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.want
	var y: float = s.y
	var ans := num(y, "y = ")
	var final := "So " + Answer.text(ans) + "."
	var x2 := float(Fmt.sf(x, 2).replace("−", "-"))
	var p: float = s.co[2]
	var parts := eq(s).split(" = ")
	var gen: Array = [{"v": qf(x)}, {"v": qf(-y)}, {"v": qf(p - x)}, {"v": qf(s.roots[0])}]
	return {
		"asked": "Solve the simultaneous equations y = %s and y = %s, for x > 0. Find the value of y." % [parts[0], parts[1]],
		"lines": ["y = %s" % parts[0], "y = %s" % parts[1]], "answer": ans,
		"wrongs": [wrong({"v": qf(p - x2 * x2)}, SG + "#1")], "generic": gen,
		"methods": {"intersect-two-graphs": {"result": ans.values, "steps": [
			"Graph y = %s and y = %s: they cross once with x > 0." % [parts[0], parts[1]],
			"The intersect tool gives (%s, %s); y comes from the unrounded x." % [W(x), W(y)], final]}},
	}


func u_first_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rs: Array = s.roots
	var ans := num(s.want, "t = ")
	var c: Q = s.nums[2]
	var final := "So the first time is " + Answer.text(ans) + "."
	var tmax: float = 1.0 / s.co[1]
	var out := {"asked": "The height of a ball, in metres, t seconds after it is hit is h(t) = %s. Find the first time it is %s m high." % [
			eq(s, "t").split(" = ")[0], D(c)], "lines": ["h(t) = %s, for t ≥ 0" % eq(s, "t").split(" = ")[0]], "answer": ans,
		"wrongs": [wrong({"v": c}, CA + "#2")], "generic": [{"v": qf(rs[1])}, {"v": qf(tmax)}, {"v": qf(rs[0] + rs[1])}]}
	if rep == "graph":
		out.lines = ["The graph of h(t) = %s, for t ≥ 0, is shown." % eq(s, "t").split(" = ")[0]]
		var f := func(x: float) -> float: return s.co[0] * x * exp(-s.co[1] * x)
		var top: float = f.call(tmax)
		var hi := ceilf(rs[1] + 1.0)
		out.graph = Plot.spec([GdcKit.curve(f, 0.0, hi)], [], -1, int(hi) + 1, -1, ceili(top) + 1)
	var two := "h(t) = %s twice, at %s; the first is the smaller." % [D(c), roots6(rs, "t")]
	out.methods = {
		"zero-of-difference": {"result": ans.values, "steps": ["Solve %s − %s = 0 on the GDC." % [eq(s, "t").split(" = ")[0], D(c)], two, final]},
		"gdc-intersect": {"result": ans.values, "steps": ["Graph y = h(t) and y = %s for t ≥ 0." % D(c), two, final]},
	}
	return out


func u_count_roots(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rs: Array = s.roots
	var n := rs.size()
	var ans := Answer.make("number", {"v": Q.new(n)})
	ans.exact = true
	var inside: int = rs.filter(func(x): return absf(x) <= 10.0).size()
	var final := "So %s has %d solution%s for −20 ≤ x ≤ 20." % [eq(s), n, "" if n == 1 else "s"]
	var out := {"asked": "How many solutions does %s have for −20 ≤ x ≤ 20?" % eq(s), "lines": [eq(s)], "answer": ans,
		"wrongs": [wrong({"v": Q.new(inside)}, SG + "#0")] if inside != n else [],
		"generic": [{"v": Q.new(n + 1)}, {"v": Q.new(maxi(n - 1, 0))}, {"v": Q.new(n + 2)}, {"v": Q.new(0)}]}
	if rep == "graph":
		out.lines = ["The graph of y = %s − (%s) is shown, for −20 ≤ x ≤ 20." % [eq(s).split(" = ")[0], eq(s).split(" = ")[1]]]
		out.graph = screen(s, -20.0, 20.0)
	var all := "Over the whole of −20 ≤ x ≤ 20, not just the standard window, the solutions are " + roots6(rs) + "."
	out.methods = {
		"intersect-two-graphs": {"result": ans.values, "steps": [both_sides(s) + ".", all, final]},
		"zero-of-difference": {"result": ans.values, "steps": ["Rearrange to one side equal to 0 and graph it.", all, final]},
		"table-sign-change": {"result": ans.values, "steps": ["Tabulate the difference of the two sides from −20 to 20 in steps of 1.",
			"It changes sign %d time%s." % [n, "" if n == 1 else "s"], final]},
		"graph-check": {"result": ans.values, "steps": ["Graph both sides with a window wide enough for every crossing: an exponential overtakes a line far out.",
			all, final]},
	}
	return out


func u_constant_from_root(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x0: Q = s.x0
	var k := GdcContextEquationSituation.k_of(s)
	var ans := num(k, "k = ")
	var final := "So " + Answer.text(ans) + "."
	var lines := ["x = k sin x has a solution x = %s." % D(x0)]
	if rep == "words":
		lines = ["The line y = x/k meets the curve y = sin x where x = %s." % D(x0)]
	var xf := x0.to_float()
	return {
		"asked": "Find the value of k.", "lines": lines, "answer": ans,
		"generic": [{"v": qf(sin(xf) / xf)}, {"v": qf(xf * sin(xf))}, {"v": qf(xf / sin(deg_to_rad(xf)))}, {"v": qf(asin(minf(1.0, 1.0 / xf)))}],
		"methods": {"apply-inverse": {"result": ans.values, "steps": [
			"Substitute x = %s: %s = k sin %s." % [D(x0), D(x0), D(x0)],
			"So k = %s ÷ sin %s, with the calculator in radians: %s." % [D(x0), D(x0), W(k)], final]}},
	}


func u_smallest_whole_number(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p0: Q = s.nums[0]
	var rate: Q = s.nums[1]
	var target: Q = s.nums[2]
	var n_real: float = s.want
	var n := ceili(n_real)
	var ans := Answer.make("number", {"v": Q.new(n)}, {}, "n = ")
	ans.exact = true
	var final := "So the smallest whole number of years is " + Answer.text(ans) + "."
	var words := "$%s is invested at %s%% a year, compounded yearly. After n whole years it is worth %s(1.%s)ⁿ dollars." % [Fmt.num(p0), D(rate),
		Fmt.num(p0), _pct_digits(rate)]
	var out := {"asked": "Find the smallest whole number of years after which the investment is worth more than $%s." % Fmt.num(target),
		"lines": [words], "answer": ans, "wrongs": [wrong({"v": Q.new(floori(n_real))}, CA + "#0")],
		"generic": [{"v": Q.new(n + 1)}, {"v": Q.new(roundi(target.to_float() / p0.to_float()))}, {"v": Q.new(maxi(n - 2, 1))}]}
	if rep == "table":
		var tb: Dictionary = s.table
		out.table = {"heads": ["n", "value ($)"], "xs": tb.xs, "ys": tb.ys,
			"rows": [["n", tb.xs.map(func(v): return Fmt.num(v))], ["value ($)", tb.ys.map(func(v): return Fmt.money(v))]]}
	var m := "1.%s" % _pct_digits(rate)
	out.methods = {
		"table-sign-change": {"result": ans.values, "steps": ["Tabulate %s(%s)ⁿ at whole n." % [Fmt.num(p0), m],
			"It is below $%s at n = %d and above it at n = %d." % [Fmt.num(target), n - 1, n], final]},
		"analytic-logs": {"result": ans.values, "steps": ["%s(%s)ⁿ > %s, so n > ln(%s/%s) ÷ ln %s = %s." % [Fmt.num(p0), m, Fmt.num(target),
			Fmt.num(target), Fmt.num(p0), m, W(n_real)], "n must be a whole number past that, so round up, not down.", final]},
		"table-search": {"result": ans.values, "steps": ["Use the GDC's table of %s(%s)^x and scroll to where it passes %s." % [Fmt.num(p0), m, Fmt.num(target)],
			"The first whole year above $%s is %d." % [Fmt.num(target), n], final]},
	}
	return out


## The multiplier's digits after "1.": 3.5% gives "035", 4% "04".
static func _pct_digits(rate: Q) -> String:
	var m := Q.new(1).add(rate.div(Q.new(100)))
	return Fmt.dec(m).trim_prefix("1.")


func u_reject_a_root(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rs: Array = s.roots
	var good := "t = %s: the other solution, t = %s, is before noon (t < 0)." % [S(s.want), S(rs[0])]
	var out := LogFunctionViews.choice(good, [wrong({"v": "t = %s: it is the first solution the GDC finds." % S(rs[0])}, CA + "#1")],
		["Both, t = %s and t = %s: each solves the equation." % [S(rs[0]), S(s.want)],
		"t = %s: the other solution makes %s negative." % [S(s.want), GdcKit.first(s.nums[1], "t") + GdcKit.join(s.nums[2], "")]])
	var final: String = "So " + good
	out.merge({
		"asked": "The GDC gives two solutions of %s. Which one says when the two quantities are equal, and why?" % eq(s, "t"),
		"lines": ["Two quantities are modelled by e^(%st) and %s, where t is the time in hours since noon, t ≥ 0." % [GdcKit.lead(s.nums[0]),
			GdcKit.first(s.nums[1], "t") + GdcKit.join(s.nums[2], "")]],
		"methods": {
			"gdc-intersect": {"result": out.answer.values, "steps": ["%s: they cross at %s." % [both_sides(s, "t"), roots6(rs, "t")],
				"The context allows only t ≥ 0.", final]},
			"graph-check": {"result": out.answer.values, "steps": ["Graph both sides over a wide window: two crossings, %s." % roots6(rs, "t"),
				"One is at a negative time, before the model starts.", final]},
		}})
	return out
