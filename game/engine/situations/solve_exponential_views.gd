class_name SolveExponentialViews
extends ExtensionViews
## The views on the `solve-exponential` situation: one builder per unknown of
## t1-solve-exponential (FAL-754), SL1.7.solve-with-logs.
##
## Two bases: a^(x + p) = b^x or a^x = b^(c − x), to 3 s.f. (Paper 2) or exactly as ln P/ln Q (a
## `form` answer, either paper). An exponential to isolate: k e^(mx) + d = c exactly as m ln r
## (the `lnq` kind, marked by value, so ln 2 and (ln 4)/2 are both right) or, with a decimal rate
## or a whole base, to 3 s.f. A model in a story: the exact time A₀ e^(kt) takes to reach a level,
## and the time two models, A₀ e^(kt) and B₀ × g^t, meet, to 3 s.f.
##
## Representations: "equation" (the equation alone), "words" (a story with its models) and
## "graph" (the two curves, or a curve and a line, drawn crossing at P). The GDC methods
## (graph-intersect, gdc-solver) are Paper 2 only, and every exact cell is solved by hand.
## Misconceptions are the map's first, then the type's own, which are "<type id>#<index>".
##
## t1-ext-common-base (FAL-780) is built here too: b^x = N or 1/N, A^x = R and A^(x + c) = B^(kx + e)
## with both sides powers of one prime t, solved exactly by equating the exponents (or with logs,
## or from a list of powers). Its answers are whole numbers or fractions, typed exactly, and its
## wrong options are SL1.7.common-base's slips and the type's own. It builds error-spot and
## method-pick; order-steps isn't built in the engine.

const MAP := "SL1.7.solve-with-logs#"
const OWN := "t1-solve-exponential#"
const R_BRACKET := MAP + "0"
const R_BEFORE := MAP + "1"
const R_EARLY := MAP + "2"
const R_SIGN := OWN + "3"
const R_COMBINE := OWN + "4"
const R_FLIP := OWN + "5"
const R_SUB_K := OWN + "6"
const R_ORDER := OWN + "7"
const R_NO_DIVIDE := OWN + "8"
const R_TIMES := OWN + "9"
const R_BASE := OWN + "10"
const R_DROP_START := OWN + "11"
const R_PERCENT := OWN + "12"
const R_PRODUCT := OWN + "13"

const CB := "SL1.7.common-base#"
const CO := "t1-ext-common-base#"
const R_DIVIDE := CB + "0"
const R_X_ONLY := CB + "1"
const R_UPSIDE := CO + "2"
const R_NO_MINUS := CO + "3"
const R_NO_BASE := CO + "4"
const R_HEIGHT := CO + "5"
const R_SPOT_ADD := CO + "6"
const R_SPOT_X_ONLY := CO + "7"
## Methods that don't work on any common-base equation, for method-pick.
const CB_PICK_WRONGS := [
	{"name": "Divide the right side by the base", "why": "x is the power the base is raised to, not a quotient"},
	{"name": "Equate the bases", "why": "the bases are numbers, so equating them has no x in it to find"},
	{"name": "Take the square root of both sides", "why": "that only halves each exponent, so x is still unknown"},
]

const BOTH := "log-both-sides"
const ISOLATE := "isolate-then-log"
const GRAPH := "graph-intersect"
const SOLVER := "gdc-solver"

const THREE := " Give your answer to 3 significant figures."
const PLACES := ["Ash Pass", "Salt Ridge", "Rust Gorge", "Cinder Bay", "Dry Lake", "Glass Flats"]
## A story: one thing that grows (model-time-exact), and two of them (model-meet).
const STORY := [
	{"one": "A mould colony on the wall of the vault at %s", "two": "Two mould colonies are growing on the wall of the vault at %s.",
		"it": "the colony", "them": "the two colonies", "time": "days", "start": "the vault was sealed", "verb": "cover"},
	{"one": "A rust bloom on the hull of a wreck at %s", "two": "Two rust blooms are spreading on the hull of a wreck at %s.",
		"it": "the bloom", "them": "the two blooms", "time": "weeks", "start": "the rains", "verb": "cover"},
	{"one": "A lichen mat on a standing stone at %s", "two": "Two lichen mats are growing on a standing stone at %s.",
		"it": "the mat", "them": "the two mats", "time": "days", "start": "the dust storm", "verb": "cover"},
	{"one": "An algae bloom in the water tank at %s", "two": "Two algae blooms are growing in the water tank at %s.",
		"it": "the bloom", "them": "the two blooms", "time": "hours", "start": "the pumps stopped", "verb": "cover"},
]


func needs() -> Dictionary:
	var out := {}
	for u in ["two-bases-3sf", "shift-base-exact", "one-minus-exact", "isolate-e-exact", "isolate-3sf", "model-time-exact", "model-meet"]:
		out[u] = {"ask": u}
	for u in SolveExponentialSituation.COMMON:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	return {"whole-power": ["method-pick"], "reciprocal-power": ["method-pick"], "fraction-power": ["error-spot", "method-pick"],
		"linear-exponents": ["error-spot", "method-pick"], "meet-on-graph": ["method-pick"]}


## An exact cell needs no calculator, so it can be either paper; the bank's part is Paper 2, so
## the engine asks it there unless a Paper 1 question is wanted. A 3 s.f. cell is Paper 2.
func papers(unknown: String, _rep: String, _angle_id: String) -> Array:
	if not has(unknown):
		return []
	if unknown in SolveExponentialSituation.COMMON:
		return [2] if _angle_id == GRAPH else [1, 2]
	return [1, 2] if unknown in SolveExponentialSituation.EXACT else [2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.wrongs = rng.shuffled(out.wrongs)
	out.given = SolveExponentialSituation.export(s)
	said_once(out.methods, out.answer)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## A working value, to 6 s.f.
static func W(x: float) -> String:
	return Fmt.work(x, 6)


## A float in the working, in a bracket if it is negative.
static func WP(x: float) -> String:
	return W(x) if x >= 0.0 else "(%s)" % W(x)


## ln 5, ln(5/3)
static func ln_of(v: Variant) -> String:
	var q := Q.of(v)
	return "ln " + N(q) if q.is_int() and q.sign() > 0 else "ln(%s)" % N(q)


## 2 ln 3, ln 3: a whole multiple of a log.
static func times_ln(n: int, v: Variant) -> String:
	return ln_of(v) if n == 1 else "%d %s" % [n, ln_of(v)]


## 3^(x + 2), 5^x, 7^(1 − x)
static func pw(b: Variant, expo: String) -> String:
	var base: String = b if b is String else N(b)
	return "%s^%s" % [base, expo] if expo == "x" or expo == "t" else "%s^(%s)" % [base, expo]


## x + 2, x − 3
static func shift_expo(p: int) -> String:
	return "x %s %d" % ["+" if p > 0 else "−", absi(p)]


## c − x
static func mirror_expo(c: int) -> String:
	return "%d − x" % c


static func left_side(s: Dictionary) -> String:
	return pw(s.a, shift_expo(s.p) if s.shape == "shift" else "x")


static func right_side(s: Dictionary) -> String:
	return pw(s.b, "x" if s.shape == "shift" else mirror_expo(s.c))


static func two_eq(s: Dictionary) -> String:
	return "%s = %s" % [left_side(s), right_side(s)]


## x = ln 9/ln(5/3), as a `form` answer or option, with its two numbers typed.
static func quot(p: Q, q: Q) -> Dictionary:
	return {"p": p, "q": q, "text": "x = %s/%s" % [ln_of(p), ln_of(q)]}


static func quot_ans(p: Q, q: Q) -> Dictionary:
	var v := quot(p, q)
	return DifferentiationViews.form(v.text, ["x = ln ", {"slot": "p"}, " / ln ", {"slot": "q"}], {"p": p, "q": q})


## A 3 s.f. value as a number answer.
static func sf_ans(label: String, x: float, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": GdcKit.qf(x)}, {}, label, unit)
	ans.show = "sf"
	return ans


## Wrong 3 s.f. options, [x, ref] each, left out where they aren't a clear number.
static func sf_wrongs(list: Array) -> Array:
	var out: Array = []
	for e in list:
		var x: float = e[0]
		if is_finite(x) and x != 0.0 and absf(x) < 1.0e5 and absf(x) >= 0.001 and Answer.rounds_clearly(x, 0.01):
			out.append(wrong({"v": GdcKit.qf(x)}, e[1]))
	return out


static func sf_spare(xs: Array) -> Array:
	return sf_wrongs(xs.map(func(x): return [x, ""])).map(func(o): return o.values)


## m ln r, as an lnq answer's values.
static func lnq(m: Q, r: Q) -> Dictionary:
	return {"m": m, "r": r}


## An lnq slip, kept only where its log has a positive number that isn't 1.
static func lnq_wrong(m: Q, r: Q, ref: String) -> Array:
	return [wrong(lnq(m, r), ref)] if r.sign() > 0 and not r.eq(1) else []


static func say(ans: Dictionary) -> String:
	return "So %s." % Answer.text(ans)


## Subtract 3 from both sides, or add 3.
static func undo_d(d: int) -> String:
	return "Subtract %d from both sides" % d if d > 0 else "Add %d to both sides" % -d


static func plus_d(d: int) -> String:
	return "" if d == 0 else " %s %d" % ["+" if d > 0 else "−", absi(d)]


## 5e^(2x), e^x, 4e^(0.6x)
static func k_exp(k: int, m: Variant, letter: String = "x") -> String:
	var mq := Q.of(m)
	var expo := letter if mq.eq(1) else D(mq) + letter
	return ("" if k == 1 else str(k)) + pw("e", expo)


static func place(s: Dictionary) -> String:
	return PLACES[s.ctx % PLACES.size()]


# ── A figure ─────────────────────────────────────────────────

## Two curves (or a curve and a line) crossing at P, each curve named where there is room.
static func figure(fns: Array, names: Array, x0: int, x1: int, y0: int, y1: int, px: float, py: float, hlines: Array = []) -> Dictionary:
	var curves: Array = fns.map(func(f): return Plot.sample(f, float(x0), float(x1)))
	var marks: Array = [[px, py, "P"]]
	for i in names.size():
		var spot := name_spot(fns, i, x0, x1, y0, y1)
		if not spot.is_empty():
			marks.append([spot[0], spot[1], names[i]])
	var g := Plot.spec(curves, marks, x0, x1, y0, y1, hlines)
	for i in range(1, g.points.size()):
		g.points[i].name = true
	return g


## A place on curve i inside the window and clear of the other curves and of P, from the right.
static func name_spot(fns: Array, i: int, x0: int, x1: int, y0: int, y1: int) -> Array:
	var span := float(y1 - y0)
	for j in 40:
		var x := float(x1) - (float(x1 - x0) * (0.12 + j * 0.02))
		var y: float = fns[i].call(x)
		if not is_finite(y) or y < y0 + 0.08 * span or y > y1 - 0.12 * span:
			continue
		var clear := true
		for k in fns.size():
			if k != i and absf(float(fns[k].call(x)) - y) < 0.12 * span:
				clear = false
		if clear:
			return [x, y]
	return []


# ── Two bases ────────────────────────────────────────────────

## The rearranged equation, as the log-both-sides working writes it: [bring down, collect, value].
static func two_steps(s: Dictionary) -> Array:
	var a: int = s.a
	var b: int = s.b
	var la := log(float(a))
	var lb := log(float(b))
	if s.shape == "shift":
		var p: int = s.p
		var n := absi(p)
		var down := "(%s) ln %d = x ln %d" % [shift_expo(p), a, b]
		var top := times_ln(n, a)
		var bottom := "ln %d − ln %d" % [b, a] if p > 0 else "ln %d − ln %d" % [a, b]
		var collect := "Expand and collect the x terms: %s, so x(%s) = %s" % [
			"x ln %d − x ln %d = %s" % [b, a, top] if p > 0 else "x ln %d − x ln %d = %s" % [a, b, top], bottom, top]
		var diff := (lb - la) if p > 0 else (la - lb)
		return [down, collect, "x = %s/(%s) = %s ÷ %s = %s" % [top, bottom, W(n * la), W(diff), W(s.x)]]
	var c: int = s.c
	var down2 := "x ln %d = (%d − x) ln %d" % [a, c, b]
	var top2 := times_ln(c, b)
	var collect2 := "Expand and collect the x terms: x ln %d + x ln %d = %s, so x(ln %d + ln %d) = %s" % [a, b, top2, a, b, top2]
	return [down2, collect2, "x = %s/(ln %d + ln %d) = %s ÷ %s = %s" % [top2, a, b, W(c * lb), W(la + lb), W(s.x)]]


func u_two_bases_3sf(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var la := log(float(s.a))
	var lb := log(float(s.b))
	var x: float = s.x
	var ans := sf_ans("x = ", x)
	var list: Array = [[SolveExponentialSituation.two_bases_early(s), R_EARLY]]
	if s.shape == "shift":
		var n := absi(s.p)
		list.append([s.p * la / (lb - 1.0), R_BRACKET])
		list.append([n * la / (la + lb), R_SIGN])
		var gap: int = s.b - s.a if s.p > 0 else s.a - s.b
		if gap >= 2:
			list.append([n * la / log(float(gap)), R_COMBINE])
	else:
		list.append([s.c / (la + lb), R_BRACKET])
		list.append([s.c * lb / (la - lb), R_SIGN])
		list.append([s.c * lb / log(float(s.a + s.b)), R_COMBINE])
	var out := {"answer": ans, "wrongs": sf_wrongs(list), "generic": sf_spare([x + 1.0, x * 2.0, -x, x * 0.5, x + 2.0]), "lines": [two_eq(s)]}
	out.asked = "Solve the equation." + THREE
	if rep == "graph":
		out.lines = ["The graph shows y = %s and y = %s, which meet at P." % [left_side(s), right_side(s)]]
		out.asked = "Find the x-coordinate of P." + THREE
		out.graph = _two_figure(s)
	var st := two_steps(s)
	out.methods = {
		BOTH: method(["Take ln of both sides and bring each power down, keeping its bracket: " + st[0], st[1], st[2], say(ans)], ans.values),
		GRAPH: method(["Graph y = %s and y = %s." % [left_side(s), right_side(s)], "They meet at x = %s." % W(x), say(ans)], ans.values),
		SOLVER: method(["Enter %s into the numerical solver." % two_eq(s), "It gives x = %s." % W(x), say(ans)], ans.values),
	}
	return out


static func _two_figure(s: Dictionary) -> Dictionary:
	var x: float = s.x
	var a: float = s.a
	var b: float = s.b
	var f1: Callable
	var f2: Callable
	if s.shape == "shift":
		var p: float = s.p
		f1 = func(t: float) -> float: return pow(a, t + p)
		f2 = func(t: float) -> float: return pow(b, t)
	else:
		var c: float = s.c
		f1 = func(t: float) -> float: return pow(a, t)
		f2 = func(t: float) -> float: return pow(b, c - t)
	var y: float = f2.call(x)
	var x0 := mini(-1, floori(x) - 2)
	var x1: int = maxi(ceili(x * 1.25) + 1, 2) if s.shape == "shift" else s.c + 1
	var top: int = Plot.nice_top(y * 1.6)
	return figure([f1, f2], ["y = " + left_side(s), "y = " + right_side(s)], x0, x1, 0, top, x, y)


## ln(a^p) and the ratio of a^(x ± p) = b^x, as the exact working has them.
func u_shift_base_exact(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var n := absi(s.p)
	var P := Q.new(SolveExponentialSituation.ipow(a, n))
	var ratio := Q.new(b, a) if s.p > 0 else Q.new(a, b)
	var ans := quot_ans(P, ratio)
	var gap: int = b - a if s.p > 0 else a - b
	var w_list: Array = [wrong(quot(P, Q.new(a * b)), R_SIGN), wrong(quot(ratio, P), R_FLIP)]
	var top := times_ln(n, a)
	w_list.append(DifferentiationViews.alt("x = %s/(ln %d − 1)" % [top, b] if s.p > 0 else "x = %s/(1 − ln %d)" % [top, b], R_BRACKET))
	if gap >= 2 and not Q.new(gap).eq(ratio) and not Q.new(gap).eq(P):
		w_list.append(wrong(quot(P, Q.new(gap)), R_COMBINE))
	var generic: Array = [quot(P, Q.new(b)), quot(Q.new(b), ratio), quot(P, Q.new(a + b)), quot(P.mul(a), ratio)]
	if n > 1:
		generic.push_front(quot(Q.new(a), ratio))
	var bottom := "ln %d − ln %d" % [b, a] if s.p > 0 else "ln %d − ln %d" % [a, b]
	var collect := "Expand and collect the x terms: x(%s) = %s" % [bottom, top]
	var steps: Array = ["Take ln of both sides and bring each power down, keeping its bracket: (%s) ln %d = x ln %d" % [shift_expo(s.p), a, b], collect,
		"Use the log laws: %s = %s and %s = %s" % [top, ln_of(P), bottom, ln_of(ratio)], say(ans)]
	if n == 1:
		steps = [steps[0], collect, "Use the log law: %s = %s" % [bottom, ln_of(ratio)], say(ans)]
	return {"lines": [two_eq(s)], "asked": "Solve the equation, giving x in the form ln p/ln q, where p and q are rational.",
		"answer": ans, "wrongs": w_list, "generic": generic, "methods": {BOTH: method(steps, ans.values)}}


func u_one_minus_exact(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var P := Q.new(SolveExponentialSituation.ipow(b, c))
	var ab := Q.new(a * b)
	var ans := quot_ans(P, ab)
	var w_list: Array = [wrong(quot(P, Q.new(a, b)), R_SIGN), wrong(quot(ab, P), R_FLIP), wrong(quot(P, Q.new(a + b)), R_COMBINE),
		DifferentiationViews.alt("x = %d/(ln %d + ln %d)" % [c, a, b], R_BRACKET)]
	var generic: Array = [quot(Q.new(SolveExponentialSituation.ipow(a, c)), ab), quot(P, Q.new(a)), quot(Q.new(b), ab), quot(P, Q.new(b))]
	var top := times_ln(c, b)
	var steps: Array = ["Take ln of both sides and bring each power down, keeping its bracket: x ln %d = (%d − x) ln %d" % [a, c, b],
		"Expand and collect the x terms: x ln %d + x ln %d = %s, so x(ln %d + ln %d) = %s" % [a, b, top, a, b, top],
		("Use the log laws: %s = %s and ln %d + ln %d = %s" % [top, ln_of(P), a, b, ln_of(ab)]) if c > 1 else "Use the log law: ln %d + ln %d = %s" % [a, b, ln_of(ab)],
		say(ans)]
	return {"lines": [two_eq(s)], "asked": "Solve the equation, giving x in the form ln p/ln q, where p and q are whole numbers.",
		"answer": ans, "wrongs": w_list, "generic": generic, "methods": {BOTH: method(steps, ans.values)}}


# ── Isolate the exponential ──────────────────────────────────

static func isolate_eq(s: Dictionary) -> String:
	return "%s%s = %d" % [k_exp(s.k, s.m), plus_d(s.d), s.c]


func u_isolate_e_exact(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var m: int = s.m
	var d: int = s.d
	var c: int = s.c
	var r: int = s.r
	var root: bool = s.shape == "root"
	var ans := Answer.make("lnq", lnq(Q.new(1), Q.new(s.a)) if root else lnq(Q.new(1, m), Q.new(r)), {}, "x = ")
	ans.exact = true
	var w_list: Array = []
	w_list.append_array(lnq_wrong(Q.new(1, k * m), Q.new(c - d), R_BEFORE))
	w_list.append_array(lnq_wrong(Q.new(1, m), Q.new(c - d - k), R_SUB_K))
	if d != 0:
		w_list.append_array(lnq_wrong(Q.new(1, m), Q.new(c, k).sub(d), R_ORDER))
	if m != 1:
		w_list.append_array(lnq_wrong(Q.new(1), Q.new(r), R_NO_DIVIDE))
		w_list.append_array(lnq_wrong(Q.new(m), Q.new(r), R_TIMES))
	var generic: Array = [lnq(Q.new(1, m), Q.new(r + 1)), lnq(Q.new(1, m), Q.new(c)), lnq(Q.new(1, m), Q.new(r * k)), lnq(Q.new(2, m), Q.new(r))]
	var e_mx := pw("e", "x" if m == 1 else "%dx" % m)
	var mx := "x" if m == 1 else "%dx" % m
	var lead: Array = ["%s: %s = %d" % [undo_d(d), k_exp(k, m), c - d]] if d != 0 else []
	var last: Array = []
	if m != 1:
		last.append("x = (ln %d)/%d = ln(%d^(1/%d)) = ln %d" % [r, m, r, m, s.a] if root else "x = (ln %d)/%d" % [r, m])
	last.append(say(ans))
	var iso: Array = lead + ["Divide by %d: %s = %d" % [k, e_mx, r], "Take ln of both sides: %s = ln %d" % [mx, r]] + last
	var both: Array = lead + ["Take ln of both sides, using the product law: ln %d + %s = ln %d" % [k, mx, c - d],
		"%s = ln %d − ln %d = ln %d" % [mx, c - d, k, r]] + last
	var asked := "Solve the equation, giving your answer in the form ln a, where a is a whole number." if root else "Solve the equation, giving the exact value of x."
	return {"lines": [isolate_eq(s)], "asked": asked, "answer": ans, "wrongs": w_list, "generic": generic,
		"methods": {ISOLATE: method(iso, ans.values), BOTH: method(both, ans.values)}}


static func iso3_eq(s: Dictionary) -> String:
	var term := k_exp(s.k, s.m) if s.shape == "e" else "%d × %s" % [s.k, pw(s.a, "x")]
	return "%s%s = %d" % [term, plus_d(s.d), s.c]


static func iso3_term(s: Dictionary) -> String:
	return k_exp(s.k, s.m) if s.shape == "e" else "%d × %s" % [s.k, pw(s.a, "x")]


func u_isolate_3sf(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var d: int = s.d
	var c: int = s.c
	var r: Q = s.r
	var x: float = s.x
	var e: bool = s.shape == "e"
	var m: float = s.m.to_float()
	var div := m if e else log(float(s.a))
	var ans := sf_ans("x = ", x)
	var list: Array = [[s.early, R_EARLY], [log(float(c - d)) / (k * div), R_BEFORE], [log(float(c - d - k)) / div, R_SUB_K]]
	if d != 0 and float(c) / k - d > 0.0 and absf(float(c) / k - d - 1.0) > 1e-9:
		list.append([log(float(c) / k - d) / div, R_ORDER])
	if e and m != 1.0:
		list.append([log(r.to_float()), R_NO_DIVIDE])
	if not e:
		list.append([log(r.to_float()) / s.a, R_BASE])
	var out := {"answer": ans, "wrongs": sf_wrongs(list), "generic": sf_spare([x + 1.0, x * 2.0, x * 0.5, -x, x + 2.0]), "lines": [iso3_eq(s)]}
	out.asked = "Solve the equation." + THREE
	var curve := iso3_eq(s).split(" = ")[0]
	if rep == "graph":
		out.lines = ["The graph shows y = %s and the line y = %d, which meet at P." % [curve, c]]
		out.asked = "Find the x-coordinate of P." + THREE
		out.graph = _iso_figure(s)
	var lead: Array = ["%s: %s = %d" % [undo_d(d), iso3_term(s), c - d]] if d != 0 else []
	var lr := log(r.to_float())
	var iso: Array
	var both: Array
	if e:
		var mx := D(s.m) + "x"
		iso = lead + ["Divide by %d: %s = %s" % [k, pw("e", mx), D(r)], "Take ln of both sides: %s = %s = %s" % [mx, ln_of(r), W(lr)],
			"x = %s ÷ %s = %s" % [W(lr), D(s.m), W(x)], say(ans)]
		both = lead + ["Take ln of both sides, using the product law: ln %d + %s = ln %d" % [k, mx, c - d],
			"%s = ln %d − ln %d = %s − %s = %s" % [mx, c - d, k, W(log(float(c - d))), W(log(float(k))), W(lr)], "x = %s ÷ %s = %s" % [W(lr), D(s.m), W(x)], say(ans)]
	else:
		var la := log(float(s.a))
		iso = lead + ["Divide by %d: %s = %s" % [k, pw(s.a, "x"), D(r)], "Take ln of both sides: x ln %d = %s" % [s.a, ln_of(r)],
			"x = %s/ln %d = %s ÷ %s = %s" % [ln_of(r), s.a, W(lr), W(la), W(x)], say(ans)]
		both = lead + ["Take ln of both sides, using the product law: ln %d + x ln %d = ln %d" % [k, s.a, c - d],
			"x = (ln %d − ln %d)/ln %d = %s ÷ %s = %s" % [c - d, k, s.a, W(lr), W(la), W(x)], say(ans)]
	out.methods = {
		ISOLATE: method(iso, ans.values),
		BOTH: method(both, ans.values),
		GRAPH: method(["Graph y = %s and y = %d." % [curve, c], "They meet at x = %s." % W(x), say(ans)], ans.values),
		SOLVER: method(["Enter %s into the numerical solver." % iso3_eq(s), "It gives x = %s." % W(x), say(ans)], ans.values),
	}
	return out


static func _iso_figure(s: Dictionary) -> Dictionary:
	var x: float = s.x
	var k: float = s.k
	var d: float = s.d
	var m: float = s.m.to_float()
	var a: float = s.a
	var f: Callable
	if s.shape == "e":
		f = func(t: float) -> float: return k * exp(m * t) + d
	else:
		f = func(t: float) -> float: return k * pow(a, t) + d
	var x1 := maxi(ceili(x * 1.3), 2)
	var y0 := 0 if s.d >= 0 else -5 * ceili(-d / 5.0 + 0.5)
	var top: int = Plot.nice_top(float(s.c) * 1.3)
	var curve := iso3_eq(s).split(" = ")[0]
	var g := figure([f], ["y = " + curve], 0, x1, y0, top, x, float(s.c), [[float(s.c), "y = %d" % s.c]])
	return g


# ── Models ───────────────────────────────────────────────────

static func model_text(s: Dictionary) -> String:
	return "A = %d%s" % [s.A0, pw("e", D(s.kk) + "t")]


func u_model_time_exact(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var st: Dictionary = STORY[s.story]
	var k: Q = s.kk
	var A0: int = s.A0
	var L: int = s.L
	var ratio: Q = s.ratio
	var inv := Q.new(1).div(k)
	var ans := Answer.make("lnq", lnq(inv, ratio), {}, "t = ")
	ans.exact = true
	var w_list: Array = []
	w_list.append_array(lnq_wrong(Q.new(1).div(k.mul(A0)), Q.new(L), R_BEFORE))
	w_list.append_array(lnq_wrong(inv, Q.new(L), R_DROP_START))
	w_list.append_array(lnq_wrong(inv, Q.new(L - A0), R_SUB_K))
	w_list.append_array(lnq_wrong(Q.new(1), ratio, R_NO_DIVIDE))
	w_list.append_array(lnq_wrong(k, ratio, R_TIMES))
	var generic: Array = [lnq(inv, ratio.add(1)), lnq(inv.mul(2), ratio), lnq(inv, Q.new(A0)), lnq(inv.add(1), ratio)]
	var lines: Array = ["%s covers %s square centimetres, t %s after %s." % [st.one % place(s), model_text(s), st.time, st.start]]
	var asked := "Find the exact number of %s it takes %s to cover %d square centimetres." % [st.time, st.it, L]
	var kt := D(k) + "t"
	var eq := "%d%s = %d" % [A0, pw("e", kt), L]
	var undo := "t = %s ÷ %s = %s" % [ln_of(ratio), D(k), Answer.text(ans).trim_prefix("t = ")]
	var iso: Array = ["Put A = %d: %s" % [L, eq], "Divide by %d: %s = %s" % [A0, pw("e", kt), D(ratio)], "Take ln of both sides: %s = %s" % [kt, ln_of(ratio)], undo, say(ans)]
	var both: Array = ["Put A = %d: %s" % [L, eq], "Take ln of both sides, using the product law: ln %d + %s = ln %d" % [A0, kt, L],
		"%s = ln %d − ln %d = %s" % [kt, L, A0, ln_of(ratio)], undo, say(ans)]
	return {"lines": lines, "asked": asked, "answer": ans, "wrongs": w_list, "generic": generic,
		"methods": {ISOLATE: method(iso, ans.values), BOTH: method(both, ans.values)}}


static func meet_a(s: Dictionary) -> String:
	return "%d%s" % [s.A0, pw("e", D(s.kk) + "t")]


static func meet_b(s: Dictionary) -> String:
	return "%d × %s" % [s.B0, pw(D(s.g), "t")]


func u_model_meet(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var st: Dictionary = STORY[s.story]
	var t: float = s.t
	var k: float = s.kk.to_float()
	var g: float = s.g.to_float()
	var lg := log(g)
	var ratio := log(float(s.B0) / s.A0)
	var unit: String = " " + st.time
	var ans := sf_ans("t = ", t, unit)
	var list: Array = [[s.early, R_EARLY], [ratio / (k + lg), R_SIGN], [log(float(s.B0 - s.A0)) / (k - lg), R_COMBINE],
		[ratio / (k - (g - 1.0)), R_PERCENT], [log(float(s.A0)) / (log(s.B0 * g) - k), R_PRODUCT]]
	var out := {"answer": ans, "wrongs": sf_wrongs(list), "generic": sf_spare([t + 1.0, t * 2.0, t * 0.5, t + 3.0]), "table": null}
	out.lines = [st.two % place(s), "t %s after %s, one covers A = %s square centimetres and the other covers B = %s square centimetres." % [st.time, st.start, meet_a(s), meet_b(s)]]
	out.asked = "Find the time when %s cover the same area.%s" % [st.them, THREE]
	if rep == "graph":
		out.lines.append("The graph shows A and B against t, crossing at P.")
		out.asked = "Find the value of t at P.%s" % THREE
		out.graph = _meet_figure(s)
	var eq := "%s = %s" % [meet_a(s), meet_b(s)]
	out.methods = {
		BOTH: method(["The areas are equal when %s." % eq, "Take ln of both sides: ln %d + %st = ln %d + t ln %s" % [s.A0, D(s.kk), s.B0, D(s.g)],
			"Collect the t terms: t(%s − ln %s) = ln %d − ln %d" % [D(s.kk), D(s.g), s.B0, s.A0],
			"t = %s ÷ (%s − %s) = %s ÷ %s = %s" % [W(ratio), D(s.kk), W(lg), W(ratio), W(k - lg), W(t)], say(ans)], ans.values),
		GRAPH: method(["Graph A = %s and B = %s for t ≥ 0." % [meet_a(s), meet_b(s)], "They cross at t = %s." % W(t), say(ans)], ans.values),
		SOLVER: method(["Enter %s into the numerical solver, with t > 0." % eq, "It gives t = %s." % W(t), say(ans)], ans.values),
	}
	return out


static func _meet_figure(s: Dictionary) -> Dictionary:
	var t: float = s.t
	var A0: float = s.A0
	var B0: float = s.B0
	var k: float = s.kk.to_float()
	var g: float = s.g.to_float()
	var fa := func(x: float) -> float: return A0 * exp(k * x)
	var fb := func(x: float) -> float: return B0 * pow(g, x)
	var y: float = fa.call(t)
	var x1 := ceili(t * 1.4)
	var g2 := figure([fa, fb], ["A", "B"], 0, x1, 0, Plot.nice_top(y * 1.7), t, y)
	return g2.merged({"x_name": "t"})


# ── A common base (t1-ext-common-base) ──────────────────────

## x, typed exactly: a whole number or a fraction.
static func x_ans(x: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": x}, {}, "x = ")
	ans.exact = true
	return ans


static func xv(x: Variant) -> Dictionary:
	return {"v": Q.of(x)}


## Wrong options [value, ref], each kept once and only where it isn't the answer.
static func cb_wrongs(x: Q, list: Array) -> Array:
	var out: Array = []
	var seen := {x.key(): true}
	for e in list:
		var v := Q.of(e[0])
		if seen.has(v.key()):
			continue
		seen[v.key()] = true
		out.append(wrong(xv(v), e[1]))
	return out


## Fillers that aren't the answer or a slip already offered.
static func cb_fillers(x: Q, wrongs: Array, list: Array) -> Array:
	var seen := {x.key(): true}
	for w in wrongs:
		seen[Q.of(w.values.v).key()] = true
	var out: Array = []
	for v in list:
		var q := Q.of(v)
		if not seen.has(q.key()):
			seen[q.key()] = true
			out.append(xv(q))
	return out


## 2^4, 3^(−2): a whole-number power, as the question writes it.
static func pn(b: Variant, e: int) -> String:
	var base: String = b if b is String else N(b)
	return "%s^%d" % [base, e] if e >= 0 else "%s^(−%d)" % [base, -e]


## "2x + 1", "x − 3", "3x", "−x + 2": the exponent kx + c.
static func lin(k: int, c: int) -> String:
	var head := "x" if k == 1 else ("−x" if k == -1 else "%dx" % k)
	if c == 0:
		return head
	return "%s %s %d" % [head, "+" if c > 0 else "−", absi(c)]


## "3(x + 2)", "x + 2": a whole exponent times the base's power.
static func times_lin(i: int, k: int, c: int) -> String:
	return lin(k, c) if i == 1 else "%d(%s)" % [i, lin(k, c)]


## "A = 2³ and B = 2²", or "A is 2 itself" where the power is 1.
static func as_power(n: int, t: int, p: int) -> String:
	return "%d = %s" % [n, pn(t, p)] if p > 1 else "%d is %d itself" % [n, t]


## The powers of b from b¹ up to b^j, as a list.
static func power_list(b: int, j: int) -> String:
	var parts: Array = []
	for p in range(1, j + 1):
		parts.append("%s = %d" % [pn(b, p), SolveExponentialSituation.ipow(b, p)])
	return ", ".join(parts)


func _cb_pack(lines: Array, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {}, "pick_wrongs": CB_PICK_WRONGS}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


func u_whole_power(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var j: int = s.j
	var N: int = s.N
	var ans := x_ans(s.x)
	var w := cb_wrongs(s.x, [[Q.new(N, b), R_DIVIDE]])
	var fill := cb_fillers(s.x, w, [j + 1, j - 1, 2 * j, j + 2])
	var eq := "%s = %d" % [pw(b, "x"), N]
	return _cb_pack([eq], "Solve the equation.", ans, w, fill, {
		"equate-exponents": ["Write %d as a power of %d: %d = %s." % [N, b, N, pn(b, j)], "So %s = %s, and the exponents are equal: x = %d." % [pw(b, "x"), pn(b, j), j], say(ans)],
		"take-logs": ["Take ln of both sides: x ln %d = ln %d." % [b, N], "ln %d = ln(%s) = %d ln %d, so x = %d ln %d ÷ ln %d = %d." % [N, pn(b, j), j, b, j, b, b, j], say(ans)],
		"inspection": ["List the powers of %d: %s." % [b, power_list(b, j)], "%s = %d, so x = %d." % [pn(b, j), N, j], say(ans)],
	})


func u_reciprocal_power(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var j: int = s.j
	var N: int = s.N
	var ans := x_ans(s.x)
	var w := cb_wrongs(s.x, [[Q.new(j), R_NO_MINUS], [Q.new(1, N * b), R_DIVIDE]])
	var fill := cb_fillers(s.x, w, [-j - 1, -j + 1, -2 * j, -j - 2])
	var eq := "%s = 1/%d" % [pw(b, "x"), N]
	return _cb_pack([eq], "Solve the equation.", ans, w, fill, {
		"equate-exponents": ["Write 1/%d as a power of %d: %d = %s, so 1/%d = %s." % [N, b, N, pn(b, j), N, pn(b, -j)],
			"So %s = %s, and the exponents are equal: x = −%d." % [pw(b, "x"), pn(b, -j), j], say(ans)],
		"take-logs": ["Take ln of both sides: x ln %d = ln(1/%d) = −ln %d." % [b, N, N], "ln %d = %d ln %d, so x = −%d ln %d ÷ ln %d = −%d." % [N, j, b, j, b, b, j], say(ans)],
		"inspection": ["List the powers of %d: %s." % [b, power_list(b, j)], "%s = %d, so %s = 1/%d and x = −%d." % [pn(b, j), N, pn(b, -j), N, j], say(ans)],
	})


func u_fraction_power(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var t: int = s.t
	var i: int = s.i
	var j: int = s.j
	var ans := x_ans(s.x)
	var w := cb_wrongs(s.x, [[Q.new(i, j), R_UPSIDE], [Q.new(s.R, s.A), R_DIVIDE]])
	var fill := cb_fillers(s.x, w, [Q.new(j + 1, i), Q.new(j, i + 1), Q.new(j * i), Q.new(j + i, i)])
	var out := _cb_pack(["%s = %d" % [pw(s.A, "x"), s.R]], "Solve the equation, giving x exactly.", ans, w, fill, {
		"equate-exponents": ["Write both sides as powers of %d: %s and %s." % [t, as_power(s.A, t, i), as_power(s.R, t, j)],
			"So %s = %s, and the exponents are equal: %dx = %d." % [pw(t, "%dx" % i), pn(t, j), i, j], say(ans)],
		"take-logs": ["Take ln of both sides: x ln %d = ln %d." % [s.A, s.R],
			"%s, so %dx = %d." % [("ln %d = %d ln %d and ln %d = %d ln %d" % [s.A, i, t, s.R, j, t]) if j > 1 else "ln %d = %d ln %d" % [s.A, i, t], i, j], say(ans)],
	})
	# The working with a power of a power whose exponents are added: first at line 2, or at line 1.
	var lines: Array = ["%s and %s, so %s = %s." % [as_power(s.A, t, i), as_power(s.R, t, j), pw(P_pow(t, i), "x"), pn(t, j)],
		"%s = %s" % [pw(P_pow(t, i), "x"), pw(t, "x + %d" % i)], "So x + %d = %d." % [i, j], "x = " + N(j - i)]
	var bad := 1
	if rng.chance(0.5):
		lines = ["%s = %s, as %s" % [pw(s.A, "x"), pw(t, "x + %d" % i), as_power(s.A, t, i)], "%s = %s" % [pw(t, "x + %d" % i), pn(t, j)], "So x + %d = %d." % [i, j], "x = " + N(j - i)]
		bad = 0
	out.spot = {"lines": lines, "bad": bad, "ref": R_SPOT_ADD, "why": "a power of a power multiplies the exponents, so %s = %s" % [pw(P_pow(t, i), "x"), pw(t, "%dx" % i)]}
	return out


## (2³), the power of a prime in brackets, as a base.
static func P_pow(t: int, i: int) -> String:
	return "(%s)" % pn(t, i)


## A^(x + c) = B^(kx + e): the equation, and the step equating the exponents.
static func lin_eq(s: Dictionary) -> String:
	return "%s = %s" % [pw(s.A, lin(1, s.c)), pw(s.B, lin(s.k, s.e))]


static func expanded(s: Dictionary) -> String:
	return "%s = %s" % [lin(s.i, s.i * s.c), lin(s.j * s.k, s.j * s.e)]


func _linear_steps(s: Dictionary) -> Dictionary:
	var t: int = s.t
	var D: int = s.i - s.j * s.k
	var top: int = s.j * s.e - s.i * s.c
	var ans := x_ans(s.x)
	var solve := "Collect the x terms: %s." % collected(D, top)
	var powers := "Write both sides as powers of %d: %s and %s." % [t, as_power(s.A, t, s.i), as_power(s.B, t, s.j)]
	return {
		"equate-exponents": [powers, "So %s = %s, and the exponents are equal: %s." % [pw(t, times_lin(s.i, 1, s.c)), pw(t, times_lin(s.j, s.k, s.e)), expanded(s)],
			solve, say(ans)],
		"take-logs": ["Take ln of both sides: (%s) ln %d = (%s) ln %d." % [lin(1, s.c), s.A, lin(s.k, s.e), s.B],
			"%s; divide by ln %d: %s." % [_ln_rewrite(s), t, expanded(s)], solve, say(ans)],
	}


## "ln 9 = 2 ln 3 and ln 27 = 3 ln 3", leaving out a base that is t itself.
static func _ln_rewrite(s: Dictionary) -> String:
	var parts: Array = []
	for pair in [[s.A, s.i], [s.B, s.j]]:
		if pair[1] > 1:
			parts.append("ln %d = %s" % [pair[0], _ln_power(s.t, pair[1])])
	return " and ".join(parts)


## Dx = top, with the x term's coefficient made positive: "5x = 8", "x = −4".
static func collected(D: int, top: int) -> String:
	var g := 1 if D > 0 else -1
	return "%s = %s" % [lin(D * g, 0), N(top * g)]


static func _ln_power(t: int, p: int) -> String:
	return "ln %d" % t if p == 1 else "%d ln %d" % [p, t]


## The slips of A^(x + c) = B^(kx + e): the base's power on the x terms only, and the exponents
## equated with the bases left different.
static func linear_slips(s: Dictionary) -> Array:
	var D: int = s.i - s.j * s.k
	var list: Array = [[Q.new(s.e - s.c, D), R_X_ONLY]]
	if s.k != 1:
		list.append([Q.new(s.e - s.c, 1 - s.k), R_NO_BASE])
	return list


func u_linear_exponents(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var x: Q = s.x
	var ans := x_ans(x)
	var w := cb_wrongs(x, linear_slips(s))
	var fill := cb_fillers(x, w, [x.neg(), x.add(1), x.sub(1), x.mul(2)])
	var out := _cb_pack([lin_eq(s)], "Solve the equation, giving x exactly.", ans, w, fill, _linear_steps(s))
	var t: int = s.t
	var D: int = s.i - s.j * s.k
	var bad_eq := "%s = %s" % [pw(t, lin(s.i, s.c)), pw(t, lin(s.j * s.k, s.e))]
	var slip := Q.new(s.e - s.c, D)
	var lines: Array
	var bad: int
	if rng.chance(0.5):
		lines = ["%s and %s." % [as_power(s.A, t, s.i), as_power(s.B, t, s.j)], "So " + bad_eq + ".", "%s = %s" % [lin(s.i, s.c), lin(s.j * s.k, s.e)],
			"x = " + N(slip)]
		bad = 1
	else:
		lines = [bad_eq + ", as %s and %s" % [as_power(s.A, t, s.i), as_power(s.B, t, s.j)], "So %s = %s." % [lin(s.i, s.c), lin(s.j * s.k, s.e)],
			collected(D, s.e - s.c), "x = " + N(slip)]
		bad = 0
	var whole := "%s = %s" % [pw(s.A, lin(1, s.c)), pw(t, times_lin(s.i, 1, s.c))] if s.i > 1 else "%s = %s" % [pw(s.B, lin(s.k, s.e)), pw(t, times_lin(s.j, s.k, s.e))]
	out.spot = {"lines": lines, "bad": bad, "ref": R_SPOT_X_ONLY, "why": "the base's power multiplies the whole exponent, so " + whole}
	return out


func u_meet_on_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: Q = s.x
	var ans := x_ans(x)
	var w := cb_wrongs(x, linear_slips(s) + [[s.y, R_HEIGHT]])
	var fill := cb_fillers(x, w, [x.add(1), x.sub(1), x.neg(), x.add(2)])
	var left := pw(s.A, lin(1, s.c))
	var right := pw(s.B, lin(1, s.e))
	var steps := _linear_steps(s)
	var out := _cb_pack(["The graph shows y = %s and y = %s, which cross at P." % [left, right]], "Find the x-coordinate of P exactly.", ans, w, fill, {
		"equate-exponents": ["At P the two are equal: %s." % lin_eq(s)] + steps["equate-exponents"],
		GRAPH: ["Graph y = %s and y = %s." % [left, right], "They meet at x = %s, where y = %s." % [N(x), N(s.y)], say(ans)],
	})
	var A: float = s.A
	var B: float = s.B
	var c: float = s.c
	var e: float = s.e
	var f1 := func(v: float) -> float: return pow(A, v + c)
	var f2 := func(v: float) -> float: return pow(B, v + e)
	var px := x.to_float()
	var py: float = s.y.to_float()
	out.graph = figure([f1, f2], ["y = " + left, "y = " + right], mini(-1, int(px) - 2), maxi(int(px) + 2, 2), 0, Plot.nice_top(py * 1.6), px, py)
	return out
