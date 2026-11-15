class_name PolynomialConditionsViews
extends ExtensionViews
## The views on the `polynomial-conditions` situation (FAL-776): one builder per unknown of
## t5-ext-unknown-coefficients and t5-ext-stationary-conditions. One letter is typed as a number
## (k = □), two as `named` (a = □, b = □), exact. The givens are f(x) and the conditions in symbols
## ("equation"), or the curve and its point in words ("words"). Every working forms one equation per
## condition and solves them; Paper 2 hands the pair to the GDC's solver. Error-spot shows a
## student's working with one slip, and every line after it follows from the slip.

const UC := "SL5.3.unknown-coefficients#"
const SC := "SL5.8.stationary-point-conditions#"
const R_INTO_F := UC + "0"
const R_DIFF_LETTER := UC + "1"
const R_TANGENT_C := "t5-ext-unknown-coefficients#2"
const R_F_ZERO := SC + "0"
const R_ONE_CONDITION := SC + "1"
const R_Y_INTO := SC + "2"
const R_INFLEXION_F1 := "t5-ext-stationary-conditions#3"
const R_NO_LEAD := "t5-ext-stationary-conditions#4"
const UNKNOWNS := ["k-from-gradient", "two-from-gradient-and-point", "two-gradients", "from-tangent",
	"k-from-stationary-x", "two-from-stationary-point", "k-from-inflexion", "two-from-two-stationary"]
const SPOTS := ["k-from-gradient", "two-from-gradient-and-point", "two-from-stationary-point"]
const S := preload("res://engine/situations/polynomial_conditions.gd")


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	var out := {}
	for u in SPOTS:
		out[u] = ["error-spot"]
	return out


## The GDC's solver is Paper 2; forming and solving by hand is Paper 1.
func papers(unknown: String, _rep: String, angle: String) -> Array:
	if not has(unknown):
		return []
	return [2] if angle.begins_with("gdc-") else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = S.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func SUM(terms: Array) -> String:
	return DifferentiationViews.SUM(terms)


static func xp(p: int) -> String:
	return "" if p == 0 else "x" + Fmt.sup(p)


## A polynomial with letters: "kx² + 3x − 2", "ax³ + bx".
static func poly(terms: Array) -> String:
	return SUM(terms.map(func(t): return [t.c, t.l + xp(t.p)]))


## A linear form, letters first in the order given, then the number: "4k + 3", "12a + 4b".
static func lin_text(lin: Dictionary, letters: Array) -> String:
	var parts: Array = []
	for l in letters:
		parts.append([lin.get(l, Q.new(0)), l])
	parts.append([lin.get("", Q.new(0)), ""])
	return SUM(parts)


## The condition "terms at x = rhs" with the number moved across: "12a + 4b = 9".
static func equation(terms: Array, x: Variant, rhs: Variant, letters: Array) -> String:
	var lin := S.at(terms, x)
	var left := lin.duplicate()
	left.erase("")
	return "%s = %s" % [lin_text(left, letters), N(Q.of(rhs).sub(lin.get("", Q.new(0))))]


## "f′(2) = 4k + 3", the condition's left side worked out.
static func at_text(name: String, terms: Array, x: Variant, letters: Array) -> String:
	return "%s(%s) = %s" % [name, N(x), lin_text(S.at(terms, x), letters)]


static func letters_of(s: Dictionary) -> Array:
	return s.vals.keys()


## One letter typed, exact: "k = 2".
static func one(letter: String, v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, letter + " = ")
	ans.exact = true
	return ans


## Two letters typed, exact: "a = 1, b = 2".
static func two(letters: Array, v0: Q, v1: Q) -> Dictionary:
	var ans := Answer.make("named", {"v0": v0, "v1": v1}, {"names": letters})
	ans.exact = true
	return ans


static func pair(v0: Q, v1: Q) -> Dictionary:
	return {"v0": v0, "v1": v1}


static func fin(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## "f′(x) = 2kx + 3." with the function first in words.
static func deriv_line(s: Dictionary, rep: String, d: Array) -> String:
	var head := "Let f(x) = %s, so " % poly(s.terms) if rep == "words" else ""
	return head + "f′(x) = %s." % poly(d)


## Solve one letter from c·k + n = r: "So 4k = 8 and k = 2."
static func solve_line(terms: Array, x: Variant, rhs: Variant, letter: String, v: Q) -> String:
	var lin := S.at(terms, x)
	var c: Q = lin[letter]
	var r := Q.of(rhs).sub(lin.get("", Q.new(0)))
	if c.eq(1):
		return "So %s = %s." % [letter, N(v)]
	return "So %s = %s and %s = %s." % [SUM([[c, letter]]), N(r), letter, N(v)]


## The derivative a student gets by differentiating `letter` as if it were x: the product rule on
## letter·xⁿ adds xⁿ.
static func slip_deriv(terms: Array, letter: String) -> Array:
	var out: Array = S.deriv(terms)
	for t in terms:
		if t.l == letter:
			var at := 0
			while at < out.size() and out[at].p >= t.p:
				at += 1
			out.insert(at, S.T(1, "", t.p))
	return out


## A pair solved from two conditions, as "a = 1, b = 2" in the answer's form.
static func pair_text(letters: Array, sol: Array) -> String:
	return "%s = %s, %s = %s" % [letters[0], N(sol[0]), letters[1], N(sol[1])]


# ── t5-ext-unknown-coefficients ──────────────────────────────

func u_k_from_gradient(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var k: Q = s.vals.k
	var x0: int = s.x0
	var d := S.deriv(s.terms)
	var ans := one("k", k)
	var out := {"asked": "Find k.", "answer": ans}
	if rep == "words":
		out.lines = ["The curve y = %s has gradient %s at the point where x = %s." % [poly(s.terms), N(s.m), N(x0)]]
	else:
		out.lines = ["f(x) = %s" % poly(s.terms), "f′(%s) = %s." % [N(x0), N(s.m)]]
	out.wrongs = [wrong({"v": s.wrong.k}, R_INTO_F)]
	out.generic = [{"v": k.neg()}, {"v": k.mul(2)}, {"v": k.add(1)}]
	out.methods = {"form-equations": method([deriv_line(s, rep, d),
		"%s = %s." % [at_text("f′", d, x0, ["k"]), N(s.m)],
		solve_line(d, x0, s.m, "k", k)], ans.values)}
	# The slip: k differentiated as if it were x.
	var bad := slip_deriv(s.terms, "k")
	var kb: Variant = S.solve_one(bad, x0, s.m, "k")
	var lines := ["f′(x) = %s" % poly(bad), "%s = %s" % [at_text("f′", bad, x0, ["k"]), N(s.m)],
		equation(bad, x0, s.m, ["k"]), "k = %s" % N(kb)]
	var at := 0
	if rng.chance(0.5):
		lines = ["The gradient at x = %s is f′(%s), so f′(%s) = %s" % [N(x0), N(x0), N(x0), N(s.m)]] + lines.slice(0, 2) + [lines[3]]
		at = 1
	out.spot = {"lines": lines, "bad": at, "ref": R_DIFF_LETTER, "why": "k is a constant, so it stays in front: the derivative of %s is %s, with no extra term" % [poly([s.terms[0]]), poly(S.deriv([s.terms[0]]))]}
	return out


## The two equations and their working, by hand and by the GDC's solver.
static func two_methods(s: Dictionary, rep: String, conds: Array, ans: Dictionary) -> Dictionary:
	var letters := letters_of(s)
	var d := S.deriv(s.terms)
	var eqs: Array = conds.map(func(c): return equation(c[0], c[1], c[2], letters))
	var says: Array = []
	for i in conds.size():
		says.append("%s(%s) = %s gives %s." % [conds[i][3], N(conds[i][1]), N(conds[i][2]), eqs[i]])
	var sol := [s.vals[letters[0]], s.vals[letters[1]]]
	return {
		"form-equations": method([deriv_line(s, rep, d)] + says + ["Solving them together gives %s." % pair_text(letters, sol)], ans.values),
		"two-equations": method([deriv_line(s, rep, d)] + says + ["Solving them together gives %s." % pair_text(letters, sol)], ans.values),
		"gdc-solver": method([deriv_line(s, rep, d), "The conditions give %s and %s." % eqs,
			"The GDC's simultaneous equation solver gives %s." % pair_text(letters, sol)], ans.values),
	}


func u_two_from_gradient_and_point(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: Q = s.vals.a
	var b: Q = s.vals.b
	var x0: int = s.x0
	var ans := two(["a", "b"], a, b)
	var out := {"asked": "Find a and b.", "answer": ans}
	if rep == "words":
		out.lines = ["The curve y = %s passes through the point %s, where its gradient is %s." % [poly(s.terms), Fmt.point(x0, s.y0), N(s.m)]]
	else:
		out.lines = ["f(x) = %s" % poly(s.terms), "f′(%s) = %s and f(%s) = %s." % [N(x0), N(s.m), N(x0), N(s.y0)]]
	out.wrongs = [wrong(pair(s.wrong.a, s.wrong.b), R_INTO_F)]
	out.generic = [pair(b, a), pair(a.neg(), b.neg()), pair(a, b.neg()), pair(a.neg(), b)]
	var d := S.deriv(s.terms)
	var ms := two_methods(s, rep, [[d, x0, s.m, "f′"], [s.terms, x0, s.y0, "f"]], ans)
	out.methods = {"form-equations": ms["form-equations"], "gdc-solver": ms["gdc-solver"]}
	# The slip: a differentiated as if it were x.
	var bad := slip_deriv(s.terms, "a")
	var sol := S.solve_pair([[bad, x0, s.m], [s.terms, x0, s.y0]], ["a", "b"])
	var e1 := "f′(%s) = %s gives %s" % [N(x0), N(s.m), equation(bad, x0, s.m, ["a", "b"])]
	var e2 := "f(%s) = %s gives %s" % [N(x0), N(s.y0), equation(s.terms, x0, s.y0, ["a", "b"])]
	var lines := ["f′(x) = %s" % poly(bad), e1, e2, pair_text(["a", "b"], sol)]
	var at := 0
	if rng.chance(0.5):
		lines = [e2, "f′(x) = %s" % poly(bad), e1, pair_text(["a", "b"], sol)]
		at = 1
	out.spot = {"lines": lines, "bad": at, "ref": R_DIFF_LETTER, "why": "a is a constant, so the derivative of %s is %s, with no extra term" % [poly([s.terms[0]]), poly(S.deriv([s.terms[0]]))]}
	return out


func u_two_gradients(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Q = s.vals.a
	var b: Q = s.vals.b
	var ans := two(["a", "b"], a, b)
	var out := {"asked": "Find a and b.", "answer": ans}
	if rep == "words":
		out.lines = ["The gradient of the curve y = %s is %s where x = %s, and %s where x = %s." % [poly(s.terms), N(s.m), N(s.x0), N(s.m1), N(s.x1)]]
	else:
		out.lines = ["f(x) = %s" % poly(s.terms), "f′(%s) = %s and f′(%s) = %s." % [N(s.x0), N(s.m), N(s.x1), N(s.m1)]]
	out.wrongs = [wrong(pair(s.wrong.a, s.wrong.b), R_INTO_F)]
	out.generic = [pair(b, a), pair(a.neg(), b.neg()), pair(a, b.neg()), pair(a.neg(), b)]
	var d := S.deriv(s.terms)
	var ms := two_methods(s, rep, [[d, s.x0, s.m, "f′"], [d, s.x1, s.m1, "f′"]], ans)
	out.methods = {"form-equations": ms["form-equations"], "gdc-solver": ms["gdc-solver"]}
	return out


func u_from_tangent(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Q = s.vals.a
	var b: Q = s.vals.b
	var x0: int = s.x0
	var ans := two(["a", "b"], a, b)
	var line := "y = %s" % SUM([[s.tm, "x"], [s.tc, ""]])
	var out := {"asked": "Find a and b.", "answer": ans}
	if rep == "words":
		out.lines = ["The line %s is the tangent to the curve y = %s at the point where x = %s." % [line, poly(s.terms), N(x0)]]
	else:
		out.lines = ["f(x) = %s" % poly(s.terms), "The tangent to y = f(x) at x = %s is %s." % [N(x0), line]]
	out.wrongs = [wrong(pair(s.wrong.a, s.wrong.b), R_TANGENT_C)]
	out.generic = [pair(b, a), pair(a.neg(), b.neg()), pair(a, b.neg()), pair(a.neg(), b)]
	var d := S.deriv(s.terms)
	var letters := ["a", "b"]
	var e1 := equation(d, x0, s.tm, letters)
	var e2 := equation(s.terms, x0, s.y0, letters)
	var touch := "On the tangent at x = %s, y = %s, so f(%s) = %s: %s." % [N(x0), N(s.y0), N(x0), N(s.y0), e2]
	var sol := pair_text(letters, [a, b])
	out.methods = {
		"form-equations": method([deriv_line(s, rep, d), "The tangent's gradient is %s, so f′(%s) = %s: %s." % [N(s.tm), N(x0), N(s.tm), e1], touch,
			"Solving them together gives %s." % sol], ans.values),
		"gdc-solver": method([deriv_line(s, rep, d), "f′(%s) = %s gives %s." % [N(x0), N(s.tm), e1], touch,
			"The GDC's simultaneous equation solver gives %s." % sol], ans.values),
	}
	return out


# ── t5-ext-stationary-conditions ─────────────────────────────

func u_k_from_stationary_x(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: Q = s.vals.k
	var x0: int = s.x0
	var d := S.deriv(s.terms)
	var ans := one("k", k)
	var out := {"asked": "Find k.", "answer": ans}
	if rep == "words":
		out.lines = ["The curve y = %s has a stationary point where x = %s." % [poly(s.terms), N(x0)]]
	else:
		out.lines = ["f(x) = %s" % poly(s.terms), "The graph of f has a stationary point at x = %s." % N(x0)]
	out.wrongs = [wrong({"v": s.wrong.k}, R_F_ZERO)]
	out.generic = [{"v": k.neg()}, {"v": k.mul(2)}, {"v": k.add(1)}]
	out.methods = {"two-equations": method([deriv_line(s, rep, d),
		"At a stationary point f′(%s) = 0: %s = 0." % [N(x0), lin_text(S.at(d, x0), ["k"])],
		solve_line(d, x0, 0, "k", k)], ans.values)}
	return out


func u_two_from_stationary_point(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: Q = s.vals.a
	var b: Q = s.vals.b
	var x0: int = s.x0
	var ans := two(["a", "b"], a, b)
	var out := {"asked": "Find a and b.", "answer": ans}
	var pt := Fmt.point(x0, s.y0)
	if rep == "words":
		out.lines = ["The curve y = %s has a stationary point at %s." % [poly(s.terms), pt]]
	else:
		out.lines = ["f(x) = %s" % poly(s.terms), "The graph of f has a stationary point at %s." % pt]
	out.wrongs = [wrong(pair(s.wrong.a, s.wrong.b), R_Y_INTO)]
	out.generic = [pair(b, a), pair(a.neg(), b.neg()), pair(a, b.neg()), pair(a.neg(), b)]
	var d := S.deriv(s.terms)
	var ms := two_methods(s, rep, [[d, x0, 0, "f′"], [s.terms, x0, s.y0, "f"]], ans)
	out.methods = {"two-equations": ms["two-equations"], "gdc-solver": ms["gdc-solver"]}
	# The slip: a picked from f′(x0) = 0 alone, which any multiple of (a, b) solves.
	var ab := a.add(1) if not a.add(1).is_zero() else a.add(2)
	var bb := _b_from(d, x0, ab)
	var picked := "f′(%s) = 0 has many solutions; take a = %s, so b = %s" % [N(x0), N(ab), N(bb)]
	var f_bad := poly([S.T(ab, "", 3), S.T(bb, "", 2), s.terms[2]])
	var e1 := "f′(%s) = 0 gives %s" % [N(x0), equation(d, x0, 0, ["a", "b"])]
	var lines := ["f′(x) = %s" % poly(d), e1, picked, "So f(x) = %s" % f_bad]
	var at := 2
	if rng.chance(0.5):
		lines = ["The point %s is on the curve, and f′(%s) = 0" % [pt, N(x0)], "f′(x) = %s" % poly(d), e1, picked]
		at = 3
	out.spot = {"lines": lines, "bad": at, "ref": R_ONE_CONDITION, "why": "f′(%s) = 0 gives one equation for two unknowns; f(%s) = %s is needed too, and it fixes a = %s" % [N(x0), N(x0), N(s.y0), N(a)]}
	return out


## b from f′(x0) = 0 once a is chosen: 3a·x0² + 2b·x0 = 0.
static func _b_from(d: Array, x0: int, av: Q) -> Q:
	var lin := S.at(d, x0)
	return av.mul(lin.a).neg().div(lin.b)


func u_k_from_inflexion(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: Q = s.vals.p
	var x0: int = s.x0
	var d := S.deriv(s.terms)
	var d2 := S.deriv(d)
	var ans := one("p", p)
	var out := {"asked": "Find p.", "answer": ans}
	if rep == "words":
		out.lines = ["The curve y = %s has a point of inflexion where x = %s." % [poly(s.terms), N(x0)]]
	else:
		out.lines = ["f(x) = %s" % poly(s.terms), "The graph of f has a point of inflexion at x = %s." % N(x0)]
	out.wrongs = [wrong({"v": s.wrong.p}, R_INFLEXION_F1)]
	out.generic = [{"v": p.neg()}, {"v": p.div(3)}, {"v": p.add(1)}]
	out.methods = {"two-equations": method([deriv_line(s, rep, d), "f″(x) = %s." % poly(d2),
		"At a point of inflexion f″(%s) = 0: %s = 0." % [N(x0), lin_text(S.at(d2, x0), ["p"])],
		solve_line(d2, x0, 0, "p", p)], ans.values)}
	return out


func u_two_from_two_stationary(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: Q = s.vals.b
	var c: Q = s.vals.c
	var lead: Q = s.terms[0].c
	var ans := two(["b", "c"], b, c)
	var out := {"asked": "Find b and c.", "answer": ans}
	if rep == "words":
		out.lines = ["The curve y = %s has stationary points where x = %s and where x = %s." % [poly(s.terms), N(s.p), N(s.q)]]
	else:
		out.lines = ["f(x) = %s" % poly(s.terms), "The graph of f has stationary points at x = %s and x = %s." % [N(s.p), N(s.q)]]
	out.wrongs = [wrong(pair(s.wrong.b, s.wrong.c), R_NO_LEAD)]
	out.generic = [pair(b.neg(), c), pair(c, b), pair(b, c.neg()), pair(b.neg(), c.neg())]
	var d := S.deriv(s.terms)
	var ms := two_methods(s, rep, [[d, s.p, 0, "f′"], [d, s.q, 0, "f′"]], ans)
	var three := lead.mul(3)
	var factored := "%s%s%s" % [Fmt.lead(three), Fmt.factor(s.p), Fmt.factor(s.q)]
	var expanded := poly([S.T(three, "", 2), S.T(three.mul(-(s.p + s.q)), "", 1), S.T(three.mul(s.p * s.q), "", 0)])
	out.methods = {"two-equations": ms["two-equations"], "gdc-solver": ms["gdc-solver"],
		"factor-form": method(["f′(x) = %s, a quadratic with roots %s and %s and leading coefficient %s." % [poly(d), N(s.p), N(s.q), N(three)],
			"So f′(x) = %s = %s." % [factored, expanded],
			"Comparing coefficients: 2b = %s and c = %s." % [N(three.mul(-(s.p + s.q))), N(c)],
			"So b = %s, c = %s." % [N(b), N(c)]], ans.values)}
	return out
