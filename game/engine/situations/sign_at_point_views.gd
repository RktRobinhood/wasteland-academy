class_name SignAtPointViews
extends ExtensionViews
## The views on the `sign-at-point` situation: one builder per unknown of t5-ext-sign-at-point
## (FAL-777). Each answer is a pick of four: a direction and its reason. The right reason is the
## asked method's: the sign of f′(a), the GDC's gradient, or f just either side of a. The slips
## read the sign of f(a), give "the graph goes up" as the reason, or get f′(a) wrong.
##
## Representations: "equation" (f(x), or f′(x) in factors) and "words" (a quantity modelled by a
## cubic in t).

const SK := "SL5.2.sign-at-point#"
const R_SIGN_OF_F := SK + "0"
const R_GRAPH_UP := SK + "1"
const T := "t5-ext-sign-at-point#"
const R_POWER_KEPT := T + "2"
const R_BRACKET_FLIP := T + "3"
const UNKNOWNS := ["from-formula", "in-context", "from-derivative", "gdc-check"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = ["true-false-reason"]
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	if not has(unknown):
		return []
	return [2] if unknown == "gdc-check" else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = SignAtPointSituation.export(s)
	return out


static func pick(right: String, tagged: Array, fillers: Array = []) -> Dictionary:
	var out := InverseRuleViews.choose(right, tagged, fillers)
	out.fillers = out.get("fillers", []) + out.get("generic", [])
	out.erase("generic")
	return out


static func tag(text: String, ref: String) -> Dictionary:
	return InverseRuleViews.tag(text, ref)


static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func S(x: float) -> String:
	return GdcKit.S(x)


## "> 0" or "< 0" after a value.
static func cmp(v: Q) -> String:
	return "> 0" if v.sign() > 0 else "< 0"


## f′(a) with its sign: "f′(2) = 7 > 0".
static func says(g: String, a: Variant, v: Q) -> String:
	return "%s′(%s) = %s %s" % [g, N(a), N(v), cmp(v)]


## The working and the answer by f just either side of a: f(a − 0.01) and f(a + 0.01).
static func neighbours(g: String, letter: String, c: Array, a: int, up: String, down: String) -> Dictionary:
	var lo := Q.new(100 * a - 1, 100)
	var hi := Q.new(100 * a + 1, 100)
	var flo := SignAtPointSituation.value(c, lo)
	var fhi := SignAtPointSituation.value(c, hi)
	var rises := flo.lt(fhi)
	var right := ("%s, because %s(%s) < %s(%s)" % [up, g, D(lo), g, D(hi)]) if rises else ("%s, because %s(%s) > %s(%s)" % [down, g, D(lo), g, D(hi)])
	return {"right": right, "steps": ["%s(%s) = %s and %s(%s) = %s." % [g, D(lo), D(flo), g, D(hi), D(fhi)],
		"From %s = %s to %s = %s the output %s." % [letter, D(lo), letter, D(hi), "goes up" if rises else "goes down"], right + "."]}


## The slips of a cubic at a: f(a) for f′(a), "the graph goes up", and x³'s power kept.
static func cubic_slips(g: String, c: Array, a: int, up: String, down: String) -> Array:
	var fa := SignAtPointSituation.value(c, a)
	var fp := SignAtPointSituation.slope(c, a)
	# The x³ term, or the x² term, differentiated with its power left the same.
	var kept := [Q.new(3 * c[0] * a * a * a + 2 * c[1] * a + c[2]), Q.new(3 * c[0] * a * a + 2 * c[1] * a * a + c[2])]
	var word := func(v: Q) -> String: return up if v.sign() > 0 else down
	var out := [tag("%s, because %s(%s) = %s %s" % [word.call(fa), g, N(a), N(fa), cmp(fa)], R_SIGN_OF_F),
		tag("%s, because the graph %s" % [word.call(fp), "goes up" if fp.sign() > 0 else "goes down"], R_GRAPH_UP)]
	for k: Q in kept:
		if not k.is_zero() and not k.eq(fp):
			out.append(tag("%s, because %s" % [word.call(k), says(g, a, k)], R_POWER_KEPT))
	return out


func _cubic(g: String, c: Array, a: int, up: String, down: String, lines: Array, asked: String, letter: String) -> Dictionary:
	var fp := SignAtPointSituation.slope(c, a)
	var dc := [3 * c[0], 2 * c[1], c[2]]
	var word: String = up if fp.sign() > 0 else down
	var nb := neighbours(g, letter, c, a, up, down)
	var right: String = nb.right if angle == "compare-neighbours" else "%s, because %s" % [word, says(g, a, fp)]
	var out := {"lines": lines, "asked": asked}
	out.merge(pick(right, cubic_slips(g, c, a, up, down), [turning(g, letter, a)]))
	out.methods = {
		"evaluate-derivative": method(["%s′(%s) = %s." % [g, letter, Fmt.poly(dc, letter)],
			"%s′(%s) = %s." % [g, N(a), N(fp)], right + "." if angle != "compare-neighbours" else "%s′(%s) %s, which gives the same answer: %s." % [g, N(a), cmp(fp), right]], {"v": right}),
		"compare-neighbours": method(nb.steps, {"v": right}),
	}
	if angle != "compare-neighbours":
		out.methods["compare-neighbours"].steps[-1] = "That gives the same answer: %s." % right
	return out


func u_from_formula(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _cubic("f", s.c, s.a, "Increasing", "Decreasing", ["f(x) = " + Fmt.poly(s.c)],
		"Is f increasing or decreasing at x = %s? Give a reason." % N(s.a), "x")


func u_in_context(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = SignAtPointSituation.CONTEXTS[s.ctx]
	var line := "%s is modelled by %s(t) = %s, where t is the time in hours, 0 ≤ t ≤ %d." % [c.what, c.q, Fmt.poly(s.c, "t"), c.end]
	var out := _cubic(c.q, s.c, s.a, c.up.capitalize(), c.down.capitalize(), [line],
		"Is the %s %s or %s at t = %s? Give a reason." % [c.name, c.up, c.down, N(s.a)], "t")
	out.fn_name = c.q
	out.titles = {"evaluate-derivative": "Evaluate %s′(a) and use its sign" % c.q}
	return out


func u_from_derivative(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var a: int = s.a
	var fp := Q.new(k * (a - s.p) * (a - s.r))
	var fac := "%s(x %s)(x %s)" % ["" if k == 1 else ("−" if k == -1 else N(k)), signed_n(-s.p), signed_n(-s.r)]
	var sub := "%s(%s %s)(%s %s)" % ["" if k == 1 else ("−" if k == -1 else N(k)), N(a), signed_n(-s.p), N(a), signed_n(-s.r)]
	var word := "Increasing" if fp.sign() > 0 else "Decreasing"
	var right := "%s, because f′(%s) = %s = %s %s" % [word, N(a), sub, N(fp), cmp(fp)]
	var tagged := [tag("%s, because the graph %s" % [word, "goes up" if fp.sign() > 0 else "goes down"], R_GRAPH_UP)]
	for flip in [[-s.p, s.r], [s.p, -s.r]]:
		var v := Q.new(k * (a - flip[0]) * (a - flip[1]))
		if not v.is_zero() and not v.eq(fp):
			tagged.append(tag("%s, because f′(%s) = %s %s" % ["Increasing" if v.sign() > 0 else "Decreasing", N(a), N(v), cmp(v)], R_BRACKET_FLIP))
	var out := {"lines": ["f′(x) = " + fac], "asked": "Is f increasing or decreasing at x = %s? Give a reason." % N(a)}
	out.merge(pick(right, tagged, [turning("f", "x", a)]))
	out.methods = {"evaluate-derivative": method(["Substitute x = %s into f′(x) = %s." % [N(a), fac], "f′(%s) = %s = %s." % [N(a), sub, N(fp)], right + "."], {"v": right})}
	return out


## The filler: no slip says f′(a) = 0 here.
static func turning(g: String, letter: String, a: Variant) -> String:
	return "Neither: %s has a turning point at %s = %s" % [g, letter, a if a is String else N(a)]


## "+ 3" or "− 3" for a bracket.
static func signed_n(v: int) -> String:
	return ("+ %d" % v) if v >= 0 else ("− %d" % -v)


func u_gdc_check(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: String
	if s.family == "exp":
		f = DifferentiationViews.SUM([[1, "e^x"], [-s.b, "x²"], [s.d, ""]])
	else:
		f = DifferentiationViews.SUM([[s.c, "ln x"], [-s.b, "x"], [s.d, ""]]) + ", x > 0"
	var at := "%.1f" % s.a
	var up: bool = s.fp > 0.0
	var word := "Increasing" if up else "Decreasing"
	var right := "%s, because the GDC gives f′(%s) = %s %s" % [word, at, S(s.fp), "> 0" if up else "< 0"]
	var fa_up: bool = s.fa > 0.0
	var tagged := [tag("%s, because f(%s) = %s %s" % ["Increasing" if fa_up else "Decreasing", at, S(s.fa), "> 0" if fa_up else "< 0"], R_SIGN_OF_F),
		tag("%s, because the graph %s" % [word, "goes up" if up else "goes down"], R_GRAPH_UP)]
	var out := {"lines": ["f(x) = " + f], "asked": "Is f increasing or decreasing at x = %s? Give a reason." % at}
	out.merge(pick(right, tagged, [turning("f", "x", at)]))
	out.methods = {"gdc-dydx": method(["Graph y = f(x) on the GDC and find dy/dx at x = %s." % at, "The GDC gives %s." % S(s.fp), right + "."], {"v": right})}
	return out
