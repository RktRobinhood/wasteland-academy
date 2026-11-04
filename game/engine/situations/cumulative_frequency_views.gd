class_name CumulativeFrequencyViews
extends ExtensionViews
## The views on the `cumulative-frequency` situation: one builder per unknown of
## t4-cumulative-frequency (FAL-726). Every question is Paper 1, as every bank part is, and every
## answer is exact: a reading of the curve lands on a corner of its grid.
##
## Representations: "graph" (the curve on its grid, PlotView's `cumfreq`) and "table" (classes with
## their frequencies, their cumulative frequencies, or both).

const SQ := "SL4.2.cumfreq-quartiles#"
const SC := "SL4.2.cumfreq-count#"
const SB := "SL4.2.cumfreq-build#"
const R_MIDDLE := SQ + "0"
const R_IQR_UP := SQ + "1"
const R_PERCENT_UP := SQ + "2"
const R_AT_MOST := SC + "0"
const R_TOP := SC + "1"
const R_MIDPOINT := SB + "0"
const R_SINGLE := SB + "1"

## The stories, in the order of CumulativeFrequencySituation.DX: who is counted, what the curve
## shows, its axis, a letter, the units, and how to say more than or at most.
const CONTEXTS := [
	{"who": "scavengers", "of": "the hours worked last week by %d scavengers", "axis": "hours worked", "noun": "hours worked", "sym": "h", "unit": "hours", "more": "worked more than %s hours", "most": "worked at most %s hours"},
	{"who": "wells", "of": "the depth of %d wells", "axis": "depth (m)", "noun": "depth", "sym": "d", "unit": "m", "more": "are deeper than %s m", "most": "are at most %s m deep"},
	{"who": "crates", "of": "the mass of %d salvage crates", "axis": "mass (kg)", "noun": "mass", "sym": "m", "unit": "kg", "more": "are heavier than %s kg", "most": "are at most %s kg"},
	{"who": "drones", "of": "the flight time of %d drones", "axis": "flight time (minutes)", "noun": "flight time", "sym": "t", "unit": "minutes", "more": "flew for more than %s minutes", "most": "flew for at most %s minutes"},
	{"who": "patrols", "of": "the distance walked by %d patrols", "axis": "distance (km)", "noun": "distance", "sym": "d", "unit": "km", "more": "walked more than %s km", "most": "walked at most %s km"},
	{"who": "traders", "of": "the takings of %d traders last week", "axis": "takings (caps)", "noun": "takings", "sym": "c", "unit": "caps", "more": "took more than %s caps", "most": "took at most %s caps"},
	{"who": "bean plants", "of": "the height of %d bean plants", "axis": "height (cm)", "noun": "height", "sym": "h", "unit": "cm", "more": "are taller than %s cm", "most": "are at most %s cm tall"},
	{"who": "tanks", "of": "the water held in %d tanks", "axis": "water (litres)", "noun": "water held", "sym": "w", "unit": "litres", "more": "hold more than %s litres", "most": "hold at most %s litres", "limit": "Each tank holds at most %d litres."},
	{"who": "trucks", "of": "the load carried by %d trucks", "axis": "load (kg)", "noun": "load", "sym": "l", "unit": "kg", "more": "carry more than %s kg", "most": "carry at most %s kg", "limit": "Each truck can carry at most %s kg."},
]

const UNKNOWNS := ["median-from-graph", "quartile-from-graph", "iqr-from-graph", "percentile-from-graph", "range-from-graph",
	"median-from-table", "quartile-from-table", "iqr-from-table", "percentile-from-table",
	"count-below", "count-above", "count-between", "percent-above", "percentile-of-value", "cutoff-top", "cutoff-percent", "share-of-limit", "scale-to-population",
	"count-below-table", "count-above-table", "count-between-table", "cutoff-table",
	"cf-entry", "last-frequency", "frequency-from-cf", "frequency-from-graph", "p-q-from-graph", "plot-point", "curve-start", "pick-curve"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = CumulativeFrequencySituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func ctx(s: Dictionary) -> Dictionary:
	return CONTEXTS[s.ctx]


## "18 hours", "6 m".
static func val(s: Dictionary, v: Variant) -> String:
	return "%s %s" % [Fmt.dec(Q.of(v)), ctx(s).unit]


static func ans_of(s: Dictionary, label: String, v: Variant) -> Dictionary:
	var ans := Answer.make("number", {"v": Q.of(v)}, {}, label, " " + ctx(s).unit)
	ans.show = "dec"
	ans.exact = true
	return ans


static func count_ans(label: String, n: Variant, unit: String = "") -> Dictionary:
	var ans := Answer.make("number", {"v": Q.of(n)}, {}, label, unit)
	ans.exact = true
	return ans


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## Wrong options, positive, as numbers.
static func nums(xs: Array) -> Array:
	return xs.filter(func(x): return Q.of(x).sign() > 0).map(func(x): return {"v": Q.of(x)})


static func wr(v: Variant, ref: String) -> Array:
	return [wrong({"v": Q.of(v)}, ref)] if Q.of(v).sign() > 0 else []


## Near a reading: a square or two along the axis.
static func near(s: Dictionary, v: int) -> Array:
	return nums([v + s.dx, v - s.dx, v + 2 * s.dx, v - 2 * s.dx, v + 3 * s.dx])


static func curve_spec(s: Dictionary) -> Dictionary:
	return {"kind": "cumfreq", "x0": 0, "x1": CumulativeFrequencySituation.SQUARES * s.dx, "dx": s.dx,
		"y1": s.n, "dy": s.dy, "curve": s.curve, "x_name": ctx(s).axis, "y_name": "cumulative frequency"}


static func graph_lines(s: Dictionary) -> Array:
	var c := ctx(s)
	return ["The curve shows %s." % (c.of % s.n), "Each small square is %d %s across and %d %s up." % [s.dx, c.unit, s.dy, c.who]]


static func graph_q(s: Dictionary, asked: String, ans: Dictionary) -> Dictionary:
	return {"lines": graph_lines(s), "graph": curve_spec(s), "asked": asked, "answer": ans, "wrongs": [], "generic": []}


## "20 < h ≤ 30"
static func class_text(s: Dictionary, j: int) -> String:
	return "%d < %s ≤ %d" % [s.bs[j], ctx(s).sym, s.bs[j + 1]]


static func head(s: Dictionary) -> String:
	return "%s, %s" % [ctx(s).noun, ctx(s).sym]


## Classes with their frequencies, and cumulative frequencies if `cum` is given. A cell's text is
## its number unless hide has it: hide[j] for a frequency, hide[-1 - j] for a cumulative one.
static func class_table(s: Dictionary, cum: bool, hide: Dictionary = {}) -> Dictionary:
	var rows: Array = [[head(s), ["frequency", "cumulative"] if cum else ["frequency"]]]
	for j in s.fs.size():
		var row: Array = [hide.get(j, str(s.fs[j]))]
		if cum:
			row.append(hide.get(-1 - j, str(s.cf[j])))
		rows.append([class_text(s, j), row])
	return {"rows": rows}


## "h ≤ 10" against its cumulative frequency.
static func cum_table(s: Dictionary) -> Dictionary:
	var rows: Array = [[head(s), ["cumulative frequency"]]]
	rows.append(["%s ≤ %d" % [ctx(s).sym, s.bs[0]], ["0"]])
	for j in s.fs.size():
		rows.append(["%s ≤ %d" % [ctx(s).sym, s.bs[j + 1]], [str(s.cf[j])]])
	return {"rows": rows}


static func table_line(s: Dictionary) -> String:
	return "The table shows %s." % (ctx(s).of % s.n)


static func table_q(s: Dictionary, asked: String, ans: Dictionary, table: Dictionary = {}) -> Dictionary:
	return {"lines": [table_line(s)], "table": table if not table.is_empty() else class_table(s, true), "asked": asked, "answer": ans, "wrongs": [], "generic": []}


## The two lines of working that find a value in a class from a cumulative frequency t.
static func interp_steps(s: Dictionary, t: int) -> Array:
	var v := CumulativeFrequencySituation.interp(s, t)
	var j := 0
	while t > s.cf[j]:
		j += 1
	var before: int = s.cf[j] - s.fs[j]
	return ["Cumulative frequency %d is in the class %s, with %d before it." % [t, class_text(s, j), before],
		"%d + (%d − %d) ÷ %d × %d = %s" % [s.bs[j], t, before, s.fs[j], s.bs[j + 1] - s.bs[j], Fmt.dec(v)]]


## The two lines of working that find how many are at or below v.
static func count_steps(s: Dictionary, v: int) -> Array:
	var c := CumulativeFrequencySituation.count_at(s, v)
	var j := 0
	while v > s.bs[j + 1]:
		j += 1
	var before: int = s.cf[j] - s.fs[j]
	return ["%d is in the class %s, spread evenly, and %d are below that class." % [v, class_text(s, j), before],
		"%d + (%d − %d) ÷ %d × %d = %s" % [before, v, s.bs[j], s.bs[j + 1] - s.bs[j], s.fs[j], Fmt.num(c)]]


# ── Reading the middle of a curve ────────────────────────────

func u_median_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := ans_of(s, "median = ", s.med)
	var out := graph_q(s, "Use the curve to estimate the median %s." % ctx(s).noun, ans)
	out.wrongs = wr(10 * s.dx, R_MIDDLE)
	out.generic = nums([s.q1, s.q3]) + near(s, s.med)
	out.methods = {"across-and-down": method(["The median is at %d ÷ 2 = %d on the vertical axis." % [s.n, s.n / 2],
		"Go across to the curve, then down: %s." % val(s, s.med), final_step(ans)], ans.values)}
	return out


func u_quartile_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var low: bool = s.which == "Q1"
	var v: int = s.q1 if low else s.q3
	var ans := ans_of(s, s.which + " = ", v)
	var word := "lower" if low else "upper"
	var out := graph_q(s, "Use the curve to estimate the %s quartile of the %s." % [word, ctx(s).noun], ans)
	out.generic = nums([s.q3 if low else s.q1, s.med]) + near(s, v)
	var t: int = s.n / 4 if low else 3 * s.n / 4
	out.methods = {"across-and-down": method(["The %s quartile is at %s of %d = %d on the vertical axis." % [word, "¼" if low else "¾", s.n, t],
		"Go across to the curve, then down: %s." % val(s, v), final_step(ans)], ans.values)}
	return out


func u_iqr_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var iqr: int = s.q3 - s.q1
	var ans := ans_of(s, "IQR = ", iqr)
	var out := graph_q(s, "Use the curve to estimate the interquartile range of the %s." % ctx(s).noun, ans)
	out.wrongs = wr(s.n / 2, R_IQR_UP)
	out.generic = nums([s.q3, s.q1, s.q3 + s.q1]) + near(s, iqr)
	out.methods = {"across-and-down": method(["Q1 is at %d and Q3 at %d on the vertical axis." % [s.n / 4, 3 * s.n / 4],
		"Across and down gives Q1 = %s and Q3 = %s." % [val(s, s.q1), val(s, s.q3)], "IQR = %d − %d = %d" % [s.q3, s.q1, iqr], final_step(ans)], ans.values)}
	return out


func u_percentile_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: int = s.pct * s.n / 100
	var v := CumulativeFrequencySituation.x_at(s, t)
	var ans := ans_of(s, "percentile = ", v)
	var out := graph_q(s, "Use the curve to estimate the %s percentile of the %s." % [SamplingViews.ordinal(s.pct), ctx(s).noun], ans)
	out.wrongs = wr(CumulativeFrequencySituation.x_at(s, s.pct), R_PERCENT_UP)
	out.generic = nums([s.med]) + near(s, v)
	out.methods = {"across-and-down": method(["The %s percentile is %d%% of %d: %d on the vertical axis." % [SamplingViews.ordinal(s.pct), s.pct, s.n, t],
		"Go across to the curve, then down: %s." % val(s, v), final_step(ans)], ans.values)}
	return out


func u_range_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var first: int = s.knots[0][0]
	var last: int = s.knots[-1][0]
	var ans := ans_of(s, "range = ", last - first)
	var out := graph_q(s, "Use where the curve starts and ends to estimate the range of the %s." % ctx(s).noun, ans)
	out.generic = nums([first + last, last + s.dx, s.q3 - s.q1, last - first + s.dx, last - first + 2 * s.dx])
	if first > 0:
		out.generic.insert(0, {"v": Q.new(last)})
	out.methods = {"across-and-down": method(["The curve leaves 0 at %s and reaches %d at %s." % [val(s, first), s.n, val(s, last)],
		"%d − %d = %d" % [last, first, last - first], final_step(ans)], ans.values)}
	return out


# ── The middle from a table ──────────────────────────────────

func u_median_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: int = s.n / 2
	var v := CumulativeFrequencySituation.interp(s, t)
	var ans := ans_of(s, "median = ", v)
	var out := table_q(s, "Estimate the median %s, taking each class as evenly spread." % ctx(s).noun, ans)
	var mid: Q = Q.new(s.bs[0] + s.bs[-1], 2)
	out.wrongs = wr(mid, R_MIDDLE)
	out.generic = nums([v.add(Q.new(s.dx)), v.sub(Q.new(s.dx)), v.add(Q.new(2 * s.dx)), v.sub(Q.new(2 * s.dx)), v.add(Q.new(3 * s.dx))])
	out.methods = {"interpolate-table": method(["The median is at %d ÷ 2 = %d." % [s.n, t]] + interp_steps(s, t) + [final_step(ans)], ans.values)}
	return out


func u_quartile_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var low: bool = s.which == "Q1"
	var t: int = s.n / 4 if low else 3 * s.n / 4
	var v := CumulativeFrequencySituation.interp(s, t)
	var ans := ans_of(s, s.which + " = ", v)
	var word := "lower" if low else "upper"
	var out := table_q(s, "Estimate the %s quartile of the %s, taking each class as evenly spread." % [word, ctx(s).noun], ans)
	out.generic = nums([v.add(Q.new(s.dx)), v.sub(Q.new(s.dx)), v.add(Q.new(2 * s.dx)), v.sub(Q.new(2 * s.dx)), v.add(Q.new(3 * s.dx))])
	out.methods = {"interpolate-table": method(["The %s quartile is at %s of %d = %d." % [word, "¼" if low else "¾", s.n, t]] + interp_steps(s, t) + [final_step(ans)], ans.values)}
	return out


func u_iqr_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := CumulativeFrequencySituation.interp(s, s.n / 4)
	var b := CumulativeFrequencySituation.interp(s, 3 * s.n / 4)
	var iqr := b.sub(a)
	var ans := ans_of(s, "IQR = ", iqr)
	var out := table_q(s, "Estimate the interquartile range of the %s, taking each class as evenly spread." % ctx(s).noun, ans)
	out.wrongs = wr(s.n / 2, R_IQR_UP)
	out.generic = nums([a, b, iqr.add(Q.new(s.dx)), iqr.sub(Q.new(s.dx)), iqr.add(Q.new(2 * s.dx))])
	out.methods = {"interpolate-table": method(["Q1 is at %d and Q3 at %d." % [s.n / 4, 3 * s.n / 4],
		"In their classes they come to Q1 = %s and Q3 = %s." % [Fmt.dec(a), Fmt.dec(b)], "IQR = %s − %s = %s" % [Fmt.dec(b), Fmt.dec(a), Fmt.dec(iqr)], final_step(ans)], ans.values)}
	return out


func u_percentile_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: int = s.pct * s.n / 100
	var v := CumulativeFrequencySituation.interp(s, t)
	var ans := ans_of(s, "percentile = ", v)
	var out := table_q(s, "Estimate the %s percentile of the %s, taking each class as evenly spread." % [SamplingViews.ordinal(s.pct), ctx(s).noun], ans)
	out.wrongs = wr(CumulativeFrequencySituation.interp(s, s.pct), R_PERCENT_UP)
	out.generic = nums([v.add(Q.new(s.dx)), v.sub(Q.new(s.dx)), v.add(Q.new(2 * s.dx)), v.sub(Q.new(2 * s.dx)), v.add(Q.new(3 * s.dx))])
	out.methods = {"interpolate-table": method(["%d%% of %d is %d." % [s.pct, s.n, t]] + interp_steps(s, t) + [final_step(ans)], ans.values)}
	return out


# ── How many ─────────────────────────────────────────────────

func u_count_below(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var f := CumulativeFrequencySituation.y_at(s, s.v)
	var ans := count_ans("number = ", f)
	var out := graph_q(s, "Estimate how many %s %s." % [c.who, c.most % s.v], ans)
	out.generic = nums([s.n - f, f + s.dy, f - s.dy, f + 2 * s.dy, f - 2 * s.dy])
	out.methods = {"read-and-subtract": method(["Go up from %s to the curve." % val(s, s.v), "Go across: %d." % f, final_step(ans)], ans.values)}
	return out


func u_count_above(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var f := CumulativeFrequencySituation.y_at(s, s.v)
	var ans := count_ans("number = ", s.n - f)
	var out := graph_q(s, "Estimate how many %s %s." % [c.who, c.more % s.v], ans)
	out.wrongs = wr(f, R_AT_MOST)
	out.generic = nums([s.n - f + s.dy, s.n - f - s.dy, s.n - f + 2 * s.dy, s.n - f - 2 * s.dy])
	out.methods = {"read-and-subtract": method(["Go up from %s to the curve, then across: %d are at or below it." % [val(s, s.v), f],
		"%d − %d = %d" % [s.n, f, s.n - f], final_step(ans)], ans.values)}
	return out


func u_count_between(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var a := CumulativeFrequencySituation.y_at(s, s.v)
	var b := CumulativeFrequencySituation.y_at(s, s.v2)
	var ans := count_ans("number = ", b - a)
	var out := graph_q(s, "Estimate how many %s are between %s and %s." % [c.who, val(s, s.v), val(s, s.v2)], ans)
	out.generic = nums([b, a + b, s.n - b + a, b - a + s.dy, b - a - s.dy, b - a + 2 * s.dy])
	out.methods = {"read-and-subtract": method(["Up from %s and across: %d." % [val(s, s.v), a], "Up from %s and across: %d." % [val(s, s.v2), b],
		"%d − %d = %d" % [b, a, b - a], final_step(ans)], ans.values)}
	return out


func u_percent_above(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var f := CumulativeFrequencySituation.y_at(s, s.v)
	var pct: int = (s.n - f) * 100 / s.n
	var ans := count_ans("percentage = ", pct, "%")
	var out := graph_q(s, "Estimate the percentage of the %s that %s." % [c.who, c.more % s.v], ans)
	out.wrongs = wr(100 - pct, R_AT_MOST)
	out.generic = nums([s.n - f, pct + 5, pct - 5, pct + 10, pct - 10])
	out.methods = {"read-and-subtract": method(["Up from %s and across: %d are at or below it, so %d − %d = %d are above it." % [val(s, s.v), f, s.n, f, s.n - f],
		"%d ÷ %d × 100 = %d" % [s.n - f, s.n, pct], final_step(ans)], ans.values)}
	return out


func u_percentile_of_value(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var f := CumulativeFrequencySituation.y_at(s, s.v)
	var pct: int = f * 100 / s.n
	var ans := count_ans("percentile = ", pct)
	var out := graph_q(s, "Which percentile of the %s is %s?" % [ctx(s).noun, val(s, s.v)], ans)
	out.generic = nums([f, 100 - pct, pct + 5, pct - 5, pct + 10])
	out.methods = {"read-and-subtract": method(["Up from %s and across: %d are at or below it." % [val(s, s.v), f],
		"%d ÷ %d × 100 = %d" % [f, s.n, pct], final_step(ans)], ans.values)}
	return out


func u_cutoff_top(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var v := CumulativeFrequencySituation.x_at(s, s.n - s.top)
	var ans := ans_of(s, "%s = " % c.noun, v)
	var out := graph_q(s, "Estimate the lowest %s of those set aside." % c.noun, ans)
	out.lines = out.lines + ["The %d %s with the highest %s are set aside." % [s.top, c.who, c.noun]]
	out.wrongs = wr(CumulativeFrequencySituation.x_at(s, s.top), R_TOP)
	out.generic = nums([s.med]) + near(s, v)
	out.methods = {"read-and-subtract": method(["The top %d leave %d − %d = %d below them." % [s.top, s.n, s.top, s.n - s.top],
		"Go across from %d to the curve, then down: %s." % [s.n - s.top, val(s, v)], final_step(ans)], ans.values)}
	return out


func u_cutoff_percent(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var top: int = s.pct * s.n / 100
	var v := CumulativeFrequencySituation.x_at(s, s.n - top)
	var ans := ans_of(s, "k = ", v)
	var out := graph_q(s, "%d%% of the %s %s. Find k." % [s.pct, c.who, c.more % "k"], ans)
	out.wrongs = wr(CumulativeFrequencySituation.x_at(s, top), R_TOP)
	out.generic = nums([s.med]) + near(s, v)
	out.methods = {"read-and-subtract": method(["%d%% of %d is %d, which leaves %d − %d = %d below k." % [s.pct, s.n, top, s.n, top, s.n - top],
		"Go across from %d to the curve, then down: %s." % [s.n - top, val(s, v)], final_step(ans)], ans.values)}
	return out


func u_share_of_limit(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var f := CumulativeFrequencySituation.y_at(s, s.v)
	var limit: int = CumulativeFrequencySituation.SQUARES * s.dx
	var ans := count_ans("number = ", s.n - f)
	var out := graph_q(s, "Estimate how many %s are above %d%% of that limit." % [c.who, s.pct], ans)
	out.lines = out.lines + [c.limit % limit]
	out.wrongs = wr(f, R_AT_MOST)
	out.generic = nums([s.n - f + s.dy, s.n - f - s.dy, s.n - f + 2 * s.dy, s.n - f - 2 * s.dy])
	out.methods = {"read-and-subtract": method(["%d%% of %d is %d." % [s.pct, limit, s.v], "Up from %s and across: %d are at or below it." % [val(s, s.v), f],
		"%d − %d = %d" % [s.n, f, s.n - f], final_step(ans)], ans.values)}
	return out


func u_scale_to_population(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var f := CumulativeFrequencySituation.y_at(s, s.v)
	var whole: int = s.n * s.r
	var v: int = (s.n - f) * s.r
	var ans := count_ans("number = ", v)
	var out := graph_q(s, "Estimate how many of all %d %s %s." % [whole, c.who, c.more % s.v], ans)
	out.lines = out.lines + ["They were chosen at random from %d %s." % [whole, c.who]]
	out.wrongs = wr(f * s.r, R_AT_MOST)
	out.generic = nums([s.n - f, (s.n - f + s.dy) * s.r, (s.n - f - s.dy) * s.r, v + s.r])
	out.methods = {"read-and-subtract": method(["Up from %s and across: %d of the %d are at or below it, so %d are above it." % [val(s, s.v), f, s.n, s.n - f],
		"The whole group is %d ÷ %d = %d times as large." % [whole, s.n, s.r], "%d × %d = %d" % [s.n - f, s.r, v], final_step(ans)], ans.values)}
	return out


# ── How many, from a table ───────────────────────────────────

func u_count_below_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var f := CumulativeFrequencySituation.count_at(s, s.v)
	var ans := count_ans("number = ", f)
	var out := table_q(s, "Estimate how many %s %s, taking each class as evenly spread." % [c.who, c.most % s.v], ans)
	out.generic = nums([Q.new(s.n).sub(f), f.add(Q.new(1)), f.add(Q.new(2)), f.sub(Q.new(1)), f.sub(Q.new(2))])
	out.methods = {"interpolate-table": method(count_steps(s, s.v) + [final_step(ans)], ans.values)}
	return out


func u_count_above_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var f := CumulativeFrequencySituation.count_at(s, s.v)
	var v := Q.new(s.n).sub(f)
	var ans := count_ans("number = ", v)
	var out := table_q(s, "Estimate how many %s %s, taking each class as evenly spread." % [c.who, c.more % s.v], ans)
	out.wrongs = wr(f, R_AT_MOST)
	out.generic = nums([v.add(Q.new(1)), v.add(Q.new(2)), v.sub(Q.new(1)), v.sub(Q.new(2))])
	out.methods = {"interpolate-table": method(count_steps(s, s.v) + ["%d − %s = %s" % [s.n, Fmt.num(f), Fmt.num(v)], final_step(ans)], ans.values)}
	return out


func u_count_between_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var a := CumulativeFrequencySituation.count_at(s, s.v)
	var b := CumulativeFrequencySituation.count_at(s, s.v2)
	var v := b.sub(a)
	var ans := count_ans("number = ", v)
	var out := table_q(s, "Estimate how many %s are between %s and %s, taking each class as evenly spread." % [c.who, val(s, s.v), val(s, s.v2)], ans)
	out.generic = nums([b, a.add(b), v.add(Q.new(1)), v.add(Q.new(2)), v.sub(Q.new(1)), v.sub(Q.new(2))])
	out.methods = {"interpolate-table": method(["At or below %s: %s." % [val(s, s.v), Fmt.num(a)], "At or below %s: %s." % [val(s, s.v2), Fmt.num(b)],
		"%s − %s = %s" % [Fmt.num(b), Fmt.num(a), Fmt.num(v)], final_step(ans)], ans.values)}
	return out


func u_cutoff_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var t: int = s.n - s.top
	var v := CumulativeFrequencySituation.interp(s, t)
	var ans := ans_of(s, "%s = " % c.noun, v)
	var out := table_q(s, "The %d %s with the highest %s are set aside. Estimate the lowest %s of those set aside." % [s.top, c.who, c.noun, c.noun], ans)
	out.wrongs = wr(CumulativeFrequencySituation.interp(s, s.top), R_TOP)
	out.generic = nums([v.add(Q.new(s.dx)), v.sub(Q.new(s.dx)), v.add(Q.new(2 * s.dx)), v.sub(Q.new(2 * s.dx)), v.add(Q.new(3 * s.dx))])
	out.methods = {"interpolate-table": method(["The top %d leave %d − %d = %d below them." % [s.top, s.n, s.top, t]] + interp_steps(s, t) + [final_step(ans)], ans.values)}
	return out


# ── Building the table ───────────────────────────────────────

func u_cf_entry(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var j: int = s.j
	var hide := {-1 - j: "?"}
	for i in range(j + 1, s.fs.size()):
		hide[-1 - i] = "–"
	var ans := count_ans("? = ", s.cf[j])
	var out := table_q(s, "Find the cumulative frequency marked ?.", ans, class_table(s, true, hide))
	out.wrongs = wr(s.fs[j], R_SINGLE)
	out.generic = nums([s.cf[j - 1], s.cf[j] + 1, s.cf[j] + 2, s.cf[j] - 1, s.cf[j] + s.fs[j]])
	out.methods = {"running-total": method(["Add this class's frequency to the total so far.", "%d + %d = %d" % [s.cf[j - 1], s.fs[j], s.cf[j]], final_step(ans)], ans.values)}
	return out


func u_last_frequency(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var j: int = s.j
	var hide := {j: "p"}
	for i in s.fs.size() - 1:
		hide[-1 - i] = "–"
	var ans := count_ans("p = ", s.fs[j])
	var known: int = s.n - s.fs[j]
	var out := table_q(s, "Find p.", ans, class_table(s, true, hide))
	out.generic = nums([known, s.n, s.fs[j] + 1, s.fs[j] + 2, s.fs[j] - 1, s.fs[j] + 3])
	out.methods = {"running-total": method(["The last cumulative frequency is the total, %d." % s.n, "The other frequencies add to %d." % known,
		"%d − %d = %d" % [s.n, known, s.fs[j]], final_step(ans)], ans.values)}
	return out


func u_frequency_from_cf(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var j: int = s.j
	var ans := count_ans("number = ", s.fs[j])
	var out := table_q(s, "Find the number of %s in the class %s." % [ctx(s).who, class_text(s, j)], ans, cum_table(s))
	out.wrongs = wr(s.cf[j], R_SINGLE)
	out.generic = nums([s.cf[j - 1], s.cf[j] + s.cf[j - 1], s.fs[j] + 1, s.fs[j] + 2, s.fs[j] - 1])
	out.methods = {"difference-back": method(["Take the cumulative frequency before the class from the one at its end.", "%d − %d = %d" % [s.cf[j], s.cf[j - 1], s.fs[j]], final_step(ans)], ans.values)}
	return out


func u_frequency_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var j: int = s.j
	var ans := count_ans("number = ", s.fs[j])
	var out := graph_q(s, "Find the number of %s in the class %s." % [ctx(s).who, class_text(s, j)], ans)
	out.wrongs = wr(s.cf[j], R_SINGLE)
	out.generic = nums([s.cf[j - 1], s.cf[j] + s.cf[j - 1], s.fs[j] + s.dy, s.fs[j] - s.dy, s.fs[j] + 2 * s.dy])
	out.methods = {"difference-back": method(["Up from %d and across: %d." % [s.bs[j], s.cf[j - 1]], "Up from %d and across: %d." % [s.bs[j + 1], s.cf[j]],
		"%d − %d = %d" % [s.cf[j], s.cf[j - 1], s.fs[j]], final_step(ans)], ans.values)}
	return out


func u_p_q_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.fs[s.j]
	var q: int = s.fs[s.j2]
	var ans := Answer.make("pq", {"p": Q.new(p), "q": Q.new(q)})
	ans.exact = true
	var out := graph_q(s, "Use the curve to find p and q.", ans)
	out.lines = out.lines + ["The table shows the same %s." % ctx(s).who]
	out.table = class_table(s, false, {s.j: "p", s.j2: "q"})
	out.wrongs = [wrong({"p": Q.new(s.cf[s.j]), "q": Q.new(s.cf[s.j2])}, R_SINGLE), wrong({"p": Q.new(q), "q": Q.new(p)})]
	out.generic = [{"p": Q.new(p + s.dy), "q": Q.new(q)}, {"p": Q.new(p), "q": Q.new(q + s.dy)}]
	var read := func(j: int) -> String:
		return "%d − %d = %d" % [s.cf[j], s.cf[j] - s.fs[j], s.fs[j]]
	out.methods = {"difference-back": method(["Read the curve at both ends of each class.", "p = " + read.call(s.j), "q = " + read.call(s.j2), Answer.text(ans)], ans.values)}
	return out


# ── Plotting ─────────────────────────────────────────────────

func u_plot_point(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var j: int = s.j
	var hi: int = s.bs[j + 1]
	var lo: int = s.bs[j]
	var pt := func(x: Variant, y: int) -> String: return "(%s, %d)" % [Fmt.dec(Q.of(x)), y]
	var right: String = pt.call(hi, s.cf[j])
	var built := DerivativeMeaningViews.claim_answer(right, [[pt.call(Q.new(lo + hi, 2), s.cf[j]), R_MIDPOINT], [pt.call(hi, s.fs[j]), R_SINGLE], [pt.call(lo, s.cf[j]), ""]])
	return {"lines": [table_line(s)], "table": class_table(s, true), "asked": "Which point is plotted on the curve for the class %s?" % class_text(s, j), "answer": built.answer, "wrongs": built.wrongs,
		"methods": {"plot-upper-bounds": method(["%d is the total at the upper boundary of the class, %d." % [s.cf[j], hi], "So it is plotted there, not at the middle of the class.", right], built.answer.values)}}


func u_curve_start(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var first: int = s.bs[0]
	var pt := func(x: Variant, y: int) -> String: return "(%s, %d)" % [Fmt.dec(Q.of(x)), y]
	var right: String = pt.call(first, 0)
	var built := DerivativeMeaningViews.claim_answer(right, [[pt.call(0, 0), ""], [pt.call(s.bs[1], s.fs[0]), ""], [pt.call(Q.new(first + s.bs[1], 2), 0), ""]])
	return {"lines": [table_line(s)], "table": class_table(s, true), "asked": "At which point does the cumulative frequency curve start?", "answer": built.answer, "wrongs": built.wrongs,
		"methods": {"plot-upper-bounds": method(["Nothing is below the first class, whose lower boundary is %d." % first, "So the curve starts on that boundary at 0.", right], built.answer.values)}}


## A card for the points, joined as PlotView's curve is, on the window of a card.
static func card(s: Dictionary, curve: Array, win: Array) -> Dictionary:
	var g := GdcKit.card([curve], [], win)
	g.x_name = ctx(s).sym
	g.y_name = "cf"
	return g


func u_pick_curve(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	# Room under the axis for its numbers.
	var win: Array = [0, s.bs[-1] + (s.bs[1] - s.bs[0]) / 2, -s.n / 6, s.n + s.n / 10]
	var right: Array = [[s.bs[0], 0]]
	var mids: Array = [[s.bs[0], 0]]
	var bare: Array = [[s.bs[0], 0]]
	var lows: Array = []
	for j in s.fs.size():
		right.append([s.bs[j + 1], s.cf[j]])
		mids.append([Q.new(s.bs[j] + s.bs[j + 1], 2).to_float(), s.cf[j]])
		bare.append([s.bs[j + 1], s.fs[j]])
		lows.append([s.bs[j], s.cf[j]])
	var pk := GdcKit.pick(card(s, CumulativeFrequencySituation.smooth(right), win), [
		{"graph": card(s, CumulativeFrequencySituation.smooth(mids), win), "mistake": "midpoints", "ref": R_MIDPOINT, "why": "its points are at the middles of the classes, not at their upper boundaries"},
		{"graph": card(s, bare.map(func(p): return [float(p[0]), float(p[1])]), win), "mistake": "frequencies", "ref": R_SINGLE, "why": "its points are the frequencies, not the running totals"},
		{"graph": card(s, CumulativeFrequencySituation.smooth(lows), win), "mistake": "lower", "ref": "", "why": "its points are at the lower boundaries"}], rng)
	var ans: Dictionary = pk.answer
	return {"lines": [table_line(s), "On each graph, cf is the cumulative frequency."], "table": class_table(s, false), "asked": "Which graph is the cumulative frequency curve?", "answer": ans, "graphs": pk.graphs,
		"methods": {"plot-upper-bounds": method(["Keep a running total: %s." % ", ".join(s.cf.map(func(v): return str(v))), "Plot each total at the upper boundary of its class, starting from (%d, 0)." % s.bs[0], Answer.text(ans)], ans.values)}}
