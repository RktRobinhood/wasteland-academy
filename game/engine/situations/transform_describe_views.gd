class_name TransformDescribeViews
extends ExtensionViews
## The views for fn-transform-describe on the `transform-chain` situation (FAL-424): given
## f and g, name the moves. TransformApplyViews adds the other two directions and
## TransformChainViews the order questions and the needs. A description is a choice of
## sentences written the one way the IB wants them ("a horizontal stretch with scale
## factor 1/2"), and a move's numbers are typed where the answer is numbers alone.

const TC := preload("res://engine/situations/transform_chain.gd")
const DESC := "SL2.11.describe#0"
const STRETCH := "SL2.11.stretch#0"
const REFLECT := "SL2.11.reflect#1"
const NO_AXIS := "SL2.11.describe#2"
const TD := "fn-transform-describe#"
const D_RECIP := TD + "6"
const D_AXIS := TD + "7"
const D_CENTRE := TD + "8"
const D_AMPS := TD + "9"
const D_LAWS := TD + "10"
const D_NO_LOG := TD + "11"
const D_RATIO := TD + "12"
const D_COEFFS := TD + "13"
const D_NOT_FACTORED := TD + "14"
const D_BACKWARDS := TD + "15"
const D_POINT := TD + "16"
const D_SAME_ORDER := TD + "17"
const D_NOT_UNDONE := TD + "18"


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = TC.export(s)
	if out.answer.get("show", "") == "sf":
		out.trap = Answer.rounding_trap_all(out.answer)
	return out


## A question answered by a choice of statements. wrongs: [[text, ref], ...], each a slip
## with its ref; fillers: the texts with no route to them. Every method's steps get the
## same last line, "So <right>."
static func ask(right: String, wrongs: Array, fillers: Array, asked: String, lines: Array, methods: Dictionary) -> Dictionary:
	var out := LogFunctionViews.choice(right, wrongs.map(func(w): return wrong({"v": w[0]}, w[1])), fillers)
	# LogFunctionViews' untagged options, whichever name it gives them, are fillers here.
	out.fillers = out.get("fillers", []) + out.get("generic", [])
	out.erase("generic")
	var ms := {}
	for a in methods:
		ms[a] = method(methods[a] + ["So the answer is %s." % right], out.answer.values)
	out.merge({"asked": asked, "lines": lines, "methods": ms})
	return out


## A question answered in numbers. methods' last lines say the answer. wrongs are slips with
## their refs, fillers the values with no route to them.
static func typed(ans: Dictionary, wrongs: Array, asked: String, lines: Array, methods: Dictionary, s: Dictionary, fillers: Array = []) -> Dictionary:
	ans.exact = true
	if s.paper == 2:
		ans.show = "dec"
	var ms := {}
	for a in methods:
		ms[a] = method(methods[a] + ["So the answer is %s." % Answer.text(ans)], ans.values)
	return {"answer": ans, "wrongs": wrongs, "fillers": fillers, "asked": asked, "lines": lines, "methods": ms}


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
	var fc := TC.curves(s, TC.identity(), s.win)
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


## A pick-the-graph card of f moved by a map: the curve, its asymptotes dashed and its key
## points' images marked, unlabelled.
static func card(s: Dictionary, map: Dictionary, win: Array) -> Dictionary:
	var pts: Array = s.key.map(func(k):
		var im := TC.image(map, k[0], k[1])
		return [im[0].to_float(), im[1].to_float(), ""])
	var asy := TC.f_asymptotes(s)
	var vl: Array = [[TC.image(map, asy.x, 0)[0].to_float(), ""]] if asy.has("x") else []
	var hl: Array = [[TC.image(map, 0, asy.y)[1].to_float(), ""]] if asy.has("y") else []
	var g := GdcKit.card(TC.curves(s, map, win), pts, win, vl, hl)
	g.one_colour = true
	return g


## The graph of f alone, with its key points labelled and its asymptotes dashed.
static func f_plot(s: Dictionary) -> Dictionary:
	var pts: Array = []
	for i in s.key.size():
		var k: Array = s.key[i]
		pts.append([k[0].to_float(), k[1].to_float(), "%s%s" % ["PQRST"[i], P_(s, k)]])
	var asy := TC.f_asymptotes(s)
	var vl: Array = [[asy.x.to_float(), ""]] if asy.has("x") else []
	var hl: Array = [[asy.y.to_float(), ""]] if asy.has("y") else []
	var g := Plot.spec(TC.curves(s, TC.identity(), s.win), pts, s.win[0], s.win[1], s.win[2], s.win[3], hl, vl)
	g.one_colour = true
	return g


## A key point that shows the move: off the axes if one is, or at least moved.
static func telling(s: Dictionary) -> Array:
	for k in s.key:
		if not k[0].is_zero() and not k[1].is_zero():
			return k
	for k in s.key:
		var im := TC.image(s.map, k[0], k[1])
		if not (im[0].eq(k[0]) and im[1].eq(k[1])):
			return k
	return s.key[0]


## A number to take away, in brackets when negative: "(−4)".
static func par(s: Dictionary, v: Q) -> String:
	return "(%s)" % TC.n(s, v) if v.sign() < 0 else TC.n(s, v)


## The steps that read a key point across: "(1, 1) on f is at (3, 5) on g."
static func point_step(s: Dictionary) -> String:
	var k: Array = telling(s)
	return "The point %s on f is at %s on g." % [P_(s, k), P_(s, TC.image(s.map, k[0], k[1]))]


## g written with f. A graph gives no rule, so there it is read from P and Q first.
static func rewrite_step(s: Dictionary, rep: String = "equation") -> String:
	if rep != "graph":
		return "Written with f, g(x) = %s." % f_form(s, s.map)
	var two: Array = s.key.slice(0, 2)
	var said: Array = []
	for i in two.size():
		said.append("%s%s %s %s′%s" % ["PQ"[i], P_(s, two[i]), "goes to" if i == 0 else "to", "PQ"[i], P_(s, TC.image(s.map, two[i][0], two[i][1]))])
	return "From the graph, %s, so g(x) = %s." % [" and ".join(PackedStringArray(said)), f_form(s, s.map)]


## A number to divide by, in brackets when it is a fraction or negative: "1 ÷ (1/3)".
static func over(s: Dictionary, v: Q) -> String:
	var t := TC.n(s, v)
	return "(%s)" % t if t.contains("/") or v.sign() < 0 else t


## A point taken through moves one at a time: "(0, 1) → (0, 2) → (0, 5)".
static func trail(s: Dictionary, moves: Array, p: Array) -> String:
	var at: Array = p
	var parts: Array = [P_(s, p)]
	for m in moves:
		at = TC.image(TC.compose([m]), at[0], at[1])
		parts.append(P_(s, at))
	return " → ".join(PackedStringArray(parts))


static func low(t: String) -> String:
	return t.left(1).to_lower() + t.substr(1)


## g written with the letter f: "2f(3(x − 1)) + 4".
static func f_form(s: Dictionary, map: Dictionary) -> String:
	return TC.rule({"fam": "pts", "paper": s.paper}, map)


## "up 4", "down 2.5".
static func vert_word(s: Dictionary, d: Q) -> String:
	return "%s %s" % ["up" if d.sign() > 0 else "down", TC.n(s, d.abs_q())]


## "3 to the right", "2 to the left".
static func across_word(s: Dictionary, c: Q) -> String:
	return "%s to the %s" % [TC.n(s, c.abs_q()), "right" if c.sign() > 0 else "left"]


func u_describe_translation(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Dictionary = s.moves[0]
	var c: Q = m.c
	var d: Q = m.d
	# A graph gives no rule for g, so a method that works on the rule reads it off P and Q.
	var seen: Array = [rewrite_step(s, rep)] if rep == "graph" else []
	var k: Array = telling(s)
	var im := TC.image(s.map, k[0], k[1])
	var diff := "The change in x is %s − %s = %s and the change in y is %s − %s = %s." % [TC.n(s, im[0]), par(s, k[0]), TC.n(s, c), TC.n(s, im[1]), par(s, k[1]), TC.n(s, d)]
	var out := ask(TC.tr_text(s, c, d), [[TC.tr_text(s, c.neg(), d), DESC]], [TC.tr_text(s, c.neg(), d.neg()), TC.tr_text(s, c, d.neg()), TC.tr_text(s, d, c)],
		"Describe the transformation that maps the graph of f onto the graph of g.", [], {
			"rewrite-in-f": [rewrite_step(s, rep), "x is replaced by %s, which moves the graph %s, and the%s outside moves it %s." % [TC.x_minus(s, c), across_word(s, c), TC.plus(s, d), vert_word(s, d)]],
			"substitute": seen + ["Putting x − a for x and adding b gives g(x) = f(x − a) + b.", "That is %s when a = %s and b = %s." % [f_form(s, s.map), TC.n(s, c), TC.n(s, d)]],
			"shift-features": [point_step(s), diff],
			"gdc-overlay": seen + ["Graph y = %s and y = %s on the GDC." % [TC.f_rule(s), TC.g_rule(s)], "Trace one point across: %s" % low(point_step(s)), diff],
		})
	out.merge(show_pair(rep, s), true)
	if rep == "graph":
		# The GDC needs f's rule to draw anything.
		out.lines = [PAIR_LINE, f_line(s)]
	return out


func u_describe_stretch(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Dictionary = s.moves[0]
	var a: Q = m.a
	var horizontal: bool = m.k == "hs"
	var right: String = TC.move_text(s, m)
	var flip := Q.new(1).div(a)
	var no_axis := "a stretch with scale factor %s" % TC.n(s, a)
	# Horizontal: b used as the factor, or the right factor on the other axis. Vertical: the
	# factor inverted, as if it were inside, or the other axis. Either: no axis named.
	var wrongs: Array = [[TC.hs_text(s, flip), STRETCH], [TC.vs_text(s, a), D_AXIS]] if horizontal else [[TC.vs_text(s, flip), D_RECIP], [TC.hs_text(s, a), D_AXIS]]
	wrongs.append([no_axis, NO_AXIS])
	var fillers: Array = [TC.vs_text(s, flip)] if horizontal else [TC.hs_text(s, flip)]
	# On 1/x a horizontal stretch is a vertical one, and on a log a translation. The other
	# axis is still a slip on a log (log₂(x/a) is no stretch); the filler is a squared, not
	# 2a (a stretch by 1 when a is ½).
	if s.fam in TC.NO_HS:
		wrongs = [[TC.vs_text(s, flip), D_RECIP], [no_axis, NO_AXIS]]
		if s.fam != "recip":
			wrongs.append([TC.hs_text(s, a), D_AXIS])
		fillers = [TC.vs_text(s, a.mul(a))]
	wrongs = wrongs.filter(func(w): return w[0] != right)
	fillers = fillers.filter(func(t): return t != right)
	var word := "x" if horizontal else "y"
	var where := "inside the bracket, so x is multiplied by %s and every x-coordinate by %s" % [TC.n(s, s.map.B), TC.n(s, a)] if horizontal \
		else "outside the bracket, so every y-coordinate is multiplied by %s" % TC.n(s, a)
	var seen: Array = [rewrite_step(s, rep)] if rep == "graph" else []
	var out := ask(right, wrongs, fillers, "Describe the transformation that maps the graph of f onto the graph of g.", [], {
		"rewrite-in-f": [rewrite_step(s, rep), "The factor is " + where + "."],
		"scale-rule": seen + ["a·f(x) stretches y by a, and f(bx) stretches x by 1/b.", "Here the factor is " + where + "."],
		"track-points": [point_step(s), "Only the %s-coordinates have changed, each multiplied by %s." % [word, TC.n(s, a)]],
		"invariant-points": ["A vertical stretch leaves points on the x-axis alone, and a horizontal one leaves points on the y-axis alone.",
			"Here the %s stay put. %s" % ["points on the y-axis" if horizontal else "points on the x-axis", point_step(s)],
			"So the %s-coordinates are multiplied by %s." % [word, TC.n(s, a)]],
	})
	out.merge(show_pair(rep, s), true)
	return out


func u_stretch_and_shift_parameters(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: Q = s.moves[0].a
	var d: Q = s.moves[1].d
	var ans := Answer.make("named", {"v0": k, "v1": d}, {"names": ["horizontal scale factor", "vertical translation"]})
	var said := "The number with x is %s, so the horizontal scale factor is 1 ÷ %s = %s." % [TC.n(s, s.map.B), over(s, s.map.B), TC.n(s, k)]
	var p: Array = telling(s)
	var im := TC.image(s.map, p[0], p[1])
	var x_said := "the x-coordinate goes from %s to %s: %s ÷ %s = %s" % [TC.n(s, p[0]), TC.n(s, im[0]), TC.n(s, im[0]), over(s, p[0]), TC.n(s, k)] if not p[0].is_zero() \
		else "the x-coordinate is multiplied by %s" % TC.n(s, k)
	var seen: Array = [rewrite_step(s, rep)] if rep == "graph" else []
	var out := typed(ans, [wrong({"v0": Q.new(1).div(k), "v1": d}, STRETCH)],
		"Find the horizontal scale factor and the vertical translation that map the graph of f onto the graph of g.", [], {
			"rewrite-in-f": [rewrite_step(s, rep), said, "The number added outside is the vertical translation, %s." % TC.n(s, d)],
			"compare-key-points": ["The point %s on f goes to %s on g." % [P_(s, p), P_(s, im)], "For the stretch, %s. For the translation, the y-coordinate goes from %s to %s: %s − %s = %s." % [x_said, TC.n(s, p[1]), TC.n(s, im[1]), TC.n(s, im[1]), par(s, p[1]), TC.n(s, d)]],
			"scale-rule": seen + ["f(bx) + d is a horizontal stretch with scale factor 1/b, then a vertical translation by d.", said, "Here d = %s." % TC.n(s, d)],
		}, s, [{"v0": k, "v1": d.neg()}, {"v0": Q.new(1).div(k), "v1": d.neg()}])
	out.merge(show_pair(rep, s), true)
	return out


## The two wave models of relate-two-models: y = A sin(wt) + D.
static func wave_text(s: Dictionary, a: Q, d: Q, name: String) -> String:
	return "%s(t) = %s%s" % [name, sine(s, a), TC.plus(s, d)]


## "3 sin(4t)", and "sin(4t)" for an amplitude of 1.
static func sine(s: Dictionary, a: Q) -> String:
	return "%ssin(%st)" % ["" if a.eq(1) else TC.n(s, a) + " ", TC.n(s, s.w)]


func u_relate_two_models(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a1: Q = s.a1
	var a2: Q = s.a2
	var d1: Q = s.d1
	var d2: Q = s.d2
	var a := a2.div(a1)
	var d := d2.sub(a.mul(d1))
	var ans := Answer.make("named", {"v0": a, "v1": d}, {"names": ["a", "d"]})
	if s.paper == 2:
		ans.show = "sf"
	else:
		ans.exact = true
	var lines: Array = [wave_text(s, a1, d1, "p"), wave_text(s, a2, d2, "q")] if rep == "equation" else \
		["Wave p has amplitude %s and centre line y = %s." % [TC.n(s, a1), TC.n(s, d1)], "Wave q has amplitude %s and centre line y = %s." % [TC.n(s, a2), TC.n(s, d2)], "Both have the same period and rise through their centre lines at t = 0."]
	var show := func(v: Q) -> String: return Fmt.sf(v) if s.paper == 2 else TC.n(s, v)
	var tail := "So %s." % Answer.text(ans)
	var ad: String = show.call(a.mul(d1))
	var taken: String = "(%s)" % ad if a.mul(d1).sign() < 0 else ad
	var joined: String = (" − " + ad.trim_prefix("−")) if a.mul(d1).sign() < 0 else " + " + ad
	# The words view gives no rule (nor the period), so its working speaks of the centre line.
	var stretched := ("%s%s" % [sine(s, a2), joined]) if rep == "equation" else "a wave of amplitude %s with centre line y = %s" % [TC.n(s, a2), ad]
	var reach := "To reach q, add %s − %s = %s." % [TC.n(s, d2), taken, show.call(d)]
	var steps := {
		"rewrite-in-f": ["Multiplying p by %s gives %s." % [show.call(a), stretched], reach, tail],
		"scale-rule": ["The stretch comes from the amplitudes: %s ÷ %s = %s." % [TC.n(s, a2), TC.n(s, a1), show.call(a)],
			"It also moves the centre line, to y = %s." % ad, "The translation takes it on to y = %s, so d = %s − %s = %s." % [TC.n(s, d2), TC.n(s, d2), taken, show.call(d)], tail],
		"shift-features": ["The amplitude goes from %s to %s, a factor of %s." % [TC.n(s, a1), TC.n(s, a2), show.call(a)],
			"The stretched centre line is y = %s, and it must reach y = %s, a move of %s." % [ad, TC.n(s, d2), show.call(d)], tail],
	}
	var ms := {}
	for m in steps:
		ms[m] = method(steps[m], ans.values)
	var wa := a1.div(a2)
	return {"asked": "The graph of p is mapped onto the graph of q by a vertical stretch with scale factor a, then a vertical translation by d, in that order. Find a and d.",
		"lines": lines, "answer": ans, "methods": ms,
		# The skill's name for the rule ("p f(x) scales y by p; f(qx) ...") reuses the waves' names.
		"titles": {"scale-rule": "a·f(x) stretches every y-value by a"},
		"wrongs": [wrong({"v0": a, "v1": d2.sub(d1)}, D_CENTRE), wrong({"v0": wa, "v1": d2.sub(wa.mul(d1))}, D_AMPS)],
		"fillers": [{"v0": a, "v1": d.neg()}]}


func u_describe_log_rewrite(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.lb
	var e: int = s.le
	var name := Answer.log_name(b)
	var power := roundi(pow(b, e))
	var is_tr: bool = s.lform == "shift"
	var head := "%s(%dx)" % [name, power] if is_tr else "%s(x%s)" % [name, Fmt.sup(e)]
	var plain := name + " x"
	var say := func(rhs: String, move: String) -> String: return "%s = %s, %s" % [head, rhs, move]
	var shift_text := TC.tr_text(s, 0, e)
	var stretch_text := TC.vs_text(s, e)
	var right: String = say.call("%s + %d" % [plain, e], shift_text) if is_tr else say.call("%d %s" % [e, plain], stretch_text)
	# The two log laws mixed up; on a product, the number inside kept as it is, not its log.
	var mixed: String = say.call("%d %s" % [e, plain], stretch_text) if is_tr else say.call("%s + %d" % [plain, e], shift_text)
	var kept: String = say.call("%s + %d" % [plain, power], TC.tr_text(s, 0, power))
	var wrongs: Array = [[mixed, D_LAWS]] + ([[kept, D_NO_LOG]] if is_tr else [])
	var fillers: Array = ([] if is_tr else [kept]) + [say.call("%d %s" % [power, plain], TC.vs_text(s, power))]
	return ask(right, wrongs, fillers, "The graph of y = %s is mapped onto y = %s, for x > 0. Rewrite the new function with a log law, and say which transformation it shows." % [plain, head],
		["y = " + plain, "y = " + head], {
			"rewrite-in-f": [("Log of a product: %s(%d · x) = %s(%d) + %s x, and %s(%d) = %d." % [name, power, name, power, name, name, power, e]) if is_tr else ("Log of a power: %s(x%s) = %d %s." % [name, Fmt.sup(e), e, plain]),
				"A number added to the whole function is a translation." if is_tr else "A number multiplying the whole function is a vertical stretch."],
			"invariant-points": ["(1, 0) is on y = %s. On the new graph, x = 1 gives y = %d." % [plain, e if is_tr else 0],
				("So the point has moved up by %d: this is no stretch, which would leave it on the x-axis." % e) if is_tr else "It has stayed on the x-axis, as a vertical stretch leaves it."],
		})


func u_describe_from_graphs(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := TC.chain_text(s, s.moves)
	var first: Dictionary = s.moves[0]
	var tr_m: Dictionary = s.moves[1]
	var bad: Array = []
	var wrongs: Array = []
	if first.k in ["vs", "hs"]:
		wrongs.append([TC.chain_text(s, [{"k": first.k, "a": Q.new(1).div(first.a)}, tr_m]), D_RATIO])
		if not s.fam in TC.NO_HS:
			bad.append(TC.chain_text(s, [{"k": "hs" if first.k == "vs" else "vs", "a": first.a}, tr_m]))
	else:
		bad.append(TC.chain_text(s, [{"k": "ry" if first.k == "rx" else "rx"}, tr_m]))
	bad.append(TC.chain_text(s, [first, TC.slide(tr_m.c.neg(), tr_m.d)]))
	bad.append(TC.chain_text(s, [first, TC.slide(tr_m.c, tr_m.d.neg())]))
	bad.append(TC.chain_text(s, [TC.slide(tr_m.c, tr_m.d), first]))
	var two: Array = s.key
	var im0 := TC.image(s.map, two[0][0], two[0][1])
	var im1 := TC.image(s.map, two[1][0], two[1][1])
	var gap_f := [two[1][0].sub(two[0][0]), two[1][1].sub(two[0][1])]
	var gap_g := [im1[0].sub(im0[0]), im1[1].sub(im0[1])]
	var across := "From P to Q, x changes by %s and y by %s. From P′ to Q′, x changes by %s and y by %s." % [TC.n(s, gap_f[0]), TC.n(s, gap_f[1]), TC.n(s, gap_g[0]), TC.n(s, gap_g[1])]
	# The ratio of the gaps names the first move, and where it leaves P names the translation.
	var i := 1 if first.k in ["vs", "rx"] else 0
	var other := 1 - i
	var ratio := "The %s-gaps go from %s to %s: %s ÷ %s = %s, and the %s-gaps are unchanged, so the first move is %s." % ["xy"[i], TC.n(s, gap_f[i]), TC.n(s, gap_g[i]),
		TC.n(s, gap_g[i]), over(s, gap_f[i]), TC.n(s, gap_g[i].div(gap_f[i])), "xy"[other], TC.move_text(s, first)]
	var mid := TC.image(TC.compose([first]), two[0][0], two[0][1])
	var rest := "That takes P to %s, and P′ is %s, so the translation is by the vector %s." % [P_(s, mid), P_(s, im0), P_(s, [tr_m.c, tr_m.d])]
	var out := ask(right, wrongs, bad, "Describe the two transformations, in order, that map the graph of f onto the graph of g.", [PAIR_LINE], {
		"compare-key-points": [across, ratio, rest],
		"overlay-graphs": ["Compare the shapes: the gaps between points show any stretch or flip.", across, ratio, rest],
		"track-points": ["P%s goes to P′%s, and Q%s goes to Q′%s." % [P_(s, two[0]), P_(s, im0), P_(s, two[1]), P_(s, im1)], across, ratio, rest],
	})
	out.graph = pair_graph(s)
	return out


func u_describe_with_reflection(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var refl: Dictionary = s.moves[0]
	var other: Dictionary = s.moves[1]
	var right := TC.chain_text(s, s.moves)
	var swapped := TC.chain_text(s, [{"k": "ry" if refl.k == "rx" else "rx"}, other])
	var bad: Array = []
	if other.k == "tr":
		bad = [TC.chain_text(s, [refl, TC.slide(other.c.neg(), other.d)]), TC.chain_text(s, [refl, TC.slide(other.c, other.d.neg())])]
	else:
		bad = [TC.chain_text(s, [refl, {"k": other.k, "a": Q.new(1).div(other.a)}])]
		if s.fam in ["root", "exp", "vert", "pts"]:
			bad.append(TC.chain_text(s, [refl, {"k": "hs" if other.k == "vs" else "vs", "a": other.a}]))
	var sign := "The minus sign is outside f, so the y-values change sign: a reflection in the x-axis." if refl.k == "rx" else "The minus sign is on x, inside f, so the x-values change sign: a reflection in the y-axis."
	# The second move read from the rule too, not only named in the answer.
	var then: String
	match other.k:
		"tr":
			then = "Then %s in the bracket and the%s outside give %s." % [TC.x_minus(s, other.c), TC.plus(s, other.d), TC.move_text(s, other)]
		"vs":
			then = "Then the %s multiplying f gives %s." % [TC.n(s, other.a), TC.move_text(s, other)]
		_:
			then = "Then the %s with x gives %s." % [TC.n(s, s.map.B.abs_q()), TC.move_text(s, other)]
	var seen: String = rewrite_step(s, rep) if rep == "graph" else "Compare a point on the two graphs: %s" % low(point_step(s))
	var out := ask(right, [[swapped, REFLECT]], bad + [TC.chain_text(s, [other]), TC.chain_text(s, [refl])], "Describe the two transformations, in order, that map the graph of f onto the graph of g.", [], {
		"rewrite-in-f": [rewrite_step(s, rep), sign, then],
		"overlay-graphs": [seen, sign, then],
	})
	out.merge(show_pair(rep, s), true)
	return out


func u_describe_after_completing_square(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h: Q = s.moves[0].c
	var k: Q = s.moves[0].d
	var p := h.mul(-2)
	var q := h.mul(h).add(k)
	var line := "y = " + Fmt.poly([Q.new(1), p, q])
	var form := "(%s)²%s" % [TC.x_minus(s, h), TC.plus(s, k)]
	# (x + 2)² is x² + 4x + 4, so the 4 is taken off again: (x + 2)² − 4 + 3.
	var undo := "(%s)² − %s%s = " % [TC.x_minus(s, h), TC.n(s, h.mul(h)), TC.plus(s, q)] if not q.is_zero() else ""
	var done := "Halve %s to get %s, so %s = %s%s." % [TC.n(s, p), TC.n(s, h.neg()), line.trim_prefix("y = "), undo, form]
	var read := "The vertex of y = x² is (0, 0), and here it is %s." % TC.pt(s, h, k)
	return ask(TC.tr_text(s, h, k), [[TC.tr_text(s, h.neg(), k), DESC], [TC.tr_text(s, p, q), D_COEFFS]], [TC.tr_text(s, h.neg(), k.neg()), TC.tr_text(s, h, k.neg())],
		"The graph of y = x² is translated onto the graph of %s. Find the translation." % line, ["y = x²", line], {
			"rewrite-in-f": [done, "That is f(x − c) + d with c = %s and d = %s." % [TC.n(s, h), TC.n(s, k)]],
			"substitute": ["Write (x − a)² + b = x² − 2ax + a² + b and match it with %s." % line.trim_prefix("y = "),
				"−2a = %s gives a = %s, and a² + b = %s gives b = %s − %s = %s." % [TC.n(s, p), TC.n(s, h), TC.n(s, q), TC.n(s, q), TC.n(s, h.mul(h)), TC.n(s, k)]],
			"shift-features": [done, read],
			"complete-square": [done, read],
		})


func u_describe_factor_inside(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: Q = s.moves[0].a
	var c: Q = s.moves[1].c
	var b := Q.new(1).div(k)
	var e := b.mul(c)
	var inside := "%sx%s" % [TC.lead(s, b), TC.plus(s, e.neg())]
	var bracket := "%s(%s)" % [TC.lead(s, b), TC.x_minus(s, c)]
	return ask(TC.chain_text(s, s.moves), [[TC.chain_text(s, [{"k": "hs", "a": b}, TC.slide(c, 0)]), STRETCH],
		[TC.chain_text(s, [{"k": "hs", "a": k}, TC.slide(e, 0)]), D_NOT_FACTORED], [TC.chain_text(s, [{"k": "hs", "a": k}, TC.slide(c.neg(), 0)]), DESC]],
		# The wrong axis is a slip too, but the three above always take the slots.
		[TC.chain_text(s, [{"k": "vs", "a": k}, TC.slide(c, 0)])],
		"Describe the transformations, in order, that map the graph of y = f(x) onto the graph of y = g(x).", ["g(x) = f(%s)" % inside], {
			"rewrite-in-f": ["Take %s out of the bracket: %s = %s." % [TC.n(s, b), inside, bracket], "The %s on x gives %s, and %s then gives the translation, %s." % [TC.n(s, b), TC.hs_text(s, k), TC.x_minus(s, c), across_word(s, c)]],
			"scale-rule": ["Take %s out: g(x) = f(%s)." % [TC.n(s, b), bracket], "f(bx) is a stretch with scale factor 1/b = %s, and %s then moves the graph %s." % [TC.n(s, k), TC.x_minus(s, c), across_word(s, c)]],
		})


func u_vector_from_key_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	# A point off the axes where f has one: from (0, 0) the moved point is the vector itself,
	# and the slip of giving the moved point (D_POINT) would be the key. P is that point.
	var p: Array = telling(s)
	s.key = [p] + s.key.filter(func(q): return q != p)
	var m: Dictionary = s.moves[0]
	var im := TC.image(s.map, p[0], p[1])
	var ans := Answer.make("point", {"x": m.c, "y": m.d})
	var diff := "Change in x: %s − %s = %s. Change in y: %s − %s = %s." % [TC.n(s, im[0]), par(s, p[0]), TC.n(s, m.c), TC.n(s, im[1]), par(s, p[1]), TC.n(s, m.d)]
	var moved := "The point goes from %s to %s." % [P_(s, p), P_(s, im)]
	var out := typed(ans, [wrong({"x": m.c.neg(), "y": m.d.neg()}, D_BACKWARDS), wrong({"x": im[0], "y": im[1]}, D_POINT)],
		"The curve is translated. Find the translation vector.", [], {
			"compare-key-points": [moved, diff],
			"shift-features": ["A translation moves every feature by the same vector, so follow this one point. " + moved, diff],
			"track-points": ["Subtract the start from the end, in that order.", diff],
		# The parts swapped are the key when they are equal, and the backwards slip when they
		# are opposite; one part's sign turned round is never either.
		}, s, [{"x": m.d, "y": m.c}, {"x": m.c, "y": m.d.neg()}, {"x": m.c.neg(), "y": m.d}])
	if rep == "graph":
		out.lines = [PAIR_LINE]
		out.graph = pair_graph(s)
	else:
		out.lines = ["A curve has a key point at %s." % P_(s, p), "After the move, that point is at %s." % P_(s, im)]
	return out


## The moves back from g to f: shared by describe-the-reverse and undo-in-reverse. refs:
## the type's two slips, each move undone but in the old order, and the old order reversed
## with nothing undone.
static func reverse_of(s: Dictionary, lines: Array, refs: Array) -> Dictionary:
	var fwd: Array = s.moves
	var back: Array = TC.undo(fwd)
	var same_order: Array = fwd.map(func(m): return TC.inverse(m))
	var flipped: Array = fwd.duplicate()
	flipped.reverse()
	var kept: Array = back.duplicate()
	kept[kept.size() - 1] = fwd[0]
	var k: Array = s.key[0]
	var im := TC.image(s.map, k[0], k[1])
	var undo := "Undo each move and take them last one first: the last move went on last, so it comes off first."
	var there := "A point goes %s." % trail(s, fwd, k)
	var home := "The moves back take it one move at a time: %s." % trail(s, back, im)
	return ask(TC.chain_text(s, back), [[TC.chain_text(s, same_order), refs[0]], [TC.chain_text(s, flipped), refs[1]]], [TC.chain_text(s, kept), TC.chain_text(s, fwd)],
		"Which moves, in order, map the new graph back onto the original one?", lines, {
			"compare-key-points": [undo, there, home],
			"step-by-step": [there, undo, home],
		})


func u_describe_the_reverse(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var said := "The graph of f goes to the graph of g by %s." % TC.chain_text(s, s.moves)
	if rep == "words":
		return reverse_of(s, ["A curve goes to a new curve by %s." % TC.chain_text(s, s.moves)], [D_SAME_ORDER, D_NOT_UNDONE])
	return reverse_of(s, [f_line(s), g_line(s), said], [D_SAME_ORDER, D_NOT_UNDONE])
