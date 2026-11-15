class_name GradientFromGraphViews
extends ExtensionViews
## The views on the `gradient-from-graph` situation: one builder per unknown of
## t5-ext-gradient-from-graph (FAL-777). A gradient read from a drawn tangent or a short chord is
## exact; a GDC gradient is to 3 s.f. Comparing two gradients is a pick of four written answers,
## and choosing the tangent is a pick-the-graph question. The slips read the height of P as the
## gradient, use the line from the origin, divide the run by the rise, drop the minus sign,
## halve the chord's run, or draw a chord for the tangent.
##
## Representations: "graph" (the curve on a grid, with P, the tangent at P, or A and B),
## "table" (f just either side of x = a) and "equation" (f(x), for the GDC).

const SK := "SL5.1.gradient-from-graph#"
const R_HEIGHT := SK + "0"
const R_ORIGIN := SK + "1"
const R_DOWNHILL := SK + "2"
const T := "t5-ext-gradient-from-graph#"
const R_RUN_RISE := T + "3"
const R_NO_MINUS := T + "4"
const R_HALF_RUN := T + "5"
const R_CHORD := T + "6"
const UNKNOWNS := ["tangent-drawn", "chord-table", "gdc-gradient", "compare-two", "pick-tangent"]
const GF := preload("res://engine/situations/gradient_from_graph.gd")


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		if u != "pick-tangent":
			out[u] = ["true-false-reason"]
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	if not has(unknown):
		return []
	return [2] if unknown == "gdc-gradient" else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = GF.export(s)
	if not out.has("fillers"):
		out.fillers = []
	return out


static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func exact(v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, "")
	ans.show = "dec"
	ans.exact = true
	ans.signed = true
	return ans


static func pt(x: Variant, y: Variant) -> String:
	return Fmt.point(x, y)


## The window: x from a − 3 to a + 3, y around the curve and P's tangent there.
static func window(s: Dictionary, lines: Array = []) -> Array:
	var lo := float(s.a - GF.HALF)
	var hi := float(s.a + GF.HALF)
	var ylo := INF
	var yhi := -INF
	for p in GdcKit.curve(GF.fn(s), lo, hi):
		ylo = minf(ylo, p[1])
		yhi = maxf(yhi, p[1])
	for g: Q in lines:
		for x in [s.a - 2, s.a + 2]:
			var y: float = float(s.y0) + g.to_float() * (x - s.a)
			ylo = minf(ylo, y)
			yhi = maxf(yhi, y)
	ylo = maxf(ylo, -14.0)
	yhi = minf(yhi, 14.0)
	return [int(lo), int(hi), mini(floori(ylo) - 1, -1), maxi(ceili(yhi) + 1, 1)]


## The line through P with gradient g, across the window.
static func line(s: Dictionary, g: Q, win: Array) -> Array:
	var gf := g.to_float()
	return GdcKit.curve(func(x: float) -> float: return float(s.y0) + gf * (x - s.a), float(win[0]), float(win[1]))


## The curve on the grid with P marked, and the lines through P (each sand).
static func figure(s: Dictionary, lines: Array, points: Array, card: bool = false) -> Dictionary:
	var win := window(s, lines)
	var curves: Array = [GdcKit.curve(GF.fn(s), float(win[0]), float(win[1]))]
	for g: Q in lines:
		curves.append(line(s, g, win))
	var out := GdcKit.card(curves, points, win) if card else Plot.spec(curves, points, win[0], win[1], win[2], win[3])
	out.sand_from = 1
	return out


# ── A drawn tangent ──────────────────────────────────────────

func u_tangent_drawn(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m := Q.new(s.m)
	var x1: int = s.a - 2
	var x2: int = s.a + 2
	var y1: int = s.y0 - 2 * s.m
	var y2: int = s.y0 + 2 * s.m
	var ans := exact(m)
	var pts := [[float(s.a), float(s.y0), "P"], [float(x1), float(y1), pt(x1, y1)], [float(x2), float(y2), pt(x2, y2)]]
	var out := {"answer": ans, "graph": figure(s, [m], pts),
		"lines": ["The graph shows the curve y = f(x) and its tangent at P%s. The tangent runs through the grid points %s and %s." % [pt(s.a, s.y0), pt(x1, y1), pt(x2, y2)]],
		"asked": "Find the gradient of the curve at P."}
	out.wrongs = [wrong({"v": Q.new(s.y0)}, R_HEIGHT), wrong({"v": Q.new(s.y0, s.a)}, R_ORIGIN), wrong({"v": Q.new(1, s.m)}, R_RUN_RISE)]
	if s.m < 0:
		out.wrongs.append(wrong({"v": m.neg()}, R_NO_MINUS))
	out.fillers = [{"v": m.add(Q.new(1))}, {"v": m.sub(Q.new(1))}].filter(func(f): return not f.v.is_zero())
	out.methods = {"tangent-rise-run": method([
		"From %s to %s on the tangent, the rise is %s − %s = %s and the run is %s − %s = 4." % [pt(x1, y1), pt(x2, y2), N(y2), P(y1), N(4 * s.m), N(x2), P(x1)],
		"Gradient = rise ÷ run = %s ÷ 4 = %s." % [N(4 * s.m), N(m)],
		"So the gradient of the curve at P is %s." % Answer.text(ans)], ans.values)}
	return out


# ── A short chord from a table ───────────────────────────────

func u_chord_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var lo := Q.new(10 * s.a - 1, 10)
	var hi := Q.new(10 * s.a + 1, 10)
	var flo := GF.value(s, lo)
	var fhi := GF.value(s, hi)
	var rise := fhi.sub(flo)
	var est := rise.div(Q.new(1, 5))
	var ans := exact(est)
	var out := {"answer": ans, "table": {"rows": [["x", [D(lo), N(s.a), D(hi)]], ["f(x)", [D(flo), N(s.y0), D(fhi)]]]},
		"lines": ["The table gives values of f(x) near x = %s." % N(s.a)],
		"asked": "Estimate the gradient of the curve y = f(x) at x = %s, using the chord from x = %s to x = %s." % [N(s.a), D(lo), D(hi)]}
	out.wrongs = [wrong({"v": Q.new(s.y0)}, R_HEIGHT), wrong({"v": rise.div(Q.new(1, 10))}, R_HALF_RUN)]
	out.fillers = [{"v": est.add(Q.new(1))}, {"v": est.sub(Q.new(1))}]
	out.methods = {"symmetric-chord": method([
		"The chord joins (%s, %s) and (%s, %s), either side of x = %s." % [D(lo), D(flo), D(hi), D(fhi), N(s.a)],
		"Its rise is %s − %s = %s over a run of %s − %s = 0.2." % [D(fhi), P(D(flo)), D(rise), D(hi), D(lo)],
		"Gradient ≈ %s ÷ 0.2 = %s." % [D(rise), D(est)],
		"So the gradient at x = %s is about %s." % [N(s.a), Answer.text(ans)]], ans.values)}
	return out


# ── The GDC's gradient ───────────────────────────────────────

func u_gdc_gradient(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: String
	if s.family == "exp":
		f = DifferentiationViews.SUM([[1, "e^x"], [-s.b, "x²"], [s.d, ""]])
	else:
		f = DifferentiationViews.SUM([[s.c, "ln x"], [-s.b, "x"], [s.d, ""]]) + ", x > 0"
	var at := "%.1f" % s.a
	var ans := Answer.make("number", {"v": GdcKit.qf(s.fp)}, {}, "")
	ans.show = "sf"
	ans.signed = true
	var h := 0.001
	var diff: float = GF.fa_of(s, s.a + h) - GF.fa_of(s, s.a - h)
	var out := {"answer": ans, "lines": ["f(x) = " + f],
		"asked": "Find the gradient of the curve y = f(x) at x = %s." % at}
	out.wrongs = [wrong({"v": GdcKit.qf(s.fa)}, R_HEIGHT), wrong({"v": GdcKit.qf(s.fa / s.a)}, R_ORIGIN)]
	out.fillers = [{"v": GdcKit.qf(s.fp + 1.0)}, {"v": GdcKit.qf(s.fp - 1.0)}]
	out.methods = {
		"gdc-dydx": method(["Graph y = f(x) on the GDC and use dy/dx at x = %s." % at,
			"The GDC gives %s." % GdcKit.W(s.fp),
			"So the gradient at x = %s is %s." % [at, Answer.text(ans)]], ans.values),
		"symmetric-chord": method(["Use the GDC for f just either side of x = %s: f(%s) − f(%s) = %s." % [at, Fmt.dec(Q.new(roundi(s.a * 1000) + 1, 1000)), Fmt.dec(Q.new(roundi(s.a * 1000) - 1, 1000)), GdcKit.W(diff)],
			"The chord's run is 0.002, so its gradient is %s ÷ 0.002 = %s." % [GdcKit.W(diff), GdcKit.W(diff / (2.0 * h))],
			"So the gradient at x = %s is %s." % [at, Answer.text(ans)]], ans.values),
	}
	return out


# ── Two gradients compared ───────────────────────────────────

static func slopes_word(g: Q) -> String:
	return "rises" if g.sign() > 0 else "falls"


func u_compare_two(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ga := GF.slope(s, s.xa)
	var gb := GF.slope(s, s.xb)
	var ya := GF.value(s, s.xa)
	var yb := GF.value(s, s.xb)
	var big := "A" if gb.lt(ga) else "B"
	var small := "B" if big == "A" else "A"
	var high := "A" if yb.lt(ya) else "B"
	var right: String
	match s.way:
		"mixed":
			right = "%s, because the curve rises at %s and falls at %s" % [big, big, small]
		"up":
			right = "%s, because the curve rises more steeply at %s than at %s" % [big, big, small]
		_:
			right = "%s, because the curve falls less steeply at %s than at %s" % [big, big, small]
	var oa := ya.div(Q.new(s.xa))
	var ob := yb.div(Q.new(s.xb))
	var steep := "A" if ob.lt(oa) else "B"
	var tagged := [tag("%s, because %s is higher up the curve" % [high, high], R_HEIGHT),
		tag("%s, because the line from the origin to %s has the greater gradient" % [steep, steep], R_ORIGIN)]
	if s.way == "down":
		tagged.append(tag("%s, because the curve falls more steeply at %s" % [small, small], R_DOWNHILL))
	var out := {"graph": figure(s, [], [[float(s.xa), ya.to_float(), "A"], [float(s.xb), yb.to_float(), "B"]]),
		"lines": ["The graph shows the curve y = f(x), with the points A and B on it."],
		"asked": "At which point, A or B, is the gradient of the curve greater? Give a reason."}
	out.merge(pick(right, tagged, ["Neither: the gradients at A and B are equal"]))
	var at := func(p: String, g: Q) -> String:
		return "At %s the curve %s, so its gradient there is %s." % [p, slopes_word(g), "positive" if g.sign() > 0 else "negative"]
	var why: String
	match s.way:
		"mixed":
			why = "A positive gradient is greater than a negative one."
		"up":
			why = "Both are positive, and the tangent at %s is steeper, so its gradient is greater." % big
		_:
			why = "Both are negative, and the tangent at %s is less steep, so its gradient is nearer 0 and greater." % big
	out.methods = {"compare-steepness": method([at.call("A", ga), at.call("B", gb), why, right + "."], {"v": right})}
	return out


static func pick(right: String, tagged: Array, fillers: Array = []) -> Dictionary:
	var out := InverseRuleViews.choose(right, tagged, fillers)
	out.fillers = out.get("fillers", []) + out.get("generic", [])
	out.erase("generic")
	return out


static func tag(text: String, ref: String) -> Dictionary:
	return InverseRuleViews.tag(text, ref)


# ── Which graph shows the tangent ────────────────────────────

func u_pick_tangent(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var m := Q.new(s.m)
	var o := Q.new(s.y0, s.a)
	var h := Q.new(s.y0)
	var ch := GF.chord(s)
	var all := [m, o, h, ch]
	var P := [[float(s.a), float(s.y0), "P"]]
	# Every card shares one window, so the curve sits in the same place on each.
	var win := window(s, all)
	var cards := {}
	for g: Q in all:
		var c := GdcKit.card([GdcKit.curve(GF.fn(s), float(win[0]), float(win[1])), line(s, g, win)], P, win)
		c.sand_from = 1
		cards[g.key()] = c
	var wrongs := [
		ConcavityViews.one_wrong(cards[o.key()], "origin", R_ORIGIN, "its line runs from the origin to P, so it is not the tangent"),
		ConcavityViews.one_wrong(cards[h.key()], "height", R_HEIGHT, "its line has gradient %s, the y-coordinate of P" % N(s.y0)),
		ConcavityViews.one_wrong(cards[ch.key()], "chord", R_CHORD, "its line joins P to another point of the curve and cuts it there")]
	var pk := GdcKit.pick(cards[m.key()], wrongs, rng)
	var ans: Dictionary = pk.answer
	var x1: int = s.a - 2
	var x2: int = s.a + 2
	var out := {"answer": ans, "graphs": pk.graphs, "graph": figure(s, [], P),
		"lines": ["The graph shows the curve y = f(x) and the point P%s on it." % pt(s.a, s.y0)],
		"asked": "Which graph shows the tangent to the curve at P?"}
	out.methods = {"tangent-rise-run": method([
		"The tangent at P touches the curve at P and runs the way the curve runs there, without cutting it.",
		"In %s the line through P runs from %s to %s: a rise of %s over a run of 4, a gradient of %s, as steep as the curve at P." % [pk.letter, pt(x1, s.y0 - 2 * s.m), pt(x2, s.y0 + 2 * s.m), N(4 * s.m), N(m)],
		"So the answer is %s." % Answer.text(ans)], ans.values)}
	return out
