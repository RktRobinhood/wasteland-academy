class_name CurveLineViews
extends RefCounted
## The views on the `curve-and-line` situation: one builder per unknown of
## fn-curve-intersection-quadratic (FAL-414). Builders return what QuadraticViews'
## builders return (see quadratic_views.gd).
##
## "equation" shows both equations, "graph" sketches the curve and the line (the meeting
## points marked A and B, their coordinates not given), "words" says it in a sentence.

const NEED := {
	"equate-to-quadratic": {"mode": "int"},
	"meeting-x": {"mode": "int"},
	"meeting-points": {"mode": "int"},
	"chord-length": {"mode": "int"},
	"normal-meets-again": {"mode": "normal"},
	"line-from-meeting-points": {"mode": "int"},
	"intercept-from-one-point": {"mode": "int"},
	"count-from-sketch": {"mode": "count"},
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
	# Q7's rounding trap, where the answer needs rounding (see game/README.md).
	out.trap = Answer.rounding_trap(out.answer)
	return out


# ── Helpers ──────────────────────────────────────────────────

static func N(v: Variant) -> String:
	return Fmt.num(v)


static func wrong(values: Dictionary, ref: String = "") -> Dictionary:
	return {"values": values, "ref": ref}


static func curve_rhs(s: Dictionary) -> String:
	return Fmt.general(s.A, s.B, s.C)


static func line_rhs(s: Dictionary) -> String:
	return Fmt.poly([s.m, s.n])


## The equated quadratic: (curve) − (line) = 0.
static func eq_coeffs(s: Dictionary) -> Array:
	return [s.A, s.B.sub(s.m), s.C.sub(s.n)]


static func eq_text(s: Dictionary) -> String:
	var c := eq_coeffs(s)
	return Fmt.general(c[0], c[1], c[2]) + " = 0"


static func shown(s: Dictionary) -> Array:
	return ["Curve: y = " + curve_rhs(s), "Line: y = " + line_rhs(s)]


static func given_of(s: Dictionary) -> Dictionary:
	return {"A": s.A.key(), "B": s.B.key(), "C": s.C.key(), "m": s.m.key(), "n": s.n.key(), "mode": s.mode}


static func equate_step(s: Dictionary) -> String:
	return "Where they meet, %s = %s, so %s" % [curve_rhs(s), line_rhs(s), eq_text(s)]


static func factor_step(s: Dictionary) -> String:
	return "%s(x%s)(x%s) = 0, so x = %s or x = %s" % [Fmt.lead(s.a), Fmt.plus(s.x1.neg()) if not s.x1.is_zero() else "", Fmt.plus(s.x2.neg()) if not s.x2.is_zero() else "", N(s.x1), N(s.x2)]


## The sketch: the curve and the line, bounds that hold the points given (or, for the
## off-screen trap, that leave one out).
static func sketch(s: Dictionary, marks: Array, labels: Array, bounds: Array = []) -> Dictionary:
	var h: Q = s.B.neg().div(s.A.mul(2))
	var par := {"a": s.A, "h": h, "k": CurveLineSituation.curve_at(s, h), "p": null, "q": null}
	var g := QuadraticViews.graph(par, marks)
	g.points = []
	for i in marks.size():
		g.points.append({"x": Q.of(marks[i][0]).to_float(), "y": Q.of(marks[i][1]).to_float(), "label": labels[i]})
	g.line = {"m": s.m.to_float(), "n": s.n.to_float()}
	if not bounds.is_empty():
		g.x0 = bounds[0]
		g.x1 = bounds[1]
		g.y0 = bounds[2]
		g.y1 = bounds[3]
	return g


func _reps(rep: String, s: Dictionary, out: Dictionary, words: String) -> void:
	out.lines = shown(s)
	if rep == "graph":
		out.graph = sketch(s, [[s.x1, s.y1], [s.x2, s.y2]], ["A", "B"])
		out.lines = shown(s) + ["The sketch shows the curve and the line meeting at A and B."]
	elif rep == "words":
		out.lines = [words]


# ── fn-curve-intersection-quadratic ──────────────────────────

func u_equate_to_quadratic(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := eq_coeffs(s)
	var ans := Answer.make("quad_in", {"B": c[1], "C": c[2]}, {"A": s.A, "var": "x", "tail": " = 0"})
	var out := {"answer": ans, "given": given_of(s),
		"asked": "Find the quadratic equation, %s = 0, that the x-coordinates of the meeting points satisfy." % (Fmt.lead(s.A) + "x² + bx + c")}
	_reps(rep, s, out, "")
	var final := "So " + Answer.text(ans) + "."
	out.generic = [{"B": s.B.add(s.m), "C": s.C.add(s.n)}, {"B": c[1], "C": s.C.add(s.n)}, {"B": s.B.add(s.m), "C": c[2]},
		{"B": s.B, "C": c[2]}, {"B": c[1], "C": s.C}]
	out.methods = {
		"equate-and-solve": {"result": ans.values, "steps": [
			"Where they meet, the y-values are equal: %s = %s" % [curve_rhs(s), line_rhs(s)],
			"Take %s from both sides." % line_rhs(s), final]},
		"reduce-to-polynomial": {"result": ans.values, "steps": [
			"Curve minus line is zero where they meet: (%s) − (%s) = 0" % [curve_rhs(s), line_rhs(s)],
			"Collect the x terms (%s − %s) and the numbers (%s − %s)." % [N(s.B), Fmt.paren(s.m), N(s.C), Fmt.paren(s.n)], final]},
	}
	return out


func u_meeting_x(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("roots", {"r1": s.x1, "r2": s.x2})
	var out := {"answer": ans, "given": given_of(s), "asked": "Find the x-coordinates of the points where the line meets the curve."}
	_reps(rep, s, out, "")
	var final := "So " + Answer.text(ans) + "."
	var c := eq_coeffs(s)
	var fs := QuadraticViews.formula_steps(c[0], c[1], c[2])
	var res: Dictionary = ans.values
	out.wrongs = [wrong({"r1": s.x1.neg(), "r2": s.x2.neg()}, "SL2.7.solve-equation#1")]
	out.generic = [{"r1": s.y1, "r2": s.y2}, {"r1": s.x1, "r2": s.x2.neg()}, {"r1": s.x1.neg(), "r2": s.x2}, {"r1": s.x1.add(1), "r2": s.x2.add(1)}]
	out.methods = {
		"equate-and-solve": {"result": res, "steps": [equate_step(s), "Factorise: " + factor_step(s), final]},
		"sketch-and-count": {"result": res, "steps": [
			("The sketch shows two meeting points, A and B." if rep == "graph" else "A sketch of both shows the line crossing the curve twice."),
			"Find them exactly: " + equate_step(s), factor_step(s), final]},
		"zeros-of-difference": {"result": res, "steps": [
			"Let d(x) = (%s) − (%s) = %s. They meet where d(x) = 0." % [curve_rhs(s), line_rhs(s), Fmt.general(c[0], c[1], c[2])],
			factor_step(s), final]},
		"factorise": {"result": res, "steps": [equate_step(s), factor_step(s), final]},
		"quadratic-formula": {"result": res, "steps": [equate_step(s), Step.text(fs.steps[0]) + ", so √Δ = " + Step.text(fs.steps[1]).trim_prefix("√Δ = "), fs.steps[2], final]},
	}
	return out


func u_meeting_points(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("points2", {"x1": s.x1, "y1": s.y1, "x2": s.x2, "y2": s.y2})
	var out := {"answer": ans, "given": given_of(s), "asked": "Find the coordinates of the points where the line meets the curve."}
	_reps(rep, s, out, "")
	var final := "So " + Answer.text(ans) + "."
	var ys := "On the line: y = %s × %s%s = %s and y = %s × %s%s = %s" % [N(s.m), Fmt.paren(s.x1), Fmt.plus(s.n), N(s.y1), N(s.m), Fmt.paren(s.x2), Fmt.plus(s.n), N(s.y2)]
	var res: Dictionary = ans.values
	out.generic = [{"x1": s.x1, "y1": s.y2, "x2": s.x2, "y2": s.y1}, {"x1": s.x1, "y1": s.y1.neg(), "x2": s.x2, "y2": s.y2.neg()},
		{"x1": s.x1.neg(), "y1": s.y1, "x2": s.x2.neg(), "y2": s.y2}, {"x1": s.x1, "y1": s.y1.sub(s.n.mul(2)), "x2": s.x2, "y2": s.y2.sub(s.n.mul(2))}]
	out.methods = {
		"equate-and-solve": {"result": res, "steps": [equate_step(s), factor_step(s), ys, final]},
		"gdc-intersect": {"result": res, "steps": [
			"Graph y = %s and y = %s, and use intersect twice: x = %s and x = %s." % [curve_rhs(s), line_rhs(s), N(s.x1), N(s.x2)],
			ys, final]},
		"graph-check": {"result": res, "steps": [equate_step(s), factor_step(s), ys,
			"Both points satisfy the curve's equation too. " + final]},
	}
	return out


## m√r with r square-free: [m, r].
static func simplify_surd(m: int, r: int) -> Array:
	var f := 2
	while f * f <= r:
		while r % (f * f) == 0:
			r /= f * f
			m *= f
		f += 1
	return [m, r]


func u_chord_length(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var dx: int = s.x2.sub(s.x1).n
	var r: int = 1 + s.m.n * s.m.n
	var sv := simplify_surd(dx, r)
	var ans := Answer.make("surd", {"m": Q.new(sv[0]), "r": Q.new(sv[1])}, {}, "AB = ")
	var final := "So " + Answer.text(ans) + "."
	var out := {"answer": ans, "given": given_of(s),
		"asked": "The line meets the curve at A and B. Find the exact length AB, in the form m√r with r as small as possible."}
	_reps(rep, s, out, "The line y = %s meets the curve y = %s at A and B." % [line_rhs(s), curve_rhs(s)])
	if rep == "graph":
		out.lines = shown(s) + ["The sketch shows the line meeting the curve at A and B."]
	var dy: Q = s.m.mul(dx)
	var dist := "Δx = %s and Δy = %s × %s = %s, so AB = √(%s² + %s²) = √%s = %s" % [N(dx), N(s.m), N(dx), N(dy), N(dx), Fmt.paren(dy), N(dx * dx * r), Answer.surd_text(sv[0], sv[1])]
	var c := eq_coeffs(s)
	var fs := QuadraticViews.formula_steps(c[0], c[1], c[2])
	var h: Q = s.x1.add(s.x2).div(2)
	var half: Q = s.x2.sub(s.x1).div(2)
	var res: Dictionary = ans.values
	var s0 := simplify_surd(1, dx * dx)
	out.generic = [{"m": Q.new(dx), "r": Q.new(1)}, {"m": Q.new(dx * dx), "r": Q.new(r)}, {"m": Q.new(sv[0]), "r": Q.new(sv[1] + 1)},
		{"m": Q.new(1), "r": Q.new(dx * dx + absi(dy.n))}, {"m": Q.new(s0[0] * 2), "r": Q.new(r)}]
	out.methods = {
		"quadratic-formula": {"result": res, "steps": [equate_step(s), Step.text(fs.steps[0]) + ", so x = " + Step.text(fs.steps[3]).trim_prefix("x = "), dist, final]},
		"complete-square": {"result": res, "steps": [equate_step(s),
			"Complete the square: %s(x%s)² = %s, so x = %s ± %s" % [Fmt.lead(s.a), Fmt.plus(h.neg()) if not h.is_zero() else "", N(s.a.mul(half.sq())), N(h), N(half)],
			dist, final]},
	}
	return out


func u_normal_meets_again(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("point", {"x": s.qx, "y": s.qy})
	var final := "So Q is " + Answer.text(ans) + "."
	var P := Fmt.point(s.px, s.py)
	var out := {"answer": ans, "given": given_of(s).merged({"P": [s.px.key(), s.py.key()]}),
		"asked": "The normal meets the curve again at Q. Find the coordinates of Q."}
	if rep == "words":
		out.lines = ["The normal to the curve y = %s at P%s is the line y = %s." % [curve_rhs(s), P, line_rhs(s)]]
	else:
		out.lines = ["Curve: y = " + curve_rhs(s), "Normal at P%s: y = %s" % [P, line_rhs(s)]]
	var c := eq_coeffs(s)
	var res: Dictionary = ans.values
	out.generic = [{"x": s.qx.neg(), "y": s.qy}, {"x": s.qx, "y": s.qy.neg()}, {"x": s.qx, "y": CurveLineSituation.curve_at(s, s.qx.neg())},
		{"x": s.qy, "y": s.qx}, {"x": s.qx.add(1), "y": s.m.mul(s.qx.add(1)).add(s.n)}]
	var qy := "y = %s × %s%s = %s" % [N(s.m), Fmt.paren(s.qx), Fmt.plus(s.n), N(s.qy)]
	out.methods = {
		"equate-and-solve": {"result": res, "steps": [equate_step(s), factor_step(s),
			"x = %s is P, so Q has x = %s and %s" % [N(s.px), N(s.qx), qy], final]},
		"factorise": {"result": res, "steps": [
			"P is on both, so x = %s is a root of %s: (x%s) is a factor." % [N(s.px), eq_text(s), Fmt.plus(s.px.neg()) if not s.px.is_zero() else ""],
			"%s = %s(x%s)(x%s)" % [Fmt.general(c[0], c[1], c[2]), Fmt.lead(s.a), Fmt.plus(s.px.neg()) if not s.px.is_zero() else "", Fmt.plus(s.qx.neg()) if not s.qx.is_zero() else ""],
			"The other root is x = %s, and %s" % [N(s.qx), qy], final]},
	}
	return out


func u_line_from_meeting_points(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("line", {"m": s.m, "c": s.n})
	var final := "So the line is " + Answer.text(ans) + "."
	var out := {"answer": ans, "given": given_of(s).merged({"xs": [s.x1.key(), s.x2.key()]}), "asked": "Find the equation of the line."}
	if rep == "words":
		out.lines = ["A line meets the curve y = %s at the points where x = %s and x = %s." % [curve_rhs(s), N(s.x1), N(s.x2)]]
	else:
		out.lines = ["Curve: y = " + curve_rhs(s), "A line meets the curve at x = %s and x = %s." % [N(s.x1), N(s.x2)]]
	out.generic = [{"m": Q.new(1).div(s.m), "c": s.n}, {"m": s.m, "c": s.n.neg()}, {"m": s.m.neg(), "c": s.n}, {"m": s.m.neg(), "c": s.n.neg()},
		{"m": s.m, "c": s.y1}]
	out.methods = {"two-point-formula": {"result": ans.values, "steps": [
		"On the curve: at x = %s, y = %s; at x = %s, y = %s" % [N(s.x1), N(s.y1), N(s.x2), N(s.y2)],
		"Gradient m = (%s − %s)/(%s − %s) = %s" % [N(s.y2), Fmt.paren(s.y1), N(s.x2), Fmt.paren(s.x1), N(s.m)],
		"y − %s = %s(x − %s), so n = %s − %s × %s = %s" % [Fmt.paren(s.y1), N(s.m), Fmt.paren(s.x1), N(s.y1), N(s.m), Fmt.paren(s.x1), N(s.n)],
		final]}}
	return out


func u_intercept_from_one_point(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	# One meeting point is given; which one is the seed's choice.
	var first := rng.chance(0.5)
	var gx: Q = s.x1 if first else s.x2
	var gy: Q = s.y1 if first else s.y2
	var ox: Q = s.x2 if first else s.x1
	var oy: Q = s.y2 if first else s.y1
	var ans := Answer.make("npoint", {"n": s.n, "x": ox, "y": oy})
	var final := "So " + Answer.text(ans) + "."
	var line := Fmt.poly([s.m, 0]) + " + n"
	var out := {"answer": ans, "given": given_of(s).merged({"x_given": gx.key()}),
		"asked": "Find n, and the coordinates of the other point where the line meets the curve."}
	if rep == "words":
		out.lines = ["The line y = %s meets the curve y = %s where x = %s, and at one other point." % [line, curve_rhs(s), N(gx)]]
	else:
		out.lines = ["Curve: y = " + curve_rhs(s), "Line: y = " + line, "They meet where x = %s." % N(gx)]
	out.generic = [{"n": s.n.neg(), "x": ox, "y": oy}, {"n": s.n, "x": ox.neg(), "y": oy}, {"n": s.n, "x": ox, "y": oy.neg()},
		{"n": gy, "x": ox, "y": oy}]
	out.methods = {"equate-and-solve": {"result": ans.values, "steps": [
		"At x = %s the curve has y = %s" % [N(gx), N(gy)],
		"The line passes through %s: %s = %s × %s + n, so n = %s" % [Fmt.point(gx, gy), N(gy), N(s.m), Fmt.paren(gx), N(s.n)],
		equate_step(s), factor_step(s) + "; the other point is %s" % Fmt.point(ox, oy), final]}}
	return out


func u_count_from_sketch(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var count := 0
	match s.mode:
		"int":
			count = 2
		"tangent":
			count = 1
	var ans := Answer.make("number", {"v": Q.new(count)}, {}, "Number of meeting points: ")
	var c := eq_coeffs(s)
	var disc: Q = c[1].sq().sub(c[0].mul(c[2]).mul(4))
	var marks: Array = []
	var labels: Array = []
	var bounds: Array = []
	var hidden := false
	if count >= 1:
		marks = [[s.x1, s.y1]] if count == 1 else [[s.x1, s.y1], [s.x2, s.y2]]
		labels = ["", ""].slice(0, marks.size())
		if count == 2 and s.x2.sub(s.x1).n >= 3 and rng.chance(0.5):
			# The window stops short of the second point.
			hidden = true
			var x1i: int = s.x1.n
			var hx: int = x1i + (s.x2.n - x1i) / 2
			var lo := mini(x1i - 3, -1)
			var ys: Array = []
			for x in range(lo, hx + 1):
				ys.append(CurveLineSituation.curve_at(s, x).to_float())
				ys.append(s.m.mul(x).add(s.n).to_float())
			bounds = [lo, hx, floori(ys.min()) - 1, ceili(ys.max()) + 1]
			marks = [[s.x1, s.y1]]
			labels = [""]
	var g := sketch(s, marks, labels, bounds)
	g.points = []
	var seen := "The sketch shows %s meeting point%s." % [["no", "one", "two"][count if not hidden else 1], "" if (count if not hidden else 1) == 1 else "s"]
	var final := "So " + Answer.text(ans) + "."
	var alg := "Check with algebra: %s has Δ = %s, %s" % [eq_text(s), N(disc), ["so no real roots", "so one repeated root", "so two real roots"][count]]
	var out := {"answer": ans, "given": given_of(s), "graph": g,
		"lines": shown(s) + ["The sketch shows part of the curve and the line."],
		"asked": "How many points do the curve and the line meet at? Confirm with algebra."}
	var wrongs: Array = []
	if hidden:
		wrongs.append(wrong({"v": Q.new(1)}, "SL2.4.intersection#1"))
	out.wrongs = wrongs
	out.generic = [0, 1, 2, 3].filter(func(v): return v != count).map(func(v): return {"v": Q.new(v)})
	out.methods = {
		"sketch-and-count": {"result": ans.values, "steps": [seen, alg + (", so the second point is off the window" if hidden else ""), final]},
		"graph-check": {"result": ans.values, "steps": [alg, "Zoom out on the GDC graph so every meeting point shows.", final]},
	}
	return out
