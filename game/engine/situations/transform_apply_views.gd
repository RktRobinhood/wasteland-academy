class_name TransformApplyViews
extends TransformDescribeViews
## The views for fn-transform-apply on the `transform-chain` situation (FAL-424): given f
## and the moves, find g, a point or a domain, and given g and the moves, find f. A sketch
## is pick-the-graph, and a rule or a domain is a choice of statements written the one way
## the working writes them. A point is typed, and so is an asymptote.

const SK_ONE := "SL2.11.composite-transform#1"
const SK_V := "SL2.11.sketch-transformed#1"
const SK_LEFT := "SL2.11.sketch-transformed#2"
const SK_ASY := "SL2.11.sketch-transformed#0"
const COMP_IN := "SL2.11.composite-transform#0"
const COMP_ORDER := "SL2.11.composite-transform#2"
const TR_SIGN := "SL2.11.translate#0"
const TR_INSIDE := "SL2.11.translate#1"
const TR_ASY := "SL2.11.translate#2"
const IM_LEFT := "SL2.11.image-point#0"
const IM_ORDER := "SL2.11.image-point#1"
const IM_DOUBLE := "SL2.11.image-point#2"
const ROOTS := "SL2.11.stretch#1"
const NEG_ONE := "SL2.11.reflect#0"
const END_OPEN := "SL2.2.domain#0"
const END_COPY := "SL2.2.domain#1"
const SWAP_SET := "SL2.2.domain#2"


## f as the question gives it: its rule and domain, or by name.
static func f_given(rep: String, s: Dictionary) -> String:
	if rep == "words":
		return "f is %s." % (TC.NAMES[s.fam] if TC.NAMES.has(s.fam) else "the quadratic function " + TC.f_rule(s))
	var dom := TC.f_domain(s)
	return f_line(s) + (", for %s" % TC.set_text(s, dom, "x") if not dom.is_empty() else "")


static func moves_line(s: Dictionary) -> String:
	return "The graph of y = f(x) is transformed by %s, to give the graph of y = g(x)." % TC.chain_text(s, s.moves)


## A map with some of its numbers changed.
static func with(map: Dictionary, changes: Dictionary) -> Dictionary:
	var out := map.duplicate()
	out.merge(changes, true)
	return out


static func rule_line(s: Dictionary, map: Dictionary) -> String:
	return "g(x) = " + TC.rule(s, map)


# ── Sketches: pick the graph ─────────────────────────────────

## A pick-the-graph question: wrongs [[map, ref, mistake, why]], with every card in one
## window. The asked line says which function; the graph of f is what is given.
static func sketch(s: Dictionary, asked: String, wrongs: Array, steps: Dictionary, rng: Seeded) -> Dictionary:
	var maps: Array = [s.map]
	for w in wrongs:
		maps.append(w[0])
	var win := TC.window(s, maps)
	var p := GdcKit.pick(card(s, s.map, win), wrongs.map(func(w): return {"graph": card(s, w[0], win), "ref": w[1], "mistake": w[2], "why": w[3]}), rng)
	var plot := f_plot(s)
	var ms := {}
	for a in steps:
		ms[a] = method(steps[a] + ["So the graph is %s." % p.answer.values.v], p.answer.values)
	return {"asked": asked, "lines": ["The graph of y = f(x) is shown, with labelled points."], "graph": plot, "answer": p.answer, "graphs": p.graphs, "methods": ms}


## Where the labelled points go, as a step.
static func points_step(s: Dictionary) -> String:
	var parts: PackedStringArray = []
	for i in s.key.size():
		var k: Array = s.key[i]
		parts.append("%s goes to %s" % [P_(s, k), P_(s, TC.image(s.map, k[0], k[1]))])
	return cap_join(parts)


static func cap_join(parts: PackedStringArray) -> String:
	return " and ".join(parts) + "."


func u_sketch_stretch_shift(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: Q = s.moves[0].a
	var d: Q = s.moves[1].d
	var off: Array = [with(s.map, {"A": Q.new(1), "B": Q.new(1).div(a)}), "", "sideways", "it stretches parallel to the x-axis, but the factor is outside f"]
	if s.fam in TC.NO_HS:
		off = [with(s.map, {"A": Q.new(1).div(a)}), "", "inverted", "it is stretched by 1 ÷ %s, not by %s" % [TC.n(s, a), TC.n(s, a)]]
	var move_y := "Multiply each y-coordinate by %s, then move it %s." % [TC.n(s, a), vert_word(s, d)]
	return sketch(s, "Which graph is y = %s?" % f_form(s, s.map), [
		[with(s.map, {"D": a.mul(d)}), SK_ONE, "bracket", "it adds the translation before stretching, so every point is too far: that is %s(f(x)%s)" % [TC.lead(s, a), TC.plus(s, d)]],
		[with(s.map, {"D": d.neg()}), "", "wrong-way", "it moves the graph the wrong way after the stretch"],
		off,
	], {
		"move-key-points": [move_y, points_step(s)],
		"one-step-at-a-time": ["First the stretch: y becomes %s·y, and points on the x-axis stay." % TC.n(s, a), "Then the translation: every point moves %s." % vert_word(s, d)],
		"track-a-point": ["Follow one point: %s goes to %s." % [P_(s, s.key[0]), P_(s, TC.image(s.map, s.key[0][0], s.key[0][1]))], "Only one graph passes through it with the right shape."],
		"step-by-step": [move_y, points_step(s)],
	}, rng)


func u_sketch_reflection(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var rx: bool = s.moves[0].k == "rx"
	var name := "y = −f(x)" if rx else "y = f(−x)"
	var word := "x" if rx else "y"
	var other := TC.compose([{"k": "ry" if rx else "rx"}])
	var both := TC.compose([{"k": "rx"}, {"k": "ry"}])
	var line := "Each point keeps its %s-coordinate, and its %s-coordinate changes sign." % ["x" if rx else "y", "y" if rx else "x"]
	return sketch(s, "Which graph is %s?" % name, [
		[other, REFLECT, "other-axis", "it is reflected in the wrong axis: it is %s" % ("y = f(−x)" if rx else "y = −f(x)")],
		[both, "", "both", "it is reflected in both axes"],
		[TC.identity(), "", "unchanged", "it is the graph of f, unmoved"],
	], {
		"move-key-points": ["%s is a reflection in the %s-axis." % [name, word], points_step(s)],
		"one-step-at-a-time": ["There is one move, a reflection in the %s-axis." % word, points_step(s)],
		"track-points": [line, points_step(s)],
	}, rng)


func u_sketch_horizontal(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var m: Dictionary = s.moves[0]
	var wrongs: Array
	var steps: Dictionary
	var name := f_form(s, s.map)
	if m.k == "hs":
		var k: Q = m.a
		var b: Q = s.map.B
		wrongs = [
			[with(TC.identity(), {"A": b}), SK_V, "up-down", "it moves points up and down, but a number inside f acts on x"],
			[with(TC.identity(), {"B": k}), "", "inverted", "it is stretched by %s, the number inside, not by 1 ÷ that number" % TC.n(s, b)],
			[with(TC.identity(), {"A": k}), "", "vertical", "it is stretched parallel to the y-axis"],
		]
		var move := "A number multiplying x inside f is a horizontal stretch with scale factor 1 ÷ %s = %s." % [TC.n(s, b), TC.n(s, k)]
		steps = {"move-key-points": [move, points_step(s)], "one-step-at-a-time": [move, points_step(s)]}
	else:
		var c: Q = m.c
		wrongs = [
			[with(TC.identity(), {"C": c.neg()}), SK_LEFT, "other-way", "it moves the graph the way the sign in the bracket reads: x − c moves it right, x + c left"],
			[with(TC.identity(), {"D": c}), "", "up", "it moves the graph up or down, but the change is inside f"],
			[with(TC.identity(), {"D": c.neg()}), "", "down", "it moves the graph up or down, but the change is inside f"],
		]
		var move := "x is replaced by %s, so the graph moves %s." % [TC.x_minus(s, c), across_word(s, c)]
		steps = {"move-key-points": [move, points_step(s)], "one-step-at-a-time": [move, points_step(s)]}
	return sketch(s, "Which graph is y = %s?" % name, wrongs, steps, rng)


# ── Rules ────────────────────────────────────────────────────

func u_rule_single_translation(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Dictionary = s.moves[0]
	var c: Q = m.c
	var d: Q = m.d
	var right := rule_line(s, s.map)
	var inside := "g(x) = " + TC.f_of(s, TC.x_minus(s, c) + TC.plus(s, d))
	return ask(right, [[rule_line(s, with(s.map, {"C": c.neg()})), TR_SIGN], [inside, TR_INSIDE]],
		[rule_line(s, with(s.map, {"D": d.neg()})), rule_line(s, with(s.map, {"C": c.neg(), "D": d.neg()})), rule_line(s, with(s.map, {"C": d, "D": c}))],
		"Find g(x).", [f_given(rep, s), "The graph of y = f(x) is translated by the vector %s to give y = g(x)." % TC.pt(s, c, d)], {
			"shift-features": ["The vector moves the graph %s and %s." % [across_word(s, c), vert_word(s, d)], "Across goes inside f, with the opposite sign. Up or down goes outside."],
			"substitute": ["A translation by (c, d) gives g(x) = f(x − c) + d.", "Put in c = %s and d = %s: f(%s)%s." % [TC.n(s, c), TC.n(s, d), TC.x_minus(s, c), TC.plus(s, d)]],
		})


func u_rule_from_moves(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var moves: Array = s.moves
	var right := rule_line(s, s.map)
	var wrongs: Array = []
	var a: Q = s.map.A
	var b: Q = s.map.B
	if not b.abs_q().eq(1):
		var bare := "%sx%s" % [TC.lead(s, b), TC.plus(s, s.map.C.neg())]
		wrongs.append(["g(x) = " + TC.rule_inner(s, a, bare, s.map.D), COMP_IN])
	if not a.abs_q().eq(1):
		wrongs.append([rule_line(s, with(s.map, {"D": a.mul(s.map.D)})), SK_ONE])
	var bad: Array = [rule_line(s, with(s.map, {"C": s.map.C.neg()})), rule_line(s, with(s.map, {"D": s.map.D.neg()})),
		rule_line(s, with(s.map, {"C": s.map.D, "D": s.map.C})), rule_line(s, with(s.map, {"C": s.map.C.neg(), "D": s.map.D.neg()}))]
	var steps: Array = []
	var so_far: Array = []
	for m in moves:
		so_far.append(m)
		steps.append("After %s: %s." % [TC.move_text(s, m), f_form(s, TC.compose(so_far))])
	var k: Array = s.key[0]
	var im := TC.image(s.map, k[0], k[1])
	return ask(right, wrongs, bad, "Find g(x).", [f_given(rep, s), moves_line(s)], {
		"step-by-step-substitution": steps + ["With f written in, g(x) = %s." % TC.g_rule(s)],
		"track-a-point": ["Follow one point through the moves: %s goes to %s." % [P_(s, k), P_(s, im)], "Stretches and reflections scale the input and output, and the translation comes last: %s." % f_form(s, s.map)],
		"stretch-then-translate-form": ["The form a·f(b(x − c)) + d fits when stretches come first and the translation last.", "Here a = %s, b = %s, c = %s and d = %s." % [TC.n(s, a), TC.n(s, b), TC.n(s, s.map.C), TC.n(s, s.map.D)]],
		"gdc-overlay": ["Write %s from the moves: %s." % ["g", f_form(s, s.map)], "Graph it beside y = %s and check that %s goes to %s." % [TC.f_rule(s), P_(s, k), P_(s, im)]],
	})


func u_reflect_translate_rule(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var refl: Dictionary = s.moves[0]
	var t: Dictionary = s.moves[1]
	var dom := TC.g_domain(s)
	var say := func(map: Dictionary, set: Dictionary) -> String: return "%s, with domain %s" % [rule_line(s, map), TC.set_text(s, set, "x")]
	var right: String = say.call(s.map, dom)
	var sign_map := TC.compose([refl, TC.slide(t.c.neg(), t.d)])
	var other_map := TC.compose([{"k": "ry" if refl.k == "rx" else "rx"}, t])
	var open_set := dom.duplicate()
	for end in ["lo_in", "hi_in"]:
		if open_set.has(end):
			open_set[end] = false
	var wrongs: Array = [[say.call(sign_map, TC.moved_set(TC.f_domain(s), Q.new(1).div(sign_map.B), sign_map.C)), TR_SIGN],
		[say.call(s.map, TC.f_domain(s)), END_COPY]]
	if s.fam == "root":
		wrongs.append([say.call(s.map, open_set), END_OPEN])
	var neg := "Negate the output, f(x) to −f(x)" if refl.k == "rx" else "Negate the input, f(x) to f(−x)"
	var edge := "The domain's end %s moves with x: it is now %s." % [TC.set_text(s, TC.f_domain(s), "x"), TC.set_text(s, dom, "x")]
	var step := "Then translate: replace x by %s and add %s, giving %s." % [TC.x_minus(s, t.c), TC.n(s, t.d), f_form(s, s.map)]
	return ask(right, wrongs, [say.call(other_map, TC.moved_set(TC.f_domain(s), Q.new(1).div(other_map.B), other_map.C)), say.call(s.map, TC.moved_set(TC.f_domain(s), Q.new(1).div(s.map.B), s.map.C.neg())), say.call(sign_map, dom)],
		"Find g(x) and the domain of g.", [f_given(rep, s), moves_line(s)], {
			"gdc-check": [neg + ". " + step, "Graph y = %s on the GDC to check where the curve starts." % TC.g_rule(s), edge],
			"step-by-step-substitution": [neg + ".", step, edge],
			"gdc-overlay": [neg + ". " + step, "Overlay y = %s and y = %s, and read the domain from the curve." % [TC.f_rule(s), TC.g_rule(s)]],
			"negate-output-or-input": [neg + ".", step, edge],
			"graph-extent": [neg + ". " + step, "The graph's left and right extent shows the domain: %s." % TC.set_text(s, dom, "x")],
		})


func u_reflect_rule(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rx: bool = s.moves[0].k == "rx"
	var other := TC.compose([{"k": "ry" if rx else "rx"}])
	var moved := "The graph of y = f(x) is reflected in the %s-axis to give y = g(x)." % ("x" if rx else "y")
	var right: String
	var wrongs: Array
	var bad: Array
	var how := "Negate the whole output: g(x) = −f(x)." if rx else "Replace x by −x: g(x) = f(−x)."
	if s.fam == "poly":
		var u: Q = s.u
		var v: Q = s.v
		right = "g(x) = " + Fmt.poly([-1, u.neg(), v.neg()]) if rx else "g(x) = " + Fmt.poly([1, u.neg(), v])
		var other_text := "g(x) = " + (Fmt.poly([1, u.neg(), v]) if rx else Fmt.poly([-1, u.neg(), v.neg()]))
		wrongs = [[other_text, REFLECT]]
		if rx:
			wrongs.append(["g(x) = " + Fmt.poly([-1, u, v]), NEG_ONE])
		bad = ["g(x) = " + Fmt.poly([-1, u.neg(), v]), "g(x) = " + Fmt.poly([-1, u, v.neg()]), "g(x) = " + Fmt.poly([1, u, v.neg()]), "g(x) = " + Fmt.poly([1, u.neg(), v.neg()])]
	else:
		right = rule_line(s, s.map)
		wrongs = [[rule_line(s, other), REFLECT]]
		bad = [rule_line(s, TC.compose([{"k": "rx"}, {"k": "ry"}])), "g(x) = " + TC.f_rule(s), rule_line(s, with(TC.identity(), {"D": Q.new(-1)})), rule_line(s, with(TC.identity(), {"C": Q.new(1)}))]
	var f_txt := TC.f_rule(s)
	return ask(right, wrongs, bad, "Find g(x), simplified.", [f_given(rep, s), moved], {
		"negate-output-or-input": [how, "Do that to every term of %s." % f_txt],
		"gdc-overlay": [how, "Graph y = %s and your g on the GDC: one should be the mirror image of the other in the %s-axis." % [f_txt, "x" if rx else "y"]],
	})


## A parabola f(x) = (x − u)² + v under a map, simplified: "2(x − 3)² + 1".
static func vert_rule(s: Dictionary, map: Dictionary) -> String:
	var a: Q = map.A.mul(map.B).mul(map.B)
	var h: Q = map.C.add(s.u.div(map.B))
	var k: Q = map.A.mul(s.v).add(map.D)
	var bracket := "x" if h.is_zero() else "(%s)" % TC.x_minus(s, h)
	return "%s%s²%s" % [TC.lead(s, a), bracket, TC.plus(s, k)]


func u_undo_moves(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var moves: Array = s.moves
	var back: Array = TC.undo(moves)
	var same_order: Array = moves.map(func(m): return TC.inverse(m))
	var right := "f(x) = " + vert_rule(s, TC.identity())
	var wrong_map := func(extra: Array) -> String: return "f(x) = " + vert_rule(s, TC.compose(moves + extra))
	var g_text := vert_rule(s, s.map)
	var lines: Array = ["g(x) = " + g_text, "The graph of y = g(x) came from the graph of y = f(x) by %s." % TC.chain_text(s, moves)]
	if rep == "words":
		lines = ["A parabola y = f(x) goes through %s." % TC.chain_text(s, moves), "It ends up as y = %s." % g_text]
	var signs: Array = back.map(func(m): return TC.slide(m.c.neg(), m.d) if m.k == "tr" else m)
	var steps: Array = ["Undo each move, last one first: %s." % TC.chain_text(s, back)]
	var done: Array = moves.duplicate()
	for m in back:
		done.append(m)
		steps.append("After %s: y = %s." % [TC.move_text(s, m), vert_rule(s, TC.compose(done))])
	return ask(right, [], [wrong_map.call(same_order), wrong_map.call(moves), wrong_map.call(signs), wrong_map.call([TC.slide(0, s.map.D.neg())])],
		"Find f(x).", lines, {
			"step-by-step-substitution": steps,
			"substitute": steps,
		})


func u_order_changes_rule(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var stretch_m: Dictionary = s.moves[0]
	var t: Dictionary = s.moves[1]
	var first := TC.compose([stretch_m, t])
	var second := TC.compose([t, stretch_m])
	var same: bool = first.A.eq(second.A) and first.B.eq(second.B) and first.C.eq(second.C) and first.D.eq(second.D)
	var say := func(m1: Dictionary, m2: Dictionary) -> String: return "stretch first, g(x) = %s; translation first, g(x) = %s" % [TC.rule(s, m1), TC.rule(s, m2)]
	var one_way := func(m: Dictionary) -> String: return "the same graph either way, g(x) = %s" % TC.rule(s, m)
	var right: String = one_way.call(first) if same else say.call(first, second)
	var other_m := with(first, {"D": first.D.neg()})
	var wrongs: Array = [[one_way.call(first), COMP_ORDER], [one_way.call(second), COMP_ORDER]] if not same else []
	var off_c := with(first, {"C": first.C.neg()})
	var bad: Array = [say.call(first, other_m), say.call(other_m, first), one_way.call(other_m), say.call(off_c, first), one_way.call(off_c)] if same else \
		[say.call(second, first), say.call(first, other_m), say.call(other_m, second), say.call(off_c, second), say.call(first, with(second, {"C": second.C.neg()}))]
	var axis_same: bool = (stretch_m.k == "vs" and not t.d.is_zero()) or (stretch_m.k == "hs" and not t.c.is_zero())
	var why := "The stretch and the translation act along the same axis, so the stretch changes the size of the translation when it comes second." if axis_same else "The stretch and the translation act along different axes, so neither changes the other."
	var k: Array = s.key[0]
	var im1 := TC.image(first, k[0], k[1])
	var im2 := TC.image(second, k[0], k[1])
	var track := "Follow %s: stretch first it lands at %s, translation first at %s." % [P_(s, k), P_(s, im1), P_(s, im2)]
	var written := "Stretch first: %s. Translation first: %s." % [f_form(s, first), f_form(s, second)]
	var lines: Array = [f_given(rep, s), "Two moves: %s, and %s." % [TC.move_text(s, stretch_m), TC.move_text(s, t)], "They can be done in either order."]
	return ask(right, wrongs, bad, "Find g(x) for each order, and say whether the orders differ.", lines, {
		"one-step-at-a-time": [written, why],
		"step-by-step-substitution": [written, why],
		"track-a-point": [track, written],
		"stretch-then-translate-form": ["Stretch first fits a·f(b(x − c)) + d straight away: %s." % f_form(s, first), "Translation first must be rebuilt: %s." % f_form(s, second), why],
	})


# ── Points ───────────────────────────────────────────────────

## The point of a key list the question uses: not on an axis where that loses a mistake.
static func chosen_point(s: Dictionary, rng: Seeded) -> Array:
	var clear: Array = s.key.filter(func(k): return not k[0].is_zero())
	return rng.pick(clear) if not clear.is_empty() else s.key[0]


## The lines that show a point on f, in the view's representation. With a graph or a
## table, the student reads it off.
static func show_point(rep: String, s: Dictionary, p: Array, on_g: bool) -> Dictionary:
	var name := "g" if on_g else "f"
	var given := "g(x) = " + f_form(s, s.map)
	if on_g:
		return {"lines": ["The point %s lies on y = g(x)." % P_(s, p), given]}
	match rep:
		"graph":
			return {"lines": ["The graph of y = f(x) is shown, with the point P%s." % P_(s, p), given], "graph": f_plot_at(s, p)}
		"table":
			var rows: Array = [["x", s.key.map(func(k): return TC.n(s, k[0]))], ["f(x)", s.key.map(func(k): return TC.n(s, k[1]))]]
			return {"lines": ["The table gives points on y = f(x). P is the point with x = %s." % TC.n(s, p[0]), given], "table": {"rows": rows}}
	return {"lines": ["The point P%s lies on y = %s(x)." % [P_(s, p), name], given]}


static func f_plot_at(s: Dictionary, p: Array) -> Dictionary:
	var g := f_plot(s)
	g.points = [{"x": p[0].to_float(), "y": p[1].to_float(), "label": "P" + P_(s, p)}]
	return g


func u_image_point(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var p: Array = chosen_point(s, rng)
	var map: Dictionary = s.map
	var im := TC.image(map, p[0], p[1])
	var wrongs: Array = [wrong({"x": p[0].div(map.B).sub(map.C), "y": im[1]}, IM_LEFT)]
	var has_v: bool = not map.A.abs_q().eq(1)
	var has_h: bool = not map.B.abs_q().eq(1)
	if has_v:
		wrongs.append(wrong({"x": im[0], "y": map.A.mul(p[1].add(map.D))}, IM_ORDER))
	if has_h:
		wrongs.append(wrong({"x": p[0].mul(map.B).add(map.C), "y": im[1]}, IM_DOUBLE))
	if has_v and p[1].is_zero() and not p[0].is_zero():
		wrongs.append(wrong({"x": p[0].mul(map.A).add(map.C), "y": im[1]}, ROOTS))
	wrongs.append(wrong({"x": im[1], "y": im[0]}))
	var ans := Answer.make("point", {"x": im[0], "y": im[1]})
	var x_line := "x: %s ÷ %s%s = %s." % [TC.n(s, p[0]), par(s, map.B), TC.plus(s, map.C), TC.n(s, im[0])]
	var y_line := "y: %s × %s%s = %s." % [TC.n(s, map.A), par(s, p[1]), TC.plus(s, map.D), TC.n(s, im[1])]
	var out := typed(ans, wrongs, "Find the image of P on y = g(x).", [], {
		"stretch-then-translate-form": ["g has the form a·f(b(x − c)) + d, with a = %s, b = %s, c = %s, d = %s." % [TC.n(s, map.A), TC.n(s, map.B), TC.n(s, map.C), TC.n(s, map.D)], x_line, y_line],
		"mapping-rule": ["The mapping is (x, y) to (x/b + c, a·y + d).", x_line, y_line],
		"step-by-step": ["Take each move in turn: first what acts on x, inside f.", x_line, y_line],
		"solve-for-input": ["Solve b(x − c) = %s for the input that f reads as %s." % [TC.n(s, p[0]), TC.n(s, p[0])], x_line, y_line],
	}, s)
	out.merge(show_point(rep, s, p, false), true)
	return out


func u_original_point(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var k: Array = chosen_point(s, rng)
	var map: Dictionary = s.map
	var im := TC.image(map, k[0], k[1])
	var src := TC.source(map, im[0], im[1])
	var wrongs: Array = [wrong({"x": im[0].add(map.C).mul(map.B), "y": src[1]}, IM_LEFT)]
	if not map.B.abs_q().eq(1):
		wrongs.append(wrong({"x": im[0].sub(map.C).div(map.B), "y": src[1]}, IM_DOUBLE))
	wrongs.append(wrong({"x": im[0], "y": src[1]}))
	wrongs.append(wrong({"x": src[0], "y": im[1].div(map.A)}))
	wrongs.append(wrong({"x": src[1], "y": src[0]}))
	var x_line := "x: b(x′ − c) = %s × (%s − %s) = %s." % [TC.n(s, map.B), TC.n(s, im[0]), par(s, map.C), TC.n(s, src[0])]
	var y_line := "y: (y′ − d) ÷ a = (%s − %s) ÷ %s = %s." % [TC.n(s, im[1]), par(s, map.D), par(s, map.A), TC.n(s, src[1])]
	var out := typed(Answer.make("point", {"x": src[0], "y": src[1]}), wrongs, "Find the point on y = f(x) it came from.", [], {
		"mapping-rule": ["The mapping runs backwards: x = b(x′ − c) and y = (y′ − d) ÷ a.", x_line, y_line],
		"step-by-step": ["Undo the moves, last one first.", x_line, y_line],
		"solve-for-input": ["g at %s reads f at b(x′ − c), so that is the x-coordinate." % TC.n(s, im[0]), x_line, y_line],
	}, s)
	var shown := show_point("equation", s, im, true)
	if rep == "table":
		shown.lines[0] = "The table gives points on y = g(x). Q is the point with x = %s." % TC.n(s, im[0])
		var imgs: Array = s.key.map(func(p): return TC.image(map, p[0], p[1]))
		shown.table = {"rows": [["x", imgs.map(func(i): return TC.n(s, i[0]))], ["g(x)", imgs.map(func(i): return TC.n(s, i[1]))]]}
	elif rep == "graph":
		var gg := Plot.spec(TC.curves(s, map, s.win), [[im[0].to_float(), im[1].to_float(), "Q" + P_(s, im)]], s.win[0], s.win[1], s.win[2], s.win[3])
		gg.one_colour = true
		shown.graph = gg
		shown.lines[0] = "The graph of y = g(x) is shown, with the point Q%s." % P_(s, im)
	out.merge(shown, true)
	return out


# ── Asymptotes, domains and ranges ───────────────────────────

func u_moved_asymptote(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var asy := TC.f_asymptotes(s)
	var map: Dictionary = s.map
	var x: Variant = TC.image(map, asy.x, 0)[0] if asy.has("x") else null
	var y: Variant = TC.image(map, 0, asy.y)[1] if asy.has("y") else null
	var lines: Array = [f_given("equation", s), moves_line(s)]
	var graph: Variant = null
	if rep == "graph":
		lines = ["The graph of y = f(x) is shown, with its asymptote%s dashed." % ("s" if x != null and y != null else ""), moves_line(s)]
		graph = f_plot(s)
	var steps := {}
	var ans: Dictionary
	var wrongs: Array
	var line_x: String = "x = 0 goes to x = %s." % TC.n(s, x) if x != null else ""
	var line_y: String = "y = 0 goes to y = %s." % TC.n(s, y) if y != null else ""
	var read := "An asymptote moves with the curve: x = p goes to x = p/b + c, and y = q to y = a·q + d."
	if x != null and y != null:
		ans = Answer.make("named", {"v0": x, "v1": y}, {"names": ["x", "y"]})
		wrongs = [wrong({"v0": Q.new(0), "v1": y}, SK_ASY), wrong({"v0": x, "v1": Q.new(0)}, TR_ASY), wrong({"v0": y, "v1": x}), wrong({"v0": x.neg(), "v1": y})]
		steps = {"move-key-points": [read, line_x + " " + line_y], "shift-features": [read, line_x + " " + line_y]}
	elif x != null:
		ans = Answer.make("axis", {"var": "x", "h": x})
		wrongs = [wrong({"var": "x", "h": Q.new(0)}, SK_ASY), wrong({"var": "x", "h": x.neg()}), wrong({"var": "y", "h": x})]
		steps = {"move-key-points": [read, line_x], "shift-features": [read, line_x]}
	else:
		ans = Answer.make("axis", {"var": "y", "h": y})
		wrongs = [wrong({"var": "y", "h": Q.new(0)}, TR_ASY), wrong({"var": "y", "h": y.neg()}), wrong({"var": "x", "h": y})]
		steps = {"move-key-points": [read, line_y], "shift-features": [read, line_y]}
	var out := typed(ans, wrongs, "Find the equation of each asymptote of g." if x != null and y != null else "Find the equation of the asymptote of g.", lines, steps, s)
	out.graph = graph
	return out


func u_domain_range_of_g(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var dom := TC.g_domain(s)
	var ran := TC.g_range(s)
	var say := func(d: Dictionary, r: Dictionary) -> String: return "domain %s; range %s" % [TC.set_text(s, d, "x"), TC.set_text(s, r, "y")]
	var right: String = say.call(dom, ran)
	var map: Dictionary = s.map
	var fd := TC.f_domain(s)
	var fr := TC.f_range(s)
	var swapped_sets := "domain %s; range %s" % [TC.set_text(s, ran, "x"), TC.set_text(s, dom, "y")]
	var bad: Array = [say.call(fd, ran), say.call(dom, fr), say.call(fd, fr),
		say.call(TC.moved_set(fd, Q.new(1).div(map.B), map.C.neg()), ran), say.call(dom, TC.moved_set(fr, map.A, map.D.neg())),
		say.call(TC.moved_set(fd, map.B, map.C), ran), say.call(dom, TC.moved_set(fr, Q.new(1).div(map.A), map.D)),
		say.call(TC.moved_set(fd, Q.new(1).div(map.B), map.C.add(1)), TC.moved_set(fr, map.A, map.D.add(1)))]
	var d_step := "The domain moves with what acts on x: %s becomes %s." % [TC.set_text(s, fd, "x"), TC.set_text(s, dom, "x")]
	var r_step := "The range moves with what acts on y: %s becomes %s." % [TC.set_text(s, fr, "y"), TC.set_text(s, ran, "y")]
	var out := ask(right, [[swapped_sets, SWAP_SET]] if swapped_sets != right else [], bad, "Find the domain and the range of g.", [f_given("equation", s), moves_line(s)], {
		"stretch-then-translate-form": ["g(x) = %s, so x goes to x/b + c and y to a·y + d, with a = %s, b = %s, c = %s, d = %s." % [f_form(s, map), TC.n(s, map.A), TC.n(s, map.B), TC.n(s, map.C), TC.n(s, map.D)], d_step, r_step],
		"graph-extent": ["Move the graph's left and right ends, and its lowest and highest points.", d_step, r_step],
	})
	if rep == "graph":
		out.lines = ["The graph of y = f(x) is shown. Its domain is %s and its range is %s." % [TC.set_text(s, fd, "x"), TC.set_text(s, fr, "y")], moves_line(s)]
		out.graph = f_plot(s)
	return out
