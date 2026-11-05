class_name MotionDistanceSituation
extends RefCounted
## The `motion-distance` situation (curriculum/question-types.json): the `motion` situation with
## its velocity added up, for t5-kinematics-distance (FAL-739, SL5.9). MotionSituation keeps the
## Paper 2 models, the rest finder and the velocity functions; this adds an antiderivative, the
## legs of a trip between rests, and the families the base has no use for. The checker works
## every integral out again with SymPy, or with mpmath for a model.
##
## generate() returns MotionSituation's Dictionary (fam, vc, sc, T, z, turns, s0 and so on) with
## ask, paper, ctx (the story) and, where the ask uses them:
##   fam "poly", shape "hump"   v(t) = 3A(t + u)(r − t), with one rest at r and its top at m
##   fam "poly", shape "two"    MotionSituation.quadratic: rests at p and q
##   fam "fall"   s(t) = ct(2q − t) from the origin, with a turn at q
##   fam "line"   v(t) = b(r − t), for t ≥ 0, with the distance d reached at t = k = r + j
##   fam "s-cos"  s(t) = A cos(wt) + Bt + C, with rests z and q the second of them
##   fam "ridge"  v(t) = B − A cos(π(t − c)/k), of period 2k, slowest at t = c
##   fam "race"   two racers over D metres: A, k and A2, k2; tf the winner's time, gap the rest
##   fam "graph"  a v–t graph: ts and ys, with a corner at each zero, and s0
##   t0, ta, tb   times asked about;  t1, t2  a stretch of a Paper 2 model
##   net, dist    the signed integral and the total distance on the stretch asked about

const TRIES := 900
const T_MAX := 8
const S_MAX := 300
const CONTEXTS := 4
const SIGNS := [1, 1, -1]


static func v_at(s: Dictionary, t: float) -> float:
	return MotionSituation.v_of(s).call(t)


## An antiderivative of v.
static func anti(s: Dictionary, t: float) -> float:
	match s.fam:
		"pulse":
			var A := float(s.A)
			var k: float = s.k.to_float()
			return -A * (t / k + 1.0 / (k * k)) * exp(-k * t) - float(s.B) * t
		"wave":
			var w: float = s.w.to_float()
			return -float(s.A) / w * cos(w * t) + float(s.B) * t
		"damped":
			var k: float = s.k.to_float()
			var w: float = s.w.to_float()
			return float(s.A) * exp(-k * t) * (w * sin(w * t) - k * cos(w * t)) / (k * k + w * w)
	var y := 0.0
	var n: int = s.vc.size()
	for i in n:
		y += float(s.vc[i]) * pow(t, n - i) / float(n - i)
	return y


static func change(s: Dictionary, a: float, b: float) -> float:
	return anti(s, b) - anti(s, a)


## The signed integral over each stretch of [a, b] between rests.
static func legs(s: Dictionary, a: float, b: float) -> Array:
	var cuts: Array = [a]
	for z in s.z:
		if z > a + 1e-9 and z < b - 1e-9:
			cuts.append(z)
	cuts.append(b)
	var out: Array = []
	for i in cuts.size() - 1:
		out.append(change(s, cuts[i], cuts[i + 1]))
	return out


static func total(list: Array) -> float:
	var y := 0.0
	for x in list:
		y += absf(x)
	return y


## v(t) = 3A(t + u)(r − t): s(t) is whole, as r − u is even, and v tops out at a whole time.
static func hump(rng: Seeded, sign: int = 1) -> Dictionary:
	var A: int = rng.pick([1, 1, 2]) * sign
	var u := rng.int_in(1, 3)
	var r := u + 2 * rng.int_in(1, 2)
	var T := r + rng.int_in(1, 2)
	var s := {"fam": "poly", "shape": "hump", "A": A, "u": u, "r": r, "m": (r - u) / 2, "T": T, "s0": rng.int_in(1, 9)}
	s.vc = [-3 * A, 3 * A * (r - u), 3 * A * u * r]
	s.sc = [-A, 3 * A * (r - u) / 2, 3 * A * u * r, s.s0]
	return _small(MotionSituation.features(s))


## Two rests, p and q, in the interval.
static func two(rng: Seeded, sign: int = 0) -> Dictionary:
	var s := MotionSituation.quadratic(rng, sign)
	s.shape = "two"
	s.s0 = rng.int_in(1, 9)
	s.sc[3] = s.s0
	return _small(s)


static func _small(s: Dictionary) -> Dictionary:
	if int(s.T) > T_MAX:
		return {}
	for t in int(s.T) + 1:
		if absf(MotionSituation.poly(s.sc, float(t))) > S_MAX:
			return {}
	return s


## Whole-number polynomial, whichever shape.
static func any_poly(rng: Seeded) -> Dictionary:
	return hump(rng, rng.pick(SIGNS)) if rng.chance(0.5) else two(rng)


static func _all_fair(list: Array) -> bool:
	for x in list:
		if not GdcKit.fair(x):
			return false
	return true


## A Paper 2 model with a start, and its trip over the whole interval.
static func paper2(rng: Seeded) -> Dictionary:
	var s := MotionSituation.model(rng)
	if s.is_empty():
		return {}
	s.s0 = rng.int_in(1, 9)
	s.net = change(s, 0.0, float(s.T))
	s.legs = legs(s, 0.0, float(s.T))
	s.dist = total(s.legs)
	# Three figures can't tell a distance from a net that nearly equals it.
	if absf(s.dist - absf(s.net)) < 0.5:
		return {}
	return s


## A time in the interval and two whole times on each paper.
static func _pick_t0(s: Dictionary, rng: Seeded) -> bool:
	s.t0 = rng.int_in(1, int(s.T))
	s.net = change(s, 0.0, float(s.t0))
	if int(s.paper) == 2:
		return _all_fair([s.net, s.net + float(s.s0)]) and GdcKit.fair(MotionSituation.a_of(s).call(float(s.t0)))
	return not is_zero_approx(s.net)


static func _pick_pair(s: Dictionary, rng: Seeded) -> bool:
	s.ta = rng.int_in(1, int(s.T) - 1)
	s.tb = rng.int_in(s.ta + 1, int(s.T))
	s.net = change(s, float(s.ta), float(s.tb))
	s.pos = float(s.s0) + change(s, 0.0, float(s.tb))
	if int(s.paper) == 2:
		return _all_fair([s.net, s.pos])
	return not is_zero_approx(s.net) and absf(s.net - s.pos) > 0.5


## s(t) = ct(2q − t): out, back through the origin, and on past it to T.
static func fall(rng: Seeded) -> Dictionary:
	var c := rng.int_in(1, 3)
	var q := rng.int_in(2, 5)
	var T := 2 * q + rng.int_in(1, 3)
	var s := {"fam": "fall", "c": c, "q": q, "T": T, "sc": [-c, 2 * c * q, 0]}
	s.top = c * q * q
	s.end = -c * T * T + 2 * c * q * T
	s.dist = s.top + (s.top - s.end)
	return s


static func line(rng: Seeded) -> Dictionary:
	var b: int = rng.pick([2, 2, 3, 4, 6])
	var r := rng.int_in(2, 6)
	var j := rng.int_in(1, 5)
	# Each leg has to be whole, not only their sum.
	if b * r * r % 2 != 0 or b * j * j % 2 != 0:
		return {}
	var s := {"fam": "line", "b": b, "r": r, "j": j, "k": r + j, "vc": [-b, b * r]}
	s.first = b * r * r / 2
	s.more = b * j * j / 2
	s.d = s.first + s.more
	return s


## s(t) = A cos(wt) + Bt + C, moving forward, back, and forward again.
static func s_cos(rng: Seeded) -> Dictionary:
	var s := {"fam": "s-cos", "A": rng.int_in(3, 12), "B": rng.int_in(1, 4), "C": rng.int_in(1, 9)}
	s.w = rng.pick([Q.new(1, 2), Q.new(4, 5), Q.new(6, 5)])
	var w: float = s.w.to_float()
	var av := float(s.A) * w
	if av < 1.3 * float(s.B):
		return {}
	var v := func(t: float) -> float: return -av * sin(w * t) + float(s.B)
	var z := GdcKit.zeros(v, 0.01, 24.0)
	if z.size() < 2 or z[0] < 0.5 or z[1] - z[0] < 0.5:
		return {}
	s.z = z.slice(0, 2)
	s.q = z[1]
	s.T = ceili(z[1]) + rng.int_in(1, 2)
	s.s_0 = s_at(s, 0.0)
	s.s_1 = s_at(s, z[0])
	s.s_2 = s_at(s, z[1])
	s.legs = [s.s_1 - s.s_0, s.s_2 - s.s_1]
	s.dist = total(s.legs)
	s.net = s.s_2 - s.s_0
	return s if _all_fair([z[0], z[1], s.s_1, s.s_2, s.dist, s.net]) and absf(s.dist - absf(s.net)) >= 0.5 else {}


static func s_at(s: Dictionary, t: float) -> float:
	return float(s.A) * cos(s.w.to_float() * t) + float(s.B) * t + float(s.C)


## v(t) = B − A cos(π(t − c)/k): its period is 2k, and B × 2k is whole, as B is in halves.
static func ridge(rng: Seeded) -> Dictionary:
	var s := {"fam": "ridge", "B": Q.new(rng.int_in(10, 24), 2), "A": Q.new(rng.int_in(3, 9), 2), "c": rng.int_in(2, 6), "k": rng.int_in(8, 20)}
	if s.A.to_float() > s.B.to_float() - 1.0:
		return {}
	s.gap = s.B.mul(2 * int(s.k))
	return s


static func x_of(A: float, k: float, t: float) -> float:
	return A * (t + (exp(-k * t) - 1.0) / k)


## Two racers: v(t) = A(1 − e^(−kt)). Each covers x_of(t) by time t.
static func race(rng: Seeded) -> Dictionary:
	var s := {"fam": "race", "D": rng.pick([100, 150, 200, 300, 400]), "A": Q.new(rng.int_in(14, 22), 2), "A2": Q.new(rng.int_in(14, 22), 2)}
	s.k = rng.pick([Q.new(1, 5), Q.new(3, 10), Q.new(2, 5), Q.new(1, 2)])
	s.k2 = rng.pick([Q.new(1, 5), Q.new(3, 10), Q.new(2, 5), Q.new(1, 2)])
	var a: float = s.A.to_float()
	var b: float = s.A2.to_float()
	var k: float = s.k.to_float()
	var k2: float = s.k2.to_float()
	var left := func(t: float) -> float: return x_of(a, k, t) - float(s.D)
	var ts := GdcKit.zeros(left, 0.1, 200.0)
	if ts.size() != 1:
		return {}
	s.tf = ts[0]
	s.x2 = x_of(b, k2, s.tf)
	s.gap = float(s.D) - s.x2
	s.flat = float(s.D) - b * s.tf
	var clear: bool = s.gap >= 2.0 and s.gap <= 0.3 * float(s.D) and s.flat > 0.0
	return s if clear and _all_fair([s.tf, s.x2, s.gap]) else {}


## Two loads of straight pieces, each with a corner at every zero, and whole areas.
static func graph(rng: Seeded) -> Dictionary:
	var a := rng.int_in(2, 8)
	var b := rng.int_in(2, 8)
	var c := rng.int_in(2, 6)
	var ys: Array
	match rng.int_in(0, 2):
		0:
			ys = [0, a, a, 0, -b, -b, 0]
		1:
			ys = [rng.int_in(1, a), a, 0, -b, -b, 0]
		_:
			ys = [0, a, 0, -b, 0, c]
	var ts: Array = [0]
	for i in ys.size() - 1:
		ts.append(ts[-1] + rng.int_in(1, 3))
	var s := {"fam": "graph", "ts": ts, "ys": ys, "s0": rng.int_in(1, 9), "T": ts[-1]}
	s.pieces = []
	s.net = Q.new(0)
	s.dist = Q.new(0)
	for i in ts.size() - 1:
		var bit := Q.new((int(ys[i]) + int(ys[i + 1])) * (int(ts[i + 1]) - int(ts[i])), 2)
		s.pieces.append(bit)
		s.net = s.net.add(bit)
		s.dist = s.dist.add(bit.abs_q())
	return s if s.net.is_int() and s.dist.is_int() else {}


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "total-distance-split")
	var paper := int(need.get("paper", 1))
	for i in TRIES:
		var ctx := rng.int_in(0, CONTEXTS - 1)
		var s := _try(ask, paper, rng)
		if not s.is_empty():
			s.ask = ask
			s.paper = paper
			s.ctx = ctx
			return s
	return {}


static func _try(ask: String, paper: int, rng: Seeded) -> Dictionary:
	var s: Dictionary = {}
	match ask:
		"position-expression":
			s = any_poly(rng)
			if not s.is_empty():
				s.t0 = rng.pick([0, 0, 1, 2])
		"velocity-from-acceleration":
			s = {"fam": "accel", "p": MotionSituation.nz(rng, -3, 3), "q": MotionSituation.nz(rng, -6, 6), "c": MotionSituation.nz(rng, -9, 9), "t0": rng.int_in(1, 3)}
			s.vc = [s.p, s.q, s.c]
			s.ac = [2 * s.p, s.q]
			s.at = MotionSituation.poly(s.vc, float(s.t0))
		"position-at-time":
			s = any_poly(rng) if paper == 1 else paper2(rng)
			if not s.is_empty():
				s.paper = paper
				return s if _pick_t0(s, rng) else {}
		"displacement-between":
			s = any_poly(rng) if paper == 1 else paper2(rng)
			if not s.is_empty():
				s.paper = paper
				return s if _pick_pair(s, rng) else {}
		"position-at-max-velocity":
			s = hump(rng) if paper == 1 else paper2(rng)
			if s.is_empty():
				return {}
			if paper == 2:
				if s.tmax <= 0.0 or s.tmax >= float(s.T) or not GdcKit.fair(s.tmax):
					return {}
				if not MotionSituation.one_peak(MotionSituation.v_of(s), MotionSituation.critical(s)):
					return {}
			s.t = float(s.m) if paper == 1 else s.tmax
			s.net = change(s, 0.0, s.t)
			if paper == 2 and not _all_fair([s.net, s.net + float(s.s0)]):
				return {}
		"does-it-return":
			s = hump(rng, rng.pick(SIGNS))
			if not s.is_empty():
				s.T = int(s.r) + rng.int_in(1, 3)
				s = _small(MotionSituation.features(s))
				if s.is_empty():
					return {}
				s.net = change(s, 0.0, float(s.T))
				if is_zero_approx(s.net):
					return {}
				s.first = change(s, 0.0, float(s.r))
				s.dist = total(legs(s, 0.0, float(s.T)))
				s.back = (s.net > 0.0) != (s.first > 0.0)
				# Half and half, so neither answer can be learned.
				if s.back != rng.chance(0.5):
					return {}
		"initial-displacement", "distance-from-position":
			s = s_cos(rng)
		"displacement-increasing":
			s = MotionSituation.quadratic(rng, -1) if paper == 1 else paper2(rng)
			if s.is_empty():
				return {}
			s.shape = "two"
			if paper == 1:
				s = _small(s)
				if s.is_empty():
					return {}
			var v := MotionSituation.v_of(s)
			if s.z.size() != 2 or v.call(0.0) >= 0.0 or v.call(float(s.T)) >= 0.0:
				return {}
		"ridge-distance":
			s = ridge(rng)
		"race-gap":
			s = race(rng)
		"position-from-graph", "distance-from-graph":
			s = graph(rng)
		"displacement-at-turn", "distance-from-origin", "total-distance-positions":
			s = fall(rng)
		"distance-before-turning":
			s = hump(rng) if paper == 1 else paper2(rng)
			if s.is_empty():
				return {}
			s.t = float(s.r) if paper == 1 else s.z[0]
			s.net = change(s, 0.0, s.t)
			if paper == 2 and not GdcKit.fair(absf(s.net)):
				return {}
		"total-distance-split":
			s = any_poly(rng)
			if not s.is_empty():
				s.net = change(s, 0.0, float(s.T))
				s.legs = legs(s, 0.0, float(s.T))
				s.dist = total(s.legs)
		"total-distance-gdc":
			s = paper2(rng)
			if not s.is_empty() and not _all_fair([s.dist, absf(s.net)]):
				return {}
		"distance-between-times":
			s = paper2(rng)
			if s.is_empty() or s.z.size() < 2:
				return {}
			s.t1 = s.turns[0]
			# The stretch has to hold a rest, so the second rest ends it where the first is
			# past t₁, and the third otherwise.
			var at := 1 if s.z[0] > s.t1 else 2
			if s.z.size() <= at or not GdcKit.fair(s.t1):
				return {}
			s.at = at
			s.t2 = s.z[at]
			s.legs = legs(s, s.t1, s.t2)
			s.net = change(s, s.t1, s.t2)
			s.dist = total(s.legs)
			if s.legs.size() < 2 or absf(s.dist - absf(s.net)) < 0.5 or not _all_fair([s.dist, absf(s.net)]):
				return {}
		"distance-expression", "speeding-distance-expression":
			s = hump(rng)
		"time-for-distance":
			s = line(rng)
	return s


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
