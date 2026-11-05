class_name TreeDiagramViews
extends ExtensionViews
## The views on the `tree-diagram` situation: one builder per unknown of t4-tree-diagram
## (FAL-739). It uses ConditionalViews' answers, tins and colours. An answer is exact on Paper 1,
## as the question writes its numbers, and to 3 s.f. on Paper 2; a branch read off the tree is
## exact on both.
##
## Representations: "diagram" (a two-stage tree of 2 or 3 branches at each fork, PlotView's `tree`
## with stage names: a missing branch shows a letter), "words" (a story) and "table" (a roster, or
## a game's scores).

const SKILL := "SL4.6.tree#"
const R_NOT_REDUCED := SKILL + "0"
const R_ADD_ALONG := SKILL + "1"
const R_ONE_ORDER := SKILL + "2"
const TYPE := "t4-tree-diagram#"
const R_PARENT := TYPE + "3"
const R_SKIP_BRANCH := TYPE + "4"
const R_SIGN := TYPE + "5"
const R_OTHER_COLOUR := TYPE + "6"
const R_NO_EXTRA := TYPE + "7"
const R_LAST_BRANCH := TYPE + "8"
const R_ONE_PATH := TYPE + "9"
const R_NO_WEIGHT := TYPE + "10"
const R_OPPOSITE := TYPE + "11"
const R_NO_SUBTRACT := TYPE + "12"
const R_EXACTLY_ONE := TYPE + "13"
const R_SWAP := TYPE + "14"
const R_ORDERS := TYPE + "15"
const R_EXTRA_FAIL := TYPE + "16"
const R_NOT_DIVIDED := TYPE + "17"
const R_ROOT := TYPE + "18"
const R_IN_TIN := TYPE + "19"
const R_LAST_OUT := TYPE + "20"
const R_NO_ROUND_ORDERS := TYPE + "21"
const R_TOP_ONLY := TYPE + "22"
const R_AT_LIMIT := TYPE + "23"
const R_KEPT_COUNT := TYPE + "24"
const R_KEPT_TOTAL := TYPE + "25"
const R_EARLY_TOTAL := TYPE + "26"

## Two stages: the story, the stage names, the branches at each, and each branch as a phrase.
const CHAINS := [
	{"line": "A scout picks a road each morning, and each trip ends in one of a few ways.", "heads": ["Road", "Trip"], "a": ["north", "ridge", "tunnel"], "b": ["safe", "raided", "delayed"], "af": "the scout takes the %s road", "bf": "the trip is %s"},
	{"line": "The weather on the flats changes how a caravan gets through.", "heads": ["Weather", "Caravan"], "a": ["storm", "dust", "clear"], "b": ["on time", "late", "lost"], "af": "the weather is %s", "bf": "the caravan is %s"},
	{"line": "A call goes out through one radio tower, and the signal comes back in one of a few ways.", "heads": ["Tower", "Signal"], "a": ["A", "B", "C"], "b": ["clear", "static", "silent"], "af": "the call goes through tower %s", "bf": "the signal is %s"},
	{"line": "A camp draws its water from one source, and then the water is tested.", "heads": ["Source", "Test"], "a": ["well", "river", "tank"], "b": ["safe", "cloudy", "unsafe"], "af": "the water comes from the %s", "bf": "the water tests %s"},
	{"line": "A battery comes from one of the camp's suppliers, and the meter then rates it.", "heads": ["Supplier", "Meter"], "a": ["forge", "depot", "yard"], "b": ["full", "weak", "dead"], "af": "the battery comes from the %s", "bf": "the battery reads %s"},
	{"line": "Seed comes in different stocks, and each seed then does one of a few things.", "heads": ["Stock", "Seed"], "a": ["old", "new", "wild"], "b": ["sprouts", "rots", "sleeps"], "af": "the seed is %s stock", "bf": "the seed %s"},
	{"line": "A traveller reaches the gate, and the guards then deal with them.", "heads": ["Traveller", "Gate"], "a": ["trader", "nomad", "medic"], "b": ["cleared", "searched", "held"], "af": "the traveller is a %s", "bf": "the traveller is %s"},
	{"line": "A part is made in one of the workshop's ways, and is then tried in an engine.", "heads": ["Made", "Engine"], "a": ["cast", "forged", "welded"], "b": ["fits", "jams", "snaps"], "af": "the part is %s", "bf": "the part %s"},
]
const THIRD := ["white", "black", "red", "blue"]
const ORDINAL := ["first", "second", "third", "fourth", "fifth"]
const COUNT := ["no", "one", "two", "three", "four", "five"]
const TRIES_STORY := [
	{"try": "radio scan", "win": "finds a signal"},
	{"try": "lock", "win": "opens"},
	{"try": "well", "win": "gives clean water"},
	{"try": "flare", "win": "lights"},
	{"try": "trap", "win": "catches something"},
	{"try": "engine start", "win": "fires"},
	{"try": "arrow", "win": "hits the target"},
	{"try": "seed", "win": "sprouts"},
]
const GAMES := ["a shooting range", "a dart board", "a bottle toss", "a knife throw", "a ring toss", "a sling contest", "a dice table", "a lever game"]
const ROLES := [["drivers", "medics", "guards"], ["cooks", "scouts", "mechanics"], ["farmers", "welders", "runners"], ["traders", "guards", "pilots"]]

const ASKS := ["complete-branch", "branch-in-terms-of-k", "branch-after-draw", "path-probability", "total-over-paths", "same-or-different",
	"at-least-one", "all-without-replacement", "draws-in-terms-of-n", "first-success-on-trial", "total-from-normals", "parameter-on-branch",
	"rounds-exceed-total", "selections-find-n"]
## Answers that aren't a probability in the usual slot, so `build` adds no near values.
const NOT_PROBABILITY := ["branch-in-terms-of-k", "draws-in-terms-of-n", "parameter-on-branch", "selections-find-n"]


func needs() -> Dictionary:
	var out := {}
	for u in ASKS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	if not has(unknown):
		return []
	if unknown in TreeDiagramSituation.P1_ONLY:
		return [1]
	return [2] if unknown in TreeDiagramSituation.P2_ONLY else [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = TreeDiagramSituation.export(s)
	if not unknown in NOT_PROBABILITY:
		out.generic.append_array(near(s, Q.of(out.answer.values.v)))
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func W(x: Variant) -> String:
	return BinomialViews.W(x.to_float() if x is Q else x)


## A number as the question writes its numbers.
static func F(s: Dictionary, v: Variant) -> String:
	return Fmt.num(v) if s.style == "frac" else D(v)


## "1/2 × 3/4 = 3/8": the product along a path, in the question's numbers.
static func times(s: Dictionary, xs: Array) -> String:
	return " × ".join(xs.map(func(x): return F(s, x)))


static func final_step(ans: Dictionary) -> String:
	return ConditionalViews.final_step(ans)


static func prob(s: Dictionary, label: String, v: Variant) -> Dictionary:
	return ConditionalViews.prob_ans(s, label, GdcKit.qf(v) if v is float else v)


## A branch of the tree, written as the tree writes it, on either paper.
static func branch(s: Dictionary, label: String, v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	ans.exact = true
	if s.style == "dec":
		ans.show = "dec"
	return ans


## Only a slip that is a probability, and shows cleanly at 3 s.f., is offered.
static func wr(s: Dictionary, v: Variant, ref: String) -> Array:
	var q: Q = GdcKit.qf(v) if v is float else v
	return [wrong({"v": q}, ref)] if shows(s, q) else []


static func probs(s: Dictionary, xs: Array) -> Array:
	var out: Array = []
	for x in xs:
		var q: Q = GdcKit.qf(x) if x is float else x
		if shows(s, q):
			out.append({"v": q})
	return out


## A value that reads as a probability once it is written: not 0.00 or 1.00 at 3 s.f.
static func shows(s: Dictionary, q: Q) -> bool:
	return q.to_float() >= 0.001 and q.to_float() <= 0.99 and TreeDiagramSituation.fits(s, q)


## Near values, written as the answer is: a fraction next to it, or a step off it.
static func near(s: Dictionary, v: Q) -> Array:
	var xs: Array = []
	if s.style == "frac" and s.paper == 1:
		for k in [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [2, 1], [-1, 1], [1, -1]]:
			if v.d + k[1] > 0:
				xs.append(Q.new(v.n + k[0], v.d + k[1]))
		for d in [3, 4, 5, 6, 8]:
			for n in range(1, d):
				xs.append(Q.new(n, d))
	else:
		var unit := Q.new(1, 100)
		for k in [1, -1, 2, -2, 3, -3, 5, -5, 8, -8]:
			xs.append(v.add(unit.mul(Q.new(k))))
	return probs(s, xs)


static func chain(s: Dictionary) -> Dictionary:
	return CHAINS[s.ctx]


static func thing(s: Dictionary) -> String:
	return ConditionalViews.THINGS[s.thing]


## The word for one of them: "tokens" gives "token".
static func one(s: Dictionary) -> String:
	return thing(s).trim_suffix("s")


static func colour(s: Dictionary, i: int) -> String:
	var pair: Array = ConditionalViews.COLOURS[s.cols]
	return THIRD[s.cols] if i == 2 else pair[i]


static func colours(s: Dictionary) -> Array:
	return range(s.counts.size()).map(func(i): return colour(s, i))


## "A tin holds 5 red, 3 blue and 4 white fuses."
static func tin(s: Dictionary) -> String:
	var bits: Array = []
	for i in s.counts.size():
		bits.append("%d %s" % [s.counts[i], colour(s, i)])
	var words: String = " and ".join(bits) if bits.size() == 2 else "%s, %s and %s" % bits
	return "A tin holds %s %s." % [words, thing(s)]


static func draw_line(s: Dictionary) -> String:
	match s.mode:
		"w":
			return "A %s is drawn at random and put back, and then a second %s is drawn." % [one(s), one(s)]
		"add":
			return "A %s is drawn at random and put back with one more of the same colour, and then a second %s is drawn." % [one(s), one(s)]
	return "Two %s are drawn at random, one after the other, without replacement." % thing(s)


## The tree for a story, or a tin. marks replaces branch labels: "1" at the first fork, "1,0" later.
static func tree(s: Dictionary, marks: Dictionary = {}) -> Dictionary:
	var heads: Array = ["First draw", "Second draw"] if s.bag else chain(s).heads
	var a: Array = colours(s) if s.bag else chain(s).a.slice(0, s.n1)
	var b: Array = colours(s) if s.bag else chain(s).b.slice(0, s.n2)
	var out := {"kind": "tree", "heads": heads, "first": a, "second": b, "p": [], "q": []}
	for i in s.n1:
		out.p.append(marks.get(str(i), F(s, s.first[i])))
		var row: Array = []
		for j in s.n2:
			row.append(marks.get("%d,%d" % [i, j], F(s, s.second[i][j])))
		out.q.append(row)
	return out


## The two branches in words, for a tree or a tin.
static func path_words(s: Dictionary, i: int, j: int) -> String:
	if s.bag:
		return "the first %s is %s and the second is %s" % [one(s), colour(s, i), colour(s, j)]
	var c := chain(s)
	return "%s and %s" % [c.af % c.a[i], c.bf % c.b[j]]


## The same in the shortest form, for working: "north, then safe".
static func path_short(s: Dictionary, i: int, j: int) -> String:
	if s.bag:
		return "%s, then %s" % [colour(s, i), colour(s, j)]
	return "%s, then %s" % [chain(s).a[i], chain(s).b[j]]


## "red, then blue: 2/5 × 1/4 = 1/10" for every path listed, by [i, j].
static func path_list(s: Dictionary, paths: Array) -> String:
	var bits: Array = []
	for p in paths:
		var x: Q = s.first[p[0]]
		var y: Q = s.second[p[0]][p[1]]
		bits.append("%s: %s = %s" % [path_short(s, p[0], p[1]), times(s, [x, y]), F(s, x.mul(y))])
	return "; ".join(bits)


## Multiplying the branches along each path, added up.
static func path_sum(s: Dictionary, paths: Array) -> Q:
	var out := Q.new(0)
	for p in paths:
		out = out.add(s.first[p[0]].mul(s.second[p[0]][p[1]]))
	return out


static func path_sum_text(s: Dictionary, paths: Array) -> String:
	return " + ".join(paths.map(func(p): return F(s, s.first[p[0]].mul(s.second[p[0]][p[1]]))))


## Paths from each first branch into the second-stage outcome j.
static func paths_into(s: Dictionary, j: int) -> Array:
	return range(s.n1).map(func(i): return [i, j])


## "k/2", "2k", "k" for a multiple of k.
static func kt(c: Q) -> String:
	if c.eq(Q.new(1)):
		return "k"
	var top := "k" if c.n == 1 else "%dk" % c.n
	return top if c.d == 1 else "%s/%d" % [top, c.d]


# ── Filling in a branch ──────────────────────────────────────

func u_complete_branch(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := branch(s, "x = ", s.v)
	var one_q := Q.new(1)
	var mark := str(s.i) if s.stage == 1 else "%d,%d" % [s.i, s.j]
	var at: Array = s.first if s.stage == 1 else s.second[s.i]
	var others: Array = []
	for k in at.size():
		if k != (s.i if s.stage == 1 else s.j):
			others.append(at[k])
	var out := {"lines": [chain(s).line, "The tree shows the probabilities, with one branch marked x."], "asked": "Find x.", "answer": ans, "table": null, "graph": tree(s, {mark: "x"})}
	out.wrongs = []
	if s.stage == 2:
		out.wrongs += wr(s, one_q.sub(s.first[s.i]), R_PARENT)
	if others.size() == 2:
		out.wrongs += wr(s, one_q.sub(others[0]), R_SKIP_BRANCH)
	out.generic = probs(s, [others[0]])
	var sum := Q.new(0)
	for o in others:
		sum = sum.add(o)
	var fork: String = "first fork" if s.stage == 1 else "fork after %s" % chain(s).a[s.i]
	var other_text := " − ".join(others.map(func(o): return F(s, o)))
	out.methods = {"branches-add-to-one": method(["The branches at the %s add to 1." % fork, "x = 1 − %s = %s" % [other_text, F(s, one_q.sub(sum))], final_step(ans)], ans.values)}
	return out


func u_branch_in_terms_of_k(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Q = s.a1 if s.stage == 1 else s.a2
	var txt := kt(c)
	var ans := Answer.make("form", {"c": c, "text": "1 − " + txt}, {"parts": ["x = 1 − ", {"slot": "c"}, "k"]}, "x = ")
	ans.exact = true
	var f := chain(s)
	var spec := {"kind": "tree", "heads": f.heads, "first": f.a.slice(0, 2), "second": f.b.slice(0, 2),
		"p": [kt(s.a1), "x" if s.stage == 1 else "1 − " + kt(s.a1)],
		"q": [[kt(s.a2), "x" if s.stage == 2 else "1 − " + kt(s.a2)], [kt(s.a2), "x" if s.stage == 2 else "1 − " + kt(s.a2)]]}
	var out := {"lines": [f.line, "The tree shows the probabilities in terms of k, with x on the missing branch%s." % ("" if s.stage == 1 else "es")], "asked": "Write x in terms of k.", "answer": ans, "table": null, "graph": spec}
	out.wrongs = [wrong({"c": c, "text": "%s − 1" % txt, "shape": "reversed"}, R_SIGN)]
	if s.stage == 2 and not s.a1.eq(s.a2):
		out.wrongs.append(wrong({"c": s.a1, "text": "1 − " + kt(s.a1)}, R_PARENT))
	var back := Q.new(c.d, c.n)
	out.generic = [{"c": c, "text": "1 + " + txt, "shape": "plus"}, {"c": c, "text": txt, "shape": "same"}, {"c": back, "text": "1 − " + kt(back)},
		{"c": c.mul(Q.new(2)), "text": "1 − " + kt(c.mul(Q.new(2)))}, {"c": c.add(Q.new(1)), "text": "1 − " + kt(c.add(Q.new(1)))}]
	var other := "The other branch at %s with x is %s." % ["the fork" if s.stage == 1 else "each fork", txt]
	out.methods = {"branches-add-to-one": method([other, "The branches at a fork add to 1, so x + %s = 1." % txt, final_step(ans)], ans.values)}
	return out


func u_branch_after_draw(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := prob(s, "x = ", s.v)
	var t := TreeDiagramSituation.total(s)
	var c: Array = s.counts
	var marks := {"%d,%d" % [s.i, s.j]: "x", "%d,%d" % [s.i, 1 - s.j]: "y"}
	var out := {"lines": [tin(s), draw_line(s), "The tree shows the probabilities, with x and y on two branches."], "asked": "Find x.", "answer": ans, "table": null, "graph": tree(s, marks)}
	var same: bool = s.i == s.j
	out.wrongs = []
	if s.mode == "wo":
		if same:
			out.wrongs += wr(s, Q.new(c[s.j], t), R_NOT_REDUCED) + wr(s, Q.new(c[s.j] - 1, t), R_KEPT_TOTAL) + wr(s, Q.new(c[s.j], t - 1), R_KEPT_COUNT)
		else:
			out.wrongs += wr(s, Q.new(c[s.j], t), R_KEPT_TOTAL) + wr(s, Q.new(c[s.j] - 1, t - 1), R_OTHER_COLOUR)
	else:
		out.wrongs += wr(s, Q.new(c[s.j] + 1, t) if same else Q.new(c[s.j], t), R_NO_EXTRA)
		if same:
			out.wrongs += wr(s, Q.new(c[s.j], t + 1), R_NO_EXTRA)
	out.generic = probs(s, [Q.new(1).sub(s.v)])
	var after: int = t - 1 if s.mode == "wo" else t + 1
	var left: int = int(round(s.v.to_float() * after))
	var change: String = "%s %s is gone" % ["The first", one(s)] if s.mode == "wo" else "One more %s %s has been added" % [colour(s, s.i), one(s)]
	var fr := "%d/%d" % [left, after]
	out.methods = {"recount-after-draw": method(["The first %s was %s. %s, so the tin now holds %d %s." % [one(s), colour(s, s.i), change, after, thing(s)],
		"Of those, %d %s %s, so x = %s." % [left, "is" if left == 1 else "are", colour(s, s.j), fr], final_step(ans)], ans.values)}
	return out


# ── Paths ────────────────────────────────────────────────────

func u_path_probability(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := prob(s, "probability = ", s.v)
	var a: Q = s.first[s.i]
	var b: Q = s.second[s.i][s.j]
	var out := {"answer": ans, "table": null, "asked": "Find the probability that %s." % path_words(s, s.i, s.j)}
	if rep == "diagram":
		out.lines = [tin(s), draw_line(s), "The tree shows the probabilities."] if s.bag else [chain(s).line, "The tree shows the probabilities."]
		out.graph = tree(s)
	else:
		out.lines = [tin(s), draw_line(s)]
	out.wrongs = wr(s, a.add(b), R_ADD_ALONG) + wr(s, b, R_LAST_BRANCH)
	if s.bag and s.mode == "wo":
		out.wrongs += wr(s, TreeDiagramSituation.path(s, [s.i, s.j], "w"), R_NOT_REDUCED if s.i == s.j else R_KEPT_TOTAL)
	out.generic = probs(s, [a, Q.new(1).sub(s.v)])
	var along := "Follow the path %s: the branches are %s and %s." % [path_short(s, s.i, s.j), F(s, a), F(s, b)]
	var mult := "Multiply along it: %s" % times(s, [a, b])
	var every: Array = []
	for x in s.n1:
		for y in s.n2:
			every.append([x, y])
	var lst: Array = every if every.size() <= 4 else every.filter(func(p): return p[0] == s.i)
	var cap := "List the paths" if every.size() <= 4 else "List the paths through %s" % (colour(s, s.i) if s.bag else chain(s).a[s.i])
	out.methods = {"multiply-add": method([along, mult, final_step(ans)], ans.values),
		"list-outcomes": method(["%s: %s." % [cap, path_list(s, lst)], "The one you want is %s." % path_short(s, s.i, s.j), final_step(ans)], ans.values)}
	return out


func u_total_over_paths(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := prob(s, "probability = ", s.v)
	var out := {"answer": ans, "table": null}
	var paths := paths_into(s, s.j)
	var named: String
	if rep == "words":
		var cs: Array = []
		var wanted: String = colour({"cols": s.cols}, 0)
		var other: String = colour({"cols": s.cols}, 1)
		for i in s.n1:
			cs.append("Crate %s holds %d %s and %d %s %s." % ["ABC"[i], s.crates[i][0], wanted, s.crates[i][1], other, ConditionalViews.THINGS[s.thing]])
		var first: String = "A crate is chosen at random, and a %s is then drawn at random from it." % ConditionalViews.THINGS[s.thing].trim_suffix("s")
		if s.paper == 2:
			var chances: Array = []
			for i in s.n1:
				chances.append("%s with probability %s" % ["ABC"[i], D(s.first[i])])
			first = "One crate is chosen: %s. A %s is then drawn at random from it." % [", ".join(chances), ConditionalViews.THINGS[s.thing].trim_suffix("s")]
		out.lines = cs + [first]
		out.asked = "Find the probability that the %s is %s." % [ConditionalViews.THINGS[s.thing].trim_suffix("s"), wanted]
		named = wanted
	else:
		var c := chain(s)
		out.lines = [c.line, "The tree shows the probabilities."]
		out.graph = tree(s)
		out.asked = "Find the probability that %s." % (c.bf % c.b[s.j])
		named = c.b[s.j]
	var plain := Q.new(0)
	for i in s.n1:
		plain = plain.add(s.second[i][s.j])
	var one_path: Q = s.first[s.i].mul(s.second[s.i][s.j])
	out.wrongs = wr(s, one_path, R_ONE_PATH)
	if rep == "diagram" or s.paper == 2:
		out.wrongs += wr(s, plain, R_NO_WEIGHT)
	out.generic = probs(s, [s.first[0], Q.new(1).sub(s.v)])
	# A crate's chance is written as the question writes it, on Paper 2 a decimal.
	var chance := func(x: Q) -> String:
		return D(x) if rep == "words" and s.paper == 2 else F(s, x)
	var worked := func(label: String, p: Array) -> String:
		var x: Q = s.first[p[0]]
		var y: Q = s.second[p[0]][p[1]]
		return "%s: %s × %s = %s" % [label, chance.call(x), F(s, y), F(s, x.mul(y))]
	var into_steps: Array = []
	for p in paths:
		into_steps.append(worked.call("ABC"[p[0]] if rep == "words" else path_short(s, p[0], p[1]), p))
	var totals := Fmt.num(s.v) if s.style == "frac" else D(s.v)
	var multi := method(["Find every path that ends in %s." % named, "Multiply along each: %s." % "; ".join(into_steps), "Add them: %s = %s" % [path_sum_text(s, paths), totals], final_step(ans)], ans.values)
	var rest_paths: Array = []
	var rest_steps: Array = []
	for j in s.n2:
		if j != s.j:
			for i in s.n1:
				rest_paths.append([i, j])
				var label: String = "%s, then %s" % ["ABC"[i], colour({"cols": s.cols}, j)] if rep == "words" else path_short(s, i, j)
				rest_steps.append(worked.call(label, [i, j]))
	var rest := path_sum(s, rest_paths)
	out.methods = {"multiply-add": multi,
		"list-outcomes": method(["List the paths that end in %s: %s." % [named, "; ".join(into_steps)], "Add them: %s = %s" % [path_sum_text(s, paths), totals], final_step(ans)], ans.values),
		"complement-paths": method(["Find the paths that do not end in %s: %s." % [named, "; ".join(rest_steps)], "They add to %s = %s." % [path_sum_text(s, rest_paths), F(s, rest)], "Subtract from 1: 1 − %s = %s" % [F(s, rest), totals], final_step(ans)], ans.values)}
	return out


func u_same_or_different(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := prob(s, "probability = ", s.v)
	var same_words := "the two %s are the same colour" % thing(s)
	var diff_words := "the two %s are different colours" % thing(s)
	var want: String = same_words if s.form == "same" else diff_words
	var out := {"answer": ans, "table": null, "asked": "Find the probability that %s." % want, "lines": [tin(s), draw_line(s)]}
	if rep == "diagram":
		out.lines.append("The tree shows the probabilities.")
		out.graph = tree(s)
	var plain: Q = TreeDiagramSituation.same_colour(s, "w")
	var used: Q = plain if s.form == "same" else Q.new(1).sub(plain)
	out.wrongs = wr(s, Q.new(1).sub(s.v), R_OPPOSITE)
	if s.mode == "wo":
		out.wrongs += wr(s, used, R_NOT_REDUCED if s.form == "same" else R_KEPT_TOTAL)
	if s.form == "diff" and s.n1 == 2:
		out.wrongs += wr(s, TreeDiagramSituation.path(s, [0, 1]), R_ONE_ORDER)
	out.generic = probs(s, [s.first[0], s.first[1].mul(s.first[0])])
	var same_paths: Array = range(s.n1).map(func(i): return [i, i])
	var diff_paths: Array = []
	for i in s.n1:
		for j in s.n1:
			if i != j:
				diff_paths.append([i, j])
	var right: Array = same_paths if s.form == "same" else diff_paths
	var wrong_paths: Array = diff_paths if s.form == "same" else same_paths
	var v_text := F(s, s.v)
	var rest := path_sum(s, wrong_paths)
	var order: String = "Both orders count." if s.form == "diff" else "Each colour gives one path."
	var multi := method([order + " Multiply along each path: %s." % path_list(s, right), "Add them: %s = %s" % [path_sum_text(s, right), v_text], final_step(ans)], ans.values)
	out.methods = {"multiply-add": multi,
		"list-outcomes": method(["List the ordered pairs you want, with their probabilities: %s." % path_list(s, right), "Add them: %s = %s" % [path_sum_text(s, right), v_text], final_step(ans)], ans.values),
		"complement-paths": method(["Find the paths you do not want: %s." % path_list(s, wrong_paths), "They add to %s = %s." % [path_sum_text(s, wrong_paths), F(s, rest)], "Subtract from 1: 1 − %s = %s" % [F(s, rest), v_text], final_step(ans)], ans.values)}
	return out


func u_at_least_one(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := prob(s, "probability = ", s.v)
	var want: String = colour(s, s.target)
	var other: int = 1 - s.target
	var lines: Array = [tin(s)]
	if s.draws == 2:
		lines.append(draw_line(s))
	else:
		lines.append("Three %s are drawn at random, one after the other, without replacement." % thing(s))
	var out := {"answer": ans, "table": null, "lines": lines, "asked": "Find the probability that at least one of the %s is %s." % [thing(s), want]}
	if rep == "diagram":
		lines.append("The tree shows the probabilities.")
		out.graph = tree(s)
	var all_seq: Array = range(s.draws).map(func(_x): return other)
	var none := TreeDiagramSituation.path(s, all_seq)
	var once := TreeDiagramSituation.exactly_one(s)
	out.wrongs = wr(s, none, R_NO_SUBTRACT) + wr(s, Q.new(1).sub(TreeDiagramSituation.path(s, all_seq, "w")), R_NOT_REDUCED) + wr(s, once, R_EXACTLY_ONE)
	out.generic = probs(s, [Q.new(s.counts[s.target], TreeDiagramSituation.total(s))])
	var t := TreeDiagramSituation.total(s)
	var c: int = s.counts[other]
	var fracs: Array = []
	for k in s.draws:
		fracs.append("%d/%d" % [c - k, t - k])
	var bit := "No %s means every draw is %s." % [want, colour(s, other)]
	var mult := "P(none) = %s = %s" % [" × ".join(fracs), Fmt.num(none)]
	var comp := method([bit, mult, "Subtract from 1: 1 − %s = %s" % [Fmt.num(none), Fmt.num(s.v)], final_step(ans)], ans.values)
	var groups: Array = []
	var vals: Array = []
	for hits in range(1, s.draws + 1):
		var seq: Array = []
		for k in s.draws:
			seq.append(s.target if k < hits else other)
		var ways := roundi(BinomialSituation.comb(s.draws, hits))
		var one_way := TreeDiagramSituation.path(s, seq)
		var value: Q = one_way.mul(Q.new(ways))
		var left: Array = s.counts.duplicate()
		var bits: Array = []
		for k in s.draws:
			bits.append("%d/%d" % [left[seq[k]], t - k])
			left[seq[k]] -= 1
		var along := " × ".join(bits)
		vals.append(value)
		var word: String = {1: "One", 2: "Two", 3: "Three"}[hits]
		groups.append("%s %s: %s = %s" % [word, want, "%d × %s" % [ways, along] if ways > 1 else along, Fmt.num(value)])
	var add := method(["Split by how many are %s. Each order of the same colours has the same probability." % want, "; ".join(groups) + ".", "Add them: %s = %s" % [" + ".join(vals.map(func(x): return Fmt.num(x))), Fmt.num(s.v)], final_step(ans)], ans.values)
	out.methods = {"complement-paths": comp, "multiply-add": add}
	return out


func u_all_without_replacement(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := prob(s, "probability = ", s.v)
	var t := TreeDiagramSituation.total(s)
	var n: int = s.counts[s.target]
	var out := {"answer": ans, "table": null}
	var name: String
	if rep == "table":
		var roles: Array = ROLES[s.cols]
		name = roles[s.target]
		out.table = {"rows": [["Job", roles], ["People", s.counts.map(func(x): return str(x))]]}
		out.lines = ["The table shows the people at a camp.", "Three of them are chosen at random, one after the other, for a night watch."]
		out.asked = "Find the probability that all three are %s." % name
	else:
		name = colour(s, s.target)
		out.lines = [tin(s), "Three %s are drawn at random, one after the other, without replacement." % thing(s)]
		out.asked = "Find the probability that all three are %s." % name
	var fr: Array = ["%d/%d" % [n, t], "%d/%d" % [n - 1, t - 1], "%d/%d" % [n - 2, t - 2]]
	var tgt: int = s.target
	out.wrongs = wr(s, TreeDiagramSituation.path(s, [tgt, tgt, tgt], "w"), R_NOT_REDUCED)
	out.wrongs += wr(s, Q.new(n * (n - 1) * (n - 2), t * t * t), R_KEPT_TOTAL)
	out.wrongs += wr(s, Q.new(n, t).add(Q.new(n - 1, t - 1)).add(Q.new(n - 2, t - 2)), R_ADD_ALONG)
	out.generic = probs(s, [Q.new(n, t), Q.new(n * (n - 1), t * (t - 1)), Q.new(n - 2, t - 2)])
	var mult := "Multiply: %s" % " × ".join(fr)
	out.methods = {"multiply-add": method(["This is one path of three branches: %s, %s, %s. One has gone before each later branch, so the count and the total each fall by 1." % [name, name, name], mult, final_step(ans)], ans.values),
		"recount-after-draw": method(["The first pick: %d of %d. One has gone, so the second pick is %d of %d, and the third %d of %d." % [n, t, n - 1, t - 1, n - 2, t - 2], mult, final_step(ans)], ans.values)}
	return out


func u_draws_in_terms_of_n(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var g: int = s.big
	var col: String = colour(s, 0)
	var out := {"lines": ["A tin holds n %s. Of these, %d are %s and the rest are %s." % [thing(s), g, col, colour(s, 1)], "%s are drawn at random, one after the other, without replacement." % thing(s).capitalize()], "table": null}
	var ans: Dictionary
	if s.form == "one":
		ans = Answer.make("form", {"a": Q.new(g), "text": "%d/n" % g}, {"parts": [{"slot": "a"}, "/n"]}, "probability = ")
		out.asked = "Find, in terms of n, the probability that the first %s is %s." % [one(s), col]
		out.wrongs = [wrong({"a": Q.new(g), "text": "%d/(n − 1)" % g, "shape": "after"}, R_EARLY_TOTAL)]
		out.generic = [{"a": Q.new(g - 1), "text": "%d/n" % (g - 1)}, {"a": Q.new(g + 1), "text": "%d/n" % (g + 1)}, {"a": Q.new(g), "text": "n/%d" % g, "shape": "flip"}]
		out.methods = {"recount-after-draw": method(["There are n %s, and %d of them are %s." % [thing(s), g, col], "Nothing has been drawn yet, so the probability is %d out of n." % g, _form_end(ans)], ans.values)}
	else:
		var top := g * (g - 1)
		ans = Answer.make("form", {"a": Q.new(top), "text": "%d/(n(n − 1))" % top}, {"parts": [{"slot": "a"}, "/(n(n − 1))"]}, "probability = ")
		out.asked = "Find, in terms of n, the probability that the first two %s are %s." % [thing(s), col]
		out.wrongs = [wrong({"a": Q.new(g * g), "text": "%d/n²" % (g * g), "shape": "power"}, R_NOT_REDUCED),
			wrong({"a": Q.new(top), "text": "%d/n²" % top, "shape": "power2"}, R_KEPT_TOTAL),
			wrong({"a": Q.new(g), "text": "%d/n + %d/(n − 1)" % [g, g - 1], "shape": "sum"}, R_ADD_ALONG)]
		out.generic = [{"a": Q.new(g * g), "text": "%d/(n(n − 1))" % (g * g)}, {"a": Q.new(g * (g + 1)), "text": "%d/(n(n − 1))" % (g * (g + 1))}]
		out.methods = {"recount-after-draw": method(["The first is %s: %d out of n." % [col, g], "That leaves %d %s out of n − 1 %s." % [g - 1, col, thing(s)], "Multiply: %d/n × %d/(n − 1)" % [g, g - 1], _form_end(ans)], ans.values)}
	ans.exact = true
	out.answer = ans
	return out


static func _form_end(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


# ── One event, repeated ──────────────────────────────────────

func u_first_success_on_trial(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := prob(s, "probability = ", s.v)
	var out := {"answer": ans, "table": null}
	var k: int = s.k
	var hit: String
	var nope: String
	var p_text: String
	var q_text: String
	if s.source == "normal":
		var c: Dictionary = NormalUnknownViews.CONTEXTS[s.ctx]
		var it: Dictionary = NormalProbabilityViews.ITEMS[s.ctx]
		out.lines = ["%s are normally distributed with mean %d%s and standard deviation %d%s." % [c.what, s.mu, c.unit, s.sg, c.unit]]
		hit = "has a %s of more than %d%s" % [it.attr, s.lim, c.unit]
		if s.form == "first":
			out.lines.append("%s are checked at random, one at a time." % it.items.capitalize())
			out.asked = "Find the probability that the first one that %s is the %s one checked." % [hit, ORDINAL[k - 1]]
		else:
			out.lines.append("%s %s are chosen at random and checked in turn." % [COUNT[k].capitalize(), it.items])
			out.asked = "Find the probability that the %s is the only one that %s." % [ORDINAL[k - 1], hit]
		p_text = W(s.pf)
		q_text = W(1.0 - s.pf)
	else:
		var c: Dictionary = TRIES_STORY[s.ctx]
		p_text = F(s, s.p)
		q_text = F(s, Q.new(1).sub(s.p))
		hit = c.win
		out.lines = ["Each %s %s with probability %s, independently of the others." % [c.try, c.win, p_text]]
		if s.form == "first":
			out.lines.append("A scavenger tries one %s after another." % c.try)
			out.asked = "Find the probability that the first %s that %s is the %s." % [c.try, c.win, ORDINAL[k - 1]]
		else:
			out.lines.append("A scavenger tries %s of them, one after another." % COUNT[k])
			out.asked = "Find the probability that the %s is the only one that %s." % [ORDINAL[k - 1], c.win]
	var pv: Variant = s.pf if s.source == "normal" else s.p
	var qv: Variant = 1.0 - s.pf if s.source == "normal" else Q.new(1).sub(s.p)
	var pow_of := func(x: Variant, n: int) -> Variant:
		return pow(x, n) if x is float else TreeDiagramSituation.power(x, n)
	var mul_of := func(a: Variant, b: Variant) -> Variant:
		return a * b if a is float else a.mul(b)
	var swap: Variant = mul_of.call(pow_of.call(pv, k - 1), qv)
	var orders: Variant = s.v * k if s.v is float else s.v.mul(Q.new(k))
	var extra: Variant = mul_of.call(s.v, qv)
	out.wrongs = wr(s, swap, R_SWAP) + wr(s, orders, R_ORDERS) + wr(s, extra, R_EXTRA_FAIL)
	out.generic = probs(s, [pv, qv])
	var bits: Array = []
	var seq: Array = []
	for i in k - 1:
		bits.append(q_text)
		seq.append("miss")
	bits.append(p_text)
	seq.append("hit")
	var setup: Array = []
	if s.source == "normal":
		setup.append("normalcdf gives the chance that one %s: %s. The other branch is 1 − %s = %s." % [hit, p_text, p_text, q_text])
	var path_step := "Call it a hit when one %s. The order is fixed: %d %s, then a hit, so there is one path." % [hit, k - 1, "miss" if k == 2 else "misses"]
	var along := "Multiply along it: %s" % " × ".join(bits)
	var one_seq := "Call it a hit when one %s. List the outcome: %s. It is the only one, because the order is fixed." % [hit, ", ".join(seq)]
	out.methods = {"multiply-add": method(setup + [path_step, along, final_step(ans)], ans.values),
		"list-outcomes": method(setup + [one_seq, along, final_step(ans)], ans.values)}
	return out


func u_total_from_normals(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Dictionary = NormalUnknownViews.CONTEXTS[s.ctx]
	var it: Dictionary = NormalProbabilityViews.ITEMS[s.ctx]
	var ans := prob(s, "probability = ", s.v)
	var pct := roundi(s.share.to_float() * 100.0)
	var lines: Array = ["Workshop A makes %d%% of the %s at a camp, and workshop B makes the rest." % [pct, it.items],
		"For A, the %s is normally distributed with mean %d%s and standard deviation %d%s." % [it.attr, s.mu[0], c.unit, s.sg[0], c.unit],
		"For B, the %s is normally distributed with mean %d%s and standard deviation %d%s." % [it.attr, s.mu[1], c.unit, s.sg[1], c.unit]]
	var out := {"lines": lines, "answer": ans, "table": null}
	var event := "less than %d%s" % [s.lim, c.unit]
	var a0 := TreeDiagramSituation.area(s, 0)
	var a1 := TreeDiagramSituation.area(s, 1)
	var pa: float = s.share.to_float()
	var share: String = D(s.share)
	var rest: String = D(Q.new(1).sub(s.share))
	# The working carries on from the figures it shows, so each line can be followed on a calculator.
	var path0: String = W(pa * W(a0).to_float())
	var path1: String = W((1.0 - pa) * W(a1).to_float())
	var num: String = W(path0.to_float() + path1.to_float())
	var st := ["The first branches are A, %s, and B, %s." % [share, rest],
		"normalcdf gives the second branches: for A, %s; for B, %s." % [W(a0), W(a1)],
		"Multiply along: %s × %s = %s and %s × %s = %s." % [share, W(a0), path0, rest, W(a1), path1]]
	if s.form == "total":
		out.asked = "One of the %s is chosen at random. Find the probability that its %s is %s." % [it.items, it.attr, event]
		out.wrongs = wr(s, s.path0, R_ONE_PATH) + wr(s, a0 + a1, R_NO_WEIGHT)
		out.generic = probs(s, [a0, a1, 1.0 - s.num])
		st.append("Add the paths: %s + %s = %s. %s" % [path0, path1, num, final_step(ans)])
	else:
		out.asked = "One of the %s is chosen at random, and its %s is %s. Find the probability that it came from workshop A." % [it.items, it.attr, event]
		out.wrongs = wr(s, s.path0, R_NOT_DIVIDED)
		out.generic = probs(s, [a0, s.num, pa, 1.0 - s.v])
		st.append("Add the paths: %s + %s = %s. Divide the path through A by the total: %s ÷ %s" % [path0, path1, num, path0, num])
		st.append(final_step(ans))
	out.methods = {"multiply-add": method(st, ans.values)}
	return out


# ── Equations ────────────────────────────────────────────────

func u_parameter_on_branch(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v: Q = s.v
	var ans := Answer.make("number", {"v": v}, {}, "k = ")
	ans.exact = true
	var f := chain(s)
	var spec := {"kind": "tree", "heads": f.heads, "first": f.a.slice(0, 2), "second": f.b.slice(0, 2), "p": ["k", "?"], "q": [[kt(s.a2), "?"], [kt(s.a2), "?"]]}
	var phrase := "%s and %s" % [f.af % f.a[1], f.bf % f.b[1]]
	var out := {"lines": [f.line, "The tree shows some of the probabilities in terms of k, where 0 < k < 1."], "asked": "The probability that %s is %s. Find the value of k." % [phrase, Fmt.num(s.r)],
		"answer": ans, "table": null, "graph": spec}
	var one_q := Q.new(1)
	out.wrongs = [wrong({"v": s.other}, R_ROOT)]
	var added: Q = Q.new(2).sub(s.r).div(one_q.add(s.a2))
	if added.sign() > 0 and added.lt(one_q):
		out.wrongs.append(wrong({"v": added}, R_ADD_ALONG))
	out.generic = [one_q.sub(v), s.r, v.mul(Q.new(2)), v.div(Q.new(2)), v.add(Q.new(1, 6)), Q.new(v.n + 1, v.d + 1)].filter(func(x): return x.sign() > 0 and x.lt(one_q)).map(func(x): return {"v": x})
	# a2 k² − (1 + a2) k + 1 − r = 0, cleared of fractions.
	var clear: int = s.a2.d * s.r.d
	var ca: int = roundi(s.a2.to_float() * clear)
	var cb: int = roundi((one_q.add(s.a2)).to_float() * clear)
	var cc: int = roundi((one_q.sub(s.r)).to_float() * clear)
	var eq := "%s(1 − %s)(1 − %s) = %s" % ["", "k", kt(s.a2), Fmt.num(s.r)]
	var g: int = Q.gcd(Q.gcd(ca, cb), cc)
	var quad := "Expand and clear the fractions: %dk² − %dk + %d = 0" % [ca / g, cb / g, cc / g]
	out.methods = {"multiply-add": method(["The branches you want are 1 − k and 1 − %s. Multiply along the path: %s" % [kt(s.a2), eq.strip_edges()], quad,
		"The roots are k = %s and k = %s." % [Fmt.num(v), Fmt.num(s.other)], "A branch is at most 1, so k = %s is the one that works. So k = %s." % [Fmt.num(v), Fmt.num(v)]], ans.values)}
	return out


func u_rounds_exceed_total(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := prob(s, "probability = ", s.v)
	var game: String = GAMES[s.ctx]
	var n: int = s.rounds
	var out := {"answer": ans, "table": null}
	var rules := "A player plays exactly %s rounds, and the rounds are independent. A prize goes to anyone who scores more than %d points in total." % [COUNT[n], s.limit]
	if rep == "table":
		out.lines = ["The table shows the scores for one round at %s." % game, rules]
		out.table = {"rows": [["Points", [str(s.hi), str(s.lo), "0"]], ["Probability", [D(s.a), D(s.b), D(s.c)]]]}
	else:
		out.lines = ["In one round at %s, a player scores %d points with probability %s, %d points with probability %s, and otherwise 0." % [game, s.hi, D(s.a), s.lo, D(s.b)], rules]
	out.asked = "Find the probability that the player wins a prize."
	var top: Q = TreeDiagramSituation.power(s.a, n)
	var once: Q = TreeDiagramSituation.power(s.a, n - 1).mul(s.b)
	var ways: Q = once.mul(Q.new(n))
	out.wrongs = wr(s, top.add(once), R_NO_ROUND_ORDERS) + wr(s, top, R_TOP_ONLY) + wr(s, TreeDiagramSituation.game_total(s, false), R_AT_LIMIT)
	out.generic = probs(s, [ways, Q.new(1).sub(s.v), s.a])
	var a_t := D(s.a)
	var b_t := D(s.b)
	var with_lo: int = (n - 1) * s.hi + s.lo
	var all_hi: int = n * s.hi
	var cases := "Only two kinds of game beat %d: %d in every round (%d points), or %d in %s rounds and %d in one (%d points)." % [s.limit, s.hi, all_hi, s.hi, COUNT[n - 1], s.lo, with_lo]
	var sum_t := "%s%s + %d × %s%s × %s = %s + %s = %s" % [a_t, Fmt.sup(n), n, a_t, Fmt.sup(n - 1), b_t, W(top), W(ways), W(s.v)]
	var listing := "List the winning games: %s in every round; or %s in one round, in any of the %d places, and %s in the rest." % [s.hi, s.lo, n, s.hi]
	out.methods = {"multiply-add": method([cases, "The %d-point round can be any of the %d, so that path counts %d times." % [s.lo, n, n], "Add: " + sum_t, final_step(ans)], ans.values),
		"list-outcomes": method([listing, "Add their probabilities: " + sum_t, final_step(ans)], ans.values)}
	return out


func u_selections_find_n(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("number", {"v": Q.new(s.n)}, {}, "n = ")
	ans.exact = true
	var red: String = colour(s, 0)
	var blue: String = colour(s, 1)
	var it := one(s)
	var r: int = s.r0
	var m: int = s.m
	var lines := ["A tin holds %d %s %s and 1 %s %s." % [r, red, thing(s), blue, it],
		"A %s is drawn at random and put back with one more of the same colour. This repeats until a %s %s is drawn." % [it, blue, it]]
	var out := {"lines": lines, "asked": "The probability that the first %s %s comes on selection n is %s. Find n." % [blue, it, Fmt.num(s.chance)], "answer": ans, "table": null}
	out.wrongs = [wrong({"v": Q.new(m)}, R_IN_TIN)]
	if s.n > 1:
		out.wrongs.append(wrong({"v": Q.new(s.n - 1)}, R_LAST_OUT))
	out.generic = [{"v": Q.new(s.n + 1)}, {"v": Q.new(s.n + 2)}, {"v": Q.new(m + 1)}]
	var top := Q.new(r).div(s.chance).to_float()
	out.methods = {"multiply-add": method(["Before selection n, every draw is %s: %d/%d × %d/%d × ... The tops and bottoms cancel, leaving %d/(n + %d)." % [red, r, r + 1, r + 1, r + 2, r, r - 1],
		"Selection n is then %s, with 1 in n + %d: so %d/((n + %d)(n + %d)) = %s." % [blue, r, r, r - 1, r, Fmt.num(s.chance)],
		"So (n + %d)(n + %d) = %d, which gives n + %d = %d or n + %d = −%d." % [r - 1, r, roundi(top), r, m, r, m - 1],
		"n can't be negative, so n = %d." % s.n], ans.values)}
	return out
