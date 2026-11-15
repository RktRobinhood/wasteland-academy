class_name RateOfRateSituation
extends RefCounted
## The `rate-of-rate` situation (curriculum/question-types.json): a quantity in a story with the
## signs of its first and second derivatives, for t5-ext-interpret-second-derivative (FAL-777).
## The signs are mostly mixed, where reading f″ as the direction gives the wrong answer.
##
## generate() returns ask, paper (always 1), story (an index into STORIES), s1 and s2 (the signs
## of the first and second derivatives, ±1) and:
##   sentence-from-signs, signs-from-sentence  t1, t2: the stretch of time, t1 < t < t2
##   signs-from-sentence                       also rate_words: the sentence says "at a
##                                             decreasing rate" (a rise that slows only)
##   from-graph, from-model                    c (the cubic's [t³, t², t, 1] coefficients) and t0;
##                                             the signs are those of h′(t₀) and h″(t₀)
##
## The clean limits are the checker's too (E14RR_*).

const TRIES := 4000
const END := 6
## The stories: the letter, the quantity, and its words for going up and down.
const STORIES := [
	{"q": "N", "name": "number of rats in a bunker", "up": "increasing", "down": "decreasing"},
	{"q": "T", "name": "temperature of a reactor's coolant", "up": "rising", "down": "falling"},
	{"q": "L", "name": "water level in a tank", "up": "rising", "down": "falling"},
	{"q": "P", "name": "price of fuel", "up": "rising", "down": "falling"},
	{"q": "V", "name": "volume of water in a reservoir", "up": "increasing", "down": "decreasing"},
	{"q": "H", "name": "height of a weather balloon", "up": "rising", "down": "falling"},
	{"q": "A", "name": "amount of dust in the air", "up": "increasing", "down": "decreasing"},
	{"q": "R", "name": "radiation level in a crater", "up": "rising", "down": "falling"},
]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "sentence-from-signs")
	# The pair is picked first, mixed signs three times in four, and again every 500 tries.
	var pair: Array = []
	for i in TRIES:
		if i % 500 == 0:
			pair = rng.pick([[1, -1], [-1, 1], [1, -1], [-1, 1], [1, -1], [-1, 1], [1, 1], [-1, -1]])
		var s := _try(ask, pair, rng)
		if not s.is_empty():
			s.ask = ask
			s.paper = 1
			s.story = rng.int_in(0, STORIES.size() - 1)
			return s
	push_error("RateOfRateSituation: no clean situation for %s" % need)
	return {}


static func value(c: Array, x: Variant) -> Q:
	var v := Q.new(0)
	for k in c.size():
		v = v.mul(Q.of(x)).add(Q.new(c[k]))
	return v


static func d1(c: Array, x: Variant) -> Q:
	return value([3 * c[0], 2 * c[1], c[2]], x)


static func d2(c: Array, x: Variant) -> Q:
	return value([6 * c[0], 2 * c[1]], x)


static func _try(ask: String, pair: Array, rng: Seeded) -> Dictionary:
	if ask in ["sentence-from-signs", "signs-from-sentence"]:
		var t1 := rng.int_in(0, 4)
		var s := {"s1": pair[0], "s2": pair[1], "t1": t1, "t2": t1 + rng.int_in(2, 5)}
		if ask == "signs-from-sentence":
			s.rate_words = pair == [1, -1] and rng.chance(0.5)
		return s
	var c := [rng.pick([-1, 1]), rng.int_in(-9, 9), rng.int_in(-20, 20), rng.int_in(20, 80)]
	var t0 := rng.int_in(1, END - 1)
	var g1 := d1(c, t0)
	var g2 := d2(c, t0)
	if g1.sign() != pair[0] or g2.sign() != pair[1] or absf(g1.to_float()) < 2.0 or absf(g2.to_float()) < 2.0:
		return {}
	if c[1] == 0 or c[2] == 0:
		return {}
	# Clear of the point of inflexion and the turning points.
	var infl: float = -float(c[1]) / (3.0 * c[0])
	if absf(t0 - infl) < 1.0:
		return {}
	var A: float = 3.0 * c[0]
	var B: float = 2.0 * c[1]
	var disc: float = B * B - 4.0 * A * c[2]
	if disc >= 0.0:
		for r in [(-B - sqrt(disc)) / (2.0 * A), (-B + sqrt(disc)) / (2.0 * A)]:
			if absf(t0 - r) < 1.0:
				return {}
	# The quantity stays positive and readable for 0 ≤ t ≤ 6.
	for t in END + 1:
		var v := value(c, t).to_float()
		if v <= 0.0 or v > 150.0:
			return {}
	return {"s1": pair[0], "s2": pair[1], "c": c, "t0": t0}


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
