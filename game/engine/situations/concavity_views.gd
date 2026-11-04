class_name ConcavityViews
extends ExtensionViews
## The views on the `concavity` situation: one builder per unknown of t5-concavity
## (FAL-723). A second derivative is a `form` answer, an interval is a side of a number or
## MonotonicViews' interval, and matching graphs is a pick-the-graph question: f on the
## screen and four candidates, each wrong card one typical mistake.
##
## Representations: "equation", "words", "graph" and "table" (a row of signs).

const SF := "SL5.7.find-second-derivative#"
const SC := "SL5.7.concavity#"
const SM := "SL5.7.sketch-match-graphs#"
const R_SQUARED := SF + "0"
const R_F_AGAIN := SF + "1"
const R_READ_SQ := SF + "2"
const R_INCREASING := SC + "0"
const R_DECREASING := SC + "1"
const R_F_POS := SC + "2"
const R_SHIFTED := SM + "0"
const R_INTERCEPTS := SM + "1"
const R_ABOVE := SM + "2"
const WIN_PAD := 2.0


func needs() -> Dictionary:
	var out := {}
	for u in ["second-derivative", "second-derivative-value", "concave-interval", "concave-exponential", "concave-gdc",
			"concave-from-derivative-graph", "concave-at-point", "match-derivative", "match-second-derivative", "match-from-signs"]:
		out[u] = {"ask": u}
	return out


## The GDC methods are Paper 2; a value of f″ has its own Paper 2 numbers; the rest is Paper 1.
func papers(unknown: String, _rep: String, angle: String) -> Array:
	if not has(unknown):
		return []
	if unknown == "concave-gdc" or angle in ["gdc-gradient-of-derivative", "gdc-nderiv"]:
		return [2]
	return [1, 2] if unknown == "second-derivative-value" else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = ConcavitySituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func T(c: Variant, body: String) -> String:
	return DifferentiationViews.T(c, body)


static func SUM(terms: Array) -> String:
	return DifferentiationViews.SUM(terms)


static func EX(c: int) -> String:
	return DifferentiationViews.E(c)


static func form(text: String, parts: Array, slots: Dictionary) -> Dictionary:
	return DifferentiationViews.form(text, parts, slots)


static func alt(text: String, ref: String = "", slots: Dictionary = {}) -> Dictionary:
	return DifferentiationViews.alt(text, ref, slots)


static func cubic_fn(s: Dictionary) -> Callable:
	return func(x: float) -> float:
		return float(s.A) * x * x * x + float(s.coeffs[1]) * x * x + float(s.coeffs[2]) * x + float(s.d)


static func cubic_d1(s: Dictionary) -> Callable:
	return func(x: float) -> float: return 3.0 * s.A * (x - s.p) * (x - s.q)


static func cubic_d2(s: Dictionary) -> Callable:
	return func(x: float) -> float: return 6.0 * s.A * x + 2.0 * float(s.coeffs[1])


# ── The second derivative ────────────────────────────────────

func u_second_derivative(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var d: int = s.d
	var e: int = s.e
	var is_f: bool = s.name == "f"
	var lhs := "f(x)" if is_f else "y"
	var d1 := "f′(x) = " if is_f else "dy/dx = "
	var d2 := "f″(x) = " if is_f else "d²y/dx² = "
	var fx := ""
	var first := ""
	var slots: Array
	var parts: Array = []
	var w: Callable
	match s.fam:
		"poly":
			fx = SUM([[a, "x⁴"], [b, "x³"], [c, "x²"], [d, "x"]])
			first = SUM([[4 * a, "x³"], [3 * b, "x²"], [2 * c, "x"], [d, ""]])
			slots = [12 * a, 6 * b, 2 * c]
			parts = [{"slot": "c0"}, "x² + ", {"slot": "c1"}, "x + ", {"slot": "c2"}]
			w = func(p: int, q: int, r: int) -> String: return SUM([[p, "x²"], [q, "x"], [r, ""]])
		"exp":
			fx = SUM([[a, "x³"], [b, EX(e)], [d, ""]])
			first = SUM([[3 * a, "x²"], [b * e, EX(e)]])
			slots = [6 * a, b * e * e]
			parts = [{"slot": "c0"}, "x + ", {"slot": "c1"}, EX(e)]
			w = func(p: int, q: int) -> String: return SUM([[p, "x"], [q, EX(e)]])
		"ln":
			fx = SUM([[a, "x²"], [b, "ln x"], [d, "x"]])
			first = SUM([[2 * a, "x"], [b, "/x"], [d, ""]])
			slots = [2 * a, -b]
			parts = [{"slot": "c0"}, " + ", {"slot": "c1"}, "/x²"]
			w = func(p: int, q: int) -> String: return SUM([[p, ""], [q, "/x²"]])
		"sin", "cos":
			var cos: bool = s.fam == "cos"
			var t := "cos x" if cos else "sin x"
			var dt := "sin x" if cos else "cos x"
			fx = SUM([[a, "x³"], [b, t], [d, "x"]])
			first = SUM([[3 * a, "x²"], [-b if cos else b, dt], [d, ""]])
			slots = [6 * a, -b]
			parts = [{"slot": "c0"}, "x + ", {"slot": "c1"}, " " + t]
			w = func(p: int, q: int) -> String: return SUM([[p, "x"], [q, t]])
	var keys: Array = ["c0", "c1", "c2"].slice(0, slots.size())
	var values := {}
	for i in slots.size():
		values[keys[i]] = Q.new(slots[i])
	var ans := form(d2 + w.callv(slots), [d2] + parts, values)
	var sl := func(v: Array) -> Dictionary:
		var d0 := {}
		for i in v.size():
			d0[keys[i]] = Q.new(v[i])
		return alt(d2 + w.callv(v), "", d0).values
	var gen: Array = []
	for i in slots.size():
		var v := slots.duplicate()
		v[i] = -v[i]
		gen.append(sl.call(v))
		var u := slots.duplicate()
		u[i] = u[i] + 1
		gen.append(sl.call(u))
	var dom := ", for x > 0" if s.fam == "ln" else ""
	var wr: Array = [alt(d2 + "(%s)²" % first, R_SQUARED if is_f else R_READ_SQ), alt(d2 + first, R_F_AGAIN)]
	return {"lines": ["%s = %s%s" % [lhs, fx, dom]], "asked": "Find %s." % ("f″(x)" if is_f else "d²y/dx²"), "answer": ans, "wrongs": wr, "generic": gen,
		"methods": {"differentiate-twice": method([
			"Differentiate once: %s%s." % [d1, first],
			"Differentiate that again, term by term.",
			Answer.text(ans)], ans.values)}}


func u_second_derivative_value(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	if s.paper == 2:
		return _value_paper_2(s)
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var k: int = s.k
	var p4: bool = s.fam == "quartic"
	# f′ as coefficients of x³, x², x, 1.
	var d1: Array = [4 * a, 3 * b, 2 * c, 7] if p4 else [0, 3 * a, 2 * b, c]
	var fx: String = SUM([[a, "x⁴"], [b, "x³"], [c, "x²"], [7, "x"]]) if p4 else SUM([[a, "x³"], [b, "x²"], [c, "x"]])
	var first: String = Fmt.poly(d1)
	var second: Array = [3 * d1[0], 2 * d1[1], d1[2]]
	var f2: int = second[0] * k * k + second[1] * k + second[2]
	var f1: int = d1[0] * k * k * k + d1[1] * k * k + d1[2] * k + d1[3]
	var head := "f″(%s) = " % Fmt.num(k)
	var ans := form(head + Fmt.num(f2), [head, {"slot": "v"}], {"v": Q.new(f2)})
	var sl := func(v: int, ref: String = "") -> Dictionary:
		return alt(head + Fmt.num(v), ref, {"v": Q.new(v)})
	var given_prime: bool = s.fam == "given-prime"
	var line: String = "f′(x) = " + first if given_prime else "f(x) = " + fx
	var asked: String = "Find the gradient of the graph of f′ at x = %s." % Fmt.num(k) if given_prime else "Find f″(%s)." % Fmt.num(k)
	var wr: Array = [sl.call(f1 * f1, R_SQUARED), sl.call(f1, R_F_AGAIN)]
	return {"lines": [line], "asked": asked, "answer": ans, "wrongs": wr,
		"generic": [sl.call(-f2).values, sl.call(f2 + 1).values, sl.call(f2 - 1).values, sl.call(2 * f2).values, sl.call(f2 + 2).values],
		"methods": {"differentiate-twice": method([
			("f″ is the gradient of the graph of f′. Differentiate f′(x): f″(x) = %s." if given_prime else "Differentiate twice: f″(x) = %s.") % Fmt.poly(second),
			"Put x = %s." % Fmt.num(k),
			Answer.text(ans)], ans.values),
		"gdc-gradient-of-derivative": method([
			"Graph y = f′(x) on the GDC: y = %s." % first,
			"dy/dx at x = %s gives the gradient of f′." % Fmt.num(k),
			Answer.text(ans)], ans.values)}}


func _value_paper_2(s: Dictionary) -> Dictionary:
	var kt := Fmt.dec(s.k)
	var v: float = ConcavitySituation.second_value(s)
	var d: float = ConcavitySituation.first_value(s)
	var fx: String = "%s + %s" % [EX(s.c), T(s.a, "x²")] if s.fam == "exp" else "x² ln x"
	var first: String = "%s + %s" % [T(s.c, EX(s.c)), T(2 * s.a, "x")] if s.fam == "exp" else "2x ln x + x"
	var second: String = "%s + %s" % [T(s.c * s.c, EX(s.c)), Fmt.num(2 * s.a)] if s.fam == "exp" else "2 ln x + 3"
	var ans := Answer.make("number", {"v": GdcKit.qf(v)}, {}, "f″(%s) = " % kt)
	ans.show = "sf"
	var wr: Array = [wrong({"v": GdcKit.qf(d)}, R_F_AGAIN), wrong({"v": GdcKit.qf(d * d)}, R_SQUARED)]
	return {"lines": ["f(x) = %s%s" % [fx, ", for x > 0" if s.fam == "ln" else ""]], "asked": "Find f″(%s), to 3 s.f." % kt, "answer": ans, "wrongs": wr,
		"generic": [{"v": GdcKit.qf(v * 2.0)}, {"v": GdcKit.qf(v * 0.5)}, {"v": GdcKit.qf(v + 1.0)}, {"v": GdcKit.qf(-v)}],
		"methods": {"differentiate-twice": method([
			"f′(x) = %s." % first,
			"f″(x) = %s. Put x = %s: %s." % [second, kt, GdcKit.W(v)],
			Answer.text(ans)], ans.values),
		"gdc-gradient-of-derivative": method([
			"Graph y = f′(x) on the GDC: y = %s." % first,
			"dy/dx at x = %s: %s." % [kt, GdcKit.W(v)],
			Answer.text(ans)], ans.values)}}


# ── Where a graph is concave up or down ──────────────────────

func u_concave_interval(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var up: bool = s.want == "up"
	var fx := Fmt.poly(s.coeffs)
	var lines: Array = ["A curve has equation y = %s." % fx] if rep == "words" else ["f(x) = %s" % fx]
	var asked := "Find the set of values of x for which the curve is concave %s." % s.want if rep == "words" else "Find the values of x for which the graph of f is concave %s." % s.want
	var rel2 := "> 0" if up else "< 0"
	var A: int = s.A
	if s.fam == "cubic":
		var h: int = (s.p + s.q) / 2
		var more: bool = (A > 0) == up
		var ans := MonotonicViews.side(">" if more else "<", h)
		var f2 := Fmt.poly([6 * A, -6 * A * h])
		var df := Fmt.poly([3 * A, -6 * A * h, 3 * A * s.p * s.q])
		var inc := MonotonicViews.interval_text("outside" if A > 0 else "between", s.p, s.q)
		return {"lines": lines, "asked": asked, "answer": ans,
			"wrongs": [alt(inc, R_INCREASING), wrong(MonotonicViews.side("<" if more else ">", h).values, "")],
			"generic": [MonotonicViews.side(">" if more else "<", h + 1).values, MonotonicViews.side(">" if more else "<", h - 1).values, MonotonicViews.side("<" if more else ">", h + 1).values, MonotonicViews.side(">" if more else "<", -h if h != 0 else 2).values],
			"methods": {"sign-of-second-derivative": method([
				"f″(x) = %s." % f2,
				"Concave %s means f″(x) %s, and %s changes sign at x = %s." % [s.want, rel2, f2, Fmt.num(h)],
				Answer.text(ans)], ans.values),
			"f-prime-increasing": method([
				"Concave %s means f′ is %s. f′(x) = %s is a parabola with its vertex at x = %s." % [s.want, "increasing" if up else "decreasing", df, Fmt.num(h)],
				"It opens %s, so it is %s on the %s of its vertex." % ["up" if A > 0 else "down", "increasing" if up else "decreasing", "right" if more else "left"],
				Answer.text(ans)], ans.values)}}
	var between: bool = (A > 0) != up
	var shape := "between" if between else "outside"
	var ans := MonotonicViews.interval(shape, s.p, s.q)
	var f2 := Fmt.poly([12 * A, -12 * A * (s.p + s.q), 12 * A * s.p * s.q])
	return {"lines": lines, "asked": asked, "answer": ans,
		"wrongs": [MonotonicViews.alt_iv(MonotonicViews.other(shape), s.p, s.q, "")],
		"generic": [MonotonicViews.alt_iv(shape, s.p - 1, s.q).values, MonotonicViews.alt_iv(shape, s.p, s.q + 1).values, MonotonicViews.alt_iv(MonotonicViews.other(shape), s.p - 1, s.q + 1).values, MonotonicViews.alt_iv(shape, s.p - 1, s.q + 1).values],
		"methods": {"sign-of-second-derivative": method([
			"f″(x) = %s = %s(x%s)(x%s)." % [f2, Fmt.lead(12 * A), Fmt.plus(-s.p), Fmt.plus(-s.q)],
			"Concave %s means f″(x) %s. The parabola f″ opens %s, so that holds %s the roots." % [s.want, rel2, "up" if A > 0 else "down", shape],
			Answer.text(ans)], ans.values),
		"f-prime-increasing": method([
			"Concave %s means f′ is %s, so look at the turning points of f′: x = %s and x = %s." % [s.want, "increasing" if up else "decreasing", Fmt.num(s.p), Fmt.num(s.q)],
			"f′ is %s %s them." % ["increasing" if up else "decreasing", shape],
			Answer.text(ans)], ans.values)}}


func u_concave_exponential(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var up: bool = s.want == "up"
	var h: int = -b / a
	var more: bool = (a > 0) == up
	var rel := ">" if more else "<"
	var flip := "<" if more else ">"
	var ans := MonotonicViews.side(rel, h)
	var f2 := "(%s)%s" % [SUM([[a, "x"], [b, ""]]), EX(c)]
	return {"lines": ["f″(x) = " + f2], "asked": "Find the values of x for which the graph of f is concave %s." % s.want, "answer": ans,
		"wrongs": [wrong(MonotonicViews.side(flip, h).values, "")],
		"generic": [MonotonicViews.side(rel, h + 1).values, MonotonicViews.side(rel, h - 1).values, MonotonicViews.side(rel, -h if h != 0 else 3).values, MonotonicViews.side(flip, h + 2).values],
		"methods": {"sign-of-second-derivative": method([
			"%s is always positive, so f″ has the sign of %s." % [EX(c), SUM([[a, "x"], [b, ""]])],
			"Concave %s means f″(x) %s 0: %s %s 0." % [s.want, ">" if up else "<", SUM([[a, "x"], [b, ""]]), ">" if up else "<"],
			Answer.text(ans)], ans.values)}}


func u_concave_gdc(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var up: bool = s.want == "up"
	var v: float = log(float(s.b) / s.c)
	var line := "f′(x) = %d + %s − %se^x" % [s.a, T(s.b, "x"), Fmt.lead(s.c)]
	var rel := "<" if up else ">"
	var flip := ">" if up else "<"
	var w := func(r: String, x: float, ref: String = "") -> Dictionary:
		return alt("x %s %s" % [r, Fmt.sf(x)], ref, {"rel": r, "v": GdcKit.qf(x)})
	var ans := DifferentiationViews.form("x %s %s" % [rel, Fmt.sf(v)], ["x ", {"pick": "rel", "options": ["<", ">"]}, " ", {"slot": "v"}], {"rel": rel, "v": GdcKit.qf(v)})
	ans.exact = false
	var inc := MonotonicViews.interval_text("between", s.r1, s.r2, "x", true)
	var wr: Array = [w.call(flip, v), alt(inc, R_INCREASING)]
	return {"lines": [line], "asked": "Find the values of x for which the graph of f is concave %s. Give your answer to 3 s.f." % s.want, "answer": ans, "wrongs": wr,
		"generic": [w.call(rel, v + 1.0).values, w.call(rel, s.r1).values, w.call(flip, s.r2).values, w.call(rel, v - 1.0).values],
		"methods": {"sign-of-second-derivative": method([
			"f″(x) = %d − %se^x." % [s.b, Fmt.lead(s.c)],
			"f″ falls as x grows, and it is 0 at x = ln(%s) = %s." % [Q.new(s.b, s.c).text(), GdcKit.W(v)],
			Answer.text(ans)], ans.values),
		"gdc-shape": method([
			"Graph y = f′(x) on the GDC. It has one maximum, at x = %s." % GdcKit.W(v),
			"f′ is increasing to the left of it and decreasing to the right, and concave up means f′ is increasing.",
			Answer.text(ans)], ans.values)}}


func u_concave_from_derivative_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var h: int = s.h
	var r: int = s.r
	var t: int = s.s
	var up: bool = s.want == "up"
	var rel := ">" if (a > 0) == up else "<"
	var flip := "<" if rel == ">" else ">"
	var ans := MonotonicViews.side(rel, h)
	var g := MonotonicViews.graph_of(MonotonicViews.quad_fn(s), r - 2.0, t + 2.0, [[float(h), float(s.k), Fmt.point(h, s.k)], [float(r), 0.0, Fmt.point(r, 0)], [float(t), 0.0, Fmt.point(t, 0)]])
	var above := MonotonicViews.interval_text("outside" if a > 0 else "between", r, t)
	return {"lines": ["The graph shows y = f′(x), the derivative of f."], "graph": g, "asked": "Find the values of x for which the graph of f is concave %s." % s.want, "answer": ans,
		"wrongs": [alt(above, R_INCREASING), wrong(MonotonicViews.side(flip, h).values, "")],
		"generic": [MonotonicViews.side(rel, h + 1).values, MonotonicViews.side(rel, h - 1).values, MonotonicViews.side(flip, h + 1).values, MonotonicViews.side(rel, r).values],
		"methods": {"f-prime-increasing": method([
			"This is f′. Concave %s means f′ is %s, so read its direction, not its height." % [s.want, "increasing" if up else "decreasing"],
			"f′ turns at its vertex, x = %s." % Fmt.num(h),
			Answer.text(ans)], ans.values)}}


func u_concave_at_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var A: int = s.A
	var h: int = (s.p + s.q) / 2
	var f2: int = 6 * A * (k - h)
	var word := "up" if f2 > 0 else "down"
	var flip := "down" if f2 > 0 else "up"
	var w := func(v: int, c: String) -> String: return "f″(%s) = %s, so the curve is concave %s" % [Fmt.num(k), Fmt.num(v), c]
	var parts: Array = ["f″(%s) = " % Fmt.num(k), {"slot": "v"}, ", so the curve is concave ", {"pick": "c", "options": ["up", "down"]}]
	var ans := form(w.call(f2, word), parts, {"v": Q.new(f2), "c": word})
	var sl := func(v: int, c: String, ref: String = "") -> Dictionary:
		return alt(w.call(v, c), ref, {"v": Q.new(v), "c": c})
	var d1: int = 3 * A * (k - s.p) * (k - s.q)
	# A student who reads the shape from the direction: up where f rises, down where it falls.
	var by_dir := "up" if d1 > 0 else "down"
	var wr: Array = []
	if by_dir != word:
		wr.append(sl.call(f2, by_dir, R_INCREASING if d1 > 0 else R_DECREASING))
	wr.append(sl.call(d1, "up" if d1 > 0 else "down", ""))
	var fx := Fmt.poly(s.coeffs)
	var y0 := MonotonicSituation.f_at(s, Q.new(k))
	var out := {"lines": ["f(x) = %s" % fx], "asked": "Find f″(%s), and say whether the curve is concave up or down there." % Fmt.num(k), "answer": ans, "wrongs": wr,
		"generic": [sl.call(f2, flip).values, sl.call(-f2, flip).values, sl.call(f2 + 1, word).values, sl.call(2 * f2, word).values],
		"methods": {"sign-of-second-derivative": method([
			"f″(x) = %s." % Fmt.poly([6 * A, -6 * A * h]),
			"f″(%s) = %s, which is %s." % [Fmt.num(k), Fmt.num(f2), "positive" if f2 > 0 else "negative"],
			Answer.text(ans)], ans.values),
		"tangent-position": method([
			"f″(x) = %s, so f″(%s) = %s." % [Fmt.poly([6 * A, -6 * A * h]), Fmt.num(k), Fmt.num(f2)],
			"Near x = %s the curve sits %s its tangent, which is what concave %s means." % [Fmt.num(k), "above" if f2 > 0 else "below", word],
			Answer.text(ans)], ans.values)}}
	if rep == "graph":
		var g := MonotonicViews.cubic_graph(s, false)
		var slope := float(d1)
		var y := y0.to_float()
		g.curves.append(GdcKit.curve(func(x: float) -> float: return y + slope * (x - k), k - 1.5, k + 1.5))
		g.points.append({"x": float(k), "y": y, "label": "P"})
		out.graph = g
		out.lines = ["The graph shows y = f(x), where f(x) = %s, with the tangent at P, where x = %s." % [fx, Fmt.num(k)]]
	return out


# ── Matching the graphs of f, f′ and f″ ──────────────────────

## The window every card shares: it holds f, f′ and f″ on p − 2 ≤ x ≤ q + 2.
static func card_win(s: Dictionary) -> Array:
	var lo: float = s.p - WIN_PAD
	var hi: float = s.q + WIN_PAD
	var ylo := INF
	var yhi := -INF
	for f in [cubic_fn(s), cubic_d1(s), cubic_d2(s)]:
		for p in GdcKit.curve(f, lo, hi):
			ylo = minf(ylo, p[1])
			yhi = maxf(yhi, p[1])
	return [floori(lo), ceili(hi), floori(ylo) - 1, ceili(yhi) + 1]


static func card_of(f: Callable, win: Array) -> Dictionary:
	var c: Array = GdcKit.curve(f, float(win[0]), float(win[1])).filter(func(p): return p[1] >= win[2] and p[1] <= win[3])
	return GdcKit.card([c], [], win)


static func one_wrong(graph: Dictionary, mistake: String, ref: String, why: String) -> Dictionary:
	return {"graph": graph, "mistake": mistake, "ref": ref, "why": why}


func u_match_derivative(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var win := card_win(s)
	var d1 := cubic_d1(s)
	var f := cubic_fn(s)
	var p: int = s.p
	var q: int = s.q
	var zs: Array = GdcKit.zeros(f, float(win[0]), float(win[1]))
	var wrongs: Array = [one_wrong(card_of(func(x: float) -> float: return f.call(x) - 4.0, win), "shifted", R_SHIFTED, "it is a copy of f, moved down"),
		one_wrong(card_of(func(x: float) -> float: return -d1.call(x), win), "flipped", "", "it is negative where f goes up")]
	if zs.size() >= 2 and absf(zs[0] - p) > 0.4:
		var z0: float = zs[0]
		var z1: float = zs[zs.size() - 1]
		wrongs.append(one_wrong(card_of(func(x: float) -> float: return 3.0 * s.A * (x - z0) * (x - z1), win), "intercepts", R_INTERCEPTS, "its zeros are at the x-intercepts of f, not at the turning points"))
	else:
		wrongs.append(one_wrong(card_of(func(x: float) -> float: return d1.call(x - 1.0), win), "moved", R_INTERCEPTS, "its zeros are not at the turning points of f"))
	var pk := GdcKit.pick(card_of(d1, win), wrongs, rng)
	var main := Plot.spec([GdcKit.curve(f, float(win[0]), float(win[1])).filter(func(c): return c[1] >= win[2] and c[1] <= win[3])],
		[[float(p), f.call(p), ""], [float(q), f.call(q), ""]], win[0], win[1], win[2], win[3])
	var ans: Dictionary = pk.answer
	return {"lines": ["The graph shows y = f(x), with turning points at x = %s and x = %s." % [Fmt.num(p), Fmt.num(q)]], "graph": main,
		"asked": "Which graph could be y = f′(x)?", "answer": ans, "graphs": pk.graphs,
		"methods": {"turning-points-to-zeros": method([
			"Each turning point of f is a zero of f′: x = %s and x = %s." % [Fmt.num(p), Fmt.num(q)],
			"f goes up before x = %s, so f′ is positive there." % Fmt.num(p),
			Answer.text(ans)], ans.values),
		"degree-drop": method([
			"f is a cubic, so f′ is a quadratic: a parabola.",
			"f rises at both ends, so the parabola opens up, with its zeros at x = %s and x = %s." % [Fmt.num(p), Fmt.num(q)],
			Answer.text(ans)], ans.values)}}


func u_match_second_derivative(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var win := card_win(s)
	var d1 := cubic_d1(s)
	var d2 := cubic_d2(s)
	var h: int = (s.p + s.q) / 2
	var p: int = s.p
	var q: int = s.q
	var wrongs: Array = [one_wrong(card_of(func(x: float) -> float: return d1.call(x) - 3.0, win), "shifted", R_SHIFTED, "it is a copy of f′, moved down"),
		one_wrong(card_of(func(x: float) -> float: return -d2.call(x), win), "flipped", "", "it says f′ falls when it rises"),
		one_wrong(card_of(func(x: float) -> float: return 6.0 * s.A * (x - p), win), "intercepts", R_INTERCEPTS, "its zero is at a zero of f′, not at its turning point")]
	var pk := GdcKit.pick(card_of(d2, win), wrongs, rng)
	var main := Plot.spec([GdcKit.curve(d1, float(win[0]), float(win[1])).filter(func(c): return c[1] >= win[2] and c[1] <= win[3])],
		[[float(h), d1.call(h), Fmt.point(h, roundi(d1.call(h)))]], win[0], win[1], win[2], win[3])
	var ans: Dictionary = pk.answer
	return {"lines": ["The graph shows y = f′(x), a parabola with its vertex marked."], "graph": main, "asked": "Which graph could be y = f″(x)?", "answer": ans, "graphs": pk.graphs,
		"methods": {"degree-drop": method([
			"f′ is a quadratic, so f″ is linear: a straight line.",
			"The line crosses the x-axis where f′ turns, at x = %s." % Fmt.num(h),
			Answer.text(ans)], ans.values),
		"sign-tables": method([
			"f′ falls before x = %s and rises after it." % Fmt.num(h),
			"So f″ is negative, then 0 at x = %s, then positive." % Fmt.num(h),
			Answer.text(ans)], ans.values),
		"gdc-nderiv": method([
			"Graph the numerical derivative of f′ on the GDC, from its equation y = %s." % Fmt.poly([3 * s.A, -6 * s.A * h, 3 * s.A * p * q]),
			"It is a line through (%s, 0)." % Fmt.num(h),
			Answer.text(ans)], ans.values)}}


func u_match_from_signs(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var win := card_win(s)
	var f := cubic_fn(s)
	var p: int = s.p
	var q: int = s.q
	var h: int = (p + q) / 2
	var wrongs: Array = [one_wrong(card_of(func(x: float) -> float: return -f.call(x), win), "flipped", "", "it has a minimum first, then a maximum"),
		one_wrong(card_of(func(x: float) -> float: return f.call(x + 2.0), win), "moved", "", "its turning points are in the wrong places"),
		one_wrong(card_of(cubic_d1(s), win), "parabola", R_SHIFTED, "it has only one turning point")]
	var pk := GdcKit.pick(card_of(f, win), wrongs, rng)
	var ans: Dictionary = pk.answer
	var lines: Array
	var table: Variant = null
	var ps := Fmt.num(p)
	var qs := Fmt.num(q)
	var hs := Fmt.num(h)
	if rep == "table":
		lines = ["The table gives the signs of f′ and f″ on each stretch."]
		table = {"rows": [["x", ["x < %s" % ps, "%s to %s" % [ps, hs], "%s to %s" % [hs, qs], "x > %s" % qs]], ["f′", ["+", "−", "−", "+"]], ["f″", ["−", "−", "+", "+"]]]}
	else:
		lines = ["f is a cubic. f′(x) = 0 at x = %s and x = %s, and f″(x) = 0 at x = %s. f is decreasing between x = %s and x = %s, and concave up for x > %s." % [ps, qs, hs, ps, qs, hs]]
	return {"lines": lines, "table": table, "asked": "Which graph could be y = f(x)?", "answer": ans, "graphs": pk.graphs,
		"methods": {"sign-tables": method([
			"f′ goes + then − at x = %s, a local maximum; − then + at x = %s, a local minimum." % [ps, qs],
			"f″ changes sign at x = %s, the point of inflexion." % hs,
			Answer.text(ans)], ans.values)}}
