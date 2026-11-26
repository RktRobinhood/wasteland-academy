class_name TransformChainViews
extends TransformApplyViews
## The views on the `transform-chain` situation (FAL-424): every unknown of
## fn-transform-describe (TransformDescribeViews), fn-transform-apply (TransformApplyViews)
## and fn-concept-transform-order, with the needs that pick each one's base and chain.
## The order questions are here: two orders of one pair of moves, written out both ways.

## Bases with a rule, a horizontal stretch that is only that, and no key point needed
## off the axes.
const RULED := ["sq", "cube", "root", "exp", "sin"]
## The same with key points off the axes, and those a graph can show.
const POINTED := ["sq", "cube", "root", "pts", "vert"]
const SKETCH := ["pts", "sq", "cube", "root", "vert", "recip", "log2"]
const SKETCH_HS := ["pts", "sq", "cube", "root", "vert"]
const LOGS := ["root", "ln", "log2"]
const MIRROR := ["root", "exp", "ln", "log2", "pts", "vert"]
const ASYMPTOTIC := ["recip", "exp", "ln", "log2"]
const SETS := ["root", "recip", "exp", "ln", "log2", "sin", "sq", "vert", "pts"]
## Paper 1 only: a log law is the point, there are no numbers to work, or the rule is a
## fraction-free expansion.
const P1_ONLY := ["describe-log-rewrite", "describe-after-completing-square", "sketch-reflection", "reflect-rule"]

const TO := "fn-concept-transform-order#"
const C_INSIDE_AS_Y := TO + "5"
const C_SWAP_IO := TO + "6"
const C_SAME_IO := TO + "7"
const C_OUTSIDE_IN := TO + "8"
const C_SWAP_ORDERS := TO + "9"
const C_SAME_AXIS := TO + "10"
const C_SAME_ORDER := TO + "11"
const C_NOT_UNDONE := TO + "12"

const ORDER_PICKS := [
	{"name": "Add the two scale factors", "why": "a scale factor multiplies, and adding says nothing about the order"},
	{"name": "Read the numbers in the order they are written", "why": "the order written in a rule is not always the order of the moves"},
	{"name": "Swap the moves and assume nothing changes", "why": "the order can change the result"},
]


func needs() -> Dictionary:
	return {
		"describe-translation": {"fams": TC.ALL, "pat": "tr"},
		"describe-stretch": {"fams": ["sq", "cube", "root", "recip", "log2", "pts"], "pat": "stretch"},
		"stretch-and-shift-parameters": {"fams": POINTED, "pat": "hs-vt"},
		"relate-two-models": {"kind": "models"},
		"describe-log-rewrite": {"kind": "log"},
		"describe-from-graphs": {"fams": SKETCH, "pat": "two"},
		"describe-with-reflection": {"fams": MIRROR, "pat": "ref-one"},
		"describe-after-completing-square": {"fams": ["sq"], "pat": "tr"},
		"describe-factor-inside": {"fams": RULED, "pat": "factor"},
		"vector-from-key-point": {"fams": SKETCH, "pat": "tr"},
		"describe-the-reverse": {"fams": RULED, "pat": "any-chain"},
		"sketch-stretch-shift": {"fams": SKETCH, "pat": "vs-vt"},
		"reflect-translate-rule": {"fams": LOGS, "pat": "ref-tr"},
		"rule-from-moves": {"fams": RULED, "pat": "chain"},
		"rule-single-translation": {"fams": TC.ALL, "pat": "tr"},
		"reflect-rule": {"fams": ["poly", "poly", "root", "exp", "ln"], "pat": "ref"},
		"sketch-reflection": {"fams": ["pts", "root", "log2", "vert"], "pat": "ref"},
		"sketch-horizontal": {"fams": SKETCH_HS, "pat": "hz"},
		"image-point": {"fams": SKETCH_HS, "pat": "chain"},
		"original-point": {"fams": SKETCH_HS, "pat": "chain"},
		"moved-asymptote": {"fams": ASYMPTOTIC, "pat": "asym", "marks": 1},
		"domain-range-of-g": {"fams": SETS, "pat": "chain"},
		"undo-moves": {"fams": ["vert"], "pat": "chain"},
		"order-changes-rule": {"fams": RULED, "pat": "mixed"},
		"two-orders": {"fams": RULED, "pat": "pair"},
		"which-pairs-commute": {"fams": ["pts"], "pat": "tr"},
		# Two families (FAL-1605): each cell's move hangs on its method (TC.for_angle), and
		# the two unknowns' first methods ask for different moves, so one draw can't serve both.
		"inside-opposite": {"fams": POINTED, "pat": "hz", "apart": "inside-opposite"},
		"inside-vs-outside": {"fams": POINTED, "pat": "hz", "apart": "inside-vs-outside"},
		"order-from-bracket": {"fams": ["pts"], "pat": "bracket"},
		"point-both-orders": {"fams": SKETCH_HS, "pat": "pair"},
		"undo-in-reverse": {"fams": RULED, "pat": "chain"},
	}


## A wave or a log is no chain, so neither shares a family with one.
func merge_need(a: Dictionary, b: Dictionary) -> Variant:
	if a.get("kind", "") != b.get("kind", ""):
		return null
	return QuestionEngine.merge_need(a, b)


## The concept type's formats. It lists error-spot, but no error-spot misconception, so
## none is built; order-steps and match aren't formats the engine plays.
func extra() -> Dictionary:
	var out := {}
	for u in ["two-orders", "which-pairs-commute", "inside-opposite", "inside-vs-outside", "order-from-bracket", "point-both-orders", "undo-in-reverse"]:
		out[u] = ["true-false-reason", "method-pick"]
	return out


## The papers a cell can be asked on (QuestionEngine.cell_papers). A GDC method needs
## Paper 2; the rest make both but for P1_ONLY. The order questions take their numbers
## on Paper 1, as an extension type has no paper of its own.
func papers(unknown: String, _rep: String, angle_id: String) -> Array:
	if angle_id.begins_with("gdc"):
		return [2]
	if unknown in P1_ONLY:
		return [1]
	return [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	if unknown in extra():
		out.pick_wrongs = ORDER_PICKS
	return out


# ── fn-concept-transform-order ───────────────────────────────

func u_two_orders(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var stretch_m: Dictionary = s.moves[0]
	var t: Dictionary = s.moves[1]
	var first := TC.compose([stretch_m, t])
	var second := TC.compose([t, stretch_m])
	var k: Array = s.key[0]
	var im1 := TC.image(first, k[0], k[1])
	var im2 := TC.image(second, k[0], k[1])
	var say := func(m1: Dictionary, m2: Dictionary, p1: Array, p2: Array) -> String:
		return "stretch first, g(x) = %s and %s goes to %s; translation first, g(x) = %s and it goes to %s" % [TC.rule(s, m1), P_(s, k), P_(s, p1), TC.rule(s, m2), P_(s, p2)]
	var never := "the order never matters: g(x) = %s both ways" % TC.rule(s, first)
	# The translation the wrong way. It is along one axis, so the other part stays 0: with
	# only D turned round, a horizontal pair's filler was the key, or "never matters" again.
	var shifted := with(first, {"C": first.C.neg(), "D": first.D.neg()})
	var wrong_im := TC.image(shifted, k[0], k[1])
	var lines: Array = [f_given(rep, s), "Two moves: %s, and %s." % [TC.move_text(s, stretch_m), TC.move_text(s, t)]]
	var by_rule: Array = ["Stretch first: %s." % then_rule(s, stretch_m, t), "Translation first: %s." % then_rule(s, t, stretch_m)]
	var track := "Follow %s: stretch first, %s; translation first, %s." % [P_(s, k), trail(s, [stretch_m, t], k), trail(s, [t, stretch_m], k)]
	return ask(say.call(first, second, im1, im2), [[never, COMP_ORDER], [say.call(second, first, im2, im1), C_SWAP_ORDERS]],
		[say.call(first, shifted, im1, wrong_im), say.call(shifted, second, wrong_im, im2)],
		"Find g(x) for each order, and where a point goes each way.", lines, {
			"step-by-step-substitution": by_rule + [track],
			"track-a-point": [track] + by_rule,
		})


## What a move does to a rule written with f: "add 3", "replace x with ½x".
static func move_does(s: Dictionary, m: Dictionary) -> String:
	match m.k:
		"vs":
			return "multiply all of it by %s" % TC.n(s, m.a)
		"hs":
			return "replace x with %sx" % TC.lead(s, Q.new(1).div(m.a))
		"tr":
			if m.c.is_zero():
				return ("add %s" if m.d.sign() > 0 else "take away %s") % TC.n(s, m.d.abs_q())
			if m.d.is_zero():
				return "replace x with " + TC.x_minus(s, m.c)
	return TC.move_text(s, m)


## The rule after m1, then after m2 as well: "f(x) + 3, then multiply all of it by 2:
## 2(f(x) + 3) = 2f(x) + 6".
static func then_rule(s: Dictionary, m1: Dictionary, m2: Dictionary) -> String:
	var one := f_form(s, TC.compose([m1]))
	var mid := ""
	if m1.k == "tr" and m2.k == "vs":
		mid = "%s(%s) = " % [TC.lead(s, m2.a), one]
	elif m1.k == "tr" and m2.k == "hs":
		mid = "f(%sx%s) = " % [TC.lead(s, Q.new(1).div(m2.a)), TC.plus(s, m1.c.neg())]
	return "%s, then %s: %s%s" % [one, move_does(s, m2), mid, f_form(s, TC.compose([m1, m2]))]


## A pair of moves as written: "a vertical stretch with scale factor 2 and a translation up 3".
static func pair_text(s: Dictionary, a: Dictionary, b: Dictionary) -> String:
	return "%s and %s" % [TC.move_text(s, a), TC.move_text(s, b)]


func u_which_pairs_commute(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var v := TC.vs(rng, 1)
	var h := TC.hs(rng, 1)
	var up := TC.slide(0, ExtensionViews.nonzero(rng, 1, 5))
	var side := TC.slide(ExtensionViews.nonzero(rng, 1, 5), 0)
	var rx := {"k": "rx"}
	var ry := {"k": "ry"}
	var free: Array = [[v, side], [h, up], [v, h], [rx, side], [ry, up]]
	var bound: Array = [[v, up], [h, side], [rx, up], [ry, side]]
	var free_pair: Array = rng.pick(free)
	var yes := "%s: one acts on x and the other on y, so neither changes the other" % pair_text(s, free_pair[0], free_pair[1])
	var wrongs: Array = [["any two moves: the order of moves never matters", COMP_ORDER]]
	var tied: Array = rng.shuffled(bound)
	for b in tied:
		wrongs.append(["%s: one acts on x and the other on y, so neither changes the other" % pair_text(s, b[0], b[1]), C_SAME_AXIS])
	var show := "Try each pair on y = f(x), first one way and then the other, and compare the two rules."
	# The working tries the pair that commutes and one that doesn't, rather than saying so.
	var both := func(p: Array) -> String:
		return "%s, then %s, gives %s; the other way round gives %s" % [TC.move_text(s, p[0]), TC.move_text(s, p[1]), f_form(s, TC.compose(p)), f_form(s, TC.compose([p[1], p[0]]))]
	return ask(yes, wrongs, [], "Which pair of moves gives the same graph in either order, for every f?", ["Think of each pair as two moves on y = f(x)."], {
		"step-by-step-substitution": [show, TC.cap(both.call(tied[0])) + ": two different graphs, as both moves act along one axis.",
			TC.cap(both.call(free_pair)) + ": the same, as one acts on x and the other on y."],
	})



func u_inside_opposite(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Dictionary = s.moves[0]
	var right: String
	var wrongs: Array
	var bad: Array
	var track: Array
	var scale: Array
	if m.k == "tr":
		var c: Q = m.c
		var more := "x %s %s" % ["−" if c.sign() > 0 else "+", TC.n(s, c.abs_q())]
		var why := "%s reaches each input %s later, so the graph is moved the opposite way to the sign" % [more, TC.n(s, c.abs_q())] if c.sign() > 0 \
			else "%s reaches each input %s sooner, so the graph is moved the opposite way to the sign" % [more, TC.n(s, c.abs_q())]
		right = "%s: %s" % [across_word(s, c), why]
		# x − c read as f(x) − c moves it down, and x + c read as f(x) + c up: the sign
		# says which way and how. The filler turns that the other way, on the wrong axis.
		wrongs = [["%s: the sign says which way" % across_word(s, c.neg()), DESC],
			["%s: the number is %s" % [vert_word(s, c.neg()), "taken away" if c.sign() > 0 else "added"], C_INSIDE_AS_Y]]
		bad = ["%s: the graph moves the opposite way to the sign" % vert_word(s, c)]
		track = ["%s = 0 at x = %s, so what f did at 0, g does at %s." % [more, TC.n(s, c), TC.n(s, c)], "So every point moves %s." % across_word(s, c)]
	else:
		var k: Q = m.a
		var b: Q = s.map.B
		var why := "%sx reaches each input at %s times the x, so the factor is the reciprocal" % [TC.lead(s, b), TC.n(s, k)]
		right = "%s: %s" % [TC.hs_text(s, k), why]
		wrongs = [["%s: the number with x is the factor" % TC.hs_text(s, b), STRETCH], ["%s: the number with x is the factor" % TC.vs_text(s, b), C_INSIDE_AS_Y]]
		bad = ["%s: the number is outside the function" % TC.vs_text(s, k)]
		scale = ["f(bx) is a horizontal stretch with scale factor 1/b, here 1 ÷ %s = %s." % [over(s, b), TC.n(s, k)], "x must be %s times the size to give the same input." % TC.n(s, k)]
	# Each method works only one kind of move: tracking points by a vector (the translate
	# skill's method) a translation, the scale rule a stretch. A stretch's question isn't
	# offered "move key points by the vector", nor a translation's the scale rule.
	var methods := {"track-points": track} if m.k == "tr" else {"scale-rule": scale}
	var out := ask(right, wrongs, bad, "How does the graph of g sit compared with the graph of f, and why?", ["g(x) = " + f_form(s, s.map)], methods)
	if rep == "graph":
		out.lines = [PAIR_LINE, "g(x) = " + f_form(s, s.map)]
		out.graph = pair_graph(s)
	return out


## A key point that two maps send to different places, so a graph can mark which curve is
## which: (0, 0) stays put under both stretches, and A and B would sit on one spot.
static func marked_apart(s: Dictionary, m1: Dictionary, m2: Dictionary) -> Array:
	for k in s.key:
		var a := TC.image(m1, k[0], k[1])
		var b := TC.image(m2, k[0], k[1])
		if not (a[0].eq(b[0]) and a[1].eq(b[1])):
			return k
	return s.key[0]


func u_inside_vs_outside(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var m: Dictionary = s.moves[0]
	var one := TC.identity()
	var inner_map: Dictionary = s.map
	var outer_map: Dictionary
	var in_says: String
	var out_says: String
	# in_sign: the inside change read the way it is written (x + 3 as 3 to the right, f(2x)
	# as scale factor 2); out_flip: the outside one turned round as if it were inside.
	var in_sign: String
	var out_flip: String
	var in_why: String
	var out_why: String
	var slip: String
	if m.k == "tr":
		var c: Q = m.c.neg()
		outer_map = with(one, {"D": c})
		in_says = "moves it along the x-axis, %s" % across_word(s, c.neg())
		out_says = "moves it along the y-axis, %s" % vert_word(s, c)
		in_sign = "moves it along the x-axis, %s" % across_word(s, c)
		out_flip = "moves it along the y-axis, %s" % vert_word(s, c.neg())
		slip = DESC
		var x_c := TC.x_minus(s, c.neg())
		in_why = "%s = 0 at x = %s, so f(%s) does at %s what f does at 0: %s." % [x_c, TC.n(s, c.neg()), x_c, TC.n(s, c.neg()), across_word(s, c.neg())]
		out_why = "f(x)%s %s %s %s every y-value: %s." % [TC.plus(s, c), "adds" if c.sign() > 0 else "takes", TC.n(s, c.abs_q()), "to" if c.sign() > 0 else "from", vert_word(s, c)]
	else:
		var b: Q = s.map.B
		outer_map = with(one, {"A": b})
		in_says = "stretches it parallel to the x-axis, scale factor %s" % TC.n(s, m.a)
		out_says = "stretches it parallel to the y-axis, scale factor %s" % TC.n(s, b)
		in_sign = "stretches it parallel to the x-axis, scale factor %s" % TC.n(s, b)
		out_flip = "stretches it parallel to the y-axis, scale factor %s" % TC.n(s, m.a)
		slip = STRETCH
		in_why = "%s at x does what f does at %sx, so every x-coordinate is multiplied by 1 ÷ %s = %s." % [f_form(s, s.map), TC.lead(s, b), over(s, b), TC.n(s, m.a)]
		out_why = "%s multiplies every y-value by %s." % [f_form(s, outer_map), TC.n(s, b)]
	var in_name := f_form(s, inner_map)
	var out_name := f_form(s, outer_map)
	var both := func(a: String, b: String) -> String: return "%s %s; %s %s" % [in_name, a, out_name, b]
	var right: String = both.call(in_says, out_says)
	var swapped: String = both.call(out_says, in_says)
	var same := "%s and %s are the same graph" % [in_name, out_name]
	var lines: Array = ["Two functions make the same change to f, inside the bracket and outside it: %s and %s." % [in_name, out_name]]
	var out := {}
	var reading := "A change inside the bracket acts on x and goes the opposite way. A change outside acts on y and goes as it reads."
	if rep == "graph":
		var win := TC.window(s, [inner_map, outer_map])
		var a_inner := rng.chance(0.5)
		var c0 := TC.curves(s, inner_map if a_inner else outer_map, win)
		var c1 := TC.curves(s, outer_map if a_inner else inner_map, win)
		var k: Array = marked_apart(s, inner_map, outer_map)
		var im0 := TC.image(inner_map if a_inner else outer_map, k[0], k[1])
		var im1 := TC.image(outer_map if a_inner else inner_map, k[0], k[1])
		var g := Plot.spec(c0 + c1, [[im0[0].to_float(), im0[1].to_float(), "A"], [im1[0].to_float(), im1[1].to_float(), "B"]], win[0], win[1], win[2], win[3])
		g.one_colour = true
		g.sand_from = c0.size()
		right = "A is %s, B is %s" % [in_name if a_inner else out_name, out_name if a_inner else in_name]
		swapped = "A is %s, B is %s" % [out_name if a_inner else in_name, in_name if a_inner else out_name]
		same = "A and B are the same graph"
		var pair := "%s %s; %s %s." % [in_name, in_says, out_name, out_says]
		# A and B are where one named point of f goes, so the curves can be told apart.
		var im_in := TC.image(inner_map, k[0], k[1])
		var im_out := TC.image(outer_map, k[0], k[1])
		var follow := "So %s goes to %s on %s and to %s on %s." % [P_(s, k), P_(s, im_in), in_name, P_(s, im_out), out_name]
		var tell := "A is at %s, so A is %s and B is %s." % [P_(s, im0), in_name if a_inner else out_name, out_name if a_inner else in_name]
		out = ask(right, [[swapped, C_SWAP_IO], [same, C_SAME_IO]], ["neither is a move of f", "A is f(x), B is f(x)"], "Which curve is which, in the graph shown?",
			lines + ["Curve A goes through the marked point A, and curve B through B: each is where the point %s on y = f(x) goes." % P_(s, k)], scale_only({
			"scale-rule": [reading, pair, follow, tell],
			"rewrite-in-f": ["Compare each with f(x): %s" % pair, follow, tell],
		}, m))
		out.graph = g
		return out
	var ms := {
		"scale-rule": [reading, in_why, out_why],
		"rewrite-in-f": ["Both are written with f, so read where the change sits: %s is inside the bracket, %s outside." % [in_name, out_name], in_why, out_why],
	}
	return ask(right, [[swapped, C_SWAP_IO], [same, C_SAME_IO], [both.call(in_sign, out_says), slip]], [both.call(in_says, out_flip)],
		"What does each do to the graph of f, and along which axis?", lines, scale_only(ms, m))


## The scale rule works a stretch, not a translation (FAL-1605): a translation's question
## has no scale-rule working, so the engine doesn't name it there.
static func scale_only(methods: Dictionary, m: Dictionary) -> Dictionary:
	if m.k == "tr":
		methods.erase("scale-rule")
	return methods


func u_order_from_bracket(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var moves: Array = s.moves
	var right := TC.chain_text(s, moves)
	var wrongs: Array = []
	var bad: Array = []
	var line: String
	var lead_step: String
	var ms := {}
	if moves[0].k == "hs":
		var k: Q = moves[0].a
		var c: Q = moves[1].c
		var b := Q.new(1).div(k)
		var e := b.mul(c)
		line = "g(x) = f(%sx%s)" % [TC.lead(s, b), TC.plus(s, e.neg())]
		wrongs = [[TC.chain_text(s, [moves[0], TC.slide(e, 0)]), COMP_IN], [TC.chain_text(s, [{"k": "hs", "a": b}, moves[1]]), STRETCH],
			[TC.chain_text(s, [moves[0], TC.slide(c.neg(), 0)]), DESC]]
		bad = [TC.chain_text(s, [moves[1], {"k": "hs", "a": b}])]
		lead_step = "Take %s out of the bracket: g(x) = f(%s(%s))." % [TC.n(s, b), TC.lead(s, b), TC.x_minus(s, c)]
		var each := "The %s on x is %s, and %s then moves it %s." % [TC.n(s, b), TC.hs_text(s, k), TC.x_minus(s, c), across_word(s, c)]
		ms = {
			"step-by-step-substitution": [lead_step, "Stretch first: f(x) becomes f(%sx). Then x replaced with %s gives f(%s(%s)), %s." % [TC.lead(s, b), TC.x_minus(s, c), TC.lead(s, b), TC.x_minus(s, c), TC.move_text(s, moves[1])]],
			"stretch-then-translate-form": [lead_step, "In f(b(x − c)), the stretch has scale factor 1/b = 1 ÷ %s = %s, and the translation is %s." % [over(s, b), TC.n(s, k), across_word(s, c)]],
			"rewrite-in-f": [lead_step, each],
		}
	else:
		var d: Q = moves[0].d
		var a: Q = moves[1].a
		line = "g(x) = %s(f(x)%s)" % [TC.lead(s, a), TC.plus(s, d)]
		var ad := a.mul(d)
		wrongs = [[TC.chain_text(s, [moves[1], moves[0]]), C_OUTSIDE_IN]]
		bad = [TC.chain_text(s, [TC.slide(0, ad), moves[1]]), TC.chain_text(s, [TC.slide(0, d.neg()), moves[1]]), TC.chain_text(s, [TC.slide(0, d), {"k": "vs", "a": Q.new(1).div(a)}])]
		lead_step = "Work from the bracket out: f(x)%s comes first, then the %s multiplies all of it." % [TC.plus(s, d), TC.n(s, a)]
		var each := "f(x)%s is %s, and multiplying by %s is then %s." % [TC.plus(s, d), TC.move_text(s, moves[0]), TC.n(s, a), TC.move_text(s, moves[1])]
		# Not the stretch-then-translate form: read that way, a(f(x) + d) = af(x) + ad is a
		# stretch, then a translation by ad, which isn't the order this key gives.
		ms = {
			"step-by-step-substitution": [lead_step, "Translation first: f(x) becomes f(x)%s. Then multiplying all of it by %s gives %s(f(x)%s)." % [TC.plus(s, d), TC.n(s, a), TC.lead(s, a), TC.plus(s, d)], each],
			"rewrite-in-f": [lead_step, each],
		}
	return ask(right, wrongs, bad, "Give an order of moves that takes the graph of y = f(x) to the graph of y = g(x), and the size of each.", [line], ms)


func u_point_both_orders(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var stretch_m: Dictionary = s.moves[0]
	var t: Dictionary = s.moves[1]
	var k: Array = s.key[0]
	var first := TC.compose([stretch_m, t])
	var second := TC.compose([t, stretch_m])
	var im1 := TC.image(first, k[0], k[1])
	var im2 := TC.image(second, k[0], k[1])
	var say := func(p1: Array, p2: Array) -> String: return "stretch first, %s; translation first, %s" % [P_(s, p1), P_(s, p2)]
	var swapped_ref: String = IM_ORDER if stretch_m.k == "vs" else C_SWAP_ORDERS
	var off: Array = [im1[0].add(1), im1[1].add(1)]
	var lines: Array = ["The point P%s lies on y = f(x)." % P_(s, k), "Two moves: %s, and %s." % [TC.move_text(s, stretch_m), TC.move_text(s, t)]]
	var out := ask(say.call(im1, im2), [[say.call(im2, im1), swapped_ref], [say.call(im1, im1), COMP_ORDER], [say.call(im2, im2), COMP_ORDER]], [say.call(off, im2)],
		"Find the image of P under each order.", lines, {
			"track-a-point": ["Stretch, then translate: %s." % trail(s, [stretch_m, t], k), "Translate, then stretch: %s." % trail(s, [t, stretch_m], k)],
			"step-by-step": ["Stretch first: the stretch takes %s to %s, and the translation then takes it to %s." % [P_(s, k), P_(s, TC.image(TC.compose([stretch_m]), k[0], k[1])), P_(s, im1)],
				"Translation first: the translation takes %s to %s, and the stretch acts on that moved point too, taking it to %s." % [P_(s, k), P_(s, TC.image(TC.compose([t]), k[0], k[1])), P_(s, im2)]],
		})
	if rep == "graph":
		out.lines = ["The graph of y = f(x) is shown, with the point P%s." % P_(s, k), lines[1]]
		out.graph = f_plot_at(s, k)
	return out


func u_undo_in_reverse(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return reverse_of(s, ["A curve goes to a new curve by %s." % TC.chain_text(s, s.moves)], [C_SAME_ORDER, C_NOT_UNDONE])
