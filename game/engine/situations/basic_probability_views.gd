class_name BasicProbabilityViews
extends ExtensionViews
## The views on the `basic-probability` situation: one builder per unknown of t4-probability-basic
## (FAL-728). Answers are exact on Paper 1, as a fraction or a decimal that ends; Paper 2 counts and
## products are answered to 3 s.f. (show "sf", with the rounding trap). A coin list on Paper 2, a
## complement of a written decimal and a graph reading stay exact decimals, and a run of results
## stays an exact fraction.
##
## Representations: "words" (a story), "equation" (P(A) = 0.37), "table" (a two-way table or a
## frequency table, as rows), "terms" (a list of data), "diagram" (a sample space as a table, or a
## two-stage tree) and "graph" (PlotView's `bars`, or `cumfreq` drawing a running relative
## frequency).
##
## `given` holds the situation for the SymPy checker, which only takes the story's index from it:
## it reads every number back from what the student sees.

const R_SAME_SHARE := "SL4.5.equally-likely#0"
const R_ROW := "SL4.5.equally-likely#1"
const R_EXACTLY_ONE := "SL4.5.complement#0"
const R_ADD_TRIALS := "SL4.5.complement#1"
const R_SHORT_RUN := "SL4.5.relative-frequency#0"
const R_DUE := "SL4.5.relative-frequency#1"
## The type's own slips, by their place in its misconceptions list.
const R_REST := "t4-probability-basic#6"
const R_OLD_TOTAL := "t4-probability-basic#7"
const R_OLD_COUNT := "t4-probability-basic#8"
const R_EVENT := "t4-probability-basic#9"
const R_BOUNDARY := "t4-probability-basic#10"
const R_ONE_RULE := "t4-probability-basic#11"
const R_WHOLE_RUN := "t4-probability-basic#12"

const UNKNOWNS := ["bag-counter", "bag-after-change", "two-way-whole", "list-data", "grid-total-equals", "grid-total-at-least",
	"list-then-count", "complement-given", "complement-table", "complement-count", "complement-two-rules", "at-least-one-same",
	"at-least-one-different", "rf-from-table", "rf-total-to-find", "rf-graph-estimate", "more-reliable", "gamblers-fallacy"]

const COLOURS := ["red", "blue", "green", "white", "black"]
const NAMES := ["Ash", "Bree", "Cole", "Dara", "Eli", "Fenn"]
## What a bag is and what is in it, plural and singular.
const BAGS := [["A sack", "tokens", "token"], ["A crate", "fuses", "fuse"], ["A tin", "washers", "washer"], ["A pouch", "bottle caps", "bottle cap"],
	["A drum", "marbles", "marble"], ["A jar", "beads", "bead"], ["A toolbox", "wires", "wire"], ["A bucket", "tags", "tag"]]
const TWO_WAY := [
	{"who": "scavengers", "one": "scavenger", "rows": ["Camp", "Road"], "cols": ["Knife", "Bow", "Rifle"],
		"r": ["is from the camp", "is from the road"], "c": ["carries a knife", "carries a bow", "carries a rifle"]},
	{"who": "traders", "one": "trader", "rows": ["North", "South"], "cols": ["Salt", "Fuel", "Seed"],
		"r": ["works the north road", "works the south road"], "c": ["sells salt", "sells fuel", "sells seed"]},
	{"who": "guards", "one": "guard", "rows": ["Day", "Night"], "cols": ["Gate", "Wall", "Tower"],
		"r": ["works days", "works nights"], "c": ["stands at the gate", "stands on the wall", "stands in the tower"]},
	{"who": "drivers", "one": "driver", "rows": ["Truck", "Bike"], "cols": ["Fuel", "Water", "Parts"],
		"r": ["drives a truck", "rides a bike"], "c": ["carries fuel", "carries water", "carries parts"]},
]
## Who keeps a log, of what, per what, and how the question ends.
const LOGS := [["A scavenger", "the cans found", "day", "days", "cans were found"], ["A guard", "the raiders seen", "night", "nights", "raiders were seen"],
	["A medic", "the patients treated", "day", "days", "patients were treated"], ["A trader", "the crates sold", "week", "weeks", "crates were sold"]]
## The event, and the question's words for its complement.
const EVENTS := [["an old engine starts on a cold morning", "it does not start"], ["a water sample is safe to drink", "it is not safe to drink"],
	["a radio picks up a signal at dusk", "it does not pick up a signal"], ["a patrol returns before dark", "it does not return before dark"],
	["a crate of cans is still sealed", "it is not still sealed"], ["a bridge holds a loaded cart", "it does not hold the cart"],
	["a drone lands on its pad", "it does not land on its pad"], ["a seed sprouts in dry soil", "it does not sprout"]]
## The opening, one trial, its success, the trials' plural and the line that says how many.
const TRIALS := [["Each radio scan", "scan", "picks up a signal", "scans", "The radio makes %d scans."], ["Each seed", "seed", "sprouts", "seeds", "A farmer plants %d seeds."],
	["Each arrow a guard fires", "arrow", "hits the target", "arrows", "The guard fires %d arrows."], ["Each fuse from a crate", "fuse", "blows", "fuses", "A mechanic fits %d fuses."],
	["Each can on a shelf", "can", "has gone bad", "cans", "A trader opens %d cans."], ["Each drone trip", "trip", "arrives late", "trips", "The drone makes %d trips."],
	["Each lock on the vault", "lock", "jams", "locks", "A scavenger tries %d locks."], ["Each old bridge", "bridge", "gives way", "bridges", "A caravan crosses %d bridges."]]
## What one person does, and their one go at it.
const TRIES := ["hits the target", "finds water", "fixes the pump", "gets the radio working", "reaches the depot", "spots the convoy", "finds the way through", "wins the bid"]
## The thing tested, what it does, and the verb's past.
const RF := [["A home-made spinner", "spun", "spin"], ["A bent die", "rolled", "roll"], ["A weighted wheel", "spun", "spin"], ["A dented dial", "spun", "spin"]]
## Column head, letter, unit, the plural counted and one of them.
const CLASSES := [["Load, w (kg)", "w", "kg", "crates", "crate", "its load"], ["Age, a (years)", "a", "years", "settlers", "settler", "their age"],
	["Time, t (minutes)", "t", "minutes", "patrols", "patrol", "its time"], ["Length, l (cm)", "l", "cm", "pipes", "pipe", "its length"]]
## A long test: the line, the event, and two tests of it, with the head for a hit.
const LONG_RUNS := [
	{"line": "A trader spins a wheel again and again. The graph shows the relative frequency of green after each set of spins.",
		"event": "one spin lands on green", "of": "a wheel", "test": "spun it %d times and it landed on green %d times", "hit": "Green", "x": "number of spins"},
	{"line": "A guard tests fuses from one crate, one after another. The graph shows the relative frequency of a failed fuse as the tests go on.",
		"event": "a fuse from the crate fails", "of": "a crate of fuses", "test": "tested %d fuses and %d of them failed", "hit": "Failed", "x": "number of fuses"},
	{"line": "A scavenger drops a bottle cap again and again. The graph shows the relative frequency of it landing face up as the drops go on.",
		"event": "one drop lands face up", "of": "a bottle cap", "test": "dropped it %d times and it landed face up %d times", "hit": "Face up", "x": "number of drops"},
	{"line": "A medic tests water from one well, sample after sample. The graph shows the relative frequency of an unsafe sample as the tests go on.",
		"event": "a sample from the well is unsafe", "of": "water from a well", "test": "tested %d samples and %d of them were unsafe", "hit": "Unsafe", "x": "number of samples"},
]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1, 2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = BasicProbabilitySituation.export(s)
	# Two slips can be offered beside a rounding trap, so which show varies by seed.
	out.wrongs = rng.shuffled(out.wrongs)
	# The engine's last-resort nudges add 1, which is no probability.
	var v: Q = out.answer.values.v
	var unit := near_unit(s, v)
	for k in [1, -1, 2, -2, 3, -3, 4, -4, 5, -5, 6, -6, 7, -7]:
		out.generic.append_array(fair(s, [v.add(unit.mul(Q.new(k)))]))
	return out


# ── Writing things ───────────────────────────────────────────

## A probability as this question writes it in its working.
static func T(s: Dictionary, v: Q) -> String:
	match s.form:
		"dec":
			return Fmt.dec(v)
		"sf":
			return Fmt.work(v, 6)
	return Fmt.num(v)


static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func prob_ans(s: Dictionary, v: Q, label: String = "probability = ") -> Dictionary:
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


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## How far apart near options sit: one in the answer's denominator, or one in its last place.
static func near_unit(s: Dictionary, v: Q) -> Q:
	if s.form == "frac":
		return Q.new(1, v.d)
	if s.form == "sf":
		return Q.new(1, 100)
	var scale := 10
	while scale % v.d != 0:
		scale *= 10
	return Q.new(1, scale)


## Whether v can stand as an option: a probability, written the way the answer is. A decimal
## question keeps its decimals, so a value that doesn't end is left out.
static func fits(s: Dictionary, v: Q) -> bool:
	if v.sign() <= 0 or not v.lt(Q.new(1)):
		return false
	match s.form:
		"dec":
			return Fmt.dec(v).contains(".") and Fmt.dec(v).length() <= 7
		"sf":
			return not Answer.needs_rounding(v) or Answer.rounds_clearly(v.to_float(), BasicProbabilitySituation.EDGE)
	return v.d <= 10000


static func fair(s: Dictionary, xs: Array) -> Array:
	return xs.filter(func(x): return fits(s, x)).map(func(x): return {"v": x})


## A tagged wrong value, offered only where it can stand as an option.
static func wr(s: Dictionary, v: Q, ref: String) -> Array:
	return [wrong({"v": v}, ref)] if fits(s, v) else []


## "5/15 = 1/3", or a division where the answer is a decimal.
static func ratio(s: Dictionary, a: int, b: int) -> String:
	var v := Q.new(a, b)
	if s.form != "frac":
		return "%d ÷ %d = %s" % [a, b, T(s, v)]
	return "%d/%d" % [a, b] if v.d == b else "%d/%d = %s" % [a, b, Fmt.num(v)]


static func plus(xs: Array) -> String:
	return " + ".join(xs.map(func(x): return str(x)))


static func colour(s: Dictionary, i: int) -> String:
	return COLOURS[s.cols[i]]


## "4 red, 7 blue and 3 green": a list with its last item after "and".
static func listing(items: Array) -> String:
	if items.size() < 2:
		return "".join(items)
	return ", ".join(items.slice(0, items.size() - 1)) + " and " + items[-1]


# ── Bags ─────────────────────────────────────────────────────

static func bag_line(s: Dictionary) -> String:
	var b: Array = BAGS[s.ctx % BAGS.size()]
	var items: Array = []
	for i in s.counts.size():
		items.append("%d %s" % [s.counts[i], colour(s, i)])
	return "%s holds %s %s." % [b[0], listing(items), b[1]]


func u_bag_counter(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: Array = BAGS[s.ctx % BAGS.size()]
	var total: int = BasicProbabilitySituation.sum(s.counts)
	var n := 0
	var names: Array = []
	for t in s.target:
		n += int(s.counts[t])
		names.append(colour(s, t))
	var v := Q.new(n, total)
	var ans := prob_ans(s, v)
	var event: String = " or ".join(names)
	var out := {"answer": ans, "asked": "One %s is taken at random. Find the probability that it is %s." % [b[2], event]}
	if rep == "table":
		out.lines = ["%s holds %s of the colours in the table." % [b[0], b[1]]]
		var heads: Array = []
		for i in s.counts.size():
			heads.append(colour(s, i).capitalize())
		out.table = {"rows": [["Colour", heads], ["Number", s.counts.map(func(c): return str(c))]]}
	else:
		out.lines = [bag_line(s)]
	out.wrongs = wr(s, Q.new(s.target.size(), s.counts.size()), R_SAME_SHARE) + wr(s, Q.new(n, total - n), R_REST)
	out.generic = fair(s, [Q.new(total - n, total), Q.new(1, total), Q.new(n + 1, total)])
	var have := "%d of them are %s." % [n, event] if s.target.size() == 1 else "%s = %d of them are %s." % [plus(s.target.map(func(t): return s.counts[t])), n, event]
	out.methods = {"count-ratio": method(["Every %s is equally likely, so count %s, not colours: %s = %d in all." % [b[2], b[1], plus(s.counts), total],
		have, "P = n(A) ÷ n(U): " + ratio(s, n, total), final_step(ans)], ans.values)}
	return out


func u_bag_after_change(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: Array = BAGS[s.ctx % BAGS.size()]
	var v := BasicProbabilitySituation.after_change(s)
	var ans := prob_ans(s, v)
	var total: int = BasicProbabilitySituation.sum(s.counts)
	var step := BasicProbabilitySituation.step_size(s)
	var had: int = s.counts[s.target]
	var left: int = had + (step if s.target == s.changed else 0)
	var what: String = "%d %s" % [s.m, colour(s, s.changed)] + " " + (b[2] if s.m == 1 else b[1])
	var change: String = "%s taken out and not put back." % (what + (" is" if s.m == 1 else " are")) if s.mode == "out" else "%s added." % (what + (" is" if s.m == 1 else " are"))
	var out := {"answer": ans, "lines": [bag_line(s), change], "asked": "One %s is then taken at random. Find the probability that it is %s." % [b[2], colour(s, s.target)]}
	out.wrongs = wr(s, Q.new(left, total), R_OLD_TOTAL)
	if s.target == s.changed:
		out.wrongs += wr(s, Q.new(had, total + step), R_OLD_COUNT)
	out.generic = fair(s, [Q.new(had, total), Q.new(total + step - left, total + step), Q.new(left, total + step + 1)])
	var new_total := total + step
	var count_step := "The %s stay at %d." % [colour(s, s.target) + " " + b[1], had] if s.target != s.changed else "The %s go from %d to %d." % [colour(s, s.target) + " " + b[1], had, left]
	out.methods = {"count-ratio": method(["The bag held %s = %d, and now holds %d %s %d = %d %s." % [plus(s.counts), total, total, "−" if step < 0 else "+", absi(step), new_total, b[1]],
		count_step, "P = n(A) ÷ n(U): " + ratio(s, left, new_total), final_step(ans)], ans.values)}
	return out


# ── A two-way table ──────────────────────────────────────────

static func two_way(s: Dictionary) -> Dictionary:
	var c: Dictionary = TWO_WAY[s.ctx % TWO_WAY.size()]
	var rows: Array = [["", c.cols + ["Total"]]]
	for r in 2:
		rows.append([c.rows[r], s.cells[r].map(func(x): return str(x)) + [str(BasicProbabilitySituation.sum(s.cells[r]))]])
	var foot: Array = []
	for j in 3:
		foot.append(str(int(s.cells[0][j]) + int(s.cells[1][j])))
	foot.append(str(BasicProbabilitySituation.sum(s.cells[0]) + BasicProbabilitySituation.sum(s.cells[1])))
	rows.append(["Total", foot])
	return {"rows": rows}


func u_two_way_whole(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = TWO_WAY[s.ctx % TWO_WAY.size()]
	var v := BasicProbabilitySituation.two_way_answer(s)
	var ans := prob_ans(s, v)
	var row_total: int = BasicProbabilitySituation.sum(s.cells[s.r])
	var col_total: int = BasicProbabilitySituation.col_total(s)
	var grand: int = BasicProbabilitySituation.sum(s.cells[0]) + BasicProbabilitySituation.sum(s.cells[1])
	var cell: int = s.cells[s.r][s.c]
	var event: String = "%s and %s" % [c.r[s.r], c.c[s.c]] if s.what == "cell" else c.c[s.c]
	var out := {"answer": ans, "table": two_way(s), "lines": ["The table shows the %s at an outpost." % c.who],
		"asked": "One %s is chosen at random from the whole table. Find the probability that the %s %s." % [c.one, c.one, event]}
	if s.what == "cell":
		out.wrongs = wr(s, Q.new(cell, row_total), R_ROW) + wr(s, Q.new(cell, grand - cell), R_REST)
		out.generic = fair(s, [Q.new(cell, col_total), Q.new(row_total, grand), Q.new(col_total, grand), Q.new(grand - cell, grand)])
		out.methods = {"count-ratio": method(["The %s comes from the whole table, so n(U) is the grand total, %d." % [c.one, grand],
			"The row '%s' meets the column '%s' at %d, so n(A) = %d." % [c.rows[s.r], c.cols[s.c], cell, cell], "P = n(A) ÷ n(U): " + ratio(s, cell, grand), final_step(ans)], ans.values)}
	else:
		out.wrongs = wr(s, Q.new(col_total, grand - col_total), R_REST)
		out.generic = fair(s, [Q.new(cell, col_total), Q.new(cell, grand), Q.new(grand - col_total, grand), Q.new(1, 3)])
		out.methods = {"count-ratio": method(["The %s comes from the whole table, so n(U) is the grand total, %d." % [c.one, grand],
			"The total of the column '%s' is %d, so n(A) = %d." % [c.cols[s.c], col_total, col_total], "P = n(A) ÷ n(U): " + ratio(s, col_total, grand), final_step(ans)], ans.values)}
	return out


# ── A list of data ───────────────────────────────────────────

static func op_words(op: String, k: int) -> String:
	match op:
		"more":
			return "more than %d" % k
		"least":
			return "at least %d" % k
	return "fewer than %d" % k


func u_list_data(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var l: Array = LOGS[s.ctx % LOGS.size()]
	var n: int = s.vals.size()
	var hit := BasicProbabilitySituation.list_hits(s)
	var v := Q.new(hit, n)
	var ans := prob_ans(s, v)
	var kinds := BasicProbabilitySituation.distinct(s.vals)
	var inside := kinds.filter(func(x): return BasicProbabilitySituation.list_test(s.op, int(x), s.k)).size()
	var out := {"answer": ans, "lines": ["%s logs %s on each of %d %s:" % [l[0], l[1], n, l[3]], ", ".join(s.vals.map(func(x): return str(x)))],
		"asked": "One of these %s is chosen at random. Find the probability that %s %s on that %s." % [l[3], op_words(s.op, s.k), l[4], l[2]]}
	var boundary: int = s.vals.filter(func(x): return int(x) == s.k).size()
	var slip: int = hit + boundary if s.op != "least" else hit - boundary
	out.wrongs = wr(s, Q.new(inside, kinds.size()), R_SAME_SHARE) + wr(s, Q.new(hit, n - hit), R_REST) + wr(s, Q.new(slip, n), R_BOUNDARY)
	out.generic = fair(s, [Q.new(n - hit, n), Q.new(hit + 1, n), Q.new(hit, n + 1)])
	var hits: Array = s.vals.filter(func(x): return BasicProbabilitySituation.list_test(s.op, int(x), s.k))
	var note := ", so a value of %d does not count" % s.k if s.op != "least" else ", so a value of %d counts" % s.k
	out.methods = {"count-ratio": method(["There are %d %s in the list, each equally likely, so n(U) = %d." % [n, l[3], n],
		"The values %s are %s%s." % [op_words(s.op, s.k), ", ".join(hits.map(func(x): return str(x))), note],
		"That is %d values, so n(A) = %d." % [hit, hit], "P = n(A) ÷ n(U): " + ratio(s, hit, n), final_step(ans)], ans.values)}
	return out


# ── Grids of two dice or spinners ────────────────────────────

static func faces_line(s: Dictionary) -> String:
	if s.kind == "dice":
		return "Two fair six-sided dice are rolled."
	return "Two fair spinners have equal sectors. The first shows %s and the second shows %s. Both are spun." % [listing(s.xs.map(func(x): return str(x))), listing(s.ys.map(func(y): return str(y)))]


static func thing(s: Dictionary) -> String:
	return "dice" if s.kind == "dice" else "spinners"


static func first_name(s: Dictionary) -> String:
	return "first die" if s.kind == "dice" else "first spinner"


## The sample space as a table: one row for each face of the first, one column for the second.
static func grid(s: Dictionary, corner: String, cell: Callable) -> Dictionary:
	var rows: Array = [[corner, s.ys.map(func(y): return str(y))]]
	for x in s.xs:
		rows.append([str(x), s.ys.map(func(y): return str(cell.call(int(x), int(y))))])
	return {"rows": rows}


static func totals_grid(s: Dictionary) -> Dictionary:
	return grid(s, "+", func(x, y): return x + y)


static func gaps_grid(s: Dictionary) -> Dictionary:
	return grid(s, "gap", func(x, y): return absi(x - y))


## How many outcomes pass a test on (first, second), row by row: "0 + 1 + 2".
static func by_row(s: Dictionary, test: Callable) -> Array:
	var out: Array = []
	for x in s.xs:
		out.append(s.ys.filter(func(y): return test.call(int(x), int(y))).size())
	return out


static func pairs_of(s: Dictionary, test: Callable) -> Array:
	var out: Array = []
	for x in s.xs:
		for y in s.ys:
			if test.call(int(x), int(y)):
				out.append("(%d, %d)" % [x, y])
	return out


## The two opening lines of a grid question, and its table where it has one.
func _grid_question(rep: String, s: Dictionary, out: Dictionary) -> void:
	if rep == "diagram":
		out.lines = ["The table shows every total of two fair %s, one outcome in each cell: rows for the %s." % [thing(s), first_name(s)]]
		out.table = totals_grid(s)
	else:
		out.lines = [faces_line(s), "The two numbers are added."]


func _grid_methods(rep: String, s: Dictionary, ans: Dictionary, n: int, all: int, rows: Array, listed: String) -> Dictionary:
	var size_step := "%d × %d = %d equally likely outcomes." % [s.xs.size(), s.ys.size(), all]
	var space := "The table has %d rows of %d cells: %s" % [s.xs.size(), s.ys.size(), size_step] if rep == "diagram" \
		else "Draw a grid with the %s down the side and the second across the top: %s" % [first_name(s), size_step]
	return {"list-sample-space": method([space, "Row by row, the cells in the event number %s = %d." % [plus(rows), n], "P = n(A) ÷ n(U): " + ratio(s, n, all), final_step(ans)], ans.values),
		"count-ratio": method(["n(U) = %s" % size_step, listed, "n(A) = %d, so " % n + ratio(s, n, all), final_step(ans)], ans.values)}


func u_grid_total_equals(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ts := BasicProbabilitySituation.totals(s)
	var n: int = ts.count(s.k)
	var all: int = ts.size()
	var v := Q.new(n, all)
	var ans := prob_ans(s, v)
	var out := {"answer": ans, "asked": "Find the probability that the total is %d." % s.k}
	_grid_question(rep, s, out)
	var test := func(x: int, y: int) -> bool: return x + y == s.k
	var kinds := BasicProbabilitySituation.distinct(ts).size()
	out.wrongs = wr(s, Q.new(1, kinds), R_SAME_SHARE) + wr(s, Q.new(n, all - n), R_REST)
	out.generic = fair(s, [Q.new(all - n, all), Q.new(n + 1, all), Q.new(n, kinds + all), Q.new(1, all)])
	var pairs := pairs_of(s, test)
	out.methods = _grid_methods(rep, s, ans, n, all, by_row(s, test), "The total is %d for %s." % [s.k, listing(pairs)])
	return out


func u_grid_total_at_least(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ts := BasicProbabilitySituation.totals(s)
	var ds := BasicProbabilitySituation.distinct(ts)
	var all: int = ts.size()
	var test := func(x: int, y: int) -> bool: return x + y >= s.k
	var n: int = ts.filter(func(t): return t >= s.k).size()
	var above: int = ts.filter(func(t): return t > s.k).size()
	var kinds: int = ds.filter(func(t): return t >= s.k).size()
	var v := Q.new(n, all)
	var ans := prob_ans(s, v)
	var out := {"answer": ans, "asked": "Find the probability that the total is at least %d." % s.k}
	_grid_question(rep, s, out)
	out.wrongs = wr(s, Q.new(kinds, ds.size()), R_SAME_SHARE) + wr(s, Q.new(above, all), R_BOUNDARY) + wr(s, Q.new(n, all - n), R_REST)
	out.generic = fair(s, [Q.new(all - n, all), Q.new(n + 1, all), Q.new(n, all + ds.size())])
	var rows := by_row(s, test)
	out.methods = _grid_methods(rep, s, ans, n, all, rows, "A total of %d itself counts. Row by row there are %s = %d such outcomes." % [s.k, plus(rows), n])
	return out


# ── Listing a small sample space ─────────────────────────────

static func all_flips(n: int) -> Array:
	var out: Array = [""]
	for i in n:
		var next: Array = []
		for w in out:
			next.append(w + "H")
			next.append(w + "T")
		out = next
	return out


static func coin_out(s: Dictionary) -> Dictionary:
	var flips := all_flips(s.n).filter(func(w): return w.count("H") == s.h)
	return {"all": all_flips(s.n), "hits": flips}


func u_list_then_count(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var hit: int
	var all: int
	var lines: Array
	var asked: String
	var space: String
	var hits_text: String
	var wrongs: Array = []
	match s.kind:
		"coins":
			var c := coin_out(s)
			hit = c.hits.size()
			all = c.all.size()
			lines = ["%d fair coins are tossed." % s.n]
			asked = "List the outcomes and find the probability of exactly %d %s." % [s.h, "head" if s.h == 1 else "heads"]
			space = "The outcomes are %s: %d equally likely, in order." % [", ".join(c.all), all]
			hits_text = "Exactly %d %s: %s." % [s.h, "head" if s.h == 1 else "heads", ", ".join(c.hits)]
			wrongs = wr(s, Q.new(1, s.n + 1), R_SAME_SHARE)
		"coin-die":
			hit = BasicProbabilitySituation.die_hits(s)
			all = 12
			var faces: Array = range(1, 7).filter(func(f): return _die_test(s, f))
			var side: String = "H" if s.side == "head" else "T"
			var want := "an even number" if s.cond == "even" else ("an odd number" if s.cond == "odd" else "a number greater than %d" % s.m)
			lines = ["A fair coin is tossed and a fair six-sided die is rolled."]
			asked = "List the outcomes and find the probability of a %s and %s." % [s.side, want]
			space = "The outcomes are H1 to H6 and T1 to T6: 2 × 6 = 12, all equally likely."
			hits_text = "The event is %s." % listing(faces.map(func(f): return side + str(f)))
		"pairs":
			var who: Array = s.names.map(func(i): return NAMES[i])
			var pairs: Array = []
			for i in s.n:
				for j in range(i + 1, s.n):
					pairs.append(who[i] + " and " + who[j])
			all = pairs.size()
			var a: String = who[0]
			var b: String = who[1]
			lines = ["%s are on a crew." % listing(who), "Two of them are chosen at random for a scouting trip."]
			if s.both:
				hit = 1
				asked = "List the pairs and find the probability that %s and %s are both chosen." % [a, b]
				hits_text = "Only one pair is %s and %s." % [a, b]
			else:
				hit = s.n - 1
				asked = "List the pairs and find the probability that %s is chosen." % a
				hits_text = "%s is in %d of the pairs: one with each of the other %d." % [a, hit, hit]
			space = "The pairs are %s: %d in all, each equally likely, and order doesn't matter." % ["; ".join(pairs), all]
		_:
			var nums := BasicProbabilitySituation.card_numbers(s)
			var ok := nums.filter(func(x): return BasicProbabilitySituation.card_hit(s, x))
			hit = ok.size()
			all = 6
			var ds: Array = s.digits.map(func(d): return str(d))
			lines = ["Three cards show the digits %s." % listing(ds), "They are put in a row at random to make a three-digit number."]
			var want := "even" if s.cond == "even" else "greater than %d" % s.above
			asked = "List the numbers and find the probability that the number is %s." % want
			space = "The numbers are %s: 3 × 2 × 1 = 6, all equally likely." % ", ".join(nums.map(func(x): return str(x)))
			hits_text = "The number is %s for %s." % [want, listing(ok.map(func(x): return str(x)))]
	var v := Q.new(hit, all)
	var ans := prob_ans(s, v)
	var out := {"answer": ans, "lines": lines, "asked": asked, "wrongs": wrongs + wr(s, Q.new(hit, all - hit), R_REST)}
	out.generic = fair(s, [Q.new(all - hit, all), Q.new(hit + 1, all), Q.new(hit, all + 1), Q.new(hit, all * 2)])
	out.methods = {"list-sample-space": method([space, hits_text, "P = n(A) ÷ n(U): " + ratio(s, hit, all), final_step(ans)], ans.values)}
	return out


static func _die_test(s: Dictionary, f: int) -> bool:
	match s.cond:
		"even":
			return f % 2 == 0
		"odd":
			return f % 2 == 1
	return f > s.m


# ── Complements ──────────────────────────────────────────────

func u_complement_given(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var e: Array = EVENTS[s.ctx % EVENTS.size()]
	var one := Q.new(1)
	var v := one.sub(s.p)
	var ans := prob_ans(s, v, "P(A′) = " if rep == "equation" else "probability = ")
	var out := {"answer": ans}
	var shown: String = T(s, s.p)
	if rep == "equation":
		out.lines = ["P(A) = %s" % shown]
		out.asked = "Find P(A′)."
	else:
		out.lines = ["The probability that %s is %s." % [e[0], shown]]
		out.asked = "Find the probability that %s." % e[1]
	out.wrongs = wr(s, s.p, R_EVENT)
	out.generic = []
	out.methods = {"one-minus": method(["A and A′ cover every outcome without overlapping, so P(A′) = 1 − P(A).", "1 − %s = %s" % [shown, T(s, v)], final_step(ans)], ans.values)}
	return out


func u_complement_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Array = BAGS[s.ctx % BAGS.size()]
	var heads: Array = []
	for i in s.counts.size():
		heads.append(colour(s, i).capitalize())
	var f: int = s.counts[s.target]
	var u: int = s.unit
	var v := Q.new(u - f, u)
	var ans := prob_ans(s, v)
	var name := colour(s, s.target)
	var others: Array = []
	for i in s.counts.size():
		if i != s.target:
			others.append(s.counts[i])
	var out := {"answer": ans}
	if s.kind == "prob":
		out.lines = ["The table gives the probability that a spinner lands on each colour. It always lands on one of them."]
		out.table = {"rows": [["Colour", heads], ["Probability", s.counts.map(func(x): return D(Q.new(x, u)))]]}
		out.asked = "Find the probability that the spinner does not land on %s." % name
		var ps: Array = others.map(func(x): return D(Q.new(x, u)))
		out.methods = {"one-minus": method(["Read P(%s) = %s. Not landing on %s is the complement." % [name, D(Q.new(f, u)), name], "1 − %s = %s" % [D(Q.new(f, u)), T(s, v)], final_step(ans)], ans.values),
			"count-complement": method(["'Not %s' is every other colour, so add their probabilities." % name, "%s = %s" % [plus(ps), T(s, v)], final_step(ans)], ans.values)}
	else:
		out.lines = ["%s holds %s of the colours in the table." % [c[0], c[1]]]
		out.table = {"rows": [["Colour", heads], ["Number", s.counts.map(func(x): return str(x))]]}
		out.asked = "One %s is taken at random. Find the probability that it is not %s." % [c[2], name]
		out.methods = {"one-minus": method(["There are %s = %d %s, so P(%s) = %s." % [plus(s.counts), u, c[1], name, ratio(s, f, u)], "P(not %s) = 1 − %s = %s" % [name, T(s, Q.new(f, u)), T(s, v)], final_step(ans)], ans.values),
			"count-complement": method(["There are %s = %d %s in all." % [plus(s.counts), u, c[1]], "%s = %d of them are not %s." % [plus(others), u - f, name], "P = n(A′) ÷ n(U): " + ratio(s, u - f, u), final_step(ans)], ans.values)}
	out.wrongs = wr(s, Q.new(f, u), R_EVENT) + wr(s, Q.new(s.counts.size() - 1, s.counts.size()), R_SAME_SHARE)
	out.generic = fair(s, [Q.new(f, u - f), Q.new(u - f, u + 1)])
	return out


func u_complement_count(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var all: int
	var n: int
	var out := {}
	var space: String
	var event: String
	if rep == "diagram":
		var ts := BasicProbabilitySituation.totals(s)
		all = ts.size()
		n = ts.count(s.k)
		out.lines = ["The table shows every total of two fair %s, one outcome in each cell: rows for the %s." % [thing(s), first_name(s)]]
		out.table = totals_grid(s)
		out.asked = "Find the probability that the total is not %d." % s.k
		space = "The table has %d × %d = %d equally likely cells." % [s.xs.size(), s.ys.size(), all]
		event = "%d cells show a total of %d" % [n, s.k]
		out.wrongs = wr(s, Q.new(1).sub(Q.new(1, BasicProbabilitySituation.distinct(ts).size())), R_SAME_SHARE)
	else:
		var b: Array = BAGS[s.ctx % BAGS.size()]
		all = s.big
		n = s.big / s.m
		out.lines = ["%s holds %s numbered 1 to %d, one of each." % [b[0], b[1], s.big]]
		out.asked = "One %s is taken at random. Find the probability that its number is not a multiple of %d." % [b[2], s.m]
		space = "There are %d equally likely %s." % [all, b[1]]
		event = "The multiples of %d run from %d to %d × %d = %d: %d of them" % [s.m, s.m, s.m, n, s.m * n, n]
		out.wrongs = []
	var v := Q.new(all - n, all)
	var ans := prob_ans(s, v)
	out.answer = ans
	out.wrongs = out.wrongs + wr(s, Q.new(n, all), R_EVENT)
	out.generic = fair(s, [Q.new(n, all - n), Q.new(all - n, all + 1), Q.new(all - n - 1, all), Q.new(all - n + 1, all)])
	out.methods = {"one-minus": method([space, "%s, so P(A) = %s." % [event, ratio(s, n, all)], "P(A′) = 1 − %s = %s" % [T(s, Q.new(n, all)), T(s, v)], final_step(ans)], ans.values),
		"count-complement": method([space, "%s, which leaves %d − %d = %d outcomes." % [event, all, n, all - n], "P = n(A′) ÷ n(U): " + ratio(s, all - n, all), final_step(ans)], ans.values)}
	return out


static func rule_lines(s: Dictionary) -> Array:
	if s.rule == "ends":
		return ["A total of %d or less wins a big prize. A total of %d or more wins a small prize. Any other total wins nothing." % [s.lo, s.hi]]
	return ["Equal numbers win a big prize. Numbers that differ by %d win a small prize. Anything else wins nothing." % s.d]


func u_complement_two_rules(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var w := BasicProbabilitySituation.rule_counts(s)
	var all: int = s.xs.size() * s.ys.size()
	var none: int = all - int(w[0]) - int(w[1])
	var v := Q.new(none, all)
	var ans := prob_ans(s, v)
	var out := {"answer": ans, "asked": "Find the probability that one round wins nothing."}
	if rep == "diagram":
		var what := "total" if s.rule == "ends" else "gap between the two numbers"
		out.lines = ["A stall runs a game with two fair %s. The table shows the %s for every outcome, one in each cell: rows for the %s." % [thing(s), what, first_name(s)]] + rule_lines(s)
		out.table = totals_grid(s) if s.rule == "ends" else gaps_grid(s)
	else:
		out.lines = ["A stall runs a game. " + faces_line(s)] + rule_lines(s)
	out.wrongs = wr(s, Q.new(all - int(w[0]), all), R_ONE_RULE) + wr(s, Q.new(all - int(w[1]), all), R_ONE_RULE) + wr(s, Q.new(int(w[0]) + int(w[1]), all), R_EVENT)
	out.generic = fair(s, [Q.new(1, 3), Q.new(none + 1, all), Q.new(none, all + 1)])
	var space := "There are %d × %d = %d equally likely outcomes." % [s.xs.size(), s.ys.size(), all]
	var big := "A big prize: %s = %d outcomes." % [plus(by_row(s, _big_test(s))), w[0]]
	var small := "A small prize: %s = %d outcomes." % [plus(by_row(s, _small_test(s))), w[1]]
	out.methods = {"one-minus": method([space + " Counting row by row:", big + " " + small, "No outcome wins both, so P(nothing) = 1 − %s − %s = %s" % [T(s, Q.new(w[0], all)), T(s, Q.new(w[1], all)), T(s, v)], final_step(ans)], ans.values),
		"count-complement": method([space + " Counting row by row:", big + " " + small, "That leaves %d − %d − %d = %d outcomes that win nothing." % [all, w[0], w[1], none], "P = n(A′) ÷ n(U): " + ratio(s, none, all), final_step(ans)], ans.values)}
	return out


static func _big_test(s: Dictionary) -> Callable:
	if s.rule == "ends":
		return func(x: int, y: int) -> bool: return x + y <= s.lo
	return func(x: int, y: int) -> bool: return x == y


static func _small_test(s: Dictionary) -> Callable:
	if s.rule == "ends":
		return func(x: int, y: int) -> bool: return x + y >= s.hi
	return func(x: int, y: int) -> bool: return absi(x - y) == s.d


# ── At least one ─────────────────────────────────────────────

func _at_least_one(s: Dictionary, ps: Array, out: Dictionary) -> Dictionary:
	var none := BasicProbabilitySituation.none_of(ps)
	var v := Q.new(1).sub(none)
	var ans := prob_ans(s, v)
	out.answer = ans
	out.wrongs = wr(s, BasicProbabilitySituation.exactly_one(ps), R_EXACTLY_ONE) + wr(s, BasicProbabilitySituation.total_of(ps), R_ADD_TRIALS) + wr(s, none, R_EVENT)
	var product := Q.new(1)
	for p in ps:
		product = product.mul(p)
	out.generic = fair(s, [product, ps[0], Q.new(1).sub(ps[0])])
	var qs: Array = ps.map(func(p): return T(s, Q.new(1).sub(p)))
	out.methods = {"at-least-one": method(["'At least one' is every case except 'none', so P(at least one) = 1 − P(none).",
		"Each trial fails with probability %s, and the trials are independent, so P(none) = %s = %s" % [listing(_unique(qs)), " × ".join(qs), T(s, none)],
		"1 − %s = %s" % [T(s, none), T(s, v)], final_step(ans)], ans.values)}
	return out


static func _unique(xs: Array) -> Array:
	var out: Array = []
	for x in xs:
		if not x in out:
			out.append(x)
	return out


func u_at_least_one_same(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Array = TRIALS[s.ctx % TRIALS.size()]
	var ps: Array = []
	for i in s.n:
		ps.append(s.p)
	var p := T(s, s.p)
	var q := T(s, Q.new(1).sub(s.p))
	var out := {"asked": "Find the probability that at least one %s %s." % [c[1], c[2]]}
	if rep == "diagram":
		out.lines = ["%s %s with probability %s, independently of the others. The tree shows two %s, where S means it %s." % [c[0], c[2], p, c[3], c[2]]]
		out.graph = {"kind": "tree", "first": ["S", "S′"], "second": ["S", "S′"], "p": [p, q], "q": [[p, q], [p, q]]}
	else:
		out.lines = ["%s %s with probability %s, independently of the others." % [c[0], c[2], p], c[4] % s.n]
	return _at_least_one(s, ps, out)


func u_at_least_one_different(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var verb: String = TRIES[s.ctx % TRIES.size()]
	var who: Array = NAMES.slice(0, s.n)
	var out := {"asked": "Find the probability that at least one of them %s." % verb}
	var parts: Array = []
	for i in s.n:
		parts.append("%s with probability %s" % [who[i], T(s, s.ps[i])])
	out.lines = ["%s each try once, independently of each other." % listing(who), "The chance that each one %s is: %s." % [verb, listing(parts)]]
	if rep == "diagram":
		var a := T(s, s.ps[0])
		var b := T(s, s.ps[1])
		var na := T(s, Q.new(1).sub(s.ps[0]))
		var nb := T(s, Q.new(1).sub(s.ps[1]))
		out.lines = ["%s and %s each try once, independently of each other. The tree shows A, that %s %s, and B, that %s %s." % [who[0], who[1], who[0], verb, who[1], verb]]
		out.graph = {"kind": "tree", "first": ["A", "A′"], "second": ["B", "B′"], "p": [a, na], "q": [[b, nb], [b, nb]]}
	return _at_least_one(s, s.ps, out)


# ── Relative frequency ───────────────────────────────────────

static func score_rows(s: Dictionary, heads: Array = []) -> Dictionary:
	var xs: Array = heads
	if xs.is_empty():
		for i in s.counts.size():
			xs.append(str(i + 1))
	return {"rows": [["Score", xs], ["Frequency", s.counts.map(func(c): return str(c))]]}


func u_rf_from_table(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Array = RF[s.ctx % RF.size()]
	var total: int = BasicProbabilitySituation.sum(s.counts)
	var f: int = s.counts[s.target]
	var v := Q.new(f, total)
	var ans := prob_ans(s, v, "relative frequency = ")
	var score: int = s.target + 1
	var out := {"answer": ans, "asked": "Find the relative frequency of a score of %d." % score}
	if rep == "graph":
		var xs: Array = []
		for i in s.counts.size():
			xs.append(i + 1)
		out.lines = ["%s is %s %d times. The bar chart shows the frequency of each score." % [c[0], c[1], total]]
		out.graph = {"kind": "bars", "xs": xs, "ys": s.counts}
	else:
		out.lines = ["%s is %s %d times. The table shows the frequency of each score." % [c[0], c[1], total]]
		out.table = score_rows(s)
	out.wrongs = wr(s, Q.new(1, s.counts.size()), R_SAME_SHARE) + wr(s, Q.new(f, total - f), R_REST)
	out.generic = fair(s, [Q.new(total - f, total), Q.new(f + 1, total), Q.new(f, total * 2)])
	out.methods = {"freq-over-trials": method(["The relative frequency is the frequency ÷ the number of trials.", "A score of %d has frequency %d, out of %d trials." % [score, f, total],
		ratio(s, f, total), final_step(ans)], ans.values)}
	return out


func u_rf_total_to_find(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var total: int = BasicProbabilitySituation.sum(s.counts)
	var f := BasicProbabilitySituation.rf_hits(s)
	var first: int = s.counts[s.from_score - 1]
	var v := Q.new(f, total)
	var ans := prob_ans(s, v)
	var out := {"answer": ans}
	var hit_step: String
	if s.grouped:
		var c: Array = CLASSES[s.ctx % CLASSES.size()]
		var rows: Array = [[c[0], ["Number of %s" % c[3]]]]
		for i in s.counts.size():
			rows.append(["%d ≤ %s < %d" % [s.edges[i], c[1], s.edges[i + 1]], [str(s.counts[i])]])
		var bound: int = s.edges[s.from_score - 1]
		out.table = {"rows": rows}
		out.lines = ["The table shows the %s at a depot, by group." % c[3]]
		out.asked = "One of these %s is chosen at random. Find the probability that %s is %d %s or more." % [c[3], c[5], bound, c[2]]
		hit_step = "The groups from %d %s up hold %s = %d %s." % [bound, c[2], plus(s.counts.slice(s.from_score - 1)), f, c[3]]
	else:
		var c: Array = RF[s.ctx % RF.size()]
		out.table = score_rows(s)
		out.lines = ["%s is %s many times. The table shows the frequency of each score." % [c[0], c[1]]]
		var event := "at least %d" % s.from_score if s.least else "exactly %d" % s.from_score
		out.asked = "Use the table to estimate the probability that the next %s scores %s." % [c[2], event]
		hit_step = "Score %d or more has frequency %s = %d." % [s.from_score, plus(s.counts.slice(s.from_score - 1)), f] if s.least else "A score of %d has frequency %d." % [s.from_score, f]
	out.wrongs = wr(s, Q.new(f, total - f), R_REST)
	if s.least:
		out.wrongs += wr(s, Q.new(f - first, total), R_BOUNDARY)
	out.generic = fair(s, [Q.new(total - f, total), Q.new(first, total), Q.new(f + 1, total), Q.new(f, total + 1)])
	out.methods = {"freq-over-trials": method(["The table has no total, so add the frequencies: %s = %d." % [plus(s.counts), total], hit_step,
		"The estimate is frequency ÷ trials: " + ratio(s, f, total), final_step(ans)], ans.values)}
	return out


func u_rf_graph_estimate(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = LONG_RUNS[s.ctx % LONG_RUNS.size()]
	var ans := prob_ans(s, s.settle)
	var out := {"answer": ans, "lines": [c.line], "asked": "Use the graph to estimate the probability that %s." % c.event}
	var x1: int = s.curve[-1][0]
	out.graph = {"kind": "cumfreq", "x0": 0, "x1": x1, "dx": s.dx, "y1": 1, "dy": 0.02, "curve": s.curve, "x_name": c.x, "y_name": "relative frequency"}
	out.wrongs = wr(s, s.early, R_SHORT_RUN)
	out.generic = fair(s, [Q.new(1).sub(s.settle), s.settle.add(Q.new(1, 10)), s.settle.sub(Q.new(1, 10)), s.settle.add(Q.new(6, 100))])
	out.methods = {"long-run": method(["The early points swing about, because a few trials say little. The first plotted point is %s." % D(s.early),
		"With many trials the curve settles: by %d trials it stays at about %s." % [x1, D(s.settle)],
		"The long-run value is the best estimate of the probability.", final_step(ans)], ans.values)}
	return out


func u_more_reliable(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = LONG_RUNS[s.ctx % LONG_RUNS.size()]
	var who: Array = s.names.map(func(i): return NAMES[i])
	var big: int = s.large
	var small: int = 1 - big
	var v := Q.new(s.hits[big], s.ns[big])
	var slip := Q.new(s.hits[small], s.ns[small])
	var ans := prob_ans(s, v)
	var out := {"answer": ans, "asked": "Use the more reliable test to estimate the probability that %s." % c.event}
	if rep == "table":
		out.lines = ["%s and %s each test %s. The table shows their results." % [who[0], who[1], c.of]]
		out.table = {"rows": [["", ["Trials", c.hit]], [who[0], [str(s.ns[0]), str(s.hits[0])]], [who[1], [str(s.ns[1]), str(s.hits[1])]]]}
	else:
		out.lines = ["%s and %s each test %s." % [who[0], who[1], c.of], "%s %s." % [who[0], c.test % [s.ns[0], s.hits[0]]], "%s %s." % [who[1], c.test % [s.ns[1], s.hits[1]]]]
	out.wrongs = wr(s, slip, R_SHORT_RUN)
	var mean: Q = v.add(slip).mul(Q.new(1, 2))
	out.generic = fair(s, [mean, Q.new(1).sub(v), Q.new(s.ns[big] - s.hits[big], s.ns[big]), v.add(Q.new(1, 20))])
	out.methods = {"freq-over-trials": method(["More trials give a more reliable estimate: %s's %d beat %s's %d." % [who[big], s.ns[big], who[small], s.ns[small]],
		"The estimate is frequency ÷ trials: " + ratio(s, s.hits[big], s.ns[big]), final_step(ans)], ans.values)}
	return out


func u_gamblers_fallacy(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := prob_ans(s, s.p)
	var out := {"answer": ans}
	var run: int = s.streak
	var m: int = s.m
	var why: String
	var count: String
	var run_chance := Q.new(1, 1 << (run + 1))
	match s.kind:
		"coin":
			var side := "heads" if s.heads else "tails"
			var other := "tails" if s.heads else "heads"
			var asked_side: String = side if s.same else other
			out.lines = ["A fair coin lands on %s %d times in a row." % [side, run]]
			out.asked = "Find the probability that the next toss lands on %s." % asked_side
			if s.same:
				out.wrongs = wr(s, run_chance, R_WHOLE_RUN)
			else:
				out.wrongs = wr(s, Q.new(1).sub(run_chance), R_DUE)
			why = "Each toss is independent: the coin has no memory of the last %d." % run
			count = "One of the 2 equally likely sides is %s, so P = 1/2." % asked_side
		"die":
			out.lines = ["A fair six-sided die has been rolled %d times and has not shown a %d." % [run, s.face]]
			out.asked = "Find the probability that the next roll shows a %d." % s.face
			out.wrongs = wr(s, Q.new(run + 1, m), R_DUE)
			why = "Each roll is independent: the die has no memory of the last %d." % run
			count = "One of the 6 equally likely faces is a %d, so P = 1/6." % s.face
		_:
			out.lines = ["A fair spinner has %d equal sectors, one of them red. It has been spun %d times and has not landed on red." % [m, run]]
			out.asked = "Find the probability that the next spin lands on red."
			out.wrongs = wr(s, Q.new(run + 1, m), R_DUE)
			why = "Each spin is independent: the spinner has no memory of the last %d." % run
			count = "One of the %d equally likely sectors is red, so P = 1/%d." % [m, m]
	out.generic = fair(s, [Q.new(1, m + 1), Q.new(m - 1, m), Q.new(1, m * 2), Q.new(1, m + run), Q.new(1, m * m)])
	out.methods = {"count-ratio": method([why, count, final_step(ans)], ans.values)}
	return out
