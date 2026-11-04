class_name SolidViews
extends ExtensionViews
## The views on the `solid` situation: one builder per unknown of t3-solid-volume-area
## (FAL-726). Paper 1 answers are exact: a multiple of π is a `form` answer with the multiple
## typed, a pyramid's or a length's a whole `number`. Paper 2 answers are a `number` to 3 s.f.
## with the rounding trap. An expression is a `form` answer with its coefficients typed.
##
## Representations: "diagram" (the labelled sketch, PlotView's `solid`) and "words". In words
## each measure is one sentence the checker can read back: "The radius is 5 cm."

const SV := "SL3.1.volume-solids#"
const SA := "SL3.1.surface-area#"
const R_SLANT := SV + "0"
const R_THIRD := SV + "1"
const R_DIA := SV + "2"
const R_H_FOR_L := SA + "0"
const R_FLAT := SA + "1"
const R_FOUR := SA + "2"

const UNKNOWNS := ["cone-volume", "cone-volume-from-slant", "height-from-slant", "cone-curved", "cone-total", "slant-from-total",
	"cone-volume-from-total", "pyramid-volume", "pyramid-volume-from-slant", "pyramid-volume-from-edge", "pyramid-surface",
	"sphere-volume", "sphere-surface", "hemisphere-volume", "hemisphere-surface", "radius-from-volume", "height-from-volume",
	"composite-volume", "composite-surface", "paint-cost", "composite-volume-solve", "volume-in-terms", "surface-in-terms",
	"hollow-surface", "hollow-volume-from-surface", "surface-from-volume", "inscribed-volume", "inscribed-surface",
	"sector-cone-radius", "sector-angle", "sector-curved", "sector-cone-volume"]
## Algebra with letters in it, as on the bank's Paper 1 parts.
const PAPER_1 := ["volume-in-terms", "surface-in-terms", "hollow-surface", "hollow-volume-from-surface"]

## The stories, by solid: six of each, in cm.
const THINGS := {
	"cone": ["A drone's nose cone", "A funnel in the fuel depot", "A scrap-metal rain cap", "A marker on the salt road", "A lamp shade from the old depot", "A cast-iron plumb bob"],
	"pyramid": ["A marker stone at the crossroads", "A brass weight in the depot", "The cap of a filter housing", "A block from the camp's foundry", "The top of a solar lamp", "A trader's counterweight"],
	"sphere": ["A float in the well", "A signal buoy's core", "A ball bearing from the old mill", "A drone's sensor pod", "A lead weight", "A glass filter ball"],
	"hemisphere": ["A scrap-metal cap", "A drone's sensor dome", "A lamp cover", "A cast-iron mould", "A well stopper", "A lead sinker"],
	"composite": ["A well float", "A drone's fuel pod", "A beacon's counterweight", "A signal buoy", "A salt mill's body", "A lamp stand"],
	"tank": ["A water tank at the camp", "A fuel tank at the depot", "A grain silo", "A storage tower", "A rain tank on the ridge", "A watchtower"],
	"hollow": ["A concrete well ring", "A section of old pipe", "A lead collar", "A pump sleeve", "A fuel line coupling", "A steel bushing"],
	"sector": ["A sheet of scrap tin", "A piece of old canvas", "A piece of roofing metal", "A sheet of thin copper", "A piece of drone wing", "A sheet of plastic from a rain tank"],
}
const PHRASE := {
	"cone": "a right cone", "pyramid": "a right pyramid", "sphere": "a solid sphere", "hemisphere": "a solid hemisphere",
	"cone-hemisphere": "a solid made of a cone on a hemisphere with the same radius",
	"cone-cylinder": "a solid made of a cone on a cylinder with the same radius",
	"hemisphere-cylinder": "a solid made of a hemisphere on a cylinder with the same radius",
	"cylinder-minus-hemisphere": "a solid cylinder with a hemisphere hollowed out of its top",
	"capsule": "a solid made of a cylinder with a hemisphere on each end",
	"hollow": "a solid cylinder with a smaller cylinder removed from its centre",
	"inscribed": "a solid cylinder that fits exactly inside a hollow sphere",
}
## A measure's name in words, on a plain solid and on a composite.
const NAMES := {"r": "radius", "d": "diameter", "h": "height", "l": "slant height", "t": "slant height of each face",
	"e": "slant edge", "a": "base edge", "b": "other base edge", "theta": "angle"}
const JOINED := {"h": "cone's height", "l": "cone's slant height", "c": "cylinder's height", "big": "cylinder's radius"}


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## The GDC solver is Paper 2, and the letters are Paper 1, as in the bank.
func papers(unknown: String, _rep: String, angle: String) -> Array:
	if not has(unknown):
		return []
	if angle.begins_with("gdc-"):
		return [2]
	return [1] if unknown in PAPER_1 else [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = SolidSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

## Paper 1 figures are whole, so every multiple here has a small denominator.
static func qk(x: float) -> Q:
	return Q.new(roundi(x * 120.0), 120)


## Working figures on Paper 2: five, so the next step is right to 3 s.f.
static func w(x: float) -> String:
	return Fmt.sf(x, 5)


## A length as the working writes it: as given where it has one decimal place.
static func M(x: float) -> String:
	return Fmt.dec(Q.new(roundi(x * 10.0), 10)) if absf(x * 10.0 - roundf(x * 10.0)) < 1e-9 else w(x)


## A value in the working: a multiple of π, exact, or a number on Paper 2.
static func E(s: Dictionary, x: float, pi: bool = true) -> String:
	if s.paper == 2:
		return w(x * (PI if pi else 1.0))
	return Fmt.lead(qk(x)) + "π" if pi else Fmt.num(qk(x))


## The answer: x, or x times π, with `head` before it and `unit` after.
static func val(s: Dictionary, head: String, x: float, unit: String, pi: bool) -> Dictionary:
	if s.paper == 2:
		var sf := Answer.make("number", {"v": GdcKit.qf(x * (PI if pi else 1.0))}, {}, head, unit)
		sf.show = "sf"
		return sf
	if pi:
		var q := qk(x)
		return DifferentiationViews.form(head + Fmt.lead(q) + "π" + unit, [head, {"slot": "v"}, "π" + unit], {"v": q})
	var ans := Answer.make("number", {"v": qk(x)}, {}, head, unit)
	ans.exact = true
	return ans


## The start of a builder's result: the answer, its wrong options as [value, ref], and some
## more, each only if it is positive and differs from the answer.
static func pack(s: Dictionary, head: String, unit: String, pi: bool, x: float, wrongs: Array, more: Array = []) -> Dictionary:
	var out := {"answer": val(s, head, x, unit, pi), "table": null, "wrongs": [], "generic": []}
	for item in wrongs:
		if item[0] > 0.0 and absf(item[0] - x) > 1e-9:
			out.wrongs.append(wrong(val(s, head, item[0], unit, pi).values, item[1]))
	for v in more + [x * 2.0, x / 2.0, x * 1.5, x * 3.0, x * 0.75, x * 4.0]:
		if v > 0.0 and absf(v - x) > 1e-9:
			out.generic.append(val(s, head, v, unit, pi).values)
	return out


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func thing(s: Dictionary, kind: String) -> String:
	return THINGS[kind][s.ctx]


static func family(shape: String) -> String:
	return shape if THINGS.has(shape) else "composite"


## A measure with its unit: "5 cm", "5.2 m".
static func sized(s: Dictionary, x: float) -> String:
	return "%s %s" % [M(x), s.unit]


## The label of a shown measure.
static func measure(s: Dictionary, key: String) -> String:
	if key == "d":
		return sized(s, 2.0 * s.r)
	if key == "theta":
		return M(s.theta) + "°"
	return sized(s, s[key])


static func name_of(s: Dictionary, key: String) -> String:
	if s.shape in SolidSituation.COMPOSITES and JOINED.has(key):
		return JOINED[key]
	if s.shape == "cylinder-minus-hemisphere" and key == "r":
		return "hemisphere's radius"
	if s.shape == "inscribed":
		return {"r": "sphere's radius", "h": "cylinder's height"}[key]
	return NAMES[key]


## "The radius is 5 cm and the height is 12 cm."
static func say(names: Array, shown: Array) -> String:
	var parts: Array = []
	for i in names.size():
		parts.append("the %s is %s" % [names[i], shown[i]])
	var body: String = parts[0] if parts.size() == 1 else ", ".join(parts.slice(0, -1)) + " and " + parts[-1]
	return body.left(1).to_upper() + body.substr(1) + "."


## Sets lines and the figure from the measures shown. `extra` is a sentence after them, and
## `over` replaces a label by its text, for a letter or an expression.
static func show(out: Dictionary, s: Dictionary, rep: String, opening: String, keys: Array, extra: Array = [], over: Dictionary = {}) -> void:
	var fig := {"kind": "solid", "shape": s.shape}
	var names: Array = []
	var shown: Array = []
	for key in keys:
		var text: String = over[key] if over.has(key) else measure(s, key)
		fig[key] = text
		names.append(name_of(s, key))
		shown.append(text)
	if rep == "diagram":
		out.lines = [opening + ", as in the diagram."] + extra
		out.graph = fig
	elif names.is_empty():
		out.lines = [opening + "."] + extra
	else:
		out.lines = [opening + ".", say(names, shown)] + extra


## r or d, as this question shows the circle.
static func rk(s: Dictionary) -> String:
	return "d" if s.get("dia", false) else "r"


static func half_step(s: Dictionary) -> Array:
	return ["The radius is half the diameter: r = %s ÷ 2 = %s" % [M(2.0 * s.r), M(s.r)]] if s.get("dia", false) else []


static func cone_v_text(s: Dictionary) -> String:
	return "(1/3) × π × %s² × %s" % [M(s.r), M(s.h)]


## "l = √(5² + 12²) = 13", the step from r and h to the slant height.
static func l_step(s: Dictionary) -> String:
	return "l = √(r² + h²) = √(%s² + %s²) = %s" % [M(s.r), M(s.h), M(s.l)]


## "h = √(13² − 5²) = 12", the step from l and r to the height.
static func h_step(s: Dictionary) -> String:
	return "h = √(l² − r²) = √(%s² − %s²) = %s" % [M(s.l), M(s.r), M(s.h)]


## The unit of an area and of a volume.
static func u2(s: Dictionary) -> String:
	return " %s²" % s.unit


static func u3(s: Dictionary) -> String:
	return " %s³" % s.unit


# ── Cones ────────────────────────────────────────────────────

func u_cone_volume(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.r * s.r * s.h / 3.0
	var wrongs: Array = [[s.r * s.r * s.h, R_THIRD]]
	if s.dia:
		wrongs.append([4.0 * x, R_DIA])
	var out := pack(s, "V = ", u3(s), true, x, wrongs, [s.r * s.h, s.r * s.r * s.h / 2.0])
	show(out, s, rep, "%s is %s" % [thing(s, "cone"), PHRASE.cone], [rk(s), "h"])
	out.asked = "Find the volume of the cone."
	out.methods = {"booklet-formula": method(half_step(s) + ["V = (1/3)πr²h = %s = %s" % [cone_v_text(s), E(s, x)], final_step(out.answer)], out.answer.values)}
	return out


func u_cone_volume_from_slant(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.r * s.r * s.h / 3.0
	var out := pack(s, "V = ", u3(s), true, x, [[s.r * s.r * s.l / 3.0, R_SLANT], [s.r * s.r * s.h, R_THIRD]], [s.r * s.l])
	show(out, s, rep, "%s is %s" % [thing(s, "cone"), PHRASE.cone], ["r", "l"])
	out.asked = "Find the volume of the cone."
	out.methods = {"height-by-pythagoras": method([h_step(s), "V = (1/3)πr²h = %s = %s" % [cone_v_text(s), E(s, x)], final_step(out.answer)], out.answer.values)}
	return out


func u_height_from_slant(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var unit: String = " " + s.unit
	var out := pack(s, "h = ", unit, false, s.h, [], [s.l + s.r, s.l - s.r, sqrt(s.l * s.l + s.r * s.r) if s.paper == 2 else s.l])
	show(out, s, rep, "%s is %s" % [thing(s, "cone"), PHRASE.cone], ["r", "l"])
	out.asked = "Find the perpendicular height of the cone."
	out.methods = {"height-by-pythagoras": method(["The height, the radius and the slant height make a right triangle, with l the longest side.", h_step(s), final_step(out.answer)], out.answer.values)}
	return out


func u_cone_curved(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.r * s.l
	var wrongs: Array = [[s.r * s.h, R_H_FOR_L]] if s.given == "h" else []
	var out := pack(s, "area = ", u2(s), true, x, wrongs, [s.r * s.r + x, 2.0 * x])
	show(out, s, rep, "%s is %s" % [thing(s, "cone"), PHRASE.cone], ["r", s.given])
	out.asked = "Find the curved surface area of the cone."
	var first: Array = [l_step(s)] if s.given == "h" else []
	var ring := "π × %s × %s" % [M(s.r), M(s.l)]
	out.methods = {"booklet-formula": method(first + ["Curved surface = πrl = %s = %s" % [ring, E(s, x)], final_step(out.answer)], out.answer.values),
		"unrolled-sector": method(first + ["Unrolled, the curved surface is a sector with radius l and arc 2πr.",
			"Area = (1/2) × l × 2πr = (1/2) × %s × 2 × π × %s = %s" % [M(s.l), M(s.r), E(s, x)], final_step(out.answer)], out.answer.values)}
	return out


func u_cone_total(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.r * s.l + s.r * s.r
	var wrongs: Array = [[s.r * s.h + s.r * s.r, R_H_FOR_L]] if s.given == "h" else []
	var out := pack(s, "area = ", u2(s), true, x, wrongs, [s.r * s.l, s.r * s.l + 2.0 * s.r * s.r])
	show(out, s, rep, "%s is %s, closed by a flat circular base" % [thing(s, "cone"), PHRASE.cone], ["r", s.given])
	out.asked = "Find the total surface area of the cone."
	var first: Array = [l_step(s)] if s.given == "h" else []
	var curved := "π × %s × %s = %s" % [M(s.r), M(s.l), E(s, s.r * s.l)]
	var base := "π × %s² = %s" % [M(s.r), E(s, s.r * s.r)]
	out.methods = {"booklet-formula": method(first + ["A = πrl + πr² = π × %s × %s + π × %s² = %s" % [M(s.r), M(s.l), M(s.r), E(s, x)], final_step(out.answer)], out.answer.values),
		"net-face-by-face": method(first + ["The curved surface: " + curved, "The base circle: " + base, "Adding the two faces gives %s." % E(s, x), final_step(out.answer)], out.answer.values)}
	return out


## "The total surface area is 90π cm²."
static func area_line(s: Dictionary) -> String:
	return "The total surface area is %s%s." % [Fmt.lead(qk(s.area)) + "π" if s.paper == 1 else M(s.area), u2(s)]


func u_slant_from_total(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var unit: String = " " + s.unit
	var out := pack(s, "l = ", unit, false, s.l, [], [s.h, s.l + s.r, absf(s.l - s.r)])
	show(out, s, rep, "%s is %s, closed by a flat circular base" % [thing(s, "cone"), PHRASE.cone], ["r"], [area_line(s)])
	out.asked = "Find the slant height of the cone."
	var a: String = Fmt.lead(qk(s.area)) + "π" if s.paper == 1 else M(s.area)
	out.methods = {"booklet-formula": method(["πrl + πr² = %s" % a, "%sl = %s − %s" % [E(s, s.r), a, E(s, s.r * s.r)] if s.paper == 1 else "π × %s × l = %s − π × %s²" % [M(s.r), a, M(s.r)],
		"l = %s" % M(s.l), final_step(out.answer)], out.answer.values)}
	return out


func u_cone_volume_from_total(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.r * s.r * s.h / 3.0
	var out := pack(s, "V = ", u3(s), true, x, [[s.r * s.r * s.l / 3.0, R_SLANT], [s.r * s.r * s.h, R_THIRD]], [s.r * s.h])
	show(out, s, rep, "%s is %s, closed by a flat circular base" % [thing(s, "cone"), PHRASE.cone], ["r"], [area_line(s)])
	out.asked = "Find the volume of the cone."
	var a: String = Fmt.lead(qk(s.area)) + "π" if s.paper == 1 else M(s.area)
	out.methods = {"height-by-pythagoras": method(["πrl + πr² = %s gives l = %s" % [a, M(s.l)], h_step(s), "V = (1/3)πr²h = %s = %s" % [cone_v_text(s), E(s, x)], final_step(out.answer)], out.answer.values)}
	return out


# ── Pyramids ─────────────────────────────────────────────────

static func pyr_v_text(s: Dictionary) -> String:
	return "(1/3) × %s × %s × %s" % [M(s.a), M(s.b), M(s.h)]


func u_pyramid_volume(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.a * s.b * s.h / 3.0
	var out := pack(s, "V = ", u3(s), false, x, [[s.a * s.b * s.h, R_THIRD]], [(s.a + s.b) * s.h / 3.0, s.a * s.b * s.h / 2.0])
	var kind := "a square base" if s.a == s.b else "a rectangular base"
	show(out, s, rep, "%s is %s with %s" % [thing(s, "pyramid"), PHRASE.pyramid, kind], ["a", "h"] if s.a == s.b else ["a", "b", "h"])
	out.asked = "Find the volume of the pyramid."
	out.methods = {"booklet-formula": method(["The base area is %s × %s = %s." % [M(s.a), M(s.b), M(s.a * s.b)], "V = (1/3)Bh = %s = %s" % [pyr_v_text(s), E(s, x, false)], final_step(out.answer)], out.answer.values)}
	return out


func u_pyramid_volume_from_slant(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.a * s.a * s.h / 3.0
	var out := pack(s, "V = ", u3(s), false, x, [[s.a * s.a * s.t / 3.0, R_SLANT], [s.a * s.a * s.h, R_THIRD]], [s.a * s.h])
	show(out, s, rep, "%s is %s with a square base" % [thing(s, "pyramid"), PHRASE.pyramid], ["a", "t"])
	out.asked = "Find the volume of the pyramid."
	out.methods = {"height-by-pythagoras": method(["The height, half the base edge and the face's slant height make a right triangle.",
		"h = √(%s² − %s²) = %s" % [M(s.t), M(s.a / 2.0), M(s.h)], "V = (1/3)Bh = %s = %s" % [pyr_v_text(s), E(s, x, false)], final_step(out.answer)], out.answer.values)}
	return out


func u_pyramid_volume_from_edge(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.a * s.a * s.h / 3.0
	var out := pack(s, "V = ", u3(s), false, x, [[s.a * s.a * s.e / 3.0, R_SLANT], [s.a * s.a * s.h, R_THIRD]], [s.a * s.h])
	show(out, s, rep, "%s is %s with a square base" % [thing(s, "pyramid"), PHRASE.pyramid], ["a", "e"])
	out.asked = "Find the volume of the pyramid."
	var half2: float = s.a * s.a / 2.0
	out.methods = {"height-by-pythagoras": method(["Half the base's diagonal squared is %s²/2 = %s." % [M(s.a), M(half2)],
		"h = √(%s² − %s) = %s" % [M(s.e), M(half2), M(s.h)], "V = (1/3)Bh = %s = %s" % [pyr_v_text(s), E(s, x, false)], final_step(out.answer)], out.answer.values)}
	return out


func u_pyramid_surface(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.a * s.a + 2.0 * s.a * s.t
	var out := pack(s, "area = ", u2(s), false, x, [[s.a * s.a + 2.0 * s.a * s.h, R_H_FOR_L]], [2.0 * s.a * s.t, s.a * s.a + 4.0 * s.a * s.t])
	show(out, s, rep, "%s is %s with a square base" % [thing(s, "pyramid"), PHRASE.pyramid], ["a", "h"])
	out.asked = "Find the total surface area of the pyramid."
	out.methods = {"net-face-by-face": method(["Each face's slant height: √(%s² + %s²) = %s" % [M(s.h), M(s.a / 2.0), M(s.t)],
		"Four triangles: 4 × (1/2) × %s × %s = %s" % [M(s.a), M(s.t), M(2.0 * s.a * s.t)], "The base: %s² = %s" % [M(s.a), M(s.a * s.a)],
		"Adding the five faces gives %s." % E(s, x, false), final_step(out.answer)], out.answer.values)}
	return out


# ── Spheres and hemispheres ──────────────────────────────────

func u_sphere_volume(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = 4.0 * pow(s.r, 3.0) / 3.0
	var wrongs: Array = [[8.0 * x, R_DIA]] if s.dia else []
	var out := pack(s, "V = ", u3(s), true, x, wrongs, [4.0 * s.r * s.r, x / 2.0])
	show(out, s, rep, "%s is %s" % [thing(s, "sphere"), PHRASE.sphere], [rk(s)])
	out.asked = "Find the volume of the sphere."
	out.methods = {"booklet-formula": method(half_step(s) + ["V = (4/3)πr³ = (4/3) × π × %s³ = %s" % [M(s.r), E(s, x)], final_step(out.answer)], out.answer.values)}
	return out


func u_sphere_surface(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = 4.0 * s.r * s.r
	var wrongs: Array = [[4.0 * x, R_DIA]] if s.dia else []
	var out := pack(s, "area = ", u2(s), true, x, wrongs, [x / 2.0, s.r * s.r, 4.0 * pow(s.r, 3.0) / 3.0])
	show(out, s, rep, "%s is %s" % [thing(s, "sphere"), PHRASE.sphere], [rk(s)])
	out.asked = "Find the surface area of the sphere."
	out.methods = {"booklet-formula": method(half_step(s) + ["A = 4πr² = 4 × π × %s² = %s" % [M(s.r), E(s, x)], final_step(out.answer)], out.answer.values)}
	return out


func u_hemisphere_volume(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = 2.0 * pow(s.r, 3.0) / 3.0
	var wrongs: Array = [[2.0 * x, R_THIRD]]
	if s.dia:
		wrongs.append([8.0 * x, R_DIA])
	var out := pack(s, "V = ", u3(s), true, x, wrongs, [2.0 * s.r * s.r, 3.0 * s.r * s.r])
	show(out, s, rep, "%s is %s" % [thing(s, "hemisphere"), PHRASE.hemisphere], [rk(s)])
	out.asked = "Find the volume of the hemisphere."
	out.methods = {"booklet-formula": method(half_step(s) + ["A hemisphere is half a sphere: V = (2/3)πr³", "V = (2/3) × π × %s³ = %s" % [M(s.r), E(s, x)], final_step(out.answer)], out.answer.values)}
	return out


func u_hemisphere_surface(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = 3.0 * s.r * s.r
	var wrongs: Array = [[2.0 * s.r * s.r, R_FLAT], [4.0 * s.r * s.r, R_FOUR]]
	if s.dia:
		wrongs.append([4.0 * x, R_DIA])
	var out := pack(s, "area = ", u2(s), true, x, wrongs, [s.r * s.r, 2.0 * pow(s.r, 3.0) / 3.0])
	show(out, s, rep, "%s is %s" % [thing(s, "hemisphere"), PHRASE.hemisphere], [rk(s)])
	out.asked = "Find the total surface area of the hemisphere."
	out.methods = {"booklet-formula": method(half_step(s) + ["A = 2πr² + πr² = 3πr²", "A = 3 × π × %s² = %s" % [M(s.r), E(s, x)], final_step(out.answer)], out.answer.values),
		"net-face-by-face": method(half_step(s) + ["The curved part: 2 × π × %s² = %s" % [M(s.r), E(s, 2.0 * s.r * s.r)], "The flat circle: π × %s² = %s" % [M(s.r), E(s, s.r * s.r)], final_step(out.answer)], out.answer.values)}
	return out


# ── A missing length from a volume ───────────────────────────

## "The volume is 288π cm³."
static func vol_line(s: Dictionary) -> String:
	return "The volume is %s%s." % [(Fmt.lead(qk(s.vol)) + "π") if s.paper == 1 and SolidSituation.has_pi(s) else M(s.vol), u3(s)]


func u_radius_from_volume(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var unit: String = " " + s.unit
	var wrongs: Array = [[2.0 * s.r, R_DIA]]
	if s.paper == 2:
		# With the hemisphere's or the cone's fraction missed, r doesn't come out whole.
		if s.shape == "hemisphere":
			wrongs.append([pow(3.0 * s.vol / (4.0 * PI), 1.0 / 3.0), R_THIRD])
		elif s.shape == "cone":
			wrongs.append([sqrt(s.vol / (PI * s.h)), R_THIRD])
	var out := pack(s, "r = ", unit, false, s.r, wrongs, [s.r * s.r, s.r + 1.0, s.r + 2.0, s.r + 3.0])
	show(out, s, rep, "%s is %s" % [thing(s, family(s.shape)), PHRASE[s.shape]], ["h"] if s.shape == "cone" else [], [vol_line(s)])
	if rep == "diagram":
		out.graph.r = "r"
	out.asked = "Find the radius."
	var v: String = (Fmt.lead(qk(s.vol)) + "π") if s.paper == 1 else M(s.vol)
	var steps: Array
	match s.shape:
		"sphere":
			steps = ["(4/3)πr³ = %s" % v, "r³ = 3 × %s ÷ (4π) = %s" % [v, M(pow(s.r, 3.0))]]
		"hemisphere":
			steps = ["(2/3)πr³ = %s" % v, "r³ = 3 × %s ÷ (2π) = %s" % [v, M(pow(s.r, 3.0))]]
		_:
			steps = ["(1/3)πr² × %s = %s" % [M(s.h), v], "r² = 3 × %s ÷ (π × %s) = %s" % [v, M(s.h), M(s.r * s.r)]]
	out.methods = {"rearrange": method(steps + ["r = %s" % M(s.r), final_step(out.answer)], out.answer.values)}
	return out


func u_height_from_volume(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var unit: String = " " + s.unit
	var wrongs: Array = [[s.h / 3.0, R_THIRD]]
	if s.get("dia", false):
		wrongs.append([s.h / 4.0, R_DIA])
	var out := pack(s, "h = ", unit, false, s.h, wrongs, [s.h + 1.0, s.h + 2.0, s.h * 3.0])
	var cone: bool = s.shape == "cone"
	show(out, s, rep, "%s is %s%s" % [thing(s, family(s.shape)), PHRASE[s.shape], "" if cone else " with a square base"], [rk(s)] if cone else ["a"], [vol_line(s)])
	if rep == "diagram":
		out.graph.h = "h"
	out.asked = "Find the perpendicular height."
	var v: String = (Fmt.lead(qk(s.vol)) + "π") if s.paper == 1 and cone else M(s.vol)
	var first: Array = half_step(s) if cone else []
	var move: String = "%s = (1/3)π × %s² × h" % [v, M(s.r)] if cone else "%s = (1/3) × %s² × h" % [v, M(s.a)]
	var solve: String = "h = 3 × %s ÷ (π × %s²)" % [v, M(s.r)] if cone else "h = 3 × %s ÷ %s²" % [v, M(s.a)]
	out.methods = {"rearrange": method(first + [move, "%s = %s" % [solve, M(s.h)], final_step(out.answer)], out.answer.values)}
	return out


# ── Composite solids ─────────────────────────────────────────

## [name, working, value] for each piece of a composite's volume.
static func pieces(s: Dictionary) -> Array:
	var cone := ["Cone", cone_v_text(s) if s.has("h") else "", s.r * s.r * s.get("h", 0.0) / 3.0]
	var dome := ["Hemisphere", "(2/3) × π × %s³" % M(s.r), 2.0 * pow(s.r, 3.0) / 3.0]
	var drum := ["Cylinder", "π × %s² × %s" % [M(s.r), M(s.get("c", 0.0))], s.r * s.r * s.get("c", 0.0)]
	match s.shape:
		"cone-hemisphere":
			return [cone, dome]
		"cone-cylinder":
			return [cone, drum]
		"hemisphere-cylinder":
			return [dome, drum]
	return [["Cylinder", "π × %s² × %s" % [M(s.big), M(s.c)], s.big * s.big * s.c], dome]


static func keys_of(s: Dictionary) -> Array:
	match s.shape:
		"cone-hemisphere":
			return ["r", s.given]
		"cone-cylinder":
			return ["r", s.given, "c"]
		"hemisphere-cylinder":
			return ["r", "c"]
	return ["big", "c", "r"]


func u_composite_volume(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = SolidSituation.vol_k(s)
	var ps := pieces(s)
	var wrongs: Array = []
	if s.shape in ["cone-hemisphere", "cone-cylinder"]:
		wrongs.append([x + 2.0 * ps[0][2], R_THIRD])
		if s.given == "l":
			wrongs.append([x + (s.l - s.h) * s.r * s.r / 3.0, R_SLANT])
	if s.shape in ["cone-hemisphere", "hemisphere-cylinder"]:
		wrongs.append([x + 2.0 * pow(s.r, 3.0) / 3.0, R_THIRD])
	var more: Array = [ps[0][2] + ps[1][2]] if s.shape == "cylinder-minus-hemisphere" else [ps[0][2], ps[1][2]]
	var out := pack(s, "V = ", u3(s), true, x, wrongs, more)
	show(out, s, rep, "%s is %s" % [thing(s, "composite"), PHRASE[s.shape]], keys_of(s))
	out.asked = "Find the volume of the solid."
	var steps: Array = [h_step(s)] if s.has("h") and s.get("given", "") == "l" and s.shape.begins_with("cone") else []
	for p in ps:
		steps.append("%s: %s = %s" % [p[0], p[1], E(s, p[2])])
	var join := "minus" if s.shape == "cylinder-minus-hemisphere" else "plus"
	steps.append("The %s %s the %s gives %s." % [String(ps[0][0]).to_lower(), join, String(ps[1][0]).to_lower(), E(s, x)])
	steps.append(final_step(out.answer))
	out.methods = {"decompose": method(steps, out.answer.values)}
	return out


## [name, working, value] for each outer face of a composite: `open` leaves out the base.
static func faces(s: Dictionary, open: bool) -> Array:
	var out: Array = []
	if s.shape.begins_with("cone"):
		out.append(["Curved cone", "π × %s × %s" % [M(s.r), M(s.l)], s.r * s.l])
	if s.shape in ["cone-hemisphere", "hemisphere-cylinder", "cylinder-minus-hemisphere"]:
		out.append(["Hemisphere", "2 × π × %s²" % M(s.r), 2.0 * s.r * s.r])
	if s.shape in ["cone-cylinder", "hemisphere-cylinder"]:
		out.append(["Cylinder wall", "2 × π × %s × %s" % [M(s.r), M(s.c)], 2.0 * s.r * s.c])
	if s.shape == "cylinder-minus-hemisphere":
		out.append(["Cylinder wall", "2 × π × %s × %s" % [M(s.big), M(s.c)], 2.0 * s.big * s.c])
		out.append(["Ring on top", "π × (%s² − %s²)" % [M(s.big), M(s.r)], s.big * s.big - s.r * s.r])
	if not open and s.shape != "cone-hemisphere":
		var big: float = s.get("big", s.r)
		out.append(["Base", "π × %s²" % M(big), big * big])
	return out


static func face_steps(s: Dictionary, list: Array) -> Array:
	var lead: Array = [l_step(s)] if s.shape.begins_with("cone") and s.given == "h" else []
	var rows: Array = list.map(func(f): return "%s: %s = %s" % [f[0], f[1], E(s, f[2])])
	# Three steps at most, before the sum and the answer: some faces share a line.
	var spare := lead.size() + rows.size() - 3
	if spare > 0:
		rows = ["; ".join(rows.slice(0, spare + 1))] + rows.slice(spare + 1)
	return lead + rows


func u_composite_surface(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = SolidSituation.surf_k(s)
	var wrongs: Array = []
	var join: float = 2.0 * s.r * s.r if s.shape != "cylinder-minus-hemisphere" else s.r * s.r
	wrongs.append([x + join, R_FLAT])
	if s.shape.begins_with("cone") and s.given == "h":
		wrongs.append([x + s.r * (s.h - s.l), R_H_FOR_L])
	if s.shape != "cone-cylinder":
		wrongs.append([x + 2.0 * s.r * s.r, R_FOUR])
	var out := pack(s, "area = ", u2(s), true, x, wrongs, [x - s.r * s.r, SolidSituation.vol_k(s)])
	show(out, s, rep, "%s is %s" % [thing(s, "composite"), PHRASE[s.shape]], keys_of(s))
	out.asked = "Find the total surface area of the solid."
	var steps := face_steps(s, faces(s, false))
	steps.append("Adding only the outer faces gives %s." % E(s, x))
	steps.append(final_step(out.answer))
	out.methods = {"net-face-by-face": method(steps, out.answer.values)}
	return out


func u_paint_cost(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var open: float = SolidSituation.surf_k(s) - SolidSituation.base_k(s)
	var x: float = open * s.price
	var wrongs: Array = [[(open + SolidSituation.base_k(s)) * s.price, R_FLAT]]
	if s.shape == "cone-cylinder" and s.given == "h":
		wrongs.append([x + s.r * (s.h - s.l) * s.price, R_H_FOR_L])
	if s.shape == "hemisphere-cylinder":
		wrongs.append([(open + 2.0 * s.r * s.r) * s.price, R_FOUR])
	var out := pack(s, "cost = $", "", true, x, wrongs, [open])
	show(out, s, rep, "%s is %s, with its base on the ground" % [thing(s, "tank"), PHRASE[s.shape]], keys_of(s),
		["Paint costs $%s per m²." % M(s.price)])
	out.asked = "Find the cost of painting the outside of the tank. The base is not painted."
	var steps := face_steps(s, faces(s, true))
	steps.append("Area to paint: %s m². Cost: %s × %s = %s" % [E(s, open), E(s, open), M(s.price), E(s, x)])
	steps.append(final_step(out.answer))
	out.methods = {"net-face-by-face": method(steps, out.answer.values)}
	return out


func u_composite_volume_solve(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var unit: String = " " + s.unit
	var cone: bool = s.shape == "cone-hemisphere"
	var out := pack(s, "r = ", unit, false, s.r, [], [s.r + 1.0, s.r * 1.3, s.r * 0.8])
	if cone:
		# The cone's third missed: the same equation with h for h/3.
		var slip := SolidSituation.solve_r({"vol": s.vol}, 2.0 / 3.0, s.h)
		out.wrongs.append(wrong(val(s, "r = ", slip, unit, false).values, R_THIRD))
	else:
		var slip := SolidSituation.solve_r({"vol": s.vol}, 4.0 / 3.0, s.c)
		out.wrongs.append(wrong(val(s, "r = ", slip, unit, false).values, R_THIRD))
	show(out, s, rep, "%s is %s" % [thing(s, "composite"), PHRASE[s.shape]], ["h" if cone else "c"], [vol_line(s)])
	if rep == "diagram":
		out.graph.r = "r"
	out.asked = "Find r."
	var eq: String = "(2/3)πr³ + (1/3)πr² × %s = %s" % [M(s.h), M(s.vol)] if cone else "(2/3)πr³ + πr² × %s = %s" % [M(s.c), M(s.vol)]
	out.methods = {"gdc-solver": method(["The volume is the two pieces added: " + eq, "This has r³ and r² together, so graph both sides on the GDC, or use its solver.",
		"The positive solution is r = %s." % w(s.r), final_step(out.answer)], out.answer.values)}
	return out


# ── In terms of a letter ─────────────────────────────────────

## The answer as a sum of terms [coefficient, what follows it]; `minus` joins two with −.
static func expr(head: String, terms: Array, minus: bool = false) -> Dictionary:
	var values := {}
	var parts: Array = [head]
	var text := head
	for i in terms.size():
		var id := "c%d" % i
		var c: Q = Q.of(terms[i][0])
		values[id] = c
		var body: String = terms[i][1]
		parts.append({"slot": id})
		parts.append(body)
		text += Fmt.lead(c) + body
		if i < terms.size() - 1:
			var join := " − " if minus else " + "
			parts[-1] = body + join
			text += join
	return DifferentiationViews.form(text, parts, values)


## A wrong option in the answer's shape.
static func expr_wrong(head: String, terms: Array, ref: String, minus: bool = false) -> Dictionary:
	return wrong(expr(head, terms, minus).values, ref)


## "3x cm", "x cm".
static func in_x(s: Dictionary, m: int) -> String:
	return "%sx %s" % ["" if m == 1 else str(m), s.unit]


func u_volume_in_terms(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rx: int = s.rx
	var head := "V = "
	var out := {"table": null}
	var over := {"r": in_x(s, rx)}
	var cones: bool = s.shape in ["cone", "cone-cylinder"]
	var third: Q = Q.new(rx * rx * s.get("hx", 0), 3)
	var dome: Q = Q.new(2 * rx * rx * rx, 3)
	var terms: Array
	var keys: Array = ["r"]
	match s.shape:
		"cone":
			terms = [[third, "πx³"]]
			keys.append("h")
			over.h = in_x(s, s.hx)
			out.wrongs = [expr_wrong(head, [[third.mul(3), "πx³"]], R_THIRD)]
			out.generic = [expr(head, [[third.mul(2), "πx³"]]).values, expr(head, [[third.add(1), "πx³"]]).values, expr(head, [[third.add(2), "πx³"]]).values]
		"sphere":
			terms = [[dome.mul(2), "πx³"]]
			out.wrongs = []
			out.generic = [expr(head, [[dome, "πx³"]]).values, expr(head, [[dome.mul(3), "πx³"]]).values, expr(head, [[dome.mul(4), "πx³"]]).values]
		"hemisphere":
			terms = [[dome, "πx³"]]
			out.wrongs = [expr_wrong(head, [[dome.mul(2), "πx³"]], R_THIRD)]
			out.generic = [expr(head, [[dome.mul(8), "πx³"]]).values, expr(head, [[dome.mul(3), "πx³"]]).values, expr(head, [[dome.mul(4), "πx³"]]).values]
		"hemisphere-cylinder":
			var drum := Q.new(rx * rx * s.tail)
			terms = [[dome, "πx³"], [drum, "πx²"]]
			keys.append("c")
			over.c = "%d %s" % [s.tail, s.unit]
			out.wrongs = [expr_wrong(head, [[dome.mul(2), "πx³"], [drum, "πx²"]], R_THIRD)]
			out.generic = [expr(head, [[dome, "πx³"], [drum.mul(2), "πx²"]]).values, expr(head, [[dome, "πx²"], [drum, "πx³"]]).values, expr(head, [[dome.mul(3), "πx³"], [drum, "πx²"]]).values]
		"cone-cylinder":
			var drum := Q.new(rx * rx * s.tail)
			terms = [[third, "πx³"], [drum, "πx²"]]
			keys.append("h")
			keys.append("c")
			over.h = in_x(s, s.hx)
			over.c = "%d %s" % [s.tail, s.unit]
			out.wrongs = [expr_wrong(head, [[third.mul(3), "πx³"], [drum, "πx²"]], R_THIRD)]
			out.generic = [expr(head, [[third, "πx³"], [drum.mul(2), "πx²"]]).values, expr(head, [[third, "πx²"], [drum, "πx³"]]).values, expr(head, [[third.mul(2), "πx³"], [drum, "πx²"]]).values]
	out.answer = expr(head, terms)
	show(out, s, rep, "%s is %s" % [thing(s, family(s.shape)), PHRASE[s.shape]], keys, [], over)
	out.asked = "Find an expression for the volume V, in terms of x."
	var steps: Array = []
	var r_t := "(%s)" % in_x(s, rx).trim_suffix(" " + s.unit)
	if cones:
		steps.append("Cone: (1/3)π%s² × %s = %s" % [r_t, "(%s)" % in_x(s, s.hx).trim_suffix(" " + s.unit), Fmt.lead(third) + "πx³"])
	if s.shape in ["sphere"]:
		steps.append("V = (4/3)π%s³" % r_t)
	if s.shape in ["hemisphere", "hemisphere-cylinder"]:
		steps.append("Hemisphere: (2/3)π%s³ = %s" % [r_t, Fmt.lead(dome) + "πx³"])
	if s.shape in ["hemisphere-cylinder", "cone-cylinder"]:
		steps.append("Cylinder: π%s² × %d = %s" % [r_t, s.tail, Fmt.lead(Q.new(rx * rx * s.tail)) + "πx²"])
	steps.append(final_step(out.answer))
	out.methods = {"booklet-formula": method(steps, out.answer.values)}
	return out


func u_surface_in_terms(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var rx: int = s.rx
	var head := "S = "
	var out := {"table": null}
	var over := {"r": in_x(s, rx)}
	var keys: Array = ["r"]
	var r_t := "(%s)" % in_x(s, rx).trim_suffix(" " + s.unit)
	var steps: Array = []
	var terms: Array
	match s.shape:
		"cone":
			var hx: int = s.hx
			var lx: int = s.lx
			var total: bool = s.get("total", false)
			var extra: int = rx * rx if total else 0
			var c := Q.new(rx * lx + extra)
			terms = [[c, "πx²"]]
			keys.append("h")
			over.h = in_x(s, hx)
			steps.append("l = √((%dx)² + (%dx)²) = %dx" % [rx, hx, lx])
			steps.append("Curved surface: π%s(%dx) = %dπx²" % [r_t, lx, rx * lx])
			if total:
				steps.append("Base: π%s² = %dπx²" % [r_t, rx * rx])
			out.wrongs = [expr_wrong(head, [[Q.new(rx * hx + extra), "πx²"]], R_H_FOR_L)]
			out.generic = [expr(head, [[c.add(1), "πx²"]]).values, expr(head, [[c.add(2), "πx²"]]).values, expr(head, [[c.mul(2), "πx²"]]).values]
			if not total:
				out.generic.push_front(expr(head, [[Q.new(rx * lx + rx * rx), "πx²"]]).values)
		"hemisphere":
			var r2 := Q.new(rx * rx)
			terms = [[r2.mul(3), "πx²"]]
			steps.append("Curved part: 2π%s² = %dπx²" % [r_t, 2 * rx * rx])
			steps.append("Flat circle: π%s² = %dπx²" % [r_t, rx * rx])
			out.wrongs = [expr_wrong(head, [[r2.mul(2), "πx²"]], R_FLAT), expr_wrong(head, [[r2.mul(4), "πx²"]], R_FOUR)]
			out.generic = [expr(head, [[r2, "πx²"]]).values, expr(head, [[r2.mul(5), "πx²"]]).values]
		_:
			var r2 := Q.new(rx * rx)
			var wall := Q.new(2 * rx * s.tail)
			terms = [[r2.mul(3), "πx²"], [wall, "πx"]]
			keys.append("c")
			over.c = "%d %s" % [s.tail, s.unit]
			steps.append("Hemisphere and base: 2π%s² + π%s² = %dπx²" % [r_t, r_t, 3 * rx * rx])
			steps.append("Cylinder wall: 2π%s × %d = %dπx" % [r_t, s.tail, 2 * rx * s.tail])
			out.wrongs = [expr_wrong(head, [[r2.mul(2), "πx²"], [wall, "πx"]], R_FLAT), expr_wrong(head, [[r2.mul(5), "πx²"], [wall, "πx"]], R_FOUR)]
			out.generic = [expr(head, [[r2.mul(3), "πx²"], [wall.mul(2), "πx"]]).values, expr(head, [[r2, "πx²"], [wall, "πx"]]).values]
	out.answer = expr(head, terms)
	var opening := "%s is %s" % [thing(s, family(s.shape)), PHRASE[s.shape]]
	if s.shape == "cone" and s.get("total", false):
		opening += ", closed by a flat circular base"
	show(out, s, rep, opening, keys, [], over)
	var what: String = "curved surface area" if s.shape == "cone" and not s.get("total", false) else "total surface area"
	out.asked = "Find an expression for the %s S, in terms of x." % what
	steps.append(final_step(out.answer))
	out.methods = {"booklet-formula": method(steps, out.answer.values)}
	return out


func u_hollow_surface(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var head := "S = "
	var ends := Q.new(2 * (k * k - 1))
	var walls := Q.new(2 * (k + 1))
	var out := {"table": null, "answer": expr(head, [[ends, "πr²"], [walls, "πrh"]])}
	out.wrongs = [expr_wrong(head, [[ends.mul(2), "πr²"], [walls, "πrh"]], R_FLAT)]
	out.generic = [expr(head, [[Q.new(2 * k * k), "πr²"], [walls, "πrh"]]).values, expr(head, [[ends, "πr²"], [Q.new(2 * k), "πrh"]]).values,
		expr(head, [[ends, "πr²"], [Q.new(2 * (k - 1)), "πrh"]]).values, expr(head, [[ends, "πr²"], [walls.mul(2), "πrh"]]).values]
	var labels := {"r": "r", "big": "%dr" % k, "h": "h"}
	var fig := {"kind": "solid", "shape": "hollow", "r": labels.r, "big": labels.big, "h": labels.h}
	var opening := "%s is %s" % [thing(s, "hollow"), PHRASE.hollow]
	if rep == "diagram":
		out.lines = [opening + ", as in the diagram. All lengths are in cm."]
		out.graph = fig
	else:
		out.lines = [opening + ". All lengths are in cm.", "Its outer radius is %dr, the hole's radius is r and its height is h." % k]
	out.asked = "Find an expression for the total surface area S, in terms of r and h."
	out.methods = {"net-face-by-face": method(["Outer wall: 2π(%dr)h = %dπrh, and inner wall: 2πrh" % [k, 2 * k],
		"Top and bottom rings: 2 × π((%dr)² − r²) = %dπr²" % [k, 2 * (k * k - 1)], final_step(out.answer)], out.answer.values)}
	return out


func u_hollow_volume_from_surface(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var head := "V = "
	var m: int = s.m
	var lin := Q.new((k - 1) * m, 2)
	var cub := Q.new((k - 1) * (k * k - 1))
	var out := {"table": null, "answer": expr(head, [[lin, "πr"], [cub, "πr³"]], true)}
	out.wrongs = []
	out.generic = [expr(head, [[lin.mul(2), "πr"], [cub, "πr³"]], true).values, expr(head, [[lin, "πr"], [cub.mul(2), "πr³"]], true).values,
		expr(head, [[lin, "πr²"], [cub, "πr³"]], true).values, expr(head, [[lin.add(1), "πr"], [cub.add(1), "πr³"]], true).values]
	var opening := "%s is %s" % [thing(s, "hollow"), PHRASE.hollow]
	var line2 := "Its total surface area is %dπ cm²." % m
	if rep == "diagram":
		out.lines = [opening + ", as in the diagram. All lengths are in cm.", line2]
		out.graph = {"kind": "solid", "shape": "hollow", "r": "r", "big": "%dr" % k, "h": "h"}
	else:
		out.lines = [opening + ". All lengths are in cm.", "Its outer radius is %dr, the hole's radius is r and its height is h." % k, line2]
	out.asked = "Find an expression for the volume V, in terms of r only."
	var e := 2 * (k * k - 1)
	var f := 2 * (k + 1)
	out.methods = {"rearrange": method(["S = %dπr² + %dπrh = %dπ, so rh = (%d − %dr²) ÷ %d" % [e, f, m, m, e, f],
		"V = π((%dr)² − r²)h = %dπr × rh" % [k, k * k - 1], "V = %dπr(%d − %dr²) ÷ %d" % [k * k - 1, m, e, f], final_step(out.answer)], out.answer.values)}
	return out


func u_surface_from_volume(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ends: int = s.ends
	var head := "S = "
	var two := Q.new(2 * roundi(s.vol))
	var sq := Q.new(4 if ends == 2 else 3)
	var out := {"table": null, "answer": expr(head, [[two, "/x"], [sq, "πx²"]])}
	out.wrongs = [expr_wrong(head, [[two, "/x"], [Q.new(6 if ends == 2 else 2), "πx²"]], R_FLAT)]
	if ends == 1:
		out.wrongs.append(expr_wrong(head, [[two, "/x"], [Q.new(5), "πx²"]], R_FOUR))
	out.generic = [expr(head, [[Q.new(roundi(s.vol)), "/x"], [sq, "πx²"]]).values, expr(head, [[two.mul(2), "/x"], [sq, "πx²"]]).values,
		expr(head, [[two, "/x"], [sq.add(1), "πx²"]]).values, expr(head, [[two.add(1), "/x"], [sq, "πx²"]]).values]
	var opening := "%s is %s" % [thing(s, "composite"), PHRASE[s.shape]]
	var line2 := "The cylinder has radius x cm and height h cm, and its volume is %d cm³." % roundi(s.vol)
	if rep == "diagram":
		out.lines = [opening + ", as in the diagram.", line2]
		out.graph = {"kind": "solid", "shape": s.shape, "r": "x", "c": "h"}
	else:
		out.lines = [opening + ".", line2]
	out.asked = "Find an expression for the total surface area S, in terms of x."
	var dome_step := "Two hemispheres make a sphere: 4πx²" if ends == 2 else "Hemisphere and base: 2πx² + πx² = 3πx²"
	out.methods = {"net-face-by-face": method(["πx²h = %d, so h = %d/(πx²)" % [roundi(s.vol), roundi(s.vol)], "Cylinder wall: 2πxh = 2πx × %d/(πx²) = %d/x" % [roundi(s.vol), 2 * roundi(s.vol)],
		dome_step, final_step(out.answer)], out.answer.values)}
	return out


# ── A cylinder inside a sphere ───────────────────────────────

func u_inscribed_volume(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.big * s.big * s.h
	var out := pack(s, "V = ", u3(s), true, x, [[s.r * s.r * s.h, R_SLANT], [x / 3.0, R_THIRD]], [s.big * s.h, 4.0 * pow(s.r, 3.0) / 3.0 - x])
	show(out, s, rep, "%s is %s" % [thing(s, "composite"), PHRASE.inscribed], ["r", "h"])
	out.asked = "Find the volume of the cylinder."
	out.methods = {"height-by-pythagoras": method(["The cylinder's radius R, half its height and the sphere's radius make a right triangle.",
		"R = √(%s² − %s²) = %s" % [M(s.r), M(s.h / 2.0), M(s.big)], "V = π × %s² × %s = %s" % [M(s.big), M(s.h), E(s, x)], final_step(out.answer)], out.answer.values)}
	return out


func u_inscribed_surface(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = 2.0 * s.big * s.big + 2.0 * s.big * s.h
	var out := pack(s, "area = ", u2(s), true, x, [[2.0 * s.r * s.r + 2.0 * s.r * s.h, R_H_FOR_L], [s.big * s.big + 2.0 * s.big * s.h, R_FLAT]], [2.0 * s.big * s.h])
	show(out, s, rep, "%s is %s" % [thing(s, "composite"), PHRASE.inscribed], ["r", "h"])
	out.asked = "Find the total surface area of the cylinder."
	out.methods = {"net-face-by-face": method(["The cylinder's radius: R = √(%s² − %s²) = %s" % [M(s.r), M(s.h / 2.0), M(s.big)],
		"Two circles: 2 × π × %s² = %s" % [M(s.big), E(s, 2.0 * s.big * s.big)], "The wall: 2 × π × %s × %s = %s" % [M(s.big), M(s.h), E(s, 2.0 * s.big * s.h)],
		final_step(out.answer)], out.answer.values)}
	return out


# ── The sheet that rolls into a cone ─────────────────────────

static func sheet(out: Dictionary, s: Dictionary, rep: String, keys: Array, tail: String) -> void:
	var opening := "%s is cut into a sector" % thing(s, "sector")
	var fig := {"kind": "solid", "shape": "sector"}
	for key in keys:
		fig[key] = measure(s, key)
	if rep == "diagram":
		out.lines = [opening + ", as in the diagram, and " + tail]
		out.graph = fig
	else:
		var names: Array = keys.map(func(k): return {"l": "sector's radius", "theta": "sector's angle"}[k])
		out.lines = [opening + " and " + tail, say(names, keys.map(func(k): return measure(s, k)))]


const ROLL := "its straight edges are joined to make a cone with no base."


func u_sector_cone_radius(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var unit: String = " " + s.unit
	var out := pack(s, "r = ", unit, false, s.r, [], [s.l * s.theta / 180.0, s.l - s.r, s.l * s.theta / 720.0])
	sheet(out, s, rep, ["l", "theta"], ROLL)
	out.asked = "Find the base radius of the cone."
	out.methods = {"unrolled-sector": method(["The arc of the sector becomes the circle at the base: 2πr = (%s/360) × 2π × %s" % [M(s.theta), M(s.l)],
		"r = %s × %s ÷ 360 = %s" % [M(s.theta), M(s.l), M(s.r)], final_step(out.answer)], out.answer.values)}
	return out


func u_sector_angle(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := pack(s, "θ = ", "°", false, s.theta, [], [s.theta / 2.0, 360.0 - s.theta, s.theta * 1.5])
	var opening := "A cone with no base has %s and %s." % [("radius %s" % sized(s, s.r)), ("slant height %s" % sized(s, s.l))]
	out.lines = [opening, "It is cut along a slant edge and opened out into a flat sector."]
	if rep == "diagram":
		out.lines = ["A cone with no base is cut along a slant edge and opened out into the flat sector in the diagram.", "The cone's base radius is %s." % sized(s, s.r)]
		out.graph = {"kind": "solid", "shape": "sector", "l": sized(s, s.l), "theta": "θ"}
	out.asked = "Find the angle θ of the sector."
	out.methods = {"unrolled-sector": method(["The arc of the sector is the base circle: (θ/360) × 2π × %s = 2π × %s" % [M(s.l), M(s.r)],
		"θ = 360 × %s ÷ %s = %s" % [M(s.r), M(s.l), M(s.theta)], final_step(out.answer)], out.answer.values)}
	return out


func u_sector_curved(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.r * s.l
	var out := pack(s, "area = ", u2(s), true, x, [], [s.r * s.r, s.l * s.l, x + s.r * s.r])
	sheet(out, s, rep, ["l", "theta"], ROLL)
	out.asked = "Find the curved surface area of the cone."
	out.methods = {"unrolled-sector": method(["The curved surface is the sector itself, a fraction %s/360 of a circle of radius %s." % [M(s.theta), M(s.l)],
		"Area = (%s/360) × π × %s² = %s" % [M(s.theta), M(s.l), E(s, x)], final_step(out.answer)], out.answer.values)}
	return out


func u_sector_cone_volume(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.r * s.r * s.h / 3.0
	var out := pack(s, "V = ", u3(s), true, x, [[s.r * s.r * s.l / 3.0, R_SLANT], [s.r * s.r * s.h, R_THIRD]], [s.r * s.h, s.r * s.l])
	sheet(out, s, rep, ["l", "theta"], ROLL)
	out.asked = "Find the volume of the cone."
	out.methods = {"height-by-pythagoras": method(["The arc becomes the base circle: r = %s × %s ÷ 360 = %s" % [M(s.theta), M(s.l), M(s.r)], "The sector's radius is the slant height: " + h_step(s),
		"V = (1/3)πr²h = %s = %s" % [cone_v_text(s), E(s, x)], final_step(out.answer)], out.answer.values)}
	return out
