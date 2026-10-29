class_name SymmetryViews
extends ExtensionViews
## The views on the `fn-link-symmetry` situation: one builder per unknown of
## fn-link-symmetry (FAL-459). find-the-mirror's context hangs on its method (the
## roots of a parabola, an equal pair, or nCr), so the builders read `angle`. Every
## unknown also plays as true-false-reason.

const TFR := ["true-false-reason"]

## Facts that use the mirror idea, by topic, and facts that don't.
const MIRRORS := {
	"normal": "For X ~ N(μ, σ²), P(X < μ − a) = P(X > μ + a)",
	"trig": "sin(π − θ) = sin θ",
	"ncr": "nCr = nC(n − r)",
}
const NOT_MIRRORS := ["The terms of an arithmetic sequence go up by the same amount each time", "log(ab) = log a + log b",
	"A line has the same gradient between any two of its points", "e^(a + b) = e^a × e^b", "The angles of a triangle add up to π"]


func needs() -> Dictionary:
	return {
		"same-idea": {"form": "idea"},
		"mirror-point": {"form": "parabola"},
		"find-the-mirror": {"form": "mirror"},
		"normal-middle": {"form": "normal"},
		"normal-other-tail": {"form": "normal"},
		"central-interval": {"form": "normal", "central": true},
		"related-angle": {"form": "angle"},
		"ncr-mirror": {"form": "ncr"},
	}


func extra() -> Dictionary:
	var out := {}
	for u in needs():
		out[u] = TFR
	return out


# ── Helpers ──────────────────────────────────────────────────

static func curve(p: Dictionary) -> String:
	return Fmt.vertex(p.a, p.h, p.k)


static func general(p: Dictionary) -> String:
	return Fmt.general(p.a, p.a.mul(p.h).mul(-2), p.a.mul(p.h.sq()).add(p.k))


static func at(p: Dictionary, x: Q) -> Q:
	return p.a.mul(x.sub(p.h).sq()).add(p.k)


## A parabola to draw (GraphView), with the given points labelled.
static func parabola_graph(p: Dictionary, points: Array, axis: bool) -> Dictionary:
	var xs: Array = [p.h.to_float() - 4.0, p.h.to_float() + 4.0, 0.0]
	var ys: Array = [p.k.to_float(), 0.0]
	var pts: Array = []
	for pt in points:
		xs.append(pt[0].to_float())
		ys.append(pt[1].to_float())
		pts.append({"x": pt[0].to_float(), "y": pt[1].to_float(), "label": Fmt.point(pt[0], pt[1])})
	return {"a": p.a.to_float(), "h": p.h.to_float(), "k": p.k.to_float(), "points": pts, "axis": p.h.to_float() if axis else null,
		"axis_label": "x = " + N(p.h) if axis else "", "x0": floori(xs.min()) - 1, "x1": ceili(xs.max()) + 1,
		"y0": floori(ys.min()) - 2, "y1": ceili(ys.max()) + 2, "caption": ""}


## The normal curve, drawn with the σ that makes each tail beyond μ ± a the given p,
## so the picture matches the numbers (the question itself leaves σ unknown).
static func normal_graph(s: Dictionary, shade: Array) -> Dictionary:
	var mu: float = s.mu.to_float()
	var a: float = s.a.to_float()
	var sg: float = a / SymmetrySituation.inv_norm(1.0 - s.p.to_float())
	return {"kind": "normal", "mu": mu, "sigma": sg, "x0": mu - 4 * sg, "x1": mu + 4 * sg, "shade": shade,
		"marks": [{"at": mu - a, "label": N(s.mu.sub(s.a))}, {"at": mu, "label": N(s.mu)}, {"at": mu + a, "label": N(s.mu.add(s.a))}]}


## The distribution as a tail question gives it: σ is not needed, and not given.
static func dist(s: Dictionary) -> String:
	return "X ~ N(%s, σ²)" % N(s.mu)


# ── same-idea ────────────────────────────────────────────────

func u_same_idea(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var topic: String = {"graph-symmetry": "trig", "shaded-sketch": "normal"}.get(angle, s.fact)
	var right: String = MIRRORS[topic]
	var nots: Array = rng.shuffled(NOT_MIRRORS).slice(0, 3)
	var ans := Answer.make("choice", {"v": right}, {"options": [right] + nots})
	var final := "So: %s." % Answer.text(ans)
	var why: String = {"normal": "the normal curve is symmetric about μ: μ − a and μ + a are the same distance either side, so the tails match",
		"trig": "on the unit circle θ and π − θ are mirror images in the y-axis, so they have the same sine",
		"ncr": "choosing r things to take is choosing n − r to leave, so row n of Pascal's triangle reads the same both ways"}[topic]
	var steps := {
		"midpoint-of-roots": ["The parabola's two roots are the same distance either side of the axis, so the vertex is halfway", "The same mirror: " + why, final],
		"graph-symmetry": ["The graph of sin x on [0, π] is symmetric about x = π/2, as a parabola is about its axis", "So " + why, final],
		"shaded-sketch": ["Sketch the normal curve and shade both tails: the picture is symmetric about μ, as a parabola is about its axis", "So " + why, final],
	}
	return {"asked": "The vertex of a parabola is halfway between its roots. Which of these uses the same mirror idea?",
		"lines": ["A parabola is symmetric about its axis: matching points sit the same distance either side."], "given": {"topic": topic, "options": [right] + nots},
		"answer": ans, "generic": nots.map(func(o): return {"v": o}),
		"methods": steps.keys().reduce(func(acc, k): acc[k] = method(steps[k], ans.values); return acc, {})}


# ── mirror-point ─────────────────────────────────────────────

func u_mirror_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x1: Q = s.h.sub(s.d)
	var x2: Q = s.h.add(s.d)
	var ans := Answer.make("point", {"x": x2, "y": s.y})
	var final := "So %s." % Answer.text(ans)
	var out := {"asked": "Find the matching point on the other side of the axis.", "given": export(s), "answer": ans,
		"lines": ["The parabola y = %s has its axis of symmetry at x = %s and passes through %s." % [general(s), N(s.h), Fmt.point(x1, s.y)]]}
	if rep == "graph":
		out.graph = parabola_graph(s, [[x1, s.y]], true)
		out.lines = ["The graph shows a parabola with its axis of symmetry x = %s and the point %s." % [N(s.h), Fmt.point(x1, s.y)]]
	elif rep == "table":
		var xs: Array = []
		for i in range(-s.d.n - 1, 1):
			xs.append(s.h.add(i))
		out.table = {"xs": xs, "ys": xs.map(func(x): return at(s, x)), "heads": ["x", "y"]}
		out.lines = ["The table gives points on a parabola up to its axis, x = %s." % N(s.h)]
	out.methods = {
		"midpoint-of-roots": method(["Matching points are the same distance either side of the axis: %s = (%s + x)/2" % [N(s.h), N(x1)],
			"x = 2 × %s − %s = %s, at the same height %s" % [P(s.h), P(x1), N(x2), N(s.y)], final], ans.values),
		"reflect-point": method(["%s is %s to the left of x = %s" % [Fmt.point(x1, s.y), N(s.d), N(s.h)],
			"Its mirror image is %s to the right: x = %s + %s = %s" % [N(s.d), N(s.h), N(s.d), N(x2)], final], ans.values),
	}
	out.wrongs = [wrong({"x": x1.neg(), "y": s.y}, "SL2.4.symmetry#0"), wrong({"x": s.h, "y": s.y}, "SL2.4.symmetry#1"),
		wrong({"x": s.h.add(s.d.mul(2)), "y": s.y}, "SL2.4.symmetry#1")]
	out.generic = [{"x": x2, "y": s.y.neg()}, {"x": x1, "y": s.y.neg()}]
	return out


# ── find-the-mirror ──────────────────────────────────────────

func u_find_the_mirror(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	if angle == "symmetry":
		return _mirror_ncr(rep, s.ncr)
	if angle == "midpoint-of-pair" and rep == "words":
		return _mirror_normal(s.normal)
	var p: Dictionary = s.parabola
	var roots := angle == "midpoint-of-roots"
	var xa: Q = p.r1 if roots else p.x1
	var xb: Q = p.r2 if roots else p.x2
	var yv: Q = Q.new(0) if roots else p.y2
	var ans := Answer.make("axis", {"var": "x", "h": p.h})
	var final := "So %s." % Answer.text(ans)
	var said := "y = 0 at x = %s and at x = %s" % [N(xa), N(xb)] if roots else "y = %s at x = %s and at x = %s" % [N(yv), N(xa), N(xb)]
	var out := {"asked": "Find the axis of symmetry of the parabola.", "given": export(p).merged({"xa": xa.key(), "xb": xb.key(), "yv": yv.key()}), "answer": ans,
		"lines": ["A parabola has %s." % said]}
	if rep == "graph":
		out.graph = parabola_graph(p, [[xa, yv], [xb, yv]], false)
		out.lines = ["The graph shows a parabola through %s and %s." % [Fmt.point(xa, yv), Fmt.point(xb, yv)]]
	elif rep == "table":
		var xs: Array = []
		for i in range(xa.n - 1, xb.n + 2):
			xs.append(Q.new(i))
		out.table = {"xs": xs, "ys": xs.map(func(x): return at(p, x)), "heads": ["x", "y"]}
		out.lines = ["The table gives points on a parabola."]
	var mid := "x = (%s + %s)/2 = %s" % [N(xa), N(xb), N(p.h)]
	var first := "The roots are x = %s and x = %s; the axis is halfway between them" % [N(xa), N(xb)] if roots \
		else "The parabola is a mirror about its axis: like its roots, any two points at one height sit the same distance either side"
	out.methods = {
		"midpoint-of-roots": method([first, mid, final], ans.values),
		"midpoint-of-pair": method(["x = %s and x = %s give the same y, %s, so they are mirror images" % [N(xa), N(xb), N(yv)], mid, final], ans.values),
		"symmetry": method(["As nCr = nC(n − r) puts equal values of a row either side of its middle, equal values of y sit either side of the axis", mid, final], ans.values),
	}
	out.wrongs = [wrong({"var": "y", "h": p.h}, "SL2.6.axis-symmetry#1")]
	out.generic = [{"var": "x", "h": p.k}, {"var": "x", "h": xb.sub(xa)}, {"var": "x", "h": p.h.neg()}, {"var": "x", "h": xa.add(xb)}]
	return out


func _mirror_ncr(rep: String, c: Dictionary) -> Dictionary:
	var n: int = c.n.n
	var r: int = c.r.n
	var ans := Answer.make("number", {"v": c.n}, {}, "n = ")
	ans.exact = true
	var out := {"asked": "Find n.", "given": export(c).merged({"ctx": "ncr"}), "answer": ans,
		"lines": ["nC%d = nC%d, and %d ≠ %d." % [r, n - r, r, n - r]]}
	if rep == "table":
		out.table = {"rows": [["r", [str(r), str(n - r)]], ["nCr", [str(c.value.n), str(c.value.n)]]]}
		out.lines = ["The table gives two values of nCr from one row of Pascal's triangle."]
	elif rep == "graph":
		var xs: Array = range(0, n + 1)
		out.graph = {"kind": "bars", "xs": xs, "ys": xs.map(func(k): return SymmetrySituation.ncr(n, k)), "hide": []}
		out.lines = ["The bar chart shows one row of Pascal's triangle, nCr for r = 0, 1, 2, …"]
	var pair := "r = %d and r = %d give the same value" % [r, n - r]
	if rep == "graph":
		pair = "The bars are symmetric: r = %d and r = %d are mirror images, both %d" % [r, n - r, c.value.n]
	var sum := "The mirror is the middle of the row, r = n/2 = (%d + %d)/2, so n = %d + %d" % [r, n - r, r, n - r]
	out.methods = {
		"symmetry": method([pair + ", so they are mirror images: nCr = nC(n − r)", "r + (n − r) = n, so n = %d + %d" % [r, n - r], "So %s." % Answer.text(ans)], ans.values),
		"midpoint-of-pair": method(["r = %d and r = %d give the same value: a mirror pair" % [r, n - r], sum, "So %s." % Answer.text(ans)], ans.values),
		"midpoint-of-roots": method(["As a parabola's roots sit either side of its axis, the two equal values sit either side of the middle of the row", sum, "So %s." % Answer.text(ans)], ans.values),
	}
	out.generic = [{"v": Q.new((n) / 2)}, {"v": Q.new(absi(n - 2 * r))}, {"v": Q.new(n + 1)}, {"v": Q.new(n - 1)}]
	return out


func _mirror_normal(nm: Dictionary) -> Dictionary:
	var lo: Q = nm.mu.sub(nm.a)
	var hi: Q = nm.mu.add(nm.a)
	var ans := Answer.make("number", {"v": nm.mu}, {}, "μ = ")
	ans.exact = true
	return {"asked": "Find μ.", "given": export(nm).merged({"ctx": "normal"}), "answer": ans,
		"lines": ["X ~ N(μ, σ²) and P(X < %s) = P(X > %s)." % [N(lo), N(hi)]],
		"methods": {
			"midpoint-of-pair": method(["Equal tails sit the same distance either side of the mean", "μ = (%s + %s)/2 = %s" % [N(lo), N(hi), N(nm.mu)], "So %s." % Answer.text(ans)], ans.values),
			"midpoint-of-roots": method(["As a parabola's roots sit either side of its axis, equal tails sit either side of the mean", "μ = (%s + %s)/2 = %s" % [N(lo), N(hi), N(nm.mu)], "So %s." % Answer.text(ans)], ans.values),
			"symmetry": method(["As nCr = nC(n − r) mirrors a row about its middle, the normal curve mirrors about μ", "μ = (%s + %s)/2 = %s" % [N(lo), N(hi), N(nm.mu)], "So %s." % Answer.text(ans)], ans.values),
		},
		"generic": [{"v": hi.sub(lo)}, {"v": lo}, {"v": hi}, {"v": lo.add(hi)}]}


# ── normal-middle and normal-other-tail ──────────────────────

func u_normal_middle(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var hi: Q = s.mu.add(s.a)
	var lo: Q = s.mu.sub(s.a)
	var mid: Q = Q.new(1).sub(s.p.mul(2))
	var ans := Answer.make("number", {"v": mid})
	ans.show = "dec"
	var final := "So %s." % Answer.text(ans)
	var out := {"asked": "Find P(%s < X < %s)." % [N(lo), N(hi)], "given": export(s), "answer": ans,
		"lines": ["%s and P(X > %s) = %s." % [dist(s), N(hi), Fmt.dec(s.p)]]}
	if rep == "graph":
		out.graph = normal_graph(s, [[hi.to_float(), null]])
		out.lines = ["%s. The shaded area, P(X > %s), is %s." % [dist(s), N(hi), Fmt.dec(s.p)]]
	var mirror := "%s and %s are both %s from the mean %s, so P(X < %s) = P(X > %s) = %s" % [N(lo), N(hi), N(s.a), N(s.mu), N(lo), N(hi), Fmt.dec(s.p)]
	out.methods = {
		"mirror-tails": method([mirror, "The middle is what the two tails leave: 1 − 2 × %s = %s" % [Fmt.dec(s.p), Fmt.dec(mid)], final], ans.values),
		"area-bookkeeping": method(["The whole area is 1: P(X < %s) + P(%s < X < %s) + P(X > %s) = 1" % [N(lo), N(lo), N(hi), N(hi)], mirror,
			"1 − %s − %s = %s" % [Fmt.dec(s.p), Fmt.dec(s.p), Fmt.dec(mid)], final], ans.values),
		"shaded-sketch": method(["Sketch: shade the tail beyond %s, then its mirror below %s; each is %s" % [N(hi), N(lo), Fmt.dec(s.p)],
			"The unshaded middle is 1 − %s = %s" % [Fmt.dec(s.p.mul(2)), Fmt.dec(mid)], final], ans.values),
	}
	out.wrongs = [wrong({"v": s.p.mul(2)}, "SL4.9.symmetry-probability#0")]
	out.generic = [{"v": Q.new(1).sub(s.p)}, {"v": Q.new(1, 2).sub(s.p)}, {"v": s.p}]
	return out


func u_normal_other_tail(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var hi: Q = s.mu.add(s.a)
	var lo: Q = s.mu.sub(s.a)
	var below: Q = Q.new(1).sub(s.p)
	var ans := Answer.make("named", {"v0": s.p, "v1": below}, {"names": ["P(X > %s)" % N(hi), "P(X < %s)" % N(hi)]})
	ans.show = "dec"
	var final := "So %s." % Answer.text(ans)
	var out := {"asked": "Find P(X > %s) and P(X < %s)." % [N(hi), N(hi)], "given": export(s), "answer": ans,
		"lines": ["%s and P(X < %s) = %s." % [dist(s), N(lo), Fmt.dec(s.p)]]}
	if rep == "graph":
		out.graph = normal_graph(s, [[null, lo.to_float()]])
		out.lines = ["%s. The shaded area, P(X < %s), is %s." % [dist(s), N(lo), Fmt.dec(s.p)]]
	var mirror := "%s and %s are both %s from the mean, so P(X > %s) = P(X < %s) = %s" % [N(lo), N(hi), N(s.a), N(hi), N(lo), Fmt.dec(s.p)]
	out.methods = {
		"mirror-tails": method([mirror, "P(X < %s) = 1 − P(X > %s) = 1 − %s = %s" % [N(hi), N(hi), Fmt.dec(s.p), Fmt.dec(below)], final], ans.values),
		"area-bookkeeping": method(["P(X < %s) = 0.5, the half below the mean" % N(s.mu), mirror,
			"P(X < %s) = 0.5 + (0.5 − %s) = %s" % [N(hi), Fmt.dec(s.p), Fmt.dec(below)], final], ans.values),
	}
	out.wrongs = [wrong({"v0": s.p, "v1": s.p.add(Q.new(1, 2))}, "SL4.9.symmetry-probability#1")]
	out.generic = [{"v0": below, "v1": s.p}, {"v0": s.p, "v1": Q.new(1, 2).sub(s.p)}, {"v0": s.p.mul(2), "v1": Q.new(1).sub(s.p.mul(2))}]
	return out


# ── central-interval ─────────────────────────────────────────

func u_central_interval(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("named", {"v0": s.lo, "v1": s.hi}, {"names": ["a", "b"]})
	ans.show = "sf"
	var final := "So %s." % Answer.text(ans)
	var tail: Q = Q.new(1).sub(s.q).div(2)
	var half: Q = s.z.mul(s.sigma)
	var steps_split := ["The interval is symmetric about %s, so each tail is (1 − %s)/2 = %s" % [N(s.mu), Fmt.dec(s.q), Fmt.dec(tail)],
		"b has %s above it: b = invNorm(%s, %s, %s) = %s, so the half-width is %s" % [Fmt.dec(tail), Fmt.dec(Q.new(1).sub(tail)), N(s.mu), N(s.sigma), Fmt.sf(s.hi), Fmt.sf(half)],
		"a is the same distance below: a = %s − %s = %s" % [N(s.mu), Fmt.sf(half), Fmt.sf(s.lo)], final]
	var steps_gdc := ["On the GDC, invNorm with area %s, μ = %s, σ = %s and the tail set to centre" % [Fmt.dec(s.q), N(s.mu), N(s.sigma)],
		"It gives %s and %s" % [Fmt.sf(s.lo), Fmt.sf(s.hi)], final]
	return {"asked": "Find a and b, symmetric about the mean, with P(a < X < b) = %s." % Fmt.dec(s.q), "given": export(s), "answer": ans,
		"lines": ["X ~ N(%s, %s²)." % [N(s.mu), N(s.sigma)]],
		"methods": {"split-tails": method(steps_split, ans.values), "gdc-center": method(steps_gdc, ans.values)},
		"wrongs": [wrong({"v0": s.wlo, "v1": s.whi}, "SL4.9.central-interval#0")],
		"generic": [{"v0": s.mu.sub(s.sigma), "v1": s.mu.add(s.sigma)}, {"v0": s.mu.sub(half.div(2)), "v1": s.mu.add(half.div(2))},
			{"v0": s.mu.sub(half.mul(2)), "v1": s.mu.add(half.mul(2))}]}


# ── related-angle ────────────────────────────────────────────

func u_related_angle(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: Q = s.theta
	var sin_fn: bool = s.fn == "sin"
	var same: Q = Q.new(1).sub(t) if sin_fn else Q.new(2).sub(t)
	var o1: Q = Q.new(1).add(t)
	var o2: Q = Q.new(2).sub(t) if sin_fn else Q.new(1).sub(t)
	var ans := Answer.make("related", {"s": same, "o1": o1, "o2": o2})
	var final := "So %s." % Answer.text(ans)
	var val := SymmetrySituation.exact_value(s.fn, t)
	var out := {"asked": "Find the other angle in [0, 2π] with the same %s, and the two angles whose %s is −%s." % [s.fn, s.fn, val],
		"given": export(s), "answer": ans, "lines": ["%s(%s) = %s" % [s.fn, Fmt.pi(t), val]]}
	if rep == "words":
		out.lines = ["The first-quadrant angle θ = %s has %s θ = %s." % [Fmt.pi(t), s.fn, val]]
	elif rep == "graph":
		var y: float = sin(t.to_float() * PI) if sin_fn else cos(t.to_float() * PI)
		out.graph = {"kind": "trig", "fn": s.fn, "line": y, "points": [{"x": t.to_float() * PI, "y": y, "label": Fmt.pi(t)}]}
		out.lines = ["The graph of y = %s x for 0 ≤ x ≤ 2π, with the line y = %s through x = %s." % [s.fn, val, Fmt.pi(t)]]
	var mirror := "sin is symmetric about π/2 on [0, π]: π − θ = %s" % Fmt.pi(same) if sin_fn else "cos is symmetric about π on [0, 2π]: 2π − θ = %s" % Fmt.pi(same)
	var neg := "−%s: %s is negative in quadrants %s, at π + θ = %s and %s = %s" % [val, s.fn, "3 and 4" if sin_fn else "2 and 3", Fmt.pi(o1), "2π − θ" if sin_fn else "π − θ", Fmt.pi(o2)]
	out.methods = {
		"unit-circle-reflection": method(["On the unit circle, %s is the %s of the point at angle θ = %s" % [s.fn, "height" if sin_fn else "across-distance", Fmt.pi(t)],
			"Reflect it in the %s: the same %s at %s" % ["y-axis" if sin_fn else "x-axis", s.fn, Fmt.pi(same)], "The opposite sign, " + neg, final], ans.values),
		"graph-symmetry": method(["On the graph of y = %s x, %s" % [s.fn, mirror], "The graph is below the axis by the same amount for " + neg, final], ans.values),
	}
	out.wrongs = [wrong({"s": o1, "o1": same, "o2": o2}, "SL3.5.related-angles#0"), wrong({"s": Q.new(1, 2).add(t), "o1": o1, "o2": o2}, "SL3.5.related-angles#1")]
	# Slips that keep three different angles: a quadrant off for one of them.
	var gen: Array = [{"s": same, "o1": o1.add(Q.new(1, 2)), "o2": o2}, {"s": same, "o1": o1, "o2": o2.sub(Q.new(1, 2))},
		{"s": Q.new(2).sub(t) if sin_fn else Q.new(1).sub(t), "o1": o1, "o2": Q.new(1).sub(t) if sin_fn else Q.new(2).sub(t)}, {"s": same.add(Q.new(1, 2)), "o1": o1, "o2": o2}]
	out.generic = gen.filter(func(g): return not g.o1.eq(g.o2) and not g.s.eq(g.o1) and not g.s.eq(g.o2) and not Q.new(2).lt(g.o1) and not Q.new(2).lt(g.o2) and not Q.new(2).lt(g.s))
	return out


# ── ncr-mirror ───────────────────────────────────────────────

func u_ncr_mirror(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n.n
	var r: int = s.r.n
	var ans := Answer.make("named", {"v0": Q.new(n - r), "v1": s.value}, {"names": ["r", "value"]})
	ans.exact = true
	var final := "So %s." % Answer.text(ans)
	var fact := func(k: int) -> int:
		var out := 1
		for i in range(2, k + 1):
			out *= i
		return out
	return {"asked": "Find the other r with nCr = %dC%d, and that value." % [n, r], "given": export(s), "answer": ans,
		"lines": ["%dC%d = %dCr, with r ≠ %d" % [n, r, n, r]],
		"methods": {
			"symmetry": method(["Choosing %d to take is choosing %d to leave, so %dC%d = %dC%d" % [r, n - r, n, r, n, n - r],
				"%dC%d = %d!/(%d! × %d!) = %d" % [n, r, n, r, n - r, s.value.n], final], ans.values),
			"factorial-formula": method(["%dC%d = %d!/(%d! × %d!) = %d" % [n, r, n, r, n - r, s.value.n],
				"Try r = %d: %dC%d = %d!/(%d! × %d!) = %d, the same" % [n - r, n, n - r, n, n - r, r, s.value.n], final], ans.values),
		},
		"wrongs": [wrong({"v0": Q.new(n - r), "v1": Q.new(fact.call(n) / fact.call(r))}, "SL1.9.ncr-pascal#0")],
		"generic": [{"v0": Q.new(n - r - 1), "v1": s.value}, {"v0": Q.new(r + 1), "v1": Q.new(SymmetrySituation.ncr(n, r + 1))}, {"v0": Q.new(n - r), "v1": s.value.mul(2)}]}
