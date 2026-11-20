class_name AiTestModelViews
extends ExtensionViews
## The views on the `ai-test-model` situation (FAL-1001): one builder per unknown of
## fn-ai-test-model (AI-SL2.6.test-model, AI-SL2.6.use-model). A model in context is tested and
## used: the percentage error of its value against a reading it wasn't fitted to (from a table or
## in words), which of two models (linear and exponential, through the same two readings)
## predicts a later reading better, the model's value at an input where it is impossible and why,
## a limitation (in words, or with the model drawn through the readings it was fitted to and the
## context's cap or floor dashed), a prediction for a calendar year, which of two predictions is
## more reliable (inside or far outside the data), and what a parameter means, with its units.
##
## Every question is Paper 2, as every AI paper allows a GDC. A percentage error is to 3 s.f.
## with the rounding trap; a prediction for a year is exact. A statement with its reason is a
## picked `claim`; every unknown also plays as true-false-reason. `given` holds the situation as
## plain data.

const TM := "AI-SL2.6.test-model#"
const UM := "AI-SL2.6.use-model#"
const R_FITS_POINTS := TM + "0"
const R_ONE_ERROR := TM + "1"
const R_OVER_MODEL := TM + "2"
const R_CALENDAR := UM + "0"
const R_EXTRAPOLATE := UM + "1"
const R_UNITS := UM + "2"
const R_NOT_DIVIDED := "fn-ai-test-model#6"
const R_LARGER := "fn-ai-test-model#7"
const R_NO_REASON := "fn-ai-test-model#8"
const S := preload("res://engine/situations/ai_test_model.gd")

const UNKNOWNS := ["percentage-error", "compare-two-models", "reject-from-value", "limitation", "year-to-t",
	"interpolate-or-extrapolate", "interpret-parameter"]
## Each story: the output's letter, what it is (for "where ..."), its name in a sentence, the
## words sentence before "is modelled by", the unit of t, and how a reading is named.
const CTX := [
	{"sym": "P", "is": "P is the population of the settlement of Rustwater", "story": "The population of the settlement of Rustwater t years after %d",
		"per": "year", "name": "population", "of": "the population P of the settlement of Rustwater"},
	{"sym": "T", "is": "T is the temperature of a mug of tea, in °C", "story": "The temperature, in °C, of a mug of tea t minutes after it is poured",
		"per": "minute", "name": "temperature", "of": "the temperature T of a mug of tea, in °C"},
	{"sym": "h", "is": "h is the height of a signal flare above the ground, in metres",
		"story": "The height above the ground, in metres, of a signal flare t seconds after it is fired from a tower",
		"per": "second", "name": "height", "of": "the height h of a signal flare, in metres"},
	{"sym": "V", "is": "V is the value of a salvage truck, in dollars", "story": "The value, in dollars, of a salvage truck t years after it was bought in %d",
		"per": "year", "name": "value", "of": "the value V of a salvage truck, in dollars"},
	{"sym": "N", "is": "N is the number of solar panels on the city's roofs", "story": "The number of solar panels on the city's roofs t years after %d",
		"per": "year", "name": "number of panels", "of": "the number N of solar panels on the city's roofs"},
	{"sym": "M", "is": "M is the number of traders at the night market", "story": "The number of traders at the night market t years after %d",
		"per": "year", "name": "number of traders", "of": "the number M of traders at the night market"},
]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = ["true-false-reason"]
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
static func W(x: Variant) -> String:
	return Fmt.work(Q.of(x).to_float() if x is Q else x, 6)


static func W7(x: Variant) -> String:
	return Fmt.work(Q.of(x).to_float() if x is Q else x, 7)


static func c(s: Dictionary) -> Dictionary:
	return CTX[s.ctx]


static func sym(s: Dictionary) -> String:
	return c(s).sym


## t's meaning: "t is the number of years after 2010".
static func tdef(s: Dictionary) -> String:
	match s.ctx:
		1:
			return "t is the time in minutes after the tea is poured"
		2:
			return "t is the time in seconds after the flare is fired"
		3:
			return "t is the number of years after the truck was bought in %d" % s.y0
	return "t is the number of years after %d" % s.y0


## The model's right-hand side: "85 − 2.5t", "−4.9t² + 19.6t + 2", "2400 × 1.05^t".
static func expr(s: Dictionary) -> String:
	match s.fam:
		"exp":
			return "%s × %s^t" % [D(s.A), D(s.b)]
		"quad":
			return Fmt.terms([s.qa, s.qb, s.qc], [2, 1, 0], "t", true)
	return Fmt.terms([s.c0, s.c1], [0, 1], "t", true)


static func model(s: Dictionary) -> String:
	return "%s(t) = %s" % [sym(s), expr(s)]


## The model with t written in: "85 − 2.5 × 30", "−4.9 × 5² + 19.6 × 5 + 2", "2400 × 1.05^40".
static func subst(s: Dictionary, t: Q) -> String:
	var T := D(t)
	match s.fam:
		"exp":
			return "%s × %s^%s" % [D(s.A), D(s.b), T]
		"quad":
			return "%s × %s² %s %s × %s %s %s" % [D(s.qa), T, "−" if s.qb.sign() < 0 else "+", D(s.qb.abs_q()), T,
				"−" if s.qc.sign() < 0 else "+", D(s.qc.abs_q())]
	return "%s %s %s × %s" % [D(s.c0), "−" if s.c1.sign() < 0 else "+", D(s.c1.abs_q()), T]


## The question's lines: the model on a line of its own (equation), or in a sentence.
static func lines(s: Dictionary, rep: String) -> Array:
	if rep == "equation":
		return [model(s), "where %s, and %s." % [c(s).is, tdef(s)]]
	var story: String = c(s).story
	if story.contains("%d"):
		story = story % s.y0
	return ["%s is modelled by %s." % [story, model(s)]]


## The line that gives the context's cap or floor, where the question doesn't take it as read.
static func limit_line(s: Dictionary) -> Array:
	match s.ctx:
		0:
			return ["The wells of Rustwater can supply water for at most %s people." % D(s.level)]
		1:
			return ["The tea is in a room at %s °C." % D(s.level)]
		4:
			return ["The roofs can hold at most %s panels." % D(s.level)]
	return []


## A value as the model gives it: exact where it ends, else to 3 s.f.
static func vt(v: Variant) -> String:
	return D(v) if v is Q else Fmt.sf(v)


## A value with its unit: "10 °C", "−12.5 m", "−$2250", "16900".
static func unit(s: Dictionary, t: String) -> String:
	match s.ctx:
		1:
			return t + " °C"
		2:
			return t + " m"
		3:
			return ("−$" + t.substr(1)) if t.begins_with("−") else "$" + t
	return t


static func amount(s: Dictionary, v: Variant) -> String:
	return unit(s, vt(v))


## When the model reaches its cap or floor: "t = 26" when that ends, else "t ≈ 24.7".
static func cross_text(s: Dictionary) -> String:
	if S.cross_exact(s):
		return "t = " + D(S.cross_q(s))
	return "t ≈ " + Fmt.sf(s.cross)


static func sf_ans(label: String, v: float, unit_text: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": GdcKit.qf(v)}, {}, label, unit_text)
	ans.show = "sf"
	return ans


static func exact_ans(label: String, v: Q, unit_text: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label, unit_text)
	ans.show = "dec"
	ans.exact = true
	return ans


static func val(v: Variant) -> Dictionary:
	return {"v": v if v is Q else GdcKit.qf(v)}


static func say(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func pack(lines_in: Array, asked: String, ans: Dictionary, wrongs: Array, fillers: Array, steps: Dictionary,
		graph: Variant = null, table: Variant = null) -> Dictionary:
	var out := {"lines": lines_in, "asked": asked, "answer": ans, "wrongs": wrongs, "fillers": fillers, "methods": {},
		"graph": graph, "table": table}
	for m in steps:
		out.methods[m] = method(steps[m], ans.values)
	return out


## A claim question: the right statement, and [text, ref] wrong ones ("" for a filler).
static func claims(right: String, others: Array) -> Dictionary:
	return SamplingViews.claims(right, others)


## How the model behaves as t grows, in a sentence.
static func trend(s: Dictionary) -> String:
	var per: String = c(s).per
	match s.fam:
		"exp":
			return "%s multiplies by %s each %s, so it grows without limit." % [model(s), D(s.b), per]
		"quad":
			return "In %s the %st² term wins as t grows, so once it has turned it falls without end." % [model(s), D(s.qa)]
	if s.c1.sign() < 0:
		return "%s falls by %s each %s, without end." % [model(s), D(s.c1.abs_q()), per]
	return "%s grows by %s each %s, without end." % [model(s), D(s.c1), per]


## The cap or floor with its unit: "8000 people", "20 °C", "0 m", "$0", "2000 panels", "0".
static func level_text(s: Dictionary) -> String:
	match s.ctx:
		0:
			return D(s.level) + " people"
		4:
			return D(s.level) + " panels"
	return amount(s, s.level)


## What the context says about the cap or floor, as the working's first line.
static func context_line(s: Dictionary) -> String:
	match s.ctx:
		0:
			return "The wells set a cap: the settlement can hold at most %s people." % D(s.level)
		1:
			return "In a room at %s °C the tea cools towards %s °C and stays there: it can't get colder." % [D(s.level), D(s.level)]
		2:
			return "A flare's height can't be below 0 m: once it reaches the ground it stops."
		3:
			return "A truck's value can fall to $0 but no lower."
		4:
			return "The roof space sets a cap: at most %s panels." % D(s.level)
	return "A count of traders can't be below 0."


# ── Percentage error ─────────────────────────────────────────

func u_percentage_error(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var vals := S.percentage_slips(s)
	var e: float = vals[0]
	var ans := sf_ans("percentage error = ", e, "%")
	var wr: Array = rng.shuffled([wrong(val(vals[1]), R_OVER_MODEL), wrong(val(vals[2]), R_NOT_DIVIDED)])
	var fill: Array = [val(e / 100.0), val(e * 10.0)]
	var m := S.value(s, s.tt.to_float())
	var y := sym(s)
	var T := D(s.tt)
	var L: Array = lines(s, "words")
	var table: Variant = null
	if rep == "table":
		L.append("The table gives the recorded values. The reading at t = %s was not used to fit the model." % T)
		table = {"rows": [["t", s.ts.map(func(t): return D(t))], [y + " (recorded)", s.ys.map(func(v): return D(v))]]}
	else:
		L.append("At t = %s the recorded %s was %s. This reading was not used to fit the model." % [T, c(s).name, amount(s, s.obs)])
	var O := D(s.obs)
	return pack(L, "Find the percentage error in the model's value at t = %s, against the recorded value." % T, ans, wr, fill, {
		"compare-data": ["The model gives %s(%s) = %s = %s." % [y, T, subst(s, s.tt), W7(m)],
			"The recorded value is %s, so the error is |%s − %s| = %s." % [O, W7(m), O, W(vals[2])],
			"ε = |%s − %s| ÷ %s × 100%% = %s%%" % [W7(m), O, O, W(e)], say(ans)],
	}, null, table)


# ── Two models ───────────────────────────────────────────────

func u_compare_two_models(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var y := sym(s)
	var T := D(s.tt)
	var pa := S.pred_a(s)
	var pb := S.pred_b(s)
	var o: Q = s.obs
	var P := {"A": amount(s, GdcKit.qf(pa)) if false else unit(s, Fmt.sf(pa)), "B": unit(s, Fmt.sf(pb))}
	var O := amount(s, o)
	var best: String = s.better
	var worst := "B" if best == "A" else "A"
	var right := "Model %s: it predicts %s, closer to the recorded %s than Model %s's %s." % [best, P[best], O, worst, P[worst]]
	var others: Array = [["Neither: Model %s's %s is not exactly the recorded %s, so neither model is suitable." % [best, P[best], O], R_ONE_ERROR],
		["Both equally: each passes exactly through the two readings it was fitted to, so both are good.", R_FITS_POINTS]]
	# The larger prediction is the exponential one's: a slip only when it is the worse.
	if best == "A":
		others.append(["Model B: its prediction, %s, is the larger of the two." % P.B, R_LARGER])
	others = rng.shuffled(others)
	others.append(["Model %s: it predicts %s, closer to the recorded %s than Model %s's %s." % [worst, P[worst], O, best, P[best]], ""])
	var built := claims(right, others)
	var L: Array = ["Two models are fitted to %s, where %s." % [c(s).of, tdef(s)],
		"Model A: %s(t) = %s" % [y, Fmt.terms([s.c0, s.c1], [0, 1], "t", true)],
		"Model B: %s(t) = %s × %s^t" % [y, D(s.A), D(s.b)],
		"Both pass exactly through the readings at t = 0 and t = 2, %s and %s." % [amount(s, s.y_a), amount(s, s.y_b)]]
	var table: Variant = null
	if rep == "table":
		L.append("The table gives the readings. The one at t = %s was not used to fit either model." % T)
		table = {"rows": [["t", ["0", "2", T]], [y + " (recorded)", [D(s.y_a), D(s.y_b), D(o)]]]}
	else:
		L.append("In %d (t = %s) the recorded %s was %s." % [s.y0 + int(s.tt.to_float()), T, c(s).name, O])
	var asked := "Which model predicts the reading at t = %s better? Give both predictions." % T
	return pack(L, asked, built.answer, built.wrongs, built.fillers, {
		"compare-data": ["Model A: %s(%s) = %s = %s" % [y, T, "%s %s %s × %s" % [D(s.c0), "−" if s.c1.sign() < 0 else "+", D(s.c1.abs_q()), T], W(pa)],
			"Model B: %s(%s) = %s × %s^%s = %s" % [y, T, D(s.A), D(s.b), T, W(pb)],
			"Against the recorded %s, Model A is %s off and Model B is %s off." % [D(o), W(absf(pa - o.to_float())), W(absf(pb - o.to_float()))],
			"So: " + right],
	}, null, table)


# ── An impossible value ──────────────────────────────────────

## Why the value is impossible, as the right option gives it.
static func reject_reason(s: Dictionary) -> String:
	match s.ctx:
		0:
			return "more than the %s people the wells can supply" % D(s.level)
		1:
			return "colder than the room's %s °C, which a cooling drink can't be" % D(s.level)
		2:
			return "below the ground, where the flare can't be"
		3:
			return "a negative value, which the truck can't have"
		4:
			return "more than the %s panels the roofs can hold" % D(s.level)
	return "a negative number of traders, which can't happen"


## A reason that is false on this question's own numbers.
static func false_reason(s: Dictionary) -> String:
	match s.ctx:
		0:
			return "fewer people than at the start"
		1:
			return "below 0 °C, where the tea would freeze"
		2:
			return "higher than the tower it was fired from"
		3:
			return "more than the truck was worth when it was bought"
		4:
			return "fewer panels than at the start"
	return "more traders than at the start"


## What the context sets, said against the value: the substitution's second line.
static func limit_check(s: Dictionary, v: String) -> String:
	match s.ctx:
		0:
			return "The wells can supply at most %s people, and %s is more." % [D(s.level), v]
		1:
			return "The tea cools towards the room's %s °C and can't go below it, and %s is below." % [D(s.level), v]
		2:
			return "A height below 0 m would put the flare under the ground."
		3:
			return "A truck can't be worth less than $0."
		4:
			return "The roofs can hold at most %s panels, and %s is more." % [D(s.level), v]
	return "There can't be fewer than 0 traders."


func u_reject_from_value(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var y := sym(s)
	var T := D(s.tb)
	var v: Variant = S.at(s, s.tb)
	var V := amount(s, v)
	var head := "%s(%s) = %s: " % [y, T, V]
	var right := head + reject_reason(s) + ", so the model fails there."
	var cap: bool = s.ctx in S.CAPS
	var built := claims(right, rng.shuffled([
		[head + "%s than the starting %s, which can't happen, so the model fails there." % ["more" if cap else "less", amount(s, S.start(s))], R_NO_REASON],
		[head + "a possible value, so the model still holds there.", ""],
		[head + false_reason(s) + ", so the model fails there.", ""]]))
	var L: Array = lines(s, rep) + limit_line(s)
	var asked := "Find %s(%s), and explain why it shows the model is not valid when t = %s." % [y, T, T]
	var value_line := "%s(%s) = %s = %s" % [y, T, subst(s, s.tb), V]
	return pack(L, asked, built.answer, built.wrongs, built.fillers, {
		"substitute-predict": [value_line, limit_check(s, V), "So: " + right],
		"long-run-behaviour": [trend(s), "It reaches %s at %s and keeps going: %s(%s) = %s." % [level_text(s), cross_text(s), y, T, V], "So: " + right],
		"context-sense": [context_line(s), "The model gives %s, which breaks that." % value_line, "So: " + right],
	})


# ── A limitation ─────────────────────────────────────────────

static func limitation_claim(s: Dictionary) -> String:
	var at := cross_text(s)
	match s.ctx:
		0:
			return "It grows without limit: it passes the %s people the wells can supply at %s, but the settlement can't hold more." % [D(s.level), at]
		1:
			return "It keeps falling: it goes below the room's %s °C at %s, but the tea only cools to the temperature of the room." % [D(s.level), at]
		2:
			return "It gives negative heights after %s, but the flare can't go below the ground: it has landed." % at
		3:
			return "It gives a negative value after %s, but the truck can't be worth less than $0." % at
	return "It grows without limit: it passes the %s panels the roofs can hold at %s, but the roofs can't take more." % [D(s.level), at]


## The model drawn from t = 0 past where it breaks the context, with the two readings it was
## fitted to as dots and the cap or the room's temperature dashed.
static func model_graph(s: Dictionary) -> Dictionary:
	var hi := ceili(maxf(s.cross * 1.3, s.t1.to_float() + 1.0))
	var fn := func(t): return S.value(s, t)
	var pts: Array = GdcKit.curve(fn, 0.0, float(hi))
	var lo := 0.0
	var top := 0.0
	for p in pts:
		lo = minf(lo, p[1])
		top = maxf(top, p[1])
	top = maxf(top, s.level.to_float())
	var pad := (top - lo) * 0.08
	var hl: Array = []
	if s.ctx in [0, 1, 4]:
		hl.append([s.level.to_float(), level_text(s)])
	var y1: Q = S.value_q(s, s.t1)
	var g := Plot.spec([pts], [[0.0, S.start(s).to_float(), ""], [s.t1.to_float(), y1.to_float(), ""]], 0, hi,
		floori(lo - pad) if lo < 0.0 else 0, ceili(top + pad), hl)
	g.x_name = "t"
	g.y_name = sym(s)
	return g


func u_limitation(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var y := sym(s)
	var right := limitation_claim(s)
	var y1: Q = S.value_q(s, s.t1)
	var y0 := amount(s, S.start(s))
	var built := claims(right, [["None: it passes exactly through the two readings it was fitted to, so it is a good model with no limitation.", R_FITS_POINTS]]
		+ rng.shuffled([["It can't be used at t = 0: the model gives no value there.", ""],
		["It starts from nothing: at t = 0 it gives 0, not the recorded %s." % y0, ""]]))
	var L: Array = lines(s, "words") + limit_line(s)
	L.append("The model was fitted to the readings at t = 0 and t = %s: %s and %s." % [D(s.t1), y0, amount(s, y1)])
	var graph: Variant = null
	if rep == "graph":
		L.append("The graph shows the model with the two readings it was fitted to.")
		graph = model_graph(s)
	var reach := "%s at %s" % [level_text(s), cross_text(s)]
	return pack(L, "Give one limitation of the model in this context.", built.answer, built.wrongs, built.fillers, {
		"long-run-behaviour": [trend(s), "It reaches %s and goes past it." % reach, "So: " + right],
		"context-sense": [context_line(s), "The model has no such limit: %s(t) reaches %s and carries on past it." % [y, reach], "So: " + right],
	}, graph)


# ── A prediction for a year ──────────────────────────────────

func u_year_to_t(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y := sym(s)
	var t: Q = s.tp
	var year: int = s.y0 + int(t.to_float())
	var key: Q = S.value_q(s, t)
	var slip: Q = S.value_q(s, Q.new(year))
	var ans := exact_ans(y + " = ", key, " dollars" if s.ctx == 3 else "")
	var what := {3: "the value of the truck", 4: "the number of panels on the roofs", 5: "the number of traders at the market"}
	var conv := "%d is t = %d − %d = %s." % [year, year, s.y0, D(t)]
	var pred := "%s(%s) = %s = %s" % [y, D(t), subst(s, t), D(key)]
	return pack(lines(s, rep), "Use the model to predict %s in %d." % [what[s.ctx], year], ans,
		[wrong({"v": slip}, R_CALENDAR)], [{"v": key.mul(2)}, {"v": key.div(2)}], {
		"substitute-predict": ["t counts the years after %d, so %s" % [s.y0, conv], pred, say(ans)],
		"gdc-solve": [conv, "In the GDC's solver, enter 0 = %s − %s and solve for %s." % [subst(s, t), y, y],
			"The solver gives %s = %s." % [y, D(key)], say(ans)],
	})


# ── Inside or outside the data ───────────────────────────────

func u_interpolate_or_extrapolate(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var first: int = s.y0
	var last: int = s.y0 + int(s.ts[-1].to_float())
	var yin: int = s.y0 + int(s.t_in.to_float())
	var yout: int = s.y0 + int(s.t_out.to_float())
	var past := yout - last
	var right := "The prediction for %d: it is inside the data's range, %d to %d (interpolation), while %d is %d years past it (extrapolation)." % [yin, first, last, yout, past]
	var built := claims(right, [
		["The prediction for %d: the model fits the data well, so it can be trusted far beyond the data too." % yout, R_EXTRAPOLATE],
		["Both equally: the same model gives both predictions, so they are equally reliable.", ""],
		["The prediction for %d: it comes after all the data, so it is based on more of it." % yout, ""]])
	var L: Array = lines(s, "words")
	var table: Variant = null
	if rep == "table":
		L.append("The model was fitted to the readings in the table.")
		table = {"rows": [["year", s.ts.map(func(t): return str(s.y0 + int(t.to_float())))], [sym(s), s.ys.map(func(v): return D(v))]]}
	else:
		L.append("The model was fitted to readings taken every two years from %d to %d." % [first, last])
	var two: Array = [yin, yout] if s.in_first else [yout, yin]
	L.append("It is used to predict the %s in %d and in %d." % [c(s).name, two[0], two[1]])
	return pack(L, "Which of the two predictions is more reliable? Give a reason.", built.answer, built.wrongs, built.fillers, {
		"interpolate-or-extrapolate": ["The readings run from %d to %d." % [first, last],
			"%d is inside that range: interpolation. %d is %d years past the last reading: extrapolation, where the pattern may not hold." % [yin, yout, past],
			"So: " + right],
	}, null, table)


# ── What a parameter means ───────────────────────────────────

## [the right meaning, the one in the wrong units, two fillers] for the parameter p (as written).
static func meanings(s: Dictionary, p: String) -> Array:
	var rate: bool = s.which == "rate"
	match s.ctx:
		0:
			if rate:
				var pc := D(s.b.sub(1).mul(100))
				return ["The population grows by %s%% each year: it is multiplied by %s every year." % [pc, p],
					"The population grows by %s people each year." % p,
					"The population at the start, in %d: %s people." % [s.y0, p],
					"The number of years the population takes to double: %s." % p]
			return ["The population at the start, in %d: %s people." % [s.y0, p],
				"The number of people who join the settlement each year: %s people per year." % p,
				"The most people the model allows: %s." % p,
				"The population grows by %s%% each year." % p]
		1:
			if rate:
				return ["The tea cools by %s °C each minute." % p, "The tea cools by %s °C in all." % p,
					"The tea's temperature when it is poured: %s °C." % p, "The time the tea takes to cool: %s minutes." % p]
			return ["The tea's temperature when it is poured: %s °C." % p, "The tea cools by %s °C each minute." % p,
				"The temperature of the room: %s °C." % p, "The time the tea takes to cool: %s minutes." % p]
		3:
			if rate:
				return ["The truck loses $%s of its value each year." % p, "The truck loses $%s of its value in all." % p,
					"The truck's value when it was bought, in %d: $%s." % [s.y0, p], "The number of years until the truck is worth nothing: %s." % p]
			return ["The truck's value when it was bought, in %d: $%s." % [s.y0, p], "The truck loses $%s of its value each year." % p,
				"The truck's value after one year: $%s." % p, "The number of years until the truck is worth nothing: %s." % p]
	if rate:
		return ["%s panels are added each year." % p, "%s panels are added in all." % p,
			"The number of panels in %d, when t = 0: %s." % [s.y0, p], "The number of years until the roofs are full: %s." % p]
	return ["The number of panels in %d, when t = 0: %s." % [s.y0, p], "%s panels are added each year." % p,
		"The most panels the roofs can hold: %s." % p, "The number of years until the roofs are full: %s." % p]


## The parameter as the model writes it: the rate without its sign.
static func param(s: Dictionary) -> String:
	if s.fam == "exp":
		return D(s.b) if s.which == "rate" else D(s.A)
	return D(s.c1.abs_q()) if s.which == "rate" else D(s.c0)


static func units_of(s: Dictionary) -> String:
	match s.ctx:
		0:
			return "people"
		1:
			return "°C"
		3:
			return "dollars"
	return "panels"


func u_interpret_parameter(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var p := param(s)
	var ms := meanings(s, p)
	var built := claims(ms[0], [[ms[1], R_UNITS]] + rng.shuffled([[ms[2], ""], [ms[3], ""]]))
	var y := sym(s)
	var per: String = c(s).per
	var steps: Array
	if s.fam == "exp":
		if s.which == "rate":
			steps = ["In %s, each extra year multiplies %s by %s." % [model(s), y, p],
				"%s = 1 + %s, so %s grows by %s%% each year; %s itself has no units." % [p, D(s.b.sub(1)), y, D(s.b.sub(1).mul(100)), p]]
		else:
			steps = ["At t = 0, %s^0 = 1, so %s(0) = %s." % [D(s.b), y, p],
				"It is a number of people, the population in %d, not a rate." % s.y0]
	elif s.which == "rate":
		steps = ["In %s, the %s multiplies t: each %s changes %s by %s, and the %s sign says it %s." % [model(s), p, per, y, p,
			"minus" if s.c1.sign() < 0 else "plus", "falls" if s.c1.sign() < 0 else "grows"],
			"So it is a rate, in %s per %s." % [units_of(s), per]]
	else:
		steps = ["At t = 0 the term in t is 0, so %s(0) = %s: the value at the start." % [y, p],
			"Its units are %s: an amount, not a rate." % units_of(s)]
	steps.append("So: " + ms[0])
	return pack(lines(s, rep), "What does the %s in the model mean in this context, with its units?" % p, built.answer, built.wrongs,
		built.fillers, {"any": steps})
