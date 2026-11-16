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
##
## t1-ext-binomial-constant-term and t1-ext-binomial-product (FAL-779) are built here too, as
## unknowns of their own (BinomialExpansionSituation.CONSTANT and PRODUCT), so t1-binomial-term's
## cells and numbers are as before. Their wrong options are wrongs with a slip or declared
## fillers, never `generic`. They build method-pick, and error-spot where the catalogue has one;
## order-steps and multipart aren't built in the engine.

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
## t1-binomial-term's own slips for the options that had no line (FAL-820).
const R_NO_NCR := "t1-binomial-term#14"
const R_POWERS_SWAPPED := "t1-binomial-term#15"
const R_SIGNS_MOVED := "t1-binomial-term#16"
const R_NCR_ALONE := "t1-binomial-term#17"
const R_ENTRY_ONE := "t1-binomial-term#18"
const R_ADD_R := "t1-binomial-term#19"
const R_ALL_ZERO := "t1-binomial-term#20"
const R_EDGE_N := "t1-binomial-term#21"
const R_ABOVE := "t1-binomial-term#22"
const R_OTHER_LETTER := "t1-binomial-term#23"

const UNKNOWNS := ["ncr-value", "ncr-read-triangle", "ncr-large-r", "ncr-symmetry", "ncr-edge", "ncr-find-n",
	"ncr-formula-in-n", "pascal-row", "pascal-next-row", "row-from-entries", "number-of-terms", "expand-small",
	"expand-unit", "expand-negative", "expand-raised", "expand-from-triangle", "expand-power", "expand-reciprocal",
	"first-three-terms", "coefficient-plain", "coefficient-negative", "coefficient-raised",
	"coefficient-from-triangle", "coefficient-power", "coefficient-letter", "specific-term", "missing-coefficient",
	"term-by-position"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS + BinomialExpansionSituation.CONSTANT + BinomialExpansionSituation.PRODUCT:
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
	# No calculator on Paper 1, so a calculator's working isn't shown there.
	if s.paper == 1:
		out.methods.erase("gdc-ncr")
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
	w.append(wp(s, order, func(j): return pw(a, j) * pw(b, n - j), R_NO_NCR))
	w.append(wp(s, order, func(j): return C(n, j) * pw(b, j) * pw(a, n - j), R_POWERS_SWAPPED))
	w.append(wp(s, order, func(j): return coef(s, j) * (-1 if (n - j) % 2 == 1 else 1), R_SIGNS_MOVED))
	var g: Array = [
		wp(s, order, func(j): return coef(s, j) + (1 if j == order[0] else 0)).values,
		wp(s, order, func(j): return coef(s, j) * 2).values,
	]
	return {"wrongs": rng.shuffled(w), "fillers": g}


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
		"fillers": pad(v, [C(n, r + 1), C(n, r - 1), C(n - 1, r), C(n + 1, r)]),
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
		"wrongs": rng.shuffled([wn(C(n - 1, r), R_ROW_ONE)] + ([wn(C(n, r - 1), R_ENTRY_ONE)] if r > 0 else [])),
		"fillers": pad(v, [C(n + 1, r), C(n, r + 1)]),
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
		"fillers": pad(v, [C(n, r - 1), C(n, r + 1), n, C(n - 1, r)]),
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
	var near: Array = [m + 1, m - 1, n, r + 1, m + 2].filter(func(x): return x != r and x != m)
	return {"asked": "%dC%d = %dCm, where m ≠ %d. Find m." % [n, r, n, r], "answer": ans,
		"wrongs": [wn(n + r, R_ADD_R)], "fillers": near.map(func(x): return wn(x).values),
		"methods": {"symmetry": method(["Choosing %d from %d to take is the same as choosing %d to leave, so nCr = nC(n − r)." % [r, n, m],
			"%dC%d = %dC(%d − %d) = %dC%d" % [n, r, n, n, r, n, m], "So %s." % Answer.text(ans)], ans.values)}}


func u_ncr_edge(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var r: int = s.r
	var ans := number("%dC%d = " % [n, r], 1)
	var final := "So %s." % Answer.text(ans)
	return {"asked": "Find the value of %dC%d." % [n, r], "answer": ans,
		"wrongs": [wn(0, R_ZERO if r == 0 else R_ALL_ZERO), wn(n, R_EDGE_N)], "fillers": pad(1, [n + 1, n - 1]),
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
		"wrongs": rng.shuffled(w), "fillers": pad(n, [n + 1, n - 1, v, 2 * v]),
		"methods": {
			"factorial-formula": method(["nC2 = n!/(2! × (n − 2)!) = n(n − 1)/2", "n(n − 1)/2 = %d, so n² − n − %d = 0" % [v, 2 * v],
				"(n − %d)(n + %d) = 0, so n = %d or n = %s" % [n, n - 1, n, N(1 - n)], "n is a whole number, so it can't be negative. " + final], ans.values),
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
		"wrongs": rng.shuffled([make.call(-1, 1, R_NO_R), make.call(1, 2, R_ABOVE)]),
		"fillers": [make.call(-2, 2).values, make.call(0, 2).values, make.call(1, 1).values],
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
		"fillers": [alt(row_text(n + 1)).values, alt(row_text(n + 2)).values, row_off(ans, n, 2), row_off(ans, n, -1)],
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
		"fillers": [alt(row_text(n)).values, alt(row_text(m + 1)).values, row_off(ans, m, 2), row_off(ans, m, -1), row_off(ans, m, 1)],
		"methods": {"pascal-build": method(["The last row shown is %s." % row_text(n),
			"Each entry of the next row is the sum of the two above it: %s, with a 1 at each end." % ", ".join(sums),
			"So the next row is %s." % Answer.text(ans)], ans.values)}}


func u_row_from_entries(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var ans := number("n = ", n)
	return {"asked": "This row of Pascal's triangle gives the coefficients of (a + b)^n. Find n.", "answer": ans,
		"table": {"rows": [["", row(n).map(func(v): return str(v))]]},
		"wrongs": rng.shuffled([wn(n + 1, R_ROW_ONE)]), "fillers": pad(n, [n - 1, n + 2, n - 2]),
		"methods": {"pascal-build": method(["The top row, 1, is row 0, and the row that starts 1, n is row n.",
			"This row starts 1, %d. It has %d entries, one more than n." % [n, n + 1], "So %s." % Answer.text(ans)], ans.values)}}


func u_number_of_terms(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var ans := number("", n + 1)
	var final := "So the expansion has %d terms." % (n + 1)
	return {"asked": "Write down the number of terms in the expansion of %s, where %s > 0." % [power_text(s), s.letter], "answer": ans,
		"wrongs": rng.shuffled([wn(n, R_N_TERMS)]), "fillers": pad(n + 1, [n + 2, n - 1, 2 * n]),
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
	var w: Array = term_slips(s, j, func(v, ref): return wn(v, ref)) + [alt(full(s, j), R_TERM), wn(C(s.n, j), R_NCR_ALONE),
		wn(pw(s.a, j) * pw(s.b, s.n - j), R_NO_NCR)]
	return {"asked": asked, "answer": ans, "wrongs": rng.shuffled(w),
		"fillers": pad(c, [coef(s, j + 1), coef(s, j - 1)]),
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
		"fillers": [wt(C(n, j + 1), k, "", L).values, wt(C(n, j - 1), k, "", L).values, wt(c + 1, k, "", L).values, wt(c * 2, k, "", L).values],
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
	var w: Array = term_slips(s, j, func(v, ref): return wt(v, power, ref)) + [alt(N(c), R_TERM), wt(C(s.n, j), power, R_NCR_ALONE),
		wt(pw(s.a, j) * pw(s.b, s.n - j), power, R_NO_NCR)]
	return {"asked": asked, "answer": ans, "wrongs": rng.shuffled(w), "fillers": pad_term(c, power),
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
	out.fillers = [alt(full(s, s.j + 1)).values] + out.fillers
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
	w.append(wn(other, R_OTHER_LETTER))
	w.append(wn(C(n, pick), R_NCR_ALONE))
	return {"lines": [line], "asked": "Find the value of %s." % name, "answer": ans, "wrongs": rng.shuffled(w),
		"fillers": pad(c, [C(n + 1, pick) * pw(s.b, pick), n]),
		"methods": {"general-term": method(general_steps(s, j) + [final], ans.values),
			"pascal-select": method(row_steps(s, j) + [final], ans.values)}}


# ── x in both terms (t1-ext-binomial-constant-term, FAL-779) ─
# (ax^p + k/x^q)^n: the term with the fraction to the power r is nCr a^(n − r) k^r x^(pn − (p + q)r).
# Its answers are whole numbers (r, a coefficient) or the power of x in r, and its wrong options
# are SL1.9.constant-term's slips and the type's own.

const CT_MAPREF := "SL1.9.constant-term#"
const CT_OWN := "t1-ext-binomial-constant-term#"
const R_CT_NEG := CT_MAPREF + "0"
const R_CT_TOP := CT_MAPREF + "1"
const R_CT_R := CT_MAPREF + "2"
const R_CT_FIRST := CT_OWN + "3"
const R_CT_POW := CT_OWN + "4"
const R_CT_SIGN := CT_OWN + "5"
const R_CT_UNRAISED := CT_OWN + "6"
const R_CT_TERM := CT_OWN + "7"
const R_CT_SPOT_UP := CT_OWN + "8"
const R_CT_SPOT_TOP := CT_OWN + "9"
## Methods that don't work on any of these brackets, for method-pick.
const CT_PICK_WRONGS := [
	{"name": "Set the power of the first term alone to the power asked", "why": "the fraction carries x too, so the first term's power is not the power of the term"},
	{"name": "Raise both terms to the power n and multiply them", "why": "each term of the expansion takes the two terms to powers that add up to n, not both to n"},
	{"name": "Read the answer from row n of Pascal's triangle alone", "why": "the numbers in the bracket are raised to their powers too, so nCr is only part of the term"},
]

# ── A bracket times an expansion (t1-ext-binomial-product, FAL-779) ─

const PR_MAPREF := "SL1.9.product-expansion#"
const PR_OWN := "t1-ext-binomial-product#"
const R_PR_ONE := PR_MAPREF + "0"
const R_PR_SAME := PR_MAPREF + "1"
const R_PR_SIGN := PR_MAPREF + "2"
const R_PR_PAIR := PR_OWN + "3"
const R_PR_ADD := PR_OWN + "4"
const R_PR_X2 := PR_OWN + "5"
const R_PR_SPOT := PR_OWN + "6"
const PR_PICK_WRONGS := [
	{"name": "Multiply the coefficients of the asked power in the two brackets", "why": "the terms that multiply are those whose powers add up to the power asked"},
	{"name": "Find the coefficient in the expansion alone", "why": "each term of the first bracket pairs with a different term of the expansion, and both pairs count"},
	{"name": "Put x = 1 in both brackets", "why": "that gives the sum of all the coefficients, not one of them"},
]


func extra() -> Dictionary:
	var out := {}
	for u in BinomialExpansionSituation.CONSTANT + BinomialExpansionSituation.PRODUCT:
		out[u] = ["method-pick"]
	for u in ["ct-find-r", "ct-constant", "pr-linear", "pr-small"]:
		out[u] = ["error-spot", "method-pick"]
	return out


## A wrong whole number, or a wrong r, kept once and only where it isn't the answer.
static func ext_wrongs(v: int, list: Array) -> Array:
	var seen := {v: true}
	var out: Array = []
	for e in list:
		if seen.has(e[0]):
			continue
		seen[e[0]] = true
		out.append(wn(e[0], e[1]))
	return out


## Fillers: the answer scaled or nudged, never a slip already offered.
static func ext_fillers(v: int, wrongs: Array, list: Array) -> Array:
	var seen := {v: true}
	for w in wrongs:
		if w.values.has("v"):
			seen[int(Q.of(w.values.v).to_float())] = true
	var out: Array = []
	for x in list:
		if not seen.has(x):
			seen[x] = true
			out.append(wn(x).values)
	return out


## A term wrapped in brackets when it is negative, to multiply by: (−3x), 60x².
static func par(t: String) -> String:
	return "(%s)" % t if t.begins_with("−") else t


static func ct_xq(s: Dictionary) -> String:
	return x_text(s.q)


## (x² + 3/x)⁹, (2x − 3/x²)⁶.
static func ct_bracket(s: Dictionary) -> String:
	return "(%s %s %d/%s)%s" % [term(s.a, s.p), "+" if s.b > 0 else "−", absi(s.b), ct_xq(s), Fmt.sup(s.n)]


static func ct_first_base(s: Dictionary) -> String:
	return "x" if s.a == 1 and s.p == 1 else "(%s)" % term(s.a, s.p)


static func ct_frac_base(s: Dictionary) -> String:
	return "(%s/%s)" % [N(s.b), ct_xq(s)]


## 3r, r.
static func times_r(c: int) -> String:
	return "r" if c == 1 else "%dr" % c


## The power of x in the general term: 18 − 3r.
static func ct_expo(s: Dictionary) -> String:
	return "%d − %s" % [s.p * s.n, times_r(s.p + s.q)]


## 9Cr × (x²)^(9 − r) × (3/x)^r
static func ct_general(s: Dictionary) -> String:
	return "%dCr × %s^(%d − r) × %s^r" % [s.n, ct_first_base(s), s.n, ct_frac_base(s)]


## The general term with its powers of x collected: 9Cr × 3^r × x^(18 − 3r).
static func ct_collected(s: Dictionary) -> String:
	var bits: Array = ["%dCr" % s.n]
	if s.a != 1:
		bits.append("%d^(%d − r)" % [s.a, s.n])
	bits.append("%s^r" % P(s.b))
	bits.append("x^(%s)" % ct_expo(s))
	return " × ".join(bits)


## "The constant term", "The term in x³".
static func ct_name(m: int) -> String:
	return "the constant term" if m == 0 else "the term in %s" % x_text(m)


## 9C6 × 3⁶ = 84 × 729 = 61236, with the number beside x where there is one.
static func ct_value_line(s: Dictionary, r: int) -> String:
	var parts: Array = ["%dC%d" % [s.n, r]]
	var nums: Array = [str(C(s.n, r))]
	if s.a != 1:
		parts.append(raised(str(s.a), s.n - r))
		nums.append(str(pw(s.a, s.n - r)))
	parts.append(raised(P(s.b), r))
	nums.append(bare(pw(s.b, r)))
	return "%s = %s = %s" % [" × ".join(parts), " × ".join(nums), N(BinomialExpansionSituation.ct_coef(s, r))]


## The steps to r by setting the power of x: the general term collected, then the equation.
static func ct_eq_steps(s: Dictionary) -> Array:
	return ["The general term is %s = %s." % [ct_general(s), ct_collected(s)],
		"%s needs %s = %s, so r = %d." % [_cap(ct_name(s.m)), ct_expo(s), N(s.m), s.r]]


static func _cap(t: String) -> String:
	return t.substr(0, 1).to_upper() + t.substr(1)


## The steps to r by listing the power of x for each r.
static func ct_table_steps(s: Dictionary) -> Array:
	var start := "The first term has %s" % x_text(s.p * s.n)
	var powers: Array = range(s.r + 1).map(func(r): return N(BinomialExpansionSituation.ct_power(s, r)))
	return ["%s; each step up in r swaps one %s for one %s/%s, so the power falls by %d + %d = %d." % [start, term(s.a, s.p), N(s.b), ct_xq(s), s.p, s.q, s.p + s.q],
		"The powers run %s, so %s is at r = %d." % [", ".join(powers), ct_name(s.m), s.r]]


## The steps by symmetry: the powers fall from x^(pn) to x^(−pn) evenly.
static func ct_middle_steps(s: Dictionary) -> Array:
	return ["The powers of x fall by %d from %s to %s, symmetric about 0, so the constant term is the middle one." % [s.p + s.q, x_text(s.p * s.n), x_text(-s.q * s.n)],
		"There are %d terms, so the middle one has r = %d." % [s.n + 1, s.r]]


## The coefficient's slips: the fraction's x left out, the top unraised, r given, the sign lost,
## the number beside x unraised.
static func ct_slips(s: Dictionary) -> Array:
	var n: int = s.n
	var r: int = s.r
	var c := BinomialExpansionSituation.ct_coef(s, r)
	var list: Array = []
	if s.m % s.p == 0:
		var r2: int = n - s.m / s.p
		if r2 >= 0 and r2 <= n and r2 != r:
			list.append([BinomialExpansionSituation.ct_coef(s, r2), R_CT_NEG])
	list.append([C(n, r) * pw(s.a, n - r), R_CT_TOP])
	list.append([r, R_CT_R])
	if c < 0:
		list.append([-c, R_CT_SIGN])
	if s.a > 1:
		list.append([C(n, r) * s.a * pw(s.b, r), R_CT_UNRAISED])
	return list


func _ct_pack(s: Dictionary, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary) -> Dictionary:
	var out := {"asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {}, "pick_wrongs": CT_PICK_WRONGS}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


## The power of x as a typed pn − cr.
static func expo_values(top: int, c: int) -> Dictionary:
	return {"c": Q.new(top), "d": Q.new(c), "text": "%d − %s" % [top, times_r(c)]}


func u_ct_power_of_x(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var top: int = s.p * s.n
	var c: int = s.p + s.q
	var ans := Answer.make("form", expo_values(top, c), {"parts": [{"slot": "c"}, " − ", {"slot": "d"}, "r"]})
	ans.exact = true
	var w: Array = [wrong(expo_values(top, s.p), R_CT_NEG)]
	if s.p > 1:
		w.append(wrong(expo_values(s.n, 1 + s.q), R_CT_POW))
	var fill: Array = [expo_values(top, c + 1), expo_values(top + 1, c), expo_values(2 * top, c), expo_values(top, 2 * c)]
	var first := "%s^(%d − r) = x^(%d − %s)" % [ct_first_base(s), s.n, top, times_r(s.p)] if s.p > 1 else "x^(%d − r)" % s.n
	var final := "So the power of x is %s." % Answer.text(ans)
	return _ct_pack(s, "The general term of the expansion of %s is %s. Find the power of x in this term, in terms of r." % [ct_bracket(s), ct_general(s)],
		ans, rng.shuffled(w), fill, {
		"exponent-equation": ["%s, and %s^r = %s^r × x^(−%s)." % [first, ct_frac_base(s), P(s.b), times_r(s.q)],
			"Add the powers of x: %d − %s − %s = %s." % [top, times_r(s.p), times_r(s.q), ct_expo(s)], final],
		"power-table": [ct_table_steps(s)[0], "After r steps the power is %d − %d × r = %s." % [top, c, ct_expo(s)], final],
	})


func u_ct_find_r(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var r: int = s.r
	var ans := number("r = ", r)
	var list: Array = [[n, R_CT_NEG], [n - r, R_CT_FIRST]]
	if s.p > 1 and n % (1 + s.q) == 0:
		list.append([n / (1 + s.q), R_CT_POW])
	var w := ext_wrongs(r, list)
	var final := "So %s." % Answer.text(ans)
	var out := _ct_pack(s, "The general term of the expansion of %s is %s. Find the value of r for which the term is independent of x." % [ct_bracket(s), ct_general(s)],
		ans, rng.shuffled(w), ext_fillers(r, w, [r + 1, r - 1, r + 2, 2 * r]), {
		"exponent-equation": ct_eq_steps(s) + [final],
		"power-table": ct_table_steps(s) + [final],
	})
	out.spot = _ct_spot_up(s, rng)
	return out


## The working that writes the fraction's power of x as positive: on its own line, or with the
## powers collected.
static func _ct_spot_up(s: Dictionary, rng: Seeded) -> Dictionary:
	var top: int = s.p * s.n
	var diff: int = s.p - s.q
	var bad_expo := "%d − %s" % [top, times_r(diff)] if diff > 0 else "%d + %s" % [top, times_r(-diff)]
	var bad_r := Q.new(top, diff)
	var first := "The general term is %s" % ct_general(s)
	var up := "x^r" if s.q == 1 else "x^(%s)" % times_r(s.q)
	var lines: Array
	var bad: int
	if rng.chance(0.5):
		lines = [first, "%s^r = %s^r × %s" % [ct_frac_base(s), P(s.b), up],
			"The power of x is %d − %s + %s = %s" % [top, times_r(s.p), times_r(s.q), bad_expo], "%s = 0, so r = %s" % [bad_expo, N(bad_r)]]
		bad = 1
	else:
		var solve := "r = %s" % N(bad_r) if absi(diff) == 1 else "%s = %s, so r = %s" % [times_r(absi(diff)), N(top if diff > 0 else -top), N(bad_r)]
		lines = ["%s^(%d − r) × %s^r = %s^r × x^(%s)" % [ct_first_base(s), s.n, ct_frac_base(s), P(s.b), bad_expo],
			"So the power of x is %s" % bad_expo, "The constant term needs %s = 0" % bad_expo, solve]
		bad = 0
	return {"lines": lines, "bad": bad, "ref": R_CT_SPOT_UP, "why": "a power of x in the denominator is a negative power, so %s^r = %s^r × x^(−%s)" % [ct_frac_base(s), P(s.b), times_r(s.q)]}


func _ct_coefficient(s: Dictionary, asked: String, rng: Seeded, middle: bool) -> Dictionary:
	var c := BinomialExpansionSituation.ct_coef(s, s.r)
	var ans := number("", c)
	var w := ext_wrongs(c, ct_slips(s))
	var final := "So %s is %s." % [ct_name(s.m), N(c)]
	var value := ct_value_line(s, s.r)
	var steps := {
		"exponent-equation": ct_eq_steps(s) + [value, final],
		"power-table": ct_table_steps(s) + [value, final],
	}
	if middle:
		steps["middle-term"] = ct_middle_steps(s) + [value, final]
	return _ct_pack(s, asked, ans, rng.shuffled(w), ext_fillers(c, w, [2 * c, c + 1, c - 1, 3 * c]), steps)


func u_ct_middle_constant(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _ct_coefficient(s, "Find the constant term in the expansion of %s." % ct_bracket(s), rng, true)


func u_ct_constant(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := _ct_coefficient(s, "Find the term independent of x in the expansion of %s." % ct_bracket(s), rng, false)
	out.spot = _ct_spot_top(s, rng)
	return out


## The working that leaves the top of the fraction unraised: in the general term, or in the term found.
static func _ct_spot_top(s: Dictionary, rng: Seeded) -> Dictionary:
	var r: int = s.r
	var slip: int = C(s.n, r) * s.b
	var gen := "%s^(%d − r) × %s^r" % [ct_first_base(s), s.n, ct_frac_base(s)]
	var lines: Array
	var bad: int
	if rng.chance(0.5):
		lines = ["%s = %s^r × x^(%s)" % [gen, P(s.b), ct_expo(s)], "%s = 0, so r = %d" % [ct_expo(s), r],
			"%s%s = %s/%s" % [ct_frac_base(s), Fmt.sup(r), N(s.b), x_text(s.q * r)], "The constant term is %dC%d × %s = %s" % [s.n, r, P(s.b), N(slip)]]
		bad = 2
	else:
		lines = ["%s = %s × x^(%s)" % [gen, P(s.b), ct_expo(s)], "%s = 0, so r = %d" % [ct_expo(s), r],
			"%dC%d = %d" % [s.n, r, C(s.n, r)], "The constant term is %d × %s = %s" % [C(s.n, r), P(s.b), N(slip)]]
		bad = 0
	return {"lines": lines, "bad": bad, "ref": R_CT_SPOT_TOP, "why": "the top of the fraction is raised to the power too, so %s^r = %s^r × x^(−%s)" % [ct_frac_base(s), P(s.b), times_r(s.q)]}


func u_ct_constant_raised(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _ct_coefficient(s, "Find the constant term in the expansion of %s." % ct_bracket(s), rng, false)


func u_ct_given_power(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := _ct_coefficient(s, "Find the coefficient of %s in the expansion of %s." % [x_text(s.m), ct_bracket(s)], rng, false)
	var c := BinomialExpansionSituation.ct_coef(s, s.r)
	out.wrongs = rng.shuffled(out.wrongs + [alt(term(c, s.m), R_CT_TERM)])
	for m in out.methods.values():
		m.steps[-1] = "So the coefficient of %s is %s." % [x_text(s.m), N(c)]
	return out


# ── A bracket times an expansion (t1-ext-binomial-product) ─────

static func pr_first(s: Dictionary) -> String:
	if s.ask == "pr-reciprocal":
		return "(%s)" % Fmt.terms([1, s.fa], [2, 0])
	return "(%s)" % Fmt.terms([s.fa, s.fb], [0, s.d])


static func pr_exp(s: Dictionary) -> String:
	if s.ask == "pr-reciprocal":
		return "(x %s %d/x)%s" % ["+" if s.rk > 0 else "−", absi(s.rk), Fmt.sup(s.n)]
	return "(%s)%s" % [Fmt.terms([s.ea, s.eb], [0, 1]), Fmt.sup(s.n)]


static func pr_text(s: Dictionary) -> String:
	return pr_first(s) + pr_exp(s)


static func pc(s: Dictionary, j: int) -> int:
	return BinomialExpansionSituation.pr_coef(s, j)


## "the x³ term", "the constant term".
static func pr_name(j: int) -> String:
	return "the constant term" if j == 0 else "the %s term" % x_text(j)


## 6C3 × 2² × (−x)³ = −160x³: the term in x^j of (ea + eb·x)^n.
static func pr_term_eq(s: Dictionary, j: int) -> String:
	var bits: Array = ["%dC%d" % [s.n, j]]
	if s.ea != 1 and s.n > j:
		bits.append(raised(str(s.ea), s.n - j))
	if j > 0:
		bits.append(raised("x" if s.eb == 1 else "(%s)" % term(s.eb, 1), j))
	return "%s = %s" % [" × ".join(bits), term(pc(s, j), j)]


## The two pairs multiplied and added: 2 × 160x³ + (−3x) × 60x² = 320x³ − 180x³.
static func pr_pair_sum(s: Dictionary) -> String:
	var m: int = s.m
	var j: int = m - s.d
	return "%s × %s + %s × %s = %s" % [N(s.fa), par(term(pc(s, m), m)), par(term(s.fb, s.d)), par(term(pc(s, j), j)),
		Fmt.terms([s.fa * pc(s, m), s.fb * pc(s, j)], [m, m])]


## The expansion from the constant up to x^m: 1 + 12x + 60x² + 160x³ + …
static func pr_upto(s: Dictionary, m: int) -> String:
	var cs: Array = range(m + 1).map(func(j): return Q.new(pc(s, j)))
	return Fmt.terms(cs, range(m + 1))


static func pr_full_poly(s: Dictionary) -> Array:
	var out: Array = []
	for j in s.n + s.d + 1:
		out.append(s.fa * pc(s, j) + s.fb * pc(s, j - s.d))
	return out


func _pr_pack(asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary, lines: Array = []) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {}, "pick_wrongs": PR_PICK_WRONGS}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


## The slips of one coefficient of (fa + fb·x^d)(ea + eb·x)^n.
static func pr_slips(s: Dictionary) -> Array:
	var p := BinomialExpansionSituation.pr_pairs(s)
	var m: int = s.m
	var list: Array = [[p[0], R_PR_ONE]]
	if s.ask == "pr-same-power":
		list.append([s.fb * pc(s, m), R_PR_SAME])
	else:
		list.append([(s.fa + s.fb) * pc(s, m), R_PR_PAIR])
	list.append([absi(p[0]) + absi(p[1]), R_PR_SIGN])
	return list


func _pr_coefficient(s: Dictionary, rng: Seeded, full: bool) -> Dictionary:
	var m: int = s.m
	var j: int = m - s.d
	var v := BinomialExpansionSituation.pr_answer(s)
	var ans := number("", v)
	var w := ext_wrongs(v, pr_slips(s))
	var final := "So the coefficient of %s is %s." % [x_text(m), N(v)]
	var steps := {
		"pair-contributions": ["The %s terms come from %s × %s and %s × %s of %s." % [x_text(m), N(s.fa), pr_name(m), term(s.fb, s.d), pr_name(j), pr_exp(s)],
			"%s is %s, and %s is %s." % [_cap(pr_name(m)), pr_term_eq(s, m), pr_name(j), pr_term_eq(s, j)],
			"%s = %s" % [pr_pair_sum(s), term(v, m)], final],
		"partial-expansion": ["Up to %s: %s = %s%s" % [x_text(m), pr_exp(s), pr_upto(s, m), "" if m == s.n else " + ..."],
			"Multiply by %s and keep the %s terms: %s = %s." % [pr_first(s), x_text(m), pr_pair_sum(s), term(v, m)], final],
	}
	if full:
		var all: Array = range(s.n + 1).map(func(i): return Q.new(pc(s, i)))
		var poly: Array = pr_full_poly(s).map(func(c): return Q.new(c))
		steps["full-expansion"] = ["%s = %s" % [pr_exp(s), Fmt.terms(all, range(s.n + 1))],
			"%s(%s) = %s" % [pr_first(s), Fmt.terms(all, range(s.n + 1)), Fmt.terms(poly, range(poly.size()))], final]
	return _pr_pack("Find the coefficient of %s in the expansion of %s." % [x_text(m), pr_text(s)], ans, rng.shuffled(w),
		ext_fillers(v, w, [2 * v, v + 1, v - 1, -v]), steps)


func u_pr_linear(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := _pr_coefficient(s, rng, false)
	out.spot = _pr_spot(s, rng)
	return out


func u_pr_small(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := _pr_coefficient(s, rng, true)
	out.spot = _pr_spot(s, rng)
	return out


func u_pr_same_power(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _pr_coefficient(s, rng, false)


## The working that pairs the x term with the term of the asked power: on its own line, or in the sum.
static func _pr_spot(s: Dictionary, rng: Seeded) -> Dictionary:
	var m: int = s.m
	var cm: int = pc(s, m)
	var slip: int = (s.fa + s.fb) * cm
	var x := x_text(m)
	var first := "%s of %s is %s" % [_cap(pr_name(m)), pr_exp(s), pr_term_eq(s, m)]
	var lines: Array
	var bad: int
	if rng.chance(0.5):
		lines = [first, "%s × %s = %s" % [par(term(s.fb, 1)), par(term(cm, m)), term(s.fb * cm, m)],
			"The %s terms add to %s × %s + %s = %s" % [x, N(s.fa), par(term(cm, m)), par(term(s.fb * cm, m)), term(slip, m)],
			"So the coefficient of %s is %s" % [x, N(slip)]]
		bad = 1
	else:
		lines = [first, "%s of %s is %s" % [_cap(pr_name(m - 1)), pr_exp(s), pr_term_eq(s, m - 1)],
			"%s × %s + %s × %s = %s" % [N(s.fa), par(term(cm, m)), par(term(s.fb, 1)), par(term(cm, m)), term(slip, m)],
			"So the coefficient of %s is %s" % [x, N(slip)]]
		bad = 2
	return {"lines": lines, "bad": bad, "ref": R_PR_SPOT, "why": "%s times the %s term gives a power of x one too high, so %s pairs with %s" % [term(s.fb, 1), x, term(s.fb, 1), pr_name(m - 1)]}


func u_pr_hence(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var m: int = s.m
	var cm: int = pc(s, m)
	var c1: int = pc(s, m - 1)
	var v := BinomialExpansionSituation.pr_answer(s)
	var ans := number("", v)
	var w := ext_wrongs(v, [[s.fa * cm, R_PR_ONE], [(s.fa + s.fb) * cm, R_PR_PAIR], [cm + c1, R_PR_ADD]])
	var line := "In the expansion of %s, the coefficient of %s is %s and the coefficient of %s is %s." % [pr_exp(s), x_text(m), N(cm), x_text(m - 1), N(c1)]
	return _pr_pack("Hence find the coefficient of %s in the expansion of %s." % [x_text(m), pr_text(s)], ans, rng.shuffled(w),
		ext_fillers(v, w, [2 * v, v + 1, v - 1, -v]), {
		"pair-contributions": ["The %s terms come from %s × %s and %s × %s." % [x_text(m), N(s.fa), par(term(cm, m)), term(s.fb, 1), par(term(c1, m - 1))],
			"%s × %s + %s × %s = %s" % [N(s.fa), P(cm), P(s.fb), P(c1), N(v)], "So the coefficient of %s is %s." % [x_text(m), N(v)]],
	}, [line])


func u_pr_reciprocal(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var k: int = s.rk
	var mid := BinomialExpansionSituation.rec_coef(s, 0)
	var low := BinomialExpansionSituation.rec_coef(s, -2)
	var v := BinomialExpansionSituation.pr_answer(s)
	var ans := number("", v)
	var w := ext_wrongs(v, [[s.fa * mid, R_PR_ONE], [BinomialExpansionSituation.rec_coef(s, 2) + s.fa * mid, R_PR_X2],
		[absi(low) + absi(s.fa * mid), R_PR_SIGN]])
	var fr := "(%s/x)" % N(k)
	var r0: int = n / 2
	var sum := "x² × %s + %s × %s = %s" % [par(term(low, -2)), P(s.fa), P(mid), Fmt.terms([low, s.fa * mid], [0, 0])]
	var down: Array = range(r0 + 2).map(func(r): return Q.new(C(n, r) * pw(k, r)))
	var final := "So the constant term is %s." % N(v)
	return _pr_pack("Find the constant term in the expansion of %s." % pr_text(s), ans, rng.shuffled(w),
		ext_fillers(v, w, [2 * v, v + 1, v - 1, -v]), {
		"pair-contributions": ["The general term of %s is %dCr × x^(%d − r) × %s^r = %dCr × %s^r × x^(%d − 2r)." % [pr_exp(s), n, n, fr, n, P(k), n],
			"x⁰ needs r = %d: %dC%d × %s = %s; x⁻² needs r = %d: %dC%d × %s = %s." % [r0, n, r0, raised(P(k), r0), N(mid), r0 + 1, n, r0 + 1, raised(P(k), r0 + 1), N(low)],
			"%s = %s" % [sum, N(v)], final],
		"partial-expansion": ["Down to x⁻²: %s = %s + ..." % [pr_exp(s), Fmt.terms(down, range(r0 + 2).map(func(r): return n - 2 * r))],
			"Multiply by %s and keep the constant terms: %s = %s." % [pr_first(s), sum, N(v)], final],
	})


func u_pr_find_k(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var m: int = s.m
	var cm: int = pc(s, m)
	var c1: int = pc(s, m - 1)
	var V: int = s.V
	var k: int = s.fb
	var ans := Answer.make("number", {"v": Q.new(k)}, {}, "k = ")
	ans.exact = true
	var list: Array = [[Q.new(V, c1), R_PR_ONE], [Q.new(V - cm, cm), R_PR_PAIR]]
	# The expansion's negative term made positive: both coefficients worked with |eb|.
	if s.eb < 0:
		var pos := s.duplicate()
		pos.eb = -s.eb
		var pm := pc(pos, m)
		var p1 := pc(pos, m - 1)
		if p1 != 0:
			list.append([Q.new(V - pm, p1), R_PR_SIGN])
	var w: Array = []
	var seen := {Q.new(k).key(): true}
	for e in list:
		if not seen.has(e[0].key()):
			seen[e[0].key()] = true
			w.append(wrong({"v": e[0]}, e[1]))
	var fill: Array = []
	for x in [-k, k + 1, k - 1, 2 * k]:
		if not seen.has(Q.new(x).key()):
			seen[Q.new(x).key()] = true
			fill.append({"v": Q.new(x)})
	var eq := "%s = %s" % [Fmt.terms([cm, c1], [0, 1], "k"), N(V)]
	var solve := "%s = %s" % [term(c1, 1, "k"), N(V - cm)]
	var final := "So k = %s." % N(k)
	return _pr_pack("The coefficient of %s in the expansion of (1 + kx)%s is %s. Find the value of k." % [x_text(m), pr_exp(s), N(V)], ans, rng.shuffled(w), fill, {
		"pair-contributions": ["The %s terms come from 1 × %s and kx × %s of %s." % [x_text(m), pr_name(m), pr_name(m - 1), pr_exp(s)],
			"%s is %s, and %s is %s." % [_cap(pr_name(m)), pr_term_eq(s, m), pr_name(m - 1), pr_term_eq(s, m - 1)],
			"So %s, which gives %s." % [eq, solve], final],
		"partial-expansion": ["Up to %s: %s = %s + ..." % [x_text(m), pr_exp(s), pr_upto(s, m)],
			"Multiply by (1 + kx): the %s terms give %s, so %s." % [x_text(m), eq, solve], final],
	})
