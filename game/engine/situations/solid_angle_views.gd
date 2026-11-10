class_name SolidAngleViews
extends ExtensionViews
## The views on the `solid-angle` situation: one builder per unknown of t3-3d-angle (FAL-754).
## An angle is a `number` to 3 s.f. with the rounding trap on Paper 2, and an exact whole number
## of degrees on Paper 1 (landmark-angle only).
##
## Representations: "diagram" (PlotView's `space`: the solid with its lettered corners, the line
## or lines asked in pink, a plane shaded, and the measures on the edges, or the points on axes),
## "words" (the solid in a story, its measures in the sentences), "equation" (the points'
## coordinates in a sentence, as A(1, −2, 3)) and "notation" (position vectors a = (1, −2, 3)).
## The working keeps every root exact, as √73, and rounds only at the end, so each step follows
## from the one before.

const LP := "SL3.1.angle-line-plane#"
const TL := "SL3.1.angle-two-lines#"
const TYPE := "t3-3d-angle#"
const R_EDGE := LP + "0"
const R_FACE_UP := LP + "1"
const R_SLANT := LP + "2"
const R_LOOKS_RIGHT := TL + "0"
const R_FACE_DIAG := TL + "1"
const R_OPPOSITE := TL + "2"
## The type's own slips: an index into its misconceptions.
const R_VERTICAL := TYPE + "6"
const R_FULL_RUN := TYPE + "7"
const R_WHOLE_DIAG := TYPE + "8"
const R_OTHER_HALF := TYPE + "9"
const R_DIAMETER := TYPE + "10"
const R_SLANT_UP := TYPE + "11"
const R_ONE_RUN := TYPE + "12"
const R_HALF_ANGLE := TYPE + "13"
const R_WHOLE_SPACE := TYPE + "14"
const R_NO_TWO := TYPE + "15"
const R_HEIGHT_EDGE := TYPE + "16"
const R_ACUTE := TYPE + "17"
const R_TO_BASE := TYPE + "18"
const R_TAN_HYP := TYPE + "19"

const UNKNOWNS := ["cuboid-diagonal-base", "pyramid-edge-base", "pyramid-face-base", "cone-slant-base", "coords-line-plane",
	"landmark-angle", "cuboid-two-diagonals", "pyramid-apex-angle", "cuboid-diagonal-edge", "coords-angle-abc", "coords-right-angle"]

## The stories: [thing, unit].
const CRATES := [["A storage crate", "cm"], ["A shipping container", "m"], ["A rain tank", "m"], ["A tool locker", "cm"],
	["A grain bin", "m"], ["A battery case", "cm"]]
const PYRAMIDS := [["A canvas shelter", "m"], ["A scrap-metal roof", "m"], ["A stone marker", "cm"], ["A glass lamp cover", "cm"],
	["A watchtower's cap", "m"], ["A salt store", "m"]]
const CONES := [["A spoil heap", "m"], ["A sand pile", "m"], ["A fuel funnel", "cm"], ["A lamp shade", "cm"], ["A gravel mound", "m"],
	["A road cone", "cm"]]
const RUNS := ["A zip line", "A cable", "A fuel pipe", "A rope bridge", "A power line", "A chute"]
const THREE := ["Three signal lamps", "Three marker drones", "Three cable anchors", "Three radio masts' tips", "Three scrap towers' tops",
	"Three camp beacons"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## landmark-angle is the one Paper 1 unknown: its angle is exact. The rest need a calculator.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	if not has(unknown):
		return []
	return [1] if unknown == "landmark-angle" else [2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = SolidAngleSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

## "8² + 6² + (−3)²"
static func sqsum(vals: Array) -> String:
	return " + ".join(vals.map(func(v): return "%s²" % P(v)))


static func is_square(n: Variant) -> bool:
	var q := Q.of(n)
	var a := roundi(sqrt(float(q.n)))
	var b := roundi(sqrt(float(q.d)))
	return a * a == q.n and b * b == q.d


## The root of n as a value in a sum: "10" when n is 100, else "√73" (a decimal n as √31.25).
static func rv(n: Variant) -> String:
	var q := Q.of(n)
	if is_square(q):
		return Fmt.dec(Q.new(roundi(sqrt(float(q.n))), roundi(sqrt(float(q.d)))))
	return "√" + Fmt.dec(q)


## "√73", or "√100 = 10".
static func root_eq(n: Variant) -> String:
	var q := Q.of(n)
	return "√%s = %s" % [Fmt.dec(q), rv(q)] if is_square(q) else "√" + Fmt.dec(q)


## Half of a root: "√100 ÷ 2 = 5", or "√73 ÷ 2".
static func half_eq(n: int) -> String:
	if is_square(n):
		return "%s ÷ 2 = %s" % [rv(n), Fmt.dec(Q.new(roundi(sqrt(float(n))), 2))]
	return "√%d ÷ 2" % n


## Half of a root as a value in a sum: "5", or "(√73 ÷ 2)".
static func half_v(n: int) -> String:
	return Fmt.dec(Q.new(roundi(sqrt(float(n))), 2)) if is_square(n) else "(√%d ÷ 2)" % n


static func sf3(text: String) -> String:
	return text + " Give your answer to 3 significant figures."


static func deg(x: float) -> String:
	return Fmt.sf(x) + "°"


static func ang_ans(label: String, x: float) -> Dictionary:
	var ans := Answer.make("number", {"v": GdcKit.qf(x)}, {}, label, "°")
	ans.show = "sf"
	return ans


## The last step: the inverse worked out, then the answer.
static func last(expr: String, x: float, ans: Dictionary) -> String:
	return "%s = %s to 3 s.f., so %s." % [expr, deg(x), Answer.text(ans)]


## A wrong angle, kept when it is a real angle that reads clearly at 3 s.f.
static func bad(x: float, ref: String = "") -> Array:
	if not is_finite(x) or x <= 0.5 or x >= 179.5 or not Answer.rounds_clearly(x, 0.002):
		return []
	return [wrong({"v": GdcKit.qf(x)}, ref)]


static func gens(xs: Array) -> Array:
	var out: Array = []
	for x in xs:
		if is_finite(x) and x > 0.5 and x < 179.5 and Answer.rounds_clearly(x, 0.002):
			out.append({"v": GdcKit.qf(x)})
	return out


static func atan_d(y: float, x: float) -> float:
	return rad_to_deg(atan2(y, x))


static func acos_d(c: float) -> float:
	return rad_to_deg(acos(c)) if absf(c) <= 1.0 else NAN


static func asin_d(c: float) -> float:
	return rad_to_deg(asin(c)) if absf(c) <= 1.0 else NAN


static func unit_of(s: Dictionary, list: Array) -> String:
	return " " + str(list[s.ctx][1])


static func pt(p: Array) -> String:
	return "(%s)" % ", ".join(p.map(func(v): return N(v)))


# ── Figures ──────────────────────────────────────────────────

static func line(a: String, b: String, dash: bool = false, asked: bool = false, label: String = "") -> Dictionary:
	return {"a": a, "b": b, "dash": dash, "asked": asked, "label": label}


static func space(pts: Dictionary, lines: Array, axes: bool = false) -> Dictionary:
	var labels := {}
	for n in pts:
		if not String(n).begins_with("_"):
			labels[n] = n
	return {"kind": "space", "dim": 3, "axes": axes, "pts": pts, "labels": labels, "lines": lines}


## The corners of a cuboid (or a pyramid's base) with D at the origin, as the figure sees them:
## A comes towards you, B to its right, and E to H are h above A to D.
static func box_pts(s: Dictionary, top: bool) -> Dictionary:
	var l := float(s.l)
	var w := float(s.w)
	var h := float(s.h)
	var out := {"A": [w, 0.0, 0.0], "B": [w, l, 0.0], "C": [0.0, l, 0.0], "D": [0.0, 0.0, 0.0]}
	if top:
		out.merge({"E": [w, 0.0, h], "F": [w, l, h], "G": [0.0, l, h], "H": [0.0, 0.0, h]})
	return out


## A cuboid's twelve edges, the three at D dashed (it is hidden), each with its label if any.
## `asked` lines are drawn over them in pink.
static func cuboid_figure(s: Dictionary, labels: Dictionary, asked: Array, extra: Dictionary = {}) -> Dictionary:
	var pts := box_pts(s, true)
	pts.merge(extra)
	var lines: Array = []
	for e in ["AB", "BC", "CD", "DA", "EF", "FG", "GH", "HE", "AE", "BF", "CG", "DH"]:
		if e in asked or e.reverse() in asked:
			continue
		lines.append(line(e[0], e[1], e.contains("D"), false, labels.get(e, "")))
	for e in asked:
		lines.append(line(e[0], e[1], false, true, labels.get(e, "")))
	return space(pts, lines)


static func cuboid_labels(s: Dictionary) -> Dictionary:
	var u := unit_of(s, CRATES)
	return {"AB": "%d%s" % [s.l, u], "BC": "%d%s" % [s.w, u], "AE": "%d%s" % [s.h, u]}


## A right pyramid VABCD over the same base, V above the centre X.
static func pyramid_figure(s: Dictionary, labels: Dictionary, asked: Array, extra: Dictionary = {}, height: bool = true) -> Dictionary:
	var pts := box_pts(s, false)
	pts["X"] = [s.w / 2.0, s.l / 2.0, 0.0]
	pts["V"] = [s.w / 2.0, s.l / 2.0, float(s.h)]
	pts.merge(extra)
	var lines: Array = []
	for e in ["AB", "BC", "CD", "DA", "VA", "VB", "VC", "VD"]:
		if e in asked:
			continue
		lines.append(line(e[0], e[1], e.contains("D"), false, labels.get(e, "")))
	if height:
		lines.append(line("V", "X", true, false, labels.get("VX", "")))
	for e in asked:
		lines.append(line(e[0], e[1], false, true, labels.get(e, "")))
	var g := space(pts, lines)
	if not height:
		g.pts.erase("X")
		g.labels.erase("X")
	return g


static func pyramid_labels(s: Dictionary) -> Dictionary:
	var u := unit_of(s, PYRAMIDS)
	return {"AB": "%d%s" % [s.l, u], "BC": "%d%s" % [s.w, u], "VX": "%d%s" % [s.h, u]}


## A cone with vertex V over the centre O, and A on the rim towards you on the right.
static func cone_figure(s: Dictionary, labels: Dictionary) -> Dictionary:
	var c := SolidAngleSituation.cone(s)
	var r: float = c[0]
	var pts := {"O": [0.0, 0.0, 0.0], "V": [0.0, 0.0, c[1]], "A": [r * 0.5, r * sqrt(3.0) / 2.0, 0.0]}
	var lines: Array = [line("O", "A", true, false, labels.get("OA", "")), line("V", "O", true, false, labels.get("VO", "")),
		line("V", "A", false, true, labels.get("VA", ""))]
	var g := space(pts, lines)
	g.rims = [{"at": "O", "r": r, "apex": "V"}]
	return g


static func cone_labels(s: Dictionary) -> Dictionary:
	var u := unit_of(s, CONES)
	var out := {}
	if "r" in s.given:
		out.OA = "%d%s" % [s.r, u]
	if "h" in s.given:
		out.VO = "%d%s" % [s.h, u]
	if "l" in s.given:
		out.VA = "%d%s" % [s.sl, u]
	return out


## Points on axes with their coordinates, each joined by a dashed drop to the xy-plane.
static func points_figure(names: Array, s: Dictionary, lines: Array, drops: bool) -> Dictionary:
	var pts := {}
	var labels := {}
	for n in names:
		var p: Array = s[n]
		pts[n] = p.map(func(v): return float(v))
		labels[n] = n + pt(p)
		if drops and p[2] != 0:
			pts["_" + n] = [float(p[0]), float(p[1]), 0.0]
			lines.append(line(n, "_" + n, true))
	return {"kind": "space", "dim": 3, "axes": true, "pts": pts, "labels": labels, "lines": lines}


# ── Line and plane ───────────────────────────────────────────

static func cuboid_lines(rep: String, s: Dictionary) -> Array:
	if rep == "diagram":
		return ["The diagram shows a cuboid ABCDEFGH. Its base ABCD is horizontal, and E, F, G and H are directly above A, B, C and D."]
	var u := unit_of(s, CRATES)
	return ["%s is a cuboid ABCDEFGH. Its base ABCD is horizontal, with AB = %d%s and BC = %d%s, and E, F, G and H are directly above A, B, C and D, with AE = %d%s." % [
		CRATES[s.ctx][0], s.l, u, s.w, u, s.h, u]]


func u_cuboid_diagonal_base(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var l: int = s.l
	var w: int = s.w
	var h: int = s.h
	var base := l * l + w * w
	var n := base + h * h
	var t: float = s.theta
	var ans := ang_ans("θ = ", t)
	var d := sqrt(float(n))
	var f := sqrt(float(base))
	var lines := cuboid_lines(rep, s)
	var wr: Array = bad(acos_d(l / d), R_EDGE) + bad(atan_d(f, h), R_FACE_UP) + bad(atan_d(h, d), R_FULL_RUN)
	var out := {"lines": lines, "answer": ans, "wrongs": rng.shuffled(wr), "generic": gens([atan_d(h, l), atan_d(h, w), acos_d(w / d), t + 10.0]),
		"asked": sf3("Find the angle θ between the diagonal AG and the base ABCD.")}
	var see := "G is directly above C, so AC is the projection of AG onto the base, and θ is angle GAC."
	out.methods = {
		"project-and-tan": method([see, "AC = √(%s) = %s." % [sqsum([l, w]), root_eq(base)], "tan θ = CG ÷ AC = %d ÷ %s." % [h, rv(base)],
			last("tan⁻¹(%d ÷ %s)" % [h, rv(base)], t, ans)], ans.values),
		"sin-with-length": method([see + " Triangle GAC has its right angle at C.", "AG = √(%s) = %s." % [sqsum([l, w, h]), root_eq(n)],
			"sin θ = CG ÷ AG = %d ÷ %s." % [h, rv(n)], last("sin⁻¹(%d ÷ %s)" % [h, rv(n)], t, ans)], ans.values),
		"coordinates": method(["Put A at the origin with AB along the x-axis, AD along the y-axis and AE up the z-axis, so G is (%d, %d, %d)." % [l, w, h],
			"From A to G the rise is Δz = %d and the run across the base is √(Δx² + Δy²) = √(%s) = %s." % [h, sqsum([l, w]), root_eq(base)],
			last("tan⁻¹(%d ÷ %s)" % [h, rv(base)], t, ans)], ans.values)}
	if rep == "diagram":
		out.graph = cuboid_figure(s, cuboid_labels(s), ["AG"])
		out.graph.faces = [["A", "B", "C", "D"]]
	return out


static func pyramid_lines(rep: String, s: Dictionary, extra: String = "") -> Array:
	var shape := "square" if s.l == s.w else "rectangular"
	if rep == "diagram":
		return [("The diagram shows a right pyramid VABCD with a %s base ABCD. The vertex V is directly above the centre X of the base." % shape) + extra]
	var u := unit_of(s, PYRAMIDS)
	var sides := "AB = BC = %d%s" % [s.l, u] if s.l == s.w else "AB = %d%s and BC = %d%s" % [s.l, u, s.w, u]
	return [("%s is a right pyramid VABCD. Its base ABCD is a %s with %s, and the vertex V is directly above the centre X of the base, with VX = %d%s." % [
		PYRAMIDS[s.ctx][0], "square" if s.l == s.w else "rectangle", sides, s.h, u]) + extra]


## The base diagonal through a corner.
static func diagonal_of(corner: String) -> String:
	return "AC" if corner in ["A", "C"] else "BD"


## The corner's place with D at the origin, DA along the x-axis and DC along the y-axis.
static func corner_at(s: Dictionary, corner: String) -> Array:
	return {"A": [s.w, 0], "B": [s.w, s.l], "C": [0, s.l], "D": [0, 0]}[corner]


func u_pyramid_edge_base(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var l: int = s.l
	var w: int = s.w
	var h: int = s.h
	var k: String = s.corner
	var base := l * l + w * w
	var xa := sqrt(float(base)) / 2.0
	var va2 := Q.new(base, 4).add(h * h)
	var va := sqrt(va2.to_float())
	var t: float = s.theta
	var ans := ang_ans("θ = ", t)
	var edge := "V" + k
	var dg := diagonal_of(k)
	# The slip's face: the slant height up the middle of a face at the corner.
	var face: float = (w if k in ["A", "B"] else l) / 2.0
	var along: float = (l if k in ["A", "B"] else w) / 2.0
	var wr: Array = bad(atan_d(h, face), R_SLANT) + bad(acos_d(along / va), R_EDGE) + bad(90.0 - t, R_VERTICAL) + bad(atan_d(h, va), R_FULL_RUN) \
		+ bad(atan_d(h, 2.0 * xa), R_WHOLE_DIAG)
	var out := {"lines": pyramid_lines(rep, s), "answer": ans, "wrongs": rng.shuffled(wr), "generic": gens([atan_d(h, l), atan_d(h, w), t + 10.0, t - 10.0]),
		"asked": sf3("Find the angle θ between the edge %s and the base ABCD." % edge)}
	var half := "%s = √(%s) = %s, and X is its midpoint, so X%s = %s." % [dg, sqsum([l, w]), root_eq(base), k, half_eq(base)]
	var see := "V is directly above X, so X%s is the projection of %s onto the base, and θ is angle V%sX." % [k, edge, k]
	var c := corner_at(s, k)
	var dx := Q.new(w, 2).sub(c[0])
	var dy := Q.new(l, 2).sub(c[1])
	out.methods = {
		"project-and-tan": method([see, half, "tan θ = VX ÷ X%s = %d ÷ %s." % [k, h, half_v(base)], last("tan⁻¹(%d ÷ %s)" % [h, half_v(base)], t, ans)], ans.values),
		"sin-with-length": method([half, "%s = √(X%s² + VX²) = √(%s ÷ 4 + %d²) = %s." % [edge, k, base, h, root_eq(va2)],
			"sin θ = VX ÷ %s = %d ÷ %s." % [edge, h, rv(va2)], last("sin⁻¹(%d ÷ %s)" % [h, rv(va2)], t, ans)], ans.values),
		"coordinates": method(["Put D at the origin with DA along the x-axis, DC along the y-axis and the height up the z-axis, so %s is (%d, %d, 0) and V is (%s, %s, %d)." % [
				k, c[0], c[1], Fmt.dec(Q.new(w, 2)), Fmt.dec(Q.new(l, 2)), h],
			"From %s to V the rise is Δz = %d and the run is √(Δx² + Δy²) = √(%s) = %s." % [k, h, _dec_sqsum([dx, dy]), root_eq(dx.sq().add(dy.sq()))],
			last("tan⁻¹(%d ÷ %s)" % [h, rv(dx.sq().add(dy.sq()))], t, ans)], ans.values)}
	if rep == "diagram":
		out.graph = pyramid_figure(s, pyramid_labels(s), [edge])
		out.graph.faces = [["A", "B", "C", "D"]]
	return out


## "2.5² + (−3)²" for exact decimals.
static func _dec_sqsum(vals: Array) -> String:
	return " + ".join(vals.map(func(v): return ("(%s)²" if v.sign() < 0 else "%s²") % Fmt.dec(v)))


func u_pyramid_face_base(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var l: int = s.l
	var w: int = s.w
	var h: int = s.h
	var e: String = s.edge
	var run := Q.new(w if e in ["AB", "CD"] else l, 2)
	var other := Q.new(l if e in ["AB", "CD"] else w, 2)
	var next_edge := "BC" if e in ["AB", "CD"] else "AB"
	var vm2 := run.sq().add(h * h)
	var t: float = s.theta
	var ans := ang_ans("θ = ", t)
	var base := l * l + w * w
	var wr: Array = bad(atan_d(h, sqrt(float(base)) / 2.0), R_SLANT) + bad(90.0 - t, R_VERTICAL) + bad(atan_d(h, sqrt(vm2.to_float())), R_FULL_RUN)
	if l != w:
		wr += bad(atan_d(h, other.to_float()), R_OTHER_HALF)
	var out := {"lines": pyramid_lines(rep, s, " M is the midpoint of %s." % e), "answer": ans, "wrongs": rng.shuffled(wr),
		"generic": gens([atan_d(h, run.to_float() * 2.0), t + 10.0, t - 10.0, 90.0 - t / 2.0]),
		"asked": sf3("Find the angle θ between the line VM and the base ABCD.")}
	var xm := "XM runs from the centre of the base to the middle of %s, parallel to %s, so XM = %d ÷ 2 = %s." % [e, next_edge, run.mul(2).n, Fmt.dec(run)]
	out.methods = {
		"project-and-tan": method(["V is directly above X, so XM is the projection of VM onto the base, and θ is angle VMX.", xm,
			"tan θ = VX ÷ XM = %d ÷ %s." % [h, Fmt.dec(run)], last("tan⁻¹(%d ÷ %s)" % [h, Fmt.dec(run)], t, ans)], ans.values),
		"sin-with-length": method([xm, "VM = √(XM² + VX²) = √(%s) = %s." % [_dec_sqsum([run, Q.new(h)]), root_eq(vm2)],
			"sin θ = VX ÷ VM = %d ÷ %s." % [h, rv(vm2)], last("sin⁻¹(%d ÷ %s)" % [h, rv(vm2)], t, ans)], ans.values)}
	if rep == "diagram":
		var p := box_pts(s, false)
		var a: Array = p[e[0]]
		var b: Array = p[e[1]]
		out.graph = pyramid_figure(s, pyramid_labels(s), ["VM"], {"M": [(a[0] + b[0]) / 2.0, (a[1] + b[1]) / 2.0, 0.0]})
		out.graph.faces = [["A", "B", "C", "D"]]
	return out


static func cone_lines(rep: String, s: Dictionary) -> Array:
	if rep == "diagram":
		return ["The diagram shows a cone with vertex V and base centre O. A is a point on the edge of its base, and V is directly above O."]
	var u := unit_of(s, CONES)
	var bits: Array = []
	if "r" in s.given:
		bits.append("its base radius is %d%s" % [s.r, u])
	if "h" in s.given:
		bits.append("its vertical height is %d%s" % [s.h, u])
	if "l" in s.given:
		bits.append("its slant height is %d%s" % [s.sl, u])
	return ["%s is a cone with vertex V directly above the centre O of its base: %s and %s. A is a point on the edge of the base." % [CONES[s.ctx][0], bits[0], bits[1]]]


func u_cone_slant_base(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := SolidAngleSituation.cone(s)
	var r: float = c[0]
	var h: float = c[1]
	var sl: float = c[2]
	var t: float = s.theta
	var ans := ang_ans("θ = ", t)
	var wr: Array = bad(atan_d(h, 2.0 * r), R_DIAMETER) + bad(90.0 - t, R_VERTICAL) + bad(atan_d(sl, r), R_SLANT_UP) + bad(atan_d(h, sl), R_FULL_RUN)
	var out := {"lines": cone_lines(rep, s), "answer": ans, "wrongs": rng.shuffled(wr), "generic": gens([t + 10.0, t - 10.0, t / 2.0, 90.0 - t / 2.0]),
		"asked": sf3("Find the angle θ between the slant height VA and the base of the cone.")}
	var see := "V is directly above O, so OA is the projection of VA onto the base, and θ is angle VAO, with its right angle at O."
	# Each side as a value in a sum, and the line that finds a missing one.
	var rt := str(s.r)
	var ht := str(s.h)
	var lt := str(s.sl)
	var find := ""
	match s.given:
		"rh":
			lt = rv(s.r * s.r + s.h * s.h)
			find = "VA = √(%s) = %s." % [sqsum([s.r, s.h]), root_eq(s.r * s.r + s.h * s.h)]
		"rl":
			ht = rv(s.sl * s.sl - s.r * s.r)
			find = "VO = √(%d² − %d²) = %s." % [s.sl, s.r, root_eq(s.sl * s.sl - s.r * s.r)]
		"hl":
			rt = rv(s.sl * s.sl - s.h * s.h)
			find = "OA = √(%d² − %d²) = %s." % [s.sl, s.h, root_eq(s.sl * s.sl - s.h * s.h)]
	var tan_steps: Array = [see]
	if s.given != "rh":
		tan_steps.append(find)
	tan_steps.append_array(["tan θ = VO ÷ OA = %s ÷ %s." % [ht, rt], last("tan⁻¹(%s ÷ %s)" % [ht, rt], t, ans)])
	var sin_steps: Array = [see]
	if s.given != "hl":
		sin_steps.append(find)
	sin_steps.append_array(["sin θ = VO ÷ VA = %s ÷ %s." % [ht, lt], last("sin⁻¹(%s ÷ %s)" % [ht, lt], t, ans)])
	out.methods = {"project-and-tan": method(tan_steps, ans.values), "sin-with-length": method(sin_steps, ans.values)}
	if rep == "diagram":
		out.graph = cone_figure(s, cone_labels(s))
	return out


static func points_lines(rep: String, s: Dictionary, names: Array, story: String) -> Array:
	match rep:
		"notation":
			var bits: Array = names.map(func(n): return "%s = %s" % [n.to_lower(), pt(s[n])])
			return ["Relative to the origin O, the points %s have position vectors %s." % [_and(names), _and(bits)]]
		"diagram":
			return ["The diagram shows the points %s on a set of axes." % _and(names)]
	var bits: Array = names.map(func(n): return n + pt(s[n]))
	return [story % _and(bits)]


static func _and(items: Array) -> String:
	if items.size() == 1:
		return items[0]
	return ", ".join(items.slice(0, -1)) + " and " + items[-1]


func u_coords_line_plane(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var d := SolidAngleSituation.minus(s.B, s.A)
	var run2: int = d[0] * d[0] + d[1] * d[1]
	var n := SolidAngleSituation.sq(d)
	var rise := absi(d[2])
	var t: float = s.theta
	var ans := ang_ans("θ = ", t)
	var story := "On a site plan with x-, y- and z-axes in metres, the ground is the xy-plane. %s runs straight between the points %%s." % RUNS[s.ctx]
	var lines := points_lines(rep, s, ["A", "B"], story)
	var wr: Array = bad(90.0 - t, R_VERTICAL) + bad(atan_d(rise, sqrt(float(n))), R_FULL_RUN) + bad(atan_d(rise, absf(d[0])), R_ONE_RUN)
	var out := {"lines": lines, "answer": ans, "wrongs": rng.shuffled(wr), "generic": gens([atan_d(rise, absf(d[1])), t + 10.0, t - 10.0, t / 2.0]),
		"asked": sf3("Find the angle θ between the line AB and the xy-plane.")}
	var moves := "From A to B: Δx = %s, Δy = %s and Δz = %s." % [N(d[0]), N(d[1]), N(d[2])]
	if rep == "notation":
		moves = "Subtract the position vectors: from A to B, Δx = %s, Δy = %s and Δz = %s." % [N(d[0]), N(d[1]), N(d[2])]
	out.methods = {
		"coordinates": method([moves, "The rise is |Δz| = %d, and the run across the xy-plane is √(Δx² + Δy²) = √(%s) = %s." % [rise, sqsum([d[0], d[1]]), root_eq(run2)],
			"tan θ = rise ÷ run = %d ÷ %s." % [rise, rv(run2)], last("tan⁻¹(%d ÷ %s)" % [rise, rv(run2)], t, ans)], ans.values),
		"sin-with-length": method([moves, "AB = √(%s) = %s." % [sqsum(d), root_eq(n)],
			"The rise is |Δz| = %d, so sin θ = rise ÷ AB = %d ÷ %s." % [rise, rise, rv(n)], last("sin⁻¹(%d ÷ %s)" % [rise, rv(n)], t, ans)], ans.values)}
	if rep == "diagram":
		out.graph = points_figure(["A", "B"], s, [line("A", "B", false, true)], true)
	return out


# ── Paper 1: a landmark angle ────────────────────────────────

## "4√3", "√3" or "4".
static func surd(m: int, r: int) -> String:
	return Answer.surd_text(m, r)


## A surd after ÷, bracketed when it has a number in front: "(4√2)".
static func wrap(m: int, r: int) -> String:
	return "(%s)" % surd(m, r) if m != 1 else surd(m, r)


func u_landmark_angle(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t := roundi(s.theta)
	var ans := Answer.make("number", {"v": Q.new(t)}, {}, "θ = ", "°")
	ans.exact = true
	var say := "So θ = %d°." % t
	var tan_steps: Array
	var sin_steps: Array
	var lines: Array
	var asked: String
	var g: Dictionary
	var vert := 90 - t
	var wr: Array = []
	match s.shape:
		"cone-rl", "cone-hl", "cone-rh":
			lines = cone_lines("diagram", s)
			asked = "Find the exact size of the angle θ between the slant height VA and the base of the cone."
			g = cone_figure(s, cone_labels(s))
			var k: int = s.r if s.shape != "cone-hl" else s.h
			var see := "V is directly above O, so OA is the projection of VA onto the base, and θ is angle VAO, with its right angle at O."
			match s.shape:
				"cone-rl":
					tan_steps = [see, "VO = √(%d² − %d²) = √%d = %s." % [s.sl, k, 3 * k * k, surd(k, 3)], "tan θ = VO ÷ OA = %s ÷ %d = √3. %s" % [surd(k, 3), k, say]]
					sin_steps = [see, "VO = √(%d² − %d²) = √%d = %s." % [s.sl, k, 3 * k * k, surd(k, 3)], "sin θ = VO ÷ VA = %s ÷ %d = √3 ÷ 2. %s" % [surd(k, 3), s.sl, say]]
				"cone-hl":
					tan_steps = [see, "OA = √(%d² − %d²) = √%d = %s." % [s.sl, k, 3 * k * k, surd(k, 3)], "tan θ = VO ÷ OA = %d ÷ %s = 1 ÷ √3. %s" % [k, wrap(k, 3), say]]
					sin_steps = [see, "sin θ = VO ÷ VA = %d ÷ %d = 1 ÷ 2. %s" % [k, s.sl, say]]
				_:
					tan_steps = [see, "tan θ = VO ÷ OA = %d ÷ %d = 1. %s" % [k, k, say]]
					sin_steps = [see, "VA = √(%d² + %d²) = √%d = %s." % [k, k, 2 * k * k, surd(k, 2)], "sin θ = VO ÷ VA = %d ÷ %s = 1 ÷ √2. %s" % [k, wrap(k, 2), say]]
			if vert != t:
				wr.append(wrong({"v": Q.new(vert)}, R_VERTICAL))
		"cuboid":
			lines = cuboid_lines("diagram", s)
			asked = "Find the exact size of the angle θ between the diagonal AG and the base ABCD."
			g = cuboid_figure(s, cuboid_labels(s), ["AG"])
			g.faces = [["A", "B", "C", "D"]]
			var see := "G is directly above C, so AC is the projection of AG onto the base, and θ is angle GAC."
			tan_steps = [see, "AC = √(%s) = √%d = %d." % [sqsum([s.l, s.w]), s.h * s.h, s.h], "tan θ = CG ÷ AC = %d ÷ %d = 1. %s" % [s.h, s.h, say]]
			sin_steps = [see, "AG = √(%s) = √%d = %s." % [sqsum([s.l, s.w, s.h]), 2 * s.h * s.h, surd(s.h, 2)],
				"sin θ = CG ÷ AG = %d ÷ %s = 1 ÷ √2. %s" % [s.h, wrap(s.h, 2), say]]
		_:
			lines = ["The diagram shows a right pyramid VABCD with a square base ABCD. The vertex V is directly above the centre X of the base, and every edge of the pyramid has the same length."]
			var k: String = s.corner
			var edge := "V" + k
			var a: int = s.l
			var half: int = a / 2
			asked = "Find the exact size of the angle θ between the edge %s and the base ABCD." % edge
			var labels := pyramid_labels(s)
			labels.erase("VX")
			labels[edge] = "%d%s" % [a, unit_of(s, PYRAMIDS)]
			g = pyramid_figure(s, labels, [edge])
			g.faces = [["A", "B", "C", "D"]]
			var see := "V is directly above X, so X%s is the projection of %s onto the base, and θ is angle V%sX." % [k, edge, k]
			var dg := diagonal_of(k)
			var first := "%s = √(%d² + %d²) = √%d = %s, so X%s = %s." % [dg, a, a, 2 * a * a, surd(a, 2), k, surd(half, 2)]
			var vx := "VX = √(%d² − (%s)²) = √%d = %s." % [a, surd(half, 2), 2 * half * half, surd(half, 2)]
			tan_steps = [see, first, vx, "tan θ = VX ÷ X%s = %s ÷ %s = 1. %s" % [k, surd(half, 2), wrap(half, 2), say]]
			sin_steps = [see, first, vx, "sin θ = VX ÷ %s = %s ÷ %d = √2 ÷ 2. %s" % [edge, surd(half, 2), a, say]]
	var gen: Array = []
	for x in [30, 45, 60, 90]:
		if x != t:
			gen.append({"v": Q.new(x)})
	var out := {"lines": lines, "answer": ans, "wrongs": wr, "generic": gen, "asked": asked, "graph": g,
		"methods": {"project-and-tan": method(tan_steps, ans.values), "sin-with-length": method(sin_steps, ans.values)}}
	return out


# ── Two lines ────────────────────────────────────────────────

## The diagonals that meet at M, and the angle between them: by the edge of triangle AM?.
const DIAGONALS := {"AB": ["AG", "BH", "AMB", "B"], "AD": ["AG", "DF", "AMD", "D"], "AE": ["AG", "EC", "AME", "E"]}


func u_cuboid_two_diagonals(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var l: int = s.l
	var w: int = s.w
	var h: int = s.h
	var e: int = SolidAngleSituation.edge_len(s)
	var info: Array = DIAGONALS[s.edge]
	var other: String = info[1]
	var name: String = info[2]
	var corner: String = info[3]
	var n := l * l + w * w + h * h
	var q := Q.new(n, 4)
	var t: float = s.theta
	var ans := ang_ans("angle %s = " % name, t)
	var lines := cuboid_lines(rep, s)
	lines.append("The diagonals AG and %s meet at M." % other)
	var d := sqrt(float(n))
	var f2: int = l * l + (w * w if s.edge != "AE" else h * h)
	var no_two := (2.0 * q.to_float() - e * e) / q.to_float()
	# A right angle where the diagonals cross is what a drawing seems to show.
	var wr: Array = ([wrong({"v": GdcKit.qf(90.0)}, R_LOOKS_RIGHT)] if rep == "diagram" else []) + bad(acos_d(1.0 - 2.0 * e * e / float(f2)), R_FACE_DIAG) + bad(acos_d(e / d), R_OPPOSITE) \
		+ bad(t / 2.0, R_HALF_ANGLE) + bad(acos_d(1.0 - e * e / (2.0 * n)), R_WHOLE_SPACE) + bad(acos_d(no_two), R_NO_TWO)
	if t > 90.0:
		wr += bad(180.0 - t, R_ACUTE)
	var out := {"lines": lines, "answer": ans, "wrongs": rng.shuffled(wr), "generic": gens([t + 10.0, t - 10.0, 180.0 - t / 2.0, t * 1.5]),
		"asked": sf3("Find the size of angle %s." % name)}
	var ag := "AG = √(%s) = %s, and the diagonals cut each other in half at M, so AM = %sM = %s." % [sqsum([l, w, h]), root_eq(n), corner, half_eq(n)]
	var opp := "A%s" % corner
	out.methods = {
		"three-sides-cosine": method([ag, "Triangle %s has AM² = %sM² = %d ÷ 4 = %s, and %s = %d is opposite the angle at M." % [name, corner, n, Fmt.dec(q), opp, e],
			"cos %s = (AM² + %sM² − %s²) ÷ (2 × AM × %sM) = (%s + %s − %d²) ÷ (2 × %s)." % [name, corner, opp, corner, Fmt.dec(q), Fmt.dec(q), e, Fmt.dec(q)],
			last("cos⁻¹((%s + %s − %d²) ÷ (2 × %s))" % [Fmt.dec(q), Fmt.dec(q), e, Fmt.dec(q)], t, ans)], ans.values),
		"isosceles-split": method([ag, "Triangle %s is isosceles, so the line from M to the middle of %s cuts it into two right-angled halves, each with half of %s, %d ÷ 2, opposite half of the angle at M." % [
				name, opp, opp, e],
			"sin(%s ÷ 2) = (%d ÷ 2) ÷ %s." % [name, e, half_v(n)], last("2 × sin⁻¹((%d ÷ 2) ÷ %s)" % [e, half_v(n)], t, ans)], ans.values)}
	if rep == "diagram":
		var g := cuboid_figure(s, cuboid_labels(s), ["AG", other], {"M": [w / 2.0, l / 2.0, h / 2.0]})
		g.angles = [{"at": "M", "from": "A", "to": corner, "label": "?"}]
		out.graph = g
	return out


func u_pyramid_apex_angle(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var l: int = s.l
	var w: int = s.w
	var h: int = s.h
	var pair: String = s.pair
	var base := l * l + w * w
	var va2 := Q.new(base, 4).add(h * h)
	var va := sqrt(va2.to_float())
	var side2 := SolidAngleSituation.apex_side_sq(s)
	var side := sqrt(float(side2))
	var t: float = s.theta
	var ans := ang_ans("angle %s = " % pair, t)
	var opp := pair[0] + pair[2]
	var e1 := "V" + pair[0]
	var e2 := "V" + pair[2]
	var no_two := (2.0 * va2.to_float() - side2) / va2.to_float()
	# A right angle at the base corner is what a drawing seems to show.
	var wr: Array = (bad(atan_d(side, va), R_LOOKS_RIGHT) if rep == "diagram" else []) + bad(acos_d(side / 2.0 / va), R_OPPOSITE) + bad(t / 2.0, R_HALF_ANGLE) + bad(acos_d(no_two), R_NO_TWO) \
		+ bad(2.0 * asin_d(side / 2.0 / h), R_HEIGHT_EDGE)
	var out := {"lines": pyramid_lines(rep, s), "answer": ans, "wrongs": rng.shuffled(wr), "generic": gens([t + 10.0, t - 10.0, 180.0 - t, t * 1.5]),
		"asked": sf3("Find the size of angle %s." % pair)}
	var edge := "%s = √(%s) = %s, and X is its middle, so XA = %s. Then VA = √(XA² + VX²) = √(%d ÷ 4 + %d²) = %s, and every slant edge has this length." % [
		"AC", sqsum([l, w]), root_eq(base), half_eq(base), base, h, root_eq(va2)]
	var opp_text := "%s = %d" % [opp, roundi(side)] if pair != "AVC" else "AC = %s" % rv(base)
	var half_side := "%d ÷ 2" % roundi(side) if pair != "AVC" else "(%s ÷ 2)" % rv(base)
	var side_sq := "%d²" % roundi(side) if pair != "AVC" else str(base)
	out.methods = {
		"isosceles-split": method([edge, "Triangle %s is isosceles with %s = %s and %s, so the line from V to the middle of %s cuts it into two right-angled halves, with half of %s opposite half of the angle at V." % [
				pair, e1, e2, opp_text, opp, opp],
			"sin(%s ÷ 2) = (%s) ÷ %s." % [pair, half_side.trim_prefix("(").trim_suffix(")"), rv(va2)],
			last("2 × sin⁻¹((%s) ÷ %s)" % [half_side.trim_prefix("(").trim_suffix(")"), rv(va2)], t, ans)], ans.values),
		"three-sides-cosine": method([edge, "In triangle %s, %s is opposite the angle at V, so cos %s = (%s² + %s² − %s²) ÷ (2 × %s × %s)." % [pair, opp_text, pair, e1, e2, opp, e1, e2],
			last("cos⁻¹((%s + %s − %s) ÷ (2 × %s))" % [Fmt.dec(va2), Fmt.dec(va2), side_sq, Fmt.dec(va2)], t, ans)], ans.values)}
	if rep == "diagram":
		var g := pyramid_figure(s, pyramid_labels(s), [e1, e2])
		g.angles = [{"at": "V", "from": pair[0], "to": pair[2], "label": "?"}]
		if pair == "AVC":
			g.lines.append(line("A", "C", true))
		out.graph = g
	return out


## The right angle of triangle GA? for each edge: where it is, the face that holds the other
## leg, and the leg.
const EDGE_RIGHT := {"AB": ["B", "BCGF", "BG"], "AD": ["D", "DCGH", "DG"], "AE": ["E", "EFGH", "EG"]}


func u_cuboid_diagonal_edge(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var l: int = s.l
	var w: int = s.w
	var h: int = s.h
	var info: Array = EDGE_RIGHT[s.edge]
	var at: String = info[0]
	var leg: String = info[2]
	var e: int = SolidAngleSituation.edge_len(s)
	var legs: Array = {"AB": [w, h], "AD": [l, h], "AE": [l, w]}[s.edge]
	var f2: int = legs[0] * legs[0] + legs[1] * legs[1]
	var n := l * l + w * w + h * h
	var d := sqrt(float(n))
	var t: float = s.theta
	var name: String = "G" + str(s.edge)
	var ans := ang_ans("angle %s = " % name, t)
	var face2: int = l * l + (w * w if s.edge != "AE" else h * h)
	var wr: Array = bad(acos_d(e / sqrt(float(face2))), R_FACE_DIAG) + bad(90.0 - t, R_OPPOSITE) + bad(atan_d(sqrt(float(f2)), d), R_TAN_HYP)
	if s.edge != "AE":
		wr += bad(atan_d(h, sqrt(float(l * l + w * w))), R_TO_BASE)
	var lines := cuboid_lines(rep, s)
	var out := {"lines": lines, "answer": ans, "wrongs": rng.shuffled(wr), "generic": gens([t + 10.0, t - 10.0, t / 2.0, 90.0 - t / 2.0]),
		"asked": sf3("Find the size of angle %s, between the diagonal AG and the edge %s." % [name, s.edge])}
	var ag := "AG = √(%s) = %s." % [sqsum([l, w, h]), root_eq(n)]
	out.methods = {
		"spot-right-angle": method(["%s is at right angles to the face %s, which holds %s, so angle A%sG = 90°." % [s.edge, info[1], leg, at], ag,
			"cos %s = %s ÷ AG = %d ÷ %s." % [name, s.edge, e, rv(n)], last("cos⁻¹(%d ÷ %s)" % [e, rv(n)], t, ans)], ans.values),
		"three-sides-cosine": method([ag, "%s is a diagonal of a face, so %s = √(%s) = %s." % [leg, leg, sqsum(legs), root_eq(f2)],
			"%s is opposite the angle at A, so cos %s = (%s² + AG² − %s²) ÷ (2 × %s × AG)." % [leg, name, s.edge, leg, s.edge],
			last("cos⁻¹((%d² + %d − %d) ÷ (2 × %d × %s))" % [e, n, f2, e, rv(n)], t, ans)], ans.values)}
	if rep == "diagram":
		var g := cuboid_figure(s, cuboid_labels(s), ["AG", s.edge])
		g.angles = [{"at": "A", "from": "G", "to": s.edge[1], "label": "?"}]
		out.graph = g
	return out


## AB², BC² and AC² with their squares: "AB² = 3² + 4² + (−2)² = 29".
static func side_sq_text(s: Dictionary, a: String, b: String) -> String:
	var d := SolidAngleSituation.minus(s[b], s[a])
	return "%s%s² = %s = %d" % [a, b, sqsum(d), SolidAngleSituation.sq(d)]


func u_coords_angle_abc(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var p := SolidAngleSituation.sq(SolidAngleSituation.minus(s.A, s.B))
	var q := SolidAngleSituation.sq(SolidAngleSituation.minus(s.C, s.B))
	var r := SolidAngleSituation.sq(SolidAngleSituation.minus(s.C, s.A))
	var t: float = s.theta
	var ans := ang_ans("angle ABC = ", t)
	var story := "%s are at the points %%s." % THREE[s.ctx]
	var lines := points_lines(rep, s, ["A", "B", "C"], story)
	var at_a := SolidAngleSituation.angle_at(s.B, s.A, s.C)
	var at_c := SolidAngleSituation.angle_at(s.A, s.C, s.B)
	var no_two := (p + q - r) / sqrt(float(p) * float(q))
	var wr: Array = bad(rng.pick([at_a, at_c]), R_OPPOSITE) + bad(acos_d(no_two), R_NO_TWO)
	if t > 90.0:
		wr += bad(180.0 - t, R_ACUTE)
	var out := {"lines": lines, "answer": ans, "wrongs": rng.shuffled(wr), "generic": gens([at_a, at_c, t + 10.0, t - 10.0, 180.0 - t]),
		"asked": sf3("Find the size of angle ABC.")}
	var sides := "%s, %s and %s." % [side_sq_text(s, "A", "B"), side_sq_text(s, "B", "C"), side_sq_text(s, "A", "C")]
	out.methods = {"three-sides-cosine": method(["The squares of the sides: " + sides,
		"AC is opposite angle ABC, so cos ABC = (AB² + BC² − AC²) ÷ (2 × AB × BC).",
		last("cos⁻¹((%d + %d − %d) ÷ (2 × %s × %s))" % [p, q, r, rv(p), rv(q)], t, ans)], ans.values)}
	if rep == "diagram":
		var g := points_figure(["A", "B", "C"], s, [line("A", "B", false, true), line("B", "C", false, true), line("A", "C")], false)
		g.angles = [{"at": "B", "from": "A", "to": "C", "label": "?"}]
		out.graph = g
	return out


func u_coords_right_angle(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var p := SolidAngleSituation.sq(SolidAngleSituation.minus(s.A, s.B))
	var q := SolidAngleSituation.sq(SolidAngleSituation.minus(s.C, s.B))
	var r := SolidAngleSituation.sq(SolidAngleSituation.minus(s.C, s.A))
	var t: float = s.theta
	var ans := ang_ans("angle ABC = ", t)
	var story := "%s are at the points %%s." % THREE[s.ctx]
	var lines := points_lines(rep, s, ["A", "B", "C"], story)
	# The right angle's vertex P: its two sides, and the hypotenuse from B.
	var at: String = s.right
	var near := p if at == "A" else q
	var far := r
	var hyp := q if at == "A" else p
	var near_name := "AB" if at == "A" else "BC"
	var hyp_name := "BC" if at == "A" else "AB"
	var no_two := (p + q - r) / sqrt(float(p) * float(q))
	var wr: Array = bad(90.0 - t, R_OPPOSITE) + bad(atan_d(sqrt(float(far)), sqrt(float(hyp))), R_TAN_HYP) + bad(acos_d(no_two), R_NO_TWO)
	var out := {"lines": lines, "answer": ans, "wrongs": rng.shuffled(wr), "generic": gens([t + 10.0, t - 10.0, t / 2.0, 90.0 - t / 2.0]),
		"asked": sf3("Find the size of angle ABC.")}
	var sides := "%s, %s and %s." % [side_sq_text(s, "A", "B"), side_sq_text(s, "B", "C"), side_sq_text(s, "A", "C")]
	var sum_names := "AB² + AC²" if at == "A" else "BC² + AC²"
	out.methods = {
		"spot-right-angle": method(["The squares of the sides: " + sides,
			"%s = %d + %d = %d = %s², so the triangle has its right angle at %s, and %s is the hypotenuse." % [sum_names, near, far, hyp, hyp_name, at, hyp_name],
			"cos ABC = %s ÷ %s = %s ÷ %s." % [near_name, hyp_name, rv(near), rv(hyp)], last("cos⁻¹(%s ÷ %s)" % [rv(near), rv(hyp)], t, ans)], ans.values),
		"three-sides-cosine": method(["The squares of the sides: " + sides,
			"AC is opposite angle ABC, so cos ABC = (AB² + BC² − AC²) ÷ (2 × AB × BC).",
			last("cos⁻¹((%d + %d − %d) ÷ (2 × %s × %s))" % [p, q, r, rv(p), rv(q)], t, ans)], ans.values)}
	if rep == "diagram":
		var g := points_figure(["A", "B", "C"], s, [line("A", "B", false, true), line("B", "C", false, true), line("A", "C")], false)
		g.angles = [{"at": "B", "from": "A", "to": "C", "label": "?"}]
		out.graph = g
	return out
