class_name VennViews
extends ExtensionViews
## The views on the `venn` situation: one builder per unknown of t4-venn-addition-rule
## (FAL-725). Paper 1 answers are exact, as a fraction or a decimal; Paper 2 has decimals to 3
## places, or counts answered to 3 s.f.
##
## Representations: "equation" (P(A) = 0.4, ...), "words" (a story of counts), "diagram" (a Venn
## diagram, drawn by PlotView's `venn`) and "table" (a two-way table with totals).

const SKILL := "SL4.6."
const R_DOUBLE := SKILL + "union#0"
const R_TIMES := SKILL + "union#1"
const R_EXACTLY_ONE := SKILL + "union#2"
const R_N_A := SKILL + "venn#0"
const R_NO_OUTSIDE := SKILL + "venn#1"
const R_NEITHER := SKILL + "venn#2"

## The stories: who is counted, one of them, and what A and B are, plural and singular.
const CONTEXTS := [
	{"who": "scavengers", "one": "scavenger", "a": "carry a radio", "b": "carry a water filter", "a1": "carries a radio", "b1": "carries a water filter"},
	{"who": "traders", "one": "trader", "a": "sell fuel", "b": "sell salt", "a1": "sells fuel", "b1": "sells salt"},
	{"who": "guards", "one": "guard", "a": "own a crossbow", "b": "own a shield", "a1": "owns a crossbow", "b1": "owns a shield"},
	{"who": "settlers", "one": "settler", "a": "keep goats", "b": "grow beans", "a1": "keeps goats", "b1": "grows beans"},
	{"who": "mechanics", "one": "mechanic", "a": "repair engines", "b": "repair radios", "a1": "repairs engines", "b1": "repairs radios"},
	{"who": "drivers", "one": "driver", "a": "hold a permit", "b": "carry a spare wheel", "a1": "holds a permit", "b1": "carries a spare wheel"},
	{"who": "medics", "one": "medic", "a": "carry bandages", "b": "carry painkillers", "a1": "carries bandages", "b1": "carries painkillers"},
	{"who": "farmers", "one": "farmer", "a": "use a well", "b": "use a rain tank", "a1": "uses a well", "b1": "uses a rain tank"},
]

const UNKNOWNS := ["union-from-rule", "intersection-from-rule", "neither-from-rule", "union-from-regions", "union-from-table",
	"one-event-only", "exactly-one", "region-from-totals", "x-from-total", "table-missing-entry", "least-overlap", "greatest-overlap"]
## The unknowns answered with a whole number, not a probability.
const COUNTS := ["region-from-totals", "x-from-total", "table-missing-entry"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1, 2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = VennSituation.export(s)
	# The engine's last-resort nudges add 1, which is no probability.
	if not unknown in COUNTS:
		var v: Q = out.answer.values.v
		var unit := Q.new(1, s.get("u", 100))
		for k in [1, -1, 2, -2, 3, -3, 4, -4, 5, -5]:
			out.generic.append_array(probs([v.add(unit.mul(Q.new(k)))]))
	return out


# ── Writing things ───────────────────────────────────────────

static func ctx(s: Dictionary) -> Dictionary:
	return CONTEXTS[s.ctx]


static func pr(s: Dictionary, n: int) -> Q:
	return Q.new(n, s.u)


## A probability as this question writes it.
static func T(s: Dictionary, v: Q) -> String:
	return Fmt.dec(v) if s.style == "dec" else Fmt.num(v)


## The probability answer: exact, except a Paper 2 count, whose options are all to 3 s.f.
static func prob_ans(s: Dictionary, label: String, v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	if s.style == "dec":
		ans.show = "dec"
		ans.exact = true
	elif s.style == "frac" or s.paper == 1:
		ans.exact = true
	else:
		ans.show = "sf"
	return ans


static func count_ans(label: String, n: int) -> Dictionary:
	var ans := Answer.make("number", {"v": Q.new(n)}, {}, label)
	ans.exact = true
	return ans


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


## Wrong options that are probabilities.
static func probs(xs: Array) -> Array:
	return xs.filter(func(x): return x.sign() > 0 and x.lt(Q.new(1))).map(func(x): return {"v": x})


## Only a wrong option that is a probability is offered.
static func wr(v: Q, ref: String) -> Array:
	return [wrong({"v": v}, ref)] if v.sign() > 0 and v.lt(Q.new(1)) else []


## "Of the 120 scavengers in a camp, 70 carry a radio, 50 carry a water filter and 20 do both."
static func story(s: Dictionary) -> String:
	var c := ctx(s)
	return "Of the %d %s in a camp, %d %s, %d %s and %d do both." % [s.u, c.who, s.a + s.i, c.a, s.b + s.i, c.b, s.i]


static func chosen(s: Dictionary) -> String:
	return "One %s is chosen at random." % ctx(s).one


static func venn_graph(a: String, i: String, b: String, o: String) -> Dictionary:
	return {"kind": "venn", "names": ["A", "B"], "a": a, "i": i, "b": b, "o": o}


## The diagram of the situation's regions, as counts or decimals.
static func diagram(s: Dictionary) -> Dictionary:
	if s.style == "dec":
		return venn_graph(Fmt.dec(pr(s, s.a)), Fmt.dec(pr(s, s.i)), Fmt.dec(pr(s, s.b)), Fmt.dec(pr(s, s.o)))
	return venn_graph(str(s.a), str(s.i), str(s.b), str(s.o))


static func diagram_line(s: Dictionary) -> String:
	if s.style == "dec":
		return "The Venn diagram shows the probability of each region for events A and B."
	return "The Venn diagram shows how many of %d outcomes are in each region for events A and B. One is chosen at random." % s.u


static func both(s: Dictionary) -> Array:
	return ["P(A) = " + T(s, pr(s, s.a + s.i)), "P(B) = " + T(s, pr(s, s.b + s.i))]


# ── The addition rule ────────────────────────────────────────

func u_union_from_rule(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := pr(s, s.a + s.i + s.b)
	var ans := prob_ans(s, "P(A ∪ B) = " if rep == "equation" else "probability = ", v)
	var c := ctx(s)
	var out := {"table": null, "answer": ans}
	if rep == "equation":
		out.lines = both(s) + ["P(A ∩ B) = " + T(s, pr(s, s.i))]
		out.asked = "Find P(A ∪ B)."
	else:
		out.lines = [story(s), chosen(s)]
		out.asked = "Find the probability that the %s %s or %s, or both." % [c.one, c.a1, c.b1]
	var pa := pr(s, s.a + s.i)
	var pb := pr(s, s.b + s.i)
	out.wrongs = wr(pa.add(pb), R_DOUBLE) + wr(pa.mul(pb), R_TIMES) + wr(pr(s, s.a + s.b), R_EXACTLY_ONE)
	out.generic = probs([pa.add(pb).sub(pr(s, 2 * s.i)), pr(s, s.i), pr(s, s.o), pr(s, s.a)])
	var i_t := T(s, pr(s, s.i))
	out.methods = {"addition-rule": method(["P(A ∪ B) = P(A) + P(B) − P(A ∩ B)", "= %s + %s − %s" % [T(s, pa), T(s, pb), i_t], final_step(ans)], ans.values),
		"venn-regions": method(["Put %s in the middle. A only is %s and B only is %s." % [i_t, T(s, pr(s, s.a)), T(s, pr(s, s.b))],
			"Add the three regions inside the circles: %s + %s + %s" % [T(s, pr(s, s.a)), i_t, T(s, pr(s, s.b))], final_step(ans)], ans.values)}
	return out


func u_intersection_from_rule(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := pr(s, s.i)
	var ans := prob_ans(s, "P(A ∩ B) = " if rep == "equation" else "probability = ", v)
	var c := ctx(s)
	var pa := pr(s, s.a + s.i)
	var pb := pr(s, s.b + s.i)
	var pu := pr(s, s.a + s.i + s.b)
	var out := {"table": null, "answer": ans}
	if rep == "equation":
		out.lines = both(s) + ["P(A ∪ B) = " + T(s, pu)]
		out.asked = "Find P(A ∩ B)."
	else:
		out.lines = ["Of the %d %s in a camp, %d %s and %d %s. In all, %d do at least one of these." % [s.u, c.who, s.a + s.i, c.a, s.b + s.i, c.b, s.a + s.i + s.b], chosen(s)]
		out.asked = "Find the probability that the %s %s and %s." % [c.one, c.a1, c.b1]
	out.wrongs = wr(pa.mul(pb), R_TIMES)
	out.generic = probs([pu.sub(pa), pu.sub(pb), Q.new(1).sub(pu), pa.add(pb).sub(pu).add(pr(s, 1))])
	out.methods = {"addition-rule": method(["P(A ∪ B) = P(A) + P(B) − P(A ∩ B), so P(A ∩ B) = P(A) + P(B) − P(A ∪ B)", "= %s + %s − %s" % [T(s, pa), T(s, pb), T(s, pu)], final_step(ans)], ans.values),
		"venn-regions": method(["Inside the circles the total is %s, but P(A) and P(B) add to %s." % [T(s, pu), T(s, pa.add(pb))],
			"The overlap was counted twice, so it is the difference: %s − %s" % [T(s, pa.add(pb)), T(s, pu)], final_step(ans)], ans.values)}
	return out


func u_neither_from_rule(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := pr(s, s.o)
	var ans := prob_ans(s, "P(A′ ∩ B′) = " if rep == "equation" else "probability = ", v)
	var c := ctx(s)
	var pa := pr(s, s.a + s.i)
	var pb := pr(s, s.b + s.i)
	var pu := pr(s, s.a + s.i + s.b)
	var out := {"table": null, "answer": ans}
	if rep == "equation":
		out.lines = both(s) + ["P(A ∩ B) = " + T(s, pr(s, s.i))]
		out.asked = "Find P(A′ ∩ B′)."
	else:
		out.lines = [story(s), chosen(s)]
		out.asked = "Find the probability that the %s does neither." % c.one
	out.wrongs = wr(Q.new(1).sub(pa).sub(pb), R_DOUBLE)
	out.generic = probs([pu, pr(s, s.i), Q.new(1).sub(pr(s, s.i)), pr(s, s.o + s.i + 1)])
	out.methods = {"one-minus-neither": method(["P(A ∪ B) = %s + %s − %s = %s" % [T(s, pa), T(s, pb), T(s, pr(s, s.i)), T(s, pu)], "Neither is everything outside the union: 1 − %s" % T(s, pu), final_step(ans)], ans.values),
		"venn-regions": method(["The three regions inside the circles are %s, %s and %s." % [T(s, pr(s, s.a)), T(s, pr(s, s.i)), T(s, pr(s, s.b))],
			"What is left of 1 is outside both: 1 − %s" % T(s, pu), final_step(ans)], ans.values)}
	return out


func u_union_from_regions(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := pr(s, s.a + s.i + s.b)
	var ans := prob_ans(s, "P(A ∪ B) = ", v)
	var out := {"lines": [diagram_line(s)], "asked": "Find P(A ∪ B).", "answer": ans, "table": null, "graph": diagram(s)}
	out.wrongs = wr(pr(s, s.a + s.b + 2 * s.i), R_DOUBLE) + wr(pr(s, s.a + s.b), R_EXACTLY_ONE)
	out.generic = probs([pr(s, s.o), pr(s, s.i), pr(s, s.a + s.i), pr(s, s.b + s.i)])
	out.methods = {"venn-regions": method(["A ∪ B is all three regions inside the circles, the middle counted once.", "%s + %s + %s" % [_r(s, s.a), _r(s, s.i), _r(s, s.b)], final_step(ans)], ans.values),
		"one-minus-neither": method(["The region outside both circles is %s." % _r(s, s.o), "P(A ∪ B) = 1 − P(A′ ∩ B′)", final_step(ans)], ans.values)}
	return out


## A region as the diagram writes it, as a probability.
static func _r(s: Dictionary, n: int) -> String:
	return Fmt.dec(pr(s, n)) if s.style == "dec" else "%d/%d" % [n, s.u]


# ── Two-way tables ───────────────────────────────────────────

static func two_way(s: Dictionary, hide: Dictionary = {}) -> Dictionary:
	var cell := func(id: String, n: int) -> String: return hide.get(id, str(n))
	return {"rows": [["", ["B", "B′", "Total"]],
		["A", [cell.call("i", s.i), cell.call("a", s.a), cell.call("na", s.a + s.i)]],
		["A′", [cell.call("b", s.b), cell.call("o", s.o), cell.call("na'", s.b + s.o)]],
		["Total", [cell.call("nb", s.b + s.i), cell.call("nb'", s.a + s.o), cell.call("u", s.u)]]]}


static func table_line(s: Dictionary) -> String:
	var c := ctx(s)
	return "The table shows %d %s. A means they %s and B means they %s." % [s.u, c.who, c.a, c.b]


func u_union_from_table(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := pr(s, s.a + s.i + s.b)
	var ans := prob_ans(s, "P(A ∪ B) = ", v)
	var out := {"lines": [table_line(s), chosen(s)], "asked": "Find P(A ∪ B).", "answer": ans, "table": two_way(s)}
	out.wrongs = wr(pr(s, s.a + s.b + 2 * s.i), R_DOUBLE) + wr(pr(s, s.a + s.b), R_EXACTLY_ONE)
	out.generic = probs([pr(s, s.o), pr(s, s.i), pr(s, s.a + s.i)])
	var n: int = s.a + s.i + s.b
	out.methods = {"two-way-table": method(["Add every cell in row A or column B, counting the shared cell once: %d + %d + %d = %d" % [s.a, s.i, s.b, n],
		"Divide by the grand total: %d ÷ %d" % [n, s.u], final_step(ans)], ans.values)}
	return out


func u_table_missing_entry(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var hide := {"i": "–", "a": "–", "b": "–", "o": "–", "na": "–", "nb": "–", "na'": "–", "nb'": "–"}
	var shown := ["i", "na", "nb"]
	var worth: Dictionary = {"a": s.a, "b": s.b, "o": s.o, "na'": s.b + s.o, "nb'": s.a + s.o}
	var n: int = worth[s.cell]
	for id in shown:
		hide.erase(id)
	hide[s.cell] = "?"
	var ans := count_ans("? = ", n)
	var out := {"lines": ["The two-way table shows %d outcomes." % s.u], "asked": "Find the entry marked ?.", "answer": ans, "table": two_way(s, hide)}
	var pool: Array = [s.a, s.b, s.o, s.a + s.i, s.b + s.i, s.u - s.i, n + 1, n + 2]
	out.generic = pool.filter(func(x): return x > 0).map(func(x): return {"v": Q.new(x)})
	var step: String = {"a": "%d − %d = %d" % [s.a + s.i, s.i, s.a], "b": "%d − %d = %d" % [s.b + s.i, s.i, s.b],
		"na'": "%d − %d = %d" % [s.u, s.a + s.i, s.b + s.o], "nb'": "%d − %d = %d" % [s.u, s.b + s.i, s.a + s.o],
		"o": "%d − %d = %d, then %d − %d = %d" % [s.u, s.a + s.i, s.b + s.o, s.b + s.o, s.b, s.o]}[s.cell]
	out.methods = {"two-way-table": method(["Every row and column adds to its total. Work from the entries you have.", step, final_step(ans)], ans.values)}
	return out


# ── Regions of the diagram ───────────────────────────────────

func u_one_event_only(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := pr(s, s.a)
	var ans := prob_ans(s, "P(A ∩ B′) = ", v)
	var pa := pr(s, s.a + s.i)
	var out := {"asked": "Find P(A ∩ B′).", "answer": ans, "table": null}
	if rep == "equation":
		out.lines = both(s) + ["P(A ∩ B) = " + T(s, pr(s, s.i))]
	else:
		out.lines = [diagram_line(s)]
		out.graph = diagram(s)
	out.wrongs = wr(pr(s, s.o), R_NEITHER) + wr(pa, R_N_A)
	out.generic = probs([pr(s, s.b), pr(s, s.i), pr(s, s.a + s.b)])
	out.methods = {"set-notation": method(["P(A ∩ B′) = P(A) − P(A ∩ B)", "= %s − %s" % [T(s, pa), T(s, pr(s, s.i))], final_step(ans)], ans.values),
		"fill-from-middle": method(["Put %s in the middle of the diagram." % T(s, pr(s, s.i)), "A ∩ B′ is the part of A outside B: %s − %s" % [T(s, pa), T(s, pr(s, s.i))], final_step(ans)], ans.values)}
	return out


func u_exactly_one(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := pr(s, s.a + s.b)
	var ans := prob_ans(s, "probability = ", v)
	var c := ctx(s)
	var pa := pr(s, s.a + s.i)
	var pb := pr(s, s.b + s.i)
	var mid := pr(s, s.i)
	var out := {"answer": ans, "table": null}
	if rep == "diagram":
		out.lines = [diagram_line(s)]
		out.graph = diagram(s)
		out.asked = "Find the probability that exactly one of A and B happens."
	else:
		out.lines = [story(s), chosen(s)]
		out.asked = "Find the probability that the %s does exactly one of these." % c.one
	out.wrongs = wr(pr(s, s.a + s.i + s.b), R_EXACTLY_ONE)
	out.generic = probs([pr(s, s.i), pr(s, s.o), pa, pb])
	out.methods = {"fill-from-middle": method(["Put %s in the middle. A only is %s and B only is %s." % [T(s, mid), T(s, pr(s, s.a)), T(s, pr(s, s.b))], "Exactly one is those two regions: %s + %s" % [T(s, pr(s, s.a)), T(s, pr(s, s.b))], final_step(ans)], ans.values),
		"set-notation": method(["P(exactly one) = P(A) + P(B) − 2P(A ∩ B)", "= %s + %s − 2 × %s" % [T(s, pa), T(s, pb), T(s, mid)], final_step(ans)], ans.values)}
	return out


func u_region_from_totals(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var ans := count_ans("number = ", s.o)
	var na: int = s.a + s.i
	var nb: int = s.b + s.i
	var out := {"answer": ans, "table": null}
	if rep == "diagram":
		out.lines = ["n(U) = %d, n(A) = %d and n(B) = %d" % [s.u, na, nb]]
		out.graph = venn_graph("", str(s.i), "", "?")
		out.asked = "Find the number in the region marked ?."
	else:
		out.lines = [story(s)]
		out.asked = "Find the number of %s who do neither." % c.who
	var wrongs: Array = [wrong({"v": Q.new(0)}, R_NO_OUTSIDE)]
	if s.u - na - nb - s.i > 0:
		wrongs.insert(0, wrong({"v": Q.new(s.u - na - nb - s.i)}, R_N_A))
	out.wrongs = wrongs
	var pool: Array = [s.u - na, s.u - nb, s.u - s.i, s.o + 1, s.o + 2, s.o + s.i]
	out.generic = pool.filter(func(x): return x > 0).map(func(x): return {"v": Q.new(x)})
	out.methods = {"fill-from-middle": method(["Put %d in the middle. A only is %d − %d = %d and B only is %d − %d = %d." % [s.i, na, s.i, s.a, nb, s.i, s.b],
		"The three regions inside the circles add to %d." % [s.a + s.i + s.b], "What is left of %d is outside both: %d − %d = %d" % [s.u, s.u, s.a + s.i + s.b, s.o], final_step(ans)], ans.values)}
	return out


## "2x + 3", "x", "3x − 1".
static func lin(m: int, c: int) -> String:
	var t := ("x" if m == 1 else "%dx" % m)
	if c == 0:
		return t
	return "%s %s %d" % [t, "−" if c < 0 else "+", absi(c)]


func u_x_from_total(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := count_ans("x = ", s.x)
	var ta := lin(s.ma, s.ca)
	var ti := lin(s.mi, s.ci)
	var tb := lin(s.mb, s.cb)
	var c := ctx(s)
	var out := {"asked": "Find x.", "answer": ans, "table": null}
	if rep == "diagram":
		out.lines = ["The Venn diagram shows the number in each region. The total is %d." % s.u]
		out.graph = venn_graph(ta, ti, tb, str(s.o))
	else:
		out.lines = ["Of the %d %s in a camp, %s only %s, %s only %s, %s do both and %d do neither." % [s.u, c.who, ta, c.a, tb, c.b, ti, s.o]]
	var m: int = s.ma + s.mi + s.mb
	var k: int = s.ca + s.ci + s.cb
	var no_out := Q.new(s.u - k, m)
	out.wrongs = [wrong({"v": no_out}, R_NO_OUTSIDE)]
	out.generic = [{"v": Q.new(s.u - k - s.o)}, {"v": Q.new(s.x + 1)}, {"v": Q.new(s.x - 1)}, {"v": Q.new(s.x + 2)}]
	out.methods = {"unknown-total": method(["The four regions add to the total: (%s) + (%s) + (%s) + %d = %d" % [ta, ti, tb, s.o, s.u],
		"%dx + %d = %d" % [m, k + s.o, s.u], "%dx = %d, so x = %d" % [m, s.u - k - s.o, s.x], final_step(ans)], ans.values)}
	return out


# ── Least and greatest overlap ───────────────────────────────

func u_least_overlap(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var sum: Q = s.pa.add(s.pb)
	var v: Q = sum.sub(Q.new(1))
	var ans := Answer.make("number", {"v": v}, {}, "P(A ∩ B) = ")
	ans.show = "dec"
	ans.exact = true
	var out := {"lines": ["P(A) = " + Fmt.dec(s.pa), "P(B) = " + Fmt.dec(s.pb)], "asked": "Find the least possible value of P(A ∩ B).", "answer": ans, "table": null}
	out.wrongs = wr(s.pa.mul(s.pb), R_TIMES)
	out.generic = probs([Q.new(1, 100), s.pa, s.pb, Q.new(1).sub(s.pa), Q.new(1).sub(s.pb)])
	out.methods = {"addition-rule": method(["P(A ∪ B) = P(A) + P(B) − P(A ∩ B), and P(A ∪ B) ≤ 1.", "So %s + %s − P(A ∩ B) ≤ 1, which gives P(A ∩ B) ≥ %s" % [Fmt.dec(s.pa), Fmt.dec(s.pb), Fmt.dec(v)], final_step(ans)], ans.values)}
	return out


func u_greatest_overlap(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var small: Q = s.pa if s.pa.lt(s.pb) else s.pb
	var big: Q = s.pb if s.pa.lt(s.pb) else s.pa
	var ans := Answer.make("number", {"v": small}, {}, "P(A ∩ B) = ")
	ans.show = "dec"
	ans.exact = true
	var out := {"lines": ["P(A) = " + Fmt.dec(s.pa), "P(B) = " + Fmt.dec(s.pb)], "asked": "Find the greatest possible value of P(A ∩ B).", "answer": ans, "table": null}
	out.wrongs = wr(s.pa.mul(s.pb), R_TIMES)
	out.generic = probs([big, s.pa.add(s.pb).sub(Q.new(1)), Q.new(1).sub(small), Q.new(1).sub(big)])
	out.methods = {"addition-rule": method(["A ∩ B is inside A and inside B, so it can be no bigger than either.", "It is largest when the smaller event sits inside the other: P(A ∩ B) = %s" % Fmt.dec(small), final_step(ans)], ans.values)}
	return out
