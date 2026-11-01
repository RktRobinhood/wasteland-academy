class_name GdcCombinedSituation
extends RefCounted
## The `gdc-combined` situation (curriculum/question-types.json): the two-curves
## situation plus a function made from them, whose extreme or zero the GDC finds
## (FAL-420). It extends gdc-two-curves: its curves are GdcTwoCurvesSituation curves,
## evaluated and written by that recipe. fn-gdc-optimise-combined is built on it.
## Paper 2: every value to 3 s.f.
##
## generate() returns what gdc-two-curves does (mode, f, g, var, d1, d2, ctx, paper),
## with mode one of
##   "difference"  two models of time t and D(t), how far one is ahead of the other:
##                 kind "towns" (P(t) = pe^(kt) against Q(t) = q + rt, D = Q − P, which
##                 P overtakes) or "drugs" (A(t) = a·te^(−kt) against B(t) = b·te^(−mt),
##                 D = A − B)
##   "distance"    a curve y = f(x) and a point P, d(x) the distance from P to the curve
##   "sum"         S(x) = f(x) + g(x)
## and
##   ext       the greatest D, least d, or (sum) nothing: {"x", "y"}, strictly inside
##   zeros     the zeros of D or S on the domain (floats)
##   outside   (towns) the zero of D before t = 0
##   P         (distance) [x0, y0], whole numbers
##   table     (need.table, towns) {"xs", "fs", "gs"} at whole years
##
## need (all optional): mode, kind ("towns" or "drugs"), zero (D has a zero on the
## domain), table.

const TRIES := 3000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	# The stream's first draw leans low (FAL-460), so it is spent first.
	rng.int_in(0, 1)
	var mode: String = need.get("mode", "difference")
	if mode == "any":
		mode = "difference"
	var kind: String = need.get("kind", "any")
	if kind == "any":
		kind = "towns" if need.get("zero", false) or need.get("table", false) or rng.chance(0.6) else "drugs"
	for i in TRIES:
		var s := _draw(rng, mode, kind)
		if s.is_empty():
			continue
		if _clean(s, need):
			s.paper = 2
			if need.get("table", false):
				s.table = _table(s)
			return s
	push_error("GdcCombinedSituation: no clean situation for %s" % need)
	return {}


static func dq(v: float) -> Q:
	return GdcTwoCurvesSituation.dq(v)


static func _pick(rng: Seeded, items: Array) -> Q:
	return dq(float(items[rng.int_in(0, items.size() - 1)]))


## The combined function at x: D, d or S.
static func at(s: Dictionary, x: float) -> float:
	var f: float = GdcTwoCurvesSituation.at(s.f, x)
	var g: float = GdcTwoCurvesSituation.at(s.g, x)
	match s.mode:
		"difference":
			return g - f if s.kind == "towns" else f - g
		"distance":
			return sqrt(pow(x - s.P[0], 2) + pow(f - s.P[1], 2))
		"sum":
			return f + g
	return NAN


static func slope(s: Dictionary, x: float) -> float:
	var df: float = GdcTwoCurvesSituation.slope(s.f, x)
	var dg: float = GdcTwoCurvesSituation.slope(s.g, x)
	match s.mode:
		"difference":
			return dg - df if s.kind == "towns" else df - dg
		"distance":
			var f: float = GdcTwoCurvesSituation.at(s.f, x)
			return ((x - s.P[0]) + (f - s.P[1]) * df) / maxf(at(s, x), 1e-12)
		"sum":
			return df + dg
	return NAN


static func _draw(rng: Seeded, mode: String, kind: String) -> Dictionary:
	var C = GdcTwoCurvesSituation
	var s := {"mode": mode, "kind": kind, "var": "x"}
	match mode:
		"difference":
			s.var = "t"
			s.d1 = Q.new(0)
			s.d2 = Q.new(rng.int_in(8, 15))
			if kind == "towns":
				var p0 := rng.int_in(2, 6)
				s.f = C.curve("explin", {"A": Q.new(p0), "b": _pick(rng, [0.1, 0.12, 0.15, 0.2, 0.25])})
				s.g = C.line(_pick(rng, [0.5, 0.8, 1, 1.2, 1.5, 2]), Q.new(p0 + rng.int_in(2, 8)))
				s.ctx = {"kind": "towns", "f": "P", "g": "Q", "x_unit": "years", "y_unit": "thousand"}
			else:
				s.d2 = Q.new(rng.int_in(6, 10))
				s.f = C.curve("texp", {"A": Q.new(rng.int_in(4, 12)), "k": _pick(rng, [0.3, 0.4, 0.5, 0.6])})
				s.g = C.curve("texp", {"A": Q.new(rng.int_in(2, 8)), "k": _pick(rng, [0.2, 0.25, 0.3])})
				s.ctx = {"kind": "drugs", "f": "A", "g": "B", "x_unit": "hours", "y_unit": "mg/l"}
		"distance":
			var fam: String = ["explin", "log", "explin"][rng.int_in(0, 2)]
			if fam == "explin":
				s.f = C.curve("explin", {"A": _pick(rng, [0.5, 1, 2]), "b": _pick(rng, [0.5, 0.8, 1, -0.5, -1]), "c": Q.new(rng.int_in(-6, 6), 2)})
				s.d1 = Q.new(rng.int_in(-4, -2))
			else:
				s.f = C.curve("log", {"A": _pick(rng, [1, 2, 1.5]), "r": Q.new(rng.int_in(1, 3)), "c": Q.new(rng.int_in(-4, 4), 2)})
				s.d1 = Q.new(1).sub(s.f.r)
			s.d2 = s.d1.add(Q.new(rng.int_in(5, 7)))
			s.g = C.line(Q.new(0), Q.new(0))
			s.P = [rng.int_in(-2, 3), rng.int_in(-2, 3)] if rng.chance(0.5) else [0, 0]
		"sum":
			s.d1 = Q.new(rng.int_in(-3, 0))
			s.d2 = s.d1.add(Q.new(rng.int_in(5, 7)))
			s.f = C.curve("trig", {"A": _pick(rng, [1.5, 2, 2.5]), "B": _pick(rng, [1, 1.5]), "fn": "sin" if rng.chance(0.5) else "cos"})
			s.g = C.line(_pick(rng, [0.5, -0.5, 0.8, -0.8, 1, -1]), Q.new(rng.int_in(-6, 6), 2))
	return s


static func _clean(s: Dictionary, need: Dictionary) -> bool:
	var lo: float = s.d1.to_float()
	var hi: float = s.d2.to_float()
	var h := func(x: float) -> float: return at(s, x)
	var dh := func(x: float) -> float: return slope(s, x)
	var n := maxi(64, ceili((hi - lo) * 16.0))
	# Two drugs both start at 0, so D(0) = 0 is not a zero to ask about.
	var from := lo + (1e-6 if s.get("kind", "") == "drugs" and s.mode == "difference" else 0.0)
	s.zeros = GdcKit.zeros(h, from, hi, n) if s.mode != "distance" else []
	for z in s.zeros:
		if absf(slope(s, z)) < 0.3 or z - lo < 0.2 or hi - z < 0.2 or not GdcKit.fair(z):
			return false
	if need.get("zero", false) and s.zeros.size() != 1:
		return false
	match s.mode:
		"difference", "distance":
			var turns := GdcKit.turns(h, dh, lo, hi, n)
			var want := "max" if s.mode == "difference" else "min"
			var ext: Array = turns.filter(func(t): return t.kind == want)
			if ext.size() != 1:
				return false
			var e: Dictionary = ext[0]
			if e.x - lo < 0.4 or hi - e.x < 0.4 or not (GdcKit.fair(e.x) and GdcKit.fair(e.y)) or absf(e.y) < 1.0:
				return false
			# The extreme is the greatest (least) on the domain, not an end.
			for x in [lo, hi]:
				if (s.mode == "difference" and at(s, x) > e.y) or (s.mode == "distance" and at(s, x) < e.y):
					return false
			s.ext = {"x": e.x, "y": e.y}
			if s.mode == "difference":
				# Clear of each model's own maximum, so "f at its own maximum" is another number.
				for c in [s.f, s.g]:
					if c.fam == "texp" and absf(1.0 / c.co[4] - e.x) < 0.5:
						return false
				if s.kind == "towns":
					var before := GdcKit.zeros(h, -20.0, 0.0, 320)
					if before.size() != 1 or not GdcKit.fair(before[0]):
						return false
					s.outside = before[0]
					# Both start above 0, and P overtakes Q inside the domain.
					if s.zeros.size() != 1:
						return false
			else:
				var y: float = GdcTwoCurvesSituation.at(s.f, e.x)
				if not (GdcKit.fair(y)):
					return false
				s.closest = [e.x, y]
		"sum":
			if s.zeros.size() < 1 or s.zeros.size() > 3:
				return false
			for i in range(1, s.zeros.size()):
				if s.zeros[i] - s.zeros[i - 1] < 0.5:
					return false
			# f and g have zeros of their own, so "the zeros of each" is another answer.
			var fz := GdcKit.zeros(func(x: float) -> float: return GdcTwoCurvesSituation.at(s.f, x), lo, hi, n)
			var gz := GdcKit.zeros(func(x: float) -> float: return GdcTwoCurvesSituation.at(s.g, x), lo, hi, n)
			if fz.is_empty() or (fz + gz).any(func(z): return not GdcKit.fair(z)):
				return false
			s.f_zeros = fz
			s.g_zeros = gz
			var ys: Array = []
			for j in 25:
				ys.append(at(s, lo + (hi - lo) * j / 24.0))
			if ys.max() - ys.min() > 16.0:
				return false
	if need.get("table", false) and _table(s).is_empty():
		return false
	return true


## The towns' populations at whole years, so the year P first leads is a row.
static func _table(s: Dictionary) -> Dictionary:
	if s.kind != "towns":
		return {}
	var hi := mini(int(s.d2.n), 12)
	var xs: Array = []
	var fs: Array = []
	var gs: Array = []
	for t in hi + 1:
		if absf(at(s, float(t))) < 0.05:
			return {}
		xs.append(Q.new(t))
		fs.append(GdcKit.qf(GdcTwoCurvesSituation.at(s.f, t)))
		gs.append(GdcKit.qf(GdcTwoCurvesSituation.at(s.g, t)))
	if s.zeros.is_empty() or s.zeros[0] > hi:
		return {}
	return {"xs": xs, "fs": fs, "gs": gs}


static func export(s: Dictionary) -> Dictionary:
	return GdcTwoCurvesSituation.export(s)
