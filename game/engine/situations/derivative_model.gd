class_name DerivativeModelSituation
extends RefCounted
## The `derivative-model` situation (curriculum/question-types.json): a story modelled by a
## function of time, and the chain, product and quotient rules with values read from a table or
## from graphs (SL5.6, SL5.1, FAL-753). Every bank part is Paper 2, so a rate is a GDC value, a
## float to 3 s.f., and a time comes from a scan for sign changes (GdcKit); only the values read
## from a table or graphs are exact, with Q. The SymPy checker (tools/check_answers.py) reads the
## model back from the line shown, differentiates it and finds each value again.
##
## need.ask is the unknown, need.rep the representation:
##   rate-at-time          the model, t0: S′(t0)
##   rate-with-units       the same: the rate and its units, as a statement
##   rate-other-unit       the same: the rate per a shorter unit of time
##   time-at-rate          the model, a rate: the first time it takes that rate
##   greatest-rate         the model: the greatest rate on the domain
##   time-of-greatest-rate the model: when that is
##   rising-or-falling     the model, t0: which way it is going, and how fast
##   interpret-rate        the model, t0: what the rate there means in the story
##   compare-models        two models, t0: which rises faster
##   time-rate-greater     a wave and a straight line: the total time the line's rate is greater
##   steeper-tangent       a model and two tangents: where it rises faster
##   tangent-estimate      the model, t0, a step: the tangent's estimate of a later value
##   product-from-table, quotient-from-table, chain-from-table
##   composite-with-model  h = A e^(c g(t)), A ln(g(t)) or A√(g(t)), g from a table
##   rising-from-table     h = f × g: which way h is going, and how fast
##   product-from-graphs, quotient-from-graphs, chain-from-graphs
##
## generate() returns a Dictionary:
##   paper, ask, rep, ctx   2; the unknown; the representation; the story
##   mod      the model: a Dictionary with fam and its numbers, all Q:
##              "exp"       P e^(kt), k either sign
##              "logistic"  L/(1 + a e^(−kt))
##              "pulse"     a t e^(−kt)
##              "wave"      c + mt + B cos(wt)
##              "log"       c + a ln(bt + 1)
##   T        the domain is 0 ≤ t ≤ T;  t0  the time asked about;  v, r  S(t0) and S′(t0)
##   k        (time-at-rate) the rate given, Q;  x  the time found;  first  more than one time has it
##   top      (greatest) {"t", "r"}: the time of the greatest rate, and the rate there;  fall  it
##            is the greatest rate of decrease, shown as a size
##   mod2     (compare-models, time-rate-greater) the second model: "line" c + mt in the second
##   flip     (compare-models) the model that rises faster is called B, not A
##   t1, t2   (steeper-tangent) the two times;  opposite  the slower one falls;  flip  as above
##   h        (tangent-estimate) the step, Q
##   xs, cross, pieces  (time-rate-greater) the total, the crossings and the stretches [[lo, hi]]
##   story    (rules) an index into a list of stories;  a  the point;  ts  the table's times
##   f, g, df, dg  (rules, from a table) the columns, whole numbers
##   fv, gv   (rules, from graphs) the heights at x = 0, 2, 4, 6;  form, A, c  composite-with-model
##
## The clean limits below are the numbers behind the catalogue's `clean` text. The SymPy
## checker holds its own copy and fails on any breach.

const TRIES := 6000
## |rate| is at least this.
const RATE_MIN := 0.05
## A time found is at least this far from another time with the same rate, and from 0 and T.
const TIME_GAP := 0.5
## Samples when scanning a domain for the times a rate is reached.
const SAMPLES := 400
## The story indices of each family (DerivativeModelViews.CONTEXTS).
const GROW := [0, 1]
const DECAY := [2, 3]
const LOGISTIC := [4, 5, 6]
const PULSE := [7, 8, 9]
const WAVE := [10, 11, 12]
const LOG := [13, 14]
const ALL_FAMS := ["exp", "logistic", "pulse", "wave", "log"]
const FAMS := {"greatest-rate": ["logistic", "pulse", "wave"], "time-of-greatest-rate": ["logistic", "pulse", "wave"],
	"rising-or-falling": ["pulse", "wave"], "steeper-tangent": ["logistic", "wave"]}
## The rates a quotient's g and g′ take, so that its value and its slips end as decimals.
const G_AT := [2, 4, 5, 8, 10]
const DG_AT := [1, 2, 4, 5]
const STORIES := 4
const QUOTIENT_STORIES := 3
## The outer functions of composite-with-model.
const SHAPES := ["exp", "ln", "root"]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "rate-at-time")
	var rep: String = need.get("rep", "equation")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "rep": rep, "ctx": 0, "T": 0, "t0": 0, "v": 0.0, "r": 0.0}
		var ok := false
		match ask:
			"rate-at-time", "rate-with-units", "rate-other-unit", "rising-or-falling", "interpret-rate", "tangent-estimate":
				ok = _at_time(rng, s)
			"time-at-rate":
				ok = _time_at(rng, s)
			"greatest-rate", "time-of-greatest-rate":
				ok = _greatest(rng, s)
			"compare-models":
				ok = _compare(rng, s)
			"time-rate-greater":
				ok = _rates_cross(rng, s)
			"steeper-tangent":
				ok = _tangents(rng, s)
			"product-from-table", "rising-from-table":
				ok = _product_table(rng, s)
			"quotient-from-table":
				ok = _quotient_table(rng, s)
			"chain-from-table":
				ok = _chain_table(rng, s)
			"composite-with-model":
				ok = _composite(rng, s)
			"product-from-graphs":
				ok = _product_graphs(rng, s)
			"quotient-from-graphs":
				ok = _quotient_graphs(rng, s)
			"chain-from-graphs":
				ok = _chain_graphs(rng, s)
		if ok:
			return s
	push_error("DerivativeModelSituation: no clean situation for %s" % ask)
	return {}


# ── The models ───────────────────────────────────────────────

static func y(m: Dictionary, t: float) -> float:
	match m.fam:
		"exp":
			return m.P.to_float() * exp(m.k.to_float() * t)
		"logistic":
			return m.L.to_float() / (1.0 + m.a.to_float() * exp(-m.k.to_float() * t))
		"pulse":
			return m.a.to_float() * t * exp(-m.k.to_float() * t)
		"wave":
			return m.c.to_float() + m.m.to_float() * t + m.B.to_float() * cos(m.w.to_float() * t)
		"log":
			return m.c.to_float() + m.a.to_float() * log(m.b.to_float() * t + 1.0)
	return m.c.to_float() + m.m.to_float() * t


static func dy(m: Dictionary, t: float) -> float:
	match m.fam:
		"exp":
			return m.P.to_float() * m.k.to_float() * exp(m.k.to_float() * t)
		"logistic":
			var e: float = m.a.to_float() * exp(-m.k.to_float() * t)
			return m.L.to_float() * m.k.to_float() * e / pow(1.0 + e, 2.0)
		"pulse":
			return m.a.to_float() * (1.0 - m.k.to_float() * t) * exp(-m.k.to_float() * t)
		"wave":
			return m.m.to_float() - m.B.to_float() * m.w.to_float() * sin(m.w.to_float() * t)
		"log":
			return m.a.to_float() * m.b.to_float() / (m.b.to_float() * t + 1.0)
	return m.m.to_float()


## A model of this family and its story, in s.mod, s.ctx and s.T.
static func _model(rng: Seeded, s: Dictionary, fam: String) -> void:
	var m := {"fam": fam}
	match fam:
		"exp":
			var up := rng.chance(0.5)
			s.ctx = rng.pick(GROW if up else DECAY)
			m.P = Q.new(rng.int_in(5, 60) * 10)
			m.k = Q.new(rng.int_in(3, 30) * (1 if up else -1), 100)
			s.T = rng.pick([10, 12, 15, 20])
		"logistic":
			s.ctx = rng.pick(LOGISTIC)
			m.L = Q.new(rng.int_in(4, 60) * 50)
			m.a = Q.new(rng.int_in(4, 30))
			m.k = Q.new(rng.int_in(4, 16) * 5, 100)
			s.T = ceili(2.0 * log(m.a.to_float()) / m.k.to_float()) + rng.int_in(0, 2)
		"pulse":
			s.ctx = rng.pick(PULSE)
			m.a = Q.new(rng.int_in(2, 12) * 5)
			m.k = Q.new(rng.int_in(3, 12) * 5, 100)
			s.T = ceili(4.0 / m.k.to_float())
		"wave":
			s.ctx = rng.pick(WAVE)
			m.c = Q.new(rng.int_in(2, 8) * 5)
			m.m = Q.new(rng.int_in(1, 12), 10)
			m.B = Q.new(rng.int_in(2, 9))
			m.w = Q.new(rng.int_in(3, 12), 10)
			s.T = ceili(TAU / m.w.to_float()) + rng.int_in(1, 3)
		"log":
			s.ctx = rng.pick(LOG)
			m.c = Q.new(rng.int_in(1, 6) * 5)
			m.a = Q.new(rng.int_in(2, 9) * 5)
			m.b = Q.new(rng.int_in(1, 10), 10)
			s.T = rng.pick([10, 12, 15, 20, 24])
	s.mod = m


## A rate that is a fair 3 s.f. answer whose third figure isn't a 0: that would read the same as
## the 2 s.f. trap.
static func answerable(x: float) -> bool:
	return absf(x) >= RATE_MIN and GdcKit.fair(x) and not Fmt.sf(x).ends_with("0")


static func _pick_fam(rng: Seeded, s: Dictionary) -> String:
	var fams: Array = FAMS.get(s.ask, ALL_FAMS)
	return fams[rng.int_in(0, fams.size() - 1)]


## A value and a rate at a whole time. They read differently, and the rate of one unit of time
## later is different too, so that its slips are options of their own.
static func _at_time(rng: Seeded, s: Dictionary) -> bool:
	_model(rng, s, _pick_fam(rng, s))
	s.t0 = rng.int_in(1, s.T - 1)
	s.v = y(s.mod, s.t0)
	s.r = dy(s.mod, s.t0)
	if s.v <= 0.0 or not answerable(s.r) or not GdcKit.fair(s.v) or Fmt.sf(absf(s.r)) == Fmt.sf(s.v):
		return false
	match s.ask:
		"rate-other-unit":
			var div: int = DerivativeModelViews.shorter(s.ctx).div
			return answerable(s.r / div) and Fmt.sf(s.r / div) != Fmt.sf(s.r)
		"tangent-estimate":
			s.h = Q.new(rng.int_in(1, 5), 10)
			var h: float = s.h.to_float()
			var est: float = estimate(s)
			return est > 0.0 and answerable(est) and Fmt.sf(est) != Fmt.sf(y(s.mod, s.t0 + h)) and Fmt.sf(est) != Fmt.sf(s.v)
	return true


## The tangent at t0 at t0 + h.
static func estimate(s: Dictionary) -> float:
	return s.v + s.r * s.h.to_float()


## The change in S over the unit of time from t0: what a slip takes for the rate.
static func next_change(s: Dictionary) -> float:
	return y(s.mod, s.t0 + 1) - s.v


## What drops out of the rate when the inner derivative is left out, where it is the rule's own step.
static func no_inner(m: Dictionary, t: float) -> float:
	match m.fam:
		"log":
			return m.a.to_float() / (m.b.to_float() * t + 1.0)
		"wave":
			return m.m.to_float() - m.B.to_float() * sin(m.w.to_float() * t)
	return NAN


## f′ × g′ for the product a·t × e^(−kt).
static func product_slip(m: Dictionary, t: float) -> float:
	return -m.a.to_float() * m.k.to_float() * exp(-m.k.to_float() * t)


## The times the rate is k on the domain, in order.
static func rate_times(s: Dictionary, k: float) -> Array:
	var m: Dictionary = s.mod
	return GdcKit.zeros(func(t: float) -> float: return dy(m, t) - k, 0.0, float(s.T), SAMPLES)


## The times the amount itself is k.
static func amount_times(s: Dictionary, k: float) -> Array:
	var m: Dictionary = s.mod
	return GdcKit.zeros(func(t: float) -> float: return y(m, t) - k, 0.0, float(s.T), SAMPLES)


## A round rate on the way, and the first time it is reached.
static func _time_at(rng: Seeded, s: Dictionary) -> bool:
	_model(rng, s, ALL_FAMS[rng.int_in(0, ALL_FAMS.size() - 1)])
	var hidden := rng.int_in(5, (s.T - 1) * 10) / 10.0
	var k := two_figures(dy(s.mod, hidden))
	if k.is_zero() or absf(k.to_float()) < RATE_MIN:
		return false
	s.k = k
	var roots := rate_times(s, k.to_float())
	if roots.is_empty():
		return false
	s.x = roots[0]
	s.first = roots.size() > 1
	s.t0 = 0
	if s.x < TIME_GAP or s.x > s.T - TIME_GAP or not answerable(s.x):
		return false
	# The second time of a hump or a wave stands off, so "first" is a real choice.
	if roots.size() > 1 and roots[1] - roots[0] < TIME_GAP:
		return false
	return true


## x to 2 significant figures, exactly.
static func two_figures(x: float) -> Q:
	if x == 0.0:
		return Q.new(0)
	var e := floori(log(absf(x)) / log(10.0))
	var unit := e - 1
	if unit >= 0:
		return Q.new(roundi(x / pow(10.0, unit)) * int(pow(10.0, unit)))
	return Q.new(roundi(x * pow(10.0, -unit)), int(pow(10.0, -unit)))


## The time and size of the greatest rate. A pulse's greatest rate is its fall.
static func top_of(s: Dictionary) -> Dictionary:
	var m: Dictionary = s.mod
	match m.fam:
		"logistic":
			var t: float = log(m.a.to_float()) / m.k.to_float()
			return {"t": t, "r": dy(m, t)}
		"pulse":
			var t: float = 2.0 / m.k.to_float()
			return {"t": t, "r": -dy(m, t)}
	var t: float = 3.0 * PI / (2.0 * m.w.to_float())
	return {"t": t, "r": dy(m, t)}


## Where the amount itself is greatest on the domain, and how much it is.
static func peak_of(s: Dictionary) -> Dictionary:
	var m: Dictionary = s.mod
	var at := float(s.T)
	var best := y(m, at)
	var f := func(t: float) -> float: return y(m, t)
	var df := func(t: float) -> float: return dy(m, t)
	for p in GdcKit.turns(f, df, 0.0, float(s.T), SAMPLES):
		if p.kind == "max" and p.y > best:
			at = p.x
			best = p.y
	return {"t": at, "y": best}


static func _greatest(rng: Seeded, s: Dictionary) -> bool:
	_model(rng, s, _pick_fam(rng, s))
	s.top = top_of(s)
	s.fall = s.mod.fam == "pulse"
	s.t0 = 0
	var t: float = s.top.t
	if t < 1.0 or t > s.T - 1.0 or s.mod.fam == "wave" and 3.5 * PI <= s.mod.w.to_float() * s.T:
		return false
	var height := y(s.mod, t)
	var p := peak_of(s)
	if absf(p.t - t) < TIME_GAP or not GdcKit.fair(height) or not GdcKit.fair(p.y):
		return false
	return answerable(t) and answerable(s.top.r) and Fmt.sf(height) != Fmt.sf(s.top.r) and Fmt.sf(p.y) != Fmt.sf(s.top.r)


## Two models of one story: a hump and an exponential. The one that rises faster is behind.
static func _compare(rng: Seeded, s: Dictionary) -> bool:
	_model(rng, s, "logistic")
	var m := {"fam": "exp", "P": Q.new(rng.int_in(2, 40) * 10), "k": Q.new(rng.int_in(2, 30), 100)}
	s.mod2 = m
	s.t0 = rng.int_in(1, s.T - 1)
	s.flip = rng.chance(0.5)
	var a: float = dy(s.mod, s.t0)
	var b: float = dy(m, s.t0)
	var va: float = y(s.mod, s.t0)
	var vb: float = y(m, s.t0)
	s.v = va
	s.r = a
	if (a > b) == (va > vb) or minf(a, b) < RATE_MIN or absf(a - b) < 0.25 * maxf(a, b):
		return false
	return GdcKit.fair(a) and GdcKit.fair(b) and GdcKit.fair(va) and GdcKit.fair(vb) and GdcKit.fair(absf(a - b))


## A wave and a straight line, whose rates cross. pieces are the stretches where the line's rate
## is the greater; amounts the same for the line above the wave.
static func _rates_cross(rng: Seeded, s: Dictionary) -> bool:
	_model(rng, s, "wave")
	var m: Dictionary = s.mod
	var line := {"fam": "line", "c": Q.new(rng.int_in(1, 8) * 5), "m": Q.new(rng.int_in(1, 30), 10)}
	s.mod2 = line
	var k: float = line.m.to_float()
	s.cross = rate_times(s, k)
	if s.cross.size() < 2:
		return false
	for i in s.cross.size() - 1:
		if s.cross[i + 1] - s.cross[i] < TIME_GAP:
			return false
	s.pieces = stretches(func(t: float) -> bool: return dy(m, t) < k, s.cross, s.T)
	s.xs = total(s.pieces)
	s.t0 = 0
	if not answerable(s.xs) or s.xs >= s.T - TIME_GAP:
		return false
	# The slip: the line's height over the wave's.
	var meet := GdcKit.zeros(func(t: float) -> float: return y(m, t) - y(line, t), 0.0, float(s.T), SAMPLES)
	var over := total(stretches(func(t: float) -> bool: return y(line, t) > y(m, t), meet, s.T))
	s.above = over
	return Fmt.sf(over) != Fmt.sf(s.xs) and Fmt.sf(s.T - s.xs) != Fmt.sf(s.xs) and (over <= 0.0 or over >= 0.3 and GdcKit.fair(over))


## The stretches of [0, T] between the cuts, where inside holds.
static func stretches(inside: Callable, cuts: Array, top: int) -> Array:
	var ends: Array = [0.0]
	ends.append_array(cuts)
	ends.append(float(top))
	var out: Array = []
	for i in ends.size() - 1:
		if ends[i + 1] - ends[i] > 1e-9 and inside.call((ends[i] + ends[i + 1]) / 2.0):
			out.append([ends[i], ends[i + 1]])
	return out


static func total(pieces: Array) -> float:
	var sum := 0.0
	for p in pieces:
		sum += p[1] - p[0]
	return sum


## Two points on a curve. The first rises faster, and the second is higher: on a wave it may be
## falling, more steeply than the first rises.
static func _tangents(rng: Seeded, s: Dictionary) -> bool:
	_model(rng, s, _pick_fam(rng, s))
	var m: Dictionary = s.mod
	s.t1 = rng.int_in(1, s.T - 1)
	s.t2 = rng.int_in(1, s.T - 1)
	s.flip = rng.chance(0.5)
	s.t0 = 0
	if s.t1 == s.t2:
		return false
	var a := dy(m, s.t1)
	var b := dy(m, s.t2)
	s.opposite = b < 0.0
	if a < RATE_MIN or absf(b) < RATE_MIN or y(m, s.t2) <= y(m, s.t1) + 0.5:
		return false
	if s.opposite:
		return absf(b) >= 1.3 * a and GdcKit.fair(a) and GdcKit.fair(b)
	return a >= 1.3 * b and GdcKit.fair(a) and GdcKit.fair(b)


# ── Rules with values ────────────────────────────────────────

## The four columns at t = 1 to 4, none of them 0, with the point a among them.
static func _columns(rng: Seeded, s: Dictionary) -> void:
	s.ts = [1, 2, 3, 4]
	s.a = rng.int_in(1, 4)
	s.f = []
	s.g = []
	s.df = []
	s.dg = []
	for i in 4:
		s.f.append(rng.int_in(2, 20))
		s.g.append(rng.int_in(2, 20))
		s.df.append(ExtensionViews.nonzero(rng, -6, 6))
		s.dg.append(ExtensionViews.nonzero(rng, -6, 6))


static func at(col: Array, s: Dictionary) -> int:
	return col[s.a - 1]


static func _product_table(rng: Seeded, s: Dictionary) -> bool:
	_columns(rng, s)
	s.story = rng.int_in(0, STORIES - 1)
	var f := at(s.f, s)
	var g := at(s.g, s)
	var df := at(s.df, s)
	var dg := at(s.dg, s)
	var r := df * g + f * dg
	if r == 0 or absi(r) == absi(df * dg) or absi(r) == absi(f * g):
		return false
	if s.ask == "rising-from-table":
		# The slip gives the other direction.
		return (r > 0) != (df * dg > 0)
	return r != df * dg + f * dg


## The column g(a) is one that makes a decimal, and g′(a) too.
static func _quotient_table(rng: Seeded, s: Dictionary) -> bool:
	_columns(rng, s)
	s.story = rng.int_in(0, QUOTIENT_STORIES - 1)
	s.g[s.a - 1] = rng.pick(G_AT)
	s.dg[s.a - 1] = rng.pick(DG_AT) * rng.pick([1, -1])
	return quotient(at(s.f, s), at(s.g, s), at(s.df, s), at(s.dg, s)) != null


## (f′g − fg′)/g², when it isn't 0 and its slips differ.
static func quotient(f: int, g: int, df: int, dg: int) -> Variant:
	var r := Q.new(df * g - f * dg, g * g)
	if r.is_zero() or r.eq(Q.new(df, dg)) or r.eq(Q.new(df, g)):
		return null
	return r


## f at x = 1 to 4, g(a) inside that, g′(a) too, so that each slip is a value in the table.
static func _chain_table(rng: Seeded, s: Dictionary) -> bool:
	_columns(rng, s)
	s.g = [rng.int_in(1, 4), rng.int_in(1, 4), rng.int_in(1, 4), rng.int_in(1, 4)]
	s.dg[s.a - 1] = rng.int_in(1, 4)
	var a: int = s.a
	var b := at(s.g, s)
	var c := at(s.dg, s)
	# The three places f′ could be read from are different rows, with different values.
	if b == a or c == a or c == b:
		return false
	var fb: int = s.df[b - 1]
	return fb != s.df[a - 1] and fb != s.df[c - 1] and s.df[a - 1] != s.df[c - 1] and c != 1


## h from g in a table: its value by the rule needs a GDC.
static func _composite(rng: Seeded, s: Dictionary) -> bool:
	_columns(rng, s)
	s.form = SHAPES[rng.int_in(0, SHAPES.size() - 1)]
	s.A = Q.new(rng.int_in(2, 12) * 5)
	s.c = Q.new(rng.int_in(1, 6), 10)
	s.g = s.g.map(func(v): return rng.int_in(2, 9))
	var r := composite(s, at(s.g, s), at(s.dg, s))
	return answerable(r) and at(s.dg, s) != at(s.g, s) and answerable(composite(s, s.a, at(s.dg, s))) and at(s.g, s) != s.a


## h′ = f′(u) × g′, for the outer function of s.form.
static func composite(s: Dictionary, u: float, dg: float) -> float:
	var a: float = s.A.to_float()
	match s.form:
		"exp":
			var c: float = s.c.to_float()
			return a * c * exp(c * u) * dg
		"ln":
			return a / u * dg
	return a / (2.0 * sqrt(u)) * dg


## Straight pieces between x = 0, 2, 4 and 6, at whole heights 1 to 8, with whole gradients.
static func _pieces(rng: Seeded) -> Array:
	var out: Array = [rng.int_in(1, 8)]
	while out.size() < 4:
		var v: int = out[out.size() - 1] + rng.pick([-4, -2, 2, 4])
		if v >= 1 and v <= 8:
			out.append(v)
	return out


## The height of pieces at x, and the gradient, at an odd x.
static func height(pieces: Array, x: int) -> int:
	return (pieces[(x - 1) / 2] + pieces[(x + 1) / 2]) / 2


static func slope(pieces: Array, x: int) -> int:
	return (pieces[(x + 1) / 2] - pieces[(x - 1) / 2]) / 2


## The two graphs end apart, so that the letter at each end is plainly its own.
static func _apart(s: Dictionary) -> bool:
	return absi(s.fv[3] - s.gv[3]) >= 2


static func _product_graphs(rng: Seeded, s: Dictionary) -> bool:
	s.a = rng.pick([1, 3, 5])
	s.fv = _pieces(rng)
	s.gv = _pieces(rng)
	var f := height(s.fv, s.a)
	var g := height(s.gv, s.a)
	var df := slope(s.fv, s.a)
	var dg := slope(s.gv, s.a)
	var r := df * g + f * dg
	return _apart(s) and r != 0 and absi(r) != absi(df * dg) and r != df * dg + f * dg and absi(r) != f * g


static func _quotient_graphs(rng: Seeded, s: Dictionary) -> bool:
	s.a = rng.pick([1, 3, 5])
	s.fv = _pieces(rng)
	s.gv = _pieces(rng)
	var g := height(s.gv, s.a)
	var dg := slope(s.gv, s.a)
	if not g in G_AT or not absi(dg) in DG_AT:
		return false
	return _apart(s) and quotient(height(s.fv, s.a), g, slope(s.fv, s.a), dg) != null


## f on x = 0 to 6, and g(a) an odd x where f has a gradient: the slip reads f′ on another piece.
static func _chain_graphs(rng: Seeded, s: Dictionary) -> bool:
	s.a = rng.pick([1, 3, 5])
	s.fv = _pieces(rng)
	s.gv = [rng.pick([0, 2, 4, 6]), rng.pick([0, 2, 4, 6]), rng.pick([0, 2, 4, 6]), rng.pick([0, 2, 4, 6])]
	var a: int = s.a
	var b := height(s.gv, a)
	var c := slope(s.gv, a)
	if not b in [1, 3, 5] or c == 0 or b == a:
		return false
	var fb := slope(s.fv, b)
	return _apart(s) and fb != 0 and fb != slope(s.fv, a)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
