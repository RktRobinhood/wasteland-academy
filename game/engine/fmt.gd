class_name Fmt
extends RefCounted
## Writes numbers, points and the three quadratic forms as students see them: a true
## minus sign, x² (and x³, x⁴ for the cubic), "½" for a half as a leading coefficient, and "(3/2)x" for any other
## fraction in front of x. tools/check_answers.py parses these strings back with SymPy,
## so a formatting slip is caught as a wrong question.

## Multiply by this before rounding a scaled value: an exact tie lands a hair low in binary
## (1.025 ÷ 0.01 = 102.49999…) and must still round away from zero.
const TIE := 1.0 + 1e-14


## s cut at its powers, for a label that can raise them: "e^(4x − 3)" is
## [["e", false], ["4x − 3", true]]. The brackets round a power go, as on paper. A ^ with
## no power after it stays as it is.
static func power_runs(s: String) -> Array:
	var out := []
	var plain := ""
	var i := 0
	while i < s.length():
		var end := _power_end(s, i + 1) if s[i] == "^" else 0
		if end <= i + 1:
			plain += s[i]
			i += 1
			continue
		if plain != "":
			out.append([plain, false])
			plain = ""
		var bracketed := s[i + 1] == "("
		out.append([s.substr(i + 2, end - i - 3) if bracketed else s.substr(i + 1, end - i - 1), true])
		i = end
	if plain != "":
		out.append([plain, false])
	return out


## Where the power that starts at index at ends, or at if there isn't one: a bracket with
## its match, or a number or letters. A full stop after them ends the sentence, not the power.
static func _power_end(s: String, at: int) -> int:
	if at >= s.length():
		return at
	if s[at] == "(":
		var depth := 0
		for j in range(at, s.length()):
			depth += int(s[j] == "(") - int(s[j] == ")")
			if depth == 0:
				return j + 1
		return at
	var j := at + 1 if s[at] in ["−", "-"] else at
	var start := j
	while j < s.length():
		var dot: bool = s[j] == "." and j > start and j + 1 < s.length() and s[j + 1].is_valid_int()
		if not dot and not s[j].is_valid_int() and s[j] != "½" and s[j].to_lower() == s[j].to_upper():
			break
		j += 1
	return j if j > start else at


static func num(v: Variant) -> String:
	return Q.of(v).text()


## A number to n significant figures, with trailing zeros kept: sf(6.9993) is "7.00",
## sf(1234.5) is "1230". Rounds half away from zero, as Answer.number_right does.
static func sf(v: Variant, n: int = 3) -> String:
	var x: float = v.to_float() if v is Q else float(v)
	if x == 0.0:
		return "0"
	var e := floori(log(absf(x)) / log(10.0) + 1e-12)
	var r := roundf(x / pow(10.0, e - n + 1) * TIE) * pow(10.0, e - n + 1)
	if absf(r) >= pow(10.0, e + 1):
		e += 1
	var places := maxi(0, n - 1 - e)
	return ("−" if r < 0.0 else "") + ("%.*f" % [places, absf(r)])


## A working value to n s.f., without the zeros a GDC doesn't show: "1.5708", not "1.57080".
static func work(v: Variant, n: int) -> String:
	var t := sf(v, n)
	return t.rstrip("0").rstrip(".") if t.contains(".") else t


## A number as a decimal when it ends ("0.35", "−2.5", "3"), else as a fraction ("1/6").
static func dec(v: Variant) -> String:
	var q := Q.of(v)
	var scale := 1
	var places := 0
	while scale % q.d != 0:
		scale *= 10
		places += 1
		if places > 9:
			return q.text()
	var whole := absi(q.n) * (scale / q.d)
	var digits := str(whole).lpad(places + 1, "0")
	var body := digits if places == 0 else digits.left(digits.length() - places) + "." + digits.right(places)
	return ("−" if q.n < 0 else "") + body


## An amount of money: "3" for whole dollars, else two decimal places ("2.50").
static func money(v: Variant) -> String:
	var q := Q.of(v)
	if q.is_int():
		return q.text()
	var cents := roundi(q.to_float() * 100.0)
	return ("−" if cents < 0 else "") + "%d.%02d" % [absi(cents) / 100, absi(cents) % 100]


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
## letter is the variable: term(c, 2, true, "k") is "−2k²".
static func term(c: Q, power: int, first: bool, letter: String = "x") -> String:
	var mag := c.abs_q()
	var body := ""
	var v: String = "" if power == 0 else letter + ["", "", "²", "³", "⁴"][power]
	if power == 0:
		body = mag.text()
	else:
		body = lead(mag) + v
	if first:
		return ("−" if c.sign() < 0 else "") + body
	return (" − " if c.sign() < 0 else " + ") + body


## Polynomial from coefficients, highest power first, skipping zero terms.
static func poly(coeffs: Array, letter: String = "x") -> String:
	var out := ""
	var power := coeffs.size() - 1
	for c in coeffs:
		var q := Q.of(c)
		if not q.is_zero():
			out += term(q, power, out == "", letter)
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


# ── Quadratics extension types (FAL-459) ─────────────────────

const SUPS := {"0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹", "-": "⁻"}


## A power as a superscript after a letter: "" for 1, "²", "⁻³".
static func sup(power: Variant) -> String:
	var p := int(power)
	if p == 1:
		return ""
	var out := ""
	for ch in str(p):
		out += SUPS[ch]
	return out


## A sum of c·xⁿ in the order given, skipping zero terms: terms([3, −1/4], [−2, −3])
## is "3x⁻² − (1/4)x⁻³". A power of 0 is the number itself. With dec, coefficients
## are decimals when they end ("−4.9t² + 19.6t + 1.5").
static func terms(coeffs: Array, powers: Array, letter: String = "x", decimal: bool = false) -> String:
	var out := ""
	for i in coeffs.size():
		var c := Q.of(coeffs[i])
		if c.is_zero():
			continue
		var p := int(powers[i])
		var mag := c.abs_q()
		var body: String
		if decimal:
			body = dec(mag) if p == 0 else ("" if mag.eq(1) else dec(mag)) + letter + sup(p)
		else:
			body = mag.text() if p == 0 else lead(mag) + letter + sup(p)
		if out == "":
			out = ("−" if c.sign() < 0 else "") + body
		else:
			out += (" − " if c.sign() < 0 else " + ") + body
	return out if out != "" else "0"


## A multiple of π: "π", "5π/6", "−π/2", "2π", "0".
static func pi(v: Variant) -> String:
	var q := Q.of(v)
	if q.is_zero():
		return "0"
	var top := "π" if absi(q.n) == 1 else "%dπ" % absi(q.n)
	return ("−" if q.n < 0 else "") + top + ("" if q.d == 1 else "/%d" % q.d)
