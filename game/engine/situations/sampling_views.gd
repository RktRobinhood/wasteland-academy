class_name SamplingViews
extends ExtensionViews
## The views on the `sampling` situation: one builder per unknown of t4-sampling (FAL-726). A
## reading in words is a multiple-choice `claim`, as in DerivativeMeaningViews; a number is
## exact on both papers.
##
## Representations: "words" (a story) and "table" (each group's size, with the sample beside it).

const ST := "SL4.1.sampling-technique#"
const BI := "SL4.1.bias-reliability#"
const R_QUOTA := ST + "0"
const R_INTERVAL := ST + "1"
const R_STREET := ST + "2"
const R_LARGER := BI + "0"
const R_PERFECT := BI + "1"

const NAMES := {"simple": "Simple random sampling", "systematic": "Systematic sampling", "convenience": "Convenience sampling",
	"quota": "Quota sampling", "stratified": "Stratified sampling"}

## The stories: who is counted, where, three groups, a spot to stand at, the list of names, and
## what the survey wants to know.
const CONTEXTS := [
	{"who": "settlers", "place": "camp", "a": ["farmers", "guards", "cooks"], "spot": "at the well", "list": "the camp register", "topic": "how much water they use"},
	{"who": "traders", "place": "market", "a": ["salt sellers", "fuel sellers", "scrap dealers"], "spot": "at the market gate", "list": "the traders' ledger", "topic": "how far they travel"},
	{"who": "scavengers", "place": "depot", "a": ["day crew", "night crew", "drivers"], "spot": "at the depot door", "list": "the crew roster", "topic": "how many hours they work"},
	{"who": "miners", "place": "mine", "a": ["diggers", "haulers", "blasters"], "spot": "at the pit head", "list": "the pay book", "topic": "how often they fall ill"},
	{"who": "drivers", "place": "convoy", "a": ["truck drivers", "bike riders", "tanker drivers"], "spot": "at the fuel pump", "list": "the convoy log", "topic": "how much fuel they burn"},
	{"who": "medics", "place": "hospital", "a": ["nurses", "surgeons", "porters"], "spot": "at the supply tent", "list": "the duty rota", "topic": "how many hours they sleep"},
	{"who": "farmers", "place": "settlement", "a": ["goat keepers", "bean growers", "fish farmers"], "spot": "at the grain store", "list": "the land register", "topic": "how much they harvest"},
	{"who": "mechanics", "place": "workshop", "a": ["welders", "wirers", "fitters"], "spot": "at the tool hatch", "list": "the workshop roll", "topic": "how many repairs they finish"},
]

## Stories of a sample that leans one way: what is wanted, of whom, where they were asked, the
## way the estimate is pushed, and the reason each way.
const STORIES := [
	{"qty": "daily water use", "who": "settlers", "place": "camp", "where": "in the queue at the well", "high": true, "more": "people in that queue fetch more water than most.", "less": "people in that queue fetch less water than most."},
	{"qty": "weekly walking distance", "who": "scavengers", "place": "depot", "where": "in the sick bay", "high": false, "more": "people in the sick bay walk further than most.", "less": "people in the sick bay walk less than most."},
	{"qty": "weekly fuel use", "who": "drivers", "place": "convoy", "where": "in the line at the fuel pump", "high": true, "more": "people in that line burn more fuel than most.", "less": "people in that line burn less fuel than most."},
	{"qty": "hours of sleep", "who": "guards", "place": "fort", "where": "on the night watch", "high": false, "more": "people on the night watch sleep more than most.", "less": "people on the night watch sleep less than most."},
	{"qty": "monthly takings", "who": "traders", "place": "market", "where": "at the largest stalls", "high": true, "more": "people at the largest stalls take more than most.", "less": "people at the largest stalls take less than most."},
	{"qty": "meals a day", "who": "settlers", "place": "camp", "where": "in the hunger ward", "high": false, "more": "people in the hunger ward eat more than most.", "less": "people in the hunger ward eat less than most."},
	{"qty": "hours worked", "who": "mechanics", "place": "workshop", "where": "at their benches at midnight", "high": true, "more": "people at their benches at midnight work longer than most.", "less": "people at their benches at midnight work less than most."},
	{"qty": "age", "who": "settlers", "place": "settlement", "where": "in the schoolroom", "high": false, "more": "people in the schoolroom are older than most.", "less": "people in the schoolroom are younger than most."},
]

## Figures from a doubtful source: who says what, from what, and why it can't be trusted.
const SOURCES := [
	{"who": "A fuel trader", "says": "of drivers prefer his fuel", "from": "thank-you notes from %d of his own customers", "why": "He hears only from his own happy customers, and he gains if the figure is high."},
	{"who": "A water seller", "says": "of her jars are clean", "from": "her own test of %d jars", "why": "She tested her own jars, and she gains if the figure is high."},
	{"who": "A filter maker", "says": "of his filters last a year", "from": "letters from %d buyers who came back", "why": "Buyers whose filters failed are unlikely to have written in."},
	{"who": "A camp leader", "says": "of the camp back her plan", "from": "a show of hands from %d people in front of her guards", "why": "People may not say what they think in front of her guards."},
	{"who": "A radio host", "says": "of listeners want a new road", "from": "%d people who called the show", "why": "Only people who feel strongly enough to call are counted."},
	{"who": "An old map", "says": "of the ruins are safe", "from": "a walk through %d ruins before the floods", "why": "The survey is old, and the floods may have changed the ruins."},
]

## What could go wrong with a technique, and which technique each one is true of.
const FLAWS := {"list": "It needs a complete list of everyone in the %s.",
	"pattern": "A repeating pattern in the list could match the interval.",
	"groups": "The size of each group must be known before starting.",
	"passers": "Those who come by first may differ from the rest of the %s.",
	"chooser": "Nobody is drawn at random within a group, so the surveyor's choices can skew it.",
	"start": "Only the starting point is chosen at random."}
const MAIN_FLAW := {"simple": "list", "systematic": "pattern", "stratified": "groups", "convenience": "passers", "quota": "chooser"}
## Flaws that are false of the technique, so each is a wrong option.
const FALSE_FLAWS := {"simple": ["pattern", "start", "chooser", "passers"], "systematic": ["chooser", "passers", "groups"],
	"stratified": ["pattern", "start", "passers", "chooser"], "convenience": ["list", "pattern", "start"], "quota": ["list", "pattern", "start"]}

const UNKNOWNS := ["name-technique", "technique-disadvantage", "describe-systematic", "systematic-interval", "systematic-member",
	"best-technique", "is-it-random", "quota-number", "fair-share", "under-represented", "why-biased", "bias-direction",
	"better-method", "bigger-sample", "random-not-perfect", "improve-reliability", "source-reliability"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1, 2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = SamplingSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func ctx(s: Dictionary) -> Dictionary:
	return CONTEXTS[s.ctx]


static func group(s: Dictionary, i: int) -> String:
	return ctx(s).a[i]


static func cap(t: String) -> String:
	return t[0].to_upper() + t.substr(1)


## "12th", "21st", "3rd".
static func ordinal(k: int) -> String:
	var tail := "th"
	if k % 100 < 11 or k % 100 > 13:
		tail = {1: "st", 2: "nd", 3: "rd"}.get(k % 10, "th")
	return "%d%s" % [k, tail]


## "A camp has 240 settlers: 160 farmers and 80 guards."
static func camp_line(s: Dictionary) -> String:
	var c := ctx(s)
	var parts: Array = []
	for i in s.G.size():
		parts.append("%d %s" % [s.G[i], group(s, i)])
	var groups: String = ", ".join(parts.slice(0, -1)) + " and " + parts[-1]
	return "A %s has %d %s: %s." % [c.place, s.N, c.who, groups]


## What the surveyor does, for a technique.
static func method_line(s: Dictionary, tech: String) -> String:
	var c := ctx(s)
	match tech:
		"simple":
			return "A surveyor numbers everyone on %s and draws %d of the numbers at random." % [c.list, s.n]
		"systematic":
			return "A surveyor goes down %s, picks a random start among the first %d names, then takes every %s name." % [c.list, s.k, ordinal(s.k)]
		"convenience":
			return "A surveyor stands %s and asks the first %d %s who come by." % [c.spot, s.n, c.who]
		"stratified":
			return "A surveyor draws %d %s and %d %s at random from %s." % [s.q[0], group(s, 0), s.q[1], group(s, 1), c.list]
	return "A surveyor stands %s and asks whoever comes by until there are %d %s and %d %s." % [c.spot, s.q[0], group(s, 0), s.q[1], group(s, 1)]


static func claims(right: String, wrongs_in: Array) -> Dictionary:
	return DerivativeMeaningViews.claim_answer(right, wrongs_in)


static func count_ans(label: String, n: int) -> Dictionary:
	var ans := Answer.make("number", {"v": Q.new(n)}, {}, label)
	ans.exact = true
	return ans


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func nums(xs: Array) -> Array:
	return xs.filter(func(x): return x > 0).map(func(x): return {"v": Q.new(x)})


## A table of the groups: [head, value], one column per list in `cols`.
static func groups_table(s: Dictionary, heads: Array, cols: Array, total: Array) -> Dictionary:
	var rows: Array = [["group", heads]]
	for i in s.G.size():
		rows.append([group(s, i), cols.map(func(col): return str(col[i]))])
	rows.append(["Total", total.map(func(t): return str(t))])
	return {"rows": rows}


# ── Naming a technique ───────────────────────────────────────

## How each technique passes the checklist, in a sentence or two, for the working.
static func checklist(s: Dictionary, tech: String) -> Array:
	match tech:
		"simple":
			return ["No fixed interval, and no group is filled.", "Everyone is numbered and the numbers are drawn at random, so everyone has an equal chance."]
		"systematic":
			return ["There is a fixed interval: every %s name." % ordinal(s.k), "Only the start is random, so the rest follows the interval."]
		"convenience":
			return ["No interval, no groups and no random draw.", "It takes whoever is easiest to reach."]
		"stratified":
			return ["The groups are filled in proportion: %d and %d out of %d and %d." % [s.q[0], s.q[1], s.G[0], s.G[1]], "Inside each group the choice is random."]
	return ["The groups are filled in proportion: %d and %d out of %d and %d." % [s.q[0], s.q[1], s.G[0], s.G[1]], "Inside each group nothing is random: it takes whoever comes by."]


## Who the technique leaves out, for the working.
static func flaw_steps(s: Dictionary, tech: String) -> Array:
	match tech:
		"simple":
			return ["Nobody is left out: everyone is on the list.", "No interval or forced group shapes who gets in."]
		"systematic":
			return ["Once the start is drawn, most names can't be chosen: picks are %d apart." % s.k, "That rules out a free random draw."]
		"convenience":
			return ["Anyone who doesn't come by can never be chosen.", "No list, no interval and no groups are used."]
		"stratified":
			return ["Each group's size in the sample is fixed, so neither can be over-represented.", "Names are drawn at random, so the surveyor can't favour anyone."]
	return ["Each group's size in the sample is fixed, so neither can be over-represented.", "But the surveyor takes whoever comes by, so anyone who doesn't come by can't be chosen."]


func u_name_technique(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right: String = NAMES[s.tech]
	var wrongs: Array = {
		"simple": [[NAMES.systematic, ""], [NAMES.convenience, ""], [NAMES.stratified, ""]],
		"systematic": [[NAMES.simple, R_INTERVAL], [NAMES.stratified, ""], [NAMES.convenience, ""]],
		"convenience": [[NAMES.simple, R_STREET], [NAMES.quota, ""], [NAMES.systematic, ""]],
		"quota": [[NAMES.stratified, R_QUOTA], [NAMES.convenience, ""], [NAMES.simple, ""]],
		"stratified": [[NAMES.quota, R_QUOTA], [NAMES.simple, ""], [NAMES.systematic, ""]]}[s.tech]
	var built := claims(right, wrongs)
	return {"lines": [camp_line(s), method_line(s, s.tech)], "asked": "Which sampling technique is this?", "answer": built.answer, "wrongs": built.wrongs,
		"methods": {"feature-checklist": method(checklist(s, s.tech) + [right], built.answer.values),
			"eliminate-by-flaw": method(flaw_steps(s, s.tech) + [right], built.answer.values)}}


func u_technique_disadvantage(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var flaw := func(key: String) -> String: return FLAWS[key] % c.place if "%s" in FLAWS[key] else FLAWS[key]
	var right: String = flaw.call(MAIN_FLAW[s.tech])
	var built := claims(right, FALSE_FLAWS[s.tech].map(func(key): return [flaw.call(key), ""]))
	return {"lines": [camp_line(s), method_line(s, s.tech)], "asked": "Which of these is a real disadvantage of this method?", "answer": built.answer, "wrongs": built.wrongs,
		"methods": {"eliminate-by-flaw": method(["This is %s." % NAMES[s.tech].to_lower()] + flaw_steps(s, s.tech).slice(0, 1) + [right], built.answer.values)}}


func u_best_technique(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var a := group(s, 0)
	var b := group(s, 1)
	var lines: Array = []
	var wrongs: Array = []
	var why: Array = []
	var flawed: Array = []
	match s.tech:
		"stratified":
			lines = [camp_line(s), "%s lists everyone. The sample of %d must match the mix of %s and %s, and everyone in a group must have an equal chance." % [cap(c.list), s.n, a, b]]
			wrongs = [[NAMES.quota, R_QUOTA], [NAMES.simple, ""], [NAMES.convenience, ""]]
			why = ["The mix must match, so the groups are filled in proportion.", "An equal chance inside each group means a random draw."]
			flawed = ["A simple random draw could miss the mix, and a quota isn't random.", "Only filling each group by a random draw has neither flaw."]
		"quota":
			lines = [camp_line(s), "There is no list, and the surveyor can only reach people %s. The sample of %d must still match the mix of %s and %s." % [c.spot, s.n, a, b]]
			wrongs = [[NAMES.stratified, R_QUOTA], [NAMES.simple, ""], [NAMES.systematic, ""]]
			why = ["The mix must match, so the groups are filled in proportion.", "With no list there can be no random draw inside a group."]
			flawed = ["With no list, a random draw inside a group can't be done, and asking the first to come by could miss the mix.", "Filling each group as people come by is what is left."]
		"systematic":
			lines = ["The %d %s come by %s one at a time during a shift." % [s.N, c.who, c.spot], "There is no list. The surveyor wants %d of them, spread evenly along the line, from a random start." % s.n]
			wrongs = [[NAMES.simple, R_INTERVAL], [NAMES.stratified, ""], [NAMES.quota, ""]]
			why = ["Spread evenly along a line means a fixed interval: every %s." % ordinal(s.k), "A random start then fixes the rest."]
			flawed = ["With no list there is nothing to draw numbers from.", "No groups are asked for, so a fixed interval from a random start is what is left."]
		_:
			lines = ["%s lists all %d %s by number." % [cap(c.list), s.N, c.who], "The groups don't matter here. The surveyor wants every set of %d to have the same chance." % s.n]
			wrongs = [[NAMES.systematic, R_INTERVAL], [NAMES.convenience, ""], [NAMES.quota, ""]]
			why = ["Every set of %d has the same chance only if the names are drawn freely." % s.n, "A fixed interval would rule out most sets, and no group is needed."]
			flawed = ["A fixed interval rules out most sets of %d, and a spot leaves out whoever doesn't come by." % s.n, "A draw from the full list has neither flaw."]
	var right: String = NAMES[s.tech]
	var built := claims(right, wrongs)
	return {"lines": lines, "asked": "Which technique fits best?", "answer": built.answer, "wrongs": built.wrongs,
		"methods": {"feature-checklist": method(why + [right], built.answer.values), "eliminate-by-flaw": method(flawed + [right], built.answer.values)}}


func u_is_it_random(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := ""
	var wrongs: Array = []
	match s.tech:
		"systematic":
			right = "No: only the start is random, and the interval fixes every pick after it."
			wrongs = [["Yes: the start is random, so the whole sample is random.", R_INTERVAL],
				["Yes: every %s name is as good as any other." % ordinal(s.k), ""], ["No: a sample from a list can never be random.", ""]]
		"convenience":
			right = "No: anyone who doesn't come by has no chance of being chosen."
			wrongs = [["Yes: whoever comes by is a random person.", R_STREET], ["Yes: the surveyor didn't choose who came by.", ""], ["No: a sample of %d is too large to be random." % s.n, ""]]
		_:
			right = "Yes: every set of %d people has the same chance." % s.n
			wrongs = [["No: a sample from a list can never be random.", ""], ["No: only the start is random.", R_INTERVAL], ["No: some people on the list were left out.", ""]]
	var built := claims(right, wrongs)
	return {"lines": [camp_line(s), method_line(s, s.tech)], "asked": "Is this a simple random sample?", "answer": built.answer, "wrongs": built.wrongs,
		"methods": {"feature-checklist": method(checklist(s, s.tech) + [right], built.answer.values),
			"eliminate-by-flaw": method(flaw_steps(s, s.tech) + [right], built.answer.values)}}


# ── A systematic sample ──────────────────────────────────────

## "A sample of 5% is wanted." or "A sample of 20 is wanted."
static func size_line(s: Dictionary) -> String:
	if s.pct > 0 and (s.n + s.k) % 2 == 0:
		return "The surveyor wants a sample of %d%% of them." % s.pct
	return "The surveyor wants a sample of %d of them." % s.n


func u_describe_systematic(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var full := "Go down %s, pick a random start among the first %d names, then take every %s name."
	var right: String = full % [c.list, s.k, ordinal(s.k)]
	var built := claims(right, [["Draw %d names at random from %s." % [s.n, c.list], R_INTERVAL],
		[full % [c.list, s.n, ordinal(s.n)], ""],
		["Take the first %d names on %s." % [s.n, c.list], ""],
		["Ask the first %d %s who come by." % [s.n, c.who], ""]])
	return {"lines": [camp_line(s), size_line(s)], "asked": "Which of these describes a systematic sample?", "answer": built.answer, "wrongs": built.wrongs,
		"methods": {"feature-checklist": method(["A systematic sample needs a fixed interval: %d ÷ %d = %d." % [s.N, s.n, s.k], "Only the start is random, so it is drawn among the first %d." % s.k, right], built.answer.values)}}


func u_systematic_interval(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var ans := count_ans("interval = ", s.k)
	return {"lines": ["%s lists %d %s." % [cap(c.list), s.N, c.who], size_line(s)], "asked": "Find the interval for a systematic sample.", "answer": ans,
		"wrongs": [], "generic": nums([s.n, s.N - s.n, 2 * s.k, s.k + 1, s.k - 1, s.k + 2]),
		"methods": {"feature-checklist": method(["The %d picks spread evenly over the %d names." % [s.n, s.N], "%d ÷ %d = %d" % [s.N, s.n, s.k], final_step(ans)], ans.values)}}


func u_systematic_member(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var v: int = s.start + (s.j - 1) * s.k
	var ans := count_ans("number ", v)
	return {"lines": ["%s numbers %d %s from 1 to %d." % [cap(c.list), s.N, c.who, s.N], "A systematic sample starts at number %d and takes every %s name." % [s.start, ordinal(s.k)]],
		"asked": "Find the number of the %s person chosen." % ordinal(s.j), "answer": ans, "wrongs": [],
		"generic": nums([s.start + s.j * s.k, s.j * s.k, s.start + s.j - 1, s.start + (s.j - 2) * s.k, v + 1]),
		"methods": {"feature-checklist": method(["The first pick is number %d, and each pick after it adds %d." % [s.start, s.k],
			"The %s pick is %d steps on: %d + %d × %d" % [ordinal(s.j), s.j - 1, s.start, s.j - 1, s.k], final_step(ans)], ans.values)}}


# ── Numbers in proportion ────────────────────────────────────

func u_quota_number(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var g: int = s.g
	var ans := count_ans("number = ", s.q[g])
	var word := "quota" if s.tech == "quota" else "stratified"
	var line := "A %s sample of %d must match the mix of the %s." % [word, s.n, c.place]
	var out := {"lines": [camp_line(s), line], "asked": "Find how many %s go in the sample." % group(s, g), "answer": ans, "wrongs": []}
	if rep == "table":
		out.lines = ["The table shows the %d %s in a %s." % [s.N, c.who, c.place], line]
		out.table = groups_table(s, ["number"], [s.G], [s.N])
	var pool: Array = [s.n - s.q[g], s.q[(g + 1) % 3], s.q[(g + 2) % 3], s.q[g] + 1, s.q[g] + 2, s.q[g] - 1]
	if s.n % 3 == 0:
		pool.insert(0, s.n / 3)
	out.generic = nums(pool)
	out.methods = {"feature-checklist": method(["Groups filled in proportion: every group is cut by the same factor, %d ÷ %d = %d." % [s.N, s.n, s.k],
		"%d ÷ %d = %d" % [s.G[g], s.k, s.q[g]], final_step(ans)], ans.values)}
	return out


func u_fair_share(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var g: int = s.g
	var short: int = s.q[g] - s.got[g]
	var ans := count_ans("number = ", short)
	var out := {"asked": "By how many does the number of %s fall short of the mix of the %s?" % [group(s, g), c.place], "answer": ans, "wrongs": []}
	if rep == "table":
		out.lines = ["The table shows a %s of %d %s and a sample of %d of them." % [c.place, s.N, c.who, s.n]]
		out.table = groups_table(s, [c.place, "sample"], [s.G, s.got], [s.N, s.n])
	else:
		out.lines = [camp_line(s), "A sample of %d holds %d %s, %d %s and %d %s." % [s.n, s.got[0], group(s, 0), s.got[1], group(s, 1), s.got[2], group(s, 2)]]
	out.generic = nums([s.q[g], s.got[g], s.G[g] - s.got[g], short + 1, short + 2, short + 3])
	out.methods = {"compare-proportions": method(["The %s are %d of %d in the %s, the same share as %d of %d." % [group(s, g), s.G[g], s.N, c.place, s.q[g], s.n],
		"The sample holds %d of them." % s.got[g], "%d − %d = %d" % [s.q[g], s.got[g], short], final_step(ans)], ans.values)}
	return out


func u_under_represented(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var g: int = s.g
	var right := cap(group(s, g))
	var low: int = s.got.find(s.got.min())
	var other: int = 3 - g - low
	var built := claims(right, [[cap(group(s, low)), ""], [cap(group(s, other)), ""], ["None: the sample matches the %s." % c.place, R_PERFECT]])
	var fair: Array = s.q
	return {"lines": ["The table shows a %s of %d %s and a sample of %d of them." % [c.place, s.N, c.who, s.n]], "table": groups_table(s, [c.place, "sample"], [s.G, s.got], [s.N, s.n]),
		"asked": "Which group is most under-represented in the sample?", "answer": built.answer, "wrongs": built.wrongs,
		"methods": {"compare-proportions": method(["Scale the %s down by %d: a matching sample holds %d, %d and %d." % [c.place, s.k, fair[0], fair[1], fair[2]],
			"The sample holds %d, %d and %d." % s.got, "%s fall short by %d, the most of any group." % [cap(group(s, g)), fair[g] - s.got[g]], right], built.answer.values)}}


# ── Bias ─────────────────────────────────────────────────────

## A survey of one group alone: "To learn how much water ...".
static func one_group_line(s: Dictionary) -> String:
	var c := ctx(s)
	return "To learn %s across the whole %s, a surveyor draws %d %s at random and asks only them." % [c.topic, c.place, s.n, group(s, 0)]


static func compare_step(s: Dictionary) -> String:
	return "The %s are %d of the %d in the %s, but all %d of the sample." % [group(s, 0), s.G[0], s.N, ctx(s).place, s.n]


func u_why_biased(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var a := group(s, 0)
	var b := group(s, 1)
	var right := "Only %s were asked, so the %s had no chance of being chosen." % [a, b]
	var built := claims(right, [["The sample is too small: with more %s it would have no bias." % a, R_LARGER],
		["Nothing: a random draw always represents the whole %s." % c.place, R_PERFECT],
		["A random draw always favours the larger group.", ""]])
	return {"lines": [camp_line(s), one_group_line(s)], "asked": "Why might this not represent the whole %s?" % c.place, "answer": built.answer, "wrongs": built.wrongs,
		"methods": {"who-is-missing": method(["Picture the whole %s: %d %s and %d %s." % [c.place, s.G[0], a, s.G[1], b], "Nobody from the %s can be chosen." % b, right], built.answer.values),
			"compare-proportions": method([compare_step(s), "So the sample's make-up is far from the population's.", right], built.answer.values)}}


func u_better_method(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var a := group(s, 0)
	var b := group(s, 1)
	var right := "Stratified sampling: draw at random from both the %s and the %s, in proportion to their numbers." % [a, b]
	var built := claims(right, [["Keep to the %s, and ask %d of them instead." % [a, 2 * s.n], R_LARGER],
		["Change nothing: a random draw from the %s is enough." % a, R_PERFECT],
		["Ask the first %d %s who come by %s." % [s.n, c.who, c.spot], R_STREET]])
	return {"lines": [camp_line(s), one_group_line(s)], "asked": "Which change would make the sample represent the whole %s?" % c.place, "answer": built.answer, "wrongs": built.wrongs,
		"methods": {"who-is-missing": method(["The %s are left out, so more %s can't fix it." % [b, a], "Both groups need a place, in proportion, and a random draw keeps the choice fair.", right], built.answer.values)}}


func u_bias_direction(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: Dictionary = STORIES[s.story]
	var right: String = ("Too high: " + t.more) if t.high else ("Too low: " + t.less)
	var other: String = ("Too low: " + t.less) if t.high else ("Too high: " + t.more)
	var built := claims(right, [[other, ""], ["Neither: asking %d people cancels out any bias." % s.n, R_LARGER], ["Neither: a sample is always a fair picture of everyone.", R_PERFECT]])
	return {"lines": ["A surveyor wants to estimate the mean %s of all the %s in a %s." % [t.qty, t.who, t.place], "She asks %d of them, all %s." % [s.n, t.where]],
		"asked": "How is her estimate likely to be wrong?", "answer": built.answer, "wrongs": built.wrongs,
		"methods": {"who-is-missing": method(["Picture all the %s: she reaches only those %s." % [t.who, t.where], "Those people are not typical, and the rest are left out.", right], built.answer.values)}}


func u_bigger_sample(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var a := group(s, 0)
	var b := group(s, 1)
	var right := "No: the result gets steadier, but the %s are still left out." % b
	var built := claims(right, [["Yes: a larger sample removes bias.", R_LARGER],
		["Yes: with %d people everyone has had a chance." % (3 * s.n), ""],
		["No: a larger sample always makes the bias worse.", ""]])
	return {"lines": [camp_line(s), "A surveyor asks %d %s about %s, and none of the %s." % [s.n, a, c.topic, b], "She plans to ask %d %s instead." % [3 * s.n, a]],
		"asked": "Will asking more remove the bias?", "answer": built.answer, "wrongs": built.wrongs,
		"methods": {"who-is-missing": method(["A larger sample makes a result more reliable.", "But the %s still can't be chosen, so the method stays biased." % b, right], built.answer.values),
			"compare-proportions": method([compare_step(s), "With %d %s, the sample is still all %s." % [3 * s.n, a, a], right], built.answer.values)}}


func u_random_not_perfect(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var g: int = s.g
	var a := group(s, g)
	var right := "The draw can be fair and still miss the mix: chance alone moves a sample."
	var built := claims(right, [["The draw can't have been random: a random sample always matches the %s." % c.place, R_PERFECT],
		["The %s's numbers must be wrong: a sample shows the true mix." % c.place, R_PERFECT],
		["The method is biased against the %s." % a, ""]])
	var line := "A simple random sample of %d holds %d %s and %d %s." % [s.n, s.got[0], group(s, 0), s.got[1], group(s, 1)]
	var out := {"lines": [camp_line(s), line], "asked": "What does this show?", "answer": built.answer, "wrongs": built.wrongs}
	if rep == "table":
		out.lines = ["The table shows a %s of %d %s and a simple random sample of %d of them." % [c.place, s.N, c.who, s.n]]
		out.table = groups_table(s, [c.place, "sample"], [s.G, s.got], [s.N, s.n])
	out.methods = {"compare-proportions": method(["A sample that matched would hold %d %s, and this one holds %d." % [s.q[g], a, s.got[g]],
		"Everyone still had an equal chance, so the method is not biased.", right], built.answer.values)}
	return out


func u_improve_reliability(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var right := "Take a larger random sample, so that one person counts for less."
	var built := claims(right, [["Keep the %d: a random sample is always exact." % s.n, R_PERFECT],
		["Ask the same %d people again." % s.n, ""],
		["Leave out anyone whose answer looks unusual.", ""]])
	return {"lines": ["A surveyor wants to learn %s, so she draws %d of all the %s at random." % [c.topic, s.n, c.who], "Each time she repeats this, the result changes a lot."],
		"asked": "What would make the result more reliable?", "answer": built.answer, "wrongs": built.wrongs,
		"methods": {"who-is-missing": method(["Nobody is left out: the draw is random.", "The trouble is the size: with only %d people, one odd answer moves the result." % s.n, right], built.answer.values),
			"compare-proportions": method(["One person is 1/%d of the sample." % s.n, "So the sample's make-up can swing far from the population's by chance.", right], built.answer.values)}}


func u_source_reliability(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var t: Dictionary = SOURCES[s.story]
	var right: String = t.why
	var built := claims(right, [["It is reliable: %d is enough to remove any bias." % s.n, R_LARGER],
		["It is reliable: a figure that is written down can't be wrong.", ""],
		["It can't be used, because a percentage is never exact.", ""]])
	return {"lines": ["%s says %d%% %s." % [t.who, s.rate, t.says], "The figure comes from %s." % (t.from % s.n)], "asked": "Why might this figure not be reliable?",
		"answer": built.answer, "wrongs": built.wrongs,
		"methods": {"who-is-missing": method(["Look at where the figure comes from, not at how large it is.", "Ask who is left out, or who gains.", right], built.answer.values)}}
