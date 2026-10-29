class_name GraphReadingViews
extends RefCounted
## The views on the `fn-pre-graph-reading` situation (FAL-420): prior learning for
## reading graphs and rounding. Builders return what QuadraticViews' builders return
## (see quadratic_views.gd). Its misconceptions have no catalogue ref, so they are
## logged as "fn-pre-graph-reading#<index>" (QuestionEngine.misconception_text).

const NEED := {"read-coordinates": {}, "read-with-scale": {}, "plot-from-table": {}, "round-3sf": {}, "round-small-3sf": {},
	"round-dp": {}, "which-values-round": {}}
const T := "fn-pre-graph-reading#"


func has(unknown: String) -> bool:
	return NEED.has(unknown)


func need(unknown: String, _rep: String) -> Dictionary:
	return NEED[unknown].duplicate()


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "wrongs", "generic"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "generic"] else null
	out.given = GraphReadingSituation.export(s)
	out.trap = {}
	return out


static func N(v: Variant) -> String:
	return Fmt.num(v)


static func wrong(values: Dictionary, ref: String = "") -> Dictionary:
	return {"values": values, "ref": ref}


static func dec(v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v})
	ans.exact = true
	ans.show = "dec"
	return ans


func u_read_coordinates(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x := Q.new(s.px)
	var y := Q.new(s.py)
	var ans := Answer.make("point", {"x": x, "y": y})
	ans.exact = true
	var final := "So P is " + Answer.text(ans) + "."
	return {
		"asked": "Write down the coordinates of the point P.", "lines": ["The point P is marked on the grid."],
		"graph": Plot.spec([], [[s.px, s.py, "P"]], -6, 6, -6, 6), "answer": ans,
		"wrongs": [wrong({"x": y, "y": x}, T + "1")], "generic": [{"x": x.neg(), "y": y}, {"x": x, "y": y.neg()}, {"x": x.neg(), "y": y.neg()}],
		"methods": {
			"grid-count": {"result": ans.values, "steps": ["Count squares from the origin: %d %s, then %d %s." % [absi(s.px), "right" if s.px > 0 else "left",
				absi(s.py), "up" if s.py > 0 else "down"], final]},
			"across-then-up": {"result": ans.values, "steps": ["Go along the x-axis first: x = %s." % N(x), "Then up or down to the point: y = %s." % N(y), final]},
		},
	}


func u_read_with_scale(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var val := Q.new(s.squares * s.scale)
	var ans := Answer.make("number", {"v": val}, {}, "y = ")
	ans.exact = true
	var final := "So the value is " + Answer.text(ans) + "."
	return {
		"asked": "Each grid square on the y-axis is %d units. Find the y-value of the marked point." % s.scale,
		"lines": ["The point is %d squares above the x-axis." % s.squares],
		"graph": Plot.spec([], [[2, s.squares * s.scale, ""]], -1, 5, -s.scale, s.scale * 8), "answer": ans,
		"wrongs": [wrong({"v": Q.new(s.squares)}, T + "0")],
		"generic": [{"v": Q.new((s.squares + 1) * s.scale)}, {"v": Q.new(s.squares * s.scale / 2) if s.scale > 2 else Q.new(s.squares + 2)}, {"v": Q.new(s.squares + s.scale)}],
		"methods": {"grid-count": {"result": ans.values, "steps": ["The point is %d squares up, and each square is %d units." % [s.squares, s.scale],
			"%d × %d = %d." % [s.squares, s.scale, s.squares * s.scale], final]}},
	}


func u_plot_from_table(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var pts: Array = []
	for i in 4:
		pts.append([s.xs[i], s.ys[i], ""])
	var w := [-6, 6, -6, 6]
	var card := func(ps: Array) -> Dictionary: return GdcKit.card([], ps, w)
	var p := GdcKit.pick(card.call(pts), [
		{"graph": card.call(pts.map(func(q): return [q[1], q[0], ""])), "ref": T + "1", "mistake": "swapped", "why": "its points have x and y swapped"},
		{"graph": card.call(pts.map(func(q): return [q[0], q[1] + 1, ""])), "ref": "", "mistake": "up-one", "why": "every point is one square too high"},
		{"graph": card.call(pts.map(func(q): return [q[0], -q[1], ""])), "ref": "", "mistake": "flipped", "why": "every y-value has the wrong sign"},
	], rng)
	var final: String = "So the plot is %s." % p.answer.values.v
	return {
		"asked": "Which grid shows the points in the table?", "lines": [], "table": {"xs": s.xs.map(func(v): return Q.new(v)), "ys": s.ys.map(func(v): return Q.new(v))},
		"answer": p.answer, "graphs": p.graphs,
		"methods": {"across-then-up": {"result": p.answer.values, "steps": ["Each column is a point (x, y): go across to x, then up or down to y.",
			"The first is (%d, %d), the last (%d, %d)." % [s.xs[0], s.ys[0], s.xs[3], s.ys[3]], final]}},
	}


func u_round_3sf(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v: Q = s.v
	var r := GraphReadingSituation.sf_q(v, 3)
	var ans := dec(r)
	var final := "So it is %s to 3 s.f." % Fmt.dec(r)
	# Cut off after 3 figures, not rounded.
	var trunc := Q.new(floori(v.to_float() / _unit(v).to_float() + 1e-9)).mul(_unit(v))
	return {
		"asked": "Write %s correct to 3 significant figures." % Fmt.dec(v), "lines": [Fmt.dec(v)], "answer": ans,
		"wrongs": [wrong({"v": GraphReadingSituation.sf_q(v, 2)}, T + "4")],
		"generic": [{"v": trunc}, {"v": GraphReadingSituation.sf_q(v, 4)}, {"v": r.add(_unit(v))}],
		"methods": {
			"first-nonzero-digit": {"result": ans.values, "steps": ["Count three figures from the first non-zero digit of %s." % Fmt.dec(v),
				"The next digit decides: round once, up if it is 5 or more.", final]},
			"round-once": {"result": ans.values, "steps": ["Look only at the 4th figure, and round once: never round in stages.", final]},
		},
	}


## The size of the 3rd significant figure of v: 0.01 for 2.345.
static func _unit(v: Q) -> Q:
	var e := floori(log(absf(v.to_float())) / log(10.0)) - 2
	return Q.new(1, int(pow(10, -e))) if e < 0 else Q.new(int(pow(10, e)))


func u_round_small_3sf(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v: Q = s.v_small
	var r := GraphReadingSituation.sf_q(v, 3)
	var ans := dec(r)
	var final := "So it is %s to 3 s.f." % Fmt.dec(r)
	return {
		"asked": "Write %s correct to 3 significant figures." % Fmt.dec(v), "lines": [Fmt.dec(v)], "answer": ans,
		"wrongs": [wrong({"v": GraphReadingSituation.dp_q(v, 3)}, T + "2")],
		"generic": [{"v": GraphReadingSituation.dp_q(v, 2) if not GraphReadingSituation.dp_q(v, 2).is_zero() else Q.new(1, 100)}, {"v": GraphReadingSituation.sf_q(v, 2)},
			{"v": r.mul(Q.new(10))}],
		"methods": {"first-nonzero-digit": {"result": ans.values, "steps": ["The zeros after the point don't count: start at the first non-zero digit.",
			"Keep three figures from there and round once.", final]}},
	}


func u_round_dp(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v: Q = s.v
	var n: int = s.dp
	var r := GraphReadingSituation.dp_q(v, n)
	var ans := dec(r)
	var final := "So it is %s to %d decimal place%s." % [Fmt.dec(r), n, "" if n == 1 else "s"]
	return {
		"asked": "Write %s correct to %d decimal place%s." % [Fmt.dec(v), n, "" if n == 1 else "s"], "lines": [Fmt.dec(v)], "answer": ans,
		"generic": [{"v": GraphReadingSituation.dp_q(v, n + 1)}, {"v": GraphReadingSituation.sf_q(v, n) if not GraphReadingSituation.sf_q(v, n).eq(r) else r.add(Q.new(1, 10))},
			{"v": GraphReadingSituation.dp_q(v, 3 - n)}, {"v": r.sub(Q.new(1, int(pow(10, n))))}],
		"methods": {
			"decimal-places": {"result": ans.values, "steps": ["Count %d digit%s after the decimal point." % [n, "" if n == 1 else "s"],
				"The next digit decides whether to round up.", final]},
			"round-once": {"result": ans.values, "steps": ["Look only at the digit after the last one kept, and round once.", final]},
		},
	}


func u_which_values_round(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: Q = s.bound
	var half := Q.new(1, 200)
	var ans := Answer.make("range2", {"lo": b.sub(half), "r1": "≤", "r2": "<", "hi": b.add(half)}, {"var": "x"})
	ans.exact = true
	ans.show = "dec"
	var final := "So " + Answer.text(ans) + "."
	return {
		"asked": "A value x is %s, correct to 3 significant figures. Write down the interval of values x can take." % Fmt.dec(b), "lines": [Fmt.dec(b)],
		"answer": ans,
		"generic": [{"lo": b.sub(half), "r1": "≤", "r2": "≤", "hi": b.add(half)}, {"lo": b.sub(Q.new(1, 100)), "r1": "≤", "r2": "<", "hi": b.add(Q.new(1, 100))},
			{"lo": b, "r1": "≤", "r2": "<", "hi": b.add(Q.new(1, 100))}, {"lo": b.sub(Q.new(1, 20)), "r1": "≤", "r2": "<", "hi": b.add(Q.new(1, 20))}],
		"methods": {"bounds": {"result": ans.values, "steps": ["The 3rd figure is in the hundredths, so x is within half of 0.01 of %s." % Fmt.dec(b),
			"%s rounds up to %s, but %s rounds to the next value: it is left out." % [Fmt.dec(b.sub(half)), Fmt.dec(b), Fmt.dec(b.add(half))], final]}},
	}
