class_name LineCrossingViews
extends ExtensionViews
## The views on the `line-crossing` situation: one builder per unknown of
## fn-ext-intersection-lines (FAL-424). A meeting point is a typed point (`point`), exact, or to
## 3 s.f. on Paper 2, where the GDC's intersect does the work. "Does it lie on both" and "do they
## meet" are picks of written statements. The catalogue has no error-spot misconception here, so
## method-pick is the only extra format.

const T := "SL2.1.intersection-lines#"
const R_X_ONLY := T + "0"
const R_SIGN := T + "1"
const R_FAR := T + "2"

## Methods that don't find a meeting point, for method-pick (after the catalogue's weak ones).
const NOT_MEET := [
	{"name": "Compare the two y-intercepts", "why": "each intercept is where one line meets the y-axis, not the other line"},
	{"name": "Put x = 0 into both lines", "why": "that only finds the y-intercepts"},
	{"name": "Add the two gradients", "why": "the sum of the gradients says nothing about where the lines cross"},
]


func needs() -> Dictionary:
	return {
		"meet-slope-intercept": {"mode": "one", "form": "sl"},
		"meet-general": {"mode": "one", "form": "gen"},
		"point-on-both": {"mode": "one", "form": "sl"},
		"do-they-meet": {"mode": "mix"},
		"meet-from-graph": {"mode": "one", "form": "sl"},
		"line-through-meeting-point": {"mode": "one", "form": "gen"},
		"constant-from-meeting-point": {"mode": "one", "form": "sl"},
	}


## A line in words is its gradient and intercept.
func need(unknown: String, rep: String) -> Dictionary:
	var n := super.need(unknown, rep)
	n.erase("rep")
	if unknown == "line-through-meeting-point" and rep == "words":
		n.form = "sl"
	return n


func extra() -> Dictionary:
	var mp := ["method-pick"]
	return {"meet-slope-intercept": mp, "meet-general": mp, "do-they-meet": mp, "meet-from-graph": mp, "line-through-meeting-point": mp,
		"constant-from-meeting-point": mp}


## The GDC's intersect is Paper 2; everything else is Paper 1.
func papers(_unknown: String, _rep: String, angle_id: String) -> Array:
	return [2] if angle_id == "gdc-intersect" else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = LineCrossingSituation.export(s)
	if out.answer.kind == "point":
		out.trap = Answer.rounding_trap_all(out.answer)
	return out


static func PF(v: Variant) -> String:
	return Fmt.paren(v)


## y = mx + c: decimals where they end, so Paper 2's lines read as a GDC shows them.
static func yeq(m: Variant, c: Variant, decimal: bool = false) -> String:
	return "y = " + Fmt.terms([Q.of(m), Q.of(c)], [1, 0], "x", decimal)


static func gk(a: Variant, b: Variant, k: Variant) -> String:
	return Answer.gline_text(a, b, 0).trim_suffix(" = 0") + " = " + N(k)


static func L1(s: Dictionary) -> String:
	return yeq(s.m1, s.c1, s.get("paper", 1) == 2)


static func L2(s: Dictionary) -> String:
	return yeq(s.m2, s.c2, s.get("paper", 1) == 2)


static func V(s: Dictionary, v: Variant) -> String:
	return Fmt.sf(v, 6) if s.paper == 2 else N(v)


static func P_(s: Dictionary, v: Variant) -> String:
	return "(%s)" % V(s, v) if Q.of(v).sign() < 0 else V(s, v)


## The meeting point as an answer: exact, or to 3 s.f. on Paper 2.
static func point(s: Dictionary) -> Dictionary:
	var ans := Answer.make("point", {"x": s.X, "y": s.Y})
	if s.paper == 2:
		ans.show = "sf"
	else:
		ans.exact = true
	return ans


static func fin(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## mx + c as the lines are written.
static func rhs(s: Dictionary, m: Variant, c: Variant) -> String:
	return yeq(m, c, s.paper == 2).trim_prefix("y = ")


## A coefficient as the lines write it.
static func C(s: Dictionary, v: Variant) -> String:
	return Fmt.dec(v) if s.paper == 2 else N(v)


static func CP(s: Dictionary, v: Variant) -> String:
	return "(%s)" % C(s, v) if Q.of(v).sign() < 0 or not Q.of(v).is_int() and s.paper == 1 else C(s, v)


## The move from equal right-hand sides to x, then y from L₁.
static func sl_x(s: Dictionary) -> String:
	var dm: Q = s.m1.sub(s.m2)
	var dc: Q = s.c2.sub(s.c1)
	if dm.eq(1):
		return "Collect the x terms: x = %s." % V(s, s.X)
	return "Collect the x terms: %s = %s, so x = %s." % [Fmt.terms([dm], [1], "x", s.paper == 2), C(s, dc), V(s, s.X)]


static func sl_y(s: Dictionary) -> String:
	var c: Q = s.c1
	var tail: String = "" if c.is_zero() else (" − " if c.sign() < 0 else " + ") + C(s, c.abs_q())
	return "Put x = %s into L₁: y = %s × %s%s = %s." % [V(s, s.X), CP(s, s.m1), P_(s, s.X), tail, V(s, s.Y)]


static func sl_equate(s: Dictionary) -> Array:
	return ["Both lines give y, so set them equal: %s = %s." % [rhs(s, s.m1, s.c1), rhs(s, s.m2, s.c2)], sl_x(s), sl_y(s)]


static func sl_sub(s: Dictionary) -> Array:
	return ["Put y = %s into L₂: %s = %s." % [rhs(s, s.m1, s.c1), rhs(s, s.m1, s.c1), rhs(s, s.m2, s.c2)], sl_x(s), sl_y(s)]


static func sl_elim(s: Dictionary) -> Array:
	return ["Subtract L₂ from L₁ to remove y: 0 = %s." % rhs(s, s.m1.sub(s.m2), s.c1.sub(s.c2)), sl_x(s), sl_y(s)]


static func gen_sub(s: Dictionary) -> Array:
	var det: int = s.a1 * s.b2 - s.b1
	var rhs: int = s.a1 * s.k2 - s.k1
	return ["From L₂, x = %s. Put it into L₁: %s(%s)%s = %s." % [Fmt.poly([-s.b2, s.k2], "y"), N(s.a1), Fmt.poly([-s.b2, s.k2], "y"), Fmt.term(Q.new(s.b1), 1, false, "y"), N(s.k1)],
		"Collect: %s = %s, so y = %s." % [Fmt.poly([-det, 0], "y"), N(-rhs), V(s, s.Y)], "Then x = %s − %s × %s = %s." % [N(s.k2), PF(s.b2), P_(s, s.Y), V(s, s.X)]]


static func gen_elim(s: Dictionary) -> Array:
	var det: int = s.a1 * s.b2 - s.b1
	var rhs: int = s.a1 * s.k2 - s.k1
	return ["Multiply L₂ by %s: %s." % [PF(s.a1), gk(s.a1, s.a1 * s.b2, s.a1 * s.k2)], "Subtract L₁ to remove x: %s = %s, so y = %s." % [Fmt.poly([det, 0], "y"), N(rhs), V(s, s.Y)],
		"Then x = %s − %s × %s = %s." % [N(s.k2), PF(s.b2), P_(s, s.Y), V(s, s.X)]]


static func gen_y(a: int, b: int, k: int) -> String:
	return yeq(Q.new(-a, b), Q.new(k, b))


static func point_wrongs(s: Dictionary) -> Array:
	return [{"x": s.Y, "y": s.X}, {"x": s.X, "y": s.Y.neg()}, {"x": s.X.neg(), "y": s.Y}, {"x": s.X.neg(), "y": s.Y.neg()}]


func u_meet_slope_intercept(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := point(s)
	var out := {"asked": "Find the point where L₁ and L₂ meet.", "answer": ans, "lines": ["L₁: " + L1(s), "L₂: " + L2(s)],
		"pick_wrongs": NOT_MEET}
	if rep == "graph":
		out.graph = plot(s)
	out.wrongs = [wrong({"x": s.X, "y": Q.new(0), "alone": true}, R_X_ONLY)]
	out.generic = point_wrongs(s)
	out.methods = {
		"substitution": method(sl_sub(s) + [fin(ans)], ans.values),
		"equate-y": method(sl_equate(s) + [fin(ans)], ans.values),
		"elimination": method(sl_elim(s) + [fin(ans)], ans.values),
	}
	return out


func u_meet_general(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := point(s)
	var out := {"asked": "Find the point where L₁ and L₂ meet.", "answer": ans, "lines": ["L₁: " + gk(s.a1, s.b1, s.k1), "L₂: " + gk(1, s.b2, s.k2)],
		"pick_wrongs": NOT_MEET}
	# The subtraction with one sign wrong: a₁b₂ + b₁ for a₁b₂ − b₁.
	var slip: int = s.a1 * s.b2 + s.b1
	out.wrongs = [wrong({"x": s.X, "y": Q.new(0), "alone": true}, R_X_ONLY)]
	if slip != 0:
		var y := Q.new(s.a1 * s.k2 - s.k1, slip)
		out.wrongs.append(wrong({"x": Q.new(s.k2).sub(y.mul(s.b2)), "y": y}, R_SIGN))
	out.generic = point_wrongs(s)
	var gdc := ["Rearrange to y = …: %s and %s." % [gen_y(s.a1, s.b1, s.k1), gen_y(1, s.b2, s.k2)], "Graph both and use intersect: x = %s, y = %s." % [V(s, s.X), V(s, s.Y)], fin(ans)]
	out.methods = {
		"substitution": method(gen_sub(s) + [fin(ans)], ans.values),
		"elimination": method(gen_elim(s) + [fin(ans)], ans.values),
		"gdc-intersect": method(gdc, ans.values),
	}
	return out


func u_point_on_both(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var both := "It lies on both lines"
	var one := "It lies on L₁ but not on L₂"
	var two := "It lies on L₂ but not on L₁"
	var none := "It lies on neither line"
	var right: String = {"both": both, "one": one, "two": two, "none": none}[s.on]
	var out := {"asked": "Show whether the point (%s, %s) lies on L₁ and L₂." % [N(s.px), N(s.py)]}
	out.lines = ["L₁: " + L1(s), "L₂: " + L2(s)] if rep == "equation" else ["L₁ has gradient %s and y-intercept %s." % [N(s.m1), N(s.c1)], "L₂ has gradient %s and y-intercept %s." % [N(s.m2), N(s.c2)]]
	out.merge(InverseRuleViews.choose(right, [], [both, one, two, none]))
	var at := func(name: String, m: Q, c: Q) -> String:
		var y: Q = m.mul(s.px).add(c)
		return "On %s at x = %s, y = %s × %s%s = %s, %s %s." % [name, N(s.px), PF(m), PF(s.px), Fmt.plus(c), N(y), "the same as" if y.eq(s.py) else "not", N(s.py)]
	out.methods = {"any": method([at.call("L₁", s.m1, s.c1), at.call("L₂", s.m2, s.c2), right + "."], {"v": right})}
	return out


func u_do_they_meet(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var meet := "They meet at one point, because the gradients are different"
	var never := "They never meet, because the gradients are equal and the intercepts differ"
	var same := "They are the same line, so they share every point"
	var far := "They do meet far away, because any two lines cross somewhere"
	var right: String = {"one": meet, "para": never, "same": same}[s.rel]
	var out := {"asked": "Do L₁ and L₂ meet? Give the reason.", "pick_wrongs": NOT_MEET}
	if rep == "equation":
		out.lines = ["L₁: " + L1(s), "L₂: " + gk(s.a2, s.b2, s.k2)]
	else:
		out.lines = ["L₁ has gradient %s and y-intercept %s." % [N(s.m1), N(s.c1)], "L₂ goes through (%s, %s) and (%s, %s)." % [N(s.qx), N(s.qy), N(s.rx), N(s.ry)]]
		# Neither line is in general form here, so the working has no −a/b to use.
		out.titles = {"coefficient-shortcut": "Compare the gradients and intercepts"}
	var bad: Array = [InverseRuleViews.tag(far, R_FAR)] if s.rel == "para" else []
	out.merge(InverseRuleViews.choose(right, bad, [meet, never, same, far]))
	var second := "L₂ rearranges to %s." % L2(s) if rep == "equation" else "L₂ has gradient (%s − %s)/(%s − %s) = %s, so it is %s." % [N(s.ry), PF(s.qy), N(s.rx), PF(s.qx), N(s.m2), L2(s)]
	var eq_step: String
	match s.rel:
		"one":
			eq_step = "Set them equal: %s = %s has the one solution x = %s." % [Fmt.poly([s.m1, s.c1]), Fmt.poly([s.m2, s.c2]), N(s.X)]
		"para":
			eq_step = "Set them equal: %s = %s. The x terms cancel and leave %s = %s, which is false." % [Fmt.poly([s.m1, s.c1]), Fmt.poly([s.m2, s.c2]), N(s.c1), N(s.c2)]
		_:
			eq_step = "Set them equal: %s = %s is true for every x." % [Fmt.poly([s.m1, s.c1]), Fmt.poly([s.m2, s.c2])]
	var cmp := "The gradients are %s and %s, the intercepts %s and %s." % [N(s.m1), N(s.m2), N(s.c1), N(s.c2)]
	var shortcut := second
	if rep == "equation":
		shortcut = "For L₂, a = %s and b = %s, so m = −a/b = −(%s)/(%s) = %s. Put x = 0: %s, so its y-intercept is %s." % [N(s.a2), N(s.b2), N(s.a2), N(s.b2), N(s.m2), gk(0, s.b2, s.k2), N(s.c2)]
	out.methods = {
		"equate-y": method([second, eq_step, right + "."], {"v": right}),
		"coefficient-shortcut": method([shortcut, cmp, right + "."], {"v": right}),
	}
	return out


## Both lines on a grid.
static func plot(s: Dictionary) -> Dictionary:
	var w: Array = LineCrossingSituation.WIN
	var curve := func(m: Q, c: Q) -> Array:
		var mf := m.to_float()
		var cf := c.to_float()
		return Plot.sample(func(x: float) -> float:
			var y := mf * x + cf
			return y if y >= w[2] and y <= w[3] else NAN, w[0], w[1])
	return Plot.spec([curve.call(s.m1, s.c1), curve.call(s.m2, s.c2)], [], w[0], w[1], w[2], w[3])


func u_meet_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := point(s)
	var out := {"asked": "The two lines are drawn on the grid. Find where they meet, and confirm it with algebra.", "answer": ans,
		"lines": ["L₁: " + L1(s), "L₂: " + L2(s)], "graph": plot(s), "pick_wrongs": NOT_MEET}
	out.wrongs = [wrong({"x": s.X, "y": Q.new(0), "alone": true}, R_X_ONLY)]
	out.generic = point_wrongs(s)
	var read := "The lines cross near (%s, %s) on the grid." % [Fmt.sf(s.X, 2), Fmt.sf(s.Y, 2)] if s.paper == 2 else "The lines cross at (%s, %s) on the grid." % [N(s.X), N(s.Y)]
	out.methods = {
		"equate-y": method([read] + sl_equate(s) + [fin(ans)], ans.values),
		"gdc-intersect": method([read, "Enter both lines and use intersect: x = %s, y = %s." % [V(s, s.X), V(s, s.Y)], fin(ans)], ans.values),
	}
	return out


func u_line_through_meeting_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("line", {"m": s.n, "c": s.c3})
	ans.exact = true
	var tail: String = "through T(%s, %s)" % [N(s.tx), N(s.ty)] if s.by_point else "has gradient %s" % N(s.n)
	var out := {"asked": "Line L goes through the point where L₁ and L₂ meet, and %s. Find L in the form y = mx + c." % tail,
		"answer": ans, "pick_wrongs": NOT_MEET}
	var sub: Array
	var elim: Array
	if rep == "equation":
		out.lines = ["L₁: " + gk(s.a1, s.b1, s.k1), "L₂: " + gk(1, s.b2, s.k2)]
		sub = gen_sub(s)
		elim = gen_elim(s)
	else:
		out.lines = ["L₁ has gradient %s and y-intercept %s." % [N(s.m1), N(s.c1)], "L₂ has gradient %s and y-intercept %s." % [N(s.m2), N(s.c2)]]
		sub = sl_sub(s)
		elim = sl_elim(s)
	var at := "They meet at (%s, %s)." % [N(s.X), N(s.Y)]
	var grad: String = "The gradient from there to T is (%s − %s)/(%s − %s) = %s." % [N(s.ty), PF(s.Y), N(s.tx), PF(s.X), N(s.n)] if s.by_point else "L has gradient %s." % N(s.n)
	var cs := "c = %s − %s × %s = %s." % [N(s.Y), PF(s.n), PF(s.X), N(s.c3)]
	out.wrongs = []
	out.generic = [{"m": s.n, "c": s.X.sub(s.n.mul(s.Y))}, {"m": s.n.neg(), "c": s.Y.add(s.n.mul(s.X))}, {"m": s.n, "c": s.c3.neg()}, {"m": s.n, "c": s.Y}]
	out.methods = {
		"substitution": method([sub[0], " ".join([sub[1], sub[2]]), grad + " " + cs, fin(ans)], ans.values),
		"elimination": method([elim[0], " ".join([elim[1], elim[2]]), at + " " + grad, cs, fin(ans)], ans.values),
	}
	return out


func u_constant_from_meeting_point(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("number", {"v": s.c1}, {}, "k = ")
	ans.exact = true
	var out := {"asked": "L₁ and L₂ meet where x = %s. Find k." % N(s.X), "answer": ans, "lines": ["L₁: y = %sx + k" % Fmt.lead(s.m1), "L₂: " + L2(s)],
		"pick_wrongs": NOT_MEET}
	var m1x: Q = s.m1.mul(s.X)
	out.generic = [{"v": s.Y.add(m1x)}, {"v": s.Y}, {"v": s.c2}, {"v": s.c1.neg()}, {"v": m1x}]
	var y := "On L₂ at x = %s, y = %s × %s%s = %s." % [N(s.X), PF(s.m2), PF(s.X), Fmt.plus(s.c2), N(s.Y)]
	out.methods = {
		"substitution": method([y, "Put (%s, %s) into L₁: %s = %s × %s + k." % [N(s.X), N(s.Y), N(s.Y), PF(s.m1), PF(s.X)], fin(ans)], ans.values),
		"equate-y": method(["At x = %s the lines are equal: %s × %s + k = %s × %s%s." % [N(s.X), PF(s.m1), PF(s.X), PF(s.m2), PF(s.X), Fmt.plus(s.c2)], "%s + k = %s." % [N(m1x), N(s.Y)], fin(ans)], ans.values),
	}
	return out
