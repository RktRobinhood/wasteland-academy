class_name ConditionalDiagramViews
extends ExtensionViews
## The views on the `conditional-diagram` situation: one builder per unknown of
## t4-ext-conditional-diagram (FAL-777). Every answer is exact: a fraction from counts, a decimal
## from a tree's branches. Wrong options are the slips: the grand total, the other group's total,
## the given group's own probability, the product along a path, the other branch, the total of
## the paths, and a bag with the first sweet put back.
##
## Representations: "table" (a two-way table of counts with totals), "diagram" (a Venn diagram of
## counts or a tree diagram, drawn by PlotView) and "words" (a bag drawn twice).

const SK := "SL4.6.conditional-diagram#"
const R_GRAND := SK + "0"
const R_REVERSE := SK + "1"
const T := "t4-ext-conditional-diagram#"
const R_PATH := T + "2"
const R_PUT_BACK := T + "3"
const R_OTHER_BRANCH := T + "4"
const R_SPOT_GRAND := T + "5"
const R_PATHS_ADDED := T + "6"
const R_GIVEN_ITSELF := T + "7"
const UNKNOWNS := ["from-table", "from-venn", "tree-branch", "second-draw"]
const COLOURS := [["red", "blue"], ["green", "white"], ["black", "yellow"], ["red", "green"]]
const THINGS := ["sweets", "tokens", "marbles", "fuses"]
const PICK_WRONGS := [
	{"name": "Divide by the grand total", "why": "the given group is the new whole, so you divide by its total, not by everyone's"},
	{"name": "Multiply the two probabilities", "why": "multiplying gives the probability that both happen, not one given the other"},
]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = ["method-pick"] + (["error-spot"] if u in ["from-table", "from-venn"] else [])
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = ConditionalDiagramSituation.export(s)
	out.pick_wrongs = PICK_WRONGS
	if not out.has("fillers"):
		out.fillers = []
	return out


static func F(v: Q) -> String:
	return Fmt.num(v)


static func D(v: Q) -> String:
	return Fmt.dec(v)


static func exact(label: String, v: Q, dec: bool = false) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	ans.exact = true
	if dec:
		ans.show = "dec"
	return ans


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func wr(v: Q, ref: String) -> Array:
	return [wrong({"v": v}, ref)] if v.sign() > 0 and v.lt(Q.new(1)) else []


# ── Counts: a table or a Venn diagram ────────────────────────

## The given group's count, the other group's, and the conditional's name.
static func groups(s: Dictionary) -> Dictionary:
	var gb: bool = s.given == "B"
	return {"g": s.i + (s.b if gb else s.a), "other": s.i + (s.a if gb else s.b), "G": s.given, "O": "A" if gb else "B",
		"name": "P(A | B)" if gb else "P(B | A)", "gonly": s.b if gb else s.a}


static func count_wrongs(s: Dictionary) -> Array:
	var g := groups(s)
	return wr(Q.new(s.i, s.u), R_GRAND) + wr(Q.new(s.i, g.other), R_REVERSE) + wr(Q.new(g.g, s.u), R_GIVEN_ITSELF)


static func formula(s: Dictionary, ans: Dictionary) -> Dictionary:
	var g := groups(s)
	return method(["%s = P(A ∩ B) ÷ P(%s)." % [g.name, g.G], "= %s ÷ %s = %d/%d." % [F(Q.new(s.i, s.u)), F(Q.new(g.g, s.u)), s.i, g.g], final_step(ans)], ans.values)


## Error-spot: the count in both over the grand total.
static func count_spot(s: Dictionary, rng: Seeded) -> Dictionary:
	var g := groups(s)
	var given := "The given group is %s: n(%s) = %d + %d = %d." % [g.G, g.G, s.i, g.gonly, g.g]
	var both := "Both A and B: n(A ∩ B) = %d." % s.i
	var slip := "%s = %d ÷ %d" % [g.name, s.i, s.u]
	var end := "= " + F(Q.new(s.i, s.u))
	var lines: Array
	var bad := 2
	match rng.int_in(0, 2):
		0:
			lines = [given, both, slip, end]
		1:
			lines = [both, given, slip, end]
		_:
			lines = [both, slip, end, "So %s = %s" % [g.name, F(Q.new(s.i, s.u))]]
			bad = 1
	return {"lines": lines, "bad": bad, "ref": R_SPOT_GRAND,
		"why": "the given group, %s, is the new whole: divide by n(%s) = %d, not by all %d" % [g.G, g.G, g.g, s.u]}


func u_from_table(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var g := groups(s)
	var c := VennViews.ctx(s)
	var ans := exact("probability = ", Q.new(s.i, g.g))
	var gb: bool = s.given == "B"
	var out := {"lines": [VennViews.table_line(s)], "table": VennViews.two_way(s), "answer": ans,
		"asked": "A %s is chosen at random from those who %s. Find the probability that they also %s." % [c.one, c.b if gb else c.a, c.a if gb else c.b]}
	out.wrongs = count_wrongs(s)
	var keep := "Keep only the B column: it holds %d %s in all." % [g.g, c.who] if gb else "Keep only the A row: it holds %d %s in all." % [g.g, c.who]
	var also := "Of those, %d are also in row A: %d/%d." % [s.i, s.i, g.g] if gb else "Of those, %d are also in column B: %d/%d." % [s.i, s.i, g.g]
	out.methods = {"restrict-table": method([keep, also, final_step(ans)], ans.values), "formula": formula(s, ans)}
	out.spot = count_spot(s, rng)
	return out


func u_from_venn(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var g := groups(s)
	var ans := exact(g.name + " = ", Q.new(s.i, g.g))
	var out := {"lines": ["The Venn diagram shows how many of %d outcomes are in each region for events A and B. One is chosen at random." % s.u],
		"graph": VennViews.venn_graph(str(s.a), str(s.i), str(s.b), str(s.o)), "answer": ans, "asked": "Find %s." % g.name}
	out.wrongs = count_wrongs(s)
	out.methods = {"restrict-venn": method(["Look only inside circle %s: %d + %d = %d outcomes." % [g.G, s.i, g.gonly, g.g],
			"%d of them are also in %s: %d/%d." % [s.i, g.O, s.i, g.g], final_step(ans)], ans.values),
		"formula": formula(s, ans)}
	out.spot = count_spot(s, rng)
	return out


# ── A tree ───────────────────────────────────────────────────

static func tree_graph(s: Dictionary) -> Dictionary:
	var one := Q.new(1)
	return {"kind": "tree", "first": ["A", "A′"], "second": ["B", "B′"], "p": [D(s.pa), D(one.sub(s.pa))],
		"q": [[D(s.pba), D(one.sub(s.pba))], [D(s.pbn), D(one.sub(s.pbn))]]}


func u_tree_branch(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var one := Q.new(1)
	var on_a: bool = s.want == "B|A"
	# The first branch, the wanted second branch, the same second outcome from the other first
	# outcome, and the other path into it.
	var first: Q = s.pa if on_a else one.sub(s.pa)
	var branch: Q = s.pba if on_a else one.sub(s.pbn)
	var other: Q = s.pbn if on_a else one.sub(s.pba)
	var other_first: Q = one.sub(s.pa) if on_a else s.pa
	var name := "P(B | A)" if on_a else "P(B′ | A′)"
	var ans := exact(name + " = ", branch, true)
	var out := {"lines": ["The tree diagram shows the events A and B."], "graph": tree_graph(s), "answer": ans, "asked": "Find %s." % name}
	out.wrongs = wr(first.mul(branch), R_PATH) + wr(other, R_OTHER_BRANCH) + wr(first.mul(branch).add(other_first.mul(other)), R_PATHS_ADDED)
	var A := "A" if on_a else "A′"
	var B := "B" if on_a else "B′"
	out.methods = {
		"tree-branch": method(["Each second-stage branch is already conditional on the first-stage branch it grows from.",
			"The branch from %s to %s is labelled %s." % [A, B, D(branch)], final_step(ans)], ans.values),
		"formula": method(["%s = P(%s ∩ %s) ÷ P(%s)." % [name, A, B, A],
			"P(%s ∩ %s) = %s × %s = %s, so %s = %s ÷ %s." % [A, B, D(first), D(branch), D(first.mul(branch)), name, D(first.mul(branch)), D(first)], final_step(ans)], ans.values),
	}
	return out


# ── Two draws from a bag ─────────────────────────────────────

func u_second_draw(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var col: Array = COLOURS[s.ctx]
	var thing: String = THINGS[s.ctx]
	var r: int = s.r
	var g: int = s.g
	var n := r + g
	var want: String = col[0] if s.same else col[1]
	var top: int = r - 1 if s.same else g
	var ans := exact("probability = ", Q.new(top, n - 1))
	var out := {"lines": ["A bag holds %d %s and %d %s %s." % [r, col[0], g, col[1], thing], "Two are taken at random, one after the other, without replacement."],
		"asked": "Given that the first is %s, find the probability that the second is %s." % [col[0], want], "answer": ans, "table": null}
	out.wrongs = wr(Q.new(r * top, n * (n - 1)), R_PATH) + wr(Q.new(r if s.same else g, n), R_PUT_BACK)
	if s.same:
		out.wrongs += wr(Q.new(top, n), R_GRAND)
	out.fillers = [{"v": Q.new(top + 1, n - 1)}, {"v": Q.new(top, n + 1)}]
	var left := "After a %s is taken, the bag holds %d %s and %d %s: %d in all." % [col[0], r - 1, col[0], g, col[1], n - 1]
	out.methods = {
		"tree-branch": method([left, "The second-stage branch from %s to %s is %d/%d." % [col[0], want, top, n - 1], final_step(ans)], ans.values),
		"formula": method(["P(first %s and second %s) = %d/%d × %d/%d = %s." % [col[0], want, r, n, top, n - 1, F(Q.new(r * top, n * (n - 1)))],
			"Divide by P(first %s) = %d/%d: %s ÷ %s." % [col[0], r, n, F(Q.new(r * top, n * (n - 1))), F(Q.new(r, n))], final_step(ans)], ans.values),
	}
	return out
