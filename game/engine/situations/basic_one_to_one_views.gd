class_name BasicOneToOneViews
extends ExtensionViews
## The views on the `basic-one-to-one` situation (FAL-424): one builder per unknown of
## fn-inverse-reflection. The sketch is pick-the-graph (GdcKit.pick): the right graph swaps
## every point of f, and each wrong one reflects f in the wrong line. Points and values are
## typed; a statement about the inverse is one of four sentences (the `choice` kind).

const R_RECIPROCAL := "SL2.2.inverse-undo#0"
const R_AXIS := "SL2.2.inverse-undo#1"
const R_VALUE := "SL2.2.inverse-undo#2"
const R_Y_INTERCEPT := "SL2.4.symmetry#0"
const R_SIDE := "SL2.4.symmetry#1"


func needs() -> Dictionary:
	return {
		"sketch-inverse": {"kind": "curve"},
		"area-by-symmetry": {"kind": "area"},
		"image-point": {"kind": "curve"},
		"point-from-inverse": {"kind": "curve"},
		"inverse-from-table": {"kind": "table"},
		"inverse-from-graph": {"kind": "curve"},
		"inverse-from-rule": {"kind": "rule"},
		"intercepts-of-inverse": {"kind": "cross"},
		"asymptotes-of-inverse": {"kind": "asym"},
		"meeting-on-y-equals-x": {"kind": "meet"},
		"is-self-inverse": {"kind": "self"},
	}


## Paper 2 changes the sums for a value from a rule and for an area; the readings are
## the same on either paper, so the exam's even split still holds.
func papers(_unknown: String, _rep: String, _angle: String) -> Array:
	return [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	var own: Dictionary = out.get("given", {}) if out.get("given") != null else {}
	out.given = BasicOneToOneSituation.export(s)
	out.given.merge(ExtensionViews.export(own), true)
	return out


# ── Helpers ──────────────────────────────────────────────────

static func N(v: Variant) -> String:
	return Fmt.num(v)


## The rule as a question shows it: half a parabola has to say which half.
static func eqn(s: Dictionary) -> String:
	var rule := BasicFunctionSituation.eqn(s)
	return "%s, for x ≥ %s" % [rule, N(s.lo)] if s.get("form", "") == "half" else rule


static func ways(steps: Dictionary, last: String, ans: Dictionary) -> Dictionary:
	return BasicFunctionViews.ways(steps, last, ans)


static func exact(kind: String, values: Dictionary, label: String = "") -> Dictionary:
	var ans := Answer.make(kind, values, {}, label)
	ans.exact = true
	return ans


static func plot(s: Dictionary, dots: Array = []) -> Dictionary:
	var g := Plot.spec([BasicOneToOneSituation.points(s)], dots, -8, 8, -8, 8)
	g.one_colour = true
	return g


## A point with its coordinates.
static func dot(p: int, q: int) -> Array:
	return [p, q, Fmt.point(p, q)]


# ── The sketch ───────────────────────────────────────────────

func u_sketch_inverse(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var pts := BasicOneToOneSituation.points(s)
	var keys: Array = s.keys.filter(func(k): return absi(k[0]) <= 8 and absi(k[1]) <= 8)
	var card := func(fx: Callable) -> Dictionary:
		var g := GdcKit.card([pts.map(func(p): return fx.call(p))], keys.map(func(k): var c: Array = fx.call(k); return [c[0], c[1], ""]), BasicOneToOneSituation.WIN)
		g.one_colour = true
		return g
	var wrongs := [
		{"graph": card.call(func(p): return [p[0], -p[1]]), "ref": R_AXIS, "mistake": "x-axis", "why": "this reflects f in the x-axis, not in y = x"},
		{"graph": card.call(func(p): return [-p[0], p[1]]), "ref": R_AXIS, "mistake": "y-axis", "why": "this reflects f in the y-axis, not in y = x"},
		{"graph": card.call(func(p): return [-p[1], -p[0]]), "ref": "", "mistake": "y=-x", "why": "this reflects f in y = −x, so each point also changes sign"},
	]
	var picked := GdcKit.pick(card.call(func(p): return [p[1], p[0]]), wrongs, rng)
	var ans: Dictionary = picked.answer
	var a: Array = keys[0]
	var b: Array = keys[1]
	var swap := "The points %s and %s are on f, so %s and %s are on f⁻¹" % [Fmt.point(a[0], a[1]), Fmt.point(b[0], b[1]), Fmt.point(a[1], a[0]), Fmt.point(b[1], b[0])]
	var out := {"asked": "Which graph shows y = f⁻¹(x)?", "lines": ["The graph of y = f(x) is shown, with its key points marked."],
		"graph": plot(s, keys.map(func(k): return dot(k[0], k[1]))), "answer": ans, "graphs": picked.graphs}
	var last := "The graph through those swapped points is %s. So %s." % [picked.letter, picked.letter]
	out.methods = ways({"swap-coordinates": [swap, "Find the graph through the swapped points"], "reflect-in-y-equals-x": ["f⁻¹ is the mirror image of f in the line y = x", swap],
		"reflect-point": ["Reflect one point in y = x: its coordinates swap", swap]}, last, ans)
	return out


func u_area_by_symmetry(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var m: Q = s.m
	var give := rng.chance(0.5)
	var ans := BasicFunctionViews.value("Area = ", s.area, s)
	var say := func(v: Q) -> String: return BasicFunctionViews.say(v, s)
	var meet := "The graphs of f and f⁻¹ meet at (0, 0) and (%s, %s)." % [Fmt.dec(m), Fmt.dec(m)]
	var lines: Array = ["%s, for x ≥ 0" % eqn(s), meet]
	if give:
		lines.append("The area between the graph of f and the line y = x is %s." % say.call(s.half))
	var out := {"asked": "Find the area of the region between the graphs of f and f⁻¹.", "lines": lines, "answer": ans, "wrongs": [],
		"generic": BasicFunctionViews.nums([s.half, s.area.mul(2), m.sq().div(2)], s.area)}
	if rep == "graph":
		var g := Plot.spec([Plot.sample(func(x): return s.a.to_float() * x * x, 0.0, m.to_float()), Plot.sample(func(x): return sqrt(x / s.a.to_float()), 0.0, m.to_float()),
			Plot.sample(func(x): return x, 0.0, m.to_float())], [[m.to_float(), m.to_float(), ""]], -1, ceili(m.to_float()) + 1, -1, ceili(m.to_float()) + 1)
		out.graph = g
		out.lines = lines + ["The graph shows f, f⁻¹ and y = x."]
	var half := "The area between f and y = x is ∫(x − %s)dx from 0 to %s = %s" % [BasicFunctionSituation.text(s.f), Fmt.dec(m), say.call(s.half)]
	if give:
		half = "The area between f and y = x is given: %s" % say.call(s.half)
	var twice := "f⁻¹ is the mirror image of f in y = x, so the whole region is twice that: 2 × %s" % say.call(s.half)
	out.methods = ways({"reflect-in-y-equals-x": [half, twice], "reflect-point": ["Each point of f between (0, 0) and (%s, %s) has its mirror image on f⁻¹, at the same distance from y = x" % [Fmt.dec(m), Fmt.dec(m)], half, twice]}, "So %s." % Answer.text(ans), ans)
	return out


# ── Points and values ────────────────────────────────────────

func u_image_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var ans := exact("point", {"x": Q.new(q), "y": Q.new(p)})
	var pt := Fmt.point(p, q)
	var out := {"asked": "The point %s is on the graph of f. Find the matching point on the graph of f⁻¹." % pt, "answer": ans,
		"wrongs": [wrong({"x": Q.new(-q), "y": Q.new(-p)}, R_SIDE), wrong({"x": Q.new(q), "y": Q.new(-p)}, R_SIDE)],
		"generic": [{"x": Q.new(p), "y": Q.new(q)}, {"x": Q.new(-p), "y": Q.new(q)}, {"x": Q.new(p), "y": Q.new(-q)}]}
	match rep:
		"graph":
			out.lines = ["The graph of y = f(x) is shown."]
			out.graph = plot(s, [dot(p, q)])
		"equation":
			out.lines = [eqn(s)]
		_:
			out.lines = ["f is one-to-one."]
	var last := "So %s." % Answer.text(ans)
	var swap := "On f⁻¹ the input and the output change places: %s becomes %s" % [pt, Fmt.point(q, p)]
	var mid := Q.new(p + q, 2)
	out.methods = ways({"swap-coordinates": ["%s means f(%s) = %s" % [pt, N(p), N(q)], swap], "reflect-point": ["Reflecting in y = x keeps the distance to the line and swaps the coordinates", swap],
		"midpoint-of-pair": [swap, "Check: the midpoint of the pair is (%s, %s), which is on y = x" % [N(mid), N(mid)]]}, last, ans)
	return out


func u_point_from_inverse(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var ans := exact("point", {"x": Q.new(p), "y": Q.new(q)})
	var pt := Fmt.point(q, p)
	var out := {"asked": "The point %s is on the graph of f⁻¹. Find the matching point on the graph of f." % pt, "answer": ans, "wrongs": [],
		"generic": [{"x": Q.new(q), "y": Q.new(p)}, {"x": Q.new(-p), "y": Q.new(-q)}, {"x": Q.new(-q), "y": Q.new(p)}, {"x": Q.new(p), "y": Q.new(-q)}]}
	if rep == "graph":
		out.lines = ["The graph of y = f⁻¹(x) is shown."]
		var pts: Array = BasicOneToOneSituation.points(s).map(func(c): return [c[1], c[0]])
		var g := Plot.spec([pts], [dot(q, p)], -8, 8, -8, 8)
		g.one_colour = true
		out.graph = g
	else:
		out.lines = ["f is one-to-one."]
	out.methods = ways({"swap-coordinates": ["A point on f⁻¹ undoes a point on f: the input and the output change places", "%s becomes %s" % [pt, Fmt.point(p, q)]]}, "So %s." % Answer.text(ans), ans)
	return out


func u_inverse_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var ans := exact("number", {"v": Q.new(s.inv)}, "f⁻¹(%s) = " % N(a))
	var at_a := BasicFunctionSituation.at(s.f, a)
	var t := BasicFunctionViews.table_of(s, s.xs)
	var out := {"asked": "Find f⁻¹(%s)." % N(a), "lines": ["The table gives values of the one-to-one function f."], "table": t, "answer": ans,
		"wrongs": [wrong({"v": at_a}, R_VALUE)], "generic": BasicFunctionViews.nums([Q.new(a), Q.new(s.inv).add(1), Q.new(1).div(at_a) if not at_a.is_zero() else Q.new(-a), Q.new(s.inv).neg()])}
	out.methods = ways({"swap-coordinates": ["f⁻¹(%s) asks which input gives the output %s" % [N(a), N(a)], "Find %s in the f(x) row and read the x above it: %s" % [N(a), N(s.inv)]]}, "So %s." % Answer.text(ans), ans)
	return out


func u_inverse_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.q
	var ans := exact("number", {"v": Q.new(s.p)}, "f⁻¹(%s) = " % N(a))
	var out := {"asked": "Find f⁻¹(%s)." % N(a), "lines": ["The graph of y = f(x) is shown."], "graph": plot(s), "answer": ans, "wrongs": [],
		"generic": BasicFunctionViews.nums([Q.new(a), Q.new(s.p).add(1), Q.new(s.p).neg(), Q.new(1, a)])}
	out.methods = ways({"solve-f-equals": ["f⁻¹(%s) is the x with f(x) = %s" % [N(a), N(a)], "Go across from y = %s to the curve, then down to the x-axis: x = %s" % [N(a), N(s.p)]]}, "So %s." % Answer.text(ans), ans)
	return out


func u_inverse_from_rule(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Q = Q.of(s.a)
	var inv: Q = Q.of(s.inv)
	var ans := BasicFunctionViews.value("f⁻¹(%s) = " % N(a), inv, s)
	var wrongs: Array = []
	var val: float = BasicFunctionSituation.fl(s.f, a.to_float())
	# Paper 1 options stay exact, so a value that isn't (a root that doesn't come out) has no option.
	if not is_nan(val) and val != 0.0:
		var at_a := BasicFunctionSituation.at(s.f, a)
		if s.paper == 2:
			wrongs = [wrong({"v": at_a}, R_VALUE), wrong({"v": GdcKit.qf(1.0 / val)}, R_RECIPROCAL)]
		elif at_a.d <= 1000:
			wrongs = [wrong({"v": at_a}, R_VALUE), wrong({"v": Q.new(1).div(at_a)}, R_RECIPROCAL)]
	var out := {"asked": "Find f⁻¹(%s), without finding f⁻¹(x)." % N(a), "lines": [eqn(s)], "answer": ans, "wrongs": wrongs,
		"generic": BasicFunctionViews.nums([a, GdcKit.qf(inv.to_float() + 1.0), inv.neg()], inv)}
	var w := BasicFunctionViews.W(inv)
	var solve := "f⁻¹(%s) is the x with f(x) = %s: %s = %s" % [N(a), N(a), BasicFunctionSituation.text(s.f), N(a)]
	var undo := "Undo the steps of f in reverse order, starting from %s" % N(a)
	out.methods = ways({"solve-f-equals": [solve, "Solve it: x = %s" % w], "reverse-flow": [undo, "That ends at x = %s" % w]}, "So %s." % Answer.text(ans), ans)
	return out


func u_intercepts_of_inverse(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var txt := func(x: int, y: int) -> String: return "x-intercept (%s, 0), y-intercept (0, %s)" % [N(x), N(y)]
	var right: String = txt.call(q, p)
	var out := {"asked": "Find the intercepts of the graph of f⁻¹."}
	out.merge(BasicFunctionViews.choose(right, [], [txt.call(p, q), txt.call(-q, -p), txt.call(-p, -q), txt.call(q, -p)]))
	if rep == "graph":
		out.lines = ["The straight-line graph of y = f(x) is shown."]
		out.graph = Plot.spec([[[-9.0, BasicFunctionSituation.fl(s.f, -9.0)], [9.0, BasicFunctionSituation.fl(s.f, 9.0)]]], [dot(p, 0), dot(0, q)], -8, 8, -8, 8)
	else:
		out.lines = ["The graph of f crosses the x-axis at (%s, 0) and the y-axis at (0, %s)." % [N(p), N(q)]]
	out.methods = ways({"swap-coordinates": ["(%s, 0) on f gives (0, %s) on f⁻¹" % [N(p), N(p)], "(0, %s) on f gives (%s, 0) on f⁻¹" % [N(q), N(q)]]}, "So %s." % right, out.answer)
	return out


func u_asymptotes_of_inverse(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := {"asked": "State the asymptotes of the graph of f⁻¹."}
	var right: String
	var steps: Array
	if s.form == "rat":
		var h: int = s.h
		var big: int = s.A
		right = "x = %s and y = %s" % [N(big), N(h)]
		out.merge(BasicFunctionViews.choose(right, [], ["x = %s and y = %s" % [N(h), N(big)], "x = %s and y = %s" % [N(-big), N(-h)], "x = %s and y = %s" % [N(-h), N(-big)], "x = %s and y = %s" % [N(big), N(-h)], "x = %s and y = %s" % [N(-big), N(h)], "x = %s and y = %s" % [N(big + 1), N(h)]]))
		steps = ["f has asymptotes x = %s and y = %s" % [N(h), N(big)], "Swapping x and y swaps the two lines"]
		match rep:
			"graph":
				out.lines = ["The graph of y = f(x) is shown, with its asymptotes dashed."]
				out.graph = RationalCards.plot([float(big), float(s.B), float(h)])
			"words":
				out.lines = ["The graph of f has asymptotes x = %s and y = %s." % [N(h), N(big)]]
			_:
				out.lines = [eqn(s)]
	else:
		var c: int = s.c
		right = "x = %s" % N(c)
		out.merge(BasicFunctionViews.choose(right, [], ["y = %s" % N(c), "x = %s" % N(-c), "y = %s" % N(-c), "x = 0"]))
		steps = ["f has the asymptote y = %s" % N(c), "Swapping x and y gives a vertical line"]
		match rep:
			"graph":
				out.lines = ["The graph of y = f(x) is shown, with its asymptote dashed."]
				var g := Plot.spec([Plot.sample(func(x): return BasicFunctionSituation.fl(s.f, x), -8.0, 3.2).filter(func(p): return absf(p[1]) <= 8.0)], [], -8, 8, -8, 8, [[float(c), ""]])
				out.graph = g
			"words":
				out.lines = ["The graph of f has the asymptote y = %s." % N(c)]
			_:
				out.lines = [eqn(s)]
	out.methods = ways({"swap-coordinates": steps}, "So %s." % right, out.answer)
	return out


func u_meeting_on_y_equals_x(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var ans := exact("point", {"x": Q.new(p), "y": Q.new(p)})
	var at0: Q = Q.of(BasicFunctionSituation.at(s.f, 0))
	var out := {"asked": "f is increasing. Find where the graphs of f and f⁻¹ meet.", "answer": ans,
		"wrongs": [wrong({"x": Q.new(0), "y": at0}, R_Y_INTERCEPT)] if not at0.is_zero() and s.form == "line" else [],
		"generic": [{"x": Q.new(-p), "y": Q.new(-p)}, {"x": Q.new(p), "y": Q.new(0)}, {"x": Q.new(p + 1), "y": Q.new(p + 1)}, {"x": Q.new(0), "y": Q.new(p)}]}
	if rep == "graph":
		out.lines = ["The graph of y = f(x) is shown."]
		var lo: float = -8.0 if s.form == "line" else -float(s.f.n.n) / float(s.f.m.n)
		var g := Plot.spec([Plot.sample(func(x): return BasicFunctionSituation.fl(s.f, x), maxf(lo, -8.0), 8.0).filter(func(c): return absf(c[1]) <= 8.0)], [], -8, 8, -8, 8)
		g.one_colour = true
		out.graph = g
		out.given = {"x_y": true}
	else:
		out.lines = [eqn(s)]
	var eq := "Solve f(x) = x: %s = x" % BasicFunctionSituation.text(s.f)
	var why := "f is increasing, so f and f⁻¹ meet on y = x"
	var sv := "That gives x = %s, and y = x there" % N(p)
	out.methods = ways({"reflect-in-y-equals-x": [why, "Find where the curve crosses y = x: " + sv.to_lower()], "solve-f-equals": [why, eq, sv]}, "So %s." % Answer.text(ans), ans)
	return out


func u_is_self_inverse(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: Variant = s.p
	var q: Variant = s.q
	var yes := "Yes: the graph is its own mirror image in y = x"
	var no := "No: %s is on the graph, but %s is not" % [Fmt.point(p, q), Fmt.point(q, p)]
	var right := yes if s.inverse else no
	var wrong_verdict := "No: the graph is not a line through the origin" if s.inverse else "Yes: swapping x and y gives the same rule"
	var other := no if s.inverse else yes
	var out := {"asked": "Is f its own inverse?"}
	out.merge(BasicFunctionViews.choose(right, [], [wrong_verdict, other if s.inverse == false else "No: f has no inverse", "Yes: it has a point on y = x, so it must be symmetric", "No: f(x) and 1/f(x) are different"]))
	if rep == "graph":
		out.lines = ["The graph of y = f(x) is shown."]
		var curves: Array
		if s.form in ["recip", "recip-up"]:
			var f: Dictionary = s.f
			curves = RationalCards.branches(RationalCards.triple(f.a.to_float(), f.b.to_float(), f.c.to_float(), f.d.to_float()))
		else:
			curves = [Plot.sample(func(x): return BasicFunctionSituation.fl(s.f, x), -8.0, 8.0).filter(func(c): return absf(c[1]) <= 8.0)]
		var g := Plot.spec(curves, [[Q.of(p).to_float(), Q.of(q).to_float(), Fmt.point(p, q)]], -8, 8, -8, 8)
		g.one_colour = true
		out.graph = g
	else:
		out.lines = [eqn(s)]
	var check := "Take the point %s on f: its mirror image in y = x is %s" % [Fmt.point(p, q), Fmt.point(q, p)]
	var verdict: String = "Every swapped point is on the graph too" if s.inverse else "Put x = %s into f: it does not give %s" % [N(q), N(p)]
	out.methods = ways({"reflect-in-y-equals-x": ["f is its own inverse when its graph is symmetric in y = x", check, verdict],
		"midpoint-of-pair": [check, "The midpoint of the pair is on y = x, so the test is whether the second point is on f", verdict]}, "So: %s." % right, out.answer)
	return out
