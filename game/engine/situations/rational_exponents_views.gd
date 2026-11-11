class_name RationalExponentsViews
extends ExtensionViews
## The views on the `rational-exponents` situation: one builder per unknown of
## t1-rational-exponents (FAL-754). Every answer is the `form` kind, so its numbers are typed
## and a wrong option in another shape, such as 3^(3/4), can be picked but never typed: a value
## is one slot, a power of x has its power typed, a bracket its number and power, and a sum of
## powers each term's number and power.
##
## The one representation is "equation": the exam gives the expression and nothing needs a
## figure. Powers are written with a caret, 64^(2/3) and x^(−1/2), and whole powers raised:
## 4², x⁻³. Only square and cube roots are written with a sign; other roots are in words.
##
## Paper 1 only, as the bank is: no cell needs a calculator.
##
## Misconceptions are the skill's, SL1.7.rational-exponents#i: the map's three, then the type's.

const SK := "SL1.7.rational-exponents#"
const R_TIMES := SK + "0"
const R_NEGATIVE := SK + "1"
const R_MUL_EXP := SK + "2"
const R_ROOT_ONLY := SK + "3"
const R_TIMES_TOP := SK + "4"
const R_NO_RECIP := SK + "5"
const R_DIVIDE := SK + "6"
const R_FLIP := SK + "7"
const R_NO_MINUS := SK + "8"
const R_COEF := SK + "9"
const R_ADD_BRACKET := SK + "10"
const R_TOPS_BOTTOMS := SK + "11"
const R_DIV_EXP := SK + "12"
const R_WRONG_WAY := SK + "13"
const R_DIV_ADD := SK + "14"
const R_TWO_BASES := SK + "15"
const R_TOP_ONLY := SK + "16"
const R_ADD_COEF := SK + "17"
const R_COEF_DIV := SK + "18"
const R_SQUARE_ROOT := SK + "19"
const R_SAME_POWER := SK + "20"

const ROOT_FIRST := "root-then-power"
const POWER_FIRST := "power-then-root"
const PRIME := "prime-base"
const SPLIT := "split-terms"
const LAWS := "index-laws"
const UNKNOWNS := ["value-fraction", "value-negative", "value-fraction-base", "solve-base", "root-as-power",
	"root-product-as-power", "bracket-power", "product-x", "quotient-x", "product-numbers", "split-two", "split-three"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, _angle_id: String) -> Array:
	return [1] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = RationalExponentsSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

## A base to a rational power: "64^(2/3)", "2⁶", "2⁻⁴", "(3/2)²". A base that is a fraction or
## negative gets brackets.
static func pw(base: Variant, e: Variant) -> String:
	var b := Q.of(base)
	var q := Q.of(e)
	var bt := b.text() if b.is_int() and b.sign() > 0 else "(%s)" % b.text()
	if q.is_int():
		return bt + ("¹" if q.eq(1) else Fmt.sup(q.n))
	return "%s^(%s)" % [bt, q.text()]


## x to a rational power: "" for 0, "x", "x³", "x⁻²", "x^(1/2)", "x^(−4/3)".
static func XQ(p: Q) -> String:
	if p.is_int():
		return "" if p.is_zero() else "x" + Fmt.sup(p.n)
	return "x^(%s)" % p.text()


## A coefficient before a body: "" for 1, "−" for −1, "3", "(3/2)", "−(3/2)".
static func lead(c: Q) -> String:
	if c.eq(1):
		return ""
	if c.eq(-1):
		return "−"
	if c.is_int():
		return c.text()
	return ("−" if c.sign() < 0 else "") + "(%s)" % c.abs_q().text()


## One term c x^p: "3x^(1/2)", "(5/2)x⁻¹", "−7" for p = 0.
static func term(c: Q, p: Q) -> String:
	var body := XQ(p)
	return c.text() if body == "" else lead(c) + body


## A sum of [coefficient, power] terms, skipping zero coefficients.
static func SUM(terms: Array) -> String:
	var out := ""
	for t in terms:
		var c: Q = t[0]
		if c.is_zero():
			continue
		var body := term(c.abs_q(), t[1])
		out += (("−" if c.sign() < 0 else "") if out == "" else (" − " if c.sign() < 0 else " + ")) + body
	return out if out != "" else "0"


## The root of a body, with its sign for 2 and 3: "√x", "∛(x²)".
static func root(n: int, body: String) -> String:
	return ("√" if n == 2 else "∛") + body


## The name of a root: "square root", "cube root", "fourth root", "fifth root".
static func root_name(n: int) -> String:
	return ["", "", "square", "cube", "fourth", "fifth"][n] + " root"


## A whole power as a word, for "raise to the power 3".
static func said(ans: Dictionary) -> String:
	return "So the answer is %s." % Answer.text(ans)


# ── Answers ──────────────────────────────────────────────────

static func val_ans(v: Q, head: String = "") -> Dictionary:
	var parts: Array = [{"slot": "v"}]
	if head != "":
		parts.push_front(head)
	var ans := Answer.make("form", {"v": v, "text": head + v.text()}, {"parts": parts})
	ans.exact = true
	return ans


static func wv(v: Q, ref: String = "", head: String = "") -> Dictionary:
	return wrong({"v": v, "text": head + v.text()}, ref)


static func gv(vals: Array, head: String = "") -> Array:
	return vals.map(func(v): return {"v": v, "text": head + v.text()})


## Another shape: it can be picked and never typed.
static func walt(text: String, ref: String = "") -> Dictionary:
	return wrong({"text": text, "shape": "other"}, ref)


## x^p, with p typed.
static func xpow_ans(p: Q) -> Dictionary:
	var ans := Answer.make("form", {"e": p, "text": XQ(p)}, {"parts": ["x^", {"slot": "e"}]})
	ans.exact = true
	return ans


static func xv(p: Q) -> Dictionary:
	return {"e": p, "text": XQ(p)}


static func wx(p: Q, ref: String = "") -> Dictionary:
	return wrong(xv(p), ref)


## c x^p, with c and p typed.
static func mono_ans(c: Q, p: Q) -> Dictionary:
	var ans := Answer.make("form", mv(c, p), {"parts": [{"slot": "c"}, "x^", {"slot": "e"}]})
	ans.exact = true
	return ans


static func mv(c: Q, p: Q) -> Dictionary:
	return {"c": c, "e": p, "text": term(c, p)}


static func wm(c: Q, p: Q, ref: String = "") -> Dictionary:
	return wrong(mv(c, p), ref)


## Σ c_i x^(p_i), with every number typed.
static func sum_ans(cs: Array, ps: Array) -> Dictionary:
	var parts: Array = []
	for i in cs.size():
		if i > 0:
			parts.append(" + ")
		parts.append_array([{"slot": "c%d" % i}, "x^", {"slot": "e%d" % i}])
	var ans := Answer.make("form", sv(cs, ps), {"parts": parts})
	ans.exact = true
	return ans


static func sv(cs: Array, ps: Array) -> Dictionary:
	var out := {}
	var terms: Array = []
	for i in cs.size():
		out["c%d" % i] = cs[i]
		out["e%d" % i] = ps[i]
		terms.append([cs[i], ps[i]])
	out.text = SUM(terms)
	return out


## Options for a number: wrongs first (shuffled), then fillers.
func _number(lines: Array, asked: String, ans: Dictionary, w: Array, gen: Array, rng: Seeded, methods: Dictionary) -> Dictionary:
	said_once(methods, ans)
	return {"lines": lines, "asked": asked, "answer": ans, "wrongs": rng.shuffled(w), "generic": gen, "methods": methods}


## Fillers near a value, never the value itself.
static func near(v: Q) -> Array:
	return [v.add(1), v.sub(1), v.mul(2), v.add(2), v.mul(3), v.neg()].filter(func(x): return not x.eq(v) and not x.is_zero())


## Fillers near a power of x.
static func near_powers(p: Q) -> Array:
	return [p.add(1), p.sub(1), p.neg(), p.mul(2), p.add(Q.new(1, 2)), p.sub(Q.new(1, 2))].filter(func(x): return not x.eq(p) and not x.is_zero())


# ── Values ───────────────────────────────────────────────────

## The root step for a^(1/n) = b: "4³ = 64, so 64^(1/3) = 4."
static func root_line(a: Variant, n: int, b: Variant) -> String:
	return "%s = %s, so %s = %s." % [pw(b, n), Q.of(a).text(), pw(a, Q.new(1, n)), Q.of(b).text()]


func u_value_fraction(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _value(s, rng)


func u_value_negative(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _value(s, rng)


func _value(s: Dictionary, rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var m: int = s.m
	var n: int = s.n
	var neg: bool = s.sgn < 0
	var e: Q = s.e
	var pos := Q.new(m, n)
	var expr := pw(a, e)
	var ans := val_ans(s.val)
	var big := Q.new(RationalExponentsSituation.ipow(b, m))
	var am := RationalExponentsSituation.ipow(a, m)
	var head := ["%s = 1/%s, as a negative power is a reciprocal." % [expr, pw(a, pos)]] if neg else []
	var tail := "So %s = 1/%s." % [expr, big.text()] if neg else "So the value is %s." % big.text()
	var m_root: Array = head + [root_line(a, n, b), "%s = (%s)%s = %s = %s." % [pw(a, pos), pw(a, Q.new(1, n)), Fmt.sup(m), pw(b, m), big.text()], tail]
	var m_power: Array = head + ["Raise to the power first: %s = %d." % [pw(a, m), am],
		"Then take the %s: %s = %s, as %s = %d." % [root_name(n), pw(am, Q.new(1, n)), big.text(), pw(big, n), am], tail]
	var p: int = s.p
	var t: int = s.k * n
	var m_prime: Array = ["%d = %s, so %s = (%s)^(%s)." % [a, pw(p, t), expr, pw(p, t), e.text()],
		"(%s)^(%s) = %s^(%d × %s) = %s = %s." % [pw(p, t), e.text(), p, t, PP(e), pw(p, e.mul(t)), s.val.text()], "So the value is %s." % s.val.text()]
	var w: Array = []
	if neg:
		w = [wv(big.neg(), R_NEGATIVE), wv(Q.new(-a * m, n), R_TIMES), wv(big, R_NO_RECIP), wv(Q.new(1, b), R_ROOT_ONLY), wv(Q.new(1, b * m), R_TIMES_TOP)]
	else:
		w = [wv(Q.new(a * m, n), R_TIMES), wv(Q.new(b), R_ROOT_ONLY), wv(Q.new(b * m), R_TIMES_TOP)]
	var gen: Array = gv(near(s.val)) if not neg else gv([Q.new(1, big.n + 1), Q.new(1, big.n * b), Q.new(1, 2 * big.n), Q.new(1, big.n - 1), Q.new(2, big.n)])
	return _number([expr], "Find the exact value.", ans, w, gen, rng,
		{ROOT_FIRST: method(m_root, ans.values), POWER_FIRST: method(m_power, ans.values), PRIME: method(m_prime, ans.values)})


func u_value_fraction_base(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var u: int = s.u
	var v: int = s.v
	var m: int = s.m
	var n: int = s.n
	var c: int = s.c
	var d: int = s.d
	var neg: bool = s.sgn < 0
	var e: Q = s.e
	var pos := Q.new(m, n)
	var base := Q.new(c, d)
	var expr := pw(base, e)
	var ans := val_ans(s.val)
	# The base the root and power act on: flipped first when the power is negative.
	var top: int = d if neg else c
	var bottom: int = c if neg else d
	var r := Q.new(top, bottom)
	var rr := Q.new(v, u) if neg else Q.new(u, v)
	var head := ["%s = %s, as a negative power flips the fraction." % [expr, pw(r, pos)]] if neg else []
	var rt: int = v if neg else u
	var rb: int = u if neg else v
	var both := func(a: int, ta: int, b2: int, tb: int) -> String:
		return "%s = %d" % [pw(a, n), ta] if tb == 1 else "%s = %d and %s = %d" % [pw(a, n), ta, pw(b2, n), tb]
	var m_root: Array = head + ["%s = %s, as %s." % [pw(r, Q.new(1, n)), rr.text(), both.call(rt, top, rb, bottom)],
		"%s = %s = %s." % [pw(r, pos), pw(rr, m), s.val.text()], "So the value is %s." % s.val.text()]
	var tm := RationalExponentsSituation.ipow(top, m)
	var bm := RationalExponentsSituation.ipow(bottom, m)
	var vt := RationalExponentsSituation.ipow(rt, m)
	var vb := RationalExponentsSituation.ipow(rb, m)
	var m_power: Array = head + ["Raise to the power first: %s = %s." % [pw(r, m), Q.new(tm, bm).text()],
		"Then take the %s: %s = %s, as %s." % [root_name(n), pw(Q.new(tm, bm), Q.new(1, n)), s.val.text(), both.call(vt, tm, vb, bm)],
		"So the value is %s." % s.val.text()]
	var uv := Q.new(u, v)
	var first := "%s = %s/%s = %s." % [base.text(), "1" if u == 1 else pw(u, n), pw(v, n), pw(uv, n)]
	var m_prime: Array = [first, "%s = (%s)^(%s) = %s = %s." % [expr, pw(uv, n), e.text(), pw(uv, e.mul(n)), s.val.text()],
		"So the value is %s." % s.val.text()]
	var w: Array = []
	if neg:
		var no_flip := RationalExponentsSituation.qpow(Q.new(u, v), m)
		w = [wv(no_flip, R_NO_RECIP), wv(no_flip.neg(), R_NEGATIVE),
			wv(Q.new(v, u), R_ROOT_ONLY), wv(base.mul(e), R_TIMES)]
	else:
		w = [wv(Q.new(u, v), R_ROOT_ONLY), wv(base.mul(e), R_TIMES), wv(Q.new(u * m, v), R_TIMES_TOP)]
	var val: Q = s.val
	var gen: Array = gv([Q.new(val.d, val.n), Q.new(val.n + 1, val.d), Q.new(val.n, val.d + 1), val.mul(2), Q.new(val.n * u, val.d * v)].filter(func(x): return not x.eq(val)))
	return _number([expr], "Find the exact value.", ans, w, gen, rng,
		{ROOT_FIRST: method(m_root, ans.values), POWER_FIRST: method(m_power, ans.values), PRIME: method(m_prime, ans.values)})


func u_solve_base(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var b: int = s.b
	var m: int = s.m
	var n: int = s.n
	var neg: bool = s.sgn < 0
	var e: Q = s.e
	var rhs: Q = s.rhs
	var pos := Q.new(m, n)
	var x: int = s.x
	var line := "%s = %s" % [XQ(e), rhs.text()]
	var ans := val_ans(s.val, "x = ")
	var km := RationalExponentsSituation.ipow(b, m)
	var head := ["%s, so %s = %d, taking the reciprocal of both sides." % [line, XQ(pos), km]] if neg else []
	var m_root: Array = head + ["Take the %s of both sides: %s = %d, as %s = %d." % [root_name(m) if m > 1 else "", XQ(Q.new(1, n)), b, pw(b, m), km],
		"Then raise both sides to the power %d: x = %s = %d." % [n, pw(b, n), x], "So x = %d." % x]
	if m == 1:
		m_root = head + ["Raise both sides to the power %d: x = %s = %d." % [n, pw(b, n), x], "So x = %d." % x]
	var kn := RationalExponentsSituation.ipow(km, n)
	var m_power: Array = head + ["Raise both sides to the power %d first: %s = %s = %d." % [n, XQ(Q.new(m)), pw(km, n), kn],
		"Then take the %s: x = %s = %d, as %s = %d and x > 0." % [root_name(m), pw(kn, Q.new(1, m)), x, pw(x, m), kn], "So x = %d." % x]
	var p: int = s.p
	var t: int = s.k * m * s.sgn
	var flip := Q.new(1).div(e)
	var m_prime: Array = ["%s = %s, so %s = %s." % [rhs.text(), pw(p, t), XQ(e), pw(p, t)],
		"Raise both sides to the power %s: x = (%s)^(%s) = %s = %d." % [flip.text(), pw(p, t), flip.text(), pw(p, Q.new(s.k * n)), x], "So x = %d." % x]
	var w: Array = [wv(Q.new(1, x) if neg else Q.new(b), R_NO_RECIP if neg else R_ROOT_ONLY, "x = "), walt("x = " + pw(rhs, e), R_SAME_POWER)]
	if neg:
		w.append(wv(Q.new(1, b), R_ROOT_ONLY, "x = "))
	else:
		w.append(wv(rhs.div(e), R_DIVIDE, "x = "))
	var gen: Array = gv([Q.new(x).add(1), Q.new(RationalExponentsSituation.ipow(b, n + 1)), Q.new(x * b), Q.new(km * n), Q.new(x).sub(1)].filter(func(q): return not q.eq(x) and q.sign() > 0), "x = ")
	return _number([line], "Find x, where x > 0.", ans, w, gen, rng,
		{ROOT_FIRST: method(m_root, ans.values), POWER_FIRST: method(m_power, ans.values), PRIME: method(m_prime, ans.values)})


# ── Powers of x ──────────────────────────────────────────────

func u_root_as_power(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var m: int = s.m
	var pw_x: Q = s.pw
	var pos := Q.new(m, n)
	var inside := root(n, "x" if m == 1 else "(%s)" % XQ(Q.new(m)))
	var outside := "(%s)%s" % [root(n, "x"), Fmt.sup(m)]
	var expr: String = {"inside": inside, "outside": outside, "recip": "1/" + inside}[s.shape]
	var ans := xpow_ans(pw_x)
	var rq := Q.new(1, n)
	var name := "a square root" if n == 2 else "a cube root"
	var m_root: Array = []
	var m_power: Array = []
	if m == 1:
		m_root = ["%s is %s, which is the power 1/%d: %s = %s." % [root(n, "x"), name, n, root(n, "x"), XQ(rq)]]
		m_power = m_root.duplicate()
	else:
		m_root = ["%s = %s, as %s is the power 1/%d." % [root(n, "x"), XQ(rq), name, n],
			"Then the power: %s = (%s)%s = %s, multiplying the powers." % [outside, XQ(rq), Fmt.sup(m), XQ(pos)]]
		if s.shape != "outside":
			m_root.push_front("Take the root first: %s = %s, as the root and the power can come in either order." % [inside, outside])
		m_power = ["Raise to the power first: %s = %s, as %s is the power 1/%d." % [inside, pw_text_x(Q.new(m), rq), name, n],
			"%s = x^(%d × 1/%d) = %s, multiplying the powers." % [pw_text_x(Q.new(m), rq), m, n, XQ(pos)]]
		if s.shape == "outside":
			m_power.push_front("%s = %s, as the root and the power can come in either order." % [outside, inside])
	if s.shape == "recip":
		var last := "So %s = 1/%s = %s, as 1 over a power is the negative power." % [expr, XQ(pos), XQ(pw_x)]
		m_root.append(last)
		m_power.append(last)
	else:
		m_root.append(said(ans))
		m_power.append(said(ans))
	var sg := -1 if s.shape == "recip" else 1
	var w: Array = [wx(Q.new(sg * n, m), R_FLIP)]
	if s.shape == "recip":
		w.append(wx(pos, R_NO_MINUS))
	if n == 3:
		w.append(wx(Q.new(sg * m, 2), R_SQUARE_ROOT))
	var gen: Array = [Q.new(sg * m), Q.new(sg * (m + 1), n), Q.new(sg * m, n + 1), pw_x.neg(), Q.new(sg * m * n)].filter(func(q): return not q.eq(pw_x)).map(func(q): return xv(q))
	var methods := {ROOT_FIRST: method(m_root, ans.values), POWER_FIRST: method(m_power, ans.values)}
	return _number([expr], "Write this as a power of x, in the form x^n.", ans, w, gen, rng, methods)


## (x^a)^b written out: "(x²)^(1/3)".
static func pw_text_x(a: Q, b: Q) -> String:
	return "(%s)^(%s)" % [XQ(a), b.text()]


func u_root_product_as_power(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var k: int = s.k
	var r := Q.new(1, n)
	var rt := root(n, "x")
	var xk := XQ(Q.new(k))
	var pw_x: Q = s.pw
	var ans := xpow_ans(pw_x)
	var expr: String
	var steps: Array = ["%s = %s, as %s is the power 1/%d." % [rt, XQ(r), "a square root" if n == 2 else "a cube root", n]]
	var w: Array = []
	match s.shape:
		"times":
			expr = xk + rt
			steps.append("%s × %s = x^(%d + %s) = %s, adding the powers." % [xk, XQ(r), k, r.text(), XQ(pw_x)])
			w = [wx(Q.new(k, n), R_MUL_EXP), wx(Q.new(k + 1, n + 1), R_TOPS_BOTTOMS)]
			if n == 3:
				w.append(wx(Q.new(k).add(Q.new(1, 2)), R_SQUARE_ROOT))
		"under":
			expr = "1/(%s%s)" % [xk, rt]
			var up := r.add(k)
			steps.append("%s × %s = x^(%d + %s) = %s, adding the powers." % [xk, XQ(r), k, r.text(), XQ(up)])
			steps.append("So %s = 1/%s = %s, as 1 over a power is the negative power." % [expr, XQ(up), XQ(pw_x)])
			w = [wx(Q.new(-k, n), R_MUL_EXP), wx(up, R_NO_MINUS)]
		"over":
			expr = "%s/%s" % [rt, xk]
			steps.append("%s/%s = x^(%s − %d) = %s, subtracting the powers." % [XQ(r), xk, r.text(), k, XQ(pw_x)])
			w = [wx(Q.new(1, n * k), R_DIV_EXP), wx(pw_x.neg(), R_WRONG_WAY)]
		"top":
			expr = "%s/%s" % [xk, rt]
			steps.append("%s/%s = x^(%d − %s) = %s, subtracting the powers." % [xk, XQ(r), k, r.text(), XQ(pw_x)])
			w = [wx(Q.new(k * n), R_DIV_EXP), wx(pw_x.neg(), R_WRONG_WAY)]
	steps.append(said(ans))
	var gen: Array = near_powers(pw_x).map(func(q): return xv(q))
	return _number([expr], "Write this as a power of x, in the form x^n.", ans, w, gen, rng, {LAWS: method(steps, ans.values)})


func u_bracket_power(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var b: int = s.b
	var c: int = s.c
	var m: int = s.m
	var n: int = s.n
	var q: int = s.q
	var e: Q = s.e
	var neg: bool = s.sgn < 0
	var co: Q = s.co
	var pw_x: Q = s.pw
	var expr := "(%s)^(%s)" % [term(Q.new(c), Q.new(q)), e.text()]
	var ans := mono_ans(co, pw_x)
	var bm := RationalExponentsSituation.ipow(b, m)
	var cm := RationalExponentsSituation.ipow(c, m)
	var num_end := "1/%d" % bm if neg else str(bm)
	var x_line := "%s = x^(%d × %s) = %s, multiplying the powers." % [pw_text_x(Q.new(q), e), q, PP(e), XQ(pw_x)]
	if q == 1:
		x_line = "x stays as %s, as only the number in front changes." % XQ(pw_x)
	var last := "So %s = %s." % [expr, Answer.text(ans)]
	var m_root := ["%s = %d, as %s = %d, so %s = %s = %s." % [pw(c, Q.new(1, n)), b, pw(b, n), c, pw(c, e), ("1/" if neg else "") + pw(b, m), num_end], x_line, last]
	var m_power := ["%s = %d, and %s = %d, as %s = %d, so %s = %s." % [pw(c, m), cm, pw(cm, Q.new(1, n)), bm, pw(bm, n), cm, pw(c, e), num_end], x_line, last]
	var p: int = s.p
	var t: int = s.k * n
	var m_prime := ["%d = %s, so %s = (%s)^(%s) = %s = %s." % [c, pw(p, t), pw(c, e), pw(p, t), e.text(), pw(p, e.mul(t)), co.text()], x_line, last]
	var w: Array = [wm(Q.new(c), pw_x, R_COEF), wm(co, e.add(q), R_ADD_BRACKET), wm(Q.new(c).mul(e), pw_x, R_TIMES)]
	if neg:
		w.append(wm(Q.new(bm), pw_x.neg(), R_NO_RECIP))
	var gen: Array = [mv(co, Q.new(q)), mv(co.mul(2), pw_x), mv(Q.new(b) if not neg else Q.new(1, b), pw_x), mv(co, pw_x.add(1)), mv(co, e)]
	return _number([expr], "Simplify this, in the form ax^n.", ans, w, gen, rng,
		{ROOT_FIRST: method(m_root, ans.values), POWER_FIRST: method(m_power, ans.values), PRIME: method(m_prime, ans.values)})


## A number to put after an operator: brackets only when it is negative, "(−2/3)".
static func PP(v: Q) -> String:
	return "(%s)" % v.text() if v.sign() < 0 else v.text()


## The sum of two fractions with the working's common denominator: "1/2 + 2/3 = 3/6 + 4/6 = 7/6".
static func frac_sum(a: Q, b: Q, sub: bool) -> String:
	var op := " − " if sub else " + "
	var out := a.text() + op + PP(b)
	var l := a.d * b.d / Q.gcd(a.d, b.d)
	if a.d != l or b.d != l:
		var an := a.n * (l / a.d)
		var bn := b.n * (l / b.d)
		var bt := "%d/%d" % [absi(bn), l]
		out += " = %s/%d%s%s" % [Q.new(an).text(), l, op, bt if bn >= 0 else "(−%s)" % bt]
	return out + " = " + (a.sub(b) if sub else a.add(b)).text()


func u_product_x(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var e1: Q = s.e1
	var e2: Q = s.e2
	var pw_x: Q = s.pw
	var coef: bool = s.shape == "coef"
	var co: Q = s.co
	var expr := "%s × %s" % [term(Q.new(s.a1), e1), term(Q.new(s.a2), e2)]
	var ans := mono_ans(co, pw_x) if coef else xpow_ans(pw_x)
	var steps: Array = []
	if coef:
		steps.append("Multiply the numbers: %d × %d = %d." % [s.a1, s.a2, co.n])
	steps.append("Add the powers: %s." % frac_sum(e1, e2, false))
	steps.append("So %s = %s." % [expr, Answer.text(ans)])
	var mk := func(c: Q, p: Q, ref: String) -> Dictionary:
		return wm(c, p, ref) if coef else wx(p, ref)
	var w: Array = [mk.call(co, e1.mul(e2), R_MUL_EXP)]
	var tb := Q.new(e1.n + e2.n, e1.d + e2.d)
	if not tb.eq(pw_x) and not tb.is_zero():
		w.append(mk.call(co, tb, R_TOPS_BOTTOMS))
	if coef:
		w.append(wm(Q.new(s.a1 + s.a2), pw_x, R_ADD_COEF))
	var gen: Array = []
	for p in near_powers(pw_x):
		gen.append(mv(co, p) if coef else xv(p))
	if coef:
		gen.push_front(mv(co.add(1), pw_x))
	return _number([expr], "Write this as a single term, in the form %s." % ("ax^n" if coef else "x^n"), ans, w, gen, rng, {LAWS: method(steps, ans.values)})


func u_quotient_x(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var e1: Q = s.e1
	var e2: Q = s.e2
	var A: int = s.A
	var B: int = s.B
	var pw_x: Q = s.pw
	var co: Q = s.co
	var top := term(Q.new(A), e1)
	var bottom := term(Q.new(B), e2)
	var expr := "%s/%s" % [top if A == 1 else "(%s)" % top, bottom if B == 1 else "(%s)" % bottom]
	var coef := not co.eq(1)
	var ans := mono_ans(co, pw_x) if coef else xpow_ans(pw_x)
	var steps: Array = []
	if B > 1:
		steps.append("Divide the numbers: %d ÷ %d = %d." % [A, B, co.n])
	steps.append("Subtract the powers: %s." % frac_sum(e1, e2, true))
	steps.append("So %s = %s." % [expr, Answer.text(ans)])
	var mk := func(c: Q, p: Q, ref: String) -> Dictionary:
		return wm(c, p, ref) if coef else wx(p, ref)
	var w: Array = [mk.call(co, e1.div(e2), R_DIV_EXP), mk.call(co, pw_x.neg(), R_WRONG_WAY)]
	if B > 1:
		w.append(wm(Q.new(A), pw_x, R_COEF_DIV))
	var gen: Array = []
	for p in near_powers(pw_x):
		gen.append(mv(co, p) if coef else xv(p))
	return _number([expr], "Write this as a single term, in the form %s." % ("ax^n" if coef else "x^n"), ans, w, gen, rng, {LAWS: method(steps, ans.values)})


## A number p^e for an option: a typed value when e is whole, else a power to pick.
static func power_option(p: int, e: Q, ref: String) -> Dictionary:
	if e.is_int():
		return wv(RationalExponentsSituation.qpow(Q.new(p), e.n), ref)
	return walt(pw(p, e), ref)


func u_product_numbers(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var p: int = s.p
	var A: int = s.A
	var B: int = s.B
	var r: Q = s.r
	var sq: Q = s.s
	var ri: Q = s.ri
	var sj: Q = s.sj
	var times: bool = s.op == "×"
	var expr := "%s %s %s" % [pw(A, r), s.op, pw(B, sq)]
	var ans := val_ans(s.val)
	var steps: Array = []
	for f in [[A, s.i, r, ri], [B, s.j, sq, sj]]:
		if f[1] == 1:
			steps.append("%d is already a power of %d." % [f[0], p])
		else:
			steps.append("%d = %s, so %s = %d^(%d × %s) = %s." % [f[0], pw(p, f[1]), pw(f[0], f[2]), p, f[1], PP(f[2]), pw(p, f[3])])
	var total := Q.new(s.T)
	steps.append("%s %s %s = %d^(%s) = %s = %s, %s the powers." % [pw(p, ri), s.op, pw(p, sj), p, frac_sum(ri, sj, not times).split(" = ")[0], pw(p, total),
		s.val.text(), "adding" if times else "subtracting"])
	steps.append("So the value is %s." % s.val.text())
	if steps[0].ends_with("power of %d." % p) and steps[1].ends_with("power of %d." % p):
		steps.remove_at(0)
	var w: Array = []
	if times:
		if not ri.mul(sj).eq(total):
			w.append(power_option(p, ri.mul(sj), R_MUL_EXP))
		w.append(walt(pw(A, r.add(sq)), R_TWO_BASES) if not r.add(sq).is_int() else wv(RationalExponentsSituation.qpow(Q.new(A), r.add(sq).n), R_TWO_BASES))
	else:
		if not ri.div(sj).eq(total):
			w.append(power_option(p, ri.div(sj), R_DIV_EXP))
		w.append(power_option(p, ri.add(sj), R_DIV_ADD))
	var val: Q = s.val
	var gen: Array = gv([val.mul(p), val.div(p), val.add(1), Q.new(1).div(val), val.mul(2)].filter(func(x): return not x.eq(val)))
	return _number([expr], "Find the exact value.", ans, w, gen, rng, {PRIME: method(steps, ans.values)})


# ── Splitting a quotient ─────────────────────────────────────

func u_split_two(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _split(s, rng)


func u_split_three(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _split(s, rng)


func _split(s: Dictionary, rng: Seeded) -> Dictionary:
	var tops: Array = s.tops
	var k: int = s.k
	var d: Q = s.dpow
	var dt: String = s.dtext
	var cs: Array = s.cs
	var ps: Array = s.ps
	var count := tops.size()
	var raw: Array = tops.map(func(t): return [Q.new(t[0]), Q.new(t[1])])
	var top := SUM(raw)
	var under := dt if k == 1 else "%d%s" % [k, dt]
	var under_b := under if k == 1 and not dt.contains("x√") else "(%s)" % under
	var expr := "(%s)/%s" % [top, under_b]
	var ans := sum_ans(cs, ps)
	var pieces: Array = []
	for i in count:
		var t: Array = raw[i]
		var body := term(t[0].abs_q(), t[1])
		var piece := "%s/%s" % [body, under_b]
		pieces.append([t[0].sign(), piece])
	var split_text := ""
	for pc in pieces:
		split_text += (("−" if pc[0] < 0 else "") if split_text == "" else (" − " if pc[0] < 0 else " + ")) + pc[1]
	var dline := "%s = %s" % [dt, XQ(d)]
	var each: Array = []
	for i in count:
		var t: Array = raw[i]
		each.append("%s/(%d%s) = %s" % [term(t[0].abs_q(), t[1]), k, XQ(d), term(cs[i].abs_q(), ps[i])])
	var steps := ["Split the fraction: %s = %s." % [expr, split_text],
		"%s, so take %s from each power%s." % [dline, d.text(), "" if k == 1 else " and divide each number by %d" % k],
		"Term by term: %s." % "; ".join(each), "So %s = %s." % [expr, Answer.text(ans)]]
	if k == 1:
		each.clear()
		for i in count:
			var t: Array = raw[i]
			each.append("%s/%s = %s" % [term(t[0].abs_q(), t[1]), XQ(d), term(cs[i].abs_q(), ps[i])])
		steps[2] = "Term by term: %s." % "; ".join(each)
	# Wrong options, each typed in the answer's slots.
	var w: Array = []
	var only_first: Array = [cs[0]]
	var only_pw: Array = [ps[0]]
	for i in range(1, count):
		only_first.append(raw[i][0])
		only_pw.append(raw[i][1])
	w.append(wrong(sv(only_first, only_pw), R_TOP_ONLY))
	w.append(wrong(sv(cs, ps.map(func(p): return p.add(d.mul(2)))), R_NO_MINUS))
	var mul_pw: Array = []
	var div_pw: Array = []
	for i in count:
		var tp: Q = raw[i][1]
		mul_pw.append(ps[i] if tp.is_zero() else tp.mul(d).neg())
		div_pw.append(ps[i] if tp.is_zero() else tp.div(d))
	w.append(wrong(sv(cs, mul_pw), R_MUL_EXP))
	w.append(wrong(sv(cs, div_pw), R_DIV_EXP))
	var gen: Array = []
	var flip0 := cs.duplicate()
	flip0[0] = cs[0].neg()
	var flip_last := cs.duplicate()
	flip_last[count - 1] = cs[count - 1].neg()
	var shift := ps.map(func(p): return p.sub(1))
	var times_k := cs.map(func(c): return c.mul(k)) if k > 1 else cs.map(func(c): return c.mul(2))
	gen = [sv(flip_last, ps), sv(cs, shift), sv(flip0, ps), sv(times_k, ps)]
	var asked := "Write this as a sum of powers of x, in the form %s." % ("ax^p + bx^q" if count == 2 else "ax^p + bx^q + cx^r")
	return _number([expr], asked, ans, w, gen, rng, {SPLIT: method(steps, ans.values)})
