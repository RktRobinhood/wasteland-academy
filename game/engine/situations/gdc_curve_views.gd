class_name GdcCurveViews
extends RefCounted
## The views on the `gdc-curve` situation: one builder per unknown of fn-sketch-gdc and
## fn-gdc-features (FAL-420). Builders return what QuadraticViews' builders return (see
## quadratic_views.gd). Paper 2: every number is found on a GDC (GdcKit) and answered to
## 3 s.f. (show "sf"), with 6 s.f. in the working as a GDC shows it; the factorised,
## x-factor and bell-form modes give some exact values, which are then exact.
##
## The sketch unknowns are pick the graph (Q13): four cards (GdcKit.pick), the right
## sketch and three wrong ones, each with one mistake: drawn past the domain, a squashed
## window that sits a turning point on the x-axis, a curve carried through the
## asymptote, upside down or the mirror image. greatest-on-domain is an unknown of both
## types; one builder serves both, with every method either lists.

const NEED := {
	# fn-sketch-gdc
	"sketch-on-domain": {"mode": "mixed", "sketch": true},
	"endpoint-coordinates": {"mode": "mixed"},
	"label-zeros": {"yint": true},
	"label-y-intercept": {"mode": "mixed", "yint": true},
	"label-turning-point": {"turn": "any"},
	"greatest-on-domain": {"mode": "endpoint"},
	"sketch-with-asymptote": {"mode": "asymptote", "sketch": true},
	"window-for-domain": {"mode": "mixed"},
	"judge-a-sketch": {"mode": "mixed", "sketch": true},
	"sketch-from-table": {"mode": "mixed", "sketch": true, "table": true},
	"count-solutions-from-sketch": {"mode": "mixed", "sketch": true},
	"k-for-count": {"mode": "mixed", "sketch": true, "k2": true},
	# fn-gdc-features
	"zeros-gdc": {"yint": true, "far_ok": true},
	"solve-as-zeros": {"mode": "mixed", "shift": true},
	"turning-point-coordinates": {"turn": "any"},
	"extreme-value-only": {"turn": "any"},
	"y-intercept": {"mode": "mixed", "yint": true},
	"zeros-with-x-factor": {"mode": "xfactor"},
	"count-zeros": {"far_ok": true},
	"zero-from-table": {"mode": "mixed", "table": true},
	"use-stored-zeros": {"mode": "mixed", "zeros": 2},
	"constant-from-max": {"mode": "mixed", "turn": "max"},
}

const SIT := "SL2.3.sketch-from-equation"
const ZI := "SL2.4.zeros-intercepts"
const MM := "SL2.4.max-min"
const NS := "SL2.10.number-of-solutions"
const SG := "SL2.10.solve-gdc"


func has(unknown: String) -> bool:
	return NEED.has(unknown)


func need(unknown: String, _rep: String) -> Dictionary:
	return NEED[unknown].duplicate()


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "wrongs", "generic"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "generic"] else null
	out.given = GdcCurveSituation.export(s)
	# What a builder adds for the checker: the labels it drew, the k it chose.
	out.given.merge(out.get("check", {}))
	if not out.has("trap"):
		out.trap = trap(out.answer)
	# Every option's numbers are clear of a 3 s.f. rounding edge.
	out.wrongs = out.wrongs.filter(func(w): return clear(w.values))
	out.generic = out.generic.filter(func(g): return clear(g))
	return out


# ── Helpers ──────────────────────────────────────────────────

static func S(x: Variant) -> String:
	return GdcKit.S(x)


static func W(x: Variant) -> String:
	return GdcKit.W(x)


static func qf(x: float) -> Q:
	return GdcKit.qf(x)


## x rounded to n significant figures, as Q.
static func sfq(x: float, n: int) -> Q:
	return Answer.parse_number(Fmt.sf(x, n).replace("−", "-")).q


static func at(s: Dictionary, x: float) -> float:
	return GdcCurveSituation.at(s, x)


static func lo_of(s: Dictionary) -> float:
	return GdcCurveSituation.lo_x(s)


static func hi_of(s: Dictionary) -> float:
	return s.d2.to_float()


static func fx(s: Dictionary) -> String:
	return "f(x) = " + GdcCurveSituation.text(s)


static func line(s: Dictionary) -> String:
	return GdcCurveSituation.line(s)


static func dom(s: Dictionary) -> String:
	return GdcCurveSituation.domain_text(s)


static func wrong(values: Dictionary, ref: String = "") -> Dictionary:
	return {"values": values, "ref": ref}


## Q7's rounding trap: one number to 2 s.f., or every number of a point or a list.
static func trap(ans: Dictionary) -> Dictionary:
	if ans.kind in ["point", "points2", "xs", "range2"]:
		return Answer.rounding_trap_all(ans)
	return Answer.rounding_trap(ans)


## Whether every number that needs rounding is clear of a 3 s.f. rounding edge.
static func clear(values: Dictionary) -> bool:
	for k in values:
		var v: Variant = values[k]
		if v is Q and not v.is_zero() and Answer.needs_rounding(v) and not Answer.rounds_clearly(v.to_float()):
			return false
	return true


## A number answer to 3 s.f.
static func num(x: Variant, label: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": x if x is Q else qf(x)}, {}, label)
	ans.show = "sf"
	return ans


## The exact value where the family makes one, else the GDC's.
static func exact_or(x: float, exact: Variant) -> Q:
	return exact if exact is Q else qf(x)


## The zeros as Q: exact in the factorised and x-factor families.
static func zero_qs(s: Dictionary) -> Array:
	var out: Array = []
	for z in s.zeros:
		if s.fam == "product":
			out.append(s.p.neg() if absf(z + s.p.to_float()) < 1e-9 else s.q)
		elif s.fam == "xcubic" and z == 0.0:
			out.append(Q.new(0))
		else:
			out.append(qf(z))
	return out


static func xs_ans(qs: Array) -> Dictionary:
	var ans := Answer.make("xs", Answer.xs_of(qs), {"var": "x"})
	ans.show = "sf"
	return ans


## A turning point's coordinates as Q: exact in the bell-form family.
static func turn_q(s: Dictionary, t: Dictionary) -> Array:
	if s.fam == "bellform":
		return [s.h, s.A.add(s.c)]
	return [qf(t.x), qf(t.y)]


## f(0) as Q, exact where it is a decimal.
static func yint_q(s: Dictionary) -> Q:
	match s.fam:
		"explin", "bell":
			return s.A.add(s.c)
		"cubic":
			return s.c
		"trig":
			return s.c if s.fn == "sin" else s.A.add(s.c)
		"product":
			return s.A.mul(s.p).mul(s.q).neg()
		"xcubic":
			return Q.new(0)
		"log":
			if s.r.eq(1):
				return s.c
	return qf(at(s, 0.0))


static func pt(x: float, y: float) -> String:
	return GdcKit.pt(x, y)


static func pt6(x: float, y: float) -> String:
	return GdcKit.pt6(x, y)


static func kind_word(t: Dictionary) -> String:
	return "maximum" if t.kind == "max" else "minimum"


## The least and greatest y of the curve's features (for the log family the
## asymptote's end is cut at y a little below).
static func y_range(s: Dictionary) -> Array:
	var ys: Array = s.turns.map(func(t): return t.y) + s.ends.map(func(e): return e[1]) + [0.0]
	if GdcCurveSituation.open_left(s):
		ys.append(at(s, lo_of(s) + 0.05))
	return [ys.min(), ys.max()]


## The GDC window this curve wants: the domain, and y a little past its features.
static func win(s: Dictionary, pad_x: float = 0.6) -> Array:
	var yr := y_range(s)
	return GdcKit.window(s.d1.to_float(), hi_of(s), yr[0], yr[1], pad_x)


static func win_text(w: Array) -> String:
	return "%s ≤ x ≤ %s and %s ≤ y ≤ %s" % [Fmt.num(w[0]), Fmt.num(w[1]), Fmt.num(w[2]), Fmt.num(w[3])]


## The vertical asymptote of the log family as a dashed line.
static func vlines(s: Dictionary) -> Array:
	return [[s.d1.to_float(), "x = " + Fmt.num(s.d1)]] if GdcCurveSituation.open_left(s) else []


## A GDC screen of the curve on its domain, with these marked points.
static func screen(s: Dictionary, points: Array) -> Dictionary:
	var w := win(s)
	var f := func(x: float) -> float: return at(s, x)
	return Plot.spec([GdcKit.curve(f, lo_of(s), hi_of(s))], points, w[0], w[1], w[2], w[3], [], vlines(s))


## Every feature of the curve as a labelled point: zeros, turning points and ends.
static func labels(s: Dictionary) -> Array:
	var out: Array = []
	for z in s.zeros:
		out.append([z, 0.0, "(%s, 0)" % S(z)])
	for t in s.turns:
		out.append([t.x, t.y, pt(t.x, t.y)])
	for e in s.ends:
		out.append([e[0], e[1], end_pt(e)])
	return out


## The endpoints as unlabelled dots, so a screen shows where the domain stops.
static func end_dots(s: Dictionary) -> Array:
	return s.ends.map(func(e): return [e[0], e[1], ""])


## f′(x) as written, for the derivative method.
static func deriv_text(s: Dictionary) -> String:
	match s.fam:
		"explin":
			return GdcKit.first(s.A.mul(s.b), "e^(%sx)" % GdcKit.lead(s.b)) + GdcKit.join(s.m, "")
		"cubic", "xcubic":
			return GdcKit.first(s.A.mul(3), "x²") + GdcKit.join(s.b.mul(2), "x") + GdcKit.join(s.m, "")
		"bell":
			return GdcKit.first(s.A.mul(s.k).mul(-2), "xe^(−%sx²)" % GdcKit.lead(s.k)) + GdcKit.join(s.m, "")
		"trig":
			var ab: Q = s.A.mul(s.B)
			if s.fn == "sin":
				return GdcKit.first(ab, "cos(%sx)" % GdcKit.lead(s.B)) + GdcKit.join(s.m, "")
			return GdcKit.first(ab.neg(), "sin(%sx)" % GdcKit.lead(s.B)) + GdcKit.join(s.m, "")
		"product":
			return GdcKit.first(s.A, "e^(−%sx)((2x + %s) − %s(x + %s)(x − %s))" % [GdcKit.lead(s.k), Fmt.dec(s.p.sub(s.q)),
				Fmt.dec(s.k), Fmt.num(s.p), Fmt.num(s.q)])
		"log":
			return "%s/(x + %s)" % [Fmt.dec(s.A), Fmt.num(s.r)] + GdcKit.join(s.m, "")
		"bellform":
			var u := "x %s %s" % ["−" if s.h.sign() > 0 else "+", Fmt.dec(s.h.abs_q())]
			return GdcKit.first(s.A.mul(s.k).mul(-2), "(%s)e^(−%s(%s)²)" % [u, GdcKit.lead(s.k), u])
	return "?"


static func graph_step(s: Dictionary) -> String:
	return "Graph y = %s on the GDC, with the window %s." % [GdcCurveSituation.text(s), win_text(win(s))]


## "x = −0.654 or x = 1.46" to 3 s.f., and the same to 6 s.f.
static func zeros3(s: Dictionary) -> String:
	return Answer.xs_list(s.zeros.map(func(z): return "x = " + S(z)))


static func zeros6(s: Dictionary) -> String:
	return Answer.xs_list(s.zeros.map(func(z): return "x = " + W(z)))


## The curve's monotone pieces on [lo, hi]: breakpoints at its turning points there,
## with f at each (±INF at the log family's open end). For counting solutions.
static func pieces(s: Dictionary, lo: float, hi: float) -> Array:
	var xs: Array = [lo]
	var f := func(x: float) -> float: return at(s, x)
	var df := func(x: float) -> float: return GdcCurveSituation.slope(s, x)
	for t in GdcKit.turns(f, df, lo, hi, maxi(48, ceili((hi - lo) * 12.0))):
		xs.append(t.x)
	xs.append(hi)
	var vs: Array = xs.map(func(x): return at(s, x))
	if GdcCurveSituation.open_left(s) and lo <= lo_of(s) + 1e-6:
		vs[0] = -INF if s.A.sign() > 0 else INF
	return [xs, vs]


## How many solutions f(x) = k has on [lo, hi] (the domain unless given): one per
## monotone piece that reaches k, a turning point at height k counted once.
static func solutions(s: Dictionary, k: float, lo: float = NAN, hi: float = NAN) -> int:
	var a := lo_of(s) if is_nan(lo) else lo
	var b := hi_of(s) if is_nan(hi) else hi
	return count_in(pieces(s, a, b)[1], k)


## How many solutions on monotone pieces with these values at their breakpoints.
static func count_in(vs: Array, k: float) -> int:
	var n := 0
	for i in vs.size() - 1:
		if k >= minf(vs[i], vs[i + 1]) - 1e-12 and k <= maxf(vs[i], vs[i + 1]) + 1e-12:
			n += 1
	for i in range(1, vs.size() - 1):
		if absf(vs[i] - k) < 1e-9:
			n -= 1
	return n


## The k for which f(x) = k has exactly n solutions on [lo, hi], as one interval
## {"lo", "hi", "lo_in", "hi_in"}, or {} if it is not one bounded interval.
static func k_set(s: Dictionary, n: int, lo: float = NAN, hi: float = NAN) -> Dictionary:
	var a := lo_of(s) if is_nan(lo) else lo
	var b := hi_of(s) if is_nan(hi) else hi
	var levels: Array = []
	var vs: Array = pieces(s, a, b)[1]
	for v in vs:
		if is_finite(v) and not levels.any(func(l): return absf(l - v) < 1e-9):
			levels.append(v)
	levels.sort()
	# Test k below, at and between the levels, in order.
	var tests: Array = [[levels[0] - 1.0, false]]
	for i in levels.size():
		tests.append([levels[i], true])
		tests.append([levels[i] + 1.0 if i == levels.size() - 1 else (levels[i] + levels[i + 1]) / 2.0, false])
	var runs: Array = []
	var cur: Dictionary = {}
	for i in tests.size():
		var ok := count_in(vs, tests[i][0]) == n
		if ok and cur.is_empty():
			if i == 0 or i == tests.size() - 1:
				return {}
			# A run starts at a level (included) or in a gap (its lower level left out).
			cur = {"lo": tests[i][0] if tests[i][1] else tests[i - 1][0], "lo_in": tests[i][1]}
		elif not ok and not cur.is_empty():
			cur.hi = tests[i][0] if tests[i][1] else tests[i - 1][0]
			cur.hi_in = not tests[i][1]
			runs.append(cur)
			cur = {}
	if not cur.is_empty() or runs.size() != 1 or runs[0].hi - runs[0].lo < 0.5:
		return {}
	return runs[0]


static func k_ans(ks: Dictionary) -> Dictionary:
	var ans := Answer.make("range2", {"lo": qf(ks.lo), "r1": "≤" if ks.lo_in else "<", "r2": "≤" if ks.hi_in else "<",
		"hi": qf(ks.hi)}, {"var": "k"})
	ans.show = "sf"
	return ans


# ── Pick the graph ───────────────────────────────────────────

## The window every card of this curve shares: room past the domain to show a
## curve carried on past it.
static func card_win(s: Dictionary) -> Array:
	var w := win(s, 1.8)
	return w


static func card_of(s: Dictionary, curves: Array, dots: Array, vls: Array = []) -> Dictionary:
	return GdcKit.card(curves, dots, card_win(s), vls)


static func feature_dots(s: Dictionary, g: Callable) -> Array:
	var out: Array = []
	for z in s.zeros:
		out.append([z, 0.0, ""])
	for t in s.turns:
		out.append([t.x, g.call(t.x), ""])
	for e in s.ends:
		out.append([e[0], g.call(e[0]), ""])
	return out


static func right_card(s: Dictionary) -> Dictionary:
	var f := func(x: float) -> float: return at(s, x)
	return card_of(s, [GdcKit.curve(f, lo_of(s), hi_of(s))], feature_dots(s, f), vlines(s))


## Carried on past the domain's ends, with no endpoints marked (SL2.3#1).
static func past_domain(s: Dictionary) -> Dictionary:
	var f := func(x: float) -> float: return at(s, x)
	var lo: float = lo_of(s) if GdcCurveSituation.open_left(s) else s.d1.to_float() - 1.5
	var dots: Array = []
	for z in s.zeros:
		dots.append([z, 0.0, ""])
	for t in s.turns:
		dots.append([t.x, t.y, ""])
	return {"graph": card_of(s, [GdcKit.curve(f, lo, hi_of(s) + 1.5)], dots, vlines(s)), "ref": SIT + "#1",
		"mistake": "past-domain", "why": "it carries on past the end of the domain, with no endpoint marked"}


## A squashed window: the turning point nearest the x-axis sits on it, like a zero (SL2.3#2).
static func squashed(s: Dictionary) -> Dictionary:
	var t: Dictionary = s.turns[0]
	for u in s.turns:
		if absf(u.y) < absf(t.y):
			t = u
	var dy: float = t.y
	var g := func(x: float) -> float: return at(s, x) - dy
	var dots: Array = [[t.x, 0.0, ""]]
	for e in s.ends:
		dots.append([e[0], e[1] - dy, ""])
	var out := {"graph": card_of(s, [GdcKit.curve(g, lo_of(s), hi_of(s))], dots, vlines(s)), "ref": SIT + "#2",
		"mistake": "squashed", "why": "its %s sits on the x-axis, as a squashed window makes it look, so it looks like a zero" % kind_word(t)}
	out.shift = dy
	return out


static func reflected(s: Dictionary) -> Dictionary:
	var g := func(x: float) -> float: return -at(s, x)
	var dots: Array = []
	for z in s.zeros:
		dots.append([z, 0.0, ""])
	for t in s.turns:
		dots.append([t.x, -t.y, ""])
	for e in s.ends:
		dots.append([e[0], -e[1], ""])
	return {"graph": card_of(s, [GdcKit.curve(g, lo_of(s), hi_of(s))], dots, vlines(s)), "ref": "",
		"mistake": "reflected", "why": "it is upside down: its maximum and minimum have swapped"}


static func mirrored(s: Dictionary) -> Dictionary:
	var g := func(x: float) -> float: return at(s, -x)
	var dots: Array = []
	for z in s.zeros:
		dots.append([-z, 0.0, ""])
	for t in s.turns:
		dots.append([-t.x, t.y, ""])
	for e in s.ends:
		dots.append([-e[0], e[1], ""])
	var vls: Array = vlines(s).map(func(v): return [-v[0], ""])
	return {"graph": card_of(s, [GdcKit.curve(g, -hi_of(s), -lo_of(s))], dots, vls), "ref": "",
		"mistake": "mirrored", "why": "it is the mirror image: its features are on the wrong side of the y-axis"}


## The log curve carried on through its asymptote x = −r (SL2.3#0).
static func through_asymptote(s: Dictionary) -> Dictionary:
	var r: float = s.r.to_float()
	var co: Array = s.co
	var left := func(x: float) -> float: return co[0] * log(-(x + r)) + co[2] * x + co[3]
	var f := func(x: float) -> float: return at(s, x)
	var dots := feature_dots(s, f)
	return {"graph": card_of(s, [GdcKit.curve(left, -r - 1.5, -r - 0.001), GdcKit.curve(f, lo_of(s), hi_of(s))], dots, vlines(s)),
		"ref": SIT + "#0", "mistake": "through-asymptote", "why": "it carries on through the asymptote x = %s, where ln(x + %s) has no value" % [Fmt.num(s.d1), Fmt.num(s.r)]}


## Three wrong cards: the must-haves, then one of the rest.
static func wrong_cards(s: Dictionary, rng: Seeded, must: Array) -> Array:
	var others: Array = [reflected(s), mirrored(s)]
	return must + [others[rng.int_in(0, 1)]]


static func pick_out(s: Dictionary, rng: Seeded, must: Array) -> Dictionary:
	var p := GdcKit.pick(right_card(s), wrong_cards(s, rng, must), rng)
	return {"answer": p.answer, "graphs": p.graphs}


static func feature_list(s: Dictionary) -> String:
	var parts: Array = []
	if not s.zeros.is_empty():
		parts.append(("a zero at " if s.zeros.size() == 1 else "zeros at ") + Answer.xs_list(s.zeros.map(func(z): return S(z))))
	for t in s.turns:
		parts.append("a local %s at %s" % [kind_word(t), pt(t.x, t.y)])
	for e in s.ends:
		parts.append("an endpoint at %s" % end_pt(e))
	return ", ".join(parts)


## An endpoint, its whole-number x as it is: "(−4, 12.8)".
static func end_pt(e: Array) -> String:
	return "(%s, %s)" % [Fmt.num(roundi(e[0])), S(e[1])]


# ── fn-sketch-gdc ────────────────────────────────────────────

func u_sketch_on_domain(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := pick_out(s, rng, [past_domain(s), squashed(s)])
	var final: String = "So the sketch is %s: it stops at both endpoints and shows every feature." % out.answer.values.v
	out.merge({
		"asked": "Which graph is the sketch of y = f(x)?", "lines": [line(s)],
		"methods": {
			"gdc-transfer": {"result": out.answer.values, "steps": [graph_step(s),
				"The GDC gives " + feature_list(s) + ".", final]},
			"table-of-values": {"result": out.answer.values, "steps": [
				"A table of f from x = %s to x = %s shows where f changes sign and where it turns." % [Fmt.num(s.d1), Fmt.num(s.d2)],
				"Refined on the GDC: " + feature_list(s) + ".", final]},
		}})
	return out


func u_endpoint_coordinates(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var e1: Array = s.ends[0]
	var e2: Array = s.ends[1]
	var vals := {"x1": s.d1, "y1": qf(e1[1]), "x2": s.d2, "y2": qf(e2[1])}
	var ans := Answer.make("points2", vals)
	ans.show = "sf"
	var final := "So the endpoints are %s." % Answer.text(ans)
	var d1: float = s.d1.to_float()
	var d2: float = s.d2.to_float()
	var past := {"x1": Q.new(int(d1) - 1), "y1": qf(at(s, d1 - 1.0)), "x2": Q.new(int(d2) + 1), "y2": qf(at(s, d2 + 1.0))}
	var t: Dictionary = s.turns[0]
	var gen: Array = [{"x1": s.d1, "y1": qf(-e1[1]), "x2": s.d2, "y2": qf(-e2[1])},
		{"x1": s.d1, "y1": qf(e2[1]), "x2": s.d2, "y2": qf(e1[1])},
		{"x1": qf(t.x), "y1": qf(t.y), "x2": s.d2, "y2": qf(e2[1])},
		{"x1": s.d1, "y1": qf(at(s, -d1)), "x2": s.d2, "y2": qf(at(s, -d2))}]
	var ev := "f(%s) = %s and f(%s) = %s" % [Fmt.num(s.d1), W(e1[1]), Fmt.num(s.d2), W(e2[1])]
	return {
		"asked": "Find the coordinates of the endpoints of the graph of f.", "lines": [line(s)], "answer": ans,
		"wrongs": [wrong(past, SIT + "#1")], "generic": gen,
		"methods": {
			"gdc-transfer": {"result": ans.values, "steps": [graph_step(s),
				"Trace to each end of the domain, or evaluate there: " + ev + ".", final]},
			"key-features-algebra": {"result": ans.values, "steps": [
				"The endpoints are at the ends of the domain, x = %s and x = %s." % [Fmt.num(s.d1), Fmt.num(s.d2)],
				"Substitute each into f: " + ev + ".", final]},
			"table-of-values": {"result": ans.values, "steps": [
				"Start a GDC table at x = %s with a step of %s, so its first and last rows are the ends." % [Fmt.num(s.d1), Fmt.num(s.d2.sub(s.d1))],
				"The rows give " + ev + ".", final]},
		},
	}


func u_label_zeros(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var qs := zero_qs(s)
	var ans := xs_ans(qs)
	var final := "So the zeros are " + Answer.text(ans) + "."
	var wrongs: Array = []
	# f(0) labelled on the x-axis as a zero, in place of the zero nearest the y-axis.
	var y0 := yint_q(s)
	var swap := qs.duplicate()
	var near := 0
	for i in qs.size():
		if absf(qs[i].to_float()) < absf(qs[near].to_float()):
			near = i
	swap[near] = y0
	wrongs.append(wrong(Answer.xs_of(swap), ZI + "#0"))
	if s.fam == "product":
		wrongs.append(wrong(Answer.xs_of([s.p, s.q.neg()]), ZI + "#1"))
	var gen: Array = [Answer.xs_of(qs.map(func(q): return q.neg())), Answer.xs_of(s.turns.map(func(t): return qf(t.x))),
		Answer.xs_of(qs.slice(0, qs.size() - 1) if qs.size() > 1 else [qf(s.turns[0].x)])]
	var out := {"asked": "Find the x-intercepts of the graph of f.", "lines": [line(s)], "answer": ans, "wrongs": wrongs, "generic": gen}
	if rep == "graph":
		out.lines = ["The graph of %s is shown." % line(s)]
		out.graph = screen(s, end_dots(s))
	var gdc := [graph_step(s), "Use the zero (root) tool between each pair of sign changes: " + zeros6(s) + ".", final]
	var fac: Array
	if s.fam == "product":
		fac = ["f is a product with e^(−%sx), which is never 0, so f(x) = 0 only where a factor is 0." % GdcKit.lead(s.k),
			"x + %s = 0 or x − %s = 0." % [Fmt.num(s.p), Fmt.num(s.q)], final]
	else:
		fac = ["f(x) is not a product of factors, so there are no factors to read: this method fails here.",
			"Use the GDC's zero tool instead: " + zeros6(s) + ".", final]
	out.methods = {
		"gdc-zero": {"result": ans.values, "steps": gdc},
		"factorised-read": {"result": ans.values, "steps": fac},
		"graph-read": {"result": ans.values, "steps": [
			"Reading the sketch gives each zero to about 1 s.f., not the 3 s.f. the label needs.",
			"So refine each with the GDC's zero tool: " + zeros6(s) + ".", final]},
	}
	return out


func u_label_y_intercept(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y0 := yint_q(s)
	var ans := Answer.make("yint", {"y": y0})
	ans.show = "sf"
	var final := "So the y-intercept is %s." % Answer.text(ans)
	var gen: Array = [{"y": s.c}, {"y": y0.neg()}, {"y": qf(at(s, 1.0))}, {"y": s.A}, {"y": qf(s.zeros[0])}]
	return {
		"asked": "Find the y-intercept of the graph of f.", "lines": [line(s)], "answer": ans, "generic": gen,
		"methods": {"set-equal-zero": {"result": ans.values, "steps": [
			"The y-intercept is where x = 0, which is inside the domain.", "f(0) = %s." % zero_sub(s), final]}},
	}


## f(0) worked out: "2e^(0) + 0 − 1 = 1".
static func zero_sub(s: Dictionary) -> String:
	var y0 := yint_q(s)
	match s.fam:
		"explin", "bell":
			return "%s × 1 %s = %s" % [Fmt.dec(s.A), GdcKit.join(s.c, ""), Fmt.dec(y0)]
		"trig":
			return "%s × %s %s = %s" % [Fmt.dec(s.A), "0" if s.fn == "sin" else "1", GdcKit.join(s.c, ""), Fmt.dec(y0)]
		"cubic":
			return Fmt.dec(y0)
		"product":
			return "%s × %s × (−%s) × 1 = %s" % [Fmt.dec(s.A), Fmt.num(s.p), Fmt.num(s.q), Fmt.dec(y0)]
	return W(y0.to_float())


## The turning point a view asks about: one of them, by the stream.
static func pick_turn(s: Dictionary, rng: Seeded) -> Dictionary:
	return s.turns[rng.int_in(0, s.turns.size() - 1)]


func u_label_turning_point(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _turning_point(rep, s, rng, "label")


func _turning_point(rep: String, s: Dictionary, rng: Seeded, style: String) -> Dictionary:
	var t := pick_turn(s, rng)
	var tq := turn_q(s, t)
	var ans := Answer.make("point", {"x": tq[0], "y": tq[1]})
	ans.show = "sf"
	var word := kind_word(t)
	var final := "So the local %s is at %s." % [word, Answer.text(ans)]
	var wrongs: Array = [wrong({"x": tq[0], "y": Q.new(0)}, MM + "#0")]
	if style == "coords":
		wrongs.append(wrong({"x": sfq(t.x, 1), "y": sfq(t.y, 1)}, MM + "#2"))
	var gen: Array = [{"x": tq[1], "y": tq[0]}, {"x": tq[0], "y": tq[1].neg()}]
	for u in s.turns:
		if u != t:
			gen.append({"x": qf(u.x), "y": qf(u.y)})
	gen.append({"x": qf(s.zeros[0]), "y": Q.new(0)})
	var asked := "Find the coordinates of the local %s of the graph of f." % word
	var out := {"asked": asked, "lines": [line(s)], "answer": ans, "wrongs": wrongs, "generic": gen}
	if rep == "graph":
		out.lines = ["The graph of %s is shown." % line(s)]
		out.graph = screen(s, end_dots(s))
	var tool := "Use the %s tool near x = %s: it gives %s." % [word, S(t.x), pt6(t.x, t.y)]
	var form: Array
	if s.fam == "bellform":
		form = ["e^(−%s(x %s %s)²) is largest, 1, where the bracket is 0: x = %s." % [GdcKit.lead(s.k),
			"−" if s.h.sign() > 0 else "+", Fmt.dec(s.h.abs_q()), Fmt.dec(s.h)],
			"Then y = %s × 1 %s = %s." % [Fmt.dec(s.A), GdcKit.join(s.c, ""), Fmt.dec(s.A.add(s.c))], final]
	else:
		form = ["f is not a transformed parent such as a(x − h)² + k, so the turning point can't be read off: this method fails here.",
			tool, final]
	out.methods = {
		"gdc-max-min": {"result": ans.values, "steps": [graph_step(s), tool, final]},
		"derivative-zero": {"result": ans.values, "steps": [
			"f′(x) = " + deriv_text(s) + ".",
			"Solve f′(x) = 0 on the GDC: x = %s, and f(%s) = %s." % [W(t.x), W(t.x), W(t.y)], final]},
		"read-from-form": {"result": ans.values, "steps": form},
	}
	return out


func u_greatest_on_domain(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var top: Dictionary = s.hi
	var ans := num(top.y)
	var final := "So the greatest value of f on the domain is %s, at the endpoint x = %s." % [Answer.text(ans), Fmt.num(top.x)]
	var maxes: Array = s.turns.filter(func(t): return t.kind == "max")
	var lmax: Dictionary = maxes[0]
	var other: Array = s.ends[0] if s.ends[0][0] != top.x else s.ends[1]
	var gen: Array = [{"v": qf(top.x)}, {"v": qf(other[1])}, {"v": qf(lmax.x)}]
	if not s.lo.is_empty():
		gen.append({"v": qf(s.lo.y)})
	var out := {"asked": "Find the greatest value of f(x) on the domain.", "lines": [line(s)], "answer": ans,
		"wrongs": [wrong({"v": qf(lmax.y)}, MM + "#1")], "generic": gen}
	if rep == "graph":
		out.lines = ["The graph of %s is shown, with its turning points and endpoints labelled." % line(s)]
		out.graph = screen(s, labels(s).filter(func(p): return p[1] != 0.0))
	var ends := "f(%s) = %s and f(%s) = %s" % [Fmt.num(s.d1), W(s.ends[0][1]), Fmt.num(s.d2), W(s.ends[1][1])]
	var compare := "The local maximum is %s, but %s: the endpoint is higher." % [W(lmax.y), ends]
	out.methods = {
		"gdc-max-min": {"result": ans.values, "steps": [graph_step(s),
			"The maximum tool gives the local maximum %s. Evaluate the ends too: %s." % [pt6(lmax.x, lmax.y), ends], final]},
		"graph-read": {"result": ans.values, "steps": [
			"On the graph the highest point is at an end of the domain, not at the turning point.",
			"Its label gives f(%s) = %s; the local maximum is only %s." % [Fmt.num(top.x), S(top.y), S(lmax.y)], final]},
		"endpoint-evaluation": {"result": ans.values, "steps": [
			"The greatest value is at a turning point or an endpoint. The GDC's maximum tool gives the turning value %s." % W(lmax.y),
			compare, final]},
	}
	return out


func u_sketch_with_asymptote(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := pick_out(s, rng, [through_asymptote(s), past_domain(s)])
	var r := Fmt.num(s.r)
	var final: String = "So the sketch is %s: it rises from the asymptote x = %s and stops at x = %s." % [out.answer.values.v,
		Fmt.num(s.d1), Fmt.num(s.d2)]
	if s.A.sign() < 0:
		final = "So the sketch is %s: it comes down from the asymptote x = %s and stops at x = %s." % [out.answer.values.v,
			Fmt.num(s.d1), Fmt.num(s.d2)]
	var asy := "ln(x + %s) has no value for x ≤ −%s, so x = %s is a vertical asymptote and the graph is only to its right." % [r, r, Fmt.num(s.d1)]
	out.merge({
		"asked": "Which graph is the sketch of y = f(x)?", "lines": [line(s)],
		"methods": {
			"gdc-transfer": {"result": out.answer.values, "steps": [graph_step(s), "The GDC gives " + feature_list(s) + ".", final]},
			"key-features-algebra": {"result": out.answer.values, "steps": [asy,
				"Near the asymptote %s; the GDC gives %s." % ["f falls without limit" if s.A.sign() > 0 else "f rises without limit", feature_list(s)], final]},
			"transform-parent": {"result": out.answer.values, "steps": [
				"%s·ln(x + %s) is ln x moved %s left%s, so its asymptote is x = %s." % [Fmt.dec(s.A), r, r,
					" and flipped" if s.A.sign() < 0 else "", Fmt.num(s.d1)],
				"Adding %sx%s tilts it into one turning point: the GDC gives %s." % [Fmt.dec(s.m), GdcKit.join(s.c, ""), feature_list(s)], final]},
			"undefined-input": {"result": out.answer.values, "steps": [asy, "So no graph can cross x = %s or have a point left of it." % Fmt.num(s.d1), final]},
		}})
	return out


func u_window_for_domain(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var yr := [s.lo.y, s.hi.y]
	var y0 := floori(yr[0]) - 1
	var y1 := ceili(yr[1]) + 1
	var d1: int = s.d1.n
	var d2: int = s.d2.n
	var right := wt(d1, d2, y0, y1)
	var wrongs: Array = [wrong({"v": wt(-10, 10, -10, 10)}, SIT + "#2")]
	var gen: Array = [wt(d1, d2, y0, floori(yr[1]) - 1), wt(d1, d2 - 2, y0, y1), wt(d1, d2, 0, y1) if y0 < 0 else wt(d1, d2, ceili(yr[0]) + 1, y1),
		wt(y0, y1, d1, d2)]
	var out := LogFunctionViews.choice(right, wrongs, gen)
	var lines := [line(s)]
	if rep == "words":
		lines = ["A GDC is used to graph f(x) = %s for %s. On this domain the least value of f is about %s and the greatest about %s." % [
			GdcCurveSituation.text(s), dom(s), S(yr[0]), S(yr[1])]]
	var final: String = "So the window is " + right + "."
	out.merge({
		"asked": "Which GDC window shows the whole graph on its domain without squashing it?", "lines": lines,
		"methods": {"gdc-transfer": {"result": out.answer.values, "steps": [
			"Set x from one end of the domain to the other: %d to %d." % [d1, d2],
			"The least and greatest values are %s and %s, so y from %d to %d holds them with a little room." % [S(yr[0]), S(yr[1]), y0, y1],
			final]}}})
	return out


static func wt(x0: int, x1: int, y0: int, y1: int) -> String:
	return "Xmin = %s, Xmax = %s, Ymin = %s, Ymax = %s" % [Fmt.num(x0), Fmt.num(x1), Fmt.num(y0), Fmt.num(y1)]


func u_judge_a_sketch(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var feats: Array = []
	for z in s.zeros:
		feats.append({"x": z, "y": 0.0, "name": "the zero at x ≈ %s" % S(z), "kind": "zero"})
	for t in s.turns:
		feats.append({"x": t.x, "y": t.y, "name": "the local " + kind_word(t), "kind": "turn"})
	for i in s.ends.size():
		feats.append({"x": s.ends[i][0], "y": s.ends[i][1], "name": "the %s endpoint" % ["left", "right"][i], "kind": "end"})
	for f in feats:
		f.label = pt(f.x, f.y) if f.kind == "turn" else ("(%s, 0)" % S(f.x) if f.kind == "zero" else end_pt([f.x, f.y]))
	# The wrong label: a turning point to 2 s.f., its coordinates swapped, or an endpoint's sign.
	var bad_kind: String = ["2sf", "swap", "sign"][rng.int_in(0, 2)]
	var turns: Array = feats.filter(func(f): return f.kind == "turn")
	var ends: Array = feats.filter(func(f): return f.kind == "end")
	var bad: Dictionary = turns[rng.int_in(0, turns.size() - 1)] if bad_kind != "sign" else ends[rng.int_in(0, ends.size() - 1)]
	match bad_kind:
		"2sf":
			bad.label = "(%s, %s)" % [Fmt.sf(bad.x, 2), Fmt.sf(bad.y, 2)]
			bad.why = "it is to 2 s.f.: the GDC gives %s" % pt(bad.x, bad.y)
		"swap":
			bad.label = "(%s, %s)" % [S(bad.y), S(bad.x)]
			bad.why = "its coordinates are the wrong way round: it should be %s" % pt(bad.x, bad.y)
		"sign":
			bad.label = end_pt([bad.x, -bad.y])
			bad.why = "f(%s) = %s, so the sign of y is wrong" % [Fmt.num(roundi(bad.x)), S(bad.y)]
	bad.mistake = bad_kind
	# Four labels to choose from: the wrong one and three right ones.
	var good: Array = rng.shuffled(feats.filter(func(f): return f != bad)).slice(0, 3)
	var shown: Array = [bad] + good
	var opt := func(f: Dictionary) -> String: return "The label %s at %s" % [f.label, f.name]
	var right: String = opt.call(bad)
	var out := LogFunctionViews.choice(right, [], good.map(func(f): return opt.call(f)))
	var pts: Array = feats.map(func(f): return [f.x, f.y, f.label])
	var final: String = "So the wrong label is %s: %s." % [bad.label, bad.why]
	out.merge({
		"asked": "A student sketched y = f(x) and labelled its features. Which label is wrong?",
		"lines": ["The student's sketch of %s is shown." % line(s)], "graph": screen(s, pts),
		"check": {"labels": shown.map(func(f): return {"label": f.label, "name": f.name, "x": f.x, "y": f.y, "bad": f == bad})},
		"methods": {
			"gdc-transfer": {"result": out.answer.values, "steps": [graph_step(s), "The GDC gives " + feature_list(s) + ".",
				"Compare each label with those values to 3 s.f.", final]},
			"gdc-max-min": {"result": out.answer.values, "steps": [
				"Check the turning points with the maximum and minimum tools, and the ends by evaluating f.",
				"The GDC gives " + feature_list(s) + ".", final]},
		}})
	return out


func u_sketch_from_table(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := pick_out(s, rng, [past_domain(s), squashed(s)])
	var tb: Dictionary = s.table
	var rows := []
	for z in s.zeros:
		var i := floori((z - tb.xs[0].to_float()) / tb.step.to_float())
		rows.append("x = %s and x = %s" % [Fmt.dec(tb.xs[i]), Fmt.dec(tb.xs[i + 1])])
	var between := "f changes sign between " + Answer.xs_list(rows) + ", so a zero lies in each of those intervals."
	var final: String = "So the sketch is %s." % out.answer.values.v
	out.merge({
		"asked": "The table shows values of f(x) = %s on %s. Which graph is the sketch of y = f(x)?" % [GdcCurveSituation.text(s), dom(s)],
		"lines": [], "table": {"xs": tb.xs, "ys": tb.ys},
		"methods": {
			"table-of-values": {"result": out.answer.values, "steps": [between,
				"The values rise and fall as the sketch must: it has %s." % feature_list(s), final]},
			"gdc-zero": {"result": out.answer.values, "steps": [between, "The zero tool refines them: " + zeros6(s) + ".", final]},
			"graph-read": {"result": out.answer.values, "steps": [
				"Plot the rows and join them smoothly, stopping at x = %s and x = %s." % [Fmt.dec(tb.xs[0]), Fmt.dec(tb.xs[tb.xs.size() - 1])],
				between, final]},
		}})
	return out


func u_count_solutions_from_sketch(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var touch := rng.chance(0.4)
	var t := pick_turn(s, rng)
	var k: float
	var k_text: String
	if touch:
		k = t.y
		k_text = "the local %s value of f" % kind_word(t)
	else:
		k = _k_between(s, rng)
		k_text = Fmt.dec(qf(k))
	var n := solutions(s, k)
	var ans := Answer.make("number", {"v": Q.new(n)})
	ans.exact = true
	var wrongs: Array = []
	if touch:
		wrongs.append(wrong({"v": Q.new(n + 1)}, NS + "#0"))
	var ext := solutions(s, k, lo_of(s) if GdcCurveSituation.open_left(s) else s.d1.to_float() - 3.0, hi_of(s) + 3.0)
	if ext != n:
		wrongs.append(wrong({"v": Q.new(ext)}, NS + "#1"))
	var gen: Array = [{"v": Q.new(n + 1)}, {"v": Q.new(maxi(n - 1, 0))}, {"v": Q.new(n + 2)}, {"v": Q.new(s.zeros.size())}, {"v": Q.new(0)}]
	var final := "So f(x) = %s has %d solution%s on the domain." % [k_text if not touch else "k", n, "" if n == 1 else "s"]
	var asked := "How many solutions does f(x) = %s have on the domain?" % k_text
	if touch:
		asked = "Let k be the local %s value of f. How many solutions does f(x) = k have on the domain?" % kind_word(t)
	var out := {"asked": asked, "answer": ans, "wrongs": wrongs, "generic": gen, "check": {"k": qf(k), "touch": touch}}
	if rep == "graph":
		out.lines = ["The sketch of %s is shown, with its turning points and endpoints labelled." % line(s)]
		out.graph = screen(s, labels(s).filter(func(p): return p[1] != 0.0))
	else:
		out.lines = ["f(x) = %s, for %s, has %s." % [GdcCurveSituation.text(s), dom(s), feature_list(s)]]
	var sweep := "Draw the line y = %s across the sketch and count where it meets the curve, endpoints included." % (S(k) if not touch else "k")
	var touch_note := " At the turning point the line only touches the curve: that is one solution, not two." if touch else ""
	out.methods = {
		"horizontal-line-sweep": {"result": ans.values, "steps": [sweep, "It meets the curve %d time%s.%s" % [n, "" if n == 1 else "s", touch_note], final]},
		"gdc-graph": {"result": ans.values, "steps": [
			"Graph y = f(x) and y = %s on the domain." % (S(k) if not touch else "k"),
			"The intersect tool finds %d meeting point%s.%s" % [n, "" if n == 1 else "s", touch_note], final]},
	}
	return out


## A k with one decimal place between two of the curve's levels, at least 0.3 from each.
static func _k_between(s: Dictionary, rng: Seeded) -> float:
	var levels: Array = s.turns.map(func(t): return t.y) + s.ends.map(func(e): return e[1])
	levels.sort()
	var lo: float = levels[0]
	var hi: float = levels[levels.size() - 1]
	for i in 200:
		var k := rng.int_in(roundi(lo * 10) + 1, roundi(hi * 10) - 1) / 10.0
		if levels.all(func(l): return absf(l - k) >= 0.3):
			return k
	return (lo + hi) / 2.0


func u_k_for_count(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ks := k_set(s, 2)
	var ans := k_ans(ks)
	var final := "So f(x) = k has exactly two solutions for " + Answer.text(ans) + "."
	var wrongs: Array = []
	var ext := k_set(s, 2, lo_of(s) if GdcCurveSituation.open_left(s) else s.d1.to_float() - 3.0, hi_of(s) + 3.0)
	if not ext.is_empty():
		wrongs.append(wrong(k_ans(ext).values, NS + "#1"))
	var v: Dictionary = ans.values
	var flip := func(r: String) -> String: return "<" if r == "≤" else "≤"
	var gen: Array = [{"lo": v.lo, "r1": flip.call(v.r1), "r2": v.r2, "hi": v.hi}, {"lo": v.lo, "r1": v.r1, "r2": flip.call(v.r2), "hi": v.hi},
		{"lo": v.lo, "r1": flip.call(v.r1), "r2": flip.call(v.r2), "hi": v.hi}]
	if not s.lo.is_empty():
		gen.append({"lo": qf(s.lo.y), "r1": "≤", "r2": "≤", "hi": qf(s.hi.y)})
	var levels := ", ".join(s.turns.map(func(t): return "the %s %s" % [kind_word(t), S(t.y)]) + s.ends.map(func(e): return "f(%s) = %s" % [Fmt.num(roundi(e[0])), S(e[1])]))
	var n_lo := solutions(s, ks.lo)
	var n_hi := solutions(s, ks.hi)
	var edges := "For k between %s and %s the line y = k meets the curve twice. At k = %s it meets it %d time%s, and at k = %s, %d time%s." % [
		S(ks.lo), S(ks.hi), S(ks.lo), n_lo, "" if n_lo == 1 else "s", S(ks.hi), n_hi, "" if n_hi == 1 else "s"]
	return {
		"asked": "Find the values of k for which f(x) = k has exactly two solutions on the domain.",
		"lines": ["The sketch of %s is shown, with its turning points and endpoints labelled." % line(s)],
		"graph": screen(s, labels(s).filter(func(p): return p[1] != 0.0)), "answer": ans, "wrongs": wrongs, "generic": gen,
		"methods": {
			"graph-read": {"result": ans.values, "steps": ["The levels that matter are the turning values and the endpoint values: " + levels + ".",
				edges, final]},
			"horizontal-line-sweep": {"result": ans.values, "steps": ["Sweep a horizontal line y = k up the sketch and count where it meets the curve.",
				edges, final]},
			"turning-point-boundaries": {"result": ans.values, "steps": ["The count changes only at a turning value or an endpoint value: " + levels + ".",
				edges, final]},
		},
	}


# ── fn-gdc-features ──────────────────────────────────────────

func u_zeros_gdc(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var qs := zero_qs(s)
	var ans := xs_ans(qs)
	var final := "So the zeros are " + Answer.text(ans) + "."
	var wrongs: Array = []
	var inside: Array = qs.filter(func(q): return absf(q.to_float()) <= 10.0)
	if inside.size() < qs.size() and not inside.is_empty():
		wrongs.append(wrong(Answer.xs_of(inside), SG + "#0"))
	var swap := qs.duplicate()
	swap[0] = yint_q(s)
	wrongs.append(wrong(Answer.xs_of(swap), ZI + "#0"))
	var gen: Array = [Answer.xs_of(qs.map(func(q): return q.neg())), Answer.xs_of(s.turns.map(func(t): return qf(t.x))),
		Answer.xs_of(qs.slice(1) if qs.size() > 1 else [qf(s.turns[0].x)])]
	var out := {"asked": "Find every zero of f.", "lines": [line(s)], "answer": ans, "wrongs": wrongs, "generic": gen}
	if rep == "graph":
		out.lines = ["The graph of %s is shown." % line(s)]
		out.graph = screen(s, end_dots(s))
	var whole := "Set the x-window to the whole domain, %s, not the default −10 to 10." % dom(s)
	out.methods = {
		"gdc-zero": {"result": ans.values, "steps": [graph_step(s), whole, "The zero tool at each crossing: " + zeros6(s) + ".", final]},
		"graph-read": {"result": ans.values, "steps": ["Reading a graph gives each zero to about 1 s.f.: this method fails for 3 s.f.",
			"Use the zero tool instead: " + zeros6(s) + ".", final]},
		"zero-of-difference": {"result": ans.values, "steps": [
			"f(x) = 0 has no algebraic solution, so solve it on the GDC as the zeros of y = f(x).", whole,
			"The solver gives " + zeros6(s) + ".", final]} if s.fam != "product" else {"result": ans.values, "steps": [
			"f(x) = 0 is the zeros of y = f(x): graph it on the domain.", "The solver gives " + zeros6(s) + ".", final]},
	}
	return out


func u_solve_as_zeros(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var qs := zero_qs(s)
	var ans := xs_ans(qs)
	var k: Q = s.k_shift
	var eq := "%s = %s" % [GdcCurveSituation.text(s, k), Fmt.dec(k)]
	var final := "So the solutions are " + Answer.text(ans) + "."
	var gen: Array = [Answer.xs_of(qs.map(func(q): return q.neg())), Answer.xs_of(s.turns.map(func(t): return qf(t.x))),
		Answer.xs_of(qs.slice(1) if qs.size() > 1 else [qf(s.turns[0].x)])]
	var g := GdcCurveSituation.text(s, k)
	return {
		"asked": "Solve %s, for %s." % [eq, dom(s)], "lines": [eq], "answer": ans, "generic": gen,
		"methods": {
			"zero-of-difference": {"result": ans.values, "steps": [
				"Subtract %s from both sides: %s = 0." % [Fmt.dec(k), GdcCurveSituation.text(s)],
				"Its zeros on the domain, from the GDC: " + zeros6(s) + ".", final]},
			"intersect-two-graphs": {"result": ans.values, "steps": [
				"Graph y = %s and y = %s on the domain." % [g, Fmt.dec(k)],
				"The intersect tool gives " + zeros6(s) + ".", final]},
		},
	}


func u_turning_point_coordinates(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _turning_point(rep, s, rng, "coords")


func u_extreme_value_only(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var t := pick_turn(s, rng)
	var tq := turn_q(s, t)
	var ans := num(tq[1])
	var word := kind_word(t)
	var final := "So the local %s value of f is %s." % [word, Answer.text(ans)]
	var gen: Array = [{"v": tq[1].neg()}, {"v": qf(s.hi.y if t.kind == "min" else (s.lo.y if not s.lo.is_empty() else -t.y))}]
	for u in s.turns:
		if u != t:
			gen.append({"v": qf(u.y)})
	gen.append({"v": qf(s.zeros[0])})
	var out := {"asked": "Write down the local %s value of f." % word, "lines": [line(s)], "answer": ans,
		"wrongs": [wrong({"v": tq[0]}, MM + "#0")], "generic": gen}
	if rep == "graph":
		out.lines = ["The graph of %s is shown." % line(s)]
		out.graph = screen(s, end_dots(s))
	var form: Array
	if s.fam == "bellform":
		form = ["e^(−%s(x %s %s)²) is at most 1, at x = %s." % [GdcKit.lead(s.k), "−" if s.h.sign() > 0 else "+", Fmt.dec(s.h.abs_q()), Fmt.dec(s.h)],
			"So the maximum value is %s × 1 %s = %s." % [Fmt.dec(s.A), GdcKit.join(s.c, ""), Fmt.dec(s.A.add(s.c))], final]
	else:
		form = ["f is not a transformed parent, so its turning value can't be read off: this method fails here.",
			"The %s tool gives %s." % [word, pt6(t.x, t.y)], final]
	out.methods = {
		"gdc-max-min": {"result": ans.values, "steps": [graph_step(s),
			"The %s tool gives %s: the value is the y-coordinate, %s." % [word, pt6(t.x, t.y), W(t.y)], final]},
		"read-from-form": {"result": ans.values, "steps": form},
	}
	return out


func u_y_intercept(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y0 := yint_q(s)
	var ans := Answer.make("yint", {"y": y0})
	ans.show = "sf"
	var final := "So the y-intercept is %s." % Answer.text(ans)
	var z: Q = zero_qs(s)[0]
	var gen: Array = [{"y": s.c}, {"y": y0.neg()}, {"y": qf(at(s, 1.0))}, {"y": s.A}]
	var out := {"asked": "Find the y-intercept of the graph of f.", "lines": [line(s)], "answer": ans,
		"wrongs": [wrong({"y": z}, ZI + "#0")], "generic": gen}
	if rep == "graph":
		out.lines = ["The graph of %s is shown." % line(s)]
		out.graph = screen(s, end_dots(s))
	out.methods = {
		"set-equal-zero": {"result": ans.values, "steps": ["The y-intercept is where x = 0.", "f(0) = %s." % zero_sub(s), final]},
		"graph-read": {"result": ans.values, "steps": ["The graph crosses the y-axis near y = %s." % Fmt.sf(y0, 1),
			"Exactly, f(0) = %s." % zero_sub(s), final]},
	}
	return out


func u_zeros_with_x_factor(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var qs := zero_qs(s)
	var ans := xs_ans(qs)
	var final := "So the zeros are " + Answer.text(ans) + "."
	var others: Array = qs.filter(func(q): return not q.is_zero())
	var gen: Array = [Answer.xs_of(qs.map(func(q): return q.neg())), Answer.xs_of(s.turns.map(func(t): return qf(t.x))),
		Answer.xs_of([Q.new(0), others[0]]), Answer.xs_of([Q.new(0), others[1]])]
	var quad := GdcKit.first(s.A, "x²") + GdcKit.join(s.b, "x") + GdcKit.join(s.m, "")
	var nz := Answer.xs_list(s.zeros.filter(func(z): return z != 0.0).map(func(z): return "x = " + W(z)))
	return {
		"asked": "Find all the zeros of f.", "lines": [line(s)], "answer": ans,
		"wrongs": [wrong(Answer.xs_of(others), ZI + "#2")], "generic": gen,
		"methods": {
			"gdc-zero": {"result": ans.values, "steps": [graph_step(s), "The zero tool at each crossing: " + zeros6(s) + ".", final]},
			"set-equal-zero": {"result": ans.values, "steps": ["f(x) = x(%s) = 0. Don't divide by x: that loses x = 0." % quad,
				"So x = 0, or %s = 0, which the GDC solves: %s." % [quad, nz], final]},
			"factorised-read": {"result": ans.values, "steps": ["Take out the factor x: f(x) = x(%s), so x = 0 is a zero." % quad,
				"The quadratic factor has no whole-number factors, so its zeros still need the GDC or the formula: %s." % nz, final]},
		},
	}


func u_count_zeros(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.zeros.size()
	var ans := Answer.make("number", {"v": Q.new(n)})
	ans.exact = true
	var inside: int = s.zeros.filter(func(z): return absf(z) <= 10.0).size()
	var gen: Array = [{"v": Q.new(n + 1)}, {"v": Q.new(maxi(n - 1, 0))}, {"v": Q.new(s.turns.size())}, {"v": Q.new(n + 2)}]
	var final := "So f has %d zero%s on the domain." % [n, "" if n == 1 else "s"]
	var out := {"asked": "How many zeros does f have on the domain?", "lines": [line(s)], "answer": ans,
		"wrongs": [wrong({"v": Q.new(inside)}, SG + "#0")] if inside != n else [], "generic": gen}
	if rep == "graph":
		out.lines = ["The graph of %s is shown." % line(s)]
		out.graph = screen(s, end_dots(s))
	out.methods = {
		"zero-of-difference": {"result": ans.values, "steps": [
			"Graph y = f(x) with the x-window set to the whole domain, %s." % dom(s),
			"It crosses the x-axis at " + zeros6(s) + ".", final]},
		"table-sign-change": {"result": ans.values, "steps": [
			"Tabulate f across the whole domain and look for sign changes.",
			"f changes sign %d time%s, once near each of %s." % [n, "" if n == 1 else "s", Answer.xs_list(s.zeros.map(func(z): return Fmt.sf(z, 2)))], final]},
	}
	return out


func u_zero_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var tb: Dictionary = s.table
	var z: float = s.zeros[s.zeros.size() - 1]
	var i := floori((z - tb.xs[0].to_float()) / tb.step.to_float())
	var a: Q = tb.xs[i]
	var b: Q = tb.xs[i + 1]
	var ans := num(z, "x = ")
	var final := "So the largest zero is " + Answer.text(ans) + "."
	var gen: Array = [{"v": a}, {"v": b}, {"v": a.add(b).div(Q.new(2))}, {"v": qf(s.zeros[0])} if s.zeros.size() > 1 else {"v": qf(s.turns[0].x)}]
	var sign := "f(%s) = %s and f(%s) = %s have opposite signs, so the zero lies between x = %s and x = %s." % [Fmt.dec(a), Fmt.dec(tb.ys[i]),
		Fmt.dec(b), Fmt.dec(tb.ys[i + 1]), Fmt.dec(a), Fmt.dec(b)]
	return {
		"asked": "The table shows values of f(x) = %s on %s. Find the interval holding the largest zero of f, then the zero to 3 s.f." % [GdcCurveSituation.text(s), dom(s)],
		"lines": [], "table": {"xs": tb.xs, "ys": tb.ys}, "answer": ans, "generic": gen,
		"methods": {
			"gdc-zero": {"result": ans.values, "steps": [sign, "Use the zero tool between them: x = %s." % W(z), final]},
			"table-sign-change": {"result": ans.values, "steps": [sign,
				"Tabulate again from x = %s with a smaller step, and again, until the zero is fixed: x = %s." % [Fmt.dec(a), W(z)], final]},
		},
	}


func u_use_stored_zeros(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z1: float = s.zeros[0]
	var z2: float = s.zeros[1]
	var ans := num(z2 - z1)
	var final := "So the distance between the zeros is " + Answer.text(ans) + "."
	var r1 := float(Fmt.sf(z1).replace("−", "-"))
	var r2 := float(Fmt.sf(z2).replace("−", "-"))
	var gen: Array = [{"v": qf(absf(z1 + z2))}, {"v": qf(absf(z2))}, {"v": qf(absf(z1))}, {"v": qf(z2 - z1 + 1.0)}]
	return {
		"asked": "The graph of f meets the x-axis at A and B. Find the distance AB.", "lines": [line(s)], "answer": ans,
		"wrongs": [wrong({"v": Q.new(roundi((r2 - r1) * 1000), 1000)}, SG + "#1")], "generic": gen,
		"methods": {"gdc-zero": {"result": ans.values, "steps": [graph_step(s),
			"Store the zeros at full accuracy: x = %s and x = %s." % [W(z1), W(z2)],
			"AB = %s − (%s) = %s, from the stored values, not the rounded ones." % [W(z2), W(z1), W(z2 - z1)], final]}},
	}


func u_constant_from_max(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: Dictionary = s.turns.filter(func(u): return u.kind == "max")[0]
	var gmax: float = t.y - s.c.to_float()
	# The maximum value given: f's own, to one decimal place, nudged off the GDC value.
	var M := Q.new(roundi(t.y * 10) + 3, 10)
	var c := M.to_float() - gmax
	var ans := num(c, "c = ")
	var final := "So " + Answer.text(ans) + "."
	var no_c := s.duplicate()
	no_c.c = Q.new(0)
	var g := GdcCurveSituation.text(no_c)
	var gen: Array = [{"v": qf(M.to_float() + gmax)}, {"v": qf(gmax - M.to_float())}, {"v": M}, {"v": qf(M.to_float() - t.x)}]
	return {
		"asked": "f(x) = %s + c, for %s, where c is a constant. The local maximum value of f is %s. Find c." % [g, dom(s), Fmt.dec(M)],
		"lines": ["f(x) = %s + c" % g], "answer": ans, "generic": gen,
		"methods": {
			"gdc-max-min": {"result": ans.values, "steps": [
				"c only lifts the graph, so graph y = %s and find its local maximum." % g,
				"The maximum tool gives %s." % pt6(t.x, gmax),
				"%s + c = %s, so c = %s − %s = %s." % [W(gmax), Fmt.dec(M), Fmt.dec(M), W(gmax), W(c)], final]},
			"derivative-zero": {"result": ans.values, "steps": [
				"f′(x) = %s, which has no c in it." % deriv_text(s),
				"f′(x) = 0 at x = %s on the GDC, where %s = %s." % [W(t.x), g, W(gmax)],
				"%s + c = %s, so c = %s." % [W(gmax), Fmt.dec(M), W(c)], final]},
		},
	}
