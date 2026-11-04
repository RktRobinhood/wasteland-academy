class_name DifferentiationViews
extends ExtensionViews
## The views on the `differentiation` situation: one builder per unknown of
## t5-differentiation-rules (FAL-723). A derivative is answered as an expression, the
## `form` answer: the student types its numbers into the expression, and it is marked
## exactly. Only a gradient on Paper 2 is a number to 3 s.f.
##
## Representations: "equation" (y = …, or f(x) = …) and, for a gradient, "words".
## `given` holds the situation's numbers, for the SymPy checker.

const STD := "SL5.6.standard-derivatives"
const CHAIN := "SL5.6.chain-rule"
const PROD := "SL5.6.product-rule"
const QUOT := "SL5.6.quotient-rule"
const SHOW := "SL5.6.show-derivative-form"
const R_COS := STD + "#0"
const R_EXP := STD + "#1"
const R_FRAC := STD + "#2"
const R_NO_INNER := CHAIN + "#0"
const R_LN_SCALE := CHAIN + "#1"
const R_INSIDE := CHAIN + "#2"
const R_UV := PROD + "#0"
const R_ONE_TERM := PROD + "#1"
const R_BAD_FACTOR := PROD + "#2"
const R_FLIP := QUOT + "#0"
const R_NOT_SQUARED := QUOT + "#1"
const R_U_V := QUOT + "#2"
const R_SIGN := SHOW + "#2"
const R_CANCEL := SHOW + "#1"


func needs() -> Dictionary:
	var out := {}
	for u in ["standard-terms", "root-powers", "log-power-terms", "chain-power", "chain-small-power", "chain-function",
			"chain-log-split", "product-functions", "product-polys", "product-powers", "quotient-linear",
			"quotient-functions", "quotient-split", "show-form", "parameter-derivative"]:
		out[u] = {"ask": u}
	for fam in ["chain", "product", "quotient"]:
		out["gradient-" + fam] = {"ask": "gradient", "fam": fam}
	return out


## The bank's Paper 2 rules parts find an expression too, so the harder expressions make
## both papers; a gradient has its own Paper 2 numbers, and the letter p is Paper 2 only.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	if not has(unknown):
		return []
	if unknown == "parameter-derivative":
		return [2]
	return [1, 2] if unknown.begins_with("gradient-") or unknown in ["chain-power", "chain-function", "quotient-functions"] else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = DifferentiationSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

## x to a whole power: "" for 0, "x", "x³", "x⁻²".
static func X(p: int) -> String:
	return "" if p == 0 else "x" + Fmt.sup(p)


## x to a rational power: "x³", "x^(1/2)", "x^(−4/3)".
static func XQ(p: Q) -> String:
	return X(p.n) if p.is_int() else "x^(%s)" % p.text()


## The start of a sum: the coefficient on a body. "3x", "−x", "(3/2)x", "5".
static func T(c: Variant, body: String) -> String:
	var q := Q.of(c)
	if body == "" or body.begins_with("/"):
		return q.text() + body
	var head := Fmt.lead(q)
	for word in ["ln", "sin", "cos"]:
		if body.begins_with(word) and head != "" and head != "−":
			return head + " " + body
	return head + body


## A sum of [coefficient, body] terms, skipping zero terms.
static func SUM(terms: Array) -> String:
	var out := ""
	for t in terms:
		var q := Q.of(t[0])
		if q.is_zero():
			continue
		var mag := q.abs_q()
		var body := T(mag, t[1])
		out += (("−" if q.sign() < 0 else "") if out == "" else (" − " if q.sign() < 0 else " + ")) + body
	return out if out != "" else "0"


## ax + b in brackets.
static func B(a: Variant, b: Variant) -> String:
	return "(%s)" % SUM([[a, "x"], [b, ""]])


## e to a linear power: "e^x", "e^(−2x)".
static func E(a: int) -> String:
	return "e^x" if a == 1 else "e^(%sx)" % Fmt.lead(a)


## e to a whole number: "e³", "e^(−2)".
static func EN(n: int) -> String:
	return "e" + Fmt.sup(n) if n > 0 else "e^(%s)" % Fmt.num(n)


## An expression answer with these slots.
static func form(text: String, parts: Array, slots: Dictionary = {}) -> Dictionary:
	var v := slots.duplicate()
	v.text = text
	var ans := Answer.make("form", v, {"parts": parts})
	ans.exact = true
	return ans


## A wrong option: with slots it can be typed, and without it can only be picked.
static func alt(text: String, ref: String = "", slots: Dictionary = {}) -> Dictionary:
	var v := slots.duplicate()
	v.text = text
	if slots.is_empty():
		v.shape = "other"
	return wrong(v, ref)


static func say(ans: Dictionary, s: String = "So ") -> String:
	return s + Answer.text(ans)


# ── Standard results ─────────────────────────────────────────

func u_standard_terms(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var cos: bool = s.fam == "cos"
	var trig := "cos x" if cos else "sin x"
	var dtrig := "sin x" if cos else "cos x"
	var dc := -c if cos else c
	var f := SUM([[a, "e^x"], [b, "ln x"], [c, trig], [s.d, ""]])
	var dh := "f′(x) = "
	var ans := form(dh + SUM([[a, "e^x"], [b, "/x"], [dc, dtrig]]),
		[dh, {"slot": "c0"}, " e^x + ", {"slot": "c1"}, "/x + ", {"slot": "c2"}, " " + dtrig],
		{"c0": Q.new(a), "c1": Q.new(b), "c2": Q.new(dc)})
	var ws: Array = [alt(dh + SUM([[a, "x e^(x − 1)"], [b, "/x"], [dc, dtrig]]), R_EXP)]
	if cos:
		ws.append(alt(dh + SUM([[a, "e^x"], [b, "/x"], [c, dtrig]]), R_COS, {"c0": Q.new(a), "c1": Q.new(b), "c2": Q.new(c)}))
	var g := func(x: int, y: int, z: int) -> Dictionary:
		return alt(dh + SUM([[x, "e^x"], [y, "/x"], [z, dtrig]]), "", {"c0": Q.new(x), "c1": Q.new(y), "c2": Q.new(z)}).values
	return {"lines": ["f(x) = %s, for x > 0" % f], "asked": "Find f′(x).", "answer": ans, "wrongs": ws,
		"generic": [g.call(a, -b, dc), g.call(-a, b, dc), g.call(a, b, -dc), g.call(a + 1, b, dc), g.call(a, b + 1, dc)],
		"methods": {"booklet-rules": method([
			"Term by term: e^x stays e^x, ln x gives 1/x, and %s gives %s." % [trig, ("−" if cos else "") + dtrig],
			"%s is a constant, so it gives 0." % Fmt.num(s.d) if s.d != 0 else "The sum has no constant term to drop.",
			say(ans)], ans.values)}}


## The root's power, r: 1/2, 1/3, −1/2 or −1/3.
static func root_power(s: Dictionary) -> Q:
	return {"sqrt": Q.new(1, 2), "cbrt": Q.new(1, 3), "invsqrt": Q.new(-1, 2), "invcbrt": Q.new(-1, 3)}[s.fam]


func u_root_powers(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := Q.of(s.a)
	var b := Q.of(s.b)
	var n: int = s.n
	var r := root_power(s)
	var body: String = {"sqrt": "√x", "cbrt": "∛x", "invsqrt": "/√x", "invcbrt": "/∛x"}[s.fam]
	var f: String = SUM([[a, body], [b, "/" + X(n)]])
	var c0 := a.mul(r)
	var e0 := r.sub(1)
	var c1 := b.mul(-n)
	var e1 := Q.new(-n - 1)
	var dh := "f′(x) = "
	var w := func(p: Q, q: Q, u: Q, v: Q) -> String:
		return dh + SUM([[p, XQ(q)], [u, XQ(v)]])
	var ans := form(w.call(c0, e0, c1, e1), [dh, {"slot": "c0"}, "x^", {"slot": "e0"}, " + ", {"slot": "c1"}, "x^", {"slot": "e1"}],
		{"c0": c0, "e0": e0, "c1": c1, "e1": e1})
	var sl := func(p: Q, q: Q, u: Q, v: Q) -> Dictionary:
		return {"c0": p, "e0": q, "c1": u, "e1": v}
	var ws: Array = [alt(w.call(c0, r.add(1), c1, e1), R_FRAC, sl.call(c0, r.add(1), c1, e1))]
	var gen: Array = []
	for t in [[a, e0, c1, e1], [c0, e0, b, e1], [c0, e0, c1, Q.new(-n + 1)], [c0.neg(), e0, c1, e1], [c0, e0, c1.neg(), e1], [c0.add(1), e0, c1, e1]]:
		gen.append(alt(w.call(t[0], t[1], t[2], t[3]), "", sl.call(t[0], t[1], t[2], t[3])).values)
	return {"lines": ["f(x) = %s, for x > 0" % f], "asked": "Find f′(x). Write each term as a power of x.", "answer": ans, "wrongs": ws, "generic": gen,
		"methods": {"index-form": method([
			"Write each term as a power of x: f(x) = %s." % SUM([[a, XQ(r)], [b, XQ(Q.new(-n))]]),
			"Bring the power down and take 1 off it: %s becomes %s, and %s becomes %s." % [XQ(r), T(r, XQ(e0)), XQ(Q.new(-n)), T(Q.new(-n), XQ(e1))],
			say(ans)], ans.values)}}


func u_log_power_terms(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var m: int = s.m
	var n: int = s.n
	var d: int = s.d
	var power: bool = s.fam == "power"
	var inner: String = X(n) if power else "%dx" % d
	var f := SUM([[a, "ln(%s)" % inner], [b, X(m)]])
	var c0: int = a * n if power else a
	var c1: int = b * m
	var tail := X(m - 1)
	var dh := "dy/dx = "
	var w := func(p: Variant, q: int) -> String:
		return dh + SUM([[p, "/x"], [q, tail]])
	var ans := form(w.call(c0, c1), [dh, {"slot": "c0"}, "/x + ", {"slot": "c1"}, tail], {"c0": Q.new(c0), "c1": Q.new(c1)})
	var ws: Array = []
	if power:
		ws.append(alt(dh + SUM([[a, "/" + X(n)], [c1, tail]]), R_NO_INNER))
	else:
		ws.append(alt(dh + SUM([[a, "/(%dx)" % d], [c1, tail]]), R_LN_SCALE))
	var gen: Array = []
	for t in [[c0 + 1, c1], [-c0, c1], [c0, b], [c0, -c1], [c0, c1 + 1]]:
		gen.append(alt(w.call(t[0], t[1]), "", {"c0": Q.new(t[0]), "c1": Q.new(t[1])}).values)
	var law := "ln(%s) = %d ln x" % [inner, n] if power else "ln(%s) = ln %d + ln x, and ln %d is a constant" % [inner, d, d]
	var inner_d := "%sx%s" % [n, Fmt.sup(n - 1)] if n > 2 else "%dx" % n
	if not power:
		inner_d = str(d)
	return {"lines": ["y = %s, for x > 0" % f], "asked": "Find dy/dx.", "answer": ans, "wrongs": ws, "generic": gen,
		"methods": {"log-laws-first": method([
			"Use the log laws first: " + law + ".",
			"So y = %s, and each term is a standard result." % SUM([[c0, "ln x"], [b, X(m)]] if power else [[a, "ln %d" % d], [a, "ln x"], [b, X(m)]]),
			say(ans)], ans.values),
		"outer-times-inner": method([
			"Outer × inner: ln(u) gives 1/u, and u = %s gives %s." % [inner, inner_d],
			"So the log term gives %s × (%s)/(%s), and the powers of x cancel." % [Fmt.num(a), inner_d, inner],
			say(ans)], ans.values)}}


# ── Chain rule ───────────────────────────────────────────────

## The inside as text: "3x² + 1".
static func inside(a: int, m: int, b: int) -> String:
	return SUM([[a, X(m)], [b, ""]])


func u_chain_power(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var m: int = s.m
	var n: int = s.n
	var inn := inside(a, m, b)
	var y := "%s(%s)%s" % [Fmt.lead(c), inn, Fmt.sup(n)]
	var k: int = c * n * a * m
	var xp := X(m - 1)
	var dh := "dy/dx = "
	var w := func(q: int, p: int, x: String = xp) -> String:
		return dh + "%s%s(%s)%s" % [Fmt.lead(q), x, inn, Fmt.sup(p)]
	var ans := form(w.call(k, n - 1), [dh, {"slot": "k"}, xp + "(" + inn + ")^", {"slot": "p"}], {"k": Q.new(k), "p": Q.new(n - 1)})
	var dinner := T(a * m, xp)
	var ws: Array = []
	var forgot: String = w.call(c * n, n - 1, "")
	ws.append(alt(forgot, R_NO_INNER, {"k": Q.new(c * n), "p": Q.new(n - 1)} if m == 1 else {}))
	ws.append(alt(dh + "%s(%s)%s" % [Fmt.lead(c * n), dinner, Fmt.sup(n - 1)], R_INSIDE))
	var gen: Array = []
	for t in [[k, n], [-k, n - 1], [k + c, n - 1], [k * 2, n - 1], [c * a * m, n - 1]]:
		gen.append(alt(w.call(t[0], t[1]), "", {"k": Q.new(t[0]), "p": Q.new(t[1])}).values)
	return {"lines": ["y = %s" % y], "asked": "Find dy/dx.", "answer": ans, "wrongs": ws, "generic": gen,
		"methods": {"outer-times-inner": method([
			"The outside is %s(…)%s, which gives %s(…)%s." % [Fmt.lead(c), Fmt.sup(n), T(c * n, ""), Fmt.sup(n - 1)],
			"The inside is %s, which gives %s." % [inn, dinner],
			"Multiply them: %s × %s = %s." % [Fmt.num(c * n), dinner, T(k, xp)],
			say(ans)], ans.values),
		"u-substitution": method([
			"Let u = %s, so y = %s and du/dx = %s." % [inn, T(c, "u" + Fmt.sup(n)), dinner],
			"dy/du = %s." % T(c * n, "u" + Fmt.sup(n - 1)),
			"dy/dx = dy/du × du/dx = %s × %s." % [T(c * n, "u" + Fmt.sup(n - 1)), dinner],
			"Put u back: " + Answer.text(ans) + "."], ans.values)}}


func u_chain_small_power(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var y := "%s²" % B(a, b)
	var c1: int = 2 * a * a
	var c0: int = 2 * a * b
	var dh := "dy/dx = "
	var w := func(p: int, q: int) -> String:
		return dh + SUM([[p, "x"], [q, ""]])
	var ans := form(w.call(c1, c0), [dh, {"slot": "c1"}, "x + ", {"slot": "c0"}], {"c1": Q.new(c1), "c0": Q.new(c0)})
	var sl := func(p: int, q: int) -> Dictionary:
		return alt(w.call(p, q), "", {"c1": Q.new(p), "c0": Q.new(q)}).values
	return {"lines": ["y = " + y], "asked": "Find dy/dx. Write your answer in the form px + q.", "answer": ans,
		"wrongs": [alt(w.call(2 * a, 2 * b), R_NO_INNER, {"c1": Q.new(2 * a), "c0": Q.new(2 * b)})],
		"generic": [sl.call(2 * a * a, b), sl.call(a * a, 2 * a * b), sl.call(c1, -c0), sl.call(c1 + 1, c0), sl.call(c1, c0 + 1)],
		"methods": {"outer-times-inner": method([
			"The outside gives 2(…), and the inside %s gives %d." % [SUM([[a, "x"], [b, ""]]), a],
			"dy/dx = 2 × %d × %s." % [a, B(a, b)],
			say(ans)], ans.values),
		"expand-first": method([
			"Multiply out first: y = %s." % Fmt.poly([a * a, 2 * a * b, b * b]),
			"Differentiate term by term: the constant goes.",
			say(ans)], ans.values)}}


func u_chain_function(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var dh := "dy/dx = "
	var y := ""
	var parts: Array = []
	var ans_text := ""
	var slots := {}
	var out_d := ""     # the outer function's derivative, in u
	var inn := ""
	var dinn := ""
	var wr: Array = []
	var gen: Array = []
	match s.fam:
		"exp-quad":
			inn = inside(a, 2, b)
			dinn = T(2 * a, "x")
			y = "e^(%s)" % inn
			out_d = "e^u"
			var tail := "x e^(%s)" % inn
			ans_text = dh + T(2 * a, tail)
			parts = [dh, {"slot": "k"}, tail]
			slots = {"k": Q.new(2 * a)}
			wr.append(alt(dh + y, R_NO_INNER))
			for q in [a, 2 * a + 1, -2 * a, 2 * a * a]:
				gen.append(alt(dh + T(q, tail), "", {"k": Q.new(q)}).values)
			gen.append(alt(dh + "%s e^(%s)" % [T(2 * a, "x"), T(2 * a, "x")]).values)
		"exp-lin":
			inn = SUM([[a, "x"], [b, ""]])
			dinn = str(a)
			y = "e^(%s)" % inn
			out_d = "e^u"
			ans_text = dh + T(a, y)
			parts = [dh, {"slot": "k"}, y]
			slots = {"k": Q.new(a)}
			wr.append(alt(dh + y, R_NO_INNER, {"k": Q.new(1)}))
			for q in [a + 1, -a, 2 * a, a - 1]:
				if q != 1:
					gen.append(alt(dh + T(q, y), "", {"k": Q.new(q)}).values)
		"ln-quad":
			inn = inside(1, 2, b)
			dinn = "2x"
			y = "ln(%s)" % inn
			out_d = "1/u"
			ans_text = dh + "2x/(%s)" % inn
			parts = [dh, {"slot": "k"}, "x/(" + inn + ")"]
			slots = {"k": Q.new(2)}
			wr.append(alt(dh + "1/(%s)" % inn, R_NO_INNER))
			for q in [1, 4, -2, 3]:
				gen.append(alt(dh + "%sx/(%s)" % [Fmt.lead(q), inn], "", {"k": Q.new(q)}).values)
		"ln-lin":
			inn = SUM([[a, "x"], [b, ""]])
			dinn = str(a)
			y = "ln(%s)" % inn
			out_d = "1/u"
			ans_text = dh + "%d/(%s)" % [a, inn]
			parts = [dh, {"slot": "k"}, "/(" + inn + ")"]
			slots = {"k": Q.new(a)}
			wr.append(alt(dh + "1/(%s)" % inn, R_NO_INNER, {"k": Q.new(1)}))
			for q in [a + 1, -a, 2 * a, a - 1]:
				if q != 1:
					gen.append(alt(dh + "%s/(%s)" % [Fmt.num(q), inn], "", {"k": Q.new(q)}).values)
		"sin-lin", "cos-lin":
			var cos: bool = s.fam == "cos-lin"
			inn = SUM([[a, "x"], [b, ""]])
			dinn = str(a)
			y = "%s(%s)" % ["cos" if cos else "sin", inn]
			var other := "%s(%s)" % ["sin" if cos else "cos", inn]
			out_d = "−sin u" if cos else "cos u"
			var k: int = -a if cos else a
			ans_text = dh + T(k, other)
			parts = [dh, {"slot": "k"}, " " + other]
			slots = {"k": Q.new(k)}
			wr.append(alt(dh + T(signi(k), other), R_NO_INNER, {"k": Q.new(signi(k))}))
			if cos:
				wr.append(alt(dh + T(a, other), R_COS, {"k": Q.new(a)}))
			for q in [-k, k + 1, 2 * k, k - 1]:
				if absi(q) != 1:
					gen.append(alt(dh + T(q, other), "", {"k": Q.new(q)}).values)
		"sqrt-lin":
			inn = SUM([[a, "x"], [b, ""]])
			dinn = str(a)
			y = "√(%s)" % inn
			out_d = "1/(2√u)"
			var c := Q.new(a, 2)
			var w := func(q: Q) -> String:
				return dh + "%s/(2√(%s))" % [q.mul(2).text(), inn]
			ans_text = w.call(c)
			parts = [dh, {"slot": "k"}, "/(2√(" + inn + "))"]
			slots = {"k": Q.new(a)}
			wr.append(alt(dh + "1/(2√(%s))" % inn, R_NO_INNER, {"k": Q.new(1)}))
			for q in [a + 1, -a, 2 * a, a - 1]:
				if q != 1:
					gen.append(alt(dh + "%s/(2√(%s))" % [Fmt.num(q), inn], "", {"k": Q.new(q)}).values)
	var ans := form(ans_text, parts, slots)
	var line := "y = %s" % y
	if s.fam.begins_with("ln") or s.fam == "sqrt-lin":
		line += ", where the expression is defined"
	return {"lines": [line], "asked": "Find dy/dx.", "answer": ans, "wrongs": wr, "generic": gen,
		"methods": {"outer-times-inner": method([
			"The outside function gives %s, with u left as it is." % out_d,
			"The inside %s gives %s." % [inn, dinn],
			"Multiply outer by inner.",
			say(ans)], ans.values),
		"u-substitution": method([
			"Let u = %s, so du/dx = %s." % [inn, dinn],
			"dy/du = %s." % out_d,
			"dy/dx = dy/du × du/dx, then put u back.",
			say(ans)], ans.values)}}


func u_chain_log_split(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var n: int = s.n
	var power: bool = s.fam == "power"
	var inn := SUM([[a, "x"], [b, ""]])
	var y: String = "ln(%s%s)" % [B(a, b), Fmt.sup(n)] if power else "ln(√(%s))" % inn
	var dh := "dy/dx = "
	var c: Q = Q.new(a * n) if power else Q.new(a, 2)
	var den := "(%s)" % inn
	var w := func(q: Q) -> String:
		return dh + ("%s/%s" % [q.text(), den] if q.is_int() else "%s/(%d%s)" % [Fmt.num(q.n), q.d, den])
	var ans := form(w.call(c), [dh, {"slot": "k"}, "/" + den], {"k": c})
	var outer: Q = Q.new(n) if power else Q.new(1, 2)
	var sl := func(q: Q) -> Dictionary:
		return alt(w.call(q), "", {"k": q}).values
	var gen: Array = [sl.call(c.add(1)), sl.call(c.neg()), sl.call(c.mul(2)), sl.call(c.add(2))]
	if not c.eq(a):
		gen.append(sl.call(Q.new(a)))
	var law := "y = %d ln%s" % [n, den] if power else "y = ½ ln%s" % den
	var dy2 := "(1/u) × du/dx"
	return {"lines": ["y = %s, where the expression is defined" % y], "asked": "Find dy/dx.", "answer": ans,
		"wrongs": [alt(w.call(outer), R_NO_INNER, {"k": outer})], "generic": gen,
		"methods": {"log-laws-first": method([
			"Split the log first: " + law + ".",
			"ln%s gives %d/%s by the chain rule." % [den, a, den],
			say(ans)], ans.values),
		"outer-times-inner": method([
			"The outside ln(u) gives " + dy2 + ", with u = %s." % (B(a, b) + Fmt.sup(n) if power else "√(%s)" % inn),
			("du/dx = %d × %d%s%s." % [n, a, den, Fmt.sup(n - 1)]) if power else "du/dx = %d/(2√(%s))." % [a, inn],
			"Divide by u, and the bracket cancels down.",
			say(ans)], ans.values)}}


# ── Product rule ─────────────────────────────────────────────

func u_product_functions(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var a: int = s.a
	var dh := "dy/dx = "
	var xn := X(n)
	var xm := X(n - 1)
	var y := ""
	var v := ""
	var dv := ""
	var u := xn
	var du := T(n, xm)
	var parts: Array = []
	var slots := {}
	var text := ""
	var wr: Array = []
	var gen: Array = []
	match s.fam:
		"exp":
			var e := E(a)
			y = xn + " " + e
			v = e
			dv = T(a, e)
			var w := func(p: int, q: int) -> String:
				return dh + "%s %s(%s)" % [xm, e, SUM([[p, ""], [q, "x"]])]
			text = w.call(n, a)
			parts = [dh + "%s %s(" % [xm, e], {"slot": "p"}, " + ", {"slot": "q"}, "x)"]
			slots = {"p": Q.new(n), "q": Q.new(a)}
			wr.append(alt(dh + "%s %s" % [T(n * a, xm), e], R_UV))
			wr.append(alt(dh + "%s %s" % [T(a, xn), e], R_ONE_TERM))
			for t in [[n, -a], [-n, a], [n + 1, a], [n, a + 1], [n - 1, a]]:
				if t[1] != 0 and t[0] != 0:
					gen.append(alt(w.call(t[0], t[1]), "", {"p": Q.new(t[0]), "q": Q.new(t[1])}).values)
		"ln":
			y = xn + " ln x"
			v = "ln x"
			dv = "1/x"
			var w := func(p: int, q: int) -> String:
				return dh + "%s(%s)" % [xm, SUM([[p, "ln x"], [q, ""]])]
			text = w.call(n, 1)
			parts = [dh + xm + "(", {"slot": "p"}, " ln x + ", {"slot": "q"}, ")"]
			slots = {"p": Q.new(n), "q": Q.new(1)}
			wr.append(alt(dh + "%s/x" % T(n, xm), R_UV))
			wr.append(alt(dh + "%s ln x" % T(n, xm), R_ONE_TERM))
			wr.append(alt(dh + "%s(%d ln x)" % [xm, n], R_BAD_FACTOR))
			for t in [[n, -1], [n + 1, 1], [1, n], [n - 1, 1]]:
				if t[0] != 0:
					gen.append(alt(w.call(t[0], t[1]), "", {"p": Q.new(t[0]), "q": Q.new(t[1])}).values)
		"sin", "cos":
			var cos: bool = s.fam == "cos"
			v = "cos x" if cos else "sin x"
			var o := "sin x" if cos else "cos x"
			y = xn + " " + v
			var sgn := -1 if cos else 1
			dv = ("−" if cos else "") + o
			var w := func(p: int, q: int) -> String:
				return dh + SUM([[p, xm + " " + v], [q, xn + " " + o]])
			text = w.call(n, sgn)
			parts = [dh, {"slot": "p"}, xm + " " + v + " + ", {"slot": "q"}, xn + " " + o]
			slots = {"p": Q.new(n), "q": Q.new(sgn)}
			wr.append(alt(dh + "%s %s" % [T(n * sgn, xm), o], R_UV))
			wr.append(alt(dh + "%s %s" % [T(n, xm), v], R_ONE_TERM))
			for t in [[n, -sgn], [-n, sgn], [n + 1, sgn], [n - 1, sgn], [n, 2 * sgn]]:
				gen.append(alt(w.call(t[0], t[1]), "", {"p": Q.new(t[0]), "q": Q.new(t[1])}).values)
		"exp-sin":
			u = "e^x"
			du = "e^x"
			v = "sin x"
			dv = "cos x"
			y = "e^x sin x"
			var w := func(p: int, q: int) -> String:
				return dh + "e^x(%s)" % SUM([[p, "sin x"], [q, "cos x"]])
			text = w.call(1, 1)
			parts = [dh + "e^x(", {"slot": "p"}, " sin x + ", {"slot": "q"}, " cos x)"]
			slots = {"p": Q.new(1), "q": Q.new(1)}
			wr.append(alt(dh + "e^x cos x", R_UV))
			wr.append(alt(dh + "e^x sin x", R_ONE_TERM))
			for t in [[1, -1], [-1, 1], [2, 1], [1, 2]]:
				gen.append(alt(w.call(t[0], t[1]), "", {"p": Q.new(t[0]), "q": Q.new(t[1])}).values)
	var ans := form(text, parts, slots)
	var line := "y = " + y + (", for x > 0" if s.fam == "ln" else "")
	return {"lines": [line], "asked": "Find dy/dx.", "answer": ans, "wrongs": wr, "generic": gen,
		"methods": {"product-rule": method([
			"Let u = %s and v = %s, so u′ = %s and v′ = %s." % [u, v, du, dv],
			"dy/dx = u′v + uv′ = (%s)(%s) + (%s)(%s)." % [du, v, u, dv],
			"Take out what the two terms share." if s.fam in ["exp", "ln", "exp-sin"] else "The two terms share no bracket, so leave them as they are.",
			say(ans)], ans.values)}}


func u_product_polys(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var d: int = s.d
	var y := "%s(%s)" % [B(a, b), inside(c, 2, d)]
	var dh := "dy/dx = "
	var w := func(p: int, q: int, r: int) -> String:
		return dh + Fmt.poly([p, q, r])
	var u2: int = 3 * a * c
	var u1: int = 2 * b * c
	var u0: int = a * d
	var ans := form(w.call(u2, u1, u0), [dh, {"slot": "u2"}, "x² + ", {"slot": "u1"}, "x + ", {"slot": "u0"}],
		{"u2": Q.new(u2), "u1": Q.new(u1), "u0": Q.new(u0)})
	var sl := func(p: int, q: int, r: int, ref: String = "") -> Dictionary:
		return alt(w.call(p, q, r), ref, {"u2": Q.new(p), "u1": Q.new(q), "u0": Q.new(r)})
	return {"lines": ["y = " + y], "asked": "Find dy/dx. Write your answer in the form px² + qx + r.", "answer": ans,
		"wrongs": [alt(dh + T(2 * a * c, "x"), R_UV), sl.call(a * c, 0, a * d, R_ONE_TERM)],
		"generic": [sl.call(u2, -u1, u0).values, sl.call(u2, u1, -u0).values, sl.call(u2 + 1, u1, u0).values, sl.call(2 * a * c, u1, u0).values, sl.call(u2, u1 + 1, u0).values],
		"methods": {"product-rule": method([
			"Let u = %s and v = %s, so u′ = %d and v′ = %s." % [SUM([[a, "x"], [b, ""]]), inside(c, 2, d), a, T(2 * c, "x")],
			"dy/dx = u′v + uv′ = %d(%s) + %s%s." % [a, inside(c, 2, d), T(2 * c, "x"), B(a, b)],
			"Multiply out and collect the terms.",
			say(ans)], ans.values),
		"expand-first": method([
			"Multiply out first: y = %s." % Fmt.terms([a * c, b * c, a * d, b * d], [3, 2, 1, 0]),
			"Differentiate term by term.",
			say(ans)], ans.values)}}


func u_product_powers(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := Q.of(s.a)
	var m: int = s.m
	var p := Q.new(2 * m + 1, 2)
	var c := a.mul(p)
	var e := p.sub(1)
	var dh := "dy/dx = "
	var w := func(q: Q, r: Q) -> String:
		return dh + T(q, XQ(r))
	var ans := form(w.call(c, e), [dh, {"slot": "c"}, "x^", {"slot": "e"}], {"c": c, "e": e})
	var sl := func(q: Q, r: Q, ref: String = "") -> Dictionary:
		return alt(w.call(q, r), ref, {"c": q, "e": r})
	var y := "%s √x" % T(a, X(m))
	var uv := a.mul(m).div(2)
	return {"lines": ["y = %s, for x > 0" % y], "asked": "Find dy/dx. Write your answer as a power of x.", "answer": ans,
		"wrongs": [sl.call(uv, Q.new(2 * m - 3, 2), R_UV), sl.call(a.mul(m), e, R_ONE_TERM)],
		"generic": [sl.call(a, e).values, sl.call(c, p).values, sl.call(c.neg(), e).values, sl.call(c.add(1), e).values, sl.call(c, e.add(1)).values],
		"methods": {"product-rule": method([
			"Let u = %s and v = √x = x^(1/2), so u′ = %s and v′ = (1/2)x^(−1/2)." % [T(a, X(m)), T(a.mul(m), X(m - 1))],
			"dy/dx = u′v + uv′ = %s + %s." % [T(a.mul(m), XQ(e)), T(a.div(2), XQ(e))],
			"Add the two terms: they are the same power of x.",
			say(ans)], ans.values),
		"combine-powers": method([
			"Combine into one power: y = %s." % T(a, XQ(p)),
			"Bring the power down and take 1 off it.",
			say(ans)], ans.values)}}


# ── Quotient rule ────────────────────────────────────────────

func u_quotient_linear(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var d: int = s.d
	var k: int = a * d - b * c
	var top := SUM([[a, "x"], [b, ""]])
	var bot := SUM([[c, "x"], [d, ""]])
	var den := "(%s)²" % bot
	var dh := "dy/dx = "
	var w := func(q: int) -> String:
		return dh + "%s/%s" % [Fmt.num(q), den]
	var ans := form(w.call(k), [dh, {"slot": "k"}, "/" + den], {"k": Q.new(k)})
	var ac := Q.new(a, c)
	var wr: Array = [alt(w.call(-k), R_FLIP, {"k": Q.new(-k)}), alt(dh + "%s/(%s)" % [Fmt.num(k), bot], R_NOT_SQUARED), alt(dh + ac.text(), R_U_V)]
	var gen: Array = []
	for q in [a * d + b * c, k + 1, k - 1, 2 * k]:
		if q != k and q != -k and q != 0:
			gen.append(alt(w.call(q), "", {"k": Q.new(q)}).values)
	return {"lines": ["y = (%s)/(%s), for x ≠ %s" % [top, bot, Q.new(-d, c).text()]], "asked": "Find dy/dx.", "answer": ans, "wrongs": wr, "generic": gen,
		"methods": {"quotient-rule": method([
			"Let u = %s and v = %s, so u′ = %s and v′ = %s." % [top, bot, N(a), N(c)],
			"dy/dx = (vu′ − uv′)/v² = (%s(%s) − %s(%s))/%s." % [N(a), bot, N(c), top, den],
			"The x terms cancel on top, leaving %s." % Fmt.num(k),
			say(ans)], ans.values),
		"product-with-negative-power": method([
			"Write y = (%s)(%s)⁻¹." % [top, bot],
			"The product rule, with the chain rule on the second bracket: %s(%s)⁻¹ − %s(%s)(%s)⁻²." % [N(a), bot, N(c), top, bot],
			"Put both over %s; the x terms cancel on top." % den,
			say(ans)], ans.values)}}


func u_quotient_functions(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var dh := "dy/dx = "
	var n: int = s.n
	var a: int = s.a
	var y := ""
	var text := ""
	var parts: Array = []
	var slots := {}
	var wr: Array = []
	var gen: Array = []
	var u := ""
	var du := ""
	var v := X(n)
	var dv := T(n, X(n - 1))
	var neg := ""
	match s.fam:
		"ln":
			u = "ln x"
			du = "1/x"
			y = "(ln x)/%s" % v
			var den := X(n + 1)
			var w := func(p: int, q: int) -> String:
				return dh + "(%s)/%s" % [SUM([[p, ""], [q, "ln x"]]), den]
			text = w.call(1, -n)
			parts = [dh + "(", {"slot": "p"}, " + ", {"slot": "q"}, " ln x)/" + den]
			slots = {"p": Q.new(1), "q": Q.new(-n)}
			wr.append(alt(w.call(-1, n), R_FLIP, {"p": Q.new(-1), "q": Q.new(n)}))
			wr.append(alt(dh + "(1 − %d ln x)/%s" % [n, X(n)], R_NOT_SQUARED))
			wr.append(alt(dh + "1/(%s)" % T(n, X(n)), R_U_V))
			for t in [[1, n], [n, -1], [1, -n - 1], [1, 1 - n], [2, -n]]:
				if t[1] != 0:
					gen.append(alt(w.call(t[0], t[1]), "", {"p": Q.new(t[0]), "q": Q.new(t[1])}).values)
			neg = "x^(−%d) ln x" % n
		"exp":
			var e := E(a)
			u = e
			du = T(a, e)
			v = "x"
			dv = "1"
			y = "%s/x" % e
			var w := func(p: int, q: int) -> String:
				return dh + "%s(%s)/x²" % [e, SUM([[p, "x"], [q, ""]])]
			text = w.call(a, -1)
			parts = [dh + e + "(", {"slot": "p"}, "x + ", {"slot": "q"}, ")/x²"]
			slots = {"p": Q.new(a), "q": Q.new(-1)}
			wr.append(alt(w.call(-a, 1), R_FLIP, {"p": Q.new(-a), "q": Q.new(1)}))
			wr.append(alt(dh + "%s(%s)/x" % [e, SUM([[a, "x"], [-1, ""]])], R_NOT_SQUARED))
			wr.append(alt(dh + T(a, e), R_U_V))
			for t in [[a, 1], [1, -1], [a + 1, -1], [a, -2]]:
				gen.append(alt(w.call(t[0], t[1]), "", {"p": Q.new(t[0]), "q": Q.new(t[1])}).values)
			neg = "%s x⁻¹" % e
		"sin":
			u = "sin x"
			du = "cos x"
			v = "x"
			dv = "1"
			y = "(sin x)/x"
			var w := func(p: int, q: int) -> String:
				return dh + "(%s)/x²" % SUM([[p, "x cos x"], [q, "sin x"]])
			text = w.call(1, -1)
			parts = [dh + "(", {"slot": "p"}, "x cos x + ", {"slot": "q"}, " sin x)/x²"]
			slots = {"p": Q.new(1), "q": Q.new(-1)}
			wr.append(alt(w.call(-1, 1), R_FLIP, {"p": Q.new(-1), "q": Q.new(1)}))
			wr.append(alt(dh + "(x cos x − sin x)/x", R_NOT_SQUARED))
			wr.append(alt(dh + "cos x", R_U_V))
			for t in [[1, 1], [2, -1], [1, -2], [-1, -1]]:
				gen.append(alt(w.call(t[0], t[1]), "", {"p": Q.new(t[0]), "q": Q.new(t[1])}).values)
			neg = "x⁻¹ sin x"
	var ans := form(text, parts, slots)
	var line := "y = " + y + ", for x > 0"
	return {"lines": [line], "asked": "Find dy/dx.", "answer": ans, "wrongs": wr, "generic": gen,
		"methods": {"quotient-rule": method([
			"Let u = %s and v = %s, so u′ = %s and v′ = %s." % [u, v, du, dv],
			"dy/dx = (vu′ − uv′)/v².",
			"Tidy the top, and cancel any power of x it shares with the bottom.",
			say(ans)], ans.values),
		"product-with-negative-power": method([
			"Write y = %s, and use the product rule." % neg,
			"One term keeps the power of x, the other drops it by one.",
			"Put both over one denominator.",
			say(ans)], ans.values)}}


func u_quotient_split(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var top := Fmt.poly([a, b, c])
	var dh := "dy/dx = "
	var w := func(p: int, q: int) -> String:
		return dh + SUM([[p, ""], [q, "/x²"]])
	var ans := form(w.call(a, -c), [dh, {"slot": "p"}, " + ", {"slot": "q"}, "/x²"], {"p": Q.new(a), "q": Q.new(-c)})
	var sl := func(p: int, q: int, ref: String = "") -> Dictionary:
		return alt(w.call(p, q), ref, {"p": Q.new(p), "q": Q.new(q)})
	return {"lines": ["y = (%s)/x, for x ≠ 0" % top], "asked": "Find dy/dx.", "answer": ans,
		"wrongs": [sl.call(-a, c, R_FLIP), alt(dh + SUM([[a, "x"], [-c, "/x"]]), R_NOT_SQUARED), alt(dh + Fmt.poly([2 * a, b]), R_U_V)],
		"generic": [sl.call(a, c).values, sl.call(b, -c).values, sl.call(a + 1, -c).values, sl.call(a, -c + 1).values],
		"methods": {"quotient-rule": method([
			"Let u = %s and v = x, so u′ = %s and v′ = 1." % [top, Fmt.poly([2 * a, b])],
			"dy/dx = (x(%s) − (%s))/x²." % [Fmt.poly([2 * a, b]), top],
			"Collect the top: %s, and the x terms cancel." % Fmt.poly([a, 0, -c]),
			say(ans)], ans.values),
		"split-fraction": method([
			"The bottom is a single term, so split it: y = %s." % SUM([[a, "x"], [b, ""], [c, "/x"]]),
			"Write %s as %s, and differentiate term by term." % [T(c, "/x"), T(c, "x⁻¹")],
			say(ans)], ans.values)}}


# ── Show that ────────────────────────────────────────────────

func u_show_form(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var n: int = s.n
	var names: Array = []
	var vals: Array = []
	var line := ""
	var target := ""
	var wr: Array = []
	var gen: Array = []
	var ds: Array = []    # differentiate-simplify
	var alt_rule: Array = []
	var ends: Array = []
	match s.fam:
		"ln":
			line = "y = (ln x)/%s, for x > 0" % X(n)
			target = "dy/dx = (p + q ln x)/x^r"
			names = ["p", "q", "r"]
			vals = [1, -n, n + 1]
			wr = [[[1, n, n + 1], R_SIGN], [[1, -n, 2 * n], R_NOT_SQUARED]]
			gen = [[1, -n, n], [n, -1, n + 1], [-1, n, n + 1], [1, -n - 1, n + 1]]
			ds = ["The quotient rule, with u = ln x and v = %s: dy/dx = (%s × 1/x − %s ln x)/%s." % [X(n), X(n), T(n, X(n - 1)), X(2 * n)],
				"Take out %s on top: (%s)/%s." % [X(n - 1), SUM([[1, ""], [-n, "ln x"]]), X(n + 1)]]
			alt_rule = ["The product rule lands closer: y = x^(−%d) ln x." % n,
				"dy/dx = x^(−%d) × 1/x − %d x^(−%d) ln x." % [n, n, n + 1],
				"Both terms have x^(−%d), which is 1/%s." % [n + 1, X(n + 1)]]
			ends = ["The target says one power of x below: x^r.",
				"From the left, the quotient rule gives (%s − %s ln x)/%s." % [X(n - 1), T(n, X(n - 1)), X(2 * n)],
				"Cancel %s from top and bottom, and the two ends meet." % X(n - 1)]
		"linear":
			line = "f(x) = (%s)/(x − %d), for x ≠ %d" % [SUM([[a, "x"], [b, ""]]), c, c]
			target = "f′(x) = p/(x − %d)²" % c
			names = ["p"]
			vals = [-b - a * c]
			var k: int = vals[0]
			wr = [[[-k], R_SIGN]]
			gen = [[k + 1], [k - 1], [2 * k], [a - b], [b - a * c]]
			ds = ["The quotient rule, with u = %s and v = x − %d: f′(x) = (%d(x − %d) − (%s))/(x − %d)²." % [SUM([[a, "x"], [b, ""]]), c, a, c, SUM([[a, "x"], [b, ""]]), c],
				"The x terms cancel on top, leaving %s." % Fmt.num(k)]
			alt_rule = ["Split the top first: (%s)/(x − %d) = %d + %s/(x − %d)." % [SUM([[a, "x"], [b, ""]]), c, a, Fmt.num(b + a * c), c],
				"Only the second term changes: its derivative is %s/(x − %d)²." % [Fmt.num(k), c]]
			ends = ["The target has (x − %d)² below, which is v², so the quotient rule's bottom is already right." % c,
				"So only the top is left to find: vu′ − uv′ = %s." % Fmt.num(k)]
		"alg":
			line = "f(x) = %s/(x² + %d)%s" % [T(a, "x"), b, Fmt.sup(n)]
			target = "f′(x) = %d(p − qx²)/(x² + %d)^r" % [a, b]
			names = ["p", "q", "r"]
			vals = [b, 2 * n - 1, n + 1]
			wr = [[[b, -2 * n - 1, n + 1], R_SIGN], [[b, 2 * n - 1, 2 * n], R_NOT_SQUARED]]
			gen = [[b, 2 * n, n + 1], [b, n, n + 1], [2 * b, 2 * n - 1, n + 1], [b + 1, 2 * n - 1, n + 1]]
			ds = ["The quotient rule, with u = %s and v = (x² + %d)%s: v′ = %s(x² + %d)%s." % [T(a, "x"), b, Fmt.sup(n), T(2 * n, "x"), b, Fmt.sup(n - 1)],
				"Take out %d(x² + %d)%s on top, leaving x² + %d − %s." % [a, b, Fmt.sup(n - 1), b, T(2 * n, "x²")],
				"Collect: %d − %s, over (x² + %d)%s." % [b, T(2 * n - 1, "x²"), b, Fmt.sup(n + 1)]]
			alt_rule = ["The product rule on %s(x² + %d)^(−%d): u′ = %d, v′ = −%s(x² + %d)^(−%d)." % [T(a, "x"), b, n, a, T(2 * n, "x"), b, n + 1],
				"f′(x) = %d(x² + %d)^(−%d) − %s(x² + %d)^(−%d)." % [a, b, n, T(2 * n * a, "x²"), b, n + 1],
				"Take out %d(x² + %d)^(−%d): the bracket left is %d − %s." % [a, b, n + 1, b, T(2 * n - 1, "x²")]]
			ends = ["The target has (x² + %d)^r below; the quotient rule gives (x² + %d)%s before cancelling." % [b, b, Fmt.sup(2 * n)],
				"Cancel (x² + %d)%s from top and bottom, so r = %d." % [b, Fmt.sup(n - 1), n + 1],
				"Match the top: x² + %d − %s = %d − %s." % [b, T(2 * n, "x²"), b, T(2 * n - 1, "x²")]]
	var fx := {"names": names}
	var values := {}
	for i in vals.size():
		values["v%d" % i] = Q.new(vals[i])
	var ans := Answer.make("named", values, fx)
	ans.exact = true
	var one := func(t: Array) -> Dictionary:
		var d := {}
		for i in t.size():
			d["v%d" % i] = Q.new(t[i])
		return d
	var wrs: Array = wr.map(func(p): return wrong(one.call(p[0]), p[1]))
	var noun := "the value of p" if names.size() == 1 else "the values of " + ("p, q and r")
	return {"lines": [line, "Show that %s, and state %s." % [target, noun]], "asked": "State %s." % noun, "answer": ans,
		"wrongs": wrs, "generic": gen.map(func(t): return one.call(t)),
		"methods": {"differentiate-simplify": method(ds + [say(ans)], ans.values),
			"alternate-rule": method(alt_rule + [say(ans)], ans.values),
			"both-ends": method(ends + [say(ans)], ans.values)}}


# ── A gradient at a point ────────────────────────────────────

func u_gradient_chain(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _gradient_at_point(rep, s, rng)


func u_gradient_product(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _gradient_at_point(rep, s, rng)


func u_gradient_quotient(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _gradient_at_point(rep, s, rng)


func _gradient_at_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p2: bool = s.paper == 2
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var n: int = s.n
	var k := Q.of(s.k)
	var kt := Fmt.dec(k)
	var f := ""
	var ans: Dictionary
	var wr: Array = []
	var gen: Array = []
	var steps: Array = []
	if p2:
		var x := k.to_float()
		var v: float = DifferentiationSituation.gradient_value(s)
		ans = Answer.make("number", {"v": GdcKit.qf(v)}, {}, "Gradient = ")
		ans.show = "sf"
		var nums: Array = []
		match s.fam:
			"chain":
				f = "√(%s)" % inside(a, 2, b)
				nums = [[1.0 / (2.0 * sqrt(a * x * x + b)), R_NO_INNER], [a * x, ""]]
				steps = ["The outside gives 1/(2√u) and the inside gives %s, so dy/dx = %s/√(%s)." % [T(2 * a, "x"), T(a, "x"), inside(a, 2, b)],
					"Put x = %s, on the GDC: %s." % [kt, GdcKit.W(v)]]
			"product":
				f = X(n) + " ln x"
				nums = [[n * pow(x, n - 1) / x, R_UV], [n * pow(x, n - 1) * log(x), R_ONE_TERM]]
				steps = ["u = %s and v = ln x, so dy/dx = %s ln x + %s." % [X(n), T(n, X(n - 1)), X(n - 1)],
					"Put x = %s, on the GDC: %s." % [kt, GdcKit.W(v)]]
			"quotient":
				f = "(ln x)/(x + %d)" % c
				nums = [[(log(x) - (x + c) / x) / pow(x + c, 2), R_FLIP], [(1.0 / x * (x + c) - log(x)) / (x + c), R_NOT_SQUARED], [1.0 / x, R_U_V]]
				steps = ["u = ln x and v = x + %d, so dy/dx = ((x + %d)/x − ln x)/(x + %d)²." % [c, c, c],
					"Put x = %s, on the GDC: %s." % [kt, GdcKit.W(v)]]
		for w in nums:
			if GdcKit.fair(w[0]):
				wr.append(wrong({"v": GdcKit.qf(w[0])}, w[1]))
		gen = [{"v": GdcKit.qf(v * 2.0)}, {"v": GdcKit.qf(-v)}, {"v": GdcKit.qf(v * 0.5)}, {"v": GdcKit.qf(v * 1.5)}]
	else:
		var kn: int = k.n
		var val: Q
		match s.fam:
			"chain":
				f = "e^(%s)" % inside(1, 2, b)
				var e: int = kn * kn + b
				var cc: int = 2 * kn
				var head := "Gradient = "
				var w := func(p: int, q: int) -> String:
					return head + "%s%s" % [Fmt.lead(p), EN(q)]
				ans = form(w.call(cc, e), [head, {"slot": "c"}, "e^", {"slot": "e"}], {"c": Q.new(cc), "e": Q.new(e)})
				wr.append(alt(head + EN(e), R_NO_INNER, {"c": Q.new(1), "e": Q.new(e)}))
				for t in [[-cc, e], [cc, e + 1], [cc, e - 1], [2 * cc, e], [cc + 1, e]]:
					if t[0] != 1 and t[0] != 0:
						gen.append(alt(w.call(t[0], t[1]), "", {"c": Q.new(t[0]), "e": Q.new(t[1])}).values)
				steps = ["The chain rule: dy/dx = 2x e^(%s)." % inside(1, 2, b),
					"Put x = %s: 2 × %s × e^(%s + %s)." % [kt, Fmt.paren(k), Fmt.num(kn * kn), Fmt.paren(b)]]
			"product":
				var lin := SUM([[a, "x"], [-b, ""]])
				f = "%s(%s)²" % [X(n), lin]
				var m: int = a * kn - b
				var pw := func(t: int, p: int) -> int:
					return int(pow(t, p))
				var t1: int = n * pw.call(kn, n - 1) * m * m
				var t2: int = 2 * a * pw.call(kn, n) * m
				val = Q.new(t1 + t2)
				ans = _exact_number(val)
				wr.append(alt("Gradient = " + Fmt.num(n * pw.call(kn, n - 1) * 2 * a * m), R_UV, {"v": Q.new(n * pw.call(kn, n - 1) * 2 * a * m)}))
				wr.append(alt("Gradient = " + Fmt.num(t1), R_ONE_TERM, {"v": Q.new(t1)}))
				steps = ["u = %s and v = (%s)², so u′ = %s and v′ = %s(%s) by the chain rule." % [X(n), lin, T(n, X(n - 1)), T(2 * a, ""), lin],
					"dy/dx = u′v + uv′. Put x = %s: %s + %s." % [kt, Fmt.num(t1), Fmt.paren(t2)]]
			"quotient":
				var top := SUM([[a, "x"], [b, ""]])
				var bot := inside(1, 2, c)
				f = "(%s)/(%s)" % [top, bot]
				var v0: int = kn * kn + c
				var u0: int = a * kn + b
				var num: int = v0 * a - u0 * 2 * kn
				val = Q.new(num, v0 * v0)
				ans = _exact_number(val)
				wr.append(alt("Gradient = " + Q.new(-num, v0 * v0).text(), R_FLIP, {"v": Q.new(-num, v0 * v0)}))
				wr.append(alt("Gradient = " + Q.new(num, v0).text(), R_NOT_SQUARED, {"v": Q.new(num, v0)}))
				if kn != 0:
					wr.append(alt("Gradient = " + Q.new(a, 2 * kn).text(), R_U_V, {"v": Q.new(a, 2 * kn)}))
				steps = ["At x = %s, u = %s and v = %s, with u′ = %d and v′ = %s." % [kt, Fmt.num(u0), Fmt.num(v0), a, Fmt.num(2 * kn)],
					"dy/dx = (vu′ − uv′)/v² = (%s − %s)/%s." % [Fmt.num(v0 * a), Fmt.paren(u0 * 2 * kn), Fmt.num(v0 * v0)]]
		if ans.kind == "form" and ans.values.has("v"):
			for d in [val.neg(), val.add(1), val.mul(2), val.sub(1), val.add(2)]:
				gen.append(alt("Gradient = " + d.text(), "", {"v": d}).values)
	var line: String
	var asked: String
	if rep == "words":
		line = "A curve has equation y = %s%s." % [f, ", for x > 0" if f.contains("ln") else ""]
		asked = "Find the gradient of the curve at the point where x = %s%s." % [kt, ", to 3 s.f." if p2 else ""]
	else:
		line = "f(x) = %s%s" % [f, ", for x > 0" if f.contains("ln") else ""]
		asked = "Find f′(%s)%s." % [kt, ", to 3 s.f." if p2 else ""]
	var st: Array = steps + [say(ans)]
	var key: String = {"chain": "outer-times-inner", "product": "product-rule", "quotient": "quotient-rule"}[s.fam]
	return {"lines": [line], "asked": asked, "answer": ans, "wrongs": wr, "generic": gen, "methods": {key: method(st, ans.values)}}


## A gradient as an exact number, typed.
static func _exact_number(v: Q) -> Dictionary:
	return form("Gradient = " + v.text(), ["Gradient = ", {"slot": "v"}], {"v": v})


# ── A letter left in ─────────────────────────────────────────

func u_parameter_derivative(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var c: int = s.c
	var lin := "%dx + p" % a
	var bot := "x + %d" % c
	var f := "f(x) = (%s)³/(%s)²" % [lin, bot]
	var dh := "f′(x) = "
	var head := "%s(%s)²(" % [dh, lin]
	var tail := ")/(%s)³" % bot
	var w := func(x: int, y: int, z: int) -> String:
		return head + SUM([[x, "x"], [y, ""], [z, "p"]]) + tail
	var c1: int = a
	var c0: int = 3 * a * c
	var ans := form(w.call(c1, c0, -2), [head, {"slot": "c1"}, "x + ", {"slot": "c0"}, " + ", {"slot": "cp"}, "p" + tail],
		{"c1": Q.new(c1), "c0": Q.new(c0), "cp": Q.new(-2)})
	var sl := func(x: int, y: int, z: int, ref: String = "") -> Dictionary:
		return alt(w.call(x, y, z), ref, {"c1": Q.new(x), "c0": Q.new(y), "cp": Q.new(z)})
	return {"lines": [f + ", for x ≠ −%d" % c], "asked": "Find an expression for f′(x), in terms of p.", "answer": ans,
		"wrongs": [sl.call(-c1, -c0, 2, R_FLIP), sl.call(3 - 2 * a, 3 * c, -2, R_NO_INNER), alt("%s(%s)²(%s)/(%s)²" % [dh, lin, SUM([[c1, "x"], [c0, ""], [-2, "p"]]), bot], R_NOT_SQUARED)],
		"generic": [sl.call(c1, c0, 2).values, sl.call(c1 + 1, c0, -2).values, sl.call(c1, c0 + 1, -2).values, sl.call(c1, c0, -3).values],
		"methods": {"quotient-rule": method([
			"u = (%s)³, so u′ = %d(%s)² by the chain rule. v = (%s)², so v′ = 2(%s)." % [lin, 3 * a, lin, bot, bot],
			"f′(x) = (vu′ − uv′)/v², and v² = (%s)⁴." % bot,
			"Take out (%s)²(%s) on top, and cancel one (%s)." % [lin, bot, bot],
			"What is left on top: %d(%s) − 2(%s)." % [3 * a, bot, lin],
			say(ans)], ans.values),
		"product-with-negative-power": method([
			"Write f(x) = (%s)³(%s)⁻²." % [lin, bot],
			"The product rule, with the chain rule on each bracket: %d(%s)²(%s)⁻² − 2(%s)³(%s)⁻³." % [3 * a, lin, bot, lin, bot],
			"Take out (%s)²(%s)⁻³." % [lin, bot],
			"What is left: %d(%s) − 2(%s)." % [3 * a, bot, lin],
			say(ans)], ans.values)}}
