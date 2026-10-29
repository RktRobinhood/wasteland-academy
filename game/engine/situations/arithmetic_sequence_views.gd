class_name ArithmeticSequenceViews
extends RefCounted
## The views on the `arithmetic-sequence` situation: one builder per unknown of
## t1-arithmetic-sequence (curriculum/question-types.json). A builder returns the same
## fields as the quadratic ones (see quadratic_views.gd): asked, lines, table, given,
## answer, wrongs, generic and methods.
##
## Representations: "notation" (u₁ = 7,  d = 3), "terms" (7, 10, 13, 16, …), "table"
## (n against uₙ) and "words". Every answer is a whole number and is marked exactly.
##
## Paper 2 (FAL-419, papers()): in words, a savings plan in dollars and cents or a
## training plan in km, with a decimal u₁ and d, worked with a GDC. A term or a sum is
## a decimal that ends, written as money (2 d.p.) or a decimal and still marked exactly
## (the IB gives it exactly); the first term or sum over a round threshold is a whole n.
##
## `given` holds what the student is shown, as plain strings, for the SymPy checker:
## u1, d, n, un (the term uₙ for the given n), sum (Sₙ), value (a term whose n is
## asked), and terms: [[k, u_k], ...].

## n is written out even where it is the default ("sum"), so a shared situation (see
## QuestionEngine.families) never gives a sum's unknown a term's n.
const NEED := {
	"term-from-u1-d": {"n": "term"},
	"d-from-two-terms": {"n": "sum", "two_terms": true},
	"u1-from-two-terms": {"n": "sum", "two_terms": true},
	"n-from-term": {"n": "term"},
	"sum-from-u1-d": {"n": "sum"},
	"sum-from-first-last": {"n": "sum"},
	"n-from-sum": {"n": "sum", "sum_root": true},
	"d-from-sum": {"n": "sum"},
	"u1-from-sum": {"n": "sum"},
}

const SUBS := "₀₁₂₃₄₅₆₇₈₉"
## The unknowns with a Paper 2 version, asked in words.
const PAPER2 := ["term-from-u1-d", "n-from-term", "sum-from-u1-d", "n-from-sum"]
const REF := "SL1.2."


func has(unknown: String) -> bool:
	return NEED.has(unknown)


func need(unknown: String, _rep: String) -> Dictionary:
	return NEED[unknown].duplicate()


## The papers a cell can be asked on (QuestionEngine.cell_papers).
func papers(unknown: String, rep: String, _angle: String) -> Array:
	return [1, 2] if unknown in PAPER2 and rep == "words" else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng) if s.get("paper", 1) != 2 \
		else call("p2_" + unknown.replace("-", "_"), s)
	for key in ["lines", "graph", "table", "wrongs", "generic"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "generic"] else null
	out.answer.exact = true
	return out


# ── Helpers ──────────────────────────────────────────────────

static func N(v: Variant) -> String:
	return Fmt.num(v)


static func P(v: Variant) -> String:
	return Fmt.paren(v)


## A whole number written as a subscript: sub(20) is "₂₀".
static func sub(k: Variant) -> String:
	var out := ""
	for ch in str(Q.of(k).n):
		out += SUBS[int(ch)]
	return out


static func u(k: Variant) -> String:
	return "u" + sub(k)


static func S(k: Variant) -> String:
	return "S" + sub(k)


## 1st, 2nd, 3rd, 4th, 11th, 21st ...
static func nth(k: Variant) -> String:
	var n: int = Q.of(k).n
	var suffix := "th"
	if n % 100 < 11 or n % 100 > 13:
		suffix = {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")
	return str(n) + suffix


## dn + c written in n: "3n + 4", "−n + 9", "2n".
static func lin_n(dq: Q, c: Q) -> String:
	return Fmt.poly([dq, c]).replace("x", "n")


static func number(label: String, v: Q) -> Dictionary:
	return Answer.make("number", {"v": v}, {}, label)


static func wrong(v: Q, ref: String = "") -> Dictionary:
	return {"values": {"v": v}, "ref": REF + ref if ref != "" else ""}


static func gen(vs: Array) -> Array:
	return vs.map(func(v): return {"v": v})


static func res(v: Q) -> Dictionary:
	return {"v": v}


## "a + k × d" for a term worked out from another: "7 + 19 × 3", "7 + 19 × (−3)".
static func step_from(a: Q, k: int, dq: Q) -> String:
	return "%s + %d × %s" % [N(a), k, P(dq)]


static func terms_line(s: Dictionary) -> String:
	return ", ".join(s.us.map(func(e): return N(e))) + ", …"


static func terms_table(ns: Array, us: Array) -> Dictionary:
	return {"xs": ns.duplicate(), "ys": us.duplicate(), "heads": ["n", "uₙ"]}


static func pairs(ks: Array, vs: Array) -> Array:
	var out: Array = []
	for i in ks.size():
		out.append([Q.of(ks[i]).key(), Q.of(vs[i]).key()])
	return out


## Shows u₁ and d in a representation. Sets lines, table and given on `out`, and
## returns {"intro": text before the question, "read": steps that read u₁ and d}.
static func show_u1_d(rep: String, s: Dictionary, out: Dictionary, extra: String = "") -> Dictionary:
	var read: Array = []
	var intro := ""
	match rep:
		"notation":
			out.lines = ["u₁ = %s,  d = %s%s" % [N(s.u1), N(s.d), extra]]
			out.given = {"u1": s.u1.key(), "d": s.d.key()}
			intro = "An arithmetic sequence has the values shown."
		"terms", "table":
			if rep == "terms":
				out.lines = [terms_line(s)]
				intro = "These are the first four terms of an arithmetic sequence."
			else:
				out.table = terms_table(s.ns, s.us)
				intro = "The table shows the first four terms of an arithmetic sequence."
			out.given = {"terms": pairs(s.ns, s.us)}
			read.append("u₁ = %s, and d = u₂ − u₁ = %s − %s = %s." % [N(s.u1), N(s.us[1]), P(s.u1), N(s.d)])
		"words":
			out.lines = ["The first term of an arithmetic sequence is %s and the common difference is %s." % [N(s.u1), N(s.d)]]
			out.given = {"u1": s.u1.key(), "d": s.d.key()}
	return {"intro": intro, "read": read}


static func ask(intro: String, question: String) -> String:
	return (intro + " " + question) if intro != "" else question


# ── t1-arithmetic-sequence ───────────────────────────────────

func u_term_from_u1_d(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n.n
	var ans := number(u(n) + " = ", s.un)
	var out := {"answer": ans}
	var sh := show_u1_d(rep, s, out)
	out.given.n = s.n.key()
	out.asked = ask(sh.intro, "Find the %s term, %s." % [nth(n), u(n)] if rep == "words" else "Find %s." % u(n))
	var jump: Q = s.d.mul(n - 1)
	var v: Q = s.u1.add(jump)
	var formula: Array = sh.read.duplicate()
	formula.append_array([
		"uₙ = u₁ + (n − 1)d",
		"%s = %s = %s%s = %s" % [u(n), step_from(s.u1, n - 1, s.d), N(s.u1), Fmt.plus(jump), N(v)],
		"So %s." % Answer.text(ans, res(v))])
	var c: Q = s.u1.sub(s.d)
	var w: Q = s.d.mul(n).add(c)
	var linear: Array = sh.read.duplicate()
	linear.append_array([
		"uₙ = u₁ + (n − 1)d = %s + %s(n − 1) = %s" % [N(s.u1), P(s.d), lin_n(s.d, c)],
		"%s = %s × %d%s = %s" % [u(n), N(s.d), n, Fmt.plus(c), N(w)],
		"So %s." % Answer.text(ans, res(w))])
	out.methods = {"nth-formula": {"steps": formula, "result": res(v)}, "linear-function": {"steps": linear, "result": res(w)}}
	out.wrongs = [wrong(s.u1.add(s.d.mul(n)), "nth-term#0"), wrong(s.n, "nth-term#2")]
	if rep in ["terms", "table"]:
		out.wrongs.append(wrong(s.u1.sub(jump), "nth-term#1"))
	out.generic = gen([jump, s.d.mul(n), s.un.sub(s.d.mul(2))])
	return out


## Shows two terms u_p and u_q. Sets lines, table and given; returns the intro.
static func show_two(rep: String, s: Dictionary, out: Dictionary) -> String:
	out.given = {"terms": pairs([s.p, s.q], [s.up, s.uq])}
	match rep:
		"notation":
			out.lines = ["%s = %s,  %s = %s" % [u(s.p), N(s.up), u(s.q), N(s.uq)]]
			return "An arithmetic sequence has the two terms shown."
		"table":
			out.table = terms_table([s.p, s.q], [s.up, s.uq])
			return "The table shows two terms of an arithmetic sequence."
	out.lines = ["The %s term of an arithmetic sequence is %s and the %s term is %s." % [nth(s.p), N(s.up), nth(s.q), N(s.uq)]]
	return ""


func u_d_from_two_terms(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := number("d = ", s.d)
	var out := {"answer": ans}
	var intro := show_two(rep, s, out)
	out.asked = ask(intro, "Find the common difference d.")
	var gaps: int = s.q.n - s.p.n
	var rise: Q = s.uq.sub(s.up)
	var dv := rise.div(gaps)
	out.methods = {
		"gap-count": {"result": res(dv), "steps": [
			"From %s to %s is %d − %d = %d steps of d." % [u(s.p), u(s.q), s.q.n, s.p.n, gaps],
			"d = (%s − %s)/%d = %s/%d = %s" % [N(s.uq), P(s.up), gaps, N(rise), gaps, N(dv)],
			"So %s." % Answer.text(ans, res(dv))]},
		"simultaneous": {"result": res(dv), "steps": [
			"%s = u₁ + %dd = %s" % [u(s.p), s.p.n - 1, N(s.up)],
			"%s = u₁ + %dd = %s" % [u(s.q), s.q.n - 1, N(s.uq)],
			"Subtract the first from the second: %dd = %s" % [gaps, N(rise)],
			"So %s." % Answer.text(ans, res(dv))]},
	}
	out.wrongs = [wrong(rise.div(gaps + 1), "find-u1-d#0"), wrong(s.d.neg(), "nth-term#1")]
	out.generic = gen([rise, rise.div(s.q), s.d.mul(2)])
	return out


func u_u1_from_two_terms(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := number("u₁ = ", s.u1)
	var out := {"answer": ans}
	var intro := show_two(rep, s, out)
	out.asked = ask(intro, "Find the first term u₁.")
	var gaps: int = s.q.n - s.p.n
	var rise: Q = s.uq.sub(s.up)
	var dv := rise.div(gaps)
	var back: int = s.p.n - 1
	var v: Q = s.up.sub(dv.mul(back))
	out.methods = {
		"gap-count": {"result": res(v), "steps": [
			"From %s to %s is %d steps, so d = (%s − %s)/%d = %s." % [u(s.p), u(s.q), gaps, N(s.uq), P(s.up), gaps, N(dv)],
			"From %s back to u₁ is %d steps: u₁ = %s − %d × %s = %s" % [u(s.p), back, N(s.up), back, P(dv), N(v)],
			"So %s." % Answer.text(ans, res(v))]},
		"simultaneous": {"result": res(v), "steps": [
			"%s = u₁ + %dd = %s" % [u(s.p), back, N(s.up)],
			"%s = u₁ + %dd = %s" % [u(s.q), s.q.n - 1, N(s.uq)],
			"Subtract the first from the second: %dd = %s, so d = %s" % [gaps, N(rise), N(dv)],
			"u₁ = %s − %d × %s = %s" % [N(s.up), back, P(dv), N(v)],
			"So %s." % Answer.text(ans, res(v))]},
	}
	var d_wrong := rise.div(gaps + 1)
	out.wrongs = [wrong(s.up, "find-u1-d#1"), wrong(s.up.sub(s.d.mul(s.p)), "nth-term#0"),
		wrong(s.up.sub(d_wrong.mul(back)), "find-u1-d#0")]
	out.generic = gen([s.up.sub(s.d), s.u1.neg(), s.d])
	return out


func u_n_from_term(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := number("n = ", s.n)
	var out := {"answer": ans}
	var sh := show_u1_d(rep, s, out, ",  uₙ = %s" % N(s.un))
	out.given.value = s.un.key()
	match rep:
		"notation":
			out.asked = ask(sh.intro, "Find n.")
		"words":
			out.lines[0] += " One of its terms is %s." % N(s.un)
			out.asked = "Which term of the sequence is %s? Find n." % N(s.un)
		_:
			out.asked = ask(sh.intro, "Which term of the sequence is %s? Find n." % N(s.un))
	var rise: Q = s.un.sub(s.u1)
	var steps := rise.div(s.d)
	var v := steps.add(1)
	var solve: Array = sh.read.duplicate()
	solve.append_array([
		"uₙ = u₁ + (n − 1)d = %s" % N(s.un),
		"%s + (n − 1) × %s = %s" % [N(s.u1), P(s.d), N(s.un)],
		"(n − 1) × %s = %s" % [P(s.d), N(rise)],
		"n − 1 = %s" % N(steps),
		"So %s." % Answer.text(ans, res(v))])
	var count: Array = sh.read.duplicate()
	count.append_array([
		"From %s to %s is %s − %s = %s." % [N(s.u1), N(s.un), N(s.un), P(s.u1), N(rise)],
		"Each step adds %s, so that is %s/%s = %s steps." % [N(s.d), N(rise), P(s.d), N(steps)],
		"%s steps after the first term is term %s + 1, so %s." % [N(steps), N(steps), Answer.text(ans, res(v))]])
	out.methods = {"solve-linear": {"steps": solve, "result": res(v)}, "count-steps": {"steps": count, "result": res(v)}}
	out.wrongs = [wrong(steps, "find-n#2"), wrong(s.un, "find-n#1")]
	out.generic = gen([v.add(1), s.un.div(s.d), s.un.add(s.u1).div(s.d)])
	return out


func u_sum_from_u1_d(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n.n
	var ans := number(S(n) + " = ", s.sn)
	var out := {"answer": ans}
	var sh := show_u1_d(rep, s, out)
	out.given.n = s.n.key()
	out.asked = ask(sh.intro, "Find %s, the sum of the first %d terms." % [S(n), n])
	var inner: Q = s.u1.mul(2).add(s.d.mul(n - 1))
	var v: Q = Q.new(n, 2).mul(inner)
	var fd: Array = sh.read.duplicate()
	fd.append_array([
		"Sₙ = n/2 (2u₁ + (n − 1)d)",
		"%s = %s × (2 × %s + %d × %s) = %s × %s = %s" % [S(n), half(n), P(s.u1), n - 1, P(s.d), half(n), P(inner), N(v)],
		"So %s." % Answer.text(ans, res(v))])
	var last: Q = s.u1.add(s.d.mul(n - 1))
	var w: Q = Q.new(n, 2).mul(s.u1.add(last))
	var fl: Array = sh.read.duplicate()
	fl.append_array([
		"%s = %s = %s" % [u(n), step_from(s.u1, n - 1, s.d), N(last)],
		"Sₙ = n/2 (u₁ + uₙ)",
		"%s = %s × (%s + %s) = %s × %s = %s" % [S(n), half(n), N(s.u1), P(last), half(n), P(s.u1.add(last)), N(w)],
		"So %s." % Answer.text(ans, res(w))])
	out.methods = {"formula-d": {"steps": fd, "result": res(v)}, "formula-last": {"steps": fl, "result": res(w)}}
	out.wrongs = [wrong(Q.new(n, 2).mul(s.u1.mul(2).add(s.d.mul(n))), "sum#0"),
		wrong(ArithmeticSequenceSituation.sum(s, n - 1), "sum#1"), wrong(s.un, "sum#2")]
	out.generic = gen([s.sn.mul(2), ArithmeticSequenceSituation.sum(s, n + 1), s.un.mul(n)])
	return out


## n/2 as shown in working: "10" for n = 20, "21/2" for n = 21.
static func half(n: int) -> String:
	return N(Q.new(n, 2))


func u_sum_from_first_last(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n.n
	var ans := number(S(n) + " = ", s.sn)
	var out := {"answer": ans, "given": {"u1": s.u1.key(), "n": s.n.key(), "un": s.un.key()}}
	if rep == "notation":
		out.lines = ["u₁ = %s,  %s = %s" % [N(s.u1), u(n), N(s.un)]]
		out.asked = "An arithmetic sequence has the first term and the %s term shown. Find %s, the sum of the first %d terms." % [nth(n), S(n), n]
	else:
		out.lines = ["The first term of an arithmetic sequence is %s and the %s term is %s." % [N(s.u1), nth(n), N(s.un)]]
		out.asked = "Find %s, the sum of the first %d terms." % [S(n), n]
	var pair: Q = s.u1.add(s.un)
	var v: Q = Q.new(n, 2).mul(pair)
	out.methods = {
		"formula-last": {"result": res(v), "steps": [
			"Sₙ = n/2 (u₁ + uₙ)",
			"%s = %s × (%s + %s) = %s × %s = %s" % [S(n), half(n), N(s.u1), P(s.un), half(n), P(pair), N(v)],
			"So %s." % Answer.text(ans, res(v))]},
		"gauss-pairing": {"result": res(v), "steps": [
			"Write %s forwards and backwards, and add the two lines term by term." % S(n),
			"Each of the %d columns adds to u₁ + %s = %s + %s = %s." % [n, u(n), N(s.u1), P(s.un), N(pair)],
			"2%s = %d × %s = %s" % [S(n), n, P(pair), N(pair.mul(n))],
			"So %s." % Answer.text(ans, res(v))]},
	}
	out.wrongs = [wrong(Q.new(n - 1, 2).mul(pair), "sum#1")]
	out.generic = gen([pair.mul(n), pair, Q.new(n, 2).mul(s.un.sub(s.u1))])
	return out


func u_n_from_sum(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := number("n = ", s.n)
	var out := {"answer": ans}
	var sh := show_u1_d(rep, s, out, ",  Sₙ = %s" % N(s.sn))
	out.given.sum = s.sn.key()
	match rep:
		"notation":
			out.asked = ask(sh.intro, "Sₙ is the sum of the first n terms. Find n.")
		"words":
			out.lines[0] += " The sum of its first n terms is %s." % N(s.sn)
			out.asked = "Find n."
		_:
			out.asked = ask(sh.intro, "The sum of the first n terms is %s. Find n." % N(s.sn))
	var b: Q = s.u1.mul(2).sub(s.d)
	var two_s: Q = s.sn.mul(2)
	var sg: Q = Q.new(s.d.sign())
	var k: Q = s.d.abs_q()
	var root: Q = s.n
	var other: Q = s.other
	var st: Array = sh.read.duplicate()
	st.append_array([
		"Sₙ = n/2 (2u₁ + (n − 1)d) = %s" % N(s.sn),
		"%s = n/2 (2 × %s + (n − 1) × %s)" % [N(s.sn), P(s.u1), P(s.d)],
		"Multiply by 2: %s = n(%s)" % [N(two_s), lin_n(s.d, b)],
		"%s = 0" % Fmt.poly([k, b.mul(sg), two_s.neg().mul(sg)]).replace("x", "n"),
		"%s%s%s = 0" % [Fmt.lead(k), Fmt.factor(root).replace("x", "n"), Fmt.factor(other).replace("x", "n")],
		"n = %s or n = %s" % [N(root), N(other)],
		"n counts terms, so it is a positive whole number. So %s." % Answer.text(ans, res(root))])
	out.methods = {"quadratic-in-n": {"steps": st, "result": res(root)}}
	out.wrongs = [wrong(other, "sum-unknown#1"), wrong(s.sn, "sum-unknown#2")]
	out.generic = gen([root.sub(1), root.add(1), root.mul(2)])
	return out


func u_d_from_sum(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n.n
	var ans := number("d = ", s.d)
	var out := {"answer": ans, "given": {"u1": s.u1.key(), "n": s.n.key(), "sum": s.sn.key()}}
	if rep == "notation":
		out.lines = ["u₁ = %s,  %s = %s" % [N(s.u1), S(n), N(s.sn)]]
		out.asked = "An arithmetic sequence has the first term and the sum of its first %d terms shown. Find the common difference d." % n
	else:
		out.lines = ["The first term of an arithmetic sequence is %s and the sum of its first %d terms is %s." % [N(s.u1), n, N(s.sn)]]
		out.asked = "Find the common difference d."
	var mean2: Q = s.sn.mul(2).div(n)   # 2Sₙ/n = 2u₁ + (n − 1)d = u₁ + uₙ
	var rest: Q = mean2.sub(s.u1.mul(2))
	var v := rest.div(n - 1)
	var last: Q = mean2.sub(s.u1)
	var w := last.sub(s.u1).div(n - 1)
	out.methods = {
		"linear-unknowns": {"result": res(v), "steps": [
			"%s = %s (2 × %s + %dd) = %s" % [S(n), half(n), P(s.u1), n - 1, N(s.sn)],
			"2 × %s + %dd = 2 × %s/%d = %s" % [P(s.u1), n - 1, P(s.sn), n, N(mean2)],
			"%dd = %s%s = %s" % [n - 1, N(mean2), Fmt.plus(s.u1.mul(-2)), N(rest)],
			"So %s." % Answer.text(ans, res(v))]},
		"formula-last": {"result": res(w), "steps": [
			"%s = %s (u₁ + %s) = %s, so u₁ + %s = 2 × %s/%d = %s" % [S(n), half(n), u(n), N(s.sn), u(n), P(s.sn), n, N(mean2)],
			"%s = %s − %s = %s" % [u(n), N(mean2), P(s.u1), N(last)],
			"%s = u₁ + %dd, so %dd = %s − %s = %s" % [u(n), n - 1, n - 1, N(last), P(s.u1), N(last.sub(s.u1))],
			"So %s." % Answer.text(ans, res(w))]},
	}
	out.wrongs = [wrong(rest.div(n), "sum#0")]
	# (n − 1)d left undivided, the sign of d flipped, one more
	out.generic = gen([rest, s.d.neg(), s.d.add(1)])
	return out


func u_u1_from_sum(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n.n
	var ans := number("u₁ = ", s.u1)
	var out := {"answer": ans, "given": {"d": s.d.key(), "n": s.n.key(), "sum": s.sn.key()}}
	if rep == "notation":
		out.lines = ["d = %s,  %s = %s" % [N(s.d), S(n), N(s.sn)]]
		out.asked = "An arithmetic sequence has the common difference and the sum of its first %d terms shown. Find the first term u₁." % n
	else:
		out.lines = ["The common difference of an arithmetic sequence is %s and the sum of its first %d terms is %s." % [N(s.d), n, N(s.sn)]]
		out.asked = "Find the first term u₁."
	var mean2: Q = s.sn.mul(2).div(n)
	var jump: Q = s.d.mul(n - 1)
	var v := mean2.sub(jump).div(2)
	out.methods = {
		"linear-unknowns": {"result": res(v), "steps": [
			"%s = %s (2u₁ + %d × %s) = %s" % [S(n), half(n), n - 1, P(s.d), N(s.sn)],
			"2u₁%s = 2 × %s/%d = %s" % [Fmt.plus(jump), P(s.sn), n, N(mean2)],
			"2u₁ = %s" % N(mean2.sub(jump)),
			"So %s." % Answer.text(ans, res(v))]},
		"formula-last": {"result": res(v), "steps": [
			"%s = %s (u₁ + %s) = %s, so u₁ + %s = 2 × %s/%d = %s" % [S(n), half(n), u(n), N(s.sn), u(n), P(s.sn), n, N(mean2)],
			"%s − u₁ = %dd = %d × %s = %s" % [u(n), n - 1, n - 1, P(s.d), N(jump)],
			"Subtract the second from the first: 2u₁ = %s − %s = %s" % [N(mean2), P(jump), N(mean2.sub(jump))],
			"So %s." % Answer.text(ans, res(v))]},
	}
	out.wrongs = [wrong(mean2.sub(s.d.mul(n)).div(2), "sum#0")]
	# 2u₁ not halved, the mean term Sₙ/n, one step on
	out.generic = gen([mean2.sub(jump), s.sn.div(n), s.u1.add(s.d)])
	return out


# ── Paper 2 (FAL-419) ────────────────────────────────────────
# A context in words with a decimal u₁ and d. The words name the person, the period
# (week or day) and the unit; the SymPy checker reads u₁ and d back from them.

const CTX := {
	"money": {"who": "Ana", "she": "she", "her": "her", "per": "week",
		"intro": "Ana saves $%s in the first week of a savings plan, and each week after that she saves $%s more than the week before."},
	"km": {"who": "Ben", "she": "he", "her": "his", "per": "day",
		"intro": "Ben runs %s km on the first day of his training plan, and each day after that he runs %s km more than the day before."},
}


## An amount as the context writes it: "12.40" (dollars) or "3.6" (km).
static func V(s: Dictionary, v: Variant) -> String:
	return Fmt.money(v) if s.ctx == "money" else Fmt.dec(v)


## With its unit: "$12.40", "3.6 km".
static func VU(s: Dictionary, v: Variant) -> String:
	return ("$" + V(s, v)) if s.ctx == "money" else V(s, v) + " km"


## An amount answer: money to 2 d.p. or a decimal in km, marked exactly.
static func amount(s: Dictionary, label: String, v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label + ("$" if s.ctx == "money" else ""), "" if s.ctx == "money" else " km")
	ans.show = "money" if s.ctx == "money" else "dec"
	return ans


## A whole n, written as a decimal so a wrong option such as a root shows as 22.7.
static func count(v: Q) -> Dictionary:
	var ans := number("n = ", v)
	ans.show = "dec"
	return ans


## A value to 3 s.f., as an exact decimal (a wrong option).
static func q3(x: float) -> Q:
	return Answer.parse_number(Fmt.sf(x).replace("−", "-")).q


static func p2_out(s: Dictionary, ans: Dictionary, asked: String) -> Dictionary:
	return {"answer": ans, "asked": asked, "lines": [CTX[s.ctx].intro % [V(s, s.u1), V(s, s.d)]],
		"given": {"u1": s.u1.key(), "d": s.d.key(), "ctx": s.ctx}}


static func p2_read(s: Dictionary) -> String:
	return "u₁ = %s and d = %s, in %s." % [V(s, s.u1), V(s, s.d), "dollars" if s.ctx == "money" else "km"]


## An amount as it would be written: money to the nearest cent (a wrong sum such as
## n/2 (2u₁ + nd) can end in half a cent).
static func cent(s: Dictionary, v: Q) -> Q:
	if s.ctx != "money":
		return v
	var w := v.mul(100).add(Q.new(1, 2))
	return Q.new(w.n / w.d, 100)


## Only positive amounts are offered, each as it would be written.
static func positive(s: Dictionary, vs: Array) -> Array:
	return gen(vs.filter(func(v): return v.sign() > 0).map(func(v): return cent(s, v)))


func p2_term_from_u1_d(s: Dictionary) -> Dictionary:
	var c: Dictionary = CTX[s.ctx]
	var n: int = s.n.n
	var ans := amount(s, u(n) + " = ", s.un)
	var asked := ("How much does %s save in week %d?" if s.ctx == "money" else "How far does %s run on day %d?") % [c.she, n]
	var out := p2_out(s, ans, asked)
	out.given.n = s.n.key()
	var jump: Q = s.d.mul(n - 1)
	var c0: Q = s.u1.sub(s.d)
	var final := "So %s." % Answer.text(ans)
	out.methods = {
		"nth-formula": {"result": res(s.un), "steps": [p2_read(s), "uₙ = u₁ + (n − 1)d, and %s %d is %s." % [c.per, n, u(n)],
			"With a GDC: %s = %s + %d × %s = %s" % [u(n), V(s, s.u1), n - 1, V(s, s.d), V(s, s.un)], final]},
		"linear-function": {"result": res(s.un), "steps": [p2_read(s),
			"uₙ = %s + %s(n − 1) = %sn + %s" % [V(s, s.u1), V(s, s.d), V(s, s.d), V(s, c0)],
			"With a GDC: %s = %s × %d + %s = %s" % [u(n), V(s, s.d), n, V(s, c0), V(s, s.un)], final]},
	}
	out.wrongs = [wrong(s.u1.add(s.d.mul(n)), "nth-term#0"), wrong(s.n, "nth-term#2")]
	out.generic = positive(s, [jump, s.d.mul(n), s.un.sub(s.d.mul(2))])
	return out


func p2_sum_from_u1_d(s: Dictionary) -> Dictionary:
	var c: Dictionary = CTX[s.ctx]
	var n: int = s.n.n
	var ans := amount(s, S(n) + " = ", s.sn)
	var asked := ("How much has %s saved in total after %d weeks?" if s.ctx == "money" else "How far has %s run in total after %d days?") % [c.she, n]
	var out := p2_out(s, ans, asked)
	out.given.n = s.n.key()
	var inner: Q = s.u1.mul(2).add(s.d.mul(n - 1))
	var final := "So %s." % Answer.text(ans)
	out.methods = {
		"formula-d": {"result": res(s.sn), "steps": [p2_read(s) + " After %d %ss is %s." % [n, c.per, S(n)], "Sₙ = n/2 (2u₁ + (n − 1)d)",
			"With a GDC: %s = %s × (2 × %s + %d × %s) = %s × %s = %s" % [S(n), half(n), V(s, s.u1), n - 1, V(s, s.d), half(n), V(s, inner), V(s, s.sn)], final]},
		"formula-last": {"result": res(s.sn), "steps": [p2_read(s) + " %s = %s + %d × %s = %s" % [u(n), V(s, s.u1), n - 1, V(s, s.d), V(s, s.un)],
			"Sₙ = n/2 (u₁ + uₙ)",
			"With a GDC: %s = %s × (%s + %s) = %s" % [S(n), half(n), V(s, s.u1), V(s, s.un), V(s, s.sn)], final]},
	}
	out.wrongs = [wrong(cent(s, Q.new(n, 2).mul(s.u1.mul(2).add(s.d.mul(n)))), "sum#0"),
		wrong(ArithmeticSequenceSituation.sum(s, n - 1), "sum#1"), wrong(s.un, "sum#2")]
	out.generic = positive(s, [s.sn.mul(2), ArithmeticSequenceSituation.sum(s, n + 1), s.un.mul(n)])
	return out


func p2_n_from_term(s: Dictionary) -> Dictionary:
	var c: Dictionary = CTX[s.ctx]
	var y: Q = s.Y
	var ans := count(s.n)
	var asked := ("In which week n does %s first save more than %s?" if s.ctx == "money" else "On which day n does %s first run more than %s?") % [c.she, VU(s, y)]
	var out := p2_out(s, ans, asked)
	out.given.over = y.key()
	var rise: Q = y.sub(s.u1)
	var steps: float = rise.to_float() / s.d.to_float()
	var whole: int = s.n.n - 1
	var final := "So %s." % Answer.text(ans)
	out.methods = {
		"solve-linear": {"result": res(s.n), "steps": [
			"uₙ = %s + (n − 1) × %s > %s" % [V(s, s.u1), V(s, s.d), V(s, y)],
			"With a GDC: n − 1 > (%s − %s)/%s = %s" % [V(s, y), V(s, s.u1), V(s, s.d), Fmt.sf(steps, 6)],
			"n > %s, and n is a whole number of %ss, so it is the next whole number." % [Fmt.sf(steps + 1.0, 6), c.per], final]},
		"count-steps": {"result": res(s.n), "steps": [
			"From %s to %s is %s − %s = %s." % [V(s, s.u1), V(s, y), V(s, y), V(s, s.u1), V(s, rise)],
			"Each step adds %s: %s/%s = %s on a GDC, so %d whole steps are needed to pass %s." % [V(s, s.d), V(s, rise), V(s, s.d), Fmt.sf(steps, 6), whole, V(s, y)],
			"%d steps after the first term is term %d + 1. %s" % [whole, whole, final]]},
	}
	out.wrongs = [wrong(Q.new(whole), "find-n#2"), wrong(y, "find-n#1")]
	out.generic = gen([s.n.add(1), q3(steps + 1.0)])
	return out


func p2_n_from_sum(s: Dictionary) -> Dictionary:
	var c: Dictionary = CTX[s.ctx]
	var x: Q = s.X
	var n: int = s.n.n
	var ans := count(s.n)
	var asked := ("After how many weeks n is %s total saved first more than %s?" if s.ctx == "money" \
		else "After how many days n is %s total distance first more than %s?") % [c.her, VU(s, x)]
	var out := p2_out(s, ans, asked)
	out.given.over_sum = x.key()
	var r := ArithmeticSequenceSituation.sum_root(s, x)
	var neg := ArithmeticSequenceSituation.sum_root(s, x, false)
	var before := ArithmeticSequenceSituation.sum(s, n - 1)
	out.methods = {"quadratic-in-n": {"result": res(s.n), "steps": [
		"Sₙ = n/2 (2 × %s + (n − 1) × %s) > %s" % [V(s, s.u1), V(s, s.d), V(s, x)],
		"With a GDC, solve n/2 (2 × %s + (n − 1) × %s) = %s: n = %s or n = %s" % [V(s, s.u1), V(s, s.d), V(s, x), Fmt.sf(r, 6), Fmt.sf(neg, 6)],
		"n counts %ss, so it is positive, and Sₙ grows with n: the sum first passes %s at the next whole number." % [c.per, V(s, x)],
		"A table of Sₙ on the GDC checks it: %s = %s and %s = %s. So %s." % [S(n - 1), V(s, before), S(n), V(s, s.sn), Answer.text(ans)]]}}
	out.wrongs = [wrong(q3(neg), "sum-unknown#1"), wrong(x, "sum-unknown#2")]
	out.generic = gen([Q.new(n - 1), q3(r), s.n.add(1)])
	return out
