class_name GdcInequalityViews
extends RefCounted
## The views on the `gdc-inequality` situation: one builder per unknown of
## fn-ext-inequality-graphical (FAL-420). Builders return what QuadraticViews' builders
## return (see quadratic_views.gd). The solution set is written with its ends to 3 s.f.
## and played as a choice of sets, each wrong one a typical mistake.

const NEED := {
	"solve-with-gdc": {"set": "any"},
	"read-from-graph": {"set": "any"},
	"two-piece-solution": {"set": "outside"},
	"exceeds-in-context": {"mode": "level"},
	"inequality-from-region": {"set": "any"},
}

const IE := "SL2.10.inequality-graphical"


func has(unknown: String) -> bool:
	return NEED.has(unknown)


func need(unknown: String, _rep: String) -> Dictionary:
	return NEED[unknown].duplicate()


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "wrongs", "generic"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "generic"] else null
	out.given = GdcInequalitySituation.export(s)
	out.trap = {}
	return out


# ── Helpers ──────────────────────────────────────────────────

static func S(x: Variant) -> String:
	return GdcKit.S(x)


static func ft(s: Dictionary) -> String:
	return GdcTwoCurvesSituation.text(s.f, s.var)


static func gt(s: Dictionary) -> String:
	return GdcTwoCurvesSituation.text(s.g, s.var)


static func dom(s: Dictionary) -> String:
	return GdcTwoCurvesSituation.domain_text(s)


static func wrong(v: String, ref: String = "") -> Dictionary:
	return {"values": {"v": v}, "ref": ref}


## The sets: between the crossings, the two pieces outside them, and each piece alone.
static func sets(s: Dictionary) -> Dictionary:
	var v: String = s.var
	var a := S(s.crossings[0][0])
	var b := S(s.crossings[1][0])
	var d1 := Fmt.num(s.d1)
	var d2 := Fmt.num(s.d2)
	return {"inside": "%s < %s < %s" % [a, v, b], "outside": "%s ≤ %s < %s or %s < %s ≤ %s" % [d1, v, a, b, v, d2],
		"left": "%s ≤ %s < %s" % [d1, v, a], "right": "%s < %s ≤ %s" % [b, v, d2], "points": "%s = %s or %s = %s" % [v, a, v, b],
		"closed": "%s ≤ %s ≤ %s" % [a, v, b]}


static func ineq(s: Dictionary, rel: String) -> String:
	return "%s %s %s" % [ft(s), rel, gt(s)]


## Both curves with the crossings marked (to 3 s.f.).
static func screen(s: Dictionary) -> Dictionary:
	var g := GdcTwoCurvesViews.screen(s)
	g.points = s.crossings.map(func(c): return {"x": c[0], "y": c[1], "label": GdcKit.pt(c[0], c[1])})
	return g


static func steps(s: Dictionary, final: String) -> Array:
	var cs: Array = s.crossings
	var above := "f is above g" if s.inside == (s.rel == ">") else "f is below g"
	return ["The graphs cross at %s = %s and %s = %s (the GDC's intersect tool)." % [s.var, GdcKit.W(cs[0][0]), s.var, GdcKit.W(cs[1][0])],
		"Between the crossings %s; outside them it is the other way round." % above, final]


func _choice(s: Dictionary, right_key: String, wrongs: Array, asked: String, lines: Array) -> Dictionary:
	var st := sets(s)
	var right: String = st[right_key]
	var gen: Array = []
	for k in ["inside", "outside", "closed", "left", "right"]:
		if k != right_key:
			gen.append(st[k])
	var out := LogFunctionViews.choice(right, wrongs, gen)
	var final: String = "So the solution is " + out.answer.values.v + "."
	out.merge({"asked": asked, "lines": lines, "methods": {
		"intersections-then-read": {"result": out.answer.values, "steps": steps(s, final)},
		"difference-sign": {"result": out.answer.values, "steps": ["Graph y = (%s) − (%s): its zeros are the crossings, %s." % [ft(s), gt(s),
			st.points], "It is %s 0 %s." % ["above" if s.rel == ">" else "below", "between them" if s.inside else "outside them"], final]},
		"analytic-boundary": {"result": out.answer.values, "steps": ["The boundary is where %s = %s: no algebra solves it, so read the crossings, %s." % [ft(s), gt(s), st.points],
			"Then test a point in each part to see where %s holds." % ineq(s, s.rel), final]},
	}})
	return out


# ── fn-ext-inequality-graphical ──────────────────────────────

func u_solve_with_gdc(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var st := sets(s)
	var right := "inside" if s.inside else "outside"
	var wrongs: Array = [wrong(st.points, IE + "#0")]
	if not s.inside:
		wrongs.append(wrong(st.inside, IE + "#1"))
	return _choice(s, right, wrongs, "Solve %s, for %s." % [ineq(s, s.rel), dom(s)], [ineq(s, s.rel)])


func u_read_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var st := sets(s)
	var right := "inside" if s.inside else "outside"
	var wrongs: Array = [] if s.inside else [wrong(st.inside, IE + "#1")]
	var out := _choice(s, right, wrongs, "Use the graph to solve %s, for %s." % [ineq(s, s.rel), dom(s)],
		["The graphs of y = %s and y = %s are shown, with their crossings marked." % [ft(s), gt(s)]])
	out.graph = screen(s)
	return out


func u_two_piece_solution(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var st := sets(s)
	var out := _choice(s, "outside", [wrong(st.right, IE + "#2"), wrong(st.inside, IE + "#1")],
		"Solve %s, for %s. Give both parts of the solution." % [ineq(s, s.rel), dom(s)], [ineq(s, s.rel)])
	if rep == "graph":
		out.lines = ["The graphs of y = %s and y = %s are shown, with their crossings marked." % [ft(s), gt(s)]]
		out.graph = screen(s)
	return out


func u_exceeds_in_context(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var st := sets(s)
	var L: Q = s.g.c
	return _choice(s, "inside", [wrong(st.points, IE + "#0")],
		"Find the times when the concentration is above %s mg/l." % Fmt.dec(L),
		["A drug's concentration in the blood t hours after a dose is C(t) = %s mg/l, for %s." % [ft(s), dom(s)]])


func u_inequality_from_region(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var st := sets(s)
	var shown: String = st.inside if s.inside else st.outside
	var other := "<" if s.rel == ">" else ">"
	var out := LogFunctionViews.choice(ineq(s, s.rel), [], [ineq(s, other), "%s = %s" % [ft(s), gt(s)], ineq(s, "≥" if s.rel == ">" else "≤")])
	var final: String = "So the inequality is " + out.answer.values.v + "."
	var above := "above" if s.rel == ">" else "below"
	out.merge({
		"asked": "The solution set of an inequality between f and g is %s. Which inequality is it?" % shown,
		"lines": ["The graphs of y = %s and y = %s are shown, with their crossings marked." % [ft(s), gt(s)]], "graph": screen(s),
		"methods": {"intersections-then-read": {"result": out.answer.values, "steps": [
			"On %s the graph of f is %s the graph of g." % [shown, above],
			"The ends are left out, so the inequality is strict, not ≥ or ≤.", final]}}})
	return out
