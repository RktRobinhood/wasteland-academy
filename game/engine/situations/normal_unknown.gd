class_name NormalUnknownSituation
extends RefCounted
## The `normal-unknown` situation (curriculum/question-types.json): a normal variable with
## something hidden (FAL-725). The student's facts stay clean (whole values, areas in
## hundredths) and the hidden parameter is what they force, so z and the answers are floats, as
## a GDC gives them. Standard normal values come from SymmetrySituation (phi, inv_norm). The
## checker finds them again with mpmath.
##
## need.ask is the unknown:
##   z-from-area            side "lt" or "gt", p: P(Z < k) = p or P(Z > k) = p
##   standardise-event      mu, sg, x, side: the same event for Z, with z exact (zq)
##   within-k-sd            k: P(mu - k sg < X < mu + k sg)
##   unknown-sd             mu, x, side, p: sg
##   unknown-mean           sg, x, side, p: mu
##   sd-from-iqr            mu, iqr: sg
##   sd-from-central-area   mu, a, c: P(mu - a < X < mu + a) = c, sg
##   mean-and-sd            x1, x2, p1, p2, form "tails" or "below"
##   mean-from-equal-tails  a1, b1: P(X < a1) = P(X > b1), mu exact
##   sd-from-equal-tails    a1, b1, p: sg
##   mean-from-two-z        x1, z1, x2, z2: mu exact
##
## generate() returns a Dictionary:
##   paper  2 (every part in the bank is Paper 2);  ask;  ctx  the story (NormalUnknownViews.CONTEXTS)
##   z      the z-value;  mu, sg  floats, or Q where exact
##   and what each unknown lists above.
##
## The clean limits are the numbers behind the catalogue's `clean` text. The checker holds its
## own copy.

const TRIES := 6000
const EDGE := 0.03
const CONTEXTS := 8
const Z_MIN := 0.1
## Standard deviations that end when they divide a whole number, for an exact z.
const NEAT_SD := [2, 4, 5, 8, 10, 16, 20, 25, 40]
const IQR_Z := 0.75


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "unknown-sd")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "ctx": rng.int_in(0, CONTEXTS - 1)}
		var ok := false
		match ask:
			"z-from-area":
				ok = _z_from_area(rng, s)
			"standardise-event":
				ok = _standardise(rng, s)
			"within-k-sd":
				s.k = Q.new(rng.int_in(12, 28), 10)
				s.prob = phi(s.k.to_float()) - phi(-s.k.to_float())
				ok = not s.k.eq(Q.new(2)) and clear(s.prob) and clear(phi(s.k.to_float())) and clear(s.prob / 2.0)
			"unknown-sd":
				ok = _unknown_sd(rng, s)
			"unknown-mean":
				ok = _unknown_mean(rng, s)
			"sd-from-iqr":
				ok = _sd_iqr(rng, s)
			"sd-from-central-area":
				ok = _sd_central(rng, s)
			"mean-and-sd":
				ok = _mean_and_sd(rng, s)
			"mean-from-equal-tails":
				ok = _equal_tails(rng, s)
			"sd-from-equal-tails":
				ok = _equal_tails(rng, s) and _sd_equal(s)
			"mean-from-two-z":
				ok = _two_z(rng, s)
		if ok:
			return s
	return {}


static func phi(z: float) -> float:
	return SymmetrySituation.phi(z)


static func inv(p: float) -> float:
	return SymmetrySituation.inv_norm(p)


static func clear(x: float) -> bool:
	return Answer.rounds_clearly(x, EDGE)


## p in hundredths from 0.02 to 0.48.
static func tail(rng: Seeded) -> Q:
	return Q.new(rng.int_in(2, 48), 100)


## The left-tail area of a tail on `side`.
static func left_area(p: Q, side: String) -> float:
	return p.to_float() if side == "lt" else 1.0 - p.to_float()


static func _z_from_area(rng: Seeded, s: Dictionary) -> bool:
	s.side = rng.pick(["lt", "gt"])
	s.p = Q.new(rng.int_in(2, 98), 100)
	s.z = inv(left_area(s.p, s.side))
	s.pz = phi(s.p.to_float())
	return absf(s.z) >= Z_MIN and clear(s.z) and clear(s.pz)


## mu and sg whole, x such that z ends within two decimal places and is not a trivial value.
static func _standardise(rng: Seeded, s: Dictionary) -> bool:
	s.mu = rng.int_in(20, 200)
	s.sg = int(rng.pick(NEAT_SD))
	var gap := rng.int_in(1, 2 * s.sg + s.sg / 2)
	s.x = s.mu + gap * (1 if rng.chance(0.5) else -1)
	s.side = rng.pick(["lt", "gt"])
	s.zq = Q.new(s.x - s.mu, s.sg)
	s.zv = Q.new(s.x - s.mu, s.sg * s.sg)
	s.area = phi(s.zq.to_float()) if s.side == "lt" else 1.0 - phi(s.zq.to_float())
	return s.x > 0 and s.sg > 2 and Q.new(100).mul(s.zq).is_int() and s.zv.to_float() != s.zq.to_float() and Q.new(10000).mul(s.zv).is_int()


## mu, x and the tail on the side away from the mean, so |z| is what the tail gives.
static func _gap_tail(rng: Seeded, s: Dictionary) -> void:
	s.p = tail(rng)
	s.side = rng.pick(["lt", "gt"])
	s.z = inv(left_area(s.p, s.side))


static func _unknown_sd(rng: Seeded, s: Dictionary) -> bool:
	_gap_tail(rng, s)
	s.mu = rng.int_in(20, 400)
	var gap := rng.int_in(2, 60)
	s.x = s.mu - gap if s.side == "lt" else s.mu + gap
	s.sg = gap / absf(s.z)
	return absf(s.z) >= Z_MIN and s.sg >= 1.0 and s.sg <= s.mu / 4.0 and clear(s.sg) and clear(gap * absf(s.z)) and clear(gap / s.p.to_float())


static func _unknown_mean(rng: Seeded, s: Dictionary) -> bool:
	_gap_tail(rng, s)
	s.sg = rng.int_in(2, 40)
	s.x = rng.int_in(4 * s.sg, 400)
	s.mu = s.x - s.z * s.sg
	s.mw = s.x + s.z * s.sg
	return absf(s.z) >= Z_MIN and s.mu >= 4.0 * s.sg and clear(s.mu) and clear(s.mw) and Fmt.sf(s.mu) != Fmt.sf(s.mw)


static func _sd_iqr(rng: Seeded, s: Dictionary) -> bool:
	s.mu = rng.int_in(20, 400)
	s.iqr = Q.new(rng.int_in(20, 400), 10)
	s.z = inv(IQR_Z)
	s.sg = s.iqr.to_float() / 2.0 / s.z
	return s.sg <= s.mu / 4.0 and clear(s.sg) and clear(s.sg * 2.0) and clear(s.iqr.to_float() / s.z / 4.0)


static func _sd_central(rng: Seeded, s: Dictionary) -> bool:
	s.mu = rng.int_in(20, 400)
	s.a = rng.int_in(2, 40)
	s.c = Q.new(rng.int_in(50, 95), 100)
	s.z = inv((1.0 + s.c.to_float()) / 2.0)
	s.sg = s.a / s.z
	s.sw = s.a / inv(s.c.to_float())
	return s.sg <= s.mu / 4.0 and clear(s.sg) and clear(s.sw) and Fmt.sf(s.sg) != Fmt.sf(s.sw)


static func _mean_and_sd(rng: Seeded, s: Dictionary) -> bool:
	s.form = rng.pick(["tails", "below"])
	s.x1 = rng.int_in(20, 300)
	s.x2 = s.x1 + rng.int_in(6, 80)
	s.p1 = tail(rng)
	s.p2 = tail(rng) if s.form == "tails" else Q.new(rng.int_in(52, 98), 100)
	if s.form == "below" and s.p2.to_float() <= s.p1.to_float():
		return false
	s.a1 = s.p1.to_float()
	s.a2 = 1.0 - s.p2.to_float() if s.form == "tails" else s.p2.to_float()
	s.z1 = inv(s.a1)
	s.z2 = inv(s.a2)
	var gap: float = s.x2 - s.x1
	s.sg = gap / (s.z2 - s.z1)
	s.mu = s.x1 - s.z1 * s.sg
	# The slips, each solved the same way from the wrong two numbers.
	s.pos = _solve(s.x1, s.x2, absf(s.z1), absf(s.z2))
	s.prb = _solve(s.x1, s.x2, s.a1, s.a2)
	s.dp1 = _solve(s.x1, s.x2, snappedf(s.z1, 0.1), snappedf(s.z2, 0.1))
	if s.sg <= 0.0 or s.sg > s.mu / 3.0 or not clear(s.sg) or not clear(s.mu):
		return false
	# Every slip must solve, and read differently from the answer in both numbers.
	for w in [s.prb, s.dp1]:
		if w.is_empty() or not clear(w.mu) or not clear(w.sg) or Fmt.sf(w.mu) == Fmt.sf(s.mu) or Fmt.sf(w.sg) == Fmt.sf(s.sg):
			return false
	if not s.pos.is_empty() and (not clear(s.pos.mu) or not clear(s.pos.sg)):
		s.pos = {}
	return true


## mu and sg from x1 = mu + z1 sg and x2 = mu + z2 sg; {} where sg isn't positive.
static func _solve(x1: float, x2: float, z1: float, z2: float) -> Dictionary:
	if absf(z2 - z1) < 1e-9:
		return {}
	var sg := (x2 - x1) / (z2 - z1)
	return {} if sg <= 0.0 else {"mu": x1 - z1 * sg, "sg": sg}


static func _equal_tails(rng: Seeded, s: Dictionary) -> bool:
	s.mu = rng.int_in(20, 400)
	s.half = rng.int_in(2, 40)
	s.a1 = s.mu - s.half
	s.b1 = s.mu + s.half
	s.p = Q.new(rng.int_in(2, 40), 100)
	return s.half <= s.mu / 2


static func _sd_equal(s: Dictionary) -> bool:
	s.z = inv(1.0 - s.p.to_float())
	s.sg = s.half / s.z
	return s.sg <= s.mu / 4.0 and clear(s.sg) and clear(s.half * 2.0 / s.z) and clear(s.half * s.z)


static func _two_z(rng: Seeded, s: Dictionary) -> bool:
	s.mu = rng.int_in(20, 300)
	s.sg = rng.int_in(2, 30)
	s.z1 = Q.new(-rng.int_in(3, 25), 10)
	s.z2 = Q.new(rng.int_in(3, 25), 10)
	s.x1 = Q.new(s.mu).add(s.z1.mul(Q.new(s.sg)))
	s.x2 = Q.new(s.mu).add(s.z2.mul(Q.new(s.sg)))
	return s.mu > 4 * s.sg and not s.z1.neg().eq(s.z2)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
