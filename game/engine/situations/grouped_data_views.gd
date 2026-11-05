class_name GroupedDataViews
extends ExtensionViews
## The views on the `grouped-data` situation: one builder per unknown of t4-grouped-data (FAL-740).
## A frequency table runs down the card, as it does on the exam, with the class or value on the
## left and the frequency on the right (q.table). An estimate replaces each class by its
## mid-interval value. An answer is exact on Paper 1 and to 3 s.f. on Paper 2 where it needs
## rounding. The GDC methods and the standard deviations of a table are Paper 2 only.
##
## `given` is the situation for the export. The checker reads the numbers back from the table and
## the lines; it takes only the story's index from `given`.

const GM := "SL4.3.grouped-mean#"
const SD := "SL4.3.sd-variance#"
const MT := "SL4.3.mean-totals#"
const MM := "SL4.3.mean-median-mode#"
const R_BY_CLASSES := GM + "0"
const R_UPPER := GM + "1"
const R_EXACT := GM + "2"
const R_LOWER := GM + "3"
const R_WIDTH := GM + "4"
const R_NO_FREQ := GM + "5"
const R_MEDIAN_CLASS := GM + "6"
const R_P_LEFT_OUT := GM + "7"
const R_FIRST_WIDTH := GM + "8"
const R_SX := SD + "0"
const R_SWAPPED := SD + "1"
const R_NEGATIVE := SD + "2"
const R_ABS := SD + "3"
const R_DOUBLE := SD + "4"
const R_HALVE := SD + "5"
const R_LARGER_MEAN := SD + "6"
const R_BACKWARDS := SD + "7"
const R_ALL_WITHIN := SD + "8"
const R_AVERAGE := MT + "0"
const R_NO_P := MT + "1"
const R_KNOWN_SUM := MT + "2"
const R_EQUAL_SHARE := MT + "3"
const R_P_Q_SWAPPED := MT + "4"
const R_OLD_COUNT := MT + "5"
const R_ONE_F := MT + "6"
const R_WHOLE_SIZE := MT + "7"
const R_MEAN_EQ := MM + "3"
const R_ONE_SIDE := MM + "4"

## A grouped table's story: the letter, the two heads, what `many` counts and the line above it.
const CLASSES := [
	{"sym": "t", "head": "Time, t (minutes)", "count": "Caravans", "many": "caravans", "line": "The table shows how long each caravan took to cross the salt flat.", "what": "crossing times"},
	{"sym": "l", "head": "Length, l (cm)", "count": "Rats", "many": "rats", "line": "The table shows the length of each rat caught at the pump house.", "what": "rat lengths"},
	{"sym": "m", "head": "Mass, m (kg)", "count": "Crates", "many": "crates", "line": "The table shows the mass of each crate in the depot.", "what": "crate masses"},
	{"sym": "d", "head": "Distance, d (km)", "count": "Scouts", "many": "scouts", "line": "The table shows how far each scout walked in a week.", "what": "distances walked"},
	{"sym": "w", "head": "Water, w (litres)", "count": "Households", "many": "households", "line": "The table shows how much water each household drew in a week.", "what": "amounts of water drawn"},
	{"sym": "r", "head": "Range, r (km)", "count": "Radios", "many": "radios", "line": "The table shows the range of each radio on the repair bench.", "what": "radio ranges"},
]
## A table of single values.
const VALUES := [
	{"head": "Rats caught", "count": "Trap lines", "many": "trap lines", "line": "The table shows how many rats each trap line caught."},
	{"head": "Flat tyres", "count": "Crews", "many": "crews", "line": "The table shows how many flat tyres each crew had in a year."},
	{"head": "Fuses blown", "count": "Months", "many": "months", "line": "The table shows how many fuses blew each month."},
	{"head": "Barrels filled", "count": "Days", "many": "days", "line": "The table shows how many barrels were filled each day."},
	{"head": "Radios fixed", "count": "Weeks", "many": "weeks", "line": "The table shows how many radios were fixed each week."},
	{"head": "Scrap runs", "count": "Scavengers", "many": "scavengers", "line": "The table shows how many scrap runs each scavenger made."},
]
## Groups of things: the groups, what they are, what was measured, and how it reads.
const GROUPS := [
	{"names": ["the north camp", "the south camp", "the river camp"], "head": "Camp", "things": "scouts", "verb": "carried a mean of", "tail": " kg of scrap", "what": "mass of scrap carried", "all": "total mass of scrap carried", "unit": " kg", "mean": "Mean (kg)"},
	{"names": ["the day shift", "the night shift", "the dawn shift"], "head": "Shift", "things": "guards", "verb": "walked a mean of", "tail": " km", "what": "distance walked", "all": "total distance walked", "unit": " km", "mean": "Mean (km)"},
	{"names": ["the first depot", "the second depot", "the third depot"], "head": "Depot", "things": "crates", "verb": "held a mean of", "tail": " fuses", "what": "number of fuses held", "all": "total number of fuses held", "unit": "", "mean": "Mean"},
	{"names": ["the east well", "the west well", "the hill well"], "head": "Well", "things": "buckets", "verb": "held a mean of", "tail": " litres", "what": "volume of water held", "all": "total volume of water held", "unit": " litres", "mean": "Mean (litres)"},
	{"names": ["the old road", "the new road", "the salt road"], "head": "Road", "things": "caravans", "verb": "hauled a mean of", "tail": " barrels", "what": "number of barrels hauled", "all": "total number of barrels hauled", "unit": "", "mean": "Mean"},
	{"names": ["the top bunker", "the middle bunker", "the low bunker"], "head": "Bunker", "things": "radios", "verb": "reached a mean of", "tail": " km", "what": "range reached", "all": "total of the ranges reached", "unit": " km", "mean": "Mean (km)"},
]
## Two places compared by their standard deviations.
const PAIRS := [
	{"a": "the north pump", "b": "the south pump", "at": "At", "thing": "the water drawn each day", "unit": "litres",
		"more": "More water is drawn on an average day at %s.", "each": "Every day's draw at %s is within %d litres of the mean."},
	{"a": "the east trap line", "b": "the west trap line", "at": "On", "thing": "the weekly catch", "unit": "rats",
		"more": "More rats are caught in an average week on %s.", "each": "Every week's catch on %s is within %d rats of the mean."},
	{"a": "the tower radio", "b": "the bunker radio", "at": "From", "thing": "the range of a message", "unit": "km",
		"more": "Messages reach further on average from %s.", "each": "Every message from %s reaches within %d km of the mean."},
	{"a": "the salt road", "b": "the river road", "at": "On", "thing": "the time for a crossing", "unit": "hours",
		"more": "An average crossing takes longer on %s.", "each": "Every crossing on %s is within %d hours of the mean."},
]

const WHY_RIGHT := "It is an estimate: the exact values in each class are not known."
const WHY_EXACT := "It is the exact mean: every row of the table was used."
const WHY_ROUNDED := "It is an estimate: the frequencies have been rounded."
const WHY_ONE := "It is an estimate: only the class with the most values was used."

const SUB := ["₁", "₂", "₃", "₄", "₅", "₆"]

const UNKNOWNS := ["modal-class", "modal-class-after-frequency", "mid-interval-value", "mid-interval-list", "estimate-mean", "estimate-why",
	"estimate-sd", "estimate-variance", "sd-from-table", "variance-from-table", "sd-of-small-set", "variance-of-small-set", "variance-from-sd",
	"sd-from-variance", "interpret-sd", "missing-frequency-from-total", "missing-frequency-from-estimate", "two-frequencies-from-mean",
	"missing-frequency-from-median", "missing-value-from-table-mean", "new-value-from-new-mean", "whole-mean-from-groups", "whole-total-from-groups",
	"group-mean-from-whole"]
## A table's standard deviation has too many squares for Paper 1.
const P2_ONLY := ["estimate-sd", "estimate-variance", "sd-from-table", "variance-from-table"]
const GDC := ["gdc-lists", "gdc-sigma"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, method_id: String) -> Array:
	if not has(unknown):
		return []
	return [2] if unknown in P2_ONLY or method_id in GDC else [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = GroupedDataSituation.export(s)
	# Only three wrong options fit, so each tag gets its turn.
	out.wrongs = rng.shuffled(out.wrongs)
	# No calculator on Paper 1, even in the other worked solutions.
	if s.paper == 1:
		for m in GDC:
			out.methods.erase(m)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## A value as a GDC shows it: 6 significant figures, no trailing zeros.
static func W(v: Variant) -> String:
	var t := Fmt.sf(v, 6)
	if t.contains("."):
		t = t.rstrip("0").rstrip(".")
	return t


static func L(xs: Array) -> String:
	return ", ".join(xs.map(func(x): return D(x)))


static func and_list(xs: Array) -> String:
	if xs.size() == 1:
		return D(xs[0])
	return L(xs.slice(0, xs.size() - 1)) + " and " + D(xs[xs.size() - 1])


static func plus(xs: Array) -> String:
	return " + ".join(xs.map(func(x): return D(x)))


## "3 × 15 + 6 × 25": the frequencies by the values, skipping a row.
static func products(fs: Array, xs: Array, skip: int = -1) -> String:
	var out: PackedStringArray = []
	for i in fs.size():
		if i != skip:
			out.append("%s × %s" % [D(fs[i]), D(xs[i])])
	return " + ".join(out)


static func without(xs: Array, i: int) -> Array:
	var out := xs.duplicate()
	out.remove_at(i)
	return out


static func total(xs: Array) -> Q:
	var t := Q.new(0)
	for x: Q in xs:
		t = t.add(x)
	return t


## "23.4 + 0.6" or "23.4 − 0.6": a plus a signed difference.
static func plus_signed(a: Q, d: Q) -> String:
	return "%s + %s" % [D(a), D(d)] if d.sign() >= 0 else "%s − %s" % [D(a), D(d.abs_q())]


## "1.8p − 2.8q": two coefficients.
static func two_terms(a: Q, b: Q) -> String:
	return "%sp %s %sq" % [D(a), "+" if b.sign() >= 0 else "−", D(b.abs_q())]


## "3 + 6 = 9", or the one number.
static func sum_text(xs: Array) -> String:
	return D(xs[0]) if xs.size() == 1 else "%s = %s" % [plus(xs), D(total(xs))]


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## A number: exact where it ends, else to 3 s.f.
static func num_ans(s: Dictionary, label: String, v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	if s.paper == 2 and Answer.needs_rounding(v):
		ans.show = "sf"
	else:
		ans.show = "dec"
		ans.exact = true
	return ans


static func exact_ans(label: String, v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	ans.show = "dec"
	ans.exact = true
	return ans


## How the question asks for a number.
static func to_sf(ans: Dictionary, text: String) -> String:
	return text + (", to 3 s.f." if ans.show == "sf" else ".")


## An option can show this: to 3 s.f. if the answer is, else within two decimal places.
static func shows(ans: Dictionary, v: Q) -> bool:
	return ans.show == "sf" or GroupedDataSituation.ends(v, 2)


static func wr(ans: Dictionary, v: Q, ref: String) -> Array:
	return [wrong({"v": v}, ref)] if v.sign() != 0 and shows(ans, v) and not too_close(ans, v) else []


## A wrong value this near a 3 s.f. answer would be marked right when typed.
static func too_close(ans: Dictionary, v: Q) -> bool:
	return ans.show == "sf" and absf(v.to_float() - ans.values.v.to_float()) < 0.01 * absf(ans.values.v.to_float())


## Fillers: positive numbers an option can show.
static func gen(ans: Dictionary, xs: Array) -> Array:
	return xs.filter(func(x): return x.sign() > 0 and shows(ans, x) and not too_close(ans, x)).map(func(x): return {"v": x})


static func nudges(v: Q) -> Array:
	return [v.add(Q.new(1)), v.sub(Q.new(1)), v.add(Q.new(2)), v.mul(Q.new(2))]


static func claim(tag: String, text: String) -> Dictionary:
	return {"form": tag, "vals": [], "text": text}


static func class_label(s: Dictionary, i: int) -> String:
	var c: Dictionary = CLASSES[s.ctx]
	var left := "≤" if s.closed == "lo" else "<"
	var right := "<" if s.closed == "lo" else "≤"
	return "%d %s %s %s %d" % [s.lo[i], left, c.sym, right, s.hi[i]]


static func class_labels(s: Dictionary) -> Array:
	var out: Array = []
	for i in s.lo.size():
		out.append(class_label(s, i))
	return out


## The left column, then the frequency in the row, with `blank` in row `at`.
static func rows(head: String, count: String, left: Array, s: Dictionary, blank: String = "", show_total: bool = false, blank2: String = "") -> Array:
	var out: Array = [[head, [count]]]
	for i in left.size():
		var cell: String = D(s.fs[i])
		if blank != "" and i == s.at:
			cell = blank
		if blank2 != "" and i == s.at2:
			cell = blank2
		out.append([left[i], [cell]])
	if show_total:
		out.append(["Total", [D(s.n)]])
	return out


## The grouped table and its line. With `blank`, row `at` shows it and the total is told.
static func class_view(s: Dictionary, blank: String = "") -> Dictionary:
	var c: Dictionary = CLASSES[s.ctx]
	var lines: Array = [c.line]
	var count: String = c.count
	if s.thousands:
		lines.append("The numbers of %s are in thousands." % c.many)
		count += " (thousands)"
	var show_total: bool = blank != "" and s.total_row
	if blank != "" and not s.total_row:
		lines.append("There are %s %s in all." % [D(s.n), c.many])
	return {"lines": lines, "table": {"rows": rows(c.head, count, class_labels(s), s, blank, show_total)}}


## The discrete table: the values down the left.
static func value_rows(s: Dictionary, blank: String = "", blank2: String = "") -> Array:
	var c: Dictionary = VALUES[s.ctx]
	return rows(c.head, c.count, s.xs.map(func(x): return D(x)), s, blank, false, blank2)


static func values_line(s: Dictionary) -> String:
	return VALUES[s.ctx].line


static func group_line(g: Dictionary, n: int, name: String, m: Q) -> String:
	return "%d %s from %s %s %s%s." % [n, g.things, name, g.verb, D(m), g.tail]


static func cap(t: String) -> String:
	return t.left(1).to_upper() + t.substr(1)


static func short_name(name: String) -> String:
	return cap(name.trim_prefix("the "))


static func group_rows(g: Dictionary, s: Dictionary) -> Array:
	var out: Array = [[g.head, ["Number", g.mean]]]
	for i in s.sizes.size():
		out.append([short_name(g.names[i]), [str(s.sizes[i]), D(s.means[i])]])
	return out


# ── The GDC, in every question that uses it ─────────────────

static func keyed(s: Dictionary, what: String) -> String:
	return "Enter the %s %s in list L1 and the frequencies %s in list L2." % [what, and_list(s.xs), and_list(s.fs)]


# ── The modal class and mid-interval values ──────────────────

func u_modal_class(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var labels := class_labels(s)
	var ans := Answer.make("choice", {"v": labels[s.big]}, {"options": labels})
	var out := class_view(s)
	out.asked = "Write down the modal class."
	out.answer = ans
	out.wrongs = [wrong({"v": labels[s.mid]}, R_MEDIAN_CLASS)]
	out.generic = labels.filter(func(l): return l != labels[s.big] and l != labels[s.mid]).map(func(l): return {"v": l})
	out.methods = {"any": method(["The modal class is the class with the greatest frequency.",
		"The greatest frequency is %s, in the row %s." % [D(s.fs[s.big]), labels[s.big]], "So the modal class is %s." % Answer.text(ans)], ans.values)}
	return out


func u_modal_class_after_frequency(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var labels := class_labels(s)
	var ans := Answer.make("choice", {"v": labels[s.big]}, {"options": labels})
	var out := class_view(s, "p")
	out.asked = "Write down the modal class."
	out.answer = ans
	out.wrongs = []
	if s.p_top:
		out.wrongs.append(wrong({"v": labels[s.known_top]}, R_P_LEFT_OUT))
	if s.mid >= 0 and s.mid != s.big:
		out.wrongs.append(wrong({"v": labels[s.mid]}, R_MEDIAN_CLASS))
	out.generic = labels.filter(func(l): return l != labels[s.big]).map(func(l): return {"v": l})
	var known := without(s.fs, s.at)
	var rest := total(known)
	out.methods = {"any": method(["p is hidden, so find it first: the frequencies add to %s." % D(s.n),
		"The known rows add to %s = %s, so p = %s − %s = %s." % [plus(known), D(rest), D(s.n), D(rest), D(s.p)],
		"Now compare all the rows: the greatest frequency is %s, in the row %s." % [D(s.fs[s.big]), labels[s.big]],
		"So the modal class is %s." % Answer.text(ans)], ans.values)}
	return out


func u_mid_interval_value(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var i: int = s.at
	var lo: int = s.lo[i]
	var hi: int = s.hi[i]
	var ans := exact_ans("mid-interval value = ", s.xs[i])
	var out := class_view(s)
	out.asked = "Write down the mid-interval value of the class %s." % class_label(s, i)
	out.answer = ans
	out.wrongs = wr(ans, Q.new(hi), R_UPPER) + wr(ans, Q.new(lo), R_LOWER) + wr(ans, Q.new(hi - lo), R_WIDTH)
	out.generic = gen(ans, nudges(s.xs[i]))
	out.methods = {"any": method(["The mid-interval value is halfway between the two ends of the class.",
		"(%d + %d) ÷ 2 = %s" % [lo, hi, D(s.xs[i])], final_step(ans)], ans.values)}
	return out


## Named slots x₁ to x_k, one for each row.
static func list_values(xs: Array) -> Dictionary:
	var v := {}
	for i in xs.size():
		v["v%d" % i] = xs[i]
	return v


func u_mid_interval_list(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var names: Array = []
	var sums: PackedStringArray = []
	for i in s.xs.size():
		names.append("x" + SUB[i])
		sums.append("(%d + %d) ÷ 2 = %s" % [s.lo[i], s.hi[i], D(s.xs[i])])
	var ans := Answer.make("named", list_values(s.xs), {"names": names})
	ans.show = "dec"
	ans.exact = true
	var out := class_view(s)
	out.asked = "List the mid-interval value of each class, x₁ for the first row, and so on down the table."
	out.answer = ans
	var w0 := Q.new(s.hi[0] - s.lo[0])
	var stepped: Array = []
	for i in s.xs.size():
		stepped.append(s.xs[0].add(w0.mul(Q.new(i))))
	out.wrongs = [wrong(list_values(s.hi.map(func(h): return Q.new(h))), R_UPPER), wrong(list_values(s.lo.map(func(l): return Q.new(l))), R_LOWER),
		wrong(list_values(stepped), R_FIRST_WIDTH)]
	out.generic = [list_values(s.xs.map(func(x): return x.add(Q.new(1))))]
	out.methods = {"any": method(["Each mid-interval value is halfway between the ends of its class. The classes need not be equally wide, so find each one.",
		"; ".join(sums), "So " + Answer.text(ans) + "."], ans.values)}
	return out


# ── Estimates from a grouped table ───────────────────────────

static func mean_steps(s: Dictionary, shown: String) -> Array:
	return ["The mid-interval values are %s." % and_list(s.xs), "Σfx = %s = %s" % [products(s.fs, s.xs), D(s.fx)],
		"Σf = %s = %s" % [plus(s.fs), D(s.n)], "Mean ≈ Σfx ÷ Σf = %s ÷ %s = %s" % [D(s.fx), D(s.n), shown]]


static func gdc_mean_steps(s: Dictionary, shown: String) -> Array:
	return [keyed(s, "mid-interval values"), "Run 1-Var Stats with L2 as the frequency list.", "Read off x̄ = %s." % shown]


func u_estimate_mean(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := num_ans(s, "mean ≈ ", s.mean)
	var out := class_view(s)
	out.asked = to_sf(ans, "Find an estimate of the mean")
	out.answer = ans
	var k := Q.new(s.xs.size())
	var uppers: Array = s.hi.map(func(h): return Q.new(h))
	var lowers: Array = s.lo.map(func(l): return Q.new(l))
	var by_hi := Q.new(0)
	var by_lo := Q.new(0)
	for i in s.xs.size():
		by_hi = by_hi.add(s.fs[i].mul(uppers[i]))
		by_lo = by_lo.add(s.fs[i].mul(lowers[i]))
	out.wrongs = wr(ans, s.fx.div(k), R_BY_CLASSES) + wr(ans, by_hi.div(s.n), R_UPPER) + wr(ans, by_lo.div(s.n), R_LOWER) + wr(ans, total(s.xs).div(k), R_NO_FREQ)
	out.generic = gen(ans, nudges(s.mean))
	var shown: String = D(s.mean) if ans.show == "dec" else W(s.mean)
	out.methods = {"midpoint-formula": method(mean_steps(s, shown) + [final_step(ans)], ans.values),
		"gdc-lists": method(gdc_mean_steps(s, shown) + [final_step(ans)], ans.values)}
	return out


func u_estimate_why(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("claim", claim("right", WHY_RIGHT))
	var out := class_view(s)
	var shown: String = D(s.mean) if not Answer.needs_rounding(s.mean) else Fmt.sf(s.mean)
	out.lines.append("Using the mid-interval values, the mean comes to %s." % shown)
	out.asked = "Which statement about this value is true?"
	out.answer = ans
	out.wrongs = [wrong(claim("exact", WHY_EXACT), R_EXACT)]
	out.generic = [claim("rounded", WHY_ROUNDED), claim("one", WHY_ONE)]
	out.methods = {"any": method(["A class gives only a range for its values: the table doesn't say where in the class each one lies.",
		"The mid-interval value stands in for all the values of its class, so the result is an estimate, not the exact mean.", WHY_RIGHT], ans.values)}
	return out


## σ with `xs` in place of the mid-interval values and the table's frequencies.
static func spread_with(s: Dictionary, xs: Array) -> Q:
	var t := {"xs": xs, "fs": s.fs}
	GroupedDataSituation.stats(t)
	return t.variance


func _spread(s: Dictionary, asked: String, grouped: bool, want_sd: bool) -> Dictionary:
	var label := "standard deviation ≈ " if want_sd else "variance ≈ "
	if not grouped:
		label = "standard deviation = " if want_sd else "variance = "
	var value: Q = s.sd if want_sd else s.variance
	var ans := num_ans(s, label, value)
	var out := class_view(s) if grouped else {"lines": [values_line(s)], "table": {"rows": value_rows(s)}}
	out.asked = to_sf(ans, asked)
	out.answer = ans
	var flat := GroupedDataSituation.flat_variance(s.xs)
	out.wrongs = []
	if want_sd:
		out.wrongs += wr(ans, s.variance, R_SWAPPED) + wr(ans, GroupedDataSituation.root(flat), R_NO_FREQ)
	else:
		out.wrongs += wr(ans, s.sd, R_SWAPPED) + wr(ans, flat, R_NO_FREQ)
	if not s.thousands:
		var sx := GroupedDataSituation.sample_sd(s)
		out.wrongs += wr(ans, sx if want_sd else GroupedDataSituation.sample_variance(s), R_SX)
	if grouped:
		var hi_var := spread_with(s, s.hi.map(func(h): return Q.new(h)))
		out.wrongs += wr(ans, GroupedDataSituation.root(hi_var) if want_sd else hi_var, R_UPPER)
	out.generic = gen(ans, [s.mean, s.sd.mul(Q.new(2)), value.add(Q.new(1)), value.mul(Q.new(2))])
	var read := "Read off σx = %s, not Sx, which divides by one less than n." % W(s.sd)
	var finish: Array = [] if want_sd else ["Variance = σx² = %s² = %s" % [W(s.sd), W(s.variance)]]
	var data := "mid-interval values" if grouped else "values"
	var run := "Run 1-Var Stats with L2 as the frequency list."
	var sigma: Array = [keyed(s, data), run, read] + finish + [final_step(ans)]
	var lists: Array = ["Put the %s %s in L1 and the frequencies %s in L2." % [data, and_list(s.xs), and_list(s.fs)], run,
		"Read σx = %s from the screen." % W(s.sd)] + finish + [final_step(ans)]
	out.methods = {"gdc-sigma": method(sigma, ans.values), "gdc-lists": method(lists, ans.values)}
	return out


func u_estimate_sd(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _spread(s, "Find an estimate of the standard deviation", true, true)


func u_estimate_variance(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _spread(s, "Find an estimate of the variance", true, false)


func u_sd_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _spread(s, "Find the standard deviation", false, true)


func u_variance_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _spread(s, "Find the variance", false, false)


# ── A small set, and the link between variance and sd ────────

func _small_set(s: Dictionary, want_sd: bool) -> Dictionary:
	var name := "standard deviation" if want_sd else "variance"
	var value: Q = s.sd if want_sd else s.variance
	var ans := num_ans(s, name + " = ", value)
	var count: int = s.xs.size()
	var sq_sum: Q = s.variance.mul(s.n)
	var devs: Array = s.xs.map(func(x): return x.sub(s.mean))
	var abs_sum := Q.new(0)
	for d: Q in devs:
		abs_sum = abs_sum.add(d.abs_q())
	var out := {"lines": ["The %d values are %s." % [count, L(s.xs)]], "table": null, "answer": ans}
	out.asked = to_sf(ans, "Find the %s of these values" % name)
	var by_less: Q = sq_sum.div(Q.new(count - 1))
	out.wrongs = wr(ans, abs_sum.div(s.n), R_ABS)
	if want_sd:
		out.wrongs += wr(ans, s.variance, R_SWAPPED) + wr(ans, GroupedDataSituation.root(by_less), R_SX)
	else:
		out.wrongs += wr(ans, s.sd, R_SWAPPED) + wr(ans, by_less, R_SX)
	out.generic = gen(ans, [sq_sum, s.mean, value.add(Q.new(1)), value.add(Q.new(2)), value.mul(Q.new(2))])
	var squares: Array = devs.map(func(d): return d.mul(d))
	var steps: Array = ["Mean = (%s) ÷ %d = %s ÷ %d = %s" % [plus(s.xs), count, D(s.fx), count, D(s.mean)],
		"Take the mean from each value: the deviations are %s." % L(devs),
		"Square them and add: %s = %s" % [plus(squares), D(sq_sum)]]
	if want_sd:
		var shown: String = D(s.sd) if ans.show == "dec" else W(s.sd)
		steps.append("σ = √(%s ÷ %d) = √%s = %s" % [D(sq_sum), count, D(s.variance), shown])
	else:
		var shown: String = D(s.variance) if GroupedDataSituation.ends(s.variance, 6) else W(s.variance)
		steps.append("σ² = %s ÷ %d = %s" % [D(sq_sum), count, shown])
	steps.append(final_step(ans))
	var gdc: Array = ["Enter the %d values %s in list L1." % [count, L(s.xs)], "Run 1-Var Stats.", "Read off σx = %s, not Sx." % W(s.sd)]
	if not want_sd:
		gdc.append("Variance = σx² = %s² = %s" % [W(s.sd), W(s.variance)])
	gdc.append(final_step(ans))
	out.methods = {"definition-formula": method(steps, ans.values), "gdc-sigma": method(gdc, ans.values)}
	return out


func u_sd_of_small_set(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _small_set(s, true)


func u_variance_of_small_set(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _small_set(s, false)


func u_variance_from_sd(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = CLASSES[s.ctx]
	var ans := num_ans(s, "variance = ", s.variance)
	var out := {"lines": ["The standard deviation of the %s is %s." % [c.what, D(s.sd)]], "table": null, "answer": ans}
	out.asked = to_sf(ans, "Find the variance")
	out.wrongs = wr(ans, s.sd.mul(Q.new(2)), R_DOUBLE) + wr(ans, s.sd, R_SWAPPED)
	out.generic = gen(ans, [s.sd.div(Q.new(2)), s.sd.add(Q.new(1)), s.variance.mul(Q.new(2)), s.variance.add(Q.new(1))])
	out.methods = {"variance-sd-link": method(["The variance is the square of the standard deviation.",
		"%s × %s = %s" % [D(s.sd), D(s.sd), D(s.variance)], final_step(ans)], ans.values)}
	return out


func u_sd_from_variance(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = CLASSES[s.ctx]
	var ans := num_ans(s, "standard deviation = ", s.sd)
	var out := {"lines": ["The variance of the %s is %s." % [c.what, D(s.variance)]], "table": null, "answer": ans}
	out.asked = to_sf(ans, "Find the standard deviation")
	out.wrongs = wr(ans, s.variance.div(Q.new(2)), R_HALVE) + wr(ans, s.variance, R_SWAPPED) + wr(ans, s.sd.neg(), R_NEGATIVE)
	out.generic = gen(ans, [s.sd.add(Q.new(1)), s.sd.mul(Q.new(2)), s.variance.add(Q.new(1))])
	var shown: String = D(s.sd) if ans.show == "dec" else W(s.sd)
	out.methods = {"variance-sd-link": method(["The standard deviation is the positive square root of the variance.",
		"√%s = %s" % [D(s.variance), shown], final_step(ans)], ans.values)}
	return out


func u_interpret_sd(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = PAIRS[s.ctx]
	var more: String = c.a if s.first else c.b
	var less: String = c.b if s.first else c.a
	var large: int = maxi(s.sd1, s.sd2)
	var right := "%s varies more around its mean %s." % [cap(c.thing), _place(c, more)]
	var back := "%s varies more around its mean %s." % [cap(c.thing), _place(c, less)]
	var ans := Answer.make("claim", claim("right", right))
	var out := {"lines": ["%s %s, %s has mean %d %s and standard deviation %d %s." % [c.at, c.a, c.thing, s.m1, c.unit, s.sd1, c.unit],
		"%s %s, %s has mean %d %s and standard deviation %d %s." % [c.at, c.b, c.thing, s.m2, c.unit, s.sd2, c.unit]], "table": null, "answer": ans}
	out.asked = "What do these figures show?"
	out.wrongs = [wrong(claim("mean", c.more % more), R_LARGER_MEAN), wrong(claim("back", back), R_BACKWARDS), wrong(claim("each", c.each % [more, large]), R_ALL_WITHIN)]
	out.generic = []
	out.methods = {"any": method(["The standard deviation measures how far the values typically lie from their mean. It says nothing about which mean is greater.",
		"The larger standard deviation is %d %s, %s." % [large, c.unit, _place(c, more)], right], ans.values)}
	return out


static func _place(c: Dictionary, name: String) -> String:
	return "%s %s" % [String(c.at).to_lower(), name]


# ── Missing frequencies and values ───────────────────────────

func u_missing_frequency_from_total(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := exact_ans("p = ", s.p)
	var out := class_view(s, "p")
	out.asked = "Find the value of p."
	out.answer = ans
	var known := without(s.fs, s.at)
	var rest := total(known)
	out.wrongs = wr(ans, rest, R_KNOWN_SUM)
	var share: Q = s.n.div(Q.new(s.xs.size()))
	if share.is_int():
		out.wrongs += wr(ans, share, R_EQUAL_SHARE)
	out.generic = gen(ans, nudges(s.p))
	out.methods = {"any": method(["The frequencies add to %s." % D(s.n), "The known rows add to %s = %s." % [plus(known), D(rest)],
		"p = %s − %s = %s" % [D(s.n), D(rest), D(s.p)], final_step(ans)], ans.values)}
	return out


## p from a mean, whatever the values are: the row's value is xs[at].
func _frequency_methods(s: Dictionary, ans: Dictionary, mean_name: String) -> Dictionary:
	var i: int = s.at
	var xp: Q = s.xs[i]
	var mean: Q = s.mean
	var f_known: Q = s.n.sub(s.p)
	var fx_known: Q = s.fx.sub(s.p.mul(xp))
	var diff := xp.sub(mean)
	var rhs := mean.mul(f_known).sub(fx_known)
	var known_devs: Array = []
	var dev_known := Q.new(0)
	for j in s.xs.size():
		if j != i:
			var d: Q = s.fs[j].mul(s.xs[j].sub(mean))
			known_devs.append(d)
			dev_known = dev_known.add(d)
	var eq := ["Σfx = %s + %sp and Σf = %s + p, with the row of p using x = %s." % [D(fx_known), D(xp), D(f_known), D(xp)],
		"%s = Σfx ÷ Σf = %s, so %s + %sp = %s(%s + p)." % [mean_name, D(mean), D(fx_known), D(xp), D(mean), D(f_known)],
		"Collect p: %sp − %sp = %s × %s − %s, so %sp = %s." % [D(xp), D(mean), D(mean), D(f_known), D(fx_known), D(diff), D(rhs)],
		"p = %s ÷ %s = %s" % [D(rhs), D(diff), D(s.p)], final_step(ans)]
	var dev := ["The deviations from the mean balance: Σf(x − %s) = 0." % D(mean),
		"The known rows give f(x − %s) = %s, which add to %s." % [D(mean), and_list(known_devs), D(dev_known)],
		"The row of p gives p(%s − %s) = %sp." % [D(xp), D(mean), D(diff)],
		"%sp = %s, so p = %s ÷ %s = %s" % [D(diff), D(dev_known.neg()), D(dev_known.neg()), D(diff), D(s.p)], final_step(ans)]
	return {"frequency-equation": method(eq, ans.values), "deviations-sum-zero": method(dev, ans.values)}


func u_missing_frequency_from_estimate(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = CLASSES[s.ctx]
	var ans := exact_ans("p = ", s.p)
	var xp: Q = s.xs[s.at]
	var f_known: Q = s.n.sub(s.p)
	var fx_known: Q = s.fx.sub(s.p.mul(xp))
	var out := {"lines": [c.line, "Using mid-interval values, an estimate of the mean is %s." % D(s.mean)],
		"table": {"rows": rows(c.head, c.count, class_labels(s), s, "p")}, "asked": "Find the value of p.", "answer": ans}
	# The slip: p left out of Σf, so xp = mean × Σf − Σfx.
	out.wrongs = []
	var slip: Q = s.mean.mul(f_known).sub(fx_known).div(xp)
	if slip.sign() > 0:
		out.wrongs += wr(ans, slip, R_NO_P)
	out.generic = gen(ans, nudges(s.p) + [f_known])
	out.methods = _frequency_methods(s, ans, "Mean")
	return out


func u_two_frequencies_from_mean(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = VALUES[s.ctx]
	var a: Q = s.xs[s.at]
	var b: Q = s.xs[s.at2]
	var ans := Answer.make("pq", {"p": s.p, "q": s.q})
	ans.show = "dec"
	ans.exact = true
	var out := {"lines": [values_line(s), "There are %s %s in all, and the mean is %s." % [D(s.n), c.many, D(s.mean)]],
		"table": {"rows": value_rows(s, "p", "q")}, "asked": "Find the value of p and the value of q.", "answer": ans}
	var f_known: Q = s.n.sub(s.p).sub(s.q)
	var fx_known: Q = s.fx.sub(s.p.mul(a)).sub(s.q.mul(b))
	var left: Q = s.p.add(s.q)
	var right: Q = s.mean.mul(s.n).sub(fx_known)
	out.wrongs = [wrong({"p": s.q, "q": s.p}, R_P_Q_SWAPPED)]
	# The slip: p and q left out of Σf, so ap + bq = mean × (known Σf) − known Σfx.
	var slip_rhs: Q = s.mean.mul(f_known).sub(fx_known)
	var slip_q: Q = slip_rhs.sub(a.mul(left)).div(b.sub(a))
	var slip_p: Q = left.sub(slip_q)
	if slip_p.sign() > 0 and slip_q.sign() > 0 and GroupedDataSituation.ends(slip_p, 2) and GroupedDataSituation.ends(slip_q, 2):
		out.wrongs.append(wrong({"p": slip_p, "q": slip_q}, R_NO_P))
	out.generic = [{"p": s.p.add(Q.new(1)), "q": s.q.sub(Q.new(1))}, {"p": s.p.sub(Q.new(1)), "q": s.q.add(Q.new(1))},
		{"p": s.p.add(Q.new(2)), "q": s.q.sub(Q.new(2))}, {"p": s.p.add(Q.new(1)), "q": s.q.add(Q.new(1))}]
	var d := b.sub(a)
	var last := "(%s − %s)q = %s − %s × %s = %s, so q = %s ÷ %s = %s and p = %s − %s = %s" % [D(b), D(a), D(right), D(a), D(left), D(right.sub(a.mul(left))),
		D(right.sub(a.mul(left))), D(d), D(s.q), D(left), D(s.q), D(s.p)]
	var eq := ["The frequencies add to %s: %s + p + q = %s, so p + q = %s." % [D(s.n), D(f_known), D(s.n), D(left)],
		"Σfx = mean × Σf = %s × %s = %s, so %s + %sp + %sq = %s." % [D(s.mean), D(s.n), D(s.mean.mul(s.n)), D(fx_known), D(a), D(b), D(s.mean.mul(s.n))],
		"So %sp + %sq = %s. Take %s times p + q = %s away." % [D(a), D(b), D(right), D(a), D(left)], last, final_step(ans)]
	var kd := Q.new(0)
	for j in s.xs.size():
		if j != s.at and j != s.at2:
			kd = kd.add(s.fs[j].mul(s.xs[j].sub(s.mean)))
	var da: Q = a.sub(s.mean)
	var db: Q = b.sub(s.mean)
	var coef := db.sub(da)
	var rest: Q = kd.neg().sub(da.mul(left))
	var dev := ["The frequencies add to %s, so p + q = %s − %s = %s." % [D(s.n), D(s.n), D(f_known), D(left)],
		"The deviations balance: Σf(x − %s) = 0. The known rows give %s." % [D(s.mean), D(kd)],
		"So %s = %s." % [two_terms(da, db), D(kd.neg())],
		"With p = %s − q, the q terms leave %s, so p = %s − %s = %s" % [D(left), ("q = %s" % D(rest)) if coef.eq(Q.new(1)) else "%sq = %s, so q = %s ÷ %s = %s" % [D(coef), D(rest), D(rest), D(coef), D(s.q)], D(left), D(s.q), D(s.p)], final_step(ans)]
	out.methods = {"frequency-equation": method(eq, ans.values), "deviations-sum-zero": method(dev, ans.values)}
	return out


func u_missing_frequency_from_median(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := exact_ans("x = ", s.p)
	var out := {"lines": [values_line(s), "The median is %s." % D(s.median)], "table": {"rows": value_rows(s, "x")},
		"asked": "Find the value of x.", "answer": ans}
	var upper: bool = s.at > s.cut
	var low: Array = []
	var high: Array = []
	for i in s.fs.size():
		if i == s.at:
			continue
		if i <= s.cut:
			low.append(s.fs[i])
		else:
			high.append(s.fs[i])
	var ls := total(low)
	var hs := total(high)
	var near: Q = ls if upper else hs
	var far: Q = hs if upper else ls
	var near_list: Array = low if upper else high
	var far_list: Array = high if upper else low
	var known_n: Q = s.n.sub(s.p)
	var known_fx: Q = s.fx.sub(s.p.mul(s.xs[s.at]))
	var slip: Q = s.median.mul(known_n).sub(known_fx).div(s.xs[s.at].sub(s.median)) if not s.xs[s.at].eq(s.median) else Q.new(-1)
	out.wrongs = wr(ans, near, R_ONE_SIDE)
	if slip.sign() > 0:
		out.wrongs += wr(ans, slip, R_MEAN_EQ)
	out.generic = gen(ans, nudges(s.p))
	var a: Q = s.xs[s.cut]
	var b: Q = s.xs[s.cut + 1]
	out.methods = {"ordered-position": method(["The median %s is halfway between %s and %s, so the two middle values are one %s and one %s." % [D(s.median), D(a), D(b), D(a), D(b)],
		"So exactly half of the values are at most %s and half are at least %s." % [D(a), D(b)],
		"One side is known: %s. The side with x has %s, and x." % [sum_text(near_list), sum_text(far_list)],
		"Both sides must be equal: x = %s − %s = %s" % [D(near), D(far), D(s.p)], final_step(ans)], ans.values)}
	return out


func u_missing_value_from_table_mean(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: Q = s.k
	var f: Q = s.fs[s.at]
	var ans := exact_ans("k = ", k)
	var c: Dictionary = VALUES[s.ctx]
	var left: Array = s.xs.map(func(x): return D(x))
	left[s.at] = "k"
	var out := {"lines": [c.line, "The mean is %s." % D(s.mean)], "table": {"rows": rows(c.head, c.count, left, s)}, "asked": "Find the value of k.", "answer": ans}
	var known_fx: Q = s.fx.sub(f.mul(k))
	var want: Q = s.mean.mul(s.n)
	var rest := want.sub(known_fx)
	out.wrongs = wr(ans, rest, R_ONE_F)
	out.generic = gen(ans, nudges(k) + [s.mean])
	var known_devs: Array = []
	var dev := Q.new(0)
	for j in s.xs.size():
		if j != s.at:
			var d: Q = s.fs[j].mul(s.xs[j].sub(s.mean))
			known_devs.append(d)
			dev = dev.add(d)
	var ftext := D(f)
	out.methods = {"total-from-mean": method(["Σf = %s = %s, so the total of all the values is %s × %s = %s." % [plus(s.fs), D(s.n), D(s.mean), D(s.n), D(want)],
		"The known rows give %s = %s." % [products(s.fs, s.xs, s.at), D(known_fx)],
		"The row of k is the rest: %sk = %s − %s = %s." % [ftext, D(want), D(known_fx), D(rest)],
		"k = %s ÷ %s = %s" % [D(rest), ftext, D(k)], final_step(ans)], ans.values),
		"deviations-sum-zero": method(["Σf(x − %s) = 0: the deviations from the mean balance." % D(s.mean),
		"The known rows give f(x − %s) = %s, which add to %s." % [D(s.mean), and_list(known_devs), D(dev)],
		"So %s(k − %s) = %s, and k − %s = %s ÷ %s = %s." % [ftext, D(s.mean), D(dev.neg()), D(s.mean), D(dev.neg()), ftext, D(k.sub(s.mean))],
		"k = %s = %s" % [plus_signed(s.mean, k.sub(s.mean)), D(k)],
		final_step(ans)], ans.values)}
	return out


func u_new_value_from_new_mean(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var g: Dictionary = GROUPS[s.ctx]
	var c: int = s.count
	var old: Q = s.old
	var new_m: Q = s.new
	var k: Q = s.k
	var ans := exact_ans("new value = ", k)
	var one: String = String(g.things).trim_suffix("s")
	var out := {"lines": ["%d %s %s %s%s." % [c, g.things, g.verb, D(old), g.tail], "One more %s joins them, and the mean of all %d becomes %s%s." % [one, c + 1, D(new_m), g.tail]],
		"table": null, "answer": ans, "asked": "Find the %s by the new %s." % [g.what, one]}
	var before := old.mul(Q.new(c))
	var after := new_m.mul(Q.new(c + 1))
	out.wrongs = wr(ans, new_m.mul(Q.new(2)).sub(old), R_AVERAGE) + (wr(ans, new_m.sub(old).mul(Q.new(c)), R_OLD_COUNT) if new_m.sub(old).sign() > 0 else [])
	out.generic = gen(ans, nudges(k) + [new_m])
	var dev := old.sub(new_m).mul(Q.new(c))
	out.methods = {"total-from-mean": method(["The %d %s had a total of %s × %d = %s." % [c, g.things, D(old), c, D(before)],
		"All %d now have a total of %s × %d = %s." % [c + 1, D(new_m), c + 1, D(after)], "The new value is the difference: %s − %s = %s" % [D(after), D(before), D(k)],
		final_step(ans)], ans.values),
		"deviations-sum-zero": method(["Measure from the new mean %s: the deviations of all %d values add to zero." % [D(new_m), c + 1],
		"The first %d values add up to %d × (%s − %s) = %s away from it." % [c, c, D(old), D(new_m), D(dev)],
		"The new value's deviation balances that, so it is %s = %s" % [plus_signed(new_m, dev.neg()), D(k)], final_step(ans)], ans.values)}
	return out


# ── Means of groups ──────────────────────────────────────────

static func group_steps(s: Dictionary, g: Dictionary) -> Array:
	var parts: PackedStringArray = []
	var sums: Array = []
	for i in s.sizes.size():
		var t: Q = s.means[i].mul(Q.new(s.sizes[i]))
		parts.append("%d × %s = %s" % [s.sizes[i], D(s.means[i]), D(t)])
		sums.append(t)
	return ["Each group's total is its size times its mean: %s." % "; ".join(parts), "All together: %s = %s%s" % [plus(sums), D(s.total), g.unit]]


func u_whole_mean_from_groups(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var g: Dictionary = GROUPS[s.ctx]
	var ans := num_ans(s, "mean = ", s.whole)
	var out := {"answer": ans, "table": null}
	var count: int = s.sizes.size()
	if rep == "table":
		out.lines = ["The table shows the number of %s and the mean for each %s." % [g.things, String(g.head).to_lower()]]
		out.table = {"rows": group_rows(g, s)}
	else:
		out.lines = [group_line(g, s.sizes[0], g.names[0], s.means[0]), group_line(g, s.sizes[1], g.names[1], s.means[1])]
	out.asked = to_sf(ans, "Find the mean %s by all %s %s" % [g.what, D(s.n), g.things])
	var flat := total(s.means).div(Q.new(count))
	out.wrongs = wr(ans, flat, R_AVERAGE)
	out.generic = gen(ans, nudges(s.whole) + [s.total.div(Q.new(count)), s.means[0]])
	var shown: String = D(s.whole) if ans.show == "dec" else W(s.whole)
	out.methods = {"total-from-mean": method(group_steps(s, g) + ["There are %s = %s %s: %s ÷ %s = %s" % [" + ".join(s.sizes.map(func(n): return str(n))), D(s.n), g.things, D(s.total), D(s.n), shown],
		final_step(ans)], ans.values)}
	return out


func u_whole_total_from_groups(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var g: Dictionary = GROUPS[s.ctx]
	var ans := exact_ans("total = ", s.total)
	var out := {"lines": ["The table shows the number of %s and the mean for each %s." % [g.things, String(g.head).to_lower()]],
		"table": {"rows": group_rows(g, s)}, "answer": ans, "asked": "Find the %s by all %s %s." % [g.all, D(s.n), g.things]}
	var flat := total(s.means).div(Q.new(s.sizes.size()))
	out.wrongs = wr(ans, flat.mul(s.n), R_AVERAGE)
	out.generic = gen(ans, [s.total.add(Q.new(10)), s.total.sub(Q.new(10)), total(s.means).mul(s.n), s.total.div(s.n)])
	out.methods = {"total-from-mean": method(group_steps(s, g) + [final_step(ans)], ans.values)}
	return out


func u_group_mean_from_whole(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var g: Dictionary = GROUPS[s.ctx]
	var n1: int = s.sizes[0]
	var n2: int = s.sizes[1]
	var ans := exact_ans("mean = ", s.means[1])
	var out := {"lines": ["%s %s %s %s%s." % [D(s.n), g.things, g.verb, D(s.whole), g.tail], "Of these, %s" % group_line(g, n1, g.names[0], s.means[0])],
		"table": null, "answer": ans, "asked": "Find the mean %s by the other %d %s." % [g.what, n2, g.things]}
	var t: Q = s.whole.mul(s.n)
	var t1: Q = s.means[0].mul(Q.new(n1))
	var rest := t.sub(t1)
	out.wrongs = wr(ans, s.whole.mul(Q.new(2)).sub(s.means[0]), R_AVERAGE) + wr(ans, rest.div(s.n), R_WHOLE_SIZE)
	out.generic = gen(ans, nudges(s.means[1]) + [s.whole])
	out.methods = {"total-from-mean": method(["The whole group's total is %s × %s = %s." % [D(s.whole), D(s.n), D(t)],
		"The %d known %s make %d × %s = %s." % [n1, g.things, n1, D(s.means[0]), D(t1)],
		"The other %d make %s − %s = %s, so their mean is %s ÷ %d = %s" % [n2, D(t), D(t1), D(rest), D(rest), n2, D(s.means[1])],
		final_step(ans)], ans.values)}
	return out
