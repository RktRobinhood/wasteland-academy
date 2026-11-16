class_name StudySituation
extends RefCounted
## The `study` situation (curriculum/question-types.json): a surveyor who wants to learn something
## about all the people in a place and asks some of them, for t4-ext-population-sample (FAL-778).
## The stories are SamplingViews.CONTEXTS.
##
## generate() returns ask, paper, ctx (an index into CONTEXTS), N (the population), n (the
## sample) and how: "draw" (a numbered draw from everyone: random), "spot" (the first n to come by),
## "volunteer" (those who answer a notice) or "group" (a draw from one group only, g).

const HOWS := ["draw", "spot", "volunteer", "group"]
const NOT_RANDOM := ["spot", "volunteer", "group"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "name-population")
	var paper := int(need.get("paper", 1))
	var s := {"ask": ask, "paper": paper, "ctx": rng.int_in(0, SamplingViews.CONTEXTS.size() - 1), "g": rng.int_in(0, 2)}
	s.N = rng.int_in(12, 60) * 10 if paper == 1 else rng.int_in(24, 96) * 25
	# The sample is well under the population: less than a quarter of it.
	s.n = rng.int_in(2, mini(12, (s.N - 1) / 20)) * 5
	match ask:
		"is-random":
			# The spot comes up most, so its slip is seen most.
			s.how = HOWS[rng.weighted([3, 4, 2, 2])]
		"make-random":
			s.how = HOWS[rng.weighted([0, 4, 2, 2])]
		_:
			s.how = rng.pick(HOWS)
	return s


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
