class_name Fmt
extends RefCounted
## Writes numbers, points and the three quadratic forms as students see them: a true
## minus sign, x² (and x³, x⁴ for the cubic), "½" for a half as a leading coefficient, and "(3/2)x" for any other
## fraction in front of x. tools/check_answers.py parses these strings back with SymPy,
## so a formatting slip is caught as a wrong question.


static func num(v: Variant) -> String:
	return Q.of(v).text()


static func point(x: Variant, y: Variant) -> String:
	return "(%s, %s)" % [num(x), num(y)]


## The coefficient in front of a bracket or x: "" for 1, "−" for −1, "½", "−½", "2",
## "(3/2)".
static func lead(v: Variant) -> String:
	var q := Q.of(v)
	if q.eq(1):
		return ""
	if q.eq(-1):
		return "−"
	if q.eq(Q.new(1, 2)):
		return "½"
	if q.eq(Q.new(-1, 2)):
		return "−½"
	if q.is_int():
		return q.text()
	return ("−" if q.sign() < 0 else "") + "(%s)" % q.abs_q().text()


## One term c·x^power, with its sign joined on: first term "−2x²", later terms " − 2x²".
static func term(c: Q, power: int, first: bool) -> String:
	var mag := c.abs_q()
	var body := ""
	var v: String = ["", "x", "x²", "x³", "x⁴"][power]
	if power == 0:
		body = mag.text()
	else:
		body = lead(mag) + v
	if first:
		return ("−" if c.sign() < 0 else "") + body
	return (" − " if c.sign() < 0 else " + ") + body


## Polynomial from coefficients, highest power first, skipping zero terms.
static func poly(coeffs: Array) -> String:
	var out := ""
	var power := coeffs.size() - 1
	for c in coeffs:
		var q := Q.of(c)
		if not q.is_zero():
			out += term(q, power, out == "")
		power -= 1
	return out if out != "" else "0"


static func general(a: Variant, b: Variant, c: Variant) -> String:
	return poly([a, b, c])


## (x − r): "(x + 1)" for r = −1, "x" for r = 0.
static func factor(r: Variant) -> String:
	var q := Q.of(r)
	if q.is_zero():
		return "x"
	return "(x %s %s)" % ["+" if q.sign() < 0 else "−", q.abs_q().text()]


static func factorised(a: Variant, p: Variant, q: Variant) -> String:
	return lead(a) + factor(p) + factor(q)


## a(x − h)² + k: "2(x − 3)² − 4", "−x² + 5" when h = 0.
static func vertex(a: Variant, h: Variant, k: Variant) -> String:
	var hq := Q.of(h)
	var kq := Q.of(k)
	var sq := "x²" if hq.is_zero() else factor(hq) + "²"
	var out := lead(a) + sq
	if not kq.is_zero():
		out += (" − " if kq.sign() < 0 else " + ") + kq.abs_q().text()
	return out


## " + 3" or " − 3": a number joined onto an expression.
static func plus(v: Variant) -> String:
	var q := Q.of(v)
	return (" − " if q.sign() < 0 else " + ") + q.abs_q().text()


## A number in brackets when negative, for substituting: "(−2)".
static func paren(v: Variant) -> String:
	var q := Q.of(v)
	return "(%s)" % q.text() if q.sign() < 0 or not q.is_int() else q.text()
