class_name AiVariationViews
extends ExtensionViews
## The views on the `ai-variation` situation (FAL-1001): one builder per unknown of
## fn-ai-variation-model (AI-SL2.5.variation-model, AI-SL2.6.find-parameters). A variation in
## words ("is inversely proportional to the square of") or as y = axⁿ with a to find, with one
## pair: the constant a (from the words or a table of two pairs), a prediction, an input from an
## output, the factor on the output when the input is scaled, the asymptotes of y = a/xⁿ (from
## the equation or its graph), the inputs past a threshold (in words or on a graph with the
## line drawn), the least whole-number input within a limit, and which of four graphs is the
## model (pick the graph).
##
## Every question is Paper 2, as every AI paper allows a GDC. A value is to 3 s.f. with the
## rounding trap unless it ends in 3 figures or fewer; a, a scale factor and a whole number are
## exact. The asymptotes are a picked `claim`. `given` holds the situation as plain data.

const VM := "AI-SL2.5.variation-model#"
const OWN := "fn-ai-variation-model#"
const R_SQUARE := VM + "0"
const R_MINUS := VM + "1"
const R_ONLY_Y := VM + "2"
const R_CUBE := VM + "3"
const R_POWER := OWN + "4"
const R_DIRECT := OWN + "5"
const R_REVERSED := OWN + "6"
const R_NEAREST := OWN + "7"
const R_GRAPH := OWN + "8"
const S := preload("res://engine/situations/ai_variation.gd")

const UNKNOWNS := ["find-constant", "predict", "input-from-output", "scale-factor", "asymptotes", "threshold-range",
	"least-whole-number", "pick-graph"]
## A slip's name in the recipe -> its misconception.
const REFS := {"power": R_POWER, "minus": R_MINUS, "direct": R_DIRECT, "square": R_SQUARE, "cube": R_CUBE,
	"reversed": R_REVERSED, "nearest": R_NEAREST}
const CHANGE := {"2": "doubled", "3": "tripled", "0.5": "halved", "4": "multiplied by 4"}
const ASYMPTOTES := "x = 0 and y = 0"


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## Every AI paper allows a GDC: every cell is Paper 2.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = S.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## A GDC's screen: 6 significant figures.
static func W(x: Variant) -> String:
	return Fmt.work(x, 6)


## An exact value as the working writes it: as a decimal when it ends, else to 6 s.f.
static func E(v: Q) -> String:
	return D(v) if not D(v).contains("/") else W(v)


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func C(s: Dictionary) -> Dictionary:
	return S.CONTEXTS[s.ctx]


static func X(s: Dictionary) -> String:
	return C(s).x


static func Y(s: Dictionary) -> String:
	return C(s).y


## A number to a power as the working writes it: "4²", "2.5³", "6" for a power of 1.
static func pw(base: String, n: int) -> String:
	return base + Fmt.sup(absi(n))


## y = axⁿ with a as given ("a" or a number): "P = 0.6v³", "I = 900/d²", "T = a/w".
static func model(s: Dictionary, a: String, x: String = "", y: String = "") -> String:
	var xs := X(s) if x == "" else x
	var ys := Y(s) if y == "" else y
	if s.n < 0:
		return "%s = %s/%s" % [ys, a, pw(xs, s.n)]
	return "%s = %s%s" % [ys, "" if a == "1" else a, pw(xs, s.n)]


## The right side of the model at a number: "900/8²", "0.6 × 5³".
static func at(s: Dictionary, a: String, x: String) -> String:
	if s.n < 0:
		return "%s/%s" % [a, pw(x, s.n)]
	return "%s × %s" % [a, pw(x, s.n)]


static func story(s: Dictionary) -> String:
	return "%s %s %s." % [C(s).ylong, S.PHRASE[s.n], C(s).xlong]


static func pair_line(s: Dictionary) -> String:
	return "When %s = %s, %s = %s." % [X(s), D(s.x1), Y(s), D(s.y1)]


## The model with a to find, in place of the words.
static func model_line(s: Dictionary) -> String:
	return "%s is modelled by %s, where a is a constant and %s." % [C(s).ylong, model(s, "a"), C(s).xdef]


## The constant from the pair: "I = a/d², so a = I × d² = 56.25 × 4² = 900."
static func a_line(s: Dictionary, x1: Q = null, y1: Q = null) -> String:
	var xq: Q = s.x1 if x1 == null else x1
	var yq: Q = s.y1 if y1 == null else y1
	var a: Q = yq.mul(S.qpow(xq, -s.n))
	if s.n < 0:
		return "%s, so a = %s × %s = %s × %s = %s." % [model(s, "a"), Y(s), pw(X(s), s.n), D(yq), pw(D(xq), s.n), D(a)]
	return "%s, so a = %s ÷ %s = %s ÷ %s = %s." % [model(s, "a"), Y(s), pw(X(s), s.n), D(yq), pw(D(xq), s.n), D(a)]


## Solving a·xⁿ = v for x, by hand: "d² = 900 ÷ 20 = 45, so d = √45 = 6.70820".
static func solve_line(s: Dictionary, v: Q, x: float) -> String:
	var xs := X(s)
	var a := D(s.a)
	var vs := D(v)
	match s.n:
		1:
			return "%s = %s ÷ %s = %s" % [xs, vs, a, W(x)]
		-1:
			return "%s = %s ÷ %s = %s" % [xs, a, vs, W(x)]
		2:
			var q1 := v.to_float() / s.a.to_float()
			return "%s² = %s ÷ %s = %s, so %s = √%s = %s" % [xs, vs, a, W(q1), xs, W(q1), W(x)]
		3:
			var q3 := v.to_float() / s.a.to_float()
			return "%s³ = %s ÷ %s = %s, so %s = %s^(1/3) = %s" % [xs, vs, a, W(q3), xs, W(q3), W(x)]
	var q2 := s.a.to_float() / v.to_float()
	return "%s² = %s ÷ %s = %s, so %s = √%s = %s" % [xs, a, vs, W(q2), xs, W(q2), W(x)]


static func num_ans(label: String, v: Q, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label, unit)
	if Answer.needs_rounding(v):
		ans.show = "sf"
	else:
		ans.show = "dec"
		ans.exact = true
	return ans


static func exact_ans(label: String, v: Q, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label, unit)
	ans.show = "dec"
	ans.exact = true
	return ans


## A value for an option beside the answer: exact (as it is when it ends, else to 3 s.f.) or to 3 s.f.
static func opt(ans: Dictionary, v: Variant) -> Dictionary:
	if ans.get("exact", false):
		var q: Q = v if v is Q else GdcKit.qf(v)
		return {"v": q if not D(q).contains("/") else GraphReadingSituation.sf_q(q, 3)}
	return {"v": v if v is Q else GdcKit.qf(v)}


static func slips_to_wrongs(ans: Dictionary, slips: Array, rng: Seeded) -> Array:
	var out: Array = []
	for p in slips:
		if p[1] != "":
			out.append(wrong(opt(ans, p[0]), REFS[p[1]]))
	return rng.shuffled(out)


static func pack(lines: Array, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary,
		graph: Variant = null, table: Variant = null) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {},
		"graph": graph, "table": table}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


# ── Figures ──────────────────────────────────────────────────
## y = c·xᵐ sampled on [lo, hi] for x > 0, kept to the part with y from 0 to top (and a little past).
static func branch(c: float, m: int, lo: float, hi: float, top: float) -> Array:
	var from := lo
	if m < 0:
		from = maxf(lo, pow(c / (top * 1.05), 1.0 / -m))
	var to := hi
	if m > 0:
		to = minf(hi, pow(top * 1.05 / c, 1.0 / m))
	return GdcKit.curve(func(x): return c * pow(x, m), from, to)


# ── The constant ─────────────────────────────────────────────

func u_find_constant(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := exact_ans("a = ", s.a)
	var wr := slips_to_wrongs(ans, S.constant_slips(s), rng)
	var fill: Array = S.constant_fillers(s).map(func(v): return opt(ans, v))
	var lines: Array = [story(s)]
	var table: Variant = null
	var first := "%s %s %s, so %s." % [Y(s), S.PHRASE[s.n], X(s), model(s, "a")]
	var steps: Array
	if rep == "table":
		lines.append("The table gives two pairs of values of %s and %s." % [X(s), Y(s)])
		table = {"rows": [[X(s), [D(s.x1), D(s.x1b)]], [Y(s), [D(s.y1), D(s.y1b)]]]}
		var check := "Check with the other pair: %s = %s, as in the table." % [at(s, D(s.a), D(s.x1b)), D(s.y1b)]
		steps = [first, "Use the pair %s = %s, %s = %s: %s" % [X(s), D(s.x1), Y(s), D(s.y1), a_line(s)], check, say(ans)]
	else:
		lines.append(pair_line(s))
		steps = [first, a_line(s), say(ans)]
	var asked := "Write the variation as an equation in %s, %s and a constant a, and find the value of a." % [Y(s), X(s)]
	return pack(lines, asked, ans, wr, fill, {"find-a": steps}, null, table)


# ── A prediction ─────────────────────────────────────────────

static func k_power(k: Q, n: int) -> String:
	var kt := D(k)
	if n < 0:
		return "1/" + pw(kt, n)
	return pw(kt, n)


func u_predict(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := num_ans("%s = " % Y(s), s.y2, C(s).yu)
	var wr := slips_to_wrongs(ans, S.predict_slips(s), rng)
	var fill: Array = S.predict_fillers(s).map(func(v): return opt(ans, v))
	var lines: Array = [story(s), pair_line(s)] if rep == "words" else [model_line(s), pair_line(s)]
	var asked := "Find %s when %s = %s." % [Y(s), X(s), D(s.x2)]
	var fk: Q = S.qpow(s.k, s.n)
	var steps := {
		"find-a": [a_line(s), "At %s = %s: %s = %s = %s" % [X(s), D(s.x2), Y(s), at(s, D(s.a), D(s.x2)), E(s.y2)], say(ans)],
		"scale-factor": ["%s goes from %s to %s, so it is multiplied by %s ÷ %s = %s." % [X(s), D(s.x1), D(s.x2), D(s.x2), D(s.x1), D(s.k)],
			"%s, so %s is multiplied by %s = %s." % [model(s, "a"), Y(s), k_power(s.k, s.n), D(fk)],
			"%s = %s × %s = %s" % [Y(s), D(s.y1), D(fk), E(s.y2)], say(ans)],
	}
	return pack(lines, asked, ans, wr, fill, steps)


# ── An input from an output ──────────────────────────────────

func u_input_from_output(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := num_ans("%s = " % X(s), GdcKit.qf(s.X), C(s).xu)
	var wr := slips_to_wrongs(ans, S.input_slips(s), rng)
	var fill: Array = S.input_fillers(s).map(func(v): return opt(ans, v))
	var lines: Array = [story(s), pair_line(s)] if rep == "words" else [model_line(s), pair_line(s)]
	var asked := "Find %s when %s = %s." % [X(s), Y(s), D(s.Y)]
	var steps := {
		"find-a": [a_line(s), "Solve %s = %s: %s." % [at(s, D(s.a), X(s)), D(s.Y), solve_line(s, s.Y, s.X)], say(ans)],
		"gdc-graph": [a_line(s), "Graph %s and %s = %s for %s > 0, and find where they meet: %s = %s." % [model(s, D(s.a), "x", "y"), "y", D(s.Y), "x", "x", W(s.X)],
			say(ans)],
	}
	return pack(lines, asked, ans, wr, fill, steps)


# ── The scale factor ─────────────────────────────────────────

func u_scale_factor(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := exact_ans("factor = ", s.f)
	var wr: Array = []
	for p in S.scale_slips(s):
		if p[1] != "":
			wr.append(wrong({"v": p[0]}, REFS[p[1]]))
	wr = rng.shuffled(wr)
	var fill: Array = S.scale_fillers(s).map(func(v): return {"v": v})
	var lines: Array = [story(s), "The %s is %s." % [C(s).xname, CHANGE[D(s.k)]]]
	var asked := "Find the factor by which the %s is multiplied." % C(s).yname
	var kn := "1/k" + Fmt.sup(-s.n) if s.n < 0 else "k" + Fmt.sup(s.n)
	var steps := {
		"scale-factor": ["%s, so when %s is multiplied by k, %s is multiplied by %s." % [model(s, "a"), X(s), Y(s), kn],
			"Here k = %s, so the factor is %s = %s." % [D(s.k), k_power(s.k, s.n), D(s.f)], say(ans)],
	}
	return pack(lines, asked, ans, wr, fill, steps)


# ── Asymptotes ───────────────────────────────────────────────

static func pure(s: Dictionary) -> String:
	return "y = %s/%s" % [D(s.a), pw("x", s.n)]


## y = a/xᵏ for x ≠ 0, both branches, with the given point marked.
static func asymptote_graph(s: Dictionary) -> Dictionary:
	var a: float = s.a.to_float()
	var x1: float = s.x1.to_float()
	var y1: float = s.y1.to_float()
	var xw := ceili(x1 * 3.0)
	var yw := ceili(maxf(y1 * 2.5, 4.0))
	var right := branch(a, s.n, 0.0, float(xw), float(yw))
	var left: Array = []
	for p in right:
		left.push_front([-p[0], p[1] if s.n == -2 else -p[1]])
	var y0 := -yw if s.n == -1 else -maxi(1, roundi(yw * 0.1))
	var g := Plot.spec([left, right], [[x1, y1, "(%s, %s)" % [D(s.x1), D(s.y1)]]], -xw, xw, y0, yw)
	g.one_colour = true
	return g


func u_asymptotes(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var built := SamplingViews.claims(ASYMPTOTES, [
		["y = 0 only", R_ONLY_Y],
		["x = 0 only", ""],
		["x = 0 and y = %s" % D(s.a), ""]])
	var lines: Array
	var graph: Variant = null
	var first: Array = []
	var curve := pure(s)
	if rep == "graph":
		lines = ["The graph of y = a/%s, where a is a constant, passes through the point (%s, %s), as shown." % [pw("x", s.n), D(s.x1), D(s.y1)]]
		graph = asymptote_graph(s)
		first = ["The curve passes through (%s, %s), so a = %s × %s = %s and %s." % [D(s.x1), D(s.y1), D(s.y1), pw(D(s.x1), s.n), D(s.a), curve]]
	else:
		lines = ["A model is %s, for x ≠ 0." % curve]
	var asked := "Write down the equations of the asymptotes of the graph."
	var steps: Array = first + [
		"Graph %s on the GDC. It has no value at x = 0, as that divides by zero: near x = 0 the curve runs off the screen beside the y-axis, so x = 0 is a vertical asymptote." % curve,
		"As x gets large, y = %s gets closer and closer to 0 but never reaches it, so y = 0 is a horizontal asymptote." % at(s, D(s.a), "x"),
		"So the asymptotes are " + ASYMPTOTES + "."]
	return pack(lines, asked, built.answer, built.wrongs, built.fillers, {"gdc-graph": steps}, graph)


# ── Inputs past a threshold ──────────────────────────────────

static func threshold_graph(s: Dictionary) -> Dictionary:
	var x1: float = s.x1.to_float()
	var y1: float = s.y1.to_float()
	var T: float = s.T.to_float()
	var xw := ceili(maxf(x1, s.b) * 1.6)
	var yw := ceili(maxf(y1, T) * 1.6)
	var curve := branch(s.a.to_float(), s.n, xw / 400.0, float(xw), float(yw))
	var g := Plot.spec([curve], [[x1, y1, "(%s, %s)" % [D(s.x1), D(s.y1)]]], 0, xw, 0, yw, [[T, "%s = %s" % [Y(s), D(s.T)]]])
	g.x_name = X(s)
	g.y_name = Y(s)
	return g


static func grows(s: Dictionary) -> String:
	return "rises" if s.n > 0 else "falls"


func u_threshold_range(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := Answer.make("bound", {"rel": s.rel, "v": GdcKit.qf(s.b)}, {"var": X(s)})
	ans.show = "sf"
	var wr: Array = []
	for p in S.threshold_slips(s):
		if p[2] != "":
			wr.append(wrong({"rel": p[1], "v": GdcKit.qf(p[0])}, REFS[p[2]]))
	wr = rng.shuffled(wr)
	var fill: Array = S.threshold_fillers(s).map(func(p): return {"rel": p[1], "v": GdcKit.qf(p[0])})
	var sign := ">" if s.above else "<"
	var lines: Array = [story(s), pair_line(s)]
	var graph: Variant = null
	if rep == "graph":
		lines = [story(s), "The graph shows %s against %s for %s > 0. It passes through (%s, %s), and the line %s = %s is drawn." % [Y(s), X(s), X(s), D(s.x1), D(s.y1), Y(s), D(s.T)]]
		graph = threshold_graph(s)
	var asked := "Find the set of values of %s > 0 for which %s %s %s." % [X(s), Y(s), sign, D(s.T)]
	var B := W(s.b)
	var then := "%s %s as %s grows, so %s %s %s for %s %s %s." % [Y(s), grows(s), X(s), Y(s), sign, D(s.T), X(s), s.rel, B]
	var side := "above" if s.above else "below"
	var where := "to the right of" if s.rel == ">" else "to the left of"
	var steps := {
		"find-a": [a_line(s), "Solve %s = %s: %s." % [at(s, D(s.a), X(s)), D(s.T), solve_line(s, s.T, s.b)], then, say(ans)],
		"gdc-graph": [a_line(s), "Graph %s and %s = %s for %s > 0: they meet at %s = %s." % [model(s, D(s.a)), Y(s), D(s.T), X(s), X(s), B],
			"The curve is %s the line %s that point, so %s %s %s for %s %s %s." % [side, where, Y(s), sign, D(s.T), X(s), s.rel, B], say(ans)],
	}
	return pack(lines, asked, ans, wr, fill, steps, graph)


# ── The least whole number ───────────────────────────────────

func u_least_whole_number(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := exact_ans("%s = " % X(s), Q.new(s.m))
	var wr: Array = []
	for p in S.least_slips(s):
		if p[1] != "":
			wr.append(wrong({"v": Q.new(p[0])}, REFS[p[1]]))
	wr = rng.shuffled(wr)
	var fill: Array = S.least_fillers(s).map(func(w): return {"v": Q.new(w)})
	var rel := "≤" if s.n < 0 else "≥"
	var asked := "Find the least whole-number value of %s for which %s %s %s." % [X(s), Y(s), rel, D(s.L)]
	var B := W(s.b)
	var lo := floori(s.b)
	var y_lo := S.power_at(s.a.to_float(), s.n, lo)
	var y_hi := S.power_at(s.a.to_float(), s.n, s.m)
	var steps := {
		"find-a": [a_line(s), "Solve %s = %s: %s." % [at(s, D(s.a), X(s)), D(s.L), solve_line(s, s.L, s.b)],
			"%s %s as %s grows, so %s %s %s needs %s ≥ %s: the next whole number up is %d." % [Y(s), grows(s), X(s), Y(s), rel, D(s.L), X(s), B, s.m],
			say(ans)],
		"gdc-graph": [a_line(s), "Graph %s and %s = %s: they meet at %s = %s." % [model(s, D(s.a)), Y(s), D(s.L), X(s), B],
			"The table of values gives %s = %s at %s = %d, which fails, and %s = %s at %s = %d, which works." % [Y(s), W(y_lo), X(s), lo, Y(s), W(y_hi), X(s), s.m],
			say(ans)],
	}
	return pack([story(s), pair_line(s)], asked, ans, wr, fill, steps)


# ── Pick the graph ───────────────────────────────────────────

func u_pick_graph(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var x1: float = s.x1.to_float()
	var y1: float = s.y1.to_float()
	var xw := ceili(x1 * 2.5)
	var yw := ceili(y1 * 3.0)
	var win := [0, xw, 0, yw]
	var card := func(cd: Dictionary) -> Dictionary:
		var curve: Array
		if cd.get("minus", false):
			curve = GdcKit.curve(func(x): return cd.c - x, xw / 400.0, minf(float(xw), cd.c))
		else:
			curve = branch(cd.c, cd.m, xw / 400.0, float(xw), float(yw))
		var g := GdcKit.card([curve], [[x1, y1, ""]], win)
		g.x_name = X(s)
		g.y_name = Y(s)
		return g
	var right: Dictionary
	var wrongs: Array = []
	var law := "inverse" if s.n < 0 else "direct"
	for cd in s.cards:
		match cd.role:
			"right":
				right = card.call(cd)
			"power":
				wrongs.append({"graph": card.call(cd), "mistake": "power", "ref": R_GRAPH,
						"why": "it passes through the point but has the wrong power: %s" % power_model(s, cd.m)})
			"line":
				wrongs.append({"graph": card.call(cd), "mistake": "line", "ref": R_GRAPH,
					"why": "it is a straight line through the origin and the point, so %s would be proportional to %s itself" % [Y(s), X(s)]})
			"direct":
				wrongs.append({"graph": card.call(cd), "mistake": "direct", "ref": R_DIRECT,
					"why": "it rises, as %s does: a direct law, but the variation is inverse" % power_model(s, cd.m)})
			"minus":
				wrongs.append({"graph": card.call(cd), "mistake": "minus", "ref": R_MINUS,
					"why": "it is the falling line %s = c − %s through the point, not %s" % [Y(s), X(s), model(s, "a")]})
			"inverse":
				wrongs.append({"graph": card.call(cd), "mistake": "inverse", "ref": R_GRAPH,
					"why": "it falls, as %s does: an inverse law, but the variation is %s" % [power_model(s, cd.m), law]})
	var pk := GdcKit.pick(right, wrongs, rng)
	var ans: Dictionary = pk.answer
	var x2: float = x1 * 2.0 if s.n < 0 else x1 / 2.0
	var y2 := S.power_at(s.a.to_float(), s.n, x2)
	var shape := "falls, more and more slowly, towards the %s-axis" % X(s) if s.n < 0 else "rises, more and more steeply, from the origin"
	return {"asked": "Which graph shows %s against %s?" % [Y(s), X(s)],
		"lines": [story(s), pair_line(s)],
		"answer": ans, "graphs": pk.graphs,
		"methods": {"gdc-graph": method([a_line(s),
			"Graph %s on the GDC: it %s, through (%s, %s), and at %s = %s it gives %s = %s." % [model(s, D(s.a)), shape, D(s.x1), D(s.y1), X(s), W(x2), Y(s), W(y2)],
			"%s is the graph with that shape through those points. So %s." % [pk.letter, Answer.text(ans)]], ans.values)}}


## y = axᵐ with the letters of the story, as a law of power m: "P = av²", "I = a/d".
static func power_model(s: Dictionary, m: int) -> String:
	if m < 0:
		return "%s = a/%s" % [Y(s), pw(X(s), m)]
	return "%s = a%s" % [Y(s), pw(X(s), m)]
