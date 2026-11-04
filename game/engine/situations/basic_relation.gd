class_name BasicRelationSituation
extends RefCounted
## The `basic-relation` situation (curriculum/question-types.json): a relation that may or
## may not be a function, for fn-ext-is-function (FAL-424). An extension type, so always
## Paper 1, and every witness is a small whole number.
##
## generate() returns, by need.kind:
##   graph     a curve: fn (is y a function of x?), then see relation() or rule()
##   mapping   pairs [[in, out]] (need.rep "table": numbers; "words": indices into ctx.names and
##             ctx.items), fn, many, and the witnesses: wx, wy1, wy2 (an input with two outputs),
##             or wa, wb, wy (two inputs sharing an output, where many)
##   equation  an equation `eq`: fn, many, solved (y is the subject) and the witnesses
##   one       a function, one-to-one or not, as a rule or (rep "table") pairs: many, witnesses
##   lines     a vertical line x = a and a horizontal line y = b
##   restrict  a circle, or a parabola or a V on its side, and the half that makes it a
##             function: rel (">=" or "<="), the half y rel k
##
## relation() picks a curve in x and y that fails the vertical line test: form, eq, h, k, r and
## the witness wx, wy1, wy2. rule() picks a function: form, text (after "y = "), many and, for a
## many-to-one one, wa, wb, wy. The checker reads these back from the graph or the text.

const WIN := [-8, 8, -8, 8]
const LOOP := 240
const NOT_FN := ["circle", "side", "vee", "wave"]
const MANY := ["para", "abs", "wave-fn"]
const ONE := ["line", "cubic", "exp", "root"]
## Rules that need more than a sketch: half a parabola and a reciprocal, on a rule's text only.
const ONE_RULES := ["line", "cubic", "exp", "root", "half", "recip"]
const CONTEXTS := [
	{"who": "scavenger", "what": "sector", "rule": "Each scavenger is listed with the sectors they searched",
		"names": ["Ana", "Ben", "Cal", "Dee", "Eli"], "items": ["North", "South", "East", "West", "Dock"]},
	{"who": "student", "what": "club", "rule": "Each student is listed with the clubs they joined",
		"names": ["Fay", "Gus", "Hana", "Ivo", "Jun"], "items": ["Chess", "Radio", "Rowing", "Drama", "Maths"]},
	{"who": "trader", "what": "town", "rule": "Each trader is listed with the towns they visit",
		"names": ["Kim", "Leo", "Mia", "Noor", "Omar"], "items": ["Ashford", "Brine", "Cinder", "Dunmore", "Ember"]},
]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var kind: String = need.get("kind", "graph")
	var rep: String = need.get("rep", "graph")
	var s: Dictionary
	match kind:
		"mapping":
			s = _mapping(rng, rep, rng.chance(0.5), rng.chance(0.7))
		"equation":
			s = _equation(rng)
		"one":
			s = _one(rng, rep)
		"lines":
			s = {"a": ExtensionViews.nonzero(rng, -6, 6), "b": ExtensionViews.nonzero(rng, -6, 6)}
		"restrict":
			s = relation(rng, ["circle", "side", "vee"])
			s.rel = rng.pick([">=", "<="])
		_:
			s = relation(rng, NOT_FN) if rng.chance(0.5) else rule(rng, rng.pick(MANY if rng.chance(0.6) else ONE))
	s.kind = kind
	s.paper = 1
	return s


## "(y − 1)" for k = 1, "y" for k = 0.
static func shifted(letter: String, k: int) -> String:
	return letter if k == 0 else "(%s %s %d)" % [letter, "+" if k < 0 else "−", absi(k)]


## "x + 3", "x − 2", "x", without brackets.
static func plain(letter: String, k: int) -> String:
	return letter if k == 0 else "%s %s %d" % [letter, "+" if k < 0 else "−", absi(k)]


## " + 3", " − 3", or nothing for 0.
static func tail(c: int) -> String:
	return "" if c == 0 else Fmt.plus(c)


static func relation(rng: Seeded, forms: Array) -> Dictionary:
	var form: String = rng.pick(forms)
	var s := {"form": form, "fn": false, "many": false, "h": 0, "k": 0}
	match form:
		"circle":
			var r: int = rng.pick([3, 4, 5])
			var k := rng.int_in(-2, 2)
			var wx: int = rng.pick([0, 3, 4]) if r == 5 else 0
			var w: int = {0: r, 3: 4, 4: 3}[wx]
			s.merge({"r": r, "k": k, "wx": wx, "wy1": k + w, "wy2": k - w, "eq": "x² + %s² = %d" % [shifted("y", k), r * r]}, true)
		"side":
			var h := rng.int_in(-4, 1)
			var k := rng.int_in(-2, 2)
			var w := rng.int_in(1, 2)
			s.merge({"h": h, "k": k, "wx": h + w * w, "wy1": k + w, "wy2": k - w, "eq": "%s² = %s" % [shifted("y", k), plain("x", h)]}, true)
		"vee":
			var h := rng.int_in(-4, 1)
			var k := rng.int_in(-2, 2)
			var w := rng.int_in(1, 3)
			s.merge({"h": h, "k": k, "wx": h + w, "wy1": k + w, "wy2": k - w, "eq": "x = |%s|%s" % [plain("y", k), tail(h)]}, true)
		_:
			var h := rng.int_in(-2, 2)
			s.merge({"h": h, "wx": h, "wy1": 2, "wy2": -2, "eq": "x = y³ − 4y%s" % tail(h)}, true)
	return s


static func rule(rng: Seeded, form: String) -> Dictionary:
	var s := {"form": form, "fn": true, "many": form in MANY}
	match form:
		"para":
			var h := rng.int_in(-2, 2)
			var k := rng.int_in(-4, 1)
			var w := rng.int_in(1, 2)
			s.merge({"h": h, "k": k, "text": Fmt.vertex(1, h, k), "wa": h - w, "wb": h + w, "wy": k + w * w})
		"abs":
			var h := rng.int_in(-2, 2)
			var k := rng.int_in(-4, 1)
			var w := rng.int_in(1, 3)
			s.merge({"h": h, "k": k, "text": "|%s|%s" % [plain("x", h), tail(k)], "wa": h - w, "wb": h + w, "wy": k + w})
		"wave-fn":
			var k := rng.int_in(-3, 3)
			s.merge({"k": k, "text": "x³ − 4x%s" % tail(k), "wa": -2, "wb": 2, "wy": k})
		"line":
			var m: int = rng.pick([2, 3, -2, -3, 1, -1])
			var c := rng.int_in(-4, 4)
			s.merge({"m": m, "c": c, "text": Fmt.poly([m, c])})
		"cubic":
			var c := rng.int_in(-3, 3)
			s.merge({"c": c, "text": "x³%s" % tail(c)})
		"exp":
			var c := rng.int_in(-3, 2)
			s.merge({"c": c, "text": "2^x%s" % tail(c)})
		"root":
			var h := rng.int_in(-4, 0)
			var k := rng.int_in(-3, 2)
			s.merge({"h": h, "k": k, "text": "√(%s)%s" % [plain("x", h), tail(k)]})
		"half":
			var c := rng.int_in(-3, 3)
			s.merge({"c": c, "text": "x²%s, for x ≥ 0" % tail(c)})
		_:
			var k: int = rng.pick([4, 6, 8, -4, -6])
			s.merge({"k": k, "text": "%s/x" % Fmt.num(k)})
	return s


## y at x on a rule, NAN off its domain.
static func y_at(s: Dictionary, x: float) -> float:
	match s.form:
		"para":
			return (x - s.h) * (x - s.h) + s.k
		"abs":
			return absf(x - s.h) + s.k
		"wave-fn":
			return x * x * x - 4.0 * x + s.k
		"line":
			return s.m * x + s.c
		"cubic":
			return x * x * x + s.c
		"exp":
			return pow(2.0, x) + s.c
		"root":
			return sqrt(x - s.h) + s.k if x >= s.h else NAN
		"half":
			return x * x + s.c if x >= 0.0 else NAN
	return s.k / x if x != 0.0 else NAN


## The whole relation as one polyline, or a rule as its pieces, in order along the curve.
static func _loop(s: Dictionary) -> Array:
	var out: Array = []
	for i in LOOP + 1:
		var t := float(i) / LOOP
		match s.form:
			"circle":
				out.append([s.r * cos(TAU * t), s.k + s.r * sin(TAU * t)])
			"side":
				var u := 6.0 * t - 3.0
				out.append([s.h + u * u, s.k + u])
			"vee":
				var u := 10.0 * t - 5.0
				out.append([s.h + absf(u), s.k + u])
			_:
				var y := 5.6 * t - 2.8
				out.append([s.h + y * y * y - 4.0 * y, y])
	return out


## Splits a polyline into the runs inside the window that keep(point) holds on.
static func pieces(pts: Array, keep: Callable) -> Array:
	var out: Array = []
	var run: Array = []
	for p in pts:
		if absf(p[0]) <= 8.0 and absf(p[1]) <= 8.0 and keep.call(p):
			run.append(p)
		else:
			if run.size() > 1:
				out.append(run)
			run = []
	if run.size() > 1:
		out.append(run)
	return out


## The curve's pieces, drawn from the x-values or (for a relation) along the curve.
static func curves(s: Dictionary, keep: Callable = func(_p): return true) -> Array:
	if not s.fn:
		return pieces(_loop(s), keep)
	var y := func(x: float) -> float: return y_at(s, x)
	var out: Array = []
	match s.form:
		"root":
			out = pieces(Plot.sample(y, float(s.h), 8.0), keep)
		"half":
			out = pieces(Plot.sample(y, 0.0, 3.6), keep)
		"recip":
			out = pieces(Plot.sample(y, -8.0, -0.4), keep) + pieces(Plot.sample(y, 0.4, 8.0), keep)
		"exp":
			out = pieces(Plot.sample(y, -8.0, 4.0), keep)
		_:
			out = pieces(Plot.sample(y, -8.0, 8.0), keep)
	return out


static func plot(s: Dictionary, dots: Array = []) -> Dictionary:
	var g := Plot.spec(curves(s), dots, -8, 8, -8, 8)
	g.one_colour = true
	return g


static func card(cs: Array) -> Dictionary:
	var g := GdcKit.card(cs, [], WIN)
	g.one_colour = true
	return g


## Whole-number pairs. In a function every input has one output, and with `many` two inputs
## share one. Otherwise one input gets a second output. The two kinds show the same number of
## pairs, so counting them gives nothing away.
static func _mapping(rng: Seeded, rep: String, fn: bool, many: bool) -> Dictionary:
	var words := rep == "words"
	var inputs: Array = rng.shuffled(range(0, 5) if words else range(-3, 7))
	var outputs: Array = rng.shuffled(range(0, 5) if words else range(0, 10))
	var n := 5 if words else 6
	var xs: Array = inputs.slice(0, n if fn else n - 1)
	var ys: Array = outputs.slice(0, xs.size())
	var s := {"fn": fn, "many": fn and many}
	if s.many:
		ys[1] = ys[0]
		s.merge({"wa": mini(xs[0], xs[1]), "wb": maxi(xs[0], xs[1]), "wy": ys[0]})
	var pairs: Array = []
	for i in xs.size():
		pairs.append([xs[i], ys[i]])
	if not fn:
		var other: int = outputs[n - 1]
		pairs.append([xs[0], other])
		s.merge({"wx": xs[0], "wy1": mini(ys[0], other), "wy2": maxi(ys[0], other), "fx": xs[1], "fy": ys[1]})
	else:
		s.merge({"fx": xs[0], "fy": ys[0], "fy2": ys[2]})
	s.pairs = rng.shuffled(pairs)
	if words:
		s.ctx = rng.pick(CONTEXTS)
	return s


## An equation in x and y: not a function, or a function written with y the subject or not.
static func _equation(rng: Seeded) -> Dictionary:
	if rng.chance(0.5):
		return relation(rng, NOT_FN)
	match rng.int_in(0, 4):
		0:
			var a := rng.int_in(2, 5)
			var b := rng.int_in(2, 5)
			var c := rng.int_in(6, 20)
			return {"form": "lin", "fn": true, "many": false, "solved": false, "eq": "%dx + %dy = %d" % [a, b, c]}
		1:
			var c := rng.int_in(-3, 3)
			return {"form": "cuberoot", "fn": true, "many": false, "solved": false, "eq": "y³ = %s" % plain("x", -c)}
		2:
			var k: int = rng.pick([4, 6, 8, 12])
			return {"form": "prod", "fn": true, "many": false, "solved": false, "eq": "xy = %d" % k}
		3:
			var c := ExtensionViews.nonzero(rng, -4, 4)
			var w := rng.int_in(1, 3)
			return {"form": "minus", "fn": true, "many": true, "solved": false, "eq": "y − x² = %d" % c, "wa": -w, "wb": w, "wy": c + w * w}
	var r := rule(rng, rng.pick(MANY))
	r.solved = true
	r.eq = "y = " + r.text
	return r


## A function, for the one-to-one test. A table has no rule; a graph or an equation has.
static func _one(rng: Seeded, rep: String) -> Dictionary:
	if rep == "table":
		return _mapping(rng, "table", true, rng.chance(0.5))
	if rep == "graph":
		# The four cards of the pick: this right one and three many-to-one curves.
		var s := rule(rng, rng.pick(ONE))
		s.wrongs = [rule(rng, "para"), rule(rng, "abs"), rule(rng, "wave-fn")]
		return s
	var s := rule(rng, rng.pick(MANY if rng.chance(0.5) else ONE_RULES))
	s.eq = "y = " + s.text
	return s


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
