class_name LinearInputViews
extends ExtensionViews
## The views on the `linear-input` situation, one builder per unknown of fn-ext-linear-input
## (FAL-1008): y = f(ax + b) is y = f(x) translated by (−b, 0) and then stretched horizontally
## with scale factor 1/a, so (p, q) goes to ((p − b)/a, q); y = f(b − x) is a reflection in the
## y-axis and then a translation by (b, 0), so (p, q) goes to (b − p, q).
## A point is typed (`point`); the moves are a choice of written sequences, in the order the
## asked method takes them; the graph is pick-the-graph, on transformation-chain's cards. The
## image of a point and f(b − x) are also played as error-spots: a student solving ax + b = p.

const TC := preload("res://engine/situations/transform_chain.gd")
const TDV := preload("res://engine/situations/transform_describe_views.gd")

const SK := "AHL2.16.linear-input#"
const R_FIRST := SK + "0"
const R_FACTOR := SK + "1"
const R_WAY := SK + "2"
const OWN := "fn-ext-linear-input#"
const R_HEIGHT := OWN + "3"
const R_NO_SHIFT := OWN + "4"
const R_REFL_WAY := OWN + "5"
const R_SIGN := OWN + "6"
const R_MUL := OWN + "7"


func needs() -> Dictionary:
	var lin := {"kind": "lin"}
	return {"image-point": lin, "original-point": lin, "describe-moves": lin, "pick-graph": lin, "reflect-inside": {"kind": "refl"}}


func extra() -> Dictionary:
	return {"image-point": ["error-spot"], "reflect-inside": ["error-spot"]}


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = LinearInputSituation.export(s)
	return out


# ── Writing it ───────────────────────────────────────────────

## The input as written: "2x + 6", "½x − 3", "(1/3)x + 2", or "3 − x".
static func inside(s: Dictionary) -> String:
	if s.kind == "refl":
		return "%s − x" % N(s.b)
	return Fmt.lead(s.a) + "x" + TC.plus(s, s.b)


static func fx(s: Dictionary) -> String:
	return "f(%s)" % inside(s)


## "2(x + 3)": the input with a taken out.
static func factored(s: Dictionary) -> String:
	return "%s(x%s)" % [Fmt.lead(s.a), TC.plus(s, s.b.div(s.a))]


static func pt(x: Variant, y: Variant) -> String:
	return "(%s, %s)" % [N(x), N(y)]


static func point(x: Variant, y: Variant) -> Dictionary:
	return {"x": Q.of(x), "y": Q.of(y)}


## 1/a, the horizontal scale factor.
static func k(s: Dictionary) -> Q:
	return Q.new(1).div(s.a)


static func shift_text(s: Dictionary, c: Variant) -> String:
	return TC.tr_text(s, c, 0)


static func stretch_text(s: Dictionary, f: Variant) -> String:
	return TC.hs_text(s, f)


## A sequence of moves as an option: "A translation by the vector (−6, 0), then a horizontal
## stretch with scale factor 1/2".
static func seq(first: String, second: String) -> String:
	return TC.cap("%s, then %s" % [first, second])


## The moves of y = f(ax + b) as a sentence, translation first.
static func moves_tts(s: Dictionary) -> String:
	return "y = %s is y = f(x) translated by the vector %s, then stretched horizontally with scale factor %s." % [fx(s), pt(s.b.neg(), 0), N(k(s))]


static func moves_fi(s: Dictionary) -> String:
	return "%s = f(%s): a horizontal stretch with scale factor %s, then a translation by the vector %s." % [fx(s), factored(s), N(k(s)), pt(s.b.div(s.a).neg(), 0)]


static func given_point(s: Dictionary) -> String:
	return "The point P%s lies on the graph of y = f(x)." % pt(s.p, s.q)


## The graph of f with only P marked.
static func f_with_p(s: Dictionary) -> Dictionary:
	var g := Plot.spec(TC.curves(s, TC.identity(), s.win), [[s.p.to_float(), s.q.to_float(), "P" + pt(s.p, s.q)]], s.win[0], s.win[1], s.win[2], s.win[3])
	g.one_colour = true
	return g


## A student solving for the image: f(p) = q, the input set to p, b moved across (or kept, R_SIGN),
## then divided by a (or multiplied, R_MUL). bad is the first wrong line, -1 for none.
static func solving_lines(s: Dictionary, slip: String) -> Array:
	var p: Q = s.p
	var b: Q = s.b
	var rhs: Q = p.add(b) if slip == R_SIGN else p.sub(b)
	var x: Q = rhs.mul(s.a) if slip == R_MUL else rhs.div(s.a)
	var lhs: String = "−x" if s.kind == "refl" else Fmt.lead(s.a) + "x"
	return ["P%s is on y = f(x), so f(%s) = %s." % [pt(p, s.q), N(p), N(s.q)],
		"On y = %s the height is %s where %s = %s." % [fx(s), N(s.q), inside(s), N(p)],
		"%s = %s" % [lhs, N(rhs)],
		"x = %s, so the image is %s." % [N(x), pt(x, s.q)]]


static func spot(s: Dictionary, slip: String) -> Dictionary:
	var lines := solving_lines(s, slip)
	var lhs: String = "−x" if s.kind == "refl" else Fmt.lead(s.a) + "x"
	if slip == R_SIGN:
		return {"lines": lines, "bad": 2, "ref": R_SIGN,
			"why": "taking %s to the other side changes its sign, so %s = %s − %s = %s" % [N(s.b), lhs, N(s.p), P(s.b), N(s.p.sub(s.b))]}
	return {"lines": lines, "bad": 3, "ref": R_MUL,
		"why": "to get x on its own, divide by %s: x = %s ÷ %s = %s" % [N(s.a), N(s.p.sub(s.b)), P(s.a), N(s.x0)]}


# ── fn-ext-linear-input ──────────────────────────────────────

func u_image_point(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: Q = s.a
	var b: Q = s.b
	var p: Q = s.p
	var q: Q = s.q
	var x0: Q = s.x0
	var ans := Answer.make("point", point(x0, q))
	var wrongs: Array = rng.shuffled([
		wrong(point(p.div(a).sub(b), q), R_FIRST),
		wrong(point(p.sub(b).mul(a), q), R_FACTOR),
		wrong(point(p.add(b).div(a), q), R_WAY),
		wrong(point(x0, q.div(a)), R_HEIGHT),
	])
	var height := "Only x changes, so the height stays %s." % N(q)
	var out := TDV.typed(ans, wrongs, "Find the image of P on the graph of y = %s." % fx(s), [given_point(s)], {
		"translate-then-stretch": [moves_tts(s), "x-coordinate: %s − %s = %s, then %s × %s = %s." % [N(p), P(b), N(p.sub(b)), P(p.sub(b)), P(k(s)), N(x0)], height],
		"factorise-inside": [moves_fi(s), "x-coordinate: %s × %s = %s, then %s%s = %s." % [P(p), P(k(s)), N(p.div(a)), N(p.div(a)), TC.plus(s, b.div(a).neg()), N(x0)], height],
		"solve-for-image": ["The image is where the input to f is %s: solve %s = %s." % [N(p), inside(s), N(p)],
			"%sx = %s, so x = %s." % [Fmt.lead(a), N(p.sub(b)), N(x0)], "The height is f(%s) = %s." % [N(p), N(q)]],
	}, s)
	out.spot = spot(s, R_SIGN if rng.chance(0.5) else R_MUL)
	return out


func u_original_point(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: Q = s.a
	var b: Q = s.b
	var p: Q = s.p
	var q: Q = s.q
	var x0: Q = s.x0
	var wrongs: Array = rng.shuffled([
		wrong(point(x0.div(a).add(b), q), R_FACTOR),
		wrong(point(x0.mul(a).sub(b), q), R_WAY),
		wrong(point(p, q.mul(a)), R_HEIGHT),
	])
	return TDV.typed(Answer.make("point", point(p, q)), wrongs, "Find the point on the graph of y = f(x) that Q came from.",
		["The point Q%s lies on the graph of y = %s." % [pt(x0, q), fx(s)]], {
		"translate-then-stretch": [moves_tts(s) + " Undo them, last first.",
			"x-coordinate: %s × %s = %s, then %s%s = %s." % [P(x0), P(a), N(x0.mul(a)), N(x0.mul(a)), TC.plus(s, b), N(p)], "Only x changes, so the height stays %s." % N(q)],
		"solve-for-image": ["Q is on y = %s, so f at %s × %s%s is %s." % [fx(s), P(a), P(x0), TC.plus(s, b), N(q)],
			"%s × %s%s = %s, so f(%s) = %s." % [P(a), P(x0), TC.plus(s, b), N(p), N(p), N(q)]],
	}, s)


func u_describe_moves(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: Q = s.b
	var c: Q = b.div(s.a)
	var right: String
	var wrongs: Array
	if angle == "factorise-inside":
		right = seq(stretch_text(s, k(s)), shift_text(s, c.neg()))
		wrongs = [[seq(stretch_text(s, k(s)), shift_text(s, b.neg())), R_FIRST], [seq(stretch_text(s, s.a), shift_text(s, c.neg())), R_FACTOR], [seq(stretch_text(s, k(s)), shift_text(s, c)), R_WAY]]
	else:
		right = seq(shift_text(s, b.neg()), stretch_text(s, k(s)))
		wrongs = [[seq(stretch_text(s, k(s)), shift_text(s, b.neg())), R_FIRST], [seq(shift_text(s, b.neg()), stretch_text(s, s.a)), R_FACTOR], [seq(shift_text(s, b), stretch_text(s, k(s))), R_WAY]]
	# Each method gives the moves in its own order, so only the asked one's working is shown:
	# the other's sequence is right too but is not among the options.
	var ways := {
		"translate-then-stretch": ["%s is x%s with %sx put in place of x." % [inside(s), TC.plus(s, b), Fmt.lead(s.a)],
			"f(x%s) is f(x) translated by the vector %s; putting %sx in place of x then stretches it horizontally with scale factor %s." % [TC.plus(s, b), pt(b.neg(), 0), Fmt.lead(s.a), N(k(s))]],
		"factorise-inside": ["Take %s out of the input: %s = %s." % [N(s.a), inside(s), factored(s)],
			"f(%sx) is a horizontal stretch with scale factor %s; putting x%s in place of x then translates it by the vector %s." % [Fmt.lead(s.a), N(k(s)), TC.plus(s, c), pt(c.neg(), 0)]],
	}
	var way: String = "factorise-inside" if angle == "factorise-inside" else "translate-then-stretch"
	return TDV.ask(right, wrongs, [], "Which sequence of moves maps the graph of y = f(x) onto the graph of y = %s?" % fx(s), [], {way: ways[way]})


func u_pick_graph(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: Q = s.a
	var b: Q = s.b
	var maps: Array = LinearInputSituation.all_maps(s)
	var wrongs: Array = [
		{"graph": TDV.card(s, maps[1], s.win), "ref": R_FIRST, "mistake": "stretch-first",
			"why": "it is stretched first and then translated by the whole of %s, which is f(%s(x%s))" % [pt(b.neg(), 0), Fmt.lead(a), TC.plus(s, b)]},
		{"graph": TDV.card(s, maps[2], s.win), "ref": R_FACTOR, "mistake": "factor-a",
			"why": "it is stretched with scale factor %s, not 1 ÷ %s = %s" % [N(a), N(a), N(k(s))]},
		{"graph": TDV.card(s, maps[3], s.win), "ref": R_WAY, "mistake": "wrong-way",
			"why": "it is translated by %s, the same way as the sign of b = %s, not the opposite way, %s" % [pt(b, 0), N(b), pt(b.neg(), 0)]},
	]
	var pk := GdcKit.pick(TDV.card(s, s.map, s.win), wrongs, rng)
	var moved: PackedStringArray = []
	var names := ["P", "Q"]
	for i in s.key.size():
		var kp: Array = s.key[i]
		moved.append("%s%s goes to %s" % [names[i], pt(kp[0], kp[1]), pt(kp[0].sub(b).div(a), kp[1])])
	var final := "So the graph is %s." % pk.answer.values.v
	return {"asked": "Which graph is y = %s?" % fx(s), "lines": ["The graph of y = f(x) is shown, with labelled points."], "graph": TDV.f_plot(s),
		"answer": pk.answer, "graphs": pk.graphs, "methods": {
		"translate-then-stretch": method([moves_tts(s), " and ".join(moved) + ".", final], pk.answer.values)}}


func u_reflect_inside(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: Q = s.b
	var p: Q = s.p
	var q: Q = s.q
	var x0: Q = s.x0
	var wrongs: Array = [wrong(point(p.neg(), q), R_NO_SHIFT), wrong(point(x0, q.neg()), R_HEIGHT), wrong(point(p.neg().sub(b), q), R_REFL_WAY)]
	var out := TDV.typed(Answer.make("point", point(x0, q)), wrongs, "Find the image of P on the graph of y = %s." % fx(s), [given_point(s)], {
		"factorise-inside": ["%s = −(x%s), so %s = f(−(x%s)): a reflection in the y-axis, then a translation by the vector %s." % [inside(s), TC.plus(s, b.neg()), fx(s), TC.plus(s, b.neg()), pt(b, 0)],
			"x-coordinate: %s becomes %s, then %s%s = %s." % [N(p), N(p.neg()), N(p.neg()), TC.plus(s, b), N(x0)], "Only x changes, so the height stays %s." % N(q)],
		"solve-for-image": ["The image is where the input to f is %s: solve %s = %s." % [N(p), inside(s), N(p)],
			"−x = %s, so x = %s." % [N(p.sub(b)), N(x0)], "The height is f(%s) = %s." % [N(p), N(q)]],
	}, s)
	if rep == "graph":
		out.lines = ["The graph of y = f(x) is shown, with the point P%s." % pt(p, q)]
		out.graph = f_with_p(s)
	out.spot = spot(s, R_SIGN)
	return out
