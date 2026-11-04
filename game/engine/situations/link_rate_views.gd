class_name LinkRateViews
extends ExtensionViews
## The views on the `fn-link-rate-of-change` situation: one builder per unknown of
## fn-link-rate-of-change (FAL-424), one rate seen as a common difference, a gradient, a
## regression slope and a derivative. A line is the `line` kind, two numbers are `named`, a
## tangent gradient is a typed number (to 3 s.f. on Paper 2, the GDC's dy/dx), and a meaning is
## a pick of written statements. The catalogue's match-rate-kind is a match; the match format
## isn't built, so it is one pick of the whole matching, A to D. Every unknown plays as
## true-false-reason and method-pick (bar the catalogue's failing methods). The type's formats
## list no error-spot, so "0.6 is the gradient" is a tagged option here, and its 0/0 mistake isn't
## built.

const REG := LinkRateSituation.REG
const DERIV := LinkRateSituation.DERIV
const R_RUN_RISE := "SL2.1.gradient#0"
const R_ORDER := "SL2.1.gradient#1"
const R_TOTAL := "SL2.1.line-model#0"
const R_SWAP := "SL2.1.line-model#1"
const R_NTH := "SL1.2.nth-term#0"
const R_TERMS := "SL1.2.find-u1-d#0"
const R_AB_SWAP := "SL4.4.interpret-ab#0"
const R_AB_BARE := "SL4.4.interpret-ab#1"
const R_SIGN := "SL5.1.interpret-derivative#1"
const R_UNITS := "SL5.1.interpret-derivative#2"
const R_ONE_CHORD := "SL5.1.chord-to-tangent#1"
const R_F_NOT_DF := "SL5.3.gradient-at-point#0"
const KIND_WHOLE := "exact, whole steps"
const KIND_ALL := "exact, every x"
const KIND_FIT := "fitted model"
const KIND_NOW := "one instant"

## Moves that don't find a rate, for method-pick (after the catalogue's failing ones).
const NOT_RATE := [
	{"name": "Divide the output by the input", "why": "y/x is the gradient only when the line goes through the origin"},
	{"name": "Average the outputs", "why": "an average of outputs is a size, not a change per step"},
	{"name": "Read the largest value", "why": "the largest value says nothing about the change per step"},
]


func needs() -> Dictionary:
	var seq := {"kind": "seq"}
	return {"sequence-as-line": seq, "sequence-from-line": seq, "d-from-two-terms": seq, "match-rate-kind": {"kind": "kinds"}, "interpret-regression-gradient": {"kind": "reg"},
		"derivative-in-context": {"kind": "deriv"}, "chord-to-limit": {"kind": "curve"}, "tangent-gradient-methods": {"kind": "curve"}, "constant-derivative": {"kind": "const"}}


func need(unknown: String, rep: String) -> Dictionary:
	var n := super.need(unknown, rep)
	n.erase("rep")
	return n


func extra() -> Dictionary:
	var out := {}
	for u in needs():
		out[u] = ["true-false-reason", "method-pick"]
	return out


## The GDC's dy/dx is Paper 2; everything else is Paper 1.
func papers(_unknown: String, _rep: String, angle_id: String) -> Array:
	return [2] if angle_id == "gdc-dydx" else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = LinkRateSituation.export(s)
	out.pick_wrongs = NOT_RATE
	return out


static func D(v: Variant) -> String:
	return Fmt.dec(v)


## In brackets when negative, for substituting.
static func PD(v: Variant) -> String:
	return "(%s)" % D(v) if Q.of(v).sign() < 0 else D(v)


static func fin(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func line_ans(m: Variant, c: Variant) -> Dictionary:
	var ans := Answer.make("line", {"m": Q.of(m), "c": Q.of(c)})
	ans.exact = true
	return ans


static func line_text(m: Variant, c: Variant) -> String:
	return "y = " + Fmt.poly([m, c])


static func named(names: Array, a: Variant, b: Variant) -> Dictionary:
	var ans := Answer.make("named", {"v0": Q.of(a), "v1": Q.of(b)}, {"names": names})
	ans.show = "dec"
	ans.exact = true
	return ans


static func v2(a: Variant, b: Variant) -> Dictionary:
	return {"v0": Q.of(a), "v1": Q.of(b)}


# ── A sequence as a line ─────────────────────────────────────

## uₙ = 7 + 4(n − 1).
static func rule(s: Dictionary) -> String:
	return "uₙ = %s %s %d(n − 1)" % [N(s.u1), "−" if s.m < 0 else "+", absi(s.m)]


static func term(s: Dictionary, n: int) -> int:
	return s.u1 + (n - 1) * s.m


## The points (n, uₙ) for n = 1 to 5 on axes, each labelled.
static func seq_plot(s: Dictionary) -> Dictionary:
	var ys: Array = range(1, 6).map(func(n): return term(s, n))
	var lo: int = mini(0, ys.min()) - 1
	var hi: int = maxi(0, ys.max()) + 1
	var pts: Array = range(1, 6).map(func(n): return [n, term(s, n), "(%d, %s)" % [n, N(term(s, n))]])
	return Plot.spec([], pts, 0, 6, lo, hi)


static func seq_table(s: Dictionary) -> Dictionary:
	var ns: Array = range(1, 6)
	return {"rows": [["n", ns.map(func(n): return str(n))], ["uₙ", ns.map(func(n): return N(term(s, n)))]]}


func u_sequence_as_line(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := line_ans(s.m, s.c)
	var out := {"asked": "The points (n, uₙ) lie on a straight line. Find its equation in the form y = mx + c.", "answer": ans}
	match rep:
		"graph":
			out.lines = ["The graph shows the first five terms of an arithmetic sequence as points (n, uₙ)."]
			out.graph = seq_plot(s)
		"table":
			out.lines = ["The table shows the first five terms of an arithmetic sequence."]
			out.table = seq_table(s)
		_:
			out.lines = [rule(s)]
	out.wrongs = [wrong({"m": Q.new(s.u1), "c": Q.new(s.m)}, R_SWAP), wrong({"m": Q.new(s.m), "c": Q.new(s.u1)}, R_NTH)]
	out.generic = [{"m": Q.new(-s.m), "c": Q.new(s.u1 + s.m)}, {"m": Q.new(s.m), "c": Q.new(s.u1 + s.m)}, {"m": Q.new(s.m), "c": Q.new(-s.c)}]
	var read: String = "From uₙ, u₁ = %s and d = %s." % [N(s.u1), N(s.m)] if rep == "equation" else "The terms start at u₁ = %s and change by d = %s each step." % [N(s.u1), N(s.m)]
	var back := "Step back one from (1, %s): the line is at %s when x = 0, so c = %s." % [N(s.u1), N(s.c), N(s.c)]
	var expand := "So uₙ = %s + %s(n − 1) = %s." % [N(s.u1), P(s.m), Fmt.poly([s.m, s.c], "n")]
	out.methods = {
		"rise-over-run": method(["From (1, %s) to (2, %s) the run is 1 and the rise is %s, so m = %s." % [N(s.u1), N(term(s, 2)), N(s.m), N(s.m)], back, fin(ans)], ans.values),
		"table-differences": method(["The differences between terms are all %s, so m = %s." % [N(s.m), N(s.m)], back, fin(ans)], ans.values),
		"linear-function": method([read, expand, "That is a linear function of n, so m = %s and c = %s." % [N(s.m), N(s.c)], fin(ans)], ans.values),
		"nth-formula": method([read, "Put them into uₙ = u₁ + (n − 1)d, then multiply out: %s." % Fmt.poly([s.m, s.c], "n"), fin(ans)], ans.values),
	}
	return out


func u_sequence_from_line(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := named(["u₁", "d"], s.u1, s.m)
	var out := {"asked": "An arithmetic sequence has its terms on this line at x = 1, 2, 3, … Find u₁ and d.", "answer": ans}
	if rep == "graph":
		var c: float = float(s.c)
		var m: float = float(s.m)
		var far: int = s.c + 4 * s.m
		var lo: int = mini(0, mini(s.c, far)) - 1
		var hi: int = maxi(0, maxi(s.c, far)) + 1
		var curve := Plot.sample(func(x: float) -> float: return m * x + c, 0.0, 4.0)
		out.lines = ["The graph shows a straight line through the two points marked."]
		out.graph = Plot.spec([curve], [[0, s.c, "(0, %s)" % N(s.c)], [4, far, "(4, %s)" % N(far)]], 0, 4, lo, hi)
	else:
		out.lines = [line_text(s.m, s.c)]
	out.generic = [v2(s.c, s.m), v2(s.m, s.c), v2(s.u1 + s.m, s.m), v2(s.u1, -s.m)]
	var first: String = "The line has gradient %s and y-intercept %s." % [N(s.m), N(s.c)]
	if rep == "graph":
		first = "The gradient is (%s − %s)/(4 − 0) = %s, and the y-intercept is %s." % [N(s.c + 4 * s.m), P(s.c), N(s.m), N(s.c)]
	var at1 := "At x = 1, y = %s + %s = %s, so u₁ = %s." % [N(s.m), P(s.c), N(s.u1), N(s.u1)]
	var gap := "One step of x adds the gradient, so d = %s." % N(s.m)
	out.methods = {
		"rate-and-start": method([first, gap + " " + at1, fin(ans)], ans.values),
		"linear-function": method([first, "The terms are y at x = 1, 2, 3, …: %s, %s, %s, …" % [N(s.u1), N(term(s, 2)), N(term(s, 3))], gap, fin(ans)], ans.values),
		"nth-formula": method([first, "Match %s with uₙ = u₁ + (n − 1)d = dn + (u₁ − d): d = %s and u₁ − d = %s." % [Fmt.poly([s.m, s.c], "n"), N(s.m), N(s.c)], at1, fin(ans)], ans.values),
	}
	return out


# ── d as a gradient ──────────────────────────────────────────

func u_d_from_two_terms(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := named(["d", "u₁"], s.m, s.u1)
	var p: int = s.p
	var q: int = s.q
	var up: int = s.up
	var uq: int = s.uq
	var out := {"asked": "The sequence is arithmetic. Find d, as the gradient between the points (%d, u%s) and (%d, u%s), then u₁." % [p, sub(p), q, sub(q)], "answer": ans}
	match rep:
		"table":
			out.lines = ["The table shows two terms of an arithmetic sequence."]
			out.table = {"rows": [["n", [str(p), str(q)]], ["uₙ", [N(up), N(uq)]]]}
		"words":
			out.lines = ["Term number %d of an arithmetic sequence is %s, and term number %d is %s." % [p, N(up), q, N(uq)]]
		_:
			out.lines = ["u%s = %s and u%s = %s" % [sub(p), N(up), sub(q), N(uq)]]
	var rise: int = uq - up
	var run: int = q - p
	# Each slip finds its own d, and u₁ from it.
	var from := func(d: Q) -> Dictionary: return {"v0": d, "v1": d.mul(1 - p).add(up)}
	out.wrongs = [wrong(from.call(Q.new(run, rise)), R_RUN_RISE), wrong(from.call(Q.new(-s.m)), R_ORDER), wrong(from.call(Q.new(rise, run + 1)), R_TERMS)]
	out.generic = [v2(s.m, up), v2(s.m, s.c), v2(s.u1, s.m)]
	var u1_step := "Then u₁ = %s − %d × %s = %s." % [N(up), p - 1, P(s.m), N(s.u1)]
	var points := "On the points (%d, %s) and (%d, %s), " % [p, N(up), q, N(uq)]
	out.methods = {
		"two-point-formula": method([points + "d = (%s − %s)/(%d − %d) = %s." % [N(uq), P(up), q, p, N(s.m)], u1_step, fin(ans)], ans.values),
		"table-differences": method(["n goes up by %d while the term changes by %s." % [run, N(rise)], "Each step of 1 is %s ÷ %d = %s, so d = %s." % [N(rise), run, N(s.m), N(s.m)], u1_step, fin(ans)], ans.values),
		"gap-count": method(["From term %d to term %d there are %d gaps, each d." % [p, q, run], "So %d × d = %s, and d = %s." % [run, N(rise), N(s.m)], u1_step, fin(ans)], ans.values),
		"simultaneous": method(["u₁ + %d × d = %s and u₁ + %d × d = %s." % [p - 1, N(up), q - 1, N(uq)], "Subtract: %d × d = %s, so d = %s." % [run, N(rise), N(s.m)], u1_step, fin(ans)], ans.values),
	}
	return out


## A term's position as a subscript: "₁₀".
static func sub(n: int) -> String:
	var out := ""
	for ch in str(n):
		out += "₀₁₂₃₄₅₆₇₈₉"[int(ch)]
	return out


# ── Four kinds of rate ───────────────────────────────────────

static func matching(letters: Array, kinds: Array) -> String:
	var parts: Array = []
	for i in 4:
		parts.append("%s: %s" % [letters[i], kinds[i]])
	return "; ".join(parts)


func u_match_rate_kind(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var m: int = s.m
	var c: int = s.c
	var sq: String
	var ln: String
	var rg: String
	var dv: String
	if rep == "words":
		sq = "Row n of a theatre has uₙ seats, and each row has %d more seats than the row before." % m
		ln = "A tap adds water to a tank at exactly %d litres per minute, for any time t." % m
		rg = "A line fitted to data from 20 plants says each extra week goes with about %d cm more height." % m
		dv = "At the moment t = %d, the height of a kite is rising at %d metres per second." % [s.a, m]
	else:
		sq = "%s, for whole numbers n" % rule(s)
		ln = "%s, for every real x" % line_text(m, c)
		rg = "y = %s, the regression line of a scatter of data" % Fmt.terms([Q.new(m), s.b], [1, 0], "x", true)
		dv = "f′(%d) = %d, for a curve y = f(x)" % [s.a, m]
	var order: Array = rng.shuffled([[sq, KIND_WHOLE], [ln, KIND_ALL], [rg, KIND_FIT], [dv, KIND_NOW]])
	var letters := ["A", "B", "C", "D"]
	var lines: Array = []
	var kinds: Array = []
	for i in 4:
		lines.append("%s: %s" % [letters[i], order[i][0]])
		kinds.append(order[i][1])
	var right := matching(letters, kinds)
	# A wrong matching swaps two of them: the fitted model read as exact first.
	var at := func(k: String) -> int: return kinds.find(k)
	var swapped := func(k1: String, k2: String) -> String:
		var w: Array = kinds.duplicate()
		w[at.call(k1)] = k2
		w[at.call(k2)] = k1
		return matching(letters, w)
	var out := {"asked": "Each of A to D goes up by %d per step. Say which is an exact rule for whole steps, which is an exact rule for every x, which is a fitted model, and which is a rate at one instant." % m, "lines": lines}
	out.merge(InverseRuleViews.choose(right, [], [swapped.call(KIND_FIT, KIND_ALL), swapped.call(KIND_NOW, KIND_ALL), swapped.call(KIND_WHOLE, KIND_ALL), swapped.call(KIND_FIT, KIND_NOW)]))
	var seq_says := "The sequence has a term only at whole n, so its rule is exact for whole steps."
	var line_says := "The line is exact at every x."
	var reg_says := "The regression line is fitted to scattered data, so its gradient is an average."
	var der_says := "The derivative is a rate at one instant; at other times it can differ."
	out.methods = {
		"rate-and-start": method([seq_says + " " + line_says, reg_says + " " + der_says, right + "."], {"v": right}),
		"per-unit-sentence": method(["Say each as \"for each one step\": the sequence per term, the line per unit of x.", reg_says, der_says, right + "."], {"v": right}),
		"units-ratio": method(["All four are a change in output over a change in input, %d per step." % m, "What differs is where it holds: whole n, every x, on average, or at one instant.", right + "."], {"v": right}),
	}
	return out


# ── A regression gradient ────────────────────────────────────

func u_interpret_regression_gradient(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var r: Dictionary = REG[s.ctx]
	var a: Q = s.a.abs_q()
	var av := D(a)
	var bv := D(s.b)
	var eq := "y = " + Fmt.terms([s.a, s.b], [1, 0], "x", true)
	var lines: Array
	if rep == "equation":
		lines = ["%s is the regression line of y on x." % eq, "x is %s in %s and y is %s in %s." % [r.x, r.xu, r.y, r.yu]]
	else:
		lines = ["A line fitted to data from 30 %s predicts %s, y %s, from %s, x %s." % [r.n, r.y, r.yu, r.x, r.xu], "Its gradient is %s and its y-intercept is %s." % [D(s.a), bv]]
	var say := func(v: String) -> String: return "Each extra %s goes with about %s %s on average; real points sit above and below the line" % [r.each, v, r.up]
	var right: String = say.call(av)
	var bad: Array = [InverseRuleViews.tag(r.total.replace("%v", av), R_TOTAL), InverseRuleViews.tag("Each extra %s goes with about %s %s on average, from a start of %s" % [r.each, bv, r.up, av], R_AB_SWAP)]
	var exact: String = r.exact.replace("%v", av)
	# "Is the gradient" says nothing of the context: half the time it takes the exact reading's place.
	if rng.chance(0.5):
		bad.append(InverseRuleViews.tag("%s is the gradient" % D(s.a), R_AB_BARE))
	var out := {"asked": "What does the gradient mean?", "lines": lines}
	out.merge(InverseRuleViews.choose(right, bad, [exact]))
	var unit: String = "The gradient's units are %s per %s." % [r.yu, r.each.split(" ")[0]]
	out.methods = {
		"rate-and-start": method(["%s is the number multiplying x, so it is the rate, and %s is the start." % [D(s.a), bv], unit, right + "."], {"v": right}),
		"per-unit-sentence": method(["Say it per one unit of x: %s %s for each extra %s." % [av, r.up, r.each], "It is fitted to scattered data, so it is an average, not an exact step.", right + "."], {"v": right}),
	}
	return out


# ── A derivative in context ──────────────────────────────────

func u_derivative_in_context(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = DERIV[s.ctx]
	var at: int = s.at
	var size: int = absi(s.k)
	var way := "falling" if s.k < 0 else "rising"
	var other := "rising" if s.k < 0 else "falling"
	var say := func(w: String, unit: String) -> String: return "At t = %d, %s is %s at %d %s, at that instant only" % [at, c.of, w, size, unit]
	var right: String = say.call(way, c.per)
	var out := {"asked": "What does this mean?", "lines": ["%s(t) is %s, in %s, t %s after %s." % [c.f, c.in, c.u, c.t, c.after], "%s′(%d) = %s" % [c.f, at, N(s.k)]]}
	var bad: Array = [InverseRuleViews.tag(say.call(way, c.u), R_UNITS)]
	if s.k < 0:
		bad.push_front(InverseRuleViews.tag(say.call(other, c.per), R_SIGN))
	var line := "%s%s %s at %d %s at every time, like a straight line" % [c.of.left(1).to_upper(), c.of.substr(1), "falls" if s.k < 0 else "rises", size, c.per]
	var value := "At t = %d, %s is %d %s" % [at, c.of, size, c.u]
	out.merge(InverseRuleViews.choose(right, bad, [line, value, say.call(other, c.per)]))
	var differs := "A line's gradient is the same at every point; this rate holds at t = %d only." % at
	out.methods = {
		"units-ratio": method(["%s′ is a change in %s over a change in t, so its units are %s." % [c.f, c.f, c.per], differs, right + "."], {"v": right}),
		"sign-direction": method(["The sign is %s, so %s is %s." % ["negative" if s.k < 0 else "positive", c.of, way], "The size, %d, is how fast, in %s. %s" % [size, c.per, differs], right + "."], {"v": right}),
	}
	return out


# ── Chords and tangents ──────────────────────────────────────

static func curve(s: Dictionary) -> String:
	return "y = " + (Fmt.terms([s.p, s.q], [3, 1], "x", true) if s.cubic else Fmt.poly([s.k, 0, 0]))


static func f_at(s: Dictionary, x: Q) -> Q:
	return s.p.mul(x).mul(x).mul(x).add(s.q.mul(x)) if s.cubic else x.mul(x).mul(s.k)


static func chord(s: Dictionary, h: Variant) -> Q:
	var q: Q = Q.of(h)
	return s.A.add(s.B.mul(q)).add(s.C.mul(q).mul(q))


## The general chord gradient, A + Bh + Ch².
static func chord_form(s: Dictionary) -> String:
	return Fmt.terms([s.C, s.B, s.A], [2, 1, 0], "h", true)


## The curve drawn around x0, with marked points.
static func curve_plot(s: Dictionary, x1: Q, marks: Array) -> Dictionary:
	var lo: int = floori(s.x0.to_float()) - 2
	var hi: int = ceili(x1.to_float()) + 2
	var f := func(x: float) -> float:
		return s.p.to_float() * x * x * x + s.q.to_float() * x if s.cubic else float(s.k) * x * x
	var top := -INF
	var bot := INF
	for i in range(0, 41):
		var y: float = f.call(lo + (hi - lo) * i / 40.0)
		top = maxf(top, y)
		bot = minf(bot, y)
	var cv := Plot.sample(f, float(lo), float(hi))
	var pts: Array = marks.map(func(p): return [Q.of(p[0]).to_float(), Q.of(p[1]).to_float(), "(%s, %s)" % [D(p[0]), D(p[1])]])
	return Plot.spec([cv], pts, lo, hi, floori(minf(bot, 0.0)) - 1, ceili(maxf(top, 0.0)) + 1)


func u_chord_to_limit(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var x0: Q = s.x0
	var h: Q
	var out := {"lines": ["%s, at x = %s" % [curve(s), N(x0)]]}
	match rep:
		"table":
			h = Q.new(1, 1000)
			out.lines = ["%s. The table shows the gradient of the chord from x = %s to x = %s + h." % [curve(s), N(x0), N(x0)]]
			var hs := [Q.new(1, 10), Q.new(1, 100)]
			out.table = {"rows": [["h", hs.map(func(v): return D(v))], ["chord gradient", hs.map(func(v): return D(chord(s, v)))]]}
		"graph":
			h = Q.new(1)
			out.lines = ["The graph shows %s and a chord between the two points marked." % curve(s)]
			out.graph = curve_plot(s, x0.add(h), [[x0, f_at(s, x0)], [x0.add(h), f_at(s, x0.add(h))]])
		_:
			h = rng.pick([Q.new(1, 10), Q.new(1, 100)])
	var x1: Q = x0.add(h)
	var g := chord(s, h)
	out.asked = "Find the gradient of the chord from x = %s to x = %s, then the gradient of the tangent at x = %s." % [N(x0), D(x1), N(x0)]
	var ans := named(["chord", "tangent"], g, s.A)
	out.answer = ans
	var y0: Q = f_at(s, x0)
	var y1: Q = f_at(s, x1)
	var rise: Q = y1.sub(y0)
	out.wrongs = [wrong(v2(g, g), R_ONE_CHORD)]
	out.generic = [v2(g, y0), v2(rise, s.A), v2(g, s.A.add(s.B)), v2(g, s.A.div(2))]
	var limit := "In general the chord gradient is %s, which tends to %s as h shrinks to 0." % [chord_form(s), N(s.A)]
	var run := "The run is %s and the rise is %s − %s = %s." % [D(h), D(y1), PD(y0), D(rise)]
	var inner := "%s(%s + h)² − %s" % [Fmt.lead(s.k), N(x0), PD(y0)]
	out.methods = {
		"two-point-formula": method(["The points are (%s, %s) and (%s, %s)." % [N(x0), D(y0), D(x1), D(y1)], "m = (%s − %s)/(%s − %s) = %s." % [D(y1), PD(y0), D(x1), PD(x0), D(g)], limit, fin(ans)], ans.values),
		"rise-over-run": method([run, "The gradient is rise ÷ run = %s." % D(g), limit, fin(ans)], ans.values),
		"chord-sequence": method(["For h = 1, 0.1, 0.01 the chord gradients are %s, %s, %s." % [D(chord(s, 1)), D(chord(s, Q.new(1, 10))), D(chord(s, Q.new(1, 100)))], "With h = %s the chord gradient is %s, and they close in on %s." % [D(h), D(g), N(s.A)], fin(ans)], ans.values),
		"simplify-difference-quotient": method(["The chord gradient is (%s)/h." % inner, "Multiply out and cancel h: %s." % chord_form(s), "Put h = %s for the chord, and h → 0 for the tangent." % D(h), fin(ans)], ans.values),
	}
	return out


func u_tangent_gradient_methods(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x0: Q = s.x0
	var ans: Dictionary = InverseRuleViews.number("gradient = ", s.A)
	ans.show = "dec"
	if s.cubic:
		ans.erase("exact")
		ans.show = "sf"
	var y0: Q = f_at(s, x0)
	var A := D(s.A)
	var out := {"asked": "Find the gradient of the tangent at x = %s." % D(x0), "lines": [curve(s)], "answer": ans}
	if rep == "graph":
		out.lines = ["The graph shows %s with the point at x = %s marked." % [curve(s), D(x0)]]
		out.graph = curve_plot(s, x0.add(1), [[x0, y0]])
	var one: Q = chord(s, Q.new(1, 10))
	out.wrongs = [wrong({"v": one}, R_ONE_CHORD), wrong({"v": y0}, R_F_NOT_DF)]
	out.generic = [{"v": s.A.div(2)}, {"v": s.A.neg()}, {"v": chord(s, 1)}, {"v": s.A.add(s.B)}]
	var deriv: String = "f′(x) = %s" % (Fmt.terms([s.p.mul(3), s.q], [2, 0], "x", true) if s.cubic else Fmt.poly([s.k * 2, 0]))
	var sub: String = "f′(%s) = %s = %s" % [D(x0), _at_text(s), A]
	var two: Q = chord(s, Q.new(1, 100))
	out.methods = {
		"differentiate-substitute": method(["The power rule gives %s." % deriv, "%s." % sub, fin(ans)], ans.values),
		"simplify-difference-quotient": method(["The chord gradient from x = %s to x = %s + h simplifies to %s." % [D(x0), D(x0), chord_form(s)], "Let h shrink to 0: the gradient is %s." % A, fin(ans)], ans.values),
		"chord-sequence": method(["For h = 0.1 and h = 0.01 the chord gradients are %s and %s." % [D(one), D(two)], "They close in on %s, but no chord reaches it: the limit of %s gives the exact value." % [A, chord_form(s)], fin(ans)], ans.values),
		"gdc-dydx": method(["Enter %s and use dy/dx at x = %s: %s." % [curve(s), D(x0), A], fin(ans)], ans.values),
	}
	return out


## f′(x0) with x0 put in, as written: "3 × 0.3 × 1.7² + (−1.2)" or "4 × (−1)".
static func _at_text(s: Dictionary) -> String:
	if s.cubic:
		return "3 × %s × %s²%s" % [D(s.p), D(s.x0), (" − " if s.q.sign() < 0 else " + ") + D(s.q.abs_q())]
	return "%d × %s" % [s.k * 2, PD(s.x0)]


# ── A constant derivative ────────────────────────────────────

func u_constant_derivative(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := line_ans(s.m, s.c)
	var out := {"answer": ans}
	var m: int = s.m
	if rep == "words":
		out.asked = "Find y in terms of x, in the form y = mx + c."
		out.lines = ["y goes %s by exactly %d per unit of x, at every x." % ["up" if m > 0 else "down", absi(m)], "y = %s when x = %s." % [N(s.y0), N(s.x0)]]
	else:
		out.asked = "Find f. Give it in the form y = mx + c."
		out.lines = ["f′(x) = %s for every x, and f(%s) = %s." % [N(m), N(s.x0), N(s.y0)]]
	out.generic = [{"m": Q.new(m), "c": Q.new(s.y0)}, {"m": Q.new(m), "c": Q.new(s.y0 + m * s.x0)}, {"m": Q.new(-m), "c": Q.new(s.y0 + m * s.x0)}, {"m": Q.new(s.y0), "c": Q.new(m)}]
	var c_step := "Put in the point: %s = %s × %s + c, so c = %s." % [N(s.y0), P(m), P(s.x0), N(s.c)]
	out.methods = {
		"rate-and-start": method(["The gradient is %s at every x, so the graph is a straight line with m = %s." % [N(m), N(m)], c_step, fin(ans)], ans.values),
		"sign-direction": method(["The rate is %s at every x, so the graph %s at one steady rate: a straight line with m = %s." % ["negative" if m < 0 else "positive", "falls" if m < 0 else "rises", N(m)], c_step, fin(ans)], ans.values),
	}
	return out
