class_name MotionDistanceViews
extends ExtensionViews
## The views on the `motion-distance` situation: one builder per unknown of
## t5-kinematics-distance (FAL-739). Paper 1 asks whole-number polynomials, exact; Paper 2 asks
## a velocity with e or sin, to 3 s.f., and every value is a `form` answer in
## DefiniteIntegralViews' shape, with its unit. The way the motion is written, its curve and a
## graph in straight pieces are MotionViews'.
##
## Representations: "equation" (a particle), "words" (a cart, a drone, a buggy, a sled) and
## "graph" (the curve of v or s with its equation, or a v–t graph in straight pieces).

const SD := "SL5.9.displacement-from-velocity#"
const ST := "SL5.9.total-distance#"
const ME := "t5-kinematics-distance#"
const R_NO_START := SD + "0"
const R_DIFFERENTIATED := SD + "1"
const R_POSITION := SD + "2"
const R_NET := ST + "0"
const R_NO_SPLIT := ST + "1"
const R_SUBTRACTED := ST + "2"
const R_ALL_POSITIVE := "SL5.9.motion-graphs#2"
const R_SIGNED := ME + "7"
const R_TRIP := ME + "8"
const R_FLAT := ME + "9"
const R_V_RISING := ME + "10"
const R_A_ONLY := ME + "11"
const R_HALF := ME + "12"
const R_GONE := ME + "13"
const R_REST_IS_BACK := ME + "14"
const R_USED_DISTANCE := ME + "15"
const R_NO_C := ME + "16"
const R_ADDED := ME + "17"
const R_CHANGE := ME + "18"
const R_CHANGE_SIZE := ME + "19"
const R_NO_SPLIT_STORY := ME + "20"

const UNKNOWNS := ["position-expression", "velocity-from-acceleration", "position-at-time", "displacement-between",
	"position-at-max-velocity", "does-it-return", "initial-displacement", "displacement-increasing", "ridge-distance",
	"race-gap", "position-from-graph", "displacement-at-turn", "distance-from-origin", "total-distance-positions",
	"distance-before-turning", "total-distance-split", "total-distance-gdc", "distance-between-times",
	"distance-from-position", "distance-expression", "speeding-distance-expression", "time-for-distance", "distance-from-graph"]
## Every value here needs a GDC, or the bank only asks it on Paper 2.
const P2_ONLY := ["total-distance-gdc", "distance-between-times", "distance-from-position", "initial-displacement", "ridge-distance", "race-gap"]
## These read the same on a polynomial and on a model.
const BOTH := ["position-at-time", "displacement-between", "position-at-max-velocity", "distance-before-turning", "displacement-increasing"]
const M := " m"
const DIST := "Distance = "
const STORIES := [
	{"say": "A salvage cart runs along a straight rail.", "it": "the cart"},
	{"say": "A courier drone flies along a straight pipeline.", "it": "the drone"},
	{"say": "A patrol buggy drives along a straight causeway.", "it": "the buggy"},
	{"say": "A winch hauls a sled along a straight trench.", "it": "the sled"},
]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## A GDC method is Paper 2. A model can't be integrated by hand here, so integrating with + C
## is Paper 1. The rest follow P2_ONLY and BOTH, and the type lands on the bank's share.
func papers(unknown: String, _rep: String, method_id: String) -> Array:
	if not has(unknown):
		return []
	if method_id.begins_with("gdc-") or unknown in P2_ONLY:
		return [2]
	if unknown in BOTH and method_id != "integrate-with-constant":
		return [1, 2]
	return [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = MotionDistanceSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func pack(lines: Array, asked: String, ans: Dictionary, wr: Array, gen: Array, methods: Dictionary, graph: Variant = null) -> Dictionary:
	var out := DefiniteIntegralViews.pack(lines, asked, ans, wr, gen, methods, graph)
	# "So Distance = 60 m." reads wrongly: these answers already start like a sentence.
	for id in out.methods:
		var steps: Array = out.methods[id].steps
		var last: String = steps[-1]
		if last.begins_with("So " + DIST) or last.begins_with("So Displacement"):
			steps[-1] = last.trim_prefix("So ")
	return out


static func p2(s: Dictionary) -> bool:
	return int(s.paper) == 2


static func Wr(s: Dictionary, x: Variant) -> String:
	return MotionViews.Wr(s, x)


static func val(s: Dictionary, x: float, head: String, tail: String = M) -> Dictionary:
	return MotionViews.val(s, x, head, tail)


static func like(ans: Dictionary, x: float, ref: String = "") -> Dictionary:
	return MotionViews.like(ans, x, ref)


static func fl(ans: Dictionary, list: Array) -> Array:
	return MotionViews.fl(ans, list)


## ", to 3 s.f" on Paper 2, ahead of the full stop.
static func sf3(s: Dictionary) -> String:
	return ", to 3 s.f" if p2(s) else ""


static func opening(s: Dictionary, rep: String) -> String:
	return STORIES[s.ctx].say if rep == "words" else "A particle moves in a straight line."


static func it(s: Dictionary, rep: String) -> String:
	return STORIES[s.ctx].it if rep == "words" else "the particle"


static func v_line(s: Dictionary, rep: String) -> String:
	return "%s Its velocity, in m/s, t seconds after it starts is v(t) = %s, for 0 ≤ t ≤ %d." % [opening(s, rep), MotionViews.v_text(s), s.T]


static func start_line(s: Dictionary) -> String:
	return "Its displacement from a fixed point O is s metres, and s = %d when t = 0." % s.s0


## The opening lines, with the graph's own line where one is drawn.
static func lines_for(s: Dictionary, rep: String, more: Array = []) -> Array:
	var out: Array = [v_line(s, rep)] + more
	if rep == "graph":
		out.append("The graph of v is shown.")
	return out


static func graph_for(s: Dictionary, rep: String) -> Variant:
	return MotionViews.v_graph(s) if rep == "graph" else null


## "s(t) = …" without its constant, from whole coefficients.
static func anti_text(s: Dictionary) -> String:
	var co: Array = (s.sc as Array).slice(0, 3) + [0]
	return Fmt.poly(co, "t")


static func at(s: Dictionary, t: float) -> float:
	return MotionSituation.v_of(s).call(t)


## The times a list of rests reads as: "t = 2, t = 5".
static func rest_list(s: Dictionary, list: Array) -> String:
	return ", ".join(list.map(func(z): return "t = " + Wr(s, z)))


static func leg_sum(s: Dictionary, legs: Array) -> String:
	return " + ".join(legs.map(func(x): return Wr(s, absf(x))))


static func leg_list(s: Dictionary, legs: Array) -> String:
	return ", ".join(legs.map(func(x): return Wr(s, x)))


## An integral from a to b in the working: from the GDC on Paper 2, by hand on Paper 1.
static func gives(s: Dictionary, x: float, a: float, b: float) -> String:
	if p2(s):
		return "The GDC gives %s." % Wr(s, x)
	return "∫ v dt = %s, which gives %s from %s to %s." % [anti_text(s), Wr(s, x), Wr(s, a), Wr(s, b)]


## The "not splitting" slip: a story isn't about a particle.
static func no_split(rep: String) -> String:
	return R_NO_SPLIT_STORY if rep == "words" else R_NO_SPLIT


## A name at the start of a sentence: "The particle".
static func cap(text: String) -> String:
	return text.left(1).to_upper() + text.substr(1)


# ── Position from velocity ───────────────────────────────────

func u_position_expression(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var co: Array = s.sc
	var head := "s(t) = "
	var mk := func(a: int, b: int, c: int, d: int) -> Dictionary:
		return DifferentiationViews.form(head + Fmt.poly([a, b, c, d], "t"), [head, {"slot": "a"}, "t³ + ", {"slot": "b"}, "t² + ", {"slot": "c"}, "t + ", {"slot": "d"}],
			{"a": Q.new(a), "b": Q.new(b), "c": Q.new(c), "d": Q.new(d)})
	var ans: Dictionary = mk.call(co[0], co[1], co[2], co[3])
	var t0: int = s.t0
	var shown := roundi(MotionSituation.poly(co, float(t0)))
	var part: int = shown - int(co[3])
	var fix := "When t = 0, s = C, so C = %d." % co[3]
	if t0 != 0:
		fix = "Put in t = %d, s = %d: %d + C = %d, so C = %d." % [t0, shown, part, shown, co[3]]
	var wr: Array = [DifferentiationViews.alt(head + Fmt.poly(MotionSituation.diff(s.vc), "t"), R_DIFFERENTIATED), wrong(mk.call(co[0], co[1], co[2], 0).values, R_NO_START if t0 == 0 else R_NO_C)]
	return pack([v_line(s, rep), "s is its displacement, in metres, from a fixed point, and s = %d when t = %d." % [shown, t0]],
		"Find an expression for s(t).", ans, wr,
		[mk.call(co[0], co[1], co[2], shown).values, mk.call(3 * int(co[0]), 2 * int(co[1]), co[2], co[3]).values, mk.call(-int(co[0]), -int(co[1]), -int(co[2]), co[3]).values, mk.call(co[0], co[1], co[2], int(co[3]) + 1).values],
		{"integrate-with-constant": [
			"s is the integral of v, one power up on each term: s(t) = %s + C." % anti_text(s),
			fix]})


func u_velocity_from_acceleration(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var head := "v(t) = "
	var mk := func(a: int, b: int, c: int) -> Dictionary:
		return DifferentiationViews.form(head + Fmt.poly([a, b, c], "t"), [head, {"slot": "a"}, "t² + ", {"slot": "b"}, "t + ", {"slot": "c"}], {"a": Q.new(a), "b": Q.new(b), "c": Q.new(c)})
	var p: int = s.p
	var q: int = s.q
	var c: int = s.c
	var t0: int = s.t0
	var vt: int = roundi(s.at)
	var part: int = vt - c
	var ans: Dictionary = mk.call(p, q, c)
	var line := "%s Its acceleration, in m/s², t seconds after it starts is a(t) = %s, and v = %d when t = %d." % [opening(s, rep), Fmt.poly(s.ac, "t"), vt, t0]
	return pack([line], "Find an expression for the velocity, v(t).", ans, [wrong(mk.call(p, q, 0).values, R_NO_C)],
		[mk.call(p, q, vt).values, mk.call(2 * p, q, c).values, mk.call(-p, -q, c).values, mk.call(p, q, c + 1).values, mk.call(p, 2 * q, c).values],
		{"integrate-with-constant": [
			"v is the integral of a, one power up on each term: v(t) = %s + C." % Fmt.poly([p, q, 0], "t"),
			"Put in t = %d, v = %d: %d + C = %d, so C = %d." % [t0, vt, part, vt, c]]})


func u_position_at_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t0: int = s.t0
	var net: float = s.net
	var pos: float = net + float(s.s0)
	var ans := val(s, pos, "s = ")
	var acc: float = MotionSituation.a_of(s).call(float(t0))
	var wr: Array = [like(ans, net, R_NO_START), like(ans, acc, R_DIFFERENTIATED)]
	var ms := {}
	if not p2(s):
		var sc: Array = s.sc
		ms["integrate-with-constant"] = [
			"s is the integral of v: s(t) = %s + C." % anti_text(s),
			"s = %d when t = 0, so C = %d." % [s.s0, s.s0],
			"At t = %d, s = %d + %s." % [t0, sc[3], Fmt.paren(roundi(net))]]
	ms["start-plus-change"] = [
		"The position is the start plus the change: s(%d) = s(0) + ∫ from 0 to %d of v(t) dt." % [t0, t0],
		gives(s, net, 0.0, float(t0)),
		"s = %d + %s." % [s.s0, Fmt.paren(roundi(net)) if not p2(s) else ("(%s)" % Wr(s, net) if net < 0.0 else Wr(s, net))]]
	if p2(s):
		ms["gdc-integral"] = [
			"Enter ∫ from 0 to %d of v(t) dt on the GDC: %s." % [t0, GdcKit.W(net)],
			"Add the start: %d + %s." % [s.s0, "(%s)" % GdcKit.W(net) if net < 0.0 else GdcKit.W(net)]]
	return pack(lines_for(s, rep, [start_line(s)]), "Find the displacement from O when t = %d%s." % [t0, sf3(s)], ans, wr,
		fl(ans, [at(s, float(t0)), -pos, pos + float(s.s0), pos + 1.0, pos * 2.0]), ms, graph_for(s, rep))


func u_displacement_between(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.ta
	var b: int = s.tb
	var net: float = s.net
	var ans := val(s, net, DIST.replace("Distance", "Displacement"))
	var ms := {}
	ms["change-integral"] = [
		"The displacement between two times is the change in s: ∫ from %d to %d of v(t) dt. The start plays no part." % [a, b],
		gives(s, net, float(a), float(b))]
	if p2(s):
		ms["gdc-integral"] = [
			"The displacement between two times is ∫ from %d to %d of v(t) dt." % [a, b],
			"The GDC gives %s." % GdcKit.W(net)]
	return pack(lines_for(s, rep, [start_line(s)]), "Find the displacement of %s between t = %d and t = %d%s." % [it(s, rep), a, b, sf3(s)], ans,
		[like(ans, s.pos, R_POSITION)],
		fl(ans, [at(s, float(b)) - at(s, float(a)), -net, net + 2.0, net * 2.0]), ms, graph_for(s, rep))


func u_position_at_max_velocity(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: float = s.t
	var net: float = s.net
	var pos: float = net + float(s.s0)
	var ans := val(s, pos, "s = ")
	var find := "a = v′(t) = %s, which is 0 at t = %d. v is a quadratic that opens down, so that is its maximum." % [MotionViews.a_text(s), s.m] if not p2(s) else "The GDC's maximum of v on the interval is at t = %s." % GdcKit.W(t)
	var add := "s = %d + %s." % [s.s0, ("(%s)" % Wr(s, net)) if net < 0.0 else Wr(s, net)]
	var ms := {"start-plus-change": [find, "Find ∫ from 0 to %s of v(t) dt. %s" % [Wr(s, t), gives(s, net, 0.0, t)], add]}
	if p2(s):
		ms["gdc-integral"] = [find, "Enter ∫ from 0 to %s of v(t) dt: %s." % [GdcKit.W(t), GdcKit.W(net)], add]
	return pack(lines_for(s, rep, [start_line(s)]), "Find the displacement from O at the time when the velocity is greatest%s." % sf3(s), ans,
		[like(ans, net, R_NO_START)],
		fl(ans, [at(s, t), pos + float(s.s0), -pos, pos + 2.0, pos * 2.0]), ms)


func u_does_it_return(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var T: int = s.T
	var r: int = s.r
	var net := roundi(s.net)
	var first := roundi(s.first)
	var dist := roundi(s.dist)
	var yes := "Yes: its displacement from the start is %d m at t = %d and %d m at t = %d, so it passes the start." % [first, r, net, T]
	var no := "No: at t = %d, the end of the interval, its displacement from the start is still %d m." % [T, net]
	var flip_yes := "Yes: it changes direction at t = %d, so it comes back to where it began." % r
	var flip_no := "No: it changes direction at t = %d, so it never comes back to where it began." % r
	var by_dist := ("Yes: it travels %d m in all, more than the %d m out, so it is back." % [dist, absi(first)]) if not s.back else ("No: it travels %d m in all, not 0 m." % dist)
	var other := no if s.back else yes
	var built := DerivativeMeaningViews.claim_answer(DefiniteIntegralViews.minus(yes if s.back else no),
		[[DefiniteIntegralViews.minus(flip_yes if not s.back else flip_no), R_REST_IS_BACK if not s.back else ""], [DefiniteIntegralViews.minus(by_dist), R_USED_DISTANCE],
		[DefiniteIntegralViews.minus(other), ""]])
	var sums := "It moves one way until v = 0 at t = %d, then back, so check s at t = %d and at t = %d." % [r, r, T]
	var read := "s changes sign, so it crossed 0." if s.back else "s has the same sign both times, and it only moves back after t = %d, so it never reaches 0." % r
	var ms := {
		"start-plus-change": [sums,
			"From the start, s(t) = %s: %d m at t = %d and %d m at t = %d." % [anti_text(s), first, r, net, T],
			read, Answer.text(built.answer)],
	}
	var lines := lines_for(s, rep, ["The particle starts at a fixed point O."])
	return {"lines": lines.map(DefiniteIntegralViews.minus), "asked": "Determine whether the particle gets back to O during 0 ≤ t ≤ %d." % T, "answer": built.answer,
		"wrongs": built.wrongs, "generic": [], "graph": graph_for(s, rep),
		"methods": {"start-plus-change": method(ms["start-plus-change"].map(DefiniteIntegralViews.minus), built.answer.values)}}


## s(t) = A cos(wt) + Bt + C, and its derivative.
static func s_text(s: Dictionary) -> String:
	return "%d cos(%st) + %st + %d" % [s.A, Fmt.dec(s.w), Fmt.lead(s.B), s.C]


static func ds_text(s: Dictionary) -> String:
	return "−%s sin(%st) + %d" % [Fmt.dec(Q.of(s.A).mul(s.w)), Fmt.dec(s.w), s.B]


static func s_line(s: Dictionary, rep: String) -> String:
	return "%s Its displacement from a fixed point, in metres, t seconds after it starts is s(t) = %s, for 0 ≤ t ≤ %d." % [opening(s, rep), s_text(s), s.T]


func u_initial_displacement(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var start: int = int(s.A) + int(s.C)
	var ans := DefiniteIntegralViews.val(Q.new(start), false, "s = ", M)
	return pack([s_line(s, rep)], "Find the displacement of %s from the fixed point when t = 0." % it(s, rep), ans, [],
		DefiniteIntegralViews.vals(ans, [Q.new(s.C), Q.new(int(s.B)), Q.new(int(s.A)), Q.new(int(s.A) + int(s.B) + int(s.C)), Q.new(start - int(s.B))]),
		{"substitute-zero": [
			"Put t = 0 in s(t). The term in t is 0, and cos 0 = 1.",
			"s(0) = %d + %d." % [s.A, s.C]]})


func u_displacement_increasing(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var lo: float = s.z[0]
	var hi: float = s.z[1]
	var sf := p2(s)
	var txt := func(a: float, b: float) -> String:
		return ("%s < t < %s" % [Fmt.sf(a), Fmt.sf(b)]) if sf else ("%d < t < %d" % [roundi(a), roundi(b)])
	var qv := func(x: float) -> Q: return GdcKit.qf(x) if sf else Q.new(roundi(x))
	var mk := func(a: float, b: float) -> Dictionary:
		var ans := DifferentiationViews.form(txt.call(a, b), ["", {"slot": "lo"}, " < t < ", {"slot": "hi"}], {"lo": qv.call(a), "hi": qv.call(b)})
		ans.exact = not sf
		return ans
	var ans: Dictionary = mk.call(lo, hi)
	var turn: float = s.turns[0]
	var wr: Array = [wrong(mk.call(0.0, turn).values, R_V_RISING)]
	var T := float(s.T)
	return pack(lines_for(s, rep), "Find the interval of t for which the displacement of the particle is increasing%s." % (", with the ends to 3 s.f" if sf else ""), ans, wr,
		[mk.call(0.0, lo).values, mk.call(hi, T).values, mk.call(lo, T).values, mk.call(0.0, hi).values, mk.call(turn, T).values],
		{"positive-velocity": [
			"Displacement increases when ds/dt = v is positive.",
			"v = 0 at t = %s and t = %s." % [Wr(s, lo), Wr(s, hi)],
			"v is negative at t = 0 and positive between the two rests."]}, graph_for(s, rep))


# ── Two stories on a Paper 2 model ───────────────────────────

func u_ridge_distance(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A: Q = s.A
	var B: Q = s.B
	var k: int = s.k
	var c: int = s.c
	var gap: Q = s.gap
	var ans := DefiniteIntegralViews.val(gap, false, DIST, M)
	var line := "A convoy truck crawls over a row of evenly spaced rubble ridges on a straight road. It is slowest on each ridge and reaches its slowest point on the first ridge at t = %d." % c
	var model := "Its velocity, in m/s, t seconds after it sets off is v(t) = %s − %s cos(π(t − %d)/%d)." % [Fmt.dec(B), Fmt.dec(A), c, k]
	return pack([line, model], "Find the distance between two neighbouring ridges.", ans,
		[DefiniteIntegralViews.like(ans, B.mul(k), R_HALF), DefiniteIntegralViews.like(ans, B.add(A).mul(2 * k), R_FLAT)],
		DefiniteIntegralViews.vals(ans, [B.sub(A).mul(2 * k), A.mul(2 * k), gap.add(10)]),
		{"gdc-integral": [
			"The truck is slowest once each period, so the ridges are one period apart.",
			"The period is 2π ÷ (π/%d) = %d s, and v is always positive, so the distance is an integral." % [k, 2 * k],
			"∫ from %d to %d of v(t) dt on the GDC gives %s." % [c, c + 2 * k, Fmt.dec(gap)]]})


func u_race_gap(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var D: int = s.D
	var tf: float = s.tf
	var gap: float = s.gap
	var x2: float = s.x2
	var ans := DefiniteIntegralViews.val(gap, true, DIST, M)
	var line := "Two buggies, P and Q, race %d metres along a straight causeway. t seconds after the start, the velocity of P, in m/s, is v(t) = %s(1 − e^(−%st)) and the velocity of Q is w(t) = %s(1 − e^(−%st))." % [D, Fmt.dec(s.A), Fmt.dec(s.k), Fmt.dec(s.A2), Fmt.dec(s.k2)]
	return pack([line, "P crosses the finishing line first."], "Find how far Q is from the finishing line when P finishes, to 3 s.f.", ans,
		[DefiniteIntegralViews.like(ans, x2, R_GONE), DefiniteIntegralViews.like(ans, s.flat, R_FLAT)],
		DefiniteIntegralViews.vals(ans, [tf, gap + 2.0, gap * 2.0]),
		{"gdc-integral": [
			"P finishes when ∫ from 0 to T of v(t) dt = %d." % D,
			"Solve that on the GDC: T = %s." % GdcKit.W(tf),
			"Q has then gone ∫ from 0 to T of w(t) dt = %s." % GdcKit.W(x2),
			"It has %d − %s left." % [D, GdcKit.W(x2)]]})


# ── A distance from s(t) ─────────────────────────────────────

static func fall_line(s: Dictionary, rep: String) -> String:
	return "%s Its displacement from the origin, in metres, t seconds after it starts is s(t) = %s, for 0 ≤ t ≤ %d." % [opening(s, rep), Fmt.poly(s.sc, "t"), s.T]


## s against t, as a curve.
static func fall_graph(s: Dictionary) -> Dictionary:
	var co: Array = s.sc
	var f := func(t: float) -> float: return MotionSituation.poly(co, t)
	var T := float(s.T)
	var g := Plot.spec([GdcKit.curve(f, 0.0, T)], [], 0, ceili(T) + 1, mini(int(s.end), 0) - 2, int(s.top) + 2)
	g.x_name = "t"
	g.y_name = "s"
	return g


static func fall_lines(s: Dictionary, rep: String) -> Array:
	var out: Array = [fall_line(s, rep)]
	if rep == "graph":
		out.append("The graph of s is shown.")
	return out


static func fall_v(s: Dictionary) -> String:
	return "v = s′(t) = %s, which is 0 at t = %d." % [Fmt.poly(MotionSituation.diff(s.sc), "t"), s.q]


func u_displacement_at_turn(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := val(s, float(s.top), "s = ")
	return pack(fall_lines(s, rep), "Find the displacement of the particle from the origin at the time it changes direction.", ans, [],
		fl(ans, [float(s.q), 2.0 * s.c * s.q, float(s.end), float(s.top) + float(s.c), float(s.dist)]),
		{"track-positions": [
			"It changes direction where v = 0: " + fall_v(s),
			"s(%d) = %d." % [s.q, s.top]]}, fall_graph(s) if rep == "graph" else null)


func u_distance_from_origin(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var end: int = s.end
	var ans := val(s, float(-end), DIST)
	return pack(fall_lines(s, rep), "Find the distance of the particle from the origin when t = %d." % s.T, ans,
		[like(ans, float(end), R_SIGNED), like(ans, float(s.dist), R_TRIP)],
		fl(ans, [float(s.top), float(-end + s.top), float(s.T), float(-end) + 2.0]),
		{"track-positions": [
			"s(%d) = %d, so it is past the origin on the negative side." % [s.T, end],
			"A distance is a size, so drop the sign."]}, fall_graph(s) if rep == "graph" else null)


func u_total_distance_positions(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var top: int = s.top
	var end: int = s.end
	var ans := val(s, float(s.dist), DIST)
	return pack(fall_lines(s, rep), "Find the total distance travelled by the particle.", ans,
		[like(ans, float(end), R_CHANGE), like(ans, float(-end), R_CHANGE_SIZE)],
		fl(ans, [float(top), float(top - end + top + 1), float(top - end), float(2 * top)]),
		{"track-positions": [
			fall_v(s).replace("v = s′(t)", "It turns where v = 0: v = s′(t)"),
			"s(0) = 0, s(%d) = %d and s(%d) = %d." % [s.q, top, s.T, end],
			"Add the two legs: %d + %d." % [top, top - end]]}, fall_graph(s) if rep == "graph" else null)


# ── A distance from v(t) ─────────────────────────────────────

## v in brackets, for the working on Paper 1.
static func v_factors(s: Dictionary) -> String:
	if s.shape == "hump":
		return "%s(t + %d)(%d − t)" % [Fmt.lead(3 * int(s.A)), s.u, s.r]
	return "%s(t − %d)(t − %d)" % [Fmt.lead(3 * int(s.A)), s.p, s.q]


func u_distance_before_turning(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: float = s.t
	var d: float = absf(s.net)
	var ans := val(s, d, DIST)
	var find := "It turns where v changes sign: " + ("v = %s, so t = %d." % [v_factors(s), s.r] if not p2(s) else "the GDC's first zero of v is t = %s." % GdcKit.W(t))
	var ms := {"first-leg-integral": [find,
		"It moves one way until then, so one integral covers the trip: ∫ from 0 to %s of v(t) dt." % Wr(s, t),
		gives(s, s.net, 0.0, t) + (" The distance is its size." if s.net < 0.0 else "")]}
	if p2(s):
		ms["gdc-abs-integral"] = [find, "Enter ∫ from 0 to %s of |v(t)| dt on the GDC: %s." % [GdcKit.W(t), GdcKit.W(d)]]
	var whole := MotionDistanceSituation.total(MotionDistanceSituation.legs(s, 0.0, float(s.T)))
	return pack(lines_for(s, rep), "Find the distance %s travels before it first changes direction%s." % [it(s, rep), sf3(s)], ans,
		[like(ans, absf(at(s, 0.0)) * t, R_FLAT)],
		fl(ans, [whole, t, absf(at(s, 0.0)) + 1.0, d * 2.0, d + 2.0]), ms, graph_for(s, rep))


func u_total_distance_split(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var dist: float = s.dist
	var net: float = s.net
	var legs: Array = s.legs
	var ans := val(s, dist, DIST)
	var wr: Array = [like(ans, net, R_NET)]
	# A trip with two rests, split at the first only, is what "not splitting" gives there too.
	wr.append(like(ans, absf(legs[0]) + absf(legs[1] + legs[2]) if legs.size() == 3 else absf(net), R_NO_SPLIT))
	var rests := rest_list(s, s.z)
	var co: Array = (s.sc as Array).slice(0, 3) + [0]
	var positions: Array = [0.0]
	for x in legs:
		positions.append(positions[-1] + x)
	return pack(lines_for(s, rep), "Find the total distance travelled by %s." % it(s, rep), ans, wr,
		fl(ans, [absf(legs[0]), absf(at(s, float(s.T))), dist + 2.0, dist * 2.0]),
		{"split-at-rest": [
			"v = %s, which is 0 at %s, so the direction changes there." % [v_factors(s), rests],
			"Integrate over each piece, using ∫ v dt = %s: %s." % [Fmt.poly(co, "t"), leg_list(s, legs)],
			"Add the sizes: %s." % leg_sum(s, legs)],
		"track-positions": [
			"Take s(t) = %s, so s = 0 at the start. v = 0 at %s." % [Fmt.poly(co, "t"), rests],
			"The positions in turn are %s." % leg_list(s, positions),
			"Add the gaps between them: %s." % leg_sum(s, legs)]}, graph_for(s, rep))


func u_total_distance_gdc(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var dist: float = s.dist
	var net: float = s.net
	var T: int = s.T
	var legs: Array = s.legs
	var ans := val(s, dist, DIST)
	return pack(lines_for(s, rep), "Find the total distance travelled by %s, to 3 s.f." % it(s, rep), ans,
		[like(ans, net, R_NET), like(ans, absf(net), no_split(rep))],
		fl(ans, [absf(legs[0]), dist + 2.0, dist * 2.0, s.smax * float(T)]),
		{"gdc-abs-integral": [
			"Speed is |v|, so the distance is ∫ from 0 to %d of |v(t)| dt." % T,
			"The GDC gives %s." % GdcKit.W(dist)],
		"split-at-rest": [
			"The GDC's zeros of v: %s." % rest_list(s, s.z),
			"∫ v dt over each piece gives %s." % leg_list(s, legs),
			"Add the sizes: %s." % leg_sum(s, legs)]}, graph_for(s, rep))


func u_distance_between_times(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t1: float = s.t1
	var t2: float = s.t2
	var dist: float = s.dist
	var ans := val(s, dist, DIST)
	var nth: String = ["first", "second", "third"][int(s.at)]
	var whole := MotionDistanceSituation.total(MotionDistanceSituation.legs(s, 0.0, t2))
	return pack(lines_for(s, rep, ["Let t₁ be the first time the acceleration of %s is 0, and t₂ the %s time it is at rest." % [it(s, rep), nth]]),
		"Find the distance travelled between t = t₁ and t = t₂, to 3 s.f.", ans,
		[like(ans, s.net, R_NET), like(ans, absf(s.net), no_split(rep))],
		fl(ans, [whole, absf(s.legs[0]), dist + 2.0, dist * 2.0]),
		{"gdc-abs-integral": [
			"The GDC's first zero of v′(t) is t₁ = %s." % GdcKit.W(t1),
			"Its zeros of v: %s, so t₂ = %s." % [rest_list(s, s.z), GdcKit.W(t2)],
			"Enter ∫ from t₁ to t₂ of |v(t)| dt: %s. The |v| deals with the turn in between." % GdcKit.W(dist)]}, graph_for(s, rep))


func u_distance_from_position(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var dist: float = s.dist
	var q: float = s.q
	var ans := val(s, dist, DIST)
	var z: Array = s.z
	var find := "v = s′(t) = %s. Its zeros on the GDC are t = %s and t = %s." % [ds_text(s), GdcKit.W(z[0]), GdcKit.W(z[1])]
	return pack([s_line(s, rep), "%s comes to rest for the second time at t = q." % cap(it(s, rep))], "Find the total distance travelled by %s in the first q seconds, to 3 s.f." % it(s, rep), ans,
		[like(ans, s.net, R_CHANGE), like(ans, absf(s.net), R_CHANGE_SIZE)],
		fl(ans, [q, s.s_2, dist + 2.0, dist * 2.0]),
		{"gdc-abs-integral": [
			find,
			"Enter ∫ from 0 to %s of |v(t)| dt: %s." % [GdcKit.W(q), GdcKit.W(dist)]],
		"track-positions": [
			find,
			"s(0) = %s, s(%s) = %s and s(%s) = %s." % [GdcKit.W(s.s_0), GdcKit.W(z[0]), GdcKit.W(s.s_1), GdcKit.W(z[1]), GdcKit.W(s.s_2)],
			"Add the sizes of the legs: %s + %s." % [GdcKit.W(absf(s.legs[0])), GdcKit.W(absf(s.legs[1]))]]})


# ── Expressions ──────────────────────────────────────────────

## "Distance = ∫ from a to b of v(t) dt − ∫ from c to d of v(t) dt", typed by its four limits.
static func two_integrals(a: int, b: int, c: int, d: int) -> Dictionary:
	var tail := " of v(t) dt"
	var text := "%s∫ from %d to %d%s − ∫ from %d to %d%s" % [DIST, a, b, tail, c, d, tail]
	# Not slots a to d: the engine drops an option whose slot a is 0, and a limit often is.
	return DifferentiationViews.form(text, [DIST + "∫ from ", {"slot": "lo1"}, " to ", {"slot": "hi1"}, tail + " − ∫ from ", {"slot": "lo2"}, " to ", {"slot": "hi2"}, tail],
		{"lo1": Q.new(a), "hi1": Q.new(b), "lo2": Q.new(c), "hi2": Q.new(d)})


static func one_integral(a: int, b: int) -> String:
	return "%s∫ from %d to %d of v(t) dt" % [DIST, a, b]


static func added(a: int, b: int, c: int, d: int) -> String:
	return "%s + ∫ from %d to %d of v(t) dt" % [one_integral(a, b), c, d]


func u_distance_expression(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: int = s.r
	var T: int = s.T
	var ans := two_integrals(0, r, r, T)
	return pack(lines_for(s, rep), "Write down an expression for the total distance travelled by %s. Do not evaluate it." % it(s, rep), ans,
		[DifferentiationViews.alt(one_integral(0, T), R_NET)],
		[two_integrals(r, T, 0, r).values, two_integrals(0, T, 0, r).values, two_integrals(0, r, 0, T).values, two_integrals(0, s.m, s.m, T).values],
		{"split-at-rest": [
			"v = %s, so v changes from positive to negative at t = %d." % [v_factors(s), r],
			"After that v is negative, so its integral is negative. Subtracting it adds a positive distance."]}, graph_for(s, rep))


func u_speeding_distance_expression(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: int = s.r
	var T: int = s.T
	var m: int = s.m
	var ans := two_integrals(0, m, r, T)
	var g: Variant = graph_for(s, rep)
	if rep == "graph":
		g.points.append({"x": float(m), "y": float(s.vmax), "label": Fmt.point(m, roundi(s.vmax))})
	return pack(lines_for(s, rep), "Write down an expression for the distance travelled while the speed of %s is increasing. Do not evaluate it." % it(s, rep), ans,
		[DifferentiationViews.alt(one_integral(0, m), R_A_ONLY), DifferentiationViews.alt(added(0, m, r, T), R_ADDED)],
		[two_integrals(m, r, r, T).values, two_integrals(0, m, m, r).values, two_integrals(0, r, r, T).values, two_integrals(m, r, 0, m).values],
		{"split-at-rest": [
			"a = v′(t) = %s, which is 0 at t = %d, and v = 0 at t = %d." % [MotionViews.a_text(s), m, r],
			"Speed rises when v and a have the same sign: both positive for 0 < t < %d, both negative for %d < t < %d." % [m, r, T],
			"On the second stretch v is negative, so subtract its integral to add a positive distance."]}, g)


func u_time_for_distance(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: int = s.r
	var j: int = s.j
	var k: int = s.k
	var d: int = s.d
	var line := "A particle moves in a straight line. Its velocity, in m/s, t seconds after it starts is v(t) = %s, for t ≥ 0." % Fmt.poly(s.vc, "t")
	var ans := DefiniteIntegralViews.val(Q.new(k), false, "k = ", "")
	var half := Q.new(s.b, 2)
	return pack([line, "When t = k, the total distance it has travelled is %d m." % d], "Find the value of k.", ans, [],
		DefiniteIntegralViews.vals(ans, [Q.new(r), Q.new(j), Q.new(k + 1), Q.new(r + 2 * j), Q.new(2 * r)]),
		{"split-at-rest": [
			"v = 0 at t = %d. Up to then it travels ∫ from 0 to %d of v(t) dt = %d m." % [r, r, s.first],
			"That leaves %d − %d = %d m, travelled after it turns." % [d, s.first, s.more],
			"Past the turn, the size of ∫ from %d to k of v(t) dt is %s(k − %d)², and that must be %d." % [r, Fmt.lead(half), r, s.more],
			"So k − %d = %d, and k is the root past the rest." % [r, j]]})


# ── Areas on a v–t graph ─────────────────────────────────────

const G_STORY := "The graph shows the velocity v, in m/s, of a particle moving in a straight line, t seconds after it starts."


func u_distance_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var dist: Q = s.dist
	var net: Q = s.net
	var ans := DefiniteIntegralViews.val(dist, false, DIST, M)
	var ys: Array = s.ys
	var pieces: Array = s.pieces
	return pack([G_STORY], "Find the total distance travelled by the particle in the %d seconds shown." % s.T, ans,
		[DefiniteIntegralViews.like(ans, net, R_SUBTRACTED)],
		DefiniteIntegralViews.vals(ans, [Q.of(ys.max()), Q.of(ys.max()).sub(ys.min()), net.neg(), dist.add(2)]),
		{"area-under-v-t": [
			"Distance is the area between the graph and the t-axis, all counted as positive.",
			"The piece areas, left to right: %s." % ", ".join(pieces.map(func(p): return Fmt.dec(p.abs_q()))),
			"Add them."]}, MotionViews.piece_graph(s.ts, ys, "v"))


func u_position_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var net: Q = s.net
	var dist: Q = s.dist
	var s0: Q = Q.of(s.s0)
	var pos: Q = s0.add(net)
	var ans := DefiniteIntegralViews.val(pos, false, "s = ", M)
	var pieces: Array = s.pieces
	return pack([G_STORY, start_line(s)], "Find the displacement from O when t = %d." % s.T, ans,
		[DefiniteIntegralViews.like(ans, net, R_NO_START), DefiniteIntegralViews.like(ans, s0.add(dist), R_ALL_POSITIVE)],
		DefiniteIntegralViews.vals(ans, [pos.neg(), pos.add(2), Q.of((s.ys as Array).max())]),
		{"start-plus-change": [
			"The change in s is the signed area under the graph: below the axis counts as negative.",
			"The piece areas, left to right: %s." % ", ".join(pieces.map(func(p): return Fmt.dec(p))),
			"They add to %s. Then add the start: %d + %s." % [Fmt.dec(net), s.s0, Fmt.paren(net)]]}, MotionViews.piece_graph(s.ts, s.ys, "v"))
