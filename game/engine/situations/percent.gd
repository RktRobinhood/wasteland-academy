class_name PercentSituation
extends RefCounted
## The `fn-pre-percent-multiplier` situation (curriculum/question-types.json): a
## percentage change as one multiplier (FAL-418). Prior learning for the Exponentials
## and logs region: amounts and multipliers are exact.
##
## generate() returns:
##   P        the amount before (a whole number)
##   r, up    the change: r% (a whole number), a rise when up
##   m        the multiplier 1 ± r/100 (a Q)
##   A        P·m, the amount after (whole or to the cent)
##   r2, up2, m2   a second change in a row (repeated changes), M = m·m2
##   mm       a multiplier with three figures after the point, for reading back (0.92, 1.035)
##
## The clean limits are the checker's too (tools/check_answers.py, PC_*).

const RATES := [5, 8, 10, 12, 15, 20, 25, 30, 35, 40]
const AMOUNTS := [80, 120, 160, 200, 240, 300, 360, 400, 500, 640, 800, 1200, 1500, 2000]
const TRIES := 500


static func generate(rng: Seeded, _need: Dictionary = {}) -> Dictionary:
	for i in TRIES:
		var s := {}
		s.P = Q.new(AMOUNTS[rng.int_in(0, AMOUNTS.size() - 1)])
		s.r = RATES[rng.int_in(0, RATES.size() - 1)]
		s.up = rng.chance(0.5)
		s.m = mult(s.r, s.up)
		s.A = s.P.mul(s.m)
		# The amount after is whole or to the cent, so it can be read off exactly.
		if 100 % s.A.d != 0:
			continue
		s.r2 = RATES[rng.int_in(0, RATES.size() - 1)]
		s.up2 = not s.up if rng.chance(0.6) else s.up
		s.m2 = mult(s.r2, s.up2)
		var t := rng.int_in(1, 99)
		s.mm = Q.new(1000 + (t * 5 if rng.chance(0.5) else -t * 5), 1000)
		return s
	return {}


static func mult(r: int, up: bool) -> Q:
	return Q.new(100 + (r if up else -r), 100)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
