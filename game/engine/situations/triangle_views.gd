class_name TriangleViews
extends RefCounted
## The views on the `triangle` situation: one builder per unknown of t3-sine-cosine-rule
## and t3-triangle-area (curriculum/question-types.json). A builder returns the same
## fields as the quadratic ones (see quadratic_views.gd), plus
##   diagram   the triangle to draw (or null): vertices, side and angle labels
##
## Representations: "words" (sides named by their ends, as the IB writes them: AB = 9 cm,
## angle BAC = 50°) and "diagram" (a labelled drawing, with the asked side or angle
## marked ?). Every answer is a measure written to 3 s.f. and marked to 3 s.f.
##
## `given` holds what the student is shown, for the SymPy checker: the givens kind,
## sides (letter -> cm), angles (letter -> degrees), area, obtuse, and ask.

const NEED := {
	"side-cosine-rule": {"givens": "sas"},
	"angle-cosine-rule": {"givens": "sss"},
	"side-sine-rule": {"givens": "aas"},
	"angle-sine-rule": {"givens": "ssa"},
	"area-from-two-sides": {"givens": "sas", "ask": "area"},
	"side-from-area": {"givens": "area-side"},
	"angle-from-area": {"givens": "area-angle"},
}

const CM := " cm"
const CM2 := " cm²"
const DEG := "°"
## Answers keep this many decimal places, far more than 3 s.f. needs.
const SCALE := 1000000000


func has(unknown: String) -> bool:
	return NEED.has(unknown)


func need(unknown: String, _rep: String) -> Dictionary:
	return NEED[unknown].duplicate()


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "diagram", "wrongs", "generic"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "generic"] else null
	return out


# ── Helpers ──────────────────────────────────────────────────

## A float as an answer value: a Y with nine decimal places.
static func qf(x: float) -> Q:
	return Q.new(roundi(x * SCALE), SCALE)


static func sf(x: float) -> String:
	return Fmt.sf(x)


## Working figures: four significant figures, one more than the answer.
static func w(x: float) -> String:
	return Fmt.sf(x, 4)


static func rad(deg: float) -> float:
	return deg_to_rad(deg)


static func deg(x: float) -> float:
	return rad_to_deg(x)


static func lo(letter: String) -> String:
	return letter.to_lower()


## The side opposite a vertex, by its ends: side("A") is "BC".
static func side(letter: String) -> String:
	var ends := ["A", "B", "C"].filter(func(x): return x != letter)
	return ends[0] + ends[1]


## The angle at a vertex, by three letters: angle("B") is "angle ABC".
static func angle(letter: String) -> String:
	var ends := ["A", "B", "C"].filter(func(x): return x != letter)
	return "angle %s%s%s" % [ends[0], letter, ends[1]]


static func cap(text: String) -> String:
	return text.left(1).to_upper() + text.substr(1)


## The line through two vertices, in alphabetical order: line("C", "A") is "AC".
static func line(p1: String, p2: String) -> String:
	return p1 + p2 if p1 < p2 else p2 + p1


static func whole(v: Variant) -> String:
	return str(int(v))


static func measure(label: String, x: float, unit: String) -> Dictionary:
	return Answer.make("measure", {"v": qf(x)}, {}, label, unit)


static func side_answer(letter: String, x: float) -> Dictionary:
	return measure(side(letter) + " = ", x, CM)


static func angle_answer(letter: String, x: float) -> Dictionary:
	return measure(angle(letter) + " = ", x, DEG)


static func res(x: float) -> Dictionary:
	return {"v": qf(x)}


## A wrong option, kept only when it is a real positive number.
static func wrong(out: Dictionary, x: float, ref: String = "") -> void:
	if is_finite(x) and x > 0.0:
		out.wrongs.append({"values": {"v": qf(x)}, "ref": ref})


static func generic(out: Dictionary, xs: Array) -> void:
	for x in xs:
		if is_finite(x) and x > 0.0:
			out.generic.append({"v": qf(x)})


## The question as the student sees it: lines (words), or a caption and a diagram.
## Sets lines, diagram and given on out and returns the intro sentence.
static func show(rep: String, s: Dictionary, out: Dictionary) -> void:
	var sh: Dictionary = s.shown
	out.given = {"givens": s.givens, "ask": s.ask, "sides": {}, "angles": {}, "area": null, "obtuse": null}
	for k in sh.sides:
		out.given.sides[k] = whole(sh.sides[k])
	for k in sh.angles:
		out.given.angles[k] = whole(sh.angles[k])
	if sh.area != null:
		out.given.area = whole(sh.area)
	if sh.obtuse != null:
		out.given.obtuse = sh.obtuse
	var facts: Array = []
	for k in sh.sides:
		facts.append("%s = %s cm" % [side(k.to_upper()), whole(sh.sides[k])])
	for k in sh.angles:
		facts.append("%s = %s°" % [angle(k), whole(sh.angles[k])])
	var tail := ""
	if sh.obtuse != null:
		tail = " %s is %s." % [cap(angle(s.X)), "obtuse" if sh.obtuse else "acute"]
	if rep == "words":
		if sh.area != null:
			out.lines = ["Triangle ABC has an area of %s cm². In it, %s.%s" % [whole(sh.area), and_list(facts), tail]]
		else:
			out.lines = ["In triangle ABC, %s." % and_list(facts)]
		return
	var cap := "The diagram shows triangle ABC (not to scale)."
	if sh.area != null:
		cap += " Its area is %s cm².%s" % [whole(sh.area), tail]
	out.lines = [cap]
	out.diagram = diagram(s)


static func and_list(items: Array) -> String:
	if items.size() == 1:
		return items[0]
	return ", ".join(items.slice(0, items.size() - 1)) + " and " + items[-1]


## The drawing: A at the origin, B along the x-axis, C above it, to scale; each side
## and angle carries its given value, ? when asked, or nothing.
static func diagram(s: Dictionary) -> Dictionary:
	var A: float = s.angles.A
	var b: float = s.sides.b
	var c: float = s.sides.c
	var pts := {"A": [0.0, 0.0], "B": [c, 0.0], "C": [b * cos(rad(A)), b * sin(rad(A))]}
	var sides: Array = []
	for L in ["A", "B", "C"]:
		var label := ""
		if s.shown.sides.has(lo(L)):
			label = whole(s.shown.sides[lo(L)]) + " cm"
		elif s.ask == lo(L):
			label = "?"
		sides.append({"side": lo(L), "label": label})
	var angles: Array = []
	for L in ["A", "B", "C"]:
		var label := ""
		if s.shown.angles.has(L):
			label = whole(s.shown.angles[L]) + "°"
		elif s.ask == L:
			label = "?"
		angles.append({"at": L, "label": label})
	return {"vertices": pts, "sides": sides, "angles": angles}


static func ask_side(letter: String) -> String:
	return "Find the length of %s, to 3 significant figures." % side(letter)


static func ask_angle(letter: String) -> String:
	return "Find the size of %s, to 3 significant figures." % angle(letter)


## "a = BC, b = AC": the sides a step uses, named both ways.
static func names(letters: Array) -> String:
	return "Label each side by the angle opposite it: " + ", ".join(letters.map(func(L): return "%s = %s" % [lo(L), side(L)])) + "."


# ── t3-sine-cosine-rule ──────────────────────────────────────

func u_side_cosine_rule(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var X: String = s.X
	var Y: String = s.Y
	var Z: String = s.Z
	var sy: float = s.sides[lo(Y)]
	var sz: float = s.sides[lo(Z)]
	var ax: float = s.angles[X]
	var ans := side_answer(X, s.value)
	var out := {"answer": ans, "wrongs": [], "generic": []}
	show(rep, s, out)
	out.asked = ask_side(X)
	var ty := whole(sy)
	var tz := whole(sz)
	var tX := whole(ax)
	var sx2 := sy * sy + sz * sz - 2.0 * sy * sz * cos(rad(ax))
	var sx := sqrt(sx2)
	var cosine := [
		names([X, Y, Z]),
		"%s is opposite %s, the angle between the two given sides, so use the cosine rule." % [side(X), angle(X)],
		"%s² = %s² + %s² − 2%s%s cos %s" % [lo(X), lo(Y), lo(Z), lo(Y), lo(Z), X],
		"%s² = %s² + %s² − 2 × %s × %s × cos %s° = %s" % [lo(X), ty, tz, ty, tz, tX, w(sx2)],
		"%s = √%s = %s" % [lo(X), w(sx2), sf(sx)],
		"So %s." % Answer.text(ans, res(sx))]
	# The perpendicular from Z to the line PQ, at F: RF = sy sin X and FQ = sz − sy cos X.
	var h := sy * sin(rad(ax))
	var fq := sz - sy * cos(rad(ax))
	var fq_text := "%s − %s cos %s°" % [tz, ty, tX]
	var perp := [
		"Drop a perpendicular from %s to the line %s, meeting it at F." % [Z, line(X, Y)],
		"In the right triangle %sF%s: %sF = %s sin %s° = %s cm." % [X, Z, Z, ty, tX, w(h)],
		("F%s = %s = %s cm." % [Y, fq_text, w(fq)]) if fq >= 0.0 else ("F lies beyond %s, so F%s = −(%s) = %s cm." % [Y, Y, fq_text, w(-fq)]),
		"In the right triangle %sF%s: %s² = %sF² + F%s² = %s² + %s² = %s" % [Z, Y, side(X), Z, Y, w(h), w(absf(fq)), w(h * h + fq * fq)],
		"%s = √%s = %s" % [side(X), w(h * h + fq * fq), sf(sqrt(h * h + fq * fq))],
		"So %s." % Answer.text(ans, res(sqrt(h * h + fq * fq)))]
	out.methods = {"cosine-rule": {"steps": cosine, "result": res(sx)},
		"drop-perpendicular": {"steps": perp, "result": res(sqrt(h * h + fq * fq))}}
	if cos(rad(ax)) > 0.0:
		wrong(out, sqrt((sy * sy + sz * sz - 2.0 * sy * sz) * cos(rad(ax))), "SL3.2.cosine-rule-side#0")
	wrong(out, sx2, "SL3.2.cosine-rule-side#1")
	wrong(out, sqrt(sy * sy + sz * sz - 2.0 * sy * sz * cos(ax)), "SL3.2.right-side#2")
	generic(out, [sqrt(sy * sy + sz * sz + 2.0 * sy * sz * cos(rad(ax))), sqrt(sy * sy + sz * sz), sy + sz - sx])
	return out


func u_angle_cosine_rule(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var X: String = s.X
	var Y: String = s.Y
	var Z: String = s.Z
	var sx: int = s.shown.sides[lo(X)]
	var sy: int = s.shown.sides[lo(Y)]
	var sz: int = s.shown.sides[lo(Z)]
	var ans := angle_answer(X, s.value)
	var out := {"answer": ans, "wrongs": [], "generic": []}
	show(rep, s, out)
	out.asked = ask_angle(X)
	var top := sy * sy + sz * sz - sx * sx
	var bottom := 2 * sy * sz
	var c := Q.new(top, bottom)
	var x := deg(acos(float(top) / bottom))
	var obtuse := "The cosine is negative, so the angle is obtuse." if top < 0 else ""
	var rearranged := [
		"%s is opposite %s = %d cm, so %s² is the square that is taken away." % [cap(angle(X)), side(X), sx, lo(X)],
		"cos %s = (%s² + %s² − %s²) / (2%s%s)" % [X, lo(Y), lo(Z), lo(X), lo(Y), lo(Z)],
		"cos %s = (%d² + %d² − %d²) / (2 × %d × %d) = %s / %d = %s" % [X, sy, sz, sx, sy, sz, Q.new(top).text(), bottom, c.text()],
		"%s = cos⁻¹(%s) = %s°" % [X, c.text(), sf(x)]]
	if obtuse != "":
		rearranged.append(obtuse)
	rearranged.append("So %s." % Answer.text(ans, res(x)))
	var solve := [
		"%s is opposite %s = %d cm." % [cap(angle(X)), side(X), sx],
		"%s² = %s² + %s² − 2%s%s cos %s" % [lo(X), lo(Y), lo(Z), lo(Y), lo(Z), X],
		"%d² = %d² + %d² − 2 × %d × %d × cos %s" % [sx, sy, sz, sy, sz, X],
		"%d = %d − %d cos %s" % [sx * sx, sy * sy + sz * sz, bottom, X],
		"%d cos %s = %s, so cos %s = %s" % [bottom, X, Q.new(top).text(), X, c.text()],
		"%s = cos⁻¹(%s) = %s°" % [X, c.text(), sf(x)]]
	if obtuse != "":
		solve.append(obtuse)
	solve.append("So %s." % Answer.text(ans, res(x)))
	out.methods = {"rearranged-formula": {"steps": rearranged, "result": res(x)},
		"substitute-then-solve": {"steps": solve, "result": res(x)}}
	wrong(out, s.angles[Y], "SL3.2.cosine-rule-angle#0")
	wrong(out, s.angles[Z], "SL3.2.cosine-rule-angle#0")
	if top < 0:
		wrong(out, 180.0 - x, "SL3.2.cosine-rule-angle#1")
	generic(out, [180.0 - x, deg(acos(clampf(float(sx * sx + sy * sy - sz * sz) / (2 * sx * sy), -1.0, 1.0))) + 5.0])
	return out


func u_side_sine_rule(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var X: String = s.X
	var Y: String = s.Y
	var Z: String = s.Z
	var sx: float = s.sides[lo(X)]
	var ax: float = s.angles[X]
	var ay: float = s.angles[Y]
	var az: float = s.angles[Z]
	var ans := side_answer(Y, s.value)
	var out := {"answer": ans, "wrongs": [], "generic": []}
	show(rep, s, out)
	out.asked = ask_side(Y)
	var first: Array = [names([X, Y])]
	if s.variant == "sum":
		first.append("%s is opposite %s, which is not given, so use the angle sum first: %s = 180° − %s° − %s° = %s°." % [
			side(Y), angle(Y), Y, whole(ax), whole(az), whole(ay)])
	var tX := whole(ax)
	var tY := whole(ay)
	var tx := whole(sx)
	var sy := sx * sin(rad(ay)) / sin(rad(ax))
	var top := first.duplicate()
	top.append_array([
		"%s / sin %s = %s / sin %s" % [lo(Y), Y, lo(X), X],
		"%s = %s sin %s / sin %s = %s sin %s° / sin %s° = %s" % [lo(Y), lo(X), Y, X, tx, tY, tX, sf(sy)],
		"So %s." % Answer.text(ans, res(sy))])
	var h := sx * sin(rad(ay))
	var q2 := h / sin(rad(ax))
	var alt := first.duplicate()
	alt.append_array([
		"Drop the altitude from %s to the line %s. Its height h is a side of two right triangles: h = %s sin %s and h = %s sin %s." % [
			Z, line(X, Y), lo(X), Y, lo(Y), X],
		"h = %s sin %s° = %s cm" % [tx, tY, w(h)],
		"%s = h / sin %s = %s / sin %s° = %s" % [lo(Y), X, w(h), tX, sf(q2)],
		"So %s." % Answer.text(ans, res(q2))])
	out.methods = {"sides-on-top": {"steps": top, "result": res(sy)}, "drop-altitude": {"steps": alt, "result": res(q2)}}
	wrong(out, sx * sin(rad(az)) / sin(rad(ax)), "SL3.2.sine-rule#0")
	wrong(out, sx * sin(rad(ax)) / sin(rad(ay)), "SL3.2.sine-rule#1")
	wrong(out, sx * sin(ay) / sin(ax), "SL3.2.right-side#2")
	generic(out, [sx * sin(rad(ay)), sx / sin(rad(ay)), sx * sin(rad(ax))])
	return out


func u_angle_sine_rule(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var X: String = s.X
	var Y: String = s.Y
	var Z: String = s.Z
	var sx: float = s.sides[lo(X)]
	var sy: float = s.sides[lo(Y)]
	var ax: float = s.angles[X]
	var ans := angle_answer(Y, s.value)
	var out := {"answer": ans, "wrongs": [], "generic": []}
	show(rep, s, out)
	out.asked = ask_angle(Y)
	var tx := whole(sx)
	var ty := whole(sy)
	var tX := whole(ax)
	var ratio := sy * sin(rad(ax)) / sx
	var x := deg(asin(ratio))
	var unique := "%s < %s, so %s < %s and %s is acute: 180° − %s° would leave no room for %s = %s°." % [
		lo(Y), lo(X), Y, X, Y, sf(x), X, tX]
	var sines := [
		names([X, Y]),
		"sin %s / %s = sin %s / %s" % [Y, lo(Y), X, lo(X)],
		"sin %s = %s sin %s / %s = %s sin %s° / %s = %s" % [Y, lo(Y), X, lo(X), ty, tX, tx, w(ratio)],
		"%s = sin⁻¹(%s) = %s°" % [Y, w(ratio), sf(x)],
		unique,
		"So %s." % Answer.text(ans, res(x))]
	var h := sy * sin(rad(ax))
	var x2 := deg(asin(h / sx))
	var alt := [
		names([X, Y]),
		"Drop the altitude from %s to the line %s: in the right triangle with hypotenuse %s, h = %s sin %s° = %s cm." % [
			Z, line(X, Y), lo(Y), ty, tX, w(h)],
		"In the right triangle with hypotenuse %s = %s cm: sin %s = h / %s = %s / %s = %s" % [lo(X), tx, Y, lo(X), w(h), tx, w(h / sx)],
		"%s = sin⁻¹(%s) = %s°" % [Y, w(h / sx), sf(x2)],
		unique,
		"So %s." % Answer.text(ans, res(x2))]
	out.methods = {"sines-on-top": {"steps": sines, "result": res(x)}, "drop-altitude": {"steps": alt, "result": res(x2)}}
	var swapped := sx * sin(rad(ax)) / sy
	if swapped < 1.0:
		wrong(out, deg(asin(swapped)), "SL3.2.sine-rule#0")
	wrong(out, 180.0 - x, "SL3.5.ambiguous-case#1")
	generic(out, [s.angles[Z], deg(asin(sy / sx)), ax * sy / sx])
	return out


# ── t3-triangle-area ─────────────────────────────────────────

func u_area_from_two_sides(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var X: String = s.X
	var Y: String = s.Y
	var Z: String = s.Z
	var sy: float = s.sides[lo(Y)]
	var sz: float = s.sides[lo(Z)]
	var ax: float = s.angles[X]
	var ans := measure("Area = ", s.value, CM2)
	var out := {"answer": ans, "wrongs": [], "generic": []}
	show(rep, s, out)
	out.asked = "Find the area of triangle ABC, to 3 significant figures."
	var ty := whole(sy)
	var tz := whole(sz)
	var tX := whole(ax)
	var area := 0.5 * sy * sz * sin(rad(ax))
	var half := [
		"%s is the angle between %s and %s, so use Area = ½%s%s sin %s." % [cap(angle(X)), side(Y), side(Z), lo(Y), lo(Z), X],
		"Area = ½ × %s × %s × sin %s° = %s" % [ty, tz, tX, sf(area)],
		"So %s." % Answer.text(ans, res(area))]
	var h := sy * sin(rad(ax))
	var area2 := 0.5 * sz * h
	var base := [
		"Take %s = %s cm as the base. The perpendicular height from %s is h = %s sin %s° = %s cm." % [side(Z), tz, Z, ty, tX, w(h)],
		"Area = ½ × base × height = ½ × %s × %s = %s" % [tz, w(h), sf(area2)],
		"So %s." % Answer.text(ans, res(area2))]
	out.methods = {"half-ab-sinc": {"steps": half, "result": res(area)}, "base-height": {"steps": base, "result": res(area2)}}
	wrong(out, 2.0 * area, "SL3.2.area-sine#2")
	wrong(out, 0.5 * sy * sz * sin(ax), "SL3.2.right-side#2")
	generic(out, [0.5 * sy * sz * absf(cos(rad(ax))), 0.5 * sy * sz, sy * sz * absf(cos(rad(ax)))])
	return out


func u_side_from_area(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var X: String = s.X
	var Y: String = s.Y
	var Z: String = s.Z
	var sy: float = s.sides[lo(Y)]
	var ax: float = s.angles[X]
	var area: int = s.shown.area
	var ans := side_answer(Z, s.value)
	var out := {"answer": ans, "wrongs": [], "generic": []}
	show(rep, s, out)
	out.asked = ask_side(Z)
	var ty := whole(sy)
	var tX := whole(ax)
	var sz := 2.0 * area / (sy * sin(rad(ax)))
	var half := [
		"%s is the angle between %s and %s, so Area = ½ × %s × %s × sin %s." % [cap(angle(X)), side(Y), side(Z), side(Y), side(Z), X],
		"%d = ½ × %s × %s × sin %s°" % [area, ty, side(Z), tX],
		"%s = 2 × %d / (%s sin %s°) = %s" % [side(Z), area, ty, tX, sf(sz)],
		"So %s." % Answer.text(ans, res(sz))]
	var h := sy * sin(rad(ax))
	var r2 := 2.0 * area / h
	var base := [
		"Take %s as the base. The perpendicular height from %s is h = %s sin %s° = %s cm." % [side(Z), Z, ty, tX, w(h)],
		"%d = ½ × %s × %s" % [area, side(Z), w(h)],
		"%s = 2 × %d / %s = %s" % [side(Z), area, w(h), sf(r2)],
		"So %s." % Answer.text(ans, res(r2))]
	out.methods = {"half-ab-sinc": {"steps": half, "result": res(sz)}, "base-height": {"steps": base, "result": res(r2)}}
	wrong(out, sz / 2.0, "SL3.2.area-sine#2")
	generic(out, [2.0 * area / sy, sz * sin(rad(ax)), area / sy])
	return out


func u_angle_from_area(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var X: String = s.X
	var Y: String = s.Y
	var Z: String = s.Z
	var sy: float = s.sides[lo(Y)]
	var sz: float = s.sides[lo(Z)]
	var area: int = s.shown.area
	var obtuse: bool = s.shown.obtuse
	var ans := angle_answer(X, s.value)
	var out := {"answer": ans, "wrongs": [], "generic": []}
	show(rep, s, out)
	out.asked = ask_angle(X)
	var ty := whole(sy)
	var tz := whole(sz)
	var ratio := 2.0 * area / (sy * sz)
	var acute := deg(asin(ratio))
	var x := 180.0 - acute if obtuse else acute
	var pick := ("%s is obtuse, so %s = 180° − %s° = %s°." % [cap(angle(X)), X, w(acute), sf(x)]) if obtuse \
		else ("%s is acute, so %s = %s°." % [cap(angle(X)), X, sf(x)])
	var frac := Q.new(2 * area, int(sy) * int(sz))
	var half := [
		"%s is the angle between %s and %s, so Area = ½%s%s sin %s." % [cap(angle(X)), side(Y), side(Z), lo(Y), lo(Z), X],
		"%d = ½ × %s × %s × sin %s" % [area, ty, tz, X],
		"sin %s = 2 × %d / (%s × %s) = %s = %s" % [X, area, ty, tz, frac.text(), w(ratio)],
		"sin⁻¹(%s) = %s°" % [w(ratio), w(acute)],
		pick,
		"So %s." % Answer.text(ans, res(x))]
	var h := 2.0 * area / sz
	var ratio2 := h / sy
	var acute2 := deg(asin(ratio2))
	var x2 := 180.0 - acute2 if obtuse else acute2
	var base := [
		"Take %s = %s cm as the base: %d = ½ × %s × h, so the height from %s is h = %s cm." % [side(Z), tz, area, tz, Z, w(h)],
		"That height is %s sin %s, so sin %s = h / %s = %s / %s = %s" % [lo(Y), X, X, lo(Y), w(h), ty, w(ratio2)],
		"sin⁻¹(%s) = %s°" % [w(ratio2), w(acute2)],
		pick,
		"So %s." % Answer.text(ans, res(x2))]
	var both := [
		"sin %s = 2 × Area / (%s%s) = 2 × %d / (%s × %s) = %s" % [X, lo(Y), lo(Z), area, ty, tz, w(ratio)],
		"Two angles from 0° to 180° have this sine: %s° and 180° − %s° = %s°. Both give the same area." % [w(acute), w(acute), w(180.0 - acute)],
		pick,
		"So %s." % Answer.text(ans, res(x))]
	out.methods = {"half-ab-sinc": {"steps": half, "result": res(x)}, "base-height": {"steps": base, "result": res(x2)},
		"reverse-two-angles": {"steps": both, "result": res(x)}}
	if obtuse:
		wrong(out, acute, "SL3.2.area-sine#1")
	var no_half := deg(asin(ratio / 2.0))
	wrong(out, 180.0 - no_half if obtuse else no_half, "SL3.2.area-sine#2")
	generic(out, [180.0 - x, deg(acos(ratio)), 90.0 - acute if not obtuse else 90.0 + acute / 2.0])
	return out
