class_name GdcCurveSituation
extends RefCounted
## The `gdc-curve` situation (curriculum/question-types.json): one awkward curve on a
## closed domain, whose zeros, turning points and endpoints only a GDC finds (FAL-420).
## fn-sketch-gdc and fn-gdc-features are built on it. Paper 2: every feature is found
## numerically (GdcKit) and asked to 3 s.f.
##
## generate() returns:
##   fam      the family: "explin" A·e^(bx) + mx + c, "cubic" Ax³ + bx² + mx + c,
##            "bell" A·e^(−kx²) + mx + c, "trig" A·sin(Bx) + mx + c (or cos),
##            "product" A(x + p)(x − q)e^(−kx), "xcubic" Ax³ + bx² + mx (x is a factor),
##            "log" A·ln(x + r) + mx + c, "bellform" A·e^(−k(x − h)²) + c
##   A, b, m, c, k, B, p, q, r, h     the family's coefficients, as Q (decimals)
##   co       the same as floats, [A, b, m, c, k, B, p, q, r, h], for evaluating
##   d1, d2   the domain d1 ≤ x ≤ d2 (whole numbers); in the log family d1 = −r and the
##            left end is left out (open): the asymptote x = −r
##   zeros    the zeros in the domain, in order (floats)
##   turns    the turning points inside it: [{"x", "y", "kind"}], kind "max" or "min"
##   ends     the endpoints: [[x, y], ...] (one in the log family)
##   hi, lo   the greatest and least values on the domain: {"x", "y", "at"} with at
##            "turn" or "end" (in the log family with A > 0 the least is {}: it runs to −∞)
##   mode     the mode it was drawn in
##   k_shift  (need.shift) the equation is f(x) + k_shift = k_shift, written with the
##            constant moved, so its solutions are f's zeros
##   table    (need.table) {"xs", "ys", "step"} at a fixed step across the domain
##   paper    2
##
## need (all optional): mode ("mixed", "product", "xfactor", "endpoint", "asymptote",
## "bellform", "far"; the angle factorised-read means product and read-from-form
## bellform), sketch (at most two zeros and a domain at most 8 wide, so a card shows it
## all), turn ("max", "min" or "any": a turning point of that kind; "max" also keeps the
## greatest value at that maximum unless the mode is endpoint), turn2 (two turning
## points), yint (0 is inside the domain and not near a zero), zeros (exactly that
## many), shift, table, far_ok (the far mode a third of the time), k2 (f(x) = k has
## exactly two solutions for one interval of k, GdcCurveViews.k_set).
##
## The clean limits are the checker's too (tools/check_answers.py, GC_*).

const TRIES := 3000
## The largest y-range of the curve on its domain (the catalogue's "about 20 units").
const Y_SPAN := 20.0
## Features at least this far apart in x.
const SEP := 0.5

const EXP_A := [1, 1.5, 2, 2.5, 3, 0.5]
const EXP_B := [0.5, 0.6, 0.8, 1, 1.2, -0.5, -0.6, -0.8, -1]
const EXP_M := [1, 1.5, 2, 2.5, 3, 4]
const BELL_A := [3, 4, 5, -3, -4]
const BELL_K := [0.5, 0.3, 1]
const SMALL_M := [0.4, 0.5, 0.6, 0.8, 1, -0.4, -0.5, -0.6, -0.8, -1]
const TRIG_A := [1.5, 2, 2.5, 3]
const TRIG_B := [1, 1.5, 2]
const FAR_B := [0.5, 0.6, 0.75]
const CUBIC_A := [0.5, 1, -0.5, -1, 0.2, -0.2]
const LOG_A := [2, 3, 4, -2, -3]
const LOG_M := [0.5, 1, 1.5]
const MIXED := ["explin", "cubic", "bell", "trig"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var mode: String = need.get("mode", "mixed")
	if mode == "any":
		mode = "mixed"
	match need.get("angle", ""):
		"factorised-read":
			# The x-factor mode has its factor x already; any other view gets the product.
			if mode == "mixed":
				mode = "product"
		"read-from-form":
			if mode == "mixed":
				mode = "bellform"
	# The far mode only where nothing else pins the zeros or a maximum down (a boss chain
	# that also asks for exactly two zeros).
	var far_free: bool = not need.has("zeros") and need.get("turn", "") != "max" and not need.get("sketch", false)
	if mode == "mixed" and need.get("far_ok", false) and far_free and rng.chance(1.0 / 3.0):
		mode = "far"
	# The family is drawn once, so families that are often unclean still come up as
	# often. An endpoint extreme needs a local maximum below an end (a bell or a cubic
	# makes one), and one interval of k with two solutions needs one turning point.
	var fams: Array = MIXED
	if mode == "endpoint":
		fams = ["bell", "cubic"]
	elif need.get("k2", false):
		fams = ["explin", "bell"]
	var fam: String = fams[rng.int_in(0, fams.size() - 1)] if mode in ["mixed", "endpoint"] else ""
	for i in TRIES:
		if i > 0 and i % 500 == 0 and fam != "":
			fam = fams[rng.int_in(0, fams.size() - 1)]
		var s := _draw(rng, mode, fam)
		if s.is_empty() or not _rough(s):
			continue
		_features(s)
		if _clean(s, mode, need):
			s.mode = mode
			s.paper = 2
			if need.get("shift", false):
				s.k_shift = Q.new([-4, -3, -2, 2, 3, 4, 5][rng.int_in(0, 6)])
			if need.get("table", false):
				s.table = _table(s)
			return s
	push_error("GdcCurveSituation: no clean situation for %s" % need)
	return {}


static func dq(v: float) -> Q:
	return Q.new(roundi(v * 10), 10)


static func _pick(rng: Seeded, items: Array) -> Q:
	return dq(float(items[rng.int_in(0, items.size() - 1)]))


## A decimal with one place from lo to hi.
static func _dec(rng: Seeded, lo: float, hi: float) -> Q:
	return Q.new(rng.int_in(roundi(lo * 10), roundi(hi * 10)), 10)


static func _draw(rng: Seeded, mode: String, fam: String = "") -> Dictionary:
	match mode:
		"product":
			fam = "product"
		"xfactor":
			fam = "xcubic"
		"asymptote":
			fam = "log"
		"bellform":
			fam = "bellform"
		"far":
			fam = "trig"
		_:
			if fam == "":
				fam = MIXED[rng.int_in(0, MIXED.size() - 1)]
	var z := Q.new(0)
	var s := {"fam": fam, "A": z, "b": z, "m": z, "c": z, "k": z, "B": z, "p": z, "q": z, "r": z, "h": z, "fn": ""}
	match fam:
		"explin":
			s.A = _pick(rng, EXP_A)
			if rng.chance(0.3):
				s.A = s.A.neg()
			s.b = _pick(rng, EXP_B)
			var sg: int = s.A.sign() * s.b.sign()
			s.m = _pick(rng, EXP_M).mul(-sg)
			s.c = Q.new(rng.int_in(-12, 12), 2)
			var xt: float = log(-s.m.to_float() / (s.A.to_float() * s.b.to_float())) / s.b.to_float()
			if absf(xt) > 4.0:
				return {}
			s.d1 = Q.new(floori(xt) - rng.int_in(1, 3))
			s.d2 = Q.new(ceili(xt) + rng.int_in(1, 3))
		"cubic":
			s.A = _pick(rng, CUBIC_A)
			s.b = _dec(rng, -2.0, 2.0)
			s.m = _dec(rng, -4.0, 4.0)
			s.c = _dec(rng, -4.0, 4.0)
			var a: float = s.A.to_float()
			var b: float = s.b.to_float()
			var cc: float = s.m.to_float()
			var disc := 4.0 * b * b - 12.0 * a * cc
			if disc <= 0.0:
				return {}
			var p := (-2.0 * b - sqrt(disc)) / (6.0 * a)
			var q := (-2.0 * b + sqrt(disc)) / (6.0 * a)
			var lo := minf(p, q)
			var hi := maxf(p, q)
			if hi - lo < 1.0 or hi - lo > 4.5 or absf(lo) > 4.0 or absf(hi) > 4.0:
				return {}
			s.d1 = Q.new(floori(lo) - rng.int_in(1, 2))
			s.d2 = Q.new(ceili(hi) + rng.int_in(1, 2))
		"bell":
			s.A = _pick(rng, BELL_A)
			s.k = _pick(rng, BELL_K)
			s.m = _pick(rng, SMALL_M)
			s.c = Q.new(rng.int_in(-6, 6), 2)
			s.d1 = Q.new(rng.int_in(-4, -2))
			s.d2 = Q.new(rng.int_in(2, 4))
		"trig":
			s.A = _pick(rng, TRIG_A)
			s.B = _pick(rng, FAR_B if mode == "far" else TRIG_B)
			s.m = _pick(rng, SMALL_M)
			s.c = Q.new(rng.int_in(-4, 4), 2)
			s.fn = "sin" if rng.chance(0.6) else "cos"
			if mode == "far":
				s.m = s.m.mul(Q.new(1, 2))
				s.d1 = Q.new(0)
				s.d2 = Q.new(rng.int_in(12, 14))
			else:
				s.d1 = Q.new(rng.int_in(-3, 0))
				s.d2 = s.d1.add(Q.new(rng.int_in(4, 6)))
		"product":
			s.A = _pick(rng, [0.5, 1, -0.5, -1, 0.2])
			s.p = Q.new(rng.int_in(1, 4))
			s.q = Q.new(rng.int_in(1, 5))
			s.k = dq(0.5)
			s.d1 = s.p.neg().sub(Q.new(1))
			s.d2 = s.q.add(Q.new(rng.int_in(2, 4)))
		"xcubic":
			s.A = _pick(rng, [1, -1, 0.5, -0.5, 0.25, -0.25])
			s.b = Q.new(rng.int_in(-3, 3))
			s.m = Q.new(rng.int_in(-8, 8))
			if s.m.is_zero():
				return {}
			# Ax² + bx + m has Δ = b² − 4Am, a whole number for these A.
			var disc: int = s.b.n * s.b.n - roundi(4.0 * s.A.to_float()) * s.m.n
			if disc <= 0:
				return {}
			var rt := roundi(sqrt(float(disc)))
			if rt * rt == disc:
				return {}
			var a: float = s.A.to_float()
			var r1: float = (-s.b.to_float() - sqrt(float(disc))) / (2.0 * a) if a > 0.0 else (-s.b.to_float() + sqrt(float(disc))) / (2.0 * a)
			var r2: float = (-s.b.to_float() + sqrt(float(disc))) / (2.0 * a) if a > 0.0 else (-s.b.to_float() - sqrt(float(disc))) / (2.0 * a)
			if r2 - r1 > 7.0:
				return {}
			s.d1 = Q.new(floori(minf(r1, 0.0) - 0.3) - rng.int_in(0, 1))
			s.d2 = Q.new(ceili(maxf(r2, 0.0) + 0.3) + rng.int_in(0, 1))
		"log":
			s.A = _pick(rng, LOG_A)
			s.r = Q.new(rng.int_in(1, 3))
			s.m = _pick(rng, LOG_M).mul(-s.A.sign())
			s.c = Q.new(rng.int_in(-6, 6), 2)
			var xt: float = -s.A.to_float() / s.m.to_float() - s.r.to_float()
			s.d1 = s.r.neg()
			s.d2 = Q.new(ceili(xt) + rng.int_in(2, 4))
		"bellform":
			s.A = _pick(rng, [3, 4, 5, 6])
			s.k = _pick(rng, [0.5, 0.8, 1])
			s.h = _dec(rng, -2.0, 3.0)
			if s.h.is_int():
				return {}
			s.c = Q.new(rng.int_in(-3, 1))
			s.d1 = Q.new(floori(s.h.to_float()) - rng.int_in(2, 3))
			s.d2 = Q.new(ceili(s.h.to_float()) + rng.int_in(2, 3))
	s.co = [s.A.to_float(), s.b.to_float(), s.m.to_float(), s.c.to_float(), s.k.to_float(), s.B.to_float(),
		s.p.to_float(), s.q.to_float(), s.r.to_float(), s.h.to_float()]
	return s


## f(x).
static func at(s: Dictionary, x: float) -> float:
	var co: Array = s.co
	match s.fam:
		"explin":
			return co[0] * exp(co[1] * x) + co[2] * x + co[3]
		"cubic":
			return ((co[0] * x + co[1]) * x + co[2]) * x + co[3]
		"bell":
			return co[0] * exp(-co[4] * x * x) + co[2] * x + co[3]
		"trig":
			var t: float = co[5] * x
			return co[0] * (sin(t) if s.fn == "sin" else cos(t)) + co[2] * x + co[3]
		"product":
			return co[0] * (x + co[6]) * (x - co[7]) * exp(-co[4] * x)
		"xcubic":
			return ((co[0] * x + co[1]) * x + co[2]) * x
		"log":
			var inside: float = x + co[8]
			if inside <= 0.0:
				return NAN
			return co[0] * log(inside) + co[2] * x + co[3]
		"bellform":
			var u: float = x - co[9]
			return co[0] * exp(-co[4] * u * u) + co[3]
	return NAN


## f′(x).
static func slope(s: Dictionary, x: float) -> float:
	var co: Array = s.co
	match s.fam:
		"explin":
			return co[0] * co[1] * exp(co[1] * x) + co[2]
		"cubic":
			return (3.0 * co[0] * x + 2.0 * co[1]) * x + co[2]
		"bell":
			return -2.0 * co[0] * co[4] * x * exp(-co[4] * x * x) + co[2]
		"trig":
			var t: float = co[5] * x
			var d: float = cos(t) if s.fn == "sin" else -sin(t)
			return co[0] * co[5] * d + co[2]
		"product":
			var p: float = co[6]
			var q: float = co[7]
			var k: float = co[4]
			return co[0] * exp(-k * x) * ((2.0 * x + p - q) - k * (x + p) * (x - q))
		"xcubic":
			return (3.0 * co[0] * x + 2.0 * co[1]) * x + co[2]
		"log":
			return co[0] / (x + co[8]) + co[2]
		"bellform":
			var u: float = x - co[9]
			return -2.0 * co[0] * co[4] * u * exp(-co[4] * u * u)
	return NAN


## Where the curve starts: d1, or just right of the asymptote in the log family.
static func lo_x(s: Dictionary) -> float:
	return s.d1.to_float() + (1e-3 if s.fam == "log" else 0.0)


static func open_left(s: Dictionary) -> bool:
	return s.fam == "log"


## A cheap first look before the root finding: 48 samples. The y-range fits the
## window, and f and f′ change sign about as often as a clean curve's would.
static func _rough(s: Dictionary) -> bool:
	var lo := lo_x(s) + (0.05 if open_left(s) else 0.0)
	var hi: float = s.d2.to_float()
	var top := -INF
	var bottom := INF
	var fz := 0
	var dz := 0
	var fp := 0.0
	var dp := 0.0
	for i in 49:
		var x := lo + (hi - lo) * i / 48.0
		var y := at(s, x)
		var dy := slope(s, x)
		if not is_finite(y):
			return false
		top = maxf(top, y)
		bottom = minf(bottom, y)
		if i > 0:
			if (y > 0.0) != (fp > 0.0):
				fz += 1
			if (dy > 0.0) != (dp > 0.0):
				dz += 1
		fp = y
		dp = dy
	if open_left(s):
		# The curve runs off towards the asymptote: the y-range is the rest of it.
		return fz >= 1 and fz <= 3 and dz >= 1 and dz <= 2
	return top - bottom <= Y_SPAN + 1.0 and top - bottom >= 2.0 and fz >= 1 and fz <= 3 and dz >= 1 and dz <= 2


static func _features(s: Dictionary) -> void:
	var f := func(x: float) -> float: return at(s, x)
	var df := func(x: float) -> float: return slope(s, x)
	var lo := lo_x(s)
	var hi: float = s.d2.to_float()
	var n := maxi(48, ceili((hi - lo) * 12.0))
	s.zeros = GdcKit.zeros(f, lo, hi, n)
	# Exact zeros where the family makes them: −p and q, or 0.
	if s.fam == "product":
		s.zeros = [s.p.neg().to_float(), s.q.to_float()].filter(func(z): return z >= lo and z <= hi)
	elif s.fam == "xcubic":
		s.zeros = s.zeros.map(func(z): return 0.0 if absf(z) < 1e-9 else z)
	s.turns = GdcKit.turns(f, df, lo, hi, n)
	if s.fam == "bellform":
		for t in s.turns:
			t.x = s.h.to_float()
			t.y = s.A.add(s.c).to_float()
	s.ends = [] if open_left(s) else [[s.d1.to_float(), at(s, s.d1.to_float())]]
	s.ends.append([hi, at(s, hi)])
	var cands: Array = []
	for t in s.turns:
		cands.append({"x": t.x, "y": t.y, "at": "turn"})
	for e in s.ends:
		cands.append({"x": e[0], "y": e[1], "at": "end"})
	var top: Dictionary = cands[0]
	var bottom: Dictionary = cands[0]
	for c in cands:
		if c.y > top.y:
			top = c
		if c.y < bottom.y:
			bottom = c
	s.hi = top
	s.lo = bottom if not open_left(s) or s.A.sign() < 0 else {}


static func _clean(s: Dictionary, mode: String, need: Dictionary) -> bool:
	var zs: Array = s.zeros
	var ts: Array = s.turns
	var lo: float = s.d1.to_float()
	var hi: float = s.d2.to_float()
	var exact_zeros: bool = s.fam in ["product", "xcubic"]
	if zs.size() < 1 or zs.size() > 3 or ts.size() < 1 or ts.size() > 2:
		return false
	if need.get("sketch", false) and (zs.size() > 2 or hi - lo > 8.0):
		return false
	if need.has("zeros") and zs.size() != int(need.zeros):
		return false
	if need.get("turn2", false) and ts.size() != 2:
		return false
	var want_turn: String = need.get("turn", "")
	if want_turn in ["max", "min"] and not ts.any(func(t): return t.kind == want_turn):
		return false
	for z in zs:
		if absf(slope(s, z)) < 0.25 or z - lo < 0.2 or hi - z < 0.2:
			return false
		if not exact_zeros and not GdcKit.fair(z):
			return false
		if s.fam == "xcubic" and z != 0.0 and not GdcKit.fair(z):
			return false
	for t in ts:
		if t.x - lo < 0.3 or hi - t.x < 0.3 or absf(t.y) < 0.4:
			return false
		if s.fam != "bellform" and not (GdcKit.fair(t.x) and GdcKit.fair(t.y)):
			return false
	# A cubic with decimal coefficients is exact at a whole-number end (3.4), which is
	# fine; anything else must be a fair 3 s.f. value.
	for e in s.ends:
		if absf(e[1]) < 0.3 or not (GdcKit.fair(e[1]) or (s.fam in ["cubic", "xcubic"] and absf(e[1] - roundf(e[1])) > 0.02)):
			return false
	# Features at least SEP apart in x: the zeros, the turning points and the y-intercept.
	var xs: Array = zs.duplicate()
	for t in ts:
		xs.append(t.x)
	xs.sort()
	for i in range(1, xs.size()):
		if xs[i] - xs[i - 1] < SEP:
			return false
	# In the far mode the domain starts at 0, so f(0) is its left end.
	if need.get("yint", false) and mode == "far" and absf(at(s, 0.0)) < 0.3:
		return false
	if need.get("yint", false) and mode != "far":
		if not (lo < -0.3 and hi > 0.3) or zs.any(func(z): return absf(z) < SEP) or absf(at(s, 0.0)) < 0.3:
			return false
	# The whole graph fits a window of about 20 units.
	var ys: Array = ts.map(func(t): return t.y) + s.ends.map(func(e): return e[1])
	var top: float = ys.max()
	var bottom: float = ys.min()
	if open_left(s):
		bottom = minf(bottom, at(s, lo + 0.05))
		top = maxf(top, at(s, lo + 0.05))
	if top - bottom > Y_SPAN or top - bottom < 2.5:
		return false
	match mode:
		"endpoint":
			# The greatest value is at an endpoint, above a local maximum.
			var maxes: Array = ts.filter(func(t): return t.kind == "max")
			if maxes.is_empty() or s.hi.at != "end" or s.hi.y - maxes[0].y < 0.5:
				return false
		"far":
			if not zs.any(func(z): return z > 10.2) or not zs.any(func(z): return z < 9.8):
				return false
		"xfactor":
			if zs.size() != 3 or not zs.has(0.0):
				return false
	if mode != "endpoint" and want_turn == "max" and s.hi.at == "end":
		return false
	if need.get("table", false) and _table(s).is_empty():
		return false
	# k-for-count: exactly two solutions for one interval of k.
	if need.get("k2", false) and GdcCurveViews.k_set(s, 2).is_empty():
		return false
	return true


## A GDC table across the domain: step 0.5 (or 1 on a wide domain), so each zero is a
## sign change between two rows, with no row at or next to a zero. {} if it can't be.
static func _table(s: Dictionary) -> Dictionary:
	var lo: float = s.d1.to_float()
	var hi: float = s.d2.to_float()
	var step := 0.5 if hi - lo <= 6.0 else 1.0
	var xs: Array = []
	var ys: Array = []
	var x := lo if not open_left(s) else lo + step
	while x <= hi + 1e-9:
		var y := at(s, x)
		if absf(y) < 0.05:
			return {}
		xs.append(dq(x))
		ys.append(GdcKit.qf(y))
		x += step
	if xs.size() > 13:
		return {}
	# Each zero alone between two rows.
	var used := {}
	for z in s.zeros:
		var i := floori((z - xs[0].to_float()) / step)
		if used.has(i) or i < 0 or i >= xs.size() - 1:
			return {}
		used[i] = true
	return {"xs": xs, "ys": ys, "step": dq(step)}


## The function as written: "2e^(0.5x) − 3x − 1". With shift, the constant has
## k_shift added (the left side of f(x) + k = k).
static func text(s: Dictionary, shift: Variant = null) -> String:
	var add: Q = Q.of(shift) if shift != null else Q.new(0)
	match s.fam:
		"explin":
			return GdcKit.first(s.A, "e^(%sx)" % GdcKit.lead(s.b)) + GdcKit.join(s.m, "x") + GdcKit.join(s.c.add(add), "")
		"cubic":
			return GdcKit.first(s.A, "x³") + GdcKit.join(s.b, "x²") + GdcKit.join(s.m, "x") + GdcKit.join(s.c.add(add), "")
		"bell":
			return GdcKit.first(s.A, "e^(−%sx²)" % GdcKit.lead(s.k)) + GdcKit.join(s.m, "x") + GdcKit.join(s.c.add(add), "")
		"trig":
			return GdcKit.first(s.A, "%s(%sx)" % [s.fn, GdcKit.lead(s.B)]) + GdcKit.join(s.m, "x") + GdcKit.join(s.c.add(add), "")
		"product":
			var body := "(x + %s)(x − %s)e^(−%sx)" % [Fmt.num(s.p), Fmt.num(s.q), GdcKit.lead(s.k)]
			return GdcKit.first(s.A, body) + GdcKit.join(add, "")
		"xcubic":
			return GdcKit.first(s.A, "x³") + GdcKit.join(s.b, "x²") + GdcKit.join(s.m, "x") + GdcKit.join(add, "")
		"log":
			return GdcKit.first(s.A, "ln(x + %s)" % Fmt.num(s.r)) + GdcKit.join(s.m, "x") + GdcKit.join(s.c.add(add), "")
		"bellform":
			var u := "x %s %s" % ["−" if s.h.sign() > 0 else "+", Fmt.dec(s.h.abs_q())]
			return GdcKit.first(s.A, "e^(−%s(%s)²)" % [GdcKit.lead(s.k), u]) + GdcKit.join(s.c.add(add), "")
	return "?"


## The domain as written: "−2 ≤ x ≤ 4", or "−2 < x ≤ 4" with the asymptote at the left.
static func domain_text(s: Dictionary) -> String:
	return "%s %s x ≤ %s" % [Fmt.num(s.d1), "<" if open_left(s) else "≤", Fmt.num(s.d2)]


## f(x) = … with its domain: "f(x) = 2e^(0.5x) − 3x − 1, for −2 ≤ x ≤ 4".
static func line(s: Dictionary) -> String:
	return "f(x) = %s, for %s" % [text(s), domain_text(s)]


static func export(s: Dictionary) -> Dictionary:
	var out: Dictionary = ExtensionViews.export(s)
	out.erase("co")
	return out
