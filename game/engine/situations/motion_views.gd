class_name MotionViews
extends ExtensionViews
## The views on the `motion` situation: one builder per unknown of t5-kinematics-motion
## (FAL-724). Paper 1 asks whole-number polynomials, exact; Paper 2 asks a velocity with e or
## sin, to 3 s.f. Most of this type is Paper 2, as most of the bank is. A value is a `form`
## answer in DefiniteIntegralViews' shape, with its unit.
##
## Representations: "equation" (a particle), "words" (a cart on a rail) and "graph".

const SV := "SL5.9.velocity-acceleration#"
const SD := "SL5.9.rest-and-direction#"
const SX := "SL5.9.max-speed#"
const SG := "SL5.9.motion-graphs#"
const R_S_AT_T := SV + "0"
const R_AVERAGE := SV + "1"
const R_CONSTANT_A := SV + "2"
const R_A_ZERO := SD + "0"
const R_A_POSITIVE := SD + "1"
const R_TOUCH := SD + "2"
const R_VELOCITY := SX + "0"
const R_ENDS := SX + "1"
const R_V_ZERO := SX + "2"
const R_HEIGHT := SG + "0"
const R_SLOPE := SG + "1"
const R_POSITIVE_AREA := SG + "2"
const UNKNOWNS := ["velocity-expression", "acceleration-expression", "velocity-at-time", "acceleration-at-time", "time-from-acceleration",
	"time-from-velocity", "first-at-rest", "change-direction", "returns-to-start", "moving-one-way", "acceleration-at-rest", "speeding-up",
	"max-velocity-quadratic", "max-velocity", "max-speed", "acceleration-at-max-speed", "max-acceleration", "speed-from-graph",
	"acceleration-from-graph", "velocity-from-graph", "displacement-from-graph", "direction-from-graph"]
const V_UNIT := " m/s"
const A_UNIT := " m/s²"
const T_UNIT := " s"


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## A GDC method and a model are Paper 2, and an expression is Paper 1; the rest make both, so
## the type lands on the bank's share.
func papers(unknown: String, _rep: String, angle: String) -> Array:
	if not has(unknown):
		return []
	if angle.begins_with("gdc-") or unknown in ["time-from-velocity", "max-velocity", "acceleration-at-max-speed", "max-acceleration"]:
		return [2]
	if unknown in ["velocity-expression", "acceleration-expression", "returns-to-start", "max-velocity-quadratic"]:
		return [1]
	return [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = MotionSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func pack(lines: Array, asked: String, ans: Dictionary, wr: Array, gen: Array, methods: Dictionary, graph: Variant = null) -> Dictionary:
	return DefiniteIntegralViews.pack(lines, asked, ans, wr, gen, methods, graph)


static func p2(s: Dictionary) -> bool:
	return int(s.paper) == 2


## A number as this paper writes it, in the working.
static func Wr(s: Dictionary, x: Variant) -> String:
	return GdcKit.W(x) if p2(s) else Fmt.num(Q.new(roundi(x)))


static func val(s: Dictionary, x: float, head: String, tail: String) -> Dictionary:
	return DefiniteIntegralViews.val(x if p2(s) else Q.new(roundi(x)), p2(s), head, tail)


static func like(ans: Dictionary, x: float, ref: String = "") -> Dictionary:
	var sf: bool = not ans.exact
	return DefiniteIntegralViews.like(ans, x if sf else Q.new(roundi(x)), ref)


static func fl(ans: Dictionary, list: Array) -> Array:
	return list.map(func(x): return like(ans, x).values)


## The velocity as the question writes it.
static func v_text(s: Dictionary) -> String:
	match s.fam:
		"pulse":
			return "%st e^(−%st) − %d" % [Fmt.lead(s.A), Fmt.dec(s.k), s.B]
		"wave":
			return "%d sin(%st)%s" % [s.A, wt(s.w), Fmt.plus(s.B)]
		"damped":
			return "%de^(−%st) cos(%st)" % [s.A, Fmt.dec(s.k), wt(s.w)]
	return Fmt.poly(s.vc, "t")


## The number in front of t inside sin or cos: none for 1.
static func wt(w: Q) -> String:
	return "" if w.eq(1) else Fmt.dec(w)


static func a_text(s: Dictionary) -> String:
	return Fmt.poly(MotionSituation.diff(s.vc), "t")


static func s_text(s: Dictionary) -> String:
	match s.fam:
		"s-wave":
			return "%d sin(%st) + %st" % [s.A, Fmt.dec(s.w), Fmt.lead(s.B)]
		"s-exp":
			return "%de^(−%st) + %st" % [s.A, Fmt.dec(s.w), Fmt.lead(s.B)]
	return Fmt.poly(s.sc, "t")


## The opening line: a particle, or a cart on a rail. name is "v" or "s".
static func story(s: Dictionary, rep: String, name: String, text: String) -> String:
	var dom := "for 0 ≤ t ≤ %d" % s.T
	var what := "velocity, in m/s," if name == "v" else "displacement from a fixed point, in metres,"
	if rep == "words":
		return "A cart rolls along a straight rail. Its %s t seconds after it starts is %s(t) = %s, %s." % [what, name, text, dom]
	return "A particle moves in a straight line. Its %s t seconds after it starts is %s(t) = %s, %s." % [what, name, text, dom]


static func v_story(s: Dictionary, rep: String) -> String:
	return story(s, rep, "v", v_text(s))


## The curve of v on [0, T], with the rests marked.
static func v_graph(s: Dictionary) -> Dictionary:
	var v := MotionSituation.v_of(s)
	var T := float(s.T)
	var pts: Array = []
	for z in s.z:
		pts.append([z, 0.0, ("(%s, 0)" % Wr(s, z)) if not p2(s) else ""])
	var c := GdcKit.curve(v, 0.0, T)
	var g := Plot.spec([c], pts, 0, ceili(T) + 1, floori(s.vmin) - 1, ceili(s.vmax) + 1)
	g.x_name = "t"
	g.y_name = "v"
	return g


## A motion graph in straight pieces, with its corners marked.
static func piece_graph(ts: Array, ys: Array, name: String) -> Dictionary:
	var pts: Array = []
	var marks: Array = []
	for i in ts.size():
		pts.append([float(ts[i]), float(ys[i])])
		marks.append([ts[i], ys[i], Fmt.point(ts[i], ys[i])])
	var g := Plot.spec([pts], marks, 0, int(ts[-1]) + 1, mini(int(ys.min()), 0) - 1, maxi(int(ys.max()), 0) + 1)
	g.x_name = "t"
	g.y_name = name
	return g


# ── Differentiating s and v ──────────────────────────────────

func u_velocity_expression(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var co: Array = s.vc
	var head := "v(t) = "
	var mk := func(a: int, b: int, c: int) -> Dictionary:
		return DifferentiationViews.form(head + Fmt.poly([a, b, c], "t"), [head, {"slot": "a"}, "t² + ", {"slot": "b"}, "t + ", {"slot": "c"}], {"a": Q.new(a), "b": Q.new(b), "c": Q.new(c)})
	var ans: Dictionary = mk.call(co[0], co[1], co[2])
	return pack([story(s, rep, "s", s_text(s))], "Find an expression for the velocity.", ans, [],
		[mk.call(co[0] * 2, co[1], co[2]).values, mk.call(co[0], -co[1], co[2]).values, mk.call(-co[0], co[1], -co[2]).values, mk.call(co[0], co[1], co[2] + int(s.s0) + 1).values],
		{"differentiate-displacement": [
			"v = ds/dt, so differentiate s(t) with respect to t.",
			"Each term: bring the power down and take 1 off it. The constant goes."]})


func u_acceleration_expression(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var co: Array = s.vc
	var d := MotionSituation.diff(co)
	var head := "a(t) = "
	var mk := func(a: int, b: int) -> Dictionary:
		return DifferentiationViews.form(head + Fmt.poly([a, b], "t"), [head, {"slot": "a"}, "t + ", {"slot": "b"}], {"a": Q.new(a), "b": Q.new(b)})
	var ans: Dictionary = mk.call(d[0], d[1])
	return pack([v_story(s, rep)], "Find an expression for the acceleration.", ans, [],
		[mk.call(co[0], co[1]).values, mk.call(d[0], -d[1]).values, mk.call(-d[0], d[1]).values, mk.call(d[0], co[2]).values, mk.call(2 * d[0], d[1]).values],
		{"differentiate-displacement": [
			"a = dv/dt, so differentiate v(t) with respect to t.",
			"The result depends on t, so the acceleration is not constant here."]})


func u_velocity_at_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t0: int = s.t0
	var pos: float
	var vel: float
	if p2(s):
		pos = s.pos
		vel = s.vel
	else:
		pos = MotionSituation.poly(s.sc, float(t0))
		vel = MotionSituation.poly(s.vc, float(t0))
	var ans := val(s, vel, "v = ", V_UNIT)
	var wr: Array = [like(ans, pos, R_S_AT_T)]
	if not p2(s) and roundi(pos) % t0 == 0 and not is_equal_approx(pos / t0, vel):
		wr.append(like(ans, pos / t0, R_AVERAGE))
	elif p2(s):
		wr.append(like(ans, pos / t0, R_AVERAGE))
	var ds: String = ""
	if not p2(s):
		ds = "v(t) = %s." % v_text(s)
	elif s.fam == "s-wave":
		ds = "v(t) = %s cos(%st) + %d." % [Fmt.dec(Q.of(s.A).mul(s.w)), Fmt.dec(s.w), s.B]
	else:
		ds = "v(t) = −%se^(−%st) + %d." % [Fmt.dec(Q.of(s.A).mul(s.w)), Fmt.dec(s.w), s.B]
	return pack([story(s, rep, "s", s_text(s))], "Find the velocity when t = %d%s." % [t0, ", to 3 s.f" if p2(s) else ""], ans, wr,
		fl(ans, [vel * 2.0, -vel, vel + pos, pos - vel]),
		{"differentiate-displacement": [
			"Velocity is the derivative of displacement: " + ds,
			"Substitute t = %d: %s." % [t0, Wr(s, vel)]],
		"gdc-dydx": [
			"Graph s against t on the GDC.",
			"dy/dx at t = %d gives %s." % [t0, GdcKit.W(vel)]]})


func u_acceleration_at_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t0: int = s.t0
	var v := MotionSituation.v_of(s)
	var a := MotionSituation.a_of(s)
	var vt: float = v.call(float(t0))
	var at: float = a.call(float(t0))
	var avg: float = (vt - v.call(0.0)) / t0
	var ans := val(s, at, "a = ", A_UNIT)
	var wr: Array = [like(ans, vt, R_S_AT_T)]
	if p2(s) or absf(avg - roundf(avg)) < 1e-9:
		wr.append(like(ans, avg, R_CONSTANT_A))
	return pack([v_story(s, rep)], "Find the acceleration when t = %d%s." % [t0, ", to 3 s.f" if p2(s) else ""], ans, wr,
		fl(ans, [at * 2.0, -at, at + vt, at - vt]),
		{"differentiate-displacement": [
			"Acceleration is the derivative of velocity: find v′(t).",
			"Substitute t = %d: %s." % [t0, Wr(s, at)]],
		"gdc-dydx": [
			"Graph v against t on the GDC.",
			"dy/dx at t = %d gives %s." % [t0, GdcKit.W(at)]]})


func u_time_from_acceleration(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: float = s.target
	var t: float = float(s.t0) if not p2(s) else s.roots[0]
	var ans := val(s, t, "t = ", T_UNIT)
	var shown := Fmt.num(Q.new(roundi(c))) if not p2(s) else Fmt.dec(GdcKit.qf(c))
	return pack([v_story(s, "equation")], "Find the time when the acceleration is %s m/s²%s." % [shown, ", to 3 s.f" if p2(s) else ""], ans, [],
		fl(ans, [t + 1.0, t * 2.0, t + 0.5, absf(t - 1.0) + 0.5]),
		{"differentiate-displacement": [
			"Acceleration is v′(t), so differentiate v(t) and set it equal to %s." % shown,
			"Solve%s: t = %s." % [" on the GDC, with y = v′(t) and y = %s" % shown if p2(s) else "", Wr(s, t)]]})


func u_time_from_velocity(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: float = s.target
	var roots: Array = s.roots
	var t: float = roots[0]
	var ans := val(s, t, "t = ", T_UNIT)
	var shown := Fmt.dec(GdcKit.qf(c))
	var gen: Array = [t + 1.0, t * 2.0, t + 0.5]
	if roots.size() > 1:
		gen.push_front(roots[1])
	return pack([v_story(s, "equation")], "Find the first time when the velocity is %s m/s, to 3 s.f." % shown, ans, [], fl(ans, gen),
		{"gdc-zeros": [
			"Graph y = v(t) and y = %s on the GDC." % shown,
			"The first intersection is at t = %s." % GdcKit.W(t)]})


# ── Rest and direction ───────────────────────────────────────

func u_first_at_rest(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z: Array = s.z
	var t: float = z[0]
	var ans := val(s, t, "t = ", T_UNIT)
	var wr: Array = []
	if p2(s):
		wr.append(like(ans, s.turns[0], R_A_ZERO))
	else:
		wr.append(like(ans, float(s.p + s.q) / 2.0, R_A_ZERO))
	return pack([v_story(s, rep)], "Find the first time at which %s is at rest%s." % ["the cart" if rep == "words" else "the particle", ", to 3 s.f" if p2(s) else ""], ans, wr,
		fl(ans, [z[1], t + 1.0, float(s.T), t * 2.0]),
		{"solve-v-zero": [
			"At rest means v = 0.",
			"Solve v(t) = 0 for t in the interval%s." % (": the GDC gives t = " + GdcKit.W(t) + " first" if p2(s) else ": v factorises as %s(t%s)(t%s)" % [Fmt.lead(3 * int(s.A)), Fmt.plus(-int(s.p)), Fmt.plus(-int(s.q))]),
			"The earlier root is %s." % Wr(s, t)],
		"gdc-zeros": [
			"Graph v against t on the GDC.",
			"Its first zero after t = 0 is at t = %s." % GdcKit.W(t)]})


func u_change_direction(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var touch: bool = s.fam == "touch"
	var t: float = float(s.q) if touch else s.z[0]
	var ans := val(s, t, "t = ", T_UNIT)
	var wr: Array = []
	var g: Variant = v_graph(s) if rep == "graph" else null
	var asked := "Find the time at which the particle changes direction."
	if touch:
		wr.append(like(ans, float(s.p), R_TOUCH))
		wr.append(like(ans, (float(s.p) + 2.0 * s.q) / 3.0, R_A_ZERO))
	else:
		asked = "Find the first time at which the particle changes direction, to 3 s.f."
		wr.append(like(ans, s.turns[0], R_A_ZERO))
	var v := MotionSituation.v_of(s)
	var before: float = v.call(t - 0.25)
	var after: float = v.call(t + 0.25)
	var sg := func(y: float) -> String: return "positive" if y > 0.0 else "negative"
	var gen: Array = [t + 1.0, float(s.T), t + 2.0, t * 2.0]
	if not touch:
		gen.push_front(s.z[1])
	return pack([v_story(s, "equation")], asked, ans, wr, fl(ans, gen),
		{"sign-table": [
			"The particle can only change direction where v = 0: %s." % ", ".join((s.z as Array).map(func(z): return "t = " + Wr(s, z))),
			"v must change sign there. Either side of t = %s, v is %s then %s." % [Wr(s, t), sg.call(before), sg.call(after)],
			"So it turns at t = %s%s." % [Wr(s, t), ", and only touches 0 at t = %d" % s.p if touch else ""]],
		"gdc-zeros": [
			"Graph v against t on the GDC.",
			"It crosses the t-axis at t = %s, going from %s to %s." % [GdcKit.W(t), sg.call(before), sg.call(after)]]}, g)


func u_returns_to_start(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A: int = s.A
	var p: int = s.p
	var q: int = s.q
	var co: Array = [A, -A * (p + q), A * p * q, 0]
	var ans := val(s.merged({"paper": 1}), float(q), "t = ", T_UNIT)
	var dom := q + 1
	var line := "A particle moves in a straight line. Its displacement from its starting point, in metres, t seconds after it starts is s(t) = %s, for 0 ≤ t ≤ %d." % [Fmt.poly(co, "t"), dom]
	return pack([line], "Find the last time at which the particle is back at its starting point.", ans, [],
		[like(ans, p).values, like(ans, q + 1).values, like(ans, p + q).values, like(ans, p * q).values, like(ans, 0).values],
		{"solve-s-zero": [
			"Back at the start means s = 0.",
			"s(t) factorises as %st(t%s)(t%s)." % [Fmt.lead(A), Fmt.plus(-p), Fmt.plus(-q)],
			"Its roots are t = 0, %d and %d, and the last is %d." % [p, q, q]]})


func u_moving_one_way(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z: Array = s.z
	var lo: float = z[0]
	var hi: float = z[1]
	var v := MotionSituation.v_of(s)
	var pos: bool = v.call((lo + hi) / 2.0) > 0.0
	var word := "positive" if pos else "negative"
	var sf := p2(s)
	var txt := func(a: float, b: float) -> String:
		return ("%s < t < %s" % [Fmt.sf(a), Fmt.sf(b)]) if sf else ("%d < t < %d" % [roundi(a), roundi(b)])
	var q := func(x: float) -> Q: return GdcKit.qf(x) if sf else Q.new(roundi(x))
	var mk := func(a: float, b: float) -> Dictionary:
		var ans := DifferentiationViews.form(DefiniteIntegralViews.minus(txt.call(a, b)), ["", {"slot": "lo"}, " < t < ", {"slot": "hi"}], {"lo": q.call(a), "hi": q.call(b)})
		ans.exact = not sf
		return ans
	var ans: Dictionary = mk.call(lo, hi)
	var g: Variant = v_graph(s) if rep == "graph" else null
	var T := float(s.T)
	return pack([v_story(s, "equation")], "Find the interval of time, between its first two rests, on which the particle moves in the %s direction%s." % [word, ", with the ends to 3 s.f" if sf else ""], ans, [],
		[mk.call(0.0, lo).values, mk.call(hi, T).values, mk.call(lo, T).values, mk.call(0.0, hi).values],
		{"sign-table": [
			"v = 0 at t = %s and t = %s." % [Wr(s, lo), Wr(s, hi)],
			"Between them v is %s, so the particle moves in the %s direction." % [word, word]],
		"gdc-zeros": [
			"Graph v against t on the GDC: its zeros are t = %s and t = %s." % [GdcKit.W(lo), GdcKit.W(hi)],
			"The graph is %s the t-axis between them." % ("above" if pos else "below")]}, g)


func u_acceleration_at_rest(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: float = s.z[0]
	var a := MotionSituation.a_of(s)
	var at: float = a.call(t)
	var v := MotionSituation.v_of(s)
	var ans := val(s, at, "a = ", A_UNIT)
	return pack([v_story(s, "equation")], "Find the acceleration when the particle is first at rest%s." % (", to 3 s.f" if p2(s) else ""), ans, [],
		fl(ans, [0.0, t, -at, a.call(0.0), v.call(0.0), at * 2.0]),
		{"solve-v-zero": [
			"First at rest: v = 0 first at t = %s." % Wr(s, t),
			"Acceleration is v′(t). It need not be 0 when v is.",
			"At t = %s it is %s." % [Wr(s, t), Wr(s, at)]],
		"gdc-zeros": [
			"Graph v against t on the GDC: its first zero is t = %s." % GdcKit.W(t),
			"dy/dx there gives the acceleration: %s." % GdcKit.W(at)]})


func u_speeding_up(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t0: int = s.t0
	var v: float = MotionSituation.v_of(s).call(float(t0))
	var a: float = MotionSituation.a_of(s).call(float(t0))
	var same: bool = (v > 0.0) == (a > 0.0)
	var up := "Speeding up: v and a have the same sign."
	var down := "Slowing down: v and a have opposite signs."
	var only := "Speeding up: a is positive." if a > 0.0 else "Slowing down: a is negative."
	var built := DerivativeMeaningViews.claim_answer(up if same else down, [[down if same else up, ""], [only, R_A_POSITIVE],
		["Neither: the speed only changes when v = 0.", ""]])
	var sign := func(y: float) -> String: return "positive" if y > 0.0 else "negative"
	return {"lines": [v_story(s, "equation"), "When t = %d, v = %s and a = %s." % [t0, Fmt.sf(v) if p2(s) else Wr(s, v), Fmt.sf(a) if p2(s) else Wr(s, a)]].map(DefiniteIntegralViews.minus),
		"asked": "Is the particle speeding up or slowing down when t = %d?" % t0, "answer": built.answer, "wrongs": built.wrongs, "generic": [],
		"methods": {"compare-signs": method([
			"v is %s and a is %s." % [sign.call(v), sign.call(a)],
			"The size of v grows when a pushes the same way as v, and shrinks when it pushes against it.",
			Answer.text(built.answer)], built.answer.values)}}


# ── The greatest velocity, speed and acceleration ────────────

func u_max_velocity_quadratic(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var co: Array = s.vc
	var m: float = float(s.p + s.q) / 2.0
	var top := MotionSituation.poly(co, m)
	var ans := val(s, top, "v = ", V_UNIT)
	return pack([v_story(s, "equation")], "Find the maximum velocity.", ans, [like(ans, 0.0, R_V_ZERO)],
		fl(ans, [m, MotionSituation.poly(co, 0.0), MotionSituation.poly(co, float(s.T)), top + 1.0, top * 2.0]),
		{"acceleration-zero": [
			"The maximum of v is where a = 0: v′(t) = %s." % a_text(s),
			"That gives t = %s." % Wr(s, m),
			"v there is %s, and the ends of the interval are lower." % Wr(s, top)],
		"vertex-of-velocity": [
			"v is a quadratic that opens down, so its maximum is at its vertex.",
			"t = −b/(2a) = %s." % Wr(s, m),
			"v there is %s." % Wr(s, top)]})


func u_max_velocity(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var top: float = s.vmax
	var t: float = s.tmax
	var ans := val(s, top, "v = ", V_UNIT)
	var v := MotionSituation.v_of(s)
	return pack([v_story(s, rep)], "Find the maximum velocity, to 3 s.f.", ans, [],
		fl(ans, [t, v.call(float(s.T)), top * 2.0, top + 1.0, v.call(0.0), s.smax + 1.0]),
		{"acceleration-zero": [
			"The maximum of v is where a = 0 inside the interval, or at an end.",
			"GDC, zeros of v′(t) on the interval: the maximum is at t = %s." % GdcKit.W(t),
			"v there is %s." % GdcKit.W(top)],
		"gdc-max-min": [
			"Graph v against t on the GDC.",
			"The maximum on the interval is at t = %s, with v = %s." % [GdcKit.W(t), GdcKit.W(top)]]})


func u_max_speed(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var top: float = s.smax
	var ans := val(s, top, "Speed = ", V_UNIT)
	var inner := 0.0
	var v := MotionSituation.v_of(s)
	for t in s.turns:
		inner = maxf(inner, absf(v.call(t)))
	var wr: Array = []
	if absf(s.vmax - top) > 1e-6 and s.vmax > 0.0:
		wr.append(like(ans, s.vmax, R_VELOCITY))
	if top - inner > 1e-6 and inner > 0.0:
		wr.append(like(ans, inner, R_ENDS))
	var g: Variant = v_graph(s) if rep == "graph" else null
	var t_: float = s.ts
	return pack([v_story(s, "equation")], "Find the maximum speed of the particle%s." % (", to 3 s.f" if p2(s) else ""), ans, wr,
		fl(ans, [top + 1.0, top * 2.0, absf(v.call(0.0)) + 2.0, absf(s.vmin) + 3.0, 0.5 * top + 1.0]),
		{"acceleration-zero": [
			"Speed is |v|, so the greatest speed is at a turning point of v or at an end of the interval.",
			"The turning points: %s." % ", ".join((s.turns as Array).map(func(t): return "t = " + Wr(s, t))),
			"Compare |v| there, and at t = 0 and t = %d: the greatest is %s, at t = %s." % [s.T, Wr(s, top), Wr(s, t_)]],
		"gdc-max-min": [
			"Graph y = |v(t)| on the GDC, on the interval.",
			"The maximum is %s, at t = %s." % [GdcKit.W(top), GdcKit.W(t_)]]}, g)


func u_acceleration_at_max_speed(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := MotionSituation.a_of(s)
	var at: float = a.call(s.ts)
	var v := MotionSituation.v_of(s)
	var ans := val(s, at, "a = ", A_UNIT)
	return pack([v_story(s, "equation")], "Find the acceleration at the time when the speed is greatest, to 3 s.f.", ans, [],
		fl(ans, [s.smax, s.ts, -at + 1.0, a.call(0.0) + 1.0, at + 2.0]),
		{"gdc-max-min": [
			"Graph y = |v(t)| on the GDC: its maximum on the interval is at t = %s." % GdcKit.W(s.ts),
			"dy/dx of v there gives %s." % GdcKit.W(at)]})


func u_max_acceleration(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var top: float = s.amax
	var ans := val(s, top, "a = ", A_UNIT)
	return pack([v_story(s, "equation")], "Find the maximum acceleration on the interval, to 3 s.f.", ans, [],
		fl(ans, [s.vmax, s.tamax + 1.0, top * 2.0, top + 1.0, -top, s.smax]),
		{"gdc-max-min": [
			"Acceleration is v′(t). Graph it on the GDC, using the derivative of v.",
			"The maximum on the interval is %s, at t = %s." % [GdcKit.W(top), GdcKit.W(s.tamax)]]})


# ── Motion graphs ────────────────────────────────────────────

const G_STORY := "The graph shows the velocity v, in m/s, of a particle moving in a straight line, t seconds after it starts."


func u_speed_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var head := "Maximum velocity "
	var mk := func(x: int, y: int) -> Dictionary:
		var t := "%s%d m/s, maximum speed %d m/s" % [head, x, y]
		return DifferentiationViews.form(t, [head, {"slot": "x"}, " m/s, maximum speed ", {"slot": "y"}, " m/s"], {"x": Q.new(x), "y": Q.new(y)})
	var ans: Dictionary = mk.call(a, maxi(a, b))
	var wr: Array = []
	if b > a:
		wr.append(wrong(mk.call(a, a).values, R_VELOCITY))
	else:
		wr.append(wrong(mk.call(a, b).values, R_VELOCITY))
	var g := piece_graph(s.ts, s.ys, "v")
	return pack([G_STORY], "Find the maximum velocity and the maximum speed.", ans, wr,
		[mk.call(b, a).values, mk.call(a + b, a + b).values, mk.call(a, a + b).values, mk.call(b, b).values, mk.call(a + 1, maxi(a, b)).values],
		{"sign-of-graph": [
			"The maximum velocity is the highest point of the graph: %d m/s." % a,
			"Speed ignores direction, so the lowest point counts too: it is %d m/s below the axis." % b,
			"The greater of %d and %d is the maximum speed." % [a, b]]}, g)


## The straight piece of ts/ys that s.k names, as [t0, t1, gradient].
static func piece(ts: Array, ys: Array, k: int) -> Array:
	var i: int = k % (ts.size() - 1)
	return [ts[i], ts[i + 1], Q.new(int(ys[i + 1]) - int(ys[i]), int(ts[i + 1]) - int(ts[i]))]


func _gradient(s: Dictionary, name: String, story_line: String, head: String, unit: String, what: String) -> Dictionary:
	var ts: Array = s.ts
	var ys: Array = s.ys
	var bit := piece(ts, ys, s.k)
	var t: Q = Q.new(int(bit[0]) + int(bit[1]), 2)
	var slope: Q = bit[2]
	var ans := DefiniteIntegralViews.val(slope, false, head, unit)
	var g := piece_graph(ts, ys, name)
	var h: Q = Q.of(int(ys[ts.find(bit[0])])).add(slope.mul(t.sub(int(bit[0]))))
	var m := {}
	var read := "On this piece the graph is a straight line from t = %d to t = %d." % [bit[0], bit[1]]
	var rise := "Gradient = change in %s ÷ change in t = %s." % [name, N(slope)]
	m["gradient-reading"] = [read, rise]
	m["graph-gradient"] = ["%s is the gradient of the %s–t graph." % [what.capitalize(), name], read + " " + rise]
	return pack([story_line], "Find the %s when t = %s." % [what, t.text()], ans, [],
		DefiniteIntegralViews.vals(ans, [h, slope.neg(), Q.of(int(bit[1]) - int(bit[0])), h.add(1), slope.add(1)]), m, g)


func u_acceleration_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _gradient(s, "v", G_STORY, "a = ", A_UNIT, "acceleration")


func u_velocity_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _gradient(s, "s", "The graph shows the displacement s, in metres, of a particle from a fixed point, t seconds after it starts.", "v = ", V_UNIT, "velocity")


func u_displacement_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ts: Array = s.ts
	var ys: Array = s.ys
	var above := Q.new(0)
	var below := Q.new(0)
	for i in range(1, ts.size()):
		var bit := Q.new((int(ys[i - 1]) + int(ys[i])) * (int(ts[i]) - int(ts[i - 1])), 2)
		if int(ys[i - 1]) + int(ys[i]) >= 0:
			above = above.add(bit)
		else:
			below = below.add(bit)
	var net := above.add(below)
	var T_: int = ts[-1]
	var ans := DefiniteIntegralViews.val(net, false, "", " m")
	return pack([G_STORY], "Find the displacement of the particle from its starting point when t = %d." % T_, ans,
		[DefiniteIntegralViews.like(ans, Q.of(s.a), R_HEIGHT), DefiniteIntegralViews.like(ans, above.sub(below), R_POSITIVE_AREA)],
		DefiniteIntegralViews.vals(ans, [above, below, net.neg(), net.add(1)]),
		{"signed-area": [
			"Displacement is the signed area under the v–t graph.",
			"Above the axis: %s." % N(above),
			"Below the axis: %s." % N(below),
			"Add them: %s." % N(net)]}, piece_graph(ts, ys, "v"))


func u_direction_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ts: Array = s.ts
	var lo: int = ts[3]
	var hi: int = ts[5]
	var mk := func(a: int, b: int) -> Dictionary:
		return DifferentiationViews.form("%d < t < %d" % [a, b], ["", {"slot": "lo"}, " < t < ", {"slot": "hi"}], {"lo": Q.new(a), "hi": Q.new(b)})
	var ans: Dictionary = mk.call(lo, hi)
	return pack([G_STORY], "Find the interval of time when the particle moves in the negative direction.", ans,
		[wrong(mk.call(ts[2], ts[4]).values, R_SLOPE)],
		[mk.call(ts[1], ts[3]).values, mk.call(ts[0], ts[3]).values, mk.call(ts[4], ts[5]).values, mk.call(ts[3], ts[4]).values, mk.call(ts[2], ts[3]).values],
		{"sign-of-graph": [
			"The particle moves in the negative direction where v is negative, below the t-axis.",
			"The graph is below the axis from t = %d to t = %d. The downward slope before that only means v is falling." % [lo, hi]]},
		piece_graph(ts, s.ys, "v"))
