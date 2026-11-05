class_name NormalPropertiesSituation
extends RefCounted
## The `normal-properties` situation (curriculum/question-types.json): what the shape of a normal
## curve gives without working out an area from nothing (FAL-740). Facts are clean and every answer
## is exact, except a value a GDC gives (a bound more than h standard deviations from the mean, a
## tail beside a given band, and the central intervals), which is a float to 3 s.f.
##
## need.ask is the unknown (see NormalPropertiesViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx (the story, NormalUnknownViews.CONTEXTS)
##   mu, sg       Q, or sg left out where the question keeps it hidden
##   muf, sgf     the same as floats, for the curve. A hidden σ is what the areas force.
##   k            how many standard deviations a band reaches, 1, 2 or 3
##   lo, hi       the ends of a band, Q
##   form         "pr" or "pct" (the answer's form), "bounds" or "sds" (how a band is said)
##   sym          the equation writes σ as the letter a
##   n, mode      a count: how many of n, "in" or "out" of the band
##   x, kind      a bound and its side, "lt" or "gt"
##   z1, z2       a band between two whole numbers of σ from the mean
##   p, c         a tail and a central area
##   x1, x2, p1, p2  two different tails
##   change, d, mu2, sg2  a change of parameter; curves, want: the four curves of a figure
##   h, u         a non-whole number of standard deviations, and the upper tail beside a band
##   prob         a GDC answer;  level, z, width: a central area, its z and the half-width
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 6000
const EDGE := 0.03
const CONTEXTS := 8
const SD_P1 := [2, 3, 4, 5, 6, 8, 10, 12]
const PICK_SD := [2, 3, 4, 5, 6, 8, 10]
## A share of the whole, as [top, bottom]: the 68-95-99.7 rule.
const RULE := {1: [68, 100], 2: [95, 100], 3: [997, 1000]}
const LEVELS := [60, 70, 75, 80, 85, 90, 95, 98, 99]
const SCALE_HEIGHT := 6.0
## Three marks under a figure need this many σ between them to be read.
const FIG_GAP := 0.6
const FIG_TAIL := 27
const WORD_TAIL := 45
const HS_MIN := 5
const HS_MAX := 25


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "empirical-share")
	var rep: String = need.get("rep", "equation")
	var paper: int = int(need.get("paper", 2))
	for i in TRIES:
		var s := {"paper": paper, "ask": ask, "rep": rep, "ctx": rng.int_in(0, CONTEXTS - 1)}
		var ok := false
		match ask:
			"empirical-share":
				ok = _share_of_band(rng, s)
			"empirical-count":
				ok = _count(rng, s)
			"empirical-tail":
				ok = _rule_tail(rng, s)
			"empirical-band":
				ok = _rule_band(rng, s)
			"sd-from-rule":
				ok = _sd_rule(rng, s)
			"other-sd-end":
				ok = _other_end(rng, s)
			"point-probability":
				ok = _point(rng, s)
			"effect-of-change":
				ok = _effect(rng, s)
			"match-curve":
				ok = _four_curves(rng, s)
			"pick-two-curves":
				ok = _two_curves(rng, s)
			"pick-shaded":
				ok = _shaded(rng, s)
			"same-sd-shift", "shifted-mirror":
				ok = _shift(rng, s)
			"beyond-sd":
				ok = _beyond(rng, s)
			"half-below-mean":
				_known(rng, s)
				s.kind = rng.pick(["lt", "gt"])
				ok = true
			"mirror-tail", "mirror-complement", "middle-from-tail", "mean-to-point":
				ok = _tail(rng, s)
			"tail-from-middle", "half-of-middle":
				ok = _tail(rng, s)
				s.c = Q.new(1).sub(s.p.mul(2))
			"between-from-two-tails":
				ok = _two_tails(rng, s)
			"tail-from-band":
				ok = _band_and_tail(rng, s)
			"mirror-value":
				ok = _mirror_value(rng, s)
			"central-k", "central-endpoints", "central-k-sd":
				ok = _central(rng, s)
		if ok:
			return s
	return {}


static func phi(z: float) -> float:
	return SymmetrySituation.phi(z)


static func inv(p: float) -> float:
	return SymmetrySituation.inv_norm(p)


static func clear(x: float) -> bool:
	return Answer.rounds_clearly(x, EDGE)


## The share inside μ ± kσ, by the rule.
static func share(k: int) -> Q:
	return Q.new(RULE[k][0], RULE[k][1])


## The area from the mean out to a whole number of σ, signed.
static func half_share(z: int) -> Q:
	if z == 0:
		return Q.new(0)
	var v := share(absi(z)).div(Q.new(2))
	return v.neg() if z < 0 else v


## μ and σ: whole numbers on Paper 1, tenths half of the time on Paper 2. σ stays at most μ ÷ 5,
## so three standard deviations under the mean is a real measurement.
static func _known(rng: Seeded, s: Dictionary) -> void:
	if s.paper == 2 and rng.chance(0.5):
		s.sg = Q.new(rng.int_in(12, 60), 10)
		s.mu = Q.new(rng.int_in(int(s.sg.to_float() * 50.0), 900), 10)
	else:
		var sg: int = rng.pick(SD_P1)
		s.sg = Q.new(sg)
		s.mu = Q.new(rng.int_in(maxi(20, sg * 5), sg * 5 + 60))
	s.muf = s.mu.to_float()
	s.sgf = s.sg.to_float()


## How a percentage or a probability is asked: a story asks a percentage.
static func _rule_form(rng: Seeded, s: Dictionary) -> void:
	s.form = "pct" if s.rep == "words" and rng.chance(0.7) else "pr"


static func _set_band(s: Dictionary) -> void:
	s.lo = s.mu.sub(s.sg.mul(s.k))
	s.hi = s.mu.add(s.sg.mul(s.k))


static func _share_of_band(rng: Seeded, s: Dictionary) -> bool:
	_known(rng, s)
	s.k = rng.pick([1, 1, 2, 2, 3])
	_set_band(s)
	_rule_form(rng, s)
	s.sym = s.rep == "equation" and rng.chance(0.4)
	s.said = "sds" if s.rep == "words" and rng.chance(0.5) else "bounds"
	return true


## A count: 1000s for the third band, so 99.7% of n is whole, else 100s.
static func _count(rng: Seeded, s: Dictionary) -> bool:
	_known(rng, s)
	s.k = rng.pick([1, 2, 2, 3])
	_set_band(s)
	s.mode = rng.pick(["in", "out"])
	s.n = 1000 * rng.int_in(1, 5) if s.k == 3 else 100 * rng.pick([2, 4, 5, 6, 8, 10, 20, 40])
	return true


static func _rule_tail(rng: Seeded, s: Dictionary) -> bool:
	_known(rng, s)
	s.k = rng.pick([1, 1, 2, 2, 3])
	s.kind = rng.pick(["lt", "gt"])
	s.up = rng.chance(0.5)
	s.x = s.mu.add(s.sg.mul(s.k)) if s.up else s.mu.sub(s.sg.mul(s.k))
	_rule_form(rng, s)
	return true


## z1 < z2, whole numbers of σ from the mean, and never a band centred on the mean.
static func _rule_band(rng: Seeded, s: Dictionary) -> bool:
	_known(rng, s)
	s.z1 = rng.int_in(-3, 2)
	s.z2 = rng.int_in(s.z1 + 1, 3)
	if s.z1 + s.z2 == 0:
		return false
	s.lo = s.mu.add(s.sg.mul(s.z1))
	s.hi = s.mu.add(s.sg.mul(s.z2))
	_rule_form(rng, s)
	return true


## σ is a whole number or a half, from a band whose ends are whole.
static func _sd_rule(rng: Seeded, s: Dictionary) -> bool:
	_known(rng, s)
	s.sg = Q.new(rng.int_in(4, 24), 2)
	s.mu = Q.new(rng.int_in(maxi(20, int(s.sg.to_float() * 5.0)), 90))
	s.sgf = s.sg.to_float()
	s.muf = s.mu.to_float()
	s.k = rng.pick([1, 2, 2, 3])
	_set_band(s)
	return s.lo.is_int() and s.hi.is_int()


static func _other_end(rng: Seeded, s: Dictionary) -> bool:
	_known(rng, s)
	s.k = rng.pick([1, 1, 2, 3])
	_set_band(s)
	s.given_low = rng.chance(0.7)
	return true


static func _point(rng: Seeded, s: Dictionary) -> bool:
	_known(rng, s)
	s.j = rng.pick([-2, -1, 0, 1, 2])
	s.x = s.mu.add(s.sg.mul(s.j))
	return true


static func _effect(rng: Seeded, s: Dictionary) -> bool:
	_known(rng, s)
	s.change = rng.pick(["mu-up", "mu-down", "sd-up", "sd-down"])
	s.mu2 = s.mu
	s.sg2 = s.sg
	match s.change:
		"mu-up", "mu-down":
			s.d = Q.new(rng.int_in(2, 12))
			s.mu2 = s.mu.add(s.d) if s.change == "mu-up" else s.mu.sub(s.d)
		"sd-up":
			s.sg2 = s.sg.mul(Q.new(rng.pick([3, 2]), 1))
		"sd-down":
			if not s.sg.is_int() or int(s.sg.to_float()) % 2 != 0:
				return false
			s.sg2 = s.sg.div(Q.new(2))
	return true


## Four curves from two means and two spreads, lettered in a random order.
static func _four_curves(rng: Seeded, s: Dictionary) -> bool:
	var a: int = rng.pick(PICK_SD)
	var b: int = a * 2
	var m: int = rng.int_in(maxi(20, b * 5), 80)
	var gap: int = rng.int_in(a * 2, a * 3)
	var means: Array = [m, m + gap]
	var spreads: Array = [a, b]
	var letters: Array = rng.shuffled(["A", "B", "C", "D"])
	var curves: Array = []
	var i := 0
	for mu in means:
		for sg in spreads:
			curves.append({"mu": mu, "sg": sg, "label": letters[i]})
			i += 1
	s.curves = curves
	s.want = rng.int_in(0, 3)
	s.as_variance = rng.chance(0.5)
	s.mu = Q.new(m)
	return true


## X and Y on one pair of axes. With `same`, they share a mean, as the skill's exam line does.
static func _two_curves(rng: Seeded, s: Dictionary) -> bool:
	var a: int = rng.pick(PICK_SD)
	var b: int = a * rng.pick([2, 2, 3])
	s.same = rng.chance(0.5)
	var m: int = rng.int_in(maxi(20, b * 5), 80)
	s.mx = m
	s.my = m if s.same else m + rng.pick([-1, 1]) * rng.int_in(a, a * 3)
	s.sx = a
	s.sy = b
	if rng.chance(0.5):
		s.sx = b
		s.sy = a
	s.as_variance = rng.chance(0.5)
	return s.my > 0


static func _shaded(rng: Seeded, s: Dictionary) -> bool:
	var sg: int = rng.pick(PICK_SD)
	s.sg = Q.new(sg)
	s.mu = Q.new(rng.int_in(maxi(20, sg * 5), 80))
	s.muf = s.mu.to_float()
	s.sgf = float(sg)
	s.kind = rng.pick(["gt", "lt", "in"])
	var j1: int = rng.pick([-2, -1, 1, 2])
	var j2: int = rng.pick([-2, -1, 1, 2])
	if s.kind == "in":
		if j1 >= j2 or j1 + j2 == 0:
			return false
		s.lo = s.mu.add(s.sg.mul(j1))
		s.hi = s.mu.add(s.sg.mul(j2))
	else:
		s.x = s.mu.add(s.sg.mul(j1))
	return true


static func _shift(rng: Seeded, s: Dictionary) -> bool:
	s.mu = Q.new(rng.int_in(5, 60))
	s.mu2 = Q.new(rng.int_in(5, 60))
	var off := rng.int_in(1, 9)
	s.x = s.mu2.add(off)
	s.off = off
	return not s.mu.eq(s.mu2) and absi(int(s.mu.sub(s.mu2).to_float())) >= 3


## More than h standard deviations from the mean, h in tenths and never a whole number.
static func _beyond(rng: Seeded, s: Dictionary) -> bool:
	_known(rng, s)
	s.h = Q.new(rng.int_in(HS_MIN, HS_MAX), 10)
	if s.h.is_int():
		return false
	s.kind = rng.pick(["gt", "lt", "out"])
	var h: float = s.h.to_float()
	s.x = s.mu.add(s.sg.mul(s.h)) if s.kind != "lt" else s.mu.sub(s.sg.mul(s.h))
	var tail := phi(-h)
	s.prob = tail * 2.0 if s.kind == "out" else tail
	# The two slips: the area on the other side, and h added on without σ.
	s.other = 1.0 - s.prob
	s.no_sd = phi(-h / s.sgf)
	return clear(s.prob) and clear(s.other) and clear(s.no_sd) and clear(tail) and s.sgf > 1.0


## A tail p beyond μ + a and its mirror: hundredths on Paper 1, thousandths on Paper 2. A figure
## draws the σ that makes the areas true.
static func _tail(rng: Seeded, s: Dictionary) -> bool:
	var top: int = FIG_TAIL if s.rep == "diagram" else WORD_TAIL
	if s.paper == 2:
		s.p = Q.new(rng.int_in(21, top * 10), 1000)
	else:
		s.p = Q.new(rng.int_in(4, top), 100)
	if s.p.eq(Q.new(1, 4)):
		return false
	s.mu = Q.new(rng.int_in(8, 70))
	s.a = Q.new(rng.int_in(2, 7))
	s.lo = s.mu.sub(s.a)
	s.hi = s.mu.add(s.a)
	s.muf = s.mu.to_float()
	s.sgf = s.a.to_float() / inv(1.0 - s.p.to_float())
	s.up = rng.chance(0.5)
	return s.lo.sign() > 0


## Two tails that differ, for a variable with its mean and σ hidden.
static func _two_tails(rng: Seeded, s: Dictionary) -> bool:
	if s.paper == 2:
		s.p1 = Q.new(rng.int_in(40, 420), 1000)
		s.p2 = Q.new(rng.int_in(40, 420), 1000)
		s.x1 = Q.new(rng.int_in(300, 900), 10)
		s.x2 = s.x1.add(Q.new(rng.int_in(20, 90), 10))
	else:
		s.p1 = Q.new(rng.int_in(5, 40), 100)
		s.p2 = Q.new(rng.int_in(5, 40), 100)
		s.x1 = Q.new(rng.int_in(20, 80))
		s.x2 = s.x1.add(rng.int_in(4, 20))
	var z1 := inv(s.p1.to_float())
	var z2 := inv(1.0 - s.p2.to_float())
	s.sgf = (s.x2.to_float() - s.x1.to_float()) / (z2 - z1)
	s.muf = s.x1.to_float() - z1 * s.sgf
	if s.p1.eq(s.p2) or s.p1.add(s.p2).to_float() > 0.8:
		return false
	if s.rep != "diagram":
		return true
	return s.muf - s.x1.to_float() >= FIG_GAP * s.sgf and s.x2.to_float() - s.muf >= FIG_GAP * s.sgf


## P2: a band from w to b of given area, with b and σ known, as a GDC question.
static func _band_and_tail(rng: Seeded, s: Dictionary) -> bool:
	_known(rng, s)
	var z := float(rng.int_in(4, 18)) / 10.0
	s.x = s.mu.add(s.sg.mul(Q.new(int(z * 10.0), 10)))
	s.u = phi(-z)
	s.c = Q.new(rng.int_in(50, 85), 100)
	s.prob = 1.0 - s.c.to_float() - s.u
	if s.prob < 0.03 or s.prob > 0.42:
		return false
	# w is what the left tail forces; it stays a letter in the question.
	s.w = s.muf + s.sgf * inv(s.prob)
	s.one = 1.0 - s.c.to_float()
	return clear(s.prob) and clear(s.u) and clear(s.one) and clear(1.0 - s.u) and s.u > 0.02


static func _mirror_value(rng: Seeded, s: Dictionary) -> bool:
	s.mu = Q.new(rng.int_in(10, 80))
	s.a = Q.new(rng.int_in(2, 9))
	s.lo = s.mu.sub(s.a)
	s.hi = s.mu.add(s.a)
	s.muf = s.mu.to_float()
	s.sgf = s.a.to_float() / 1.2
	s.given_low = rng.chance(0.5)
	return s.lo.sign() > 0


## A central area, its z, and everything a GDC reads for it.
static func _central(rng: Seeded, s: Dictionary) -> bool:
	_known(rng, s)
	s.level = Q.new(rng.pick(LEVELS), 100)
	var c: float = s.level.to_float()
	s.left = 0.5 + c / 2.0
	s.z = inv(s.left)
	# The slip: the central area used as the left tail.
	s.zc = inv(c)
	s.width = s.z * s.sgf
	s.lof = s.muf - s.width
	s.hif = s.muf + s.width
	s.wlo = s.muf - s.zc * s.sgf
	s.whi = s.muf + s.zc * s.sgf
	s.zlo = s.muf - s.z
	s.zhi = s.muf + s.z
	for v in [s.z, s.zc, s.width, s.zc * s.sgf, s.hif, s.lof]:
		if not clear(v):
			return false
	for v in [s.wlo, s.whi, s.zlo, s.zhi]:
		if not clear(v):
			return false
	return s.zc > 0.15


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
