class_name SequenceProofViews
extends AlgebraicProofViews
## The views on the `sequence-proof` situation: one builder per unknown of t1-sequence-proof
## (FAL-753). As in AlgebraicProofViews, a phone can't read a written proof, so each unknown is
## one decision inside a proof, with one right answer that code works out: a relation, a missing
## line, the next line, the first wrong line and its correction, a common ratio or difference
## the proof establishes, or which of four arguments is a proof at all.
##
## Every proof is a chain of lines (lines_of()), each written out in full as "left = right" from
## the situation's numbers. A chain can be built with a slip: the same proof with one wrong move,
## carried down to the end, so a wrong option is what that slip really gives.
##
## Representations: "equation" (the claim in symbols), "words" (a sentence about the lists) and
## "diagram" (a dot pattern drawn by PlotView's "dots", for the dot-diagram method). `given` is the
## situation, plus which line a question hid or spoiled, for the SymPy checker.

const SKILL := "SL1.6.series-proof#"
const M_CHECK := SKILL + "0"
const M_CIRCULAR := SKILL + "1"
const M_PARTICULAR := SKILL + "2"
const M_GAPS := SKILL + "3"
const M_FIRST_ONLY := SKILL + "4"
const M_ONE_TERM := SKILL + "5"
const M_TERMWISE := SKILL + "6"
const M_NO_DOUBLE := SKILL + "7"
const M_WRONG_TEST := SKILL + "8"
const M_RECIPROCAL := SKILL + "9"
const M_LOG_DIFF := SKILL + "10"
const M_RATIO_AS_DIFF := SKILL + "11"
const M_NO_HALF := SKILL + "12"
const M_NO_TWO := SKILL + "13"
const M_LAST_AS_SUM := SKILL + "14"
const M_SUM_AS_TERM := SKILL + "15"
const M_NEXT_SUM := SKILL + "16"
const M_COEFF := SKILL + "17"
const M_SWAP := SKILL + "18"
const M_WIDTH := SKILL + "19"
const M_CORNER := SKILL + "20"
const M_LAST_TWICE := SKILL + "21"
const M_HALF_COLUMNS := SKILL + "22"
const M_ACROSS := SKILL + "23"
const M_SIGN_MOVE := SKILL + "24"
const M_POSITION := SKILL + "25"
const M_NO_DIVIDE := SKILL + "26"
const M_CONSECUTIVE := SKILL + "27"
const M_HALF_RECT := SKILL + "28"
const M_D_OVER_A := SKILL + "29"
const M_LAST_ONLY := SKILL + "30"

## The slip numbers of lines_of(): chain -> the slip each number makes.
const SLIP_REFS := {
	"ap-term": [M_ONE_TERM, M_FIRST_ONLY],
	"sum-term": [M_TERMWISE, M_FIRST_ONLY, M_NEXT_SUM],
	"log-geo": [M_LOG_DIFF, M_RATIO_AS_DIFF, M_RECIPROCAL],
	"linked": [M_NO_DOUBLE, M_TERMWISE, M_SIGN_MOVE],
	"sum-formula": [M_GAPS, M_NO_TWO, M_NO_HALF],
	"sum-columns": [M_NO_HALF, M_HALF_COLUMNS, M_LAST_TWICE],
}
const ASKED := ["arithmetic-relation", "geometric-relation", "second-term-bound", "common-ratio-check", "difference-in-a", "linked-ratio",
	"log-difference", "log-general-term", "constant-difference", "particular-terms", "term-from-sum", "difference-from-sum",
	"sum-by-formula", "pair-sum", "dot-total", "dot-layer", "dot-rectangle", "missing-line", "next-line", "flawed-line", "valid-proof"]
const STEP_TITLE := "Show uₙ₊₁ − uₙ is a constant"
## How a method reads on an unknown where the map's own name doesn't fit.
const TITLES := {
	"arithmetic-relation": {"general-difference": "Compare the gaps between the terms"},
	"geometric-relation": {"general-difference": "Compare the ratios between the terms"},
	"second-term-bound": {"series-formula": "Write each term from its formula"},
	"common-ratio-check": {"general-difference": "Compare the ratios between neighbouring terms"},
	"difference-in-a": {"series-formula": "Write each term from its formula"},
	"linked-ratio": {"series-formula": "Write each term from its formula"},
	"log-general-term": {"series-formula": "Write the nth term from its formula"},
	"constant-difference": {"general-difference": STEP_TITLE},
	"particular-terms": {"general-difference": STEP_TITLE},
	"log-difference": {"general-difference": "Show vₙ₊₁ − vₙ is a constant"},
	"term-from-sum": {"general-difference": "Take Sₙ₋₁ from Sₙ"},
	"difference-from-sum": {"general-difference": "Take Sₙ₋₁ from Sₙ, then compare neighbouring terms"},
	"missing-line": {"general-difference": "Compare neighbouring terms"},
	"next-line": {"general-difference": "Compare neighbouring terms"},
	"flawed-line": {"general-difference": "Compare neighbouring terms"},
	"valid-proof": {"general-difference": "Compare neighbouring terms"},
}
const UN := "uₙ"
const UN1 := "uₙ₊₁"
const SN := "Sₙ"
const SN1 := "Sₙ₋₁"
const SN2 := "Sₙ₊₁"
const VN := "vₙ"
const VN1 := "vₙ₊₁"
const GAP := UN1 + " − " + UN
const LOG_GAP := VN1 + " − " + VN


func needs() -> Dictionary:
	var out := {}
	for u in ASKED:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.titles = TITLES.get(unknown, {})
	said_once(out.methods, out.answer)
	return out


# ── Writing a line ───────────────────────────────────────────

## A line "left = right": each side is what AlgebraicProofViews.ln() takes. Slots stay typed.
static func E(left_items: Array, right_items: Array, why: String = "") -> Dictionary:
	var a := ln(left_items)
	var b := ln(right_items)
	var v: Dictionary = a.v.duplicate()
	v.merge(b.v)
	return {"text": a.text + " = " + (b.text if b.text != "" else "0"), "parts": a.parts + [" = "] + b.parts, "v": v,
		"left": left_items, "right": right_items, "why": why}


## The line with its nth slot moved by d: a wrong line of the same shape.
static func bump_line(line: Dictionary, d: int, nth: int) -> Dictionary:
	var sides: Array = [line.left.duplicate(), line.right.duplicate()]
	var seen := 0
	for side in sides:
		for i in side.size():
			if side[i] is Dictionary and side[i].id != "":
				if seen == nth:
					side[i] = T(side[i].id, side[i].c.add(Q.new(d)), side[i].rest)
				seen += 1
	return E(sides[0], sides[1], line.why)


## Wrong lines of the good one's shape, to fill the options.
static func nudged(good: Dictionary) -> Array:
	var out: Array = []
	for d in [1, -1, 2]:
		for nth in good.v.size():
			out.append(line_option(bump_line(good, d, nth), good))
	return out.map(func(w): return w.values)


static func poly(c: Array, letter: String = "n") -> String:
	return Fmt.poly(c, letter)


static func sub(k: Variant) -> String:
	return ArithmeticSequenceViews.sub(k)


## "1st", "2nd", "3rd", "4th".
static func nth(k: int) -> String:
	var tail := "th"
	if k % 100 < 11 or k % 100 > 13:
		tail = {1: "st", 2: "nd", 3: "rd"}.get(k % 10, "th")
	return "%d%s" % [k, tail]


## "2d": a letter with its multiple.
static func times(c: int, letter: String) -> String:
	return Fmt.lead(c) + letter


## Term k of the sequence pn + q.
static func term_at(p: int, q: int, k: int) -> int:
	return p * k + q


## pn + q in a bracket, or n alone.
static func wrapped(p: int, q: int) -> String:
	return "(%s)" % poly([p, q]) if q != 0 else poly([p, q])


static func first_of(s: Dictionary) -> int:
	return s.p + s.q


## pn + c: the constant of u₁ + uₙ.
static func pair_tail(s: Dictionary) -> int:
	return s.p + 2 * s.q


static func base_log(s: Dictionary) -> String:
	return "log%s" % sub(s.b)


## The ratio of a log-geo claim, as a fraction when its power is negative.
static func geo_ratio(s: Dictionary) -> Q:
	var v := int(pow(float(s.b), float(absi(s.q))))
	return Q.new(v) if s.q > 0 else Q.new(1, v)


static func geo_first(s: Dictionary) -> int:
	return int(pow(float(s.b), float(s.p)))


## How a method's chain is named in SLIP_REFS.
static func chain_of(s: Dictionary, how: String) -> String:
	if s.fam == "sum-list":
		return "sum-columns" if how == "forwards-backwards" else "sum-formula"
	return s.fam


# ── The chains ───────────────────────────────────────────────

## A proof as lines. slip (see SLIP_REFS) makes one wrong move and carries it on.
static func lines_of(s: Dictionary, how: String, slip: int = 0) -> Array:
	match chain_of(s, how):
		"ap-term":
			return _gap_lines(s, slip)
		"sum-term":
			return _difference_lines(s, slip)
		"log-geo":
			return _log_lines(s, slip)
		"linked":
			return _linked_lines(s, slip)
		"sum-formula":
			return _formula_lines(s, slip)
		"sum-columns":
			return _column_lines(s, slip)
	return []


static func _gap_lines(s: Dictionary, slip: int) -> Array:
	var p: int = s.p
	var q: int = s.q
	var inc: int = 1 if slip == 1 else p
	var tail: int = q if slip == 2 else -q
	return [E([GAP], ["(%s(n + 1)%s) − (%s)" % [Fmt.lead(p), Fmt.plus(q), poly([p, q])]], "Put n + 1 in place of n"),
		E([GAP], [K(p, "n"), T("u", inc), T("b", q), K(-p, "n"), T("c", tail)], "Multiply out, and take away each term of the second bracket"),
		E([GAP], [T("u", inc + q + tail)], "The n terms cancel")]


static func _difference_lines(s: Dictionary, slip: int) -> Array:
	var a: int = s.A
	var b: int = s.B
	var both := poly([a, b, 0])
	if slip == 3:
		return [E([UN], [SN2 + " − " + SN], "Use the next sum"),
			E([UN], ["(", T("u", a, "(n + 1)²"), T("b", b, "(n + 1)"), ") − (%s)" % both], "Put the sums in"),
			E([UN], [K(a, "n²"), K(2 * a, "n"), K(a), K(b, "n"), K(b), K(-a, "n²"), K(-b, "n")], "Multiply out"),
			E([UN], [T("u", 2 * a, "n"), T("b", a + b)], "Collect like terms")]
	var mid: Array = [2 * a, -a, -b, b]
	if slip == 1:
		mid = [0, -a, -b, b]
	elif slip == 2:
		mid = [-2 * a, a, b, -b]
	var by_n: int = mid[0] + b + mid[2]
	var rest: int = mid[1] + mid[3]
	return [E([UN], [SN + " − " + SN1], "Sₙ less the sum of the terms before uₙ leaves uₙ"),
		E([UN], ["(", K(a, "n²"), K(b, "n"), ") − (", T("u", a, "(n − 1)²"), T("b", b, "(n − 1)"), ")"], "Put n − 1 in place of n"),
		E([UN], [K(a, "n²"), K(b, "n"), K(-a, "n²"), T("u", mid[0], "n"), T("b", mid[1]), T("c", mid[2], "n"), T("d", mid[3])], "Multiply out, and take away each term of the second bracket"),
		E([UN], [T("u", by_n, "n"), T("b", rest)], "Collect like terms")]


static func _log_lines(s: Dictionary, slip: int) -> Array:
	var lg := base_log(s)
	var r := geo_ratio(s)
	var first := E([LOG_GAP], ["%s %s − %s %s" % [lg, UN1, lg, UN]], "Each v is the log of its u")
	if slip == 1:
		return [first, E([LOG_GAP], ["%s(%s)" % [lg, GAP]], "Join the logs")]
	var flip: bool = slip == 3
	var why_ratio := "That fraction is the common ratio"
	var out := [first,
		E([LOG_GAP], ["%s(%s)" % [lg, UN + "/" + UN1 if flip else UN1 + "/" + UN]], "A difference of logs is the log of a quotient"),
		E([LOG_GAP], [lg + "(", T("u", Q.new(1).div(r) if flip else r), ")"], why_ratio)]
	var q: int = s.q
	var why_power := "%s = %s%s" % [Q.new(1).div(r).text() if flip else r.text(), s.b, Fmt.sup(-q if flip else q)]
	if slip == 2:
		out.append(E([LOG_GAP], [T("u", r)], "Take the log"))
	else:
		out.append(E([LOG_GAP], [T("u", -q if flip else q)], why_power))
	return out


static func _linked_lines(s: Dictionary, slip: int) -> Array:
	var i: int = s.i
	var j: int = s.j
	var ii := i * i
	var two: int = i if slip == 1 else 2 * i
	var m: int = [j - 2 * i, j - i, j, j + 2 * i][slip]
	var both := "a² and %sad" % Fmt.lead(two)
	var out := [E(["(a + %s)²" % times(i, "d")], ["a(a + %s)" % times(j, "d")], "The middle of three consecutive geometric terms, squared, is the product of the other two"),
		E(["a²", T("u", 0 if slip == 2 else two, "ad"), T("b", ii, "d²")], ["a²", T("c", j, "ad")], "Multiply out both sides"),
		E([T("u", ii, "d²")], [T("b", m, "ad")], "Take %s from both sides" % ("a²" if slip == 2 else both))]
	if i == 1:
		out.append(E(["d"], [T("u", m, "a")], "Divide by d, which is not zero"))
		return out
	out.append(E([T("u", ii, "d")], [T("b", m, "a")], "Divide by d, which is not zero"))
	out.append(E(["d"], [T("u", Q.new(m, ii), "a")], "Divide by %d" % ii))
	return out


static func _formula_lines(s: Dictionary, slip: int) -> Array:
	var p: int = s.p
	var f := first_of(s)
	var two: int = f if slip == 2 else 2 * f
	var gaps: int = 0 if slip == 1 else -p
	var head := "(n/2)("
	var steps := " + n × %d)" % p if slip == 1 else " + (n − 1) × %d)" % p
	var out := [E([SN], [head, T("u", two), steps], "Use Sₙ = (n/2)(2u₁ + (n − 1)d), with u₁ = %d and d = %d" % [f, p]),
		E([SN], [head, T("u", two), T("b", p, "n"), T("c", gaps), ")"], "Multiply out the inner bracket")]
	if slip == 3:
		out.append(E([SN], ["n(", T("u", p, "n"), T("b", two + gaps), ")"], "Collect the numbers"))
	else:
		out.append(E([SN], [head, T("u", p, "n"), T("b", two + gaps), ")"], "Collect the numbers"))
	return out


static func _column_lines(s: Dictionary, slip: int) -> Array:
	var p: int = s.p
	var q: int = s.q
	var f := first_of(s)
	var c := pair_tail(s)
	var top := p
	var tail := c
	if slip == 3:
		top = 2 * p
		tail = 2 * q
	var twice := "2" + SN
	var body := func(head: String) -> Array: return [head + "(", K(top, "n"), T("u", tail), ")"]
	var list := "%d + %d + %d + … + (%s)" % [f, f + p, f + 2 * p, poly([p, q])]
	var out := [E([SN], [list], "Write the sum forwards"),
		E([SN], ["(", K(p, "n"), T("u", q), ") + (", K(p, "n"), T("b", q - p), ") + (", K(p, "n"), T("c", q - 2 * p), ") + … + %d" % f], "Write it backwards"),
		E([twice], body.call("(n/2) copies of " if slip == 2 else "n copies of "), "Add the two lists column by column")]
	if slip == 2:
		out.append(E([twice], body.call("(n/2)"), "There are n/2 columns"))
		out.append(E([SN], body.call("(n/4)"), "Halve both sides"))
		return out
	out.append(E([twice], body.call("n"), "There are n columns"))
	out.append(E([SN], body.call("n" if slip == 1 else "(n/2)"), "Halve both sides"))
	return out


## How many slips a chain has.
static func slip_count(s: Dictionary, how: String) -> int:
	return SLIP_REFS[chain_of(s, how)].size()


static func slip_tag(s: Dictionary, how: String, k: int) -> String:
	return SLIP_REFS[chain_of(s, how)][k - 1]


## Slips that can be carried down a whole proof: joining logs by subtraction stops it.
static func carried(s: Dictionary, how: String) -> Array:
	var out: Array = []
	for k in range(1, slip_count(s, how) + 1):
		if not (s.fam == "log-geo" and k == 1):
			out.append(k)
	return out


## What each slip gives on line i of a chain. With made_here, only the slips made on that line:
## with the lines before it shown right, an earlier slip isn't what a wrong line there did.
static func slip_lines(s: Dictionary, how: String, i: int, good: Dictionary, made_here: bool = false) -> Array:
	var clean := lines_of(s, how)
	var out: Array = []
	var seen := {good.text: true}
	for k in range(1, slip_count(s, how) + 1):
		var c := lines_of(s, how, k)
		if c.size() <= i or seen.has(c[i].text):
			continue
		if made_here and i > 0 and c[i - 1].text != clean[i - 1].text:
			continue
		seen[c[i].text] = true
		out.append(line_option(c[i], good, slip_tag(s, how, k)))
	return out


# ── What a question shows ────────────────────────────────────

## The claim's setting, in symbols or in a sentence. A chain's claim comes after it.
static func setup(s: Dictionary, rep: String) -> Array:
	match s.fam:
		"ap-term":
			if rep == "words":
				return ["The nth term of a sequence is found by multiplying n by %s, then %s." % [Fmt.num(s.p), adding(s.q)]]
			return ["%s = %s, where n is a positive integer." % [UN, poly([s.p, s.q])]]
		"sum-term":
			if rep == "words":
				return ["The sum of the first n terms of a sequence is found by multiplying n² by %s, then %s n." % [Fmt.num(s.A), "adding %s times" % Fmt.num(s.B) if s.B > 0 else "taking away %s times" % Fmt.num(-s.B)]]
			return ["%s = %s is the sum of the first n terms of a sequence." % [SN, poly([s.A, s.B, 0])]]
		"log-geo":
			var r := geo_ratio(s)
			if rep == "words":
				return ["A geometric sequence uₙ starts at %d, and each term is %s times the one before." % [geo_first(s), r.text()],
					"A second sequence vₙ is the log base %d of each term." % s.b]
			return ["uₙ is a geometric sequence with u₁ = %d and common ratio %s." % [geo_first(s), r.text()],
				"%s = %s %s" % [VN, base_log(s), UN]]
		"linked":
			if rep == "words":
				return ["An arithmetic sequence has first term a and common difference d, and neither is zero.",
					"Its %s, %s and %s terms are three consecutive terms of a geometric sequence, in that order." % [nth(1), nth(s.i + 1), nth(s.j + 1)]]
			return ["An arithmetic sequence has first term a and common difference d, with a ≠ 0 and d ≠ 0.",
				"a, a + %s and a + %s are three consecutive terms of a geometric sequence." % [times(s.i, "d"), times(s.j, "d")]]
		"sum-list":
			if rep == "words":
				return ["A list of numbers starts at %d, and each number is %d more than the one before. %s is the sum of the first n numbers." % [first_of(s), s.p, SN]]
			return ["uₙ = %s is an arithmetic sequence, and %s is the sum of its first n terms." % [poly([s.p, s.q]), SN]]
	return []


## "adding 3" or "taking away 3".
static func adding(c: int) -> String:
	return "adding %d" % c if c > 0 else "taking away %d" % -c


## What a chain proves, as the question says it.
static func claim_text(s: Dictionary) -> String:
	match s.fam:
		"ap-term":
			return "Prove that the sequence is arithmetic."
		"sum-term":
			return "Prove that the sequence is arithmetic."
		"log-geo":
			return "Prove that vₙ is an arithmetic sequence."
		"linked":
			return "Prove that %s." % lines_of(s, "series-formula").back().text
	return "Prove that %s." % lines_of(s, "series-formula").back().text


static func shown(c: Array, hide: int = -1, upto: int = -1) -> Array:
	var out: Array = []
	var last: int = c.size() - 1 if upto < 0 else upto
	for i in last + 1:
		out.append("Line %d: %s" % [i + 1, "?" if i == hide else c[i].text])
	return out


## [text, ref] rows with each text once, and none that reads as the answer.
static func unique_texts(rows: Array, avoid: String) -> Array:
	var seen := {avoid: true}
	var out: Array = []
	for r in rows:
		if not seen.has(r[0]):
			seen[r[0]] = true
			out.append(r)
	return out


## The method whose proof a question shows, and every other method: their tabs say so. A shared
## situation belongs to no method, so its lines can be another's, and the working says that too.
func of_lines(s: Dictionary, steps: Array, ans: Dictionary) -> Dictionary:
	var head: Array = [] if SequenceProofSituation.suits(s.ask, angle, s.fam) else [UNSUITED]
	var out := {angle: method(head + steps, ans.values)}
	for m in SequenceProofSituation.ASKS[s.ask]:
		if m != angle:
			out[m] = method([OTHER_ROUTE] + steps, ans.values)
	return out


# ── Three terms: the exam's relations ────────────────────────

func u_arithmetic_relation(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: String = s.l1
	var y: String = s.l2
	var z: String = s.l3
	var e: int = s.e
	var row := func(a: int, b: int) -> Dictionary: return E([z], [T("u", a, y), T("b", b, x)])
	var good: Dictionary = row.call(e + 1, -e)
	var ans := form(good)
	var lines: Array = ["%s, %s and %s are the %s, %s and %s terms of an arithmetic sequence." % [x, y, z, nth(1), nth(2), nth(e + 2)]]
	if rep == "words":
		lines = ["In an arithmetic sequence, %s is the first term and %s comes straight after it. %s comes %d terms after %s." % [x, y, z, e, y]]
	var gap := "%s − %s" % [y, x]
	var steps: Array = ["%s − %s = d, the common difference." % [y, x],
		"%s is %d steps on from %s, so %s − %s = %d(%s)." % [z, e, y, z, y, e, gap],
		"Multiply out and add %s to both sides: %s" % [y, good.text], say(ans)]
	return {"asked": "Write %s in terms of %s and %s." % [z, x, y], "lines": lines, "answer": ans,
		"wrongs": [line_option(row.call(e + 3, -e - 2), good, M_POSITION), line_option(row.call(e + 1, -1), good, M_ONE_TERM), line_option(row.call(e - 1, -e), good, M_SIGN_MOVE)],
		"generic": nudged(good), "methods": {"general-difference": method(steps, ans.values)}}


func u_geometric_relation(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: String = s.l1
	var y: String = s.l2
	var z: String = s.l3
	var g: int = s.g
	var h: int = s.h
	var big := g + h
	var lines: Array = ["%s, %s and %s are the %s, %s and %s terms of a geometric sequence with no zero terms." % [x, y, z, nth(1), nth(1 + g), nth(1 + big)]]
	if rep == "words":
		lines = ["In a geometric sequence with no zero terms, %s is the first term, %s comes %d after it and %s comes %d after %s." % [x, y, g, z, h, y]]
	var left_side := "%s%s%s%s" % [x, Fmt.sup(h), z, Fmt.sup(g)]
	lines.append("%s = %s^k for every such sequence." % [left_side, y])
	var ans := Answer.make("number", {"v": Q.new(big)}, {}, "k = ")
	ans.exact = true
	var power := g * big
	var steps: Array = ["With common ratio r, %s = %sr%s and %s = %sr%s." % [y, x, Fmt.sup(g), z, x, Fmt.sup(big)],
		"%s = %s%sr%s" % [left_side, x, Fmt.sup(big), Fmt.sup(power)],
		"%s%s = (%sr%s)%s = %s%sr%s, the same expression." % [y, Fmt.sup(big), x, Fmt.sup(g), Fmt.sup(big), x, Fmt.sup(big), Fmt.sup(power)], say(ans)]
	return {"asked": "Find k.", "lines": lines, "answer": ans,
		"wrongs": [wrong({"v": Q.new(big + 1)}, M_POSITION), wrong({"v": Q.new(2 * mini(g, h))}, M_CONSECUTIVE if g != h else "")],
		"generic": [{"v": Q.new(big + 2)}, {"v": Q.new(big - 1)}, {"v": Q.new(big + 3)}, {"v": Q.new(g * h + 1)}],
		"methods": {"general-difference": method(steps, ans.values)}}


func u_second_term_bound(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var e: int = s.e
	var w: int = s.w
	var lines: Array = ["An arithmetic sequence and a geometric sequence both start at b. Their second terms are m and c, with m and c not zero.",
		"The %s term of the arithmetic sequence and the %s term of the geometric sequence are both %d." % [nth(e + 2), nth(3), w]]
	if rep == "words":
		lines = ["Two lists start on the same number b. One adds a fixed amount each time, and its next number is m. The other multiplies by a fixed amount, and its next number is c. Neither m nor c is zero.",
			"The adding list reaches %d at its %s number. The multiplying list reaches %d at its %s number." % [w, nth(e + 2), w, nth(3)]]
	var bound := Q.new(w, e + 1)
	var ans := Answer.make("number", {"v": bound}, {}, "L = ")
	ans.exact = true
	var coef := Fmt.lead(e + 1)
	var steps: Array = ["In the arithmetic sequence, %d − m = %s(m − b), so %sm = %d + %sb." % [w, Fmt.lead(e), coef, w, Fmt.lead(e)],
		"In the geometric sequence, c² = %db, so b = c²/%d. c is not zero, so b > 0." % [w, w],
		"So %sm > %d, and m > %s. b can be as close to 0 as we like, so no greater number works." % [coef, w, bound.text()], say(ans)]
	return {"asked": "m is always greater than a number L, and L is as great as it can be. Find L.", "lines": lines, "answer": ans,
		"wrongs": [wrong({"v": Q.new(w)}, M_NO_DIVIDE), wrong({"v": Q.new(w, e + 2)}, M_POSITION)],
		"generic": [{"v": Q.new(w, e + 1).add(Q.new(1))}, {"v": Q.new(2 * w, e + 1)}, {"v": Q.new(0)}, {"v": Q.new(w + e, e + 1)}],
		"methods": {"series-formula": method(steps, ans.values)}}


func k_text(c: int, d: int) -> String:
	return Fmt.poly([c, d], "k")


func u_common_ratio_check(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k0
	var r := Q.new(s.r_top, s.r_den)
	var t1 := Q.new(s.t1)
	var t2 := t1.mul(r)
	var t3 := t2.mul(r)
	var lines: Array = ["The first three terms of a sequence are u₁ = %s, u₂ = %s and u₃ = %s." % [k_text(s.c1, s.d1), k_text(s.c2, s.d2), k_text(s.c3, s.d3)],
		"k = %d" % k]
	if rep == "words":
		lines = ["A sequence's first term is %s, its second is %s and its third is %s, where k is %d." % [k_text(s.c1, s.d1), k_text(s.c2, s.d2), k_text(s.c3, s.d3), k]]
	var ans := Answer.make("number", {"v": r}, {}, "r = ")
	ans.exact = true
	var steps: Array = ["Put k = %d: u₁ = %s, u₂ = %s and u₃ = %s." % [k, t1.text(), t2.text(), t3.text()],
		"u₂/u₁ = %s/%s = %s and u₃/u₂ = %s/%s = %s." % [P(t2), P(t1), r.text(), P(t3), P(t2), r.text()],
		"The two ratios are equal, so the three terms are geometric.", say(ans)]
	return {"asked": "Show that the three terms form a geometric sequence, and find its common ratio r.", "lines": lines, "answer": ans,
		"wrongs": [wrong({"v": t2.sub(t1)}, M_WRONG_TEST), wrong({"v": Q.new(1).div(r)}, M_RECIPROCAL), wrong({"v": r.mul(r)}, M_ACROSS)],
		"generic": [{"v": r.neg()}, {"v": r.add(Q.new(1))}, {"v": r.sub(Q.new(1))}], "methods": {"general-difference": method(steps, ans.values)}}


# ── Arithmetic terms that are also geometric ─────────────────

## The lines as working: at most four steps, so a fifth line is said with the fourth.
static func walk_lines(c: Array) -> Array:
	var out: Array = []
	for i in mini(c.size(), 3):
		out.append("%s: %s" % [c[i].why, c[i].text])
	if c.size() == 4:
		out.append("%s: %s" % [c[3].why, c[3].text])
	elif c.size() == 5:
		out.append("%s, then %s: %s" % [c[3].why, c[4].why.to_lower(), c[4].text])
	return out


func u_difference_in_a(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := lines_of(s, "series-formula")
	var good: Dictionary = c.back()
	var ans := form(good)
	return {"asked": "Find d in terms of a.", "lines": setup(s, rep), "answer": ans, "wrongs": slip_lines(s, "series-formula", c.size() - 1, good),
		"generic": nudged(good), "methods": {"series-formula": method(walk_lines(c) + [say(ans)], ans.values)}}


func u_linked_ratio(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := lines_of(s, "series-formula")
	var k: int = (s.j - 2 * s.i) / (s.i * s.i)
	var r: int = 1 + s.i * k
	var ans := Answer.make("number", {"v": Q.new(r)}, {}, "r = ")
	ans.exact = true
	var steps: Array = ["%s: %s" % [c[0].why, c[0].text], "Solving for d gives %s." % c.back().text,
		"r = (a + %s)/a = (a + %s)/a = %d" % [times(s.i, "d"), times(s.i * k, "a"), r], say(ans)]
	var lines := setup(s, rep)
	lines.append("r is the common ratio of the geometric sequence.")
	return {"asked": "Find r.", "lines": lines, "answer": ans,
		"wrongs": [wrong({"v": Q.new(k)}, M_D_OVER_A), wrong({"v": Q.new(r * r)}, M_ACROSS), wrong({"v": Q.new(1, r)}, M_RECIPROCAL)],
		"generic": [{"v": Q.new(r + 1)}, {"v": Q.new(r + 2)}, {"v": Q.new(-r)}, {"v": Q.new(r + 3)}], "methods": {"series-formula": method(steps, ans.values)}}


# ── Logs of a geometric sequence ─────────────────────────────

func u_log_difference(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := lines_of(s, "general-difference")
	var ans := Answer.make("number", {"v": Q.new(s.q)}, {}, LOG_GAP + " = ")
	ans.exact = true
	var lines := setup(s, rep)
	var steps: Array = walk_lines(c) + [say(ans)]
	return {"asked": "Prove that vₙ is an arithmetic sequence, and find %s." % LOG_GAP, "lines": lines, "answer": ans,
		"wrongs": [wrong({"v": geo_ratio(s)}, M_RATIO_AS_DIFF), wrong({"v": Q.new(-s.q)}, M_RECIPROCAL), wrong({"v": Q.new(s.p)}, M_SWAP)],
		"generic": [{"v": Q.new(s.q + 1)}, {"v": Q.new(s.q - 1)}, {"v": Q.new(s.q + 2)}, {"v": Q.new(2 * s.q)}], "methods": {"general-difference": method(steps, ans.values)}}


func u_log_general_term(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var row := func(a: Variant, b: Variant) -> Dictionary: return E([VN], [T("u", a, "n"), T("b", b)])
	var good: Dictionary = row.call(q, p - q)
	var ans := form(good)
	var r := geo_ratio(s)
	var lg := base_log(s)
	var steps: Array = ["v₁ = %s %d = %d" % [lg, geo_first(s), p],
		"Each term multiplies by %s, so each v adds %s %s = %s." % [r.text(), lg, P(r), Fmt.num(q)],
		"%s = %d + (n − 1) × %s" % [VN, p, P(q)], say(ans)]
	return {"asked": "Write %s in terms of n." % VN, "lines": setup(s, rep), "answer": ans,
		"wrongs": [line_option(row.call(q, p), good, M_GAPS), line_option(row.call(p, q - p), good, M_SWAP), line_option(row.call(r, Q.new(p).sub(r)), good, M_RATIO_AS_DIFF)],
		"generic": nudged(good), "methods": {"series-formula": method(steps, ans.values)}}


# ── General terms ────────────────────────────────────────────

func u_constant_difference(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := lines_of(s, "general-difference")
	var good: Dictionary = c.back()
	var ans := form(good)
	var steps: Array = walk_lines(c) + ["This holds for every n, so the sequence is arithmetic.", say(ans)]
	return {"asked": "Prove that the sequence is arithmetic, and find %s." % GAP, "lines": setup(s, rep), "answer": ans,
		"wrongs": slip_lines(s, "general-difference", 2, good), "generic": nudged(good), "methods": {"general-difference": method(steps, ans.values)}}


func u_particular_terms(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var gap := poly([3, -9, 6 + p])
	var u1 := p + q
	var u2 := 2 * p + q
	var u3 := 3 * p + q
	var out := pick_answer("Not arithmetic: %s = %s, which changes with n." % [GAP, gap], [
		["Arithmetic: u₂ − u₁ = u₃ − u₂ = %s, so the gap is constant." % N(p), M_PARTICULAR],
		["Arithmetic: %s is %s at n = 1 and at n = 2, so it is %s for every n." % [GAP, N(p), N(p)], M_CHECK],
		["Not arithmetic: u₂/u₁ and u₃/u₂ are different.", M_WRONG_TEST]])
	var ans: Dictionary = out.answer
	out.asked = "Is uₙ an arithmetic sequence? Which line settles it?"
	out.lines = ["%s = %s, where n is a positive integer." % [UN, poly([1, -6, 11 + p, q - 6])],
		"u₁ = %s, u₂ = %s and u₃ = %s" % [N(u1), N(u2), N(u3)]]
	var steps: Array = ["Work out the gap for a general n: %s = %s" % [GAP, gap],
		"At n = 1 and n = 2 the gap is %s, but at n = 3 it is %s, so two equal gaps settle nothing." % [N(p), N(6 + p)], picked("So the line is", ans)]
	out.methods = {"general-difference": method(steps, ans.values)}
	return out


func u_term_from_sum(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := lines_of(s, "general-difference")
	var good: Dictionary = c.back()
	var ans := form(good)
	var wrongs := slip_lines(s, "general-difference", 3, good)
	wrongs.append(alt("%s = %s" % [UN, poly([s.A, s.B, 0])], M_SUM_AS_TERM))
	return {"asked": "Write %s in terms of n." % UN, "lines": setup(s, rep), "answer": ans, "wrongs": rng.shuffled(wrongs),
		"generic": nudged(good), "methods": {"general-difference": method(walk_lines(c) + [say(ans)], ans.values)}}


func u_difference_from_sum(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := lines_of(s, "general-difference")
	var a: int = s.A
	var b: int = s.B
	var d := 2 * a
	var ans := Answer.make("number", {"v": Q.new(d)}, {}, "d = ")
	ans.exact = true
	var tail := b - a
	var lines := setup(s, rep)
	lines.append("d is the common difference of the sequence.")
	var next_term := poly([d, d + tail])
	var steps: Array = ["%s = %s − %s = %s" % [UN, SN, SN1, c.back().text.trim_prefix(UN + " = ")],
		"%s = %s" % [UN1, next_term], "%s = (%s) − (%s) = %d, for every n" % [GAP, next_term, poly([d, tail]), d], say(ans)]
	return {"asked": "Find d.", "lines": lines, "answer": ans,
		"wrongs": [wrong({"v": Q.new(a)}, M_COEFF), wrong({"v": Q.new(a + b)}, M_SWAP), wrong({"v": Q.new(b)}, M_COEFF)],
		"generic": [{"v": Q.new(d + 1)}, {"v": Q.new(d - 1)}, {"v": Q.new(3 * a)}, {"v": Q.new(d + 2)}, {"v": Q.new(4 * a)}],
		"methods": {"general-difference": method(steps, ans.values)}}


# ── Arithmetic sums ──────────────────────────────────────────

func u_sum_by_formula(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := lines_of(s, "series-formula")
	var good: Dictionary = c.back()
	var ans := form(good)
	var cols := lines_of(s, "forwards-backwards")
	var by_columns: Array = ["%s: %s" % [cols[0].why, cols[0].text], "%s: %s" % [cols[1].why, cols[1].text],
		"%s: %s" % [cols[2].why, cols[2].text], "%s: %s" % [cols[3].why, cols[3].text], "%s, so %s." % [cols[4].why, Answer.text(ans)]]
	var wrongs := slip_lines(s, "series-formula", 2, good)
	return {"asked": "Write %s in terms of n." % SN, "lines": setup(s, rep), "answer": ans, "wrongs": wrongs, "generic": nudged(good),
		"methods": {"series-formula": method(walk_lines(c) + [say(ans)], ans.values), "forwards-backwards": method(by_columns, ans.values)}}


func u_pair_sum(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var f := first_of(s)
	var cols := lines_of(s, "forwards-backwards")
	var row := func(a: int, b: int) -> Dictionary: return E(["Column total"], [T("u", a, "n"), T("b", b)])
	var good: Dictionary = row.call(p, pair_tail(s))
	var ans := form(good)
	var lines := setup(s, rep)
	lines.append(cols[0].text)
	lines.append(cols[1].text)
	lines.append("The two lines are added column by column.")
	var steps: Array = ["The first column is u₁ + uₙ = %d + %s." % [f, wrapped(p, q)],
		"Each column on, the top goes up by %d and the bottom goes down by %d, so every column has the same total." % [p, p], say(ans)]
	return {"asked": "Find the total of each column.", "lines": lines, "answer": ans,
		"wrongs": [line_option(row.call(2 * p, 2 * q), good, M_LAST_TWICE), line_option(row.call(p, q), good, M_LAST_ONLY), line_option(row.call(p, q + f + p), good, M_GAPS)],
		"generic": nudged(good), "methods": {"forwards-backwards": method(steps, ans.values)}}


# ── Dots ─────────────────────────────────────────────────────

## n rows of pn + q dots, with each dot's number the layer that added it.
static func layer_rows(s: Dictionary, n: int) -> Array:
	var p: int = s.p
	var q: int = s.q
	var rows: Array = []
	for r in n:
		var row: Array = []
		for c in term_at(p, q, n):
			var k := r + 1
			while c >= term_at(p, q, k):
				k += 1
			row.append(k - 1)
		rows.append(row)
	return rows


## Two staircases of m rows, the second turned round to fill the first's gaps.
static func stair_rows(s: Dictionary) -> Array:
	var rows: Array = []
	var m: int = s.m
	for r in m:
		var row: Array = []
		for _c in term_at(s.p, s.q, r + 1):
			row.append(0)
		for _c in term_at(s.p, s.q, m - r):
			row.append(1)
		rows.append(row)
	return rows


const SHOWN_LAYERS := 4


## One of what the dots stand for: "rivet", "bottle cap".
static func thing_one(s: Dictionary) -> String:
	var t: String = s.thing
	return t.left(-2) if t.ends_with("hes") else t.trim_suffix("s")


func layer_setup(s: Dictionary, rep: String) -> Dictionary:
	var thing: String = s.thing
	var size := func(k: int) -> String: return str(term_at(s.p, s.q, k))
	var sized: String = "%s, %s and %s" % [size.call(1), size.call(2), size.call(3)]
	var fig := {"kind": "dots", "rows": layer_rows(s, SHOWN_LAYERS), "name": "Layers 1 to %d" % SHOWN_LAYERS}
	var wrap := "Each new layer of %s wraps an L shape round the rectangle before it, and adds one row." % thing
	if rep == "diagram":
		return {"lines": ["The figure shows a rectangle of %s built in %d layers, one colour for each." % [thing, SHOWN_LAYERS], wrap,
			"Layer k is the kth term of an arithmetic sequence uₖ, and Sₙ is the number of %s in the first n layers." % thing], "graph": fig}
	return {"lines": ["A scavenger lays out %s in a rectangle. After 1, 2 and 3 layers it has 1, 2 and 3 rows, and %s columns." % [thing, sized], wrap,
		"The number of %s in layer k is uₖ, and Sₙ is the number in the first n layers." % thing]}


func u_dot_total(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var row := func(a: int, b: int) -> Dictionary: return E([SN], ["n(", T("u", a, "n"), T("b", b), ")"])
	var good: Dictionary = row.call(p, q)
	var ans := form(good)
	var set_up := layer_setup(s, rep)
	var by_dots: Array = ["After n layers the rectangle has n rows and %s columns." % poly([p, q]),
		"Rows times columns counts every %s once, so the layers need no adding up." % thing_one(s), say(ans)]
	var f := p + q
	var by_formula: Array = ["u₁ = %d and d = %d, from the rectangle's sizes." % [f, 2 * p],
		"%s = (n/2)(2 × %d + (n − 1) × %d) = (n/2)(%s)" % [SN, f, 2 * p, poly([2 * p, 2 * q])], say(ans)]
	var wrongs: Array = [alt("%s = %s" % [SN, poly([2 * p, q - p])], M_LAST_AS_SUM), alt("%s = (n/2)(%s)" % [SN, poly([p, q])], M_HALF_RECT),
		line_option(row.call(p, q + p), good, M_GAPS)]
	var out := {"asked": "Write %s in terms of n." % SN, "lines": set_up.lines, "answer": ans, "wrongs": wrongs, "generic": nudged(good),
		"methods": {"dot-diagram": method(by_dots, ans.values), "series-formula": method(by_formula, ans.values)}}
	out.graph = set_up.get("graph")
	return out


func u_dot_layer(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var row := func(a: int, b: int) -> Dictionary: return E([UN], [T("u", a, "n"), T("b", b)])
	var good: Dictionary = row.call(2 * p, q - p)
	var ans := form(good)
	var set_up := layer_setup(s, rep)
	var steps: Array = ["After n layers there are n rows of %s, and after n − 1 layers there are n − 1 rows of %s." % [poly([p, q]), poly([p, q - p])],
		"Layer n is the difference: %s = n(%s) − (n − 1)(%s)" % [UN, poly([p, q]), poly([p, q - p])], say(ans)]
	var out := {"asked": "Write %s in terms of n." % UN, "lines": set_up.lines, "answer": ans,
		"wrongs": [line_option(row.call(p, q), good, M_WIDTH), line_option(row.call(2 * p, q), good, M_CORNER), line_option(row.call(2 * p, q + p), good, M_GAPS)],
		"generic": nudged(good), "methods": {"dot-diagram": method(steps, ans.values)}}
	out.graph = set_up.get("graph")
	return out


func u_dot_rectangle(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var m: int = s.m
	var f := first_of(s)
	var thing: String = s.thing
	var row := func(a: int, b: int) -> Dictionary: return E(["Width"], [T("u", a, "n"), T("b", b)])
	var good: Dictionary = row.call(p, pair_tail(s))
	var ans := form(good)
	var lines: Array = ["The figure shows two copies of a staircase of %s, for n = %d. Its rows are the terms of uₙ = %s." % [thing, m, poly([p, q])],
		"The second copy is turned round, so together they make a rectangle with n rows."]
	var steps: Array = ["The top row of the rectangle is the shortest step of one copy and the longest of the other: u₁ + uₙ.",
		"u₁ + uₙ = %d + %s" % [f, wrapped(p, q)], say(ans)]
	return {"asked": "Find the width of the rectangle for any n, in terms of n.", "lines": lines, "answer": ans,
		"wrongs": [line_option(row.call(2 * p, 2 * q), good, M_LAST_TWICE), line_option(row.call(p, q), good, M_LAST_ONLY), line_option(row.call(p, q + f + p), good, M_GAPS)],
		"generic": nudged(good), "methods": {"dot-diagram": method(steps, ans.values)},
		"graph": {"kind": "dots", "rows": stair_rows(s), "name": "n = %d" % m}}


# ── Lines of a proof ─────────────────────────────────────────

func u_missing_line(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := lines_of(s, angle)
	var hide: int = rng.pick(range(1, c.size() - 1).filter(func(i): return not c[i].v.is_empty()))
	var good: Dictionary = c[hide]
	var ans := form(good, "Line %d: " % (hide + 1))
	var lines := setup(s, rep)
	lines.append(claim_text(s))
	lines.append_array(shown(c, hide))
	var steps: Array = ["Line %d: %s" % [hide, c[hide - 1].text], "%s: %s" % [good.why, good.text],
		"Line %d follows from that: %s" % [hide + 2, c[hide + 1].text], picked("So the missing line is", ans)]
	return {"asked": "Line %d of this proof is missing. What does it say?" % (hide + 1), "lines": lines, "answer": ans,
		"wrongs": slip_lines(s, angle, hide, good, true), "generic": nudged(good), "methods": of_lines(s, steps, ans), "shown": {"hide": hide}}


## A true value at n = 1, in place of the next line: the #0 slip.
static func one_value(s: Dictionary) -> String:
	match s.fam:
		"ap-term":
			return "Try n = 1: u₂ − u₁ = %s." % N(s.p)
		"sum-term":
			return "Try n = 1: u₁ = %s." % N(s.A + s.B)
		"log-geo":
			return "Try n = 1: v₂ − v₁ = %s." % Fmt.num(s.q)
		"sum-list":
			return "Try n = 1: S₁ = %d." % first_of(s)
	return ""


func u_next_line(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := lines_of(s, angle)
	var at := rng.int_in(1, c.size() - 1)
	var good: Dictionary = c[at]
	var slips: Array = rng.shuffled(slip_lines(s, angle, at, good, true))
	var rows: Array = []
	if at < c.size() - 1:
		rows.append(["%s, because that is the result to prove." % c.back().text, M_CIRCULAR])
	if one_value(s) != "":
		rows.append([one_value(s), M_CHECK])
	rows = rng.shuffled(rows).slice(0, 1 if not slips.is_empty() else 2)
	for w in slips:
		rows.append([w.values.text, w.ref])
	for g in nudged(good):
		rows.append([g.text, ""])
	var out := pick_answer(good.text, unique_texts(rows, good.text).slice(0, 3))
	var ans: Dictionary = out.answer
	out.asked = "Which line comes next in this proof?"
	out.lines = setup(s, "equation") + [claim_text(s)] + shown(c, -1, at - 1)
	out.methods = of_lines(s, ["Line %d: %s" % [at, c[at - 1].text], "%s: %s" % [good.why, good.text], picked("So the next line is", ans)], ans)
	out.shown = {"at": at}
	return out


func u_flawed_line(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := lines_of(s, angle)
	var slip: int = rng.pick(carried(s, angle))
	var bad := lines_of(s, angle, slip)
	var at := 0
	while bad[at].text == c[at].text:
		at += 1
	var good: Dictionary = c[at]
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
	for k in range(1, slip_count(s, angle) + 1):
		var other := lines_of(s, angle, k)
		if k != slip and other.size() > at and other[at].text != good.text and other[at].text != bad[at].text and (at == 0 or other[at - 1].text == c[at - 1].text):
			wrongs.append(fix.call(at, other[at], slip_tag(s, angle, k)))
	# A later line is wrong too, but it only follows the first mistake.
	for i in range(at + 1, mini(bad.size(), c.size())):
		wrongs.append(fix.call(i, c[i]))
	for d in [1, -1, 2]:
		wrongs.append(fix.call(at, bump_line(good, d, 0)))
		wrongs.append(fix.call(at, bump_line(good, d, good.v.size() - 1)))
	var lines := setup(s, "equation")
	lines.append(claim_text(s))
	lines.append("A student's proof has one slip, carried down to the end:")
	lines.append_array(shown(bad))
	var steps: Array = []
	if at > 0:
		steps.append({1: "Line 1 is right.", 2: "Lines 1 and 2 are right."}.get(at, "Lines 1 to %d are right." % at))
	steps.append("Line %d says %s, which is not right." % [at + 1, bad[at].text])
	steps.append("%s: %s" % [good.why, good.text])
	steps.append(say(ans))
	return {"asked": "Find the first line that goes wrong, and correct it.", "lines": lines, "answer": ans, "wrongs": wrongs, "generic": [],
		"methods": of_lines(s, steps, ans), "shown": {"at": at, "slip": slip}}


## The four arguments a claim can be given: the proof first, then [text, ref] of each that isn't.
func arguments(s: Dictionary) -> Array:
	if s.fam == "ap-term":
		var c := lines_of(s, angle)
		var p: int = s.p
		return ["%s = %s = %s for every n, so the sequence is arithmetic." % [GAP, c[0].text.trim_prefix(GAP + " = "), N(p)], [
			["Try n = 1, n = 2 and n = 3: %s is %s each time, so the sequence is arithmetic." % [GAP, N(p)], M_CHECK],
			["The sequence is arithmetic, so %s is constant, so the sequence is arithmetic." % GAP, M_CIRCULAR],
			["u₂ − u₁ = u₃ − u₂ = %s, so the sequence is arithmetic." % N(p), M_PARTICULAR]]]
	if s.fam == "sum-term":
		var c := lines_of(s, angle)
		var d: int = 2 * s.A
		var term: String = c.back().text.trim_prefix(UN + " = ")
		return ["%s = %s − %s = %s for every n, so %s = %d, a constant." % [UN, SN, SN1, term, GAP, d], [
			["Try n = 1, n = 2 and n = 3: %s is %d each time, so the sequence is arithmetic." % [GAP, d], M_CHECK],
			["The sequence is arithmetic, so %s = %s, so %s is a constant, so the sequence is arithmetic." % [UN, term, GAP], M_CIRCULAR],
			["u₂ − u₁ = u₃ − u₂ = %d, so the sequence is arithmetic." % d, M_PARTICULAR]]]
	var ends: String = lines_of(s, "series-formula").back().text
	var back: String = ends.trim_prefix(SN + " = ")
	var inside: String = poly([s.p, pair_tail(s)])
	var checked := "S₁ = %d, S₂ = %d and S₃ = %d fit the formula, so it holds for every n." % [first_of(s), sum_at(s, 2), sum_at(s, 3)]
	var assumed := "Let %s. Then 2%s = n(%s), so halving gives %s." % [ends, SN, inside, back]
	var f := first_of(s)
	if angle == "forwards-backwards":
		return ["Add %s forwards and backwards: each of the n columns is %s, so 2%s = n(%s), and %s." % [SN, inside, SN, inside, ends],
			[[checked, M_CHECK], [assumed, M_CIRCULAR], ["Add %s forwards and backwards: each of the n columns is %s, so %s = n(%s)." % [SN, inside, SN, inside], M_NO_HALF]]]
	return ["%s = (n/2)(2 × %d + (n − 1) × %d) = (n/2)(%s), by the formula for an arithmetic sum." % [SN, f, s.p, inside],
		[[checked, M_CHECK], [assumed, M_CIRCULAR], ["%s = (n/2)(2 × %d + n × %d) = (n/2)(%s), by the formula for an arithmetic sum." % [SN, f, s.p, poly([s.p, 2 * f])], M_GAPS]]]


static func sum_at(s: Dictionary, n: int) -> int:
	return n * (s.p * n + pair_tail(s)) / 2


func u_valid_proof(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := arguments(s)
	var out := pick_answer(a[0], a[1])
	var ans: Dictionary = out.answer
	var c := lines_of(s, angle)
	out.asked = "Which of these is a complete proof?"
	out.lines = setup(s, "equation") + [claim_text(s)]
	var steps: Array = [c[0].text, c.back().text, "Each line holds for every n, so the proof covers every term.", picked("So the complete proof is", ans)]
	out.methods = of_lines(s, steps, ans)
	return out
