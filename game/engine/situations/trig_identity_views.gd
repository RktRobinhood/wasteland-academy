class_name TrigIdentityViews
extends ExtensionViews
## The views on the `trig-identity` situation: one builder per unknown of t3-identity-values
## (FAL-727). Every answer is exact: a value (TrigKit) or a rewritten expression, a `form` answer.
##
## Representations: "equation" (written out) and "diagram" (the unit circle with θ's quadrant
## shaded, or a triangle with the angle 2θ).

const R_SIGN := "SL3.6.ratio-from-ratio#0"
const R_DROP_SQ := "SL3.6.ratio-from-ratio#1"
const R_ROOT := "SL3.6.ratio-from-ratio#2"
const R_SIN2 := "SL3.6.double-angle-values#0"
const R_COS2 := "SL3.6.double-angle-values#1"
const R_LOST := "SL3.6.double-angle-values#2"
const R_EXPAND := "SL3.6.simplify#0"
const R_PRODUCT := "SL3.6.simplify#1"

const UNKNOWNS := ["cos-from-sin", "sin-from-cos", "tan-from-ratio", "cos-from-tan", "sin2-from-ratio", "cos2-from-sin", "cos2-from-cos",
	"cos-from-cos2", "rewrite-in-sin", "single-cos", "product-sine", "expand-square", "max-after-rewrite"]
const BOUNDS := ["0 < θ < π/2", "π/2 < θ < π", "π < θ < 3π/2", "3π/2 < θ < 2π"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = TrigIdentitySituation.export(s)
	return out


static func T(v: Array) -> String:
	return TrigKit.text(v)


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## √top/n: the given ratio without its sign.
static func size_of(s: Dictionary) -> Array:
	return TrigKit.times(TrigKit.root(s.top), Q.new(1, s.n))


## sin θ and cos θ, with their signs: [given fn's value, the other's].
static func both(s: Dictionary) -> Array:
	var size := size_of(s)
	var left: int = s.n * s.n - s.top
	var other := TrigKit.times(TrigKit.root(left), Q.new(1, s.n))
	var given := "sin" if s.fn == "sin" else "cos"
	var rest := "cos" if s.fn == "sin" else "sin"
	return [TrigKit.times(size, TrigKit.sign_in(given, s.q)), TrigKit.times(other, TrigKit.sign_in(rest, s.q))]


static func sin_cos(s: Dictionary) -> Array:
	var b := both(s)
	return b if s.fn == "sin" else [b[1], b[0]]


## The line that gives θ, and the unit circle behind it, on the diagram.
static func show(rep: String, s: Dictionary, given: String) -> Dictionary:
	var v := {"lines": ["%s and %s." % [given, BOUNDS[s.q - 1]]], "graph": null}
	if rep == "diagram":
		var sc := sin_cos(s) if s.has("top") else tan_point(s)
		var th := atan2(TrigKit.fl(sc[0]), TrigKit.fl(sc[1]))
		v.lines = ["%s. The point P on the unit circle is at angle θ, in the shaded quadrant." % given]
		v.graph = {"kind": "unit-circle", "quadrant": s.q, "points": [{"x": TrigKit.fl(sc[1]), "y": TrigKit.fl(sc[0]), "label": "P"}], "angle": th if th > 0.0 else th + TAU, "angle_label": "θ", "radius": true}
	return v


## sin θ and cos θ of a θ fixed by tan θ.
static func tan_point(s: Dictionary) -> Array:
	var h := TrigKit.root(s.rise * s.rise + s.run * s.run)
	var one := TrigKit.V(1)
	var inv := TrigKit.over(one, h)
	return [TrigKit.times(inv, s.rise * TrigKit.sign_in("sin", s.q)), TrigKit.times(inv, s.run * TrigKit.sign_in("cos", s.q))]


static func quad_sign(fn: String, q: int) -> String:
	return "In quadrant %d, %s is %s." % [q, fn, "positive" if TrigKit.sign_in(fn, q) > 0 else "negative"]


## The other ratio, by a method, ending in its value. given: the value; want: its partner.
static func other_steps(id: String, s: Dictionary, fn: String, rest: String, given: Array, want: Array) -> Array:
	var size := TrigKit.times(want, TrigKit.sign_in(rest, s.q))
	var sq := TrigKit.sq(given)
	var left := TrigKit.plus(TrigKit.V(1), TrigKit.neg(sq))
	var mine := "%s θ = %s" % [rest, T(want)]
	match id:
		"pythagorean-identity":
			return ["%s²θ = 1 − %s²θ = 1 − %s = %s" % [rest, fn, T(sq), T(left)], "%s θ = ±√(%s) = ±%s" % [rest, T(left), T(size)], quad_sign(rest, s.q), mine]
		"right-triangle-sketch":
			var top := T(TrigKit.root(s.top))
			var side := T(TrigKit.root(s.n * s.n - s.top))
			return ["Sketch a right triangle with hypotenuse %d and one side %s, for the %s." % [s.n, top, "opposite" if fn == "sin" else "adjacent"],
				"Pythagoras: the third side is √(%d − %s) = %s." % [s.n * s.n, str(s.top), side], "The size is %s ÷ %d = %s. %s" % [side, s.n, T(size), quad_sign(rest, s.q)], mine]
	var axis := "x" if rest == "cos" else "y"
	var known := "y" if rest == "cos" else "x"
	return ["Put P = (x, y) on x² + y² = 1, with %s = %s." % [known, T(given)], "%s² = 1 − %s = %s, so %s = ±%s" % [axis, T(sq), T(left), axis, T(size)],
		"P is in quadrant %d, so %s %s 0." % [s.q, axis, ">" if TrigKit.sign_in(rest, s.q) > 0 else "<"], mine]


## Every method's working: the steps, then `more`, then the answer.
static func three(s: Dictionary, a: Dictionary, fn: String, rest: String, given: Array, want: Array, more: Array = []) -> Dictionary:
	var out := {}
	for id in ["pythagorean-identity", "right-triangle-sketch", "unit-circle-point"]:
		out[id] = method(other_steps(id, s, fn, rest, given, want) + more + [say(a)], a.values)
	return out


static func _sized(a: Dictionary, vs: Array) -> Array:
	return TrigKit.others(a, vs.filter(func(v): return not v.is_empty()))


func u_cos_from_sin(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b := both(s)
	var a := TrigKit.ans("cos θ = ", b[1])
	var v := show(rep, s, "sin θ = " + T(b[0]))
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "asked": "Find the exact value of cos θ."}
	out.wrongs = TrigKit.like(a, TrigKit.neg(b[1]), R_SIGN) + TrigKit.like(a, TrigKit.plus(TrigKit.V(1), TrigKit.neg(b[0])), R_DROP_SQ)
	out.generic = _sized(a, [b[0], TrigKit.neg(b[0]), TrigKit.over(b[0], b[1]), TrigKit.over(b[1], b[0]), TrigKit.sq(b[1])])
	out.methods = three(s, a, "sin", "cos", b[0], b[1])
	return out


func u_sin_from_cos(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b := both(s)
	var a := TrigKit.ans("sin θ = ", b[1])
	var v := show(rep, s, "cos θ = " + T(b[0]))
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "asked": "Find the exact value of sin θ."}
	var slip := TrigKit.plus(TrigKit.V(1), TrigKit.neg(size_of(s)))
	out.wrongs = TrigKit.like(a, TrigKit.neg(b[1]), R_SIGN) + TrigKit.like(a, TrigKit.times(slip, TrigKit.sign_in("sin", s.q)), R_ROOT)
	out.generic = _sized(a, [b[0], TrigKit.neg(b[0]), TrigKit.over(b[0], b[1]), TrigKit.over(b[1], b[0]), TrigKit.sq(b[1])])
	out.methods = three(s, a, "cos", "sin", b[0], b[1])
	return out


func u_tan_from_ratio(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b := both(s)
	var sc := sin_cos(s)
	var v0 := TrigKit.over(sc[0], sc[1])
	var a := TrigKit.ans("tan θ = ", v0)
	var v := show(rep, s, "%s θ = %s" % [s.fn, T(b[0])])
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "asked": "Find the exact value of tan θ."}
	out.wrongs = TrigKit.like(a, TrigKit.neg(v0), R_SIGN)
	out.generic = _sized(a, [TrigKit.over(sc[1], sc[0]), TrigKit.neg(TrigKit.over(sc[1], sc[0])), sc[0], sc[1], TrigKit.times(v0, 2)])
	var rest := "cos" if s.fn == "sin" else "sin"
	out.methods = three(s, a, s.fn, rest, b[0], b[1], ["tan θ = sin θ ÷ cos θ = %s" % T(v0)])
	return out


func u_cos_from_tan(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var sc := tan_point(s)
	var tn := Q.new(s.rise * TrigKit.sign_in("tan", s.q), s.run)
	var a := TrigKit.ans("cos θ = ", sc[1])
	var v := show(rep, s, "tan θ = " + Fmt.num(tn))
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "asked": "Find the exact value of cos θ."}
	var hyp: int = s.rise * s.rise + s.run * s.run
	var h := T(TrigKit.root(hyp))
	var size := TrigKit.times(sc[1], TrigKit.sign_in("cos", s.q))
	out.wrongs = TrigKit.like(a, TrigKit.neg(sc[1]), R_SIGN)
	out.generic = _sized(a, [sc[0], TrigKit.neg(sc[0]), TrigKit.V(Q.new(s.run, s.rise)), TrigKit.V(Q.new(s.run, s.rise + s.run)), TrigKit.V(Q.new(s.run, hyp))])
	var last := "cos θ = %s" % T(sc[1])
	out.methods = {"right-triangle-sketch": method(["Sketch a right triangle with opposite %d and adjacent %d." % [s.rise, s.run], "Pythagoras: hypotenuse² = %d, so it is %s." % [hyp, h],
			"The size of cos θ is %d ÷ %s = %s. %s" % [s.run, h, T(size), quad_sign("cos", s.q)], last, say(a)], a.values),
		"unit-circle-point": method(["P = (x, y) on x² + y² = 1 has y ÷ x = %s, so y = %s x." % [Fmt.num(tn), Fmt.num(tn)], "x²(1 + %s) = 1, so x = ±%s" % [Fmt.num(tn.sq()), T(size)],
			"P is in quadrant %d, so x %s 0." % [s.q, ">" if TrigKit.sign_in("cos", s.q) > 0 else "<"], last, say(a)], a.values)}
	return out


func u_sin2_from_ratio(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b := both(s)
	var sc := sin_cos(s)
	var d := TrigKit.times(TrigKit.mul(sc[0], sc[1]), 2)
	var a := TrigKit.ans("sin 2θ = ", d)
	var v := show(rep, s, "%s θ = %s" % [s.fn, T(b[0])])
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "asked": "Find the exact value of sin 2θ."}
	out.wrongs = TrigKit.like(a, TrigKit.times(sc[0], 2), R_SIN2)
	if TrigKit.fl(sc[1]) < 0.0:
		out.wrongs += TrigKit.like(a, TrigKit.times(TrigKit.mul(sc[0], TrigKit.neg(sc[1])), 2), R_LOST)
	out.generic = _sized(a, [TrigKit.neg(d), TrigKit.mul(sc[0], sc[1]), TrigKit.times(sc[1], 2), TrigKit.times(d, 2), TrigKit.plus(TrigKit.sq(sc[1]), TrigKit.neg(TrigKit.sq(sc[0])))])
	var rest := "cos" if s.fn == "sin" else "sin"
	var sub := "sin 2θ = 2 sin θ cos θ = 2 × %s × %s = %s" % [P2(sc[0]), P2(sc[1]), T(d)]
	out.methods = {"find-both-ratios": method(other_steps("pythagorean-identity", s, s.fn, rest, b[0], b[1]) + [sub, say(a)], a.values),
		"triangle": method(other_steps("right-triangle-sketch", s, s.fn, rest, b[0], b[1]) + [sub, say(a)], a.values)}
	return out


## A value in the working, in brackets where it is negative.
static func P2(v: Array) -> String:
	return "(%s)" % T(v) if TrigKit.fl(v) < 0.0 else T(v)


func u_cos2_from_sin(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b := both(s)
	var sq := TrigKit.sq(b[0])
	var d := TrigKit.plus(TrigKit.V(1), TrigKit.times(sq, -2))
	var a := TrigKit.ans("cos 2θ = ", d)
	var v := show(rep, s, "sin θ = " + T(b[0]))
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "asked": "Find the exact value of cos 2θ."}
	out.wrongs = TrigKit.like(a, TrigKit.plus(TrigKit.V(1), TrigKit.neg(sq)), R_COS2) + TrigKit.like(a, TrigKit.times(b[1], 2), R_COS2)
	out.generic = _sized(a, [TrigKit.neg(d), TrigKit.plus(TrigKit.times(sq, 2), TrigKit.V(-1)), sq, TrigKit.times(sq, 2), TrigKit.plus(d, TrigKit.V(1)), TrigKit.times(d, 2)])
	var cq := TrigKit.sq(b[1])
	var last := "cos 2θ = cos²θ − sin²θ = %s − %s = %s" % [T(cq), T(sq), T(d)]
	out.methods = {"pick-cos2-form": method(["sin θ is given, so use cos 2θ = 1 − 2sin²θ. cos θ isn't needed.", "sin²θ = %s" % T(sq), "cos 2θ = 1 − 2 × %s = %s" % [T(sq), T(d)], say(a)], a.values),
		"find-both-ratios": method(other_steps("pythagorean-identity", s, "sin", "cos", b[0], b[1]) + [last, say(a)], a.values),
		"triangle": method(other_steps("right-triangle-sketch", s, "sin", "cos", b[0], b[1]) + [last, say(a)], a.values)}
	return out


func u_cos2_from_cos(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b := both(s)
	var cq := TrigKit.sq(b[0])
	var d := TrigKit.plus(TrigKit.times(cq, 2), TrigKit.V(-1))
	var a := TrigKit.ans("cos 2θ = ", d)
	var v := show(rep, s, "cos θ = " + T(b[0]))
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "asked": "Find the exact value of cos 2θ."}
	out.wrongs = TrigKit.like(a, TrigKit.times(b[0], 2), R_COS2)
	out.generic = _sized(a, [TrigKit.neg(d), cq, TrigKit.times(cq, 2), TrigKit.plus(cq, TrigKit.V(-1)), TrigKit.plus(d, TrigKit.V(1)), TrigKit.times(d, 2)])
	var sq := TrigKit.sq(b[1])
	var last := "cos 2θ = cos²θ − sin²θ = %s − %s = %s" % [T(cq), T(sq), T(d)]
	out.methods = {"pick-cos2-form": method(["cos θ is given, so use cos 2θ = 2cos²θ − 1. sin θ isn't needed.", "cos²θ = %s" % T(cq), "cos 2θ = 2 × %s − 1 = %s" % [T(cq), T(d)], say(a)], a.values),
		"find-both-ratios": method(other_steps("pythagorean-identity", s, "cos", "sin", b[0], b[1]) + [last, say(a)], a.values),
		"triangle": method(other_steps("right-triangle-sketch", s, "cos", "sin", b[0], b[1]) + [last, say(a)], a.values)}
	return out


func u_cos_from_cos2(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c2: Q = s.cos2
	var half: Q = c2.add(1).div(2)
	var v := TrigKit.sqrt_q(half)
	var a := TrigKit.ans("cos θ = ", v)
	var out := {"answer": a, "asked": "Find the exact value of cos θ."}
	var first: Array = []
	if rep == "diagram":
		out.lines = ["In triangle ABC, AB = %d cm, AC = %d cm, BC = %d cm and angle BAC = 2θ." % [s.c, s.b, s.a]]
		var ang := acos(c2.to_float())
		out.diagram = {"vertices": {"A": [0.0, 0.0], "B": [float(s.c), 0.0], "C": [s.b * cos(ang), s.b * sin(ang)]},
			"sides": [{"side": "a", "label": "%d cm" % s.a}, {"side": "b", "label": "%d cm" % s.b}, {"side": "c", "label": "%d cm" % s.c}],
			"angles": [{"at": "A", "label": "2θ"}, {"at": "B", "label": ""}, {"at": "C", "label": ""}]}
		first = ["The cosine rule: cos 2θ = (%d² + %d² − %d²) ÷ (2 × %d × %d) = %s" % [s.b, s.c, s.a, s.b, s.c, Fmt.num(c2)]]
	else:
		out.lines = ["cos 2θ = %s and 0 < θ < π/2." % Fmt.num(c2)]
	out.wrongs = TrigKit.like(a, TrigKit.V(c2.div(2)), R_COS2)
	out.generic = _sized(a, [TrigKit.V(half), TrigKit.neg(v), TrigKit.sqrt_q(Q.new(1).sub(c2).div(2)), TrigKit.V(c2), TrigKit.times(v, 2), TrigKit.V(half.div(2))])
	out.methods = {"pick-cos2-form": method(first + ["cos θ is wanted, so use cos 2θ = 2cos²θ − 1.", "2cos²θ = 1 + %s = %s, so cos²θ = %s" % [P(c2), Fmt.num(c2.add(1)), Fmt.num(half)],
		"θ is acute, so take the positive root: cos θ = %s" % T(v), say(a)], a.values)}
	return out


# ── Rewriting ────────────────────────────────────────────────

## "−2 sin²x + 3 sin x + 1": a quadratic in sin x or cos x.
static func quad_text(c: Array, fn: String) -> String:
	var out := _term(c[0], fn + "²x", true)
	if c[1] != 0:
		out += _term(c[1], fn + " x", false)
	if c[2] != 0:
		out += " %s %d" % ["+" if c[2] > 0 else "−", absi(c[2])]
	return out


static func _term(c: int, body: String, first: bool) -> String:
	var size := "" if absi(c) == 1 else "%d " % absi(c)
	if first:
		return ("−" if c < 0 else "") + size + body
	return " %s %s%s" % ["+" if c > 0 else "−", size, body]


static func rewrite_of(s: Dictionary, double: bool) -> Array:
	if s.base == "cos" and double:
		return [2 * s.p, s.m, s.k - s.p]
	return [-2 * s.p if double else -s.p, s.m, s.p + s.k]


static func source_text(s: Dictionary) -> String:
	var other := "cos" if s.base == "sin" else "sin"
	var lead := "%d cos 2x" % s.p if s.src == "double" else "%d %s²x" % [s.p, other]
	return lead + _term(s.m, s.base + " x", false) + ("" if s.k == 0 else " %s %d" % ["+" if s.k > 0 else "−", absi(s.k)])


static func quad_slots(c: Array) -> Dictionary:
	return {"a": Q.new(c[0]), "b": Q.new(c[1]), "c": Q.new(c[2])}


func u_rewrite_in_sin(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var fn: String = s.base
	var dbl: bool = s.src == "double"
	var c := rewrite_of(s, dbl)
	var a := DifferentiationViews.form(quad_text(c, fn), [{"slot": "a"}, " %s²x + " % fn, {"slot": "b"}, " %s x + " % fn, {"slot": "c"}], quad_slots(c))
	var out := {"answer": a, "lines": [source_text(s)], "asked": "Write this in the form a %s²x + b %s x + c." % [fn, fn]}
	var alt := func(cs: Array, ref: String = "") -> Dictionary: return DifferentiationViews.alt(quad_text(cs, fn), ref, quad_slots(cs))
	out.wrongs = []
	if dbl:
		var drop: Array = [-s.p, s.m, s.p + s.k] if fn == "sin" else [s.p, s.m, s.k]
		out.wrongs.append(alt.call(drop, R_COS2))
	var gens: Array = [[-c[0], c[1], c[2]], [c[0], -c[1], c[2]], [c[0], c[1], c[2] + 2], [c[0], c[1], c[2] - 1], [c[0], c[1], -c[2]], [c[0] * 2, c[1], c[2]], [c[0], c[1], c[2] + 1]]
	out.generic = gens.filter(func(g): return g[0] != 0 and g[1] != 0 and g != c).map(func(g): return alt.call(g).values)
	var other := "cos" if fn == "sin" else "sin"
	var use: String
	if dbl:
		use = "cos 2x = 1 − 2sin²x" if fn == "sin" else "cos 2x = 2cos²x − 1"
	else:
		use = "%s²x = 1 − %s²x" % [other, fn]
	var x := Q.new(1, 2) if fn == "sin" else Q.new(0)
	var at := Fmt.pi(x)
	var left: int = s.m + s.k + s.p * _lead_at(s)
	out.methods = {"pattern-match": method(["Only one term isn't in %s x, so swap it: %s." % [fn, use], "Multiply by %d and collect the numbers." % s.p, say(a)], a.values),
		"test-value": method(["Use %s and collect: %s." % [use, Answer.text(a)], "Test x = %s: the first form gives %s." % [at, N(left)],
			"The new form gives %s + %s + %s = %s, and they agree." % [P(c[0]), P(c[1]), P(c[2]), N(c[0] + c[1] + c[2])], say(a)], a.values)}
	return out


## cos²x, sin²x or cos 2x at the test value (x = π/2 for sin x, x = 0 for cos x).
static func _lead_at(s: Dictionary) -> int:
	if s.src == "double":
		return -1 if s.base == "sin" else 1
	return 0


## "cos 2x", "cos 4x": with the inner multiple.
static func inner(fn: String, n: int) -> String:
	return "%s %sx" % [fn, "" if n == 1 else str(n)]


## 3 cos 2x, as a `form` answer: k and n typed.
static func wave_ans(fn: String, k: int, n: int) -> Dictionary:
	return DifferentiationViews.form(wave_text(fn, k, n), [{"slot": "k"}, " %s " % fn, {"slot": "n"}, "x"], {"k": Q.new(k), "n": Q.new(n)})


static func wave_text(fn: String, k: int, n: int) -> String:
	return ("" if k == 1 else str(k) + " ") + inner(fn, n)


static func wave_alt(fn: String, k: int, n: int, ref: String = "", typed: bool = true) -> Dictionary:
	return DifferentiationViews.alt(wave_text(fn, k, n), ref, {"k": Q.new(k), "n": Q.new(n)} if typed else {})


func u_single_cos(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var w: int = s.w
	var n := 2 * w
	var a := wave_ans("cos", k, n)
	var mid := inner(s.from, w)
	var head := "%d − %d %s²%sx" % [k, 2 * k, s.from, "" if w == 1 else str(w)] if s.from == "sin" else "%d cos²%sx − %d" % [2 * k, "" if w == 1 else str(w), k]
	var out := {"answer": a, "lines": [head], "asked": "Write this in the form a cos bx, with a and b whole numbers."}
	out.wrongs = []
	out.generic = [wave_alt("cos", 2 * k, n).values, wave_alt("cos", k, w).values, wave_alt("sin", k, n, "", false).values, wave_alt("cos", 2 * k, w).values, wave_alt("cos", k, 2 * n).values]
	var form := "1 − 2sin²u" if s.from == "sin" else "2cos²u − 1"
	var u := "%sx" % ("" if w == 1 else str(w))
	out.methods = {"pattern-match": method(["Take out the %d: %d(%s)" % [k, k, form.replace("u", u)], "%s = cos 2u, with u = %s." % [form, u], say(a)], a.values),
		"test-value": method(["Take out the %d: this is %d cos %dx by cos 2u = %s." % [k, k, n, form], "Test x = 0: the first form gives %d, and %d cos 0 = %d." % [k, k, k], say(a)], a.values)}
	return out


func u_product_sine(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var w: int = s.w
	var n := 2 * w
	var two := 2 * k
	var a := wave_ans("sin", k, n)
	var u := "%sx" % ("" if w == 1 else str(w))
	var out := {"answer": a, "lines": ["%d sin %s cos %s" % [two, u, u]], "asked": "Write this in the form a sin bx, with a and b whole numbers."}
	out.wrongs = [wave_alt("sin", two, n, R_PRODUCT)]
	out.generic = [wave_alt("sin", k, w).values, wave_alt("sin", two, w).values, wave_alt("cos", k, n, "", false).values, wave_alt("sin", k, 2 * n).values]
	var test := Q.new(1, 4 * w)
	out.methods = {"pattern-match": method(["sin 2u = 2 sin u cos u, so %d sin %s cos %s is %d × 2 sin %s cos %s." % [two, u, u, k, u, u], "That is %d sin 2(%s)." % [k, u], say(a)], a.values),
		"test-value": method(["sin 2u = 2 sin u cos u gives %d sin %dx." % [k, n], "Test x = %s: sin and cos of %s are both √2/2, so the first form gives %d, and %d sin(π/2) = %d." % [Fmt.pi(test), "π/4", k, k, k], say(a)], a.values)}
	return out


## k + b sin 2x, as it reads.
static func expand_text(k: int, b: int) -> String:
	return "%d %s %ssin 2x" % [k, "+" if b > 0 else "−", "" if absi(b) == 1 else str(absi(b)) + " "]


func u_expand_square(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var b := -k if s.minus else k
	var a := DifferentiationViews.form(expand_text(k, b), [{"slot": "a"}, " + ", {"slot": "b"}, " sin ", {"slot": "c"}, "x"], {"a": Q.new(k), "b": Q.new(b), "c": Q.new(2)})
	var sign := "−" if s.minus else "+"
	var head := "%s(sin x %s cos x)²" % ["" if k == 1 else str(k), sign]
	var out := {"answer": a, "lines": [head], "asked": "Write this in the form a + b sin cx, with a, b and c whole numbers."}
	out.wrongs = [DifferentiationViews.alt(str(k), R_EXPAND)]
	var alt := func(x: int, y: int) -> Dictionary: return DifferentiationViews.alt(expand_text(x, y), "", {"a": Q.new(x), "b": Q.new(y), "c": Q.new(2)}).values
	out.generic = [alt.call(k, -b), alt.call(2 * k, b), alt.call(k, 2 * b), alt.call(k + 1, b), alt.call(k, b + (1 if b > 0 else -1))]
	var mid := "sin²x %s 2 sin x cos x + cos²x" % sign
	var one := "%d(1 %s sin 2x)" % [k, sign] if k > 1 else "1 %s sin 2x" % sign
	out.methods = {"expand-then-identity": method(["Expand the square: %s" % mid, "sin²x + cos²x = 1 and 2 sin x cos x = sin 2x, which leaves %s." % one, say(a)], a.values),
		"test-value": method(["Expanding and using the identities gives %s." % expand_text(k, b), "Test x = π/4: sin x and cos x are equal, so the first form gives %d, and %s." % [0 if s.minus else 2 * k, "the new form gives %d" % (k + b)], say(a)], a.values)}
	return out


func u_max_after_rewrite(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var w: int = s.w
	var two := 2 * k
	var top: int = k + s.d
	var a := Answer.make("number", {"v": Q.new(top)}, {}, "maximum = ")
	a.exact = true
	var u := "%sx" % ("" if w == 1 else str(w))
	var tail := "" if s.d == 0 else " %s %d" % ["+" if s.d > 0 else "−", absi(s.d)]
	var out := {"answer": a, "lines": ["f(x) = %d sin %s cos %s%s" % [two, u, u, tail]], "asked": "Find the maximum value of f."}
	out.wrongs = [wrong({"v": Q.new(two + s.d)}, R_PRODUCT)]
	out.generic = [{"v": Q.new(s.d)}, {"v": Q.new(k)}, {"v": Q.new(two)}, {"v": Q.new(top + 1)}, {"v": Q.new(top - 1)}, {"v": Q.new(top + 2)}, {"v": Q.new(s.d - k)}].filter(func(g): return g.v.to_float() != float(top))
	var rewrite := "%d sin %s cos %s = %d sin %dx" % [two, u, u, k, 2 * w]
	out.methods = {"pattern-match": method(["Rewrite with sin 2u = 2 sin u cos u: %s" % rewrite, "The sine has maximum 1, so f has maximum %d + %s." % [k, P(s.d)], say(a)], a.values),
		"test-value": method(["Rewrite: %s, which is largest where sin %dx = 1." % [rewrite, 2 * w], "Test x = %s: f = %d × 1%s = %s" % [Fmt.pi(Q.new(1, 4 * w)), k, tail, N(top)], say(a)], a.values)}
	return out
