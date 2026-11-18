class_name TrapezoidalSituation
extends RefCounted
## The `trapezoidal` situation (curriculum/question-types.json), FAL-1000: an area or a total
## estimated with the trapezoidal rule, for t5-ai-trapezoidal (AI-SL5.8). Every AI paper allows a
## GDC, so every question is Paper 2.
##
## need.ask is the unknown and need.rep its representation (see TrapezoidalViews). generate()
## returns a Dictionary:
##   paper, ask, rep, ctx   always 2; the unknown; the representation; the story (an index)
##   A function on [a, b] with n strips of width h (strip-width, function-estimate,
##   percentage-error-of-estimate, improve-estimate, over-or-under):
##     fam    "quad", "cubic", "sqrt", "exp", "recip" or "line"
##     co     the coefficients, highest power first (quad, cubic, line), as Q
##     m, c   m√(x + c) or m/(x + c), as Q;  m, k: m e^(kx)
##     a, h   Q;  n: whole;  b = a + n h
##     blank  the table's missing heights (function-estimate, table): their indices
##   pick-underestimate-graph: target "under" or "over", a, b (whole), cards: four functions as
##     above, each with its role ("right", "rises", "line", "same-way")
##   A table of measurements (data-estimate, accumulated-total, missing-height):
##     kind   data-estimate and missing-height: "field", "lake" or "canal";
##            accumulated-total: "rover", "pipe" or "channel"
##     h      the spacing (Q), in the story's unit;  ys: the n + 1 heights (Q)
##     mix    accumulated-total: the spacing is in minutes and the rate per second
##     v      channel: the flow speed (Q, m/s)
##     split  lake (diagram): the share of each width above the centre line (floats)
##     j      missing-height: the index of the height k
##
## The numbers are drawn, not taken from any exam question. The SymPy checker
## (tools/check_answers.py, r2tr_check) reads every value back from what the question shows and
## works it out again.

const TRIES := 4000
const WHO := 6
## A 3 s.f. answer is at least this far (a fraction of its last place) from a rounding edge.
const EDGE := 0.04
const SAMPLES := 48


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "function-estimate")
	var rep: String = need.get("rep", "")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "rep": rep, "ctx": rng.int_in(0, WHO - 1)}
		if _draw(rng, s):
			return s
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"strip-width":
			return _strip_width(rng, s)
		"function-estimate":
			return _function_estimate(rng, s)
		"percentage-error-of-estimate":
			return _percentage(rng, s)
		"improve-estimate":
			return _improve(rng, s)
		"over-or-under":
			return _over_under(rng, s)
		"pick-underestimate-graph":
			return _pick(rng, s)
		"data-estimate":
			return _data(rng, s)
		"accumulated-total":
			return _total(rng, s)
		"missing-height":
			return _missing(rng, s)
	return false


# ── Small tools ──────────────────────────────────────────────

static func clear(x: float) -> bool:
	return Answer.rounds_clearly(x, EDGE)


## Every value is clear of a 3 s.f. edge and no two read the same.
static func distinct(xs: Array) -> bool:
	var seen := {}
	for x in xs:
		if not is_finite(x) or not clear(x):
			return false
		seen[Fmt.sf(x)] = true
	return seen.size() == xs.size()


static func dec(x: float) -> Q:
	return GdcKit.qf(x)


static func pick_q(rng: Seeded, xs: Array) -> Q:
	var v: Variant = rng.pick(xs)
	return Q.new(int(v[0]), int(v[1])) if v is Array else Q.new(int(v))


# ── The function ─────────────────────────────────────────────

static func horner(co: Array, x: float) -> float:
	var y := 0.0
	for c in co:
		y = y * x + Q.of(c).to_float()
	return y


static func fx(f: Dictionary, x: float) -> float:
	match f.fam:
		"sqrt":
			return f.m.to_float() * sqrt(x + f.c.to_float())
		"exp":
			return f.m.to_float() * exp(f.k.to_float() * x)
		"recip":
			return f.m.to_float() / (x + f.c.to_float())
	return horner(f.co, x)


static func poly_d(co: Array) -> Array:
	var out: Array = []
	var deg := co.size() - 1
	for i in deg:
		out.append(Q.of(co[i]).mul(deg - i))
	return out


static func d1(f: Dictionary, x: float) -> float:
	match f.fam:
		"sqrt":
			return f.m.to_float() / (2.0 * sqrt(x + f.c.to_float()))
		"exp":
			return f.m.to_float() * f.k.to_float() * exp(f.k.to_float() * x)
		"recip":
			return -f.m.to_float() / pow(x + f.c.to_float(), 2)
	return horner(poly_d(f.co), x) if f.co.size() > 1 else 0.0


static func d2(f: Dictionary, x: float) -> float:
	match f.fam:
		"sqrt":
			return -f.m.to_float() / (4.0 * pow(x + f.c.to_float(), 1.5))
		"exp":
			return f.m.to_float() * pow(f.k.to_float(), 2) * exp(f.k.to_float() * x)
		"recip":
			return 2.0 * f.m.to_float() / pow(x + f.c.to_float(), 3)
	var d := poly_d(f.co)
	return horner(poly_d(d), x) if d.size() > 1 else 0.0


## ∫ f from lo to hi, worked out exactly from an antiderivative.
static func integral(f: Dictionary, lo: float, hi: float) -> float:
	match f.fam:
		"sqrt":
			var c: float = f.c.to_float()
			return 2.0 * f.m.to_float() / 3.0 * (pow(hi + c, 1.5) - pow(lo + c, 1.5))
		"exp":
			var k: float = f.k.to_float()
			return f.m.to_float() / k * (exp(k * hi) - exp(k * lo))
		"recip":
			var c2: float = f.c.to_float()
			return f.m.to_float() * log((hi + c2) / (lo + c2))
	var co: Array = f.co
	var deg := co.size() - 1
	var F := func(x: float) -> float:
		var t := 0.0
		for i in co.size():
			var p := deg - i + 1
			t += Q.of(co[i]).to_float() * pow(x, p) / p
		return t
	return F.call(hi) - F.call(lo)


static func xs_of(s: Dictionary, n: int = -1) -> Array:
	var k: int = s.n if n < 0 else n
	var h: Q = s.h if n < 0 else s.h.mul(s.n).div(n)
	var out: Array = []
	for i in k + 1:
		out.append(s.a.add(h.mul(i)))
	return out


static func ys_of(s: Dictionary, n: int = -1) -> Array:
	return xs_of(s, n).map(func(x): return fx(s, x.to_float()))


## A polynomial's exact heights at the strip edges.
static func ys_exact(s: Dictionary) -> Array:
	return xs_of(s).map(func(x):
		var y := Q.new(0)
		for c in s.co:
			y = y.mul(x).add(Q.of(c))
		return y)


## (h/2)[y₀ + yₙ + 2(y₁ + … + yₙ₋₁)], with weights `inner` inside and `ends` at the ends,
## times `half` (½ for the rule).
static func rule(ys: Array, h: float, inner: float = 2.0, ends: float = 1.0, half: float = 0.5) -> float:
	var t := 0.0
	for i in ys.size():
		t += float(ys[i]) * (ends if i == 0 or i == ys.size() - 1 else inner)
	return half * h * t


static func trap(s: Dictionary, n: int = -1) -> float:
	var h: float = s.h.to_float() if n < 0 else s.h.to_float() * s.n / n
	return rule(ys_of(s, n), h)


static func exact(s: Dictionary) -> float:
	return integral(s, s.a.to_float(), s.b.to_float())


## The same, exactly, for heights as Q.
static func rule_q(ys: Array, h: Q, inner: int = 2, ends: int = 1) -> Q:
	var t := Q.new(0)
	for i in ys.size():
		t = t.add(Q.of(ys[i]).mul(ends if i == 0 or i == ys.size() - 1 else inner))
	return t.mul(h).div(2)


## How the curve bends on [lo, hi]: "up", "down", "line", or "" if it changes or is too flat
## for the estimate to be clearly over or under.
static func bend(f: Dictionary, lo: float, hi: float) -> String:
	if f.fam == "line":
		return "line"
	var sg := 0
	for i in SAMPLES + 1:
		var x := lo + (hi - lo) * i / SAMPLES
		var v := d2(f, x)
		var t := 1 if v > 1e-9 else (-1 if v < -1e-9 else 0)
		if t == 0 or (sg != 0 and t != sg):
			return ""
		sg = t
	return "up" if sg > 0 else "down"


## Whether f rises or falls on [lo, hi]: "rises", "falls" or "" (it turns).
static func slope(f: Dictionary, lo: float, hi: float) -> String:
	var sg := 0
	for i in SAMPLES + 1:
		var x := lo + (hi - lo) * i / SAMPLES
		var v := d1(f, x)
		var t := 1 if v > 1e-9 else (-1 if v < -1e-9 else 0)
		if t == 0 or (sg != 0 and t != sg):
			return ""
		sg = t
	return "rises" if sg > 0 else "falls"


## [least, greatest] of f on [lo, hi].
static func span(f: Dictionary, lo: float, hi: float) -> Array:
	var ylo := INF
	var yhi := -INF
	for i in SAMPLES + 1:
		var y := fx(f, lo + (hi - lo) * i / SAMPLES)
		ylo = minf(ylo, y)
		yhi = maxf(yhi, y)
	return [ylo, yhi]


## A function of family `fam`, with its parameters in f. Its domain is checked by the caller.
static func draw_fam(rng: Seeded, fam: String, f: Dictionary, tidy: bool) -> void:
	f.fam = fam
	match fam:
		"quad":
			var p: Q = pick_q(rng, [[1, 2], 1, [3, 2], 2, [-1, 2], -1, [-3, 2], -2] + ([] if tidy else [[1, 4], [-1, 4]]))
			f.co = [p, Q.new(rng.int_in(-6, 6)), Q.new(rng.int_in(1, 30))]
		"cubic":
			var p3: Q = pick_q(rng, [[1, 2], 1, [-1, 2], -1] + ([] if tidy else [[1, 10], [1, 5], [1, 4], [-1, 10], [-1, 5], [-1, 4]]))
			f.co = [p3, Q.new(rng.int_in(-3, 3)), Q.new(rng.int_in(-5, 5)), Q.new(rng.int_in(1, 30))]
		"line":
			f.co = [pick_q(rng, [[1, 2], 1, [3, 2], 2, 3, [-1, 2], -1, [-3, 2], -2]), Q.new(rng.int_in(2, 20))]
		"sqrt":
			f.m = Q.new(rng.int_in(1, 6))
			f.c = Q.new(rng.int_in(0, 6))
		"exp":
			f.m = Q.new(rng.int_in(1, 8))
			f.k = pick_q(rng, [[1, 5], [1, 4], [3, 10], [2, 5], [1, 2], [3, 5], [-1, 5], [-1, 4], [-3, 10], [-2, 5], [-1, 2]])
		"recip":
			f.m = Q.new(rng.pick([4, 6, 8, 10, 12, 15, 18, 20, 24]))
			f.c = Q.new(rng.int_in(0, 5))


## f on [a, b] with n strips of width h. tidy: a polynomial whose heights end within three
## decimal places, for a table. A function stays positive, bends one way only and is far
## enough from a line that the estimate is clearly over or under.
static func draw_fn(rng: Seeded, s: Dictionary, fams: Array, tidy: bool = false) -> bool:
	var fam: String = rng.pick(fams)
	s.h = pick_q(rng, [[1, 2], 1, 2] if tidy else [[1, 2], 1, 2, [1, 4], [1, 5], [2, 5], [3, 2]])
	s.n = rng.int_in(3, 6)
	s.a = Q.new(rng.pick([0, 0, 1, 1, 2, 3]))
	s.b = s.a.add(s.h.mul(s.n))
	draw_fam(rng, fam, s, tidy)
	var lo: float = s.a.to_float()
	var hi: float = s.b.to_float()
	if fam in ["sqrt", "recip"] and lo + s.c.to_float() < 1.0:
		return false
	if hi - lo < 1.0 or hi - lo > 12.0:
		return false
	var sp := span(s, lo, hi)
	if sp[0] < 0.5 or sp[1] > 80.0 or sp[1] < 2.0:
		return false
	var bd := bend(s, lo, hi)
	if bd == "":
		return false
	s.bend = bd
	if tidy:
		for y in ys_exact(s):
			if 1000 % y.d != 0:
				return false
	if fam != "line":
		var t := trap(s)
		var e := exact(s)
		if absf(t - e) / e < 0.002:
			return false
	return true


static func _strip_width(rng: Seeded, s: Dictionary) -> bool:
	if not draw_fn(rng, s, ["quad", "cubic"] if s.rep == "table" else ["quad", "cubic", "sqrt", "exp", "recip"], s.rep == "table"):
		return false
	# The slip (b − a)/(n + 1) reads differently from h and from the fillers.
	var slip: Q = s.b.sub(s.a).div(s.n + 1)
	return not slip.eq(s.h)


static func _function_estimate(rng: Seeded, s: Dictionary) -> bool:
	var table: bool = s.rep == "table"
	if not draw_fn(rng, s, ["quad", "cubic"] if table else ["quad", "cubic", "sqrt", "exp", "recip"], table):
		return false
	if table:
		var k := rng.int_in(1, 2)
		var idx: Array = rng.shuffled(range(s.n + 1))
		s.blank = idx.slice(0, k)
		s.blank.sort()
	var vals := function_slips(s)
	return distinct(vals) and Answer.needs_rounding(dec(vals[0]))


## [T, h from n + 1, no doubling, no half].
static func function_slips(s: Dictionary) -> Array:
	var t := trap(s)
	var ys := ys_of(s)
	var h: float = s.h.to_float()
	return [t, t * s.n / (s.n + 1), rule(ys, h, 1.0), rule(ys, h, 2.0, 1.0, 1.0)]


static func _percentage(rng: Seeded, s: Dictionary) -> bool:
	if not draw_fn(rng, s, ["quad", "cubic", "sqrt", "exp", "recip"]):
		return false
	var vals := percentage_slips(s)
	var e: float = vals[0]
	if e < 0.1 or e > 25.0 or not Answer.needs_rounding(dec(e)):
		return false
	# The error from the 7 figures the working shows is the same to 3 s.f.
	var t7 := float(Fmt.sf(trap(s), 7).replace("−", "-"))
	var i7 := float(Fmt.sf(exact(s), 7).replace("−", "-"))
	if Fmt.sf(absf(t7 - i7) / i7 * 100.0) != Fmt.sf(e):
		return false
	return distinct(vals)


## [the error, over the estimate, the h slip carried through] and, when the estimate is
## under, the signed error.
static func percentage_slips(s: Dictionary) -> Array:
	var t := trap(s)
	var i := exact(s)
	var t0: float = t * s.n / (s.n + 1)
	var out: Array = [absf(t - i) / i * 100.0, absf(t - i) / t * 100.0, absf(t0 - i) / i * 100.0]
	if t < i:
		out.append((t - i) / i * 100.0)
	return out


static func _improve(rng: Seeded, s: Dictionary) -> bool:
	if not draw_fn(rng, s, ["quad", "cubic", "sqrt", "exp", "recip"]):
		return false
	var i := exact(s)
	var t := trap(s)
	var t2 := trap(s, s.n * 2)
	return absf(t2 - i) < absf(t - i) and distinct([t, t2, i])


static func _over_under(rng: Seeded, s: Dictionary) -> bool:
	var fams := ["quad", "cubic", "sqrt", "exp", "recip"]
	if rng.chance(0.2):
		fams = ["line"]
	if not draw_fn(rng, s, fams):
		return false
	s.slope = slope(s, s.a.to_float(), s.b.to_float())
	if s.slope == "":
		return false
	return distinct([trap(s), exact(s)]) if s.fam != "line" else clear(exact(s))


# ── Pick the graph ───────────────────────────────────────────

## The roles of the four cards. The slip that decides from the slope reads "rises" as an
## overestimate and "falls" as an underestimate, so its card has the slope the target suggests
## and bends the other way; the right card bends the way the target needs, with the other
## slope, so that slip never picks it; a straight line; and one that bends the other way with
## the right card's slope.
static func _pick(rng: Seeded, s: Dictionary) -> bool:
	s.target = "under" if rng.chance(0.5) else "over"
	s.a = Q.new(0)
	s.b = Q.new(rng.pick([4, 5, 6]))
	var want := "down" if s.target == "under" else "up"
	var other := "up" if want == "down" else "down"
	var slip_sl := "falls" if s.target == "under" else "rises"
	var right_sl := "rises" if s.target == "under" else "falls"
	var roles := [["right", want, right_sl], ["rises", other, slip_sl], ["line", "line", ""], ["same-way", other, right_sl]]
	var cards: Array = []
	for r in roles:
		var f := card_fn(rng, s, r[1], r[2])
		if f.is_empty():
			return false
		f.role = r[0]
		cards.append(f)
	s.cards = cards
	return true


## A function that bends `bd` and rises or falls on [a, b], with values from 1 to 9.
static func card_fn(rng: Seeded, s: Dictionary, bd: String, sl: String) -> Dictionary:
	var lo: float = s.a.to_float()
	var hi: float = s.b.to_float()
	for i in 400:
		var f := {}
		var fams: Array
		if bd == "line":
			fams = ["line"]
		elif bd == "up":
			fams = ["quad", "exp"] if sl == "rises" else ["quad", "exp", "recip"]
		else:
			fams = ["quad", "sqrt"] if sl == "rises" else ["quad"]
		draw_fam(rng, rng.pick(fams), f, false)
		if f.fam == "quad":
			# A gentler bend, so the curve fits the card.
			f.co = [f.co[0].div(4), Q.new(rng.int_in(-6, 6)).div(2), Q.new(rng.int_in(1, 9))]
		if f.fam in ["sqrt", "recip"] and lo + f.c.to_float() < 1.0:
			continue
		var sp := span(f, lo, hi)
		if sp[0] < 1.0 or sp[1] > 9.0 or sp[1] - sp[0] < 1.5:
			continue
		if bend(f, lo, hi) != bd:
			continue
		if sl != "" and slope(f, lo, hi) != sl:
			continue
		if bd != "line":
			# The bend shows: the curve is at least 0.4 off its chord in the middle.
			var mid := fx(f, (lo + hi) / 2.0)
			var chord := (fx(f, lo) + fx(f, hi)) / 2.0
			if absf(mid - chord) < 0.4:
				continue
		return f
	return {}


# ── Measurements ─────────────────────────────────────────────

## n + 1 heights from lo to hi, changing smoothly, to 1 d.p. (tenths) or whole.
static func heights(rng: Seeded, n: int, lo: int, hi: int, tenths: bool) -> Array:
	var scale := 10 if tenths else 1
	var out: Array = []
	var y := rng.int_in(lo * scale, hi * scale)
	var step := (hi - lo) * scale / 3
	var drift := rng.int_in(-step, step) / 2
	for i in n + 1:
		out.append(Q.new(clampi(y, lo * scale, hi * scale), scale))
		y += drift + rng.int_in(-step, step) / 2
		# Off an end, the profile bounces back.
		if y < lo * scale:
			y = 2 * lo * scale - y
			drift = absi(drift)
		elif y > hi * scale:
			y = 2 * hi * scale - y
			drift = -absi(drift)
	return out


static func all_distinct_q(ys: Array) -> bool:
	var seen := {}
	for y in ys:
		seen[y.key()] = true
	return seen.size() == ys.size()


## A field, lake or canal: n + 1 widths or depths every h metres.
static func _shape(rng: Seeded, s: Dictionary, spacing: Array) -> void:
	s.kind = rng.pick(["field", "lake", "canal"])
	s.n = rng.int_in(4, 6)
	var tenths := rng.chance(0.6)
	if s.kind == "canal":
		s.h = pick_q(rng, [[1, 2], 1, [3, 2], 2])
		s.ys = heights(rng, s.n, 1, 5, true)
	else:
		s.h = Q.new(rng.pick(spacing))
		s.ys = heights(rng, s.n, 6, 45, tenths)
	var split: Array = []
	for i in s.n + 1:
		split.append(0.4 + 0.2 * rng.int_in(0, 10) / 10.0)
	s.split = split


static func _data(rng: Seeded, s: Dictionary) -> bool:
	_shape(rng, s, [4, 5, 6, 8, 10, 12, 15, 20])
	if not all_distinct_q(s.ys):
		return false
	var vals := data_slips(s)
	return distinct(vals.map(func(v): return v.to_float())) and Answer.needs_rounding(vals[0])


## [T, the x-values as heights, the ends doubled, no doubling, no half], as Q.
static func data_slips(s: Dictionary) -> Array:
	var h: Q = s.h
	var xs: Array = []
	for i in s.n + 1:
		xs.append(h.mul(i))
	var t := rule_q(s.ys, h)
	return [t, rule_q(xs, h), rule_q(s.ys, h, 2, 2), rule_q(s.ys, h, 1, 1), t.mul(2)]


static func _total(rng: Seeded, s: Dictionary) -> bool:
	var graph: bool = s.rep == "graph"
	s.kind = "rover" if graph else rng.pick(["rover", "rover", "pipe", "pipe", "channel"])
	s.n = rng.int_in(4, 6)
	s.mix = false
	match s.kind:
		"rover":
			if graph:
				s.h = Q.new(rng.pick([2, 4, 10]))
				s.ys = heights(rng, s.n, 1, 20, false)
				if rng.chance(0.3):
					s.ys[0] = Q.new(0)
			else:
				s.mix = rng.chance(0.45)
				s.h = Q.new(rng.pick([1, 2, 3, 5]) if s.mix else rng.pick([2, 4, 5, 10]))
				s.ys = heights(rng, s.n, 1, 20, rng.chance(0.6))
				if rng.chance(0.3):
					s.ys[0] = Q.new(0)
		"pipe":
			s.mix = rng.chance(0.45)
			if s.mix:
				s.h = Q.new(rng.pick([1, 2, 5]))
				s.ys = heights(rng, s.n, 1, 12, true)
			else:
				s.h = Q.new(rng.pick([5, 10, 15, 20]))
				s.ys = heights(rng, s.n, 20, 300, false)
		"channel":
			s.h = pick_q(rng, [[1, 2], 1, 2])
			s.ys = heights(rng, s.n, 1, 4, true)
			s.v = pick_q(rng, [[2, 5], [1, 2], [3, 5], [4, 5], [6, 5], [3, 2]])
	if not all_distinct_q(s.ys):
		return false
	var vals := total_slips(s)
	# Speeds read off a graph are whole numbers, so the total may end: it is then exact.
	return distinct(vals.map(func(v): return v.to_float())) and (graph or Answer.needs_rounding(vals[0]))


## The factor from the rule's sum to the total: 60 when minutes meet a rate per second, the
## flow speed for a channel, else 1.
static func factor(s: Dictionary) -> Q:
	if s.kind == "channel":
		return s.v
	return Q.new(60) if s.mix else Q.new(1)


## [the total, no half, the ends doubled, no doubling] and, when the units mix, the spacing
## left in minutes.
static func total_slips(s: Dictionary) -> Array:
	var f := factor(s)
	var t := rule_q(s.ys, s.h)
	var out: Array = [t.mul(f), t.mul(2).mul(f), rule_q(s.ys, s.h, 2, 2).mul(f), rule_q(s.ys, s.h, 1, 1).mul(f)]
	if s.mix:
		out.append(t)
	return out


static func _missing(rng: Seeded, s: Dictionary) -> bool:
	_shape(rng, s, [4, 5, 6, 8, 10])
	if s.kind == "canal" or not all_distinct_q(s.ys):
		return false
	s.j = rng.int_in(0, s.n) if rng.chance(0.5) else rng.pick([0, s.n])
	var vals := missing_slips(s)
	var seen := {}
	for v in vals:
		if v.sign() <= 0:
			return false
		seen[v.key()] = true
	return seen.size() == vals.size()


static func inner(s: Dictionary) -> bool:
	return s.j > 0 and s.j < s.n


## [k, an inner k with weight one (2k), the h/2 left out] and, for an end, both end heights
## doubled ((k − the other end)/2).
static func missing_slips(s: Dictionary) -> Array:
	var k: Q = s.ys[s.j]
	var area := rule_q(s.ys, s.h)
	var w := 2 if inner(s) else 1
	var rest: Q = area.mul(2).div(s.h).sub(k.mul(w))
	var out: Array = [k]
	if inner(s):
		out.append(k.mul(2))
	out.append(area.sub(rest).div(w))
	if not inner(s):
		out.append(k.sub(s.ys[s.n - s.j]).div(2))
	return out


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
