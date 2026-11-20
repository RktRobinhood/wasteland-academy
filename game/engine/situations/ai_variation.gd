class_name AiVariationSituation
extends RefCounted
## The `ai-variation` situation (curriculum/question-types.json), FAL-1001: direct and inverse
## variation y = axⁿ, n = −2, −1, 1, 2 or 3, for fn-ai-variation-model (AI-SL2.5.variation-model,
## AI-SL2.6.find-parameters). Every AI paper allows a GDC, so every question is Paper 2.
##
## need.ask is the unknown and need.rep its representation (see AiVariationViews). generate()
## returns a Dictionary:
##   paper, ask, rep   always 2; the unknown; the representation
##   ctx               the story's index in CONTEXTS ("pure" asymptotes have none: ctx −1)
##   n, a              the power (int) and the constant (Q)
##   x1, y1            the pair given (Q), y1 = a·x1ⁿ;  x1b, y1b: a second pair (find-constant, table)
##   predict:            k (Q), x2 = k·x1, y2 = a·x2ⁿ (Q)
##   input-from-output:  Y (Q), the output; X (float), the input that gives it
##   scale-factor:       k (Q), f = kⁿ (Q)
##   threshold-range:    T (Q), above (y > T, else y < T), b (float) the boundary, rel ("<" or ">")
##   least-whole-number: L (Q), b (float), m = ceil(b) (int)
##   pick-graph:         cards: [{"role", "m" (int) or "minus" true, "c" (float)}], the right one first
##
## The numbers are drawn, not taken from any exam question. The SymPy checker
## (tools/check_answers.py, r3va_check) reads every value back from what the question shows and
## works it out again.

const TRIES := 3000
## A 3 s.f. answer or slip is at least this far (a fraction of its last place) from a rounding edge.
const EDGE := 0.04
## The powers a wrong option may take in place of n.
const POWERS := [-2, -1, 1, 2, 3]

## x, y: the letters; xu, yu: their units as an answer writes them; ylong, xlong: the output and
## the input as the variation's sentence names them, with PHRASE between; xdef: the input, defined
## after a model; xname, yname: for the scale factor; as, xs: the constants and inputs drawn from (decimals as text); whole: an input in
## whole numbers only (a count of workers), so it is only used for the least whole number.
const CONTEXTS := [
	{"id": "beacon", "n": -2, "x": "d", "y": "I", "xu": " m", "yu": " lux",
		"ylong": "The intensity I lux of the light from a signal beacon", "xlong": "the distance d metres from the beacon", "xdef": "d metres is the distance from the beacon",
		"xname": "distance from the beacon", "yname": "intensity",
		"as": ["180", "240", "300", "360", "450", "500", "600", "720", "800", "900", "1200", "1500"],
		"xs": ["2", "2.5", "3", "4", "5", "6", "8", "10"], "whole": false},
	{"id": "heat", "n": -2, "x": "r", "y": "H", "xu": " m", "yu": " W/m²",
		"ylong": "The heat H W/m² felt from a burning fuel dump", "xlong": "the distance r metres from its centre", "xdef": "r metres is the distance from its centre",
		"xname": "distance from the fuel dump", "yname": "heat felt",
		"as": ["2000", "2500", "3200", "3600", "4000", "4500", "5000", "6400", "8000"],
		"xs": ["5", "8", "10", "12", "15", "20", "25", "40"], "whole": false},
	{"id": "crew", "n": -1, "x": "w", "y": "T", "xu": "", "yu": " hours",
		"ylong": "The time T hours that a salvage crew takes to clear a site", "xlong": "the number of workers w in the crew", "xdef": "w is the number of workers in the crew",
		"xname": "number of workers", "yname": "time taken",
		"as": ["24", "36", "48", "60", "72", "84", "90", "96", "120", "144", "180"],
		"xs": ["2", "3", "4", "5", "6", "8", "10", "12"], "whole": true},
	{"id": "pump", "n": -1, "x": "r", "y": "T", "xu": " litres per second", "yu": " minutes",
		"ylong": "The time T minutes taken to drain a flooded bunker", "xlong": "the pumping rate r litres per second", "xdef": "r litres per second is the pumping rate",
		"xname": "pumping rate", "yname": "time taken",
		"as": ["90", "120", "150", "180", "240", "300", "360", "450", "600"],
		"xs": ["1.5", "2", "2.5", "3", "4", "5", "6", "8"], "whole": false},
	{"id": "turbine", "n": 3, "x": "v", "y": "P", "xu": " m/s", "yu": " kW",
		"ylong": "The power P kW of a wind turbine", "xlong": "the wind speed v m/s", "xdef": "v m/s is the wind speed",
		"xname": "wind speed", "yname": "power",
		"as": ["0.2", "0.25", "0.3", "0.4", "0.5", "0.6", "0.75", "0.8", "1.2", "1.5"],
		"xs": ["2", "3", "4", "5", "6", "8", "10"], "whole": false},
	{"id": "buggy", "n": 2, "x": "v", "y": "D", "xu": " km/h", "yu": " m",
		"ylong": "The stopping distance D metres of a dune buggy", "xlong": "its speed v km/h", "xdef": "v km/h is its speed",
		"xname": "speed", "yname": "stopping distance",
		"as": ["0.004", "0.005", "0.006", "0.008", "0.01", "0.012", "0.015"],
		"xs": ["20", "25", "30", "40", "50", "60", "80"], "whole": false},
	{"id": "cable", "n": 2, "x": "d", "y": "L", "xu": " mm", "yu": " kg",
		"ylong": "The greatest load L kg that a steel cable can hold", "xlong": "its diameter d mm", "xdef": "d mm is its diameter",
		"xname": "diameter", "yname": "greatest load",
		"as": ["1.2", "1.5", "2", "2.5", "3", "3.6", "4.5", "5"],
		"xs": ["4", "5", "6", "8", "10", "12"], "whole": false},
	{"id": "pellet", "n": 3, "x": "d", "y": "M", "xu": " mm", "yu": " g",
		"ylong": "The mass M grams of a lead pellet", "xlong": "its diameter d mm", "xdef": "d mm is its diameter",
		"xname": "diameter", "yname": "mass",
		"as": ["0.004", "0.005", "0.006", "0.008"],
		"xs": ["2", "3", "4", "5", "6", "8", "10"], "whole": false},
	{"id": "spring", "n": 1, "x": "w", "y": "e", "xu": " kg", "yu": " cm",
		"ylong": "The extension e cm of a spring", "xlong": "the load w kg hung on it", "xdef": "w kg is the load hung on it",
		"xname": "load", "yname": "extension",
		"as": ["0.4", "0.5", "0.6", "0.75", "1.2", "1.5", "2.5", "3"],
		"xs": ["2", "3", "4", "5", "6", "8", "10", "12"], "whole": false},
]

## How the words say y = axⁿ.
const PHRASE := {-2: "is inversely proportional to the square of", -1: "is inversely proportional to",
	1: "is directly proportional to", 2: "is proportional to the square of", 3: "is proportional to the cube of"}


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "find-constant")
	var rep: String = need.get("rep", "")
	for i in TRIES:
		var s := {"paper": 2, "ask": ask, "rep": rep}
		if _draw(rng, s):
			return s
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"find-constant":
			return _find_constant(rng, s)
		"predict":
			return _predict(rng, s)
		"input-from-output":
			return _input(rng, s)
		"scale-factor":
			return _scale(rng, s)
		"asymptotes":
			return _asymptotes(rng, s)
		"threshold-range":
			return _threshold(rng, s)
		"least-whole-number":
			return _least(rng, s)
		"pick-graph":
			return _pick(rng, s)
	return false


# ── Small tools ──────────────────────────────────────────────

## A decimal written as text, exactly: "0.75" is 3/4.
static func qd(t: String) -> Q:
	var neg := t.begins_with("-")
	var body := t.trim_prefix("-")
	var parts := body.split(".")
	var den := 1
	var digits := parts[0]
	if parts.size() > 1:
		digits += parts[1]
		for i in parts[1].length():
			den *= 10
	return Q.new((-1 if neg else 1) * int(digits), den)


## bᵉ for a Q and any whole e.
static func qpow(b: Q, e: int) -> Q:
	return IntegerPowersSituation.qpow(b, e)


static func f(q: Q) -> float:
	return q.to_float()


## Whether a Q ends as a decimal with at most `figs` significant figures.
static func tidy(q: Q, figs: int = 5) -> bool:
	var t := Fmt.dec(q)
	if t.contains("/"):
		return false
	var digits := t.replace("−", "").replace(".", "").lstrip("0").rstrip("0")
	return digits.length() <= figs


## A value clear of a 3 s.f. rounding edge.
static func clear(x: float) -> bool:
	return Answer.rounds_clearly(x, EDGE)


## y = c·xᵐ.
static func power_at(c: float, m: int, x: float) -> float:
	return c * pow(x, m)


## x with c·xᵐ = y, for x > 0.
static func root_of(y: float, c: float, m: int) -> float:
	return pow(y / c, 1.0 / m)


## A value as an option shows it: as it is when the answer is exact and it ends, else to 3 s.f.
static func reads(v: Variant, exact: bool) -> String:
	if exact and v is Q and not Fmt.dec(v).contains("/"):
		return Fmt.dec(v)
	return Fmt.sf(v)


## Every value reads differently, is positive and finite, and each one shown to 3 s.f. is clear
## of a rounding edge.
static func distinct(vals: Array, exact: bool) -> bool:
	var seen := {}
	for v in vals:
		var x: float = v.to_float() if v is Q else float(v)
		if not is_finite(x) or x <= 0.0:
			return false
		var t := reads(v, exact)
		if not (exact and v is Q and not Fmt.dec(v).contains("/")) and not clear(x):
			return false
		seen[t] = true
	return seen.size() == vals.size()


static func ctx(s: Dictionary) -> Dictionary:
	return CONTEXTS[s.ctx]


## A story whose power is allowed, and a pair (x1, y1) on it with tidy values.
static func draw_pair(rng: Seeded, s: Dictionary, ok: Callable) -> bool:
	var ids: Array = range(CONTEXTS.size()).filter(func(i): return ok.call(CONTEXTS[i]))
	s.ctx = rng.pick(ids)
	var c: Dictionary = CONTEXTS[s.ctx]
	s.n = int(c.n)
	s.a = qd(rng.pick(c.as))
	s.x1 = qd(rng.pick(c.xs))
	s.y1 = s.a.mul(qpow(s.x1, s.n))
	return tidy(s.y1) and f(s.y1) >= 0.1


## The constant found with the power left out: a = y₁/x₁.
static func a_no_power(s: Dictionary) -> Q:
	return s.y1.div(s.x1)


# ── The constant ─────────────────────────────────────────────

static func _find_constant(rng: Seeded, s: Dictionary) -> bool:
	if not draw_pair(rng, s, func(c): return c.n != 1 and not c.whole):
		return false
	if s.rep == "table":
		var c := ctx(s)
		s.x1b = qd(rng.pick(c.xs))
		if s.x1b.eq(s.x1):
			return false
		s.y1b = s.a.mul(qpow(s.x1b, s.n))
		if not tidy(s.y1b) or f(s.y1b) < 0.1:
			return false
	return distinct(constant_slips(s).map(func(p): return p[0]), true)


## [[a, ""], [a slip, its slip], ...]: the power left out ("power"), y = a − x for an inverse
## law ("minus"), and a direct law for an inverse one ("direct").
static func constant_slips(s: Dictionary) -> Array:
	var out: Array = [[s.a, ""], [a_no_power(s), "power"]]
	if s.n == -1:
		out.append([s.y1.add(s.x1), "minus"])
	if s.n < 0:
		out.append([s.y1.div(qpow(s.x1, -s.n)), "direct"])
	return out


## Wrong options with no slip behind them: a from the other powers, y·xⁿ and xⁿ/y.
static func constant_fillers(s: Dictionary) -> Array:
	return [s.y1.mul(qpow(s.x1, s.n)), qpow(s.x1, s.n).div(s.y1)]


# ── A prediction ─────────────────────────────────────────────

static func _predict(rng: Seeded, s: Dictionary) -> bool:
	if not draw_pair(rng, s, func(c): return c.n != 1 and not c.whole):
		return false
	s.k = qd(rng.pick(["2", "3", "0.5", "1.5", "4"]))
	s.x2 = s.x1.mul(s.k)
	s.y2 = s.a.mul(qpow(s.x2, s.n))
	var lo := f(qd(ctx(s).xs[0])) / 2.0
	var hi := f(qd(ctx(s).xs[-1])) * 2.0
	if f(s.x2) < lo or f(s.x2) > hi or not tidy(s.x2, 4):
		return false
	var exact := not Answer.needs_rounding(s.y2)
	return distinct(predict_slips(s).map(func(p): return p[0]), exact)


## [[y₂, ""], [a slip, its slip], ...]: ÷k for an inverse square ("square"), y = a − x
## ("minus"), the power left out of a ("power") and a direct law ("direct").
static func predict_slips(s: Dictionary) -> Array:
	var out: Array = [[s.y2, ""]]
	if s.n == -2:
		out.append([s.y1.div(s.k), "square"])
	if s.n == -1:
		out.append([s.y1.add(s.x1).sub(s.x2), "minus"])
	out.append([a_no_power(s).mul(qpow(s.x2, s.n)), "power"])
	if s.n < 0:
		out.append([s.y1.mul(qpow(s.k, -s.n)), "direct"])
	return out


## The prediction with another power: y₁·kᵐ, kept off the key (more than 10% from it).
static func power_fillers(key: float, vals: Array, named: Array) -> Array:
	var out: Array = []
	for v in vals:
		var x: float = v.to_float() if v is Q else float(v)
		if x <= 0.0 or absf(x - key) <= 0.1 * key:
			continue
		var dup := false
		for o in named + out:
			var y: float = o.to_float() if o is Q else float(o)
			if absf(y - x) <= 1e-9 * maxf(1.0, absf(x)):
				dup = true
		if not dup:
			out.append(v)
	return out


static func predict_fillers(s: Dictionary) -> Array:
	var vals: Array = []
	for m in POWERS:
		if m != s.n:
			vals.append(s.y1.mul(qpow(s.k, m)))
	return power_fillers(f(s.y2), vals, predict_slips(s).map(func(p): return p[0]))


# ── An input from an output ──────────────────────────────────

static func _input(rng: Seeded, s: Dictionary) -> bool:
	if not draw_pair(rng, s, func(c): return not c.whole):
		return false
	var r := qd(rng.pick(["0.25", "0.4", "0.6", "1.5", "2", "2.5", "3", "4"]))
	s.Y = GraphReadingSituation.sf_q(s.y1.mul(r), 2)
	if s.Y.eq(s.y1) or f(s.Y) <= 0.0:
		return false
	s.X = root_of(f(s.Y), f(s.a), s.n)
	if not GdcKit.fair(s.X):
		return false
	var vals: Array = input_slips(s).map(func(p): return p[0])
	return distinct(vals, false)


## [[X, ""], [the power left out of a, "power"]] (n ≠ 1).
static func input_slips(s: Dictionary) -> Array:
	var out: Array = [[s.X, ""]]
	if s.n != 1:
		out.append([root_of(f(s.Y), f(a_no_power(s)), s.n), "power"])
	return out


## The input with the wrong root: (Y/a)^(1/m).
static func input_fillers(s: Dictionary) -> Array:
	var vals: Array = []
	for m in POWERS:
		if m != s.n:
			vals.append(root_of(f(s.Y), f(s.a), m))
	var good: Array = power_fillers(s.X, vals, input_slips(s).map(func(p): return p[0]))
	return good.filter(func(x): return clear(x) and Fmt.sf(x) != Fmt.sf(s.X))


# ── The scale factor ─────────────────────────────────────────

static func _scale(rng: Seeded, s: Dictionary) -> bool:
	var ids: Array = range(CONTEXTS.size()).filter(func(i): return int(CONTEXTS[i].n) != 1)
	s.ctx = rng.pick(ids)
	s.n = int(ctx(s).n)
	s.k = qd(rng.pick(["2", "3", "0.5", "4"]))
	s.f = qpow(s.k, s.n)
	var seen := {}
	for p in scale_slips(s):
		seen[Fmt.dec(p[0])] = true
	return seen.size() == scale_slips(s).size()


## [[kⁿ, ""], ...]: ÷k for an inverse square ("square"), ×k for a cube ("cube") and k^|n| for
## an inverse law ("direct").
static func scale_slips(s: Dictionary) -> Array:
	var out: Array = [[s.f, ""]]
	if s.n == -2:
		out.append([Q.new(1).div(s.k), "square"])
	if s.n == 3:
		out.append([s.k, "cube"])
	if s.n < 0:
		out.append([qpow(s.k, -s.n), "direct"])
	return out


## kᵐ for the other powers.
static func scale_fillers(s: Dictionary) -> Array:
	var out: Array = []
	var seen := {}
	for p in scale_slips(s):
		seen[Fmt.dec(p[0])] = true
	for m in [1, 2, 3, -1, -2, -3]:
		var v := qpow(s.k, m)
		if not seen.has(Fmt.dec(v)):
			seen[Fmt.dec(v)] = true
			out.append(v)
	return out


# ── Asymptotes ───────────────────────────────────────────────

static func _asymptotes(rng: Seeded, s: Dictionary) -> bool:
	s.ctx = -1
	s.n = rng.pick([-1, -2])
	s.a = Q.new(rng.pick([2, 3, 4, 5, 6, 8, 10, 12, 15, 18, 20, 24]))
	s.x1 = Q.new(rng.pick([1, 2, 3]))
	s.y1 = s.a.mul(qpow(s.x1, s.n))
	return s.rep != "graph" or (tidy(s.y1, 3) and f(s.y1) >= 1.0 and not s.x1.eq(1))


# ── Inputs past a threshold ──────────────────────────────────

static func _threshold(rng: Seeded, s: Dictionary) -> bool:
	var graph: bool = s.rep == "graph"
	if not draw_pair(rng, s, func(c): return not c.whole and (not graph or c.id != "pellet")):
		return false
	if graph and f(s.y1) < 3.0:
		return false
	var r := qd(rng.pick(["0.3", "0.4", "0.5", "0.6", "1.5", "2", "2.5", "3"]))
	s.T = GraphReadingSituation.sf_q(s.y1.mul(r), 2)
	if s.T.eq(s.y1):
		return false
	s.above = rng.chance(0.5)
	s.b = root_of(f(s.T), f(s.a), s.n)
	s.rel = rel_for(s.n, s.above)
	# The boundary needs rounding and is clear of an edge; the power slip is kept only where it
	# reads differently (threshold_slips), and there must be four options.
	return GdcKit.fair(s.b) and threshold_slips(s).size() + threshold_fillers(s).size() >= 4


## The inequality on x for y > T (above) or y < T: y rises with x when n > 0.
static func rel_for(n: int, above: bool) -> String:
	return ">" if above == (n > 0) else "<"


static func flip(rel: String) -> String:
	return "<" if rel == ">" else ">"


## [[b, rel, ""], [b, the other rel, "reversed"], [b from a with the power left out, rel, "power"]].
static func threshold_slips(s: Dictionary) -> Array:
	var out: Array = [[s.b, s.rel, ""], [s.b, flip(s.rel), "reversed"]]
	if s.n != 1:
		var b2 := root_of(f(s.T), f(a_no_power(s)), s.n)
		if clear(b2) and Fmt.sf(b2) != Fmt.sf(s.b):
			out.append([b2, s.rel, "power"])
	return out


## The boundary with the wrong root, either way round: [[b, rel], ...].
static func threshold_fillers(s: Dictionary) -> Array:
	var named: Array = threshold_slips(s).map(func(p): return p[0])
	var vals: Array = []
	for m in POWERS:
		if m != s.n:
			vals.append(root_of(f(s.T), f(s.a), m))
	var out: Array = []
	for b in power_fillers(s.b, vals, named):
		if clear(b) and not named.any(func(x): return Fmt.sf(x) == Fmt.sf(b)):
			out.append([b, s.rel])
			out.append([b, flip(s.rel)])
	return out


# ── The least whole number ───────────────────────────────────

static func _least(rng: Seeded, s: Dictionary) -> bool:
	if not draw_pair(rng, s, func(_c): return true):
		return false
	var r := qd(rng.pick(["0.15", "0.2", "0.3", "0.4", "0.6"]) if s.n < 0 else rng.pick(["1.5", "2", "2.5", "3", "4", "5"]))
	s.L = GraphReadingSituation.sf_q(s.y1.mul(r), 2)
	s.b = root_of(f(s.L), f(s.a), s.n)
	if s.b < 1.5:
		return false
	var frac := s.b - floorf(s.b)
	if frac < 0.08 or frac > 0.42:
		return false
	s.m = ceili(s.b)
	var vals: Array = least_slips(s).map(func(p): return p[0])
	var seen := {}
	for v in vals:
		if v < 1:
			return false
		seen[v] = true
	return seen.size() == vals.size() and least_fillers(s).size() >= 4 - vals.size()


## [[m, ""], [the boundary to the nearest whole number, "nearest"], [m from a with the power left
## out, "power"]].
static func least_slips(s: Dictionary) -> Array:
	var out: Array = [[s.m, ""], [roundi(s.b), "nearest"]]
	if s.n != 1:
		var b2 := root_of(f(s.L), f(a_no_power(s)), s.n)
		var m2 := ceili(b2)
		if m2 >= 1 and m2 != s.m and m2 != roundi(s.b) and absf(b2 - roundf(b2)) > 0.02:
			out.append([m2, "power"])
	return out


## The least whole number with the wrong root, kept at least 2 from the key.
static func least_fillers(s: Dictionary) -> Array:
	var taken: Array = least_slips(s).map(func(p): return p[0])
	var out: Array = []
	for m in POWERS:
		if m == s.n:
			continue
		var b := root_of(f(s.L), f(s.a), m)
		if not is_finite(b) or b > 1e6 or absf(b - roundf(b)) < 0.02:
			continue
		var w := ceili(b)
		if w >= 1 and absi(w - s.m) >= 2 and not w in taken and not w in out:
			out.append(w)
	return out


# ── Pick the graph ───────────────────────────────────────────

## The right card and three wrong ones, each through (x₁, y₁): another power ("power"), a straight
## line through the origin ("line"), a direct law for an inverse one ("direct"), y = c − x for
## y = a/x ("minus") or an inverse law for a direct one ("inverse").
static func _pick(rng: Seeded, s: Dictionary) -> bool:
	if not draw_pair(rng, s, func(c): return c.n != 1 and not c.whole and c.id != "pellet"):
		return false
	if f(s.y1) < 3.0:
		return false
	var x1 := f(s.x1)
	var y1 := f(s.y1)
	var cards: Array = [{"role": "right", "m": s.n}]
	match s.n:
		-2:
			cards.append_array([{"role": "power", "m": -1}, {"role": "direct", "m": 2}, {"role": "line", "m": 1}])
		-1:
			cards.append_array([{"role": "power", "m": -2}, {"role": "direct", "m": 1}, {"role": "minus", "minus": true}])
		2:
			cards.append_array([{"role": "power", "m": 3}, {"role": "line", "m": 1}, {"role": "inverse", "m": -2}])
		3:
			cards.append_array([{"role": "power", "m": 2}, {"role": "line", "m": 1}, {"role": "inverse", "m": -1}])
	for cd in cards:
		cd.c = y1 + x1 if cd.get("minus", false) else y1 / pow(x1, cd.m)
	s.cards = cards
	return true


## A card's y at x.
static func card_y(cd: Dictionary, x: float) -> float:
	if cd.get("minus", false):
		return cd.c - x
	return cd.c * pow(x, cd.m)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
