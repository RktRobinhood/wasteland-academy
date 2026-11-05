class_name NormalProbabilitySituation
extends RefCounted
## The `normal-probability` situation (curriculum/question-types.json): X is normal with μ and σ
## known, and a region of it is asked for (FAL-728). It is a thin layer on `normal-unknown`:
## phi, inv and clear come from NormalUnknownSituation, the stories and the curve from
## NormalUnknownViews, so there is one normal distribution in the engine. The checker finds the
## areas again with mpmath.
##
## need.ask is the unknown:
##   prob-below, prob-above, prob-between   kind "lt", "gt" or "in"
##   percentage-in-range    form "percentage" or "proportion", kind "lt", "gt" or "in"
##   expected-number        n and a region
##   outside-interval       kind "out": below lo or above hi
##   rejected-rule          kind "lt", "gt" or "out": the rejected region
##   expected-rejected      n and a rejected region
##   exactly-in-sample      n, k and a region: P(exactly k of the n fall in it), with the area
##                          as a binomial's p; pmf is that, cum is P(at most k), flip is the
##                          same with the region left out (absent where it reads as nothing)
##   negative-lower-tail    neg true: a temperature or a change, P(X < hi) with hi > 0 and a
##                          real area below 0
##   variance-given         variance: X ~ N(μ, σ²) written with σ² (sg is missing where σ² isn't
##                          a square); kind "lt", "gt" or "in"
##   recorded-value         v to the nearest u: lo = v − h, hi = v + h, kind "in"
##   between-from-tails     mu and sg hidden: x1, p1, x2, p2 give P(x1 < X < x2) = mid, exact
##
## generate() returns a Dictionary:
##   paper  2;  ask;  ctx  the story (NormalProbabilityViews)
##   mu, sg  Q;  muf, sgf  the same as floats
##   lo, hi  the region's bounds, Q or absent for an open end;  kind
##   zlo, zhi  their z-values;  p  the area of the region;  and what each slip needs.
##
## _fill's z_min keeps a bound off μ; a recorded value passes −1, as it may sit on the mean.

const TRIES := 6000
const NEG_CONTEXTS := 3
const Z_MAX := 2.3
const P_MIN := 0.005
## A slip's area below this reads as absurd.
const SLIP_MIN := 0.001
const SAMPLES := [50, 80, 100, 120, 150, 200, 250, 300, 400, 500, 800, 1000]
## Samples small enough that "exactly k" has a real chance.
const SMALL_SAMPLES := [10, 12, 15, 20, 25, 30, 40, 50, 60, 80, 100]
## A band this many σ wide, so its two labels can sit in a row on the curve.
const BAND_MIN := 1.0
const PMF_MIN := 0.02


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "prob-below")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "ctx": rng.int_in(0, NormalUnknownSituation.CONTEXTS - 1)}
		var ok := false
		match ask:
			"prob-below":
				ok = _region(rng, s, "lt")
			"prob-above":
				ok = _region(rng, s, "gt")
			"prob-between":
				ok = _region(rng, s, "in")
			"percentage-in-range":
				s.form = rng.pick(["percentage", "proportion"])
				ok = _region(rng, s, rng.pick(["lt", "gt", "in"]))
			"expected-number":
				ok = _region(rng, s, rng.pick(["lt", "gt", "in"])) and _sample(rng, s)
			"outside-interval":
				ok = _region(rng, s, "out")
			"rejected-rule":
				ok = _region(rng, s, rng.pick(["lt", "gt", "out", "out"]))
			"expected-rejected":
				ok = _region(rng, s, rng.pick(["lt", "gt", "out", "out"])) and _sample(rng, s)
			"exactly-in-sample":
				ok = _region(rng, s, rng.pick(["lt", "gt", "in"])) and _exactly(rng, s)
			"negative-lower-tail":
				ok = _negative(rng, s)
			"variance-given":
				ok = _variance(rng, s)
			"recorded-value":
				ok = _recorded(rng, s)
			"between-from-tails":
				ok = _tails(rng, s)
		if ok:
			return s
	return {}


static func phi(z: float) -> float:
	return NormalUnknownSituation.phi(z)


static func clear(x: float) -> bool:
	return NormalUnknownSituation.clear(x)


## μ and σ, whole or to 1 d.p. σ is at most a quarter of μ, so the measures stay positive.
static func _params(rng: Seeded, s: Dictionary) -> bool:
	s.mu = Q.new(rng.int_in(200, 4000), 10) if rng.chance(0.4) else Q.new(rng.int_in(20, 400))
	s.sg = Q.new(rng.int_in(12, 400), 10) if rng.chance(0.4) else Q.new(rng.int_in(2, 40))
	_floats(s)
	return s.sgf <= s.muf / 4.0


static func _floats(s: Dictionary) -> void:
	s.muf = s.mu.to_float()
	if s.has("sg"):
		s.sgf = s.sg.to_float()


## A value z standard deviations from μ, for z from z0 to z1, whole unless σ is small.
static func _cut(rng: Seeded, s: Dictionary, z0: float, z1: float) -> Q:
	var z: float = rng.int_in(roundi(z0 * 100.0), roundi(z1 * 100.0)) / 100.0
	var m := 1 if s.sgf >= 3.0 else 10
	return Q.new(roundi((s.muf + z * s.sgf) * m), m)


static func _region(rng: Seeded, s: Dictionary, kind: String) -> bool:
	return _params(rng, s) and _bounds(rng, s, kind) and _fill(s, kind)


## The bounds of a region of that kind, with μ and σ picked.
static func _bounds(rng: Seeded, s: Dictionary, kind: String) -> bool:
	match kind:
		"lt":
			s.hi = _cut(rng, s, -Z_MAX, Z_MAX)
		"gt":
			s.lo = _cut(rng, s, -Z_MAX, Z_MAX)
		"in":
			s.lo = _cut(rng, s, -Z_MAX, Z_MAX)
			s.hi = _cut(rng, s, -Z_MAX, Z_MAX)
			if (s.hi.to_float() - s.lo.to_float()) < BAND_MIN * s.sgf:
				return false
		"out":
			s.lo = _cut(rng, s, -Z_MAX, -BAND_MIN / 2.0)
			s.hi = _cut(rng, s, BAND_MIN / 2.0, Z_MAX)
	return true


## The area between two bounds under N(mu, sg²): null is an open end.
static func area(lo: Variant, hi: Variant, mu: float, sg: float) -> float:
	var top := 1.0 if hi == null else phi((hi.to_float() - mu) / sg)
	var low := 0.0 if lo == null else phi((lo.to_float() - mu) / sg)
	return top - low


## The region's z-values and area, and whether every number it gives rounds clearly.
static func _fill(s: Dictionary, kind: String, z_min: float = NormalUnknownSituation.Z_MIN) -> bool:
	s.kind = kind
	var lo: Variant = s.get("lo")
	var hi: Variant = s.get("hi")
	for k in ["lo", "hi"]:
		if s.has(k):
			var z: float = (s[k].to_float() - s.muf) / s.sgf
			s["z" + k] = z
			if absf(z) <= z_min + 1e-9 or absf(z) > Z_MAX + 0.2:
				return false
	var inside := area(lo, hi, s.muf, s.sgf)
	s.p = 1.0 - inside if kind == "out" else inside
	s.other = 1.0 - s.p
	if s.p < P_MIN or s.other < P_MIN or not clear(s.p) or not clear(s.other):
		return false
	if kind == "in":
		s.upper = area(null, hi, s.muf, s.sgf)
		return clear(s.upper)
	if kind == "out":
		s.one = area(null, lo, s.muf, s.sgf)
		return clear(s.one)
	return true


## A sample size whose expected count is at least 10, so it reads as a count.
static func _sample(rng: Seeded, s: Dictionary) -> bool:
	s.n = int(rng.pick(SAMPLES))
	var e: float = s.n * s.p
	return e >= 10.0 and clear(e) and clear(s.n * s.other)


## k near the expected count of a small sample, and the binomial values from the region's area.
static func _exactly(rng: Seeded, s: Dictionary) -> bool:
	s.n = int(rng.pick(SMALL_SAMPLES))
	s.k = roundi(s.n * s.p) + rng.int_in(-2, 2)
	if s.k < 1 or s.k >= s.n:
		return false
	s.pmf = BinomialSituation.pmf(s.n, s.p, s.k)
	s.cum = BinomialSituation.cdf(s.n, s.p, s.k)
	var flip := BinomialSituation.pmf(s.n, s.other, s.k)
	if flip >= SLIP_MIN:
		if not clear(flip):
			return false
		s.flip = flip
	return s.pmf >= PMF_MIN and clear(s.pmf) and clear(s.cum)


## A temperature or a change: μ near 0, so 0 is no lower limit for X.
static func _negative(rng: Seeded, s: Dictionary) -> bool:
	s.neg = true
	s.ctx = rng.int_in(0, NEG_CONTEXTS - 1)
	s.mu = Q.new(rng.int_in(-6, 10))
	s.sg = Q.new(rng.int_in(2, 8))
	_floats(s)
	if s.mu.is_zero():
		return false
	s.hi = Q.new(rng.int_in(1, 14))
	if not _fill(s, "lt"):
		return false
	var z0: float = -s.muf / s.sgf
	s.zero = s.p - phi(z0)
	return z0 > -1.6 and s.zero > 0.02 and clear(s.zero) and Fmt.sf(s.zero) != Fmt.sf(s.p)


## X ~ N(μ, σ²) with σ² written. σ² is a square or a whole number that isn't one.
static func _variance(rng: Seeded, s: Dictionary) -> bool:
	s.mu = Q.new(rng.int_in(20, 400))
	if rng.chance(0.6):
		s.sg = Q.new(rng.int_in(2, 20))
		s.variance = s.sg.n * s.sg.n
	else:
		s.variance = rng.int_in(5, 400)
		var root := roundi(sqrt(s.variance))
		if root * root == s.variance:
			return false
		s.sgf = sqrt(float(s.variance))
	_floats(s)
	if s.sgf > s.muf / 4.0:
		return false
	var kind: String = rng.pick(["lt", "gt", "in"])
	if not _bounds(rng, s, kind) or not _fill(s, kind):
		return false
	var x: float = area(s.get("lo"), s.get("hi"), s.muf, float(s.variance))
	s.slip = x
	return x >= SLIP_MIN and x <= 1.0 - SLIP_MIN and clear(x) and Fmt.sf(x) != Fmt.sf(s.p)


## A value on a grid of u, as a thin strip of the curve.
static func _recorded(rng: Seeded, s: Dictionary) -> bool:
	s.u = rng.pick([Q.new(1), Q.new(1, 10)])
	var m: int = s.u.d
	s.mu = Q.new(rng.int_in(200, 4000), 10)
	s.sg = Q.new(rng.int_in(30, 120), 10) if m == 1 else Q.new(rng.int_in(12, 80), 10)
	_floats(s)
	if s.sgf > s.muf / 4.0:
		return false
	var z: float = rng.int_in(-160, 160) / 100.0
	s.v = Q.new(roundi((s.muf + z * s.sgf) * m), m)
	s.h = s.u.div(Q.new(2))
	s.lo = s.v.sub(s.h)
	s.hi = s.v.add(s.h)
	if not _fill(s, "in", -1.0):
		return false
	s.wide = area(s.v.sub(s.u), s.v.add(s.u), s.muf, s.sgf)
	s.half_up = area(s.v, s.hi, s.muf, s.sgf)
	return clear(s.wide) and clear(s.half_up)


## Two clean tails, with μ and σ what they force, as in `mean-and-sd`.
static func _tails(rng: Seeded, s: Dictionary) -> bool:
	s.kind = "in"
	s.p1 = Q.new(rng.int_in(40, 450), 1000)
	s.p2 = Q.new(rng.int_in(40, 450), 1000)
	s.x1 = rng.int_in(20, 300)
	s.x2 = s.x1 + rng.int_in(4, 60)
	s.lo = Q.new(s.x1)
	s.hi = Q.new(s.x2)
	s.mid = Q.new(1).sub(s.p1).sub(s.p2)
	s.left = Q.new(1).sub(s.p1)
	s.sum = s.p1.add(s.p2)
	var z1 := NormalUnknownSituation.inv(s.p1.to_float())
	var z2 := NormalUnknownSituation.inv(1.0 - s.p2.to_float())
	s.sgf = (s.x2 - s.x1) / (z2 - z1)
	s.muf = s.x1 - z1 * s.sgf
	return s.sgf <= s.muf / 4.0 and not s.mid.eq(s.sum) and not s.mid.eq(s.left)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
