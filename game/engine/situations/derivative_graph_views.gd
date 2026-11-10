class_name DerivativeGraphViews
extends ExtensionViews
## The views on the `derivative-graph` situation: one builder per unknown of
## t5-derivative-graph (FAL-754). The figure is the point: each question shows the graph
## of f′, of f″ or of f (GraphView, with the regions of a signed area shaded), or, where a
## view says so, the same curve as an equation or in words. Every question is Paper 1 and
## exact. An x is an `xval`, several are `xs`, an interval is MonotonicViews' between/outside
## form or a side of a number, a justification or a comparison is a picked `claim`, and
## "which graph could be f?" is a pick-the-graph question.
##
## Representations: "graph", "equation" (f′ or f″ as a product of factors) and "words".

const SF := "SL5.7.f-from-derivative-graph#"
const SG := "SL5.2.sign-from-graph#"
const R_FP_TURN := SF + "0"
const R_TOUCH := SF + "1"
const R_ZERO_ALONE := SF + "2"
const R_ZEROS_INFLEXION := SF + "3"
const R_MISS_TOUCH := SF + "4"
const R_STOP_AT_TOUCH := SF + "5"
const R_UNSIGNED := SF + "6"
const R_HEIGHTS := SF + "7"
const R_TOUCH_INFLEXION := SF + "8"
const R_FPP_TURN := SF + "9"
const R_SAME_SHAPE := SF + "10"
const R_WAY_ROUND := SF + "11"
const R_NO_START := SF + "12"
const R_F_SIGN := SG + "0"
const R_INTERCEPTS := SG + "1"
const R_ZERO_VALUE := SG + "2"
const R_HEIGHT := SG + "3"
const R_CONCAVE_SIGN := "SL5.7.concavity#0"


func needs() -> Dictionary:
	var out := {}
	for u in ["extremum-from-derivative", "extremum-justified", "inflexion-from-derivative", "touch-not-turning", "increasing-past-touch",
			"concave-up-from-cubic", "inflexion-from-second", "compare-from-areas", "value-from-areas", "pick-f-from-derivative",
			"gradient-sign-statement", "gradient-negative-where", "gradient-at-turning-point"]:
		out[u] = {"ask": u}
	return out


## Every part of this type in the bank is Paper 1, and every method here works by hand.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = DerivativeGraphSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func xv(x: Variant) -> Dictionary:
	var ans := Answer.make("xval", {"v": Q.of(x)})
	ans.exact = true
	return ans


static func wx(x: Variant, ref: String = "") -> Dictionary:
	return wrong({"v": Q.of(x)}, ref)


static func xs(list: Array) -> Dictionary:
	var sorted := list.duplicate()
	sorted.sort()
	return Answer.xs_of(sorted.map(func(x): return Q.of(x)))


static func sign_word(n: int) -> String:
	return "positive" if n > 0 else ("negative" if n < 0 else "zero")


static func pm(n: int) -> String:
	return "+" if n > 0 else "−"


## "2(x − 1)(x + 2)²", "−x²(x − 3)": the touch family as factors.
static func touch_text(s: Dictionary) -> String:
	var lead := Fmt.lead(s.k)
	if s.b == 0:
		return lead + "x²" + Fmt.factor(s.a)
	return lead + Fmt.factor(s.a) + Fmt.factor(s.b) + "²"


static func quad_text(s: Dictionary) -> String:
	return Fmt.factorised(s.k, s.a, s.b)


static func g_text(s: Dictionary) -> String:
	return touch_text(s) if s.fam == "touch" else quad_text(s)


## The curve on [lo, hi], with a dot at each place it meets the x-axis.
static func figure(s: Dictionary, points: Array = []) -> Dictionary:
	var pts: Array = points.duplicate()
	if s.get("v", 0) == 0:
		pts.append([float(s.a), 0.0, ""])
		pts.append([float(s.b), 0.0, ""])
	var g := MonotonicViews.graph_of(DerivativeGraphSituation.fn(s), float(s.lo), float(s.hi), pts)
	return g


static func domain(s: Dictionary) -> String:
	return "%s ≤ x ≤ %s" % [Fmt.num(s.lo), Fmt.num(s.hi)]


static func shows(s: Dictionary, what: String = "f′(x)") -> String:
	return "The graph shows y = %s, for %s." % [what, domain(s)]


## The sign of g just left and just right of a whole number x where g is 0.
static func left_sign(s: Dictionary, x: int) -> int:
	return int(signf(DerivativeGraphSituation.fn(s).call(x - 0.5)))


static func right_sign(s: Dictionary, x: int) -> int:
	return int(signf(DerivativeGraphSituation.fn(s).call(x + 0.5)))


## What f does at a zero of f′: "maximum", "minimum" or "inflexion" (no sign change).
static func nature(s: Dictionary, x: int) -> String:
	var l := left_sign(s, x)
	var r := right_sign(s, x)
	if l == r:
		return "inflexion"
	return "maximum" if l > 0 else "minimum"


## The stretches of the sign row of g from lo to hi, cut at its zeros: "− for x < 1, + for 1 < x < 4, + for x > 4".
static func sign_row(s: Dictionary, cuts: Array) -> String:
	var f := DerivativeGraphSituation.fn(s)
	var cs: Array = cuts.duplicate()
	cs.sort()
	var out: Array = []
	var sg := func(x: float) -> String: return pm(int(signf(f.call(x))))
	out.append("%s for x < %s" % [sg.call(cs[0] - 0.5), Fmt.num(cs[0])])
	for i in range(1, cs.size()):
		out.append("%s for %s < x < %s" % [sg.call((cs[i - 1] + cs[i]) / 2.0), Fmt.num(cs[i - 1]), Fmt.num(cs[i])])
	out.append("%s for x > %s" % [sg.call(cs[-1] + 0.5), Fmt.num(cs[-1])])
	return ", ".join(out)


## Where f′ (a parabola or the touch cubic) turns: the vertex, or c and b.
static func turns(s: Dictionary) -> Array:
	return [s.h] if s.fam == "quad" else [s.c, s.b]


## Whether g has a maximum (true) or a minimum at the turning point x.
static func g_max_at(s: Dictionary, x: int) -> bool:
	var f := DerivativeGraphSituation.fn(s)
	return f.call(x) > f.call(x + 0.5)


static func turn_word(s: Dictionary, x: int) -> String:
	return "maximum" if g_max_at(s, x) else "minimum"


static func other_kind(kind: String) -> String:
	return "minimum" if kind == "maximum" else "maximum"


## Whole numbers near x, for generic options.
static func near(x: int, avoid: Array) -> Array:
	var out: Array = []
	for d in [1, -1, 2, -2, 3]:
		if not (x + d) in avoid:
			out.append({"v": Q.new(x + d)})
	return out


# ── Turning points of f from the graph of f′ ─────────────────

## The zero of f′ where f has the extremum asked, and its kind.
static func extremum(s: Dictionary) -> Dictionary:
	if s.fam == "touch":
		return {"x": s.a, "kind": nature(s, s.a), "other": s.b}
	var at_a := nature(s, s.a)
	if s.want == at_a:
		return {"x": s.a, "kind": at_a, "other": s.b}
	return {"x": s.b, "kind": s.want, "other": s.a}


func _f_prime_lines(rep: String, s: Dictionary) -> Array:
	if rep == "equation":
		return ["f′(x) = %s" % g_text(s)]
	return [shows(s)]


func u_extremum_from_derivative(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var e := extremum(s)
	var x: int = e.x
	var kind: String = e.kind
	var ans := xv(x)
	var l := left_sign(s, x)
	var tp: int = turns(s)[0]
	var wr: Array = [wx(tp, R_FP_TURN)]
	if s.fam == "touch":
		wr.append(wx(s.b, R_TOUCH))
	else:
		wr.append(wx(e.other, R_WAY_ROUND))
	var cuts: Array = [s.a, s.b]
	var g: Variant = figure(s) if rep == "graph" else null
	var see := "crosses the x-axis at x = %s" % Fmt.num(x) if rep == "graph" else "changes sign at x = %s, where its factor %s does" % [Fmt.num(x), "x" if x == 0 else Fmt.factor(x)]
	var touch_line := ""
	if s.fam == "touch":
		touch_line = (" At x = %s it only touches the axis, so f′ keeps its sign there." if rep == "graph" else " At x = %s its factor is squared, so f′ keeps its sign there.") % Fmt.num(s.b)
	return {"lines": _f_prime_lines(rep, s), "graph": g, "asked": "Find the x-coordinate of the local %s of f." % kind, "answer": ans, "wrongs": wr,
		"generic": near(x, [tp, s.b, s.a]),
		"methods": {"sign-change-of-f-prime": method([
			"A local %s of f is where f′ changes sign from %s to %s." % [kind, sign_word(l), sign_word(-l)],
			"f′ %s, going from %s to %s.%s" % [see, sign_word(l), sign_word(-l), touch_line],
			Answer.text(ans)], ans.values),
		"sign-diagram": method([
			"Sign row of f′: %s." % sign_row(s, cuts),
			"The sign changes from %s to %s only at x = %s, so f has a local %s there." % [pm(l), pm(-l), Fmt.num(x), kind],
			Answer.text(ans)], ans.values)}}


func u_extremum_justified(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var e := extremum(s)
	var x: int = e.x
	var kind: String = e.kind
	var l := left_sign(s, x)
	var X := Fmt.num(x)
	var tp: int = turns(s)[0]
	var right := "x = %s, because f′ changes sign from %s to %s at x = %s" % [X, sign_word(l), sign_word(-l), X]
	var wrongs: Array = [["x = %s, because f′(%s) = 0" % [X, X], R_ZERO_ALONE],
		["x = %s, because the graph of f′ has a %s there" % [Fmt.num(tp), turn_word(s, tp)], R_FP_TURN]]
	if s.fam == "touch":
		wrongs.append(["x = %s, because the graph of f′ touches the x-axis there" % Fmt.num(s.b), R_TOUCH])
	else:
		var o: int = e.other
		var lo := left_sign(s, o)
		wrongs.append(["x = %s, because f′ changes sign from %s to %s at x = %s" % [Fmt.num(o), sign_word(lo), sign_word(-lo), Fmt.num(o)], R_WAY_ROUND])
	var built := DerivativeMeaningViews.claim_answer(right, wrongs)
	return {"lines": [shows(s)], "graph": figure(s), "asked": "Find the x-coordinate of the local %s of f. Which answer is fully justified?" % kind,
		"answer": built.answer, "wrongs": built.wrongs, "generic": [],
		"methods": {"sign-change-of-f-prime": method([
			"f′(x) = 0 is not enough: f has a local %s only where f′ changes sign from %s to %s." % [kind, sign_word(l), sign_word(-l)],
			"The graph of f′ crosses the axis at x = %s, from %s the axis to %s it." % [X, "above" if l > 0 else "below", "below" if l > 0 else "above"],
			right + "."], built.answer.values)}}


func u_inflexion_from_derivative(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ts := turns(s)
	var ans := Answer.make("xs", xs(ts))
	ans.exact = true
	var wr: Array = [wrong(xs([s.a, s.b]), R_ZEROS_INFLEXION)]
	var gen: Array = []
	if s.fam == "touch":
		wr.append(wrong(xs([s.c]), R_MISS_TOUCH))
		gen = [xs([s.b]), xs([s.a, s.c]), xs([s.c + 1, s.b])]
	else:
		gen = [xs([s.a]), xs([s.b]), xs([s.h + 1]), xs([s.h - 1])]
	var where: String
	if s.fam == "touch":
		where = "The graph of f′ has a local %s at x = %s and a local %s at x = %s, where it touches the axis." % [turn_word(s, s.c), Fmt.num(s.c), turn_word(s, s.b), Fmt.num(s.b)]
	else:
		where = "The graph of f′ is a parabola with its vertex, a %s, at x = %s." % [turn_word(s, s.h), Fmt.num(s.h)]
	var cuts: Array = ts.duplicate()
	cuts.sort()
	var dir := func(x: int) -> String: return "increasing" if DerivativeGraphSituation.slope(s, x) > 0 else "decreasing"
	var rows: Array = ["%s for x < %s" % [dir.call(cuts[0] - 1), Fmt.num(cuts[0])]]
	if cuts.size() == 2:
		rows.append("%s for %s < x < %s" % [dir.call(cuts[0] + 1), Fmt.num(cuts[0]), Fmt.num(cuts[1])])
	rows.append("%s for x > %s" % [dir.call(cuts[-1] + 1), Fmt.num(cuts[-1])])
	return {"lines": [shows(s)], "graph": figure(s), "asked": "Find the x-coordinate of each point of inflexion of f.", "answer": ans, "wrongs": wr, "generic": gen,
		"methods": {"turning-point-of-f-prime": method([
			"f has a point of inflexion where f″ changes sign, which is where f′ has a local maximum or minimum, not where f′ is 0.",
			where,
			Answer.text(ans)], ans.values),
		"sign-diagram": method([
			"f″ is the gradient of f′. From the graph, f′ is %s." % ", ".join(rows),
			"So f″ changes sign at x = %s." % Answer.xs_list(cuts.map(func(x): return Fmt.num(x))).replace(" or ", " and x = "),
			Answer.text(ans)], ans.values)}}


func u_touch_not_turning(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var B := Fmt.num(b)
	var sg := left_sign(s, b)
	var rise := "increasing" if sg > 0 else "decreasing"
	var right := "A point of inflexion, not a turning point: f′ is %s on both sides of x = %s" % [sign_word(sg), B]
	var fp_kind := turn_word(s, b)
	var built := DerivativeMeaningViews.claim_answer(right, [
		["A local %s, because the graph of f′ has a %s at x = %s" % [fp_kind, fp_kind, B], R_FP_TURN],
		["A turning point of f, because the graph of f′ touches the x-axis at x = %s" % B, R_TOUCH],
		["A local %s, because f′(%s) = 0" % [other_kind(fp_kind), B], R_ZERO_ALONE]])
	var lines: Array = _f_prime_lines(rep, s)
	lines.append("f′(%s) = 0." % B)
	var sq := "x²" if b == 0 else Fmt.factor(b) + "²"
	var near_b := "At x = %s the graph only touches the x-axis: f′ is %s on both sides." % [B, sign_word(sg)]
	if rep != "graph":
		near_b = "%s is never negative, so near x = %s f′ has the sign of %s%s: %s on both sides." % [sq, B, Fmt.lead(s.k), "x" if s.a == 0 else Fmt.factor(s.a), sign_word(sg)]
	return {"lines": lines, "graph": figure(s) if rep == "graph" else null,
		"asked": "Which statement about the point on the graph of f where x = %s is true?" % B, "answer": built.answer, "wrongs": built.wrongs, "generic": [],
		"methods": {"sign-change-of-f-prime": method([
			"A turning point of f needs f′ to change sign, not just to be 0.",
			near_b,
			right + "."], built.answer.values),
		"sign-diagram": method([
			"Sign row of f′: %s." % sign_row(s, [s.a, b]),
			"There is no sign change at x = %s: f keeps %s through it, with a horizontal tangent there." % [B, rise],
			right + "."], built.answer.values)}}


# ── Where f rises and how it bends ───────────────────────────

func u_increasing_past_touch(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	# The question asks about the side the touch is on, where stopping at it is the trap.
	var tsg := left_sign(s, b)
	var word := "increasing" if tsg > 0 else "decreasing"
	var on_right: bool = b > a
	var rel := ">" if on_right else "<"
	var flip := "<" if on_right else ">"
	var ans := MonotonicViews.side(rel, a)
	var stop := MonotonicViews.interval_text("between", mini(a, b), maxi(a, b))
	var wr: Array = [DifferentiationViews.alt(stop, R_STOP_AT_TOUCH), wrong(MonotonicViews.side(flip, a).values, "")]
	var need := "≥" if tsg > 0 else "≤"
	return {"lines": [shows(s)], "graph": figure(s), "asked": "Find the values of x for which f is %s." % word, "answer": ans, "wrongs": wr,
		"generic": [MonotonicViews.side(rel, b).values, MonotonicViews.side(rel, s.c).values, MonotonicViews.side(flip, b).values, MonotonicViews.side(rel, a + 1).values],
		"methods": {"sign-diagram": method([
			"f is %s where f′(x) %s 0." % [word, need],
			"Sign row of f′: %s." % sign_row(s, [a, b]),
			"f′ is 0 at x = %s but does not change sign, so f keeps %s there." % [Fmt.num(b), word],
			Answer.text(ans)], ans.values)}}


func u_concave_up_from_cubic(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: int = s.c
	var b: int = s.b
	var up: bool = s.want == "up"
	var lo := mini(b, c)
	var hi := maxi(b, c)
	# f″ = 3k(x − b)(x − c): positive outside c and b when k > 0.
	var pos_outside: bool = s.k > 0
	var shape := "outside" if pos_outside == up else "between"
	var ans := MonotonicViews.interval(shape, lo, hi)
	# Where f′ itself is positive (or negative): the sign of k(x − a), past the touch.
	var a: int = s.a
	var fp_rel := ">" if (s.k > 0) == up else "<"
	var wr: Array = [DifferentiationViews.alt("x %s %s" % [fp_rel, Fmt.num(a)], R_CONCAVE_SIGN), MonotonicViews.alt_iv(MonotonicViews.other(shape), lo, hi)]
	var rising := "increasing" if up else "decreasing"
	return {"lines": [shows(s)], "graph": figure(s), "asked": "Find the values of x for which the graph of f is concave %s." % s.want, "answer": ans, "wrongs": wr,
		"generic": [MonotonicViews.alt_iv(shape, mini(a, b), maxi(a, b)).values, MonotonicViews.alt_iv(shape, lo - 1, hi).values, MonotonicViews.alt_iv(shape, lo, hi + 1).values, MonotonicViews.alt_iv(MonotonicViews.other(shape), lo - 1, hi + 1).values],
		"methods": {"turning-point-of-f-prime": method([
			"Concave %s means f′ is %s: read the direction of the graph of f′, not its height." % [s.want, rising],
			"The graph of f′ turns at x = %s and x = %s, and it is %s %s them." % [Fmt.num(lo), Fmt.num(hi), rising, shape],
			Answer.text(ans)], ans.values),
		"sign-diagram": method([
			"f″ is the gradient of f′. Sign row of f″: %s for x < %s, %s for %s < x < %s, %s for x > %s." % [pm(DerivativeGraphSituation.slope(s, lo - 1)), Fmt.num(lo), pm(DerivativeGraphSituation.slope(s, (lo + hi) / 2)), Fmt.num(lo), Fmt.num(hi), pm(DerivativeGraphSituation.slope(s, hi + 1)), Fmt.num(hi)],
			"Concave %s where f″(x) %s 0." % [s.want, ">" if up else "<"],
			Answer.text(ans)], ans.values)}}


func u_inflexion_from_second(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var ans := xv(a)
	var l := left_sign(s, a)
	var lines: Array = ["f″(x) = %s" % touch_text(s)] if rep == "equation" else [shows(s, "f″(x)")]
	var see := "crosses the x-axis at x = %s" % Fmt.num(a) if rep == "graph" else "changes sign at x = %s, where its factor %s is 0" % [Fmt.num(a), "x" if a == 0 else Fmt.factor(a)]
	var keep := "only touches the axis at x = %s" % Fmt.num(b) if rep == "graph" else "is 0 at x = %s too, but its factor there is squared" % Fmt.num(b)
	return {"lines": lines, "graph": figure(s) if rep == "graph" else null, "asked": "The graph of f has one point of inflexion. Find its x-coordinate.",
		"answer": ans, "wrongs": [wx(b, R_TOUCH_INFLEXION), wx(s.c, R_FPP_TURN)], "generic": near(a, [b, s.c]),
		"methods": {"sign-diagram": method([
			"A point of inflexion is where f″ changes sign, not just where f″ = 0.",
			"f″ %s, from %s to %s. It %s, so it keeps its sign there." % [see, sign_word(l), sign_word(-l), keep],
			Answer.text(ans)], ans.values)}}


# ── Signed areas under f′ ────────────────────────────────────

static func area_lines(rep: String, s: Dictionary) -> Array:
	var L := Fmt.num(s.lo)
	var M := Fmt.num(s.m)
	var H := Fmt.num(s.hi)
	if rep == "words":
		return ["A function f has f′(x) %s 0 for %s < x < %s and f′(x) %s 0 for %s < x < %s." % [">" if s.s1 > 0 else "<", L, M, ">" if s.s2 > 0 else "<", M, H],
			"The area between the graph of f′ and the x-axis is %d for %s ≤ x ≤ %s and %d for %s ≤ x ≤ %s." % [s.A1, L, M, s.A2, M, H]]
	return [shows(s), "Region A lies between the graph and the x-axis for %s ≤ x ≤ %s, and has area %d. Region B lies between them for %s ≤ x ≤ %s, and has area %d." % [L, M, s.A1, M, H, s.A2]]


static func area_figure(s: Dictionary) -> Dictionary:
	var f := DerivativeGraphSituation.fn(s)
	var mid1: float = (s.lo + s.m) / 2.0
	var mid2: float = (s.m + s.hi) / 2.0
	var g := MonotonicViews.graph_of(f, float(s.lo), float(s.hi), [[float(s.a), 0.0, ""], [float(s.b), 0.0, ""]])
	g.shade = [DefiniteIntegralViews.under(f, float(s.lo), float(s.m)), DefiniteIntegralViews.under(f, float(s.m), float(s.hi))]
	g.points.append({"x": mid1, "y": f.call(mid1) / 2.0, "label": "A", "name": true})
	g.points.append({"x": mid2, "y": f.call(mid2) / 2.0, "label": "B", "name": true})
	return g


## "−4 + 20": the signed areas as a sum.
static func signed_sum(t1: int, t2: int) -> String:
	return "%s%s" % [Fmt.num(t1), Fmt.plus(t2)]


func u_compare_from_areas(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var L := Fmt.num(s.lo)
	var H := Fmt.num(s.hi)
	var t1: int = s.s1 * s.A1
	var t2: int = s.s2 * s.A2
	var S := t1 + t2
	var verdict := func(d: int) -> String:
		return "f(%s) is greater" % (H if d > 0 else L)
	var right := "%s: f(%s) − f(%s) = %s = %s" % [verdict.call(S), H, L, signed_sum(t1, t2), Fmt.num(S)]
	var flat := "%s: f(%s) − f(%s) = %s = %s" % [verdict.call(1), H, L, signed_sum(s.A1, s.A2), Fmt.num(s.A1 + s.A2)]
	var flipped := "%s: f(%s) − f(%s) = %s = %s" % [verdict.call(-S), H, L, signed_sum(-t1, -t2), Fmt.num(-S)]
	var f := DerivativeGraphSituation.fn(s)
	var hl: float = f.call(float(s.lo))
	var hh: float = f.call(float(s.hi))
	var taller := H if hh > hl else L
	var shorter := L if hh > hl else H
	var heights := "f(%s) is greater, because f′(%s) > f′(%s)" % [taller, taller, shorter]
	var built := DerivativeMeaningViews.claim_answer(right, [[flat, R_UNSIGNED], [heights, R_HEIGHTS], [flipped, ""]])
	var where := "Region A is %s the axis and region B is %s it." % ["above" if s.s1 > 0 else "below", "above" if s.s2 > 0 else "below"]
	if rep == "words":
		where = "f′ is %s on the first stretch and %s on the second." % [sign_word(s.s1), sign_word(s.s2)]
	return {"lines": area_lines(rep, s), "graph": area_figure(s) if rep == "graph" else null, "asked": "Which is greater, f(%s) or f(%s)?" % [L, H],
		"answer": built.answer, "wrongs": built.wrongs, "generic": [],
		"methods": {"area-under-f-prime": method([
			"f(%s) − f(%s) is the integral of f′ from %s to %s: the signed area, where area below the axis counts as negative." % [H, L, L, H],
			where,
			right + "."], built.answer.values)}}


func u_value_from_areas(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var L := Fmt.num(s.lo)
	var v: int = s.v
	var t1: int = s.s1 * s.A1
	var t2: int = s.s2 * s.A2
	var to_hi: bool = s.target == "hi"
	var X := Fmt.num(s.hi if to_hi else s.m)
	var change := t1 + t2 if to_hi else t1
	var y := v + change
	var head := "f(%s) = " % X
	var ans := Answer.make("number", {"v": Q.new(y)}, {}, head)
	ans.exact = true
	var flat: int = v + (s.A1 + s.A2 if to_hi else s.A1)
	var wr: Array = [wrong({"v": Q.new(flat)}, R_UNSIGNED), wrong({"v": Q.new(change)}, R_NO_START), wrong({"v": Q.new(v - change)}, "")]
	var sum_text := signed_sum(t1, t2) if to_hi else Fmt.num(t1)
	var lines := area_lines("graph", s)
	lines.append("f(%s) = %s." % [L, Fmt.num(v)])
	return {"lines": lines, "graph": area_figure(s), "asked": "Find f(%s)." % X, "answer": ans, "wrongs": wr,
		"generic": [{"v": Q.new(y + 1)}, {"v": Q.new(y - 1)}, {"v": Q.new(-y)}, {"v": Q.new(y + 2)}],
		"methods": {"area-under-f-prime": method([
			"f(%s) − f(%s) is the signed area under f′ from %s to %s: area above the x-axis counts as positive, area below it as negative." % [X, L, L, X],
			("Region A is %s the axis and region B is %s it, so f(%s) − f(%s) = %s = %s." % ["above" if s.s1 > 0 else "below", "above" if s.s2 > 0 else "below", X, L, sum_text, Fmt.num(change)]) if to_hi
				else "Region A is %s the axis, so f(%s) − f(%s) = %s." % ["above" if s.s1 > 0 else "below", X, L, Fmt.num(change)],
			"%s: f(%s) plus the change, %s%s." % [Answer.text(ans), L, Fmt.num(v), Fmt.plus(change)]], ans.values)}}


# ── Which graph is f? ────────────────────────────────────────

## An antiderivative of k(x − p)(x − b)² that is 0 at x = b.
static func quartic(k: float, p: float, b: float) -> Callable:
	return func(x: float) -> float: return k * (pow(x - b, 4) / 4.0 + (b - p) * pow(x - b, 3) / 3.0)


## An antiderivative of m(x − a)(x − b) that is 0 at x = b.
static func cubic_through(m: float, a: float, b: float) -> Callable:
	var F := func(x: float) -> float: return m * (x * x * x / 3.0 - (a + b) * x * x / 2.0 + a * b * x)
	return func(x: float) -> float: return F.call(x) - F.call(b)


static func own_card(f: Callable, lo: float, hi: float) -> Dictionary:
	var c := GdcKit.curve(f, lo, hi)
	var ylo := INF
	var yhi := -INF
	for p in c:
		ylo = minf(ylo, p[1])
		yhi = maxf(yhi, p[1])
	return GdcKit.card([c], [], [floori(lo), ceili(hi), floori(ylo) - 1, ceili(yhi) + 1])


func u_pick_f_from_derivative(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var k := float(s.k)
	var a := float(s.a)
	var b := float(s.b)
	var c := float(s.c)
	var lo := float(s.lo)
	var hi := float(s.hi)
	var F := quartic(k, a, b)
	var wrongs: Array = [
		ConcavityViews.one_wrong(own_card(DerivativeGraphSituation.fn(s), lo, hi), "copy", R_SAME_SHAPE, "it is the graph of f′ itself"),
		ConcavityViews.one_wrong(own_card(func(x: float) -> float: return -F.call(x), lo, hi), "flipped", R_WAY_ROUND, "its maximum and minimum are the wrong way round"),
		ConcavityViews.one_wrong(own_card(cubic_through(k * (a - b), a, b), lo, hi), "touch-turn", R_TOUCH, "it turns where f′ only touches the axis")]
	if rng.chance(0.5):
		wrongs[0] = ConcavityViews.one_wrong(own_card(quartic(k, c, b), lo, hi), "peak", R_FP_TURN, "its turning point is where f′ has its turning point")
	var pk := GdcKit.pick(own_card(F, lo, hi), wrongs, rng)
	var ans: Dictionary = pk.answer
	var A := Fmt.num(s.a)
	var B := Fmt.num(s.b)
	var kind := nature(s, s.a)
	return {"lines": [shows(s)], "graph": figure(s), "asked": "Which graph could be y = f(x)?", "answer": ans, "graphs": pk.graphs,
		"methods": {"sign-change-of-f-prime": method([
			"f′ changes sign at x = %s, so f has a local %s there." % [A, kind],
			"At x = %s, f′ touches the axis without changing sign: f flattens out there but does not turn." % B,
			Answer.text(ans)], ans.values),
		"turning-point-of-f-prime": method([
			"f′ has turning points at x = %s and x = %s, so f has points of inflexion there; one of them, at x = %s, is flat." % [Fmt.num(mini(s.c, s.b)), Fmt.num(maxi(s.c, s.b)), B],
			"The only turning point of f is the local %s at x = %s, where f′ crosses the axis." % [kind, A],
			Answer.text(ans)], ans.values)}}


# ── The sign of f′ from the graph of f ───────────────────────

func u_gradient_sign_statement(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x0: int = s.x0
	var X := Fmt.num(x0)
	var d := DerivativeGraphSituation.slope(s, x0)
	var y := DerivativeGraphSituation.at(s, x0)
	var up := "f′(%s) > 0: the curve is going up at x = %s" % [X, X]
	var down := "f′(%s) < 0: the curve is going down at x = %s" % [X, X]
	var flat := "f′(%s) = 0: the curve is flat at x = %s" % [X, X]
	var right: String = up if d > 0 else (down if d < 0 else flat)
	var others: Array = []
	if y == 0:
		others.append(["f′(%s) = 0: the curve meets the x-axis at x = %s" % [X, X], R_INTERCEPTS])
	elif d == 0:
		others.append(["f(%s) = 0, since f′(%s) = 0" % [X, X], R_ZERO_VALUE])
	elif signi(y) != signi(d):
		others.append(["f′(%s) %s 0: the curve is %s the x-axis at x = %s" % [X, ">" if y > 0 else "<", "above" if y > 0 else "below", X], R_F_SIGN])
	for t in [up, down, flat]:
		if t != right and others.size() < 3:
			others.append([t, ""])
	var built := DerivativeMeaningViews.claim_answer(right, others)
	var g := figure(s, [[float(x0), float(y), "A"]])
	var walk: String = "going up" if d > 0 else ("going down" if d < 0 else "at a turning point, flat for an instant")
	return {"lines": ["The graph shows y = f(x), for %s. The point A on the curve has x = %s." % [domain(s), X]], "graph": g,
		"asked": "Which statement about f′ at A is true?", "answer": built.answer, "wrongs": built.wrongs, "generic": [],
		"methods": {"walk-the-curve": method([
			"The sign of f′ is the direction of the curve, not which side of the x-axis it is on.",
			"Walking left to right, at A you are %s." % walk,
			right + "."], built.answer.values),
		"tangent-sketch": method([
			"Lay a ruler along the curve at A as its tangent.",
			"It %s." % ("slopes up" if d > 0 else ("slopes down" if d < 0 else "is horizontal")),
			right + "."], built.answer.values)}}


func u_gradient_negative_where(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var neg: bool = s.want == "< 0"
	var lo := mini(b, c)
	var hi := maxi(b, c)
	# f′ = 3k(x − b)(x − c): negative between c and b when k > 0.
	var between_neg: bool = s.k > 0
	var shape := "between" if between_neg == neg else "outside"
	var ans := MonotonicViews.interval(shape, lo, hi)
	# Where f itself has that sign: k(x − a) has it, past the touch.
	var f_rel := ("<" if neg else ">") if s.k > 0 else (">" if neg else "<")
	var wr: Array = [DifferentiationViews.alt("x %s %s" % [f_rel, Fmt.num(a)], R_F_SIGN),
		MonotonicViews.alt_iv(shape, mini(a, b), maxi(a, b), R_INTERCEPTS), MonotonicViews.alt_iv(MonotonicViews.other(shape), lo, hi)]
	var pts: Array = [[float(c), float(DerivativeGraphSituation.at(s, c)), Fmt.point(c, DerivativeGraphSituation.at(s, c))], [float(b), 0.0, Fmt.point(b, 0)]]
	var g := MonotonicViews.graph_of(DerivativeGraphSituation.fn(s), float(s.lo), float(s.hi), pts)
	var dir := "down" if neg else "up"
	return {"lines": ["The graph shows y = f(x), for %s, with its turning points marked." % domain(s)], "graph": g,
		"asked": "Write down the values of x for which f′(x) %s." % s.want, "answer": ans, "wrongs": wr,
		"generic": [MonotonicViews.alt_iv(shape, lo - 1, hi).values, MonotonicViews.alt_iv(shape, lo, hi + 1).values, MonotonicViews.alt_iv(MonotonicViews.other(shape), mini(a, b), maxi(a, b)).values],
		"methods": {"walk-the-curve": method([
			"f′(x) %s where the curve is going %s as you walk left to right, whichever side of the x-axis it is on." % [s.want, dir],
			"It turns at x = %s and x = %s, the turning points, not at the x-intercepts." % [Fmt.num(lo), Fmt.num(hi)],
			Answer.text(ans)], ans.values),
		"sign-row": method([
			"Mark the turning points, x = %s and x = %s, on the x-axis." % [Fmt.num(lo), Fmt.num(hi)],
			"Sign row of f′: %s for x < %s, %s between, %s for x > %s." % [pm(DerivativeGraphSituation.slope(s, lo - 1)), Fmt.num(lo), pm(DerivativeGraphSituation.slope(s, (lo + hi) / 2)), pm(DerivativeGraphSituation.slope(s, hi + 1)), Fmt.num(hi)],
			Answer.text(ans)], ans.values)}}


func u_gradient_at_turning_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: int = s.c
	var yc: int = DerivativeGraphSituation.at(s, c) + s.v
	var C := Fmt.num(c)
	var kind := "maximum" if DerivativeGraphSituation.slope(s, c - 1) > 0 else "minimum"
	var head := "f′(%s) = " % C
	var ans := Answer.make("number", {"v": Q.new(0)}, {}, head)
	ans.exact = true
	var out := {"asked": "Write down the value of f′(%s)." % C, "answer": ans,
		"wrongs": [wrong({"v": Q.new(yc)}, R_HEIGHT), wrong({"v": Q.new(c)}, "")],
		"generic": [{"v": Q.new(1)}, {"v": Q.new(-1)}, {"v": Q.new(yc + 1)}, {"v": Q.new(2)}],
		"methods": {"tangent-sketch": method([
			"The tangent at a local %s is horizontal." % kind,
			"A horizontal line has gradient 0, whatever the height of the point.",
			Answer.text(ans)], ans.values),
		"walk-the-curve": method([
			"Walking left to right, the curve goes %s to the point, then %s." % ["up" if kind == "maximum" else "down", "down" if kind == "maximum" else "up"],
			"At the turn it is flat for an instant, so its gradient there is 0.",
			Answer.text(ans)], ans.values)}}
	if rep == "words":
		out.lines = ["The graph of y = f(x) has a local %s at the point (%s, %s)." % [kind, C, Fmt.num(yc)]]
	else:
		out.lines = ["The graph shows y = f(x), for %s. It has a local %s at A(%s, %s)." % [domain(s), kind, C, Fmt.num(yc)]]
		out.graph = figure(s, [[float(c), float(yc), "A"]])
	return out
