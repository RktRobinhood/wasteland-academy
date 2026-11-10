class_name ConstantChangeViews
extends ExtensionViews
## The views on the `constant-change` situation: one builder per unknown of t4-constant-changes
## (FAL-754). A data set's summary statistics go through y = x + b, y = ax or y = ax + b, told as
## an equation ("equation"), a story ("words"), a list of the data ("terms") or a box plot to scale
## (PlotView's `box`, "graph"). Every question is Paper 1, so every number is exact.
##
## Each method of the map is worked in full: the rules (a measure of centre takes the whole change,
## a measure of spread only the factor, the variance its square), the picture of the histogram or
## box plot sliding and stretching, and the change tried on 1, 2, 3 (or on the list itself).
##
## `given` is the situation for the export. The checker reads the numbers back from the lines and
## the figure; it takes only the story's index from `given`.

const CC := "SL4.3.constant-changes#"
const R_SD_ADD := CC + "0"
const R_VAR_K := CC + "1"
const R_IQR_ADD := CC + "2"
const R_RANGE_ADD := CC + "3"
const R_VAR_ADD := CC + "4"
const R_CENTRE_KEPT := CC + "5"
const R_A_TIMES_B := CC + "6"
const R_NO_B := CC + "7"
const R_SPREAD_KEPT := CC + "8"
const R_SPREAD_SQ := CC + "9"
const R_ORDER := CC + "10"
const R_AGAIN := CC + "11"
const R_MEAN_GAP := CC + "12"
const R_MEAN_RATIO := CC + "13"
const R_SWAP := CC + "14"

const RULES := "shift-stretch-rules"
const PICTURE := "picture-the-histogram"
const TINY := "tiny-example"

const UNKNOWNS := ["add-mean-sd", "add-mean-variance", "add-centre-spread", "multiply-mean", "multiply-variance", "multiply-centre-spread",
	"linear-mean-iqr", "linear-sd-variance", "linear-centre-spread", "original-mean-sd", "original-variance", "original-centre-spread",
	"find-a-and-b", "factor-from-variance", "effect-statement"]

const ARTICLE := {"mean": "a", "median": "a", "mode": "a", "lower quartile": "a", "upper quartile": "an", "standard deviation": "a",
	"variance": "a", "interquartile range": "an", "range": "a"}


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## Every part in the bank is Paper 1, and every number here is exact.
func papers(unknown: String, _rep: String, _angle_id: String) -> Array:
	return [1] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = ConstantChangeSituation.export(s)
	# Only three wrong options fit, so each tag gets its turn.
	out.wrongs = rng.shuffled(out.wrongs)
	said_once(out.methods, out.answer)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func story(s: Dictionary) -> Dictionary:
	return ConstantChangeSituation.STORIES[s.ctx]


static func cap(t: String) -> String:
	return t.left(1).to_upper() + t.substr(1)


static func is_location(name: String) -> bool:
	return name in ConstantChangeSituation.LOCATION


## A value with the story's unit: "24.5 kg", "18°C", or the number alone. A variance has none.
static func U(s: Dictionary, v: Q, name: String, after: bool) -> String:
	if s.ctx < 0 or name == "variance":
		return D(v)
	var u: String = story(s).unit2 if after else story(s).unit
	if u == "":
		return D(v)
	if v.eq(Q.new(1)) and u.ends_with("s"):
		u = u.trim_suffix("s")
	return D(v) + ("" if u.begins_with("°") else " ") + u


## "a mean of 24.5 kg and a standard deviation of 3 kg", or "mean 12 and standard deviation 3".
static func stat_list(s: Dictionary, names: Array, after: bool) -> String:
	var side: Dictionary = s.new if after else s.old
	var bits: Array = []
	for name in names:
		if s.ctx >= 0:
			bits.append("%s %s of %s" % [ARTICLE[name], name, U(s, side[name], name, after)])
		else:
			bits.append("%s %s" % [name, D(side[name])])
	return and_join(bits)


static func and_join(bits: Array) -> String:
	if bits.size() == 1:
		return bits[0]
	return ", ".join(bits.slice(0, bits.size() - 1)) + " and " + bits[bits.size() - 1]


## "2x + 5", "x − 4", "3x", "ax + b".
static func lin_text(a: Variant, b: Variant, x: String = "x") -> String:
	var head: String = x if (a is Q and a.eq(Q.new(1))) else ((a if a is String else D(a)) + x)
	if b is String:
		return "%s + %s" % [head, b]
	if b.is_zero():
		return head
	return "%s %s %s" % [head, "+" if b.sign() > 0 else "−", D(b.abs_q())]


## The sentence that makes the change: the story's, or an equation.
static func change_line(s: Dictionary, letters: Array = []) -> String:
	if s.ctx >= 0:
		var st: Dictionary = story(s)
		var a: String = letters[0] if not letters.is_empty() else D(s.a)
		var b: String = letters[1] if letters.size() > 1 else D(s.b.abs_q())
		return st.change.format({"a": a, "b": b})
	if not letters.is_empty():
		var shape := "%sx" % letters[0] if letters.size() == 1 else "%sx + %s" % letters
		return "Each value x is changed to y = %s, where %s > 0." % [shape, letters[0]]
	return "Each value x is changed to y = %s." % lin_text(s.a, s.b) if not s.back else "Each value x of a data set is changed to y = %s." % lin_text(s.a, s.b)


## The data described before or after the change.
static func target(s: Dictionary, after: bool) -> String:
	if s.ctx < 0:
		return "the new values" if after else "the original values"
	return story(s).new if after else story(s).what


## Where the question asks: the new data forwards, the original backwards.
static func asked_of(s: Dictionary) -> String:
	if s.ctx < 0:
		return "the original values" if s.back else "the new values"
	return story(s).old if s.back else story(s).new


static func ask_text(s: Dictionary) -> String:
	var verb := "Write down" if s.op == "add" and not s.back else "Find"
	var names: Array = s.asked.map(func(n): return "the " + n)
	return "%s %s of %s." % [verb, " and ".join(names), asked_of(s)]


## The statistics told, and the change: forwards the data then the change, backwards the change then
## the new data.
static func stat_lines(s: Dictionary) -> Array:
	if s.ctx >= 0:
		var told := "%s have %s." % [cap(target(s, s.back)), stat_list(s, s.shown, s.back)]
		return [change_line(s), told] if s.back else [told, change_line(s)]
	if s.back:
		return [change_line(s), "The new values have %s." % stat_list(s, s.shown, true)]
	return ["A data set has %s." % stat_list(s, s.shown, false), change_line(s)]


# ── The arithmetic of one statistic ──────────────────────────

static func Pa(v: Q) -> String:
	return D(v)


## "2 × 12 + 5 = 29", "12 − 4 = 8", "3 × 12 = 36"; a spread "2 × 3 = 6"; a variance
## "2² × 9 = 4 × 9 = 36". "" where the statistic doesn't change.
static func calc_fwd(name: String, v: Q, a: Q, b: Q) -> String:
	var r := ConstantChangeSituation.forward(name, v, a, b)
	var one := a.eq(Q.new(1))
	if is_location(name):
		var head := D(v) if one else "%s × %s" % [D(a), D(v)]
		if b.is_zero():
			return "%s = %s" % [head, D(r)]
		return "%s %s %s = %s" % [head, "+" if b.sign() > 0 else "−", D(b.abs_q()), D(r)]
	if one:
		return ""
	if name == "variance":
		return "%s² × %s = %s × %s = %s" % [D(a), D(v), D(a.sq()), D(v), D(r)]
	return "%s × %s = %s" % [D(a), D(v), D(r)]


## The way back: "(29 − 5) ÷ 2 = 12", "17 − 5 = 12", "36 ÷ 3 = 12"; a variance "36 ÷ 2² = 36 ÷ 4 = 9".
static func calc_back(name: String, v: Q, a: Q, b: Q) -> String:
	var r := ConstantChangeSituation.backward(name, v, a, b)
	var one := a.eq(Q.new(1))
	if is_location(name):
		var off := "" if b.is_zero() else "%s %s %s" % [D(v), "−" if b.sign() > 0 else "+", D(b.abs_q())]
		if one:
			return "%s = %s" % [off, D(r)]
		if b.is_zero():
			return "%s ÷ %s = %s" % [D(v), D(a), D(r)]
		return "(%s) ÷ %s = %s" % [off, D(a), D(r)]
	if one:
		return ""
	if name == "variance":
		return "%s ÷ %s² = %s ÷ %s = %s" % [D(v), D(a), D(v), D(a.sq()), D(r)]
	return "%s ÷ %s = %s" % [D(v), D(a), D(r)]


## One statistic's line in the rules: "the mean: 2 × 12 + 5 = 29", or "the range stays 14".
static func stat_step(s: Dictionary, name: String) -> String:
	var v: Q = s.new[name] if s.back else s.old[name]
	var c := calc_back(name, v, s.a, s.b) if s.back else calc_fwd(name, v, s.a, s.b)
	var which := "original" if s.back else "new"
	if c == "":
		return "the %s stays %s" % [name, D(v)]
	return "the %s %s is %s" % [which, name, c]


# ── The answer and its slips ─────────────────────────────────

static func answer_values(s: Dictionary) -> Array:
	var side: Dictionary = s.old if s.back else s.new
	return s.asked.map(func(n): return side[n])


static func make_answer(s: Dictionary) -> Dictionary:
	var vals := answer_values(s)
	var ans: Dictionary
	if vals.size() == 1:
		ans = Answer.make("number", {"v": vals[0]}, {}, s.asked[0] + " = ")
	else:
		ans = Answer.make("named", {"v0": vals[0], "v1": vals[1]}, {"names": s.asked})
	ans.show = "dec"
	ans.exact = true
	return ans


## The misconception that adds the constant to this measure of spread.
static func spread_ref(name: String) -> String:
	return {"standard deviation": R_SD_ADD, "interquartile range": R_IQR_ADD, "range": R_RANGE_ADD, "variance": R_VAR_ADD}[name]


## [value, ref] for each slip on one statistic, worked from what the question tells.
static func slips(s: Dictionary, name: String) -> Array:
	var a: Q = s.a
	var b: Q = s.b
	var out: Array = []
	if not s.back:
		var v: Q = s.old[name]
		if is_location(name):
			if s.op == "lin":
				out.append([a.mul(v.add(b)), R_A_TIMES_B])
				out.append([a.mul(v), R_NO_B])
			else:
				out.append([v, R_CENTRE_KEPT])
		elif name == "variance":
			match s.op:
				"add":
					out.append([v.add(b), R_VAR_ADD])
				"mul":
					out.append([a.mul(v), R_VAR_K])
					out.append([v, R_SPREAD_KEPT])
				"lin":
					out.append([a.mul(v), R_VAR_K])
					out.append([a.sq().mul(v).add(b), R_VAR_ADD])
		else:
			match s.op:
				"add":
					out.append([v.add(b), spread_ref(name)])
				"mul":
					out.append([v, R_SPREAD_KEPT])
					out.append([a.sq().mul(v), R_SPREAD_SQ])
				"lin":
					out.append([a.mul(v).add(b), spread_ref(name)])
					out.append([a.sq().mul(v), R_SPREAD_SQ])
		return out
	var w: Q = s.new[name]
	if is_location(name):
		match s.op:
			"add":
				out.append([w.add(b), R_AGAIN])
				out.append([w, R_CENTRE_KEPT])
			"mul":
				out.append([a.mul(w), R_AGAIN])
				out.append([w, R_CENTRE_KEPT])
			"lin":
				out.append([w.div(a).sub(b), R_ORDER])
				out.append([a.mul(w).add(b), R_AGAIN])
	elif name == "variance":
		match s.op:
			"mul":
				out.append([w.div(a), R_VAR_K])
				out.append([a.sq().mul(w), R_AGAIN])
			"lin":
				out.append([w.div(a), R_VAR_K])
				out.append([w.sub(b).div(a.sq()), R_VAR_ADD])
	else:
		match s.op:
			"add":
				out.append([w.sub(b), spread_ref(name)])
			"mul":
				out.append([a.mul(w), R_AGAIN])
				out.append([w, R_SPREAD_KEPT])
			"lin":
				out.append([w.sub(b).div(a), spread_ref(name)])
				out.append([a.mul(w), R_AGAIN])
	return out


## A value an option can show: positive, and ending within two decimal places.
static func fits(v: Q) -> bool:
	return v.sign() > 0 and ConstantChangeSituation.ends(v, 2)


## The wrong options: one slip on one statistic with the other right, and for a change that adds,
## the swap that keeps the centre and moves the spread.
static func wrong_options(s: Dictionary) -> Array:
	var right := answer_values(s)
	var out: Array = []
	for i in right.size():
		for sl in slips(s, s.asked[i]):
			var v: Q = sl[0]
			if not fits(v) or v.eq(right[i]):
				continue
			var vals := right.duplicate()
			vals[i] = v
			out.append(wrong(pack(vals), sl[1]))
	if s.op == "add" and right.size() == 2 and is_location(s.asked[0]) and not is_location(s.asked[1]):
		var from: Dictionary = s.new if s.back else s.old
		var spread: Q = from[s.asked[1]].sub(s.b) if s.back else from[s.asked[1]].add(s.b)
		if fits(spread):
			out.append(wrong(pack([from[s.asked[0]], spread]), R_SWAP))
	return out


static func pack(vals: Array) -> Dictionary:
	return {"v": vals[0]} if vals.size() == 1 else {"v0": vals[0], "v1": vals[1]}


## Fillers: each value nudged, kept positive.
static func fillers(s: Dictionary) -> Array:
	var right := answer_values(s)
	var out: Array = []
	for d in [Q.new(1), Q.new(-1), Q.new(2), Q.new(1, 2)]:
		for i in right.size():
			var vals := right.duplicate()
			vals[i] = right[i].add(d)
			if fits(vals[i]):
				out.append(pack(vals))
	return out


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


# ── The three methods ────────────────────────────────────────

## The rule for this change, in words.
static func rule_line(s: Dictionary) -> String:
	var a := D(s.a)
	var b := D(s.b.abs_q())
	match s.op:
		"add":
			if s.b.sign() > 0:
				return "Adding %s to every value moves every measure of centre up by %s and leaves every measure of spread as it was." % [b, b]
			return "Taking %s off every value moves every measure of centre down by %s and leaves every measure of spread as it was." % [b, b]
		"mul":
			return "Multiplying every value by %s multiplies every measure of centre and of spread by %s, and the variance by %s² = %s." % [a, a, a, D(s.a.sq())]
	return "Each value x becomes %s: a measure of centre does the same, a measure of spread is only multiplied by %s, and the variance by %s² = %s." \
		% [lin_text(s.a, s.b), a, a, D(s.a.sq())]


## The rule run backwards.
static func undo_line(s: Dictionary) -> String:
	var a := D(s.a)
	var b := D(s.b.abs_q())
	match s.op:
		"add":
			return "Undo the change: %s %s each measure of centre; a measure of spread didn't change, so it is the same." % ["take" if s.b.sign() > 0 else "add", b + (" off" if s.b.sign() > 0 else " to")]
		"mul":
			return "Undo the change: divide each measure of centre and of spread by %s, and the variance by %s² = %s." % [a, a, D(s.a.sq())]
	var first := "take away %s" % b if s.b.sign() > 0 else "add %s back" % b
	return "Undo y = %s in reverse order: %s, then divide by %s. A measure of spread is only divided by %s, and the variance by %s² = %s." \
		% [lin_text(s.a, s.b), first, a, a, a, D(s.a.sq())]


## "the mean is 2 × 12 + 5 = 29 and the standard deviation is 2 × 3 = 6", one statistic a step.
static func stat_steps(s: Dictionary) -> Array:
	return s.asked.map(func(n): return cap(stat_step(s, n)) + ".")


func rules_steps(s: Dictionary, ans: Dictionary, lead: Array) -> Array:
	return lead + [undo_line(s) if s.back else rule_line(s)] + stat_steps(s) + [final_step(ans)]


static func picture_name(s: Dictionary) -> String:
	return "box plot" if s.rep == "graph" else "histogram"


static func move_line(s: Dictionary) -> String:
	var p := picture_name(s)
	var a := D(s.a)
	var b := D(s.b.abs_q())
	var dir := "right" if s.b.sign() > 0 else "left"
	var back_dir := "left" if s.b.sign() > 0 else "right"
	var stretch := "stretches it away from 0 to %s times its width" % a if Q.new(1).lt(s.a) else "squeezes it towards 0 to %s times its width" % a
	if s.back:
		match s.op:
			"add":
				return "Picture the %s of %s and slide it back %s to the %s: its shape and width do not change." % [p, target(s, true), b, back_dir]
			"mul":
				return "Picture the %s of %s and undo the stretch: every point and every width on it is divided by %s." % [p, target(s, true), a]
		return "Picture the %s of %s and move it back: slide it %s to the %s, then divide every point and every width by %s." % [p, target(s, true), b, back_dir, a]
	match s.op:
		"add":
			return "Picture the %s of %s: the change slides it %s to the %s, and its shape and width do not change." % [p, target(s, false), b, dir]
		"mul":
			return "Picture the %s of %s: the change %s, so every point and every width on it is multiplied by %s." % [p, target(s, false), stretch, a]
	return "Picture the %s of %s: multiplying %s, then adding %s slides it %s to the %s without changing its width." \
		% [p, target(s, false), stretch, D(s.b) if s.b.sign() > 0 else "−" + b, b, dir]


static func picture_stat(s: Dictionary, name: String) -> String:
	var v: Q = s.new[name] if s.back else s.old[name]
	var c := calc_back(name, v, s.a, s.b) if s.back else calc_fwd(name, v, s.a, s.b)
	var times := "divided" if s.back else "multiplied"
	if is_location(name):
		return "The %s moves with the picture: %s." % [name, c]
	if c == "":
		return "The width is the same, so the %s is still %s." % [name, D(v)]
	if name == "variance":
		return "The variance is in squared units, so it is %s by %s²: %s." % [times, D(s.a), c]
	return "Widths are %s by %s, so the %s is %s." % [times, D(s.a), name, c]


func picture_steps(s: Dictionary, ans: Dictionary, lead: Array) -> Array:
	return lead + [move_line(s)] + s.asked.map(func(n): return picture_stat(s, n)) + [final_step(ans)]


## 1, 2, 3 after the change.
static func tiny_values(s: Dictionary) -> Array:
	return [1, 2, 3].map(func(i): return ConstantChangeSituation.forward("mean", Q.new(i), s.a, s.b))


static func tiny_lines(s: Dictionary) -> Array:
	var t := tiny_values(s)
	var a := D(s.a)
	var out: Array = ["Try the change on 1, 2, 3: they become %s, %s and %s." % [D(t[0]), D(t[1]), D(t[2])]]
	var mean_c := calc_fwd("mean", Q.new(2), s.a, s.b)
	var range_c := calc_fwd("range", Q.new(2), s.a, s.b)
	match s.op:
		"add":
			out.append("The mean goes from 2 to %s, but the gaps between the values are the same, so the range is still 2: the centre moves and the spread doesn't." % mean_c)
		"mul":
			out.append("The mean goes from 2 to %s and the range from 2 to %s: both are multiplied by %s." % [mean_c, range_c, a])
		"lin":
			out.append("The mean goes from 2 to %s, but the range only from 2 to %s: the centre takes the whole change, the spread only the factor." % [mean_c, range_c])
	if "variance" in s.asked:
		var nv := Q.new(2, 3).mul(s.a.sq())
		if s.op == "add":
			out.append("The variance of 1, 2, 3 is 2/3, and the new values have the same gaps, so their variance is 2/3 too.")
		else:
			out.append("The variance of 1, 2, 3 is 2/3, and of the new values %s, which is %s² = %s times as much." % [Fmt.num(nv), a, D(s.a.sq())])
	return out


func tiny_steps(s: Dictionary, ans: Dictionary, lead: Array) -> Array:
	var how: Array = s.asked.map(func(n): return stat_step(s, n))
	return tiny_lines(s) + lead + ["So here " + and_join(how) + "." if not s.back else "Undo it here in the same way: " + and_join(how) + "."] + [final_step(ans)]


## The three workings of a question on statistics, each after `lead` (what the figure or list gives).
func stat_methods(s: Dictionary, ans: Dictionary, lead: Array = []) -> Dictionary:
	return {RULES: method(rules_steps(s, ans, lead), ans.values), PICTURE: method(picture_steps(s, ans, lead), ans.values),
		TINY: method(tiny_steps(s, ans, lead), ans.values)}


# ── The questions on statistics ──────────────────────────────

func stats_question(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := make_answer(s)
	var out := {"answer": ans, "asked": ask_text(s), "table": null}
	var lead: Array = []
	match rep:
		"graph":
			out.lines = graph_lines(s)
			out.graph = figure(s)
			lead = [read_line(s)]
		"terms":
			out.lines = ["The values of a data set are %s." % and_join(s.xs.map(func(x): return D(x))), change_line(s)]
		_:
			out.lines = stat_lines(s)
	out.wrongs = wrong_options(s)
	out.generic = fillers(s)
	if rep == "terms":
		out.methods = list_methods(s, ans)
	else:
		out.methods = stat_methods(s, ans, lead)
	return out


func u_add_mean_sd(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return stats_question(rep, s, rng)


func u_add_mean_variance(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return stats_question(rep, s, rng)


func u_add_centre_spread(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return stats_question(rep, s, rng)


func u_multiply_mean(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := stats_question(rep, s, rng)
	out.generic = [{"v": s.old.mean.add(s.a)}, {"v": s.old.mean.mul(s.a.sq())}].filter(func(g): return fits(g.v)) + out.generic
	return out


func u_multiply_variance(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := stats_question(rep, s, rng)
	out.generic = [{"v": s.old.variance.add(s.a)}].filter(func(g): return fits(g.v)) + out.generic
	return out


func u_multiply_centre_spread(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return stats_question(rep, s, rng)


func u_linear_mean_iqr(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return stats_question(rep, s, rng)


func u_linear_sd_variance(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return stats_question(rep, s, rng)


func u_linear_centre_spread(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return stats_question(rep, s, rng)


func u_original_mean_sd(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return stats_question(rep, s, rng)


func u_original_variance(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return stats_question(rep, s, rng)


func u_original_centre_spread(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return stats_question(rep, s, rng)


# ── The box plot ─────────────────────────────────────────────

static func figure(s: Dictionary) -> Dictionary:
	var f: Dictionary = s.box
	var row := {"name": "", "min": D(f.min), "q1": D(f.q1), "med": D(f.med), "q3": D(f.q3), "max": D(f.max), "out": []}
	var st := story(s)
	return {"kind": "box", "x0": D(s.x0), "x1": D(s.x1), "tick": D(s.tick), "every": ConstantChangeSituation.EVERY,
		"name": st.axis2 if s.back else st.axis, "boxes": [row]}


static func graph_lines(s: Dictionary) -> Array:
	var shows := "The box plot shows %s." % target(s, s.back)
	return [change_line(s), shows] if s.back else [shows, change_line(s)]


## What the box plot gives: "From the box plot, the median is 24 and the IQR is 30 − 18 = 12."
static func read_line(s: Dictionary) -> String:
	var f: Dictionary = s.box
	var bits: Array = []
	for name in s.asked:
		match name:
			"median":
				bits.append("the median is %s" % D(f.med))
			"lower quartile":
				bits.append("the lower quartile is %s" % D(f.q1))
			"upper quartile":
				bits.append("the upper quartile is %s" % D(f.q3))
			"interquartile range":
				bits.append("the interquartile range is %s − %s = %s" % [D(f.q3), D(f.q1), D(f.q3.sub(f.q1))])
			"range":
				bits.append("the range is %s − %s = %s" % [D(f.max), D(f.min), D(f.max.sub(f.min))])
	return "From the box plot, " + and_join(bits) + "."


# ── A list of data ───────────────────────────────────────────

static func L(xs: Array) -> String:
	return ", ".join(xs.map(func(x): return D(x)))


static func half_of(xs: Array, lower: bool) -> Array:
	var n := xs.size()
	var h := n / 2
	return xs.slice(0, h) if lower else xs.slice(h + n % 2, n)


## How one statistic of a list is found: "the median is the middle value, 9".
static func list_stat(xs: Array, name: String, st: Dictionary) -> String:
	var n := xs.size()
	match name:
		"mean":
			var sum := Q.new(0)
			for x: Q in xs:
				sum = sum.add(x)
			return "the mean is %s ÷ %d = %s" % [D(sum), n, D(st.mean)]
		"median":
			if n % 2 == 1:
				return "the median is %s, the middle value" % D(st.median)
			return "the median is %s, halfway between %s and %s" % [D(st.median), D(xs[n / 2 - 1]), D(xs[n / 2])]
		"mode":
			return "the mode is %s, the value that appears twice" % D(st.mode)
		"lower quartile":
			return "the lower quartile is %s, the median of %s" % [D(st["lower quartile"]), and_join(half_of(xs, true).map(func(x): return D(x)))]
		"upper quartile":
			return "the upper quartile is %s, the median of %s" % [D(st["upper quartile"]), and_join(half_of(xs, false).map(func(x): return D(x)))]
		"interquartile range":
			return "the interquartile range is %s − %s = %s" % [D(st["upper quartile"]), D(st["lower quartile"]), D(st["interquartile range"])]
	return "the range is %s − %s = %s" % [D(xs[n - 1]), D(xs[0]), D(st.range)]


## The rules and the picture work from the list's own statistics; the tiny example is the list itself,
## every value changed.
func list_methods(s: Dictionary, ans: Dictionary) -> Dictionary:
	var lead := ["For the data, " + and_join(s.asked.map(func(n): return list_stat(s.xs, n, s.old))) + "."]
	var tiny := ["Change every value: %s become %s." % [L(s.xs), L(s.ys)],
		"For the new values, " + and_join(s.asked.map(func(n): return list_stat(s.ys, n, s.new))) + ".", final_step(ans)]
	return {RULES: method(rules_steps(s, ans, lead), ans.values), PICTURE: method(picture_steps(s, ans, lead), ans.values), TINY: method(tiny, ans.values)}


# ── Finding the change ───────────────────────────────────────

func u_find_a_and_b(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var spread := "variance" if s.given_var else "standard deviation"
	var names := ["mean", spread]
	var m: Q = s.old.mean
	var big_m: Q = s.new.mean
	var sd: Q = s.old["standard deviation"]
	var big_s: Q = s.new["standard deviation"]
	var ans := Answer.make("named", {"v0": s.a, "v1": s.b}, {"names": ["a", "b"]})
	ans.show = "dec"
	ans.exact = true
	var out := {"answer": ans, "table": null, "asked": "Find the value of a and the value of b."}
	if s.ctx >= 0:
		out.lines = ["%s have %s." % [cap(target(s, false)), stat_list(s, names, false)], change_line(s, ["a", "b"]) + " Here a and b are constants, and a > 0.",
			"%s have %s." % [cap(target(s, true)), stat_list(s, names, true)]]
	else:
		out.lines = ["A data set has %s." % stat_list(s, names, false), change_line(s, ["a", "b"]), "The new values have %s." % stat_list(s, names, true)]
	var wrongs: Array = []
	wrongs.append(wrong({"v0": s.a, "v1": big_m.sub(m)}, R_MEAN_GAP))
	var ratio := big_m.div(m)
	if fits(ratio) and not ratio.eq(s.a):
		wrongs.append(wrong({"v0": ratio, "v1": Q.new(0)}, R_MEAN_RATIO))
	if s.given_var:
		var k: Q = s.new.variance.div(s.old.variance)
		wrongs.append(wrong({"v0": k, "v1": big_m.sub(k.mul(m))}, R_VAR_K))
	out.wrongs = wrongs.filter(func(w): return ConstantChangeSituation.ends(w.values.v1, 2) and ConstantChangeSituation.ends(w.values.v0, 2))
	out.generic = [{"v0": s.a.add(1), "v1": s.b}, {"v0": s.a, "v1": s.b.neg()}, {"v0": s.a, "v1": s.b.add(1)}]
	var am: Q = s.a.mul(m)
	var first := "Only the factor changes the standard deviation, so a = %s ÷ %s = %s." % [D(big_s), D(sd), D(s.a)]
	if s.given_var:
		first = "The variance is multiplied by a², so a² = %s ÷ %s = %s, and a > 0 gives a = %s." % [D(s.new.variance), D(s.old.variance), D(s.a.sq()), D(s.a)]
	var mean_line := "The mean takes the whole change: %s = %s × %s + b = %s + b." % [D(big_m), D(s.a), D(m), D(am)]
	var b_line := "So b = %s − %s = %s." % [D(big_m), D(am), D(s.b)]
	var see_sd := "" if not s.given_var else " (the standard deviation goes from √%s = %s to √%s = %s)" % [D(s.old.variance), D(sd), D(s.new.variance), D(big_s)]
	out.methods = {RULES: method([first, mean_line, b_line, final_step(ans)], ans.values),
		PICTURE: method(["The width of the histogram%s grew by a factor of %s ÷ %s = %s, so the stretch is a = %s." % [see_sd, D(big_s), D(sd), D(s.a), D(s.a)],
			"Stretching alone puts the mean at %s × %s = %s; it sits at %s, so the histogram then slid by %s − %s = %s." % [D(s.a), D(m), D(am), D(big_m), D(big_m), D(am), D(s.b)],
			final_step(ans)], ans.values),
		TINY: method(["Try y = ax + b on 1, 2, 3: the range 2 becomes 2a and the mean 2 becomes 2a + b, so a comes from the spread alone and b from the mean after that.",
			first, b_line.trim_prefix("So ").replace("b = ", "Then b = "), final_step(ans)], ans.values)}
	return out


func u_factor_from_variance(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v: Q = s.old.variance
	var big_v: Q = s.new.variance
	var k2 := big_v.div(v)
	var ans := Answer.make("number", {"v": s.a}, {}, "k = ")
	ans.show = "dec"
	ans.exact = true
	var out := {"answer": ans, "table": null, "asked": "Find the value of k."}
	if s.ctx >= 0:
		out.lines = ["%s have a variance of %s." % [cap(target(s, false)), D(v)], change_line(s, ["k"]) + " Here k is a positive constant.",
			"%s have a variance of %s." % [cap(target(s, true)), D(big_v)]]
	else:
		out.lines = ["A data set has variance %s." % D(v), change_line(s, ["k"]), "The new values have variance %s." % D(big_v)]
	out.wrongs = [wrong({"v": k2}, R_VAR_K)].filter(func(w): return fits(w.values.v) and not w.values.v.eq(s.a))
	out.generic = [{"v": s.a.add(1)}, {"v": s.a.mul(2)}, {"v": s.a.add(Q.new(1, 2))}]
	var root := "k > 0, so k = √%s = %s." % [D(k2), D(s.a)]
	out.methods = {RULES: method(["Multiplying every value by k multiplies the variance by k², so k² = %s ÷ %s = %s." % [D(big_v), D(v), D(k2)], root, final_step(ans)], ans.values),
		PICTURE: method(["Stretching the histogram by a factor of k makes every width, and so the standard deviation, k times as big.",
			"The variance is the square of the standard deviation, so it grows by k² = %s ÷ %s = %s." % [D(big_v), D(v), D(k2)], root, final_step(ans)], ans.values),
		TINY: method(["Try multiplying 1, 2, 3 by 2: they become 2, 4, 6, and the variance goes from 2/3 to 8/3, which is 4 = 2² times as much.",
			"So multiplying by k multiplies the variance by k²: here k² = %s ÷ %s = %s." % [D(big_v), D(v), D(k2)], root, final_step(ans)], ans.values)}
	return out


# ── Which statement is true ──────────────────────────────────

static func claim(tag: String, text: String) -> Dictionary:
	return {"form": tag, "vals": [], "text": text}


## The four statements about one change: the true one and the three slips, by tag.
static func statements(s: Dictionary) -> Dictionary:
	var c: String = s.asked[0]
	var sp: String = s.asked[1]
	var out := {}
	if s.op == "add":
		var by := "goes %s by %s" % ["up" if s.b.sign() > 0 else "down", U(s, s.b.abs_q(), c, false)]
		var both := "go %s by %s" % ["up" if s.b.sign() > 0 else "down", U(s, s.b.abs_q(), c, false)]
		out.right = "The %s %s, and the %s stays the same." % [c, by, sp]
		out[spread_ref(sp)] = "The %s and the %s both %s." % [c, sp, both]
		out[R_SWAP] = "The %s stays the same, and the %s %s." % [c, sp, by]
		out[R_CENTRE_KEPT] = "The %s and the %s both stay the same." % [c, sp]
		return out
	var a := D(s.a)
	var a2 := D(s.a.sq())
	if sp == "variance":
		out.right = "The %s is multiplied by %s, and the variance by %s." % [c, a, a2]
		out[R_VAR_K] = "The %s and the variance are both multiplied by %s." % [c, a]
		out[R_SPREAD_KEPT] = "The %s is multiplied by %s, and the variance stays the same." % [c, a]
		out[R_CENTRE_KEPT] = "The %s stays the same, and the variance is multiplied by %s." % [c, a2]
		return out
	out.right = "The %s and the %s are both multiplied by %s." % [c, sp, a]
	out[R_SPREAD_SQ] = "The %s is multiplied by %s, and the %s by %s." % [c, a, sp, a2]
	out[R_SPREAD_KEPT] = "The %s is multiplied by %s, and the %s stays the same." % [c, a, sp]
	out[R_CENTRE_KEPT] = "The %s stays the same, and the %s is multiplied by %s." % [c, sp, a]
	return out


func u_effect_statement(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var st := statements(s)
	var ans := Answer.make("claim", claim("right", st.right))
	var out := {"answer": ans, "table": null, "lines": [change_line(s)], "asked": "Which statement about %s is true?" % target(s, true)}
	out.wrongs = []
	for ref in st:
		if ref != "right":
			out.wrongs.append(wrong(claim(ref, st[ref]), ref))
	out.generic = []
	var c: String = s.asked[0]
	var sp: String = s.asked[1]
	var centre := "The %s takes the whole change" % c
	var spread_says := "the %s stays the same" % sp if s.op == "add" else ("the variance is multiplied by %s² = %s" % [D(s.a), D(s.a.sq())] if sp == "variance" else "the %s is multiplied by %s too" % [sp, D(s.a)])
	var rule := "Adding a constant moves every measure of centre by it and leaves every measure of spread alone." if s.op == "add" \
		else "Multiplying by a constant multiplies every measure of centre and of spread by it, and the variance by its square."
	out.methods = {RULES: method([rule, "%s, and %s." % [centre, spread_says], "So: " + st.right], ans.values),
		PICTURE: method([move_line(s), "%s, and %s." % [centre, spread_says], "So: " + st.right], ans.values),
		TINY: method(tiny_lines(s) + ["So: " + st.right], ans.values)}
	return out
