class_name ExactTriangleViews
extends ExtensionViews
## The views on the `exact-triangle` situation: one builder per unknown of t3-ext-exact-triangle
## (FAL-778). Every question is Paper 1; an answer is a whole number, a fraction or m√r, marked
## exactly (TriangleViews.exact_answer). Wrong options are SL3.5.exact-triangle's cos 120° = +½ and
## the type's own slips: cos C for sin C, no ½, no 2 in 2ab cos C, another angle's cosine, cos A for
## a height and the cosine rule's top line flipped. Error-spot shows an area left as a decimal, or a
## square root taken term by term.
##
## Representation: "diagram" (the labelled triangle, TriangleView; the height as a sketch with its
## right angle) and "words".

const SK := "SL3.5.exact-triangle#"
const R_COS120 := SK + "0"
const R_SPLIT_ROOT := SK + "1"
const R_DECIMAL := SK + "2"
const R_COS_FOR_SIN := "t3-ext-exact-triangle#3"
const R_NO_HALF := "t3-ext-exact-triangle#4"
const R_NO_TWO := "t3-ext-exact-triangle#5"
const R_OTHER_ANGLE := "t3-ext-exact-triangle#6"
const R_COS_HEIGHT := "t3-ext-exact-triangle#7"
const R_FLIPPED := "t3-ext-exact-triangle#8"
const UNKNOWNS := ["exact-area", "exact-side", "exact-cos", "side-from-exact-area", "exact-height"]
const S := preload("res://engine/situations/exact_triangle.gd")


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	return {"exact-area": ["error-spot"], "exact-side": ["error-spot"]}


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = S.export(s)
	return out


## An exact value as text: "4√3", "5√2/2", "−1/4".
static func ex(e: Array) -> String:
	return TriangleSituation.ex_text(e)


## m√r × k.
static func times(e: Array, k: Variant) -> Array:
	return [(e[0] as Q).mul(k), e[1]]


static func sin_t(deg: int) -> String:
	return ex(S.sin_of(deg))


static func cos_t(deg: int) -> String:
	return ex(S.cos_of(deg))


## A factor after × or ÷, in brackets unless it is a positive whole number: "(−1/2)", "(3√2)".
static func fac(e: Array) -> String:
	var t := ex(e)
	return t if (e[0] as Q).sign() > 0 and (e[0] as Q).is_int() and int(e[1]) == 1 else "(%s)" % t


## The triangle with a, b and C given, or the three sides: TriangleView's spec.
static func diagram(s: Dictionary, asked_side: String = "", show: Array = ["a", "b"], angle: String = "C") -> Dictionary:
	var a: float = s.a
	var b: float = s.b
	var C: float = s.C if s.C > 0 else rad_to_deg(acos(clampf((a * a + b * b - s.c * s.c) / (2.0 * a * b), -1.0, 1.0)))
	var pts := {"C": [0.0, 0.0], "B": [a, 0.0], "A": [b * cos(deg_to_rad(C)), b * sin(deg_to_rad(C))]}
	var lengths := {"a": s.a, "b": s.b, "c": s.c}
	var sides: Array = []
	for L in ["a", "b", "c"]:
		var label := ""
		if L in show:
			label = "%d cm" % lengths[L]
		elif L == asked_side:
			label = "?"
		sides.append({"side": L, "label": label})
	var angles: Array = []
	for V in ["A", "B", "C"]:
		var label := ""
		if V == "C" and angle == "C":
			label = "%d°" % s.C
		elif V == "C" and angle == "?":
			label = "?"
		angles.append({"at": V, "label": label})
	return {"vertices": pts, "sides": sides, "angles": angles}


## The givens in words.
static func two_sides(s: Dictionary) -> String:
	return "In triangle ABC, BC = %d cm, AC = %d cm and angle ACB = %d°." % [s.a, s.b, s.C]


func _pack(lines: Array, diag: Variant, graph: Variant, asked: String, ans: Dictionary, steps: Dictionary) -> Dictionary:
	var out := {"lines": lines, "diagram": diag, "graph": graph, "table": null, "asked": asked, "answer": ans, "wrongs": [], "fillers": [], "methods": {}}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


## Spare wrong options near an exact answer: m ± 1 and 2m on the same root.
static func near(e: Array) -> Array:
	var m: Q = e[0]
	return [[m.add(1), e[1]], [m.sub(1), e[1]], [m.mul(2), e[1]], [m.add(2), e[1]]]


func u_exact_area(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var C: int = s.C
	var e: Array = s.area
	var ans := TriangleViews.exact_answer("Area = ", " cm²", e)
	var lines := ["The diagram shows triangle ABC." if rep == "diagram" else two_sides(s)]
	var h := times(S.sin_of(C), b)
	var foot := "the angle between AC and BC is %d°" % C if C < 90 else "the angle between AC and BC extended past C is %d°" % (180 - C)
	var steps := {
		"exact-substitution": ["Area = ½ab sin C, with BC = %d, AC = %d and sin %d° = %s." % [a, b, C, sin_t(C)],
			"Area = ½ × %d × %d × %s = %s" % [a, b, sin_t(C), ex(e)], "So Area = %s cm²." % ex(e)],
		"drop-perpendicular": ["Drop the perpendicular from A to the line BC: %s." % foot,
			"In that right triangle the height is h = %d × %s = %s." % [b, sin_t(180 - C if C > 90 else C), ex(h)],
			"Area = ½ × BC × h = ½ × %d × %s = %s" % [a, fac(h), ex(e)], "So Area = %s cm²." % ex(e)],
	}
	var out := _pack(lines, diagram(s) if rep == "diagram" else null, null, "Find the exact area of triangle ABC.", ans, steps)
	if C == 60:
		TriangleViews.ex_wrong(out, [Q.new(a * b, 4), 1], R_COS_FOR_SIN)
	TriangleViews.ex_wrong(out, times(e, 2), R_NO_HALF)
	TriangleViews.ex_fillers(out, near(e))
	# Error-spot: the exact area worked out, then given as a decimal.
	var dec := "%.1f" % (e[0].to_float() * sqrt(float(e[1])))
	var spot := ["Area = ½ab sin C", "sin %d° = %s" % [C, sin_t(C)], "Area = ½ × %d × %d × %s = %s" % [a, b, sin_t(C), ex(e)], "So the area is %s cm²" % dec]
	var bad := 3
	if rng.chance(0.5):
		spot = ["sin %d° = %s" % [C, sin_t(C)], "Area = ½ × %d × %d × %s" % [a, b, sin_t(C)], "Area ≈ %s" % dec, "So the area is %s cm²" % dec]
		bad = 2
	out.spot = {"lines": spot, "bad": bad, "ref": R_DECIMAL, "why": "the question asks for the exact area, %s cm², not a decimal" % ex(e)}
	return out


func u_exact_side(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var C: int = s.C
	var c2: int = s.c2
	var e: Array = s.side
	var ans := TriangleViews.exact_answer("AB = ", " cm", e)
	var lines := ["The diagram shows triangle ABC." if rep == "diagram" else two_sides(s)]
	var sign := "+" if C == 120 else "−"
	var root := "√%d" % c2 + (" = %s" % ex(e) if int(e[1]) != c2 else "")
	var ch := Q.new(b, 2)
	var ah := times(S.sin_of(60), b)
	var hb: Q = Q.new(a).add(ch) if C == 120 else Q.new(a).sub(ch)
	var where := "beyond C, so HB = %d + %s = %s" % [a, ch.text(), hb.text()] if C == 120 else "between B and C, so HB = %d − %s = %s" % [a, ch.text(), hb.abs_q().text()]
	# For C = 60° the foot is CH = b/2 from C along CB: past B when b > 2a, at B when b = 2a.
	if C == 60 and hb.sign() < 0:
		where = "beyond B, so HB = %s − %d = %s" % [ch.text(), a, hb.abs_q().text()]
	elif C == 60 and hb.sign() == 0:
		where = "at B itself, so HB = 0 and AB = AH"
	var steps := {
		"exact-substitution": ["AB² = a² + b² − 2ab cos C, with cos %d° = %s." % [C, cos_t(C)],
			"AB² = %d + %d − 2 × %d × %d × %s = %d" % [a * a, b * b, a, b, fac(S.cos_of(C)), c2], "AB = %s" % root, "So AB = %s cm." % ex(e)],
		"drop-perpendicular": ["Drop the perpendicular from A to the line BC, meeting it at H: triangle ACH has angles 30°, 60° and 90°.",
			"So CH = %d ÷ 2 = %s and AH = %s, with H %s." % [b, ch.text(), ex(ah), where],
			"AB² = AH² + HB² = %s + %s = %d" % [ah[0].mul(ah[0]).mul(3).text(), hb.mul(hb).text(), c2], "So AB = %s cm." % ex(e)],
	}
	var out := _pack(lines, diagram(s, "c") if rep == "diagram" else null, null, "Find the exact length of AB.", ans, steps)
	if C == 120:
		TriangleViews.ex_wrong(out, S.simplify(a * a + b * b - a * b), R_COS120)
	TriangleViews.ex_wrong(out, S.simplify(a * a + b * b + (a * b / 2 if C == 120 else -a * b / 2)), R_NO_TWO)
	TriangleViews.ex_fillers(out, [S.simplify(a * a + b * b)] + near(e))
	# Error-spot: the square root taken of each term.
	var terms := "%d + %d %s %d" % [a * a, b * b, sign, a * b]
	var split := "%d + %d %s %s" % [a, b, sign, ex(S.simplify(a * b))]
	var spot := ["AB² = %d² + %d² − 2 × %d × %d × cos %d°" % [a, b, a, b, C], "AB² = %s" % terms, "AB = %s" % split, "So AB = %s cm" % split]
	var bad := 2
	if rng.chance(0.5):
		spot = ["cos %d° = %s" % [C, cos_t(C)], "AB² = %s" % terms, "AB = √(%s) = %s" % [terms, split], "So AB = %s cm" % split]
	out.spot = {"lines": spot, "bad": bad, "ref": R_SPLIT_ROOT, "why": "√(%s) is √%d = %s: a square root of a sum is not the sum of the square roots" % [terms, c2, ex(e)]}
	return out


func u_exact_cos(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var e: Array = s.cos
	var ans := TriangleViews.exact_answer("cos ACB = ", "", e)
	var lines := ["The diagram shows triangle ABC." if rep == "diagram" else "In triangle ABC, BC = %d cm, AC = %d cm and AB = %d cm." % [a, b, c]]
	var top := a * a + b * b - c * c
	var steps := {"exact-substitution": ["cos C = (a² + b² − c²)/(2ab), with c = AB, the side opposite C.",
		"cos C = (%d + %d − %d)/(2 × %d × %d) = %d/%d" % [a * a, b * b, c * c, a, b, top, 2 * a * b], "So cos ACB = %s." % ex(e)]}
	var out := _pack(lines, diagram(s, "", ["a", "b", "c"], "?") if rep == "diagram" else null, null, "Find the exact value of cos ACB.", ans, steps)
	out.wrongs = [wrong({"v": e[0].mul(2)}, R_NO_TWO), wrong({"v": Q.new(b * b + c * c - a * a, 2 * b * c)}, R_OTHER_ANGLE), wrong({"v": e[0].neg()}, R_FLIPPED)]
	out.fillers = [{"v": Q.new(top, a * b * 4)}, {"v": Q.new(top + 1, 2 * a * b)}]
	return out


func u_side_from_exact_area(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var C: int = s.C
	var e: Array = s.area
	var ans := TriangleViews.exact_answer("AC = ", " cm", [Q.new(b), 1])
	var k := times(S.sin_of(C), Q.new(a, 2))
	var lines: Array = ["The diagram shows triangle ABC. Its area is %s cm²." % ex(e)] if rep == "diagram" else \
		["In triangle ABC, BC = %d cm and angle ACB = %d°. The area of the triangle is %s cm²." % [a, C, ex(e)]]
	var steps := {"exact-substitution": ["Area = ½ab sin C, with BC = %d and sin %d° = %s." % [a, C, sin_t(C)],
		"%s = ½ × %d × AC × %s, so %s = %s × AC" % [ex(e), a, sin_t(C), ex(e), ex(k)], "AC = %s ÷ %s = %d" % [ex(e), fac(k), b], "So AC = %d cm." % b]}
	var out := _pack(lines, diagram(s, "b", ["a"]) if rep == "diagram" else null, null, "Find AC.", ans, steps)
	out.wrongs = [wrong({"v": Q.new(b / 2)}, R_NO_HALF)]
	out.fillers = [{"v": Q.new(2 * b)}, {"v": Q.new(b + 1)}, {"v": Q.new(b - 1)}, {"v": Q.new(b + 2)}]
	return out


func u_exact_height(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A: int = s.A
	var b: int = s.b
	var e: Array = s.h
	var ans := TriangleViews.exact_answer("CH = ", " cm", e)
	var ah := times(S.cos_of(A), b)
	var x: float = b * cos(deg_to_rad(A))
	var y: float = b * sin(deg_to_rad(A))
	var sketch := {"kind": "sketch", "pts": {"A": [0.0, 0.0], "B": [float(s.c), 0.0], "C": [x, y], "H": [x, 0.0]},
		"lines": [{"a": "A", "b": "H", "label": "", "dash": false}, {"a": "H", "b": "B", "label": "", "dash": false},
			{"a": "B", "b": "C", "label": "", "dash": false}, {"a": "A", "b": "C", "label": "%d cm" % b, "dash": false},
			{"a": "C", "b": "H", "label": "?", "dash": true}],
		"arcs": [{"at": "A", "from": "B", "to": "C", "label": "%d°" % A}], "north": [], "right": ["H"]}
	var kind := "45°, 45° and 90°" if A == 45 else "30°, 60° and 90°"
	var ratio := "1 : 1 : √2, so CH = %d ÷ √2 = %s" % [b, ex(e)] if A == 45 else \
		("1 : √3 : 2, and CH is opposite 30°, so CH = %d ÷ 2 = %s" % [b, ex(e)] if A == 30 else "1 : √3 : 2, and CH is opposite 60°, so CH = %d ÷ 2 × √3 = %s" % [b, ex(e)])
	var steps := {
		"exact-substitution": ["CH is opposite the angle at A in the right triangle ACH, whose hypotenuse is AC = %d." % b,
			"CH = %d sin %d° = %d × %s = %s" % [b, A, b, sin_t(A), ex(e)], "So CH = %s cm." % ex(e)],
		"drop-perpendicular": ["Triangle ACH has angles %s, with hypotenuse AC = %d." % [kind, b], "Its sides are in the ratio %s." % ratio, "So CH = %s cm." % ex(e)],
	}
	var out := _pack(["The diagram shows triangle ABC. The perpendicular from C meets AB at H."], null, sketch, "Find the exact length of CH.", ans, steps)
	TriangleViews.ex_wrong(out, ah, R_COS_HEIGHT)
	TriangleViews.ex_fillers(out, [[Q.new(b), 1], [Q.new(b), e[1]]] + near(e))
	return out
