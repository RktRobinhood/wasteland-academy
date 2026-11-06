class_name RegressionInterpretViews
extends ExtensionViews
## The views on the `regression-interpret` situation: one builder per unknown of
## t4-regression-interpret. Every question is Paper 2. Most answers are a picked statement
## (Answer's `claim`, so multiple choice only); the expected change is a number to 3 s.f.
## Each wrong statement is false for the numbers shown, and the checker judges it from them.
##
## Representations: "table" (the data, with a story line; the GDC gives a, b and r), "equation"
## (the line to 3 s.f. with r and the story), "words" (the same in a sentence: a gradient and a
## y-intercept) and "graph" (a scatter of the data with the line drawn).

const AB := "SL4.4.interpret-ab#"
const R_AB_SWAP := AB + "0"
const R_BARE := AB + "1"
const R_B_FAR := AB + "2"
const R_BACKWARDS := AB + "3"
const R_SIGN := AB + "4"
const R_EXACT := AB + "5"
const R_B_MEAN := AB + "6"
const R_B_ROOT := AB + "7"
const R_EXTRA_AS_X := AB + "8"
const R_ONE_UNIT := AB + "9"
const R_ALWAYS_OUT := AB + "10"
const R_ON_POINTS := AB + "11"
const R_B_BARE := AB + "12"
const PR := "SL4.4.predict#"
const R_EXTRAPOLATE := PR + "0"
const R_REARRANGED := PR + "1"
const R_WEAK := PR + "2"
const R_NEAREST := PR + "3"
const R_NEVER := PR + "4"
const R_ACROSS := PR + "5"
const R_ORIGIN := "SL4.4.mean-point#0"

## The same method, said for b: the catalogue's name is about a.
const B_METHOD := "b is the predicted y when x = 0"

const UNKNOWNS := ["interpret-gradient", "expected-change", "interpret-intercept", "intercept-sensible", "judge-prediction", "flawed-estimate", "read-estimate"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## Every cell is Paper 2: every part of this type in the bank is.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = RegressionInterpretSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func T(v: Variant) -> String:
	return Fmt.sf(v)


static func W(v: Variant) -> String:
	return RegressionViews.W(v)


## r to 2 d.p.: "0.93", "−0.40".
static func R2(v: Q) -> String:
	return ("−" if v.sign() < 0 else "") + "%.2f" % v.abs_q().to_float()


static func story(s: Dictionary) -> Dictionary:
	return RegressionInterpretSituation.STORIES[s.ctx]


static func line_of(a: Q, b: Q) -> String:
	return "y = %sx %s %s" % [T(a), "−" if b.sign() < 0 else "+", T(b.abs_q())]


## The line's a and b as a GDC shows them on a table's question, or as they were given.
static func read_line(rep: String, s: Dictionary) -> String:
	if rep == "table":
		return "Enter x and y in two lists and run LinReg (ax + b): a = %s and b = %s." % [W(s.a), W(s.b)]
	return "The line is %s, so a = %s and b = %s." % [line_of(s.a3, s.b3), T(s.a3), T(s.b3)]


static func r_line(s: Dictionary) -> String:
	return "Pearson's r = %s" % R2(s.rr)


## What the student is shown of the data, as the representation has it.
static func setup(rep: String, s: Dictionary) -> Dictionary:
	var c := story(s)
	match rep:
		"table":
			return {"lines": ["The table shows the %s (x) and the %s (y) for %d %s." % [c.xl, c.yl, s.n, c.who]],
				"table": {"rows": [["x", s.xs.map(func(x): return str(x))], ["y", s.ys.map(func(y): return str(y))]]}}
		"equation":
			return {"lines": ["The regression line of y on x is %s." % line_of(s.a3, s.b3),
				"x is the %s and y is the %s, for %d %s." % [c.xl, c.yl, s.n, c.who], r_line(s)], "table": null}
		"words":
			return {"lines": ["A line fitted to data from %d %s predicts the %s (y) from the %s (x)." % [s.n, c.who, c.yl, c.xl],
				"Its gradient is %s and its y-intercept is %s." % [T(s.a3), T(s.b3)], r_line(s)], "table": null}
	return {"lines": ["The graph shows the %s (x) and the %s (y) for %d %s, with the regression line of y on x." % [c.xl, c.yl, s.n, c.who], r_line(s)],
		"table": null, "graph": scatter(s)}


## The line y = ua x + ub on the part of the window it stays in, and one dot per row.
static func scatter(s: Dictionary) -> Dictionary:
	var a: float = s.ua.to_float()
	var b: float = s.ub.to_float()
	var far: float = float(s.hi)
	if s.has("x0"):
		far = maxf(far, float(s.x0))
	var hi := int(ceilf(far * 1.1 / 5.0)) * 5
	var tallest: float = s.ys.max()
	if s.has("y0"):
		tallest = maxf(tallest, s.y0.to_float())
	var top := Plot.nice_top(tallest)
	var ends: Array = [0.0, float(hi)]
	if a != 0.0:
		var at_floor: float = -b / a
		var at_top: float = (top - b) / a
		var low := minf(at_floor, at_top)
		var high := maxf(at_floor, at_top)
		ends = [maxf(0.0, low), minf(float(hi), high)]
	var f := func(x: float) -> float: return a * x + b
	var points: Array = []
	for i in s.n:
		points.append([s.xs[i], s.ys[i], ""])
	var vlines: Array = [[s.x0, "x = %d" % s.x0]] if s.has("x0") else []
	return Plot.spec([Plot.sample(f, ends[0], ends[1])], points, 0, hi, 0, top, [], vlines)


## The statements, in a fresh order: the first three are the wrong options.
static func statements(right: String, wrongs_in: Array, rng: Seeded) -> Dictionary:
	return DerivativeMeaningViews.claim_answer(right, rng.shuffled(wrongs_in))


## "rises by about 2.31 km"
static func moves(a: Q, c: Dictionary, about: String = "about") -> String:
	return "%s by %s %s %s" % ["rises" if a.sign() > 0 else "falls", about, T(a.abs_q()), c.uy]


static func right_gradient(s: Dictionary) -> String:
	var c := story(s)
	return "For each %s, the %s %s on average." % [c.per, c.y, moves(s.a3, c)]


static func signed_sum(v: Q) -> String:
	return "%s %s" % ["−" if v.sign() < 0 else "+", D(v.abs_q())]


# ── The gradient ─────────────────────────────────────────────

func u_interpret_gradient(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := story(s)
	var a: Q = s.a3
	var b: Q = s.b3
	var right := right_gradient(s)
	var made := statements(right, [
		["The %s starts at about %s %s, and changes by about %s %s for each %s." % [c.y, T(a), c.uy, T(b), c.uy, c.per], R_AB_SWAP],
		["%s is only the gradient of the line: it has no meaning for the %s." % [T(a), c.who], R_BARE],
		["A rise of 1 %s in the %s goes with a %s of about %s %s in the %s." % [c.uy1, c.y, "rise" if a.sign() > 0 else "fall", T(a.abs_q()), c.ux, c.x], R_BACKWARDS],
		["For each %s, the %s %s on average." % [c.per, c.y, moves(a.neg(), c)], R_SIGN],
		["For each %s, the %s of every one of the %s %s." % [c.per, c.y, c.who, moves(a, c, "exactly")], R_EXACT]], rng)
	var out := setup(rep, s)
	out.asked = "The regression line of y on x is y = ax + b. Interpret, in context, the value of a."
	out.answer = made.answer
	out.wrongs = made.wrongs
	var p: int = s.lo
	var y1: Q = a.mul(Q.new(p)).add(b)
	var y2: Q = a.mul(Q.new(p + 1)).add(b)
	out.methods = {
		"per-unit-sentence": method([read_line(rep, s),
			"a is the change in y for one more unit of x: here, the change in the %s for each %s." % [c.y, c.per],
			"a is %s, so the %s %s as x grows. Real points sit off the line, so this is an average." % ["positive" if a.sign() > 0 else "negative", c.y, "rises" if a.sign() > 0 else "falls"],
			right], made.answer.values),
		"two-predictions": method([read_line(rep, s) + (" To 3 s.f., y = %s." % line_of(a, b).trim_prefix("y = ") if rep == "table" else ""),
			"At x = %d, y = %s × %d %s = %s. At x = %d, y = %s × %d %s = %s." % [p, T(a), p, signed_sum(b), D(y1), p + 1, T(a), p + 1, signed_sum(b), D(y2)],
			"The difference is %s − %s = %s, which is a." % [D(y2), D(y1) if y1.sign() >= 0 else "(%s)" % D(y1), D(y2.sub(y1))],
			right], made.answer.values)}
	return out


func u_expected_change(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := story(s)
	var k: int = s.k
	var a: Q = s.ua
	var b: Q = s.ub
	var ans := Answer.make("number", {"v": s.ch}, {}, "change = ", " " + c.uy)
	ans.show = "sf"
	var out := setup(rep, s)
	out.asked = "What change in the %s does the line predict when %s? Give your answer to 3 s.f., with a minus sign for a fall." % [c.y, c.up % k]
	out.answer = ans
	out.wrongs = [wrong({"v": a}, R_ONE_UNIT), wrong({"v": a.mul(Q.new(k)).add(b)}, R_EXTRA_AS_X), wrong({"v": b.mul(Q.new(k))}, R_AB_SWAP)]
	out.generic = [{"v": s.ch.neg()}, {"v": s.ch.mul(Q.new(11, 10))}, {"v": s.ch.mul(Q.new(9, 10))}]
	var p: int = s.p
	var y1: Q = a.mul(Q.new(p)).add(b)
	var y2: Q = a.mul(Q.new(p + k)).add(b)
	var last := "So " + Answer.text(ans) + "."
	var two: Array
	if rep == "table":
		two = [read_line(rep, s), "At x = %d, y ≈ %s. At x = %d, y ≈ %s." % [p, W(y1), p + k, W(y2)],
			"The difference is %s − %s ≈ %s." % [W(y2), W(y1), W(s.ch)], last]
	else:
		two = [read_line(rep, s), "At x = %d, y = %s. At x = %d, y = %s." % [p, D(y1), p + k, D(y2)],
			"The difference is %s − %s = %s." % [D(y2), D(y1) if y1.sign() >= 0 else "(%s)" % D(y1), D(s.ch)], last]
	out.methods = {
		"per-unit-sentence": method([read_line(rep, s),
			"a is the change in y for one more unit of x, so %d more units change y by %d × a." % [k, k],
			"%d × %s %s %s" % [k, W(a) if rep == "table" else T(a), "≈" if rep == "table" else "=", W(s.ch) if rep == "table" else D(s.ch)], last], ans.values),
		"two-predictions": method(two, ans.values)}
	return out


# ── The intercept ────────────────────────────────────────────

func u_interpret_intercept(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := story(s)
	var a: Q = s.a3
	var b: Q = s.b3
	var right := "The %s the line gives when the %s is 0 %s: about %s %s." % [c.y, c.x, c.ux, T(b), c.uy]
	var made := statements(right, [
		["The change in the %s for each %s: about %s %s." % [c.y, c.per, T(b), c.uy], R_AB_SWAP],
		["A constant of the line, which has no units and tells nothing about the %s." % c.who, R_B_BARE],
		["The mean %s of the %s: about %s %s." % [c.y, c.who, T(b), c.uy], R_B_MEAN],
		["The %s at which the %s reaches 0: about %s %s." % [c.x, c.y, T(b), c.ux], R_B_ROOT]], rng)
	var out := setup(rep, s)
	out.asked = "The regression line of y on x is y = ax + b. Explain what the value of b represents here."
	out.answer = made.answer
	out.wrongs = made.wrongs
	out.titles = {"per-unit-sentence": B_METHOD}
	out.methods = {"per-unit-sentence": method([read_line(rep, s),
		"Put x = 0 into y = ax + b: y = a × 0 + b = b.",
		"So b is what the line gives for the %s when the %s is 0 %s, in %s." % [c.y, c.x, c.ux, c.uy],
		right], made.answer.values)}
	return out


func u_intercept_sensible(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := story(s)
	var b: Q = s.b3
	var value := "%s %s" % [T(b), c.uy]
	var right := ""
	var wrongs: Array = []
	var steps: Array = [read_line(rep, s), "b is what the line gives at x = 0, so ask whether the line can fairly be used at x = 0."]
	if s.case == "sensible":
		right = "Yes: x = 0 is in the data, so about %s is a fair estimate for %s." % [value, c.zero]
		wrongs = [["No: x = 0 is outside the data, so b can't mean anything.", R_ALWAYS_OUT],
			["No: b is not one of the y-values in the data, so it is not a real value.", R_ON_POINTS],
			["No: a line fitted to data must pass through the origin, so b should be 0.", R_ORIGIN]]
		steps.append("The lowest x in the data is 0, so this estimate is inside the data, and %s is a possible amount." % value)
	else:
		var tail := ", and a negative %s can't happen." % c.y if s.case == "negative" else ", so the line can't be trusted there."
		right = "No: x = 0 is far outside the data, which start at x = %d%s" % [s.lo, tail]
		wrongs = [["Yes: every regression line gives a value at x = 0, so about %s is a sound estimate." % value, R_B_FAR],
			["Yes: r is strong, so the line holds all the way down to x = 0.", R_EXTRAPOLATE],
			["No: a line fitted to data must pass through the origin, so b should be 0.", R_ORIGIN]]
		steps.append("The lowest x in the data is %d, so x = 0 is far outside the data%s." % [s.lo, ", and b is negative" if s.case == "negative" else ""])
	var made := statements(right, wrongs, rng)
	steps.append(right)
	var out := setup(rep, s)
	if rep != "table":
		out.lines.append("In the data, x runs from %d to %d." % [s.lo, s.hi])
	out.asked = "The regression line of y on x is y = ax + b. Does the value of b have a sensible meaning here?"
	out.answer = made.answer
	out.wrongs = made.wrongs
	out.titles = {"per-unit-sentence": B_METHOD}
	out.methods = {"per-unit-sentence": method(steps, made.answer.values)}
	return out


# ── Judging an estimate ──────────────────────────────────────

func u_judge_prediction(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var x0: int = s.x0
	var at := "x = %d" % x0
	var good := "Reliable: %s is inside the data and the correlation is strong." % at
	var outside := "Not reliable: %s is outside the data, which run from %d to %d." % [at, s.lo, s.hi]
	var weak := "Not reliable: the correlation is weak."
	var no_line := "Not reliable: a line of y on x can't be used to estimate y."
	var right: String = {"good": good, "outside": outside, "weak": weak}[s.case]
	var wrongs: Array = []
	if s.case == "outside":
		wrongs = [["Reliable: r is strong, so the line holds for any x.", R_EXTRAPOLATE], [weak, ""], [no_line, ""]]
	elif s.case == "weak":
		wrongs = [[good, R_WEAK], ["Reliable: %s is inside the data, so the line can be trusted there." % at, R_WEAK], [outside, ""], [no_line, ""]]
	else:
		wrongs = [["Not reliable: an estimate from a regression line can never be trusted.", R_NEVER], [weak, ""], [outside, ""], [no_line, ""]]
	var made := statements(right, wrongs, rng)
	var out := setup(rep, s)
	if rep == "equation":
		out.lines.append("In the data, x runs from %d to %d." % [s.lo, s.hi])
	out.asked = "A scout uses the line to estimate y when x = %d, and gets y ≈ %s. Comment on the reliability of this estimate." % [x0, T(s.y0)]
	out.answer = made.answer
	out.wrongs = made.wrongs
	var inside: bool = x0 >= s.lo and x0 <= s.hi
	var first := "Is x inside the data? The data run from %d to %d, so %d is %s them." % [s.lo, s.hi, x0, "inside" if inside else "outside"]
	var r_said: String = "Run LinReg on the lists: r = %s" % W(GdcKit.qf(s.r)) if rep == "table" else "r = %s" % R2(s.rr)
	out.methods = {"reliability-check": method([first, "Is the correlation strong? %s, so it is %s." % [r_said, "weak" if s.case == "weak" else "strong"], right], made.answer.values)}
	return out


func u_flawed_estimate(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := setup(rep, s)
	var a: Q = s.a3
	var b: Q = s.b3
	if rep == "table":
		out.lines.append("The regression line of y on x is %s." % line_of(a, b))
	if rep == "equation":
		out.lines.append("In the data, x runs from %d to %d and y from %d to %d." % [s.lo, s.hi, s.ys.min(), s.ys.max()])
	var r_word := "Run LinReg on the lists: r = %s" % W(GdcKit.qf(s.r)) if rep == "table" else "r = %s" % R2(s.rr)
	var right := ""
	var wrongs: Array = []
	var steps: Array = []
	var too_weak := "The correlation is too weak for any estimate."
	if s.case == "outside":
		right = "x = %d is outside the data, which run from %d to %d, so the line may not hold there." % [s.x0, s.lo, s.hi]
		wrongs = [["Nothing is wrong: r is strong, so the line holds for any x.", R_EXTRAPOLATE],
			["The line must be rearranged to make x the subject first.", ""],
			[too_weak, ""]]
		out.lines.append("A scout estimates y when x = %d: y = %s × %d %s ≈ %s" % [s.x0, T(a), s.x0, signed_sum(b), T(s.y0)])
		steps = ["%s, so the correlation is strong, and the arithmetic is right." % r_word,
			"The data run from x = %d to x = %d, and %d is well %s that." % [s.lo, s.hi, s.x0, "above" if s.x0 > s.hi else "below"], right]
	else:
		var y: int = s.given_y
		right = "x is being estimated, so the line of x on y is needed: the line of y on x only estimates y."
		wrongs = [["Nothing is wrong: rearranging a line gives the same estimate.", R_REARRANGED],
			["y = %d is outside the data, so the line may not hold there." % y, ""],
			[too_weak, ""],
			["The sign is wrong: it should be x = (%d + %s) ÷ %s." % [y, T(b), T(a)], ""]]
		out.lines.append("A scout knows that y = %d and estimates x: %d = %sx %s, so x ≈ %s" % [y, y, T(a), signed_sum(b), T(s.xr)])
		steps = ["%s, so the correlation is strong, and y = %d is inside the data." % [r_word, y],
			"The line of y on x makes the vertical gaps small, to estimate y. It is a different line from the line of x on y unless r = ±1.",
			right]
	var made := statements(right, wrongs, rng)
	out.asked = "Give a reason why this method is not appropriate."
	out.answer = made.answer
	out.wrongs = made.wrongs
	out.methods = {"reliability-check": method(steps, made.answer.values)}
	return out


func u_read_estimate(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := story(s)
	var said := func(v: int) -> String: return "About %d %s" % [v, c.uy]
	var right: String = said.call(s.read)
	var wrongs: Array = []
	if s.near != s.read:
		wrongs.append([said.call(s.near), R_NEAREST])
	if s.across != s.read and s.across != s.near and s.across > 0 and s.across <= s.ys.max():
		wrongs.append([said.call(s.across), R_ACROSS])
	var taken: Array = [s.near, s.across]
	for step in [10, -10, 20, -20, 30, 40]:
		var v: int = s.read + step
		if v > 0 and not v in taken and wrongs.size() < 3:
			wrongs.append([said.call(v), ""])
	var made := DerivativeMeaningViews.claim_answer(right, wrongs)
	var out := setup(rep, s)
	out.lines = out.lines.slice(0, 1)
	out.asked = "Read from the line an estimate of the %s when x = %d, to the nearest 5." % [c.y, s.x0]
	out.answer = made.answer
	out.wrongs = made.wrongs
	out.methods = {"read-off-line": method(["Go up from x = %d to the line, not to the nearest dot." % s.x0, "Go across to the y-axis: the line is at about y = %d there." % s.read, right], made.answer.values)}
	return out
