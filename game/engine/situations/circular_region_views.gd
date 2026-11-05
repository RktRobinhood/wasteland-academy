class_name CircularRegionViews
extends ExtensionViews
## The views on the `circular-region` situation: one builder per unknown of
## t3-composite-circular-region (FAL-739). Sums and differences of sectors, triangles, rectangles
## and circles, and sectors fixed by two conditions. Paper 2 answers are numbers to 3 s.f.; an
## answer in letters, and every Paper 1 answer, is a `form`.
##
## Representations: "diagram" (the region drawn to its real shape and shaded, by RegionPlot, or by
## PlotView's `sector`), "equation" (the conditions listed) and "words" (a story).

const SKILL := "SL3.4."
const R_SIN_DEG := SKILL + "segment-shaded#0"
const R_RADII := SKILL + "segment-shaded#1"
const R_SECTOR := SKILL + "segment-shaded#3"
const R_JOIN := SKILL + "segment-shaded#4"
const R_TAN_ANGLE := SKILL + "segment-shaded#5"
const R_RATIO := SKILL + "segment-shaded#6"
const R_DIAMETER := SKILL + "segment-shaded#7"
const R_NO_TRIANGLE := SKILL + "segment-shaded#8"
const R_ARC_DEG := SKILL + "arc-length#0"
const R_MINOR := SKILL + "sector-area#2"
const R_NO_RADII := SKILL + "sector-two-conditions#0"
const R_BIG_THETA := SKILL + "sector-two-conditions#1"
const R_ONE_ROOT := SKILL + "sector-two-conditions#2"
const R_DEG_SECTOR := "t3-composite-circular-region#13"
const R_ANY_SINE := "t3-composite-circular-region#14"

## A circle cut by a straight line: the thing, the line, and the part behind it.
const SEG_STORIES := [
	{"thing": "The floor of a round silo", "line": "wall", "part": "grain bay"},
	{"thing": "A round pond at the bean farm", "line": "dam", "part": "fish pen"},
	{"thing": "A round camp on the flats", "line": "fence", "part": "goat yard"},
]

const UNKNOWNS := ["segment-area", "segment-exact", "segment-perimeter", "segment-in-terms-of-theta", "segment-radius",
	"tether-area", "tether-expression", "tether-angle", "ratio-equation", "ratio-theta", "ratio-radius", "arch-area",
	"ring-area", "ring-expression", "hatch-area", "hatch-height", "tangent-region", "tangent-expression",
	"theta-in-r", "two-conditions-quadratic", "two-conditions-r", "two-conditions-theta", "two-conditions-both",
	"arc-area-radius", "cone-from-area"]
## Paper 1 as well: the sector from two conditions, as in the bank.
const BOTH_PAPERS := ["theta-in-r", "two-conditions-quadratic", "two-conditions-r", "two-conditions-theta", "two-conditions-both", "arc-area-radius"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## An exact landmark segment is Paper 1, a GDC is Paper 2, and the rest are Paper 2 as in the bank.
func papers(unknown: String, _rep: String, method_id: String) -> Array:
	if not has(unknown):
		return []
	if unknown == "segment-exact":
		return [1]
	if unknown in BOTH_PAPERS and method_id != "gdc-intersection":
		return [1, 2]
	return [2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = CircularRegionSituation.export(s)
	return out


# ── Numbers ──────────────────────────────────────────────────

static func rad(s: Dictionary) -> float:
	return ArcSectorViews.radians(s)


## A float as a value: [a, 0].
static func val(x: float) -> Array:
	return ArcSectorViews.ab(GdcKit.qf(x))


## A value in the working, to 5 figures.
static func w(x: float) -> String:
	return Fmt.work(x, 5)


## That value as a number, so the next step works from what is on the page.
static func rd(x: float) -> float:
	return float(w(x))


static func sin_deg(x: float) -> float:
	return sin(deg_to_rad(x))


static func num(s: Dictionary, label: String, x: float, tail: String) -> Dictionary:
	return ArcSectorViews.ans_of(s, label, val(x), tail)


static func slip(ans: Dictionary, s: Dictionary, x: float, ref: String) -> Array:
	return ArcSectorViews.like(ans, s, val(x), ref)


static func rest(ans: Dictionary, s: Dictionary, xs: Array) -> Array:
	return ArcSectorViews.others(ans, s, xs.map(func(x): return val(x)))


## The units: a story in metres, a labelled figure in centimetres.
static func U(s: Dictionary) -> String:
	return " m" if s.rep == "words" or s.ask.begins_with("tether") or s.ask.begins_with("hatch") else " cm"


static func U2(s: Dictionary) -> String:
	return U(s) + "²"


static func Rt(s: Dictionary) -> String:
	return ArcSectorViews.R(s)


## "sin 1.2", or "sin 73°": the angle as a calculator takes it.
static func sin_text(s: Dictionary) -> String:
	return "sin " + ArcSectorViews.angle_text(s)


## The size of θ the working uses: as given in radians, to 5 figures from degrees.
static func th_shown(s: Dictionary) -> float:
	return s.t.to_float() if s.form == "rad" else rd(rad(s))


## An angle given in radians, in words: "1 radian", "1.25 radians".
static func rad_words(t: Q) -> String:
	return Fmt.dec(t) + (" radian" if t.eq(Q.new(1)) else " radians")


static func in_radians(s: Dictionary) -> String:
	return "" if s.form == "deg" else " Angle AOB is in radians."


# ── What the student is shown ────────────────────────────────

static func region(shape: String, s: Dictionary, over: Dictionary = {}) -> Dictionary:
	var out := {"kind": "region", "shape": shape, "theta": rad(s), "r_label": "", "angle_label": ""}
	out.merge(over, true)
	return out


## A segment of a circle: in a story, or drawn.
static func seg_view(rep: String, s: Dictionary, what: String) -> Dictionary:
	var r := Rt(s) + U(s)
	if rep == "words":
		var c: Dictionary = SEG_STORIES[s.ctx]
		return {"lines": ["%s has radius %s. A straight %s joins points A and B on its edge, and angle AOB at the centre O is %s. The smaller part, behind the %s, is the %s." % [c.thing, r, c.line, ArcSectorViews.angle_words(s), c.line, c.part]],
			"graph": null, "asked": "Find the %s of the %s." % [what, c.part]}
	return {"lines": ["The diagram shows sector OAB of a circle with centre O. Chord AB cuts off the shaded segment." + in_radians(s)],
		"graph": region("segment", s, {"r_label": r, "angle_label": ArcSectorViews.angle_text(s)}), "asked": "Find the %s of the shaded segment." % what}


static func frame(v: Dictionary, s: Dictionary, ans: Dictionary, asked: String = "") -> Dictionary:
	return {"lines": v.lines, "graph": v.graph, "table": null, "answer": ans, "asked": ArcSectorViews.finish(s, asked if asked != "" else v.asked, ans)}


# ── Segments ─────────────────────────────────────────────────

func u_segment_area(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rr: float = s.r.to_float()
	var th := rad(s)
	var half := rr * rr / 2.0
	var ans := num(s, "A = ", half * (th - sin(th)), U2(s))
	var out := frame(seg_view(rep, s, "area"), s, ans)
	out.wrongs = slip(ans, s, half * th, R_SECTOR)
	if s.form == "rad":
		out.wrongs += slip(ans, s, half * (th - sin_deg(th)), R_SIN_DEG)
	else:
		out.wrongs += slip(ans, s, half * (s.t.to_float() - sin(th)), R_DEG_SECTOR)
	out.generic = rest(ans, s, [half * sin(th), half * (th + sin(th)), rr * rr * (th - sin(th)), rr * (th - sin(th)) / 2.0, half * (th - sin(th)) * 2.0])
	var r := Rt(s)
	var t := th_shown(s)
	var sec := rd(half * t)
	var tri := rd(half * sin(th))
	out.methods = {"sector-minus-triangle": method(ArcSectorViews.to_rad(s) + ["Sector: ½ × %s² × %s = %s" % [r, w(t), w(sec)],
		"Triangle: ½ × %s² × %s = %s" % [r, sin_text(s), w(tri)], "Segment: %s − %s = %s" % [w(sec), w(tri), w(sec - tri)], ArcSectorViews.say(ans)], ans.values)}
	return out


## The exact pieces of a landmark segment: b in bπ, c and whether it carries √3.
static func exact_parts(s: Dictionary) -> Dictionary:
	var half: Q = s.r.sq().div(2)
	var surd: bool = s.t.d == 3
	var sn: Q = Q.new(1) if s.t.d == 2 else Q.new(1, 2)
	return {"b": half.mul(s.t), "c": half.mul(sn), "surd": surd, "half": half, "sin": "√3/2" if surd else ("1" if s.t.d == 2 else "1/2")}


func u_segment_exact(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var e := exact_parts(s)
	var u := U2(s)
	var b := Fmt.pi(e.b)
	var c := Fmt.dec(e.c)
	var root := "√3" if e.surd else ""
	var parts: Array = ["A = ", {"slot": "b"}, "π − ", {"slot": "c"}, root + u]
	var ans := DifferentiationViews.form("A = %s − %s%s%s" % [b, c, root, u], parts, {"b": e.b, "c": e.c})
	var v := seg_view("diagram", s, "exact area")
	var out := {"table": null, "answer": ans, "lines": v.lines, "graph": v.graph, "asked": v.asked}
	out.wrongs = [DifferentiationViews.alt("A = %s%s" % [b, u], R_SECTOR)]
	var half_b: Q = e.b.mul(Q.new(1, 2))
	out.generic = [DifferentiationViews.alt("A = %s + %s%s%s" % [b, c, root, u]).values,
		DifferentiationViews.alt("A = %s%s%s" % [c, root, u]).values,
		DifferentiationViews.alt("A = %s − %s%s%s" % [Fmt.pi(half_b), c, root, u], "", {"b": half_b, "c": e.c}).values,
		DifferentiationViews.alt("A = %s − %s%s%s" % [Fmt.pi(e.b.mul(2)), Fmt.dec(e.c.mul(2)), root, u], "", {"b": e.b.mul(2), "c": e.c.mul(2)}).values,
		DifferentiationViews.alt("A = %s − %s%s%s" % [b, Fmt.dec(e.c.mul(2)), root, u], "", {"b": e.b, "c": e.c.mul(2)}).values]
	var r := Fmt.dec(s.r)
	var t := ArcSectorViews.angle_text(s)
	out.methods = {"sector-minus-triangle": method(["Sector: ½ × %s² × %s = %s" % [r, t, b], "sin %s = %s" % [t, e.sin],
		"Triangle: ½ × %s² × %s = %s%s" % [r, e.sin, c, root], ArcSectorViews.say(ans)], ans.values)}
	return out


func u_segment_perimeter(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rr: float = s.r.to_float()
	var th := rad(s)
	var arc := rr * th
	var chord := 2.0 * rr * sin(th / 2.0)
	var ans := num(s, "P = ", arc + chord, U(s))
	var out := frame(seg_view(rep, s, "perimeter"), s, ans)
	out.wrongs = slip(ans, s, arc + 2.0 * rr, R_RADII)
	if s.form == "rad":
		out.wrongs += slip(ans, s, arc + 2.0 * rr * sin_deg(th / 2.0), R_ANY_SINE)
	else:
		out.wrongs += slip(ans, s, rr * s.t.to_float() + chord, R_ARC_DEG)
	out.generic = rest(ans, s, [arc, chord, arc + chord + 2.0 * rr, arc + 2.0 * chord, arc + rr * sin(th / 2.0)])
	var r := Rt(s)
	var t := th_shown(s)
	var half_text: String = Fmt.dec(s.t.div(2)) + ("°" if s.form == "deg" else "")
	var a2 := rd(rr * t)
	var c2 := rd(chord)
	out.methods = {"chord-length": method(ArcSectorViews.to_rad(s) + ["Arc: l = rθ = %s × %s = %s" % [r, w(t), w(a2)], "Chord: 2r sin(θ/2) = 2 × %s × sin %s = %s" % [r, half_text, w(c2)],
		"P = %s + %s = %s" % [w(a2), w(c2), w(a2 + c2)], ArcSectorViews.say(ans)], ans.values)}
	return out


func u_segment_in_terms_of_theta(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Q = s.r.sq().div(2)
	var at := Fmt.dec(a)
	var u := U2(s)
	var ans := DifferentiationViews.form("A = %sθ − %s sin θ%s" % [at, at, u], ["A = ", {"slot": "a"}, "θ − ", {"slot": "b"}, " sin θ" + u], {"a": a, "b": a})
	var out := {"table": null, "answer": ans, "asked": "Find the area of the shaded segment in terms of θ."}
	out.lines = ["A and B lie on a circle with centre O and radius %s. Chord AB cuts off the shaded segment, and angle AOB is θ radians, where 0 < θ < π." % (Fmt.dec(s.r) + " cm")]
	out.graph = region("segment", s, {"r_label": Fmt.dec(s.r) + " cm", "angle_label": "θ"})
	out.wrongs = [DifferentiationViews.alt("A = %sθ%s" % [at, u], R_SECTOR)]
	var dbl := Fmt.dec(a.mul(2))
	var rt := Fmt.dec(s.r)
	out.generic = [DifferentiationViews.alt("A = %sθ + %s sin θ%s" % [at, at, u]).values,
		DifferentiationViews.alt("A = %s sin θ%s" % [at, u]).values,
		DifferentiationViews.alt("A = %sθ − %s sin θ%s" % [dbl, dbl, u], "", {"a": a.mul(2), "b": a.mul(2)}).values,
		DifferentiationViews.alt("A = %sθ − %s sin θ%s" % [Fmt.dec(s.r.div(2)), Fmt.dec(s.r.div(2)), u], "", {"a": s.r.div(2), "b": s.r.div(2)}).values]
	out.methods = {"sector-minus-triangle": method(["Sector: ½ × %s² × θ = %sθ" % [rt, at], "Triangle: ½ × %s² × sin θ = %s sin θ" % [rt, at],
		"The segment is the sector less the triangle.", ArcSectorViews.say(ans)], ans.values)}
	return out


func u_segment_radius(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: float = s.t.to_float()
	var a: float = s.area[0].to_float()
	var size := t - sin(t)
	var ans := num(s, "r = ", sqrt(2.0 * a / size), " cm")
	var at := Fmt.dec(s.area[0])
	var v := {"lines": ["The diagram shows sector OAB of a circle with centre O and radius r. Chord AB cuts off the shaded segment, and angle AOB is in radians.", "The area of the segment is %s cm²." % at],
		"graph": region("segment", s, {"r_label": "r", "angle_label": Fmt.dec(s.t)})}
	var out := frame(v, s, ans, "Find r.")
	out.wrongs = slip(ans, s, sqrt(2.0 * a / t), R_SECTOR) + slip(ans, s, sqrt(2.0 * a / (t - sin_deg(t))), R_SIN_DEG)
	out.generic = rest(ans, s, [2.0 * a / size, sqrt(a / size), sqrt(2.0 * a / sin(t)), sqrt(2.0 * a / (t + sin(t))), 2.0 * sqrt(2.0 * a / size)])
	var inside := rd(size)
	var sq := rd(2.0 * a / inside)
	out.methods = {"sector-minus-triangle": method(["The segment is ½r²(θ − sin θ), so ½r²(%s − sin %s) = %s." % [Fmt.dec(s.t), Fmt.dec(s.t), at],
		"%s − sin %s = %s, in radians." % [Fmt.dec(s.t), Fmt.dec(s.t), w(inside)], "r² = 2 × %s ÷ %s = %s" % [at, w(inside), w(sq)], "r = √%s = %s" % [w(sq), w(sqrt(sq))], ArcSectorViews.say(ans)], ans.values)}
	return out


# ── Tethers: a sector and a triangle ─────────────────────────

const WALLS := "Two straight walls meet at A. A rover is tied by a cable to a stake O on one wall, with OA = OD = OE, where D is further along that wall and E is on the other wall."


static func tether_figure(s: Dictionary, over: Dictionary) -> Dictionary:
	return region("tether", s, over)


func u_tether_area(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rr: float = s.r.to_float()
	var t: float = s.t.to_float()
	var half := rr * rr / 2.0
	var ans := num(s, "A = ", half * (t + sin(t)), U2(s))
	var r := Rt(s)
	var ts := Fmt.dec(s.t)
	var out := {"table": null, "answer": ans, "graph": null}
	if rep == "words":
		out.lines = ["Two straight walls meet at a corner A. A rover is tied to a stake O on one wall by a cable %s long, and the stake is %s from A. Stretched out, the cable reaches D further along that wall and E on the other wall, and angle DOE is %s." % [r + U(s), r + U(s), rad_words(s.t)]]
		out.asked = ArcSectorViews.finish(s, "Find the area of the ground between the walls that the rover can reach.", ans)
	else:
		out.lines = [WALLS + " OA = %s and angle DOE is %s." % [r + U(s), rad_words(s.t)], "The rover can reach the shaded ground: sector ODE and triangle OEA."]
		out.graph = tether_figure(s, {"r_label": r + U(s), "angle_label": ts})
		out.asked = ArcSectorViews.finish(s, "Find the area the rover can reach.", ans)
	out.wrongs = slip(ans, s, half * t, R_NO_TRIANGLE) + slip(ans, s, half * (t + sin_deg(t)), R_SIN_DEG)
	out.generic = rest(ans, s, [half * sin(t), half * (t - sin(t)), rr * rr * (t + sin(t)), half * (t + 2.0 * sin(t)), half * PI])
	var sec := rd(half * t)
	var other := w(PI - t)
	var tri := rd(half * sin(float(other)))
	out.methods = {"add-subtract-regions": method(["Sector ODE: ½ × %s² × %s = %s" % [r, ts, w(sec)], "Angle AOE is π − %s = %s, on a straight wall." % [ts, other],
		"Triangle OEA: ½ × %s² × sin %s = %s" % [r, other, w(tri)], "A = %s + %s = %s" % [w(sec), w(tri), w(sec + tri)], ArcSectorViews.say(ans)], ans.values)}
	return out


func u_tether_expression(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var l: Q = s.l[0]
	var ls := Fmt.dec(l)
	var k: Q = l.sq().div(2)
	var ks := Fmt.dec(k)
	var ans := DifferentiationViews.form("A = (%s/θ²)(θ + sin θ) m²" % ks, ["A = (", {"slot": "k"}, "/θ²)(θ + sin θ) m²"], {"k": k})
	var out := {"table": null, "answer": ans, "asked": "Write the area the rover can reach in terms of θ."}
	out.lines = [WALLS + " OA = r m and angle DOE is θ radians.", "Arc DE is %s m long. The rover can reach the shaded ground: sector ODE and triangle OEA." % ls]
	out.graph = tether_figure(s, {"r_label": "r", "angle_label": "θ", "arc_label": ls + " m"})
	out.wrongs = [DifferentiationViews.alt("A = %s/θ m²" % ks, R_NO_TRIANGLE)]
	var dbl := Fmt.dec(l.sq())
	var half := Fmt.dec(k.div(2))
	out.generic = [DifferentiationViews.alt("A = (%s/θ²)(θ + sin θ) m²" % dbl, "", {"k": l.sq()}).values,
		DifferentiationViews.alt("A = (%s/θ²)(θ + sin θ) m²" % half, "", {"k": k.div(2)}).values,
		DifferentiationViews.alt("A = (%s/θ²)(θ − sin θ) m²" % ks).values,
		DifferentiationViews.alt("A = (%s/θ)(θ + sin θ) m²" % ks).values]
	out.methods = {"add-subtract-regions": method(["l = rθ, so r = %s/θ." % ls, "Sector ODE is ½r²θ, and triangle OEA is ½r² sin(π − θ) = ½r² sin θ.", "So A = ½r²(θ + sin θ).",
		"Put r² = %s/θ²: ½ × %s = %s." % [Fmt.dec(l.sq()), Fmt.dec(l.sq()), ks], ArcSectorViews.say(ans)], ans.values)}
	return out


func u_tether_angle(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: float = s.t.to_float()
	var ans := num(s, "angle DAE = ", t / 2.0, " radians")
	var r := Rt(s)
	var l := Fmt.dec(s.l[0])
	var out := {"table": null, "answer": ans}
	out.lines = [WALLS + " OA = %s, arc DE is %s long, and angle DOE is θ radians." % [r + " m", l + " m"]]
	out.graph = tether_figure(s, {"r_label": r + " m", "angle_label": "θ", "arc_label": l + " m", "mark_a": true})
	out.asked = ArcSectorViews.finish(s, "Find angle DAE, in radians.", ans)
	out.wrongs = []
	out.generic = rest(ans, s, [t, PI - t, (PI - t) / 2.0, t * 2.0])
	var ts := w(rd(t))
	var other := w(PI - rd(t))
	out.methods = {"angle-facts": method(["θ = l ÷ r = %s ÷ %s = %s" % [l, r, ts], "Angle AOE is π − %s = %s, on a straight wall." % [ts, other],
		"OA = OE, so triangle OEA is isosceles, and its other two angles are equal.", "Angle DAE = (π − %s) ÷ 2 = %s ÷ 2 = %s" % [other, ts, w(rd(t) / 2.0)], ArcSectorViews.say(ans)], ans.values)}
	return out


# ── A segment and a triangle in a ratio ──────────────────────

## k in θ = k sin θ for segment : triangle = m : n.
static func ratio_k(s: Dictionary) -> Q:
	return Q.new(s.m + s.n, s.n)


static func k_text(k: Q) -> String:
	return Fmt.dec(k) if k.is_int() else "(%s)" % Fmt.num(k)


static func semi_lines(s: Dictionary) -> Array:
	return ["The diagram shows a semicircle with centre O, radius r and diameter PQ. R is on the arc, and angle ROQ is θ radians, where 0 < θ < π.",
		"The shaded segment on chord RQ and the shaded triangle POR have areas in the ratio %d : %d." % [s.m, s.n]]


static func semi_figure(s: Dictionary) -> Dictionary:
	return region("semi", s, {"r_label": "r", "angle_label": "θ"})


## The working from the ratio to the equation for θ.
static func ratio_steps(s: Dictionary) -> Array:
	var q := Q.new(s.m, s.n)
	return ["The segment is ½r²(θ − sin θ). Triangle POR has angle π − θ at O, so its area is ½r² sin(π − θ) = ½r² sin θ.",
		"Their ratio gives θ − sin θ = %s sin θ, as the ½r² cancels." % k_text(q), "Collect the sin θ terms: θ = (1 + %s) sin θ." % Fmt.num(q)]


func u_ratio_equation(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k := ratio_k(s)
	var parts: Array = ["θ = ", {"slot": "k"}, " sin θ"] if k.is_int() else ["θ = (", {"slot": "k"}, ") sin θ"]
	var ans := DifferentiationViews.form("θ = %s sin θ" % k_text(k), parts, {"k": k})
	var out := {"table": null, "answer": ans, "lines": semi_lines(s), "graph": semi_figure(s)}
	out.asked = "Write the equation this gives for θ, in the form θ = k sin θ."
	var flip := Q.new(s.m + s.n, s.m)
	out.wrongs = [DifferentiationViews.alt("θ = %s sin θ" % k_text(flip), R_RATIO, {"k": flip})] if not flip.eq(k) else []
	var bare := Q.new(s.m, s.n)
	out.generic = [DifferentiationViews.alt("θ = %s sin θ" % k_text(bare), "", {"k": bare}).values, DifferentiationViews.alt("θ = %s sin θ" % k_text(k.add(1)), "", {"k": k.add(1)}).values,
		DifferentiationViews.alt("θ = %s sin θ" % k_text(k.mul(2)), "", {"k": k.mul(2)}).values, DifferentiationViews.alt("θ = %s sin θ" % k_text(k.add(2)), "", {"k": k.add(2)}).values]
	out.methods = {"add-subtract-regions": method(ratio_steps(s) + [ArcSectorViews.say(ans)], ans.values)}
	return out


func u_ratio_theta(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var th: float = s.t.to_float()
	var ans := num(s, "θ = ", th, "")
	var out := {"table": null, "answer": ans, "lines": semi_lines(s), "graph": semi_figure(s)}
	out.asked = ArcSectorViews.finish(s, "Find θ.", ans)
	var k := ratio_k(s).to_float()
	out.wrongs = []
	if s.m != s.n:
		out.wrongs = slip(ans, s, CircularRegionSituation.root(1.0 + float(s.n) / s.m), R_RATIO)
	out.generic = rest(ans, s, [CircularRegionSituation.root(k + 1.0), CircularRegionSituation.root(k + 0.5), th + 0.5, th / 2.0, PI - th])
	out.methods = {"add-subtract-regions": method(ratio_steps(s) + ["Solve θ = %s sin θ on the GDC, in radians, with 0 < θ < π." % k_text(ratio_k(s)), ArcSectorViews.say(ans)], ans.values)}
	return out


func u_ratio_radius(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var th: float = s.t.to_float()
	var a: float = s.area[0].to_float()
	var q: float = a * s.n / s.m
	var ans := num(s, "r = ", sqrt(2.0 * q / sin(th)), " cm")
	var at := Fmt.dec(s.area[0])
	var v := {"lines": ["Chord AB splits sector OAB of a circle, with centre O and radius r, into a shaded segment P and a triangle Q. Angle AOB is θ radians.",
		"P has an area of %s cm², and area P : area Q = %d : %d." % [at, s.m, s.n]],
		"graph": region("segment", s, {"r_label": "r", "angle_label": "θ", "circle": true, "parts": true})}
	var out := frame(v, s, ans, "Find r.")
	var flip := CircularRegionSituation.root(1.0 + float(s.n) / s.m)
	out.wrongs = slip(ans, s, sqrt(2.0 * a / th), R_SECTOR) + slip(ans, s, sqrt(2.0 * q / sin_deg(th)), R_SIN_DEG)
	if s.m != s.n:
		out.wrongs += slip(ans, s, sqrt(2.0 * a * s.m / s.n / sin(flip)), R_RATIO)
	out.generic = rest(ans, s, [2.0 * q / sin(th), sqrt(2.0 * q), sqrt(q / sin(th)), sqrt(2.0 * a / sin(th)), 2.0 * sqrt(2.0 * q / sin(th))])
	var ths := rd(th)
	var qs := rd(q)
	var f := Fmt.num(Q.new(s.m, s.n))
	var sq: float = rd(2.0 * qs / sin(ths))
	out.methods = {"sector-minus-triangle": method(["P : Q gives ½r²(θ − sin θ) ÷ ½r² sin θ = %s, so θ = %s sin θ." % [f, k_text(ratio_k(s))], "Solve on the GDC, in radians: θ = %s" % w(ths),
		"Q = %s × %d ÷ %d = %s, and Q = ½r² sin θ." % [at, s.n, s.m, w(qs)], "r² = 2 × %s ÷ sin %s = %s, so r = %s" % [w(qs), w(ths), w(sq), w(sqrt(sq))], ArcSectorViews.say(ans)], ans.values)}
	return out


# ── A rectangle and a segment ────────────────────────────────

func u_arch_area(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rr: float = s.r.to_float()
	var th: float = s.t.to_float()
	var hh: float = s.h.to_float()
	var half := rr * rr / 2.0
	var wide := 2.0 * rr * sin(th / 2.0)
	var seg := half * (th - sin(th))
	var ans := num(s, "A = ", wide * hh + seg, " cm²")
	var r := Fmt.dec(s.r) + " cm"
	var ht := Fmt.dec(s.h) + " cm"
	var ts := Fmt.dec(s.t)
	var v := {"lines": ["The shaded end of a shelter is a rectangle with arc AB on top. Each vertical side is %s high." % ht,
		"Arc AB is part of a circle with centre O and radius %s, and angle AOB is %s radians." % [r, ts]],
		"graph": region("arch", s, {"r": rr, "h": hh, "r_label": r, "angle_label": ts, "h_label": ht})}
	var out := frame(v, s, ans, "Find the area of the end of the shelter.")
	out.wrongs = slip(ans, s, wide * hh + half * th, R_SECTOR) + slip(ans, s, 2.0 * rr * sin_deg(th / 2.0) * hh + half * (th - sin_deg(th)), R_ANY_SINE)
	out.generic = rest(ans, s, [wide * hh, rr * hh + seg, 2.0 * wide * hh + seg, wide * hh + 2.0 * seg, seg])
	var rt := Fmt.dec(s.r)
	var hs := Fmt.dec(s.h)
	var ws := rd(wide)
	var box := rd(ws * hh)
	var cap := rd(seg)
	var c2 := rd(2.0 * rr * rr * (1.0 - cos(th)))
	var ab := rd(sqrt(c2))
	var box2 := rd(ab * hh)
	var seg_line := "Segment: ½ × %s² × (%s − sin %s) = %s" % [rt, ts, ts, w(cap)]
	out.methods = {"add-subtract-regions": method(["Width: AB = 2r sin(θ/2) = 2 × %s × sin %s = %s" % [rt, w(th / 2.0), w(ws)], "Rectangle: %s × %s = %s" % [w(ws), hs, w(box)],
		seg_line, "A = %s + %s = %s" % [w(box), w(cap), w(box + cap)], ArcSectorViews.say(ans)], ans.values),
		"chord-length": method(["Cosine rule: AB² = 2 × %s² − 2 × %s² × cos %s = %s" % [rt, rt, ts, w(c2)], "AB = √%s = %s, so the rectangle is %s × %s = %s" % [w(c2), w(ab), w(ab), hs, w(box2)],
		seg_line, "A = %s + %s = %s" % [w(box2), w(cap), w(box2 + cap)], ArcSectorViews.say(ans)], ans.values)}
	return out


# ── A curved strip ───────────────────────────────────────────

func u_ring_area(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var big: float = s.r.to_float()
	var small: float = s.rin.to_float()
	var t: float = s.t.to_float()
	var ans := num(s, "A = ", t * (big * big - small * small) / 2.0, " cm²")
	var v := {"lines": ["A curved shield lies between two circles with centre O, as shaded. The reflex angle at O is %s radians, the outer radius is %s and the inner radius is %s." % [Fmt.dec(s.t), Fmt.dec(s.r) + " cm", Fmt.dec(s.rin) + " cm"]],
		"graph": ArcSectorViews.ring_figure(s, Fmt.dec(s.rin) + " cm")}
	var out := frame(v, s, ans, "Find the area of the shield.")
	out.wrongs = slip(ans, s, (TAU - t) * (big * big - small * small) / 2.0, R_MINOR)
	out.generic = rest(ans, s, [t * big * big / 2.0, t * pow(big - small, 2) / 2.0, t * (big * big - small * small), t * (big - small), PI * (big * big - small * small)])
	var o2 := rd(t * big * big / 2.0)
	var i2 := rd(t * small * small / 2.0)
	var ts := Fmt.dec(s.t)
	out.methods = {"add-subtract-regions": method(["Outer sector: ½ × %s² × %s = %s" % [Fmt.dec(s.r), ts, w(o2)], "Inner sector: ½ × %s² × %s = %s" % [Fmt.dec(s.rin), ts, w(i2)],
		"A = %s − %s = %s" % [w(o2), w(i2), w(o2 - i2)], ArcSectorViews.say(ans)], ans.values)}
	return out


func u_ring_expression(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: Q = s.t.div(2)
	var a: Q = b.mul(s.r.sq())
	var at := Fmt.dec(a)
	var bt := Fmt.dec(b)
	var ans := DifferentiationViews.form("A = %s − %sr² cm²" % [at, bt], ["A = ", {"slot": "a"}, " − ", {"slot": "b"}, "r² cm²"], {"a": a, "b": b})
	var out := {"table": null, "answer": ans, "asked": "Write the area of the shield in terms of r."}
	out.lines = ["A curved shield lies between two circles with centre O, as shaded. The reflex angle at O is %s radians, the outer radius is %s and the inner radius is r cm, where r < %s." % [Fmt.dec(s.t), Fmt.dec(s.r) + " cm", Fmt.dec(s.r)]]
	out.graph = ArcSectorViews.ring_figure(s, "r")
	var t := Fmt.dec(s.t)
	out.wrongs = []
	out.generic = [DifferentiationViews.alt("A = %s − %sr cm²" % [at, bt]).values,
		DifferentiationViews.alt("A = %s − %sr² cm²" % [Fmt.dec(a.mul(2)), Fmt.dec(b.mul(2))], "", {"a": a.mul(2), "b": b.mul(2)}).values,
		DifferentiationViews.alt("A = %s − %sr² cm²" % [at, Fmt.dec(b.mul(2))], "", {"a": a, "b": b.mul(2)}).values,
		DifferentiationViews.alt("A = %s + %sr² cm²" % [at, bt]).values]
	out.methods = {"add-subtract-regions": method(["Outer sector: ½ × %s² × %s = %s" % [Fmt.dec(s.r), t, at], "Inner sector: ½ × r² × %s = %sr²" % [t, bt], "The shield is the outer sector less the inner one.", ArcSectorViews.say(ans)], ans.values)}
	return out


# ── A rectangle and a semicircle ─────────────────────────────

## "2x": kx, as the hatch's width is written.
static func hatch_figure(s: Dictionary) -> Dictionary:
	return {"kind": "region", "shape": "hatch", "rho": s.r.to_float(), "h": s.h.to_float(), "w_label": "%dx m" % s.k, "h_label": "h m"}


## bπx²: "πx²/2", "2πx²", "9πx²/2".
static func pi_x2(b: Q) -> String:
	var top := "πx²" if b.n == 1 else "%dπx²" % b.n
	return top + ("" if b.d == 1 else "/%d" % b.d)


func u_hatch_area(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var b := Q.new(k * k, 8)
	var ans := DifferentiationViews.form("A = %dxh + %s m²" % [k, pi_x2(b)], ["A = ", {"slot": "a"}, "xh + ", {"slot": "b"}, "πx² m²"], {"a": Q.new(k), "b": b})
	var out := {"table": null, "answer": ans, "asked": "Write the area A of the whole hatch in terms of x and h."}
	out.lines = ["A bunker hatch is a rectangle %dx m wide and h m high with a semicircle on top. The semicircle's diameter is the top of the rectangle." % k]
	out.graph = hatch_figure(s)
	var big := Q.new(k * k, 2)
	out.wrongs = [DifferentiationViews.alt("A = %dxh + %s m²" % [k, pi_x2(big)], R_DIAMETER, {"a": Q.new(k), "b": big})]
	out.generic = [DifferentiationViews.alt("A = %dxh + %s m²" % [k, pi_x2(b.mul(2))], "", {"a": Q.new(k), "b": b.mul(2)}).values,
		DifferentiationViews.alt("A = %dxh + %s m²" % [k * 2, pi_x2(b)], "", {"a": Q.new(k * 2), "b": b}).values,
		DifferentiationViews.alt("A = %dxh + %dπx m²" % [k, k]).values,
		DifferentiationViews.alt("A = %dxh m²" % k).values]
	out.methods = {"add-subtract-regions": method(["Rectangle: %dx × h = %dxh" % [k, k], "The semicircle's radius is half the width: %s." % ("x" if k == 2 else "%dx" % (k / 2)),
		"Semicircle: ½π%s² = %s" % ["x" if k == 2 else "(%dx)" % (k / 2), pi_x2(b)], ArcSectorViews.say(ans)], ans.values)}
	return out


func u_hatch_height(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var per: Q = s.per[0]
	var p := Fmt.dec(per)
	var hf: int = k / 2
	var arc := "πx" if hf == 1 else "%dπx" % hf
	var ans := DifferentiationViews.form("h = ½(%s − %dx − %s)" % [p, k, arc], ["h = ½(", {"slot": "p"}, " − ", {"slot": "a"}, "x − ", {"slot": "b"}, "πx)"], {"p": per, "a": Q.new(k), "b": Q.new(hf)})
	var out := {"table": null, "answer": ans, "asked": "Write h in terms of x."}
	out.lines = ["A bunker hatch is a rectangle %dx m wide and h m high with a semicircle on top. The semicircle's diameter is the top of the rectangle." % k, "The perimeter of the whole hatch is %s m." % p]
	out.graph = hatch_figure(s)
	out.wrongs = [DifferentiationViews.alt("h = ½(%s − %dx − %s)" % [p, 2 * k, arc], R_JOIN, {"p": per, "a": Q.new(2 * k), "b": Q.new(hf)})]
	out.generic = [DifferentiationViews.alt("h = ½(%s − %dx − %dπx)" % [p, k, k], "", {"p": per, "a": Q.new(k), "b": Q.new(k)}).values,
		DifferentiationViews.alt("h = %s − %dx − %s" % [p, k, arc]).values,
		DifferentiationViews.alt("h = ½(%s − %s)" % [p, arc]).values,
		DifferentiationViews.alt("h = ½(%s + %dx + %s)" % [p, k, arc]).values]
	out.methods = {"add-subtract-regions": method(["The join between the rectangle and the semicircle is inside, so it isn't on the perimeter.",
		"The curved top is half a circle: ½ × 2π × %s = %s." % ["x" if k == 2 else "%dx" % hf, arc], "P = %dx + 2h + %s = %s" % [k, arc, p], "2h = %s − %dx − %s" % [p, k, arc], ArcSectorViews.say(ans)], ans.values)}
	return out


# ── Tangents and a circle ────────────────────────────────────

func u_tangent_region(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rr: float = s.r.to_float()
	var th: float = s.t.to_float()
	var half := rr * rr / 2.0
	var kite := rr * rr / tan(th / 2.0)
	var sec := half * (PI - th)
	var ans := num(s, "A = ", kite - sec, " cm²")
	var r := Fmt.dec(s.r)
	var ts := Fmt.dec(s.t)
	var v := {"lines": ["AD and AE are tangents to a circle with centre O and radius %s, touching it at D and E. Angle DAE is %s." % [r + " cm", rad_words(s.t)], "The shaded region lies between the tangents and minor arc DE."],
		"graph": region("tangent", s, {"r_label": r + " cm", "angle_label": ts})}
	var out := frame(v, s, ans, "Find the area of the shaded region.")
	out.wrongs = slip(ans, s, kite - half * th, R_TAN_ANGLE)
	out.generic = rest(ans, s, [kite, kite / 2.0 - sec / 2.0, rr * rr * tan(th / 2.0) - sec, kite - 2.0 * sec, kite / 2.0])
	var half_t := w(th / 2.0)
	var dod := rd(PI - th)
	var k2 := rd(kite)
	var s2 := rd(half * dod)
	out.methods = {"add-subtract-regions": method(["The radii meet the tangents at right angles, and OA bisects angle DAE, so in triangle OAD, tan %s = %s ÷ AD." % [half_t, r],
		"Kite ADOE is two such triangles: 2 × ½ × %s × AD = %s² ÷ tan %s = %s" % [r, r, half_t, w(k2)],
		"The kite's angles add to 2π, with right angles at D and E, so angle DOE = π − %s = %s." % [ts, w(dod)],
		"Sector DOE: ½ × %s² × %s = %s. The shaded region is the kite less the sector: A = %s − %s = %s" % [r, w(dod), w(s2), w(k2), w(s2), w(k2 - s2)], ArcSectorViews.say(ans)], ans.values)}
	return out


func u_tangent_expression(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Q = s.a2
	var c: Q = a.div(2)
	var at := Fmt.dec(a)
	var ct := Fmt.dec(c)
	var ans := DifferentiationViews.form("A = %s/tan α − %s(π − 2α) cm²" % [at, ct], ["A = ", {"slot": "a"}, "/tan α − ", {"slot": "c"}, "(π − 2α) cm²"], {"a": a, "c": c})
	var out := {"table": null, "answer": ans, "asked": "Write the area of the shaded region in terms of α."}
	var r := Fmt.dec(s.r)
	out.lines = ["AD and AE are tangents to a circle with centre O and radius %s, touching it at D and E. Angle DAE is 2α radians." % (r + " cm"), "The shaded region lies between the tangents and minor arc DE."]
	out.graph = region("tangent", s, {"r_label": r + " cm", "angle_label": "2α"})
	out.wrongs = [DifferentiationViews.alt("A = %s/tan α − %sα cm²" % [at, at], R_TAN_ANGLE)]
	out.generic = [DifferentiationViews.alt("A = %s/tan α cm²" % at).values,
		DifferentiationViews.alt("A = %s/tan α − %s(π − 2α) cm²" % [ct, ct], "", {"a": c, "c": c}).values,
		DifferentiationViews.alt("A = %s tan α − %s(π − 2α) cm²" % [at, ct]).values,
		DifferentiationViews.alt("A = %s/tan α − %s(π − 2α) cm²" % [at, at], "", {"a": a, "c": a}).values]
	out.methods = {"add-subtract-regions": method(["The radii meet the tangents at right angles, and OA bisects angle DAE, so angle OAD = α and AD = %s/tan α." % r,
		"Kite ADOE is two such triangles: 2 × ½ × %s × %s/tan α = %s/tan α." % [r, r, at],
		"The kite's angles add to 2π, with right angles at D and E, so angle DOE = π − 2α.",
		"Sector DOE: ½ × %s² × (π − 2α) = %s(π − 2α). The shaded region is the kite less the sector." % [r, ct], ArcSectorViews.say(ans)], ans.values)}
	return out


# ── Two conditions ───────────────────────────────────────────

const LETTERS := "r is the radius of the sector and θ is its angle at the centre, in radians."


## The sector's perimeter and area, as this representation shows them. A diagram labels r and θ;
## the other representations say what the letters are.
static func two_view(rep: String, s: Dictionary, keys: Array = ["p", "a"]) -> Dictionary:
	var v := ArcSectorViews.show(rep, s, keys)
	if rep != "diagram":
		v.lines.insert(1, LETTERS)
	return v


func u_theta_in_r(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var per: Q = s.per[0]
	var p := Fmt.dec(per)
	var ans := DifferentiationViews.form("θ = (%s − 2r)/r" % p, ["θ = (", {"slot": "p"}, " − 2r)/r"], {"p": per})
	var v := two_view(rep, s, ["p"])
	var out := {"table": null, "answer": ans, "lines": v.lines, "graph": v.graph, "asked": "Write θ, in radians, in terms of the radius r."}
	out.wrongs = [DifferentiationViews.alt("θ = %s/r" % p, R_NO_RADII)]
	out.generic = [DifferentiationViews.alt("θ = (%s − r)/r" % p).values, DifferentiationViews.alt("θ = (%s + 2r)/r" % p).values,
		DifferentiationViews.alt("θ = (%s − 2r)/r²" % p).values, DifferentiationViews.alt("θ = (%s − 2)/r" % p).values]
	out.methods = {"rearrange-perimeter": method(["The perimeter is two radii and the arc: P = 2r + rθ.", "%s = 2r + rθ, so rθ = %s − 2r." % [p, p], ArcSectorViews.say(ans)], ans.values)}
	return out


func u_two_conditions_quadratic(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var per: Q = s.per[0]
	var area: Q = s.area[0]
	var b: Q = per.div(2)
	var p := Fmt.dec(per)
	var a := Fmt.dec(area)
	var bt := Fmt.dec(b)
	var ans := DifferentiationViews.form("r² − %sr + %s = 0" % [bt, a], ["r² − ", {"slot": "b"}, "r + ", {"slot": "c"}, " = 0"], {"b": b, "c": area})
	var v := two_view(rep, s)
	var out := {"table": null, "answer": ans, "lines": v.lines, "graph": v.graph, "asked": "Eliminate θ from the two conditions, and write the equation for r in the form r² − br + c = 0."}
	out.wrongs = [DifferentiationViews.alt("r − %s = 0" % Fmt.num(area.mul(2).div(per)), R_NO_RADII)]
	out.generic = [DifferentiationViews.alt("r² − %sr + %s = 0" % [p, a], "", {"b": per, "c": area}).values,
		DifferentiationViews.alt("r² − %sr + %s = 0" % [bt, Fmt.dec(area.mul(2))], "", {"b": b, "c": area.mul(2)}).values,
		DifferentiationViews.alt("r² + %sr + %s = 0" % [bt, a]).values,
		DifferentiationViews.alt("r² − %sr − %s = 0" % [bt, a]).values]
	out.methods = {"eliminate-theta": method(["From the perimeter: θ = (%s − 2r)/r." % p, "Into the area: ½r² × (%s − 2r)/r = %s, so ½r(%s − 2r) = %s." % [p, a, p, a],
		"Multiply out: %sr − r² = %s" % [bt, a], ArcSectorViews.say(ans)], ans.values)}
	return out


## The two roots as the working shows them.
static func roots_text(s: Dictionary) -> Array:
	return [Fmt.dec(s.r1), Fmt.dec(s.r2)] if s.paper == 1 else [w(s.r1.to_float()), w(s.r2.to_float())]


static func quad_text(s: Dictionary) -> String:
	return "r² − %sr + %s = 0" % [Fmt.dec(s.per[0].div(2)), Fmt.dec(s.area[0])]


## The way from the two conditions to the quadratic, in one step.
static func into_area(s: Dictionary) -> String:
	var p := Fmt.dec(s.per[0])
	return "From the perimeter, 2r + rθ = %s, so θ = (%s − 2r)/r. Into the area, ½r²θ = %s, this gives %s." % [p, p, Fmt.dec(s.area[0]), quad_text(s)]


## How the roots come out: by factors on Paper 1, by the quadratic formula on Paper 2.
static func solve_text(s: Dictionary) -> String:
	var ts := roots_text(s)
	if s.paper == 1:
		return "It factorises: (r − %s)(r − %s) = 0, so r = %s or r = %s." % [ts[0], ts[1], ts[0], ts[1]]
	return "The quadratic formula gives r = %s and r = %s." % [ts[0], ts[1]]


static func curves_text(s: Dictionary) -> String:
	return "θ = (%s − 2r)/r and θ = 2 × %s/r²" % [Fmt.dec(s.per[0]), Fmt.dec(s.area[0])]


func u_two_conditions_r(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var u := ArcSectorViews.unit(s)
	var ans := ArcSectorViews.ans_of(s, "r = ", _exact_or(s, s.r2), u)
	var v := two_view(rep, s)
	var out := frame(v, s, ans, "Find the radius." if rep == "words" else "Find r.")
	var r1: float = s.r1.to_float()
	var r2: float = s.r2.to_float()
	out.wrongs = ArcSectorViews.like(ans, s, _exact_or(s, s.r1), R_BIG_THETA) + ArcSectorViews.like(ans, s, _exact_or(s, s.area[0].mul(2).div(s.per[0])), R_NO_RADII)
	out.generic = ArcSectorViews.others(ans, s, [val(r1 + r2), val(2.0 * r2), val(r2 + 1.0), val(r2 + 2.0), val(r2 + 0.5)] if s.paper == 2 else [_exact_or(s, s.r1.add(s.r2)), _exact_or(s, s.r2.mul(2)), _exact_or(s, s.r2.add(1)), _exact_or(s, s.r2.add(2))])
	var ts := roots_text(s)
	var check := "θ = (%s − 2r)/r gives θ %s at r = %s, more than 2π, so that root is no sector." % [Fmt.dec(s.per[0]), big_theta(s), ts[0]]
	out.methods = {"substitute-eliminate": method([into_area(s), solve_text(s), check, ArcSectorViews.say(ans)], ans.values)}
	if s.paper == 2:
		out.methods["gdc-intersection"] = method(["Graph %s for r > 0." % curves_text(s), "They cross at r = %s and r = %s." % [ts[0], ts[1]], check, ArcSectorViews.say(ans)], ans.values)
	return out


## θ at the smaller root, past 2π: "= 16/3" or "≈ 7.42".
static func big_theta(s: Dictionary) -> String:
	return "= " + Fmt.dec(s.r2.mul(2).div(s.r1)) if s.paper == 1 else "≈ " + Fmt.sf(2.0 * s.r2.to_float() / s.r1.to_float())


## θ at the larger root: "= 2/3" or "≈ 0.733".
static func small_theta(s: Dictionary) -> String:
	return "= " + Fmt.dec(s.r1.mul(2).div(s.r2)) if s.paper == 1 else "≈ " + Fmt.sf(2.0 * s.r1.to_float() / s.r2.to_float())


## A Q as an answer's value: as it is on Paper 1, through a float on Paper 2 (a nine-place Q).
static func _exact_or(s: Dictionary, q: Q) -> Array:
	return ArcSectorViews.ab(q) if s.paper == 1 else val(q.to_float())


func u_two_conditions_theta(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := ArcSectorViews.ans_of(s, "θ = ", _exact_or(s, s.t), "")
	var v := two_view(rep, s)
	var out := frame(v, s, ans, "Find θ, the angle at the centre, in radians.")
	var r1: float = s.r1.to_float()
	var r2: float = s.r2.to_float()
	var pf: float = s.per[0].to_float()
	var af: float = s.area[0].to_float()
	var t: float = s.t.to_float()
	var ts := roots_text(s)
	if s.paper == 1:
		out.wrongs = ArcSectorViews.like(ans, s, ArcSectorViews.ab(s.r2.mul(2).div(s.r1)), R_BIG_THETA) + ArcSectorViews.like(ans, s, ArcSectorViews.ab(s.per[0].sq().div(s.area[0].mul(2))), R_NO_RADII)
		out.generic = ArcSectorViews.others(ans, s, [ArcSectorViews.ab(s.t.mul(2)), ArcSectorViews.ab(s.t.add(1)), ArcSectorViews.ab(s.t.add(2)), ArcSectorViews.ab(s.t.div(2))])
	else:
		out.wrongs = slip(ans, s, 2.0 * r2 / r1, R_BIG_THETA) + slip(ans, s, pf * pf / (2.0 * af), R_NO_RADII)
		out.generic = rest(ans, s, [t * 2.0, t + 1.0, t / 2.0, t + 0.5])
	var rs := rd(r2)
	var at := Fmt.dec(s.t) if s.paper == 1 else w((pf - 2.0 * rs) / rs)
	var pick := "At r = %s, θ %s is more than 2π, so r = %s." % [ts[0], big_theta(s), ts[1]]
	var last := "θ = (%s − 2 × %s) ÷ %s = %s" % [Fmt.dec(s.per[0]), ts[1], ts[1], at]
	out.methods = {"substitute-eliminate": method([into_area(s), solve_text(s), pick, last, ArcSectorViews.say(ans)], ans.values)}
	if s.paper == 2:
		out.methods["gdc-intersection"] = method(["Graph %s for r > 0." % curves_text(s), "They cross at r = %s and r = %s." % [ts[0], ts[1]], pick, last, ArcSectorViews.say(ans)], ans.values)
	return out


func u_two_conditions_both(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var u := ArcSectorViews.unit(s)
	var v := two_view(rep, s)
	var r1: float = s.r1.to_float()
	var r2: float = s.r2.to_float()
	var ts := roots_text(s)
	var ans: Dictionary
	var out := {"table": null, "lines": v.lines, "graph": v.graph}
	if s.paper == 1:
		ans = DifferentiationViews.form("r = %s%s or %s%s" % [ts[0], u, ts[1], u], ["r = ", {"slot": "a"}, u + " or ", {"slot": "b"}, u], {"a": s.r1, "b": s.r2})
		ans.unordered = [["a", "b"]]
		out.asked = "Find both possible values of the radius."
		out.wrongs = [DifferentiationViews.alt("r = %s%s" % [ts[1], u], R_ONE_ROOT), DifferentiationViews.alt("r = %s%s" % [ts[0], u], R_ONE_ROOT)]
		var one: Q = s.r1.add(1)
		var two: Q = s.r2.add(1)
		var b2: Q = s.r1.mul(2)
		var c2: Q = s.r2.mul(2)
		out.generic = [DifferentiationViews.alt("r = %s%s or %s%s" % [Fmt.dec(one), u, Fmt.dec(two), u], "", {"a": one, "b": two}).values,
			DifferentiationViews.alt("r = %s%s or %s%s" % [Fmt.dec(b2), u, Fmt.dec(c2), u], "", {"a": b2, "b": c2}).values]
	else:
		ans = TriangleViews.two_measures("r = ", r1, r2, u)
		ans.show = "sf"
		out.asked = "Find both possible values of the radius. Give your answers to 3 significant figures."
		out.wrongs = [wrong({"v1": GdcKit.qf(r2), "v2": GdcKit.qf(r1), "only": true}, R_ONE_ROOT), wrong({"v1": GdcKit.qf(r1), "v2": GdcKit.qf(r2), "only": true}, R_ONE_ROOT)]
		out.generic = [TriangleViews.res2(r1 + 1.0, r2 + 1.0), TriangleViews.res2(2.0 * r1, 2.0 * r2), TriangleViews.res2(r1 / 2.0, r2 / 2.0), TriangleViews.res2(r1 + 0.5, r2 - 0.5)]
	out.answer = ans
	var check := "θ = (%s − 2r)/r gives θ %s at r = %s and θ %s at r = %s. Both are between 0 and 2π, so both are real sectors." % [Fmt.dec(s.per[0]), big_theta(s), ts[0], small_theta(s), ts[1]]
	out.methods = {"substitute-eliminate": method([into_area(s), solve_text(s), check, ArcSectorViews.say(ans)], ans.values)}
	if s.paper == 2:
		out.methods["gdc-intersection"] = method(["Graph %s for r > 0." % curves_text(s), "They cross at r = %s and r = %s." % [ts[0], ts[1]], check, ArcSectorViews.say(ans)], ans.values)
	return out


func u_arc_area_radius(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var u := ArcSectorViews.unit(s)
	var ans := ArcSectorViews.ans_of(s, "r = ", _exact_or(s, s.r), u)
	var out := frame(two_view(rep, s, ["l", "a"]), s, ans, "Find the radius." if rep == "words" else "Find r.")
	var lq: Q = s.l[0]
	var aq: Q = s.area[0]
	out.wrongs = []
	out.generic = ArcSectorViews.others(ans, s, [_exact_or(s, aq.div(lq)), _exact_or(s, aq.mul(4).div(lq)), _exact_or(s, lq.div(aq)), _exact_or(s, lq.mul(2).div(aq)), _exact_or(s, aq.mul(2).div(lq).add(1)), _exact_or(s, aq.mul(2).div(lq).add(2))])
	var at := Fmt.dec(aq)
	var lt := Fmt.dec(lq)
	var worked := Fmt.dec(s.r) if s.paper == 1 else w(s.r.to_float())
	out.methods = {"area-half-rl": method(["A = ½r²θ = ½r × rθ, and rθ = l, so A = ½rl.", "%s = ½ × r × %s" % [at, lt], "r = 2 × %s ÷ %s = %s" % [at, lt, worked], ArcSectorViews.say(ans)], ans.values)}
	return out


func u_cone_from_area(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var sl: float = s.r.to_float()
	var a: float = s.area[0].to_float()
	var ans := num(s, "radius = ", a / (PI * sl), " cm")
	var r := Fmt.dec(s.r)
	var at := Fmt.dec(s.area[0])
	var out := {"table": null, "answer": ans}
	out.lines = ["The sector in the diagram, with centre O and radius %s, has an area of %s cm². It is rolled up so that OA meets OB, to make a cone, and the arc becomes the rim." % [r + " cm", at]]
	out.graph = ArcSectorViews.figure(s, "minor", {"r_label": r + " cm", "cone": true})
	out.asked = ArcSectorViews.finish(s, "Find the radius of the circle at the rim.", ans)
	out.wrongs = []
	out.generic = rest(ans, s, [2.0 * a / sl, a / sl, sqrt(a / PI), 2.0 * a / (PI * sl), a / (2.0 * PI * sl)])
	var arc := rd(2.0 * a / sl)
	out.methods = {"area-half-rl": method(["A = ½rl, so the arc is l = 2 × %s ÷ %s = %s" % [at, r, w(arc)], "The arc is the rim: 2π × radius = %s" % w(arc), "radius = %s ÷ 2π = %s" % [w(arc), w(arc / TAU)], ArcSectorViews.say(ans)], ans.values)}
	return out
