class_name IntegerPowersViews
extends ExtensionViews
## The views on the `integer-powers` situation: one builder per unknown of t1-ext-exponent-laws
## (FAL-780), SL1.5.integer-exponent-laws and SL1.5.zero-negative. A value is a `number`, typed
## exactly as a fraction. A term cxᵉ (or axᵖ) is a `form` with its number and its exponent typed, a
## power of a prime tᵏ a `form` with k typed, and a quotient of two letters a `form` with its two
## exponents typed in the answer's own layout; a wrong option in another layout can only be picked.
## Wrong options are the two skills' misconceptions and the type's own; error-spot shows a working
## that raises only the x of (axᵐ)ᵖ to the power, and true-false-reason plays on every cell. The
## catalogue's `match` and `order-steps` formats aren't built in the engine.
##
## Representation: "equation" (the number or expression in symbols).

const IL := "SL1.5.integer-exponent-laws#"
const ZN := "SL1.5.zero-negative#"
const OWN := "t1-ext-exponent-laws#"
const R_POW_ADD := IL + "0"
const R_PART := IL + "1"
const R_BASES := IL + "2"
const R_NEGATIVE := ZN + "0"
const R_ZERO := ZN + "1"
const R_COEF_UP := ZN + "2"
const R_NO_SIGN := OWN + "6"
const R_TIMES := OWN + "7"
const R_ZERO_SELF := OWN + "8"
const R_KEEP_POS := OWN + "9"
const R_COEF_TIMES := OWN + "10"
const R_SUB_NEG := OWN + "11"
const R_WRONG_WAY := OWN + "12"
const R_ADD_DIV := OWN + "13"
const R_NO_PRIME := OWN + "14"
const R_SPOT_PART := OWN + "15"
const UNKNOWNS := ["negative-power", "zero-and-negative", "to-index-form", "power-of-product", "two-letter-quotient", "single-prime-power"]
const S := preload("res://engine/situations/integer_powers.gd")


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = ["true-false-reason"]
	out["power-of-product"] = ["true-false-reason", "error-spot"]
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = S.export(s)
	said_once(out.methods, out.answer)
	return out


# ── Writing things ───────────────────────────────────────────

## 2^3, 2^(−3), (2/3)^(−2): a power as the question writes it.
static func pw(b: Variant, e: int) -> String:
	var q := Q.of(b) if not b is String else null
	var base: String = b if b is String else (q.text() if q.is_int() and q.sign() > 0 else "(%s)" % q.text())
	return "%s^%d" % [base, e] if e >= 0 else "%s^(−%d)" % [base, -e]


## cx^e: "18x^5", "x^(−3)", "−x^2", "(1/4)x^(−3)", "3x", "7".
static func mono(c: Variant, e: int, letter: String = "x") -> String:
	var q := Q.of(c)
	var head := ""
	if q.eq(1):
		head = ""
	elif q.eq(-1):
		head = "−"
	elif q.is_int():
		head = q.text()
	else:
		head = ("−" if q.sign() < 0 else "") + "(%s)" % q.abs_q().text()
	if e == 0:
		return q.text()
	return head + (letter if e == 1 else pw(letter, e))


static func term_ans(c: Variant, e: int, slots: Array = ["c", "e"]) -> Dictionary:
	var ans := DifferentiationViews.form(mono(c, e), [{"slot": slots[0]}, "x^", {"slot": slots[1]}], {slots[0]: Q.of(c), slots[1]: Q.new(e)})
	return ans


## A wrong term in the answer's shape, typable.
static func term_wrong(c: Variant, e: int, ref: String, slots: Array = ["c", "e"]) -> Dictionary:
	return DifferentiationViews.alt(mono(c, e), ref, {slots[0]: Q.of(c), slots[1]: Q.new(e)})


static func value_ans(v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, "value = ")
	ans.exact = true
	return ans


static func say(ans: Dictionary) -> String:
	return ("So " if ans.kind == "number" else "So the answer is ") + Answer.text(ans) + "."


func _pack(lines: Array, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {}}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


## Values [v, ref] kept once each, never the answer; then fillers that are neither.
static func value_wrongs(v: Q, list: Array) -> Array:
	var seen := {v.key(): true}
	var out: Array = []
	for e in list:
		var w := Q.of(e[0])
		if not seen.has(w.key()):
			seen[w.key()] = true
			out.append(wrong({"v": w}, e[1]))
	return out


static func value_fillers(v: Q, wrongs: Array, list: Array) -> Array:
	var seen := {v.key(): true}
	for w in wrongs:
		seen[Q.of(w.values.v).key()] = true
	var out: Array = []
	for e in list:
		var w := Q.of(e)
		if not seen.has(w.key()):
			seen[w.key()] = true
			out.append({"v": w})
	return out


## Wrong forms kept once each by their text, never the answer's.
static func form_wrongs(ans: Dictionary, list: Array) -> Array:
	var seen := {Answer.text(ans): true}
	var out: Array = []
	for w in list:
		if not seen.has(w.values.text):
			seen[w.values.text] = true
			out.append(w)
	return out


static func form_fillers(ans: Dictionary, wrongs: Array, list: Array) -> Array:
	var seen := {Answer.text(ans): true}
	for w in wrongs:
		seen[w.values.text] = true
	var out: Array = []
	for w in list:
		if not seen.has(w.values.text):
			seen[w.values.text] = true
			out.append(w.values)
	return out


# ── Zero and negative powers ─────────────────────────────────

## The powers of a base going down, from base^hi to base^lo, each as base^e = value.
static func ladder(base: Q, hi: int, lo: int) -> String:
	var parts: Array = []
	for e in range(hi, lo - 1, -1):
		parts.append("%s = %s" % [pw(base, e), S.qpow(base, e).text()])
	return ", ".join(parts)


func u_negative_power(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var base: Q = s.base
	var n: int = s.n
	var v: Q = s.v
	var ans := value_ans(v)
	var pos := S.qpow(base, n)
	var list: Array = [[pos.neg(), R_NEGATIVE], [pos, R_NO_SIGN]]
	if s.shape == "whole":
		list.append([Q.new(-s.b * n), R_TIMES])
	var w := value_wrongs(v, list)
	var fill := value_fillers(v, w, [S.qpow(base, -n - 1), S.qpow(base, -n + 1), v.neg(), Q.new(1).div(base.mul(n))])
	var shown := pw(base, -n)
	var flip := Q.new(1).div(base)
	var steps := {}
	if s.shape == "whole":
		steps["reciprocal-rule"] = ["A negative exponent means the reciprocal of the positive power: %s = 1/%s." % [shown, pw(base, n)],
			"%s = %s, so %s = %s." % [pw(base, n), pos.text(), shown, v.text()], say(ans)]
	else:
		steps["reciprocal-rule"] = ["A negative exponent means the reciprocal of the positive power: %s = %s." % [shown, pw(flip, n)],
			"%s = %s" % [pw(flip, n), v.text()], say(ans)]
	steps["pattern-down"] = ["Each step down the powers divides by %s: %s." % [base.text(), ladder(base, 2, 0)],
		"Keep dividing by %s: %s." % [base.text(), ladder(base, -1, -n)], say(ans)]
	return _pack([], "Find the exact value of %s." % shown, ans, w, fill, steps)


func u_zero_and_negative(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: int = s.c
	var b: int = s.b
	var n: int = s.n
	var v: Q = s.v
	var bn := S.ipow(b, n)
	var ans := value_ans(v)
	var small := Q.new(1, bn)
	var w := value_wrongs(v, [[small, R_ZERO], [Q.new(1 - bn), R_NEGATIVE], [small.add(c), R_ZERO_SELF], [Q.new(1 + bn), R_NO_SIGN]])
	var fill := value_fillers(v, w, [Q.new(1).add(Q.new(1, bn * b)), Q.new(2).add(small), Q.new(1, bn + 1), v.mul(2)])
	var expr := "%s + %s" % [pw(c, 0), pw(b, -n)]
	return _pack([], "Find the exact value of %s." % expr, ans, w, fill, {
		"reciprocal-rule": ["A non-zero number to the power 0 is 1: %s = 1." % pw(c, 0),
			"A negative exponent is the reciprocal of the positive power: %s = 1/%s = 1/%d." % [pw(b, -n), pw(b, n), bn],
			"1 + 1/%d = %s" % [bn, v.text()], say(ans)],
		"pattern-down": ["One step down from %s divides by %d: %s = %d ÷ %d = 1." % [pw(c, 1), c, pw(c, 0), c, c],
			"Each step down the powers of %d divides by %d: %s." % [b, b, ladder(Q.new(b), 0, -n)],
			"1 + 1/%d = %s" % [bn, v.text()], say(ans)],
	})


func u_to_index_form(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: int = s.c
	var n: int = s.n
	var a: Q = s.a
	var ans := term_ans(a, -n, ["a", "p"])
	var top: bool = s.shape == "top"
	var shown := "%d/%s" % [c, pw("x", n)] if top else "1/(%d%s)" % [c, pw("x", n)]
	if n == 1:
		shown = "%d/x" % c if top else "1/(%dx)" % c
	var list: Array = [term_wrong(a, n, R_KEEP_POS, ["a", "p"]), term_wrong(a.neg(), n, R_NEGATIVE, ["a", "p"])]
	if not top:
		list.append(term_wrong(Q.new(c), -n, R_COEF_UP, ["a", "p"]))
	var w := form_wrongs(ans, list)
	var fill := form_fillers(ans, w, [term_wrong(a, -n - 1, "", ["a", "p"]), term_wrong(Q.new(1).div(a), -n, "", ["a", "p"]),
		term_wrong(a, -n + 1 if n > 1 else -n - 2, "", ["a", "p"]), term_wrong(a.mul(n), -n, "", ["a", "p"])])
	var xn := pw("x", n) if n > 1 else "x"
	var steps := {}
	if top:
		steps["reciprocal-rule"] = ["A reciprocal of a power is a negative power: 1/%s = %s." % [xn, pw("x", -n)],
			"So %s = %d × 1/%s = %s." % [shown, c, xn, mono(a, -n)], say(ans)]
		steps["quotient-law"] = ["Write the top as %d%s, since %s = 1: %s = %d%s/%s." % [c, pw("x", 0), pw("x", 0), shown, c, pw("x", 0), xn],
			"Dividing subtracts the exponents: %s/%s = x^(0 − %d) = %s." % [pw("x", 0), xn, n, pw("x", -n)], "So %s = %s." % [shown, mono(a, -n)], say(ans)]
	else:
		steps["reciprocal-rule"] = ["Only %s moves up, so split the number off: %s = (1/%d) × 1/%s." % [xn, shown, c, xn],
			"1/%s = %s, so %s = %s." % [xn, pw("x", -n), shown, mono(a, -n)], say(ans)]
		steps["quotient-law"] = ["Split the number off: %s = (1/%d) × 1/%s, and write 1 as %s." % [shown, c, xn, pw("x", 0)],
			"Dividing subtracts the exponents: %s/%s = x^(0 − %d) = %s." % [pw("x", 0), xn, n, pw("x", -n)], "So %s = %s." % [shown, mono(a, -n)], say(ans)]
	return _pack([], "Write %s in the form ax^p, where a and p are constants." % shown, ans, w, fill, steps)


# ── Simplifying ──────────────────────────────────────────────

static func product_text(s: Dictionary) -> String:
	return "(%s)^%d × %s" % [mono(s.a, s.m), s.pp, mono(s.b, s.n)]


## "x^(8 − 3)", "x^(8 + 2)": the exponents of a product, with a negative one subtracted.
static func sum_exp(a: int, b: int) -> String:
	return "x^(%d %s %d)" % [a, "+" if b > 0 else "−", absi(b)]


func u_power_of_product(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: int = s.a
	var m: int = s.m
	var p: int = s.pp
	var b: int = s.b
	var n: int = s.n
	var C: int = s.C
	var e: int = s.e
	var ap := S.ipow(a, p)
	var ans := term_ans(Q.new(C), e)
	var list: Array = [term_wrong(Q.new(C), m + p + n, R_POW_ADD), term_wrong(Q.new(a * b), e, R_PART)]
	if a * p != ap:
		list.append(term_wrong(Q.new(a * p * b), e, R_COEF_TIMES))
	if n < 0:
		list.append(term_wrong(Q.new(C), m * p - n, R_SUB_NEG))
	var w := form_wrongs(ans, list)
	var fill := form_fillers(ans, w, [term_wrong(Q.new(C), e + 1, ""), term_wrong(Q.new(C), e - 1, ""), term_wrong(Q.new(ap + b), e, ""),
		term_wrong(Q.new(C), m * p * n, "")])
	var shown := product_text(s)
	var inner := mono(a, m)
	var powered := mono(ap, m * p)
	var copies: Array = []
	for i in p:
		copies.append(inner)
	var times_a: Array = []
	for i in p:
		times_a.append(str(a))
	var last := "%s × %s = %s%s = %s" % [powered, mono(b, n), (str(C) if C != 1 else ""), sum_exp(m * p, n), mono(C, e)]
	var x0 := 2
	var orig := S.qpow(Q.new(a * S.ipow(x0, m)), p).mul(Q.new(b)).mul(S.qpow(x0, n))
	var mine := Q.new(C).mul(S.qpow(x0, e))
	var steps := {
		"apply-laws": ["The power applies to %d and to %s: (%s)^%d = %d^%d × x^(%d × %d) = %s." % [a, pw("x", m), inner, p, a, p, m, p, powered],
			"Multiplying adds the exponents: " + last + ".", say(ans)],
		"expand-definition": ["Write the power out: (%s)^%d = %s." % [inner, p, " × ".join(copies)],
			"The numbers give %s = %d, and the %d factors of %s give x^(%s) = %s: %s." % [" × ".join(times_a), ap, p, pw("x", m), " + ".join(copies.map(func(_c): return str(m))), pw("x", m * p), powered],
			"Then %s." % last, say(ans)],
		"substitute-check": ["With the laws: (%s)^%d = %s, and %s." % [inner, p, powered, last],
			"Check at x = %d: %s = %s and %s = %s." % [x0, shown.replace("x", "(%d)" % x0), orig.text(), mono(C, e).replace("x", "(%d)" % x0), mine.text()], say(ans)],
	}
	var out := _pack([], "Simplify %s, giving your answer in the form cx^e." % shown, ans, w, fill, steps)
	# A working that raises only the x to the power: at line 1, or at line 2 after the plan.
	var bad_power := mono(a, m * p)
	var lines: Array = ["(%s)^%d = %s" % [inner, p, bad_power], "%s × %s = %s%s" % [bad_power, mono(b, n), str(a * b) if a * b != 1 else "", sum_exp(m * p, n)],
		"%d %s %d = %s" % [m * p, "+" if n > 0 else "−", absi(n), N(e)], "So %s = %s." % [shown, mono(a * b, e)]]
	var bad := 0
	if rng.chance(0.5):
		lines = ["Raise the bracket to the power %d, then multiply by %s." % [p, mono(b, n)], "(%s)^%d = %s" % [inner, p, bad_power],
			"%s × %s = %s%s" % [bad_power, mono(b, n), str(a * b) if a * b != 1 else "", sum_exp(m * p, n)], "So %s = %s." % [shown, mono(a * b, e)]]
		bad = 1
	out.spot = {"lines": lines, "bad": bad, "ref": R_SPOT_PART, "why": "the power applies to the whole bracket, so (%s)^%d = %s" % [inner, p, powered]}
	return out


## a^E b^F with each letter on the side its exponent's sign puts it: "b^4/a^5", "a^3/b", "a^2b^3".
static func ab_text(ea: int, eb: int) -> String:
	var top: Array = []
	var bottom: Array = []
	for pair in [["a", ea], ["b", eb]]:
		var e: int = pair[1]
		if e > 0:
			top.append(pair[0] if e == 1 else pw(pair[0], e))
		elif e < 0:
			bottom.append(pair[0] if e == -1 else pw(pair[0], -e))
	var t := "".join(top) if not top.is_empty() else "1"
	if bottom.is_empty():
		return t
	var below := "".join(bottom)
	return "%s/%s" % [t, below if bottom.size() == 1 else "(%s)" % below]


## The quotient's answer in its own layout: the letter with the positive exponent on top.
static func quotient_ans(ea: int, eb: int) -> Dictionary:
	var up := "a" if ea > 0 else "b"
	var down := "b" if ea > 0 else "a"
	var parts: Array = [up + "^", {"slot": "e1"}, "/" + down + "^", {"slot": "e2"}]
	return DifferentiationViews.form(ab_text(ea, eb), parts, {"e1": Q.new(absi(ea if ea > 0 else eb)), "e2": Q.new(absi(eb if ea > 0 else ea))})


static func quotient_wrong(ea: int, eb: int, ref: String) -> Dictionary:
	return DifferentiationViews.alt(ab_text(ea, eb), ref)


static func quotient_shown(ex: Array) -> String:
	return "(%s%s)/(%s%s)" % [_letter("a", ex[0]), _letter("b", ex[1]), _letter("a", ex[2]), _letter("b", ex[3])]


static func _letter(l: String, e: int) -> String:
	return l if e == 1 else pw(l, e)


func u_two_letter_quotient(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ex: Array = s.ex
	var ea: int = s.ea
	var eb: int = s.eb
	var ans := quotient_ans(ea, eb)
	var w := form_wrongs(ans, [quotient_wrong(-ea, -eb, R_WRONG_WAY), quotient_wrong(ex[0] + ex[2], ex[1] + ex[3], R_ADD_DIV)])
	var fill := form_fillers(ans, w, [quotient_wrong(absi(ea), absi(eb), ""), quotient_wrong(ea + (1 if ea > 0 else -1), eb, ""),
		quotient_wrong(ea, eb + (1 if eb > 0 else -1), ""), quotient_wrong(ea * 2, eb, "")])
	var shown := quotient_shown(ex)
	var sub := func(top: int, bot: int) -> String: return "%s − %s" % [N(top), P(bot)]
	var neg_line := "A negative exponent is a reciprocal, so %s%s = %s." % [_letter("a", ea), _letter("b", eb), ab_text(ea, eb)]
	var a0 := 2
	var b0 := 3
	var orig := S.qpow(a0, ex[0]).mul(S.qpow(b0, ex[1])).div(S.qpow(a0, ex[2]).mul(S.qpow(b0, ex[3])))
	var mine := S.qpow(a0, ea).mul(S.qpow(b0, eb))
	return _pack([], "Simplify %s, giving your answer with positive exponents only." % shown, ans, w, fill, {
		"apply-laws": ["Dividing subtracts the exponents, letter by letter: a^(%s) = %s and b^(%s) = %s." % [sub.call(ex[0], ex[2]), _letter("a", ea), sub.call(ex[1], ex[3]), _letter("b", eb)],
			neg_line, say(ans)],
		"substitute-check": ["With the laws, the quotient is %s%s = %s." % [_letter("a", ea), _letter("b", eb), ab_text(ea, eb)],
			"Check at a = %d and b = %d: %s = %s, and %s = %s." % [a0, b0, _at(shown, a0, b0), orig.text(), _at(ab_text(ea, eb), a0, b0), mine.text()], say(ans)],
	})


static func _at(text: String, a0: int, b0: int) -> String:
	return text.replace("a", "(%d)" % a0).replace("b", "(%d)" % b0)


# ── A power of one prime ─────────────────────────────────────

static func prime_shown(s: Dictionary) -> String:
	return "%s %s %s" % [pw(s.A, s.m), s.op, pw(s.B, s.n)]


static func prime_ans(t: int, k: int) -> Dictionary:
	return DifferentiationViews.form(pw(t, k), ["%d^" % t, {"slot": "k"}], {"k": Q.new(k)})


static func prime_wrong(t: int, k: int, ref: String) -> Dictionary:
	return DifferentiationViews.alt(pw(t, k), ref, {"k": Q.new(k)})


## "2^2", or "2 is 2 itself" where the power is 1.
static func as_power(n: int, t: int, p: int) -> String:
	return "%d = %s" % [n, pw(t, p)] if p > 1 else "%d is %d itself" % [n, t]


func u_single_prime_power(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: int = s.t
	var k: int = s.k
	var sign := 1 if s.op == "×" else -1
	var ans := prime_ans(t, k)
	var list: Array = [prime_wrong(t, s.m + sign * s.n, R_NO_PRIME)]
	if s.op == "×":
		list.push_front(DifferentiationViews.alt(pw(s.A * s.B, s.m + s.n), R_BASES))
	var w := form_wrongs(ans, list)
	var fill := form_fillers(ans, w, [prime_wrong(t, k + 1, ""), prime_wrong(t, k - 1, ""), prime_wrong(t, -k, ""), prime_wrong(t, s.i * s.m * s.j * s.n, "")])
	var ea: int = s.i * s.m
	var eb: int = s.j * s.n
	var shown := prime_shown(s)
	var law := "%s %s %s = %s" % [pw(t, ea), s.op, pw(t, eb), "%d^(%s %s %s)" % [t, N(ea), "+" if sign > 0 else "−", P(eb)]]
	return _pack([shown], "Write this number as a single power of %d, in the form %d^k." % [t, t], ans, w, fill, {
		"common-base": ["Write each number as a power of %d: %s and %s." % [t, as_power(s.A, t, s.i), as_power(s.B, t, s.j)],
			"A power of a power multiplies the exponents: %s = %s and %s = %s." % [pw(s.A, s.m), pw(t, ea), pw(s.B, s.n), pw(t, eb)],
			"%s exponents: %s = %s." % ["Multiplying adds the" if sign > 0 else "Dividing subtracts the", law, pw(t, k)], say(ans)],
	})
