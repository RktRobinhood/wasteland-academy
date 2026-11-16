class_name HistogramSituation
extends RefCounted
## The `histogram` situation (curriculum/question-types.json): a measured variable in 4 to 6 classes
## of equal width w, a ≤ x < a + w from 0, with their frequencies, for t4-ext-frequency-histogram
## (FAL-778). The stories are HistogramViews.STORIES.
##
## generate() returns ask, paper, story, w, k (the number of classes), f (the frequencies), T (their
## total) and, by unknown, i (the class asked about, or the hidden one) and j (the class a range or
## a boundary ends at: the boundary is j w).

const TRIES := 2000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "missing-frequency")
	for t in TRIES:
		var story: int = rng.int_in(0, HistogramViews.STORIES.size() - 1)
		var k := rng.int_in(4, 6)
		var s := {"ask": ask, "paper": int(need.get("paper", 1)), "story": story, "w": rng.pick(HistogramViews.STORIES[story].w), "k": k, "f": [], "i": 0, "j": 0}
		var ok := true
		for c in k:
			var f := rng.int_in(2, 24)
			if c > 0 and f == s.f[c - 1]:
				ok = false
			s.f.append(f)
		if not ok:
			continue
		s.T = s.f.reduce(func(a, b): return a + b)
		match ask:
			"missing-frequency", "bar-height":
				s.i = rng.int_in(1, k - 1) if ask == "bar-height" else rng.int_in(0, k - 1)
			"count-in-range":
				s.i = rng.int_in(1, k - 2)
				s.j = mini(k, s.i + rng.int_in(2, 3))
			"count-at-least":
				s.j = rng.int_in(1, k - 2)
			"class-of-value":
				s.j = rng.int_in(1, k - 1)
			"pick-histogram":
				s.i = rng.int_in(0, k - 2)
		# A bar's height over its width must not be another option's value.
		if ask == "bar-height" and (s.f[s.i] % s.w == 0 or _cum(s, s.i) == s.f[s.i]):
			continue
		return s
	push_error("HistogramSituation: no clean situation for %s" % need)
	return {}


## The frequencies of classes 0 to i added: the running total to the end of class i.
static func _cum(s: Dictionary, i: int) -> int:
	var t := 0
	for c in i + 1:
		t += s.f[c]
	return t


## The frequencies of classes lo to hi − 1 added.
static func total(s: Dictionary, lo: int, hi: int) -> int:
	var t := 0
	for c in range(lo, hi):
		t += s.f[c]
	return t


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
