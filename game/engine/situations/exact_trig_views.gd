class_name ExactTrigViews
extends ExtensionViews
## The views on the `exact-trig` situation: one builder per unknown of t3-exact-values (FAL-727).
## Every answer is exact, and a `form` answer (TrigKit), or a `claim` where it is a reading.
##
## Representations: "equation" (written out), "diagram" (a special triangle, or the unit circle,
## PlotView's `unit-circle`), "graph" (the wave with the angle marked) and "table" (the landmark
## values with one to fill in).

const R_SWAP := "SL3.5.exact-special#0"
const R_TAN_SIX := "SL3.5.exact-special#1"
const R_SIN_FOUR := "SL3.5.exact-special#2"
const R_SIGN := "SL3.5.related-angles#0"
const R_Y_AXIS := "SL3.5.related-angles#1"
const R_NEGATIVE := "SL3.5.related-angles#2"
const R_COORDS := "SL3.5.unit-circle#0"
const R_CLOCKWISE := "SL3.5.unit-circle#1"
const R_TAN_ZERO := "SL3.5.unit-circle#2"

const UNKNOWNS := ["special-value", "scaled-value", "special-sum", "related-value", "related-sum", "given-related",
	"point-at-angle", "ratio-from-point", "tan-from-point", "sign-in-quadrant", "tan-undefined"]

const HEADS := ["0", "π/6", "π/4", "π/3", "π/2"]
const SIZES := [[0, 1], [1, 6], [1, 4], [1, 3], [1, 2]]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = ExactTrigSituation.export(s)
	return out


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func T(v: Array) -> String:
	return TrigKit.text(v)


static func call_of(s: Dictionary) -> String:
	return TrigKit.call_text(s.fn, s.t, s.form)


## The opposite, adjacent and hypotenuse of the special triangle at t.
static func sides_at(t: Q) -> Array:
	match t.key():
		"0":
			return ["0", "1", "1"]
		"1/6":
			return ["1", "√3", "2"]
		"1/4":
			return ["1", "1", "√2"]
		"1/3":
			return ["√3", "1", "2"]
	return ["1", "0", "1"]


## The working for one first-quadrant value, by each method.
static func first_steps(method_id: String, fn: String, t: Q, form: String) -> Array:
	var name := TrigKit.call_text(fn, t, form)
	var a := TrigKit.angle(t, form)
	var v: String = T(TrigKit.of(fn, t))
	match method_id:
		"special-triangles":
			var e := sides_at(t)
			var ratio: String = {"sin": "opposite ÷ hypotenuse", "cos": "adjacent ÷ hypotenuse", "tan": "opposite ÷ adjacent"}[fn]
			var top: String = e[1] if fn == "cos" else e[0]
			var low: String = e[1] if fn == "tan" else e[2]
			var shape := "Half an equilateral triangle of side 2" if t.d in [3, 6] else ("The isosceles right triangle" if t.d == 4 else "The flattened triangle")
			return ["%s has opposite %s, adjacent %s and hypotenuse %s at %s." % [shape, e[0], e[1], e[2], a],
				"%s is %s = %s ÷ %s = %s" % [name, ratio, top, low, v]]
		"unit-circle-points":
			var c: String = T(TrigKit.cos_pi(t))
			var y: String = T(TrigKit.sin_pi(t))
			var read: String = {"sin": "sin is the y-coordinate", "cos": "cos is the x-coordinate", "tan": "tan is y ÷ x"}[fn]
			return ["The point on the unit circle at %s is (%s, %s)." % [a, c, y], "%s, so %s = %s" % [read, name, v]]
	var i := _step(t)
	var list := "√0/2, √1/2, √2/2, √3/2, √4/2"
	match fn:
		"sin":
			return ["sin of 0, π/6, π/4, π/3, π/2 is %s." % list, "%s is number %d in that list: %s = %s" % [a, i + 1, name, v]]
		"cos":
			return ["cos of 0, π/6, π/4, π/3, π/2 is the list %s backwards." % list, "%s is number %d in the backwards list: %s = %s" % [a, i + 1, name, v]]
	return ["sin and cos follow %s, cos backwards." % list, "tan is sin ÷ cos: %s ÷ %s = %s" % [T(TrigKit.sin_pi(t)), T(TrigKit.cos_pi(t)), v]]


static func _step(t: Q) -> int:
	return {"0": 0, "1/6": 1, "1/4": 2, "1/3": 3, "1/2": 4}[t.key()]


## Wrong options for a first-quadrant value, times k.
static func first_wrongs(a: Dictionary, fn: String, t: Q, k: Variant = 1) -> Array:
	var out: Array = []
	if fn != "tan" and t.d in [3, 6]:
		out += TrigKit.like(a, TrigKit.times(TrigKit.of("cos" if fn == "sin" else "sin", t), k), R_SWAP)
	if fn == "tan" and t.key() == "1/6":
		out += TrigKit.like(a, TrigKit.times(TrigKit.root(3), k), R_TAN_SIX)
	if fn != "tan" and t.key() == "1/4":
		out += TrigKit.like(a, TrigKit.times(TrigKit.V(Q.new(1, 2)), k), R_SIN_FOUR)
	return out


static func landmark_values(k: Variant = 1) -> Array:
	return [TrigKit.V(Q.new(1, 2)), TrigKit.V(0, Q.new(1, 2), 2), TrigKit.V(0, Q.new(1, 2), 3), TrigKit.V(1), TrigKit.V(2), TrigKit.V(0, 1, 3), TrigKit.V(0, 1, 2), TrigKit.V(0, Q.new(1, 3), 3)].map(func(v): return TrigKit.times(v, k))


func u_special_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := TrigKit.of(s.fn, s.t)
	var a := TrigKit.ans("%s θ = " % s.fn if rep == "diagram" else call_of(s) + " = ", v)
	var out := {"answer": a, "asked": "Find the exact value of %s." % call_of(s), "lines": [call_of(s)]}
	out.wrongs = first_wrongs(a, s.fn, s.t)
	out.generic = TrigKit.others(a, landmark_values())
	if rep == "table":
		out.lines = ["The table lists the landmark angles. Fill in the cell with the question mark."]
		out.table = _table(s)
		out.asked = "Find the exact value of the cell marked ?."
	elif rep == "diagram":
		out.lines = ["The diagram shows a right-angled triangle with angle θ = %s at A." % TrigKit.angle(s.t, s.form)]
		out.diagram = _triangle(s.t)
		out.asked = "Find the exact value of %s θ." % s.fn
	var m := {}
	for id in ["special-triangles", "unit-circle-points", "root-pattern"]:
		m[id] = method(first_steps(id, s.fn, s.t, s.form) + [say(a)], a.values)
	out.methods = m
	return out


static func _table(s: Dictionary) -> Dictionary:
	var rows: Array = [["θ", HEADS]]
	for fn in TrigKit.FNS:
		if fn == s.fn:
			var cells: Array = []
			for p in SIZES:
				cells.append("?" if Q.new(p[0], p[1]).eq(s.t) else "")
			rows.append(["%s θ" % fn, cells])
		elif fn != "tan":
			rows.append(["%s θ" % fn, SIZES.map(func(p): return T(TrigKit.of(fn, Q.new(p[0], p[1]))))])
	return {"rows": rows}


## The right-angled triangle with angle t at A, sides as the special triangle has them.
static func _triangle(t: Q) -> Dictionary:
	var e := sides_at(t)
	var ang := t.to_float() * PI
	var pts := {"A": [0.0, 0.0], "B": [cos(ang), 0.0], "C": [cos(ang), sin(ang)]}
	return {"vertices": pts, "sides": [{"side": "a", "label": e[0]}, {"side": "b", "label": e[2]}, {"side": "c", "label": e[1]}],
		"angles": [{"at": "A", "label": "θ"}, {"at": "B", "label": "90°"}, {"at": "C", "label": ""}]}


func u_scaled_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var v := TrigKit.times(TrigKit.of(s.fn, s.t), k)
	var ang: String = TrigKit.angle(s.t, "pi")
	var a := TrigKit.ans("f(%s) = " % ang if rep == "equation" else "h = ", v, "" if rep == "equation" else " m")
	var out := {"answer": a}
	if rep == "equation":
		out.lines = ["f(x) = %d %s x" % [k, s.fn]]
		out.asked = "Find the exact value of f(%s)." % ang
	else:
		var at := "θ radians to the ground" if s.fn == "sin" else "θ radians to the vertical"
		out.lines = ["A rope %d m long runs up from a peg at %s, so its top end is h = %d %s θ metres above the peg." % [k, at, k, s.fn]]
		out.asked = "Find the exact value of h when θ = %s." % ang
	out.wrongs = first_wrongs(a, s.fn, s.t, k)
	out.generic = TrigKit.others(a, landmark_values(k) + landmark_values(1))
	var name := "%s(%s)" % [s.fn, ang]
	var m := {}
	for id in ["special-triangles", "unit-circle-points", "root-pattern"]:
		m[id] = method(first_steps(id, s.fn, s.t, "pi") + ["%d × %s = %s" % [k, T(TrigKit.of(s.fn, s.t)), T(v)], say(a)], a.values)
	out.methods = m
	return out


## The value of first·fn²(t) ± fn2(t2), or [] where the sum has two surds.
static func special_sum(s: Dictionary) -> Array:
	var second := TrigKit.of(s.fn2, s.t2)
	return TrigKit.plus(TrigKit.times(TrigKit.sq(TrigKit.of(s.fn, s.t)), s.first), second if s.plus else TrigKit.neg(second))


static func sum_text(s: Dictionary) -> String:
	return "%s%s²(%s) %s %s" % ["" if s.first == 1 else str(s.first), s.fn, Fmt.pi(s.t), "+" if s.plus else "−", TrigKit.call_text(s.fn2, s.t2, "pi")]


func u_special_sum(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := special_sum(s)
	var a := TrigKit.ans("", v)
	var one := TrigKit.of(s.fn, s.t)
	var two := TrigKit.of(s.fn2, s.t2)
	var sq := TrigKit.times(TrigKit.sq(one), s.first)
	var out := {"answer": a, "lines": [sum_text(s)], "asked": "Find the exact value."}
	out.wrongs = []
	var sg := two if s.plus else TrigKit.neg(two)
	if s.fn != "tan" and s.t.key() == "1/4":
		out.wrongs = TrigKit.like(a, TrigKit.plus(TrigKit.times(TrigKit.V(Q.new(1, 4)), s.first), sg), R_SIN_FOUR)
	var gens: Array = [TrigKit.plus(TrigKit.times(one, s.first), sg), TrigKit.plus(sq, TrigKit.neg(sg)), TrigKit.plus(TrigKit.times(sq, 2), sg), TrigKit.plus(sq, TrigKit.times(sg, 2))]
	out.generic = TrigKit.others(a, gens.filter(func(g): return not g.is_empty()) + [TrigKit.plus(v, TrigKit.V(1)), TrigKit.plus(v, TrigKit.V(Q.new(1, 2))), TrigKit.plus(v, TrigKit.V(2))])
	var steps := func(head: String) -> Array:
		return ["%s %s = %s and %s = %s." % [head, TrigKit.call_text(s.fn, s.t, "pi"), T(one), TrigKit.call_text(s.fn2, s.t2, "pi"), T(two)],
			"Square the first: %s%s²(%s) = %s" % ["" if s.first == 1 else str(s.first), s.fn, Fmt.pi(s.t), T(sq)],
			"%s = %s" % [TrigKit.sum_text(sq, sg), T(v)], say(a)]
	out.methods = {"special-triangles": method(steps.call("The special triangles give"), a.values), "root-pattern": method(steps.call("The √n/2 pattern gives"), a.values)}
	return out


# ── Related angles ───────────────────────────────────────────

## The name of the identity for t: its shape, and the angle it leaves.
static func related_rule(fn: String, t: Q) -> String:
	var r: Q = TrigKit.ref_of(t)
	var rt := Fmt.pi(r)
	var sign := "" if TrigKit.of(fn, t)[0].add(TrigKit.of(fn, t)[1]).sign() > 0 else "−"
	if t.sign() < 0:
		return "%s(−x) = %s%s x" % [fn, "" if fn == "cos" else "−", fn]
	match TrigKit.quadrant(t):
		2:
			return "%s(π − %s) = %s%s(%s)" % [fn, rt, sign, fn, rt]
		3:
			return "%s(π + %s) = %s%s(%s)" % [fn, rt, sign, fn, rt]
		4:
			return "%s(2π − %s) = %s%s(%s)" % [fn, rt, sign, fn, rt]
	return "%s repeats every turn" % fn


## The working for an angle past the first quadrant, by each method.
static func round_steps(id: String, fn: String, t: Q) -> Array:
	var r: Q = TrigKit.ref_of(t)
	var q := TrigKit.quadrant(t)
	var rt := Fmt.pi(r)
	var size: String = T(TrigKit.of(fn, r))
	var name := TrigKit.call_text(fn, t, "pi")
	var v := TrigKit.of(fn, t)
	var sign := "positive" if v[0].add(v[1]).sign() > 0 else "negative"
	match id:
		"unit-circle-reflection":
			return ["%s is in quadrant %d of the unit circle." % [Fmt.pi(t), q],
				"Reflect its point into the first quadrant: it lands at %s, so the size is %s(%s) = %s." % [rt, fn, rt, size],
				"Only the sign can change, and in quadrant %d %s is %s: %s = %s" % [q, fn, sign, name, T(v)]]
		"reference-angle-cast":
			return ["The angle to the nearest x-axis is %s, and %s(%s) = %s." % [rt, fn, rt, size],
				"CAST: in quadrant %d, %s is %s." % [q, fn, sign], "%s = %s" % [name, T(v)]]
		"graph-symmetry":
			var mirror: String = {"sin": "y = sin x has mirror lines x = π/2 and x = 3π/2", "cos": "y = cos x has mirror lines x = 0 and x = π", "tan": "y = tan x repeats every π"}[fn]
			return ["%s, and it repeats every 2π." % mirror if fn != "tan" else mirror + ".",
				"So at %s the curve is as far from the axis as at %s, %s(%s) = %s, and it is %s there." % [Fmt.pi(t), rt, fn, rt, size, sign],
				"%s = %s" % [name, T(v)]]
	return ["Use %s." % related_rule(fn, t), "%s(%s) = %s" % [fn, rt, size], "%s = %s" % [name, T(v)]]


func u_related_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := TrigKit.of(s.fn, s.t)
	var a := TrigKit.ans(call_of(s) + " = ", v)
	var out := {"answer": a, "lines": [call_of(s)], "asked": "Find the exact value of %s." % call_of(s)}
	var ang: float = s.t.to_float() * PI
	if rep == "diagram":
		out.lines = ["The diagram shows the unit circle, with the point P at angle %s from the positive x-axis." % Fmt.pi(s.t)]
		out.graph = {"kind": "unit-circle", "points": [TrigKit.point(ang, "P")], "angle": ang, "angle_label": Fmt.pi(s.t), "radius": true}
	elif rep == "graph":
		var f: Callable = sin if s.fn == "sin" else cos
		out.lines = ["The graph shows y = %s x for 0 ≤ x ≤ 2π. P is the point at x = %s." % [s.fn, Fmt.pi(s.t)]]
		var ys: float = TrigKit.fl(v)
		out.graph = TrigKit.wave(f, Q.new(0), Q.new(2), -2, 2, Q.new(1, 2), [[ang, ys, "P"]])
	out.wrongs = []
	if s.t.sign() < 0:
		out.wrongs += TrigKit.like(a, TrigKit.of(s.fn, s.t.neg()), R_NEGATIVE)
	out.wrongs += TrigKit.like(a, TrigKit.neg(v), R_SIGN)
	var r: Q = TrigKit.ref_of(s.t)
	if r.key() != "1/4":
		var y := TrigKit.of(s.fn, Q.new(1, 2).sub(r))
		out.wrongs += TrigKit.like(a, y if v[0].add(v[1]).sign() > 0 else TrigKit.neg(y), R_Y_AXIS)
	out.generic = TrigKit.others(a, landmark_values() + landmark_values(-1))
	var m := {}
	for id in ["unit-circle-reflection", "reference-angle-cast", "graph-symmetry", "identity"]:
		m[id] = method(round_steps(id, s.fn, s.t) + [say(a)], a.values)
	out.methods = m
	return out


func u_related_sum(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var one := TrigKit.of(s.fn, s.t)
	var two := TrigKit.of(s.fn2, s.t2)
	var v := TrigKit.plus(one, two)
	var a := TrigKit.ans("", v)
	var left := "%s + %s" % [TrigKit.call_text(s.fn, s.t, "pi"), TrigKit.call_text(s.fn2, s.t2, "pi")]
	var out := {"answer": a, "lines": [left], "asked": "Find the exact value."}
	out.wrongs = TrigKit.like(a, TrigKit.plus(TrigKit.neg(one), two), R_SIGN)
	out.generic = TrigKit.others(a, [TrigKit.plus(one, TrigKit.neg(two)), TrigKit.neg(v), TrigKit.plus(v, TrigKit.V(1)), TrigKit.plus(v, TrigKit.V(Q.new(1, 2))), TrigKit.plus(v, TrigKit.V(-1)), TrigKit.plus(v, TrigKit.V(2))].filter(func(g): return not g.is_empty()))
	var add := "%s = %s" % [TrigKit.sum_text(one, two), T(v)]
	out.methods = {"reference-angle-cast": method(round_steps("reference-angle-cast", s.fn, s.t).slice(0, 2) + ["%s = %s" % [TrigKit.call_text(s.fn, s.t, "pi"), T(one)]] + round_steps("reference-angle-cast", s.fn2, s.t2).slice(0, 2) + ["%s = %s" % [TrigKit.call_text(s.fn2, s.t2, "pi"), T(two)], add, say(a)], a.values),
		"identity": method(round_steps("identity", s.fn, s.t) + round_steps("identity", s.fn2, s.t2) + [add, say(a)], a.values)}
	return out


## The value of the related ratio, as a sign: +1 or −1 of fn(θ).
static func related_sign(rule: String, fn: String) -> int:
	match rule:
		"pi-minus":
			return 1 if fn == "sin" else -1
		"pi-plus":
			return 1 if fn == "tan" else -1
	return 1 if fn == "cos" else -1


static func related_angle(rule: String) -> String:
	return {"pi-minus": "π − θ", "pi-plus": "π + θ", "minus": "−θ"}[rule]


static func related_why(rule: String) -> String:
	return {"pi-minus": "θ and π − θ are mirror images in the y-axis: the point keeps its y and x changes sign",
		"pi-plus": "π + θ is a half turn on from θ: both x and y change sign",
		"minus": "θ and −θ are mirror images in the x-axis: the point keeps its x and y changes sign"}[rule]


func u_given_related(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var g := Q.new(s.g, s.n)
	var sg := related_sign(s.rule, s.fn)
	var v := TrigKit.V(g.mul(sg))
	var a: Dictionary
	var out := {}
	if rep == "diagram":
		a = TrigKit.ans("sin CAB = ", v)
		out.lines = ["B, A and D lie on a straight line, and C is off the line.", "sin CAD = %s" % Fmt.num(g)]
		out.asked = "Find the exact value of sin CAB."
		out.graph = {"kind": "straight-angle", "theta": asin(g.to_float()), "names": ["B", "A", "D", "C"], "right_label": "θ", "left_label": "π − θ"}
	else:
		var name := "%s(%s)" % [s.fn, related_angle(s.rule)]
		a = TrigKit.ans(name + " = ", v)
		out.lines = ["%s θ = %s, where θ is acute." % [s.fn, Fmt.num(g)]]
		out.asked = "Find the exact value of %s." % name
	out.answer = a
	out.wrongs = TrigKit.like(a, TrigKit.neg(v), R_SIGN)
	var rest := Q.new(1).sub(g)
	out.generic = TrigKit.others(a, [TrigKit.V(rest), TrigKit.V(rest.neg()), TrigKit.V(g.div(2)), TrigKit.V(g.mul(2)), TrigKit.V(Q.new(1).div(g)), TrigKit.sqrt_q(Q.new(1).sub(g.sq()))])
	var word := "%s(%s)" % [s.fn, related_angle(s.rule)]
	var st := "%s = %s%s θ" % [word, "" if sg > 0 else "−", s.fn]
	if rep == "diagram":
		out.methods = {"identity": method(["CAB and CAD make a straight line, so CAB = π − θ, where θ = CAD.", "sin(π − θ) = sin θ", say(a)], a.values),
			"unit-circle-reflection": method(["CAB = π − θ, where θ = CAD, and %s." % related_why("pi-minus"), "sin is the y-coordinate, so sin CAB = sin CAD.", say(a)], a.values)}
	else:
		out.methods = {"identity": method(["Use %s." % st, "%s = %s" % [word, T(v)], say(a)], a.values),
			"unit-circle-reflection": method(["On the unit circle, %s." % related_why(s.rule), "So %s, which is %s." % [st, T(v)], say(a)], a.values)}
	return out


# ── The unit circle ──────────────────────────────────────────

static func _pair(x: Array, y: Array) -> String:
	return "P = (%s, %s)" % [T(x), T(y)]


static func _pair_slots(x: Array, y: Array) -> Dictionary:
	var out := TrigKit.slots(x, "x")
	out.merge(TrigKit.slots(y, "y"))
	return out


static func _pair_alt(a: Dictionary, x: Array, y: Array, ref: String = "") -> Dictionary:
	var keep: bool = TrigKit.shape(x) == a.sx and TrigKit.shape(y) == a.sy
	return DifferentiationViews.alt(_pair(x, y), ref, _pair_slots(x, y) if keep else {})


func u_point_at_angle(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x := TrigKit.cos_pi(s.t)
	var y := TrigKit.sin_pi(s.t)
	var parts: Array = ["P = ("] + TrigKit.parts(x, "x") + [", "] + TrigKit.parts(y, "y") + [")"]
	var a := DifferentiationViews.form(_pair(x, y), parts, _pair_slots(x, y))
	a.sx = TrigKit.shape(x)
	a.sy = TrigKit.shape(y)
	var ang: float = s.t.to_float() * PI
	var at := Fmt.pi(s.t)
	var out := {"answer": a, "asked": "Write down the exact coordinates of P."}
	out.lines = ["P is the point on the unit circle at angle θ = %s, measured anticlockwise from the positive x-axis." % at]
	if rep == "diagram":
		out.lines = ["The diagram shows the unit circle, with P at angle %s." % at]
		out.graph = {"kind": "unit-circle", "points": [TrigKit.point(ang, "P")], "angle": ang, "angle_label": at, "radius": true}
	out.wrongs = [_pair_alt(a, y, x, R_COORDS), _pair_alt(a, x, TrigKit.neg(y), R_CLOCKWISE)]
	out.generic = [_pair_alt(a, TrigKit.neg(x), y).values, _pair_alt(a, TrigKit.neg(x), TrigKit.neg(y)).values, _pair_alt(a, TrigKit.neg(y), x).values, _pair_alt(a, y, TrigKit.neg(x)).values]
	out.methods = {"read-coordinates": method(["cos θ is the x-coordinate and sin θ the y-coordinate.", "cos(%s) = %s and sin(%s) = %s" % [at, T(x), at, T(y)], say(a)], a.values)}
	return out


static func _point_show(rep: String, s: Dictionary) -> Dictionary:
	var xt := Fmt.num(s.x)
	var yt := Fmt.num(s.y)
	if rep == "diagram":
		var th := atan2(s.y.to_float(), s.x.to_float())
		return {"lines": ["The point P(%s, %s) on the unit circle is at angle θ from the positive x-axis." % [xt, yt]],
			"graph": {"kind": "unit-circle", "points": [{"x": s.x.to_float(), "y": s.y.to_float(), "label": "P"}], "angle": th if th > 0 else th + TAU, "angle_label": "θ", "radius": true}}
	return {"lines": ["The point (%s, %s) lies on the unit circle, at angle θ from the positive x-axis." % [xt, yt]], "graph": null}


static func _qs(a: Dictionary, vs: Array) -> Array:
	return TrigKit.others(a, vs.map(func(q): return TrigKit.V(q)))


func u_ratio_from_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var sin_: bool = s.fn == "sin"
	var v: Q = s.y if sin_ else s.x
	var o: Q = s.x if sin_ else s.y
	var a := TrigKit.ans("%s θ = " % s.fn, TrigKit.V(v))
	var show := _point_show(rep, s)
	var out := {"answer": a, "lines": show.lines, "graph": show.graph, "asked": "Write down the exact value of %s θ." % s.fn}
	out.wrongs = TrigKit.like(a, TrigKit.V(o), R_COORDS)
	out.generic = _qs(a, [v.neg(), o.neg(), v.div(o), o.div(v), v.mul(o)])
	out.methods = {"read-coordinates": method(["The point is (cos θ, sin θ).", "sin is the y-coordinate: %s" % Fmt.num(v) if sin_ else "cos is the x-coordinate: %s" % Fmt.num(v), say(a)], a.values)}
	return out


func u_tan_from_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v: Q = s.y.div(s.x)
	var a := TrigKit.ans("tan θ = ", TrigKit.V(v))
	var show := _point_show(rep, s)
	var out := {"answer": a, "lines": show.lines, "graph": show.graph, "asked": "Write down the exact value of tan θ."}
	out.wrongs = TrigKit.like(a, TrigKit.V(s.x.div(s.y)), R_COORDS)
	out.generic = _qs(a, [v.neg(), s.x.div(s.y).neg(), s.y, s.x, s.y.mul(s.x)])
	var xt := Fmt.num(s.x)
	var yt := Fmt.num(s.y)
	out.methods = {"read-coordinates": method(["cos θ = %s and sin θ = %s, reading x and y." % [xt, yt], "tan θ = sin θ ÷ cos θ = %s ÷ %s" % [P(s.y), P(s.x)], say(a)], a.values),
		"tan-as-gradient": method(["tan θ is the gradient of OP: rise over run.", "Rise %s, run %s: %s ÷ %s" % [yt, xt, P(s.y), P(s.x)], say(a)], a.values)}
	return out


const BOUNDS := ["0 < θ < π/2", "π/2 < θ < π", "π < θ < 3π/2", "3π/2 < θ < 2π"]


static func signs_text(fn: String, fn2: String, sa: int, sb: int) -> String:
	return "%s θ %s 0 and %s θ %s 0" % [fn, ">" if sa > 0 else "<", fn2, ">" if sb > 0 else "<"]


func u_sign_in_quadrant(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var q: int = s.q
	var sa := TrigKit.sign_in(s.fn, q)
	var sb := TrigKit.sign_in(s.fn2, q)
	var mq := 5 - q
	var sets: Array = [[sa, sb], [sa, -sb], [-sa, sb], [-sa, -sb]]
	var ma := TrigKit.sign_in(s.fn, mq)
	var mb := TrigKit.sign_in(s.fn2, mq)
	var wrongs_in: Array = []
	for pair in sets:
		if pair != [sa, sb]:
			wrongs_in.append([signs_text(s.fn, s.fn2, pair[0], pair[1]), R_CLOCKWISE if pair == [ma, mb] else ""])
	var c := DerivativeMeaningViews.claim_answer(signs_text(s.fn, s.fn2, sa, sb), wrongs_in)
	var a: Dictionary = c.answer
	var out := {"answer": a, "wrongs": c.wrongs, "lines": ["%s" % BOUNDS[q - 1]], "asked": "Which statement is true of θ?"}
	if rep == "diagram":
		out.lines = ["%s: θ ends in the shaded quadrant of the unit circle." % BOUNDS[q - 1]]
		out.graph = {"kind": "unit-circle", "quadrant": q}
	elif rep == "graph":
		out.lines = ["The graphs of y = sin x and y = cos x are shown. θ is between the dashed lines, %s." % BOUNDS[q - 1]]
		var edge := func(i: int) -> Array: return [i * PI / 2.0, ""]
		var g := TrigKit.wave(sin, Q.new(0), Q.new(2), -2, 2, Q.new(1, 2), [], [])
		g.curves.append(Plot.sample(cos, 0.0, TAU))
		g.vlines = [edge.call(q - 1), edge.call(q)].map(func(v): return {"at": v[0], "label": v[1]})
		out.graph = g
	var word := func(sg: int) -> String: return "positive" if sg > 0 else "negative"
	var all: String = ["all three", "sin only", "tan only", "cos only"][q - 1]
	out.methods = {"cast": method(["θ is in quadrant %d, where CAST makes %s positive." % [q, all], "So %s θ is %s and %s θ is %s." % [s.fn, word.call(sa), s.fn2, word.call(sb)], "So " + a.values.text + "."], a.values),
		"graph-read": method(["On this interval, y = sin x is %s and y = cos x is %s." % [word.call(TrigKit.sign_in("sin", q)), word.call(TrigKit.sign_in("cos", q))], "tan = sin ÷ cos, so tan is %s." % word.call(TrigKit.sign_in("tan", q)), "So " + a.values.text + "."], a.values)}
	return out


func u_tan_undefined(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var at := Fmt.pi(s.t)
	var right := "cos(%s) = 0, so sin ÷ cos divides by zero" % at
	var c := DerivativeMeaningViews.claim_answer(right, [["tan(%s) = 0, because the angle is on an axis" % at, R_TAN_ZERO], ["tan(%s) = 1, because sin and cos are equal there" % at, R_TAN_ZERO],
		["sin(%s) = 0, so tan has no value" % at, ""]])
	var a: Dictionary = c.answer
	var out := {"answer": a, "wrongs": c.wrongs, "asked": "Why does tan(%s) have no value?" % at}
	var ang: float = s.t.to_float() * PI
	if rep == "diagram":
		out.lines = ["The diagram shows the unit circle, with P at angle %s." % at]
		out.graph = {"kind": "unit-circle", "points": [TrigKit.point(ang, "P")], "angle": ang, "angle_label": at, "radius": true}
	else:
		out.lines = ["The graphs of y = sin x and y = cos x are shown, with the dashed line at x = %s." % at]
		var g := TrigKit.wave(sin, Q.new(0), Q.new(2), -2, 2, Q.new(1, 2))
		g.curves.append(Plot.sample(cos, 0.0, TAU))
		g.vlines = [{"at": ang, "label": ""}]
		out.graph = g
	var y := TrigKit.sin_pi(s.t)
	out.methods = {"tan-as-gradient": method(["At %s the radius OP is vertical: P = (0, %s)." % [at, T(y)], "tan θ is the gradient of OP, y ÷ x, and x = 0.", "So " + right + "."], a.values),
		"graph-read": method(["At x = %s the graph of y = cos x crosses the axis, and y = sin x is at %s." % [at, T(y)], "tan = sin ÷ cos needs cos ≠ 0.", "So " + right + "."], a.values)}
	return out
