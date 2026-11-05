class_name AntiderivativeConditionViews
extends ExtensionViews
## The views on the `antiderivative-condition` situation: one builder per unknown of
## t5-antiderivative-condition (FAL-740). A function is a `form` answer: each coefficient and the
## constant are slots, so the student types f(x) with no C left in it. An option with + C still
## in it can be picked but not typed. A value is a `form` answer in DefiniteIntegralViews' shape.
## Exact on Paper 1, as on the Paper 2 parts that end exactly; the decimal e^(ax) and the rate
## model are to 3 s.f., and the GDC method is Paper 2 only.
##
## Representations: "equation" (f′(x) and a condition), "words" (a curve on a map, or a rate in a
## story) and "graph" (a family of curves, or the graph of f′ in straight pieces).

const BC := "SL5.5.boundary-condition#"
const FF := "SL5.10.find-function-from-derivative#"
const R_POINT := BC + "0"
const R_Y_AS_X := BC + "2"
const R_KEPT_C := BC + "3"
const R_NO_C := BC + "4"
const R_SIGN := BC + "5"
const R_Y_IS_C := BC + "6"
const R_DIFF := BC + "7"
const R_F_PRIME := BC + "8"
const R_GRAD_HEIGHT := BC + "9"
const R_ALL_POSITIVE := BC + "10"
const R_ONE_C := FF + "0"
const R_EXACT := FF + "1"
const R_POINT_F := FF + "2"
const R_SAME_RATE := FF + "3"
const R_STAGES := FF + "4"
const R_STOPPED := FF + "5"
const R_OLD_POWER := "SL5.5.antidiff-power#0"
const R_SIN_SIGN := "SL5.10.standard-integrals#0"
const R_MULT_A := "SL5.10.linear-composites#0"
const R_NO_A := "SL5.10.linear-composites#1"
const R_NO_HALF := "SL5.10.inspection-substitution#1"
const R_AT_END := "SL5.5.total-change-from-rate#0"
const R_NO_START := "SL5.5.total-change-from-rate#1"

const UNKNOWNS := ["poly-function", "poly-decimal-point", "curve-through-point", "find-constant", "further-value", "negative-power",
	"trig-chain", "trig-shift", "reciprocal-linear", "exp-and-power", "trig-and-exp", "exp-linear-decimal", "log-inspection",
	"log-given-log", "rate-model", "second-derivative", "second-derivative-exp", "second-derivative-value",
	"parameter-from-gradient", "family-pick", "accumulate-graph"]
const P1_ONLY := ["trig-chain", "trig-shift", "trig-and-exp", "log-inspection", "log-given-log"]
const P2_ONLY := ["poly-decimal-point", "exp-linear-decimal", "rate-model"]
## The curve a scout, a surveyor or a rigger follows: what it is.
const CURVES := ["A ridge line on a scout's map", "A buried pipe on the survey sheet", "A cable slung between two towers on a rigger's plan",
	"A dry riverbed on a caravan's chart"]
## A count that changes with time: the thing, its letter, the time unit, the plural unit, the start.
const RATES := [["rats in the old tunnels", "R", "year", "years", "the survey began"],
	["litres of water in the reservoir", "W", "day", "days", "the gauge was fitted"],
	["ration tins in the depot", "N", "week", "weeks", "the count was taken"],
	["settlers at the crossing", "S", "month", "months", "the gate opened"]]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## A GDC method is Paper 2 only. A trig landmark or a log left in C is Paper 1, as in the bank, and
## decimals are Paper 2; the rest make both, so the type lands on the bank's share.
func papers(unknown: String, _rep: String, angle_id: String) -> Array:
	if not has(unknown):
		return []
	if angle_id.begins_with("gdc-") or unknown in P2_ONLY:
		return [2]
	return [1] if unknown in P1_ONLY else [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = AntiderivativeConditionSituation.export(s)
	# Only three wrong options fit, and the engine takes the first it finds.
	out.wrongs = rng.shuffled(out.wrongs)
	return out


# ── Writing things ───────────────────────────────────────────

static func body(p: int) -> String:
	return "" if p == 0 else ("x" if p == 1 else DifferentiationViews.X(p))


## [[c, p], ...] as [[c, "x²"], ...].
static func bodied(terms: Array) -> Array:
	return terms.map(func(t): return [t[0], body(t[1])])


static func pw(terms: Array) -> String:
	return DifferentiationViews.SUM(bodied(terms))


static func is_curve(s: Dictionary) -> bool:
	return s.ask in ["curve-through-point", "trig-shift", "parameter-from-gradient"] or (s.ask == "reciprocal-linear" and s.rep == "words")


static func lhs(s: Dictionary) -> String:
	return "y" if is_curve(s) else "%s(x)" % s.name


static func dash(s: Dictionary) -> String:
	return "dy/dx" if is_curve(s) else "%s′(x)" % s.name


## A number as this question writes it.
static func W(s: Dictionary, v: Variant) -> String:
	return Fmt.dec(v) if s.style == "dec" else N(v)


static func WP(s: Dictionary, v: Q) -> String:
	return "(%s)" % W(s, v) if v.sign() < 0 else W(s, v)


## " + 4", " − 5.4", or "" for 0.
static func konst(s: Dictionary, k: Variant, sf: bool = false) -> String:
	var q := Q.of(k)
	if q.is_zero():
		return ""
	var mag: String = Fmt.sf(q.abs_q()) if sf else W(s, q.abs_q())
	return (" + " if q.sign() > 0 else " − ") + mag


## f(x) = terms + k, each coefficient and k a slot, so a wrong one can be typed too.
static func fn(s: Dictionary, terms: Array, k: Variant, sf: bool = false) -> Dictionary:
	var head := lhs(s) + " = "
	var parts: Array = [head]
	var slots := {}
	for i in terms.size():
		if i > 0:
			parts.append(" + ")
		parts.append({"slot": "c%d" % i})
		var b: String = terms[i][1]
		parts.append((" " if b.begins_with("ln") or b.begins_with("sin") or b.begins_with("cos") else "") + b)
		slots["c%d" % i] = Q.of(terms[i][0])
	parts.append(" + ")
	parts.append({"slot": "k"})
	slots.k = Q.of(k)
	var ans := DifferentiationViews.form(head + DifferentiationViews.SUM(terms) + konst(s, k, sf), parts, slots)
	ans.exact = not sf
	return ans


static func opt(s: Dictionary, terms: Array, k: Variant, ref: String = "", sf: bool = false) -> Dictionary:
	return wrong(fn(s, terms, k, sf).values, ref)


static func other(text: String, ref: String = "") -> Dictionary:
	return DifferentiationViews.alt(text, ref)


## The right terms with + C left in.
static func kept(s: Dictionary, terms: Array) -> Dictionary:
	return other(lhs(s) + " = " + DifferentiationViews.SUM(terms) + " + C", R_KEPT_C)


## Options with the right terms and other constants.
static func nudged(s: Dictionary, terms: Array, k: Variant, sf: bool = false) -> Array:
	var q := Q.of(k)
	var flipped: Array = terms.map(func(t): return [Q.of(t[0]).neg(), t[1]])
	var list: Array = [q.neg(), q.add(1), q.sub(1), q.add(2), q.sub(2), q.mul(2)].map(func(v): return fn(s, terms, v, sf).values)
	list.append(fn(s, flipped, q, sf).values)
	return list


## Integrate, put the condition in, solve for C: the three steps of every fit.
static func fit(s: Dictionary, rule: String, whole: String, cond: String, fv: Q) -> Array:
	return ["%s: %s = %s + C." % [rule, lhs(s), whole],
		"Put %s into this result, not into the derivative: %s + C = %s." % [cond, W(s, fv), W(s, s.y0)],
		"C = %s − %s = %s." % [W(s, s.y0), WP(s, fv), W(s, s.k)]]


## "x = 2 and y = 5", naming f(2) = 5 for a function.
static func cond_text(s: Dictionary) -> String:
	if is_curve(s):
		return "x = %s, y = %s" % [W(s, s.x0), W(s, s.y0)]
	return "%s(%s) = %s" % [s.name, W(s, s.x0), W(s, s.y0)]


## The two lines of a derivative and a condition.
static func stem(s: Dictionary, f: String) -> Array:
	if is_curve(s):
		return ["dy/dx = %s" % f, "The curve passes through %s." % Fmt.point(s.x0, s.y0)]
	return ["%s′(x) = %s" % [s.name, f], "%s(%s) = %s" % [s.name, W(s, s.x0), W(s, s.y0)]]


static func find(s: Dictionary) -> String:
	return "Find y in terms of x." if is_curve(s) else "Find %s(x)." % s.name


static func map_line(s: Dictionary, f: String) -> String:
	return "%s follows a curve with gradient dy/dx = %s at any point (x, y)." % [CURVES[s.ctx], f]


# ── Sums of powers ───────────────────────────────────────────

const RULE_POWER := "Integrate term by term, raising each power by 1 and dividing by the new power"


## Every slip on a sum of powers, by ref.
static func power_slips(s: Dictionary) -> Dictionary:
	var fp: Array = s.fp
	var F := AntiderivativeConditionSituation.anti(fp)
	var ter := bodied(F)
	var x0: Q = s.x0
	var y0: Q = s.y0
	var D1 := AntiderivativeConditionSituation.diff(fp)
	var old: Array = fp.map(func(t): return [Q.of(t[0]).div(t[1]) if t[1] != 0 else Q.of(t[0]), t[1] + 1])
	var out := {
		R_POINT: opt(s, ter, y0.sub(AntiderivativeConditionSituation.val(fp, x0)), R_POINT),
		R_POINT_F: opt(s, ter, y0.sub(AntiderivativeConditionSituation.val(fp, x0)), R_POINT_F),
		R_KEPT_C: kept(s, ter),
		R_NO_C: opt(s, ter, 0, R_NO_C),
		R_SIGN: opt(s, ter, y0.add(AntiderivativeConditionSituation.val(F, x0)), R_SIGN),
		R_DIFF: other(lhs(s) + " = " + _merged(s, D1, y0.sub(AntiderivativeConditionSituation.val(D1, x0))), R_DIFF),
		R_OLD_POWER: opt(s, bodied(old), y0.sub(AntiderivativeConditionSituation.val(old, x0)), R_OLD_POWER),
	}
	if y0.d == 1 and absi(y0.n) <= 9:
		out[R_Y_AS_X] = opt(s, ter, x0.sub(AntiderivativeConditionSituation.val(F, y0)), R_Y_AS_X)
	return out


## A sum of powers with k added to its own constant term, if it has one.
static func _merged(s: Dictionary, terms: Array, k: Q) -> String:
	var rest: Array = terms.filter(func(t): return t[1] != 0)
	var total := k
	for t in terms:
		if t[1] == 0:
			total = total.add(t[0])
	return pw(rest) + konst(s, total)


func _powers(s: Dictionary, lines: Array, asked: String, refs: Array, rule: String = RULE_POWER, angle_id: String = "integrate-then-substitute") -> Dictionary:
	var F := AntiderivativeConditionSituation.anti(s.fp)
	var ter := bodied(F)
	var slips := power_slips(s)
	var wr: Array = []
	for r in refs:
		if slips.has(r):
			wr.append(slips[r])
	var ans := fn(s, ter, s.k)
	var steps := fit(s, rule, pw(F), cond_text(s), AntiderivativeConditionSituation.val(F, s.x0))
	return DefiniteIntegralViews.pack(lines, asked, ans, wr, nudged(s, ter, s.k), {angle_id: steps})


func u_poly_function(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _powers(s, stem(s, pw(s.fp)), find(s), [R_POINT, R_NO_C, R_KEPT_C, R_Y_AS_X, R_SIGN, R_DIFF, R_OLD_POWER])


func u_poly_decimal_point(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _powers(s, stem(s, pw(s.fp)), find(s), [R_POINT, R_NO_C, R_KEPT_C, R_SIGN])


func u_curve_through_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var lines := stem(s, pw(s.fp))
	var asked := find(s)
	if rep == "words":
		lines = [map_line(s, pw(s.fp)), lines[1]]
		asked = "Find the equation of the curve."
	return _powers(s, lines, asked, [R_POINT, R_NO_C, R_KEPT_C, R_Y_AS_X, R_SIGN])


func u_find_constant(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var F := AntiderivativeConditionSituation.anti(s.fp)
	var fv := AntiderivativeConditionSituation.val(F, s.x0)
	var ans := DefiniteIntegralViews.val(s.k, false, "C = ")
	var lines := stem(s, pw(s.fp)) + ["Integrating gives %s = %s + C." % [lhs(s), pw(F)]]
	var y0: Q = s.y0
	var wr: Array = [DefiniteIntegralViews.like(ans, y0.sub(AntiderivativeConditionSituation.val(s.fp, s.x0)), R_POINT), DefiniteIntegralViews.like(ans, y0.add(fv), R_SIGN), DefiniteIntegralViews.like(ans, y0, R_Y_IS_C)]
	if y0.d == 1 and absi(y0.n) <= 9:
		wr.append(DefiniteIntegralViews.like(ans, Q.of(s.x0).sub(AntiderivativeConditionSituation.val(F, y0)), R_Y_AS_X))
	return DefiniteIntegralViews.pack(lines, "Find the value of C.", ans, wr, [],
		{"integrate-then-substitute": ["Put %s into the integrated form, not into the derivative: %s + C = %s." % [cond_text(s), N(fv), N(y0)],
			"C = %s − %s = %s." % [N(y0), P(fv), N(s.k)]]})


func u_further_value(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var fp: Array = s.fp
	var F := AntiderivativeConditionSituation.anti(fp)
	var x0: Q = s.x0
	var y0: Q = s.y0
	var b: Q = s.b
	var Fb := AntiderivativeConditionSituation.val(F, b)
	var Fa := AntiderivativeConditionSituation.val(F, x0)
	var v: Q = Fb.add(s.k)
	var change := Fb.sub(Fa)
	var ans := DefiniteIntegralViews.val(v, false, "%s(%s) = " % [s.name, N(b)])
	var wr: Array = [DefiniteIntegralViews.like(ans, Fb, R_NO_C), DefiniteIntegralViews.like(ans, Fb.add(y0).sub(AntiderivativeConditionSituation.val(fp, x0)), R_POINT), DefiniteIntegralViews.like(ans, AntiderivativeConditionSituation.val(fp, b), R_F_PRIME),
		DefiniteIntegralViews.like(ans, change, R_NO_START)]
	var integral: String = DefiniteIntegralViews.integral_text(pw(fp), N(x0), N(b))
	var tail := "%s(%s) = %s + %s = %s." % [s.name, N(b), N(y0), P(change), N(v)]
	return DefiniteIntegralViews.pack(stem(s, pw(fp)), "Find %s(%s)." % [s.name, N(b)], ans, wr, [],
		{"integrate-then-substitute": fit(s, RULE_POWER, pw(F), cond_text(s), Fa) + ["Then %s(%s) = %s + %s = %s." % [s.name, N(b), P(Fb), P(s.k), N(v)]],
		"accumulate-from-point": [
			"No C is needed: %s(%s) = %s(%s) + %s." % [s.name, N(b), s.name, N(x0), integral],
			"An antiderivative of the derivative is F(x) = %s, with F(%s) = %s and F(%s) = %s." % [pw(F), N(b), N(Fb), N(x0), N(Fa)],
			"The integral is %s − %s = %s." % [N(Fb), P(Fa), N(change)],
			tail],
		"gdc-start-plus-change": [
			"Only one value is wanted, so use %s(%s) = %s(%s) + %s." % [s.name, N(b), s.name, N(x0), integral],
			"Key in the definite integral on the GDC, with the derivative as the integrand and limits %s and %s." % [N(x0), N(b)],
			"The GDC reads %s." % N(change),
			tail]})


func u_negative_power(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var fp: Array = s.fp
	var shown := DifferentiationViews.SUM([[fp[0][0], "/" + DifferentiationViews.X(s.n)], [fp[1][0], "x"]])
	var lines := stem(s, shown)
	lines[0] += ", for x > 0"
	var rule := "Write the first term as %s, then integrate each power, raising it by 1 and dividing by the new power" % DifferentiationViews.T(fp[0][0], body(-s.n))
	return _powers(s, lines, find(s), [R_POINT_F, R_KEPT_C, R_DIFF, R_OLD_POWER], rule, "integrate-and-fit")


func u_parameter_from_gradient(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var c: int = s.c
	var x1: Q = s.x1
	var x0: Q = s.x0
	var y0: Q = s.y0
	var m: Q = s.m
	var F := AntiderivativeConditionSituation.anti(s.fp)
	var ter := bodied(F)
	var ans := fn(s, ter, s.k)
	var fv := AntiderivativeConditionSituation.val(F, x0)
	var shown := "a" + body(n) + konst(s, c)
	var bad: Q = y0.sub(c).div(AntiderivativeConditionSituation.power(x0, n))
	var badF := AntiderivativeConditionSituation.anti([[bad, n], [c, 0]])
	var lines := ["dy/dx = %s, where a is a constant." % shown, "The gradient of the curve at x = %s is %s." % [N(x1), N(m)],
		"The curve passes through %s." % Fmt.point(x0, y0)]
	if rep == "words":
		lines[0] = map_line(s, shown) + " Here a is a constant."
	var wr: Array = [opt(s, bodied(badF), y0.sub(AntiderivativeConditionSituation.val(badF, x0)), R_POINT), opt(s, ter, m.sub(AntiderivativeConditionSituation.val(F, x1)), R_GRAD_HEIGHT),
		opt(s, ter, 0, R_NO_C), kept(s, ter)]
	var with_a: String = Fmt.lead(AntiderivativeConditionSituation.power(x1, n)) + "a"
	return DefiniteIntegralViews.pack(lines, find(s), ans, wr, nudged(s, ter, s.k),
		{"integrate-then-substitute": [
			"The gradient goes into dy/dx, not into y: %s%s = %s, so %s = %s." % [with_a, konst(s, c), N(m), with_a, N(m.sub(c))],
			"So a = %s, and dy/dx = %s." % [N(s.K), pw(s.fp)],
			"Integrate: y = %s + C." % pw(F),
			"The point goes into y: %s + C = %s, so C = %s − %s = %s." % [N(fv), N(y0), N(y0), P(fv), N(s.k)]]})


func u_family_pick(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var fp: Array = s.fp
	var F := AntiderivativeConditionSituation.anti(fp)
	var x0: Q = s.x0
	var y0: Q = s.y0
	var fv := AntiderivativeConditionSituation.val(F, x0)
	var ans := DefiniteIntegralViews.val(s.k, false, "C = ")
	var wr: Array = [DefiniteIntegralViews.like(ans, y0, R_Y_IS_C), DefiniteIntegralViews.like(ans, y0.add(fv), R_SIGN), DefiniteIntegralViews.like(ans, y0.sub(AntiderivativeConditionSituation.val(fp, x0)), R_POINT)]
	var lines := ["%s′(x) = %s" % [s.name, pw(fp)], "The diagram shows y = %s + C for four values of C. The graph of %s passes through %s." % [pw(F), s.name, Fmt.point(x0, y0)]]
	return DefiniteIntegralViews.pack(lines, "Find the value of C for the graph of %s." % s.name, ans, wr, [],
		{"pick-from-family": [
			"Every curve here is y = %s moved up or down by C, so they never cross." % pw(F),
			"At x = %s, each curve is at height %s + C." % [N(x0), N(fv)],
			"The point is at height %s, which needs a shift of %s − %s = %s." % [N(y0), N(y0), P(fv), N(s.k)],
			"That is the curve labelled C = %s, the one through the marked point." % N(s.k)],
		"integrate-then-substitute": fit(s, RULE_POWER, pw(F), cond_text(s), fv)},
		family_graph(s, F))


## The curves F + C, each labelled at its right-hand end, with the given point marked.
static func family_graph(s: Dictionary, F: Array) -> Dictionary:
	var vx: int = s.vx
	var lo := float(vx - 3)
	var hi := float(vx + 3)
	var curves: Array = []
	var marks: Array = [[s.x0.n, s.y0.n, Fmt.point(s.x0, s.y0)]]
	var ylo := INF
	var yhi := -INF
	for c in s.cs:
		var f := func(x: float) -> float:
			return Q.of(F[0][0]).to_float() * x * x + Q.of(F[1][0]).to_float() * x + c.to_float()
		var line := GdcKit.curve(f, lo, hi)
		curves.append(line)
		for p in line:
			ylo = minf(ylo, p[1])
			yhi = maxf(yhi, p[1])
		marks.append([hi, f.call(hi), "C = " + N(c)])
	var g := Plot.spec(curves, marks, int(lo) - 1, int(hi) + 1, floori(ylo) - 1, ceili(yhi) + 1)
	g.one_colour = true
	return g


func u_accumulate_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var xs: Array = s.xs
	var ys: Array = s.ys
	var y0: Q = s.y0
	var area: Q = s.area
	var v := y0.add(area)
	var b: Q = s.b
	var ans := DefiniteIntegralViews.val(v, false, "%s(%s) = " % [s.name, N(b)])
	var wr: Array = [DefiniteIntegralViews.like(ans, area, R_NO_START), DefiniteIntegralViews.like(ans, Q.new(ys[3]), R_AT_END),
		DefiniteIntegralViews.like(ans, y0.add(AntiderivativeConditionSituation.signed_area(s, true)), R_ALL_POSITIVE)]
	var pts: Array = []
	var marks: Array = []
	for i in 4:
		pts.append([float(xs[i]), float(ys[i])])
		marks.append([xs[i], ys[i], Fmt.point(xs[i], ys[i])])
	var g := Plot.spec([pts], marks, -1, xs[3] + 1, mini(ys.min(), 0) - 1, maxi(ys.max(), 0) + 2)
	g.y_name = "%s′" % s.name
	var pieces: Array = []
	var parts: Array = []
	for i in range(s.from, 3):
		var part := Q.new((ys[i] + ys[i + 1]) * (xs[i + 1] - xs[i]), 2)
		pieces.append("%s to %s gives %s" % [N(xs[i]), N(xs[i + 1]), N(part)])
		parts.append(P(part))
	return DefiniteIntegralViews.pack(["The diagram shows the graph of %s′, which is made of straight lines." % s.name, "%s(%s) = %s" % [s.name, N(s.x0), N(y0)]],
		"Find %s(%s)." % [s.name, N(b)], ans, wr, [],
		{"accumulate-from-point": [
			"%s(%s) = %s(%s) + the integral of %s′ from %s to %s, which is the signed area under the graph." % [s.name, N(b), s.name, N(s.x0), s.name, N(s.x0), N(b)],
			"Area below the x-axis counts as negative. Each piece is width × (left height + right height) ÷ 2, even where it crosses the axis.",
			"From %s, so the integral is %s = %s." % ["; ".join(pieces), " + ".join(parts), N(area)],
			"%s(%s) = %s + %s = %s." % [s.name, N(b), N(y0), P(area), N(v)]]},
		g)


# ── Chains and standard results ──────────────────────────────

## cos(2x), sin(x − π/4): the bracket of a trig term.
static func inside(s: Dictionary) -> String:
	if s.has("sh"):
		var sh: Q = s.sh
		return "x %s %s" % ["+" if sh.sign() > 0 else "−", Fmt.pi(sh.abs_q())]
	return "%dx" % s.a


func _trig(s: Dictionary, lines: Array, rule: String, c0: Q, sign_c: Q, x_text: String, angle_text: String) -> Dictionary:
	var cos_fam: bool = s.fam == "cos"
	var name := "sin" if cos_fam else "cos"
	var bd := "%s(%s)" % [name, inside(s)]
	var ter: Array = [[c0, bd]]
	var ans := fn(s, ter, s.k)
	var y0: Q = s.y0
	var own: Q = s.sv if cos_fam else s.cv       # the value the term really takes
	var swapped: Q = s.cv if cos_fam else s.sv   # the other one, the slip
	var K: int = s.K
	var deriv: Q = Q.new(K).mul(s.cv if cos_fam else s.sv)
	var wr: Array = [opt(s, ter, y0.sub(c0.mul(swapped)), R_EXACT), opt(s, ter, y0.sub(deriv), R_POINT_F), kept(s, ter)]
	if s.ask == "trig-chain":
		wr.append(opt(s, [[sign_c.mul(K * s.a), bd]], y0.sub(sign_c.mul(K * s.a).mul(own)), R_MULT_A))
		wr.append(opt(s, [[sign_c.mul(K), bd]], y0.sub(sign_c.mul(K).mul(own)), R_NO_A))
	else:
		wr.append(opt(s, ter, 0, R_NO_C))
	if not cos_fam:
		wr.append(opt(s, [[c0.neg(), bd]], y0.add(c0.mul(own)), R_SIN_SIGN))
	var step2 := "Put in x = %s, where %s = %s, so %s(%s) = %s." % [x_text, inside(s), angle_text, name, angle_text, N(own)]
	var fv: Q = s.fv
	return DefiniteIntegralViews.pack(lines, find(s), ans, wr, nudged(s, ter, s.k),
		{"integrate-and-fit": ["%s: %s = %s + C." % [rule, lhs(s), DifferentiationViews.T(c0, bd)],
			step2,
			"So %s + C = %s." % [N(fv), N(y0)],
			"C = %s − %s = %s." % [N(y0), P(fv), N(s.k)]]})


func u_trig_chain(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var K: int = s.K
	var cos_fam: bool = s.fam == "cos"
	var sign_c := Q.new(1 if cos_fam else -1)
	var f := DifferentiationViews.T(K, "%s(%dx)" % [s.fam, a])
	var x_text := Fmt.pi(s.x0)
	var lines: Array = ["%s′(x) = %s" % [s.name, f], "%s(%s) = %s" % [s.name, x_text, N(s.y0)]]
	return _trig(s, lines, "Integrate%s, dividing by %d for the inside" % ["" if cos_fam else ": sin gives −cos", a], sign_c.mul(Q.new(K, a)), sign_c,
		x_text, Fmt.pi(s.x0.mul(a)))


func u_trig_shift(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var K: int = s.K
	var cos_fam: bool = s.fam == "cos"
	var sign_c := Q.new(1 if cos_fam else -1)
	var x_text := Fmt.pi(s.x0)
	var lines: Array = ["dy/dx = %s" % DifferentiationViews.T(K, "%s(%s)" % [s.fam, inside(s)]), "y = %s when x = %s" % [N(s.y0), x_text]]
	return _trig(s, lines, "Integrate%s; the inside has gradient 1, so nothing is divided" % ("" if cos_fam else ": sin gives −cos"), sign_c.mul(K), sign_c,
		x_text, Fmt.pi(s.theta))


func u_reciprocal_linear(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var K: int = s.K
	var a: int = s.a
	var b: int = s.lin_b
	var y0: Q = s.y0
	var c0 := Q.new(K, a)
	var inner: String = IntegrationViews.inner(a, b)
	var bd := "ln|%s|" % inner
	var ter: Array = [[c0, bd]]
	var f := "%s/(%s)" % [N(K), inner]
	var lines := stem(s, f)
	var asked := find(s)
	if rep == "words":
		lines = [map_line(s, f), lines[1]]
		asked = "Find the equation of the curve."
	var wr: Array = [opt(s, ter, y0.sub(c0), R_EXACT), opt(s, ter, y0.sub(K), R_POINT_F), kept(s, ter)]
	if absi(a) != 1:
		wr.append(opt(s, [[Q.new(K * a), bd]], y0, R_MULT_A))
		wr.append(opt(s, [[Q.new(K), bd]], y0, R_NO_A))
	return DefiniteIntegralViews.pack(lines, asked, fn(s, ter, s.k), wr, nudged(s, ter, s.k),
		{"integrate-and-fit": [
			"Integrate: 1/(ax + b) gives (1/a) ln|ax + b|, so %s = %s + C." % [lhs(s), DifferentiationViews.T(c0, bd)],
			"At x = %s, %s = 1, and ln 1 = 0." % [N(s.x0), inner],
			"So 0 + C = %s, and C = %s." % [N(y0), N(s.k)]]})


## A power or trig term beside B e^(ex), at x = 0.
func _with_exp(s: Dictionary, first: Array, f: String, lhs_rule: String, wr_more: Array, deriv0: Q) -> Dictionary:
	var B: int = s.B
	var e: int = s.e
	var y0: Q = s.y0
	var ebody: String = DifferentiationViews.E(e)
	var c1 := Q.new(B, e)
	var ter: Array = [first, [c1, ebody]]
	var ans := fn(s, ter, s.k)
	var wr: Array = [opt(s, ter, y0, R_EXACT), opt(s, ter, y0.sub(deriv0), R_POINT_F), kept(s, ter)] + wr_more
	if absi(e) != 1:
		var rest: Q = Q.of(s.fv).sub(c1)
		wr.append(opt(s, [first, [Q.new(B), ebody]], y0.sub(rest).sub(B), R_NO_A))
		wr.append(opt(s, [first, [Q.new(B * e), ebody]], y0.sub(rest).sub(B * e), R_MULT_A))
	var fv: Q = s.fv
	return DefiniteIntegralViews.pack(stem(s, f), find(s), ans, wr, nudged(s, ter, s.k),
		{"integrate-and-fit": ["%s: %s = %s + C." % [lhs_rule, lhs(s), DifferentiationViews.SUM(ter)],
			"At x = 0, e⁰ = 1, not 0%s." % (", and cos 0 = 1" if s.get("fam", "") == "sin" else (", and sin 0 = 0" if s.get("fam", "") == "cos" else "")),
			"So %s + C = %s." % [N(fv), N(y0)],
			"C = %s − %s = %s." % [N(y0), P(fv), N(s.k)]]})


func u_exp_and_power(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var A: int = s.A
	var f := DifferentiationViews.SUM([[A, body(n)], [s.B, DifferentiationViews.E(s.e)]])
	return _with_exp(s, [Q.new(A, n + 1), body(n + 1)], f, "Integrate each term", [], Q.new(s.B))


func u_trig_and_exp(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A: int = s.A
	var cos_fam: bool = s.fam == "cos"
	var f := DifferentiationViews.SUM([[A, "cos x" if cos_fam else "sin x"], [s.B, DifferentiationViews.E(s.e)]])
	var more: Array = []
	var first: Array = [Q.new(A if cos_fam else -A), "sin x" if cos_fam else "cos x"]
	if not cos_fam:
		var c1 := Q.new(s.B, s.e)
		more.append(opt(s, [[Q.new(A), "cos x"], [c1, DifferentiationViews.E(s.e)]], Q.of(s.y0).sub(A).sub(c1), R_SIN_SIGN))
	return _with_exp(s, first, f, "Integrate each term%s" % ("" if cos_fam else ": sin gives −cos"), more, Q.new(s.B + (A if cos_fam else 0)))


func u_exp_linear_decimal(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b0
	var x: float = s.x0.to_float()
	var y: float = s.y0.to_float()
	var k: float = s.k
	var ebody: String = DifferentiationViews.E(a)
	var ter: Array = [[Q.new(1, a), ebody], [b, "x"]]
	var ex: float = exp(a * x)
	var keep := func(c: float) -> Q: return GdcKit.qf(c)
	var ans := fn(s, ter, keep.call(k), true)
	var wr: Array = [opt(s, [[1, ebody], [b, "x"]], keep.call(y - ex - b * x), R_NO_A, true),
		opt(s, ter, keep.call(y - ex - b), R_POINT_F, true), opt(s, ter, 0, R_NO_C, true), kept(s, ter)]
	var e_text: String = "e^(%s)" % Fmt.dec(s.x0.mul(a))
	var fv: float = ex / a + b * x
	return DefiniteIntegralViews.pack(stem(s, DifferentiationViews.SUM([[1, ebody], [b, ""]])), find(s), ans, wr, nudged(s, ter, keep.call(k), true),
		{"integrate-and-fit": [
			"Integrate, dividing by %d for the e term: %s = %s + C." % [a, lhs(s), DifferentiationViews.SUM(ter)],
			"Put in x = %s: (1/%d)%s + %s = %s + %s = %s, to 6 s.f." % [W(s, s.x0), a, e_text, Fmt.dec(s.x0.mul(b)), GdcKit.W(ex / a), Fmt.dec(s.x0.mul(b)), GdcKit.W(fv)],
			"So %s + C = %s." % [GdcKit.W(fv), N(s.y0)],
			"C = %s − %s = %s, to 3 s.f." % [N(s.y0), GdcKit.W(fv), Fmt.sf(k)]]})


func u_log_inspection(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var K: int = s.K
	var n: int = s.n
	var y0: Q = s.y0
	var q: String = IntegrationViews.quad(s.a)
	var head := "%s(x) = " % s.name
	var mk := func(c: int, k: Q, d: int) -> Dictionary:
		var tail := "" if d == 0 else " − " + DifferentiationViews.T(d, "ln %d" % n)
		return DifferentiationViews.form(head + DifferentiationViews.T(c, "ln(%s)" % q) + konst(s, k) + tail,
			[head, {"slot": "c"}, " ln(%s) + " % q, {"slot": "k"}, " − ", {"slot": "d"}, " ln %d" % n], {"c": Q.new(c), "k": k, "d": Q.new(d)})
	var ans: Dictionary = mk.call(K, y0, K)
	var slope := Q.new(2 * K * s.x0.n, n)
	var wr: Array = [wrong(mk.call(2 * K, y0, 2 * K).values, R_NO_HALF), wrong(mk.call(K, y0, 0).values, R_Y_IS_C),
		wrong(mk.call(K, y0.sub(slope), 0).values, R_POINT_F), other(head + DifferentiationViews.T(K, "ln(%s)" % q) + " + C", R_KEPT_C)]
	var gen: Array = [mk.call(K, y0.add(1), K).values, mk.call(K, y0.sub(1), K).values, mk.call(K, y0.add(2), K).values, mk.call(K + 1, y0, K + 1).values]
	return DefiniteIntegralViews.pack(["%s′(x) = %s/(%s)" % [s.name, DifferentiationViews.T(2 * K, "x"), q], "The graph of y = %s(x) passes through %s." % [s.name, Fmt.point(s.x0, y0)]],
		find(s), ans, wr, gen,
		{"integrate-and-fit": [
			"The top is %d × the derivative of %s, which is 2x, so integrate by inspection: %s(x) = %s + C. %s is always positive, so no modulus is needed." % [K, q, s.name, DifferentiationViews.T(K, "ln(%s)" % q), q],
			"Put in %s(%s) = %s, where %s = %d: %s + C = %s." % [s.name, N(s.x0), N(y0), q.replace("x²", P(s.x0) + "²"), n, DifferentiationViews.T(K, "ln %d" % n), N(y0)],
			"So C = %s − %s." % [N(y0), DifferentiationViews.T(K, "ln %d" % n)]]})


func u_log_given_log(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var K: int = s.K
	var n: int = s.n
	var y0: Q = s.y0
	var q: String = Fmt.poly([1, s.lin_b, s.c])
	var top: String = Fmt.poly([2 * K, K * s.lin_b])
	var ln_q := "ln(%s)" % q
	var ter: Array = [[K, ln_q]]
	var head := "%s(x) = " % s.name
	var given: String = "%s + %s" % [N(y0), DifferentiationViews.T(K, "ln %d" % n)]
	var ans := fn(s, ter, y0)
	var wr: Array = [other(head + DifferentiationViews.T(2 * K, ln_q) + konst(s, y0) + " − " + DifferentiationViews.T(K, "ln %d" % n), R_NO_HALF),
		other(head + DifferentiationViews.T(K, ln_q) + konst(s, y0) + " + " + DifferentiationViews.T(K, "ln %d" % n), R_Y_IS_C), kept(s, ter)]
	return DefiniteIntegralViews.pack(["%s′(x) = (%s)/(%s)" % [s.name, top, q], "%s(%s) = %s" % [s.name, N(s.x0), given]], find(s), ans, wr, nudged(s, ter, y0),
		{"integrate-and-fit": [
			"The top is %s the derivative of the bottom, so integrate by inspection: %s(x) = %s + C. The bottom is always positive." % ["exactly" if K == 1 else "%d ×" % K, s.name, DifferentiationViews.T(K, ln_q)],
			"At x = %s the bottom is %d, so %s + C = %s." % [N(s.x0), n, DifferentiationViews.T(K, "ln %d" % n), given],
			"The logs cancel, so C = %s." % N(y0)]})


# ── A rate in a story ────────────────────────────────────────

func u_rate_model(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Array = RATES[s.ctx]
	var sym: String = c[1]
	var A: int = s.A
	var sg: int = s.sign
	var T: int = s.T
	var P0: int = s.P0
	var kq: Q = s.kq
	var k: float = kq.to_float()
	var v: float = s.Pt
	var decay := exp(-k * T)
	var change: float = v - P0
	var ans := DefiniteIntegralViews.val(v, true, "%s(%d) = " % [sym, T])
	var rate := "%se^(−%st)" % ["−%d" % A if sg < 0 else str(A), Fmt.dec(kq)]
	var wr: Array = [DefiniteIntegralViews.like(ans, float(P0 + sg * A * T), R_SAME_RATE), DefiniteIntegralViews.like(ans, P0 + sg * A * (1.0 - decay), R_NO_A)]
	# A count can't be negative, so the rate or the change alone is only an option when it rises.
	if sg > 0:
		wr.append(DefiniteIntegralViews.like(ans, change, R_NO_START))
		wr.append(DefiniteIntegralViews.like(ans, sg * A * decay, R_AT_END))
	var integral: String = "∫ from 0 to %d of %s dt" % [T, rate]
	var factor := "%d/%s" % [A, Fmt.dec(kq)]
	var after: float = P0 + sg * A / k
	var end_step := "So %s(%d) = %d + %s = %s, to 6 s.f." % [sym, T, P0, "(%s)" % GdcKit.W(change) if change < 0 else GdcKit.W(change), GdcKit.W(v)]
	var gen: Array = [P0 - change, v * 1.1, v * 0.9, v + 100.0, v - 100.0].map(func(x): return DefiniteIntegralViews.val(x, true, "%s(%d) = " % [sym, T]).values)
	return DefiniteIntegralViews.pack(["The number of %s changes at the rate d%s/dt = %s per %s, where t is measured in %s from the moment %s." % [c[0], sym, rate, c[2], c[3], c[4]],
		"At that moment %s(0) = %d." % [sym, P0]],
		"Use the model to find %s(%d), to 3 s.f." % [sym, T], ans, wr, gen,
		{"integrate-and-fit": [
			"Integrate, dividing by −%s: %s(t) = (%s%s)e^(−%st) + C." % [Fmt.dec(kq), sym, "−" if sg > 0 else "", factor, Fmt.dec(kq)],
			"At t = 0, e⁰ = 1, so C = %d %s %s = %s, to 6 s.f." % [P0, "+" if sg > 0 else "−", factor, GdcKit.W(after)],
			"Put in t = %d: e^(−%s) = %s, to 6 s.f." % [T, Fmt.dec(kq.mul(T)), GdcKit.W(decay)],
			"So %s(%d) = (%s%s) × %s + C = %s, to 6 s.f." % [sym, T, "−" if sg > 0 else "", factor, GdcKit.W(decay), GdcKit.W(v)]],
		"accumulate-from-point": [
			"No C is needed: %s(%d) = %s(0) + %s." % [sym, T, sym, integral],
			"The integral is (%s%s)(1 − e^(−%s)) = %s, to 6 s.f." % ["−" if sg < 0 else "", factor, Fmt.dec(kq.mul(T)), GdcKit.W(change)],
			end_step],
		"gdc-start-plus-change": [
			"Only one value is wanted, so use %s(%d) = %s(0) + %s." % [sym, T, sym, integral],
			"Key in the definite integral on the GDC, with %s as the integrand and limits 0 and %d." % [rate, T],
			"The GDC reads %s." % GdcKit.W(change),
			end_step]})


# ── From the second derivative ───────────────────────────────

## The two conditions, as the question gives them.
static func two_lines(s: Dictionary, f: String) -> Array:
	return ["%s″(x) = %s" % [s.name, f], "%s′(%s) = %s and %s(%s) = %s" % [s.name, N(s.x0), N(s.p), s.name, N(s.x0), N(s.q)]]


func _twice(s: Dictionary) -> Dictionary:
	var G := AntiderivativeConditionSituation.anti(s.fpp)
	var H := AntiderivativeConditionSituation.anti(G)
	var x0: Q = s.x0
	var p: Q = s.p
	var r: Q = s.q
	var c1: Q = s.c1
	var c2: Q = s.c2
	var bad1 := r.sub(AntiderivativeConditionSituation.val(G, x0))
	var bad2 := p.sub(AntiderivativeConditionSituation.val(H, x0)).sub(bad1.mul(x0))
	var GV := AntiderivativeConditionSituation.val(G, x0)
	var HV := AntiderivativeConditionSituation.val(H, x0).add(c1.mul(x0))
	return {"G": G, "H": H, "bad1": bad1, "bad2": bad2, "GV": GV, "HV": HV,
		"steps": [
			"Integrate once: %s′(x) = %s + C." % [s.name, pw(G)],
			"%s′(%s) = %s gives C = %s − %s = %s." % [s.name, N(x0), N(p), N(p), P(GV), N(c1)],
			"Integrate again, with a new constant: %s(x) = %s + D." % [s.name, DifferentiationViews.SUM(bodied(H) + [[c1, "x"]])],
			"%s(%s) = %s gives D = %s − %s = %s." % [s.name, N(x0), N(r), N(r), P(HV), N(c2)]]}


func u_second_derivative(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var w := _twice(s)
	var H: Array = bodied(w.H)
	var c1: Q = s.c1
	var c2: Q = s.c2
	var with := func(c: Q) -> Array: return H + [[c, "x"]]
	var ter: Array = with.call(c1)
	var ans := fn(s, ter, c2)
	var x0: Q = s.x0
	var wr: Array = [opt(s, ter, c1, R_ONE_C), opt(s, with.call(Q.new(0)), Q.of(s.q).sub(AntiderivativeConditionSituation.val(w.H, x0)), R_ONE_C),
		opt(s, with.call(w.bad1), w.bad2, R_STAGES), kept(s, ter)]
	return DefiniteIntegralViews.pack(two_lines(s, pw(s.fpp)), find(s), ans, wr, nudged(s, ter, c2), {"integrate-and-fit": w.steps})


func u_second_derivative_value(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var w := _twice(s)
	var H: Array = w.H
	var G: Array = w.G
	var b: Q = s.b
	var c1: Q = s.c1
	var c2: Q = s.c2
	var Hb := AntiderivativeConditionSituation.val(H, b)
	var v := Hb.add(c1.mul(b)).add(c2)
	var ans := DefiniteIntegralViews.val(v, false, "%s(%s) = " % [s.name, N(b)])
	var wr: Array = [DefiniteIntegralViews.like(ans, AntiderivativeConditionSituation.val(G, b).add(c1), R_STOPPED), DefiniteIntegralViews.like(ans, Hb.add(c1.mul(b)).add(c1), R_ONE_C),
		DefiniteIntegralViews.like(ans, Hb.add(Q.of(w.bad1).mul(b)).add(w.bad2), R_STAGES)]
	var steps: Array = w.steps.slice(0, 2) + ["Integrate again, with a new constant: %s(x) = %s + D, and %s" % [s.name, DifferentiationViews.SUM(bodied(H) + [[c1, "x"]]), w.steps[3]],
		"So %s(x) = %s, and %s(%s) = %s." % [s.name, DifferentiationViews.SUM(bodied(H) + [[c1, "x"], [c2, ""]]), s.name, N(b), N(v)]]
	return DefiniteIntegralViews.pack(two_lines(s, pw(s.fpp)), "Find %s(%s)." % [s.name, N(b)], ans, wr, [], {"integrate-and-fit": steps})


func u_second_derivative_exp(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A: int = s.A
	var B: int = s.B
	var p: Q = s.p
	var r: Q = s.q
	var c1: Q = s.c1
	var c2: Q = s.c2
	var ter := func(c: Q) -> Array: return [[Q.new(A, 6), "x³"], [B, "e^x"], [c, "x"]]
	var right: Array = ter.call(c1)
	var ans := fn(s, right, c2)
	var f := DifferentiationViews.SUM([[A, "x"], [B, "e^x"]])
	var wr: Array = [opt(s, right, c1, R_ONE_C), opt(s, ter.call(p), r, R_EXACT), opt(s, ter.call(r.sub(B)), p.sub(B), R_STAGES), kept(s, right)]
	var gx := DifferentiationViews.SUM([[Q.new(A, 2), "x²"], [B, "e^x"]])
	return DefiniteIntegralViews.pack(two_lines(s, f), find(s), ans, wr, nudged(s, right, c2),
		{"integrate-and-fit": [
			"Integrate once: %s′(x) = %s + C." % [s.name, gx],
			"e⁰ = 1, so %s′(0) = %s + C = %s, and C = %s − %s = %s." % [s.name, N(B), N(p), N(p), P(B), N(c1)],
			"Integrate again, with a new constant: %s(x) = %s + D." % [s.name, DifferentiationViews.SUM(right)],
			"%s(0) = %s + D = %s, so D = %s − %s = %s." % [s.name, N(B), N(r), N(r), P(B), N(c2)]]})
