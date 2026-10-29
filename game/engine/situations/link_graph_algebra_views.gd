class_name LinkGraphAlgebraViews
extends ExtensionViews
## The views on the `fn-link-graph-vs-algebra` situation: one builder per unknown of
## fn-link-graph-vs-algebra (FAL-420). An equation f(x) = g(x) seen as two graphs that
## meet: whether algebra can solve it, every meeting point to 3 s.f., counting solutions
## on an interval or for y = k, the meeting points as limits of an area, a log equation's
## rejected root, and an exponential solved exactly and checked on a GDC. Played as a
## choice of statements.
##
## which-method offers no method-pick: its failing method (apply inverse operations)
## does work when the equation is e^(kx) = c, so it can't be a wrong option there.

const T := "fn-link-graph-vs-algebra"


func needs() -> Dictionary:
	return {"which-method": {"kind": "method"}, "solve-by-intersection": {"kind": "meet"}, "count-trig-solutions": {"kind": "trig"},
		"k-for-count": {"kind": "kcount"}, "limits-first": {"kind": "area"}, "log-equation-check": {"kind": "log"},
		"exponential-two-ways": {"kind": "exp"}}


func extra() -> Dictionary:
	var both := ["true-false-reason", "method-pick"]
	var out := {}
	for u in needs():
		out[u] = both
	out["which-method"] = ["true-false-reason"]
	return out


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = LinkGraphAlgebraSituation.export(s)
	return out


static func S(x: float) -> String:
	return GdcKit.S(x)


static func W(x: float) -> String:
	return GdcKit.W(x)


static func pick(name: String, why: String) -> Dictionary:
	return LinkExtremesViews.pick(name, why)


static func ask(right: String, wrongs: Array, generic: Array, asked: String, lines: Array, methods: Dictionary, final: String,
		picks: Array) -> Dictionary:
	return LinkExtremesViews.ask(right, wrongs, generic, asked, lines, methods, final, picks)


## e^(kx) as written: "eˣ", "e^(2x)".
static func ex(k: int) -> String:
	return "eˣ" if k == 1 else "e^(%dx)" % k


## (ln c)/k as written: "ln 20", "(ln 5)/2"; log for "log".
static func ln_over(c: int, k: int, name: String = "ln") -> String:
	return "%s %d" % [name, c] if k == 1 else "(%s %d)/%d" % [name, c, k]


## "x = a, b or c".
static func xs_text(names: Array) -> String:
	return "x = " + (names[0] if names.size() == 1 else ", ".join(names.slice(0, -1)) + " or " + names[-1])


# ── Can algebra solve it? ────────────────────────────────────

func u_which_method(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right: String
	var eq: String
	var generic: Array
	var steps: Dictionary
	if s.solvable:
		var k: int = s.k
		var c: int = s.c
		eq = "%s = %d" % [ex(k), c]
		right = "Yes: x = %s ≈ %s" % [ln_over(c, k), S(s.x0)]
		generic = ["No: only a GDC can solve it", ("Yes: x = ln %d ≈ %s" % [c, S(log(float(c)))]) if k > 1 else
			("Yes: x = %d/e ≈ %s" % [c, S(c / exp(1.0))]), "No: it has no solution"]
		steps = {
			"intersect-two-graphs": ["Graph y = %s and y = %d: they meet once, at x = %s." % [ex(k), c, W(s.x0)],
				"Algebra works too: x appears once, in the exponent, so taking ln isolates it."],
			"apply-inverse": ["Take ln of both sides: %s = ln %d." % ["x" if k == 1 else "%dx" % k, c], "So x = %s = %s." % [ln_over(c, k), W(s.x0)]],
		}
	else:
		var a: int = s.a
		var f := "eˣ" if s.form == "exp" else "ln x"
		eq = "%s = %d − x" % [f, a]
		right = "No: graph both sides; x ≈ " + S(s.x0)
		if s.form == "exp":
			generic = ["Yes: x = ln(%d − x)" % a, "Yes: x = ln %d ≈ %s" % [a, S(log(float(a)))], "No: it has no solution"]
		else:
			generic = ["Yes: x = e^(%d − x)" % a, "Yes: x = %d − ln x" % a, "No: it has no solution"]
		var other := "y = %d − x" % a
		steps = {
			"intersect-two-graphs": ["Graph y = %s and %s: they meet once, at x = %s." % [f, other, W(s.x0)],
				"x is both inside %s and outside it, so no rearranging isolates it." % f],
			"apply-inverse": [("Taking ln of both sides gives x = ln(%d − x): x is still on both sides." % a) if s.form == "exp" else
				("Raising e to both sides gives x = e^(%d − x): x is still on both sides." % a),
				"So graph both sides instead: they meet at x = %s." % W(s.x0)],
		}
	return ask(right, [], generic, "Can %s be solved exactly by algebra? Choose the true statement." % eq, [eq], steps,
		"So the true statement is: %s." % right, [])


# ── Every meeting point ──────────────────────────────────────

func u_solve_by_intersection(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var line := Fmt.poly([s.b, s.a])
	var x1: float = s.xs[0]
	var x2: float = s.xs[1]
	var eq := "eˣ = " + line
	var right := xs_text([S(x1), S(x2)])
	var h := func(x: float) -> float: return exp(x) - (s.b * x + s.a)
	var sign := func(x: int) -> String: return "h(%s) = %s" % [N(x), S(h.call(x))]
	var final: String = "So " + right + "."
	var out := ask(right, [[xs_text([S(x2)]), "SL2.10.solve-gdc#0"], [xs_text([Fmt.sf(x1, 2), Fmt.sf(x2, 2)]), "SL2.10.solve-gdc#1"]],
		[xs_text([S(x1)]), "No solution"],
		"Solve %s, giving every solution to 3 s.f." % eq, [eq], {
			"intersect-two-graphs": ["Graph Y1 = eˣ and Y2 = %s and use intersect: x = %s." % [line, W(x2)],
				"Widen the window to the left: they meet again at x = %s." % W(x1)],
			"zero-of-difference": ["Graph y = eˣ − (%s) and find its zeros: x = %s and x = %s." % [line, W(x1), W(x2)]],
			"table-sign-change": ["With h(x) = eˣ − (%s): %s and %s differ in sign, and so do %s and %s." % [line,
				sign.call(floori(x1)), sign.call(ceili(x1)), sign.call(floori(x2)), sign.call(ceili(x2))],
				"Refining each sign change gives x = %s and x = %s." % [W(x1), W(x2)]],
			"gdc-intersect": ["Intersect on the GDC, in a window wide enough for both: x = %s and x = %s." % [W(x1), W(x2)]],
		}, final,
		[pick("Take ln of both sides", "x is in the exponent and outside it, so ln doesn't isolate it"),
			pick("Use the quadratic formula", "the equation isn't a quadratic"),
			pick("Intersect in the default window only", "the second meeting point is far to the left")])
	if rep == "graph":
		var lo := floori(x1) - 1
		out.lines = [ExpLogPairViews.M("The graphs of y = eˣ and y = %s are shown." % line)]
		out.graph = Plot.spec([GdcKit.curve(func(x: float) -> float: return exp(x), lo, 3.0), GdcKit.curve(func(x: float) -> float: return s.b * x + s.a, lo, 3.0)],
			[], lo, 3, -3, ceili(3.0 * s.b + s.a) + 2)
	return out


# ── Counting solutions on an interval ────────────────────────

static func trig_eq(s: Dictionary) -> String:
	return "%d %s x = %s" % [s.A, s.fn, N(s.sign * s.A / 2)]


static func sols_text(xs: Array) -> String:
	var n := xs.size()
	return "%d solution%s: %s" % [n, "" if n == 1 else "s", xs_text(xs.map(func(x): return Fmt.pi(x)))]


func u_count_trig_solutions(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var sols: Array = s.sols
	var U := Q.new(s.N, 2)
	var dom := "0 ≤ x ≤ " + Fmt.pi(U)
	var eq := trig_eq(s)
	var half := "%s x = %s" % [s.fn, N(Q.new(s.sign, 2))]
	var right := sols_text(sols)
	var other: Array = []
	for b in LinkGraphAlgebraSituation.BASE["%s%s" % [s.fn, "-" if s.sign > 0 else "+"]]:
		other.append(Q.new(b[0], b[1]))
	var first_turn: Array = sols.filter(func(x): return not Q.new(2).lt(x))
	var b0: Q = first_turn[0]
	var b1: Q = first_turn[1]
	var listed := xs_text(sols.map(func(x): return Fmt.pi(x))).trim_prefix("x = ")
	var final: String = "So there are " + right + "."
	var out := ask(right, [[sols_text(sols + [s.next]), "SL2.10.number-of-solutions#1"], [sols_text(first_turn), "SL3.8.graphical#0"]],
		[sols_text(other), sols_text(sols.slice(0, 1))],
		"How many solutions has %s for %s? Find them." % [eq, dom], [eq + ", for " + dom], {
			"horizontal-line-sweep": ["%s means %s: draw y = %s across y = %s x for %s." % [eq, half, N(Q.new(s.sign, 2)), s.fn, dom],
				"It crosses %d times, at x = %s." % [sols.size(), listed]],
			"gdc-graph": ["In radian mode, graph Y1 = %d %s x and Y2 = %s for %s." % [s.A, s.fn, N(s.sign * s.A / 2), dom],
				"Intersect finds %d crossings, at multiples of π/6: x = %s." % [sols.size(), listed]],
			"sketch-and-count": ["%s first at x = %s and, by symmetry, at x = %s." % [half, Fmt.pi(b0), Fmt.pi(b1)],
				"Adding 2π gives the rest; the next, %s, is past %s." % [Fmt.pi(s.next), Fmt.pi(U)]],
			"gdc-intersect": ["Graph both sides in radians with the window set to %s, and use intersect on each crossing." % dom,
				"There are %d: x = %s." % [sols.size(), listed]],
		}, final,
		[pick("Solve once and stop", "the graph repeats every 2π, so there are more solutions in the interval"),
			pick("Use a window from 0 to 2π", "the interval goes past 2π"),
			pick("Graph in degree mode", "the interval is in radians")])
	if rep == "graph":
		var A: int = s.A
		var f := (func(x: float) -> float: return A * cos(x)) if s.fn == "cos" else (func(x: float) -> float: return A * sin(x))
		out.lines = [ExpLogPairViews.M("The graph of y = %d %s x is shown for %s, with the line y = %s." % [A, s.fn, dom, N(s.sign * A / 2)])]
		out.graph = Plot.spec([GdcKit.curve(f, 0.0, U.to_float() * PI)], [], 0, ceili(U.to_float() * PI), -A - 1, A + 1,
			[[s.sign * A / 2.0, ""]])
	return out


# ── The values of k ──────────────────────────────────────────

func u_k_for_count(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var hi: int = s.yp
	var lo: int = s.yq
	var H := N(hi)
	var L := N(lo)
	var inside := "%s < k < %s" % [L, H]
	var closed := "%s ≤ k ≤ %s" % [L, H]
	var outside := "k < %s or k > %s" % [L, H]
	var at := "k = %s or k = %s" % [L, H]
	var right: String
	var wrongs: Array = []
	var generic: Array
	var why: String
	match int(s.count):
		3:
			right = inside
			wrongs = [[closed, "SL2.10.number-of-solutions#0"]]
			generic = [outside, at, "%s < k < %s" % [N(p), N(q)]]
			why = "Strictly between them, y = k crosses all three branches; at %s or %s it only touches a turning point." % [L, H]
		2:
			right = at
			generic = [inside, closed, "k = %s or k = %s" % [N(p), N(q)]]
			why = "Exactly at a turning value, y = k touches the curve there and crosses it once more."
		_:
			right = outside
			generic = ["k ≤ %s or k ≥ %s" % [L, H], inside, at]
			why = "Below %s or above %s, y = k misses the turning points and crosses once." % [L, H]
	var count: String = ["one solution", "two solutions", "three solutions"][int(s.count) - 1]
	var fx := "f(x) = " + Fmt.poly([1, s.b, s.c, s.d])
	var out := ask(right, wrongs, generic, "Find the values of k for which f(x) = k has exactly %s." % count,
		["The graph of %s is shown, with its turning points %s and %s." % [fx, Fmt.point(p, hi), Fmt.point(q, lo)]], {
			"horizontal-line-sweep": ["Slide the line y = k up the graph.",
				"Below %s it crosses once; at %s two; between, three; at %s two; above, once." % [L, L, H]],
			"turning-point-boundaries": ["The count only changes where y = k passes a turning value: y = %s or y = %s." % [H, L], why],
		}, "So " + right + ".",
		[pick("Solve f(x) = 0", "that counts the solutions for k = 0 only"),
			pick("Use the x-coordinates of the turning points", "k is a height, so the boundaries are the turning values"),
			pick("Graph f for one value of k", "one graph gives one count; the boundaries need the turning points")])
	var f := func(x: float) -> float: return x * x * x + s.b * x * x + s.c * x + s.d
	out.graph = Plot.spec([GdcKit.curve(f, p - 2, q + 2)], [[p, hi, Fmt.point(p, hi)], [q, lo, Fmt.point(q, lo)]],
		p - 2, q + 2, lo - 10, hi + 10)
	return out


# ── The limits of an area ────────────────────────────────────

func u_limits_first(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var u: int = s.u
	var v: int = s.v
	var area: Q = s.area
	var par := Fmt.poly([1, -(u + v), u * v])
	var line := Fmt.poly([s.m, s.n])
	var say := func(a: int, b: int, ar: Q) -> String: return "x = %s and x = %s; area %s" % [N(a), N(b), N(ar)]
	var right: String = say.call(p, q, area)
	var diff := Fmt.poly([-1, s.m + u + v, s.n - u * v])
	var integral := "∫ from %s to %s of (%s) dx" % [N(p), N(q), diff]
	var final: String = "So " + right + "."
	var out := ask(right, [[say.call(p, q, area.neg()), "SL5.11.area-between-curves#0"], [say.call(u, v, s.wrong_limits), "SL5.11.area-between-curves#1"],
		[say.call(0, q, s.one_limit), "SL2.4.intersection#1"]], [say.call(p, q, area.mul(Q.new(2)))],
		"The curve y = %s and the line y = %s enclose a region. Find where they meet, and the area of the region." % [par, line],
		["y = " + par, "y = " + line], {
			"equate-and-solve": ["%s = %s, so %s = (%s)(%s) = 0: x = %s or x = %s." % [par, line, Fmt.poly([1, -(p + q), p * q]),
				Answer.x_minus(p), Answer.x_minus(q), N(p), N(q)], "The line is on top between them: %s = %s." % [integral, N(area)]],
			"gdc-intersect": ["Intersect on the GDC: x = %s and x = %s." % [N(p), N(q)],
				"The GDC's integral of the line minus the curve between them is %s = %s." % [W(area.to_float()), N(area)]],
			"top-minus-bottom": ["At x = 0 the line gives %s and the curve %s, so the line is on top." % [N(s.n), N(u * v)],
				"Area = %s = %s." % [integral, N(area)]],
			"gdc-abs-difference": ["The meeting points, from the GDC, are x = %s and x = %s." % [N(p), N(q)],
				"∫ from %s to %s of |(%s) − (%s)| dx = %s = %s." % [N(p), N(q), line, par, W(area.to_float()), N(area)]],
		}, final,
		[pick("Use the curve's x-intercepts as the limits", "the region is bounded where the curve meets the line"),
			pick("Integrate the curve alone", "the area is between the curve and the line"),
			pick("Integrate from 0", "the region starts at the left meeting point")])
	if rep == "graph":
		var lo := mini(p, u) - 1
		var up := maxi(q, v) + 1
		out.lines = [ExpLogPairViews.M("The graphs of y = %s and y = %s are shown." % [par, line])]
		var fc := func(x: float) -> float: return (x - u) * (x - v)
		var fl := func(x: float) -> float: return s.m * x + s.n
		var ys := [fc.call(lo), fc.call(up), fl.call(lo), fl.call(up), (u - v) * (u - v) / -4.0]
		out.graph = Plot.spec([GdcKit.curve(fc, lo, up), GdcKit.curve(fl, lo, up)], [], lo, up, floori(ys.min()) - 1, ceili(ys.max()) + 1)
	return out


# ── A rejected root ──────────────────────────────────────────

func u_log_equation_check(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var r: int = s.r
	var a: int = s.a
	var b: int = s.b
	var bad := -(r + a)
	var eq := "ln x + ln(x + %d) = ln %d" % [a, b]
	var right := "x = " + N(r)
	var keep := "SL2.10.solve-analytic#0" if rng.chance(0.5) else "SL1.7.log-equations#0"
	var both := "x = %s or x = %s" % [N(r), N(bad)]
	var roots := "x = %s or x = %s" % [N(r), N(bad)]
	var lhs := "ln x + ln(x + %d)" % a
	var out := ask(right, [[both, keep]], ["x = " + N(bad), "x = " + N(Q.new(b - a, 2)), "No solution"],
		"Solve %s." % eq, [eq], {
			"intersect-two-graphs": ["Graph Y1 = %s and Y2 = ln %d: they meet once, at x = %d." % [lhs, b, r],
				"The left side exists only for x > 0, so there is no other meeting point."],
			"reduce-to-polynomial": ["ln(x(x + %d)) = ln %d, so %s − %d = 0." % [a, b, Fmt.poly([1, a, 0]), b],
				"(%s)(%s) = 0: %s." % [Answer.x_minus(r), Answer.x_minus(bad), roots],
				"ln(%s) is undefined, so x = %s is rejected." % [N(bad), N(bad)]],
			"graph-check": ["Algebra gives %s." % roots, "The graph of y = %s exists only for x > 0 and meets y = ln %d once." % [lhs, b]],
			"combine-then-exponentiate": ["ln(%s) = ln %d, so %s = %d." % [Fmt.poly([1, a, 0]), b, Fmt.poly([1, a, 0]), b],
				"%s, but ln x needs x > 0." % roots],
			"graph-intersect": ["On the GDC, y = %s and y = ln %d meet at x = %d only." % [lhs, b, r]],
		}, "So %s only." % right,
		[pick("Split ln(x + %d) into ln x + ln %d" % [a, a], "ln of a sum is not a sum of lns"),
			pick("Keep every root the quadratic gives", "a root that makes a log's argument negative is not a solution"),
			pick("Take ln of each term and add the numbers", "the logs must be combined first")])
	if rep == "graph":
		var f := func(x: float) -> float: return log(x) + log(x + a)
		var up := r + 3
		out.lines = [ExpLogPairViews.M("The graphs of y = %s and y = ln %d are shown." % [lhs, b])]
		out.graph = Plot.spec([GdcKit.curve(f, 0.02, up)], [], -2, up, -4, ceili(f.call(up)) + 1,
			[[log(float(b)), ""]], [[0.0, ""]])
	return out


# ── An exponential two ways ──────────────────────────────────

func u_exponential_two_ways(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var c: int = s.c
	var x: float = s.x0
	var eq := "%s = %d" % [ex(k), c]
	var right := "x = %s ≈ %s" % [ln_over(c, k), S(x)]
	var log10 := log(float(c)) / log(10.0) / k
	var g1 := ("x = ln(%s) ≈ %s" % [N(Q.new(c, k)), S(log(float(c) / k))]) if k > 1 else ("x = (ln %d)/2 ≈ %s" % [c, S(log(float(c)) / 2.0)])
	var final: String = "So " + right + "."
	return ask(right, [["x = %s ≈ %s" % [ln_over(c, k, "log"), S(log10)], "SL1.5.evaluate-tech#0"]],
		[g1, "x = %d/e ≈ %s" % [c, S(c / exp(1.0))], "x = −%s ≈ %s" % [ln_over(c, k), S(-x)]],
		"Solve %s exactly, and give x to 3 s.f." % eq, [eq], {
			"apply-inverse": ["Take ln of both sides: %s = ln %d." % ["x" if k == 1 else "%dx" % k, c], "So x = %s = %s." % [ln_over(c, k), W(x)]],
			"graph-check": ["Graph y = %s and y = %d: they meet once, at x = %s." % [ex(k), c, W(x)], "That agrees with %s." % ln_over(c, k)],
			"log-key": ["x = %s: use the ln key, not log (base 10)." % ln_over(c, k), "%s = %s." % [ln_over(c, k), W(x)]],
			"graph-intersect": ["Intersect y = %s with y = %d on the GDC: x = %s." % [ex(k), c, W(x)]],
		}, final,
		[pick("Use the log key", "log is base 10; undoing e needs ln"),
			pick("Divide %d by e" % c, "e is raised to a power, not multiplied"),
			pick("Take the square root of both sides", "that undoes a square, not an exponential")])
