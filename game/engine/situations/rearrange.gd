class_name RearrangeSituation
extends RefCounted
## The `fn-pre-rearrange` situation (curriculum/question-types.json): change the subject
## of a formula (FAL-422), the prior learning that finding an inverse rests on.
##
## generate() returns, by mode (need.mode):
##   one       a formula from FORMULAS (v = u + at, d = st, ...) and the letter to isolate
##   two       y = a·x + b
##   power     y = x² + c (c a perfect square, so a term-by-term root is a believable slip) or
##             y = √(x + c)
##   denom     y = a/(x − b)
##   twice     y = (a·x + b)/(c·x + d), with x in the top and the bottom
##   twicelin  k·x + p = q·x + m, with x on both sides
##   original  a formula from two, denom or twice, shown as its rearrangement (which-original)
##
## The clean limits are the checker's too (tools/check_answers.py, RA_*).

const TRIES := 1000
## [formula, subject, rearranged, words]
const FORMULAS := [
	["v = u + at", "u", "u = v − at", "The speed v is the starting speed u plus the acceleration a times the time t."],
	["d = st", "s", "s = d/t", "The distance d is the speed s times the time t."],
	["F = ma", "m", "m = F/a", "The force F is the mass m times the acceleration a."],
	["A = lw", "l", "l = A/w", "The area A is the length l times the width w."],
	["y = x + 5", "x", "x = y − 5", "y is x plus 5."],
	["C = πd", "d", "d = C/π", "The circumference C is π times the diameter d."],
]


static func pick(rng: Seeded, xs: Array) -> Variant:
	return xs[rng.int_in(0, xs.size() - 1)]


static func nonzero(rng: Seeded, lo: int, hi: int) -> int:
	var v := 0
	while v == 0:
		v = rng.int_in(lo, hi)
	return v


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var mode: String = need.get("mode", "two")
	for i in TRIES:
		var s := _draw(rng, mode)
		if not s.is_empty():
			s.mode = mode
			return s
	push_error("RearrangeSituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, mode: String) -> Dictionary:
	var s := {}
	match mode:
		"one":
			s.i = rng.int_in(0, FORMULAS.size() - 1)
		"two":
			s.a = pick(rng, [2, 3, 4, 5, -2, -3])
			s.b = nonzero(rng, -8, 8)
		"power":
			s.kind = "sq" if rng.chance(0.6) else "root"
			s.c = pick(rng, [1, 4, 9, 16]) if s.kind == "sq" else nonzero(rng, -6, 6)
			if s.kind == "sq" and rng.chance(0.4):
				s.c = -s.c
		"denom":
			s.a = pick(rng, [2, 3, 4, 5, 6, -2, -3])
			s.b = nonzero(rng, -5, 5)
		"twice":
			var c: int = pick(rng, [1, 1, -1, 2])
			s.a = nonzero(rng, -3, 3)
			s.b = rng.int_in(-5, 5)
			s.c = c
			s.d = nonzero(rng, -4, 4)
			if s.a * s.d - s.b * c == 0:
				return {}
		"twicelin":
			s.p = nonzero(rng, -5, 5)
			s.n = pick(rng, [1, 2, 3, 4, 5])
		"original":
			s.src = pick(rng, ["two", "denom", "twice"])
			s.inner = _draw(rng, s.src)
			if s.inner.is_empty():
				return {}
	return s


## The original formula of a two, denom or twice rule, as the game writes it.
static func formula_text(src: String, s: Dictionary) -> String:
	match src:
		"two":
			return "y = %s" % Fmt.poly([s.a, s.b])
		"denom":
			return "y = %s/(%s)" % [Fmt.num(s.a), Fmt.poly([1, -s.b])]
		"twice":
			return "y = %s" % InverseRuleSituation.frac(Fmt.poly([s.a, s.b]), Fmt.poly([s.c, s.d]))
		"power":
			return "y = x² %s" % Fmt.plus(s.c) if s.kind == "sq" else "y = √(%s)" % Fmt.poly([1, s.c])
	return "?"


## x = … as the game writes it (the right answer for each mode).
static func solved_text(src: String, s: Dictionary) -> String:
	match src:
		"two":
			return "x = %s" % _over(Fmt.poly([1, -s.b]).replace("x", "y"), s.a)
		"denom":
			return "x = %s/y%s" % [Fmt.num(s.a), Fmt.plus(s.b)]
		"twice":
			return "x = %s" % InverseRuleSituation.frac(Fmt.poly([s.d, -s.b]).replace("x", "y"), Fmt.poly([-s.c, s.a]).replace("x", "y"))
	return "?"


## "(y + 5)/3", "−(y + 5)/3" kept simple: a bracketed top over the divisor, or the top alone.
static func _over(top: String, a: int) -> String:
	var t := top if not top.contains(" ") else "(%s)" % top
	if a == 1:
		return top
	if a == -1:
		return "−" + t
	return "%s/%s" % [t, Fmt.num(a)] if a > 0 else "−%s/%s" % [t, Fmt.num(-a)]


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
