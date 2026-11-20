class_name AhlInequalityViews
extends ExtensionViews
## The views on the `ahl-inequality` situation (FAL-1008): one builder per unknown of
## fn-ahl-inequalities (AA HL 2.15). Builders return what QuadraticViews' builders return
## (see quadratic_views.gd).
##
## Every solution set is worked out by one routine (solve): the critical values in order,
## each kept or left out as a point (a zero is kept by ≥ and ≤, an asymptote never), and each
## open gap between them tested at a point inside it. The set is written one way only
## (set_text), so every answer and slip has one canonical text: pieces in order joined by
## "or", each "a < x ≤ b", "x < b", "x ≥ a" or "x = a", and two pieces split by one left-out
## value joined as "x > a, x ≠ b". Exact ends are whole numbers or fractions; a GDC's ends
## are written to 3 s.f. The checker (tools/check_answers.py, ahlineq_*) solves every set
## again with SymPy and compares the texts exactly.
##
## The answer is a choice of sets (played as four options, or picked from them), except the
## least whole number, which is typed. Every wrong set is a slip from the type's
## misconceptions, or a declared filler (the complement, the signs of the roots changed).

const PI := "AHL2.15.polynomial-inequality#"
const RG := "AHL2.15.read-from-graphs#"
const TI := "AHL2.15.technology-inequality#"
const RI := "AHL2.15.rational-inequality#"
const CI := "AHL2.15.context-inequality#"
## The type's own slip: the ends included in a strict inequality, or left out of a non-strict one.
const ENDS := "fn-ahl-inequalities#16"

const S := preload("res://engine/situations/ahl_inequality.gd")


func needs() -> Dictionary:
	return {
		"cubic-from-factors": {"form": "cubic3"},
		"cubic-against-kx": {"form": "kx"},
		"cubic-given-factor": {"form": "factor"},
		"double-root": {"form": "double"},
		"read-from-graphs": {"form": "graphs"},
		"horizontal-band": {"form": "band"},
		"technology-inequality": {"form": "tech"},
		"rational-against-constant": {"form": "ratk"},
		"rational-against-line": {"form": "ratl"},
		"context-models": {"form": "models"},
		"least-whole-number": {"form": "whole"},
	}


func need(unknown: String, rep: String) -> Dictionary:
	var n := super.need(unknown, rep)
	if rep == "graph":
		n.graph = true
	return n


## The GDC families are Paper 2; the rest can be either (a GDC method is made Paper 2 by
## QuestionEngine). Two models are polynomial, and exact, only for the algebraic method.
func papers(unknown: String, _rep: String, angle_id: String) -> Array:
	if not has(unknown):
		return []
	if unknown in ["technology-inequality", "least-whole-number"]:
		return [2]
	if unknown == "context-models":
		return [1, 2] if angle_id == "algebraic-polynomial-model" else [2]
	return [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	var own: Dictionary = out.get("given", {}) if out.get("given") != null else {}
	out.given = S.export(s)
	out.given.merge(ExtensionViews.export(own), true)
	return out


# ── Solution sets ────────────────────────────────────────────

static func F(v: Variant) -> float:
	return S.F(v)


static func same(a: Variant, b: Variant) -> bool:
	if a == null or b == null:
		return a == null and b == null
	return absf(F(a) - F(b)) < 1e-9


## A number as a set writes it: exact, or to 3 s.f.
static func Nv(v: Variant) -> String:
	return Fmt.num(v) if v is Q or v is int else Fmt.sf(v)


## A number as the working writes it: exact, or to 6 s.f. as a GDC shows it.
static func Wv(v: Variant) -> String:
	return Fmt.num(v) if v is Q or v is int else GdcKit.W(v)


## Whether rel holds for a value d of the difference (never 0 inside a gap).
static func holds(rel: String, d: float) -> bool:
	return d > 0.0 if rel == ">" or rel == "≥" else d < 0.0


## The solution set: crit [[value, kept as a point], ...] in order, ok(x) whether a gap
## holds at x, and a domain's lower end (kept or not). Pieces {"lo", "li", "hi", "hi_in"},
## an end null where the piece runs off to infinity.
static func solve(crit: Array, ok: Callable, lo: Variant = null, lo_in: bool = false) -> Array:
	var atoms: Array = []
	var left: Variant = lo
	if lo != null:
		atoms.append({"pt": true, "a": lo, "b": lo, "in": lo_in and ok.call(F(lo))})
	for c in crit:
		if lo != null and F(c[0]) <= F(lo):
			continue
		atoms.append({"pt": false, "a": left, "b": c[0], "in": ok.call(_mid(left, c[0]))})
		atoms.append({"pt": true, "a": c[0], "b": c[0], "in": c[1]})
		left = c[0]
	atoms.append({"pt": false, "a": left, "b": null, "in": ok.call(_mid(left, null))})
	var out: Array = []
	var cur: Variant = null
	for at in atoms:
		if at.in:
			if cur == null:
				cur = {"lo": at.a, "li": at.pt, "hi": at.b, "hi_in": at.pt}
			else:
				cur.hi = at.b
				cur.hi_in = at.pt
		elif cur != null:
			out.append(cur)
			cur = null
	if cur != null:
		out.append(cur)
	return out


static func _mid(a: Variant, b: Variant) -> float:
	if a == null:
		return F(b) - 1.0
	if b == null:
		return F(a) + 1.0
	return (F(a) + F(b)) / 2.0


## Zeros as critical values: kept as points when the inequality is not strict.
static func zeros_crit(vals: Array, rel: String) -> Array:
	var out: Array = vals.map(func(v): return [v, not S.strict(rel)])
	out.sort_custom(func(p, q): return F(p[0]) < F(q[0]))
	return out


## The set written the one way it is written.
static func set_text(ps: Array, v: String = "x") -> String:
	var groups: Array = []
	for p in ps:
		if not groups.is_empty():
			var g: Dictionary = groups[-1]
			if g.hi != null and p.lo != null and not g.hi_in and not p.li and same(g.hi, p.lo):
				g.out.append(g.hi)
				g.hi = p.hi
				g.hi_in = p.hi_in
				continue
		groups.append({"lo": p.lo, "li": p.li, "hi": p.hi, "hi_in": p.hi_in, "out": []})
	var parts: Array = []
	for g in groups:
		var body := ""
		if g.lo == null and g.hi == null:
			body = ""
		elif g.lo == null:
			body = "%s %s %s" % [v, "≤" if g.hi_in else "<", Nv(g.hi)]
		elif g.hi == null:
			body = "%s %s %s" % [v, "≥" if g.li else ">", Nv(g.lo)]
		elif same(g.lo, g.hi):
			body = "%s = %s" % [v, Nv(g.lo)]
		else:
			body = "%s %s %s %s %s" % [Nv(g.lo), "≤" if g.li else "<", v, "≤" if g.hi_in else "<", Nv(g.hi)]
		var nots: Array = g.out.map(func(c): return "%s ≠ %s" % [v, Nv(c)])
		if body == "":
			parts.append(", ".join(nots) if not nots.is_empty() else "every real " + v)
		else:
			parts.append(", ".join([body] + nots))
	return " or ".join(parts) if not parts.is_empty() else "no values of " + v


## A gap or a point, written alone: "x < −1", "−1 < x < 2".
static func gap_text(a: Variant, b: Variant, v: String = "x") -> String:
	return set_text([{"lo": a, "li": false, "hi": b, "hi_in": false}], v)


## The sign of h in each gap between the critical values: "negative for x < −1, positive
## for −1 < x < 2 and negative for x > 2".
static func signs(vals: Array, h: Callable, v: String = "x", lo: Variant = null) -> String:
	var cuts: Array = vals.duplicate()
	cuts.sort_custom(func(p, q): return F(p) < F(q))
	var bits: Array = []
	var left: Variant = lo
	for c in cuts + [null]:
		var x := _mid(left, c)
		bits.append("%s for %s" % ["positive" if h.call(x) > 0.0 else "negative", gap_text(left, c, v)])
		left = c
	return ", ".join(bits.slice(0, bits.size() - 1)) + " and " + bits[-1]


static func want(rel: String) -> String:
	return {">": "positive", "≥": "positive or zero", "<": "negative", "≤": "negative or zero"}[rel]


## The ends rule in words.
static func ends_rule(rel: String, what: String = "the zeros") -> String:
	return ("The inequality is strict, so %s are left out." if S.strict(rel) else "The inequality is not strict, so %s are included.") % what


## Every end at x = c (an asymptote) included: the asymptote slip.
static func with_end_in(ps: Array, c: Variant) -> Array:
	var out: Array = []
	for p in ps:
		var q: Dictionary = p.duplicate()
		if q.lo != null and same(q.lo, c):
			q.li = true
		if q.hi != null and same(q.hi, c):
			q.hi_in = true
		out.append(q)
	return out


## The pieces with no end at x = c.
static func without_end(ps: Array, c: Variant) -> Array:
	return ps.filter(func(p): return not ((p.lo != null and same(p.lo, c)) or (p.hi != null and same(p.hi, c))))


## Whether the set holds some x (tested inside its pieces) between lo and hi that `other` does not.
static func has_outside(ps: Array, other_ok: Callable, lo: float, hi: float) -> bool:
	for p in ps:
		var a: float = maxf(lo, F(p.lo) if p.lo != null else -1e9)
		var b: float = minf(hi, F(p.hi) if p.hi != null else 1e9)
		if a >= b:
			continue
		for j in range(1, 20):
			var x := a + (b - a) * j / 20.0
			if not other_ok.call(x):
				return true
	return false


static func choice(right: String, wrongs: Array, fillers: Array) -> Dictionary:
	return RationalQuadraticViews.choice(right, wrongs, fillers)


static func cw(t: String, ref: String) -> Dictionary:
	return wrong({"v": t}, ref)


static func fin(t: String) -> String:
	return "So the solution is %s." % t


## A rel written the other way round: a < b is b > a.
static func mirror(rel: String) -> String:
	return {">": "<", "≥": "≤", "<": ">", "≤": "≥"}[rel]


static func steps_out(out: Dictionary, methods: Dictionary) -> void:
	out.methods = {}
	for k in methods:
		out.methods[k] = method(methods[k], out.answer.values)


# ── Graphs ───────────────────────────────────────────────────

## A graph spec from curves [[f, lo, hi], ...] (each sampled), its marked points [[x, y, label]].
static func plot(fns: Array, points: Array, win: Array, hlines: Array = [], vlines: Array = []) -> Dictionary:
	var curves: Array = fns.map(func(c): return GdcKit.curve(c[0], c[1], c[2]))
	return Plot.spec(curves, points, win[0], win[1], win[2], win[3], hlines, vlines)


## A cubic's graph with its zeros marked: x from two left of the first zero to two right
## of the last, y to a little past its largest value between them.
static func cubic_plot(f: Callable, zs: Array, peak: float) -> Dictionary:
	var lo: int = int(zs[0]) - 2
	var hi: int = int(zs[zs.size() - 1]) + 2
	var top := ceili(peak * 1.25) + 1
	var pts: Array = []
	for z in zs:
		if not pts.any(func(p): return p[0] == float(z)):
			pts.append([float(z), 0.0, Fmt.point(z, 0)])
	return plot([[f, float(lo), float(hi)]], pts, [lo, hi, -top, top])


# ── Cubics ───────────────────────────────────────────────────

## a(x − p)(x − q)(x − r), a factor of x first.
static func cubic_text(a: Variant, rs: Array) -> String:
	var fs: Array = rs.duplicate()
	fs.sort_custom(func(p, q): return (0 if Q.of(p).is_zero() else 1) < (0 if Q.of(q).is_zero() else 1))
	var body := ""
	for r in fs:
		body += Fmt.factor(r)
	return Fmt.lead(a) + body


static func cubic_set(a: Variant, rs: Array, rel: String) -> Array:
	return solve(zeros_crit(rs, rel), func(x: float) -> bool: return holds(rel, S.cubic_at(a, rs, x)))


static func signs_line(a: Variant, rs: Array) -> String:
	return signs(rs, func(x: float) -> float: return S.cubic_at(a, rs, x))


func u_cubic_from_factors(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var rs: Array = s.roots
	var rel: String = s.rel
	var right := set_text(cubic_set(a, rs, rel))
	var wrongs: Array = []
	if a < 0:
		wrongs.append(cw(set_text(cubic_set(-a, rs, rel)), PI + "2"))
	wrongs.append(cw(set_text(cubic_set(a, rs, S.flip_ends(rel))), ENDS))
	var neg: Array = rs.map(func(r): return -r)
	var out := choice(right, wrongs, [set_text(cubic_set(a, rs, S.opposite(rel))), set_text(cubic_set(a, neg, rel))])
	var ct := cubic_text(a, rs)
	var zs := "x = %s, x = %s and x = %s" % [N(rs[0]), N(rs[1]), N(rs[2])]
	var sg := signs_line(a, rs)
	var lead := "positive" if a > 0 else "negative"
	if rep == "graph":
		out.asked = "Solve f(x) %s 0." % rel
		out.lines = ["f(x) = " + ct, "The graph of y = f(x) is shown, with its zeros marked."]
		out.graph = cubic_plot(func(x: float) -> float: return S.cubic_at(a, rs, x), rs, S._peak(a, rs))
	else:
		out.asked = "Solve %s %s 0." % [ct, rel]
	var f := fin(right)
	steps_out(out, {
		"rearrange-factorise-sign": [
			"The critical values are the zeros of the factors: %s." % zs,
			"For large x every bracket is positive, so the cubic has the sign of its leading coefficient %s, %s; it changes sign at each zero. It is %s." % [N(a), lead, sg],
			"The inequality wants it %s. %s" % [want(rel), ends_rule(rel)], f],
		"sketch-cubic": [
			"y = %s crosses the x-axis at %s. Its leading coefficient is %s, so it %s on the right." % [ct, zs, lead, "rises" if a > 0 else "falls"],
			"From the sketch the curve is %s." % sg,
			"Read where it is %s 0. %s" % ["above" if rel in [">", "≥"] else "below", ends_rule(rel)], f],
		"gdc-check": [
			"Graph y = %s on the GDC: its zeros are %s." % [ct, zs],
			"The graph is %s." % sg,
			"The inequality wants it %s. %s" % [want(rel), ends_rule(rel)], f],
	})
	return out


func u_cubic_against_kx(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var rel: String = s.rel
	var rs := [-k, 0, k]
	var right := set_text(cubic_set(1, rs, rel))
	var sq := func(x: float) -> bool: return holds(rel, x * x - k * k)
	var wrongs: Array = [cw(set_text(solve(zeros_crit([-k, k], rel), sq)), PI + "0")]
	if rel == ">" or rel == "≥":
		wrongs.append(cw(set_text([{"lo": k, "li": rel == "≥", "hi": null, "hi_in": false}]), PI + "1"))
	wrongs.append(cw(set_text(cubic_set(1, rs, S.flip_ends(rel))), ENDS))
	var out := choice(right, wrongs, [set_text(cubic_set(1, rs, S.opposite(rel))), set_text(cubic_set(1, [-k, k], rel))])
	var kk := k * k
	out.asked = "Solve %s." % ("%dx %s x³" % [kk, mirror(rel)] if s.swap else "x³ %s %dx" % [rel, kk])
	var f := fin(right)
	var fac := "x(x − %d)(x + %d)" % [k, k]
	var moved := "x³ − %dx %s 0" % [kk, rel]
	var sg := signs_line(1, rs)
	steps_out(out, {
		"rearrange-factorise-sign": [
			"Move everything to one side, without dividing by x (which could be negative): %s." % moved,
			"Factorise: %s %s 0, with critical values x = −%d, x = 0 and x = %d." % [fac, rel, k, k],
			"The cubic is %s. It must be %s. %s" % [sg, want(rel), ends_rule(rel)], f],
		"sketch-cubic": [
			"Sketch y = x³ − %dx = %s: a positive cubic crossing the x-axis at x = −%d, 0 and %d." % [kk, fac, k, k],
			"It is below the axis for x < −%d, above it for −%d < x < 0, below it for 0 < x < %d and above it for x > %d." % [k, k, k, k],
			"Read where %s. %s" % ["the curve is above the axis" if rel in [">", "≥"] else "the curve is below the axis", ends_rule(rel)], f],
	})
	return out


func u_cubic_given_factor(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var rs: Array = s.roots
	var p: int = s.p
	var rel: String = s.rel
	var c: Array = s.coeffs
	var right := set_text(cubic_set(a, rs, rel))
	var wrongs: Array = []
	if a < 0:
		wrongs.append(cw(set_text(cubic_set(-a, rs, rel)), PI + "2"))
	wrongs.append(cw(set_text(cubic_set(a, rs, S.flip_ends(rel))), ENDS))
	var others: Array = rs.filter(func(r): return r != p)
	var fillers: Array = [set_text(cubic_set(a, rs, S.opposite(rel)))]
	var swapped: Array = [-p] + others
	if not (-p in others):
		fillers.append(set_text(cubic_set(a, swapped, rel)))
	fillers.append(set_text(cubic_set(a, rs.map(func(r): return -r), rel)))
	var out := choice(right, wrongs, fillers)
	var ft := Fmt.poly(c)
	out.asked = "Given that %s is a factor of f(x), solve f(x) %s 0." % [Fmt.factor(p), rel]
	out.lines = ["f(x) = " + ft]
	var quad := Fmt.poly([a, -a * (others[0] + others[1]), a * others[0] * others[1]])
	var f := fin(right)
	var zs := "x = %s, x = %s and x = %s" % [N(rs[0]), N(rs[1]), N(rs[2])]
	var sg := signs_line(a, rs)
	steps_out(out, {
		"rearrange-factorise-sign": [
			"Divide f(x) by %s: f(x) = %s(%s)." % [Fmt.factor(p), Fmt.factor(p), quad],
			"Factorise the quadratic: f(x) = %s, so the critical values are %s." % [cubic_text(a, rs), zs],
			"f(x) is %s. It must be %s. %s" % [sg, want(rel), ends_rule(rel)], f],
		"gdc-check": [
			"Graph y = %s on the GDC: its zeros are %s." % [ft, zs],
			"The graph is %s." % sg,
			"The inequality wants it %s. %s" % [want(rel), ends_rule(rel)], f],
	})
	return out


static func double_text(s: Dictionary) -> String:
	var fp := Fmt.factor(s.p)
	var fq := Fmt.factor(s.q) + "²"
	if s.q == 0:
		fq = "x²"
	var q_first: bool = s.first == "q"
	if s.p == 0:
		q_first = false
	elif s.q == 0:
		q_first = true
	return fq + fp if q_first else fp + fq


func u_double_root(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var rel: String = s.rel
	var h := func(x: float) -> float: return (x - p) * (x - q) * (x - q)
	var setof := func(r: String, g: Callable) -> Array:
		return solve(zeros_crit([p, q], r), func(x: float) -> bool: return holds(r, g.call(x)))
	var right := set_text(setof.call(rel, h))
	var sgn := 1.0 if p > q else -1.0
	var as_change := func(x: float) -> float: return (x - p) * (x - q) * sgn
	var wrongs: Array = [cw(set_text(setof.call(rel, as_change)), PI + "3"), cw(set_text(setof.call(S.flip_ends(rel), h)), ENDS)]
	var neg := func(x: float) -> float: return (x + p) * (x + q) * (x + q)
	var negset: Array = solve(zeros_crit([-p, -q], rel), func(x: float) -> bool: return holds(rel, neg.call(x)))
	var out := choice(right, wrongs, [set_text(setof.call(S.opposite(rel), h)), set_text(negset)])
	var dt := double_text(s)
	if rep == "graph":
		out.asked = "Solve f(x) %s 0." % rel
		out.lines = ["f(x) = " + dt, "The graph of y = f(x) is shown, with the points where it meets the x-axis marked."]
		out.graph = cubic_plot(h, [mini(p, q), maxi(p, q)], S._peak(1, [p, q, q]))
	else:
		out.asked = "Solve %s %s 0." % [dt, rel]
	var f := fin(right)
	var at_q := "At x = %s the expression is 0, so x = %s is %s." % [N(q), N(q), "left out" if S.strict(rel) else "included"]
	steps_out(out, {
		"rearrange-factorise-sign": [
			"%s ≥ 0 for every x, and is 0 only at x = %s, so the sign does not change there: the expression has the sign of %s." % [Fmt.factor(q) + "²" if q != 0 else "x²", N(q), Fmt.factor(p) if p != 0 else "x"],
			"It is %s." % signs([p], h),
			"It must be %s. %s" % [want(rel), at_q], f],
		"sketch-cubic": [
			"y = %s crosses the x-axis at x = %s and touches it at x = %s, the repeated root, turning back without crossing." % [dt, N(p), N(q)],
			"For large x it is positive, so the curve is %s." % signs([p], h),
			"Read where it is %s 0. %s" % ["above" if rel in [">", "≥"] else "below", at_q], f],
	})
	return out


# ── Two graphs ───────────────────────────────────────────────

func u_read_from_graphs(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rel: String = s.rel
	var xs: Array = s.xs
	var gf := func(x: float) -> float: return S.graph_g(s, x) - S.graph_f(s, x)
	var setof := func(r: String) -> Array:
		return solve(zeros_crit(xs, r), func(x: float) -> bool: return holds(r, gf.call(x)))
	var ps: Array = setof.call(rel)
	var right := set_text(ps)
	var wrongs: Array = []
	if rel == ">" or rel == "≥":
		wrongs.append(cw(set_text(solve(zeros_crit([s.z], rel), func(x: float) -> bool: return holds(rel, S.graph_g(s, x)))), RG + "0"))
	wrongs.append(cw(set_text(heights(ps, func(x): return Q.new(int(round(S.graph_g(s, F(x))))))), "y"), RG + "1"))
	wrongs.append(cw(set_text(setof.call(S.opposite(rel))), RG + "2"))
	wrongs.append(cw(set_text(setof.call(S.flip_ends(rel))), ENDS))
	var out := choice(right, wrongs, [set_text(solve(zeros_crit(xs, rel), func(x: float) -> bool: return holds(rel, -gf.call(x))))])
	out.asked = "Use the graph to solve g(x) %s f(x)." % rel
	out.lines = ["The graphs of y = f(x), the curve, and y = g(x), the straight line, are shown. They cross at the marked points."]
	out.graph = graphs_plot(s)
	var cx := " and ".join(xs.map(func(x): return "x = " + N(x)))
	var f := fin(right)
	var above := "on or above" if rel == "≥" else ("above" if rel == ">" else ("on or below" if rel == "≤" else "below"))
	steps_out(out, {
		"above-between-intersections": [
			"The graphs cross at %s." % cx,
			"Between and beyond the crossings, the line is %s." % signs(xs, gf).replace("positive", "above the curve").replace("negative", "below the curve"),
			"The inequality wants the line %s the curve. %s" % [above, ends_rule(rel, "the crossings")], f],
		"difference-graph": [
			"g(x) %s f(x) is the same as g(x) − f(x) %s 0, and g − f is 0 at the crossings, %s." % [rel, rel, cx],
			"g(x) − f(x) is %s." % signs(xs, gf),
			"It must be %s. %s" % [want(rel), ends_rule(rel, "the crossings")], f],
	})
	return out


## The ends of a set read off the other axis: each end's height, in order of size.
static func heights(ps: Array, y: Callable) -> Array:
	var ends: Array = []
	for p in ps:
		for key in ["lo", "hi"]:
			if p[key] != null:
				ends.append(y.call(p[key]))
	ends.sort_custom(func(a, b): return F(a) < F(b))
	var out: Array = []
	var i := 0
	for p in ps:
		var q: Dictionary = p.duplicate()
		for key in ["lo", "hi"]:
			if q[key] != null:
				q[key] = ends[i]
				i += 1
		out.append(q)
	return out


static func graphs_plot(s: Dictionary) -> Dictionary:
	var xs: Array = s.xs
	var lo := mini(xs[0], s.z) - 2
	var hi := maxi(xs[xs.size() - 1], s.z) + 2
	var top := 1.0
	var bot := -1.0
	for j in 101:
		var x: float = xs[0] - 0.6 + (xs[xs.size() - 1] - xs[0] + 1.2) * j / 100.0
		for y in [S.graph_f(s, x), S.graph_g(s, x)]:
			top = maxf(top, y)
			bot = minf(bot, y)
	var pts: Array = xs.map(func(x): return [float(x), S.graph_g(s, float(x)), Fmt.point(x, int(round(S.graph_g(s, float(x)))))])
	var f := func(x: float) -> float: return S.graph_f(s, x)
	var g := func(x: float) -> float: return S.graph_g(s, x)
	return plot([[f, float(lo), float(hi)], [g, float(lo), float(hi)]], pts, [lo, hi, floori(bot) - 2, ceili(top) + 2])


func u_horizontal_band(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rel: String = s.rel
	var ds: Array = s.ds
	var a: int = s.a
	var h: int = s.h
	var k: int = s.k
	var f := func(x: float) -> float: return S.band_f(s, x)
	var cs: Array = ds.map(func(d): return k + a * d * d)
	var xs: Array = []
	for d in ds:
		xs += [h - d, h + d]
	xs.sort()
	var lo_c: int = mini(cs[0], cs[cs.size() - 1])
	var hi_c: int = maxi(cs[0], cs[cs.size() - 1])
	var ok: Callable
	var setof: Callable
	var asked: String
	var heights_text: String
	var fillers: Array = []
	if ds.size() == 1:
		var c: int = cs[0]
		setof = func(r: String) -> Array:
			return solve(zeros_crit(xs, r), func(x: float) -> bool: return holds(r, f.call(x) - c))
		asked = "Find the values of x for which f(x) %s %s." % [rel, N(c)]
		heights_text = "y %s %s" % [rel, N(c)]
		var inside := set_text([{"lo": xs[0], "li": not S.strict(rel), "hi": xs[1], "hi_in": not S.strict(rel)}])
		var outside := set_text([{"lo": null, "li": false, "hi": xs[0], "hi_in": not S.strict(rel)}, {"lo": xs[1], "li": not S.strict(rel), "hi": null, "hi_in": false}])
		fillers = [inside, outside]
	else:
		var st := S.strict(rel)
		setof = func(r: String) -> Array:
			var sr := S.strict(r)
			var crit: Array = xs.map(func(x): return [x, not sr])
			return solve(crit, func(x: float) -> bool: return f.call(x) > lo_c and f.call(x) < hi_c)
		asked = "Find the values of x for which %s %s f(x) %s %s." % [N(lo_c), rel, rel, N(hi_c)]
		heights_text = "%s %s y %s %s" % [N(lo_c), rel, rel, N(hi_c)]
		var outer := [h - ds[1], h + ds[1]]
		fillers = [set_text([{"lo": outer[0], "li": not st, "hi": outer[1], "hi_in": not st}])]
	var right := set_text(setof.call(rel))
	var comp: Array
	if ds.size() == 1:
		comp = setof.call(S.opposite(rel))
	else:
		var sr := not S.strict(rel)
		comp = solve(xs.map(func(x): return [x, not sr]), func(x: float) -> bool: return f.call(x) < lo_c or f.call(x) > hi_c)
	var wrongs: Array = [cw(heights_text, RG + "1"), cw(set_text(comp), RG + "2"), cw(set_text(setof.call(S.flip_ends(rel))), ENDS)]
	var out := choice(right, wrongs, fillers)
	out.asked = asked
	var lines_word := "the line y = %s" % N(cs[0]) if ds.size() == 1 else "the lines y = %s and y = %s" % [N(lo_c), N(hi_c)]
	out.lines = ["The graph of y = f(x) is shown with %s. The points where they meet are marked." % lines_word]
	var pts: Array = []
	for d in ds:
		var c: int = k + a * d * d
		for x in [h - d, h + d]:
			pts.append([float(x), float(c), Fmt.point(x, c)])
	var span: int = ds[ds.size() - 1]
	var win := [h - span - 2, h + span + 2, mini(mini(lo_c, k), 0) - 2, maxi(maxi(hi_c, k), 0) + 2]
	out.graph = plot([[f, float(win[0]), float(win[1])]], pts, win, cs.map(func(c): return [float(c), "y = " + N(c)]))
	var cx := ", ".join(xs.map(func(x): return "x = " + N(x)))
	var where := "the curve lies above the line" if rel in [">", "≥"] else "the curve lies below the line"
	if ds.size() == 2:
		where = "the curve lies between the lines"
	steps_out(out, {"above-between-intersections": [
		"The curve meets %s at %s." % [lines_word, cx],
		"Read the x-values where %s. %s" % [where, ends_rule(rel, "the meeting points")],
		fin(right)]})
	return out


# ── On the GDC ───────────────────────────────────────────────

static func tech_text(s: Dictionary) -> String:
	if s.fam == "exp":
		var sx: Q = s.sx
		var pw := "e^x" if sx.eq(1) else ("e^(−x)" if sx.eq(-1) else "e^(%sx)" % Fmt.dec(sx))
		return ("" if s.A == 1 else str(s.A)) + pw
	var inner := "x" if s.d == 0 else "x + %d" % s.d
	var ln := "ln x" if s.d == 0 else "ln(%s)" % inner
	return ln if s.A == 1 else "%d %s" % [s.A, ln]


static func line_text(m: Variant, n: Variant) -> String:
	return GdcKit.first(m, "x") + GdcKit.join(n, "")


func u_technology_inequality(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rel: String = s.rel
	var xs: Array = s.xs
	var ln: bool = s.fam == "ln"
	var dom: Variant = Q.new(-s.d) if ln else null
	var h := func(x: float) -> float: return S.tech_h(s, x)
	var setof := func(r: String, d: Variant) -> Array:
		return solve(zeros_crit(xs, r), func(x: float) -> bool: return holds(r, h.call(x)), d, false)
	var ps: Array = setof.call(rel, dom)
	var right := set_text(ps)
	var inside := holds(rel, h.call((xs[0] + xs[1]) / 2.0))
	var ni := not S.strict(rel)
	var wrongs: Array = []
	if not inside:
		wrongs.append(cw(set_text([{"lo": xs[0], "li": ni, "hi": xs[1], "hi_in": ni}]), TI + "0"))
		wrongs.append(cw(set_text([ps[ps.size() - 1]]), TI + "1"))
		if ln:
			wrongs.append(cw(set_text(setof.call(rel, null)), TI + "2"))
	var out := choice(right, wrongs, [set_text(setof.call(S.flip_ends(rel), dom)), set_text(setof.call(S.opposite(rel), dom))])
	var ft := tech_text(s)
	var lt := line_text(s.m, s.n)
	out.asked = "Solve %s %s %s." % [ft, rel, lt]
	if rep == "graph":
		out.lines = ["The graphs of y = %s and y = %s are shown." % [ft, lt]]
		out.graph = tech_plot(s)
	var cx := "x = %s and x = %s" % [GdcKit.W(xs[0]), GdcKit.W(xs[1])]
	var f := fin(right)
	var side := ("above" if rel in [">", "≥"] else "below")
	var dom_line := "%s is defined only for x > %s, so the solution starts there, with x = %s left out." % [ft, N(-s.d), N(-s.d)] if ln \
		else "%s is defined for every x and has no vertical asymptote, so nothing is cut from the set." % ft
	var ends := ends_rule(rel, "the crossings")
	var dsg := signs(xs, h, "x", dom)
	steps_out(out, {
		"gdc-intersections": [
			"Graph y = %s and y = %s on the GDC. The intersect tool gives %s." % [ft, lt, cx],
			"The curve is %s the line %s. %s" % [side, "between the crossings" if inside else "outside the crossings", ends],
			(dom_line + " " if ln else "") + f],
		"gdc-zero-of-difference": [
			"Graph y = %s − (%s) on the GDC. Its zeros are %s." % [ft, lt, cx],
			"The difference is %s." % dsg,
			"It must be %s. %s" % [want(rel), ends], f],
		"domain-check": [
			dom_line,
			"On the GDC the graphs of y = %s and y = %s cross at %s, and the curve is %s the line %s." % [ft, lt, cx, side, "between them" if inside else "outside them"],
			ends, f],
	})
	return out


static func tech_plot(s: Dictionary) -> Dictionary:
	var xs: Array = s.xs
	var lo := floori(xs[0]) - 2
	var hi := ceili(xs[1]) + 2
	var cl := lo
	if s.fam == "ln":
		lo = maxi(lo, -s.d - 1)
		cl = lo
	var f := func(x: float) -> float: return S.tech_f(s, x)
	var g := func(x: float) -> float: return S.tech_line(s, x)
	var c0 := float(cl) if s.fam == "exp" else -float(s.d) + 0.002
	var top := 1.0
	var bot := -1.0
	for x in xs:
		top = maxf(top, S.tech_f(s, x))
		bot = minf(bot, S.tech_f(s, x))
	var win := [lo, hi, floori(bot) - 3, ceili(top) + 3]
	var pts: Array = xs.map(func(x): return [x, S.tech_f(s, x), ""])
	return plot([[f, c0, float(hi)], [g, float(lo), float(hi)]], pts, win, [], [[float(-s.d), ""]] if s.fam == "ln" else [])


# ── Rational functions ───────────────────────────────────────

static func rat_text(a: int, b: int, c: int) -> String:
	var den := Fmt.poly([1, -c])
	return "(%s)/%s" % [Fmt.poly([a, b]), den if den == "x" else "(%s)" % den]


func u_rational_against_constant(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var k: int = s.k
	var x0: Q = s.x0
	var rel: String = s.rel
	var h := func(x: float) -> float: return S.ratk_y(s, x) - k
	var crit_of := func(r: String) -> Array:
		var cr: Array = [[Q.new(c), false], [x0, not S.strict(r)]]
		cr.sort_custom(func(p, q): return F(p[0]) < F(q[0]))
		return cr
	var setof := func(r: String) -> Array:
		return solve(crit_of.call(r), func(x: float) -> bool: return holds(r, h.call(x)))
	var ps: Array = setof.call(rel)
	var right := set_text(ps)
	var wrongs: Array = []
	# Multiplied through by x − c as if it were positive: (a − k)x + b + kc rel 0.
	var lin := func(x: float) -> bool: return holds(rel, (a - k) * x + b + k * c)
	var through: Array = solve([[x0, not S.strict(rel)]], lin)
	if through.any(func(p): return (p.lo == null or F(p.lo) < c) and (p.hi == null or F(p.hi) > c)):
		wrongs.append(cw(set_text(through), RI + "0"))
	wrongs.append(cw(set_text(with_end_in(ps, Q.new(c))), RI + "1"))
	var kept := without_end(ps, Q.new(c))
	if not kept.is_empty():
		wrongs.append(cw(set_text(kept), RI + "2"))
	wrongs.append(cw(set_text(setof.call(S.flip_ends(rel))), ENDS))
	var out := choice(right, wrongs, [set_text(setof.call(S.opposite(rel)))])
	var ft := rat_text(a, b, c)
	var den := Fmt.poly([1, -c])
	if rep == "graph":
		out.asked = "Solve f(x) %s %s." % [rel, N(k)]
		out.lines = ["f(x) = %s, for x ≠ %s" % [ft, N(c)], "The graph of y = f(x) is shown with its asymptotes dashed, and the line y = %s." % N(k)]
		out.graph = rat_plot(func(x: float) -> float: return S.ratk_y(s, x), c, a, func(x: float) -> float: return float(k),
			[[x0.to_float(), float(k), Fmt.point(x0, k)]])
	else:
		out.asked = "Solve %s %s %s." % [ft, rel, N(k)]
	var top := Fmt.poly([a - k, b + k * c])
	var f := fin(right)
	var dsg := signs([c, x0], h)
	var at_c := "x = %s is a vertical asymptote, where f has no value, so it is never included." % N(c)
	var bracket := den if den == "x" else "(%s)" % den
	steps_out(out, {
		"gdc-graph-asymptote": [
			"Graph y = %s and y = %s on the GDC: they meet at x = %s, and the vertical asymptote is x = %s." % [ft, N(k), Wv(x0), N(c)],
			"The curve minus the line is %s." % dsg,
			"It must be %s. %s %s" % [want(rel), ends_rule(rel, "the crossing"), at_c], f],
		"single-fraction-sign": [
			"Subtract %s and write one fraction: %s − %s = (%s)/%s %s 0." % [N(k), ft, N(k), top, bracket, rel],
			"The critical values are x = %s, where the top is 0, and x = %s, where the bottom is 0." % [Nv(x0), N(c)],
			"The fraction is %s. It must be %s. %s" % [dsg, want(rel), ends_rule(rel, "the zero")],
			at_c + " " + f],
		"multiply-by-square": [
			"Multiply both sides by %s², which is positive for x ≠ %s: (%s)%s %s %s%s²." % [bracket, N(c), Fmt.poly([a, b]), bracket, rel, Fmt.lead(k) if k != -1 else "−", bracket] if k != 1 and k != 0 else
				"Multiply both sides by %s², which is positive for x ≠ %s: (%s)%s %s %s." % [bracket, N(c), Fmt.poly([a, b]), bracket, rel, bracket + "²" if k == 1 else "0"],
			"Take everything to one side and factor out %s: %s(%s) %s 0, with zeros x = %s and x = %s." % [bracket, bracket, top, rel, N(c), Nv(x0)],
			"This quadratic in x is %s. It must be %s. %s" % [signs([c, x0], func(x: float) -> float: return (x - c) * ((a - k) * x + b + k * c)), want(rel), ends_rule(rel, "the zero")],
			at_c + " " + f],
	})
	return out


## A rational function's graph on −8 to 8: its branches (one colour), its asymptotes
## dashed, the line it is compared with in sand, and the marked crossings.
static func rat_plot(fy: Callable, c: int, ha: Variant, line: Callable, pts: Array) -> Dictionary:
	var curves := RationalQuadraticViews.trace(fy, [float(c)])
	var w: Array = RationalQuadraticViews.WIN
	var g := Plot.spec(curves, pts, w[0], w[1], w[2], w[3], [[F(ha), ""]] if ha != null else [], [[float(c), ""]])
	g.one_colour = true
	g.sand_from = curves.size()
	g.curves = curves + [GdcKit.curve(line, float(w[0]), float(w[1]))]
	return g


func u_rational_against_line(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var m: int = s.m
	var n: int = s.n
	var rel: String = s.rel
	var xs: Array = s.xs
	var h := func(x: float) -> float: return S.ratl_y(s, x) - S.ratl_line(s, x)
	var nc: Array = S.ratl_num(s)
	var num := func(x: float) -> float: return nc[0] * x * x + nc[1] * x + nc[2]
	var crit_of := func(r: String) -> Array:
		var cr: Array = [[Q.new(c), false]] + xs.map(func(x): return [x, not S.strict(r)])
		cr.sort_custom(func(p, q): return F(p[0]) < F(q[0]))
		return cr
	var setof := func(r: String) -> Array:
		return solve(crit_of.call(r), func(x: float) -> bool: return holds(r, h.call(x)))
	var ps: Array = setof.call(rel)
	var right := set_text(ps)
	var true_ok := func(x: float) -> bool: return holds(rel, h.call(x))
	var wrongs: Array = []
	var quad: Array = solve(zeros_crit(xs, rel), func(x: float) -> bool: return holds(rel, num.call(x)))
	if has_outside(quad, true_ok, -1e6, float(c)):
		wrongs.append(cw(set_text(quad), RI + "0"))
	wrongs.append(cw(set_text(with_end_in(ps, Q.new(c))), RI + "1"))
	var kept := without_end(ps, Q.new(c))
	if not kept.is_empty():
		wrongs.append(cw(set_text(kept), RI + "2"))
	var out := choice(right, wrongs, [set_text(setof.call(S.opposite(rel))), set_text(setof.call(S.flip_ends(rel)))])
	var ft := rat_text(a, b, c)
	var lt := Fmt.poly([m, n])
	var den := Fmt.poly([1, -c])
	var bracket := den if den == "x" else "(%s)" % den
	if rep == "graph":
		out.asked = "Solve f(x) %s %s." % [rel, lt]
		out.lines = ["f(x) = %s, for x ≠ %s" % [ft, N(c)], "The graph of y = f(x) is shown with its asymptotes dashed, and the line y = %s." % lt]
		var pts: Array = xs.map(func(x): return [F(x), S.ratl_line(s, F(x)), Fmt.point(x, Q.new(m).mul(x).add(n)) if x is Q else ""])
		out.graph = rat_plot(func(x: float) -> float: return S.ratl_y(s, x), c, a, func(x: float) -> float: return S.ratl_line(s, x), pts)
	else:
		out.asked = "Solve %s %s %s." % [ft, rel, lt]
	var f := fin(right)
	var cx := "x = %s and x = %s" % [Wv(xs[0]), Wv(xs[1])]
	var dsg := signs([c] + xs, h)
	var at_c := "x = %s is a vertical asymptote, where f has no value, so it is never included." % N(c)
	var ntext := Fmt.poly(nc)
	var roots_line: String
	if s.exact:
		roots_line = "The top is %s = %s, zero at %s; the bottom is zero at x = %s." % [ntext, cubic_text(-m, xs), cx, N(c)]
	else:
		var A: int = nc[0]
		var B: int = nc[1]
		var C: int = nc[2]
		roots_line = "The top %s is zero where x = (%s ± √%s)/%s, that is %s; the bottom is zero at x = %s." % [ntext, N(-B), N(B * B - 4 * A * C), N(2 * A), cx, N(c)]
	steps_out(out, {
		"gdc-intersections": [
			"Graph y = %s and y = %s on the GDC. The intersect tool gives %s, and the curve has the vertical asymptote x = %s." % [ft, lt, cx, N(c)],
			"Reading either side of the asymptote, the curve minus the line is %s." % dsg,
			"It must be %s. %s %s" % [want(rel), ends_rule(rel, "the crossings"), at_c], f],
		"gdc-zero-of-difference": [
			"Graph y = %s − (%s) on the GDC. Its zeros are %s, and it has a vertical asymptote at x = %s." % [ft, lt, cx, N(c)],
			"The difference is %s." % dsg,
			"It must be %s. %s %s" % [want(rel), ends_rule(rel, "the zeros"), at_c], f],
		"domain-check": [
			"f is undefined at x = %s, its vertical asymptote: x = %s is left out, and the sign can change there." % [N(c), N(c)],
			"The graphs cross at %s, so the critical values are those and x = %s." % [cx, N(c)],
			"Testing a value in each interval, the curve minus the line is %s. It must be %s. %s" % [dsg, want(rel), ends_rule(rel, "the crossings")], f],
		"gdc-graph-asymptote": [
			"Graph y = %s and y = %s on the GDC: they cross at %s, and the asymptote x = %s is a boundary too." % [ft, lt, cx, N(c)],
			"Between the boundaries the curve minus the line is %s." % dsg,
			"It must be %s. %s %s" % [want(rel), ends_rule(rel, "the crossings"), at_c], f],
		"single-fraction-sign": [
			"Subtract the line and write one fraction: %s − (%s) = (%s)/%s %s 0." % [ft, lt, ntext, bracket, rel],
			roots_line,
			"The fraction is %s. It must be %s. %s" % [dsg, want(rel), ends_rule(rel, "the zeros")],
			at_c + " " + f],
	})
	return out


# ── In context ───────────────────────────────────────────────

const CONTEXTS := [
	["The populations, in thousands, of two towns t years after the start of a study are modelled by", "towns", "the population of town %s is greater than the population of town %s"],
	["Two species of fish are put into a lake. Their numbers, in hundreds, t months later are modelled by", "species", "there are more of species %s than of species %s"],
	["The monthly sales, in thousands, of two products t months after their launch are modelled by", "products", "product %s sells more than product %s"],
]


static func model_a_text(s: Dictionary) -> String:
	if s.fam == "poly":
		return Fmt.poly([s.q, s.p], "t")
	return "%d × %s^t" % [s.P, Fmt.dec(s.g)]


static func model_b_text(s: Dictionary) -> String:
	if s.fam == "poly":
		return Fmt.poly(s.B, "t")
	return Fmt.poly([s.q, s.p], "t")


func u_context_models(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var who: String = s.who
	var other := "B" if who == "A" else "A"
	var ts: Array = s.ts
	var poly: bool = s.fam == "poly"
	# A − B < 0 between the crossings: A exceeds B for t past the positive one.
	var d := func(t: float) -> float: return S.models_h(s, t) if who == "A" else -S.models_h(s, t)
	var crit := zeros_crit(ts, ">")
	var ok := func(t: float) -> bool: return d.call(t) > 0.0
	var ps := solve(crit, ok, Q.new(0), true)
	var right := set_text(ps, "t")
	var T: Variant = ts[1]
	var V: Variant = Q.new(s.p + s.q * T.n) if poly else S.models_a(s, ts[1])
	var swapped: Array = []
	for p in ps:
		var q: Dictionary = p.duplicate()
		for key in ["lo", "hi"]:
			if q[key] != null and same(q[key], T):
				q[key] = V
		swapped.append(q)
	var wrongs: Array = [cw(set_text(solve(crit, ok), "t"), CI + "0"), cw(set_text(swapped, "t"), CI + "2")]
	var comp := solve(zeros_crit(ts, "≥"), func(t: float) -> bool: return d.call(t) < 0.0, Q.new(0), true)
	var ends := solve(zeros_crit(ts, "≥"), ok, Q.new(0), true)
	var out := choice(right, wrongs, [set_text(comp, "t"), set_text(ends, "t")])
	var ctx: Array = CONTEXTS[s.ctx]
	out.asked = "Find the values of t for which %s." % (ctx[2] % [who, other])
	out.lines = ["%s A(t) = %s and B(t) = %s, for t ≥ 0." % [ctx[0], model_a_text(s), model_b_text(s)]]
	var f := fin(right)
	var cx := "t = %s and t = %s" % [Wv(ts[0]), Wv(ts[1])]
	var sign_words := "%s(t) > %s(t) %s" % [who, other, "for t > " + Wv(T) if (who == "A") else "between the crossings"]
	var methods := {
		"gdc-intersections-context": [
			"Graph y = %s and y = %s on the GDC for t ≥ 0: they meet at t = %s." % [model_a_text(s), model_b_text(s), Wv(T)],
			"%s, and the inequality is strict, so the crossing is left out." % sign_words,
			"The model starts at t = 0, which is included. " + f],
		"interpret-domain": [
			"Solving A(t) = B(t) gives %s." % cx,
			"t = %s is a negative time, outside the model's t ≥ 0, so only t = %s is a boundary, with t = 0 the start." % [Wv(ts[0]), Wv(T)],
			"%s, so %s." % [sign_words, "past it" if who == "A" else "until it"], f],
	}
	if poly:
		var diff: Array = [s.B[0], s.B[1] - s.q, s.B[2] - s.p]
		var lead := "−" if s.cc == 1 else "−%d" % s.cc
		methods["algebraic-polynomial-model"] = [
			"B(t) − A(t) = %s = %s(t + %d)(t − %d)." % [Fmt.poly(diff, "t"), lead, s.r, s.s],
			"Its zeros are t = −%d and t = %d, and it is positive between them and negative outside." % [s.r, s.s],
			"Only t ≥ 0 is allowed, and %s(t) − %s(t) must be positive. " % [who, other] + f]
	steps_out(out, methods)
	return out


const WHOLE := {
	"grow": "An investment of $%s earns interest at %s%% a year, compounded yearly. Its value after n years is %s × %s^n dollars.",
	"decay": "A patient takes a %s mg dose of a medicine. The amount left in the body n hours later is %s × %s^n mg.",
	"quad": "The nth pattern in a sequence of tile patterns uses n² + %dn tiles.",
}


func u_least_whole_number(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var ans := Answer.make("number", {"v": Q.new(n)}, {}, "n = ")
	ans.exact = true
	var nstar: float = s.nstar
	var line: String
	var asked: String
	var formula: String
	var target := "%s" % N(s.T)
	match s.fam:
		"grow":
			var pct := Fmt.dec(s.r.sub(1).mul(100))
			line = WHOLE.grow % [N(s.P), pct, N(s.P), Fmt.dec(s.r)]
			asked = "Find the least number of whole years n for which the value is more than $%s." % target
			formula = "%s × %s^n" % [N(s.P), Fmt.dec(s.r)]
		"decay":
			line = WHOLE.decay % [N(s.P), N(s.P), Fmt.dec(s.r)]
			asked = "Find the least whole number of hours n after which less than %s mg is left." % target
			formula = "%s × %s^n" % [N(s.P), Fmt.dec(s.r)]
		_:
			line = WHOLE.quad % s.b
			asked = "Find the least n for which the pattern uses more than %s tiles." % target
			formula = "n² + %dn" % s.b
	var rel := "<" if s.fam == "decay" else ">"
	var before := S.whole_at(s, float(n - 1))
	var after := S.whole_at(s, float(n))
	var shown := func(v: float) -> String: return Fmt.num(int(round(v))) if s.fam == "quad" else GdcKit.W(v)
	var fin_n := "So n = %d." % n
	var solve_line := "Solve %s = %s: n = ln(%s/%s)/ln %s = %s." % [formula, target, target, N(s.P), Fmt.dec(s.r), GdcKit.W(nstar)] if s.fam != "quad" \
		else "Solve n² + %dn = %s: n = (−%d + √%d)/2 = %s." % [s.b, target, s.b, s.b * s.b + 4 * s.T, GdcKit.W(nstar)]
	return {
		"asked": asked, "lines": [line], "answer": ans,
		"wrongs": [wrong({"v": Q.new(n - 1)}, CI + "1")],
		"fillers": [{"v": Q.new(n + 1)}, {"v": Q.new(n + 2)}, {"v": Q.new(n - 2)}],
		"methods": {
			"gdc-intersections-context": method([
				"Graph y = %s and y = %s on the GDC: they meet at n = %s." % [formula.replace("n", "x"), target, GdcKit.W(nstar)],
				"The formula is %s %s for n past the crossing, and n is a whole number, so round up, not to the nearest." % [rel, target],
				"Check: n = %d gives %s, not yet %s %s; n = %d gives %s. %s" % [n - 1, shown.call(before), rel, target, n, shown.call(after), fin_n]], ans.values),
			"interpret-domain": method([
				solve_line,
				"n counts whole %s, and the crossing is not whole, so take the next whole number up: n = %d." % ["years" if s.fam == "grow" else ("hours" if s.fam == "decay" else "patterns"), n],
				"Check: n = %d gives %s and n = %d gives %s. %s" % [n - 1, shown.call(before), n, shown.call(after), fin_n]], ans.values),
		},
	}
