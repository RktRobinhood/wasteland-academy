class_name ExpLogPairViews
extends RefCounted
## The views on the `exp-log-pair` situation: one builder per unknown of
## fn-exp-log-inverse-composite (FAL-418). Builders return what QuadraticViews' builders
## return (see quadratic_views.gd). Paper 1: every answer is exact.
##
## Paper 2 (FAL-419, papers()): g at an input whose inside is not a power of b, g⁻¹ at
## a decimal, log_b(x − h) + c = a decimal and e^(mx) + c = d, each asked to 3 s.f.
## (show "sf") and worked with a GDC, with the rounding trap. fn-ext-exp-graph is
## Paper 1 only.
##
## `given` holds the numbers the student is shown, for the SymPy checker, which reads
## them back from the lines, the table and the graph.

const NEED := {
	"evaluate-log-function": {"mode": "log"},
	"log-of-non-positive": {"mode": "log"},
	"inverse-of-exponential": {"mode": "exp"},
	"inverse-of-log": {"mode": "log"},
	"evaluate-inverse": {"mode": "log"},
	"inverse-awkward-base": {"mode": "family", "awkward": true},
	"simplify-composite": {"mode": "family"},
	"composite-inequality": {"mode": "ineq"},
	"transformations-between": {"mode": "transform"},
	"write-log-form": {"mode": "log"},
	"solve-exp-equation": {"mode": "esolve"},
	"solve-log-equation": {"mode": "log"},
	"composite-order": {"mode": "compose"},
	"inverse-graph": {"mode": "exp", "graph": true},
	"inverse-log-of-square": {"mode": "square"},
	"function-from-inverse": {"mode": "log"},
	# fn-ext-exp-graph (the extra skill "Exponential graphs")
	"y-intercept": {"mode": "expgraph", "h_nonzero": true},
	"asymptote": {"mode": "expgraph", "c_nonzero": true},
	"range": {"mode": "expgraph", "c_nonzero": true},
	"growth-or-decay": {"mode": "expgraph", "a_pos": true},
	"pick-graph": {"mode": "expgraph", "a_pos": true},
	"moves-from-parent": {"mode": "expgraph"},
	"equation-from-graph": {"mode": "expgraph", "h0": true, "c_nonzero": true},
	"compare-reflections": {"mode": "expgraph"},
}
## The extra formats the fn-ext-exp-graph views build (the catalogue lists true-false-reason).
const EXTRA := ["y-intercept", "asymptote", "range", "growth-or-decay", "pick-graph", "moves-from-parent",
	"equation-from-graph", "compare-reflections"]
const NOT_DEFINED := "not defined: there is no log of a number that is not positive"
## Slips with no ref of their own (FAL-815): "<type id>#<index>".
const EL := "fn-exp-log-inverse-composite#"
const EG := "fn-ext-exp-graph#"
const NO_C := EL + "19"  ## the number outside the log left off
const KEEP_SHIFTS := EL + "20"  ## exp and log swapped, the shifts left where they were
const SHIFT_SIGNS := EL + "21"  ## both shifts undone with the wrong signs
const NO_H := EL + "22"  ## the shift inside the bracket not added back
const C_FIRST := EL + "23"  ## the base raised to the value before the outside number is taken off
const BASE_POWER := EL + "24"  ## the base's own power over the common base forgotten
const LOG_LEFT := EL + "25"  ## the log inequality's bound given for x
const SF_A := EL + "26"  ## a, not 1/a, as the scale factor of f(ax)
const SWAP_BASE := EL + "27"  ## base and number swapped in log form
const SWAP_POWER := EL + "28"  ## power and number swapped in log form
const NO_ROOT := EL + "29"  ## the square not undone, so the power isn't halved
const LINE_C := EG + "4"  ## the constant taken as the y-intercept, as for a line
const NO_ADD_C := EG + "5"  ## the constant not added at x = 0
const X_EQ_C := EG + "6"  ## the asymptote written x = c
const PARENT_ASYM := EG + "7"  ## the parent's asymptote y = 0 kept
const NEG_A := EG + "8"  ## a negative A not turning the graph over
const MINUS_X := EG + "9"  ## b^(−x) read as having base b
const SHIFT_WAY := EG + "10"  ## the x shift taken the wrong way
const NO_A := EG + "11"  ## the y-value not multiplied by A
const A_IS_Y0 := EG + "12"  ## A read as the y-intercept, c not taken off
const B_NOT_DIV := EG + "13"  ## b not divided by A
## The cells with a Paper 2 version: unknown -> its representations.
const PAPER2 := {"evaluate-log-function": ["equation"], "evaluate-inverse": ["equation"],
	"solve-exp-equation": ["equation"], "solve-log-equation": ["equation"]}


func has(unknown: String) -> bool:
	return NEED.has(unknown)


func need(unknown: String, _rep: String) -> Dictionary:
	return NEED[unknown].duplicate()


## The papers a cell can be asked on (QuestionEngine.cell_papers).
func papers(unknown: String, rep: String, _angle: String) -> Array:
	return [1, 2] if rep in PAPER2.get(unknown, []) else [1]


func formats(unknown: String) -> Array:
	return ["true-false-reason"] if unknown in EXTRA else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "wrongs", "fillers"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "fillers"] else null
	if not out.has("given"):
		out.given = ExpLogPairSituation.export(s)
	out.trap = Answer.rounding_trap(out.answer) if s.get("paper", 1) == 2 else {}
	# Numbers written with %d keep a hyphen for a minus: the game writes "−".
	out.asked = M(out.asked)
	out.lines = out.lines.map(func(l): return M(l))
	for a in out.methods:
		out.methods[a].steps = out.methods[a].steps.map(func(st): return Step.map_text(st, M))
	return out


static var _minus := RegEx.create_from_string("-(?=\\d)")


## A true minus sign for every hyphen before a digit.
static func M(text: String) -> String:
	return _minus.sub(text, "−", true)


## b to a rational power: "2³", "4^(3/2)".
static func QP(b: Variant, n: Q) -> String:
	return Answer.base_text(b) + Fmt.sup(n.n) if n.is_int() and n.sign() > 0 and n.n != 1 else "%s^(%s)" % [Answer.base_text(b), N(n)]


# ── Helpers ──────────────────────────────────────────────────

static func N(v: Variant) -> String:
	return Fmt.num(v)


static func wrong(values: Dictionary, ref: String = "") -> Dictionary:
	return {"values": values, "ref": ref}


static func LG(b: Variant) -> String:
	return Answer.log_name(b)


## b^n written as a power: "2⁵", "10²".
static func PW(b: Variant, n: int) -> String:
	return Answer.base_text(b) + Fmt.sup(n) if n != 1 else Answer.base_text(b) + "¹"


## The log function g(x) = log_b(x − h) + c as written.
static func log_fn(s: Dictionary, name: String = "g") -> String:
	return "%s(x) = %s" % [name, Answer.fn_text("log", s.b, s.h, s.c)]


static func exp_fn(s: Dictionary, name: String = "f") -> String:
	return "%s(x) = %s" % [name, Answer.fn_text("exp", s.b, s.h, s.c)]


static func fn_answer(name: String, shape: String, b: Variant, p: Variant, q: Variant) -> Dictionary:
	var ans := Answer.make("fn", {"form": shape, "p": Q.of(p), "q": Q.of(q)} if shape != "exphalf" else {"form": shape, "q": Q.of(q)},
		{"name": name, "shape": shape, "b": b})
	ans.exact = true
	return ans


## A wrong fn option in another form (or the same form with other shifts).
static func fn_wrong(form: String, p: Variant, q: Variant) -> Dictionary:
	return {"form": form, "p": Q.of(p), "q": Q.of(q)} if form not in ["exphalf", "pm"] else {"form": form, "q": Q.of(q)}


static func exact_number(label: String, v: Variant, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": Q.of(v)}, {}, label, unit)
	ans.exact = true
	return ans


## A Paper 2 answer: a number written to 3 s.f.
static func sf_number(label: String, x: float) -> Dictionary:
	var ans := Answer.make("number", {"v": TriangleViews.qf(x)}, {}, label)
	ans.show = "sf"
	return ans


## A wrong Paper 2 value (as an option), kept only when it is a real number.
static func sf_wrong(out: Dictionary, x: float, ref: String = "") -> void:
	if is_finite(x) and x != 0.0 and absf(x) < 1e6:
		if ref == "":
			out.fillers.append({"v": TriangleViews.qf(x)})
		else:
			out.wrongs.append(wrong({"v": TriangleViews.qf(x)}, ref))


## Working figures on a GDC: six significant figures.
static func W(x: float) -> String:
	return Fmt.sf(x, 6)


static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func lg(b: int, x: float) -> float:
	return log(x) / log(float(b))


static func ipow(b: int, n: int) -> int:
	var out := 1
	for i in n:
		out *= b
	return out


## "x − 3 = 8" style: the inside of the log at x.
static func inside(s: Dictionary, x: Variant) -> String:
	var h: int = s.h
	if h == 0:
		return "x = %s" % N(x)
	return "%s %s %d = %s" % [N(x), "−" if h > 0 else "+", absi(h), N(Q.of(x).sub(Q.new(h)))]


static func log_table(s: Dictionary, hide: int) -> Dictionary:
	var b: int = s.b
	var h: int = s.h
	var c: int = s.c
	var xs: Array = []
	var ys: Array = []
	for n in s.ns:
		xs.append(N(h + ipow(b, n)))
		ys.append("?" if n == hide else N(n + c))
	return {"rows": [["x", xs], ["g(x)", ys]]}


## log_b(x − h) as written: "log₂(x − 5)", or "log₂ x" when h = 0.
static func log_in(b: int, h: int) -> String:
	return "%s x" % LG(b) if h == 0 else "%s(%s)" % [LG(b), Answer.x_minus(h)]


static func c_step(c: int) -> String:
	return "" if c == 0 else " %s %d" % ["+" if c > 0 else "−", absi(c)]


## "add 4" / "subtract 4" ("adds" / "subtracts" with third) for adding k, or "" for 0.
static func add_k(k: int, third: bool = false) -> String:
	if k == 0:
		return ""
	if k > 0:
		return ("adds %d" if third else "add %d") % k
	return ("subtracts %d" if third else "subtract %d") % -k


## Steps in order, the empty (zero) ones left out: "a, b, then c".
static func op_list(parts: Array) -> String:
	var ps := parts.filter(func(p): return p != "")
	if ps.size() == 1:
		return ps[0]
	return ", ".join(ps.slice(0, ps.size() - 1)) + ", then " + ps[-1]


## A bracket to a rational power: "(3^(log₃ x))²", "(…)^(1/2)" (#193).
static func RAISE(inner: String, n: Q) -> String:
	return "(%s)%s" % [inner, Fmt.sup(n.n)] if n.is_int() and n.n > 1 else "(%s)^(%s)" % [inner, N(n)]


## x to a rational power: "x²", "x^(1/2)".
static func XP(n: Q) -> String:
	return "x" + Fmt.sup(n.n) if n.is_int() and n.n > 1 else "x^(%s)" % N(n)


## b^e as an exact number, for a whole e of either sign.
static func qpow(b: int, e: int) -> Q:
	return Q.new(ipow(b, e)) if e >= 0 else Q.new(1, ipow(b, -e))


## "k log 3", with the coefficient 1 left out.
static func k_log(k: int, logn: String, p: int) -> String:
	return "%s %d" % [logn, p] if k == 1 else "%d %s %d" % [k, logn, p]


# ── fn-exp-log-inverse-composite ─────────────────────────────

func u_evaluate_log_function(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	if s.get("paper", 1) == 2:
		return p2_evaluate_log_function(s)
	var b: int = s.b
	var h: int = s.h
	var c: int = s.c
	var n: int = s.n
	var x := h + ipow(b, n)
	var ans := exact_number(M("g(%d) = " % x), n + c)
	var out := {"answer": ans, "lines": [log_fn(s) + ", for x > %d" % h], "wrongs": [], "fillers": []}
	if rep == "table":
		out.asked = "The table shows values of g. Find the missing value, g(%d)." % x
		out.table = log_table(s, n)
	else:
		out.asked = "Find g(%d)." % x
	var divided := Q.new(ipow(b, n), b).add(Q.new(c))
	out.wrongs.append(wrong({"v": divided}, "SL1.5.exp-log-form#0"))
	out.wrongs.append(wrong({"v": Q.new(n)}, NO_C))
	out.fillers = [{"v": Q.new(ipow(b, n) + c)}, {"v": Q.new(n - c)}, {"v": Q.new(n + c + 1)}]
	var final := "So " + Answer.text(ans) + "."
	out.methods = {"what-power": {"result": ans.values, "steps": [
		"The inside is %s, and %s = %d: the power of %d that gives %d is %d." % [inside(s, x), PW(b, n), ipow(b, n), b, ipow(b, n), n],
		"So %s %d = %d, and g(%d) = %s." % [LG(b), ipow(b, n), n, x, Fmt.equals("%d%s" % [n, c_step(c)], str(n + c))], final]}}
	return out


func u_log_of_non_positive(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var h: int = s.h
	var c: int = s.c
	var x0: int = s.x0
	var wrong_zero := M("g(%d) = %d" % [x0, c])
	var opts := [NOT_DEFINED, wrong_zero, M("g(%d) = %d" % [x0, c - 1]), M("g(%d) = %d" % [x0, c + 1])]
	var ans := Answer.make("choice", {"v": NOT_DEFINED}, {"options": opts})
	var final := "So it is " + NOT_DEFINED + "."
	return {
		"asked": "Find g(%d), or say why it does not exist." % x0, "lines": [log_fn(s)], "answer": ans,
		"wrongs": [wrong({"v": wrong_zero}, "SL1.5.exp-log-form#2")],
		"fillers": [{"v": opts[2]}, {"v": opts[3]}],
		"methods": {"what-power": {"result": ans.values, "steps": [
			"The inside is %s." % inside(s, x0),
			"No power of %d is %d: %d^y is positive for every y." % [b, x0 - h, b], final]}},
	}


func u_inverse_of_exponential(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var h: int = s.h
	var c: int = s.c
	var ans := fn_answer("f⁻¹(x)", "log", b, c, h)
	var final := "So " + Answer.text(ans) + "."
	var bb := str(b)
	var yh := Answer.x_minus(h).replace("x", "y")
	var xc := Answer.x_minus(c)
	return {
		"asked": "Find f⁻¹(x).", "lines": [exp_fn(s)], "answer": ans,
		"titles": {"take-logs": "Take %s of both sides" % LG(b)},
		"wrongs": [wrong(fn_wrong("recip", h, c), "SL2.5.find-inverse#0"), wrong(fn_wrong("log", h, c), KEEP_SHIFTS),
			wrong(fn_wrong("log", -c, -h), SHIFT_SIGNS)],
		"fillers": [fn_wrong("exp", c, h), fn_wrong("log", c, -h)],
		"methods": {
			"swap-then-solve": {"result": ans.values, "steps": [
				"Swap x and y: x = %s^(%s)%s" % [bb, yh, Answer.plus_q(c)],
				"%s = %s^(%s), so %s = %s(%s)" % [xc, bb, yh, yh, LG(b), xc], final]},
			"reverse-operations": {"result": ans.values, "steps": [
				"f takes x, %s." % op_list([add_k(-h, true), "raises %d to that power" % b, add_k(c, true)]),
				"Undo them in reverse order: %s." % op_list([add_k(-c), "take " + LG(b), add_k(h)]), final]},
			"convert-form": {"result": ans.values, "steps": [
				"y%s = %s^(%s) is the same statement as %s = %s(y%s)." % [Answer.plus_q(-c), bb, Answer.x_minus(h), Answer.x_minus(h), LG(b), Answer.plus_q(-c)],
				"So x = %s(y%s)%s; swap x and y." % [LG(b), Answer.plus_q(-c), Answer.plus_q(h)], final]},
			"take-logs": {"result": ans.values, "steps": [
				"y%s = %s^(%s). Take %s of both sides: %s(y%s) = %s" % [Answer.plus_q(-c), bb, Answer.x_minus(h), LG(b), LG(b), Answer.plus_q(-c), Answer.x_minus(h)],
				"x = %s(y%s)%s; swap x and y." % [LG(b), Answer.plus_q(-c), Answer.plus_q(h)], final]},
		},
	}


func u_inverse_of_log(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var h: int = s.h
	var c: int = s.c
	var ans := fn_answer("g⁻¹(x)", "exp", b, c, h)
	var final := "So " + Answer.text(ans) + "."
	var bb := str(b)
	return {
		"asked": "Find g⁻¹(x).", "lines": [log_fn(s) + ", for x > %d" % h], "answer": ans,
		"wrongs": [wrong(fn_wrong("exp", -h, -c), "SL2.5.find-inverse#1"), wrong(fn_wrong("pow", c, h), "SL1.5.exp-log-form#1"),
			wrong(fn_wrong("exp", h, c), KEEP_SHIFTS)],
		"fillers": [fn_wrong("log", c, h), fn_wrong("exp", c, -h)],
		"methods": {
			"swap-then-solve": {"result": ans.values, "steps": [
				"Swap x and y: x = %s%s" % [log_in(b, h).replace("x", "y"), Answer.plus_q(c)],
				"%s = %s, so %s = %s^(%s)" % [Answer.x_minus(c), log_in(b, h).replace("x", "y"), Answer.x_minus(h).replace("x", "y"), bb, Answer.x_minus(c)],
				final]},
			"reverse-operations": {"result": ans.values, "steps": [
				"g %s." % op_list([add_k(-h, true), "takes " + LG(b), add_k(c, true)]),
				"Undo them in reverse order: %s." % op_list([add_k(-c), "raise %d to that power" % b, add_k(h)]), final]},
			"rewrite-exponential": {"result": ans.values, "steps": [
				"y%s = %s means %s^(y%s) = %s." % [Answer.plus_q(-c), log_in(b, h), bb, Answer.plus_q(-c), Answer.x_minus(h)],
				"So x = %s^(y%s)%s; swap x and y." % [bb, Answer.plus_q(-c), Answer.plus_q(h)], final]},
		},
	}


func u_evaluate_inverse(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	if s.get("paper", 1) == 2:
		return p2_evaluate_inverse(s)
	var b: int = s.b
	var h: int = s.h
	var c: int = s.c
	var m: int = s.m
	var a: int = s.a
	var x := ipow(b, m) + h
	var ans := exact_number(M("g⁻¹(%d) = " % a), x)
	var out := {"answer": ans, "lines": [log_fn(s) + ", for x > %d" % h], "wrongs": [], "fillers": []}
	if rep == "table":
		out.asked = "The table shows values of g. Find g⁻¹(%d)." % a
		out.table = log_table(s, -1)
	else:
		out.asked = "Find g⁻¹(%d)." % a
	out.wrongs.append(wrong({"v": Q.new(ipow(m, b) + h)}, "SL2.9.exp-log-inverse#1"))
	out.wrongs.append(wrong({"v": Q.new(ipow(b, m))}, NO_H))
	out.fillers = [{"v": Q.new(m + h)}, {"v": Q.new(ipow(b, m) - h)}, {"v": Q.new(ipow(b, m + 1) + h)}]
	var final := "So " + Answer.text(ans) + "."
	# Subtracting or adding 0 is no sum to show.
	var chain := ["%s = %d" % [PW(b, m), ipow(b, m)]]
	if c != 0:
		chain.push_front("%d%s = %d" % [a, c_step(-c), m])
	if h != 0:
		chain.append("%d%s = %d" % [ipow(b, m), c_step(h), x])
	out.methods = {
		"reverse-operations": {"result": ans.values, "steps": [
			"g⁻¹ undoes g: %s." % op_list([add_k(-c), "raise %d to that power" % b, add_k(h)]),
			", ".join(chain), final]},
		"convert-form": {"result": ans.values, "steps": [
			"g⁻¹(%d) is the x with g(x) = %d: %s = %d" % [a, a, log_in(b, h), m],
			"In exponential form: %s = %s = %d%s" % [Answer.x_minus(h), PW(b, m), ipow(b, m), ", so x = %d" % x if h != 0 else ""], final]},
		# Found from g(x) = a, not assumed: the check comes after.
		"inverse-identities": {"result": ans.values, "steps": [
			"g⁻¹(%d) is the x with g(x) = %d: %s = %s" % [a, a, log_in(b, h), Fmt.equals("%d%s" % [a, c_step(-c)], str(m))],
			"Raise %d to both sides, as %d^(%s A) = A with A = %s: %s = %s = %d%s. Check: g(%d) = %s %d%s = %s." % [b, b, LG(b), Answer.x_minus(h), Answer.x_minus(h), PW(b, m), ipow(b, m),
				", so x = %d" % x if h != 0 else "", x, LG(b), ipow(b, m), c_step(c), Fmt.equals("%d%s" % [m, c_step(c)], str(a))], final]},
	}
	return out


func u_inverse_awkward_base(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var i: int = s.i
	var k: int = s.k
	var b1: int = s.b1
	var v := ipow(p, k)
	var ans := exact_number("f⁻¹(%d) = " % v, Q.new(k, i))
	var final := "So " + Answer.text(ans) + "."
	var dec := String.num(float(k) / i, 4)
	return {
		"asked": "Find f⁻¹(%d), as a fraction." % v, "lines": ["f(x) = %d^x" % b1], "answer": ans,
		"wrongs": [wrong({"v": Q.new(i, k)}, "SL1.7.change-of-base#0"), wrong({"v": Q.new(v, b1)}, "SL1.5.exp-log-form#0"),
			wrong({"v": Q.new(k)}, BASE_POWER)],
		"fillers": [{"v": Q.new(k * i)}, {"v": Q.new(k + 1, i)}],
		"methods": {
			"change-of-base": {"result": ans.values, "steps": [
				"f⁻¹(%d) = %s %d, the power of %d that gives %d." % [v, LG(b1), v, b1, v],
				"%s %d = ln %d / ln %d = (%s)/(%s)" % [LG(b1), v, v, b1, k_log(k, "ln", p), k_log(i, "ln", p)], final]},
			"what-power": {"result": ans.values, "steps": [
				"Ask: %d to what power gives %d?" % [b1, v],
				"%d = %s and %d = %s, so %s = %d." % [b1, PW(p, i), v, PW(p, k), QP(b1, Q.new(k, i)), v], final]},
			"common-base-power": {"result": ans.values, "steps": [
				"Write both as powers of %d: (%s)^y = %s" % [p, PW(p, i), PW(p, k)],
				"%dy = %d" % [i, k], final]},
			"cob-formula": {"result": ans.values, "steps": [
				"%s %d = log %d / log %d = log %s / log %s" % [LG(b1), v, v, b1, PW(p, k) if k != 1 else str(p), PW(p, i)],
				"= (%s)/(%s)" % [k_log(k, "log", p), k_log(i, "log", p)], final]},
			"gdc-logbase": {"result": ans.values, "steps": [
				"The GDC's log-base template gives %s %d = %s." % [LG(b1), v, dec],
				"As a fraction that is %s, but Paper 1 needs it worked out: %d = %s, %d = %s." % [N(Q.new(k, i)), b1, PW(p, i), v, PW(p, k)], final]},
		},
	}


func u_simplify_composite(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var i: int = s.i
	var j: int = s.j
	var b1: int = s.b1
	var b2: int = s.b2
	var n := Q.new(i, j)
	var ans := Answer.make("xpow", {"n": n}, {"name": "f(g(x))"})
	ans.exact = true
	var final := "So " + Answer.text(ans) + "."
	var out := {
		"asked": "Find f(g(x)), in its simplest form.", "lines": ["f(x) = %d^x" % b1, "g(x) = %s x, for x > 0" % LG(b2)],
		"answer": ans, "wrongs": [wrong({"n": n, "form": "lin"}, "SL2.5.composite-expression#0"), wrong({"n": Q.new(j, i)}, "SL1.7.change-of-base#0")],
		"fillers": [{"n": Q.new(b1, b2)}, {"n": Q.new(i * j)}],
	}
	if j > 1:
		out.wrongs.append(wrong({"n": Q.new(i, b2)}, "SL1.7.change-of-base#2"))
	out.methods = {
		"inverse-identities": {"result": ans.values, "steps": [
			"f(g(x)) = %d^(%s x), and %d = %s." % [b1, LG(b2), b1, QP(b2, n)],
			"So f(g(x)) = %s, and %d^(%s x) = x, so it is %s." % [RAISE("%d^(%s x)" % [b2, LG(b2)], n), b2, LG(b2), XP(n)], final]},
		"substitute-whole": {"result": ans.values, "steps": [
			"Put g(x) in place of x in f: f(g(x)) = %d^(%s x)." % [b1, LG(b2)],
			"%d = %s, so this is %s = %s." % [b1, QP(b2, n), RAISE("%d^(%s x)" % [b2, LG(b2)], n), XP(n)], final]},
		# Derived first, then checked at x = b2², where g(x) = 2: that point separates
		# x^n (b1²) from the slip n·x (n·b2²), which x = b2 does not when n = 2.
		"numeric-check": {"result": ans.values, "steps": [
			"%d = %s, so f(g(x)) = %s = %s." % [b1, QP(b2, n), RAISE("%d^(%s x)" % [b2, LG(b2)], n), XP(n)],
			"Check at x = %d, where g(x) = 2: f(2) = %d² = %d, and %s at x = %d is %d too." % [b2 * b2, b1, b1 * b1, XP(n), b2 * b2, b1 * b1], final]},
		"common-base-power": {"result": ans.values, "steps": [
			"Both bases are powers of %d: %d = %s, %d = %s." % [p, b1, PW(p, i), b2, PW(p, j)],
			("%s x is already base %d, so f(g(x)) = %d^(%d %s x) = %s." % [LG(b2), p, p, i, LG(p), XP(n)]) if j == 1 else
				"%s x = (%s x)/%d, so f(g(x)) = %d^(%s %s x) = %s." % [LG(b2), LG(p), j, p, Fmt.paren(n) if not n.is_int() else N(n), LG(p), XP(n)], final]},
	}
	return out


## The answer to f(g(x)) rel d after the log becomes a power: x rel b^n with x > 0.
static func ineq_answer(rel: String, v: int) -> Dictionary:
	if rel in ["<", "≤"]:
		return Answer.make("range2", {"lo": Q.new(0), "r1": "<", "r2": rel, "hi": Q.new(v)}, {"var": "x"})
	return Answer.make("bound", {"rel": rel, "v": Q.new(v)}, {"var": "x"})


const FLIP := {"<": ">", ">": "<", "≤": "≥", "≥": "≤"}


func u_composite_inequality(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var b: int = s.b
	var n: int = s.n
	var d: int = s.d
	var rel: String = s.rel
	var r2: String = FLIP[rel] if p < 0 else rel
	var v := ipow(b, n)
	var ans := ineq_answer(r2, v)
	ans.exact = true
	var other_end: String = {"<": "≤", "≤": "<", ">": "≥", "≥": ">"}[r2]
	var gen: Array = []
	var wr: Array = []
	if ans.kind == "range2":
		wr = [wrong({"lo": Q.new(0), "r1": "<", "r2": r2, "hi": Q.new(n)}, LOG_LEFT),
			wrong({"lo": Q.new(0), "r1": "<", "r2": r2, "hi": Q.new(ipow(n, b))}, "SL2.9.exp-log-inverse#1")]
		gen = [{"lo": Q.new(0), "r1": "<", "r2": other_end, "hi": Q.new(v)}, {"lo": Q.new(0), "r1": "≤", "r2": r2, "hi": Q.new(v)}]
	else:
		wr = [wrong({"rel": r2, "v": Q.new(n)}, LOG_LEFT), wrong({"rel": r2, "v": Q.new(ipow(n, b))}, "SL2.9.exp-log-inverse#1")]
		gen = [{"rel": other_end, "v": Q.new(v)}, {"rel": r2, "v": Q.new(v * b)}]
	var final := "So " + Answer.text(ans) + "."
	var by := " (dividing by %d turns the inequality round)" % p if p < 0 else ""
	var tail := "and %s x needs x > 0" % LG(b) if ans.kind == "range2" else "which is inside the domain x > 0"
	return {
		"asked": "Solve f(g(x)) %s %d." % [rel, d], "lines": ["f(x) = %s" % Fmt.poly([p, q]), "g(x) = %s x, for x > 0" % LG(b)],
		"answer": ans, "wrongs": wr, "fillers": gen,
		"methods": {
			"convert-form": {"result": ans.values, "steps": [
				"f(g(x)) = %s %s %d" % [Fmt.poly([p, q]).replace("x", LG(b) + " x"), rel, d],
				"%s x %s %d%s" % [LG(b), r2, n, by],
				"As a power: x %s %s = %d, %s." % [r2, PW(b, n), v, tail], final]},
			"substitute-whole": {"result": ans.values, "steps": [
				"Replace x in f with %s x: %s %s %d" % [LG(b), Fmt.poly([p, q]).replace("x", LG(b) + " x"), rel, d],
				"%s x %s %d%s, so x %s %d" % [LG(b), r2, n, by, r2, v],
				"Keep the domain of %s x in mind: x > 0." % LG(b), final]},
		},
	}


func u_transformations_between(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var lines: Array = ["f(x) = %d^x" % b]
	var opts: Array = []
	var wrongs: Array = []
	var right := ""
	var asked := ""
	var methods := {}
	var g: Callable
	if s.mode == "shift":
		var p: int = s.p
		var q: int = s.q
		var gtext := Answer.fn_text("exp", b, -p, q)
		lines.append("g(x) = " + gtext)
		g = func(x: float) -> float: return pow(float(b), x + p) + q
		right = M("a translation by the vector (%d, %d)" % [-p, q])
		var w0 := M("a translation by the vector (%d, %d)" % [p, q])
		# Wrong vectors: the sign of the x move (describe#0), then the other usual slips,
		# the first three that differ from the answer and from each other.
		opts = [right]
		for v in [[p, q], [-p, -q], [q, -p], [p, -q], [-q, p], [-p, q + (1 if q >= 0 else -1)], [-p - 1, q]]:
			var o := M("a translation by the vector (%d, %d)" % v)
			if not o in opts and opts.size() < 4:
				opts.append(o)
		wrongs = [wrong({"v": w0}, "SL2.11.describe#0")]
		asked = "Describe the translation that maps the graph of y = f(x) onto the graph of y = g(x)."
		var steps := [
			"g(x) = f(x %s %d)%s: the x inside is %s." % ["+" if p > 0 else "−", absi(p), Answer.plus_q(q), "increased" if p > 0 else "decreased"],
			"f(x + a) moves the graph a to the left: %d %s, then %d %s." % [absi(p), "left" if p > 0 else "right", absi(q), "up" if q >= 0 else "down"]]
		methods["rewrite-in-f"] = {"result": {"v": right}, "steps": steps + ["So it is %s." % right]}
		methods["compare-key-points"] = {"result": {"v": right}, "steps": [
			"f passes through (0, 1) with asymptote y = 0.",
			"g passes through (%d, %d) with asymptote y = %d: each point moved by (%d, %d)." % [-p, 1 + q, q, -p, q], "So it is %s." % right]}
		methods["common-base-power"] = {"result": {"v": right}, "steps": [
			"g(x) = %d^(x %s %d)%s keeps the base %d, so no stretch is needed." % [b, "+" if p > 0 else "−", absi(p), Answer.plus_q(q), b],
			"Only x has moved, by %d, and y by %d." % [-p, q], "So it is %s." % right]}
	else:
		var j: int = s.j
		var bj := ipow(b, j)
		lines.append("g(x) = %d^x" % bj)
		g = func(x: float) -> float: return pow(float(bj), x)
		var sf := "1/%d" % j
		right = "a horizontal stretch, scale factor %s" % sf
		var w2 := "a stretch, scale factor %s" % sf
		opts = [right, w2, "a horizontal stretch, scale factor %d" % j, "a vertical stretch, scale factor %d" % j]
		wrongs = [wrong({"v": w2}, "SL2.11.describe#2"), wrong({"v": opts[2]}, SF_A)]
		asked = "Describe the stretch that maps the graph of y = f(x) onto the graph of y = g(x)."
		methods["common-base-power"] = {"result": {"v": right}, "steps": [
			"%d = %s, so g(x) = (%s)^x = %d^(%dx) = f(%dx)." % [bj, PW(b, j), PW(b, j), b, j, j],
			"f(%dx) squeezes the graph towards the y-axis: a horizontal stretch, scale factor 1/%d." % [j, j], "So it is %s." % right]}
		methods["rewrite-in-f"] = {"result": {"v": right}, "steps": [
			"g(x) = %d^(%dx) = f(%dx)." % [b, j, j], "y = f(ax) is a horizontal stretch with scale factor 1/a.", "So it is %s." % right]}
		methods["compare-key-points"] = {"result": {"v": right}, "steps": [
			"f(1) = %d, and g reaches %d at x = 1/%d." % [b, b, j],
			"Every point keeps its height and has its x divided by %d, and both graphs pass through (0, 1)." % j, "So it is %s." % right]}
	var ans := Answer.make("choice", {"v": right}, {"options": opts})
	var out := {"asked": asked, "lines": lines, "answer": ans, "wrongs": wrongs,
		"fillers": opts.slice(1).filter(func(o): return not wrongs.any(func(w): return w.values.v == o)).map(func(o): return {"v": o}), "methods": methods}
	if rep == "graph":
		var f := func(x: float) -> float: return pow(float(b), x)
		var lo := mini(0, s.get("q", 0)) - 2
		out.graph = Plot.spec([Plot.sample(f, -5.0, 5.0), Plot.sample(g, -5.0, 5.0)], [], -5, 5, lo, lo + 14,
			[[float(s.get("q", 0)), "y = %d" % s.get("q", 0)]] if s.get("q", 0) != 0 else [])
		out.lines = ["The graphs of y = f(x) and y = g(x) are shown."] + lines
	return out


func u_write_log_form(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var n: int = maxi(s.n, 2)
	var x := ipow(b, n)
	var ans := Answer.make("logform", {"b": Q.new(b), "x": Q.new(x), "y": Q.new(n)})
	ans.exact = true
	var final := "So " + Answer.text(ans) + "."
	return {
		"asked": "Write %s = %d in log form." % [PW(b, n), x], "lines": ["%s = %d" % [PW(b, n), x]], "answer": ans,
		"wrongs": [wrong({"b": Q.new(n), "x": Q.new(x), "y": Q.new(b)}, "SL1.5.exp-log-form#1"), wrong({"b": Q.new(x), "x": Q.new(b), "y": Q.new(n)}, SWAP_BASE),
			wrong({"b": Q.new(b), "x": Q.new(n), "y": Q.new(x)}, SWAP_POWER)],
		"fillers": [{"b": Q.new(b), "x": Q.new(x), "y": Q.new(n + 1)}],
		"methods": {
			"convert-form": {"result": ans.values, "steps": [
				"b^y = x says y is the power of b that gives x: log_b x = y.", "Here b = %d, y = %d and x = %d." % [b, n, x], final]},
			"rewrite-exponential": {"result": ans.values, "steps": [
				"log_b x = y means exactly b^y = x.", "%s = %d has b = %d, x = %d, y = %d." % [PW(b, n), x, b, x, n], final]},
		},
	}


func u_solve_exp_equation(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	if s.get("paper", 1) == 2:
		return p2_solve_exp_equation(s)
	var m: int = s.m
	var c: int = s.c
	var d: int = s.d
	var r: int = s.r
	var ans := Answer.make("lnq", {"m": Q.new(1, m), "r": Q.new(r)}, {}, "x = ")
	ans.exact = true
	var final := "So " + Answer.text(ans) + "."
	var eq := "e^(%dx)%s = %d" % [m, Answer.plus_q(c), d]
	var dec := String.num(log(float(r)) / m, 5)
	return {
		"asked": "Solve %s, giving the exact value of x." % eq, "lines": [eq], "answer": ans,
		"wrongs": [wrong({"m": Q.new(m), "r": Q.new(r)}, "SL2.9.exp-log-inverse#0"),
			wrong({"m": Q.new(m), "r": Q.new(r), "form": "sub"}, "SL2.9.exp-log-inverse#0"),
			wrong({"m": Q.new(m), "r": Q.new(r), "form": "dive"}, "SL2.9.exp-log-inverse#2")],
		"fillers": [{"m": Q.new(1, m), "r": Q.new(d)} if d > 0 else {"m": Q.new(-1, m), "r": Q.new(r)}, {"m": Q.new(-1, m), "r": Q.new(r)}, {"m": Q.new(1), "r": Q.new(r)}],
		"methods": {
			"take-logs": {"result": ans.values, "steps": ["e^(%dx) = %d" % [m, r], "Take ln of both sides: %dx = ln %d" % [m, r], final]},
			"change-of-base": {"result": ans.values, "steps": ["e^(%dx) = %d, so %dx = logₑ %d = ln %d" % [m, r, m, r, r], "x = (ln %d)/%d" % [r, m], final]},
			"gdc-intersect": {"result": ans.values, "steps": [
				"Graph y = e^(%dx)%s and y = %d: they meet at x = %s." % [m, Answer.plus_q(c), d, dec],
				"The exact value is asked for: e^(%dx) = %d gives %dx = ln %d." % [m, r, m, r], final]},
			"apply-inverse": {"result": ans.values, "steps": [
				"%s: e^(%dx) = %d" % ["Subtract %d" % c if c > 0 else ("Add %d" % -c if c < 0 else "Already alone"), m, r],
				"Apply ln, the inverse of e^x: %dx = ln %d, then divide by %d." % [m, r, m], final]},
		},
	}


func u_solve_log_equation(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	if s.get("paper", 1) == 2:
		return p2_solve_log_equation(s)
	var b: int = s.b
	var h: int = s.h
	var c: int = s.c
	var m: int = s.m
	var d: int = s.d
	var x := ipow(b, m) + h
	var ans := exact_number("x = ", x)
	var final := "So " + Answer.text(ans) + "."
	var eq := "%s(%s)%s = %d" % [LG(b), Answer.x_minus(h), Answer.plus_q(c), d]
	return {
		"asked": "Solve %s." % eq, "lines": [eq], "answer": ans,
		# b^d + h is the slip only for d ≥ 0: ipow takes a negative power as 1.
		"wrongs": [wrong({"v": Q.new(ipow(m, b) + h)}, "SL2.9.exp-log-inverse#1")] + ([wrong({"v": Q.new(ipow(b, d) + h)}, C_FIRST)] if d >= 0 else [])
			+ [wrong({"v": Q.new(ipow(b, m))}, NO_H)],
		"fillers": [{"v": Q.new(ipow(b, m) - h)}] + ([] if d >= 0 else [{"v": Q.new(ipow(b, d) + h)}]) + [{"v": Q.new(m + h)}],
		"methods": {
			"convert-form": {"result": ans.values, "steps": [
				"%s = %d" % [log_in(b, h), m], "In exponential form: %s = %s = %d" % [Answer.x_minus(h), PW(b, m), ipow(b, m)], final]},
			"rewrite-exponential": {"result": ans.values, "steps": [
				"log_b A = m means b^m = A: here %s = %s." % [Answer.x_minus(h), PW(b, m)], "x = " + Fmt.equals("%d%s" % [ipow(b, m), c_step(h)], str(x)), final]},
			"apply-inverse": {"result": ans.values, "steps": [
				"%s%s = %d" % ["" if c == 0 else ("Subtract %d: " % c if c > 0 else "Add %d: " % -c), log_in(b, h), m],
				"Raise %d to each side: %s = %d" % [b, Answer.x_minus(h), ipow(b, m)], final]},
		},
	}


func u_composite_order(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var p: int = s.p
	var eq: bool = s.equal
	var lines: Array = ["f(x) = %d^x" % b]
	var fg := ""
	var gf := ""
	var opts: Array = []
	var wrongs: Array = []
	if eq:
		lines.append("g(x) = %s x, for x > 0" % LG(b))
		fg = "x"
		gf = "x"
	else:
		lines.append("g(x) = " + Fmt.poly([1, p]))
		fg = Answer.fn_text("exp", b, -p, 0)
		gf = "%d^x%s" % [b, Answer.plus_q(p)]
	var say := func(a: String, c: String, same: bool) -> String: return "f(g(x)) = %s, g(f(x)) = %s: %s" % [a, c, "equal" if same else "not equal"]
	var right: String = say.call(fg, gf, eq)
	if eq:
		opts = [right, say.call(fg, gf, false), say.call("%s x" % LG(b), "%d^x" % b, false), say.call("%d^x" % b, "%s x" % LG(b), false)]
	else:
		var w: String = say.call(fg, gf, true)
		opts = [right, w, say.call(gf, fg, false), say.call(fg, fg, true)]
		# The two the wrong way round (g(f(x)) for f(g(x))), and one composite taken for both.
		wrongs = [wrong({"v": w}, "SL2.5.composite-expression#2"), wrong({"v": opts[2]}, "SL2.5.composite-expression#0"),
			wrong({"v": opts[3]}, "SL2.5.composite-expression#2")]
	var ans := Answer.make("choice", {"v": right}, {"options": opts})
	var final := "So " + Answer.text(ans) + "."
	# The check point: x = 1, or the first of 2, 3 where the two differ (b = 2, p = −1
	# gives 1 at x = 1 both ways).
	var test := b
	if not eq:
		for t in [1, 2, 3]:
			test = t
			if not qpow(b, t + p).eq(Q.new(ipow(b, t) + p)):
				break
	var check := ""
	if eq:
		check = "Check at x = %d: f(g(%d)) = %d^(%s %d) = %d and g(f(%d)) = %s %s = %d, the same." % [test, test, b, LG(b), test, test, test, LG(b), PW(b, test), test]
	else:
		var fg_at := str(b) if test + p == 1 else "%d^(%d)" % [b, test + p] if test + p <= 0 else PW(b, test + p)
		var gf_at := (str(b) if test == 1 else PW(b, test)) + Answer.plus_q(p)
		check = "Check at x = %d: f(g(%d)) = %s and g(f(%d)) = %s, which differ." % [test, test,
			Fmt.equals(fg_at, N(qpow(b, test + p))), test, Fmt.equals(gf_at, N(Q.new(ipow(b, test) + p)))]
	var put_g := "f(g(x)) = f(%s x) = %d^(%s x) = x" % [LG(b), b, LG(b)] if eq else "f(g(x)) = f(%s) = %s" % [Fmt.poly([1, p]), fg]
	var put_f := "g(f(x)) = g(%d^x) = %s(%d^x) = x" % [b, LG(b), b] if eq else "g(f(x)) = g(%d^x) = %s" % [b, gf]
	return {
		"asked": "Find f(g(x)) and g(f(x)). Are they equal?", "lines": lines, "answer": ans, "wrongs": wrongs,
		"fillers": opts.slice(1).filter(func(o): return not wrongs.any(func(w): return w.values.v == o)).map(func(o): return {"v": o}),
		"methods": {
			"substitute-whole": {"result": ans.values, "steps": [
				"f(g(x)): put g(x) into f, giving %s." % fg, "g(f(x)): put f(x) into g, giving %s." % gf, final]},
			"numeric-check": {"result": ans.values, "steps": [
				"Work out each: %s, and %s." % [put_g, put_f], check, final]},
		},
	}


func u_inverse_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var h: int = s.h
	var c: int = s.c
	var y0 := ipow(b, -h) + c
	var ans := Answer.make("named", {"v0": Q.new(c), "v1": Q.new(y0)}, {"names": ["asymptote: x", "x-intercept: x"]})
	ans.exact = true
	var f := func(x: float) -> float: return ExpLogPairSituation.exp_at(s, x)
	var final := "So " + Answer.text(ans) + "."
	return {
		"asked": "The graph of y = f(x) is shown. Find the vertical asymptote and the x-intercept of y = f⁻¹(x).",
		"lines": [exp_fn(s)], "answer": ans,
		"graph": Plot.spec([Plot.sample(f, -6.0, 6.0)], [[0, y0, Fmt.point(0, y0)]], -6, 6, mini(c, 0) - 3, mini(c, 0) + 11,
			[[float(c), "y = %d" % c]]),
		"fillers": [{"v0": Q.new(h), "v1": Q.new(y0)}, {"v0": Q.new(c), "v1": Q.new(h)}, {"v0": Q.new(y0), "v1": Q.new(c)},
			{"v0": Q.new(-c), "v1": Q.new(y0)}],
		"methods": {
			"graph-check": {"result": ans.values, "steps": [
				"Reflect the graph in y = x: the asymptote y = %d becomes x = %d." % [c, c],
				("f crosses the y-axis at (0, %d), so f⁻¹ crosses the x-axis at (%d, 0)." % [y0, y0]) if y0 != 0
					else "f passes through the origin, so f⁻¹ does too: its x-intercept is x = 0.", final]},
			"compare-key-points": {"result": ans.values, "steps": [
				"f has asymptote y = %d and passes through (0, %d)." % [c, y0],
				"The inverse swaps x and y: asymptote x = %d, through (%d, 0)." % [c, y0], final]},
		},
	}


func u_inverse_log_of_square(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var h: int = s.h
	var ans := fn_answer("g⁻¹(x)", "exphalf", b, 0, h)
	var final := "So " + Answer.text(ans) + "."
	var sq := "(%s)²" % Answer.x_minus(h) if h != 0 else "x²"
	return {
		"asked": "Find g⁻¹(x).", "lines": ["g(x) = %s(%s), for x > %d" % [LG(b), sq, h]], "answer": ans,
		"wrongs": [wrong(fn_wrong("pm", 0, h), "SL2.5.find-inverse#2"), wrong(fn_wrong("exp", 0, h), NO_ROOT)],
		"fillers": [fn_wrong("exphalf", 0, -h), fn_wrong("pm", 0, -h)],
		"methods": {"swap-then-solve": {"result": ans.values, "steps": [
			"Swap x and y: x = %s(%s), so %s = %d^x." % [LG(b), sq.replace("x", "y"), sq.replace("x", "y"), b],
			"%s = ±%d^(x/2). g's domain is x > %d, so g⁻¹'s range is y > %d: take +." % [Answer.x_minus(h).replace("x", "y"), b, h, h],
			final]}},
	}


func u_function_from_inverse(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var h: int = s.h
	var c: int = s.c
	var ans := fn_answer("f(x)", "exp", b, c, h)
	var final := "So " + Answer.text(ans) + "."
	return {
		"asked": "Find f(x).", "lines": ["f⁻¹(x) = %s" % Answer.fn_text("log", b, h, c)], "answer": ans,
		"wrongs": [wrong(fn_wrong("exp", h, c), KEEP_SHIFTS), wrong(fn_wrong("exp", -c, -h), SHIFT_SIGNS), wrong(fn_wrong("pow", c, h), "SL1.5.exp-log-form#1")],
		"fillers": [fn_wrong("log", c, h)],
		"methods": {
			"swap-then-solve": {"result": ans.values, "steps": [
				"f is the inverse of f⁻¹. Swap x and y in y = %s: x = %s" % [Answer.fn_text("log", b, h, c), Answer.fn_text("log", b, h, c).replace("x", "y")],
				"%s = %s, so y = %d^(%s)%s" % [Answer.x_minus(c), log_in(b, h).replace("x", "y"), b, Answer.x_minus(c), Answer.plus_q(h)], final]},
			"rewrite-exponential": {"result": ans.values, "steps": [
				"y = f⁻¹(x) means x = f(y): y%s = %s." % [Answer.plus_q(-c), log_in(b, h)],
				"In exponential form: %s = %d^(y%s), so f(x) = %d^(%s)%s" % [Answer.x_minus(h), b, Answer.plus_q(-c), b, Answer.x_minus(c), Answer.plus_q(h)], final]},
		},
	}


# ── Paper 2 (FAL-419) ────────────────────────────────────────
# The same functions at numbers that need a calculator: each answer to 3 s.f.

const SF := ", correct to 3 significant figures"


## g(xe) = log_b(xe − h) + c, where xe − h is not a power of b.
func p2_evaluate_log_function(s: Dictionary) -> Dictionary:
	var b: int = s.b
	var h: int = s.h
	var c: int = s.c
	var x: int = s.xe
	var k := x - h
	var lk := lg(b, k)
	var val := lk + c
	var ans := sf_number(M("g(%d) = " % x), val)
	var out := {"answer": ans, "lines": [log_fn(s) + ", for x > %d" % h], "wrongs": [], "fillers": [],
		"asked": "Find g(%d)%s." % [x, SF]}
	sf_wrong(out, float(k) / b + c, "SL1.5.exp-log-form#0")
	sf_wrong(out, lk, NO_C)
	# The log of x itself and ln for log_b are slips too, but the rounding trap and the two
	# above fill every slot, so they never show.
	for w in [lg(b, x) + c if x > 0 else NAN, log(float(k)) + c, val + 1.0]:
		sf_wrong(out, w)
	var lo := 0
	while ipow(b, lo + 1) < k:
		lo += 1
	out.methods = {"what-power": {"result": ans.values, "steps": [
		"The inside is %s, and %s < %d < %s: no whole power of %d gives %d." % [inside(s, x), PW(b, lo), k, PW(b, lo + 1), b, k],
		"With a GDC: %s %d = ln %d / ln %d = %s" % [LG(b), k, k, b, W(lk)],
		"g(%d) = %s" % [x, Fmt.equals(W(lk) + c_step(c), W(val))], "So " + Answer.text(ans) + "."]}}
	return out


## g⁻¹(at) = b^t + h, with t in tenths.
func p2_evaluate_inverse(s: Dictionary) -> Dictionary:
	var b: int = s.b
	var h: int = s.h
	var c: int = s.c
	var t: Q = s.t
	var a: Q = s.at
	var bt := pow(float(b), t.to_float())
	var x := bt + h
	var ans := sf_number(M("g⁻¹(%s) = " % D(a)), x)
	var out := {"answer": ans, "lines": [log_fn(s) + ", for x > %d" % h], "wrongs": [], "fillers": [],
		"asked": "Find g⁻¹(%s)%s." % [D(a), SF]}
	sf_wrong(out, pow(t.to_float(), b) + h, "SL2.9.exp-log-inverse#1")
	sf_wrong(out, bt, NO_H)
	# b^a + h and g at the value are slips too, but the rounding trap and the two above fill
	# every slot, so they never show.
	for w in [pow(float(b), a.to_float()) + h, bt - h, lg(b, a.to_float() - h) + c if a.to_float() > h else NAN]:
		sf_wrong(out, w)
	var final := "So " + Answer.text(ans) + "."
	var pw := "%d^(%s)" % [b, D(t)]
	var add_h: Array = ["%s%s = %s" % [W(bt), c_step(h), W(x)]] if h != 0 else []
	out.methods = {
		"reverse-operations": {"result": ans.values, "steps": [
			"g⁻¹ undoes g: %s." % op_list([add_k(-c), "raise %d to that power" % b, add_k(h)]),
			("%s%s = %s, and with a GDC %s = %s" % [D(a), c_step(-c), D(t), pw, W(bt)]) if c != 0 else "With a GDC %s = %s" % [pw, W(bt)]] + add_h + [final]},
		"convert-form": {"result": ans.values, "steps": [
			"g⁻¹(%s) is the x with g(x) = %s: %s = %s" % [D(a), D(a), log_in(b, h), D(t)],
			"In exponential form: %s = %s = %s (GDC)" % [Answer.x_minus(h), pw, W(bt)],
			"x = " + Fmt.equals(W(bt) + c_step(h), W(x)), final]},
		"inverse-identities": {"result": ans.values, "steps": [
			"Let x = g⁻¹(%s), so g(x) = %s: %s = %s" % [D(a), D(a), log_in(b, h), Fmt.equals(D(a) + c_step(-c), D(t))],
			"%d^(%s A) = A with A = %s, so %s = %s; with a GDC that is %s." % [b, LG(b), Answer.x_minus(h), Answer.x_minus(h), pw, W(bt)],
			"x = %s" % W(x), final]},
	}
	return out


## e^(mx) + c = d, with x = (ln r)/m to 3 s.f.
func p2_solve_exp_equation(s: Dictionary) -> Dictionary:
	var m: int = s.m
	var c: int = s.c
	var d: int = s.d
	var r: int = s.r
	var lr := log(float(r))
	var x := lr / m
	var ans := sf_number("x = ", x)
	var eq := "e^(%dx)%s = %d" % [m, Answer.plus_q(c), d]
	var out := {"answer": ans, "lines": [eq], "wrongs": [], "fillers": [], "asked": "Solve %s, giving x%s." % [eq, SF]}
	# The trap takes one of the three wrong options, so the two misconceptions go first.
	sf_wrong(out, m * lr, "SL2.9.exp-log-inverse#0")
	sf_wrong(out, r / (m * exp(1.0)), "SL2.9.exp-log-inverse#2")
	sf_wrong(out, lr - m, "SL2.9.exp-log-inverse#0")
	for w in [log(float(d)) / m if d > 0 else NAN, -x, lr, x + 1.0]:
		sf_wrong(out, w)
	var final := "So " + Answer.text(ans) + "."
	var alone := "Subtract %d" % c if c > 0 else ("Add %d" % -c if c < 0 else "Already alone")
	out.methods = {
		"take-logs": {"result": ans.values, "steps": ["e^(%dx) = %d" % [m, r], "Take ln of both sides: %dx = ln %d" % [m, r],
			"With a GDC: x = (ln %d)/%d = %s" % [r, m, W(x)], final]},
		"change-of-base": {"result": ans.values, "steps": ["e^(%dx) = %d, so %dx = logₑ %d = ln %d" % [m, r, m, r, r],
			"x = (ln %d)/%d = %s on a GDC" % [r, m, W(x)], final]},
		"gdc-intersect": {"result": ans.values, "steps": [
			"Graph y = e^(%dx)%s and y = %d on a GDC." % [m, Answer.plus_q(c), d],
			"The intersection tool gives x = %s." % W(x), final]},
		"apply-inverse": {"result": ans.values, "steps": ["%s: e^(%dx) = %d" % [alone, m, r],
			"Apply ln, the inverse of e^x: %dx = ln %d, then divide by %d." % [m, r, m], "With a GDC: x = %s" % W(x), final]},
	}
	return out


## log_b(x − h) + c = at, so x = b^t + h.
func p2_solve_log_equation(s: Dictionary) -> Dictionary:
	var b: int = s.b
	var h: int = s.h
	var c: int = s.c
	var t: Q = s.t
	var a: Q = s.at
	var bt := pow(float(b), t.to_float())
	var x := bt + h
	var ans := sf_number("x = ", x)
	var eq := "%s(%s)%s = %s" % [LG(b), Answer.x_minus(h), Answer.plus_q(c), D(a)]
	var out := {"answer": ans, "lines": [eq], "wrongs": [], "fillers": [], "asked": "Solve %s, giving x%s." % [eq, SF]}
	sf_wrong(out, pow(t.to_float(), b) + h, "SL2.9.exp-log-inverse#1")
	sf_wrong(out, pow(float(b), a.to_float()) + h, C_FIRST)
	sf_wrong(out, bt, NO_H)
	for w in [bt - h, x + 1.0]:
		sf_wrong(out, w)
	var final := "So " + Answer.text(ans) + "."
	var pw := "%d^(%s)" % [b, D(t)]
	out.methods = {
		"convert-form": {"result": ans.values, "steps": [
			"%s = %s" % [log_in(b, h), D(t)],
			"In exponential form: %s = %s = %s (GDC)" % [Answer.x_minus(h), pw, W(bt)], final]},
		"rewrite-exponential": {"result": ans.values, "steps": [
			"log_b A = m means b^m = A: here %s = %s." % [Answer.x_minus(h), pw],
			"With a GDC: x = " + Fmt.equals(W(bt) + c_step(h), W(x)), final]},
		"apply-inverse": {"result": ans.values, "steps": [
			"%s%s = %s" % ["" if c == 0 else ("Subtract %d: " % c if c > 0 else "Add %d: " % -c), log_in(b, h), D(t)],
			"Raise %d to each side: %s = %s = %s on a GDC" % [b, Answer.x_minus(h), pw, W(bt)], final]},
	}
	return out


# ── fn-ext-exp-graph ─────────────────────────────────────────

## A·b^(x − h) + c as written: "2 × 3^(x − 1) + 2", "−2^x + 1".
static func eg_text(s: Dictionary) -> String:
	var A: Q = s.A
	var pw := Answer.fn_text("exp", s.b, s.h, 0)
	var lead := "" if A.eq(Q.new(1)) else ("−" if A.eq(Q.new(-1)) else Fmt.paren(A) + " × ")
	return lead + pw + Answer.plus_q(s.c)


static func eg_at(s: Dictionary, x: float) -> float:
	return s.A.to_float() * pow(float(s.b), x - s.h) + s.c


## f(0) = A·b^(−h) + c, exactly.
static func eg_y0(s: Dictionary) -> Q:
	var h: int = s.h
	var p := Q.new(1)
	for i in absi(h):
		p = p.div(Q.new(s.b)) if h > 0 else p.mul(Q.new(s.b))
	return s.A.mul(p).add(Q.new(s.c))


static func eg_graph(s: Dictionary, points: Array = []) -> Dictionary:
	var f := func(x: float) -> float: return eg_at(s, x)
	var c: int = s.c
	return Plot.spec([Plot.sample(f, -6.0, 6.0)], points, -6, 6, c - 8, c + 8, [[float(c), "y = %d" % c]])


func u_y_intercept(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y0 := eg_y0(s)
	var ans := Answer.make("yint", {"y": y0})
	ans.exact = true
	var final := "So it is " + Answer.text(ans) + "."
	return {"asked": "Find the y-intercept of the graph.", "lines": ["y = " + eg_text(s)], "answer": ans,
		"wrongs": [wrong({"y": s.A.add(Q.new(s.c))}, "SL2.9.exp-graph#0"), wrong({"y": Q.new(s.c)}, LINE_C), wrong({"y": y0.sub(Q.new(s.c))}, NO_ADD_C)],
		"fillers": [{"y": y0.add(Q.new(1))}, {"y": y0.neg()}],
		"methods": {
			"key-points": {"result": ans.values, "steps": ["Put x = 0: y = %s" % eg_text(s).replace("x", "0"), "= %s" % N(y0), final]},
			"transform-parent": {"result": ans.values, "steps": [
				"Moving (0, 1) on y = %d^x gives (%d, %s), not the y-intercept, as h ≠ 0." % [s.b, s.h, N(s.A.add(Q.new(s.c)))],
				"Substitute x = 0 instead: y = %s" % N(y0), final]},
		}}


## "; the reflection and the shift in x don't move it", naming only the moves y = A·b^(x − h) + c has.
static func others_text(s: Dictionary) -> String:
	var A: Q = s.A
	var parts: Array = []
	if A.sign() < 0:
		parts.append("the reflection" if A.eq(Q.new(-1)) else "the reflection and stretch")
	elif not A.eq(Q.new(1)):
		parts.append("the stretch")
	if s.h != 0:
		parts.append("the shift in x")
	if parts.is_empty():
		return ""
	return "; %s %s move it" % [" and ".join(parts), "don't" if parts.size() > 1 or "and" in parts[0] else "doesn't"]


func u_asymptote(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: int = s.c
	var ans := Answer.make("axis", {"var": "y", "h": Q.new(c)})
	ans.exact = true
	var final := "So the asymptote is " + Answer.text(ans) + "."
	var out := {"asked": "Write down the equation of the horizontal asymptote.", "lines": ["y = " + eg_text(s)], "answer": ans,
		"wrongs": [wrong({"var": "y", "h": Q.new(0)}, "SL2.9.exp-graph#1"), wrong({"var": "x", "h": Q.new(c)}, X_EQ_C)],
		"fillers": [{"var": "y", "h": Q.new(-c)}, {"var": "y", "h": s.A.add(Q.new(c))}, {"var": "x", "h": Q.new(s.h)}],
		"methods": {
			"key-points": {"result": ans.values, "steps": ["As x → −∞, %d^x → 0, so the A·b^(x − h) part → 0." % s.b, "y → %d" % c, final]},
			"transform-parent": {"result": ans.values, "steps": ["y = %d^x has asymptote y = 0." % s.b, "The%s moves it %s %d to y = %d%s." % [Answer.plus_q(c), "up" if c > 0 else "down", absi(c), c, others_text(s)], final]},
		}}
	if rep == "graph":
		out.lines = ["The graph of y = %s is shown." % eg_text(s)]
		out.graph = eg_graph(s)
	return out


func u_range(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: int = s.c
	var up: bool = s.A.sign() > 0
	var ans := Answer.make("bound", {"rel": ">" if up else "<", "v": Q.new(c)}, {"var": "y"})
	ans.exact = true
	var final := "So the range is " + Answer.text(ans) + "."
	var out := {"asked": "Find the range of the function.", "lines": ["y = " + eg_text(s)], "answer": ans,
		"wrongs": [wrong({"rel": "≥" if up else "≤", "v": Q.new(c)}, "SL2.2.range#1"), wrong({"rel": ">" if up else "<", "v": Q.new(0)}, PARENT_ASYM)],
		"fillers": [{"rel": ">" if up else "<", "v": eg_y0(s)}],
		"methods": {
			"key-points": {"result": ans.values, "steps": ["The asymptote is y = %d, which the graph never reaches." % c, "A = %s is %s, so the graph is %s it." % [N(s.A), "positive" if up else "negative", "above" if up else "below"], final]},
			"gdc-transfer": {"result": ans.values, "steps": ["Graph y = %s: it levels off towards y = %d on the left." % [eg_text(s), c], "It stays %s y = %d and takes every value there." % ["above" if up else "below", c], final]},
			"vertex-or-asymptote": {"result": ans.values, "steps": ["An exponential has no vertex: its range is fixed by the asymptote y = %d." % c, "The values are all on one side, never equal to %d." % c, final]},
		}}
	# The other side of the asymptote: a slip when a negative A is ignored, no route when A > 0.
	var side := {"rel": "<" if up else ">", "v": Q.new(c)}
	if up:
		out.fillers.insert(0, side)
	else:
		out.wrongs.append(wrong(side, NEG_A))
	if rep == "graph":
		out.lines = ["The graph of y = %s is shown." % eg_text(s)]
		out.graph = eg_graph(s)
	return out


const GROWS := "increasing: the base is greater than 1"
const DECAYS := "decreasing: the base is between 0 and 1"


func u_growth_or_decay(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var flip: bool = s.flip
	var right := DECAYS if flip else GROWS
	var opts := [right, GROWS if flip else DECAYS, "increasing: the exponent is negative" if flip else "decreasing: the exponent is positive",
		"neither: it has an asymptote"]
	var ans := Answer.make("choice", {"v": right}, {"options": opts})
	var shown := "y = %d^x" % b if not flip else ("y = %d^(−x)" % b if rep != "table" else "y = (1/%d)^x" % b)
	# Reading y = b^(−x) as base b gives the opposite verdict; with no minus in sight it has no route.
	var minus: bool = flip and rep == "equation"
	var out := {"asked": "Does the graph rise or fall from left to right, and why?", "lines": [shown], "answer": ans,
		"wrongs": [wrong({"v": opts[1]}, MINUS_X)] if minus else [],
		"fillers": opts.slice(2 if minus else 1).map(func(o): return {"v": o}),
		"methods": {"base-comparison": {"result": ans.values, "steps": [
			("%d^(−x) = (1/%d)^x: the base is 1/%d." % [b, b, b]) if flip else "The base is %d." % b,
			"A base %s 1 makes y %s as x grows." % ["between 0 and" if flip else "greater than", "shrink" if flip else "grow"], "So it is " + right + "."]}}}
	if rep == "table":
		var xs := [-1, 0, 1, 2]
		out.table = {"rows": [["x", xs.map(func(x): return str(x).replace("-", "−"))], ["y", xs.map(func(x): return N(Q.new(1).mul(Q.new(int(pow(b, absi(x))))) if (x >= 0) != flip else Q.new(1, int(pow(b, absi(x))))))]]}
		out.lines = ["The table shows values of an exponential function."]
	elif rep == "graph":
		var t := s.duplicate()
		t.A = Q.new(1)
		t.h = 0
		t.c = 0
		var f := func(x: float) -> float: return pow(float(b), -x if flip else x)
		out.graph = Plot.spec([Plot.sample(f, -4.0, 4.0)], [[0, 1, "(0, 1)"]], -4, 4, -1, 10)
		out.lines = ["The graph of an exponential function y = a^x is shown."]
	return out


func u_pick_graph(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: int = s.c
	var y0 := eg_y0(s)
	var p1 := Fmt.point(s.h, s.A.add(Q.new(c)))
	# With h = 0 the y-intercept is also where the exponent is 0, so the point is named once.
	var say := func(asym: int, a: String, b2: String, up: bool) -> String:
		return M("asymptote y = %d, through %s, %s" % [asym, a if a == b2 else a + " and " + b2, "increasing" if up else "decreasing"])
	var right: String = say.call(c, Fmt.point(0, y0), p1, true)
	var opts: Array = [right]
	var refs := {}
	for o in [[say.call(0, Fmt.point(0, y0), p1, true), PARENT_ASYM], [say.call(c, Fmt.point(0, y0), p1, false), ""],
			[say.call(c, Fmt.point(0, s.A.add(Q.new(c))), p1, true), "SL2.9.exp-graph#0"],
			[say.call(-c, Fmt.point(0, y0), p1, true), ""], [say.call(c, Fmt.point(0, y0.add(Q.new(1))), p1, true), ""],
			[say.call(c + 1, Fmt.point(0, y0), p1, true), ""], [say.call(c, Fmt.point(0, y0), Fmt.point(-s.h, s.A.add(Q.new(c))), true), SHIFT_WAY]]:
		if not o[0] in opts:
			opts.append(o[0])
			if o[1] != "":
				refs[o[0]] = o[1]
	var ans := Answer.make("choice", {"v": right}, {"options": opts})
	var final := "So it is: " + right + "."
	var out := {"asked": "Which description matches the graph of y = %s?" % eg_text(s), "lines": ["y = " + eg_text(s)], "answer": ans,
		"wrongs": opts.filter(func(o): return refs.has(o)).map(func(o): return wrong({"v": o}, refs[o])),
		"fillers": opts.slice(1).filter(func(o): return not refs.has(o)).map(func(o): return {"v": o}),
		"methods": {
			"key-points": {"result": ans.values, "steps": ["The asymptote is y = %d; at x = 0, y = %s." % [c, N(y0)],
				"At x = %d, y = %s." % [s.h, N(s.A.add(Q.new(c)))] if s.h != 0 else "At x = 1, y = %s." % N(s.A.mul(Q.new(s.b)).add(Q.new(c))), final]},
			"base-comparison": {"result": ans.values, "steps": ["The base %d is greater than 1 and A > 0, so the graph increases." % s.b, "It passes through (0, %s) and levels off at y = %d." % [N(y0), c], final]},
			"gdc-transfer": {"result": ans.values, "steps": ["Graph y = %s on the GDC." % eg_text(s), "Its trace crosses x = 0 at y = %s and flattens towards y = %d." % [N(y0), c], final]},
		}}
	if rep == "graph":
		out.graph = eg_graph(s)
		out.lines = ["The graph of y = %s is shown." % eg_text(s)]
	return out


func u_moves_from_parent(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: int = s.c
	var top: Q = s.A.add(Q.new(c))
	var ans := Answer.make("point", {"x": Q.new(s.h), "y": top})
	ans.exact = true
	var final := "So (0, 1) goes to " + Answer.text(ans) + "."
	var said := "y = " + eg_text(s) if rep == "equation" else "The graph of y = %d^x is transformed to y = %s." % [s.b, eg_text(s)]
	return {"asked": "Where does the point (0, 1) on y = %d^x go?" % s.b, "lines": [said], "answer": ans,
		"wrongs": [wrong({"x": Q.new(-s.h), "y": top}, SHIFT_WAY), wrong({"x": Q.new(s.h), "y": Q.new(1 + c)}, NO_A)],
		"fillers": [{"x": Q.new(s.h), "y": s.A.mul(Q.new(c))}, {"x": Q.new(0), "y": eg_y0(s)}],
		"methods": {"transform-parent": {"result": ans.values, "steps": [moves_text(s), up_text(s), final]}}}


## How x − h and A move (0, 1): each clause only for a move there is.
static func moves_text(s: Dictionary) -> String:
	var h: int = s.h
	var A: Q = s.A
	var parts: Array = []
	if h != 0:
		parts.append("%s inside moves it %d to the %s" % [Answer.x_minus(h), absi(h), "right" if h > 0 else "left"])
	if A.eq(Q.new(-1)):
		parts.append("the − in front reflects it in the x-axis: the y-value 1 goes to −1")
	elif A.sign() < 0:
		parts.append("the %s in front reflects it in the x-axis and stretches it: the y-value 1 goes to %s" % [N(A), N(A)])
	elif not A.eq(Q.new(1)):
		parts.append("the %s in front stretches it vertically: the y-value 1 goes to %s" % [N(A), N(A)])
	if parts.is_empty():
		return "There is no shift in x and nothing in front, so (0, 1) stays put until the vertical shift."
	var out: String = "; ".join(parts)
	return out[0].to_upper() + out.substr(1) + ": (%d, %s)." % [h, N(A)] if not out.begins_with("x") else out + ": (%d, %s)." % [h, N(A)]


static func up_text(s: Dictionary) -> String:
	var c: int = s.c
	var at := Fmt.point(s.h, s.A.add(Q.new(c)))
	if c == 0:
		return "There is no vertical shift: %s, and the asymptote stays y = 0." % at
	return "The%s moves it %s %d: %s; the asymptote y = 0 goes to y = %d." % [Answer.plus_q(c), "up" if c > 0 else "down", absi(c), at, c]


func u_equation_from_graph(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var c: int = s.c
	var A: Q = s.A
	var y0: Q = A.add(Q.new(c))
	var y1: Q = A.mul(Q.new(b)).add(Q.new(c))
	var ans := Answer.make("named", {"v0": Q.new(c), "v1": A, "v2": Q.new(b)}, {"names": ["c", "A", "b"]})
	ans.exact = true
	var out := {"asked": "The function is y = A·b^x + c. Find c, A and b.", "answer": ans,
		"wrongs": [wrong({"v0": Q.new(c), "v1": y0, "v2": Q.new(b)}, A_IS_Y0), wrong({"v0": Q.new(c), "v1": A, "v2": y1.sub(Q.new(c))}, B_NOT_DIV)],
		"fillers": [{"v0": y0, "v1": Q.new(c), "v2": Q.new(b)}, {"v0": Q.new(-c), "v1": A, "v2": Q.new(b)}]}
	if rep == "table":
		out.lines = ["As x → −∞, y → %d." % c]
		out.table = {"rows": [["x", ["0", "1", "2"]], ["y", [N(y0), N(y1), N(A.mul(Q.new(b * b)).add(Q.new(c)))]]]}
	else:
		out.lines = ["The graph of y = A·b^x + c is shown, with its asymptote y = %d." % c]
		out.graph = eg_graph(s, [[0, y0.to_float(), Fmt.point(0, y0)], [1, y1.to_float(), Fmt.point(1, y1)]])
	var final := "So " + Answer.text(ans) + "."
	var steps_c := "The asymptote is y = %d, so c = %d." % [c, c]
	var steps_a := "At x = 0, b⁰ = 1: A%s = %s, so A = %s." % [Answer.plus_q(c), N(y0), N(A)]
	var steps_b := "At x = 1: %sb%s = %s, so b = %d." % [Fmt.lead(A), Answer.plus_q(c), N(y1), b]
	var ab := y1.sub(Q.new(c))
	out.methods = {
		# The parent y = b^x through (0, 1) and (1, b), asymptote y = 0: ×A, then + c.
		"transform-parent": {"result": ans.values, "steps": [
			"Start from y = b^x: asymptote y = 0, through (0, 1) and (1, b). Adding c moves the asymptote to y = c, so c = %d." % c,
			"Multiplying by A sends (0, 1) to (0, A), then + c to (0, A%s) = %s: A = %s. (1, b) goes to (1, %sb%s) = %s: %s." % [
				Answer.plus_q(c), Fmt.point(0, y0), N(A), Fmt.lead(A), Answer.plus_q(c), Fmt.point(1, y1),
				# With A = 1 this is b = 3 already, not "b = 3, so b = 3" (#193).
				("b = %d" % b) if A.eq(Q.new(1)) else "%sb = %s, so b = %d" % [Fmt.lead(A), N(ab), b]], final]},
		"gdc-transfer": {"result": ans.values, "steps": [steps_c + " " + steps_a, "Check b on the GDC: y = %s passes through (1, %s)." % [eg_text(s), N(y1)], final]},
		"asymptote-first": {"result": ans.values, "steps": [steps_c, steps_a, steps_b, final]},
	}
	return out


const MIRROR_Y := "reflections of each other in the y-axis"
const MIRROR_X := "reflections of each other in the x-axis"


func u_compare_reflections(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var opts := [MIRROR_Y, MIRROR_X, "reflections of each other in y = x", "the same graph"]
	var ans := Answer.make("choice", {"v": MIRROR_Y}, {"options": opts})
	var f := func(x: float) -> float: return pow(float(b), x)
	var g := func(x: float) -> float: return pow(float(b), -x)
	return {"asked": "How are the two graphs related?", "lines": ["The graphs of y = %d^x and y = (1/%d)^x are shown." % [b, b]], "answer": ans,
		"graph": Plot.spec([Plot.sample(f, -4.0, 4.0), Plot.sample(g, -4.0, 4.0)], [[0, 1, "(0, 1)"]], -4, 4, -1, 10),
		"wrongs": [wrong({"v": MIRROR_X}, "SL2.9.exp-graph#2")], "fillers": [{"v": opts[2]}, {"v": opts[3]}],
		"methods": {"base-comparison": {"result": ans.values, "steps": [
			"(1/%d)^x = %d^(−x): it is y = %d^x with x replaced by −x." % [b, b, b], "Replacing x by −x reflects a graph in the y-axis; both pass through (0, 1).", "So they are " + MIRROR_Y + "."]}}}
