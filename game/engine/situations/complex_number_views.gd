class_name ComplexNumberViews
extends ExtensionViews
## The views on the `complex-number` situation (FAL-1004): one builder per unknown of
## t1-ahl-complex-cartesian (AHL1.12), shared with t1-ai-complex-cartesian (AI-AHL1.12) through
## ComplexNumberAiViews, which sets the AI refs and puts every question on Paper 2.
##
## A complex answer is a `form` answer with its real and imaginary parts typed (slots re and im),
## written as the IB writes it: 3 − 2i, −i, (3/5)i. A modulus or a distance is exact (m√r) unless
## the GDC is the method, then 3 s.f.; an argument is a multiple of π on Paper 1 and radians to
## 3 s.f. on Paper 2.
##
## Representations: "equation" (the numbers written out) and "graph" (an Argand diagram,
## GraphView with the axes named Re and Im, the points lettered A and B; quadratic-roots draws the
## parabola y = x² + px + q with its vertex marked instead).
##
## A slip is named here by a key, and slips() gives its catalogue ref for the type: a slip with
## no ref on a type is not offered there. Every builder also gives fillers, wrong options with no
## slip behind them, since a form answer has no nudges.

const S := preload("res://engine/situations/complex_number.gd")
const AA := "AHL1.12."
const TA := "t1-ahl-complex-cartesian#"
const UNKNOWNS := ["power-of-i", "product", "quotient", "power", "real-parameter", "solve-linear", "equate-conjugate",
	"square-root", "root-substitute", "modulus", "argument", "argand-read", "argand-sum", "distance"]


## slip key -> the type's misconception ref (t1-ahl-complex-cartesian's list, in order).
func slips() -> Dictionary:
	return {
		"i3": AA + "powers-of-i#0", "coef": AA + "powers-of-i#1", "i2plus": AA + "cartesian-arithmetic#0",
		"i2plus-div": AA + "cartesian-arithmetic#0", "i2plus-pow": AA + "cartesian-arithmetic#0",
		"denom-only": AA + "cartesian-arithmetic#1", "pairwise": AA + "cartesian-arithmetic#2", "power-parts": AA + "cartesian-arithmetic#2",
		"quadrant": AA + "parts-modulus-argument#1", "mod-add": AA + "parts-modulus-argument#2", "mod-diff": AA + "parts-modulus-argument#2",
		"one-root": AA + "equate-parts#1", "conj-as-z": AA + "equate-parts#2", "swap-axes": AA + "argand-diagram#0",
		"conj-imag-axis": AA + "argand-diagram#1", "part-by-part": TA + "11", "times": TA + "12", "wrong-part": TA + "13",
		"k-sign": TA + "14", "conj-real-sign": TA + "15", "sqrt-swap": TA + "16", "sqrt-sign": TA + "17", "p-sign": TA + "18",
		"arctan-swap": TA + "19", "clockwise": TA + "20", "conj-neg": TA + "21", "add-not-sub": TA + "22",
		"dist-no-root": TA + "23", "sub-wrong-way": TA + "24", "sub-not-add": TA + "25", "no-brackets": TA + "26",
	}


func unknowns() -> Array:
	return UNKNOWNS


func needs() -> Dictionary:
	var out := {}
	for u in unknowns():
		out[u] = {"ask": u}
	return out


## AA HL: powers of i are a Paper 1 skill; the rest make both papers in the bank's ratio.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	if not has(unknown):
		return []
	return [1] if unknown == "power-of-i" else [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = S.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func T(z: Array) -> String:
	return S.text(z)


static func B(z: Array) -> String:
	return S.bracket(z)


## The answer z in the form a + bi, after head ("z = ", or "" for a value on its own).
static func cx_ans(head: String, z: Array) -> Dictionary:
	var ans := Answer.make("form", cx(head, z), {"parts": [head, {"slot": "re"}, " + ", {"slot": "im"}, "i"]})
	ans.exact = true
	return ans


static func cx(head: String, z: Array) -> Dictionary:
	return {"re": z[0], "im": z[1], "text": head + T(z)}


## A wrong option: the slip's value with its ref, or null when the type has no such slip.
func slip(key: String, values: Dictionary) -> Variant:
	var ref: String = slips().get(key, "")
	return wrong(values, ref) if ref != "" else null


## The slips that apply, with the nulls left out.
static func kept(ws: Array) -> Array:
	return ws.filter(func(w): return w != null)


## px + qy for a working line: "3x − 4y", "−y".
static func lin(p: Variant, x: String, q: Variant, y: String) -> String:
	var out := ""
	for pair in [[Q.of(p), x], [Q.of(q), y]]:
		var cq: Q = pair[0]
		if cq.is_zero():
			continue
		var body: String = Fmt.lead(cq.abs_q()) + pair[1]
		if out == "":
			out = ("−" if cq.sign() < 0 else "") + body
		else:
			out += (" − " if cq.sign() < 0 else " + ") + body
	return out if out != "" else "0"


## pk + q, with the letter k first: "2k + 3", "−k + 6", "4".
static func lin_k(p: Variant, q: Variant) -> String:
	var pq := Q.of(p)
	var qq := Q.of(q)
	var out := "" if pq.is_zero() else ("−" if pq.sign() < 0 else "") + Fmt.lead(pq.abs_q()) + "k"
	if qq.is_zero():
		return out if out != "" else "0"
	if out == "":
		return qq.text()
	return out + Fmt.plus(qq)


## The root of n: "√61", "6√2" or "13".
static func root_text(n: int) -> String:
	var sv := DistanceMidpointSituation.surd(n)
	return Answer.surd_text(sv[0], sv[1])


## head + √n, exact: a whole number, √r or m√r typed (as DistanceMidpointViews.length_ans).
static func root_ans(head: String, n: int) -> Dictionary:
	var sv := DistanceMidpointSituation.surd(n)
	var text := head + root_text(n)
	var ans: Dictionary
	if sv[1] == 1:
		ans = Answer.make("form", {"v": Q.new(sv[0]), "text": text}, {"parts": [head, {"slot": "v"}]})
	elif sv[0] == 1:
		ans = Answer.make("form", {"r": Q.new(sv[1]), "text": text}, {"parts": [head + "√", {"slot": "r"}]})
	else:
		ans = Answer.make("form", {"m": Q.new(sv[0]), "r": Q.new(sv[1]), "text": text}, {"parts": [head, {"slot": "m"}, "√", {"slot": "r"}]})
		ans.surd = true
	ans.exact = true
	return ans


## A wrong root option, in whatever shape its number takes: never typed.
static func root_val(head: String, n: int) -> Dictionary:
	return {"text": head + root_text(n), "shape": "other"}


static func sf_ans(head: String, x: float) -> Dictionary:
	var ans := Answer.make("number", {"v": GdcKit.qf(x)}, {}, head)
	ans.show = "sf"
	return ans


## The GDC's screen: 6 decimal places.
static func F(x: float) -> String:
	return ("−" if x < 0.0 else "") + "%.6f" % absf(x)


## A point (a, b) on an Argand diagram, as the working names it.
static func pt(z: Array) -> String:
	return "(%s, %s)" % [z[0].text(), z[1].text()]


## The Argand diagram: points [z, label] and segments from 0 to each point in `arrows`.
static func argand(points: Array, arrows: Array = []) -> Dictionary:
	var r := 4
	for p in points:
		for part in p[0]:
			r = maxi(r, ceili(absf(float(part.to_float()))) + 1)
	var curves: Array = []
	for z in arrows:
		curves.append([[0.0, 0.0], [z[0].to_float(), z[1].to_float()]])
	var pts: Array = []
	for p in points:
		pts.append({"x": p[0][0].to_float(), "y": p[0][1].to_float(), "label": p[1]})
	return {"x0": -r, "x1": r, "y0": -r, "y1": r, "x_name": "Re", "y_name": "Im", "curves": curves, "points": pts}


const READ_A := "The point A on the Argand diagram represents the complex number z."


func _pack(lines: Array, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary, graph: Variant = null) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "wrongs": kept(wrongs), "fillers": fillers, "methods": {}, "table": null, "graph": graph}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


static func gdc_steps(entry: String, shown: String, last: String) -> Array:
	return ["Set the GDC to a + bi mode and enter %s." % entry, "The GDC gives %s." % shown, last]


# ── Powers of i ──────────────────────────────────────────────

const UNITS := [[1, 0], [0, 1], [-1, 0], [0, -1]]


static func unit(r: int) -> Array:
	return S.c(UNITS[posmod(r, 4)][0], UNITS[posmod(r, 4)][1])


func u_power_of_i(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var k: int = s.k
	var r := n % 4
	var kn := 1
	for i in n:
		kn *= k
	var name := ("i" if k == 1 else "(%di)" % k) + Fmt.sup(n)
	var value := S.scale(unit(r), kn)
	var ans := cx_ans("", value)
	var wr: Array = []
	if r == 3:
		wr.append(slip("i3", cx("", S.scale(unit(1), kn))))
	if k > 1:
		wr.append(slip("coef", cx("", S.scale(unit(r), k))))
	var fill: Array = [cx("", S.scale(unit(r + 2), kn)), cx("", S.scale(unit(r + 1), kn)), cx("", S.scale(unit(r + 3), kn))]
	var last := "So %s = %s." % [name, T(value)]
	var head: Array = [] if k == 1 else ["%s = %d%s × i%s = %d × i%s" % [name, k, Fmt.sup(n), Fmt.sup(n), kn, Fmt.sup(n)]]
	var iv := T(unit(r))
	var rem := "%d = 4 × %d" % [n, n / 4] + (" + %d" % r if r > 0 else "")
	var cycle: Array = head + ["The powers of i repeat every 4: i, −1, −i, 1, then i again."]
	if r == 0:
		cycle.append("%s, so i%s = (i⁴)%s = 1." % [rem, Fmt.sup(n), Fmt.sup(n / 4)])
	else:
		cycle.append("%s, so i%s = %s." % [rem, Fmt.sup(n), iv] if r == 1 else "%s, so i%s = i%s = %s." % [rem, Fmt.sup(n), Fmt.sup(r), iv])
	cycle.append(last)
	var pair: Array = head.duplicate()
	if n % 2 == 0:
		pair.append("i%s = (i²)%s = (−1)%s = %s" % [Fmt.sup(n), Fmt.sup(n / 2), Fmt.sup(n / 2), iv])
	else:
		pair.append("i%s = (i²)%s × i = (−1)%s × i = %s" % [Fmt.sup(n), Fmt.sup(n / 2), Fmt.sup(n / 2), iv])
	pair.append(last)
	var turns: Array = head + ["Each factor of i turns a point a quarter turn anticlockwise about 0, starting from 1.",
		"%d quarter turns is %d full turns and %d quarter turn%s, which ends at %s." % [n, n / 4, r, "" if r == 1 else "s", iv], last]
	return _pack([name], "Simplify %s, giving your answer in the form a + bi." % name, ans, wr, fill, {
		"cycle-of-four": cycle, "powers-of-i-cycle": cycle, "pair-i-squared": pair, "quarter-turns": turns,
	})


# ── Products, quotients and powers ───────────────────────────

## The four terms of (a + bi)(c + di) before i² is replaced: "3 + 12i − 2i − 8i²".
static func four_terms(z: Array, w: Array) -> String:
	var ts: Array = [[z[0].mul(w[0]), ""], [z[0].mul(w[1]), "i"], [z[1].mul(w[0]), "i"], [z[1].mul(w[1]), "i²"]]
	var out := ""
	for t in ts:
		var cq: Q = t[0]
		if cq.is_zero():
			continue
		var body: String = (cq.abs_q().text() if t[1] == "" else Fmt.lead(cq.abs_q()) + t[1])
		if out == "":
			out = ("−" if cq.sign() < 0 else "") + body
		else:
			out += (" − " if cq.sign() < 0 else " + ") + body
	return out


## The expansion of z × w in two lines, ending on the product.
static func expand_lines(name: String, z: Array, w: Array) -> Array:
	var p := S.mul(z, w)
	var bd: Q = z[1].mul(w[1])
	return ["%s = %s%s = %s" % [name, B(z), B(w), four_terms(z, w)],
		"Replace i² with −1, so the i² term is %s: %s = %s" % [bd.neg().text(), name, T(p)]]


func u_product(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z: Array = s.z
	var w: Array = S.conj(s.w) if s.mode == "zwconj" else s.w
	var name: String = {"zw": "zw", "square": "z²", "zconj": "zz*", "zwconj": "zw*"}[s.mode]
	var lines: Array = ["z = " + T(z)] if s.mode in ["square", "zconj"] else ["z = " + T(z), "w = " + T(s.w)]
	var p := S.mul(z, w)
	var head := name + " = "
	var ans := cx_ans(head, p)
	var wr: Array = [slip("i2plus", cx(head, S.mul_plus(z, w))), slip("pairwise", cx(head, S.c(z[0].mul(w[0]), z[1].mul(w[1]))))]
	var fill: Array = [cx(head, S.conj(p)), cx(head, S.c(p[1], p[0])), cx(head, S.neg(p)), cx(head, S.mul(z, S.conj(w)))]
	var asked := "Find %s in the form a + bi." % name if s.mode != "zconj" else "Find the value of zz*."
	var expand := expand_lines(name, z, w)
	expand.append("So %s = %s." % [name, T(p)])
	var gdc := gdc_steps("%s%s" % [B(z), B(w)], T(p), "So %s = %s." % [name, T(p)])
	return _pack(lines, asked, ans, wr, fill, {"expand-brackets": expand, "gdc-complex": gdc})


## (e + fi) ÷ (c + di) by the conjugate, in two lines, ending on the quotient.
static func conj_lines(top: Array, w: Array, name: String) -> Array:
	var wc := S.conj(w)
	var num := S.mul(top, wc)
	var den := S.norm(w)
	var r := S.div(top, w)
	return ["Multiply the top and the bottom by the conjugate of %s, which is %s." % [T(w), T(wc)],
		"%s%s = %s and %s%s = %s" % [B(top), B(wc), T(num), B(w), B(wc), den.text()],
		"(%s)/%s = %s, so %s = %s." % [T(num), den.text(), T(r), name, T(r)]]


func u_quotient(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z: Array = s.z
	var w: Array = s.w
	var r: Array = s.r
	var head := "z/w = "
	var ans := cx_ans(head, r)
	var wc := S.conj(w)
	var nw := S.norm(w)
	var diff: Q = w[0].sq().sub(w[1].sq())
	var wr: Array = [slip("denom-only", cx(head, S.scale(z, Q.new(1).div(nw)))),
		slip("part-by-part", cx(head, S.c(z[0].div(w[0]), z[1].div(w[1])))),
		slip("diff-squares", cx(head, S.scale(S.mul(z, wc), Q.new(1).div(diff)))),
		slip("i2plus-div", cx(head, S.scale(S.mul_plus(z, wc), Q.new(1).div(diff))))]
	var fill: Array = [cx(head, S.conj(r)), cx(head, S.c(r[1], r[0])), cx(head, S.neg(r))]
	var gdc := gdc_steps("%s ÷ %s" % [B(z), B(w)], T(r), "So z/w = %s." % T(r))
	var by_conj := conj_lines(z, w, "z/w")
	return _pack(["z = " + T(z), "w = " + T(w)], "Express z/w in the form a + bi.", ans, wr, fill,
		{"realise-denominator": by_conj, "multiply-conjugate": by_conj, "gdc-complex": gdc, "gdc-divide": gdc})


## The left side of (c + di)z = e + fi as written: "(2 + i)z", "3iz", "−iz".
static func times_z(w: Array) -> String:
	if w[0].is_zero():
		return T(w) + "z"
	return B(w) + "z"


func u_solve_linear(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var w: Array = s.w
	var top: Array = s.z
	var r: Array = s.r
	var eq := "%s = %s" % [times_z(w), T(top)]
	var ans := cx_ans("z = ", r)
	var nw := S.norm(w)
	var wc := S.conj(w)
	var diff: Q = w[0].sq().sub(w[1].sq())
	var wr: Array = [slip("denom-only", cx("z = ", S.scale(top, Q.new(1).div(nw)))), slip("times", cx("z = ", S.mul(top, w))),
		slip("diff-squares", cx("z = ", S.scale(S.mul(top, wc), Q.new(1).div(diff))))]
	if not w[0].is_zero():
		wr.append(slip("part-by-part", cx("z = ", S.c(top[0].div(w[0]), top[1].div(w[1])))))
	var fill: Array = [cx("z = ", S.conj(r)), cx("z = ", S.c(r[1], r[0])), cx("z = ", S.neg(r))]
	var divide: Array = ["z = %s ÷ %s" % [B(top), B(w)]] + conj_lines(top, w, "z").slice(1)
	divide[0] += ". Multiply the top and the bottom by %s." % T(wc)
	# (c + di)(x + yi) = (cx − dy) + (dx + cy)i.
	var re := lin(w[0], "x", w[1].neg(), "y")
	var im := lin(w[1], "x", w[0], "y")
	var equate: Array = ["Let z = x + yi. Then %s(x + yi) = (%s) + (%s)i." % [B(w) if not w[0].is_zero() else T(w), re, im],
		"Equate the parts: %s = %s and %s = %s." % [re, top[0].text(), im, top[1].text()],
		"Solving these together gives x = %s and y = %s." % [r[0].text(), r[1].text()], "So z = %s." % T(r)]
	var gdc := gdc_steps("%s ÷ %s" % [B(top), B(w)], T(r), "So z = %s." % T(r))
	return _pack([eq], "Find z in the form a + bi.", ans, wr, fill,
		{"divide-directly": divide, "multiply-conjugate": divide, "substitute-x-iy": equate, "equate-parts": equate, "gdc-divide": gdc})


func u_power(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z: Array = s.z
	var n: int = s.n
	var p := S.power(z, n)
	var name := "z" + Fmt.sup(n)
	var head := name + " = "
	var ans := cx_ans(head, p)
	var an := 1
	var bn := 1
	for i in n:
		an *= z[0].n
		bn *= z[1].n
	var wr: Array = [slip("power-parts", cx(head, S.add(S.c(an, 0), S.scale(unit(n), bn)))),
		slip("no-brackets", cx(head, S.add(S.c(z[0], 0), S.scale(unit(n), z[1])))), slip("i2plus-pow", cx(head, S.power(z, n, true)))]
	var fill: Array = [cx(head, S.conj(p)), cx(head, S.c(p[1], p[0])), cx(head, S.neg(p))]
	var last := "So %s = %s." % [name, T(p)]
	# By hand: multiply by z once more each line.
	var expand: Array = ["z² = %s%s = %s" % [B(z), B(z), T(S.power(z, 2))]]
	for k in range(3, n + 1):
		expand.append("z%s = z%s × z = %s%s = %s" % [Fmt.sup(k), Fmt.sup(k - 1), B(S.power(z, k - 1)), B(z), T(S.power(z, k))])
	expand.append(last)
	# Squaring: z², z⁴, and the last power from those.
	var sq: Array = ["z² = %s² = %s" % [B(z), T(S.power(z, 2))]]
	if n >= 4:
		sq.append("z⁴ = (z²)² = %s² = %s" % [B(S.power(z, 2)), T(S.power(z, 4))])
	match n:
		3:
			sq.append("z³ = z² × z = %s%s = %s" % [B(S.power(z, 2)), B(z), T(p)])
		5:
			sq.append("z⁵ = z⁴ × z = %s%s = %s" % [B(S.power(z, 4)), B(z), T(p)])
		6:
			sq.append("z⁶ = z⁴ × z² = %s%s = %s" % [B(S.power(z, 4)), B(S.power(z, 2)), T(p)])
	sq.append(last)
	var gdc := gdc_steps("%s^%d, with the brackets" % [B(z), n], T(p), last)
	var methods := {"gdc-complex": gdc, "gdc-power": gdc, "repeated-squaring": sq}
	if n <= 4:
		methods["expand-brackets"] = expand
	return _pack(["z = " + T(z)], "Find %s in the form a + bi." % name, ans, wr, fill, methods)


# ── Equating real and imaginary parts ────────────────────────

func u_real_parameter(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m := Q.new(s.m)
	var w: Array = s.w
	var k: Q = s.k
	var cc: Q = w[0]
	var d: Q = w[1]
	var zt := "(k %s %s)%s" % ["−" if m.sign() < 0 else "+", S.i_term(m), B(w)]
	# (k + mi)(c + di) = (ck − md) + (dk + mc)i.
	var re := lin_k(cc, m.mul(d).neg())
	var im := lin_k(d, m.mul(cc))
	var asked: String = {"real": "Find the value of k for which z is real.", "imaginary": "Find the value of k for which z is purely imaginary.",
		"quarter": "Find the value of k for which arg z = π/4."}[s.mode]
	var ans := Answer.make("number", {"v": k}, {}, "k = ")
	ans.exact = true
	var wr: Array = [slip("k-sign", {"v": k.neg()})]
	match s.mode:
		"real":
			wr.append(slip("wrong-part", {"v": m.mul(d).div(cc)}))
		"imaginary":
			wr.append(slip("wrong-part", {"v": m.mul(cc).neg().div(d)}))
			wr.append(slip("i2plus", {"v": m.mul(d).neg().div(cc)}))
		"quarter":
			# With i² = +1 the real part is ck + md: ck + md = dk + mc.
			wr.append(slip("i2plus", {"v": m.mul(cc.sub(d)).div(cc.sub(d))}))
	var fill: Array = [{"v": k.mul(2)}, {"v": k.add(1)}, {"v": Q.new(1).div(k)}, {"v": k.sub(1)}]
	var p := S.mul([k, m], w)
	var cond: String
	match s.mode:
		"real":
			cond = "z is real when its imaginary part is 0: %s = 0" % im
		"imaginary":
			cond = "z is purely imaginary when its real part is 0: %s = 0" % re
		_:
			cond = "arg z = π/4 when the real and imaginary parts are equal and positive: %s = %s" % [re, im]
	var steps: Array = ["Expand, with i² = −1: z = (%s) + (%s)i." % [re, im], cond + "."]
	if s.mode == "quarter":
		steps.append("This gives k = %s, and then both parts are %s, which is positive." % [k.text(), p[0].text()])
	steps.append("So k = %s." % k.text())
	return _pack(["z = " + zt + ", where k is real."], asked, ans, wr, fill, {"expand-brackets": steps})


static func conj_eq_text(s: Dictionary) -> String:
	var a := Q.new(s.alpha)
	var b := Q.new(s.beta)
	var other := "z*" if s.mode == "conj" else "iz*"
	return "%sz %s %s%s = %s" % [Fmt.lead(a), "−" if b.sign() < 0 else "+", Fmt.lead(b.abs_q()), other, T(s.rhs)]


## The x + yi that a real-linear map f sends to rhs: f(x + yi) = x f(1) + y f(i).
static func solve_lin(f: Callable, rhs: Array) -> Array:
	var c1: Array = f.call(S.c(1, 0))
	var c2: Array = f.call(S.c(0, 1))
	var det: Q = c1[0].mul(c2[1]).sub(c2[0].mul(c1[1]))
	if det.is_zero():
		return []
	var x: Q = rhs[0].mul(c2[1]).sub(c2[0].mul(rhs[1])).div(det)
	var y: Q = c1[0].mul(rhs[1]).sub(rhs[0].mul(c1[1])).div(det)
	return [x, y]


func u_equate_conjugate(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z: Array = s.z
	var rhs: Array = s.rhs
	var a := Q.new(s.alpha)
	var b := Q.new(s.beta)
	var ans := cx_ans("z = ", z)
	var wr: Array = []
	var as_z: Array = S.div(rhs, S.c(a.add(b), 0) if s.mode == "conj" else S.c(a, b))
	wr.append(slip("conj-as-z", cx("z = ", as_z)))
	var mode: String = s.mode
	# z* taken as −x + yi: the conjugate with its real part's sign changed.
	var slipped := func(v: Array) -> Array:
		var star: Array = S.neg(S.conj(v))
		return S.add(S.scale(v, a), S.scale(star if mode == "conj" else S.times_i(star), b))
	var sign_slip := solve_lin(slipped, rhs)
	if not sign_slip.is_empty():
		wr.append(slip("conj-real-sign", cx("z = ", sign_slip)))
	var fill: Array = [cx("z = ", S.conj(z)), cx("z = ", S.neg(z)), cx("z = ", S.c(z[1], z[0]))]
	# αz + βz* = (α + β)x + (α − β)y i; αz + βiz* = (αx + βy) + (βx + αy)i.
	var re: String
	var im: String
	if s.mode == "conj":
		re = lin(a.add(b), "x", 0, "y")
		im = lin(0, "x", a.sub(b), "y")
	else:
		re = lin(a, "x", b, "y")
		im = lin(b, "x", a, "y")
	var left := conj_eq_text(s).split(" = ")[0]
	var steps: Array = ["Let z = x + yi, so z* = x − yi%s." % ("" if s.mode == "conj" else " and iz* = y + xi"),
		"Then %s = (%s) + (%s)i." % [left, re, im],
		"Equate the parts: %s = %s and %s = %s, so x = %s and y = %s." % [re, rhs[0].text(), im, rhs[1].text(), z[0].text(), z[1].text()],
		"So z = %s." % T(z)]
	return _pack([conj_eq_text(s)], "Find z, giving your answer in the form a + bi.", ans, wr, fill, {"substitute-x-iy": steps})


## ±(a + bi) with a > 0, as the answer and its options write it.
static func pm(z: Array) -> Array:
	return z if z[0].sign() > 0 or (z[0].is_zero() and z[1].sign() > 0) else S.neg(z)


static func pm_val(z: Array) -> Dictionary:
	var r := pm(z)
	return {"re": r[0], "im": r[1], "text": "±(%s)" % T(r)}


func u_square_root(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: Array = s.r
	var A: Q = s.z[0]
	var Bq: Q = s.z[1]
	var ans := Answer.make("form", pm_val(r), {"parts": ["±(", {"slot": "re"}, " + ", {"slot": "im"}, "i)"]})
	ans.exact = true
	var wr: Array = [slip("one-root", {"text": T(r), "shape": "other"}), slip("sqrt-swap", pm_val(S.c(r[1], r[0]))),
		slip("sqrt-sign", pm_val(S.conj(r)))]
	var fill: Array = [pm_val(S.c(r[1], r[0].neg())), pm_val(S.c(r[0].add(1), r[1])), pm_val(S.c(r[0], r[1].mul(2)))]
	var half: Q = Bq.div(2)
	var quartic := Fmt.terms([1, A.neg(), half.sq().neg()], [4, 2, 0], "a")
	var x: Q = r[0]
	var y: Q = r[1]
	var steps: Array = ["Let (a + bi)² = %s, with a and b real. Then a² − b² = %s and 2ab = %s." % [T(s.z), A.text(), Bq.text()],
		"So b = %s/a, and a² − %s/a² = %s, which gives %s = 0." % [half.text(), half.sq().text(), A.text(), quartic],
		"This factorises as (a² − %s)(a² + %s) = 0, and a is real, so a = ±%s." % [x.sq().text(), y.sq().text(), x.text()],
		"Then b = %s/a = ±%s, with the same sign as a." % [half.text(), y.text()] if y.sign() > 0 else "Then b = %s/a, so b = %s when a = %s." % [half.text(), y.text(), x.text()],
		"So the square roots are %s." % pm_val(r).text]
	return _pack(["z = " + T(s.z)], "Find the two square roots of z, in the form ±(a + bi) with a > 0.", ans, wr, fill, {"square-root-system": steps})


func u_root_substitute(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z: Array = s.z
	var m: Q = z[0]
	var n: Q = z[1]
	var p := m.mul(-2)
	var q := m.sq().add(n.sq())
	var names := {"names": ["p", "q"]}
	var ans := Answer.make("named", {"v0": p, "v1": q}, names)
	ans.exact = true
	var wr: Array = [slip("i2plus", {"v0": p, "v1": m.sq().sub(n.sq())}), slip("p-sign", {"v0": p.neg(), "v1": n.sq().sub(m.sq().mul(3))})]
	var fill: Array = [{"v0": p.neg(), "v1": q}, {"v0": p, "v1": q.neg()}, {"v0": m.neg(), "v1": q}]
	var sq := S.power(z, 2)
	var two_mn: Q = sq[1]
	var steps: Array = ["Substitute z = %s: %s² + p%s + q = 0, and %s² = %s." % [T(z), B(z), B(z), B(z), T(sq)],
		"Collect the parts: (%s + %sp + q) + (%s + %sp)i = 0." % [sq[0].text(), Fmt.lead(m), two_mn.text(), Fmt.lead(n)],
		"The imaginary part is 0: %s + %sp = 0, so p = %s." % [two_mn.text(), Fmt.lead(n), p.text()],
		"The real part is 0: %s%s + q = 0, so q = %s." % [sq[0].text(), Fmt.plus(m.mul(p)), q.text()],
		"So p = %s, q = %s." % [p.text(), q.text()]]
	return _pack(["The equation z² + pz + q = 0, where p and q are real, has a root z = %s." % T(z)],
		"Find the value of p and the value of q.", ans, wr, fill, {"substitute-x-iy": steps})


# ── Modulus and argument ─────────────────────────────────────

func u_modulus(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z: Array = s.z
	var a: int = z[0].n
	var b: int = z[1].n
	var n := a * a + b * b
	var head := "|z| = "
	var by_gdc := angle == "gdc-abs-angle"
	var ans := sf_ans(head, sqrt(float(n))) if by_gdc and DistanceMidpointSituation.surd(n)[1] != 1 else root_ans(head, n)
	var val := func(m: int) -> Dictionary:
		return {"v": GdcKit.qf(sqrt(float(m)))} if ans.kind == "number" else root_val(head, m)
	var wr: Array = [slip("mod-add", {"v": Q.new(absi(a) + absi(b))} if ans.kind == "number" else {"text": head + str(absi(a) + absi(b)), "shape": "other"}),
		slip("no-root", {"v": Q.new(n)} if ans.kind == "number" else {"text": head + str(n), "shape": "other"})]
	if a * a != b * b:
		wr.append(slip("mod-diff", val.call(absi(a * a - b * b))))
	var fill: Array = [val.call(2 * n), val.call(n + absi(a)), val.call(n + 2 * absi(b)), val.call(n + 1), val.call(n + 4),
		val.call((absi(a) + 1) * (absi(a) + 1) + b * b)]
	var lines: Array = ["z = " + T(z)] if rep == "equation" else [READ_A]
	var read: Array = [] if rep == "equation" else ["A is the point %s, so z = %s." % [pt(z), T(z)]]
	var exact: bool = ans.kind != "number"
	var shown := root_text(n) if exact else F(sqrt(float(n)))
	var last := "So |z| = %s." % (root_text(n) if exact else Fmt.sf(sqrt(float(n))))
	var pyth: Array = read + ["|z| = √(a² + b²) = √(%s² + %s²) = √%d" % [P(z[0]), P(z[1]), n], last]
	if exact and root_text(n) != "√%d" % n:
		pyth[-1] = "√%d = %s, so |z| = %s." % [n, root_text(n), root_text(n)]
	var sketch: Array = read + ["Plot z at %s. The sides of the right triangle from 0 along the axes are %d and %d." % [pt(z), absi(a), absi(b)],
		"|z| is the hypotenuse: √(%d² + %d²) = √%d%s" % [absi(a), absi(b), n, "" if root_text(n) == "√%d" % n else " = " + root_text(n)], last]
	var gdc: Array = read + ["Enter abs(%s) on the GDC." % T(z), "The GDC gives %s." % shown, last]
	return _pack(lines, "Find the exact value of |z|." if not by_gdc else "Find |z|.", ans, wr, fill,
		{"pythagoras-arctan": pyth, "pythag-arctan": pyth, "sketch-first": sketch, "argand-sketch": sketch, "gdc-abs-angle": gdc},
		null if rep == "equation" else argand([[z, "A"]]))


## A part m√r as written: "2√3", "−√3", "4".
static func surd_part(m: int, r: int) -> String:
	if r == 1:
		return Fmt.num(m)
	return ("−" if m < 0 else "") + ("" if absi(m) == 1 else str(absi(m))) + "√%d" % r


## A Paper 1 point on a 30°, 45° or 60° line: [re as [m, r], im as [m, r]].
static func special_parts(sp: Array) -> Array:
	var alpha: Q = sp[0]
	var quad: int = sp[1]
	var k: int = sp[2]
	var re := [k, 1]
	var im := [k, 1]
	if alpha.eq(Q.new(1, 6)):
		re = [k, 3]
	elif alpha.eq(Q.new(1, 3)):
		im = [k, 3]
	if quad in [2, 3]:
		re[0] = -re[0]
	if quad in [3, 4]:
		im[0] = -im[0]
	return [re, im]


static func special_text(parts: Array) -> String:
	var re: Array = parts[0]
	var im: Array = parts[1]
	var it: String
	if im[1] == 1:
		it = S.i_term(Q.new(absi(im[0])))
	else:
		it = surd_part(absi(im[0]), im[1]) + " i"
	return "%s %s %s" % [surd_part(re[0], re[1]), "−" if im[0] < 0 else "+", it]


## arg z as a multiple of π, from the reference angle and the quadrant.
static func special_arg(alpha: Q, quad: int) -> Q:
	match quad:
		1:
			return alpha
		2:
			return Q.new(1).sub(alpha)
		3:
			return Q.new(1).sub(alpha).neg()
	return alpha.neg()


const QUADRANTS := ["", "first", "second", "third", "fourth"]
const RATIOS := {"1/6": "1/√3", "1/4": "1", "1/3": "√3"}


static func pi_ans(th: Q) -> Dictionary:
	var ans := Answer.make("form", pi_val(th), {"parts": ["arg z = ", {"slot": "c"}, "π"]})
	ans.exact = true
	return ans


static func pi_val(th: Q) -> Dictionary:
	return {"c": th, "text": "arg z = " + Fmt.pi(th)}


func u_argument(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	if s.has("special"):
		return _argument_exact(rep, s)
	var z: Array = s.z
	var a: float = z[0].to_float()
	var b: float = z[1].to_float()
	var th := S.arg(z)
	var quad := (1 if b > 0 else 4) if a > 0 else (2 if b > 0 else 3)
	var head := "arg z = "
	var ans := sf_ans(head, th)
	var wr: Array = [slip("arctan-swap", {"v": GdcKit.qf(atan(a / b))})]
	if a < 0:
		wr.append(slip("quadrant", {"v": GdcKit.qf(atan(b / a))}))
	var fill: Array = [{"v": GdcKit.qf(-th)}, {"v": GdcKit.qf(th / 2.0)}, {"v": GdcKit.qf(th * 2.0 if absf(th) < 1.5 else th - PI / 2.0)}]
	var lines: Array = ["z = " + T(z)] if rep == "equation" else [READ_A]
	var read: Array = [] if rep == "equation" else ["A is the point %s, so z = %s." % [pt(z), T(z)]]
	var ref := atan(absf(b / a))
	var ratio := Q.new(absi(z[1].n), absi(z[0].n)).text()
	var placed: String
	match quad:
		1:
			placed = "In the first quadrant, arg z = %s." % F(th)
		2:
			placed = "In the second quadrant, arg z = π − %s = %s." % [F(ref), F(th)]
		3:
			placed = "In the third quadrant, arg z = −(π − %s) = %s." % [F(ref), F(th)]
		_:
			placed = "In the fourth quadrant, arg z = −%s." % F(ref)
	var last := "So arg z = %s." % Fmt.sf(th)
	var pyth: Array = read + ["z is in the %s quadrant. The angle with the real axis is arctan(%s) = %s." % [QUADRANTS[quad], ratio, F(ref)], placed, last]
	var sketch: Array = read + ["Sketch z at %s, in the %s quadrant, and measure from the positive real axis%s." % [pt(z), QUADRANTS[quad], ", clockwise as it is below it" if b < 0 else ""],
		"The angle between the line to z and the real axis is arctan(%s) = %s, so arg z = %s." % [ratio, F(ref), F(th)], last]
	var gdc: Array = read + ["Set the GDC to radians and enter angle(%s)." % T(z), "The GDC gives %s." % F(th), last]
	return _pack(lines, "Find arg z, giving your answer in radians, correct to 3 significant figures.", ans, wr, fill,
		{"pythagoras-arctan": pyth, "pythag-arctan": pyth, "sketch-first": sketch, "argand-sketch": sketch, "gdc-abs-angle": gdc},
		null if rep == "equation" else argand([[z, "A"]]))


func _argument_exact(rep: String, s: Dictionary) -> Dictionary:
	var alpha: Q = s.special[0]
	var quad: int = s.special[1]
	var parts := special_parts(s.special)
	var zt := special_text(parts)
	var th := special_arg(alpha, quad)
	var ans := pi_ans(th)
	var wr: Array = []
	# arctan(b/a) straight from the calculator: the reference angle with b/a's sign.
	var same_sign := quad in [1, 3]
	if quad in [2, 3]:
		wr.append(slip("quadrant", pi_val(alpha if same_sign else alpha.neg())))
	var beta := Q.new(1, 2).sub(alpha)
	wr.append(slip("arctan-swap", pi_val(beta if same_sign else beta.neg())))
	var fill: Array = [pi_val(th.neg()), pi_val(beta), pi_val(Q.new(1).sub(beta)), pi_val(alpha.sub(1))]
	# More multiples of π in −π < θ ≤ π, so four options read differently when two of these agree.
	for step in [Q.new(1, 6), Q.new(-1, 6), Q.new(1, 3), Q.new(-1, 3), Q.new(1, 2), Q.new(-1, 2)]:
		var other: Q = th.add(step)
		if Q.new(-1).lt(other) and not Q.new(1).lt(other):
			fill.append(pi_val(other))
	var re_t := surd_part(parts[0][0], parts[0][1])
	var im_t := surd_part(parts[1][0], parts[1][1])
	var shown := "A(%s, %s)" % [re_t, im_t]
	var lines: Array = ["z = " + zt] if rep == "equation" else ["The point %s on the Argand diagram represents the complex number z." % shown]
	var read: Array = [] if rep == "equation" else ["A is the point (%s, %s), so z = %s." % [re_t, im_t, zt]]
	var ratio: String = RATIOS[alpha.key()]
	var placed: String
	match quad:
		1:
			placed = "In the first quadrant, arg z = %s." % Fmt.pi(alpha)
		2:
			placed = "In the second quadrant, arg z = π − %s = %s." % [Fmt.pi(alpha), Fmt.pi(th)]
		3:
			placed = "In the third quadrant, arg z = −(π − %s) = %s." % [Fmt.pi(alpha), Fmt.pi(th)]
		_:
			placed = "In the fourth quadrant, arg z = −%s." % Fmt.pi(alpha)
	var last := "So arg z = %s." % Fmt.pi(th)
	var pyth: Array = read + ["z is in the %s quadrant. The angle with the real axis is arctan(%s) = %s." % [QUADRANTS[quad], ratio, Fmt.pi(alpha)], placed, last]
	var sketch: Array = read + ["Sketch z in the %s quadrant and measure from the positive real axis%s." % [QUADRANTS[quad], ", clockwise as it is below it" if quad > 2 else ""],
		"The angle between the line to z and the real axis is arctan(%s) = %s, so arg z = %s." % [ratio, Fmt.pi(alpha), Fmt.pi(th)], last]
	var graph: Variant = null
	if rep == "graph":
		var x := float(parts[0][0]) * sqrt(float(parts[0][1]))
		var y := float(parts[1][0]) * sqrt(float(parts[1][1]))
		var r := maxi(4, ceili(maxf(absf(x), absf(y))) + 1)
		graph = {"x0": -r, "x1": r, "y0": -r, "y1": r, "x_name": "Re", "y_name": "Im", "curves": [[[0.0, 0.0], [x, y]]],
			"points": [{"x": x, "y": y, "label": shown}]}
	return _pack(lines, "Find arg z, where −π < arg z ≤ π.", ans, wr, fill, {"pythagoras-arctan": pyth, "sketch-first": sketch}, graph)


# ── The Argand diagram ───────────────────────────────────────

func u_argand_read(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z: Array = s.z
	var mode: String = s.mode
	var name: String = {"z": "z", "conj": "z*", "neg": "−z", "iz": "iz"}[mode]
	var head := name + " = "
	var op := func(v: Array) -> Array:
		match mode:
			"conj":
				return S.conj(v)
			"neg":
				return S.neg(v)
			"iz":
				return S.times_i(v)
		return v
	var v: Array = op.call(z)
	var ans := cx_ans(head, v)
	var wr: Array = [slip("swap-axes", cx(head, op.call(S.c(z[1], z[0]))))]
	match mode:
		"conj":
			wr.append(slip("conj-imag-axis", cx(head, S.c(z[0].neg(), z[1]))))
			wr.append(slip("conj-neg", cx(head, S.neg(z))))
		"neg":
			wr.append(slip("conj-neg", cx(head, S.conj(z))))
		"iz":
			wr.append(slip("clockwise", cx(head, S.neg(S.times_i(z)))))
	var fill: Array = []
	for other in [S.conj(z), S.neg(z), S.times_i(z), z, S.c(z[0].neg(), z[1])]:
		if not S.same(other, v):
			fill.append(cx(head, other))
	var read := "A is the point %s: %s across and %s up, so z = %s." % [pt(z), z[0].text(), z[1].text(), T(z)]
	var last := "So %s = %s." % [name, T(v)]
	var plot: Array = [read]
	var turn: Array = ["A is the point %s, so z = %s." % [pt(z), T(z)]]
	match mode:
		"conj":
			plot.append("z* keeps the real part and changes the sign of the imaginary part: z* = %s." % T(v))
			turn.append("z* is z reflected in the real axis: %s goes to %s." % [pt(z), pt(v)])
		"neg":
			plot.append("−z changes the sign of both parts: −z = %s." % T(v))
			turn.append("−z is z turned through a half turn about 0: %s goes to %s." % [pt(z), pt(v)])
		"iz":
			plot.append("iz = i%s = %s, and i² = −1, so iz = %s." % [B(z), four_terms(S.c(0, 1), z), T(v)])
			turn.append("iz is z turned a quarter turn anticlockwise about 0: %s goes to %s." % [pt(z), pt(v)])
	plot.append(last)
	turn.append(last)
	var asked := "Write down %s in the form a + bi." % name if mode != "iz" else "Find iz in the form a + bi."
	var methods := {"plot-coordinates": plot}
	if mode != "z":
		methods["transformations"] = turn
	return _pack([READ_A], asked, ans, wr, fill, methods, argand([[z, "A"]], [z]))


func u_argand_sum(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z1: Array = s.z
	var z2: Array = s.w
	var sum: bool = s.mode == "sum"
	var name := "z₁ + z₂" if sum else "z₂ − z₁"
	var head := name + " = "
	var v := S.add(z1, z2) if sum else S.sub(z2, z1)
	var ans := cx_ans(head, v)
	var sw1 := S.c(z1[1], z1[0])
	var sw2 := S.c(z2[1], z2[0])
	var wr: Array = [slip("swap-axes", cx(head, S.add(sw1, sw2) if sum else S.sub(sw2, sw1)))]
	wr.append(slip("sub-not-add" if sum else "sub-wrong-way", cx(head, S.sub(z1, z2))))
	var fill: Array = [cx(head, S.sub(z2, z1) if sum else S.add(z1, z2)), cx(head, S.conj(v)), cx(head, S.neg(S.add(z1, z2)))]
	var read := "A is %s and B is %s, so z₁ = %s and z₂ = %s." % [pt(z1), pt(z2), T(z1), T(z2)]
	var mid: String
	if sum:
		mid = "Add as vectors, head to tail: z₁ + z₂ is the fourth corner of the parallelogram on 0, A and B, at %s." % pt(v)
	else:
		mid = "The vector from A to B is B − A: %s across and %s up." % [v[0].text(), v[1].text()]
	var asked := "Find z₁ + z₂ in the form a + bi." if sum else "The vector from A to B represents z₂ − z₁. Find z₂ − z₁ in the form a + bi."
	return _pack(["The points A and B on the Argand diagram represent the complex numbers z₁ and z₂."], asked, ans, wr, fill,
		{"vector-addition": [read, mid, "So %s = %s." % [name, T(v)]]}, argand([[z1, "A"], [z2, "B"]], [z1, z2]))


func u_distance(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z1: Array = s.z
	var z2: Array = s.w
	var d := S.sub(z2, z1)
	var n: int = S.norm(d).n
	var head := "|z₂ − z₁| = "
	var ans := root_ans(head, n)
	var wr: Array = [slip("add-not-sub", root_val(head, S.norm(S.add(z1, z2)).n)),
		slip("dist-no-root", {"text": head + str(n), "shape": "other"}), slip("no-root", {"text": head + str(n), "shape": "other"})]
	var fill: Array = [root_val(head, 2 * n), root_val(head, n + absi(d[0].n)), root_val(head, n + 2 * absi(d[1].n))]
	var lines: Array = ["z₁ = " + T(z1), "z₂ = " + T(z2)] if rep == "equation" else ["The points A and B on the Argand diagram represent the complex numbers z₁ and z₂."]
	var asked := "Find the exact distance between the points that represent z₁ and z₂ on an Argand diagram." if rep == "equation" else "Find the exact distance AB."
	var read: Array = [] if rep == "equation" else ["A is %s and B is %s, so z₁ = %s and z₂ = %s." % [pt(z1), pt(z2), T(z1), T(z2)]]
	var rt := root_text(n)
	var steps: Array = read + ["The distance is |z₂ − z₁|, and z₂ − z₁ = %s." % T(d),
		"|%s| = √(%s² + %s²) = √%d%s" % [T(d), P(d[0]), P(d[1]), n, "" if rt == "√%d" % n else " = " + rt], "So the distance is %s." % rt]
	steps[-1] = "So |z₂ − z₁| = %s." % rt
	return _pack(lines, asked, ans, wr, fill, {"distance-modulus": steps, "pythag-arctan": steps},
		null if rep == "equation" else argand([[z1, "A"], [z2, "B"]]))


# ── A real quadratic with complex roots (AI) ─────────────────

func u_quadratic_roots(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h := Q.new(s.h)
	var k := Q.new(s.kq)
	var p := h.mul(-2)
	var q := h.sq().add(k.sq())
	var poly := Fmt.terms([1, p, q], [2, 1, 0], "z")
	var roots := func(hh: Q, kk: Q) -> String:
		return "z = %s ± %s" % [hh.text(), S.i_term(kk)]
	var ans := Answer.make("form", {"h": h, "k": k, "text": roots.call(h, k)}, {"parts": ["z = ", {"slot": "h"}, " ± ", {"slot": "k"}, "i"]})
	ans.exact = true
	var wr: Array = [slip("not-halved", {"h": h, "k": k.mul(2), "text": roots.call(h, k.mul(2))}),
		slip("real-roots", {"text": "z = %s or z = %s" % [h.sub(k).text(), h.add(k).text()], "shape": "other"}),
		slip("no-solution", {"text": "There are no solutions.", "shape": "other"}),
		slip("h-sign", {"h": h.neg(), "k": k, "text": roots.call(h.neg(), k)})]
	var fill: Array = [{"h": h, "k": k.sq(), "text": roots.call(h, k.sq())}, {"h": h.neg(), "k": k.mul(2), "text": roots.call(h.neg(), k.mul(2))},
		{"h": h.mul(2), "k": k, "text": roots.call(h.mul(2), k)}]
	var disc := p.sq().sub(q.mul(4))
	var last := "So %s." % roots.call(h, k)
	var formula: Array = ["z = (−b ± √(b² − 4ac))/(2a) = (%s ± √(%s − %s))/2" % [p.neg().text(), p.sq().text(), q.mul(4).text()],
		"√(%s) = %si, so z = (%s ± %si)/2" % [disc.text(), k.mul(2).text(), p.neg().text(), k.mul(2).text()], last]
	var vertex := "(%s, %s)" % [h.text(), k.sq().text()]
	var square: Array = ["%s = (z %s)² + %s" % [poly, Fmt.plus(h.neg()).strip_edges(), k.sq().text()]]
	if rep == "graph":
		square = ["The vertex is at %s, so x² %s = (x %s)² + %s." % [vertex, poly.trim_prefix("z²").replace("z", "x"), Fmt.plus(h.neg()).strip_edges(), k.sq().text()]]
	square.append("(z %s)² = −%s, so z %s = ±%s" % [Fmt.plus(h.neg()).strip_edges(), k.sq().text(), Fmt.plus(h.neg()).strip_edges(), S.i_term(k)])
	square.append(last)
	var gdc: Array = ["Set the GDC's polynomial solver to a + bi mode and enter the coefficients 1, %s and %s." % [p.text(), q.text()],
		"It gives z = %s + %s and z = %s − %s." % [h.text(), S.i_term(k), h.text(), S.i_term(k)], last]
	var lines: Array = [poly + " = 0"]
	var asked := "Solve the equation, giving the roots in the form h ± ki."
	var graph: Variant = null
	if rep == "graph":
		var fx := Fmt.terms([1, p, q], [2, 1, 0], "x")
		lines = ["The diagram shows the graph of y = %s, with its vertex marked." % fx]
		asked = "Hence solve %s = 0, giving the roots in the form h ± ki." % poly
		var top := int(k.sq().to_float()) + 6
		graph = {"a": 1.0, "h": h.to_float(), "k": k.sq().to_float(), "x0": s.h - 5, "x1": s.h + 5, "y0": -2, "y1": top,
			"points": [{"x": h.to_float(), "y": k.sq().to_float(), "label": vertex}]}
	return _pack(lines, asked, ans, wr, fill, {"quadratic-formula": formula, "complete-square": square, "gdc-poly-solver": gdc}, graph)
