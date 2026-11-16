class_name MutuallyExclusiveViews
extends ExtensionViews
## The views on the `mutually-exclusive` situation: one builder per unknown of
## t4-ext-mutually-exclusive (FAL-777). A decision is a pick of four written answers, each a
## verdict and its reason: the right one, and the slips that test independence, add the two
## probabilities and compare with 1, or look at the union. A value is exact, in decimals.
##
## Representations: "equation" (P(A) = 0.3, ...), "diagram" (a Venn diagram of counts, drawn by
## PlotView's `venn`) and "words" (a fair die, spinner or cards, or a story).

const SK := "SL4.6.mutually-exclusive#"
const R_INDEPENDENT := SK + "0"
const R_SUM_BELOW_ONE := SK + "1"
const T := "t4-ext-mutually-exclusive#"
const R_TIMES := T + "2"
const R_MINUS_PRODUCT := T + "3"
const R_COMPLEMENTARY := T + "4"
const R_UNION := T + "5"
const UNKNOWNS := ["decide-from-probabilities", "decide-from-venn", "decide-in-context", "union-exclusive", "missing-exclusive"]
const EVENT_WORDS := {"odd": "an odd number", "even": "an even number", "multiple3": "a multiple of 3", "multiple4": "a multiple of 4",
	"prime": "a prime number", "square": "a square number", "factor12": "a factor of 12"}
## Stories in which exactly one thing happens, so the two events can't both happen.
const STORIES := [
	{"lines": "A courier takes exactly one route each day. The probability that it is the north road is %s, and that it is the river path is %s.",
		"asked": "Find the probability that the courier takes the north road or the river path."},
	{"lines": "Each morning a guard is given exactly one post. The probability that it is the gate is %s, and that it is the tower is %s.",
		"asked": "Find the probability that the guard is posted at the gate or the tower."},
	{"lines": "A spinner lands on exactly one colour. The probability that it lands on red is %s, and on green is %s.",
		"asked": "Find the probability that the spinner lands on red or green."},
	{"lines": "A trader opens exactly one stall each day. The probability that it is the market stall is %s, and the dock stall is %s.",
		"asked": "Find the probability that the trader opens the market stall or the dock stall."},
]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = ["true-false-reason"]
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = MutuallyExclusiveSituation.export(s)
	if unknown in ["union-exclusive", "missing-exclusive"]:
		# The answer nudged by 0.05 either way: no slip gives these. The engine's own nudges
		# add 1, which is no probability.
		var v: Q = out.answer.values.v
		for k in [1, -1, 2, -2, 3, -3]:
			var x: Q = v.add(Q.new(k, 20))
			if x.sign() > 0 and x.lt(Q.new(1)):
				out.fillers.append({"v": x})
	return out


static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func p20(k: int) -> Q:
	return Q.new(k, 20)


## Every wrong statement here is a tagged slip; any left after the first three are dropped.
static func pick(right: String, tagged: Array, rng: Seeded) -> Dictionary:
	var out := InverseRuleViews.choose(right, rng.shuffled(tagged), [])
	out.fillers = out.get("fillers", []) + out.get("generic", [])
	out.erase("generic")
	return out


static func tag(text: String, ref: String) -> Dictionary:
	return InverseRuleViews.tag(text, ref)


## The slips of a decision, from P(A), P(B), P(A ∩ B) and P(A ∪ B) written as the question
## writes them (w): independence, the sum below 1, complementary, and the union.
static func slips(me: bool, pa: Q, pb: Q, pi: Q, w: Callable) -> Array:
	var out: Array = []
	if not me and pi.eq(pa.mul(pb)):
		out.append(tag("Yes: P(A ∩ B) = P(A) × P(B)", R_INDEPENDENT))
	else:
		out.append(tag("No: P(A ∩ B) ≠ P(A) × P(B)", R_INDEPENDENT))
	var sum := pa.add(pb)
	if not me and sum.lt(Q.new(1)):
		out.append(tag("Yes: P(A) + P(B) = %s < 1" % w.call(sum), R_SUM_BELOW_ONE))
	if not sum.eq(Q.new(1)):
		out.append(tag("No: P(A) + P(B) = %s, not 1" % w.call(sum), R_COMPLEMENTARY))
	out.append(tag("No: P(A ∪ B) = %s, not 0" % w.call(sum.sub(pi)), R_UNION))
	return out


# ── Deciding ─────────────────────────────────────────────────

func u_decide_from_probabilities(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var pa := p20(s.ka)
	var pb := p20(s.kb)
	var pi := p20(s.ki)
	var pu := pa.add(pb).sub(pi)
	var union: bool = s.form == "union"
	var lines := ["P(A) = " + D(pa), "P(B) = " + D(pb), ("P(A ∪ B) = " + D(pu)) if union else ("P(A ∩ B) = " + D(pi))]
	var via := "P(A ∩ B) = P(A) + P(B) − P(A ∪ B) = " if union else "P(A ∩ B) = "
	var right: String = ("Yes: %s0" % via) if s.me else ("No: %s%s, not 0" % [via, D(pi)])
	var out := {"asked": "Are A and B mutually exclusive?", "lines": lines}
	out.merge(pick(right, slips(s.me, pa, pb, pi, D), rng))
	var steps: Array = ["A and B are mutually exclusive exactly when P(A ∩ B) = 0."]
	if union:
		steps.append("P(A ∪ B) = P(A) + P(B) − P(A ∩ B), so P(A ∩ B) = %s + %s − %s = %s." % [D(pa), D(pb), D(pu), D(pi)])
	else:
		steps.append("P(A ∩ B) is given: %s." % D(pi))
	steps.append(right + ".")
	out.methods = {"intersection-zero": method(steps, {"v": right})}
	return out


static func frac(n: int, u: int) -> String:
	return Fmt.num(Q.new(n, u))


func u_decide_from_venn(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var u: int = s.u
	var pa := Q.new(s.a + s.i, u)
	var pb := Q.new(s.b + s.i, u)
	var pi := Q.new(s.i, u)
	var right: String = "Yes: no outcome is in both A and B, so P(A ∩ B) = 0" if s.me \
		else "No: %d outcomes are in both A and B, so P(A ∩ B) = %s, not 0" % [s.i, frac(s.i, u)]
	var out := {"asked": "Are A and B mutually exclusive?",
		"lines": ["The Venn diagram shows how many of %d equally likely outcomes are in each region for events A and B." % u],
		"graph": VennViews.venn_graph(str(s.a), str(s.i), str(s.b), str(s.o))}
	out.merge(pick(right, slips(s.me, pa, pb, pi, func(v): return Fmt.num(v)), rng))
	var overlap: String = "The circles overlap in a region that holds 0 outcomes, so no outcome is in both." if s.me \
		else "The region where the circles overlap holds %d outcomes, so both can happen at once." % s.i
	out.methods = {
		"separate-circles": method(["Look at the overlap of circles A and B.", overlap, right + "."], {"v": right}),
		"intersection-zero": method(["n(A ∩ B) = %d, out of %d outcomes." % [s.i, u], "P(A ∩ B) = %d/%d%s." % [s.i, u, "" if s.i == 0 else " = " + frac(s.i, u)], right + "."], {"v": right}),
	}
	return out


static func number_word(x: int) -> String:
	return ("an %d" if x in [8, 11, 18] else "a %d") % x


static func event_text(ev: String, k: int) -> String:
	match ev:
		"number":
			return number_word(k)
		"greater":
			return "a number greater than %d" % k
		"less":
			return "a number less than %d" % k
	return EVENT_WORDS[ev]


## "3 and 9", "2, 4 and 6".
static func and_list(xs: Array) -> String:
	var t: Array = xs.map(func(x): return str(x))
	return ", ".join(t.slice(0, -1)) + " and " + t[-1]


static func listed(xs: Array) -> String:
	return ", ".join(xs.map(func(x): return str(x)))


func u_decide_in_context(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var dev: Dictionary = MutuallyExclusiveSituation.DEVICES[s.dev]
	var n: int = dev.n
	var a := event_text(MutuallyExclusiveSituation.EVENTS[s.ea], s.k1)
	var b := event_text(MutuallyExclusiveSituation.EVENTS[s.eb], s.k2)
	var both: Array = s.A.filter(func(x): return x in s.B)
	var right: String = ("Yes: no single %s is both %s and %s" % [dev.one, a, b]) if s.me \
		else ("No: %s is both %s and %s" % [number_word(both[0]), a, b])
	var pa := Q.new(s.A.size(), n)
	var pb := Q.new(s.B.size(), n)
	var pi := Q.new(both.size(), n)
	var out := {"asked": "Are A and B mutually exclusive?",
		"lines": [dev.what, "A is the event \"%s\" and B is the event \"%s\"." % [a, b]]}
	out.merge(pick(right, slips(s.me, pa, pb, pi, func(v): return Fmt.num(v)), rng))
	var lists := "A: %s. B: %s." % [listed(s.A), listed(s.B)]
	out.methods = {
		"can-both-happen": method(["List the outcomes. " + lists,
			"No outcome is on both lists." if s.me else "%s on both lists." % (("%d is" % both[0]) if both.size() == 1 else (and_list(both) + " are")), right + "."], {"v": right}),
		"intersection-zero": method([lists,
			("A ∩ B has no outcomes, so P(A ∩ B) = 0.") if s.me else ("A ∩ B = {%s}, so P(A ∩ B) = %d/%d%s." % [listed(both), both.size(), n, "" if pi.d == n else " = " + Fmt.num(pi)]),
			right + "."], {"v": right}),
	}
	return out


# ── Values ───────────────────────────────────────────────────

static func val(label: String, v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	ans.show = "dec"
	ans.exact = true
	return ans


static func wr(v: Q, ref: String) -> Array:
	return [wrong({"v": v}, ref)] if v.sign() > 0 and v.lt(Q.new(1)) else []


func u_union_exclusive(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pa := p20(s.ka)
	var pb := p20(s.kb)
	var v := pa.add(pb)
	var ans := val("P(A ∪ B) = " if rep == "equation" else "probability = ", v)
	var out := {"answer": ans}
	var none: String
	if rep == "equation":
		out.lines = ["A and B are mutually exclusive.", "P(A) = " + D(pa), "P(B) = " + D(pb)]
		out.asked = "Find P(A ∪ B)."
		none = "A and B are mutually exclusive, so P(A ∩ B) = 0."
	else:
		var st: Dictionary = STORIES[s.ctx]
		out.lines = [st.lines % [D(pa), D(pb)]]
		out.asked = st.asked
		none = "Exactly one of them happens, so the two can't both happen."
	out.wrongs = wr(pa.mul(pb), R_TIMES) + wr(v.sub(pa.mul(pb)), R_MINUS_PRODUCT)
	out.fillers = []
	var add: String = "P(A ∪ B) = P(A) + P(B) − P(A ∩ B) = %s + %s − 0." % [D(pa), D(pb)] if rep == "equation" \
		else "The probability of one or the other is the sum: %s + %s." % [D(pa), D(pb)]
	out.methods = {"intersection-zero": method([none, add, "So %s." % Answer.text(ans)], ans.values)}
	return out


func u_missing_exclusive(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pa := p20(s.ka)
	var pu := p20(s.ku)
	var v := pu.sub(pa)
	var ans := val("P(B) = ", v)
	var out := {"answer": ans, "lines": ["A and B are mutually exclusive.", "P(A) = " + D(pa), "P(A ∪ B) = " + D(pu)], "asked": "Find P(B)."}
	out.wrongs = wr(v.div(Q.new(1).sub(pa)), R_MINUS_PRODUCT)
	out.fillers = []
	out.methods = {"intersection-zero": method(["P(A ∩ B) = 0, so P(A ∪ B) = P(A) + P(B).", "%s = %s + P(B)." % [D(pu), D(pa)], "So %s." % Answer.text(ans)], ans.values)}
	return out
