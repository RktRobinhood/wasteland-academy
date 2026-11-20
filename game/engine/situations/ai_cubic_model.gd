class_name AiCubicModelSituation
extends RefCounted
## The `ai-cubic-model` situation (curriculum/question-types.json), FAL-1001, for
## fn-ai-cubic-model (AI-SL2.5.cubic-model, AI-SL2.6.reasonable-domain). Every AI paper allows
## a GDC, so every question is Paper 2.
##
## need.ask is the unknown and need.rep its representation (see AiCubicModelViews). generate()
## returns a Dictionary:
##   paper, ask, rep, ctx   always 2; the unknown; the representation; a story index
##   The open box (box-volume, box-domain, box-max):
##     L, W     the card's length and width, whole cm (W even, so W/2 ends), W + 4 ≤ L ≤ 2W − 2 (so the shorter
##              side ends the domain and half the longer side is less than the shorter side)
##     x1, v1   the best x and the greatest volume (floats), the local maximum, inside 0 < x < W/2
##     x2, v2   the other turning point (floats): W/2 < x2 < L/2, so v2 < 0
##     target   box-max: "x" (the best x) or "V" (the greatest volume)
##     expanded box-max, equation: V is given expanded (4x³ + ...) rather than as x(L − 2x)(W − 2x)
##     pick     box-domain: the question is pick the graph (V drawn on four domains)
##   A cubic model (evaluate, positive-zero, negative-total):
##     kind     "profit" (P thousand scrap from x hundred items, a loss at first),
##              "temp" (T °C, t hours after midnight) or "flow" (F litres per minute into a
##              tank, t minutes after a valve opens; negative means water flows out)
##     co       [a, b, c, d] as Q: a to 3 d.p., b, c, d to 2 d.p.
##     hi       the domain's top: 0 ≤ input ≤ hi (whole)
##     zeros    every real zero of the model, smallest first (floats)
##     x0       evaluate: the input (Q, to 1 d.p., not whole)
##     sign     temp, flow: the sign of a; the model is negative on [0, z₁) and (z₂, z₃) when
##              a > 0, on (z₁, z₂) and (z₃, hi] when a < 0
##
## The numbers are drawn, not taken from any exam question. The SymPy checker
## (tools/check_answers.py, r3cu_check) reads every value back from what the question shows and
## works it out again.

const TRIES := 4000
const WHO := 6
## A 3 s.f. value is at least this far (a fraction of its last place) from a rounding edge.
const EDGE := 0.05
const KINDS := ["profit", "temp", "flow"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "box-volume")
	var rep: String = need.get("rep", "")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "rep": rep, "ctx": rng.int_in(0, WHO - 1)}
		if _draw(rng, s):
			return s
	push_error("AiCubicModelSituation: no clean situation for %s" % ask)
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"box-volume":
			return _box(rng, s, false)
		"box-domain":
			s.pick = rng.chance(0.35)
			return _box(rng, s, s.pick)
		"box-max":
			s.target = "x" if rng.chance(0.5) else "V"
			s.expanded = s.rep == "equation" and rng.chance(0.5)
			return _box(rng, s, false) and _box_max_clean(s)
		"evaluate":
			return _model(rng, s, rng.pick(KINDS)) and _evaluate(rng, s)
		"positive-zero":
			return _model(rng, s, "profit") and _positive_zero_clean(s)
		"negative-total":
			return _model(rng, s, rng.pick(["temp", "flow"])) and _negative_total_clean(s)
	return false


# ── Small tools ──────────────────────────────────────────────

static func clear(x: float) -> bool:
	return absf(x) >= 0.1 and Answer.rounds_clearly(x, EDGE)


## Every value is clear of a 3 s.f. edge and no two read the same.
static func distinct(xs: Array) -> bool:
	var seen := {}
	for x in xs:
		if not is_finite(x) or not clear(x):
			return false
		seen[Fmt.sf(x)] = true
	return seen.size() == xs.size()


## A value as a GDC's screen shows it, read back as a number: what the working's figures give.
static func w6(x: float) -> float:
	return float(Fmt.work(x, 6).replace("−", "-"))


# ── The open box ─────────────────────────────────────────────

static func vol(L: float, W: float, x: float) -> float:
	return x * (L - 2.0 * x) * (W - 2.0 * x)


## The expanded volume, highest power first: x(L − 2x)(W − 2x) = 4x³ − 2(L + W)x² + LWx.
static func box_co(s: Dictionary) -> Array:
	return [Q.new(4), Q.new(-2 * (s.L + s.W)), Q.new(s.L * s.W), Q.new(0)]


## The two turning points of x(L − 2x)(W − 2x): 12x² − 4(L + W)x + LW = 0, so
## x = (L + W ∓ √(L² − LW + W²))/6.
static func turning(L: int, W: int) -> Array:
	var r := sqrt(float(L * L - L * W + W * W))
	return [(L + W - r) / 6.0, (L + W + r) / 6.0]


static func _box(rng: Seeded, s: Dictionary, pick: bool) -> bool:
	var W := 2 * rng.int_in(6, 15) if pick else 2 * rng.int_in(5, 20)
	# For pick the graph, L is close to 2W, so the four cards' heights stay alike.
	var L := rng.int_in(ceili(1.75 * W), 2 * W - 2) if pick else rng.int_in(W + 4, 2 * W - 2)
	# The domain's slips are whole or end in .5 either way; for box-domain L is even, so half
	# the longer side is whole as an option writes it.
	if L - W < 4 or (s.ask == "box-domain" and L % 2 != 0):
		return false
	s.L = L
	s.W = W
	var d := L * L - L * W + W * W
	var r := roundi(sqrt(float(d)))
	if r * r == d:
		# A rational turning point: the GDC isn't needed.
		return false
	var t := turning(L, W)
	s.x1 = t[0]
	s.x2 = t[1]
	s.v1 = vol(L, W, t[0])
	s.v2 = vol(L, W, t[1])
	return s.x1 > 0.5 and s.x1 < W / 2.0 and s.x2 > W / 2.0 and s.x2 < L / 2.0 and s.v2 < 0.0


## The values a box-max question asks or offers: [the answer, the other turning point's, the
## other coordinate, the one-corner slip's (2x₁ or 2V: x(L − x)(W − x) peaks at x = 2x₁)].
static func box_max_vals(s: Dictionary) -> Array:
	if s.target == "x":
		return [s.x1, s.x2, s.v1, 2.0 * s.x1]
	return [s.v1, s.v2, s.x1, 2.0 * s.v1]


## The table method: the best whole x, then the best x in tenths and in hundredths, each with
## its volume. [n, V(n), t, V(t), h, V(h)].
static func table_steps(s: Dictionary) -> Array:
	var best := func(lo: float, hi: float, step: float) -> float:
		var bx := lo
		var bv := -INF
		var k := 0
		while lo + k * step <= hi + 1e-9:
			var x := lo + k * step
			if x > 0.0 and x < s.W / 2.0:
				var v := vol(s.L, s.W, x)
				if v > bv:
					bv = v
					bx = x
			k += 1
		return bx
	var n: float = best.call(1.0, floorf(s.W / 2.0), 1.0)
	var t: float = snappedf(best.call(n - 1.0, n + 1.0, 0.1), 0.1)
	var h: float = snappedf(best.call(t - 0.1, t + 0.1, 0.01), 0.01)
	return [n, vol(s.L, s.W, n), t, vol(s.L, s.W, t), h, vol(s.L, s.W, h)]


static func _box_max_clean(s: Dictionary) -> bool:
	var vals := box_max_vals(s)
	if not distinct(vals):
		return false
	# The table's best hundredth is x₁ to 3 s.f., and its volume reads as the greatest volume.
	var tb := table_steps(s)
	if Fmt.sf(tb[4]) != Fmt.sf(s.x1) or Fmt.sf(tb[5]) != Fmt.sf(s.v1):
		return false
	# The GDC's 6 figures give the same answer to 3 s.f.
	return Fmt.sf(w6(vals[0])) == Fmt.sf(vals[0])


# ── A cubic model ────────────────────────────────────────────

static func horner(co: Array, x: float) -> float:
	var y := 0.0
	for c in co:
		y = y * x + Q.of(c).to_float()
	return y


## Every real zero of the cubic, smallest first, from its monotone pieces.
static func zeros(co: Array) -> Array:
	var a: float = co[0].to_float()
	var b: float = co[1].to_float()
	var c: float = co[2].to_float()
	# The turning points split the line into pieces on which the cubic is monotone.
	var cuts: Array = []
	var disc := 4.0 * b * b - 12.0 * a * c
	if disc > 0.0:
		var r := sqrt(disc)
		cuts = [(-2.0 * b - r) / (6.0 * a), (-2.0 * b + r) / (6.0 * a)]
		cuts.sort()
	var big := 1.0 + (absf(b) + absf(c) + absf(co[3].to_float())) / absf(a)
	var ends: Array = [-big] + cuts + [big]
	var out: Array = []
	for i in ends.size() - 1:
		var lo: float = ends[i]
		var hi: float = ends[i + 1]
		var flo := horner(co, lo)
		var fhi := horner(co, hi)
		if flo == 0.0:
			if out.is_empty() or absf(out[-1] - lo) > 1e-12:
				out.append(lo)
			continue
		if flo * fhi > 0.0:
			continue
		for k in 200:
			var mid := (lo + hi) / 2.0
			var fm := horner(co, mid)
			if (fm < 0.0) == (flo < 0.0):
				lo = mid
				flo = fm
			else:
				hi = mid
		out.append((lo + hi) / 2.0)
	return out


## A cubic k(x − z₁)(x − z₂)(x − z₃) with its coefficients rounded: a to 3 d.p., the rest to 2.
static func rounded(k: float, zs: Array) -> Array:
	var b: float = -(zs[0] + zs[1] + zs[2])
	var c: float = zs[0] * zs[1] + zs[0] * zs[2] + zs[1] * zs[2]
	var d: float = -zs[0] * zs[1] * zs[2]
	return [Q.new(roundi(k * 1000.0), 1000), Q.new(roundi(k * b * 100.0), 100), Q.new(roundi(k * c * 100.0), 100), Q.new(roundi(k * d * 100.0), 100)]


static func r2(rng: Seeded, lo: float, hi: float) -> float:
	return rng.int_in(roundi(lo * 100.0), roundi(hi * 100.0)) / 100.0


## [least, greatest] of the model on [lo, hi].
static func span(co: Array, lo: float, hi: float) -> Array:
	var ylo := INF
	var yhi := -INF
	for i in 241:
		var y := horner(co, lo + (hi - lo) * i / 240.0)
		ylo = minf(ylo, y)
		yhi = maxf(yhi, y)
	return [ylo, yhi]


static func _model(rng: Seeded, s: Dictionary, kind: String) -> bool:
	s.kind = kind
	var zs: Array
	var size: float
	if kind == "profit":
		var z2 := r2(rng, 0.6, 3.5)
		zs = [-r2(rng, 0.8, 6.0), z2, z2 + r2(rng, 2.5, 7.0)]
		s.hi = mini(12, ceili(zs[2] + r2(rng, 0.4, 2.0)))
		s.sign = -1
		size = rng.int_in(8, 60)
	else:
		s.hi = rng.pick([10, 12]) if kind == "temp" else rng.pick([8, 10, 12, 15])
		var hi: float = s.hi
		var z1 := r2(rng, 0.6, hi / 3.0)
		var z2 := z1 + r2(rng, 1.2, hi / 3.0)
		var z3 := z2 + r2(rng, 1.2, hi / 3.0)
		zs = [z1, z2, z3]
		s.sign = 1 if rng.chance(0.5) else -1
		size = rng.int_in(4, 16) if kind == "temp" else rng.int_in(6, 40)
	if zs[2] >= s.hi - 0.4:
		return false
	# Scale so the model's greatest size on its domain is about `size`.
	var sp0 := span(rounded(s.sign, zs), 0.0, s.hi)
	var k: float = s.sign * size / maxf(absf(sp0[0]), absf(sp0[1]))
	s.co = rounded(k, zs)
	if s.co[0].is_zero() or s.co.any(func(c): return c.is_zero()):
		return false
	# The zeros of the rounded model: three, apart and clean, laid out as the story needs.
	var z: Array = zeros(s.co)
	if z.size() != 3:
		return false
	s.zeros = z
	for i in 2:
		if z[i + 1] - z[i] < 1.0:
			return false
	for v in z:
		if not clear(v) or absf(v - roundf(v)) < 0.05:
			return false
	if kind == "profit":
		return z[0] < -0.5 and z[1] > 0.4 and z[2] < s.hi - 0.3
	return z[0] > 0.4 and z[2] < s.hi - 0.3


static func value(s: Dictionary, x: float) -> float:
	return horner(s.co, x)


## evaluate: x₀ to 1 d.p., not whole, inside the domain; the value needs rounding.
static func _evaluate(rng: Seeded, s: Dictionary) -> bool:
	var k := rng.int_in(3, s.hi * 10 - 3)
	if k % 10 == 0:
		return false
	s.x0 = Q.new(k, 10)
	var vals := evaluate_vals(s)
	return distinct(vals) and Answer.needs_rounding(GdcKit.qf(vals[0]))


## [f(x₀), and the fillers: f(x₀ + 1), f(x₀) without its constant, f(−x₀)].
static func evaluate_vals(s: Dictionary) -> Array:
	var x: float = s.x0.to_float()
	var y := value(s, x)
	return [y, value(s, x + 1.0), y - s.co[3].to_float(), value(s, -x)]


## positive-zero: [z₂, the negative zero z₁, the zero z₃ where profit turns back to loss, the
## best x (a filler)].
static func positive_zero_vals(s: Dictionary) -> Array:
	var a: float = s.co[0].to_float()
	var b: float = s.co[1].to_float()
	var c: float = s.co[2].to_float()
	var r := sqrt(4.0 * b * b - 12.0 * a * c)
	var tps: Array = [(-2.0 * b - r) / (6.0 * a), (-2.0 * b + r) / (6.0 * a)]
	return [s.zeros[1], s.zeros[0], s.zeros[2], maxf(tps[0], tps[1])]


static func _positive_zero_clean(s: Dictionary) -> bool:
	var vals := positive_zero_vals(s)
	return distinct(vals) and Fmt.sf(w6(vals[0])) == Fmt.sf(vals[0])


## The stretches where the model is negative on [0, hi], as [from, to].
static func negative_parts(s: Dictionary) -> Array:
	var z: Array = s.zeros
	if s.sign > 0:
		return [[0.0, z[0]], [z[1], z[2]]]
	return [[z[0], z[1]], [z[2], float(s.hi)]]


## negative-total: [the total, each stretch alone, and the fillers: the time it is positive,
## from the first zero to the last].
static func negative_total_vals(s: Dictionary) -> Array:
	var p := negative_parts(s)
	var a: float = p[0][1] - p[0][0]
	var b: float = p[1][1] - p[1][0]
	return [a + b, a, b, s.hi - a - b, s.zeros[2] - s.zeros[0]]


static func _negative_total_clean(s: Dictionary) -> bool:
	var vals := negative_total_vals(s)
	if not distinct(vals):
		return false
	# The total from the 6 figures the working shows is the same to 3 s.f.
	var p := negative_parts(s)
	var t := 0.0
	for st in p:
		t += w6(st[1]) - w6(st[0])
	return Fmt.sf(t) == Fmt.sf(vals[0])


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
