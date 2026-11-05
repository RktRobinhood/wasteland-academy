class_name BoxPlotViews
extends ExtensionViews
## The views on the `box-plot` situation: one builder per unknown of t4-box-plot and
## t4-outlier-rule, which share it (FAL-740). Every value is exact: a quartile or a fence is
## written in full on both papers, so the answers carry `exact`. Only a new mean on Paper 2 is to
## 3 s.f. GDC methods are Paper 2 only.
##
## Representations: "graph" (PlotView's `box` to scale, or `cumfreq`), "terms" (a list), "table"
## (a frequency table or a table of summary statistics) and "words" (the five numbers in a line).
##
## A decision is answered like a test of independence: the two numbers typed, the verdict picked.
## Picking a box plot is one figure of four rows on one axis, so each stays readable at 390 wide:
## the answer is the `choice` kind, "Plot A" to "Plot D".

const BOX := "SL4.2.box-plot#"
const CMP := "SL4.2.compare-distributions#"
const TST := "SL4.2.outlier-test#"
const DEC := "SL4.1.outlier-decision#"
const R_LONGER := BOX + "0"
const R_WHISKER := BOX + "1"
const R_KEEP_MEDIAN := BOX + "2"
const R_UNSORTED := BOX + "3"
const R_NO_FREQ := BOX + "4"
const R_BOX_MIDDLE := BOX + "5"
const R_WHOLE := BOX + "6"
const R_NO_CROSS := BOX + "7"
const R_AXIS := BOX + "8"
const R_LEVELS := BOX + "9"
const R_ENDS := BOX + "10"
const R_SIDE := BOX + "11"
const R_RANGE_SHAPE := BOX + "12"
const R_SHAPE_BACK := BOX + "13"
const R_EQUAL := BOX + "14"
const R_POSITIONS := BOX + "15"
const R_TO_FENCE := BOX + "16"
const R_ENDS_ONLY := CMP + "0"
const R_SPREAD_AVG := CMP + "1"
const R_NO_CONTEXT := CMP + "2"
const R_CLAIM_BACK := CMP + "3"
const R_THREE := TST + "0"
const R_FROM_MEDIAN := TST + "1"
const R_LOOKS_FAR := TST + "2"
const R_FAR_FENCE := TST + "3"
const R_BACKWARDS := TST + "4"
const R_NO_FACTOR := TST + "5"
const R_ON_FENCE := TST + "6"
const R_QUARTILE_DIST := TST + "7"
const R_DELETE := DEC + "0"
const R_SAME_MOVE := DEC + "1"
const R_KEEP_ALL := DEC + "2"
const R_OLD_N := DEC + "3"
const R_MEDIAN_FIXED := DEC + "4"
const R_SWAP_MEASURES := DEC + "5"
const R_DIRECTION := DEC + "6"

const IS := "is an outlier"
const NOT := "is not an outlier"
const NORMAL := "are symmetric and could be normal"
const SKEWED := "are skewed and unlikely to be normal"
const SUPPORT := "support"
const OPPOSE := "do not support"
const NAMES := ["min", "q1", "med", "q3", "max"]
const PLOTS := ["Plot A", "Plot B", "Plot C", "Plot D"]
const LETTERS := ["A", "B", "C", "D"]
const RULE := "An outlier is a value less than Q1 − 1.5 × IQR or greater than Q3 + 1.5 × IQR."
const HALVES := "Q1 and Q3 are the medians of the lower and upper halves, leaving out the median when n is odd."

## The stories: who is measured, the words before them, the short noun, the unit, the axis, the two
## groups, how to say the first of two is higher in a typical case, the noun with its article, and
## the unit in words.
const STORIES := [
	{"who": "patrols", "by": "the distance walked in a day by", "noun": "distance walked", "unit": "km", "axis": "distance walked (km)", "groups": ["north patrols", "south patrols"], "typ": "walked further", "a": "a distance walked", "in": "km"},
	{"who": "crates", "by": "the mass of", "noun": "mass", "unit": "kg", "axis": "mass (kg)", "groups": ["salvage crates", "market crates"], "typ": "were heavier", "a": "a mass", "in": "kg"},
	{"who": "drones", "by": "the flight time of", "noun": "flight time", "unit": "min", "axis": "flight time (minutes)", "groups": ["old drones", "new drones"], "typ": "flew for longer", "a": "a flight time", "in": "minutes"},
	{"who": "wells", "by": "the depth of", "noun": "depth", "unit": "m", "axis": "depth (m)", "groups": ["hill wells", "valley wells"], "typ": "were deeper", "a": "a depth", "in": "m"},
	{"who": "tanks", "by": "the water held in", "noun": "water held", "unit": "L", "axis": "water held (litres)", "groups": ["roof tanks", "yard tanks"], "typ": "held more", "a": "water held", "in": "litres"},
	{"who": "traders", "by": "the takings of", "noun": "takings", "unit": "caps", "axis": "takings (caps)", "groups": ["gate traders", "market traders"], "typ": "took more", "a": "takings", "in": "caps"},
	{"who": "bean plants", "by": "the height of", "noun": "height", "unit": "cm", "axis": "height (cm)", "groups": ["shaded plants", "sunlit plants"], "typ": "grew taller", "a": "a height", "in": "cm"},
	{"who": "radios", "by": "the battery life of", "noun": "battery life", "unit": "h", "axis": "battery life (hours)", "groups": ["scrap radios", "trade radios"], "typ": "lasted longer", "a": "a battery life", "in": "hours"},
]
## keep-or-remove: what is recorded, the limit in words, and the reason a value past it can't be.
const LIMITS := [
	["the water in one tank, in litres", "The tank holds at most %s litres.", "the tank can't hold that much"],
	["the depth to the water in one well, in m", "The well is %s m deep.", "the well isn't that deep"],
	["the hours a scavenger worked in a week", "The camp's rule stops a week at %s hours.", "the rule stops the week before that"],
	["the charge of a radio battery, in amp hours", "A full battery holds %s amp hours.", "a battery can't hold that much"],
	["the top speed of a drone, in km/h", "These drones are built to fly at no more than %s km/h.", "the drones can't fly that fast"],
	["the mass of a cart's load, in kg", "The bridge scale reads up to %s kg and every cart crossed it.", "the scale can't read that high"],
]

const UNKNOWNS := ["read-median", "read-quartile", "read-iqr", "read-range", "read-median-iqr", "five-number-from-data", "five-number-from-cumfreq",
	"pick-box-from-data", "pick-box-with-outlier", "count-in-section", "percent-in-section", "value-at-share", "could-be-normal", "mean-against-median",
	"compare-box-plots", "compare-summary", "claim-from-box-plots",
	"find-fences", "decide-outlier", "show-max-outlier", "largest-not-outlier", "smallest-outlier", "quartile-from-no-outliers", "outliers-in-data",
	"keep-or-remove", "effect-of-removing", "which-measure-moves"]
const GDC := ["gdc-stats", "gdc-modified-box"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, angle_id: String) -> Array:
	if not has(unknown):
		return []
	return [2] if angle_id in GDC else [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = BoxPlotSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func story(s: Dictionary) -> Dictionary:
	return STORIES[s.ctx]


## "12 km", "12 caps".
static func U(s: Dictionary, v: Variant) -> String:
	return "%s %s" % [D(v), story(s).unit]


static func num(s: Dictionary, label: String, v: Variant) -> Dictionary:
	var ans := Answer.make("number", {"v": Q.of(v)}, {}, label, " " + story(s).unit)
	ans.show = "dec"
	ans.exact = true
	return ans


static func final_step(ans: Dictionary) -> String:
	return Answer.text(ans) + "."


static func nums(xs: Array) -> Array:
	return xs.filter(func(x): return x.sign() > 0).map(func(x): return {"v": x})


## Only a wrong number above 0 is offered.
static func wr(v: Q, ref: String) -> Array:
	return [wrong({"v": v}, ref)] if v.sign() > 0 else []


static func row(f: Dictionary, name: String = "") -> Dictionary:
	return {"name": name, "min": D(f.min), "q1": D(f.q1), "med": D(f.med), "q3": D(f.q3), "max": D(f.max), "out": f.out.map(func(x): return D(x))}


static func fig(s: Dictionary, rows: Array) -> Dictionary:
	return {"kind": "box", "x0": D(s.x0), "x1": D(s.x1), "tick": D(s.tick), "every": BoxPlotSituation.EVERY, "name": story(s).axis, "boxes": rows}


## The figure of one group, or of two with their names.
static func figure(s: Dictionary) -> Dictionary:
	if s.two:
		var g: Array = story(s).groups
		return fig(s, [row(s.a, g[0]), row(s.b, g[1])])
	return fig(s, [row(s.a)])


static func plot_line(s: Dictionary) -> String:
	var c := story(s)
	if s.two:
		return "The box plots show %s the %s and the %s." % [c.by, c.groups[0], c.groups[1]]
	return "The box plot shows %s %d %s." % [c.by, s.n, c.who]


## The box asked about, and the words that name it in a question.
static func chosen(s: Dictionary) -> Dictionary:
	if s.two:
		return s.b if s.which == 1 else s.a
	return s.a


static func of_group(s: Dictionary) -> String:
	return " of the %s" % story(s).groups[s.which] if s.two else ""


## The figure's step of a worked solution on two boxes.
static func which_box(s: Dictionary) -> String:
	return "the box for the %s" % story(s).groups[s.which] if s.two else "the box"


static func cap(t: String) -> String:
	return t.left(1).to_upper() + t.substr(1)


static func five_line(f: Dictionary) -> String:
	return "The least value is %s, Q1 = %s, the median is %s, Q3 = %s and the greatest value is %s." % [D(f.min), D(f.q1), D(f.med), D(f.q3), D(f.max)]


## The data as the student sees it, by representation: lines and a table.
static func data_lines(s: Dictionary, name_of: String) -> Array:
	if s.rep == "table":
		return ["The table shows %s." % name_of]
	return [cap(name_of) + ":", ", ".join(s.xs.map(func(x): return D(x)))]


static func data_name(s: Dictionary) -> String:
	var c := story(s)
	return "%s %d %s, in %s" % [c.by, s.n, c.who, c["in"]]


static func data_table(s: Dictionary) -> Variant:
	if s.rep != "table":
		return null
	return {"rows": [["x", s.xs.map(func(x): return D(x))], ["Frequency", s.fs.map(func(f): return str(f))]]}


static func ordinal(i: int) -> String:
	return DataSummaryViews.ordinal(i)


## "the 6th value", or "halfway between the 3rd and 4th values".
static func place(lo: int, n: int) -> String:
	if n % 2 == 1:
		return "the %s value" % ordinal(lo + DataSummarySituation.half(n))
	var h := DataSummarySituation.half(n)
	return "halfway between the %s and %s values" % [ordinal(lo + h - 1), ordinal(lo + h)]


## By-hand steps: from the data to the quartiles.
static func hand_steps(s: Dictionary) -> Array:
	var a: Dictionary = s.a
	var n: int = s.n
	var h := DataSummarySituation.half(n)
	var first: String
	if s.rep == "table":
		var run: Array = []
		var t := 0
		for f in s.fs:
			t += int(f)
			run.append(str(t))
		first = "The running totals of the frequencies are %s, so n = %d." % [", ".join(run), n]
	elif s.paper == 1:
		first = "The list is in order, with n = %d." % n
	else:
		first = "In order, the %d values are %s." % [n, ", ".join(s.data.map(func(x): return D(x)))]
	var skip := " The median is left out of both halves." if n % 2 == 1 else ""
	return [first, "The median is %s: %s.%s" % [place(1, n), D(a.med), skip],
		"Q1 is %s: %s. Q3 is %s: %s." % [place(1, h), D(a.q1), place(n - h + 1, h), D(a.q3)]]


## The GDC steps for the five numbers, with what is keyed in and what is read off.
static func gdc_steps(s: Dictionary) -> Array:
	var a: Dictionary = s.a
	var enter := "Enter the values in list L1 and the frequencies in list L2." if s.rep == "table" else "Enter the %d values in list L1." % s.n
	var run := "Run 1-Var Stats with L2 as the frequency list." if s.rep == "table" else "Run 1-Var Stats on L1."
	return [enter, run, "Read off minX = %s, Q1 = %s, Med = %s, Q3 = %s and maxX = %s." % [D(a.min), D(a.q1), D(a.med), D(a.q3), D(a.max)]]


# ── Reading a box plot ───────────────────────────────────────

func u_read_median(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f := chosen(s)
	var ans := num(s, "median = ", f.med)
	var mid: Q = f.q1.add(f.q3).div(Q.new(2))
	return {"answer": ans, "lines": [plot_line(s)], "graph": figure(s), "asked": "Write down the median %s%s." % [story(s).noun, of_group(s)],
		"wrongs": wr(mid, R_BOX_MIDDLE), "generic": nums([f.min.add(f.max).div(Q.new(2)), f.q1, f.q3, f.min, f.max]),
		"methods": {"any": method(["The median is the line inside %s. It is at %s on the scale." % [which_box(s), D(f.med)], final_step(ans)], ans.values)}}


func u_read_quartile(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.a
	var low: bool = s.which == "Q1"
	var v: Q = f.q1 if low else f.q3
	var ans := num(s, "%s = " % s.which, v)
	var word := "lower" if low else "upper"
	return {"answer": ans, "lines": [plot_line(s)], "graph": figure(s), "asked": "Write down the %s quartile of the %s." % [word, story(s).noun],
		"wrongs": [], "generic": nums([f.q3 if low else f.q1, f.med, f.min if low else f.max, f.max if low else f.min]),
		"methods": {"any": method(["The %s quartile is the %s edge of the box, at %s." % [word, "left" if low else "right", D(v)], final_step(ans)], ans.values)}}


func u_read_iqr(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f := chosen(s)
	var v: Q = f.q3.sub(f.q1)
	var ans := num(s, "IQR = ", v)
	return {"answer": ans, "lines": [plot_line(s)], "graph": figure(s), "asked": "Find the interquartile range%s." % of_group(s),
		"wrongs": wr(f.max.sub(f.min), R_WHOLE) + wr(f.q1.add(f.q3), "SL4.3.quartiles-discrete#0"), "generic": nums([f.q3.sub(f.med), f.med.sub(f.q1), f.q3, f.q1]),
		"methods": {"any": method(["Read the edges of %s: Q1 = %s and Q3 = %s." % [which_box(s), D(f.q1), D(f.q3)], "IQR = Q3 − Q1 = %s − %s = %s" % [D(f.q3), D(f.q1), D(v)], final_step(ans)], ans.values)}}


func u_read_range(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.a
	var crossed: bool = not f.out.is_empty()
	var top: Q = f.out[0] if crossed else f.max
	var v: Q = top.sub(f.min)
	var ans := num(s, "range = ", v)
	var lines: Array = [plot_line(s)]
	if crossed:
		lines.append("A cross marks an outlier.")
	var w: Array = wr(f.q3.sub(f.q1), R_WHOLE)
	if crossed:
		w = wr(f.max.sub(f.min), R_NO_CROSS) + w
	var read := "The least value is %s. The greatest is the cross, at %s: an outlier is still a value of the data." % [D(f.min), D(top)] if crossed \
		else "The whiskers end at the least value, %s, and the greatest, %s." % [D(f.min), D(top)]
	return {"answer": ans, "lines": lines, "graph": figure(s), "asked": "Find the range of the %s." % story(s).noun, "wrongs": w,
		"generic": nums([top, f.q3.sub(f.min), top.sub(f.q1), top.sub(f.med)]),
		"methods": {"any": method([read, "range = %s − %s = %s" % [D(top), D(f.min), D(v)], final_step(ans)], ans.values)}}


## The answer of two labelled numbers, with its text, for a slot l and a slot r.
static func two_numbers(s: Dictionary, a: String, l: Q, b: String, r: Q) -> Dictionary:
	var v := {"l": l, "r": r, "text": "%s = %s, %s = %s" % [a, U(s, l), b, U(s, r)]}
	var ans := Answer.make("form", v, {"parts": [a + " = ", {"slot": "l"}, " " + story(s).unit + ", " + b + " = ", {"slot": "r"}, " " + story(s).unit]})
	ans.exact = true
	return ans


static func two_wrong(s: Dictionary, a: String, l: Q, b: String, r: Q, ref: String) -> Dictionary:
	return wrong({"l": l, "r": r, "text": "%s = %s, %s = %s" % [a, U(s, l), b, U(s, r)]}, ref)


func u_read_median_iqr(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f := chosen(s)
	var iq: Q = f.q3.sub(f.q1)
	var ans := two_numbers(s, "median", f.med, "IQR", iq)
	var mid: Q = f.q1.add(f.q3).div(Q.new(2))
	return {"answer": ans, "lines": [plot_line(s)], "graph": figure(s), "asked": "Write down the median and the interquartile range%s." % of_group(s),
		"wrongs": [two_wrong(s, "median", mid, "IQR", iq, R_BOX_MIDDLE), two_wrong(s, "median", f.med, "IQR", f.max.sub(f.min), R_WHOLE),
			wrong({"l": f.med, "r": f.q3.sub(f.med), "text": "median = %s, IQR = %s" % [U(s, f.med), U(s, f.q3.sub(f.med))]}, ""),
			wrong({"l": f.q1, "r": iq, "text": "median = %s, IQR = %s" % [U(s, f.q1), U(s, iq)]}, "")],
		"generic": [], "methods": {"any": method(["The median is the line inside %s: %s." % [which_box(s), D(f.med)],
			"The IQR is the width of the box: %s − %s = %s" % [D(f.q3), D(f.q1), D(iq)], final_step(ans)], ans.values)}}


# ── The five numbers ─────────────────────────────────────────

static func five_text(f: Dictionary) -> String:
	return "min = %s, Q1 = %s, median = %s, Q3 = %s, max = %s" % [D(f.min), D(f.q1), D(f.med), D(f.q3), D(f.max)]


static func five_values(f: Dictionary) -> Dictionary:
	return {"p": f.min, "q": f.q1, "r": f.med, "t": f.q3, "u": f.max, "text": five_text(f)}


static func five_answer(f: Dictionary) -> Dictionary:
	var ans := Answer.make("form", five_values(f), {"parts": ["min = ", {"slot": "p"}, ", Q1 = ", {"slot": "q"}, ", median = ", {"slot": "r"},
		", Q3 = ", {"slot": "t"}, ", max = ", {"slot": "u"}]})
	ans.exact = true
	return ans


## The wrong summaries of a data set, the tagged ones first, as far as each is one.
static func data_slips(s: Dictionary) -> Array:
	var out: Array = []
	if s.n % 2 == 1:
		out.append([BoxPlotSituation.keep_median(s.data), R_KEEP_MEDIAN])
	out.append([BoxPlotSituation.positions(s.data), R_POSITIONS])
	if s.rep == "table":
		out.append([BoxPlotSituation._quartiles_of(s.xs), R_NO_FREQ])
	elif s.paper == 2:
		out.append([BoxPlotSituation.unsorted(s.xs), R_UNSORTED])
	return out


func u_five_number_from_data(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Dictionary = s.a
	var ans := five_answer(a)
	var wrongs: Array = []
	for slip in data_slips(s):
		wrongs.append(wrong(five_values(slip[0]), slip[1]))
	var bump := func(v: Q, by: int) -> Q:
		return v.add(by)
	var generic: Array = [five_values(BoxPlotSituation.five(a.min, a.q1, bump.call(a.med, 1), a.q3, a.max)),
		five_values(BoxPlotSituation.five(a.min, bump.call(a.q1, 1), a.med, bump.call(a.q3, -1), a.max)),
		five_values(BoxPlotSituation.five(a.min, bump.call(a.q1, -1), a.med, bump.call(a.q3, 1), a.max))]
	var name := data_name(s)
	return {"answer": ans, "lines": data_lines(s, name) + [HALVES], "table": data_table(s), "asked": "Find the five-number summary of the data.",
		"wrongs": wrongs, "generic": generic,
		"methods": {"five-number-summary": method(hand_steps(s) + ["The least value is %s and the greatest is %s. %s." % [D(a.min), D(a.max), Answer.text(ans)]], ans.values),
			"gdc-stats": method(gdc_steps(s) + [final_step(ans)], ans.values)}}


func u_five_number_from_cumfreq(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Dictionary = s.a
	var ans := five_answer(a)
	var c: Dictionary = CumulativeFrequencyViews.CONTEXTS[s.ctx]
	var n: int = s.n
	var x1 := Q.new(CumulativeFrequencySituation.SQUARES * s.dx)
	var quarter := func(k: int) -> Q:
		return x1.mul(Q.new(k, 4))
	var wrongs: Array = [wrong(five_values(BoxPlotSituation.five(a.min, quarter.call(1), quarter.call(2), quarter.call(3), a.max)), R_AXIS),
		wrong(five_values(BoxPlotSituation.five(a.min, Q.new(n, 4), Q.new(n, 2), Q.new(3 * n, 4), a.max)), R_LEVELS),
		wrong(five_values(BoxPlotSituation.five(Q.new(0), a.q1, a.med, a.q3, x1)), R_ENDS)]
	var g := CumulativeFrequencyViews.curve_spec(s)
	return {"answer": ans, "lines": CumulativeFrequencyViews.graph_lines(s), "graph": g, "asked": "Find the five numbers of a box plot of the data, min, Q1, median, Q3 and max, from the curve.",
		"wrongs": wrongs, "generic": [five_values(BoxPlotSituation.five(a.min, a.q1.add(s.dx), a.med, a.q3.sub(s.dx), a.max))], "methods": {"from-cumfreq": method([
			"There are %d %s, so read across at %d ÷ 4 = %s, %d ÷ 2 = %s and 3 × %d ÷ 4 = %s." % [n, c.who, n, D(Q.new(n, 4)), n, D(Q.new(n, 2)), n, D(Q.new(3 * n, 4))],
			"Down to the axis, these give Q1 = %s, median = %s and Q3 = %s." % [D(a.q1), D(a.med), D(a.q3)],
			"The curve leaves 0 at %s and reaches %d at %s: the least and greatest values." % [D(a.min), n, D(a.max)], final_step(ans)], ans.values)}}


## One figure of four rows, on one axis, the letters shuffled.
static func pick_figure(s: Dictionary, rng: Seeded, tags: Dictionary) -> Dictionary:
	var order := rng.shuffled(s.rows)
	var rows: Array = []
	var right := ""
	var wrongs: Array = []
	for i in order.size():
		rows.append(row(order[i].five, LETTERS[i]))
		if order[i].ref == "right":
			right = PLOTS[i]
		else:
			wrongs.append(wrong({"v": PLOTS[i]}, tags.get(order[i].mistake, "")))
	var ans := Answer.make("choice", {"v": right}, {"options": PLOTS})
	return {"answer": ans, "graph": fig(s, rows), "wrongs": wrongs}


func u_pick_box_from_data(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: Dictionary = s.a
	var tags := {"keep-median": R_KEEP_MEDIAN, "positions": R_POSITIONS, "no-frequency": R_NO_FREQ, "unsorted": R_UNSORTED, "box-middle": R_BOX_MIDDLE}
	var out := pick_figure(s, rng, tags)
	var ans: Dictionary = out.answer
	out.lines = data_lines(s, data_name(s)) + [HALVES]
	out.table = data_table(s)
	out.asked = "Which box plot shows these data?"
	out.generic = []
	var match_step := "%s has its box from %s to %s, its line at %s and its whiskers to %s and %s." % [ans.values.v, D(a.q1), D(a.q3), D(a.med), D(a.min), D(a.max)]
	out.methods = {"five-number-summary": method(hand_steps(s) + ["The least value is %s and the greatest is %s." % [D(a.min), D(a.max)], match_step], ans.values),
		"gdc-stats": method(gdc_steps(s) + [match_step], ans.values)}
	return out


func u_pick_box_with_outlier(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: Dictionary = s.a
	var inside: Q = s.data[s.data.size() - 2]
	var out := pick_figure(s, rng, {"whisker": R_WHISKER, "fence": R_TO_FENCE})
	var ans: Dictionary = out.answer
	out.lines = data_lines(s, data_name(s)) + [HALVES, RULE]
	out.table = null
	out.asked = "Which box plot shows these data, with any outlier as a cross?"
	out.generic = []
	var fence := "Q3 + 1.5 × IQR = %s + 1.5 × %s = %s, and %s is above it, so it is an outlier." % [D(a.q3), D(s.iqr), D(s.hi_f), D(s.x)]
	var end := "%s has a cross at %s and its upper whisker at %s, the greatest value that is not an outlier." % [ans.values.v, D(s.x), D(inside)]
	var hand: Array = hand_steps(s)
	out.methods = {"five-number-summary": method([hand[0], hand[1] + " " + hand[2], fence, end], ans.values),
		"gdc-stats": method(["Enter the %d values in list L1." % s.n, "Run 1-Var Stats on L1 and read off Q1 = %s, Med = %s and Q3 = %s." % [D(a.q1), D(a.med), D(a.q3)], fence, end], ans.values)}
	return out


# ── What the quarters hold ───────────────────────────────────

static func mark_of(s: Dictionary, k: int) -> Q:
	return s.a[NAMES[k]]


func u_count_in_section(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := story(s)
	var k: int = s.kb - s.ka
	var lo := mark_of(s, s.ka)
	var hi := mark_of(s, s.kb)
	var v := Q.new(s.n * k, 4)
	var ans := Answer.make("number", {"v": v}, {}, "number = ", " " + c.who)
	ans.exact = true
	ans.show = "dec"
	var slip: Q = hi.sub(lo).div(s.a.max.sub(s.a.min)).mul(Q.new(s.n))
	var out := {"answer": ans, "asked": "Estimate the number of %s with %s between %s and %s." % [c.who, c.a, D(lo), D(hi)],
		"wrongs": wr(slip, R_LONGER), "generic": nums([Q.new(s.n * ((k % 4) + 1), 4), Q.new(25 * k), Q.new(s.n, 4), Q.new(s.n * (4 - k), 4), Q.new(s.n, 2)])}
	if rep == "words":
		out.lines = ["For %s %d %s:" % [c.by, s.n, c.who], five_line(s.a)]
	else:
		out.lines = [plot_line(s)]
		out.graph = figure(s)
	var what: String = "That is %d of the four sections" % k if k > 1 else "That is one of the four sections"
	out.methods = {"any": method(["Each section of a box plot holds a quarter of the data, however long it looks. %s, from %s to %s." % [what, D(lo), D(hi)],
		"%d ÷ 4 × %d = %s" % [s.n, k, D(v)], final_step(ans)], ans.values)}
	return out


func u_percent_in_section(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := story(s)
	var k: int = s.kb - s.ka
	var lo := mark_of(s, s.ka)
	var hi := mark_of(s, s.kb)
	var v := Q.new(25 * k)
	var ans := Answer.make("number", {"v": v}, {}, "percentage = ", "%")
	ans.exact = true
	var slip: Q = hi.sub(lo).div(s.a.max.sub(s.a.min)).mul(Q.new(100))
	return {"answer": ans, "lines": [plot_line(s)], "graph": figure(s), "asked": "Estimate the percentage of the %s with %s between %s and %s." % [c.who, c.a, D(lo), D(hi)],
		"wrongs": wr(slip, R_LONGER), "generic": nums([Q.new(25 * ((k % 4) + 1)), Q.new(25 * (4 - k)), Q.new(10), Q.new(100 - 10 * k)]),
		"methods": {"any": method(["Each section of a box plot holds a quarter of the data, however long it looks.",
			"From %s to %s is %d section%s, so %d × 25 = %d" % [D(lo), D(hi), k, "" if k == 1 else "s", k, 25 * k], final_step(ans)], ans.values)}}


func u_value_at_share(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := story(s)
	var f: Dictionary = s.a
	var words: String = s.share[0]
	var side: String = s.share[1]
	var mark: String = s.share[2]
	var v: Q = f[mark]
	var ans := num(s, "a = ", v)
	var w: Array = []
	if mark == "med":
		w = wr(f.q1.add(f.q3).div(Q.new(2)), R_BOX_MIDDLE)
	else:
		w = wr(f.q3 if mark == "q1" else f.q1, R_SIDE)
	var name: String = {"med": "the median", "q1": "the lower quartile", "q3": "the upper quartile"}[mark]
	var share_words: String = {"Half": "half", "A quarter": "a quarter", "Three quarters": "three quarters"}[words]
	return {"answer": ans, "lines": [plot_line(s)], "graph": figure(s), "asked": "%s of the %s have %s %s a %s. Estimate the value of a." % [words, c.who, c.a, side, c.unit],
		"wrongs": w, "generic": nums([f.med, f.q1, f.q3, f.min.add(f.max).div(Q.new(2)), f.min, f.max]),
		"methods": {"any": method(["%s lies with %s of the data %s it." % [cap(name), share_words, side], "On the plot, %s is at %s." % [name, D(v)], final_step(ans)], ans.values)}}


# ── Shape ────────────────────────────────────────────────────

func u_could_be_normal(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f: Dictionary = s.a
	var l: Q = f.med.sub(f.q1)
	var r: Q = f.q3.sub(f.med)
	var verdict := NORMAL if l.eq(r) else SKEWED
	var said := func(which: String) -> String:
		return "median − Q1 = %s and Q3 − median = %s, so the data %s" % [D(l), D(r), which]
	var v := {"l": l, "r": r, "verdict": verdict, "text": said.call(verdict)}
	var ans := Answer.make("form", v, {"parts": ["median − Q1 = ", {"slot": "l"}, " and Q3 − median = ", {"slot": "r"}, ", so the data ", {"pick": "verdict", "options": [NORMAL, SKEWED]}]})
	ans.exact = true
	var other := SKEWED if l.eq(r) else NORMAL
	var one := "range = %s, so the data " % D(f.max.sub(f.min))
	var w1: Q = f.q1.sub(f.min)
	var w2: Q = f.max.sub(f.q3)
	var why := "The two halves of the box match and so do the whiskers, so the plot is symmetric, and a normal curve is symmetric about its centre." if l.eq(r) \
		else "The two halves of the box differ and so do the whiskers, so the plot is lopsided, and a normal curve is symmetric."
	return {"answer": ans, "lines": [plot_line(s)], "graph": figure(s), "asked": "State, with a reason, whether the data could be normally distributed.",
		"wrongs": [wrong({"l": l, "r": r, "verdict": other, "text": said.call(other)}, R_SHAPE_BACK),
			wrong({"text": one + NORMAL, "shape": "one number"}, R_RANGE_SHAPE), wrong({"text": one + SKEWED, "shape": "one number"}, R_RANGE_SHAPE)],
		"generic": [], "methods": {"any": method(["In the box, median − Q1 = %s − %s = %s and Q3 − median = %s − %s = %s." % [D(f.med), D(f.q1), D(l), D(f.q3), D(f.med), D(r)],
			"The whiskers are %s and %s long." % [D(w1), D(w2)], why, Answer.text(ans) + "."], ans.values)}}


func u_mean_against_median(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var up: bool = s.skew == "up"
	var more := "greater" if up else "less"
	var less := "less" if up else "greater"
	var tail := "upper" if up else "lower"
	var pull := "high" if up else "low"
	var right := "The mean is likely to be %s than the median: the long %s whisker holds a few %s values, which pull the mean that way." % [more, tail, pull]
	var w: Array = [["The mean is likely to be %s than the median: the long %s whisker holds more of the data." % [less, tail], R_LONGER],
		["The mean and the median are likely to be equal: half of the data lie on each side of the median.", R_EQUAL],
		["The mean is likely to be %s than the median: the box is longer than either whisker." % more, ""]]
	var made := DerivativeMeaningViews.claim_answer(right, w)
	var ans: Dictionary = made.answer
	var f: Dictionary = s.a
	return {"answer": ans, "lines": [plot_line(s)], "graph": figure(s), "asked": "State how the mean is likely to compare with the median, with a reason.",
		"wrongs": made.wrongs, "generic": [], "methods": {"any": method([
			"The upper whisker is %s long and the lower is %s long. The median is off centre in the box." % [D(f.max.sub(f.q3)), D(f.q1.sub(f.min))],
			"The median depends only on the middle of the data, but the mean uses every value, so the few values far along the %s whisker pull it that way." % tail,
			right], ans.values)}}


# ── Comparing ────────────────────────────────────────────────

static func group(s: Dictionary, i: int) -> String:
	return "the %s" % story(s).groups[i]


static func compare_text(s: Dictionary, g_hi: int, word: String, hi: Q, lo: Q, g_steady: int, spread: String, sp: Q, sq: Q) -> String:
	var c := story(s)
	return "%s typically %s: %s %s against %s. %s were more consistent: %s %s against %s." % [cap(group(s, g_hi)), c.typ, word, U(s, hi), U(s, lo), cap(group(s, g_steady)), spread, U(s, sp), U(s, sq)]


## Options 1 to 4 of a comparison. values: [centre a, centre b, spread a, spread b, max a, max b].
static func compare_claims(s: Dictionary, word: String, spread: String, v: Array) -> Dictionary:
	var g_hi: int = 0 if v[1].lt(v[0]) else 1
	var g_lo: int = 1 - g_hi
	var g_steady: int = 0 if v[2].lt(v[3]) else 1
	var g_wide: int = 1 - g_steady
	var g_top: int = 0 if v[5].lt(v[4]) else 1
	var c := story(s)
	var right := compare_text(s, g_hi, word, v[g_hi], v[g_lo], g_steady, spread, v[2 + g_steady], v[2 + g_wide])
	var w: Array = [["%s typically %s: maximum %s against %s. %s were more consistent: %s %s against %s." % [cap(group(s, g_top)), c.typ, U(s, v[4 + g_top]), U(s, v[5 - g_top]), cap(group(s, g_steady)), spread, U(s, v[2 + g_steady]), U(s, v[2 + g_wide])], R_ENDS_ONLY],
		["%s typically %s: %s %s against %s. %s were less consistent: %s %s against %s." % [cap(group(s, g_wide)), c.typ, spread, U(s, v[2 + g_wide]), U(s, v[2 + g_steady]), cap(group(s, g_wide)), spread, U(s, v[2 + g_wide]), U(s, v[2 + g_steady])], R_SPREAD_AVG],
		["The %ss are %s and %s, and the %ss are %s and %s." % [word, U(s, v[0]), U(s, v[1]), spread, U(s, v[2]), U(s, v[3])], R_NO_CONTEXT]]
	return {"made": DerivativeMeaningViews.claim_answer(right, w), "g_hi": g_hi, "g_steady": g_steady, "right": right}


func u_compare_box_plots(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Dictionary = s.a
	var b: Dictionary = s.b
	var ia: Q = a.q3.sub(a.q1)
	var ib: Q = b.q3.sub(b.q1)
	var cl := compare_claims(s, "median", "IQR", [a.med, b.med, ia, ib, a.max, b.max])
	var ans: Dictionary = cl.made.answer
	return {"answer": ans, "lines": [plot_line(s)], "graph": figure(s), "asked": "Compare the two groups, in context.", "wrongs": cl.made.wrongs, "generic": [],
		"methods": {"median-iqr": method(["The medians, for the centre, are %s and %s." % [U(s, a.med), U(s, b.med)],
			"The IQRs, for the spread, are %s − %s = %s and %s − %s = %s." % [D(a.q3), D(a.q1), D(ia), D(b.q3), D(b.q1), D(ib)],
			"A higher median means a higher typical value, and a smaller IQR means more consistent values.", cl.right], ans.values)}}


func u_compare_summary(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var g: Array = story(s).groups
	var c := story(s)
	var cl := compare_claims(s, "mean", "standard deviation", [s.ma, s.mb, s.sa, s.sb, s.ta, s.tb])
	var ans: Dictionary = cl.made.answer
	var table := {"rows": [["", [g[0], g[1]]], ["Mean", [D(s.ma), D(s.mb)]], ["Standard deviation", [D(s.sa), D(s.sb)]], ["Maximum", [D(s.ta), D(s.tb)]]]}
	return {"answer": ans, "lines": ["The table summarises %s two groups, in %s." % [c.by, c["in"]]], "table": table, "asked": "Compare the two groups, in context.", "wrongs": cl.made.wrongs, "generic": [],
		"methods": {"mean-sd": method(["The means, for the centre, are %s and %s." % [U(s, s.ma), U(s, s.mb)],
			"The standard deviations, for the spread, are %s and %s." % [U(s, s.sa), U(s, s.sb)],
			"A higher mean means a higher typical value, and a smaller standard deviation means more consistent values. The maximum is one value and says little about either.", cl.right], ans.values)}}


func u_claim_from_box_plots(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := story(s)
	var g: Array = c.groups
	var a: Dictionary = s.a
	var b: Dictionary = s.b
	var first: int = s.claim
	var other: int = 1 - first
	var mine: Dictionary = a if first == 0 else b
	var yours: Dictionary = b if first == 0 else a
	var holds: bool = yours.med.lt(mine.med)
	var verdict := SUPPORT if holds else OPPOSE
	var flip := OPPOSE if holds else SUPPORT
	var said := func(word: String, l: Q, r: Q, which: String) -> String:
		return "The %s is %s for the %s and %s for the %s, so the plots %s the claim" % [word, D(l), g[0], D(r), g[1], which]
	var v := {"l": a.med, "r": b.med, "verdict": verdict, "text": said.call("median", a.med, b.med, verdict)}
	var ans := Answer.make("form", v, {"parts": ["The median is ", {"slot": "l"}, " for the %s and " % g[0], {"slot": "r"}, " for the %s, so the plots " % g[1], {"pick": "verdict", "options": [SUPPORT, OPPOSE]}, " the claim"]})
	ans.exact = true
	var ia: Q = a.q3.sub(a.q1)
	var ib: Q = b.q3.sub(b.q1)
	var name_a: String = g[first]
	var name_b: String = g[other]
	return {"answer": ans, "lines": [plot_line(s), "Mara claims that the %s typically %s than the %s." % [name_a, c.typ, name_b]], "graph": figure(s),
		"asked": "Decide whether the box plots support the claim, with a valid reason.",
		"wrongs": [wrong({"l": a.med, "r": b.med, "verdict": flip, "text": said.call("median", a.med, b.med, flip)}, R_CLAIM_BACK),
			wrong({"text": said.call("maximum", a.max, b.max, flip), "shape": "the maxima"}, R_ENDS_ONLY),
			wrong({"text": said.call("IQR", ia, ib, verdict), "shape": "the IQRs"}, R_SPREAD_AVG)],
		"generic": [], "methods": {"median-iqr": method(["The typical value of a group is its median: the line in each box.",
			"The median is %s for the %s and %s for the %s." % [D(a.med), g[0], D(b.med), g[1]],
			"The claim is about the %s, whose median is the %s." % [name_a, "higher" if holds else "lower"], Answer.text(ans) + "."], ans.values)}}


# ── The outlier rule ─────────────────────────────────────────

## The data as a question on the rule shows it: a box, a list or five numbers.
static func rule_lines(rep: String, s: Dictionary, out: Dictionary) -> void:
	var c := story(s)
	match rep:
		"graph":
			out.lines = [plot_line(s), RULE]
			out.graph = figure(s)
		"terms":
			out.lines = data_lines(s, data_name(s)) + [HALVES, RULE]
		_:
			out.lines = ["For %s %d %s:" % [c.by, s.n, c.who], five_line(s.a), RULE]


## The opening step: where the quartiles come from. The rule needs nothing else of the data.
static func quartile_step(rep: String, s: Dictionary) -> String:
	var a: Dictionary = s.a
	match rep:
		"graph":
			return "From the box plot, Q1 = %s and Q3 = %s, so IQR = %s − %s = %s." % [D(a.q1), D(a.q3), D(a.q3), D(a.q1), D(s.iqr)]
		"terms":
			var hand := hand_steps(s)
			return "%s %s IQR = %s − %s = %s." % [hand[0], hand[2], D(a.q3), D(a.q1), D(s.iqr)]
	return "Q1 = %s and Q3 = %s, so IQR = %s − %s = %s." % [D(a.q1), D(a.q3), D(a.q3), D(a.q1), D(s.iqr)]


static func onehalf(v: Q) -> Q:
	return v.mul(Q.new(3, 2))


static func fences_said(s: Dictionary, lo: Q, hi: Q) -> Dictionary:
	return {"l": lo, "r": hi, "text": "lower fence = %s, upper fence = %s" % [D(lo), D(hi)]}


func u_find_fences(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Dictionary = s.a
	var d := onehalf(s.iqr)
	var v := fences_said(s, s.lo_f, s.hi_f)
	var ans := Answer.make("form", v, {"parts": ["lower fence = ", {"slot": "l"}, ", upper fence = ", {"slot": "r"}]})
	ans.exact = true
	var out := {"answer": ans, "table": null, "asked": "Find the two values beyond which a value is an outlier: Q1 − 1.5 × IQR, the lower fence, and Q3 + 1.5 × IQR, the upper fence."}
	rule_lines(rep, s, out)
	out.wrongs = [wrong(fences_said(s, a.med.sub(d), a.med.add(d)), R_FROM_MEDIAN), wrong(fences_said(s, a.q1.sub(s.iqr), a.q3.add(s.iqr)), R_NO_FACTOR),
		wrong(fences_said(s, s.lo_f, onehalf(a.q3)), R_THREE)]
	out.generic = [fences_said(s, s.lo_f.add(s.iqr), s.hi_f), fences_said(s, s.lo_f, s.hi_f.add(s.iqr))]
	out.methods = {"fences": method([quartile_step(rep, s), "1.5 × IQR = 1.5 × %s = %s" % [D(s.iqr), D(d)],
		"Lower fence: %s − %s = %s. Upper fence: %s + %s = %s." % [D(a.q1), D(d), D(s.lo_f), D(a.q3), D(d), D(s.hi_f)], final_step(ans)], ans.values)}
	return out


## The two numbers a test compares, for the method asked, and the two that its slips give.
func compared(s: Dictionary) -> Dictionary:
	var a: Dictionary = s.a
	var up: bool = s.side == "up"
	var d := onehalf(s.iqr)
	var x: Q = s.x
	var q: Q = a.q3 if up else a.q1
	if angle == "fences":
		var fence: Q = s.hi_f if up else s.lo_f
		var name := "upper fence" if up else "lower fence"
		return {"ln": "IQR", "lv": s.iqr, "rn": name, "rv": fence, "beyond": x.lt(fence) if not up else fence.lt(x)}
	var dist: Q = x.sub(q) if up else q.sub(x)
	var ln := "%s − Q3" % D(x) if up else "Q1 − %s" % D(x)
	return {"ln": ln, "lv": dist, "rn": "1.5 × IQR", "rv": d, "beyond": d.lt(dist)}


static func test_text(s: Dictionary, cmp: Dictionary, l: Q, r: Q, verdict: String) -> String:
	return "%s = %s and %s = %s, so %s %s" % [cmp.ln, D(l), cmp.rn, D(r), D(s.x), verdict]


## The wrong options of a test. Each is a slip that leads to its own verdict, and two options end
## in each verdict: BoxPlotSituation keeps the value where that is so.
func test_wrongs(s: Dictionary, cmp: Dictionary) -> Array:
	var a: Dictionary = s.a
	var up: bool = s.side == "up"
	var d := onehalf(s.iqr)
	var x: Q = s.x
	var right := IS if cmp.beyond else NOT
	var other := NOT if cmp.beyond else IS
	var out: Array = [wrong({"l": cmp.lv, "r": cmp.rv, "verdict": other, "text": test_text(s, cmp, cmp.lv, cmp.rv, other)}, R_BACKWARDS)]
	if angle == "fences":
		var by_median: Q = a.med.add(d) if up else a.med.sub(d)
		out.append(wrong({"l": s.iqr, "r": by_median, "verdict": IS, "text": test_text(s, cmp, s.iqr, by_median, IS)}, R_FROM_MEDIAN))
		if up:
			var three := onehalf(a.q3)
			out.append(wrong({"l": s.iqr, "r": three, "verdict": NOT, "text": test_text(s, cmp, s.iqr, three, NOT)}, R_THREE))
		else:
			out.append(wrong({"text": "IQR = %s and upper fence = %s, so %s %s" % [D(s.iqr), D(s.hi_f), D(x), NOT], "shape": "the other fence"}, R_FAR_FENCE))
	else:
		var by_median: Q = x.sub(a.med) if up else a.med.sub(x)
		out.append(wrong({"l": by_median, "r": d, "verdict": IS, "text": test_text(s, cmp, by_median, d, IS)}, R_FROM_MEDIAN))
		var far: Q = onehalf(a.q3 if up else a.q1)
		out.append(wrong({"l": cmp.lv, "r": far, "verdict": NOT, "text": test_text(s, cmp, cmp.lv, far, NOT)}, R_THREE if up else R_QUARTILE_DIST))
	assert(right != other)
	return out


func u_decide_outlier(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Dictionary = s.a
	var up: bool = s.side == "up"
	var cmp := compared(s)
	var verdict := IS if cmp.beyond else NOT
	var v := {"l": cmp.lv, "r": cmp.rv, "verdict": verdict, "text": test_text(s, cmp, cmp.lv, cmp.rv, verdict)}
	var ans := Answer.make("form", v, {"parts": [cmp.ln + " = ", {"slot": "l"}, " and " + cmp.rn + " = ", {"slot": "r"}, ", so %s " % D(s.x), {"pick": "verdict", "options": [IS, NOT]}]})
	ans.exact = true
	var out := {"answer": ans, "table": null, "asked": "Determine whether %s is an outlier, with a valid reason." % D(s.x), "generic": []}
	rule_lines(rep, s, out)
	out.wrongs = test_wrongs(s, cmp)
	var d := onehalf(s.iqr)
	var q: Q = a.q3 if up else a.q1
	var fence: Q = s.hi_f if up else s.lo_f
	var sign := "+" if up else "−"
	var dist: Q = cmp.lv if angle == "distance-from-quartile" else (s.x.sub(q) if up else q.sub(s.x))
	var low := "above" if up else "below"
	var fence_end := "%s is %s the fence, so it is %san outlier." % [D(s.x), ("above" if up else "below") if cmp.beyond else ("not above" if up else "not below"), "" if cmp.beyond else "not "]
	var dist_end := "%s is %s %s, %s 1.5 × IQR, so it is %san outlier." % [D(s.x), D(dist), low + " the quartile", "more than" if cmp.beyond else "no more than", "" if cmp.beyond else "not "]
	out.methods = {"fences": method([quartile_step(rep, s), "The fence is %s %s 1.5 × %s = %s" % [D(q), sign, D(s.iqr), D(fence)], fence_end, final_step(ans)], ans.values),
		"distance-from-quartile": method([quartile_step(rep, s), "1.5 × IQR = 1.5 × %s = %s" % [D(s.iqr), D(d)],
			"The nearest quartile is %s, and %s − %s = %s." % [D(q), D(s.x if up else q), D(q if up else s.x), D(dist)], dist_end + " " + final_step(ans)], ans.values)}
	return out


func u_show_max_outlier(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Dictionary = s.a
	var cmp := compared(s)
	var d := onehalf(s.iqr)
	var end := ", so %s %s" % [D(s.x), IS]
	var said := func(l: Q, r: Q) -> String:
		return "%s = %s and %s = %s%s" % [cmp.ln, D(l), cmp.rn, D(r), end]
	var v := {"l": cmp.lv, "r": cmp.rv, "text": said.call(cmp.lv, cmp.rv)}
	var ans := Answer.make("form", v, {"parts": [cmp.ln + " = ", {"slot": "l"}, " and " + cmp.rn + " = ", {"slot": "r"}, end]})
	ans.exact = true
	var out := {"answer": ans, "table": null, "asked": "Show that the greatest value, %s, is an outlier." % D(s.x), "generic": []}
	rule_lines(rep, s, out)
	var w: Array
	if angle == "fences":
		w = [[s.iqr, a.med.add(d), R_FROM_MEDIAN], [s.iqr, onehalf(a.q3), R_THREE], [s.iqr, a.q3.add(s.iqr), R_NO_FACTOR]]
	else:
		w = [[s.x.sub(a.med), d, R_FROM_MEDIAN], [cmp.lv, onehalf(a.q3), R_THREE], [cmp.lv, s.iqr, R_NO_FACTOR]]
	out.wrongs = w.map(func(e): return wrong({"l": e[0], "r": e[1], "text": said.call(e[0], e[1])}, e[2]))
	out.generic = [cmp.lv.add(s.iqr), cmp.rv.add(s.iqr)].map(func(e): return {"l": cmp.lv, "r": e, "text": said.call(cmp.lv, e)})
	var dist: Q = s.x.sub(a.q3)
	out.methods = {"fences": method([quartile_step(rep, s), "The upper fence is %s + 1.5 × %s = %s" % [D(a.q3), D(s.iqr), D(s.hi_f)],
			"%s is above %s, so it is an outlier." % [D(s.x), D(s.hi_f)], final_step(ans)], ans.values),
		"distance-from-quartile": method([quartile_step(rep, s), "1.5 × IQR = 1.5 × %s = %s" % [D(s.iqr), D(d)],
			"The nearest quartile is Q3: %s − %s = %s, which is more than %s." % [D(s.x), D(a.q3), D(dist), D(d)], final_step(ans)], ans.values)}
	return out


func u_largest_not_outlier(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Dictionary = s.a
	var d := onehalf(s.iqr)
	var ans := num(s, "largest value = ", s.hi_f)
	var out := {"answer": ans, "table": null, "asked": "Find the largest value that would not be an outlier."}
	rule_lines(rep, s, out)
	out.wrongs = wr(onehalf(a.q3), R_THREE) + wr(a.med.add(d), R_FROM_MEDIAN) + wr(a.q3.add(s.iqr), R_NO_FACTOR)
	out.generic = nums([a.q3.add(s.iqr.mul(2)), s.hi_f.add(Q.new(1)), s.hi_f.add(s.tick) if s.has("tick") else s.hi_f.add(2)])
	out.methods = {"fences": method([quartile_step(rep, s), "Only a value above the upper fence is an outlier, so the fence itself is the largest that is not.",
			"Q3 + 1.5 × IQR = %s + 1.5 × %s = %s" % [D(a.q3), D(s.iqr), D(s.hi_f)], final_step(ans)], ans.values),
		"distance-from-quartile": method([quartile_step(rep, s), "A value can lie up to 1.5 × IQR above Q3: 1.5 × %s = %s" % [D(s.iqr), D(d)],
			"%s + %s = %s" % [D(a.q3), D(d), D(s.hi_f)], final_step(ans)], ans.values)}
	return out


func u_smallest_outlier(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Dictionary = s.a
	var d := onehalf(s.iqr)
	var f: Q = s.hi_f
	var top := Q.new(floori(f.to_float()))
	var v := top.add(1)
	var ans := num(s, "smallest outlier = ", v)
	var out := {"answer": ans, "table": null, "asked": "Every value is a whole number. Find the smallest value that would be an outlier."}
	rule_lines(rep, s, out)
	var whole := func(x: Q) -> Q:
		return Q.new(floori(x.to_float())).add(1)
	out.wrongs = wr(top, R_ON_FENCE) + wr(whole.call(onehalf(a.q3)), R_THREE) + wr(whole.call(a.med.add(d)), R_FROM_MEDIAN) + wr(whole.call(a.q3.add(s.iqr)), R_NO_FACTOR)
	out.generic = nums([v.add(1), v.add(2)])
	var next := "A value must be above %s to be an outlier, so the smallest whole number that is above it is %s." % [D(f), D(v)]
	out.methods = {"fences": method([quartile_step(rep, s), "The upper fence is %s + 1.5 × %s = %s" % [D(a.q3), D(s.iqr), D(f)], next, final_step(ans)], ans.values),
		"distance-from-quartile": method([quartile_step(rep, s), "An outlier lies more than 1.5 × %s = %s above Q3." % [D(s.iqr), D(d)],
			"%s + %s = %s. %s" % [D(a.q3), D(d), D(f), next], final_step(ans)], ans.values)}
	return out


func u_quartile_from_no_outliers(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := story(s)
	var a: Dictionary = s.a
	var iq: Q = s.iqr_given
	var d := onehalf(iq)
	var low_u: Q = a.max.sub(d)
	var low_l: Q = low_u.sub(iq)
	var is_u: bool = s.which == "U"
	var v: Q = low_u if is_u else low_l
	var ans := num(s, "%s = " % s.which, v)
	var out := {"answer": ans, "table": null, "asked": "Find the minimum possible value of %s." % s.which}
	var facts := "The interquartile range is %s and there are no outliers." % U(s, iq)
	var names := "L and U are the lower and upper quartiles."
	if rep == "graph":
		out.lines = ["The box plot, not drawn to scale, shows %s a group of %s. %s" % [c.by, c.who, names], facts, RULE]
		out.graph = {"kind": "box", "scale": false, "name": c.axis, "boxes": [row(a)], "labels": [D(a.min), "L", D(a.med), "U", D(a.max)]}
	else:
		out.lines = ["For %s a group of %s, the least value is %s, the median is %s and the greatest value is %s. %s" % [c.by, c.who, D(a.min), D(a.med), D(a.max), names], facts, RULE]
	var slip_u: Q = a.max.div(Q.new(3, 2))
	out.wrongs = (wr(a.max.sub(iq), R_NO_FACTOR) + (wr(slip_u, R_THREE) if not D(slip_u).contains("/") else [])) if is_u else (wr(a.max.sub(iq).sub(iq), R_NO_FACTOR))
	out.generic = nums([low_l if is_u else low_u, a.max.sub(iq.mul(2)), low_u.add(iq), a.med.add(d), v.add(a.med.sub(a.min))])
	var hence := [] if is_u else ["L = U − IQR, and the smallest U gives the smallest L: %s − %s = %s" % [D(low_u), D(iq), D(low_l)]]
	out.methods = {"fences": method(["The greatest value, %s, is no outlier, so it is at most the upper fence: %s ≤ U + 1.5 × %s." % [D(a.max), D(a.max), D(iq)],
			"1.5 × %s = %s, so %s ≤ U + %s." % [D(iq), D(d), D(a.max), D(d)], "So U ≥ %s − %s = %s" % [D(a.max), D(d), D(low_u)]] + hence + [final_step(ans)], ans.values),
		"distance-from-quartile": method(["The greatest value is no outlier, so it lies at most 1.5 × IQR above U.", "1.5 × %s = %s" % [D(iq), D(d)],
			"The smallest U is that far below %s: %s − %s = %s" % [D(a.max), D(a.max), D(d), D(low_u)]] + hence + [final_step(ans)], ans.values)}
	return out


func u_outliers_in_data(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Dictionary = s.a
	var d := onehalf(s.iqr)
	var v := Q.new(s.k)
	var ans := Answer.make("number", {"v": v}, {}, "number of outliers = ")
	ans.exact = true
	var near: Array = s.data.filter(func(x): return a.q3.add(s.iqr).lt(x) and not s.hi_f.lt(x))
	var far: Array = s.data.filter(func(x): return x.lt(s.lo_f) or s.hi_f.lt(x))
	var out := {"answer": ans, "lines": data_lines(s, data_name(s)) + [HALVES, RULE], "table": data_table(s), "asked": "Find how many of the values are outliers."}
	var w: Array = [wrong({"v": Q.new(s.k + near.size())}, R_LOOKS_FAR)]
	if s.k_m != s.k:
		w.append(wrong({"v": Q.new(s.k_m)}, R_FROM_MEDIAN))
	if s.k_q != s.k:
		w.append(wrong({"v": Q.new(s.k_q)}, R_THREE))
	out.wrongs = w
	out.generic = [0, 1, 2, 3, 4, 5].map(func(i): return {"v": Q.new(i)})
	var name_far := "None of the values is beyond a fence." if far.is_empty() else "Beyond a fence: %s." % ", ".join(far.map(func(x): return D(x)))
	var fences_line := "The fences are %s − 1.5 × %s = %s and %s + 1.5 × %s = %s." % [D(a.q1), D(s.iqr), D(s.lo_f), D(a.q3), D(s.iqr), D(s.hi_f)]
	var enter := "Enter the values in list L1 and the frequencies in list L2." if rep == "table" else "Enter the %d values in list L1." % s.n
	var shown := "no point on its own" if s.k == 0 else "%d point%s on %s own" % [s.k, "" if s.k == 1 else "s", "its" if s.k == 1 else "their"]
	var hand := hand_steps(s)
	out.methods = {"fences": method([hand[0], hand[1] + " " + hand[2], fences_line, name_far, final_step(ans)], ans.values),
		"gdc-modified-box": method([enter, "Draw the modified box plot: it shows %s." % shown, "Trace it to read Q1 = %s and Q3 = %s." % [D(a.q1), D(a.q3)], "Confirm with the fences: " + fences_line + " " + name_far, final_step(ans)], ans.values)}
	assert(d.sign() > 0)
	return out


# ── Keep or remove, and the effect ───────────────────────────

func u_keep_or_remove(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var l: Array = LIMITS[s.ctx]
	var a: Dictionary = s.a
	var x := D(s.x)
	var lim := D(s.limit)
	var remove := "Remove it: %s is above %s, so %s, and it must be a recording error." % [x, lim, l[2]]
	var keep := "Keep it: %s is unusually high but it is possible, so it is a genuine value." % x
	var right: String = remove if s.error else keep
	var other: String = keep if s.error else "Remove it: %s is far above the rest of the data, so it must be a recording error." % x
	var w: Array = [[other, ""], ["Remove it: every outlier must be deleted, because it fails the test.", R_DELETE], ["Keep it: an outlier is always part of the data, whatever its value.", R_KEEP_ALL]]
	var made := DerivativeMeaningViews.claim_answer(right, w)
	var ans: Dictionary = made.answer
	var why := "%s is above that limit, so it can't be a true reading." % x if s.error else "%s is within that limit, so nothing says it is a mistake." % x
	return {"answer": ans, "lines": ["A camp has %d readings of %s." % [s.n, l[0]], l[1] % lim, "Q1 = %s and Q3 = %s, and the value %s is an outlier by the 1.5 × IQR rule." % [D(a.q1), D(a.q3), x]],
		"asked": "Suggest whether %s should be removed. Justify your answer." % x, "wrongs": made.wrongs, "generic": [], "table": null,
		"methods": {"plausibility": method(["An outlier is removed only if it can't be true. The limit here is %s." % lim, why, right], ans.values)}}


static func short(s: Dictionary, v: Q) -> String:
	var t := Fmt.dec(v)
	if s.paper == 2 and (t.contains("/") or t.replace(".", "").lstrip("0").length() > 3):
		return Fmt.sf(v)
	return t


static func effect_said(s: Dictionary, m: Q, med: Q) -> Dictionary:
	return {"l": m, "r": med, "text": "new mean = %s, new median = %s" % [short(s, m), short(s, med)]}


func u_effect_of_removing(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := effect_said(s, s.mean1, s.med1)
	var ans := Answer.make("form", v, {"parts": ["new mean = ", {"slot": "l"}, ", new median = ", {"slot": "r"}]})
	if s.paper == 1:
		ans.exact = true
	else:
		ans.show = "sf"
	var total: Q = DataSummarySituation.total_of(s.rest)
	var m: int = s.rest.size()
	var moved: Q = s.mean1.sub(s.mean0)
	var w: Array = [wrong(effect_said(s, s.mean1, s.med0), R_MEDIAN_FIXED), wrong(effect_said(s, s.mean1, s.med0.add(moved)), R_SAME_MOVE),
		wrong(effect_said(s, total.div(Q.new(s.n)), s.med1), R_OLD_N)]
	var lines: Array = data_lines(s, data_name(s)) + ["The value %s is an outlier and is removed." % D(s.x)]
	return {"answer": ans, "lines": lines, "table": null, "asked": "Find the mean and the median of the %d values left%s" % [m, ", to 3 s.f." if s.paper == 2 else "."], "wrongs": w, "generic": [],
		"methods": {"effect-on-measures": method(["%d values are left, and their total is %s." % [m, D(total)], "The new mean is %s ÷ %d = %s." % [D(total), m, short(s, s.mean1)],
			"In order, the values left are %s, so the new median is %s: %s." % [", ".join(s.rest.map(func(x): return D(x))), place(1, m), D(s.med1)], final_step(ans)], ans.values)}}


func u_which_measure_moves(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var centre: bool = s.pair == "centre"
	var big: String = "mean" if centre else "range"
	var small: String = "median" if centre else "IQR"
	# Removing a high outlier lowers the mean, and a low one raises it; removing either cuts the range.
	var way: String = ("falls" if s.side == "up" else "rises") if centre else "falls"
	var back: String = ("rises" if s.side == "up" else "falls") if centre else "rises"
	var plural: String = {"falls": "fall", "rises": "rise"}[way]
	var said := func(one: String, verb: String, other: String) -> String:
		return "The %s %s by far more than the %s moves: only the %s feels how far out a value is." % [one, verb, other, one]
	var right: String = said.call(big, way, small)
	var w: Array = [["The %s and the %s %s by about the same amount: they both describe the same data." % [big, small, plural], R_SAME_MOVE],
		[said.call(small, way, big), R_SWAP_MEASURES], [said.call(big, back, small), R_DIRECTION]]
	var made := DerivativeMeaningViews.claim_answer(right, w)
	var ans: Dictionary = made.answer
	var before: Q = s.mean0 if centre else s.a.max.sub(s.a.min)
	var after: Q = s.mean1 if centre else s.b.max.sub(s.b.min)
	var was: Q = s.med0 if centre else s.iqr
	var now: Q = s.med1 if centre else s.iqr1
	var lines: Array = data_lines(s, data_name(s)) + ["The value %s is an outlier and is removed." % D(s.x)]
	return {"answer": ans, "lines": lines, "table": null, "asked": "Which statement describes the effect on the %s and the %s?" % [big, small], "wrongs": made.wrongs, "generic": [],
		"methods": {"effect-on-measures": method(["The %s goes from %s to %s." % [big, short(s, before), short(s, after)],
			"The %s goes from %s to %s." % [small, short(s, was), short(s, now)], right], ans.values)}}
