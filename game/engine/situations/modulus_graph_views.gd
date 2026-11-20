class_name ModulusGraphViews
extends ExtensionViews
## The views on the `modulus-graph` situation (FAL-1008): one builder per unknown of
## fn-ahl-modulus-graphs (AA HL 2.16). Builders return what QuadraticViews' builders return
## (see quadratic_views.gd).
##
## A sketch is "which of four graphs" (GdcKit.pick): the question shows the graph of f with
## its zeros and turning points labelled, and each card is f with one transformation applied
## to every sampled point, so the right card and each slip come from the same f. A card is
## named by its `mistake`, the transformation it draws (CARDS), and the checker draws it
## again from that name alone. 1/f is drawn branch by branch between its vertical
## asymptotes (dashed), each branch traced to the edge of the plot, so none crosses one.
##
## Every cell can be Paper 1 or Paper 2; the GDC methods are Paper 2. Answers are exact.

const SK := "AHL2.16."
const R_SWAP := SK + "modulus-graphs#0"
const R_LEFT := SK + "modulus-graphs#1"
const R_NEG := SK + "modulus-graphs#2"
const R_TP := SK + "reciprocal-graph#0"
const R_INV := SK + "reciprocal-graph#1"
const R_SIDE := SK + "reciprocal-graph#2"
const R_CROSS := SK + "square-graph#0"
const R_ABS := SK + "square-graph#1"
const R_PERIOD := SK + "square-graph#2"
## fn-ahl-modulus-graphs' own slips.
const T := "fn-ahl-modulus-graphs#"
const R_BEFORE := T + "9"
const R_HALF := T + "10"

## The plot every graph of the type is drawn in: x from −7 to 7, y from −6 to 6.
const WIN := [-7, 7, -6, 6]
const SAMPLES := 280

## Each pick-the-graph unknown: the right card, then its wrong cards
## [mistake, ref, why-template]. A card's mistake is the transformation it draws.
const PICKS := {
	"modulus-of-f": ["abs", [["fabs", R_SWAP], ["neg", R_NEG], ["pos", ""]]],
	"f-of-modulus": ["fabs", [["abs", R_SWAP], ["fnegabs", R_LEFT], ["fneg", ""]]],
	"modulus-of-both": ["absabs", [["absnegabs", R_LEFT], ["abs", ""], ["fabs", ""]]],
	"pick-reciprocal": ["recip", [["inverse", R_INV], ["recipmid", R_SIDE], ["k2recip", ""]]],
	"pick-square": ["sq", [["sgnsq", R_CROSS], ["abs", R_ABS], ["fx2", ""]]],
}
## The situation shape each pick unknown is drawn on.
const PICK_SHAPE := {"mod": ["modulus-of-f", "f-of-modulus", "modulus-of-both"], "recip": ["pick-reciprocal"],
	"square": ["pick-square"]}


func needs() -> Dictionary:
	return {
		"modulus-of-f": {"shape": "mod"},
		"f-of-modulus": {"shape": "mod"},
		"modulus-of-both": {"shape": "mod"},
		"vertex-image": {"shape": "vertex"},
		"f-of-modulus-intercepts": {"shape": "zeros"},
		"f-of-modulus-inequality": {"shape": "ineq"},
		"pick-reciprocal": {"shape": "recip"},
		"reciprocal-asymptotes": {"shape": "move"},
		"reciprocal-turning-point": {"shape": "turn"},
		"pick-square": {"shape": "square"},
		"square-features": {"shape": "sqfeat"},
	}


## Every cell can be either paper; QuestionEngine makes the GDC methods' Paper 2.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1, 2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = ModulusGraphSituation.export(s)
	return out


# ── Writing f ────────────────────────────────────────────────

static func rule(s: Dictionary) -> String:
	if s.fam == "sine":
		return "%s sin%s" % [Fmt.lead(s.A), " x" if s.b == 1 else "(%dx)" % s.b] if s.A != 1 else "sin%s" % (" x" if s.b == 1 else "(%dx)" % s.b)
	return Fmt.poly(s.coef)


static func fx(s: Dictionary) -> String:
	return "f(x) = " + rule(s)


## f from its features: "½(x + 1)(x − 3)", "−(x − 1)(x + 2)²".
static func factored(s: Dictionary) -> String:
	match s.fam:
		"quad":
			if s.zs.is_empty():
				return Fmt.vertex(s.a, s.h, s.k)
			return Fmt.lead(s.a) + Fmt.factor(s.zs[0]) + Fmt.factor(s.zs[1])
		"cubic":
			return Fmt.lead(s.a) + Fmt.factor(s.p) + Fmt.factor(s.q) + "²"
		"cubic3":
			return Fmt.factor(s.zs[0]) + Fmt.factor(s.zs[1]) + Fmt.factor(s.zs[2])
	return rule(s)


static func y(s: Dictionary, x: float) -> float:
	return ModulusGraphSituation.y(s, x)


## The turning point of f a question names: the vertex, or the cubic's off the axis.
static func turn_pt(s: Dictionary) -> Array:
	if s.fam == "cubic":
		return [Q.new(s.t), s.v]
	return [Q.new(s.h), Q.new(s.k)]


static func xs_text(xs: Array) -> String:
	var sorted := xs.duplicate()
	sorted.sort()
	return ", ".join(sorted.map(func(x): return "x = " + Fmt.num(x))) if sorted.size() > 1 else "x = " + Fmt.num(sorted[0])


static func and_list(items: Array) -> String:
	if items.size() <= 1:
		return "".join(items)
	return ", ".join(items.slice(0, -1)) + " and " + items[-1]


static func zeros_and(xs: Array) -> String:
	var sorted := xs.duplicate()
	sorted.sort()
	return and_list(sorted.map(func(x): return "x = " + Fmt.num(x)))


static func pos_zeros(s: Dictionary) -> Array:
	return s.zs.filter(func(z): return z > 0)


static func neg_zeros(s: Dictionary) -> Array:
	return s.zs.filter(func(z): return z < 0)


## Where f is below the x-axis, in words: "−1 < x < 3", "x < −2 or x > 4", "x > 1".
static func below(s: Dictionary) -> String:
	var a: Q = s.a
	if s.fam == "quad":
		var r0 := Fmt.num(s.zs[0])
		var r1 := Fmt.num(s.zs[1])
		return "%s < x < %s" % [r0, r1] if a.sign() > 0 else "x < %s or x > %s" % [r0, r1]
	# a(x − p)(x − q)²: the sign of a(x − p), and 0 at q.
	var side := "x < %s" % Fmt.num(s.p) if a.sign() > 0 else "x > %s" % Fmt.num(s.p)
	var q_in: bool = (s.q < s.p) == (a.sign() > 0)
	return side + (", apart from x = %s where it touches the axis" % Fmt.num(s.q) if q_in else "")


# ── The cards ────────────────────────────────────────────────

## The value of a card's function at x (NAN where it has none).
static func card_y(s: Dictionary, mistake: String, x: float) -> float:
	var f := func(t: float) -> float: return y(s, t)
	match mistake:
		"f":
			return f.call(x)
		"abs":
			return absf(f.call(x))
		"fabs":
			return f.call(absf(x))
		"fnegabs":
			return f.call(-absf(x))
		"neg":
			return -f.call(x)
		"fneg":
			return f.call(-x)
		"pos":
			return maxf(f.call(x), 0.0)
		"absabs":
			return absf(f.call(absf(x)))
		"absnegabs":
			return absf(f.call(-absf(x)))
		"recip":
			var v: float = f.call(x)
			return NAN if v == 0.0 else 1.0 / v
		"recipmid":
			var v: float = f.call(x)
			if v == 0.0:
				return NAN
			var mid: bool = x > s.zs[0] and x < s.zs[1]
			return (-1.0 if mid else 1.0) / v
		"k2recip":
			var v: float = f.call(x)
			return NAN if v == 0.0 else float(s.k * s.k) / v
		"sq":
			var v: float = f.call(x)
			return v * v
		"sgnsq":
			var v: float = f.call(x)
			return v * absf(v)
		"fx2":
			return f.call(x * x)
	push_error("ModulusGraphViews: no card %s" % mistake)
	return NAN


## The vertical asymptotes a card has: the zeros of f, for the reciprocal cards.
static func card_breaks(s: Dictionary, mistake: String) -> Array:
	return s.zs.map(func(z): return float(z)) if mistake in ["recip", "recipmid", "k2recip"] else []


## The pieces of y = g(x) inside the window, between the breaks: each a polyline that runs
## to the window's edge where it leaves, found by bisection, so no piece crosses a break.
static func trace(g: Callable, breaks: Array) -> Array:
	var cuts: Array = [float(WIN[0])]
	for x in breaks:
		if x > WIN[0] and x < WIN[1]:
			cuts.append(float(x))
	cuts.append(float(WIN[1]))
	var out: Array = []
	for i in cuts.size() - 1:
		var x0: float = cuts[i] + (1e-4 if i > 0 else 0.0)
		var x1: float = cuts[i + 1] - (1e-4 if i < cuts.size() - 2 else 0.0)
		var line: Array = []
		var prev := []
		for j in SAMPLES + 1:
			var x := x0 + (x1 - x0) * float(j) / SAMPLES
			var yv: float = g.call(x)
			var inside := yv >= WIN[2] and yv <= WIN[3]
			if not prev.is_empty() and prev[2] != inside:
				var edge: float = WIN[3] if (yv > WIN[3] or prev[1] > WIN[3]) else WIN[2]
				var xe := _edge(g, prev[0], x, edge)
				line.append([xe, edge])
				if not inside:
					out.append(line)
					line = []
			if inside:
				line.append([x, yv])
			prev = [x, yv, inside]
		if line.size() > 1:
			out.append(line)
	return out.filter(func(l): return l.size() > 1)


static func _edge(g: Callable, xa: float, xb: float, edge: float) -> float:
	var fa: float = g.call(xa) - edge
	# A sample exactly on the edge is the edge point (bisection would run off from it).
	if fa == 0.0:
		return xa
	if g.call(xb) - edge == 0.0:
		return xb
	for i in 60:
		var xm := (xa + xb) / 2.0
		var fm: float = g.call(xm) - edge
		if (fm < 0.0) == (fa < 0.0):
			xa = xm
			fa = fm
		else:
			xb = xm
	return (xa + xb) / 2.0


## The reflection of f in y = x: the points (f(t), t), t across the window's height, in
## pieces inside the window (an x-edge found by bisection).
static func trace_inverse(s: Dictionary) -> Array:
	var out: Array = []
	var line: Array = []
	var prev := []
	for j in SAMPLES + 1:
		var t := WIN[2] + (WIN[3] - WIN[2]) * float(j) / SAMPLES
		var xv := y(s, t)
		var inside := xv >= WIN[0] and xv <= WIN[1]
		if not prev.is_empty() and prev[2] != inside:
			var edge: float = WIN[1] if (xv > WIN[1] or prev[1] > WIN[1]) else WIN[0]
			var ta: float = prev[0]
			var tb := t
			var fa: float = y(s, ta) - edge
			# A sample exactly on the edge is the edge point (bisection would run off from it).
			if fa == 0.0:
				tb = ta
			elif y(s, tb) - edge == 0.0:
				ta = tb
			for i in (0 if ta == tb else 60):
				var tm := (ta + tb) / 2.0
				var fm := y(s, tm) - edge
				if (fm < 0.0) == (fa < 0.0):
					ta = tm
					fa = fm
				else:
					tb = tm
			line.append([edge, (ta + tb) / 2.0])
			if not inside:
				out.append(line)
				line = []
		if inside:
			line.append([xv, t])
		prev = [t, xv, inside]
	if line.size() > 1:
		out.append(line)
	return out.filter(func(l): return l.size() > 1)


static func card(s: Dictionary, mistake: String) -> Dictionary:
	var curves: Array
	if mistake == "inverse":
		curves = trace_inverse(s)
	else:
		curves = trace(func(x: float) -> float: return card_y(s, mistake, x), card_breaks(s, mistake))
	var g := GdcKit.card(curves, [], WIN, card_breaks(s, mistake).map(func(v): return [v, ""]))
	g.one_colour = true
	return g


## The graph of f a question shows, its zeros and turning points labelled.
static func plot(s: Dictionary, extra: Array = [], hlines: Array = []) -> Dictionary:
	var pts: Array = []
	for z in s.zs:
		pts.append([float(z), 0.0, Fmt.point(z, 0)])
	if s.fam == "quad":
		pts.append([float(s.h), float(s.k), Fmt.point(s.h, s.k)])
	elif s.fam == "cubic":
		pts.append([float(s.t), s.v.to_float(), Fmt.point(s.t, s.v)])
	pts += extra
	var g := Plot.spec(trace(func(x: float) -> float: return y(s, x), []), pts, WIN[0], WIN[1], WIN[2], WIN[3], hlines, [])
	g.one_colour = true
	return g


## Whether every pair of cards a pick unknown on this situation offers differs where you can
## see it: at some x both are inside the plot and half a unit apart, or one is in and the
## other is out by half a unit. The reflection in y = x always differs.
static func cards_differ(s: Dictionary, shape: String) -> bool:
	for u in PICK_SHAPE.get(shape, []):
		var names: Array = [PICKS[u][0]]
		for w in PICKS[u][1]:
			if w[0] != "inverse":
				names.append(w[0])
		for i in names.size():
			for j in range(i + 1, names.size()):
				if not _apart(s, names[i], names[j]):
					return false
	return true


static func _apart(s: Dictionary, m1: String, m2: String) -> bool:
	for j in 281:
		var x: float = WIN[0] + (WIN[1] - WIN[0]) * j / 280.0
		var a := card_y(s, m1, x)
		var b := card_y(s, m2, x)
		if is_nan(a) or is_nan(b):
			continue
		var ina: bool = a >= WIN[2] and a <= WIN[3]
		var inb: bool = b >= WIN[2] and b <= WIN[3]
		if (ina or inb) and absf(clampf(a, WIN[2] - 1, WIN[3] + 1) - clampf(b, WIN[2] - 1, WIN[3] + 1)) >= 0.5:
			return true
	return false


## A pick-the-graph question: the cards PICKS lists for the unknown, each wrong one with
## what is wrong with it.
func _pick(unknown: String, asked: String, s: Dictionary, why: Dictionary, methods: Dictionary, rng: Seeded) -> Dictionary:
	var wrongs: Array = []
	for w in PICKS[unknown][1]:
		wrongs.append({"graph": card(s, w[0]), "ref": w[1], "mistake": w[0], "why": why[w[0]]})
	var p := GdcKit.pick(card(s, PICKS[unknown][0]), wrongs, rng)
	var fin := "So the graph is %s." % p.answer.values.v
	var out := {"asked": asked, "lines": ["The graph of y = f(x) is shown, with its zeros and turning points labelled."],
		"graph": plot(s), "answer": p.answer, "graphs": p.graphs, "methods": {}}
	for a in methods:
		var steps: Array = methods[a].duplicate()
		steps.append(fin)
		out.methods[a] = method(steps, p.answer.values)
	return out


# ── |f(x)|, f(|x|) and |f(|x|)| ──────────────────────────────

## What happens to f's turning point under |f(x)|, as a step.
static func turn_moves(s: Dictionary) -> String:
	var tp := turn_pt(s)
	var at := Fmt.point(tp[0], tp[1])
	if tp[1].sign() < 0:
		return "The turning point %s is below the axis, so it goes to %s." % [at, Fmt.point(tp[0], tp[1].neg())]
	return "The turning point %s is above the axis, so it stays where it is." % at


func u_modulus_of_f(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var why := {
		"fabs": "it is the graph of f(|x|): the x < 0 half is replaced, not the part below the x-axis",
		"neg": "it is the graph of −f(x): the parts above the x-axis are reflected too",
		"pos": "the part below the x-axis is deleted, not reflected",
	}
	var methods := {
		"reflect-negative-part": [
			"f(x) < 0 for %s. Keep the rest of the graph as it is." % below(s),
			"Reflect the part below the x-axis in the x-axis. %s" % turn_moves(s)],
		"piecewise-definition": [
			"|f(x)| = f(x) where f(x) ≥ 0, and −f(x) where f(x) < 0, that is for %s." % below(s),
			"So |f(x)| is never negative: it meets the x-axis at the zeros of f, %s. %s" % [zeros_and(s.zs), turn_moves(s)]],
	}
	return _pick("modulus-of-f", "Which graph is y = |f(x)|?", s, why, methods, rng)


## The right half's features mirrored, as a step.
static func mirrored(s: Dictionary) -> String:
	var zp := pos_zeros(s)
	var parts: Array = []
	for z in zp:
		parts.append("x = ±%s" % Fmt.num(z))
	var out := "It meets the x-axis at %s" % and_list(parts)
	var tp := turn_pt(s)
	if tp[0].sign() > 0:
		out += ", with turning points %s and %s" % [Fmt.point(tp[0], tp[1]), Fmt.point(tp[0].neg(), tp[1])]
	return out + "."


func u_f_of_modulus(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var why := {
		"abs": "it is the graph of |f(x)|: the part below the x-axis is reflected, not the x ≥ 0 half",
		"fnegabs": "it mirrors the x ≤ 0 half of f, not the x ≥ 0 half",
		"fneg": "it is the graph of f(−x): the whole graph is reflected in the y-axis, so the x ≥ 0 half is not f's",
	}
	var methods := {
		"keep-right-reflect": [
			"For x ≥ 0, |x| = x, so f(|x|) = f(x): keep the graph of f for x ≥ 0.",
			"Replace the x < 0 half with the mirror image of the x ≥ 0 half in the y-axis. %s" % mirrored(s)],
		"piecewise-definition": [
			"f(|x|) = f(x) for x ≥ 0, and f(−x) for x < 0.",
			"At x < 0, f(−x) is the value f has at −x > 0, so the left half mirrors the right half. %s" % mirrored(s)],
	}
	return _pick("f-of-modulus", "Which graph is y = f(|x|)?", s, why, methods, rng)


func u_modulus_of_both(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var why := {
		"absnegabs": "it mirrors the x ≤ 0 half of f, not the x ≥ 0 half, before the parts below the axis are reflected",
		"abs": "it is the graph of |f(x)|: the x < 0 half is f's own, not the mirror image of the x ≥ 0 half",
		"fabs": "it is the graph of f(|x|): the parts below the x-axis are not reflected",
	}
	var methods := {
		"reflect-negative-part": [
			"Start from f(|x|): keep the graph of f for x ≥ 0 and mirror it in the y-axis. %s" % mirrored(s),
			"Then reflect every part below the x-axis in the x-axis, so the graph is never negative and is symmetric in the y-axis."],
		"keep-right-reflect": [
			"For x ≥ 0, |f(|x|)| = |f(x)|: keep the graph of f for x ≥ 0 and reflect any part of it below the x-axis.",
			"|f(|−x|)| = |f(|x|)|, so the x < 0 half is the mirror image of that half in the y-axis. %s" % mirrored(s)],
	}
	return _pick("modulus-of-both", "Which graph is y = |f(|x|)|?", s, why, methods, rng)


func u_vertex_image(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h := Q.new(s.h)
	var k := Q.new(s.k)
	var ans := Answer.make("point", {"x": h, "y": k.abs_q()})
	ans.exact = true
	var wrongs: Array = []
	if k.sign() > 0:
		wrongs.append(wrong({"x": h, "y": k.neg()}, R_NEG))
	var fillers: Array = [{"x": h.neg(), "y": k.abs_q()}, {"x": h, "y": k} if k.sign() < 0 else {"x": h.neg(), "y": k.neg()},
		{"x": k.abs_q(), "y": h}, {"x": h, "y": k.abs_q().add(1)}]
	var vf := Fmt.vertex(s.a, s.h, s.k)
	var fin := "So the vertex moves to %s." % Answer.text(ans)
	var where := "below" if k.sign() < 0 else "above"
	var moved := "it is reflected in the x-axis: %s goes to %s" % [Fmt.point(h, k), Fmt.point(h, k.neg())] if k.sign() < 0 \
		else "|f(x)| = f(x) there, so it stays where it is"
	return {
		"asked": "Find the coordinates of the point that the vertex of the graph of y = f(x) moves to on the graph of y = |f(x)|.",
		"lines": [fx(s)], "answer": ans, "wrongs": wrongs, "fillers": fillers,
		"methods": {
			"reflect-negative-part": method(["Complete the square: f(x) = %s, so the vertex is %s." % [vf, Fmt.point(h, k)],
				"The vertex is %s the x-axis, so %s." % [where, moved], fin], ans.values),
			"piecewise-definition": method(["|f(x)| = f(x) where f(x) ≥ 0, and −f(x) where f(x) < 0.",
				"f(x) = %s, so the vertex is at x = %s, where f(%s) = %s." % [vf, Fmt.num(h), Fmt.num(h), Fmt.num(k)],
				"|f(%s)| = |%s| = %s. %s" % [Fmt.num(h), Fmt.num(k), Fmt.num(k.abs_q()), fin]], ans.values),
		},
	}


static func xs_ans(xs: Array) -> Dictionary:
	var sorted := xs.duplicate()
	sorted.sort()
	var ans := Answer.make("xs", Answer.xs_of(sorted.map(func(x): return Q.new(x))))
	ans.exact = true
	return ans


static func xs_vals(xs: Array) -> Dictionary:
	var sorted := xs.duplicate()
	sorted.sort()
	return Answer.xs_of(sorted.map(func(x): return Q.new(x)))


static func pm(xs: Array) -> Array:
	var out: Array = []
	for x in xs:
		out.append(-absi(x))
		out.append(absi(x))
	out.sort()
	return out


func u_f_of_modulus_intercepts(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var zp := pos_zeros(s)
	var zn := neg_zeros(s)
	var ans := xs_ans(pm(zp))
	var fin := "So %s." % Answer.text(ans)
	var lines: Array = [fx(s)]
	var graph: Variant = null
	var found := "Solve f(x) = 0: %s = 0 gives %s." % [factored(s), zeros_and(s.zs)]
	if rep == "graph":
		lines = ["The graph of y = f(x) is shown, with its zeros and turning points labelled."]
		graph = plot(s)
		found = "The graph of y = f(x) meets the x-axis at %s." % zeros_and(s.zs)
	var dropped := "drop %s, which %s on the left" % [zeros_and(zn), "is" if zn.size() == 1 else "are"]
	return {
		"asked": "Find the x-coordinates of the points where the graph of y = f(|x|) meets the x-axis.",
		"lines": lines, "graph": graph, "answer": ans,
		"wrongs": [wrong(xs_vals(pm(zn)), R_LEFT)],
		"fillers": [xs_vals(s.zs), xs_vals(pm(s.zs)), xs_vals(zp)],
		"methods": {
			"keep-right-reflect": method([found,
				"For x ≥ 0, f(|x|) = f(x): keep %s and %s." % [zeros_and(zp), dropped],
				"The graph of y = f(|x|) is that half mirrored in the y-axis. " + fin], ans.values),
			"piecewise-definition": method(["f(|x|) = f(x) for x ≥ 0, and f(−x) for x < 0. " + found,
				"For x ≥ 0, f(x) = 0 at %s only." % zeros_and(zp),
				"For x < 0, f(−x) = 0 where −x is one of those, at %s. %s" % [zeros_and(zp.map(func(z): return -z)), fin]], ans.values),
		},
	}


# ── An inequality in f(|x|) ──────────────────────────────────

func u_f_of_modulus_inequality(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rel: String = s.rel
	var strict := rel in ["<", ">"]
	var lt := "<" if strict else "≤"
	var gt := ">" if strict else "≥"
	var a: Q = s.a
	var inside := (a.sign() > 0) == (rel in ["<", "≤"])
	var lo: int = s.h - s.m
	var hi: int = s.h + s.m
	var L := func(v: int) -> String: return Fmt.num(v)
	var right: String
	var half: String
	var plain: String
	if inside:
		plain = "%s %s x %s %s" % [L.call(lo), lt, lt, L.call(hi)]
		if lo > 0:
			right = "%s %s x %s %s or %s %s x %s %s" % [L.call(-hi), lt, lt, L.call(-lo), L.call(lo), lt, lt, L.call(hi)]
			half = plain
		else:
			right = "%s %s x %s %s" % [L.call(-hi), lt, lt, L.call(hi)]
			half = "0 ≤ x %s %s" % [lt, L.call(hi)]
	else:
		plain = "x %s %s or x %s %s" % [lt, L.call(lo), gt, L.call(hi)]
		if lo > 0:
			right = "x %s %s or %s %s x %s %s or x %s %s" % [lt, L.call(-hi), L.call(-lo), lt, lt, L.call(lo), gt, L.call(hi)]
			half = "0 ≤ x %s %s or x %s %s" % [lt, L.call(lo), gt, L.call(hi)]
		else:
			right = "x %s %s or x %s %s" % [lt, L.call(-hi), gt, L.call(hi)]
			half = "x %s %s" % [gt, L.call(hi)]
	var flip := right.replace("<", "#").replace("≤", "<").replace("#", "≤").replace(">", "#").replace("≥", ">").replace("#", "≥")
	var mirror := ("%s %s x %s %s" % [L.call(-hi), lt, lt, L.call(-lo)]) if inside else ("x %s %s or x %s %s" % [lt, L.call(-hi), gt, L.call(-lo)])
	var out := RationalQuadraticViews.choice(right, [RationalQuadraticViews.cw(half, R_HALF)], [plain, flip, mirror])
	out.asked = "Find the set of values of x for which f(|x|) %s %s." % [rel, Fmt.num(s.c)]
	out.lines = ["The graph of y = f(x) is shown, with the line y = %s." % Fmt.num(s.c)]
	out.graph = plot(s, [[float(lo), float(s.c), Fmt.point(lo, s.c)], [float(hi), float(s.c), Fmt.point(hi, s.c)]],
		[[float(s.c), "y = %s" % Fmt.num(s.c)]])
	var side := "between them" if inside else "outside them"
	var right_half := "%s %s x %s %s" % [L.call(lo), lt, lt, L.call(hi)] if inside and lo > 0 else half
	out.methods = {"keep-right-reflect": method([
		"From the graph, f(x) = %s at x = %s and x = %s, and f(x) %s %s %s." % [Fmt.num(s.c), L.call(lo), L.call(hi), rel, Fmt.num(s.c), side],
		"For x ≥ 0, f(|x|) = f(x), so f(|x|) %s %s for %s there." % [rel, Fmt.num(s.c), right_half],
		"f(|x|) is even, so the set is symmetric in the y-axis: mirror that piece for x < 0. So %s." % right], out.answer.values)}
	return out


# ── 1/f(x) ───────────────────────────────────────────────────

func u_pick_reciprocal(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var h := Q.new(s.h)
	var k := Q.new(s.k)
	var inv_k := Q.new(1).div(k)
	# A minimum of f is a maximum of 1/f, and a maximum a minimum.
	var kind := "maximum" if s.a.sign() > 0 else "minimum"
	var r0 := Fmt.num(s.zs[0])
	var r1 := Fmt.num(s.zs[1])
	var why := {
		"inverse": "it is the reflection of f in the line y = x, not the graph of 1/f(x)",
		"recipmid": "between x = %s and x = %s it is on the other side of the x-axis from f" % [r0, r1],
		"k2recip": "its turning point is %s, where f's is, not %s" % [Fmt.point(h, k), Fmt.point(h, inv_k)],
	}
	var between := "negative" if s.a.sign() > 0 else "positive"
	var outside := "positive" if s.a.sign() > 0 else "negative"
	var methods := {
		"feature-swap": [
			"The zeros of f, x = %s and x = %s, become the vertical asymptotes of 1/f." % [r0, r1],
			"The turning point %s becomes %s, a local %s, and as f grows large, 1/f tends to 0." % [Fmt.point(h, k), Fmt.point(h, inv_k), kind]],
		"sign-and-size": [
			"1/f has the sign of f: %s between x = %s and x = %s, and %s outside." % [between, r0, r1, outside],
			"Near a zero f is small, so 1/f is large; where f is large, 1/f is near 0. Between the zeros 1/f is closest to the axis at %s." % Fmt.point(h, inv_k)],
		"gdc-graph": [
			"From its zeros and turning point, f(x) = %s. Graph y = 1/f(x) on the GDC." % factored(s),
			"It has vertical asymptotes x = %s and x = %s and a turning point at %s." % [r0, r1, Fmt.point(h, inv_k)]],
	}
	return _pick("pick-reciprocal", "Which graph is y = 1/f(x)?", s, why, methods, rng)


func u_reciprocal_asymptotes(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var moved: bool = s.mx != 0 or s.my != 0
	var gz: Array = s.gzs if moved else s.zs
	var right := RationalQuadraticViews.xs_and(gz)
	var wrongs: Array = []
	if moved:
		wrongs.append(RationalQuadraticViews.cw(RationalQuadraticViews.xs_and(s.zs), R_BEFORE))
	var back: Array = [s.h - s.mx - s.n, s.h - s.mx + s.n]
	var fillers: Array = [RationalQuadraticViews.xs_and(gz.map(func(z): return -z)), "x = %s" % Fmt.num(s.h + s.mx),
		RationalQuadraticViews.xs_and(back), "no vertical asymptotes"]
	var out := RationalQuadraticViews.choice(right, wrongs, fillers)
	var name := "g" if moved else "f"
	out.lines = [fx(s)]
	if moved:
		out.lines.append("The graph of y = f(x) is translated by the vector (%s, %s) to give the graph of y = g(x)." % [Fmt.num(s.mx), Fmt.num(s.my)])
	out.asked = "Find the equations of the vertical asymptotes of the graph of y = 1/%s(x)." % name
	var H: int = s.h + s.mx
	var nn: int = s.n
	var fv := Fmt.vertex(1, s.h, -s.m * s.m)
	var steps: Array = []
	if moved:
		var gv := Fmt.vertex(1, H, -nn * nn)
		steps.append("Complete the square: f(x) = %s. The translation gives g(x) = f(x %s %s) %s %s = %s." % [fv,
			"−" if s.mx >= 0 else "+", Fmt.num(absi(s.mx)), "+" if s.my >= 0 else "−", Fmt.num(absi(s.my)), gv])
		steps.append("g(x) = 0 where (%s)² = %s: x = %s ± %s, that is %s." % [Fmt.factor(H).trim_prefix("(").trim_suffix(")"), Fmt.num(nn * nn), Fmt.num(H), Fmt.num(nn), zeros_and(gz)])
	else:
		steps.append("Factorise: f(x) = %s, so f(x) = 0 at %s." % [Fmt.factor(gz[0]) + Fmt.factor(gz[1]), zeros_and(gz)])
	steps.append("1/%s(x) grows without bound where %s(x) = 0, so each zero is a vertical asymptote. So the vertical asymptotes are %s." % [name, name, right])
	out.methods = {"feature-swap": method(steps, out.answer.values)}
	return out


func u_reciprocal_turning_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h := Q.new(s.h)
	var k := Q.new(s.k)
	var inv := Q.new(1).div(k)
	var a: Q = s.a
	var f_kind := "minimum" if a.sign() > 0 else "maximum"
	var kind := "maximum" if a.sign() > 0 else "minimum"
	var other := "minimum" if kind == "maximum" else "maximum"
	var ans := Answer.make("vertex_kind", {"x": h, "y": inv, "kind": kind})
	var fin := "So the turning point is %s." % Answer.text(ans)
	var lines: Array = [fx(s)]
	var graph: Variant = null
	var read := "Complete the square: f(x) = %s, so f has a %s at %s." % [Fmt.vertex(a, h, k), f_kind, Fmt.point(h, k)]
	if rep == "graph":
		lines = ["The graph of the quadratic y = f(x) is shown, with its vertex labelled."]
		graph = plot(s)
		read = "The graph shows that f has a %s at %s." % [f_kind, Fmt.point(h, k)]
	# 1/k, and its value when the two read differently: "1/2", "1/(−3) = −1/3".
	var one_over := "1/%s" % Fmt.paren(k)
	var inv_eq := one_over if one_over == Fmt.num(inv) else "%s = %s" % [one_over, Fmt.num(inv)]
	var least := "least" if f_kind == "minimum" else "greatest"
	var most := "greatest" if f_kind == "minimum" else "least"
	return {
		"asked": "Find the coordinates of the turning point of the graph of y = 1/f(x), and say whether it is a maximum or a minimum.",
		"lines": lines, "graph": graph, "answer": ans,
		"wrongs": [wrong({"x": h, "y": k.neg(), "kind": kind}, R_TP), wrong({"x": h, "y": k, "kind": kind}, R_TP)],
		"fillers": [{"x": h, "y": inv, "kind": other}, {"x": h, "y": inv.neg(), "kind": kind}, {"x": h.neg(), "y": inv, "kind": kind}],
		"methods": {
			"feature-swap": method([read,
				"1/f has a turning point where f does, at x = %s, with y = %s." % [Fmt.num(h), inv_eq],
				"A %s of f becomes a %s of 1/f. %s" % [f_kind, kind, fin]], ans.values),
			"sign-and-size": method([read,
				"Near x = %s, f keeps the sign of %s, and %s is its %s value there." % [Fmt.num(h), Fmt.num(k), Fmt.num(k), least],
				"Taking reciprocals of numbers of one sign reverses their order, so %s is the %s value of 1/f near x = %s. %s" % [inv_eq, most, Fmt.num(h), fin]], ans.values),
			"gdc-graph": method(["Graph y = 1/f(x) on the GDC%s." % ("" if rep == "equation" else ", with f(x) = " + Fmt.vertex(a, h, k)),
				"Its local %s is at (%s, %s), and %s = 1/%s." % [kind, Fmt.num(h), GdcKit.W(inv.to_float()), GdcKit.W(inv.to_float()), Fmt.paren(k)],
				fin], ans.values),
		},
	}


# ── [f(x)]² ──────────────────────────────────────────────────

func u_pick_square(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var tp := turn_pt(s)
	var top := Fmt.point(tp[0], tp[1].mul(tp[1]))
	var why := {
		"sgnsq": "it crosses the x-axis at the zeros of f, but [f(x)]² is never negative",
		"abs": "it is the graph of |f(x)|: the turning point is at %s, not %s" % [Fmt.point(tp[0], tp[1].abs_q()), top],
		"fx2": "it is the graph of f(x²): x is squared, not the output f(x)",
	}
	var methods := {
		"square-outputs": [
			"Squaring makes every output positive or zero: [f(x)]² touches the x-axis at the zeros of f, %s." % zeros_and(s.zs),
			"The turning point %s of f goes to %s, since %s² = %s; heights below 1 shrink and heights above 1 grow." % [
				Fmt.point(tp[0], tp[1]), top, Fmt.paren(tp[1]), Fmt.num(tp[1].mul(tp[1]))]],
		"gdc-graph": [
			"From its zeros and turning point, f(x) = %s. Graph y = [f(x)]² on the GDC." % factored(s),
			"It touches the x-axis at %s and has a turning point at %s." % [zeros_and(s.zs), top]],
	}
	return _pick("pick-square", "Which graph is y = [f(x)]²?", s, why, methods, rng)


static func pts_vals(pts: Array) -> Dictionary:
	var out := {"n": str(pts.size())}
	for i in pts.size():
		out["x%d" % i] = Q.of(pts[i][0])
		out["y%d" % i] = Q.of(pts[i][1])
	return out


func u_square_features(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	if s.fam == "sine":
		return _square_period(s)
	var h := Q.new(s.h)
	var k := Q.new(s.k)
	var K := k.mul(k)
	var r0: int = s.zs[0]
	var r1: int = s.zs[1]
	var ans := Answer.make("pts", pts_vals([[r0, 0], [h, K], [r1, 0]]))
	ans.exact = true
	var fin := "So the turning points are %s." % Answer.text(ans)
	var lines: Array = [fx(s)]
	var graph: Variant = null
	var read := "Factorise: f(x) = %s, with its vertex %s halfway between the zeros." % [factored(s), Fmt.point(h, k)]
	if rep == "graph":
		lines = ["The graph of the quadratic y = f(x) is shown, with its zeros and vertex labelled."]
		graph = plot(s)
		read = "The graph shows the zeros of f, %s, and its vertex %s." % [zeros_and(s.zs), Fmt.point(h, k)]
	var a: Q = s.a
	var df := Fmt.poly([a.mul(2), s.coef[1]])
	return {
		"asked": "Find the coordinates of the turning points of the graph of y = [f(x)]².",
		"lines": lines, "graph": graph, "answer": ans,
		"wrongs": [wrong(pts_vals([[r0, 0], [h, k.abs_q()], [r1, 0]]), R_ABS)],
		"fillers": [pts_vals([[h, K]]), pts_vals([[r0, 0], [h, k], [r1, 0]]), pts_vals([[r0, 0], [r1, 0]]), pts_vals([[r0, 0], [h, K.neg()], [r1, 0]])],
		"methods": {
			"square-outputs": method([read,
				"Squaring makes every output positive or zero, so [f(x)]² touches the x-axis at the zeros: minima (%s, 0) and (%s, 0)." % [Fmt.num(r0), Fmt.num(r1)],
				"The vertex's height %s becomes %s² = %s, a maximum between them. %s" % [Fmt.num(k), Fmt.paren(k), Fmt.num(K), fin]], ans.values),
			"derivative-check": method([read,
				"d/dx [f(x)]² = 2f(x)f′(x), with f′(x) = %s. It is 0 where f(x) = 0, at x = %s and x = %s, and where f′(x) = 0, at x = %s." % [df, Fmt.num(r0), Fmt.num(r1), Fmt.num(h)],
				"[f(%s)]² = %s² = %s, and [f(x)]² = 0 at the zeros. %s" % [Fmt.num(h), Fmt.paren(k), Fmt.num(K), fin]], ans.values),
			"gdc-graph": method(["Graph y = [f(x)]² on the GDC%s." % ("" if rep == "equation" else ", with f(x) = " + factored(s)),
				"It touches the x-axis at x = %s and x = %s, and has a local maximum at %s. %s" % [Fmt.num(r0), Fmt.num(r1), Fmt.point(h, K), fin]], ans.values),
		},
	}


## The period of sin(bx), worked: "2π", "2π/3", "2π/2 = π".
static func _period_text(b: int) -> String:
	var full := Fmt.pi(Q.new(2, b))
	if b == 1:
		return full
	var raw := "2π/%d" % b
	return raw if raw == full else "%s = %s" % [raw, full]


func _square_period(s: Dictionary) -> Dictionary:
	var b: int = s.b
	var A: int = s.A
	var per := Q.new(1, b)
	var ans := DifferentiationViews.form(Fmt.pi(per), [{"slot": "p"}, "π"], {"p": per})
	var fin := "So the period is %s." % Answer.text(ans)
	var full := Q.new(2, b)
	var wrongs: Array = []
	var fillers: Array = []
	if b == 1:
		wrongs.append(DifferentiationViews.alt(Fmt.pi(full), R_PERIOD, {"p": full}))
	else:
		fillers.append({"text": Fmt.pi(full), "p": full})
	for v in [Q.new(1, 2 * b), Q.new(4, b), Q.new(b)]:
		fillers.append({"text": Fmt.pi(v), "p": v})
	var sb := "sin x" if b == 1 else "sin(%dx)" % b
	var A2 := A * A
	var sq := "%s sin²%s" % [Fmt.num(A2), " x" if b == 1 else "(%dx)" % b] if A2 != 1 else "sin²%s" % (" x" if b == 1 else "(%dx)" % b)
	return {
		"asked": "Write down the period of the graph of y = [f(x)]².",
		"lines": [fx(s)], "answer": ans, "wrongs": wrongs, "fillers": fillers,
		"methods": {
			"square-outputs": method([
				"f has period %s: it is positive for the first half of each period and negative for the second." % _period_text(b),
				"[f(x)]² = %s, and squaring makes the negative half a copy of the positive half, so the graph repeats twice as often." % sq,
				fin], ans.values),
			"derivative-check": method([
				"d/dx [f(x)]² = 2f(x)f′(x), which is 0 where %s = 0 or cos%s = 0: every %s." % [sb, " x" if b == 1 else "(%dx)" % b, Fmt.pi(Q.new(1, 2 * b))],
				"[f(x)]² = 0, a minimum, where %s = 0, at x = 0, %s, %s, …, and %s, a maximum, halfway between." % [sb, Fmt.pi(per), Fmt.pi(Q.new(2, b)), Fmt.num(A2)],
				"The graph repeats from one minimum to the next. " + fin], ans.values),
			"gdc-graph": method(["Graph y = [f(x)]² on the GDC, in radians.",
				"It touches 0 at x = 0 and next at x = %s, peaking at %s halfway between, and then repeats." % [GdcKit.W(PI / b), Fmt.num(A2)],
				"%s = %s. %s" % [GdcKit.W(PI / b), Fmt.pi(per), fin]], ans.values),
		},
	}
