class_name LinkGrowthSituation
extends RefCounted
## The `fn-link-multiplicative-growth` situation (curriculum/question-types.json): one
## multiplicative change seen as a sequence, a function and a series (FAL-418).
## Values a calculator gives are to 3 s.f.
##
## generate() returns:
##   P0, r, up, f    a start value, a yearly rate of r% (up: a rise) and its factor f (a Q)
##   n               a number of years
##   T, nb           a threshold below P0 and the first whole year nb with P0·f^m < T
##                   (a decay); nx the exact crossing
##   t1, t2, V1, V2  two exact readings V = P0·f^t (factor from two values)
##   k, R, N         compounding k times a year at R% a year, for N years
##   kc              a continuous rate e^(kc·t) (a Q)
##   q               a series ratio (a Q), some with |q| ≥ 1
##
## The clean limits are the checker's too (tools/check_answers.py, LG_*).

const STARTS := [1000, 2000, 5000, 8000, 12000, 20000]
const RATES := [2, 4, 5, 8, 10, 12, 15, 20, 25]
const RATIOS := [[1, 2], [-1, 2], [1, 3], [-2, 3], [3, 4], [-2, 1], [1, 1], [-1, 1], [101, 100], [3, 2], [-3, 2]]
const TRIES := 2000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	# The stream's first draw leans low, so it is spent first (as the quadratic recipes do).
	rng.int_in(0, 1)
	for i in TRIES:
		var s := {"P0": Q.new(STARTS[rng.int_in(0, STARTS.size() - 1)]), "r": RATES[rng.int_in(0, RATES.size() - 1)]}
		s.up = rng.chance(0.5) and not need.get("decay", false)
		s.f = Q.new(100 + (s.r if s.up else -s.r), 100)
		s.n = rng.int_in(3, 12)
		var val: Variant = s.P0.to_float() * pow(s.f.to_float(), s.n)
		if not ExpModelSituation.rounds_clear(val) or not ExpModelSituation.rounds_clear(s.P0.to_float() * pow(s.f.to_float(), s.n - 1)):
			continue
		# A threshold for a decay, crossed between whole years.
		var fd := Q.new(100 - s.r, 100).to_float()
		s.T = Q.new(roundi(s.P0.to_float() * rng.int_in(20, 70) / 100.0))
		s.nx = log(s.T.to_float() / s.P0.to_float()) / log(fd)
		s.nb = ceili(s.nx)
		if s.nx - floorf(s.nx) < 0.1 or s.nx - floorf(s.nx) > 0.9 or s.nb > 40:
			continue
		s.t1 = rng.int_in(0, 2)
		s.t2 = s.t1 + rng.int_in(1, 3)
		s.V1 = s.P0.mul(ExpModelSituation.pow_q(s.f, s.t1))
		s.V2 = s.P0.mul(ExpModelSituation.pow_q(s.f, s.t2))
		if 100000000 % s.V2.d != 0 or 100000000 % s.V1.d != 0:
			continue
		s.k = [2, 4, 12][rng.int_in(0, 2)]
		s.R = [2, 3, 4, 5, 6, 8][rng.int_in(0, 5)]
		s.N = rng.int_in(2, 10)
		var fv: Variant = s.P0.to_float() * pow(1.0 + s.R / (100.0 * s.k), s.k * s.N)
		if not ExpModelSituation.rounds_clear(fv) or not ExpModelSituation.rounds_clear(s.P0.to_float() * pow(1.0 + s.R / 100.0, s.k * s.N)):
			continue
		s.kc = Q.new(rng.int_in(2, 15) * (1 if rng.chance(0.6) else -1), 100)
		if not ExpModelSituation.rounds_clear(exp(s.kc.to_float())) or not ExpModelSituation.rounds_clear(absf(exp(s.kc.to_float()) - 1.0) * 100.0):
			continue
		var qq: Array = RATIOS[rng.int_in(0, RATIOS.size() - 1)]
		s.q = Q.new(qq[0], qq[1])
		return s
	return {}


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
