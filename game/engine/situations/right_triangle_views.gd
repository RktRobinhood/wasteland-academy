class_name RightTriangleViews
extends BearingsViews
## The views on the `right-triangle` situation: one builder per unknown of t3-right-angle-trig
## (FAL-739). It extends BearingsViews for its writing and sketch helpers. Paper 2 measures are to
## 3 s.f. with the rounding trap; Paper 1 answers are exact.
##
## Representations: "words" (the story alone) and "diagram" (the same story with PlotView's
## `sketch`: a triangle turned to any position, a circle, or a side view with the horizontal at
## the eye drawn, so the place of an angle is on show). An angle of elevation or depression
## always has its figure. Worked figures are five significant figures.

const RT_TYPE := "t3-right-angle-trig#"
const R_WRONG_ANGLE := "SL3.2.right-ratio#0"
const R_UPSIDE := "SL3.2.right-ratio#1"
const R_LONG_LEG := "SL3.2.right-ratio#2"
const R_GRAD_SIN := "SL3.2.right-ratio#3"
const R_GRAD_FLIP := "SL3.2.right-ratio#4"
const R_REARRANGE := "SL3.2.right-side#0"
const R_HYP_ADJ := "SL3.2.right-side#1"
const R_HALF := "SL3.2.right-side#3"
const R_NO_INVERSE := "SL3.2.right-angle#0"
const R_ONE_OVER := "SL3.2.right-angle#1"
const R_OTHER_ACUTE := "SL3.2.right-angle#2"
const R_GRAD_ARCSIN := "SL3.2.right-angle#3"
const R_HORIZONTAL := "SL3.2.right-angle#4"
## The story's own slips: an index into the type's misconceptions.
const R_MODE := RT_TYPE + "7"
const R_WHOLE_SPAN := RT_TYPE + "17"
const R_NO_OVERHANG := RT_TYPE + "18"
const R_NO_EXTRA := RT_TYPE + "19"
const R_EXTRA_T := RT_TYPE + "20"
const R_WALKED := RT_TYPE + "21"
const R_HALF_PHI := RT_TYPE + "22"
const R_CENTRE := RT_TYPE + "23"
const R_AT_GROUND := RT_TYPE + "24"
const R_DIAMETER := RT_TYPE + "25"
const R_APEX := RT_TYPE + "26"
const R_OTHER_TOWER := RT_TYPE + "27"
const R_ADD_DISTANCES := RT_TYPE + "28"

const RT_UNKNOWNS := ["ratio-from-sides", "ratio-needs-pythagoras", "ratio-in-letters", "side-in-letters", "side-from-angle",
	"side-under-ratio", "side-either-angle", "chord-length", "side-special", "angle-from-sides", "angle-special",
	"gradient-from-angle", "angle-from-gradient", "angle-with-vertical", "edge-from-span", "upper-edge", "height-from-angle",
	"elevation-after-walk", "equal-elevations", "cone-from-eye-level", "depression-sight-line", "depression-from-sight-line",
	"depression-two-points", "name-the-angle"]
const RT_EXACT := ["ratio-from-sides", "ratio-needs-pythagoras", "ratio-in-letters", "side-in-letters", "side-special", "angle-special"]

## What leans, what slopes, what rises and what is round.
const RT_LEANS := ["zip line", "boarding ramp", "steel strut", "conveyor belt", "rope walkway", "salvage chute"]
const RT_SLOPES := ["track", "dirt road", "mine ramp", "caravan trail", "gravel path", "rail line"]
const RT_HEAPS := ["spoil heap", "slag heap", "dune", "rubble mound", "scrap pile", "cinder heap"]
const RT_GANTRY := ["gantry over a gate", "bridge truss", "hoist frame", "market arch", "pump shelter frame", "signal frame"]
const RT_ROUND := ["hatch", "vent cover", "filter plate", "solar panel", "steel door", "access panel"]
const RT_TUBE := ["pipe", "storage tank", "drum", "culvert", "boiler", "water main"]
const RT_RANGE := ["radio mast", "signal beacon", "relay tower", "scanner dish", "radar post", "alarm siren"]


func needs() -> Dictionary:
	var out := {}
	for u in RT_UNKNOWNS:
		out[u] = {"ask": u}
	return out


## An exact answer can be either paper; the rest need a calculator. The engine draws the paper.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	if not has(unknown):
		return []
	return [1, 2] if unknown in RT_EXACT else [2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = RightTriangleSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func fnv(fn: String, t: float) -> float:
	match fn:
		"sin":
			return sin(t)
		"cos":
			return cos(t)
	return tan(t)


static func deg_of(s: Dictionary) -> float:
	return s.e.to_float()


static func m(v: Variant) -> String:
	return D(v) + " m"


static func t_of(s: Dictionary) -> String:
	return s.names[0]


static func r_of(s: Dictionary) -> String:
	return s.names[1]


static func o_of(s: Dictionary) -> String:
	return s.names[2]


static func theta_name(s: Dictionary) -> String:
	return "angle %s%s%s" % [r_of(s), t_of(s), o_of(s)]


## The three vertices in their alphabetical order.
static func tri_name(s: Dictionary) -> String:
	var n: Array = s.names.duplicate()
	n.sort()
	return "".join(n)


## "AB" with the letters in alphabetical order, as a side is usually read.
static func sn(a: String, b: String) -> String:
	return a + b if a < b else b + a


static func opp(s: Dictionary) -> String:
	return sn(r_of(s), o_of(s))


static func adj(s: Dictionary) -> String:
	return sn(t_of(s), r_of(s))


static func hyp(s: Dictionary) -> String:
	return sn(t_of(s), o_of(s))


## An exact value as a `form` answer: a whole multiple of a root has no denominator to type.
static func ex(label: String, v: Array, tail: String = "") -> Dictionary:
	var a := TrigKit.ans(label, v, tail)
	var sl := ex_slots(v)
	if a.shape == "s" and not sl.has("d"):
		var parts: Array = [label, {"slot": "m"}, "√", {"slot": "r"}, tail]
		a = DifferentiationViews.form(label + TrigKit.text(v) + tail, parts, sl)
		a.head = label
		a.tail = tail
		a.shape = "s"
	return a


static func ex_slots(v: Array) -> Dictionary:
	var sl := TrigKit.slots(v)
	if sl.has("d") and sl.d.eq(Q.new(1)):
		sl.erase("d")
	return sl


## A wrong exact option: typed where it has the answer's slots, else only picked.
static func ex_like(a: Dictionary, v: Array, ref: String = "") -> Dictionary:
	var sl := ex_slots(v)
	var mine: Array = a.values.keys().filter(func(k): return k != "text")
	var same: bool = mine.size() == sl.size() and mine.all(func(k): return sl.has(k))
	return DifferentiationViews.alt(a.head + TrigKit.text(v) + a.tail, ref, sl if same else {})


static func ex_others(a: Dictionary, vs: Array) -> Array:
	var out: Array = []
	for v in vs:
		out.append(ex_like(a, v).values)
	return out


# ── Figures ──────────────────────────────────────────────────

## The vertices of a triangle with these sides: T at the origin, turned by s.spin.
static func tri_pts(s: Dictionary, o: float, a: float) -> Dictionary:
	var ux := cos(rad(float(s.spin)))
	var uy := sin(rad(float(s.spin)))
	var f := float(s.flip)
	var out := {}
	out[t_of(s)] = [0.0, 0.0]
	out[r_of(s)] = [ux * a, uy * a]
	out[o_of(s)] = [ux * a - uy * o * f, uy * a + ux * o * f]
	return out


## The triangle in the position s.spin gives, with θ marked and the right angle squared.
static func tri_sketch(s: Dictionary, o: float, a: float, ol: String, al: String, hl: String, angle_label: String) -> Dictionary:
	var T := t_of(s)
	var R := r_of(s)
	var O := o_of(s)
	return sketch(tri_pts(s, o, a), [side(R, O, ol), side(T, R, al), side(T, O, hl)], [arc(T, R, O, angle_label)], [], {"right": [R]})


## A triangle standing on the ground: T left, R right, O above R.
static func ground_sketch(s: Dictionary, o: float, a: float, ol: String, al: String, hl: String, angle_label: String) -> Dictionary:
	var T := t_of(s)
	var R := r_of(s)
	var O := o_of(s)
	var pts := {}
	pts[T] = [0.0, 0.0]
	pts[R] = [a, 0.0]
	pts[O] = [a, o]
	return sketch(pts, [side(O, R, ol), side(T, R, al), side(T, O, hl)], [arc(T, R, O, angle_label)], [], {"right": [R]})


# ── Ratios ───────────────────────────────────────────────────

static func triangle_lines(s: Dictionary, sides: String) -> Array:
	return ["Triangle %s has a right angle at %s." % [tri_name(s), r_of(s)], sides, "θ is %s." % theta_name(s)]


## What the ratio is over: top and bottom sides by fn, as [top, bottom].
static func ratio_of(fn: String, o: Variant, a: Variant, h: Variant) -> Array:
	match fn:
		"sin":
			return [o, h]
		"cos":
			return [a, h]
	return [o, a]


static func ratio_words(fn: String) -> String:
	match fn:
		"sin":
			return "opposite ÷ hypotenuse"
		"cos":
			return "adjacent ÷ hypotenuse"
	return "opposite ÷ adjacent"


func u_ratio_from_sides(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var fn: String = s.fn
	var a: Q = s.a
	var b: Q = s.b
	var c: Q = s.c
	var pair := ratio_of(fn, a, b, c)
	var ans := ex(fn + " θ = ", TrigKit.V(pair[0].div(pair[1])))
	var list := "%s = %s, %s = %s and %s = %s." % [opp(s), m(a), adj(s), m(b), hyp(s), m(c)]
	var g := tri_sketch(s, a.to_float(), b.to_float(), m(a), m(b), m(c), "θ")
	var out := frame(rep, triangle_lines(s, list), "Write down the value of %s θ as a fraction." % fn, ans, g)
	out.wrongs = [ex_like(ans, TrigKit.V(pair[1].div(pair[0])), R_UPSIDE)]
	if fn != "tan":
		var other: Q = b if fn == "sin" else a
		out.wrongs.append(ex_like(ans, TrigKit.V(other.div(c)), R_WRONG_ANGLE))
		var mine: Q = a if fn == "sin" else b
		if mine.lt(other):
			out.wrongs.append(ex_like(ans, TrigKit.V(mine.div(other)), R_LONG_LEG))
	out.generic = ex_others(ans, [TrigKit.V(a.div(c)), TrigKit.V(b.div(c)), TrigKit.V(a.div(b)), TrigKit.V(b.div(a))])
	out.methods = {
		"label-soh-cah-toa": method(["The hypotenuse is opposite the right angle: %s = %s." % [hyp(s), D(c)],
			"Opposite θ is %s = %s, and adjacent to θ is %s = %s." % [opp(s), D(a), adj(s), D(b)],
			"%s θ = %s, which is %s/%s." % [fn, ratio_words(fn), D(pair[0]), D(pair[1])], say(ans)], ans.values),
		"scale-to-unit": method(["Divide every side by the hypotenuse %s, so that it becomes 1." % D(c),
			"The side opposite θ becomes %s and the side adjacent to it becomes %s." % [Fmt.num(a.div(c)), Fmt.num(b.div(c))],
			"In this smaller triangle the angle is still θ, and %s." % _scaled_words(fn, a.div(c), b.div(c)), say(ans)], ans.values)}
	return out


static func _scaled_words(fn: String, o: Q, a: Q) -> String:
	match fn:
		"sin":
			return "sin θ is the height, %s" % Fmt.num(o)
		"cos":
			return "cos θ is the base, %s" % Fmt.num(a)
	return "tan θ is the height ÷ the base, %s ÷ %s" % [Fmt.num(o), Fmt.num(a)]


func u_ratio_needs_pythagoras(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var fn: String = s.fn
	var a: int = s.a.n
	var b: int = s.b.n
	var n := a * a + b * b
	var h: Array = TrigKit.root(n)
	var top: int = a if fn == "sin" else b
	var other: int = b if fn == "sin" else a
	var v: Array = TrigKit.over(TrigKit.V(top), h)
	var ans := ex(fn + " θ = ", v)
	var list := "%s = %s and %s = %s." % [opp(s), m(a), adj(s), m(b)]
	var g := tri_sketch(s, float(a), float(b), m(a), m(b), "", "θ")
	var out := frame(rep, triangle_lines(s, list), "Find the exact value of %s θ." % fn, ans, g)
	out.wrongs = [ex_like(ans, TrigKit.over(h, TrigKit.V(top)), R_UPSIDE), ex_like(ans, TrigKit.over(TrigKit.V(other), h), R_WRONG_ANGLE)]
	if top < other:
		out.wrongs.append(ex_like(ans, TrigKit.V(Q.new(top, other)), R_LONG_LEG))
	out.generic = ex_others(ans, [TrigKit.V(Q.new(top, other)), TrigKit.V(Q.new(other, top)), TrigKit.times(v, 2), TrigKit.V(Q.new(top, a + b))])
	var surd := TrigKit.text(h)
	var named := "√%d" % n
	var hyp_line := "so the hypotenuse is %s." % named if surd == named else "so the hypotenuse is %s, which is %s." % [named, surd]
	# The hypotenuse as c√radicand; a whole factor cancels before the root is cleared.
	var c := 1
	var radicand := n
	for f in range(9, 1, -1):
		while radicand % (f * f) == 0:
			radicand /= f * f
			c *= f
	var shared := Q.gcd(top, c)
	var steps := ["%s² = %d² + %d², which is %d, %s" % [hyp(s), a, b, n, hyp_line],
		"%s θ = %s, which is %d/%s." % [fn, ratio_words(fn), top, surd if c == 1 else "(%s)" % surd]]
	var low := c / shared
	if shared > 1:
		steps.append("That simplifies to %d/%s." % [top / shared, "√%d" % radicand if low == 1 else "(%d√%d)" % [low, radicand]])
	steps.append("Multiply the top and bottom by √%d to clear the root." % radicand)
	steps.append(say(ans))
	out.methods = {"pythagoras-third-side": method(steps, ans.values)}
	return out


func u_ratio_in_letters(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var fn: String = s.fn
	var o: String = s.sides[0]
	var a: String = s.sides[1]
	var h: String = s.sides[2]
	var pair := ratio_of(fn, o, a, h)
	var head := fn + " θ = "
	var letters := ["p", "q", "r"]
	var ans := DifferentiationViews.form("%s%s/%s" % [head, pair[0], pair[1]],
		[head, {"pick": "top", "options": letters}, "/", {"pick": "bot", "options": letters}], {"top": pair[0], "bot": pair[1]})
	var list := "%s = %s, %s = %s and %s = %s." % [opp(s), o, adj(s), a, hyp(s), h]
	var g := tri_sketch(s, s.a.to_float(), s.b.to_float(), o, a, h, "θ")
	var out := frame(rep, triangle_lines(s, list), "Write down %s θ in terms of the sides p, q and r." % fn, ans, g)
	var slip := func(top: String, bot: String, ref: String = "") -> Dictionary:
		return DifferentiationViews.alt("%s%s/%s" % [head, top, bot], ref, {"top": top, "bot": bot})
	out.wrongs = [slip.call(pair[1], pair[0], R_UPSIDE)]
	if fn != "tan":
		var other: String = a if fn == "sin" else o
		var mine: String = o if fn == "sin" else a
		out.wrongs.append(slip.call(other, h, R_WRONG_ANGLE))
		# A leg can only be seen to be the longer one in a figure.
		var longer: bool = s.b.to_float() > s.a.to_float() if fn == "sin" else s.a.to_float() > s.b.to_float()
		if rep == "diagram" and longer:
			out.wrongs.append(slip.call(mine, other, R_LONG_LEG))
	out.generic = [slip.call(o, h).values, slip.call(a, h).values, slip.call(o, a).values, slip.call(a, o).values, slip.call(h, a).values, slip.call(h, o).values]
	out.methods = {"label-soh-cah-toa": method(["The hypotenuse is opposite the right angle: %s = %s." % [hyp(s), h],
		"Opposite θ is %s = %s, and adjacent to θ is %s = %s." % [opp(s), o, adj(s), a],
		"%s θ = %s." % [fn, ratio_words(fn)], say(ans)], ans.values)}
	return out


# ── Sides ────────────────────────────────────────────────────

func u_side_in_letters(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var fn: String = s.fn
	var asked_side := "PS" if fn == "sin" else "RS"
	var options := ["sin θ", "cos θ", "tan θ"]
	var head := asked_side + " = "
	var text := func(k: int, f: String) -> String:
		return "%s%sr %s" % [head, "" if k == 1 else str(k), f]
	var mine := fn + " θ"
	var ans := DifferentiationViews.form(text.call(2, mine), [head, {"slot": "k"}, "r ", {"pick": "f", "options": options}], {"k": Q.new(2), "f": mine})
	var lines := ["A rectangular %s PQRS fits exactly inside a round %s with centre O and radius r." % [RT_ROUND[s.ctx], RT_TUBE[s.ctx]],
		"All four corners touch the circle, so the diagonal PR passes through O. Angle PRS = θ."]
	var t := rad(deg_of(s))
	var cx := cos(t)
	var sy := sin(t)
	var pts := {"P": [-cx, sy], "Q": [cx, sy], "R": [cx, -sy], "S": [-cx, -sy], "O": [0.0, 0.0], "_N": [0.0, 1.0], "_E": [1.0, 0.0], "_W": [-1.0, 0.0], "_L": [0.0, -1.0]}
	var g := sketch(pts, [side("P", "S", "?" if fn == "sin" else ""), side("S", "R", "?" if fn == "cos" else ""), side("R", "Q"), side("Q", "P"), side("O", "R", "r"), side("O", "P", "", true)],
		[arc("R", "S", "P", "θ")], [], {"right": ["S"], "circles": [{"at": "O", "through": "R"}]})
	var out := frame(rep, lines, "Write down an expression for %s in terms of r and θ." % asked_side, ans, g)
	var slip := func(k: int, f: String, ref: String = "") -> Dictionary:
		return DifferentiationViews.alt(text.call(k, f), ref, {"k": Q.new(k), "f": f})
	var other := "cos θ" if fn == "sin" else "sin θ"
	out.wrongs = [slip.call(1, mine, R_DIAMETER), slip.call(2, other, R_WRONG_ANGLE), slip.call(2, "tan θ", R_HYP_ADJ)]
	out.generic = [slip.call(1, other).values, slip.call(4, mine).values, DifferentiationViews.alt("%s2r/%s" % [head, mine]).values]
	out.methods = {"choose-ratio-rearrange": method(["PR is a diameter, so PR = 2r.",
		"In triangle PRS the right angle is at S, and PR is the hypotenuse.",
		"%s is %s θ, so %s θ = %s ÷ 2r." % [asked_side, "opposite" if fn == "sin" else "adjacent to", fn, asked_side], say(ans)], ans.values)}
	return out


static func lean_lines(s: Dictionary) -> Array:
	return ["A straight %s %s is %s long, with %s on level ground and %s directly above the point %s on the ground." % [RT_LEANS[s.ctx], hyp(s), m(s.x), t_of(s), o_of(s), r_of(s)],
		"The %s makes an angle of %s° with the ground." % [RT_LEANS[s.ctx], D(s.e)]]


static func cable_lines(s: Dictionary, given: String) -> Array:
	return ["A %s %s stands on level ground, with its foot at %s. A straight cable runs from the top %s to a peg %s%s." % [TALL[s.ctx], opp(s), r_of(s), o_of(s), t_of(s), given],
		"The cable makes an angle of %s° with the ground." % D(s.e)]


func u_side_from_angle(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.x.to_float()
	var t := rad(deg_of(s))
	var fn: String = s.fn
	var v := x * fnv(fn, t)
	var name := adj(s) if fn == "cos" else opp(s)
	var ans := ans_of(name + " = ", v, " m")
	var g: Dictionary
	var lines: Array
	var asked: String
	var known := "the hypotenuse"
	var want := "the opposite side"
	match fn:
		"sin":
			lines = lean_lines(s)
			asked = "Find %s, the height of %s above the ground." % [opp(s), o_of(s)]
			g = ground_sketch(s, v, x * cos(t), "?", "", m(s.x), D(s.e) + "°")
		"cos":
			lines = lean_lines(s)
			asked = "Find %s, the distance from %s to %s along the ground." % [adj(s), t_of(s), r_of(s)]
			want = "the adjacent side"
			g = ground_sketch(s, x * sin(t), v, "", "?", m(s.x), D(s.e) + "°")
		_:
			lines = cable_lines(s, ", %s from %s" % [m(s.x), r_of(s)])
			asked = "Find %s, the height of the %s." % [opp(s), TALL[s.ctx]]
			known = "the adjacent side"
			g = ground_sketch(s, v, x, "?", m(s.x), "", D(s.e) + "°")
	var out := frame(rep, lines, sf3(asked), ans, g)
	var slip_mode := x * fnv(fn, deg_of(s))
	out.wrongs = bad(slip_mode, R_MODE)
	if fn == "sin":
		out.wrongs += bad(x * tan(t), R_HYP_ADJ)
	out.generic = gens([x * cos(t) if fn != "cos" else x * sin(t), x / fnv(fn, t), x * tan(t) if fn != "tan" else x * sin(t), v + 2.0, v * 1.5])
	out.methods = {"choose-ratio-rearrange": method(["You know %s and want %s, so use %s θ = %s." % [known, want, fn, ratio_words(fn)],
		"The side you want is on top, so multiply: %s = %s × %s %s° = %s" % [name, D(s.x), fn, D(s.e), W(v)], say(ans)], ans.values)}
	return out


func u_side_under_ratio(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.x.to_float()
	var t := rad(deg_of(s))
	var fn: String = s.fn
	var v := x / fnv(fn, t)
	var ans := ans_of(hyp(s) + " = ", v, " m")
	var thing: String = RT_LEANS[s.ctx]
	var first := "A straight %s %s goes up from %s on level ground at an angle of %s°." % [thing, hyp(s), t_of(s), D(s.e)]
	var lines: Array
	var g: Dictionary
	if fn == "sin":
		lines = [first, "Its top %s is %s above the point %s on the ground directly below it." % [o_of(s), m(s.x), r_of(s)]]
		g = ground_sketch(s, x, v * cos(t), m(s.x), "", "?", D(s.e) + "°")
	else:
		lines = [first, "Its top %s is directly above the point %s on the ground, and %s = %s." % [o_of(s), r_of(s), adj(s), m(s.x)]]
		g = ground_sketch(s, v * sin(t), x, "", m(s.x), "?", D(s.e) + "°")
	var out := frame(rep, lines, sf3("Find %s, the length of the %s." % [hyp(s), thing]), ans, g)
	out.wrongs = bad(x * fnv(fn, t), R_REARRANGE) + bad(x / fnv(fn, deg_of(s)), R_MODE)
	if fn == "sin":
		out.wrongs += bad(x / tan(t), R_HYP_ADJ)
	out.generic = gens([x * tan(t), x / (cos(t) if fn == "sin" else sin(t)), x + 2.0, v + 2.0, v * 1.5])
	var known := "the opposite side" if fn == "sin" else "the adjacent side"
	out.methods = {"choose-ratio-rearrange": method(["You know %s and want the hypotenuse, so use %s θ = %s." % [known, fn, ratio_words(fn)],
		"%s %s° = %s ÷ %s: the side you want is underneath." % [fn, D(s.e), D(s.x), hyp(s)],
		"Multiply by %s, then divide by %s %s°." % [hyp(s), fn, D(s.e)], "%s ÷ %s %s° = %s" % [D(s.x), fn, D(s.e), W(v)], say(ans)], ans.values)}
	return out


func u_side_either_angle(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.x.to_float()
	var t := rad(deg_of(s))
	var v := x / tan(t)
	var ans := ans_of(adj(s) + " = ", v, " m")
	var lines := ["A %s %s stands on level ground, with its foot at %s and its top %s %s high." % [TALL[s.ctx], opp(s), r_of(s), o_of(s), m(s.x)],
		"A straight cable runs from %s to a peg %s, and makes an angle of %s° with the ground." % [o_of(s), t_of(s), D(s.e)]]
	var g := ground_sketch(s, x, v, m(s.x), "?", "", D(s.e) + "°")
	var out := frame(rep, lines, sf3("Find %s, the distance from the peg to the foot of the %s." % [adj(s), TALL[s.ctx]]), ans, g)
	out.wrongs = bad(x * tan(t), R_REARRANGE) + bad(x / tan(deg_of(s)), R_MODE)
	out.generic = gens([x / sin(t), x / cos(t), x * sin(t), v + 2.0, v * 1.5])
	var other: int = 90 - int(deg_of(s))
	out.methods = {
		"choose-ratio-rearrange": method(["You know the opposite side and want the adjacent one, so use tan θ = opposite ÷ adjacent.",
			"tan %s° = %s ÷ %s: the side you want is underneath." % [D(s.e), D(s.x), adj(s)], "%s ÷ tan %s° = %s" % [D(s.x), D(s.e), W(v)], say(ans)], ans.values),
		"other-acute-angle": method(["The other acute angle, at %s, is 90° − %s° = %d°." % [o_of(s), D(s.e), other],
			"From there, %s is opposite and %s is adjacent, so the side you want is on top." % [adj(s), opp(s)],
			"%s × tan %d° = %s" % [D(s.x), other, W(x * tan(rad(float(other))))], say(ans)], ans.values)}
	return out


func u_chord_length(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: float = s.r.to_float()
	var d: float = s.d.to_float()
	var half := sqrt(r * r - d * d)
	var v := 2.0 * half
	var ans := ans_of("AB = ", v, " km")
	var thing: String = RT_RANGE[s.ctx]
	var lines := ["%s %s at S reaches every point within %s km of it." % ["An" if thing.begins_with("a") else "A", thing, D(s.r)],
		"A straight road passes %s km from S, at the point M, where the road is at right angles to SM." % D(s.d),
		"The road enters the range at A and leaves it at B."]
	var pts := {"S": [0.0, 0.0], "M": [d, 0.0], "A": [d, half], "B": [d, -half], "_N": [0.0, r], "_L": [0.0, -r], "_W": [-r, 0.0], "_E": [r, 0.0]}
	var g := sketch(pts, [side("S", "M", D(s.d) + " km"), side("M", "B"), side("S", "A", D(s.r) + " km"), side("A", "B", "?")], [], [], {"right": ["M"], "circles": [{"at": "S", "through": "A"}]})
	var out := frame(rep, lines, sf3("Find AB, the length of road within range."), ans, g)
	out.wrongs = bad(half, R_HALF) + bad(2.0 * sqrt(r * r + d * d), R_HYP_ADJ)
	out.generic = gens([2.0 * (r - d), r * r - d * d, 2.0 * r, v + 2.0, v * 1.5])
	var at_s := rad_to_deg(acos(d / r))
	var aw := W(at_s)
	var hw := W(r * sin(rad(back(aw))))
	out.methods = {
		"pythagoras": method(["Triangle SMA has a right angle at M, and SA is its hypotenuse: AM² = %s² − %s²" % [D(s.r), D(s.d)],
			"AM = √%s = %s" % [D(s.r.mul(s.r).sub(s.d.mul(s.d))), W(half)], "S is the same distance from A and B, so M is the middle of AB: 2 × %s = %s" % [W(half), W(back(W(half)) * 2.0)], say(ans)], ans.values),
		"choose-ratio-rearrange": method(["In triangle SMA, cos(angle ASM) = %s ÷ %s, so angle ASM = %s°" % [D(s.d), D(s.r), aw],
			"AM = %s × sin %s° = %s" % [D(s.r), aw, hw], "S is the same distance from A and B, so M is the middle of AB: 2 × %s = %s" % [hw, W(back(hw) * 2.0)], say(ans)], ans.values)}
	return out


func u_side_special(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var deg: int = s.e.n
	var t := Q.new(deg, 180)
	var fn: String = s.fn
	var ratio: Array = TrigKit.of(fn, t)
	var k: int = s.k
	var o: float
	var a: float
	var lines: Array
	var v: Array
	var name: String
	var ans: Dictionary
	var R := r_of(s)
	var at := "Triangle %s has a right angle at %s, and angle %s%s%s = %d°." % [tri_name(s), R, R, t_of(s), o_of(s), deg]
	if s.mode == "leg":
		v = TrigKit.times(ratio, k)
		name = opp(s) if fn == "sin" else adj(s)
		ans = ex(name + " = ", v, " m")
		lines = [at, "%s = %s." % [hyp(s), m(k)]]
		o = k * sin(rad(deg))
		a = k * cos(rad(deg))
	else:
		v = TrigKit.over(TrigKit.V(k), ratio)
		name = hyp(s)
		ans = ex(name + " = ", v, " m")
		lines = [at, "%s = %s." % [opp(s) if fn == "sin" else adj(s), m(k)]]
		o = float(k) if fn == "sin" else k * tan(rad(deg))
		a = float(k) if fn == "cos" else k / tan(rad(deg))
	var at_o := "?" if name == opp(s) else (m(k) if s.mode == "hyp" and fn == "sin" else "")
	var at_a := "?" if name == adj(s) else (m(k) if s.mode == "hyp" and fn == "cos" else "")
	var at_h := "?" if name == hyp(s) else m(k)
	var g := tri_sketch(s, o, a, at_o, at_a, at_h, "%d°" % deg)
	var out := frame(rep, lines, "Find the exact length of %s." % name, ans, g)
	var other: Array = TrigKit.of("cos" if fn == "sin" else "sin", t)
	if s.mode == "hyp":
		out.wrongs = [ex_like(ans, TrigKit.times(ratio, k), R_REARRANGE)]
		out.generic = ex_others(ans, [TrigKit.over(TrigKit.V(k), other), TrigKit.times(other, k), TrigKit.V(2 * k), TrigKit.V(k), TrigKit.times(TrigKit.root(2), k), TrigKit.times(TrigKit.root(3), k)])
	else:
		out.wrongs = []
		out.generic = ex_others(ans, [TrigKit.over(TrigKit.V(k), ratio), TrigKit.times(other, k), TrigKit.V(k), TrigKit.times(TrigKit.root(2), k), TrigKit.times(TrigKit.root(3), k), TrigKit.V(2 * k)])
	var shape := "1 : 1 : √2, with the hypotenuse √2" if deg == 45 else "1 : √3 : 2, with the side opposite 30° as 1 and the hypotenuse 2"
	var value := TrigKit.text(ratio)
	var build_line := "%s = %d × %s" % [name, k, value] if s.mode == "leg" else "%s = %d ÷ %s" % [name, k, "(%s)" % value if value.contains("/") else value]
	if s.mode == "hyp" and value.contains("√"):
		build_line += " = %d/√%d" % [2 * k, 2 if deg == 45 else 3]
	# In the ratio's own sides: which part the known side matches, so the triangle can be scaled.
	var part_o := "√3" if deg == 60 else "1"
	var part_a := "√3" if deg == 30 else "1"
	var part_h := "√2" if deg == 45 else "2"
	var known_side: String = hyp(s) if s.mode == "leg" else (opp(s) if fn == "sin" else adj(s))
	var known_part: String = part_h if s.mode == "leg" else (part_o if fn == "sin" else part_a)
	var want_part: String = part_h if s.mode == "hyp" else (part_o if fn == "sin" else part_a)
	var scale: Array = TrigKit.over(TrigKit.V(k), _part_value(known_part))
	var scale_text := TrigKit.text(scale)
	var scale_line := "%s = %d matches the %s, so the scale is %s." % [known_side, k, known_part, scale_text if known_part == "1" else "%d ÷ %s = %s" % [k, known_part, scale_text]]
	var scaled_line := "%s matches the 1, so %s = %s" % [name, name, scale_text] if want_part == "1" else "%s matches the %s: %s = %s × %s" % [name, want_part, name, scale_text, want_part]
	out.methods = {
		"special-triangle": method(["A %d° right-angled triangle has sides in the ratio %s." % [deg, shape], scale_line, scaled_line, say(ans)], ans.values),
		"choose-ratio-rearrange": method(["Choose the ratio linking the two sides: %s θ = %s." % [fn, ratio_words(fn)],
			"%s %d° = %s, an exact value." % [fn, deg, value], build_line, say(ans)], ans.values)}
	return out


static func _part_value(part: String) -> Array:
	match part:
		"√2":
			return TrigKit.root(2)
		"√3":
			return TrigKit.root(3)
	return TrigKit.V(part.to_int())


# ── Angles ───────────────────────────────────────────────────

func u_angle_from_sides(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: float = s.a.to_float()
	var b: float = s.b.to_float()
	var fn: String = s.fn
	var r := a / b
	var t: float
	var thing: String = RT_LEANS[s.ctx]
	var lines: Array
	var g: Dictionary
	var inv := fn + "⁻¹"
	var o: float
	var ad: float
	var first := "A straight %s %s has %s on level ground and %s directly above the point %s on the ground." % [thing, hyp(s), t_of(s), o_of(s), r_of(s)]
	match fn:
		"sin":
			t = asin(r)
			o = a
			ad = sqrt(b * b - a * a)
			lines = [first, "It is %s long, and %s is %s above the ground." % [m(s.b), o_of(s), m(s.a)]]
			g = ground_sketch(s, o, ad, m(s.a), "", m(s.b), "?")
		"cos":
			t = acos(r)
			ad = a
			o = sqrt(b * b - a * a)
			lines = [first, "It is %s long, and %s = %s." % [m(s.b), adj(s), m(s.a)]]
			g = ground_sketch(s, o, ad, "", m(s.a), m(s.b), "?")
		_:
			t = atan(r)
			o = a
			ad = b
			lines = [first, "%s is %s above the ground, and %s = %s." % [o_of(s), m(s.a), adj(s), m(s.b)]]
			g = ground_sketch(s, o, ad, m(s.a), m(s.b), "", "?")
	var deg := rad_to_deg(t)
	var ans := ans_of("angle = ", deg, "°")
	var out := frame(rep, lines, sf3("Find the angle the %s makes with the ground." % thing), ans, g)
	out.wrongs = bad(fnv(fn, rad(r)), R_NO_INVERSE) + bad(1.0 / fnv(fn, rad(r)), R_ONE_OVER)
	if fn == "tan":
		out.wrongs += bad(90.0 - deg, R_OTHER_ACUTE)
	out.generic = gens([90.0 - deg, deg / 2.0, deg + 10.0, deg * 1.5])
	var ratio := "%s ÷ %s" % [D(s.a), D(s.b)]
	var third := W(o if fn == "cos" else (ad if fn == "sin" else sqrt(a * a + b * b)))
	var pyth: String
	var again: String
	match fn:
		"sin":
			pyth = "The third side is √(%s² − %s²) = %s" % [D(s.b), D(s.a), third]
			again = "tan⁻¹(%s ÷ %s) = %s°" % [D(s.a), third, W(rad_to_deg(atan(a / back(third))))]
		"cos":
			pyth = "The third side is √(%s² − %s²) = %s" % [D(s.b), D(s.a), third]
			again = "tan⁻¹(%s ÷ %s) = %s°" % [third, D(s.a), W(rad_to_deg(atan(back(third) / a)))]
		_:
			pyth = "The hypotenuse is √(%s² + %s²) = %s" % [D(s.a), D(s.b), third]
			again = "sin⁻¹(%s ÷ %s) = %s°" % [D(s.a), third, W(rad_to_deg(asin(a / back(third))))]
	out.methods = {
		"inverse-ratio": method(["The sides you know give %s θ = %s, which is %s." % [fn, ratio_words(fn), ratio], "%s(%s) = %s°" % [inv, ratio, W(deg)], say(ans)], ans.values),
		"pythagoras-then-other-ratio": method([pyth, "Now any ratio will do, so use another one.", again, say(ans)], ans.values)}
	return out


func u_angle_special(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var deg: int = s.e.n
	var fn: String = s.fn
	var t := Q.new(deg, 180)
	var k: int = s.k
	var unit_opp: Array = TrigKit.of("sin", t)
	var unit_adj: Array = TrigKit.of("cos", t)
	# Scale the sides so that the two given are simple: over 2 (or √2) and times k.
	var scale: Array = TrigKit.V(2 * k) if deg != 45 else TrigKit.times(TrigKit.root(2), k)
	var o_v: Array = TrigKit.mul(unit_opp, scale)
	var a_v: Array = TrigKit.mul(unit_adj, scale)
	var pair := ratio_of(fn, o_v, a_v, scale)
	var top: String = TrigKit.text(pair[0])
	var bot: String = TrigKit.text(pair[1])
	var names := ratio_of(fn, opp(s), adj(s), hyp(s))
	var ans := whole("θ = ", deg, "%d°" % deg)
	var lines := triangle_lines(s, "%s = %s m and %s = %s m." % [names[0], top, names[1], bot])
	var o := TrigKit.fl(o_v)
	var a := TrigKit.fl(a_v)
	var labels := {opp(s): "", adj(s): "", hyp(s): ""}
	labels[names[0]] = top + " m"
	labels[names[1]] = bot + " m"
	var g := tri_sketch(s, o, a, labels[opp(s)], labels[adj(s)], labels[hyp(s)], "θ")
	var out := frame(rep, lines, "Find the size of θ.", ans, g)
	var mirror := 90 - deg
	out.wrongs = [whole_wrong(ans, mirror, R_OTHER_ACUTE, false)] if fn == "tan" and deg != 45 else []
	out.generic = [whole_wrong(ans, mirror, "", false).values, whole_wrong(ans, 30, "", false).values, whole_wrong(ans, 45, "", false).values, whole_wrong(ans, 60, "", false).values, whole_wrong(ans, 90, "", false).values]
	var value := TrigKit.text(TrigKit.of(fn, t))
	out.methods = {
		"recognise-special": method(["%s θ = %s, which is %s ÷ %s." % [fn, ratio_words(fn), top, bot], "That simplifies to %s, which is %s %d° in the special triangles." % [value, fn, deg], say(ans)], ans.values),
		"inverse-ratio": method(["%s θ = %s ÷ %s, which simplifies to %s." % [fn, top, bot, value], "θ is %s⁻¹(%s), an exact angle." % [fn, value], say(ans)], ans.values)}
	return out


# ── Gradients ────────────────────────────────────────────────

func u_gradient_from_angle(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t := rad(deg_of(s))
	var v := tan(t)
	var ans := ans_of("gradient = ", v)
	var thing: String = RT_SLOPES[s.ctx]
	var g := ground_sketch(s, v, 1.0, "", "", "", D(s.e) + "°")
	var out := frame(rep, ["A straight %s %s rises at an angle of %s° above the horizontal." % [thing, hyp(s), D(s.e)]], sf3("Find the gradient of the %s." % thing), ans, g)
	out.wrongs = bad(sin(t), R_GRAD_SIN) + bad(1.0 / v, R_GRAD_FLIP)
	out.generic = gens([cos(t), deg_of(s) / 90.0, deg_of(s) / 100.0, v * 2.0, v + 0.5])
	out.methods = {"gradient-tan": method(["Gradient is the rise ÷ the run.",
		"In a right-angled triangle under the slope, the rise is opposite the angle and the run is adjacent to it, so gradient = tan θ.",
		"tan %s° = %s" % [D(s.e), W(v)], say(ans)], ans.values)}
	return out


static func grad(s: Dictionary) -> String:
	return "%d/%d" % [s.p, s.q]


static func grad_v(s: Dictionary) -> float:
	return float(s.p) / float(s.q)


func u_angle_from_gradient(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r := grad_v(s)
	var deg := rad_to_deg(atan(r))
	var ans := ans_of("angle = ", deg, "°")
	var thing: String = RT_SLOPES[s.ctx]
	var pts := {}
	pts[t_of(s)] = [0.0, 0.0]
	pts[r_of(s)] = [float(s.q), 0.0]
	pts[o_of(s)] = [float(s.q), float(s.p)]
	var g := sketch(pts, [side(t_of(s), o_of(s), "gradient " + grad(s)), side(t_of(s), r_of(s), "", true), side(r_of(s), o_of(s), "", true)],
		[arc(t_of(s), r_of(s), o_of(s), "?")], [], {"right": [r_of(s)]})
	var out := frame(rep, ["A straight %s %s has a gradient of %s." % [thing, hyp(s), grad(s)]], sf3("Find the angle between the %s and the horizontal." % thing), ans, g)
	out.wrongs = (bad(rad_to_deg(asin(r)), R_GRAD_ARCSIN) if r < 1.0 else []) + bad(90.0 - deg, R_OTHER_ACUTE) + bad(tan(rad(r)), R_NO_INVERSE)
	out.generic = gens([rad_to_deg(acos(r)) if r < 1.0 else 0.0, deg + 10.0, deg / 2.0, deg * 1.5])
	out.methods = {"gradient-inverse-tan": method(["Gradient is rise ÷ run, which is tan θ, so tan θ = %s." % grad(s), "θ = tan⁻¹(%s) = %s°" % [grad(s), W(deg)], say(ans)], ans.values)}
	return out


## A frame symmetrical about the vertical through its top A: BA slopes up to A.
func u_angle_with_vertical(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r := grad_v(s)
	var rise := rad_to_deg(atan(r))
	var deg := 90.0 - rise
	var ans := ans_of("angle BAM = ", deg, "°")
	var thing: String = RT_GANTRY[s.ctx]
	var lines := ["The cross-section of a %s is symmetrical about the vertical line through its top A." % thing,
		"The sloping edge BA has a gradient of %s. M is on the vertical line through A, level with B." % grad(s)]
	var pts := {"A": [0.0, float(s.p)], "M": [0.0, 0.0], "B": [-float(s.q), 0.0], "_C": [float(s.q), 0.0]}
	var g := sketch(pts, [side("B", "A", "gradient " + grad(s)), side("A", "M", "", true), side("B", "M", "", true), side("A", "_C"), side("M", "_C", "", true)],
		[arc("A", "B", "M", "?")], [], {"right": ["M"]})
	var out := frame(rep, lines, sf3("Find the size of angle BAM."), ans, g)
	out.wrongs = bad(rise, R_HORIZONTAL) + bad(2.0 * deg, R_APEX)
	out.generic = gens([rise + 10.0, deg + 10.0, deg / 2.0, deg * 1.5])
	out.methods = {
		"gradient-inverse-tan": method(["Gradient is tan of the angle with the horizontal, so that angle is tan⁻¹(%s) = %s°" % [grad(s), W(rise)],
			"Triangle BAM has a right angle at M, so angle BAM = 90° − %s° = %s°" % [W(rise), W(90.0 - back(W(rise)))], say(ans)], ans.values),
		"inverse-ratio": method(["A gradient of %s rises %d for each %d across, so in triangle BAM take AM = %d and BM = %d." % [grad(s), s.p, s.q, s.p, s.q],
			"BM is opposite angle BAM and AM is adjacent to it: tan(angle BAM) = %d ÷ %d" % [s.q, s.p], "tan⁻¹(%d ÷ %d) = %s°" % [s.q, s.p, W(deg)], say(ans)], ans.values)}
	return out


## The beam: U and V on the vertical at the top, P and Q at the low end, with M on the lower edge
## QV and N its mirror image, level with M. Angles at P and Q in the beam's end are right angles.
static func beam_lines(s: Dictionary) -> Array:
	return ["A %s is made of two sloping steel beams, symmetrical about the vertical line through U and V." % RT_GANTRY[s.ctx],
		"The top edge PU and the lower edge QV of the left beam both have a gradient of %s, and its end PQ is at right angles to them." % grad(s),
		"PQ = %s. M and N are level points on the lower edges, with MN = %s and QM = %s." % [m(s.t), m(s.span), m(s.over)]]


static func beam_sketch(s: Dictionary, asked: String) -> Dictionary:
	var al := atan(grad_v(s))
	var half: float = s.span.to_float() / 2.0
	# Drawn thicker and longer than life, so that the labels at the low end have room.
	var along: float = half / cos(al) + s.span.to_float() * 0.18
	var t: float = s.span.to_float() * 0.12
	var c := cos(al)
	var sn_a := sin(al)
	var q_pt := [-along * c, -along * sn_a]
	var p_pt := [q_pt[0] - t * sn_a, q_pt[1] + t * c]
	var pts := {"V": [0.0, 0.0], "U": [0.0, t / c], "Q": q_pt, "P": p_pt, "M": [-half, -half * tan(al)], "N": [half, -half * tan(al)],
		"_Q": [along * c, q_pt[1]], "_P": [-p_pt[0], p_pt[1]]}
	# The thickness is written on the free end, the mirror image of PQ: its own end is full of letters.
	var lines := [side("P", "Q"), side("Q", "V", "?" if asked == "QV" else ""), side("Q", "M", m(s.over)), side("P", "U", "?" if asked == "PU" else ""), side("U", "V"), side("U", "_P"), side("V", "_Q"), side("_P", "_Q", m(s.t)), side("M", "N", m(s.span), true)]
	return sketch(pts, lines, [], [], {"right": ["Q", "P"], "note": "not to scale"})


func u_edge_from_span(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r := grad_v(s)
	var al := atan(r)
	var half: float = s.span.to_float() / 2.0
	var over: float = s.over.to_float()
	var v := half / cos(al) + over
	var ans := ans_of("QV = ", v, " m")
	var out := frame(rep, beam_lines(s), sf3("Find QV, the length of the lower edge."), ans, beam_sketch(s, "QV"))
	out.wrongs = bad(2.0 * half / cos(al) + over, R_WHOLE_SPAN) + bad(half / cos(al), R_NO_OVERHANG) + bad(half / sin(al) + over, R_WRONG_ANGLE)
	out.generic = gens([half * cos(al) + over, half + over, half / tan(al) + over, v + 2.0])
	var aw := W(rad_to_deg(al))
	var mv := W(half / cos(rad(back(aw))))
	out.methods = {"choose-ratio-rearrange": method(["The angle of the edge to the horizontal is tan⁻¹(%s) = %s°" % [grad(s), aw],
		"V is on the line of symmetry, so it is above the middle of MN, %s m along from M." % D(s.span.div(2)),
		"That is the adjacent side, and MV is the hypotenuse: MV = %s ÷ cos %s° = %s" % [D(s.span.div(2)), aw, mv],
		"Add QM: QV = %s + %s = %s" % [mv, D(s.over), W(back(mv) + over)], say(ans)], ans.values)}
	return out


func u_upper_edge(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r := grad_v(s)
	var al := atan(r)
	var half: float = s.span.to_float() / 2.0
	var over: float = s.over.to_float()
	var t: float = s.t.to_float()
	var lower := half / cos(al) + over
	var v := lower + t * r
	var ans := ans_of("PU = ", v, " m")
	var out := frame(rep, beam_lines(s), sf3("Find PU, the length of the top edge."), ans, beam_sketch(s, "PU"))
	out.wrongs = bad(lower, R_NO_EXTRA) + bad(lower + t, R_EXTRA_T) + bad(lower + t / r, R_WRONG_ANGLE)
	out.generic = gens([half / cos(al), lower - t * r, v + 2.0, v * 1.2])
	var lw := W(lower)
	var ew := W(t * r)
	out.methods = {"choose-ratio-rearrange": method(["The lower edge is half of MN ÷ the cosine of its angle, plus QM: %s ÷ cos(tan⁻¹(%s)) + %s = %s" % [D(s.span.div(2)), grad(s), D(s.over), lw],
		"Draw a line from V at right angles to PU. It is %s long and meets PU at W, so PW = QV." % m(s.t),
		"VW is at right angles to the edge and VU to the horizontal, so angle UVW equals the angle of the edge to the horizontal. Its tan is the gradient, and UW is opposite it: UW = %s × %s = %s" % [D(s.t), grad(s), ew],
		"PU = %s + %s = %s" % [lw, ew, W(back(lw) + back(ew))], say(ans)], ans.values)}
	return out


# ── Elevation and depression ─────────────────────────────────

func u_height_from_angle(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.x.to_float()
	var t := elev(s)
	var h := x * tan(t)
	var ans := ans_of("height = ", h, " m")
	var lines := ["From P on level ground, %s from the foot F of a %s, the angle of elevation of its top T is %s." % [m(s.x), tall(s), angle_words(s)]]
	var out := frame(rep, lines, sf3("Find the height of T above the ground."), ans, side_view(h, x, false, "?", m(s.x), _angle_label(s), {"right": ["F"]}))
	var slip := x * (tan(rad(s.e.to_float())) if s.form == "rad" else tan(s.e.to_float()))
	out.wrongs = bad(slip, R_MODE)
	out.generic = gens([x * sin(t), x * cos(t), x / tan(t), h + 2.0, h * 1.5])
	out.methods = {"right-triangle": method(["The angle sits at P, between the ground and the line of sight, so tan θ = height ÷ distance.", "height = %s × %s = %s" % [D(s.x), tan_text(s), W(h)], say(ans)], ans.values)}
	return out


func u_elevation_after_walk(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var d: float = s.x.to_float()
	var w: float = s.w.to_float()
	var t := elev(s)
	var h := d * tan(t)
	var left := d - w
	var a := atan(h / left)
	var is_rad: bool = s.form == "rad"
	var tail := " radians" if is_rad else "°"
	var val := a if is_rad else rad_to_deg(a)
	var ans := ans_of("angle = ", val, tail)
	var lines := ["From A on level ground, %s from the foot F of a %s, the angle of elevation of its top T is %s." % [m(s.x), tall(s), angle_words(s)],
		"A scout walks %s straight towards F, to a point B." % m(s.w)]
	var pts := {"T": [0.0, h], "F": [0.0, 0.0], "B": [left, 0.0], "A": [d, 0.0], "_a": [d, -h * 0.16], "_f": [0.0, -h * 0.16]}
	var g := sketch(pts, [side("F", "T"), side("F", "B"), side("B", "A", m(s.w)), side("A", "T", "", true), side("B", "T", "", true), side("_a", "_f", m(s.x), true)],
		[arc("A", "F", "T", _angle_label(s)), arc("B", "F", "T", "?")], [], {"right": ["F"]})
	var out := frame(rep, lines, sf3("Find the angle of elevation of T from B%s." % (", in radians" if is_rad else "")), ans, g)
	var conv := func(x: float) -> float: return x if is_rad else rad_to_deg(x)
	out.wrongs = bad(conv.call(atan(h / w)), R_WALKED)
	out.generic = gens([conv.call(t) * d / left, conv.call(t) + conv.call(atan(w / d)), conv.call(atan(left / h)), val * 1.5, val / 2.0])
	var hw := W(h)
	var unit := " radians" if is_rad else "°"
	var again: float = atan(back(hw) / left)
	out.methods = {"inverse-ratio": method(["Height first: %s × %s = %s" % [D(s.x), tan_text(s), hw],
		"From B the distance to F is %s − %s = %s m." % [D(s.x), D(s.w), D(s.x.sub(s.w))],
		"The sides you know give tan θ = opposite ÷ adjacent, which is %s ÷ %s." % [hw, D(s.x.sub(s.w))],
		"The angle from B is tan⁻¹(%s ÷ %s), which is %s%s" % [hw, D(s.x.sub(s.w)), W(conv.call(again)), unit], say(ans)], ans.values)}
	return out


func u_equal_elevations(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var l: float = s.l.to_float()
	var x: float = s.x.to_float()
	var deg: int = (180 - int(s.phi)) / 2
	var t := rad(deg)
	var h := l * sin(t)
	var ans := ans_of("height = ", h, " m")
	var lines := ["Two %ss stand on level ground. Their tops are A and B, and P is on the ground directly between them." % tall(s),
		"From P, the angle of elevation is the same, θ, to both A and B.",
		"PA = %s, PB = %s and angle APB = %d°." % [m(s.l), m(s.x), s.phi]]
	var pts := {"P": [0.0, 0.0], "A": [-l * cos(t), h], "F": [-l * cos(t), 0.0], "B": [x * cos(t), x * sin(t)], "G": [x * cos(t), 0.0]}
	var g := sketch(pts, [side("F", "A", "?"), side("G", "B"), side("F", "P"), side("P", "G"), side("P", "A", m(s.l), true), side("P", "B", m(s.x), true)],
		[arc("P", "A", "B", "%d°" % s.phi), arc("P", "F", "A", "θ"), arc("P", "G", "B", "θ")], [], {"right": ["F", "G"]})
	var out := frame(rep, lines, sf3("Find the height of the taller %s." % tall(s)), ans, g)
	out.wrongs = bad(l * sin(rad(float(s.phi) / 2.0)), R_HALF_PHI) + bad(x * sin(t), R_OTHER_TOWER)
	out.generic = gens([l * cos(t), l * tan(t), l, h + 2.0, h * 1.2])
	out.methods = {"choose-ratio-rearrange": method(["The angles at P on the straight ground add to 180°: θ + %d° + θ = 180°, so θ = %d°." % [s.phi, deg],
		"In the taller triangle, PA is the hypotenuse and the height is opposite θ, so use sin θ = opposite ÷ hypotenuse.",
		"The side you want is on top, so multiply: height = %s × sin %d° = %s" % [D(s.l), deg, W(h)], say(ans)], ans.values)}
	return out


func u_cone_from_eye_level(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var hh: float = s.h.to_float()
	var eye: float = s.eye.to_float()
	var d: float = s.x.to_float()
	var t := rad(deg_of(s))
	var rise := hh - eye
	var across := rise / tan(t)
	var v := across - d
	var ans := ans_of("radius = ", v, " m")
	var thing: String = RT_HEAPS[s.ctx]
	var lines := ["A %s has the shape of a right cone, %s high, with its top at T." % [thing, m(s.h)],
		"A guard stands on level ground at Q, %s from the edge B of its base, with her eyes E %s above the ground." % [m(s.x), m(s.eye)],
		"The angle of elevation of T from E is %s°." % D(s.e)]
	# The guard is drawn taller and further out than life, with the angle kept, so her labels fit.
	var eye_d := hh * 0.14
	var out_d := (hh - eye_d) / tan(t)
	var edge := out_d * 0.72
	var pts := {"T": [0.0, hh], "C": [0.0, 0.0], "B": [edge, 0.0], "_B": [-edge, 0.0], "Q": [out_d, 0.0], "E": [out_d, eye_d], "_L": [0.0, eye_d]}
	var g := sketch(pts, [side("C", "T", m(s.h), true), side("_B", "T"), side("B", "T"), side("C", "B", "?"), side("_B", "C"), side("B", "Q", m(s.x)), side("Q", "E", m(s.eye)), side("E", "_L", "", true), side("E", "T", "", true)],
		[arc("E", "_L", "T", D(s.e) + "°")], [], {"note": "not to scale"})
	var out := frame(rep, lines, sf3("Find the radius of the base of the %s." % thing), ans, g)
	out.wrongs = bad(hh / tan(t) - d, R_NO_EYE) + bad(across, R_CENTRE)
	out.generic = gens([rise * tan(t) - d, rise / sin(t) - d, rise / tan(t) + d, v + 2.0, v * 1.5])
	var rw := W(across)
	out.methods = {"right-triangle": method(["From eye level up to T is %s − %s = %s m." % [D(s.h), D(s.eye), D(s.h.sub(s.eye))],
		"The horizontal from E to the axis of the cone is %s ÷ tan %s° = %s" % [D(s.h.sub(s.eye)), D(s.e), rw],
		"That reaches from the axis all the way out to the guard, so take off the %s from the edge to Q." % m(s.x),
		"radius = %s − %s = %s" % [rw, D(s.x), W(back(rw) - d)], say(ans)], ans.values)}
	return out


## The side view for depression: the horizontal TH is drawn at the top.
static func drop_sketch(h: float, x: float, h_label: String, sight: String, label: String) -> Dictionary:
	var pts := {"T": [0.0, h], "F": [0.0, 0.0], "P": [x, 0.0], "H": [x * 0.8, h]}
	return sketch(pts, [side("F", "T", h_label), side("F", "P"), side("T", "P", sight, true), side("T", "H", "", true)], [arc("T", "H", "P", label)], [], {"right": ["F"]})


func u_depression_sight_line(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h: float = s.h.to_float()
	var t := rad(deg_of(s))
	var v := h / sin(t)
	var ans := ans_of("TP = ", v, " m")
	var lines := ["The top T of a %s is %s above level ground. TH is horizontal." % [tall(s), m(s.h)], "A lookout at T sees %s at P on the ground. The angle of depression of P from T is %s°." % [SEEN[s.ctx], D(s.e)]]
	var out := frame(rep, lines, sf3("Find TP, the distance along the line of sight."), ans, drop_sketch(h, h / tan(t), m(s.h), "?", D(s.e) + "°"))
	out.wrongs = bad(h / cos(t), R_AT_TOP)
	out.generic = gens([h * sin(t), h / tan(t), h * tan(t), v + 2.0, v * 1.5])
	var inside_t := "The horizontals at T and F are parallel, so the angle at P inside the triangle is also %s°." % D(s.e)
	out.methods = {
		"choose-ratio-rearrange": method(["The angle lies between TH and TP, so the angle at T inside the triangle is 90° − %s° = %s°." % [D(s.e), D(90 - s.e.n)],
			"The height is adjacent to it and TP is the hypotenuse, so cos %s° = %s ÷ TP: the side you want is underneath." % [D(90 - s.e.n), D(s.h)],
			"%s ÷ cos %s° = %s" % [D(s.h), D(90 - s.e.n), W(v)], say(ans)], ans.values),
		"alternate-angles": method([inside_t, "The height is opposite that angle, and TP is the hypotenuse, so sin %s° = %s ÷ TP." % [D(s.e), D(s.h)], "%s ÷ sin %s° = %s" % [D(s.h), D(s.e), W(v)], say(ans)], ans.values)}
	return out


func u_depression_from_sight_line(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h: float = s.h.to_float()
	var l: float = s.l.to_float()
	var deg := rad_to_deg(asin(h / l))
	var ans := ans_of("angle = ", deg, "°")
	var x := sqrt(l * l - h * h)
	var lines := ["The top T of a %s is %s above level ground. TH is horizontal." % [tall(s), m(s.h)], "A lookout at T sees %s at P on the ground, and TP = %s." % [SEEN[s.ctx], m(s.l)]]
	var out := frame(rep, lines, sf3("Find the angle of depression of P from T."), ans, drop_sketch(h, x, m(s.h), m(s.l), "?"))
	out.wrongs = bad(90.0 - deg, R_FROM_VERTICAL)
	out.generic = gens([rad_to_deg(atan(h / l)), deg + 10.0, deg / 2.0, deg * 1.5])
	var top := W(rad_to_deg(acos(h / l)))
	out.methods = {
		"inverse-ratio": method(["At T, inside the triangle, the height is adjacent and TP is the hypotenuse: angle FTP = cos⁻¹(%s ÷ %s) = %s°" % [D(s.h), D(s.l), top],
			"That angle is measured from the vertical. The horizontal TH is at right angles to TF, so take it from 90°.", "90° − %s° = %s°" % [top, W(90.0 - back(top))], say(ans)], ans.values),
		"alternate-angles": method(["The horizontals at T and F are parallel, so the angle of depression equals the angle at P inside the triangle.", "sin(angle) = %s ÷ %s" % [D(s.h), D(s.l)], "sin⁻¹(%s ÷ %s) = %s°" % [D(s.h), D(s.l), W(deg)], say(ans)], ans.values)}
	return out


func u_depression_two_points(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h: float = s.h.to_float()
	var near := rad(s.e.to_float())
	var far := rad(s.e2.to_float())
	var x1 := h / tan(near)
	var x2 := h / tan(far)
	var v := x2 - x1
	var ans := ans_of("PQ = ", v, " m")
	var lines := ["The top T of a %s is %s above level ground. TH is horizontal." % [tall(s), m(s.h)],
		"Two carts P and Q are on the ground on the same side of the %s, in a straight line with its foot F." % tall(s),
		"From T, the angle of depression of P is %s° and of Q is %s°." % [D(s.e), D(s.e2)]]
	var pts := {"T": [0.0, h], "F": [0.0, 0.0], "P": [x1, 0.0], "Q": [x2, 0.0], "H": [x2 * 0.9, h]}
	var g := sketch(pts, [side("F", "T", m(s.h)), side("F", "P"), side("P", "Q", "?"), side("T", "P", "", true), side("T", "Q", "", true), side("T", "H", "", true)],
		[arc("T", "H", "Q", D(s.e2) + "°"), arc("T", "H", "P", D(s.e) + "°")], [], {"right": ["F"]})
	var out := frame(rep, lines, sf3("Find PQ, the distance between the carts."), ans, g)
	out.wrongs = bad(absf(h * tan(near) - h * tan(far)), R_AT_TOP) + bad(x1 + x2, R_ADD_DISTANCES)
	out.generic = gens([h * (tan(near) + tan(far)), h / sin(far) - h / sin(near), x2, v + 2.0, v * 1.5])
	var aw := W(x1)
	var bw := W(x2)
	out.methods = {
		"choose-ratio-rearrange": method(["Depression is measured from the horizontal, so the angles at T inside the triangles are 90° − %s° = %d° and 90° − %s° = %d°." % [D(s.e), 90 - s.e.n, D(s.e2), 90 - s.e2.n],
			"FP is opposite the first and the height is adjacent, so the side you want is on top: FP = %s × tan %d° = %s" % [D(s.h), 90 - s.e.n, W(h * tan(rad(90 - s.e.n)))],
			"FQ = %s × tan %d° = %s" % [D(s.h), 90 - s.e2.n, W(h * tan(rad(90 - s.e2.n)))], "PQ = FQ − FP = %s − %s = %s" % [bw, aw, W(back(bw) - back(aw))], say(ans)], ans.values),
		"alternate-angles": method(["The horizontals are parallel, so the angles at P and Q inside the triangles equal the angles of depression.",
			"FP = %s ÷ tan %s° = %s" % [D(s.h), D(s.e), aw], "FQ = %s ÷ tan %s° = %s" % [D(s.h), D(s.e2), bw], "PQ = %s − %s = %s" % [bw, aw, W(back(bw) - back(aw))], say(ans)], ans.values)}
	return out


func u_name_the_angle(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var dep: bool = s.mode == "depression"
	var right := "angle HTP" if dep else "angle FPT"
	var options := ["angle FPT", "angle FTP", "angle HTF", "angle HTP"]
	var ans := DifferentiationViews.form(right, [{"pick": "v", "options": options}], {"v": right})
	var lines := ["A lookout is at the top T of a %s, which stands on level ground with its foot at F." % tall(s),
		"%s is at P on the ground. TH is horizontal." % (SEEN[s.ctx].left(1).to_upper() + SEEN[s.ctx].substr(1))]
	var x := 1.0 / tan(rad(deg_of(s)))
	var pts := {"T": [0.0, 1.0], "F": [0.0, 0.0], "P": [x, 0.0], "H": [x, 1.0]}
	var g := sketch(pts, [side("F", "T"), side("F", "P"), side("T", "P", "", true), side("T", "H", "", true)], [], [], {"right": ["F"]})
	var asked := "Which angle is the angle of depression of P from T?" if dep else "Which angle is the angle of elevation of T from P?"
	var out := frame(rep, lines, asked, ans, g)
	var pick := func(t: String, ref: String = "") -> Dictionary:
		return DifferentiationViews.alt(t, ref, {"v": t})
	out.wrongs = [pick.call("angle FPT" if dep else "angle HTP", R_AT_GROUND)]
	if dep:
		out.wrongs.append(pick.call("angle FTP", R_FROM_VERTICAL))
	out.generic = [pick.call("angle FTP").values, pick.call("angle HTF").values]
	var horizontal := "An angle of depression is measured down from the horizontal at the eye, and the eye is at T." if dep else "An angle of elevation is measured up from the horizontal at the eye, and the eye is at P."
	var between := "The horizontal there is TH, and the line of sight is TP." if dep else "The horizontal there is the ground PF, and the line of sight is PT."
	out.methods = {"angle-from-horizontal": method([horizontal, between, "So it is %s." % right], ans.values)}
	return out
