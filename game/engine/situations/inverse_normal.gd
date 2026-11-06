class_name InverseNormalSituation
extends RefCounted
## The `inverse-normal` situation (curriculum/question-types.json): X is normal with μ and σ known
## and an area is given, so the value it cuts off is asked for. It is a thin layer on
## `normal-probability`: phi, inv and clear come from NormalUnknownSituation, μ and σ from
## NormalProbabilitySituation, the stories and the curve from their views. The checker finds the
## values again with mpmath, by its own inverse.
##
## need.ask is the unknown. On Paper 2 (float answers, as a GDC gives them):
##   value-below, value-above   p: P(X < a) = p or P(X > a) = p; below may hold the mean
##   top-percent, bottom-percent   p: the top or bottom share of a story
##   quartile       which "upper" or "lower"
##   percentile     p: the share below it
##   most-above     p above 0.5: P(X > a) = p, so a is below the mean
##   central-bounds level: the middle area, with ends lof and hif
##   band-end       known bound b, level, which "lower" or "upper": P(w < X < b) = level, or
##                  P(b < X < w) = level
##   ratio-tails    level, r, big ("a" or "b", the end with the larger tail), which ("a" or "b")
## On Paper 1 (exact, with no area worked out by machine):
##   shift-same-sd  mu1, mu2, c, rel_x, rel_y: X and Y share σ, P(X rel_x b) = P(Y rel_y c)
##   mirror-bound   c, rel: P(X rel a) is the other tail of c, with σ a letter
##   rule-value     k, area, rel: an area of the 68-95-99.7 rule gives μ ± kσ
##   given-z        z0, table, area, rel: a line of the standard normal is given
##
## generate() returns a Dictionary:
##   paper, ask, rep, ctx (the story)
##   mu, sg     Q;  muf, sgf  the same as floats
##   rel        "<" or ">" of the area given;  p  that area (Q)
##   left       the area to the left of the value (Q, or a float for band-end)
##   z, x       the value's z and the value (Q on Paper 1)
##   flip, no_sd, cdf   the slips: the mirror image, μ + z with σ left out, and normalcdf with the
##                      left area as its bound and the GDC's default N(0, 1)
##   and what each unknown lists above.
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 6000
## A value is this many σ from μ, so its mark and the mean's read apart.
const Z_MIN := 0.3
## The smallest and largest left area, in hundredths.
const P_LOW := 1
const P_HIGH := 99
## A tail that keeps z past Z_MIN.
const TAIL_MAX := 38
const P1_ASKS := ["shift-same-sd", "mirror-bound", "rule-value", "given-z"]
const SD_P1 := [2, 3, 4, 5, 6, 8, 10, 12]
## The tail of each band of the 68-95-99.7 rule, as [top, bottom].
const RULE_TAIL := {1: [16, 100], 2: [25, 1000], 3: [15, 10000]}


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "value-below")
	for i in TRIES:
		var s := {"paper": 1 if ask in P1_ASKS else 2, "ask": ask, "rep": need.get("rep", "equation"),
			"ctx": rng.int_in(0, NormalUnknownSituation.CONTEXTS - 1)}
		var ok := false
		match ask:
			"value-below":
				ok = _value_below(rng, s)
			"value-above", "top-percent":
				ok = _tail(rng, s, ">")
			"bottom-percent":
				ok = _tail(rng, s, "<")
			"quartile":
				ok = _quartile(rng, s)
			"percentile":
				ok = _value_below(rng, s)
			"most-above":
				ok = _most_above(rng, s)
			"central-bounds":
				ok = _central(rng, s)
			"band-end":
				ok = _band(rng, s)
			"ratio-tails":
				ok = _ratio(rng, s)
			"shift-same-sd":
				ok = _shift(rng, s)
			"mirror-bound":
				ok = _mirror(rng, s)
			"rule-value":
				ok = _rule(rng, s)
			"given-z":
				ok = _given_z(rng, s)
		if ok:
			return s
	return {}


static func phi(z: float) -> float:
	return NormalUnknownSituation.phi(z)


static func inv(p: float) -> float:
	return NormalUnknownSituation.inv(p)


static func clear(x: float) -> bool:
	return NormalUnknownSituation.clear(x)


## invNorm(left, μ, σ).
static func at(s: Dictionary, left: float) -> float:
	return s.muf + inv(left) * s.sgf


## Every one of these rounds clearly, and reads differently from the value to 3 s.f.
static func _apart(s: Dictionary, vals: Array) -> bool:
	for v in vals:
		if not clear(v) or Fmt.sf(v) == Fmt.sf(s.x):
			return false
	return true


## The value with the area to its left, and the slips that follow from it. z_edge lets z sit on a
## rounding edge, as a quartile's fixed 0.67449 does: it is only ever a wrong option.
static func _fill(s: Dictionary, left: float, z_edge: bool = false) -> bool:
	s.leftf = left
	s.z = inv(left)
	if absf(s.z) < Z_MIN:
		return false
	s.x = s.muf + s.z * s.sgf
	s.flip = s.muf - s.z * s.sgf
	s.no_sd = s.muf + s.z
	s.cdf = phi(left)
	# The value must also read apart from the mean, or the question shows nothing to find.
	return clear(s.x) and Fmt.sf(s.x) != Fmt.sf(s.mu) and (z_edge or clear(s.z)) and clear(s.cdf) and _apart(s, [s.flip, s.no_sd])


static func _params(rng: Seeded, s: Dictionary) -> bool:
	return NormalProbabilitySituation._params(rng, s)


static func _area(s: Dictionary, rel: String, p: Q) -> void:
	s.rel = rel
	s.p = p
	s.left = p if rel == "<" else Q.new(1).sub(p)


static func _value_below(rng: Seeded, s: Dictionary) -> bool:
	_area(s, "<", Q.new(rng.int_in(P_LOW + 1, P_HIGH - 1), 100))
	return _params(rng, s) and _fill(s, s.p.to_float())


## A tail on `rel`'s side, of at most TAIL_MAX hundredths.
static func _tail(rng: Seeded, s: Dictionary, rel: String) -> bool:
	_area(s, rel, Q.new(rng.int_in(P_LOW, TAIL_MAX), 100))
	return _params(rng, s) and _fill(s, s.left.to_float())


static func _quartile(rng: Seeded, s: Dictionary) -> bool:
	s.which = rng.pick(["upper", "lower"])
	s.left = Q.new(3, 4) if s.which == "upper" else Q.new(1, 4)
	s.rel = rng.pick(["<", ">"])
	s.p = s.left if s.rel == "<" else Q.new(1).sub(s.left)
	return _params(rng, s) and _fill(s, s.left.to_float(), true)


static func _most_above(rng: Seeded, s: Dictionary) -> bool:
	_area(s, ">", Q.new(rng.int_in(100 - TAIL_MAX, P_HIGH), 100))
	return _params(rng, s) and _fill(s, s.left.to_float())


static func _central(rng: Seeded, s: Dictionary) -> bool:
	if not _params(rng, s):
		return false
	s.level = Q.new(rng.int_in(50, 98), 100)
	var c: float = s.level.to_float()
	s.left = Q.new(1).add(s.level).div(Q.new(2))
	s.rel = "<"
	if not _fill(s, s.left.to_float()):
		return false
	s.hif = s.x
	s.lof = s.flip
	# The slip: the middle area keyed as the left tail.
	s.zc = inv(c)
	s.wlo = s.muf - s.zc * s.sgf
	s.whi = s.muf + s.zc * s.sgf
	s.nlo = s.muf - s.z
	s.nhi = s.muf + s.z
	return s.zc > 0.15 and _apart(s, [s.whi, s.nhi]) and clear(s.lof) and clear(s.wlo) and clear(s.nlo) and clear(s.zc * s.sgf)


## One end is known, a share of the whole lies between it and w.
static func _band(rng: Seeded, s: Dictionary) -> bool:
	if not _params(rng, s):
		return false
	s.which = rng.pick(["lower", "upper"])
	s.level = Q.new(rng.int_in(30, 90), 100)
	var c: float = s.level.to_float()
	var known := NormalProbabilitySituation._cut(rng, s, 0.3, 2.2) if s.which == "lower" else NormalProbabilitySituation._cut(rng, s, -2.2, -0.3)
	s.b = known
	s.zb = (known.to_float() - s.muf) / s.sgf
	s.below = phi(s.zb)
	var left: float = s.below - c if s.which == "lower" else s.below + c
	if left < 0.01 or left > 0.99 or not clear(s.below) or not clear(left) or absf(s.zb) < Z_MIN:
		return false
	s.rel = "<"
	if not _fill(s, left):
		return false
	# The slips: the band run to the end of the curve, and what is left split in two.
	s.to_end = at(s, 1.0 - c) if s.which == "lower" else at(s, c)
	var rest := (1.0 - c) / 2.0
	s.equal = at(s, rest) if s.which == "lower" else at(s, 1.0 - rest)
	return absf(s.x - known.to_float()) >= s.sgf * 0.5 and _apart(s, [s.to_end, s.equal]) and clear(left)


## The tails outside a band are in the ratio r : 1, with the smaller one clean.
static func _ratio(rng: Seeded, s: Dictionary) -> bool:
	if not _params(rng, s):
		return false
	s.r = rng.int_in(2, 4)
	s.small = Q.new(rng.int_in(10, 120), 1000)
	s.large = s.small.mul(Q.new(s.r))
	s.rest = s.small.add(s.large)
	s.level = Q.new(1).sub(s.rest)
	if s.level.to_float() < 0.5:
		return false
	s.big = rng.pick(["a", "b"])
	s.which = rng.pick(["a", "b"])
	var ta: Q = s.large if s.big == "a" else s.small
	var tb: Q = s.small if s.big == "a" else s.large
	s.ta = ta
	s.tb = tb
	s.left = ta if s.which == "a" else Q.new(1).sub(tb)
	s.rel = "<"
	if not _fill(s, s.left.to_float()):
		return false
	s.afl = at(s, ta.to_float())
	s.bfl = at(s, 1.0 - tb.to_float())
	var half: float = s.rest.to_float() / 2.0
	s.equal = at(s, half) if s.which == "a" else at(s, 1.0 - half)
	s.swap = at(s, tb.to_float()) if s.which == "a" else at(s, 1.0 - ta.to_float())
	s.other = s.bfl if s.which == "a" else s.afl
	return _apart(s, [s.equal, s.swap]) and clear(s.afl) and clear(s.bfl)


# ── Paper 1 ──────────────────────────────────────────────────

static func _p1_params(rng: Seeded, s: Dictionary) -> void:
	s.mu = Q.new(rng.int_in(20, 200))
	s.sg = Q.new(int(rng.pick(SD_P1)))
	s.muf = s.mu.to_float()
	s.sgf = s.sg.to_float()


static func _shift(rng: Seeded, s: Dictionary) -> bool:
	s.mu1 = rng.int_in(10, 90)
	s.mu2 = s.mu1 + (rng.int_in(4, 40) * (1 if rng.chance(0.7) else -1))
	s.gap = rng.int_in(2, 12) * (1 if rng.chance(0.5) else -1)
	s.c = s.mu2 + s.gap
	s.rel_x = rng.pick(["<", ">"])
	s.rel_y = rng.pick(["<", ">"])
	s.same = s.rel_x == s.rel_y
	s.dist = s.gap if s.same else -s.gap
	s.x = s.mu1 + s.dist
	s.wrong_side = s.mu1 - s.dist
	s.wrong_gap = s.c + (s.mu2 - s.mu1)
	return s.mu2 > 0 and s.mu1 != s.c and s.x > 0 and s.wrong_side > 0 and s.wrong_gap > 0 and s.x != s.c


static func _mirror(rng: Seeded, s: Dictionary) -> bool:
	s.mu = Q.new(rng.int_in(20, 200))
	s.muf = s.mu.to_float()
	s.gap = rng.int_in(3, 18) * (1 if rng.chance(0.5) else -1)
	s.c = s.mu.n + s.gap
	s.sgf = absf(s.gap) / 1.2
	s.x = s.mu.n - s.gap
	s.rel = "<" if s.gap > 0 else ">"
	s.wrong_side = s.c + s.gap
	return s.x > 0 and s.c > 0 and s.wrong_side > 0


static func _rule(rng: Seeded, s: Dictionary) -> bool:
	_p1_params(rng, s)
	s.k = rng.int_in(1, 3)
	var tail: Array = RULE_TAIL[s.k]
	s.tail = Q.new(tail[0], tail[1])
	s.rel = rng.pick(["<", ">"])
	s.tailed = rng.chance(0.7)
	# Either the tail beyond the value, or all the area on the mean's side of it.
	s.p = s.tail if s.tailed else Q.new(1).sub(s.tail)
	s.side = 1 if (s.rel == ">") == s.tailed else -1
	s.x = s.mu.add(Q.new(s.side * s.k).mul(s.sg))
	s.flip = s.mu.sub(Q.new(s.side * s.k).mul(s.sg))
	s.no_sd = s.mu.add(Q.new(s.side * s.k))
	var k2: int = s.k + 1 if s.k < 3 else s.k - 1
	s.other_k = s.mu.add(Q.new(s.side * k2).mul(s.sg))
	return s.flip.sign() > 0 and s.x.sign() > 0 and s.mu.sub(Q.new(3).mul(s.sg)).sign() > 0


static func _given_z(rng: Seeded, s: Dictionary) -> bool:
	_p1_params(rng, s)
	s.z0 = Q.new(rng.int_in(5, 25), 10)
	s.table = Q.new(roundi(phi(s.z0.to_float()) * 1000.0), 1000)
	s.rel = rng.pick(["<", ">"])
	s.tailed = rng.chance(0.5)
	s.p = s.table if s.tailed else Q.new(1).sub(s.table)
	# P(X < a) = table puts a above the mean, as P(X > a) = 1 − table does.
	var up: bool = (s.rel == "<") == s.tailed
	s.up = up
	var shift: Q = s.z0.mul(s.sg)
	s.x = s.mu.add(shift) if up else s.mu.sub(shift)
	s.flip = s.mu.sub(shift) if up else s.mu.add(shift)
	s.no_sd = s.mu.add(s.z0) if up else s.mu.sub(s.z0)
	return s.flip.sign() > 0 and s.mu.sub(Q.new(3).mul(s.sg)).sign() > 0


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
