class_name TrigQuadraticViews
extends TrigEquationViews
## The views on the `trig-quadratic` situation (FAL-753): t3-trig-quadratic, a trig equation that is
## a quadratic in sin x, cos x or tan x. They extend TrigEquationViews for its interval, its `form`
## answer of exact solutions and its wrong lists. A step of the solution has its own unknown: the
## quadratic in u, the identity, the brackets, the values of u, the root to reject.
##
## Paper 1 is exact. The two gdc- unknowns are Paper 2, to 3 s.f., and are the only cells where the
## map's GDC method can be asked.
##
## Representations: "equation" (written out) and "graph". A graph of the whole equation is
## y = the left side once every term is on it, with the crossings marked for gdc-solve. For a count
## or a root to reject it is y = sin x with a dashed line at each root in u.

const R_RANGE := "SL3.8.quadratic-in-trig#0"
const R_COS2_IN_SIN := "SL3.8.quadratic-in-trig#2"
const R_COS2_IN_COS := "SL3.8.quadratic-in-trig#3"
const R_PLUS_ONLY := "SL3.8.quadratic-in-trig#4"
const R_ONE_BRACKET := "SL3.8.quadratic-in-trig#5"
const R_SIGNS := "SL3.8.quadratic-in-trig#6"
const R_PYTHAG := "SL3.8.quadratic-in-trig#7"
const R_INTERVAL := "SL3.8.quadratic-in-trig#8"
const R_MOVED := "SL3.8.quadratic-in-trig#9"
const R_ONE_EACH := "SL3.8.quadratic-in-trig#10"
const R_TOUCH := "SL3.8.quadratic-in-trig#11"
const R_REJECT_NEG := "SL3.8.quadratic-in-trig#12"
const R_NOT_DOUBLED := "SL3.8.quadratic-in-trig#13"
const R_NO_SQUARE := "SL3.8.quadratic-in-trig#14"
const R_COS2_LOSE := "SL3.6.double-angle-values#1"
const R_DEGREES := "SL3.8.graphical#2"
const R_PART_TURN := "SL3.8.graphical#0"
const R_TOUCH_TWICE := "SL3.8.graphical#4"

const M_IF := "identity-then-factorise"
const M_QF := "quadratic-formula"
const M_GDC := "gdc-graph"

const ASKS := ["quadratic-in-u", "identity-to-use", "factorised-form", "values-of-u", "formula-root", "reject-root", "all-solutions", "all-solutions-degrees",
	"double-angle-solve", "plus-minus-root", "tan-squared", "tan-zero-root", "surd-coefficient", "compound-quadratic", "rational-disguise", "double-factor",
	"count-solutions", "one-solution", "sum-solutions", "constant-from-solution", "gdc-solve", "gdc-count"]
const P2 := ["gdc-solve", "gdc-count"]
## These ask for one step, so no list of solutions is made.
const NO_LIST := ["quadratic-in-u", "identity-to-use", "factorised-form", "values-of-u", "formula-root", "reject-root", "constant-from-solution"]
const COUNTS := ["count-solutions", "gdc-count"]
const WHY_RANGE := "it is outside the range of %s x"
const WHY_NEGATIVE := "it is negative"
const WHY_LARGER := "it is the larger root"
const NEITHER := "Neither: both roots give solutions"


func needs() -> Dictionary:
	var out := {}
	for u in ASKS:
		out[u] = {"ask": u}
	return out


## Every bank part is Paper 1, and only the two gdc- unknowns need a calculator.
func papers(unknown: String, _rep: String, _method_id: String) -> Array:
	if not has(unknown):
		return []
	return [2] if unknown in P2 else [1]


# ── Writing the equation ─────────────────────────────────────

## "2 sin²x", "− sin x", "+ 3": one term of a side.
static func term(c: int, body: String, first: bool) -> String:
	var size := str(absi(c)) if body == "" else ("" if absi(c) == 1 else "%d " % absi(c)) + body
	if first:
		return ("−" if c < 0 else "") + size
	return " %s %s" % ["+" if c > 0 else "−", size]


## [[c, body], ...] as a side of an equation, its zero terms left out.
static func side(ts: Array) -> String:
	var out := ""
	for t in ts:
		if t[0] != 0:
			out += term(t[0], t[1], out == "")
	return "0" if out == "" else out


## "sin x", "cos 2x": what u is.
static func u_name(s: Dictionary) -> String:
	return call_of(s)


## "sin²x", "cos²2x".
static func sq_name(s: Dictionary, fn: String = "") -> String:
	return "%s²%s" % [s.fn if fn == "" else fn, arg(s)]


static func other_fn(s: Dictionary) -> String:
	return "cos" if s.fn == "sin" else "sin"


## The quadratic in u that the working comes to, with sc taken in.
static func scaled(s: Dictionary) -> Array:
	return s.p.map(func(c): return c * s.sc)


## The equation's three terms, which add up to 0.
static func terms(s: Dictionary) -> Array:
	var c: Array = scaled(s)
	var name := u_name(s)
	match s.dis:
		"pythag":
			return [[c[0], sq_name(s, other_fn(s))], [-c[1], name], [-c[0] - c[2], ""]]
		"double":
			var t: int = c[0] / 2
			if s.fn == "sin":
				return [[t, "cos 2x"], [-c[1], name], [-t - c[2], ""]]
			return [[t, "cos 2x"], [c[1], name], [t + c[2], ""]]
	return [[c[0], sq_name(s)], [c[1], name], [c[2], ""]]


## The left side minus the right side is `sign` times the quadratic in u.
static func sign_of(s: Dictionary) -> int:
	return -1 if s.dis == "pythag" or (s.dis == "double" and s.fn == "sin") else 1


static func eq_text(s: Dictionary) -> String:
	var ts := terms(s)
	if s.lay == 1 and ts[2][0] != 0:
		return "%s = %s" % [side([ts[0], ts[1]]), Fmt.num(-ts[2][0])]
	if s.lay == 2 and ts[1][0] != 0:
		return "%s = %s" % [side([ts[0], ts[2]]), side([[-ts[1][0], ts[1][1]]])]
	return side(ts) + " = 0"


static func line(s: Dictionary) -> String:
	return "%s, for %s" % [eq_text(s), interval(s)]


## "2u² − u − 1 = 0".
static func uq(c: Array) -> String:
	var head := "u²" if c[0] == 1 else "%du²" % c[0]
	var mid := "" if c[1] == 0 else " %s %su" % ["+" if c[1] > 0 else "−", "" if absi(c[1]) == 1 else str(absi(c[1]))]
	return "%s%s%s = 0" % [head, mid, "" if c[2] == 0 else term(c[2], "", false)]


static func bracket(l: int, c: int, letter: String = "u") -> String:
	var head := letter if l == 1 else ("%d%s" if letter == "u" else "%d %s") % [l, letter]
	return head if c == 0 else "(%s %s %d)" % [head, "+" if c > 0 else "−", absi(c)]


# ── The working ──────────────────────────────────────────────

static func cos2_form(fn: String) -> String:
	return "1 − 2sin²x" if fn == "sin" else "2cos²x − 1"


## The first step: from the equation to the quadratic in u.
static func to_quadratic(s: Dictionary) -> String:
	var let_u := "u = " + u_name(s)
	var q := uq(scaled(s))
	match s.dis:
		"pythag":
			return "Use %s²x = 1 − %s²x, collect the terms and let %s: %s" % [other_fn(s), s.fn, let_u, q]
		"double":
			return "Use cos 2x = %s, collect the terms and let %s: %s" % [cos2_form(s.fn), let_u, q]
	if s.lay == 0 or eq_text(s).ends_with(" = 0"):
		return "Let %s: %s" % [let_u, q]
	return "Bring every term to one side and let %s: %s" % [let_u, q]


static func roots_text(s: Dictionary) -> String:
	return "u = %s or u = %s" % [T(s.us[0]), T(s.us[1])]


static func brackets_text(s: Dictionary) -> String:
	var a := bracket(s.lead[0], s.cons[0])
	var b := bracket(s.lead[1], s.cons[1])
	var body := b + a if s.cons[1] == 0 else a + b
	return ("" if s.sc == 1 else "%d" % s.sc) + body


## What rules a root out, if the quadratic has one to rule out.
static func reject_tail(s: Dictionary) -> String:
	if s.bad.is_empty():
		return ""
	return " %s = %s has no solutions, as %s is never below −1 or above 1." % [u_name(s), T(s.bad[0]), u_name(s)]


static func factor_step(s: Dictionary) -> String:
	return "Factorise: %s = 0, so %s.%s" % [brackets_text(s), roots_text(s), reject_tail(s)]


## b² − 4ac of the quadratic in whole numbers.
static func discriminant(c: Array) -> int:
	return c[1] * c[1] - 4 * c[0] * c[2]


static func formula_step(s: Dictionary) -> String:
	var c := scaled(s)
	return "The quadratic formula gives u = (%s ± %d)/%d, so %s.%s" % [Fmt.num(-c[1]), roundi(sqrt(discriminant(c))), 2 * c[0], roots_text(s), reject_tail(s)]


## Where each root in range lands on the interval.
static func solve_step(s: Dictionary) -> String:
	var bits: Array = []
	for v in s.kept:
		var xs := TrigQuadraticSituation.on(s, s.fn, v)
		bits.append("%s = %s gives x = %s" % [u_name(s), T(v), ", ".join(names(s, xs))] if not xs.is_empty() else "%s = %s gives nothing on this interval" % [u_name(s), T(v)])
	return ", and ".join(bits) + "."


## The two ways to every solution of a rational quadratic.
static func solving(s: Dictionary, a: Dictionary, tail: Array = []) -> Dictionary:
	var last: Array = tail if not tail.is_empty() else [say(a)]
	return {M_IF: method([to_quadratic(s), factor_step(s), solve_step(s)] + last, a.values),
		M_QF: method([to_quadratic(s), formula_step(s), solve_step(s)] + last, a.values)}


## The equation with its identity put in, before the terms are collected.
static func swapped_step(s: Dictionary) -> String:
	var ts := terms(s)
	var swap := "1 − %s" % sq_name(s) if s.dis == "pythag" else cos2_form(s.fn)
	var what := "%s²x = 1 − %s²x" % [other_fn(s), s.fn] if s.dis == "pythag" else "cos 2x = " + swap
	var head: String = "(%s)" % swap if ts[0][0] == 1 else "%d(%s)" % [ts[0][0], swap]
	return "Use %s: %s%s = 0" % [what, head, tail_of(ts)]


static func tail_of(ts: Array) -> String:
	var out := ""
	for t in ts.slice(1):
		if t[0] != 0:
			out += term(t[0], t[1], false)
	return out


# ── Slips ────────────────────────────────────────────────────

## A question's slips, from its own `spin`, so every slip shows up across the seeds.
static func turned(wrongs: Array, s: Dictionary) -> Array:
	return [] if wrongs.is_empty() else TrigModelEquationViews.spun(wrongs, s)


## The principal values of the roots in range that are on the interval.
static func mains(s: Dictionary) -> Array:
	var out: Array = []
	for v in s.kept:
		var x: Q = principal(s.fn, v).div(s.b)
		if not x.lt(s.lo) and not s.hi.lt(x) and not out.any(func(y): return y.eq(x)):
			out.append(x)
	return _sorted(out)


## The roots read with the wrong sign.
static func flipped_roots(s: Dictionary) -> Array:
	return TrigQuadraticSituation._all_of(s, s.kept.map(func(v): return TrigKit.neg(v)))


## The solutions on a whole turn from 0, when the interval is only half of one.
static func past_interval(s: Dictionary) -> Array:
	if not (s.lo.is_zero() and s.hi.eq(1) and s.b.eq(1)):
		return []
	var wide := s.duplicate()
	wide.hi = Q.new(2)
	return TrigQuadraticSituation._all_of(wide, s.kept)


## A cosine's solutions found the way a sine's are, for each root.
static func cos_like_sin(s: Dictionary) -> Array:
	var out: Array = []
	for al in mains(s):
		for x in [al, Q.new(1).sub(al)]:
			if not x.lt(s.lo) and not s.hi.lt(x) and not out.any(func(y): return y.eq(x)):
				out.append(x)
	return out


## The slips every list of solutions can show, in the order of the question's spin.
static func slips(a: Dictionary, s: Dictionary, one: String = R_ONE_BRACKET) -> Array:
	var out: Array = []
	if s.kept.size() == 2:
		out += xs_alt(a, s, TrigQuadraticSituation.on(s, s.fn, s.kept[0]), one)
		if one == R_ONE_BRACKET:
			out += xs_alt(a, s, TrigQuadraticSituation.on(s, s.fn, s.kept[1]), one)
	if mains(s).size() < s.xs.size():
		out += xs_alt(a, s, mains(s), R_PRINCIPAL)
	if s.fn == "cos" and s.b.eq(1):
		out += xs_alt(a, s, cos_like_sin(s), R_COS_MIRROR)
	if one == R_ONE_BRACKET and not s.kept.any(func(v): return TrigKit.is_zero(v)):
		out += xs_alt(a, s, flipped_roots(s), R_SIGNS)
	out += xs_alt(a, s, past_interval(s), R_INTERVAL)
	if s.lo.sign() < 0:
		out += xs_alt(a, s, s.xs.filter(func(x): return x.sign() >= 0), R_NEGATIVE)
	return turned(out, s)


# ── Graphs ───────────────────────────────────────────────────

## The left side at x, once every term is on it.
static func whole_at(s: Dictionary, x: float) -> float:
	var bx: float = s.b.to_float() * x
	if s.ask == "double-factor":
		if s.kind == "tan":
			var k := TrigKit.fl(s.k)
			var c1: float = sqrt(3.0) if tan_third(s) else 1.0
			return c1 * sin(2.0 * x) - c1 * 2.0 * k * cos(x) * cos(x)
		return df_left(s) * sin(2.0 * x) * sin(x) - df_right(s) * cos(x)
	var u: float = sin(bx) if s.fn == "sin" else (cos(bx) if s.fn == "cos" else tan(bx))
	var c := scaled(s)
	return sign_of(s) * (c[0] * u * u + c[1] * u + c[2])


## The whole equation, left side only, on the interval.
static func whole_graph(s: Dictionary, marks: Array = []) -> Dictionary:
	var lo: float = s.lo.to_float() * PI
	var hi: float = s.hi.to_float() * PI
	var clip := 8.0
	var curve := Plot.sample(func(x: float) -> float:
		var y := whole_at(s, x)
		return y if absf(y) <= clip else NAN, lo, hi)
	var y0 := 0.0
	var y1 := 0.0
	for p in curve:
		y0 = minf(y0, p[1])
		y1 = maxf(y1, p[1])
	var g := Plot.spec(TrigKit.branches(curve) if s.fn == "tan" else [curve], marks, floori(lo), ceili(hi), floori(y0) - 1, ceili(y1) + 1)
	g.x_ticks = TrigKit.pi_ticks(s.lo, s.hi, tick_step(s))
	return g


static func tick_step(s: Dictionary) -> Q:
	var span: Q = s.hi.sub(s.lo)
	if span.lt(Q.new(3, 2)):
		return Q.new(1, 4)
	return Q.new(1) if Q.new(5, 2).lt(span) else Q.new(1, 2)


## y = fn x with a dashed line at each root in u.
static func root_lines(s: Dictionary) -> Dictionary:
	var hlines: Array = s.us.map(func(v): return [TrigKit.fl(v), ""])
	var top := 2
	for v in s.us:
		top = maxi(top, ceili(absf(TrigKit.fl(v))) + 1)
	return TrigKit.wave(curve_of(s.fn, s.b.to_float(), 0.0), s.lo, s.hi, -top, top, tick_step(s), [], hlines)


## The text of the whole equation as a graph shows it.
static func whole_text(s: Dictionary) -> String:
	if s.ask == "double-factor":
		return df_whole_text(s)
	return side(terms(s))


static func fig_whole(out: Dictionary, rep: String, s: Dictionary, marks: Array = []) -> void:
	if rep != "graph":
		return
	out.lines.append("The graph shows y = %s on this interval%s." % [whole_text(s), ", with its zeros marked" if not marks.is_empty() else ""])
	out.graph = whole_graph(s, marks)


static func fig_lines(out: Dictionary, rep: String, s: Dictionary) -> void:
	if rep != "graph":
		return
	out.lines.append("The graph shows y = %s, with a dashed line at each root of the quadratic in %s." % [u_name(s), u_name(s)])
	out.graph = root_lines(s)


# ── One step of the solution ─────────────────────────────────

## a sin²x + b sin x + c = 0 with a shown: the two numbers that are left, as an option.
static func quad_alt(s: Dictionary, b: int, c: int, ref: String = "") -> Dictionary:
	return DifferentiationViews.alt(quad_line(s, [scaled(s)[0], b, c]), ref, {"b": Q.new(b), "c": Q.new(c)})


static func quad_line(s: Dictionary, c: Array) -> String:
	return side([[c[0], sq_name(s)], [c[1], u_name(s)], [c[2], ""]]) + " = 0"


## The slip of moving a term across without changing its sign, or {} if no term has been moved.
static func moved_slip(s: Dictionary) -> Dictionary:
	var c := scaled(s)
	var ts := terms(s)
	if s.lay == 2 and ts[1][0] != 0:
		return quad_alt(s, -c[1], c[2], R_MOVED)
	if s.lay == 1 and ts[2][0] != 0:
		return quad_alt(s, c[1], -2 * c[0] - c[2] if s.dis == "pythag" else -c[0] - c[2], R_MOVED)
	return {}


func u_quadratic_in_u(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := scaled(s)
	var name := u_name(s)
	var lead := term(c[0], sq_name(s), true)
	var a := DifferentiationViews.form(quad_line(s, c), [lead + " + ", {"slot": "b"}, " %s + " % name, {"slot": "c"}, " = 0"], {"b": Q.new(c[1]), "c": Q.new(c[2])})
	var out := {"answer": a, "lines": [eq_text(s)], "asked": "Write this as a quadratic in %s, in the form %s + b %s + c = 0." % [name, lead, name]}
	var wrongs: Array = []
	var slip := moved_slip(s)
	if not slip.is_empty():
		wrongs.append(slip)
	if s.dis == "pythag":
		wrongs.append(quad_alt(s, -c[1], -2 * c[0] - c[2], R_PYTHAG))
	else:
		var two := side([[c[0], sq_name(s, other_fn(s))], [-c[1], name], [-c[0] - c[2], ""]]) + " = 0"
		wrongs.append(DifferentiationViews.alt(two, R_COS2_IN_SIN if s.fn == "sin" else R_COS2_IN_COS))
		wrongs.append(DifferentiationViews.alt(side([[c[0] / 2, sq_name(s)], [c[1], name], [c[2], ""]]) + " = 0", R_COS2_LOSE))
	out.wrongs = turned(wrongs, s)
	var gens: Array = [[-c[1], c[2]], [c[1], -c[2]], [c[1], c[2] + 1], [c[1], c[2] - 1], [-c[1], -c[2]], [c[1] + 1, c[2]]]
	out.generic = gens.filter(func(g): return g[0] != 0).map(func(g): return quad_alt(s, g[0], g[1]).values)
	out.methods = {M_IF: method([swapped_step(s), "Bring every term to one side, with %s in front of %s." % [Fmt.num(c[0]), sq_name(s)], say(a)], a.values)}
	return out


func u_identity_to_use(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var fn: String = s.fn
	var o := other_fn(s)
	var right: String
	var picks: Array
	if s.dis == "pythag":
		right = "%s²x = 1 − %s²x" % [o, fn]
		picks = [wrong({"v": "%s²x = %s²x − 1" % [o, fn]}, R_PYTHAG), wrong({"v": "%s²x = 1 + %s²x" % [o, fn]}, R_PYTHAG), wrong({"v": "%s²x = 1 − %s²x" % [fn, o]})]
	else:
		right = "cos 2x = " + cos2_form(fn)
		picks = [wrong({"v": "cos 2x = " + cos2_form(o)}, R_COS2_IN_SIN if fn == "sin" else R_COS2_IN_COS),
			wrong({"v": "cos 2x = 1 − sin²x" if fn == "sin" else "cos 2x = cos²x − 1"}, R_COS2_LOSE), wrong({"v": "cos 2x = cos²x − sin²x"})]
	var opts: Array = [right]
	for w in picks:
		opts.append(w.values.v)
	var a := Answer.make("choice", {"v": right}, {"options": rng.shuffled(opts)})
	var out := {"answer": a, "lines": [eq_text(s)], "asked": "Which identity turns this into a quadratic in %s?" % u_name(s), "wrongs": picks}
	var from := "cos 2x" if s.dis == "double" else "%s²x" % o
	out.methods = {M_IF: method(["The rest of the equation is in %s, so %s has to be written in %s too." % [u_name(s), from, u_name(s)], "That gives %s, one function in a quadratic." % uq(scaled(s)), say(a)], a.values)}
	return out


## "(2 sin x + 1)(sin x − 1) = 0". Two brackets alike are written in one order.
static func two_brackets(s: Dictionary, p: int, q: int) -> String:
	var name := u_name(s)
	var swap: bool = s.lead[0] == s.lead[1] and p > q
	return "%s%s = 0" % [bracket(s.lead[0], q if swap else p, name), bracket(s.lead[1], p if swap else q, name)]


func u_factorised_form(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var name := u_name(s)
	var head := func(l: int) -> String: return name if l == 1 else "%d %s" % [l, name]
	var p: int = s.cons[0]
	var q: int = s.cons[1]
	var parts: Array = ["(%s + " % head.call(s.lead[0]), {"slot": "p"}, ")(%s + " % head.call(s.lead[1]), {"slot": "q"}, ") = 0"]
	var a := DifferentiationViews.form(two_brackets(s, p, q), parts, {"p": Q.new(p), "q": Q.new(q)})
	if s.lead[0] == s.lead[1]:
		a.unordered = [["p", "q"]]
	var out := {"answer": a, "lines": [eq_text(s)], "asked": "Factorise the left side."}
	var alt := func(x: int, y: int, ref: String = "") -> Dictionary: return DifferentiationViews.alt(two_brackets(s, x, y), ref, {"p": Q.new(x), "q": Q.new(y)})
	out.wrongs = [alt.call(-p, -q, R_SIGNS)]
	var gens: Array = [[q, p], [p, -q], [-p, q], [p + 1, q], [p, q - 1]]
	out.generic = gens.filter(func(g): return g[0] != 0 and g[1] != 0).map(func(g): return alt.call(g[0], g[1]).values)
	var c: Array = s.p
	out.methods = {M_IF: method(["Let u = %s: %s" % [name, uq(c)], "Two numbers with product %s and sum %s split the middle term, or try brackets: %s = 0" % [Fmt.num(c[0] * c[2]), Fmt.num(c[1]), brackets_text(s)], say(a)], a.values)}
	return out


func u_values_of_u(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pair := func(x: Q, y: Q, ref: String = "") -> Dictionary:
		var lo_v: Q = x if x.lt(y) else y
		var hi_v: Q = y if x.lt(y) else x
		return DifferentiationViews.alt("u = %s or u = %s" % [Fmt.num(lo_v), Fmt.num(hi_v)], ref, {"r1": lo_v, "r2": hi_v})
	var r1: Q = s.us[0][0]
	var r2: Q = s.us[1][0]
	var first: Dictionary = pair.call(r1, r2)
	var a := DifferentiationViews.form(first.values.text, ["u = ", {"slot": "r1"}, " or u = ", {"slot": "r2"}], {"r1": first.values.r1, "r2": first.values.r2})
	a.unordered = [["r1", "r2"]]
	var out := {"answer": a, "lines": [eq_text(s)], "asked": "Let u = %s. Find the two values of u that solve the quadratic this gives." % u_name(s)}
	out.wrongs = [pair.call(r1.neg(), r2.neg(), R_SIGNS)]
	out.generic = [pair.call(r1, r2.neg()).values, pair.call(r1.neg(), r2).values, pair.call(r1.add(1), r2).values, pair.call(r1, r2.add(1)).values, pair.call(r1.mul(2), r2.mul(2)).values]
	var plain := s.duplicate()
	plain.bad = []
	out.methods = {M_IF: method([to_quadratic(s), factor_step(plain), say(a)], a.values), M_QF: method([to_quadratic(s), formula_step(plain), say(a)], a.values)}
	return out


func u_formula_root(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var name := u_name(s)
	var v: Array = s.kept[0]
	var bad: Array = s.bad[0]
	var a := TrigKit.ans(name + " = ", v)
	var out := {"answer": a, "lines": [eq_text(s)], "asked": "Find the exact value of %s." % name}
	out.wrongs = turned(TrigKit.like(a, bad, R_RANGE) + TrigKit.like(a, TrigKit.times(v, 2), R_NOT_DOUBLED), s)
	out.generic = TrigKit.others(a, [TrigKit.neg(v), TrigKit.neg(bad), TrigKit.times(bad, 2), TrigKit.plus(v, TrigKit.V(1)), TrigKit.plus(v, TrigKit.V(-1))])
	var c: Array = s.p
	out.methods = {M_QF: method([to_quadratic(s), "It has no whole-number factors, so use the formula: u = (%s ± √%d)/%d" % [Fmt.num(-c[1]), discriminant(c), 2 * c[0]],
		"So u = %s or u = %s.%s" % [T(s.us[0]), T(s.us[1]), reject_tail(s)], say(a)], a.values)}
	return out


## The sentence a reject-root option is: a root and why it goes.
static func reject_text(s: Dictionary, v: Array, why: String) -> String:
	return "%s = %s has no solutions, as %s" % [u_name(s), T(v), why]


func u_reject_root(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var good: Array = s.kept[0]
	var bad: Array = s.bad[0]
	var range_why: String = WHY_RANGE % s.fn
	var whys: Array = [range_why, WHY_NEGATIVE, WHY_LARGER]
	var parts: Array = [u_name(s) + " = ", {"slot": "v"}, " has no solutions, as ", {"pick": "why", "options": whys}]
	var a := DifferentiationViews.form(reject_text(s, bad, range_why), parts, {"v": bad[0], "why": range_why})
	var out := {"answer": a, "lines": [eq_text(s)], "asked": "One root of the quadratic in %s gives no solutions. Which one, and why?" % u_name(s)}
	fig_lines(out, rep, s)
	var alt := func(v: Array, why: String, ref: String = "") -> Dictionary: return DifferentiationViews.alt(reject_text(s, v, why), ref, {"v": v[0], "why": why})
	var wrongs: Array = [DifferentiationViews.alt(NEITHER, R_RANGE)]
	if TrigKit.fl(good) < 0.0:
		wrongs.append(alt.call(good, WHY_NEGATIVE, R_REJECT_NEG))
	out.wrongs = turned(wrongs, s)
	var gens: Array = [alt.call(bad, WHY_LARGER), alt.call(good, range_why), alt.call(good, WHY_LARGER), alt.call(bad, WHY_NEGATIVE)]
	out.generic = gens.map(func(g): return g.values)
	var plain := s.duplicate()
	plain.bad = []
	var last := "%s can't be below −1 or above 1, and %s is outside that." % [u_name(s), T(bad)]
	out.methods = {M_IF: method([to_quadratic(s), factor_step(plain), last, say(a)], a.values), M_QF: method([to_quadratic(s), formula_step(plain), last, say(a)], a.values)}
	return out


# ── Every solution ───────────────────────────────────────────

func _solve_view(rep: String, s: Dictionary) -> Dictionary:
	var a := xs_ans(s)
	var out := {"answer": a, "lines": [line(s)], "asked": "Solve the equation, giving exact answers."}
	fig_whole(out, rep, s)
	out.wrongs = slips(a, s)
	out.generic = xs_others(a, s, [flipped_roots(s)] + nudged(s, s.xs))
	out.methods = solving(s, a)
	return out


func u_all_solutions(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _solve_view(rep, s)


func u_all_solutions_degrees(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _solve_view(rep, s)


func u_double_angle_solve(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _solve_view(rep, s)


## u² = a number: the two roots, for the working.
static func square_steps(s: Dictionary) -> Array:
	var first := "Let u = %s: u² = %s" % [u_name(s), Fmt.num(s.sq)]
	if s.get("tan_over", false):
		first = "Multiply by tan x, which is not 0 at a solution, and let u = tan x: u² = %s" % Fmt.num(s.sq)
	return [first, "Take both roots: u = %s or u = %s" % [T(s.us[0]), T(s.us[1])], solve_step(s)]


func u_plus_minus_root(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := xs_ans(s)
	var out := {"answer": a, "lines": [line(s)], "asked": "Solve the equation, giving exact answers."}
	fig_whole(out, rep, s)
	out.wrongs = slips(a, s, R_PLUS_ONLY)
	out.generic = xs_others(a, s, nudged(s, s.xs))
	out.methods = {M_IF: method(square_steps(s) + [say(a)], a.values)}
	return out


func u_tan_squared(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := xs_ans(s)
	var c: Array = s.p
	var eq := "%s tan x = %d/tan x" % [str(c[0]), -c[2]] if s.tan_over else eq_text(s)
	if s.tan_over and c[0] == 1:
		eq = "tan x = %d/tan x" % -c[2]
	var out := {"answer": a, "lines": ["%s, for %s" % [eq, interval(s)]], "asked": "Solve the equation, giving exact answers."}
	fig_whole(out, rep, s)
	out.wrongs = slips(a, s, R_ONE_ROOT)
	out.generic = xs_others(a, s, nudged(s, s.xs))
	out.methods = {M_IF: method(square_steps(s) + [say(a)], a.values)}
	return out


func u_tan_zero_root(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := xs_ans(s)
	var out := {"answer": a, "lines": ["%s, for %s" % [to_tan_line("tan²x", "tan x", s.k), interval(s)]], "asked": "Solve the equation, giving exact answers."}
	var kept := TrigQuadraticSituation.on(s, "tan", s.k)
	var zeros := TrigQuadraticSituation.on(s, "tan", TrigKit.V(0))
	out.wrongs = xs_alt(a, s, kept, R_CANCEL)
	out.generic = xs_others(a, s, [zeros, flipped_roots(s)] + nudged(s, s.xs))
	out.methods = {M_IF: method(["Let u = tan x and bring it to one side: u(u %s) = 0" % _minus(s.k), "Do not cancel u: u = 0 or u = %s" % T(s.k), "u = 0 gives x = %s, and u = %s gives x = %s." % [list_text(s, zeros), T(s.k), list_text(s, kept)], say(a)], a.values)}
	return out


## "(2 + 2√3)", with a sign in front: the coefficient of u, as the equation writes it.
static func signed_value(v: Array, body: String) -> String:
	var neg_: bool = v[0].sign() < 0 or (v[0].is_zero() and v[1].sign() < 0)
	var size := TrigKit.neg(v) if neg_ else v
	return "%s (%s)%s%s" % ["−" if neg_ else "+", T(size), "" if body == "u" else " ", body]


static func surd_line(s: Dictionary, body_sq: String, body: String) -> String:
	var q: Dictionary = s.surd
	var c: Array = q.c
	var neg_: bool = TrigKit.fl(c) < 0.0
	var head: String = uq([q.a, 0, 0]).split(" ")[0] if body == "u" else term(q.a, body_sq, true)
	return "%s %s %s %s = 0" % [head, signed_value(q.b, body), "−" if neg_ else "+", T(TrigKit.neg(c) if neg_ else c)]


## "(2u − 1)", "(u + √3)": a surd bracket.
static func surd_bracket(l: int, v: Array) -> String:
	var neg_: bool = TrigKit.fl(v) < 0.0
	return "(%s %s %s)" % ["u" if l == 1 else "%du" % l, "+" if neg_ else "−", T(TrigKit.neg(v) if neg_ else v)]


func u_surd_coefficient(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := xs_ans(s)
	var out := {"answer": a, "lines": ["%s, for %s" % [surd_line(s, sq_name(s), u_name(s)), interval(s)]], "asked": "Solve the equation, giving exact answers."}
	out.wrongs = slips(a, s)
	out.generic = xs_others(a, s, [flipped_roots(s)] + nudged(s, s.xs))
	var q: Dictionary = s.surd
	var let_u := "Let u = %s: %s" % [u_name(s), surd_line({"surd": q}, "u²", "u")]
	var top := "%s" % T(TrigKit.plus(TrigKit.times(q.right, q.l), TrigKit.times(q.left, q.m)))
	var diff := TrigKit.plus(TrigKit.times(q.right, q.l), TrigKit.times(q.left, -q.m))
	var fact := "Factorise: %s%s = 0, so %s.%s" % [surd_bracket(q.l, q.left), surd_bracket(q.m, q.right), roots_text(s), reject_tail(s)]
	var form := "The formula's discriminant is the perfect square (%s)², so u = (%s ± (%s))/%d = %s or %s.%s" % [T(diff), top, T(diff), 2 * q.a, T(s.us[0]), T(s.us[1]), reject_tail(s)]
	out.methods = {M_IF: method([let_u, fact, solve_step(s), say(a)], a.values), M_QF: method([let_u, form, solve_step(s), say(a)], a.values)}
	return out


## A multiple of the angle, solved on the first wave only.
static func first_wave(s: Dictionary) -> Array:
	return s.xs.filter(func(x): return not s.hi.lt(x.mul(s.b)))


static func wave_note(s: Dictionary) -> String:
	return "%s runs from %s to %s, so go round the wave that far." % [arg(s), A(s, s.lo.mul(s.b)), A(s, s.hi.mul(s.b))]


func u_compound_quadratic(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := xs_ans(s)
	var out := {"answer": a, "lines": [line(s)], "asked": "Solve the equation, giving exact answers."}
	fig_whole(out, rep, s)
	var wrongs: Array = xs_alt(a, s, first_wave(s), R_NO_EXTEND)
	wrongs += xs_alt(a, s, [principal(s.fn, s.kept[0]).div(s.b)].filter(func(x): return not x.lt(s.lo) and not s.hi.lt(x)), R_ONE_BACK)
	if s.kept.size() == 2:
		wrongs += xs_alt(a, s, TrigQuadraticSituation.on(s, s.fn, s.kept[0]), R_ONE_BRACKET)
	out.wrongs = turned(wrongs, s)
	out.generic = xs_others(a, s, [flipped_roots(s)] + nudged(s, s.xs))
	out.methods = solving(s, a)
	out.methods[M_IF].steps.insert(2, wave_note(s))
	out.methods[M_QF].steps.insert(2, wave_note(s))
	return out


static func gap_names(s: Dictionary) -> String:
	return ", ".join(names(s, s.gaps))


## "2 sin 2x − 3 − 6/(sin 2x − 1) = 0".
static func rational_text(s: Dictionary) -> String:
	var name := u_name(s)
	var top: int = s.top
	var inner := "(%s %s 1)" % [name, "−" if s.e.sign() > 0 else "+"]
	return "%s %s %d/%s = 0" % [side([[s.p[0], name], [s.q, ""]]), "+" if top > 0 else "−", absi(top), inner]


func u_rational_disguise(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := xs_ans(s)
	var head := "%s, for %s" % [rational_text(s), interval(s)]
	var out := {"answer": a, "lines": [head if s.gaps.is_empty() else "%s, x ≠ %s" % [head, gap_names(s)]], "asked": "Solve the equation, giving exact answers."}
	var wrongs: Array = []
	if s.b.n > 1:
		wrongs += xs_alt(a, s, first_wave(s), R_NO_EXTEND)
	if s.kept.size() == 2:
		wrongs += xs_alt(a, s, TrigQuadraticSituation.on(s, s.fn, s.kept[0]), R_ONE_BRACKET)
	wrongs += xs_alt(a, s, flipped_roots(s), R_SIGNS)
	out.wrongs = turned(wrongs, s)
	out.generic = xs_others(a, s, nudged(s, s.xs))
	var e_text := "u %s 1" % ("−" if s.e.sign() > 0 else "+")
	var c: Array = s.p
	var top: int = s.top
	var mult := "Let u = %s and multiply through by (%s): %s(%s) %s %d = 0, which is %s" % [u_name(s), e_text, bracket(c[0], s.q), e_text, "+" if top > 0 else "−", absi(top), uq(c)]
	out.methods = {M_IF: method([mult, factor_step(s), solve_step(s), say(a)], a.values)}
	return out


## √3 sin 2x = 2 cos²x, where k = √3/3 would put a fraction in front of cos²x.
static func tan_third(s: Dictionary) -> bool:
	return TrigKit.same(TrigKit.neg(s.k) if TrigKit.fl(s.k) < 0.0 else s.k, TrigKit.V(0, Q.new(1, 3), 3))


static func df_left(s: Dictionary) -> int:
	return 1 if s.n == 2 else 2


static func df_right(s: Dictionary) -> int:
	return 1 if s.n != 3 else 3


static func df_sides(s: Dictionary) -> Array:
	if s.kind == "tan":
		if tan_third(s):
			return ["√3 sin 2x", ("−" if TrigKit.fl(s.k) < 0.0 else "") + "2 cos²x"]
		return ["sin 2x", times_text(TrigKit.times(s.k, 2), "cos²x")]
	return ["%ssin 2x sin x" % ("" if df_left(s) == 1 else "%d " % df_left(s)), "cos x" if df_right(s) == 1 else "%d cos x" % df_right(s)]


static func df_whole_text(s: Dictionary) -> String:
	var two := df_sides(s)
	var right: String = two[1]
	return "%s + %s" % [two[0], right.substr(1)] if right.begins_with("−") else "%s − %s" % [two[0], right]


func u_double_factor(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := xs_ans(s)
	var two := df_sides(s)
	var out := {"answer": a, "lines": ["%s = %s, for %s" % [two[0], two[1], interval(s)]], "asked": "Solve the equation, giving exact answers."}
	fig_whole(out, rep, s)
	var zeros := TrigQuadraticSituation.on(s, "cos", TrigKit.V(0))
	var rest := TrigQuadraticSituation._all_of(s, s.us)
	var wrongs: Array = xs_alt(a, s, rest, R_CANCEL)
	if s.kind == "square":
		wrongs += xs_alt(a, s, TrigEquationSituation._merge(zeros, TrigQuadraticSituation.on(s, "sin", s.us[0])), R_PLUS_ONLY)
	out.wrongs = turned(wrongs, s)
	out.generic = xs_others(a, s, [zeros] + nudged(s, s.xs))
	var head: String
	var parts: String
	if s.kind == "tan":
		var size: Array = TrigKit.neg(s.k) if TrigKit.fl(s.k) < 0.0 else s.k
		var sign := "+" if TrigKit.fl(s.k) < 0.0 else "−"
		var inner := "√3 sin x %s cos x" % sign if tan_third(s) else "sin x %s %s" % [sign, times_text(size, "cos x")]
		head = "Use sin 2x = 2 sin x cos x and bring it to one side: 2 cos x(%s) = 0" % inner
		parts = "cos x = 0 gives x = %s, and the bracket gives tan x = %s, so x = %s." % [list_text(s, zeros), T(s.k), list_text(s, rest)]
	else:
		var q: int = 4 if s.n != 2 else 2
		var m: int = s.n if s.n != 2 else 1
		head = "Use sin 2x = 2 sin x cos x and bring it to one side: cos x(%d sin²x − %d) = 0" % [q, m]
		parts = "cos x = 0 gives x = %s, and sin²x = %s gives sin x = ±%s, so x = %s." % [list_text(s, zeros), Fmt.num(Q.new(s.n, 4)), T(s.us[0]), list_text(s, rest)]
	out.methods = {M_IF: method([head, parts, say(a)], a.values)}
	return out


# ── One number from the solutions ────────────────────────────

## How many solutions a root that is out of range would give, if it gave any.
static func two_a_turn(s: Dictionary) -> int:
	return s.hi.sub(s.lo).n


## How many solutions sit where u is 1 or −1, at a top or bottom of the wave.
static func at_extremes(s: Dictionary) -> int:
	var n := 0
	for v in s.kept:
		if absf(absf(TrigKit.fl(v)) - 1.0) < 1e-9:
			n += TrigQuadraticSituation.on(s, s.fn, v).size()
	return n


static func count_plain(n: int) -> Dictionary:
	var a := Answer.make("number", {"v": Q.new(n)}, {}, "Number of solutions = ")
	a.exact = true
	return a


static func count_wrongs(s: Dictionary, n: int, gdc: bool) -> Array:
	var out: Array = []
	if not s.bad.is_empty():
		out.append(wrong({"v": Q.new(n + two_a_turn(s))}, R_RANGE))
	if s.us.size() != n:
		out.append(wrong({"v": Q.new(s.us.size())}, R_ONE_EACH))
	var ends := at_extremes(s)
	if ends > 0:
		out.append(wrong({"v": Q.new(n + ends)}, R_TOUCH_TWICE))
		if gdc and n > ends:
			out.append(wrong({"v": Q.new(n - ends)}, R_TOUCH))
	if s.hi.sub(s.lo).n > 2:
		var one := s.duplicate()
		one.hi = s.lo.add(2)
		var part := TrigQuadraticSituation._all_of(one, s.kept).size()
		if part != n and part > 0:
			out.append(wrong({"v": Q.new(part)}, R_PART_TURN))
	return turned(out, s)


func u_count_solutions(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.xs.size()
	var a := count_plain(n)
	var out := {"answer": a, "lines": [line(s)], "asked": "How many solutions does the equation have on this interval?"}
	fig_lines(out, rep, s)
	out.wrongs = count_wrongs(s, n, false)
	out.generic = [{"v": Q.new(n + 1)}, {"v": Q.new(n + 2)}, {"v": Q.new(maxi(n - 1, 1))}, {"v": Q.new(2 * n)}, {"v": Q.new(n + 3)}, {"v": Q.new(n + 4)}]
	out.methods = solving(s, a, ["Count them: %s." % Answer.text(a)])
	return out


## The word for what is asked, and the same pick from any other list.
static func pick_or(xs: Array, kind: String) -> Array:
	if kind == "positive" and not xs.any(func(x): return x.sign() > 0):
		return []
	return [] if xs.is_empty() else [TrigQuadraticSituation.pick_from(xs, kind)]


func u_one_solution(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := xs_ans(s)
	var word: String = {"largest": "largest", "smallest": "smallest", "positive": "smallest positive"}[s.kind]
	var full := s.duplicate()
	full.xs = s.all
	var out := {"answer": a, "lines": [line(s)], "asked": "Find the %s solution, in exact form." % word}
	fig_whole(out, rep, s)
	var wrongs: Array = []
	if s.kept.size() == 2:
		for v in s.kept:
			wrongs += xs_alt(a, s, pick_or(TrigQuadraticSituation.on(s, s.fn, v), s.kind), R_ONE_BRACKET)
	wrongs += xs_alt(a, s, pick_or(flipped_roots(s), s.kind), R_SIGNS)
	if not s.kept.any(func(v): return TrigKit.is_zero(v)):
		wrongs += xs_alt(a, s, pick_or(mains(s), s.kind), R_PRINCIPAL)
	out.wrongs = turned(wrongs, s)
	var others: Array = s.all.map(func(x): return [x])
	out.generic = xs_others(a, s, others + nudged(s, s.xs))
	out.methods = {M_IF: method([to_quadratic(s), factor_step(s), solve_step(s), say(a)], a.values)}
	return out


static func sum_text(s: Dictionary, t: Q) -> String:
	return "Sum = " + A(s, t)


static func sum_alt(s: Dictionary, xs: Array, ref: String = "") -> Array:
	if xs.is_empty():
		return []
	var t := TrigQuadraticSituation.total(xs)
	return [DifferentiationViews.alt(sum_text(s, t), ref, {"a": slot_value(s, t)})]


func u_sum_solutions(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t := TrigQuadraticSituation.total(s.xs)
	var a := DifferentiationViews.form(sum_text(s, t), ["Sum = ", {"slot": "a"}, "°" if s.form == "deg" else "π"], {"a": slot_value(s, t)})
	var out := {"answer": a, "lines": [line(s)], "asked": "Find the sum of the solutions of this equation."}
	var wrongs: Array = []
	if s.kept.size() == 2:
		wrongs += sum_alt(s, TrigQuadraticSituation.on(s, s.fn, s.kept[0]), R_ONE_BRACKET)
		wrongs += sum_alt(s, TrigQuadraticSituation.on(s, s.fn, s.kept[1]), R_ONE_BRACKET)
	if mains(s).size() < s.xs.size():
		wrongs += sum_alt(s, mains(s), R_PRINCIPAL)
	wrongs += sum_alt(s, flipped_roots(s), R_SIGNS)
	out.wrongs = turned(wrongs, s)
	var gens: Array = [t.add(Q.new(1, 2)), t.add(1), t.sub(Q.new(1, 2)), t.mul(2), t.add(Q.new(1, 3)), t.add(2)]
	out.generic = gens.filter(func(g): return not g.is_zero()).map(func(g): return DifferentiationViews.alt(sum_text(s, g), "", {"a": slot_value(s, g)}).values)
	var last := "Add them: %s." % Answer.text(a)
	out.methods = {M_IF: method([to_quadratic(s), factor_step(s), solve_step(s), last], a.values)}
	return out


## x is given, and k stands in the place of one number of the quadratic.
func u_constant_from_solution(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Array = s.p
	var r: Q = s.root
	var name := u_name(s)
	var sq := sq_name(s)
	var head := term(c[0], sq, true)
	var at_c: bool = s.shape == "c"
	var eq := "%s %s k = 0" % [side([[c[0], sq], [c[1], name]]), "+"] if at_c else "%s + k %s%s = 0" % [head, name, term(c[2], "", false)]
	var k := Q.new(c[2] if at_c else c[1])
	var a := Answer.make("number", {"v": k}, {}, "k = ")
	a.exact = true
	var out := {"answer": a, "lines": ["x = %s is a solution of %s." % [A(s, s.sol), eq]], "asked": "Find the value of k."}
	var ar := r.mul(c[0])
	var no_sq: Q = ar.add(r.mul(c[1])).neg() if at_c else ar.add(c[2]).div(r).neg()
	out.wrongs = [wrong({"v": no_sq}, R_NO_SQUARE)]
	out.generic = [{"v": k.neg()}, {"v": k.add(1)}, {"v": k.sub(1)}, {"v": k.mul(2)}, {"v": k.add(2)}]
	var put: String
	var first := "%s(%s)²" % ["" if c[0] == 1 else str(c[0]), Fmt.num(r)]
	if at_c:
		put = "%s %s %s(%s) + k = 0" % [first, "+" if c[1] > 0 else "−", "" if absi(c[1]) == 1 else str(absi(c[1])), Fmt.num(r)]
	else:
		put = "%s + k(%s) %s %d = 0" % [first, Fmt.num(r), "+" if c[2] > 0 else "−", absi(c[2])]
	out.methods = {M_IF: method(["At x = %s, %s = %s." % [A(s, s.sol), name, Fmt.num(r)], "Put that in the equation: %s" % put, say(a)], a.values)}
	return out


# ── Paper 2 ──────────────────────────────────────────────────

static func dec_list(xs: Array) -> String:
	return ", ".join(xs.map(func(x): return GdcKit.S(x)))


static func decimal_step(s: Dictionary) -> String:
	var bits: Array = []
	var lo: float = s.lo.to_float() * PI
	var hi: float = s.hi.to_float() * PI
	for u in s.kept_dec:
		var xs := TrigQuadraticSituation.decimal_xs(s, u, lo, hi)
		bits.append("%s = %s gives x = %s" % [u_name(s), GdcKit.S(u), dec_list(xs)] if not xs.is_empty() else "%s = %s gives nothing on this interval" % [u_name(s), GdcKit.S(u)])
	return ", and ".join(bits) + "."


func u_gdc_solve(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := GdcCurveViews.xs_ans(s.xs)
	var out := {"answer": a, "lines": [line(s)], "asked": "Find every solution, to 3 significant figures."}
	fig_whole(out, rep, s, s.xs.map(func(x): return [x.to_float(), 0.0, ""]))
	var wrongs: Array = [wrong(Answer.xs_of(s.xs.map(func(x): return GdcKit.qf(x.to_float() * 180.0 / PI))), R_DEGREES)]
	if s.xs.size() > 1:
		wrongs.append(wrong(Answer.xs_of(s.xs.slice(0, 1)), R_PRINCIPAL))
	out.wrongs = turned(wrongs, s)
	out.generic = dec_others(s)
	var c := scaled(s)
	var us: Array = s.u_dec
	var tail := "" if s.bad_dec.is_empty() else " %s = %s has no solutions, as %s is never below −1 or above 1." % [u_name(s), GdcKit.S(s.bad_dec[0]), u_name(s)]
	var form := "The quadratic formula gives u = (%s ± √%d)/%d, so u = %s or u = %s.%s" % [Fmt.num(-c[1]), discriminant(c), 2 * c[0], GdcKit.S(us[0]), GdcKit.S(us[1]), tail]
	out.methods = {M_QF: method([to_quadratic(s), form, decimal_step(s), say(a)], a.values),
		M_GDC: method(["Bring every term to one side and graph y = %s in radian mode over %s." % [side(terms(s)), interval(s)], "The curve is 0 at x = %s." % dec_list(s.xs), say(a)], a.values)}
	return out


func u_gdc_count(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.xs.size()
	var a := count_plain(n)
	var out := {"answer": a, "lines": [line(s)], "asked": "How many solutions does the equation have on this interval?"}
	fig_whole(out, rep, s)
	out.wrongs = count_wrongs(s, n, true)
	out.generic = [{"v": Q.new(n + 1)}, {"v": Q.new(n + 2)}, {"v": Q.new(maxi(n - 1, 1))}, {"v": Q.new(2 * n)}, {"v": Q.new(n + 3)}, {"v": Q.new(n + 4)}]
	var ends := at_extremes(s)
	var seen := "The curve meets the x-axis at 1 point." if n == 1 else "The curve meets the x-axis at %d points." % n
	if ends == n:
		seen = "The curve only touches the x-axis, at %s, and a touch still counts." % ("1 point" if n == 1 else "%d points" % n)
	elif ends > 0:
		seen = "The curve meets the x-axis at %d points, and at %d of them it only touches, which still counts." % [n, ends]
	out.methods = {M_GDC: method(["Bring every term to one side and graph y = %s in radian mode over %s." % [side(terms(s)), interval(s)], seen, Answer.text(a) + "."], a.values)}
	return out
