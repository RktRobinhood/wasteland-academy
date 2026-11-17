class_name ExpModelViews
extends RefCounted
## The views on the `exp-model` situation: one builder per unknown of
## fn-exponential-model (FAL-418). Builders return what QuadraticViews' builders return
## (see quadratic_views.gd). Paper 2: values and times are measures to 3 s.f., with the
## rounding trap (Q7); a count of whole periods and the start value are exact.
##
## `given` holds the numbers the student is shown, for the SymPy checker, which reads
## them back from the lines, the table and the graph.

const NEED := {
	"initial-value": {"form": "limited"},
	"predict-value": {"form": "factor"},
	"interpret-factor": {"form": "factor"},
	"long-run-value": {"form": "limited"},
	"k-from-half-life": {"form": "half"},
	"k-from-data-point": {"form": "data"},
	"predict-from-data-point": {"form": "data"},
	"time-to-level": {"form": "any"},
	"whole-units-inequality": {"form": "any", "whole": true},
	"log-model-solve": {"form": "log10"},
	"factor-from-percent": {"form": "factor"},
	"model-from-table": {"form": "factor", "table": true},
	"model-from-graph": {"form": "limited", "kpoint": true},
	"initial-from-later": {"form": "factor"},
	"half-life-from-k": {"form": "cont", "decay": true},
	"time-from-graph": {"form": "half", "grid": true},
	"change-over-period": {"form": "factor"},
	"two-models-equal": {"form": "two"},
}


## fn-exponential-model's own slips, by index (FAL-820).
const EM := "fn-exponential-model#"
const R_ADD_P0 := EM + "13"
const R_DIRECTION := EM + "14"
const R_START := EM + "15"
const R_NO_C := EM + "16"
const R_K_SIGN := EM + "17"
const R_TIMES_T := EM + "18"
const R_T_SWAP := EM + "19"
const R_LOG_FIRST := EM + "20"
const R_NO_LOG := EM + "21"
const R_TIMES_TIME := EM + "22"
const R_LINE := EM + "23"
const R_FROM_LATER := EM + "24"
const R_TIMES_TEN := EM + "25"
const R_DIVIDE_X0 := EM + "26"
const R_NO_X0 := EM + "27"
const R_NO_M := EM + "28"
const R_ONE_MINUS := EM + "29"
const R_TENTHS := EM + "30"
const R_UPSIDE := EM + "31"
const R_STEP_UP := EM + "32"
const R_DIFF := EM + "33"
const R_A_START := EM + "34"
const R_HALF_NO_LOG := EM + "35"
const R_COUNT := EM + "36"
const R_WHOLE_FACTOR := EM + "37"
const R_ONE_STEP := EM + "38"
const R_RATIO_NO_LOG := EM + "39"
const R_LINEAR := "SL2.9.exp-model#1"
const R_ROUNDED := "SL2.10.context-apply#0"

## The largest wrong option: bigger ones overflow the exact marking of a typed answer.
const MAX_OPTION := 1e6


func has(unknown: String) -> bool:
	return NEED.has(unknown)


func need(unknown: String, rep: String) -> Dictionary:
	return NEED[unknown].duplicate()


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "wrongs", "fillers"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "fillers"] else null
	# More slips than the options have room for: a stream order, so each can show.
	if out.wrongs.size() > 2:
		out.wrongs = rng.shuffled(out.wrongs)
	out.trap = trap(out.answer)
	return out


# ── Helpers ──────────────────────────────────────────────────

static func N(v: Variant) -> String:
	return Fmt.num(v)


static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func S3(x: float) -> String:
	return Fmt.sf(x)


## Working figures: six significant figures, so nothing is rounded early.
static func W(x: float) -> String:
	return Fmt.sf(x, 6)


static func qf(x: float) -> Q:
	return TriangleViews.qf(x)


static func wrong(values: Dictionary, ref: String = "") -> Dictionary:
	return {"values": values, "ref": ref}


## A measure answer to 3 s.f.
static func measure(label: String, x: float, unit: String = "", signed: bool = false) -> Dictionary:
	var a := Answer.make("measure", {"v": qf(x)}, {}, label, unit)
	if signed:
		a.signed = true
	return a


## A tagged wrong measure, kept only when it is a real number (and positive unless the
## answer is signed).
static func wrong_x(out: Dictionary, x: float, ref: String = "") -> void:
	if is_finite(x) and x != 0.0 and (x > 0.0 or out.answer.get("signed", false)) and absf(x) < MAX_OPTION:
		out.wrongs.append(wrong({"v": qf(x)}, ref))


## Plain wrong measures, still unsorted, for the views that share this helper.
static func generic_x(out: Dictionary, xs: Array) -> void:
	for x in xs:
		if is_finite(x) and x > 0.0 and x < MAX_OPTION:
			out.generic.append({"v": qf(x)})


## Wrong measures with no slip behind them (FAL-820).
static func filler_x(out: Dictionary, xs: Array) -> void:
	for x in xs:
		if is_finite(x) and x > 0.0 and x < MAX_OPTION:
			out.fillers.append({"v": qf(x)})


## Answer.trap_text has no measure or pct case yet, so a 2 s.f. trap would show padded
## to 3 s.f. ("6.00 days") under the note "The IB needs 3 s.f.", which is then false
## (#193). Off until the engine writes these kinds at 2 s.f.
const MEASURE_TRAP := false


## Q7's rounding trap: the answer to 2 s.f., for a measure or a percentage change that
## needs rounding at 3 s.f. {} where it doesn't fit.
static func trap(ans: Dictionary) -> Dictionary:
	if ans.kind == "measure" or (ans.kind == "pct" and not ans.get("exact", false)):
		if not MEASURE_TRAP:
			return {}
		var v: Q = ans.values.v
		if not Answer.needs_rounding(v):
			return {}
		var r := Answer.parse_number(Fmt.sf(v, 2).replace("−", "-"))
		if not r.ok or r.q.is_zero():
			return {}
		var out: Dictionary = ans.values.duplicate()
		out.v = r.q
		return out
	return Answer.rounding_trap(ans)


static func sym(s: Dictionary) -> String:
	return s.ctx.sym


## The exponent written after e or a bracket: "^t", "^(t − 3)", "^(0.035t)".
static func k_text(k: Variant) -> String:
	return D(k) if k is Q else "k"


## The model as written. k_shown false writes e^(kt) for a k still to be found.
static func model(s: Dictionary, k_shown: bool = true) -> String:
	var f := sym(s) + "(t) = "
	match s.form:
		"factor":
			return f + "%s(%s)^t" % [N(s.P0), D(s.a)]
		"shift":
			return f + "%s(%s)^(t − %d)" % [N(s.P0), D(s.a), s.t0]
		"cont":
			return f + "%se^(%st)" % [N(s.A), D(s.k)]
		"half", "data":
			return f + "%se^(kt)" % N(s.A)
		"limited":
			var e := "e^(−%st)" % D(s.k) if k_shown and s.k is Q else "e^(−kt)"
			return f + "%s %s %s%s" % [N(s.C), "+" if s.A.sign() > 0 else "−", N(s.A.abs_q()), e]
		"log10":
			return "%s = %slog₁₀(x/%s)" % [sym(s), "" if s.m.eq(1) else N(s.m) + " ", N(s.x0)]
	return "?"


## What the model's extra information says: the reading or the half-life.
static func extras(s: Dictionary, rep: String) -> Array:
	match s.form:
		"data":
			if rep == "words":
				return ["After %d %s it is %s." % [s.t1, s.ctx.time, N(s.P1)]]
			return ["%s(%d) = %s" % [sym(s), s.t1, N(s.P1)]]
		"half":
			if s.dir == "half":
				return ["Its half-life is %d %s." % [s.T, s.ctx.time]]
			return ["It doubles every %d %s." % [s.T, s.ctx.time]]
		"shift":
			return ["The model holds for t ≥ %d." % s.t0]
	return []


## The lines a student sees: the model and its extras, as equations or in words.
static func lines(rep: String, s: Dictionary, k_shown: bool = true) -> Array:
	if s.form == "log10":
		if rep == "words":
			return ["%s is modelled by %s, where x is %s." % [s.ctx.what, model(s), s.ctx.x]]
		return [model(s)]
	if rep == "words":
		var out: Array = ["%s t %s after it was first measured is modelled by %s." % [s.ctx.what, s.ctx.time, model(s, k_shown)]]
		out.append_array(extras(s, rep))
		return out
	var eq: Array = [model(s, k_shown)]
	eq.append_array(extras(s, rep))
	eq.append("t is the time in %s." % s.ctx.time)
	return eq


static func given_of(s: Dictionary) -> Dictionary:
	return ExpModelSituation.export(s)


## The model's graph from t = 0 to t1, with points marked and the long-run value dashed.
static func model_graph(s: Dictionary, t_max: float, points: Array, asymptote: bool, level: Variant = null) -> Dictionary:
	var f := func(t: float) -> float: return ExpModelSituation.value(s, t)
	var top := 0.0
	for i in 41:
		top = maxf(top, f.call(t_max * i / 40.0))
	var hl: Array = []
	if asymptote and s.form == "limited":
		hl.append([s.C.to_float(), ""])
	if level != null:
		hl.append([Q.of(level).to_float(), "y = %s" % N(level)])
	return Plot.spec([Plot.sample(f, 0.0, t_max)], points, 0, ceili(t_max), 0, Plot.nice_top(top), hl).merged({"x_name": "t"})


## Solving the model = lv for t, written for each method. Returns {"eq", "iso", "logs",
## "expr", "both"}: the equation, the exponential alone, its log form, t as an
## expression, and the log-both-sides step. A limited model is rearranged first, since
## the log of a sum is no sum of logs (#193).
static func solve_lines(s: Dictionary, lv: Q) -> Dictionary:
	var y := sym(s)
	match s.form:
		"factor", "shift":
			var ex := "t" if s.form == "factor" else "(t − %d)" % s.t0
			var pw := "%s^%s" % [D(s.a), ex] if s.form == "shift" else "%s^t" % D(s.a)
			var ratio := lv.div(s.P0)
			var lead := "" if s.form == "factor" else "%d + " % s.t0
			return {
				"eq": "%s(%s)%s = %s" % [N(s.P0), D(s.a), "^t" if s.form == "factor" else "^" + ex, N(lv)],
				"iso": "%s = %s" % [pw, Fmt.equals("%s/%s" % [N(lv), N(s.P0)], N(ratio))],
				"logs": "%s × ln %s = ln(%s)" % [ex, D(s.a), N(ratio)],
				"expr": "t = %sln(%s)/ln %s" % [lead, N(ratio), D(s.a)],
				"both": "Take ln of both sides: ln %s + %s × ln %s = ln %s" % [N(s.P0), ex, D(s.a), N(lv)],
			}
		"cont":
			var ratio := lv.div(s.A)
			var kd := D(s.k) if s.k.sign() > 0 else "(%s)" % D(s.k)
			return {
				"eq": "%se^(%st) = %s" % [N(s.A), D(s.k), N(lv)],
				"iso": "e^(%st) = %s" % [D(s.k), Fmt.equals("%s/%s" % [N(lv), N(s.A)], N(ratio))],
				"logs": "%st = ln(%s)" % [D(s.k), N(ratio)],
				"expr": "t = ln(%s)/%s" % [N(ratio), kd],
				"both": "Take ln of both sides: ln %s %s %st = ln %s" % [N(s.A), "+" if s.k.sign() > 0 else "−", D(s.k.abs_q()), N(lv)],
			}
		"half", "data":
			var ratio := lv.div(s.A)
			var kexpr := "ln(%s)/%d" % [N(s.P1.div(s.A)), s.t1] if s.form == "data" else ("(ln 2)/%d" % s.T if s.dir == "double" else "−(ln 2)/%d" % s.T)
			return {
				"eq": "%se^(kt) = %s, with k = %s = %s" % [N(s.A), N(lv), kexpr, W(ExpModelSituation.kf(s))],
				"iso": "e^(kt) = " + Fmt.equals("%s/%s" % [N(lv), N(s.A)], N(ratio)),
				"logs": "kt = ln(%s)" % N(ratio),
				"expr": "t = ln(%s)/k" % N(ratio),
				"both": "Take ln of both sides: ln %s + kt = ln %s" % [N(s.A), N(lv)],
			}
		"limited":
			var ratio := lv.sub(s.C).div(s.A)
			return {
				"eq": "%s %s %se^(−%st) = %s" % [N(s.C), "+" if s.A.sign() > 0 else "−", N(s.A.abs_q()), D(s.k), N(lv)],
				"iso": "e^(−%st) = (%s − %s)/%s = %s" % [D(s.k), N(lv), N(s.C), N(s.A) if s.A.sign() > 0 else "(%s)" % N(s.A), N(ratio)],
				"logs": "−%st = ln(%s)" % [D(s.k), N(ratio)],
				"expr": "t = −ln(%s)/%s" % [N(ratio), D(s.k)],
				"both": "Rearrange: %se^(−%st) = %s, then take ln of both sides: ln %s − %st = ln %s" % [N(s.A.abs_q()), D(s.k),
					N(lv.sub(s.C).abs_q()), N(s.A.abs_q()), D(s.k), N(lv.sub(s.C).abs_q())],
			}
	return {}


# ── fn-exponential-model ─────────────────────────────────────

func u_initial_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y := sym(s)
	var start: Q = s.C.add(s.A)
	var ans := Answer.make("number", {"v": start}, {}, "%s(0) = " % y)
	ans.exact = true
	var final := "So " + Answer.text(ans) + "."
	return {
		"asked": "Find the initial value, %s(0)." % y, "lines": lines(rep, s), "given": given_of(s), "answer": ans,
		"wrongs": [wrong({"v": s.A}, "SL2.9.find-parameters#0"), wrong({"v": s.C}, "SL2.9.find-parameters#1")],
		"fillers": [{"v": s.C.sub(s.A)}, {"v": s.A.neg()}],
		"methods": {
			"substitute-model": {"result": ans.values, "steps": [
				"Put t = 0: e⁰ = 1.", "%s(0) = %s %s %s × 1 = %s" % [y, N(s.C), "+" if s.A.sign() > 0 else "−", N(s.A.abs_q()), N(start)], final]},
			"asymptote-first": {"result": ans.values, "steps": [
				"The model settles towards %s: the asymptote. The start is %s away from it, since e⁰ = 1." % [N(s.C), N(s.A)],
				"%s(0) = %s + (%s) = %s" % [y, N(s.C), N(s.A), N(start)], final]},
		},
	}


func u_predict_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y := sym(s)
	var x := ExpModelSituation.value(s, s.t2)
	var out := {"asked": "Find %s(%d), the value after %d %s." % [y, s.t2, s.t2, s.ctx.time], "lines": lines(rep, s),
		"given": given_of(s), "answer": measure("%s(%d) = " % [y, s.t2], x), "wrongs": [], "fillers": []}
	if rep == "graph":
		out.lines = ["The graph of %s is shown." % model(s), "t is the time in %s." % s.ctx.time]
		out.graph = model_graph(s, s.t2 * 1.3, [[0, s.P0.to_float(), Fmt.point(0, s.P0)]], false)
	wrong_x(out, s.P0.to_float() * s.a.to_float() * s.t2, "SL2.9.exp-model#1")
	wrong_x(out, s.P0.to_float() * (1.0 + s.r / 100.0 * s.t2), "SL2.9.exp-model#1")
	wrong_x(out, ExpModelSituation.value(s, s.t2 - 1), "SL2.9.exp-model#2")
	wrong_x(out, s.P0.to_float() + pow(s.a.to_float(), s.t2), R_ADD_P0)
	filler_x(out, [ExpModelSituation.value(s, s.t2 + 1),
		s.P0.to_float() * pow(s.a.to_float(), s.t2 + 2), s.P0.to_float() * pow(s.a.to_float(), maxf(s.t2 - 2, 1))])
	var final := "So " + Answer.text(out.answer) + "."
	out.methods = {"substitute-model": {"result": out.answer.values, "steps": [
		"Substitute t = %d: %s(%d) = %s × %s^%d" % [s.t2, y, s.t2, N(s.P0), D(s.a), s.t2],
		"= %s × %s = %s" % [N(s.P0), W(pow(s.a.to_float(), s.t2)), W(x)], final]}}
	return out


func u_interpret_factor(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y := sym(s)
	var up: bool = s.r > 0
	var per: String = "each " + s.ctx.one
	var ans := Answer.make("pct", {"dir": "rise" if up else "fall", "v": Q.new(absi(s.r))}, {"per": per})
	ans.exact = true
	var v: Dictionary = ans.values
	var other := "fall" if up else "rise"
	var final := "So it is " + Answer.text(ans) + "."
	return {
		"asked": "What does the %s in the model tell you about %s? Give it as a percentage change." % [D(s.a), y],
		"lines": lines(rep, s), "given": given_of(s), "answer": ans,
		"wrongs": [wrong({"dir": v.dir, "v": s.a.mul(100)}, "SL2.9.exp-model#0"), wrong({"dir": other, "v": v.v}, R_DIRECTION)],
		"fillers": [{"dir": other, "v": s.a.mul(100)}, {"dir": v.dir, "v": v.v.div(100)}],
		"methods": {"substitute-model": {"result": v, "steps": [
			"Each %s, %s is multiplied by %s." % [s.ctx.one, y, D(s.a)],
			"%s = 1 %s %s, so %s %s %d%% of its value %s." % [D(s.a), "+" if up else "−", D(Q.new(absi(s.r), 100)), y,
				"gains" if up else "loses", absi(s.r), per], final]}},
	}


func u_long_run_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y := sym(s)
	var ans := Answer.make("number", {"v": s.C}, {}, "%s(t) → " % y)
	ans.exact = true
	var out := {"asked": "Find the value %s(t) approaches in the long run." % y, "lines": lines(rep, s), "given": given_of(s),
		"answer": ans, "wrongs": [wrong({"v": s.C.add(s.A)}, R_START)] + ([] if s.C.is_zero() else [wrong({"v": Q.new(0)}, R_NO_C)]),
		"fillers": [{"v": s.A.abs_q()}]}
	var etext := "e^(−kt)" if not s.k is Q else "e^(−%st)" % D(s.k)
	if rep == "graph":
		var t1 := 3.0 / ExpModelSituation.kf(s)
		out.lines = ["The graph of %s is shown, where t is the time in %s." % [model(s), s.ctx.time]]
		out.graph = model_graph(s, t1, [[0, s.C.add(s.A).to_float(), Fmt.point(0, s.C.add(s.A))]], true)
	var final := "So " + Answer.text(ans) + "."
	out.methods = {"asymptote-first": {"result": ans.values, "steps": [
		"As t grows, %s gets closer and closer to 0." % etext,
		"So %s(t) → %s + (%s) × 0 = %s: the asymptote is y = %s." % [y, N(s.C), N(s.A), N(s.C), N(s.C)], final]}}
	return out


func u_k_from_half_life(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y := sym(s)
	var half: bool = s.dir == "half"
	var m := Q.new(-1 if half else 1, s.T)
	var ans := Answer.make("lnq", {"m": m, "r": Q.new(2)}, {}, "k = ")
	ans.exact = true
	var final := "So " + Answer.text(ans) + "."
	var target := "%s/2" % N(s.A) if half else "2 × %s" % N(s.A)
	var frac := "½" if half else "2"
	var lnf := "ln ½ = −ln 2" if half else "ln 2"
	return {
		"asked": "Find the exact value of k.", "lines": lines(rep, s, false), "given": given_of(s), "answer": ans,
		"wrongs": [wrong({"m": m.neg(), "r": Q.new(2)}, R_K_SIGN), wrong({"m": Q.new(s.T * (-1 if half else 1)), "r": Q.new(2)}, R_TIMES_T),
			wrong({"m": Q.new(-1 if half else 1, 2), "r": Q.new(s.T)}, R_T_SWAP)],
		"fillers": [{"m": m.mul(2), "r": Q.new(2)}],
		"methods": {
			"logs-for-unknown": {"result": ans.values, "steps": [
				"After %d %s, %s(%d) = %s: %se^(%dk) = %s" % [s.T, s.ctx.time, y, s.T, target, N(s.A), s.T, target],
				"e^(%dk) = %s" % [s.T, frac], "%dk = %s" % [s.T, lnf], final]},
			"isolate-then-log": {"result": ans.values, "steps": [
				"Divide %se^(%dk) = %s by %s: e^(%dk) = %s" % [N(s.A), s.T, target, N(s.A), s.T, frac],
				"In log form: %dk = %s" % [s.T, lnf], final]},
		},
	}


func _data_table(s: Dictionary) -> Dictionary:
	return {"rows": [["t", ["0", str(s.t1)]], ["%s(t)" % sym(s), [N(s.A), N(s.P1)]]]}


func _data_lines(rep: String, s: Dictionary) -> Array:
	if rep == "table":
		return ["%s(t) = %se^(kt), where t is the time in %s. The table gives two values." % [sym(s), N(s.A), s.ctx.time]]
	return lines(rep, s, false)


func u_k_from_data_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y := sym(s)
	var k := ExpModelSituation.kf(s)
	var ratio: Q = s.P1.div(s.A)
	var out := {"asked": "Find the value of k.", "lines": _data_lines(rep, s), "given": given_of(s),
		"answer": measure("k = ", k, "", true), "wrongs": [], "fillers": []}
	if rep == "table":
		out.table = _data_table(s)
	wrong_x(out, log(s.P1.to_float()) / s.t1, R_LOG_FIRST)
	wrong_x(out, ratio.to_float() / s.t1, R_NO_LOG)
	wrong_x(out, log(ratio.to_float()) * s.t1, R_TIMES_TIME)
	wrong_x(out, -k, R_K_SIGN)
	# The size of k × t² for a decay: the time multiplied and the sign lost, no one step.
	if k < 0.0:
		filler_x(out, [absf(log(ratio.to_float())) * s.t1])
	var final := "So " + Answer.text(out.answer) + "."
	var kx := "k = ln(%s)/%d = %s" % [N(ratio), s.t1, W(k)]
	out.methods = {
		"logs-for-unknown": {"result": out.answer.values, "steps": [
			"%se^(%dk) = %s" % [N(s.A), s.t1, N(s.P1)], "e^(%dk) = %s" % [s.t1, Fmt.equals("%s/%s" % [N(s.P1), N(s.A)], N(ratio))],
			"%dk = ln(%s)" % [s.t1, N(ratio)], kx, final]},
		"simultaneous-points": {"result": out.answer.values, "steps": [
			"t = 0 gives %s(0) = %s, the A in front." % [y, N(s.A)],
			"t = %d gives %se^(%dk) = %s, so e^(%dk) = %s" % [s.t1, N(s.A), s.t1, N(s.P1), s.t1, N(ratio)], kx, final]},
		"isolate-then-log": {"result": out.answer.values, "steps": [
			"Divide by %s first: e^(%dk) = %s" % [N(s.A), s.t1, N(ratio)], "In log form: %dk = ln(%s), so %s" % [s.t1, N(ratio), kx], final]},
	}
	return out


func u_predict_from_data_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y := sym(s)
	var k := ExpModelSituation.kf(s)
	var ratio: Q = s.P1.div(s.A)
	var x := ExpModelSituation.value(s, s.t2)
	var out := {"asked": "Find %s(%d)." % [y, s.t2], "lines": _data_lines(rep, s), "given": given_of(s),
		"answer": measure("%s(%d) = " % [y, s.t2], x), "wrongs": [], "fillers": []}
	if rep == "table":
		out.table = _data_table(s)
	var k2 := float(Fmt.sf(k, 2).replace("−", "-"))
	if Fmt.sf(s.A.to_float() * exp(k2 * s.t2)) != Fmt.sf(x):
		wrong_x(out, s.A.to_float() * exp(k2 * s.t2), "SL1.7.solve-with-logs#2")
	for w in [[s.A.to_float() + (s.P1.to_float() - s.A.to_float()) * s.t2 / s.t1, R_LINE], [s.P1.to_float() * exp(k * s.t2), R_FROM_LATER],
			[s.A.to_float() * exp(-k * s.t2), R_K_SIGN]]:
		if w[0] > 0.0:
			wrong_x(out, w[0], w[1])
	filler_x(out, [s.A.to_float() * exp(k * (s.t2 - s.t1)), ExpModelSituation.value(s, s.t2 + 1),
		ExpModelSituation.value(s, maxf(s.t2 - 1, 1))])
	var final := "So " + Answer.text(out.answer) + "."
	out.methods = {
		"substitute-model": {"result": out.answer.values, "steps": [
			"First k: e^(%dk) = %s, so k = ln(%s)/%d = %s (keep it unrounded)." % [s.t1, N(ratio), N(ratio), s.t1, W(k)],
			"%s(%d) = %se^(%d × %s)" % [y, s.t2, N(s.A), s.t2, W(k)], "= %s" % W(x), final]},
		"simultaneous-points": {"result": out.answer.values, "steps": [
			"t = 0 gives A = %s; t = %d gives e^(%dk) = %s." % [N(s.A), s.t1, s.t1, N(ratio)],
			"So %s(%d) = %s × (%s)^(%s)" % [y, s.t2, N(s.A), N(ratio), N(Q.new(s.t2, s.t1))], "= %s" % W(x), final]},
	}
	return out


func u_time_to_level(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var lv: Q = s.L
	var t: float = s.tL
	var sl := solve_lines(s, lv)
	var unit: String = " " + s.ctx.time
	var out := {"asked": "Find the value of t when %s(t) = %s." % [sym(s), N(lv)], "lines": lines(rep, s, s.form != "data"),
		"given": given_of(s), "answer": measure("t = ", t, unit, true), "wrongs": [], "fillers": []}
	wrong_x(out, -t, "SL2.10.context-apply#1")
	wrong_x(out, lv.to_float(), "SL2.10.context-apply#2")
	if s.form == "shift":
		wrong_x(out, log(lv.div(s.P0).to_float()) + s.t0 * log(s.a.to_float()), "SL1.7.solve-with-logs#0")
	filler_x(out, [t * 2.0, t / 2.0, t + 1.5])
	var final := "So " + Answer.text(out.answer) + "."
	var at := "%s = %s" % [sl.expr, W(t)]
	out.methods = {
		"logs-for-unknown": {"result": out.answer.values, "steps": [sl.eq, sl.iso, sl.logs, at, final]},
		"isolate-then-log": {"result": out.answer.values, "steps": ["Isolate the power: " + sl.iso, "In log form: %s, so %s" % [sl.logs, at], final]},
		"log-both-sides": {"result": out.answer.values, "steps": [sl.eq, sl.both, at, final]},
		"gdc-intersect": {"result": out.answer.values, "steps": [
			"Graph y = %s and y = %s." % [model(s).split(" = ", true, 1)[1], N(lv)], "They meet at t = %s." % W(t), final]},
		"gdc-solver": {"result": out.answer.values, "steps": [
			"Solve %s with the numerical solver, t > 0." % sl.eq.split(", with")[0], "t = %s" % W(t), final]},
		"analytic-logs": {"result": out.answer.values, "steps": ["Rearrange: " + sl.iso, at, final]},
	}
	return out


func u_whole_units_inequality(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var lv: Q = s.L
	var t: float = s.tL
	var y := sym(s)
	var up := ExpModelSituation.growing(s)
	var first := ceili(t)
	var unit: String = " " + s.ctx.time
	var ans := Answer.make("number", {"v": Q.new(first)}, {}, "t = ", unit)
	ans.exact = true
	var past := "more than" if up else "less than"
	var out := {"asked": "Find the first whole number of %s after which %s(t) is %s %s." % [s.ctx.time, y, past, N(lv)],
		"lines": lines(rep, s, s.form != "data"), "given": given_of(s), "answer": ans, "wrongs": []}
	# Rounding down, or to the nearest when that is down: the whole number before the crossing.
	out.wrongs.append(wrong({"v": Q.new(first - 1)}, R_ROUNDED))
	out.fillers = [{"v": Q.new(first + 1)}, {"v": Q.new(first + 2)}]
	# With the slip always one below, fillers always above put the key second smallest
	# every time (#193); half the time the one two below comes first instead.
	if first > 3:
		out.fillers.insert(0 if rng.chance(0.5) else 2, {"v": Q.new(first - 2)})
	var sl := solve_lines(s, lv)
	var lo := ExpModelSituation.value(s, first - 1)
	var hi := ExpModelSituation.value(s, first)
	var check := "%s(%d) = %s and %s(%d) = %s, so t = %d is the first whole number past %s." % [y, first - 1, W(lo), y, first, W(hi), first, N(lv)]
	var final := "So " + Answer.text(ans) + "."
	var crossing := "%s(t) = %s at t = %s, so it is %s %s from t = %s on." % [y, N(lv), W(t), past, N(lv), W(t)]
	var by := ""
	match s.form:
		"factor", "shift":
			by = "%s is multiplied by %s" % [y, D(s.a)]
		"cont":
			by = "%s is multiplied by e^(%s)" % [y, D(s.k)]
		"limited":
			by = "the gap between %s and %s is multiplied by e^(−%s)" % [y, N(s.C), D(s.k)]
		_:
			by = "%s is multiplied by e^k = %s" % [y, W(exp(ExpModelSituation.kf(s)))]
	out.methods = {
		"logs-for-unknown": {"result": ans.values, "steps": [sl.eq, "%s = %s" % [sl.expr, W(t)], "Round up, not to the nearest: " + check, final]},
		"gdc-intersect": {"result": ans.values, "steps": ["Graph y = %s and y = %s." % [model(s).split(" = ", true, 1)[1], N(lv)], crossing, check, final]},
		"repeated-multiplication": {"result": ans.values, "steps": [
			"Each %s, %s." % [s.ctx.one, by], "Keep going until it passes %s: %s" % [N(lv), check], final]},
		"log-both-sides": {"result": ans.values, "steps": [sl.eq, sl.both + ", so t = " + W(t), check, final]},
		"gdc-solver": {"result": ans.values, "steps": ["Solve %s with the numerical solver: t = %s." % [sl.eq.split(", with")[0], W(t)], check, final]},
		"table-search": {"result": ans.values, "steps": ["Tabulate %s at whole t and look for the first value %s %s." % [model(s).split(" = ", true, 1)[1], past, N(lv)], check, final]},
	}
	return out


func u_log_model_solve(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y := sym(s)
	var e: Q = s.R.div(s.m)
	var x := ExpModelSituation.log_x(s)
	var out := {"asked": "Find x when %s = %s." % [y, D(s.R)], "lines": lines(rep, s), "given": given_of(s),
		"answer": measure("x = ", x), "wrongs": [], "fillers": [],
		# No P₀a^t here: the step is undoing the log (#193).
		"titles": {"substitute-model": "Substitute, then turn the log back into a power of 10"}}
	wrong_x(out, s.x0.to_float() * pow(e.to_float(), 10.0), "SL1.5.exp-log-form#1")
	var p10 := pow(10.0, e.to_float())
	wrong_x(out, s.x0.to_float() * e.to_float() * 10.0, R_TIMES_TEN)
	wrong_x(out, p10 / s.x0.to_float(), R_DIVIDE_X0)
	wrong_x(out, p10, R_NO_X0)
	if not s.m.eq(1):
		wrong_x(out, s.x0.to_float() * pow(10.0, s.R.to_float()), R_NO_M)
	filler_x(out, [s.x0.to_float() + p10, s.x0.to_float() * p10 / 10.0] + ([] if not s.m.eq(1) else [s.x0.to_float() * p10 * 10.0]))
	var final := "So " + Answer.text(out.answer) + "."
	var first := "%s = %slog₁₀(x/%s), so log₁₀(x/%s) = %s" % [D(s.R), "" if s.m.eq(1) else N(s.m) + " ", N(s.x0), N(s.x0), D(e)]
	out.methods = {"substitute-model": {"result": out.answer.values, "steps": [
		first, "Turn the log back into a power of 10: x/%s = 10^%s = %s" % [N(s.x0), D(e), W(pow(10.0, e.to_float()))],
		"x = %s × %s = %s" % [N(s.x0), W(pow(10.0, e.to_float())), W(x)], final]}}
	return out


func u_factor_from_percent(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y := sym(s)
	var up: bool = s.r > 0
	var ans := Answer.make("expmodel", {"p0": s.P0, "a": s.a}, {"sym": y})
	ans.exact = true
	var pr := Q.new(absi(s.r), 100)
	var final := "So " + Answer.text(ans) + "."
	return {
		"asked": "Write down %s(t), where t is the time in %s." % [y, s.ctx.time],
		"lines": ["%s is %s at t = 0, and it %s by %d%% each %s." % [s.ctx.what, N(s.P0), "grows" if up else "falls", absi(s.r), s.ctx.one]],
		"given": given_of(s), "answer": ans,
		"wrongs": [wrong({"p0": s.P0, "a": pr}, "SL2.9.exp-model#0"), wrong({"p0": s.P0, "a": Q.new(1).sub(s.a.sub(1))}, R_ONE_MINUS)] \
			+ ([wrong({"p0": s.P0, "a": Q.new(1).add(pr.mul(10))}, R_TENTHS)] if up else []),
		# One plus ten times the rate is the misplaced point only for growth; for decay it has no route.
		"fillers": ([] if up else [{"p0": s.P0, "a": Q.new(1).add(pr.mul(10))}]) + [{"p0": s.a, "a": s.P0}],
		"methods": {"substitute-model": {"result": ans.values, "steps": [
			"%s %d%% means multiplying by 1 %s %s = %s each %s." % ["Growing by" if up else "Falling by", absi(s.r), "+" if up else "−", D(pr), D(s.a), s.ctx.one],
			"It starts at %s, so P₀ = %s and a = %s." % [N(s.P0), N(s.P0), D(s.a)], final]}},
	}


func u_model_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y := sym(s)
	var ans := Answer.make("expmodel", {"p0": s.P0, "a": s.a}, {"sym": y})
	ans.exact = true
	var vals: Array = []
	for i in range(1, 5):
		vals.append(s.P0.mul(ExpModelSituation.pow_q(s.a, i)))
	var final := "So " + Answer.text(ans) + "."
	return {
		"asked": "The table shows %s at t = 1, 2, 3 and 4 %s. Find the model %s(t) = P₀(a)^t." % [y, s.ctx.time, y],
		"lines": ["%s t %s after it was first measured grows or falls by the same factor each %s." % [s.ctx.what, s.ctx.time, s.ctx.one]],
		"table": {"rows": [["t", ["1", "2", "3", "4"]], ["%s(t)" % y, vals.map(func(v): return D(v))]]},
		"given": given_of(s), "answer": ans,
		"wrongs": [wrong({"p0": vals[0], "a": s.a}, "SL2.9.exp-model#2"), wrong({"p0": s.P0, "a": Q.new(1).div(s.a)}, R_UPSIDE),
			wrong({"p0": vals[0].mul(s.a), "a": s.a}, R_STEP_UP), wrong({"p0": s.P0, "a": vals[1].sub(vals[0])}, R_DIFF)],
		"methods": {
			"repeated-multiplication": {"result": ans.values, "steps": [
				"Each step multiplies by %s/%s = %s." % [D(vals[1]), D(vals[0]), D(s.a)],
				"Go back one step from t = 1: P₀ = %s ÷ %s = %s" % [D(vals[0]), D(s.a), N(s.P0)], final]},
			"simultaneous-points": {"result": ans.values, "steps": [
				"P₀a = %s and P₀a² = %s." % [D(vals[0]), D(vals[1])],
				"Divide: a = %s; then P₀ = %s ÷ %s = %s" % [D(s.a), D(vals[0]), D(s.a), N(s.P0)], final]},
			"gdc-regression": {"result": ans.values, "steps": [
				"Exponential regression on the table gives y = %s × %s^x, exactly, since every ratio is %s." % [N(s.P0), D(s.a), D(s.a)],
				"The regression's start is at t = 0, not at the first column (t = 1).", final]},
		},
	}


func u_model_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y := sym(s)
	var start: Q = s.C.add(s.A)
	var k := ExpModelSituation.kf(s)
	var ans := Answer.make("limited", {"C": s.C, "A": s.A, "k": qf(k)})
	var g: Q = s.P1.sub(s.C).div(s.A)
	var kw: float = -log((s.P1.to_float() - start.to_float()) / (s.C.to_float() - start.to_float())) / s.t1
	var final := "So " + Answer.text(ans) + "."
	var t_max := maxf(s.t1 * 1.6, 2.5 / k)
	return {
		"asked": "The graph shows %s(t) = C + Ae^(−kt), where t is the time in %s. Find C, A and k." % [y, s.ctx.time],
		"lines": ["%s is modelled by C + Ae^(−kt). Its graph and asymptote are shown." % s.ctx.what],
		"graph": model_graph(s, t_max, [[0, start.to_float(), Fmt.point(0, start)], [s.t1, s.P1.to_float(), Fmt.point(s.t1, s.P1)]], false) \
			.merged({"hlines": [{"at": s.C.to_float(), "label": "y = %s" % N(s.C)}]}, true),
		"given": given_of(s), "answer": ans,
		"wrongs": [wrong({"C": start, "A": s.C.sub(start), "k": qf(kw)}, "SL2.9.find-parameters#1"), wrong({"C": s.C, "A": start, "k": qf(k)}, R_A_START)],
		"fillers": [{"C": s.C, "A": s.A.neg(), "k": qf(k)}, {"C": s.C, "A": s.A, "k": qf(k * s.t1)}],
		"methods": {
			"asymptote-first": {"result": ans.values, "steps": [
				"The asymptote is y = %s, so C = %s." % [N(s.C), N(s.C)],
				"At t = 0, e⁰ = 1, so C + A = %s and A = %s." % [N(start), N(s.A)],
				"Through %s: e^(−%dk) = (%s − %s)/%s = %s, so k = −ln(%s)/%d = %s" % [Fmt.point(s.t1, s.P1), s.t1, N(s.P1), N(s.C), N(s.A) if s.A.sign() > 0 else "(%s)" % N(s.A), N(g), N(g), s.t1, W(k)],
				final]},
			"simultaneous-points": {"result": ans.values, "steps": [
				"As t grows the model tends to C, so C = %s; and (0, %s) gives C + A = %s, so A = %s." % [N(s.C), N(start), N(start), N(s.A)],
				"(%d, %s) gives %s + (%s)e^(−%dk) = %s, so k = %s" % [s.t1, N(s.P1), N(s.C), N(s.A), s.t1, N(s.P1), W(k)], final]},
		},
	}


func u_initial_from_later(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y := sym(s)
	var g := pow(s.a.to_float(), s.t1)
	var x: float = s.P1.to_float() / g
	var shown := "%s(t) = P₀(%s)^t" % [y, D(s.a)]
	var said := ["%s t %s after it was first measured is modelled by %s. After %d %s it is %s." % [s.ctx.what, s.ctx.time, shown, s.t1, s.ctx.time, N(s.P1)]] \
		if rep == "words" else [shown, "%s(%d) = %s" % [y, s.t1, N(s.P1)], "t is the time in %s." % s.ctx.time]
	var out := {"asked": "Find the start value P₀.", "lines": said, "given": given_of(s), "answer": measure("P₀ = ", x),
		"wrongs": [], "fillers": [],
		# The unknown is the start, not an exponent: no logs are needed (#193).
		"titles": {"logs-for-unknown": "Substitute, then divide by the growth factor"}}
	wrong_x(out, s.P1.to_float() / pow(s.a.to_float(), s.t1 - 1), "SL2.9.exp-model#2")
	wrong_x(out, s.P1.to_float() * g, R_STEP_UP)
	wrong_x(out, s.P1.to_float() / (1.0 + (s.a.to_float() - 1.0) * s.t1), R_LINEAR)
	filler_x(out, [s.P1.to_float() / s.a.to_float() / s.t1, s.P1.to_float() / g * s.a.to_float() * s.a.to_float(),
		s.P1.to_float() / g / s.a.to_float()])
	var final := "So " + Answer.text(out.answer) + "."
	out.methods = {"logs-for-unknown": {"result": out.answer.values, "steps": [
		"P₀ × %s^%d = %s" % [D(s.a), s.t1, N(s.P1)], "Divide by the growth, don't multiply: P₀ = %s ÷ %s = %s" % [N(s.P1), W(g), W(x)], final]}}
	return out


func u_half_life_from_k(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var kk: float = absf(s.k.to_float())
	var x := log(2.0) / kk
	var unit: String = " " + s.ctx.time
	var out := {"asked": "Find the half-life of the model, in %s." % s.ctx.time, "lines": lines("equation", s), "given": given_of(s),
		"answer": measure("half-life = ", x, unit), "wrongs": [], "fillers": []}
	wrong_x(out, 1.0 / (2.0 * kk), R_HALF_NO_LOG)
	filler_x(out, [1.0 / kk, 2.0 / kk, log(2.0) * kk * 100.0])
	var final := "So " + Answer.text(out.answer) + "."
	out.methods = {
		"logs-for-unknown": {"result": out.answer.values, "steps": [
			"Half the start: %se^(%st) = %s" % [N(s.A), D(s.k), N(s.A.div(2))], "e^(%st) = ½, so %st = ln ½ = −ln 2" % [D(s.k), D(s.k)],
			"t = (ln 2)/%s = %s" % [D(s.k.abs_q()), W(x)], final]},
		"isolate-then-log": {"result": out.answer.values, "steps": [
			"Divide by %s: e^(%st) = 0.5" % [N(s.A), D(s.k)], "t = ln 0.5 ÷ (%s) = %s" % [D(s.k), W(x)], final]},
	}
	return out


func u_time_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y := sym(s)
	var n: int = s.halvings
	var t: int = n * s.T
	var lv: Q = s.L
	var unit: String = " " + s.ctx.time
	var ans := Answer.make("number", {"v": Q.new(t)}, {}, "t = ", unit)
	ans.exact = true
	var word := "halves" if s.dir == "half" else "doubles"
	var final := "So " + Answer.text(ans) + "."
	var steps := [N(s.A)]
	var v: float = s.A.to_float()
	for i in n:
		v = v / 2.0 if s.dir == "half" else v * 2.0
		steps.append(N(Q.new(roundi(v))))
	return {
		"asked": "Use the graph to find when %s(t) = %s." % [y, N(lv)],
		"lines": ["The graph of %s(t) = %se^(kt) is shown, where t is the time in %s." % [y, N(s.A), s.ctx.time]],
		"graph": model_graph(s, t + s.T, [[0, s.A.to_float(), Fmt.point(0, s.A)]], false, lv),
		"given": given_of(s), "answer": ans,
		"wrongs": [wrong({"v": Q.new(n)}, R_COUNT)],
		"fillers": [{"v": Q.new(s.T)}, {"v": Q.new(t + s.T)}, {"v": Q.new(maxi(t - s.T, 1) if t - s.T != n else t + 2 * s.T)}],
		"methods": {"gdc-intersect": {"result": ans.values, "steps": [
			"Go across from %s on the y-axis to the curve, then down to the t-axis." % N(lv),
			"The curve %s every %d %s: %s, so it reaches %s after %d × %d = %d %s." % [word, s.T, s.ctx.time, " → ".join(steps), N(lv), n, s.T, t, s.ctx.time],
			final]}},
	}


func u_change_over_period(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var g := pow(s.a.to_float(), s.n)
	var up := g > 1.0
	var per := "over %d %s" % [s.n, s.ctx.time]
	var ans := Answer.make("pct", {"dir": "rise" if up else "fall", "v": qf(absf(g - 1.0) * 100.0)}, {"per": per})
	var out := {"asked": "Find the percentage change in %s over %d %s." % [sym(s), s.n, s.ctx.time], "lines": lines(rep, s),
		"given": given_of(s), "answer": ans, "wrongs": [], "fillers": []}
	var dir: String = ans.values.dir
	for w in [[absi(s.r) * s.n, R_LINEAR], [g * 100.0, R_WHOLE_FACTOR], [absi(s.r), R_ONE_STEP]]:
		if is_finite(w[0]) and w[0] > 0.0:
			out.wrongs.append(wrong({"dir": dir, "v": qf(w[0])}, w[1]))
	out.fillers.append({"dir": "fall" if up else "rise", "v": ans.values.v})
	var final := "So it is " + Answer.text(ans) + "."
	out.methods = {"repeated-multiplication": {"result": ans.values, "steps": [
		"Each %s multiplies %s by %s, so %d %s multiply it by %s^%d = %s." % [s.ctx.one, sym(s), D(s.a), s.n, s.ctx.time, D(s.a), s.n, W(g)],
		"%s − 1 = %s: a %s of %s%%." % [W(g), W(g - 1.0), dir, W(absf(g - 1.0) * 100.0)], final]}}
	return out


func u_two_models_equal(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: float = s.tL
	var unit: String = " " + s.ctx.time
	var p := "%s(%s)^t" % [N(s.P0), D(s.a)]
	var q := "%s(%s)^t" % [N(s.P0b), D(s.ab)]
	var out := {"asked": "Find the value of t when P(t) = Q(t).", "lines": [s.ctx.what, "P(t) = " + p, "Q(t) = " + q],
		"given": given_of(s), "answer": measure("t = ", t, unit, true), "wrongs": [], "fillers": []}
	if rep == "graph":
		var fp := func(x: float) -> float: return s.P0.to_float() * pow(s.a.to_float(), x)
		var fq := func(x: float) -> float: return s.P0b.to_float() * pow(s.ab.to_float(), x)
		var tm := t * 1.5
		out.graph = Plot.spec([Plot.sample(fp, 0.0, tm), Plot.sample(fq, 0.0, tm)],
			[[0, s.P0.to_float(), "P"], [0, s.P0b.to_float(), "Q"]], 0, ceili(tm), 0, Plot.nice_top(maxf(fp.call(tm), fq.call(tm)))).merged({"x_name": "t"})
	var ratio: Q = s.P0b.div(s.P0)
	var fr: Q = s.a.div(s.ab)
	wrong_x(out, -t, "SL2.10.context-apply#1")
	wrong_x(out, ratio.to_float() / fr.to_float(), R_RATIO_NO_LOG)
	filler_x(out, [log(ratio.to_float()) / (s.a.to_float() - s.ab.to_float()), t + 1.5])
	var final := "So " + Answer.text(out.answer) + "."
	var at := "t = ln(%s)/ln(%s) = %s" % [N(ratio), N(fr), W(t)]
	out.methods = {
		"logs-for-unknown": {"result": out.answer.values, "steps": [
			"%s = %s" % [p, q], "(%s/%s)^t = %s/%s, so (%s)^t = %s" % [D(s.a), D(s.ab), N(s.P0b), N(s.P0), N(fr), N(ratio)], at, final]},
		"gdc-intersect": {"result": out.answer.values, "steps": ["Graph y = %s and y = %s." % [p, q], "They cross at t = %s." % W(t), final]},
		"log-both-sides": {"result": out.answer.values, "steps": [
			"ln %s + t ln %s = ln %s + t ln %s" % [N(s.P0), D(s.a), N(s.P0b), D(s.ab)],
			"t(ln %s − ln %s) = ln %s − ln %s" % [D(s.a), D(s.ab), N(s.P0b), N(s.P0)], at, final]},
		"analytic-logs": {"result": out.answer.values, "steps": ["Divide both sides by %s(%s)^t: (%s)^t = %s" % [N(s.P0), D(s.ab), N(fr), N(ratio)], at, final]},
	}
	return out
