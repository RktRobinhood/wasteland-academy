class_name BinomialExpansionViews
extends ExtensionViews
## The views on the `binomial-expansion` situation: one builder per unknown of t1-binomial-term
## (FAL-728). Every answer is an exact whole number, so every kind is "form": the text is written
## here, and the slots are what a student types.
##
## Representations: "equation" (the bracket, or nCr, in the question) and "table" (Pascal's
## triangle as a figure, with blank cells for the staggering and no row numbers, as reading the
## row is the skill). The methods that need the triangle have unknowns of their own
## (ncr-read-triangle and so on), as the cells of a type are unknown by representation by method.
##
## Misconceptions come from SL1.9, then the type's own, which are "<type id>#<index>".

const SKILL := "SL1.9."
const R_NO_DENOM := SKILL + "ncr-pascal#0"
const R_ROW_ONE := SKILL + "ncr-pascal#1"
const R_ZERO := SKILL + "ncr-pascal#2"
const R_UNRAISED := SKILL + "full-expansion#0"
const R_SIGNS := SKILL + "full-expansion#1"
const R_POWERS := SKILL + "full-expansion#2"
const R_SIGN := SKILL + "specific-term#0"
const R_OTHER := SKILL + "specific-term#1"
const R_TERM := SKILL + "specific-term#2"
const R_NO_R := "t1-binomial-term#9"
const R_NEG_ROOT := "t1-binomial-term#10"
const R_N_TERMS := "t1-binomial-term#11"
const R_PLACE := "t1-binomial-term#12"
const R_OVER := "t1-binomial-term#13"

const UNKNOWNS := ["ncr-value", "ncr-read-triangle", "ncr-large-r", "ncr-symmetry", "ncr-edge", "ncr-find-n",
	"ncr-formula-in-n", "pascal-row", "pascal-next-row", "row-from-entries", "number-of-terms", "expand-small",
	"expand-unit", "expand-negative", "expand-raised", "expand-from-triangle", "expand-power", "expand-reciprocal",
	"first-three-terms", "coefficient-plain", "coefficient-negative", "coefficient-raised",
	"coefficient-from-triangle", "coefficient-power", "coefficient-letter", "specific-term", "missing-coefficient",
	"term-by-position"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## The GDC is Paper 2. The rest is both: Paper 2 has the longer rows.
func papers(unknown: String, _rep: String, angle_id: String) -> Array:
	if not has(unknown):
		return []
	return [2] if angle_id == "gdc-ncr" else [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = BinomialExpansionSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func C(n: int, r: int) -> int:
	return BinomialExpansionSituation.ncr(n, r)


static func pw(v: int, e: int) -> int:
	return BinomialExpansionSituation.power(v, e)


static func fact(n: int) -> int:
	return BinomialExpansionSituation.factorial(n)


static func row(n: int) -> Array:
	return BinomialExpansionSituation.row(n)


static func row_text(n: int) -> String:
	return ", ".join(row(n).map(func(v): return str(v)))


static func term(c: int, power: int, letter: String = "x") -> String:
	return Fmt.terms([Q.new(c)], [power], letter)


## The x term as written: 2x, x², −3x.
static func term_a(s: Dictionary) -> String:
	return term(s.a, s.p)


## The other term as written: 3, −2, 2/x, k.
static func term_b(s: Dictionary) -> String:
	if s.letter != "":
		return s.letter
	return N(s.b) + "/x" if s.over else N(s.b)


## (2x − 3), (3 − 2x), (x + 2/x).
static func bracket(s: Dictionary) -> String:
	var one: String = term_b(s) if s.first else term_a(s)
	var two: String = term_a(s) if s.first else term_b(s)
	return "(%s − %s)" % [one, two.substr(1)] if two.begins_with("−") else "(%s + %s)" % [one, two]


## (2x − 3)⁶.
static func power_text(s: Dictionary) -> String:
	return bracket(s) + Fmt.sup(s.n)


## A term as a base to take a power of: x, (2x), (x²), (−3), 3, (2/x), k.
static func base_a(s: Dictionary) -> String:
	return "x" if s.a == 1 and s.p == 1 else "(%s)" % term_a(s)


static func base_b(s: Dictionary) -> String:
	var t := term_b(s)
	return "(%s)" % t if s.over or t.begins_with("−") else t


static func raised(base: String, e: int) -> String:
	return base if e == 1 else base + Fmt.sup(e)


## The number the x term gives from j brackets, as a term: 16x⁴.
static func a_value(s: Dictionary, j: int) -> String:
	var t := term(pw(s.a, j), s.p * j)
	return "(%s)" % t if t.begins_with("−") else t


## A whole number, in brackets when negative, to multiply by.
static func bare(v: int) -> String:
	return "(%s)" % N(v) if v < 0 else N(v)


## The number the other term gives from k brackets: 9, (−27), (8/x³ as 8x⁻³).
static func b_value(s: Dictionary, k: int) -> String:
	if s.over:
		return "(%s)" % term(pw(s.b, k), -k)
	return bare(pw(s.b, k))


## The term in x^(p·j) as a product. r is nCr's r, and with first_b the number is written first.
static func product(s: Dictionary, j: int, r: int, first_b: bool) -> String:
	var a := raised(base_a(s), j) if j > 0 else ""
	var b := raised(base_b(s), s.n - j) if s.n > j else ""
	var bits: Array = ["%dC%d" % [s.n, r]] + ([b, a] if first_b else [a, b])
	return " × ".join(bits.filter(func(t): return t != ""))


## The same with the numbers worked out: 15 × 16x⁴ × 9.
static func worked(s: Dictionary, j: int, first_b: bool) -> String:
	var a := a_value(s, j) if j > 0 else ""
	var b := b_value(s, s.n - j) if s.n > j else ""
	var bits: Array = [str(C(s.n, j))] + ([b, a] if first_b else [a, b])
	return " × ".join(bits.filter(func(t): return t != ""))


static func x_text(power: int) -> String:
	return term(1, power)


static func coef(s: Dictionary, j: int) -> int:
	return BinomialExpansionSituation.coef(s, j)


static func power_of(s: Dictionary, j: int) -> int:
	return BinomialExpansionSituation.power_of(s, j)


## The term with j brackets giving x: −96x³.
static func full(s: Dictionary, j: int) -> String:
	return term(coef(s, j), power_of(s, j))


# ── Answers and options ──────────────────────────────────────

## One typed whole number after a label.
static func number(label: String, v: int) -> Dictionary:
	var ans := Answer.make("form", {"v": Q.new(v), "text": N(v)}, {"parts": [label, {"slot": "v"}]}, label)
	ans.exact = true
	return ans


## A whole number with its letters written after the box: −560x³, 35k³.
static func with_tail(v: int, power: int, letter: String = "x") -> Dictionary:
	var tail := term(1, power, letter)
	var ans := Answer.make("form", {"v": Q.new(v), "text": term(v, power, letter)}, {"parts": [{"slot": "v"}, tail]})
	ans.exact = true
	return ans


## A wrong whole number, which can be typed.
static func wn(v: int, ref: String = "") -> Dictionary:
	return wrong({"v": Q.new(v), "text": N(v)}, ref)


## A wrong number before the answer's letters, which can be typed.
static func wt(v: int, power: int, ref: String = "", letter: String = "x") -> Dictionary:
	return wrong({"v": Q.new(v), "text": term(v, power, letter)}, ref)


## A wrong option in another shape, which can only be picked.
static func alt(text: String, ref: String = "") -> Dictionary:
	return wrong({"text": text, "shape": "other"}, ref)


## Values of plain wrong numbers near v, so there are always enough different options.
static func pad(v: int, xs: Array = []) -> Array:
	return (xs + [v + 1, v - 1, v + 2, v * 2]).map(func(x): return wn(x).values)


## Plain wrong terms near v.
static func pad_term(v: int, power: int, xs: Array = [], letter: String = "x") -> Array:
	return (xs + [v + 1, v - 1, v + 2, v * 2]).map(func(x): return wt(x, power, "", letter).values)


## The expansion as an answer: one typed coefficient per term, in the order of `order`, a list
## of j.
static func expansion(s: Dictionary, order: Array) -> Dictionary:
	var vals := poly_values(s, order, order.map(func(j): return coef(s, j)))
	var parts: Array = []
	for i in order.size():
		parts.append({"slot": "c%d" % i})
		if power_of(s, order[i]) != 0:
			parts.append(x_text(power_of(s, order[i])))
		if i < order.size() - 1:
			parts.append(" + ")
	var ans := Answer.make("form", vals, {"parts": parts})
	ans.exact = true
	return ans


## {c0, c1, ..., text} for these coefficients at the powers of `order`.
static func poly_values(s: Dictionary, order: Array, cs: Array) -> Dictionary:
	var out := {}
	var powers: Array = order.map(func(j): return power_of(s, j))
	for i in cs.size():
		out["c%d" % i] = Q.new(cs[i])
	out.text = Fmt.terms(cs.map(func(c): return Q.new(c)), powers)
	return out


## A wrong expansion with these coefficients, which can be typed.
static func wp(s: Dictionary, order: Array, f: Callable, ref: String = "") -> Dictionary:
	return wrong(poly_values(s, order, order.map(f)), ref)


## Every slip an expansion can show, and enough plain wrong ones.
static func expansion_options(s: Dictionary, order: Array, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var a: int = s.a
	var b: int = s.b
	var w: Array = []
	if absi(a) > 1:
		w.append(wp(s, order, func(j): return C(n, j) * (a if j > 0 else 1) * pw(b, n - j), R_UNRAISED))
	elif s.over:
		if absi(b) > 1:
			w.append(wp(s, order, func(j): return C(n, j) * pw(a, j) * (b if n > j else 1), R_UNRAISED))
	elif absi(b) > 1:
		w.append(wp(s, order, func(j): return C(n, j) * pw(a, j) * (b if n > j else 1), R_OTHER))
	if a < 0 or b < 0:
		w.append(wp(s, order, func(j): return absi(coef(s, j)), R_SIGNS))
	if s.over:
		var ps: Array = order.map(func(j): return j)
		w.append(alt(Fmt.terms(order.map(func(j): return Q.new(coef(s, j))), ps), R_OVER))
	else:
		w.append(wp(s, order, func(j): return C(n, j) * pw(a, j) * pw(b, j), R_POWERS))
	var g: Array = [
		wp(s, order, func(j): return pw(a, j) * pw(b, n - j)).values,
		wp(s, order, func(j): return C(n, j) * pw(b, j) * pw(a, n - j)).values,
		wp(s, order, func(j): return coef(s, j) * (-1 if (n - j) % 2 == 1 else 1)).values,
		wp(s, order, func(j): return coef(s, j) + (1 if j == order[0] else 0)).values,
		wp(s, order, func(j): return coef(s, j) * 2).values,
	]
	return {"wrongs": rng.shuffled(w), "generic": g}


## The rows of Pascal's triangle from 0 to n, staggered: blank cells either side of each row.
static func triangle(n: int) -> Dictionary:
	var rows: Array = []
	for i in n + 1:
		var cells: Array = []
		cells.resize(2 * n + 1)
		cells.fill("")
		for r in i + 1:
			cells[n - i + 2 * r] = str(C(i, r))
		rows.append(["", cells])
	return {"rows": rows}


# ── nCr ──────────────────────────────────────────────────────

## n × (n − 1) × ... for k factors.
static func falling(n: int, k: int) -> Array:
	return range(k).map(func(i): return n - i)


static func times(xs: Array) -> String:
	return " × ".join(xs.map(func(x): return str(x)))


## The steps of the factorial formula, cancelling the larger factorial.
static func formula_steps(n: int, r: int) -> Array:
	var small := mini(r, n - r)
	var big := n - small
	var top: Array = falling(n, small)
	var low: Array = falling(small, small)
	var top_v: int = 1
	for x in top:
		top_v *= x
	var low_v := BinomialExpansionSituation.factorial(small)
	return ["%dC%d = %d!/(%d! × %d!)" % [n, r, n, r, n - r],
		"Cancel the %d! from the top: (%s)/(%s) = %d/%d" % [big, times(top), times(low), top_v, low_v],
		"%d/%d = %d" % [top_v, low_v, C(n, r)]]


## The rows adding up to row n, from the row before: one line for the sums.
static func add_steps(n: int) -> Array:
	var sums: Array = []
	for r in range(1, n):
		sums.append("%d + %d" % [C(n - 1, r - 1), C(n - 1, r)])
	return ["Build the triangle from the 1 at the top by adding adjacent entries, down to row %d: %s." % [n - 1, row_text(n - 1)],
		"Add adjacent entries of that row: %s. Put a 1 at each end." % ", ".join(sums),
		"Row %d is %s." % [n, row_text(n)]]


func u_ncr_value(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var r: int = s.r
	var v := C(n, r)
	var ans := number("%dC%d = " % [n, r], v)
	var final := "So %s." % Answer.text(ans)
	return {"asked": "Find the value of %dC%d." % [n, r], "answer": ans,
		"wrongs": rng.shuffled([wn(fact(n) / fact(r), R_NO_DENOM), wn(fact(n) / fact(n - r), R_NO_R)]),
		"generic": pad(v, [C(n, r + 1), C(n, r - 1), C(n - 1, r), C(n + 1, r)]),
		"methods": {
			"factorial-formula": method(formula_steps(n, r) + [final], ans.values),
			"pascal-build": method(add_steps(n) + ["Counting from 0 at the left, entry %d of that row is %d." % [r, v], final], ans.values),
			"gdc-ncr": method(["Use the nCr function on the GDC: enter %d nCr %d." % [n, r], "%d nCr %d = %d" % [n, r, v], final], ans.values),
		}}


func u_ncr_read_triangle(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var r: int = s.r
	var v := C(n, r)
	var ans := number("%dC%d = " % [n, r], v)
	return {"asked": "Use Pascal's triangle to find %dC%d." % [n, r], "answer": ans, "table": triangle(n + 1),
		"wrongs": rng.shuffled([wn(C(n - 1, r), R_ROW_ONE)]),
		"generic": pad(v, [C(n + 1, r), C(n, r + 1), C(n, r - 1)]),
		"methods": {"pascal-build": method(["The top row is row 0, so the row that starts 1, %d is row %d: %s." % [n, n, row_text(n)],
			"Counting from 0 at the left, entry %d of that row is %d." % [r, v], "So %s." % Answer.text(ans)], ans.values)}}


func u_ncr_large_r(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var r: int = s.r
	var v := C(n, r)
	var ans := number("%dC%d = " % [n, r], v)
	var final := "So %s." % Answer.text(ans)
	var small := n - r
	var out := formula_steps(n, small)
	return {"asked": "Find the value of %dC%d." % [n, r], "answer": ans,
		"wrongs": rng.shuffled([wn(fact(n) / fact(r), R_NO_DENOM)]),
		"generic": pad(v, [C(n, r - 1), C(n, r + 1), n, C(n - 1, r)]),
		"methods": {
			"symmetry": method(["Use nCr = nC(n − r) to choose the smaller r: %dC%d = %dC%d." % [n, r, n, small]] + out + [final], ans.values),
			"factorial-formula": method(formula_steps(n, r) + [final], ans.values),
			"gdc-ncr": method(["Use the nCr function on the GDC: enter %d nCr %d." % [n, r], "%d nCr %d = %d" % [n, r, v], final], ans.values),
		}}


func u_ncr_symmetry(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var r: int = s.r
	var m := n - r
	var ans := number("m = ", m)
	var near: Array = [m + 1, m - 1, n, n + r, r + 1, m + 2].filter(func(x): return x != r and x != m)
	return {"asked": "%dC%d = %dCm, where m ≠ %d. Find m." % [n, r, n, r], "answer": ans,
		"generic": near.map(func(x): return wn(x).values),
		"methods": {"symmetry": method(["Choosing %d from %d to take is the same as choosing %d to leave, so nCr = nC(n − r)." % [r, n, m],
			"%dC%d = %dC(%d − %d) = %dC%d" % [n, r, n, n, r, n, m], "So %s." % Answer.text(ans)], ans.values)}}


func u_ncr_edge(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var r: int = s.r
	var ans := number("%dC%d = " % [n, r], 1)
	var final := "So %s." % Answer.text(ans)
	return {"asked": "Find the value of %dC%d." % [n, r], "answer": ans,
		"wrongs": [wn(0, R_ZERO if r == 0 else "")], "generic": pad(1, [n, 0, n + 1, n - 1]),
		"methods": {
			"factorial-formula": method(["%dC%d = %d!/(%d! × %d!)" % [n, r, n, r, n - r], "0! = 1, so the top and the bottom are both %d!." % n, final], ans.values),
			"pascal-build": method(["Every row of Pascal's triangle starts and ends with 1.", "%dC%d is the %s entry of row %d." % [n, r, "first" if r == 0 else "last", n], final], ans.values),
		}}


func u_ncr_find_n(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var v := C(n, 2)
	var ans := number("n = ", n)
	var final := "So %s." % Answer.text(ans)
	var w: Array = [wn(1 - n, R_NEG_ROOT)]
	if angle == "pascal-build":
		w.append(wn(n + 1, R_ROW_ONE))
	var entries: Array = range(2, n + 1).map(func(m): return str(C(m, 2)))
	return {"asked": "nC2 = %d, where n is a whole number. Find n." % v, "answer": ans,
		"wrongs": rng.shuffled(w), "generic": pad(n, [n + 1, n - 1, v, 2 * v]),
		"methods": {
			"factorial-formula": method(["nC2 = n!/(2! × (n − 2)!) = n(n − 1)/2", "n(n − 1)/2 = %d, so n² − n − %d = 0" % [v, 2 * v],
				"(n − %d)(n + %d) = 0, so n = %d or n = %s" % [n, n - 1, n, N(1 - n)], "n counts brackets, so it can't be negative. " + final], ans.values),
			"gdc-ncr": method(["Tabulate x nCr 2 on the GDC against x.", "The table gives %d at x = %d." % [v, n], final], ans.values),
			"pascal-build": method(["nC2 is entry 2 of row n, counting from 0.", "Entry 2 of rows 2, 3, 4 and on is %s." % ", ".join(entries),
				"%d is in row %d. " % [v, n] + final], ans.values),
		}}


## n + c as written: "n", "n + 1", "n − 1".
static func shifted(c: int) -> String:
	return "n" if c == 0 else "n %s %d" % ["+" if c > 0 else "−", absi(c)]


## n + c ready for a factorial or a product: "n", "(n + 1)".
static func inner(c: int) -> String:
	return shifted(c) if c == 0 else "(%s)" % shifted(c)


func u_ncr_formula_in_n(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c: int = s.shift
	var top := shifted(c)
	var name := "nC2" if c == 0 else "(%s)C2" % top
	var cs: Array = [Q.new(1, 2), Q.new(2 * c - 1, 2), Q.new(c * (c - 1), 2)]
	var powers := [2, 1, 0]
	var slots := 3 if c * (c - 1) != 0 else 2
	var parts: Array = [{"slot": "c0"}, "n² + ", {"slot": "c1"}, "n"]
	if slots == 3:
		parts.append_array([" + ", {"slot": "c2"}])
	var vals := {"c0": cs[0], "c1": cs[1], "text": Fmt.terms(cs, powers, "n")}
	if slots == 3:
		vals.c2 = cs[2]
	var ans := Answer.make("form", vals, {"parts": parts})
	ans.exact = true
	## (n + c)(n + c + d) / e as the same slots.
	var make := func(d: int, e: int, ref: String = "") -> Dictionary:
		var q: Array = [Q.new(1, e), Q.new(2 * c + d, e), Q.new(c * (c + d), e)]
		var v := {"c0": q[0], "c1": q[1], "text": Fmt.terms(q, powers, "n")}
		if slots == 3:
			v.c2 = q[2]
		elif not q[2].is_zero():
			v.shape = "other"
		return wrong(v, ref)
	var below := inner(c) + inner(c - 1)
	var low := inner(c - 2)
	return {"asked": "Write %s as a polynomial in n, for whole numbers n ≥ 3." % name, "answer": ans,
		"wrongs": rng.shuffled([make.call(-1, 1, R_NO_R)]),
		"generic": [make.call(1, 2).values, make.call(-2, 2).values, make.call(0, 2).values, make.call(1, 1).values],
		"methods": {"factorial-formula": method(["%s = %s!/(2! × %s!)" % [name, inner(c), low],
			"Cancel %s! from the top, which leaves %s." % [low, below], "2! = 2, so %s = %s/2" % [name, below],
			"Multiply out: %s = %s" % [name, Answer.text(ans)]], ans.values)}}


# ── Rows of the triangle ─────────────────────────────────────

## Row n as an answer: the ends are given, the rest typed.
static func row_answer(n: int) -> Dictionary:
	var vals := {"text": row_text(n)}
	var parts: Array = ["1, "]
	for r in range(1, n):
		vals["v%d" % r] = Q.new(C(n, r))
		parts.append({"slot": "v%d" % r})
		parts.append(", ")
	parts.append("1")
	var ans := Answer.make("form", vals, {"parts": parts})
	ans.exact = true
	return ans


## Row n with one entry out, which can be typed.
static func row_off(ans: Dictionary, n: int, by: int) -> Dictionary:
	var v: Dictionary = ans.values.duplicate()
	var r: int = n / 2
	v["v%d" % r] = Q.new(C(n, r) + by)
	var cells: Array = row(n)
	cells[r] = C(n, r) + by
	v.text = ", ".join(cells.map(func(x): return str(x)))
	return v


func u_pascal_row(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var ans := row_answer(n)
	var final := "So row %d is %s." % [n, Answer.text(ans)]
	var list: Array = range(n + 1).map(func(r): return "%dC%d = %d" % [n, r, C(n, r)])
	return {"asked": "Write down the row of Pascal's triangle for n = %d." % n, "answer": ans,
		"wrongs": [alt(row_text(n - 1), R_ROW_ONE)],
		"generic": [alt(row_text(n + 1)).values, alt(row_text(n + 2)).values, row_off(ans, n, 2), row_off(ans, n, -1)],
		"methods": {
			"pascal-build": method(add_steps(n).slice(0, 2) + [final], ans.values),
			"factorial-formula": method(["The entries are nCr for r = 0 to %d, from nCr = n!/(r!(n − r)!)." % n, ", ".join(list), final], ans.values),
			"gdc-ncr": method(["Tabulate %d nCx on the GDC for x = 0 to %d." % [n, n], "The table gives %s." % row_text(n), final], ans.values),
		}}


func u_pascal_next_row(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var m: int = n + 1
	var ans := row_answer(m)
	var sums: Array = []
	for r in range(1, m):
		sums.append("%d + %d" % [C(n, r - 1), C(n, r)])
	return {"asked": "These are the first rows of Pascal's triangle. Write down the next row.", "answer": ans, "table": triangle(n),
		"generic": [alt(row_text(n)).values, alt(row_text(m + 1)).values, row_off(ans, m, 2), row_off(ans, m, -1), row_off(ans, m, 1)],
		"methods": {"pascal-build": method(["The last row shown is %s." % row_text(n),
			"Each entry of the next row is the sum of the two above it: %s, with a 1 at each end." % ", ".join(sums),
			"So the next row is %s." % Answer.text(ans)], ans.values)}}


func u_row_from_entries(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var ans := number("n = ", n)
	return {"asked": "This row of Pascal's triangle gives the coefficients of (a + b)^n. Find n.", "answer": ans,
		"table": {"rows": [["", row(n).map(func(v): return str(v))]]},
		"wrongs": rng.shuffled([wn(n + 1, R_ROW_ONE)]), "generic": pad(n, [n - 1, n + 2, n - 2]),
		"methods": {"pascal-build": method(["The top row, 1, is row 0, and the row that starts 1, n is row n.",
			"This row starts 1, %d. It has %d entries, one more than n." % [n, n + 1], "So %s." % Answer.text(ans)], ans.values)}}


func u_number_of_terms(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var ans := number("", n + 1)
	var final := "So the expansion has %d terms." % (n + 1)
	return {"asked": "Write down the number of terms in the expansion of %s, where %s > 0." % [power_text(s), s.letter], "answer": ans,
		"wrongs": rng.shuffled([wn(n, R_N_TERMS)]), "generic": pad(n + 1, [n + 2, n - 1, 2 * n]),
		"methods": {
			"binomial-theorem": method(["Each term is nCr × a^(%d − r) × b^r, with one term for each r." % n, "r runs from 0 to %d, which is %d values." % [n, n + 1], final], ans.values),
			"choose-brackets": method(["Each term is set by how many of the %d brackets give %s." % [n, s.letter], "That can be 0, 1 and so on up to %d brackets: %d choices." % [n, n + 1], final], ans.values),
		}}


# ── Full expansions ──────────────────────────────────────────

## The power order as written: the number first, or x first.
static func written(s: Dictionary) -> Array:
	var up: Array = range(s.n + 1)
	if s.first:
		return up
	up.reverse()
	return up


## r for a term of `order`: counting along the terms, so the term that falls is the first.
static func by_row(s: Dictionary, order: Array, final: String, ans: Dictionary) -> Dictionary:
	var asc: bool = order[0] == 0
	var bits: Array = order.map(func(j): return product(s, j, j, asc).replace("%dC%d" % [s.n, j], str(C(s.n, j))))
	var falls: String = term_b(s) if asc else term_a(s)
	var rises: String = term_a(s) if asc else term_b(s)
	var head := turned(s, asc) + "The power of %s falls from %d as the power of %s rises from 0." % [falls, s.n, rises]
	return method(["Row %d of Pascal's triangle is %s." % [s.n, row_text(s.n)], head + " Term by term: " + " + ".join(bits),
		"= " + " + ".join(order.map(func(j): return worked(s, j, asc))),
		"= " + Fmt.terms(order.map(func(j): return Q.new(coef(s, j))), order.map(func(j): return power_of(s, j))), final], ans.values)


## With the powers of x rising, the number has to come first in the working.
static func turned(s: Dictionary, asc: bool) -> String:
	return "The powers of x rise, so take the number first. " if asc and not s.first else ""


static func by_theorem(s: Dictionary, order: Array, final: String, ans: Dictionary) -> Dictionary:
	var asc: bool = order[0] == 0
	var a: String = term_b(s) if asc else term_a(s)
	var b: String = term_a(s) if asc else term_b(s)
	var steps: Array = [turned(s, asc) + "Each term is nCr × a^(%d − r) × b^r, with a = %s and b = %s." % [s.n, a, b]]
	for i in order.size():
		var j: int = order[i]
		steps.append("r = %d: %s = %s = %s" % [i, product(s, j, i, asc), worked(s, j, asc), full(s, j)])
	steps.append(final)
	return method(steps, ans.values)


static func brackets(i: int) -> String:
	return "1 bracket" if i == 1 else "%d brackets" % i


static func by_choosing(s: Dictionary, order: Array, final: String, ans: Dictionary) -> Dictionary:
	var a := term_a(s)
	var b := term_b(s)
	var steps: Array = ["Every term picks %s or %s from each of the %d brackets." % [a, b, s.n]]
	for j in order:
		var k: int = s.n - j
		var each := term(pw(s.a, j) * pw(s.b, k), power_of(s, j))
		steps.append("%s from %s and %s from %s: %dC%d = %d, and each choice gives %s, so %s" % [a, brackets(j), b, brackets(k), s.n, j, C(s.n, j), each, full(s, j)])
	steps.append(final)
	return method(steps, ans.values)


## The bracket as [[coefficient, power], ...], in the order written.
static func pieces(s: Dictionary) -> Array:
	return [[s.b, 0], [s.a, s.p]] if s.first else [[s.a, s.p], [s.b, 0]]


## The terms of a product, one for each pair, not collected.
static func multiply(xs: Array, ys: Array) -> Array:
	var out: Array = []
	for x in xs:
		for y in ys:
			out.append([x[0] * y[0], x[1] + y[1]])
	return out


## Like terms added, in the order they first come.
static func collect(xs: Array) -> Array:
	var out: Array = []
	for x in xs:
		var found := false
		for y in out:
			if y[1] == x[1]:
				y[0] += x[0]
				found = true
		if not found:
			out.append([x[0], x[1]])
	return out


static func sum_text(xs: Array) -> String:
	return Fmt.terms(xs.map(func(x): return Q.new(x[0])), xs.map(func(x): return x[1]))


## n is 2 or 3, so the brackets multiply out in a line or two.
static func by_multiplying(s: Dictionary, final: String, ans: Dictionary) -> Dictionary:
	var b := bracket(s)
	var one := pieces(s)
	var two := multiply(one, one)
	var square := collect(two)
	var steps: Array = ["%s² = %s%s" % [b, b, b], "= " + sum_text(two), "= " + sum_text(square)]
	if s.n == 3:
		var three := multiply(square, one)
		steps = ["%s³ = %s² × %s" % [b, b, b], "%s² = %s%s = %s = %s" % [b, b, b, sum_text(two), sum_text(square)],
			"(%s)%s = %s" % [sum_text(square), b, sum_text(three)], "= " + sum_text(collect(three))]
	steps.append(final)
	return method(steps, ans.values)


func _expand(s: Dictionary, asked: String, rng: Seeded) -> Dictionary:
	var order := written(s)
	var ans := expansion(s, order)
	var out := expansion_options(s, order, rng)
	out.asked = asked
	out.answer = ans
	var final := "So %s = %s." % [power_text(s), Answer.text(ans)]
	out.methods = {"pascal-row": by_row(s, order, final, ans), "binomial-theorem": by_theorem(s, order, final, ans),
		"choose-brackets": by_choosing(s, order, final, ans)}
	return out


func _expand_asked(s: Dictionary) -> String:
	return "Expand and simplify %s." % power_text(s)


func u_expand_small(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := _expand(s, _expand_asked(s), rng)
	var final := "So %s = %s." % [power_text(s), Answer.text(out.answer)]
	out.methods["repeated-multiply"] = by_multiplying(s, final, out.answer)
	return out


func u_expand_unit(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _expand(s, _expand_asked(s), rng)


func u_expand_negative(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _expand(s, _expand_asked(s), rng)


func u_expand_raised(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _expand(s, _expand_asked(s), rng)


func u_expand_from_triangle(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := _expand(s, "Use Pascal's triangle to expand and simplify %s." % power_text(s), rng)
	out.table = triangle(s.n)
	return out


func u_expand_power(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _expand(s, _expand_asked(s), rng)


func u_expand_reciprocal(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _expand(s, "Expand %s and simplify each term." % power_text(s), rng)


func u_first_three_terms(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var order := [0, 1, 2]
	var ans := expansion(s, order)
	var out := expansion_options(s, order, rng)
	out.asked = "Write down the first three terms, in ascending powers of x, of the expansion of %s." % power_text(s)
	out.answer = ans
	var final := "So the first three terms are %s." % Answer.text(ans)
	out.methods = {"pascal-row": by_row(s, order, final, ans), "binomial-theorem": by_theorem(s, order, final, ans)}
	return out


# ── One term ─────────────────────────────────────────────────

## The steps from the general term to the term with j brackets giving x. why is the step that
## finds r; left out, it's worked from the power of x.
static func general_steps(s: Dictionary, j: int, why: String = "") -> Array:
	var n: int = s.n
	var one: String = base_b(s) if s.first else base_a(s)
	var two: String = base_a(s) if s.first else base_b(s)
	var r: int = j if s.first else n - j
	var head := "The general term of %s is %dCr × %s^(%d − r) × %s^r." % [power_text(s), n, one, n, two]
	var target: int = power_of(s, j)
	if why == "":
		if s.first:
			why = "%s needs r = %d." % [x_text(target), r] if s.p == 1 else "%s needs 2r = %d, so r = %d." % [x_text(target), target, r]
		else:
			why = "%s needs %d − r = %d, so r = %d." % [x_text(target), n, target, r] if s.p == 1 \
				else "%s needs 2(%d − r) = %d, so r = %d." % [x_text(target), n, target, r]
	return [head, why, "%s = %s" % [product(s, j, r, s.first), worked(s, j, s.first)], "= " + full(s, j)]


## The steps reading the number from the row.
static func row_steps(s: Dictionary, j: int) -> Array:
	var r: int = j if s.first else s.n - j
	var a := raised(base_a(s), j) if j > 0 else ""
	var b := raised(base_b(s), s.n - j) if s.n > j else ""
	var powers: Array = ([b, a] if s.first else [a, b]).filter(func(t): return t != "")
	return ["Row %d of Pascal's triangle is %s." % [s.n, row_text(s.n)],
		"The term with %s uses entry %d of the row, counting from 0, which is %d." % [" and ".join(powers), r, C(s.n, r)],
		"%s = %s" % [worked(s, j, s.first), full(s, j)]]


## The steps counting brackets.
static func choose_steps(s: Dictionary, j: int) -> Array:
	var n: int = s.n
	var k: int = n - j
	var each := pw(s.a, j) * pw(s.b, k)
	return ["%s needs %s from %d of the %d brackets, and %s from the other %d." % [x_text(power_of(s, j)), term_a(s), j, n, term_b(s), k],
		"There are %dC%d = %d ways to choose those brackets." % [n, j, C(n, j)],
		"Each way gives %s × %s = %s." % [raised(base_a(s), j), raised(base_b(s), k), term(each, power_of(s, j))],
		"%d × %s = %s" % [C(n, j), bare(each), N(coef(s, j))]]


## The slips a single coefficient can show, in order of a shuffle.
static func term_slips(s: Dictionary, j: int, make: Callable) -> Array:
	var n: int = s.n
	var c := coef(s, j)
	var w: Array = []
	if c < 0:
		w.append(make.call(-c, R_SIGN))
	if absi(s.b) > 1 and n - j >= 2:
		w.append(make.call(C(n, j) * pw(s.a, j) * s.b, R_OTHER))
	if absi(s.a) > 1 and j >= 2:
		w.append(make.call(C(n, j) * s.a * pw(s.b, n - j), R_UNRAISED))
	if j != n - j and absi(s.b) > 1:
		w.append(make.call(C(n, j) * pw(s.a, j) * pw(s.b, j), R_POWERS))
	return w


func _coefficient(s: Dictionary, asked: String, rng: Seeded) -> Dictionary:
	var j: int = s.j
	var c := coef(s, j)
	var ans := number("", c)
	var final := "So the coefficient of %s is %s." % [x_text(power_of(s, j)), N(c)]
	var w: Array = term_slips(s, j, func(v, ref): return wn(v, ref)) + [alt(full(s, j), R_TERM)]
	return {"asked": asked, "answer": ans, "wrongs": rng.shuffled(w),
		"generic": pad(c, [coef(s, j + 1), coef(s, j - 1), C(s.n, j), pw(s.a, j) * pw(s.b, s.n - j)]),
		"methods": {"general-term": method(general_steps(s, j) + [final], ans.values),
			"pascal-select": method(row_steps(s, j) + [final], ans.values),
			"choose-brackets": method(choose_steps(s, j) + [final], ans.values)}}


func _coefficient_asked(s: Dictionary) -> String:
	return "Find the coefficient of %s in the expansion of %s." % [x_text(power_of(s, s.j)), power_text(s)]


func u_coefficient_plain(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _coefficient(s, _coefficient_asked(s), rng)


func u_coefficient_negative(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _coefficient(s, _coefficient_asked(s), rng)


func u_coefficient_raised(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _coefficient(s, _coefficient_asked(s), rng)


func u_coefficient_from_triangle(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := _coefficient(s, "Use Pascal's triangle to find the coefficient of %s in the expansion of %s." % [x_text(power_of(s, s.j)), power_text(s)], rng)
	out.table = triangle(s.n)
	return out


func u_coefficient_power(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _coefficient(s, _coefficient_asked(s), rng)


func u_coefficient_letter(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var j: int = s.j
	var k: int = n - j
	var L: String = s.letter
	var c := C(n, j)
	var ans := with_tail(c, k, L)
	var x := x_text(j)
	var tail := term(1, k, L)
	var final := "So the coefficient of %s is %s." % [x, Answer.text(ans)]
	return {"asked": "Find the coefficient of %s in the expansion of %s, in terms of %s." % [x, power_text(s), L], "answer": ans,
		"wrongs": rng.shuffled([alt(term(c, j, L), R_POWERS), alt(term(c, k, L) + x, R_TERM), alt(term(c, 1, L), R_OTHER)]),
		"generic": [wt(C(n, j + 1), k, "", L).values, wt(C(n, j - 1), k, "", L).values, wt(c + 1, k, "", L).values, wt(c * 2, k, "", L).values],
		"methods": {
			"general-term": method(["The general term of %s is %dCr × x^(%d − r) × %s^r." % [power_text(s), n, n, L],
				"%s needs %d − r = %d, so r = %d." % [x, n, j, k], "%dC%d × %s × %s = %s%s" % [n, k, x, tail, term(c, k, L), x], final], ans.values),
			"choose-brackets": method(["%s needs x from %d of the %d brackets, and %s from the other %d." % [x, j, n, L, k],
				"There are %dC%d = %d ways to choose those brackets." % [n, j, c], "Each way gives %s × %s, so the term is %s%s." % [x, tail, term(c, k, L), x], final], ans.values),
		}}


## A term as the answer, for specific-term and term-by-position.
func _term_answer(s: Dictionary, j: int, asked: String, say: String, why: String, rng: Seeded) -> Dictionary:
	var c := coef(s, j)
	var power: int = power_of(s, j)
	var ans := with_tail(c, power)
	var final := "%s is %s." % [say, Answer.text(ans)]
	var w: Array = term_slips(s, j, func(v, ref): return wt(v, power, ref)) + [alt(N(c), R_TERM)]
	return {"asked": asked, "answer": ans, "wrongs": rng.shuffled(w), "generic": pad_term(c, power, [C(s.n, j), pw(s.a, j) * pw(s.b, s.n - j)]),
		"methods": {"general-term": method(general_steps(s, j, why) + [final], ans.values),
			"pascal-select": method(row_steps(s, j) + [final], ans.values),
			"choose-brackets": method(choose_steps(s, j) + [final], ans.values)}}


func u_specific_term(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var x := x_text(power_of(s, s.j))
	return _term_answer(s, s.j, "Find the term in %s in the expansion of %s." % [x, power_text(s)], "So the term in %s" % x, "", rng)


func u_term_by_position(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var pos: int = s.pos
	var name := BinomialViews.ordinal(pos)
	var asked := "The expansion of %s is written in descending powers of x. Find the %s term." % [power_text(s), name]
	var why := "The first term has r = 0, so the %s term has r = %d." % [name, pos - 1]
	var out := _term_answer(s, s.j, asked, "So the %s term" % name, why, rng)
	out.wrongs = rng.shuffled(out.wrongs + [alt(full(s, s.j - 1), R_PLACE)])
	out.generic = [alt(full(s, s.j + 1)).values] + out.generic
	return out


func u_missing_coefficient(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var j: int = s.j
	var pick: int = s.pick
	var name: String = ["p", "q"][pick - 1]
	var c := coef(s, j)
	var ans := number(name + " = ", c)
	var line := "%s = %s + p%s + q%s + ... + %d" % [power_text(s), x_text(n), x_text(n - 1), x_text(n - 2), pw(s.b, n)]
	var other := coef(s, n - (3 - pick))
	var final := "So %s." % Answer.text(ans)
	var w: Array = [wn(C(n - 1, pick) * pw(s.b, pick), R_ROW_ONE)]
	if pick == 2 and s.b > 1:
		w.append(wn(C(n, pick) * s.b, R_OTHER))
	return {"lines": [line], "asked": "Find the value of %s." % name, "answer": ans, "wrongs": rng.shuffled(w),
		"generic": pad(c, [other, C(n, pick), C(n + 1, pick) * pw(s.b, pick), n]),
		"methods": {"general-term": method(general_steps(s, j) + [final], ans.values),
			"pascal-select": method(row_steps(s, j) + [final], ans.values)}}
