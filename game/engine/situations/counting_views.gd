class_name CountingViews
extends ExtensionViews
## The views on the `counting` situation: one builder per unknown of t1-ahl-counting
## (FAL-695), the first type built for AA HL only. Every answer is a whole number of ways,
## exact. Representations: "words" (a story) and, where the count has a symbol,
## "equation" (7!, 10P3, 12C4, nP2 = 56). `given` holds what the student is shown, for the
## SymPy checker: the sizes and the story.

const SKILL := "AHL1.10."
const R_LEADING_ZERO := SKILL + "counting-principle#0"
const R_ADD_STAGES := SKILL + "counting-principle#1"
const R_FREE_FIRST := SKILL + "counting-principle#2"
const R_COMB_FOR_PERM := SKILL + "permutations#0"
const R_REPEATS := SKILL + "permutations#1"
const R_PERM_OVER_R := SKILL + "permutations#2"
const R_ADD_GROUPS := SKILL + "combinations#0"
const R_DOUBLE_COUNT := SKILL + "combinations#1"
const R_PERM_FOR_COMB := SKILL + "combinations#2"
const R_NO_BLOCK_ORDER := SKILL + "restricted-arrangements#0"
const R_APART_MINUS_2 := SKILL + "restricted-arrangements#1"

func needs() -> Dictionary:
	var out := {}
	for u in ["code-count", "no-repeat-number", "even-numbers", "arrange-all", "award-places", "find-n-from-npr", "committee",
			"committee-mixed", "committee-at-least-one", "together", "apart"]:
		out[u] = {"ask": u}
	return out


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = CountingSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func ways(label: String, v: int) -> Dictionary:
	var ans := Answer.make("number", {"v": Q.new(v)}, {}, label)
	ans.show = "dec"
	ans.exact = true
	return ans


static func V(v: int) -> Dictionary:
	return {"v": Q.new(v)}


## Wrong values from ints that are positive, whole and not the answer, never twice.
static func vs(xs: Array, right: int) -> Array:
	var out: Array = []
	var seen := {right: true}
	for x in xs:
		if x > 0 and x < CountingSituation.COUNT_MAX * 50 and not seen.has(x):
			seen[x] = true
			out.append(V(x))
	return out


static func tagged(xs: Array, right: int, ref: String) -> Array:
	return vs(xs, right).map(func(w): return wrong(w, ref))


func _ans(label: String, s: Dictionary) -> Dictionary:
	return ways(label, s.count)


## "value = " for a count written in symbols, "number of ways = " for a story.
static func _label(rep: String) -> String:
	return "value = " if rep == "equation" else "number of ways = "


static func final(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func I(v: int) -> String:
	return str(v)


# ── Counting principle ───────────────────────────────────────

const CODE_STORIES := ["A locker code is %s followed by %s. Letters and digits can repeat.",
	"A radio password is %s then %s, with repeats allowed.",
	"A vault code has %s followed by %s. Any letter or digit can be used again."]


func u_code_count(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var ans := _ans("number of ways = ", s)
	var l := "%d letters" % a
	var d := "%d digits" % b
	var n := int(pow(26, a)) * int(pow(10, b))
	return {"asked": "How many different codes are possible?", "lines": [CODE_STORIES[s.ctx % 3] % [l, d]], "answer": ans,
		"wrongs": tagged([26 * a + 10 * b], n, R_ADD_STAGES),
		"generic": vs([int(pow(26, a)) + int(pow(10, b)), int(pow(26, a + b)), int(pow(36, a + b)), int(pow(26, a)) * 10 * b], n),
		"methods": {"slot-boxes": method(["Draw a box for each place: %d letter boxes, then %d digit boxes." % [a, b],
			"Each letter box has 26 choices and each digit box 10, and the stages happen together, so the choices multiply: 26^%d × 10^%d." % [a, b],
			"26^%d = %s and 10^%d = %s, so %s × %s = %s" % [a, I(int(pow(26, a))), b, I(int(pow(10, b))), I(int(pow(26, a))), I(int(pow(10, b))), I(n)],
			final(ans)], ans.values)}}


func u_no_repeat_number(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var d: int = s.d
	var n: int = s.count
	var ans := _ans("number of ways = ", s)
	var no_zero_rule := CountingSituation.perm(10, d)
	var boxes: PackedStringArray = ["9"]
	for i in d - 1:
		boxes.append(str(9 - i))
	return {"asked": "How many %d-digit numbers have no repeated digit?" % d, "lines": ["A %d-digit number does not start with 0." % d], "answer": ans,
		"wrongs": tagged([no_zero_rule], n, R_LEADING_ZERO),
		"generic": vs([int(pow(9, d)), 9 * int(pow(10, d - 1)), CountingSituation.perm(9, d), CountingSituation.perm(10, d - 1)], n),
		"methods": {
			"slot-boxes": method(["Draw %d boxes. The first digit can't be 0, so it has 9 choices." % d,
				"Each later box can use any digit not used yet, 0 included: %s." % ", ".join(boxes.slice(1)),
				"%s = %s" % [" × ".join(boxes), I(n)], final(ans)], ans.values),
			"complement-count": method(["With no repeats and 0 allowed first, there are 10P%d = %s strings of %d digits." % [d, I(no_zero_rule), d],
				"Those starting with 0 are 0 then %d more digits from the other 9: 9P%d = %s." % [d - 1, d - 1, I(CountingSituation.perm(9, d - 1))],
				"%s − %s = %s" % [I(no_zero_rule), I(CountingSituation.perm(9, d - 1)), I(n)], final(ans)], ans.values)}}


func u_even_numbers(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: int = s.m
	var d: int = s.d
	var n: int = s.count
	var ans := _ans("number of ways = ", s)
	var evens := m / 2
	var rest := PackedStringArray()
	for i in d - 1:
		rest.append(str(m - 1 - i))
	var free_first := CountingSituation.perm(m, d - 1) * evens
	return {"asked": "How many even %d-digit numbers can be made?" % d,
		"lines": ["The digits are 1 to %d, and each is used at most once." % m], "answer": ans,
		"wrongs": tagged([free_first], n, R_FREE_FIRST),
		"generic": vs([CountingSituation.perm(m, d), int(pow(evens, d)), evens * int(pow(m, d - 1)), CountingSituation.perm(m - 1, d - 1)], n),
		"methods": {"slot-boxes": method(["Draw %d boxes and fill the restricted one first: the last digit must be even, so it has %d choices." % [d, evens],
			"The other %d boxes use the digits left, in turn: %s." % [d - 1, ", ".join(rest)],
			"%d × %s = %s" % [evens, " × ".join(rest), I(n)], final(ans)], ans.values)}}


# ── Permutations ─────────────────────────────────────────────

func u_arrange_all(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var v: int = s.count
	var ans := _ans(_label(rep), s)
	var items := ["books", "flags", "tools", "photographs", "batteries", "jars"]
	var lines: Array = ["Evaluate %d!" % n] if rep == "equation" else ["%d different %s are arranged in a row." % [n, items[s.ctx % items.size()]]]
	var asked := "Find the value." if rep == "equation" else "In how many ways can this be done?"
	var steps := PackedStringArray()
	for i in n:
		steps.append(str(n - i))
	return {"asked": asked, "lines": lines, "answer": ans, "wrongs": [],
		"generic": vs([int(pow(n, n)), n * n, CountingSituation.fact(n - 1), CountingSituation.fact(n) / 2], v),
		"methods": {
			"npr-formula": method(["n objects in a row can be arranged in nPn = n!/0! = n! ways.", "%d! = %s" % [n, " × ".join(steps)], "= %s" % I(v), final(ans)], ans.values),
			"slot-product": method(["Draw %d places. The first can be filled %d ways, the next %d, and so on down to 1." % [n, n, n - 1],
				"%s = %s" % [" × ".join(steps), I(v)], final(ans)], ans.values)}}


const PLACES := {2: "A winner and a runner-up are chosen from %d runners.", 3: "Gold, silver and bronze medals are awarded among %d runners.",
	4: "The first four places are decided in a race with %d runners."}


func u_award_places(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var r: int = s.r
	var v: int = s.count
	var ans := _ans(_label(rep), s)
	var lines: Array = ["Evaluate %dP%d" % [n, r]] if rep == "equation" else [PLACES[r] % n]
	var asked := "Find the value." if rep == "equation" else "How many different results are possible?"
	var terms := PackedStringArray()
	for i in r:
		terms.append(str(n - i))
	return {"asked": asked, "lines": lines, "answer": ans,
		"wrongs": tagged([CountingSituation.comb(n, r)], v, R_COMB_FOR_PERM) + tagged([int(pow(n, r))], v, R_REPEATS) + tagged([CountingSituation.fact(n) / CountingSituation.fact(r)], v, R_PERM_OVER_R),
		"generic": vs([CountingSituation.perm(n, r - 1), CountingSituation.perm(n + 1, r), CountingSituation.perm(n, r + 1), n * r], v),
		"methods": {
			"npr-formula": method(["Order matters and nobody wins twice, so the count is %dP%d = %d!/%d!." % [n, r, n, n - r],
				"%d!/%d! = %s (the first %d terms of %d!)" % [n, n - r, " × ".join(terms), r, n], "= %s" % I(v), final(ans)], ans.values),
			"slot-product": method(["Draw %d places. The first can go to %d runners, the next to %d, and so on: nobody takes two places." % [r, n, n - 1],
				"%s = %s" % [" × ".join(terms), I(v)], final(ans)], ans.values),
			"gdc-npr": method(["Order matters, so use nPr on the GDC with n = %d and r = %d." % [n, r], "%dP%d = %s" % [n, r, I(v)], final(ans)], ans.values)}}


func u_find_n_from_npr(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var v: int = s.v
	var ans := ways("n = ", n)
	var lines: Array = ["nP2 = %d" % v] if rep == "equation" else ["A race has n runners. There are %d ways to award first and second place." % v]
	return {"asked": "Find n.", "lines": lines, "answer": ans, "wrongs": [],
		"generic": vs([n - 1, n + 1, v / 2, v - n], n),
		"methods": {"quadratic-in-n": method(["nP2 = n(n − 1) = %d, so n² − n − %d = 0." % [v, v],
			"Factorise: (n − %d)(n + %d) = 0, so n = %d or n = −%d." % [n, n - 1, n, n - 1],
			"n counts runners, so it is positive: n = %d." % n, final(ans)], ans.values)}}


# ── Combinations ─────────────────────────────────────────────

const GROUPS := [["men", "women"], ["boys", "girls"], ["scouts", "guides"], ["sailors", "pilots"], ["farmers", "traders"], ["engineers", "medics"]]


func u_committee(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var k: int = s.k
	var v: int = s.count
	var ans := _ans(_label(rep), s)
	var lines: Array = ["Evaluate %dC%d" % [n, k]] if rep == "equation" else ["A committee of %d is chosen from %d people." % [k, n]]
	var asked := "Find the value." if rep == "equation" else "How many different committees are possible?"
	return {"asked": asked, "lines": lines, "answer": ans,
		"wrongs": tagged([CountingSituation.perm(n, k)], v, R_PERM_FOR_COMB),
		"generic": vs([CountingSituation.comb(n, k - 1), CountingSituation.comb(n, k + 1), int(pow(n, k)), CountingSituation.comb(n + 1, k)], v),
		"methods": {"gdc-ncr": method(["The order of choosing doesn't matter, so use nCr on the GDC with n = %d and r = %d." % [n, k],
			"%dC%d = %s" % [n, k, I(v)], final(ans)], ans.values)}}


func _mixed_lines(s: Dictionary) -> Array:
	var g: Array = GROUPS[s.ctx % GROUPS.size()]
	return ["A committee of %d is chosen from %d %s and %d %s." % [s.k, s.men, g[0], s.women, g[1]]]


func u_committee_mixed(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var men: int = s.men
	var women: int = s.women
	var k: int = s.k
	var j: int = s.j
	var v: int = s.count
	var ans := _ans("number of ways = ", s)
	var g: Array = GROUPS[s.ctx % GROUPS.size()]
	var cw := CountingSituation.comb(women, j)
	var cm := CountingSituation.comb(men, k - j)
	return {"asked": "How many committees have exactly %d %s?" % [j, g[1]], "lines": _mixed_lines(s), "answer": ans,
		"wrongs": tagged([cw + cm], v, R_ADD_GROUPS),
		"generic": vs([CountingSituation.comb(men + women, k), CountingSituation.comb(women, j) * CountingSituation.comb(men, k), CountingSituation.comb(women, j) * CountingSituation.comb(men, k - j + 1), CountingSituation.perm(women, j) * CountingSituation.perm(men, k - j)], v),
		"methods": {
			"product-of-choices": method(["Choose the %s and the %s separately: %d %s from %d, and %d %s from %d." % [g[1], g[0], j, g[1], women, k - j, g[0], men],
				"%dC%d = %s and %dC%d = %s" % [women, j, I(cw), men, k - j, I(cm)],
				"The two choices happen together, so multiply: %s × %s = %s" % [I(cw), I(cm), I(v)], final(ans)], ans.values),
			"gdc-ncr": method(["Use nCr on the GDC for each group: %dC%d for the %s and %dC%d for the %s." % [women, j, g[1], men, k - j, g[0]],
				"%s × %s = %s" % [I(cw), I(cm), I(v)], final(ans)], ans.values)}}


func u_committee_at_least_one(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var men: int = s.men
	var women: int = s.women
	var k: int = s.k
	var v: int = s.count
	var ans := _ans("number of ways = ", s)
	var g: Array = GROUPS[s.ctx % GROUPS.size()]
	var all := CountingSituation.comb(men + women, k)
	var none := CountingSituation.comb(men, k)
	var terms := PackedStringArray()
	var parts := PackedStringArray()
	for j in range(1, mini(women, k) + 1):
		if k - j <= men:
			terms.append("%dC%d × %dC%d" % [women, j, men, k - j])
			parts.append(I(CountingSituation.comb(women, j) * CountingSituation.comb(men, k - j)))
	return {"asked": "How many committees have at least one of the %s?" % g[1], "lines": _mixed_lines(s), "answer": ans,
		"wrongs": tagged([women * CountingSituation.comb(men + women - 1, k - 1)], v, R_DOUBLE_COUNT),
		"generic": vs([all, none, women * CountingSituation.comb(men, k - 1), CountingSituation.comb(women, 1) + CountingSituation.comb(men, k - 1)], v),
		"methods": {
			"complement": method(["Count every committee, then take away the ones with none of the %s." % g[1],
				"All: %dC%d = %s. None of the %s: %dC%d = %s." % [men + women, k, I(all), g[1], men, k, I(none)],
				"%s − %s = %s" % [I(all), I(none), I(v)], final(ans)], ans.values),
			"case-sum": method(["Add the cases by the number of %s on it." % g[1],
				" + ".join(terms), "%s = %s" % [" + ".join(parts), I(v)], final(ans)], ans.values),
			"gdc-ncr": method(["Use nCr on the GDC for the total and for the committees with none of the %s." % g[1],
				"%dC%d − %dC%d = %s − %s" % [men + women, k, men, k, I(all), I(none)], "= %s" % I(v), final(ans)], ans.values)}}


# ── Restricted arrangements ──────────────────────────────────

func _row_lines(s: Dictionary, together: bool) -> Array:
	var who: String = ["friends", "guards", "scavengers", "traders", "pilots", "cadets"][s.ctx % 6]
	return ["%d %s sit in a row. Two particular %s %s sit next to each other." % [s.n, who, who, "must" if together else "must not"]]


func u_together(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var v: int = s.count
	var ans := _ans("number of ways = ", s)
	return {"asked": "In how many ways can they be arranged?", "lines": _row_lines(s, true), "answer": ans,
		"wrongs": tagged([CountingSituation.fact(n - 1)], v, R_NO_BLOCK_ORDER),
		"generic": vs([CountingSituation.fact(n), CountingSituation.fact(n) / 2, 2 * CountingSituation.fact(n), CountingSituation.fact(n - 2) * 2], v),
		"methods": {"glue-block": method(["Treat the two who must be together as one block: there are %d things to arrange, in %d! = %s ways." % [n - 1, n - 1, I(CountingSituation.fact(n - 1))],
			"The two can swap places inside the block: 2! = 2 ways.",
			"%s × 2 = %s" % [I(CountingSituation.fact(n - 1)), I(v)], final(ans)], ans.values)}}


func u_apart(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var n: int = s.n
	var v: int = s.count
	var ans := _ans("number of ways = ", s)
	var together := 2 * CountingSituation.fact(n - 1)
	return {"asked": "In how many ways can they be arranged?", "lines": _row_lines(s, false), "answer": ans,
		"wrongs": tagged([CountingSituation.fact(n) - 2], v, R_APART_MINUS_2),
		"generic": vs([together, CountingSituation.fact(n) / 2, CountingSituation.fact(n) - CountingSituation.fact(n - 1), CountingSituation.fact(n - 1) * (n - 2)], v),
		"methods": {"complement": method(["All arrangements: %d! = %s." % [n, I(CountingSituation.fact(n))],
			"With the two together, glue them into a block: 2 × %d! = %s." % [n - 1, I(together)],
			"%s − %s = %s" % [I(CountingSituation.fact(n)), I(together), I(v)], final(ans)], ans.values)}}
