class_name BasicRelationViews
extends ExtensionViews
## The views on the `basic-relation` situation (FAL-424): one builder per unknown of
## fn-ext-is-function. Every answer is a sentence with its reason (the `choice` kind), which
## the checker tests against the relation it reads back, or a graph to pick: "which function
## is one-to-one" and "which half is a function" play as pick-the-graph on their graph cells
## with the vertical or horizontal line test.
##
## A wrong sentence is wrong in what it says, never only in its reason: "Not a function: x = 1
## and x = −1 both give y = 3" is true about the two inputs but false in its verdict, while a
## sentence with the right verdict quotes a witness that isn't on the relation.

const R_MANY := "SL2.2.is-function#0"
const R_HORIZONTAL := "SL2.2.is-function#1"
const R_VERTICAL := "SL2.2.is-function#2"
const VERT := "every vertical line crosses it at most once"
const HORIZ := "every horizontal line crosses it at most once, so it has an inverse"


func needs() -> Dictionary:
	return {
		"from-graph": {"kind": "graph"},
		"from-mapping": {"kind": "mapping"},
		"from-equation": {"kind": "equation"},
		"one-to-one": {"kind": "one"},
		"vertical-line": {"kind": "lines"},
		"make-it-a-function": {"kind": "restrict"},
	}


## one-to-one and make-it-a-function have a pick-the-graph cell, which can't be reworded as a
## student's claim, so they keep to their own formats.
func extra() -> Dictionary:
	return {"from-graph": ["true-false-reason"], "from-mapping": ["true-false-reason"],
		"from-equation": ["true-false-reason"], "vertical-line": ["true-false-reason"]}


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	var own: Dictionary = out.get("given", {}) if out.get("given") != null else {}
	out.given = BasicRelationSituation.export(s)
	out.given.merge(ExtensionViews.export(own), true)
	return out


# ── Helpers ──────────────────────────────────────────────────

## The sentence answer with its options in a seeded order, so the first isn't always right.
static func sentence(right: String, bad: Array, plain: Array, rng: Seeded) -> Dictionary:
	var c := BasicFunctionViews.choose(right, bad, plain)
	var opts: Array = c.answer.fixed.options
	var mixed := rng.shuffled(opts)
	opts.clear()
	opts.append_array(mixed)
	return c


static func tag(text: String, ref: String) -> Dictionary:
	return BasicFunctionViews.tag(text, ref)


static func gives(x: int, y1: int, y2: int) -> String:
	return "x = %s gives y = %s and y = %s" % [N(x), N(y1), N(y2)]


static func both(a: int, b: int, y: int) -> String:
	return "x = %s and x = %s both give y = %s" % [N(a), N(b), N(y)]


## A witness that isn't on the relation: two outputs one step further out than the real pair.
static func false_gives(s: Dictionary) -> String:
	if s.has("wx"):
		return gives(s.wx, s.wy1 + 1, s.wy2 - 1)
	return gives(1, 3, 5)


## The steps of the test: what the line meets, then the verdict in words.
static func not_fn_steps(s: Dictionary) -> Array:
	return ["Take the input x = %s" % N(s.wx), "It has two outputs, y = %s and y = %s, so one input has two outputs" % [N(s.wy1), N(s.wy2)]]


static func many_note(s: Dictionary) -> String:
	return "Two inputs may share an output: %s is many-to-one, which is still a function" % both(s.wa, s.wb, s.wy) if s.many else "No input has a second output"


# ── Function or not ──────────────────────────────────────────

func u_from_graph(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var right: String
	var c: Dictionary
	var steps: Array
	var yes := "A function: " + VERT
	if not s.fn:
		right = "Not a function: " + gives(s.wx, s.wy1, s.wy2)
		c = sentence(right, [tag("A function: no horizontal line crosses it twice", R_HORIZONTAL)], [yes, "Not a function: " + false_gives(s)], rng)
		steps = ["Draw the vertical line x = %s" % N(s.wx), "It crosses the curve at y = %s and y = %s, so one input has two outputs" % [N(s.wy1), N(s.wy2)]]
	else:
		right = yes
		var fake := "Not a function: " + gives(1, 3, 5)
		var bad: Array = []
		if s.many:
			bad = [tag("Not a function: " + both(s.wa, s.wb, s.wy), R_MANY), tag("Not a function: a horizontal line crosses it twice", R_HORIZONTAL)]
		c = sentence(right, bad, [fake, "Not a function: some vertical line crosses it twice", "Not a function: it has no turning point"], rng)
		steps = ["Slide a vertical line across the graph: it never crosses the curve twice", many_note(s)]
	var out := {"asked": "Is y a function of x? Give the reason.", "lines": ["The graph shows a relation between x and y."], "graph": BasicRelationSituation.plot(s)}
	out.merge(c)
	out.methods = BasicFunctionViews.ways({"vertical-line-test": steps}, "So: %s." % right, out.answer)
	return out


func u_from_equation(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var right: String
	var c: Dictionary
	var steps: Array
	var yes := "Yes: no x gives two values of y"
	if not s.fn:
		right = "No: " + gives(s.wx, s.wy1, s.wy2)
		c = sentence(right, [], [yes, "No: " + false_gives(s), "Yes: y is on one side of the equation"], rng)
		steps = ["Put x = %s into %s" % [N(s.wx), s.eq], "Solve for y: y = %s or y = %s, two outputs for one input" % [N(s.wy1), N(s.wy2)]]
	else:
		right = yes
		var bad: Array = []
		if s.many:
			bad = [tag("No: " + both(s.wa, s.wb, s.wy), R_MANY)]
		var plain: Array = ["No: " + gives(1, 3, 5), "No: some x gives two values of y"]
		if not s.solved:
			plain.append("No: y is not the subject")
		c = sentence(right, bad, plain, rng)
		var solve := "Rearrange %s for y: there is no ± in it" % s.eq
		steps = [solve, "No x gives two values of y" + ("; two inputs may share an output, which is still a function" if s.many else "")]
	var out := {"asked": "Is y a function of x? Give the reason.", "lines": [s.eq]}
	out.merge(c)
	out.methods = BasicFunctionViews.ways({"solve-for-y": steps}, "So: %s." % right, out.answer)
	return out


## The pairs as a line of words, each name with its items: "Ana: North and Dock."
static func listing(s: Dictionary) -> String:
	var by := {}
	var order: Array = []
	for p in s.pairs:
		if not by.has(p[0]):
			by[p[0]] = []
			order.append(p[0])
		by[p[0]].append(s.ctx.items[p[1]])
	var parts: PackedStringArray = []
	for x in order:
		parts.append("%s: %s." % [s.ctx.names[x], " and ".join(PackedStringArray(by[x]))])
	return " ".join(parts)


static func pairs_table(s: Dictionary) -> Dictionary:
	return {"rows": [["x", s.pairs.map(func(p): return N(p[0]))], ["y", s.pairs.map(func(p): return N(p[1]))]]}


func u_from_mapping(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var words := rep == "words"
	var nm := func(x: int) -> String: return s.ctx.names[x] if words else "x = " + N(x)
	var it := func(y: int) -> String: return s.ctx.items[y] if words else N(y)
	var two := func(x: int, a: int, b: int) -> String:
		return "Not a function: %s has two outputs, %s and %s" % [nm.call(x), it.call(a), it.call(b)]
	var yes: String = "A function: each %s has one output" % (s.ctx.who if words else "x")
	var right: String
	var c: Dictionary
	var steps: Array
	if not s.fn:
		right = two.call(s.wx, s.wy1, s.wy2)
		c = sentence(right, [], [yes, two.call(s.fx, s.fy, s.wy1 if s.wy1 != s.fy else s.wy2), "A function: every input in the list has an output"], rng)
		steps = ["Go through the inputs one at a time", "%s appears with %s and with %s, so one input has two outputs" % [nm.call(s.wx), it.call(s.wy1), it.call(s.wy2)]]
	else:
		right = yes
		var bad: Array = []
		if s.many:
			bad = [tag("Not a function: %s and %s share the output %s" % [nm.call(s.wa), nm.call(s.wb), it.call(s.wy)], R_MANY)]
		c = sentence(right, bad, [two.call(s.fx, s.fy, s.fy2), "Not a function: the inputs are not in order", "Not a function: an output is missing"], rng)
		steps = ["Go through the inputs one at a time: each appears once, with one output",
			"Two inputs may share an output, which is still a function" if s.many else "No input appears with a second output"]
	var out := {}
	if words:
		out.asked = "Taking each %s as the input and each %s as the output, is this a function?" % [s.ctx.who, s.ctx.what]
		out.lines = [s.ctx.rule + ":", listing(s)]
	else:
		out.asked = "Is y a function of x? If not, name an input with two outputs."
		out.lines = ["The table lists the pairs of a relation."]
		out.table = pairs_table(s)
	out.merge(c)
	out.methods = BasicFunctionViews.ways({"mapping-check": steps}, "So: %s." % right, out.answer)
	return out


# ── One-to-one ───────────────────────────────────────────────

func u_one_to_one(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	if rep == "graph":
		return _one_pick(s, rng)
	var no: String = "No: %s, so it has no inverse" % both(s.wa, s.wb, s.wy) if s.many else ""
	var yes := "Yes: " + HORIZ
	var right: String
	var c: Dictionary
	var steps: Array
	var bad_many := tag("No: it is not a function, so it has no inverse", R_MANY)
	if s.many:
		right = no
		c = sentence(right, [bad_many], [yes, "Yes: each input has one output, so it has an inverse", "No: %s, so it has no inverse" % both(s.wa, s.wb + 1, s.wy)], rng)
		steps = ["Find two inputs with one output: %s" % both(s.wa, s.wb, s.wy), "So the horizontal line y = %s crosses it twice, and undoing f would give two answers" % N(s.wy)]
	else:
		right = yes
		c = sentence(right, [], ["No: %s, so it has no inverse" % both(1, -1, 3), "No: it is not a function, so it has no inverse", "No: some horizontal line crosses it twice, so it has no inverse"], rng)
		steps = ["Check the outputs: no output comes from two inputs", "So no horizontal line crosses it twice, and undoing f gives one answer"]
	var out := {"asked": "f is a function. Is it one-to-one, so that it has an inverse?"}
	if rep == "table":
		out.lines = ["The table gives values of the function f."]
		out.table = pairs_table(s)
	else:
		out.lines = [s.eq]
	out.merge(c)
	out.methods = BasicFunctionViews.ways({"horizontal-line-test": steps}, "So: %s." % right, out.answer)
	return out


func _one_pick(s: Dictionary, rng: Seeded) -> Dictionary:
	var wrongs: Array = s.wrongs.map(func(w): return {"graph": BasicRelationSituation.card(BasicRelationSituation.curves(w)), "ref": "", "mistake": "many-to-one",
		"why": "%s, so it is not one-to-one" % both(w.wa, w.wb, w.wy)})
	var picked := GdcKit.pick(BasicRelationSituation.card(BasicRelationSituation.curves(s)), wrongs, rng)
	var out := {"asked": "Which graph shows a one-to-one function, so that it has an inverse?", "lines": ["Each graph shows a function."], "answer": picked.answer, "graphs": picked.graphs}
	out.methods = BasicFunctionViews.ways({"horizontal-line-test": ["Slide a horizontal line up each graph: a many-to-one curve is crossed twice somewhere", "Only %s is never crossed twice" % picked.letter]},
		"So %s." % picked.letter, picked.answer)
	return out


# ── Vertical and horizontal lines ────────────────────────────

func u_vertical_line(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var say := func(xf: bool, yf: bool) -> String:
		return "x = %s %s; y = %s %s" % [N(a), "is a function" if xf else "is not a function", N(b), "is a function" if yf else "is not a function"]
	var right: String = say.call(false, true)
	var c := sentence(right, [tag(say.call(true, true), R_VERTICAL), tag(say.call(true, false), R_VERTICAL), tag(say.call(false, false), R_HORIZONTAL)], [], rng)
	var out := {"asked": "Is each line a function, with x as the input?"}
	if rep == "graph":
		out.lines = ["The graph shows the lines x = %s and y = %s." % [N(a), N(b)]]
		var g := Plot.spec([[[float(a), -8.0], [float(a), 8.0]], [[-8.0, float(b)], [8.0, float(b)]]], [], -8, 8, -8, 8)
		g.one_colour = true
		out.graph = g
	else:
		out.lines = ["Two lines: x = %s and y = %s." % [N(a), N(b)]]
	out.merge(c)
	out.methods = BasicFunctionViews.ways({"vertical-line-test": ["x = %s: the one input %s has every y as an output, so a vertical line lies along it" % [N(a), N(a)],
		"y = %s: every input has the one output %s, so a vertical line crosses it once" % [N(b), N(b)]]}, "So: %s." % right, out.answer)
	return out


# ── A restriction that makes it a function ───────────────────

static func half_text(s: Dictionary) -> String:
	return "y %s %s" % ["≥" if s.rel == ">=" else "≤", N(s.k)]


## The curve's halves and pieces, for the pick: what each keeps.
static func keep_half(s: Dictionary) -> Callable:
	var up: bool = s.rel == ">="
	var k: float = s.k
	return func(p): return p[1] >= k if up else p[1] <= k


## The two cuts in x that leave inputs with two outputs: [where, "x ≥ …", "x ≤ …"].
static func x_side(s: Dictionary) -> Array:
	var cut: int = 0 if s.form == "circle" else s.h + 1
	return [cut, "x ≥ %s" % N(cut), "x ≤ %s" % N(cut)]


## y = k ± the rest, the relation solved for y.
static func solved(s: Dictionary) -> String:
	var rest: String
	match s.form:
		"circle":
			rest = "√(%d − x²)" % (s.r * s.r)
		"side":
			rest = "√%s" % BasicRelationSituation.shifted("x", s.h)
		_:
			rest = BasicRelationSituation.shifted("x", s.h)
	return "y = %s± %s" % ["" if s.k == 0 else N(s.k) + " ", rest]


func u_make_it_a_function(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	if rep == "graph" and angle == "vertical-line-test":
		return _restrict_pick(s, rng)
	var half := half_text(s)
	var k: int = s.k
	var side := x_side(s)
	var out := {"asked": "Which restriction makes this relation a function?", "lines": ["Relation: %s" % s.eq]}
	if rep == "graph":
		out.lines = ["The graph shows the relation %s." % s.eq]
		out.graph = BasicRelationSituation.plot(s)
	var right := "Keep only " + half
	out.merge(sentence(right, [], ["Keep only %s" % side[1], "Keep only %s" % side[2], "Keep only %s ≤ y ≤ %s" % [N(k - 1), N(k + 1)], "Keep only y ≠ %s" % N(k)], rng))
	out.methods = BasicFunctionViews.ways({
		"vertical-line-test": ["A vertical line crosses the curve twice: at y = %s and y = %s when x = %s" % [N(s.wy1), N(s.wy2), N(s.wx)], "The part with %s is cut once by every vertical line" % half],
		"solve-for-y": ["Solve for y: %s, two outputs for one input" % solved(s), "Taking only the %s sign gives %s, one output for each input" % ["+" if s.rel == ">=" else "−", half]]}, "So: %s." % right, out.answer)
	return out


func _restrict_pick(s: Dictionary, rng: Seeded) -> Dictionary:
	var cut: float = x_side(s)[0]
	var k: float = s.k
	# Wide enough to see both pieces: near a circle's widest point a thin band is nearly upright.
	var width: float = s.r - 1.0 if s.form == "circle" else 2.0
	var mk := func(keep: Callable) -> Dictionary: return BasicRelationSituation.card(BasicRelationSituation.curves(s, keep))
	var wrongs := [
		{"graph": mk.call(func(_p): return true), "ref": "", "mistake": "whole", "why": "this is the whole relation, with nothing taken away"},
		{"graph": mk.call(func(p): return p[0] >= cut), "ref": "", "mistake": "x-half", "why": "cutting x leaves inputs with two outputs"},
		{"graph": mk.call(func(p): return absf(p[1] - k) <= width), "ref": "", "mistake": "band", "why": "a band round the middle still has inputs with two outputs"},
	]
	var picked := GdcKit.pick(mk.call(keep_half(s)), wrongs, rng)
	var out := {"asked": "Which graph shows a part of this relation that is a function?", "lines": ["The graph shows the relation %s." % s.eq],
		"graph": BasicRelationSituation.plot(s), "answer": picked.answer, "graphs": picked.graphs}
	out.methods = BasicFunctionViews.ways({"vertical-line-test": ["Try a vertical line on each graph", "Only %s is never crossed twice: it keeps %s" % [picked.letter, half_text(s)]],
		"solve-for-y": ["Solve for y: %s, two outputs for one input" % solved(s), "Keeping one sign gives %s, which is %s" % [half_text(s), picked.letter]]}, "So %s." % picked.letter, picked.answer)
	return out
