class_name HenceIntegralViews
extends ExtensionViews
## The views on the `hence-integral` situation: one builder per unknown of t5-ext-hence-integral
## (FAL-776). A derivative result is given ("d/dx (x ln x) = ln x + 1"), and the answer is a pick of
## four expressions: the integral read backwards with its constant factor divided out or its extra
## term moved across, against the derivative itself, a term left where it was, a missing + C or a
## factor not divided. Error-spot shows a student's working with one slip; method-pick offers
## methods that don't work on a product.
##
## Representation: "equation" (the result written out, then the integral).

const SK := "SL5.10.hence-from-derivative#"
const R_PRODUCT := "SL5.6.product-rule#0"
const R_ONE_TERM := "SL5.6.product-rule#1"
const R_DERIVATIVE := SK + "0"
const R_NOT_MOVED := SK + "1"
const R_NO_C := SK + "2"
const R_NOT_DIVIDED := "t5-ext-hence-integral#5"
const R_MULTIPLIED := "t5-ext-hence-integral#6"
const R_SIGN := "t5-ext-hence-integral#7"
const UNKNOWNS := ["find-derivative", "adjust-factor", "move-extra-term", "hence-definite", "pick-the-derivative"]
const DIFF_WRONGS := [
	{"name": "Multiply the derivatives of the two factors", "why": "(uv)′ is u′v + uv′, not u′v′"},
	{"name": "Differentiate only the second factor", "why": "both factors change with x, so both terms are needed"},
	{"name": "Reverse the chain rule", "why": "this is a product to differentiate, not an integral to find"},
]
const INT_WRONGS := [
	{"name": "Integrate each factor separately", "why": "the integral of a product is not the product of the integrals"},
	{"name": "Use the power rule on the whole integrand", "why": "the integrand is not a power of x"},
	{"name": "Take the derivative result as the integral", "why": "a derivative result has to be read backwards, with its extra term or constant factor sorted out"},
]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = ["method-pick"] + (["error-spot"] if u in ["adjust-factor", "move-extra-term"] else [])
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = HenceIntegralSituation.export(s)
	out.pick_wrongs = DIFF_WRONGS if unknown == "find-derivative" else INT_WRONGS
	return out


# ── Writing things ───────────────────────────────────────────

static func SUM(terms: Array) -> String:
	return DifferentiationViews.SUM(terms)


static func T(c: Variant, body: String) -> String:
	return DifferentiationViews.T(c, body)


static func q(a: int, b: int = 1) -> Q:
	return Q.new(a, b)


static func Ek(k: int) -> String:
	return "e^x" if k == 1 else "e^(%dx)" % k


static func Sk(k: int) -> String:
	return "sin x" if k == 1 else "sin(%dx)" % k


static func Ck(k: int) -> String:
	return "cos x" if k == 1 else "cos(%dx)" % k


## "∫ (ln x + 1) dx", brackets round a sum.
static func integral(f: String) -> String:
	return "∫ %s dx" % IntegrationViews.wrapped(f)


static func plus_c(t: String) -> String:
	return t + " + C"


static func pick(right: String, tagged: Array, plain: Array) -> Dictionary:
	return InverseRuleViews.choose(right, tagged, plain)


static func tag(text: String, ref: String) -> Dictionary:
	return InverseRuleViews.tag(text, ref)


## A product family: F, F′ as [u′v, uv′], the term of F′ the integral is about (tt) and its
## integral (tt_int), the other term (other) and its integral (other_int), and the integral asked
## for: target = tt ÷ k, answer = tt_int ÷ k, all as [coefficient, body] terms.
static func product(fam: String, k: int) -> Dictionary:
	var x_e := "x " + Ek(k)
	match fam:
		"xlnx":
			return {"F": "x ln x", "v": "ln x", "dv": [[1, "/x"]], "uv": [[1, "ln x"]], "udv": [[1, ""]],
				"tt": [[1, "ln x"]], "other": [[1, ""]], "other_int": [[1, "x"]], "tt_int": [[1, "x ln x"], [-1, "x"]], "k": 1}
		"xekx":
			return {"F": x_e, "v": Ek(k), "dv": [[k, Ek(k)]], "uv": [[1, Ek(k)]], "udv": [[k, x_e]],
				"tt": [[k, x_e]], "other": [[1, Ek(k)]], "other_int": [[q(1, k), Ek(k)]], "tt_int": [[1, x_e], [q(-1, k), Ek(k)]], "k": k}
		"xsin":
			return {"F": "x " + Sk(k), "v": Sk(k), "dv": [[k, Ck(k)]], "uv": [[1, Sk(k)]], "udv": [[k, "x " + Ck(k)]],
				"tt": [[k, "x " + Ck(k)]], "other": [[1, Sk(k)]], "other_int": [[q(-1, k), Ck(k)]], "tt_int": [[1, "x " + Sk(k)], [q(1, k), Ck(k)]], "k": k}
		_:
			return {"F": "x " + Ck(k), "v": Ck(k), "dv": [[-k, Sk(k)]], "uv": [[1, Ck(k)]], "udv": [[-k, "x " + Sk(k)]],
				"tt": [[k, "x " + Sk(k)]], "other": [[1, Ck(k)]], "other_int": [[q(1, k), Sk(k)]], "tt_int": [[q(1, k), Sk(k)], [-1, "x " + Ck(k)]], "k": k}


static func scaled(terms: Array, by: Q) -> Array:
	return terms.map(func(t): return [Q.of(t[0]).mul(by), t[1]])


static func flipped_last(terms: Array) -> Array:
	var out := terms.duplicate(true)
	out[-1] = [Q.of(out[-1][0]).neg(), out[-1][1]]
	return out


## A composite family: F, F′ = factor × core, and core's body.
static func composite(s: Dictionary) -> Dictionary:
	var c: int = s.c
	match s.fam:
		"ex2":
			var F := "e^(x²)" if s.p == 1 else "e^(%dx²)" % s.p
			return {"F": F, "core": "x " + F, "factor": 2 * s.p}
		"lnq":
			return {"F": "ln(x² + %d)" % c, "core": "x/(x² + %d)" % c, "factor": 2}
		"pow":
			return {"F": "(x² + %d)%s" % [c, Fmt.sup(s.n)], "core": "x(x² + %d)%s" % [c, Fmt.sup(s.n - 1)], "factor": 2 * s.n}
		_:
			return {"F": "sin(x²)", "core": "x cos(x²)", "factor": 2}


# ── The derivative first ─────────────────────────────────────

func u_find_derivative(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var P := product(s.fam, k)
	var right := SUM(P.uv + P.udv)
	var both: Array = P.uv + P.udv
	var plain: Array = [SUM([both[0], [Q.of(both[1][0]).neg(), both[1][1]]])]
	if k > 1:
		plain.append(SUM([both[0], [Q.of(both[1][0]).div(k), both[1][1]]]))
	var out := {"asked": "Find d/dx (%s)." % P.F, "lines": ["This is the first part of a \"hence\" question: the result is used to integrate."]}
	out.merge(pick(right, [tag(SUM(P.dv), R_PRODUCT), tag(SUM(P.uv), R_ONE_TERM), tag(SUM(P.udv), R_ONE_TERM)], plain))
	var dv := SUM(P.dv)
	var dv_shown := "(%s)" % dv if dv.begins_with("−") else dv
	out.methods = {"product-rule": method(["u = x and v = %s, so u′ = 1 and v′ = %s." % [P.v, dv],
		"d/dx (uv) = u′v + uv′ = 1 × %s + x × %s." % [P.v, dv_shown], "So d/dx (%s) = %s." % [P.F, right]], {"v": right})}
	return out


# ── A constant factor ────────────────────────────────────────

func u_adjust_factor(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var C := composite(s)
	var m: int = s.m
	var factor: int = C.factor
	var r := q(m, factor)
	var dF := T(factor, C.core)
	var g := T(m, C.core)
	var ans := T(r, C.F)
	var right := plus_c(ans)
	var out := {"asked": "Hence find %s." % integral(g), "lines": ["d/dx (%s) = %s" % [C.F, dF]]}
	out.merge(pick(right, [tag(plus_c(dF), R_DERIVATIVE), tag(plus_c(T(m, C.F)), R_NOT_DIVIDED), tag(ans, R_NO_C)], [plus_c(T(m * factor, C.F))]))
	out.methods = {
		"rearrange-derivative": method(["Read the result backwards: %s = %s + C." % [integral(dF), C.F],
			"%s is %s times %s." % [g, r.text(), dF], "So %s = %s." % [integral(g), right]], {"v": right}),
		"differentiate-check": method(["Try %s: by the result, its derivative is %s × %s = %s." % [ans, r.text(), dF, g],
			"That is the integrand, so %s = %s." % [integral(g), right]], {"v": right}),
	}
	# The slip: multiplied by the factor instead of divided.
	var bad := plus_c(T(m * factor, C.F))
	var lines := ["d/dx (%s) = %s" % [C.F, dF], "So %s = %s + C" % [integral(dF), C.F], "%s is %s times %s" % [g, r.text(), dF], "So %s = %s" % [integral(g), bad]]
	var at := 3
	if rng.chance(0.5):
		lines = [lines[0], lines[2], lines[3], "Check: d/dx (%s) = %s" % [T(m * factor, C.F), T(m * factor * factor, C.core)]]
		at = 2
	out.spot = {"lines": lines, "bad": at, "ref": R_MULTIPLIED, "why": "%s is %s times %s, so its integral is %s times %s, not %s times" % [g, r.text(), dF, r.text(), C.F, N(m * factor)]}
	return out


# ── An extra term ────────────────────────────────────────────

func u_move_extra_term(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var k: int = s.k
	var m: int = s.m
	var P := product(s.fam, k)
	var by := q(m, P.k)
	var target := SUM(scaled(P.tt, by))
	var ans := SUM(scaled(P.tt_int, by))
	var right := plus_c(ans)
	var dF := SUM(P.uv + P.udv)
	var out := {"asked": "Hence find %s." % integral(target), "lines": ["d/dx (%s) = %s" % [P.F, dF]]}
	var tagged := [tag(plus_c(SUM(scaled(P.uv + P.udv, q(m)))), R_DERIVATIVE),
		tag(plus_c(SUM(scaled([[1, P.F]], by)) if s.fam != "xcos" else SUM(scaled([[-1, P.F]], by))), R_NOT_MOVED), tag(ans, R_NO_C)]
	var sign := plus_c(SUM(scaled(flipped_last(P.tt_int) if s.fam != "xcos" else _flip_first(P.tt_int), by)))
	out.merge(pick(right, tagged, [sign]))
	var tt := SUM(P.tt)
	var tt_int := plus_c(SUM(P.tt_int))
	var joined := " − " if s.fam == "xcos" else " + "
	var steps := ["Integrate both sides of the result: %s = %s%s%s, and %s = %s + C." % [P.F, integral(SUM(P.other)), joined, integral(tt), integral(SUM(P.other)), SUM(P.other_int)],
		"So %s = %s." % [integral(tt), tt_int]]
	if not by.eq(1):
		steps.append("So %s = %s." % [integral(target), right])
	else:
		steps[1] = "So %s = %s." % [integral(target), right]
	out.methods = {
		"rearrange-derivative": method(steps, {"v": right}),
		"differentiate-check": method(["Differentiate %s with the product rule: its derivative is %s." % [ans, target],
			"That is the integrand, so %s = %s." % [integral(target), right]], {"v": right}),
	}
	# The slip: the moved term's integral keeps its sign.
	var bad_tt := plus_c(SUM(flipped_last(P.tt_int) if s.fam != "xcos" else _flip_first(P.tt_int)))
	var std := "%s = %s + C" % [integral(SUM(P.other)), SUM(P.other_int)]
	var l1 := "d/dx (%s) = %s" % [P.F, dF]
	var l2 := "So %s = %s + C" % [integral(dF), P.F]
	var l3 := "So %s = %s" % [integral(tt), bad_tt]
	var lines := [l1, l2, std, l3]
	var at := 3
	if not by.eq(1) and rng.chance(0.5):
		lines = [l1, l2, l3, "So %s = %s" % [integral(target), sign]]
		at = 2
	out.spot = {"lines": lines, "bad": at, "ref": R_SIGN, "why": "%s moves to the other side, so its integral changes sign" % integral(SUM(P.other))}
	return out


## For x cos(kx) the moved term (sin(kx)/k) comes first.
static func _flip_first(terms: Array) -> Array:
	var out := terms.duplicate(true)
	out[0] = [Q.of(out[0][0]).neg(), out[0][1]]
	return out


# ── Exact values ─────────────────────────────────────────────

func u_hence_definite(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: int = s.m
	var out := {}
	if s.fam == "xlnx":
		var n: int = s.n
		var lnn := "ln %d" % n
		var right := SUM([[m * n, lnn], [-m * (n - 1), ""]])
		out = {"asked": "Hence find the exact value of ∫ from 1 to %d of %s dx." % [n, T(m, "ln x")], "lines": ["d/dx (x ln x) = ln x + 1"]}
		out.merge(pick(right, [tag(T(m, lnn), R_DERIVATIVE), tag(T(m * n, lnn), R_NOT_MOVED)],
			[SUM([[m * n, lnn], [m * (n - 1), ""]]), SUM([[m * n, lnn], [-m * n, ""]])]))
		out.methods = {"rearrange-derivative": method(["Read the result backwards: ∫ ln x dx = x ln x − x + C.",
			"So the integral is %s[x ln x − x] from 1 to %d = %s(%s − %d) − %s(0 − 1)." % [Fmt.lead(m), n, Fmt.lead(m), T(n, lnn), n, Fmt.lead(m)],
			"So the integral is %s." % right], {"v": right})}
		return out
	var b: int = s.b
	var eb := "e" if b == 1 else "e⁴"
	var half := q(m, 2)
	var right: String = (eb + " − 1") if half.eq(1) else T(half, "(%s − 1)" % eb)
	out = {"asked": "Hence find the exact value of ∫ from 0 to %d of %s dx." % [b, T(m, "x e^(x²)")], "lines": ["d/dx (e^(x²)) = 2x e^(x²)"]}
	out.merge(pick(right, [tag(T(m * b, eb), R_DERIVATIVE), tag(T(m, "(%s − 1)" % eb), R_NOT_DIVIDED)], [T(half, eb)]))
	out.methods = {"rearrange-derivative": method(["Read the result backwards: ∫ 2x e^(x²) dx = e^(x²) + C.",
		"%s is %s times 2x e^(x²), so ∫ %s dx = %s + C." % [T(m, "x e^(x²)"), half.text(), T(m, "x e^(x²)"), T(half, "e^(x²)")],
		"From 0 to %d: %s." % [b, T(half, "(%s − e⁰)" % eb)], "So the integral is %s." % right], {"v": right})}
	return out


# ── Which result helps ───────────────────────────────────────

func u_pick_the_derivative(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var E := Ek(k)
	var cases := {
		"xcos": ["x cos x", "d/dx (x sin x) = sin x + x cos x",
			["d/dx (x cos x) = cos x − x sin x", "d/dx (x² sin x) = 2x sin x + x² cos x", "d/dx (x² cos x) = 2x cos x − x² sin x"]],
		"xsin": ["x sin x", "d/dx (x cos x) = cos x − x sin x",
			["d/dx (x sin x) = sin x + x cos x", "d/dx (x² cos x) = 2x cos x − x² sin x", "d/dx (x² sin x) = 2x sin x + x² cos x"]],
		"lnx": ["ln x", "d/dx (x ln x) = ln x + 1",
			["d/dx ((ln x)²) = (2 ln x)/x", "d/dx (x² ln x) = 2x ln x + x", "d/dx (ln(2x)) = 1/x"]],
		"xekx": ["x " + E, "d/dx (x %s) = %s" % [E, SUM([[1, E], [k, "x " + E]])],
			["d/dx (x² %s) = %s" % [E, SUM([[2, "x " + E], [k, "x² " + E]])], "d/dx (e^(x²)) = 2x e^(x²)", "d/dx (x ln x) = ln x + 1"]],
		"ex2": ["x e^(x²)", "d/dx (e^(x²)) = 2x e^(x²)",
			["d/dx (x e^(x²)) = e^(x²) + 2x² e^(x²)", "d/dx (x² e^(x²)) = 2x e^(x²) + 2x³ e^(x²)", "d/dx (e^(2x)) = 2e^(2x)"]],
	}
	var c: Array = cases[s.fam]
	var out := {"asked": "Which derivative result helps to find %s?" % integral(c[0]), "lines": ["Each result below is true."]}
	out.merge(pick(c[1], [], c[2]))
	out.methods = {"differentiate-check": method(["The one that helps has %s, or a multiple of it, as one term, and the other term easy to integrate." % c[0],
		"%s." % c[1]], {"v": c[1]})}
	return out
