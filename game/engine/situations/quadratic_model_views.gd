class_name QuadraticModelViews
extends ExtensionViews
## The views on the `quadratic-model` situation: one builder per unknown of
## fn-ext-quadratic-model (FAL-459). A ball's model is h(t), in metres after t seconds;
## a pen's is A(x), in m² for a width of x m. Numbers are written as decimals where they
## end (Paper 2's −4.9t² + 19.6t + 1.5).

const REF_SWAP := "SL2.6.model#0"
const REF_NEGATIVE := "SL2.6.model#1"

## Methods that don't work, for method-pick (after the catalogue's own weak ones).
const NOT_ROOTS := {"name": "Solve the model = 0", "why": "that gives where it starts or lands, not the top"}
const NOT_START := {"name": "Put 0 into the model", "why": "that gives the starting value, not the best one"}
const NOT_SQUARE := {"name": "Make the pen a square", "why": "against a wall the best pen is twice as long as it is wide"}
const NOT_DOUBLE := {"name": "Double the time of the maximum", "why": "that is when it is back at its starting height"}
const NOT_ADD := {"name": "Add the two times given", "why": "the other time is the first one mirrored in the top"}
const NOT_START_TOP := {"name": "Use the start height as the vertex", "why": "the vertex is the top, not the start"}
const NOT_XY := {"name": "Maximise A = xy as it stands", "why": "A has two variables until the fence length removes one"}


func needs() -> Dictionary:
	return {
		"max-value": {"ctx": "any"},
		"time-of-max": {"ctx": "any"},
		"zero-time": {"ctx": "ball", "land": true},
		"form-area-model": {"ctx": "pen"},
		"interpret-vertex": {"ctx": "any"},
		"second-time-at-height": {"ctx": "ball"},
		"model-from-features": {"ctx": "ball"},
	}


func need(unknown: String, rep: String) -> Dictionary:
	var n := super.need(unknown, rep)
	if rep == "table":
		n.table = true
	return n


## The papers each cell can make (FAL-419): a ball can be Paper 2 (a = −4.9); a pen
## and a table are Paper 1 only. The type has no exam counts, so this only says which
## papers a view may force; the recipe still picks its own otherwise.
func papers(unknown: String, rep: String, _angle: String) -> Array:
	if rep == "table" or needs()[unknown].ctx == "pen":
		return [1]
	return [1, 2]


func extra() -> Dictionary:
	var mp := ["method-pick"]
	return {"max-value": mp, "time-of-max": mp, "form-area-model": mp, "interpret-vertex": mp,
		"second-time-at-height": mp, "model-from-features": mp}


# ── Helpers ──────────────────────────────────────────────────

static func ball(s: Dictionary) -> bool:
	return s.ctx == "ball"


static func fname(s: Dictionary) -> String:
	return "h(t)" if ball(s) else "A(x)"


static func f1(s: Dictionary) -> String:
	return "h" if ball(s) else "A"


static func v(s: Dictionary) -> String:
	return "t" if ball(s) else "x"


static func D(x: Variant) -> String:
	return Fmt.dec(x)


## a in front of a bracket, as a decimal: "−4.9", "−5", "−".
static func dlead(a: Q) -> String:
	return "−" if a.eq(-1) else D(a)


static func general(s: Dictionary) -> String:
	return Fmt.terms([s.a, s.b, s.c], [2, 1, 0], v(s), true)


static func vertex_form(s: Dictionary) -> String:
	return "%s(%s − %s)² + %s" % [dlead(s.a), v(s), D(s.T), D(s.H)]


## The context, as the question shows it.
static func setting(s: Dictionary) -> String:
	if ball(s):
		return "A ball is thrown upwards. Its height after t seconds is h(t) metres."
	if s.wall:
		return "A rectangular pen is built against a wall with %s m of fence for its other three sides. Its area is A(x) m² when its width is x m." % N(s.L)
	return "A rectangular pen is built with %s m of fence all round. Its area is A(x) m² when its width is x m." % N(s.L)


static func model_line(s: Dictionary) -> String:
	return "%s = %s" % [fname(s), general(s)]


static func top_unit(s: Dictionary) -> String:
	return " m" if ball(s) else " m²"


static func at_unit(s: Dictionary) -> String:
	return " s" if ball(s) else " m"


static func graph_of(s: Dictionary) -> Dictionary:
	var far: Q = s.T.mul(2)
	var pts: Array = [{"x": 0.0, "y": s.h0.to_float(), "label": "(0, %s)" % D(s.h0)}, {"x": far.to_float(), "y": s.h0.to_float(), "label": "(%s, %s)" % [D(far), D(s.h0)]}]
	var top: float = s.H.to_float()
	var step := maxf(1.0, top / 8.0)
	return {"a": s.a.to_float(), "h": s.T.to_float(), "k": top, "points": pts, "axis": null, "axis_label": "",
		"x0": -1, "x1": ceili(far.to_float()) + 1, "y0": -ceili(step), "y1": ceili(top + step), "caption": "y = " + fname(s)}


## A table of the model: 0 to 2T for a ball, T − 3 to T + 3 (not T) for a pen.
static func table_of(s: Dictionary) -> Dictionary:
	var xs: Array = []
	if ball(s):
		for t in range(0, s.T.mul(2).n + 1):
			xs.append(Q.new(t))
	else:
		for d in [-3, -2, -1, 1, 2, 3]:
			xs.append(s.T.add(d))
	return {"xs": xs, "ys": xs.map(func(x): return QuadraticModelSituation.f(s, x)), "heads": [v(s), fname(s)]}


## The worked solutions for the top of the model, ending at `final`.
static func top_methods(s: Dictionary, final: String, result: Dictionary, which: Array) -> Dictionary:
	var out := {}
	var vtx := "(%s, %s)" % [D(s.T), D(s.H)]
	var at := "%s(%s) = %s" % [f1(s), D(s.T), D(s.H)]
	if "vertex-in-context" in which:
		out["vertex-in-context"] = method(["The top is the vertex: %s = −b/(2a) = %s/%s = %s" % [v(s), D(s.b.neg()), D(s.a.mul(2)), D(s.T)], at,
			"So the vertex is %s. %s" % [vtx, final]], result)
	if "gdc-max" in which:
		out["gdc-max"] = method(["Graph y = %s on the GDC and use maximum: %s" % [general(s), vtx], final], result)
	if "derivative" in which:
		out["derivative"] = method(["%s′(%s) = %s" % [f1(s), v(s), Fmt.terms([s.a.mul(2), s.b], [1, 0], v(s), true)],
			"%s′(%s) = 0 when %s = %s" % [f1(s), v(s), v(s), D(s.T)], at, final], result)
	if "symmetry-of-flight" in which:
		var far: Q = s.T.mul(2)
		out["symmetry-of-flight"] = method(["%s(0) = %s, and %s = %s again when %s = 0, at %s = %s" % [
			f1(s), D(s.h0), fname(s), D(s.h0), Fmt.terms([s.a, s.b], [2, 1], v(s), true), v(s), D(far)],
			"The top is halfway between: %s = %s ÷ 2 = %s" % [v(s), D(far), D(s.T)], at, final], result)
	return out


# ── fn-ext-quadratic-model ───────────────────────────────────

func u_max_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("number", {"v": s.H}, {}, "", top_unit(s))
	ans.show = "dec"
	var out := {"asked": "Find the maximum %s." % ("height" if ball(s) else "area"), "lines": [setting(s), model_line(s)], "given": export(s), "answer": ans}
	if rep == "graph":
		out.graph = graph_of(s)
		out.lines = [setting(s), "The graph of y = %s is shown." % model_line(s)]
	out.methods = top_methods(s, "So %s." % Answer.text(ans), ans.values, ["vertex-in-context", "gdc-max", "derivative"])
	out.wrongs = [wrong({"v": s.T}, REF_SWAP)]
	out.generic = [{"v": s.h0}, {"v": s.H.add(s.h0)}, {"v": s.H.sub(s.h0)}, {"v": s.T.mul(2)}]
	out.pick_wrongs = [NOT_ROOTS, NOT_START, NOT_DOUBLE]
	return out


func u_time_of_max(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("number", {"v": s.T}, {}, "%s = " % v(s), at_unit(s))
	ans.show = "dec"
	var asked := "When does the ball reach its greatest height?" if ball(s) else "Find the width that gives the largest area."
	var final := "So %s." % Answer.text(ans)
	var out := {"asked": asked, "lines": [setting(s), model_line(s)], "given": export(s), "answer": ans}
	var ms := top_methods(s, final, ans.values, ["vertex-in-context", "gdc-max", "derivative", "symmetry-of-flight"])
	if rep == "graph":
		out.graph = graph_of(s)
		out.lines = [setting(s), "The graph of y = %s is shown." % model_line(s)]
	elif rep == "table":
		var t := table_of(s)
		out.table = t
		out.lines = [setting(s), "Some values of %s are in the table." % fname(s)]
		var x1: Q = t.xs[0]
		var x2: Q = t.xs[t.xs.size() - 1]
		var fit := "The values fit %s = %s" % [fname(s), general(s)]
		for k in ms:
			if k == "symmetry-of-flight":
				ms[k] = method(["%s(%s) = %s(%s) = %s" % [f1(s), D(x1), f1(s), D(x2), D(t.ys[0])],
					"The top is halfway between equal values: %s = (%s + %s)/2 = %s" % [v(s), D(x1), D(x2), D(s.T)], final], ans.values)
			else:
				ms[k] = method([fit] + ms[k].steps, ans.values)
	out.methods = ms
	out.wrongs = [wrong({"v": s.H}, REF_SWAP)]
	out.generic = [{"v": s.T.mul(2)}, {"v": s.T.add(1)}, {"v": s.b}, {"v": s.T.sub(1)}]
	out.pick_wrongs = [NOT_ROOTS, NOT_START, NOT_DOUBLE if ball(s) else NOT_SQUARE]
	return out


func u_zero_time(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("number", {"v": s.land}, {}, "t = ", " s")
	ans.show = "sf" if s.paper == 2 else "dec"
	var sq := "%s/%s" % [D(s.H), D(s.a.neg())]
	var r := "√(%s)" % sq if s.paper == 2 else D(s.land.sub(s.T))
	var steps := ["Complete the square: h(t) = " + vertex_form(s),
		"h(t) = 0 when (t − %s)² = %s, so t = %s ± %s" % [D(s.T), sq, D(s.T), r],
		"t = %s or t = %s" % [Answer.shown(ans, s.land), Answer.shown(ans, s.neg)],
		"t = %s is before the throw, so it is rejected" % Answer.shown(ans, s.neg), "So %s." % Answer.text(ans)]
	return {"asked": "When does the ball land?", "lines": [setting(s), model_line(s)],
		"given": export(s), "answer": ans, "wrongs": [wrong({"v": s.neg}, REF_NEGATIVE)],
		"generic": [{"v": s.T}, {"v": s.T.mul(2)}, {"v": s.land.add(1)}, {"v": s.H}],
		"methods": {"any": method(steps, ans.values)}}


func u_form_area_model(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("named", {"v0": s.T, "v1": s.H}, {"names": ["x", "A"], "units": [" m", " m²"]})
	var final := "So %s." % Answer.text(ans)
	var length := "%s − 2x" % N(s.L) if s.wall else "%s − x" % N(s.L.div(2))
	var why := "The sides are x, x and a length of %s, using all %s m" % [length, N(s.L)] if s.wall \
		else "Two widths and two lengths use %s m, so the length is %s" % [N(s.L), length]
	var model := "A(x) = x(%s) = %s" % [length, general(s)]
	var ms := {
		"vertex-in-context": method([why, model, "The vertex: x = −b/(2a) = %s/%s = %s, and A(%s) = %s" % [N(s.b.neg()), N(s.a.mul(2)), N(s.T), N(s.T), N(s.H)], final], ans.values),
		"derivative": method([why, model, "A′(x) = %s = 0 when x = %s, and A(%s) = %s" % [Fmt.terms([s.a.mul(2), s.b], [1, 0], "x"), N(s.T), N(s.T), N(s.H)], final], ans.values),
	}
	var gen: Array = [{"v0": s.L.div(2), "v1": s.L.sq().div(8)}, {"v0": s.T.mul(2), "v1": s.H.mul(2)}, {"v0": s.T, "v1": s.H.mul(2)}]
	if s.wall:
		# A square pen against the wall: three sides of L/3.
		gen.push_front({"v0": s.L.div(3), "v1": s.L.div(3).sq()})
	return {"asked": "Write A(x), then find the width x that gives the largest area, and that area.", "lines": [setting(s)],
		"given": export(s), "answer": ans, "generic": gen, "methods": ms,
		"pick_wrongs": [NOT_SQUARE if s.wall else NOT_ROOTS, NOT_START, NOT_XY]}


func u_interpret_vertex(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var T := D(s.T)
	var H := D(s.H)
	var opts: Array
	if ball(s):
		opts = ["The ball is highest, %s m, after %s s" % [H, T], "The ball is highest, %s m, after %s s" % [T, H],
			"The ball lands after %s s, %s m away" % [T, H], "The ball starts at %s m and is highest after %s s" % [H, T]]
	else:
		opts = ["The area is largest, %s m², when the width is %s m" % [H, T], "The area is largest, %s m², when the width is %s m" % [T, H],
			"The pen is %s m wide and %s m long" % [T, H], "The fence is %s m long and the area is %s m²" % [T, H]]
	var ans := Answer.make("choice", {"v": opts[0]}, {"options": opts})
	var lines := [setting(s), "%s = %s" % [fname(s), vertex_form(s)]]
	if rep == "words":
		lines = [setting(s), "The graph of %s against %s has its vertex at (%s, %s)." % [fname(s), v(s), T, H]]
	var steps := ["In a(%s − h)² + k the vertex is (h, k) = (%s, %s), and a < 0, so it is a maximum" % [v(s), T, H],
		"h = %s is the %s and k = %s is the greatest %s" % [T, "time in seconds" if ball(s) else "width in metres", H, "height in metres" if ball(s) else "area in m²"],
		"So: %s." % Answer.text(ans)]
	return {"asked": "What does the vertex mean here?", "lines": lines, "given": export(s), "answer": ans,
		"wrongs": [wrong({"v": opts[1]}, REF_SWAP)], "generic": [{"v": opts[2]}, {"v": opts[3]}],
		"methods": {"vertex-in-context": method(steps, ans.values)},
		"pick_wrongs": [NOT_ROOTS, NOT_START, NOT_DOUBLE]}


func u_second_time_at_height(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	# A first time strictly between 0 and the top, on the half-second grid.
	var t1 := Q.new(rng.int_in(1, s.T.mul(2).n - 1), 2)
	var y1 := QuadraticModelSituation.f(s, t1)
	var t2: Q = s.T.mul(2).sub(t1)
	var ans := Answer.make("number", {"v": t2}, {}, "t = ", " s")
	ans.show = "dec"
	var out := {"asked": "At what other time is it at that height?", "given": export(s).merged({"t1": t1.key()}), "answer": ans,
		"lines": [setting(s), "h(t) = %s. The ball is %s m high at t = %s s." % [general(s), D(y1), D(t1)]]}
	var find_T := "The top is at t = −b/(2a) = %s/%s = %s" % [D(s.b.neg()), D(s.a.mul(2)), D(s.T)]
	if rep == "words":
		out.lines = ["A ball is thrown upwards and is highest after %s s. It is %s m high at t = %s s." % [D(s.T), D(y1), D(t1)]]
		find_T = "The top is at t = %s" % D(s.T)
	elif rep == "table":
		out.table = table_of(s)
		out.lines = [setting(s), "Some heights are in the table. The ball is %s m high at t = %s s." % [D(y1), D(t1)]]
		find_T = "h(0) = h(%s) = %s, so the top is halfway, at t = %s" % [D(s.T.mul(2)), D(s.h0), D(s.T)]
	out.methods = {"symmetry-of-flight": method([find_T, "The two times are the same distance either side of it: %s − %s = %s" % [D(s.T), D(t1), D(s.T.sub(t1))],
		"t = %s + %s = %s" % [D(s.T), D(s.T.sub(t1)), D(t2)], "So %s." % Answer.text(ans)], ans.values)}
	out.generic = [{"v": t1.add(s.T)}, {"v": s.T.sub(t1)}, {"v": s.T.mul(2).add(t1)}, {"v": s.T}]
	out.pick_wrongs = [NOT_ROOTS, NOT_START, NOT_ADD]
	return out


func u_model_from_features(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("poly", {"c0": s.a, "c1": s.b, "c2": s.c}, {"powers": [2, 1, 0], "var": "t"}, "h(t) = ")
	ans.show = "dec"
	var steps := ["The top (%s, %s) is the vertex: h(t) = a(t − %s)² + %s" % [D(s.T), D(s.H), D(s.T), D(s.H)],
		"h(0) = %s: a × %s + %s = %s, so a = %s" % [D(s.h0), D(s.T.sq()), D(s.H), D(s.h0), D(s.a)],
		"h(t) = %s = %s" % [vertex_form(s), general(s)], "So %s." % Answer.text(ans)]
	var bad_a: Q = s.a.neg()
	return {"asked": "Find the model h(t) = at² + bt + c.", "given": export(s), "answer": ans,
		"lines": ["A ball is thrown upwards from %s m. It is highest, %s m, after %s s." % [D(s.h0), D(s.H), D(s.T)]],
		"generic": [{"c0": bad_a, "c1": bad_a.mul(s.T).mul(-2), "c2": bad_a.mul(s.T.sq()).add(s.H)},
			{"c0": s.a, "c1": s.b.neg(), "c2": s.c}, {"c0": s.a, "c1": s.b, "c2": s.H}, {"c0": s.a, "c1": s.b.neg(), "c2": s.H}],
		"methods": {"vertex-in-context": method(steps, ans.values)},
		"pick_wrongs": [NOT_ROOTS, NOT_DOUBLE, NOT_START_TOP]}
