class_name ComplexPolarViews
extends ExtensionViews
## The views on the `complex-polar` situation (FAL-1005): one builder per unknown of
## t1-ahl-complex-polar (AHL1.13). DeMoivreViews, ConjugateRootsViews and ComplexPolarAiViews
## extend it for the other three types, and share its writing and answer helpers.
##
## A polar answer is a `form` answer: the modulus typed (r, or m and k for m√k) and the argument
## as a multiple of π (c), written re^(iθ) or r cis θ as the question asks. A Cartesian answer
## types each part's coefficient, with its root (√2, √3) written in the box's frame. A sentence
## (a transformation, an identity, an exact value) is a claim, picked from four.
##
## Representations: "equation" (the numbers written out) and "graph" (an Argand diagram,
## GraphView with the axes named Re and Im).
##
## A slip is named by a key, and slips() gives its catalogue ref for the type: a slip with no ref
## on a type is not offered there. Every builder also gives fillers, wrong options with no slip
## behind them.

const S := preload("res://engine/situations/complex_polar.gd")
const AA := "AHL1.13."
const TA := "t1-ahl-complex-polar#"
const UNKNOWNS := ["to-polar", "to-cartesian", "polar-product", "product-cartesian", "rotate-point", "describe-map",
	"euler-sum", "euler-trig", "exact-trig"]
const QUADRANTS := ["", "first", "second", "third", "fourth"]


## slip key -> the type's misconception ref (t1-ahl-complex-polar's list, in order).
func slips() -> Dictionary:
	return {
		"quadrant": AA + "convert-forms#0", "mod-add": AA + "convert-forms#1", "neg-mod": AA + "convert-forms#2",
		"arg-mul": AA + "polar-products-quotients#0", "mod-sum": AA + "polar-products-quotients#1", "arg-div": AA + "polar-products-quotients#2",
		"clockwise": AA + "geometric-interpretation#0", "rotation-only": AA + "geometric-interpretation#1",
		"add-rotates": AA + "geometric-interpretation#2", "two-mod": AA + "sums-in-euler-form#0", "add-exp": AA + "sums-in-euler-form#1",
		"no-i": AA + "sums-in-euler-form#2", "part-mod": AA + "exact-trig-from-forms#0", "sub-args": AA + "exact-trig-from-forms#1",
		"arctan-swap": TA + "14", "arg-sign": TA + "15", "trig-swap": TA + "16", "ref-signs": TA + "17", "unreduced": TA + "18",
		"quot-order": TA + "19", "square-mod": TA + "20", "mean-diff": TA + "21", "lost-two": TA + "22", "rev-sign": TA + "23",
		"re-for-im": TA + "24", "neg-vector": TA + "25",
	}


func unknowns() -> Array:
	return UNKNOWNS


func needs() -> Dictionary:
	var out := {}
	for u in unknowns():
		out[u] = {"ask": u}
	return out


## AA HL: these are exact, Paper 1 questions; a GDC method has its own Paper 2 cells.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = S.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func T(z: Array) -> String:
	return S.ctext(z)


static func PT(r: Array, c: Q, style: String) -> String:
	return S.ptext(r, c, style)


## The form a question asks for: "re^(iθ)" or "r cis θ".
static func form_name(style: String) -> String:
	return "re^(iθ)" if style == "euler" else "r cis θ"


static func polar_ask(name: String, style: String) -> String:
	return "Write %s in the form %s, where r > 0 and −π < θ ≤ π." % [name, form_name(style)]


## A surd squared, for a working line: "(−2√3)² = 12" is P2 of −2√3, "(−2)²".
static func P2(a: Array) -> String:
	var t := S.stext(a)
	return ("(%s)²" % t) if t.begins_with("−") or t.contains("√") or t.contains("/") else t + "²"


static func sq(a: Array) -> Q:
	return a[0].sq().mul(int(a[1]))


## The polar answer, typed as its modulus and argument.
static func polar_ans(head: String, r: Array, c: Q, style: String) -> Dictionary:
	var ans := Answer.make("form", pval(head, r, c, style), {"parts": polar_parts(head, r, style)})
	ans.exact = true
	return ans


static func polar_parts(head: String, r: Array, style: String) -> Array:
	var lead: Array = [head, {"slot": "r"}] if int(r[1]) == 1 else [head, {"slot": "m"}, "√", {"slot": "k"}]
	if style == "euler":
		return lead + [("" if int(r[1]) == 1 else " ") + "e^(", {"slot": "c"}, "πi)"]
	return lead + [" cis(", {"slot": "c"}, "π)"]


static func pval(head: String, r: Array, c: Q, style: String) -> Dictionary:
	var v := {"c": c, "text": head + PT(r, c, style)}
	if int(r[1]) == 1:
		v.r = r[0]
	else:
		v.m = r[0]
		v.k = Q.new(int(r[1]))
	return v


## A wrong polar option: typed where its modulus has the answer's shape, else only picked.
static func pwrong(ans: Dictionary, head: String, r: Array, c: Q, style: String) -> Dictionary:
	var v := pval(head, r, c, style)
	if v.has("r") != ans.values.has("r") or (v.has("k") and not v.k.eq(ans.values.k)):
		return {"text": v.text, "shape": "other"}
	return v


## A wrong option that is only written, never typed.
static func other(text: String) -> Dictionary:
	return {"text": text, "shape": "other"}


## The Cartesian answer a + bi: each part's coefficient typed, its root shown.
static func cart_ans(head: String, z: Array) -> Dictionary:
	var parts: Array = [head, {"slot": "a"}]
	if int(z[0][1]) != 1:
		parts.append("√%d" % z[0][1])
	parts.append(" + ")
	parts.append({"slot": "b"})
	parts.append("√%d i" % z[1][1] if int(z[1][1]) != 1 else "i")
	var ans := Answer.make("form", cval(head, z), {"parts": parts, "roots": [int(z[0][1]), int(z[1][1])]})
	ans.exact = true
	return ans


static func cval(head: String, z: Array) -> Dictionary:
	return {"a": z[0][0], "b": z[1][0], "text": head + T(z)}


## A wrong a + bi: typed where its roots are the answer's, else only picked.
static func cwrong(ans: Dictionary, head: String, z: Array) -> Dictionary:
	var roots: Array = ans.fixed.roots
	var same := func(i: int) -> bool: return S.szero(z[i]) or int(z[i][1]) == int(roots[i])
	if same.call(0) and same.call(1):
		return cval(head, z)
	return other(head + T(z))


static func claim(text: String) -> Dictionary:
	return {"form": text, "vals": [], "text": text}


static func claim_ans(text: String) -> Dictionary:
	return Answer.make("claim", claim(text))


## A wrong option: the slip's value with its ref, or null when the type has no such slip.
func slip(key: String, values: Dictionary) -> Variant:
	var ref: String = slips().get(key, "")
	return wrong(values, ref) if ref != "" else null


func _pack(lines: Array, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary, rng: Seeded, graph: Variant = null) -> Dictionary:
	var ws: Array = rng.shuffled(wrongs.filter(func(w): return w != null))
	var out := {"lines": lines, "asked": asked, "answer": ans, "wrongs": ws, "fillers": fillers, "methods": {}, "table": null, "graph": graph}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


## The angle in words for a working line: "the second quadrant", "the negative real axis".
static func where(c: Q) -> String:
	var q := S.quadrant(c)
	if q > 0:
		return "the %s quadrant" % QUADRANTS[q]
	if c.eq(1):
		return "the negative real axis"
	if c.is_zero():
		return "the positive real axis"
	return "the positive imaginary axis" if c.sign() > 0 else "the negative imaginary axis"


## The reference angle: the acute angle cπ makes with the real axis, as a multiple of π.
static func ref_angle(c: Q) -> Q:
	var a := c.abs_q()
	return a if not Q.new(1, 2).lt(a) else Q.new(1).sub(a)


## How the argument follows from the reference angle α in its quadrant.
static func placed(c: Q) -> String:
	var al := Fmt.pi(ref_angle(c))
	match S.quadrant(c):
		1:
			return "In the first quadrant, θ = %s." % al
		2:
			return "In the second quadrant, θ = π − %s = %s." % [al, Fmt.pi(c)]
		3:
			return "In the third quadrant, θ = −(π − %s) = %s." % [al, Fmt.pi(c)]
		4:
			return "In the fourth quadrant, θ = −%s." % al
	return "On %s, θ = %s." % [where(c), Fmt.pi(c)]


## |z|² from the parts, for a working line: "√((−2√3)² + 2²) = √16 = 4".
static func mod_line(z: Array, r: Array) -> String:
	var n: Q = sq(z[0]).add(sq(z[1]))
	var out := "r = √(%s + %s) = √%s" % [P2(z[0]), P2(z[1]), n.text()]
	var rt := S.stext(r)
	return out + ("" if rt == n.text() or ("√" + n.text()) == rt else " = " + rt)


## The exact cos and sin of an angle, for a working line: "cos(5π/6) = −√3/2 and sin(5π/6) = 1/2".
static func trig_line(c: Q) -> String:
	var cs := S.cos_sin(c)
	return "cos(%s) = %s and sin(%s) = %s" % [Fmt.pi(c), S.stext(cs[0]), Fmt.pi(c), S.stext(cs[1])]


## The point (a, b) as the working names it.
static func pt(z: Array) -> String:
	return "(%s, %s)" % [S.stext(z[0]), S.stext(z[1])]


## An Argand diagram with the points [z, label], a segment from 0 to each point in `arrows`.
static func argand(points: Array, arrows: Array = []) -> Dictionary:
	var r := 4
	for p in points:
		for part in p[0]:
			r = maxi(r, ceili(absf(S.sval(part))) + 1)
	var curves: Array = []
	for z in arrows:
		curves.append([[0.0, 0.0], [S.sval(z[0]), S.sval(z[1])]])
	var pts: Array = []
	for p in points:
		pts.append({"x": S.sval(p[0][0]), "y": S.sval(p[0][1]), "label": p[1]})
	return {"x0": -r, "x1": r, "y0": -r, "y1": r, "x_name": "Re", "y_name": "Im", "curves": curves, "points": pts}


const READ_A := "The point A on the Argand diagram represents the complex number z."


# ── Cartesian to polar and back ──────────────────────────────

## arctan(b/a) straight from a calculator, as a multiple of π: the reference angle with b/a's sign.
static func atan_ratio(c: Q) -> Q:
	var al := ref_angle(c)
	return al if S.quadrant(c) in [1, 3] else al.neg()


func u_to_polar(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: Array = s.r
	var c: Q = s.c
	var style: String = s.style
	var z := S.cart(r, c)
	var head := "z = "
	var ans := polar_ans(head, r, c, style)
	var q := S.quadrant(c)
	var wr: Array = []
	if q in [2, 3]:
		wr.append(slip("quadrant", pwrong(ans, head, r, atan_ratio(c), style)))
	elif c.eq(1):
		wr.append(slip("quadrant", other(head + PT(r, Q.new(0), style))))
	if S.family(c) == 4:
		wr.append(slip("mod-add", pwrong(ans, head, S.sd(z[0][0].abs_q().add(z[1][0].abs_q())), c, style)))
	if q == 0:
		var flip := S.principal(c.add(1))
		wr.append(slip("neg-mod", other(head + ("−%s" % S.stext(r)) + ("e^(%s)" % S.pi_i(flip) if style == "euler" else " cis(%s)" % Fmt.pi(flip)) if not flip.is_zero() \
			else head + "−" + S.stext(r) + ("e^(0)" if style == "euler" else " cis 0"))))
	if q > 0:
		var sw := Q.new(1, 2).sub(ref_angle(c))
		wr.append(slip("arctan-swap", pwrong(ans, head, r, sw if q in [1, 3] else sw.neg(), style)))
	if not c.eq(1):
		wr.append(slip("arg-sign", pwrong(ans, head, r, c.neg(), style)))
	var fill: Array = [pwrong(ans, head, r, S.principal(c.add(Q.new(1, 2))), style), pwrong(ans, head, r, S.principal(c.sub(Q.new(1, 2))), style),
		pwrong(ans, head, S.sscale(r, 2), c, style), pwrong(ans, head, r, S.principal(Q.new(1).sub(c)), style)]
	var lines: Array = ["z = " + T(z)]
	var read: Array = []
	var graph: Variant = null
	if rep == "graph":
		lines = ["The point A%s on the Argand diagram represents the complex number z." % pt(z)]
		read = ["A is the point %s, so z = %s." % [pt(z), T(z)]]
		graph = argand([[z, "A" + pt(z)]], [z])
	var last := "So z = %s." % PT(r, c, style)
	var ma: Array
	if q == 0:
		ma = read + ["z is on %s, %s from 0, so r = %s." % [where(c), S.stext(r), S.stext(r)], "The argument of a point on %s is %s." % [where(c), Fmt.pi(c)], last]
	else:
		ma = read + [mod_line(z, r), "z is in %s. The angle with the real axis is arctan(%s) = %s." % [where(c), S.stext(S.sd(z[1][0].abs_q(), z[1][1])) + "/" + S.stext(S.sd(z[0][0].abs_q(), z[0][1])), Fmt.pi(ref_angle(c))],
			placed(c), last]
	var sk: Array = read + ["Sketch z at %s: it is on %s, %s from 0, so r = %s." % [pt(z), where(c), S.stext(r), S.stext(r)]]
	if q > 0:
		sk.append("The line to z makes %s with the real axis, measured %s from the positive real axis, so θ = %s." % [Fmt.pi(ref_angle(c)), "anticlockwise" if c.sign() > 0 else "clockwise", Fmt.pi(c)])
	else:
		sk.append("Measured from the positive real axis, %s is at θ = %s." % [where(c), Fmt.pi(c)])
	sk.append(last)
	return _pack(lines, polar_ask("z", style), ans, wr, fill, {"modulus-argument": ma, "sketch-and-read": sk}, _rng, graph)


func u_to_cartesian(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var r: Array = s.r
	var c: Q = s.c
	var style: String = s.style
	var z := S.cart(r, c)
	var head := "z = "
	var ans := cart_ans(head, z)
	var wr: Array = [slip("trig-swap", cwrong(ans, head, [z[1], z[0]]))]
	if S.quadrant(c) != 1:
		wr.append(slip("ref-signs", cwrong(ans, head, [S.sd(z[0][0].abs_q(), z[0][1]), S.sd(z[1][0].abs_q(), z[1][1])])))
	var fill: Array = [cwrong(ans, head, [z[0], S.sneg(z[1])]), cwrong(ans, head, [S.sneg(z[0]), S.sneg(z[1])]), cwrong(ans, head, [S.sneg(z[0]), z[1]]),
		cwrong(ans, head, [S.sscale(z[0], 2), S.sscale(z[1], 2)])]
	var cs := S.cos_sin(c)
	var last := "So z = %s." % T(z)
	var expand: Array = ["z = %s(cos(%s) + i sin(%s))" % [S.stext(r) if not S.ssame(r, S.sd(1)) else "", Fmt.pi(c), Fmt.pi(c)], trig_line(c) + ".",
		"So the real part is %s × %s = %s and the imaginary part is %s × %s = %s." % [S.stext(r), S.stext(cs[0]), S.stext(z[0]), S.stext(r), S.stext(cs[1]), S.stext(z[1])], last]
	var sk: Array = ["θ = %s puts z in %s, %s from 0." % [Fmt.pi(c), where(c), S.stext(r)],
		"The right triangle to the real axis has angle %s, so its sides are %s across and %s up or down." % [Fmt.pi(ref_angle(c)), S.stext(S.sd(z[0][0].abs_q(), z[0][1])), S.stext(S.sd(z[1][0].abs_q(), z[1][1]))],
		"In %s the real part is %s and the imaginary part %s." % [where(c), "negative" if z[0][0].sign() < 0 else "positive" if z[0][0].sign() > 0 else "0", "negative" if z[1][0].sign() < 0 else "positive" if z[1][0].sign() > 0 else "0"], last]
	return _pack(["z = " + PT(r, c, style)], "Write z in the form a + bi.", ans, wr, fill, {"expand-cis": expand, "sketch-and-read": sk}, rng)


# ── Products and quotients ───────────────────────────────────

## The two numbers' lines and the name of what is asked: "z₁z₂", "z₁/z₂", "z²".
static func pp_names(s: Dictionary) -> Array:
	match s.mode:
		"product":
			return ["z₁z₂", ["z₁ = " + PT(s.r, s.c, s.style), "z₂ = " + PT(s.r2, s.c2, s.style)]]
		"quotient":
			return ["z₁/z₂", ["z₁ = " + PT(s.r, s.c, s.style), "z₂ = " + PT(s.r2, s.c2, s.style)]]
	return ["z²", ["z = " + PT(s.r, s.c, s.style)]]


## The answer's modulus and its argument before it is brought into −π < θ ≤ π.
static func pp_value(s: Dictionary) -> Array:
	match s.mode:
		"product":
			return [S.sd(s.r[0].mul(s.r2[0])), s.c.add(s.c2)]
		"quotient":
			return [S.sd(s.r[0].div(s.r2[0])), s.c.sub(s.c2)]
	return [S.sd(s.r[0].sq()), s.c.mul(2)]


## cπ² for a slip that multiplies two arguments: "π²/36", "−π²/8".
static func pi2(c: Q) -> String:
	var top := "π²" if absi(c.n) == 1 else "%dπ²" % absi(c.n)
	return ("−" if c.n < 0 else "") + top + ("" if c.d == 1 else "/%d" % c.d)


## r with an argument that is a plain number (a slip): "3 cis(4)", "3e^(4i)", "3e^(−2i/3)".
static func plain_arg(r: Array, x: Q, style: String) -> String:
	var rt := S.stext(r)
	if style == "euler":
		var top := ("" if absi(x.n) == 1 else str(absi(x.n))) + "i"
		return rt + "e^(%s%s%s)" % ["−" if x.sign() < 0 else "", top, "" if x.d == 1 else "/%d" % x.d]
	return rt + " cis(%s)" % x.text()


func u_polar_product(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var nm: Array = pp_names(s)
	var name: String = nm[0]
	var style: String = s.style
	var v := pp_value(s)
	var R: Array = v[0]
	var raw: Q = v[1]
	var C := S.principal(raw)
	var head := name + " = "
	var ans := polar_ans(head, R, C, style)
	var r1: Q = s.r[0]
	var c1: Q = s.c
	var wr: Array = []
	match s.mode:
		"product":
			var r2: Q = s.r2[0]
			var c2: Q = s.c2
			var pr := c1.mul(c2)
			wr.append(slip("arg-mul", other(head + (S.stext(R) + "e^(%si)" % pi2(pr) if style == "euler" else S.stext(R) + " cis(%s)" % pi2(pr)))))
			wr.append(slip("mod-sum", pwrong(ans, head, S.sd(r1.add(r2)), C, style)))
		"quotient":
			var c2: Q = s.c2
			wr.append(slip("arg-div", other(head + plain_arg(R, c1.div(c2), style))))
			wr.append(slip("quot-order", pwrong(ans, head, R, S.principal(c2.sub(c1)), style)))
		"square":
			wr.append(slip("square-mod", pwrong(ans, head, S.sd(r1.mul(2)), C, style)))
	if not raw.eq(C):
		wr.append(slip("unreduced", pwrong(ans, head, R, raw, style)))
	var fill: Array = [pwrong(ans, head, R, C.neg(), style), pwrong(ans, head, R, S.principal(C.add(Q.new(1, 2))), style),
		pwrong(ans, head, S.sscale(R, 2), C, style), pwrong(ans, head, R, S.principal(C.add(1)), style)]
	var last := "So %s = %s." % [name, PT(R, C, style)]
	var adjust := "%s is outside −π < θ ≤ π, so %s 2π: %s %s 2π = %s." % [Fmt.pi(raw), "take away" if raw.sign() > 0 else "add", Fmt.pi(raw), "−" if raw.sign() > 0 else "+", Fmt.pi(C)]
	var rules: Array
	var index: Array
	var c2: Q = s.get("c2", Q.new(0))
	match s.mode:
		"product":
			rules = ["|z₁z₂| = |z₁||z₂| = %s × %s = %s" % [r1.text(), s.r2[0].text(), S.stext(R)],
				"arg(z₁z₂) = arg z₁ + arg z₂ = %s + %s = %s" % [Fmt.pi(c1), Fmt.paren(c2).replace(c2.text(), Fmt.pi(c2)) if c2.sign() < 0 else Fmt.pi(c2), Fmt.pi(raw)]]
			index = ["z₁z₂ = %s × %s = (%s × %s)e^(%s + %s)" % [PT(s.r, c1, "euler"), PT(s.r2, c2, "euler"), r1.text(), s.r2[0].text(), S.pi_i(c1), "(" + S.pi_i(c2) + ")" if c2.sign() < 0 else S.pi_i(c2)],
				"= %se^(%s)" % [S.stext(R), S.pi_i(raw)]]
		"quotient":
			rules = ["|z₁/z₂| = |z₁|/|z₂| = %s/%s = %s" % [r1.text(), s.r2[0].text(), S.stext(R)],
				"arg(z₁/z₂) = arg z₁ − arg z₂ = %s − %s = %s" % [Fmt.pi(c1), "(" + Fmt.pi(c2) + ")" if c2.sign() < 0 else Fmt.pi(c2), Fmt.pi(raw)]]
			index = ["z₁/z₂ = (%s/%s)e^(%s − %s)" % [r1.text(), s.r2[0].text(), S.pi_i(c1), "(" + S.pi_i(c2) + ")" if c2.sign() < 0 else S.pi_i(c2)],
				"= %se^(%s)" % [S.stext(R), S.pi_i(raw)]]
		_:
			rules = ["|z²| = |z|² = %s² = %s" % [r1.text(), S.stext(R)], "arg(z²) = 2 arg z = 2 × %s = %s" % [Fmt.pi(c1), Fmt.pi(raw)]]
			index = ["z² = (%s)² = %s²e^(2 × %s)" % [PT(s.r, c1, "euler"), r1.text(), S.pi_i(c1)], "= %se^(%s)" % [S.stext(R), S.pi_i(raw)]]
	if not raw.eq(C):
		rules.append(adjust)
		index.append(adjust)
	rules.append(last)
	index.append(last)
	var methods := {"modulus-argument-rules": rules, "euler-index-laws": index}
	if not raw.eq(C):
		methods["argument-adjust"] = ["Multiply the moduli and %s the arguments: |%s| = %s and the arguments give %s." % ["subtract" if s.mode == "quotient" else "add", name, S.stext(R), Fmt.pi(raw)],
			adjust, last]
	var asked := polar_ask(name, style)
	return _pack(nm[1], asked, ans, wr, fill, methods, rng)


func u_product_cartesian(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var nm: Array = pp_names(s)
	var name: String = nm[0]
	var v := pp_value(s)
	var R: Array = v[0]
	var raw: Q = v[1]
	var C := S.principal(raw)
	var z := S.cart(R, C)
	var head := name + " = "
	var ans := cart_ans(head, z)
	var wr: Array = [slip("trig-swap", cwrong(ans, head, [z[1], z[0]]))]
	if s.mode == "product":
		wr.append(slip("mod-sum", cwrong(ans, head, S.cart(S.sd(s.r[0].add(s.r2[0])), C))))
	else:
		wr.append(slip("quot-order", cwrong(ans, head, S.cart(R, S.principal(s.c2.sub(s.c))))))
	var fill: Array = [cwrong(ans, head, [z[0], S.sneg(z[1])]), cwrong(ans, head, [S.sneg(z[0]), S.sneg(z[1])]), cwrong(ans, head, [S.sneg(z[0]), z[1]]),
		cwrong(ans, head, [S.sscale(z[0], 2), S.sscale(z[1], 2)])]
	var cs := S.cos_sin(C)
	var last := "So %s = %s." % [name, T(z)]
	var op := "multiply" if s.mode == "product" else "divide"
	var both: Array = ["%s the moduli and %s the arguments: |%s| = %s and arg(%s) = %s%s." % [op.capitalize(), "add" if s.mode == "product" else "subtract", name, S.stext(R), name, Fmt.pi(raw),
		"" if raw.eq(C) else ", which is " + Fmt.pi(C)],
		"So %s = %s, and %s." % [name, PT(R, C, "cis"), trig_line(C)],
		"%s = %s(%s + %s i) = %s" % [name, S.stext(R), S.stext(cs[0]), "(" + S.stext(cs[1]) + ")" if cs[1][0].sign() < 0 else S.stext(cs[1]), T(z)], last]
	var index: Array = ["%s = %s" % [name, ("(%s)(%s)" if s.mode == "product" else "(%s)/(%s)") % [PT(s.r, s.c, "euler"), PT(s.r2, s.c2, "euler")]],
		"= %se^(%s)%s" % [S.stext(R), S.pi_i(raw), "" if raw.eq(C) else " = %se^(%s)" % [S.stext(R), S.pi_i(C)]],
		"= %s(cos(%s) + i sin(%s)) = %s" % [S.stext(R), Fmt.pi(C), Fmt.pi(C), T(z)], last]
	return _pack(nm[1], "Express %s in the form a + bi." % name, ans, wr, fill, {"modulus-argument-rules": both, "euler-index-laws": index}, rng)


# ── The Argand diagram: rotations, enlargements, translations ─

## A turn in words: "π/2 anticlockwise", "π/2 clockwise", "π".
static func turn(c: Q) -> String:
	if c.eq(1):
		return "π"
	return "%s %s" % [Fmt.pi(c.abs_q()), "anticlockwise" if c.sign() > 0 else "clockwise"]


func u_rotate_point(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var z: Array = s.z
	var c: Q = s.c
	var k: int = s.k
	var w: Array = s.w
	var image := cmul(w, z)
	var head := "B = "
	var ans := cart_ans(head, image)
	var wr: Array = []
	if not c.eq(1):
		wr.append(slip("clockwise", cwrong(ans, head, cmul(S.cart(S.sd(k), c.neg()), z))))
	if k > 1:
		wr.append(slip("rotation-only", cwrong(ans, head, cmul(S.cart(S.sd(1), c), z))))
	var fill: Array = [cwrong(ans, head, S.cx(image[0][0].neg(), image[1][0].neg())), cwrong(ans, head, cmul(w, [z[0], S.sneg(z[1])])),
		cwrong(ans, head, S.cx(z[0][0].mul(k), z[1][0].mul(k))), cwrong(ans, head, S.cx(image[1][0], image[0][0]))]
	var how := "rotated through %s about the origin" % turn(c)
	if k > 1:
		how += ", then enlarged with scale factor %d and centre the origin," % k
	var asked := "A is %s to give the point B. Find the complex number that B represents, in the form a + bi." % how
	var mult := "%s%s" % ["" if k == 1 else str(k), {"1/2": "i", "-1/2": "(−i)", "1": "(−1)"}[c.key()]]
	var mult_t := T(w)
	var steps: Array = ["A is the point %s, so z = %s." % [pt(z), T(z)],
		"A turn of %s about 0 is multiplying by %s%s, so B represents %sz." % [turn(c), T(S.cart(S.sd(1), c)), "" if k == 1 else ", and enlarging by %d multiplies by %d" % [k, k], mult_t if mult_t != "i" else "i"],
		"%s × (%s) = %s" % [mult_t, T(z), T(image)], "So B = %s." % T(image)]
	var _unused := mult
	return _pack([READ_A], asked, ans, wr, fill, {"rotation-enlargement": steps}, rng, argand([[z, "A"]], [z]))


## The product of two complex numbers with whole parts.
static func cmul(w: Array, z: Array) -> Array:
	var a: Q = w[0][0]
	var b: Q = w[1][0]
	var c: Q = z[0][0]
	var d: Q = z[1][0]
	return S.cx(a.mul(c).sub(b.mul(d)), a.mul(d).add(b.mul(c)))


## The transformation z ↦ wz in words, for |w| = r and arg w = cπ.
static func describe(r: Array, c: Q) -> String:
	var rot := "a rotation of %s about 0" % turn(c)
	if S.ssame(r, S.sd(1)):
		return rot.capitalize().substr(0, 1) + rot.substr(1) + "."
	return "An enlargement with scale factor %s and centre 0, and %s." % [S.stext(r), rot]


static func vec(w: Array) -> String:
	return "(%s, %s)" % [w[0][0].text(), w[1][0].text()]


func u_describe_map(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var w: Array = s.w
	if s.mode == "translate":
		var t := "A translation by the vector %s." % vec(w)
		var ans := claim_ans(t)
		var wr: Array = [slip("add-rotates", claim("A rotation about 0 through the angle arg w.")),
			slip("neg-vector", claim("A translation by the vector %s." % vec([S.sneg(w[0]), S.sneg(w[1])])))]
		var fill: Array = [claim("A translation by the vector %s." % vec([w[1], w[0]])), claim("An enlargement with scale factor |w| and centre 0."),
			claim("A translation by the vector %s." % vec([w[0], S.sneg(w[1])]))]
		var steps: Array = ["Adding w = %s adds %s to the real part and %s to the imaginary part of every point." % [T(w), w[0][0].text(), w[1][0].text()],
			"Every point moves by the same vector, the side of the parallelogram on z and w: %s." % vec(w), "So the map is %s" % t.substr(0, 1).to_lower() + t.substr(1)]
		return _pack(["w = " + T(w)], "Describe geometrically the transformation of the Argand diagram that maps z to z + w.", ans, wr, fill, {"parallelogram": steps}, rng)
	var r: Array = s.r
	var c: Q = s.c
	var right := describe(r, c)
	var ans := claim_ans(right)
	var wr: Array = []
	if not c.eq(1):
		wr.append(slip("clockwise", claim(describe(r, c.neg()))))
	if not S.ssame(r, S.sd(1)):
		wr.append(slip("rotation-only", claim(describe(S.sd(1), c))))
	var fill: Array = [claim(describe(S.sscale(r, 2), c)), claim(describe(r, S.principal(c.mul(2)))) if not S.principal(c.mul(2)).is_zero() else claim("A reflection in the real axis."),
		claim(describe(r, S.principal(c.add(Q.new(1, 2))))), claim("A reflection in the real axis.")]
	var mod_t := "|w| = %s" % S.stext(r)
	var steps: Array = ["w = %s, so %s and arg w = %s." % [T(w), mod_t, Fmt.pi(c)], "In polar form w = %s, so multiplying by w multiplies every distance from 0 by %s and adds %s to every argument." % [PT(r, c, "cis"), S.stext(r), Fmt.pi(c)],
		"So the map is %s" % right.substr(0, 1).to_lower() + right.substr(1)]
	return _pack(["w = " + T(w)], "Describe geometrically the transformation of the Argand diagram that maps z to wz.", ans, wr, fill, {"rotation-enlargement": steps}, rng)


# ── Sums in Euler form ───────────────────────────────────────

## 2 cos(dπ/2) as a surd, for |d| = 1/3, 1/2, 2/3.
static func two_cos_half(d: Q) -> Array:
	match d.abs_q().key():
		"1/3":
			return S.sd(1, 3)
		"1/2":
			return S.sd(1, 2)
	return S.sd(1)


## e^(iα) or cis α as the sum writes it.
static func unit_text(c: Q, style: String) -> String:
	if c.is_zero():
		return "1"
	return PT(S.sd(1), c, style)


func u_euler_sum(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: Q = s.c
	var b: Q = s.c2
	var style: String = s.style
	var d := a.sub(b)
	var mean := a.add(b).div(2)
	var r := two_cos_half(d)
	var head := "z = "
	var ans := polar_ans(head, r, mean, style)
	var half := d.div(2)
	var wr: Array = [slip("two-mod", pwrong(ans, head, S.sd(2), mean, style)), slip("add-exp", pwrong(ans, head, S.sd(1), S.principal(a.add(b)), style))]
	if not half.abs_q().eq(mean.abs_q()):
		wr.append(slip("mean-diff", pwrong(ans, head, r, half, style)))
	var fill: Array = [pwrong(ans, head, r, mean.neg(), style), pwrong(ans, head, S.sscale(r, 2), mean, style), pwrong(ans, head, r, S.principal(a.add(b)), style),
		pwrong(ans, head, r, S.principal(mean.add(Q.new(1, 2))), style)]
	var zt := "%s + %s" % [unit_text(a, style), unit_text(b, style)] if not b.is_zero() else "1 + " + unit_text(a, style)
	var last := "So z = %s." % PT(r, mean, style)
	var ht := Fmt.pi(half.abs_q())
	var factor: Array = ["Take out e^(%s), half-way between the arguments: z = e^(%s)(e^(%s) + e^(%s))." % [S.pi_i(mean), S.pi_i(mean), S.pi_i(half), S.pi_i(half.neg())],
		"e^(iδ) + e^(−iδ) = 2 cos δ, and with δ = %s, 2 cos(%s) = %s." % [ht, ht, S.stext(r) if S.stext(r) != "1" else "1"],
		"So the modulus is %s and the argument %s. %s" % [S.stext(r), Fmt.pi(mean), last]]
	var cart: Array = ["z = (cos(%s) + cos(%s)) + i(sin(%s) + sin(%s))" % [Fmt.pi(a), Fmt.pi(b), Fmt.pi(a), Fmt.pi(b)],
		"Sum to product: cos A + cos B = 2 cos((A + B)/2) cos((A − B)/2), sin A + sin B = 2 sin((A + B)/2) cos((A − B)/2).",
		"So z = 2 cos(%s)(cos(%s) + i sin(%s)) = %s(cos(%s) + i sin(%s)), and 2 cos(%s) > 0." % [ht, Fmt.pi(mean), Fmt.pi(mean), S.stext(r), Fmt.pi(mean), Fmt.pi(mean), ht], last]
	var rh: Array = ["%s and %s both have modulus 1, so 0, the two points and z make a rhombus." % [unit_text(a, style), unit_text(b, style)],
		"The diagonal to z bisects the angle between them: arg z = (%s + %s)/2 = %s." % [Fmt.pi(a), Fmt.pi(b) if b.sign() >= 0 else "(" + Fmt.pi(b) + ")", Fmt.pi(mean)],
		"The diagonal makes %s with each side, so |z| = 2 cos(%s) = %s. %s" % [ht, ht, S.stext(r), last]]
	return _pack(["z = " + zt], polar_ask("z", style), ans, wr, fill, {"half-angle-factor": factor, "to-cartesian": cart, "rhombus": rh}, rng)


## k e^(inθ) as written: "3e^(2iθ)", "e^(−iθ)".
static func ek(k: int, n: int, letter: String, neg: bool) -> String:
	var p := ("−" if neg else "") + ("" if n == 1 else str(n)) + "i" + letter
	return ("" if k == 1 else str(k)) + "e^(%s)" % p


## k cos nθ or k i sin nθ: "6 cos 2θ", "−6i sin θ".
static func trig_term(k: int, fn: String, n: int, letter: String, with_i: bool) -> String:
	var sign := "−" if k < 0 else ""
	var m := absi(k)
	var lead := ("" if m == 1 else str(m)) + ("i" if with_i else "")
	return "%s%s%s%s %s%s" % [sign, lead, " " if lead != "" else "", fn, "" if n == 1 else str(n), letter] if lead == "" else "%s%s %s %s%s" % [sign, lead, fn, "" if n == 1 else str(n), letter]


func u_euler_trig(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var k: int = s.k
	var n: int = s.n
	var L: String = s.letter
	var mode: String = s.mode
	var expr: String
	var right: String
	match mode:
		"plus":
			expr = "%s + %s" % [ek(k, n, L, false), ek(k, n, L, true)]
			right = trig_term(2 * k, "cos", n, L, false)
		"minus":
			expr = "%s − %s" % [ek(k, n, L, false), ek(k, n, L, true)]
			right = trig_term(2 * k, "sin", n, L, true)
		_:
			expr = "%s − %s" % [ek(k, n, L, true), ek(k, n, L, false)]
			right = trig_term(-2 * k, "sin", n, L, true)
	var ans := claim_ans(right)
	var wr: Array = []
	match mode:
		"plus":
			wr.append(slip("lost-two", claim(trig_term(k, "cos", n, L, false))))
		"minus":
			wr.append(slip("no-i", claim(trig_term(2 * k, "sin", n, L, false))))
			wr.append(slip("lost-two", claim(trig_term(k, "sin", n, L, true))))
		_:
			wr.append(slip("no-i", claim(trig_term(-2 * k, "sin", n, L, false))))
			wr.append(slip("rev-sign", claim(trig_term(2 * k, "sin", n, L, true))))
	var fill: Array = [claim(trig_term(2 * k, "cos" if mode != "plus" else "sin", n, L, mode == "plus")), claim(trig_term(2 * k, "cos", 2 * n, L, false)),
		claim(trig_term(4 * k, "cos" if mode == "plus" else "sin", n, L, mode != "plus")), claim(trig_term(2 * k, "cos", n, L, true)), claim(trig_term(-2 * k, "cos", n, L, false))]
	var nl := ("" if n == 1 else str(n)) + L
	var ks := "" if k == 1 else str(k)
	var add: String = {"plus": "The sine terms cancel and the cosine terms add", "minus": "The cosine terms cancel and the sine terms add",
		"reverse": "The cosine terms cancel, and the sine terms add with a minus sign"}[mode]
	var steps: Array = ["e^(i%s) = cos %s + i sin %s and e^(−i%s) = cos %s − i sin %s, as cos is even and sin is odd." % [nl, nl, nl, nl, nl, nl],
		"%s: %s = %s." % [add, expr, right], "So %s = %s." % [expr, right]]
	var _unused := ks
	return _pack([expr], "Write this expression as a single term in sin %s or cos %s." % [nl, nl], ans, wr, fill, {"to-cartesian": steps}, rng)


# ── Exact values from two forms ──────────────────────────────

## (x√6 + y√2)/4 and its kin written as the IB writes them: "(√6 + √2)/4", "(√2 − √6)/4",
## "−(√6 + √2)/4". x and y are ±1; den the denominator; ra and rb the two roots.
static func pair_text(x: int, y: int, ra: String, rb: String, den: int) -> String:
	var tail := "" if den == 1 else "/%d" % den
	if x > 0 and y > 0:
		return "(%s + %s)%s" % [ra, rb, tail]
	if x < 0 and y < 0:
		return "−(%s + %s)%s" % [ra, rb, tail]
	if x > 0:
		return "(%s − %s)%s" % [ra, rb, tail]
	return "(%s − %s)%s" % [rb, ra, tail]


## The exact real and imaginary parts of z₁z₂ (or z₁/z₂) as [[x, y], [x, y]]: each part is
## (x + y√3), halved for a quotient.
static func xt_parts(s: Dictionary, mode: String) -> Array:
	var z1 := S.cart(s.r, s.c)
	var z2 := S.cart(s.r2, s.c2)
	# z₁ = p + q i with p, q in {±1, ±√3}; z₂ = u + v i with u, v = ±1.
	var w := z2 if mode == "product" else [z2[0], S.sneg(z2[1])]
	var re := [Q.new(0), Q.new(0)]
	var im := [Q.new(0), Q.new(0)]
	for term in [[z1[0], w[0], 1, re], [z1[1], w[1], -1, re], [z1[0], w[1], 1, im], [z1[1], w[0], 1, im]]:
		var prod := S.smul(term[0], term[1])
		var slot := 0 if int(prod[1]) == 1 else 1
		term[3][slot] = term[3][slot].add(prod[0].mul(term[2]))
	return [re, im]


## cos φ or sin φ as (x√6 + y√2)/4 from a part (x' + y'√3) over 2√2: (y'√6 + x'√2)/4.
static func xt_value(part: Array, mode: String) -> String:
	var x: Q = part[0]
	var y: Q = part[1]
	if mode == "quotient":
		x = x.div(2)
		y = y.div(2)
	return pair_text(int(y.sign()), int(x.sign()), "√6", "√2", 4)


func u_exact_trig(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var mode: String = s.mode
	var target: String = s.target
	var phi: Q = s.phi
	var z1 := S.cart(s.r, s.c)
	var z2 := S.cart(s.r2, s.c2)
	var parts := xt_parts(s, mode)
	var idx := 0 if target == "cos" else 1
	var val := xt_value(parts[idx], mode)
	var fn := "%s(%s)" % [target, Fmt.pi(phi)]
	var ans := claim_ans("%s = %s" % [fn, val])
	var p: Array = parts[idx]
	var x: Q = p[0]
	var y: Q = p[1]
	var wr: Array = [slip("re-for-im", claim("%s = %s" % [fn, xt_value(parts[1 - idx], mode)]))]
	# Dividing by |z₁| = 2 alone: the part over 2 (product) or over 2 × 2 (quotient).
	var den := 2 if mode == "product" else 4
	wr.append(slip("part-mod", claim("%s = %s" % [fn, pair_text(int(x.sign()), int(y.sign()), "1", "√3", den).replace("(1 − √3)", "(1 − √3)")])))
	if mode == "product":
		var other_parts := xt_parts(s, "quotient")
		wr.append(slip("sub-args", claim("%s = %s" % [fn, xt_value(other_parts[idx], "quotient")])))
	var neg := "−" + val if not val.begins_with("−") else val.substr(1)
	var fill: Array = [claim("%s = %s" % [fn, neg]), claim("%s = %s" % [fn, val.replace("/4", "/2")]), claim("%s = %s" % [fn, val.replace("√6", "√3").replace("√2", "1")]),
		claim("%s = %s" % [fn, "(√6 + √2)/2"])]
	var name := "z₁z₂" if mode == "product" else "z₁/z₂"
	var w := S.cx(S.sadd(S.sd(parts[0][0].div(2 if mode == "quotient" else 1)), S.sd(0)), S.sd(0))
	var _w := w
	var re_t := part_text(parts[0], mode)
	var im_t := part_text(parts[1], mode)
	var modt := "2√2" if mode == "product" else "√2"
	var arg_t := "%s %s %s" % [Fmt.pi(s.c), "+" if mode == "product" else "−", "(" + Fmt.pi(s.c2) + ")" if s.c2.sign() < 0 else Fmt.pi(s.c2)]
	var lines: Array = ["z₁ = " + T(z1), "z₂ = " + T(z2)]
	var asked := "By writing %s in the form a + bi and in modulus-argument form, find the exact value of %s." % [name, fn]
	var part_name := "real" if target == "cos" else "imaginary"
	var compare: Array = ["%s = %s + (%s)i, %s" % [name, re_t, im_t, "multiplying out" if mode == "product" else "multiplying the top and the bottom by z₂*, which is %s" % T([z2[0], S.sneg(z2[1])])],
		"|z₁| = 2 and |z₂| = √2, arg z₁ = %s and arg z₂ = %s, so %s = %s cis(%s)." % [Fmt.pi(s.c), Fmt.pi(s.c2), name, modt, Fmt.pi(phi)],
		"Equate the %s parts: %s %s = %s, so %s = (%s)/(%s) = %s." % [part_name, modt, fn, re_t if target == "cos" else im_t, fn, re_t if target == "cos" else im_t, modt, val],
		"So %s = %s." % [fn, val]]
	var cs1 := S.cos_sin(s.c)
	var cs2 := S.cos_sin(s.c2)
	var rule: String
	if target == "cos":
		rule = "cos(A %s B) = cos A cos B %s sin A sin B" % ["+" if mode == "product" else "−", "−" if mode == "product" else "+"]
	else:
		rule = "sin(A %s B) = sin A cos B %s cos A sin B" % ["+" if mode == "product" else "−", "+" if mode == "product" else "−"]
	var compound: Array = ["%s = %s, with A = %s and B = %s." % [Fmt.pi(phi), arg_t, Fmt.pi(s.c), Fmt.pi(s.c2)] if S.principal(s.c.add(s.c2) if mode == "product" else s.c.sub(s.c2)).eq(phi) else "%s = %s.",
		"%s, with cos A = %s, sin A = %s, cos B = %s, sin B = %s." % [rule, S.stext(cs1[0]), S.stext(cs1[1]), S.stext(cs2[0]), S.stext(cs2[1])],
		"Multiplying out and writing over 4 gives %s." % val, "So %s = %s." % [fn, val]]
	return _pack(lines, asked, ans, wr, fill, {"compare-forms": compare, "compound-angle": compound}, rng)


## A part x + y√3 (halved for a quotient) as written: "1 + √3", "(√3 − 1)/2".
static func part_text(p: Array, mode: String) -> String:
	var x: Q = p[0]
	var y: Q = p[1]
	if mode == "quotient":
		x = x.div(2)
		y = y.div(2)
	var den := x.d
	var xs := x.mul(den)
	var ys := y.mul(den)
	var body: String
	if ys.is_zero():
		body = xs.text()
	elif xs.is_zero():
		body = S.stext(S.sd(ys, 3))
	else:
		body = "%s %s %s" % [xs.text(), "−" if ys.sign() < 0 else "+", S.stext(S.sd(ys.abs_q(), 3))]
	return body if den == 1 else "(%s)/%d" % [body, den]
