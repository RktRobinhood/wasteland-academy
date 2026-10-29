class_name GraphFromFeaturesViews
extends RefCounted
## The views on the `graph-from-features` situation: one builder per unknown of
## fn-sketch-from-features (FAL-420). Builders return what QuadraticViews' builders
## return (see quadratic_views.gd). Paper 1: every feature is exact.
##
## The sketch unknowns are pick the graph (Q13, GdcKit.pick): the right sketch and three
## wrong ones, each one mistake from the catalogue: opening the wrong way, a sharp V at
## the vertex, the vertex put on the y-axis, a quantity carried below its limit, a
## level-off drawn as a turning point, a curve that doubles back.

const NEED := {
	"sketch-quadratic": {"fam": "quadratic"},
	"sketch-on-interval": {"fam": "interval"},
	"sketch-with-asymptote": {"fam": "levels", "kind": "texp"},
	"sketch-trig-on-interval": {"fam": "trig"},
	"sketch-from-conditions": {"fam": "conditions"},
	"sketch-from-context": {"fam": "levels", "kind": "cooling"},
	"features-from-sketch": {"fam": "quadratic", "a_neg": true},
	"judge-a-sketch": {"fam": "quadratic"},
}

const SK := "SL2.6.sketch"
const SI := "SL2.3.sketch-from-info"


func has(unknown: String) -> bool:
	return NEED.has(unknown)


func need(unknown: String, _rep: String) -> Dictionary:
	return NEED[unknown].duplicate()


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "wrongs", "generic"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "generic"] else null
	out.given = GraphFromFeaturesSituation.export(s)
	out.given.merge(out.get("check", {}), true)
	out.trap = {}
	return out


# ── Helpers ──────────────────────────────────────────────────

static func N(v: Variant) -> String:
	return Fmt.num(v)


static func P(x: Variant, y: Variant) -> String:
	return Fmt.point(x, y)


static func at(s: Dictionary, x: float) -> float:
	return GraphFromFeaturesSituation.at(s, x)


static func wrong(values: Dictionary, ref: String = "") -> Dictionary:
	return {"values": values, "ref": ref}


## f(x) = a(x − r1)(x − r2), and its expanded form.
static func factorised(s: Dictionary) -> String:
	return "f(x) = %s(%s)(%s)" % [Fmt.lead(s.a), Answer.x_minus(s.r1), Answer.x_minus(s.r2)]


static func general(s: Dictionary) -> String:
	return "f(x) = " + Fmt.poly([s.a, s.a.mul(s.r1.add(s.r2)).neg(), s.c])


static func pi_text(m: float) -> String:
	match roundi(m * 2):
		0:
			return "0"
		1:
			return "π/2"
		2:
			return "π"
		3:
			return "3π/2"
		4:
			return "2π"
	return "?"


## The window every card shares: the domain with room, and y around the features.
static func card_win(s: Dictionary, ys_extra: Array = []) -> Array:
	var ys: Array = [0.0] + ys_extra
	for i in 41:
		ys.append(at(s, s.x0 + (s.x1 - s.x0) * i / 40.0))
	var pad := 2.5 if s.fam in ["interval"] else 1.0
	var w := GdcKit.window(s.x0, s.x1 + (pad if s.fam == "interval" else 0.0), ys.min(), ys.max(), 0.6)
	return w


static func card(s: Dictionary, curves: Array, dots: Array, w: Array, hlines: Array = []) -> Dictionary:
	return GdcKit.card(curves, dots, w, [], hlines)


static func fcurve(s: Dictionary, lo: float = NAN, hi: float = NAN) -> Array:
	var f := func(x: float) -> float: return at(s, x)
	return GdcKit.curve(f, s.x0 if is_nan(lo) else lo, s.x1 if is_nan(hi) else hi)


## The features to mark, as dots: [[x, y, ""], ...].
static func feature_dots(s: Dictionary) -> Array:
	match s.fam:
		"quadratic":
			return [[s.r1.to_float(), 0.0, ""], [s.r2.to_float(), 0.0, ""], [s.h.to_float(), s.k.to_float(), ""], [0.0, s.c.to_float(), ""]]
		"interval":
			var T: float = s.T.to_float()
			if s.kind == "height":
				return [[0.0, 0.0, ""], [T, 0.0, ""], [T / 2.0, at(s, T / 2.0), ""]]
			var v: float = (s.p.to_float() + s.q.to_float()) / 2.0
			return [[0.0, at(s, 0.0), ""], [s.p.to_float(), 0.0, ""], [s.q.to_float(), 0.0, ""], [v, at(s, v), ""], [T, at(s, T), ""]]
		"levels":
			if s.kind == "texp":
				return [[0.0, 0.0, ""], [1.0, at(s, 1.0), ""]]
			return [[0.0, at(s, 0.0), ""]]
		"trig":
			var out: Array = []
			for i in 5:
				var x := PI / 2.0 * i
				out.append([x, at(s, x), ""])
			return out
		"conditions":
			return [[0.0, s.y0.to_float(), ""], [s.z.to_float(), 0.0, ""]]
	return []


static func level_lines(s: Dictionary) -> Array:
	if s.fam == "levels":
		return [[0.0 if s.kind == "texp" else s.R.to_float(), ""]]
	return []


## A wrong card: the curve g on [lo, hi] (the domain unless given), with dots.
static func wrong_card(s: Dictionary, w: Array, g: Callable, mistake: String, ref: String, why: String, lo: float = NAN,
		hi: float = NAN, dots: Array = []) -> Dictionary:
	var curve := GdcKit.curve(g, s.x0 if is_nan(lo) else lo, s.x1 if is_nan(hi) else hi)
	return {"graph": card(s, [curve], dots, w, level_lines(s)), "ref": ref, "mistake": mistake, "why": why}


static func flipped(s: Dictionary, w: Array, ref: String) -> Dictionary:
	var g := func(x: float) -> float: return -at(s, x)
	return wrong_card(s, w, g, "flipped", ref, "it opens the wrong way: the sign of a says which way it opens")


## A sharp V through the roots and the vertex (SL2.6.sketch#1).
static func pointed(s: Dictionary, w: Array, h: float, k: float, r: float) -> Dictionary:
	var g := func(x: float) -> float: return k - k * absf(x - h) / absf(h - r)
	return wrong_card(s, w, g, "pointed", SK + "#1", "its vertex is a sharp point: a parabola is a smooth curve")


func _pick(s: Dictionary, rng: Seeded, wrongs: Array, extra_ys: Array = []) -> Dictionary:
	var w := card_win(s, extra_ys)
	var right := card(s, [fcurve(s)], feature_dots(s), w, level_lines(s))
	var cards: Array = []
	for mk in wrongs:
		cards.append(mk.call(w))
	var p := GdcKit.pick(right, cards, rng)
	return {"answer": p.answer, "graphs": p.graphs}


static func ending(letter: String) -> String:
	return "So the sketch is %s." % letter


# ── fn-sketch-from-features ──────────────────────────────────

func u_sketch_quadratic(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var h: float = s.h.to_float()
	var k: float = s.k.to_float()
	var a: Q = s.a
	var vax := func(x: float) -> float: return a.to_float() * x * x + s.c.to_float()
	var out := _pick(s, rng, [
		func(w): return flipped(s, w, SK + "#0" if a.sign() < 0 else ""),
		func(w): return pointed(s, w, h, k, s.r1.to_float()),
		func(w): return wrong_card(s, w, vax, "vertex-on-axis", SK + "#2", "its vertex is on the y-axis, at the y-intercept, but the vertex is at x = %s" % N(s.h)),
	], [-k, s.c.to_float()])
	var feats := "roots %s and %s, vertex %s, y-intercept %s, opening %s" % [N(s.r1), N(s.r2), P(s.h, s.k), P(0, s.c), "upwards" if a.sign() > 0 else "downwards"]
	var lines := [factorised(s)]
	if rep == "words":
		lines = ["A parabola y = ax² + bx + c has roots x = %s and x = %s, its vertex at %s and its y-intercept at %s, with a %s 0." % [
			N(s.r1), N(s.r2), P(s.h, s.k), P(0, s.c), ">" if a.sign() > 0 else "<"]]
	var final := ending(out.answer.values.v)
	out.merge({
		"asked": "Which graph is the sketch of the parabola?", "lines": lines,
		"methods": {
			"features-then-join": {"result": out.answer.values, "steps": ["Mark the features: " + feats + ".",
				"Join them with a smooth, symmetric curve.", final]},
			"transform-x-squared": {"result": out.answer.values, "steps": ["In vertex form it is %s(x − %s)² + %s: y = x² stretched by %s and moved to %s." % [
				Fmt.lead(a), Fmt.dec(s.h), Fmt.dec(s.k), Fmt.dec(a), P(s.h, s.k)], "It crosses the axes at %s, %s and %s." % [P(s.r1, 0), P(s.r2, 0), P(0, s.c)], final]},
			"midpoint-of-roots": {"result": out.answer.values, "steps": ["The vertex is halfway between the roots: x = (%s + %s)/2 = %s, and f(%s) = %s." % [
				N(s.r1), N(s.r2), Fmt.dec(s.h), Fmt.dec(s.h), Fmt.dec(s.k)], "The sketch has " + feats + ".", final]},
		}})
	return out


func u_sketch_on_interval(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var T: float = s.T.to_float()
	var cards: Array
	var lines: Array
	var feats: String
	if s.kind == "height":
		var top := T / 2.0
		var hmax := at(s, top)
		var under := func(x: float) -> float: return at(s, x)
		cards = [func(w): return wrong_card(s, w, under, "below-zero", SI + "#1", "the height carries on below 0 after the ball lands at t = %s" % N(s.T), 0.0, T + 1.5),
			func(w): return pointed(s, w, top, hmax, 0.0),
			func(w): return flipped(s, w, "")]
		lines = ["h(t) = %st(%s − t), for 0 ≤ t ≤ %s" % [Fmt.lead(s.a), N(s.T), N(s.T)]]
		if rep == "words":
			lines = ["A ball is thrown up at t = 0 and lands at t = %s s. Its height is h(t) = %st(%s − t) metres." % [N(s.T), Fmt.lead(s.a), N(s.T)]]
		feats = "zeros at t = 0 and t = %s, a maximum of %s at t = %s" % [N(s.T), Fmt.dec(GdcKit.qf(hmax)), Fmt.dec(s.T.div(Q.new(2)))]
	else:
		var v: float = (s.p.to_float() + s.q.to_float()) / 2.0
		var vmin := at(s, v)
		var on := func(x: float) -> float: return at(s, x)
		cards = [func(w): return wrong_card(s, w, on, "past-domain", "", "it carries on past t = %s, with no endpoint" % N(s.T), 0.0, T + 1.5),
			func(w): return pointed(s, w, v, vmin, s.p.to_float()),
			func(w): return flipped(s, w, "")]
		lines = ["v(t) = (%s)(%s), for 0 ≤ t ≤ %s" % [Answer.x_minus(s.p).replace("x", "t"), Answer.x_minus(s.q).replace("x", "t"), N(s.T)]]
		if rep == "words":
			lines = ["A particle's velocity is v(t) = (%s)(%s) m/s, for 0 ≤ t ≤ %s seconds." % [Answer.x_minus(s.p).replace("x", "t"),
				Answer.x_minus(s.q).replace("x", "t"), N(s.T)]]
		feats = "v(0) = %s, zeros at t = %s and t = %s, a minimum at t = %s, and v(%s) = %s at the end" % [N(s.p.mul(s.q)), N(s.p), N(s.q),
			Fmt.dec(s.p.add(s.q).div(Q.new(2))), N(s.T), N(s.T.sub(s.p).mul(s.T.sub(s.q)))]
	var out := _pick(s, rng, cards)
	var final := ending(out.answer.values.v)
	out.merge({
		"asked": "Which graph is the sketch on the whole domain?", "lines": lines,
		"methods": {
			"features-then-join": {"result": out.answer.values, "steps": ["Mark " + feats + ".", "Join them smoothly and stop at both ends of the domain.", final]},
			"midpoint-of-roots": {"result": out.answer.values, "steps": ["The turning point is halfway between the zeros.", "So the sketch has " + feats + ".", final]},
			"plot-constraints": {"result": out.answer.values, "steps": ["The domain is 0 ≤ t ≤ %s: the graph starts and stops there." % N(s.T),
				"It has " + feats + ".", final]},
		}})
	return out


func u_sketch_with_asymptote(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: float = s.a.to_float()
	var back := func(x: float) -> float: return a * x * exp(-x) + 0.25 * a * pow(maxf(0.0, x - 2.5), 2)
	var later := func(x: float) -> float: return a * x * exp(-x / 2.0)
	var out := _pick(s, rng, [
		func(w): return wrong_card(s, w, back, "turns-back", SI + "#2", "it reaches the long-run level, turns and goes back up; it should level off"),
		func(w): return wrong_card(s, w, later, "max-moved", "", "its maximum is at x = 2, not at x = 1"),
		func(w): return flipped(s, w, ""),
	])
	var mx := "(1, %s/e)" % N(s.a)
	var lines := ["y = %sxe^(−x), for x ≥ 0" % N(s.a)]
	if rep == "words":
		lines = ["A curve starts at the origin, rises to a maximum at %s, then falls towards the level y = 0 without reaching it." % mx]
	var final := ending(out.answer.values.v)
	out.merge({
		"asked": "Which graph shows the curve: its zero, its maximum and its long-run level?", "lines": lines,
		"methods": {
			"plot-constraints": {"result": out.answer.values, "steps": ["Mark the zero (0, 0) and the maximum %s, about (1, %s)." % [mx, Fmt.sf(a / exp(1.0), 2)],
				"As x grows, e^(−x) wins, so the curve falls towards y = 0 and levels off.", final]},
			"contextual-shape": {"result": out.answer.values, "steps": ["It rises from 0 to one maximum at %s, then dies away." % mx,
				"A level-off never turns back up.", final]},
		}})
	return out


func u_sketch_trig_on_interval(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var A: float = s.A.to_float()
	var other := func(x: float) -> float: return A * (cos(x) if s.fn == "sin" else sin(x))
	var amp: float = 1.0 if A > 1.0 else 2.0
	var small := func(x: float) -> float: return amp * (sin(x) if s.fn == "sin" else cos(x))
	var out := _pick(s, rng, [
		func(w): return wrong_card(s, w, other, "swapped", "", "it is the %s graph: it starts at %s, not %s" % ["cos" if s.fn == "sin" else "sin",
			N(s.A) if s.fn == "sin" else "0", "0" if s.fn == "sin" else N(s.A)]),
		func(w): return wrong_card(s, w, small, "amplitude", "", "its amplitude is %s, not %s" % [Fmt.num(roundi(amp)), N(s.A)]),
		func(w): return flipped(s, w, ""),
	], [-A, A])
	var f := "y = %s%s x" % [Fmt.lead(s.A), s.fn]
	var zs := "0, π and 2π" if s.fn == "sin" else "π/2 and 3π/2"
	var lines := [f + ", for 0 ≤ x ≤ 2π"]
	if rep == "words":
		lines = ["A %s graph with amplitude %s is drawn for 0 ≤ x ≤ 2π. It crosses the x-axis at x = %s." % [s.fn, N(s.A), zs]]
	var mn := "(3π/2, −%s)" % N(s.A) if s.fn == "sin" else "(π, −%s)" % N(s.A)
	var final := ending(out.answer.values.v)
	out.merge({
		"asked": "Which graph is the sketch on 0 ≤ x ≤ 2π?", "lines": lines,
		"methods": {"plot-constraints": {"result": out.answer.values, "steps": [
			"Its zeros are at x = %s, its minimum at %s and its ends at (0, %s) and (2π, %s)." % [zs, mn, "0" if s.fn == "sin" else N(s.A), "0" if s.fn == "sin" else N(s.A)],
			"Join them with the smooth wave shape, amplitude %s." % N(s.A), final]}}})
	return out


func u_sketch_from_conditions(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var z: float = s.z.to_float()
	var y0: float = s.y0.to_float()
	var up := func(x: float) -> float: return at(s, x) + 2.0
	var mirror := func(x: float) -> float: return at(s, -x)
	var out := _pick(s, rng, [
		func(w): return _doubles_back(s, w),
		func(w): return wrong_card(s, w, up, "shifted", "", "it misses the point (0, %s) and the zero at x = %s" % [N(s.y0), N(s.z)]),
		func(w): return wrong_card(s, w, mirror, "mirrored", "", "it is decreasing, and its zero is at x = %s" % N(s.z.neg()), -s.x1, -s.x0),
	])
	var final := ending(out.answer.values.v)
	out.merge({
		"asked": "A function f passes through (0, %s), has a zero at x = %s and is increasing for every x. Which graph could be the graph of y = f(x)?" % [N(s.y0), N(s.z)],
		"lines": ["f passes through (0, %s), f(%s) = 0, and f is increasing everywhere." % [N(s.y0), N(s.z)]],
		"methods": {
			"plot-constraints": {"result": out.answer.values, "steps": ["Plot the two points (0, %s) and (%s, 0)." % [N(s.y0), N(s.z)],
				"Join them with a curve that always rises and that has one y for each x.", final]},
			"choose-family": {"result": out.answer.values, "steps": ["An increasing exponential, moved down, fits: it rises everywhere and crosses the x-axis once.",
				"It must pass through (0, %s) and (%s, 0)." % [N(s.y0), N(s.z)], final]},
		}})
	return out


## A curve through both points that turns back in x, so one x has two y-values (SL2.3#0).
static func _doubles_back(s: Dictionary, w: Array) -> Dictionary:
	var z: float = s.z.to_float()
	var y0: float = s.y0.to_float()
	var pts: Array = []
	for i in 161:
		var u := -0.4 + 1.8 * i / 160.0
		pts.append([z * (1.0 - u) + 4.0 * u * (u - 1.0), y0 * u])
	return {"graph": card(s, [pts], [], w), "ref": SI + "#0", "mistake": "doubles-back",
		"why": "it turns back on itself, so one x has two y-values: it is not the graph of a function"}


func u_sketch_from_context(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var R: float = s.R.to_float()
	var D: float = s.D.to_float()
	var k: float = s.kk.to_float()
	var below := func(x: float) -> float: return (R - 6.0) + (D + 6.0) * exp(-k * x)
	var steady := func(x: float) -> float: return R + D - D * k * x
	var warm := func(x: float) -> float: return R + D - D * exp(-k * x)
	var out := _pick(s, rng, [
		func(w): return wrong_card(s, w, below, "below-room", SI + "#1", "it cools below the room's %s °C, which a drink can't do" % N(s.R)),
		func(w): return wrong_card(s, w, steady, "steady", "", "it cools at a steady rate, so it would never level off"),
		func(w): return wrong_card(s, w, warm, "warming", "", "it warms up from %s °C instead of cooling from %s °C" % [N(s.R), N(s.R.add(s.D))]),
	], [R - 8.0, R + D + 2.0])
	var final := ending(out.answer.values.v)
	out.merge({
		"asked": "A cup of tea at %s °C is left in a room at %s °C. Its temperature t minutes later is T(t) = %s + %se^(−%st). Which graph shows its temperature?" % [
			N(s.R.add(s.D)), N(s.R), N(s.R), N(s.D), GdcKit.lead(s.kk)],
		"lines": ["T(t) = %s + %se^(−%st), for t ≥ 0" % [N(s.R), N(s.D), GdcKit.lead(s.kk)]],
		"methods": {
			"contextual-shape": {"result": out.answer.values, "steps": ["The tea starts at %s °C and cools fast at first, then slower." % N(s.R.add(s.D)),
				"It levels off at the room's %s °C and never goes below it." % N(s.R), final]},
			"choose-family": {"result": out.answer.values, "steps": ["%s + %se^(−%st) is a decaying exponential lifted by %s." % [N(s.R), N(s.D), GdcKit.lead(s.kk), N(s.R)],
				"Its graph falls from (0, %s) towards the asymptote T = %s." % [N(s.R.add(s.D)), N(s.R)], final]},
		}})
	return out


func u_features_from_sketch(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var dir := "opens upwards" if s.a.sign() > 0 else "opens downwards"
	var other := "opens downwards" if s.a.sign() > 0 else "opens upwards"
	var desc := func(h: Q, k: Q, r1: Q, r2: Q, c: Q, d: String) -> String:
		return "vertex %s, roots %s and %s, y-intercept %s, %s" % [P(h, k), N(r1), N(r2), N(c), d]
	var right: String = desc.call(s.h, s.k, s.r1, s.r2, s.c, dir)
	var out := LogFunctionViews.choice(right, [wrong({"v": desc.call(s.h, s.k, s.r1, s.r2, s.c, other)}, SK + "#0" if s.a.sign() < 0 else "")],
		[desc.call(s.k, s.h, s.r1, s.r2, s.c, dir), desc.call(s.h, s.k, s.r1.neg(), s.r2.neg(), s.c, dir), desc.call(s.h, s.k, s.r1, s.r2, s.k, dir)])
	var pts: Array = [[s.r1.to_float(), 0.0, P(s.r1, 0)], [s.r2.to_float(), 0.0, P(s.r2, 0)], [s.h.to_float(), s.k.to_float(), P(s.h, s.k)],
		[0.0, s.c.to_float(), P(0, s.c)]]
	var w := card_win(s, [s.c.to_float()])
	var f := func(x: float) -> float: return at(s, x)
	var final: String = "So: " + out.answer.values.v + "."
	out.merge({
		"asked": "The sketch shows a parabola with its key points labelled. Which describes it?", "lines": ["The graph of y = f(x) is shown."],
		"graph": Plot.spec([GdcKit.curve(f, s.x0, s.x1)], pts, w[0], w[1], w[2], w[3]),
		"methods": {
			"features-then-join": {"result": out.answer.values, "steps": ["Read the labelled points: the vertex %s, the roots %s and %s, the y-intercept %s." % [
				P(s.h, s.k), N(s.r1), N(s.r2), P(0, s.c)], "The vertex is the %s point, so it %s." % ["lowest" if s.a.sign() > 0 else "highest", dir], final]},
			"transform-x-squared": {"result": out.answer.values, "steps": ["It is y = x² %s and moved to %s." % ["stretched" if s.a.sign() > 0 else "reflected", P(s.h, s.k)],
				"Its roots are %s and %s and it meets the y-axis at %s." % [N(s.r1), N(s.r2), N(s.c)], final]},
		}})
	return out


func u_judge_a_sketch(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var flaw := "flipped" if rng.chance(0.5) else "pointed"
	var w := card_win(s, [-s.k.to_float()])
	var h: float = s.h.to_float()
	var k: float = s.k.to_float()
	var drawn: Dictionary = flipped(s, w, "") if flaw == "flipped" else pointed(s, w, h, k, s.r1.to_float())
	var says := {"flipped": "It opens the wrong way: a %s 0, so it should open %s." % [">" if s.a.sign() > 0 else "<", "upwards" if s.a.sign() > 0 else "downwards"],
		"pointed": "Its vertex is a sharp point: a parabola is smooth there."}
	var right: String = says[flaw]
	var other: String = says["pointed" if flaw == "flipped" else "flipped"]
	var out := LogFunctionViews.choice(right, [wrong({"v": "Its vertex should be on the y-axis, at %s." % P(0, s.c)}, SK + "#2")],
		[other, "Nothing: the sketch is right."])
	var g: Dictionary = drawn.graph.duplicate()
	g.erase("card")
	var lines := [general(s)]
	if rep == "graph":
		lines = [factorised(s)]
	var final: String = "So: " + right
	out.merge({
		"asked": "A student sketched the parabola. What is wrong with the sketch?", "lines": lines + ["The student's sketch is shown."], "graph": g,
		"check": {"flaw": flaw},
		"methods": {
			"features-then-join": {"result": out.answer.values, "steps": ["The parabola has roots %s and %s and its vertex at %s." % [N(s.r1), N(s.r2), P(s.h, s.k)],
				"The vertex is halfway between the roots, not at the y-intercept, and the curve is smooth.", final]},
			"gdc-transfer": {"result": out.answer.values, "steps": ["Graph y = f(x) on the GDC and compare its shape with the sketch.",
				"The GDC's parabola %s and is smooth at %s." % ["opens upwards" if s.a.sign() > 0 else "opens downwards", P(s.h, s.k)], final]},
			"plot-constraints": {"result": out.answer.values, "steps": ["a %s 0, so the parabola opens %s, with a smooth vertex at %s." % [
				">" if s.a.sign() > 0 else "<", "upwards" if s.a.sign() > 0 else "downwards", P(s.h, s.k)], "Check the sketch against each fact.", final]},
		}})
	return out
