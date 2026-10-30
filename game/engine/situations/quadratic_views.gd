class_name QuadraticViews
extends RefCounted
## The views on the `quadratic` situation: one builder per unknown of the three types
## built on it (fn-quadratic-features, fn-quadratic-from-conditions and
## fn-concept-quadratic-forms in curriculum/question-types.json).
##
## A builder takes the representation, the situation and the seeded stream and returns
##   asked     what the question asks (the engine adds the method line)
##   lines     text shown above the answer: the equation, the words, or a caption
##   graph     a parabola to draw (or null): curve, labelled points, an axis line, bounds
##   table     {"xs": [...], "ys": [...]} (or null)
##   given     the given quantities, as plain data, for the SymPy checker
##   answer    an Answer (answer.gd)
##   wrongs    misconception distractors: [{"values": {...}, "ref": "SL2.6.vertex#0"}]
##   generic   other wrong options, used when the misconceptions don't give three
##   trap      the rounding trap (Answer.rounding_trap), {} where it doesn't fit
##   methods   angle (method id) -> {"steps": [...], "result": values}. Each method
##             works the answer out again from the givens, and its last step states it.
##             "any" when no listed method suits the unknown.

const NEED := {
	"roots-from-factorised": {"mode": "rational"},
	"y-intercept-from-factorised": {"mode": "rational", "a_not_one": true},
	"y-intercept-from-vertex-form": {"mode": "any", "even": true},
	"axis-from-roots": {"mode": "rational", "even": true},
	"axis-from-vertex": {"mode": "any", "even": true},
	"axis-from-general": {"mode": "any", "even": true},
	"axis-from-equal-outputs": {"mode": "any", "even": true},
	"second-root-from-axis": {"mode": "rational", "even": true},
	"b-from-axis": {"mode": "any", "even": true},
	"vertex-from-vertex-form": {"mode": "any", "even": true},
	"vertex-from-factorised": {"mode": "rational", "even": true},
	"vertex-from-general": {"mode": "any", "even": true},
	"vertex-from-table": {"mode": "any", "even": true},
	"max-or-min": {"mode": "any", "even": true},
	"h-k-from-vertex": {"mode": "any", "even": true},
	"vertex-form-from-general": {"mode": "any", "even": true},
	"vertex-form-from-factorised": {"mode": "rational", "even": true},
	"general-from-vertex-form": {"mode": "any", "even": true},
	"factorised-from-general": {"mode": "rational", "a_not_one": true},
	"factorised-from-vertex-form": {"mode": "rational", "even": true},
	"vertex-form-from-vertex-and-a": {"mode": "any", "even": true},
	"a-from-vertex-and-point": {"mode": "any", "even": true, "point": true, "a_not_one": true},
	"equation-from-vertex-and-root": {"mode": "rational", "even": true},
	"a-from-roots-and-point": {"mode": "rational", "point": true, "a_not_one": true},
	"coefficients-from-roots": {"mode": "rational", "a_not_one": true},
	"coefficient-from-axis": {"mode": "any", "even": true},
	"coefficients-from-two-points-and-axis": {"mode": "any", "even": true, "no_halves": true},
	"range-after-finding": {"mode": "rational", "even": true, "point": true, "point_off_axis": true},
	"coefficients-from-three-points": {"mode": "any", "even": true, "no_halves": true},
	"coefficient-from-point": {"mode": "any", "even": true, "point": true, "point_off_axis": true},
	"equation-from-table": {"mode": "any", "even": true, "a_not_one": true},
	"match-three-forms": {"mode": "rational", "even": true, "a_not_one": true},
	"form-for-feature": {"mode": "rational", "even": true, "a_not_one": true},
	"form-for-task": {"mode": "rational", "even": true, "a_not_one": true},
	"missing-form": {"mode": "none"},
}


func has(unknown: String) -> bool:
	return NEED.has(unknown)


## What the situation must satisfy for this view.
func need(unknown: String, rep: String) -> Dictionary:
	var n: Dictionary = NEED[unknown].duplicate()
	if rep == "graph":
		n.graph = true
	if rep == "table":
		n.no_halves = true
		if unknown in ["a-from-roots-and-point"]:
			n.table = "roots"
		elif unknown not in ["coefficients-from-two-points-and-axis"]:
			n.table = true
	return n


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


static func P(v: Variant) -> String:
	return Fmt.paren(v)


static func q(v: Variant, den: int = 1) -> Q:
	return Q.of(v, den)


static func gen_line(s: Dictionary) -> String:
	return "f(x) = " + Fmt.general(s.a, s.b, s.c)


static func fac_line(s: Dictionary) -> String:
	return "f(x) = " + Fmt.factorised(s.a, s.p, s.q)


static func ver_line(s: Dictionary) -> String:
	return "f(x) = " + Fmt.vertex(s.a, s.h, s.k)


static func given_form(form: String, s: Dictionary) -> Dictionary:
	match form:
		"general":
			return {"form": "general", "a": s.a.key(), "b": s.b.key(), "c": s.c.key()}
		"factorised":
			return {"form": "factorised", "a": s.a.key(), "p": s.p.key(), "q": s.q.key()}
		_:
			return {"form": "vertex", "a": s.a.key(), "h": s.h.key(), "k": s.k.key()}


## A linear expression in letters: lin([9, -3, 1], ["a", "b", "c"]) is "9a − 3b + c".
static func lin(coeffs: Array, names: Array) -> String:
	var out := ""
	for i in coeffs.size():
		var c := Q.of(coeffs[i])
		if c.is_zero():
			continue
		var body: String = Fmt.lead(c.abs_q()) + names[i]
		if out == "":
			out = ("−" if c.sign() < 0 else "") + body
		else:
			out += (" − " if c.sign() < 0 else " + ") + body
	return out if out != "" else "0"


## ax² + bx + c with x put in, keeping the letters in `letters` as unknowns:
## subst({"a": ½, "b": −2}, ["c"], −2) is "½(−2)² − 2(−2) + c".
static func subst(known: Dictionary, letters: Array, x: Q) -> String:
	var out := ""
	for key in ["a", "b", "c"]:
		var tail: String = {"a": "(%s)²" % N(x), "b": "(%s)" % N(x), "c": ""}[key]
		var body := ""
		var neg := false
		if key in letters:
			body = key + tail
		else:
			var c: Q = known[key]
			if c.is_zero():
				continue
			neg = c.sign() < 0
			body = (Fmt.lead(c.abs_q()) + tail) if tail != "" else c.abs_q().text()
		if out == "":
			out = ("−" if neg else "") + body
		else:
			out += (" − " if neg else " + ") + body
	return out


static func pt(x: Variant, y: Variant) -> Array:
	return [q(x).key(), q(y).key()]


static func wrong(values: Dictionary, ref: String = "") -> Dictionary:
	return {"values": values, "ref": ref}


## A parabola to draw, with the given points labelled and bounds that hold them all.
static func graph(s: Dictionary, points: Array, axis: bool = false, caption: String = "") -> Dictionary:
	var xs: Array = [s.h.to_float(), 0.0]
	var ys: Array = [s.k.to_float(), 0.0]
	var pts: Array = []
	for p in points:
		xs.append(q(p[0]).to_float())
		ys.append(q(p[1]).to_float())
		pts.append({"x": q(p[0]).to_float(), "y": q(p[1]).to_float(), "label": Fmt.point(p[0], p[1])})
	if s.p != null:
		xs.append(s.p.to_float())
		xs.append(s.q.to_float())
	var x0 := floori(xs.min()) - 2
	var x1 := ceili(xs.max()) + 2
	var y0 := floori(ys.min()) - 2
	var y1 := ceili(ys.max()) + 2
	return {"a": s.a.to_float(), "h": s.h.to_float(), "k": s.k.to_float(), "points": pts,
		"axis": s.h.to_float() if axis else null, "axis_label": "x = " + N(s.h) if axis else "",
		"x0": x0, "x1": x1, "y0": y0, "y1": y1, "caption": caption}


static func table_of(xs: Array, ys: Array) -> Dictionary:
	return {"xs": xs.map(func(e): return Q.of(e)), "ys": ys.map(func(e): return Q.of(e))}


static func table_given(t: Dictionary) -> Dictionary:
	return {"xs": t.xs.map(func(e): return e.key()), "ys": t.ys.map(func(e): return e.key())}


## Completing the square on ax² + bx + c. Returns {"steps", "h", "k"}.
static func cs_steps(a: Q, b: Q, c: Q) -> Dictionary:
	var h := b.neg().div(a.mul(2))
	var hh := h.sq()
	var k := c.sub(a.mul(hh))
	var st: Array = ["f(x) = " + Fmt.general(a, b, c)]
	var sq := Fmt.factor(h) + "²"
	if a.eq(1):
		st.append("Half of %s is %s, so x²%s = %s − %s" % [N(b), N(b.div(2)), Fmt.term(b, 1, false), sq, N(hh)])
		st.append("f(x) = %s − %s%s" % [sq, N(hh), Fmt.plus(c)])
	else:
		st.append("Take out a = %s from the x terms: f(x) = %s(%s)%s" % [N(a), Fmt.lead(a), Fmt.poly([1, b.div(a), 0]), Fmt.plus(c)])
		st.append("Half of %s is %s, so %s = %s − %s" % [N(b.div(a)), N(b.div(a).div(2)), Fmt.poly([1, b.div(a), 0]), sq, N(hh)])
		st.append("f(x) = %s[%s − %s]%s" % [Fmt.lead(a), sq, N(hh), Fmt.plus(c)])
		st.append("f(x) = %s%s%s%s" % [Fmt.lead(a), sq, Fmt.plus(a.mul(hh).neg()), Fmt.plus(c)])
	st.append("f(x) = " + Fmt.vertex(a, h, k))
	return {"steps": st, "h": h, "k": k}


## Expanding a(x − h)² + k. Returns {"steps", "b", "c"}.
static func expand_vertex_steps(a: Q, h: Q, k: Q) -> Dictionary:
	var b := a.mul(h).mul(-2)
	var c := a.mul(h.sq()).add(k)
	var inner := Fmt.poly([1, h.mul(-2), h.sq()])
	var st: Array = ["%s² = %s" % [Fmt.factor(h), inner]]
	if a.eq(1):
		st.append("f(x) = %s%s" % [inner, Fmt.plus(k)])
	else:
		st.append("f(x) = %s(%s)%s" % [Fmt.lead(a), inner, Fmt.plus(k)])
		st.append("f(x) = %s%s" % [Fmt.poly([a, a.mul(h).mul(-2), a.mul(h.sq())]), Fmt.plus(k)])
	st.append("f(x) = " + Fmt.general(a, b, c))
	return {"steps": st, "b": b, "c": c}


## Expanding a(x − p)(x − q). Returns {"steps", "b", "c"}.
static func expand_factorised_steps(a: Q, p: Q, r: Q) -> Dictionary:
	var inner := Fmt.poly([1, p.add(r).neg(), p.mul(r)])
	var st: Array = ["%s%s = %s" % [Fmt.factor(p), Fmt.factor(r), inner]]
	var b := a.mul(p.add(r)).neg()
	var c := a.mul(p).mul(r)
	if not a.eq(1):
		st.append("f(x) = %s(%s)" % [Fmt.lead(a), inner])
	st.append("f(x) = " + Fmt.general(a, b, c))
	return {"steps": st, "b": b, "c": c}


## The roots of ax² + bx + c by the quadratic formula (Δ a perfect square here).
static func formula_steps(a: Q, b: Q, c: Q) -> Dictionary:
	var disc := b.sq().sub(a.mul(c).mul(4))
	# √(n/d) for a rational square: both n and d are squares.
	var root := Q.new(int(round(sqrt(float(disc.n)))), int(round(sqrt(float(disc.d)))))
	var r1 := b.neg().sub(root).div(a.mul(2))
	var r2 := b.neg().add(root).div(a.mul(2))
	var st: Array = [
		"Δ = b² − 4ac = %s² − 4 × %s × %s = %s" % [P(b), P(a), P(c), N(disc)],
		"√Δ = %s" % N(root),
		"x = (−b ± √Δ)/(2a) = (%s ± %s)/%s" % [N(b.neg()), N(root), P(a.mul(2))],
		"x = %s or x = %s" % [N(r1), N(r2)],
	]
	return {"steps": st, "r1": r1, "r2": r2}


# ── fn-quadratic-features ────────────────────────────────────

func u_roots_from_factorised(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("roots", {"r1": s.p, "r2": s.q})
	var st: Array = []
	if not s.a.eq(1):
		st.append("%s is never 0, so f(x) = 0 only when a bracket is 0." % N(s.a))
	else:
		st.append("f(x) = 0 when one of the brackets is 0.")
	st.append("%s = 0 gives x = %s" % [Fmt.factor(s.p).trim_prefix("(").trim_suffix(")"), N(s.p)])
	st.append("%s = 0 gives x = %s" % [Fmt.factor(s.q).trim_prefix("(").trim_suffix(")"), N(s.q)])
	var res := {"r1": s.p, "r2": s.q}
	st.append("So the x-intercepts are " + Answer.text(ans, res) + ".")
	return {
		"asked": "Find the x-coordinates where the graph of y = f(x) crosses the x-axis.",
		"lines": [fac_line(s)], "given": given_form("factorised", s), "answer": ans,
		"wrongs": [wrong({"r1": s.p.neg(), "r2": s.q.neg()}, "SL2.6.factorised-form#0")],
		"generic": [{"r1": s.p, "r2": s.q.neg()}, {"r1": s.p.neg(), "r2": s.q}, {"r1": s.p.mul(s.a), "r2": s.q.mul(s.a)}],
		"methods": {"factorise": {"steps": st, "result": res}},
	}


func u_y_intercept_from_factorised(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("yint", {"y": s.c})
	var y0: Q = s.a.mul(s.p.neg()).mul(s.q.neg())
	var res := {"y": y0}
	var st: Array = [
		"The y-intercept is where x = 0.",
		"f(0) = %s(0%s)(0%s) = %s × %s × %s = %s" % [Fmt.lead(s.a) if not s.a.eq(-1) else "−", Fmt.plus(s.p.neg()), Fmt.plus(s.q.neg()), N(s.a), P(s.p.neg()), P(s.q.neg()), N(y0)],
		"So the y-intercept is " + Answer.text(ans, res) + ".",
	]
	return {
		"asked": "Find the y-intercept of the graph of y = f(x).",
		"lines": [fac_line(s)], "given": given_form("factorised", s), "answer": ans,
		"wrongs": [wrong({"y": s.p.mul(s.q)}, "SL2.6.factorised-form#2")],
		"generic": [{"y": s.c.neg()}, {"y": s.p.add(s.q).mul(s.a)}, {"y": s.p.mul(s.q).neg()}],
		"methods": {"any": {"steps": st, "result": res}},
	}


func u_y_intercept_from_vertex_form(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("yint", {"y": s.c})
	var y0: Q = s.a.mul(s.h.sq()).add(s.k)
	var res := {"y": y0}
	var st: Array = [
		"The y-intercept is where x = 0.",
		"f(0) = %s(0%s)²%s = %s%s = %s" % [Fmt.lead(s.a), Fmt.plus(s.h.neg()), Fmt.plus(s.k), N(s.a.mul(s.h.sq())), Fmt.plus(s.k), N(y0)],
		"So the y-intercept is " + Answer.text(ans, res) + ".",
	]
	return {
		"asked": "Find the y-intercept of the graph of y = f(x).",
		"lines": [ver_line(s)], "given": given_form("vertex", s), "answer": ans,
		"generic": [{"y": s.k}, {"y": s.h.sq().add(s.k)}, {"y": s.a.mul(s.h.sq()).sub(s.k)}, {"y": s.a.mul(s.h).add(s.k)}],
		"methods": {"any": {"steps": st, "result": res}},
	}


func u_axis_from_roots(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("axis", {"var": "x", "h": s.h})
	var out := {"asked": "Find the equation of the axis of symmetry of the graph of y = f(x).", "answer": ans,
		"given": {"roots": [s.p.key(), s.q.key()]}}
	match rep:
		"equation":
			out.lines = [fac_line(s)]
			out.given.merge(given_form("factorised", s))
		"graph":
			out.graph = graph(s, [[s.p, 0], [s.q, 0]])
			out.lines = ["The graph of y = f(x) is shown."]
		"words":
			out.lines = ["The graph of a quadratic function f crosses the x-axis at x = %s and x = %s." % [N(s.p), N(s.q)]]
	var h: Q = s.p.add(s.q).div(2)
	var res := {"var": "x", "h": h}
	out.methods = {"midpoint-of-roots": {"result": res, "steps": [
		"The roots are x = %s and x = %s. The axis is halfway between them." % [N(s.p), N(s.q)],
		"x = (%s%s)/2 = %s/2 = %s" % [N(s.p), Fmt.plus(s.q), N(s.p.add(s.q)), N(h)],
		"So the axis of symmetry is " + Answer.text(ans, res) + "."]}}
	out.wrongs = [wrong({"var": "y", "h": s.h}, "SL2.6.axis-symmetry#1")]
	out.generic = [{"var": "x", "h": s.h.neg()}, {"var": "x", "h": s.q.sub(s.p).div(2)}, {"var": "y", "h": s.h.neg()}]
	return out


func u_axis_from_vertex(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("axis", {"var": "x", "h": s.h})
	var out := {"asked": "Find the equation of the axis of symmetry of the graph of y = f(x).", "answer": ans,
		"given": {"vertex": pt(s.h, s.k)}}
	var st: Array = []
	match rep:
		"equation":
			out.lines = [ver_line(s)]
			out.given.merge(given_form("vertex", s))
			st.append("In a(x − h)² + k the axis is x = h.")
			if s.h.sign() < 0:
				st.append("%s is x − (%s), so h = %s." % [Fmt.factor(s.h), N(s.h), N(s.h)])
			else:
				st.append("The bracket is %s, so h = %s." % [Fmt.factor(s.h), N(s.h)])
		"graph":
			out.graph = graph(s, [[s.h, s.k]])
			out.lines = ["The graph of y = f(x) is shown, with its vertex marked."]
			st.append("The axis of symmetry is the vertical line through the vertex %s." % Fmt.point(s.h, s.k))
		"words":
			out.lines = ["The graph of a quadratic function f has its vertex at %s." % Fmt.point(s.h, s.k)]
			st.append("The axis of symmetry is the vertical line through the vertex %s." % Fmt.point(s.h, s.k))
	var res := {"var": "x", "h": s.h}
	st.append("So the axis of symmetry is " + Answer.text(ans, res) + ".")
	out.methods = {"vertex-form-read": {"steps": st, "result": res}}
	out.wrongs = [wrong({"var": "y", "h": s.h}, "SL2.6.axis-symmetry#1"), wrong({"var": "x", "h": s.h.neg()}, "SL2.6.axis-symmetry#2")]
	out.generic = [{"var": "x", "h": s.k}, {"var": "y", "h": s.k}]
	return out


func u_axis_from_general(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("axis", {"var": "x", "h": s.h})
	var a: Q = s.a
	var b: Q = s.b
	var h := b.neg().div(a.mul(2))
	var res := {"var": "x", "h": h}
	var cs := cs_steps(a, b, s.c)
	var cs_st: Array = cs.steps.duplicate()
	cs_st.append("In a(x − h)² + k the axis is x = h, so h = %s." % N(cs.h))
	cs_st.append("So the axis of symmetry is " + Answer.text(ans, {"var": "x", "h": cs.h}) + ".")
	var d1 := a.mul(2)
	return {
		"asked": "Find the equation of the axis of symmetry of the graph of y = f(x).",
		"lines": [gen_line(s)], "given": given_form("general", s), "answer": ans,
		"wrongs": [wrong({"var": "x", "h": s.h.neg()}, "SL2.6.axis-symmetry#0")],
		"generic": [{"var": "y", "h": s.h}, {"var": "x", "h": b.neg().div(a)}, {"var": "x", "h": s.c.neg().div(b)}],
		"methods": {
			"minus-b-over-2a": {"result": res, "steps": [
				"a = %s and b = %s." % [N(a), N(b)],
				"x = −b/(2a) = %s/(2 × %s) = %s/%s = %s" % [P(b.neg()), P(a), N(b.neg()), N(d1), N(h)],
				"So the axis of symmetry is " + Answer.text(ans, res) + "."]},
			"vertex-form-read": {"result": {"var": "x", "h": cs.h}, "steps": cs_st},
			"derivative-zero": {"result": res, "steps": [
				"f′(x) = %s" % Fmt.poly([d1, b]),
				"f′(x) = 0 gives x = %s" % N(h) if d1.eq(1) else "f′(x) = 0 gives %sx = %s, so x = %s" % [Fmt.lead(d1), N(b.neg()), N(h)],
				"The turning point is on the axis, so the axis of symmetry is " + Answer.text(ans, res) + "."]},
		},
	}


func u_axis_from_equal_outputs(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := Answer.make("axis", {"var": "x", "h": s.h})
	var out := {"asked": "Find the equation of the axis of symmetry of the graph of y = f(x).", "answer": ans}
	var d := 0
	var x1: Q
	var x2: Q
	var y: Q
	if rep == "table":
		out.table = table_of(s.xs, s.ys)
		out.given = {"table": table_given(out.table)}
		out.lines = ["The table shows some values of a quadratic function f."]
		# The widest symmetric pair the table shows.
		for dd in [3, 2, 1]:
			if not s.h.sub(dd).lt(s.xs[0]) and not s.xs[6].lt(s.h.add(dd)):
				d = dd
				break
	else:
		var opts: Array = []
		for dd in [1, 2, 3, 4]:
			var yy := QuadraticSituation.f(s, s.h.add(dd))
			if yy.is_int() and absi(yy.n) <= QuadraticSituation.GRAPH_Y_MAX and not yy.is_zero():
				opts.append(dd)
		d = opts[rng.int_in(0, opts.size() - 1)] if not opts.is_empty() else 1
	x1 = s.h.sub(d)
	x2 = s.h.add(d)
	y = QuadraticSituation.f(s, x1)
	if rep == "graph":
		out.graph = graph(s, [[x1, y], [x2, y]])
		out.lines = ["The graph of y = f(x) passes through the two marked points."]
		out.given = {"points": [pt(x1, y), pt(x2, y)]}
	var h := x1.add(x2).div(2)
	var res := {"var": "x", "h": h}
	out.methods = {"midpoint-of-roots": {"result": res, "steps": [
		"f(%s) = f(%s) = %s: two inputs give the same output, so they are mirror images in the axis." % [N(x1), N(x2), N(y)],
		"x = (%s%s)/2 = %s" % [N(x1), Fmt.plus(x2), N(h)],
		"So the axis of symmetry is " + Answer.text(ans, res) + "."]}}
	out.generic = [{"var": "y", "h": s.h}, {"var": "x", "h": y}, {"var": "x", "h": s.h.neg()}, {"var": "y", "h": y}]
	return out


func u_second_root_from_axis(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var first := rng.chance(0.5)
	var r: Q = s.p if first else s.q
	var other: Q = s.q if first else s.p
	var ans := Answer.make("xval", {"v": other})
	var out := {"asked": "Find the other root of f(x) = 0.", "answer": ans, "given": {"root": r.key(), "axis": s.h.key()}}
	match rep:
		"equation":
			out.lines = ["f(%s) = 0" % N(r), "The axis of symmetry of y = f(x) is x = %s." % N(s.h)]
		"graph":
			out.graph = graph(s, [[r, 0]], true)
			out.lines = ["The graph of y = f(x) crosses the x-axis at the marked point. The dashed line is its axis of symmetry."]
		"words":
			out.lines = ["A parabola crosses the x-axis at x = %s. Its axis of symmetry is x = %s." % [N(r), N(s.h)]]
	var v: Q = s.h.mul(2).sub(r)
	var res := {"v": v}
	out.methods = {"midpoint-of-roots": {"result": res, "steps": [
		"The axis is halfway between the two roots, so (%s + r)/2 = %s, where r is the other root." % [N(r), N(s.h)],
		"%s + r = %s" % [N(r), N(s.h.mul(2))],
		"r = %s%s = %s" % [N(s.h.mul(2)), Fmt.plus(r.neg()), N(v)],
		"So the other root is " + Answer.text(ans, res) + "."]}}
	out.generic = [{"v": s.h.sub(r)}, {"v": s.h.mul(2).add(r)}, {"v": r.neg()}, {"v": s.h.add(r)}]
	return out


func u_b_from_axis(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("number", {"v": s.b}, {}, "b = ")
	var out := {"asked": "Find the value of b.", "answer": ans, "given": {"a": s.a.key(), "c": s.c.key(), "axis": s.h.key()}}
	if rep == "equation":
		out.lines = ["f(x) = %sx² + bx%s" % [Fmt.lead(s.a), Fmt.plus(s.c)], "The axis of symmetry of y = f(x) is x = %s." % N(s.h)]
	else:
		out.lines = ["f(x) = ax² + bx + c, where a = %s and c = %s. The axis of symmetry of its graph is x = %s." % [N(s.a), N(s.c), N(s.h)]]
	var b: Q = s.a.mul(s.h).mul(-2)
	var res := {"v": b}
	out.methods = {"minus-b-over-2a": {"result": res, "steps": [
		"The axis is x = −b/(2a), so −b/(2 × %s) = %s." % [P(s.a), N(s.h)],
		"−b = %s × %s = %s" % [N(s.a.mul(2)), P(s.h), N(b.neg())],
		"So " + Answer.text(ans, res) + "."]}}
	out.generic = [{"v": b.neg()}, {"v": s.a.mul(s.h).neg()}, {"v": s.h.mul(-2)}, {"v": s.h.neg().div(s.a.mul(2))}]
	return out


func u_vertex_from_vertex_form(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("point", {"x": s.h, "y": s.k})
	var res := {"x": s.h, "y": s.k}
	var st: Array = ["a(x − h)² + k is y = ax² translated by the vector (h, k), so its vertex is (h, k)."]
	if s.h.sign() < 0:
		st.append("%s² is (x − (%s))², so h = %s, and k = %s." % [Fmt.factor(s.h), N(s.h), N(s.h), N(s.k)])
	else:
		st.append("Here h = %s and k = %s." % [N(s.h), N(s.k)])
	st.append("So the vertex is " + Answer.text(ans, res) + ".")
	return {
		"asked": "Write down the coordinates of the vertex of the graph of y = f(x).",
		"lines": [ver_line(s)], "given": given_form("vertex", s), "answer": ans,
		"wrongs": [wrong({"x": s.h.neg(), "y": s.k}, "SL2.6.vertex#0")],
		"generic": [{"x": s.h, "y": s.k.neg()}, {"x": s.k, "y": s.h}, {"x": s.h.neg(), "y": s.k.neg()}],
		"methods": {"read-vertex-form": {"steps": st, "result": res}},
	}


func u_vertex_from_factorised(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("point", {"x": s.h, "y": s.k})
	var out := {"asked": "Find the coordinates of the vertex of the graph of y = f(x).", "answer": ans}
	var pre: Array = []
	var a: Q = s.a
	if rep == "graph":
		out.graph = graph(s, [[s.p, 0], [s.q, 0], [0, s.c]])
		out.lines = ["The graph of a quadratic function y = f(x) is shown."]
		out.given = {"roots": [s.p.key(), s.q.key()], "yint": s.c.key()}
		a = s.c.div(s.p.mul(s.q))
		pre = ["The roots are %s and %s, so f(x) = a%s%s." % [N(s.p), N(s.q), Fmt.factor(s.p), Fmt.factor(s.q)],
			"The y-intercept gives f(0) = a × %s × %s = %s, so a = %s." % [P(s.p.neg()), P(s.q.neg()), N(s.c), N(a)]]
	else:
		out.lines = [fac_line(s)]
		out.given = given_form("factorised", s)
	var h: Q = s.p.add(s.q).div(2)
	var k := a.mul(h.sub(s.p)).mul(h.sub(s.q))
	var res := {"x": h, "y": k}
	var mid: Array = pre.duplicate()
	mid.append_array([
		"The vertex is on the axis, halfway between the roots: x = (%s%s)/2 = %s" % [N(s.p), Fmt.plus(s.q), N(h)],
		"f(%s) = %s(%s%s)(%s%s) = %s" % [N(h), Fmt.lead(a) if not a.eq(-1) else "−", N(h), Fmt.plus(s.p.neg()), N(h), Fmt.plus(s.q.neg()), N(k)],
		"So the vertex is " + Answer.text(ans, res) + "."])
	var ex := expand_factorised_steps(a, s.p, s.q)
	var hf: Q = ex.b.neg().div(a.mul(2))
	var kf := a.mul(hf.sq()).add(ex.b.mul(hf)).add(ex.c)
	var form: Array = pre.duplicate()
	form.append("Expand: " + Step.text(ex.steps[0]))
	form.append(ex.steps[-1])
	form.append_array([
		"x = −b/(2a) = %s/%s = %s" % [P(ex.b.neg()), P(a.mul(2)), N(hf)],
		"f(%s) = %s × %s%s = %s" % [N(hf), N(a), P(hf.sq()), Fmt.plus(ex.b.mul(hf)) + Fmt.plus(ex.c), N(kf)],
		"So the vertex is " + Answer.text(ans, {"x": hf, "y": kf}) + "."])
	out.methods = {"midpoint-of-roots": {"steps": mid, "result": res}, "formula-then-substitute": {"steps": form, "result": {"x": hf, "y": kf}}}
	out.generic = [{"x": s.h, "y": s.k.neg()}, {"x": s.h.neg(), "y": s.k}, {"x": s.h, "y": s.c}, {"x": s.h, "y": s.k.div(s.a)}]
	return out


func u_vertex_from_general(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("point", {"x": s.h, "y": s.k})
	var a: Q = s.a
	var b: Q = s.b
	var c: Q = s.c
	var cs := cs_steps(a, b, c)
	var cs_st: Array = cs.steps.duplicate()
	cs_st.append("So the vertex is " + Answer.text(ans, {"x": cs.h, "y": cs.k}) + ".")
	var h := b.neg().div(a.mul(2))
	var k := a.mul(h.sq()).add(b.mul(h)).add(c)
	var res := {"x": h, "y": k}
	var sub := "f(%s) = %s × %s%s%s = %s" % [N(h), N(a), P(h.sq()), Fmt.plus(b.mul(h)), Fmt.plus(c), N(k)]
	return {
		"asked": "Find the coordinates of the vertex of the graph of y = f(x).",
		"lines": [gen_line(s)], "given": given_form("general", s), "answer": ans,
		"generic": [{"x": h.neg(), "y": k}, {"x": h, "y": c}, {"x": h, "y": k.neg()}, {"x": h.neg(), "y": k.neg()}],
		"methods": {
			"complete-square": {"steps": cs_st, "result": {"x": cs.h, "y": cs.k}},
			"formula-then-substitute": {"result": res, "steps": [
				"x = −b/(2a) = %s/(2 × %s) = %s" % [P(b.neg()), P(a), N(h)], sub,
				"So the vertex is " + Answer.text(ans, res) + "."]},
			"derivative-zero": {"result": res, "steps": [
				"f′(x) = %s" % Fmt.poly([a.mul(2), b]),
				"f′(x) = 0 gives x = %s" % N(h), sub,
				"So the vertex is " + Answer.text(ans, res) + "."]},
		},
	}


func u_vertex_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var kind := "minimum" if s.a.sign() > 0 else "maximum"
	var ans := Answer.make("vertex_kind", {"x": s.h, "y": s.k, "kind": kind})
	var t := table_of(s.xs, s.ys)
	var h: Q = s.h
	var y1 := QuadraticSituation.f(s, h.sub(1))
	var k := QuadraticSituation.f(s, h)
	var res := {"x": h, "y": k, "kind": kind}
	return {
		"asked": "Find the vertex of the graph of y = f(x), and say whether it is a maximum or a minimum.",
		"lines": ["The table shows some values of a quadratic function f."], "table": t,
		"given": {"table": table_given(t)}, "answer": ans,
		"generic": [{"x": h, "y": k, "kind": "maximum" if kind == "minimum" else "minimum"}, {"x": k, "y": h, "kind": kind},
			{"x": h.add(1), "y": QuadraticSituation.f(s, h.add(1)), "kind": kind}, {"x": h, "y": y1, "kind": kind}],
		"methods": {"midpoint-of-roots": {"result": res, "steps": [
			"f(%s) = f(%s) = %s, so the axis is halfway between: x = %s." % [N(h.sub(1)), N(h.add(1)), N(y1), N(h)],
			"The vertex is on the axis, and the table gives f(%s) = %s." % [N(h), N(k)],
			"The values %s either side of it, so it is a %s." % ["rise" if kind == "minimum" else "fall", kind],
			"So the vertex is " + Answer.text(ans, res) + "."]}},
	}


func u_max_or_min(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var kind := "minimum" if s.a.sign() > 0 else "maximum"
	var ans := Answer.make("maxmin", {"kind": kind, "k": s.k})
	var other := "maximum" if kind == "minimum" else "minimum"
	var out := {"asked": "Does f have a maximum or a minimum value? Find that value.", "answer": ans}
	var st: Array = []
	if rep == "graph":
		out.graph = graph(s, [[s.h, s.k]])
		out.lines = ["The graph of y = f(x) is shown, with its vertex marked."]
		out.given = {"vertex": pt(s.h, s.k), "opens": "up" if s.a.sign() > 0 else "down"}
		st.append("The parabola opens %s, so the vertex is its %s point." % ["upwards" if kind == "minimum" else "downwards", "lowest" if kind == "minimum" else "highest"])
	else:
		out.lines = [ver_line(s)]
		out.given = given_form("vertex", s)
		st.append("a = %s is %s, so the parabola opens %s and the vertex is its %s point." % [N(s.a), "positive" if kind == "minimum" else "negative", "upwards" if kind == "minimum" else "downwards", "lowest" if kind == "minimum" else "highest"])
	st.append("The vertex is %s." % Fmt.point(s.h, s.k))
	var res := {"kind": kind, "k": s.k}
	st.append("So f has a " + Answer.text(ans, res) + ".")
	out.methods = {"read-vertex-form": {"steps": st, "result": res}}
	out.wrongs = [wrong({"kind": other, "k": s.k}, "SL2.6.vertex#2")]
	out.generic = [{"kind": kind, "k": s.h}, {"kind": other, "k": s.h}, {"kind": kind, "k": s.k.neg()}]
	return out


func u_h_k_from_vertex(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("vertex_form_a", {"h": s.h, "k": s.k}, {"a": s.a})
	var out := {"asked": "f(x) = %s(x − h)² + k. Find h and k." % Fmt.lead(s.a), "answer": ans,
		"given": {"vertex": pt(s.h, s.k), "a": s.a.key()}}
	if rep == "graph":
		out.graph = graph(s, [[s.h, s.k]])
		out.lines = ["The graph of y = f(x) is shown, with its vertex marked."]
	else:
		out.lines = ["The graph of y = f(x) has its vertex at %s." % Fmt.point(s.h, s.k)]
	var res := {"h": s.h, "k": s.k}
	out.methods = {"read-vertex-form": {"result": res, "steps": [
		"a(x − h)² + k is y = ax² translated by the vector (h, k), so its vertex is (h, k).",
		"The vertex is %s, so h = %s and k = %s." % [Fmt.point(s.h, s.k), N(s.h), N(s.k)],
		"So " + Answer.text(ans, res) + "."]}}
	out.generic = [{"h": s.h.neg(), "k": s.k}, {"h": s.h, "k": s.k.neg()}, {"h": s.k, "k": s.h}, {"h": s.h.neg(), "k": s.k.neg()}]
	return out


func u_vertex_form_from_general(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("vertex_form", {"a": s.a, "h": s.h, "k": s.k})
	var a: Q = s.a
	var b: Q = s.b
	var c: Q = s.c
	var cs := cs_steps(a, b, c)
	var cs_st: Array = cs.steps.duplicate()
	var cs_res := {"a": a, "h": cs.h, "k": cs.k}
	cs_st.append("So " + Answer.text(ans, cs_res) + ".")
	# Compare coefficients of a(x − h)² + k = ax² − 2ahx + ah² + k.
	var h := b.div(a.mul(-2))
	var k := c.sub(a.mul(h.sq()))
	var res := {"a": a, "h": h, "k": k}
	var vh := b.neg().div(a.mul(2))
	var vk := a.mul(vh.sq()).add(b.mul(vh)).add(c)
	return {
		"asked": "Write f(x) in the form a(x − h)² + k.",
		"lines": [gen_line(s)], "given": given_form("general", s), "answer": ans,
		"wrongs": [wrong({"a": a, "h": s.h, "k": c}, "SL2.6.complete-square#0"),
			wrong({"a": a, "h": s.h, "k": c.sub(s.h.sq())}, "SL2.6.complete-square#1"),
			wrong({"a": a, "h": s.h.neg(), "k": s.k}, "SL2.6.complete-square#2")],
		"generic": [{"a": Q.new(1), "h": s.h, "k": s.k}, {"a": a, "h": s.h, "k": s.k.neg()}],
		"methods": {
			"complete-square": {"steps": cs_st, "result": cs_res},
			"compare-coefficients": {"result": res, "steps": [
				"a(x − h)² + k = ax² − 2ahx + ah² + k",
				"Compare with %s: the x² terms give a = %s." % [Fmt.general(a, b, c), N(a)],
				"The x terms: −2 × %s × h = %s, so h = %s" % [P(a), N(b), N(h)],
				"The constants: %s × %s + k = %s, so k = %s" % [P(a), P(h.sq()), N(c), N(k)],
				"So " + Answer.text(ans, res) + "."]},
			"vertex-first": {"result": {"a": a, "h": vh, "k": vk}, "steps": [
				"h = −b/(2a) = %s/%s = %s" % [P(b.neg()), P(a.mul(2)), N(vh)],
				"k = f(%s) = %s × %s%s%s = %s" % [N(vh), N(a), P(vh.sq()), Fmt.plus(b.mul(vh)), Fmt.plus(c), N(vk)],
				"Keep a = %s: so %s." % [N(a), Answer.text(ans, {"a": a, "h": vh, "k": vk})]]},
		},
	}


func u_vertex_form_from_factorised(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("vertex_form", {"a": s.a, "h": s.h, "k": s.k})
	var h: Q = s.p.add(s.q).div(2)
	var k: Q = s.a.mul(h.sub(s.p)).mul(h.sub(s.q))
	var res := {"a": s.a, "h": h, "k": k}
	return {
		"asked": "Write f(x) in the form a(x − h)² + k.",
		"lines": [fac_line(s)], "given": given_form("factorised", s), "answer": ans,
		"wrongs": [wrong({"a": s.a, "h": s.h.neg(), "k": s.k}, "SL2.6.complete-square#2")],
		"generic": [{"a": s.a, "h": s.h, "k": s.k.neg()}, {"a": Q.new(1), "h": s.h, "k": s.k}, {"a": s.a, "h": s.h, "k": s.c}],
		"methods": {"vertex-first": {"result": res, "steps": [
			"The roots are %s and %s, so h is their midpoint: h = (%s%s)/2 = %s" % [N(s.p), N(s.q), N(s.p), Fmt.plus(s.q), N(h)],
			"k = f(%s) = %s(%s%s)(%s%s) = %s" % [N(h), Fmt.lead(s.a) if not s.a.eq(-1) else "−", N(h), Fmt.plus(s.p.neg()), N(h), Fmt.plus(s.q.neg()), N(k)],
			"Keep a = %s: so %s." % [N(s.a), Answer.text(ans, res)]]}},
	}


func u_general_from_vertex_form(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("general", {"a": s.a, "b": s.b, "c": s.c})
	var ex := expand_vertex_steps(s.a, s.h, s.k)
	var st: Array = ex.steps.duplicate()
	var res := {"a": s.a, "b": ex.b, "c": ex.c}
	st.append("So " + Answer.text(ans, res) + ".")
	return {
		"asked": "Write f(x) in the form ax² + bx + c.",
		"lines": [ver_line(s)], "given": given_form("vertex", s), "answer": ans,
		"generic": [{"a": s.a, "b": s.b.neg(), "c": s.c}, {"a": s.a, "b": s.b, "c": s.h.sq().add(s.k)},
			{"a": s.a, "b": s.b, "c": s.k}, {"a": s.a, "b": s.h.mul(-2), "c": s.c}],
		"methods": {"compare-coefficients": {"steps": st, "result": res}},
	}


func u_factorised_from_general(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("factorised", {"a": s.a, "p": s.p, "q": s.q})
	var a: Q = s.a
	var b: Q = s.b
	var c: Q = s.c
	var mb := b.div(a)
	var mc := c.div(a)
	var st: Array = []
	if not a.eq(1):
		st.append("Take out a = %s: f(x) = %s(%s)" % [N(a), Fmt.lead(a), Fmt.poly([1, mb, mc])])
	st.append("Find two numbers that multiply to %s and add to %s: %s and %s." % [N(mc), N(mb), N(s.p.neg()), N(s.q.neg())])
	st.append("%s = %s%s" % [Fmt.poly([1, mb, mc]), Fmt.factor(s.p), Fmt.factor(s.q)])
	var res := {"a": a, "p": s.p, "q": s.q}
	st.append("So " + Answer.text(ans, res) + ".")
	var fm := formula_steps(a, b, c)
	var st2: Array = ["Solve f(x) = 0 with the quadratic formula."]
	st2.append_array(fm.steps)
	var res2 := {"a": a, "p": fm.r1, "q": fm.r2}
	st2.append("Roots %s and %s give the factors %s and %s, and a = %s stays in front." % [N(fm.r1), N(fm.r2), Fmt.factor(fm.r1), Fmt.factor(fm.r2), N(a)])
	st2.append("So " + Answer.text(ans, res2) + ".")
	return {
		"asked": "Write f(x) in the form a(x − p)(x − q).",
		"lines": [gen_line(s)], "given": given_form("general", s), "answer": ans,
		"wrongs": [wrong({"a": Q.new(1), "p": s.p, "q": s.q}, "SL2.6.factorised-form#1")],
		"generic": [{"a": a, "p": s.p.neg(), "q": s.q.neg()}, {"a": a, "p": s.p, "q": s.q.neg()}, {"a": a.neg(), "p": s.p, "q": s.q}],
		"methods": {"factorise": {"steps": st, "result": res}, "roots-to-factors": {"steps": st2, "result": res2}},
	}


func u_factorised_from_vertex_form(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("factorised", {"a": s.a, "p": s.p, "q": s.q})
	var m2: Q = s.k.neg().div(s.a)
	var m := Q.new(int(round(sqrt(float(m2.n)))), int(round(sqrt(float(m2.d)))))
	var r1: Q = s.h.sub(m)
	var r2: Q = s.h.add(m)
	var res := {"a": s.a, "p": r1, "q": r2}
	var ex := expand_vertex_steps(s.a, s.h, s.k)
	var fm := formula_steps(s.a, ex.b, ex.c)
	var st2: Array = ["Expand: f(x) = " + Fmt.general(s.a, ex.b, ex.c), "Solve f(x) = 0 with the quadratic formula."]
	st2.append_array(fm.steps)
	var res2 := {"a": s.a, "p": fm.r1, "q": fm.r2}
	st2.append("So " + Answer.text(ans, res2) + ".")
	return {
		"asked": "Write f(x) in the form a(x − p)(x − q).",
		"lines": [ver_line(s)], "given": given_form("vertex", s), "answer": ans,
		"generic": [{"a": s.a, "p": s.p.neg(), "q": s.q.neg()}, {"a": Q.new(1), "p": s.p, "q": s.q}, {"a": s.a, "p": s.h, "q": s.k}],
		"methods": {
			"complete-square": {"result": res, "steps": [
				"Set f(x) = 0: %s%s² = %s" % [Fmt.lead(s.a), Fmt.factor(s.h), N(s.k.neg())],
				"%s² = %s" % [Fmt.factor(s.h), N(m2)],
				"x%s = ±%s, so x = %s or x = %s" % [Fmt.plus(s.h.neg()), N(m), N(r1), N(r2)],
				"So " + Answer.text(ans, res) + "."]},
			"roots-to-factors": {"steps": st2, "result": res2},
		},
	}


# ── fn-quadratic-from-conditions ─────────────────────────────

func u_vertex_form_from_vertex_and_a(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("vertex_form", {"a": s.a, "h": s.h, "k": s.k})
	var out := {"asked": "Write down the equation of the parabola in the form f(x) = a(x − h)² + k.", "answer": ans,
		"given": {"vertex": pt(s.h, s.k), "a": s.a.key()}}
	if rep == "graph":
		out.graph = graph(s, [[s.h, s.k]], false, "a = " + N(s.a))
		out.lines = ["The graph of y = f(x) is shown, with its vertex marked. Its leading coefficient is a = %s." % N(s.a)]
	else:
		out.lines = ["A parabola y = f(x) has its vertex at %s and leading coefficient a = %s." % [Fmt.point(s.h, s.k), N(s.a)]]
	var res := {"a": s.a, "h": s.h, "k": s.k}
	out.methods = {"vertex-form-plus-point": {"result": res, "steps": [
		"Vertex form is f(x) = a(x − h)² + k, with vertex (h, k).",
		"Put in the vertex %s and a = %s." % [Fmt.point(s.h, s.k), N(s.a)],
		"So " + Answer.text(ans, res) + "."]}}
	out.generic = [{"a": s.a, "h": s.h.neg(), "k": s.k}, {"a": s.a, "h": s.h, "k": s.k.neg()}, {"a": s.a, "h": s.k, "k": s.h}]
	return out


func u_a_from_vertex_and_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("vertex_form", {"a": s.a, "h": s.h, "k": s.k})
	var out := {"asked": "Find the equation of the parabola in the form f(x) = a(x − h)² + k.", "answer": ans}
	var x1: Q = s.x1
	var y1: Q = s.y1
	match rep:
		"graph":
			out.graph = graph(s, [[s.h, s.k], [x1, y1]])
			out.lines = ["The graph of y = f(x) is shown. Its vertex and one other point are marked."]
			out.given = {"vertex": pt(s.h, s.k), "points": [pt(x1, y1)]}
		"words":
			out.lines = ["A parabola y = f(x) has its vertex at %s and passes through %s." % [Fmt.point(s.h, s.k), Fmt.point(x1, y1)]]
			out.given = {"vertex": pt(s.h, s.k), "points": [pt(x1, y1)]}
		"table":
			out.table = table_of(s.xs, s.ys)
			out.lines = ["The table shows values of a quadratic function f, including its vertex."]
			out.given = {"table": table_given(out.table)}
			# Use a table point other than the vertex.
			x1 = s.h.sub(2) if s.xs[6].lt(s.h.add(2)) else s.h.add(2)
			y1 = QuadraticSituation.f(s, x1)
	var dx2: Q = x1.sub(s.h).sq()
	var a: Q = y1.sub(s.k).div(dx2)
	var res := {"a": a, "h": s.h, "k": s.k}
	var head: Array = []
	if rep == "table":
		head.append("f(%s) = f(%s), so the axis is x = %s and the vertex is %s." % [N(s.h.sub(1)), N(s.h.add(1)), N(s.h), Fmt.point(s.h, s.k)])
	var vf: Array = head.duplicate()
	vf.append_array([
		"f(x) = a%s²%s" % [Fmt.factor(s.h), Fmt.plus(s.k)],
		"Substitute %s: %s = a(%s%s)²%s" % [Fmt.point(x1, y1), N(y1), N(x1), Fmt.plus(s.h.neg()), Fmt.plus(s.k)],
		"%s = %s, so a = %s" % [N(y1.sub(s.k)), lin([dx2], ["a"]), N(a)],
		"So " + Answer.text(ans, res) + "."])
	var sim: Array = head.duplicate()
	sim.append_array([
		"Write f(x) = ax² + bx + c. The vertex is on x = −b/(2a) = %s, so b = %s." % [N(s.h), lin([s.h.mul(-2)], ["a"])],
		"Vertex %s: %s = %s" % [Fmt.point(s.h, s.k), lin([s.h.sq(), s.h, 1], ["a", "b", "c"]), N(s.k)],
		"Point %s: %s = %s" % [Fmt.point(x1, y1), lin([x1.sq(), x1, 1], ["a", "b", "c"]), N(y1)],
		"Subtract: %s = %s" % [lin([x1.sq().sub(s.h.sq()), x1.sub(s.h)], ["a", "b"]), N(y1.sub(s.k))],
		"Put in b = %s: %s = %s, so a = %s" % [lin([s.h.mul(-2)], ["a"]), lin([x1.sq().sub(s.h.sq()).add(x1.sub(s.h).mul(s.h.mul(-2)))], ["a"]), N(y1.sub(s.k)), N(a)],
		"With vertex %s: %s." % [Fmt.point(s.h, s.k), Answer.text(ans, res)]])
	out.methods = {"vertex-form-plus-point": {"steps": vf, "result": res}, "simultaneous-equations": {"steps": sim, "result": res}}
	out.wrongs = [wrong({"a": Q.new(1), "h": s.h, "k": s.k}, "SL2.6.find-equation#0")]
	out.generic = [{"a": s.a, "h": s.h.neg(), "k": s.k}, {"a": s.a.neg(), "h": s.h, "k": s.k}, {"a": s.a, "h": s.h, "k": s.k.neg()}]
	return out


func u_equation_from_vertex_and_root(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var first := rng.chance(0.5)
	var r: Q = s.p if first else s.q
	var ans := Answer.make("factorised", {"a": s.a, "p": s.p, "q": s.q})
	var out := {"asked": "Find the other root, and write the equation in the form f(x) = a(x − p)(x − q).", "answer": ans,
		"given": {"vertex": pt(s.h, s.k), "root": r.key()}}
	if rep == "graph":
		out.graph = graph(s, [[s.h, s.k], [r, 0]])
		out.lines = ["The graph of y = f(x) is shown. Its vertex and one root are marked."]
	else:
		out.lines = ["A parabola y = f(x) has its vertex at %s and crosses the x-axis at x = %s." % [Fmt.point(s.h, s.k), N(r)]]
	var other: Q = s.h.mul(2).sub(r)
	var lo: Q = r if r.lt(other) else other
	var hi: Q = other if r.lt(other) else r
	var a_vf: Q = s.k.neg().div(r.sub(s.h).sq())
	var a_if: Q = s.k.div(s.h.sub(lo).mul(s.h.sub(hi)))
	var res := {"a": a_vf, "p": lo, "q": hi}
	var res_if := {"a": a_if, "p": lo, "q": hi}
	var mirror := "The other root is the mirror image of %s in the axis x = %s: 2 × %s − %s = %s." % [N(r), N(s.h), P(s.h), P(r), N(other)]
	var by_vertex := "The vertex is on the curve: %s = a(%s%s)(%s%s) = %sa, so a = %s" % [N(s.k), N(s.h), Fmt.plus(lo.neg()), N(s.h), Fmt.plus(hi.neg()), N(s.h.sub(lo).mul(s.h.sub(hi))), N(a_if)]
	out.methods = {
		"vertex-form-plus-point": {"result": res, "steps": [
			"f(x) = a%s²%s" % [Fmt.factor(s.h), Fmt.plus(s.k)],
			"The root (%s, 0) is on the curve: 0 = a(%s%s)²%s, so a = %s" % [N(r), N(r), Fmt.plus(s.h.neg()), Fmt.plus(s.k), N(a_vf)],
			mirror,
			"So " + Answer.text(ans, res) + "."]},
		"intercept-form-plus-point": {"result": res_if, "steps": [
			mirror, "f(x) = a%s%s" % [Fmt.factor(lo), Fmt.factor(hi)], by_vertex,
			"So " + Answer.text(ans, res_if) + "."]},
		"midpoint-of-roots": {"result": res_if, "steps": [
			"The axis x = %s is halfway between the roots: (%s + r)/2 = %s, so r = %s." % [N(s.h), N(r), N(s.h), N(other)],
			"f(x) = a%s%s" % [Fmt.factor(lo), Fmt.factor(hi)], by_vertex,
			"So " + Answer.text(ans, res_if) + "."]},
		"read-graph-intercepts": {"result": res_if, "steps": [
			"One x-intercept is %s. %s" % [N(r), mirror],
			"f(x) = a%s%s, and the vertex gives a." % [Fmt.factor(lo), Fmt.factor(hi)], by_vertex,
			"So " + Answer.text(ans, res_if) + "."]},
	}
	out.generic = [{"a": Q.new(1), "p": s.p, "q": s.q}, {"a": s.a, "p": s.p.neg(), "q": s.q.neg()}, {"a": s.a.neg(), "p": s.p, "q": s.q},
		{"a": s.a, "p": r, "q": s.h}]
	return out


func u_a_from_roots_and_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("factorised", {"a": s.a, "p": s.p, "q": s.q})
	var out := {"asked": "Find the equation of the parabola in the form f(x) = a(x − p)(x − q).", "answer": ans}
	var x1: Q = s.x1
	var y1: Q = s.y1
	match rep:
		"graph":
			out.graph = graph(s, [[s.p, 0], [s.q, 0], [x1, y1]])
			out.lines = ["The graph of y = f(x) is shown. Its roots and one other point are marked."]
			out.given = {"roots": [s.p.key(), s.q.key()], "points": [pt(x1, y1)]}
		"words":
			var where := "its y-intercept is %s" % N(y1) if x1.is_zero() else "it passes through %s" % Fmt.point(x1, y1)
			out.lines = ["A parabola y = f(x) crosses the x-axis at x = %s and x = %s, and %s." % [N(s.p), N(s.q), where]]
			out.given = {"roots": [s.p.key(), s.q.key()], "points": [pt(x1, y1)]}
		"table":
			out.table = table_of(s.xs, s.ys)
			out.lines = ["The table shows values of a quadratic function f."]
			out.given = {"table": table_given(out.table)}
			for i in s.xs.size():
				if not s.ys[i].is_zero():
					x1 = s.xs[i]
					y1 = s.ys[i]
					if not x1.eq(s.h):
						break
	var prod: Q = x1.sub(s.p).mul(x1.sub(s.q))
	var a := y1.div(prod)
	var res := {"a": a, "p": s.p, "q": s.q}
	var sub := "Substitute %s: %s = a(%s%s)(%s%s) = %sa, so a = %s" % [Fmt.point(x1, y1), N(y1), N(x1), Fmt.plus(s.p.neg()), N(x1), Fmt.plus(s.q.neg()), N(prod), N(a)]
	var read := "f(%s) = 0 and f(%s) = 0, so the roots are %s and %s." % [N(s.p), N(s.q), N(s.p), N(s.q)] if rep == "table" else "The roots are %s and %s." % [N(s.p), N(s.q)]
	out.methods = {
		"intercept-form-plus-point": {"result": res, "steps": [read, "f(x) = a%s%s" % [Fmt.factor(s.p), Fmt.factor(s.q)], sub, "So " + Answer.text(ans, res) + "."]},
		"roots-to-factors": {"result": res, "steps": [read, "Roots %s and %s give the factors %s and %s, so f(x) = a%s%s for some a." % [N(s.p), N(s.q), Fmt.factor(s.p), Fmt.factor(s.q), Fmt.factor(s.p), Fmt.factor(s.q)], sub, "So " + Answer.text(ans, res) + "."]},
		"read-graph-intercepts": {"result": res, "steps": ["Read the x-intercepts: p = %s and q = %s." % [N(s.p), N(s.q)], "f(x) = a%s%s" % [Fmt.factor(s.p), Fmt.factor(s.q)], sub, "So " + Answer.text(ans, res) + "."]},
	}
	# (x − 1) written for a root at x = −1: flip the sign of one root.
	var flip := {"a": s.a, "p": s.p.neg(), "q": s.q} if s.p.sign() < 0 else {"a": s.a, "p": s.p, "q": s.q.neg()}
	out.wrongs = [wrong({"a": Q.new(1), "p": s.p, "q": s.q}, "SL2.6.find-equation#0"), wrong(flip, "SL2.6.find-equation#1")]
	out.generic = [{"a": s.a.neg(), "p": s.p, "q": s.q}, {"a": s.a, "p": s.p.neg(), "q": s.q.neg()}, {"a": s.a.mul(2), "p": s.p, "q": s.q}]
	return out


func u_coefficients_from_roots(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("general_a", {"b": s.b, "c": s.c}, {"a": s.a})
	var out := {"asked": "f(x) = %sx² + bx + c. Find b and c." % Fmt.lead(s.a), "answer": ans,
		"given": {"roots": [s.p.key(), s.q.key()], "a": s.a.key()}}
	if rep == "graph":
		out.graph = graph(s, [[s.p, 0], [s.q, 0]])
		out.lines = ["The graph of y = f(x) is shown, with its roots marked."]
	else:
		out.lines = ["The graph of y = f(x) crosses the x-axis at x = %s and x = %s." % [N(s.p), N(s.q)]]
	var ex := expand_factorised_steps(s.a, s.p, s.q)
	var res := {"b": ex.b, "c": ex.c}
	var st: Array = ["f(x) = %s%s%s" % [Fmt.lead(s.a), Fmt.factor(s.p), Fmt.factor(s.q)]]
	st.append_array(ex.steps)
	st.append("So " + Answer.text(ans, res) + ".")
	var st2: Array = ["Roots %s and %s give the factors %s and %s." % [N(s.p), N(s.q), Fmt.factor(s.p), Fmt.factor(s.q)]]
	st2.append_array(st)
	var h: Q = s.p.add(s.q).div(2)
	var bm: Q = s.a.mul(h).mul(-2)
	var cm: Q = s.a.mul(s.p).mul(s.q)
	var resm := {"b": bm, "c": cm}
	# (x − 1) written for a root at x = −1.
	var fp: Q = s.p.neg() if s.p.sign() < 0 else s.p
	var fq: Q = s.q if s.p.sign() < 0 else s.q.neg()
	out.methods = {
		"intercept-form-plus-point": {"steps": st, "result": res},
		"roots-to-factors": {"steps": st2, "result": res},
		"midpoint-of-roots": {"result": resm, "steps": [
			"The axis is halfway between the roots: x = (%s%s)/2 = %s" % [N(s.p), Fmt.plus(s.q), N(h)],
			"−b/(2a) = %s, so b = −2 × %s × %s = %s" % [N(h), P(s.a), P(h), N(bm)],
			"c = f(0) = %s × %s × %s = %s" % [N(s.a), P(s.p.neg()), P(s.q.neg()), N(cm)],
			"So " + Answer.text(ans, resm) + "."]},
	}
	out.wrongs = [wrong({"b": s.a.mul(fp.add(fq)).neg(), "c": s.a.mul(fp).mul(fq)}, "SL2.6.find-equation#1"),
		wrong({"b": s.p.add(s.q).neg(), "c": s.p.mul(s.q)}, "SL2.6.factorised-form#1")]
	out.generic = [{"b": s.b.neg(), "c": s.c}, {"b": s.b, "c": s.c.neg()}, {"b": s.b.neg(), "c": s.c.neg()}]
	return out


func u_coefficient_from_axis(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("number", {"v": s.b}, {}, "b = ")
	var out := {"asked": "f(x) = %sx² + bx + c. Find b." % Fmt.lead(s.a), "answer": ans, "given": {"axis": s.h.key(), "a": s.a.key()}}
	if rep == "graph":
		out.graph = graph(s, [], true)
		out.lines = ["The graph of y = f(x) is shown. The dashed line is its axis of symmetry."]
	else:
		out.lines = ["The graph of y = f(x) has axis of symmetry x = %s." % N(s.h)]
	var b: Q = s.a.mul(s.h).mul(-2)
	var res := {"v": b}
	out.methods = {"minus-b-over-2a": {"result": res, "steps": [
		"The axis is x = −b/(2a), so −b/(2 × %s) = %s." % [P(s.a), N(s.h)],
		"−b = %s × %s = %s" % [N(s.a.mul(2)), P(s.h), N(b.neg())],
		"So " + Answer.text(ans, res) + "."]}}
	out.generic = [{"v": b.neg()}, {"v": s.a.mul(s.h).neg()}, {"v": s.h.mul(-2)}, {"v": s.h.neg()}]
	return out


func u_coefficients_from_two_points_and_axis(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var with_axis := rng.chance(0.5)
	var ymax := QuadraticSituation.GRAPH_Y_MAX if rep == "graph" else QuadraticSituation.POINT_Y_MAX
	var xs: Array = []
	for x in range(-QuadraticSituation.POINT_X_MAX, QuadraticSituation.POINT_X_MAX + 1):
		var y := QuadraticSituation.f(s, x)
		if absi(y.n) <= ymax and not Q.new(x).eq(s.h) and absi(x - s.h.n) <= 4:
			xs.append(x)
	var pts := rng.shuffled(xs)
	var x1 := Q.new(pts[0])
	var x2 := Q.new(pts[1])
	# With the axis known, the two points must not be mirror images (x1 + x2 ≠ 2h).
	for j in range(1, pts.size()):
		x2 = Q.new(pts[j])
		if not with_axis or not x1.add(x2).eq(s.h.mul(2)):
			break
	# Only a mirror pair fits (two points in range): the axis adds nothing, so give a instead.
	if with_axis and x1.add(x2).eq(s.h.mul(2)):
		with_axis = false
	if x2.lt(x1):
		var t := x1
		x1 = x2
		x2 = t
	var y1 := QuadraticSituation.f(s, x1)
	var y2 := QuadraticSituation.f(s, x2)
	var ans: Dictionary
	var out := {}
	var cond := ""
	if with_axis:
		ans = Answer.make("general", {"a": s.a, "b": s.b, "c": s.c})
		out.asked = "f(x) = ax² + bx + c. Find a, b and c."
		out.given = {"points": [pt(x1, y1), pt(x2, y2)], "axis": s.h.key()}
		cond = "its axis of symmetry is x = %s" % N(s.h)
	else:
		ans = Answer.make("general_a", {"b": s.b, "c": s.c}, {"a": s.a})
		out.asked = "f(x) = %sx² + bx + c. Find b and c." % Fmt.lead(s.a)
		out.given = {"points": [pt(x1, y1), pt(x2, y2)], "a": s.a.key()}
		cond = "a = %s" % N(s.a)
	out.answer = ans
	match rep:
		"graph":
			out.graph = graph(s, [[x1, y1], [x2, y2]], with_axis)
			out.lines = ["The graph of y = f(x) passes through the two marked points%s." % [". The dashed line is its axis of symmetry" if with_axis else ", and " + cond]]
		"table":
			out.table = table_of([x1, x2], [y1, y2])
			out.lines = ["The table shows two points on the graph of y = f(x), and %s." % cond]
		"words":
			out.lines = ["The graph of y = f(x) passes through %s and %s, and %s." % [Fmt.point(x1, y1), Fmt.point(x2, y2), cond]]
	var st: Array = []
	var res := {}
	if with_axis:
		# b = −2ha; then two equations in a and c.
		var u1 := x1.sq().sub(x1.mul(s.h).mul(2))
		var u2 := x2.sq().sub(x2.mul(s.h).mul(2))
		var a := y2.sub(y1).div(u2.sub(u1))
		var c := y1.sub(a.mul(u1))
		var b := a.mul(s.h).mul(-2)
		res = {"a": a, "b": b, "c": c}
		st = ["The axis x = %s gives −b/(2a) = %s, so b = %s." % [N(s.h), N(s.h), lin([s.h.mul(-2)], ["a"])],
			"Substitute %s: %s = %s. With b = %s: %s = %s" % [Fmt.point(x1, y1), subst({}, ["a", "b", "c"], x1), N(y1), lin([s.h.mul(-2)], ["a"]), lin([u1, 1], ["a", "c"]), N(y1)],
			"Substitute %s: %s = %s" % [Fmt.point(x2, y2), lin([u2, 1], ["a", "c"]), N(y2)],
			"Subtract: %s = %s, so a = %s" % [lin([u2.sub(u1)], ["a"]), N(y2.sub(y1)), N(a)],
			"c = %s − %s × %s = %s, and b = %s × %s = %s" % [N(y1), P(u1), P(a), N(c), N(s.h.mul(-2)), P(a), N(b)],
			"So " + Answer.text(ans, res) + "."]
	else:
		var r1 := y1.sub(s.a.mul(x1.sq()))
		var r2 := y2.sub(s.a.mul(x2.sq()))
		var b := r2.sub(r1).div(x2.sub(x1))
		var c := r1.sub(b.mul(x1))
		res = {"b": b, "c": c}
		st = ["Substitute %s: %s = %s, so %s = %s" % [Fmt.point(x1, y1), subst({"a": s.a}, ["b", "c"], x1), N(y1), lin([x1, 1], ["b", "c"]), N(r1)],
			"Substitute %s: %s = %s, so %s = %s" % [Fmt.point(x2, y2), subst({"a": s.a}, ["b", "c"], x2), N(y2), lin([x2, 1], ["b", "c"]), N(r2)],
			"Subtract: %s = %s, so b = %s" % [lin([x2.sub(x1)], ["b"]), N(r2.sub(r1)), N(b)],
			"c = %s − %s × %s = %s" % [N(r1), P(x1), P(b), N(c)],
			"So " + Answer.text(ans, res) + "."]
	out.methods = {"simultaneous-equations": {"steps": st, "result": res}}
	if with_axis:
		out.generic = [{"a": s.a, "b": s.b.neg(), "c": s.c}, {"a": s.a.neg(), "b": s.b, "c": s.c}, {"a": s.a, "b": s.b, "c": s.c.neg()}]
	else:
		out.generic = [{"b": s.b.neg(), "c": s.c}, {"b": s.b, "c": s.c.neg()}, {"b": s.c, "c": s.b}]
	return out


func u_range_after_finding(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rel := "≥" if s.a.sign() > 0 else "≤"
	var ans := Answer.make("range", {"var": "y", "rel": rel, "k": s.k})
	var out := {"asked": "Find the equation of f, then the range of f.", "answer": ans,
		"given": {"roots": [s.p.key(), s.q.key()], "points": [pt(s.x1, s.y1)]}}
	if rep == "graph":
		out.graph = graph(s, [[s.p, 0], [s.q, 0], [s.x1, s.y1]])
		out.lines = ["The graph of y = f(x) is shown. Its roots and one other point are marked."]
	else:
		out.lines = ["A parabola y = f(x) crosses the x-axis at x = %s and x = %s, and passes through %s." % [N(s.p), N(s.q), Fmt.point(s.x1, s.y1)]]
	var prod: Q = s.x1.sub(s.p).mul(s.x1.sub(s.q))
	var a: Q = s.y1.div(prod)
	var h: Q = s.p.add(s.q).div(2)
	var k := a.mul(h.sub(s.p)).mul(h.sub(s.q))
	var r := "≥" if a.sign() > 0 else "≤"
	var res := {"var": "y", "rel": r, "k": k}
	out.methods = {"vertex-or-asymptote": {"result": res, "steps": [
		"f(x) = a%s%s. Substitute %s: %s = %sa, so a = %s." % [Fmt.factor(s.p), Fmt.factor(s.q), Fmt.point(s.x1, s.y1), N(s.y1), N(prod), N(a)],
		"The vertex is on the axis x = (%s%s)/2 = %s: f(%s) = %s." % [N(s.p), Fmt.plus(s.q), N(h), N(h), N(k)],
		"a %s 0, so the parabola opens %s and %s is its %s value." % [">" if a.sign() > 0 else "<", "upwards" if a.sign() > 0 else "downwards", N(k), "least" if a.sign() > 0 else "greatest"],
		"So the range is " + Answer.text(ans, res) + "."]}}
	var flip := "≤" if rel == "≥" else "≥"
	out.wrongs = [wrong({"var": "x", "rel": rel, "k": s.k}, "SL2.2.range#2")]
	out.generic = [{"var": "y", "rel": flip, "k": s.k}, {"var": "y", "rel": rel, "k": s.h}, {"var": "y", "rel": rel, "k": s.c}]
	return out


func u_coefficients_from_three_points(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := Answer.make("general", {"a": s.a, "b": s.b, "c": s.c})
	var out := {"asked": "f(x) = ax² + bx + c. Find a, b and c.", "answer": ans}
	var xs: Array = []
	if rep == "table":
		out.table = table_of(s.xs, s.ys)
		out.lines = ["The table shows values of f(x) = ax² + bx + c."]
		out.given = {"table": table_given(out.table)}
		var idx := rng.shuffled([0, 1, 2, 3, 4, 5, 6]).slice(0, 3)
		idx.sort()
		for i in idx:
			xs.append(s.xs[i])
	else:
		var opts: Array = []
		for x in range(-QuadraticSituation.POINT_X_MAX, QuadraticSituation.POINT_X_MAX + 1):
			if absi(QuadraticSituation.f(s, x).n) <= QuadraticSituation.POINT_Y_MAX:
				opts.append(Q.new(x))
		xs = rng.shuffled(opts).slice(0, 3)
		xs.sort_custom(func(u, v): return u.lt(v))
		var ptxt: Array = xs.map(func(x): return Fmt.point(x, QuadraticSituation.f(s, x)))
		out.lines = ["The graph of y = f(x) passes through %s, %s and %s." % ptxt]
		out.given = {"points": xs.map(func(x): return pt(x, QuadraticSituation.f(s, x)))}
	var ys: Array = xs.map(func(x): return QuadraticSituation.f(s, x))
	# Elimination: difference quotients, then a, b, c.
	var m1: Q = ys[1].sub(ys[0]).div(xs[1].sub(xs[0]))
	var m2: Q = ys[2].sub(ys[1]).div(xs[2].sub(xs[1]))
	var a: Q = m2.sub(m1).div(xs[2].sub(xs[0]))
	var b: Q = m1.sub(a.mul(xs[0].add(xs[1])))
	var c: Q = ys[0].sub(a.mul(xs[0].sq())).sub(b.mul(xs[0]))
	var res := {"a": a, "b": b, "c": c}
	var eqs: Array = []
	for i in 3:
		eqs.append("(%d)  %s = %s" % [i + 1, lin([xs[i].sq(), xs[i], 1], ["a", "b", "c"]), N(ys[i])])
	var sim: Array = ["Substitute the three points into ax² + bx + c:"]
	sim.append_array(eqs)
	sim.append_array([
		"(2) − (1), divided by %s: %s = %s" % [N(xs[1].sub(xs[0])), lin([xs[0].add(xs[1]), 1], ["a", "b"]), N(m1)],
		"(3) − (2), divided by %s: %s = %s" % [N(xs[2].sub(xs[1])), lin([xs[1].add(xs[2]), 1], ["a", "b"]), N(m2)],
		"Subtract: %s = %s, so a = %s" % [lin([xs[2].sub(xs[0])], ["a"]), N(m2.sub(m1)), N(a)],
		"b = %s − %s × %s = %s" % [N(m1), P(xs[0].add(xs[1])), P(a), N(b)],
		"c = %s − %s × %s − %s × %s = %s" % [N(ys[0]), P(a), P(xs[0].sq()), P(b), P(xs[0]), N(c)],
		"So " + Answer.text(ans, res) + "."])
	var gdc: Array = ["Enter the three equations in the GDC's simultaneous equation solver:"]
	gdc.append_array(eqs)
	gdc.append("The solver gives a = %s, b = %s, c = %s." % [N(a), N(b), N(c)])
	gdc.append("So " + Answer.text(ans, res) + ".")
	out.methods = {"simultaneous-equations": {"steps": sim, "result": res}, "gdc-solve": {"steps": gdc, "result": res}}
	out.generic = [{"a": s.a.neg(), "b": s.b, "c": s.c}, {"a": s.a, "b": s.b.neg(), "c": s.c}, {"a": s.a, "b": s.b, "c": s.c.neg()}]
	return out


func u_coefficient_from_point(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var which: String = rng.pick(["a", "b", "c"])
	var ans := Answer.make("number", {"v": s[which]}, {}, which + " = ")
	var parts := {"a": Fmt.lead(s.a) + "x²", "b": Fmt.term(s.b, 1, false), "c": Fmt.plus(s.c)}
	parts[which] = {"a": "ax²", "b": " + bx", "c": " + c"}[which]
	var eq: String = "f(x) = " + parts.a + parts.b + parts.c
	var known := {}
	for key in ["a", "b", "c"]:
		if key != which:
			known[key] = s[key].key()
	var out := {"asked": "Find the value of %s." % which, "answer": ans,
		"given": {"partial": known, "unknown": which, "points": [pt(s.x1, s.y1)]}}
	if rep == "equation":
		out.lines = [eq, "The graph of y = f(x) passes through %s." % Fmt.point(s.x1, s.y1)]
	else:
		var others: Array = []
		for key in known:
			others.append("%s = %s" % [key, N(s[key])])
		out.lines = ["f(x) = ax² + bx + c, where %s and %s. The graph of y = f(x) passes through %s." % [others[0], others[1], Fmt.point(s.x1, s.y1)]]
	var x1: Q = s.x1
	var coef := {"a": x1.sq(), "b": x1, "c": Q.new(1)}
	var rest := Q.new(0)
	for key in known:
		rest = rest.add(s[key].mul(coef[key]))
	var v: Q = s.y1.sub(rest).div(coef[which])
	var res := {"v": v}
	var lhs := lin([coef[which]], [which])
	out.methods = {"simultaneous-equations": {"result": res, "steps": [
		"Substitute %s into f(x): %s = %s" % [Fmt.point(x1, s.y1), subst(s, [which], x1), N(s.y1)],
		"%s%s = %s" % [lhs, Fmt.plus(rest), N(s.y1)] if not rest.is_zero() else "%s = %s" % [lhs, N(s.y1)],
		"%s = %s" % [lhs, N(s.y1.sub(rest))],
		"So " + Answer.text(ans, res) + "."]}}
	out.generic = [{"v": v.neg()}, {"v": s.y1.add(rest).div(coef[which])}, {"v": s.y1.sub(rest)}]
	return out


func u_equation_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("vertex_form", {"a": s.a, "h": s.h, "k": s.k})
	var t := table_of(s.xs, s.ys)
	var h: Q = s.h
	var k := QuadraticSituation.f(s, h)
	var x1: Q = h.add(2) if (h.add(2).lt(s.xs[6]) or h.add(2).eq(s.xs[6])) else h.sub(2)
	var y1 := QuadraticSituation.f(s, x1)
	var a := y1.sub(k).div(x1.sub(h).sq())
	var res := {"a": a, "h": h, "k": k}
	return {
		"asked": "Find the equation of f in the form f(x) = a(x − h)² + k.",
		"lines": ["The table shows values of a quadratic function f."], "table": t,
		"given": {"table": table_given(t)}, "answer": ans,
		"generic": [{"a": s.a, "h": s.h.neg(), "k": s.k}, {"a": s.a.neg(), "h": s.h, "k": s.k}, {"a": Q.new(1), "h": s.h, "k": s.k}, {"a": s.a, "h": s.h, "k": s.k.neg()}],
		"methods": {"vertex-form-plus-point": {"result": res, "steps": [
			"f(%s) = f(%s), so the axis is x = %s and the vertex is %s." % [N(h.sub(1)), N(h.add(1)), N(h), Fmt.point(h, k)],
			"f(x) = a%s²%s" % [Fmt.factor(h), Fmt.plus(k)],
			"Use another point from the table, %s: %s = a(%s%s)²%s" % [Fmt.point(x1, y1), N(y1), N(x1), Fmt.plus(h.neg()), Fmt.plus(k)],
			"%s = 4a, so a = %s" % [N(y1.sub(k)), N(a)],
			"So " + Answer.text(ans, res) + "."]}},
	}


# ── fn-concept-quadratic-forms ───────────────────────────────

func u_match_three_forms(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := {"ga": s.a, "gb": s.b, "gc": s.c, "fa": s.a, "fp": s.p, "fq": s.q, "va": s.a, "vh": s.h, "vk": s.k}
	var ans := Answer.make("triple", right)
	var out := {"asked": "Which set of three equations all describe this same parabola?", "answer": ans}
	var pre: Array = []
	if rep == "graph":
		out.graph = graph(s, [[s.p, 0], [s.q, 0], [s.h, s.k], [0, s.c]])
		out.lines = ["The graph of y = f(x) is shown."]
		out.given = {"roots": [s.p.key(), s.q.key()], "vertex": pt(s.h, s.k), "yint": s.c.key()}
		pre = ["Read from the graph: roots %s and %s, vertex %s, y-intercept %s." % [N(s.p), N(s.q), Fmt.point(s.h, s.k), N(s.c)]]
	else:
		out.lines = [gen_line(s)]
		out.given = given_form("general", s)
	var ev := expand_vertex_steps(s.a, s.h, s.k)
	var ef := expand_factorised_steps(s.a, s.p, s.q)
	var cmp: Array = pre.duplicate()
	cmp.append("Expand the vertex form: %s = %s" % [Fmt.vertex(s.a, s.h, s.k), Fmt.general(s.a, ev.b, ev.c)])
	cmp.append("Expand the factorised form: %s = %s" % [Fmt.factorised(s.a, s.p, s.q), Fmt.general(s.a, ef.b, ef.c)])
	var res := {"ga": s.a, "gb": ev.b, "gc": ev.c, "fa": s.a, "fp": s.p, "fq": s.q, "va": s.a, "vh": s.h, "vk": s.k}
	cmp.append("Both expand to the general form, so the set is " + Answer.text(ans, res) + ".")
	var fm := formula_steps(s.a, s.b, s.c)
	var rtf: Array = pre.duplicate()
	rtf.append("Solve %s = 0:" % Fmt.general(s.a, s.b, s.c))
	rtf.append_array(fm.steps)
	var hh: Q = fm.r1.add(fm.r2).div(2)
	var kk: Q = s.a.mul(hh.sub(fm.r1)).mul(hh.sub(fm.r2))
	rtf.append("So f(x) = %s, with vertex at the midpoint x = %s and f(%s) = %s." % [Fmt.factorised(s.a, fm.r1, fm.r2), N(hh), N(hh), N(kk)])
	var res2 := {"ga": s.a, "gb": s.b, "gc": s.c, "fa": s.a, "fp": fm.r1, "fq": fm.r2, "va": s.a, "vh": hh, "vk": kk}
	rtf.append("So the set is " + Answer.text(ans, res2) + ".")
	out.methods = {"compare-coefficients": {"steps": cmp, "result": res}, "roots-to-factors": {"steps": rtf, "result": res2}}
	var w1 := right.duplicate()
	w1.vh = s.h.neg()
	out.wrongs = [wrong(w1, "SL2.6.vertex#0")]
	var g1 := right.duplicate()
	g1.fp = s.p.neg()
	g1.fq = s.q.neg()
	var g2 := right.duplicate()
	g2.gc = s.c.neg()
	var g3 := right.duplicate()
	g3.fa = Q.new(1)
	var g4 := right.duplicate()
	g4.vk = s.k.neg()
	out.generic = [g1, g2, g3, g4]
	return out


static func claim(form: String, feature: String, vals: Array, text: String) -> Dictionary:
	return {"form": form, "feature": feature, "vals": vals, "text": text}


func u_form_for_feature(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var feature: String = rng.pick(["vertex", "roots", "y-intercept"])
	var forms := "general %s,  factorised %s,  vertex %s" % [Fmt.general(s.a, s.b, s.c), Fmt.factorised(s.a, s.p, s.q), Fmt.vertex(s.a, s.h, s.k)]
	var right: Dictionary
	var wrongs: Array = []
	var generic: Array = []
	var why := ""
	match feature:
		"vertex":
			right = claim("vertex", feature, [s.h, s.k], "Vertex form: the vertex is %s" % Fmt.point(s.h, s.k))
			generic = [claim("vertex", feature, [s.h.neg(), s.k], "Vertex form: the vertex is %s" % Fmt.point(s.h.neg(), s.k)),
				claim("factorised", feature, [s.p, s.q], "Factorised form: the vertex is %s" % Fmt.point(s.p, s.q)),
				claim("general", feature, [s.b, s.c], "General form: the vertex is %s" % Fmt.point(s.b, s.c)),
				claim("vertex", feature, [s.h, s.k.neg()], "Vertex form: the vertex is %s" % Fmt.point(s.h, s.k.neg()))]
			why = "a(x − h)² + k is y = ax² translated by (h, k), so the vertex %s shows at a glance." % Fmt.point(s.h, s.k)
		"roots":
			right = claim("factorised", feature, [s.p, s.q], "Factorised form: the roots are %s and %s" % [N(s.p), N(s.q)])
			generic = [claim("factorised", feature, [s.p.neg(), s.q.neg()], "Factorised form: the roots are %s and %s" % [N(s.p.neg()), N(s.q.neg())]),
				claim("vertex", feature, [s.h, s.k], "Vertex form: the roots are %s and %s" % [N(s.h), N(s.k)]),
				claim("general", feature, [s.b, s.c], "General form: the roots are %s and %s" % [N(s.b), N(s.c)]),
				claim("factorised", feature, [s.p, s.q.neg()], "Factorised form: the roots are %s and %s" % [N(s.p), N(s.q.neg())])]
			why = "a(x − p)(x − q) is 0 exactly when x = p or x = q, so the roots %s and %s show at a glance." % [N(s.p), N(s.q)]
		_:
			right = claim("general", feature, [s.c], "General form: the y-intercept is %s" % Fmt.point(0, s.c))
			wrongs = [wrong(claim("factorised", feature, [s.p.mul(s.q)], "Factorised form: the y-intercept is %s" % Fmt.point(0, s.p.mul(s.q))), "SL2.6.factorised-form#2")]
			generic = [claim("vertex", feature, [s.k], "Vertex form: the y-intercept is %s" % Fmt.point(0, s.k)),
				claim("vertex", feature, [s.h], "Vertex form: the y-intercept is %s" % Fmt.point(0, s.h)),
				claim("general", feature, [s.b], "General form: the y-intercept is %s" % Fmt.point(0, s.b)),
				claim("factorised", feature, [s.p.add(s.q)], "Factorised form: the y-intercept is %s" % Fmt.point(0, s.p.add(s.q)))]
			why = "In ax² + bx + c, f(0) = c, so the y-intercept %s shows at a glance. In the other forms it is apq or ah² + k." % Fmt.point(0, s.c)
	var ans := Answer.make("claim", right)
	return {
		"asked": "Which form shows the %s without any working, and what is it?" % feature,
		"lines": ["One parabola, three forms: %s." % forms], "answer": ans,
		"given": {"forms": [given_form("general", s), given_form("factorised", s), given_form("vertex", s)], "feature": feature},
		"wrongs": wrongs, "generic": generic,
		"methods": {"read-vertex-form": {"steps": [why, "So: " + right.text + "."], "result": right}},
	}


func u_form_for_task(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var task: String = rng.pick(["solve", "range", "f0"])
	var forms := "general %s,  factorised %s,  vertex %s" % [Fmt.general(s.a, s.b, s.c), Fmt.factorised(s.a, s.p, s.q), Fmt.vertex(s.a, s.h, s.k)]
	var rel := "≥" if s.a.sign() > 0 else "≤"
	var right: Dictionary
	var generic: Array = []
	var asked := ""
	var why := ""
	match task:
		"solve":
			asked = "To solve f(x) = 0, which form is the best start, and what does it give?"
			right = claim("factorised", "roots", [s.p, s.q], "Factorised: x = %s or x = %s" % [N(s.p), N(s.q)])
			generic = [claim("vertex", "roots", [s.h], "Vertex: x = %s" % N(s.h)),
				claim("general", "roots", [s.c], "General: x = %s" % N(s.c)),
				claim("factorised", "roots", [s.p.neg(), s.q.neg()], "Factorised: x = %s or x = %s" % [N(s.p.neg()), N(s.q.neg())]),
				claim("general", "roots", [s.b], "General: x = %s" % N(s.b)),
				claim("vertex", "roots", [s.k], "Vertex: x = %s" % N(s.k))]
			why = "a(x − p)(x − q) = 0 needs one bracket to be 0, so the solutions can be read off: x = %s or x = %s." % [N(s.p), N(s.q)]
		"range":
			asked = "To find the range of f, which form is the best start, and what does it give?"
			right = claim("vertex", "range", [s.k], "Vertex: y %s %s" % [rel, N(s.k)])
			generic = [claim("factorised", "range", [s.p], "Factorised: y %s %s" % [rel, N(s.p)]),
				claim("general", "range", [s.c], "General: y %s %s" % [rel, N(s.c)]),
				claim("vertex", "range", [s.h], "Vertex: y %s %s" % [rel, N(s.h)]),
				claim("general", "range", [s.b], "General: y %s %s" % [rel, N(s.b)]),
				claim("factorised", "range", [s.q], "Factorised: y %s %s" % [rel, N(s.q)])]
			why = "The range stops at the vertex height k, which vertex form shows: k = %s, and a %s 0, so y %s %s." % [N(s.k), ">" if s.a.sign() > 0 else "<", rel, N(s.k)]
		_:
			asked = "To find f(0), which form is the best start, and what does it give?"
			right = claim("general", "f0", [s.c], "General: f(0) = %s" % N(s.c))
			generic = [claim("factorised", "f0", [s.p.mul(s.q)], "Factorised: f(0) = %s" % N(s.p.mul(s.q))),
				claim("vertex", "f0", [s.k], "Vertex: f(0) = %s" % N(s.k)),
				claim("general", "f0", [s.b], "General: f(0) = %s" % N(s.b)),
				claim("vertex", "f0", [s.h], "Vertex: f(0) = %s" % N(s.h)),
				claim("factorised", "f0", [s.p.add(s.q)], "Factorised: f(0) = %s" % N(s.p.add(s.q)))]
			why = "Every x term in ax² + bx + c is 0 at x = 0, so f(0) = c = %s with no working." % N(s.c)
	var ans := Answer.make("claim", right)
	return {
		"asked": asked, "lines": ["One parabola, three forms: %s." % forms], "answer": ans,
		"given": {"forms": [given_form("general", s), given_form("factorised", s), given_form("vertex", s)], "task": task},
		"generic": generic,
		"methods": {"read-vertex-form": {"steps": [why, "So: " + right.text + "."], "result": right}},
	}


func u_missing_form(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var disc: Q = s.disc
	var right := claim("factorised", "missing", [disc], "Factorised form: Δ = %s < 0, so f(x) = 0 has no real roots p and q" % N(disc))
	var ans := Answer.make("claim", right)
	var out := {"asked": "One of the three forms of f can't be written with real numbers. Which one, and why?", "answer": ans}
	if rep == "graph":
		out.graph = graph(s, [[s.h, s.k], [0, s.c]])
		out.lines = ["The graph of y = f(x) is shown, with its vertex and y-intercept marked. f(x) = %s." % Fmt.vertex(s.a, s.h, s.k)]
	else:
		out.lines = [ver_line(s)]
	out.given = given_form("vertex", s)
	var ex := expand_vertex_steps(s.a, s.h, s.k)
	var d2: Q = ex.b.sq().sub(s.a.mul(ex.c).mul(4))
	var res := claim("factorised", "missing", [d2], "Factorised form: Δ = %s < 0, so f(x) = 0 has no real roots p and q" % N(d2))
	out.methods = {"roots-to-factors": {"result": res, "steps": [
		"General form: f(x) = " + Fmt.general(s.a, ex.b, ex.c),
		"Δ = b² − 4ac = %s² − 4 × %s × %s = %s" % [P(ex.b), P(s.a), P(ex.c), N(d2)],
		"Δ < 0, so f(x) = 0 has no real roots. a(x − p)(x − q) needs real roots p and q.",
		"So: " + res.text + "."]}}
	out.generic = [claim("vertex", "missing", [disc], "Vertex form: Δ = %s < 0, so the square can't be completed" % N(disc)),
		claim("general", "missing", [disc], "General form: Δ = %s < 0, so b and c can't be found" % N(disc)),
		claim("factorised", "missing", [disc.neg()], "Factorised form: Δ = %s, which is not a square" % N(disc.neg()))]
	return out
