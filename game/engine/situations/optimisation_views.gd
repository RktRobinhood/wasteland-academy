class_name OptimisationViews
extends ExtensionViews
## The views on the `optimisation-model` situation: one builder per unknown of
## t5-optimisation-modelling (FAL-739). The exam walks one shape through stages: a second
## length from the constraint, the function of one variable ("show that"), its derivative,
## the stationary point, why it is a maximum or a minimum, and the value there. Each stage is
## its own unknown. A phone can't read a written proof, so a "show that" follows
## SL5.6's show-form: the target has letters where its numbers go, and the student states them.
##
## Representations: "diagram" (a labelled figure with the question's numbers on it), "words"
## and "equation" (the function is given, and the story is one line). On Paper 1 every value
## is exact, with π left in. On Paper 2 values are to 3 s.f., and the GDC is a method.
## `given` is the situation, for the SymPy checker.

const M := "SL5.8.optimisation-modelling#"
const R_ELIM := M + "0"
const R_DOMAIN := M + "1"
const R_X := M + "2"
const R_ROOT := "SL5.8.find-stationary-points#0"
const R_SIGN_F := "SL5.8.classify-stationary-points#2"
## The type's own slips, by their place in the catalogue's misconceptions.
const TYPE := "t5-optimisation-modelling#"
const R_SWAP := TYPE + "4"
const R_WALL := TYPE + "6"
const R_ONE_X := TYPE + "7"
const R_FLIP := TYPE + "8"
const R_CIRC := TYPE + "9"
const R_FACES := TYPE + "10"
const R_LID := TYPE + "11"
const R_ENDS := TYPE + "12"
const R_SIDE := TYPE + "13"
const R_ONE_CUT := TYPE + "14"
const R_NO_H := TYPE + "15"
const R_HALF := TYPE + "16"
const R_PYTH := TYPE + "17"
const R_RATE := TYPE + "18"
const R_ROAD := TYPE + "19"
const R_NEG_SIGN := TYPE + "20"
const R_NEG_POW := TYPE + "21"
const R_SAME_POW := TYPE + "22"
const R_NO_ROOT := TYPE + "23"
const R_SQRT := TYPE + "24"
const R_FROM_B := TYPE + "25"
const R_DIRECT := TYPE + "26"
const R_ABOVE := TYPE + "27"
const R_CHAIN := TYPE + "28"
const R_FIRST := TYPE + "29"

const FENCED := ["pen", "paddock", "can", "bin"]
const CURVED := ["paddock", "can", "bin", "arch"]
const OPEN := ["paddock", "can", "bin", "box", "arch"]

## The stories, one list per family, CONTEXTS long.
const PEN := [["A salvage crew", "scrap yard", "the old depot wall"], ["A caravan camp", "goat yard", "a concrete flood wall"],
	["A market trader", "stall yard", "the bazaar wall"]]
const PADDOCK := [["A settler", "bean plot", "a dam wall"], ["A water crew", "filter bed", "a bunker wall"],
	["A salt farmer", "drying pan", "the side of a cargo hull"]]
const CAN_SHUT := ["A fuel drum", "A sealed seed can", "A pressure tank"]
const CAN_OPEN := ["A rain barrel", "A smelting pot", "A catch basin"]
const BIN := ["a salt bin", "a tool hopper", "a seed bin"]
const SHEET := ["sheet of roof tin", "panel from a wrecked van", "sign from the old highway"]
const ARCH := [["the mouth of a rail tunnel", "steel shutter"], ["a fallen bridge", "billboard"], ["a bunker entrance", "blast door"]]


func needs() -> Dictionary:
	return {
		"constraint-rearrange": {"fams": FENCED},
		"build-objective": {"fams": ["box", "arch", "route"]},
		"show-objective": {"fams": FENCED},
		"derivative-of-objective": {"fams": ["pen", "paddock", "can", "bin", "box", "arch"]},
		"solve-stationary": {"fams": CURVED},
		"exact-stationary": {"fams": CURVED, "mode": "surd"},
		"justify-second-derivative": {"fams": ["pen", "paddock", "can", "bin", "arch"]},
		"justify-sign-change": {"fams": ["pen", "paddock", "can", "bin", "arch"]},
		"optimum-value": {"fams": OPEN},
		"other-dimension": {"fams": ["paddock", "can", "bin"]},
		"quadratic-optimum": {"fams": ["pen"]},
		"box-best-cut": {"fams": ["box"]},
		"route-best-point": {"fams": ["route"]},
		"route-least-value": {"fams": ["route"]},
		"closest-point": {"fams": ["closest"]},
	}


func need(unknown: String, rep: String) -> Dictionary:
	var n := super.need(unknown, rep)
	# Named, so a clean question and an exact one never share a situation.
	if not n.has("mode"):
		n.mode = "clean"
	# The two-variable form is only written for a constraint a student eliminates.
	if unknown == "derivative-of-objective" and rep == "words":
		n.fams = ["paddock", "can", "bin"]
	return n


func papers(unknown: String, _rep: String, method_id: String) -> Array:
	if not has(unknown):
		return []
	if unknown == "closest-point":
		return [1]
	if unknown.begins_with("route-") or method_id == "gdc-graph-optimum":
		return [2]
	return [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = OptimisationSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.num(v)


## A float to 6 significant figures with no trailing zeros, or an exact value.
static func W(v: Variant) -> String:
	if v is Q:
		return Fmt.num(v)
	var t := Fmt.sf(v, 6)
	if t.contains("."):
		t = t.rstrip("0").rstrip(".")
	return t


## The free length's letter, the second length's and the objective's.
static func vr(s: Dictionary) -> String:
	return "r" if s.fam == "can" else "x"


static func second(s: Dictionary) -> String:
	return "y" if s.fam in ["pen", "paddock", "arch"] else "h"


static func obj(s: Dictionary) -> String:
	match s.fam:
		"pen", "arch":
			return "A"
		"paddock":
			return "L"
		"can":
			return "C" if s.cost else "S"
		"bin", "box":
			return "V"
		"route":
			return "C" if s.cost else "T"
	return "D"


## cm or m.
static func unit(s: Dictionary) -> String:
	if s.fam == "can":
		return "m" if s.cost else "cm"
	return "cm" if s.fam in ["bin", "box"] else ("km" if s.fam == "route" else "m")


## What follows the objective's value.
static func value_tail(s: Dictionary) -> String:
	match s.fam:
		"pen", "arch":
			return " m²"
		"paddock":
			return " m"
		"can":
			return " scrap" if s.cost else " cm²"
		"bin", "box":
			return " cm³"
		"route":
			return " scrap" if s.cost else " hours"
	return ""


static func word(s: Dictionary) -> String:
	return "maximum" if s.big else "minimum"


## What the objective's letter measures, for a question that doesn't give its function.
static func name_line(s: Dictionary) -> String:
	match s.fam:
		"pen":
			return "A m² is the area of the %s." % PEN[s.ctx][1]
		"paddock":
			return "L m is the total length of fence."
		"can":
			return "C scrap is the total cost." if s.cost else "S cm² is the total surface area."
	return "V cm³ is the volume of the bin."


static func body(letter: String, p: int, pi: bool) -> String:
	var b := "π" if pi else ""
	if p > 0:
		return b + letter + (Fmt.sup(p) if p > 1 else "")
	if p < 0:
		return b + "/" + letter + (Fmt.sup(-p) if p < -1 else "")
	return b


## Terms [c, p, π] as the game writes them: "6πr² + 108π/r".
static func show(ts: Array, letter: String) -> String:
	return DifferentiationViews.SUM(ts.map(func(t): return [t[0], body(letter, t[1], t[2])]))


static func f_text(s: Dictionary) -> String:
	return "%s = %s" % [obj(s), show(OptimisationSituation.terms(s), vr(s))]


static func d_name(s: Dictionary) -> String:
	return "d%s/d%s" % [obj(s), vr(s)]


static func dd_name(s: Dictionary) -> String:
	return "d²%s/d%s²" % [obj(s), vr(s)]


static func deriv(s: Dictionary) -> Array:
	return OptimisationSituation.diff(OptimisationSituation.terms(s))


static func deriv2(s: Dictionary) -> Array:
	return OptimisationSituation.diff(deriv(s))


static func d_text(s: Dictionary) -> String:
	return "%s = %s" % [d_name(s), show(deriv(s), vr(s))]


static func dd_text(s: Dictionary) -> String:
	return "%s = %s" % [dd_name(s), show(deriv2(s), vr(s))]


## √v: a whole number where v is a square, in a bracket where v is a fraction.
static func root_text(v: Q) -> String:
	if v.is_int() and OptimisationSituation.is_square(v.n):
		return D(Q.new(roundi(sqrt(float(v.n)))))
	return "√%s" % D(v) if v.is_int() else "√(%s)" % D(v)


## "for r > 0", or the shape's limit.
static func domain(s: Dictionary) -> String:
	match s.fam:
		"pen":
			return "for 0 < x < %s" % D(Q.new(s.F, s.n))
		"bin":
			return "for 0 < x < %s" % root_text(Q.new(s.P))
		"box":
			return "for 0 < x < %s" % D(Q.new(mini(s.w, s.h), 2))
		"arch":
			return "for 0 < x < %s" % root_text(Q.new(s.c, s.a))
	return "for %s > 0" % vr(s)


## A number, with its π where the objective has one: "54π", "(37/8)π", "−(19/2)π".
static func P_(s: Dictionary, v: Variant) -> String:
	if not s.pi:
		return W(v)
	var q: Q = v
	return DifferentiationViews.T(q, "π")


## An answer: exact on Paper 1, 3 s.f. on Paper 2.
static func amount(s: Dictionary, head: String, v: Variant, tail: String = "") -> Dictionary:
	return DefiniteIntegralViews.val(v, v is float, head, tail)


static func like(ans: Dictionary, v: Variant, ref: String = "") -> Dictionary:
	return DefiniteIntegralViews.like(ans, v, ref)


## v × (top/bottom), Q or float as v is.
static func scaled(v: Variant, top: int, bottom: int = 1) -> Variant:
	return v.mul(Q.new(top, bottom)) if v is Q else v * top / bottom


## Plain wrong values: multiples of the answer, in its shape.
static func spread(ans: Dictionary, v: Variant) -> Array:
	return [[2, 1], [3, 2], [1, 2], [2, 3], [3, 1], [1, 3]].map(func(f): return like(ans, scaled(v, f[0], f[1])).values)


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## A wrong option in another shape, for picking only.
static func other(text: String, ref: String = "") -> Dictionary:
	return DifferentiationViews.alt(text, ref)


static func typed(text: String, slots: Dictionary, ref: String = "") -> Dictionary:
	return DifferentiationViews.alt(text, ref, slots)


# ── The stories and the figures ──────────────────────────────

## What the student reads before the question, with the figure in "diagram".
func setup(rep: String, s: Dictionary) -> Dictionary:
	var fig: bool = rep == "diagram"
	var out := {"graph": _figure(s) if fig else null}
	match s.fam:
		"pen":
			var c: Array = PEN[s.ctx]
			var parts := ", split into %d pens" % (s.n - 1) if s.n > 2 else ""
			if fig:
				out.lines = ["%s builds the %s in the diagram against %s, using %d m of fence%s. The wall needs no fence." % [c[0], c[1], c[2], s.F, parts]]
			else:
				out.lines = ["%s builds a rectangular %s against %s%s. The wall needs no fence." % [c[0], c[1], c[2], parts],
					"%d m of fence makes %d straight sections at right angles to the wall, each x m long, and one section parallel to the wall, y m long." % [s.F, s.n]]
		"paddock":
			var c: Array = PADDOCK[s.ctx]
			if fig:
				out.lines = ["%s marks out the rectangular %s in the diagram against %s. Its area is %d m², and the wall needs no fence." % [c[0], c[1], c[2], s.P]]
			else:
				out.lines = ["%s marks out a rectangular %s of area %d m² against %s. The wall needs no fence." % [c[0], c[1], s.P, c[2]],
					"The fence is %d straight sections at right angles to the wall, each x m long, and one section parallel to the wall, y m long." % s.n]
		"can":
			out.lines = _can_lines(s, fig)
		"bin":
			if fig:
				out.lines = ["A tinsmith uses exactly %d cm² of metal sheet to make %s, the open box with a square base in the diagram." % [s.P, BIN[s.ctx]]]
			else:
				out.lines = ["A tinsmith uses exactly %d cm² of metal sheet to make %s: an open box with a square base of side x cm, height h cm and no lid." % [s.P, BIN[s.ctx]]]
		"box":
			if fig:
				out.lines = ["A square of side x cm is cut from each corner of the %s in the diagram. The sides are folded up to make an open tray." % SHEET[s.ctx]]
			else:
				out.lines = ["A %s measures %d cm by %d cm. A square of side x cm is cut from each corner, and the sides are folded up to make an open tray." % [SHEET[s.ctx], s.w, s.h]]
		"arch":
			var c: Array = ARCH[s.ctx]
			out.lines = ["The diagram shows the arch of %s, y = %s, with lengths in metres and the x-axis as the ground." % [c[0], arch_text(s)] if fig
				else "The arch of %s is y = %s, with lengths in metres and the x-axis as the ground." % [c[0], arch_text(s)],
				"A rectangular %s stands on the ground, with its top corners on the arch at (x, y) and (−x, y), where x > 0." % c[1]]
		"route":
			out.lines = _route_lines(s, fig)
	return out


static func arch_text(s: Dictionary) -> String:
	return "%d − %sx²" % [s.c, Fmt.lead(s.a)]


static func _can_lines(s: Dictionary, fig: bool) -> Array:
	var shut: bool = s.ends == 2
	var thing: String = (CAN_SHUT if shut else CAN_OPEN)[s.ctx]
	var what := "closed at both ends" if shut else "with a base and no lid"
	var volume := "%dπ" % s.k if s.paper == 1 else str(s.V)
	var u := unit(s)
	var shape := "is the cylinder in the diagram, %s" % what if fig else "is a cylinder of radius r %s and height h %s, %s" % [u, u, what]
	var lines: Array = ["%s %s. Its volume is %s %s³." % [thing, shape, volume, u]]
	if s.cost:
		var flat := "Each flat end" if shut else "The base"
		lines.append("%s costs %d scrap per m² to make, and the curved side costs %d scrap per m²." % [flat, s.rate_end, s.rate_side])
	return lines


static func _route_lines(s: Dictionary, fig: bool) -> Array:
	var where := "M is %d km from a straight highway, and P is the nearest point of the highway to M. B is on the highway, %d km from P." % [s.a, s.b]
	if s.cost:
		var open_ := "A crew runs a cable from the radio mast M in the diagram to the depot B." if fig else "A crew runs a cable from a radio mast M to a depot B. " + where
		return [open_, "The cable goes straight across the ash flats to a point D on the highway, x km from P, for %d scrap per km, then along the highway to B for %d scrap per km." % [s.front, s.back]]
	var head := "A courier leaves the radio mast M in the diagram for the depot B." if fig else "A courier leaves a radio mast M for a depot B. " + where
	return [head, "She rides straight across the ash flats at %d km/h to a point D on the highway, x km from P, then along the highway to B at %d km/h." % [s.front, s.back]]


## One short line that says what the function is, for "equation".
static func intro(s: Dictionary) -> String:
	match s.fam:
		"pen":
			return "The area, A m², of a yard fenced against a wall is"
		"paddock":
			return "The length, L m, of fence around a plot against a wall is"
		"can":
			return "The cost, C scrap, of a cylinder of radius r m is" if s.cost else "The surface area, S cm², of a cylinder of radius r cm is"
		"bin":
			return "The volume, V cm³, of an open bin with square base of side x cm is"
		"box":
			return "The volume, V cm³, of a tray cut from a sheet, with corners of side x cm, is"
	return "The area, A m², of a rectangle under an arch, of half-width x m, is"


func _equation(s: Dictionary) -> Array:
	return [intro(s), "%s, %s" % [f_text(s), domain(s)]]


## A sketch line.
static func L(a: String, b: String, label: String = "", dash: bool = false) -> Dictionary:
	return {"a": a, "b": b, "label": label, "dash": dash}


static func sketch(pts: Dictionary, lines: Array, right: Array = []) -> Dictionary:
	return {"kind": "sketch", "pts": pts, "lines": lines, "arcs": [], "north": [], "right": right}


func _figure(s: Dictionary) -> Dictionary:
	match s.fam:
		"pen", "paddock":
			return _fence_figure(s)
		"can":
			return {"kind": "solid", "shape": "cylinder" if s.ends == 2 else "open-cylinder", "r": "r", "h": "h"}
		"bin":
			return {"kind": "solid", "shape": "open-bin", "a": "x", "a2": "x", "h": "h"}
		"box":
			return _sheet_figure(s)
		"arch":
			return _arch_figure(s)
		"route":
			return _route_figure(s)
	return {}


## The yard seen from above, drawn for x a quarter past its best: wide enough to label.
func _fence_figure(s: Dictionary) -> Dictionary:
	var n: int = s.n
	var deep := 4.0
	var wide := 6.0 + 1.5 * n
	var pts := {"_w0": [-1.2, deep], "_w1": [wide + 1.2, deep]}
	var lines: Array = [L("_w0", "_w1", "wall", true)]
	for i in n:
		var at := wide * i / (n - 1)
		pts["_t%d" % i] = [at, deep]
		pts["_b%d" % i] = [at, 0.0]
		lines.append(L("_t%d" % i, "_b%d" % i, "x m" if i == 0 else ""))
	lines.append(L("_b0", "_b%d" % (n - 1), "y m"))
	return sketch(pts, lines)


## The sheet from above, with its four corners marked out.
func _sheet_figure(s: Dictionary) -> Dictionary:
	var w: float = s.h
	var h: float = s.w
	var c := minf(w, h) / 5.0
	var pts := {"_a": [0.0, 0.0], "_b": [w, 0.0], "_c": [w, h], "_d": [0.0, h],
		"_a1": [c, 0.0], "_a2": [c, c], "_a3": [0.0, c], "_b1": [w - c, 0.0], "_b2": [w - c, c], "_b3": [w, c],
		"_c1": [w - c, h], "_c2": [w - c, h - c], "_c3": [w, h - c], "_d1": [c, h], "_d2": [c, h - c], "_d3": [0.0, h - c],
		"_m0": [0.0, -c], "_m1": [w, -c], "_n0": [w + c, 0.0], "_n1": [w + c, h]}
	var lines: Array = [L("_m0", "_m1", "%d cm" % s.h, true), L("_n0", "_n1", "%d cm" % s.w, true),
		L("_a1", "_a2", "x"), L("_a2", "_a3", "x"), L("_b1", "_b2"), L("_b2", "_b3"), L("_c1", "_c2"), L("_c2", "_c3"), L("_d1", "_d2"), L("_d2", "_d3"),
		L("_a1", "_b1"), L("_b3", "_c3"), L("_c1", "_d1"), L("_d3", "_a3"), L("_a2", "_b2", "", true), L("_b2", "_c2", "", true), L("_c2", "_d2", "", true), L("_d2", "_a2", "", true)]
	return sketch(pts, lines)


## The arch and a rectangle under it, shaded.
func _arch_figure(s: Dictionary) -> Dictionary:
	var root := sqrt(float(s.c) / s.a)
	var f := func(x: float) -> float: return s.c - s.a * x * x
	var r := ceili(root) + 1
	var top := int(s.c) + maxi(1, int(s.c) / 8)
	var xc := root * 0.6
	var yc: float = f.call(xc)
	var g := Plot.spec([Plot.sample(f, -root, root)], [[xc, yc, "(x, y)"], [-xc, yc, "(−x, y)"]], -r, r, -maxi(1, int(s.c) / 8), top)
	g.shade = [[[-xc, 0.0, yc], [xc, 0.0, yc]]]
	return g


## The mast, the highway and the depot.
func _route_figure(s: Dictionary) -> Dictionary:
	var a: float = s.a
	var b: float = s.b
	var pts := {"M": [0.0, a], "P": [0.0, 0.0], "D": [0.45 * b, 0.0], "B": [b, 0.0], "_m0": [0.0, -0.3 * a], "_m1": [b, -0.3 * a]}
	var lines: Array = [L("M", "P", "%d km" % s.a, true), L("M", "D"), L("P", "D", "x km"), L("D", "B"), L("_m0", "_m1", "%d km" % s.b, true)]
	return sketch(pts, lines, ["P"])


func _closest_figure(s: Dictionary) -> Dictionary:
	if s.kind == "root":
		var k := float(s.k)
		var f := func(x: float) -> float: return sqrt(k * x)
		var x1 := int(s.px) + 3
		var xq: float = s.x.to_float() * 0.5 + 0.4
		var g := Plot.spec([Plot.sample(f, 0.0, x1), [[xq, f.call(xq)], [float(s.px), 0.0]]], [[s.px, 0, "P"], [xq, f.call(xq), "Q"]], -1, x1, -1, ceili(f.call(x1)) + 1)
		return g
	var k := float(s.k)
	var c := float(s.c)
	var end := exp(c / k)
	var h := func(x: float) -> float: return sqrt(maxf(0.0, c - k * log(x)))
	var x1 := mini(ceili(end) + 1, 12)
	var xq: float = s.x.to_float()
	return Plot.spec([Plot.sample(h, 0.08, minf(end, x1)), [[0.0, 0.0], [xq, h.call(xq)]]], [[0, 0, "O"], [xq, h.call(xq), "Q"]], -1, x1, -1, ceili(h.call(0.08)) + 1)


# ── A second length from the constraint ──────────────────────

## The second length as the student writes it, on Paper 1 or 2.
func u_constraint_rearrange(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := setup(rep, s)
	var ans: Dictionary
	var ws: Array = []
	var gen: Array = []
	var steps: Array = []
	match s.fam:
		"pen":
			var mk := func(a: int, b: int) -> Dictionary:
				return typed("y = %d − %sx" % [a, Fmt.lead(b)], {"a": Q.new(a), "b": Q.new(b)})
			var r: Dictionary = mk.call(s.F, s.n)
			ans = DifferentiationViews.form(r.values.text, ["y = ", {"slot": "a"}, " − ", {"slot": "b"}, "x"], {"a": Q.new(s.F), "b": Q.new(s.n)})
			var slip: Dictionary = mk.call(s.F, 1)
			slip.ref = R_ONE_X
			ws = [other("y = (%d − %sx)/2" % [s.F, Fmt.lead(s.n)], R_WALL), slip]
			gen = [mk.call(s.F, 2 * s.n).values, mk.call(s.F, s.n + 1).values, mk.call(2 * s.F, s.n).values, other("y = %s − %d" % [Fmt.lead(s.n) + "x", s.F]).values]
			steps = ["The fence is %d lengths of x and one of y: %dx + y = %d." % [s.n, s.n, s.F], "Take %dx from both sides." % s.n]
		"paddock":
			ans = DifferentiationViews.form("y = %d/x" % s.P, ["y = ", {"slot": "a"}, "/x"], {"a": Q.new(s.P)})
			ws = [other("y = x/%d" % s.P, R_FLIP)]
			gen = [typed("y = %d/x" % (2 * s.P), {"a": Q.new(2 * s.P)}).values, other("y = %d − %sx" % [s.P, Fmt.lead(s.n)]).values, other("y = %d/(%dx)" % [s.P, s.n]).values, typed("y = %d/x" % (s.P + s.n), {"a": Q.new(s.P + s.n)}).values]
			steps = ["The plot is a rectangle x by y, so xy = %d." % s.P, "Divide both sides by x."]
		"can":
			var pi1: bool = s.paper == 1
			var m: int = s.k if pi1 else s.V
			var below := "/r²" if pi1 else "/(πr²)"
			ans = DifferentiationViews.form("h = %d%s" % [m, below], ["h = ", {"slot": "a"}, below], {"a": Q.new(m)})
			ws = [other(("h = %d/(2r)" % m) if pi1 else ("h = %d/(2πr)" % m), R_CIRC)]
			gen = [typed("h = %d%s" % [2 * m, below], {"a": Q.new(2 * m)}).values, other(("h = %d/r" % m) if pi1 else ("h = %d/(πr)" % m)).values,
				other(("h = %d/(2r²)" % m) if pi1 else ("h = %d/(2πr²)" % m)).values, typed("h = %d%s" % [m + 1, below], {"a": Q.new(m + 1)}).values]
			steps = ["The volume of a cylinder is πr²h, so πr²h = %s." % ("%dπ" % m if pi1 else str(m)), "Divide both sides by πr²."]
		"bin":
			var mk := func(a: int, b: int) -> Dictionary:
				return typed("h = (%d − x²)/(%sx)" % [a, Fmt.lead(b)], {"a": Q.new(a), "b": Q.new(b)})
			var r: Dictionary = mk.call(s.P, 4)
			ans = DifferentiationViews.form(r.values.text, ["h = (", {"slot": "a"}, " − x²)/(", {"slot": "b"}, "x)"], {"a": Q.new(s.P), "b": Q.new(4)})
			var slip: Dictionary = mk.call(s.P, 2)
			slip.ref = R_FACES
			ws = [slip, other("h = (%d − 2x²)/(4x)" % s.P, R_LID)]
			gen = [mk.call(s.P, 8).values, mk.call(2 * s.P, 4).values, mk.call(s.P, 3).values, mk.call(s.P + 4, 4).values]
			steps = ["The base has area x², and each of the 4 sides has area xh: x² + 4xh = %d." % s.P, "Take x² from both sides, then divide by 4x."]
	out.answer = ans
	out.asked = "Find an expression for %s in terms of %s." % [second(s), vr(s)]
	out.wrongs = ws
	out.generic = gen
	out.methods = {"constraint-substitution": method(steps + [say(ans)], ans.values)}
	return out


# ── Reading the function off the figure ──────────────────────

func u_build_objective(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := setup(rep, s)
	var ws: Array = []
	var gen: Array = []
	var steps: Array = []
	var ans: Dictionary
	match s.fam:
		"box":
			var w: int = s.w
			var h: int = s.h
			var text := func(a: int, b: int, c: int, d: int) -> String:
				return "V = x(%d − %sx)(%d − %sx)" % [a, Fmt.lead(b), c, Fmt.lead(d)]
			ans = DifferentiationViews.form(text.call(w, 2, h, 2), ["V = x(", {"slot": "a"}, " − ", {"slot": "b"}, "x)(", {"slot": "c"}, " − ", {"slot": "d"}, "x)"],
				{"a": Q.new(w), "b": Q.new(2), "c": Q.new(h), "d": Q.new(2)})
			ans.pairs = [["a", "b"], ["c", "d"]]
			var sl := func(a: int, b: int, c: int, d: int) -> Dictionary:
				return typed(text.call(a, b, c, d), {"a": Q.new(a), "b": Q.new(b), "c": Q.new(c), "d": Q.new(d)})
			var one: Dictionary = sl.call(w, 1, h, 1)
			one.ref = R_ONE_CUT
			ws = [one, other("V = (%d − 2x)(%d − 2x)" % [w, h], R_NO_H)]
			gen = [sl.call(w, 2, h, 1).values, sl.call(w, 4, h, 4).values, other("V = x²(%d − 2x)(%d − 2x)" % [w, h]).values, sl.call(w, 3, h, 3).values]
			steps = ["A corner comes off each end of every edge, so the base is %d − 2x by %d − 2x." % [w, h], "The folded sides have height x, and volume is base × height."]
			out.asked = "Find an expression for V, the volume of the tray in cm³, in terms of x."
		"arch":
			var c: int = s.c
			var a: int = s.a
			var mk := func(p: int, q: int) -> Dictionary:
				return typed("A = %dx − %sx³" % [p, Fmt.lead(q)], {"a": Q.new(p), "b": Q.new(q)})
			ans = DifferentiationViews.form(mk.call(2 * c, 2 * a).values.text, ["A = ", {"slot": "a"}, "x − ", {"slot": "b"}, "x³"], {"a": Q.new(2 * c), "b": Q.new(2 * a)})
			var half: Dictionary = mk.call(c, a)
			half.ref = R_HALF
			ws = [half]
			gen = [mk.call(2 * c, a).values, mk.call(c, 2 * a).values, mk.call(4 * c, 4 * a).values, mk.call(2 * c, 2 * a + 1).values, mk.call(2 * c + 1, 2 * a).values]
			steps = ["The corners are at x and −x, so the width is 2x, and the height is y = %s." % arch_text(s), "A = 2x(%s). Expand the bracket." % arch_text(s)]
			out.asked = "Find an expression for A, the area of the %s in m², in terms of x." % ARCH[s.ctx][1]
		"route":
			var a2: int = s.a * s.a
			var f: int = s.front
			var v: int = s.back
			var b: int = s.b
			if s.cost:
				var mk := func(p: int, q: int) -> String:
					return "C = %d√(%d + x²) + %d(%d − x)" % [p, q, v, b]
				ans = DifferentiationViews.form(mk.call(f, a2), ["C = ", {"slot": "f"}, "√(", {"slot": "a"}, " + x²) + ", {"slot": "v"}, "(", {"slot": "b"}, " − x)"],
					{"f": Q.new(f), "a": Q.new(a2), "v": Q.new(v), "b": Q.new(b)})
				ws = [other("C = %d(%d + x) + %d(%d − x)" % [f, s.a, v, b], R_PYTH), other("C = %d√(%d + x²) + %dx" % [f, a2, v], R_ROAD)]
				gen = [other("C = %d√(%d + x²) + %d(%d − x)" % [v, a2, f, b]).values, other("C = %d√(%d + x) + %d(%d − x)" % [f, s.a, v, b]).values,
					other("C = %d√(%d + x²) + %d(%d + x)" % [f, a2, v, b]).values, other("C = %d√(%d − x²) + %d(%d − x)" % [f, a2, v, b]).values]
				out.asked = "Find an expression for C, the total cost in scrap, in terms of x."
				steps = ["M, P and D make a right triangle, so MD = √(%d² + x²) = √(%d + x²) km." % [s.a, a2], "D is x km from P, so DB = %d − x km." % b, "Multiply each length by its cost per km, and add."]
			else:
				var mk := func(q: int) -> String:
					return "T = √(%d + x²)/%d + (%d − x)/%d" % [q, f, b, v]
				ans = DifferentiationViews.form(mk.call(a2), ["T = √(", {"slot": "a"}, " + x²)/", {"slot": "f"}, " + (", {"slot": "b"}, " − x)/", {"slot": "v"}],
					{"f": Q.new(f), "a": Q.new(a2), "v": Q.new(v), "b": Q.new(b)})
				ws = [other("T = (%d + x)/%d + (%d − x)/%d" % [s.a, f, b, v], R_PYTH), other("T = %d√(%d + x²) + %d(%d − x)" % [f, a2, v, b], R_RATE),
					other("T = √(%d + x²)/%d + x/%d" % [a2, f, v], R_ROAD)]
				gen = [other("T = √(%d + x²)/%d + (%d − x)/%d" % [a2, v, b, f]).values, other("T = √(%d + x)/%d + (%d − x)/%d" % [s.a, f, b, v]).values,
					other("T = √(%d − x²)/%d + (%d − x)/%d" % [a2, f, b, v]).values, other("T = √(%d + x²)/%d + (%d + x)/%d" % [a2, f, b, v]).values]
				out.asked = "Find an expression for T, the total time in hours, in terms of x."
				steps = ["M, P and D make a right triangle, so MD = √(%d² + x²) = √(%d + x²) km." % [s.a, a2], "D is x km from P, so DB = %d − x km." % b, "Time = distance ÷ speed for each stretch, and the two times add."]
	out.answer = ans
	out.wrongs = ws
	out.generic = gen
	if rep == "words":
		out.titles = {"model-from-figure": "Write each length in terms of x"}
	out.methods = {"model-from-figure": method(steps + [say(ans)], ans.values)}
	return out


# ── "Show that" ──────────────────────────────────────────────

func u_show_objective(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := setup(rep, s)
	var target := ""
	var p: Variant
	var q: Variant
	var ws: Array = []
	var gen: Array = []
	var steps: Array = []
	var pair := func(a: Variant, b: Variant, ref: String = "") -> Dictionary:
		return wrong({"v0": Q.of(a), "v1": Q.of(b)}, ref)
	match s.fam:
		"pen":
			target = "A = px − qx²"
			p = s.F
			q = s.n
			ws = [pair.call(Q.new(s.F, 2), Q.new(s.n, 2), R_WALL)]
			gen = [{"v0": Q.new(s.n), "v1": Q.new(s.F)}, {"v0": Q.new(s.F), "v1": Q.new(2 * s.n)}, {"v0": Q.new(2 * s.F), "v1": Q.new(s.n)}, {"v0": Q.new(s.F), "v1": Q.new(s.n + 1)}]
			steps = ["Area is xy, and the fence gives %dx + y = %d, so y = %d − %sx." % [s.n, s.F, s.F, Fmt.lead(s.n)],
				"Substitute: A = x(%d − %sx) = %dx − %sx²." % [s.F, Fmt.lead(s.n), s.F, Fmt.lead(s.n)]]
		"paddock":
			target = "L = px + q/x"
			p = s.n
			q = s.P
			ws = [pair.call(s.n, 2 * s.P, R_WALL)]
			gen = [{"v0": Q.new(s.P), "v1": Q.new(s.n)}, {"v0": Q.new(2 * s.n), "v1": Q.new(s.P)}, {"v0": Q.new(s.n + 1), "v1": Q.new(s.P)}, {"v0": Q.new(s.n), "v1": Q.new(s.P + s.n)}]
			steps = ["The fence is L = %sx + y, and the area gives xy = %d, so y = %d/x." % [Fmt.lead(s.n), s.P, s.P],
				"Substitute: L = %sx + %d/x." % [Fmt.lead(s.n), s.P]]
		"can":
			var pi1: bool = s.paper == 1
			var m: int = s.k if pi1 else s.V
			var side: int = 2 * s.rate_side * m
			target = "%s = pπr² + qπ/r" % obj(s) if pi1 else "%s = pπr² + q/r" % obj(s)
			p = s.e
			q = side
			var other_ends: int = s.rate_end * (3 - s.ends)
			ws = [pair.call(other_ends, side, R_ENDS), pair.call(s.e, side / 2, R_SIDE)]
			gen = [{"v0": Q.new(side), "v1": Q.new(s.e)}, {"v0": Q.new(s.e), "v1": Q.new(2 * side)}, {"v0": Q.new(s.e + 1), "v1": Q.new(side)}, {"v0": Q.new(s.e), "v1": Q.new(side + 2)}]
			var below := "%d/r²" % m if pi1 else "%d/(πr²)" % m
			var flat := "%sπr²" % Fmt.lead(s.e)
			var round_ := "2πrh" if s.rate_side == 1 else "%dπrh" % (2 * s.rate_side)
			steps = ["πr²h = %s, so h = %s." % ["%dπ" % m if pi1 else str(m), below],
				"%s = %s + %s. The ends give the first term and the curved side the second." % [obj(s), flat, round_],
				"Substitute for h: 2πr × %s = %s." % [below, "%dπ/r" % (2 * m) if pi1 else "%d/r" % (2 * m)]]
		"bin":
			target = "V = (px − x³)/q"
			p = s.P
			q = 4
			ws = [pair.call(s.P, 2, R_FACES)]
			gen = [{"v0": Q.new(4), "v1": Q.new(s.P)}, {"v0": Q.new(s.P), "v1": Q.new(8)}, {"v0": Q.new(2 * s.P), "v1": Q.new(4)}, {"v0": Q.new(s.P), "v1": Q.new(3)}]
			steps = ["The base has area x², and each of the 4 sides has area xh: x² + 4xh = %d, so h = (%d − x²)/(4x)." % [s.P, s.P], "V = x²h = x² × (%d − x²)/(4x)." % s.P, "Cancel an x: V = x(%d − x²)/4 = (%dx − x³)/4." % [s.P, s.P]]
	var ans := Answer.make("named", {"v0": Q.of(p), "v1": Q.of(q)}, {"names": ["p", "q"]})
	ans.exact = true
	out.lines = out.lines + [name_line(s), "Show that %s, where p and q are whole numbers." % target]
	out.asked = "State the values of p and q."
	out.answer = ans
	out.wrongs = ws
	out.generic = gen
	out.methods = {"constraint-substitution": method(steps + ["So " + Answer.text(ans) + "."], ans.values)}
	return out


# ── The derivative ───────────────────────────────────────────

## dO/dx, typed term by term, and terms made by a slip.
func _deriv_answer(s: Dictionary) -> Dictionary:
	var ds := deriv(s)
	var letter := vr(s)
	var parts: Array = [d_name(s) + " = "]
	var slots := {}
	for i in ds.size():
		if i > 0:
			parts.append(" + ")
		var id := "c%d" % i
		parts.append({"slot": id})
		parts.append(body(letter, ds[i][1], ds[i][2]))
		slots[id] = ds[i][0]
	return DifferentiationViews.form(d_text(s), parts, slots)


## A wrong derivative in the answer's shape, each term's coefficient changed by `fix`.
func _slip(s: Dictionary, ts: Array, ref: String = "") -> Dictionary:
	var text := "%s = %s" % [d_name(s), show(ts, vr(s))]
	var same := ts.size() == deriv(s).size()
	for i in ts.size():
		same = same and ts[i][1] == deriv(s)[i][1] and ts[i][2] == deriv(s)[i][2]
	if not same:
		return other(text, ref)
	var slots := {}
	for i in ts.size():
		slots["c%d" % i] = ts[i][0]
	return typed(text, slots, ref)


func u_derivative_of_objective(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := {"graph": null}
	var o := obj(s)
	var v := vr(s)
	var ts := OptimisationSituation.terms(s)
	var ws: Array = []
	var ans := _deriv_answer(s)
	var steps: Array = []
	if rep == "words":
		var slip := ""
		var line := ""
		match s.fam:
			"paddock":
				line = "L = %sx + y, where xy = %d" % [Fmt.lead(s.n), s.P]
				slip = "dL/dx = %d" % s.n
				steps = ["Eliminate y first: y = %d/x, so %s." % [s.P, f_text(s)]]
			"can":
				var pi1: bool = s.paper == 1
				var m: int = s.k if pi1 else s.V
				var side: int = 2 * s.rate_side
				line = "%s = %sπr² + %dπrh, where πr²h = %s" % [o, Fmt.lead(s.e), side, "%dπ" % m if pi1 else str(m)]
				slip = "d%s/dr = %dπr + %dπh" % [o, 2 * s.e, side]
				steps = ["Eliminate h first: h = %s, so %s." % ["%d/r²" % m if pi1 else "%d/(πr²)" % m, f_text(s)]]
			"bin":
				line = "V = x²h, where x² + 4xh = %d" % s.P
				slip = "dV/dx = 2xh"
				steps = ["Eliminate h first: h = (%d − x²)/(4x), so %s." % [s.P, f_text(s)]]
		out.lines = [intro(s), line]
		out.asked = "Write %s in terms of %s only, then find %s." % [o, v, d_name(s)]
		ws.append(other(slip, R_ELIM))
		out.titles = {"differentiate-and-test": "Eliminate, then differentiate"}
	else:
		out.lines = _equation(s)
		out.asked = "Find %s." % d_name(s)
		out.titles = {"differentiate-and-test": "Differentiate term by term"}
	# The slips: each works on the whole function, so a tagged option differs in that term.
	var ds := deriv(s)
	var neg := -1
	for i in ts.size():
		if ts[i][1] < 0:
			neg = i
	if neg >= 0:
		var flipped: Array = ds.map(func(t): return [t[0], t[1], t[2]])
		flipped[neg][0] = ds[neg][0].neg()
		ws.append(_slip(s, flipped, R_NEG_SIGN))
		var up: Array = ds.map(func(t): return [t[0], t[1], t[2]])
		up[neg][1] = ts[neg][1] + 1
		ws.append(_slip(s, up, R_NEG_POW))
	var kept: Array = []
	for i in ts.size():
		if ts[i][1] != 0:
			kept.append([ds[i][0], ts[i][1], ts[i][2]])
	ws.append(_slip(s, kept, R_SAME_POW))
	var gen: Array = []
	for f in [2, 3]:
		var bigger: Array = ds.map(func(t): return [t[0], t[1], t[2]])
		bigger[0][0] = ds[0][0].mul(f)
		gen.append(_slip(s, bigger).values)
	var low: Array = ds.map(func(t): return [t[0], t[1], t[2]])
	low[ds.size() - 1][0] = ds[ds.size() - 1][0].mul(2)
	gen.append(_slip(s, low).values)
	gen.append(_slip(s, ds.map(func(t): return [t[0].mul(Q.new(1, 2)), t[1], t[2]])).values)
	steps.append("Write each term as a power of %s and use the power rule: multiply by the power, then lower it by 1." % v)
	if neg >= 0:
		steps.append("%s is %s, which gives %s." % [show([ts[neg]], v), _power_form(ts[neg], v), show([ds[neg]], v)])
	else:
		steps.append("Term by term, %s becomes %s." % [show(ts, v), show(ds, v)])
	steps.append("So %s." % Answer.text(ans))
	out.answer = ans
	out.wrongs = ws
	out.generic = gen
	out.methods = {"differentiate-and-test": method(steps, ans.values)}
	return out


static func _power_form(t: Array, v: String) -> String:
	return DifferentiationViews.T(t[0], ("π" if t[2] else "") + v + "⁻" + Fmt.sup(-t[1]) if t[1] < -1 else ("π" if t[2] else "") + v + "⁻¹")


# ── Solving dO/dx = 0 ────────────────────────────────────────

## The lines from dO/dx = 0 to the stationary point, ending at x = value. A tray given as a
## bare function has its domain to go on, and no sheet.
static func solve_lines(s: Dictionary, rep: String = "") -> Array:
	var name := "%s = 0" % d_name(s)
	var x_ := W(s.x)
	match s.fam:
		"pen":
			return ["%s: %d − %dx = 0, so x = %s." % [name, s.F, 2 * s.n, x_]]
		"paddock":
			return ["%s: %d − %d/x² = 0, so x² = %s." % [name, s.n, s.P, D(Q.new(s.P, s.n))], "x is a length, so take the positive root: x = %s." % x_]
		"can":
			var e2: int = 2 * s.e
			if s.paper == 1:
				return ["%s: %dπr − %dπ/r² = 0, so r³ = %s." % [name, e2, 2 * s.k * s.rate_side, D(Q.new(s.k, s.e))], "Take the cube root: r = %s." % x_]
			return ["%s: %dπr − %d/r² = 0, so r³ = %d/(%dπ)." % [name, e2, 2 * s.V, 2 * s.V, e2], "Take the cube root: r = %s." % x_]
		"bin":
			return ["%s: %s = 0, so x² = %s." % [name, show(deriv(s), "x"), D(Q.new(s.P, 3))], "x is a length, so take the positive root: x = %s." % x_]
		"arch":
			return ["%s: %s = 0, so x² = %s." % [name, show(deriv(s), "x"), D(Q.new(s.c, 3 * s.a))], "x > 0, so x = %s." % x_]
		"box":
			var sum: int = 2 * (s.w + s.h)
			var limit := D(Q.new(mini(s.w, s.h), 2))
			var pick := "The domain is %s, so x = %s." % [domain(s).trim_prefix("for "), x_] if rep == "equation" else "The sheet's shorter side is %d cm, so x < %s and x = %s." % [mini(s.w, s.h), limit, x_]
			return ["%s: 12x² − %dx + %d = 0." % [name, 2 * sum, s.w * s.h],
				"The roots are x = %s and x = %s." % [x_, W(s.other)], pick]
	return []


## Why it is a maximum or a minimum, from the second derivative.
static func test_line(s: Dictionary) -> String:
	var sign_ := "negative" if s.big else "positive"
	return "%s. At %s = %s it is %s, which is %s, so this is a %s." % [dd_text(s), vr(s), W(s.x), P_(s, s.d2), sign_, word(s)]


## The same, for an exact optimum: the sign holds for every positive length.
static func sign_line(s: Dictionary) -> String:
	return "%s, which is %s for %s > 0, so this is a %s." % [dd_text(s), "negative" if s.big else "positive", vr(s), word(s)]


func _gdc_steps(s: Dictionary, value: bool) -> Array:
	var graph := "Graph %s on the GDC, %s." % [f_text(s), domain(s)]
	var read := "The %s tool gives %s = %s, %s = %s." % [word(s), vr(s), W(s.x), obj(s), W(s.best)] if value else "The %s tool gives %s = %s." % [word(s), vr(s), W(s.x)]
	return [graph, read]


func u_solve_stationary(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := setup(rep, s) if rep != "equation" else {"graph": null, "lines": _equation(s)}
	if rep != "equation":
		out.lines = out.lines + ["%s, %s." % [f_text(s), domain(s)]]
	var v := vr(s)
	out.asked = "Find the value of %s for which %s is a %s." % [v, obj(s), word(s)]
	var ans := amount(s, v + " = ", s.x, " " + unit(s))
	out.answer = ans
	var ws: Array = []
	match s.fam:
		"paddock":
			ws.append(like(ans, _no_root(s), R_NO_ROOT))
		"bin":
			ws.append(like(ans, _no_root(s), R_NO_ROOT))
			ws.append(_zero_root(s, ans))
		"arch":
			ws.append(like(ans, _no_root(s), R_NO_ROOT))
			ws.append(_zero_root(s, ans))
		"can":
			ws.append(like(ans, _no_root(s), R_NO_ROOT))
	out.wrongs = ws
	out.generic = spread(ans, s.x)
	var steps: Array = ["%s." % d_text(s)]
	steps += solve_lines(s)
	steps.append(test_line(s))
	steps.append(say(ans))
	out.methods = {"differentiate-and-test": method(steps, ans.values)}
	if s.paper == 2:
		out.methods["gdc-graph-optimum"] = method(_gdc_steps(s, false) + [say(ans)], ans.values)
	return out


## x² or r³ where the student stopped.
static func _no_root(s: Dictionary) -> Variant:
	var x: Variant = s.x
	var v: Variant = x.mul(x) if x is Q else x * x
	if s.fam == "can":
		v = v.mul(x) if x is Q else v * x
	return v


## Where the function is 0, for a function with a root: a wrong answer as a surd.
static func _zero_root(s: Dictionary, ans: Dictionary) -> Dictionary:
	var inside: Q = Q.new(s.P) if s.fam == "bin" else Q.new(s.c, s.a)
	var root := sqrt(inside.to_float())
	var head: String = ans.template[0]
	if ans.exact:
		return other(head + root_text(inside) + " " + unit(s), R_ROOT)
	return like(ans, root, R_ROOT)


# ── An exact optimum that isn't tidy ─────────────────────────

func u_exact_stationary(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := {"graph": null, "lines": _equation(s)}
	var v := vr(s)
	out.asked = "Find the exact value of %s for which %s is a %s." % [v, obj(s), word(s)]
	var ans: Dictionary
	var ws: Array = []
	var gen: Array = []
	var tail := " " + unit(s)
	var steps: Array = ["%s." % d_text(s)]
	if s.fam == "can":
		var g := Q.gcd(s.V, s.e)
		var top: int = s.V / g
		var low: int = s.e / g
		var text := func(a: int, b: int) -> String:
			return "∛(%d/π)" % a if b == 1 else "∛(%d/(%dπ))" % [a, b]
		var parts: Array = ["r = ∛(", {"slot": "a"}, "/π)" + tail] if low == 1 else ["r = ∛(", {"slot": "a"}, "/(", {"slot": "b"}, "π))" + tail]
		var slots := {"a": Q.new(top)}
		if low != 1:
			slots.b = Q.new(low)
		ans = DifferentiationViews.form("r = " + text.call(top, low) + tail, parts, slots)
		var inside := "%d/π" % top if low == 1 else "%d/(%dπ)" % [top, low]
		ws = [other("r = √(%s)%s" % [inside, tail], R_SQRT), other("r = %s%s" % [inside, tail], R_NO_ROOT)]
		var mk := func(a: int, b: int) -> Dictionary:
			var sl := {"a": Q.new(a)}
			if low != 1:
				sl.b = Q.new(b)
			return typed("r = " + text.call(a, b if low != 1 else 1) + tail, sl)
		gen = [mk.call(2 * top, low).values, mk.call(top + 1, low).values, mk.call(3 * top, low).values]
		if low != 1:
			gen.append(mk.call(top, 2 * low).values)
		steps.append("%s = 0: %dπr − %d/r² = 0, so r³ = %d/(%dπ) = %s." % [d_name(s), 2 * s.e, 2 * s.V, 2 * s.V, 2 * s.e, inside])
		steps.append("Take the cube root.")
	else:
		var m: int = s.m
		var t: int = s.t
		var mk := func(a: int, b: int) -> Dictionary:
			return typed("x = %d√%d%s" % [a, b, tail], {"a": Q.new(a), "b": Q.new(b)})
		ans = DifferentiationViews.form("x = %d√%d%s" % [m, t, tail], ["x = ", {"slot": "a"}, "√", {"slot": "b"}, tail], {"a": Q.new(m), "b": Q.new(t)})
		var sq: int = m * m * t
		ws = [other("x = %d%s" % [sq, tail], R_NO_ROOT)]
		if s.fam != "paddock":
			var inside: Q = Q.new(s.P) if s.fam == "bin" else Q.new(s.c, s.a)
			ws.append(other("x = " + root_text(inside) + tail, R_ROOT))
		var other_t: int = OptimisationSituation.NON_SQUARE[(OptimisationSituation.NON_SQUARE.find(t) + 1) % OptimisationSituation.NON_SQUARE.size()]
		gen = [mk.call(2 * m, t).values, mk.call(m, other_t).values, mk.call(m + 1, t).values, mk.call(m + 2, t).values, mk.call(3 * m, t).values]
		steps.append("%s = 0: %s = 0, so x² = %d." % [d_name(s), show(deriv(s), "x"), sq])
		steps.append("Take the positive root and simplify: √%d = %d√%d." % [sq, m, t])
	steps.append(sign_line(s))
	steps.append(say(ans))
	out.answer = ans
	out.wrongs = ws
	out.generic = gen
	out.methods = {"differentiate-and-test": method(steps, ans.values)}
	return out


# ── Justifying a maximum or a minimum ────────────────────────

## The point as the question names it: its value, or its exact surd on Paper 2.
static func point_text(s: Dictionary) -> String:
	if s.x is Q:
		return W(s.x)
	match s.fam:
		"pen":
			return D(Q.new(s.F, 2 * s.n))
		"paddock":
			return root_text(Q.new(s.P, s.n))
		"can":
			return "∛(%s)" % _frac_pi(s.V, s.e)
		"bin":
			return root_text(Q.new(s.P, 3))
		"arch":
			return root_text(Q.new(s.c, 3 * s.a))
	return W(s.x)


static func _frac_pi(a: int, b: int) -> String:
	var g := Q.gcd(a, b)
	return "%d/π" % (a / g) if b == g else "%d/(%dπ)" % [a / g, b / g]


static func nature_of(s: Dictionary, flip: bool = false) -> String:
	return Answer.NATURES[0] if s.big != flip else Answer.NATURES[1]


func u_justify_second_derivative(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := {"graph": null, "lines": _equation(s) + ["%s has a stationary point at %s = %s." % [obj(s), vr(s), point_text(s)]]}
	var n := dd_name(s)
	out.asked = "Find %s at this point, and decide whether it is a local maximum or a local minimum." % n
	var head := "%s = " % n
	var num: Q = s.d2 if s.d2 is Q else GdcKit.qf(s.d2)
	var shown := func(v: Variant) -> String:
		return P_(s, v) if v is Q else Fmt.sf(v)
	var parts: Array = [head, {"slot": "v"}, ("π" if s.pi else "") + ", a ", {"pick": "kind", "options": Answer.NATURES}]
	var txt := func(v: Variant, kind: String) -> String:
		return "%s%s, a %s" % [head, shown.call(v), kind]
	var ans := DifferentiationViews.form(txt.call(s.d2, nature_of(s)), parts, {"v": num, "kind": nature_of(s)})
	ans.exact = s.d2 is Q
	var as_q := func(v: Variant) -> Q:
		return v if v is Q else GdcKit.qf(v)
	var mk := func(v: Variant, kind: String, ref: String = "") -> Dictionary:
		return typed(txt.call(v, kind), {"v": as_q.call(v), "kind": kind}, ref)
	out.answer = ans
	out.wrongs = [mk.call(s.d2, nature_of(s, true), R_SWAP)]
	out.generic = [mk.call(scaled(s.d2, 2), nature_of(s)).values, mk.call(scaled(s.d2, 1, 2), nature_of(s)).values,
		mk.call(scaled(s.d2, 2), nature_of(s, true)).values, mk.call(scaled(s.d2, 1, 2), nature_of(s, true)).values, mk.call(scaled(s.d2, 3), nature_of(s)).values]
	var sign_ := "negative" if s.big else "positive"
	out.methods = {"second-derivative-test": method([d_text(s) + ".", dd_text(s) + ".",
		"At %s = %s the value is %s, which is %s." % [vr(s), point_text(s), P_(s, s.d2), sign_], "So %s." % Answer.text(ans)], ans.values)}
	return out


func u_justify_sign_change(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := vr(s)
	var o := obj(s)
	var out := {"graph": null, "lines": _equation(s) + ["%s has a stationary point at %s = %s." % [o, v, point_text(s)]]}
	var n := d_name(s)
	out.asked = "Find %s at %s = %s and at %s = %s, and decide what kind of point it is." % [n, v, W(s.lo), v, W(s.hi)]
	var pi_tail := "π" if s.pi else ""
	var left := "at %s = %s: %s = " % [v, W(s.lo), n]
	var mid := "; at %s = %s: %s = " % [v, W(s.hi), n]
	var end := "; a "
	var parts: Array = [left, {"slot": "a"}, pi_tail + mid, {"slot": "b"}, pi_tail + end, {"pick": "kind", "options": Answer.NATURES}]
	var shown := func(x: Variant) -> String:
		return P_(s, x) if x is Q else Fmt.sf(x)
	var txt := func(a: Variant, b: Variant, kind: String) -> String:
		return left + shown.call(a) + mid + shown.call(b) + end + kind
	var as_q := func(x: Variant) -> Q:
		return x if x is Q else GdcKit.qf(x)
	var ans := DifferentiationViews.form(txt.call(s.dlo, s.dhi, nature_of(s)), parts, {"a": as_q.call(s.dlo), "b": as_q.call(s.dhi), "kind": nature_of(s)})
	ans.exact = s.dlo is Q
	var mk := func(a: Variant, b: Variant, kind: String, ref: String = "") -> Dictionary:
		return typed(txt.call(a, b, kind), {"a": as_q.call(a), "b": as_q.call(b), "kind": kind}, ref)
	out.answer = ans
	var ts := OptimisationSituation.terms(s)
	var f_lo: Variant = OptimisationSituation.at(s, ts, s.lo)
	var f_hi: Variant = OptimisationSituation.at(s, ts, s.hi)
	out.wrongs = [mk.call(s.dlo, s.dhi, nature_of(s, true), R_SWAP), mk.call(f_lo, f_hi, nature_of(s), R_SIGN_F)]
	out.generic = [mk.call(scaled(s.dlo, 2), s.dhi, nature_of(s)).values, mk.call(s.dlo, scaled(s.dhi, 2), nature_of(s)).values,
		mk.call(scaled(s.dlo, -1), scaled(s.dhi, -1), nature_of(s, true)).values, mk.call(scaled(s.dhi, 1), scaled(s.dlo, 1), nature_of(s, true)).values]
	var change := "positive to negative" if s.big else "negative to positive"
	out.methods = {"first-derivative-sign-table": method([d_text(s) + ".",
		"At %s = %s it is %s, and at %s = %s it is %s." % [v, W(s.lo), P_(s, s.dlo), v, W(s.hi), P_(s, s.dhi)],
		"The gradient goes from %s, so the point is a local %s." % [change, word(s)], "So %s." % Answer.text(ans)], ans.values)}
	return out


# ── The value at the optimum ─────────────────────────────────

## The fixed amount as the question gave it, for the option that gives it back.
static func constraint_text(s: Dictionary) -> String:
	match s.fam:
		"pen":
			return "%d m of fence" % s.F
		"paddock":
			return "%d m²" % s.P
		"can":
			return ("%dπ %s³" % [s.k, unit(s)]) if s.paper == 1 else ("%d %s³" % [s.V, unit(s)])
		"bin":
			return "%d cm²" % s.P
	return ""


## The function at the optimum, term by term.
static func _sub_line(s: Dictionary) -> String:
	var bits: Array = []
	for t in OptimisationSituation.terms(s):
		var one: Variant = OptimisationSituation.at(s, [t], s.x)
		bits.append([one, t[2] and s.pi])
	var line := ""
	for b in bits:
		var neg: bool = (b[0].sign() < 0) if b[0] is Q else b[0] < 0.0
		var mag: Variant = b[0].abs_q() if b[0] is Q else absf(b[0])
		var text: String = DifferentiationViews.T(mag, "π") if b[1] else W(mag)
		line += text if line == "" and not neg else (("−" + text) if line == "" else ((" − " if neg else " + ") + text))
	return "Substitute %s = %s: %s = %s = %s." % [vr(s), W(s.x), obj(s), line, P_(s, s.best)]


func u_optimum_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := setup(rep, s) if rep != "equation" else {"graph": null, "lines": _equation(s)}
	if rep != "equation":
		out.lines = out.lines + ["%s, %s." % [f_text(s), domain(s)]]
	var o := obj(s)
	var v := vr(s)
	out.asked = "Find the %s value of %s." % [word(s), o]
	var tail := ("π" if s.pi else "") + value_tail(s)
	var ans := amount(s, o + " = ", s.best, tail)
	out.answer = ans
	var ws: Array = [other("%s = %s %s" % [v, _sf(s.x), unit(s)], R_X)]
	var c := constraint_text(s)
	if c != "" and rep != "equation":
		ws.append(other(c, R_X))
	out.wrongs = ws
	out.generic = spread(ans, s.best)
	var steps: Array = ["%s." % d_text(s)]
	steps += solve_lines(s, rep)
	steps.append(test_line(s))
	steps.append(_sub_line(s))
	steps.append(say(ans))
	out.methods = {"differentiate-and-test": method(steps, ans.values)}
	if s.paper == 2:
		out.methods["gdc-graph-optimum"] = method(_gdc_steps(s, true) + [say(ans)], ans.values)
	return out


static func _sf(v: Variant) -> String:
	return Fmt.num(v) if v is Q else Fmt.sf(v)


## The second length from the constraint, once x is known.
static func _y_line(s: Dictionary) -> String:
	var x_ := W(s.x)
	var y_ := W(s.y)
	match s.fam:
		"paddock":
			return "y = %d/x = %d ÷ %s = %s." % [s.P, s.P, x_, y_]
		"can":
			if s.paper == 1:
				return "h = %d/r² = %d ÷ %s² = %s." % [s.k, s.k, x_, y_]
			return "h = %d/(πr²) = %d ÷ (π × %s²) = %s." % [s.V, s.V, x_, y_]
		"bin":
			return "h = (%d − x²)/(4x) = (%d − %s²) ÷ (4 × %s) = %s." % [s.P, s.P, x_, x_, y_]
	return ""


## The objective in the free length alone, from the constraint.
static func _one_variable_line(s: Dictionary) -> String:
	match s.fam:
		"paddock":
			return "L = %sx + y, and xy = %d gives y = %d/x, so %s." % [Fmt.lead(s.n), s.P, s.P, f_text(s)]
		"can":
			var pi1: bool = s.paper == 1
			var m: int = s.k if pi1 else s.V
			return "%s = %sπr² + 2πrh, and πr²h = %s gives h = %s, so %s." % [obj(s), Fmt.lead(s.e), "%dπ" % m if pi1 else str(m), "%d/r²" % m if pi1 else "%d/(πr²)" % m, f_text(s)]
	return "V = x²h, and x² + 4xh = %d gives h = (%d − x²)/(4x), so %s." % [s.P, s.P, f_text(s)]


func u_other_dimension(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := setup(rep, s)
	out.lines = out.lines + [name_line(s)]
	var o := obj(s)
	var v := vr(s)
	var w := second(s)
	out.asked = "Find the value of %s when %s is a %s." % [w, o, word(s)]
	var ans := amount(s, w + " = ", s.y, " " + unit(s))
	out.answer = ans
	out.wrongs = [like(ans, s.x, R_FIRST)]
	out.generic = spread(ans, s.y)
	var steps: Array = [_one_variable_line(s), "%s." % d_text(s)]
	steps += solve_lines(s)
	steps.append(test_line(s))
	steps.append(_y_line(s))
	steps.append(say(ans))
	out.methods = {"differentiate-and-test": method(steps, ans.values)}
	return out


# ── A quadratic model ────────────────────────────────────────

## Why y is what it is: pens are one fewer than the sections between them.
static func _pen_line(s: Dictionary) -> String:
	var head := "%d pens need %d sections of length x and one of length y" % [s.n - 1, s.n] if s.n > 2 else "The fence is %d sections of length x and one of length y" % s.n
	return "%s, so %dx + y = %d and y = %d − %sx." % [head, s.n, s.F, s.F, Fmt.lead(s.n)]


func u_quadratic_optimum(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := setup(rep, s)
	out.asked = "Find the maximum area of the yard."
	var ans := amount(s, "A = ", s.best, " m²")
	out.answer = ans
	var y0: int = s.F
	var fence_all: Variant = scaled(s.best, 1, 2)
	out.wrongs = [other("x = %s m" % _sf(s.x), R_X), like(ans, fence_all, R_WALL)]
	out.generic = spread(ans, s.best)
	var fx := "A = x(%d − %sx)" % [y0, Fmt.lead(s.n)]
	var area_line := "A = %s × (%d − %d × %s) = %s." % [W(s.x), s.F, s.n, W(s.x), W(s.best)]
	out.methods = {
		"differentiate-and-test": method([_pen_line(s), "A = xy = %dx − %sx²." % [s.F, Fmt.lead(s.n)],
			"dA/dx = %d − %dx = 0, so x = %s." % [s.F, 2 * s.n, W(s.x)], "d²A/dx² = %s, which is negative, so this is a maximum." % D(-2 * s.n), area_line, say(ans)], ans.values),
		"quadratic-vertex": method([_pen_line(s), "So %s." % fx, "A = 0 at x = 0 and x = %s, and the vertex is halfway between the roots: x = %s." % [D(Q.new(s.F, s.n)), W(s.x)],
			area_line, say(ans)], ans.values),
	}
	return out


# ── The tray: a root that doesn't fit ────────────────────────

func u_box_best_cut(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := setup(rep, s)
	out.lines = out.lines + ["V = x(%d − 2x)(%d − 2x)" % [s.w, s.h]]
	out.asked = "Find the value of x that gives the tray its greatest volume."
	var ans := amount(s, "x = ", s.x, " cm")
	out.answer = ans
	var half: Q = Q.new(mini(s.w, s.h), 2)
	out.wrongs = [like(ans, s.other, R_DOMAIN), like(ans, half if s.x is Q else half.to_float(), R_ROOT)]
	out.generic = spread(ans, s.x)
	var steps: Array = ["V = %s." % show(OptimisationSituation.terms(s), "x"), "%s." % d_text(s)]
	steps += solve_lines(s)
	steps.append(test_line(s))
	steps.append(say(ans))
	out.methods = {"differentiate-and-test": method(steps, ans.values)}
	if s.paper == 2:
		out.methods["gdc-graph-optimum"] = method(["Graph V = x(%d − 2x)(%d − 2x) on the GDC, for 0 < x < %s." % [s.w, s.h, D(half)],
			"The maximum tool gives x = %s." % W(s.x), say(ans)], ans.values)
	return out


# ── The route ────────────────────────────────────────────────

static func route_text(s: Dictionary) -> String:
	if s.cost:
		return "C = %d√(%d + x²) + %d(%d − x)" % [s.front, s.a * s.a, s.back, s.b]
	return "T = √(%d + x²)/%d + (%d − x)/%d" % [s.a * s.a, s.front, s.b, s.back]


func _route_setup(rep: String, s: Dictionary) -> Dictionary:
	var out := setup(rep, s)
	out.lines = out.lines + ["%s, for 0 ≤ x ≤ %d." % [route_text(s), s.b]]
	return out


func u_route_best_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := _route_setup(rep, s)
	out.asked = "Find the value of x that makes %s a minimum." % obj(s)
	var ans := amount(s, "x = ", s.x, " km")
	out.answer = ans
	out.wrongs = [like(ans, s.b - s.x, R_FROM_B)]
	out.generic = spread(ans, s.x)
	out.methods = {"gdc-graph-optimum": method(["Graph the function on the GDC, for 0 ≤ x ≤ %d." % s.b, "The minimum tool gives x = %s." % W(s.x), say(ans)], ans.values)}
	return out


func u_route_least_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := _route_setup(rep, s)
	out.asked = "Find the minimum value of %s." % obj(s)
	var ans := amount(s, obj(s) + " = ", s.best, value_tail(s))
	out.answer = ans
	out.wrongs = [other("x = %s km" % Fmt.sf(s.x), R_X), like(ans, OptimisationSituation.route_value(s, float(s.b)), R_DIRECT)]
	out.generic = spread(ans, s.best)
	out.methods = {"gdc-graph-optimum": method(["Graph the function on the GDC, for 0 ≤ x ≤ %d." % s.b, "The minimum tool gives x = %s and %s = %s." % [W(s.x), obj(s), W(s.best)], say(ans)], ans.values)}
	return out


# ── The closest point on a curve ─────────────────────────────

func u_closest_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := {"graph": _closest_figure(s) if rep == "diagram" else null}
	var ans := amount(s, "x = ", s.x)
	out.answer = ans
	var m: int = s.x.n
	if s.kind == "root":
		out.lines = ["A relay stands at P(%d, 0), and a road follows the curve y = √(%sx), for x ≥ 0." % [s.px, Fmt.lead(s.k)], "Q(x, y) is a point on the road."]
		out.asked = "Find the x-coordinate of the point Q that is closest to P."
		out.wrongs = [like(ans, Q.new(s.px), R_ABOVE)]
		if s.px > s.k:
			out.wrongs.append(like(ans, Q.new(s.px - s.k), R_CHAIN))
		out.generic = [like(ans, Q.new(s.px).add(Q.new(s.k, 2))).values, like(ans, s.x.add(1)).values, like(ans, s.x.mul(2)).values, like(ans, s.x.add(2)).values]
		var sq := "(x − %d)² + %sx" % [s.px, Fmt.lead(s.k)]
		out.methods = {"differentiate-and-test": method(["PQ² = (x − %d)² + y² = %s. The distance is least where PQ² is least." % [s.px, sq],
			"d(PQ²)/dx = 2(x − %d) + %d." % [s.px, s.k], "2(x − %d) + %d = 0, so x = %s." % [s.px, s.k, W(s.x)],
			"The second derivative is 2, which is positive, so this is a minimum.", say(ans)], ans.values)}
		return out
	var top := Q.new(s.c, s.k)
	var up := ("e" + Fmt.sup(top.n)) if top.is_int() else "e^(%s)" % D(top)
	out.lines = ["A curve is y = √(%d − %s ln x), for 0 < x ≤ %s." % [s.c, Fmt.lead(s.k), up], "Q(x, y) is a point on the curve, and O is the origin."]
	out.asked = "Find the x-coordinate of the point Q that is closest to O."
	out.wrongs = [] if m == 1 else [like(ans, Q.new(m * m), R_NO_ROOT)]
	out.generic = [like(ans, Q.new(m + 1)).values, like(ans, Q.new(s.k)).values, like(ans, Q.new(2 * m + 1)).values, like(ans, Q.new(m + 2)).values, like(ans, Q.new(1, m + 1)).values]
	out.methods = {"differentiate-and-test": method(["OQ² = x² + y² = x² + %d − %s ln x. The distance is least where OQ² is least." % [s.c, Fmt.lead(s.k)],
		"d(OQ²)/dx = 2x − %d/x." % s.k, "2x − %d/x = 0, so x² = %d and x = %d, as x > 0." % [s.k, s.k / 2, m],
		"The second derivative is 2 + %d/x², which is positive, so this is a minimum." % s.k, say(ans)], ans.values)}
	return out
