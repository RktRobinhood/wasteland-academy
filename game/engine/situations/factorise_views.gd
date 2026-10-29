class_name FactoriseViews
extends ExtensionViews
## The views on the `fn-pre-factorise` situation: one builder per unknown of
## fn-pre-factorise (FAL-459). The "graph" representation is the catalogue's area
## grid with the total given and the edges missing, drawn as a table.

const REF_SIGNS := "fn-pre-factorise#0"
const REF_SUM_OF_SQUARES := "fn-pre-factorise#1"
const REF_FIRST_ONLY := "fn-pre-factorise#2"
const REF_IGNORE_A := "fn-pre-factorise#3"
const NO_FACTORS := "It does not factorise"

## Methods that don't work, for method-pick (the catalogue marks none as failing here).
const NOT_COMMON := {"name": "Take out a common factor", "why": "the terms have no common factor"}
const NOT_DOS := {"name": "Use a difference of two squares", "why": "there is an x term, so it is not p²x² − q²"}
const NOT_C_ONLY := {"name": "Two numbers with product c and sum b", "why": "that ignores a: the product must be ac"}
const NOT_ROOT_TERMS := {"name": "Square root each term", "why": "roots don't split over a sum or a difference"}
const NOT_DIVIDE_X := {"name": "Divide every term by x", "why": "that changes the expression; take the x out as a factor instead"}
const NOT_SPLIT := {"name": "Split the middle term and group", "why": "there is no middle term to split"}


func needs() -> Dictionary:
	return {
		"common-factor": {"form": "common"},
		"monic-trinomial": {"form": "monic"},
		"difference-of-squares": {"form": "dos"},
		"non-monic": {"form": "nonmonic"},
		"factor-pair": {"form": "pair"},
		"missing-bracket-term": {"form": "missing"},
	}


func extra() -> Dictionary:
	return {"common-factor": ["method-pick"], "monic-trinomial": ["method-pick"], "difference-of-squares": ["method-pick"],
		"non-monic": ["error-spot", "method-pick"], "factor-pair": ["method-pick"], "missing-bracket-term": ["method-pick"]}


# ── Helpers ──────────────────────────────────────────────────

static func expr(s: Dictionary) -> String:
	return Fmt.general(s.A, s.B, s.C)


## (ax + b) as written: "(2x + 1)", "(x − 3)".
static func lin(a: Q, b: Q) -> String:
	return "(%s)" % Fmt.poly([a, b])


static func b2(a1: Q, b1: Q, a2: Q, b2_: Q) -> Dictionary:
	return {"a1": a1, "b1": b1, "a2": a2, "b2": b2_}


static func given_of(s: Dictionary) -> Dictionary:
	return {"form": s.form, "A": s.A.key(), "B": s.B.key(), "C": s.C.key()}


## The area grid with ax² and c in its corners and the edges missing.
static func grid(s: Dictionary) -> Dictionary:
	var lead := "?x" if not s.A.eq(1) else "x"
	return {"rows": [["×", [lead, "?"]], [lead, [Fmt.term(s.A, 2, true), "?"]], ["?", ["?", N(s.C)]]]}


static func grid_line(s: Dictionary) -> String:
	return "The area grid's total is %s: its two empty cells add to %s." % [expr(s), Fmt.term(s.B, 1, true)]


# ── fn-pre-factorise ─────────────────────────────────────────

func u_common_factor(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("common", {"g": s.g, "a": s.a, "b": s.b})
	var gx := Fmt.lead(s.g) + "x"
	var steps := ["The highest common factor of %s and %s is %s, and both terms have an x: take out %s" % [N(s.A), N(s.B), N(s.g), gx],
		"%s ÷ %s = %s and %s ÷ %s = %s" % [Fmt.term(s.A, 2, true), gx, Fmt.term(s.a, 1, true), Fmt.term(s.B, 1, true), gx, N(s.b)],
		"So %s." % Answer.text(ans)]
	return {"asked": "Factorise fully.", "lines": [expr(s)], "given": given_of(s), "answer": ans,
		"wrongs": [wrong({"g": s.g, "a": s.a, "b": s.B}, REF_FIRST_ONLY)],
		"generic": [{"g": Q.new(1), "a": s.A, "b": s.B}, {"g": s.g, "a": s.a, "b": s.b.neg()}, {"g": s.g, "a": s.A, "b": s.b}, {"g": s.g.neg(), "a": s.a, "b": s.b}],
		"methods": {"recognise-pattern": method(steps, ans.values)},
		"pick_wrongs": [NOT_SPLIT, NOT_DIVIDE_X, NOT_ROOT_TERMS, NOT_DOS]}


func u_monic_trinomial(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("brackets", {"r": s.r, "s": s.s})
	var final := "So %s." % Answer.text(ans)
	var out := {"asked": "Factorise.", "lines": [expr(s)], "given": given_of(s), "answer": ans}
	if rep == "graph":
		out.table = grid(s)
		out.lines = [expr(s), grid_line(s)]
	var find := "Two numbers with product %s and sum %s: %s and %s" % [N(s.C), N(s.B), N(s.r), N(s.s)]
	out.methods = {
		"product-sum": method([find, final], ans.values),
		"expand-check": method(["Try %s and %s (product %s, sum %s)" % [N(s.r), N(s.s), N(s.C), N(s.B)],
			"Expand to check: %s = %s" % [Answer.text(ans), expr(s)], final], ans.values),
	}
	out.wrongs = [wrong({"r": s.r.neg(), "s": s.s.neg()}, REF_SIGNS)]
	out.generic = [{"r": s.r.neg(), "s": s.s}, {"r": s.r, "s": s.s.neg()}, {"r": s.C, "s": Q.new(1)}, {"r": s.B, "s": s.C}]
	out.pick_wrongs = [NOT_COMMON, NOT_DOS, NOT_ROOT_TERMS, NOT_DIVIDE_X]
	return out


func u_difference_of_squares(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var px := Fmt.lead(s.p) + "x"
	var out := {"asked": "Factorise, if it can be done over the integers.", "lines": [expr(s)], "given": given_of(s).merged({"sum": s.sum})}
	out.pick_wrongs = [NOT_COMMON, NOT_ROOT_TERMS, NOT_SPLIT, NOT_DIVIDE_X]
	var pxsq := "x²" if s.p.eq(1) else "(%s)²" % px
	if s.sum:
		var fake := "(%s + %s)(%s − %s)" % [px, N(s.q), px, N(s.q)]
		var opts := [NO_FACTORS, fake, "(%s + %s)²" % [px, N(s.q)], "(%s − %s)²" % [px, N(s.q)]]
		var ans := Answer.make("choice", {"v": NO_FACTORS}, {"options": opts})
		out.answer = ans
		out.wrongs = [wrong({"v": fake}, REF_SUM_OF_SQUARES)]
		out.generic = opts.slice(2).map(func(o): return {"v": o})
		out.methods = {"recognise-pattern": method([
			"%s = %s + %s² is a sum of two squares, not a difference" % [expr(s), pxsq, N(s.q)],
			"%s = %s − %s, and (%s ± %s)² has a middle term ±%s, so none of them is %s" % [fake, Fmt.term(s.A, 2, true), N(s.C), px, N(s.q), Fmt.term(s.p.mul(s.q).mul(2), 1, true), expr(s)],
			"So: %s." % Answer.text(ans)], ans.values)}
		return out
	var ans := Answer.make("brackets2", b2(s.p, s.q.neg(), s.p, s.q))
	out.answer = ans
	out.methods = {"recognise-pattern": method([
		"%s = %s − %s², a difference of two squares" % [expr(s), pxsq, N(s.q)],
		"a² − b² = (a − b)(a + b) with a = %s and b = %s" % [px, N(s.q)],
		"So %s." % Answer.text(ans)], ans.values)}
	out.generic = [b2(s.p, s.q.neg(), s.p, s.q.neg()), b2(s.p, s.q, s.p, s.q), b2(Q.new(1), s.q.neg(), s.A, s.q), b2(s.p, s.C, s.p, Q.new(1))]
	return out


func u_non_monic(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := Answer.make("brackets2", b2(s.a1, s.b1, s.a2, s.b2))
	var final := "So %s." % Answer.text(ans)
	var out := {"asked": "Factorise.", "lines": [expr(s)], "given": given_of(s), "answer": ans}
	if rep == "graph":
		out.table = grid(s)
		out.lines = [expr(s), grid_line(s)]
	var ac: Q = s.A.mul(s.C)
	# The split: a1·b2 x + a2·b1 x, grouped as a1x(a2x + b2) + b1(a2x + b2).
	var m: Q = s.a1.mul(s.b2)
	var n: Q = s.a2.mul(s.b1)
	var split := "%s%s%s%s" % [Fmt.term(s.A, 2, true), Fmt.term(m, 1, false), Fmt.term(n, 1, false), Fmt.plus(s.C)]
	var grouped := "%sx%s %s %s%s" % [Fmt.lead(s.a1), lin(s.a2, s.b2), "−" if s.b1.sign() < 0 else "+", s.b1.abs_q().text(), lin(s.a2, s.b2)]
	var disc: Q = s.B.sq().sub(ac.mul(4))
	var root := Q.new(roundi(sqrt(disc.to_float())))
	var x1: Q = s.b1.neg().div(s.a1)
	var x2: Q = s.b2.neg().div(s.a2)
	out.methods = {
		"product-sum": method(["ac = %s × %s = %s. Two numbers with product %s and sum %s: %s and %s" % [N(s.A), P(s.C), N(ac), N(ac), N(s.B), N(m), N(n)],
			"%s = %s = %s" % [expr(s), split, grouped], final], ans.values),
		"split-middle": method(["Split %s as %s%s (product %s = ac, sum %s)" % [Fmt.term(s.B, 1, true), Fmt.term(m, 1, true), Fmt.term(n, 1, false), N(ac), N(s.B)],
			"Group: %s = %s" % [split, grouped], "Take out the common bracket %s" % lin(s.a2, s.b2), final], ans.values),
		"roots-first": method(["Solve %s = 0: Δ = %s² − 4 × %s × %s = %s, so x = (%s ± %s)/%s" % [expr(s), P(s.B), N(s.A), P(s.C), N(disc), N(s.B.neg()), N(root), N(s.A.mul(2))],
			"x = %s or x = %s" % [N(x1), N(x2)],
			"%s = %s%s%s = %s%s" % [expr(s), Fmt.lead(s.A), Fmt.factor(x1), Fmt.factor(x2), lin(s.a1, s.b1), lin(s.a2, s.b2)], final], ans.values),
		"expand-check": method(["%s = %s × %s and %s = %s × %s: try %s%s" % [N(s.A), N(s.a1), N(s.a2), N(s.C), P(s.b1), P(s.b2), lin(s.a1, s.b1), lin(s.a2, s.b2)],
			"Expand to check: %s%s = %s = %s" % [lin(s.a1, s.b1), lin(s.a2, s.b2), split, expr(s)], final], ans.values),
	}
	out.wrongs = [wrong(b2(Q.new(1), s.b1, Q.new(1), s.b2), REF_IGNORE_A)]
	out.generic = [b2(s.a1, s.b1.neg(), s.a2, s.b2.neg()), b2(s.a1, s.b2, s.a2, s.b1), b2(s.A, s.b1, Q.new(1), s.b2), b2(s.a1, s.b1.neg(), s.a2, s.b2)]
	out.pick_wrongs = [NOT_C_ONLY, NOT_COMMON, NOT_DOS, NOT_ROOT_TERMS]
	out.spot = _spot_ignore_a(s, rng)
	return out


## A student's working that looks only at c (fn-pre-factorise#3): up to two right lines
## first, then the pair of c, then where it leads. The first wrong line is 1, 2 or 3.
static func _spot_ignore_a(s: Dictionary, rng: Seeded) -> Dictionary:
	var lead: Array = ["%s has a = %s, b = %s and c = %s" % [expr(s), N(s.A), N(s.B), N(s.C)],
		"We need two numbers that add to %s" % N(s.B)]
	var k := rng.int_in(0, 2)
	var lines: Array = lead.slice(0, k)
	lines.append("Two numbers that multiply to %s: %s and %s" % [N(s.C), N(s.b1), N(s.b2)])
	lines.append("So %s = (x%s)(x%s)" % [expr(s), Fmt.plus(s.b1), Fmt.plus(s.b2)])
	if lines.size() < 4:
		lines.append("Check: (x%s)(x%s) = %s" % [Fmt.plus(s.b1), Fmt.plus(s.b2), Fmt.general(1, s.b1.add(s.b2), s.C)])
	if lines.size() < 4:
		lines.append("The roots are x = %s and x = %s" % [N(s.b1.neg()), N(s.b2.neg())])
	return {"lines": lines, "bad": k, "ref": REF_IGNORE_A,
		"why": "with a = %s, the two numbers must multiply to ac = %s, not to c = %s" % [N(s.A), N(s.A.mul(s.C)), N(s.C)]}


func u_factor_pair(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("pair", {"r1": s.m, "r2": s.n})
	var pairs: Array = []
	var p: int = s.P.n
	for d in range(1, absi(p) + 1):
		if absi(p) % d == 0 and d * d <= absi(p):
			var e := p / d
			pairs.append("%s × %s" % [N(d), N(e)])
			pairs.append("%s × %s" % [N(-d), N(-e)])
	var steps := ["Factor pairs of %s: %s" % [N(s.P), ", ".join(pairs)],
		"The pair that adds to %s is %s and %s" % [N(s.S), N(s.m), N(s.n)], "So %s." % Answer.text(ans)]
	return {"asked": "Find the two numbers.", "lines": ["Two numbers have product %s and sum %s." % [N(s.P), N(s.S)]],
		"given": {"form": "pair", "P": s.P.key(), "S": s.S.key()}, "answer": ans,
		"generic": [{"r1": s.m.neg(), "r2": s.n.neg()}, {"r1": s.m.neg(), "r2": s.n}, {"r1": Q.new(1), "r2": s.P}, {"r1": s.S, "r2": Q.new(1)}],
		"methods": {"product-sum": method(steps, ans.values)},
		"pick_wrongs": [{"name": "Halve the sum", "why": "that gives two equal numbers, whose product is not %s" % N(s.P)},
			{"name": "Square root the product", "why": "that gives two equal numbers too"},
			{"name": "Divide the product by the sum", "why": "that number has no reason to be one of the two"}]}


func u_missing_bracket_term(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("number", {"v": s.s}, {}, "□ = ")
	ans.exact = true
	var steps := ["%s(x + □) = x² + (%s + □)x + %s × □, so %s × □ = %s" % [Fmt.factor(s.r.neg()), N(s.r), P(s.r), P(s.r), N(s.C)],
		"□ = %s ÷ %s = %s. Check the x term: %s + %s = %s" % [N(s.C), P(s.r), N(s.s), N(s.r), P(s.s), N(s.B)],
		"So %s." % Answer.text(ans)]
	return {"asked": "Find the missing number.", "lines": ["%s(x + □) = %s" % [Fmt.factor(s.r.neg()), expr(s)]],
		"given": given_of(s).merged({"r": s.r.key()}), "answer": ans,
		"generic": [{"v": s.s.neg()}, {"v": s.C}, {"v": s.B}, {"v": s.B.add(s.r)}, {"v": s.C.sub(s.r)}],
		"methods": {"expand-check": method(steps, ans.values)},
		"pick_wrongs": [{"name": "Subtract the number in the bracket from c", "why": "the numbers in the brackets multiply to c, they don't add to it"},
			{"name": "Divide b by the number in the bracket", "why": "the numbers in the brackets add to b, they don't multiply to it"},
			{"name": "Halve b", "why": "the two numbers are only equal in a perfect square"}]}
