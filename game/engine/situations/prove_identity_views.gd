class_name ProveIdentityViews
extends ExtensionViews
## The views on the `prove-identity` situation: one builder per unknown of t3-prove-identity
## (FAL-753). A phone can't read a written proof, so each unknown is one decision inside a proof,
## with one right answer that code works out: the simplified form, a line, the first wrong line
## and its fix, the form of cos 2x that cancels the 1, the side to start from, which of four
## arguments is a proof, or a value once the identity holds.
##
## Every proof is a chain of lines (chain()), built from the situation's numbers. A chain can be
## built with a slip: the same work with one wrong move, carried down until no line can be written,
## so wrong options are what that slip really gives. A line's last form, where it has one, is
## typed in slots; every other line is picked (AlgebraicProofViews' `claim` answers).
##
## Representations: "equation" (written out) and "words" (a sentence). `given` is the situation,
## plus which line a question hid or spoiled, for the SymPy checker.

const SKILL := "SL3.6.prove-identity#"
const R_BOTH := SKILL + "0"
const R_SUM := SKILL + "1"
const R_KEEP := SKILL + "2"
const R_VALUES := SKILL + "3"
const R_NO_END := SKILL + "4"
const R_SIGN := SKILL + "5"
const R_DOUBLE := SKILL + "6"
const R_FORM := SKILL + "7"
const R_PYTH := SKILL + "8"
const R_MID := SKILL + "9"
const R_NOMID := SKILL + "10"
const R_ARG := SKILL + "11"
const R_DIFF := SKILL + "12"
const R_TAN := SKILL + "13"
const R_COEF := SKILL + "14"
const R_EXT := SKILL + "15"
const R_PRE := SKILL + "16"
const R_AT := SKILL + "17"
const R_WHICH := SKILL + "18"
const R_ADD := SKILL + "19"
const R_PART := SKILL + "20"
const R_COEFSQ := SKILL + "21"
const R_FACT := SKILL + "22"
const R_SIMPLE := SKILL + "23"

## statement -> the slips chain() can make on it.
const SLIPS := {
	"half-tan": [R_SIGN, R_DOUBLE, R_FORM],
	"half-tan-plus": [R_DOUBLE, R_FORM],
	"product": [R_COEF, R_ARG],
	"double-twice": [R_COEF, R_ARG],
	"square": [R_MID, R_NOMID],
	"quartic-diff": [R_DIFF, R_PYTH, R_WHICH],
	"quartic-sin": [R_SIGN, R_COEFSQ, R_DOUBLE],
	"reciprocal-sum": [R_DOUBLE, R_ADD],
	"tan-diff": [R_TAN, R_PART, R_WHICH],
	"tan-ratio": [R_TAN, R_SUM, R_WHICH],
	"tan-double": [R_TAN, R_FORM, R_WHICH],
	"factor-sum": [R_SIGN, R_FORM, R_DOUBLE],
	"perfect-square": [R_FACT, R_FORM, R_COEFSQ],
	"split": [R_SUM, R_DOUBLE],
}
const OTHER_ROUTE := "These lines take a different route from that method, so work through them line by line."
const UNSUITED := "This statement does not suit that method, so work through it line by line."
const POWERS := {2: "²", 3: "³", 4: "⁴"}
const HAS_LIMITS := ["half-tan", "half-tan-plus", "reciprocal-sum", "tan-diff", "tan-ratio", "tan-double", "split"]

const UNKNOWNS := ["simplified-result", "next-line", "missing-line", "flawed-line", "valid-argument", "start-side", "true-identity", "cos2-form", "half-form",
	"sin2-multiple", "cancel-fraction", "factor-structure", "identity-value", "value-from-ratio", "greatest-value", "common-expression"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = ProveIdentitySituation.export(s)
	out.given.merge(out.get("shown", {}))
	said_once(out.methods, out.answer)
	return out


# ── Writing a line ───────────────────────────────────────────

## m times the letter times w: "x", "2x", "8θ".
static func ang(s: Dictionary, m: int) -> String:
	var n: int = m * int(s.w)
	return ("" if n == 1 else str(n)) + str(s.letter)


## "sin 2x", "sin²2x".
static func F(fn: String, a: String, p: int = 1) -> String:
	return "%s %s" % [fn, a] if p == 1 else fn + POWERS[p] + a


## "sin x cos x".
static func sc(s: Dictionary) -> String:
	var u := ang(s, 1)
	return "sin %s cos %s" % [u, u]


## A number in front of a body: "3 sin x", "sin x", "−sin x", "(3/2) sin x", "3(1 − sin x)".
static func lead(c: Variant, body: String) -> String:
	var q := Q.of(c)
	var mag := q.abs_q()
	var head := ""
	if not mag.eq(Q.new(1)):
		head = mag.text() if mag.is_int() else "(%s)" % mag.text()
	var gap := "" if head == "" or body.begins_with("(") else " "
	return ("−" if q.sign() < 0 else "") + head + gap + body


## "3(1 − sin x)", and with no number no bracket either.
static func whole(k: int, inner: String) -> String:
	return inner if k == 1 else lead(k, "(%s)" % inner)


## A line: its text and what it did. v and parts, where a slot form can type it.
static func L(text: String, why: String = "", v: Dictionary = {}, parts: Array = []) -> Dictionary:
	return {"text": text, "why": why, "v": v, "parts": parts}


## a fn bx, typed as a and b. m counts u, so b is mw.
static func wave(s: Dictionary, fn: String, a: Variant, m: int, why: String = "") -> Dictionary:
	return L(lead(a, F(fn, ang(s, m))), why, {"a": Q.of(a), "b": Q.new(m * int(s.w))}, [{"slot": "a"}, " %s " % fn, {"slot": "b"}, s.letter])


## a sin²bx or a cos⁴bx, typed as a and b.
static func power(s: Dictionary, fn: String, p: int, a: Variant, m: int, why: String = "") -> Dictionary:
	return L(lead(a, F(fn, ang(s, m), p)), why, {"a": Q.of(a), "b": Q.new(m * int(s.w))}, [{"slot": "a"}, " %s%s" % [fn, POWERS[p]], {"slot": "b"}, s.letter])


## a/sin bx, typed as a and b.
static func over(s: Dictionary, a: int, m: int, why: String = "") -> Dictionary:
	return L("%s/sin %s" % [Fmt.num(a), ang(s, m)], why, {"a": Q.new(a), "b": Q.new(m * int(s.w))}, [{"slot": "a"}, "/sin ", {"slot": "b"}, s.letter])


## sin 2u = 2 sin u cos u, for the working.
static func sin2(s: Dictionary, m: int = 1) -> String:
	var u := ang(s, m)
	return "sin %s = 2 sin %s cos %s" % [ang(s, 2 * m), u, u]


## cos 2u in the form with only fn: "1 − 2 sin²u" or "2 cos²u − 1".
static func cos2_form(s: Dictionary, fn: String) -> String:
	var u := ang(s, 1)
	return "1 − 2 " + F("sin", u, 2) if fn == "sin" else "2 %s − 1" % F("cos", u, 2)


static func cos2(s: Dictionary, fn: String) -> String:
	return "cos %s = %s" % [ang(s, 2), cos2_form(s, fn)]


static func other(fn: String) -> String:
	return "cos" if fn == "sin" else "sin"


## Which function the double angle's cosine turns into, to cancel a 1.
static func base_of(s: Dictionary) -> String:
	return {"half-tan": "sin", "half-tan-plus": "cos"}.get(s.fam, s.get("base", "sin"))


# ── The chains ───────────────────────────────────────────────

## A proof as lines, from the left side to the right. slip (see SLIPS) makes one wrong move and
## carries it on, and the chain stops where the next line can't be written.
static func chain(s: Dictionary, slip: String = "") -> Array:
	match s.fam:
		"half-tan":
			return _half_tan(s, slip)
		"half-tan-plus":
			return _half_tan_plus(s, slip)
		"product":
			return _product(s, slip)
		"double-twice":
			return _double_twice(s, slip)
		"square":
			return _square(s, slip)
		"quartic-diff":
			return _quartic_diff(s, slip)
		"quartic-sin":
			return _quartic_sin(s, slip)
		"reciprocal-sum":
			return _reciprocal_sum(s, slip)
		"tan-diff":
			return _tan_diff(s, slip)
		"tan-ratio":
			return _tan_ratio(s, slip)
		"tan-double":
			return _tan_double(s, slip)
		"factor-sum":
			return _factor_sum(s, slip)
		"perfect-square":
			return _perfect_square(s, slip)
		"split":
			return _split(s, slip)
	return []


static func _half_tan(s: Dictionary, slip: String) -> Array:
	var k: int = s.k
	var u := ang(s, 1)
	var d := ang(s, 2)
	var ss := F("sin", u, 2)
	var den := "(%s)" % (sc(s) if slip == R_DOUBLE else "2 " + sc(s))
	var out := [L(lead(k, "(1 − cos %s)" % d) + "/sin " + d)]
	if slip == R_FORM:
		out.append(L(lead(k, "(1 − (2 %s − 1))" % ss) + "/" + den))
		out.append(L(lead(k, "(2 − 2 %s)" % ss) + "/" + den))
		out.append(L("%d %s/%s" % [2 * k, F("cos", u, 2), den]))
		out.append(L(lead(k, "cos %s/sin %s" % [u, u])))
		return out
	var top := -2 * k if slip == R_SIGN else 2 * k
	var a: int = top if slip == R_DOUBLE else top / 2
	out.append(L(lead(k, "(1 − (%s))" % cos2_form(s, "sin")) + "/" + den, "Use %s and %s" % [cos2(s, "sin"), sin2(s)]))
	out.append(L(lead(top, ss) + "/" + den, "The 1s cancel"))
	out.append(L(lead(a, "sin %s/cos %s" % [u, u]), "Cancel 2 sin %s" % u))
	out.append(wave(s, "tan", a, 1, "sin %s/cos %s = tan %s" % [u, u, u]))
	return out


static func _half_tan_plus(s: Dictionary, slip: String) -> Array:
	var k: int = s.k
	var u := ang(s, 1)
	var d := ang(s, 2)
	var cc := F("cos", u, 2)
	var top := sc(s) if slip == R_DOUBLE else "2 " + sc(s)
	var inner := "(1 − 2 %s)" % cc if slip == R_FORM else "(2 %s − 1)" % cc
	var out := [L(lead(k, "sin " + d) + "/(1 + cos %s)" % d), L(lead(k, "(%s)" % top) + "/(1 + %s)" % inner, "Use %s and %s" % [sin2(s), cos2(s, "cos")])]
	if slip == R_FORM:
		out.append(L(lead(2 * k, sc(s)) + "/(2 − 2 %s)" % cc))
		out.append(L(lead(2 * k, sc(s)) + "/(2 %s)" % F("sin", u, 2)))
		out.append(L(lead(k, "cos %s/sin %s" % [u, u])))
		return out
	if slip == R_DOUBLE:
		out.append(L(lead(k, sc(s)) + "/(2 %s)" % cc))
		out.append(L(lead(k, "sin " + u) + "/(2 cos %s)" % u))
		out.append(wave(s, "tan", Q.new(k, 2), 1))
		return out
	out.append(L(lead(2 * k, sc(s)) + "/(2 %s)" % cc, "The 1s cancel"))
	out.append(L(lead(k, "sin %s/cos %s" % [u, u]), "Cancel 2 cos %s" % u))
	out.append(wave(s, "tan", k, 1, "sin %s/cos %s = tan %s" % [u, u, u]))
	return out


static func _product(s: Dictionary, slip: String) -> Array:
	var n: int = s.n
	var half := Q.new(n, 2)
	var c: Variant = n if slip == R_COEF else half
	var out := [L(lead(n, sc(s))), L(lead(c, "(2 %s)" % sc(s)), "Take out %s to leave 2 %s" % [Fmt.num(half), sc(s)])]
	if slip == R_ARG:
		out.append(wave(s, "sin", half, 1))
	else:
		out.append(wave(s, "sin", c, 2, "Use " + sin2(s)))
	return out


static func _double_twice(s: Dictionary, slip: String) -> Array:
	var k: int = s.k
	var d := ang(s, 2)
	var out := [L(lead(4 * k, "%s cos %s" % [sc(s), d])), L(lead(2 * k, "(2 %s) cos %s" % [sc(s), d]), "Group 2 %s" % sc(s))]
	if slip == R_ARG:
		out.append(L(lead(2 * k, "sin %s cos %s" % [ang(s, 1), d])))
		return out
	var c: int = 2 * k if slip == R_COEF else k
	out.append(L(lead(2 * k, "sin %s cos %s" % [d, d]), "Use " + sin2(s)))
	out.append(L(lead(c, "(2 sin %s cos %s)" % [d, d]), "Group 2 sin %s cos %s" % [d, d]))
	out.append(wave(s, "sin", c, 4, "Use " + sin2(s, 2)))
	return out


static func _square(s: Dictionary, slip: String) -> Array:
	var k: int = s.k
	var u := ang(s, 1)
	var sg := " − " if s.minus else " + "
	var ss := F("sin", u, 2)
	var cc := F("cos", u, 2)
	var out := [L(lead(k, "(sin %s%scos %s)²" % [u, sg, u]))]
	if slip == R_NOMID:
		out.append(L(whole(k, "%s + %s" % [ss, cc])))
		out.append(L(Fmt.num(k)))
		return out
	var mid := sc(s) if slip == R_MID else "2 " + sc(s)
	out.append(L(whole(k, ss + sg + mid + " + " + cc), "Expand the square"))
	out.append(L(whole(k, "1" + sg + mid), "%s + %s = 1" % [ss, cc]))
	var one := Q.new(-1) if s.minus else Q.new(1)
	var b: Q = one.mul(Q.new(1, 2)) if slip == R_MID else one
	var body := "1%s%ssin %s" % [sg, "½ " if slip == R_MID else "", ang(s, 2)]
	out.append(L(whole(k, body), "Use " + sin2(s), {"a": Q.new(k), "b": b, "c": Q.new(2 * int(s.w))},
		[{"slot": "a"}, "(1 + ", {"slot": "b"}, " sin ", {"slot": "c"}, s.letter, ")"]))
	return out


static func _quartic_diff(s: Dictionary, slip: String) -> Array:
	var k: int = s.k
	var u := ang(s, 1)
	var a := "sin" if s.flip else "cos"
	var b := other(a)
	var aa := F(a, u, 2)
	var bb := F(b, u, 2)
	var diff := "%s − %s" % [aa, bb]
	var add := "%s + %s" % [aa, bb]
	var sign: int = -k if s.flip else k
	var out := [L(lead(k, "(%s − %s)" % [F(a, u, 4), F(b, u, 4)]))]
	if slip == R_DIFF:
		out.append(L(lead(k, "(%s)(%s)" % [diff, diff])))
		out.append(L(lead(k, "(%s)²" % diff)))
		out.append(power(s, "cos", 2, k, 2))
		return out
	out.append(L(lead(k, "(%s)(%s)" % [diff, add]), "Use a² − b² = (a − b)(a + b)"))
	if slip == R_PYTH:
		out.append(L(whole(k, add)))
		out.append(L(Fmt.num(k)))
		return out
	out.append(L(whole(k, diff), "%s + %s = 1" % [aa, bb]))
	out.append(wave(s, "sin" if slip == R_WHICH else "cos", sign, 2, "cos %s = %s − %s" % [ang(s, 2), F("cos", u, 2), F("sin", u, 2)]))
	return out


static func _quartic_sin(s: Dictionary, slip: String) -> Array:
	var k: int = s.k
	var u := ang(s, 1)
	var fn: String = s.base
	var bb := F(fn, u, 2)
	var aa := F(other(fn), u, 2)
	var out := [L(lead(4 * k, "(%s − %s)" % [bb, F(fn, u, 4)]))]
	if slip == R_SIGN:
		out.append(L(lead(4 * k, "%s(1 + %s)" % [bb, bb])))
		return out
	out.append(L(lead(4 * k, "%s(1 − %s)" % [bb, bb]), "Take out the common factor %s" % bb))
	out.append(L(lead(4 * k, "%s %s" % [bb, aa]), "1 − %s = %s" % [bb, aa]))
	if slip == R_DOUBLE:
		out.append(power(s, "sin", 2, 4 * k, 2))
		return out
	var c: int = 2 * k if slip == R_COEFSQ else k
	out.append(L(lead(c, "(2 %s)²" % sc(s)), "Write it as one square"))
	out.append(power(s, "sin", 2, c, 2, "Use " + sin2(s)))
	return out


static func _reciprocal_sum(s: Dictionary, slip: String) -> Array:
	var k: int = s.k
	var u := ang(s, 1)
	var ss := F("sin", u, 2)
	var cc := F("cos", u, 2)
	var out := [L(lead(k, "(sin %s/cos %s + cos %s/sin %s)" % [u, u, u, u]))]
	if slip == R_ADD:
		out.append(L(lead(k, "(sin %s + cos %s)/(cos %s + sin %s)" % [u, u, u, u])))
		out.append(L(Fmt.num(k)))
		return out
	out.append(L(lead(k, "(%s + %s)/(%s)" % [ss, cc, sc(s)]), "Write both fractions over %s" % sc(s)))
	out.append(L("%d/(%s)" % [k, sc(s)], "%s + %s = 1" % [ss, cc]))
	if slip == R_DOUBLE:
		out.append(over(s, k, 2))
		return out
	out.append(L("%d/(2 %s)" % [2 * k, sc(s)], "Multiply top and bottom by 2"))
	out.append(over(s, 2 * k, 2, "Use " + sin2(s)))
	return out


static func _tan_diff(s: Dictionary, slip: String) -> Array:
	var k: int = s.k
	var u := ang(s, 1)
	var ss := F("sin", u, 2)
	var cc := F("cos", u, 2)
	var out := [L(lead(k, "%s(1 − %s)" % [cc, F("tan", u, 2)]))]
	if slip == R_TAN:
		out.append(L(lead(k, "%s(1 − %s/%s)" % [cc, cc, ss])))
		out.append(L(whole(k, "%s − %s/%s" % [cc, F("cos", u, 4), ss])))
		return out
	out.append(L(lead(k, "%s(1 − %s/%s)" % [cc, ss, cc]), "tan %s = sin %s/cos %s" % [u, u, u]))
	if slip == R_PART:
		out.append(L(whole(k, "%s − %s/%s" % [cc, ss, cc])))
		return out
	out.append(L(whole(k, "%s − %s" % [cc, ss]), "Multiply out the bracket"))
	out.append(wave(s, "sin" if slip == R_WHICH else "cos", k, 2, "cos %s = %s − %s" % [ang(s, 2), cc, ss]))
	return out


static func _tan_ratio(s: Dictionary, slip: String) -> Array:
	var k: int = s.k
	var u := ang(s, 1)
	var tt := F("tan", u, 2)
	var ss := F("sin", u, 2)
	var cc := F("cos", u, 2)
	var out := [L(lead(k, "(1 − %s)/(1 + %s)" % [tt, tt]))]
	if slip == R_SUM:
		out.append(L(lead(-k, tt) + "/" + tt))
		out.append(L(Fmt.num(-k)))
		return out
	var a := cc if slip == R_TAN else ss
	var b := ss if slip == R_TAN else cc
	var d := "%s − %s" % [b, a]
	out.append(L(lead(k, "(1 − %s/%s)/(1 + %s/%s)" % [a, b, a, b]), "tan %s = sin %s/cos %s" % [u, u, u]))
	out.append(L(lead(k, "(%s)/(%s + %s)" % [d, b, a]), "Multiply top and bottom by %s" % cc))
	out.append(L(whole(k, d), "%s + %s = 1" % [ss, cc]))
	var why := "cos %s = %s − %s" % [ang(s, 2), cc, ss]
	if slip == R_TAN:
		out.append(wave(s, "cos", -k, 2))
	else:
		out.append(wave(s, "sin" if slip == R_WHICH else "cos", k, 2, why))
	return out


static func _tan_double(s: Dictionary, slip: String) -> Array:
	var k: int = s.k
	var u := ang(s, 1)
	var cc := F("cos", u, 2)
	var ratio := "(cos %s/sin %s)" % [u, u] if slip == R_TAN else "(sin %s/cos %s)" % [u, u]
	var out := [L(lead(k, "tan %s(1 + cos %s)" % [u, ang(s, 2)]))]
	if slip == R_FORM:
		out.append(L(lead(k, "%s(1 + 1 − 2 %s)" % [ratio, cc])))
		out.append(L(lead(k, "%s(2 − 2 %s)" % [ratio, cc])))
		out.append(L(lead(2 * k, "%s/cos %s" % [F("sin", u, 3), u])))
		return out
	out.append(L(lead(k, "%s(1 + 2 %s − 1)" % [ratio, cc]), "Use tan %s = sin %s/cos %s and %s" % [u, u, u, cos2(s, "cos")]))
	out.append(L(lead(k, "%s(2 %s)" % [ratio, cc]), "The 1s cancel"))
	if slip == R_TAN:
		out.append(L(lead(2 * k, "%s/sin %s" % [F("cos", u, 3), u])))
		return out
	out.append(L(lead(2 * k, sc(s)), "Cancel cos %s" % u))
	out.append(wave(s, "cos" if slip == R_WHICH else "sin", k, 2, "Use " + sin2(s)))
	return out


static func _factor_sum(s: Dictionary, slip: String) -> Array:
	var k: int = s.k
	var u := ang(s, 1)
	var d := ang(s, 2)
	var fn: String = s.base
	var rest := other(fn)
	var bb := F(fn, u, 2)
	var minus: bool = fn == "sin"
	var two := sc(s) if slip == R_DOUBLE else "2 " + sc(s)
	var out := [L(whole(k, "sin %s + 1 %s cos %s" % [d, "−" if minus else "+", d]))]
	if slip == R_FORM:
		out.append(L(whole(k, "%s + 1 − (2 %s − 1)" % [two, bb]) if minus else whole(k, "%s + 1 + 1 − 2 %s" % [two, bb])))
		out.append(L(whole(k, "%s + 2 − 2 %s" % [two, bb])))
		out.append(L(whole(k, "%s + 2 %s" % [two, F(rest, u, 2)])))
		out.append(L(lead(2 * k, "%s %s(%s %s + %s %s)" % [rest, u, fn, u, rest, u])))
		return out
	var after := "1 − (%s)" % cos2_form(s, "sin") if minus else "1 + %s" % cos2_form(s, "cos")
	out.append(L(whole(k, "%s + %s" % [two, after]), "Use %s and %s" % [sin2(s), cos2(s, fn)]))
	var sg := " − " if slip == R_SIGN else " + "
	out.append(L(whole(k, "%s%s2 %s" % [two, sg, bb]), "The 1s cancel"))
	if slip == R_DOUBLE:
		out.append(L(lead(k, "%s %s(%s %s + 2 %s %s)" % [fn, u, rest, u, fn, u])))
		return out
	out.append(L(lead(2 * k, "%s %s(%s %s%s%s %s)" % [fn, u, rest, u, sg, fn, u]), "Take out the common factor 2 %s %s" % [fn, u]))
	return out


static func _perfect_square(s: Dictionary, slip: String) -> Array:
	var k: int = s.k
	var u := ang(s, 1)
	var d := ang(s, 2)
	var fn: String = s.base
	var minus: bool = fn == "sin"
	var sg := "−" if minus else "+"
	var cd := "cos " + d
	var out := [L(whole(k, "1 %s 2 %s + %s" % [sg, cd, F("cos", d, 2)]))]
	if slip == R_FACT:
		out.append(L(lead(k, "(1 − %s)(1 + %s)" % [cd, cd])))
		out.append(L(whole(k, "1 − " + F("cos", d, 2))))
		out.append(power(s, "sin", 2, k, 2))
		return out
	var bb := F(fn, u, 2)
	out.append(L(lead(k, "(1 %s %s)²" % [sg, cd]), "This is a perfect square"))
	if slip == R_FORM:
		out.append(L(lead(k, "(1 − (2 %s − 1))²" % bb) if minus else lead(k, "(1 + 1 − 2 %s)²" % bb)))
		out.append(L(lead(k, "(2 %s)²" % F(other(fn), u, 2))))
		out.append(power(s, other(fn), 4, 4 * k, 1))
		return out
	var inner := "1 − (%s)" % cos2_form(s, "sin") if minus else "1 + %s" % cos2_form(s, "cos")
	out.append(L(lead(k, "(%s)²" % inner), "Use " + cos2(s, fn)))
	out.append(L(lead(k, "(2 %s)²" % bb), "The 1s cancel"))
	out.append(power(s, fn, 4, 2 * k if slip == R_COEFSQ else 4 * k, 1, "Square the bracket"))
	return out


static func _split(s: Dictionary, slip: String) -> Array:
	var k: int = s.k
	var u := ang(s, 1)
	var fn: String = s.base
	var rest := other(fn)
	var bb := F(fn, u, 2)
	var den := "/(2 %s %s)" % [fn, u]
	var two := sc(s) if slip == R_DOUBLE else "2 " + sc(s)
	var out := [L(lead(k, "(sin %s + 2 %s)" % [ang(s, 2), bb]) + den), L(lead(k, "(%s + 2 %s)" % [two, bb]) + den, "Use " + sin2(s))]
	if slip == R_SUM:
		out.append(L(whole(k, "%s %s + 2 %s" % [rest, u, bb])))
		return out
	if slip == R_DOUBLE:
		out.append(L(lead(k, "%s %s(%s %s + 2 %s %s)" % [fn, u, rest, u, fn, u]) + den))
		out.append(L(lead(k, "(%s %s + 2 %s %s)" % [rest, u, fn, u]) + "/2"))
		return out
	out.append(L(lead(2 * k, "%s %s(%s %s + %s %s)" % [fn, u, rest, u, fn, u]) + den, "Take out the common factor 2 %s %s" % [fn, u]))
	var slot_b: Dictionary = {"slot": "b"}
	out.append(L(whole(k, "%s %s + %s %s" % [rest, u, fn, u]), "Cancel 2 %s %s" % [fn, u], {"a": Q.new(k), "b": Q.new(int(s.w)), "c": Q.new(int(s.w))},
		[{"slot": "a"}, "(%s " % rest, slot_b, s.letter, " + %s " % fn, {"slot": "c"}, s.letter, ")"]))
	return out


## The slips that can be made on this statement.
static func slips_of(s: Dictionary) -> Array:
	var out: Array = SLIPS[s.fam].duplicate()
	if s.fam == "factor-sum" and s.base == "cos":
		out.erase(R_SIGN)
	return out


static func left(s: Dictionary) -> String:
	return chain(s)[0].text


static func right(s: Dictionary) -> String:
	return chain(s).back().text


## "Prove that LHS ≡ RHS."
static func claim(s: Dictionary, swap: bool = false, rhs: String = "") -> String:
	var r := right(s) if rhs == "" else rhs
	var note := ", where both sides are defined" if s.fam in HAS_LIMITS else ""
	return "Prove that %s ≡ %s%s." % [r if swap else left(s), left(s) if swap else r, note]


## The statement's left side, as an equation or a sentence.
static func named(s: Dictionary, rep: String, nm: String = "L") -> Array:
	if rep != "words":
		return ["%s = %s" % [nm, left(s)]]
	var u := ang(s, 1)
	var by := "" if int(s.get("k", 1)) == 1 else ", multiplied by %d" % s.k
	match s.fam:
		"product":
			return ["%s is %d times the product of sin %s and cos %s." % [nm, s.n, u, u]]
		"square":
			return ["%s is the square of %s of sin %s and cos %s%s." % [nm, "the difference, sine minus cosine," if s.minus else "the sum", u, u, by]]
		"quartic-diff":
			var a := "sin" if s.flip else "cos"
			return ["%s is the fourth power of %s %s minus the fourth power of %s %s%s." % [nm, a, u, other(a), u, by]]
		"tan-double":
			return ["%s is tan %s times the sum of 1 and cos %s%s." % [nm, u, ang(s, 2), by]]
	return []


## The lines shown for a proof, with `hide` replaced by a question mark.
static func numbered(c: Array, hide: int = -1, upto: int = -1) -> Array:
	return AlgebraicProofViews.numbered(c, "LHS", hide, upto)


## One step per line of the chain, up to line `upto`.
static func walk(c: Array, upto: int, nm: String) -> Array:
	var out: Array = []
	for i in range(1, upto + 1):
		out.append("%s: %s = %s" % [c[i].why, nm, c[i].text])
	return out


## The method whose proof a question shows. Other methods' tabs say so, and walk the same lines.
func routes(s: Dictionary, steps: Array, ans: Dictionary) -> Dictionary:
	var out := {}
	for m in ProveIdentitySituation.ASKS[s.ask]:
		var note := ""
		if m != angle:
			note = OTHER_ROUTE
		elif not ProveIdentitySituation.suits(s.ask, m, s.fam):
			note = UNSUITED
		var lines: Array = steps.duplicate()
		if note != "":
			lines[0] = note + " " + lines[0]
		out[m] = method(lines, ans.values)
	if not out.has(angle):
		var lines: Array = steps.duplicate()
		lines[0] = UNSUITED + " " + lines[0]
		out[angle] = method(lines, ans.values)
	return out


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func picked(head: String, ans: Dictionary) -> String:
	return "%s: %s" % [head, Answer.text(ans)]


## A line as a `form` answer, typed in its slots.
static func typed(line: Dictionary, label: String) -> Dictionary:
	var v: Dictionary = line.v.duplicate()
	v.text = line.text
	var ans := Answer.make("form", v, {"parts": [label] + line.parts}, label)
	ans.exact = true
	return ans


static func number(v: Q, label: String) -> Dictionary:
	var a := Answer.make("number", {"v": v}, {}, label)
	a.exact = true
	return a


## The form a line's slots spell: "a tan bx".
static func form_name(line: Dictionary) -> String:
	var out := ""
	for p in line.parts:
		out += p if p is String else p.slot
	return out


## The same statement with a bigger number, for lines of the same shape that are simply wrong.
static func shifted(s: Dictionary, d: int) -> Dictionary:
	var t := s.duplicate()
	if s.fam == "product":
		t.n = s.n + d
	else:
		t.k = s.k + d
	return t


## Wrong end lines with no slip behind them.
static func shifted_ends(s: Dictionary, good: Dictionary) -> Array:
	var out: Array = []
	for d in [1, 2, 3]:
		out.append(AlgebraicProofViews.line_option(chain(shifted(s, d)).back(), good).values)
	return out


## What each slip ends on, as options.
static func slip_ends(s: Dictionary, good: Dictionary) -> Array:
	var out: Array = []
	for slip in slips_of(s):
		var end: Dictionary = chain(s, slip).back()
		if not end.v.is_empty() or end.parts.is_empty() and end.text.is_valid_int():
			out.append(AlgebraicProofViews.line_option(end, good, slip))
	return out


## Line i as each slip made on that line writes it (with the line before still right), then as
## the same line with a bigger number. [[text, ref], ...], different from good and each other.
static func wrong_lines(s: Dictionary, i: int, rng: Seeded, head: String = "") -> Array:
	var clean := chain(s)
	var out: Array = []
	var seen := {clean[i].text: true}
	for slip in rng.shuffled(slips_of(s)):
		var c := chain(s, slip)
		if c.size() > i and c[i - 1].text == clean[i - 1].text and not seen.has(c[i].text):
			seen[c[i].text] = true
			out.append([head + c[i].text, slip])
	for d in [1, 2, 3]:
		var t: String = chain(shifted(s, d))[i].text
		if not seen.has(t):
			seen[t] = true
			out.append([head + t, ""])
	return out


# ── The proof itself ─────────────────────────────────────────

func u_simplified_result(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := chain(s)
	var good: Dictionary = c.back()
	var ans := typed(good, "L = ")
	return {"asked": "Write L in the form %s." % form_name(good), "lines": named(s, rep), "answer": ans, "wrongs": slip_ends(s, good), "generic": shifted_ends(s, good),
		"methods": routes(s, walk(c, c.size() - 1, "L") + [say(ans)], ans)}


func u_next_line(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := chain(s)
	var at := rng.int_in(1, c.size() - 1)
	var good: Dictionary = c[at]
	var ws: Array = [["%s − (%s) = 0" % [left(s), right(s)], R_BOTH]] + wrong_lines(s, at, rng, "= ")
	var out := AlgebraicProofViews.pick_answer("= " + good.text, ws.slice(0, 3))
	out.asked = "Which line comes next in this proof?"
	out.lines = [claim(s)] + numbered(c, -1, at - 1)
	out.methods = routes(s, walk(c, at, "LHS") + [picked("So the next line is", out.answer)], out.answer)
	out.shown = {"at": at}
	return out


func u_missing_line(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := chain(s)
	var hide := rng.int_in(1, c.size() - 2)
	var label := "Line %d: " % (hide + 1)
	var out := AlgebraicProofViews.pick_answer(label + c[hide].text, wrong_lines(s, hide, rng, label).slice(0, 3))
	out.asked = "Line %d of this proof is missing. What does it say?" % (hide + 1)
	out.lines = [claim(s)] + numbered(c, hide)
	out.methods = routes(s, walk(c, hide, "LHS") + [picked("So the missing line is", out.answer)], out.answer)
	out.shown = {"hide": hide}
	return out


func u_flawed_line(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := chain(s)
	var slip: String = rng.pick(slips_of(s))
	var bad := chain(s, slip)
	var at := 1
	while bad[at].text == c[at].text:
		at += 1
	var said := func(no: int, text: String) -> String: return "Line %d should read: %s" % [no + 1, text]
	var ws: Array = []
	for w in wrong_lines(s, at, rng):
		if w[0] != bad[at].text:
			ws.append([said.call(at, w[0]), w[1]])
	# A later line is wrong too, but it only follows the first mistake.
	if at + 1 < bad.size() and at + 1 < c.size():
		ws.insert(0, [said.call(at + 1, c[at + 1].text), ""])
	var out := AlgebraicProofViews.pick_answer(said.call(at, c[at].text), ws.slice(0, 3))
	out.asked = "Find the first line that goes wrong, and correct it."
	out.lines = [claim(s), "A student's proof has one slip, carried down to the end:"] + numbered(bad)
	var steps: Array = ["Check each line against the one before. Line %d does not follow from line %d." % [at + 1, at], "%s: LHS = %s" % [c[at].why, c[at].text],
		picked("So the fix is", out.answer)]
	out.methods = routes(s, steps, out.answer)
	out.shown = {"at": at, "slip": slip}
	return out


func u_valid_argument(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := chain(s)
	var t := Q.new(1, 6 * int(s.w))
	var first: String = c[1].text
	var all_lines: PackedStringArray = []
	for i in range(1, c.size()):
		# A k of 1 leaves a line that only adds brackets: the chain shows it once.
		if i == 1 or c[i].text.trim_prefix("(").trim_suffix(")") != c[i - 1].text:
			all_lines.append(c[i].text)
	var out := AlgebraicProofViews.pick_answer("LHS = %s = RHS, so LHS ≡ RHS." % " = ".join(all_lines), [
		["Assume LHS ≡ RHS. Take the RHS from both sides: 0 = 0, so LHS ≡ RHS.", R_BOTH],
		["At %s = %s both sides equal %s, so LHS ≡ RHS." % [s.letter, Fmt.pi(t), TrigKit.text(right_value(s, t))], R_VALUES],
		["LHS = %s" % first, R_NO_END]])
	out.asked = "Which of these is a complete proof?"
	out.lines = [claim(s)]
	out.methods = routes(s, walk(c, c.size() - 1, "LHS") + [picked("So the complete proof is", out.answer)], out.answer)
	return out


## How many sines, cosines and tangents a side is written with.
static func busy(text: String) -> int:
	return text.count("sin") + text.count("cos") + text.count("tan")


func u_start_side(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := chain(s)
	var swap: bool = s.swap
	var side := "right" if swap else "left"
	var rest := "left" if swap else "right"
	var out := AlgebraicProofViews.pick_answer("Start from the %s side: it is the busier one, so there is more to rewrite." % side, [
		["Start from the %s side: it is the shorter one, so there is less to write." % rest, R_SIMPLE],
		["Work on both sides at once until they match.", R_BOTH],
		["Put %s = %s into both sides and compare them." % [s.letter, Fmt.pi(Q.new(1, 6 * int(s.w)))], R_VALUES]])
	out.asked = "Which is the best way to start this proof?"
	out.lines = [claim(s, swap)]
	var steps: Array = ["The %s side has %d trig functions and the %s side %d." % [side, busy(left(s)), rest, busy(right(s))],
		"%s: %s" % [c[1].why, c[1].text], picked("So the start is", out.answer)]
	out.methods = routes(s, steps, out.answer)
	return out


func u_true_identity(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := chain(s)
	var l := left(s)
	var ws: Array = []
	var seen := {c.back().text: true}
	for slip in rng.shuffled(slips_of(s)):
		var end: String = chain(s, slip).back().text
		if not seen.has(end):
			seen[end] = true
			ws.append(["%s ≡ %s" % [l, end], slip])
	for d in [1, 2, 3, 4]:
		var end: String = chain(shifted(s, d)).back().text
		if not seen.has(end):
			seen[end] = true
			ws.append(["%s ≡ %s" % [l, end], ""])
	var out := AlgebraicProofViews.pick_answer("%s ≡ %s" % [l, c.back().text], ws.slice(0, 3))
	out.asked = "Which of these is true for every value of %s where both sides are defined?" % s.letter
	out.lines = ["Work on the left side of each, which is the same in all four."]
	out.methods = routes(s, walk(c, c.size() - 1, "L") + [picked("So the identity is", out.answer)], out.answer)
	return out


# ── Forms of cos 2x and sin 2x ───────────────────────────────

func u_cos2_form(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := chain(s)
	var fn := base_of(s)
	var d := ang(s, 2)
	var u := ang(s, 1)
	var rest := other(fn)
	var head := "cos %s = " % d
	var mix := "%s − %s" % [F("cos", u, 2), F("sin", u, 2)]
	var swapped := "2 %s − 1" % F("sin", u, 2) if fn == "sin" else "1 − 2 %s" % F("cos", u, 2)
	var out := AlgebraicProofViews.pick_answer(head + cos2_form(s, fn), [[head + mix, R_KEEP], [head + cos2_form(s, rest), R_KEEP], [head + swapped, R_FORM]])
	out.asked = "Which form of cos %s makes the 1 cancel?" % d
	var show_line: String = c[1].text if s.fam == "perfect-square" else c[0].text
	out.lines = ["L = " + show_line]
	var pair := "1 − (%s)" % cos2_form(s, "sin") if fn == "sin" else "1 + (%s)" % cos2_form(s, "cos")
	var steps: Array = ["%s = 2 %s: the 1s cancel." % [pair, F(fn, u, 2)], "The other two true forms leave a constant behind.", picked("So use", out.answer)]
	out.methods = {angle: method(steps, out.answer.values)}
	return out


func u_half_form(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var fn := base_of(s)
	var minus: bool = fn == "sin"
	var d := ang(s, 2)
	var good := power(s, fn, 2, 2 * k, 1)
	var ans := typed(good, "L = ")
	var wrongs: Array = [AlgebraicProofViews.line_option(power(s, fn, 2, 2 * k, 2), good, R_ARG), AlgebraicProofViews.line_option(power(s, fn, 2, k, 1), good, R_COEF),
		AlgebraicProofViews.line_option(power(s, other(fn), 2, 2 * k, 1), good, R_FORM)]
	if minus:
		wrongs.insert(1, AlgebraicProofViews.line_option(power(s, fn, 2, -2 * k, 1), good, R_SIGN))
	var generic: Array = [power(s, fn, 2, 4 * k, 1), power(s, fn, 2, 2 * k + 1, 1), power(s, fn, 2, 4 * k, 2)].map(func(l): return AlgebraicProofViews.line_option(l, good).values)
	var inner := "1 − (%s)" % cos2_form(s, "sin") if minus else "1 + %s" % cos2_form(s, "cos")
	var steps: Array = ["Use %s: L = %s" % [cos2(s, fn), whole(k, inner)], "The 1s cancel: L = %s" % good.text, say(ans)]
	return {"asked": "Write L in the form %s." % form_name(good), "lines": ["L = " + whole(k, "1 %s cos %s" % ["−" if minus else "+", d])], "answer": ans, "wrongs": wrongs,
		"generic": generic, "methods": {angle: method(steps, ans.values)}}


func u_sin2_multiple(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var a := Q.new(n, 2)
	var ans := number(a, "a = ")
	var d := ang(s, 2)
	var line: String = "%s ≡ a sin %s" % [left(s), d] if rep != "words" else "%d times the product of sin %s and cos %s is a times sin %s, for every %s." % [n, ang(s, 1), ang(s, 1), d, s.letter]
	var steps: Array = ["%s, so %s = ½ sin %s." % [sin2(s), sc(s), d], "Multiply by %d: %s = %s." % [n, left(s), lead(a, "sin " + d)], say(ans)]
	return {"asked": "Find a.", "lines": [line], "answer": ans, "wrongs": [wrong({"v": Q.new(n)}, R_COEF)],
		"generic": [{"v": Q.new(2 * n)}, {"v": Q.new(n, 4)}, {"v": Q.new(n + 2)}, {"v": a.add(Q.new(1))}], "methods": {angle: method(steps, ans.values)}}


func u_cancel_fraction(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := chain(s)
	var good: Dictionary = c.back()
	var ans := typed(good, "L = ")
	var fn: String = s.base
	var wrongs: Array = [AlgebraicProofViews.alt(chain(s, R_SUM).back().text, R_SUM), AlgebraicProofViews.alt(whole(s.k, "2 %s + %s %s" % [sc(s), fn, ang(s, 1)]), R_SUM),
		AlgebraicProofViews.alt(chain(s, R_DOUBLE).back().text, R_DOUBLE)]
	return {"asked": "Factorise the top and cancel. Write L in the form %s." % form_name(good), "lines": named(s, "equation"), "answer": ans, "wrongs": wrongs,
		"generic": shifted_ends(s, good), "methods": {angle: method(walk(c, c.size() - 1, "L") + [say(ans)], ans.values)}}


func u_factor_structure(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := chain(s)
	var out := AlgebraicProofViews.pick_answer("L = " + c[1].text, wrong_lines(s, 1, rng, "L = ").slice(0, 3))
	out.asked = "Which line is a correct first step in factorising L?"
	out.lines = named(s, "equation")
	out.methods = {angle: method([c[1].why + ".", picked("So the first step is", out.answer)], out.answer.values)}
	return out


# ── Once the identity holds ──────────────────────────────────

## The right side as [a, fn, m] (a fn(m·wx)), for a statement that ends in one wave.
static func wave_of(s: Dictionary) -> Array:
	match s.fam:
		"half-tan", "half-tan-plus":
			return [Q.new(s.k), "tan", 1]
		"product":
			return [Q.new(s.n, 2), "sin", 2]
		"double-twice":
			return [Q.new(s.k), "sin", 4]
		"quartic-diff":
			return [Q.new(-s.k if s.flip else s.k), "cos", 2]
		"tan-diff", "tan-ratio":
			return [Q.new(s.k), "cos", 2]
		"tan-double":
			return [Q.new(s.k), "sin", 2]
	return []


## fn(m·wt·π).
static func tv(s: Dictionary, fn: String, m: int, t: Q) -> Array:
	return TrigKit.of(fn, t.mul(m * int(s.w)))


## The right side at x = tπ, or [] where it has no exact value of one surd.
static func right_value(s: Dictionary, t: Q) -> Array:
	var w := wave_of(s)
	if not w.is_empty():
		var v := tv(s, w[1], w[2], t)
		return [] if v.is_empty() else TrigKit.times(v, w[0])
	var k: int = s.k
	var sn := tv(s, "sin", 1, t)
	var cs := tv(s, "cos", 1, t)
	var sd := tv(s, "sin", 2, t)
	match s.fam:
		"square":
			return TrigKit.plus(TrigKit.V(k), TrigKit.times(sd, -k if s.minus else k))
		"quartic-sin":
			return TrigKit.times(TrigKit.sq(sd), k)
		"reciprocal-sum":
			return TrigKit.times(TrigKit.over(TrigKit.V(1), sd), 2 * k)
		"perfect-square":
			return TrigKit.times(TrigKit.sq(TrigKit.sq(sn if s.base == "sin" else cs)), 4 * k)
		"factor-sum":
			var v := TrigKit.plus(TrigKit.mul(sn, cs), TrigKit.sq(sn if s.base == "sin" else cs))
			return [] if v.is_empty() else TrigKit.times(v, 2 * k)
		"split":
			var v := TrigKit.plus(sn, cs)
			return [] if v.is_empty() else TrigKit.times(v, k)
	return []


## Whether the left side has a value at x = tπ.
static func defined(s: Dictionary, t: Q) -> bool:
	match s.fam:
		"half-tan":
			return not TrigKit.is_zero(tv(s, "sin", 2, t))
		"half-tan-plus":
			return TrigKit.fl(tv(s, "cos", 2, t)) > -0.999
		"tan-diff", "tan-ratio", "tan-double":
			return not TrigKit.is_zero(tv(s, "cos", 1, t))
	return true


func u_identity_value(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: Q = s.t
	var x: String = s.letter
	var v := right_value(s, t)
	var a := TrigKit.ans("L = ", v)
	var at := Fmt.pi(t)
	var out := {"asked": "Find the exact value of L when %s = %s." % [x, at], "lines": ["L = " + left(s), "It has been proved that L ≡ %s." % right(s)], "answer": a}
	var slipped: Array = []
	var w := wave_of(s)
	if s.w != 1 or (not w.is_empty() and w[2] != 1):
		if w.is_empty():
			var one := TrigKit.of("sin", t)
			slipped = TrigKit.plus(TrigKit.V(s.k), TrigKit.times(one, -s.k if s.minus else s.k))
		else:
			var one := TrigKit.of(w[1], t)
			slipped = [] if one.is_empty() else TrigKit.times(one, w[0])
	out.wrongs = TrigKit.like(a, slipped, R_AT)
	out.generic = TrigKit.others(a, [TrigKit.neg(v), TrigKit.times(v, 2), TrigKit.times(v, Q.new(1, 2)), TrigKit.times(v, 3), TrigKit.plus(v, TrigKit.V(1))].filter(func(e): return not e.is_empty()))
	var angle_at := Fmt.pi(t.mul(2 * int(s.w) if w.is_empty() else int(w[2]) * int(s.w)))
	var inside := ang(s, 2) if w.is_empty() else ang(s, w[2])
	var fn: String = "sin" if w.is_empty() else w[1]
	var steps: Array = ["Use the identity: L = %s" % right(s), "At %s = %s, %s = %s." % [x, at, inside, angle_at] if inside != x else "%s = %s." % [x, at], say(a)]
	steps[1] += " So %s %s is %s." % [fn, inside, TrigKit.text(tv(s, fn, 2 if w.is_empty() else w[2], t))]
	out.methods = {angle: method(steps, a.values)}
	return out


## What each slip gives from the ratio r. [[value, ref], ...].
static func ratio_slips(s: Dictionary) -> Array:
	var k := Q.new(s.k)
	var r: Q = s.r
	match s.fam:
		"half-tan":
			return [[k.mul(r).mul(-1), R_SIGN], [k.mul(r).mul(2), R_DOUBLE], [k.div(r), R_FORM]]
		"half-tan-plus":
			return [[k.mul(r).mul(Q.new(1, 2)), R_DOUBLE], [k.div(r), R_FORM]]
		"square":
			var b: Q = r.mul(-1) if s.minus else r
			return [[k, R_NOMID], [k.mul(b.mul(Q.new(1, 2)).add(1)), R_MID]]
		"quartic-diff":
			return [[k, R_PYTH]]
		"quartic-sin":
			return [[k.mul(r).mul(r).mul(4), R_DOUBLE], [k.mul(r).mul(r).mul(2), R_COEFSQ]]
		"reciprocal-sum":
			return [[k.div(r), R_DOUBLE]]
	return []


## The value of the statement from the ratio given.
static func ratio_value(s: Dictionary) -> Q:
	var k := Q.new(s.k)
	var r: Q = s.r
	match s.fam:
		"square":
			return k.mul(r.mul(-1 if s.minus else 1).add(1))
		"quartic-diff":
			return k.mul(r).mul(-1 if s.flip else 1)
		"quartic-sin":
			return k.mul(r).mul(r)
		"reciprocal-sum":
			return k.mul(2).div(r)
	return k.mul(r)


func u_value_from_ratio(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: Q = s.r
	var v := ratio_value(s)
	var ans := number(v, "L = ")
	var what: String = "tan %s" % ang(s, 1) if s.given == "tan" else "%s %s" % [s.given, ang(s, 2)]
	var given := "%s = %s" % [what, Fmt.num(r)]
	var wrongs: Array = ratio_slips(s).map(func(p): return wrong({"v": p[0]}, p[1]))
	var generic: Array = [{"v": r}, {"v": v.mul(-1)}, {"v": v.mul(2)}, {"v": v.mul(Q.new(1, 2))}, {"v": v.add(Q.new(1))}, {"v": v.sub(Q.new(1))}]
	var steps: Array = ["Simplify L with the identities: L = %s" % right(s), "Put in %s." % given, say(ans)]
	return {"asked": "Find the exact value of L.", "lines": ["L = " + left(s), "%s." % given], "answer": ans, "wrongs": wrongs, "generic": generic,
		"methods": routes(s, steps, ans)}


## The least and greatest of the right side.
static func range_of(s: Dictionary) -> Array:
	match s.fam:
		"product":
			return [Q.new(-s.n, 2), Q.new(s.n, 2)]
		"double-twice", "quartic-diff":
			return [Q.new(-s.k), Q.new(s.k)]
		"square":
			return [Q.new(0), Q.new(2 * s.k)]
	return [Q.new(0), Q.new(s.k)]


func u_greatest_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: int = s.c
	var r := range_of(s)
	var top: bool = s.want == "greatest"
	var add := Q.new(c)
	var v: Q = (r[1] if top else r[0]).add(add)
	var ans := number(v, "%s value = " % s.want)
	var tail := "" if c == 0 else " %s %d" % ["+" if c > 0 else "−", absi(c)]
	var lines: Array = ["f(%s) = %s%s" % [s.letter, left(s), tail]]
	if rep == "words":
		lines = named(s, rep, "L")
		if c != 0:
			lines.append("f(%s) is L %s %d." % [s.letter, "plus" if c > 0 else "minus", absi(c)])
		else:
			lines.append("f(%s) is L." % s.letter)
	var wrongs: Array = []
	if top:
		if s.fam == "square":
			wrongs.append(wrong({"v": Q.new(s.k).add(add)}, R_EXT))
		elif s.fam == "product":
			wrongs.append(wrong({"v": Q.new(s.n).add(add)}, R_PRE))
		elif s.fam in ["double-twice", "quartic-sin"]:
			wrongs.append(wrong({"v": Q.new(4 * s.k).add(add)}, R_PRE))
	var generic: Array = [{"v": (r[0] if top else r[1]).add(add)}, {"v": add}, {"v": r[1]}, {"v": v.add(Q.new(1))}, {"v": v.sub(Q.new(1))}, {"v": v.add(Q.new(2))}]
	var steps: Array = ["Simplify with the identities: f(%s) = %s%s" % [s.letter, right(s), tail],
		"Its values run from %s to %s." % [Fmt.num(r[0].add(add)), Fmt.num(r[1].add(add))], say(ans)]
	return {"asked": "Find the %s value of f." % s.want, "lines": lines, "answer": ans, "wrongs": wrongs, "generic": generic, "methods": routes(s, steps, ans)}


func u_common_expression(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := chain(s)
	var good: Dictionary = c.back()
	var ans := typed(good, "")
	var fn: String = rng.pick(["sin", "cos"])
	var rhs := whole(s.k, cos2_form(s, fn))
	var steps: Array = walk(c, c.size() - 1, "LHS")
	steps.append("Use %s: RHS = %s" % [cos2(s, fn), good.text])
	steps.append(say(ans).replace("So ", "Both sides reach the same expression, so the proof ends on "))
	return {"asked": "Simplify each side on its own. Which expression do both sides reach? Write it in the form %s." % form_name(good), "lines": [claim(s, false, rhs)], "answer": ans,
		"wrongs": slip_ends(s, good), "generic": shifted_ends(s, good), "methods": routes(s, steps, ans), "shown": {"rhs": fn}}
