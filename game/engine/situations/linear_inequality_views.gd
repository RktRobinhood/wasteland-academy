class_name LinearInequalityViews
extends ExtensionViews
## The views on the `fn-pre-linear-inequalities` situation: one builder per unknown of
## fn-pre-linear-inequalities (FAL-459). A one-sided answer is the bound kind (x ≤ 3), a
## two-sided one range2 (−2 < x ≤ 4), and the graph is a number line (ui/plot_view.gd).

const REF_KEEP_SIGN := "fn-pre-linear-inequalities#0"
const REF_CIRCLES := "fn-pre-linear-inequalities#1"
const REF_MIDDLE_ONLY := "fn-pre-linear-inequalities#2"
const FLIP := LinearInequalitySituation.FLIP
const STRICT := {"<": "≤", "≤": "<", ">": "≥", "≥": ">"}
const WORDS := {"<": "is less than", "≤": "is at most", ">": "is more than", "≥": "is at least"}


func needs() -> Dictionary:
	return {
		"one-sided": {"form": "one"},
		"two-sided": {"form": "two"},
		"read-number-line": {"form": "line"},
		"count-integers": {"form": "count"},
	}


func extra() -> Dictionary:
	return {"two-sided": ["error-spot"]}


# ── Helpers ──────────────────────────────────────────────────

static func lin(a: Q, b: Q) -> String:
	return Fmt.poly([a, b])


static func bound(rel: String, v: Q) -> Dictionary:
	return Answer.make("bound", {"rel": rel, "v": v}, {"var": "x"})


static func range2(lo: Q, r1: String, r2: String, hi: Q) -> Dictionary:
	return Answer.make("range2", {"lo": lo, "r1": r1, "r2": r2, "hi": hi}, {"var": "x"})


static func r2v(lo: Q, r1: String, r2: String, hi: Q) -> Dictionary:
	return {"lo": lo, "r1": r1, "r2": r2, "hi": hi}


## Taking v away from a place: "Subtract 2 from", "Add 2 to" (for v = −2).
static func take(v: Q, place: String) -> String:
	return ("Subtract %s from " if v.sign() > 0 else "Add %s to ") % v.abs_q().text() + place


static func two_line(s: Dictionary) -> String:
	return "%s %s %s %s %s" % [N(s.c1), s.rel1, lin(s.a, s.b), s.rel2, N(s.c2)]


## "3 times a number x, plus 4, is less than 19." / "4 minus 3 times a number x is at least −8."
static func words_one(s: Dictionary) -> String:
	if s.a.sign() > 0:
		return "%s times a number x, %s %s, %s %s." % [N(s.a), "plus" if s.b.sign() > 0 else "minus", s.b.abs_q().text(), WORDS[s.rel], N(s.c)]
	return "%s minus %s times a number x %s %s." % [N(s.b), s.a.abs_q().text(), WORDS[s.rel], N(s.c)]


static func words_shown(s: Dictionary) -> String:
	if s.a.sign() > 0:
		return lin(s.a, s.b)
	return "%s − %sx" % [N(s.b), Fmt.lead(s.a.abs_q())]


## "x = 4: 3(4) + 1 = 13, which is more than 10, so it fits."
static func test_point(s: Dictionary, x: Q, lhs: Q, rel: String, rhs: Q) -> String:
	var ok := _holds(lhs, rel, rhs)
	return "x = %s: %s(%s)%s = %s, %s %s %s is %s" % [N(x), N(s.a), N(x), Fmt.plus(s.b), N(lhs), N(lhs), rel, N(rhs), "true" if ok else "false"]


static func _holds(l: Q, rel: String, r: Q) -> bool:
	match rel:
		"<":
			return l.lt(r)
		"≤":
			return l.lt(r) or l.eq(r)
		">":
			return r.lt(l)
	return r.lt(l) or l.eq(r)


static func numberline(s: Dictionary) -> Dictionary:
	if s.sided == "one":
		var up: bool = s.sol_rel in [">", "≥"]
		return {"kind": "numberline", "x0": s.v.n - 5, "x1": s.v.n + 5, "marks": [{"at": s.v.to_float(), "open": s.sol_rel in ["<", ">"]}],
			"segment": {"from": s.v.to_float() if up else null, "to": null if up else s.v.to_float()}}
	return {"kind": "numberline", "x0": s.lo.n - 3, "x1": s.hi.n + 3,
		"marks": [{"at": s.lo.to_float(), "open": s.r1 == "<"}, {"at": s.hi.to_float(), "open": s.r2 == "<"}],
		"segment": {"from": s.lo.to_float(), "to": s.hi.to_float()}}


# ── fn-pre-linear-inequalities ───────────────────────────────

func u_one_sided(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := bound(s.sol_rel, s.v)
	var final := "So %s." % Answer.text(ans)
	var neg: bool = s.a.sign() < 0
	var shown := "%s %s %s" % [lin(s.a, s.b), s.rel, N(s.c)]
	var out := {"asked": "Solve the inequality.", "lines": [shown], "given": {"form": "one", "a": s.a.key(), "b": s.b.key(), "rel": s.rel, "c": s.c.key()}, "answer": ans}
	if rep == "words":
		out.lines = [words_one(s)]
		out.asked = "Write an inequality for x and solve it."
	var cb: Q = s.c.sub(s.b)
	var move := "%s: %s %s %s" % [take(s.b, "both sides"), Fmt.term(s.a, 1, true), s.rel, N(cb)]
	var divide := "Divide both sides by %s%s: x %s %s" % [N(s.a), ", a negative number, so the sign turns round" if neg else "", s.sol_rel, N(s.v)]
	var ms := {"inverse-operations": method([move, divide, final], ans.values)}
	if neg:
		var bc: Q = s.b.sub(s.c)
		ms["keep-x-positive"] = method(["Add %s to both sides, so x has a positive coefficient: %s %s %s%s" % [Fmt.term(s.a.abs_q(), 1, true), N(s.b), s.rel, Fmt.term(s.a.abs_q(), 1, true), Fmt.plus(s.c)],
			"%s: %s %s %s" % [take(s.c, "both sides"), N(bc), s.rel, Fmt.term(s.a.abs_q(), 1, true)],
			"Divide by %s, which is positive, so the sign stays: %s %s x" % [s.a.abs_q().text(), N(s.v), s.rel], final], ans.values)
	else:
		ms["keep-x-positive"] = method(["The x term %s is already positive. %s" % [Fmt.term(s.a, 1, true), move], divide, final], ans.values)
	var t: Q = s.v.add(1)
	ms["test-value"] = method(["The boundary: %s = %s when x = %s" % [lin(s.a, s.b), N(s.c), N(s.v)],
		"Test " + test_point(s, t, s.a.mul(t).add(s.b), s.rel, s.c),
		"So the solution is on the %s side of %s, and %s itself is %s" % ["upper" if s.sol_rel in [">", "≥"] else "lower", N(s.v), N(s.v), "included" if s.rel in ["≤", "≥"] else "left out"],
		final], ans.values)
	out.methods = ms
	if neg:
		out.wrongs = [wrong({"rel": s.rel, "v": s.v}, REF_KEEP_SIGN)]
	out.generic = [{"rel": STRICT[s.sol_rel], "v": s.v}, {"rel": FLIP[s.sol_rel], "v": s.v}, {"rel": s.sol_rel, "v": s.v.neg()},
		{"rel": s.sol_rel, "v": s.c.add(s.b).div(s.a)}]
	return out


func u_two_sided(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := range2(s.lo, s.r1, s.r2, s.hi)
	var neg: bool = s.a.sign() < 0
	var c1b: Q = s.c1.sub(s.b)
	var c2b: Q = s.c2.sub(s.b)
	var steps := ["%s: %s %s %s %s %s" % [take(s.b, "all three parts"), N(c1b), s.rel1, Fmt.term(s.a, 1, true), s.rel2, N(c2b)],
		"Divide all three parts by %s%s: %s" % [N(s.a), ", a negative number, so both signs turn round and the ends swap" if neg else "", Answer.text(ans)],
		"So %s." % Answer.text(ans)]
	var out := {"asked": "Solve the inequality.", "lines": [two_line(s)], "answer": ans,
		"given": {"form": "two", "a": s.a.key(), "b": s.b.key(), "c1": s.c1.key(), "rel1": s.rel1, "c2": s.c2.key(), "rel2": s.rel2},
		"methods": {"inverse-operations": method(steps, ans.values)}}
	var wrongs: Array = []
	if neg:
		# Dividing by a negative and keeping the signs: the ends come out the wrong way round.
		wrongs.append(wrong(r2v(c1b.div(s.a), s.rel1, s.rel2, c2b.div(s.a)), REF_KEEP_SIGN))
	wrongs.append(wrong(r2v(s.c1.div(s.a), s.rel1, s.rel2, s.c2.div(s.a)) if not neg else r2v(s.c2.div(s.a), s.rel2, s.rel1, s.c1.div(s.a)), REF_MIDDLE_ONLY))
	out.wrongs = wrongs
	out.generic = [r2v(s.lo, STRICT[s.r1], STRICT[s.r2], s.hi), r2v(s.lo, s.r2, s.r1, s.hi), r2v(s.hi.neg(), s.r1, s.r2, s.lo.neg()), r2v(s.lo.sub(1), s.r1, s.r2, s.hi.add(1))]
	out.spot = _spot_middle_only(s, rng)
	return out


## A student's working that does a step to the middle part only (catalogue error-spot):
## the subtraction (first wrong line 1) or the division (line 2).
static func _spot_middle_only(s: Dictionary, rng: Seeded) -> Dictionary:
	var lines: Array = []
	var bad := rng.int_in(0, 1)
	var c1: Q = s.c1
	var c2: Q = s.c2
	if bad == 0:
		lines.append("%s: %s %s %s %s %s" % [take(s.b, "the middle"), N(c1), s.rel1, Fmt.term(s.a, 1, true), s.rel2, N(c2)])
	else:
		c1 = c1.sub(s.b)
		c2 = c2.sub(s.b)
		lines.append("%s: %s %s %s %s %s" % [take(s.b, "each part"), N(c1), s.rel1, Fmt.term(s.a, 1, true), s.rel2, N(c2)])
	var lo: Q
	var hi: Q
	var r1: String
	var r2: String
	if bad == 1:
		lo = c1
		hi = c2
		r1 = s.rel1
		r2 = s.rel2
		lines.append("Divide the middle by %s: %s %s x %s %s" % [N(s.a), N(lo), r1, r2, N(hi)])
	else:
		if s.a.sign() > 0:
			lo = c1.div(s.a)
			hi = c2.div(s.a)
			r1 = s.rel1
			r2 = s.rel2
		else:
			lo = c2.div(s.a)
			hi = c1.div(s.a)
			r1 = s.rel2
			r2 = s.rel1
		lines.append("Divide each part by %s%s: %s %s x %s %s" % [N(s.a), " and turn the signs round" if s.a.sign() < 0 else "", N(lo), r1, r2, N(hi)])
	lines.append("That is: x %s %s and x %s %s" % [FLIP[r1], N(lo), r2, N(hi)])
	lines.append("So the solution is: %s %s x %s %s" % [N(lo), r1, r2, N(hi)])
	var why := "each step must be done to all three parts: %s too" % take(s.b, "%s and %s" % [N(s.c1), N(s.c2)]).to_lower() if bad == 0 \
		else "each step must be done to all three parts: divide %s and %s by %s too" % [N(s.c1.sub(s.b)), N(s.c2.sub(s.b)), N(s.a)]
	return {"lines": lines, "bad": bad, "ref": REF_MIDDLE_ONLY, "why": why}


func u_read_number_line(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans: Dictionary
	var gen: Array
	var wrongs: Array
	var shade := ""
	var tests := ""
	if s.sided == "one":
		ans = bound(s.sol_rel, s.v)
		wrongs = [wrong({"rel": STRICT[s.sol_rel], "v": s.v}, REF_CIRCLES)]
		gen = [{"rel": FLIP[s.sol_rel], "v": s.v}, {"rel": FLIP[STRICT[s.sol_rel]], "v": s.v}, {"rel": s.sol_rel, "v": s.v.add(1)}, {"rel": s.sol_rel, "v": s.v.neg()}]
		var up: bool = s.sol_rel in [">", "≥"]
		shade = "The line is shaded from %s %s, with %s circle at %s" % [N(s.v), "upwards" if up else "downwards", "an open" if s.sol_rel in ["<", ">"] else "a closed", N(s.v)]
		var inside: Q = s.v.add(2 if up else -2)
		var outside: Q = s.v.add(-2 if up else 2)
		tests = "Test x = %s, in the shading: %s %s %s is true; x = %s, outside it: %s %s %s is false" % [N(inside), N(inside), s.sol_rel, N(s.v), N(outside), N(outside), s.sol_rel, N(s.v)]
	else:
		ans = range2(s.lo, s.r1, s.r2, s.hi)
		wrongs = [wrong(r2v(s.lo, STRICT[s.r1], STRICT[s.r2], s.hi), REF_CIRCLES)]
		gen = [r2v(s.lo, s.r2, s.r1, s.hi), r2v(s.lo.sub(1), s.r1, s.r2, s.hi.add(1)), r2v(s.lo, STRICT[s.r1], s.r2, s.hi), r2v(s.lo, s.r1, STRICT[s.r2], s.hi)]
		shade = "The line is shaded from %s to %s: %s circle at %s and %s circle at %s" % [N(s.lo), N(s.hi), "an open" if s.r1 == "<" else "a closed", N(s.lo), "an open" if s.r2 == "<" else "a closed", N(s.hi)]
		var mid: Q = s.lo.add(s.hi).div(2)
		tests = "Test x = %s, in the shading, and x = %s, outside it: only the first fits" % [N(mid), N(s.hi.add(1))]
	var steps := [shade, tests, "An open circle leaves its number out (< or >); a closed one includes it (≤ or ≥)", "So %s." % Answer.text(ans)]
	return {"asked": "Write the inequality the number line shows.", "lines": ["The number line shows the solution of an inequality in x."],
		"graph": numberline(s), "given": export(s), "answer": ans, "wrongs": wrongs, "generic": gen,
		"methods": {"test-value": method(steps, ans.values)}}


func u_count_integers(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("number", {"v": s.n})
	ans.exact = true
	var first := ceili(s.lo.to_float())
	if s.r1 == "<" and s.lo.eq(first):
		first += 1
	var last := floori(s.hi.to_float())
	if s.r2 == "<" and s.hi.eq(last):
		last -= 1
	var steps := ["Solve: %s %s x %s %s%s" % [N(s.lo), s.r1, s.r2, N(s.hi), " (dividing by a negative turns the signs round)" if s.a.sign() < 0 else ""],
		"The whole numbers in it run from %s to %s" % [N(first), N(last)],
		"Test the ends: x = %s fits and %s doesn't; x = %s fits and %s doesn't" % [N(first), N(first - 1), N(last), N(last + 1)],
		"So there are %s − %s + 1 = %s whole numbers." % [N(last), P(first), Answer.text(ans)]]
	var line := two_line(s)
	var out := {"asked": "How many whole numbers x satisfy the inequality?", "lines": [line], "answer": ans,
		"given": {"form": "count", "a": s.a.key(), "b": s.b.key(), "c1": s.c1.key(), "rel1": s.rel1, "c2": s.c2.key(), "rel2": s.rel2},
		"methods": {"test-value": method(steps, ans.values)}}
	if rep == "words":
		out.lines = ["%s %s %s and %s %s." % [words_shown(s), WORDS[FLIP[s.rel1]], N(s.c1), WORDS[s.rel2], N(s.c2)]]
		out.asked = "How many whole numbers x make this true?"
	out.generic = [{"v": s.n.add(1)}, {"v": s.n.sub(1)}, {"v": s.n.add(2)}, {"v": Q.new(last - first)}]
	return out
