class_name AlgebraicFractionSituation
extends RefCounted
## The `fn-pre-algebraic-fractions` situation (curriculum/question-types.json): fractions
## with x in them, the prior learning rational functions rest on (FAL-423). Every answer is
## built first and the fraction or equation from it, so the numbers stay clean and a solution
## is never an excluded value.
##
## generate() returns, by mode (need.mode):
##   excluded  (px + q)/(cx + d): p, q, c (1 or 2), d, h = −d/c (the value x can't take)
##   simplify  kind "factor" (x + p)(x + q)/(x + p) = x + q, kind "scale" (mx + ma)/(x + a) = m,
##             or kind "none" (x + a)/(x + b), which doesn't simplify: p, q (factor), m, a
##             (scale) or a, b (none)
##   add       p/(x + a) + q/(x + b) = ((p + q)x + (pb + qa))/((x + a)(x + b)): p, q, a, b
##   clear     a + k/(x − h) = c, with x = h + t whole: a, k, h, c, t, x
##   missing   a + k/(x − h) = (□)/(x − h): a, k, h
## The clean limits are the checker's too (tools/check_answers.py, AF_*).

const TRIES := 1000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var mode: String = need.get("mode", "excluded")
	for i in TRIES:
		var s := _draw(rng, mode)
		if not s.is_empty():
			s.mode = mode
			s.paper = 1
			return s
	push_error("AlgebraicFractionSituation: no clean situation for %s" % need)
	return {}


static func _nonzero(rng: Seeded, lo: int, hi: int) -> int:
	var v := 0
	while v == 0:
		v = rng.int_in(lo, hi)
	return v


static func _draw(rng: Seeded, mode: String) -> Dictionary:
	var s := {}
	match mode:
		"excluded":
			s.p = _nonzero(rng, -3, 3)
			s.q = _nonzero(rng, -9, 9)
			s.c = 1 if rng.chance(0.7) else 2
			s.d = _nonzero(rng, -7, 7)
			s.h = Q.new(-s.d, s.c)
			if s.p * s.d == s.q * s.c:
				return {}
		"simplify":
			var r := rng.int_in(0, 9)
			s.kind = "factor" if r < 4 else ("scale" if r < 7 else "none")
			match s.kind:
				"factor":
					s.p = _nonzero(rng, -6, 6)
					s.q = _nonzero(rng, -6, 6)
					if s.p == s.q or s.p + s.q == 0:
						return {}
				"scale":
					s.m = rng.int_in(2, 5)
					s.a = _nonzero(rng, -6, 6)
				_:
					s.a = _nonzero(rng, -6, 6)
					s.b = _nonzero(rng, -6, 6)
					if s.a == s.b or s.a + s.b == 0:
						return {}
		"add":
			s.p = _nonzero(rng, -4, 4)
			s.q = _nonzero(rng, -4, 4)
			s.a = _nonzero(rng, -4, 4)
			s.b = _nonzero(rng, -4, 4)
			if s.a == s.b or s.p + s.q == 0 or s.p * s.b + s.q * s.a == 0:
				return {}
		"clear":
			s.h = _nonzero(rng, -5, 5)
			s.t = [-3, -2, -1, 1, 2, 3, 4][rng.int_in(0, 6)]
			var m := _nonzero(rng, -4, 4)
			s.k = s.t * m
			s.a = _nonzero(rng, -5, 5)
			s.c = s.a + m
			s.x = s.h + s.t
			# The slip multiplies only the fraction term: (k + a)/c should be another x.
			if s.c == 0 or s.x == 0 or Q.new(s.k + s.a, s.c).eq(Q.new(s.t)):
				return {}
		"missing":
			s.a = _nonzero(rng, -5, 5)
			s.k = _nonzero(rng, -9, 9)
			s.h = _nonzero(rng, -5, 5)
			if s.k - s.a * s.h == 0:
				return {}
	return s


## "x + 2", "x − 3", "2x + 1".
static func lin(c: int, d: int) -> String:
	return Fmt.poly([c, d])


## The text of one of the fractions, in brackets where it has two terms.
static func over(top: String, bottom: String) -> String:
	return "%s/%s" % [top if not " " in top else "(%s)" % top, bottom if not " " in bottom else "(%s)" % bottom]


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
