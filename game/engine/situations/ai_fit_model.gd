class_name AiFitModelSituation
extends RefCounted
## The `ai-fit-model` situation (curriculum/question-types.json), FAL-1001: a model whose form
## is given, with its parameters to find from given values, for fn-ai-fit-model
## (AI-SL2.6.find-parameters). Every AI paper allows a GDC, so every question is Paper 2.
##
## need.ask is the unknown and need.rep its representation (see AiFitModelViews). generate()
## returns a Dictionary:
##   paper, ask, rep, ctx   always 2; the unknown; the representation; the story (an index)
##   exp-factor-from-point: form "factor" (P(t) = k·a^t, a asked) or "cont" (P(t) = k·e^(rt),
##     r asked); k the start (whole), T and V the later reading (V whole); key the answer
##     (float, from the V shown); T2, V2 a further reading, V2 the model's value to the
##     nearest whole number (shown only for the check-point method)
##   exp-start-from-point: a the factor (Q, 2 d.p.), T and V the reading (V whole); key k
##   exp-two-constants: a (Q, 1 d.p.), k and c (whole), T; P0 = k + c and V = k·a^T + c (Q)
##   quadratic-three-points: co [a, b, c] (Q), xs the three x-values, x4 a fourth (check)
##   quadratic-from-symmetry: co [a, b, c], h the axis (whole), p the point's x (whole)
##   cubic-through-points: co [a, b, c, d] (Q), xs the three x-values
##   sinusoid-two-points: amp a, mid c (Q), b the angle's coefficient in degrees, ts the two
##     times (whole), each with sin(b·t°) one of 0, ±1/2, ±1
##
## The numbers are drawn, not taken from any exam question. The SymPy checker
## (tools/check_answers.py, r3fi_check) reads every value back from what the question shows and
## works it out again.

const TRIES := 4000
const EDGE := 0.04
const WHO := 3

const EXP_STARTS := [100, 120, 150, 200, 240, 250, 300, 400, 450, 500, 600, 800]
## sin of a whole multiple of 30°, exactly: angle (degrees, 0 to 330) -> sin.
const NICE := {0: [0, 1], 30: [1, 2], 90: [1, 1], 150: [1, 2], 180: [0, 1], 210: [-1, 2], 270: [-1, 1], 330: [-1, 2]}
## The sinusoid's b (degrees per unit of time) for each story.
const SIN_B := [30, 15, 10]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "quadratic-three-points")
	var rep: String = need.get("rep", "")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "rep": rep, "ctx": rng.int_in(0, WHO - 1)}
		if _draw(rng, s):
			return s
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"exp-factor-from-point":
			return _exp_factor(rng, s)
		"exp-start-from-point":
			return _exp_start(rng, s)
		"exp-two-constants":
			return _exp_two(rng, s)
		"quadratic-three-points":
			return _quad_three(rng, s)
		"quadratic-from-symmetry":
			return _quad_sym(rng, s)
		"cubic-through-points":
			return _cubic(rng, s)
		"sinusoid-two-points":
			return _sinusoid(rng, s)
	return false


# ── Small tools ──────────────────────────────────────────────

static func clear(x: float) -> bool:
	return Answer.rounds_clearly(x, EDGE)


## Every value is finite, clear of a 3 s.f. edge, and no two read the same.
static func distinct(xs: Array) -> bool:
	var seen := {}
	for x in xs:
		if not is_finite(x) or not clear(x):
			return false
		seen[Fmt.sf(x)] = true
	return seen.size() == xs.size()


static func qf(x: float) -> Q:
	return GdcKit.qf(x)


static func pick_q(rng: Seeded, xs: Array) -> Q:
	var v: Variant = rng.pick(xs)
	return Q.new(int(v[0]), int(v[1])) if v is Array else Q.new(int(v))


## q to the power n (n ≥ 0), exactly.
static func qpow(q: Q, n: int) -> Q:
	var out := Q.new(1)
	for i in n:
		out = out.mul(q)
	return out


## Whether q is a decimal with at most `places` decimal places.
static func ends_within(q: Q, places: int = 4) -> bool:
	var scale := 1
	for i in places:
		scale *= 10
	return scale % q.d == 0


## A wrong value as an exact answer's option shows it: as it is when it ends within four
## decimal places, else to 3 s.f.
static func shown_q(v: Q) -> Q:
	return v if ends_within(v) else GraphReadingSituation.sf_q(v, 3)


static func shown_f(x: float) -> Q:
	return GraphReadingSituation.sf_q(qf(x), 3)


static func horner(co: Array, x: Q) -> Q:
	var y := Q.new(0)
	for c in co:
		y = y.mul(x).add(c)
	return y


## The solution of the 3 × 3 system rows·[u, v, w] = rhs, exactly (Cramer), or [] if singular.
static func solve3(rows: Array, rhs: Array) -> Array:
	var det := func(m: Array) -> Q:
		return m[0][0].mul(m[1][1].mul(m[2][2]).sub(m[1][2].mul(m[2][1]))) \
			.sub(m[0][1].mul(m[1][0].mul(m[2][2]).sub(m[1][2].mul(m[2][0])))) \
			.add(m[0][2].mul(m[1][0].mul(m[2][1]).sub(m[1][1].mul(m[2][0]))))
	var d: Q = det.call(rows)
	if d.is_zero():
		return []
	var out: Array = []
	for col in 3:
		var m: Array = []
		for r in 3:
			var row: Array = rows[r].duplicate()
			row[col] = rhs[r]
			m.append(row)
		out.append(det.call(m).div(d))
	return out


## Whether the three option texts of named exact values (lists of Q) all differ from each
## other, as shown.
static func all_differ(sets: Array) -> bool:
	var seen := {}
	for vs in sets:
		seen[",".join(vs.map(func(v): return Fmt.dec(v)))] = true
	return seen.size() == sets.size()


# ── Exponentials ─────────────────────────────────────────────

static func _exp_factor(rng: Seeded, s: Dictionary) -> bool:
	s.form = "cont" if rng.chance(0.3) else "factor"
	s.grow = rng.chance(0.55)
	var r := rng.int_in(3, 30) if s.grow else -rng.int_in(4, 40)
	var a_true := 1.0 + r / 100.0
	s.k = Q.new(rng.pick(EXP_STARTS))
	s.T = rng.int_in(2, 10)
	var k: float = s.k.to_float()
	var V := roundi(k * pow(a_true, s.T))
	if V < 5 or V == int(s.k.n) or V > 50000:
		return false
	s.V = Q.new(V)
	s.key = factor_key(s)
	s.T2 = rng.int_in(1, 12)
	if s.T2 == s.T:
		return false
	var v2 := k * pow(model_factor(s), s.T2)
	s.V2 = Q.new(roundi(v2))
	if s.V2.to_float() < 5.0 or s.V2.eq(s.V) or absf(v2 - roundi(v2)) > 0.45:
		return false
	var vals := factor_slips(s)
	return distinct(vals + factor_fillers(s)) and Answer.needs_rounding(qf(vals[0]))


## a = (V/k)^(1/T), or r = ln(V/k)/T.
static func factor_key(s: Dictionary) -> float:
	var ratio: float = s.V.to_float() / s.k.to_float()
	return pow(ratio, 1.0 / s.T) if s.form == "factor" else log(ratio) / s.T


## The factor per unit of time: a, or e^r.
static func model_factor(s: Dictionary) -> float:
	return s.key if s.form == "factor" else exp(s.key)


## [the key, the ratio without the root, the coordinates swapped].
static func factor_slips(s: Dictionary) -> Array:
	var k: float = s.k.to_float()
	var V: float = s.V.to_float()
	if s.form == "factor":
		return [s.key, V / k, pow(s.T / k, 1.0 / V)]
	return [s.key, log(V / k), log(s.T / k) / V]


## Two fillers with no slip behind them: V/(kT), and 1/a (or the factor e^r).
static func factor_fillers(s: Dictionary) -> Array:
	var f1: float = s.V.to_float() / (s.k.to_float() * s.T)
	return [f1, 1.0 / s.key if s.form == "factor" else exp(s.key)]


static func _exp_start(rng: Seeded, s: Dictionary) -> bool:
	s.grow = rng.chance(0.55)
	var r := rng.int_in(2, 25) if s.grow else -rng.int_in(3, 30)
	s.a = Q.new(100 + r, 100)
	s.T = rng.int_in(2, 12)
	var k_true: float = rng.pick(EXP_STARTS) + rng.int_in(-9, 9)
	var V := roundi(k_true * pow(s.a.to_float(), s.T))
	if V < 5 or V > 50000:
		return false
	s.V = Q.new(V)
	s.key = s.V.to_float() / pow(s.a.to_float(), s.T)
	var vals := start_slips(s)
	return distinct(vals + start_fillers(s)) and Answer.needs_rounding(qf(vals[0]))


## [k, V divided by a once].
static func start_slips(s: Dictionary) -> Array:
	return [s.key, s.V.to_float() / s.a.to_float()]


## Two fillers: V × a^T, V/T.
static func start_fillers(s: Dictionary) -> Array:
	var V: float = s.V.to_float()
	return [V * pow(s.a.to_float(), s.T), V / s.T]


static func _exp_two(rng: Seeded, s: Dictionary) -> bool:
	s.grow = s.ctx == 2
	if s.grow:
		s.a = pick_q(rng, [[6, 5], [3, 2], 2])
		s.k = Q.new(rng.int_in(4, 40))
		s.c = Q.new(rng.int_in(10, 60))
	else:
		s.a = pick_q(rng, [[1, 2], [3, 5], [4, 5], [9, 10]])
		s.k = Q.new(5 * rng.int_in(4, 18))
		s.c = Q.new(rng.int_in(10, 30))
	s.T = rng.int_in(1, 3 if s.a.eq(2) else 4)
	s.P0 = s.k.add(s.c)
	s.V = s.k.mul(qpow(s.a, s.T)).add(s.c)
	if s.k.eq(s.c) or not ends_within(s.V):
		return false
	return all_differ(two_options(s))


## The options' (k, c): [the answer, k set to the start value (c from the second reading), k and
## c swapped, k as V − P0 with no division].
static func two_options(s: Dictionary) -> Array:
	var aT := qpow(s.a, s.T)
	var dk: Q = s.V.sub(s.P0)
	return [[s.k, s.c], [s.P0, shown_q(s.V.sub(s.P0.mul(aT)))], [s.c, s.k], [dk, s.P0.sub(dk)]]


# ── Quadratics and the cubic ─────────────────────────────────

const QUAD_DOWN := [[-1, 10], [-1, 5], [-1, 4], [-1, 2], -1, [-3, 2], -2]
const QUAD_UP := [[1, 10], [1, 5], [1, 4], [1, 2], 1, [3, 2], 2]


## ctx 0 and 1 open downwards (an arch, a flare), ctx 2 upwards (a hanging cable).
static func _quad_co(rng: Seeded, s: Dictionary) -> Q:
	return pick_q(rng, QUAD_UP if s.ctx == 2 else QUAD_DOWN)


static func _quad_three(rng: Seeded, s: Dictionary) -> bool:
	var a := _quad_co(rng, s)
	var b := Q.new(rng.int_in(-12, 12))
	var c := Q.new(rng.int_in(1, 30))
	s.co = [a, b, c]
	var pool: Array = rng.shuffled(range(0, 11))
	var xs: Array = pool.slice(0, 3)
	xs.sort()
	s.xs = xs.map(func(x): return Q.new(x))
	s.x4 = Q.new(pool[3])
	for x in s.xs + [s.x4]:
		var y := horner(s.co, x)
		if y.sign() <= 0 or y.to_float() > 80.0 or not ends_within(y, 2):
			return false
	if b.is_zero() or a.eq(c):
		return false
	var opts := quad_three_options(s)
	return not opts.is_empty() and all_differ(opts)


static func ys_of(s: Dictionary) -> Array:
	return s.xs.map(func(x): return horner(s.co, x))


## The options' (a, b, c): [the answer, x and y swapped (a·y² + b·y + c = x, solved), the
## order reversed, every sign changed], or [] if the swapped system has no single solution.
static func quad_three_options(s: Dictionary) -> Array:
	var ys := ys_of(s)
	var rows: Array = ys.map(func(y): return [y.mul(y), y, Q.new(1)])
	var sw := solve3(rows, s.xs)
	if sw.is_empty():
		return []
	var co: Array = s.co
	return [co, sw.map(func(v): return shown_q(v)), [co[2], co[1], co[0]], co.map(func(v): return v.neg())]


static func _quad_sym(rng: Seeded, s: Dictionary) -> bool:
	var a := _quad_co(rng, s)
	s.h = rng.int_in(1, 6)
	var b := a.mul(-2 * s.h)
	var c := Q.new(rng.int_in(1, 20))
	s.co = [a, b, c]
	s.p = rng.int_in(1, 10)
	if s.p == 2 * s.h:
		return false
	var q := horner(s.co, Q.new(s.p))
	var top := horner(s.co, Q.new(s.h))
	if q.sign() <= 0 or top.sign() <= 0 or q.to_float() > 80.0 or top.to_float() > 80.0 or not ends_within(q, 2):
		return false
	return all_differ(quad_sym_options(s))


## The options' (a, b, c): [the answer, a·x for a·x² in the point's equation, b = 2ah (the
## minus dropped), a and b with their signs changed].
static func quad_sym_options(s: Dictionary) -> Array:
	var c: Q = s.co[2]
	var p := Q.new(s.p)
	var q := horner(s.co, p)
	var a1: Q = q.sub(c).div(p.mul(1 - 2 * s.h))
	var a2: Q = q.sub(c).div(p.mul(p).add(p.mul(2 * s.h)))
	return [s.co, [shown_q(a1), shown_q(a1.mul(-2 * s.h)), c], [shown_q(a2), shown_q(a2.mul(2 * s.h)), c],
		[s.co[0].neg(), s.co[1].neg(), c]]


static func _cubic(rng: Seeded, s: Dictionary) -> bool:
	var a := pick_q(rng, [[1, 10], [1, 5], [1, 4], [1, 2], 1, [-1, 10], [-1, 5], [-1, 4], [-1, 2], -1])
	var b := Q.new(rng.int_in(-6, 6))
	var c := Q.new(rng.int_in(-12, 12))
	var d := Q.new(rng.int_in(2, 30))
	s.co = [a, b, c, d]
	var pool: Array = rng.shuffled(range(1, 7))
	var xs: Array = pool.slice(0, 3)
	xs.sort()
	s.xs = xs.map(func(x): return Q.new(x))
	if b.is_zero() or c.is_zero() or a.eq(b) or b.eq(c) or a.eq(c):
		return false
	for x in s.xs:
		var y := horner(s.co, x)
		if y.sign() <= 0 or y.to_float() > 120.0:
			return false
	return all_differ(cubic_options(s))


## The options' (a, b, c): [the answer, the solver's output read in reverse, a and b
## swapped, every sign changed].
static func cubic_options(s: Dictionary) -> Array:
	var co: Array = s.co
	return [[co[0], co[1], co[2]], [co[2], co[1], co[0]], [co[1], co[0], co[2]], [co[0].neg(), co[1].neg(), co[2].neg()]]


# ── The sinusoid ─────────────────────────────────────────────

## sin(b·t°) exactly, or null where it is not one of 0, ±1/2, ±1.
static func nice_sin(b: int, t: int) -> Variant:
	var ang := (b * t) % 360
	if not NICE.has(ang):
		return null
	return Q.new(NICE[ang][0], NICE[ang][1])


static func _sinusoid(rng: Seeded, s: Dictionary) -> bool:
	s.b = SIN_B[s.ctx]
	var span: int = 360 / s.b
	var ts: Array = []
	for t in range(1, span):
		if nice_sin(s.b, t) != null:
			ts.append(t)
	ts = rng.shuffled(ts).slice(0, 2)
	ts.sort()
	s.ts = ts
	var s1: Q = nice_sin(s.b, ts[0])
	var s2: Q = nice_sin(s.b, ts[1])
	if s1.eq(s2):
		return false
	s.amp = pick_q(rng, [2, 3, 4, 5, 6, 8, [5, 2], [7, 2], [9, 2]])
	if s.ctx == 0:
		s.amp = pick_q(rng, [1, 2, 3, [3, 2], [5, 2]])
	s.mid = Q.new(rng.int_in(int(ceil(s.amp.to_float())) + 2, 30 if s.ctx == 1 else 12))
	var opts := sin_options(s)
	if opts.is_empty():
		return false
	for o in opts.slice(1, 3):
		for v in o:
			if absf(v.to_float()) > 999.0 or absf(v.to_float()) < 0.01:
				return false
	return all_differ(opts)


static func sin_ys(s: Dictionary) -> Array:
	return s.ts.map(func(t): return s.amp.mul(nice_sin(s.b, t)).add(s.mid))


## a and c from two readings with sines s1 and s2: [a, c].
static func two_by_two(s1: float, s2: float, y1: float, y2: float) -> Array:
	var a := (y1 - y2) / (s1 - s2)
	return [a, y1 - a * s1]


## The options' (a, c): [the answer, sin worked out in radians, t and y swapped (a sin(b·y°) + c
## = t), a and c swapped], or [] if a slip's two sines are too close to give a sensible answer.
static func sin_options(s: Dictionary) -> Array:
	var ys := sin_ys(s)
	var t1: float = s.ts[0]
	var t2: float = s.ts[1]
	var r1 := sin(s.b * t1)
	var r2 := sin(s.b * t2)
	var w1 := sin(deg_to_rad(s.b * ys[0].to_float()))
	var w2 := sin(deg_to_rad(s.b * ys[1].to_float()))
	if absf(r1 - r2) < 0.1 or absf(w1 - w2) < 0.1:
		return []
	var rad := two_by_two(r1, r2, ys[0].to_float(), ys[1].to_float())
	var swp := two_by_two(w1, w2, t1, t2)
	for v in rad + swp:
		if not clear(v):
			return []
	return [[s.amp, s.mid], [shown_f(rad[0]), shown_f(rad[1])], [shown_f(swp[0]), shown_f(swp[1])], [s.mid, s.amp]]


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
