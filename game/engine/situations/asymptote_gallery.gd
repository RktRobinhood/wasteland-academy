class_name AsymptoteGallerySituation
extends RefCounted
## The `rational-asymptote-gallery` situation (curriculum/question-types.json): curves with
## asymptotes, side by side, for fn-concept-asymptote-meaning (FAL-423). Every example is
## built from its answer, so each claim about it can be checked by substituting numbers.
##
## generate() returns, by mode (need.mode):
##   lin     f(x) = A + B/(x − h) = (ax + b)/(x + d), A, h, B whole: a = A, d = −h, b = B − Ah.
##           It never meets y = A, because B/(x − h) is never 0
##   cross   a curve and whether it meets its horizontal asymptote: kind "bell" x/(x² + 1),
##           "decay" x·e^(−x), "shifted" A + x/(x² + 1) (all meet it at x = 0) or "lin" (never)
##   gap     (ax + b)/(cx + d) with ad = bc: m(cx + d)/(cx + d), which is m except at x = −d/c
##   model   a level that settles: P(t) = (Lt + P₀k)/(t + k) in a story, L the long-run level
##
## need: graph (cross: only the kinds that fit a plot).
## The clean limits are the checker's too (tools/check_answers.py, AG_*).

const TRIES := 500
const STORIES := [
	["the number of fish in a lake", " thousand fish", "years"],
	["the concentration of salt in a tank", " g per litre", "minutes"],
	["the speed of a rocket sled", " m/s", "seconds"],
]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var mode: String = need.get("mode", "lin")
	for i in TRIES:
		var s := _draw(rng, mode, need)
		if not s.is_empty():
			s.mode = mode
			s.paper = 1
			return s
	push_error("AsymptoteGallerySituation: no clean situation for %s" % need)
	return {}


static func _nonzero(rng: Seeded, lo: int, hi: int) -> int:
	var v := 0
	while v == 0:
		v = rng.int_in(lo, hi)
	return v


static func _draw(rng: Seeded, mode: String, need: Dictionary) -> Dictionary:
	var s := {}
	match mode:
		"lin":
			s.A = _nonzero(rng, -3, 3)
			s.h = _nonzero(rng, -4, 4)
			s.B = _nonzero(rng, -4, 4)
			s.a = s.A
			s.d = -s.h
			s.b = s.B - s.A * s.h
			if s.b == 0:
				return {}
		"cross":
			var kinds := ["bell", "shifted", "lin"] if need.get("graph", false) else ["bell", "decay", "shifted", "lin"]
			s.kind = kinds[rng.int_in(0, kinds.size() - 1)]
			s.A = 0
			if s.kind == "shifted":
				s.A = _nonzero(rng, -3, 3)
			if s.kind == "lin":
				var t := _draw(rng, "lin", need)
				if t.is_empty():
					return {}
				s.merge(t, true)
		"gap":
			s.c = rng.int_in(1, 2)
			s.d = _nonzero(rng, -5, 5)
			s.m = _nonzero(rng, -4, 4)
			if absi(s.m) < 2 or s.c * s.m == 0:
				return {}
			s.a = s.m * s.c
			s.b = s.m * s.d
			s.h = Q.new(-s.d, s.c)
		"model":
			var st: Array = STORIES[rng.int_in(0, STORIES.size() - 1)]
			s.story = st
			s.L = [400, 600, 800, 1000][rng.int_in(0, 3)]
			s.P0 = [100, 200, 300][rng.int_in(0, 2)]
			s.k = [2, 4, 5][rng.int_in(0, 2)]
	return s


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
