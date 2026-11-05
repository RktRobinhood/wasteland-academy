class_name TrigEquationViews
extends ExtensionViews
## The views on the `trig-equation` situation: one builder per unknown of t3-trig-equation
## (FAL-727). A Paper 1 answer is every solution on the interval, a `form` answer with its slots
## in any order: multiples of π, or degrees. A wrong option with another count can be picked but
## not typed. The two GDC unknowns are Paper 2, with an `xs` answer to 3 s.f.
##
## Representations: "equation" (written out), "graph" (the wave and the line y = k, or both sides)
## and "diagram" (the unit circle with the line through the solutions).

const R_PRINCIPAL := "SL3.8.solve-basic#0"
const R_COS_MIRROR := "SL3.8.solve-basic#1"
const R_NEGATIVE := "SL3.8.solve-basic#2"
const R_NO_EXTEND := "SL3.8.compound-angle#0"
const R_ONE_BACK := "SL3.8.compound-angle#1"
const R_ADD := "SL3.8.compound-angle#2"
const R_CANCEL := "SL3.8.factorise-not-divide#0"
const R_FLIP := "SL3.8.factorise-not-divide#1"
const R_TWO_X := "SL3.8.factorise-not-divide#2"
const R_ONE_ROOT := "SL3.8.quadratic-in-trig#1"

const UNKNOWNS := ["basic-exact", "wide-interval", "basic-degrees", "basic-decimal", "multiple-angle", "shifted-angle", "least-positive", "degree-compound",
	"compound-decimal", "tan-compound", "k-cos-to-tan", "double-equals-cos", "double-equals-sin", "product-zero", "squares-to-tan", "factor-reject"]
const P2_ONLY := ["basic-decimal", "compound-decimal"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## Every bank part is Paper 1. A decimal k is the one thing the GDC method needs.
func papers(unknown: String, _rep: String, _method_id: String) -> Array:
	if not has(unknown):
		return []
	return [2] if unknown in P2_ONLY else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = TrigEquationSituation.export(s)
	return out


static func T(v: Array) -> String:
	return TrigKit.text(v)


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


# ── Writing ──────────────────────────────────────────────────

## A multiple of π as the question writes it.
static func A(s: Dictionary, x: Q) -> String:
	return TrigKit.angle(x, s.form)


## "2x", "x/2", "x + π/4", "2x − 15°".
static func arg(s: Dictionary, letter: String = "x") -> String:
	var b: Q = s.b
	var head := letter
	if not b.eq(1):
		head = ("%d%s" % [b.n, letter] if b.n != 1 else letter) + ("" if b.d == 1 else "/%d" % b.d)
	if s.phi.is_zero():
		return head
	return "%s %s %s" % [head, "+" if s.phi.sign() > 0 else "−", A(s, s.phi.abs_q())]


## "sin x", "cos 2x", "cos(x + π/4)".
static func call_of(s: Dictionary, fn: String = "") -> String:
	var f: String = s.fn if fn == "" else fn
	return "%s(%s)" % [f, arg(s)] if not s.phi.is_zero() or s.b.d > 1 else "%s %s" % [f, arg(s)]


## name = k, written the way a question would, for `shape` 0 or 1.
static func equation(name: String, k: Array, shape: int) -> String:
	if k[1].is_zero():
		var q: Q = k[0]
		if q.is_zero():
			return "%d %s = 0" % [shape + 2, name]
		if absi(q.n) == 1 and q.d == 1:
			var c := shape * 2 + 2
			return "%d + %d %s = 0" % [c, c, name] if q.n < 0 else "%d %s − %d = 0" % [c, name, c]
		if q.d == 2 and shape == 1:
			return "%d %s = %s" % [q.d * 3, name, Fmt.num(q.n * 3)]
		return "%d %s %s %d = 0" % [q.d, name, "+" if q.n < 0 else "−", absi(q.n)]
	var neg_: bool = k[1].sign() < 0
	var size: Q = k[1].abs_q()
	if k[2] == 3 and size.eq(1):
		return "%s = %s√3" % [name, "−" if neg_ else ""] if shape == 0 else "%s %s √3 = 0" % [name, "+" if neg_ else "−"]
	if k[2] == 3 and size.eq(Q.new(1, 3)):
		return "√3 %s = %s1" % [name, "−" if neg_ else ""]
	if k[2] == 2 and shape == 0:
		return "√2 %s = %s1" % [name, "−" if neg_ else ""]
	return "2 %s = %s√%d" % [name, "−" if neg_ else "", k[2]] if shape == 0 or k[2] == 2 else "2 %s %s √%d = 0" % [name, "+" if neg_ else "−", k[2]]


static func interval(s: Dictionary) -> String:
	return "%s ≤ x %s %s" % [A(s, s.lo), "<" if s.open_hi else "≤", A(s, s.hi)]


static func names(s: Dictionary, xs: Array) -> Array:
	return xs.map(func(x): return A(s, x))


static func list_text(s: Dictionary, xs: Array) -> String:
	return Answer.xs_list(names(s, xs))


static func slot_value(s: Dictionary, x: Q) -> Q:
	return x.mul(180) if s.form == "deg" else x


static func xs_slots(s: Dictionary, xs: Array) -> Dictionary:
	var out := {}
	for i in xs.size():
		out["a%d" % i] = slot_value(s, xs[i])
	return out


static func xs_ans(s: Dictionary) -> Dictionary:
	var xs: Array = s.xs
	var parts: Array = ["x = "]
	var ids: Array = []
	for i in xs.size():
		if i > 0:
			parts.append(" or " if i == xs.size() - 1 else ", ")
		parts.append({"slot": "a%d" % i})
		parts.append("°" if s.form == "deg" else "π")
		ids.append("a%d" % i)
	var out := DifferentiationViews.form("x = " + list_text(s, xs), parts, xs_slots(s, xs))
	out.unordered = [ids]
	out.count = xs.size()
	return out


static func _sorted(xs: Array) -> Array:
	var out := xs.duplicate()
	out.sort_custom(func(p, q): return p.lt(q))
	return out


## A wrong list of solutions: typed where the count is the answer's.
static func xs_alt(a: Dictionary, s: Dictionary, xs: Array, ref: String = "") -> Array:
	if xs.is_empty():
		return []
	var sorted := _sorted(xs)
	return [DifferentiationViews.alt("x = " + list_text(s, sorted), ref, xs_slots(s, sorted) if xs.size() == a.count else {})]


static func xs_others(a: Dictionary, s: Dictionary, lists: Array) -> Array:
	var out: Array = []
	for xs in lists:
		for w in xs_alt(a, s, xs):
			out.append(w.values)
	return out


## The principal value of fn u = k, as a multiple of π.
static func principal(fn: String, k: Array) -> Q:
	var size := TrigKit.times(k, -1) if TrigKit.fl(k) < 0.0 else k
	var r := Q.new(0)
	for p in [[0, 1], [1, 6], [1, 4], [1, 3], [1, 2]]:
		var t := Q.new(p[0], p[1])
		var v := TrigKit.of(fn, t)
		if not v.is_empty() and TrigKit.same(v, size):
			r = t
	if TrigKit.fl(k) >= 0.0:
		return r
	return Q.new(1).sub(r) if fn == "cos" else r.neg()


## Quadrants where fn has k's sign, for the working.
static func quadrants(fn: String, k: Array) -> String:
	var up: bool = TrigKit.fl(k) > 0.0
	match fn:
		"sin":
			return "1 and 2" if up else "3 and 4"
		"cos":
			return "1 and 4" if up else "2 and 3"
	return "1 and 3" if up else "2 and 4"


static func mirror_rule(fn: String) -> String:
	return {"sin": "sin also gives π − α", "cos": "cos also gives −α", "tan": "tan repeats every π"}[fn]


## The two middle steps for fn u = k: its angles, by CAST or by the graph's symmetry.
static func angle_steps(id: String, fn: String, k: Array, name: String, s: Dictionary) -> Array:
	var size := TrigKit.times(k, -1) if TrigKit.fl(k) < 0.0 else k
	var al := principal(fn, k)
	if TrigKit.is_zero(k):
		return ["%s = 0 at two opposite points of the unit circle, half a turn apart." % name]
	if k[1].is_zero() and absf(k[0].to_float()) == 1.0 and fn != "tan":
		return ["%s = %s at one point of the unit circle, once a turn." % [name, T(k)]]
	if id == "unit-circle-cast":
		return ["The reference angle is %s, as %s(%s) = %s." % [A(s, principal(fn, size)), fn, A(s, principal(fn, size)), T(size)], "%s has this sign in quadrants %s." % [fn, quadrants(fn, k)]]
	if fn == "tan":
		return ["The principal value is α = %s." % A(s, al), "%s." % mirror_rule(fn)]
	return ["The principal value is α = %s." % A(s, al), "%s, and all of it repeats every %s." % [mirror_rule(fn), A(s, Q.new(2))]]


## Every value of u = bx + φ on the transformed interval, for the working.
static func u_values(s: Dictionary) -> Array:
	var out: Array = s.xs.map(func(x): return x.mul(s.b).add(s.phi))
	return out


# ── Graphs ───────────────────────────────────────────────────

static func curve_of(fn: String, b: float, phi: float) -> Callable:
	match fn:
		"sin":
			return func(x: float) -> float: return sin(b * x + phi)
		"cos":
			return func(x: float) -> float: return cos(b * x + phi)
	return func(x: float) -> float:
		var t := tan(b * x + phi)
		return t if absf(t) <= 3.0 else NAN


## The wave of the left side with the line y = k, on the interval.
static func graph_of(s: Dictionary) -> Dictionary:
	var k := TrigKit.fl(s.k)
	var step := Q.new(1, 4) if s.hi.sub(s.lo).lt(Q.new(3, 2)) else Q.new(1, 2)
	var g := TrigKit.wave(curve_of(s.fn, s.b.to_float(), s.phi.to_float() * PI), s.lo, s.hi, -3 if s.fn == "tan" else -2, 3 if s.fn == "tan" else 2, step, [], [[k, ""]])
	g.curves = TrigKit.branches(g.curves[0])
	return g


# ── Finding them ─────────────────────────────────────────────

static func _basic(rep: String, s: Dictionary) -> Dictionary:
	var a := xs_ans(s)
	var name := call_of(s)
	var eq := equation(name, s.k, s.shape)
	var iv := interval(s)
	var out := {"answer": a, "lines": ["%s, for %s" % [eq, iv]], "asked": "Solve the equation, giving exact answers."}
	if rep == "graph":
		out.lines.append("The graph shows y = %s with the dashed line y = %s." % [name, T(s.k)])
		out.graph = graph_of(s)
	elif rep == "diagram":
		var pts: Array = TrigEquationSituation.solve(s.fn, s.k, Q.new(1), Q.new(0), Q.new(0), Q.new(2), true)
		var letters := ["A", "B"]
		var g := {"kind": "unit-circle", "points": [], "radius": true}
		for i in pts.size():
			g.points.append(TrigKit.point(pts[i].to_float() * PI, letters[i]))
		g[("level" if s.fn == "sin" else "level_x")] = TrigKit.fl(s.k)
		out.lines.append("On the unit circle, the dashed line is %s = %s." % ["y" if s.fn == "sin" else "x", T(s.k)])
		out.graph = g
	return out


## Wrong lists shared by the basic unknowns.
static func basic_wrongs(a: Dictionary, s: Dictionary) -> Array:
	var al := principal(s.fn, s.k)
	var out: Array = []
	if s.xs.size() > 1:
		out += xs_alt(a, s, [al], R_PRINCIPAL)
	if s.fn == "cos":
		var other: Q = Q.new(1).sub(al)
		var pair: Array = [al] if other.eq(al) else [al, other]
		out += xs_alt(a, s, pair.filter(func(x): return not x.lt(s.lo) and not s.hi.lt(x)), R_COS_MIRROR)
	return out


static func flipped(s: Dictionary) -> Array:
	return TrigEquationSituation.solve(s.fn, TrigKit.neg(s.k), s.b, s.phi, s.lo, s.hi, s.open_hi)


static func nudged(s: Dictionary, xs: Array) -> Array:
	var out: Array = []
	for d in [Q.new(1, 6), Q.new(1, 4), Q.new(-1, 6), Q.new(1, 3), Q.new(1, 2)]:
		out.append(xs.map(func(x): return x.add(d)))
	return out


func _basic_view(rep: String, s: Dictionary) -> Dictionary:
	var out := _basic(rep, s)
	var a: Dictionary = out.answer
	out.wrongs = basic_wrongs(a, s)
	if s.ask == "wide-interval" and s.lo.sign() < 0:
		out.wrongs += xs_alt(a, s, s.xs.filter(func(x): return x.sign() >= 0), R_NEGATIVE)
	out.generic = xs_others(a, s, [flipped(s)] + nudged(s, s.xs))
	var name := call_of(s)
	var head := "Rearrange: %s = %s" % [name, T(s.k)]
	var tail := "On %s: %s" % [interval(s), list_text(s, s.xs)]
	out.methods = {"unit-circle-cast": method([head] + angle_steps("unit-circle-cast", s.fn, s.k, name, s) + [tail, say(a)], a.values),
		"graph-symmetry": method([head] + angle_steps("graph-symmetry", s.fn, s.k, name, s) + [tail, say(a)], a.values)}
	return out


func u_basic_exact(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _basic_view(rep, s)


func u_wide_interval(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _basic_view(rep, s)


func u_basic_degrees(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _basic_view(rep, s)


static func gdc_steps(s: Dictionary, a: Dictionary, shown: Array) -> Array:
	var name := call_of(s)
	return ["Graph y = %s and y = %s in radian mode, with a window over %s." % [name, Fmt.dec(s.k), interval(s)],
		"Use intersect at every crossing: x = %s" % ", ".join(shown), say(a)]


static func dec_others(s: Dictionary) -> Array:
	var xs: Array = s.xs
	return [Answer.xs_of(xs.slice(0, 1)), Answer.xs_of(xs.map(func(x): return GdcKit.qf(x.to_float() * 2.0))), Answer.xs_of(xs.map(func(x): return GdcKit.qf(x.to_float() + 0.5))),
		Answer.xs_of(xs.map(func(x): return GdcKit.qf(x.to_float() * 180.0 / PI)))]


func u_basic_decimal(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := GdcCurveViews.xs_ans(s.xs)
	var out := {"answer": a, "lines": ["%s = %s, for %s" % [call_of(s), Fmt.dec(s.k), interval(s)]], "asked": "Find every solution, to 3 significant figures."}
	out.wrongs = [wrong(Answer.xs_of(s.xs.slice(0, 1)), R_PRINCIPAL)] if s.xs.size() > 1 else []
	out.generic = dec_others(s)
	out.methods = {"gdc-intersection": method(gdc_steps(s, a, s.xs.map(func(x): return GdcKit.W(x))), a.values)}
	return out


func u_compound_decimal(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := GdcCurveViews.xs_ans(s.xs)
	var out := {"answer": a, "lines": ["%s = %s, for %s" % [call_of(s), Fmt.dec(s.k), interval(s)]], "asked": "Find every solution, to 3 significant figures."}
	var top: float = s.hi.to_float() * PI
	var first: Array = s.xs.filter(func(x): return x.to_float() * s.b.to_float() <= top)
	out.wrongs = [wrong(Answer.xs_of(first), R_NO_EXTEND)] if not first.is_empty() and first.size() < s.xs.size() else []
	out.generic = dec_others(s)
	out.methods = {"gdc-intersection": method(gdc_steps(s, a, s.xs.map(func(x): return GdcKit.W(x))), a.values)}
	return out


## The steps for fn(bx + φ) = k, by substitution or by adding the period.
static func compound_steps(id: String, s: Dictionary, name: String, solved: Array) -> Array:
	var us := u_values(s)
	var u0 := A(s, s.lo.mul(s.b).add(s.phi))
	var u1 := A(s, s.hi.mul(s.b).add(s.phi))
	var period: Q = Q.new(1 if s.fn == "tan" else 2).div(s.b)
	if id == "substitute-u":
		return ["Let u = %s. The interval becomes %s ≤ u %s %s." % [arg(s), u0, "<" if s.open_hi else "≤", u1], "Solve %s u = %s: u = %s" % [s.fn, T(s.k), list_text(s, us)],
			"Undo u = %s for each one: x = %s" % [arg(s), list_text(s, solved)]]
	return ["%s = %s has a solution at x = %s." % [name, T(s.k), A(s, solved[0])], "The period of %s is %s, so add or subtract it, with the other solution in each period." % [name, A(s, period)],
		"On %s: x = %s" % [interval(s), list_text(s, solved)]]


func _compound_view(rep: String, s: Dictionary) -> Dictionary:
	var out := _basic(rep, s)
	var a: Dictionary = out.answer
	var b: Q = s.b
	var name := call_of(s)
	var first: Array = s.xs.filter(func(x): return x.mul(b).add(s.phi).lt(s.hi.add(s.phi)) or x.mul(b).add(s.phi).eq(s.hi.add(s.phi)))
	out.wrongs = []
	if b.n > 1:
		if first.size() < s.xs.size():
			out.wrongs += xs_alt(a, s, first, R_NO_EXTEND)
		out.wrongs += xs_alt(a, s, [principal(s.fn, s.k).sub(s.phi).div(b)], R_ONE_BACK)
	if not s.phi.is_zero():
		out.wrongs += xs_alt(a, s, TrigEquationSituation.solve(s.fn, s.k, b, s.phi.neg(), s.lo, s.hi), R_ADD)
	out.generic = xs_others(a, s, [flipped(s)] + nudged(s, s.xs))
	out.methods = {"substitute-u": method(compound_steps("substitute-u", s, name, s.xs) + [say(a)], a.values),
		"add-the-period": method(compound_steps("add-the-period", s, name, s.xs) + [say(a)], a.values)}
	return out


func u_multiple_angle(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _compound_view(rep, s)


func u_shifted_angle(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _compound_view(rep, s)


func u_degree_compound(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _compound_view(rep, s)


func u_least_positive(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: Q = s.xs[0]
	var a := xs_ans(s)
	var name := call_of(s)
	var out := {"answer": a, "lines": [equation(name, s.k, s.shape)], "asked": "Find the least positive solution, in exact form."}
	var flipped_phi := TrigEquationSituation.solve(s.fn, s.k, s.b, s.phi.neg(), Q.new(0), s.hi).filter(func(v): return v.sign() > 0)
	out.wrongs = xs_alt(a, s, flipped_phi.slice(0, 1), R_ADD) if not flipped_phi.is_empty() else []
	var later: Array = s.all.slice(1, 3)
	var lists: Array = later.map(func(v): return [v])
	lists.append([x.mul(2)])
	lists.append([x.add(Q.new(1, 6))])
	lists.append([x.add(Q.new(1, 4))])
	lists.append([x.add(Q.new(1, 3))])
	out.generic = xs_others(a, s, lists)
	var u := x.mul(s.b).add(s.phi)
	var start := A(s, s.phi)
	var period: Q = Q.new(2).div(s.b)
	out.methods = {"substitute-u": method(["Let u = %s. x > 0 means u > %s." % [arg(s), start], "Solve %s u = %s: the first u past %s is %s." % [s.fn, T(s.k), start, A(s, u)], "Undo u = %s: x = %s" % [arg(s), A(s, x)], say(a)], a.values),
		"add-the-period": method(["Solve for one x, then the period of %s is %s." % [name, A(s, period)], "The two families of solutions step by the period; the smallest positive one is %s." % A(s, x), say(a)], a.values)}
	return out


func u_tan_compound(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := xs_ans(s)
	var bx := arg(s)
	var line := to_tan_line("sin " + bx, "cos " + bx, s.k)
	var out := {"answer": a, "lines": ["%s, for %s" % [line, interval(s)]], "asked": "Solve the equation, giving exact answers."}
	out.wrongs = []
	out.wrongs += xs_alt(a, s, [principal("tan", s.k).div(s.b)], R_ONE_BACK)
	var inv := TrigKit.over(TrigKit.V(1), s.k)
	out.generic = xs_others(a, s, [flipped(s), TrigEquationSituation.solve("tan", inv, s.b, s.phi, s.lo, s.hi)] + nudged(s, s.xs))
	var us := list_text(s, u_values(s))
	var name := "tan " + bx
	out.methods = {"divide-to-tan": method(["cos %s = 0 would make sin %s = 0 too, which can't happen, so divide by cos %s." % [bx, bx, bx], "%s = %s" % [name, T(s.k)], "So %s = %s, which gives x = %s" % [bx, us, list_text(s, s.xs)], say(a)], a.values),
		"substitute-u": method(["Let u = %s, so the interval becomes %s ≤ u ≤ %s." % [bx, A(s, s.lo.mul(s.b)), A(s, s.hi.mul(s.b))], "Divide by cos u: tan u = %s" % T(s.k), "u = %s, so x = %s" % [us, list_text(s, s.xs)], say(a)], a.values)}
	return out


## sin x = k cos x, written the way a question would.
static func to_tan_line(si: String, co: String, k: Array) -> String:
	var neg_: bool = TrigKit.fl(k) < 0.0
	var size := TrigKit.neg(k) if neg_ else k
	if TrigKit.same(size, TrigKit.V(1)):
		return "%s + %s = 0" % [si, co] if neg_ else "%s = %s" % [si, co]
	if size[2] == 3 and size[1].eq(1):
		return "%s = %s√3 %s" % [si, "−" if neg_ else "", co]
	return "√3 %s = %s%s" % [si, "−" if neg_ else "", co]


func u_k_cos_to_tan(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := xs_ans(s)
	var line := to_tan_line("sin x", "cos x", s.k)
	var out := {"answer": a, "lines": ["%s, for %s" % [line, interval(s)]], "asked": "Solve the equation, giving exact answers."}
	var inv := TrigKit.over(TrigKit.V(1), s.k)
	if rep == "graph":
		out.lines.append("The graph shows both sides of the equation, written as y = sin x and y = %s cos x." % T(s.k))
		var kk := TrigKit.fl(s.k)
		var g := TrigKit.wave(sin, Q.new(0), Q.new(2), -2, 2, Q.new(1, 2))
		g.curves.append(Plot.sample(func(x: float) -> float: return kk * cos(x), 0.0, TAU))
		out.graph = g
	out.wrongs = xs_alt(a, s, TrigEquationSituation.solve("tan", inv, s.b, s.phi, s.lo, s.hi), R_FLIP) if not TrigKit.same(inv, s.k) else []
	out.generic = xs_others(a, s, [flipped(s), [s.xs[0]]] + nudged(s, s.xs))
	var head := "cos x = 0 would make sin x = 0 too, which can't happen, so divide by cos x."
	var mid := "tan x = %s" % T(s.k)
	var tail := "On %s: x = %s" % [interval(s), list_text(s, s.xs)]
	out.methods = {"divide-to-tan": method([head, mid, tail, say(a)], a.values),
		"graphical-check": method(graph_first(rep, "sin x", times_text(s.k, "cos x"), s) + [head, mid, tail, say(a)], a.values)}
	return out


## The first lines of "Graph both sides": the graph says how many solutions there are,
## and the algebra after it finds them exactly.
static func graph_first(rep: String, left: String, right: String, s: Dictionary) -> Array:
	var look := "The graph shows both sides." if rep == "graph" else "Sketch y = %s and y = %s on %s." % [left, right, interval(s)]
	return [look, "They meet at %d points, so the equation has %d solutions." % [s.xs.size(), s.xs.size()]]


## m cos x, or m sin x: "cos x", "√3 cos x", "−cos x".
static func times_text(m: Array, body: String) -> String:
	if TrigKit.same(m, TrigKit.V(1)):
		return body
	if TrigKit.same(m, TrigKit.V(-1)):
		return "−" + body
	return "%s %s" % [T(m), body]


## Two curves on 0 to 2π, for both sides of an equation.
static func both_sides(f: Callable, g: Callable) -> Dictionary:
	var spec := TrigKit.wave(f, Q.new(0), Q.new(2), -2, 2, Q.new(1, 2))
	spec.curves.append(Plot.sample(g, 0.0, TAU))
	return spec


func u_double_equals_cos(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := xs_ans(s)
	var side := times_text(s.m, "cos x")
	var out := {"answer": a, "lines": ["sin 2x = %s, for %s" % [side, interval(s)]], "asked": "Solve the equation, giving exact answers."}
	var mf := TrigKit.fl(s.m)
	if rep == "graph":
		out.lines.append("The graph shows y = sin 2x and y = %s." % side)
		out.graph = both_sides(func(x: float) -> float: return sin(2.0 * x), func(x: float) -> float: return mf * cos(x))
	var kept := TrigEquationSituation.solve("sin", s.k, Q.new(1), Q.new(0), s.lo, s.hi)
	var zeros := TrigEquationSituation.solve("cos", TrigKit.V(0), Q.new(1), Q.new(0), s.lo, s.hi)
	out.wrongs = xs_alt(a, s, kept, R_CANCEL)
	out.generic = xs_others(a, s, [zeros, flipped_sin(s, zeros)] + nudged(s, s.xs))
	var head := "Use sin 2x = 2 sin x cos x and bring it to one side: cos x(2 sin x %s) = 0" % _minus(s.m)
	var parts := "cos x = 0 gives x = %s, and sin x = %s gives x = %s" % [list_text(s, zeros), T(s.k), list_text(s, kept)]
	out.methods = {"factorise": method([head, parts, say(a)], a.values),
		"graphical-check": method(graph_first(rep, "sin 2x", side, s) + [head, parts, say(a)], a.values)}
	return out


static func flipped_sin(s: Dictionary, zeros: Array) -> Array:
	return TrigEquationSituation._merge(zeros, TrigEquationSituation.solve("sin", TrigKit.neg(s.k), Q.new(1), Q.new(0), s.lo, s.hi))


## "− √3", "+ 1": m taken over to the left of a bracket.
static func _minus(m: Array) -> String:
	return "%s %s" % ["+" if TrigKit.fl(m) < 0.0 else "−", T(TrigKit.neg(m) if TrigKit.fl(m) < 0.0 else m)]


func u_double_equals_sin(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := xs_ans(s)
	var side := times_text(s.m, "sin x")
	var out := {"answer": a, "lines": ["sin 2x = %s, for %s" % [side, interval(s)]], "asked": "Solve the equation, giving exact answers."}
	var mf := TrigKit.fl(s.m)
	if rep == "graph":
		out.lines.append("The graph shows y = sin 2x and y = %s." % side)
		out.graph = both_sides(func(x: float) -> float: return sin(2.0 * x), func(x: float) -> float: return mf * sin(x))
	var kept := TrigEquationSituation.solve("cos", s.k, Q.new(1), Q.new(0), s.lo, s.hi, s.open_hi)
	var zeros := TrigEquationSituation.solve("sin", TrigKit.V(0), Q.new(1), Q.new(0), s.lo, s.hi, s.open_hi)
	out.wrongs = []
	if TrigKit.same(s.m, TrigKit.V(1)):
		out.wrongs += xs_alt(a, s, [Q.new(0)], R_TWO_X)
	out.wrongs += xs_alt(a, s, kept, R_CANCEL)
	out.generic = xs_others(a, s, [zeros] + nudged(s, s.xs))
	var head := "Use sin 2x = 2 sin x cos x and bring it to one side: sin x(2 cos x %s) = 0" % _minus(s.m)
	var parts := "sin x = 0 gives x = %s, and cos x = %s gives x = %s" % [list_text(s, zeros), T(s.k), list_text(s, kept)]
	out.methods = {"factorise": method([head, parts, say(a)], a.values),
		"graphical-check": method(graph_first(rep, "sin 2x", side, s) + [head, parts, say(a)], a.values)}
	return out


func u_product_zero(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := xs_ans(s)
	var inner := "2 %s x %s" % [s.f2, _minus(TrigKit.times(s.k, 2))]
	var out := {"answer": a, "lines": ["%s x(%s) = 0, for %s" % [s.f1, inner, interval(s)]], "asked": "Solve the equation, giving exact answers."}
	var kept := TrigEquationSituation.solve(s.f2, s.k, Q.new(1), Q.new(0), s.lo, s.hi)
	var zeros := TrigEquationSituation.solve(s.f1, TrigKit.V(0), Q.new(1), Q.new(0), s.lo, s.hi)
	out.wrongs = xs_alt(a, s, kept, R_CANCEL)
	out.generic = xs_others(a, s, [zeros] + nudged(s, s.xs))
	out.methods = {"factorise": method(["A product is 0 when one factor is: %s x = 0 or %s x = %s." % [s.f1, s.f2, T(s.k)], "%s x = 0 gives x = %s" % [s.f1, list_text(s, zeros)], "%s x = %s gives x = %s" % [s.f2, T(s.k), list_text(s, kept)], say(a)], a.values)}
	return out


func u_squares_to_tan(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := xs_ans(s)
	var first := "%scos²x" % ("" if s.ca == 1 else "%d " % s.ca)
	var second := "%ssin²x" % ("" if s.cb == 1 else "%d " % s.cb)
	var out := {"answer": a, "lines": ["%s − %s = 0, for %s" % [first, second, interval(s)]], "asked": "Solve the equation, giving exact answers."}
	var plus_only := TrigEquationSituation.solve("tan", s.k, Q.new(1), Q.new(0), s.lo, s.hi)
	out.wrongs = xs_alt(a, s, plus_only, R_ONE_ROOT)
	out.generic = xs_others(a, s, [TrigEquationSituation.solve("tan", TrigKit.neg(s.k), Q.new(1), Q.new(0), s.lo, s.hi)] + nudged(s, s.xs))
	var r := TrigKit.sq(s.k)
	var root := T(s.k)
	out.methods = {"divide-to-tan": method(["cos x = 0 would make sin x = 0 too, so divide by cos²x: tan²x = %s" % T(r), "Take both roots: tan x = %s or tan x = %s" % [root, T(TrigKit.neg(s.k))], "On %s: x = %s" % [interval(s), list_text(s, s.xs)], say(a)], a.values),
		"factorise": method(["Use cos²x − %s sin²x: a difference of two squares gives (cos x − %s sin x)(cos x + %s sin x) = 0." % [T(TrigKit.over(TrigKit.V(1), r)), T(TrigKit.over(TrigKit.V(1), s.k)), T(TrigKit.over(TrigKit.V(1), s.k))], "Each bracket gives tan x = ±%s" % root, "On %s: x = %s" % [interval(s), list_text(s, s.xs)], say(a)], a.values)}
	return out


func u_factor_reject(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Q = s.m
	var a := TrigKit.ans("tan θ = ", TrigKit.V(m))
	var side := times_text(TrigKit.V(m), "sin θ cos θ")
	var out := {"answer": a, "lines": ["sin²θ = %s, for 0 < θ < π" % side], "asked": "Find the exact value of tan θ."}
	out.wrongs = TrigKit.like(a, TrigKit.V(Q.new(1).div(m)), R_FLIP)
	out.generic = TrigKit.others(a, [TrigKit.V(m.neg()), TrigKit.V(Q.new(-1).div(m)), TrigKit.V(m.mul(2)), TrigKit.V(m.div(2)), TrigKit.V(m.add(1)), TrigKit.V(0)])
	var mt := Fmt.num(m)
	out.methods = {"factorise": method(["Bring it to one side: sin θ(sin θ − (%s) cos θ) = 0" % mt, "sin θ = 0 has no solution on 0 < θ < π, so reject it.", "sin θ = %s cos θ, so tan θ = %s" % [P(m), mt], say(a)], a.values),
		"divide-to-tan": method(["sin θ ≠ 0 on 0 < θ < π, so divide by sin θ: sin θ = %s cos θ" % P(m), "cos θ = 0 would make sin θ = 0 too, so divide by cos θ.", "tan θ = %s" % mt, say(a)], a.values)}
	return out
