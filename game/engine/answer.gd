class_name Answer
extends RefCounted
## What a question's answer looks like, how to write it, and how to mark it.
##
## An answer is a Dictionary:
##   kind       how it is written (see text()): number, axis, xval, roots, point, yint,
##              vertex_form, vertex_form_a, general, general_a, factorised, maxmin,
##              vertex_kind, range, triple, claim; for the triangle situation also
##              measure (a length, angle or area, written to 3 s.f. with its unit); for
##              the distribution situation also pq (two unknown probabilities p and q);
##              for the cubic situation also deriv
##              (f′(x) as a quadratic), line (y = mx + c), tangent_read (f′(x₀) and f(x₀)),
##              points2 (two points, either order) and natures (maximum or minimum at
##              each stationary point);
##              for the Quadratics region (FAL-414) also choice, delta_nature, kvals,
##              interval, bound, quad_in, kpoint, surd, surd_roots, npoint, kroot and
##              ineq_a, with points2 and line as the cubic writes them;
##              for the Quadratics extension types (FAL-459) also poly (a sum of
##              c·xⁿ, with the powers fixed or typed), named (labelled numbers),
##              pair (two numbers, either order), brackets ((x + r)(x + s)),
##              brackets2 ((ax + b)(cx + d)), common (gx(ax + b)), pm_surd
##              (h ± m√r), range2 (lo < x ≤ hi), related (angles as multiples of π),
##              features (a quadratic's y-intercept, roots and vertex) and angles
##              (the solutions of a trig equation, as multiples of π, in any order);
##              for the Exponentials and logs region (FAL-418) also lnq (m·ln r, exact,
##              marked by value so (1/5) ln(1/2) is −(ln 2)/5), pct (a rise or fall of r%),
##              expmodel (P₀(a)^t), limited (C, A and k of C + A·e^(−kt)), fn (a function
##              of x in one of FN_FORMS, its shifts p and q typed; a wrong option may
##              take another form, such as 1/f(x)), logform (log_b x = y) and xpow
##              (xⁿ; a wrong option may be n·x);
##              for the Graphs and key features region (FAL-420) also xs (x-values in
##              any order; options may have other counts), pts (points in any order; a
##              wrong option may give only_x, the x-coordinates) and graph (pick the
##              graph: "Graph A" to "Graph D")
##   template   the slot input: literal Strings, {"slot": id} for a typed number and
##              {"pick": id, "options": [...]} for a choice of words
##   values     slot id -> Q (typed number) or String (picked option)
##   fixed      values shown as given, not asked (a in "2(x − □)² + □")
##   unordered  groups of slot ids that may come in any order (two roots)
##   pairs      (optional) groups of slot-id lists that may swap as wholes: two points
##              [["x1", "y1"], ["x2", "y2"]] can come in either order, each kept whole.
##              points2 swaps its own; any other kind that sets pairs is marked in
##              every order of them (brackets2, a poly with typed powers)
##   unit       text after the number: " cm", "°" (measure only)
##   exact      (optional) true when only the exact value is right, not 3 s.f.: Paper 1
##              answers the IB wants exact, such as a whole-number sum (2345 is not 2350)
##   show       (optional) how a number is written: "dec" as a decimal when it ends
##              (0.35, not 7/20), "money" with two decimal places (2.50), "sf" to 3
##              significant figures (a value a calculator gives); else a fraction.
##              roots, points2 and line honour it too (the cubic's Paper 2, FAL-419)
##   signed     (optional) a measure that may be negative (a decay rate k): wrong options
##              may be negative too
##
## Typed numbers go through parse_number(), which reads them with the calculator's
## expression engine (engine/expr.gd) and takes any that work out to a fraction of whole
## numbers. Godot's Expression class is never used on what a student types (it reads
## 2^3 as 1 and can call engine functions).

const MC_ONLY := ["triple", "claim", "natures", "graph"]
const NATURES := ["local maximum", "local minimum"]


static func make(kind: String, values: Dictionary, fixed: Dictionary = {}, label: String = "", unit: String = "") -> Dictionary:
	var t: Array = []
	var unordered: Array = []
	match kind:
		"number":
			t = [label, {"slot": "v"}]
			if unit != "":
				t.append(unit)
		"xval":
			t = ["x = ", {"slot": "v"}]
		"axis":
			t = [{"pick": "var", "options": ["x", "y"]}, " = ", {"slot": "h"}]
		"roots":
			t = ["x = ", {"slot": "r1"}, " and x = ", {"slot": "r2"}]
			unordered = [["r1", "r2"]]
		"point":
			t = ["(", {"slot": "x"}, ", ", {"slot": "y"}, ")"]
		"yint":
			t = ["(0, ", {"slot": "y"}, ")"]
		"vertex_form":
			t = ["f(x) = ", {"slot": "a"}, "(x − ", {"slot": "h"}, ")² + ", {"slot": "k"}]
		"vertex_form_a":
			t = ["f(x) = %s(x − " % Fmt.lead(fixed.a), {"slot": "h"}, ")² + ", {"slot": "k"}]
		"general":
			t = ["f(x) = ", {"slot": "a"}, "x² + ", {"slot": "b"}, "x + ", {"slot": "c"}]
		"general_a":
			t = ["f(x) = %sx² + " % Fmt.lead(fixed.a), {"slot": "b"}, "x + ", {"slot": "c"}]
		"factorised":
			t = ["f(x) = ", {"slot": "a"}, "(x − ", {"slot": "p"}, ")(x − ", {"slot": "q"}, ")"]
			unordered = [["p", "q"]]
		"maxmin":
			t = [{"pick": "kind", "options": ["maximum", "minimum"]}, " value ", {"slot": "k"}]
		"vertex_kind":
			t = ["(", {"slot": "x"}, ", ", {"slot": "y"}, "), a ", {"pick": "kind", "options": ["maximum", "minimum"]}]
		"range":
			t = [{"pick": "var", "options": ["x", "y"]}, " ", {"pick": "rel", "options": ["≥", "≤"]}, " ", {"slot": "k"}]
		"triple":
			unordered = [["fp", "fq"]]
		"claim":
			t = []
		"measure":
			t = [label, {"slot": "v"}, unit]
		"pq":
			t = ["p = ", {"slot": "p"}, ",  q = ", {"slot": "q"}]
		# ── Quadratics region (FAL-414) ──
		"choice":
			t = [label, {"pick": "v", "options": fixed.options}]
		"delta_nature":
			t = ["Δ = ", {"slot": "d"}, ", so ", {"pick": "nature", "options": fixed.options}]
		"kvals":
			var v: String = fixed.get("var", "k")
			t = [v + " = ", {"slot": "r1"}, " or %s = " % v, {"slot": "r2"}]
			unordered = [["r1", "r2"]]
		"interval":
			t = [fixed.get("var", "k") + " is ", {"pick": "shape", "options": SHAPES}, " ", {"slot": "lo"}, " and ", {"slot": "hi"},
				", with the ends ", {"pick": "ends", "options": ENDS}]
		"bound":
			t = [fixed.get("var", "k") + " ", {"pick": "rel", "options": RELS}, " ", {"slot": "v"}]
		"quad_in":
			var v: String = fixed.get("var", "x")
			t = [label]
			if fixed.has("A"):
				if not Q.of(fixed.A).is_zero():
					t.append(Fmt.lead(fixed.A) + v + "² + ")
			else:
				t.append_array([{"slot": "A"}, v + "² + "])
			t.append_array([{"slot": "B"}, v + " + ", {"slot": "C"}, fixed.get("tail", "")])
		"kpoint":
			t = ["k = ", {"slot": "k"}, ", touching at (", {"slot": "x"}, ", ", {"slot": "y"}, ")"]
		"surd":
			t = [label, {"slot": "m"}, "√", {"slot": "r"}, unit]
		"surd_roots":
			t = ["x = ", {"slot": "h"}, " ± √", {"slot": "d"}]
		"npoint":
			t = ["n = ", {"slot": "n"}, ", other point (", {"slot": "x"}, ", ", {"slot": "y"}, ")"]
		"kroot":
			t = ["k = ", {"slot": "k"}, ", other root x = ", {"slot": "r"}]
		"ineq_a":
			t = ["x² + ", {"slot": "b"}, "x + ", {"slot": "c"}, " ", {"pick": "rel", "options": RELS}, " 0"]
		"deriv":
			t = [label if label != "" else "f′(x) = ", {"slot": "u2"}, "x² + ", {"slot": "u1"}, "x + ", {"slot": "u0"}]
		"line":
			t = ["y = ", {"slot": "m"}, "x + ", {"slot": "c"}]
		"tangent_read":
			t = ["f′(%s) = " % Fmt.num(fixed.x0), {"slot": "m"}, ",  f(%s) = " % Fmt.num(fixed.x0), {"slot": "y"}]
		"points2":
			t = ["(", {"slot": "x1"}, ", ", {"slot": "y1"}, ") and (", {"slot": "x2"}, ", ", {"slot": "y2"}, ")"]
		"natures":
			t = ["x = %s: " % Fmt.num(fixed.p), {"pick": "k1", "options": NATURES}, ",  x = %s: " % Fmt.num(fixed.q), {"pick": "k2", "options": NATURES}]
		# ── Quadratics extension types (FAL-459) ──
		"poly":
			t = [label]
			var v: String = fixed.get("var", "x")
			var n: int = fixed.powers.size()
			for i in n:
				if i == 0 and fixed.has("lead"):
					t.append(Fmt.lead(fixed.lead) + v + Fmt.sup(fixed.powers[0]))
				elif fixed.get("typed_powers", false):
					t.append_array([{"slot": "c%d" % i}, v + "^", {"slot": "e%d" % i}])
				else:
					t.append({"slot": "c%d" % i})
					if int(fixed.powers[i]) != 0:
						t.append(v + Fmt.sup(fixed.powers[i]))
				if i < n - 1:
					t.append(" + ")
		"named":
			var names: Array = fixed.names
			for i in names.size():
				t.append(("" if i == 0 else ",  ") + names[i] + " = ")
				t.append({"slot": "v%d" % i})
				if fixed.has("units"):
					t.append(fixed.units[i])
		"pair":
			t = [label, {"slot": "r1"}, " and ", {"slot": "r2"}]
			unordered = [["r1", "r2"]]
		"brackets":
			t = [label + "(x + ", {"slot": "r"}, ")(x + ", {"slot": "s"}, ")"]
			unordered = [["r", "s"]]
		"brackets2":
			t = [label + "(", {"slot": "a1"}, "x + ", {"slot": "b1"}, ")(", {"slot": "a2"}, "x + ", {"slot": "b2"}, ")"]
		"common":
			t = [label, {"slot": "g"}, "x(", {"slot": "a"}, "x + ", {"slot": "b"}, ")"]
		"pm_surd":
			t = [label, {"slot": "h"}, " ± ", {"slot": "m"}, "√", {"slot": "r"}]
		"range2":
			t = [{"slot": "lo"}, " ", {"pick": "r1", "options": ["<", "≤"]}, " %s " % fixed.get("var", "x"), {"pick": "r2", "options": ["<", "≤"]}, " ", {"slot": "hi"}]
		"related":
			t = ["same value: ", {"slot": "s"}, "π;  opposite sign: ", {"slot": "o1"}, "π and ", {"slot": "o2"}, "π"]
			unordered = [["o1", "o2"]]
		"features":
			t = ["y-intercept ", {"slot": "c"}, ";  roots ", {"slot": "r1"}, " and ", {"slot": "r2"}, ";  vertex (", {"slot": "h"}, ", ", {"slot": "k"}, ")"]
			unordered = [["r1", "r2"]]
		"angles":
			t = ["x = "]
			var ids: Array = []
			for i in int(fixed.n):
				if i > 0:
					t.append(" or " if i == int(fixed.n) - 1 else ", ")
				t.append({"slot": "a%d" % i})
				t.append("π")
				ids.append("a%d" % i)
			unordered = [ids]
		# ── Exponentials and logs (FAL-418) ──
		"lnq":
			t = [label, {"slot": "m"}, " ln ", {"slot": "r"}]
		"pct":
			t = ["a ", {"pick": "dir", "options": DIRS}, " of ", {"slot": "v"}, "% " + str(fixed.get("per", ""))]
		"expmodel":
			t = ["%s(t) = " % fixed.get("sym", "P"), {"slot": "p0"}, "(", {"slot": "a"}, ")^t"]
		"limited":
			t = ["C = ", {"slot": "C"}, ",  A = ", {"slot": "A"}, ",  k = ", {"slot": "k"}]
		"fn":
			var head: String = fixed.get("name", "f(x)") + " = "
			var bb := base_text(fixed.b)
			match fixed.get("shape", "exp"):
				"exp":
					t = [head + bb + "^(x − ", {"slot": "p"}, ") + ", {"slot": "q"}]
				"log":
					t = [head + log_name(fixed.b) + "(x − ", {"slot": "p"}, ") + ", {"slot": "q"}]
				"exphalf":
					t = [head + bb + "^(x/2) + ", {"slot": "q"}]
		"logform":
			t = ["log base ", {"slot": "b"}, " of ", {"slot": "x"}, " = ", {"slot": "y"}]
		"xpow":
			t = [fixed.get("name", "y") + " = x^", {"slot": "n"}]
		# ── Graphs and key features (FAL-420) ──
		"xs":
			t = [fixed.get("var", "x") + " = "]
			var ids: Array = []
			var n := int(str(values.n))
			for i in n:
				if i > 0:
					t.append(" or " if i == n - 1 else ", ")
				t.append({"slot": "x%d" % i})
				ids.append("x%d" % i)
			unordered = [ids]
		"graph":
			t = [{"pick": "v", "options": fixed.options}]
		"pts":
			var n := int(str(values.n))
			for i in n:
				if i > 0:
					t.append(" and " if i == n - 1 else ", ")
				t.append_array(["(", {"slot": "x%d" % i}, ", ", {"slot": "y%d" % i}, ")"])
	var out := {"kind": kind, "template": t, "values": values, "fixed": fixed, "unordered": unordered, "label": label, "unit": unit}
	if kind == "brackets2":
		out.pairs = [["a1", "b1"], ["a2", "b2"]]
	elif kind == "pts":
		out.pairs = range(int(str(values.n))).map(func(i): return ["x%d" % i, "y%d" % i])
	elif kind == "poly" and fixed.get("typed_powers", false):
		out.pairs = range(fixed.powers.size()).map(func(i): return ["c%d" % i, "e%d" % i])
	return out


## The interval kind: between the two numbers, or outside them, with the ends left out
## (strict) or included. pm_lt, pm_gt, below and above are only ever wrong options
## (k < ±6; k < 9 with the other condition forgotten), so they are not offered as picks.
const SHAPES := ["between", "outside"]
const ENDS := ["left out", "included"]
const RELS := ["<", "≤", ">", "≥"]
## A percentage change (pct): a rise or a fall.
const DIRS := ["rise", "fall"]


## show "sf" writes the ends to 3 s.f. (a Paper 2 interval whose ends need a calculator).
static func interval_text(v: String, shape: String, lo: Variant, hi: Variant, ends: String, show: String = "") -> String:
	var inc := ends == "included"
	var lt := "≤" if inc else "<"
	var gt := "≥" if inc else ">"
	var a := Fmt.sf(lo) if show == "sf" else Fmt.num(lo)
	var b := Fmt.sf(hi) if show == "sf" else Fmt.num(hi)
	match shape:
		"between":
			return "%s %s %s %s %s" % [a, lt, v, lt, b]
		"outside":
			return "%s %s %s or %s %s %s" % [v, lt, a, v, gt, b]
		"pm_lt":
			return "%s %s ±%s" % [v, lt, b]
		"pm_gt":
			return "%s %s ±%s" % [v, gt, b]
		"below":
			return "%s %s %s" % [v, lt, b]
		"above":
			return "%s %s %s" % [v, gt, a]
	return "?"


## m√r as written: "3√2", "√5", "4" when r = 1.
static func surd_text(m: Variant, r: Variant) -> String:
	var mq := Q.of(m)
	var rq := Q.of(r)
	if rq.eq(1):
		return Fmt.num(mq)
	return ("" if mq.eq(1) else Fmt.num(mq)) + "√" + Fmt.num(rq)


## m·ln r as the IB writes it: "ln 2", "3 ln 2", "−(ln 2)/5", "(3 ln 2)/5", "ln(3/2)/4".
## A wrong option may take another form: "sub" ln r − m, "dive" r/(me).
static func lnq_text(m: Variant, r: Variant, form: String = "") -> String:
	var mq := Q.of(m)
	var rq := Q.of(r)
	if form == "sub":
		return "ln %s %s %s" % [rq.text(), "−" if mq.sign() >= 0 else "+", mq.abs_q().text()]
	if form == "dive":
		return "%s/(%se)" % [rq.text(), "" if mq.eq(1) else mq.text()]
	var top := "ln " + rq.text() if rq.is_int() else "ln(%s)" % rq.text()
	var n := absi(mq.n)
	if n != 1:
		top = "%d %s" % [n, top]
	var body := top
	if mq.d != 1:
		body = ("(%s)" % top if top.contains(" ") and rq.is_int() else top) + "/%d" % mq.d
	return ("−" if mq.sign() < 0 else "") + body


## The forms an fn answer can take (FAL-418), for b, p and q:
##   exp      b^(x − p) + q          log      log_b(x − p) + q
##   recip    1/(b^(x − p) + q)      pow      (x − p)^b + q
##   exphalf  b^(x/2) + q            pm       q ± b^(x/2)
const FN_FORMS := ["exp", "log", "recip", "pow", "exphalf", "pm"]
const SUBS := "₀₁₂₃₄₅₆₇₈₉"


## A base as written in a power: "2", "e".
static func base_text(b: Variant) -> String:
	return "e" if str(b) == "e" else Fmt.num(b)


## log_b written with its base as a subscript: "log₂", "log₁₀", "ln".
static func log_name(b: Variant) -> String:
	if str(b) == "e":
		return "ln"
	var out := "log"
	for ch in Fmt.num(b):
		out += SUBS[int(ch)]
	return out


## "x − 3", "x + 2", "x".
static func x_minus(p: Variant) -> String:
	var pq := Q.of(p)
	if pq.is_zero():
		return "x"
	return "x %s %s" % ["−" if pq.sign() > 0 else "+", Fmt.num(pq.abs_q())]


## " + 4", " − 1", "".
static func plus_q(q: Variant) -> String:
	var qq := Q.of(q)
	if qq.is_zero():
		return ""
	return " %s %s" % ["+" if qq.sign() > 0 else "−", Fmt.num(qq.abs_q())]


static func fn_text(form: String, b: Variant, p: Variant, q: Variant) -> String:
	var bb := base_text(b)
	var xp := x_minus(p)
	var pw := bb + "^x" if xp == "x" else "%s^(%s)" % [bb, xp]
	match form:
		"exp":
			return pw + plus_q(q)
		"log":
			return "%s(%s)%s" % [log_name(b), xp, plus_q(q)]
		"recip":
			return "1/(%s%s)" % [pw, plus_q(q)] if not Q.of(q).is_zero() else "1/%s" % pw
		"pow":
			var sq := "(%s)%s" % [xp, Fmt.sup(int(b))] if xp != "x" else "x" + Fmt.sup(int(b))
			return sq + plus_q(q)
		"exphalf":
			return bb + "^(x/2)" + plus_q(q)
		"pm":
			return ("" if Q.of(q).is_zero() else Fmt.num(q) + " ") + "± " + bb + "^(x/2)"
	return "?"


## m·ln r as a float, for marking an lnq answer by value.
static func lnq_value(m: Variant, r: Variant, form: String = "") -> float:
	var rq := Q.of(r)
	if rq.sign() <= 0:
		return NAN
	match form:
		"sub":
			return log(rq.to_float()) - Q.of(m).to_float()
		"dive":
			return rq.to_float() / (Q.of(m).to_float() * exp(1.0))
	return Q.of(m).to_float() * log(rq.to_float())


## Whether a student could type these values into the answer's slots: every value that
## isn't a slot (an fn's form, say) is the answer's own. A wrong option in another form,
## such as 1/f(x) for an inverse asked as a log, can be picked but never typed.
static func typable(ans: Dictionary, values: Dictionary) -> bool:
	var ids: Array = slots(ans).map(func(item): return item.get("slot", item.get("pick", "")))
	for key in values:
		if key in ids:
			continue
		if not ans.values.has(key) or str(ans.values[key]) != str(values[key]):
			return false
	return true


## The same answer shape with other values (for a wrong option).
static func with_values(ans: Dictionary, values: Dictionary) -> Dictionary:
	var out := ans.duplicate()
	out.values = values
	return out


static func slots(ans: Dictionary) -> Array:
	var out: Array = []
	for item in ans.template:
		if item is Dictionary:
			out.append(item)
	return out


## The answer written out, as feedback and as a multiple-choice option shows it.
static func text(ans: Dictionary, values: Dictionary = {}) -> String:
	var v: Dictionary = values if not values.is_empty() else ans.values
	var fx: Dictionary = ans.fixed
	match ans.kind:
		"number":
			return ans.label + shown(ans, v.v) + ans.unit
		"xval":
			return "x = " + Fmt.num(v.v)
		"axis":
			return "%s = %s" % [v["var"], Fmt.num(v.h)]
		"roots":
			var rs := _sorted([v.r1, v.r2])
			return "x = %s and x = %s" % [shown(ans, rs[0]), shown(ans, rs[1])]
		"point":
			return "(%s, %s)" % [shown(ans, v.x), shown(ans, v.y)]
		"yint":
			return "(0, %s)" % shown(ans, v.y)
		"vertex_form":
			return "f(x) = " + Fmt.vertex(v.a, v.h, v.k)
		"vertex_form_a":
			return "f(x) = " + Fmt.vertex(fx.a, v.h, v.k)
		"general":
			return "f(x) = " + Fmt.general(v.a, v.b, v.c)
		"general_a":
			return "f(x) = " + Fmt.general(fx.a, v.b, v.c)
		"factorised":
			var rs := _sorted([v.p, v.q])
			return "f(x) = " + Fmt.factorised(v.a, rs[0], rs[1])
		"maxmin":
			return "%s value %s" % [v.kind, Fmt.num(v.k)]
		"vertex_kind":
			return "%s, a %s" % [Fmt.point(v.x, v.y), v.kind]
		"range":
			return "%s %s %s" % [v["var"], v.rel, Fmt.num(v.k)]
		"triple":
			var rs := _sorted([v.fp, v.fq])
			return "%s,  %s,  %s" % [Fmt.general(v.ga, v.gb, v.gc), Fmt.factorised(v.fa, rs[0], rs[1]), Fmt.vertex(v.va, v.vh, v.vk)]
		"claim":
			return v.text
		"measure":
			return ans.label + Fmt.sf(v.v) + ans.unit
		"pq":
			return "p = %s, q = %s" % [shown(ans, v.p), shown(ans, v.q)]
		"choice":
			return ans.label + str(v.v)
		"delta_nature":
			return "Δ = %s, so %s" % [Fmt.num(v.d), v.nature]
		"kvals":
			var rs := _sorted([v.r1, v.r2])
			var name: String = fx.get("var", "k")
			return "%s = %s or %s = %s" % [name, shown(ans, rs[0]), name, shown(ans, rs[1])]
		"interval":
			return interval_text(fx.get("var", "k"), v.shape, v.lo, v.hi, v.ends, ans.get("show", ""))
		"bound":
			return "%s %s %s" % [fx.get("var", "k"), v.rel, shown(ans, v.v)]
		"quad_in":
			var a: Variant = fx.A if fx.has("A") else v.A
			return ans.label + Fmt.poly([a, v.B, v.C], fx.get("var", "x")) + fx.get("tail", "")
		"kpoint":
			return "k = %s, touching at %s" % [Fmt.num(v.k), Fmt.point(v.x, v.y)]
		"surd":
			return ans.label + surd_text(v.m, v.r) + ans.unit
		"surd_roots":
			return "x = %s± √%s" % ["" if Q.of(v.h).is_zero() else Fmt.num(v.h) + " ", Fmt.num(v.d)]
		"npoint":
			return "n = %s, other point %s" % [Fmt.num(v.n), Fmt.point(v.x, v.y)]
		"kroot":
			return "k = %s, other root x = %s" % [Fmt.num(v.k), Fmt.num(v.r)]
		"ineq_a":
			return "%s %s 0" % [Fmt.poly([1, v.b, v.c]), v.rel]
		"deriv":
			return (ans.label if ans.label != "" else "f′(x) = ") + Fmt.poly([v.u2, v.u1, v.u0])
		"line":
			if ans.get("show", "") == "sf":
				return "y = " + sf_line(v.m, v.c)
			return "y = " + Fmt.poly([v.m, v.c])
		"tangent_read":
			return "f′(%s) = %s,  f(%s) = %s" % [Fmt.num(fx.x0), Fmt.num(v.m), Fmt.num(fx.x0), Fmt.num(v.y)]
		"points2":
			var ps := _pairs(v)
			return "(%s, %s) and (%s, %s)" % [shown(ans, ps[0][0]), shown(ans, ps[0][1]), shown(ans, ps[1][0]), shown(ans, ps[1][1])]
		"natures":
			return "x = %s: %s,  x = %s: %s" % [Fmt.num(fx.p), v.k1, Fmt.num(fx.q), v.k2]
		"poly":
			return ans.label + poly_text(ans, v)
		"named":
			var parts: PackedStringArray = []
			for i in fx.names.size():
				parts.append("%s = %s%s" % [fx.names[i], shown(ans, v["v%d" % i]), fx.units[i] if fx.has("units") else ""])
			return ", ".join(parts)
		"pair":
			var rs := _sorted([v.r1, v.r2])
			return "%s%s and %s" % [ans.label, Fmt.num(rs[0]), Fmt.num(rs[1])]
		"brackets":
			var rs := _sorted([v.r, v.s])
			return ans.label + Fmt.factor(Q.of(rs[1]).neg()) + Fmt.factor(Q.of(rs[0]).neg())
		"brackets2":
			var bs: Array = [[v.a1, v.b1], [v.a2, v.b2]]
			return ans.label + "(%s)(%s)" % [Fmt.poly([bs[0][0], bs[0][1]]), Fmt.poly([bs[1][0], bs[1][1]])]
		"common":
			return ans.label + Fmt.lead(v.g) + "x(" + Fmt.poly([v.a, v.b]) + ")"
		"pm_surd":
			var h := Q.of(v.h)
			return ans.label + ("" if h.is_zero() else Fmt.num(h) + " ") + "± " + surd_text(v.m, v.r)
		"range2":
			return "%s %s %s %s %s" % [shown(ans, v.lo), v.r1, fx.get("var", "x"), v.r2, shown(ans, v.hi)]
		"related":
			var os := _sorted([v.o1, v.o2])
			return "same value %s; opposite sign %s and %s" % [Fmt.pi(v.s), Fmt.pi(os[0]), Fmt.pi(os[1])]
		"features":
			var rs := _sorted([v.r1, v.r2])
			return "y-intercept %s; roots %s and %s; vertex %s" % [Fmt.num(v.c), Fmt.num(rs[0]), Fmt.num(rs[1]), Fmt.point(v.h, v.k)]
		"angles":
			var xs := _sorted(range(int(fx.n)).map(func(i): return v["a%d" % i]))
			var names: Array = xs.map(func(x): return Fmt.pi(x))
			return "x = " + (", ".join(names.slice(0, names.size() - 1)) + " or " + names[names.size() - 1] if names.size() > 1 else names[0])
		"lnq":
			return ans.label + lnq_text(v.m, v.r, v.get("form", ""))
		"pct":
			var pv: String = Fmt.dec(v.v) if ans.get("exact", false) else Fmt.sf(v.v)
			return ("a %s of %s%% %s" % [v.dir, pv, fx.get("per", "")]).strip_edges()
		"expmodel":
			return "%s(t) = %s(%s)^t" % [fx.get("sym", "P"), Fmt.dec(v.p0), Fmt.dec(v.a)]
		"limited":
			return "C = %s, A = %s, k = %s" % [Fmt.num(v.C), Fmt.num(v.A), Fmt.sf(v.k)]
		"fn":
			return fx.get("name", "f(x)") + " = " + fn_text(v.get("form", fx.get("shape", "exp")), fx.b, v.get("p", 0), v.q)
		"logform":
			return "%s %s = %s" % [log_name(v.b), Fmt.num(v.x), Fmt.num(v.y)]
		"xpow":
			var nq := Q.of(v.n)
			if v.get("form", "") == "lin":
				return fx.get("name", "y") + " = " + Fmt.lead(nq) + "x"
			return fx.get("name", "y") + " = x" + (Fmt.sup(nq.n) if nq.is_int() and nq.sign() > 0 else "^(%s)" % nq.text())
		"xs":
			return fx.get("var", "x") + " = " + xs_list(_sorted(xs_values(v)).map(func(x): return shown(ans, x)))
		"graph":
			return str(v.v)
		"pts":
			# A wrong option may give only the x-coordinates (SL2.4.intersection#0).
			if v.get("only_x", false):
				return "x = " + xs_list(pts_values(v).map(func(p): return shown(ans, p[0]))).replace(" or ", " and x = ")
			return xs_list(pts_values(v).map(func(p): return "(%s, %s)" % [shown(ans, p[0]), shown(ans, p[1])])).replace(" or ", " and ")
	return "?"


## The points of a pts answer, in order of x: [[x, y], ...].
static func pts_values(v: Dictionary) -> Array:
	var out: Array = []
	for i in int(str(v.n)):
		out.append([v["x%d" % i], v["y%d" % i]])
	out.sort_custom(func(a, b): return Q.of(a[0]).to_float() < Q.of(b[0]).to_float())
	return out


## A pts answer's values from a list of [x, y].
static func pts_of(ps: Array) -> Dictionary:
	var out := {"n": str(ps.size())}
	for i in ps.size():
		out["x%d" % i] = ps[i][0]
		out["y%d" % i] = ps[i][1]
	return out


## The x-values of an xs answer, as many as its own count says.
static func xs_values(v: Dictionary) -> Array:
	var out: Array = []
	for i in int(str(v.n)):
		out.append(v["x%d" % i])
	return out


## "a", "a or b", "a, b or c".
static func xs_list(names: Array) -> String:
	if names.size() <= 1:
		return names[0] if names.size() == 1 else ""
	return ", ".join(names.slice(0, names.size() - 1)) + " or " + names[names.size() - 1]


## An xs answer's values from a list of numbers.
static func xs_of(xs: Array) -> Dictionary:
	var out := {"n": str(xs.size())}
	for i in xs.size():
		out["x%d" % i] = xs[i]
	return out


## mx + c with both numbers to 3 s.f. (a Paper 2 line): "2.31x − 0.552", "−4.70x".
static func sf_line(m: Variant, c: Variant) -> String:
	var mq := Q.of(m)
	var cq := Q.of(c)
	var out := Fmt.sf(mq) + "x"
	if not cq.is_zero():
		out += (" − " if cq.sign() < 0 else " + ") + Fmt.sf(cq.abs_q())
	return out


## A poly answer written out: its terms in the order of its powers, each power the
## value's own when the powers are typed.
static func poly_text(ans: Dictionary, v: Dictionary) -> String:
	var fx: Dictionary = ans.fixed
	var coeffs: Array = []
	var powers: Array = []
	for i in fx.powers.size():
		coeffs.append(fx.lead if i == 0 and fx.has("lead") else v["c%d" % i])
		powers.append(int(Q.of(v["e%d" % i]).n) if fx.get("typed_powers", false) else int(fx.powers[i]))
	return Fmt.terms(coeffs, powers, fx.get("var", "x"), ans.get("show", "") == "dec")


## A typed number as the answer writes it: a fraction, a decimal or money (see show).
static func shown(ans: Dictionary, v: Variant) -> String:
	match ans.get("show", ""):
		"dec":
			return Fmt.dec(v)
		"money":
			return Fmt.money(v)
		"sf":
			return Fmt.sf(v)
	return Fmt.num(v)


## A key that is the same for two answers exactly when their values are, with
## unordered slots sorted. Used to keep wrong options apart from each other and
## from the answer.
static func canon(ans: Dictionary, values: Dictionary) -> String:
	if ans.kind == "claim":
		return "claim:" + str(values.form) + ":" + str(values.vals.map(func(e): return e.key() if e is Q else str(e)))
	# A measure is told apart by what it shows: two values with the same 3 s.f. are one option.
	if ans.kind == "measure":
		return "measure:" + Fmt.sf(values.v)
	# So is any answer written to 3 s.f. (FAL-459): it is told apart by its text.
	if ans.get("show", "") == "sf":
		return "sf:" + text(ans, values)
	if ans.kind == "lnq":
		return "lnq:%.9f" % lnq_value(values.m, values.r, values.get("form", ""))
	# Its options may have other counts, so an xs answer is told apart by its text.
	if ans.kind in ["xs", "pts"]:
		return ans.kind + ":" + text(ans, values)
	# Shown to 3 s.f. or as decimals: two values that read the same are one option.
	if ans.kind in ["pct", "expmodel", "limited", "fn", "xpow"]:
		return ans.kind + ":" + text(ans, values)
	var v := values.duplicate()
	if ans.kind == "points2":
		var ps := _pairs(v)
		v = {"x1": ps[0][0], "y1": ps[0][1], "x2": ps[1][0], "y2": ps[1][1]}
	elif not ans.get("pairs", []).is_empty():
		# Groups that swap as wholes: written in a sorted order of their values.
		var groups: Array = ans.pairs.map(func(g): return g.map(func(id): return v[id].key() if v[id] is Q else str(v[id])))
		var order := range(groups.size())
		order.sort_custom(func(i, j): return str(groups[i]) < str(groups[j]))
		var nv := v.duplicate()
		for gi in order.size():
			for k in ans.pairs[gi].size():
				nv[ans.pairs[gi][k]] = v[ans.pairs[order[gi]][k]]
		v = nv
	for group in ans.unordered:
		var sorted_vals := _sorted(group.map(func(id): return v[id]))
		for i in group.size():
			v[group[i]] = sorted_vals[i]
	var keys := v.keys()
	keys.sort()
	var parts: PackedStringArray = []
	for key in keys:
		parts.append("%s=%s" % [key, v[key].key() if v[key] is Q else str(v[key])])
	return ",".join(parts)


## Plain strings for the export: Q -> "3/2".
static func export_values(values: Dictionary) -> Dictionary:
	var out := {}
	for key in values:
		var x = values[key]
		if x is Q:
			out[key] = x.key()
		elif x is Array:
			out[key] = x.map(func(e): return e.key() if e is Q else e)
		else:
			out[key] = x
	return out


## The two points of a points2 answer, the one with the smaller x first.
static func _pairs(v: Dictionary) -> Array:
	var ps: Array = [[v.x1, v.y1], [v.x2, v.y2]]
	var x0 := Q.of(ps[0][0]).to_float()
	var x1 := Q.of(ps[1][0]).to_float()
	if x1 < x0 or (x1 == x0 and Q.of(ps[1][1]).to_float() < Q.of(ps[0][1]).to_float()):
		ps.reverse()
	return ps


## In order of value. Compared as floats: a GDC value has nine decimal places, and
## Q.lt's cross-multiplying would overflow.
static func _sorted(qs: Array) -> Array:
	var out := qs.duplicate()
	out.sort_custom(func(x, y): return Q.of(x).to_float() < Q.of(y).to_float())
	return out


# ── Typed numbers ────────────────────────────────────────────

## Reads a typed number with the expression engine (Expr, the calculator's own): 3,
## −1.5, .5, 3/2, 3/-2, ½, 2(3), 2^-1, with an optional "x =" or "y =" in front and
## spaces anywhere. The value must be a fraction of whole numbers, so exact marking
## stays exact: √2 or ln 2 is turned down with a note to work it out. Returns
## {"ok": true, "q": Q, "decimal": bool} or {"ok": false, "error": "..."}.
static func parse_number(raw: String) -> Dictionary:
	var s := raw.strip_edges().replace("−", "-").replace("–", "-").replace("—", "-")
	var bare := s.replace(" ", "")
	for prefix in ["f(x)=", "y=", "x=", "Y=", "X="]:
		if bare.begins_with(prefix):
			s = s.substr(s.find("=") + 1)
			break
	if s.strip_edges() == "":
		return {"ok": false, "error": "empty"}
	var r := Expr.parse(s)
	if not r.ok:
		if r.error == "empty":
			return r
		return {"ok": false, "error": "Type a number, like 3, −1.5 or 3/2."}
	var q := Expr.eval_exact(r.tree)
	if q == null:
		if is_finite(Expr.eval_float(r.tree)) and not _divides_by_zero(r.tree):
			return {"ok": false, "error": "Work that out to a number, like 2.35."}
		return {"ok": false, "error": "That has no value: is something divided by 0?"}
	return {"ok": true, "q": q, "decimal": r.decimal}


## Whether a tree divides by 0 anywhere (1/0, 3/(2 − 2)).
static func _divides_by_zero(tree: Variant) -> bool:
	if not tree is Array:
		return false
	if tree[0] == "div":
		var b := Expr.eval_exact(tree[2])
		if b != null and b.is_zero():
			return true
	for i in range(1, tree.size()):
		if tree[i] is Array and _divides_by_zero(tree[i]):
			return true
	return false


## IB style: right if exact, or if it rounds to the same 3 significant figures as the
## exact value, or if it is the exact value correctly rounded to the 3 or more figures
## typed (12.35 for 12.3456 is right, though 12.35 itself rounds to 12.4).
static func number_right(typed: Q, exact: Q) -> bool:
	if typed.eq(exact):
		return true
	if exact.is_zero():
		return false
	var t := exact.to_float()
	var e := floori(log(absf(t)) / log(10.0) + 1e-12)
	var unit := pow(10.0, e - 2)
	var same := roundi(t / unit) == roundi(typed.to_float() / unit)
	# Across a power of ten (0.997 against 1.002) the typed number's own 3 s.f. must
	# agree too: 0.997 is not 1.00.
	if same and typed.to_float() != 0.0:
		var te := floori(log(absf(typed.to_float())) / log(10.0) + 1e-12)
		if te != e:
			var tu := pow(10.0, te - 2)
			same = roundi(t / tu) == roundi(typed.to_float() / tu)
	return same or _rounded_to_own_figures(typed, t, unit)


## Whether x is at least `edge` units of its 3rd significant figure away from a
## rounding edge, so its 3 s.f. value does not hang on the last digits of a
## calculation (32.55 can show as 32.5 or 32.6).
static func rounds_clearly(x: float, edge: float = 0.02) -> bool:
	if x == 0.0 or not is_finite(x):
		return false
	var e := floori(log(absf(x)) / log(10.0) + 1e-12)
	var scaled := absf(x) / pow(10.0, e - 2)
	return absf(scaled - floorf(scaled) - 0.5) >= edge


## Whether a typed decimal at least as fine as t's 3rd significant figure (unit) is t
## rounded to as many decimal places as it has. 100 is not right for 99.94: it has
## three digits, but it is coarser than 99.9.
static func _rounded_to_own_figures(typed: Q, t: float, unit: float) -> bool:
	var scale := 1
	var places := 0
	while scale % typed.d != 0:
		scale *= 10
		places += 1
		if places > 9:
			return false
	if scale * unit < 1.0 - 1e-9:
		return false
	return roundi(t * scale) == typed.n * (scale / typed.d)


## Q7 on the FAL-274 plan: the right value written with too few significant figures
## (2.3 for 2.347) is a glancing hit, not a miss. Only when the exact value needs
## rounding at 3 s.f. (so 1 is not a glancing 1/2), and only when the typed number is
## the value rounded to its own, coarser, places.
static func number_glancing(typed: Q, exact: Q) -> bool:
	if exact.is_zero() or typed.is_zero() or number_right(typed, exact) or not needs_rounding(exact):
		return false
	var t := exact.to_float()
	var e := floori(log(absf(t)) / log(10.0) + 1e-12)
	var unit := pow(10.0, e - 2)
	var scale := 1
	var places := 0
	while scale % typed.d != 0:
		scale *= 10
		places += 1
		if places > 9:
			return false
	if scale * unit >= 1.0 - 1e-9:
		return false
	return roundi(t * scale) == typed.n * (scale / typed.d)


## Whether a value can't be written exactly in 3 significant figures (2/3, 2.347), so
## a 3 s.f. answer is a rounded one.
static func needs_rounding(v: Q) -> bool:
	if v.is_zero():
		return false
	var r := parse_number(Fmt.sf(v).replace("−", "-"))
	return not (r.ok and r.q.eq(v))


## Kinds whose one typed number can be shown rounded, as a rounding trap.
const TRAP_KINDS := ["number", "xval", "axis", "yint"]


## The rounding trap for a multiple-choice question (Q7): the answer's value rounded to
## 2 significant figures, a glancing hit if picked. {} where it doesn't fit: the answer
## is exact-only, has more than one number, or its number needs no rounding. Every
## situation's views offer it as `trap` (see game/README.md).
static func rounding_trap(ans: Dictionary) -> Dictionary:
	if ans.get("exact", false) or not ans.kind in TRAP_KINDS:
		return {}
	var nums := slots(ans).filter(func(item): return item.has("slot"))
	if nums.size() != 1:
		return {}
	var id: String = nums[0].slot
	var v: Variant = ans.values[id]
	if not v is Q or not needs_rounding(v):
		return {}
	var r := parse_number(Fmt.sf(v, 2).replace("−", "-"))
	if not r.ok or r.q.is_zero():
		return {}
	var out := (ans.values as Dictionary).duplicate()
	out[id] = r.q
	return out


## A rounding trap written as a student would write it, as a decimal.
static func trap_text(ans: Dictionary, values: Dictionary) -> String:
	match ans.kind:
		"number":
			return ans.label + Fmt.dec(values.v) + ans.unit
		"xval":
			return "x = " + Fmt.dec(values.v)
		"axis":
			return "%s = %s" % [values["var"], Fmt.dec(values.h)]
		"yint":
			return "(0, %s)" % Fmt.dec(values.y)
		# Several numbers at 2 s.f. (FAL-420): each written as the decimal it is.
		"point":
			return "(%s, %s)" % [Fmt.dec(values.x), Fmt.dec(values.y)]
		"points2":
			var ps := _pairs(values)
			return "(%s, %s) and (%s, %s)" % [Fmt.dec(ps[0][0]), Fmt.dec(ps[0][1]), Fmt.dec(ps[1][0]), Fmt.dec(ps[1][1])]
		"range2":
			return "%s %s %s %s %s" % [Fmt.dec(values.lo), values.r1, fx_var(ans), values.r2, Fmt.dec(values.hi)]
		"xs":
			return fx_var(ans) + " = " + xs_list(_sorted(xs_values(values)).map(func(x): return Fmt.dec(x)))
		"pts":
			return xs_list(pts_values(values).map(func(p): return "(%s, %s)" % [Fmt.dec(p[0]), Fmt.dec(p[1])])).replace(" or ", " and ")
		"named":
			var parts: PackedStringArray = []
			for i in ans.fixed.names.size():
				parts.append("%s = %s" % [ans.fixed.names[i], Fmt.dec(values["v%d" % i])])
			return ", ".join(parts)
	return text(ans, values)


static func fx_var(ans: Dictionary) -> String:
	return ans.fixed.get("var", "x")


## Q7's rounding trap for an answer of several 3 s.f. numbers (a point, a list of
## zeros, named values): every number to 2 s.f. {} where none needs rounding.
static func rounding_trap_all(ans: Dictionary) -> Dictionary:
	if ans.get("exact", false):
		return {}
	var out := (ans.values as Dictionary).duplicate()
	var any := false
	for item in slots(ans):
		if not item.has("slot"):
			continue
		var v: Variant = ans.values[item.slot]
		if not v is Q or v.is_zero():
			continue
		if needs_rounding(v):
			var r := parse_number(Fmt.sf(v, 2).replace("−", "-"))
			if not r.ok or r.q.is_zero():
				return {}
			out[item.slot] = r.q
			any = true
	return out if any else {}


## Marks typed slot entries. response: slot id -> String (typed or picked).
## Returns {"correct": bool, "complete": bool, "glancing": bool, "errors": {id: message},
## "values": {...}}. glancing: not right, but right with too few figures (Q7).
static func mark(ans: Dictionary, response: Dictionary) -> Dictionary:
	var errors := {}
	var got := {}
	for item in slots(ans):
		var id: String = item.get("slot", item.get("pick", ""))
		var raw := str(response.get(id, ""))
		if item.has("pick"):
			if raw == "":
				errors[id] = "Choose one."
			got[id] = raw
		else:
			var r := parse_number(raw)
			if not r.ok:
				errors[id] = r.error if r.error != "empty" else "Fill this in."
			else:
				got[id] = r.q
	if not errors.is_empty():
		return {"correct": false, "complete": false, "glancing": false, "errors": errors, "values": got}
	var right := values_right(ans, got)
	return {"correct": right, "complete": true, "glancing": not right and values_right(ans, got, true),
		"errors": {}, "values": got}


## Whether typed values match the answer, slot by slot, trying each order of an
## unordered group. With glancing, a number with too few figures counts too.
static func values_right(ans: Dictionary, got: Dictionary, glancing: bool = false) -> bool:
	if ans.kind == "lnq":
		# Marked by value: (1/5) ln(1/2) and −(1/5) ln 2 are the same k.
		var want := lnq_value(ans.values.m, ans.values.r)
		var have := lnq_value(got.get("m", Q.new(0)), got.get("r", Q.new(0))) if got.get("m") is Q and got.get("r") is Q else NAN
		return is_finite(have) and absf(have - want) <= 1e-9 * maxf(1.0, absf(want))
	if ans.kind == "points2" and not got.is_empty():
		var swapped := {"x1": got.get("x2"), "y1": got.get("y2"), "x2": got.get("x1"), "y2": got.get("y1")}
		var plain := ans.duplicate()
		plain.kind = "point_pair"
		return values_right(plain, got, glancing) or values_right(plain, swapped, glancing)
	if not ans.get("pairs", []).is_empty():
		var plain := ans.duplicate()
		plain.erase("pairs")
		for perm in _perms(range(ans.pairs.size())):
			var moved := got.duplicate()
			for gi in perm.size():
				for k in ans.pairs[gi].size():
					moved[ans.pairs[gi][k]] = got.get(ans.pairs[perm[gi]][k])
			if values_right(plain, moved, glancing):
				return true
		return false
	var want: Dictionary = ans.values
	var exact: bool = ans.get("exact", false)
	var free := {}
	for group in ans.unordered:
		for id in group:
			free[id] = true
	for item in slots(ans):
		var id: String = item.get("slot", item.get("pick", ""))
		if free.has(id):
			continue
		if not _slot_right(want[id], got.get(id), exact, glancing):
			return false
	for group in ans.unordered:
		var ok := false
		for perm in _perms(group):
			var all := true
			for i in group.size():
				if not _slot_right(want[group[i]], got.get(perm[i]), exact, glancing):
					all = false
					break
			if all:
				ok = true
				break
		if not ok:
			return false
	return true


static func _slot_right(want: Variant, got: Variant, exact: bool = false, glancing: bool = false) -> bool:
	if want is Q:
		if not got is Q:
			return false
		if exact:
			return got.eq(want)
		return number_right(got, want) or (glancing and number_glancing(got, want))
	return str(want) == str(got)


static func _perms(ids: Array) -> Array:
	if ids.size() <= 1:
		return [ids]
	var out: Array = []
	for i in ids.size():
		var rest := ids.duplicate()
		rest.remove_at(i)
		for p in _perms(rest):
			out.append([ids[i]] + p)
	return out
