class_name InverseRestrictedViews
extends ExtensionViews
## The views on the `inverse-restricted` situation (FAL-1007): one builder per unknown of
## fn-ahl-inverse-restricted (AHL2.14.restrict-domain-inverse, self-inverse,
## inverse-intersection). The boundary a and the constant k are typed numbers; a multiple of
## π, an inverse, a domain, a verdict with its reason and a set of meeting points are picked
## from four written options (the `choice` kind, as inverse_rule_views.gd does). Every wrong
## option is one of the type's slips, tagged, or a declared filler. A calculator method
## (gdc-intersect) is Paper 2 with meeting points to 3 s.f.; the rest are exact on either
## paper. The checker (tools/check_answers.py, r9ir_*) reads each rule back from the lines
## and works every answer and every tagged option out again.

const T := "fn-ahl-inverse-restricted"
const R_PM := "AHL2.14.restrict-domain-inverse#0"
const R_SIGN := "AHL2.14.restrict-domain-inverse#1"
const R_DOMAIN_OF_F := "AHL2.14.restrict-domain-inverse#2"
const R_TIMES := "AHL2.14.self-inverse#0"
const R_ONE_VALUE := "AHL2.14.self-inverse#1"
const R_ODD := "AHL2.14.self-inverse#2"
const R_ON_LINE := "AHL2.14.inverse-intersection#0"
const R_RECIPROCAL := "AHL2.14.inverse-intersection#2"
## The type's own slips, by index.
const R_Y_INT := T + "#8"
const R_ROOT := T + "#9"
const R_VERTEX_Y := T + "#10"
const R_PERIOD := T + "#11"
const R_SIGN_K := T + "#12"

const S := preload("res://engine/situations/inverse_restricted.gd")

## The options of is-self-inverse that no question's numbers change.
const YES_ALL := "Yes: f(f(x)) = x for every x in its domain."
const NO_TIMES := "No: f(x) × f(x) is not 1, so f is not its own inverse."
const NO_ONE_TO_ONE := "No: f is not one-to-one, so it has no inverse."
const NO_NEVER := "No: a function is never its own inverse."
const YES_ONE_TO_ONE := "Yes: f is one-to-one, so it is its own inverse."
const YES_ODD := "Yes: f is odd, f(−x) = −f(x), so f is its own inverse."


func needs() -> Dictionary:
	return {
		"largest-domain": {"kind": "domain"},
		"largest-domain-trig": {"kind": "trig"},
		"inverse-restricted": {"kind": "half"},
		"inverse-domain": {"kind": "half", "apart": true},
		"self-inverse-constant": {"kind": "selfk"},
		"is-self-inverse": {"kind": "selfq"},
		"meet-increasing": {"kind": "meetup"},
		"meet-decreasing": {"kind": "meetdown"},
	}


## A calculator method is Paper 2; every other cell is exact and can be asked on either
## paper, so the exam's share of Paper 2 parts sets the ratio.
func papers(_unknown: String, _rep: String, method_id: String) -> Array:
	return [2] if method_id.begins_with("gdc-") else [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = S.export(s)
	return out


# ── Helpers ──────────────────────────────────────────────────

static func tag(text: String, ref: String) -> Dictionary:
	return InverseRuleViews.tag(text, ref)


## The four options of a written answer: the right one, the slips (shuffled, so each shows
## when there are more than three), then the fillers.
static func pick_of(right: String, bad: Array, plain: Array, rng: Seeded) -> Dictionary:
	return InverseRuleViews.pick_of(right, rng.shuffled(bad), plain)


static func number(label: String, v: Variant) -> Dictionary:
	return InverseRuleViews.number(label, v)


static func final(text: String) -> String:
	return "So %s." % text.rstrip(".")


static func ways(steps: Dictionary, last: String, ans: Dictionary) -> Dictionary:
	var out := {}
	for a in steps:
		out[a] = method(steps[a] + [last], ans.values)
	return out


## A value as a meeting point writes it: exact, or to 3 s.f. from a calculator.
static func say(v: Variant) -> String:
	if v is float:
		return Fmt.sf(v)
	return N(v)


static func pt(x: Variant, y: Variant) -> String:
	return "(%s, %s)" % [say(x), say(y)]


static func neg(v: Variant) -> Variant:
	return -v if v is float else Q.of(v).neg()


## Points joined as a list: "(1, 1) and (2, 2)", "(−1, 1), (0, 0) and (1, −1)".
static func pts(ps: Array) -> String:
	if ps.size() == 1:
		return ps[0]
	return ", ".join(ps.slice(0, -1)) + " and " + ps[-1]


## A curve sampled between x0 and x1, keeping the points near the window.
static func clip(fn: Callable, x0: float, x1: float, lim: float) -> Array:
	return Plot.sample(fn, x0, x1).filter(func(p): return absf(p[1]) <= lim)


static func f_quad(s: Dictionary) -> Callable:
	return func(x: float) -> float: return float(s.A) * (x - float(s.h)) * (x - float(s.h)) + float(s.k)


# ── largest domain: cut at the vertex ────────────────────────

func u_largest_domain(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var h: int = s.h
	var root: bool = s.form == "root"
	var largest: bool = s.side == "≤"
	var ans := number("a = ", h)
	var rule := S.domain_rule(s)
	var out := {"asked": "Find the %s value of a for which f has an inverse." % ("largest" if largest else "smallest"),
		"lines": ["f(x) = %s, x %s a" % [rule, s.side]], "answer": ans}
	var bad: Array = [wrong({"v": Q.new(0)}, R_Y_INT), wrong({"v": Q.of(s.top)}, R_VERTEX_Y)]
	if not s.roots.is_empty():
		bad.append(wrong({"v": s.roots[0] if largest else s.roots[1]}, R_ROOT))
	out.wrongs = rng.shuffled(bad)
	out.fillers = [{"v": Q.new(-h)}, {"v": Q.new(h + (1 if largest else -1))}, {"v": Q.new(h - (1 if largest else -1))}]
	if rep == "graph":
		out.lines.append("The graph of y = %s is shown." % rule)
		var lo := float(h) - 4.0
		var hi := float(h) + 4.0
		var fn: Callable = (func(x: float) -> float: return sqrt(x * x + float(s.b) * x + float(s.c))) if root else f_quad(s)
		var curve := Plot.sample(fn, lo, hi)
		var ys: Array = curve.map(func(p): return p[1])
		var win := GdcKit.window(lo, hi, minf(ys.min(), 0.0), maxf(ys.max(), 0.0))
		var g := Plot.spec([curve], [], win[0], win[1], win[2], win[3])
		g.one_colour = true
		out.graph = g
	var inside := Fmt.poly([s.A, s.b, s.c])
	var vx := Fmt.vertex(s.A, h, s.k)
	var keep := ("f is one-to-one on x ≤ %s, but on no x ≤ a with a > %s, as that crosses the turn" % [N(h), N(h)]) if largest else ("f is one-to-one on x ≥ %s, but on no x ≥ a with a < %s, as that crosses the turn" % [N(h), N(h)])
	var square := "Complete the square: %s = %s" % [inside, vx]
	var turn := ("The square root follows %s, which turns at its vertex x = %s" % [inside, N(h)]) if root else ("The vertex is at x = %s, where f turns" % N(h))
	var deriv: String
	if root:
		deriv = "f′(x) = (%s)/(2√(%s)), which is 0 where %s = 0" % [Fmt.poly([2, s.b]), inside, Fmt.poly([2, s.b])]
	else:
		deriv = "f′(x) = %s, which is 0 where %s = 0" % [Fmt.poly([2 * int(s.A), s.b]), Fmt.poly([2 * int(s.A), s.b])]
	var look := "On the graph" if rep == "graph" else "Sketch f"
	out.methods = ways({
		"complete-square-invert": [square, turn, keep],
		"turning-point-restriction": [deriv, "So f has its turning point at x = %s, and f′ changes sign there" % N(h), keep],
		"horizontal-line-test": ["%s: a horizontal line just %s the turning point meets it twice, once on each side of x = %s" % [look, "above" if (int(s.A) > 0 or root) else "below", N(h)],
			"Cut at x = %s and every horizontal line meets what is left at most once" % N(h), keep],
	}, final(Answer.text(ans)), ans)
	return out


# ── largest domain of a shifted cosine or sine ───────────────

func u_largest_domain_trig(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var st: Q = s.s
	var end: Q = s.end
	var right := "a = " + Fmt.pi(end)
	var out := {"asked": "Find the largest value of a for which f has an inverse.",
		"lines": ["f(x) = %s, %s ≤ x ≤ a" % [S.trig_rule(s), Fmt.pi(st)]]}
	var bad := [tag("a = " + Fmt.pi(st.add(Q.new(1, 2))), R_PERIOD), tag("a = " + Fmt.pi(st.add(2)), R_PERIOD)]
	out.merge(pick_of(right, bad, ["a = " + Fmt.pi(st.add(Q.new(3, 2)))], rng))
	var A: int = s.A
	var D: int = s.D
	var cos: bool = s.fn == "cos"
	var deriv := "f′(x) = %ssin(%s)" % [Fmt.lead(-A), S.shift(s.p)] if cos else "f′(x) = %scos(%s)" % [Fmt.lead(A), S.shift(s.p)]
	# The height at the start, and whether it is the top or the bottom of the wave.
	var start_q: Q = Q.new(A if cos or st.sub(s.p).eq(Q.new(1, 2)) else -A)
	var top: bool = start_q.sign() > 0
	var h0 := start_q.add(D)
	var h1 := start_q.neg().add(D)
	var zeros := "f′(x) = 0 at x = %s, and next at x = %s, half a period (π) on" % [Fmt.pi(st), Fmt.pi(end)]
	var one := "Between two neighbouring turning points f only %s, so it is one-to-one from x = %s to x = %s" % ["falls" if top else "rises", Fmt.pi(st), Fmt.pi(end)]
	out.methods = ways({
		"turning-point-restriction": [deriv, zeros, one],
		"horizontal-line-test": ["At x = %s, f is at its %s, f(%s) = %s" % [Fmt.pi(st), "maximum" if top else "minimum", Fmt.pi(st), N(h0)],
			"It %s to its %s, %s, at x = %s, half a period (π) later" % ["falls" if top else "rises", "minimum" if top else "maximum", N(h1), Fmt.pi(end)],
			"Past that it turns back, so a horizontal line would meet the graph twice"],
	}, final(right), out.answer)
	return out


# ── the inverse on one side of the vertex ────────────────────

## The rule and its domain, as the question gives it.
static func half_line(s: Dictionary) -> String:
	return "f(x) = %s, x %s %s" % [S.half_rule(s), s.side, N(s.h)]


## The lines that bring f to vertex form: none when it is given that way.
static func to_vertex(s: Dictionary) -> Array:
	if s.form == "vertex" or int(s.h) == 0:
		return []
	return ["Complete the square: %s = %s" % [Fmt.poly([s.A, s.b, s.c]), Fmt.vertex(s.A, s.h, s.k)]]


func u_inverse_restricted(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var A: int = s.A
	var h: int = s.h
	var k: int = s.k
	var sign := S.branch(s)
	var other := "−" if sign == "+" else "+"
	var right := "f⁻¹(x) = " + S.inv_text(A, h, k, sign)
	var out := {"asked": "Find f⁻¹(x).", "lines": [half_line(s)]}
	var bad := [tag("f⁻¹(x) = " + S.inv_text(A, h, k, "±"), R_PM), tag("f⁻¹(x) = " + S.inv_text(A, h, k, other), R_SIGN)]
	var plain: Array = []
	if h != 0:
		plain.append("f⁻¹(x) = " + S.inv_text(A, -h, k, sign))
	if k != 0:
		plain.append("f⁻¹(x) = " + S.inv_text(A, h, -k, sign))
	plain.append("f⁻¹(x) = " + S.inv_text(A, k, h, sign))
	out.merge(pick_of(right, bad, plain, rng))
	var root := S.inv_root(A, k)
	var side := "x %s %s" % [s.side, N(h)]
	var choose := "f⁻¹ gives back the inputs of f, so its values are %s: take the %s root" % [side.replace("x", "y"), "+" if sign == "+" else "−"]
	var swapped := "Swap x and y: x = %s" % Fmt.vertex(A, h, k).replace("x", "y")
	var sq_out := "(y − %d)²" % h if h > 0 else ("(y + %d)²" % -h if h < 0 else "y²")
	var isolate := "%s = %s, so y = %s" % [sq_out, _over_a(A, k), S.inv_text(A, h, k, "±")]
	# The quadratic formula in y, with the discriminant 4A(x − k) worked out.
	var cq := Fmt.poly([A, s.b, 0]).replace("x", "y") + (" − x" if int(s.c) == 0 else " + (%s − x)" % N(s.c))
	var disc := Fmt.poly([4 * A, -4 * A * k])
	var top := "%s ± √(%s)" % [N(-int(s.b)), disc] if int(s.b) != 0 else "±√(%s)" % disc
	var formula := "y = (%s)/%s" % [top, P(2 * A)]
	out.methods = ways({
		"complete-square-invert": to_vertex(s) + [swapped, isolate, choose],
		"quadratic-formula-in-y": ["Swap x and y and write it as a quadratic in y: %s = 0" % cq, "%s, which simplifies to y = %s" % [formula, S.inv_text(A, h, k, "±")], choose],
	}, final(right), out.answer)
	return out


## (x − k)/A as the square of the root holds it: "x − 5", "(x + 3)/2", "4 − x", "(4 − x)/2".
static func _over_a(A: int, k: int) -> String:
	var top: String
	if A > 0:
		top = "x" if k == 0 else "x" + Fmt.plus(-k)
	else:
		top = "−x" if k == 0 else "%s − x" % N(k)
	return top if absi(A) == 1 else "(%s)/%d" % [top, absi(A)]


func u_inverse_domain(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var A: int = s.A
	var h: int = s.h
	var k: int = s.k
	var up := A > 0
	var dir := "≥" if up else "≤"
	var flip := "≤" if up else "≥"
	var right := "x %s %s" % [dir, N(k)]
	var out := {"asked": "State the domain of f⁻¹.", "lines": [half_line(s)]}
	var bad := [tag("x %s %s" % [s.side, N(h)], R_DOMAIN_OF_F), tag("x %s %s" % [dir, N(h)], R_VERTEX_Y)]
	# The domain of f's own slip comes first, so where the two read the same it keeps its tag.
	out.merge(InverseRuleViews.pick_of(right, bad, ["x %s %s" % [flip, N(k)], "all real numbers", "x %s %s" % [dir, N(-k)]]))
	if rep == "graph":
		out.lines.append("The graph of y = f(x) on its domain is shown.")
		var lo := float(h) if s.side == "≥" else float(h) - 4.0
		var hi := float(h) + 4.0 if s.side == "≥" else float(h)
		var curve := Plot.sample(f_quad(s), lo, hi)
		var ys: Array = curve.map(func(p): return p[1])
		var win := GdcKit.window(lo, hi, minf(ys.min(), 0.0), maxf(ys.max(), 0.0))
		var g := Plot.spec([curve], [[h, k, Fmt.point(h, k)]], win[0], win[1], win[2], win[3])
		g.points[0].filled = true
		g.one_colour = true
		out.graph = g
	var range_line := "On x %s %s, f(x) takes every value from %s %s: its range is y %s %s" % [s.side, N(h), N(k), "upwards" if up else "downwards", dir, N(k)]
	var swap := "The domain of f⁻¹ is the range of f"
	var look := "On the graph" if rep == "graph" else "Sketch f on its domain"
	out.methods = ways({
		"complete-square-invert": (to_vertex(s) if not to_vertex(s).is_empty() else ["The vertex is (%s, %s)" % [N(h), N(k)]]) + [range_line, swap],
		"horizontal-line-test": ["%s: it starts at the vertex (%s, %s) and runs %s" % [look, N(h), N(k), "up" if up else "down"],
			"A horizontal line y = c meets it once when c %s %s, and not at all when c %s %s" % [dir, N(k), "<" if up else ">", N(k)], swap],
	}, "So the domain of f⁻¹ is %s." % right, out.answer)
	return out


# ── self-inverse ─────────────────────────────────────────────

func u_self_inverse_constant(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var d: int = s.d
	var slot: String = s.slot
	var k: int = a if slot == "a" else d
	var ans := number("k = ", k)
	var shown := S.rat_text("k" if slot == "a" else a, b, "k" if slot == "d" else d)
	var excl := "x ≠ −k" if slot == "d" else "x ≠ %s" % N(-d)
	var out := {"asked": "Find the value of k for which f is its own inverse.", "lines": ["f(x) = %s, %s" % [shown, excl]], "answer": ans,
		"wrongs": [wrong({"v": Q.new(-k)}, R_SIGN_K)], "fillers": [{"v": Q.new(b)}, {"v": Q.new(-b)}, {"v": Q.new(k + 1)}, {"v": Q.new(0)}]}
	var here := "Here a = %s and d = %s, so %s" % ["k" if slot == "a" else N(a), "k" if slot == "d" else N(d),
		"k%s = 0" % Fmt.plus(d) if slot == "a" else "%s + k = 0" % N(a)]
	out.methods = ways({
		"compose-with-itself": ["For f(x) = (ax + b)/(x + d), multiply the top and the bottom of f(f(x)) by x + d: f(f(x)) = ((a² + b)x + b(a + d))/((a + d)x + b + d²)",
			"This is x for every x only when a + d = 0, as it then is (a² + b)x/(a² + b)", here],
		"find-inverse-compare": ["For f(x) = (ax + b)/(x + d), swap x and y: x(y + d) = ay + b, so y(x − a) = b − dx",
			"So f⁻¹(x) = (−dx + b)/(x − a), which is f(x) exactly when −d = a", here],
		"symmetric-in-y-equals-x": ["(ax + b)/(x + d) has asymptotes x = −d and y = a, and reflecting in y = x swaps them",
			"The graph is its own reflection only if its asymptotes cross on y = x: −d = a, so a + d = 0", here],
	}, final(Answer.text(ans)), ans)
	return out


func u_is_self_inverse(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := {"asked": "Is f its own inverse? Give a reason.", "lines": [S.selfq_rule(s)]}
	var right: String
	var bad: Array = [tag(NO_TIMES, R_TIMES)]
	var plain: Array
	var lines := {}
	if s.inverse:
		right = YES_ALL
		plain = [NO_ONE_TO_ONE, NO_NEVER]
		lines = _self_true(s)
	else:
		right = "No: f(f(%s)) = %s, not %s." % [N(s.v), N(s.ffv), N(s.v)]
		bad.append(tag("Yes: f(f(%s)) = %s, so f is its own inverse." % [N(s.fixed), N(s.fixed)], R_ONE_VALUE))
		if s.form in ["odd", "cube"]:
			bad.append(tag(YES_ODD, R_ODD))
		plain = [YES_ONE_TO_ONE]
		lines = _self_false(s)
	out.merge(pick_of(right, bad, plain, rng))
	out.methods = ways(lines, "So: " + right, out.answer)
	return out


func _self_true(s: Dictionary) -> Dictionary:
	match str(s.form):
		"rat":
			var a: int = s.a
			var b: int = s.b
			var d: int = s.d
			var top := "%s(%s) + %s(%s)" % [N(a), Fmt.poly([a, b]), P(b), Fmt.poly([1, d])]
			var bottom := "(%s) + %s(%s)" % [Fmt.poly([a, b]), P(d), Fmt.poly([1, d])]
			var n := a * a + b
			return {
				"compose-with-itself": ["Multiply the top and the bottom of f(f(x)) by %s: the top is %s = %s" % [Fmt.poly([1, d]), top, Fmt.poly([n, 0])],
					"The bottom is %s = %s" % [bottom, N(n)], "So f(f(x)) = %s/%s = x" % [Fmt.poly([n, 0]), N(n)]],
				"find-inverse-compare": ["Swap x and y: x(y %s) = %s, so y(x %s) = %s" % [Fmt.plus(d).strip_edges(), Fmt.poly([a, b]).replace("x", "y"), Fmt.plus(-a).strip_edges(), Fmt.poly([-d, b])],
					"So f⁻¹(x) = %s, the same rule as f" % S.rat_text(-d, b, -a), "f⁻¹ = f, and so f(f(x)) = x"],
				"symmetric-in-y-equals-x": ["The asymptotes of f are x = %s and y = %s, crossing at %s on y = x" % [N(-d), N(a), Fmt.point(-d, a)],
					"Reflecting in y = x gives (%s)/(%s) again, so the graph is its own reflection" % [Fmt.poly([-d, b]), Fmt.poly([1, -a])], "So f⁻¹ = f, and f(f(x)) = x"],
			}
		"lin":
			var c: int = s.c
			return {
				"compose-with-itself": ["f(f(x)) = %s − (%s − x)" % [N(c), N(c)], "= x for every x"],
				"find-inverse-compare": ["Swap x and y: x = %s − y, so y = %s − x" % [N(c), N(c)], "So f⁻¹(x) = %s − x, the same rule as f, and f(f(x)) = x" % N(c)],
				"symmetric-in-y-equals-x": ["y = %s − x is a line of gradient −1, at right angles to y = x" % N(c), "Reflecting it in y = x gives the same line, so f⁻¹ = f and f(f(x)) = x"],
			}
	var r: int = s.r
	var r2 := r * r
	return {
		"compose-with-itself": ["f(f(x)) = √(%d − (%d − x²)) = √(x²)" % [r2, r2], "= x, as x ≥ 0 on the domain"],
		"find-inverse-compare": ["Swap x and y: x = √(%d − y²), so y² = %d − x² and y = √(%d − x²), as y ≥ 0" % [r2, r2, r2],
			"The domain and the range are both 0 ≤ x ≤ %d, so f⁻¹ = f and f(f(x)) = x" % r],
		"symmetric-in-y-equals-x": ["y = √(%d − x²) is the quarter of the circle x² + y² = %d with x ≥ 0 and y ≥ 0" % [r2, r2],
			"Swapping x and y leaves x² + y² = %d unchanged, so the graph is its own reflection in y = x: f(f(x)) = x" % r2],
	}


func _self_false(s: Dictionary) -> Dictionary:
	var v := N(s.v)
	var fv := N(s.fv)
	var ffv := N(s.ffv)
	var check := "f(%s) = %s and f(%s) = %s, not %s" % [v, fv, fv, ffv, v]
	match str(s.form):
		"rat":
			var a: int = s.a
			var b: int = s.b
			var d: int = s.d
			return {
				"compose-with-itself": ["f(f(x)) = x needs a + d = 0 for (ax + b)/(x + d), and here a + d = %s" % N(a + d), "Check with x = %s: %s" % [v, check]],
				"find-inverse-compare": ["Swap x and y: y(x %s) = %s, so f⁻¹(x) = %s" % [Fmt.plus(-a).strip_edges(), Fmt.poly([-d, b]), S.rat_text(-d, b, -a)],
					"That is not the rule of f. Check with x = %s: %s" % [v, check]],
				"symmetric-in-y-equals-x": ["The asymptotes of f are x = %s and y = %s, crossing at %s, which is not on y = x" % [N(-d), N(a), Fmt.point(-d, a)],
					"So the graph is not its own reflection. Check with x = %s: %s" % [v, check]],
			}
		"odd":
			var m: int = s.m
			return {
				"compose-with-itself": ["f(f(x)) = %s(%sx) = %sx, which is not x" % [N(m), N(m), N(m * m)], "Check with x = %s: %s" % [v, check]],
				"find-inverse-compare": ["Swap x and y: x = %sy, so f⁻¹(x) = x/%s" % [N(m), P(m)], "That is not %sx. Check with x = %s: %s" % [N(m), v, check]],
				"symmetric-in-y-equals-x": ["Reflecting y = %sx in y = x gives y = x/%s, another line" % [N(m), P(m)], "Check with x = %s: %s" % [v, check]],
			}
	return {
		"compose-with-itself": ["f(f(x)) = (x³)³ = x⁹, which is not x", "Check with x = %s: %s" % [v, check]],
		"find-inverse-compare": ["Swap x and y: x = y³, so f⁻¹(x) = x^(1/3)", "That is not x³. Check with x = %s: %s" % [v, check]],
		"symmetric-in-y-equals-x": ["Reflecting y = x³ in y = x gives y = x^(1/3), another curve", "Check with x = %s: %s" % [v, check]],
	}


# ── where f meets f⁻¹ ────────────────────────────────────────

## f, f⁻¹ and y = x on one grid.
static func meet_graph(f: Callable, finv: Callable, lo: float, hi: float, win: Array) -> Dictionary:
	var lim := float(maxi(absi(win[2]), absi(win[3]))) + 0.5
	var g := Plot.spec([clip(f, lo, hi, lim), clip(finv, win[0], win[1], lim), [[float(win[0]), float(win[0])], [float(win[1]), float(win[1])]]], [], win[0], win[1], win[2], win[3])
	return g


func u_meet_increasing(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var m: int = s.m
	var c: int = s.c
	var quad: bool = s.form == "quad"
	var exact: bool = s.exact
	var x1: Variant = s.xs[0]
	var x2: Variant = s.xs[1]
	var right := pts([pt(x1, x1), pt(x2, x2)])
	var out := {"asked": "Find the coordinates of the points where the graphs of y = f(x) and y = f⁻¹(x) meet.", "lines": [S.meetup_rule(s)]}
	var bad: Array = []
	# f⁻¹ taken as 1/f: f(x)² = 1, and f is never negative, so f(x) = 1.
	var one: Variant = _where_one(s)
	if one is String:
		bad.append(tag(one, R_RECIPROCAL))
	out.merge(pick_of(right, bad, [pts([pt(x1, x2), pt(x2, x1)]), pt(x1, x1) + " only", pt(x2, x2) + " only"], rng))
	if rep == "graph":
		out.lines.append("The graphs of y = f(x), y = f⁻¹(x) and y = x are shown.")
		var fq := func(x: float) -> float: return (float(n) * x * x + float(c)) / float(m)
		var fr := func(x: float) -> float: return sqrt(maxf(0.0, (float(m) * x - float(c)) / float(n))) if x >= float(c) / float(m) else NAN
		var top := ceili((x2 if x2 is float else x2.to_float()) + 2.0)
		var lim := float(top) + 0.5
		var q_curve := clip(fq, 0.0, float(top), lim)
		var r_curve := clip(fr, float(c) / float(m), float(top), lim)
		out.graph = Plot.spec([q_curve if quad else r_curve, r_curve if quad else q_curve, [[-1.0, -1.0], [float(top), float(top)]]], [], -1, top, -1, top)
	var eq := Fmt.poly([n, -m, c])
	var start := ("(%s)/%d = x" % [Fmt.poly([n, 0, c]), m]) if quad else ("%s = x, and squaring, %s = x²" % [S.meetup_rule(s).trim_prefix("f(x) = ").split(",")[0], (Fmt.poly([m, -c]) if n == 1 else "(%s)/%d" % [Fmt.poly([m, -c]), n])])
	var solve: String
	if exact:
		var fac := "(x − %s)(x − %s)" % [N(x1), N(x2)] if n == 1 else _fac2(s)
		solve = "%s = 0, so x = %s or x = %s, both in the domain" % [fac, say(x1), say(x2)]
	else:
		solve = "x = (%d ± √%d)/2, so x = %s or x = %s, both in the domain" % [m, m * m - 4 * c, say(x1), say(x2)]
	var on_line := "f is increasing, so f and f⁻¹ meet on y = x: solve f(x) = x"
	out.methods = ways({
		"solve-f-equals-x": [on_line, "%s gives %s = 0" % [start, eq], solve],
		"gdc-intersect": ["Graph y = f(x) and y = x, and use the intersect tool: x = %s and x = %s" % [say(x1), say(x2)],
			"f is increasing, so f⁻¹ crosses f only on y = x, and there y = x too"],
	}, "So the graphs meet at %s." % right, out.answer)
	return out


## The factors of 2x² − mx + c with roots r/2 and q, in the order of the roots.
static func _fac2(s: Dictionary) -> String:
	var a: Q = s.xs[0]
	var b: Q = s.xs[1]
	var half: Q = a if not a.is_int() else b
	var whole: Q = b if not a.is_int() else a
	return "(2x − %s)(x − %s)" % [N(half.mul(2)), N(whole)]


## What the 1/f slip gives: the points where f(x) = 1, or that the graphs don't meet.
## null where the point is a surd an option can't write exactly.
static func _where_one(s: Dictionary) -> Variant:
	var n: int = s.n
	var m: int = s.m
	var c: int = s.c
	if s.form == "root":
		return "(%s, 1)" % _gdc_q(Q.new(n + c, m), s.exact)
	# n x² + c = m on x ≥ 0.
	if m - c < 0:
		return "The graphs do not meet."
	var sq := Q.new(m - c, n)
	var r: Variant = S._rational_sqrt(sq)
	if r != null:
		return "(%s, 1)" % _gdc_q(r, s.exact)
	if not s.exact:
		return "(%s, 1)" % Fmt.sf(sqrt(sq.to_float()))
	return null


## An exact value as a calculator question writes it: as it is when it ends, else to 3 s.f.
static func _gdc_q(v: Q, exact: bool) -> String:
	if exact:
		return N(v)
	var t := Fmt.dec(v)
	return Fmt.sf(v) if t.contains("/") else t


func u_meet_decreasing(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var A: Q = s.A
	var pw: int = s.pw
	var sv: Variant = s.s
	var zero: Variant = Q.new(0) if s.exact else 0.0
	var right := pts([pt(neg(sv), sv), pt(zero, zero), pt(sv, neg(sv))])
	var out := {"asked": "Find the coordinates of every point where the graphs of y = f(x) and y = f⁻¹(x) meet.", "lines": [S.meetdown_rule(s)]}
	var bad := [tag(pt(zero, zero) + " only", R_ON_LINE)]
	out.merge(pick_of(right, bad, [pts([pt(neg(sv), neg(sv)), pt(zero, zero), pt(sv, sv)]), pts([pt(neg(sv), sv), pt(sv, neg(sv))]), pts([pt(zero, zero), pt(sv, neg(sv))])], rng))
	var af := A.to_float()
	var f := func(x: float) -> float: return -af * pow(x, pw)
	var finv := func(x: float) -> float: return -signf(x) * pow(absf(x) / af, 1.0 / pw)
	if rep == "graph":
		out.lines.append("The graphs of y = f(x), y = f⁻¹(x) and y = x are shown.")
		var sf: float = sv if sv is float else sv.to_float()
		var e := maxi(2, ceili(sf * 2.0))
		out.graph = meet_graph(f, finv, -float(e), float(e), [-e, e, -e, e])
	var rule := S.meetdown_rule(s).trim_prefix("f(x) = ")
	var lead := Fmt.lead(A.neg())
	var p1 := pw - 1
	var inv_a := Q.new(1).div(A)
	var even := "x%s = %s, so x = ±%s" % [Fmt.sup(p1), N(inv_a), say(sv)]
	var lead_a := Fmt.lead(A)
	var ff := "%s(%sx%s)%s" % [lead, lead, Fmt.sup(pw), Fmt.sup(pw)]
	var ffa := ("" if A.eq(1) else P(A) + Fmt.sup(pw + 1)) + "x" + Fmt.sup(pw * pw)
	var yv := "f(%s) = %s and f(%s) = %s" % [say(sv), say(neg(sv)), say(neg(sv)), say(sv)]
	out.methods = ways({
		"solve-f-equals-x": ["On y = x: %s = x gives x = 0 only, since %sx%s = −1 has no real root" % [rule, lead_a, Fmt.sup(p1)],
			"f is decreasing, so f and f⁻¹ can also meet off y = x: as f is odd, a point (u, −u) on f has (−u, u) on f too, so it is on f⁻¹",
			"Solve f(x) = −x: x = 0 or %s" % even, yv],
		"solve-directly": ["Swap x and y: x = %s, so f⁻¹(x) = %s" % [rule.replace("x", "y"), S.meetdown_inverse(s)],
			"f(x) = f⁻¹(x) means f(f(x)) = x, and f(f(x)) = %s = %s" % [ff, ffa],
			"%s = x: x = 0, or x%s = %s%s, which gives %s" % [ffa, Fmt.sup(pw * pw - 1), P(inv_a), Fmt.sup(pw + 1), even], yv],
		"gdc-intersect": ["Graph y = f(x) and y = f⁻¹(x) = %s, and use the intersect tool at every crossing" % S.meetdown_inverse(s),
			"They cross at x = %s, x = 0 and x = %s" % [say(neg(sv)), say(sv)], yv + ", and f(0) = 0"],
	}, "So the graphs meet at %s." % right, out.answer)
	return out
