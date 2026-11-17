class_name LogTechnologyViews
extends ExtensionViews
## The views on the `log-technology` situation (FAL-999): t1-ext-logs-with-technology, an
## extension type for SL1.5.evaluate-tech. It evaluates log b or ln b, solves 10ˣ = b, eˣ = b and
## aˣ = b, and evaluates a combination such as 3 ln 5 − log 2, each to 3 s.f. on the GDC.
## Wrong options are SL1.5.evaluate-tech's slips (the other log key, a bracket round the
## quotient, a log rounded early) and the type's own (the logs the wrong way round). It builds
## method-pick on every cell and error-spot on the two equations.
##
## Representation: "equation", the log or the equation as the question writes it.

const ET := "SL1.5.evaluate-tech#"
const TL := "t1-ext-logs-with-technology#"
const R_OTHER_KEY := ET + "0"
const R_BRACKET := ET + "1"
const R_EARLY := ET + "2"
const R_UPSIDE_DOWN := TL + "3"
const R_SPOT_KEY := TL + "4"
const R_SPOT_BRACKET := TL + "5"
const UNKNOWNS := ["evaluate-log", "solve-ten-or-e", "solve-base", "evaluate-expression"]
## Methods that don't work on any of these questions, for method-pick.
const PICK_WRONGS := [
	{"name": "Divide the number by the base", "why": "a log is a power, not a share of the number"},
	{"name": "Take the square root of the number", "why": "a root undoes a square, not a power of the base"},
	{"name": "Multiply the number by the base", "why": "that grows the number again; the log undoes the power"},
]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	return {"evaluate-log": ["method-pick"], "solve-ten-or-e": ["method-pick", "error-spot"], "solve-base": ["method-pick", "error-spot"],
		"evaluate-expression": ["method-pick"]}


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = LogTechnologySituation.export(s)
	return out


static func D(v: Variant) -> String:
	return Fmt.dec(v)


## The GDC's screen: 6 decimal places.
static func F(x: float) -> String:
	return ("−" if x < 0.0 else "") + "%.6f" % absf(x)


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func sf_ans(label: String, x: float) -> Dictionary:
	var ans := Answer.make("number", {"v": GdcKit.qf(x)}, {}, label)
	ans.show = "sf"
	return ans


static func x_ans(x: float) -> Dictionary:
	var ans := Answer.make("number", {"v": GdcKit.qf(x)}, {}, "x = ")
	ans.show = "sf"
	return ans


const KEYS := "log is the log to base 10 and ln the log to base e."


func _pack(lines: Array, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {}, "table": null, "pick_wrongs": PICK_WRONGS}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


func u_evaluate_log(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: float = s.b.to_float()
	var name := "%s %s" % [s.key, D(s.b)]
	var ans := sf_ans(name + " = ", s.x)
	var o := LogTechnologySituation.lg(LogTechnologySituation.other(s.key), b)
	return _pack([name], "Use your GDC to find the value of %s, correct to 3 significant figures." % name, ans, [wrong({"v": GdcKit.qf(o)}, R_OTHER_KEY)],
		[{"v": GdcKit.qf(s.x * 2.0)}, {"v": GdcKit.qf(s.x + 1.0)}], {
		"log-key": [KEYS + " Press the %s key." % s.key, "The GDC gives %s = %s" % [name, F(s.x)], final_step(ans)],
	})


static func base_word(key: String) -> String:
	return "10" if key == "log" else "e"


func u_solve_ten_or_e(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var b: float = s.b.to_float()
	var base := base_word(s.key)
	var eq := "%s^x = %s" % [base, D(s.b)]
	var ans := x_ans(s.x)
	var o := LogTechnologySituation.lg(LogTechnologySituation.other(s.key), b)
	var out := _pack([eq], "Solve the equation, giving x correct to 3 significant figures.", ans, [wrong({"v": GdcKit.qf(o)}, R_OTHER_KEY)],
		[{"v": GdcKit.qf(s.x * 2.0)}, {"v": GdcKit.qf(s.x + 1.0)}], {
		"log-key": [KEYS + " %s, so x = %s %s." % [eq, s.key, D(s.b)], "The GDC gives %s %s = %s" % [s.key, D(s.b), F(s.x)], final_step(ans)],
		"graph-intersect": ["Graph y = %s^x and y = %s, and find where they meet." % [base, D(s.b)], "They meet at x = %s" % F(s.x), final_step(ans)],
		"gdc-solver": ["Enter %s^x − %s = 0 in the GDC's equation solver, starting from x = 1." % [base, D(s.b)], "The solver gives x = %s" % F(s.x), final_step(ans)],
	})
	# The slip: the other key, on line 1 (x written with it) or line 2 (the key pressed).
	var ok := LogTechnologySituation.other(s.key)
	var lines: Array
	if s.spot_at == 0:
		lines = ["x = %s %s" % [ok, D(s.b)], "%s %s = %s" % [ok, D(s.b), F(o)], "x = %s" % F(o), "x = %s to 3 s.f." % Fmt.sf(o)]
	else:
		lines = ["x = %s %s" % [s.key, D(s.b)], "%s %s = %s" % [s.key, D(s.b), F(o)], "x = %s" % F(o), "x = %s to 3 s.f." % Fmt.sf(o)]
	out.spot = {"lines": lines, "bad": s.spot_at, "ref": R_SPOT_KEY,
		"why": "%s %s is %s on the GDC: the %s key works to base %s" % [s.key, D(s.b), F(s.x), s.key, base] if s.spot_at == 1 else "the base is %s, so x = %s %s" % [base, s.key, D(s.b)]}
	return out


func u_solve_base(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: float = s.a.to_float()
	var b: float = s.b.to_float()
	var eq := "%s^x = %s" % [D(s.a), D(s.b)]
	var ans := x_ans(s.x)
	var la := LogTechnologySituation.lg("log", a)
	var lb := LogTechnologySituation.lg("log", b)
	var bracket := LogTechnologySituation.lg("log", b / a)
	var wr: Array = [wrong({"v": GdcKit.qf(bracket)}, R_BRACKET), wrong({"v": GdcKit.qf(la / lb)}, R_UPSIDE_DOWN)]
	var out := _pack([eq], "Solve the equation, giving x correct to 3 significant figures.", ans, wr, [{"v": GdcKit.qf(s.x * 2.0)}, {"v": GdcKit.qf(s.x + 1.0)}], {
		"log-key": ["Take logs of both sides: x log %s = log %s, so x = log %s ÷ log %s." % [D(s.a), D(s.b), D(s.b), D(s.a)],
			"log %s ÷ log %s = %s ÷ %s = %s" % [D(s.b), D(s.a), F(lb), F(la), F(s.x)], final_step(ans)],
		"graph-intersect": ["Graph y = %s and y = %s, and find where they meet." % [eq.split(" = ")[0], D(s.b)], "They meet at x = %s" % F(s.x), final_step(ans)],
		"gdc-solver": ["Enter %s − %s = 0 in the GDC's equation solver, starting from x = 1." % [eq.split(" = ")[0], D(s.b)], "The solver gives x = %s" % F(s.x), final_step(ans)],
	})
	var lines: Array
	if s.spot_at == 0:
		lines = ["x = log(%s ÷ %s)" % [D(s.b), D(s.a)], "log(%s ÷ %s) = %s" % [D(s.b), D(s.a), F(bracket)], "x = %s" % F(bracket), "x = %s to 3 s.f." % Fmt.sf(bracket)]
	else:
		lines = ["x = log %s ÷ log %s" % [D(s.b), D(s.a)], "log %s ÷ log %s = %s" % [D(s.b), D(s.a), F(bracket)], "x = %s" % F(bracket), "x = %s to 3 s.f." % Fmt.sf(bracket)]
	out.spot = {"lines": lines, "bad": s.spot_at, "ref": R_SPOT_BRACKET,
		"why": "taking logs gives x = log %s ÷ log %s, a quotient of two logs, not the log of a quotient" % [D(s.b), D(s.a)] if s.spot_at == 0
			else "log %s ÷ log %s = %s ÷ %s = %s: the GDC found log(%s ÷ %s) instead, without a bracket round each log" % [D(s.b), D(s.a), F(lb), F(la), F(s.x), D(s.b), D(s.a)]}
	return out


static func expr_text(s: Dictionary) -> String:
	if s.form == "ln-log":
		return "%d ln %d − log %d" % [s.p, s.q, s.r]
	return "%d log %d + ln %d" % [s.p, s.q, s.r]


func u_evaluate_expression(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var e := expr_text(s)
	var ans := sf_ans("value = ", s.x)
	var swapped := LogTechnologySituation.expression(s, true, false)
	var early := LogTechnologySituation.expression(s, false, true)
	var k1 := "ln" if s.form == "ln-log" else "log"
	var k2 := LogTechnologySituation.other(k1)
	var l1 := LogTechnologySituation.lg(k1, s.q)
	var l2 := LogTechnologySituation.lg(k2, s.r)
	return _pack([e], "Use your GDC to find the value of %s, correct to 3 significant figures." % e, ans,
		[wrong({"v": GdcKit.qf(swapped)}, R_OTHER_KEY), wrong({"v": GdcKit.qf(early)}, R_EARLY)], [{"v": GdcKit.qf(s.x * 2.0)}], {
		"log-key": [KEYS + " Keep every figure until the end.", "%s %d = %s and %s %d = %s" % [k1, s.q, F(l1), k2, s.r, F(l2)],
			"%d × %s %s %s = %s" % [s.p, F(l1), "−" if s.form == "ln-log" else "+", F(l2), F(s.x)], final_step(ans)],
	})
