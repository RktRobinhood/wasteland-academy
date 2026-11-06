class_name TrigWaveViews
extends TrigModelViews
## The views on the `trig-wave` situation (FAL-751): reading a wave, t3-trig-read-features, and using
## a model, t3-trig-model-use. They extend the base situation's views for its stories, graph and
## answers. Paper 1 is exact. Paper 2 is exact where a figure or a model gives it and 3 s.f. with the
## rounding trap where a calculator does.
##
## Representations: "equation" (written out), "graph" (the wave drawn) and "words" (a story). A base
## wave on a figure hides its equation unless the question's method is the GDC.

const R_B := "SL3.7.read-features#0"
const R_AMP := "SL3.7.read-features#11"
const R_TAN_AMP := "SL3.7.read-features#2"
const R_TAN_SIN := "SL3.7.read-features#3"
const R_SIN_TAN := "SL3.7.read-features#4"
const R_NO_D := "SL3.7.read-features#5"
const R_MINUS_SWAP := "SL3.7.read-features#6"
const R_AXIS_AMP := "SL3.7.read-features#7"
const R_IGNORE_MINUS := "SL3.7.read-features#8"
const R_SIN_COS := "SL3.7.read-features#9"
const R_WHEEL_SIGN := "SL3.7.read-features#10"
const R_HALF := "SL3.7.equation-from-graph#0"
const R_DOUBLE := "SL3.7.equation-from-graph#1"
const R_FIRST_ONLY := "SL3.7.model-context#1"
const R_OTHER_SIDE := "SL3.7.model-context#3"
const R_ONE_SIDE := "SL3.7.model-context#4"
const R_ONE_CYCLE := "SL3.7.model-context#5"
const R_C_PEAK := "SL3.7.model-context#6"
const R_D_EXTREME := "SL3.7.model-context#7"
const R_DIVIDE := "SL3.7.model-context#8"
const R_UNIT := "SL3.7.model-context#9"
const R_WHOLE_GAP := "SL3.7.model-context#10"
const R_SIGN := "SL3.7.model-context#11"

const RF_UNKNOWNS := ["amplitude", "period", "amp-period", "principal-axis", "max-value", "min-value", "range", "first-max-x",
	"tan-period", "tan-features", "b-from-graph", "a-d-from-graph", "intercept-gap", "b-from-story", "amp-axis-story", "wheel-a-b"]
## The read-features unknowns a GDC can answer.
const RF_GDC := ["amplitude", "period", "amp-period", "principal-axis", "max-value", "min-value", "range", "first-max-x", "tan-period"]
const MU_UNKNOWNS := ["value-at-time", "exact-value", "first-time-level", "all-times", "duration-above", "duration-below", "duration-span",
	"first-max-time", "high-low-gap", "count-peaks", "count-lows", "interpret-extreme", "reaches-level"]
const GDC := "gdc-graph"


func needs() -> Dictionary:
	var out := {}
	for u in RF_UNKNOWNS + MU_UNKNOWNS:
		out[u] = {"ask": u}
	return out


## The bank's model-use parts are Paper 2 but for one exact value and one "never reaches".
func papers(unknown: String, rep: String, method_id: String) -> Array:
	if not has(unknown):
		return []
	if unknown == "intercept-gap" or unknown == "exact-value":
		return [1]
	if unknown in MU_UNKNOWNS and unknown != "reaches-level":
		return [2]
	# A marked graph has no equation to type in, and the GDC's figure has no marks to read.
	if rep == "graph" and unknown in RF_GDC:
		return [2] if method_id == GDC else [1]
	return [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = TrigWaveSituation.export(s)
	# A GDC's figure has no marks, so the other routes have nothing to read off it.
	if rep == "graph" and s.get("angle", "") == GDC and out.methods.has(GDC):
		out.methods = {GDC: out.methods[GDC]}
	return out


## The last line of a working: a sentence if the answer opens with a word.
static func say(ans: Dictionary) -> String:
	var text := Answer.text(ans)
	return text + "." if text.begins_with("Time") or text.begins_with("Number") or text.begins_with("Amplitude") or text.begins_with("Period") or text.begins_with("Maximum") or text.begins_with("Minimum") else "So " + text + "."


## A number to subtract or add, as a decimal, in brackets if negative.
static func PD(v: Variant) -> String:
	return "(%s)" % D(v) if Q.of(v).sign() < 0 else D(v)


# ── Reading a wave ───────────────────────────────────────────

## A signed coefficient in front of the function: "", "−", "3", "−2.5".
static func lead(a: Q) -> String:
	if a.eq(1):
		return ""
	return "−" if a.eq(-1) else D(a) + " "


## " + 3", " − 2.5", or nothing.
static func tail(d: Q) -> String:
	return "" if d.is_zero() else " %s %s" % ["+" if d.sign() > 0 else "−", D(d.abs_q())]


## b in front of a bracket or an x: "3", "π", "2π/3", "1.3".
static func b_num(s: Dictionary) -> String:
	if s.kind == "pi":
		return Fmt.pi(s.bq)
	return D(s.bq)


## b after a ÷, in brackets if it is a fraction.
static func b_div(s: Dictionary) -> String:
	var b := b_num(s)
	return "(%s)" % b if b.contains("/") else b


## bx: "3x", "x/2", "2x/3", "πx", "πx/6", "1.3x".
static func b_x(s: Dictionary) -> String:
	var b: Q = s.bq
	var top := "" if b.n == 1 else str(b.n)
	match s.kind:
		"x":
			return "%sx%s" % [top, "" if b.d == 1 else "/%d" % b.d]
		"pi":
			return "%sπx%s" % [top, "" if b.d == 1 else "/%d" % b.d]
	return D(b) + "x"


## The bracket: bx, or b(x − c).
static func inside(s: Dictionary) -> String:
	if s.c.is_zero():
		return b_x(s)
	var shift := "x − " + (Fmt.pi(s.c) if s.kind == "x" else D(s.c))
	return shift if s.kind == "x" and s.bq.eq(1) else "%s(%s)" % [b_num(s), shift]


static func wave_text(s: Dictionary) -> String:
	return "%s%s(%s)%s" % [lead(s.a), s.fn, inside(s), tail(s.d)]


## The period: a Q, of π for kind "x", a float's Q for "dec".
static func per(s: Dictionary) -> Q:
	var sized := 1 if s.fn == "tan" else 2
	match s.kind:
		"x", "pi":
			return Q.new(sized).div(s.bq)
		"dec":
			return GdcKit.qf(sized * PI / s.bq.to_float())
	return s.period


## A place across, as the question writes it.
static func at(s: Dictionary, v: Q) -> String:
	if s.kind == "x":
		return Fmt.pi(v)
	return GdcKit.S(v) if s.kind == "dec" else D(v)


## The same at working precision.
static func at_w(s: Dictionary, v: Q) -> String:
	return GdcKit.W(v) if s.kind == "dec" else at(s, v)


## An answer that is one place across, with π after the slot for kind "x".
static func place(s: Dictionary, label: String, v: Q) -> Dictionary:
	if s.kind == "dec":
		var ans := Answer.make("number", {"v": v}, {}, label)
		ans.show = "sf"
		return ans
	return DifferentiationViews.form(label + at(s, v), [label, {"slot": "p"}] + (["π"] if s.kind == "x" else []), {"p": v})


static func place_like(s: Dictionary, label: String, v: Q, ref: String = "") -> Dictionary:
	if s.kind == "dec":
		return wrong({"v": v}, ref)
	return DifferentiationViews.alt(label + at(s, v), ref, {"p": v})


## A wrong option that reads b as the period: in another shape it can only be picked.
static func b_as_period(s: Dictionary, label: String, ref: String = R_B) -> Dictionary:
	if s.kind == "dec":
		return wrong({"v": s.bq}, ref)
	return DifferentiationViews.alt(label + b_num(s), ref)


## A plain exact number, typed.
static func plain(label: String, v: Q) -> Dictionary:
	return num_ans({}, label, v)


## y = f(x), as the figure or the equation shows it. A base wave's equation is shown only for the GDC.
static func read_lines(rep: String, s: Dictionary) -> Array:
	if rep != "graph":
		return ["f(x) = " + wave_text(s)]
	if s.fn == "tan":
		return ["The graph shows part of y = f(x), a tan function. The dashed lines are its asymptotes."]
	if _gdc_shown(rep, s):
		return ["The graph of y = f(x) is shown, where f(x) = %s." % base_text(s)]
	return ["The graph shows part of y = f(x)."]


## Whether a GDC can be used on this question: the equation has to be there to type in.
func _can_gdc(rep: String, s: Dictionary) -> bool:
	return rep != "graph" or _gdc_shown(rep, s)


static func _gdc_shown(_rep: String, s: Dictionary) -> bool:
	return s.get("angle", "") == GDC


## A base wave's equation, Paper 2.
static func base_text(s: Dictionary) -> String:
	return "%s cos(%s(x − %s)) + %s" % [D(s.a), b_text(s), D(s.xmax), D(s.d)]


## The equation a GDC is given.
static func gdc_text(s: Dictionary) -> String:
	return base_text(s) if s.has("xmax") else wave_text(s)


static func read_graph(s: Dictionary) -> Dictionary:
	var g := graph_of(s)
	g.x_name = "x"
	g.y_name = "y"
	if _gdc_shown("graph", s):
		g.points = []
	return g


## tan on one figure: two cycles, or just over, with its asymptotes dashed.
static func tan_graph(s: Dictionary) -> Dictionary:
	var unit := PI if s.kind == "x" else 1.0
	var T: float = per(s).to_float() * unit
	var b: float = PI / T
	var a: float = s.a.to_float()
	var d: float = s.d.to_float()
	var size := absf(a)
	var f := func(x: float) -> float:
		var y: float = a * tan(b * x)
		return d + y if absf(y) <= 3.0 * size else NAN
	var span := 2.2 * T
	var hi: int = ceili(span)
	var top: int = ceili(d + 3.0 * size) + 1
	var bot: int = floori(d - 3.0 * size) - 1
	var mark: Array = [] if _gdc_shown("graph", s) else [[0.0, d, "(0, %s)" % D(s.d)], [T, d, "(%s, %s)" % [at(s, per(s)), D(s.d)]]]
	var g := Plot.spec(TrigKit.branches(Plot.sample(f, 0.0, span)), mark, 0, hi, bot, top, [], [[T / 2.0, ""], [1.5 * T, ""]])
	if s.kind == "x":
		g.x_ticks = TrigKit.pi_ticks(Q.new(0), per(s).mul(2), per(s).div(2))
	g.one_colour = true
	return g


static func read_figure(rep: String, s: Dictionary) -> Variant:
	if rep != "graph":
		return null
	return tan_graph(s) if s.fn == "tan" else read_graph(s)


func _read(rep: String, s: Dictionary, a: Dictionary, asked: String) -> Dictionary:
	return {"answer": a, "lines": read_lines(rep, s), "graph": read_figure(rep, s), "asked": asked}


## The first line of a GDC's working.
static func gdc_step(s: Dictionary) -> String:
	return "Graph y = %s in radian mode." % gdc_text(s)


## The maximum and the minimum on the GDC. A base wave's turning points are whole numbers.
static func gdc_turns(s: Dictionary) -> String:
	var x := first_max(s)
	return "The maximum point is (%s, %s) and the next minimum is (%s, %s)." % [at_w(s, x), D(s.top), at_w(s, along(s, x, 1, 2)), D(s.low)]


## From a figure the numbers are read off the two marked points; from an equation, off its letters.
static func amp_reads(rep: String, s: Dictionary) -> String:
	if rep == "graph":
		return "Half the height from the lowest to the highest point: (%s − %s) ÷ 2 = %s" % [D(s.top), PD(s.low), D(s.a)]
	return "The amplitude is the size of a, the number in front of %s: %s" % [s.fn, D(s.a.abs_q())]


static func amp_base(rep: String, s: Dictionary) -> Array:
	if rep == "graph":
		return ["The base wave runs from −1 to 1, an amplitude of 1, and this one is stretched away from its axis.", "It runs from %s to %s, so the stretch is (%s − %s) ÷ 2 = %s" % [D(s.low), D(s.top), D(s.top), PD(s.low), D(s.a)]]
	return ["%s x has amplitude 1, and multiplying by a stretches it vertically by the size of a." % s.fn, "The stretch is %s, and d moves the wave without changing its height." % D(s.a.abs_q())]


func u_amplitude(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var amp: Q = s.a.abs_q()
	var a := plain("Amplitude = ", amp)
	var out := _read(rep, s, a, "Write down the amplitude of f.")
	out.wrongs = []
	if rep == "graph":
		out.wrongs.append(wrong({"v": s.top.sub(s.low)}, R_DOUBLE))
	if s.a.sign() < 0:
		out.wrongs.append(wrong({"v": s.a}, R_AMP))
	out.wrongs.append(wrong({"v": s.a.add(s.d)}, R_AMP))
	out.generic = [{"v": amp.mul(2)}, {"v": s.d}, {"v": amp.add(1)}, {"v": s.top}]
	out.methods = {"read-parameters": method([amp_reads(rep, s), say(a)], a.values), "transform-base": method(amp_base(rep, s) + [say(a)], a.values)}
	if _can_gdc(rep, s):
		out.methods[GDC] = method([gdc_step(s), gdc_turns(s), "The amplitude is half the height: (%s − %s) ÷ 2 = %s" % [D(s.top), PD(s.low), D(amp)], say(a)], a.values)
	return out


## The period's working: what the method reads, for an equation or a figure.
func per_steps(rep: String, s: Dictionary, a: Dictionary) -> Dictionary:
	var T := per(s)
	var gap := at_w(s, T)
	if rep == "graph":
		var half: Q = T.div(2)
		var read := "The maximum and the next minimum are %s apart, which is half a cycle." % at(s, half)
		return {"read-parameters": method([read, "So the period is 2 × %s = %s" % [at(s, half), gap], say(a)], a.values),
			"transform-base": method(["The base wave has a period of 2π, and b squeezes it across.", read, "So one cycle here takes 2 × %s = %s" % [at(s, half), gap], say(a)], a.values)}
	var f := "Period = 2π ÷ b = 2π ÷ %s = %s" % [b_div(s), gap]
	return {"read-parameters": method(["b is the number in front of x: b = %s" % b_num(s), f, say(a)], a.values),
		"transform-base": method(["%s x has a period of 2π." % s.fn, "Multiplying x by b squeezes the wave across, so its period is divided by b.", f, say(a)], a.values)}


func gdc_period(rep: String, s: Dictionary, a: Dictionary) -> Dictionary:
	var x := first_max(s)
	var T := per(s)
	var next := along(s, x, 1)
	return method([gdc_step(s), "Two maxima in a row are at x = %s and x = %s." % [at_w(s, x), at_w(s, next)], "The period is the gap: %s − %s = %s" % [at_w(s, next), at_w(s, x), at_w(s, T)], say(a)], a.values)


func u_period(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var T := per(s)
	var a := place(s, "Period = ", T)
	var out := _read(rep, s, a, "Find the period of f." if s.kind != "dec" else "Find the period of f, to 3 significant figures.")
	out.wrongs = []
	if rep == "graph":
		out.wrongs.append(place_like(s, "Period = ", T.div(2), R_HALF))
		if s.kind == "x":
			out.wrongs.append(b_as_period(s, "Period = "))
	else:
		out.wrongs.append(b_as_period(s, "Period = "))
		out.wrongs.append(place_like(s, "Period = ", T.div(2), R_SIN_TAN))
	if s.kind == "dec":
		out.wrongs.push_front(wrong({"v": GdcKit.qf(360.0 / s.bq.to_float())}, R_DEGREES))
	out.generic = [place_like(s, "Period = ", T.mul(2)).values, place_like(s, "Period = ", T.mul(3)).values, place_like(s, "Period = ", T.mul(4)).values, place_like(s, "Period = ", T.div(4)).values]
	out.methods = per_steps(rep, s, a)
	if _can_gdc(rep, s):
		out.methods[GDC] = gdc_period(rep, s, a)
	return out


static func amp_per_text(amp: Q, s: Dictionary, T: Q) -> String:
	return "Amplitude = %s, period = %s" % [D(amp), at(s, T)]


func u_amp_period(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var amp: Q = s.a.abs_q()
	var T := per(s)
	var a: Dictionary
	var opt: Callable
	if s.kind == "dec":
		a = named(["Amplitude", "period"], [amp, T], true)
		opt = func(v: Q, t: Q, ref: String = "") -> Dictionary: return wrong(named_vals([v, t]), ref)
	else:
		a = DifferentiationViews.form(amp_per_text(amp, s, T), ["Amplitude = ", {"slot": "a"}, ", period = ", {"slot": "p"}] + (["π"] if s.kind == "x" else []), {"a": amp, "p": T})
		opt = func(v: Q, t: Q, ref: String = "") -> Dictionary: return DifferentiationViews.alt(amp_per_text(v, s, t), ref, {"a": v, "p": t})
	var out := _read(rep, s, a, "Write down the amplitude of f, and find its period." + (" Give the period to 3 significant figures." if s.kind == "dec" else ""))
	out.wrongs = []
	if rep == "graph":
		out.wrongs.append(opt.call(amp, T.div(2), R_HALF))
		out.wrongs.append(opt.call(s.top.sub(s.low), T, R_DOUBLE))
	else:
		out.wrongs.append(opt.call(amp, T.div(2), R_SIN_TAN))
		if s.a.sign() < 0:
			out.wrongs.append(opt.call(s.a, T, R_AMP))
		out.wrongs.append(opt.call(s.a.add(s.d), T, R_AMP))
	out.generic = [opt.call(amp, T.mul(2)).values, opt.call(amp.add(1), T).values, opt.call(amp.mul(2), T).values]
	var st := per_steps(rep, s, a)
	out.methods = {"read-parameters": method([amp_reads(rep, s)] + st["read-parameters"].steps, a.values), "transform-base": method(amp_base(rep, s).slice(1, 2) + st["transform-base"].steps, a.values)}
	if _can_gdc(rep, s):
		var x := first_max(s)
		out.methods[GDC] = method([gdc_step(s), gdc_turns(s), "The amplitude is half the height: (%s − %s) ÷ 2 = %s" % [D(s.top), PD(s.low), D(amp)], "The period is twice the gap: 2 × (%s − %s) = %s" % [at_w(s, along(s, x, 1, 2)), at_w(s, x), at_w(s, T)], say(a)], a.values)
	return out


func u_principal_axis(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := Answer.make("axis", {"var": "y", "h": s.d})
	a.show = "dec"
	a.exact = true
	var amp: Q = s.a.abs_q()
	var out := _read(rep, s, a, "Write down the equation of the principal axis of the graph of f.")
	out.wrongs = [wrong({"var": "y", "h": amp}, R_AXIS_AMP)]
	out.generic = [{"var": "x", "h": s.d}, {"var": "y", "h": s.top}, {"var": "y", "h": s.low}, {"var": "y", "h": Q.new(0)}]
	var mean := "The axis is halfway up: (%s + %s) ÷ 2 = %s" % [D(s.top), PD(s.low), D(s.d)]
	var read: String = mean if rep == "graph" else "The principal axis is y = d, the number added on: d = %s" % D(s.d)
	var base: Array = ["The base wave has the principal axis y = 0.", mean if rep == "graph" else "Adding d lifts the whole wave, so its axis lifts to y = %s." % D(s.d)]
	out.methods = {"read-parameters": method([read, say(a)], a.values), "transform-base": method(base + [say(a)], a.values)}
	if _can_gdc(rep, s):
		out.methods[GDC] = method([gdc_step(s), gdc_turns(s), mean, say(a)], a.values)
	return out


## The maximum or the minimum as the two methods say it.
func extreme(rep: String, s: Dictionary, a: Dictionary, value: Q, big: bool) -> Dictionary:
	var word := "maximum" if big else "minimum"
	var amp: Q = s.a.abs_q()
	var sum := "%s %s %s = %s" % [D(s.d), "+" if big else "−", D(amp), D(value)]
	var out := {}
	if rep == "graph":
		var read := "The %s of the wave is its %s marked point, at height %s." % [word, "highest" if big else "lowest", D(value)]
		out["read-parameters"] = method([read, say(a)], a.values)
		out["transform-base"] = method(["The base wave reaches %s, and this wave is stretched and lifted." % ("1" if big else "−1"), read, say(a)], a.values)
	else:
		out["read-parameters"] = method(["The wave goes %s above and below its axis y = %s." % [D(amp), D(s.d)], "The %s is %s" % [word, sum], say(a)], a.values)
		out["transform-base"] = method(["The base wave reaches %s, and the size of a stretches that to %s." % ["1" if big else "−1", ("" if big else "−") + D(amp)], "d lifts it: %s" % sum, say(a)], a.values)
	if _can_gdc(rep, s):
		out[GDC] = method([gdc_step(s), gdc_turns(s), "The %s value is the y-coordinate: %s" % [word, D(value)], say(a)], a.values)
	return out


func u_max_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := plain("Maximum value = ", s.top)
	var out := _read(rep, s, a, "Write down the maximum value of f.")
	out.wrongs = [wrong({"v": s.a.abs_q()}, R_NO_D)]
	if s.a.sign() < 0 and rep != "graph":
		out.wrongs.push_front(wrong({"v": s.d.add(s.a)}, R_MINUS_SWAP))
	out.generic = [{"v": s.d}, {"v": s.top.add(s.a.abs_q())}, {"v": s.top.add(1)}, {"v": s.low}]
	out.methods = extreme(rep, s, a, s.top, true)
	return out


func u_min_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := plain("Minimum value = ", s.low)
	var out := _read(rep, s, a, "Write down the minimum value of f.")
	out.wrongs = [wrong({"v": s.a.abs_q().neg()}, R_NO_D)]
	if s.a.sign() < 0 and rep != "graph":
		out.wrongs.push_front(wrong({"v": s.d.sub(s.a)}, R_MINUS_SWAP))
	out.generic = [{"v": s.d}, {"v": s.low.sub(s.a.abs_q())}, {"v": s.low.sub(1)}, {"v": s.top}]
	out.methods = extreme(rep, s, a, s.low, false)
	return out


static func range_vals(lo: Q, hi: Q, rel: String = "≤") -> Dictionary:
	return {"lo": lo, "r1": rel, "r2": rel, "hi": hi}


func u_range(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := Answer.make("range2", range_vals(s.low, s.top), {"var": "y"})
	a.show = "dec"
	a.exact = true
	var amp: Q = s.a.abs_q()
	var out := _read(rep, s, a, "Write down the range of f.")
	out.wrongs = [wrong(range_vals(amp.neg(), amp), R_NO_D)]
	out.generic = [range_vals(s.low, s.top, "<"), range_vals(s.d, s.top), range_vals(s.low, s.d), range_vals(s.low.sub(amp), s.top.add(amp))]
	var both := "The maximum is %s and the minimum is %s." % [D(s.top), D(s.low)]
	if rep == "graph":
		var read := "The lowest and highest marked points are at heights %s and %s." % [D(s.low), D(s.top)]
		out.methods = {"read-parameters": method([read, "The wave takes every height between them.", say(a)], a.values),
			"transform-base": method(["The base wave has the range −1 ≤ y ≤ 1, and this wave is that range stretched and lifted.", read, say(a)], a.values)}
	else:
		out.methods = {"read-parameters": method(["The maximum is %s + %s = %s and the minimum is %s − %s = %s." % [D(s.d), D(amp), D(s.top), D(s.d), D(amp), D(s.low)], "The wave takes every height between them.", say(a)], a.values),
			"transform-base": method(["The base wave has the range −1 ≤ y ≤ 1.", "Stretching by %s gives −%s ≤ y ≤ %s, and lifting by d gives %s to %s." % [D(amp), D(amp), D(amp), D(s.low), D(s.top)], say(a)], a.values)}
	if _can_gdc(rep, s):
		out.methods[GDC] = method([gdc_step(s), gdc_turns(s), both, say(a)], a.values)
	return out


## The first x after 0 where a wave peaks.
static func first_max(s: Dictionary) -> Q:
	if s.has("xmax"):
		return s.xmax
	return next_peak(s, s.a.sign() < 0, s.fn)


## A wave's first peak after 0, or where it would be with a's sign ignored or the other function.
static func next_peak(s: Dictionary, flipped: bool, fn: String) -> Q:
	var cycles := Q.new(1, 4) if fn == "sin" else Q.new(0)
	if flipped:
		cycles = cycles.add(Q.new(1, 2))
	if s.kind == "dec":
		return GdcKit.qf(TrigWaveSituation.after(s.c.to_float() + cycles.to_float() * per(s).to_float(), per(s).to_float()))
	var T := per(s)
	var x: Q = s.c.add(T.mul(cycles))
	while x.sign() <= 0:
		x = x.add(T)
	while T.lt(x):
		x = x.sub(T)
	return x


## x plus n/d of a period. A decimal wave's numbers are too long for Q's sums.
static func along(s: Dictionary, x: Q, n: int, d: int = 1) -> Q:
	if s.kind == "dec":
		return GdcKit.qf(x.to_float() + per(s).to_float() * n / d)
	return x.add(per(s).mul(Q.new(n, d)))


static func max_text(s: Dictionary, top: Q, x: Q) -> String:
	return "Maximum = %s, x = %s" % [D(top), at(s, x)]


func u_first_max_x(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x := first_max(s)
	var T := per(s)
	var a: Dictionary
	var opt: Callable
	if s.kind == "dec":
		a = named(["Maximum", "x"], [s.top, x], true)
		opt = func(v: Q, t: Q, ref: String = "") -> Dictionary: return wrong(named_vals([v, t]), ref)
	else:
		a = DifferentiationViews.form(max_text(s, s.top, x), ["Maximum = ", {"slot": "m"}, ", x = ", {"slot": "p"}] + (["π"] if s.kind == "x" else []), {"m": s.top, "p": x})
		opt = func(v: Q, t: Q, ref: String = "") -> Dictionary: return DifferentiationViews.alt(max_text(s, v, t), ref, {"m": v, "p": t})
	var note := " Give each to 3 significant figures." if s.kind == "dec" else ""
	var out := _read(rep, s, a, "Write down the maximum value of f and the smallest positive x at which it occurs." + note)
	var other := along(s, x, 1, 2)
	if T.to_float() < other.to_float():
		other = along(s, other, -1)
	out.wrongs = []
	if rep == "graph":
		out.generic = [opt.call(s.top, other).values, opt.call(s.low, x).values, opt.call(s.top, along(s, x, 1)).values, opt.call(s.d, x).values]
	else:
		var sign_slip: bool = s.a.sign() < 0
		if sign_slip:
			out.wrongs.append(opt.call(s.top, next_peak(s, false, s.fn), R_IGNORE_MINUS))
		out.wrongs.append(opt.call(s.top, next_peak(s, sign_slip, "cos" if s.fn == "sin" else "sin"), R_SIN_COS))
		out.generic = [opt.call(s.top, along(s, x, 1)).values, opt.call(s.d, x).values, opt.call(s.low, x).values, opt.call(s.top, along(s, x, 1, 4)).values]
	var fn_top := "1" if s.a.sign() > 0 else "−1"
	if rep == "graph":
		var read := "The highest marked point is (%s, %s), the first peak after 0." % [at(s, x), D(s.top)]
		out.methods = {"read-parameters": method([read, say(a)], a.values),
			"transform-base": method(["A base wave peaks once every cycle, and this one has moved across and up.", read, say(a)], a.values)}
	else:
		var value := "The maximum value is %s + %s = %s" % [D(s.d), D(s.a.abs_q()), D(s.top)]
		var bracket: String = {"sin1": "π/2", "sin−1": "3π/2", "cos1": "0", "cos−1": "π"}[s.fn + fn_top]
		var where := "%s has to be %s, so the bracket is %s (or that plus a period)." % [s.fn, fn_top, bracket]
		out.methods = {"read-parameters": method([value, where, "The first such x after 0 is %s" % at_w(s, x), say(a)], a.values),
			"transform-base": method(["%s x peaks at x = %s, and a minus sign in front would turn peaks into troughs." % [s.fn, "π/2" if s.fn == "sin" else "0"], value, where + " That first happens after 0 at x = %s" % at_w(s, x), say(a)], a.values)}
	if _can_gdc(rep, s):
		out.methods[GDC] = method([gdc_step(s), "The first maximum point after x = 0 is (%s, %s)." % [at_w(s, x), D(s.top)], say(a)], a.values)
	return out


# ── tan ──────────────────────────────────────────────────────

func u_tan_period(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var T := per(s)
	var a := place(s, "Period = ", T)
	var out := _read(rep, s, a, "Find the period of f." if s.kind != "dec" else "Find the period of f, to 3 significant figures.")
	if rep == "graph" and _gdc_shown(rep, s):
		out.lines = ["The graph of y = f(x) is shown, where f(x) = %s. The dashed lines are its asymptotes." % wave_text(s)]
	out.wrongs = [place_like(s, "Period = ", T.mul(2), R_TAN_SIN), b_as_period(s, "Period = ")]
	out.generic = [place_like(s, "Period = ", T.div(2)).values, place_like(s, "Period = ", T.mul(3)).values, place_like(s, "Period = ", T.mul(4)).values]
	if rep == "graph":
		var read := "The two marked points are on the same part of two branches, %s apart." % at_w(s, T)
		out.methods = {"read-parameters": method([read, "tan repeats from one branch to the next, so that gap is one period.", say(a)], a.values),
			"transform-base": method(["tan x has a period of π, from one asymptote to the next.", read, say(a)], a.values)}
	else:
		var f := "Period = π ÷ b = π ÷ %s = %s" % [b_div(s), at_w(s, T)]
		out.methods = {"read-parameters": method(["b is the number in front of x: b = %s" % b_num(s), f, say(a)], a.values),
			"transform-base": method(["tan x has a period of π, half that of sin x.", "Multiplying x by b divides the period by b.", f, say(a)], a.values)}
	if _can_gdc(rep, s):
		out.methods[GDC] = method(["Graph y = %s in radian mode." % wave_text(s), "It passes through y = %s at x = 0 and next, going the same way, at x = %s." % [D(s.d), at_w(s, T)], say(a)], a.values)
	return out


func u_tan_features(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var T := per(s)
	var amp: Q = s.a.abs_q()
	var said := func(body: String, t: Q) -> String: return "%s, and its period is %s" % [body, at(s, t)]
	var none := "It has no amplitude, as it has no maximum or minimum"
	var cl := DerivativeMeaningViews.claim_answer(said.call(none, T), [
		[said.call("Its amplitude is %s" % D(amp), T), R_TAN_AMP],
		[said.call(none, T.mul(2)), R_TAN_SIN],
		[said.call("Its range is %s ≤ y ≤ %s" % [D(s.d.sub(amp)), D(s.d.add(amp))], T), R_TAN_AMP]])
	var a: Dictionary = cl.answer
	var eq := "f(x) = " + wave_text(s)
	var out := {"answer": a, "wrongs": cl.wrongs, "generic": [], "lines": [eq], "graph": null, "asked": "Which statement about f is true?"}
	if rep == "graph":
		out.lines = ["The graph of y = f(x) is shown, where %s. The dashed lines are its asymptotes." % eq]
		out.graph = tan_graph(s)
	var right: String = Answer.text(a) + "."
	var f := "Period = π ÷ b = π ÷ %s = %s" % [b_div(s), at_w(s, T)]
	out.methods = {"read-parameters": method(["tan rises without limit on each branch, so f has no largest value, and an amplitude needs one.", f, right], a.values),
		"transform-base": method(["tan x has no maximum, and stretching it by %s or lifting it doesn't give it one." % D(amp), "tan x has a period of π, and b divides that: %s" % at_w(s, T), right], a.values)}
	return out


# ── Letters from a figure or a story ─────────────────────────

func u_b_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var T := per(s)
	var w: Variant = s.get("w", 0)
	var a: Dictionary
	var out := {"graph": read_graph(s), "lines": ["The graph shows part of y = a cos(b(x − c)) + d, with a, b > 0."]}
	var half: Q = T.div(2)
	var read := "The maximum and the next minimum are %s apart, so the period is 2 × %s = %s." % [at(s, half), at(s, half), at(s, T)]
	if s.paper == 1:
		a = DifferentiationViews.form("b = " + str(w), ["b = ", {"slot": "v"}], {"v": Q.new(w)})
		out.asked = "Write down the period of the graph, and hence find b."
		out.wrongs = [DifferentiationViews.alt("b = " + Fmt.pi(T), R_PERIOD_B), DifferentiationViews.alt("b = %d" % (2 * w), R_HALF, {"v": Q.new(2 * w)})]
		out.generic = [DifferentiationViews.alt("b = %d" % (w + 1), "", {"v": Q.new(w + 1)}).values, DifferentiationViews.alt("b = %d" % (3 * w), "", {"v": Q.new(3 * w)}).values, DifferentiationViews.alt("b = %d" % (w + 2), "", {"v": Q.new(w + 2)}).values]
	else:
		var b: float = TAU / s.period.to_float()
		a = fnum("b = ", b)
		out.asked = "Write down the period of the graph, and hence find b to 3 significant figures."
		out.wrongs = [wrong({"v": s.period}, R_PERIOD_B), wrong({"v": GdcKit.qf(2.0 * b)}, R_HALF)]
		out.generic = [{"v": GdcKit.qf(b / 2.0)}, {"v": GdcKit.qf(s.period.to_float() / TAU)}, {"v": GdcKit.qf(3.0 * b)}]
	out.answer = a
	var calc := "b = 2π ÷ %s = %s" % [("(%s)" % at(s, T) if at(s, T).contains("/") else at(s, T)), str(w) if s.paper == 1 else GdcKit.W(TAU / s.period.to_float())]
	out.methods = {"read-parameters": method([read, calc, say(a)], a.values),
		"transform-base": method(["cos x has a period of 2π, and b divides that, so the period is 2π ÷ b.", read, calc, say(a)], a.values)}
	return out


func u_a_d_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := named(["a", "d"], [s.a, s.d], false)
	var out := {"answer": a, "graph": read_graph(s), "lines": ["The graph shows part of y = a cos(b(x − c)) + d, with a > 0."], "asked": "Write down the values of a and d."}
	out.wrongs = [wrong(named_vals([s.top.sub(s.low), s.d]), R_DOUBLE), wrong(named_vals([s.d, s.a]), R_AXIS_AMP)]
	out.generic = [named_vals([s.a, s.top]), named_vals([s.a, s.low]), named_vals([s.top, s.d])]
	var r := "a is half the height: (%s − %s) ÷ 2 = %s" % [D(s.top), PD(s.low), D(s.a)]
	var m := "d is halfway up: (%s + %s) ÷ 2 = %s" % [D(s.top), PD(s.low), D(s.d)]
	out.methods = {"read-parameters": method([r, m, say(a)], a.values),
		"transform-base": method(["The base wave runs from −1 to 1: a stretches that and d lifts it.", r, m, say(a)], a.values)}
	return out


## "r", "2r": a tick on the across axis.
static func rs(n: int) -> String:
	return "r" if n == 1 else "%dr" % n


static func r_text(n: int) -> String:
	return "r = π/q" if n == 1 else "r = π/(%dq)" % n


func u_intercept_gap(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var a := DifferentiationViews.form(r_text(n), ["r = π/(", {"slot": "n"}, "q)"], {"n": Q.new(n)})
	var g := Plot.spec([Plot.sample(sin, 0.0, TAU)], [], 0, 7, -2, 2)
	g.x_ticks = [[PI, rs(n)], [TAU, rs(2 * n)]]
	g.y_bare = true
	var out := {"answer": a, "graph": g, "lines": ["f(x) = sin(qx), with q > 0 and x in radians.", "The graph of f crosses the x-axis at x = 0, x = %s and x = %s." % [rs(n), rs(2 * n)]], "asked": "Find an expression for r in terms of q."}
	out.wrongs = [DifferentiationViews.alt("r = 2π/q" if n == 1 else "r = 2π/(%dq)" % n, R_HALF)]
	out.generic = [DifferentiationViews.alt(r_text(2 * n), "", {"n": Q.new(2 * n)}).values, DifferentiationViews.alt(r_text(n + 1), "", {"n": Q.new(n + 1)}).values, DifferentiationViews.alt(r_text(3 * n + 1), "", {"n": Q.new(3 * n + 1)}).values]
	var cycle := "One full cycle runs from x = 0 to x = %s, so the period is %s." % [rs(2 * n), rs(2 * n)]
	var solve := "%s = 2π/q" % rs(2 * n)
	out.methods = {"read-parameters": method([cycle, "The period of sin(qx) is 2π/q, so %s." % solve, say(a)], a.values),
		"transform-base": method(["sin x crosses the axis every π, and multiplying x by q divides that gap by q.", "So neighbouring crossings are π/q apart, and %s = π/q." % rs(n), say(a)], a.values)}
	return out


func u_b_from_story(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var T: Q = s.period
	var out := {"lines": ["%s is modelled by %s(t) = a sin(b(t − c)) + d, with a, b, c > 0 and t in %s." % [c.thing, c.sym, c.time], "It reaches its highest value every %s %s." % [D(T), c.time]]}
	var p := "One cycle takes %s %s, so the period is %s." % [D(T), c.time, D(T)]
	var a: Dictionary
	if s.paper == 1:
		var b: Q = Q.new(2).div(T)
		a = DifferentiationViews.form("b = " + Fmt.pi(b), ["b = ", {"slot": "b"}, "π"], {"b": b})
		out.asked = "Find the exact value of b."
		out.wrongs = [DifferentiationViews.alt("b = " + D(T), R_PERIOD_B), DifferentiationViews.alt("b = " + Fmt.pi(b.mul(2)), R_HALF, {"b": b.mul(2)})]
		out.generic = [DifferentiationViews.alt("b = " + Fmt.pi(b.div(2)), "", {"b": b.div(2)}).values, DifferentiationViews.alt("b = " + Fmt.pi(T), "", {"b": T}).values, DifferentiationViews.alt("b = " + Fmt.pi(b.mul(3)), "", {"b": b.mul(3)}).values]
		out.methods = {"read-parameters": method([p, "b = 2π ÷ %s = %s" % [D(T), Fmt.pi(b)], say(a)], a.values)}
	else:
		var b: float = TAU / T.to_float()
		a = fnum("b = ", b)
		out.asked = "Find b, to 3 significant figures."
		out.wrongs = [wrong({"v": T}, R_PERIOD_B), wrong({"v": GdcKit.qf(2.0 * b)}, R_HALF)]
		out.generic = [{"v": GdcKit.qf(b / 2.0)}, {"v": GdcKit.qf(T.to_float() / TAU)}, {"v": GdcKit.qf(3.0 * b)}]
		out.methods = {"read-parameters": method([p, "b = 2π ÷ %s = %s" % [D(T), GdcKit.W(b)], say(a)], a.values)}
	out.answer = a
	return out


static func axis_text(amp: Q, d: Q) -> String:
	return "Amplitude = %s, principal axis y = %s" % [D(amp), D(d)]


func u_amp_axis_story(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var a := DifferentiationViews.form(axis_text(s.a, s.d), ["Amplitude = ", {"slot": "a"}, ", principal axis y = ", {"slot": "d"}], {"a": s.a, "d": s.d})
	var opt := func(v: Q, d: Q, ref: String = "") -> Dictionary: return DifferentiationViews.alt(axis_text(v, d), ref, {"a": v, "d": d})
	var out := {"answer": a, "lines": ["%s is modelled by a sine wave." % c.thing, "It runs between a lowest value of %s %s and a highest value of %s %s." % [D(s.low), c.unit, D(s.top), c.unit]], "asked": "Find the amplitude and the equation of the principal axis of the wave."}
	out.wrongs = [opt.call(s.top.sub(s.low), s.d, R_DOUBLE), opt.call(s.d, s.a, R_AXIS_AMP)]
	out.generic = [opt.call(s.a, s.top).values, opt.call(s.a, s.low).values, opt.call(s.top, s.d).values]
	var r := "The amplitude is half the range: (%s − %s) ÷ 2 = %s" % [D(s.top), PD(s.low), D(s.a)]
	var m := "The axis is halfway between: (%s + %s) ÷ 2 = %s" % [D(s.top), PD(s.low), D(s.d)]
	out.methods = {"read-parameters": method([r, m, say(a)], a.values),
		"transform-base": method(["sin x runs from −1 to 1, about y = 0.", r, m, say(a)], a.values)}
	return out


func u_wheel_a_b(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var T: Q = s.period
	var a_v: Q = s.a.neg()
	var story := "A wheel of diameter %d m turns once every %s minutes. Its lowest seat passes %d m above the ground, and a seat starts at the lowest point at t = 0." % [s.dia, D(T), s.base]
	var eq := "h(t) = a cos(bt) + %s gives the height of the seat in metres, t minutes later." % D(s.d)
	var out := {"lines": [story, eq]}
	var first := "The seat goes %s m above and below the middle, and cos starts at its top, so a = −%s to start at the bottom." % [D(s.a), D(s.a)]
	var a: Dictionary
	if s.paper == 1:
		var b: Q = Q.new(2).div(T)
		var t := func(v: Q, w: Q) -> String: return "a = %s, b = %s" % [D(v), Fmt.pi(w)]
		a = DifferentiationViews.form(t.call(a_v, b), ["a = ", {"slot": "a"}, ", b = ", {"slot": "b"}, "π"], {"a": a_v, "b": b})
		out.asked = "Find the exact values of a and b."
		var opt := func(v: Q, w: Q, ref: String = "") -> Dictionary: return DifferentiationViews.alt(t.call(v, w), ref, {"a": v, "b": w})
		out.wrongs = [opt.call(s.a, b, R_WHEEL_SIGN), DifferentiationViews.alt("a = %s, b = %s" % [D(a_v), D(T)], R_PERIOD_B), opt.call(a_v, b.mul(2), R_HALF)]
		out.generic = [opt.call(a_v.mul(2), b).values, opt.call(s.a, b.mul(2)).values, opt.call(s.d.neg(), b).values]
		out.methods = {"read-parameters": method([first, "One turn is %s minutes, so b = 2π ÷ %s = %s" % [D(T), D(T), Fmt.pi(b)], say(a)], a.values)}
	else:
		var b: float = TAU / T.to_float()
		a = named(["a", "b"], [a_v, b], true)
		out.asked = "Find a and b, to 3 significant figures."
		out.wrongs = [wrong(named_vals([s.a, b]), R_WHEEL_SIGN), wrong(named_vals([a_v, T]), R_PERIOD_B), wrong(named_vals([a_v, 2.0 * b]), R_HALF)]
		out.generic = [named_vals([a_v.mul(2), b]), named_vals([s.a, 2.0 * b]), named_vals([s.d.neg(), b])]
		out.methods = {"read-parameters": method([first, "One turn is %s minutes, so b = 2π ÷ %s = %s" % [D(T), D(T), GdcKit.W(b)], say(a)], a.values)}
	out.answer = a
	return out


# ── Using a model ────────────────────────────────────────────

## b as the model writes it: "π/6", "2π/7" or "0.7".
static func m_b(s: Dictionary) -> String:
	if s.has("bdec"):
		return D(s.bdec)
	return Fmt.pi(Q.new(2).div(s.period))


## The bracket: "π/6(t − 3)", "πt/6", "0.7(t − 3)", "0.7t".
static func m_inner(s: Dictionary) -> String:
	if not s.C.is_zero():
		return "%s(t − %s)" % [m_b(s), D(s.C)]
	if s.has("bdec"):
		return D(s.bdec) + "t"
	var b: Q = Q.new(2).div(s.period)
	return "%sπt%s" % ["" if b.n == 1 else str(b.n), "" if b.d == 1 else "/%d" % b.d]


static func m_text(s: Dictionary) -> String:
	return "%s %s(%s) + %s" % [D(s.A), s.fn, m_inner(s), D(s.d)]


static func m_eq(s: Dictionary) -> String:
	return "%s(t) = %s" % [ctx(s).sym, m_text(s)]


static func unit_of(s: Dictionary) -> String:
	return " " + ctx(s).unit


## The story's quantity in a sentence: "the depth of water at the old harbour wall".
static func what(s: Dictionary) -> String:
	var thing: String = ctx(s).thing
	return thing.substr(0, 1).to_lower() + thing.substr(1)


static func m_value(s: Dictionary, t: float, degrees: bool = false) -> float:
	var u: float = s.B * (t - s.C.to_float())
	if degrees:
		u = deg_to_rad(u)
	return s.A.to_float() * (sin(u) if s.fn == "sin" else cos(u)) + s.d.to_float()


## The figure of a model: the curve for 0 ≤ t ≤ L, and the level if the question has one.
static func m_graph(s: Dictionary, L: float, level: Variant = null) -> Dictionary:
	var f := func(t: float) -> float: return m_value(s, t)
	var hl: Array = [] if level == null else [[level.to_float(), "%s = %s" % [ctx(s).sym, D(level)]]]
	var g := Plot.spec([Plot.sample(f, 0.0, L)], [], 0, ceili(L), mini(0, floori(s.low.to_float()) - 1), ceili(s.top.to_float()) + 1, hl)
	g.x_name = "t"
	g.y_name = ctx(s).sym
	return g


## The lines and figure of a model question.
static func m_setup(rep: String, s: Dictionary, L: float, level: Variant = null) -> Dictionary:
	var c := ctx(s)
	match rep:
		"words":
			return {"lines": ["%s is modelled by %s, with t in %s." % [c.thing, m_eq(s), c.time]], "graph": null}
		"graph":
			return {"lines": [m_eq(s), "The graph shows the model, with t in %s." % c.time], "graph": m_graph(s, L, level)}
	return {"lines": [m_eq(s), "t is measured in %s." % c.time], "graph": null}


static func m_ans(s: Dictionary, x: float) -> Dictionary:
	var ans := Answer.make("number", {"v": GdcKit.qf(x)}, {}, ctx(s).sym + " = ", unit_of(s))
	ans.show = "sf"
	return ans


static func t_ans(s: Dictionary, x: float) -> Dictionary:
	var ans := Answer.make("number", {"v": GdcKit.qf(x)}, {}, "t = ", " " + ctx(s).time)
	ans.show = "sf"
	return ans


static func v_of(x: float) -> Dictionary:
	return {"v": GdcKit.qf(x)}


## Every t in (0, L] where the model is at `level`, in order.
static func crossings(s: Dictionary, level: float, L: float, degrees: bool = false) -> Array:
	var out: Array = []
	var us := angles(s, level, degrees)
	var turn := 360.0 if degrees else TAU
	for u in us:
		var t: float = s.C.to_float() + u / s.B
		var step: float = turn / s.B
		while t > 0.0:
			t -= step
		t += step
		while t <= L:
			if t > 1e-9:
				out.append(t)
			t += step
	out.sort()
	return out


## The two angles in a cycle where the model is at `level`, in radians or degrees.
static func angles(s: Dictionary, level: float, degrees: bool = false) -> Array:
	var r: float = (level - s.d.to_float()) / s.A.to_float()
	var half := 180.0 if degrees else PI
	var base: float = asin(r) if s.fn == "sin" else acos(r)
	if degrees:
		base = rad_to_deg(base)
	return [base, half - base] if s.fn == "sin" else [base, -base]


## The equation rearranged, for the working.
static func rearrange(s: Dictionary, level: Q) -> String:
	var r: float = level.sub(s.d).div(s.A).to_float()
	return "Rearrange: %s(%s) = (%s − %s) ÷ %s = %s" % [s.fn, m_inner(s), D(level), PD(s.d), PD(s.A), GdcKit.W(r)]


static func us_text(s: Dictionary, level: Q) -> String:
	var us := angles(s, level.to_float())
	return "In radians, the bracket is %s or %s, plus any whole number of turns of 2π." % [GdcKit.W(us[0]), GdcKit.W(us[1])]


static func gdc_line(s: Dictionary, level: Q) -> String:
	return "In radian mode, graph y = %s and y = %s." % [m_text(s), D(level)]


static func list(xs: Array) -> String:
	return Answer.xs_list(xs.map(func(x): return GdcKit.W(x)))


func u_value_at_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: float = s.t0
	var v := m_value(s, t)
	var a := m_ans(s, v)
	var set := m_setup(rep, s, maxf(2.2 * s.T, t))
	var out := {"answer": a, "lines": set.lines, "graph": set.graph, "asked": "Find %s when t = %d, to 3 significant figures." % [what(s), s.t0]}
	out.wrongs = [wrong(v_of(m_value(s, t, true)), R_DEGREES)]
	var u: float = s.B * (t - s.C.to_float())
	var fv: float = sin(u) if s.fn == "sin" else cos(u)
	out.generic = [v_of(2.0 * s.d.to_float() - v), v_of(s.A.to_float() * fv), v_of(v + s.a.to_float() / 2.0), v_of(v - 1.0)]
	var sym: String = ctx(s).sym
	out.methods = {"substitute-evaluate": method(["Put t = %d into the model, with the angle in radians: the bracket is %s" % [s.t0, GdcKit.W(u)],
		"%s(%s) = %s" % [s.fn, GdcKit.W(u), GdcKit.W(fv)], "%s = %s × %s + %s = %s" % [sym, D(s.A), PW(fv), D(s.d), GdcKit.W(v)], say(a)], a.values)}
	return out


func u_exact_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var angle_t: Q = Q.new(2).div(s.period).mul(s.t0)
	var fv := TrigKit.of(s.fn, angle_t)
	var v := TrigKit.plus(TrigKit.times(fv, s.A), TrigKit.V(s.d))
	var sym: String = ctx(s).sym
	var a := TrigKit.ans(sym + " = ", v, unit_of(s))
	var set := m_setup(rep, s, s.T)
	var out := {"answer": a, "lines": set.lines, "graph": set.graph, "asked": "Find the exact value of %s when t = %d." % [what(s), s.t0]}
	out.wrongs = TrigKit.like(a, TrigKit.plus(TrigKit.times(fv, s.A.neg()), TrigKit.V(s.d)), R_SIGN)
	var other := TrigKit.of("cos" if s.fn == "sin" else "sin", angle_t)
	out.generic = TrigKit.others(a, [TrigKit.times(fv, s.A), TrigKit.plus(TrigKit.times(other, s.A), TrigKit.V(s.d)), TrigKit.plus(fv, TrigKit.V(s.d)), TrigKit.plus(TrigKit.times(fv, s.A), TrigKit.V(s.d.add(1)))])
	out.methods = {"substitute-evaluate": method(["Put t = %d into the model: %s(%d) = %s %s(%s) + %s" % [s.t0, sym, s.t0, D(s.A), s.fn, Fmt.pi(angle_t), D(s.d)],
		"%s = %s" % [TrigKit.call_text(s.fn, angle_t, "rad"), TrigKit.text(fv)], "%s = %s × %s + %s = %s" % [sym, D(s.A), "(%s)" % TrigKit.text(fv) if TrigKit.fl(fv) < 0.0 else TrigKit.text(fv), D(s.d), TrigKit.text(v)], say(a)], a.values)}
	return out


func u_first_time_level(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: float = s.level.to_float()
	var xs := crossings(s, k, 3.0 * s.T)
	var t: float = xs[0]
	var a := t_ans(s, t)
	var set := m_setup(rep, s, 2.2 * s.T, s.level)
	var out := {"answer": a, "lines": set.lines, "graph": set.graph, "asked": "Find the first time after t = 0 that %s is %s%s, to 3 significant figures." % [what(s), D(s.level), unit_of(s)]}
	out.wrongs = [wrong(v_of(crossings(s, k, 720.0 / s.B, true)[0]), R_DEGREES)]
	out.generic = [v_of(xs[1]), v_of(t + s.T), v_of(t + s.T / 2.0), v_of(absf(t - s.T / 4.0) + 0.5)]
	out.methods = {"solve-analytically": method([rearrange(s, s.level), us_text(s, s.level), "Undoing the bracket, the times after 0 are t = %s, and each repeats every %s." % [list(xs.slice(0, 2)), GdcKit.W(s.T)], say(a)], a.values),
		"gdc-intersection": method([gdc_line(s, s.level), "After t = 0 they first cross at t = %s." % GdcKit.W(t), say(a)], a.values)}
	return out


func u_all_times(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var xs := crossings(s, s.level.to_float(), s.L)
	var a := Answer.make("xs", Answer.xs_of(xs.map(func(x): return GdcKit.qf(x))), {"var": "t"})
	a.show = "sf"
	var set := m_setup(rep, s, s.L, s.level)
	var out := {"answer": a, "lines": set.lines, "graph": set.graph, "asked": "Find every time in 0 ≤ t ≤ %d when %s is %s%s, to 3 significant figures." % [s.L, what(s), D(s.level), unit_of(s)]}
	var like := func(vals: Array) -> Dictionary: return Answer.xs_of(vals.map(func(x): return GdcKit.qf(x)))
	out.wrongs = [wrong(like.call([xs[0]]), R_FIRST_ONLY)]
	# In degree mode the first two solutions are far along, as the angles are read as small.
	out.wrongs.append(wrong(like.call(crossings(s, s.level.to_float(), 720.0 / s.B, true).slice(0, 2)), R_DEGREES))
	out.generic = [like.call(xs.slice(0, xs.size() - 1)), like.call(xs.map(func(x): return x + 1.0)), like.call(xs.map(func(x): return x + s.T / 4.0)), like.call(xs + [xs[xs.size() - 1] + s.T])]
	var last := "The times in 0 ≤ t ≤ %d are %s." % [s.L, list(xs)]
	var peak := peak_around(s, s.level.to_float())
	var h: float = peak[1]
	out.methods = {"solve-analytically": method([rearrange(s, s.level), us_text(s, s.level), "Undoing the bracket, the first times after 0 are t = %s, and each repeats every %s." % [list(xs.slice(0, 2)), GdcKit.W(s.T)], last, say(a)], a.values),
		"gdc-intersection": method([gdc_line(s, s.level), "Read every crossing in the interval.", last, say(a)], a.values),
		"symmetry-duration": method(["The wave peaks at t = %s, and crosses y = %s at t = %s." % [GdcKit.W(peak[0]), D(s.level), GdcKit.W(peak[0] - h)], "By symmetry it crosses again %s after the peak, at t = %s." % [GdcKit.W(h), GdcKit.W(peak[0] + h)], "Each crossing repeats every %s." % GdcKit.W(s.T), last, say(a)], a.values)}
	return out


## A peak with both of its crossings after 0: [its time, how far they are from it].
static func peak_around(s: Dictionary, level: float) -> Array:
	var h: float = acos((level - s.d.to_float()) / s.a.to_float()) / s.B
	var p: float = s.tmax
	while p - h <= 0.0:
		p += s.T
	return [p, h]


## The three routes to a time above (or below) a level in each cycle. out is [w, steps].
func duration_methods(s: Dictionary, a: Dictionary, above: bool, per_cycle: float, tail_steps: Array) -> Dictionary:
	var k: float = s.level.to_float()
	var pk := peak_around(s, k)
	var p: float = pk[0]
	var h: float = pk[1]
	var t1: float = p - h
	var t2: float = p + h
	var sayit := func(rest: Array) -> Array: return rest + tail_steps + [say(a)]
	var gap_above := 2.0 * h
	var from := "The model is above %s from t = %s to t = %s, around the peak at t = %s." % [D(s.level), GdcKit.W(t1), GdcKit.W(t2), GdcKit.W(p)]
	var get_it: Array
	if above:
		get_it = ["The gap is %s − %s = %s" % [GdcKit.W(t2), GdcKit.W(t1), GdcKit.W(per_cycle)]]
	else:
		get_it = ["It is above for %s of each cycle, so it is below for %s − %s = %s" % [GdcKit.W(gap_above), GdcKit.W(s.T), GdcKit.W(gap_above), GdcKit.W(per_cycle)]]
	var sym_steps: Array = ["The wave peaks at t = %s, and crosses y = %s at t = %s, which is %s before the peak." % [GdcKit.W(p), D(s.level), GdcKit.W(t1), GdcKit.W(h)],
		"By symmetry it crosses again %s after the peak." % GdcKit.W(h)]
	sym_steps.append("So in each cycle it is above for 2 × %s = %s%s" % [GdcKit.W(h), GdcKit.W(gap_above), "" if above else ", and below for %s − %s = %s" % [GdcKit.W(s.T), GdcKit.W(gap_above), GdcKit.W(per_cycle)]])
	return {"symmetry-duration": method(sayit.call(sym_steps), a.values),
		"gdc-intersection": method(sayit.call([gdc_line(s, s.level), "Around one peak they cross at t = %s and t = %s." % [GdcKit.W(t1), GdcKit.W(t2)]] + get_it), a.values),
		"solve-analytically": method(sayit.call([rearrange(s, s.level), us_text(s, s.level), from] + get_it), a.values)}


func u_duration_above(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: float = s.level.to_float()
	var h: float = peak_around(s, k)[1]
	var w := 2.0 * h
	var a := t_ans(s, w)
	a.label = "Time = "
	var set := m_setup(rep, s, 2.2 * s.T, s.level)
	var out := {"answer": a, "lines": set.lines, "graph": set.graph, "asked": "In each cycle, for how long is %s above %s%s? Answer to 3 significant figures." % [what(s), D(s.level), unit_of(s)]}
	out.wrongs = [wrong(v_of(deg_width(s, k, true)), R_DEGREES), wrong(v_of(s.T - w), R_OTHER_SIDE), wrong(v_of(h), R_ONE_SIDE)]
	out.generic = [v_of(w + s.T), v_of(w / 4.0), v_of(s.T), v_of(s.T / 2.0)]
	out.methods = duration_methods(s, a, true, w, [])
	return out


## The time above (or below) a level in a cycle of the wave a degree-mode GDC draws.
static func deg_width(s: Dictionary, level: float, above: bool) -> float:
	var r: float = (level - s.d.to_float()) / s.a.to_float()
	var w: float = 2.0 * rad_to_deg(acos(r)) / s.B
	return w if above else 360.0 / s.B - w


func u_duration_below(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: float = s.level.to_float()
	var h: float = peak_around(s, k)[1]
	var w: float = s.T - 2.0 * h
	var a := t_ans(s, w)
	a.label = "Time = "
	var set := m_setup(rep, s, 2.2 * s.T, s.level)
	var out := {"answer": a, "lines": set.lines, "graph": set.graph, "asked": "Between two neighbouring peaks, for how long is %s below %s%s? Answer to 3 significant figures." % [what(s), D(s.level), unit_of(s)]}
	out.wrongs = [wrong(v_of(deg_width(s, k, false)), R_DEGREES), wrong(v_of(2.0 * h), R_OTHER_SIDE), wrong(v_of(w / 2.0), R_ONE_SIDE)]
	out.generic = [v_of(w + s.T), v_of(w / 4.0), v_of(s.T), v_of(s.T / 2.0)]
	out.methods = duration_methods(s, a, false, w, [])
	return out


func u_duration_span(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: float = s.level.to_float()
	var h: float = peak_around(s, k)[1]
	var w := 2.0 * h
	var total: float = w * s.cycles
	var a := t_ans(s, total)
	a.label = "Time = "
	var set := m_setup(rep, s, s.L, s.level)
	var out := {"answer": a, "lines": set.lines, "graph": set.graph, "asked": "For how long in 0 ≤ t ≤ %d is %s above %s%s? Answer to 3 significant figures." % [s.L, what(s), D(s.level), unit_of(s)]}
	out.wrongs = [wrong(v_of(deg_width(s, k, true) * s.cycles), R_DEGREES), wrong(v_of(w), R_ONE_CYCLE), wrong(v_of(s.L - total), R_OTHER_SIDE)]
	out.generic = [v_of(total / 2.0), v_of(total + w), v_of(float(s.L)), v_of(total + 1.0)]
	var rest := ["0 ≤ t ≤ %d is %d periods of %s, so the total is %d × %s = %s" % [s.L, s.cycles, D(s.period), s.cycles, GdcKit.W(w), GdcKit.W(total)]]
	var m := duration_methods(s, a, true, w, rest)
	out.methods = {"symmetry-duration": m["symmetry-duration"], "gdc-intersection": m["gdc-intersection"]}
	return out


func u_first_max_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: float = s.tmax
	var a := t_ans(s, t)
	var set := m_setup(rep, s, 2.2 * s.T)
	var out := {"answer": a, "lines": set.lines, "graph": set.graph, "asked": "Find the first time after t = 0 that %s reaches its maximum." % what(s) + ("" if absf(t - roundf(t)) < 1e-9 else " Answer to 3 significant figures.")}
	if absf(t - roundf(t)) < 1e-9:
		a.show = "dec"
		a.exact = true
		a.values.v = Q.new(roundi(t))
	var c: float = s.C.to_float()
	out.wrongs = [wrong(v_of(c), R_C_PEAK)] if c > 0.0 else []
	out.generic = [v_of(s.tmin), v_of(t + s.T), v_of(s.T), v_of(t + 1.0)]
	var want := "1" if s.A.sign() > 0 else "−1"
	var turn: float = (0.5 if s.fn == "sin" else 0.0) if s.A.sign() > 0 else (1.5 if s.fn == "sin" else 1.0)
	var bracket: float = turn * PI
	var bt: String = {0.0: "0", 0.5: "π/2", 1.0: "π", 1.5: "3π/2"}[turn]
	var w := D(s.top)
	out.methods = {"solve-analytically": method(["The model is largest where %s(%s) = %s, since a is %s." % [s.fn, m_inner(s), want, "positive" if s.A.sign() > 0 else "negative"],
		"So the bracket is %s, plus any whole number of turns of 2π." % bt, "That gives t = %s + %s = %s, then every %s; the first after 0 is %s." % [D(s.C), GdcKit.W(bracket / s.B), GdcKit.W(c + bracket / s.B), GdcKit.W(s.T), GdcKit.W(t)], say(a)], a.values),
		"gdc-intersection": method(["In radian mode, graph the model and the line y = %s, its largest value." % w, "They first touch after t = 0 at t = %s." % GdcKit.W(t), say(a)], a.values)}
	return out


func u_high_low_gap(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var gap: float = s.T / 2.0
	var a := t_ans(s, gap)
	a.label = "Time = "
	var set := m_setup(rep, s, 2.2 * s.T)
	var out := {"answer": a, "lines": set.lines, "graph": set.graph, "asked": "Find the time from a minimum of the model to the next maximum, to 3 significant figures."}
	out.wrongs = [wrong(v_of(s.T), R_WHOLE_GAP), wrong(v_of(s.bdec.to_float() / 2.0), R_PERIOD_B)]
	out.generic = [v_of(s.T / 4.0), v_of(gap + 1.0), v_of(1.5 * s.T), v_of(2.0 * s.T)]
	var b := D(s.bdec)
	var f := "The period is 2π ÷ %s = %s" % [b, GdcKit.W(s.T)]
	out.methods = {"solve-analytically": method([f, "cos and sin go from −1 to 1 in half a turn of π, so the time is π ÷ %s = %s" % [b, GdcKit.W(gap)], say(a)], a.values),
		"symmetry-duration": method([f, "The wave is symmetric about each peak, so going up takes as long as coming down: half a period.", "%s ÷ 2 = %s" % [GdcKit.W(s.T), GdcKit.W(gap)], say(a)], a.values)}
	return out


## The count of turning points in 0 ≤ t ≤ L, from the first at t = from.
static func count_from(from: float, L: float, T: float) -> int:
	return floori((L - from) / T) + 1


## The working of a count: list them, or read them off a graph.
func count_methods(s: Dictionary, a: Dictionary, from: float, n: int, word: String, span: String, first: Array) -> Dictionary:
	var last: float = from + (n - 1) * s.T
	var list_it := "They come at t = %s, then every %s." % [GdcKit.W(from), GdcKit.W(s.T)]
	var end := "The last by t = %s is number %d, at t = %s + %d × %s = %s" % [span, n, GdcKit.W(from), n - 1, GdcKit.W(s.T), GdcKit.W(last)]
	return {"solve-analytically": method(first + [list_it, end, say(a)], a.values),
		"gdc-intersection": method(first + ["In radian mode, graph the model for 0 ≤ t ≤ %s, with the line y = %s: it touches at each %s." % [span, GdcKit.W(s.top if word == "peak" else s.low), word], list_it, end, say(a)], a.values)}


func u_count_peaks(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n := count_from(s.tmax, s.L, s.T)
	var a := plain("Number of maxima = ", Q.new(n))
	var set := m_setup(rep, s, s.L)
	var out := {"answer": a, "lines": set.lines, "graph": set.graph, "asked": "How many times does %s reach its maximum in 0 ≤ t ≤ %d?" % [what(s), s.L]}
	var whole := floori(s.L / s.T)
	out.wrongs = [wrong({"v": Q.new(whole)}, R_DIVIDE)] if whole != n else []
	var by_b: int = floori(s.L / s.B)
	if by_b != n and by_b > 0:
		out.wrongs.append(wrong({"v": Q.new(by_b)}, R_PERIOD_B))
	out.generic = [{"v": Q.new(n + 1)}, {"v": Q.new(n + 2)}, {"v": Q.new(maxi(n - 1, 1))}, {"v": Q.new(2 * n)}]
	var first := "The period is %s, and the first maximum is at t = %s." % [GdcKit.W(s.T), GdcKit.W(s.tmax)]
	out.methods = count_methods(s, a, s.tmax, n, "peak", str(s.L), [first])
	return out


func u_count_lows(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var up: Array = TrigWaveSituation.UP[c.time]
	var one: String = (up[0] as String).trim_suffix("s")
	var name: String = one if s.up == 1 else "%d %s" % [s.up, up[0]]
	var n := count_from(s.tmin, s.L, s.T)
	var a := plain("Number of minima = ", Q.new(n))
	var set := m_setup(rep, s, s.L)
	var out := {"answer": a, "lines": set.lines, "graph": set.graph, "asked": "How many times does %s fall to its minimum in the first %s?" % [what(s), name]}
	out.wrongs = []
	var unconverted := count_from(s.tmin, s.up, s.T) if s.up >= s.tmin else 0
	if unconverted != n:
		out.wrongs.append(wrong({"v": Q.new(unconverted)}, R_UNIT))
	var whole := floori(s.L / s.T)
	if whole != n:
		out.wrongs.append(wrong({"v": Q.new(whole)}, R_DIVIDE))
	out.generic = [{"v": Q.new(n + 1)}, {"v": Q.new(n + 2)}, {"v": Q.new(maxi(n - 1, 1))}, {"v": Q.new(2 * n)}]
	var first := "The first %s is %d %s. The period is %s, and the first minimum is at t = %s." % [name, s.L, c.time, GdcKit.W(s.T), GdcKit.W(s.tmin)]
	out.methods = count_methods(s, a, s.tmin, n, "trough", str(s.L), [first])
	return out


## A time for a sentence: whole, or to 3 s.f.
static func ft(x: float) -> String:
	return str(roundi(x)) if absf(x - roundf(x)) < 1e-9 else GdcKit.S(x)


func u_interpret_extreme(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var big: bool = s.which == "max"
	var value: Q = s.top if big else s.low
	var t: float = s.tmax if big else s.tmin
	var word := "highest" if big else "lowest"
	var u := unit_of(s)
	var said := func(w: String, v: Q, x: float) -> String: return "The %s value of %s is %s%s, first reached at t = %s" % [w, what(s), D(v), u, ft(x)]
	var ws: Array = [[said.call(word, s.d, t), R_D_EXTREME]]
	var c: float = s.C.to_float()
	if c > 0.0 and absf(c - t) > 1e-6:
		ws.append([said.call(word, value, c), R_C_PEAK])
	ws.append([said.call("lowest" if big else "highest", value, t), ""])
	ws.append([said.call(word, value, t + s.T / 2.0), ""])
	var cl := DerivativeMeaningViews.claim_answer(said.call(word, value, t), ws.slice(0, 3))
	var a: Dictionary = cl.answer
	var set := m_setup(rep, s, 2.2 * s.T)
	var out := {"answer": a, "wrongs": cl.wrongs, "generic": [], "lines": set.lines, "graph": set.graph, "asked": "Write down the %s value of the model, and say what it means here." % ("maximum" if big else "minimum")}
	var right: String = Answer.text(a) + "."
	out.methods = {"substitute-evaluate": method(["%s runs between %s and %s, so it stays within %s of %s." % [s.fn, "−1", "1", D(s.a), D(s.d)], "So the %s value is %s %s %s = %s, first at t = %s." % [word, D(s.d), "+" if big else "−", D(s.a), D(value), ft(t)], "Put t = %s into the model: it gives %s." % [ft(t), D(value)], right], a.values)}
	return out


func u_reaches_level(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k := D(s.level)
	var does := func(v: Q) -> String: return "It reaches %s, as its largest value is %s" % [k, D(v)]
	var never := func(v: Q) -> String: return "It never reaches %s, as its largest value is %s" % [k, D(v)]
	var ws: Array
	var r_text_: String
	if s.reach:
		r_text_ = does.call(s.top)
		ws = [[never.call(s.d), R_D_EXTREME], [never.call(s.a), R_NO_D], [does.call(s.top.add(s.a)), ""]]
	else:
		r_text_ = never.call(s.top)
		ws = [[does.call(s.top.add(s.a)), ""], [never.call(s.d), R_D_EXTREME], [never.call(s.a), R_NO_D]]
	var cl := DerivativeMeaningViews.claim_answer(r_text_, ws)
	var a: Dictionary = cl.answer
	var set := m_setup(rep, s, s.T * (1.25 if s.paper == 1 else 2.2), s.level)
	var out := {"answer": a, "wrongs": cl.wrongs, "generic": [], "lines": set.lines, "graph": set.graph, "asked": "Does %s ever reach %s%s? Which statement is right?" % [what(s), k, unit_of(s)]}
	var r: float = s.level.sub(s.d).div(s.A).to_float()
	var right: String = Answer.text(a) + "."
	var big := "The largest value of %s is 1, so the model's largest value is %s + %s = %s." % [s.fn, D(s.d), D(s.a), D(s.top)]
	var solve: String
	if s.reach:
		solve = "That size is at most 1, so the equation has solutions."
	else:
		solve = "The size of that is more than 1, and %s can't be more than 1 in size, so there is no solution." % s.fn
	out.methods = {"solve-analytically": method([big, "Rearrange: %s(%s) = (%s − %s) ÷ %s = %s" % [s.fn, m_inner(s), k, PD(s.d), PD(s.A), GdcKit.W(r)], solve, right], a.values),
		"gdc-intersection": method([gdc_line(s, s.level), "%s, and the highest point of the model is at %s." % ["They cross" if s.reach else "They never meet", D(s.top)], right], a.values)}
	return out
