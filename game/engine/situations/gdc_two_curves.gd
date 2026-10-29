class_name GdcTwoCurvesSituation
extends RefCounted
## The `gdc-two-curves` situation (curriculum/question-types.json): two functions from
## different families that cross one to three times, so the crossings need the GDC
## (FAL-420). fn-gdc-intersection is built on it, and `gdc-combined` extends it.
## Paper 2: every crossing is found numerically (GdcKit) and asked to 3 s.f., each y
## from the unrounded x.
##
## Each function is a curve: a gdc-curve family (GdcCurveSituation: "explin", "cubic",
## "trig", "log", "bell", with its coefficients as Q and their floats in `co`) or a
## "line" mx + c (m and c). generate() returns:
##   mode       "line" (a curve and a line), "context" (two models of time t ≥ 0),
##              "inverse" (f(x) = e^(bx) + c and f⁻¹(x) = (1/b) ln(x − c)), "far"
##              (one crossing past x = 10, outside the standard window)
##   f, g       the two curves
##   var        "x", or "t" in context
##   d1, d2     the domain (whole numbers; in the inverse mode d1 is f⁻¹'s asymptote, left out)
##   crossings  [[x, y], ...] in order of x, inside the domain
##   ctx        (context) {"kind": "tanks" or "populations", "f", "g": the models' names,
##              "x_unit", "y_unit", "what"}
##   table      (need.table) {"xs", "fs", "gs", "step"} at a fixed step
##   paper      2
##
## need (all optional): mode, crossings (exactly that many), table, at0 (the line
## passes through the curve's point at x = 0, for a constant fixed by one crossing),
## one_in (context: exactly one crossing inside the domain), far_ok (the far mode a
## third of the time, where nothing else pins the crossings down; in context, two towns
## that meet twice, the second time past t = 10).

const TRIES := 3000
const SEP := 0.5

const EXP_A := [1, 1.5, 2, 2.5, 3, 0.5]
const EXP_B := [0.5, 0.6, 0.8, 1, -0.5, -0.6, -0.8, -1]
const TRIG_A := [1.5, 2, 2.5, 3]
const TRIG_B := [1, 1.5, 2]
const CUBIC_A := [0.5, 1, -0.5, -1, 0.2, -0.2]
const LINE_M := [0.5, 1, 1.5, 2, -0.5, -1, -1.5, -2, 0.4, -0.4]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	# The stream's first draw leans low (FAL-460), so it is spent first.
	rng.int_in(0, 1)
	var mode: String = need.get("mode", "line")
	if mode == "any":
		mode = "line"
	# far_ok: a third of the time, one crossing is past x = 10 (SL2.4.intersection#1).
	var far_free: bool = need.get("far_ok", false) and not need.has("crossings") and not need.get("at0", false) \
			and not need.get("table", false)
	var far_ctx := false
	if far_free and rng.chance(1.0 / 3.0):
		if mode == "line":
			mode = "far"
		elif mode == "context":
			far_ctx = true
	need = need.duplicate()
	need.far_ctx = far_ctx
	for i in TRIES:
		var s := _draw(rng, mode, need)
		if s.is_empty():
			continue
		s.crossings = crossings(s, lo_x(s), s.d2.to_float())
		if _clean(s, need):
			s.mode = mode
			s.paper = 2
			if need.get("table", false):
				s.table = _table(s)
			return s
	push_error("GdcTwoCurvesSituation: no clean situation for %s" % need)
	return {}


static func dq(v: float) -> Q:
	return Q.new(roundi(v * 10), 10)


static func _pick(rng: Seeded, items: Array) -> Q:
	return dq(float(items[rng.int_in(0, items.size() - 1)]))


static func _dec(rng: Seeded, lo: float, hi: float) -> Q:
	return Q.new(rng.int_in(roundi(lo * 10), roundi(hi * 10)), 10)


## A curve of a family, the coefficients it doesn't give 0.
static func curve(fam: String, vals: Dictionary) -> Dictionary:
	var z := Q.new(0)
	var c := {"fam": fam, "A": z, "b": z, "m": z, "c": z, "k": z, "B": z, "p": z, "q": z, "r": z, "h": z, "fn": ""}
	c.merge(vals, true)
	c.co = [c.A.to_float(), c.b.to_float(), c.m.to_float(), c.c.to_float(), c.k.to_float(), c.B.to_float(),
		c.p.to_float(), c.q.to_float(), c.r.to_float(), c.h.to_float()]
	return c


static func line(m: Q, n: Q) -> Dictionary:
	return curve("line", {"m": m, "c": n})


static func at(c: Dictionary, x: float) -> float:
	if c.fam == "line":
		return c.co[2] * x + c.co[3]
	return GdcCurveSituation.at(c, x)


static func slope(c: Dictionary, x: float) -> float:
	if c.fam == "line":
		return c.co[2]
	return GdcCurveSituation.slope(c, x)


## A curve as written, in x or t: "2e^(0.5x) − 1", "1.5x + 2".
static func text(c: Dictionary, v: String = "x") -> String:
	var out: String
	if c.fam == "line":
		out = GdcKit.first(c.m, "x") + GdcKit.join(c.c, "") if not c.m.is_zero() else Fmt.dec(c.c)
	else:
		out = GdcCurveSituation.text(c)
	return out.replace("x", v) if v != "x" else out


## Where the curves start: d1, or just right of f⁻¹'s asymptote.
static func lo_x(s: Dictionary) -> float:
	return s.d1.to_float() + (1e-3 if s.mode == "inverse" else 0.0)


static func h(s: Dictionary, x: float) -> float:
	return at(s.f, x) - at(s.g, x)


## The crossings of f and g on [lo, hi]: [[x, y], ...].
static func crossings(s: Dictionary, lo: float, hi: float) -> Array:
	var d := func(x: float) -> float: return at(s.f, x) - at(s.g, x)
	return GdcKit.zeros(d, lo, hi, maxi(64, ceili((hi - lo) * 16.0))).map(func(x): return [x, at(s.f, x)])


static func _draw(rng: Seeded, mode: String, need: Dictionary) -> Dictionary:
	var s := {"mode": mode, "var": "x"}
	match mode:
		"line":
			var fam: String = ["explin", "cubic", "trig", "log"][rng.int_in(0, 3)]
			match fam:
				"explin":
					s.f = curve("explin", {"A": _pick(rng, EXP_A), "b": _pick(rng, EXP_B), "c": Q.new(rng.int_in(-8, 4), 2)})
				"cubic":
					s.f = curve("cubic", {"A": _pick(rng, CUBIC_A), "b": _dec(rng, -1.5, 1.5), "m": _dec(rng, -3.0, 3.0), "c": _dec(rng, -3.0, 3.0)})
				"trig":
					s.f = curve("trig", {"A": _pick(rng, TRIG_A), "B": _pick(rng, TRIG_B), "c": Q.new(rng.int_in(-4, 4), 2),
						"fn": "sin" if rng.chance(0.6) else "cos"})
				"log":
					s.f = curve("log", {"A": _pick(rng, [1, 2, 3, 1.5]), "r": Q.new(rng.int_in(1, 3)), "c": Q.new(rng.int_in(-4, 4), 2)})
			s.d1 = Q.new(rng.int_in(-3, 0)) if fam != "log" else Q.new(1).sub(s.f.r)
			s.d2 = s.d1.add(Q.new(rng.int_in(5, 8)))
			if need.get("at0", false):
				# The line meets the curve at x = 0, so its constant is f(0), exact.
				if fam == "log" or s.d1.sign() >= 0:
					return {}
				var m := _pick(rng, LINE_M)
				s.g = line(m, f0(s.f))
			else:
				s.g = line(_pick(rng, LINE_M), Q.new(rng.int_in(-8, 8), 2))
		"context":
			s.var = "t"
			s.d1 = Q.new(0)
			s.d2 = Q.new(rng.int_in(8, 15))
			if need.get("far_ctx", false):
				# Two towns that meet twice, the second time past t = 10: P starts ahead,
				# Q overtakes it, then P's growth catches up (SL2.10.solve-gdc#0).
				var p0 := rng.int_in(4, 10)
				s.d2 = Q.new(rng.int_in(13, 15))
				s.f = curve("explin", {"A": Q.new(p0), "b": _pick(rng, [0.08, 0.1, 0.12, 0.15])})
				s.g = line(_pick(rng, [0.5, 0.8, 1, 1.2, 1.5, 2]), Q.new(p0 - rng.int_in(1, 3)))
				s.ctx = {"kind": "populations", "f": "P", "g": "Q", "x_unit": "years", "y_unit": "thousand", "what": "population"}
			elif rng.chance(0.5):
				# Tank A drains towards a level, tank B fills at a steady rate (metres, hours).
				s.f = curve("explin", {"A": Q.new(rng.int_in(6, 14)), "b": _pick(rng, [-0.15, -0.2, -0.25, -0.3, -0.4]),
					"c": Q.new(rng.int_in(1, 4))})
				s.g = line(_pick(rng, [0.4, 0.5, 0.6, 0.8, 1, 1.2]), Q.new(rng.int_in(0, 3)))
				s.ctx = {"kind": "tanks", "f": "A", "g": "B", "x_unit": "hours", "y_unit": "m", "what": "depth of water"}
			else:
				# A population growing exponentially against one growing steadily (thousands, years).
				s.f = curve("explin", {"A": Q.new(rng.int_in(2, 6)), "b": _pick(rng, [0.1, 0.15, 0.2, 0.25])})
				s.g = line(_pick(rng, [0.5, 0.8, 1, 1.2, 1.5, 2]), Q.new(rng.int_in(5, 12)))
				s.ctx = {"kind": "populations", "f": "P", "g": "Q", "x_unit": "years", "y_unit": "thousand", "what": "population"}
		"inverse":
			var b := _pick(rng, [0.5, 1, 0.8])
			var c := _pick(rng, [-1.5, -2, -2.5, -3, -3.5])
			s.f = curve("explin", {"A": Q.new(1), "b": b, "c": c})
			# f⁻¹(x) = (1/b) ln(x − c).
			s.g = curve("log", {"A": Q.new(1).div(b), "r": c.neg()})
			s.d1 = c
			s.d2 = Q.new(rng.int_in(4, 6))
		"far":
			s.f = curve("explin", {"A": _pick(rng, [0.5, 0.2, 0.3, 1]), "b": _pick(rng, [0.25, 0.3, 0.35, 0.4])})
			s.g = line(_pick(rng, [1, 1.5, 2, 2.5, 3]), Q.new(rng.int_in(-4, 6), 2))
			s.d1 = Q.new(rng.int_in(-4, -2))
			s.d2 = Q.new(16)
	return s


## f(0) exactly, for the families whose value at 0 is a decimal.
static func f0(c: Dictionary) -> Q:
	match c.fam:
		"explin":
			return c.A.add(c.c)
		"cubic":
			return c.c
		"trig":
			return c.c if c.fn == "sin" else c.A.add(c.c)
	return Q.new(0)


static func _clean(s: Dictionary, need: Dictionary) -> bool:
	var cs: Array = s.crossings
	var lo: float = s.d1.to_float()
	var hi: float = s.d2.to_float()
	if cs.size() < 1 or cs.size() > 3:
		return false
	if need.has("crossings") and cs.size() != int(need.crossings):
		return false
	for i in cs.size():
		var x: float = cs[i][0]
		var y: float = cs[i][1]
		# A clear angle, away from the domain's ends, and fair 3 s.f. values.
		if absf(slope(s.f, x) - slope(s.g, x)) < 0.3 or x - lo < 0.2 or hi - x < 0.2:
			return false
		# The crossing at x = 0 that fixes the constant is exact.
		var given: bool = need.get("at0", false) and absf(x) < 1e-9
		if not given and not (GdcKit.fair(x) and GdcKit.fair(y)):
			return false
		if i > 0 and x - cs[i - 1][0] < SEP:
			return false
	match s.mode:
		"far":
			var far: Array = cs.filter(func(c): return c[0] > 10.3)
			if far.size() != 1 or cs.size() < 2 or far[0][0] > 15.5 or cs.any(func(c): return c[0] < 10.3 and c[0] > 9.0):
				return false
		"inverse":
			if cs.size() != 2:
				return false
		"context":
			if cs.any(func(c): return c[1] < 0.0) or at(s.f, 0.0) < 0.5 or at(s.g, 0.0) < 0.0:
				return false
			if need.get("far_ctx", false):
				if cs.size() != 2 or cs[0][0] > 9.0 or cs[1][0] < 10.3:
					return false
			elif need.get("one_in", false) and cs.size() != 1:
				return false
		"line":
			# The window: both curves on the domain, at most about 24 high.
			var ys: Array = []
			for j in 25:
				var x := lo + (hi - lo) * j / 24.0
				ys.append(at(s.f, x))
			ys.append(at(s.g, lo))
			ys.append(at(s.g, hi))
			if ys.max() - ys.min() > 24.0:
				return false
	if need.get("at0", false) and not cs.any(func(c): return absf(c[0]) < 1e-9):
		return false
	if need.get("table", false) and _table(s).is_empty():
		return false
	return true


## f and g side by side at step 0.5 (or 1), each crossing alone between two rows.
static func _table(s: Dictionary) -> Dictionary:
	var lo: float = ceilf(lo_x(s))
	var hi: float = s.d2.to_float()
	var step := 0.5 if hi - lo <= 6.0 else 1.0
	var xs: Array = []
	var fs: Array = []
	var gs: Array = []
	var x := lo
	while x <= hi + 1e-9:
		if absf(h(s, x)) < 0.05:
			return {}
		xs.append(dq(x))
		fs.append(GdcKit.qf(at(s.f, x)))
		gs.append(GdcKit.qf(at(s.g, x)))
		x += step
	if xs.size() > 13:
		return {}
	var used := {}
	for c in s.crossings:
		var i := floori((c[0] - xs[0].to_float()) / step)
		if used.has(i) or i < 0 or i >= xs.size() - 1:
			return {}
		used[i] = true
	return {"xs": xs, "fs": fs, "gs": gs, "step": dq(step)}


## The domain as written: "−2 ≤ x ≤ 5", "0 ≤ t ≤ 12", "x > −2" for f⁻¹.
static func domain_text(s: Dictionary) -> String:
	if s.mode == "inverse":
		return "x > %s" % Fmt.dec(s.d1)
	return "%s ≤ %s ≤ %s" % [Fmt.num(s.d1), s.var, Fmt.num(s.d2)]


static func export(s: Dictionary) -> Dictionary:
	var out: Dictionary = ExtensionViews.export(s)
	for key in ["f", "g"]:
		out[key].erase("co")
	return out
