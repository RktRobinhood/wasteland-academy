class_name TransformDescribeViews
extends ExtensionViews
## The views for fn-transform-describe on the `transform-chain` situation (FAL-424): given
## f and g, name the moves. TransformApplyViews adds the other two directions and
## TransformChainViews the order questions and the needs. A description is a choice of
## sentences written the one way the IB wants them ("a horizontal stretch with scale
## factor 1/2"), and a move's numbers are typed where the answer is numbers alone.

const TC := TransformChainSituation
const DESC := "SL2.11.describe#0"
const STRETCH := "SL2.11.stretch#0"
const REFLECT := "SL2.11.reflect#1"


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = TC.export(s)
	if out.answer.get("show", "") == "sf":
		out.trap = Answer.rounding_trap_all(out.answer)
	return out


## A question answered by a choice of statements. wrongs: [[text, ref], ...]; every
## method's steps get the same last line, "So <right>."
static func ask(right: String, wrongs: Array, generic: Array, asked: String, lines: Array, methods: Dictionary) -> Dictionary:
	var out := LogFunctionViews.choice(right, wrongs.map(func(w): return wrong({"v": w[0]}, w[1])), generic)
	var ms := {}
	for a in methods:
		ms[a] = method(methods[a] + ["So the answer is %s." % right], out.answer.values)
	out.merge({"asked": asked, "lines": lines, "methods": ms})
	return out


## A question answered in numbers. methods' last lines say the answer.
static func typed(ans: Dictionary, wrongs: Array, asked: String, lines: Array, methods: Dictionary, s: Dictionary) -> Dictionary:
	ans.exact = true
	if s.paper == 2:
		ans.show = "dec"
	var ms := {}
	for a in methods:
		ms[a] = method(methods[a] + ["So the answer is %s." % Answer.text(ans)], ans.values)
	return {"answer": ans, "wrongs": wrongs, "asked": asked, "lines": lines, "methods": ms}


static func f_line(s: Dictionary) -> String:
	return "f(x) = " + TC.f_rule(s)


static func g_line(s: Dictionary) -> String:
	return "g(x) = " + TC.g_rule(s)


static func P_(s: Dictionary, p: Array) -> String:
	return TC.pt(s, p[0], p[1])


## The curves of f and g on one set of axes, with two points of f and their images: P on
## f goes to P′ on g, Q to Q′. f is teal and g sand.
static func pair_graph(s: Dictionary) -> Dictionary:
	var two: Array = TC.two_apart(s.key)
	var fc := TC.curves(s, {"A": Q.new(1), "B": Q.new(1), "C": Q.new(0), "D": Q.new(0)}, s.win)
	var gc := TC.curves(s, s.map, s.win)
	var pts: Array = []
	for i in two.size():
		var im := TC.image(s.map, two[i][0], two[i][1])
		pts.append([two[i][0], two[i][1], "%s%s" % ["PQ"[i], P_(s, two[i])]])
		pts.append([im[0], im[1], "%s′%s" % ["PQ"[i], P_(s, im)]])
	pts = pts.map(func(p): return [p[0].to_float(), p[1].to_float(), p[2]])
	var g := Plot.spec(fc + gc, pts, s.win[0], s.win[1], s.win[2], s.win[3])
	g.one_colour = true
	g.sand_from = fc.size()
	return g


const PAIR_LINE := "The graphs of y = f(x) and y = g(x) are shown. P and Q on f move to P′ and Q′ on g."


## The lines of a view that shows f and g: the rules, or the graphs and the points.
static func show_pair(rep: String, s: Dictionary) -> Dictionary:
	if rep == "graph":
		return {"lines": [PAIR_LINE], "graph": pair_graph(s)}
	return {"lines": [f_line(s), g_line(s)]}


## The steps that read a key point across: "(1, 1) on f is at (3, 5) on g."
static func point_step(s: Dictionary) -> String:
	var k: Array = s.key[0]
	return "The point %s on f is at %s on g." % [P_(s, k), P_(s, TC.image(s.map, k[0], k[1]))]


static func rewrite_step(s: Dictionary) -> String:
	return "Written with f, g(x) = %s." % TC.rule(TC.export({"fam": "pts", "paper": s.paper}) , s.map) if false else "Written with f, g(x) = %s." % f_form(s, s.map)


## g written with the letter f: "2f(3(x − 1)) + 4".
static func f_form(s: Dictionary, map: Dictionary) -> String:
	return TC.rule({"fam": "pts", "paper": s.paper}, map)


func u_describe_translation(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Dictionary = s.moves[0]
	var c: Q = m.c
	var d: Q = m.d
	var out := ask(TC.tr_text(s, c, d), [[TC.tr_text(s, c.neg(), d), DESC]], [TC.tr_text(s, d, c), TC.tr_text(s, c.neg(), d.neg()), TC.tr_text(s, c, d.neg())],
		"Describe the transformation that maps the graph of f onto the graph of g.", [], {
			"rewrite-in-f": [rewrite_step(s), "x is replaced by %s, which moves the graph %s to the %s. The%s moves it %s %s." % [TC.x_minus(s, c), TC.n(s, c.abs_q()), "right" if c.sign() > 0 else "left", TC.plus(s, d), TC.n(s, d.abs_q()), "up" if d.sign() > 0 else "down"]],
			"substitute": ["Put x − c for x in f and add d: g(x) = f(x − c) + d.", "That matches %s when c = %s and d = %s." % [f_form(s, s.map), TC.n(s, c), TC.n(s, d)]],
			"shift-features": [point_step(s), "The change in x is %s and the change in y is %s." % [TC.n(s, c), TC.n(s, d)]],
			"gdc-overlay": ["Graph y = %s and y = %s on the GDC." % [TC.f_rule(s), TC.g_rule(s)], "Trace one point across: %s" % point_step(s)],
		})
	out.merge(show_pair(rep, s))
	return out


func u_describe_stretch(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Dictionary = s.moves[0]
	var a: Q = m.a
	var horizontal: bool = m.k == "hs"
	var right: String = TC.move_text(s, m)
	var flip := Q.new(1).div(a)
	var wrongs: Array = [[TC.hs_text(s, flip), STRETCH]] if horizontal else [[TC.hs_text(s, a), ""]]
	var generic: Array = [TC.vs_text(s, flip), TC.vs_text(s, a), TC.hs_text(s, flip), TC.hs_text(s, a), "a stretch with scale factor %s" % TC.n(s, a)]
	generic = generic.filter(func(t): return t != right)
	var word := "x" if horizontal else "y"
	var where := "inside the bracket, so x is multiplied by %s and every x-coordinate by %s" % [TC.n(s, s.map.B), TC.n(s, a)] if horizontal \
		else "outside the bracket, so every y-coordinate is multiplied by %s" % TC.n(s, a)
	var out := ask(right, wrongs, generic, "Describe the transformation that maps the graph of f onto the graph of g.", [], {
		"rewrite-in-f": [rewrite_step(s), "The factor is " + where + "."],
		"scale-rule": ["a·f(x) stretches y by a; f(bx) stretches x by 1/b.", "Here the factor is " + where + "."],
		"track-points": [point_step(s), "Only the %s-coordinates have changed, each multiplied by %s." % [word, TC.n(s, a)]],
		"invariant-points": ["A vertical stretch leaves points on the x-axis alone; a horizontal one leaves points on the y-axis alone.",
			"Here the %s stay put, and the %s-coordinates are multiplied by %s." % ["points on the y-axis" if horizontal else "points on the x-axis", word, TC.n(s, a)]],
	})
	out.merge(show_pair(rep, s))
	return out


func u_stretch_and_shift_parameters(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: Q = s.moves[0].a
	var d: Q = s.moves[1].d
	var names := ["horizontal scale factor", "vertical translation"]
	var ans := Answer.make("named", {"v0": k, "v1": d}, {"names": names})
	var said := "The number with x is %s, so the horizontal scale factor is 1/%s = %s." % [TC.n(s, s.map.B), Fmt.paren(TC.n(s, s.map.B)) if false else TC.n(s, s.map.B), TC.n(s, k)]
	var two: Array = TC.two_apart(s.key) if not TC.two_apart(s.key).is_empty() else [s.key[0], s.key[0]]
	var im: Array = TC.image(s.map, two[0][0], two[0][1])
	var out := typed(ans, [wrong({"v0": Q.new(1).div(k), "v1": d}, STRETCH), wrong({"v0": k, "v1": d.neg()}), wrong({"v0": Q.new(1).div(k), "v1": d.neg()})],
		"Find the horizontal scale factor and the vertical translation that map the graph of f onto the graph of g.", [], {
			"rewrite-in-f": [rewrite_step(s), said, "The number added outside is the vertical translation, %s." % TC.n(s, d)],
			"compare-key-points": ["The point %s on f goes to %s on g." % [P_(s, two[0]), P_(s, im)], "x is multiplied by %s and %s is added to y." % [TC.n(s, k), TC.n(s, d)]],
			"scale-rule": ["f(bx) + d is a horizontal stretch with scale factor 1/b, then a vertical translation by d.", said],
		}, s)
	out.merge(show_pair(rep, s))
	return out


## The two wave models of relate-two-models: y₁ = A₁ sin(wt) + D₁ and y₂ = A₂ sin(wt) + D₂.
static func wave_text(s: Dictionary, a: Q, d: Q, name: String) -> String:
	return "%s(t) = %s sin(%st)%s" % [name, TC.n(s, a), TC.n(s, s.w), TC.plus(s, d)]


func u_relate_two_models(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a1: Q = s.a1
	var a2: Q = s.a2
	var d1: Q = s.d1
	var d2: Q = s.d2
	var a := a2.div(a1)
	var d := d2.sub(a.mul(d1))
	var ans := Answer.make("named", {"v0": a, "v1": d}, {"names": ["scale factor", "vertical translation"]})
	ans.show = "sf" if s.paper == 2 else ""
	if s.paper == 1:
		ans.exact = true
	var lines: Array = [wave_text(s, a1, d1, "p"), wave_text(s, a2, d2, "q")] if rep == "equation" else \
		["Wave p has amplitude %s and centre line y = %s." % [TC.n(s, a1), TC.n(s, d1)], "Wave q has amplitude %s and centre line y = %s." % [TC.n(s, a2), TC.n(s, d2)], "Both have the same period and start at the centre line, rising."]
	var show := func(v: Q) -> String: return Fmt.sf(v) if s.paper == 2 else TC.n(s, v)
	var tail := "So the answer is %s." % Answer.text(ans)
	var steps := {
		"rewrite-in-f": ["q(t) = %s × (%s sin(%st)) + c, so multiply p by %s: that gives %s sin(%st) + %s." % [show.call(a), TC.n(s, a1), TC.n(s, s.w), show.call(a), TC.n(s, a2), TC.n(s, s.w), show.call(a.mul(d1))],
			"What is left to add is %s − %s = %s." % [TC.n(s, d2), show.call(a.mul(d1)), show.call(d)], tail],
		"scale-rule": ["The stretch comes from the amplitudes: %s ÷ %s = %s." % [TC.n(s, a2), TC.n(s, a1), show.call(a)],
			"The stretch also moves the centre line to y = %s × %s = %s." % [show.call(a), TC.n(s, d1), show.call(a.mul(d1))],
			"The translation takes it on to %s: %s." % [TC.n(s, d2), show.call(d)], tail],
		"shift-features": ["The amplitude goes from %s to %s, a factor of %s." % [TC.n(s, a1), TC.n(s, a2), show.call(a)],
			"The stretched centre line is y = %s, and it must reach y = %s, a move of %s." % [show.call(a.mul(d1)), TC.n(s, d2), show.call(d)], tail],
	}
	var ms := {}
	for m in steps:
		ms[m] = method(steps[m], ans.values)
	return {"asked": "The graph of p is mapped onto the graph of q by a vertical stretch with scale factor a, then a vertical translation by d, in that order. Find a and d.",
		"lines": lines, "answer": ans, "methods": ms,
		"wrongs": [wrong({"v0": a, "v1": d2.sub(d1)}), wrong({"v0": a1.div(a2), "v1": d2.sub(a1.div(a2).mul(d1))}), wrong({"v0": a, "v1": d.neg()})]}


func u_describe_log_rewrite(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.lb
	var e: int = s.le
	var name := Answer.log_name(b)
	var power: int = int(pow(b, e))
	var is_tr: bool = s.lform == "shift"
	var head := "%s(%dx)" % [name, power] if is_tr else "%s(x%s)" % [name, Fmt.sup(e)]
	var say := func(rhs: String, move: String) -> String: return "%s = %s, %s" % [head, rhs, move]
	var plain := name + " x"
	var shift_text := TC.tr_text(s, 0, e)
	var stretch_text := TC.vs_text(s, e)
	var right: String = say.call("%s + %d" % [plain, e], shift_text) if is_tr else say.call("%d %s" % [e, plain], stretch_text)
	var wrongs: Array = [[say.call("%d %s" % [e, plain], stretch_text), ""], [say.call("%s + %d" % [plain, power], TC.tr_text(s, 0, power)), ""], [say.call("%s %s" % [TC.n(s, power), plain], TC.vs_text(s, power)), ""]] if is_tr else \
		[[say.call("%s + %d" % [plain, e], shift_text), ""], [say.call("%s%s" % [plain, Fmt.sup(e)], TC.vs_text(s, power)), ""], [say.call("%d %s" % [power, plain], TC.vs_text(s, power)), ""]]
	var law := "%s(%d) + %s x = %d + %s x" % [name, power, name, e, name] if is_tr else "n log x = log xⁿ"
	return ask(right, wrongs, [], "The graph of y = %s is transformed to y = %s, for x > 0. Rewrite the new function with a log law and say which transformation it shows." % [plain, head],
		["y = " + plain, "y = " + head], {
			"rewrite-in-f": [("%s(%d · x) = %s(%d) + %s x." % [name, power, name, power, name]) if is_tr else ("Log of a power: %s(x%s) = %d %s." % [name, Fmt.sup(e), e, plain]),
				("%s(%d) = %d, since %d%s = %d." % [name, power, e, b, Fmt.sup(e), power]) if is_tr else "A number multiplying the whole function is a vertical stretch."],
			"invariant-points": ["(1, 0) is on y = %s. On the new graph, x = 1 gives y = %s." % [plain, "%d" % e if is_tr else "0"],
				("So the point has moved up by %d, and every other point with it: %s." % [e, law]) if is_tr else "It has stayed put on the x-axis, as a vertical stretch leaves it."],
		})


func u_describe_from_graphs(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var right := TC.chain_text(s, s.moves)
	var first: Dictionary = s.moves[0]
	var tr_m: Dictionary = s.moves[1]
	var bad: Array = []
	if first.k in ["vs", "hs"]:
		bad.append(TC.chain_text(s, [{"k": first.k, "a": Q.new(1).div(first.a)}, tr_m]))
		bad.append(TC.chain_text(s, [{"k": "hs" if first.k == "vs" else "vs", "a": first.a}, tr_m]))
	else:
		bad.append(TC.chain_text(s, [{"k": "ry" if first.k == "rx" else "rx"}, tr_m]))
	bad.append(TC.chain_text(s, [first, TC.tr(tr_m.c.neg(), tr_m.d)]))
	bad.append(TC.chain_text(s, [first, TC.tr(tr_m.c, tr_m.d.neg())]))
	var two: Array = TC.two_apart(s.key)
	var im0 := TC.image(s.map, two[0][0], two[0][1])
	var im1 := TC.image(s.map, two[1][0], two[1][1])
	var across := "From P to Q, x changes by %s and y by %s. From P′ to Q′, x changes by %s and y by %s." % [TC.n(s, two[1][0].sub(two[0][0])), TC.n(s, two[1][1].sub(two[0][1])), TC.n(s, im1[0].sub(im0[0])), TC.n(s, im1[1].sub(im0[1]))]
	var read := "The ratios give the stretch or reflection, and what is left over is the translation."
	var out := ask(right, [], bad, "Describe the two transformations, in order, that map the graph of f onto the graph of g.", [PAIR_LINE], {
		"compare-key-points": [across, read],
		"overlay-graphs": ["Compare the shapes: the gaps between points show any stretch or flip.", across, read],
		"track-points": ["P%s goes to P′%s, and Q%s goes to Q′%s." % [P_(s, two[0]), P_(s, im0), P_(s, two[1]), P_(s, im1)], across],
	})
	out.graph = pair_graph(s)
	return out


func u_describe_with_reflection(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var refl: Dictionary = s.moves[0]
	var other: Dictionary = s.moves[1]
	var right := TC.chain_text(s, s.moves)
	var swapped := TC.chain_text(s, [{"k": "ry" if refl.k == "rx" else "rx"}, other])
	var bad: Array = []
	match other.k:
		"tr":
			bad = [TC.chain_text(s, [refl, TC.tr(other.c.neg(), other.d)]), TC.chain_text(s, [refl, TC.tr(other.c, other.d.neg())])]
		_:
			bad = [TC.chain_text(s, [refl, {"k": other.k, "a": Q.new(1).div(other.a)}]), TC.chain_text(s, [refl, {"k": "hs" if other.k == "vs" else "vs", "a": other.a}])]
	var sign := "The minus sign is outside f, so the y-values change sign: a reflection in the x-axis." if refl.k == "rx" else "The minus sign is on x, inside f, so the x-values change sign: a reflection in the y-axis."
	var out := ask(right, [[swapped, REFLECT]], bad + [TC.chain_text(s, [other])], "Describe the two transformations, in order, that map the graph of f onto the graph of g.", [], {
		"rewrite-in-f": [rewrite_step(s), sign],
		"overlay-graphs": ["Graph f and g together and compare a point: %s" % point_step(s), sign],
	})
	out.merge(show_pair(rep, s))
	return out


func u_describe_after_completing_square(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h: Q = s.moves[0].c
	var k: Q = s.moves[0].d
	var p := h.mul(-2)
	var q := h.mul(h).add(k)
	var line := "y = " + Fmt.poly([Q.new(1), p, q])
	var form := "y = (%s)²%s" % [TC.x_minus(s, h), TC.plus(s, k)]
	var done := "Half of %s is %s, so %s, and %s." % [TC.n(s, p), TC.n(s, h.neg()), form, "the constant left over is %s" % TC.n(s, k)]
	var read := "The vertex of y = x² is (0, 0), and here it is %s." % TC.pt(s, h, k)
	return ask(TC.tr_text(s, h, k), [[TC.tr_text(s, h.neg(), k), DESC]], [TC.tr_text(s, p, q), TC.tr_text(s, h.neg(), k.neg()), TC.tr_text(s, h, k.neg())],
		"The graph of y = x² is translated onto the graph of %s. Find the translation vector." % line, ["y = x²", line], {
			"rewrite-in-f": [done, "So y = f(x − c) + d with c = %s and d = %s." % [TC.n(s, h), TC.n(s, k)]],
			"substitute": ["Write (x − c)² + d = x² − 2cx + c² + d and match it with %s." % line.trim_prefix("y = "), "−2c = %s gives c = %s, and d = %s." % [TC.n(s, p), TC.n(s, h), TC.n(s, k)]],
			"shift-features": [done, read],
			"complete-square": [done, read],
		})


func u_describe_factor_inside(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: Q = s.moves[0].a
	var c: Q = s.moves[1].c
	var b := Q.new(1).div(k)
	var e := b.mul(c)
	var inside := "%sx%s" % [TC.lead(s, b), TC.plus(s, e.neg())]
	var line := "g(x) = f(%s)" % inside
	var out := ask(TC.chain_text(s, s.moves), [[TC.chain_text(s, [{"k": "hs", "a": b}, TC.tr(c, 0)]), STRETCH]],
		[TC.chain_text(s, [{"k": "hs", "a": k}, TC.tr(e, 0)]), TC.chain_text(s, [{"k": "hs", "a": k}, TC.tr(c.neg(), 0)]), TC.chain_text(s, [{"k": "vs", "a": k}, TC.tr(c, 0)])],
		"Describe the transformations, in order, that map the graph of y = f(x) onto the graph of y = g(x).", [line], {
			"rewrite-in-f": ["Take %s out of the bracket: %s = %s(%s)." % [TC.n(s, b), inside, TC.lead(s, b), TC.x_minus(s, c)], "So x − %s is the translation, and %s multiplying x is the stretch." % [TC.n(s, c), TC.n(s, b)]],
			"scale-rule": ["Take %s out: g(x) = f(%s(%s))." % [TC.n(s, b), TC.lead(s, b), TC.x_minus(s, c)], "f(bx) is a stretch with factor 1/b = %s, and x − %s then moves the graph." % [TC.n(s, k), TC.n(s, c)]],
		})
	return out


func u_vector_from_key_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: Array = s.key[0]
	var m: Dictionary = s.moves[0]
	var im := TC.image(s.map, p[0], p[1])
	var ans := Answer.make("point", {"x": m.c, "y": m.d})
	var diff := "Change in x: %s − %s = %s. Change in y: %s − %s = %s." % [TC.n(s, im[0]), Fmt.paren(TC.n(s, p[0])) if false else TC.n(s, p[0]), TC.n(s, m.c), TC.n(s, im[1]), TC.n(s, p[1]), TC.n(s, m.d)]
	var out := typed(ans, [wrong({"x": m.c.neg(), "y": m.d.neg()}), wrong({"x": m.d, "y": m.c}), wrong({"x": im[0], "y": im[1]})],
		"The curve is translated. Find the translation vector.", [], {
			"compare-key-points": ["The key point goes from %s to %s." % [P_(s, p), P_(s, im)], diff],
			"shift-features": ["A translation moves every feature by the same vector, so follow this one point.", diff],
			"track-points": ["Subtract the start from the end, in that order.", diff],
		}, s)
	if rep == "graph":
		var two: Array = TC.two_apart(s.key)
		p = two[0]
		im = TC.image(s.map, p[0], p[1])
		out.lines = [PAIR_LINE]
		out.graph = pair_graph(s)
		for m2 in out.methods:
			out.methods[m2].steps[0] = "The point %s goes to %s." % [P_(s, p), P_(s, im)] if m2 != "track-points" else out.methods[m2].steps[0]
			out.methods[m2].steps[1] = "Change in x: %s − %s = %s. Change in y: %s − %s = %s." % [TC.n(s, im[0]), TC.n(s, p[0]), TC.n(s, m.c), TC.n(s, im[1]), TC.n(s, p[1]), TC.n(s, m.d)]
	else:
		out.lines = ["A curve has a key point at %s." % P_(s, p), "After the move, that point is at %s." % P_(s, im)]
	return out


func u_describe_the_reverse(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var fwd: Array = s.moves
	var back: Array = TC.undo(fwd)
	var same_order: Array = fwd.map(func(m): return TC.inverse(m))
	var lines: Array = [f_line(s), g_line(s), "The graph of f goes to the graph of g by %s." % TC.chain_text(s, fwd)]
	if rep == "words":
		lines = ["A graph goes to a new graph by %s." % TC.chain_text(s, fwd)]
	var k: Array = s.key[0]
	var im := TC.image(s.map, k[0], k[1])
	return ask(TC.chain_text(s, back), [], [TC.chain_text(s, same_order), TC.chain_text(s, [fwd[1], fwd[0]]), TC.chain_text(s, [back[0], fwd[0]]), TC.chain_text(s, fwd)],
		"Which moves, in order, map the new graph back onto the original one?", lines, {
			"compare-key-points": ["Undo each move and take them last one first: the last move went on last, so it comes off first.",
				"Check with a point: %s goes to %s, and the moves back return it to %s." % [P_(s, k), P_(s, im), P_(s, k)]],
		})
