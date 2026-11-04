class_name MotionSituation
extends RefCounted
## The `motion` situation (curriculum/question-types.json): a particle on a straight line
## from t = 0 (SL5.9, FAL-724). Paper 1 is a whole-number polynomial, built from its rests.
## Paper 2 is a velocity with e or sin, whose rests and turning points are found numerically
## here and again by the SymPy checker (tools/check_answers.py). A motion graph is in
## straight pieces with whole-number corners.
##
## generate() returns a Dictionary with ask, paper, fam and, for a curve:
##   vc       Paper 1: v(t) as coefficients, highest power first
##   A, k, w, B   Paper 2: pulse A t e^(−kt) − B, wave A sin(wt) + B, damped A e^(−kt) cos(wt)
##   T        the interval is 0 ≤ t ≤ T
##   z        the times v = 0, in order
##   t0       a time asked about, whole
##   vmax, tmax, vmin, tmin, smax, ts   the extremes of v and of |v|, ends included

const TRIES := 600
const GAP := 0.5


static func nz(rng: Seeded, lo: int, hi: int) -> int:
	return ExtensionViews.nonzero(rng, lo, hi)


static func poly(co: Array, x: float) -> float:
	var y := 0.0
	for c in co:
		y = y * x + float(c)
	return y


static func diff(co: Array) -> Array:
	var out: Array = []
	var n := co.size() - 1
	for i in n:
		out.append(int(co[i]) * (n - i))
	return out


static func v_of(s: Dictionary) -> Callable:
	match s.fam:
		"pulse":
			var A := float(s.A)
			var k: float = s.k.to_float()
			var B := float(s.B)
			return func(t: float) -> float: return A * t * exp(-k * t) - B
		"wave":
			var A := float(s.A)
			var w: float = s.w.to_float()
			var B := float(s.B)
			return func(t: float) -> float: return A * sin(w * t) + B
		"damped":
			var A := float(s.A)
			var k: float = s.k.to_float()
			var w: float = s.w.to_float()
			return func(t: float) -> float: return A * exp(-k * t) * cos(w * t)
	var co: Array = s.vc
	return func(t: float) -> float: return poly(co, t)


static func a_of(s: Dictionary) -> Callable:
	match s.fam:
		"pulse":
			var A := float(s.A)
			var k: float = s.k.to_float()
			return func(t: float) -> float: return A * exp(-k * t) * (1.0 - k * t)
		"wave":
			var A := float(s.A)
			var w: float = s.w.to_float()
			return func(t: float) -> float: return A * w * cos(w * t)
		"damped":
			var A := float(s.A)
			var k: float = s.k.to_float()
			var w: float = s.w.to_float()
			return func(t: float) -> float: return -A * exp(-k * t) * (k * cos(w * t) + w * sin(w * t))
	var co := diff(s.vc)
	return func(t: float) -> float: return poly(co, t)


## da/dt, for the greatest acceleration on Paper 2.
static func j_of(s: Dictionary) -> Callable:
	match s.fam:
		"pulse":
			var A := float(s.A)
			var k: float = s.k.to_float()
			return func(t: float) -> float: return A * k * exp(-k * t) * (k * t - 2.0)
		"wave":
			var A := float(s.A)
			var w: float = s.w.to_float()
			return func(t: float) -> float: return -A * w * w * sin(w * t)
		"damped":
			var A := float(s.A)
			var k: float = s.k.to_float()
			var w: float = s.w.to_float()
			return func(t: float) -> float: return A * exp(-k * t) * ((k * k - w * w) * cos(w * t) + 2.0 * k * w * sin(w * t))
	var co := diff(diff(s.vc))
	return func(t: float) -> float: return poly(co, t)


## The rests and extremes of v on [0, T]. Paper 1's are whole by construction.
static func features(s: Dictionary) -> Dictionary:
	var v := v_of(s)
	var a := a_of(s)
	var T := float(s.T)
	s.z = GdcKit.zeros(v, 0.01, T - 0.01)
	s.turns = GdcKit.zeros(a, 0.01, T - 0.01)
	var ts: Array = [0.0, T] + s.turns
	s.vmax = -INF
	s.vmin = INF
	s.smax = -1.0
	for t in ts:
		var y: float = v.call(t)
		if y > s.vmax:
			s.vmax = y
			s.tmax = t
		if y < s.vmin:
			s.vmin = y
			s.tmin = t
		if absf(y) > s.smax:
			s.smax = absf(y)
			s.ts = t
	return s


static func _spaced(list: Array, end: float) -> bool:
	var prev := 0.0
	for x in list:
		if x - prev < GAP:
			return false
		prev = x
	return end - prev >= 0.0


static func _fair_all(list: Array) -> bool:
	for x in list:
		if not GdcKit.fair(x):
			return false
	return true


## A model with two rests, past the second, every feature clear of a rounding edge.
static func model(rng: Seeded) -> Dictionary:
	var s := {"fam": rng.pick(["pulse", "wave", "damped"])}
	match s.fam:
		"pulse":
			s.A = rng.int_in(6, 16)
			s.k = rng.pick([Q.new(1, 5), Q.new(1, 4), Q.new(2, 5), Q.new(1, 2)])
			s.B = rng.int_in(1, 4)
		"wave":
			s.A = rng.int_in(4, 12)
			s.w = rng.pick([Q.new(1, 2), Q.new(3, 5), Q.new(4, 5), Q.new(6, 5)])
			s.B = nz(rng, -3, 3)
		"damped":
			s.A = rng.int_in(6, 12)
			s.k = rng.pick([Q.new(1, 10), Q.new(3, 20), Q.new(1, 5)])
			s.w = rng.pick([Q.new(4, 5), Q.new(1), Q.new(6, 5), Q.new(3, 2)])
	var early := GdcKit.zeros(v_of(s), 0.01, 24.0)
	if early.size() < 2:
		return {}
	s.T = ceili(early[1]) + rng.int_in(1, 2)
	features(s)
	if s.z.size() < 2 or s.z.size() > 3 or s.turns.is_empty():
		return {}
	if not _fair_all(s.z) or not _spaced(s.z, float(s.T)) or not _spaced(s.turns, float(s.T)):
		return {}
	# A wave's peak is whole, A + B, which is still a fair 3 s.f. answer.
	if not Answer.rounds_clearly(s.vmax, 0.05) or not Answer.rounds_clearly(s.vmin, 0.05) or not Answer.rounds_clearly(s.smax, 0.05):
		return {}
	return s if GdcKit.fair(a_of(s).call(s.z[0])) else {}


## v(t) = 3A(t − p)(t − q): s(t) has whole coefficients, as q − p is even.
static func quadratic(rng: Seeded, sign_a: int = 0) -> Dictionary:
	var A: int = rng.pick([1, 1, 2]) * (sign_a if sign_a != 0 else rng.pick([1, -1]))
	var p := rng.int_in(1, 4)
	var q := p + 2 * rng.int_in(1, 3)
	var s := {"fam": "poly", "A": A, "p": p, "q": q, "vc": [3 * A, -3 * A * (p + q), 3 * A * p * q], "T": q + rng.int_in(1, 2), "s0": rng.int_in(0, 9)}
	s.sc = [A, -3 * A * (p + q) / 2, 3 * A * p * q, s.s0]
	return features(s)


## A velocity from t0 on: a whole time inside the interval with v and a clear of 0.
static func _pick_t0(s: Dictionary, rng: Seeded) -> bool:
	var v := v_of(s)
	var a := a_of(s)
	for i in 40:
		var t := rng.int_in(1, maxi(1, int(s.T)))
		if absf(v.call(float(t))) > 0.2 and absf(a.call(float(t))) > 0.2:
			if int(s.paper) == 1 or (GdcKit.fair(v.call(float(t))) and GdcKit.fair(a.call(float(t)))):
				s.t0 = t
				return true
	return false


## s(t) with e or sin, so v comes from a derivative on Paper 2.
static func position(rng: Seeded) -> Dictionary:
	var s := {"fam": rng.pick(["s-wave", "s-exp"]), "A": rng.int_in(3, 12), "B": rng.int_in(1, 5), "t0": rng.int_in(1, 6)}
	s.w = rng.pick([Q.new(1, 2), Q.new(4, 5), Q.new(6, 5)])
	var t := float(s.t0)
	var w: float = s.w.to_float()
	if s.fam == "s-wave":
		s.pos = s.A * sin(w * t) + s.B * t
		s.vel = s.A * w * cos(w * t) + s.B
	else:
		s.pos = s.A * exp(-w * t) + s.B * t
		s.vel = -s.A * w * exp(-w * t) + s.B
	s.T = s.t0 + rng.int_in(1, 3)
	return s if GdcKit.fair(s.pos) and GdcKit.fair(s.vel) and GdcKit.fair(s.pos / t) else {}


## A v–t graph: up, level, down through 0, level, back to 0, with whole-number corners.
static func pieces(rng: Seeded) -> Dictionary:
	var ts: Array = [0]
	for i in 5:
		ts.append(ts[-1] + rng.int_in(1, 3))
	var a := rng.int_in(2, 8)
	var b := rng.int_in(2, 8)
	if a == b:
		b += 1
	return {"ts": ts, "ys": [0, a, a, 0, -b, 0], "a": a, "b": b, "k": rng.int_in(0, 4)}


static func position_pieces(rng: Seeded) -> Dictionary:
	var ts: Array = [0]
	var ys: Array = [rng.int_in(0, 4)]
	for i in 4:
		var dt: int = rng.pick([1, 2, 2, 3])
		ts.append(ts[-1] + dt)
		ys.append(ys[-1] + dt * nz(rng, -3, 4))
	return {"ts": ts, "ys": ys, "k": rng.int_in(0, 3)}


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "first-at-rest")
	var paper := int(need.get("paper", 1))
	for i in TRIES:
		var s := _try(ask, paper, rng)
		if not s.is_empty():
			s.ask = ask
			s.paper = paper
			return s
	return {}


static func _try(ask: String, paper: int, rng: Seeded) -> Dictionary:
	var s := {"fam": "", "paper": paper}
	match ask:
		"velocity-expression", "acceleration-expression":
			s = quadratic(rng)
		"velocity-at-time":
			if paper == 2:
				return position(rng)
			s = quadratic(rng)
			s.paper = 1
			s.t0 = rng.int_in(1, s.T)
			return s if s.t0 != s.p and s.t0 != s.q else {}
		"acceleration-at-time", "speeding-up":
			s = quadratic(rng) if paper == 1 else model(rng)
			if s.is_empty():
				return {}
			s.paper = paper
			return s if _pick_t0(s, rng) else {}
		"time-from-acceleration", "time-from-velocity":
			return _target(ask, paper, rng)
		"first-at-rest", "acceleration-at-rest", "moving-one-way":
			s = quadratic(rng) if paper == 1 else model(rng)
		"change-direction":
			if paper == 1:
				var p := rng.int_in(1, 4)
				var q := p + 3 * rng.int_in(1, 2)
				s = {"fam": "touch", "p": p, "q": q, "T": q + rng.int_in(1, 2), "vc": [1, -2 * p - q, p * p + 2 * p * q, -p * p * q]}
				return features(s)
			s = model(rng)
		"returns-to-start":
			var p := rng.int_in(1, 3)
			return {"fam": "poly", "A": rng.pick([1, 1, 2, -1]), "p": p, "q": p + rng.int_in(1, 5)}
		"max-velocity-quadratic":
			return quadratic(rng, -1)
		"max-velocity", "acceleration-at-max-speed", "max-acceleration":
			s = model(rng)
			if s.is_empty():
				return {}
			if ask == "max-velocity" and (s.tmax <= 0.0 or s.tmax >= float(s.T)):
				return {}
			# At a turning point of v the acceleration is 0, so this asks about an end.
			if ask == "acceleration-at-max-speed" and (s.ts > 0.0 and s.ts < float(s.T) or not GdcKit.fair(a_of(s).call(s.ts))):
				return {}
			if ask == "max-acceleration":
				return _max_a(s)
		"max-speed":
			s = quadratic(rng, 1) if paper == 1 else model(rng)
		"speed-from-graph", "acceleration-from-graph", "displacement-from-graph", "direction-from-graph":
			return pieces(rng)
		"velocity-from-graph":
			var d := position_pieces(rng)
			return d if d.ys.min() >= -8 else {}
	return s


## v or a equal to a value with one decimal place, at one time only (the first, for v).
static func _target(ask: String, paper: int, rng: Seeded) -> Dictionary:
	if paper == 1:
		var s := quadratic(rng)
		s.t0 = rng.int_in(1, s.T - 1)
		s.target = poly(diff(s.vc), float(s.t0))
		return s
	var s := model(rng)
	if s.is_empty():
		return {}
	var v := v_of(s)
	var a := a_of(s)
	var f: Callable = a if ask == "time-from-acceleration" else v
	var t: float = rng.int_in(5, 10 * (int(s.T) - 1)) / 10.0
	var c: float = snappedf(f.call(t), 0.1)
	var g := func(x: float) -> float: return f.call(x) - c
	var roots := GdcKit.zeros(g, 0.01, float(s.T) - 0.01)
	if roots.is_empty() or (ask == "time-from-acceleration" and roots.size() != 1) or not _fair_all(roots):
		return {}
	s.target = c
	s.roots = roots
	return s


static func _max_a(s: Dictionary) -> Dictionary:
	var a := a_of(s)
	var T := float(s.T)
	var ts: Array = [0.0, T] + GdcKit.zeros(j_of(s), 0.01, T - 0.01)
	s.amax = -INF
	for t in ts:
		var y: float = a.call(t)
		if y > s.amax:
			s.amax = y
			s.tamax = t
	return s if Answer.rounds_clearly(s.amax, 0.05) else {}


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
