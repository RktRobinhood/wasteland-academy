class_name BearingsViews
extends ExtensionViews
## The views on the `bearings-elevation` situation: one builder per unknown of
## t3-bearings-elevation (FAL-726). Every question is Paper 2: measures are to 3 s.f. with the
## rounding trap, and a bearing or angle that comes out whole is exact.
##
## Representations: "words" (a story) and "diagram" (the same story with a sketch from PlotView's
## `sketch`: real coordinates, a north line at each point with a bearing, or a side view).
## Worked figures are five significant figures, each worked from the figures shown before it.

const SKILL := "SL3.3."
const R_WRONG_WAY := SKILL + "bearings#0"
const R_FROM_TO := SKILL + "bearings#1"
const R_BEARING_INSIDE := SKILL + "bearings#2"
const R_FROM_VERTICAL := SKILL + "elevation-depression#0"
const R_AT_TOP := SKILL + "elevation-depression#1"
const R_NO_EYE := SKILL + "elevation-depression#2"
const R_ROUND_EARLY := SKILL + "multi-triangle#0"
const R_LOOKS_RIGHT := SKILL + "multi-triangle#1"
const R_SINE_NO_PAIR := SKILL + "multi-triangle#2"

## Who travels, and what stands tall.
const WHO := ["A caravan", "A scout drone", "A courier", "A salvage truck", "A patrol", "A water cart"]
const TALL := ["watchtower", "radio mast", "water tower", "ruined silo", "pylon", "lookout post"]
const SEEN := ["a stranded truck", "a dust storm shelter", "a broken-down cart", "a signal fire", "a lost drone", "a supply crate"]

const UNKNOWNS := ["back-bearing", "angle-from-bearing", "two-leg-distance", "two-leg-bearing", "return-bearing",
	"due-east-distance", "sine-rule-distance", "due-west-side", "height-from-elevation", "distance-from-depression",
	"angle-of-depression", "height-with-eye-level", "chain-below-hook", "time-from-depression", "route-time",
	"shared-side", "quadrilateral-area", "perpendicular-split", "rule-to-use"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## Every cell is Paper 2: every bank part of this type is.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = BearingsSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## A bearing with three figures.
static func B(b: Variant) -> String:
	return "%03d°" % int(b)


## A worked figure: five significant figures.
static func W(x: float) -> String:
	return Fmt.work(x, 5)


## The number a worked figure says, so the next step works from what is shown.
static func back(t: String) -> float:
	return float(t.replace("−", "-"))


static func rad(d: float) -> float:
	return deg_to_rad(d)


static func sq(v: Variant) -> float:
	return v.to_float() * v.to_float()


static func q(x: float) -> Q:
	return GdcKit.qf(x)


## An answer to 3 s.f., with the rounding trap.
static func ans_of(label: String, x: float, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": q(x)}, {}, label, unit)
	ans.show = "sf"
	return ans


## An answer that comes out whole, with no rounding: a bearing is written with three figures.
static func whole(label: String, n: int, text: String) -> Dictionary:
	var ans := DifferentiationViews.form(label + text, [label, {"slot": "v"}, "°"], {"v": Q.new(n)})
	ans.head = label
	return ans


static func whole_wrong(ans: Dictionary, n: int, ref: String = "", three: bool = true) -> Dictionary:
	return DifferentiationViews.alt(ans.head + (B(n) if three else "%d°" % n), ref, {"v": Q.new(n)})


## Positive wrong values only, each a wrong option.
static func bad(x: float, ref: String = "") -> Array:
	return [wrong({"v": q(x)}, ref)] if x > 0.0 and is_finite(x) else []


static func gens(xs: Array) -> Array:
	var out: Array = []
	for x in xs:
		if x > 0.0 and is_finite(x):
			out.append({"v": q(x)})
	return out


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func sf3(asked: String) -> String:
	return asked + " Give your answer to 3 significant figures."


# ── Geometry ─────────────────────────────────────────────────

## A step of d in the direction of bearing b: [east, north].
static func step(b: float, d: float) -> Array:
	return [d * sin(rad(b)), d * cos(rad(b))]


static func bearing_to(p: Array, r: Array) -> float:
	return fposmod(rad_to_deg(atan2(r[0] - p[0], r[1] - p[1])), 360.0)


static func dist(p: Array, r: Array) -> float:
	return sqrt(pow(r[0] - p[0], 2) + pow(r[1] - p[1], 2))


static func journey(s: Dictionary) -> Dictionary:
	var a := [0.0, 0.0]
	var b := step(s.b1, s.d1.to_float())
	var leg := step(s.b2, s.d2.to_float())
	return {"A": a, "B": b, "C": [b[0] + leg[0], b[1] + leg[1]]}


static func start_to_end(s: Dictionary) -> float:
	var p := journey(s)
	return bearing_to(p.A, p.C)


## The angle inside the triangle at B: 180° less the turn.
static func inside(s: Dictionary) -> int:
	return 180 - turn(s)


static func turn(s: Dictionary) -> int:
	var t: int = absi(s.b2 - s.b1)
	return 360 - t if t > 180 else t


static func elev(s: Dictionary) -> float:
	return s.e.to_float() if s.form == "rad" else rad(s.e.to_float())


static func angle_words(s: Dictionary) -> String:
	return D(s.e) + " radians" if s.form == "rad" else D(s.e) + "°"


## The ratio as a calculator is told it.
static func tan_text(s: Dictionary) -> String:
	return "tan(%s radians)" % D(s.e) if s.form == "rad" else "tan %s°" % D(s.e)


static func bd(s: Dictionary) -> float:
	var a: float = s.ab.to_float()
	var d: float = s.ad.to_float()
	return sqrt(a * a + d * d - 2.0 * a * d * cos(rad(s.a_angle)))


## A, B, C and D: A at the origin, B along the x-axis, C across BD from A.
static func quad(s: Dictionary) -> Dictionary:
	var a := [0.0, 0.0]
	var b := [s.ab.to_float(), 0.0]
	var d := [s.ad.to_float() * cos(rad(s.a_angle)), s.ad.to_float() * sin(rad(s.a_angle))]
	var to_d := atan2(d[1] - b[1], d[0] - b[0])
	# Turn from BD away from A, clockwise on the page: A is on BD's left going from B to D.
	var dir := to_d - rad(s.dbc)
	return {"A": a, "B": b, "D": d, "C": [b[0] + s.bc.to_float() * cos(dir), b[1] + s.bc.to_float() * sin(dir)]}


# ── Sketches ─────────────────────────────────────────────────

static func side(a: String, b: String, label: String = "", dash: bool = false) -> Dictionary:
	return {"a": a, "b": b, "label": label, "dash": dash}


static func arc(at: String, from: String, to: String, label: String) -> Dictionary:
	return {"at": at, "from": from, "to": to, "label": label}


static func sketch(pts: Dictionary, lines: Array, arcs: Array, north: Array = [], extra: Dictionary = {}) -> Dictionary:
	var out := {"kind": "sketch", "pts": pts, "lines": lines, "arcs": arcs, "north": north}
	out.merge(extra, true)
	return out


## The story's lines, with the sketch where this is the diagram representation.
static func frame(rep: String, lines: Array, asked: String, ans: Dictionary, g: Dictionary) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "table": null}
	if rep == "diagram":
		out.graph = g
	return out


static func journey_lines(s: Dictionary) -> Array:
	return ["%s leaves camp A and travels %s km on a bearing of %s to a well at B." % [WHO[s.ctx], D(s.d1), B(s.b1)],
		"It then travels %s km on a bearing of %s to a depot at C." % [D(s.d2), B(s.b2)]]


static func journey_sketch(s: Dictionary, closing: String) -> Dictionary:
	return sketch(journey(s), [side("A", "B", D(s.d1) + " km"), side("B", "C", D(s.d2) + " km"), side("A", "C", closing, true)],
		[arc("A", "N", "B", B(s.b1)), arc("B", "N", "C", B(s.b2))], ["A", "B"])


# ── Bearings ─────────────────────────────────────────────────

func u_back_bearing(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b1
	var back_b: int = posmod(b + 180, 360)
	var ans := whole("bearing = ", back_b, B(back_b))
	var pts := {"A": [0.0, 0.0], "B": step(b, 10.0)}
	var out := frame(rep, ["From a camp at A, a tower at B is on a bearing of %s." % B(b)], "Find the bearing of A from B.", ans,
		sketch(pts, [side("A", "B")], [arc("A", "N", "B", B(b))], ["A", "B"]))
	out.wrongs = [whole_wrong(ans, b, R_FROM_TO), whole_wrong(ans, posmod(360 - b, 360), R_WRONG_WAY)]
	out.generic = [whole_wrong(ans, posmod(b + 90, 360)).values, whole_wrong(ans, posmod(180 - b, 360)).values, whole_wrong(ans, posmod(b - 90, 360)).values]
	var line := "%s + 180° = %s" % [B(b), B(b + 180)] if b < 180 else "%s − 180° = %s" % [B(b), B(b - 180)]
	out.methods = {"back-bearing": method(["The way back is the opposite direction, so add or take away 180°.", line, say(ans)], ans.values)}
	return out


func u_angle_from_bearing(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var at_a: int = 90 - s.b1
	var c: int = 180 - at_a - s.phi
	var ans := DifferentiationViews.form("angle ACB = %d°" % c, ["angle ACB = ", {"slot": "v"}, "°"], {"v": Q.new(c)})
	ans.head = "angle ACB = "
	var pts := _east_pts(s)
	var out := frame(rep, _east_lines(s, false), "Find angle ACB.", ans,
		sketch(pts, [side("A", "B", D(s.d1) + " km"), side("A", "C"), side("B", "C")], [arc("A", "N", "C", B(s.b1)), arc("B", "A", "C", "%d°" % s.phi)], ["A"]))
	out.wrongs = [whole_wrong(ans, 180 - s.b1 - s.phi, R_BEARING_INSIDE, false)]
	out.generic = [whole_wrong(ans, at_a, "", false).values, whole_wrong(ans, 90 - s.phi, "", false).values, whole_wrong(ans, c + 10, "", false).values, whole_wrong(ans, c - 10, "", false).values]
	out.methods = {"angle-chase-cosine": method(["East is 90° from north, so angle CAB = 90° − %d° = %d°" % [s.b1, at_a], "The angles of a triangle add to 180°: 180° − %d° − %d° = %d°" % [at_a, s.phi, c], "So " + Answer.text(ans) + "."], ans.values)}
	return out


static func _east_pts(s: Dictionary) -> Dictionary:
	var ab: float = s.d1.to_float()
	var at_a := 90.0 - float(s.b1)
	var c := 180.0 - at_a - float(s.phi)
	var ac := ab * sin(rad(float(s.phi))) / sin(rad(c))
	return {"A": [0.0, 0.0], "B": [ab, 0.0], "C": step(s.b1, ac)}


static func _east_lines(s: Dictionary, with_c: bool) -> Array:
	if with_c:
		return ["An outpost B is %s km due east of a camp at A." % D(s.d1), "A signal fire at C is %s km from A, on a bearing of %s." % [D(s.d2), B(s.b1)]]
	return ["An outpost B is %s km due east of a camp at A." % D(s.d1), "From A, a signal fire at C is on a bearing of %s. Angle ABC is %d°." % [B(s.b1), s.phi]]


func u_two_leg_distance(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p := journey(s)
	var x := dist(p.A, p.C)
	var ans := ans_of("distance = ", x, " km")
	var out := frame(rep, journey_lines(s), sf3("Find the distance of the depot from camp."), ans, journey_sketch(s, "?"))
	var d1: float = s.d1.to_float()
	var d2: float = s.d2.to_float()
	var t: int = turn(s)
	var b: int = inside(s)
	var slip := sqrt(d1 * d1 + d2 * d2 - 2.0 * d1 * d2 * cos(rad(t)))
	out.wrongs = bad(slip, R_BEARING_INSIDE)
	out.generic = gens([d1 + d2, sqrt(d1 * d1 + d2 * d2), absf(d1 - d2), x + 2.0, x * 1.5])
	var line := "AC² = %s² + %s² − 2 × %s × %s × cos %d°" % [D(s.d1), D(s.d2), D(s.d1), D(s.d2), b]
	var sq2 := W(d1 * d1 + d2 * d2 - 2.0 * d1 * d2 * cos(rad(b)))
	var e1: Array = step(s.b1, d1)
	var e2: Array = step(s.b2, d2)
	var east := W(e1[0] + e2[0])
	var north := W(e1[1] + e2[1])
	var parts := "East: %s sin %d° + %s sin %d° gives %s" % [D(s.d1), s.b1, D(s.d2), s.b2, east]
	var parts2 := "North: %s cos %d° + %s cos %d° gives %s" % [D(s.d1), s.b1, D(s.d2), s.b2, north]
	out.methods = {"angle-chase-cosine": method(["The north lines are parallel and the turn is %d°, so angle ABC = 180° − %d° = %d°" % [t, t, b], line + " = " + sq2, say(ans)], ans.values),
		"components": method([parts, parts2, "Distance = √(%s² + %s²)" % [_par(east), _par(north)], say(ans)], ans.values)}
	return out


static func _par(t: String) -> String:
	return "(%s)" % t if t.begins_with("−") else t


## cos A in triangle ABC from its three sides, and the bearing from A that it gives.
static func _chase(s: Dictionary) -> Dictionary:
	var p := journey(s)
	var ac := dist(p.A, p.C)
	var d1: float = s.d1.to_float()
	var d2: float = s.d2.to_float()
	var ac_t := W(ac)
	var cs := (d1 * d1 + back(ac_t) * back(ac_t) - d2 * d2) / (2.0 * d1 * back(ac_t))
	var ca := W(rad_to_deg(acos(cs)))
	return {"ac": ac_t, "angle": ca}


static func _both_bearing(s: Dictionary) -> Dictionary:
	var c := _chase(s)
	var d2t := D(s.d2)
	var d1t := D(s.d1)
	var clockwise: bool = posmod(s.b2 - s.b1, 360) < 180
	var joined := "%s %s %s°" % [B(s.b1), "+" if clockwise else "−", c.angle]
	var b: int = inside(s)
	var p := journey(s)
	var east := W(p.C[0])
	var north := W(p.C[1])
	var note := "AC has east part %s and north part %s, from adding each leg's d sin(bearing) and d cos(bearing)." % [east, north]
	return {"chase": ["Angle ABC is %d°, and the cosine rule gives AC = %s." % [b, c.ac],
		"cos A = (%s² + %s² − %s²) ÷ (2 × %s × %s), so angle BAC = %s°" % [d1t, c.ac, d2t, d1t, c.ac, c.angle],
		"The bearing of C from A is %s = %s°" % [joined, W(fposmod(float(s.b1) + (1.0 if clockwise else -1.0) * back(c.angle), 360.0))]], "note": note}


func u_two_leg_bearing(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b := start_to_end(s)
	var ans := ans_of("bearing = ", b, "°")
	var out := frame(rep, journey_lines(s), sf3("Find the bearing of the depot from camp."), ans, journey_sketch(s, ""))
	out.wrongs = bad(fposmod(b + 180.0, 360.0), R_FROM_TO) + bad(360.0 - b, R_WRONG_WAY)
	out.generic = gens([fposmod(b + 90.0, 360.0), fposmod(450.0 - b, 360.0), float(s.b1 + s.b2) / 2.0, b - 20.0])
	var both := _both_bearing(s)
	out.methods = {"angle-chase-cosine": method(both.chase + [say(ans)], ans.values),
		"components": method([both.note, "tan⁻¹ of east ÷ north gives the angle from the north line, then put it in the right quarter.", say(ans)], ans.values)}
	return out


func u_return_bearing(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var there := start_to_end(s)
	var b := fposmod(there + 180.0, 360.0)
	var ans := ans_of("bearing = ", b, "°")
	var out := frame(rep, journey_lines(s), sf3("Find the bearing it must take to go straight back to camp from the depot."), ans, journey_sketch(s, ""))
	out.wrongs = bad(there, R_FROM_TO)
	out.generic = gens([360.0 - b, fposmod(b + 90.0, 360.0), fposmod(b - 90.0, 360.0), b - 20.0])
	var both := _both_bearing(s)
	var flip := "Add or take away 180°: the way back is %s°." % W(fposmod(back(W(there)) + 180.0, 360.0))
	out.methods = {"angle-chase-cosine": method(both.chase + [flip, say(ans)], ans.values),
		"components": method([both.note, "The way from C to A reverses both parts, then tan⁻¹ of east ÷ north gives the direction.", say(ans)], ans.values),
		"back-bearing": method(["Find the bearing of C from A first: it is %s°." % W(there), flip, say(ans)], ans.values)}
	return out


func u_due_east_distance(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ab: float = s.d1.to_float()
	var ac: float = s.d2.to_float()
	var at_a: int = 90 - s.b1
	var x := sqrt(ab * ab + ac * ac - 2.0 * ab * ac * cos(rad(at_a)))
	var ans := ans_of("BC = ", x, " km")
	var pts := {"A": [0.0, 0.0], "B": [ab, 0.0], "C": step(s.b1, ac)}
	var out := frame(rep, _east_lines(s, true), sf3("Find the distance BC."), ans,
		sketch(pts, [side("A", "B", D(s.d1) + " km"), side("A", "C", D(s.d2) + " km"), side("B", "C", "?", true)], [arc("A", "N", "C", B(s.b1))], ["A"]))
	var slip := sqrt(ab * ab + ac * ac - 2.0 * ab * ac * cos(rad(s.b1)))
	out.wrongs = bad(slip, R_BEARING_INSIDE)
	out.generic = gens([sqrt(ab * ab + ac * ac), ab + ac, absf(ab - ac), x + 2.0, x * 1.5])
	var sq2 := W(ab * ab + ac * ac - 2.0 * ab * ac * cos(rad(at_a)))
	var cx: Array = step(s.b1, ac)
	var east := W(cx[0] - ab)
	var north := W(cx[1])
	out.methods = {"angle-chase-cosine": method(["East is 90° from north, so angle CAB = 90° − %d° = %d°" % [s.b1, at_a],
		"BC² = %s² + %s² − 2 × %s × %s × cos %d° = %s" % [D(s.d1), D(s.d2), D(s.d1), D(s.d2), at_a, sq2], say(ans)], ans.values),
		"components": method(["From B, C is east by %s sin %d° − %s, which is %s" % [D(s.d2), s.b1, D(s.d1), east], "and north by %s cos %d°, which is %s." % [D(s.d2), s.b1, north], "BC = √(%s² + %s²)" % [_par(east), _par(north)], say(ans)], ans.values)}
	return out


func u_sine_rule_distance(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ab: float = s.d1.to_float()
	var at_a: int = 90 - s.b1
	var c: int = 180 - at_a - s.phi
	var ac := ab * sin(rad(s.phi)) / sin(rad(c))
	var bc := ab * sin(rad(at_a)) / sin(rad(c))
	var asked_ac: bool = s.which == "AC"
	var x := ac if asked_ac else bc
	var ans := ans_of("%s = " % s.which, x, " km")
	var pts := _east_pts(s)
	var out := frame(rep, _east_lines(s, false), sf3("Find the distance %s." % s.which), ans,
		sketch(pts, [side("A", "B", D(s.d1) + " km"), side("A", "C", "?" if asked_ac else ""), side("B", "C", "" if asked_ac else "?")], [arc("A", "N", "C", B(s.b1)), arc("B", "A", "C", "%d°" % s.phi)], ["A"]))
	# Taking the bearing itself as the angle at A.
	var c_bad: int = 180 - s.b1 - s.phi
	var slip := ab * sin(rad(s.phi if asked_ac else s.b1)) / sin(rad(c_bad))
	out.wrongs = bad(slip, R_BEARING_INSIDE)
	out.generic = gens([bc if asked_ac else ac, ab * sin(rad(c)), ab * tan(rad(s.phi)), x + 2.0, ab * cos(rad(at_a))])
	var opp: int = s.phi if asked_ac else at_a
	out.methods = {"angle-chase-cosine": method(["East is 90° from north, so angle CAB = 90° − %d° = %d°, and angle ACB = 180° − %d° − %d° = %d°" % [s.b1, at_a, at_a, s.phi, c],
		"Sine rule: %s ÷ sin %d° = %s ÷ sin %d°" % [s.which, opp, D(s.d1), c], "%s = %s sin %d° ÷ sin %d° = %s" % [s.which, D(s.d1), opp, c, W(x)], say(ans)], ans.values)}
	return out


func u_due_west_side(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var abc: int = s.b1 - 90
	var acb: int = 180 - s.phi - abc
	var ac: float = s.d1.to_float()
	var x := ac * sin(rad(s.phi)) / sin(rad(abc))
	var ans := ans_of("BC = ", x, " m")
	var lines := ["Two straight tracks leave a post at A. One passes B and the other passes C, where C is due west of B.",
		"AC = %s m, the bearing of B from A is %s and angle BAC is %d°." % [D(s.d1), B(s.b1), s.phi]]
	var a := [0.0, 0.0]
	var c := step(s.b1 + s.phi, ac)
	var ab: float = c[1] / cos(rad(s.b1))
	var b := step(s.b1, ab)
	var out := frame(rep, lines, sf3("A fence runs straight from B to C. Find its length."), ans,
		sketch({"A": a, "B": b, "C": c}, [side("A", "B"), side("A", "C", D(s.d1) + " m"), side("B", "C", "?", true)], [arc("A", "N", "B", B(s.b1)), arc("A", "B", "C", "%d°" % s.phi)], ["A"]))
	out.wrongs = []
	out.generic = gens([ac * sin(rad(s.phi)), ac * cos(rad(s.phi)), ac * tan(rad(s.phi)), ac * sin(rad(s.phi)) / sin(rad(s.b1)), ac * sin(rad(s.phi)) / sin(rad(acb)), x + 20.0])
	out.methods = {"angle-chase-cosine": method(["BA runs back along the bearing %s, and BC runs due west." % B(s.b1), "So angle ABC = %d° − 90° = %d°" % [s.b1, abc],
		"Sine rule: BC ÷ sin %d° = %s ÷ sin %d°" % [s.phi, D(s.d1), abc], "BC = %s sin %d° ÷ sin %d° = %s" % [D(s.d1), s.phi, abc, W(x)], say(ans)], ans.values)}
	return out


# ── Elevation and depression ─────────────────────────────────

static func tall(s: Dictionary) -> String:
	return TALL[s.ctx]


## A side view: the top T above the foot F, and the point P on the ground, with the horizontal
## through T where the angle is a depression.
static func side_view(h: float, x: float, depress: bool, h_label: String, x_label: String, label: String, extra: Dictionary = {}) -> Dictionary:
	var pts := {"T": [0.0, h], "F": [0.0, 0.0], "P": [x, 0.0]}
	var lines := [side("F", "T", h_label), side("F", "P", x_label), side("T", "P", "", true)]
	var arcs: Array
	if depress:
		pts["_H"] = [x * 0.75, h]
		lines.append(side("T", "_H", "", true))
		arcs = [arc("T", "_H", "P", label)]
	else:
		arcs = [arc("P", "F", "T", label)]
	return sketch(pts, lines, arcs, [], extra)


func u_height_from_elevation(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.x.to_float()
	var t := elev(s)
	var h := x * tan(t)
	var ans := ans_of("height = ", h, " m")
	var lines := ["A scavenger stands at P on level ground, %s m from the foot F of a %s." % [D(s.x), tall(s)], "The angle of elevation of the top T from P is %s." % angle_words(s)]
	var out := frame(rep, lines, sf3("Find the height of the %s." % tall(s)), ans, side_view(h, x, false, "?", D(s.x) + " m", _angle_label(s)))
	out.wrongs = []
	var degree_slip: float = x * tan(rad(s.e.to_float())) if s.form == "rad" else x * tan(s.e.to_float())
	out.generic = gens([x * sin(t), x * cos(t), x / tan(t), absf(degree_slip), h + 2.0])
	out.methods = {"right-triangle": method(["tan θ = height ÷ distance, so height = distance × tan θ", "height = %s × %s = %s" % [D(s.x), tan_text(s), W(h)], say(ans)], ans.values)}
	return out


static func _angle_label(s: Dictionary) -> String:
	return D(s.e) if s.form == "rad" else D(s.e) + "°"


func u_distance_from_depression(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h: float = s.h.to_float()
	var t := elev(s)
	var x := h / tan(t)
	var ans := ans_of("distance = ", x, " m")
	var lines := ["From the top T of a %s %s m high, a lookout sees %s at P on level ground." % [tall(s), D(s.h), SEEN[s.ctx]], "The angle of depression of P from T is %s." % angle_words(s)]
	var out := frame(rep, lines, sf3("Find the horizontal distance from the foot of the %s to P." % tall(s)), ans, side_view(h, x, true, D(s.h) + " m", "?", _angle_label(s)))
	out.wrongs = bad(h * tan(t), R_AT_TOP)
	out.generic = gens([h * sin(t), h / sin(t), h / cos(t), x + 2.0, x * 1.5])
	out.methods = {"right-triangle": method(["The angle is measured down from the horizontal, so the tangent is height ÷ distance.", "distance = %s ÷ %s = %s" % [D(s.h), tan_text(s), W(x)], say(ans)], ans.values),
		"alternate-angles": method(["The horizontals at T and F are parallel, so the angle of elevation of T from P is also %s." % angle_words(s), "tan %s = %s ÷ distance" % [angle_words(s), D(s.h)], "distance = %s ÷ %s = %s" % [D(s.h), tan_text(s), W(x)], say(ans)], ans.values)}
	return out


func u_angle_of_depression(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h: float = s.h.to_float()
	var x: float = s.x.to_float()
	var e := rad_to_deg(atan(h / x))
	var ans := ans_of("angle = ", e, "°")
	var lines := ["From the top T of a %s %s m high, a lookout sees %s at P on level ground." % [tall(s), D(s.h), SEEN[s.ctx]], "P is %s m from the foot of the %s." % [D(s.x), tall(s)]]
	var out := frame(rep, lines, sf3("Find the angle of depression of P from T."), ans, side_view(h, x, true, D(s.h) + " m", D(s.x) + " m", "?"))
	out.wrongs = bad(90.0 - e, R_FROM_VERTICAL)
	var hyp := sqrt(h * h + x * x)
	out.generic = gens([rad_to_deg(asin(h / hyp)) + 5.0, rad_to_deg(acos(h / hyp)) + 5.0, e / 2.0, e + 10.0, e * 1.5])
	var ratio := "tan⁻¹(%s ÷ %s)" % [D(s.h), D(s.x)]
	out.methods = {"right-triangle": method(["The angle is measured down from the horizontal, so its tangent is height ÷ distance.", "angle = %s = %s°" % [ratio, W(e)], say(ans)], ans.values),
		"alternate-angles": method(["The horizontals at T and F are parallel, so the angle equals the angle of elevation of T from P.", "In the triangle at P: tan(angle) = %s ÷ %s" % [D(s.h), D(s.x)], "angle = %s = %s°" % [ratio, W(e)], say(ans)], ans.values)}
	return out


func u_height_with_eye_level(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.x.to_float()
	var t := elev(s)
	var eye: float = s.eye.to_float()
	var rise := x * tan(t)
	var ans := ans_of("height = ", rise + eye, " m")
	var lines := ["A guard whose eyes are %s m above the level ground stands %s m from the foot of a %s." % [D(s.eye), D(s.x), tall(s)], "From the guard's eyes, the angle of elevation of the top is %s." % angle_words(s)]
	var g := sketch({"T": [0.0, rise + eye], "F": [0.0, 0.0], "Q": [x, 0.0], "E": [x, eye], "_L": [0.0, eye]},
		[side("F", "T", "?"), side("F", "Q", D(s.x) + " m"), side("Q", "E", D(s.eye) + " m"), side("E", "_L", "", true), side("E", "T", "", true)], [arc("E", "_L", "T", _angle_label(s))])
	var out := frame(rep, lines, sf3("Find the height of the %s." % tall(s)), ans, g)
	out.wrongs = bad(rise, R_NO_EYE)
	out.generic = gens([x * sin(t) + eye, x * tan(t) - eye, x / tan(t) + eye, rise + 2.0 * eye])
	out.methods = {"right-triangle": method(["From eye level up to the top: %s × %s = %s" % [D(s.x), tan_text(s), W(rise)], "Add the height of the eyes: %s + %s" % [W(rise), D(s.eye)], say(ans)], ans.values)}
	return out


func u_chain_below_hook(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.x.to_float()
	var t := elev(s)
	var eye: float = s.eye.to_float()
	var gp: float = s.gap.to_float()
	var top := x * tan(t)
	var v := top - eye - gp
	var ans := ans_of("length = ", v, " m")
	var lines := ["From a point P on level ground, %s m from the foot of a crane, the angle of elevation of the end T of its arm is %s." % [D(s.x), angle_words(s)],
		"A chain hangs straight down from T. A guard %s m tall stands under it, and the hook on the chain is %s m above the guard's head." % [D(s.eye), D(s.gap)]]
	var g := sketch({"T": [0.0, top], "F": [0.0, 0.0], "P": [x, 0.0], "H": [0.0, eye + gp], "G": [0.0, eye]},
		[side("F", "G", D(s.eye) + " m"), side("G", "H", D(s.gap) + " m"), side("H", "T", "?"), side("F", "P", D(s.x) + " m"), side("P", "T", "", true)], [arc("P", "F", "T", _angle_label(s))])
	var out := frame(rep, lines, sf3("Find the length of the chain."), ans, g)
	out.wrongs = bad(top - gp, R_NO_EYE)
	out.generic = gens([top - eye, top, x * sin(t) - eye - gp, top + eye + gp, v + 2.0])
	out.methods = {"right-triangle": method(["The end of the arm is %s × %s = %s m above the ground." % [D(s.x), tan_text(s), W(top)], "The hook is %s + %s m above the ground." % [D(s.eye), D(s.gap)], "length = %s − %s − %s" % [W(top), D(s.eye), D(s.gap)], say(ans)], ans.values)}
	return out


func u_time_from_depression(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h: float = s.h.to_float()
	var t := elev(s)
	var x := h / tan(t)
	var mins: float = x / 1000.0 / float(s.v1) * 60.0
	var ans := ans_of("time = ", mins, " minutes")
	var lines := ["From the top of a %s %s m high, a lookout sees %s at P. The angle of depression of P is %s." % [tall(s), D(s.h), SEEN[s.ctx], angle_words(s)],
		"A rescue cart leaves the foot of the %s and drives straight to P at %d km/h." % [tall(s), s.v1]]
	var g := side_view(20.0, 60.0, true, D(s.h) + " m", "", _angle_label(s), {"note": "not to scale"})
	var out := frame(rep, lines, sf3("Find the time the cart takes, in minutes."), ans, g)
	out.wrongs = bad(h * tan(t) / 1000.0 / float(s.v1) * 60.0, R_AT_TOP)
	out.generic = gens([x / 1000.0 / float(s.v1), h / sin(t) / 1000.0 / float(s.v1) * 60.0 * 1.5, x / float(s.v1), mins * 2.0, mins / 2.0])
	var km := W(x / 1000.0)
	out.methods = {"right-triangle": method(["distance = %s ÷ %s = %s m" % [D(s.h), tan_text(s), W(x)], "That is %s km, and time = distance ÷ speed." % km, "%s ÷ %d × 60 = %s" % [km, s.v1, W(back(km) / float(s.v1) * 60.0)], say(ans)], ans.values),
		"alternate-angles": method(["The horizontals are parallel, so the angle at P is also %s." % angle_words(s), "distance = %s ÷ %s = %s m, which is %s km" % [D(s.h), tan_text(s), W(x), km], "%s ÷ %d × 60 = %s" % [km, s.v1, W(back(km) / float(s.v1) * 60.0)], say(ans)], ans.values)}
	return out


# ── Connected triangles ──────────────────────────────────────

func u_route_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: float = s.d1.to_float()
	var b: float = s.d2.to_float()
	var hyp := sqrt(a * a + b * b)
	var direct: bool = s.which == "direct"
	var hours: float = hyp / float(s.v1) if direct else a / float(s.v1) + b / float(s.v2)
	var ans := ans_of("time = ", hours, " hours")
	var lines := ["A straight road runs through P and B, with PB = %s km. A camp at A is %s km from P, and AP is at right angles to the road." % [D(s.d2), D(s.d1)],
		"A courier's bike crosses the flats at %d km/h, and a truck drives along the road at %d km/h." % [s.v1, s.v2]]
	var asked := "The courier rides straight across the flats from A to B. Find the time this takes, in hours." if direct else "The courier rides from A to P, then takes the truck from P to B. Find the total time, in hours."
	var g := sketch({"A": [0.0, a], "P": [0.0, 0.0], "B": [-b, 0.0]}, [side("A", "P", D(s.d1) + " km"), side("P", "B", D(s.d2) + " km"), side("A", "B", "", true)], [], [], {"right": ["P"]})
	var out := frame(rep, lines, sf3(asked), ans, g)
	out.wrongs = []
	out.generic = gens([(a + b) / float(s.v1), hyp / float(s.v2), a / float(s.v2) + b / float(s.v1), (a + b) / float(s.v2), hours * 2.0, hours * 60.0])
	var h2 := W(a * a + b * b)
	var route: Array
	if direct:
		route = ["AP and PB are at right angles, so use Pythagoras: AB² = %s² + %s² = %s" % [D(s.d1), D(s.d2), h2], "AB = √%s = %s km" % [h2, W(sqrt(back(h2)))], "time = %s ÷ %d" % [W(sqrt(back(h2))), s.v1], say(ans)]
	else:
		route = ["Each leg has its own speed, so find each time and add.", "%s ÷ %d + %s ÷ %d = %s" % [D(s.d1), s.v1, D(s.d2), s.v2, W(hours)], say(ans)]
	out.methods = {"classify-given": method(route, ans.values)}
	return out


func u_shared_side(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var side2 := bd(s)
	var bc: float = s.bc.to_float()
	var x := sqrt(side2 * side2 + bc * bc - 2.0 * side2 * bc * cos(rad(s.dbc)))
	var ans := ans_of("CD = ", x, " km")
	var lines := ["Four beacons stand at A, B, C and D. AB = %s km, AD = %s km and angle BAD = 90°." % [D(s.ab), D(s.ad)],
		"BC = %s km and angle DBC = %d°. C and A are on opposite sides of BD." % [D(s.bc), s.dbc]]
	var g := sketch(quad(s), [side("A", "B", D(s.ab) + " km"), side("A", "D", D(s.ad) + " km"), side("B", "D", "", true), side("B", "C", D(s.bc) + " km"), side("C", "D", "?")], [arc("B", "D", "C", "%d°" % s.dbc)], [], {"right": ["A"]})
	var out := frame(rep, lines, sf3("Find CD."), ans, g)
	var rough: float = float(Fmt.sf(side2, 2))
	out.wrongs = bad(sqrt(rough * rough + bc * bc - 2.0 * rough * bc * cos(rad(s.dbc))), R_ROUND_EARLY) + bad(sqrt(side2 * side2 + bc * bc), R_LOOKS_RIGHT)
	out.generic = gens([side2 + bc, x + 2.0, x * 1.5, absf(side2 - bc)])
	var two := W(sq(s.ab) + sq(s.ad))
	var bdt := W(sqrt(back(two)))
	var cd2 := W(back(bdt) * back(bdt) + bc * bc - 2.0 * back(bdt) * bc * cos(rad(s.dbc)))
	out.methods = {"classify-given": method(["Triangle ABD has a right angle: BD² = %s² + %s² = %s" % [D(s.ab), D(s.ad), two], "BD = √%s = %s" % [two, bdt],
		"Triangle BCD has two sides and the angle between them, so use the cosine rule.", "CD² = %s² + %s² − 2 × %s × %s × cos %d° = %s" % [bdt, D(s.bc), bdt, D(s.bc), s.dbc, cd2], say(ans)], ans.values)}
	return out


func u_quadrilateral_area(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var side2 := bd(s)
	var bc: float = s.bc.to_float()
	var a1: float = 0.5 * s.ab.to_float() * s.ad.to_float() * sin(rad(s.a_angle))
	var a2 := 0.5 * side2 * bc * sin(rad(s.dbc))
	var ans := ans_of("area = ", a1 + a2, " km²")
	var lines := ["A field ABCD has AB = %s km, AD = %s km and angle BAD = %d°." % [D(s.ab), D(s.ad), s.a_angle],
		"BC = %s km and angle DBC = %d°, with C and A on opposite sides of BD." % [D(s.bc), s.dbc]]
	var g := sketch(quad(s), [side("A", "B", D(s.ab) + " km"), side("A", "D", D(s.ad) + " km"), side("B", "D", "", true), side("B", "C", D(s.bc) + " km"), side("C", "D")], [arc("A", "B", "D", "%d°" % s.a_angle), arc("B", "D", "C", "%d°" % s.dbc)])
	var out := frame(rep, lines, sf3("Find the area of the field."), ans, g)
	out.wrongs = []
	out.generic = gens([a1, a2, 2.0 * (a1 + a2), s.ab.to_float() * s.ad.to_float() * 0.5 + 0.5 * side2 * bc, a1 + a2 + 3.0])
	var bdsq := W(sq(s.ab) + sq(s.ad) - 2.0 * s.ab.to_float() * s.ad.to_float() * cos(rad(s.a_angle)))
	var bdt := W(sqrt(back(bdsq)))
	out.methods = {"either-diagonal": method(["Cut along BD. Triangle ABD: ½ × %s × %s × sin %d° = %s" % [D(s.ab), D(s.ad), s.a_angle, W(a1)],
		"BD² = %s² + %s² − 2 × %s × %s × cos %d° = %s, so BD = %s" % [D(s.ab), D(s.ad), D(s.ab), D(s.ad), s.a_angle, bdsq, bdt],
		"Triangle BCD: ½ × %s × %s × sin %d° = %s" % [bdt, D(s.bc), s.dbc, W(0.5 * back(bdt) * bc * sin(rad(s.dbc)))], "Add the two areas.", say(ans)], ans.values)}
	return out


func u_perpendicular_split(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ab: float = s.d1.to_float()
	var ac: float = s.d2.to_float()
	var c := cos(rad(s.phi))
	var x := sqrt(ab * ab + ac * ac - 2.0 * ab * ac * c)
	var ans := ans_of("BC = ", x, " km")
	var lines := ["A road runs straight from a camp A to a depot B, %s km away. A well at C is %s km from A, and angle BAC is %d°." % [D(s.d1), D(s.d2), s.phi]]
	var g := sketch({"A": [0.0, 0.0], "B": [ab, 0.0], "C": [ac * c, ac * sin(rad(s.phi))]}, [side("A", "B", D(s.d1) + " km"), side("A", "C", D(s.d2) + " km"), side("B", "C", "?")], [arc("A", "B", "C", "%d°" % s.phi)])
	var out := frame(rep, lines, sf3("Find the distance from the well to the depot."), ans, g)
	out.wrongs = bad(sqrt(ab * ab + ac * ac), R_LOOKS_RIGHT)
	out.generic = gens([ab + ac, absf(ab - ac) + 1.0, x + 2.0, x * 1.5, ab * sin(rad(s.phi))])
	var ht := W(ac * sin(rad(s.phi)))
	var ft := W(ac * c)
	var rest := W(ab - back(ft))
	var sq2 := W(ab * ab + ac * ac - 2.0 * ab * ac * c)
	out.methods = {"split-into-right": method(["Drop a perpendicular from C to AB. Its height is %s sin %d° = %s" % [D(s.d2), s.phi, ht], "Its foot is %s cos %d° = %s from A, so %s − %s = %s from B." % [D(s.d2), s.phi, ft, D(s.d1), ft, rest],
		"BC = √(%s² + %s²)" % [ht, rest], say(ans)], ans.values),
		"classify-given": method(["Two sides and the angle between them: use the cosine rule, as there is no right angle.", "BC² = %s² + %s² − 2 × %s × %s × cos %d° = %s" % [D(s.d1), D(s.d2), D(s.d1), D(s.d2), s.phi, sq2], say(ans)], ans.values)}
	return out


func u_rule_to_use(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.sides[0]
	var b: int = s.sides[1]
	var c: int = s.sides[2]
	var cosine := "The cosine rule"
	var sine := "The sine rule"
	var soh := "A right-angle ratio such as tan"
	var area := "½ab sin C"
	var line: String
	var ask: String
	var right: String
	var why: String
	var pts: Dictionary
	var lines_g: Array
	var arcs: Array = []
	var extra := {}
	match s.rule:
		"sas":
			line = "In triangle PQR, PQ = %d km, PR = %d km and angle QPR = %d°." % [a, b, s.phi]
			ask = "Which rule finds QR directly?"
			right = cosine
			why = "Two sides and the angle between them: no side is opposite a known angle, so the sine rule can't start."
			pts = {"P": [0.0, 0.0], "Q": [float(a), 0.0], "R": [b * cos(rad(s.phi)), b * sin(rad(s.phi))]}
			lines_g = [side("P", "Q", "%d km" % a), side("P", "R", "%d km" % b), side("Q", "R", "?")]
			arcs = [arc("P", "Q", "R", "%d°" % s.phi)]
		"sss":
			line = "In triangle PQR, PQ = %d km, PR = %d km and QR = %d km." % [a, b, c]
			ask = "Which rule finds angle QPR directly?"
			right = cosine
			why = "Three sides and no angle: the cosine rule is the one that gives an angle."
			var cs := float(a * a + b * b - c * c) / float(2 * a * b)
			pts = {"P": [0.0, 0.0], "Q": [float(a), 0.0], "R": [b * cs, b * sqrt(1.0 - cs * cs)]}
			lines_g = [side("P", "Q", "%d km" % a), side("P", "R", "%d km" % b), side("Q", "R", "%d km" % c)]
			arcs = [arc("P", "Q", "R", "?")]
		"aas":
			var third: int = 180 - s.phi - s.b1
			line = "In triangle PQR, PQ = %d km, angle QPR = %d° and angle PQR = %d°." % [a, s.phi, s.b1]
			ask = "Which rule finds PR directly, once angle PRQ is known?"
			right = sine
			why = "Angle PRQ is %d°, and it is opposite PQ, so there is a side with its opposite angle." % third
			var pr: float = a * sin(rad(s.b1)) / sin(rad(third))
			pts = {"P": [0.0, 0.0], "Q": [float(a), 0.0], "R": [pr * cos(rad(s.phi)), pr * sin(rad(s.phi))]}
			lines_g = [side("P", "Q", "%d km" % a), side("P", "R", "?"), side("Q", "R")]
			arcs = [arc("P", "Q", "R", "%d°" % s.phi), arc("Q", "P", "R", "%d°" % s.b1)]
		_:
			line = "In triangle PQR, angle PQR = 90°, PQ = %d km and angle QPR = %d°." % [a, s.phi]
			ask = "Which rule finds QR directly?"
			right = soh
			why = "There is a right angle, so tan %d° = QR ÷ %d." % [s.phi, a]
			pts = {"P": [0.0, 0.0], "Q": [float(a), 0.0], "R": [float(a), a * tan(rad(s.phi))]}
			lines_g = [side("P", "Q", "%d km" % a), side("P", "R"), side("Q", "R", "?")]
			arcs = [arc("P", "Q", "R", "%d°" % s.phi)]
			extra = {"right": ["Q"]}
	var ans := Answer.make("claim", {"form": "right", "vals": [], "text": right})
	var out := frame(rep, [line], ask, ans, sketch(pts, lines_g, arcs, [], extra))
	var opts: Array = [cosine, sine, soh, area].filter(func(o): return o != right)
	out.wrongs = []
	for i in opts.size():
		var ref: String = R_SINE_NO_PAIR if opts[i] == sine and s.rule in ["sas", "sss"] else ""
		out.wrongs.append(wrong({"form": "w%d" % i, "vals": [], "text": opts[i]}, ref))
	out.generic = []
	out.methods = {"classify-given": method([why, "Use this: " + Answer.text(ans) + "."], ans.values)}
	return out
