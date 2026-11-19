class_name ConjugateRootsViews
extends ComplexPolarViews
## The views of t1-ahl-conjugate-roots (AHL1.14, FAL-1005) on the `complex-polar` recipe: a real
## quadratic with roots h ± ki, and a real cubic with roots h ± ki and a whole t. They share
## ComplexPolarViews' writing helpers; every question is Paper 1 but a GDC method's.
##
## Answers: the roots as h ± ki (slots h and k), a quadratic z² + pz + q = 0 (slots p and q), a
## root a + bi (cart_ans), the real root as a number, and a cubic's three coefficients (slots ca,
## cb and cd: the engine drops any option whose slot "a" is 0).

const AQ := "AHL1.14.complex-quadratic#"
const AC := "AHL1.14.conjugate-root-polynomial#"
const TC := "t1-ahl-conjugate-roots#"
const CR_UNKNOWNS := ["solve-quadratic", "quadratic-from-root", "other-root", "real-root", "cubic-coefficients"]


## slip key -> the type's misconception ref (t1-ahl-conjugate-roots' list, in order).
func slips() -> Dictionary:
	return {
		"sqrt-neg": AQ + "0", "half-only": AQ + "1", "sum-sign": AQ + "2", "real-sign": AC + "0", "factor-sign": AC + "1",
		"h-sign": TC + "5", "not-halved": TC + "6", "i2-product": TC + "7", "half-sum": TC + "8", "negate": TC + "9",
		"cubic-sum-sign": TC + "10", "product-sign": TC + "11", "vieta-signs": TC + "12",
	}


func unknowns() -> Array:
	return CR_UNKNOWNS


# ── Writing things ───────────────────────────────────────────

## z² + pz + q, or any polynomial in z from its coefficients, highest power first.
static func poly(coeffs: Array) -> String:
	var powers: Array = []
	for i in coeffs.size():
		powers.append(coeffs.size() - 1 - i)
	return Fmt.terms(coeffs, powers, "z")


## h ± ki as written: "−1 ± 2i", "3 ± i".
static func pm(h: Q, k: Q) -> String:
	return "%s ± %s" % [h.text(), iterm(k)]


static func iterm(k: Q) -> String:
	return S.iterm(S.sd(k))


## A root h + ki or h − ki as written.
static func root(h: Q, k: Q) -> String:
	return T(S.cx(h, k))


## "(z − (2 + 3i))" for a factor.
static func factor(h: Q, k: Q) -> String:
	return "(z − (%s))" % root(h, k)


static func roots_ans(h: Q, k: Q) -> Dictionary:
	var ans := Answer.make("form", {"h": h, "k": k, "text": "z = " + pm(h, k)}, {"parts": ["z = ", {"slot": "h"}, " ± ", {"slot": "k"}, "i"]})
	ans.exact = true
	return ans


static func roots_val(h: Q, k: Q) -> Dictionary:
	return {"h": h, "k": k, "text": "z = " + pm(h, k)}


static func quad_ans(p: Q, q: Q) -> Dictionary:
	var ans := Answer.make("form", quad_val(p, q), {"parts": ["z² + ", {"slot": "p"}, "z + ", {"slot": "q"}, " = 0"]})
	ans.exact = true
	return ans


static func quad_val(p: Q, q: Q) -> Dictionary:
	return {"p": p, "q": q, "text": poly([1, p, q]) + " = 0"}


static func coef_text(a: Q, b: Q, d: Q) -> String:
	return "a = %s, b = %s, d = %s" % [a.text(), b.text(), d.text()]


static func coef_ans(a: Q, b: Q, d: Q) -> Dictionary:
	var ans := Answer.make("form", coef_val(a, b, d), {"parts": ["a = ", {"slot": "ca"}, ", b = ", {"slot": "cb"}, ", d = ", {"slot": "cd"}]})
	ans.exact = true
	return ans


static func coef_val(a: Q, b: Q, d: Q) -> Dictionary:
	return {"ca": a, "cb": b, "cd": d, "text": coef_text(a, b, d)}


## " − 4" or " + 4", for "z − 2" and "z + 3".
static func plus(v: Q) -> String:
	return Fmt.plus(v)


# ── A real quadratic ─────────────────────────────────────────

func u_solve_quadratic(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var h := Q.new(s.h)
	var k := Q.new(s.kq)
	var p := h.mul(-2)
	var q := h.sq().add(k.sq())
	var eq := poly([1, p, q]) + " = 0"
	var ans := roots_ans(h, k)
	var wr: Array = [slip("sqrt-neg", other("z = %s or z = %s" % [h.sub(k).text(), h.add(k).text()])),
		slip("half-only", roots_val(h.mul(2), k)), slip("h-sign", roots_val(h.neg(), k)), slip("not-halved", roots_val(h, k.mul(2)))]
	var fill: Array = [roots_val(h, k.sq()), roots_val(h.neg(), k.mul(2)), roots_val(k, h.abs_q())]
	var disc := p.sq().sub(q.mul(4))
	var last := "So z = %s." % pm(h, k)
	var formula: Array = ["z = (−b ± √(b² − 4ac))/(2a) = (%s ± √(%s − %s))/2" % [p.neg().text(), p.sq().text(), q.mul(4).text()],
		"√(%s) = √(%s) × √(−1) = %s, so z = (%s ± %s)/2." % [disc.text(), disc.neg().text(), iterm(k.mul(2)), p.neg().text(), iterm(k.mul(2))],
		"Divide both terms by 2. %s" % last]
	var zh := "z" + plus(h.neg())
	var square: Array = ["%s = (%s)² + %s" % [poly([1, p, q]), zh, k.sq().text()],
		"(%s)² = −%s, so %s = ±%s." % [zh, k.sq().text(), zh, iterm(k)], last]
	var gdc: Array = ["Set the GDC's polynomial solver to a + bi mode and enter the coefficients 1, %s and %s." % [p.text(), q.text()],
		"It gives z = %s and z = %s." % [root(h, k), root(h, k.neg())], last]
	return _pack([eq], "Solve the equation, giving the roots in the form h ± ki.", ans, wr, fill,
		{"quadratic-formula": formula, "complete-square": square, "gdc-solver": gdc}, rng)


func u_quadratic_from_root(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var h := Q.new(s.h)
	var k := Q.new(s.kq)
	var shown := k if rng.chance(0.5) else k.neg()
	var p := h.mul(-2)
	var q := h.sq().add(k.sq())
	var ans := quad_ans(p, q)
	var wr: Array = [slip("sum-sign", quad_val(p.neg(), q)), slip("i2-product", quad_val(p, h.sq().sub(k.sq()))), slip("half-sum", quad_val(h.neg(), q))]
	var fill: Array = [quad_val(p, q.add(2)), quad_val(p.neg(), h.sq().sub(k.sq())), quad_val(p.mul(2), q)]
	var z := root(h, shown)
	var zc := root(h, shown.neg())
	var last := "So the equation is %s = 0." % poly([1, p, q])
	var sp: Array = ["The coefficients are real, so the other root is the conjugate, %s." % zc,
		"Sum of the roots: (%s) + (%s) = %s, so p = −%s = %s." % [z, zc, h.mul(2).text(), P(h.mul(2)), p.text()],
		"Product of the roots: (%s)(%s) = %s + %s = %s, so q = %s." % [z, zc, P(h) + "²", P(k) + "²", q.text(), q.text()], last]
	var zh := "z" + plus(h.neg())
	var square: Array = ["z = %s, so %s = %s." % [z, zh, ("−" if shown.sign() < 0 else "") + iterm(k)],
		"Square both sides: (%s)² = −%s." % [zh, k.sq().text()],
		"So (%s)² + %s = 0, and (%s)² = %s." % [zh, k.sq().text(), zh, poly([1, p, h.sq()])], last]
	return _pack(["z = %s is a root of z² + pz + q = 0, where p and q are real." % z], "Find the values of p and q, and write down the equation.", ans,
		wr, fill, {"sum-product": sp, "complete-square": square}, rng)


func u_other_root(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var h := Q.new(s.h)
	var k := Q.new(s.kq)
	var shown := k if rng.chance(0.5) else k.neg()
	var z := S.cx(h, shown)
	var zc := S.cx(h, shown.neg())
	var head := "z = "
	var ans := cart_ans(head, zc)
	var wr: Array = [slip("real-sign", cwrong(ans, head, S.cx(h.neg(), shown))), slip("negate", cwrong(ans, head, S.cx(h.neg(), shown.neg())))]
	var fill: Array = [cwrong(ans, head, S.cx(shown, h)), cwrong(ans, head, S.cx(h.mul(2), shown.neg())), cwrong(ans, head, S.cx(shown.neg(), h.neg()))]
	var line: String
	var sp: Array
	var last := "So another root is z = %s." % T(zc)
	if s.mode == "quadratic":
		var p := h.mul(-2)
		var q := h.sq().add(k.sq())
		line = "One root of %s = 0 is %s." % [poly([1, p, q]), T(z)]
		sp = ["The sum of the roots of z² + pz + q = 0 is −p = %s." % p.neg().text(), "So the other root is %s − (%s) = %s." % [p.neg().text(), T(z), T(zc)], last]
	else:
		line = "A cubic equation with real coefficients has a root %s." % T(z)
		sp = ["The non-real roots of a real polynomial come in pairs whose sum and product are real.",
			"For a root %s, only %s gives a real sum, %s, and a real product, %s." % [T(z), T(zc), h.mul(2).text(), h.sq().add(k.sq()).text()], last]
	var sub: Array = ["The coefficients are real, so taking the conjugate of P(z) = 0 gives P(z*) = 0.",
		"So the conjugate of %s is a root too: change the sign of the imaginary part only." % T(z), last]
	return _pack([line], "Write down another root of the equation.", ans, wr, fill, {"sum-product-roots": sp, "substitute-root": sub}, rng)


# ── A real cubic ─────────────────────────────────────────────

func u_real_root(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var h := Q.new(s.h)
	var k := Q.new(s.kq)
	var t := Q.new(s.t)
	var a := Q.new(s.a)
	var b := Q.new(s.b)
	var d := Q.new(s.d)
	var m := h.sq().add(k.sq())
	var shown := k if rng.chance(0.5) else k.neg()
	var z := root(h, shown)
	var zc := root(h, shown.neg())
	var head := "z = "
	var ans := Answer.make("number", {"v": t}, {}, head)
	var wr: Array = [slip("factor-sign", {"v": h.mul(2).sub(a)}), slip("cubic-sum-sign", {"v": a.sub(h.mul(2))}), slip("product-sign", {"v": d.div(m)})]
	var fill: Array = [{"v": t.add(1)}, {"v": t.neg().add(1)}, {"v": h}]
	var quad := poly([1, h.mul(-2), m])
	var last := "So the real root is z = %s." % t.text()
	var divide: Array = ["The coefficients are real, so %s is also a root." % zc,
		"%s%s = %s is a factor." % [factor(h, shown), factor(h, shown.neg()), quad],
		"%s = (%s)(z − t): the constant terms give −%st = %s, so t = %s." % [poly([1, a, b, d]), quad, m.text(), d.text(), t.text()], last]
	var sp: Array = ["The coefficients are real, so %s is also a root." % zc,
		"The sum of the roots is −a: (%s) + (%s) + t = %s + t = %s." % [z, zc, h.mul(2).text(), a.neg().text()],
		"So t = %s − %s = %s." % [a.neg().text(), P(h.mul(2)), t.text()], last]
	var gdc: Array = ["Set the GDC's polynomial solver to a + bi mode and enter the coefficients 1, %s, %s and %s." % [a.text(), b.text(), d.text()],
		"It gives z = %s, z = %s and z = %s." % [t.text(), z, zc], last]
	return _pack(["%s = 0" % poly([1, a, b, d]), "One root of this equation is %s." % z], "Find the real root of the equation.", ans, wr, fill,
		{"quadratic-factor-divide": divide, "sum-product-roots": sp, "gdc-solver": gdc}, rng)


func u_cubic_coefficients(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var h := Q.new(s.h)
	var k := Q.new(s.kq)
	var t := Q.new(s.t)
	var a := Q.new(s.a)
	var b := Q.new(s.b)
	var d := Q.new(s.d)
	var m := h.sq().add(k.sq())
	var shown := k if rng.chance(0.5) else k.neg()
	var z := root(h, shown)
	var zc := root(h, shown.neg())
	var ans := coef_ans(a, b, d)
	# (z² + 2hz + m)(z − t), the factor with the wrong sign; and m with i² taken as +1.
	var fs := [h.mul(2).sub(t), m.sub(h.mul(2).mul(t)), m.mul(t).neg()]
	var m2 := h.sq().sub(k.sq())
	var wr: Array = [slip("factor-sign", coef_val(fs[0], fs[1], fs[2])), slip("vieta-signs", coef_val(a.neg(), b, d.neg())),
		slip("i2-product", coef_val(a, m2.add(h.mul(2).mul(t)), m2.mul(t).neg()))]
	var fill: Array = [coef_val(a, b.neg(), d), coef_val(a.add(1), b, d), coef_val(a, b, d.neg())]
	var quad := poly([1, h.mul(-2), m])
	var last := "So %s." % coef_text(a, b, d)
	var divide: Array = ["The coefficients are real, so %s is also a root, and %s%s = %s is a factor." % [zc, factor(h, shown), factor(h, shown.neg()), quad],
		"The cubic is (%s)(z%s)." % [quad, plus(t.neg())],
		"Multiplying out gives %s." % poly([1, a, b, d]), last]
	var sp: Array = ["The coefficients are real, so the roots are %s, %s and %s." % [z, zc, t.text()],
		"Sum: %s + %s = %s = −a, so a = %s." % [h.mul(2).text(), P(t), h.mul(2).add(t).text(), a.text()],
		"Pairs: %s + %s × %s = %s = b, and product: %s × %s = %s = −d." % [m.text(), h.mul(2).text(), P(t), b.text(), m.text(), P(t), d.neg().text()], last]
	return _pack(["z³ + az² + bz + d = 0, where a, b and d are real, has roots %s and %s." % [z, t.text()]], "Find the values of a, b and d.", ans, wr, fill,
		{"quadratic-factor-divide": divide, "sum-product-roots": sp}, rng)
