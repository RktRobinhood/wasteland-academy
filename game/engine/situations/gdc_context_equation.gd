class_name GdcContextEquationSituation
extends RefCounted
## The `gdc-context-equation` situation (curriculum/question-types.json): a model or a
## diagram leads to an equation that mixes families, with one root that makes sense in
## the context (FAL-420). fn-gdc-solve-equation is built on it. Paper 2: every root is
## found numerically (GdcKit) and asked to 3 s.f.
##
## generate() returns:
##   form    "ksin" x = k sin x; "sector" (r²/2)(θ − sin θ) = A, a circle's segment;
##           "expline" e^(bx) = mx + c; "height" a·te^(−kt) = c, a first time;
##           "savings" P(1 + r/100)^n ≥ T, a whole number of years; "simul" y = e^(bx) + c
##           and y = p − x², two equations in two unknowns
##   the form's numbers as Q (k; r, A; b, m, c; a, k, c; P, rate, T; b, c, p) and
##   co, their floats
##   roots   every root of the equation in a wide window, in order
##   lo, hi  the interval the context allows (floats; ±INF for none)
##   want    the root the view wants: the one in the interval (the first, for "height")
##   far     (expline) one root is past x = 10, outside the standard window
##   table   (need.table, savings) {"xs", "ys"}: the amount at whole years around n
##   paper   2
##
## need (all optional): form ("mixed": ksin, or a third of the time a far expline), far
## (an expline root past 10), far_ok (that a third of the time), neg (expline: one root
## below 0, so t ≥ 0 rejects it), root0 (ksin: the given root x₀, for a reversed view),
## table.

const TRIES := 3000
## The wide window roots are looked for in.
const WIDE := 20.0


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	# The stream's first draw leans low (FAL-460), so it is spent first.
	rng.int_in(0, 1)
	var form: String = need.get("form", "ksin")
	# mixed: x = k sin x, or (a third of the time) an exponential and a line with a root
	# past x = 10. far_ok: that far root a third of the time.
	need = need.duplicate()
	if form == "mixed":
		form = "ksin" if rng.chance(2.0 / 3.0) else "expline"
		need.far = form == "expline"
	elif form == "expline" and need.get("far_ok", false) and not need.get("neg", false) and rng.chance(1.0 / 3.0):
		need.far = true
	for i in TRIES:
		var s := _draw(rng, form, need)
		if s.is_empty():
			continue
		s.co = s.nums.map(func(q): return q.to_float())
		if _clean(s, need):
			s.paper = 2
			if need.get("table", false):
				s.table = _table(s)
			return s
	push_error("GdcContextEquationSituation: no clean situation for %s" % need)
	return {}


static func dq(v: float) -> Q:
	return Q.new(roundi(v * 10), 10)


static func _pick(rng: Seeded, items: Array) -> Q:
	return dq(float(items[rng.int_in(0, items.size() - 1)]))


static func _draw(rng: Seeded, form: String, need: Dictionary) -> Dictionary:
	var s := {"form": form, "far": false}
	match form:
		"ksin":
			if need.get("root0", false):
				# The constant that makes x₀ a root: k = x₀/sin x₀.
				s.x0 = _pick(rng, [1.2, 1.4, 1.5, 1.6, 1.8, 2.2, 2.4, 2.5])
				s.nums = [s.x0]
			else:
				s.nums = [_pick(rng, [1.5, 2, 2.5, 3, 1.8, 2.2, 2.8])]
		"sector":
			var r: int = [4, 5, 6, 8, 10][rng.int_in(0, 4)]
			var th := rng.int_in(7, 28) / 10.0
			# An area to one decimal place near the one this angle gives, so θ isn't nice.
			var a := snappedf(r * r / 2.0 * (th - sin(th)), 0.1)
			if a < 1.0:
				return {}
			s.nums = [Q.new(r), dq(a)]
		"expline":
			s.nums = [_pick(rng, [0.5, 0.6, 0.8, 1, 0.4]), _pick(rng, [1, 1.5, 2, 2.5, 3]), Q.new(rng.int_in(-4, 8), 2)]
			if need.get("far", false):
				s.nums[0] = _pick(rng, [0.25, 0.3, 0.35])
		"height":
			var a := rng.int_in(4, 12)
			var k: float = [0.3, 0.4, 0.5, 0.6][rng.int_in(0, 3)]
			var top := a / k / exp(1.0)
			s.nums = [Q.new(a), dq(k), dq(snappedf(top * rng.int_in(4, 8) / 10.0, 0.1))]
		"savings":
			var p0: int = [1000, 1500, 2000, 2500, 3000, 5000][rng.int_in(0, 5)]
			var rate: float = [2.5, 3, 3.5, 4, 4.5, 5, 2][rng.int_in(0, 6)]
			var m: float = [1.5, 2, 2.5, 1.8, 1.6][rng.int_in(0, 4)]
			s.nums = [Q.new(p0), dq(rate), Q.new(roundi(p0 * m))]
		"simul":
			s.nums = [_pick(rng, [0.5, 0.8, 1]), Q.new(rng.int_in(-3, 1)), Q.new(rng.int_in(3, 9))]
	return s


## The equation as h(x) = 0: the left side minus the right.
static func h(s: Dictionary, x: float) -> float:
	var c: Array = s.co
	match s.form:
		"ksin":
			var k: float = c[0] / sin(c[0]) if s.has("x0") else c[0]
			return x - k * sin(x)
		"sector":
			return c[0] * c[0] / 2.0 * (x - sin(x)) - c[1]
		"expline":
			return exp(c[0] * x) - (c[1] * x + c[2])
		"height":
			return c[0] * x * exp(-c[1] * x) - c[2]
		"savings":
			return c[0] * pow(1.0 + c[1] / 100.0, x) - c[2]
		"simul":
			return exp(c[0] * x) + c[1] - (c[2] - x * x)
	return NAN


static func dh(s: Dictionary, x: float) -> float:
	var e := 1e-6
	return (h(s, x + e) - h(s, x - e)) / (2.0 * e)


## k in x = k sin x (x₀/sin x₀ for the reversed view).
static func k_of(s: Dictionary) -> float:
	return s.co[0] / sin(s.co[0]) if s.has("x0") else s.co[0]


static func _clean(s: Dictionary, need: Dictionary) -> bool:
	var f := func(x: float) -> float: return h(s, x)
	var lo := -WIDE
	match s.form:
		"sector", "height", "savings":
			lo = 0.0
	s.roots = GdcKit.zeros(f, lo + (1e-6 if lo == 0.0 else 0.0), WIDE, 640)
	var rs: Array = s.roots
	if rs.is_empty() or rs.size() > 4:
		return false
	for i in rs.size():
		if absf(dh(s, rs[i])) < 0.2:
			return false
		if i > 0 and rs[i] - rs[i - 1] < 0.5:
			return false
	s.lo = -INF
	s.hi = INF
	match s.form:
		"ksin":
			# Roots 0 and ±x*; the positive one is wanted. k = 1 has only 0.
			var pos: Array = rs.filter(func(x): return x > 0.1)
			if pos.size() != 1 or rs.size() != 3:
				return false
			s.lo = 0.0
			s.want = pos[0]
		"sector":
			if rs.size() != 1 or rs[0] < 0.5 or rs[0] > 3.0:
				return false
			s.lo = 0.0
			s.hi = PI
			s.want = rs[0]
		"expline":
			if rs.size() != 2:
				return false
			if need.get("far", false):
				if rs[1] < 10.5 or rs[1] > 18.0 or rs[0] > 9.0 or rs[0] < -9.0:
					return false
				s.far = true
				s.want = rs[1]
			elif need.get("neg", false):
				if rs[0] > -0.5 or rs[1] < 0.5 or rs[1] > 9.0 or rs[0] < -9.0:
					return false
				s.lo = 0.0
				s.want = rs[1]
			else:
				if rs[0] < -9.0 or rs[1] > 9.0:
					return false
				s.want = rs[0]
		"height":
			if rs.size() != 2:
				return false
			s.lo = 0.0
			s.want = rs[0]
		"savings":
			if rs.size() != 1:
				return false
			var n: float = rs[0]
			if n < 4.0 or n > 40.0 or absf(n - roundf(n)) < 0.05:
				return false
			s.want = n
		"simul":
			var pos: Array = rs.filter(func(x): return x > 0.0)
			if pos.size() != 1 or rs.size() != 2 or rs[0] > -0.3:
				return false
			s.lo = 0.0
			s.want = pos[0]
			var y: float = s.co[2] - pos[0] * pos[0]
			# y from x to 2 s.f. is another number to 3 s.f. (SL2.10.solve-gdc#1).
			var x2 := float(Fmt.sf(pos[0], 2).replace("−", "-"))
			if not GdcKit.fair(y) or Fmt.sf(s.co[2] - x2 * x2) == Fmt.sf(y):
				return false
			s.y = y
	# Every root a fair 3 s.f. value; x = 0 always solves x = k sin x, and is exact.
	if s.form != "savings":
		for x in rs:
			if not GdcKit.fair(x) and not (s.form == "ksin" and absf(x) < 1e-9):
				return false
	if s.form == "ksin" and s.has("x0"):
		if not GdcKit.fair(k_of(s)):
			return false
	if need.get("table", false) and _table(s).is_empty():
		return false
	return true


## The savings at whole years around the answer: n − 3 to n + 2.
static func _table(s: Dictionary) -> Dictionary:
	if s.form != "savings":
		return {}
	var n := ceili(s.want)
	var xs: Array = []
	var ys: Array = []
	for t in range(maxi(n - 3, 0), n + 3):
		xs.append(Q.new(t))
		ys.append(Q.new(roundi(s.co[0] * pow(1.0 + s.co[1] / 100.0, t) * 100), 100))
	return {"xs": xs, "ys": ys}


static func export(s: Dictionary) -> Dictionary:
	var out: Dictionary = ExtensionViews.export(s)
	out.erase("co")
	for key in ["lo", "hi"]:
		if not is_finite(out[key]):
			out.erase(key)
	return out
