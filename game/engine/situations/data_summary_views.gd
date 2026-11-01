class_name DataSummaryViews
extends ExtensionViews
## The views on the `data-summary` situation: one builder per unknown of
## t4-summary-statistics (FAL-695). The data come as a list ("terms": 7, 3, 12, ...), as a
## frequency table ("table") or, for the totals and the outlier stories, as words. A
## Paper 1 question has small whole numbers and exact answers; a Paper 2 mean is answered
## to 3 s.f. (show "sf", with the rounding trap) and its GDC working reads x̄ off 1-Var Stats.
##
## `given` holds what the student is shown, for the SymPy checker, which reads the data
## back from the lines and the table anyway.

const SKILL := "SL4.3."
const R_UNORDERED_MEDIAN := SKILL + "mean-median-mode#0"
const R_POSITION := SKILL + "mean-median-mode#1"
const R_COUNT_AS_MODE := SKILL + "mean-median-mode#2"
const R_AVERAGE_MEANS := SKILL + "mean-totals#0"
const R_NO_P_DENOMINATOR := SKILL + "mean-totals#1"
const R_IQR_SUM := SKILL + "quartiles-discrete#0"
const R_UNORDERED_QUARTILES := SKILL + "quartiles-discrete#1"
const R_MEAN_BEST := SKILL + "choose-measure#0"
const R_MODE_BEST := SKILL + "choose-measure#1"

## The stories for a missing value: what the numbers are, and one of them.
const CONTEXTS := [
	{"what": "quiz scores", "one": "score"},
	{"what": "daily temperatures in °C", "one": "temperature"},
	{"what": "journey times in minutes", "one": "time"},
	{"what": "parcel masses in kg", "one": "mass"},
	{"what": "plant heights in cm", "one": "height"},
	{"what": "ages in years", "one": "age"},
]

## The two groups of a combined mean, and what the whole lot is called.
const GROUPS := [
	{"a": "boys", "b": "girls", "what": "mark", "all": "students"},
	{"a": "morning shifts", "b": "evening shifts", "what": "number of customers", "all": "shifts"},
	{"a": "small packets", "b": "large packets", "what": "number of seeds", "all": "packets"},
	{"a": "first-year pupils", "b": "second-year pupils", "what": "homework time in minutes", "all": "pupils"},
	{"a": "cyclists", "b": "walkers", "what": "distance in km", "all": "people"},
]

## The outlier stories: the line above the eight values.
const SPREADS := [
	"The masses, in kg, of 8 crates of tinned food:",
	"The times, in minutes, 8 couriers took to cross the wasteland:",
	"The daily water use, in litres, of 8 households:",
	"The distances, in km, 8 scavengers travelled in a day:",
	"The lengths, in cm, of 8 pipes:",
	"The rainfall, in mm, a station recorded on 8 days:",
]

const CENTRES := ["the mean", "the median", "the mode", "the midrange"]
const SPREAD_MEASURES := ["the range", "the interquartile range", "the standard deviation", "the variance"]

const UNKNOWNS := ["mean-of-data", "median-of-data", "mode-of-data", "range-of-data", "quartiles-of-data", "iqr-of-data",
		"missing-value-from-mean", "missing-frequency-from-mean", "combined-mean", "choose-average", "choose-spread"]
## The unknowns a student can do by hand, on Paper 1 only.
const BY_HAND := ["missing-value-from-mean", "missing-frequency-from-mean", "combined-mean", "choose-average", "choose-spread"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## The GDC's 1-Var Stats is Paper 2 only; the by-hand unknowns are Paper 1 only.
func papers(unknown: String, _rep: String, angle: String) -> Array:
	if not has(unknown):
		return []
	if angle == "gdc-1var":
		return [2]
	if unknown in BY_HAND:
		return [1]
	return [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = DataSummarySituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## A value to 6 significant figures with no trailing zeros: a GDC's screen.
static func W(v: Variant) -> String:
	var t := Fmt.sf(v, 6)
	if t.contains("."):
		t = t.rstrip("0").rstrip(".")
	return t


## 7, 3, 12
static func L(xs: Array) -> String:
	return ", ".join(xs.map(func(x): return D(x)))


## 7 + 3 + 12
static func plus(xs: Array) -> String:
	return " + ".join(xs.map(func(x): return D(x)))


## 7, 3 and 12
static func and_list(xs: Array) -> String:
	if xs.size() == 1:
		return D(xs[0])
	var head: Array = xs.slice(0, xs.size() - 1)
	return L(head) + " and " + D(xs[xs.size() - 1])


static func ordinal(i: int) -> String:
	var tens := i % 100
	if tens >= 11 and tens <= 13:
		return "%dth" % i
	match i % 10:
		1:
			return "%dst" % i
		2:
			return "%dnd" % i
		3:
			return "%drd" % i
	return "%dth" % i


## The data as the rep shows them: the list as the line, or the table's own rows.
static func data_view(s: Dictionary) -> Dictionary:
	if s.rep == "table":
		return {"lines": ["The table shows the data."], "table": {"rows": [["x", s.xs.map(func(x): return D(x))],
				["Frequency", s.fs.map(func(f): return str(f))]]}}
	return {"lines": [L(s.xs)], "table": null}


## A number answer: exact, or to 3 s.f. where it needs rounding.
static func num_ans(label: String, v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	if Answer.needs_rounding(v):
		ans.show = "sf"
	else:
		ans.show = "dec"
		ans.exact = true
	return ans


static func vs(xs: Array) -> Array:
	return xs.map(func(x): return {"v": tidy(x)})


## A wrong option for an exact answer: as it is if it ends within two decimal places, else to
## one place, so no option reads as a fraction.
static func tidy(x: Q) -> Q:
	if Q.new(100).mul(x).is_int():
		return x
	return Q.new(roundi(x.to_float() * 10.0), 10)


## "23.4 + 0.6" or "23.4 − 0.6": a plus a signed difference.
static func plus_signed(a: Q, d: Q) -> String:
	return "%s + %s" % [D(a), D(d)] if d.sign() >= 0 else "%s − %s" % [D(a), D(d.abs_q())]


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## The value in position pos (1 is the least) of the ordered data.
static func at(s: Dictionary, pos: int) -> Q:
	return s.data[pos - 1]


## "3, 8, 12, 18": the running totals of a table's frequencies.
static func running(s: Dictionary) -> String:
	var t := 0
	var out: PackedStringArray = []
	for f in s.fs:
		t += int(f)
		out.append(str(t))
	return ", ".join(out)


## The median's positions in count values starting at position `start`: one, or two.
static func mid_positions(start: int, count: int) -> Array:
	var h := DataSummarySituation.half(count)
	if count % 2 == 1:
		return [start + h]
	return [start + h - 1, start + h]


## "the 5th value" or "halfway between the 5th and 6th values", for the positions.
static func where_text(ps: Array) -> String:
	if ps.size() == 1:
		return "the %s value" % ordinal(ps[0])
	return "halfway between the %s and %s values" % [ordinal(ps[0]), ordinal(ps[1])]


# ── Mean, median, mode and range ─────────────────────────────

func u_mean_of_data(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var mean: Q = s.mean
	var ans := num_ans("mean = ", mean)
	var out := data_view(s)
	out.asked = "Find the mean of the data." if ans.show == "dec" else "Find the mean of the data, to 3 s.f."
	out.answer = ans
	var sorted: Array = s.data
	out.wrongs = []
	out.generic = vs([DataSummarySituation.median_of(sorted), DataSummarySituation.total_of(sorted).div(Q.new(s.n - 1)),
		DataSummarySituation.total_of(sorted).div(Q.new(s.n + 1)), sorted[0].add(sorted[s.n - 1]).div(Q.new(2)), mean.add(Q.new(1)),
		mean.sub(Q.new(1)), mean.mul(Q.new(2))])
	var total := DataSummarySituation.total_of(sorted)
	var shown_mean: String = D(mean) if ans.show == "dec" else W(mean)
	var steps: Array
	if rep == "table":
		var prods: PackedStringArray = []
		for i in s.xs.size():
			prods.append("%s × %d" % [D(s.xs[i]), s.fs[i]])
		steps = ["Multiply each value by its frequency and add: Σfx = %s = %s" % [" + ".join(prods), D(total)],
			"Add the frequencies: Σf = %s = %d" % [" + ".join(s.fs.map(func(f): return str(f))), s.n],
			"mean = Σfx ÷ Σf = %s ÷ %d = %s" % [D(total), s.n, shown_mean], final_step(ans)]
	else:
		steps = ["Add the values: %s = %s" % [plus(s.xs), D(total)], "Divide by the number of values, n = %d: %s ÷ %d = %s" % [s.n, D(total), s.n, shown_mean],
			final_step(ans)]
	var gdc: Array
	if rep == "table":
		gdc = ["Enter the values in list L1 and the frequencies in list L2.", "Run 1-Var Stats with L2 as the frequency list: x̄ = %s" % shown_mean, final_step(ans)]
	else:
		gdc = ["Enter the %d values in list L1." % s.n, "Run 1-Var Stats: x̄ = %s" % shown_mean, final_step(ans)]
	out.methods = {"sum-over-n": method(steps, ans.values), "gdc-1var": method(gdc, ans.values)}
	return out


func u_median_of_data(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var median := DataSummarySituation.median_of(s.data)
	var ans := num_ans("median = ", median)
	var out := data_view(s)
	out.asked = "Find the median of the data."
	out.answer = ans
	var n: int = s.n
	out.wrongs = []
	if rep != "table":
		var shown_mid := DataSummarySituation.median_of(s.xs)
		out.wrongs.append(wrong({"v": shown_mid}, R_UNORDERED_MEDIAN))
	out.wrongs.append(wrong({"v": Q.new(n + 1, 2)}, R_POSITION))
	out.generic = vs([DataSummarySituation.mean_of(s.data), median.add(Q.new(1)), median.sub(Q.new(1)), s.data[0].add(s.data[n - 1]).div(Q.new(2)),
		Q.new(n, 2)])
	var ps := mid_positions(1, n)
	var pos_text: String
	if ps.size() == 1:
		pos_text = "n = %d, so the median is the value in position (%d + 1) ÷ 2 = %d." % [n, n, ps[0]]
	else:
		pos_text = "n = %d, so the median is halfway between the values in positions %d and %d." % [n, ps[0], ps[1]]
	var pick: String
	if ps.size() == 1:
		pick = "The value in position %d is %s." % [ps[0], D(at(s, ps[0]))]
	else:
		pick = "Positions %d and %d hold %s and %s: (%s + %s) ÷ 2 = %s." % [ps[0], ps[1], D(at(s, ps[0])), D(at(s, ps[1])), D(at(s, ps[0])), D(at(s, ps[1])), D(median)]
	var steps: Array
	if rep == "table":
		steps = ["The frequencies add to n = %d, so the median is %s." % [n, where_text(ps)],
			"The running totals of the frequencies are %s." % running(s), pick, final_step(ans)]
	else:
		steps = ["Put the values in order: %s" % L(s.data), pos_text, pick, final_step(ans)]
	var gdc: Array = ["Enter the values (and the frequencies in L2) and run 1-Var Stats.", "Read off Med = %s" % D(median), final_step(ans)]
	out.methods = {"ordered-position": method(steps, ans.values), "gdc-1var": method(gdc, ans.values)}
	return out


func u_mode_of_data(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := num_ans("mode = ", s.mode)
	var out := data_view(s)
	out.asked = "Write down the mode of the data."
	out.answer = ans
	out.wrongs = [wrong({"v": Q.new(s.mode_count)}, R_COUNT_AS_MODE)]
	var sorted: Array = s.data
	out.generic = vs([DataSummarySituation.median_of(sorted), sorted[s.n - 1], sorted[0], DataSummarySituation.mean_of(sorted)])
	var steps: Array
	if rep == "table":
		steps = ["The mode is the value with the greatest frequency.", "The greatest frequency is %d, in the column x = %s." % [s.mode_count, D(s.mode)],
			final_step(ans)]
	else:
		var seen: Array = []
		var counts: PackedStringArray = []
		for x in sorted:
			if seen.any(func(y): return y.eq(x)):
				continue
			seen.append(x)
			counts.append("%s (%d)" % [D(x), sorted.filter(func(y): return y.eq(x)).size()])
		steps = ["Count how often each value occurs: %s" % ", ".join(counts),
			"%s occurs most often, %d times." % [D(s.mode), s.mode_count], final_step(ans)]
	out.methods = {"any": method(steps, ans.values)}
	return out


func u_range_of_data(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var sorted: Array = s.data
	var hi: Q = sorted[s.n - 1]
	var lo: Q = sorted[0]
	var r := hi.sub(lo)
	var ans := num_ans("range = ", r)
	var out := data_view(s)
	out.asked = "Find the range of the data."
	out.answer = ans
	out.wrongs = []
	out.generic = vs([hi, lo, hi.add(lo), r.add(Q.new(1)), r.sub(Q.new(1)), DataSummarySituation.median_of(sorted)])
	var first := "The greatest value is %s and the least is %s." % [D(hi), D(lo)] if rep != "table" else \
			"The values run from %s to %s." % [D(lo), D(hi)]
	out.methods = {"any": method([first, "range = greatest − least = %s − %s = %s" % [D(hi), D(lo), D(r)], final_step(ans)], ans.values)}
	return out


# ── Quartiles and the interquartile range ────────────────────

## The steps that lead to Q1 and Q3 (not the last one): the data in order and the halves.
func _quartile_steps(rep: String, s: Dictionary) -> Array:
	var n: int = s.n
	var h := DataSummarySituation.half(n)
	var odd := n % 2 == 1
	var q1: Q = s.q1
	var q3: Q = s.q3
	var lo_pos := mid_positions(1, h)
	var hi_pos := mid_positions(h + (1 if odd else 0) + 1, h)
	if rep == "table":
		var halves := "The frequencies add to n = %d. The lower half is the first %d values and the upper half is the last %d" % [n, h, h]
		halves += " (the middle value, position %d, is left out)." % (h + 1) if odd else "."
		return [halves, "The running totals of the frequencies are %s." % running(s),
			"Q₁ is %s: %s. Q₃ is %s: %s." % [where_text(lo_pos), _pick_text(s, lo_pos, q1), where_text(hi_pos), _pick_text(s, hi_pos, q3)]]
	var lower: Array = s.data.slice(0, h)
	var upper: Array = s.data.slice(h + (1 if odd else 0), n)
	var split: String
	if odd:
		split = "n = %d, so the median is the %s value: leave it out. The lower half is %s and the upper half is %s." % [n, ordinal(h + 1), L(lower), L(upper)]
	else:
		split = "n = %d: the lower half is %s and the upper half is %s." % [n, L(lower), L(upper)]
	return ["Put the values in order: %s" % L(s.data), split,
		"Q₁ is the median of the lower half: %s. Q₃ is the median of the upper half: %s." % [D(q1), D(q3)]]


## "4" or "(4 + 5) ÷ 2 = 4.5": the value at one or two positions.
static func _pick_text(s: Dictionary, ps: Array, result: Q) -> String:
	if ps.size() == 1:
		return D(result)
	return "(%s + %s) ÷ 2 = %s" % [D(at(s, ps[0])), D(at(s, ps[1])), D(result)]


func u_quartiles_of_data(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var q1: Q = s.q1
	var q3: Q = s.q3
	var ans := Answer.make("named", {"v0": q1, "v1": q3}, {"names": ["Q₁", "Q₃"]})
	ans.show = "dec"
	ans.exact = true
	var out := data_view(s)
	out.asked = "Find the lower quartile and the upper quartile of the data."
	out.answer = ans
	out.wrongs = []
	if rep != "table":
		var n: int = s.n
		var h := DataSummarySituation.half(n)
		var odd := 1 if n % 2 == 1 else 0
		var uq1 := DataSummarySituation.median_of(s.xs.slice(0, h))
		var uq3 := DataSummarySituation.median_of(s.xs.slice(h + odd, n))
		out.wrongs.append(wrong({"v0": uq1, "v1": uq3}, R_UNORDERED_QUARTILES))
	var med := DataSummarySituation.median_of(s.data)
	out.generic = [{"v0": q1, "v1": med}, {"v0": med, "v1": q3}, {"v0": q1.sub(Q.new(1)), "v1": q3.add(Q.new(1))},
		{"v0": s.data[0], "v1": s.data[s.n - 1]}]
	var halves := _quartile_steps(rep, s)
	var gdc: Array = ["Enter the values (and the frequencies in L2) and run 1-Var Stats.", "Read off Q1 = %s and Q3 = %s" % [D(q1), D(q3)], final_step(ans)]
	out.methods = {"median-of-halves": method(halves + [final_step(ans)], ans.values), "gdc-1var": method(gdc, ans.values)}
	return out


func u_iqr_of_data(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var q1: Q = s.q1
	var q3: Q = s.q3
	var iqr := q3.sub(q1)
	var ans := num_ans("IQR = ", iqr)
	var out := data_view(s)
	out.asked = "Find the interquartile range of the data."
	out.answer = ans
	out.wrongs = [wrong({"v": q1.add(q3)}, R_IQR_SUM)]
	var rng_all: Q = s.data[s.n - 1].sub(s.data[0])
	out.generic = vs([rng_all, q3, q1, iqr.add(Q.new(1)), iqr.sub(Q.new(1)), iqr.mul(Q.new(2))])
	var calc := "IQR = Q₃ − Q₁ = %s − %s = %s" % [D(q3), D(q1), D(iqr)]
	var gdc: Array = ["Enter the values (and the frequencies in L2) and run 1-Var Stats.", "Q1 = %s and Q3 = %s, so IQR = Q3 − Q1 = %s" % [D(q1), D(q3), D(iqr)],
		final_step(ans)]
	out.methods = {"median-of-halves": method(_quartile_steps(rep, s) + [calc, final_step(ans)], ans.values), "gdc-1var": method(gdc, ans.values)}
	return out


# ── A missing value, a missing frequency, a combined mean ────

## The list as the student sees it, with k where the missing value goes.
static func with_k(s: Dictionary) -> Array:
	var out: Array = s.xs.map(func(x): return D(x))
	out[s.at] = "k"
	return out


func u_missing_value_from_mean(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: Q = s.k
	var n: int = s.n
	var mean: Q = s.mean
	var c: Dictionary = CONTEXTS[s.ctx]
	var known: Array = s.xs.duplicate()
	known.remove_at(s.at)
	var label := "k = " if rep == "terms" else "missing %s = " % c.one
	var ans := Answer.make("number", {"v": k}, {}, label)
	ans.show = "dec"
	ans.exact = true
	var out: Dictionary
	if rep == "terms":
		out = {"lines": [", ".join(with_k(s)), "The mean of these numbers is %s." % D(mean)], "asked": "Find k.", "table": null}
	else:
		out = {"lines": ["The mean of %d %s is %s." % [n, c.what, D(mean)], "%d of them are %s." % [n - 1, and_list(known)]],
			"asked": "Find the missing %s." % c.one, "table": null}
	out.answer = ans
	var total := mean.mul(Q.new(n))
	var known_sum := DataSummarySituation.total_of(known)
	out.wrongs = []
	# A value one off, the mean of the values already there, the mean itself, and dividing by one too few.
	out.generic = vs([k.add(Q.new(1)), k.sub(Q.new(1)), known_sum.div(Q.new(n - 1)), mean, mean.mul(Q.new(n - 1)).sub(known_sum)])
	var steps_total := ["The total of all %d values is %s × %d = %s." % [n, D(mean), n, D(total)],
		"The other %d values add to %s = %s." % [n - 1, plus(known), D(known_sum)],
		"The missing value is the difference: %s − %s = %s." % [D(total), D(known_sum), D(k)], final_step(ans)]
	var devs: PackedStringArray = []
	var dev_sum := Q.new(0)
	for x in known:
		var d: Q = x.sub(mean)
		dev_sum = dev_sum.add(d)
		devs.append("%s − %s = %s" % [D(x), D(mean), D(d)])
	var steps_dev := ["The deviations from the mean add to zero. The known ones are %s." % ", ".join(devs),
		"They add to %s, so the missing value's deviation is %s." % [D(dev_sum), D(dev_sum.neg())],
		"The missing value is %s = %s." % [plus_signed(mean, dev_sum.neg()), D(k)], final_step(ans)]
	out.methods = {"total-from-mean": method(steps_total, ans.values), "deviations-sum-zero": method(steps_dev, ans.values)}
	return out


func u_missing_frequency_from_mean(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: Q = s.p
	var mean: Q = s.mean
	var xp: Q = s.xs[s.at]
	var ans := Answer.make("number", {"v": p}, {}, "p = ")
	ans.show = "dec"
	ans.exact = true
	var fcells: Array = s.fs.map(func(f): return str(f))
	fcells[s.at] = "p"
	var f_known := 0
	var fx_known := Q.new(0)
	var dev_known := Q.new(0)
	for i in s.xs.size():
		if i == s.at:
			continue
		f_known += int(s.fs[i])
		fx_known = fx_known.add(s.xs[i].mul(Q.new(s.fs[i])))
		dev_known = dev_known.add(s.xs[i].sub(mean).mul(Q.new(s.fs[i])))
	var out := {"lines": ["The mean of the data is %s." % D(mean)], "asked": "Find p.", "answer": ans, "wrongs": [],
		"table": {"rows": [["x", s.xs.map(func(x): return D(x))], ["Frequency", fcells]]}}
	# The slip: the missing frequency left out of Σf, so p x = M Σf − Σfx.
	var slip: Q = mean.mul(Q.new(f_known)).sub(fx_known).div(xp)
	if slip.sign() > 0 and Q.new(100).mul(slip).is_int():
		out.wrongs.append(wrong({"v": slip}, R_NO_P_DENOMINATOR))
	out.generic = vs([p.add(Q.new(1)), p.sub(Q.new(1)), Q.new(f_known), p.mul(Q.new(2))])
	var diff := xp.sub(mean)
	var rhs := mean.mul(Q.new(f_known)).sub(fx_known)
	var eq := ["Σfx = %s + %sp and Σf = %d + p." % [D(fx_known), D(xp), f_known],
		"Mean = Σfx ÷ Σf = %s, so %s + %sp = %s(%d + p)." % [D(mean), D(fx_known), D(xp), D(mean), f_known],
		"Collect the p terms: (%s − %s)p = %s × %d − %s, so %sp = %s." % [D(xp), D(mean), D(mean), f_known, D(fx_known), D(diff), D(rhs)],
		final_step(ans)]
	var dev := ["The deviations balance: Σf(x − %s) = 0. The known columns give %s." % [D(mean), D(dev_known)],
		"The missing column gives p(%s − %s) = %sp." % [D(xp), D(mean), D(diff)],
		"%s + %sp = 0, so p = %s." % [D(dev_known), D(diff), D(p)], final_step(ans)]
	out.methods = {"frequency-equation": method(eq, ans.values), "deviations-sum-zero": method(dev, ans.values)}
	return out


func u_combined_mean(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var g: Dictionary = GROUPS[s.ctx]
	var mean: Q = s.mean
	var ans := Answer.make("number", {"v": mean}, {}, "mean = ")
	ans.show = "dec"
	ans.exact = true
	var out := {"lines": ["%d %s have a mean %s of %d." % [s.n1, g.a, g.what, s.m1], "%d %s have a mean %s of %d." % [s.n2, g.b, g.what, s.m2]],
		"asked": "Find the mean %s of all %d %s." % [g.what, s.n, g.all], "answer": ans, "table": null}
	var t1: int = s.n1 * s.m1
	var t2: int = s.n2 * s.m2
	out.wrongs = [wrong({"v": Q.new(s.m1 + s.m2, 2)}, R_AVERAGE_MEANS)]
	out.generic = vs([mean.add(Q.new(1)), mean.sub(Q.new(1)), Q.new(t1 + t2, s.n + 2), Q.new(t1 + t2, s.n - 1), Q.new(maxi(s.m1, s.m2)), Q.new(t1 + t2)])
	out.methods = {"total-from-mean": method(["The first group's total is %d × %d = %d and the second's is %d × %d = %d." % [s.n1, s.m1, t1, s.n2, s.m2, t2],
		"All %d + %d = %d values add to %d + %d = %d." % [s.n1, s.n2, s.n, t1, t2, t1 + t2],
		"The mean is %d ÷ %d = %s." % [t1 + t2, s.n, D(mean)], final_step(ans)], ans.values)}
	return out


# ── Choosing a measure ───────────────────────────────────────

static func outlier_lines(s: Dictionary) -> Array:
	return [SPREADS[s.ctx], L(s.xs)]


func u_choose_average(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("choice", {"v": CENTRES[1]}, {"options": CENTRES})
	var big: Q = s.data[s.n - 1]
	var median: Q = s.median
	var mean: Q = s.mean
	var total := DataSummarySituation.total_of(s.data)
	var out := {"lines": outlier_lines(s), "asked": "Which is the most appropriate measure of the centre of these data?", "answer": ans, "table": null,
		"wrongs": [wrong({"v": CENTRES[0]}, R_MEAN_BEST), wrong({"v": CENTRES[2]}, R_MODE_BEST)], "generic": [{"v": CENTRES[3]}]}
	var final := "So the most appropriate measure of the centre is %s." % CENTRES[1]
	out.methods = {
		"outlier-skew-check": method(["%s is far above the other values, so the data are skewed by an outlier." % D(big),
			"The mean uses every value, so the outlier drags it upwards; the median does not move much.", final], ans.values),
		"compare-mean-median": method(["mean = %s ÷ 8 = %s" % [D(total), W(mean)],
			"median = (%s + %s) ÷ 2 = %s" % [D(s.data[3]), D(s.data[4]), D(median)],
			"The mean (%s) is far above the median (%s): an extreme value is pulling it up, so the median is more typical." % [W(mean), D(median)], final], ans.values),
	}
	return out


func u_choose_spread(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("choice", {"v": SPREAD_MEASURES[1]}, {"options": SPREAD_MEASURES})
	var big: Q = s.data[s.n - 1]
	var iqr: Q = s.q3.sub(s.q1)
	var out := {"lines": outlier_lines(s), "asked": "One value is an outlier. Which measure of spread is least affected by it?", "answer": ans, "table": null,
		"wrongs": [], "generic": [{"v": SPREAD_MEASURES[0]}, {"v": SPREAD_MEASURES[2]}, {"v": SPREAD_MEASURES[3]}]}
	out.methods = {"outlier-skew-check": method(["%s is far from the other values: it stretches the range (%s) and the standard deviation." % [D(big), D(DataSummarySituation.range_of(s.data))],
		"The interquartile range uses only the middle half of the ordered values: Q₁ = %s and Q₃ = %s, so IQR = %s, whatever the outlier is." % [D(s.q1), D(s.q3), D(iqr)],
		"So the measure of spread least affected is %s." % SPREAD_MEASURES[1]], ans.values)}
	return out
