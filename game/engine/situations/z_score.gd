class_name ZScoreSituation
extends RefCounted
## The `z-score` situation (curriculum/question-types.json): a value in a normal distribution and
## its z-value, for t4-ext-z-scores (FAL-777).
##
## generate() returns ask, paper and:
##   z-from-x, x-from-z, interpret-z   ctx (an index into CONTEXTS), mu, sg, z (a Q, a nonzero
##                                     multiple of 0.5), x = μ + zσ
##   compare-scores, compare-times     ctx (an index into NAMES), and two values, each in its own
##                                     distribution: mu1, sg1, x1, z1 (the better one) and mu2,
##                                     sg2, x2, z2. The better one has the worse raw value and is
##                                     nearer its mean, so both slips pick the other; swap
##                                     says which of the two is written first. Paper 2.
##
## σ is one of SIGMAS, so a slip that divides by σ² still gives a decimal that ends. A comparison
## asked by the proportion below (Paper 2) is fair to 3 s.f. The checker holds its own copy of
## these limits (E14ZS_*).

const TRIES := 6000
const SIGMAS := [2, 4, 5, 8, 10, 16, 20]
## What is measured, the range of its mean, and how a question names one value.
const CONTEXTS := [
	{"what": "The marks in a test", "unit": " marks", "lo": 40, "hi": 70, "subj": "The mark", "one": "a mark", "noun": "mark", "sg_max": 10},
	{"what": "The masses of melons from a farm", "unit": " g", "lo": 400, "hi": 900, "subj": "The melon's mass", "one": "a melon's mass", "noun": "mass", "sg_max": 20},
	{"what": "The heights of adult cactus plants", "unit": " cm", "lo": 100, "hi": 200, "subj": "The cactus's height", "one": "a cactus's height", "noun": "height", "sg_max": 20},
	{"what": "The lengths of steel rods from a forge", "unit": " mm", "lo": 300, "hi": 800, "subj": "The rod's length", "one": "a rod's length", "noun": "length", "sg_max": 20},
]
## The people in a comparison, and what is compared: two subjects, or two groups in one race.
const NAMES := [
	{"a": "Ana", "b": "Kofi", "s1": "biology", "s2": "chemistry", "g1": "the under-16s", "g2": "the under-18s"},
	{"a": "Priya", "b": "Tomas", "s1": "history", "s2": "physics", "g1": "the junior group", "g2": "the senior group"},
	{"a": "Lena", "b": "Omar", "s1": "French", "s2": "geography", "g1": "club A", "g2": "club B"},
	{"a": "Mei", "b": "Joel", "s1": "art", "s2": "economics", "g1": "the morning heat", "g2": "the evening heat"},
]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "z-from-x")
	for i in TRIES:
		var s := _try(ask, rng)
		if not s.is_empty():
			s.ask = ask
			return s
	push_error("ZScoreSituation: no clean situation for %s" % need)
	return {}


## A nonzero multiple of 0.5 from −m to m.
static func half_steps(rng: Seeded, m: int) -> Q:
	var k := 0
	while k == 0:
		k = rng.int_in(-2 * m, 2 * m)
	return Q.new(k, 2)


static func _try(ask: String, rng: Seeded) -> Dictionary:
	match ask:
		"z-from-x", "x-from-z", "interpret-z":
			var ctx := rng.int_in(0, CONTEXTS.size() - 1)
			var c: Dictionary = CONTEXTS[ctx]
			var sg: int = rng.pick(SIGMAS.filter(func(v): return v <= c.sg_max))
			var z := half_steps(rng, 3 if ask != "interpret-z" else 2)
			# Two in three interpretations are below the mean, where the sign is the point.
			if ask == "interpret-z" and z.sign() > 0 and rng.chance(0.6):
				z = z.neg()
			var mu := rng.int_in(c.lo, c.hi)
			var x: Q = z.mul(Q.new(sg)).add(Q.new(mu))
			if not x.is_int():
				return {}
			return {"paper": 1, "ctx": ctx, "mu": mu, "sg": sg, "z": z, "x": x}
		"compare-scores", "compare-times":
			var times := ask == "compare-times"
			# Paper 2: the proportion below each value is a method, and it needs normalcdf.
			var s := {"paper": 2, "ctx": rng.int_in(0, NAMES.size() - 1), "swap": rng.chance(0.5)}
			# Scores: marks out of 100, both above the mean. Times: seconds for a 400 m, both
			# below the mean, where lower is better.
			var lo := 50 if times else 45
			var hi := 75 if times else 70
			for k in [1, 2]:
				var sg: int = rng.int_in(2, 10)
				var z := Q.new(rng.int_in(2, 10), 4)
				if times:
					z = z.neg()
				var mu := rng.int_in(lo, hi)
				var x: Q = z.mul(Q.new(sg)).add(Q.new(mu))
				if not x.is_int():
					return {}
				s["mu%d" % k] = mu
				s["sg%d" % k] = sg
				s["z%d" % k] = z
				s["x%d" % k] = x
			var z1: Q = s.z1
			var z2: Q = s.z2
			var d1: Q = s.x1.sub(Q.new(s.mu1)).abs_q()
			var d2: Q = s.x2.sub(Q.new(s.mu2)).abs_q()
			# 1 is the better: further out in z, but worse raw and nearer its mean.
			var better := z1.abs_q().sub(z2.abs_q())
			if better.lt(Q.new(1, 4)):
				return {}
			var raw_worse: bool = s.x1.lt(s.x2) if not times else s.x2.lt(s.x1)
			if not raw_worse or not d1.lt(d2) or s.mu1 == s.mu2:
				return {}
			if not (GdcKit.fair(100.0 * phi(z1.to_float())) and GdcKit.fair(100.0 * phi(z2.to_float()))):
				return {}
			return s
	return {}


static func phi(z: float) -> float:
	return NormalUnknownSituation.phi(z)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
