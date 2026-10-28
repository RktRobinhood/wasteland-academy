class_name QuadraticInequalityViews
extends RefCounted
## The views on the `quadratic-inequality` situation: one builder per unknown of
## fn-quadratic-inequality (FAL-414). Builders return what QuadraticViews' builders
## return (see quadratic_views.gd). Solution sets use the interval answer kind.


const NEED := {
	"solve-against-zero": {"form": "zero"},
	"solve-against-constant": {"form": "const"},
	"largest-integer": {"form": "largest"},
	"square-against-constant": {"form": "square"},
	"negative-a": {"form": "nega"},
	"no-real-roots-case": {"form": "none"},
	"inequality-from-solution": {"form": "fromsol"},
}


func has(unknown: String) -> bool:
	return NEED.has(unknown)


func need(unknown: String, rep: String) -> Dictionary:
	var n: Dictionary = NEED[unknown].duplicate()
	if rep == "graph":
		n.graph = true
	return n


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "wrongs", "generic"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "generic"] else null
	return out


static func N(v: Variant) -> String:
	return Fmt.num(v)


static func wrong(values: Dictionary, ref: String = "") -> Dictionary:
	return {"values": values, "ref": ref}


static func strict(rel: String) -> bool:
	return rel == "<" or rel == ">"


## Where a·(x − p)(x − q) rel 0 holds: between the roots or outside them.
static func solution(s: Dictionary) -> Dictionary:
	var below: bool = s.rel == "<" or s.rel == "≤"
	var between: bool = below == (s.a.sign() > 0)
	return Answer.make("interval", {"shape": "between" if between else "outside", "lo": s.p, "hi": s.q,
		"ends": "left out" if strict(s.rel) else "included"}, {"var": "x"})


static func given_of(s: Dictionary) -> Dictionary:
	return {"a": s.a.key(), "b": s.b.key(), "c": s.c.key(), "rel": s.rel, "rhs": s.rhs.key()}


static func other_ends(e: String) -> String:
	return "included" if e == "left out" else "left out"


## The opposite region, the ends the other way, and swapped signs on the roots.
static func generic_sets(v: Dictionary) -> Array:
	var opp := "outside" if v.shape == "between" else "between"
	return [{"shape": opp, "lo": v.lo, "hi": v.hi, "ends": v.ends}, {"shape": v.shape, "lo": v.lo, "hi": v.hi, "ends": other_ends(v.ends)},
		{"shape": v.shape, "lo": v.hi.neg(), "hi": v.lo.neg(), "ends": v.ends}, {"shape": opp, "lo": v.lo, "hi": v.hi, "ends": other_ends(v.ends)}]


## The three ways of reading a·(x − p)(x − q) against 0, ending at the answer.
static func methods(s: Dictionary, ans: Dictionary, lead: Array) -> Dictionary:
	var final := "So " + Answer.text(ans) + "."
	var res: Dictionary = ans.values
	var up: bool = s.a.sign() > 0
	var fac := Fmt.factorised(s.a, s.p, s.q)
	var roots := "%s = 0 at x = %s and x = %s" % [fac, N(s.p), N(s.q)]
	var below: bool = s.rel == "<" or s.rel == "≤"
	var region := "between the roots" if below == up else "outside the roots"
	var sk: Array = lead.duplicate()
	sk.append(roots)
	sk.append("The parabola opens %s, so it is %s the x-axis between the roots and %s it outside them." % [
		"upwards" if up else "downwards", "below" if up else "above", "above" if up else "below"])
	sk.append("%s 0 is %s%s." % [s.rel, region, "" if strict(s.rel) else ", with the roots included"])
	sk.append(final)
	var st: Array = lead.duplicate()
	var sg := ["+", "−", "+"] if up else ["−", "+", "−"]
	st.append("f(x) = %s. Signs: x < %s gives %s, %s < x < %s gives %s, x > %s gives %s." % [fac, N(s.p), sg[0], N(s.p), N(s.q), sg[1], N(s.q), sg[2]])
	st.append("%s 0 picks the %s rows%s." % [s.rel, "−" if below else "+", "" if strict(s.rel) else ", plus the roots"])
	st.append(final)
	var tp: Array = lead.duplicate()
	var t: Q = s.p.add(s.q).div(2)
	var ft: Q = s.a.mul(t.sub(s.p)).mul(t.sub(s.q))
	tp.append(roots)
	tp.append("Test x = %s, between them: f(%s) = %s, which is %s, so %s 0 is %s." % [N(t), N(t), N(ft), "negative" if ft.sign() < 0 else "positive", s.rel, region])
	tp.append(final)
	return {"sketch-roots": {"result": res, "steps": sk}, "sign-table": {"result": res, "steps": st}, "test-point": {"result": res, "steps": tp}}


static func roots_graph(s: Dictionary) -> Dictionary:
	return QuadraticViews.graph(s, [[s.p, 0], [s.q, 0]])


# ── fn-quadratic-inequality ──────────────────────────────────

func _solve(rep: String, s: Dictionary, tag2: bool) -> Dictionary:
	var ans := solution(s)
	var line := "%s %s 0" % [Fmt.general(s.a, s.b, s.c), s.rel]
	var out := {"asked": "Solve the inequality.", "lines": [line], "given": given_of(s), "answer": ans}
	if rep == "graph":
		out.graph = roots_graph(s)
		out.lines = [line, "The graph of y = %s is shown, with its roots marked." % Fmt.general(s.a, s.b, s.c)]
	var v: Dictionary = ans.values
	var wrongs: Array = []
	if v.shape == "outside":
		wrongs.append(wrong({"shape": "between", "lo": v.lo, "hi": v.hi, "ends": v.ends}, "SL2.7.inequality#1"))
	if tag2:
		wrongs.append(wrong({"shape": "outside" if v.shape == "between" else "between", "lo": v.lo, "hi": v.hi, "ends": v.ends}, "SL2.7.inequality#2"))
	out.wrongs = wrongs
	out.generic = generic_sets(v)
	out.methods = methods(s, ans, [])
	return out


func u_solve_against_zero(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _solve(rep, s, false)


func u_negative_a(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _solve(rep, s, true)


func u_solve_against_constant(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := solution(s)
	var shown_c: Q = s.c.add(s.rhs)
	var line := "%s %s %s" % [Fmt.general(s.a, s.b, shown_c), s.rel, N(s.rhs)]
	var move := "Move %s across first: %s %s 0" % [N(s.rhs), Fmt.general(s.a, s.b, s.c), s.rel]
	var v: Dictionary = ans.values
	var wrongs: Array = []
	if v.shape == "outside":
		wrongs.append(wrong({"shape": "between", "lo": v.lo, "hi": v.hi, "ends": v.ends}, "SL2.7.inequality#1"))
	var ms := methods(s, ans, [move])
	return {"asked": "Solve the inequality.", "lines": [line], "given": given_of(s), "answer": ans, "wrongs": wrongs,
		"generic": generic_sets(v), "methods": {"sketch-roots": ms["sketch-roots"]}}


func u_square_against_constant(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := solution(s)
	var v: Dictionary = ans.values
	var n: Q = s.n
	var below: bool = s.rel == "<" or s.rel == "≤"
	var wrongs: Array = [
		wrong({"shape": "pm_lt" if below else "pm_gt", "lo": n.neg(), "hi": n, "ends": v.ends}, "SL2.7.inequality#0"),
		wrong({"shape": "below" if below else "above", "lo": n, "hi": n, "ends": v.ends}, "SL2.7.inequality#0"),
	]
	var lead: Array = ["x² %s %s means x² − %s %s 0, and x² − %s = (x + %s)(x − %s)" % [s.rel, N(s.rhs), N(s.rhs), s.rel, N(s.rhs), N(n), N(n)]]
	var ms := methods(s, ans, lead)
	ms["sketch-roots"].steps.remove_at(2)
	return {"asked": "Solve the inequality.", "lines": ["x² %s %s" % [s.rel, N(s.rhs)]], "given": given_of(s), "answer": ans,
		"wrongs": wrongs, "generic": generic_sets(v),
		"methods": {"sketch-roots": ms["sketch-roots"], "test-point": ms["test-point"]}}


func u_no_real_roots_case(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var up: bool = s.a.sign() > 0
	var above: bool = s.rel == ">" or s.rel == "≥"
	var all := above == up
	var opts := ["all real x", "no real x", "x = %s only" % N(s.h), "every x except %s" % N(s.h)]
	var ans := Answer.make("choice", {"v": opts[0] if all else opts[1]}, {"options": opts})
	var line := "%s %s 0" % [Fmt.general(s.a, s.b, s.c), s.rel]
	var out := {"asked": "Solve the inequality.", "lines": [line], "given": given_of(s), "answer": ans}
	if rep == "graph":
		out.graph = QuadraticViews.graph(s, [[s.h, s.k]])
		out.lines = [line, "The graph of y = %s is shown, with its vertex marked." % Fmt.general(s.a, s.b, s.c)]
	out.generic = opts.filter(func(o): return o != ans.values.v).map(func(o): return {"v": o})
	out.methods = {"sketch-roots": {"result": ans.values, "steps": [
		"Δ = %s² − 4 × %s × %s = %s < 0, so there are no roots." % [Fmt.paren(s.b), Fmt.paren(s.a), Fmt.paren(s.c), N(s.disc)],
		"The parabola opens %s with its vertex %s, so it is %s the x-axis for every x." % ["upwards" if up else "downwards", Fmt.point(s.h, s.k), "above" if up else "below"],
		"So " + Answer.text(ans) + "."]}}
	return out


func u_largest_integer(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var best: Q = s.best
	var ans := Answer.make("number", {"v": best}, {}, "n = ")
	ans.exact = true
	var final := "So " + Answer.text(ans) + "."
	var r3 := Fmt.sf(s.root)
	var b1 := best.add(1)
	var check := "n = %s uses %s × %s = %s tiles, but n = %s would need %s × %s = %s." % [
		N(best), N(best), N(best.add(s.d)), N(best.mul(best.add(s.d))), N(b1), N(b1), N(b1.add(s.d)), N(b1.mul(b1.add(s.d)))]
	return {
		"asked": "Find the largest number of rows n that can be made.",
		"lines": ["A mosaic has n rows of (n + %s) tiles, and there are %s tiles to use." % [N(s.d), N(s.T)]],
		"given": {"d": s.d.key(), "T": s.T.key()}, "answer": ans,
		"generic": [{"v": b1}, {"v": best.sub(1)}, {"v": best.add(2)}, {"v": Q.new(roundi(s.root))}],
		"methods": {
			"test-point": {"result": ans.values, "steps": [
				"n(n + %s) ≤ %s, so n² + %sn − %s ≤ 0." % [N(s.d), N(s.T), N(s.d), N(s.T)],
				"The positive root is n = (−%s + √%s)/2 = %s, so n ≤ %s." % [N(s.d), N(s.d.sq().add(s.T.mul(4))), r3, r3],
				"Test the whole numbers either side: " + check, final]},
			"gdc-graph": {"result": ans.values, "steps": [
				"Graph y = x(x + %s) and y = %s: they cross at x = %s." % [N(s.d), N(s.T), r3],
				"n must be a whole number no bigger than %s (round down, not to the nearest): %s" % [r3, check], final]},
		},
	}


func u_inequality_from_solution(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var sol := solution(s)
	var v: Dictionary = sol.values
	var ans := Answer.make("ineq_a", {"b": s.b, "c": s.c, "rel": s.rel})
	var final := "So " + Answer.text(ans) + "."
	var said := Answer.text(sol)
	var out := {"asked": "Write a quadratic inequality x² + bx + c < 0 (or ≤, >, ≥) with this solution.", "answer": ans,
		"given": {"p": s.p.key(), "q": s.q.key(), "shape": v.shape, "ends": v.ends},
		"lines": ["The solution of a quadratic inequality is %s." % said]}
	if rep == "graph":
		out.graph = roots_graph(s)
		out.lines = ["The graph of y = x² + bx + c is shown, with its roots marked. The solution is where it is %s the x-axis%s." % [
			"below" if v.shape == "between" else "above", "" if strict(s.rel) else ", the roots included"]]
	var flip := {"<": ">", ">": "<", "≤": "≥", "≥": "≤"}
	out.generic = [{"b": s.b, "c": s.c, "rel": flip[s.rel]}, {"b": s.b.neg(), "c": s.c, "rel": s.rel}, {"b": s.b, "c": s.c.neg(), "rel": s.rel},
		{"b": s.b, "c": s.c, "rel": {"<": "≤", "≤": "<", ">": "≥", "≥": ">"}[s.rel]}]
	out.methods = {"sketch-roots": {"result": ans.values, "steps": [
		"The ends of the solution, x = %s and x = %s, are the roots: (x%s)(x%s) = %s" % [N(s.p), N(s.q), Fmt.plus(s.p.neg()), Fmt.plus(s.q.neg()), Fmt.general(1, s.b, s.c)],
		"y = %s opens upwards, so it is %s 0 %s the roots%s." % [Fmt.general(1, s.b, s.c), "below" if v.shape == "between" else "above",
			"between" if v.shape == "between" else "outside", "" if strict(s.rel) else ", and 0 at them"],
		final]}}
	return out
