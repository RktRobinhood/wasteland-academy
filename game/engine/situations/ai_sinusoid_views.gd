class_name AiSinusoidViews
extends ExtensionViews
## The views on the `ai-sinusoid` situation (FAL-1001): one builder per unknown of
## fn-ai-sinusoidal-model (AI-SL2.5.sinusoidal-model). Reading a model a sin(bt) + d or
## a cos(bt) + d in degrees: the amplitude, the period, b from the period, the principal axis
## and the greatest or least value, from the model, its graph or the story. Building it: a, b
## and d from the greatest and least values, the period and where it starts (in words, a third
## of the time as pick the graph). Using it: a value at a time, the first time after a start
## time that it reaches a level, how long in one period it stays above or below a level, the
## number of complete cycles in a span, a changed period or greatest value, and the first time
## two models are equal.
##
## Every question is Paper 2, as every AI paper allows a GDC, in degree mode. A value that
## ends is exact; one that doesn't is to 3 s.f. with the rounding trap. `given` holds the
## situation as plain data.
##
## Representations: "equation" (the story with the model written out), "graph" (the model's
## graph with a maximum and the next minimum marked, or the level drawn) and "words" (the
## story's facts: a centre and a radius, the greatest and least values, the period or the
## times of a maximum and the next minimum, a clock time).

const SK := "AI-SL2.5.sinusoidal-model#"
const R_B_PERIOD := SK + "0"
const R_AMP_MAX := SK + "1"
const R_AXIS_AMP := SK + "2"
const R_RADIAN := SK + "3"
const TY := "fn-ai-sinusoidal-model#"
const R_HALF := TY + "4"
const R_B_FLIP := TY + "5"
const R_SIGN := TY + "6"
const R_OTHER := TY + "7"
const R_BEFORE := TY + "8"
const R_WRONG_WAY := TY + "9"
const S := preload("res://engine/situations/ai_sinusoid.gd")

const UNKNOWNS := ["amplitude", "period", "b-from-period", "principal-axis", "max-min", "build-model", "value-at-time",
	"first-time-level", "time-above-level", "count-cycles", "changed-period-or-axis", "two-models-equal"]
## When each story's clock starts, and its two-site version.
const FROM := {"wheel": "the ride starts", "tide": "midnight", "temp": "midnight", "blade": "the timer starts", "buoy": "the timer starts"}
const TWO := {"wheel": "the heights of seats on two wheels", "tide": "the depths of water at two harbour walls",
	"temp": "the temperatures inside two grain stores", "blade": "the heights of the tips of two turbine blades",
	"buoy": "the heights of two marker buoys above the seabed"}
const WHAT_CHANGES := {"wheel": "wheel", "tide": "tide", "temp": "heating cycle", "blade": "turbine", "buoy": "swell"}


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## Every AI paper allows a GDC: every cell is Paper 2.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = S.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## A GDC's screen: 6 significant figures.
static func W(x: float) -> String:
	return Fmt.work(x, 6)


static func c_of(s: Dictionary) -> Dictionary:
	return S.ctx(s)


static func sym(s: Dictionary) -> String:
	return c_of(s).sym


## A value with its unit: "42 m", "18.5 °C".
static func U(s: Dictionary, v: Variant) -> String:
	return "%s %s" % [D(v) if v is Q else W(v), c_of(s).unit]


static func cap(t: String) -> String:
	return t.left(1).to_upper() + t.substr(1)


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func exact_ans(label: String, v: Q, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label, unit)
	ans.show = "dec"
	ans.exact = true
	return ans


static func sf_ans(label: String, x: float, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": GdcKit.qf(x)}, {}, label, unit)
	ans.show = "sf"
	return ans


## Exact when it ends, else to 3 s.f.
static func q_ans(label: String, v: Q, unit: String = "") -> Dictionary:
	return exact_ans(label, v, unit) if S.ends(v) else sf_ans(label, v.to_float(), unit)


## An option's value for an answer made by q_ans.
static func opt(ans: Dictionary, v: Q) -> Dictionary:
	return {"v": S.ends_or_sf(v) if ans.get("exact", false) else GdcKit.qf(v.to_float())}


static func fv(x: float) -> Dictionary:
	return {"v": GdcKit.qf(x)}


static func pack(lines: Array, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary,
		graph: Variant = null) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {},
		"graph": graph, "table": null}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


## "−20 cos(15t) + 22" for the model m.
static func model_text(m: Dictionary) -> String:
	return "%s %s(%st) + %s" % [D(m.a), m.fn, D(m.b), D(m.d)]


static func model_line(s: Dictionary, m: Dictionary = {}) -> String:
	return "%s(t) = %s" % [sym(s), model_text(s if m.is_empty() else m)]


## The model with its letters: "h(t) = a cos(bt) + d".
static func letters(s: Dictionary) -> String:
	return "%s(t) = a %s(bt) + d" % [sym(s), s.fn]


## The story's first line, with the model written out or in letters.
static func intro(s: Dictionary, shown: bool) -> String:
	var c := c_of(s)
	return "%s, %s %s, t %s after %s, is modelled by %s." % [cap(c.thing), c.sym, c.unit,
		c.time, FROM[c.kind], model_line(s) if shown else letters(s)]


## The centre and the size of the swing, in the story's words: d first, then |a|.
static func centre_line(s: Dictionary, d: Q = null) -> String:
	var dd: Q = s.d if d == null else d
	match c_of(s).kind:
		"wheel":
			return "The wheel's centre is %s above the ground and its radius is %s." % [U(s, dd), U(s, s.A)]
		"tide":
			return "The mean depth is %s, and the depth rises and falls %s either side of it." % [U(s, dd), U(s, s.A)]
		"temp":
			return "The mean temperature is %s, and it rises and falls %s either side of it." % [U(s, dd), U(s, s.A)]
		"blade":
			return "The hub is %s above the ground and each blade is %s long." % [U(s, dd), U(s, s.A)]
	return "The buoy's mean height is %s, and the swell lifts and drops it %s either side of that." % [U(s, dd), U(s, s.A)]


static func extremes_line(s: Dictionary) -> String:
	var w: String = c_of(s).what
	return "Its greatest %s is %s and its least %s is %s." % [w, U(s, S.top(s)), w, U(s, S.low(s))]


static func period_line(s: Dictionary, T: int = -1) -> String:
	return "One full cycle takes %d %s." % [s.T if T < 0 else T, c_of(s).time]


static func gap_line(s: Dictionary) -> String:
	return "It reaches its greatest value at t = %s and its next least value at t = %s." % [D(S.t_max(s)), D(S.t_min(s))]


static func start_line(s: Dictionary) -> String:
	match s.start:
		"max":
			return "At t = 0 it is at its greatest value."
		"min":
			return "At t = 0 it is at its least value."
		"up":
			return "At t = 0 it is on its principal axis and rising."
	return "At t = 0 it is on its principal axis and falling."


static func graph_line(s: Dictionary) -> String:
	return "Its graph is shown, with a maximum and the next minimum marked."


static func time_unit(s: Dictionary) -> String:
	return " " + c_of(s).time


static func value_unit(s: Dictionary) -> String:
	return " " + c_of(s).unit


# ── Figures ──────────────────────────────────────────────────

## The model's graph from t = 0 to x1, with its first maximum and the next minimum marked.
static func wave_graph(s: Dictionary, x1: int = -1, mark: bool = true, hlines: Array = [], vlines: Array = [], more: Array = []) -> Dictionary:
	var tm: Q = S.t_max(s)
	var tn: Q = S.t_min(s)
	if x1 < 0:
		x1 = ceili(maxf(1.25 * s.T, tn.to_float() + 0.25 * s.T))
	var curves: Array = [Plot.sample(func(t): return S.val(s, t), 0.0, float(x1))]
	var top: float = S.top(s).to_float()
	for m in more:
		curves.append(Plot.sample(func(t): return S.val(m, t), 0.0, float(x1)))
		top = maxf(top, S.top(m).to_float())
	var pts: Array = []
	if mark:
		pts = [[tm.to_float(), S.top(s).to_float(), "(%s, %s)" % [D(tm), D(S.top(s))]],
			[tn.to_float(), S.low(s).to_float(), "(%s, %s)" % [D(tn), D(S.low(s))]]]
	var g := Plot.spec(curves, pts, 0, x1, 0, ceili(top * 1.15 + 1.0), hlines, vlines)
	g.x_name = "t"
	g.y_name = sym(s)
	return g


# ── The amplitude ────────────────────────────────────────────

## The lines of a reading question: the story with the model, its graph, or its facts.
static func reading(rep: String, s: Dictionary, wk: String) -> Dictionary:
	match rep:
		"graph":
			return {"lines": [intro(s, false), graph_line(s)], "graph": wave_graph(s)}
		"words":
			return {"lines": [intro(s, false), centre_line(s) if wk == "centre" else extremes_line(s)], "graph": null}
	return {"lines": [intro(s, true)], "graph": null}


func u_amplitude(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A: Q = s.A
	var M := S.top(s)
	var m := S.low(s)
	var ans := exact_ans("amplitude = ", A, value_unit(s))
	var v := reading(rep, s, s.wk)
	var steps := {}
	var half := "amplitude = (max − min)/2 = (%s − %s)/2 = %s" % [D(M), D(m), D(A)]
	match rep:
		"equation":
			steps["read-parameters"] = ["In %s, a = %s." % [model_line(s), D(s.a)], "The amplitude is |a| = |%s| = %s." % [D(s.a), D(A)], say(ans)]
			steps["from-max-min"] = ["Graph y = %s in degree mode: its greatest value is %s and its least is %s." % [model_text(s), D(M), D(m)], half, say(ans)]
		"graph":
			steps["read-parameters"] = ["The marked points give the greatest value %s, at t = %s, and the least %s, at t = %s." % [D(M), D(S.t_max(s)), D(m), D(S.t_min(s))],
				"The principal axis is halfway between them, at d = %s; the peak is %s − %s = %s above it." % [D(s.d), D(M), D(s.d), D(A)], say(ans)]
			steps["from-max-min"] = ["From the graph, max = %s and min = %s." % [D(M), D(m)], half, say(ans)]
		_:
			if s.wk == "centre":
				steps["read-parameters"] = ["The model swings %s either side of its middle value %s: |a| = %s." % [U(s, A), U(s, s.d), D(A)], say(ans)]
				steps["from-max-min"] = ["max = %s + %s = %s and min = %s − %s = %s" % [D(s.d), D(A), D(M), D(s.d), D(A), D(m)], half, say(ans)]
			else:
				steps["read-parameters"] = ["The middle value is halfway: d = (%s + %s)/2 = %s." % [D(M), D(m), D(s.d)],
					"The greatest value is |a| above it: |a| = %s − %s = %s." % [D(M), D(s.d), D(A)], say(ans)]
				steps["from-max-min"] = ["max = %s and min = %s" % [D(M), D(m)], half, say(ans)]
	var asked := "Write down the amplitude of the model." if rep == "equation" else "Find the amplitude of the model."
	return pack(v.lines, asked, ans, [wrong({"v": M}, R_AMP_MAX)], [{"v": A.mul(2)}, {"v": s.d}, {"v": m}], steps, v.graph)


# ── The principal axis ───────────────────────────────────────

func u_principal_axis(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A: Q = s.A
	var M := S.top(s)
	var m := S.low(s)
	var ans := exact_ans("y = ", s.d)
	var v := reading(rep, s, s.wk)
	var steps := {}
	var mid := "d = (max + min)/2 = (%s + %s)/2 = %s" % [D(M), D(m), D(s.d)]
	match rep:
		"equation":
			steps["read-parameters"] = ["In %s, d = %s." % [model_line(s), D(s.d)], "The principal axis is the line y = d.", say(ans)]
			steps["from-max-min"] = ["Graph y = %s in degree mode: its greatest value is %s and its least is %s." % [model_text(s), D(M), D(m)], mid, say(ans)]
		"graph":
			steps["read-parameters"] = ["The marked points give the greatest value %s and the least %s." % [D(M), D(m)],
				"The curve rises and falls the same distance either side of its principal axis, so the axis is halfway, %s below the peak: y = %s." % [D(A), D(s.d)], say(ans)]
			steps["from-max-min"] = ["From the graph, max = %s and min = %s." % [D(M), D(m)], mid, say(ans)]
		_:
			if s.wk == "centre":
				steps["read-parameters"] = ["The model swings either side of its middle value, %s: that is d." % U(s, s.d), say(ans)]
				steps["from-max-min"] = ["max = %s + %s = %s and min = %s − %s = %s" % [D(s.d), D(A), D(M), D(s.d), D(A), D(m)], mid, say(ans)]
			else:
				steps["read-parameters"] = ["The principal axis is the middle value, halfway between %s and %s." % [U(s, M), U(s, m)],
					"d = %s − (%s − %s)/2 = %s" % [D(M), D(M), D(m), D(s.d)], say(ans)]
				steps["from-max-min"] = ["max = %s and min = %s" % [D(M), D(m)], mid, say(ans)]
	var asked := "Write down the equation of the principal axis." if rep == "equation" else "Find the equation of the principal axis."
	return pack(v.lines, asked, ans, [wrong({"v": A}, R_AXIS_AMP)], [{"v": M}, {"v": m}, {"v": A.mul(2)}], steps, v.graph)


# ── The greatest or least value ──────────────────────────────

func u_max_min(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A: Q = s.A
	var M := S.top(s)
	var m := S.low(s)
	var hi: bool = s.which == "greatest"
	var key := M if hi else m
	var other := m if hi else M
	var ans := exact_ans("%s value = " % s.which, key, value_unit(s))
	var lines: Array
	var steps := {}
	var sign := "+" if hi else "−"
	var other_name := "least" if hi else "greatest"
	var twice := "The principal axis is halfway between the greatest and least values, so %s = 2d − %s = 2 × %s − %s = %s." % [
		"max" if hi else "min", "min" if hi else "max", D(s.d), D(other), D(key)]
	if rep == "equation":
		lines = [intro(s, true)]
		steps["read-parameters"] = ["a = %s, so |a| = %s, and d = %s." % [D(s.a), D(A), D(s.d)],
			"The %s value is d %s |a| = %s %s %s = %s." % [s.which, sign, D(s.d), sign, D(A), D(key)], say(ans)]
		steps["from-max-min"] = ["The %s value is d %s |a| = %s %s %s = %s." % [other_name, "−" if hi else "+", D(s.d), "−" if hi else "+", D(A), D(other)],
			twice, say(ans)]
	elif s.wk == "radius":
		lines = [intro(s, false), centre_line(s)]
		steps["read-parameters"] = ["d = %s and |a| = %s." % [D(s.d), D(A)],
			"The %s value is d %s |a| = %s %s %s = %s." % [s.which, sign, D(s.d), sign, D(A), D(key)], say(ans)]
		steps["from-max-min"] = ["The %s value is %s %s %s = %s." % [other_name, D(s.d), "−" if hi else "+", D(A), D(other)], twice, say(ans)]
	else:
		var w: String = c_of(s).what
		lines = [intro(s, false), "Its principal axis is at %s, and its %s %s is %s." % [U(s, s.d), other_name, w, U(s, other)]]
		steps["read-parameters"] = ["|a| = %s − %s = %s, the distance from the axis to the %s value." % [D(M if not hi else s.d), D(s.d if not hi else m), D(A), other_name],
			"The %s value is d %s |a| = %s %s %s = %s." % [s.which, sign, D(s.d), sign, D(A), D(key)], say(ans)]
		steps["from-max-min"] = [twice, say(ans)]
	var fill: Array = [{"v": s.d}, {"v": A}, {"v": other}, {"v": s.d.add(A.mul(2)) if hi else s.d.sub(A.mul(2))}]
	if not hi and s.d.sub(A.mul(2)).sign() <= 0:
		fill[3] = {"v": s.d.add(A.mul(2))}
	return pack(lines, "Find the %s value of %s." % [s.which, sym(s)], ans, [], fill, steps)


# ── The period ───────────────────────────────────────────────

## The graph or the words' times of a maximum and the next minimum, and the steps from them
## to the period.
static func gap_steps(s: Dictionary, graph: bool) -> Array:
	var tm: Q = S.t_max(s)
	var tn: Q = S.t_min(s)
	var half := Q.new(s.T, 2)
	var read := "The graph has a maximum at t = %s and the next minimum at t = %s." % [D(tm), D(tn)] if graph \
		else "The greatest value is at t = %s and the next least value at t = %s." % [D(tm), D(tn)]
	return [read, "From a maximum to the next minimum is half a cycle: %s − %s = %s, so the period is 2 × %s = %d." % [D(tn), D(tm), D(half), D(half), s.T]]


func u_period(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var T := Q.new(s.T)
	var ans := exact_ans("period = ", T, time_unit(s))
	var lines: Array
	var graph: Variant = null
	var steps: Array
	var wr: Array = []
	var fill: Array = [{"v": T.mul(2)}]
	match rep:
		"equation":
			lines = [intro(s, true)]
			steps = ["In %s, b = %s." % [model_line(s), D(s.b)], "period = 360/b = 360/%s = %d" % [D(s.b), s.T], say(ans)]
			wr = [wrong({"v": s.b}, R_B_PERIOD)]
			fill.push_front({"v": T.div(2)})
		"graph":
			lines = [intro(s, false), graph_line(s)]
			graph = wave_graph(s)
			steps = gap_steps(s, true) + [say(ans)]
			wr = [wrong({"v": T.div(2)}, R_HALF)]
			fill.append({"v": S.t_min(s)})
		_:
			lines = [intro(s, false), gap_line(s)]
			steps = gap_steps(s, false) + [say(ans)]
			wr = [wrong({"v": T.div(2)}, R_HALF)]
			fill.append({"v": S.t_min(s)})
	var asked := "Write down the period of the model." if rep == "equation" else "Find the period of the model."
	return pack(lines, asked, ans, wr, fill, {"read-parameters": steps}, graph)


# ── b from the period ────────────────────────────────────────

func u_b_from_period(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var bs: Array = S.b_slips(s.T)
	var ans := q_ans("b = ", bs[0])
	var b_line := "b = 360/period = 360/%d = %s" % [s.T, D(bs[0]) if S.ends(bs[0]) else W(bs[0].to_float())]
	var lines: Array
	var graph: Variant = null
	var steps: Array
	var wr: Array = [wrong(opt(ans, bs[1]), R_B_FLIP)]
	if s.wk == "gap":
		wr.append(wrong(opt(ans, bs[2]), R_HALF))
		steps = gap_steps(s, rep == "graph") + [b_line, say(ans)]
		if rep == "graph":
			lines = [intro(s, false), graph_line(s)]
			graph = wave_graph(s)
		else:
			lines = [intro(s, false), gap_line(s)]
	else:
		lines = [intro(s, false), period_line(s)]
		steps = ["The period is %d %s." % [s.T, c_of(s).time], b_line, say(ans)]
	return pack(lines, "Find the value of b.", ans, rng.shuffled(wr), [opt(ans, Q.new(180, s.T)), opt(ans, Q.new(s.T))],
		{"read-parameters": steps}, graph)


# ── Building the model ───────────────────────────────────────

static func sign_reason(s: Dictionary) -> String:
	match s.start:
		"max":
			return "the cosine model starts at its greatest value, so a > 0"
		"min":
			return "the cosine model starts at its least value, so a < 0"
	return "the sine model starts on its principal axis and rises, so a > 0"


## a, b and d as named values.
static func abd(a: Q, b: Q, d: Q) -> Dictionary:
	return {"v0": a, "v1": b, "v2": d}


func u_build_model(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var M := S.top(s)
	var m := S.low(s)
	var lines: Array = [intro(s, false)]
	var graph: Variant = null
	if rep == "graph":
		lines.append(graph_line(s))
		graph = wave_graph(s)
	else:
		lines.append(extremes_line(s))
		lines.append(gap_line(s) if s.wk == "gap" else period_line(s))
		lines.append(start_line(s))
	if s.get("pick", false):
		return _pick_model(s, lines, rng)
	var ans := Answer.make("named", abd(s.a, s.b, s.d), {"names": ["a", "b", "d"]})
	ans.show = "dec"
	ans.exact = true
	var sgn := 1 if s.a.sign() > 0 else -1
	var wr: Array = [wrong(abd(M.mul(sgn), s.b, s.d), R_AMP_MAX), wrong(abd(s.a, s.b, s.A), R_AXIS_AMP),
		wrong(abd(s.a, S.ends_or_sf(Q.new(s.T, 360)), s.d), R_B_FLIP)]
	if s.wk == "gap":
		wr.append(wrong(abd(s.a, Q.new(720, s.T), s.d), R_HALF))
	if s.start == "min":
		wr.append(wrong(abd(s.A, s.b, s.d), R_SIGN))
	var steps: Array = []
	if s.wk == "gap":
		steps.append_array(gap_steps(s, rep == "graph"))
	elif rep == "graph":
		steps.append(gap_steps(s, true)[0])
	steps.append("|a| = (max − min)/2 = (%s − %s)/2 = %s; %s: a = %s." % [D(M), D(m), D(s.A), sign_reason(s), D(s.a)])
	steps.append("d = (max + min)/2 = (%s + %s)/2 = %s, and b = 360/period = 360/%d = %s." % [D(M), D(m), D(s.d), s.T, D(s.b)])
	steps.append(say(ans))
	return pack(lines, "Find the values of a, b and d.", ans, rng.shuffled(wr), [abd(s.a, s.b.mul(2), s.d)], {"from-max-min": steps}, graph)


## Pick the graph: the right card, and three of the slips' cards (the maximum as the amplitude,
## the amplitude as the axis, the half-period as the period, a positive a from the minimum).
func _pick_model(s: Dictionary, lines: Array, rng: Seeded) -> Dictionary:
	var M := S.top(s)
	var x1 := maxi(s.T + int(ceil(s.T / 4.0)), 4)
	var sgn := 1 if s.a.sign() > 0 else -1
	var right := {"fn": s.fn, "a": s.a, "b": s.b, "d": s.d}
	var cand: Array = [
		[{"fn": s.fn, "a": M.mul(sgn), "b": s.b, "d": s.d}, "amp-max", R_AMP_MAX, "its amplitude is the greatest value, %s, so it swings %s either side of %s" % [D(M), D(M), D(s.d)]],
		[{"fn": s.fn, "a": s.a, "b": s.b, "d": s.A}, "axis-amp", R_AXIS_AMP, "its principal axis is at the amplitude, %s, not halfway at %s" % [D(s.A), D(s.d)]],
	]
	if s.wk == "gap":
		cand.append([{"fn": s.fn, "a": s.a, "b": Q.new(720, s.T), "d": s.d}, "half", R_HALF, "its period is %s, the time from a maximum to the next minimum, so it repeats twice as often" % D(Q.new(s.T, 2))])
	if s.start == "min":
		cand.append([{"fn": s.fn, "a": s.A, "b": s.b, "d": s.d}, "sign", R_SIGN, "it starts at its greatest value, not its least"])
	var picked: Array = cand.slice(0, 2)
	var extra: Array = rng.shuffled(cand.slice(2))
	if extra.is_empty():
		# No third slip in this story: a card with the period doubled, the slip no catalogue line names.
		extra = [[{"fn": s.fn, "a": s.a, "b": s.b.div(2), "d": s.d}, "double", "", "its period is %d, twice the period" % (2 * s.T)]]
	picked.append(extra[0])
	var models: Array = [right] + picked.map(func(p): return p[0])
	var lo := 0.0
	var hi := 0.0
	for md in models:
		lo = minf(lo, md.d.to_float() - md.a.abs_q().to_float())
		hi = maxf(hi, md.d.to_float() + md.a.abs_q().to_float())
	var win := [0, x1, floori(lo - 0.12 * (hi - lo)), ceili(hi + 0.12 * (hi - lo))]
	var card := func(md: Dictionary) -> Dictionary:
		var g := GdcKit.card([GdcKit.curve(func(t): return S.val(md, t), 0.0, float(x1))], [], win)
		g.x_name = "t"
		g.y_name = sym(s)
		return g
	var wrongs: Array = []
	for p in picked:
		wrongs.append({"graph": card.call(p[0]), "mistake": p[1], "ref": p[2], "why": p[3]})
	var pk := GdcKit.pick(card.call(right), wrongs, rng)
	var ans: Dictionary = pk.answer
	var steps: Array = []
	if s.wk == "gap":
		steps.append(gap_steps(s, false)[1])
	steps.append("a = %s (%s), d = (%s + %s)/2 = %s and b = 360/%d = %s: %s" % [D(s.a), sign_reason(s), D(M), D(S.low(s)), D(s.d), s.T, D(s.b), model_line(s)])
	steps.append("The right curve swings between %s and %s, repeats every %d %s and, at t = 0, is %s." % [D(S.low(s)), D(M), s.T, c_of(s).time,
		start_line(s).trim_prefix("At t = 0 it is ").trim_suffix(".")])
	steps.append("So %s." % Answer.text(ans))
	return {"lines": lines, "asked": "Which graph shows %s(t) for 0 ≤ t ≤ %d?" % [sym(s), x1], "answer": ans, "graphs": pk.graphs,
		"methods": {"from-max-min": method(steps, ans.values)}}


# ── A value at a time ────────────────────────────────────────

## A clock time from midnight on the quarter hour: "7:30 am", "12:15 am", "1:45 pm".
static func clock(t: Q) -> String:
	var mins := roundi(t.to_float() * 60.0)
	var h := mins / 60
	var mm := mins % 60
	var h12 := h % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, mm, "am" if h < 12 else "pm"]


## "3 minutes 30 seconds", "45 seconds", "4 minutes".
static func min_sec(t: Q) -> String:
	var secs := roundi(t.to_float() * 60.0)
	var m := secs / 60
	var sc := secs % 60
	var parts: Array = []
	if m > 0:
		parts.append("%d minute%s" % [m, "" if m == 1 else "s"])
	if sc > 0:
		parts.append("%d seconds" % sc)
	return " ".join(parts)


func u_value_at_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := S.value_slips(s)
	var c := c_of(s)
	var ans := sf_ans("%s = " % sym(s), v[0], value_unit(s))
	var t0: Q = s.t0
	var lines: Array = [intro(s, true)]
	var asked: String
	var first := ""
	if rep == "words":
		var when: String
		match c.time:
			"hours":
				when = "at " + clock(t0)
				first = "%s is t = %s hours after midnight." % [clock(t0), D(t0)]
			"minutes":
				when = min_sec(t0) + " after the ride starts"
				first = "%s is t = %s minutes." % [cap(min_sec(t0)), D(t0)]
			_:
				when = "%s seconds after the timer starts" % D(t0)
				first = "t = %s seconds." % D(t0)
		asked = "Find %s %s." % [c.thing, when]
	else:
		asked = "Find the value of %s when t = %s." % [sym(s), D(t0)]
	var deg: Q = s.b.mul(t0)
	var steps: Array = []
	if first != "":
		steps.append(first)
	steps.append("In degree mode, b × t = %s × %s = %s°." % [D(s.b), D(t0), D(deg)])
	steps.append("%s(%s) = %s %s(%s°) + %s = %s" % [sym(s), D(t0), D(s.a), s.fn, D(deg), D(s.d), W(v[0])])
	steps.append(say(ans))
	var wr: Array = [wrong(fv(v[1]), R_RADIAN)]
	return pack(lines, asked, ans, wr, [fv(v[2]), fv(v[3])], {"read-parameters": steps})


# ── The first time it reaches a level ────────────────────────

static func times_text(ts: Array) -> String:
	var out: Array = ts.map(func(t): return "t = " + W(t))
	if out.size() == 1:
		return out[0]
	return ", ".join(out.slice(0, -1)) + " and " + out[-1]


func u_first_time_level(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var f := S.first_slips(s)
	var key: float = f.after[0]
	var t0: Q = s.t0
	var ans := sf_ans("t = ", key)
	var x1: int = ceili(t0.to_float() + s.T)
	var lines: Array = [intro(s, true)]
	var graph: Variant = null
	if rep == "graph":
		lines.append("Its graph is shown with the line %s = %s and the start time t = %s." % [sym(s), D(s.L), D(t0)])
		graph = wave_graph(s, x1, false, [[s.L.to_float(), D(s.L)]], [[t0.to_float(), "t = " + D(t0)]])
	var seen: Array = f.before + [key]
	var steps: Array = ["Set the GDC to degree mode and graph y = %s and y = %s for 0 ≤ t ≤ %d." % [model_text(s), D(s.L), x1],
		"The curves meet at %s, and so on." % times_text(seen),
		"The first of these after t = %s is t = %s." % [D(t0), W(key)], say(ans)]
	var wr: Array = rng.shuffled([wrong(fv(f.before[0]), R_BEFORE), wrong(fv(f.rad[0]), R_RADIAN)])
	return pack(lines, "Find the first time after t = %s when the %s is %s." % [D(t0), c_of(s).what, U(s, s.L)], ans, wr,
		[fv(f.after[1]), fv(f.after[2])], {"gdc-intersect": steps}, graph)


# ── How long it stays above or below a level ─────────────────

func u_time_above_level(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var v := S.above_slips(s)
	var c: Array = S.period_crossings(s)
	var word := "above" if s.above else "below"
	var ans := sf_ans("time = ", v[0], time_unit(s))
	var lines: Array = [intro(s, true)]
	var graph: Variant = null
	if rep == "graph":
		lines.append("Its graph is shown for one period, with the line %s = %s." % [sym(s), D(s.L)])
		graph = wave_graph(s, s.T, false, [[s.L.to_float(), D(s.L)]])
	var inside: float = c[1] - c[0]
	var mid_above: bool = S.val(s, (c[0] + c[1]) / 2.0) > s.L.to_float()
	var between := "above" if mid_above else "below"
	var last: String
	if mid_above == s.above:
		last = "time %s = %s − %s = %s" % [word, W(c[1]), W(c[0]), W(v[0])]
	else:
		last = "time %s = %d − (%s − %s) = %s, the rest of the period" % [word, s.T, W(c[1]), W(c[0]), W(v[0])]
	var steps: Array = ["Set the GDC to degree mode and graph y = %s and y = %s for 0 ≤ t ≤ %d, one period (360/%s = %d)." % [model_text(s), D(s.L), s.T, D(s.b), s.T],
		"The curves meet at t = %s and t = %s; between them the model is %s %s." % [W(c[0]), W(c[1]), between, D(s.L)], last, say(ans)]
	var wr: Array = rng.shuffled([wrong(fv(v[1]), R_OTHER), wrong(fv(v[2]), R_RADIAN)])
	return pack(lines, "Find how long, in one period, the %s is %s %s." % [c_of(s).what, word, U(s, s.L)], ans, wr,
		[fv(v[3]), fv(v[4])], {"gdc-intersect": steps}, graph)


# ── Complete cycles ──────────────────────────────────────────

func u_count_cycles(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := S.cycle_slips(s)
	var c := c_of(s)
	var ans := exact_ans("", Q.new(v[0]), " complete cycles")
	var asked: String
	var steps: Array = ["period = 360/b = 360/%s = %d %s" % [D(s.b), s.T, c.time]]
	if rep == "words":
		var big: String = c.big[0]
		var span: String = "%d %s" % [s.span, big if s.span > 1 else big.trim_suffix("s")]
		asked = "How many complete cycles does the model make in the first %s?" % span
		steps.append("%s = %d × %d = %d %s." % [cap(span), s.span, int(c.big[1]), s.total, c.time])
	else:
		asked = "Find the number of complete cycles the model makes for 0 ≤ t ≤ %d." % s.total
	steps.append("%d ÷ %d = %s, so %d complete cycles fit, and part of another." % [s.total, s.T, W(float(s.total) / s.T), v[0]])
	steps.append(say(ans))
	return pack([intro(s, true)], asked, ans, [wrong({"v": Q.new(v[1])}, R_B_PERIOD)], [{"v": Q.new(v[2])}, {"v": Q.new(v[3])}],
		{"read-parameters": steps})


# ── A changed period or axis ─────────────────────────────────

func u_changed_period_or_axis(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var lines: Array
	if rep == "words":
		lines = [intro(s, false), centre_line(s), period_line(s)]
	else:
		lines = [intro(s, true)]
	var what: String = WHAT_CHANGES[c_of(s).kind]
	if s.change == "period":
		var bs := S.changed_b(s)
		var ans := q_ans("b = ", bs[0])
		lines.append("The %s is changed so that one full cycle takes %d %s; nothing else changes." % [what, s.T2, c_of(s).time])
		var steps: Array = []
		if rep == "equation":
			steps.append("Now b = %s, for a period of 360/%s = %d %s." % [D(s.b), D(s.b), s.T, c_of(s).time])
		steps.append("The new period is %d %s." % [s.T2, c_of(s).time])
		steps.append("b = 360/period = 360/%d = %s" % [s.T2, D(bs[0]) if S.ends(bs[0]) else W(bs[0].to_float())])
		steps.append(say(ans))
		var wr: Array = rng.shuffled([wrong(opt(ans, bs[1]), R_B_FLIP), wrong(opt(ans, bs[2]), R_WRONG_WAY)])
		return pack(lines, "Find the new value of b.", ans, wr, [opt(ans, bs[3]), opt(ans, Q.new(180, s.T2))], {"read-parameters": steps})
	var v := S.changed_axis(s)
	var ans2 := exact_ans("y = ", v[0])
	lines.append("The %s is changed so that its greatest %s is %s; its amplitude and period stay the same." % [what, c_of(s).what, U(s, s.M2)])
	var st: Array = []
	if rep == "equation":
		st.append("The amplitude is |a| = |%s| = %s, and it stays the same." % [D(s.a), D(s.A)])
	else:
		st.append("The amplitude is |a| = %s, and it stays the same." % D(s.A))
	st.append("The new principal axis is |a| below the new greatest value: d = %s − %s = %s." % [D(s.M2), D(s.A), D(v[0])])
	st.append(say(ans2))
	return pack(lines, "Find the equation of the new principal axis.", ans2, [], [{"v": v[1]}, {"v": v[2]}, {"v": v[3]}], {"read-parameters": st})


# ── When two models are equal ────────────────────────────────

func u_two_models_equal(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := S.meet_slips(s)
	var m2: Dictionary = s.m2
	var c := c_of(s)
	var ans := sf_ans("t = ", v[0])
	var lines: Array = ["%s₁(t) = %s and %s₂(t) = %s model %s, in %s, t %s after %s." % [c.sym, model_text(s), c.sym, model_text(m2), TWO[c.kind], c.unit, c.time, FROM[c.kind]]]
	var graph: Variant = null
	var x1: int = ceili(maxf(1.25 * maxf(s.T, m2.T), v[0] + 0.25 * minf(s.T, m2.T)))
	if rep == "graph":
		lines.append("The graphs of both models are shown.")
		graph = wave_graph(s, x1, false, [], [], [m2])
	var steps: Array = ["Set the GDC to degree mode and graph y = %s and y = %s for 0 ≤ t ≤ %d." % [model_text(s), model_text(m2), x1],
		"The first intersection after t = 0 is at t = %s, where both are %s." % [W(v[0]), W(S.val(s, v[0]))], say(ans)]
	return pack(lines, "Find the first time t > 0 at which the two models are equal.", ans, [wrong(fv(v[1]), R_RADIAN)],
		[fv(v[2]), fv(v[3])], {"gdc-intersect": steps}, graph)
