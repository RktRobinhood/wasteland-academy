class_name AiQuadraticModelSituation
extends RefCounted
## The `ai-quadratic-model` situation (curriculum/question-types.json), FAL-1001: a quadratic
## model in context, for fn-ai-quadratic-model (AI-SL2.5.quadratic-model). Every AI paper allows
## a GDC, so every question is Paper 2.
##
## need.ask is the unknown, need.rep its representation and need.angle the method (see
## AiQuadraticModelViews). generate() returns a Dictionary:
##   paper, ask, rep, ctx   always 2; the unknown; the representation; the story (an index)
##   fam   "flight": h(t) = at² + bt + c, a ball, flare or rocket in metres and seconds, with
##                   a = −4.9 or −5; c > 0 (launched above the ground) unless `ground`
##         "arch":   y = a(x − p)(x − q), an arch over a canal or a road, feet at x = p and q
##         "path":   y = ax² + bx + c, a pack, a jet of water or a ball against horizontal distance x
##         "pen":    a rectangle with F m of fence, against a wall or free-standing
##   a, b, c   the model's coefficients (Q), for flight, arch and path
##   ground    flight: launched from the ground (c = 0), for the midpoint of the roots
##   level     time-at-height and width-above-height: the height k (Q) crossed twice
##   p, q      arch: the feet (whole numbers);  pts: axis-of-symmetry's words: "feet" or a
##             level `level` crossed at u and v (whole numbers)
##   d, w      clears-obstacle: the obstacle's distance (whole) and height (Q, 1 d.p.)
##   F, wall   pen: the fence's length (whole m) and whether a wall makes one side
##
## The numbers are drawn, not taken from any exam question. The SymPy checker
## (tools/check_answers.py, r3qu_check) reads every value back from what the question shows and
## works it out again.

const TRIES := 4000
## Story counts: AiQuadraticModelViews' lists are this long.
const FLIGHTS := 4
const GROUND_FLIGHTS := 2
const ARCHES := 3
const PATHS := 3
const PENS := 3
## A 3 s.f. value is at least this far (a fraction of its last place) from a rounding edge.
const EDGE := 0.04


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "vertex-value")
	var rep: String = need.get("rep", "")
	var angle: String = need.get("angle", "any")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "rep": rep, "angle": angle}
		if _draw(rng, s):
			return s
	push_error("AiQuadraticModelSituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"initial-height", "vertex-value", "landing-time":
			return _flight(rng, s, false)
		"time-of-vertex":
			return _flight(rng, s, s.angle == "midpoint-of-roots")
		"time-at-height":
			return _flight(rng, s, false) and _level(rng, s)
		"axis-of-symmetry":
			return _arch(rng, s, false)
		"width-above-height":
			return _arch(rng, s, true)
		"clears-obstacle":
			return _path(rng, s)
		"build-area-model":
			return _pen(rng, s)
	return false


# ── Small tools ──────────────────────────────────────────────

static func clear(x: float) -> bool:
	return Answer.rounds_clearly(x, EDGE)


## A value as an option shows it: as it is when it ends within 3 s.f., else to 3 s.f.
static func short(v: Q) -> Q:
	return v if not Answer.needs_rounding(v) else GraphReadingSituation.sf_q(v, 3)


## How a value reads beside an answer that is exact (Fmt.dec of short) or to 3 s.f.
static func reads(v: Q, sf: bool) -> String:
	return Fmt.sf(v) if sf else Fmt.dec(short(v))


## The key and its slips read apart, and each one that needs rounding is clear of an edge.
static func apart(key: Q, others: Array) -> bool:
	var sf := Answer.needs_rounding(key)
	var seen := {}
	for v: Q in [key] + others:
		if Answer.needs_rounding(v) and not clear(v.to_float()):
			return false
		seen[reads(v, sf)] = true
	return seen.size() == others.size() + 1


static func value(s: Dictionary, x: Q) -> Q:
	return s.a.mul(x.sq()).add(s.b.mul(x)).add(s.c)


static func valuef(s: Dictionary, x: float) -> float:
	return s.a.to_float() * x * x + s.b.to_float() * x + s.c.to_float()


## The vertex: [T, H], exact.
static func vertex(s: Dictionary) -> Array:
	var T: Q = s.b.neg().div(s.a.mul(2))
	return [T, value(s, T)]


## The two roots of model = k, smaller first.
static func crossings(s: Dictionary, k: float = 0.0) -> Array:
	var a: float = s.a.to_float()
	var b: float = s.b.to_float()
	var c: float = s.c.to_float() - k
	var r := sqrt(b * b - 4.0 * a * c)
	var x1 := (-b + r) / (2.0 * a)
	var x2 := (-b - r) / (2.0 * a)
	return [minf(x1, x2), maxf(x1, x2)]


static func dq(rng: Seeded, lo: int, hi: int, scale: int) -> Q:
	return Q.new(rng.int_in(lo, hi), scale)


# ── A flight in time ─────────────────────────────────────────

static func _flight(rng: Seeded, s: Dictionary, ground: bool) -> bool:
	s.fam = "flight"
	s.ground = ground
	s.ctx = rng.int_in(0, (GROUND_FLIGHTS if ground else FLIGHTS) - 1)
	s.a = Q.new(-49, 10) if rng.chance(0.6) else Q.new(-5)
	s.b = dq(rng, 60, 240, 10)
	s.c = Q.new(0) if ground else dq(rng, 10, 350, 10)
	var v := vertex(s)
	var T: Q = v[0]
	var H: Q = v[1]
	if H.to_float() > 70.0 or T.to_float() < 0.6:
		return false
	var z := crossings(s)
	var land: float = z[1]
	var neg: float = z[0]
	var twice: Q = T.mul(2)
	match s.ask:
		"initial-height":
			# The start, the peak for it, b and h(1) read apart.
			return apart(s.c, [H, s.b, value(s, Q.new(1))])
		"vertex-value":
			# The peak; the time of the peak, the peak from t = b/(2a) and the start for it.
			return apart(H, [T, value(s, T.neg()), s.c])
		"time-of-vertex":
			return apart(T, [H, T.neg(), twice, T.div(2)]) and (not ground or apart(T, [GdcKit.qf(land)]))
		"landing-time":
			var L := GdcKit.qf(land)
			return clear(neg) and GdcKit.fair(land) and apart(L, [GdcKit.qf(neg), T, twice]) and neg < -0.05
		"time-at-height":
			return true
	return false


## A level between the start and the peak, crossed twice, the later crossing asked.
static func _level(rng: Seeded, s: Dictionary) -> bool:
	var v := vertex(s)
	var H: float = v[1].to_float()
	var c: float = s.c.to_float()
	var lo := ceili(c + 1.0)
	var hi := floori(H - 1.0)
	if hi < lo:
		return false
	s.level = Q.new(rng.int_in(lo, hi)) if rng.chance(0.6) or hi - lo > 8 else dq(rng, lo * 10, hi * 10, 10)
	var z := crossings(s, s.level.to_float())
	var t1: float = z[0]
	var t2: float = z[1]
	var land: float = crossings(s)[1]
	if t2 - t1 < 0.3 or t1 < 0.15:
		return false
	return GdcKit.fair(t2) and clear(t1) and apart(GdcKit.qf(t2), [GdcKit.qf(t1), v[0], GdcKit.qf(land)])


# ── An arch ──────────────────────────────────────────────────

## y = a(x − p)(x − q): the feet at whole p < q, a to 2 or 3 d.p., the top a tidy height.
static func _arch(rng: Seeded, s: Dictionary, width: bool) -> bool:
	s.fam = "arch"
	s.ctx = rng.int_in(0, ARCHES - 1)
	var r := rng.int_in(4, 15)
	var form := rng.int_in(0, 2)
	# The left foot at 0, the arch centred on x = 0 (not for the axis: −b/(2a) would be 0 either
	# way) or the feet measured from a post some way off.
	if form == 1 and not width:
		form = 2
	var p := 0 if form == 0 else (-r if form == 1 else rng.int_in(1, 8))
	s.form = form
	s.p = p
	s.q = p + 2 * r
	s.a = Q.new(-rng.int_in(2, 60), 100) if rng.chance(0.7) else Q.new(-rng.int_in(5, 120), 1000)
	s.b = s.a.mul(-(s.p + s.q))
	s.c = s.a.mul(s.p * s.q)
	var H: Q = s.a.neg().mul(r * r)
	if H.to_float() < 3.0 or H.to_float() > 25.0 or Answer.needs_rounding(H):
		return false
	var m := Q.new(s.p + s.q, 2)
	if width:
		var Hf := H.to_float()
		s.level = Q.new(rng.int_in(1, floori(Hf - 1.0))) if rng.chance(0.5) else dq(rng, 10, floori((Hf - 1.0) * 10.0), 10)
		if s.level.to_float() >= Hf - 0.8:
			return false
		var z := crossings(s, s.level.to_float())
		var wd: float = z[1] - z[0]
		return GdcKit.fair(wd) and apart(GdcKit.qf(wd), width_slips(s))
	# Two points at the same height: the feet, or a level crossed at whole u and v.
	s.pts = "feet" if rng.chance(0.5) else "level"
	if s.pts == "level":
		var e := rng.int_in(1, r - 1)
		s.u = s.p + e
		s.v = s.q - e
		s.level = value(s, Q.new(s.u))
		if Answer.needs_rounding(s.level):
			return false
	return apart(m, [m.neg(), H, Q.new(s.q - s.p)]) and not m.is_zero()


# ── A path over an obstacle ──────────────────────────────────

static func _path(rng: Seeded, s: Dictionary) -> bool:
	s.fam = "path"
	s.ctx = rng.int_in(0, PATHS - 1)
	s.a = Q.new(-rng.int_in(1, 30), 100)
	s.b = dq(rng, 3, 25, 10)
	s.c = Q.new(0) if s.ctx == 2 and rng.chance(0.5) else dq(rng, 5, 30, 10)
	var v := vertex(s)
	var H: float = v[1].to_float()
	var land: float = crossings(s)[1]
	if H < 3.0 or H > 20.0 or land < 8.0 or land > 60.0 or not GdcKit.fair(land):
		return false
	s.d = rng.int_in(2, floori(land) - 1)
	var at := value(s, Q.new(s.d))
	var atf := at.to_float()
	if atf < 0.8 or absf(float(s.d) - v[0].to_float()) < 1.0:
		return false
	# Over or under by at least 0.2 m, and the peak above the obstacle either way.
	var over := rng.chance(0.5)
	var w10 := roundi(atf * 10.0) + (-rng.int_in(2, 15) if over else rng.int_in(2, 15))
	s.w = Q.new(w10, 10)
	var w: float = s.w.to_float()
	if w < 1.0 or H - w < 0.5 or absf(atf - w) < 0.2 or absf(w - s.c.to_float()) < 0.2:
		return false
	return clear(H) or not Answer.needs_rounding(v[1])


# ── A pen from a fixed fence ─────────────────────────────────

static func _pen(rng: Seeded, s: Dictionary) -> bool:
	s.fam = "pen"
	s.ctx = rng.int_in(0, PENS - 1)
	s.wall = rng.chance(0.5)
	s.F = 4 * rng.int_in(6, 40)
	return true


## width-above-height's other values: half the width (the slip), then the fillers: the span at
## the ground, the drop from the top to the level and, off the centre, the right-hand crossing.
static func width_slips(s: Dictionary) -> Array:
	var z := crossings(s, s.level.to_float())
	var wd: float = z[1] - z[0]
	var H: Q = vertex(s)[1]
	var out: Array = [GdcKit.qf(wd / 2.0), Q.new(s.q - s.p), H.sub(s.level)]
	if s.form != 1:
		out.append(GdcKit.qf(z[1]))
	return out


## A pen's area: [a, b] of A(x) = ax² + bx, with x the width (at right angles to the wall).
static func pen_area(s: Dictionary) -> Array:
	return [Q.new(-2), Q.new(s.F)] if s.wall else [Q.new(-1), Q.new(s.F / 2)]


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
