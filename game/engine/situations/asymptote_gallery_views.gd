class_name AsymptoteGalleryViews
extends ExtensionViews
## The views on the `rational-asymptote-gallery` situation: one builder per unknown of
## fn-concept-asymptote-meaning (FAL-423). What an asymptote means is an explanation, so each
## answer is one of four written statements (the `choice` kind), and the type's
## true-false-reason format plays them as a student's claim to judge. The checker works the
## facts out again with SymPy (limits, where f(x) = A, where a function is undefined) and
## writes the right statement from them.

const RM := "SL2.8.rational-model#0"
const NO_HA := "SL2.8.asymptotes#2"
const SWAP := "SL2.4.asymptotes#1"
const RATIO := "SL2.8.asymptotes#1"


func needs() -> Dictionary:
	return {
		"why-vertical": {"mode": "lin"},
		"why-horizontal": {"mode": "lin"},
		"crosses-horizontal": {"mode": "cross"},
		"crosses-vertical": {"mode": "lin"},
		"gap-not-asymptote": {"mode": "gap"},
		"asymptote-in-context": {"mode": "model"},
	}


func need(unknown: String, rep: String) -> Dictionary:
	var n := super.need(unknown, rep)
	if unknown == "crosses-horizontal" and rep == "graph":
		n.graph = true
	return n


func extra() -> Dictionary:
	return {"why-vertical": ["true-false-reason"], "why-horizontal": ["true-false-reason"], "crosses-horizontal": ["true-false-reason"],
		"crosses-vertical": ["true-false-reason"], "gap-not-asymptote": ["true-false-reason"], "asymptote-in-context": ["true-false-reason"]}


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = AsymptoteGallerySituation.export(s)
	return out


static func pick(right: String, bad: Array, plain: Array) -> Dictionary:
	return InverseRuleViews.choose(right, bad, plain)


static func tag(text: String, ref: String) -> Dictionary:
	return InverseRuleViews.tag(text, ref)


static func N(v: Variant) -> String:
	return Fmt.num(v)


## "f(x) = (3x − 2)/(x − 2)" for a lin situation.
static func fx(s: Dictionary) -> String:
	return "f(x) = " + RationalFunctionSituation.frac(s.a, s.b, 1, s.d)


## f at x, as a float.
static func at(s: Dictionary, x: float) -> float:
	return s.A + s.B / (x - s.h)


static func table_near(s: Dictionary, xs: Array) -> Dictionary:
	var row: Array = []
	for x in xs:
		row.append(Fmt.dec(Q.new(roundi(at(s, x) * 10000.0), 10000)).replace("-", "−"))
	return {"rows": [["x", xs.map(func(x): return Fmt.dec(Q.new(roundi(x * 100.0), 100)).replace("-", "−"))], ["f(x)", row]]}


# ── why-vertical ─────────────────────────────────────────────

func u_why_vertical(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h := N(s.h)
	var low := "very large and negative" if s.B > 0 else "very large and positive"
	var high := "very large and positive" if s.B > 0 else "very large and negative"
	var right := "At x = %s the bottom is 0, so f is undefined there. Just left of x = %s, y is %s; just right of it, y is %s." % [h, h, low, high]
	var swapped := "At x = %s the bottom is 0, so f is undefined there. Just left of x = %s, y is %s; just right of it, y is %s." % [h, h, high, low]
	var out := {"asked": "Why does the graph have a vertical asymptote at x = %s, and what happens to y on each side?" % h}
	out.lines = [fx(s)] if rep == "equation" else ["The table shows f(x) for x close to %s." % h]
	if rep == "table":
		var near := [s.h - 0.1, s.h - 0.01, s.h + 0.01, s.h + 0.1]
		out.table = table_near(s, near)
	out.merge(pick(right, [tag("The graph levels off at the value x = %s, so it is a horizontal asymptote." % h, SWAP), tag(swapped, "")],
		["At x = %s the top is 0, so the graph crosses the x-axis there." % h, "y is close to %s on both sides, because f(%s) = %s." % [h, h, h]]))
	var fin := "So %s" % right
	out.methods = {
		"undefined-input": method(["Put x = %s into the bottom: x %s = 0, so f(%s) is undefined." % [h, Fmt.plus(-s.h).strip_edges() if s.h != 0 else "", h], "Close to x = %s the bottom is a tiny number, so y = B/(tiny) is very large (B = %s)." % [h, N(s.B)], fin], {"v": right}),
		"gdc-table": method(["Make a table on the GDC for x close to %s: the values jump from one very large number to another." % h, "The signs show %s on the left and %s on the right." % [low, high], fin], {"v": right}),
	}
	return out


# ── why-horizontal ───────────────────────────────────────────

func u_why_horizontal(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A := N(s.A)
	var right := "For large x the numbers %s and %s matter less and less next to %s and x, so f(x) is close to %s." % [N(s.b), N(s.d), Fmt.lead(s.a) + "x", A]
	var out := {"asked": "Why does y get close to %s for large x?" % A}
	out.lines = [fx(s)] if rep == "equation" else ["The table shows f(x) for large x."]
	if rep == "table":
		out.table = table_near(s, [-1000.0, -100.0, 100.0, 1000.0])
	out.merge(pick(right, [tag("It doesn't: %s has no horizontal asymptote, because the top is not a constant." % RationalFunctionSituation.frac(s.a, s.b, 1, s.d), NO_HA),
		tag("f(x) gets close to %s, the ratio of the constants %s and %s." % [N(Q.new(s.b, s.d)), N(s.b), N(s.d)], RATIO)],
		["f(x) grows without limit, because the top gets bigger as x does."]))
	var fin := "So " + right
	out.methods = {
		"large-x-limit": method(["Look at large x: x = 1000 gives %s." % Fmt.dec(Q.new(roundi(at(s, 1000.0) * 10000.0), 10000)).replace("-", "−"), "The constants are tiny next to the x terms, so f(x) ≈ %s/x = %s." % [Fmt.lead(s.a) + "x", A], fin], {"v": right}),
		"divide-out": method(["Split f: f(x) = %s." % RationalFunctionSituation.split(s.A, s.B, s.h), "The fraction %s/(x − %s) gets closer to 0 as x grows, so f(x) gets close to %s." % [N(s.B), N(s.h), A], fin], {"v": right}),
		"gdc-table": method(["On the GDC table, f(1000) = %s and f(−1000) = %s." % [Fmt.dec(Q.new(roundi(at(s, 1000.0) * 10000.0), 10000)).replace("-", "−"), Fmt.dec(Q.new(roundi(at(s, -1000.0) * 10000.0), 10000)).replace("-", "−")], "Both are close to %s, and closer for larger |x|." % A, fin], {"v": right}),
	}
	return out


# ── crosses-horizontal ───────────────────────────────────────

static func cross_text(s: Dictionary) -> String:
	match s.kind:
		"bell":
			return "x/(x² + 1)"
		"decay":
			return "x·e^(−x)"
		"shifted":
			return "%s + x/(x² + 1)" % N(s.A)
	return RationalFunctionSituation.frac(s.a, s.b, 1, s.d)


static func cross_fn(s: Dictionary) -> Callable:
	match s.kind:
		"bell":
			return func(x: float) -> float: return x / (x * x + 1.0)
		"decay":
			return func(x: float) -> float: return x * exp(-x)
		"shifted":
			return func(x: float) -> float: return s.A + x / (x * x + 1.0)
	return func(x: float) -> float: return s.A + s.B / (x - s.h)


func u_crosses_horizontal(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A := N(s.A)
	var line := "y = " + A
	var right: String
	var bad: Array = []
	var plain: Array = []
	if s.kind == "lin":
		right = "No: f(x) = %s would need %s/(x − %s) = 0, and a fraction with a top of %s is never 0." % [A, N(s.B), N(s.h), N(s.B)]
		bad = [tag("Yes: it crosses %s at x = %s." % [line, N(s.h)], "")]
		plain = ["Yes: it crosses %s where x = %s." % [line, N(Q.new(-s.b, s.a))], "No: a curve can reach its horizontal asymptote only when x is infinite."]
	else:
		right = "Yes: it crosses %s at x = 0, where x/(x² + 1) is 0." % line if s.kind != "decay" else "Yes: it crosses %s at x = 0, where x·e^(−x) is 0." % line
		bad = [tag("No: a curve can never cross its horizontal asymptote.", "")]
		plain = ["Yes: it crosses %s at x = 1." % line, "No: a curve can reach its horizontal asymptote only when x is infinite."]
	var out := {"asked": "Does the curve cross its horizontal asymptote %s? If it does, where?" % line}
	var fn_text := "f(x) = " + cross_text(s)
	out.lines = [fn_text] if rep == "equation" else ["The graph of %s is shown, with its horizontal asymptote dashed." % fn_text]
	if rep == "graph":
		var fn := cross_fn(s)
		var win := [-6, 6, -4, 4]
		var curves: Array = []
		if s.kind == "lin":
			curves = RationalCards.branches([float(s.A), float(s.B), float(s.h)], false, [-8, 8, -8, 8])
			out.graph = Plot.spec(curves, [], -8, 8, -8, 8, [[s.A, ""]], [[s.h, ""]])
		else:
			out.graph = Plot.spec([Plot.sample(fn, -6.0, 6.0)], [], win[0], win[1], win[2], win[3], [[s.A, ""]])
		out.graph.one_colour = true
	out.merge(pick(right, bad, plain))
	var fin := "So " + right
	var solve := "Solve f(x) = %s: %s." % [A, ("the fraction %s/(x − %s) = 0 has no solution" % [N(s.B), N(s.h)]) if s.kind == "lin" else "x/(x² + 1) = 0 gives x = 0" if s.kind != "decay" else "x·e^(−x) = 0 gives x = 0, since e^(−x) is never 0"]
	out.methods = {
		"large-x-limit": method(["For large x the curve gets close to %s." % line, solve, fin], {"v": right}),
		"divide-out": method(["Write f as %s plus a fraction: the fraction decides whether f(x) = %s." % [A, A], solve, fin], {"v": right}),
	}
	return out


# ── crosses-vertical ─────────────────────────────────────────

func u_crosses_vertical(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h := N(s.h)
	var right := "No: f is not defined at x = %s, so no point of the graph has x = %s." % [h, h]
	var out := {"asked": "A student says the graph can cross its vertical asymptote x = %s. Is that right?" % h}
	if rep == "graph":
		out.lines = ["The graph of f is shown, with its vertical asymptote dashed."]
		out.graph = RationalCards.plot([float(s.A), float(s.B), float(s.h)])
	else:
		out.lines = ["A student says %s can cross its vertical asymptote x = %s." % [fx(s), h]]
	out.merge(pick(right, [], ["Yes: it crosses where the graph meets the x-axis.", "Yes: a branch can cross it if the curve is steep enough.",
		"No: the graph is not continuous anywhere, so it cannot cross any line."]))
	var fin := "So " + right
	out.methods = {"undefined-input": method(["Put x = %s into f: the bottom is 0, so f(%s) is undefined." % [h, h], "No y goes with x = %s, so the graph has no point on the line x = %s." % [h, h], fin], {"v": right})}
	return out


# ── gap-not-asymptote ────────────────────────────────────────

func u_gap_not_asymptote(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h := N(s.h)
	var m := N(s.m)
	var top := Fmt.poly([s.a, s.b])
	var bottom := Fmt.poly([s.c, s.d])
	var right := "%s is %s for every x except x = %s, so the graph is the line y = %s with one point missing: a gap, not an asymptote." % [RationalFunctionSituation.frac(s.a, s.b, s.c, s.d), m, h, m]
	var out := {"asked": "Does f have an asymptote at x = %s? Say why." % h, "lines": ["f(x) = " + RationalFunctionSituation.frac(s.a, s.b, s.c, s.d)]}
	out.merge(pick(right, [], ["x = %s is a vertical asymptote, because the bottom is 0 there." % h, "x = %s is a vertical asymptote and y = %s a horizontal one." % [h, m],
		"The graph is the line y = %s with no point missing." % m]))
	var fin := "So " + right
	out.methods = {"divide-out": method(["Factorise the top: %s = %s(%s)." % [top, m, bottom], "Cancel (%s): f(x) = %s, except at x = %s where the bottom is 0." % [bottom, m, h], fin], {"v": right})}
	return out


# ── asymptote-in-context ─────────────────────────────────────

func u_asymptote_in_context(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var st: Array = s.story
	var L := N(s.L)
	var model := "P(t) = (%dt + %d)/(t + %d)" % [s.L, s.P0 * s.k, s.k]
	var right := "In the long run %s gets closer and closer to %s%s, but it never reaches it." % [st[0], L, st[1]]
	var out := {"asked": "What does the horizontal asymptote y = %s mean here, and is it ever reached?" % L,
		"lines": ["%s is modelled by %s, where t is in %s." % [st[0].substr(0, 1).to_upper() + st[0].substr(1), model, st[2]]]}
	out.merge(pick(right, [tag("%s reaches %s%s after enough %s." % [st[0].substr(0, 1).to_upper() + st[0].substr(1), L, st[1], st[2]], RM)],
		["%s starts at %s%s." % [st[0].substr(0, 1).to_upper() + st[0].substr(1), L, st[1]], "%s is %s%s at every time." % [st[0].substr(0, 1).to_upper() + st[0].substr(1), L, st[1]]]))
	var fin := "So " + right
	out.methods = {"interpret-asymptote": method(["For large t the constants matter little: P(t) ≈ %dt/t = %s." % [s.L, L], "P(t) = %s − (a positive number)/(t + %d), so it is always a little below %s." % [L, s.k, L], fin], {"v": right})}
	return out
