class_name LogQuadraticViews
extends RefCounted
## The views on the `log-quadratic` situation: one builder per unknown of
## fn-log-of-quadratic (FAL-418). Builders return what QuadraticViews' builders return
## (see quadratic_views.gd). Paper 1: every answer is exact.

const NEED := {
	"argument-roots": {},
	"domain-from-inequality": {},
	"asymptotes": {},
	"zeros": {},
	"max-value": {},
	"base-from-max": {},
	"range": {},
	"axis-of-graph": {"h_not_0": true},
	"y-intercept": {"straddle": true},
	"sign-of-f": {},
	"quadratic-from-features": {},
}


func has(unknown: String) -> bool:
	return NEED.has(unknown)


func need(unknown: String, _rep: String) -> Dictionary:
	return NEED[unknown].duplicate()


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "wrongs", "generic"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "generic"] else null
	out.given = LogQuadraticSituation.export(s)
	out.trap = {}
	out.asked = ExpLogPairViews.M(out.asked)
	out.lines = out.lines.map(func(l): return ExpLogPairViews.M(l))
	for a in out.methods:
		out.methods[a].steps = out.methods[a].steps.map(func(l): return ExpLogPairViews.M(l))
	return out


# ── Helpers ──────────────────────────────────────────────────

static func N(v: Variant) -> String:
	return Fmt.num(v)


static func wrong(values: Dictionary, ref: String = "") -> Dictionary:
	return {"values": values, "ref": ref}


static func LG(s: Dictionary) -> String:
	return Answer.log_name(s.base)


static func g_text(s: Dictionary) -> String:
	return Fmt.poly([s.a, s.b, s.c])


static func g_factored(s: Dictionary) -> String:
	return Fmt.factorised(s.a, s.p, s.q)


## f as written: "f(x) = log₃(−x² + 4x + 5)".
static func f_line(s: Dictionary) -> String:
	return "f(x) = %s(%s)" % [LG(s), g_text(s)]


## One zero, h − zm√zr or h + zm√zr, as written: "3 − 2√2", "√3".
static func zero_text(s: Dictionary, sign: int) -> String:
	var root := Answer.surd_text(s.zm, s.zr)
	if s.h.is_zero():
		return ("−" if sign < 0 else "") + root
	return "%s %s %s" % [N(s.h), "−" if sign < 0 else "+", root]


static func f_graph(s: Dictionary, points: Array) -> Dictionary:
	var f := func(x: float) -> float: return LogQuadraticSituation.f_at(s, x)
	var p: int = s.p.n
	var q: int = s.q.n
	var n: int = s.n
	return Plot.spec([Plot.sample(f, p + 0.0005, q - 0.0005)], points, p - 1, q + 1, -6, n + 2, [],
		[[float(p), "x = %s" % N(p)], [float(q), "x = %s" % N(q)]])


## The lines for a view: f and g, or (graph) the graph of f with its asymptotes.
static func show(rep: String, s: Dictionary, points: Array = []) -> Dictionary:
	if rep == "graph":
		return {"lines": ["The graph of y = f(x) is shown, where " + f_line(s) + "."], "graph": f_graph(s, points)}
	return {"lines": [f_line(s) + ", where it is defined."]}


# ── fn-log-of-quadratic ──────────────────────────────────────

func u_argument_roots(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("roots", {"r1": s.p, "r2": s.q})
	ans.exact = true
	var final := "So " + Answer.text(ans) + "."
	var bb: Q = s.b
	var disc: Q = s.disc
	return {
		"asked": "Solve g(x) = 0, where g(x) = %s is the quadratic inside the log." % g_text(s), "lines": [f_line(s)], "answer": ans,
		"generic": [{"r1": s.p.neg(), "r2": s.q.neg()}, {"r1": s.p, "r2": s.q.add(Q.new(1))}, {"r1": s.h, "r2": s.q}, {"r1": s.p.sub(Q.new(1)), "r2": s.q}],
		"methods": {
			"factorise": {"result": ans.values, "steps": ["%s = %s" % [g_text(s), g_factored(s)], "Each factor can be 0: x = %s or x = %s." % [N(s.p), N(s.q)], final]},
			"quadratic-formula": {"result": ans.values, "steps": [
				"Δ = (%s)² − 4(%s)(%s) = %s" % [N(bb), N(s.a), N(s.c), N(disc)],
				"x = (%s ± √%s)/(2 × %s)" % [N(bb.neg()), N(disc), Fmt.paren(s.a)], final]},
		},
	}


func u_domain_from_inequality(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("interval", {"shape": "between", "lo": s.p, "hi": s.q, "ends": "left out"}, {"var": "x"})
	ans.exact = true
	var out := show(rep, s)
	var final := "So the domain is " + Answer.text(ans) + "."
	var roots := "g(x) = %s = 0 at x = %s and x = %s." % [g_text(s), N(s.p), N(s.q)]
	var down := "g opens downwards (a = %s < 0), so it is positive between its roots." % N(s.a)
	out.merge({
		"asked": "Find the domain of f: the values of x for which g(x) = %s > 0." % g_text(s), "answer": ans,
		"wrongs": [wrong({"shape": "above", "lo": s.p, "hi": s.q, "ends": "left out"}, "SL2.7.inequality#0")],
		"generic": [{"shape": "outside", "lo": s.p, "hi": s.q, "ends": "left out"}, {"shape": "between", "lo": s.p, "hi": s.q, "ends": "included"},
			{"shape": "below", "lo": s.p, "hi": s.q, "ends": "left out"}],
		"methods": {
			"sketch-roots": {"result": ans.values, "steps": [roots, down, final]},
			"sign-table": {"result": ans.values, "steps": [
				"g(x) = %s: the sign changes at %s and %s." % [g_factored(s), N(s.p), N(s.q)],
				"Between them the two factors have opposite signs, and a < 0, so g(x) > 0 there.", final]},
			"test-point": {"result": ans.values, "steps": [roots,
				"At x = %s, g = %s > 0; outside the roots g is negative." % [N(s.h), N(s.k)], final]},
			"gdc-graph": {"result": ans.values, "steps": [
				"Graph y = %s: it is above the x-axis between x = %s and x = %s." % [g_text(s), N(s.p), N(s.q)], "The ends are not included: g = 0 there.", final]},
			"restriction-rules": {"result": ans.values, "steps": [
				"A log needs its input positive: g(x) > 0, not ≥ 0.", roots + " " + down, final]},
		}})
	return out


func u_asymptotes(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var p: Q = s.p
	var q: Q = s.q
	var right := "x = %s and x = %s" % [N(p), N(q)]
	var tagged := [
		wrong({"v": "%s and %s" % [N(p), N(q)]}, "SL2.4.asymptotes#0"),
		wrong({"v": "y = %s and y = %s" % [N(p), N(q)]}, "SL2.4.asymptotes#1"),
		wrong({"v": "x = %s and x = %s" % [N(p.neg()), N(q.neg())]}, "SL2.4.asymptotes#2"),
		wrong({"v": "y = 0"}, "SL2.9.log-graph#0"),
	]
	# Four misconceptions for three wrong options: which three is the stream's choice.
	tagged = rng.shuffled(tagged)
	var opts: Array = [right] + tagged.map(func(w): return w.values.v)
	var ans := Answer.make("choice", {"v": ExpLogPairViews.M(right)}, {"options": opts.map(func(o): return ExpLogPairViews.M(o))})
	for w in tagged:
		w.values.v = ExpLogPairViews.M(w.values.v)
	var out := show(rep, s)
	var final := "So the asymptotes are " + Answer.text(ans) + "."
	out.merge({
		"asked": "Write down the equations of the vertical asymptotes of the graph of f.", "answer": ans, "wrongs": tagged,
		"generic": [{"v": ExpLogPairViews.M("x = %s and x = %s" % [N(p), N(s.h)])}],
		"methods": {
			"undefined-input": {"result": ans.values, "steps": [
				"f is undefined where g(x) = %s = 0." % g_factored(s), "As x nears a root, g(x) → 0⁺ and f(x) → −∞.", final]},
			"move-parent-asymptote": {"result": ans.values, "steps": [
				"y = %s x has the asymptote x = 0, where its input is 0." % LG(s),
				"Here the input is g(x), and it is 0 at both roots, so there are two asymptotes, not one moved one.", final]},
			"gdc-table": {"result": ans.values, "steps": [
				"A table of f stops giving values below x = %s and above x = %s, and plunges near them." % [N(p), N(q)],
				"Solving %s = 0 confirms it exactly." % g_factored(s), final]},
		}})
	return out


func u_zeros(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("pm_surd", {"h": s.h, "m": Q.new(s.zm), "r": Q.new(s.zr)}, {}, "x = ")
	ans.exact = true
	var final := "So " + Answer.text(ans) + "."
	var b: int = s.base
	var gm1 := Fmt.poly([s.a, s.b, s.c.sub(Q.new(1))])
	var amq: Q = s.a.neg()
	return {
		"asked": "Find the exact zeros of f.", "lines": [f_line(s)], "answer": ans,
		"generic": [{"h": s.h, "m": Q.new(s.zm), "r": Q.new(s.zr + 1)}, {"h": s.h.neg(), "m": Q.new(s.zm), "r": Q.new(s.zr)},
			{"h": s.h, "m": Q.new(1), "r": s.k}, {"h": s.h, "m": Q.new(s.zm * 2), "r": Q.new(s.zr)}],
		"methods": {
			"quadratic-formula": {"result": ans.values, "steps": [
				"f(x) = 0 when g(x) = %d⁰ = 1: %s = 0" % [b, gm1],
				("x = ±√%s" % N(s.d)) if s.h.is_zero() else "x = %s ± √%s" % [N(s.h), N(s.d)], final]},
			"complete-square": {"result": ans.values, "steps": [
				"g(x) = %s, so g(x) = 1 gives (%s)² = (%s − 1)/%s = %s" % [Fmt.vertex(s.a, s.h, s.k), Answer.x_minus(s.h), N(s.k), N(amq), N(s.d)],
				"%s = ±√%s" % [Answer.x_minus(s.h), N(s.d)], final]},
			"key-points": {"result": ans.values, "steps": [
				"%s y is 0 only at y = 1, so f(x) = 0 when g(x) = 1." % LG(s), "%s = 1, so (%s)² = %s" % [g_text(s), Answer.x_minus(s.h), N(s.d)], final]},
			"rewrite-exponential": {"result": ans.values, "steps": [
				"%s(g(x)) = 0 means g(x) = %d⁰ = 1." % [LG(s), b], "%s = 0 gives (%s)² = %s" % [gm1, Answer.x_minus(s.h), N(s.d)], final]},
		},
	}


func u_max_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var ans := Answer.make("named", {"v0": Q.new(n), "v1": s.h}, {"names": ["maximum value", "at x"]})
	ans.exact = true
	var out := show(rep, s)
	var final := "So " + Answer.text(ans) + "."
	var b: int = s.base
	var gmax := "g(%s) = %s, and %s %s = %d since %d%s = %s." % [N(s.h), N(s.k), LG(s), N(s.k), n, b, Fmt.sup(n), N(s.k)]
	out.merge({
		"asked": "Find the maximum value of f, and the value of x where it happens.", "answer": ans,
		"wrongs": [wrong({"v0": Q.new(n), "v1": s.h.neg()}, "SL2.6.vertex#0"), wrong({"v0": s.h, "v1": s.h}, "SL2.6.vertex#1")],
		"generic": [{"v0": s.k, "v1": s.h}, {"v0": Q.new(n + 1), "v1": s.h}, {"v0": Q.new(n), "v1": s.p}],
		"methods": {
			"gdc-transfer": {"result": ans.values, "steps": ["Graph y = f(x) and find its maximum: (%s, %d)." % [N(s.h), n], "Check: " + gmax, final]},
			"midpoint-of-roots": {"result": ans.values, "steps": [
				"The roots of g are %s and %s, so its top is at x = (%s + %s)/2 = %s." % [N(s.p), N(s.q), N(s.p), Fmt.paren(s.q), N(s.h)],
				"The log grows as its input grows, so f is largest where g is: " + gmax, final]},
			"formula-then-substitute": {"result": ans.values, "steps": [
				"x = −b/(2a) = %s/(2 × %s) = %s" % [N(s.b.neg()), Fmt.paren(s.a), N(s.h)], gmax, final]},
			"complete-square": {"result": ans.values, "steps": [
				"g(x) = %s: largest at x = %s." % [Fmt.vertex(s.a, s.h, s.k), N(s.h)], gmax, final]},
			"derivative-zero": {"result": ans.values, "steps": [
				"f′(x) = g′(x)/(g(x) ln %d), and g′(x) = %s = 0 at x = %s." % [b, Fmt.poly([s.a.mul(Q.new(2)), s.b]), N(s.h)], gmax, final]},
			"what-power": {"result": ans.values, "steps": [
				"The largest input to the log is g's top, %s, at x = %s." % [N(s.k), N(s.h)], "What power of %d gives %s? %d." % [b, N(s.k), n], final]},
		}})
	if rep == "graph":
		out.lines = ["The graph of y = f(x) is shown, where " + f_line(s) + "."]
	return out


func u_base_from_max(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var b: int = s.base
	var ans := Answer.make("number", {"v": Q.new(b)}, {}, "k = ")
	ans.exact = true
	var gl := "f(x) = log_k(%s)" % g_text(s)
	var out := {"answer": ans}
	match rep:
		"graph":
			out.lines = ["The graph of y = f(x) is shown, where %s. Its maximum point is (%s, %d)." % [gl, N(s.h), n]]
			out.graph = f_graph(s, [[s.h.to_float(), n, Fmt.point(s.h, n)]])
		"words":
			out.lines = ["The function f(x) = log_k(g(x)) has g(x) = %s. The largest value f takes is %d." % [g_text(s), n]]
		_:
			out.lines = [gl, "The maximum value of f is %d." % n]
	var final := "So " + Answer.text(ans) + "."
	var top := "g's roots are %s and %s, so its top is g(%s) = %s." % [N(s.p), N(s.q), N(s.h), N(s.k)]
	out.merge({
		"asked": "Find the value of the base k.",
		"wrongs": [wrong({"v": s.k.div(Q.new(n))}, "SL1.5.exp-log-form#0")],
		"generic": [{"v": s.k}, {"v": Q.new(n)}, {"v": Q.new(b + 1)}, {"v": s.k.mul(Q.new(n))}],
		"methods": {
			"key-points": {"result": ans.values, "steps": [top, "log_k(%s) = %d means k%s = %s." % [N(s.k), n, Fmt.sup(n), N(s.k)], final]},
			"midpoint-of-roots": {"result": ans.values, "steps": [
				"The top of g is at x = (%s + %s)/2 = %s, where g = %s." % [N(s.p), Fmt.paren(s.q), N(s.h), N(s.k)],
				"f's maximum is log_k %s = %d, so k%s = %s." % [N(s.k), n, Fmt.sup(n), N(s.k)], final]},
			"rewrite-exponential": {"result": ans.values, "steps": [top, "log_k %s = %d in exponential form: k%s = %s" % [N(s.k), n, Fmt.sup(n), N(s.k)], final]},
			"what-power": {"result": ans.values, "steps": [top, "Which number to the power %d gives %s? %d%s = %s." % [n, N(s.k), b, Fmt.sup(n), N(s.k)], final]},
		}})
	return out


func u_range(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var ans := Answer.make("range", {"var": "y", "rel": "≤", "k": Q.new(n)})
	ans.exact = true
	var out := show(rep, s)
	var final := "So the range is " + Answer.text(ans) + "."
	out.merge({
		"asked": "Find the range of f.", "answer": ans,
		"wrongs": [wrong({"var": "y", "rel": "≥", "k": Q.new(n)}, "SL2.6.vertex#2"), wrong({"var": "x", "rel": "≤", "k": Q.new(n)}, "SL2.2.range#2")],
		"generic": [{"var": "y", "rel": "≤", "k": s.k}, {"var": "y", "rel": "≤", "k": s.h}, {"var": "x", "rel": "≥", "k": Q.new(n)}],
		"methods": {
			"complete-square": {"result": ans.values, "steps": [
				"g(x) = %s ≤ %s, and g(x) > 0 on the domain." % [Fmt.vertex(s.a, s.h, s.k), N(s.k)],
				"So 0 < g(x) ≤ %s, and f(x) = %s(g(x)) ≤ %s %s = %d, with no lower bound." % [N(s.k), LG(s), LG(s), N(s.k), n], final]},
			"vertex-or-asymptote": {"result": ans.values, "steps": [
				"The maximum is at the vertex of g: f = %s %s = %d." % [LG(s), N(s.k), n],
				"Near the asymptotes f → −∞, so every value up to %d is taken." % n, final]},
		}})
	return out


func u_axis_of_graph(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("axis", {"var": "x", "h": s.h})
	ans.exact = true
	var out := show(rep, s)
	var final := "So the line of symmetry is " + Answer.text(ans) + "."
	var z1 := zero_text(s, -1)
	var z2 := zero_text(s, 1)
	out.merge({
		"asked": "Write down the equation of the line of symmetry of the graph of f.", "answer": ans,
		"wrongs": [wrong({"var": "x", "h": Q.new(0)}, "SL2.4.symmetry#0")],
		"generic": [{"var": "y", "h": s.h}, {"var": "x", "h": s.h.neg()}, {"var": "x", "h": s.p}],
		"methods": {
			"midpoint-of-roots": {"result": ans.values, "steps": [
				"f is symmetric where g is. g's roots are %s and %s." % [N(s.p), N(s.q)], "Their midpoint is (%s + %s)/2 = %s." % [N(s.p), Fmt.paren(s.q), N(s.h)], final]},
			"formula-then-substitute": {"result": ans.values, "steps": ["g's axis: x = −b/(2a) = %s/(2 × %s) = %s" % [N(s.b.neg()), Fmt.paren(s.a), N(s.h)], "f = %s(g(x)) has the same axis." % LG(s), final]},
			"midpoint-of-pair": {"result": ans.values, "steps": [
				"The zeros %s and %s are at the same height (0)." % [z1, z2], "Their x-values average to %s." % N(s.h), final]},
			"read-from-form": {"result": ans.values, "steps": ["g(x) = %s in vertex form." % Fmt.vertex(s.a, s.h, s.k), "Its axis is x = %s, and f keeps it." % N(s.h), final]},
		}})
	return out


func u_y_intercept(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Q = s.c
	var ans := Answer.make("number", {"v": c}, {}, "f(0) = %s " % LG(s))
	ans.exact = true
	var final := "So " + Answer.text(ans) + "."
	return {
		"asked": "Find where the graph of f meets the y-axis: give f(0) in the form %s c." % LG(s), "lines": [f_line(s)], "answer": ans,
		"generic": [{"v": s.k}, {"v": c.add(Q.new(1))}, {"v": s.p.mul(s.q).abs_q()}, {"v": s.a.abs_q().add(c)}],
		"methods": {"what-power": {"result": ans.values, "steps": [
			"At x = 0: g(0) = %s, which is positive, so f(0) exists." % N(c), "f(0) = %s(g(0)) = %s %s" % [LG(s), LG(s), N(c)], final]}},
	}


func u_sign_of_f(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z1 := zero_text(s, -1)
	var z2 := zero_text(s, 1)
	var p := N(s.p)
	var q := N(s.q)
	var right := "%s < x < %s or %s < x < %s" % [p, z1, z2, q]
	var w1 := "%s < x < %s" % [z1, z2]
	var opts := [right, w1, "x < %s or x > %s" % [z1, z2], "%s < x < %s" % [p, q]]
	opts = opts.map(func(o): return ExpLogPairViews.M(o))
	var ans := Answer.make("choice", {"v": opts[0]}, {"options": opts})
	var out := show(rep, s)
	var final := "So f(x) < 0 for " + Answer.text(ans) + "."
	var zeros := "f(x) = 0 where g(x) = 1: x = %s and x = %s." % [z1, z2]
	out.merge({
		"asked": "Find the values of x for which f(x) < 0.", "answer": ans,
		"wrongs": [wrong({"v": opts[1]}, "SL2.7.inequality#1")],
		"generic": [{"v": opts[2]}, {"v": opts[3]}],
		"methods": {
			"sketch-roots": {"result": ans.values, "steps": [zeros, "f < 0 where 0 < g(x) < 1: between each asymptote and the nearer zero.", final]},
			"test-point": {"result": ans.values, "steps": [zeros, "At x = %s, f = %d > 0; just inside each asymptote f → −∞ < 0." % [N(s.h), s.n], final]},
			"key-points": {"result": ans.values, "steps": ["%s y < 0 exactly when 0 < y < 1." % LG(s), zeros + " g < 1 outside the zeros, inside the domain.", final]},
			"gdc-transfer": {"result": ans.values, "steps": ["Graph y = f(x): it is below the x-axis near both asymptotes.", zeros, final]},
		}})
	return out


func u_quadratic_from_features(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var b: int = s.base
	var ans := Answer.make("quad_in", {"A": s.a, "B": s.b, "C": s.c}, {}, "g(x) = ")
	ans.exact = true
	var out := {"answer": ans}
	var gl := "f(x) = %s(g(x)), where g is a quadratic." % LG(s)
	if rep == "graph":
		out.lines = ["The graph of y = f(x) is shown: " + gl + " Its maximum point is (%s, %d)." % [N(s.h), n]]
		out.graph = f_graph(s, [[s.h.to_float(), n, Fmt.point(s.h, n)]])
	else:
		out.lines = [gl, "The graph of f has asymptotes x = %s and x = %s, and its maximum value is %d." % [N(s.p), N(s.q), n]]
	var final := "So " + Answer.text(ans) + "."
	var w: int = s.w
	out.merge({
		"asked": "Find g(x), in the form ax² + bx + c.",
		"generic": [{"A": s.a.neg(), "B": s.b.neg(), "C": s.c.neg()}, {"A": Q.new(-1), "B": s.h.mul(Q.new(2)), "C": Q.new(w * w).sub(s.h.mul(s.h))},
			{"A": s.a, "B": s.b.neg(), "C": s.c}, {"A": s.a.mul(Q.new(n)), "B": s.b.mul(Q.new(n)), "C": s.c.mul(Q.new(n))}],
		"methods": {
			"undefined-input": {"result": ans.values, "steps": [
				"f is undefined at x = %s and x = %s, so g(x) = a(%s)(%s)." % [N(s.p), N(s.q), Answer.x_minus(s.p), Answer.x_minus(s.q)],
				"The maximum %d is at the midpoint x = %s, where g = %d%s = %s: a × %s = %s, so a = %s." % [n, N(s.h), b, Fmt.sup(n), N(s.k), Fmt.paren(Q.new(-w * w)), N(s.k), N(s.a)],
				final]},
			"read-vertex-form": {"result": ans.values, "steps": [
				"The vertex of g is (%s, %d%s) = (%s, %s): g(x) = a(x − %s)² + %s." % [N(s.h), b, Fmt.sup(n), N(s.h), N(s.k), N(s.h), N(s.k)],
				"g(%s) = 0: a × %d + %s = 0, so a = %s, and expanding gives the general form." % [N(s.q), w * w, N(s.k), N(s.a)], final]},
		}})
	return out
