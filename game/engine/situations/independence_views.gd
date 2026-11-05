class_name IndependenceViews
extends ExtensionViews
## The views on the `independence` situation: one builder per unknown of t4-independence
## (FAL-739). A number is exact on Paper 1, as the question writes its givens, and to 3 s.f. on
## Paper 2. Finding P(A) from a quadratic is Paper 2 only.
##
## A test is decided, and justified with two numbers. Its answer is the `form` kind: the two
## numbers are typed and the verdict picked, as in "P(A ∩ B) = □ and P(A) × P(B) = □, so A and B
## are ▾". Which two numbers depends on the method asked. All four options say true things about
## the question and two end in each verdict, so only the comparison can decide.
##
## Representations: "equation", "words", "diagram" (a Venn diagram or a tree, drawn by PlotView)
## and "table" (a two-way table).

const IND := "SL4.6.independent#"
const TEST := "SL4.11.test-independence#"
const UNK := "SL4.11.independence-unknown#"
const R_ADD := IND + "0"
const R_UNION := IND + "1"
const R_ZERO := IND + "2"
const R_NO_DASH := IND + "3"
const R_OVERLAP := TEST + "0"
const R_MIX := TEST + "1"
const R_ONE_NUMBER := TEST + "2"
const R_REVERSED := TEST + "3"
const R_AS_EXCLUSIVE := UNK + "0"
const R_NO_OVERLAP := UNK + "1"
const R_ONLY_PRODUCT := UNK + "2"
const R_NOT_DIVIDED := UNK + "3"

const YES := "independent"
const NO := "not independent"
const CLASSES := ["mutually exclusive", "independent", "mutually exclusive and independent", "neither mutually exclusive nor independent"]

## Two things that happen on their own: what they are, then the verb, singular and plural.
const PAIRS := [
	["the pump", "the generator", "breaks down", "break down"],
	["the north sensor", "the south sensor", "trips", "trip"],
	["the first scout", "the second scout", "finds water", "find water"],
	["the east radio tower", "the west radio tower", "loses signal", "lose signal"],
	["Mara's trap", "Jonas's trap", "catches a rat", "catch a rat"],
	["the lead caravan", "the rear caravan", "reaches camp by dark", "reach camp by dark"],
	["the rain tank", "the well", "runs dry", "run dry"],
	["the day guard", "the night guard", "spots raiders", "spot raiders"],
]
## Two sources: their name, what is in them, the good ones and the bad ones, the taking, and the plural of the name.
const SOURCES := [
	["crate", "fuses", "working", "dead", "takes out one fuse", "the fuse is working", "crates"],
	["barrel", "water flasks", "clean", "dirty", "takes out one flask", "the flask is clean", "barrels"],
	["sack", "seed packets", "fresh", "stale", "takes out one packet", "the packet is fresh", "sacks"],
	["bin", "batteries", "charged", "flat", "takes out one battery", "the battery is charged", "bins"],
	["locker", "gas masks", "sealed", "cracked", "takes out one mask", "the mask is sealed", "lockers"],
	["shelf", "ration tins", "sound", "dented", "takes down one tin", "the tin is sound", "shelves"],
	["toolbox", "spark plugs", "new", "worn", "takes out one plug", "the plug is new", "toolboxes"],
	["trunk", "radio valves", "good", "burnt", "takes out one valve", "the valve is good", "trunks"],
]

const UNKNOWNS := ["both-from-probabilities", "union-from-independence", "one-region-from-independence", "conditional-from-independence",
	"unknown-from-union", "ratio-from-union", "overlap-from-only-regions", "test-from-probabilities", "test-from-venn", "test-from-table",
	"test-from-tree", "test-from-conditional", "classify-events"]
const P2_ONLY := ["ratio-from-union", "overlap-from-only-regions"]
const TESTS := ["test-from-probabilities", "test-from-venn", "test-from-table", "test-from-tree", "test-from-conditional", "classify-events"]


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
	out.given = IndependenceSituation.export(s)
	# The engine's last-resort nudges add 1, which is no probability.
	if not unknown in TESTS:
		var v: Q = Q.of(out.answer.values.v)
		# On Paper 1 a decimal question has short decimal options: a fraction would give itself away.
		if s.paper == 1 and s.style == "dec":
			out.generic = out.generic.filter(func(g): return Fmt.dec(g.v).length() <= 6 and not Fmt.dec(g.v).contains("/"))
		elif s.paper == 1:
			out.generic = out.generic.filter(func(g): return g.v.d <= 120)
		var unit := Q.new(1, 100)
		for k in [1, -1, 2, -2, 3, -3, 5, -5, 8, -8]:
			out.generic.append_array(probs([v.add(unit.mul(Q.new(k)))]))
	return out


# ── Writing things ───────────────────────────────────────────

## A given, as the question writes its numbers.
static func T(s: Dictionary, v: Q) -> String:
	return Fmt.dec(v) if s.style in ["dec", "pct"] else Fmt.num(v)


## A worked-out value, for a comparison and the options: exact on Paper 1, 3 s.f. on Paper 2.
static func H(s: Dictionary, v: Q) -> String:
	return IndependenceSituation.H(s, v)


## A value in the working: in full where it ends, else to 4 s.f.
static func W(s: Dictionary, v: Q) -> String:
	if s.paper == 1:
		return T(s, v)
	var t := Fmt.dec(v)
	return Fmt.sf(v, 4) if t.contains("/") or t.length() > 8 else t


## An exact value to divide or multiply with: in full, or as a fraction, so nothing is rounded twice.
static func E(s: Dictionary, v: Q) -> String:
	if s.paper == 1:
		return T(s, v)
	var t := Fmt.dec(v)
	return Fmt.num(v) if t.contains("/") or t.length() > 8 else t


static func pct(v: Q) -> String:
	return Fmt.dec(v.mul(Q.new(100))) + "%"


static func one_minus(v: Q) -> Q:
	return Q.new(1).sub(v)


static func prob_ans(s: Dictionary, label: String, v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	if s.paper == 1:
		if s.style in ["dec", "pct"]:
			ans.show = "dec"
		ans.exact = true
	else:
		ans.show = "sf"
	return ans


static func final_step(ans: Dictionary) -> String:
	return Answer.text(ans) + "."


static func probs(xs: Array) -> Array:
	return xs.filter(func(x): return x.sign() > 0 and x.lt(Q.new(1))).map(func(x): return {"v": x})


## Only a wrong option that is a probability is offered.
static func wr(v: Q, ref: String) -> Array:
	return [wrong({"v": v}, ref)] if v.sign() > 0 and v.lt(Q.new(1)) else []


static func pair(s: Dictionary) -> Array:
	return PAIRS[s.ctx]


static func cap(t: String) -> String:
	return t.left(1).to_upper() + t.substr(1)


static func both(s: Dictionary) -> Array:
	return ["P(A) = " + T(s, s.pa), "P(B) = " + T(s, s.pb), "A and B are independent."]


## The tree of an independent pair: the branches for B are the same after A and after A′.
static func flat_tree(s: Dictionary) -> Dictionary:
	var b := [T(s, s.pb), T(s, one_minus(s.pb))]
	return {"kind": "tree", "first": ["A", "A′"], "second": ["B", "B′"], "p": [T(s, s.pa), T(s, one_minus(s.pa))], "q": [b, b]}


## Names A and B in a pair story, for the working and the feedback.
static func pair_named(c: Array) -> String:
	return "A is the event that %s %s, and B the event that %s %s." % [c[0], c[2], c[1], c[2]]


static func tree_line() -> String:
	return "The tree shows two independent events, A and B."


# ── Using independence ───────────────────────────────────────

func u_both_from_probabilities(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pa: Q = s.pa
	var pb: Q = s.pb
	var ans := prob_ans(s, "probability = " if rep == "words" else "P(A ∩ B) = ", s.pi)
	var c := pair(s)
	var out := {"answer": ans, "table": null}
	match rep:
		"words":
			out.lines = ["On any one day, %s %s with probability %s." % [c[0], c[2], T(s, pa)], "On any one day, %s %s with probability %s, independently of %s." % [c[1], c[2], T(s, pb), c[0]], pair_named(c)]
			out.asked = "Find the probability that %s and %s both %s on the same day." % [c[0], c[1], c[3]]
		"diagram":
			out.lines = [tree_line()]
			out.graph = flat_tree(s)
			out.asked = "Find P(A ∩ B)."
		_:
			out.lines = both(s)
			out.asked = "Find P(A ∩ B)."
	out.wrongs = [wrong({"v": Q.new(0)}, R_ZERO)] + wr(pa.add(pb), R_ADD) + wr(pa.add(pb).sub(pa.mul(pb)), R_UNION)
	out.generic = probs([pa, pb, one_minus(s.pi), one_minus(pa).mul(one_minus(pb))])
	out.methods = {"multiply": method(["The events are independent, so P(A ∩ B) = P(A) × P(B).", "= %s × %s" % [T(s, pa), T(s, pb)], final_step(ans)], ans.values),
		"tree-unchanged": method(["On a tree, the branches for B are the same after A and after A′. B has probability %s on both." % T(s, pb),
			"Follow the path A then B and multiply along it: %s × %s" % [T(s, pa), T(s, pb)], final_step(ans)], ans.values)}
	return out


static func region_value(s: Dictionary) -> Q:
	var x: Q = one_minus(s.pa) if s.region.begins_with("A′") else s.pa
	var y: Q = one_minus(s.pb) if s.region.ends_with("B′") else s.pb
	return x.mul(y)


func u_one_region_from_independence(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pa: Q = s.pa
	var pb: Q = s.pb
	var x: Q = one_minus(pa) if s.region.begins_with("A′") else pa
	var y: Q = one_minus(pb) if s.region.ends_with("B′") else pb
	var first: String = "A′" if s.region.begins_with("A′") else "A"
	var second: String = "B′" if s.region.ends_with("B′") else "B"
	var v := x.mul(y)
	var ans := prob_ans(s, "P(%s) = " % s.region, v)
	var out := {"answer": ans, "table": null, "asked": "Find P(%s)." % s.region}
	if rep == "diagram":
		out.lines = [tree_line()]
		out.graph = flat_tree(s)
	else:
		out.lines = both(s)
	out.wrongs = wr(pa.mul(pb), R_NO_DASH)
	if s.region == "A′ ∩ B′":
		out.wrongs += wr(one_minus(pa).sub(pb), R_AS_EXCLUSIVE)
	out.generic = probs([one_minus(pa).mul(one_minus(pb)), one_minus(pa).mul(pb), pa.mul(one_minus(pb)), one_minus(v), x, y])
	var pieces: Array = []
	for pc in [[first, x, pa, "A"], [second, y, pb, "B"]]:
		if pc[0].ends_with("′"):
			pieces.append("P(%s) = 1 − %s = %s" % [pc[0], T(s, pc[2]), T(s, pc[1])])
	var opening := "If A and B are independent, so are %s and %s. " % [first, second] + ("So " + " and ".join(pieces) + "." if not pieces.is_empty() else "")
	# The diagram shows each branch; otherwise the tree is the student's own, so its values are worked.
	var on_tree := "On the tree" if rep == "diagram" else "On a tree"
	var branch := func(name: String, value: Q, base: Q) -> String:
		return T(s, value) if rep == "diagram" or not name.ends_with("′") else "1 − %s = %s" % [T(s, base), T(s, value)]
	out.methods = {"multiply": method([opening.strip_edges(), "P(%s) = P(%s) × P(%s) = %s × %s" % [s.region, first, second, T(s, x), T(s, y)], final_step(ans)], ans.values),
		"tree-unchanged": method(["%s, take the branch %s, with probability %s." % [on_tree, first, branch.call(first, x, pa)],
			"Then take the branch %s, with probability %s: it is the same whichever first branch you took." % [second, branch.call(second, y, pb)],
			"Multiply along the path: %s × %s" % [T(s, x), T(s, y)], final_step(ans)], ans.values)}
	return out


func u_union_from_independence(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pa: Q = s.pa
	var pb: Q = s.pb
	var ans := prob_ans(s, "probability = " if rep == "words" else "P(A ∪ B) = ", s.pu)
	var c := pair(s)
	var out := {"answer": ans, "table": null}
	if rep == "words":
		out.lines = ["On any one day, %s %s with probability %s." % [c[0], c[2], T(s, pa)], "On any one day, %s %s with probability %s, independently of %s." % [c[1], c[2], T(s, pb), c[0]], pair_named(c)]
		out.asked = "Find the probability that at least one of them %s on a given day." % c[2]
	else:
		out.lines = both(s)
		out.asked = "Find P(A ∪ B)."
	out.wrongs = wr(pa.add(pb), R_AS_EXCLUSIVE)
	out.generic = probs([pa.mul(pb), one_minus(pa.mul(pb)), one_minus(pa).mul(one_minus(pb)), pa, pb])
	out.methods = {"addition-with-product": method(["P(A ∪ B) = P(A) + P(B) − P(A ∩ B), and independence gives P(A ∩ B) = P(A) × P(B).",
			"P(A ∩ B) = %s × %s = %s" % [T(s, pa), T(s, pb), W(s, s.pi)], "P(A ∪ B) = %s + %s − %s" % [T(s, pa), T(s, pb), W(s, s.pi)], final_step(ans)], ans.values),
		"complement-product": method(["A′ and B′ are independent too, so the chance of neither is P(A′) × P(B′).",
			"%s × %s = %s" % [T(s, one_minus(pa)), T(s, one_minus(pb)), W(s, one_minus(pa).mul(one_minus(pb)))],
			"At least one of them is the rest: 1 − %s" % W(s, one_minus(pa).mul(one_minus(pb))), final_step(ans)], ans.values)}
	return out


func u_conditional_from_independence(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pa: Q = s.pa
	var given: Q = one_minus(s.pb) if s.cond == "B′" else s.pb
	var v: Q = one_minus(pa) if s.want == "A′" else pa
	var name := "P(%s | %s)" % [s.want, s.cond]
	var ans := prob_ans(s, name + " = ", v)
	var out := {"answer": ans, "table": null, "asked": "Find %s." % name}
	out.lines = ["P(B) = " + T(s, s.pb), "P(A ∩ B) = " + T(s, s.pi), "A and B are independent."]
	out.wrongs = wr(v.mul(given), R_NOT_DIVIDED)
	out.generic = probs([one_minus(v), given, one_minus(given), s.pi, s.pb])
	var steps: Array = ["Independence gives P(A ∩ B) = P(A) × P(B), so P(A) = %s ÷ %s = %s." % [T(s, s.pi), T(s, s.pb), T(s, pa)],
		"Knowing whether B happened doesn't change the probability of A, so %s = P(%s)." % [name, s.want]]
	if s.want == "A′":
		steps.append("P(A′) = 1 − %s" % T(s, pa))
	steps.append(final_step(ans))
	out.methods = {"conditional-test": method(steps, ans.values)}
	return out


func u_unknown_from_union(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pa: Q = s.pa
	var pb: Q = s.pb
	var pu: Q = s.pu
	var ans := prob_ans(s, "probability = " if rep == "words" else "P(B) = ", pb)
	var c := pair(s)
	var a := T(s, pa)
	var u := T(s, pu)
	var out := {"answer": ans, "table": null}
	if rep == "words":
		out.lines = ["On any one day, %s %s with probability %s, independently of %s." % [c[0], c[2], a, c[1]],
			"The probability that at least one of them %s on a given day is %s." % [c[2], u], pair_named(c)]
		out.asked = "Find the probability that %s %s on a given day." % [c[1], c[2]]
	else:
		out.lines = ["P(A) = " + a, "P(A ∪ B) = " + u, "A and B are independent."]
		out.asked = "Find P(B)."
	var gap := pu.sub(pa)
	var rest := one_minus(pa)
	out.wrongs = wr(gap, R_AS_EXCLUSIVE)
	out.generic = probs([gap.div(Q.new(1).add(pa)), pu.mul(pa), pu, rest, pa, one_minus(pb)])
	var line := "%s = %s + x − %sx" % [u, a, Fmt.paren(pa)] if s.style == "frac" else "%s = %s + x − %sx" % [u, a, a]
	var solve := "%s = %sx, so x = %s ÷ %s" % [T(s, gap), Fmt.paren(rest) if s.style == "frac" else T(s, rest), W(s, gap), W(s, rest)]
	var nb := one_minus(pb)
	out.methods = {"addition-with-product": method(["Let P(B) = x. Independence gives P(A ∩ B) = %sx." % (Fmt.paren(pa) if s.style == "frac" else a), "The addition rule gives " + line, solve, final_step(ans)], ans.values),
		"complement-product": method(["A′ and B′ are independent too, so P(A′) × P(B′) = 1 − P(A ∪ B).",
			"%s × P(B′) = %s" % [T(s, rest), T(s, one_minus(pu))], "P(B′) = %s ÷ %s = %s" % [T(s, one_minus(pu)), T(s, rest), W(s, nb)],
			"P(B) = 1 − %s" % W(s, nb), final_step(ans)], ans.values),
		"venn-unknown": method(["Let P(B) = x, so the middle of the diagram is %sx and B only is x − %sx." % [Fmt.paren(pa) if s.style == "frac" else a, Fmt.paren(pa) if s.style == "frac" else a],
			"A together with B only is everything inside the circles: %s + x − %sx = %s" % [a, Fmt.paren(pa) if s.style == "frac" else a, u], solve, final_step(ans)], ans.values)}
	return out


func u_ratio_from_union(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.k
	var x: Q = s.pb
	var pu: Q = s.pu
	var ans := prob_ans(s, "P(B) = ", x)
	var out := {"answer": ans, "table": null, "asked": "Find P(B)."}
	out.lines = ["P(A) = %dP(B)" % k, "P(A ∪ B) = " + T(s, pu), "A and B are independent."]
	out.wrongs = wr(pu.div(Q.new(k + 1)), R_NO_OVERLAP)
	out.generic = probs([pu.div(Q.new(k)), s.pa, pu.sub(s.pa), x.mul(x), x.mul(Q.new(2)), x.add(Q.new(1, 10)), x.add(Q.new(1, 20))])
	var other := Q.new(k + 1, k).sub(x)
	var eq := "%dx² − %dx + %s = 0" % [k, k + 1, T(s, pu)]
	var roots := "The quadratic gives x = %s or x = %s." % [W(s, x), W(s, other)]
	var reject := "P(A) = %dx can't be more than 1, so x = %s is rejected." % [k, W(s, other)]
	out.methods = {"addition-with-product": method(["Let P(B) = x, so P(A) = %dx and P(A ∩ B) = %dx × x = %dx²." % [k, k, k],
			"The addition rule gives %s = %dx + x − %dx², so %s." % [T(s, pu), k, k, eq], roots, reject, final_step(ans)], ans.values),
		"complement-product": method(["Let P(B) = x. A′ and B′ are independent too, so (1 − %dx)(1 − x) = 1 − %s." % [k, T(s, pu)],
			"Expanding gives %s." % eq, roots, reject, final_step(ans)], ans.values),
		"venn-unknown": method(["Let P(B) = x. The middle of the diagram is %dx², A only is %dx − %dx² and B only is x − %dx²." % [k, k, k, k],
			"The three regions add to %s, so %s." % [T(s, pu), eq], roots, reject, final_step(ans)], ans.values)}
	return out


func u_overlap_from_only_regions(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Q = s.only_a
	var b: Q = s.only_b
	var x: Q = s.pi
	var ans := prob_ans(s, "x = ", x)
	var out := {"answer": ans, "table": null, "asked": "Find the value of x."}
	if rep == "diagram":
		out.lines = ["A and B are independent. The Venn diagram shows P(A ∩ B′), P(A′ ∩ B) and P(A ∩ B) = x."]
		out.graph = VennViews.venn_graph(Fmt.dec(a), "x", Fmt.dec(b), "")
	else:
		out.lines = ["P(A ∩ B′) = " + Fmt.dec(a), "P(A′ ∩ B) = " + Fmt.dec(b), "P(A ∩ B) = x", "A and B are independent."]
	out.wrongs = wr(a.mul(b), R_ONLY_PRODUCT)
	out.generic = probs([one_minus(a).sub(b), a.add(b), a, b, one_minus(a.add(b)).div(Q.new(3)), x.add(Q.new(1, 20))])
	var sum := a.add(b)
	var coef := one_minus(sum)
	out.methods = {"venn-unknown": method(["P(A) = %s + x and P(B) = %s + x." % [Fmt.dec(a), Fmt.dec(b)],
		"Independence says the middle is the product: x = (%s + x)(%s + x)." % [Fmt.dec(a), Fmt.dec(b)],
		"Expanding gives x² − %sx + %s = 0." % [Fmt.dec(coef), Fmt.dec(a.mul(b))],
		"This has one repeated root, x = %s." % W(s, x), final_step(ans)], ans.values)}
	return out


# ── Testing ──────────────────────────────────────────────────

## The two things compared, for the method asked.
func compared(s: Dictionary, rows: bool = false, tree: bool = false) -> Dictionary:
	var product := {"ln": "P(A ∩ B)", "lv": s.pi, "rn": "P(A) × P(B)", "rv": s.pa.mul(s.pb)}
	match angle:
		"table-proportions":
			return {"ln": "P(B | A)", "lv": s.pba, "rn": "P(B | A′)", "rv": s.pbn}
		"conditional-test":
			if tree:
				return {"ln": "P(B | A)", "lv": s.pba, "rn": "P(B | A′)", "rv": s.pbn}
			if rows:
				return {"ln": "P(B | A)", "lv": s.pba, "rn": "P(B)", "rv": s.pb}
			return {"ln": "P(A | B)", "lv": s.pi.div(s.pb), "rn": "P(A)", "rv": s.pa}
	return product


static func said(s: Dictionary, cmp: Dictionary, verdict: String) -> String:
	return "%s = %s and %s = %s, so A and B are %s" % [cmp.ln, H(s, cmp.lv), cmp.rn, H(s, cmp.rv), verdict]


## The test's answer: the two numbers typed, the verdict picked.
static func test_answer(s: Dictionary, cmp: Dictionary, options: Array, verdict: String) -> Dictionary:
	var v := {"l": cmp.lv, "r": cmp.rv, "verdict": verdict, "text": said(s, cmp, verdict)}
	var parts: Array = [cmp.ln + " = ", {"slot": "l"}, " and %s = " % cmp.rn, {"slot": "r"}, ", so A and B are ", {"pick": "verdict", "options": options}]
	var ans := Answer.make("form", v, {"parts": parts})
	if s.paper == 1:
		ans.exact = true
	return ans


static func other_verdict(s: Dictionary, cmp: Dictionary, verdict: String) -> Dictionary:
	return {"l": cmp.lv, "r": cmp.rv, "verdict": verdict, "text": said(s, cmp, verdict)}


## Three wrong options on true numbers: the test read backwards, and P(A ∩ B) against 0 ending
## in each verdict. So two options end in each verdict, whichever is right.
static func test_wrongs(s: Dictionary, cmp: Dictionary) -> Array:
	var other := NO if s.indep else YES
	var nonzero := "P(A ∩ B) = %s, which is not 0, so A and B are " % H(s, s.pi)
	return [wrong(other_verdict(s, cmp, other), R_REVERSED),
		wrong({"text": nonzero + NO, "shape": "one number"}, R_OVERLAP if s.indep else R_ONE_NUMBER),
		wrong({"text": nonzero + YES, "shape": "one number"}, R_MIX)]


static func compare_line(s: Dictionary, ln: String, lv: Q, rn: String, rv: Q) -> String:
	if lv.eq(rv):
		return "%s = %s, which is exactly %s, so the two are equal." % [ln, W(s, lv), rn]
	return "%s = %s and %s = %s, so the two are different." % [ln, W(s, lv), rn, W(s, rv)]


static func sentence(t: String) -> String:
	return t if t.ends_with(".") else t + "."


## A worked solution has five steps at most: the opening two become one if need be.
static func five(steps: Array) -> Array:
	return [sentence(steps[0]) + " " + steps[1]] + steps.slice(2) if steps.size() > 5 else steps


## Every test's methods. lead: the steps that find P(A), P(B) and P(A ∩ B). A method other than
## the one asked compares its own two numbers, then works out and gives the numbers asked for.
func test_methods(s: Dictionary, ans: Dictionary, lead: Array, rows: bool = false, tree: bool = false, table: bool = false) -> Dictionary:
	var pa: Q = s.pa
	var pb: Q = s.pb
	var product := pa.mul(pb)
	var given: Q = s.pi.div(pb)
	var product_step := "P(A) × P(B) = %s × %s = %s" % [E(s, pa), E(s, pb), W(s, product)]
	var given_step := "P(A | B) = P(A ∩ B) ÷ P(B) = %s ÷ %s = %s" % [E(s, s.pi), E(s, pb), W(s, given)]
	var branch_steps: Array = []
	if tree:
		branch_steps = ["P(B | A) = %d ÷ %d = %s and P(B | A′) = %d ÷ %d = %s" % [s.g1, s.n1, W(s, s.pba), s.g2, s.n2, W(s, s.pbn)]]
	elif table:
		branch_steps = ["In the row for A, P(B | A) = %d ÷ %d = %s." % [s.i, s.i + s.a, W(s, s.pba)], "In the row for A′, P(B | A′) = %d ÷ %d = %s." % [s.b, s.b + s.o, W(s, s.pbn)]]
	# What a method not asked still has to work out, once it has its verdict. A method that
	# skipped the lead has neither P(A ∩ B) nor P(B) yet.
	var to_asked := func(id: String) -> Array:
		if id == angle:
			return []
		var has_lead: bool = id != "table-proportions" and not (tree and id == "conditional-test")
		var todo: Array = [] if has_lead else lead.duplicate()
		match angle:
			"product-test":
				todo.append(product_step)
			"table-proportions":
				todo += branch_steps
			"conditional-test":
				if tree:
					todo += branch_steps
				elif not rows:
					todo.append(given_step)
		return [" ".join(todo.map(sentence))] if not todo.is_empty() else []
	var end := func(id: String) -> String:
		var text := Answer.text(ans) + "."
		return text if id == angle else "That gives the same verdict. In the numbers asked for, " + text
	var out := {}
	out["product-test"] = method(five(lead + [product_step, compare_line(s, "P(A ∩ B)", s.pi, "P(A) × P(B)", product)] + to_asked.call("product-test")
		+ [end.call("product-test")]), ans.values)
	if tree or table:
		var id := "conditional-test" if tree else "table-proportions"
		var opening: Array = ["Independent means the chance of B is the same after A and after A′, so compare those two branches."] if tree else []
		out[id] = method(five(opening + branch_steps + [compare_line(s, "P(B | A)", s.pba, "P(B | A′)", s.pbn)] + to_asked.call(id) + [end.call(id)]), ans.values)
	if not tree:
		if rows:
			out["conditional-test"] = method(five(lead + ["Independent means knowing A doesn't change the probability of B, so compare P(B | A) with P(B).",
				compare_line(s, "P(B | A)", s.pba, "P(B)", pb)] + to_asked.call("conditional-test") + [end.call("conditional-test")]), ans.values)
		else:
			out["conditional-test"] = method(five(lead + [given_step, compare_line(s, "P(A | B)", given, "P(A)", pa)] + to_asked.call("conditional-test")
				+ [end.call("conditional-test")]), ans.values)
	return out


static func decide() -> String:
	return "Determine whether A and B are independent, with a valid reason."


## Names A and B in a story.
static func named(s: Dictionary) -> String:
	var c := VennViews.ctx(s)
	return "One %s is chosen at random. A is the event that the %s %s, and B the event that the %s %s." % [c.one, c.one, c.a1, c.one, c.b1]


func u_test_from_probabilities(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := VennViews.ctx(s)
	var pa: Q = s.pa
	var pb: Q = s.pb
	var cmp := compared(s)
	var verdict := YES if s.indep else NO
	var ans := test_answer(s, cmp, [YES, NO], verdict)
	var out := {"answer": ans, "table": null, "asked": decide(), "generic": []}
	var lead: Array = []
	match s.form:
		"inter":
			out.lines = ["P(A) = " + T(s, pa), "P(B) = " + T(s, pb), "P(A ∩ B) = " + T(s, s.pi)]
		"union":
			out.lines = ["P(A) = " + T(s, pa), "P(B) = " + T(s, pb), "P(A ∪ B) = " + T(s, s.pu)]
			lead = ["P(A ∩ B) = P(A) + P(B) − P(A ∪ B) = %s + %s − %s = %s" % [T(s, pa), T(s, pb), T(s, s.pu), W(s, s.pi)]]
		"pct":
			out.lines = ["In a camp, %s of the %s %s, %s %s and %s do both." % [pct(pa), c.who, c.a, pct(pb), c.b, pct(s.pi)], named(s)]
			lead = ["As probabilities, P(A) = %s, P(B) = %s and P(A ∩ B) = %s." % [T(s, pa), T(s, pb), T(s, s.pi)]]
		"share":
			out.lines = ["In a camp, %s of the %s %s and %s %s." % [pct(pa), c.who, c.a, pct(pb), c.b], "Of those who %s, %s also %s." % [c.a, pct(s.pba), c.b], named(s)]
			lead = ["%s is P(B | A), so P(A ∩ B) = P(A) × P(B | A) = %s × %s = %s." % [pct(s.pba), T(s, pa), T(s, s.pba), T(s, s.pi)]]
	out.wrongs = test_wrongs(s, cmp)
	out.methods = test_methods(s, ans, lead)
	return out


func u_test_from_venn(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var cmp := compared(s)
	var ans := test_answer(s, cmp, [YES, NO], YES if s.indep else NO)
	var out := {"answer": ans, "table": null, "asked": decide(), "generic": [], "lines": [VennViews.diagram_line(s)], "graph": VennViews.diagram(s)}
	out.wrongs = test_wrongs(s, cmp)
	var lead: Array = ["From the diagram, P(A) = %s, P(B) = %s and P(A ∩ B) = %s." % [E(s, s.pa), E(s, s.pb), E(s, s.pi)]]
	out.methods = test_methods(s, ans, lead)
	return out


func u_test_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var cmp := compared(s)
	var ans := test_answer(s, cmp, [YES, NO], YES if s.indep else NO)
	var out := {"answer": ans, "asked": decide(), "generic": [], "lines": [VennViews.table_line(s), VennViews.chosen(s)], "table": VennViews.two_way(s)}
	out.wrongs = test_wrongs(s, cmp)
	var lead: Array = ["From the totals, P(A) = %d/%d, P(B) = %d/%d and P(A ∩ B) = %d/%d." % [s.a + s.i, s.u, s.b + s.i, s.u, s.i, s.u]]
	out.methods = test_methods(s, ans, lead, false, false, true)
	return out


func u_test_from_tree(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Array = SOURCES[s.ctx]
	var cmp := compared(s, false, true)
	var ans := test_answer(s, cmp, [YES, NO], YES if s.indep else NO)
	var out := {"answer": ans, "table": null, "asked": decide(), "generic": []}
	var pa: Q = s.pa
	var who := "A scavenger picks %s 1 with probability %s, or else %s 2, and %s." % [c[0], T(s, pa), c[0], c[4]]
	if pa.eq(Q.new(1, 2)):
		who = "A scavenger picks one of the two %s at random and %s." % [c[6], c[4]]
	var names := "A is the event that %s 1 is picked, and B the event that %s." % [c[0], c[5]]
	if rep == "diagram":
		out.lines = [who, names + " The tree shows the probabilities."]
		var qa := ["%d/%d" % [s.g1, s.n1], "%d/%d" % [s.n1 - s.g1, s.n1]]
		var qb := ["%d/%d" % [s.g2, s.n2], "%d/%d" % [s.n2 - s.g2, s.n2]]
		out.graph = {"kind": "tree", "first": ["A", "A′"], "second": ["B", "B′"], "p": [T(s, pa), T(s, one_minus(pa))], "q": [qa, qb]}
	else:
		out.lines = ["%s 1 holds %d %s and %d %s %s. %s 2 holds %d %s and %d %s %s." % [cap(c[0]), s.g1, c[2], s.n1 - s.g1, c[3], c[1], cap(c[0]), s.g2, c[2], s.n2 - s.g2, c[3], c[1]], who, names]
	out.wrongs = test_wrongs(s, cmp)
	var lead: Array = ["P(A ∩ B) = %s × %d/%d = %s" % [T(s, pa), s.g1, s.n1, W(s, s.pi)],
		"P(B) adds both paths: %s + %s × %d/%d = %s" % [W(s, s.pi), T(s, one_minus(pa)), s.g2, s.n2, W(s, s.pb)]]
	out.methods = test_methods(s, ans, lead, false, true)
	return out


func u_test_from_conditional(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var cmp := compared(s, true)
	var ans := test_answer(s, cmp, [YES, NO], YES if s.indep else NO)
	var out := {"answer": ans, "table": null, "asked": decide(), "generic": []}
	out.lines = ["P(A) = " + T(s, s.pa), "P(A ∪ B) = " + T(s, s.pu), "P(B | A) = " + T(s, s.pba)]
	out.wrongs = test_wrongs(s, cmp)
	var lead: Array = ["P(A ∩ B) = P(B | A) × P(A) = %s × %s = %s" % [T(s, s.pba), T(s, s.pa), W(s, s.pi)],
		"P(B) = P(A ∪ B) − P(A) + P(A ∩ B) = %s − %s + %s = %s" % [T(s, s.pu), T(s, s.pa), W(s, s.pi), W(s, s.pb)]]
	out.methods = test_methods(s, ans, lead, true)
	return out


func u_classify_events(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := VennViews.ctx(s)
	var pa: Q = s.pa
	var pb: Q = s.pb
	var cmp := {"ln": "P(A ∩ B)", "lv": s.pi, "rn": "P(A) × P(B)", "rv": pa.mul(pb)}
	var right: String = {"excl": CLASSES[0], "indep": CLASSES[1], "neither": CLASSES[3]}[s.kind]
	var ans := test_answer(s, cmp, CLASSES, right)
	var out := {"answer": ans, "table": null, "asked": "Decide how A and B are related, with a valid reason.", "generic": []}
	var first := "P(A ∩ B) = P(A) + P(B) − P(A ∪ B) = %s + %s − %s = %s" % [T(s, pa), T(s, pb), T(s, s.pu), E(s, s.pi)]
	if rep == "diagram":
		out.lines = [VennViews.diagram_line(s)]
		out.graph = VennViews.diagram(s)
		first = "From the diagram, P(A) = %s, P(B) = %s and P(A ∩ B) = %s." % [E(s, pa), E(s, pb), E(s, s.pi)]
	elif s.form == "pct":
		out.lines = ["In a camp, %s of the %s %s and %s %s. In all, %s do at least one of these." % [pct(pa), c.who, c.a, pct(pb), c.b, pct(s.pu)], named(s)]
	else:
		out.lines = ["P(A) = " + T(s, pa), "P(B) = " + T(s, pb), "P(A ∪ B) = " + T(s, s.pu)]
	var tags: Dictionary = {"excl": {CLASSES[1]: R_MIX}, "indep": {CLASSES[0]: R_MIX, CLASSES[3]: R_OVERLAP}, "neither": {CLASSES[1]: R_REVERSED}}[s.kind]
	var wrongs: Array = []
	for name in CLASSES:
		if name != right:
			wrongs.append(wrong(other_verdict(s, cmp, name), tags.get(name, "")))
	out.wrongs = wrongs
	var why: String = {"excl": "P(A ∩ B) = 0, so A and B are mutually exclusive. P(A) × P(B) is not 0, so they are not independent.",
		"indep": "P(A ∩ B) is not 0, so A and B are not mutually exclusive. It equals P(A) × P(B), so they are independent.",
		"neither": "P(A ∩ B) is not 0, so A and B are not mutually exclusive. It is not P(A) × P(B), so they are not independent."}[s.kind]
	out.methods = {"product-test": method([first,
		"P(A) × P(B) = %s × %s = %s" % [E(s, pa), E(s, pb), W(s, pa.mul(pb))], why, Answer.text(ans) + "."], ans.values)}
	return out
