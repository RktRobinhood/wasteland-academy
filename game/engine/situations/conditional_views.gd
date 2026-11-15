class_name ConditionalViews
extends ExtensionViews
## The views on the `conditional` situation: one builder per unknown of
## t4-conditional-probability (FAL-725). An answer is exact on Paper 1 (as the question writes its
## numbers, in decimals or fractions) and to 3 s.f. on Paper 2. Normal and binomial conditionals are Paper 2.
##
## Representations: "equation", "words", "diagram" (a Venn diagram, a tree, or a shaded normal
## curve, drawn by PlotView) and "table" (a two-way table or a distribution).

const SKILL := "SL4.11."
const R_WRONG_DIV := SKILL + "conditional-formula#0"
const R_NO_DIV := SKILL + "conditional-formula#1"
const R_TIMES := SKILL + "conditional-formula#2"
const R_BRANCH := SKILL + "reverse-conditional#0"
const R_ONE_PATH := SKILL + "reverse-conditional#1"
const R_DIVIDE_RULE := SKILL + "multiplication-rule#0"
const R_AS_INTERSECTION := SKILL + "multiplication-rule#1"
const R_NUM_PRODUCT := SKILL + "conditional-distributions#0"
const R_BETWEEN := SKILL + "conditional-distributions#1"
const R_NOT_DIVIDED := SKILL + "conditional-distributions#2"
const INF := "10^99"

## Tree stories: the first event, the second event, in a sentence each.
const TREES := [
	{"what": "crates", "a": "are spoiled", "b": "the scanner flags", "one": "A crate", "ga": "spoiled", "gb": "flagged"},
	{"what": "fuel cans", "a": "are watered down", "b": "the tester rejects", "one": "A can", "ga": "watered down", "gb": "rejected"},
	{"what": "water samples", "a": "are unsafe", "b": "the filter test marks red", "one": "A sample", "ga": "unsafe", "gb": "marked red"},
	{"what": "coins in a till", "a": "are fake", "b": "the scales reject", "one": "A coin", "ga": "fake", "gb": "rejected"},
	{"what": "seed packets", "a": "are old stock", "b": "the sorter sets aside", "one": "A packet", "ga": "old stock", "gb": "set aside"},
	{"what": "batteries", "a": "are worn out", "b": "the meter fails", "one": "A battery", "ga": "worn out", "gb": "failed"},
	{"what": "travellers", "a": "are carrying fever", "b": "the medic's strip marks", "one": "A traveller", "ga": "carrying fever", "gb": "marked"},
	{"what": "parts in a bin", "a": "are cracked", "b": "the inspector rejects", "one": "A part", "ga": "cracked", "gb": "rejected"},
]
const COLOURS := [["red", "blue"], ["green", "white"], ["black", "yellow"], ["red", "green"]]
const THINGS := ["tokens", "marbles", "fuses", "tags"]

const UNKNOWNS := ["conditional-from-probabilities", "conditional-from-venn", "conditional-from-table", "conditional-complement",
	"unknown-from-conditional", "reverse-from-tree", "reverse-two-draws", "intersection-from-conditional", "union-from-conditional",
	"marginal-from-union", "conditional-normal", "conditional-binomial", "conditional-discrete"]
const P2_ONLY := ["conditional-normal", "conditional-binomial"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	if not has(unknown):
		return []
	return [2] if unknown in P2_ONLY else [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = ConditionalSituation.export(s)
	# The engine's last-resort nudges add 1, which is no probability.
	if unknown != "unknown-from-conditional":
		var v: Q = Q.of(out.answer.values.v)
		var unit := Q.new(1, 100)
		for k in [1, -1, 2, -2, 3, -3, 5, -5, 8, -8]:
			out.generic.append_array(probs([v.add(unit.mul(Q.new(k)))]))
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func W(x: Variant) -> String:
	return BinomialViews.W(x.to_float() if x is Q else x)


static func qf(x: float) -> Q:
	return GdcKit.qf(x)


## Exact on Paper 1, to 3 s.f. on Paper 2.
static func prob_ans(s: Dictionary, label: String, v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	if s.paper == 1:
		# Givens in decimals are answered in decimals, and fractions in fractions.
		if s.get("style", "dec") == "dec":
			ans.show = "dec"
		ans.exact = true
	else:
		ans.show = "sf"
	return ans


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func probs(xs: Array) -> Array:
	return xs.filter(func(x): return x.sign() > 0 and x.lt(Q.new(1))).map(func(x): return {"v": x})


## Only a wrong option that is a probability is offered.
static func wr(v: Q, ref: String) -> Array:
	return [wrong({"v": v}, ref)] if v.sign() > 0 and v.lt(Q.new(1)) else []


static func pr(s: Dictionary, n: int) -> Q:
	return Q.new(n, s.u)


static func T(s: Dictionary, v: Q) -> String:
	return VennViews.T(s, v)


static func c3(s: Dictionary) -> Dictionary:
	return VennViews.ctx(s)


static func given_asked(s: Dictionary) -> String:
	var c := c3(s)
	return "Given that a %s %s, find the probability that the %s %s." % [c.one, c.b1, c.one, c.a1]


# ── P(A | B) ─────────────────────────────────────────────────

## The natural-frequencies method as a question with n of `noun` reads it: the map's own
## name ("Imagine 1000 people") has neither its count nor its things (FAL-814).
static func imagine(n: int, noun: String) -> String:
	return "Imagine %d %s" % [n, noun]


static func imagine_title(n: int, noun: String) -> Dictionary:
	return {"natural-frequencies": imagine(n, noun)}


## P(A | B) with A, the numerator n and the given count g: formula and count working. The
## counts are of `noun`, as the question names them.
func _given_methods(s: Dictionary, ans: Dictionary, top: Variant, under: Variant, n: int, g: int, noun: String, name: String = "P(A | B)", cap: String = "P(A ∩ B) ÷ P(B)") -> Dictionary:
	return {"formula": method(["%s = %s" % [name, cap], "= %s ÷ %s" % [top, under], final_step(ans)], ans.values),
		"natural-frequencies": method(["%s: %d are in the given group, and %d of those are also in the one you want." % [imagine(s.u, noun), g, n], "Divide: %d ÷ %d" % [n, g], final_step(ans)], ans.values),
		"venn-restrict": method(["Restrict to the given event: it holds %d of the %d." % [g, s.u], "Of those, %d are also in the one you want: %d ÷ %d" % [n, n, g], final_step(ans)], ans.values)}


func u_conditional_from_probabilities(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := Q.new(s.i, s.i + s.b)
	var ans := prob_ans(s, "P(A | B) = " if rep == "equation" else "probability = ", v)
	var pa := pr(s, s.a + s.i)
	var pb := pr(s, s.b + s.i)
	var mid := pr(s, s.i)
	var out := {"answer": ans, "table": null}
	if rep == "equation":
		out.lines = ["P(A) = " + T(s, pa), "P(B) = " + T(s, pb), "P(A ∩ B) = " + T(s, mid)]
		out.asked = "Find P(A | B)."
	else:
		out.lines = [VennViews.story(s)]
		out.asked = given_asked(s)
	out.wrongs = wr(Q.new(s.i, s.a + s.i), R_WRONG_DIV) + wr(mid, R_NO_DIV) + wr(pa.mul(pb), R_TIMES)
	out.generic = probs([pa, pb])
	var noun: String = "cases" if rep == "equation" else c3(s).who
	out.methods = _given_methods(s, ans, T(s, mid), T(s, pb), s.i, s.i + s.b, noun)
	out.titles = imagine_title(s.u, noun)
	return out


func u_conditional_from_venn(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := Q.new(s.i, s.i + s.b)
	var ans := prob_ans(s, "P(A | B) = ", v)
	var out := {"lines": [VennViews.diagram_line(s)], "asked": "Find P(A | B).", "answer": ans, "table": null, "graph": VennViews.diagram(s)}
	out.wrongs = wr(Q.new(s.i, s.a + s.i), R_WRONG_DIV) + wr(pr(s, s.i), R_NO_DIV)
	out.generic = probs([pr(s, s.a + s.i), pr(s, s.b + s.i), Q.new(s.b, s.i + s.b)])
	out.methods = _given_methods(s, ans, T(s, pr(s, s.i)), T(s, pr(s, s.i + s.b)), s.i, s.i + s.b, "outcomes")
	out.titles = imagine_title(s.u, "outcomes")
	return out


func u_conditional_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := Q.new(s.i, s.i + s.b)
	var ans := prob_ans(s, "probability = ", v)
	var out := {"lines": [VennViews.table_line(s)], "asked": given_asked(s), "answer": ans, "table": VennViews.two_way(s)}
	out.wrongs = wr(Q.new(s.i, s.a + s.i), R_WRONG_DIV) + wr(pr(s, s.i), R_NO_DIV)
	out.generic = probs([pr(s, s.a + s.i), pr(s, s.b + s.i), Q.new(s.b, s.i + s.b)])
	out.methods = _given_methods(s, ans, T(s, pr(s, s.i)), T(s, pr(s, s.i + s.b)), s.i, s.i + s.b, c3(s).who)
	out.titles = imagine_title(s.u, c3(s).who)
	return out


func u_conditional_complement(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var g: int = s.a + s.o
	var v := Q.new(s.o, g)
	var ans := prob_ans(s, "P(A′ | B′) = " if rep == "equation" else "probability = ", v)
	var c := c3(s)
	var out := {"answer": ans, "table": null}
	if rep == "equation":
		out.lines = ["P(A) = " + T(s, pr(s, s.a + s.i)), "P(B) = " + T(s, pr(s, s.b + s.i)), "P(A ∩ B) = " + T(s, pr(s, s.i))]
		out.asked = "Find P(A′ | B′)."
	else:
		out.lines = [VennViews.story(s)]
		out.asked = "Given that a %s doesn't %s, find the probability that the same %s doesn't %s either." % [c.one, c.b, c.one, c.a]
	out.wrongs = wr(Q.new(s.o, s.b + s.o), R_WRONG_DIV) + wr(pr(s, s.o), R_NO_DIV)
	out.generic = probs([Q.new(s.a, g), pr(s, s.b + s.o), pr(s, s.a + s.o)])
	var ms := _given_methods(s, ans, T(s, pr(s, s.o)), T(s, pr(s, g)), s.o, g, "", "P(A′ | B′)", "P(A′ ∩ B′) ÷ P(B′)")
	ms.erase("natural-frequencies")
	out.methods = ms
	return out


func u_unknown_from_conditional(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("number", {"v": Q.new(s.nn)}, {}, "n = ")
	ans.exact = true
	var table := {"rows": [["", ["B", "B′"]], ["A", [str(s.i), str(s.a)]], ["A′", [str(s.b), "n"]]]}
	var r := Q.new(s.t, s.w)
	var out := {"lines": ["The table shows the number of outcomes in each group.", "P(A′ | B′) = " + Fmt.num(r)], "asked": "Find n.", "answer": ans, "table": table}
	var pool: Array = [s.a, s.nn + 1, s.nn + 2, s.nn + s.t + 1, s.a + s.nn]
	out.generic = pool.filter(func(x): return x > 0).map(func(x): return {"v": Q.new(x)})
	out.methods = {"formula": method(["P(A′ | B′) is n out of everything in column B′: n ÷ (%d + n)." % s.a, "%s = n ÷ (%d + n), so %d n = %d(%d + n)" % [Fmt.num(r), s.a, s.w, s.t, s.a],
		"%d n = %d, so n = %d" % [s.w - s.t, s.t * s.a, s.nn], final_step(ans)], ans.values)}
	return out


# ── Reversed through a tree ──────────────────────────────────

static func tree_graph(s: Dictionary) -> Dictionary:
	var one := Q.new(1)
	return {"kind": "tree", "first": ["A", "A′"], "second": ["B", "B′"], "p": [D(s.pa), D(one.sub(s.pa))],
		"q": [[D(s.pba), D(one.sub(s.pba))], [D(s.pbn), D(one.sub(s.pbn))]]}


func u_reverse_from_tree(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := prob_ans(s, "P(A | B) = " if rep == "diagram" else "probability = ", s.v)
	var both: Q = s.pa.mul(s.pba)
	var other: Q = Q.new(1).sub(s.pa).mul(s.pbn)
	var pb: Q = both.add(other)
	var c: Dictionary = TREES[s.ctx]
	var out := {"answer": ans, "table": null}
	if rep == "diagram":
		out.lines = ["The tree diagram shows the events A and B."]
		out.graph = tree_graph(s)
		out.asked = "Find P(A | B)."
	else:
		out.lines = ["Of the %s at a depot, %s%% %s." % [c.what, D(s.pa.mul(Q.new(100))), c.a],
			"%s %s%% of those, and %s%% of the others." % ["A check: " + c.b, D(s.pba.mul(Q.new(100))), D(s.pbn.mul(Q.new(100)))]]
		out.asked = "%s is %s. Find the probability that it is %s." % [c.one, c.gb, c.ga]
	out.wrongs = wr(s.pba, R_BRANCH) + wr(both, R_ONE_PATH)
	out.generic = probs([s.pa, pb, other])
	var n: int = 100 if s.paper == 1 else 10000
	var nb := int(both.mul(Q.new(n)).to_float() + 0.5)
	var no := int(other.mul(Q.new(n)).to_float() + 0.5)
	var noun: String = "cases" if rep == "diagram" else c.what
	out.methods = {"path-over-paths": method(["The paths ending in B: %s × %s = %s and %s × %s = %s." % [D(s.pa), D(s.pba), D(both), D(Q.new(1).sub(s.pa)), D(s.pbn), D(other)],
			"Take the wanted path over both: %s ÷ (%s + %s)" % [D(both), D(both), D(other)], final_step(ans)], ans.values),
		"formula-total-probability": method(["P(B) = P(A ∩ B) + P(A′ ∩ B) = %s + %s = %s" % [D(both), D(other), D(pb)], "P(A | B) = P(A ∩ B) ÷ P(B) = %s ÷ %s" % [D(both), D(pb)], final_step(ans)], ans.values),
		"natural-frequencies": method(["%s: %d follow the first path into B and %d the second." % [imagine(n, noun), nb, no], "Divide: %d ÷ %d" % [nb, nb + no], final_step(ans)], ans.values)}
	out.titles = imagine_title(n, noun)
	return out


func u_reverse_two_draws(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := prob_ans(s, "probability = ", s.v)
	var col: Array = COLOURS[s.ctx % COLOURS.size()]
	var thing: String = THINGS[s.ctx % THINGS.size()]
	var t: int = s.r + s.g
	var first: int = s.r * (s.r - 1)
	var second: int = s.g * (s.g - 1)
	var pairs: int = t * (t - 1)
	var out := {"lines": ["A bag holds %d %s and %d %s %s." % [s.r, col[0], s.g, col[1], thing], "Two are drawn at random, without replacement."],
		"asked": "Given that the two are the same colour, find the probability that both are %s." % col[0], "answer": ans, "table": null}
	out.wrongs = wr(Q.new(first, pairs), R_ONE_PATH)
	out.generic = probs([Q.new(s.r * s.r, s.r * s.r + s.g * s.g), Q.new(s.r, t), Q.new(first + second, pairs), Q.new(second, first + second)])
	out.methods = {"path-over-paths": method(["Both %s: %d/%d × %d/%d. Both %s: %d/%d × %d/%d." % [col[0], s.r, t, s.r - 1, t - 1, col[1], s.g, t, s.g - 1, t - 1],
			"Take the wanted path over both: %d ÷ (%d + %d)" % [first, first, second], final_step(ans)], ans.values),
		"formula-total-probability": method(["P(same) = %s + %s = %s" % [Fmt.num(Q.new(first, pairs)), Fmt.num(Q.new(second, pairs)), Fmt.num(Q.new(first + second, pairs))],
			"P(both %s | same) = %s ÷ %s" % [col[0], Fmt.num(Q.new(first, pairs)), Fmt.num(Q.new(first + second, pairs))], final_step(ans)], ans.values),
		"natural-frequencies": method(["Count the ordered pairs: %d are both %s and %d are both %s." % [first, col[0], second, col[1]], "Divide: %d ÷ %d" % [first, first + second], final_step(ans)], ans.values)}
	out.titles = {"natural-frequencies": "Count the ordered pairs"}
	return out


# ── The multiplication rule ──────────────────────────────────

static func pcent(v: Q) -> String:
	return D(v.mul(Q.new(100)))


func u_intersection_from_conditional(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := prob_ans(s, "P(A ∩ B) = " if rep == "equation" else "probability = ", s.pi)
	var c := c3(s)
	var out := {"answer": ans, "table": null}
	if rep == "equation":
		out.lines = ["P(B) = " + D(s.pb), "P(A | B) = " + D(s.pc)]
		out.asked = "Find P(A ∩ B)."
	else:
		out.lines = ["%s%% of the %s in a camp %s." % [pcent(s.pb), c.who, c.b], "Of those, %s%% also %s." % [pcent(s.pc), c.a]]
		out.asked = "Find the probability that a %s chosen at random does both." % c.one
	out.wrongs = wr(s.pc.div(s.pb), R_DIVIDE_RULE) + wr(s.pc, R_AS_INTERSECTION)
	out.generic = probs([s.pb, s.pb.div(s.pc), Q.new(1).sub(s.pi)])
	out.methods = {"rearrange": method(["P(A | B) = P(A ∩ B) ÷ P(B), so P(A ∩ B) = P(A | B) × P(B).", "= %s × %s" % [D(s.pc), D(s.pb)], final_step(ans)], ans.values),
		"tree-multiply": method(["Draw B first, then A given B. The path has probabilities %s and %s." % [D(s.pb), D(s.pc)], "Multiply along it: %s × %s" % [D(s.pb), D(s.pc)], final_step(ans)], ans.values)}
	return out


func u_union_from_conditional(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := prob_ans(s, "P(A ∪ B) = " if rep == "equation" else "probability = ", s.pu)
	var c := c3(s)
	var out := {"answer": ans, "table": null}
	if rep == "equation":
		out.lines = ["P(A) = " + D(s.pa), "P(B) = " + D(s.pb), "P(A | B) = " + D(s.pc)]
		out.asked = "Find P(A ∪ B)."
	else:
		out.lines = ["%s%% of the %s in a camp %s and %s%% %s." % [pcent(s.pa), c.who, c.a, pcent(s.pb), c.b], "Of those who %s, %s%% also %s." % [c.b, pcent(s.pc), c.a]]
		out.asked = "Find the probability that a %s chosen at random does at least one of these." % c.one
	out.wrongs = wr(s.pa.add(s.pb).sub(s.pc), R_AS_INTERSECTION)
	out.generic = probs([s.pa.add(s.pb), s.pi, s.pa.mul(s.pb), Q.new(1).sub(s.pi)])
	var a_only: Q = s.pa.sub(s.pi)
	var b_only: Q = s.pb.sub(s.pi)
	out.methods = {"rearrange": method(["P(A ∩ B) = P(A | B) × P(B) = %s × %s = %s" % [D(s.pc), D(s.pb), D(s.pi)], "P(A ∪ B) = P(A) + P(B) − P(A ∩ B) = %s + %s − %s" % [D(s.pa), D(s.pb), D(s.pi)], final_step(ans)], ans.values),
		"venn-fill": method(["Put P(A ∩ B) = %s × %s = %s in the middle." % [D(s.pc), D(s.pb), D(s.pi)], "A only is %s and B only is %s, and the union is the three regions." % [D(a_only), D(b_only)], final_step(ans)], ans.values)}
	return out


func u_marginal_from_union(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := prob_ans(s, "P(B) = ", s.pb)
	var out := {"lines": ["P(A) = " + D(s.pa), "P(A | B) = " + D(s.pc), "P(A ∪ B) = " + D(s.pu)], "asked": "Find P(B).", "answer": ans, "table": null}
	out.generic = probs([s.pu.sub(s.pa), s.pu.sub(s.pa).add(s.pc), s.pu, s.pu.mul(s.pc)])
	var diff: Q = s.pu.sub(s.pa)
	var part: Q = Q.new(1).sub(s.pc)
	out.methods = {"rearrange": method(["P(A ∩ B) = %s × P(B), so %s = %s + P(B) − %sP(B)." % [D(s.pc), D(s.pu), D(s.pa), D(s.pc)],
			"%s = %s × P(B)" % [D(diff), D(part)], final_step(ans)], ans.values),
		"venn-fill": method(["Of B, the share %s is in A, so B only is %s × P(B)." % [D(s.pc), D(part)], "Adding B only to A gives the union: %s + %s × P(B) = %s" % [D(s.pa), D(part), D(s.pu)], final_step(ans)], ans.values)}
	return out


# ── Conditionals on distributions ────────────────────────────

## The event's bounds for the wanted and the given, as a student reads them.
static func normal_event(s: Dictionary) -> Array:
	match s.form:
		"gt":
			return ["X > %d" % s.hi, "X > %d" % s.lo]
		"lt":
			return ["X < %d" % s.lo, "X < %d" % s.hi]
	return ["X < %d" % s.hi, "X > %d" % s.lo]


func u_conditional_normal(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ev := normal_event(s)
	var ans := prob_ans(s, "probability = ", qf(s.v))
	var out := {"answer": ans, "table": null}
	var c: Dictionary = NormalUnknownViews.CONTEXTS[s.ctx]
	if rep == "words":
		out.lines = ["%s are normally distributed with mean %d%s and standard deviation %d%s." % [c.what, s.mu, c.unit, s.sg, c.unit]]
		var w := func(e: String) -> String: return ("below " if e.contains("<") else "above ") + e.get_slice(" ", 2) + c.unit
		out.asked = "Given that one of them is %s, find the probability that it is %s." % [w.call(ev[1]), w.call(ev[0])]
	else:
		out.lines = ["X ~ N(%d, %d²)" % [s.mu, s.sg]]
		out.asked = "Find P(%s | %s)." % [ev[0], ev[1]]
	if rep == "diagram":
		var lo := float(s.lo)
		var hi := float(s.hi)
		var given: Array = [null, hi] if s.form == "lt" else [lo, null]
		var wanted: Array = {"gt": [hi, null], "lt": [null, lo], "mid": [lo, hi]}[s.form]
		out.graph = NormalUnknownViews.curve(float(s.mu), float(s.sg), [given, wanted], [{"at": lo, "label": str(s.lo)}, {"at": hi, "label": str(s.hi)}])
	out.wrongs = wr(qf(s.num * s.den), R_NUM_PRODUCT) + wr(qf(s.mid), R_BETWEEN) + wr(qf(s.num), R_NOT_DIVIDED)
	out.generic = probs([qf(s.den), qf(s.v * 0.9)])
	var both := "the overlap of %s and %s is %s" % [ev[0], ev[1], {"gt": ev[0], "lt": ev[0], "mid": "%d < X < %d" % [s.lo, s.hi]}[s.form]]
	var num_t := "%s" % W(s.num)
	var den_t := "%s" % W(s.den)
	out.methods = {"simplify-intersection": method(["Simplify: %s." % both, "Its probability is %s, and P(%s) = %s." % [num_t, ev[1], den_t], "Divide: %s ÷ %s" % [num_t, den_t], final_step(ans)], ans.values),
		"shade-regions": method(["Shade %s: that is the whole you are told about, area %s." % [ev[1], den_t], "Inside it, shade the wanted part: area %s." % num_t, "The answer is the smaller area as a share of the larger: %s ÷ %s" % [num_t, den_t], final_step(ans)], ans.values),
		"gdc-values": method(["normalcdf gives the wanted overlap: %s." % num_t, "normalcdf gives the given event: %s." % den_t, "Divide, keeping full accuracy: %s ÷ %s" % [num_t, den_t], final_step(ans)], ans.values)}
	return out


func u_conditional_binomial(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var want: String = {"le": "X ≤ %d" % s.k, "eq": "X = %d" % s.k, "ge": "X ≥ %d" % s.k}[s.form]
	var given := "X ≥ %d" % s.j
	var ans := prob_ans(s, "probability = ", qf(s.v))
	var out := {"answer": ans, "table": null}
	var c: Dictionary = BinomialViews.CONTEXTS[s.ctx]
	if rep == "words":
		var b_s := {"p": s.p, "n": s.n, "ctx": s.ctx}
		out.lines = [BinomialViews.intro(b_s), "Let X be %s." % c.x]
		out.asked = "Find P(%s | %s)." % [want, given]
	else:
		out.lines = ["X ~ B(%d, %s)" % [s.n, D(s.p)]]
		out.asked = "Find P(%s | %s)." % [want, given]
	out.wrongs = wr(qf(s.num * s.den), R_NUM_PRODUCT) + wr(qf(s.num), R_NOT_DIVIDED)
	out.generic = probs([qf(s.den), qf(s.v * 0.9), qf(1.0 - s.v)])
	var lo: int = s.j if s.form == "le" else s.k
	var hi: int = {"le": s.k, "eq": s.k, "ge": s.n}[s.form]
	var both := "%d ≤ X ≤ %d" % [lo, hi] if lo != hi else "X = %d" % lo
	out.methods = {"simplify-intersection": method(["Simplify the overlap of %s and %s: it is %s." % [want, given, both], "P(%s) = %s and P(%s) = %s" % [both, W(s.num), given, W(s.den)], "Divide: %s ÷ %s" % [W(s.num), W(s.den)], final_step(ans)], ans.values),
		"gdc-values": method(["binomcdf gives the overlap, %s: %s." % [both, W(s.num)], "binomcdf gives P(%s) = %s." % [given, W(s.den)], "Divide, keeping full accuracy: %s ÷ %s" % [W(s.num), W(s.den)], final_step(ans)], ans.values)}
	return out


func u_conditional_discrete(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := prob_ans(s, "probability = ", s.v)
	var table := {"rows": [["x", s.xs.map(func(x): return str(x))], ["P(X = x)", s.ps.map(func(p): return D(p))]]}
	var want := "X ≥ %d" % s.a1
	var given := "X < %d" % s.b1
	var out := {"lines": ["The table shows the probability distribution of X."], "asked": "Find P(%s | %s)." % [want, given], "answer": ans, "table": table}
	out.wrongs = wr(s.num, R_NOT_DIVIDED)
	out.generic = probs([s.den, s.num.mul(s.den), Q.new(1).sub(s.v)])
	var both := "%d ≤ X < %d" % [s.a1, s.b1]
	out.methods = {"simplify-intersection": method(["The overlap of %s and %s is %s." % [want, given, both], "P(%s) = %s and P(%s) = %s" % [both, D(s.num), given, D(s.den)], "Divide: %s ÷ %s" % [D(s.num), D(s.den)], final_step(ans)], ans.values)}
	return out
