class_name AiExpModelViews
extends ExtensionViews
## The views on the `ai-exp-model` situation (FAL-1001): one builder per unknown of
## fn-ai-exponential-model (AI-SL2.5.exponential-model). A model ka^t + c or ke^(rt) + c in a
## story, as an equation or in words: its start value, a value at a time (perhaps given in
## another unit), the percentage change each unit of time, the horizontal asymptote (written
## down, or the graph that shows it picked from four), what the asymptote means or why a level
## is never reached, the time a level is reached (with the graph and the level drawn), the least
## whole number of units until it is passed, and when two models are equal (with their graphs).
##
## Every question is Paper 2, as every AI paper allows a GDC. A value or a time from the GDC is
## to 3 s.f. with the rounding trap; the start value, the asymptote, the percentage change and a
## whole number of units are exact. A reading in words is a picked `claim`. `given` holds the
## situation as plain data.

const EX := "AI-SL2.5.exponential-model#"
const R_NO_C := EX + "0"
const R_ZERO := EX + "1"
const R_LOST := EX + "2"
const R_LINEAR := EX + "3"
const T := "fn-ai-exponential-model#"
const R_FACTOR_PCT := T + "4"
const R_UNIT := T + "5"
const R_DOWN := T + "6"
const R_COMMON := T + "7"
const S := preload("res://engine/situations/ai_exp_model.gd")

const UNKNOWNS := ["initial-value", "value-at-time", "percent-change", "asymptote", "long-run-meaning", "time-to-level",
	"whole-units-to-level", "two-models-equal"]


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


## The first letter in capitals, the rest as it is.
static func cap(text: String) -> String:
	return text.left(1).to_upper() + text.substr(1)


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func sf_ans(label: String, x: float, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": GdcKit.qf(x)}, {}, label, unit)
	ans.show = "sf"
	return ans


static func exact_ans(label: String, v: Q, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label, unit)
	ans.show = "dec"
	ans.exact = true
	return ans


static func val(x: Variant) -> Dictionary:
	return {"v": x if x is Q else GdcKit.qf(x)}


static func pack(lines: Array, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary,
		graph: Variant = null) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {},
		"graph": graph, "table": null}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


static func ctx(m: Dictionary) -> Dictionary:
	return S.CTX[m.ctx]


static func sym(s: Dictionary) -> String:
	return ctx(s.m).sym


## The varying part with k's size: "60(0.9)^t", "1800e^(−0.105t)".
static func term(m: Dictionary) -> String:
	var k: String = N(m.k.abs_q())
	return k + ("(%s)^t" % D(m.a) if m.form == "a" else "e^(%st)" % D(m.r))


## The power alone: "(0.9)^t", "e^(−0.105t)".
static func power(m: Dictionary) -> String:
	return "(%s)^t" % D(m.a) if m.form == "a" else "e^(%st)" % D(m.r)


## The model's right-hand side: "60(0.9)^t + 20", "2000 − 1800(0.7)^t", "500(0.88)^t".
static func rhs(m: Dictionary) -> String:
	if m.c.is_zero():
		return term(m)
	if m.k.sign() > 0:
		return term(m) + " + " + N(m.c)
	return N(m.c) + " − " + term(m)


static func model_line(m: Dictionary, name: String) -> String:
	return "%s(t) = %s" % [name, rhs(m)]


## The story's unit after a number: " °C", " counts per minute", or "".
static func unit(s: Dictionary) -> String:
	return ctx(s.m).unit


## The lines a student sees: the model and what it stands for, or the story in words.
static func lines(rep: String, s: Dictionary) -> Array:
	var c := ctx(s.m)
	var y := sym(s)
	if rep == "words":
		return ["%s t %s after %s is modelled by %s." % [c.what, c.time, c.after, model_line(s.m, y)]]
	var in_unit: String = "" if c.unit == "" else ", in" + c.unit
	return [model_line(s.m, y), "%s(t) is %s%s, t %s after %s." % [y, c.qty, in_unit, c.time, c.after]]


## The model worked out at t: [the substitution, the arithmetic and its value].
static func worked(m: Dictionary, name: String, t: Q) -> Array:
	var tt := D(t)
	var x := S.value(m, t.to_float())
	var p: float
	var sub: String
	if m.form == "a":
		p = pow(m.a.to_float(), t.to_float())
		sub = "%s(%s)^%s" % [N(m.k.abs_q()), D(m.a), tt if t.is_int() and t.sign() > 0 else "(%s)" % tt]
	else:
		p = exp(m.r.to_float() * t.to_float())
		sub = "%se^(%s × %s)" % [N(m.k.abs_q()), D(m.r), tt]
	var arith := "%s × %s" % [N(m.k.abs_q()), W(p)]
	if not m.c.is_zero():
		if m.k.sign() > 0:
			sub += " + " + N(m.c)
			arith += " + " + N(m.c)
		else:
			sub = N(m.c) + " − " + sub
			arith = N(m.c) + " − " + arith
	return ["%s(%s) = %s" % [name, tt, sub], "= %s = %s" % [arith, W(x)]]


## The model's graph from t = 0 to t_max, with points marked and dashed lines.
static func model_graph(fs: Array, t_max: float, points: Array, hlines: Array) -> Dictionary:
	var top := 0.0
	var curves: Array = []
	for m in fs:
		var f := func(t: float) -> float: return S.value(m, t)
		for i in 41:
			top = maxf(top, f.call(t_max * i / 40.0))
		curves.append(Plot.sample(f, 0.0, t_max))
	var g := Plot.spec(curves, points, 0, ceili(t_max), 0, Plot.nice_top(top), hlines)
	g.x_name = "t"
	return g


## Whether the model falls (towards c, or towards 0).
static func falls(m: Dictionary) -> bool:
	return (S.factor(m) < 1.0) == (m.k.sign() > 0)


# ── The start value ──────────────────────────────────────────

func u_initial_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Dictionary = s.m
	var y := sym(s)
	var st: Q = S.start(m)
	var ans := exact_ans("%s(0) = " % y, st)
	var asked := "Write down the value of %s(0)." % y
	if rep == "words":
		asked = "Write down %s at the start, when t = 0." % ctx(m).qty
	var fill: Array = [{"v": m.c}]
	if m.form == "a":
		fill.append({"v": m.k.mul(m.a).add(m.c)})
	fill.append({"v": m.k.add(m.c.mul(2))})
	var zero := "(%s)⁰ = 1" % D(m.a) if m.form == "a" else "e⁰ = 1"
	return pack(lines(rep, s), asked, ans, [wrong({"v": m.k}, R_NO_C)], fill, {
		"substitute": ["At t = 0, %s, so the power part is %s × 1 = %s." % [zero, N(m.k), N(m.k)],
			"%s(0) = %s × 1 + %s = %s" % [y, N(m.k), N(m.c), N(st)], say(ans)],
	})


# ── A value at a time ────────────────────────────────────────

func u_value_at_time(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Dictionary = s.m
	var c := ctx(m)
	var y := sym(s)
	var tau: Q = s.tau
	var x := S.value(m, tau.to_float())
	var ans := sf_ans(y + " = ", x)
	var when: String = c.alt.time if s.conv else c.time
	var asked := "Find %s %s %s after %s." % [c.qty if rep == "words" else "the value of " + y, N(s.n), when, c.after]
	var wr: Array = []
	if not m.c.is_zero():
		wr.append(wrong(val(x - m.c.to_float()), R_NO_C))
	var conv_line := ""
	if s.conv:
		wr.append(wrong(val(S.value(m, s.n.to_float())), R_UNIT))
		var per := Q.new(c.alt.per[0], c.alt.per[1])
		if per.is_int():
			conv_line = "%s %s = %s × %s = %s %s, so t = %s." % [N(s.n), c.alt.time, N(s.n), N(per), D(tau), c.time, D(tau)]
		else:
			conv_line = "%s %s = %s ÷ %s = %s %s, so t = %s." % [N(s.n), c.alt.time, N(s.n), N(per.d), D(tau), c.time, D(tau)]
	var fill: Array = [{"v": S.start(m)}, val(S.value(m, 2.0 * tau.to_float()))]
	var w := worked(m, y, tau)
	var sub: Array = ([conv_line] if s.conv else []) + ["Substitute t = %s: %s" % [D(tau), w[0]], w[1], say(ans)]
	var step := Q.new(1)
	if not tau.is_int():
		step = Q.new(1, tau.d)
	var table: Array = ([conv_line] if s.conv else []) + [
		"Enter %s in the GDC's table, from t = 0 in steps of %s." % [model_line(m, y), D(step)],
		"The row t = %s shows %s = %s." % [D(tau), y, W(x)], say(ans)]
	return pack(lines(rep, s), asked, ans, wr, fill, {"substitute": sub, "gdc-table": table})


# ── The percentage change ────────────────────────────────────

func u_percent_change(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Dictionary = s.m
	var c := ctx(m)
	var y := sym(s)
	var a: Q = m.a
	var up := a.to_float() > 1.0
	var p: Q = a.sub(1).abs_q().mul(100)
	var per: String = "each " + c.one
	var ans := Answer.make("pct", {"dir": "rise" if up else "fall", "v": p}, {"per": per})
	ans.exact = true
	var dir: String = ans.values.dir
	var other := "fall" if up else "rise"
	var asked := "Write down the percentage change in %s each %s." % [c.qty if rep == "words" else y, c.one]
	var wr: Array = [wrong({"dir": dir, "v": a.mul(100)}, R_FACTOR_PCT if up else R_LOST)]
	var fill: Array = [{"dir": other, "v": p}, {"dir": dir, "v": p.div(100)}]
	var split := "%s = 1 + %s, so %s gains %s%% of its value %s." % [D(a), D(a.sub(1)), y, D(p), per] if up else \
		"%s = 1 − %s, so %s keeps %s%% and loses %s%% of its value %s." % [D(a), D(Q.new(1).sub(a)), y, D(a.mul(100)), D(p), per]
	return pack(lines(rep, s), asked, ans, wr, fill, {
		"any": ["%s, %s is multiplied by %s." % [cap(per), y, D(a)], split, "So it is " + Answer.text(ans) + "."],
	})


# ── The asymptote ────────────────────────────────────────────

## How the varying part dies away, for the working: "As t grows, (0.9)^t gets closer and closer to 0".
static func dies(m: Dictionary) -> String:
	return "As t grows, %s gets closer and closer to 0, so %s → 0." % [power(m), term(m)]


## The window's right end for a model: where its varying part is down to a tenth.
static func t_end(m: Dictionary) -> float:
	return clampf(ceilf(log(0.1) / log(S.factor(m))), 5.0, 40.0)


func u_asymptote(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var m: Dictionary = s.m
	var y := sym(s)
	var c: Q = m.c
	var st: Q = S.start(m)
	var settle := "%s(t) → %s %s 0 = %s" % [y, N(c), "+" if m.k.sign() > 0 else "−", N(c)]
	if rep == "graph":
		return _asymptote_cards(s, rng)
	var ans := Answer.make("axis", {"var": "y", "h": c})
	ans.exact = true
	return pack(lines(rep, s), "Write down the equation of the horizontal asymptote of the graph of y = %s(t)." % y, ans,
		[wrong({"var": "y", "h": Q.new(0)}, R_ZERO)], [{"var": "y", "h": st}, {"var": "y", "h": m.k.abs_q()}], {
		"read-asymptote": [dies(m), "So %s: the graph levels off at height %s." % [settle, N(c)], say(ans)],
	})


## Pick the graph: the model drawn with its asymptote, against one levelling off at y = 0, one
## starting at k and one rising away from the asymptote.
func _asymptote_cards(s: Dictionary, rng: Seeded) -> Dictionary:
	var m: Dictionary = s.m
	var y := sym(s)
	var c: Q = m.c
	var k: Q = m.k
	var st: Q = S.start(m)
	var te := t_end(m)
	var top := Plot.nice_top(st.to_float())
	var win := [0, int(te), 0, top]
	var zero := {"ctx": m.ctx, "form": m.form, "k": st, "c": Q.new(0)}
	var from_k := {"ctx": m.ctx, "form": m.form, "k": k.sub(c), "c": c}
	var away := {"ctx": m.ctx, "form": m.form, "k": k, "c": c}
	if m.form == "a":
		zero.a = m.a
		from_k.a = m.a
		away.a = Q.new(1).div(m.a)
	else:
		zero.r = m.r
		from_k.r = m.r
		away.r = m.r.neg()
	var card := func(f: Dictionary, at: float, label: String) -> Dictionary:
		var fn := func(t: float) -> float: return S.value(f, t)
		var s0 := S.start(f)
		return GdcKit.card([GdcKit.curve(fn, 0.0, te)], [[0, s0.to_float(), Fmt.point(0, s0)]], win, [], [[at, label]])
	var cl := "y = " + N(c)
	var right: Dictionary = card.call(m, c.to_float(), cl)
	var wrongs: Array = [
		{"graph": card.call(zero, 0.0, "y = 0"), "mistake": "zero", "ref": R_ZERO,
			"why": "it levels off at y = 0, but the + %s keeps %s above %s, so the asymptote is %s" % [N(c), y, N(c), cl]},
		{"graph": card.call(from_k, c.to_float(), cl), "mistake": "start-k", "ref": R_NO_C,
			"why": "it starts at %s, but %s(0) = %s + %s = %s" % [N(k), y, N(k), N(c), N(st)]},
		{"graph": card.call(away, c.to_float(), cl), "mistake": "away", "ref": "",
			"why": "it rises away from %s, but %s shrinks as t grows, so %s falls towards %s" % [cl, term(m), y, N(c)]},
	]
	var pk := GdcKit.pick(right, wrongs, rng)
	var ans: Dictionary = pk.answer
	return {"asked": "Which graph shows y = %s(t) with its horizontal asymptote?" % y,
		"lines": lines("equation", s), "answer": ans, "graphs": pk.graphs, "wrongs": [], "fillers": [],
		"methods": {"read-asymptote": method([
			"%s(0) = %s + %s = %s, so the graph starts at %s." % [y, N(k), N(c), N(st), Fmt.point(0, st)],
			"%s So %s(t) falls towards the asymptote %s." % [dies(m), y, cl],
			"%s starts at %s and falls towards %s: so %s." % [pk.letter, Fmt.point(0, st), cl, Answer.text(ans)]], ans.values)}}


# ── What the asymptote means ─────────────────────────────────

func u_long_run_meaning(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Dictionary = s.m
	var c := ctx(m)
	var y := sym(s)
	var u: String = c.unit
	var cv: String = N(m.c) + u
	var from_above: bool = m.k.sign() > 0
	var settle := "%s(t) → %s: the asymptote is %s = %s." % [y, N(m.c), y, N(m.c)]
	if s.say == "meaning":
		var right := "In the long run %s gets closer and closer to %s, %s, but never reaches it." % [c.qty, cv, c.limit]
		var built := SamplingViews.claims(right, [
			["In the long run %s gets closer and closer to 0%s." % [c.qty, u], R_ZERO],
			["%s %s to %s after a while and then stays at exactly %s." % [cap(c.qty), "falls" if from_above else "rises", cv, cv], ""],
			["%s starts at %s and changes from there." % [cap(c.qty), cv], ""]])
		return pack(lines(rep, s), "What does the horizontal asymptote of the model tell you about %s in the long run?" % c.qty,
			built.answer, built.wrongs, built.fillers, {
			"read-asymptote": [dies(m) + " So " + settle,
				"%s is %s: %s is never 0, so %s gets ever closer to %s without reaching it." % [cv, c.limit, term(m), y, cv],
				"So: " + right],
		})
	var lv: Q = s.L
	var lt: String = N(lv) + u
	var verb := "fall to" if from_above else "rise to"
	var side := "above" if from_above else "below"
	var right := "No: %s is always positive, so %s stays %s %s; it only gets closer and closer to %s." % [term(m), y, side, cv, cv]
	var d := S.value(m, 1.0) - S.value(m, 0.0)
	var tl := S.linear_time(m, lv.to_float())
	var change := D(Q.new(roundi(absf(d) * 1000), 1000)) if m.form == "e" else D(m.k.mul(m.a.sub(1)).abs_q())
	var others: Array = [
		["Yes: %s %s by %s%s each %s, so it gets to %s after %s %s." % [y, "falls" if from_above else "rises", change, u, c.one, lt, Fmt.sf(tl), c.time], R_LINEAR]]
	if from_above:
		others.append(["Yes: the model decays towards 0, so %s falls past %s on the way down." % [y, lt], R_ZERO])
	else:
		others.append(["No: %s can never go past its starting value." % y, ""])
	others.append(["Yes: an exponential model reaches every value in the end.", ""])
	var built := SamplingViews.claims(right, others)
	return pack(lines(rep, s), "Will %s ever %s %s? Give a reason." % [c.qty, verb, lt], built.answer, built.wrongs, built.fillers, {
		"read-asymptote": ["%s > 0 for every t, so %s(t) %s %s for every t." % [term(m), y, ">" if from_above else "<", N(m.c)],
			"%s is %s %s, the asymptote, so %s never gets there." % [N(lv), "below" if from_above else "above", N(m.c), y],
			"So: " + right],
	})


# ── The time a level is reached ──────────────────────────────

## GDC lines: what is graphed and where it meets the level.
static func graph_line(m: Dictionary, lv: Q) -> String:
	return "Graph y = %s and y = %s on the GDC, with x for t." % [rhs(m).replace("t", "x"), N(lv)]


func u_time_to_level(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Dictionary = s.m
	var c := ctx(m)
	var y := sym(s)
	var lv: Q = s.L
	var t: float = s.tL
	var unit_t: String = " " + c.time
	var ans := sf_ans("t = ", t, unit_t)
	var asked := "Find the value of t when %s(t) = %s." % [y, N(lv)]
	var ls := lines(rep, s)
	var graph: Variant = null
	if rep == "graph":
		ls = ["The graph of %s is shown with the line %s = %s, where t is the time in %s after %s." % [model_line(m, y), y, N(lv), c.time, c.after]]
		var hl: Array = [[lv.to_float(), "%s = %s" % [y, N(lv)]]]
		if not m.c.is_zero() and S.kind(s) != "grow":
			hl.append([m.c.to_float(), ""])
		graph = model_graph([m], maxf(ceilf(t * 1.6), 4.0), [[0, S.start(m).to_float(), Fmt.point(0, S.start(m))]], hl)
	var fill: Array = []
	var noc := S._no_c_time(m, lv.to_float())
	if is_finite(noc) and noc > 0.0:
		fill.append(val(noc))
	fill.append_array([val(t * 2.0), val(t / 2.0)])
	return pack(ls, asked, ans, [wrong(val(S.linear_time(m, lv.to_float())), R_LINEAR)], fill, {
		"gdc-intersect": [graph_line(m, lv), "Use intersect: x = %s, y = %s." % [W(t), N(lv)], say(ans)],
	}, graph)


# ── The least whole number of units ──────────────────────────

func u_whole_units_to_level(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var m: Dictionary = s.m
	var c := ctx(m)
	var y := sym(s)
	var lv: Q = s.L
	var t: float = s.tL
	var n := ceili(t)
	var down := falls(m)
	var past := "below" if down else "above"
	var rel := "<" if down else ">"
	var ans := exact_ans("t = ", Q.new(n), " " + c.time)
	var asked := "Find the least whole number of %s after which %s(t) %s %s." % [c.time, y, rel, N(lv)]
	if rep == "words":
		asked = "Find the least whole number of %s after which %s is %s %s%s." % [c.time, c.qty, past, N(lv), c.unit]
	var wr: Array = [wrong({"v": Q.new(n - 1)}, R_DOWN)]
	var tl := ceili(S.linear_time(m, lv.to_float()))
	if tl > 0 and tl != n and tl != n - 1:
		wr.append(wrong({"v": Q.new(tl)}, R_LINEAR))
	wr = rng.shuffled(wr)
	var fill: Array = []
	var noc := S._no_c_time(m, lv.to_float())
	if is_finite(noc) and noc > 0.0:
		fill.append({"v": Q.new(ceili(noc))})
	fill.append_array([{"v": Q.new(n + 2)}, {"v": Q.new(2 * n)}])
	var lo := S.value(m, n - 1)
	var hi := S.value(m, n)
	var rows := "%s(%d) = %s is not yet %s %s, and %s(%d) = %s is" % [y, n - 1, W(lo), past, N(lv), y, n, W(hi)]
	return pack(lines(rep, s), asked, ans, wr, fill, {
		"gdc-intersect": [graph_line(m, lv), "Use intersect: x = %s, so %s(t) %s %s once t > %s." % [W(t), y, rel, N(lv), W(t)],
			"Round up, not down: %s, so the first whole number is %d." % [rows, n], say(ans)],
		"gdc-table": ["Enter %s in the GDC's table, from t = 0 in steps of 1." % model_line(m, y),
			"Read down the rows: %s." % rows, say(ans)],
	})


# ── Two models ───────────────────────────────────────────────

func u_two_models_equal(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var st: Dictionary = S.TWO[s.story]
	var t: float = s.tL
	var unit_t: String = " " + st.time
	var ans := sf_ans("t = ", t, unit_t)
	var la := model_line(s.m, "A")
	var lb := model_line(s.m2, "B")
	var ls: Array
	var graph: Variant = null
	if rep == "words":
		ls = ["%s %s and %s." % [st.what, la, lb]]
	else:
		ls = [la, lb, "t is the time in %s." % st.time]
	if rep == "graph":
		ls.append("The graphs of y = A(t) and y = B(t) are shown.")
		graph = model_graph([s.m, s.m2], maxf(ceilf(t * 1.5), 4.0),
			[[0, S.start(s.m).to_float(), "A"], [0, S.start(s.m2).to_float(), "B"]], [])
	var common := S.value(s.m, t)
	var fill: Array = []
	var noc := S.no_c_meet(s)
	if is_finite(noc) and noc > 0.0:
		fill.append(val(noc))
	fill.append_array([val(t * 2.0), val(t / 2.0)])
	var diff := func(x: float) -> float: return S.value(s.m, x) - S.value(s.m2, x)
	var w0 := floori(t)
	var br: Array = S.bracket(t)
	var e := floori(log(t) / log(10.0) + 1e-12)
	var places := 3 - e
	var refine := "0.1, then 0.01, then 0.001" if places == 3 else "0.1, then 0.01"
	var fx := func(x: float) -> String: return "%.*f" % [places, x]
	return pack(ls, "Find the value of t when A(t) = B(t).", ans, [wrong(val(common), R_COMMON)], fill, {
		"gdc-intersect": ["Graph y = %s and y = %s on the GDC, with x for t." % [rhs(s.m).replace("t", "x"), rhs(s.m2).replace("t", "x")],
			"Use intersect: x = %s, y = %s." % [W(t), W(common)], say(ans)],
		"gdc-table": ["Tabulate A(t) − B(t) from t = 0 in steps of 1: A(%d) − B(%d) = %s and A(%d) − B(%d) = %s, so it changes sign between t = %d and t = %d." % [
				w0, w0, W(diff.call(float(w0))), w0 + 1, w0 + 1, W(diff.call(float(w0 + 1))), w0, w0 + 1],
			"Steps of %s narrow the change of sign to between t = %s and t = %s." % [refine, fx.call(br[0]), fx.call(br[1])], say(ans)],
	}, graph)
