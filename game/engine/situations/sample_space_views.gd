class_name SampleSpaceViews
extends ExtensionViews
## The views on the `sample-space` situation: one builder per unknown of t4-sample-space (FAL-752).
## Fair grids are exact fractions on Paper 1 and 3 s.f. on Paper 2. One biased object rolled twice
## is decimals, exact on Paper 1. The face and win problems are Paper 1, as the bank's are.
##
## Representations: "table" (the grid of outcomes with its heads, or a table of probabilities or
## of a sum's distribution), "diagram" (the two objects drawn, PlotView's `spinners`) and "words"
## (the same in sentences).
##
## `given` holds the situation; the SymPy checker takes only the story's place in it and reads
## every number back from what the student sees.

const G := "SL4.6.sample-space-grid#"
const R_ONE_PAIR := G + "0"
const R_KINDS := G + "1"
## The type's own slips, by their place in its misconceptions list.
const OWN := "t4-sample-space#"
const R_BOUNDARY := OWN + "2"
const R_WRONG_RULE := OWN + "3"
const R_NEXT_CELL := OWN + "4"
const R_ADD_FACES := OWN + "5"
const R_SCORES_NOT_CELLS := OWN + "6"
const R_THE_EVENT := OWN + "7"
const R_TIES := OWN + "8"
const R_HALF := OWN + "9"
const R_SWAPPED := OWN + "10"
const R_EQUAL_CELLS := OWN + "11"
const R_ONE_ROLL := OWN + "12"
const R_LARGEST := OWN + "13"
const R_SMALL_FACE := OWN + "14"
const R_NEXT_SUM := OWN + "15"
const R_OTHER_LETTER := OWN + "16"
const R_FAIR := OWN + "17"
const R_OTHER_DIE := OWN + "18"
const R_ALL_Q := OWN + "19"

const WEIGHTS_TITLE := "Fill a grid of probabilities and add the cells"
const LETTER_TITLE := "Fill the grid with the letter left in"

const UNKNOWNS := ["fill-cell", "total-outcomes", "count-event", "p-score", "p-at-least", "p-complement", "p-property", "p-compare",
	"p-mirror-score", "p-mirror-at-least", "p-rule-points", "weighted-sum", "weighted-target", "face-from-largest", "face-from-grid",
	"weight-from-win", "expected-from-win"]
## The unknowns with Paper 2 numbers: the rest are short or exact, as the bank's Paper 1 parts are.
const BOTH_PAPERS := ["p-score", "p-at-least", "p-complement", "p-property", "p-compare", "p-rule-points", "weighted-sum", "weighted-target"]

const PROP_TEXT := {"even": "an even number", "odd": "an odd number", "mult3": "a multiple of 3", "mult4": "a multiple of 4",
	"prime": "a prime number", "square": "a square number"}
const REL_TEXT := {"=": "%d", ">=": "at least %d", ">": "greater than %d", "<=": "at most %d", "<": "less than %d"}
const RULE_TEXT := {"sum": "the sum of the two numbers", "product": "the product of the two numbers",
	"difference": "the larger number minus the smaller, or 0 if they match", "max": "the larger of the two numbers, or that number if they match"}
const CORNER := {"sum": "+", "product": "×", "difference": "diff", "max": "max"}


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	if not has(unknown):
		return []
	return [1, 2] if unknown in BOTH_PAPERS else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = SampleSpaceSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func list_of(items: Array) -> String:
	var texts: Array = items.map(func(x): return str(x))
	if texts.size() < 2:
		return "".join(texts)
	return ", ".join(texts.slice(0, texts.size() - 1)) + " and " + texts[-1]


static func plus(xs: Array) -> String:
	return " + ".join(xs.map(func(x): return str(x)))


## What the two objects are called.
static func names(s: Dictionary) -> Array:
	match s.kind:
		"dice":
			return ["first die", "second die"]
		"mixed":
			return ["die", "spinner"]
	return ["first spinner", "second spinner"]


static func shape_of(name: String) -> String:
	return "die" if name.ends_with("die") else "spinner"


## "faces of the die" or "sectors of the first spinner".
static func parts_of(name: String) -> String:
	return ("faces of the " if shape_of(name) == "die" else "sectors of the ") + name


static func opening(s: Dictionary, things: String) -> String:
	return "%s %s." % [SampleSpaceSituation.STORIES[s.ctx], things]


static func fair_things(s: Dictionary) -> String:
	match s.kind:
		"dice":
			return "two fair dice"
		"mixed":
			return "a fair die and a fair spinner"
	return "two fair spinners"


static func face_line(name: String, labels: Array) -> String:
	if shape_of(name) == "die":
		return "The %s has faces labelled %s." % [name, list_of(labels)]
	return "The %s has equal sectors numbered %s." % [name, list_of(labels)]


## A step for a repeated face: every face is its own outcome.
static func repeat_note(s: Dictionary) -> String:
	if SampleSpaceSituation.all_different(s):
		return ""
	return " A number on two faces or sectors makes two separate outcomes."


static func item(name: String, labels: Array, shares: Array = []) -> Dictionary:
	var parts: Array = shares.duplicate()
	if parts.is_empty():
		for l in labels:
			parts.append(1.0 / labels.size())
	return {"name": name.capitalize(), "shape": shape_of(name), "labels": labels.map(func(l): return str(l)), "shares": parts}


static func figure(s: Dictionary) -> Dictionary:
	var n := names(s)
	return {"kind": "spinners", "items": [item(n[0], s.xs), item(n[1], s.ys)]}


## The grid of a score: a row for each face of the first, a column for each of the second.
static func grid(s: Dictionary, corner: String, cell: Callable) -> Dictionary:
	var rows: Array = [[corner, s.ys.map(func(y): return str(y))]]
	for x in s.xs:
		rows.append([str(x), s.ys.map(func(y): return str(cell.call(x, y)))])
	return {"rows": rows}


static func score_grid(s: Dictionary) -> Dictionary:
	return grid(s, CORNER[s.rule], func(a, b): return SampleSpaceSituation.score(s.rule, a, b))


## The question's opening lines and its figure, for a fair pair with a score.
func _fair_lines(rep: String, s: Dictionary, out: Dictionary, show: Dictionary = {}) -> void:
	var n := names(s)
	var lines: Array = [opening(s, fair_things(s))]
	match rep:
		"table":
			lines.append("The table shows every outcome, with a row for each number on the %s and a column for each number on the %s." % n)
			out.table = show if not show.is_empty() else score_grid(s)
		"diagram":
			lines.append("The figure shows the two of them.")
			out.graph = figure(s)
		_:
			lines.append(face_line(n[0], s.xs))
			lines.append(face_line(n[1], s.ys))
	lines.append("The score is %s." % RULE_TEXT[s.rule])
	out.lines = lines


static func event_words(s: Dictionary) -> String:
	match s.event:
		"prop":
			return "the score is %s" % PROP_TEXT[s.prop]
		"higher":
			return "the number on the %s is higher than the number on the %s" % names(s)
	return "the score is " + (REL_TEXT[s.rel] % s.k)


static func sentence(text: String) -> String:
	return text.left(1).to_upper() + text.substr(1)


static func pair(p: Array) -> String:
	return "(%d, %d)" % p


static func pairs_text(pairs: Array) -> String:
	return list_of(pairs.map(func(p): return pair(p)))


## How many cells of each row pass.
static func by_row(s: Dictionary) -> Array:
	var out: Array = []
	for x in s.xs:
		out.append(s.ys.filter(func(y): return SampleSpaceSituation.passes(s, x, y)).size())
	return out


static func prob(s: Dictionary, v: Q, label: String = "probability = ") -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	match s.form:
		"dec":
			ans.show = "dec"
			ans.exact = true
		"sf":
			ans.show = "sf"
		_:
			ans.exact = true
	return ans


static func count_ans(v: int) -> Dictionary:
	var ans := Answer.make("number", {"v": Q.new(v)}, {}, "number of outcomes = ")
	ans.exact = true
	return ans


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## Whether a wrong value can stand as an option beside the answer.
static func fits(s: Dictionary, v: Q) -> bool:
	if v.sign() <= 0 or not v.lt(Q.new(1)):
		return false
	if s.form == "dec":
		var d := v.d
		for f in [2, 5]:
			while d % f == 0:
				d /= f
		return d == 1
	return true


static func wr(s: Dictionary, v: Q, ref: String) -> Array:
	return [wrong({"v": v}, ref)] if fits(s, v) else []


static func near(s: Dictionary, vs: Array) -> Array:
	return vs.filter(func(v): return fits(s, v)).map(func(v): return {"v": v})


## "P = 10/36 = 5/18"
static func ratio(a: int, b: int) -> String:
	var v := Q.new(a, b)
	return "P = %d/%d" % [a, b] if v.d == b else "P = %d/%d = %s" % [a, b, v.text()]


## What every fair probability's wrong options share.
static func fair_wrongs(s: Dictionary, pairs: Array, flip: bool = false) -> Array:
	var h: int = pairs.size()
	var out: Array = []
	var side := func(n: int, d: int) -> Q: return Q.new(d - n, d) if flip else Q.new(n, d)
	if SampleSpaceSituation.all_different(s):
		var one_way := SampleSpaceSituation.merged(pairs)
		if one_way != h:
			out += wr(s, side.call(one_way, s.all), R_ONE_PAIR)
	var scores := SampleSpaceSituation.kinds(s)
	if h < scores:
		out += wr(s, side.call(h, scores), R_KINDS)
	return out


static func fair_near(s: Dictionary, h: int) -> Array:
	return near(s, [Q.new(h + 1, s.all), Q.new(h - 1, s.all), Q.new(h + 2, s.all), Q.new(s.all - h, s.all), Q.new(1, s.all)])


# ── Worked solutions on a fair grid ──────────────────────────

## "The grid has 4 rows of 6 cells: 4 × 6 = 24 equally likely outcomes."
static func grid_size(rep: String, s: Dictionary) -> String:
	var m: int = s.xs.size()
	var n: int = s.ys.size()
	var size := "%d × %d = %d equally likely outcomes." % [m, n, s.all]
	if rep == "table":
		return "The grid has %d rows of %d cells: %s" % [m, n, size] + repeat_note(s)
	return "Draw a grid with a row for each number on the %s and a column for each number on the %s: %s" % (names(s) + [size]) + repeat_note(s)


static func pairs_size(s: Dictionary) -> String:
	return "An outcome is an ordered pair (%s, %s), and there are %d × %d = %d of them." % (names(s) + [s.xs.size(), s.ys.size(), s.all]) + repeat_note(s)


static func row_line(s: Dictionary) -> String:
	return "Row by row, %s in %s = %d cells." % [event_words(s), plus(by_row(s)), SampleSpaceSituation.hits(s).size()]


static func pairs_line(s: Dictionary, pairs: Array) -> String:
	return "%s for %s: %d ordered pairs." % [sentence(event_words(s)), pairs_text(pairs), pairs.size()]


## The two counting routes to a plain P(event).
func _fair_methods(rep: String, s: Dictionary, ans: Dictionary) -> Dictionary:
	var pairs := SampleSpaceSituation.hits(s)
	var p := ratio(pairs.size(), s.all)
	return {"grid-count": method([grid_size(rep, s), row_line(s), p, final_step(ans)], ans.values),
		"systematic-list": method([pairs_size(s), pairs_line(s, pairs), p, final_step(ans)], ans.values)}


# ── The fair grid ────────────────────────────────────────────

func u_fill_cell(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r: int = s.hide[0]
	var c: int = s.hide[1]
	var a: int = s.xs[r]
	var b: int = s.ys[c]
	var v := SampleSpaceSituation.score(s.rule, a, b)
	var table := grid(s, CORNER[s.rule], func(x, y): return SampleSpaceSituation.score(s.rule, x, y))
	table.rows[r + 1][1][c] = "?"
	var out := {"asked": "One cell of the table is hidden. Find the score it hides."}
	_fair_lines(rep, s, out, table)
	var ans := Answer.make("number", {"v": Q.new(v)}, {}, "score = ")
	ans.exact = true
	out.answer = ans
	var wrongs: Array = []
	for other in ["sum", "product", "max"]:
		if other != s.rule:
			wrongs.append(wrong({"v": Q.new(SampleSpaceSituation.score(other, a, b))}, R_WRONG_RULE))
	var side := c + 1 if c + 1 < s.ys.size() else c - 1
	wrongs.append(wrong({"v": Q.new(SampleSpaceSituation.score(s.rule, a, s.ys[side]))}, R_NEXT_CELL))
	out.wrongs = wrongs
	out.generic = [{"v": Q.new(v + 1)}, {"v": Q.new(v + 2)}, {"v": Q.new(v + 3)}]
	out.methods = {"grid-count": method(["The cell is in the row for %d and the column for %d, so the two numbers are %d and %d." % [a, b, a, b],
		"The score is %s: %s." % [RULE_TEXT[s.rule], _score_sum(s.rule, a, b, v)], final_step(ans)], ans.values)}
	return out


static func _score_sum(rule: String, a: int, b: int, v: int) -> String:
	match rule:
		"sum":
			return "%d + %d = %d" % [a, b, v]
		"product":
			return "%d × %d = %d" % [a, b, v]
		"difference":
			return "%d − %d = %d" % [maxi(a, b), mini(a, b), v]
	return "the larger of %d and %d is %d" % [a, b, v]


func u_total_outcomes(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := {"asked": "Find the total number of outcomes in the sample space."}
	_fair_lines(rep, s, out)
	var ans := count_ans(s.all)
	out.answer = ans
	var m: int = s.xs.size()
	var n: int = s.ys.size()
	var wrongs: Array = [wrong({"v": Q.new(SampleSpaceSituation.kinds(s))}, R_KINDS), wrong({"v": Q.new(m + n)}, R_ADD_FACES)]
	if SampleSpaceSituation.all_different(s):
		var cells: Array = []
		for x in s.xs:
			for y in s.ys:
				cells.append([x, y])
		wrongs.append(wrong({"v": Q.new(SampleSpaceSituation.merged(cells))}, R_ONE_PAIR))
	out.wrongs = wrongs
	out.generic = [{"v": Q.new(s.all - 1)}, {"v": Q.new(s.all + m)}, {"v": Q.new(s.all * 2)}]
	var names_of := names(s)
	out.methods = {"grid-count": method(["A grid has a row for each of the %d %s and a column for each of the %d %s." % [m, parts_of(names_of[0]), n, parts_of(names_of[1])] + repeat_note(s),
			"The grid has %d × %d = %d cells." % [m, n, s.all], final_step(ans)], ans.values),
		"systematic-list": method(["List the ordered pairs by their first number: each of the %d %s starts %d pairs." % [m, parts_of(names_of[0]), n] + repeat_note(s),
			"That makes %d lots of %d: %d × %d = %d pairs." % [m, n, m, n, s.all], final_step(ans)], ans.values)}
	return out


func u_count_event(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := {"asked": "Find the number of outcomes for which %s." % event_words(s)}
	_fair_lines(rep, s, out)
	var pairs := SampleSpaceSituation.hits(s)
	var h: int = pairs.size()
	var ans := count_ans(h)
	out.answer = ans
	var wrongs: Array = []
	if SampleSpaceSituation.all_different(s):
		wrongs.append(wrong({"v": Q.new(SampleSpaceSituation.merged(pairs))}, R_ONE_PAIR))
	var seen: Array = pairs.map(func(p): return SampleSpaceSituation.score(s.rule, p[0], p[1]))
	wrongs.append(wrong({"v": Q.new(SampleSpaceSituation.distinct(seen).size())}, R_SCORES_NOT_CELLS))
	out.wrongs = wrongs
	out.generic = [{"v": Q.new(h + 1)}, {"v": Q.new(h + 2)}, {"v": Q.new(s.all - h)}]
	out.methods = {"grid-count": method([("In the grid, row by row, " if rep == "table" else "Draw the grid. Row by row, ") + "%s in %s = %d cells." % [event_words(s), plus(by_row(s)), h] + repeat_note(s), final_step(ans)], ans.values),
		"systematic-list": method([pairs_line(s, pairs) + repeat_note(s), final_step(ans)], ans.values)}
	return out


func u_p_score(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := {"asked": "Find the probability that %s." % event_words(s)}
	_fair_lines(rep, s, out)
	var pairs := SampleSpaceSituation.hits(s)
	out.answer = prob(s, Q.new(pairs.size(), s.all))
	out.wrongs = fair_wrongs(s, pairs)
	out.generic = fair_near(s, pairs.size())
	out.methods = _fair_methods(rep, s, out.answer)
	return out


## The event with its boundary read the other way.
static func flipped(s: Dictionary) -> Dictionary:
	var other: Dictionary = s.duplicate()
	other.rel = {">=": ">", ">": ">=", "<=": "<", "<": "<="}[s.rel]
	return other


func u_p_at_least(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := u_p_score(rep, s, _rng)
	var other := SampleSpaceSituation.hits(flipped(s)).size()
	if other != s.hit:
		out.wrongs = wr(s, Q.new(other, s.all), R_BOUNDARY) + out.wrongs
	return out


func u_p_complement(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := {"asked": "Find the probability that the score is not %d." % s.k}
	_fair_lines(rep, s, out)
	var pairs := SampleSpaceSituation.hits(s)
	var h: int = pairs.size()
	var ans := prob(s, Q.new(s.all - h, s.all))
	out.answer = ans
	out.wrongs = wr(s, Q.new(h, s.all), R_THE_EVENT) + fair_wrongs(s, pairs, true)
	out.generic = near(s, [Q.new(s.all - h - 1, s.all), Q.new(s.all - h + 1, s.all), Q.new(s.all - h - 2, s.all), Q.new(1, s.all)])
	var rest := "P(not %d) = 1 − %d/%d = %s" % [s.k, h, s.all, Q.new(s.all - h, s.all).text()]
	out.methods = {"grid-count": method([grid_size(rep, s), row_line(s), rest, final_step(ans)], ans.values),
		"systematic-list": method([pairs_size(s), pairs_line(s, pairs), rest, final_step(ans)], ans.values)}
	return out


func u_p_property(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return u_p_score(rep, s, _rng)


func u_p_compare(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n := names(s)
	var lines: Array = [opening(s, fair_things(s))]
	var out := {"asked": "Find the probability that %s." % event_words(s)}
	match rep:
		"table":
			lines.append("The table shows the number on the %s minus the number on the %s, with a row for each number on the %s and a column for each number on the %s." % [n[0], n[1], n[0], n[1]])
			out.table = grid(s, "−", func(a, b): return _signed0(a - b))
		_:
			lines.append("The figure shows the two of them.")
			out.graph = figure(s)
	out.lines = lines
	var pairs := SampleSpaceSituation.hits(s)
	var h: int = pairs.size()
	var ties := 0
	for x in s.xs:
		ties += s.ys.count(x)
	out.answer = prob(s, Q.new(h, s.all))
	out.wrongs = wr(s, Q.new(h + ties, s.all), R_TIES) + wr(s, Q.new(1, 2), R_HALF) + wr(s, Q.new(s.all - h - ties, s.all), R_SWAPPED)
	out.generic = fair_near(s, h)
	var note := "The cells with a positive number are the event." if rep == "table" else "Mark each cell where the row's number is higher than the column's."
	var p := ratio(h, s.all)
	out.methods = {"grid-count": method([grid_size(rep, s), note + " " + row_line(s), p, final_step(out.answer)], out.answer.values),
		"systematic-list": method([pairs_size(s), pairs_line(s, pairs), p, final_step(out.answer)], out.answer.values)}
	return out


static func _signed0(v: int) -> String:
	return "0" if v == 0 else signed(v)


# ── Matching dice, and the symmetry of the grid ──────────────

## Adds grid-symmetry to a sum on matching objects: mirror the sum, and count the lower side.
func _mirror_method(rep: String, s: Dictionary, out: Dictionary) -> void:
	var n: int = s.xs.size()
	var c := n + 1
	var other: Dictionary = s.duplicate()
	other.k = s.mirror
	other.rel = "=" if s.rel == "=" else "<="
	var pairs := SampleSpaceSituation.hits(other)
	var sign := "=" if s.rel == "=" else ("≥" if s.rel == ">=" else "≤")
	var back := "=" if s.rel == "=" else "≤"
	out.methods["grid-symmetry"] = method([
		"The numbers run from 1 to %d on both, so the sums run from 2 to %d, and the grid is symmetric about the sum %d." % [n, 2 * n, c],
		"%d is %d above %d, and %d is %d below it, so P(sum %s %d) = P(sum %s %d)." % [s.k, s.k - c, c, s.mirror, c - s.mirror, sign, s.k, back, s.mirror],
		"Count the lower side: the sum is %s for %s: %d ordered pairs out of %d." % [REL_TEXT[other.rel] % s.mirror, pairs_text(pairs), pairs.size(), s.all],
		ratio(pairs.size(), s.all), final_step(out.answer)], out.answer.values)


func u_p_mirror_score(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := u_p_score(rep, s, _rng)
	_mirror_method(rep, s, out)
	return out


func u_p_mirror_at_least(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := u_p_at_least(rep, s, _rng)
	_mirror_method(rep, s, out)
	return out


func u_p_rule_points(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n := names(s)
	var size: int = s.xs.size()
	var lines: Array = [opening(s, fair_things(s))]
	var out := {}
	match rep:
		"table":
			lines.append("The table shows every outcome as a pair of numbers, with a row for each number on the %s and a column for each number on the %s." % n)
			out.table = grid(s, "pair", func(a, b): return "%d,%d" % [a, b])
		_:
			lines.append(face_line(n[0], s.xs))
			lines.append(face_line(n[1], s.ys))
	lines.append("A player scores %d points if the two numbers match, %d points if they differ by exactly %d, and 0 points otherwise." % [s.hi, s.mid, s.d])
	out.lines = lines
	out.asked = "Find the probability that a player scores %d points in one round." % s.mid if s.case == "mid" \
		else "Find the probability that a player scores some points in one round."
	var pairs := SampleSpaceSituation.hits(s)
	var h: int = pairs.size()
	var ans := prob(s, Q.new(h, s.all))
	out.answer = ans
	var one_way := SampleSpaceSituation.merged(pairs)
	var unordered: int = size * (size + 1) / 2
	out.wrongs = wr(s, Q.new(one_way, s.all), R_ONE_PAIR) + wr(s, Q.new(one_way, unordered), R_ONE_PAIR) + wr(s, Q.new(s.all - h, s.all), R_THE_EVENT)
	out.generic = fair_near(s, h)
	var match_line := "The two numbers differ by exactly %d" % s.d if s.case == "mid" else "A player scores points when the numbers match or differ by exactly %d" % s.d
	var row := "Row by row, that is %s = %d cells." % [plus(by_row(s)), h]
	var p := ratio(h, s.all)
	var above: int = size - s.d
	var diag: int = size if s.case == "some" else 0
	var count := "2 × %d = %d cells." % [above, h] if diag == 0 else "2 × %d + %d = %d cells." % [above, diag, h]
	var cut := "Above the diagonal the numbers differ by exactly %d in %d cells." % [s.d, above] if diag == 0 \
		else "On the diagonal the numbers match in %d cells, and above it they differ by exactly %d in %d cells." % [diag, s.d, above]
	out.methods = {"grid-count": method([grid_size(rep, s), match_line + ". " + row, p, final_step(ans)], ans.values),
		"systematic-list": method([pairs_size(s), "%s. That happens for %s: %d ordered pairs." % [match_line, pairs_text(pairs), h], p, final_step(ans)], ans.values),
		"grid-symmetry": method(["(a, b) and (b, a) differ by the same amount, so the grid is symmetric across its diagonal.", cut,
			"Below the diagonal is the mirror of above it, so the event has " + count, p, final_step(ans)], ans.values)}
	return out


# ── One biased object, two rolls ─────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## The lines that give a biased object's probabilities.
func _biased_lines(rep: String, s: Dictionary, out: Dictionary) -> Array:
	var thing: String = "die" if s.kind == "die" else "spinner"
	var lines: Array = [opening(s, "a biased %s" % thing)]
	match rep:
		"table":
			lines.append("X is the number it shows, and the table gives the probabilities.")
			out.table = {"rows": [["x", s.xs.map(func(x): return str(x))], ["P(X = x)", s.px.map(func(p): return D(p))]]}
		"diagram":
			lines.append("X is the number it shows. The figure labels each sector with its number and its probability.")
			var labels: Array = []
			for i in s.xs.size():
				labels.append("%d: %s" % [s.xs[i], D(s.px[i])])
			out.graph = {"kind": "spinners", "items": [item("spinner", labels, s.px.map(func(p): return p.to_float()))]}
		_:
			var parts: Array = []
			for i in s.xs.size():
				parts.append("P(X = %d) = %s" % [s.xs[i], D(s.px[i])])
			lines.append("X is the number it shows, and %s." % list_of(parts))
	return lines


static func product_of(s: Dictionary, p: Array) -> String:
	return "%s × %s" % [D(SampleSpaceSituation.p_of(s, p[0])), D(SampleSpaceSituation.p_of(s, p[1]))]


func _weighted_methods(s: Dictionary, ans: Dictionary, what: String) -> Dictionary:
	var pairs := SampleSpaceSituation.hits(s)
	var n: int = s.xs.size()
	var v := SampleSpaceSituation.weighted(s, pairs)
	var products: Array = pairs.map(func(p): return product_of(s, p))
	var worked: Array = pairs.map(func(p): return D(SampleSpaceSituation.p_of(s, p[0]).mul(SampleSpaceSituation.p_of(s, p[1]))))
	return {"grid-count": method(["The %s are independent, so each cell of the %d × %d grid has probability P(X = first) × P(X = second)." % ["rolls" if s.kind == "die" else "spins", n, n],
			"%s in the cells %s." % [sentence(what), pairs_text(pairs)],
			"P = %s" % " + ".join(products), "P = %s = %s" % [" + ".join(worked), D(v)], final_step(ans)], ans.values),
		"systematic-list": method(["List the ordered pairs (first, second) where %s: %s." % [what, pairs_text(pairs)],
			"Each pair has probability P(X = first) × P(X = second), so P = %s" % " + ".join(products),
			"P = %s = %s" % [" + ".join(worked), D(v)], final_step(ans)], ans.values)}


## The wrong options of a chance from two rolls.
func _weighted_wrongs(s: Dictionary, pairs: Array) -> Array:
	var once: Array = pairs.filter(func(p): return p[0] <= p[1])
	return wr(s, SampleSpaceSituation.weighted(s, once), R_ONE_PAIR) + wr(s, Q.new(pairs.size(), s.all), R_EQUAL_CELLS)


func _weighted_near(s: Dictionary, v: Q) -> Array:
	var step := Q.new(1, 100)
	return near(s, [Q.new(1).sub(v), v.add(step), v.sub(step), v.add(step.mul(Q.new(2)))])


func u_weighted_sum(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := {}
	var lines := _biased_lines(rep, s, out)
	var verb := "rolled" if s.kind == "die" else "spun"
	lines.append("It is %s twice, and the two numbers are added to give a total." % verb)
	out.lines = lines
	var what: String = "the total is " + (REL_TEXT[s.rel] % s.k)
	out.asked = "Find the probability that %s." % what
	var pairs := SampleSpaceSituation.hits(s)
	var v := SampleSpaceSituation.weighted(s, pairs)
	out.answer = prob(s, v)
	out.wrongs = _weighted_wrongs(s, pairs)
	if s.rel == ">=":
		var over: Dictionary = s.duplicate()
		over.rel = ">"
		out.wrongs = wr(s, SampleSpaceSituation.weighted(over, SampleSpaceSituation.hits(over)), R_BOUNDARY) + out.wrongs
	out.generic = _weighted_near(s, v)
	out.methods = _weighted_methods(s, out.answer, what)
	out.titles = {"grid-count": WEIGHTS_TITLE}
	return out


func u_weighted_target(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := {}
	var lines := _biased_lines(rep, s, out)
	var verb := "rolls" if s.kind == "die" else "spins"
	lines.append("A player adds the numbers from up to %d %s, and wins with a total of at least %d." % [s.rolls + 2, verb, s.goal])
	lines.append("After %d %s, the player's total is %d. The %s are independent." % [s.rolls, verb, s.score, verb])
	out.lines = lines
	out.asked = "Find the probability that the player wins."
	var pairs := SampleSpaceSituation.hits(s)
	var v := SampleSpaceSituation.weighted(s, pairs)
	out.answer = prob(s, v)
	out.wrongs = _weighted_wrongs(s, pairs)
	var over: Dictionary = s.duplicate()
	over.rel = ">"
	out.wrongs += wr(s, SampleSpaceSituation.weighted(over, SampleSpaceSituation.hits(over)), R_BOUNDARY)
	var one := Q.new(0)
	for i in s.xs.size():
		if s.xs[i] >= s.k:
			one = one.add(s.px[i])
	out.wrongs += wr(s, one, R_ONE_ROLL)
	out.generic = _weighted_near(s, v)
	var what := "the last two numbers add to at least %d" % s.k
	out.methods = _weighted_methods(s, out.answer, what)
	var first: String = "The player needs %d − %d = %d more from the last two %s." % [s.goal, s.score, s.k, verb]
	for m in out.methods:
		out.methods[m].steps = _with_first(first, out.methods[m].steps)
	out.titles = {"grid-count": WEIGHTS_TITLE}
	return out


## A first step put in front, keeping to five steps: it joins the old first step.
static func _with_first(first: String, steps: Array) -> Array:
	return [first + " " + steps[0]] + steps.slice(1)


# ── A face to find ───────────────────────────────────────────

static func dist_table(s: Dictionary) -> Dictionary:
	var sums := SampleSpaceSituation.sums_of(s.xs, s.ys)
	return {"rows": [["s", sums.map(func(t): return str(t))],
		["P(S = s)", sums.map(func(t): return "%d/%d" % [SampleSpaceSituation.sum_count(s.xs, s.ys, t), s.all])]]}


func _face_lines(s: Dictionary, labels: Array, letters: String) -> Array:
	return [opening(s, "two fair dice"), face_line("first die", s.xs),
		face_line("second die", labels) + " Here %s." % letters, "S is the sum of the two numbers."]


func u_face_from_largest(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var labels: Array = [s.c, "a", "a", "b"]
	var out := {}
	var lines := _face_lines(s, labels, "%d < a < b, and a and b are whole numbers" % s.c)
	var top: int = s.xs.max()
	var low: int = s.xs.min()
	var largest: int = top + s.b
	match rep:
		"table":
			lines.append("The table gives the distribution of S.")
			out.table = dist_table(s)
		"diagram":
			lines = [opening(s, "two fair dice"), "The figure shows their faces, where %d < a < b, and a and b are whole numbers." % s.c,
				"S is the sum of the two numbers.", "The largest possible value of S is %d." % largest]
			out.graph = {"kind": "spinners", "items": [item("first die", s.xs), item("second die", labels)]}
		_:
			lines.append("The largest possible value of S is %d." % largest)
	out.lines = lines
	out.asked = "Find the value of b."
	var ans := Answer.make("number", {"v": Q.new(s.b)}, {}, "b = ")
	ans.exact = true
	out.answer = ans
	out.wrongs = [wrong({"v": Q.new(largest)}, R_LARGEST), wrong({"v": Q.new(largest - low)}, R_SMALL_FACE)]
	out.generic = [{"v": Q.new(s.b + 1)}, {"v": Q.new(s.b - 1)}, {"v": Q.new(s.b + 2)}]
	var read := "The table's largest sum is %d." % largest if rep == "table" else "The largest sum is %d." % largest
	out.methods = {"systematic-list": method(["Only ordered pairs of the two largest faces reach the largest sum: (%d, b)." % top,
		read + " So %d + b = %d." % [top, largest], "b = %d − %d = %d" % [largest, top, s.b], final_step(ans)], ans.values)}
	return out


## The two columns that aren't a's, as "sum: cells" for each sum.
static func _counts_text(sums: Array, counts: Array) -> String:
	var parts: Array = []
	for i in sums.size():
		parts.append("%d: %d" % [sums[i], counts[i]])
	return ", ".join(parts)


func u_face_from_grid(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var labels: Array = [s.c, "a", "a", s.b]
	var out := {}
	var lines := _face_lines(s, labels, "%d < a < %d, and a is a whole number" % [s.c, s.b])
	if rep == "table":
		lines.append("The table gives the distribution of S.")
		out.table = dist_table(s)
	else:
		lines.append("The probability that S = %d is %d/%d." % [s.t, s.count, s.all])
	out.lines = lines
	out.asked = "Find the value of a."
	var ans := Answer.make("number", {"v": Q.new(s.a)}, {}, "a = ")
	ans.exact = true
	out.answer = ans
	var low: int = s.xs.min()
	var wrongs: Array = []
	if rep == "table":
		var sums := SampleSpaceSituation.sums_of(s.xs, s.ys)
		var next: int = sums[1] - low
		if next > 0:
			wrongs.append(wrong({"v": Q.new(next)}, R_NEXT_SUM))
	out.wrongs = wrongs
	out.generic = [{"v": Q.new(s.a + 1)}, {"v": Q.new(s.a - 1)}, {"v": Q.new(s.b - 1)}, {"v": Q.new(s.a + 2)}, {"v": Q.new(s.b + 1)}]
	var grid_steps: Array
	if rep == "table":
		var sums := SampleSpaceSituation.sums_of(s.xs, s.ys)
		var all_counts: Array = sums.map(func(t): return SampleSpaceSituation.sum_count(s.xs, s.ys, t))
		var known: Array = sums.map(func(t): return SampleSpaceSituation.sum_count(s.xs, [s.c, s.b], t))
		var left: Array = []
		for i in sums.size():
			left.append(all_counts[i] - known[i])
		var first: int = low + s.a
		grid_steps = ["There are %d equally likely cells, so the table gives the cells for each sum: %s." % [s.all, _counts_text(sums, all_counts)],
			"The columns for %d and %d fill these cells: %s." % [s.c, s.b, _counts_text(sums, known)],
			"The two columns for a hold the rest: %s. The smallest sum there is %d." % [_counts_text(sums, left), first],
			"That sum is the first die's smallest number plus a: %d + a = %d, so a = %d − %d = %d." % [low, first, first, low, s.a],
			final_step(ans)]
	else:
		var v: int = (s.count - s.u) / 2
		var f: int = s.t - s.a
		grid_steps = ["There are %d equally likely cells, so the sum %d is in %d of them." % [s.all, s.t, s.count],
			"The columns for %d and %d hold %d of those cells." % [s.c, s.b, s.u],
			"The other %d − %d = %d are in the two columns for a, so each holds %d: %d row%s of the first die %s x + a = %d." % [s.count, s.u, s.count - s.u, v, v, "" if v == 1 else "s", "has" if v == 1 else "have", s.t],
			"Of the whole numbers between %d and %d, only a = %d leaves x = %d on exactly %d face%s of the first die." % [s.c, s.b, s.a, f, v, "" if v == 1 else "s"],
			final_step(ans)]
	var tried: Array = []
	for other in range(s.c + 1, s.b):
		tried.append("a = %d gives %d" % [other, SampleSpaceSituation.sum_count(s.xs, [s.c, other, other, s.b], s.t)])
	var has := "the table's P(S = %d) = %d/%d" % [s.t, s.count, s.all] if rep == "table" else "P(S = %d) = %d/%d" % [s.t, s.count, s.all]
	out.methods = {"grid-count": method(grid_steps, ans.values),
		"systematic-list": method(["Take %s: the sum %d is in %d ordered pairs." % [has, s.t, s.count],
			"List the pairs with sum %d for each whole number between %d and %d: %s." % [s.t, s.c, s.b, ", ".join(tried)],
			"Only a = %d gives %d pairs." % [s.a, s.count], final_step(ans)], ans.values)}
	out.titles = {"grid-count": LETTER_TITLE}
	return out


# ── Two biased dice, a chance to find ────────────────────────

func _win_lines(rep: String, s: Dictionary, out: Dictionary) -> void:
	var n: int = s.xs.size()
	var letters: Array = []
	for i in n:
		letters.append("r" if i == n - 1 else "q")
	var lines: Array = [opening(s, "two biased dice, A and B"), "X is the number on die A and Y is the number on die B."]
	if rep == "table":
		lines.append("The table gives their probabilities, where q and r are constants.")
		out.table = {"rows": [["n", s.xs.map(func(x): return str(x))], ["P(X = n)", s.px.map(func(p): return p.text())], ["P(Y = n)", letters]]}
	else:
		var parts: Array = []
		for i in n:
			parts.append("P(X = %d) = %s" % [s.xs[i], s.px[i].text()])
		lines.append("%s." % list_of(parts))
		var same: Array = []
		for i in n - 1:
			same.append("P(Y = %d)" % s.xs[i])
		lines.append("%s = q and P(Y = %d) = r, where q and r are constants." % [" = ".join(same), n])
	lines.append("Each die is rolled once. The probability that X is less than Y is %s." % s.pa.text())
	out.lines = lines


## cq q + cr r = P(X < Y), and what it solves to. The list of the steps both unknowns share.
func _win_steps(s: Dictionary) -> Dictionary:
	var n: int = s.xs.size()
	var parts: Array = []
	for i in n:
		parts.append("P(X < %d) = %s" % [s.xs[i], Q.of(s.gs[i]).text()])
	var pairs: Array = []
	for x in s.xs:
		for y in s.xs:
			if x < y:
				pairs.append([x, y])
	var terms: Array = []
	for i in n:
		terms.append("%s × %s" % [Q.of(s.gs[i]).text(), "r" if i == n - 1 else "q"])
	var first: String = "Adding the columns gives P(X < Y) = %s = %s × q + %s × r, and that is %s." % [" + ".join(terms), Q.of(s.cq).text(), Q.of(s.cr).text(), s.pa.text()]
	var coef: Q = Q.of(s.cq).sub(Q.of(s.cr).mul(Q.new(n - 1)))
	var right: Q = s.pa.sub(s.cr)
	var sub := "The probabilities of Y add to 1, so r = 1 − %dq, and %s × q + %s × (1 − %dq) = %s." % [n - 1, Q.of(s.cq).text(), Q.of(s.cr).text(), n - 1, s.pa.text()]
	var solved := "So %s × q = %s − %s = %s, and q = %s ÷ %s = %s." % [Fmt.paren(coef), s.pa.text(), Q.of(s.cr).text(), right.text(), Fmt.paren(right), Fmt.paren(coef), s.qy.text()]
	return {"cells": "Each cell of the grid has probability P(X = x) × P(Y = y). The column for y holds P(X < y) × P(Y = y) of the event: %s." % ", ".join(parts),
		"pairs": "List the ordered pairs (x, y) with x < y: %s. Group them by y, as P(X < y) × P(Y = y): %s." % [pairs_text(pairs), ", ".join(parts)],
		"add": first, "sub": sub, "solved": solved}


func u_weight_from_win(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := {"asked": "Find the value of q."}
	_win_lines(rep, s, out)
	var n: int = s.xs.size()
	var ans := Answer.make("number", {"v": s.qy}, {}, "q = ")
	ans.exact = true
	out.answer = ans
	out.wrongs = [wrong({"v": s.ry}, R_OTHER_LETTER), wrong({"v": Q.new(1, n)}, R_FAIR), wrong({"v": s.tie_q}, R_TIES)]
	out.generic = near(s, [s.qy.add(Q.new(1, s.qy.d)), s.qy.sub(Q.new(1, s.qy.d)), s.qy.mul(Q.new(2))])
	var w := _win_steps(s)
	out.methods = {"grid-count": method([w.cells, w.add, w.sub, w.solved, final_step(ans)], ans.values),
		"systematic-list": method([w.pairs, w.add, w.sub, w.solved, final_step(ans)], ans.values)}
	out.titles = {"grid-count": WEIGHTS_TITLE}
	return out


func u_expected_from_win(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := {"asked": "Find E(Y)."}
	_win_lines(rep, s, out)
	var n: int = s.xs.size()
	var e := Q.new(0)
	var terms: Array = []
	var all_q := Q.new(0)
	var ex := Q.new(0)
	for i in n:
		var p: Q = s.ry if i == n - 1 else s.qy
		e = e.add(p.mul(Q.new(s.xs[i])))
		all_q = all_q.add(s.qy.mul(Q.new(s.xs[i])))
		ex = ex.add(s.px[i].mul(Q.new(s.xs[i])))
		terms.append("%d × %s" % [s.xs[i], p.text()])
	var ans := Answer.make("number", {"v": e}, {}, "E(Y) = ")
	ans.exact = true
	out.answer = ans
	out.wrongs = [wrong({"v": Q.new(n + 1, 2)}, R_FAIR), wrong({"v": ex}, R_OTHER_DIE), wrong({"v": all_q}, R_ALL_Q)]
	out.generic = [{"v": e.add(Q.new(1, e.d))}, {"v": e.sub(Q.new(1, e.d))}, {"v": e.add(Q.new(2, e.d))}]
	var w := _win_steps(s)
	var last := "So r = 1 − %d × %s = %s, and E(Y) = %s = %s." % [n - 1, s.qy.text(), s.ry.text(), " + ".join(terms), e.text()]
	out.methods = {"grid-count": method([w.cells + " " + w.add, w.sub, w.solved, last, final_step(ans)], ans.values),
		"systematic-list": method([w.pairs + " " + w.add, w.sub, w.solved, last, final_step(ans)], ans.values)}
	out.titles = {"grid-count": WEIGHTS_TITLE}
	return out
