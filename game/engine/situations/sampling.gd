class_name SamplingSituation
extends RefCounted
## The `sampling` situation (curriculum/question-types.json): a population in named groups, and a
## surveyor who takes a sample from it (FAL-726). Everything is whole: k is the interval N ÷ n,
## and each group is k times its share of the sample, so a sample in proportion needs no
## rounding. Paper 2 has the same shape with larger numbers.
##
## need.ask is the unknown (see SamplingViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx (an index into SamplingViews.CONTEXTS)
##   n, k, N       the sample, the interval and the population, N = n k
##   q, G          each group's share of the sample and its size, G[i] = k q[i]
##   tech          the technique: "simple", "systematic", "convenience", "quota" or "stratified"
##   pct           the sample as a percentage of N where that is whole, else 0
##   g             the group a question is about, an index into q
##   start, j      systematic-member: the first number chosen, and which pick is asked
##   got           the sample's own numbers from each group, where they differ from q
##   story         bias-direction and source-reliability: an index into their lists
##   rate          source-reliability: the percentage claimed
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 4000
const CONTEXTS := 8
const STORIES := 8
const SOURCES := 6
const TECHS := ["simple", "systematic", "convenience", "quota", "stratified"]
const GOALS := ["simple", "systematic", "quota", "stratified"]
const RANDOM_TECHS := ["simple", "systematic", "convenience"]
const SIZES_1 := [10, 12, 15, 16, 18, 20, 24, 25, 30, 40]
const SIZES_2 := [40, 50, 60, 75, 80, 100, 120, 150]
const STEPS_1 := [4, 5, 6, 8, 10, 12, 15, 20]
const STEPS_2 := [6, 8, 10, 12, 15, 20, 25, 30, 40]
const SMALL := [5, 8, 10, 12]
## The questions on three groups.
const THREE := ["quota-number", "fair-share", "under-represented"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "name-technique")
	for i in TRIES:
		var s := {"paper": int(need.get("paper", 1)), "ask": ask, "rep": need.get("rep", "words"), "ctx": rng.int_in(0, CONTEXTS - 1),
			"tech": rng.pick(TECHS), "g": 0, "start": 0, "j": 0, "got": [], "story": 0, "rate": 0}
		if camp(rng, s, 3 if ask in THREE else 2) and _ask_clear(rng, s):
			return s
	return {}


## Draws the groups: q adds to n, and each group is k times its q.
static func camp(rng: Seeded, s: Dictionary, groups: int) -> bool:
	var n: int = rng.pick(SIZES_1 if s.paper == 1 else SIZES_2)
	var k: int = rng.pick(STEPS_1 if s.paper == 1 else STEPS_2)
	var q: Array = []
	var left := n
	for i in groups - 1:
		var share := rng.int_in(2, left - 2 * (groups - 1 - i))
		q.append(share)
		left -= share
	q.append(left)
	s.n = n
	s.k = k
	s.N = n * k
	s.q = q
	s.G = q.map(func(x): return x * k)
	s.pct = roundi(100.0 / k) if 100 % k == 0 else 0
	# Groups of one size give nothing away, and a question can tell them apart.
	for i in groups:
		for j in i:
			if q[i] == q[j]:
				return false
	return left >= 2 and n != k


static func _ask_clear(rng: Seeded, s: Dictionary) -> bool:
	var n: int = s.n
	match s.ask:
		"best-technique":
			s.tech = rng.pick(GOALS)
		"is-it-random":
			s.tech = rng.pick(RANDOM_TECHS)
		"systematic-member":
			s.start = rng.int_in(2, s.k)
			s.j = rng.int_in(3, mini(n, 9))
		"quota-number":
			s.g = rng.int_in(0, 2)
			s.tech = "quota" if rng.chance(0.5) else "stratified"
		"fair-share":
			# One group falls short; the rest of the sample is shared among the others.
			s.g = rng.int_in(0, 2)
			var short := rng.int_in(1, s.q[s.g] - 1)
			var got: Array = s.q.duplicate()
			got[s.g] -= short
			got[(s.g + 1) % 3] += short
			s.got = got
		"under-represented":
			return _uneven(rng, s)
		"random-not-perfect":
			s.g = rng.int_in(0, 1)
			var off := rng.int_in(2, maxi(2, n / 8))
			if s.q[s.g] - off < 1:
				return false
			s.got = [s.q[0] - off, s.q[1] + off] if s.g == 0 else [s.q[0] + off, s.q[1] - off]
		"improve-reliability":
			s.n = rng.pick(SMALL)
			s.k = 0
		"bias-direction":
			s.story = rng.int_in(0, STORIES - 1)
		"source-reliability":
			s.story = rng.int_in(0, SOURCES - 1)
			s.rate = rng.int_in(14, 19) * 5
	return true


## got: the numbers a sample really holds. One group falls short of its share by more than any
## other, and by more as a share of itself, and it isn't the group with the fewest in the sample,
## so comparing the raw counts points at the wrong group.
static func _uneven(rng: Seeded, s: Dictionary) -> bool:
	var q: Array = s.q
	var got: Array = []
	var total := 0
	for i in 3:
		var v: int = maxi(1, q[i] + rng.int_in(-q[i] / 2, q[i] / 2))
		got.append(v)
		total += v
	if total != s.n:
		return false
	var worst := 0
	for i in 3:
		if float(got[i]) / q[i] < float(got[worst]) / q[worst]:
			worst = i
	for i in 3:
		if i == worst:
			continue
		if q[i] - got[i] >= q[worst] - got[worst] or float(got[i]) / q[i] <= float(got[worst]) / q[worst] + 0.1:
			return false
	if got.min() == got[worst] or got.count(got.min()) > 1 or got == q:
		return false
	s.g = worst
	s.got = got
	return true


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
