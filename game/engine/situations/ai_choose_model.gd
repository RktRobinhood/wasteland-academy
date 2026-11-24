class_name AiChooseModelSituation
extends RefCounted
## The `ai-choose-model` situation (curriculum/question-types.json), FAL-1001: data, a scatter or a
## story that fits exactly one model family, and a model in context whose sensible inputs the
## situation limits, for fn-ai-choose-model (AI-SL2.6.choose-model and reasonable-domain). Every AI
## paper allows a GDC, so every question is Paper 2.
##
## need.ask is the unknown and need.rep its representation (see AiChooseModelViews). generate()
## returns a Dictionary:
##   paper, ask, rep, angle, ctx   always 2; the unknown; the representation; the method; a story index
##   family-from-table: fam ("linear", "quadratic" or "exponential"), xs and ys (Q, five values at
##     equal steps), d (linear), a2 (the second difference), r (the ratio), names [x, y], story
##   family-from-graph: mode "one" (one scatter, fam) or "pick" (four cards, target, cards: [{fam,
##     pts}]); pts are [[x, y], ...] floats to 1 d.p., a family's data with a little noise
##   family-from-context, reason-against: story (see STORIES: fam, kind, numbers), prop (the family
##     proposed, reason-against), pts (the story's data, on a graph)
##   domain-from-zero: kind "flight" (h = −4.9t² + v t + h0) or "tank" (V = V0 − r t), T (the zero
##     after the start), neg (flight: the zero before it), tp (flight: the peak), td (the last time
##     the data were measured)
##   domain-from-dimensions: kind "card" (a by b, a < b, squares x cut from each corner) or "pen"
##     (F m of fence, two sides x against a wall); top: the excluded end, a Q
##   domain-whole-numbers: kind (a count's story), N (the most there can be), m and c of the model
##
## The numbers are drawn, not taken from any exam question. The SymPy checker
## (tools/check_answers.py, r3ch_check) reads every value back from what the question shows and
## works it out again.

const TRIES := 3000
const WHO := 6
## A 3 s.f. answer is at least this far (a fraction of its last place) from a rounding edge.
const EDGE := 0.04
## The scatters' inputs: 0 to 12 in steps of 0.5.
const STEPS := 25
const STEP := 0.5

## The stories that name a family: [family, kind]. Growth and decay are both exponential.
const STORIES := [["linear", "tank"], ["linear", "rover"], ["exponential", "beetles"], ["exponential", "moss"],
	["exponential", "isotope"], ["sinusoidal", "tide"], ["sinusoidal", "wheel"], ["quadratic", "flare"], ["quadratic", "ball"]]
## Which families a story's family may be wrongly proposed as (reason-against).
const PROPOSED := {"sinusoidal": ["linear", "quadratic", "exponential"], "quadratic": ["linear", "exponential"],
	"growth": ["linear"], "decay": ["linear", "quadratic"], "linear": ["exponential", "quadratic"]}


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "family-from-table")
	var rep: String = need.get("rep", "")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "rep": rep, "angle": need.get("angle", "any"), "ctx": rng.int_in(0, WHO - 1)}
		if _draw(rng, s):
			return s
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"family-from-table":
			return _table(rng, s)
		"family-from-graph":
			return _graph(rng, s)
		"family-from-context":
			return _context(rng, s)
		"reason-against":
			return _against(rng, s)
		"domain-from-zero":
			return _zero(rng, s)
		"domain-from-dimensions":
			return _dimensions(rng, s)
		"domain-whole-numbers":
			return _whole(rng, s)
	return false


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)


# ── Small tools ──────────────────────────────────────────────

static func clear(x: float) -> bool:
	return Answer.rounds_clearly(x, EDGE)


## A float from lo to hi in steps of 0.01, from the stream.
static func uniform(rng: Seeded, lo: float, hi: float) -> float:
	return lo + (hi - lo) * rng.int_in(0, 100) / 100.0


static func r1(x: float) -> float:
	return roundf(x * 10.0) / 10.0


## Consecutive differences of Q values.
static func diffs(ys: Array) -> Array:
	var out: Array = []
	for i in ys.size() - 1:
		out.append(ys[i + 1].sub(ys[i]))
	return out


static func all_equal(qs: Array) -> bool:
	for q in qs:
		if not q.eq(qs[0]):
			return false
	return true


# ── A table at equal steps ───────────────────────────────────

const TABLE_NAMES := [["t (hours)", "R"], ["t (days)", "N"], ["x", "y"], ["t (weeks)", "M"], ["x", "y"], ["t (years)", "V"]]


static func _table(rng: Seeded, s: Dictionary) -> bool:
	var fam: String = ["linear", "quadratic", "exponential"][rng.int_in(0, 2)]
	var x0: int = rng.pick([0, 1])
	var h: int = rng.pick([1, 1, 2, 5])
	var ys: Array = []
	match fam:
		"linear":
			var c := rng.int_in(3, 60)
			var d := rng.int_in(2, 25)
			for i in 5:
				ys.append(Q.new(c + d * i))
			s.d = Q.new(d)
		"quadratic":
			var a := rng.int_in(1, 4)
			var b := rng.int_in(0, 8)
			var c := rng.int_in(2, 40)
			for i in 5:
				ys.append(Q.new(a * i * i + b * i + c))
			s.a2 = Q.new(2 * a)
		_:
			# Ratios whose values stay whole: [r as n/d, the start's factor].
			var pick: Array = rng.pick([[Q.new(2), 1, 3, 15], [Q.new(3), 1, 2, 6], [Q.new(3, 2), 16, 1, 3], [Q.new(1, 2), 16, 1, 4],
				[Q.new(6, 5), 625, 1, 2], [Q.new(4, 5), 625, 1, 2], [Q.new(11, 10), 10000, 1, 1]])
			var r: Q = pick[0]
			var c := Q.new(pick[1] * rng.int_in(pick[2], pick[3]))
			var y := c
			for i in 5:
				ys.append(y)
				y = y.mul(r)
			s.r = r
	var ds := diffs(ys)
	var d2 := diffs(ds)
	var ratios: Array = []
	for i in 4:
		ratios.append(ys[i + 1].div(ys[i]))
	# Exactly one family fits: the first differences, the second or the ratios are constant.
	var lin: bool = all_equal(ds)
	var quad: bool = all_equal(d2) and not d2[0].is_zero()
	var expo: bool = all_equal(ratios)
	if [lin, quad, expo].count(true) != 1:
		return false
	# A linear or quadratic table's working shows its ratios to 3 s.f.: they must read as not constant.
	if not expo:
		var shown := {}
		for q in ratios:
			shown[Fmt.sf(q)] = true
		if shown.size() == 1:
			return false
	s.fam = fam
	s.xs = range(5).map(func(i): return Q.new(x0 + h * i))
	s.ys = ys
	s.names = TABLE_NAMES[s.ctx]
	return true


# ── Scatters ─────────────────────────────────────────────────

## The family's clean curve, from its parameters.
static func curve_y(f: Dictionary, x: float) -> float:
	match f.fam:
		"linear":
			return f.c + f.m * x
		"quadratic":
			return f.H - f.k * (x - f.p) * (x - f.p)
		"exponential", "growth", "decay":
			return f.c * pow(f.r, x)
		"sinusoidal":
			return f.D + f.A * sin(TAU * x / f.P + f.phi)
	return 0.0


## A family's curve, with parameters that show its shape clearly on 0 ≤ x ≤ 12.
static func shape(rng: Seeded, fam: String) -> Dictionary:
	match fam:
		"linear":
			var up := rng.chance(0.6)
			var m := uniform(rng, 2.0, 5.0)
			return {"fam": "linear", "m": m if up else -m, "c": uniform(rng, 5.0, 15.0) if up else uniform(rng, 60.0, 75.0)}
		"quadratic":
			var p := uniform(rng, 4.5, 7.5)
			var H := uniform(rng, 45.0, 80.0)
			var e := uniform(rng, 3.0, 12.0)
			return {"fam": "quadratic", "p": p, "H": H, "k": (H - e) / pow(maxf(p, 12.0 - p), 2)}
		"exponential", "growth":
			var c := uniform(rng, 1.5, 4.0)
			var top := uniform(rng, 50.0, 90.0)
			return {"fam": "growth", "c": c, "r": pow(top / c, 1.0 / 12.0)}
		"decay":
			var c := uniform(rng, 60.0, 90.0)
			return {"fam": "decay", "c": c, "r": uniform(rng, 0.7, 0.8)}
		"sinusoidal":
			var A := uniform(rng, 10.0, 25.0)
			return {"fam": "sinusoidal", "A": A, "D": A + uniform(rng, 8.0, 30.0), "P": uniform(rng, 4.0, 5.0), "phi": uniform(rng, 0.0, TAU)}
	return {}


## The family's data at x = 0, 0.5, …, 12, with noise that keeps its shape: a share of the
## range, or of the value itself for an exponential.
static func noisy(rng: Seeded, f: Dictionary) -> Array:
	var ys: Array = []
	for i in STEPS:
		ys.append(curve_y(f, i * STEP))
	var lo: float = ys.min()
	var hi: float = ys.max()
	var out: Array = []
	for i in STEPS:
		var u := rng.int_in(-100, 100) / 100.0
		var y: float = ys[i]
		if f.fam in ["growth", "decay"]:
			y *= 1.0 + 0.03 * u
		else:
			y += 0.02 * (hi - lo) * u
		out.append([i * STEP, r1(maxf(y, 0.3))])
	return out


## What a scatter's points do, worked from the points alone: "linear", "quadratic" (one
## peak), "growth", "decay", "sinusoidal" or "" when none is clear.
static func classify(pts: Array) -> String:
	var ys: Array = pts.map(func(p): return float(p[1]))
	var lo: float = ys.min()
	var hi: float = ys.max()
	var span := hi - lo
	if span <= 0.0:
		return ""
	var peaks := turns(ys, span, 1)
	var troughs := turns(ys, span, -1)
	var line := fit_rms(pts, 1) / span
	if peaks >= 2 and troughs >= 2:
		return "sinusoidal"
	if peaks == 1 and troughs == 0 and fit_rms(pts, 2) / span < 0.05:
		return "quadratic"
	if peaks == 0 and troughs == 0:
		if line < 0.04:
			return "linear"
		var n := ys.size()
		var q := n / 4
		var first: float = ys[q] - ys[0]
		var last: float = ys[n - 1] - ys[n - 1 - q]
		if line > 0.07 and ys[n - 1] > ys[0] and last > 4.0 * absf(first):
			return "growth"
		if line > 0.07 and ys[n - 1] < ys[0] and absf(first) > 4.0 * absf(last):
			return "decay"
	return ""


## Interior peaks (dir 1) or troughs (dir −1) that stand out by more than a quarter of the range.
static func turns(ys: Array, span: float, dir: int) -> int:
	var n := 0
	for i in range(1, ys.size() - 1):
		var y: float = ys[i] * dir
		if y < ys[i - 1] * dir or y < ys[i + 1] * dir:
			continue
		var left: float = ys.slice(0, i).map(func(v): return v * dir).min()
		var right: float = ys.slice(i + 1).map(func(v): return v * dir).min()
		var tall := true
		for j in ys.size():
			if absi(j - i) <= 3 and ys[j] * dir > y:
				tall = false
		if tall and y - maxf(left, right) > 0.25 * span:
			n += 1
	return n


## The RMS residual of a least-squares polynomial of degree 1 or 2 through the points.
static func fit_rms(pts: Array, degree: int) -> float:
	var n := degree + 1
	var m: Array = []
	for i in n:
		var row: Array = []
		for j in n + 1:
			row.append(0.0)
		m.append(row)
	for p in pts:
		var x: float = p[0]
		var y: float = p[1]
		for i in n:
			for j in n:
				m[i][j] += pow(x, i + j)
			m[i][n] += y * pow(x, i)
	# Gauss–Jordan elimination with partial pivoting.
	for c in n:
		var best := c
		for r in range(c + 1, n):
			if absf(m[r][c]) > absf(m[best][c]):
				best = r
		var t = m[c]
		m[c] = m[best]
		m[best] = t
		for r in n:
			if r == c:
				continue
			var f: float = m[r][c] / m[c][c]
			for j in range(c, n + 1):
				m[r][j] -= f * m[c][j]
	var co: Array = []
	for i in n:
		co.append(m[i][n] / m[i][i])
	var ss := 0.0
	for p in pts:
		var fx := 0.0
		for i in n:
			fx += co[i] * pow(p[0], i)
		ss += pow(p[1] - fx, 2)
	return sqrt(ss / pts.size())


## A family's data whose shape reads as that family and nothing else.
static func scatter(rng: Seeded, fam: String) -> Array:
	var want := "growth" if fam == "exponential" else fam
	for i in 200:
		var pts := noisy(rng, shape(rng, fam))
		if classify(pts) == want:
			return pts
	return []


static func _graph(rng: Seeded, s: Dictionary) -> bool:
	var fams := ["linear", "quadratic", "exponential", "sinusoidal"]
	if rng.chance(0.5):
		s.mode = "one"
		s.fam = fams[rng.int_in(0, 3)]
		s.pts = scatter(rng, s.fam)
		return not s.pts.is_empty()
	s.mode = "pick"
	s.target = fams[rng.int_in(0, 3)]
	s.cards = []
	for f in fams:
		var pts := scatter(rng, f)
		if pts.is_empty():
			return false
		s.cards.append({"fam": f, "pts": pts})
	return true


# ── Stories ──────────────────────────────────────────────────

## A story's numbers: [family, kind] from STORIES, then what the story says.
static func story(rng: Seeded, i: int) -> Dictionary:
	var st := {"fam": STORIES[i][0], "kind": STORIES[i][1]}
	match st.kind:
		"tank":
			st.a = 10 * rng.int_in(5, 40)
			st.r = rng.int_in(12, 45)
		"rover":
			st.a = rng.int_in(2, 15)
			st.r = rng.int_in(6, 18)
		"beetles":
			st.a = 10 * rng.int_in(4, 30)
			st.p = rng.int_in(20, 35)
		"moss":
			st.a = rng.int_in(2, 9)
			st.p = rng.int_in(20, 35)
		"isotope":
			st.a = 10 * rng.int_in(6, 20)
			st.p = rng.int_in(20, 30)
		"tide":
			st.lo = rng.int_in(2, 5)
			st.hi = st.lo + rng.int_in(4, 9)
			st.T = Q.new(rng.pick([123, 124, 125]), 10)
		"wheel":
			st.lo = rng.int_in(2, 4)
			st.hi = st.lo + 2 * rng.int_in(8, 20)
			st.T = Q.new(rng.int_in(8, 20))
		"flare", "ball":
			st.tp = Q.new(rng.int_in(4, 7), 2) if st.kind == "flare" else Q.new(rng.int_in(8, 16), 10)
			st.H = Q.new(49, 10).mul(st.tp.sq())
	if st.kind in ["beetles", "moss"]:
		st.shape = "growth"
	elif st.kind == "isotope":
		st.shape = "decay"
	else:
		st.shape = st.fam
	return st


## The story's measurements as a scatter: the model at 25 equal steps with a little noise. Its
## inputs are the story's own times; the window is scaled to them.
static func story_points(rng: Seeded, st: Dictionary) -> Array:
	var span := 12.0
	var f := {}
	match st.kind:
		"tank", "rover":
			f = {"fam": "linear", "c": float(st.a), "m": float(st.r)}
		"beetles", "moss":
			f = {"fam": "growth", "c": float(st.a), "r": 1.0 + st.p / 100.0}
		"isotope":
			f = {"fam": "decay", "c": float(st.a), "r": 1.0 - st.p / 100.0}
		"tide", "wheel":
			# Starting at the low point: D − A cos(2πt/T).
			var A: float = (st.hi - st.lo) / 2.0
			span = 2.5 * st.T.to_float()
			f = {"fam": "sinusoidal", "A": A, "D": st.lo + A, "P": st.T.to_float(), "phi": -PI / 2.0}
		"flare", "ball":
			span = 2.0 * st.tp.to_float()
			f = {"fam": "quadratic", "H": st.H.to_float(), "p": st.tp.to_float(), "k": 4.9}
	var step := span / (STEPS - 1)
	var ys: Array = []
	for i in STEPS:
		ys.append(curve_y(f, i * step))
	var lo: float = ys.min()
	var hi: float = ys.max()
	var out: Array = []
	for i in STEPS:
		var u := rng.int_in(-100, 100) / 100.0
		var y: float = ys[i]
		if f.fam in ["growth", "decay"]:
			y *= 1.0 + 0.03 * u
		elif i > 0 and i < STEPS - 1 or f.fam != "quadratic":
			y += 0.02 * (hi - lo) * u
		out.append([snappedf(i * step, 0.01), r1(maxf(y, 0.0 if f.fam == "quadratic" else 0.3))])
	return out


static func _context(rng: Seeded, s: Dictionary) -> bool:
	s.story = story(rng, rng.int_in(0, STORIES.size() - 1))
	return true


static func _against(rng: Seeded, s: Dictionary) -> bool:
	s.story = story(rng, rng.int_in(0, STORIES.size() - 1))
	var props: Array = PROPOSED[s.story.shape]
	s.prop = props[rng.int_in(0, props.size() - 1)]
	if s.rep == "graph":
		for i in 200:
			var pts := story_points(rng, s.story)
			if classify(pts) == s.story.shape:
				s.pts = pts
				return true
		return false
	return true


# ── A domain that ends at a zero ─────────────────────────────

static func _zero(rng: Seeded, s: Dictionary) -> bool:
	if rng.chance(0.6):
		s.kind = "flight"
		var tower := rng.chance(0.4)
		s.tower = tower
		s.v = Q.new(rng.int_in(8, 24))
		s.h0 = Q.new(rng.int_in(50, 250), 10) if tower else Q.new(rng.int_in(10, 25), 10)
		var v: float = s.v.to_float()
		var h0: float = s.h0.to_float()
		var root := sqrt(v * v + 19.6 * h0)
		var T := (v + root) / 9.8
		var neg := (v - root) / 9.8
		var tp := v / 9.8
		s.td = Q.new(maxi(1, floori(tp)))
		if not (clear(T) and clear(neg) and clear(tp)) or Fmt.sf(T) == Fmt.sf(tp) or Fmt.sf(T).ends_with("0"):
			return false
		s.T = T
		s.neg = neg
		s.tp = tp
		return true
	s.kind = "tank"
	s.V0 = Q.new(50 * rng.int_in(8, 60))
	s.r = Q.new(rng.int_in(7, 60))
	var T: float = s.V0.div(s.r).to_float()
	if not clear(T) or Fmt.sf(T).ends_with("0") or T < 4.0:
		return false
	s.T = T
	s.td = Q.new(floori(T / 2.0))
	return true


# ── A domain from a shape's lengths ──────────────────────────

static func _dimensions(rng: Seeded, s: Dictionary) -> bool:
	if rng.chance(0.6):
		s.kind = "card"
		s.a = rng.int_in(10, 30)
		s.b = s.a + rng.int_in(4, 20)
		s.top = Q.new(s.a, 2)
		return true
	s.kind = "pen"
	s.F = 2 * rng.int_in(8, 60) + rng.pick([0, 1])
	s.top = Q.new(s.F, 2)
	return true


# ── A count ──────────────────────────────────────────────────

static func _whole(rng: Seeded, s: Dictionary) -> bool:
	s.kind = ["tickets", "crates", "seedlings"][rng.int_in(0, 2)]
	match s.kind:
		"tickets":
			s.N = 10 * rng.int_in(12, 60)
			s.m = rng.int_in(6, 25)
			s.c = 50 * rng.int_in(4, 20)
		"crates":
			s.N = rng.int_in(20, 80)
			s.m = rng.int_in(15, 60)
			s.c = 100 * rng.int_in(20, 60)
		_:
			s.N = 5 * rng.int_in(8, 40)
			s.m = rng.int_in(2, 9)
			s.c = 10 * rng.int_in(3, 20)
	return true
