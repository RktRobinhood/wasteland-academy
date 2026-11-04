class_name LinkTransformationsViews
extends ExtensionViews
## The views on the `fn-link-transformations` situation: one builder per unknown of
## fn-link-transformations (FAL-424). The same translation or stretch in a graph, a family
## of antiderivatives, a data set, a normal curve and an area. Numbers are typed where the
## answer is numbers alone (labelled ones for a list of statistics); a sentence or a
## maximum with π in it is a choice. true-false-reason and method-pick are built for every
## unknown. The type lists no error-spot, so its error-spot misconceptions are wrong
## options here, each with its ref. Every number is exact, so no rounding trap fits.

const TC := preload("res://engine/situations/transform_chain.gd")
const LS := preload("res://engine/situations/link_transformations.gd")
const SIGN := "SL2.11.translate#0"
const INSIDE := "SL2.11.translate#1"
const ASYMPTOTE := "SL2.11.translate#2"
const WAVE := "SL3.7.transformations#2"
const FACTOR := "SL2.11.stretch#0"
const VAGUE := "SL2.11.stretch#2"
const SD_K := "SL4.3.constant-changes#0"
const VAR_M := "SL4.3.constant-changes#1"
const IQR_K := "SL4.3.constant-changes#2"
const REVERSED := "SL4.12.standardise#0"
const VARIANCE := "SL4.12.standardise#1"
const POINT_IN_D := "SL5.5.boundary-condition#0"
const C_ZERO := "SL5.5.boundary-condition#1"
const NO_WIDTH := "SL5.11.integral-properties#0"
const STATS := ["mean", "median", "standard deviation", "IQR"]


func needs() -> Dictionary:
	return {"moved-feature": {"kind": "graph"}, "antiderivative-gap": {"kind": "family"}, "curve-through-point": {"kind": "family"},
		"shifted-data": {"kind": "data"}, "stretched-data": {"kind": "stats"}, "change-from-statistics": {"kind": "stats"},
		"standardise-moves": {"kind": "normal"}, "standardise-bounds": {"kind": "normal", "paper": 2},
		"translated-area": {"kind": "area"}, "raised-area": {"kind": "area"}}


func extra() -> Dictionary:
	var out := {}
	for u in needs():
		out[u] = ["true-false-reason", "method-pick"]
	return out


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = LS.export(s)
	return out


static func pick(name: String, why: String) -> Dictionary:
	return {"name": name, "why": why}


## A question answered in numbers: every method's last line says the answer.
static func typed(ans: Dictionary, wrongs: Array, asked: String, lines: Array, methods: Dictionary, picks: Array) -> Dictionary:
	ans.exact = true
	ans.show = "dec"
	var ms := {}
	for a in methods:
		ms[a] = method(methods[a].map(func(l): return ExpLogPairViews.M(l)) + ["So the answer is %s." % Answer.text(ans)], ans.values)
	return {"answer": ans, "wrongs": wrongs, "asked": ExpLogPairViews.M(asked), "lines": lines.map(func(l): return ExpLogPairViews.M(l)), "methods": ms, "pick_wrongs": picks}


## "3 to the right and 2 down".
static func move_words(s: Dictionary, a: Q, b: Q) -> String:
	return "%s and %s" % [TransformDescribeViews.across_word(s, a), TransformDescribeViews.vert_word(s, b)]


## Two curves on one set of axes, the first teal and the second sand.
static func both(first: Array, second: Array, points: Array, win: Array, hlines: Array = [], vlines: Array = []) -> Dictionary:
	var g := Plot.spec(first + second, points, win[0], win[1], win[2], win[3], hlines, vlines)
	g.one_colour = true
	g.sand_from = first.size()
	return g


# ── A moved graph ────────────────────────────────────────────

## π/2 + a, as a maximum's x-coordinate reads: "π/2 − 1", "π/2".
static func pi_plus(a: Q) -> String:
	return "π/2" + Fmt.plus(a) if not a.is_zero() else "π/2"


static func pi_point(a: Q, y: Q) -> String:
	return "(%s, %s)" % [pi_plus(a), N(y)]


## The rule, as a map with no stretches.
static func moved_rule(s: Dictionary, a: Q, b: Q) -> String:
	return TC.rule(s, {"A": Q.new(1), "B": Q.new(1), "C": a, "D": b})


func u_moved_feature(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Q = s.a
	var b: Q = s.b
	var parent := "y = " + TC.f_rule(s)
	var new_rule := "y = " + moved_rule(s, a, b)
	var vec := Fmt.point(a, b)
	var from_text := ""
	var to_text := ""
	var asked := ""
	var out: Dictionary
	var lines: Array = [parent, "The graph is translated by the vector %s." % vec]
	if rep == "words":
		lines = ["The graph of %s is moved %s." % [parent, move_words(s, a, b)]]
	var steps := func(feature: String, was: String, now: String) -> Dictionary: return {
		"substitute": ["Replace x with %s and add %s: %s." % [Answer.x_minus(a), P(b), new_rule], "Read %s from the new equation." % feature],
		"track-points": ["%s is %s on the graph of %s." % [TC.cap(feature), was, parent], "Add the vector %s to it: %s." % [vec, now]],
		"shift-features": ["The whole graph moves, and %s with it." % feature, "So %s goes to %s." % [was, now]],
		"translation-vector": ["The vector %s adds %s to every x and %s to every y." % [vec, N(a), N(b)], "So %s goes to %s." % [was, now]],
	}
	var picks: Array = [pick("Add the vector's numbers to the equation as they stand", "x has to be reduced by a, so the sign inside the bracket is the opposite of the vector's"),
		pick("Keep the feature where it is", "every point of the graph moves, and every feature with it"),
		pick("Swap the two parts of the vector", "the first part moves x and the second moves y")]
	match s.fam:
		"sq":
			from_text = "(0, 0)"
			to_text = vec
			asked = "Find the vertex of the new graph."
			out = typed(Answer.make("point", {"x": a, "y": b}), [wrong({"x": a.neg(), "y": b}, SIGN), wrong({"x": a.sub(b), "y": Q.new(0)}, INSIDE), wrong({"x": a, "y": b.neg()}), wrong({"x": b, "y": a})],
				asked, lines, steps.call("the vertex", from_text, to_text), picks)
		"recip":
			from_text = "x = 0 and y = 0"
			to_text = "x = %s and y = %s" % [N(a), N(b)]
			asked = "Find the asymptotes of the new graph."
			out = typed(Answer.make("named", {"v0": a, "v1": b}, {"names": ["x", "y"]}), [wrong({"v0": a.neg(), "v1": b}, SIGN), wrong({"v0": a, "v1": Q.new(0)}, ASYMPTOTE), wrong({"v0": a.sub(b), "v1": Q.new(0)}, INSIDE), wrong({"v0": b, "v1": a})],
				asked, lines, steps.call("the pair of asymptotes", from_text, to_text), picks)
		"exp":
			from_text = "y = 0"
			to_text = "y = " + N(b)
			asked = "Find the asymptote of the new graph."
			out = typed(Answer.make("axis", {"var": "y", "h": b}), [wrong({"var": "y", "h": Q.new(0)}, ASYMPTOTE), wrong({"var": "y", "h": b.neg()}), wrong({"var": "y", "h": a}), wrong({"var": "x", "h": a})],
				asked, lines, steps.call("the asymptote", from_text, to_text), picks)
		_:
			var y1 := b.add(1)
			from_text = "(π/2, 1)"
			to_text = pi_point(a, y1)
			asked = "y = sin x has a maximum at (π/2, 1). Find where that maximum point lands."
			var ms: Dictionary = steps.call("the maximum", from_text, to_text)
			out = LinkExtremesViews.ask(to_text, [[pi_point(a.neg(), y1), WAVE], [pi_point(a.sub(b), Q.new(1)), INSIDE]], [pi_point(a, b), pi_point(Q.new(0), y1), pi_point(a.neg(), Q.new(1).sub(b)), pi_point(b, a.add(1))],
				asked, lines, ms, "So the maximum lands at %s." % to_text, picks)
	if rep == "graph":
		out.lines = [ExpLogPairViews.M("The graphs of %s and its image are shown. The image is the graph translated by the vector %s." % [parent, vec])]
		var win := [mini(-6, floori(a.to_float()) - 4), maxi(6, ceili(a.to_float()) + 4), mini(-3, floori(b.to_float()) - 3), maxi(6, ceili(b.to_float()) + 4)]
		var one := TC.identity()
		var map := {"A": Q.new(1), "B": Q.new(1), "C": a, "D": b}
		var hl: Array = []
		var vl: Array = []
		if s.fam == "recip":
			hl = [[0.0, ""], [b.to_float(), ""]]
			vl = [[0.0, ""], [a.to_float(), ""]]
		elif s.fam == "exp":
			hl = [[0.0, ""], [b.to_float(), ""]]
		out.graph = both(TC.curves(s, one, win), TC.curves(s, map, win), [], win, hl, vl)
	return out


# ── Antiderivatives ──────────────────────────────────────────

static func F_text(s: Dictionary, c: int) -> String:
	return Fmt.poly([s.pc, s.pr, c] if s.pn == 2 else [s.pc, 0, s.pr, c])


static func f_text(s: Dictionary) -> String:
	return Fmt.poly([2 * s.pc, s.pr] if s.pn == 2 else [3 * s.pc, 0, s.pr])


static func F_curve(s: Dictionary, c: int, lo: float, hi: float) -> Array:
	var pn: int = s.pn
	var pc: int = s.pc
	var pr: int = s.pr
	return [GdcKit.curve(func(x: float) -> float: return pc * pow(x, pn) + pr * x + c, lo, hi)]


func u_antiderivative_gap(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c1: int = s.c1
	var c2: int = s.c2
	var gap := c2 - c1
	var lines: Array = ["G(x) = " + F_text(s, c1), "H(x) = " + F_text(s, c2), "Both are antiderivatives of f(x) = %s." % f_text(s)]
	var out := typed(Answer.make("point", {"x": Q.new(0), "y": Q.new(gap)}), [wrong({"x": Q.new(0), "y": Q.new(c2)}, C_ZERO), wrong({"x": Q.new(0), "y": Q.new(-gap)}), wrong({"x": Q.new(gap), "y": Q.new(0)}), wrong({"x": Q.new(0), "y": Q.new(c1 + c2)})],
		"Find the translation vector that maps the graph of y = G(x) onto the graph of y = H(x).", lines, {
			"substitute": ["H(x) = G(x) %s %d, with no change inside G." % ["+" if gap > 0 else "−", absi(gap)], "A number added outside is a vertical move: y = f(x) + d is a move by (0, d)."],
			"shift-features": ["The y-intercept moves from %s to %s." % [Fmt.point(0, c1), Fmt.point(0, c2)], "x doesn't change, and y changes by %s − %s = %d." % [N(c2), P(c1), gap]],
			"pick-from-family": ["Both curves are F(x) + C for one F, with C = %s and C = %s." % [N(c1), N(c2)], "The gap between family members is C₂ − C₁ = %d, and it is all vertical." % gap],
		}, [pick("Differentiate both and compare", "both derivatives are the same f, so that loses the gap"),
			pick("Set G(x) = H(x) and solve", "the two curves never meet: they differ by a constant"),
			pick("Take the second constant as the move", "the move is the gap between the constants, not one of them")])
	if rep == "graph":
		out.lines = [ExpLogPairViews.M("The graphs of y = G(x) and y = H(x) are shown, with their y-intercepts. Both are antiderivatives of f(x) = %s." % f_text(s))]
		out.graph = both(F_curve(s, c1, -4.0, 4.0), F_curve(s, c2, -4.0, 4.0), [[0, c1, Fmt.point(0, c1)], [0, c2, Fmt.point(0, c2)]], [-4, 4, mini(c1, c2) - 6, maxi(c1, c2) + 6])
	return out


func u_curve_through_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var px: int = s.px
	var py: int = s.py
	var c: int = s.c
	var fx := LS.F(s, px)
	var dfx := LS.dF(s, px)
	var f0 := F_text(s, 0)
	var pt := Fmt.point(px, py)
	var lines: Array = ["f′(x) = " + f_text(s), "The curve y = f(x) passes through %s." % pt]
	if rep == "words":
		lines = ["The gradient of a curve at any point is %s." % f_text(s), "The curve passes through %s." % pt]
	var sub := "%s = %s + C, so C = %s − %s = %s." % [N(py), N(fx), N(py), P(fx), N(c)]
	var out := typed(Answer.make("number", {"v": Q.new(c)}, {}, "C = "), [wrong({"v": Q.new(0)}, C_ZERO), wrong({"v": Q.new(py - dfx)}, POINT_IN_D), wrong({"v": Q.new(-c)}), wrong({"v": Q.new(py + fx)})],
		"Let F(x) be the antiderivative with no constant term. Find C, the vertical move from y = F(x) to the curve.", lines, {
			"pick-from-family": ["Every antiderivative is F(x) + C, with F(x) = %s: a family of vertical moves." % f0, "F(%s) = %s, but the curve is at height %s there." % [N(px), N(fx), N(py)], sub],
			"integrate-then-substitute": ["Integrate: y = %s + C." % f0, "Put in the point: " + sub],
		}, [pick("Put the point into f′(x)", "f′ gives the gradient, so the point doesn't lie on it"),
			pick("Set C = 0", "that picks one curve of the family, and it misses the point"),
			pick("Differentiate f′(x) again", "the curve is the integral of f′, not its derivative")])
	if rep == "graph":
		out.lines = [ExpLogPairViews.M("The graph of y = F(x) = %s is shown, with the point %s that the curve y = f(x) passes through." % [f0, pt]),
			"f′(x) = " + ExpLogPairViews.M(f_text(s))]
		var lo := mini(px, 0) - 3
		var hi := maxi(px, 0) + 3
		out.graph = Plot.spec(F_curve(s, 0, lo, hi), [[px, py, pt]], lo, hi, mini(mini(py, fx), 0) - 8, maxi(maxi(py, fx), 0) + 8)
		out.graph.one_colour = true
	return out


# ── Data ─────────────────────────────────────────────────────

static func data_table(names: Array, cols: Array) -> Dictionary:
	var rows: Array = [["Statistic", names]]
	for c in cols:
		rows.append([c[0], c[1].map(func(v): return Fmt.dec(v))])
	return {"rows": rows}


## A histogram's outline, bars of width 1 centred on each whole value.
static func outline(xs: Array, shift: int) -> Array:
	var freq := {}
	for x in xs:
		var at := int(x.to_float()) + shift
		freq[at] = freq.get(at, 0) + 1
	var keys: Array = freq.keys()
	keys.sort()
	var lo: int = keys[0]
	var hi: int = keys[keys.size() - 1]
	var out: Array = [[lo - 0.5, 0.0]]
	for x in range(lo, hi + 1):
		var f := float(freq.get(x, 0))
		out.append([x - 0.5, f])
		out.append([x + 0.5, f])
	out.append([hi + 0.5, 0.0])
	return out


static func stat_list(names: Array, vals: Array) -> String:
	var parts: PackedStringArray = []
	for i in names.size():
		parts.append("%s %s" % [names[i], Fmt.dec(vals[i])])
	return ", ".join(parts)


func u_shifted_data(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: Q = s.k
	var vals: Array = [s.mean, s.median, s.sd, s.iqr]
	var ans := Answer.make("named", {"v0": s.mean.add(k), "v1": s.median.add(k), "v2": s.sd, "v3": s.iqr}, {"names": STATS})
	var add := "Every value is increased by %s." % N(k)
	var lines: Array = ["A data set has %s." % stat_list(STATS, vals), add]
	var w: Array = [wrong({"v0": s.mean.add(k), "v1": s.median.add(k), "v2": s.sd.add(k), "v3": s.iqr}, SD_K),
		wrong({"v0": s.mean.add(k), "v1": s.median.add(k), "v2": s.sd, "v3": s.iqr.add(k)}, IQR_K),
		wrong({"v0": s.mean.add(k), "v1": s.median, "v2": s.sd, "v3": s.iqr}),
		wrong({"v0": s.mean.add(k), "v1": s.median.add(k), "v2": s.sd.add(k), "v3": s.iqr.add(k)})]
	var location := "The mean and median are places on the number line, so each goes up by %s: %s and %s." % [N(k), Fmt.dec(s.mean.add(k)), Fmt.dec(s.median.add(k))]
	var spread := "The standard deviation and IQR measure gaps between values, and no gap changes: %s and %s." % [Fmt.dec(s.sd), Fmt.dec(s.iqr)]
	var out := typed(ans, w, "Find the new mean, median, standard deviation and IQR.", lines, {
		"shift-features": ["Adding %s is a translation by (%s, 0): the data slide along the axis." % [N(k), N(k)], location, spread],
		"shift-stretch-rules": ["Adding a constant moves measures of place and leaves measures of spread.", location, spread],
		"picture-the-histogram": ["Picture the histogram sliding %s to the right, with its shape unchanged." % N(k), location, spread],
		"tiny-example": ["Try two values, 1 and 3: adding %s gives %s and %s." % [N(k), N(k.add(1)), N(k.add(3))], "Their mean rises by %s but the gap stays 2." % N(k), location, spread],
	}, [pick("Add k to all four statistics", "the spread doesn't change when every value moves together"),
		pick("Multiply all four by k", "adding a constant is a translation, not a stretch"),
		pick("Leave all four alone", "the values have moved, so the mean and median have too")])
	if rep == "table":
		out.lines = ["The table gives the summary statistics of a data set.", add]
		out.table = data_table(STATS, [["Before", vals]])
	elif rep == "graph":
		var ks := int(k.to_float())
		var low := int(s.xs[0].to_float())
		var top := int(s.xs[s.xs.size() - 1].to_float())
		var a := outline(s.xs, 0)
		var b := outline(s.xs, ks)
		var fmax := 0.0
		for p in a:
			fmax = maxf(fmax, p[1])
		out.lines = ["The histograms show a data set and the same data with every value increased by %s." % N(k), "Before: %s." % stat_list(STATS, vals)]
		out.graph = both([a], [b], [], [low - 2, top + ks + 2, 0, int(fmax) + 1])
	return out


func u_stretched_data(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Q = s.m
	var k: Q = s.k
	var mean: Q = s.mean
	var sd: Q = s.sd
	var nm := mean.mul(m).add(k)
	var ns := sd.mul(m)
	var nv := ns.mul(ns)
	var names := ["mean", "standard deviation", "variance"]
	var ans := Answer.make("named", {"v0": nm, "v1": ns, "v2": nv}, {"names": names})
	var how := "Every value is multiplied by %s, then increased by %s." % [N(m), N(k)]
	var lines: Array = ["A data set has mean %s and standard deviation %s." % [Fmt.dec(mean), Fmt.dec(sd)], how]
	var w: Array = [wrong({"v0": nm, "v1": ns, "v2": sd.mul(sd).mul(m)}, VAR_M), wrong({"v0": nm, "v1": ns.add(k), "v2": nv}, SD_K),
		wrong({"v0": mean.add(k).mul(m), "v1": ns, "v2": nv}), wrong({"v0": nm, "v1": ns, "v2": ns})]
	var mean_step := "The mean is stretched, then moved: %s × %s + %s = %s." % [Fmt.dec(mean), N(m), N(k), Fmt.dec(nm)]
	var sd_step := "The standard deviation is stretched but not moved: %s × %s = %s." % [Fmt.dec(sd), N(m), Fmt.dec(ns)]
	var var_step := "The variance is its square: %s² = %s, so it is multiplied by %s², not %s." % [Fmt.dec(ns), Fmt.dec(nv), P(m), N(m)]
	var out := typed(ans, w, "Find the new mean, standard deviation and variance.", lines, {
		"scale-rule": ["× %s stretches the data along the axis, and + %s translates them." % [N(m), N(k)], mean_step, sd_step, var_step],
		"shift-stretch-rules": ["Measures of place take both changes. Measures of spread take the stretch only.", mean_step, sd_step, var_step],
		"tiny-example": ["The two values %s and %s have this mean and standard deviation." % [Fmt.dec(mean.sub(sd)), Fmt.dec(mean.add(sd))],
			"They become %s and %s, whose mean is %s and whose gap from it is %s." % [Fmt.dec(mean.sub(sd).mul(m).add(k)), Fmt.dec(mean.add(sd).mul(m).add(k)), Fmt.dec(nm), Fmt.dec(ns)], var_step],
	}, [pick("Add k to every statistic", "adding k moves the mean but leaves the spread"),
		pick("Multiply the variance by m", "the variance is a square, so it is multiplied by m²"),
		pick("Do the two changes in the other order", "× m then + k is what happened; the other order gives another mean")])
	if rep == "table":
		out.lines = ["The table gives the summary statistics of a data set.", how]
		out.table = data_table(["mean", "standard deviation"], [["Before", [mean, sd]]])
	return out


func u_change_from_statistics(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var mean: Q = s.mean
	var sd: Q = s.sd
	var k: Q = s.k
	var m: Q = s.m
	var add: bool = s.form == "add"
	var after: Q = mean.add(k) if add else mean.mul(m)
	var sd2: Q = sd if add else sd.mul(m)
	var up := func(v: Q) -> String: return "every value was increased by %s" % Fmt.dec(v)
	var times := func(v: Q) -> String: return "every value was multiplied by %s" % N(v)
	var right: String = up.call(k) if add else times.call(m)
	var ratio := after.div(mean)
	var gen: Array = [times.call(ratio), times.call(k), up.call(k.mul(2)), "every value was decreased by %s" % Fmt.dec(k)] if add else \
		[up.call(after.sub(mean).abs_q()), times.call(Q.new(1).div(m)), up.call(sd2.sub(sd).abs_q()), times.call(m.mul(2))]
	var lines: Array = ["Before a change, a data set has mean %s and standard deviation %s." % [Fmt.dec(mean), Fmt.dec(sd)],
		"After it, the mean is %s and the standard deviation is %s." % [Fmt.dec(after), Fmt.dec(sd2)]]
	var spread := "The standard deviation is unchanged, so nothing has stretched the data." if add else "The standard deviation has changed by the factor %s ÷ %s = %s, so the data are stretched." % [Fmt.dec(sd2), Fmt.dec(sd), N(m)]
	var last := "The mean tells how far they moved: %s − %s = %s." % [Fmt.dec(after), Fmt.dec(mean), Fmt.dec(k)] if add else "The mean has the same factor: %s × %s = %s, so nothing was added." % [Fmt.dec(mean), N(m), Fmt.dec(after)]
	var out := LinkExtremesViews.ask(right, [], gen, "What was done to every value? Choose one change.", lines, {
		"shift-stretch-rules": ["Read the spread first: it ignores added constants.", spread, last],
		"picture-the-histogram": ["The histogram keeps its width when it only slides, and changes width when it is stretched.", spread, last],
	}, "So %s." % right, [pick("Compare the means alone", "a mean can't tell an added constant from a factor"),
		pick("Divide the new mean by the old one straight away", "that assumes a stretch before the spread has been read"),
		pick("Subtract the standard deviations and add that to each value", "the standard deviation doesn't move when a constant is added")])
	if rep == "table":
		out.lines = [ExpLogPairViews.M("The table gives the summary statistics of a data set before and after a change.")]
		out.table = data_table(["mean", "standard deviation"], [["Before", [mean, sd]], ["After", [after, sd2]]])
	return out


# ── The normal curve ─────────────────────────────────────────

static func model(s: Dictionary) -> String:
	return "X ~ N(%d, %d)" % [s.mu, s.sigma * s.sigma]


static func one_over(sigma: int) -> String:
	return "1/%d" % sigma


static func pdf(mu: float, sg: float) -> Callable:
	return func(x: float) -> float: return exp(-0.5 * ((x - mu) / sg) ** 2) / (sg * sqrt(TAU))


func u_standardise_moves(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var mu: int = s.mu
	var sg: int = s.sigma
	var keep := "each x goes to its own z, so the area between two values is the same"
	var say := func(moves: String, why: String) -> String: return "%s; %s" % [moves, why]
	var tr := "a translation by the vector (%s, 0)" % N(-mu)
	var hs := "a horizontal stretch with scale factor %s" % one_over(sg)
	var right: String = say.call("%s, then %s" % [tr, hs], keep)
	var lines: Array = ["%s, so the mean is %d and the standard deviation is %d." % [model(s), mu, sg]]
	var moved := "Subtracting %d moves the curve by (%s, 0), so it is centred on 0." % [mu, N(-mu)]
	var squeezed := "Dividing by %d is a horizontal stretch with scale factor %s, so its standard deviation is 1." % [sg, one_over(sg)]
	var same := "Each x has one z, and the curve's area stays 1, so matching regions have equal area."
	var out := LinkExtremesViews.ask(right, [[say.call("%s, then a horizontal stretch with scale factor %d" % [tr, sg], keep), FACTOR], [say.call("%s, then a stretch" % tr, keep), VAGUE]],
		[say.call("%s, then %s" % [hs, tr], keep), say.call("a translation by the vector (%d, 0), then %s" % [mu, hs], keep), say.call("%s, then %s" % [tr, hs], "the curve gets narrower, so the probability gets smaller")],
		"Which moves turn the curve of X into the curve of N(0, 1), and why does a probability not change?", lines, {
			"scale-rule": [moved, squeezed, same],
			"standardise-bounds": ["z = (x − %d)/%d: take off the mean first, then divide." % [mu, sg], moved, squeezed, same],
		}, "So: %s." % right, [pick("Compare the two curves on the GDC", "equal answers show the probabilities match, not which moves made them match"),
			pick("Divide by the variance", "the spread is the standard deviation, so that is what must become 1"),
			pick("Divide first, then subtract the mean", "that gives x/σ − μ, not (x − μ)/σ")])
	if rep == "graph":
		var a := GdcKit.curve(pdf(mu, sg), mu - 4.0 * sg, mu + 4.0 * sg)
		var b := GdcKit.curve(pdf(0.0, 1.0), -4.0, 4.0)
		out.lines = [ExpLogPairViews.M("The curves of %s and of N(0, 1) are shown, with the mean of X marked." % model(s)),
			ExpLogPairViews.M("The mean is %d and the standard deviation is %d." % [mu, sg])]
		out.graph = both([a], [b], [[mu, 0.0, "x = %d" % mu]], [-5, mu + 4 * sg + 1, 0, 1])
	return out


static func p_z(rel: String, z: Variant) -> String:
	return "P(Z %s %s)" % [rel, Fmt.dec(z)]


func u_standardise_bounds(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var mu: int = s.mu
	var sg: int = s.sigma
	var x: int = s.x
	var rel: String = s.rel
	var z := Q.new(x - mu, sg)
	var right := p_z(rel, z)
	var flipped := "<" if rel == ">" else ">"
	var px := "P(X %s %d)" % [rel, x]
	var lines: Array = [model(s), px]
	if rep == "words":
		lines = ["X is normally distributed with mean %d and standard deviation %d." % [mu, sg], "The probability wanted is that X is %s than %d." % ["less" if rel == "<" else "more", x]]
	var sub := "z = (%d − %d)/%d = %s." % [x, mu, sg, Fmt.dec(z)]
	var keep := "Standardising is a translation and a stretch, with no reflection, so the inequality keeps its direction."
	var gdc := Fmt.sf(s.p)
	var cdf := "normalcdf"
	return LinkExtremesViews.ask(right, [[p_z(rel, Q.new(x - mu, sg * sg)), VARIANCE], [p_z(flipped, z), REVERSED]],
		[p_z(rel, Q.new(x, sg)), p_z(rel, Q.new(x + mu, sg)), p_z(rel, z.neg())], "Write the same probability for Z ~ N(0, 1).", lines, {
			"standardise-bounds": ["Take off the mean and divide by the standard deviation.", sub, keep],
			"gdc-both": [sub, "%s for X with mean %d and standard deviation %d gives %s." % [cdf, mu, sg, gdc], "%s for Z with mean 0 and standard deviation 1 gives %s too." % [cdf, gdc]],
		}, "So %s = %s." % [px, right], [pick("Divide by the variance", "the standardising divisor is σ, not σ²"),
			pick("Reverse the inequality", "only a reflection would reverse it"),
			pick("Leave out the mean", "z measures distance from the mean")])


# ── Areas ────────────────────────────────────────────────────

## f at an input as written: "3x²", "3(x − 2)²".
static func area_f(s: Dictionary, input: String) -> String:
	var wrapped := input if input == "x" else "(%s)" % input
	match s.pw:
		2:
			return "2" + wrapped
		3:
			return "3%s²" % wrapped
		4:
			return "4%s³" % wrapped
	return "%s³" % wrapped


static func area_at(s: Dictionary, x: float) -> float:
	match s.pw:
		2:
			return 2.0 * x
		3:
			return 3.0 * x * x
		4:
			return 4.0 * x * x * x
	return x * x * x


## F at a whole number, as a Q: x², x³, x⁴, or x⁴/4 for f(x) = x³.
static func area_F(s: Dictionary, x: int) -> Q:
	return Q.new(int(pow(x, s.pw))) if s.pw != 0 else Q.new(int(pow(x, 4)), 4)


static func integral(lo: Variant, hi: Variant, body: String) -> String:
	return "∫ from %s to %s of %s dx" % [N(lo), N(hi), body]


func u_translated_area(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var ai := int(s.a.to_float())
	var area: int = s.area
	var f0 := area_f(s, "x")
	var f1 := area_f(s, Answer.x_minus(s.a))
	var lo := p + ai
	var hi := q + ai
	var moved_i := integral(lo, hi, f1)
	var lines: Array = ["%s = %d" % [integral(p, q, f0), area]]
	var asked := "Find %s, without integrating." % moved_i
	if rep == "words":
		lines = ["The area under y = %s from x = %d to x = %d is %d." % [f0, p, q, area], "The curve and the two limits are all moved %s." % TransformDescribeViews.across_word(s, s.a)]
		asked = "Find the area under the moved curve y = %s, from x = %s to x = %s." % [f1, N(lo), N(hi)]
	var unshifted := area_F(s, hi).sub(area_F(s, lo))
	var w: Array = [wrong({"v": unshifted}), wrong({"v": Q.new(area + ai)}), wrong({"v": Q.new(area - ai)}), wrong({"v": Q.new(area).mul(absi(ai) + 1)})]
	var pic := "The curve moves %s, and both limits move with it." % TransformDescribeViews.across_word(s, s.a)
	var out := typed(Answer.make("number", {"v": Q.new(area)}, {}, "Area = "), w, asked, lines, {
		"track-points": ["The point (x, y) goes to (x%s, y), so x = %d goes to %s and x = %d to %s." % [Fmt.plus(s.a), p, N(lo), q, N(hi)], "Every height stays the same over its moved x, so the area is the same."],
		"area-picture": [pic, "The region keeps its shape and size: a slide doesn't change area."],
	}, [pick("Add the shift to the area", "a move along the x-axis changes no heights and no widths"),
		pick("Integrate f(x) over the new limits", "the curve has moved too, so that is another region"),
		pick("Multiply the area by the shift", "a translation doesn't scale anything")])
	if rep == "graph":
		var x0 := mini(p, lo) - 1
		var x1 := maxi(q, hi) + 1
		var fa := func(x: float) -> float: return area_at(s, x)
		var fb := func(x: float) -> float: return area_at(s, x - ai)
		var top := area_at(s, q)
		out.lines = [ExpLogPairViews.M("The graphs of y = %s and y = %s are shown, for x from %d to %d and from %s to %s." % [f0, f1, p, q, N(lo), N(hi)]), ExpLogPairViews.M(lines[0])]
		out.graph = both([GdcKit.curve(fa, p, q)], [GdcKit.curve(fb, lo, hi)], [], [x0, x1, 0, ceili(top) + 2], [], [[p, ""], [q, ""], [lo, ""], [hi, ""]])
	return out


func u_raised_area(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var area := Q.new(s.area)
	var b: Q = s.b
	var m: Q = s.m
	var width := q - p
	var plus_b := "f(x)%s" % Fmt.plus(b)
	var i1 := integral(p, q, "(%s)" % plus_b)
	var i2 := integral(p, q, "%sf(x)" % Fmt.lead(m))
	var v1 := area.add(b.mul(width))
	var v2 := area.mul(m)
	var ans := Answer.make("named", {"v0": v1, "v1": v2}, {"names": [i1, i2]})
	var lines: Array = ["%s = %s" % [integral(p, q, "f(x)"), N(area)]]
	var rect := "Raising the curve by %s adds a rectangle %d wide and %s high: %s + %d × %s = %s." % [N(b), width, N(b), N(area), width, P(b), N(v1)]
	var tall := "Multiplying by %s stretches every height by %s, so the area is %s × %s = %s." % [N(m), N(m), N(m), N(area), N(v2)]
	var out := typed(ans, [wrong({"v0": area.add(b), "v1": v2}, NO_WIDTH), wrong({"v0": v1, "v1": area.add(m)}), wrong({"v0": area.add(b.mul(q)), "v1": v2}), wrong({"v0": area.add(b), "v1": area.add(m)})],
		"Find both integrals.", lines, {
			"scale-rule": [tall, rect],
			"area-picture": [rect, tall],
			"linearity-rules": ["∫(f + b) = ∫f + ∫b, and ∫b dx from %d to %d is %s × %d." % [p, q, N(b), width], "∫mf = m∫f.", rect, tall],
		}, [pick("Add b to the area", "b is added at every x, so it counts once for each unit of width"),
			pick("Add m to the area", "a factor multiplies every height"),
			pick("Move the limits by b", "b moves the curve up, not along")])
	if rep == "graph":
		var fa := func(x: float) -> float: return area_at(s, x)
		out.lines = [ExpLogPairViews.M("The graph of y = f(x) is shown, from x = %d to x = %d." % [p, q]), ExpLogPairViews.M(lines[0])]
		var g := Plot.spec([GdcKit.curve(fa, p, q)], [], p - 1, q + 1, 0, ceili(area_at(s, q)) + 2, [], [[p, ""], [q, ""]])
		g.one_colour = true
		out.graph = g
	return out
