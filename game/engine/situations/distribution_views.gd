class_name DistributionViews
extends RefCounted
## The views on the `distribution` situation: one builder per unknown of
## t4-discrete-distribution, t4-expected-value and t4-expected-occurrences
## (curriculum/question-types.json). A builder returns the same fields as the quadratic
## ones (see quadratic_views.gd); its table is
##   {"rows": [["x", ["1", "2", "3"]], ["P(X = x)", ["k", "2k", "3k"]]]}
## with each cell written as it is shown.
##
## Representations: "table" (a distribution table), "equation" (a formula such as
## P(X = x) = k(x + 1), for x = 0, 1, 2, 3) and "words" (X in a context, each
## probability in a sentence). Answers are exact; a probability given as a decimal is
## answered as a decimal, one in fractions as a fraction. Typed answers are marked right
## exactly or to 3 s.f., as the IB marks them.
##
## Paper 1 or 2 (FAL-419): every cell makes both. Paper 2 shows awkward decimals to
## 3 d.p. (0.137) or a reciprocal formula (k/x); k, E(X), an expected number and an
## event's probability from a formula are then answered to 3 s.f. (show "sf", with the
## rounding trap), the fair stake to the nearest cent, and the rest exactly, as the
## question writes them (0.384, p = 0.137, n = 250). Its working uses the GDC.
##
## `given` holds what the student is shown, for the SymPy checker: the style, the
## values of X, each probability as written (k, 2k, 0.35, 3/10, p, ?), the formula,
## the event, E(X) when it is given, the trials, the expected number and the game.

const CONTEXTS := [
	{"x": "the score on a spinner at the bazaar", "trial": "spins", "run": "The spinner is spun %d times."},
	{"x": "the number of radios a scavenger finds on one trip", "trial": "trips", "run": "The scavenger makes %d trips."},
	{"x": "the number of water cans in a salvage crate", "trial": "crates", "run": "%d crates are opened."},
	{"x": "the number of caravans that pass the toll gate in an hour", "trial": "hours", "run": "The gate is watched for %d hours."},
	{"x": "the number of cups of coffee a trader sells in ten minutes", "trial": "ten-minute spells", "run": "The trader is watched for %d ten-minute spells."},
]

const PX := "P(X = x)"


## Every cell can be asked on either paper (FAL-419).
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1, 2] if has(unknown) else []


func has(unknown: String) -> bool:
	return unknown in ["k-from-sum", "missing-probability", "event-probability", "expected-value",
		"probabilities-from-mean", "fair-stake", "expected-count", "trials-for-count"]


func need(unknown: String, rep: String) -> Dictionary:
	var n := {"ask": unknown}
	match unknown:
		"k-from-sum":
			n.probs = "formula" if rep == "equation" else "multiples"
		"missing-probability", "probabilities-from-mean":
			n.probs = "decimal"
		"fair-stake":
			n.probs = "decimal"
			n.game = true
		"trials-for-count":
			n.probs = "known"
			n.k_known = true
			n.event = "count"
		_:
			n.probs = "formula" if rep == "equation" else "known"
			n.k_known = true
	if unknown == "event-probability":
		n.event = "range"
	if unknown == "expected-count":
		n.event = "count"
	return n


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out: Dictionary = call("u_" + unknown.replace("-", "_"), rep, s, rng)
	for key in ["lines", "graph", "table", "diagram", "wrongs", "generic"]:
		if not out.has(key):
			out[key] = [] if key in ["lines", "wrongs", "generic"] else null
	if s.get("paper", 1) == 2:
		out.trap = trap(out)
	return out


## Q7's rounding trap on Paper 2: the answer to 2 s.f., where it needs rounding. Not for
## a stake (money is to the cent), and not where it would push out a misconception that
## reads the same (87 for an expected 86.8 is the rounding-to-whole slip).
static func trap(out: Dictionary) -> Dictionary:
	var ans: Dictionary = out.answer
	if ans.get("show", "") == "money":
		return {}
	var t := Answer.rounding_trap(ans)
	if t.is_empty():
		return t
	for w in out.wrongs:
		if Answer.canon(ans, w.values) == Answer.canon(ans, t):
			return {}
	return t


# ── Writing numbers ──────────────────────────────────────────

static func dec_style(s: Dictionary) -> bool:
	return s.style in ["decimal", "calc"]


static func p2(s: Dictionary) -> bool:
	return s.get("paper", 1) == 2


## A Paper 2 rule (k/x): its probabilities are k over a whole number.
static func recip(s: Dictionary) -> bool:
	return s.rule != "" and DistributionSituation.RULES[s.rule].get("p2", false)


## Working figures on the GDC: six significant figures, or the decimal where it ends
## within them (0.1712, not 0.171200).
static func W(v: Variant) -> String:
	var r := Answer.parse_number(Fmt.sf(v, 6).replace("−", "-"))
	return Fmt.dec(v) if r.ok and r.q.eq(Q.of(v)) else Fmt.sf(v, 6)


## " = 0.255474" after a fraction a Paper 2 formula question works out on the GDC.
static func gdc_tail(s: Dictionary, v: Q) -> String:
	return " = " + W(v) if recip(s) and Answer.needs_rounding(v) else ""


## The nudge between near-miss options: a step of the decimals (0.05 or 0.1), 0.01
## among Paper 2's 3 d.p. ones, or 1/total for multiples and formulas.
static func step(s: Dictionary) -> Q:
	return Q.new(1, 100) if s.style == "calc" else Q.new(1, s.total)


## A probability or other number as this situation writes it.
static func pt(s: Dictionary, v: Variant) -> String:
	return Fmt.dec(v) if dec_style(s) else Q.of(v).text()


## P(X = x_i) as worked with: 0.35, 3/10, or 3/14 unreduced from a formula.
static func p_text(s: Dictionary, i: int) -> String:
	if s.style == "formula":
		return "%d/%d" % [s.mult[i], s.total]
	return pt(s, s.ps[i])


## P(X = x_i) as shown in the question: with k, p, q or ? where it is unknown.
static func shown_p(s: Dictionary, i: int) -> String:
	if s.missing == i:
		return "?"
	if s.pq.size() == 2 and i == s.pq[0]:
		return "p"
	if s.pq.size() == 2 and i == s.pq[1]:
		return "q"
	if s.style == "multiples" and not s.k_known:
		return "k" if s.mult[i] == 1 else "%dk" % s.mult[i]
	if not s.get("kc", []).is_empty() and s.kc[i] > 0:
		return "k" if s.kc[i] == 1 else "%dk" % s.kc[i]
	return pt(s, s.ps[i])


## A sum of probabilities written out, ending at its total: "0.2 + 0.35 = 0.55",
## "3/14 + 4/14 = 7/14 = 1/2".
static func sum_text(s: Dictionary, idx: Array) -> String:
	var parts: Array = idx.map(func(i): return p_text(s, i))
	var total := Q.new(0)
	var c := 0
	for i in idx:
		total = total.add(s.ps[i])
		c += s.mult[i]
	var tail := ""
	if s.style == "formula":
		tail = "%d/%d" % [c, s.total]
		if not total.eq(Q.new(c, s.total)) or Q.new(c, s.total).text() != tail:
			tail += " = " + total.text()
	else:
		tail = pt(s, total)
	if idx.size() == 1:
		return tail
	return " + ".join(parts) + " = " + tail


static func sum_of(s: Dictionary, idx: Array) -> Q:
	var total := Q.new(0)
	for i in idx:
		total = total.add(s.ps[i])
	return total


static func values_list(xs: Array) -> String:
	return and_list(xs.map(func(x): return str(x)))


static func and_list(items: Array) -> String:
	if items.size() == 1:
		return items[0]
	return ", ".join(items.slice(0, items.size() - 1)) + " and " + items[-1]


static func px(x: Variant) -> String:
	return "P(X = %s)" % str(x)


## The event as written inside P( ): "X > 2", "1 < X ≤ 3".
static func event_text(e: Dictionary) -> String:
	match e.op:
		"=":
			return "X = %d" % e.a
		">", "≥":
			return "X %s %d" % [e.op, e.a]
		"<", "≤":
			return "X %s %d" % [e.op, e.b]
		"<≤":
			return "%d < X ≤ %d" % [e.a, e.b]
		"≤<":
			return "%d ≤ X < %d" % [e.a, e.b]
		"≤≤":
			return "%d ≤ X ≤ %d" % [e.a, e.b]
	return "?"


static func inside_idx(s: Dictionary) -> Array:
	var out: Array = []
	for i in s.xs.size():
		if s.inside[i]:
			out.append(i)
	return out


static func outside_idx(s: Dictionary) -> Array:
	var out: Array = []
	for i in s.xs.size():
		if not s.inside[i]:
			out.append(i)
	return out


static func xs_of(s: Dictionary, idx: Array) -> String:
	return and_list(idx.map(func(i): return "x = %d" % s.xs[i]))


## The formula's right-hand side: "k(x + 1)", or "(x + 1)/14" with k put in.
## A Paper 2 formula keeps its k: "k/x", with k given after it when it is known.
static func formula_text(s: Dictionary) -> String:
	var f: String = DistributionSituation.RULES[s.rule].text
	return "%s/%d" % [f, s.total] if s.k_known and not recip(s) else "k" + f


# ── What the student sees ────────────────────────────────────

## Sets lines, table and given on out. intro is the opening of the words sentence.
static func show(rep: String, s: Dictionary, out: Dictionary, extra: Array = []) -> void:
	var n: int = s.xs.size()
	var entries: Array = []
	for i in n:
		entries.append(shown_p(s, i))
	out.given = {"style": s.style, "k_known": s.k_known, "xs": s.xs.duplicate(), "entries": entries,
		"rule": s.rule, "total": s.total if s.k_known and s.style == "formula" else null,
		"event": s.event if not s.event.is_empty() else null, "mean": null, "n": null, "count": null,
		"game": null}
	var ctx: Dictionary = CONTEXTS[s.context]
	if rep == "equation":
		var where := ", where k = %s" % s.k.text() if recip(s) and s.k_known else ""
		out.lines = ["A discrete random variable X has", "P(X = x) = %s, for x = %s%s." % [formula_text(s),
			", ".join(s.xs.map(func(x): return str(x))), where]]
		out.given.entries = null
		if where != "":
			out.given.k = s.k.key()
	elif rep == "table":
		out.lines = ["The table shows the probability distribution of a discrete random variable X."]
		out.table = {"rows": [["x", s.xs.map(func(x): return str(x))], [PX, entries]]}
	else:
		var stated: Array = []
		for i in n:
			if entries[i] != "?":
				stated.append("%s = %s" % [px(s.xs[i]), entries[i]])
		out.lines = ["Let X be %s. X takes the values %s, with %s." % [ctx.x, values_list(s.xs), and_list(stated)]]
	out.lines.append_array(extra)


## The working line that turns a formula into its probabilities.
static func tabulate(s: Dictionary) -> String:
	var items: Array = []
	for i in s.xs.size():
		items.append("%s = %s" % [px(s.xs[i]), p_text(s, i)])
	return "Put each value of x into %s: %s." % [formula_text(s), and_list(items)]


static func number_answer(label: String, v: Q, dec: bool) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	if dec:
		ans.show = "dec"
	return ans


## A wrong option: kept when it is a real number in range (a probability strictly
## between 0 and 1), written the way the answer is (no 1/3 among decimals), not on a
## 3 s.f. rounding edge, and different to 3 s.f. from the answer and from every option
## already kept.
static func wrong(out: Dictionary, v: Variant, ref: String = "", prob: bool = false) -> void:
	if v == null:
		return
	var q := Q.of(v)
	if out.answer.get("show", "") in ["dec", "money"] and Fmt.dec(q).contains("/"):
		return
	if not _keep(out, {"v": q}, prob):
		return
	var item := {"values": {"v": q}, "ref": ref}
	if ref == "":
		out.generic.append(item.values)
	else:
		out.wrongs.append(item)


static func _keep(out: Dictionary, values: Dictionary, prob: bool) -> bool:
	var keys: Array = []
	for id in values:
		var x: float = values[id].to_float()
		if x <= 0.0 or (prob and x >= 1.0) or not Answer.rounds_clearly(x, DistributionSituation.EDGE_SAFE):
			return false
		keys.append(Fmt.sf(x))
	var key := ",".join(keys)
	var taken: Array = [_sf_key(out.answer.values)]
	for w in out.wrongs:
		taken.append(_sf_key(w.values))
	for g in out.generic:
		taken.append(_sf_key(g))
	return not key in taken


static func _sf_key(values: Dictionary) -> String:
	var keys: Array = []
	for id in values:
		keys.append(Fmt.sf(Q.of(values[id]).to_float()))
	return ",".join(keys)


static func res(v: Q) -> Dictionary:
	return {"v": v}


# ── t4-discrete-distribution ─────────────────────────────────

func u_k_from_sum(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	if p2(s):
		return k_paper2(rep, s)
	var ans := number_answer("k = ", s.k, false)
	var out := {"answer": ans, "wrongs": [], "generic": []}
	show(rep, s, out)
	out.asked = "Find the value of k."
	var terms: Array = s.mult.map(func(c): return "k" if c == 1 else "%dk" % c)
	var steps: Array = []
	if rep == "equation":
		var items: Array = []
		for i in s.xs.size():
			items.append("%s = %s" % [px(s.xs[i]), terms[i]])
		steps.append("Put each value of x into %s: %s." % [formula_text(s), and_list(items)])
	steps.append_array([
		"The probabilities add to 1: %s = 1" % " + ".join(terms),
		"%dk = 1" % s.total,
		"k = 1/%d" % s.total,
		"So %s." % Answer.text(ans)])
	out.methods = {"sum-to-one": {"steps": steps, "result": res(s.k)}}
	var sx := 0
	var sxc := 0
	for i in s.xs.size():
		sx += s.xs[i]
		sxc += s.xs[i] * s.mult[i]
	if sxc > 0:
		wrong(out, Q.new(1, sxc), "SL4.7.find-k#0", true)
	if sx > 0:
		wrong(out, Q.new(1, sx), "SL4.7.find-k#0", true)
	wrong(out, Q.new(s.total))
	wrong(out, Q.new(1, s.xs.size()), "", true)
	wrong(out, Q.new(2, s.total), "", true)
	wrong(out, Q.new(1, s.total + 1), "", true)
	return out


## Paper 2's k, to 3 s.f.: beside awkward decimals (0.137 + k + 2k + 0.264 = 1), or
## from a reciprocal formula (k(1 + 1/2 + 1/3) = 1), added up on the GDC.
func k_paper2(rep: String, s: Dictionary) -> Dictionary:
	var ans := number_answer("k = ", s.k, false)
	ans.show = "sf"
	var out := {"answer": ans, "wrongs": [], "generic": []}
	show(rep, s, out)
	out.asked = "Find the value of k, correct to 3 significant figures."
	var n: int = s.xs.size()
	var steps: Array = []
	var rest := Q.new(1)       # what the multiples of k add to
	var coef: Array = []       # P(X = x) ÷ k
	var csum := Q.new(0)
	if recip(s):
		var items: Array = []
		var parts: Array = []
		for x in s.xs:
			var d := DistributionSituation.rule_value(s.rule, x)
			items.append("%s = %s" % [px(x), "k" if d == 1 else "k/%d" % d])
			parts.append("1" if d == 1 else "1/%d" % d)
			coef.append(Q.new(1, d))
			csum = csum.add(coef[-1])
		steps.append_array([
			"Put each value of x into %s: %s." % [formula_text(s), and_list(items)],
			"The probabilities add to 1: k(%s) = 1" % " + ".join(parts),
			"With a GDC: %s = %s, so k = 1 ÷ %s = %s" % [" + ".join(parts), W(csum), W(csum), W(s.k)]])
	else:
		var terms: Array = []
		var have := Q.new(0)
		for i in n:
			terms.append(shown_p(s, i))
			coef.append(Q.new(s.kc[i]))
			csum = csum.add(s.kc[i])
			if s.kc[i] == 0:
				have = have.add(s.ps[i])
		rest = Q.new(1).sub(have)
		var ck := "k" if csum.eq(1) else "%sk" % csum.text()
		steps.append_array([
			"The probabilities add to 1: %s = 1" % " + ".join(terms),
			"%s + %s = 1, so %s = 1 − %s = %s" % [Fmt.dec(have), ck, ck, Fmt.dec(have), Fmt.dec(rest)],
			"k = %s ÷ %s = %s on the GDC" % [Fmt.dec(rest), csum.text(), W(s.k)]])
	steps.append("So %s." % Answer.text(ans))
	out.methods = {"sum-to-one": {"steps": steps, "result": res(s.k)}}
	# The products x × (P ÷ k), or the x-values, set to add up instead.
	var sxc := Q.new(0)
	var sx := 0
	for i in n:
		sxc = sxc.add(coef[i].mul(s.xs[i]))
		sx += s.xs[i]
	if sxc.sign() > 0:
		wrong(out, rest.div(sxc), "SL4.7.find-k#0")
	if rest.eq(1) and sx > 0:
		wrong(out, Q.new(1, sx), "SL4.7.find-k#0")
	wrong(out, rest)
	wrong(out, rest.div(csum.add(1)))
	wrong(out, s.k.mul(2))
	wrong(out, Q.new(1, n))
	wrong(out, csum)
	return out


func u_missing_probability(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: int = s.missing
	var p: Q = s.ps[m]
	var ans := number_answer(px(s.xs[m]) + " = ", p, true)
	var out := {"answer": ans, "wrongs": [], "generic": []}
	show(rep, s, out)
	out.asked = "Find %s." % px(s.xs[m])
	var known: Array = range(s.xs.size()).filter(func(i): return i != m)
	var have := sum_of(s, known)
	var terms: Array = []
	for i in s.xs.size():
		terms.append(px(s.xs[m]) if i == m else p_text(s, i))
	var sum1 := [
		"The probabilities add to 1: %s = 1" % " + ".join(terms),
		"%s + %s = 1" % [pt(s, have), px(s.xs[m])],
		"%s = 1 − %s = %s" % [px(s.xs[m]), pt(s, have), pt(s, p)],
		"So %s." % Answer.text(ans)]
	var last := [
		"Add the probabilities that are given%s: %s" % [" on the GDC" if p2(s) else "", sum_text(s, known)],
		"The last one is what is left of 1: 1 − %s = %s" % [pt(s, have), pt(s, p)],
		"Check: %s is from 0 to 1, so the table is a valid distribution." % pt(s, p),
		"So %s." % Answer.text(ans)]
	out.methods = {"sum-to-one": {"steps": sum1, "result": res(p)}, "last-by-subtraction": {"steps": last, "result": res(p)}}
	wrong(out, Q.new(1, s.xs.size()), "SL4.7.build-distribution#1", true)
	wrong(out, have, "", true)
	for j in known:
		wrong(out, p.add(s.ps[j]), "", true)
	wrong(out, Q.new(1).sub(p), "", true)
	var nudge := step(s)
	for k in [1, -1, 2, -2]:
		wrong(out, p.add(nudge.mul(k)), "", true)
	return out


func u_event_probability(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var e: Dictionary = s.event
	var label := "P(%s) = " % event_text(e)
	var ans := number_answer(label, s.pe, dec_style(s))
	if recip(s):
		ans.show = "sf"
	var out := {"answer": ans, "wrongs": [], "generic": []}
	show(rep, s, out)
	out.asked = "Find P(%s)." % event_text(e)
	if ans.get("show", "") == "sf":
		out.asked = "Find P(%s), correct to 3 significant figures." % event_text(e)
	var inn := inside_idx(s)
	var outs := outside_idx(s)
	var strict := DistributionSituation.with_strict_ends(e)
	var note := ""
	var note_out := ""
	if not strict.is_empty():
		var ends: Array = []
		if e.op in [">", "<≤"]:
			ends.append(e.a)
		if e.op in ["<", "≤<"]:
			ends.append(e.b)
		var named := and_list(ends.map(func(x): return "x = %d" % x))
		note = " (not %s: the inequality is strict)" % named
		note_out = " (%s too, as the inequality is strict)" % named
	var first: Array = [tabulate(s)] if rep == "equation" else []
	var add := first.duplicate()
	add.append_array([
		"%s takes in %s%s." % [event_text(e), xs_of(s, inn), note],
		"P(%s) = %s%s" % [event_text(e), sum_text(s, inn), gdc_tail(s, s.pe)],
		"So %s." % Answer.text(ans)])
	var rest := sum_of(s, outs)
	var comp := first.duplicate()
	comp.append_array([
		"%s leaves out %s%s." % [event_text(e), xs_of(s, outs), note_out],
		"Those add to %s." % sum_text(s, outs),
		"P(%s) = 1 − %s = %s%s" % [event_text(e), pt(s, rest), pt(s, s.pe), gdc_tail(s, s.pe)],
		"So %s." % Answer.text(ans)])
	out.methods = {"add-entries": {"steps": add, "result": res(s.pe)}, "complement": {"steps": comp, "result": res(s.pe)}}
	if not strict.is_empty():
		wrong(out, DistributionSituation.prob_of(s, strict), "SL4.7.table-probabilities#0", true)
	wrong(out, rest, "", true)
	# A non-strict end left out, the other slip at an end.
	var drop := e.duplicate()
	match e.op:
		"≥":
			drop.op = ">"
		"≤":
			drop.op = "<"
	if drop.op != e.op:
		wrong(out, DistributionSituation.prob_of(s, drop), "", true)
	for i in inn:
		wrong(out, s.pe.sub(s.ps[i]), "", true)
	for i in outs:
		wrong(out, s.pe.add(s.ps[i]), "", true)
	for i in s.xs.size():
		wrong(out, s.ps[i], "", true)
		for j in range(i + 1, s.xs.size()):
			wrong(out, s.ps[i].add(s.ps[j]), "", true)
	var nudge := step(s)
	for k in [1, -1, 2, -2]:
		wrong(out, s.pe.add(nudge.mul(k)), "", true)
	# Last resorts, for a symmetric table whose slips all agree (P(X ≤ 2) = 1/2).
	wrong(out, s.pe.div(2), "", true)
	wrong(out, Q.new(1).sub(s.pe.div(2)), "", true)
	return out


# ── t4-expected-value ────────────────────────────────────────

## Σ x P(X = x) written out: "1 × 0.2 + 2 × 0.35" and the products "0.2 + 0.7".
static func xp_terms(s: Dictionary) -> Array:
	var terms: Array = []
	var products: Array = []
	for i in s.xs.size():
		terms.append("%d × %s" % [s.xs[i], p_text(s, i)])
		if s.xs[i] == 0:
			products.append("0")
		elif s.style == "formula":
			products.append("%d/%d" % [s.xs[i] * s.mult[i], s.total])
		else:
			products.append(pt(s, s.ps[i].mul(s.xs[i])))
	return [terms, products]


static func mean_tail(s: Dictionary) -> String:
	if s.style == "formula":
		var top := 0
		for i in s.xs.size():
			top += s.xs[i] * s.mult[i]
		var raw := "%d/%d" % [top, s.total]
		return (raw if Q.new(top, s.total).text() == raw else raw + " = " + s.mean.text()) + gdc_tail(s, s.mean)
	return pt(s, s.mean)


func u_expected_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := number_answer("E(X) = ", s.mean, dec_style(s))
	if p2(s):
		ans.show = "sf"
	var out := {"answer": ans, "wrongs": [], "generic": []}
	show(rep, s, out)
	out.asked = "Find E(X)." if not p2(s) else "Find E(X), correct to 3 significant figures."
	var tp := xp_terms(s)
	var first: Array = [tabulate(s)] if rep == "equation" else []
	var sum := first.duplicate()
	sum.append_array([
		"E(X) = Σ x P(X = x) = %s" % " + ".join(tp[0]),
		"= %s = %s" % [" + ".join(tp[1]), mean_tail(s)],
		"So %s." % Answer.text(ans)])
	var shown_mean := Fmt.dec(s.mean)
	if shown_mean.contains("/"):
		shown_mean = Fmt.sf(s.mean, 6) + "…, which is " + s.mean.text()
	var probs: Array = []
	for i in s.xs.size():
		probs.append(p_text(s, i))
	var gdc := first.duplicate()
	gdc.append_array([
		"Put the values of x in list L1: %s." % ", ".join(s.xs.map(func(x): return str(x))),
		"Put the probabilities in list L2: %s." % ", ".join(probs),
		"Run 1-Var Stats on L1 with L2 as the frequency list.",
		"The probabilities add to 1, so the mean x̄ is E(X): x̄ = %s." % shown_mean,
		"So %s." % Answer.text(ans)])
	out.methods = {"sum-xp": {"steps": sum, "result": res(s.mean)}, "gdc-weighted": {"steps": gdc, "result": res(s.mean)}}
	var n: int = s.xs.size()
	var sx := 0
	for x in s.xs:
		sx += x
	wrong(out, Q.new(sx, n), "SL4.7.expected-value#0")
	var near := -1
	var gap := 1e9
	var tie := false
	for x in s.xs:
		var d := absf(float(x) - s.mean.to_float())
		if d < gap - 1e-9:
			gap = d
			near = x
			tie = false
		elif absf(d - gap) < 1e-9:
			tie = true
	if gap > 1e-9 and not tie:
		wrong(out, Q.new(near), "SL4.7.expected-value#1")
	wrong(out, s.mean.div(n), "SL4.7.expected-value#2")
	wrong(out, s.mean.sub(s.ps[n - 1].mul(s.xs[n - 1])))
	wrong(out, Q.new(sx))
	wrong(out, s.mean.add(s.ps[0]))
	wrong(out, s.mean.add(1))
	return out


func u_probabilities_from_mean(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var i: int = s.pq[0]
	var j: int = s.pq[1]
	var p: Q = s.ps[i]
	var q: Q = s.ps[j]
	var xp: int = s.xs[i]
	var xq: int = s.xs[j]
	var ans := Answer.make("pq", {"p": p, "q": q})
	ans.show = "dec"
	var out := {"answer": ans, "wrongs": [], "generic": []}
	var known: Array = range(s.xs.size()).filter(func(k): return k != i and k != j)
	var have := sum_of(s, known)
	var a := Q.new(1).sub(have)                     # p + q = a
	var have_x := Q.new(0)
	for k in known:
		have_x = have_x.add(s.ps[k].mul(s.xs[k]))
	var b: Q = s.mean.sub(have_x)                   # xp p + xq q = b
	show(rep, s, out, ["E(X) = %s." % Fmt.dec(s.mean)])
	out.given.mean = s.mean.key()
	out.asked = "Find p and q."
	var terms: Array = []
	var xterms: Array = []
	for k in s.xs.size():
		terms.append(shown_p(s, k))
		xterms.append(lin(s.xs[k], shown_p(s, k), 0, "") if k in [i, j] and s.xs[k] != 0 else "%d × %s" % [s.xs[k], shown_p(s, k)])
	var lhs := lin(xp, "p", xq, "q")
	var eq1 := "p + q = %s" % Fmt.dec(a)
	var eq2 := "%s = %s" % [lhs, Fmt.dec(b)]
	var solve: Array = []
	var d := xq - xp
	var r := b.sub(a.mul(xp))
	if xp == 0:
		solve.append("x = 0 adds nothing, so the second equation is %s: q = %s ÷ %d = %s" % [eq2, Fmt.dec(b), xq, Fmt.dec(q)])
	else:
		solve.append("Take %sthe first equation from the second: %s = %s − %s, so q = %s" % [
			"" if xp == 1 else "%d × " % xp, lin(0, "p", d, "q"), Fmt.dec(b), Fmt.dec(a.mul(xp)), Fmt.dec(r.div(d))])
	var two := [
		"The probabilities add to 1: %s = 1, so %s." % [" + ".join(terms), eq1],
		"E(X) = %s: %s = %s, so %s." % [Fmt.dec(s.mean), " + ".join(xterms), Fmt.dec(s.mean), eq2],
	]
	two.append_array(solve)
	two.append_array([
		"p = %s − q = %s − %s = %s" % [Fmt.dec(a), Fmt.dec(a), Fmt.dec(q), Fmt.dec(p)],
		"So %s." % Answer.text(ans)])
	var gdc := [
		"From Σ P(X = x) = 1: %s." % eq1,
		"From Σ x P(X = x) = E(X): %s." % eq2,
		"Enter the two equations in the GDC's simultaneous equation solver, with 2 unknowns.",
		"It gives p = %s and q = %s." % [Fmt.dec(p), Fmt.dec(q)],
		"So %s." % Answer.text(ans)]
	out.methods = {"two-equations": {"steps": two, "result": {"p": p, "q": q}},
		"gdc-simultaneous": {"steps": gdc, "result": {"p": p, "q": q}}}
	# Σ x P set to 1 instead of to E(X).
	var b1 := Q.new(1).sub(have_x)
	var q1 := b1.sub(a.mul(xp)).div(d)
	pair(out, a.sub(q1), q1, "SL4.7.unknowns-from-mean#1")
	pair(out, q, p)
	var nudge := step(s)
	pair(out, p.add(nudge), q.sub(nudge))
	pair(out, p.sub(nudge), q.add(nudge))
	var q2 := b.sub(Q.new(xp)).div(d)               # p + q = 1, the given ones left out
	pair(out, Q.new(1).sub(q2), q2)
	pair(out, a.div(2), a.div(2))
	for k in [2, -2, 3, -3]:
		pair(out, p.add(nudge.mul(k)), q.sub(nudge.mul(k)))
	pair(out, q.add(nudge), p.sub(nudge))
	pair(out, q.sub(nudge), p.add(nudge))
	# Σ x P = E(X) with the given values' products left out.
	var q3: Q = s.mean.sub(a.mul(xp)).div(d)
	pair(out, a.sub(q3), q3)
	for k in [1, -1]:
		pair(out, p.add(nudge.mul(k)), q)
		pair(out, p, q.add(nudge.mul(k)))
	return out


## "p + 3q", "2p + 4q", "3q": a p + c q with whole coefficients.
static func lin(a: int, u: String, c: int, v: String) -> String:
	var parts: Array = []
	if a != 0:
		parts.append(("" if a == 1 else str(a)) + u)
	if c != 0:
		parts.append(("" if c == 1 else str(c)) + v)
	return " + ".join(parts)


static func pair(out: Dictionary, p: Q, q: Q, ref: String = "") -> void:
	if not _keep(out, {"p": p, "q": q}, true):
		return
	if ref == "":
		out.generic.append({"p": p, "q": q})
	else:
		out.wrongs.append({"values": {"p": p, "q": q}, "ref": ref})


func u_fair_stake(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("number", {"v": s.mean}, {}, "Stake = $")
	ans.show = "money"
	var out := {"answer": ans, "wrongs": [], "generic": []}
	var n: int = s.xs.size()
	var entries: Array = []
	for i in n:
		entries.append(pt(s, s.ps[i]))
	out.given = {"style": s.style, "k_known": false, "xs": s.xs.duplicate(), "entries": entries, "rule": "",
		"total": null, "event": null, "mean": null, "n": null, "count": null,
		"game": {"sectors": s.sectors if rep == "words" and not p2(s) else null}}
	var probs_line := ""
	if rep == "words" and p2(s):
		# Paper 2: a lucky dip of 1000 tokens, each prize's share an awkward decimal.
		out.given.game = {"sectors": null, "tokens": s.sectors}
		var wins: Array = []
		for i in range(n - 1, 0, -1):
			wins.append("%d tokens win $%d" % [s.mult[i], s.xs[i]])
		out.lines = ["A lucky dip at the bazaar holds %d tokens. %s, and the other %d win nothing. A player pays a stake to draw one token." % [
			s.sectors, cap(and_list(wins)), s.mult[0]]]
		probs_line = "Each token has probability 1/%d, so the prizes %s have probabilities %s." % [
			s.sectors, and_list(s.xs.map(func(x): return "$%d" % x)), and_list(entries)]
	elif rep == "words":
		var wins: Array = []
		for i in range(n - 1, 0, -1):
			wins.append("%d %s $%d" % [s.mult[i], "sector wins" if s.mult[i] == 1 else "sectors win", s.xs[i]])
		out.lines = ["A game at the bazaar uses a spinner with %d equal sectors. %s, and the other %d win nothing. A player pays a stake to spin it once." % [
			s.sectors, cap(and_list(wins)), s.mult[0]]]
		probs_line = "Each sector has probability 1/%d, so the prizes %s have probabilities %s." % [
			s.sectors, and_list(s.xs.map(func(x): return "$%d" % x)), and_list(entries)]
	else:
		out.lines = ["A player pays a stake to play a game at the bazaar. The table shows the prizes and their probabilities."]
		out.table = {"rows": [["Prize ($)", s.xs.map(func(x): return str(x))], ["Probability", entries]]}
	out.asked = "Find the stake that makes the game fair." if not p2(s) else "Find the stake that makes the game fair, to the nearest cent."
	var terms: Array = []
	for i in n:
		terms.append("%d × %s" % [s.xs[i], entries[i]])
	var mean := Fmt.dec(s.mean)
	# Paper 2: the expected prize in tenths of a cent, rounded to the cent.
	var cents := "" if not p2(s) else ", which is $%s to the nearest cent" % Fmt.money(s.mean)
	var first: Array = [probs_line] if probs_line != "" else []
	var gain := first.duplicate()
	var gains: Array = s.xs.map(func(x): return ("−c" if x == 0 else "%d − c" % x))
	gain.append_array([
		"Let the stake be $c. The player's gain G is the prize minus the stake: %s." % and_list(gains),
		"E(G) = Σ (prize − c) × P = Σ prize × P − c × Σ P = %s − c" % ("(" + " + ".join(terms) + ")"),
		"Σ prize × P = %s, so E(G) = %s − c." % [mean, mean],
		"Fair means E(G) = 0, so c = %s%s." % [mean, cents],
		"So %s." % Answer.text(ans)])
	var cost := first.duplicate()
	cost.append_array([
		"Expected prize = Σ prize × P = %s = %s%s" % [" + ".join(terms), mean, cents],
		"The game is fair when the expected prize equals the cost to play: $%s." % Fmt.money(s.mean),
		"So %s." % Answer.text(ans)])
	out.methods = {"net-gain-table": {"steps": gain, "result": res(s.mean)}, "winnings-vs-cost": {"steps": cost, "result": res(s.mean)}}
	var lose: Q = s.ps[0]
	money(out, s.mean.div(lose), "SL4.7.fair-game#0")
	var sx := 0
	for x in s.xs:
		sx += x
	money(out, Q.new(sx, n))
	money(out, s.ps[n - 1].mul(s.xs[n - 1]))
	money(out, s.mean.add(s.ps[n - 1].mul(s.xs[n - 1])))
	money(out, Q.new(s.xs[n - 1], 2))
	return out


## A wrong stake, to the cent as a student would give it.
static func money(out: Dictionary, v: Q, ref: String = "") -> void:
	wrong(out, Q.new(half_up(v.mul(100)), 100), ref)


## A positive Q rounded to a whole number, halves up, in whole-number arithmetic.
@warning_ignore("integer_division")
static func half_up(v: Q) -> int:
	return (2 * v.n + v.d) / (2 * v.d)


## A fraction in brackets, for dividing by it: "(1/3)".
static func par(text: String) -> String:
	return "(%s)" % text if text.contains("/") else text


static func cap(text: String) -> String:
	return text.left(1).to_upper() + text.substr(1)


# ── t4-expected-occurrences ──────────────────────────────────

static func show_trials(rep: String, s: Dictionary, out: Dictionary, extra: Array) -> void:
	var ctx: Dictionary = CONTEXTS[s.context if rep == "words" else 0]
	if rep == "words":
		show(rep, s, out, extra)
	else:
		show(rep, s, out, extra)
		if rep == "table":
			out.lines[0] = "The table shows the probability distribution of %s, X." % ctx.x
		else:
			out.lines[0] = "%s, X, has" % cap(ctx.x)
	out.given.event = s.event
	out.given.context = s.context if rep == "words" else 0


func u_expected_count(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ctx: Dictionary = CONTEXTS[s.context if rep == "words" else 0]
	var ans := number_answer("Expected number = ", s.count, true)
	if p2(s):
		ans.show = "sf"
	var out := {"answer": ans, "wrongs": [], "generic": []}
	show_trials(rep, s, out, [ctx.run % s.n])
	out.given.n = s.n
	out.asked = "Find the expected number of %s with %s." % [ctx.trial, event_text(s.event)]
	if p2(s):
		out.asked = out.asked.trim_suffix(".") + ", correct to 3 significant figures."
	var inn := inside_idx(s)
	var steps: Array = [tabulate(s)] if rep == "equation" else []
	var count := Fmt.dec(s.count)
	if count.contains("/"):
		count += " = " + W(s.count)
	steps.append_array([
		"P(%s) = %s" % [event_text(s.event), sum_text(s, inn)],
		"Expected number = n × P(%s) = %d × %s = %s" % [event_text(s.event), s.n, pt(s, s.pe), count]])
	if not s.count.is_int():
		steps.append("It is an average over many runs, so it need not be a whole number.")
	steps.append("So %s." % Answer.text(ans))
	out.methods = {"n-times-p": {"steps": steps, "result": res(s.count)}}
	if not s.count.is_int():
		wrong(out, Q.new(half_up(s.count)), "SL4.5.expected-occurrences#0")
	wrong(out, s.pe, "SL4.5.expected-occurrences#1")
	wrong(out, Q.new(1).sub(s.pe).mul(s.n))
	for i in inn:
		wrong(out, s.ps[i].mul(s.n))
	wrong(out, s.count.mul(2))
	wrong(out, s.count.add(s.n / 10))
	return out


func u_trials_for_count(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ctx: Dictionary = CONTEXTS[s.context if rep == "words" else 0]
	var ans := number_answer("n = ", Q.new(s.n), true)
	var out := {"answer": ans, "wrongs": [], "generic": []}
	show_trials(rep, s, out, [])
	out.given.count = s.count.key()
	out.asked = "Over n %s, %s is expected to happen %s times. Find n." % [ctx.trial, event_text(s.event), Fmt.dec(s.count)]
	var inn := inside_idx(s)
	var steps: Array = [
		"P(%s) = %s" % [event_text(s.event), sum_text(s, inn)],
		"Expected number = n × P(%s), so %s = n × %s" % [event_text(s.event), Fmt.dec(s.count), pt(s, s.pe)],
		"n = %s ÷ %s = %d" % [Fmt.dec(s.count), par(pt(s, s.pe)), s.n],
		"So %s." % Answer.text(ans)]
	out.methods = {"n-times-p": {"steps": steps, "result": res(Q.new(s.n))}}
	# Multiplied instead of divided, or by the wrong probability: on Paper 2 rounded to
	# a whole number of trials, as a student would write it.
	for v in [s.count.mul(s.pe), s.count.div(Q.new(1).sub(s.pe))]:
		wrong(out, Q.new(half_up(v)) if p2(s) else v)
	wrong(out, Q.new(s.n * 2))
	wrong(out, Q.new(s.n / 2))
	wrong(out, Q.new(s.n + 10))
	return out
