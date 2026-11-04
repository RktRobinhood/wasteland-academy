class_name ArcSectorViews
extends ExtensionViews
## The views on the `arc-sector` situation: one builder per unknown of t3-arc-sector (FAL-726).
## Paper 1 answers are exact, a + bπ kept as [a, b] and written as a `form` answer with its slots
## in the shape of the value (a wrong option in another shape can be picked but not typed).
## Paper 2 answers are numbers to 3 s.f. with the rounding trap.
##
## Representations: "equation" (r = 6 cm, θ = 1.2 radians), "words" (a story) and "diagram" (a
## sector drawn to its real angle by PlotView's `sector`; a plate is PlotView's `plate`).

const SKILL := "SL3.4."
const R_FACTOR := SKILL + "convert#0"
const R_ONE_DEGREE := SKILL + "convert#1"
const R_DECIMAL := SKILL + "convert#2"
const R_ARC_DEG := SKILL + "arc-length#0"
const R_NO_RADII := SKILL + "arc-length#1"
const R_MINOR_ARC := SKILL + "arc-length#2"
const R_AREA_DEG := SKILL + "sector-area#0"
const R_THETA_SQ := SKILL + "sector-area#1"
const R_MINOR := SKILL + "sector-area#2"
const R_SIN_DEG := SKILL + "segment-shaded#0"

## The stories: what makes the sector, what it does, and its unit.
const CONTEXTS := [
	{"thing": "A searchlight on the camp wall", "does": "lights a sector of the yard", "gap": "lights the yard all round", "unit": "m"},
	{"thing": "A sprinkler at the bean farm", "does": "waters a sector of the field", "gap": "waters the field all round", "unit": "m"},
	{"thing": "A wiper on a salvaged truck", "does": "clears a sector of the windscreen", "gap": "clears the glass all round", "unit": "cm"},
	{"thing": "A scanner on a hovering drone", "does": "sweeps a sector of the ground", "gap": "sweeps the ground all round", "unit": "m"},
	{"thing": "A radio mast on the ridge", "does": "reaches a sector of the flats", "gap": "reaches the flats all round", "unit": "km"},
	{"thing": "A turret at the depot gate", "does": "covers a sector of the road", "gap": "covers the ground all round", "unit": "m"},
]

const UNKNOWNS := ["deg-to-rad", "rad-to-deg", "arc-length", "perimeter", "theta-from-arc", "r-from-arc", "r-from-perimeter",
	"theta-from-perimeter", "major-arc", "r-in-terms-of-theta", "theta-from-bent-strip", "sector-area", "theta-from-area",
	"r-from-area", "major-sector", "area-from-arc", "perimeter-from-area", "major-from-perimeter", "cone-radius",
	"ring-inner-radius", "ring-perimeter", "segments-theta"]
const P2_ONLY := ["ring-inner-radius", "ring-perimeter", "segments-theta"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## The composite shapes are Paper 2, as in the bank. Counting in landmarks needs a landmark.
func papers(unknown: String, _rep: String, method_id: String) -> Array:
	if not has(unknown):
		return []
	if unknown in P2_ONLY:
		return [2]
	return [1] if method_id == "landmarks" else [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = ArcSectorSituation.export(s)
	return out


# ── Values: a + bπ ───────────────────────────────────────────

static func ab(a: Variant, b: Variant = 0) -> Array:
	return [Q.of(a), Q.of(b)]


static func fl(v: Array) -> float:
	return v[0].to_float() + v[1].to_float() * PI


static func scale(v: Array, k: Variant) -> Array:
	return [v[0].mul(k), v[1].mul(k)]


static func plus(v: Array, w: Array) -> Array:
	return [v[0].add(w[0]), v[1].add(w[1])]


static func less(v: Array, w: Array) -> Array:
	return [v[0].sub(w[0]), v[1].sub(w[1])]


## θ in radians as a + bπ.
static func theta(s: Dictionary) -> Array:
	match s.form:
		"pi":
			return ab(0, s.t)
		"deg":
			return ab(0, s.t.div(180))
	return ab(s.t, 0)


static func radians(s: Dictionary) -> float:
	return fl(theta(s))


## The reflex angle 2π − θ.
static func reflex(s: Dictionary) -> Array:
	return less(ab(0, 2), theta(s))


## An exact value: "12 + 3π", "9π − 4.5", "5π/6", "7.5".
static func exact(v: Array) -> String:
	if v[1].is_zero():
		return Fmt.dec(v[0])
	if v[0].is_zero():
		return Fmt.pi(v[1])
	if v[0].sign() < 0:
		return "%s − %s" % [Fmt.pi(v[1]), Fmt.dec(v[0].neg())]
	return "%s + %s" % [Fmt.dec(v[0]), Fmt.pi(v[1])]


## A value in the working: exact on Paper 1, to 5 figures on Paper 2.
static func W(s: Dictionary, v: Array) -> String:
	return exact(v) if s.paper == 1 else Fmt.sf(fl(v), 5)


## A value as the working shows it, so the next step works from what is on the page.
static func S(s: Dictionary, v: Array) -> Array:
	return v if s.paper == 1 else ab(Answer.parse_number(W(s, v)).q)


## That share of a circle's [0, b]: θ ÷ 2π of it. Exact on Paper 1, from the figure shown on Paper 2.
static func share(s: Dictionary, whole: Array) -> Array:
	if s.paper == 1:
		return scale(theta(s), whole[1].div(2))
	return ab(GdcKit.qf(fl(whole) * radians(s) / TAU))


## A value in the working, in brackets where it has two terms and is about to be multiplied.
static func Br(s: Dictionary, v: Array) -> String:
	return "(%s)" % W(s, v) if s.paper == 1 and shape(v) in ["+", "−"] else W(s, v)


## A value as it is given: exact on Paper 1, as drawn on Paper 2.
static func G(v: Array) -> String:
	return exact(v)


static func R(s: Dictionary) -> String:
	return Fmt.dec(s.r) if s.paper == 1 or s.r.d <= 10 else Fmt.sf(s.r, 5)


## The angle as the question writes it, without its unit where it is in radians.
static func angle_text(s: Dictionary) -> String:
	match s.form:
		"pi":
			return Fmt.pi(s.t)
		"deg":
			return Fmt.dec(s.t) + "°"
	return Fmt.dec(s.t)


static func angle_words(s: Dictionary) -> String:
	return angle_text(s) if s.form == "deg" else angle_text(s) + " radians"


static func unit(s: Dictionary) -> String:
	return " " + (CONTEXTS[s.ctx].unit if s.rep == "words" else "cm")


static func unit2(s: Dictionary) -> String:
	return unit(s) + "²"


# ── Answers ──────────────────────────────────────────────────

static func shape(v: Array) -> String:
	if v[1].is_zero():
		return "n"
	if v[0].is_zero():
		return "p"
	return "+" if v[0].sign() > 0 else "−"


static func slots_of(v: Array) -> Dictionary:
	match shape(v):
		"n":
			return {"a": v[0]}
		"p":
			return {"b": v[1]}
		"+":
			return {"a": v[0], "b": v[1]}
	return {"c": v[0].neg(), "b": v[1]}


## The answer: 3 s.f. on Paper 2. On Paper 1 its slots follow its shape.
static func ans_of(s: Dictionary, label: String, v: Array, tail: String = "") -> Dictionary:
	if s.paper == 2:
		var ans := Answer.make("number", {"v": GdcKit.qf(fl(v))}, {}, label, tail)
		ans.show = "sf"
		return ans
	var parts: Array
	match shape(v):
		"n":
			parts = [label, {"slot": "a"}, tail]
		"p":
			parts = [label, {"slot": "b"}, "π" + tail]
		"+":
			parts = [label, {"slot": "a"}, " + ", {"slot": "b"}, "π" + tail]
		_:
			parts = [label, {"slot": "b"}, "π − ", {"slot": "c"}, tail]
	var out := DifferentiationViews.form(label + exact(v) + tail, parts, slots_of(v))
	out.head = label
	out.tail = tail
	out.shape = shape(v)
	return out


## A wrong option in the answer's own terms: positive, or none.
static func like(ans: Dictionary, s: Dictionary, v: Array, ref: String = "") -> Array:
	if fl(v) <= 0.0:
		return []
	if s.paper == 2:
		return [wrong({"v": GdcKit.qf(fl(v))}, ref)]
	var text: String = ans.head + exact(v) + ans.tail
	return [DifferentiationViews.alt(text, ref, slots_of(v) if shape(v) == ans.shape else {})]


## A wrong option on Paper 1 written out, as a decimal or a form the value can't take.
static func said(text: String, ref: String) -> Array:
	return [DifferentiationViews.alt(text, ref)]


## Wrong options with no misconception behind them, for `generic`.
static func others(ans: Dictionary, s: Dictionary, vs: Array) -> Array:
	var out: Array = []
	for v in vs:
		for w in like(ans, s, v):
			out.append(w.values)
	return out


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## What to give, after the question: 3 s.f. on Paper 2, and π left in on Paper 1.
static func finish(s: Dictionary, asked: String, ans: Dictionary) -> String:
	if s.paper == 2:
		return asked + " Give your answer to 3 significant figures."
	return asked + (" Give your answer in terms of π." if ans.shape != "n" else "")


# ── What the student is shown ────────────────────────────────

## The sector as a spec for PlotView. `over` overrides or adds labels.
static func figure(s: Dictionary, shade: String, over: Dictionary = {}) -> Dictionary:
	var out := {"kind": "sector", "theta": radians(s), "shade": shade, "names": ["O", "A", "B"], "r_label": "", "angle_label": "", "arc_label": ""}
	if shade == "major":
		out.circle = true
	out.merge(over, true)
	return out


## The givens among r, t, l, a and p, as this representation shows them: lines, and a figure.
## An asked r or θ is marked on the figure.
static func show(rep: String, s: Dictionary, keys: Array, shade: String = "minor") -> Dictionary:
	var rt := R(s) + unit(s)
	var c: Dictionary = CONTEXTS[s.ctx]
	var more: Array = []
	if rep == "words":
		var head: String = c.thing
		var first: String
		if "r" in keys:
			first = "%s has a reach of %s and %s" % [head, rt, c.does]
		else:
			first = "%s %s" % [head, c.does]
		if "t" in keys:
			first += ", with an angle of %s at the centre" % angle_words(s)
		more = [first + "."]
		if "l" in keys:
			more.append("The curved edge of the sector is %s long." % (G(s.l) + unit(s)))
		if "a" in keys:
			more.append("The area of the sector is %s." % (G(s.area) + unit2(s)))
		if "p" in keys:
			more.append("The perimeter of the sector is %s." % (G(s.per) + unit(s)))
		return {"lines": more, "graph": null}
	if rep == "equation":
		more = ["Sector OAB has centre O."]
		if "r" in keys:
			more.append("r = " + rt)
		if "t" in keys:
			more.append("θ = " + angle_words(s))
		if "l" in keys:
			more.append("arc AB = " + G(s.l) + unit(s))
		if "a" in keys:
			more.append("area = " + G(s.area) + unit2(s))
		if "p" in keys:
			more.append("perimeter = " + G(s.per) + unit(s))
		return {"lines": more, "graph": null}
	more = ["The diagram shows sector OAB of a circle with centre O, shaded."]
	if not ("t" in keys and s.form == "deg"):
		more[0] += " Its angle is in radians."
	if "a" in keys:
		more.append("The area of the sector is %s." % (G(s.area) + unit2(s)))
	if "p" in keys:
		more.append("The perimeter of the sector is %s." % (G(s.per) + unit(s)))
	var g := figure(s, shade, {"r_label": rt if "r" in keys else "r", "angle_label": angle_text(s) if "t" in keys else "θ"})
	if "l" in keys:
		g.arc_label = G(s.l) + unit(s)
	return {"lines": more, "graph": g}


static func frame(rep: String, s: Dictionary, keys: Array, asked: String, ans: Dictionary) -> Dictionary:
	var v := show(rep, s, keys)
	return {"lines": v.lines, "graph": v.graph, "table": null, "answer": ans, "asked": finish(s, asked, ans)}


## "arc AB" or "the curved edge": what the question calls the arc.
static func arc_name(rep: String) -> String:
	return "the curved edge" if rep == "words" else "arc AB"


## The step that turns degrees to radians, where the angle is in degrees.
static func to_rad(s: Dictionary) -> Array:
	if s.form != "deg":
		return []
	return ["%s × π/180 = %s radians" % [angle_text(s), W(s, theta(s))]]


# ── Radians and degrees ──────────────────────────────────────

func u_deg_to_rad(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := theta(s)
	var ans := ans_of(s, "θ = ", v)
	var d: String = angle_text(s)
	var out := {"table": null, "answer": ans}
	if rep == "diagram":
		out.lines = ["The diagram shows sector OAB of a circle with centre O."]
		out.graph = figure(s, "minor", {"r_label": "", "angle_label": d})
		out.asked = finish(s, "Write angle AOB in radians.", ans)
	else:
		out.lines = ["θ = " + d]
		out.asked = finish(s, "Write θ in radians.", ans)
	var bad := Fmt.sf(s.t.to_float() * 180.0 / PI)
	var turn: Q = s.t.div(360)
	if s.paper == 1:
		out.wrongs = said("θ = " + bad, R_FACTOR) + said("θ = " + Fmt.sf(fl(v)), R_DECIMAL)
		out.generic = others(ans, s, [ab(0, s.t.div(90)), ab(0, s.t.div(360)), ab(0, turn.mul(4)), ab(0, v[1].add(Q.new(1, 6))), ab(0, v[1].add(Q.new(1, 4)))])
		var m: Dictionary = {"fraction-of-turn": method(["%s is %s/360 = %s of a turn." % [d, Fmt.dec(s.t), Fmt.num(turn)], "A full turn is 2π: %s × 2π = %s" % [Fmt.num(turn), Fmt.pi(v[1])], say(ans)], ans.values),
			"multiply-factor": method(["Multiply by π/180: %s × π/180 = %sπ/180" % [Fmt.dec(s.t), Fmt.dec(s.t)], "Cancel: %s" % Fmt.pi(v[1]), say(ans)], ans.values)}
		var base := 30 if int(s.t.n) % 30 == 0 else 45
		m["landmarks"] = method(["%d° = %s, and %s is %d lots of %d°." % [base, Fmt.pi(Q.new(base, 180)), d, int(s.t.n) / base, base], "%d × %s = %s" % [int(s.t.n) / base, Fmt.pi(Q.new(base, 180)), Fmt.pi(v[1])], say(ans)], ans.values)
		out.methods = m
		return out
	out.wrongs = [wrong({"v": GdcKit.qf(s.t.to_float() * 180.0 / PI)}, R_FACTOR)]
	out.generic = others(ans, s, [ab(0, s.t.div(90)), ab(0, s.t.div(360)), ab(GdcKit.qf(s.t.to_float() / 180.0)), ab(GdcKit.qf(s.t.to_float() / PI))])
	out.methods = {"multiply-factor": method(["Multiply by π/180: %s × π/180 = %s" % [d, W(s, v)], say(ans)], ans.values),
		"fraction-of-turn": method(["%s is %s/360 of a turn." % [d, Fmt.dec(s.t)], "A full turn is 2π: %s/360 × 2π = %s" % [Fmt.dec(s.t), W(s, v)], say(ans)], ans.values),
		"landmarks": method(["180° = π, so %s is %s/180 of π." % [d, Fmt.dec(s.t)], "%s/180 × π = %s" % [Fmt.dec(s.t), W(s, v)], say(ans)], ans.values)}
	return out


func u_rad_to_deg(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var deg: Q = s.t.mul(180) if s.paper == 1 else GdcKit.qf(s.t.to_float() * 180.0 / PI)
	var ans := ans_of(s, "θ = ", [deg, Q.new(0)], "°")
	var d := angle_text(s)
	var out := {"table": null, "answer": ans}
	if rep == "diagram":
		out.lines = ["The diagram shows sector OAB of a circle with centre O. Its angle is in radians."]
		out.graph = figure(s, "minor", {"angle_label": d})
		out.asked = finish(s, "Write angle AOB in degrees.", ans)
	else:
		out.lines = ["θ = %s radians" % d]
		out.asked = finish(s, "Write θ in degrees.", ans)
	var size := radians(s)
	var wrong_deg: Array = said("θ = %s°" % Fmt.sf(size), R_ONE_DEGREE) if s.paper == 1 else [wrong({"v": s.t}, R_ONE_DEGREE)]
	out.wrongs = wrong_deg
	out.generic = others(ans, s, [scale(ab(deg), Q.new(1, 2)), scale(ab(deg), 2), plus(ab(deg), ab(30)), plus(ab(deg), ab(60)), plus(ab(deg), ab(90)), ab(GdcKit.qf(size * 90.0 / PI * 3.0))])
	if s.paper == 1:
		var turn: Q = s.t.div(2)
		var dd := Fmt.dec(deg)
		var unit_d: Q = Q.new(180, s.t.d)
		out.methods = {"multiply-factor": method(["Multiply by 180/π: %s × 180/π = %s × 180" % [d, Fmt.num(s.t)], "= %s" % dd, say(ans)], ans.values),
			"fraction-of-turn": method(["%s is %s of a full turn of 2π." % [d, Fmt.num(turn)], "%s × 360° = %s°" % [Fmt.num(turn), dd], say(ans)], ans.values),
			"landmarks": method(["%s is %s°, and %s is %d lots of that." % [Fmt.pi(Q.new(1, s.t.d)), Fmt.dec(unit_d), d, s.t.n], "%d × %s° = %s°" % [s.t.n, Fmt.dec(unit_d), dd], say(ans)], ans.values)}
	else:
		out.methods = {"multiply-factor": method(["Multiply by 180/π: %s × 180/π = %s" % [d, Fmt.sf(deg, 5)], say(ans)], ans.values),
			"fraction-of-turn": method(["%s is %s/2π of a full turn." % [d, d], "%s/2π × 360° = %s°" % [d, Fmt.sf(deg, 5)], say(ans)], ans.values),
			"landmarks": method(["π is 180°, and %s is %s/π of that." % [d, d], "%s/π × 180° = %s°" % [d, Fmt.sf(deg, 5)], say(ans)], ans.values)}
	return out


# ── Arcs ─────────────────────────────────────────────────────

## The fraction of the circle as the working writes it: "150/360", "5π/6 ÷ 2π".
static func part(s: Dictionary) -> String:
	return "%s/360" % Fmt.dec(s.t) if s.form == "deg" else "%s ÷ 2π" % angle_text(s)


func u_arc_length(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var th := theta(s)
	var v := scale(th, s.r)
	var ans := ans_of(s, "l = ", v, unit(s))
	var out := frame(rep, s, ["r", "t"], "Find the length of %s." % arc_name(rep), ans)
	out.wrongs = like(ans, s, ab(s.r.mul(s.t)), R_ARC_DEG) if s.form == "deg" else []
	out.generic = others(ans, s, [scale(v, 2), scale(v, Q.new(1, 2)), scale(th, s.r.sq()), scale(th, s.r.sq().div(2)), plus(v, ab(s.r)), plus(v, ab(s.r.mul(2)))])
	var r := R(s)
	var turn := S(s, ab(0, s.r.mul(2)))
	out.methods = {"l-equals-r-theta": method(to_rad(s) + ["l = rθ = %s × %s = %s" % [r, W(s, th), W(s, scale(S(s, th), s.r))], say(ans)], ans.values),
		"fraction-of-circumference": method(["The arc is %s of the circumference." % part(s), "2π × %s = %s" % [r, W(s, turn)], "l = %s × %s = %s" % [_frac(s), W(s, turn), W(s, share(s, turn))], say(ans)], ans.values)}
	return out


## The fraction of the circle as one number or a fraction, for the working.
static func _frac(s: Dictionary) -> String:
	if s.form == "deg":
		return "(%s/360)" % Fmt.dec(s.t)
	if s.form == "pi":
		return "(%s/2)" % Fmt.num(s.t)
	return "(%s ÷ 2π)" % Fmt.dec(s.t)


func u_perimeter(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var th := theta(s)
	var arc := scale(th, s.r)
	var v := plus(arc, ab(s.r.mul(2)))
	var ans := ans_of(s, "P = ", v, unit(s))
	var out := frame(rep, s, ["r", "t"], "Find the perimeter of the sector.", ans)
	out.wrongs = like(ans, s, arc, R_NO_RADII)
	if s.form == "deg":
		out.wrongs += like(ans, s, ab(s.r.mul(s.t).add(s.r.mul(2))), R_ARC_DEG)
	out.generic = others(ans, s, [plus(arc, ab(s.r)), plus(scale(arc, 2), ab(s.r.mul(2))), plus(scale(th, s.r.sq()), ab(s.r.mul(2))), plus(v, ab(s.r)), plus(arc, ab(s.r.mul(4)))])
	var r := R(s)
	var two := Fmt.dec(s.r.mul(2))
	var turn := S(s, ab(0, s.r.mul(2)))
	var a1 := scale(S(s, th), s.r)
	var a2 := share(s, turn)
	out.methods = {"l-equals-r-theta": method(to_rad(s) + ["l = rθ = %s × %s = %s" % [r, W(s, th), W(s, a1)], "Add the two radii: P = %s + %s" % [W(s, a1), two], say(ans)], ans.values),
		"fraction-of-circumference": method(["The arc is %s of the circumference, 2π × %s." % [part(s), r], "l = %s × %s = %s" % [_frac(s), W(s, turn), W(s, a2)], "Add the two radii: P = %s + %s" % [W(s, a2), two], say(ans)], ans.values)}
	return out


func u_theta_from_arc(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := theta(s)
	var ans := ans_of(s, "θ = ", v)
	var out := frame(rep, s, ["r", "l"], "Find θ, the angle at the centre, in radians.", ans)
	var l: Array = s.l
	out.wrongs = []
	out.generic = others(ans, s, [scale(l, s.r), scale(v, 2), scale(v, Q.new(1, 2)), scale(l, Q.new(1).div(s.r.sq())), scale(l, s.r.mul(Q.new(1, 2))), plus(v, ab(1))])
	var r := R(s)
	out.methods = {"l-equals-r-theta": method(["l = rθ, so θ = l ÷ r", "θ = %s ÷ %s = %s" % [G(l), r, W(s, v)], say(ans)], ans.values),
		"fraction-of-circumference": method(["The circumference is 2π × %s = %s." % [r, W(s, ab(0, s.r.mul(2)))], "The arc is %s ÷ %s of it, and θ is that much of 2π." % [G(l), W(s, ab(0, s.r.mul(2)))], say(ans)], ans.values)}
	return out


func u_r_from_arc(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := ab(s.r)
	var ans := ans_of(s, "r = ", v, unit(s))
	var out := frame(rep, s, ["t", "l"], "Find the radius." if rep == "words" else "Find r.", ans)
	var th := theta(s)
	var size := radians(s)
	var l: Array = s.l
	var ls := fl(l)
	out.wrongs = []
	out.generic = _whole(ans, s, s.r) if s.paper == 1 else others(ans, s, [ab(GdcKit.qf(ls * size)), ab(GdcKit.qf(ls / size * 2.0)), ab(GdcKit.qf(ls / size / 2.0)), ab(GdcKit.qf(ls / size * ls / size)), ab(GdcKit.qf(ls / size + 1.0))])
	var worked := Fmt.sf(ls / fl(S(s, th)), 5) if s.paper == 2 else W(s, v)
	out.methods = {"l-equals-r-theta": method(to_rad(s) + ["l = rθ, so r = l ÷ θ", "r = %s ÷ %s = %s" % [G(l), W(s, th), worked], say(ans)], ans.values)}
	return out


## Whole numbers near a whole r on Paper 1, and a fraction or two of it.
static func _whole(ans: Dictionary, s: Dictionary, r: Q) -> Array:
	return others(ans, s, [ab(r.mul(2)), ab(r.add(1)), ab(r.add(2)), ab(r.sub(1)), ab(r.add(3)), ab(r.add(4))])


func u_r_from_perimeter(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := ab(s.r)
	var ans := ans_of(s, "r = ", v, unit(s))
	var out := frame(rep, s, ["t", "p"], "Find the radius." if rep == "words" else "Find r.", ans)
	var per: Array = s.per
	var pf := fl(per)
	var size: float = s.t.to_float()
	var no_radii: Variant = per[0].div(s.t) if s.paper == 1 else GdcKit.qf(pf / size)
	out.wrongs = like(ans, s, ab(no_radii), R_NO_RADII)
	var one := ab(per[0].div(s.t.add(1))) if s.paper == 1 else ab(GdcKit.qf(pf / (1.0 + size)))
	out.generic = others(ans, s, [one]) + (_whole(ans, s, s.r) if s.paper == 1 else others(ans, s, [ab(GdcKit.qf(pf - 2.0)), ab(GdcKit.qf(pf / 2.0)), ab(GdcKit.qf(pf / (2.0 + size) * 2.0)), ab(GdcKit.qf(pf / (2.0 + size) + 1.0))]))
	var t := Fmt.dec(s.t)
	out.methods = {"l-equals-r-theta": method(["P = 2r + rθ = r(2 + %s)" % t, "r = %s ÷ (2 + %s) = %s" % [G(per), t, W(s, v)], say(ans)], ans.values)}
	return out


func u_theta_from_perimeter(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := ab(s.t)
	var ans := ans_of(s, "θ = ", v)
	var out := frame(rep, s, ["r", "p"], "Find θ, the angle at the centre, in radians.", ans)
	var per: Array = s.per
	out.wrongs = like(ans, s, ab(per[0].div(s.r)), R_NO_RADII)
	var two: Q = s.r.mul(2)
	out.generic = others(ans, s, [ab(per[0].sub(s.r).div(s.r)), ab(per[0].sub(two).div(s.r.mul(2))), ab(s.t.add(1)), ab(s.t.mul(2)), ab(s.t.add(Q.new(1, 2))), plus(v, ab(2))])
	var arc: Q = per[0].sub(two)
	out.methods = {"l-equals-r-theta": method(["The arc is the perimeter less two radii: %s − 2 × %s = %s" % [G(per), R(s), Fmt.dec(arc)], "θ = l ÷ r = %s ÷ %s = %s" % [Fmt.dec(arc), R(s), W(s, v)], say(ans)], ans.values)}
	return out


func u_major_arc(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var big := reflex(s)
	var v := scale(big, s.r)
	var ans := ans_of(s, "l = ", v, unit(s))
	var c: Dictionary = CONTEXTS[s.ctx]
	var out := {"table": null, "answer": ans}
	if rep == "words":
		out.lines = ["%s has a reach of %s. It %s, except for a gap with an angle of %s at the centre." % [c.thing, R(s) + unit(s), c.gap, angle_words(s)]]
		out.asked = finish(s, "Find the length of the outer curved edge of the part it reaches.", ans)
	else:
		out.lines = ["The diagram shows a circle with centre O. The major arc AB is on the shaded sector."]
		out.lines[0] += "" if s.form == "deg" else " Angle AOB is in radians."
		out.graph = figure(s, "major", {"r_label": R(s) + unit(s), "angle_label": angle_text(s)})
		out.asked = finish(s, "Find the length of the major arc AB.", ans)
	var minor := scale(theta(s), s.r)
	out.wrongs = like(ans, s, minor, R_MINOR_ARC)
	out.generic = others(ans, s, [ab(0, s.r.mul(2)), ab(0, s.r), scale(big, s.r.mul(2)), scale(big, s.r.div(2)), plus(v, ab(s.r.mul(2))), plus(v, minor)])
	var r := R(s)
	var round_c := S(s, ab(0, s.r.mul(2)))
	var round_m := S(s, minor)
	var round_b := S(s, less(ab(0, 2), S(s, theta(s))))
	out.methods = {"l-equals-r-theta": method(to_rad(s) + ["The major arc has the reflex angle: 2π − %s = %s" % [W(s, theta(s)), W(s, round_b)], "l = rθ = %s × %s = %s" % [r, Br(s, round_b), W(s, scale(round_b, s.r))], say(ans)], ans.values),
		"fraction-of-circumference": method(["The circumference is 2π × %s = %s." % [r, W(s, round_c)], "The minor arc is %s of it, which is %s." % [part(s), W(s, round_m)], "l = %s − %s = %s" % [W(s, round_c), W(s, round_m), W(s, less(round_c, round_m))], say(ans)], ans.values)}
	return out


func u_r_in_terms_of_theta(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var l: Q = s.l[0]
	var u := unit(s)
	var ls := Fmt.dec(l)
	var ans := DifferentiationViews.form("r = %s/θ" % ls, ["r = ", {"slot": "v"}, "/θ"], {"v": l})
	var out := {"table": null, "answer": ans}
	if rep == "words":
		var c: Dictionary = CONTEXTS[s.ctx]
		out.lines = ["%s %s, with an angle of θ radians at the centre. The curved edge of the sector is %s long." % [c.thing, c.does, ls + u]]
		out.asked = "Write down an expression for the radius r in terms of θ."
	else:
		out.lines = ["The diagram shows sector OAB of a circle with centre O and radius r. Angle AOB is θ radians."]
		out.graph = figure(s, "minor", {"r_label": "r", "angle_label": "θ", "arc_label": ls + u})
		out.asked = "Write down an expression for r in terms of θ."
	out.wrongs = []
	out.generic = [DifferentiationViews.alt("r = %sθ" % ls).values, DifferentiationViews.alt("r = θ/%s" % ls).values,
		DifferentiationViews.alt("r = %s/θ" % Fmt.dec(l.mul(2)), "", {"v": l.mul(2)}).values, DifferentiationViews.alt("r = %s/(2θ)" % ls).values]
	out.methods = {"l-equals-r-theta": method(["l = rθ, and the arc is %s." % ls, "rθ = %s, so divide by θ." % ls, "So r = %s/θ." % ls], ans.values)}
	return out


func u_theta_from_bent_strip(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := ab(s.t)
	var ans := ans_of(s, "θ = ", v)
	var u := " cm"
	var w := Fmt.dec(s.strip)
	var h := Fmt.dec(s.side)
	var r := Fmt.dec(s.r)
	var out := {"table": null, "answer": ans}
	out.lines = ["A water trough is bent from a strip of tin %s wide. Across the strip it has a straight side %s long, a curved part, then another straight side %s long." % [w + u, h + u, h + u],
		"The curved part is an arc of a circle of radius %s." % (r + u)]
	out.asked = finish(s, "Find θ, the angle at the centre of the arc, in radians.", ans)
	var arc: Q = s.strip.sub(s.side.mul(2))
	out.wrongs = []
	out.generic = others(ans, s, [ab(s.strip.div(s.r)), ab(s.strip.sub(s.side).div(s.r)), ab(arc.div(s.r.mul(2))), ab(arc.mul(s.r)), ab(s.t.add(1)), ab(s.t.mul(2))])
	out.methods = {"l-equals-r-theta": method(["The arc is what is left of the strip: %s − 2 × %s = %s" % [w, h, Fmt.dec(arc)], "θ = l ÷ r = %s ÷ %s = %s" % [Fmt.dec(arc), r, W(s, v)], say(ans)], ans.values)}
	return out


# ── Areas ────────────────────────────────────────────────────

func u_sector_area(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var th := theta(s)
	var half: Q = s.r.sq().div(2)
	var v := scale(th, half)
	var ans := ans_of(s, "A = ", v, unit2(s))
	var out := frame(rep, s, ["r", "t"], "Find the area of the sector.", ans)
	out.wrongs = []
	if s.form == "deg":
		out.wrongs += like(ans, s, ab(half.mul(s.t)), R_AREA_DEG)
	# ½rθ², with θ in radians: on Paper 1 only where that stays clean.
	if s.paper == 2:
		out.wrongs += like(ans, s, ab(GdcKit.qf(0.5 * s.r.to_float() * pow(radians(s), 2))), R_THETA_SQ)
	elif th[0].is_zero():
		out.wrongs += said("A = %s%s" % [Fmt.num(s.r.mul(th[1].sq()).div(2)) + "π²", unit2(s)], R_THETA_SQ)
	else:
		out.wrongs += like(ans, s, ab(s.r.mul(th[0].sq()).div(2)), R_THETA_SQ)
	out.generic = others(ans, s, [scale(th, s.r.sq()), scale(th, s.r), scale(th, s.r.div(2)), ab(0, s.r.sq()), scale(v, 2), plus(v, ab(s.r))])
	var r := R(s)
	var disc := S(s, ab(0, s.r.sq()))
	out.methods = {"half-r-squared-theta": method(to_rad(s) + ["A = ½r²θ = ½ × %s² × %s = %s" % [r, W(s, th), W(s, scale(S(s, th), half))], say(ans)], ans.values),
		"fraction-of-circle": method(["The sector is %s of the circle." % part(s), "π × %s² = %s" % [r, W(s, disc)], "A = %s × %s = %s" % [_frac(s), W(s, disc), W(s, share(s, disc))], say(ans)], ans.values)}
	return out


func u_theta_from_area(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := theta(s)
	var ans := ans_of(s, "θ = ", v)
	var out := frame(rep, s, ["r", "a"], "Find θ, the angle at the centre, in radians.", ans)
	var a: Array = s.area
	var r2: Q = s.r.sq()
	out.wrongs = []
	out.generic = others(ans, s, [scale(a, Q.new(1).div(r2)), scale(a, Q.new(2).div(s.r)), scale(v, 2), scale(a, Q.new(1).div(s.r)), plus(v, ab(1)), scale(v, Q.new(3, 2))])
	var r := R(s)
	out.methods = {"half-r-squared-theta": method(["A = ½r²θ, so θ = 2A ÷ r²", "θ = 2 × %s ÷ %s² = %s" % [G(a), r, W(s, v)], say(ans)], ans.values),
		"fraction-of-circle": method(["The circle's area is π × %s² = %s." % [r, W(s, ab(0, r2))], "θ is the same fraction of 2π as the sector is of the circle: (%s ÷ %s) × 2π" % [G(a), W(s, ab(0, r2))], say(ans)], ans.values)}
	return out


func u_r_from_area(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := ab(s.r)
	var ans := ans_of(s, "r = ", v, unit(s))
	var out := frame(rep, s, ["t", "a"], "Find the radius." if rep == "words" else "Find r.", ans)
	var th := theta(s)
	var a: Array = s.area
	var size := radians(s)
	var af := fl(a)
	var rs: float = 2.0 * af / size
	out.wrongs = []
	if s.paper == 2:
		out.generic = others(ans, s, [ab(GdcKit.qf(rs)), ab(GdcKit.qf(sqrt(af / size))), ab(GdcKit.qf(sqrt(rs) * 2.0)), ab(GdcKit.qf(rs / 2.0)), ab(GdcKit.qf(sqrt(rs) + 1.0))])
	else:
		out.generic = others(ans, s, [ab(s.r.sq())]) + _whole(ans, s, s.r)
	var r2 := Fmt.sf(2.0 * af / fl(S(s, th)), 5) if s.paper == 2 else Fmt.dec(s.r.sq())
	var rt := Fmt.sf(sqrt(float(r2)), 5) if s.paper == 2 else R(s)
	out.methods = {"half-r-squared-theta": method(to_rad(s) + ["A = ½r²θ, so r² = 2A ÷ θ = 2 × %s ÷ %s = %s" % [G(a), W(s, th), r2], "r = √%s = %s" % [r2, rt], say(ans)], ans.values)}
	return out


func u_major_sector(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var big := reflex(s)
	var half: Q = s.r.sq().div(2)
	var v := scale(big, half)
	var ans := ans_of(s, "A = ", v, unit2(s))
	var c: Dictionary = CONTEXTS[s.ctx]
	var out := {"table": null, "answer": ans}
	if rep == "words":
		out.lines = ["%s has a reach of %s. It %s, except for a gap with an angle of %s at the centre." % [c.thing, R(s) + unit(s), c.gap, angle_words(s)]]
		out.asked = finish(s, "Find the area it reaches.", ans)
	else:
		out.lines = ["The diagram shows a circle with centre O, with the major sector shaded."]
		out.lines[0] += "" if s.form == "deg" else " Angle AOB is in radians."
		out.graph = figure(s, "major", {"r_label": R(s) + unit(s), "angle_label": angle_text(s)})
		out.asked = finish(s, "Find the area of the shaded major sector.", ans)
	var minor := scale(theta(s), half)
	var circle := ab(0, s.r.sq())
	out.wrongs = like(ans, s, minor, R_MINOR)
	out.generic = others(ans, s, [circle, scale(big, s.r), scale(big, s.r.sq()), scale(circle, 2), plus(circle, minor), scale(v, Q.new(1, 2))])
	var r := R(s)
	var round_b := S(s, less(ab(0, 2), S(s, theta(s))))
	var round_c := S(s, circle)
	var round_t := S(s, theta(s))
	var round_m := S(s, scale(round_t, half))
	var left := less(round_c, round_m)
	out.methods = {"half-r-squared-theta": method(to_rad(s) + ["The reflex angle is 2π − %s = %s." % [W(s, theta(s)), W(s, round_b)], "A = ½r²θ = ½ × %s² × %s = %s" % [r, Br(s, round_b), W(s, scale(round_b, half))], say(ans)], ans.values),
		"fraction-of-circle": method(["The minor sector is %s of the circle, so the major sector is what is left of 1." % part(s), "The circle's area is π × %s² = %s." % [r, W(s, round_c)], "A = %s − %s = %s" % [W(s, round_c), W(s, round_m), W(s, left)], say(ans)], ans.values),
		"complement": method(to_rad(s) + ["The circle is π × %s² = %s and the minor sector is ½ × %s² × %s = %s." % [r, W(s, round_c), r, W(s, round_t), W(s, round_m)], "A = %s − %s = %s" % [W(s, round_c), W(s, round_m), W(s, left)], say(ans)], ans.values)}
	return out


func u_area_from_arc(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var half: Q = s.r.sq().div(2)
	var v := ab(half.mul(s.t))
	var ans := ans_of(s, "A = ", v, unit2(s))
	var out := frame(rep, s, ["r", "l"], "Find the area of the sector.", ans)
	var l: Q = s.l[0]
	out.wrongs = []
	out.generic = others(ans, s, [ab(l.mul(s.r)), ab(l.mul(s.r).div(4)), ab(l.sq().div(2)), ab(s.r.sq().mul(s.t)), ab(half), ab(half.mul(s.t).add(s.r)), ab(half.mul(s.t).add(1)), ab(half.mul(s.t).add(2)), ab(half.mul(s.t).mul(3))])
	out.methods = {"l-equals-r-theta": method(["θ = l ÷ r = %s ÷ %s = %s" % [Fmt.dec(l), R(s), W(s, ab(s.t))], "A = ½r²θ = ½ × %s² × %s = %s" % [R(s), W(s, ab(s.t)), W(s, scale(S(s, ab(s.t)), half))], say(ans)], ans.values)}
	return out


func u_perimeter_from_area(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := ab(s.r.mul(s.t.add(2)))
	var ans := ans_of(s, "P = ", v, unit(s))
	var out := frame(rep, s, ["t", "a"], "Find the perimeter of the sector.", ans)
	var t := Fmt.dec(s.t)
	var a: Array = s.area
	var arc := ab(s.r.mul(s.t))
	out.wrongs = []
	out.generic = others(ans, s, [arc, ab(s.r.mul(2)), ab(s.r.mul(s.t.add(1))), ab(s.r.mul(s.t.add(4))), ab(s.r.mul(s.t).mul(2).add(s.r)), scale(v, 2)])
	var r2: Q = a[0].mul(2).div(s.t)
	var r2t := Fmt.sf(r2, 5) if s.paper == 2 else Fmt.dec(r2)
	var rt := Fmt.sf(sqrt(float(r2t)), 5) if s.paper == 2 else R(s)
	var whole := W(s, ab(Answer.parse_number(rt).q.mul(s.t.add(2))))
	out.methods = {"l-equals-r-theta": method(["A = ½r²θ, so r² = 2 × %s ÷ %s = %s" % [G(a), t, r2t], "r = √%s = %s" % [r2t, rt], "P = 2r + rθ = %s × (2 + %s) = %s" % [rt, t, whole], say(ans)], ans.values)}
	return out


func u_major_from_perimeter(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var big := reflex(s)
	# A worked-back r on Paper 2 has nine places, too many to square as a Q.
	var square: Q = s.r.sq() if s.paper == 1 else GdcKit.qf(pow(s.r.to_float(), 2))
	var half: Q = square.div(2)
	var v := scale(big, half)
	var ans := ans_of(s, "A = ", v, unit2(s))
	var t := Fmt.dec(s.t)
	var per: Array = s.per
	var out := {"table": null, "answer": ans}
	out.lines = ["The diagram shows a circle with centre O. Angle AOB is %s radians, and the perimeter of the small shaded sector is %s." % [t, G(per) + unit(s)]]
	out.graph = figure(s, "minor", {"circle": true, "r_label": "r", "angle_label": t})
	out.asked = finish(s, "Find the area of the part of the circle that isn't shaded.", ans)
	var minor := ab(half.mul(s.t))
	var circle := ab(0, square)
	out.wrongs = like(ans, s, minor, R_MINOR)
	out.generic = others(ans, s, [circle, scale(circle, 2), plus(circle, minor), scale(v, 2), scale(v, Q.new(1, 2)), plus(v, ab(s.r))])
	var rt := Fmt.sf(s.r, 5) if s.paper == 2 else R(s)
	var rq: Q = Answer.parse_number(rt).q
	var whole := S(s, ab(0, rq.sq()))
	var part_m := S(s, ab(rq.sq().mul(s.t).div(2)))
	out.methods = {"l-equals-r-theta": method(["P = 2r + rθ, so r = %s ÷ (2 + %s) = %s" % [G(per), t, rt], "The circle is π × %s² = %s." % [rt, W(s, whole)], "The shaded sector is ½ × %s² × %s = %s." % [rt, t, W(s, part_m)], "A = %s − %s" % [W(s, whole), W(s, part_m)], say(ans)], ans.values)}
	return out


# ── Sectors in other shapes ──────────────────────────────────

func u_cone_radius(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var th := theta(s)
	var arc := scale(th, s.r)
	var v := ab(s.r.mul(th[1].div(2))) if s.paper == 1 else ab(GdcKit.qf(fl(arc) / TAU))
	var ans := ans_of(s, "radius = ", v, unit(s))
	var out := {"table": null, "answer": ans}
	var story := "A sheet of tin is cut into a sector of radius %s and angle %s. Its two straight edges are joined to make a funnel, with the arc as the rim." % [R(s) + unit(s), angle_words(s)]
	out.lines = [story]
	if rep == "diagram":
		out.lines = ["The sector in the diagram, with centre O, is rolled up so that OA meets OB, to make a cone. The arc becomes the rim."]
		if s.form != "deg":
			out.lines[0] += " Its angle is in radians."
		out.graph = figure(s, "minor", {"r_label": R(s) + unit(s), "angle_label": angle_text(s), "cone": true})
	out.asked = finish(s, "Find the radius of the circle at the rim.", ans)
	out.wrongs = []
	out.generic = others(ans, s, [arc, scale(arc, Q.new(1, 2)), ab(s.r), scale(v, 2), scale(v, Q.new(1, 2)), plus(v, ab(1))])
	var r := R(s)
	var worked := scale(S(s, th), s.r)
	var rim := "The rim is the arc: %s × %s = %s" % [r, W(s, th), W(s, worked)]
	out.methods = {"l-equals-r-theta": method(to_rad(s) + [rim, "2π × radius = %s, so radius = %s ÷ 2π" % [W(s, worked), W(s, worked)], say(ans)], ans.values),
		"fraction-of-circumference": method(["The arc is %s of a circle of radius %s." % [part(s), r], "The rim is that arc, so its radius is that fraction of %s." % r, say(ans)], ans.values)}
	return out


## A curved strip between circles of radius r and rin, with a gap in it.
static func ring_figure(s: Dictionary, inner: String) -> Dictionary:
	var over := {"circle": true, "r_label": Fmt.dec(s.r) + " cm", "angle_label": Fmt.dec(s.t), "inner": s.rin.to_float() / s.r.to_float(), "inner_label": inner}
	return figure(s, "major", over)


func u_ring_inner_radius(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := ans_of(s, "r = ", ab(s.rin), " cm")
	var a: Q = s.area[0]
	var big: Q = s.r.sq()
	var out := {"table": null, "answer": ans}
	out.lines = ["A curved strip of steel lies between two circles with centre O, as shaded. The reflex angle at O is %s radians, the outer radius is %s and the inner radius is r cm." % [Fmt.dec(s.t), Fmt.dec(s.r) + " cm"],
		"The area of the strip is %s cm²." % Fmt.dec(a)]
	out.graph = ring_figure(s, "r")
	out.asked = finish(s, "Find r.", ans)
	var t: float = s.t.to_float()
	var sq: float = big.to_float() - 2.0 * a.to_float() / t
	out.wrongs = []
	out.generic = others(ans, s, [ab(GdcKit.qf(sq)), ab(GdcKit.qf(sqrt(absf(big.to_float() - a.to_float() / t)))), ab(GdcKit.qf(s.r.to_float() - sqrt(2.0 * a.to_float() / t))), ab(GdcKit.qf(sqrt(sq) + 1.0)), ab(GdcKit.qf(sqrt(sq) * 2.0))])
	var sqt := Fmt.sf(sq, 5)
	out.methods = {"half-r-squared-theta": method(["The strip is the outer sector less the inner one: ½ × %s × (%s² − r²) = %s" % [Fmt.dec(s.t), Fmt.dec(s.r), Fmt.dec(a)],
		"%s² − r² = 2 × %s ÷ %s" % [Fmt.dec(s.r), Fmt.dec(a), Fmt.dec(s.t)], "r² = %s, so r = √%s" % [sqt, sqt], say(ans)], ans.values)}
	return out


func u_ring_perimeter(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var outer: Q = s.r.mul(s.t)
	var inner: Q = s.rin.mul(s.t)
	var edge: Q = s.r.sub(s.rin)
	var v := ab(outer.add(inner).add(edge.mul(2)))
	var ans := ans_of(s, "P = ", v, " cm")
	var out := {"table": null, "answer": ans}
	out.lines = ["A curved strip of steel lies between two circles with centre O, as shaded. The reflex angle at O is %s radians, the outer radius is %s and the inner radius is %s." % [Fmt.dec(s.t), Fmt.dec(s.r) + " cm", Fmt.dec(s.rin) + " cm"]]
	out.graph = ring_figure(s, Fmt.dec(s.rin) + " cm")
	out.asked = finish(s, "Find the perimeter of the strip.", ans)
	out.wrongs = []
	out.generic = others(ans, s, [ab(outer.add(inner)), ab(outer.add(edge.mul(2))), ab(outer.add(inner).add(edge)), ab(outer.add(s.r.mul(2))), ab(outer.add(inner).add(s.r.mul(2)))])
	out.methods = {"l-equals-r-theta": method(["Outer arc: %s × %s = %s" % [Fmt.dec(s.r), Fmt.dec(s.t), Fmt.dec(outer)], "Inner arc: %s × %s = %s" % [Fmt.dec(s.rin), Fmt.dec(s.t), Fmt.dec(inner)],
		"The two straight ends: 2 × (%s − %s) = %s" % [Fmt.dec(s.r), Fmt.dec(s.rin), Fmt.dec(edge.mul(2))], "P = %s + %s + %s" % [Fmt.dec(outer), Fmt.dec(inner), Fmt.dec(edge.mul(2))], say(ans)], ans.values)}
	return out


## θ with w h − k ρ²(θ − sin θ)/2 = area on 0 to π, by halving: θ − sin θ only rises.
static func solve_plate(s: Dictionary, degrees: bool = false, k: float = 2.0) -> float:
	var goal: float = (s.w * s.h - s.area[0].to_float()) * 2.0 / (k * s.rho * s.rho)
	var lo := 0.0
	var hi := TAU
	for i in 80:
		var mid := (lo + hi) / 2.0
		var sn := sin(deg_to_rad(mid) if degrees else mid)
		if mid - sn < goal:
			lo = mid
		else:
			hi = mid
	return (lo + hi) / 2.0


func u_segments_theta(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var th: float = s.t.to_float()
	var ans := ans_of(s, "θ = ", ab(s.t))
	var out := {"table": null, "answer": ans}
	var a: Q = s.area[0]
	out.lines = ["A steel plate is a rectangle %d cm by %d cm. An equal segment is cut from each of two opposite edges, as in the diagram." % [s.w, s.h],
		"Each segment is part of a circle of radius %d cm, with angle θ at its centre O, where θ is in radians and 0 < θ < π." % s.rho,
		"The area of the plate that is left is %s cm²." % Fmt.dec(a)]
	out.graph = {"kind": "plate", "w": s.w, "h": s.h, "rho": s.rho, "theta": th, "w_label": "%d cm" % s.w, "h_label": "%d cm" % s.h, "rho_label": "%d cm" % s.rho, "angle_label": "θ"}
	out.asked = finish(s, "Find θ.", ans)
	out.wrongs = like(ans, s, ab(GdcKit.qf(solve_plate(s, true))), R_SIN_DEG)
	var goal: float = float(s.w * s.h - a.to_float()) / float(s.rho * s.rho)
	out.generic = others(ans, s, [ab(GdcKit.qf(solve_plate(s, false, 1.0))), ab(GdcKit.qf(goal)), ab(GdcKit.qf(solve_plate(s, false, 4.0))), ab(GdcKit.qf(th + 0.5)), ab(GdcKit.qf(th / 2.0))])
	var total: int = s.w * s.h
	out.methods = {"sector-minus-triangle": method(["Each segment is a sector less a triangle: ½ρ²θ − ½ρ² sin θ, with ρ = %d." % s.rho,
		"The plate is the rectangle less two of them: %d − %d(θ − sin θ) = %s" % [total, s.rho * s.rho, Fmt.dec(a)],
		"Solve on the GDC, in radians, with 0 < θ < π.", say(ans)], ans.values)}
	return out
