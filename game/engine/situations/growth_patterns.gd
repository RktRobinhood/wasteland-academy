class_name GrowthPatternsSituation
extends RefCounted
## The `exp-growth-vs-linear` situation (curriculum/question-types.json), which extends
## `exp-model`: the growth-factor model next to a linear one, so the two patterns can be
## compared (FAL-418). The start values are exp-model's (ExpModelSituation.STARTS
## for the exponential), with a whole growth factor or a round percentage.
##
## generate() returns:
##   P0, a   the exponential E(t) = P0·a^t (a a Q: 2, 3/2, 6/5, 5/4, 11/10)
##   Q0, d   the linear L(t) = Q0 + d·t, starting higher (Q0 > P0) and adding d each step
##   kind    which pattern a single table, description or graph shows: "lin", "exp" or
##           "neither" (a quadratic: neither differences nor ratios constant)
##   n       the first whole step with E(n) > L(n) for good; nneg the crossing before the
##           start (a float), the one a model used outside its domain gives
##   r       the exponential's percentage (a − 1)·100
##
## The clean limits are the checker's too (tools/check_answers.py, GP_*).

const FACTORS := [[2, 1], [3, 2], [6, 5], [5, 4], [11, 10]]
const STARTS := [100, 200, 400, 500, 800, 1000]
const TRIES := 2000


static func generate(rng: Seeded, _need: Dictionary = {}) -> Dictionary:
	# The stream's first draw leans low, so it is spent first (as the quadratic recipes do).
	rng.int_in(0, 1)
	for i in TRIES:
		var f: Array = FACTORS[rng.int_in(0, FACTORS.size() - 1)]
		var s := {"P0": Q.new(STARTS[rng.int_in(0, STARTS.size() - 1)]), "a": Q.new(f[0], f[1])}
		s.r = s.a.sub(Q.new(1)).mul(Q.new(100))
		s.Q0 = s.P0.mul(Q.new(rng.int_in(2, 4)))
		s.d = Q.new(roundi(s.P0.to_float() * rng.int_in(1, 6) / 10.0))
		if s.d.is_zero():
			continue
		s.kind = ["lin", "exp", "neither"][rng.int_in(0, 2)]
		# The crossing ahead: E passes L for good at the first whole n past it.
		var n := 0
		while n < 60 and not (E(s, n) > L(s, n) and E(s, n + 1) > L(s, n + 1)):
			n += 1
		if n < 3 or n > 25:
			continue
		s.n = n
		s.nneg = _cross_below(s)
		if is_nan(s.nneg) or absf(s.nneg - roundf(s.nneg)) < 0.1:
			continue
		# The exponential's table values stay whole for 4 steps.
		var ok := true
		for t in 5:
			if not s.P0.mul(pow_q(s.a, t)).is_int():
				ok = false
		if ok:
			return s
	return {}


static func E(s: Dictionary, t: float) -> float:
	return s.P0.to_float() * pow(s.a.to_float(), t)


static func L(s: Dictionary, t: float) -> float:
	return s.Q0.to_float() + s.d.to_float() * t


## The crossing of E and L at negative t (L is below E far to the left), or NAN.
static func _cross_below(s: Dictionary) -> float:
	var lo := -200.0
	var hi := 0.0
	if not (E(s, lo) > L(s, lo) and E(s, hi) < L(s, hi)):
		return NAN
	for i in 80:
		var mid := (lo + hi) / 2.0
		if E(s, mid) > L(s, mid):
			lo = mid
		else:
			hi = mid
	return (lo + hi) / 2.0


static func pow_q(a: Q, n: int) -> Q:
	var out := Q.new(1)
	for i in n:
		out = out.mul(a)
	return out


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
