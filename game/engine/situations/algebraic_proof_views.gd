class_name AlgebraicProofViews
extends ExtensionViews
## The views on the `algebraic-proof` situation: one builder per unknown of t1-algebraic-proof
## (FAL-728). A phone can't read a written proof, so each unknown is one decision inside a
## proof, with one right answer that code works out: a simplified form, a missing line, the
## next line, the first wrong line and its correction, a factor, a bracket, a remainder, or
## which of four arguments is a proof at all.
##
## Every proof is a chain of lines (chain()), built from the situation's numbers. Each line
## holds its text and the slots a student types in. A chain can be built with a slip: the same
## algebra with one wrong move, carried down to the end, so wrong options are what that slip
## really gives and every slip has a line to show.
##
## Representations: "equation" (written out) and "words" (a sentence about numbers). `given` is
## the situation, plus which line a question hid or spoiled, for the SymPy checker.

const SKILL_ID := "SL1.6.identity-lhs-rhs#"
const SKILL_INT := "SL1.6.integer-proof#"
const R_ASSUME := SKILL_ID + "0"
const R_VALUES := SKILL_ID + "1"
const R_NO_END := SKILL_ID + "2"
const R_EXAMPLES := SKILL_INT + "1"
const R_BRACKET := SKILL_INT + "2"
## The type's own slips, by their place in the catalogue's misconceptions.
const TYPE := "t1-algebraic-proof#"
## The map's own text for this one quotes an odd number's form, which a question about
## multiples of 7 doesn't show, so the type has its own.
const R_SAME_LETTER := TYPE + "3"
const R_MID := TYPE + "6"
const R_SQ := TYPE + "7"
const R_SIGN := TYPE + "8"
const R_PART := TYPE + "9"
const R_SPLIT := TYPE + "10"
const R_TOP := TYPE + "11"
const R_GAPS := TYPE + "12"
const R_COEF := TYPE + "13"
const R_DOTS := TYPE + "14"

## The slip numbers of chain(): statement -> the slip each number makes.
const SLIPS := {
	"square-diff": [R_MID, R_SQ],
	"sym": [R_MID, R_SIGN, R_SQ],
	"sym-mult": [R_MID, R_SIGN, R_SQ],
	"shift": [R_MID, R_SQ, R_SIGN],
	"combine": [R_PART, R_SIGN],
	"split": [R_SPLIT, R_MID, R_SQ],
	"triple": [R_SQ, R_TOP],
	"reciprocal": [R_PART, R_SIGN],
	"ap": [R_GAPS],
}
const UNSUITED := "This statement does not suit that method, so work through it line by line."

const UNKNOWNS := ["simplify-left-side", "common-expression", "missing-line", "next-step", "valid-proof", "flawed-step", "multiple-k",
	"consecutive-sum", "greatest-divisor", "finish-divisibility", "represent-integers", "case-bracket", "consecutive-factors", "remainder-form"]
## The unknowns the bank asks on Paper 2 as well: its one Paper 2 part is an identity.
const BOTH_PAPERS := ["simplify-left-side", "common-expression", "missing-line", "next-step", "valid-proof", "flawed-step"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, angle: String) -> Array:
	if not has(unknown):
		return []
	return [1, 2] if unknown in BOTH_PAPERS and angle != "algebraic-form" else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = AlgebraicProofSituation.export(s)
	out.given.merge(out.get("shown", {}))
	return out


# ── Writing a line ───────────────────────────────────────────

## A term of a line: its sign is worked out by where it stands. With an id, it is a slot.
static func T(id: String, c: Variant, rest: String = "") -> Dictionary:
	return {"id": id, "c": Q.of(c), "rest": rest}


## A term shown as given, not typed.
static func K(c: Variant, rest: String = "") -> Dictionary:
	return T("", c, rest)


## One term's text: first in a bracket "−6x", later " − 6x".
static func term(c: Q, rest: String, first: bool) -> String:
	var mag := c.abs_q()
	var body: String
	if rest == "" or rest.begins_with("/"):
		body = mag.text() + rest
	else:
		body = Fmt.lead(mag) + rest
	if first:
		return ("−" if c.sign() < 0 else "") + body
	return (" − " if c.sign() < 0 else " + ") + body


## Whether a term written after this text is the first in its bracket.
static func opens(text: String) -> bool:
	return text == "" or text.ends_with("(") or text.ends_with("[") or text.ends_with("/")


## A line from strings and terms: {"text", "parts" (the typed form), "v" (slot -> value),
## "items", "why" (what this line did)}. A zero term drops out of the text, and keeps its
## slot, so a slip with a zero coefficient can still be typed.
static func ln(items: Array, why: String = "") -> Dictionary:
	var text := ""
	var parts: Array = []
	var v := {}
	var open := true
	for it in items:
		if it is String:
			text += it
			parts.append(it)
			open = opens(it)
			continue
		var c: Q = it.c
		if not c.is_zero():
			text += term(c, it.rest, opens(text))
		if it.id == "":
			if not c.is_zero():
				parts.append(term(c, it.rest, open))
				open = false
			continue
		v[it.id] = c
		if not open:
			parts.append(" + ")
		parts.append({"slot": it.id})
		if it.rest != "":
			parts.append(it.rest)
		open = false
	return {"text": text, "parts": parts, "v": v, "items": items, "why": why}


## The line with its nth slot moved by d: a wrong line of the same shape.
static func bump(line: Dictionary, d: int, nth: int = 0) -> Dictionary:
	var items: Array = line.items.duplicate()
	var seen := 0
	for i in items.size():
		if items[i] is Dictionary and items[i].id != "":
			if seen == nth:
				items[i] = T(items[i].id, items[i].c.add(Q.new(d)), items[i].rest)
				break
			seen += 1
	return ln(items, line.why)


## "(x − 3)": the letter plus a number, in a bracket.
static func br(letter: String, c: int) -> String:
	return "(%s%s)" % [letter, Fmt.plus(c)]


## "(3n + 2)".
static func br2(p: int, letter: String, q: int) -> String:
	return "(%s)" % bare(p, letter, q)


## "3n + 2".
static func bare(p: int, letter: String, q: int) -> String:
	return "%s%s%s" % [Fmt.lead(p), letter, Fmt.plus(q)]


static func sum_terms(s: Dictionary) -> String:
	var bits: PackedStringArray = []
	var bare: String = Fmt.lead(s.u) + "n"
	for i in s.c:
		var c: int = s.v + i * s.w
		bits.append(bare if c == 0 else "(%s%s)" % [bare, Fmt.plus(c)])
	return " + ".join(bits)


static func left(s: Dictionary) -> String:
	match s.fam:
		"square-diff":
			return "%s² − n²" % br("n", s.d)
		"sym", "sym-mult":
			return "%s² − %s²" % [br2(s.p, s.letter, s.q), br2(s.p, s.letter, -s.q)]
		"shift":
			return "%s²%s" % [br("x", -s.a), Fmt.plus(s.b)]
		"combine":
			return "%sx%s − %d/%s" % [Fmt.lead(s.p), Fmt.plus(s.q), s.c, br("x", -s.d)]
		"split":
			return "%s²/x" % br("x", -s.a)
		"triple":
			return "x² + ((x² − %d)/%d)²" % [s.k * s.k, 2 * s.k]
		"reciprocal":
			return "%d/n − %d/%s" % [s.a, s.a, br("n", s.d)]
		"ap":
			return sum_terms(s)
	return ""


## The right side as the statement gives it: the last line of the chain.
static func right(s: Dictionary) -> String:
	return chain(s).back().text


## What LHS is called: an identity has sides, a divisibility claim has a name.
static func name_of(s: Dictionary) -> String:
	return {"sym-mult": "E", "ap": "S"}.get(s.fam, "LHS")


static func domain(s: Dictionary) -> String:
	match s.fam:
		"combine":
			return ", for x ≠ %s" % Fmt.num(s.d)
		"split":
			return ", for x ≠ 0"
		"reciprocal":
			return ", for n ≠ 0 and n ≠ %s" % Fmt.num(-s.d)
	return ""


static func claim_line(s: Dictionary, rhs: String = "") -> String:
	return "Prove that %s ≡ %s%s." % [left(s), rhs if rhs != "" else right(s), domain(s)]


## The statement to prove, as the question shows it.
static func statement(s: Dictionary, rep: String) -> Array:
	if s.fam == "sym-mult" or s.fam == "ap":
		return numbers_shown(s, rep) + ["Prove that %s is a multiple of %d for every positive integer n." % [name_of(s), s.m]]
	if rep != "words":
		return [claim_line(s)]
	if s.fam == "square-diff":
		return ["Two integers differ by %d: n and n + %d." % [s.d, s.d], "Prove that the difference of their squares is %d times their sum." % s.d]
	return ["Two numbers are %s and %s." % [bare(s.p, "x", s.q), bare(s.p, "x", -s.q)],
		"Prove that the square of the first minus the square of the second is %s." % right(s)]


## The expression named, in symbols or in a sentence.
static func numbers_shown(s: Dictionary, rep: String, nm: String = "") -> Array:
	if nm == "":
		nm = name_of(s)
	if rep != "words":
		return ["%s = %s" % [nm, left(s)]]
	match s.fam:
		"square-diff":
			return ["Two integers differ by %d: n and n + %d." % [s.d, s.d], "%s is the square of the larger minus the square of the smaller." % nm]
		"sym":
			return ["Two numbers are %s and %s." % [bare(s.p, "x", s.q), bare(s.p, "x", -s.q)], "%s is the square of the first minus the square of the second." % nm]
		"sym-mult":
			return ["Two numbers are %s and %s, where n is a positive integer." % [bare(s.p, "n", s.q), bare(s.p, "n", -s.q)],
				"%s is the square of the first minus the square of the second." % nm]
		"ap":
			var first: String = Fmt.lead(s.u) + "n" + (Fmt.plus(s.v) if s.v != 0 else "")
			var what := "%d numbers, each %d more than the one before" % [s.c, s.w] if s.kind == "steps" else "%d consecutive %s" % [s.c, ap_noun(s)]
			return ["%s is the sum of %s, and the smallest is %s, where n is a positive integer." % [nm, what, first]]
	return []


static func ap_noun(s: Dictionary) -> String:
	return {"integers": "integers", "evens": "even numbers", "odds": "odd numbers"}.get(s.kind, "")


# ── The chains ───────────────────────────────────────────────

## A proof as lines, from the statement to the right side. slip (see SLIPS) makes one wrong
## move and carries it on, and then the chain stops where the line can't be written.
static func chain(s: Dictionary, slip: int = 0) -> Array:
	match s.fam:
		"square-diff":
			return _square_diff(s, slip)
		"sym", "sym-mult":
			return _sym(s, slip)
		"shift":
			return _shift(s, slip)
		"combine":
			return _combine(s, slip)
		"split":
			return _split(s, slip)
		"triple":
			return _triple(s, slip)
		"reciprocal":
			return _reciprocal(s, slip)
		"ap":
			return _ap(s, slip)
	return []


static func _square_diff(s: Dictionary, slip: int) -> Array:
	var d: int = s.d
	var mid: int = [2 * d, d, 0][slip]
	var out := [ln([left(s)]),
		ln(["n²", T("u", mid, "n"), T("b", d * d), " − n²"], "Expand %s²" % br("n", d)),
		ln([T("u", mid, "n"), T("b", d * d)], "The n² terms cancel")]
	if mid != 0:
		out.append(ln([K(d), "(", T("u", mid / d, "n"), T("b", d), ")"], "Take out the common factor %d" % d))
	return out


static func _sym(s: Dictionary, slip: int) -> Array:
	var p: int = s.p
	var q: int = s.q
	var x: String = s.letter
	var pp: int = p * p
	var mid: int = p * q if slip == 1 else 2 * p * q
	var qq: int = q * q
	var x2: String = x + "²"
	var out := [ln([left(s)])]
	if slip == 3:
		out.append(ln(["(", K(pp, x2), T("u", qq), ") − (", K(pp, x2), T("b", -qq), ")"], "Square each term"))
		out.append(ln([K(pp, x2), T("u", qq), K(-pp, x2), T("b", qq)], "The minus changes the sign of each term in the second bracket"))
		out.append(ln([T("u", 2 * qq)], "Collect like terms"))
		return out
	out.append(ln(["(", K(pp, x2), T("u", mid, x), T("b", qq), ") − (", K(pp, x2), T("c", -mid, x), T("d", qq), ")"], "Expand both squares"))
	var last: int = qq if slip == 2 else -qq
	out.append(ln([K(pp, x2), T("u", mid, x), T("b", qq), K(-pp, x2), T("c", mid, x), T("d", last)], "The minus changes the sign of each term in the second bracket"))
	var items: Array = [T("u", 2 * mid, x)]
	if slip == 2:
		items.append(T("b", 2 * qq))
	out.append(ln(items, "The %s terms and the numbers cancel" % x2))
	return out + _multiple(s, 2 * mid, slip == 2)


## sym-mult's last line, m(rn), where the working got there.
static func _multiple(s: Dictionary, big: int, has_tail: bool) -> Array:
	if s.fam != "sym-mult" or has_tail or big % int(s.m) != 0:
		return []
	return [ln([K(s.m), "(", T("k", big / int(s.m), s.letter), ")"], "Take out the factor %d" % s.m)]


## The same statements by the difference of two squares, a² − b² = (a − b)(a + b). Slip 1
## is the only one: writing it as (a + b)(a + b).
static func factor_chain(s: Dictionary, slip: int = 0) -> Array:
	var out := [ln([left(s)])]
	if s.fam == "square-diff":
		var d: int = s.d
		var why := "Use a² − b² = (a − b)(a + b), with a = n + %d and b = n" % d
		if slip == 0:
			out.append(ln(["[(n", T("u", d), ") − n][(n", T("b", d), ") + n]"], why))
			out.append(ln([T("u", d), "(", T("b", 2, "n"), T("c", d), ")"], "Simplify each bracket"))
			out.append(ln([T("u", 2 * d, "n"), T("b", d * d)], "Multiply out"))
		else:
			out.append(ln(["[(n", T("u", d), ") + n][(n", T("b", d), ") + n]"], why))
			out.append(ln(["(", T("b", 2, "n"), T("c", d), ")²"], "Simplify each bracket"))
			out.append(ln([K(4, "n²"), T("u", 4 * d, "n"), T("b", d * d)], "Multiply out"))
		return out
	var p: int = s.p
	var q: int = s.q
	var x: String = s.letter
	var why2 := "Use a² − b² = (a − b)(a + b), with a = %s and b = %s" % [bare(p, x, q), bare(p, x, -q)]
	if slip == 0:
		out.append(ln(["[(", K(p, x), T("u", q), ") − (", K(p, x), T("b", -q), ")][(", K(p, x), T("c", q), ") + (", K(p, x), T("d", -q), ")]"], why2))
		out.append(ln(["(", T("u", 2 * q), ")(", T("b", 2 * p, x), ")"], "Simplify each bracket"))
		out.append(ln([T("u", 4 * p * q, x)], "Multiply the brackets"))
		return out + _multiple(s, 4 * p * q, false)
	out.append(ln(["[(", K(p, x), T("u", q), ") + (", K(p, x), T("b", -q), ")][(", K(p, x), T("c", q), ") + (", K(p, x), T("d", -q), ")]"], why2))
	out.append(ln(["(", T("u", 2 * p, x), ")(", T("b", 2 * p, x), ")"], "Simplify each bracket"))
	out.append(ln([T("u", 4 * p * p, x + "²")], "Multiply the brackets"))
	return out


static func _shift(s: Dictionary, slip: int) -> Array:
	var a: int = s.a
	var b: int = s.b
	var m: int = [-2 * a, -a, 0, 2 * a][slip]
	var aa: int = kept_square(a) if slip == 2 else a * a
	return [ln([left(s)]),
		ln(["x²", T("u", m, "x"), T("b", aa), K(b)], "Expand %s²" % br("x", -a)),
		ln(["x²", T("u", m, "x"), T("b", aa + b)], "Collect the numbers")]


## The last term of (x − a)² when each term is squared and keeps its sign.
static func kept_square(a: int) -> int:
	return -a * a if a > 0 else a * a


static func _combine(s: Dictionary, slip: int) -> Array:
	var p: int = s.p
	var q: int = s.q
	var c: int = s.c
	var d: int = s.d
	var den := ")/" + br("x", -d)
	var over := "Write everything over %s" % br("x", -d)
	var line1: Dictionary
	var line2: Dictionary
	var line3: Dictionary
	if slip == 1:
		line1 = ln(["(", K(p, "x"), br("x", -d), T("u", q), T("b", -c), den], over)
		line2 = ln(["(", K(p, "x²"), T("u", -p * d, "x"), T("c", q), T("d", -c), den], "Multiply out")
		line3 = ln(["(", K(p, "x²"), T("u", -p * d, "x"), T("b", q - c), den], "Collect like terms")
	else:
		var num: int = -q * d if slip == 0 else q * d
		line1 = ln(["((", K(p, "x"), T("u", q), ")", br("x", -d), T("b", -c), den], over)
		line2 = ln(["(", K(p, "x²"), T("u", -p * d, "x"), T("b", q, "x"), T("c", num), T("d", -c), den], "Multiply out")
		line3 = ln(["(", K(p, "x²"), T("u", q - p * d, "x"), T("b", num - c), den], "Collect like terms")
	return [ln([left(s)]), line1, line2, line3]


static func _split(s: Dictionary, slip: int) -> Array:
	var a: int = s.a
	var aa: int = kept_square(a) if slip == 3 else a * a
	var m: int = [-2 * a, -2 * a, -a, 0][slip]
	var out := [ln([left(s)]), ln(["(x²", T("u", m, "x"), T("b", aa), ")/x"], "Expand %s²" % br("x", -a))]
	if slip == 1:
		out.append(ln(["x²/x", T("u", m, "x/x"), T("b", aa)], "Divide each term by x"))
		out.append(ln(["x", T("u", m), T("b", aa)], "Cancel the x"))
	else:
		out.append(ln(["x²/x", T("u", m, "x/x"), T("b", aa, "/x")], "Divide each term by x"))
		out.append(ln(["x", T("u", m), T("b", aa, "/x")], "Cancel the x"))
	return out


static func _triple(s: Dictionary, slip: int) -> Array:
	var k: int = s.k
	var kk: int = k * k
	var den: int = 2 * k if slip == 2 else 4 * kk
	var mid: int = 0 if slip == 1 else -2 * kk
	var tail: int = -kk * kk if slip == 1 else kk * kk
	var out := [ln([left(s)]),
		ln(["x² + (x⁴", T("u", mid, "x²"), T("b", tail), ")/", T("c", den)], "Square the top and the bottom of the bracket"),
		ln(["(", T("u", den, "x²"), " + x⁴", T("b", mid, "x²"), T("c", tail), ")/", T("d", den)], "Write x² over %d" % den),
		ln(["(x⁴", T("u", den + mid, "x²"), T("b", tail), ")/", T("c", den)], "Collect the x² terms")]
	if slip == 0:
		out.append(ln(["((x²", T("u", kk), ")/", T("b", 2 * k), ")²"], "The top is a perfect square, and %d = %d²" % [den, 2 * k]))
	return out


static func _reciprocal(s: Dictionary, slip: int) -> Array:
	var a: int = s.a
	var d: int = s.d
	var den := "n" + br("n", d)
	var over := "/(%s)" % den
	var out := [ln([left(s)]), ln(["(", K(a), br("n", d), T("b", -a, "n"), ")" + over], "Write both fractions over %s" % den)]
	match slip:
		0:
			out.append(ln(["(", T("u", a, "n"), T("b", a * d), T("c", -a, "n"), ")" + over], "Multiply out"))
			out.append(ln([T("u", a * d), over], "The n terms cancel"))
		1:
			out.append(ln(["(", T("u", a, "n"), T("b", d), T("c", -a, "n"), ")" + over], "Multiply out"))
			out.append(ln([T("u", d), over], "The n terms cancel"))
		2:
			out.append(ln(["(", T("u", a, "n"), T("b", a * d), T("c", a, "n"), ")" + over], "Multiply out"))
			out.append(ln(["(", T("u", 2 * a, "n"), T("b", a * d), ")" + over], "Collect the n terms"))
	return out


static func _ap(s: Dictionary, slip: int) -> Array:
	var tail: int = AlgebraicProofSituation.ap_tail(s, slip == 1)
	var m: int = s.m
	var out := [ln([left(s)]), ln([T("u", s.big, "n"), T("b", tail)], "Add the %d terms: the n terms, then the numbers" % s.c)]
	if tail % m == 0:
		out.append(ln([K(m), "(", T("u", s.big / m, "n"), T("b", tail / m), ")"], "Take out the factor %d" % m))
	return out


## The chain a method writes: the difference of two squares where it asks for that.
static func steps_of(s: Dictionary, angle: String, slip: int = 0) -> Array:
	if angle == "factorise" and s.fam in ["square-diff", "sym", "sym-mult"]:
		return factor_chain(s, slip)
	return chain(s, slip)


## The chain as a proof, ending on the right side as the statement writes it.
static func proof_of(s: Dictionary, angle: String, slip: int = 0) -> Array:
	var c := steps_of(s, angle, slip)
	return c.slice(0, 3) if angle == "factorise" and s.fam == "square-diff" else c


## How many slips a method's chain has.
static func slips_of(s: Dictionary, angle: String) -> int:
	if angle == "factorise" and s.fam in ["square-diff", "sym", "sym-mult"]:
		return 1
	return SLIPS[s.fam].size()


static func slip_ref(s: Dictionary, angle: String, slip: int) -> String:
	if angle == "factorise" and s.fam in ["square-diff", "sym", "sym-mult"]:
		return R_DOTS
	return SLIPS[s.fam][slip - 1]


## The line of the chain that is the simplified form.
static func done(s: Dictionary, angle: String) -> int:
	if angle == "factorise" and s.fam in ["square-diff", "sym"]:
		return 3
	return {"square-diff": 2, "shift": 2}.get(s.fam, 3)


# ── Answers and options ──────────────────────────────────────

## An exact answer typed in a line's slots.
static func form(line: Dictionary, label: String = "") -> Dictionary:
	var v: Dictionary = line.v.duplicate()
	v.text = line.text
	var ans := Answer.make("form", v, {"parts": [label] + line.parts}, label)
	ans.exact = true
	return ans


## A wrong option. With slots it can be typed; without, it can only be picked.
static func alt(text: String, ref: String = "", slots: Dictionary = {}) -> Dictionary:
	var v := slots.duplicate()
	v.text = text
	if slots.is_empty():
		v.shape = "other"
	return wrong(v, ref)


## A wrong line as an option, typed if it has the right line's shape.
static func line_option(line: Dictionary, good: Dictionary, ref: String = "") -> Dictionary:
	return alt(line.text, ref, line.v if line.parts == good.parts else {})


## What each slip gives on line i of a chain. With made_here, only the slips made on that line:
## with the lines before it shown right, an earlier slip isn't what a wrong line there did.
static func slip_options(s: Dictionary, angle: String, i: int, good: Dictionary, made_here: bool = false) -> Array:
	var clean := steps_of(s, angle)
	var out: Array = []
	for k in range(1, slips_of(s, angle) + 1):
		var c := steps_of(s, angle, k)
		if c.size() > i and c[i].text != good.text and (not made_here or c[i - 1].text == clean[i - 1].text):
			out.append(line_option(c[i], good, slip_ref(s, angle, k)))
	return out


## Wrong lines of the good one's shape, to fill the options.
static func bumps(good: Dictionary) -> Array:
	var out: Array = []
	for d in [1, -1, 2]:
		for nth in good.v.size():
			out.append(line_option(bump(good, d, nth), good))
	return out


static func claim_of(tag: String, text: String) -> Dictionary:
	return {"form": tag, "vals": [], "text": text}


## A question picked from sentences. wrongs_in: [[text, ref], ...].
static func pick_answer(right_text: String, wrongs_in: Array) -> Dictionary:
	var ws: Array = []
	for i in wrongs_in.size():
		ws.append(wrong(claim_of("w%d" % i, wrongs_in[i][0]), wrongs_in[i][1]))
	return {"answer": Answer.make("claim", claim_of("right", right_text)), "wrongs": ws, "generic": []}


## The working of a chain: one step per line, up to line `upto`.
static func walk(c: Array, upto: int, nm: String) -> Array:
	var out: Array = ["%s = %s" % [nm, c[0].text]]
	for i in range(1, upto + 1):
		out.append("%s: %s = %s" % [c[i].why, nm, c[i].text])
	return out


## Every method of an ask: steps(method) for those that suit the statement. One that
## doesn't (asked as "another way") says so and takes the method that does.
func every_method(s: Dictionary, ans: Dictionary, steps: Callable) -> Dictionary:
	var methods: Dictionary = AlgebraicProofSituation.ASKS[s.ask]
	var works: Array = methods.keys().filter(func(m): return AlgebraicProofSituation.suits(s.ask, m, s.fam))
	var out := {}
	for m in methods:
		if m in works:
			out[m] = method(steps.call(m), ans.values)
		elif m == angle:
			out[m] = method([UNSUITED] + steps.call(works[0]), ans.values)
	return out


## The one method whose proof a question shows: its lines belong to that method, so another
## method's working would not reach this answer.
func asked_method(s: Dictionary, steps: Array, ans: Dictionary) -> Dictionary:
	var head: Array = [] if AlgebraicProofSituation.suits(s.ask, angle, s.fam) else [UNSUITED]
	return {angle: method(head + steps, ans.values)}


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## The last step of a question picked from lines and sentences.
static func picked(head: String, ans: Dictionary) -> String:
	return "%s: %s" % [head, Answer.text(ans)]


static func numbered(c: Array, nm: String, hide: int = -1, upto: int = -1) -> Array:
	var out: Array = []
	var last: int = c.size() - 1 if upto < 0 else upto
	for i in last + 1:
		var body: String = "?" if i == hide else c[i].text
		if i == 0:
			out.append("Line 1: %s = %s" % [nm, body])
		elif i == hide:
			out.append("Line %d: ?" % (i + 1))
		else:
			out.append("Line %d: = %s" % [i + 1, body])
	return out


# ── Identities ───────────────────────────────────────────────

func u_simplify_left_side(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var nm := "L"
	var i := done(s, angle)
	var c := steps_of(s, angle)
	var good: Dictionary = c[i]
	var ans := form(good, nm + " = ")
	var asked: String = {"combine": "Write L as a single fraction.", "triple": "Write L as a single fraction.", "reciprocal": "Write L as a single fraction.",
		"split": "Write L as separate terms."}.get(s.fam, "Simplify L.")
	return {"asked": asked, "lines": numbers_shown(s, rep, nm), "answer": ans, "wrongs": slip_options(s, angle, i, good), "generic": bumps(good).map(func(w): return w.values),
		"methods": every_method(s, ans, func(m): return walk(steps_of(s, m), done(s, m), nm) + [say(ans)])}


## The other side's working, to where the left side's goes (common-form).
static func other_side(s: Dictionary) -> Array:
	match s.fam:
		"square-diff":
			return [ln(["%d(2n%s)" % [s.d, Fmt.plus(s.d)]]), ln([T("u", 2 * s.d, "n"), T("b", s.d * s.d)], "Multiply out")]
		"shift":
			return [ln(["x%s%s" % [br("x", -2 * s.a), Fmt.plus(s.a * s.a + s.b)]]),
				ln(["x²", T("u", -2 * s.a, "x"), T("b", s.a * s.a + s.b)], "Multiply out")]
		"split":
			var a: int = s.a
			return [ln(["x", K(-2 * a), K(a * a, "/x")]), ln(["x²/x", T("u", -2 * a, "x/x"), T("b", a * a, "/x")], "Write each term over x"),
				ln(["(x²", T("u", -2 * a, "x"), T("b", a * a), ")/x"], "Add the fractions")]
	var kk: int = s.k * s.k
	return [ln(["((x²", K(kk), ")/%d)²" % (2 * s.k)]), ln(["(x⁴", T("u", 2 * kk, "x²"), T("b", kk * kk), ")/", T("c", 4 * kk)], "Square top and bottom")]


func u_common_expression(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := chain(s)
	var i: int = 1 if s.fam == "split" else done(s, "expand-simplify")
	var good: Dictionary = c[i]
	var ans := form(good)
	var rhs: Array = other_side(s)
	var opts := slip_options(s, "expand-simplify", i, good)
	var steps := walk(c, i, "LHS") + walk(rhs, rhs.size() - 1, "RHS")
	steps.append("Both sides reach the same expression, so LHS ≡ RHS.")
	steps.append("The common expression is %s." % good.text)
	return {"asked": "Simplify each side on its own. Which expression do both sides reach?", "lines": [claim_line(s, rhs[0].text)], "answer": ans,
		"wrongs": opts, "generic": bumps(good).map(func(w): return w.values), "methods": {"common-form": method(steps, ans.values)}}


func u_missing_line(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := proof_of(s, angle)
	var hide := rng.int_in(1, c.size() - 2)
	var good: Dictionary = c[hide]
	var ans := form(good, "Line %d: " % (hide + 1))
	return {"asked": "Line %d of this proof is missing. What does it say?" % (hide + 1), "lines": statement(s, rep) + numbered(c, "LHS", hide), "answer": ans,
		"wrongs": slip_options(s, angle, hide, good, true), "generic": bumps(good).map(func(w): return w.values),
		"methods": asked_method(s, walk(c, c.size() - 1, "LHS") + [picked("So the missing line is", ans)], ans), "shown": {"hide": hide}}


func u_next_step(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := proof_of(s, angle)
	var at := rng.int_in(1, c.size() - 1)
	var good: Dictionary = c[at]
	var x: String = s.letter
	var rhs: String = c.back().text
	var at_x := test_point(s)
	# The two slips of reasoning, and one slip of algebra: any that shows on this line.
	var wrongs_in: Array = [["%s − (%s) = 0" % [left(s), rhs], R_ASSUME],
		["Put %s = %d: both sides equal %s." % [x, at_x, Fmt.num(side_value(s, at_x))], R_VALUES]]
	for w in rng.shuffled(slip_options(s, angle, at, good, true)) + bumps(good):
		wrongs_in.append(["= " + str(w.values.text), w.ref])
	var out := pick_answer("= " + good.text, wrongs_in.slice(0, 3))
	var ans: Dictionary = out.answer
	out.asked = "Which line comes next in this proof?"
	out.lines = [claim_line(s, rhs)] + numbered(c, "LHS", -1, at - 1)
	out.methods = asked_method(s, walk(c, at, "LHS") + [picked("So the next line is", ans)], ans)
	out.shown = {"at": at}
	return out


## A value of the letter where a statement's two sides can be worked out.
static func test_point(s: Dictionary) -> int:
	var x := 2
	while (s.fam == "combine" and x == s.d) or (s.fam == "reciprocal" and x == -s.d):
		x += 1
	return x


## The left side at a value: a whole number or a fraction.
static func side_value(s: Dictionary, x: int) -> Q:
	match s.fam:
		"square-diff":
			return Q.new((x + s.d) * (x + s.d) - x * x)
		"sym":
			return Q.new(4 * s.p * s.q * x)
		"shift":
			return Q.new((x - s.a) * (x - s.a) + s.b)
		"combine":
			return Q.new(s.p * x + s.q).sub(Q.new(s.c, x - s.d))
		"split":
			return Q.new((x - s.a) * (x - s.a), x)
		"triple":
			return Q.new(x * x + s.k * s.k, 2 * s.k).mul(Q.new(x * x + s.k * s.k, 2 * s.k))
		"reciprocal":
			return Q.new(s.a * s.d, x * (x + s.d))
	return Q.new(0)


func u_valid_proof(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := chain(s)
	var x: String = s.letter
	var last: String = c.back().text
	var first: String = c[1].text
	var right_text := "LHS = %s = %s = RHS, so LHS ≡ RHS." % [first, last]
	var a := Fmt.num(side_value(s, 1))
	var b := Fmt.num(side_value(s, 2))
	var out := pick_answer(right_text, [
		["Assume LHS = RHS. Take the RHS from both sides: 0 = 0, so LHS ≡ RHS.", R_ASSUME],
		["At %s = 1 both sides are %s and at %s = 2 both are %s, so LHS ≡ RHS." % [x, a, x, b], R_VALUES],
		["LHS = %s" % first, R_NO_END]])
	out.asked = "Which of these is a complete proof?"
	out.lines = [claim_line(s)]
	var ans: Dictionary = out.answer
	var steps := walk(c, c.size() - 1, "LHS")
	steps.append_array(["The last line is the right side, and each line followed from the one before for every %s." % x, picked("So the complete proof is", ans)])
	out.methods = {"expand-simplify": method(steps, ans.values)}
	return out


func u_flawed_step(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var how := "algebraic-form" if s.fam == "ap" else "expand-simplify"
	var c := chain(s)
	var slip := rng.int_in(1, slips_of(s, how))
	var bad := chain(s, slip)
	var at := 1
	while at < bad.size() - 1 and bad[at].text == c[at].text:
		at += 1
	var good: Dictionary = c[at]
	var nm := name_of(s)
	var options: Array = []
	for i in bad.size():
		options.append("Line %d" % (i + 1))
	var v: Dictionary = good.v.duplicate()
	v.line = "Line %d" % (at + 1)
	v.text = "%s should read: %s" % [v.line, good.text]
	var ans := Answer.make("form", v, {"parts": [{"pick": "line", "options": options}, " should read: "] + good.parts})
	ans.exact = true
	var said := func(line_no: int, line: Dictionary) -> String: return "Line %d should read: %s" % [line_no + 1, line.text]
	var fix := func(line_no: int, line: Dictionary, ref: String = "") -> Dictionary:
		var slots: Dictionary = line.v.duplicate() if line_no == at and line.parts == good.parts else {}
		if not slots.is_empty():
			slots.line = v.line
		return alt(said.call(line_no, line), ref, slots)
	var wrongs: Array = []
	for k in range(1, slips_of(s, how) + 1):
		var other := chain(s, k)
		if k != slip and other.size() > at and other[at].text != good.text and other[at].text != bad[at].text and other[at - 1].text == c[at - 1].text:
			wrongs.append(fix.call(at, other[at], slip_ref(s, how, k)))
	# A later line is wrong too, but it only follows the first mistake.
	if at + 1 < bad.size() and at + 1 < c.size():
		wrongs.append(fix.call(at + 1, c[at + 1]))
	for d in [1, -1, 2]:
		wrongs.append(fix.call(at, bump(good, d)))
		wrongs.append(fix.call(at, bump(good, d, good.v.size() - 1)))
	var lines: Array = statement(s, "equation") + ["A student's proof has one slip, carried down to the end:"] + numbered(bad, nm)
	var steps: Array = ["Check each line against the one before. Line %d says %s, which does not follow from line %d." % [at + 1, bad[at].text, at]]
	for i in range(at, c.size()):
		steps.append("%s: %s = %s" % [c[i].why, nm, c[i].text])
	steps.append(say(ans))
	return {"asked": "Find the first line that goes wrong, and correct it.", "lines": lines, "answer": ans, "wrongs": wrongs, "generic": [],
		"methods": asked_method(s, steps, ans), "shown": {"at": at, "slip": slip}}


# ── Divisibility ─────────────────────────────────────────────

func u_multiple_k(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: int = s.m
	var big: int = 4 * s.p * s.q
	var good: Dictionary = ln([T("k", big / m, "n")])
	var ans := form(good, "k = ")
	var wrongs: Array = []
	for k in range(1, slips_of(s, angle) + 1):
		var items: Array = steps_of(s, angle, k)[3].items.map(func(it): return T("k" if it.rest == "n" else "c", it.c.div(Q.new(m)), it.rest))
		wrongs.append(line_option(ln(items), good, slip_ref(s, angle, k)))
	var nm := name_of(s)
	var generic: Array = [ln([T("k", big, "n")]), ln([T("k", big / m + 1, "n")]), ln([T("k", big / m + 2, "n")]), ln([T("k", big * m, "n")])]
	return {"asked": "Find k in terms of n.", "lines": numbers_shown(s, rep) + ["%s is a multiple of %d: %s = %dk." % [nm, m, nm, m]], "answer": ans, "wrongs": wrongs,
		"generic": generic.map(func(w): return line_option(w, good).values),
		"methods": every_method(s, ans, func(meth): return walk(steps_of(s, meth), 4, nm) + ["%s is an integer, so %s is %d times an integer." % [good.text, nm, m], say(ans)])}


func u_consecutive_sum(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := chain(s)
	var good: Dictionary = c[2]
	var ans := form(good, "S = ")
	var tail: int = s.tail
	var m: int = s.m
	var generic: Array = [ln([K(m), "(", T("u", s.big, "n"), T("b", tail), ")"]), ln([K(m), "(", T("u", s.big / m, "n"), T("b", tail), ")"]),
		ln([K(m), "(", T("u", s.big, "n"), T("b", tail / m), ")"])]
	var lines: Array = numbers_shown(s, rep)
	return {"asked": "Write S as %d times an integer expression in n." % m, "lines": lines, "answer": ans, "wrongs": slip_options(s, "algebraic-form", 2, good),
		"generic": (generic.map(func(w): return line_option(w, good)) + bumps(good)).map(func(w): return w.values),
		"methods": {"algebraic-form": method(walk(c, 2, "S") + ["n is an integer, so the bracket is an integer, and S is a multiple of %d." % m, say(ans)], ans.values)}}


func u_greatest_divisor(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := chain(s)
	var m: int = s.m
	var big: int = s.big
	var tail: int = s.tail
	var ans := Answer.make("number", {"v": Q.new(m)}, {}, "greatest divisor = ")
	ans.exact = true
	var one := big + tail
	var two := 2 * big + tail
	var bracket: String = c[2].text
	var lines: Array = numbers_shown(s, rep)
	return {"asked": "Find the largest whole number that divides S for every positive integer n.", "lines": lines, "answer": ans,
		"wrongs": [wrong({"v": Q.new(big)}, R_BRACKET), wrong({"v": Q.new(one)}, R_EXAMPLES)],
		"generic": [{"v": Q.new(m + 1)}, {"v": Q.new(2 * m)}, {"v": Q.new(tail)}, {"v": Q.new(s.c)}, {"v": Q.new(3 * m)}],
		"methods": {"algebraic-form": method(walk(c, 1, "S") + ["The hcf of %d and %d is %d, so S = %s and %d divides S for every n." % [big, tail, m, bracket, m],
			"No larger number works: at n = 1 and n = 2, S is %d and %d, and their hcf is %d." % [one, two, Q.gcd(one, two)], say(ans)], ans.values)}}


func u_finish_divisibility(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := chain(s)
	var m: int = s.m
	var big: int = s.big
	var tail: int = s.tail
	var inner: String = ln([T("u", big / m, "n"), T("b", tail / m)]).text
	var one := big + tail
	var two := 2 * big + tail
	var off: String = ln([T("u", big / m, "n"), T("b", tail)]).text
	var out := pick_answer("S = %d(%s), and %s is an integer." % [m, inner, inner], [
		["S = %d(n + %s), and %d is a multiple of %d." % [big, Q.new(tail, big).text(), big, m], R_BRACKET],
		["S = %d when n = 1 and %d when n = 2, and both are multiples of %d." % [one, two, m], R_EXAMPLES],
		["S = %d(%s), and %s is an integer." % [m, off, off], ""]])
	var ans: Dictionary = out.answer
	out.asked = "Which line proves that S is a multiple of %d for every positive integer n?" % m
	out.lines = numbers_shown(s, rep) + ["S = %s" % c[1].text]
	out.methods = {"algebraic-form": method(walk(c, 2, "S") + ["n is an integer, so %s is an integer: that is what makes S a multiple of %d." % [inner, m], picked("So the line that proves it is", ans)], ans.values)}
	return out


## The numbers a statement is about: "2a + 1" for its letter.
static func pair_text(s: Dictionary, letter: String, shift: int = 0) -> String:
	var body: String = Fmt.lead(s.m) + letter
	var c: int = s.r + shift
	return body + (Fmt.plus(c) if c != 0 else "")


static func pair_noun(s: Dictionary) -> String:
	if s.m == 2:
		return "odd numbers" if s.r == 1 else "even numbers"
	if s.r == 0:
		return "multiples of %d" % s.m
	return "integers that each leave remainder %d on division by %d" % [s.r, s.m]


static func pair_claim(s: Dictionary) -> String:
	var noun := pair_noun(s)
	match s.claim:
		"sum-even":
			return "the sum of two %s is even" % noun
		"product-odd":
			return "the product of two odd numbers is odd"
		"product-four":
			return "the product of two even numbers is a multiple of 4"
		"sum-multiple":
			return "the sum of two %s is a multiple of %d" % [noun, s.m]
	return "the difference of two %s is a multiple of %d" % [noun, s.m]


## The line a proof of the claim goes on to.
static func pair_step(s: Dictionary) -> String:
	var a: String = s.l1
	var b: String = s.l2
	var m: int = s.m
	var p1 := pair_text(s, a)
	var p2 := pair_text(s, b)
	match s.claim:
		"sum-even":
			if s.r == 1:
				return "(%s) + (%s) = 2%s + 2%s + 2 = 2(%s + %s + 1), and %s + %s + 1 is an integer." % [p1, p2, a, b, a, b, a, b]
			return "%s + %s = 2(%s + %s), and %s + %s is an integer." % [p1, p2, a, b, a, b]
		"product-odd":
			var inner := "2%s%s + %s + %s" % [a, b, a, b]
			return "(%s)(%s) = 4%s%s + 2%s + 2%s + 1 = 2(%s) + 1, and %s is an integer." % [p1, p2, a, b, a, b, inner, inner]
		"product-four":
			return "(%s)(%s) = 4%s%s, and %s%s is an integer." % [p1, p2, a, b, a, b]
		"sum-multiple":
			return "%s + %s = %d(%s + %s), and %s + %s is an integer." % [p1, p2, m, a, b, a, b]
	return "(%s) − (%s) = %d(%s − %s), and %s − %s is an integer." % [p1, p2, m, a, b, a, b]


func u_represent_integers(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: String = s.l1
	var b: String = s.l2
	var m: int = s.m
	var one: int = m + s.r
	var other: int = 2 * m + s.r
	var out := pick_answer("Let them be %s and %s, for integers %s and %s." % [pair_text(s, a), pair_text(s, b), a, b], [
		["Let them be %s and %s, for an integer %s." % [pair_text(s, a), pair_text(s, a), a], R_SAME_LETTER],
		["Take %d and %d, and check that the claim holds for them." % [one, other], R_EXAMPLES],
		["Let them be %s and %s, for an integer %s." % [pair_text(s, a), pair_text(s, a, m), a], ""]])
	var ans: Dictionary = out.answer
	out.asked = "Which opening starts a proof that covers every pair?"
	out.lines = ["Prove that %s." % pair_claim(s)]
	out.methods = {"algebraic-form": method(["Two numbers need not be equal or next to each other, so each needs its own letter.",
		"%s and %s can be any two %s." % [pair_text(s, a), pair_text(s, b), pair_noun(s)],
		"Then the proof runs: %s" % pair_step(s), picked("So the opening is", ans)], ans.values)}
	return out


func u_case_bracket(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := parity_chain(s)
	var good: Dictionary = c.back()
	var ans := form(good, "E = ")
	var slips: Array = []
	for k in parity_slips(s):
		var sl := parity_chain(s, k.slip)
		slips.append(line_option(sl.back(), good, k.ref))
	var sub: String = "2k" if s.part == "even" else "2k + 1"
	var lines: Array = [("E = %s, where n is an integer." % Fmt.poly([1, s.a, s.b], "n"))] if rep != "words" else \
		["Take an integer n. Square it, add %s times n, and add %s. Call the result E." % [Fmt.num(s.a), Fmt.num(s.b)]]
	lines.append("Case: n is %s, so n = %s for an integer k." % [s.part, sub])
	var steps := walk(c, c.size() - 1, "E")
	steps.append("The bracket is an integer, so E is even in this case.")
	var other: Dictionary = s.duplicate()
	other.part = "odd" if s.part == "even" else "even"
	steps.append("The other case, n = %s, gives E = %s, so E is even for every integer n." % ["2k + 1" if s.part == "even" else "2k", parity_chain(other).back().text])
	steps.append(say(ans))
	return {"asked": "Write E as 2 times an integer expression in k.", "lines": lines, "answer": ans, "wrongs": slips,
		"generic": bumps(good).map(func(w): return w.values), "methods": {"cases": method(steps, ans.values)}}


## n² + an + b at n = 2k or 2k + 1, as lines.
static func parity_chain(s: Dictionary, slip: int = 0) -> Array:
	var a: int = s.a
	var b: int = s.b
	if s.part == "even":
		var sq: int = 2 if slip == 3 else 4
		return [ln(["(2k)²", K(a, "(2k)"), K(b)]), ln([K(sq, "k²"), T("u", 2 * a, "k"), T("b", b)], "Multiply out"),
			ln(["2(", T("u", sq / 2, "k²"), T("b", a, "k"), T("c", b / 2), ")"], "Take out the factor 2")]
	var mid: int = [4, 0, 2][slip]
	var num: int = 1 + a + b
	return [ln(["(2k + 1)²", K(a, "(2k + 1)"), K(b)]),
		ln([K(4, "k²"), T("u", mid, "k"), K(1), T("b", 2 * a, "k"), T("c", a), K(b)], "Multiply out"),
		ln([K(4, "k²"), T("u", mid + 2 * a, "k"), T("b", num)], "Collect like terms"),
		ln(["2(", T("u", 2, "k²"), T("b", mid / 2 + a, "k"), T("c", num / 2), ")"], "Take out the factor 2")]


static func parity_slips(s: Dictionary) -> Array:
	if s.part == "even":
		return [{"slip": 3, "ref": R_COEF}]
	return [{"slip": 1, "ref": R_SQ}, {"slip": 2, "ref": R_MID}]


func u_consecutive_factors(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: int = s.m
	var sum: int = 2 * m + 1
	var prod: int = m * (m + 1)
	var two := func(p: int, q: int) -> Dictionary: return ln(["(n", T("p", p), ")(n", T("q", q), ")"])
	var good: Dictionary = two.call(m, m + 1)
	var ans := form(good, "E = ")
	ans.unordered = [["p", "q"]]
	var lines: Array = ["E = %s, where n is an integer." % Fmt.poly([1, sum, prod], "n")] if rep != "words" else \
		["Take an integer n. Square it, add %s times n, and add %s. Call the result E." % [Fmt.num(sum), Fmt.num(prod)]]
	var slips: Array = [two.call(-m, -m - 1), two.call(m - 1, m + 2), two.call(m, m + 2), two.call(m - 1, m + 1), two.call(m + 1, m + 2)]
	var steps: Array = ["Find two numbers that add to %s and multiply to %s: %s and %s." % [Fmt.num(sum), Fmt.num(prod), Fmt.num(m), Fmt.num(m + 1)],
		"E = %s" % good.text, "n%s and n%s are consecutive integers, so one of them is even." % [Fmt.plus(m), Fmt.plus(m + 1)],
		"A product with an even factor is even, so E is even for every integer n.", say(ans)]
	return {"asked": "Write E as a product of two consecutive integers.", "lines": lines, "answer": ans, "wrongs": [],
		"generic": slips.map(func(w): return line_option(w, good).values), "methods": {"consecutive-product": method(steps, ans.values)}}


## A sum of squares as lines, down to its remainder.
static func never_chain(s: Dictionary) -> Array:
	var d: int = s.d
	var dd: int = d * d
	if s.shape == "three":
		return [ln(["%s² + n² + %s²" % [br("n", -d), br("n", d)]]),
			ln(["n²", T("u", -2 * d, "n"), T("b", dd), " + n² + n²", T("c", 2 * d, "n"), T("d", dd)], "Expand both squares"),
			ln([K(3, "n²"), T("u", 2 * dd)], "The n terms cancel"),
			ln(["3(n²", T("u", s.q0), ")", T("b", s.r)], "%d = 3 × %d + %d, so take out the factor 3" % [2 * dd, s.q0, s.r])]
	return [ln(["n² + %s²" % br("n", d)]), ln(["n² + n²", T("u", 2 * d, "n"), T("b", dd)], "Expand the square"),
		ln([K(2, "n²"), T("u", 2 * d, "n"), T("b", dd)], "Collect the n² terms"),
		ln(["2(n²", T("u", d, "n"), T("b", s.q0), ")", T("c", s.r)], "%d = 2 × %d + %d, so take out the factor 2" % [dd, s.q0, s.r])]


func u_remainder_form(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := never_chain(s)
	var good: Dictionary = c.back()
	var ans := form(good, "S = ")
	var m: int = s.m
	var d: int = s.d
	var wrongs: Array = []
	if s.shape == "three":
		wrongs.append(alt("3n²", R_SQ, {"u": Q.new(0), "b": Q.new(0)}))
		wrongs.append(alt("3(n² + %s)" % Q.new(2 * d * d, 3).text(), R_BRACKET))
	else:
		wrongs.append(line_option(ln(["2(n²", T("u", 0, "n"), T("b", s.q0), ")", T("c", s.r)]), good, R_SQ))
		wrongs.append(alt("2(n²%sn + %s)" % [Fmt.plus(d), Q.new(d * d, 2).text()], R_BRACKET))
	var who := "the three integers n − %d, n and n + %d" % [d, d] if s.shape == "three" else "the two integers n and n + %d" % d
	var lines: Array = ["S is the sum of the squares of %s, where n is an integer." % who] if rep == "words" else ["S = %s, where n is an integer." % c[0].text]
	var steps := walk(c, c.size() - 1, "S")
	steps.append("The bracket is an integer, so S is %d more than a multiple of %d, and is never divisible by %d." % [s.r, m, m])
	steps.append(say(ans))
	return {"asked": "Write S as %d times an integer expression, plus a remainder r with 0 < r < %d." % [m, m], "lines": lines, "answer": ans, "wrongs": wrongs,
		"generic": [bump(good, 1, good.v.size() - 1), bump(good, 1), bump(good, -1), bump(good, 2)].map(func(w): return line_option(w, good).values),
		"methods": {"algebraic-form": method(steps, ans.values)}}
