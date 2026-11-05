class_name IntegrationViews
extends ExtensionViews
## The views on the `integration` situation: one builder per unknown of
## t5-indefinite-integral (FAL-724). An integral is a `form` answer, as a derivative is: the
## student types its numbers into the expression, and + C is part of the expression, so an
## option without it is wrong. A wrong option in another shape can be picked but not typed.
##
## Representations: "equation" (∫ (…) dx) and "words" (every function with this derivative).

const PW := "SL5.5.antidiff-power#"
const ST := "SL5.10.standard-integrals#"
const LN := "SL5.10.linear-composites#"
const IN := "SL5.10.inspection-substitution#"
const RW := "SL5.10.rewrite-before-integrating#"
const R_OLD_POWER := PW + "0"
const R_NO_C := PW + "1"
const R_RECIPROCAL := PW + "2"
const R_SIN_SIGN := ST + "0"
const R_POWER_ON_X := ST + "1"
const R_MULT_NEW := ST + "2"
const R_MULT_A := LN + "0"
const R_NO_A := LN + "1"
const R_OVER_EXPONENT := LN + "2"
const R_EXTRA_X := IN + "0"
const R_NO_HALF := IN + "1"
const R_IN_U := IN + "2"
const R_SEPARATE := RW + "0"
const R_NO_MIDDLE := RW + "1"
const UNKNOWNS := ["power-polynomial", "power-negative", "power-product", "standard-exp-trig", "standard-reciprocal", "standard-roots",
	"linear-exp", "linear-trig", "linear-reciprocal", "linear-power", "linear-square", "inspection-power", "inspection-exp",
	"inspection-log", "inspection-trig", "rewrite-fraction", "rewrite-square", "rewrite-trig-product"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## The bank's Paper 2 parts integrate sums and e^(ax); its reverse chain rule parts are
## Paper 1. An integral is the same question on either paper.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	if not has(unknown):
		return []
	return [1] if unknown.begins_with("inspection-") or unknown == "rewrite-trig-product" else [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = IntegrationSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

## The sum of [coefficient, body] terms, with + C.
static func sumc(terms: Array) -> String:
	return DifferentiationViews.SUM(terms) + " + C"


## An integral as an expression: each term's coefficient is a slot, c0, c1, ...
static func anti(terms: Array) -> Dictionary:
	var parts: Array = []
	var slots := {}
	for i in terms.size():
		if i > 0:
			parts.append(" + ")
		parts.append({"slot": "c%d" % i})
		parts.append((" " if terms[i][1].begins_with("ln") or terms[i][1].begins_with("sin") or terms[i][1].begins_with("cos") else "") + terms[i][1])
		slots["c%d" % i] = Q.of(terms[i][0])
	parts.append(" + C")
	return DifferentiationViews.form(sumc(terms), parts, slots)


## A wrong option with the same bodies, so it can be typed too.
static func alt(terms: Array, ref: String = "") -> Dictionary:
	return wrong(anti(terms).values, ref)


## A wrong option in another shape.
static func other(text: String, ref: String = "") -> Dictionary:
	return DifferentiationViews.alt(text, ref)


## The right terms with no + C.
static func no_c(terms: Array) -> Dictionary:
	return other(DifferentiationViews.SUM(terms), R_NO_C)


## ax + b as it reads inside brackets: "3x − 2".
static func inner(a: int, b: int) -> String:
	return DifferentiationViews.SUM([[a, "x"], [b, ""]])


## x² + a: "x² + 3", or "x²" with no constant.
static func quad(a: int) -> String:
	return DifferentiationViews.SUM([[1, "x²"], [a, ""]])


## A function of ax + b: cos(3x − 2), e^(2x), ln|x + 1|.
static func fn(name: String, a: int, b: int) -> String:
	return "%s(%s)" % [name, inner(a, b)]


static func ask(s: Dictionary, rep: String, integrand: String) -> Dictionary:
	if rep == "words":
		return {"lines": ["F′(x) = %s" % integrand], "asked": "Find every function F with this derivative, using C for the constant."}
	return {"lines": ["∫ %s dx" % wrapped(integrand)], "asked": "Find the integral."}


## In brackets if it is a sum: "(x² + 1)", but "(2x + 1)²" and "4x/(x² + 1)" as they are.
static func wrapped(t: String) -> String:
	var depth := 0
	for i in t.length():
		var c := t[i]
		depth += 1 if c == "(" else (-1 if c == ")" else 0)
		if depth == 0 and i > 0 and c in ["+", "−"]:
			return "(%s)" % t
	return t


static func q(a: Variant, b: Variant) -> Q:
	return Q.of(a).div(Q.of(b))


## The last step of every method.
static func say(ans: Dictionary) -> String:
	return "So the integral is " + Answer.text(ans) + "."


## A question: an integrand, its answer, its wrong options and its methods.
static func out(rep: String, s: Dictionary, integrand: String, ans: Dictionary, wr: Array, gen: Array, methods: Dictionary) -> Dictionary:
	var a := ask(s, rep, integrand)
	var ms := {}
	for id in methods:
		ms[id] = method(methods[id] + [say(ans)], ans.values)
	return {"lines": a.lines, "asked": a.asked, "answer": ans, "wrongs": wr, "generic": gen, "methods": ms}


# ── Powers ───────────────────────────────────────────────────

func u_power_polynomial(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var terms: Array = [[q(a, 3), "x³"], [q(b, 2), "x²"], [c, "x"]]
	var ans := anti(terms)
	var f: String = Fmt.poly([a, b, c])
	return out(rep, s, f, ans, [alt([[q(a, 2), "x³"], [b, "x²"], [c, "x"]], R_OLD_POWER), no_c(terms)],
		[alt([[a, "x³"], [b, "x²"], [c, "x"]]).values, alt([[q(a, 3), "x³"], [q(b, 2), "x²"], [-c, "x"]]).values, alt([[q(-a, 3), "x³"], [q(b, 2), "x²"], [c, "x"]]).values,
			alt([[q(a, 3), "x³"], [q(b + 1, 2), "x²"], [c, "x"]]).values],
		{"reverse-power-rule": [
			"Raise each power by 1 and divide by the new power: %s becomes %s." % [DifferentiationViews.T(a, "x²"), DifferentiationViews.T(q(a, 3), "x³")],
			"%s becomes %s, and the constant %s becomes %s." % [DifferentiationViews.T(b, "x"), DifferentiationViews.T(q(b, 2), "x²"), N(c), DifferentiationViews.T(c, "x")],
			"Add + C, since a constant differentiates to 0."],
		"differentiate-to-check": [
			"Try %s." % DifferentiationViews.SUM(terms),
			"Differentiate it: the result is %s, which is the integrand." % f,
			"Any constant could be added without changing that, so add + C."]})


func u_power_negative(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var n: int = s.n
	var e := 1 - n
	var xe := DifferentiationViews.X(e)
	var terms: Array = [[q(a, e), xe], [q(b, 2), "x²"]]
	var ans := anti(terms)
	var f: String = DifferentiationViews.SUM([[a, "/" + DifferentiationViews.X(n)], [b, "x"]])
	var wr: Array = [alt([[q(a, -n), xe], [b, "x²"]], R_OLD_POWER),
		other(sumc([[a * (n + 1), "/" + DifferentiationViews.X(n + 1)], [q(b, 2), "x²"]]), R_RECIPROCAL),
		other(sumc([[a, "ln(%s)" % DifferentiationViews.X(n)], [q(b, 2), "x²"]]), R_RECIPROCAL)]
	return out(rep, s, f, ans, wr, [alt([[q(-a, e), xe], [q(b, 2), "x²"]]).values, alt([[q(a, e), xe], [b, "x²"]]).values, alt([[q(a, e), xe], [q(-b, 2), "x²"]]).values],
		{"reverse-power-rule": [
			"Write the first term as a power: %s." % DifferentiationViews.T(a, "x" + Fmt.sup(-n)),
			"Raise the power by 1 to %s and divide by %s." % [N(e), P(e)],
			"The second term gives %s. Add + C." % DifferentiationViews.T(q(b, 2), "x²")],
		"rewrite-first": [
			"Rewrite %s/%s as %s, so the power rule applies." % [N(a), DifferentiationViews.X(n), DifferentiationViews.T(a, "x" + Fmt.sup(-n))],
			"Integrate term by term, raising each power by 1 and dividing by the new power.",
			"The power %s never needs ln: that is only for x⁻¹." % N(-n)]})


func u_power_product(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var r: int = s.q
	var mid := p + r
	var last := p * r
	var terms: Array = [[Q.new(1, 3), "x³"], [q(mid, 2), "x²"], [last, "x"]]
	var ans := anti(terms)
	var f := "(x%s)(x%s)" % [Fmt.plus(p), Fmt.plus(r)]
	return out(rep, s, f, ans, [no_c(terms),
		other("((1/2)x²%s)((1/2)x²%s) + C" % [Fmt.plus(p) + "x", Fmt.plus(r) + "x"])],
		[alt([[Q.new(1, 2), "x³"], [q(mid, 2), "x²"], [last, "x"]]).values, alt([[Q.new(1, 3), "x³"], [mid, "x²"], [last, "x"]]).values, alt([[Q.new(1, 3), "x³"], [q(mid, 2), "x²"], [-last, "x"]]).values, alt([[Q.new(1, 3), "x³"], [q(-mid, 2), "x²"], [last, "x"]]).values],
		{"rewrite-first": [
			"Multiply out first: %s = %s." % [f, Fmt.poly([1, mid, last])],
			"Now integrate term by term.",
			"Add + C."]})


# ── Standard results ─────────────────────────────────────────

func u_standard_exp_trig(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var terms: Array = [[a, "e^x"], [-b, "cos x"], [c, "sin x"]]
	var ans := anti(terms)
	var f: String = DifferentiationViews.SUM([[a, "e^x"], [b, "sin x"], [c, "cos x"]])
	return out(rep, s, f, ans, [alt([[a, "e^x"], [b, "cos x"], [c, "sin x"]], R_SIN_SIGN), no_c(terms)],
		[alt([[a, "e^x"], [-b, "cos x"], [-c, "sin x"]]).values, alt([[a, "e^x"], [b, "cos x"], [-c, "sin x"]]).values, alt([[-a, "e^x"], [-b, "cos x"], [c, "sin x"]]).values, alt([[a + 1, "e^x"], [-b, "cos x"], [c, "sin x"]]).values],
		{"booklet-results": [
			"Term by term: e^x stays e^x, sin x gives −cos x, and cos x gives sin x.",
			"Multiply each by its coefficient.",
			"Add + C."],
		"differentiate-check": [
			"Try %s." % DifferentiationViews.SUM(terms),
			"Its derivative is %s, the integrand, because the derivative of cos x is −sin x and of sin x is cos x." % f,
			"Add + C."]})


func u_standard_reciprocal(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var terms: Array = [[q(a, 2), "x²"], [b, "x"], [c, "ln|x|"]]
	var ans := anti(terms)
	var f: String = DifferentiationViews.SUM([[a, "x"], [b, ""], [c, "/x"]])
	var two: Array = [[q(a, 2), "x²"], [b, "x"]]
	return out(rep, s, f, ans, [other(sumc(two + [[c, "x⁰/0"]]), R_POWER_ON_X), no_c(terms),
		other(sumc(two + [[-c, "/x²"]]))],
		[alt([[a, "x²"], [b, "x"], [c, "ln|x|"]]).values, alt([[q(a, 2), "x²"], [-b, "x"], [c, "ln|x|"]]).values, alt([[q(a, 2), "x²"], [b, "x"], [-c, "ln|x|"]]).values],
		{"booklet-results": [
			"1/x is the one power the power rule can't do: ∫ 1/x dx = ln|x| + C.",
			"The other terms use the power rule: %s and %s." % [DifferentiationViews.T(q(a, 2), "x²"), DifferentiationViews.T(b, "x")],
			"One + C covers the whole sum."],
		"differentiate-check": [
			"Try %s." % DifferentiationViews.SUM(terms),
			"Differentiate: ln|x| gives 1/x, so the result is %s." % f,
			"That is the integrand. Add + C."]})


func u_standard_roots(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var root: bool = s.fam == "sqrt"
	var e0 := Q.new(3, 2) if root else Q.new(4, 3)
	var e1 := Q.new(1, 2) if root else Q.new(2, 3)
	var b0 := DifferentiationViews.XQ(e0)
	var b1 := DifferentiationViews.XQ(e1)
	var sym := "√x" if root else "∛x"
	var terms: Array = [[Q.of(a).div(e0), b0], [Q.of(b).div(e1), b1]]
	var ans := anti(terms)
	var f: String = DifferentiationViews.SUM([[a, sym], [b, "/" + sym]])
	return out(rep, s, f, ans, [alt([[Q.of(a).mul(e0), b0], [Q.of(b).mul(e1), b1]], R_MULT_NEW)],
		[alt([[a, b0], [b, b1]]).values, alt([[Q.of(a).div(e0), b0], [Q.of(-b).div(e1), b1]]).values, alt([[Q.of(a).div(e1), b0], [Q.of(b).div(e0), b1]]).values, alt([[Q.of(-a).div(e0), b0], [Q.of(b).div(e1), b1]]).values],
		{"index-form": [
			"Write the roots as powers: %s = x^(%s) and 1/%s = x^(%s)." % [sym, e0.sub(1).text(), sym, e1.sub(1).text()],
			"Raise each power by 1, to %s and %s." % [e0.text(), e1.text()],
			"Divide by each new power, which is the same as multiplying by its reciprocal. Add + C."],
		"differentiate-check": [
			"Try %s." % DifferentiationViews.SUM(terms),
			"Differentiate: bring each power down and take 1 off it, which gives %s." % f,
			"That is the integrand. Add + C."]})


# ── Composites with ax + b ───────────────────────────────────

func u_linear_exp(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var e := "e^(%s)" % inner(a, b)
	var terms: Array = [[q(1, a), e], [c, "x"]]
	var ans := anti(terms)
	var f: String = DifferentiationViews.SUM([[1, e], [c, ""]])
	return out(rep, s, f, ans, [alt([[a, e], [c, "x"]], R_MULT_A), alt([[1, e], [c, "x"]], R_NO_A),
		other(sumc([[1, "%s/(%s)" % [e, inner(a, b)]], [c, "x"]]), R_OVER_EXPONENT)],
		[alt([[q(1, a), e], [-c, "x"]]).values, alt([[q(-1, a), e], [c, "x"]]).values, alt([[q(1, a), e], [q(c, 2), "x"]]).values],
		{"divide-by-a": [
			"Integrate as if the inside were x: e^u stays e^u.",
			"Divide by %s, the derivative of the inside." % N(a),
			"The constant %s integrates to %s. Add + C." % [N(c), DifferentiationViews.T(c, "x")]],
		"substitution": [
			"Let u = %s, so du = %s dx and dx = du/%s." % [inner(a, b), N(a), P(a)],
			"∫ e^u du/%s = (1/%s)e^u, as %s is a constant." % [P(a), P(a), P(a)],
			"Put u back, then integrate the constant %s to %s. Add + C." % [N(c), DifferentiationViews.T(c, "x")]],
		"differentiate-check": [
			"Try %s." % DifferentiationViews.SUM(terms),
			"The chain rule multiplies by %s, which cancels the %s and leaves %s." % [N(a), q(1, a).text(), f],
			"That is the integrand. Add + C."]})


func u_linear_trig(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var k: int = s.k
	var cos: bool = s.fam == "cos"
	var body := fn("sin" if cos else "cos", a, b)
	var sgn: int = 1 if cos else -1
	var c0 := q(sgn * k, a)
	var f: String = DifferentiationViews.T(k, fn("cos" if cos else "sin", a, b))
	var ans := anti([[c0, body]])
	return out(rep, s, f, ans, [alt([[sgn * k * a, body]], R_MULT_A), alt([[sgn * k, body]], R_NO_A)],
		[alt([[c0.neg(), body]]).values, alt([[-sgn * k * a, body]]).values, alt([[q(sgn * k, 2 * a), body]]).values, alt([[-sgn * k, body]]).values],
		{"divide-by-a": [
			"Integrate as if the inside were x: ∫ %s u du = %s u." % ["cos" if cos else "sin", "sin" if cos else "−cos"],
			"Multiply by %s and divide by %s, the derivative of the inside." % [N(k), N(a)],
			"Add + C."],
		"substitution": [
			"Let u = %s, so dx = du/%s." % [inner(a, b), P(a)],
			"The integral becomes (%s/%s) ∫ %s u du = %s." % [N(k), P(a), "cos" if cos else "sin", DifferentiationViews.T(c0, "sin u" if cos else "cos u")],
			"Put u back and add + C."]})


func u_linear_reciprocal(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var k: int = s.k
	var body := "ln|%s|" % inner(a, b)
	var ans := anti([[q(k, a), body]])
	var f := "%s/(%s)" % [N(k), inner(a, b)]
	return out(rep, s, f, ans, [alt([[k * a, body]], R_MULT_A), alt([[k, body]], R_NO_A)],
		[alt([[q(-k, a), body]]).values, alt([[q(k, 2 * a), body]]).values, alt([[-k, body]]).values, alt([[q(2 * k, a), body]]).values],
		{"divide-by-a": [
			"Integrate as if the inside were x: ∫ 1/u du = ln|u|.",
			"Multiply by %s and divide by %s, the derivative of the inside." % [N(k), N(a)],
			"Add + C."],
		"substitution": [
			"Let u = %s, so dx = du/%s." % [inner(a, b), P(a)],
			"The integral becomes (%s/%s) ∫ 1/u du = %s." % [N(k), P(a), DifferentiationViews.T(q(k, a), "ln|u|")],
			"Put u back and add + C."]})


func u_linear_power(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var k: int = s.k
	var n: int = s.n
	var body := "(%s)%s" % [inner(a, b), Fmt.sup(n + 1)]
	var c0 := q(k, a * (n + 1))
	var ans := anti([[c0, body]])
	var f: String = DifferentiationViews.T(k, "(%s)%s" % [inner(a, b), Fmt.sup(n)])
	return out(rep, s, f, ans, [alt([[q(k * a, n + 1), body]], R_MULT_A), alt([[q(k, n + 1), body]], R_NO_A)],
		[alt([[c0.neg(), body]]).values, alt([[q(k, a * n), body]]).values, alt([[q(2 * k, a * (n + 1)), body]]).values, alt([[q(k, a * (n + 2)), body]]).values],
		{"divide-by-a": [
			"Integrate as if the inside were x: raise the power to %s and divide by %s." % [n + 1, n + 1],
			"Divide by %s as well, the derivative of the inside." % N(a),
			"Add + C."],
		"substitution": [
			"Let u = %s, so dx = du/%s." % [inner(a, b), P(a)],
			"The integral becomes (%s/%s) ∫ u%s du = %s." % [N(k), P(a), Fmt.sup(n), DifferentiationViews.T(c0, "u" + Fmt.sup(n + 1))],
			"Put u back and add + C."]})


## Bracket or polynomial, as the method asks: each is right on its own question, so the other
## shape is never offered, and the other method's working ends by showing they agree.
func u_linear_square(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var f := "(%s)²" % inner(a, b)
	var body := "(%s)³" % inner(a, b)
	var c0 := q(1, 3 * a)
	var poly: Array = [[q(a * a, 3), "x³"], [a * b, "x²"], [b * b, "x"]]
	var bracket := sumc([[c0, body]])
	var expanded := sumc(poly)
	var ways := {
		"expand-first": ["Expand the square: %s = %s." % [f, Fmt.poly([a * a, 2 * a * b, b * b])], "Integrate term by term.", "Add + C."],
		"divide-by-a": ["Integrate as if the inside were x: raise the power to 3 and divide by 3.",
			"Divide by %s as well, the derivative of the inside." % N(a), "Add + C."]}
	if angle == "expand-first":
		ways["divide-by-a"].append("The bracket %s and this form differ only by a constant." % bracket)
		return out(rep, s, f, anti(poly), [other(sumc([[Q.new(1, 3), body]]), R_NO_A), other(sumc([[q(a, 3), body]]), R_MULT_A)],
			[alt([[q(a * a, 3), "x³"], [2 * a * b, "x²"], [b * b, "x"]]).values, alt([[q(a * a, 3), "x³"], [-a * b, "x²"], [b * b, "x"]]).values,
				alt([[a * a, "x³"], [a * b, "x²"], [b * b, "x"]]).values, alt([[q(a * a, 3), "x³"], [a * b, "x²"], [-b * b, "x"]]).values], ways)
	ways["expand-first"].append("The polynomial %s and this form differ only by a constant." % expanded)
	return out(rep, s, f, anti([[c0, body]]), [alt([[q(a, 3), body]], R_MULT_A), alt([[Q.new(1, 3), body]], R_NO_A)],
		[alt([[c0.neg(), body]]).values, alt([[q(1, 2 * a), body]]).values, alt([[q(1, a), body]]).values, alt([[q(2, 3 * a), body]]).values], ways)


# ── The reverse chain rule ───────────────────────────────────

func u_inspection_power(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var n: int = s.n
	var a: int = s.a
	var inside := quad(a)
	var top: bool = s.fam == "top"
	var e: int = n + 1 if top else 1 - n
	var c0 := q(k, 2 * e)
	var body: String = "(%s)%s" % [inside, Fmt.sup(e)] if top else "/(%s)%s" % [inside, Fmt.sup(n - 1)] if n > 2 else "/(%s)" % inside
	var ubody: String = "u" + Fmt.sup(e) if top else "/u" + (Fmt.sup(n - 1) if n > 2 else "")
	var f: String = "%s(%s)%s" % [DifferentiationViews.T(k, "x"), inside, Fmt.sup(n)] if top else "%s/(%s)%s" % [DifferentiationViews.T(k, "x"), inside, Fmt.sup(n)]
	var terms: Array = [[c0, body]]
	var ans := anti(terms)
	var xbody: String = "x" + body if top else "x" + body
	return out(rep, s, f, ans, [other(sumc([[q(k, e), xbody]]), R_EXTRA_X), alt([[q(k, e), body]], R_NO_HALF), other(sumc([[c0, ubody]]), R_IN_U)],
		[alt([[c0.neg(), body]]).values, alt([[q(k, 2), body]]).values, alt([[q(k, 2 * (e - 1)), body]]).values if e != 1 else alt([[q(k, 4), body]]).values],
		{"inspection": [
			"The x outside is a multiple of the derivative of %s, so try a power of the bracket." % inside,
			"d/dx of %s is %s." % [("(%s)%s" % [inside, Fmt.sup(e)]) if top else "1/(%s)%s" % [inside, Fmt.sup(n - 1) if n > 2 else ""], "%s(%s)%s" % [DifferentiationViews.T(2 * e, "x"), inside, Fmt.sup(e - 1)]],
			"Adjust the number: %s ÷ %s = %s. Add + C." % [N(k), N(2 * e), c0.text()]],
		"u-substitution": [
			"Let u = %s, so du = 2x dx." % inside,
			"The integral becomes %s∫ u%s du = %s." % [Fmt.lead(q(k, 2)), Fmt.sup(n if top else -n), DifferentiationViews.T(c0, "u" + Fmt.sup(e))],
			"Put u back and add + C."]})


func u_inspection_exp(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var a: int = s.a
	var e := "e^(%s)" % quad(a)
	var c0 := q(k, 2)
	var ans := anti([[c0, e]])
	var f: String = DifferentiationViews.T(k, "x " + e)
	return out(rep, s, f, ans, [other(sumc([[k, "x " + e]]), R_EXTRA_X), alt([[k, e]], R_NO_HALF), other(sumc([[c0, "e^u"]]), R_IN_U)],
		[alt([[c0.neg(), e]]).values, alt([[q(k, 4), e]]).values, alt([[-k, e]]).values],
		{"inspection": [
			"The x outside is a multiple of the derivative of x²%s, so try %s." % [Fmt.plus(a) if a != 0 else "", e],
			"d/dx of %s is 2x %s." % [e, e],
			"Adjust the number: %s ÷ 2 = %s. Add + C." % [N(k), N(c0)]],
		"u-substitution": [
			"Let u = %s, so du = 2x dx." % quad(a),
			"The integral becomes %s∫ e^u du = %s." % [Fmt.lead(c0), DifferentiationViews.T(c0, "e^u")],
			"Put u back and add + C."]})


func u_inspection_log(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var a: int = s.a
	var body := "ln(%s)" % quad(a)
	var c0 := q(k, 2)
	var ans := anti([[c0, body]])
	var f := "%s/(%s)" % [DifferentiationViews.T(k, "x"), quad(a)]
	return out(rep, s, f, ans, [other(sumc([[k, "x ln(%s)" % quad(a)]]), R_EXTRA_X), alt([[k, body]], R_NO_HALF), other(sumc([[c0, "ln u"]]), R_IN_U)],
		[alt([[c0.neg(), body]]).values, alt([[q(k, 4), body]]).values, alt([[2 * k, body]]).values],
		{"log-pattern": [
			"The top is a multiple of the derivative of the bottom, 2x, so this is g′/g.",
			"∫ g′(x)/g(x) dx = ln|g(x)| + C, and %s is always positive." % quad(a),
			"Adjust the number: %s ÷ 2 = %s." % [N(k), N(c0)]],
		"u-substitution": [
			"Let u = %s, so du = 2x dx." % quad(a),
			"The integral becomes %s∫ 1/u du = %s." % [Fmt.lead(c0), DifferentiationViews.T(c0, "ln u")],
			"Put u back and add + C. u is positive, so no modulus is needed."]})


func u_inspection_trig(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var n: int = s.n
	var sc: bool = s.fam == "sincos"
	var inner_fn := "cos" if sc else "sin"
	var outer := "sin" if sc else "cos"
	var body := "%s%s x" % [inner_fn, Fmt.sup(n + 1)]
	var sgn := -1 if sc else 1
	var c0 := q(sgn * k, n + 1)
	var ans := anti([[c0, body]])
	var f: String = "%s %s%s x" % [DifferentiationViews.T(k, outer + " x"), inner_fn, Fmt.sup(n)]
	return out(rep, s, f, ans, [other(sumc([[c0, "%s x %s" % [outer, body]]]), R_EXTRA_X), other(sumc([[c0, "u" + Fmt.sup(n + 1)]]), R_IN_U)],
		[alt([[c0.neg(), body]]).values, alt([[q(sgn * k, n), body]]).values, alt([[q(sgn * k, n + 2), body]]).values, alt([[sgn * k, body]]).values],
		{"inspection": [
			"%s x is a multiple of the derivative of %s x, so try %s." % [outer.capitalize(), inner_fn, body],
			"d/dx of %s is %s %s x %s%s x." % [body, N(sgn * (n + 1)), outer, inner_fn, Fmt.sup(n)],
			"Adjust the number: %s ÷ %s = %s. Add + C." % [N(k), P(sgn * (n + 1)), c0.text()]],
		"u-substitution": [
			"Let u = %s x, so du = %s%s x dx." % [inner_fn, "−" if sc else "", outer],
			"The integral becomes %s∫ u%s du = %s." % [Fmt.lead(sgn * k), Fmt.sup(n), DifferentiationViews.T(c0, "u" + Fmt.sup(n + 1))],
			"Put u back and add + C."]})


# ── Rewrite first ────────────────────────────────────────────

func u_rewrite_fraction(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var terms: Array = [[q(a, 2), "x²"], [b, "x"], [c, "ln|x|"]]
	var ans := anti(terms)
	var f := "(%s)/x" % Fmt.poly([a, b, c])
	var split: String = DifferentiationViews.SUM([[a, "x"], [b, ""], [c, "/x"]])
	var top: String = DifferentiationViews.SUM([[q(a, 3), "x³"], [q(b, 2), "x²"], [c, "x"]])
	return out(rep, s, f, ans, [other("(%s)/((1/2)x²) + C" % top, R_SEPARATE), no_c(terms)],
		[alt([[a, "x²"], [b, "x"], [c, "ln|x|"]]).values, alt([[q(a, 2), "x²"], [b, "x"], [-c, "ln|x|"]]).values, alt([[q(-a, 2), "x²"], [b, "x"], [c, "ln|x|"]]).values],
		{"split-numerator": [
			"Divide each term of the top by x: %s." % split,
			"Integrate term by term, with c/x going to c ln|x|.",
			"Add + C."]})


func u_rewrite_square(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	if s.fam == "root":
		var p: String = DifferentiationViews.XQ(Q.new(3, 2))
		var terms: Array = [[a * a, "x"], [q(4 * a, 3), p], [Q.new(1, 2), "x²"]]
		return out(rep, s, "(%d + √x)²" % a, anti(terms), [alt([[a * a, "x"], [0, p], [Q.new(1, 2), "x²"]], R_NO_MIDDLE)],
			[alt([[a * a, "x"], [2 * a, p], [Q.new(1, 2), "x²"]]).values, alt([[a * a, "x"], [q(4 * a, 3), p], [1, "x²"]]).values, alt([[a, "x"], [q(4 * a, 3), p], [Q.new(1, 2), "x²"]]).values],
			{"expand-brackets": [
				"Expand: (%d + √x)² = %d + %d√x + x. The middle term is easy to miss." % [a, a * a, 2 * a],
				"Write √x as x^(1/2) and integrate term by term.",
				"Add + C."]})
	var terms2: Array = [[Q.new(1, 2), "e^(2x)"], [2 * a, "e^x"], [a * a, "x"]]
	var sq: String = "(e^x%s)²" % Fmt.plus(a)
	return out(rep, s, sq, anti(terms2), [alt([[Q.new(1, 2), "e^(2x)"], [0, "e^x"], [a * a, "x"]], R_NO_MIDDLE)],
		[alt([[1, "e^(2x)"], [2 * a, "e^x"], [a * a, "x"]]).values, alt([[Q.new(1, 2), "e^(2x)"], [a, "e^x"], [a * a, "x"]]).values, alt([[Q.new(1, 2), "e^(2x)"], [2 * a, "e^x"], [2 * a, "x"]]).values],
		{"expand-brackets": [
			"Expand: %s = e^(2x) %s e^x + %d. The middle term is easy to miss." % [sq, Fmt.plus(2 * a).strip_edges(), a * a],
			"Integrate term by term: e^(2x) gives (1/2)e^(2x).",
			"Add + C."]})


## −(k/4) cos 2x and (k/2) sin² x are both right, differing by a constant, so the method says
## which one a question wants, and the other is never an option.
func u_rewrite_trig_product(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var f: String = "%s cos x" % DifferentiationViews.T(k, "sin x")
	var b1 := "sin² x"
	var c1 := q(k, 2)
	var b2 := "cos(2x)"
	var c2 := q(-k, 4)
	var ways := {
		"inspection-alternative": ["cos x is the derivative of sin x, so try sin² x.", "d/dx of sin² x is 2 sin x cos x.",
			"Adjust the number: %d ÷ 2 = %s. Add + C." % [k, N(c1)]],
		"identity-substitution": ["Use sin 2x = 2 sin x cos x, so %s = %s." % [f, DifferentiationViews.T(c1, "sin(2x)")],
			"∫ sin(2x) dx = −(1/2)cos(2x).", "Multiply by %s. Add + C." % N(c1)]}
	if angle == "inspection-alternative":
		ways["identity-substitution"].append("This looks different, but %s and the answer below differ only by a constant." % sumc([[c2, b2]]))
		return out(rep, s, f, anti([[c1, b1]]), [alt([[k, b1]]), alt([[-k, b1]])],
			[alt([[q(k, 4), b1]]).values, alt([[c1.neg(), b1]]).values, alt([[2 * k, b1]]).values], ways)
	ways["inspection-alternative"].append("This looks different, but %s and the answer below differ only by a constant." % sumc([[c1, b1]]))
	return out(rep, s, f, anti([[c2, b2]]), [alt([[c2.neg(), b2]]), alt([[q(-k, 2), b2]])],
		[alt([[q(k, 2), b2]]).values, alt([[-k, b2]]).values, alt([[q(-k, 8), b2]]).values], ways)
