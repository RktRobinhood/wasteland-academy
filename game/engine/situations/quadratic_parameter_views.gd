class_name QuadraticParameterViews
extends RefCounted
## The views on the `quadratic-parameter` situation: one builder per unknown of
## fn-discriminant (FAL-414). Builders return what QuadraticViews' builders return (see
## quadratic_views.gd): asked, lines, graph, given, answer, wrongs, generic, methods.
##
## Representations: "equation" shows the quadratic in k (or the curve and the line),
## "words" says the condition in a sentence (a line meeting a curve), "graph" sketches
## the parabola, or the curve and the line, at the critical k.

const NAT := ["two distinct real roots", "one repeated root", "no real roots", "two negative roots"]
const MEET := ["two points", "one point (a tangent)", "no points"]
const SIGNS := ["a > 0 and Δ > 0", "a > 0 and Δ = 0", "a > 0 and Δ < 0", "a < 0 and Δ > 0", "a < 0 and Δ = 0", "a < 0 and Δ < 0"]
const SKETCH := [
	"opens upwards and crosses the x-axis twice", "opens upwards and touches the x-axis once",
	"opens upwards and never meets the x-axis", "opens downwards and crosses the x-axis twice",
	"opens downwards and touches the x-axis once", "opens downwards and never meets the x-axis"]
const DIRECT := ["c", "b", "both"]
const LINES := ["grad", "icpt"]

const NEED := {
	"nature-from-equation": {"base": {"mode": "any4", "even": true}},
	"delta-sign-from-graph": {"base": {"mode": "any4", "even": true, "graph": true}},
	"graph-from-delta": {"base": {"mode": "any4", "even": true}},
	"roots-from-k": {"kv": true},
	"delta-in-k": {},
	"k-for-equal-roots": {},
	"k-interval": {"cond": true},
	"always-positive": {"families": DIRECT, "a_pos": true},
	"same-sign-roots": {"families": ["c"], "a_pos": true},
	"tangent-contact-point": {"families": ["icpt"]},
}


func has(unknown: String) -> bool:
	return NEED.has(unknown)


## The papers a cell can be asked on (FAL-419). Equal roots (but not on a sketch, which
## is drawn at a whole-number k), an interval of k and "always positive" have Paper 2
## versions: Δ is a quadratic in k whose zeros are irrational, so k needs a calculator
## and is given to 3 s.f. The rest are exact, Paper 1.
func papers(unknown: String, rep: String, _angle: String) -> Array:
	match unknown:
		"k-for-equal-roots":
			return [1] if rep == "graph" else [1, 2]
		"k-interval", "always-positive":
			return [1, 2]
	return [1]


func need(unknown: String, rep: String) -> Dictionary:
	var n: Dictionary = NEED[unknown].duplicate(true)
	if n.has("base"):
		return n
	if not n.has("families"):
		match rep:
			"words":
				n.families = LINES
			"graph":
				n.families = ["c", "icpt"]
			_:
				n.families = DIRECT + LINES if unknown == "k-for-equal-roots" else DIRECT
	return n


## Two needs as one, for a shared family (QuestionEngine.families). A need on a plain
## quadratic (base) shares no keys with a need on k, so the default would merge them and
## the k views would get a quadratic without k. They stay apart; base needs merge their
## bases.
func merge_need(a: Dictionary, b: Dictionary) -> Variant:
	if a.has("base") != b.has("base"):
		return null
	if not a.has("base"):
		return QuestionEngine.merge_need(a, b)
	var base = QuestionEngine.merge_need(a.base, b.base)
	return null if base == null else {"base": base}


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "wrongs", "generic"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "generic"] else null
	# Q7's rounding trap, where the answer needs rounding (see game/README.md).
	out.trap = Answer.rounding_trap(out.answer)
	return out


# ── Writing the quadratic in k ───────────────────────────────

static func N(v: Variant) -> String:
	return Fmt.num(v)


## Paper 2: the critical values of k are irrational, written to 3 s.f.
static func p2(s: Dictionary) -> bool:
	return s.get("paper", 1) == 2


## A value of k as this paper writes it: exact, or to 3 s.f. on Paper 2.
static func KN(s: Dictionary, v: Variant) -> String:
	return Fmt.sf(v) if p2(s) else N(v)


## What Paper 2 adds to the question: the answers to 3 s.f.
static func to_sf(s: Dictionary) -> String:
	return " Give your answers correct to 3 significant figures." if p2(s) else ""


static func wrong(values: Dictionary, ref: String = "") -> Dictionary:
	return {"values": values, "ref": ref}


## c0 + c1·k as written: "9", "k", "−2k", "2k + 3", "3 − k".
static func kexpr(c0: Q, c1: Q) -> String:
	if c1.is_zero():
		return N(c0)
	var kt := Fmt.lead(c1.abs_q()) + "k"
	if c0.is_zero():
		return ("−" if c1.sign() < 0 else "") + kt
	if c1.sign() > 0:
		return kt + Fmt.plus(c0)
	return N(c0) + " − " + kt


## kexpr in brackets when it is more than one term or negative, for substituting.
static func kp(c0: Q, c1: Q) -> String:
	var t := kexpr(c0, c1)
	return "(%s)" % t if t.contains(" ") or t.begins_with("−") else t


## The quadratic in x with k in it: "x² + kx + 9", "2x² − 8x + k", "x² + (3 − k)x + 4".
static func kx_text(s: Dictionary) -> String:
	var out := Fmt.term(s.a0, 2, true)
	if s.b1.is_zero():
		if not s.b0.is_zero():
			out += Fmt.term(s.b0, 1, false)
	elif s.b0.is_zero():
		out += (" − " if s.b1.sign() < 0 else " + ") + Fmt.lead(s.b1.abs_q()) + "kx"
	else:
		out += " + (%s)x" % kexpr(s.b0, s.b1)
	if s.c1.is_zero():
		if not s.c0.is_zero():
			out += Fmt.plus(s.c0)
	elif s.c0.is_zero():
		out += (" − " if s.c1.sign() < 0 else " + ") + Fmt.lead(s.c1.abs_q()) + "k"
	else:
		out += " + (%s)" % kexpr(s.c0, s.c1)
	return out


static func curve_rhs(s: Dictionary) -> String:
	return Fmt.poly([1, s.p, s.r])


static func line_rhs(s: Dictionary) -> String:
	if s.family == "grad":
		return "kx" + (Fmt.plus(s.n) if not s.n.is_zero() else "")
	return Fmt.poly([s.m, 0]) + " + k"


static func dexpr(s: Dictionary) -> String:
	return Fmt.poly([s.dA, s.dB, s.dC], "k")


static func is_line(s: Dictionary) -> bool:
	return s.family in LINES


## What the student sees for the quadratic in k.
static func shown(s: Dictionary) -> Array:
	if is_line(s):
		return ["Curve: y = " + curve_rhs(s), "Line: y = " + line_rhs(s)]
	return ["f(x) = " + kx_text(s)]


## The words representation: a line and a curve in a sentence.
static func said_lines(s: Dictionary) -> Array:
	if is_line(s):
		return ["The line y = %s meets the curve y = %s." % [line_rhs(s), curve_rhs(s)]]
	return shown(s)


static func given_of(s: Dictionary) -> Dictionary:
	var g := {"family": s.family}
	for key in ["a0", "b0", "b1", "c0", "c1", "p", "r", "m", "n"]:
		if s.get(key) != null:
			g[key] = s[key].key()
	return g


## The equating step for a line and a curve (none for a quadratic given directly).
static func equate(s: Dictionary) -> Array:
	if not is_line(s):
		return []
	return ["Equate and rearrange: %s = %s gives %s = 0" % [curve_rhs(s), line_rhs(s), kx_text(s)]]


## Reading a, b, c and writing Δ in k, in one step.
static func delta_step(s: Dictionary) -> String:
	return "a = %s, b = %s, c = %s, so Δ = b² − 4ac = %s² − 4 × %s × %s = %s" % [
		N(s.a0), kexpr(s.b0, s.b1), kexpr(s.c0, s.c1), kp(s.b0, s.b1), Fmt.paren(s.a0), kp(s.c0, s.c1), dexpr(s)]


## Solving Δ = 0, in one step.
static func zero_step(s: Dictionary) -> String:
	var c: Array = s.crit
	if p2(s):
		if s.dB.is_zero():
			return "%s = 0 gives k² = %s, so k = ±√%s; with a GDC, k = %s or k = %s" % [dexpr(s), N(s.dC.neg()), N(s.dC.neg()), Fmt.sf(c[0]), Fmt.sf(c[1])]
		return "%s = 0 has no whole-number roots; with a GDC (or the formula), k = %s or k = %s" % [dexpr(s), Fmt.sf(c[0]), Fmt.sf(c[1])]
	if s.dA.is_zero():
		return "%s = 0 gives k = %s" % [dexpr(s), N(c[0])]
	if s.dB.is_zero():
		return "%s = 0 gives k² = %s, so k = ±%s" % [dexpr(s), N(s.dC.neg()), N(c[1])]
	return "%s = (k%s)(k%s) = 0, so k = %s or k = %s" % [dexpr(s), Fmt.plus(c[0].neg()), Fmt.plus(c[1].neg()), N(c[0]), N(c[1])]


static func crit_answer(s: Dictionary) -> Dictionary:
	if s.crit.size() == 1:
		return Answer.make("number", {"v": s.crit[0]}, {}, "k = ")
	var ans := Answer.make("kvals", {"r1": s.crit[0], "r2": s.crit[1]}, {"var": "k"})
	if p2(s):
		ans.show = "sf"
	return ans


## The graph at the critical k: the parabola touching the x-axis, or the curve and the
## tangent line.
static func crit_graph(s: Dictionary, caption: String) -> Dictionary:
	var k: Q = s.crit[0]
	var abc := QuadraticParameterSituation.at(s, k)
	var pt := QuadraticParameterSituation.contact(s, k)
	var par := {}
	if is_line(s):
		var h: Q = s.p.div(-2)
		par = {"a": Q.new(1), "h": h, "k": s.r.sub(s.p.sq().div(4)), "p": null, "q": null}
	else:
		par = {"a": abc[0], "h": pt[0], "k": Q.new(0), "p": null, "q": null}
	var y_int: Q = s.r if is_line(s) else abc[2]
	var g := QuadraticViews.graph(par, [pt, [0, y_int]], false, caption)
	g.points = []
	if is_line(s):
		var m: Q = s.m if s.family == "icpt" else k
		var n: Q = k if s.family == "icpt" else s.n
		g.line = {"m": m.to_float(), "n": n.to_float()}
	return g


## a(x + B/(2a))² + C − B²/(4a) with k in it, as two strings: the completed square and
## the vertex's y-coordinate (which is 0 for equal roots, positive for "always positive").
static func cs_parts(s: Dictionary) -> Array:
	var a: Q = s.a0
	var den := a.mul(2)
	var B := kp(s.b0, s.b1)
	var C := kp(s.c0, s.c1)
	var lead := Fmt.lead(a)
	if s.b1.is_zero():
		var h: Q = s.b0.neg().div(den)
		var shift := a.mul(h.sq()).neg()
		var ky := kexpr(s.c0, s.c1) + Fmt.plus(shift)
		return [lead + Fmt.factor(h) + "² + " + ("(" + ky + ")" if ky.contains(" ") else ky), ky]
	var sq := "(x %s %s/%s)²" % ["+" if den.sign() > 0 else "−", B, N(den.abs_q())]
	var ky := "%s %s %s²/%s" % [C, "−" if a.sign() > 0 else "+", B, N(a.mul(4).abs_q())]
	return [lead + sq + " + " + ky if not ky.begins_with("−") else lead + sq + " " + ky, ky]


# ── Plain quadratics: the nature of the roots ────────────────

static func nature_of(d: Q) -> String:
	return NAT[0] if d.sign() > 0 else (NAT[1] if d.is_zero() else NAT[2])


static func meet_of(d: Q) -> String:
	return MEET[0] if d.sign() > 0 else (MEET[1] if d.is_zero() else MEET[2])


func u_nature_from_equation(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Q = s.a
	var b: Q = s.b
	var c: Q = s.c
	var d: Q = s.disc
	var ans := Answer.make("delta_nature", {"d": d, "nature": nature_of(d)}, {"options": NAT})
	var res := {"d": d, "nature": nature_of(d)}
	var calc := "Δ = b² − 4ac = %s² − 4 × %s × %s = %s" % [Fmt.paren(b), Fmt.paren(a), Fmt.paren(c), N(d)]
	var said: String = {NAT[0]: "Δ > 0, so there are two distinct real roots.", NAT[1]: "Δ = 0, so there is one repeated root.",
		NAT[2]: "Δ < 0, so there are no real roots."}[nature_of(d)]
	var up := a.sign() > 0
	var where := "on" if s.k.is_zero() else ("below" if s.k.sign() < 0 else "above")
	var seen := "touches the x-axis at its vertex" if s.k.is_zero() else (
		"crosses the x-axis twice" if (s.k.sign() < 0) == up else "never meets the x-axis")
	var cs := QuadraticViews.cs_steps(a, b, c)
	var wrongs: Array = []
	var d0 := b.sq().sub(a.mul(c.abs_q()).mul(4))
	wrongs.append(wrong({"d": d0, "nature": nature_of(d0)}, "SL2.7.discriminant#0"))
	var d2 := b.sq().add(a.mul(c).mul(4))
	wrongs.append(wrong({"d": d2, "nature": nature_of(d2)}, "SL2.7.discriminant#2"))
	if d.sign() < 0:
		wrongs.append(wrong({"d": d, "nature": NAT[3]}, "SL2.7.discriminant#1"))
	return {
		"asked": "Find the discriminant of f(x), and say how many real roots the equation f(x) = 0 has.",
		"lines": [QuadraticViews.gen_line(s)], "given": {"a": a.key(), "b": b.key(), "c": c.key()}, "answer": ans,
		"wrongs": wrongs,
		"generic": [{"d": d, "nature": NAT[0] if d.sign() <= 0 else NAT[2]}, {"d": d, "nature": NAT[1]}, {"d": d.neg(), "nature": nature_of(d.neg())}],
		"methods": {
			"compute-delta": {"result": res, "steps": [
				"a = %s, b = %s, c = %s" % [N(a), N(b), N(c)], calc, said, "So " + Answer.text(ans, res) + "."]},
			"vertex-position": {"result": res, "steps": [
				"Complete the square: f(x) = " + Fmt.vertex(a, cs.h, cs.k),
				"The vertex %s is %s the x-axis and the parabola opens %s." % [Fmt.point(cs.h, cs.k), where, "upwards" if up else "downwards"],
				"So the graph %s: %s" % [seen, said],
				"Check: " + calc + ". So " + Answer.text(ans, res) + "."]},
			"gdc-graph": {"result": res, "steps": [
				"Graph y = %s on the GDC: it %s." % [Fmt.general(a, b, c), seen],
				"A graph is a check, not a proof, so work out Δ: " + calc,
				"So " + Answer.text(ans, res) + "."]},
		},
	}


func u_delta_sign_from_graph(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var up: bool = s.a.sign() > 0
	var i := (0 if up else 3) + (0 if s.disc.sign() > 0 else (1 if s.disc.is_zero() else 2))
	var ans := Answer.make("choice", {"v": SIGNS[i]}, {"options": SIGNS})
	var seen: String = ["crosses the x-axis twice, so f(x) = 0 has two real roots and Δ > 0",
		"touches the x-axis once, so f(x) = 0 has a repeated root and Δ = 0",
		"never meets the x-axis, so f(x) = 0 has no real roots and Δ < 0"][i % 3]
	var others: Array = rng.shuffled(SIGNS.filter(func(o): return o != SIGNS[i]))
	return {
		"asked": "The graph of y = ax² + bx + c is shown. What are the signs of a and of the discriminant Δ?",
		"lines": ["The graph of y = ax² + bx + c is shown."],
		"graph": QuadraticViews.graph(s, []),
		"given": {"a": s.a.key(), "b": s.b.key(), "c": s.c.key()}, "answer": ans,
		"generic": others.map(func(o): return {"v": o}),
		"methods": {"vertex-position": {"result": {"v": SIGNS[i]}, "steps": [
			"The parabola opens %s, so a %s 0." % ["upwards" if up else "downwards", ">" if up else "<"],
			"Its vertex is %s the x-axis: the graph %s." % ["on" if s.k.is_zero() else ("below" if s.k.sign() < 0 else "above"), seen],
			"So " + SIGNS[i] + "."]}},
	}


func u_graph_from_delta(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var up: bool = s.a.sign() > 0
	var j := 0 if s.disc.sign() > 0 else (1 if s.disc.is_zero() else 2)
	var i := (0 if up else 3) + j
	var ans := Answer.make("choice", {"v": SKETCH[i]}, {"options": SKETCH})
	var others: Array = rng.shuffled(SKETCH.filter(func(o): return o != SKETCH[i]))
	return {
		"asked": "Which sketch fits the graph of y = ax² + bx + c?",
		"lines": ["For the quadratic y = ax² + bx + c, %s." % SIGNS[i]],
		"given": {"a": s.a.key(), "b": s.b.key(), "c": s.c.key(), "signs": SIGNS[i]}, "answer": ans,
		"generic": others.map(func(o): return {"v": o}),
		"methods": {"vertex-position": {"result": {"v": SKETCH[i]}, "steps": [
			"a %s 0, so the parabola opens %s." % [">" if up else "<", "upwards" if up else "downwards"],
			["Δ > 0, so there are two real roots: it crosses the x-axis twice.",
				"Δ = 0, so there is one repeated root: the vertex sits on the x-axis.",
				"Δ < 0, so there are no real roots: it never meets the x-axis."][j],
			"So " + Answer.text(ans) + "."]}},
	}


# ── A parameter k ────────────────────────────────────────────

func u_roots_from_k(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var kv: Q = s.kv
	var abc := QuadraticParameterSituation.at(s, kv)
	var d := QuadraticParameterSituation.delta_at(s, kv)
	var line := is_line(s)
	var opts: Array = MEET if line else NAT.slice(0, 3)
	var say: Callable = meet_of if line else nature_of
	var ans := Answer.make("delta_nature", {"d": d, "nature": say.call(d)}, {"options": opts})
	var res := {"d": d, "nature": say.call(d)}
	var eq := Fmt.general(abc[0], abc[1], abc[2])
	var calc := "Δ = %s² − 4 × %s × %s = %s" % [Fmt.paren(abc[1]), Fmt.paren(abc[0]), Fmt.paren(abc[2]), N(d)]
	var put := ("With k = %s, equating gives %s = 0" if line else "With k = %s, f(x) = %s") % [N(kv), eq]
	var count: String = ["it crosses the x-axis twice", "it touches the x-axis", "it does not meet the x-axis"][0 if d.sign() > 0 else (1 if d.is_zero() else 2)]
	var d2: Q = abc[1].sq().add(abc[0].mul(abc[2]).mul(4))
	var dm := QuadraticParameterSituation.delta_at(s, kv.neg())
	var generic: Array = [{"d": d2, "nature": say.call(d2)}, {"d": dm, "nature": say.call(dm)}]
	for o in opts:
		if o != say.call(d):
			generic.append({"d": d, "nature": o})
	return {
		"asked": ("When k = %s, find the discriminant of the equation for where they meet, and say how many points the line and the curve meet at." if line
			else "When k = %s, find the discriminant of f(x), and say how many real roots f(x) = 0 has.") % N(kv),
		"lines": said_lines(s), "given": given_of(s).merged({"kv": kv.key()}), "answer": ans, "generic": generic,
		"methods": {
			"compute-delta": {"result": res, "steps": [put, calc, "So " + Answer.text(ans, res) + "."]},
			"gdc-slider": {"result": res, "steps": [
				"Graph y = %s with a slider for k, and set k = %s: %s." % [kx_text(s), N(kv), count],
				"A graph is a check, so confirm: " + put + ", and " + calc,
				"So " + Answer.text(ans, res) + "."]},
		},
	}


func u_delta_in_k(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var fixed := {"var": "k"}
	if s.dA.is_zero():
		fixed.A = Q.new(0)
	var vals := {"B": s.dB, "C": s.dC}
	if not s.dA.is_zero():
		vals.A = s.dA
	var ans := Answer.make("quad_in", vals, fixed, "Δ = ")
	var wrongs: Array = []
	if s.c1.is_zero() and s.c0.sign() < 0:
		var w0 := vals.duplicate()
		w0.C = s.b0.sq().sub(s.a0.mul(s.c0.abs_q()).mul(4))
		wrongs.append(wrong(w0, "SL2.7.discriminant#0"))
	var w2 := vals.duplicate()
	w2.B = s.b0.mul(s.b1).mul(2).add(s.a0.mul(s.c1).mul(4))
	w2.C = s.b0.sq().add(s.a0.mul(s.c0).mul(4))
	wrongs.append(wrong(w2, "SL2.7.discriminant#2"))
	var g1 := vals.duplicate()
	g1.B = s.dB.neg()
	var g2 := vals.duplicate()
	g2.C = s.dC.neg()
	var g3 := vals.duplicate()
	g3.C = s.dC.add(s.a0.mul(s.c0).mul(2))
	var st: Array = equate(s)
	st.append(delta_step(s))
	st.append("So " + Answer.text(ans) + ".")
	return {
		"asked": "Find the discriminant of the equation %s, in terms of k." % ("for where they meet" if is_line(s) else "f(x) = 0"),
		"lines": said_lines(s), "given": given_of(s), "answer": ans, "wrongs": wrongs, "generic": [g1, g2, g3],
		"methods": {"discriminant-condition": {"result": vals, "steps": st}},
	}


func u_k_for_equal_roots(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := crit_answer(s)
	var line := is_line(s)
	var one: bool = s.crit.size() == 1
	var out := {"answer": ans, "given": given_of(s), "lines": shown(s)}
	var cond := "The line is a tangent to the curve." if line else "The equation f(x) = 0 has equal roots."
	out.asked = cond + (" Find the value of k." if one else " Find the possible values of k.") + to_sf(s)
	if rep == "words" and line:
		out.lines = ["The line y = %s is a tangent to the curve y = %s." % [line_rhs(s), curve_rhs(s)]]
		out.asked = ("Find the value of k." if one else "Find the possible values of k.") + to_sf(s)
	if rep == "graph":
		out.graph = crit_graph(s, "")
		out.lines = shown(s) + ["The sketch shows the %s." % ("line touching the curve" if line else "graph of y = f(x) touching the x-axis")]
	var res: Dictionary = ans.values
	var final := "So " + Answer.text(ans) + "."
	# The methods.
	var dc: Array = equate(s)
	dc.append(delta_step(s))
	dc.append("Equal roots (a tangent) need Δ = 0: " + zero_step(s))
	dc.append(final)
	var cs: Array = equate(s)
	var parts := cs_parts(s)
	cs.append("Complete the square: %s = %s" % [kx_text(s), parts[0]])
	cs.append("Equal roots when the vertex is on the x-axis: %s = 0. Times −4a, that is %s = 0" % [parts[1], dexpr(s)])
	cs.append(zero_step(s))
	cs.append(final)
	out.methods = {"discriminant-condition": {"result": res, "steps": dc}, "complete-square-condition": {"result": res, "steps": cs},
		"derivative-match": {"result": res, "steps": deriv_steps(s, final)}}
	# Wrong options.
	var wrongs: Array = []
	if s.family == "icpt" and int(s.p.n) % 2 == 0:
		wrongs.append(wrong({"v": s.r.sub(s.p.sq().div(4))}, "SL2.7.discriminant-parameter#0"))
	out.wrongs = wrongs
	if one:
		var k: Q = s.crit[0]
		out.generic = [{"v": k.neg()}, {"v": k.mul(2)}, {"v": k.add(s.dC.sign())}, {"v": QuadraticParameterSituation.contact_x(s, k)}]
	else:
		var k1: Q = s.crit[0]
		var k2: Q = s.crit[1]
		out.generic = [{"r1": k1.neg(), "r2": k2.neg()}, {"r1": k1.div(2), "r2": k2.div(2)}, {"r1": k1.mul(2), "r2": k2.mul(2)}, {"r1": k1.sub(1), "r2": k2.add(1)}]
	return out


## Matching gradients: at the touching point the curve's gradient is the line's (or 0
## where a parabola touches the x-axis), and the point is on both.
static func deriv_steps(s: Dictionary, final: String) -> Array:
	var st: Array = []
	match s.family:
		"icpt":
			var x0: Q = s.m.sub(s.p).div(2)
			var y0 := x0.sq().add(s.p.mul(x0)).add(s.r)
			st.append("The curve's gradient is dy/dx = %s. It equals the line's gradient %s where %s = %s, so x = %s" % [Fmt.poly([2, s.p]), N(s.m), Fmt.poly([2, s.p]), N(s.m), N(x0)])
			st.append("On the curve, y = %s" % N(y0))
			st.append("The line passes through %s: %s = %s × %s + k, so k = %s" % [Fmt.point(x0, y0), N(y0), N(s.m), Fmt.paren(x0), N(y0.sub(s.m.mul(x0)))])
		"grad":
			st.append("At the touching point x₀ the gradients match: k = 2x₀%s" % Fmt.plus(s.p) if not s.p.is_zero() else "At the touching point x₀ the gradients match: k = 2x₀")
			st.append("The point is on both: %s = kx₀%s; with k = 2x₀%s this gives x₀² = %s" % [Fmt.poly([1, s.p, s.r]).replace("x", "x₀"), Fmt.plus(s.n) if not s.n.is_zero() else "", Fmt.plus(s.p) if not s.p.is_zero() else "", N(s.r.sub(s.n))])
			var x1: Q = s.crit[0].sub(s.p).div(2)
			var x2: Q = s.crit[1].sub(s.p).div(2)
			var roots := "x₀ = %s or x₀ = %s" % [N(x1), N(x2)]
			if p2(s):
				roots = "x₀ = ±√%s (with a GDC, %s or %s)" % [N(s.r.sub(s.n)), Fmt.sf(x1), Fmt.sf(x2)]
			st.append("So %s, and k = 2x₀%s = %s or %s" % [roots, Fmt.plus(s.p) if not s.p.is_zero() else "", KN(s, s.crit[0]), KN(s, s.crit[1])])
		_:
			st.append("A parabola touches the x-axis at a turning point, where f′(x) = 0 and f(x) = 0.")
			st.append("f′(x) = %s" % _fprime(s))
			var parts: PackedStringArray = []
			for k in s.crit:
				var x0 := QuadraticParameterSituation.contact_x(s, k)
				parts.append("k = %s touches at x = %s" % [KN(s, k), KN(s, x0)])
			if s.family == "c":
				var x0: Q = s.b0.neg().div(s.a0.mul(2))
				st.append("f′(x) = 0 at x = %s; f(%s) = %s%s + k = 0" % [N(x0), N(x0), N(s.a0.mul(x0.sq())), Fmt.plus(s.b0.mul(x0))])
			else:
				st.append("Solving f′(x) = 0 and f(x) = 0 together%s: " % (" (with a GDC, to 3 s.f.)" if p2(s) else "") + ", ".join(parts))
	st.append(final)
	return st


static func _fprime(s: Dictionary) -> String:
	var lin := Fmt.term(s.a0.mul(2), 1, true)
	if s.b1.is_zero():
		return lin + (Fmt.plus(s.b0) if not s.b0.is_zero() else "")
	var kt := kexpr(s.b0, s.b1)
	return lin + (" − " + kt.substr(1) if kt.begins_with("−") else " + " + kt)


# ── Intervals of k ───────────────────────────────────────────

const COND := {"two": "Δ > 0", "none": "Δ < 0", "real": "Δ ≥ 0"}


## The values of k where Δ(k) meets cond: a bound when Δ is linear in k, else an
## interval (Δ is a U-shaped quadratic in k here).
static func cond_answer(s: Dictionary, cond: String) -> Dictionary:
	if s.dA.is_zero():
		var up: bool = s.dB.sign() > 0
		var rel := ""
		match cond:
			"two":
				rel = ">" if up else "<"
			"none":
				rel = "<" if up else ">"
			"real":
				rel = "≥" if up else "≤"
		return Answer.make("bound", {"rel": rel, "v": s.crit[0]}, {"var": "k"})
	var shape := "between" if cond == "none" else "outside"
	var ends := "included" if cond == "real" else "left out"
	var ans := Answer.make("interval", {"shape": shape, "lo": s.crit[0], "hi": s.crit[1], "ends": ends}, {"var": "k"})
	if p2(s):
		ans.show = "sf"
	return ans


static func flip_rel(rel: String) -> String:
	return {"<": ">", ">": "<", "≤": "≥", "≥": "≤"}[rel]


static func loose(rel: String) -> String:
	return {"<": "≤", ">": "≥", "≤": "<", "≥": ">"}[rel]


## The methods that solve Δ(k) against 0 once Δ is written down.
static func interval_methods(s: Dictionary, cond: String, ans: Dictionary, lead: Array) -> Dictionary:
	var final := "So " + Answer.text(ans) + "."
	var sym: String = COND[cond]
	var res: Dictionary = ans.values
	var base: Array = lead.duplicate()
	base.append(delta_step(s))
	var c: Array = s.crit
	var lin: bool = s.dA.is_zero()
	var region := ""
	if lin:
		region = "%s is a straight line in k with gradient %s, so it is positive for k %s %s" % [dexpr(s), N(s.dB), ">" if s.dB.sign() > 0 else "<", N(c[0])]
	else:
		region = "Δ is a U-shaped quadratic in k: positive outside %s and %s, negative between them" % [KN(s, c[0]), KN(s, c[1])]
	var dcm := base.duplicate()
	dcm.append("%s: %s" % [sym, zero_step(s)])
	dcm.append(region + ".")
	dcm.append(final)
	var sk := base.duplicate()
	if lin:
		sk.append("Sketch Δ against k: a straight line crossing the k-axis at k = %s, with gradient %s." % [N(c[0]), N(s.dB)])
	else:
		sk.append("Sketch Δ against k: a U-shaped parabola crossing the k-axis at k = %s and k = %s%s." % [KN(s, c[0]), KN(s, c[1]), " (the GDC's zero)" if p2(s) else ""])
	sk.append("%s is where the sketch is %s the axis%s." % [sym, "above" if cond != "none" else "below", " or on it" if cond == "real" else ""])
	sk.append(final)
	var tbl := base.duplicate()
	if lin:
		tbl.append("Δ changes sign once, at k = %s: Δ %s 0 for k < %s and Δ %s 0 for k > %s." % [N(c[0]), "<" if s.dB.sign() > 0 else ">", N(c[0]), ">" if s.dB.sign() > 0 else "<", N(c[0])])
	elif p2(s):
		tbl.append("With a GDC, Δ = 0 at k = %s and k = %s. Signs: k < %s gives +, %s < k < %s gives −, k > %s gives +." % [
			Fmt.sf(c[0]), Fmt.sf(c[1]), Fmt.sf(c[0]), Fmt.sf(c[0]), Fmt.sf(c[1]), Fmt.sf(c[1])])
	else:
		tbl.append("Δ = (k%s)(k%s). Signs: k < %s gives (−)(−) = +, %s < k < %s gives (+)(−) = −, k > %s gives (+)(+) = +." % [
			Fmt.plus(c[0].neg()), Fmt.plus(c[1].neg()), N(c[0]), N(c[0]), N(c[1]), N(c[1])])
	tbl.append("%s picks the %s rows%s." % [sym, "+" if cond != "none" else "−", ", plus the zeros" if cond == "real" else ""])
	tbl.append(final)
	var tp := base.duplicate()
	var t: Q = c[0].add(1) if lin else c[0].add(c[1]).div(2).add(0)
	if not lin and not t.is_int():
		t = c[0].add(1)
	if p2(s):
		# A whole number between the two irrational zeros.
		t = Q.new(roundi((s.crit_f[0] + s.crit_f[1]) / 2.0))
	var dt := QuadraticParameterSituation.delta_at(s, t)
	tp.append("%sΔ = 0 at %s. Test k = %s: Δ = %s, which is %s." % ["With a GDC, " if p2(s) else "", ("k = " + N(c[0])) if lin else "k = %s and k = %s" % [KN(s, c[0]), KN(s, c[1])], N(t), N(dt), "positive" if dt.sign() > 0 else "negative"])
	tp.append(final)
	var gs: Array = lead.duplicate()
	if p2(s):
		gs.append("Graph y = %s on the GDC with a slider for k: the number of roots changes near k = %s and k = %s." % [kx_text(s), Fmt.sf(c[0]), Fmt.sf(c[1])])
		gs.append("For 3 s.f., " + delta_step(s) + "; graph y = %s and use zero: k = %s or k = %s" % [dexpr(s).replace("k", "x"), Fmt.sf(c[0]), Fmt.sf(c[1])])
	else:
		gs.append("Graph y = %s on the GDC with a slider for k: the number of roots changes at %s." % [kx_text(s), ("k = " + N(c[0])) if lin else "k = %s and k = %s" % [N(c[0]), N(c[1])]])
		gs.append("The slider can't give exact boundaries, so set Δ = 0: " + delta_step(s) + ", and " + zero_step(s))
	gs.append(final)
	return {"discriminant-condition": {"result": res, "steps": dcm}, "sketch-roots": {"result": res, "steps": sk},
		"sign-table": {"result": res, "steps": tbl}, "test-point": {"result": res, "steps": tp},
		"gdc-slider": {"result": res, "steps": gs}}


## Wrong intervals: the opposite region, the ends the other way, and the slips the
## catalogue names for k-interval.
static func interval_wrongs(ans: Dictionary, cond: String, tag: bool) -> Dictionary:
	var v: Dictionary = ans.values
	var wrongs: Array = []
	var generic: Array = []
	if ans.kind == "bound":
		if cond == "real" and tag:
			wrongs.append(wrong({"rel": loose(v.rel), "v": v.v}, "SL2.7.discriminant-parameter#2"))
		generic = [{"rel": flip_rel(v.rel), "v": v.v}, {"rel": loose(v.rel), "v": v.v}, {"rel": v.rel, "v": v.v.neg()}, {"rel": flip_rel(loose(v.rel)), "v": v.v}]
		return {"wrongs": wrongs, "generic": generic}
	var other := "left out" if v.ends == "included" else "included"
	if tag:
		if v.shape == "between" and v.lo.eq(v.hi.neg()):
			wrongs.append(wrong({"shape": "pm_lt", "lo": v.lo, "hi": v.hi, "ends": v.ends}, "SL2.7.discriminant-parameter#1"))
		if cond == "real":
			wrongs.append(wrong({"shape": v.shape, "lo": v.lo, "hi": v.hi, "ends": "left out"}, "SL2.7.discriminant-parameter#2"))
		if v.shape == "outside":
			wrongs.append(wrong({"shape": "between", "lo": v.lo, "hi": v.hi, "ends": v.ends}, "SL2.7.inequality#1"))
	var opp := "outside" if v.shape == "between" else "between"
	generic = [{"shape": opp, "lo": v.lo, "hi": v.hi, "ends": v.ends}, {"shape": v.shape, "lo": v.lo, "hi": v.hi, "ends": other},
		{"shape": opp, "lo": v.lo, "hi": v.hi, "ends": other}, {"shape": v.shape, "lo": v.hi.neg(), "hi": v.lo.neg(), "ends": v.ends}]
	return {"wrongs": wrongs, "generic": generic}


func u_k_interval(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var cond: String = s.cond
	var ans := cond_answer(s, cond)
	var line := is_line(s)
	var said: String = ({"two": "meets the curve y = %s at two distinct points", "none": "does not meet the curve y = %s", "real": "meets the curve y = %s"} if line
		else {"two": "has two distinct real roots", "none": "has no real roots", "real": "has real roots"})[cond]
	var lines: Array = shown(s)
	if line:
		lines = ["The line y = %s %s." % [line_rhs(s), said % curve_rhs(s)]]
	var w := interval_wrongs(ans, cond, true)
	return {
		"asked": ("Find the possible values of k." if line else "The equation f(x) = 0 %s. Find the possible values of k." % said) + to_sf(s),
		"lines": lines, "given": given_of(s).merged({"cond": cond}), "answer": ans,
		"wrongs": w.wrongs, "generic": w.generic,
		"methods": interval_methods(s, cond, ans, equate(s)),
	}


func u_always_positive(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := cond_answer(s, "none")
	var w := interval_wrongs(ans, "none", false)
	var lines: Array = []
	var asked := ""
	if rep == "equation":
		lines = ["g(x) = ln(%s)" % kx_text(s)]
		asked = "The function g is defined for every real x. Find the possible values of k."
	else:
		lines = ["The expression %s is positive for every real value of x." % kx_text(s)]
		asked = "Find the possible values of k."
	asked += to_sf(s)
	var final := "So " + Answer.text(ans) + "."
	var ms := interval_methods(s, "none", ans, [])
	var why := "%s > 0 for all x needs a > 0 (here a = %s) and no real roots, so Δ < 0." % [kx_text(s), N(s.a0)]
	var cd: Array = [why, delta_step(s), zero_step(s), final]
	var dcm: Array = ms["discriminant-condition"].steps.duplicate()
	dcm.insert(0, why)
	var cs: Array = []
	var parts := cs_parts(s)
	cs.append("Complete the square: %s = %s" % [kx_text(s), parts[0]])
	cs.append("With a = %s > 0 the minimum value is %s, and it must be positive." % [N(s.a0), parts[1]])
	cs.append("Times −4a, that is %s < 0; %s" % [dexpr(s), zero_step(s)])
	cs.append(final)
	return {
		"asked": asked, "lines": lines, "given": given_of(s).merged({"cond": "none"}), "answer": ans,
		"wrongs": w.wrongs, "generic": w.generic,
		"methods": {"compute-delta": {"result": ans.values, "steps": cd}, "discriminant-condition": {"result": ans.values, "steps": dcm},
			"complete-square-condition": {"result": ans.values, "steps": cs}},
	}


func u_same_sign_roots(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var hi: Q = s.crit[0]
	var ans := Answer.make("interval", {"shape": "between", "lo": Q.new(0), "hi": hi, "ends": "left out"}, {"var": "k"})
	var final := "So " + Answer.text(ans) + "."
	var two := "Two distinct roots: Δ = %s > 0, so k < %s." % [dexpr(s), N(hi)]
	var prod := "Same sign: the product of the roots c/a = %s is positive, so k > 0." % ("k" if s.a0.eq(1) else "k/" + N(s.a0))
	var res: Dictionary = ans.values
	return {
		"asked": "Find the possible values of k.",
		"lines": ["The equation %s = 0 has two distinct real roots, and they have the same sign." % kx_text(s)],
		"given": given_of(s).merged({"cond": "same-sign"}), "answer": ans,
		"generic": [{"shape": "below", "lo": Q.new(0), "hi": hi, "ends": "left out"}, {"shape": "between", "lo": Q.new(0), "hi": hi, "ends": "included"},
			{"shape": "above", "lo": Q.new(0), "hi": hi, "ends": "left out"}, {"shape": "outside", "lo": Q.new(0), "hi": hi, "ends": "left out"}],
		"methods": {
			"discriminant-condition": {"result": res, "steps": [delta_step(s), two, prod, final]},
			"sketch-roots": {"result": res, "steps": [
				"Sketch y = %s: the axis is x = %s, on the %s side of 0." % [kx_text(s), N(s.b0.neg().div(s.a0.mul(2))), "positive" if s.b0.neg().div(s.a0).sign() > 0 else "negative"],
				"Two crossings need the vertex below the x-axis. " + two,
				"Both crossings on the same side of 0 need the y-intercept k above 0 (a > 0): k > 0.", final]},
			"test-point": {"result": res, "steps": [
				two, prod,
				"Test k = %s, halfway: Δ = %s > 0 and the product is positive, so the answer is the interval between." % [N(hi.div(2)), N(QuadraticParameterSituation.delta_at(s, hi.div(2)))],
				final]},
		},
	}


func u_tangent_contact_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: Q = s.crit[0]
	var pt := QuadraticParameterSituation.contact(s, k)
	var ans := Answer.make("kpoint", {"k": k, "x": pt[0], "y": pt[1]})
	var final := "So " + Answer.text(ans) + "."
	var out := {"answer": ans, "given": given_of(s), "lines": shown(s),
		"asked": "The line is a tangent to the curve. Find k and the point where the line touches the curve."}
	if rep == "words":
		out.lines = ["The line y = %s is a tangent to the curve y = %s." % [line_rhs(s), curve_rhs(s)]]
		out.asked = "Find k and the coordinates of the point where they touch."
	if rep == "graph":
		out.graph = crit_graph(s, "")
		out.lines = shown(s) + ["The sketch shows the line touching the curve."]
	var dc: Array = equate(s)
	dc.append(delta_step(s))
	dc.append("A tangent needs Δ = 0: " + zero_step(s))
	dc.append("The repeated root is x = −b/(2a) = %s, and y = %s × %s%s = %s" % [N(pt[0]), N(s.m), Fmt.paren(pt[0]), Fmt.plus(k), N(pt[1])])
	dc.append(final)
	var res: Dictionary = ans.values
	var wrongs: Array = []
	if int(s.p.n) % 2 == 0:
		var kw: Q = s.r.sub(s.p.sq().div(4))
		var xw: Q = s.p.div(-2)
		wrongs.append(wrong({"k": kw, "x": xw, "y": s.m.mul(xw).add(kw)}, "SL2.7.discriminant-parameter#0"))
	out.wrongs = wrongs
	out.generic = [{"k": k, "x": pt[0].neg(), "y": pt[1]}, {"k": k.neg(), "x": pt[0], "y": pt[1]}, {"k": k, "x": pt[0], "y": pt[1].neg()},
		{"k": k, "x": pt[1], "y": pt[0]}]
	out.methods = {"discriminant-condition": {"result": res, "steps": dc}, "derivative-match": {"result": res, "steps": deriv_steps(s, final)}}
	return out
