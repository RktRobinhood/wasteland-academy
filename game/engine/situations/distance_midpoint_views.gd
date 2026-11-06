class_name DistanceMidpointViews
extends ExtensionViews
## The views on the `distance-midpoint` situation: one builder per unknown of t3-distance-midpoint
## (FAL-751). A length is exact on Paper 1, a `form` answer with its surd typed, and a `number` to
## 3 s.f. on Paper 2 with the rounding trap. A point is a `form` answer with a slot per coordinate.
## Paper 1 writes a half as a fraction, and Paper 2 writes coordinates as decimals.
##
## Representations: "equation" (the points in a sentence), "notation" (position vectors a, b) and
## "diagram" (PlotView's `space`: the points on axes, with their coordinates on the figure, or a
## round solid with no axes). Every sentence writes a point as A(1, −2, 3), which the checker reads back.

const SKILL_D := "SL3.1.distance-3d#"
const SKILL_M := "SL3.1.midpoint-3d#"
const TYPE := "t3-distance-midpoint#"
const R_SUM := SKILL_D + "0"
const R_NEGATIVE := SKILL_D + "1"
const R_ONE_K := SKILL_D + "2"
const R_SUBTRACT := SKILL_M + "0"
const R_AVERAGED := SKILL_M + "1"
const R_HALVED := SKILL_M + "2"
## The type's own slips: an index into its misconceptions.
const R_NO_ROOT := TYPE + "6"
const R_ADD_COORDS := TYPE + "7"
const R_DROP_Z := TYPE + "8"
const R_WHOLE_BASE := TYPE + "9"
const R_DIAMETER := TYPE + "10"
const R_DOUBLED := TYPE + "11"
const R_NO_REST := TYPE + "12"
const R_K_SIGN := TYPE + "13"
const R_K_SQUARE := TYPE + "14"
const R_WRONG_PAIR := TYPE + "15"
const R_THIRD := TYPE + "16"
const R_NO_HALF := TYPE + "17"
const R_MID_SIGN := TYPE + "18"
const R_STEP_ONLY := TYPE + "19"
const R_DOUBLE_M := TYPE + "20"
const R_ADD_A := TYPE + "21"
const R_PLAIN_SUM := TYPE + "22"
const R_F_ONLY := TYPE + "23"
const R_TAKE_SQUARES := TYPE + "24"
const R_SUM_2D := TYPE + "25"

const UNKNOWNS := ["distance-two-points", "distance-2d", "find-k-two-values", "find-k-surd", "show-isosceles", "space-diagonal",
	"pyramid-edge", "radius-from-centre", "radius-from-diameter", "origin-to-curve", "midpoint-3d", "midpoint-2d", "missing-endpoint",
	"missing-endpoint-2d", "centre-from-diameter"]
## Asked by hand, as an exact answer or a statement: a measure to round doesn't fit them.
const PAPER_1 := ["show-isosceles", "origin-to-curve"]

## The stories: two things on a plan, a thing that runs straight, and things in a shape.
const SPOTS := [["a beacon", "a pump"], ["a drone dock", "a water tank"], ["a watchtower lamp", "a radio dish"], ["a winch", "a crane hook"],
	["a flare stand", "a bunker hatch"], ["a solar mast", "a cable anchor"]]
const RUNS := ["A cable", "A pipe", "A rope bridge", "A fuel line", "A zip line", "A power line"]
const THREE := ["Three marker posts", "Three scrap towers", "Three radio masts", "Three rain tanks", "Three signal lamps", "Three camp gates"]
const CRATES := ["A storage crate", "A cargo container", "A water cistern", "A steel locker", "A grain bin", "A battery case"]
const STONES := ["A marker stone", "A brass weight", "A filter cap", "A foundry block", "A lamp top", "A trader's counterweight"]
const BALLS := ["A signal buoy's core", "A well float", "A drone's sensor pod", "A lead weight", "A filter ball", "A mill bearing"]
const DOMES := ["A sensor dome", "A scrap-metal cap", "A lamp cover", "A cast-iron mould", "A well stopper", "A lead sinker"]
const HATCHES := ["A round hatch", "A vent cover", "A solar disc", "A filter plate", "A steel door", "An access panel"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	if not has(unknown):
		return []
	return [1] if unknown in PAPER_1 else [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = DistanceMidpointSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

## A coordinate as the paper writes it: 5/2 on Paper 1, 2.5 on Paper 2.
static func C(s: Dictionary, v: Variant) -> String:
	return Fmt.dec(v) if s.paper == 2 else N(v)


## A coordinate in a sum: −3 in brackets.
static func B(s: Dictionary, v: Variant) -> String:
	return "(%s)" % C(s, v) if Q.of(v).sign() < 0 else C(s, v)


static func pt(s: Dictionary, p: Array) -> String:
	return "(%s)" % ", ".join(p.map(func(v): return C(s, v)))


static func named(s: Dictionary, name: String, p: Array) -> String:
	return name + pt(s, p)


static func vec_name(name: String) -> String:
	return name.to_lower()


static func axis_name(i: int) -> String:
	return ["x", "y", "z"][i]


## "√61", "6√2" or "13" for the root of n.
static func root_text(n: int) -> String:
	var sv := DistanceMidpointSituation.surd(n)
	return Answer.surd_text(sv[0], sv[1])


# ── Answers ──────────────────────────────────────────────────

## The answer "label = √n": exact on Paper 1, with what is typed depending on the surd.
static func length_ans(s: Dictionary, label: String, n: int) -> Dictionary:
	if s.paper == 2:
		return decimal_ans(label, sqrt(float(n)))
	var sv := DistanceMidpointSituation.surd(n)
	var text := label + " = " + root_text(n)
	var head := label + " = "
	var ans: Dictionary
	if sv[1] == 1:
		ans = Answer.make("form", {"v": Q.new(sv[0]), "text": text}, {"parts": [head, {"slot": "v"}]})
	elif sv[0] == 1:
		ans = Answer.make("form", {"r": Q.new(sv[1]), "text": text}, {"parts": [head + "√", {"slot": "r"}]})
	else:
		ans = Answer.make("form", {"m": Q.new(sv[0]), "r": Q.new(sv[1]), "text": text}, {"parts": [head, {"slot": "m"}, "√", {"slot": "r"}]})
	ans.exact = true
	return ans


static func decimal_ans(label: String, x: float) -> Dictionary:
	var ans := Answer.make("number", {"v": GdcKit.qf(x)}, {}, label + " = ")
	ans.show = "sf"
	return ans


## A wrong length whose square is n, written as the answer writes its own.
static func length_wrong(s: Dictionary, label: String, n: int, ref: String = "") -> Dictionary:
	return wrong(length_values(s, label, n), ref)


static func length_values(s: Dictionary, label: String, n: int) -> Dictionary:
	if s.paper == 2:
		return {"v": GdcKit.qf(sqrt(float(n)))}
	return {"text": label + " = " + root_text(n), "shape": "other"}


static func point_ans(s: Dictionary, p: Array) -> Dictionary:
	var parts: Array = ["("]
	var vals := point_values(s, p)
	for i in p.size():
		parts.append({"slot": axis_name(i)})
		parts.append(", " if i < p.size() - 1 else ")")
	var ans := Answer.make("form", vals, {"parts": parts})
	ans.exact = true
	return ans


static func point_values(s: Dictionary, p: Array) -> Dictionary:
	var vals := {"text": pt(s, p)}
	for i in p.size():
		vals[axis_name(i)] = p[i]
	return vals


static func point_wrong(s: Dictionary, p: Array, ref: String = "") -> Dictionary:
	return wrong(point_values(s, p), ref)


## Other points near the answer, one coordinate off.
static func near_points(s: Dictionary, p: Array) -> Array:
	var out: Array = []
	var nudge := Q.new(1) if s.paper == 1 else Q.new(1, 2)
	for k in [1, -1, 2, -2]:
		for i in p.size():
			var q := p.duplicate()
			q[(i + (0 if k > 0 else 1)) % p.size()] = p[(i + (0 if k > 0 else 1)) % p.size()].add(nudge.mul(k))
			out.append(point_values(s, q))
	return out


# ── Figures ──────────────────────────────────────────────────

static func plain(p: Array) -> Array:
	return p.map(func(v): return v.to_float())


static func line(a: String, b: String, dash: bool = false, asked: bool = false) -> Dictionary:
	return {"a": a, "b": b, "dash": dash, "asked": asked, "label": ""}


## The points on axes. pts: name -> coordinates; shown: name -> its label.
static func figure(s: Dictionary, pts: Dictionary, shown: Dictionary, lines: Array) -> Dictionary:
	var out := {"kind": "space", "dim": s.dim, "axes": true, "pts": {}, "labels": shown, "lines": lines}
	for n in pts:
		out.pts[n] = plain(pts[n])
	return out


## Two points with the box or the right angle between them, dashed: the moves along each axis.
static func pair_figure(s: Dictionary) -> Dictionary:
	var a: Array = s.A
	var b: Array = s.B
	var n: Array = s.names
	var pts := {n[0]: a, n[1]: b}
	var lines: Array = [line(n[0], n[1], false, true)]
	if s.dim == 2:
		pts["_c"] = [b[0], a[1]]
		lines.append_array([line(n[0], "_c", true), line("_c", n[1], true)])
	else:
		for mask in 8:
			pts["_%d" % mask] = [b[0] if mask & 1 else a[0], b[1] if mask & 2 else a[1], b[2] if mask & 4 else a[2]]
		for mask in 8:
			for bit in [1, 2, 4]:
				if mask & bit == 0:
					lines.append(line("_%d" % mask, "_%d" % (mask | bit), true))
	return figure(s, pts, {n[0]: named(s, n[0], a), n[1]: named(s, n[1], b)}, lines)


## A sphere, a hemisphere or a circle, drawn flat with no axes: `at` the centre, `edge` on it.
static func ball_figure(s: Dictionary, pts: Dictionary, shown: Dictionary, lines: Array, at: String, edge: String) -> Dictionary:
	return {"kind": "space", "dim": 2, "axes": false, "pts": pts, "labels": shown, "lines": lines,
		"ball": {"at": at, "through": edge, "shape": s.shape}}


static func on_circle(deg: float) -> Array:
	return [cos(deg_to_rad(deg)), sin(deg_to_rad(deg))]


# ── Working ──────────────────────────────────────────────────

## The moves from a to b, whole numbers.
static func moves(s: Dictionary) -> Array:
	return DistanceMidpointSituation.minus(s.B, s.A)


## "x: 4 − 1 = 3, y: 2 − (−2) = 4, z: 15 − 3 = 12"
static func differences(s: Dictionary, a: Array, b: Array) -> String:
	var bits: Array = []
	for i in a.size():
		bits.append("%s: %s − %s = %s" % [axis_name(i), C(s, b[i]), B(s, a[i]), C(s, b[i].sub(a[i]))])
	return ", ".join(bits)


static func differences_step(s: Dictionary, rep: String, a: Array, b: Array) -> String:
	if rep == "notation":
		return "Subtract the position vectors: %s." % differences(s, a, b)
	return "The differences are %s." % differences(s, a, b)


## "3² + 4² + 12² = 9 + 16 + 144 = 169"
static func squares_sum(d: Array) -> String:
	var bits: Array = d.map(func(v): return "%s²" % P(v))
	var sq: Array = d.map(func(v): return N(v.sq()))
	return "%s = %s = %s" % [" + ".join(bits), " + ".join(sq), N(DistanceMidpointSituation.norm(d))]


## The last step: the root written out, then the answer as the question wants it.
static func final_step(s: Dictionary, label: String, n: int) -> String:
	var ans := length_ans(s, label, n)
	if s.paper == 2:
		return "√%d = %s to 3 s.f., so %s." % [n, Fmt.sf(sqrt(float(n))), Answer.text(ans)]
	var sv := DistanceMidpointSituation.surd(n)
	if sv[0] == 1 and sv[1] != 1:
		return "So %s." % Answer.text(ans)
	return "√%d = %s, so %s." % [n, root_text(n), Answer.text(ans)]


static func formula_steps(s: Dictionary, rep: String, label: String, a: Array, b: Array, n_final: int = -1) -> Array:
	var d := DistanceMidpointSituation.minus(b, a)
	var n := DistanceMidpointSituation.norm(d)
	return [differences_step(s, rep, a, b), "%s² = %s." % [label, squares_sum(d)], final_step(s, label, n if n_final < 0 else n_final)]


## Across the floor from the x and y moves, then up by the z move.
static func twice_steps(s: Dictionary, rep: String, label: String, a: Array, b: Array) -> Array:
	var d := DistanceMidpointSituation.minus(b, a)
	var floor_d := DistanceMidpointSituation.norm(d.slice(0, 2))
	var n := DistanceMidpointSituation.norm(d)
	return [differences_step(s, rep, a, b),
		"Across the floor, the diagonal f has f² = %s." % squares_sum(d.slice(0, 2)),
		"f and the z move are at right angles, so %s² = f² + %s² = %d + %s = %d." % [label, P(d[2]), floor_d, N(d[2].sq()), n],
		final_step(s, label, n)]


# ── Options for a length ─────────────────────────────────────

## What a slip on the squares gives for the move from a to b, as [value of the length squared, ref].
static func slips(a: Array, b: Array) -> Array:
	var d := DistanceMidpointSituation.minus(b, a)
	var n := DistanceMidpointSituation.norm(d)
	var total := Q.new(0)
	var sizes: Array = []
	for i in a.size():
		total = total.add(d[i])
		sizes.append(b[i].abs_q().sub(a[i].abs_q()))
	var out: Array = [[total.sq().n, R_SUM if a.size() == 3 else R_SUM_2D], [DistanceMidpointSituation.norm(sizes), R_NEGATIVE], [n * n, R_NO_ROOT],
		[DistanceMidpointSituation.norm(DistanceMidpointSituation.plus(a, b)), R_ADD_COORDS]]
	if a.size() == 3:
		out.append([DistanceMidpointSituation.norm(d.slice(0, 2)), R_DROP_Z])
	return out


static func length_options(s: Dictionary, label: String, n: int, tagged: Array, rng: Seeded) -> Dictionary:
	var w: Array = []
	for item in tagged:
		if item[0] > 0 and item[0] != n:
			w.append(length_wrong(s, label, item[0], item[1]))
	var gen: Array = []
	for x in [n + 1, n + 2, 2 * n, n + 3, n + 5, 2 * n + 1, n + 7, 3 * n]:
		gen.append(length_values(s, label, x))
	return {"wrongs": rng.shuffled(w), "generic": gen}


static func two_ways(s: Dictionary, rep: String, label: String, a: Array, b: Array) -> Dictionary:
	var n := DistanceMidpointSituation.norm(DistanceMidpointSituation.minus(b, a))
	var ans := length_ans(s, label, n)
	if a.size() == 2:
		return {"distance-formula-2d": method(formula_steps(s, rep, label, a, b), ans.values)}
	return {"distance-formula": method(formula_steps(s, rep, label, a, b), ans.values),
		"pythagoras-twice": method(twice_steps(s, rep, label, a, b), ans.values)}


static func exact_ask(s: Dictionary) -> String:
	return "Give your answer in exact form." if s.paper == 1 else "Give your answer to 3 significant figures."


# ── Distance ─────────────────────────────────────────────────

## The question's opening, by representation: the two points of a story.
static func pair_lines(s: Dictionary, rep: String) -> Array:
	var names: Array = s.names
	var a: String = named(s, names[0], s.A)
	var b: String = named(s, names[1], s.B)
	match rep:
		"notation":
			return ["Relative to the origin O, the points %s and %s have position vectors %s = %s and %s = %s." % [names[0], names[1],
				vec_name(names[0]), pt(s, s.A), vec_name(names[1]), pt(s, s.B)]]
		"diagram":
			return ["The diagram shows the points %s and %s on a set of axes." % names]
	var spot: Array = SPOTS[s.ctx]
	if s.dim == 2:
		return ["On a flat map with x- and y-axes, %s is at %s and %s is at %s." % [spot[0], a, spot[1], b]]
	return ["On a site plan with x-, y- and z-axes, %s is at %s and %s is at %s." % [spot[0], a, spot[1], b]]


func _distance(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var label: String = s.names[0] + s.names[1]
	var ans := length_ans(s, label, s.sq)
	var o := length_options(s, label, s.sq, slips(s.A, s.B), rng)
	var out := {"lines": pair_lines(s, rep), "answer": ans, "wrongs": o.wrongs, "generic": o.generic,
		"asked": "Find the distance %s. %s" % [label, exact_ask(s)], "methods": two_ways(s, rep, label, s.A, s.B)}
	if rep == "diagram":
		out.graph = pair_figure(s)
	return out


func u_distance_two_points(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _distance(rep, s, rng)


func u_distance_2d(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _distance(rep, s, rng)


## k in the place of A's or B's coordinate: "k − 2", "k + 3".
static func k_bracket(p: int) -> String:
	return "k − %d" % p if p > 0 else "k + %d" % -p


static func k_point(s: Dictionary) -> String:
	var bits: Array = []
	for i in 3:
		bits.append("k" if i == s.axis else C(s, s.B[i]))
	return "B(%s)" % ", ".join(bits)


static func k_vector(s: Dictionary) -> String:
	var bits: Array = []
	for i in 3:
		bits.append(k_bracket(s.p) if i == s.axis else C(s, s.B[i].sub(s.A[i])))
	return "(%s)" % ", ".join(bits)


static func k_lines(s: Dictionary, rep: String) -> Array:
	var d := root_text(s.top)
	if rep == "notation":
		return ["The vector from A to B is %s, and its length is %s." % [k_vector(s), d]]
	return ["On a site plan, %s is at %s and %s is at %s." % [SPOTS[s.ctx][0], named(s, "A", s.A), SPOTS[s.ctx][1], k_point(s)], "The distance AB is %s." % d]


## "3² + (k − 2)² + 6² = 49": the moves, with the bracket in its place.
static func k_equation(s: Dictionary) -> String:
	var bits: Array = []
	for i in 3:
		bits.append("(%s)²" % k_bracket(s.p) if i == s.axis else "%s²" % P(s.B[i].sub(s.A[i])))
	return "%s = %d" % [" + ".join(bits), s.top]


static func k_steps(s: Dictionary, rep: String, last: Array) -> Array:
	var rest: int = s.top - s.t
	var first := "Square the distance, with no roots: %s." % k_equation(s)
	if rep != "notation":
		first = "The difference that holds k is %s. Square the distance, with no roots: %s." % [k_bracket(s.p), k_equation(s)]
	return [first, "The known squares add to %d, so (%s)² = %d − %d = %d." % [rest, k_bracket(s.p), s.top, rest, s.t]] + last


func u_find_k_two_values(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var t: int = DistanceMidpointSituation.root_of(s.t)
	var p: int = s.p
	var ans := xs_ans([Q.new(p - t), Q.new(p + t)], true)
	var d2 := DistanceMidpointSituation.root_of(s.top)
	var w: Array = [wrong(Answer.xs_of([Q.new(p + t if rng.chance(0.5) else p - t)]), R_ONE_K),
		wrong(Answer.xs_of([Q.new(-p - t), Q.new(-p + t)]), R_K_SIGN),
		wrong(Answer.xs_of([Q.new(p - s.t), Q.new(p + s.t)]), R_K_SQUARE)]
	if d2 > 0:
		w.append(wrong(Answer.xs_of([Q.new(p - d2), Q.new(p + d2)]), R_NO_REST))
	var gen: Array = []
	for g in [t + 1, t + 2, t + 3, t + 4]:
		gen.append(Answer.xs_of([Q.new(p - g), Q.new(p + g)]))
	var last := ["Both signs of the root count: %s = ±%d. So %s." % [k_bracket(p), t, Answer.text(ans)]]
	return {"lines": k_lines(s, rep), "answer": ans, "wrongs": rng.shuffled(w), "generic": gen,
		"asked": "Find the possible values of k.", "methods": {"square-both-sides": method(k_steps(s, rep, last), ans.values)}}


static func xs_ans(vals: Array, exact: bool) -> Dictionary:
	var ans := Answer.make("xs", Answer.xs_of(vals), {"var": "k"})
	if exact:
		ans.exact = true
	else:
		ans.show = "sf"
	return ans


## "3 ± 2√5", the two values of k on Paper 1.
static func pm_text(p: int, m: int, r: int) -> String:
	return "%s ± %s" % [N(p), Answer.surd_text(m, r)]


func u_find_k_surd(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var sv := DistanceMidpointSituation.surd(s.t)
	var m: int = sv[0]
	var r: int = sv[1]
	var p: int = s.p
	var d2 := DistanceMidpointSituation.root_of(s.top)
	var root := sqrt(float(s.t))
	var ask := "Find the possible values of k."
	var ans: Dictionary
	var w: Array = []
	var gen: Array = []
	var last: Array
	if s.paper == 1:
		var head := "k = %s ± " % N(p)
		var parts: Array = [head + "√", {"slot": "r"}] if m == 1 else [head, {"slot": "m"}, "√", {"slot": "r"}]
		var vals := {"r": Q.new(r), "text": "k = " + pm_text(p, m, r)}
		if m > 1:
			vals.m = Q.new(m)
		ans = Answer.make("form", vals, {"parts": parts})
		ans.exact = true
		w = [wrong({"text": "k = %s + %s" % [N(p), Answer.surd_text(m, r)], "shape": "other"}, R_ONE_K),
			wrong({"text": "k = " + pm_text(-p, m, r), "shape": "other"}, R_K_SIGN),
			wrong({"text": "k = %s ± %d" % [N(p), s.t], "shape": "other"}, R_K_SQUARE),
			wrong({"text": "k = %s ± %d" % [N(p), d2], "shape": "other"}, R_NO_REST)]
		for g in [s.t + 1, s.t + 2, s.t + 3, s.t + 5, s.t + 6]:
			if DistanceMidpointSituation.root_of(g) < 0:
				var gv := DistanceMidpointSituation.surd(g)
				gen.append({"text": "k = " + pm_text(p, gv[0], gv[1]), "shape": "other"})
		ask += " Give your answers in exact form."
		last = ["Both signs of the root count, so %s = ±%s. So %s." % [k_bracket(p), root_text(s.t), Answer.text(ans)]]
	else:
		var lo := GdcKit.qf(p - root)
		var hi := GdcKit.qf(p + root)
		ans = xs_ans([lo, hi], false)
		w = [wrong(Answer.xs_of([hi]), R_ONE_K), wrong(Answer.xs_of([GdcKit.qf(-p - root), GdcKit.qf(-p + root)]), R_K_SIGN),
			wrong(Answer.xs_of([Q.new(p - s.t), Q.new(p + s.t)]), R_K_SQUARE), wrong(Answer.xs_of([Q.new(p - d2), Q.new(p + d2)]), R_NO_REST)]
		for g in [root + 1.0, root + 2.0, root * 2.0, root + 3.0]:
			gen.append(Answer.xs_of([GdcKit.qf(p - g), GdcKit.qf(p + g)]))
		ask += " Give your answers to 3 significant figures."
		last = ["Both signs of the root count, so %s = ±√%d = ±%s to 3 s.f. So %s." % [k_bracket(p), s.t, Fmt.sf(root), Answer.text(ans)]]
	return {"lines": k_lines(s, rep), "answer": ans, "wrongs": rng.shuffled(w), "generic": gen, "asked": ask,
		"methods": {"square-both-sides": method(k_steps(s, rep, last), ans.values)}}


# ── The isosceles triangle ───────────────────────────────────

const PAIRS := ["AB = AC", "AB = BC", "AC = BC"]


func u_show_isosceles(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var pair: String = PAIRS[s.apex]
	var text := "%s = √%d" % [pair, s.sq]
	var ans := Answer.make("form", {"pair": pair, "r": Q.new(s.sq), "text": text},
		{"parts": [{"pick": "pair", "options": PAIRS}, " = √", {"slot": "r"}]})
	ans.exact = true
	var lines: Array
	match rep:
		"notation":
			lines = ["Relative to the origin O, the points A, B and C have position vectors a = %s, b = %s and c = %s." % [pt(s, s.A), pt(s, s.B), pt(s, s.C)]]
		"diagram":
			lines = ["The diagram shows triangle ABC on a set of axes."]
		_:
			lines = ["%s stand at %s, %s and %s." % [THREE[s.ctx], named(s, "A", s.A), named(s, "B", s.B), named(s, "C", s.C)]]
	var odd: String = PAIRS[(s.apex + 1) % 3]
	var w: Array = [wrong({"text": "%s = √%d" % [odd, s.sq], "pair": odd, "r": Q.new(s.sq)}, R_WRONG_PAIR),
		wrong({"text": "%s = %s" % [pair, root_text(s.top)], "shape": "other"}, R_THIRD),
		wrong({"text": "%s = %d" % [pair, s.sq], "shape": "other"}, R_NO_ROOT)]
	var gen: Array = []
	for g in [s.sq + 1, s.sq + 2, s.sq + 3]:
		gen.append({"text": "%s = %s" % [pair, root_text(g)], "shape": "other"})
	var ab := DistanceMidpointSituation.minus(s.B, s.A)
	var ac := DistanceMidpointSituation.minus(s.C, s.A)
	var bc := DistanceMidpointSituation.minus(s.C, s.B)
	var sides := [["AB", ab], ["AC", ac], ["BC", bc]]
	var formula: Array = []
	var squares: Array = []
	for side in sides:
		var n := DistanceMidpointSituation.norm(side[1])
		formula.append("%s = √(%s) = %s." % [side[0], " + ".join(side[1].map(func(v): return "%s²" % P(v))), "√%d" % n])
		squares.append("%s² = %d" % [side[0], n])
	formula.append("Two sides match and the third differs, so the triangle is isosceles: %s." % text)
	var out := {"lines": lines, "answer": ans, "wrongs": rng.shuffled(w), "generic": gen,
		"asked": "Show that triangle ABC is isosceles: which two sides are equal, and what is their exact length?",
		"methods": {"distance-formula": method(formula, ans.values),
			"square-both-sides": method(["Compare the squares of the sides, with no roots: " + ", ".join(squares) + ".",
				"Two squares match and the third differs, so the triangle is isosceles, and each equal side is the root of %d: %s." % [s.sq, text]], ans.values)}}
	if rep == "diagram":
		out.graph = figure(s, {"A": s.A, "B": s.B, "C": s.C}, {"A": named(s, "A", s.A), "B": named(s, "B", s.B), "C": named(s, "C", s.C)},
			[line("A", "B"), line("B", "C"), line("A", "C")])
	return out


# ── Solids on axes ───────────────────────────────────────────

func u_space_diagonal(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var e: Array = s.B
	var ans := length_ans(s, "OG", s.sq)
	var lines := ["%s is a cuboid with one corner at O(0, 0, 0) and its edges along the axes. The opposite corner is %s." % [CRATES[s.ctx], named(s, "G", e)]]
	if rep == "diagram":
		lines = ["The diagram shows a cuboid with one corner at the origin O and its edges along the axes. G is the opposite corner."]
	var tagged: Array = slips(s.A, s.B).filter(func(item): return item[1] != R_NEGATIVE and item[1] != R_ADD_COORDS)
	var o := length_options(s, "OG", s.sq, tagged, rng)
	var out := {"lines": lines, "answer": ans, "wrongs": o.wrongs, "generic": o.generic,
		"asked": "Find the length of the space diagonal OG. %s" % exact_ask(s), "methods": two_ways(s, "equation", "OG", s.A, s.B)}
	if rep == "diagram":
		var pts := {"O": s.A, "G": e}
		var lines_fig: Array = []
		var edge := func(mask: int) -> Array:
			return [e[0] if mask & 1 else Q.new(0), e[1] if mask & 2 else Q.new(0), e[2] if mask & 4 else Q.new(0)]
		var name := func(mask: int) -> String:
			return "O" if mask == 0 else ("G" if mask == 7 else "_%d" % mask)
		for mask in range(1, 7):
			pts["_%d" % mask] = edge.call(mask)
		for mask in 8:
			for bit in [1, 2, 4]:
				if mask & bit == 0:
					lines_fig.append(line(name.call(mask), name.call(mask | bit), mask == 0))
		lines_fig.append(line("O", "G", false, true))
		out.graph = figure(s, pts, {"G": named(s, "G", e), "O": "O"}, lines_fig)
	return out


func u_pyramid_edge(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var label: String = s.names[0] + s.names[1]
	var ans := length_ans(s, label, s.sq)
	var tagged: Array = slips(s.A, s.B)
	var lines: Array
	var thing: String = STONES[s.ctx]
	var ask := "Find the length of the edge %s. %s" % [label, exact_ask(s)]
	if s.mode == "upright":
		lines = ["%s is a pyramid with vertex %s and rectangular base OABC, where O is the origin and the base is in the xy-plane. One corner of the base is %s." % [thing, named(s, "V", s.B), named(s, s.names[0], s.A)]]
		tagged.append([4 * (s.a * s.a + s.b * s.b) + s.h * s.h, R_WHOLE_BASE])
		if rep == "diagram":
			lines = ["The diagram shows a pyramid with vertex V and rectangular base OABC, where O is the origin and the base is in the xy-plane."]
	elif s.mode == "height":
		lines = ["%s is a right pyramid with vertex %s, and the centre of its base is %s." % [thing, named(s, "V", s.A), named(s, "X", s.B)]]
		ask = "Find the height %s of the pyramid. %s" % [label, exact_ask(s)]
	else:
		lines = ["%s is a right pyramid with vertex %s, and one corner of its base is %s." % [thing, named(s, "V", s.B), named(s, "A", s.A)]]
	var o := length_options(s, label, s.sq, tagged, rng)
	var out := {"lines": lines, "answer": ans, "wrongs": o.wrongs, "generic": o.generic, "asked": ask,
		"methods": two_ways(s, "equation", label, s.A, s.B)}
	if rep == "diagram":
		var c := Q.new(2 * s.a)
		var d := Q.new(2 * s.b)
		var z := Q.new(0)
		var shown := {"V": named(s, "V", s.B), "O": "O"}
		var corners := {"A": [z, d, z], "B": [c, d, z], "C": [c, z, z]}
		for n in corners:
			shown[n] = named(s, n, corners[n]) if n == s.names[0] or n == "C" else n
		var pts := corners.duplicate()
		pts["O"] = [z, z, z]
		pts["V"] = s.B
		var edges: Array = [line("O", "A"), line("A", "B"), line("B", "C"), line("C", "O"), line("O", "V"), line("A", "V"), line("B", "V"), line("C", "V")]
		edges = edges.filter(func(e): return not (e.a == s.names[0] and e.b == "V"))
		edges.append(line(s.names[0], "V", false, true))
		out.graph = figure(s, pts, shown, edges)
	return out


# ── Round solids ─────────────────────────────────────────────

static func thing_of(s: Dictionary) -> String:
	match s.shape:
		"sphere":
			return BALLS[s.ctx]
		"hemisphere":
			return DOMES[s.ctx]
	return HATCHES[s.ctx]


func u_radius_from_centre(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c: String = named(s, "C", s.A)
	var p: String = named(s, "P", s.B)
	var thing := thing_of(s)
	var lines: Array
	if s.shape == "sphere":
		lines = ["%s is a sphere with centre %s. The point %s lies on its surface." % [thing, c, p]]
	else:
		lines = ["%s is a solid hemisphere with centre %s. The point %s lies on its curved surface." % [thing, c, p]]
	if rep == "diagram":
		lines = ["The diagram shows a %s with centre C. The point P lies on its %s." % ["sphere" if s.shape == "sphere" else "solid hemisphere", "surface" if s.shape == "sphere" else "curved surface"]]
	var ans := length_ans(s, "r", s.sq)
	var tagged: Array = slips(s.A, s.B)
	tagged.append([4 * s.sq, R_DOUBLED])
	var o := length_options(s, "r", s.sq, tagged, rng)
	var out := {"lines": lines, "answer": ans, "wrongs": o.wrongs, "generic": o.generic,
		"asked": "Find the radius r. %s" % exact_ask(s), "methods": two_ways(s, "equation", "r", s.A, s.B)}
	if rep == "diagram":
		out.graph = ball_figure(s, {"C": [0.0, 0.0], "P": on_circle(s.turn)}, {"C": c, "P": p}, [line("C", "P", false, true)], "C", "P")
	return out


func diameter_lines(s: Dictionary, rep: String, ends: Array) -> Array:
	var shape: String = "sphere" if s.shape == "sphere" else "circle"
	if rep == "diagram":
		return ["The diagram shows a %s with diameter [AB]." % shape]
	return ["%s is a %s with diameter [AB], where the ends are %s and %s." % [thing_of(s), shape, ends[0], ends[1]]]


func diameter_figure(s: Dictionary, name: String, shown: String) -> Dictionary:
	var o := on_circle(s.turn)
	return ball_figure(s, {"A": o, "B": [-o[0], -o[1]], name: [0.0, 0.0]},
		{"A": named(s, "A", s.A), "B": named(s, "B", s.B), name: shown}, [line("A", "B", false, true)], name, "A")


func u_radius_from_diameter(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: Array = s.A
	var b: Array = s.B
	var n: int = s.sq
	var half := DistanceMidpointSituation.midpoint(a, b)
	var ans: Dictionary
	var tagged: Array = []
	# Each slip as the square of the diameter it gives.
	var diameter: Array = [4 * n, R_DIAMETER]
	var first := formula_steps(s, "equation", "AB", a, b)
	var steps: Array
	var through: Array
	var d := DistanceMidpointSituation.minus(b, a)
	var from_c := DistanceMidpointSituation.minus(a, half)
	if s.paper == 1:
		ans = length_ans(s, "r", n / 4)
		tagged = [diameter, [n * n / 4, R_NO_ROOT]]
		steps = [first[0], first[1], "AB = √%d = %s, and the radius is half of the diameter." % [n, root_text(n)], final_step(s, "r", n / 4)]
		through = ["The centre is the midpoint of [AB]: %s." % named(s, "C", half),
			"r² = CA² = %s." % squares_sum(from_c), final_step(s, "r", n / 4)]
	else:
		var r := sqrt(float(n)) / 2.0
		ans = decimal_ans("r", r)
		steps = [first[0], first[1], "AB = √%d = %s to 5 s.f., and the radius is half of the diameter." % [n, Fmt.work(sqrt(float(n)), 5)],
			"%s ÷ 2 = %s to 3 s.f., so %s." % [Fmt.work(sqrt(float(n)), 5), Fmt.sf(r), Answer.text(ans)]]
		tagged = [diameter]
		var m2 := DistanceMidpointSituation.norm(times_two(from_c))
		through = ["The centre is the midpoint of [AB]: %s." % named(s, "C", half),
			"r² = CA² = %s." % sq_sum_q(from_c),
			"r = √%s = %s to 3 s.f., so %s." % [C(s, Q.new(m2, 4)), Fmt.sf(r), Answer.text(ans)]]
	for slip in slips(a, b):
		if slip[1] != R_NO_ROOT and (s.paper == 2 or slip[0] % 4 == 0):
			tagged.append(slip)
	var w: Array = []
	var seen := {n: true}
	for item in tagged:
		if item[0] > 0 and not seen.has(item[0]):
			seen[item[0]] = true
			w.append(wrong(radius_values(s, item[0]), item[1]))
	var gen: Array = []
	for x in [n + 4, 2 * n, n + 12, n + 20, 3 * n, n + 28, n + 36]:
		gen.append(radius_values(s, x))
	var out := {"lines": diameter_lines(s, rep, [named(s, "A", a), named(s, "B", b)]), "answer": ans, "wrongs": rng.shuffled(w), "generic": gen,
		"asked": "Find the radius r. %s" % exact_ask(s),
		"methods": {"distance-formula": method(steps, ans.values), "average-coordinates": method(through, ans.values)}}
	if rep == "diagram":
		out.graph = diameter_figure(s, "_c", "")
	return out


static func times_two(p: Array) -> Array:
	return DistanceMidpointSituation.times(p, 2)


## "1.5² + (−2)² = 2.25 + 4 = 6.25", for half-whole moves.
static func sq_sum_q(d: Array) -> String:
	var total := Q.new(0)
	for v in d:
		total = total.add(v.sq())
	return "%s = %s = %s" % [" + ".join(d.map(func(v): return "%s²" % ("(%s)" % Fmt.dec(v) if v.sign() < 0 else Fmt.dec(v)))),
		" + ".join(d.map(func(v): return Fmt.dec(v.sq()))), Fmt.dec(total)]


## The radius from a diameter whose square is n.
static func radius_values(s: Dictionary, n: int) -> Dictionary:
	if s.paper == 2:
		return {"v": GdcKit.qf(sqrt(float(n)) / 2.0)}
	return length_values(s, "r", n / 4)


func u_origin_to_curve(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: int = s.ca
	var b: int = s.cb
	var xs := {"x": "x", "x2": "x²", "x3": "x³"}
	var term: String = xs[s.shape]
	var inner := "%d%s + %d − x²" % [a, term, b]
	var wanted := a
	if s.shape == "x2":
		inner = "%dx² + %d" % [a, b]
		wanted = a + 1
	var under := "%d%s + %d" % [wanted, term, b]
	var text := "l = √(%s)" % under
	var ans := Answer.make("form", {"a": Q.new(wanted), "b": Q.new(b), "text": text},
		{"parts": ["l = √(", {"slot": "a"}, term + " + ", {"slot": "b"}, ")"]})
	ans.exact = true
	var w: Array = [
		wrong({"text": "l = x + √(%s)" % inner, "shape": "other"}, R_PLAIN_SUM),
		wrong({"text": "l = √(%s)" % inner, "shape": "other"}, R_F_ONLY),
		wrong({"text": "l = %s" % under, "shape": "other"}, R_NO_ROOT),
		wrong({"text": "l = √(%s − x²)" % inner if s.shape == "x2" else "l = √(%s − 2x²)" % under, "shape": "other"}, R_TAKE_SQUARES)]
	var gen: Array = []
	for g in [wanted + 1, wanted + 2, wanted + 3]:
		gen.append({"text": "l = √(%d%s + %d)" % [g, term, b], "shape": "other"})
	var step2 := "f(x)² = %s, so l² = x² + %s." % [inner, inner]
	var step3 := "The x² terms cancel, so l² = %s." % under if s.shape != "x2" else "The x² terms add, so l² = %s." % under
	return {"lines": ["Consider the function f(x) = √(%s)." % inner, "The point P(x, f(x)) is on the graph of f."], "answer": ans,
		"wrongs": rng.shuffled(w), "generic": gen,
		"asked": "Find the distance l from the origin to P, in terms of x, in its simplest form.",
		"methods": {"distance-formula-2d": method(["The distance from (0, 0) to (x, f(x)) has l² = x² + f(x)².", step2, step3, "So %s." % text], ans.values)}}


# ── Midpoints ────────────────────────────────────────────────

## "x: (1 + 5)/2 = 3, y: ..."
static func averages(s: Dictionary, a: Array, b: Array) -> String:
	var bits: Array = []
	for i in a.size():
		bits.append("%s: (%s + %s)/2 = %s" % [axis_name(i), C(s, a[i]), B(s, b[i]), C(s, a[i].add(b[i]).div(2))])
	return ", ".join(bits)


## Wrong midpoints, with the slip each one is.
static func midpoint_wrongs(s: Dictionary, a: Array, b: Array) -> Array:
	var sizes: Array = []
	for i in a.size():
		sizes.append(a[i].abs_q().add(b[i].abs_q()).div(2))
	return [point_wrong(s, DistanceMidpointSituation.times(DistanceMidpointSituation.minus(b, a), Q.new(1, 2)), R_SUBTRACT),
		point_wrong(s, DistanceMidpointSituation.plus(a, b), R_NO_HALF), point_wrong(s, sizes, R_MID_SIGN)]


static func midpoint_ways(s: Dictionary, a: Array, b: Array, name: String, ans: Dictionary) -> Dictionary:
	var m := DistanceMidpointSituation.midpoint(a, b)
	var step := DistanceMidpointSituation.minus(b, a)
	var half := DistanceMidpointSituation.times(step, Q.new(1, 2))
	var said := "So %s is %s." % [name, pt(s, m)]
	return {"average-coordinates": method(["Add each pair of coordinates and halve: %s." % averages(s, a, b), said], ans.values),
		"repeat-the-step": method(["The step from A to B is %s." % pt(s, step), "Half of it is %s." % pt(s, half),
			"Add that to A: %s." % adds(s, a, half), said], ans.values)}


## "(1 + 2, 4 + (−1), 0 + 3) = (3, 3, 3)"
static func adds(s: Dictionary, a: Array, b: Array) -> String:
	var bits: Array = []
	for i in a.size():
		bits.append("%s + %s" % [C(s, a[i]), B(s, b[i])])
	return "(%s) = %s" % [", ".join(bits), pt(s, DistanceMidpointSituation.plus(a, b))]


func _midpoint(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := point_ans(s, s.M)
	var a: String = named(s, "A", s.A)
	var b: String = named(s, "B", s.B)
	var lines: Array
	match rep:
		"notation":
			lines = ["Relative to the origin O, the points A and B have position vectors a = %s and b = %s." % [pt(s, s.A), pt(s, s.B)]]
		"diagram":
			lines = ["The diagram shows the line segment [AB] on a set of axes, with its midpoint M."]
		_:
			lines = ["%s runs in a straight line from %s to %s." % [RUNS[s.ctx], a, b]]
	var out := {"lines": lines, "answer": ans, "wrongs": rng.shuffled(midpoint_wrongs(s, s.A, s.B)), "generic": near_points(s, s.M),
		"asked": "Find the coordinates of the midpoint M of [AB].", "methods": midpoint_ways(s, s.A, s.B, "M", ans)}
	if rep == "diagram":
		var hidden := "(%s)" % ", ".join(s.A.map(func(_v): return "?"))
		out.graph = figure(s, {"A": s.A, "B": s.B, "M": s.M}, {"A": a, "B": b, "M": "M" + hidden}, [line("A", "B", false, true)])
	return out


func u_midpoint_3d(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _midpoint(rep, s, rng)


func u_midpoint_2d(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _midpoint(rep, s, rng)


func u_centre_from_diameter(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := point_ans(s, s.M)
	var out := {"lines": diameter_lines(s, rep, [named(s, "A", s.A), named(s, "B", s.B)]), "answer": ans,
		"wrongs": rng.shuffled(midpoint_wrongs(s, s.A, s.B)), "generic": near_points(s, s.M),
		"asked": "Find the coordinates of the centre C.", "methods": midpoint_ways(s, s.A, s.B, "C", ans)}
	if rep == "diagram":
		out.graph = diameter_figure(s, "C", "C(?, ?, ?)")
	return out


func _endpoint(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := point_ans(s, s.B)
	var a: String = named(s, "A", s.A)
	var m: String = named(s, "M", s.M)
	var lines: Array
	match rep:
		"notation":
			lines = ["Relative to the origin O, the points A and M have position vectors a = %s and m = %s." % [pt(s, s.A), pt(s, s.M)], "M is the midpoint of [AB]."]
		"diagram":
			lines = ["The diagram shows the line segment [AB] on a set of axes, with its midpoint M."]
		_:
			lines = ["%s runs in a straight line from %s to B. Its midpoint is %s." % [RUNS[s.ctx], a, m]]
	var dm := DistanceMidpointSituation
	var two_m: Array = dm.times(s.M, 2)
	var w: Array = [point_wrong(s, dm.midpoint(s.A, s.M), R_AVERAGED), point_wrong(s, dm.times(s.M, Q.new(1, 2)), R_HALVED),
		point_wrong(s, dm.minus(s.M, s.A), R_STEP_ONLY), point_wrong(s, two_m, R_DOUBLE_M), point_wrong(s, dm.plus(two_m, s.A), R_ADD_A)]
	var solve: Array = []
	var letters := ["x", "y", "z"]
	for i in s.A.size():
		var two: Q = s.M[i].mul(2)
		solve.append("(%s + %s)/2 = %s, so %s + %s = %s and %s = %s." % [C(s, s.A[i]), letters[i], C(s, s.M[i]), C(s, s.A[i]), letters[i], C(s, two), letters[i], C(s, s.B[i])])
	var said := "So B is %s." % pt(s, s.B)
	solve.append(said)
	var step: Array = dm.minus(s.M, s.A)
	var out := {"lines": lines, "answer": ans, "wrongs": rng.shuffled(w), "generic": near_points(s, s.B),
		"asked": "Find the coordinates of B.",
		"methods": {"solve-each-coordinate": method(solve, ans.values),
			"repeat-the-step": method(["The step from A to M is %s." % pt(s, step), "B is the same step again from M: %s." % adds(s, s.M, step), said], ans.values)}}
	if rep == "diagram":
		var hidden := "(%s)" % ", ".join(s.A.map(func(_v): return "?"))
		out.graph = figure(s, {"A": s.A, "B": s.B, "M": s.M}, {"A": a, "M": m, "B": "B" + hidden}, [line("A", "B", false, true)])
	return out


func u_missing_endpoint(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _endpoint(rep, s, rng)


func u_missing_endpoint_2d(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _endpoint(rep, s, rng)
