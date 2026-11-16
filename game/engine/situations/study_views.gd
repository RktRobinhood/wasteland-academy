class_name StudyViews
extends ExtensionViews
## The views on the `study` situation: one builder per unknown of t4-ext-population-sample (FAL-778).
## Every answer is a picked `claim`. Wrong options are SL4.1.population-sample's two misconceptions
## (the people asked given as the population, whoever comes by called random) and the type's own
## two (everyone given as the sample, a larger sample taken to fix a method that leaves people out).
##
## Representation: "words" (the study in three sentences).

const SK := "SL4.1.population-sample#"
const R_ASKED_AS_POPULATION := SK + "0"
const R_PASSERS_RANDOM := SK + "1"
const R_ALL_AS_SAMPLE := "t4-ext-population-sample#2"
const R_LARGER := "t4-ext-population-sample#3"
const UNKNOWNS := ["name-population", "name-sample", "is-random", "make-random"]


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
	return [1, 2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = StudySituation.export(s)
	return out


static func ctx(s: Dictionary) -> Dictionary:
	return SamplingViews.CONTEXTS[s.ctx]


static func group(s: Dictionary) -> String:
	return ctx(s).a[s.g]


## The study: the place, what is wanted, and how the people asked were chosen.
static func lines(s: Dictionary) -> Array:
	var c := ctx(s)
	var how := ""
	match s.how:
		"draw":
			how = "She numbers everyone on %s, draws %d of the numbers at random and asks those %d %s." % [c.list, s.n, s.n, c.who]
		"spot":
			how = "She stands %s and asks the first %d %s who come by." % [c.spot, s.n, c.who]
		"volunteer":
			how = "She pins up a notice %s and asks the first %d %s who reply." % [c.spot, s.n, c.who]
		"group":
			how = "She draws %d of the %s at random from %s and asks only them." % [s.n, group(s), c.list]
	return ["The %s has %d %s." % [c.place, s.N, c.who], "A surveyor wants to learn %s." % c.topic, how]


static func everyone(s: Dictionary) -> String:
	return "All %d %s in the %s." % [s.N, ctx(s).who, ctx(s).place]


static func asked_ones(s: Dictionary) -> String:
	return "The %d %s she asked." % [s.n, ctx(s).who]


## Two wrong answers that are neither the population nor the sample.
static func elsewhere(s: Dictionary) -> Array:
	var c := ctx(s)
	return ["Every one of the %s anywhere in the wasteland." % c.who, "Only the %s in the %s." % [c.a[(s.g + 1) % 3], c.place]]


## Why the sample is or isn't random, as the right answer says it.
static func why_random(s: Dictionary) -> String:
	var c := ctx(s)
	match s.how:
		"draw":
			return "Yes: everyone on %s had the same chance of being chosen." % c.list
		"spot":
			return "No: anyone who doesn't come by %s had no chance of being chosen." % c.spot
		"volunteer":
			return "No: only people who choose to reply could be in the sample."
	return "No: only the %s could be chosen, so the other %s had no chance." % [group(s), c.who]


func _pack(s: Dictionary, asked: String, right: String, wrongs: Array, steps: Array) -> Dictionary:
	var built := SamplingViews.claims(right, wrongs)
	return {"lines": lines(s), "asked": asked, "answer": built.answer, "wrongs": built.wrongs, "fillers": built.fillers,
		"methods": {"definition-check": method(steps + [right], built.answer.values)}}


func u_name_population(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var other := elsewhere(s)
	return _pack(s, "What is the population in this study?", everyone(s), [[asked_ones(s), R_ASKED_AS_POPULATION], [other[0], ""], [other[1], ""]],
		["The population is everyone the study wants to learn about.", "That is all the %s in the %s, not only the %d she asked." % [c.who, c.place, s.n]])


func u_name_sample(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var other := elsewhere(s)
	return _pack(s, "What is the sample in this study?", asked_ones(s), [[everyone(s), R_ALL_AS_SAMPLE], [other[0], ""], [other[1], ""]],
		["The sample is the part of the population that is actually asked.", "She asks %d of the %d %s." % [s.n, s.N, c.who]])


func u_is_random(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var right := why_random(s)
	var larger := ["Yes: %d people is enough to make it random." % s.n, R_LARGER]
	var wrongs: Array
	var fact: String
	match s.how:
		"draw":
			wrongs = [["No: she chose which numbers to draw.", ""], ["No: a sample has to include everyone to be random.", ""], ["No: %d people is too few for a random sample." % s.n, ""]]
			fact = "Every one of the %d %s is on %s, and the draw picks numbers by chance." % [s.N, c.who, c.list]
		"spot":
			wrongs = [["Yes: whoever comes by is chosen by chance.", R_PASSERS_RANDOM], larger, ["Yes: she didn't pick anyone herself.", ""]]
			fact = "Only those who come by %s can be asked." % c.spot
		"volunteer":
			wrongs = [larger, ["Yes: nobody was made to reply, so it is random.", ""], ["Yes: the notice was seen by chance.", ""]]
			fact = "Only those who choose to reply can be asked."
		_:
			wrongs = [larger, ["Yes: the %s were drawn at random." % group(s), ""], ["Yes: every one of the %s had the same chance." % group(s), ""]]
			fact = "Only the %s are in the draw." % group(s)
	return _pack(s, "Is the sample random? Give a reason.", right, wrongs,
		["A sample is random only if everyone in the population had the same chance of being chosen.", fact])


func u_make_random(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := ctx(s)
	var right := "Number everyone on %s and draw %d of the numbers at random." % [c.list, s.n]
	var wrongs: Array = [["Keep the same method and ask %d %s instead." % [2 * s.n, c.who], R_LARGER],
		["Stand %s at a different time and ask the first %d %s who come by." % [c.spot, s.n, c.who], R_PASSERS_RANDOM],
		["Ask only the %s, drawn at random." % c.a[(s.g + 1) % 3], ""]]
	return _pack(s, "Which change would make this a random sample?", right, wrongs,
		["For a random sample, everyone in the population must have the same chance of being chosen.",
			"So no place, choice or group can decide who is in it; a numbered draw from everyone does that."])
