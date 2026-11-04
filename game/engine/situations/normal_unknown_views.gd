class_name NormalUnknownViews
extends ExtensionViews
## The views on the `normal-unknown` situation: one builder per unknown of
## t4-normal-unknown-parameter (FAL-725). Every question is Paper 2. Answers are to 3 s.f.
## (show "sf", with the rounding trap), except a bound for Z, a mean from equal tails and a mean
## from two z-values, which are exact.
##
## Representations: "equation" (X ~ N(35, σ²) and P(X < 30) = 0.2), "words" (a story with
## percentages) and "diagram" (the equation's lines, and the curve with the given area shaded).

const SKILL := "SL4.12."
const R_UPPER := SKILL + "unknown-mean-or-sd#1"
const R_NEG_SD := SKILL + "unknown-mean-or-sd#2"
const R_REVERSED := SKILL + "standardise#0"
const R_VARIANCE := SKILL + "standardise#1"
const R_BOTH_POS := SKILL + "unknown-mean-and-sd#0"
const R_PROB_Z := SKILL + "unknown-mean-and-sd#1"
const R_ROUND_Z := SKILL + "unknown-mean-and-sd#2"
const INF := "10^99"

## The stories: what is normally distributed, and its unit.
const CONTEXTS := [
	{"what": "The masses of the grain sacks at a depot", "unit": " kg"},
	{"what": "The lengths of the copper pipes in a yard", "unit": " cm"},
	{"what": "The times couriers take to cross the flats", "unit": " minutes"},
	{"what": "The volumes of water in the filled cans", "unit": " ml"},
	{"what": "The heights of the fence posts at a camp", "unit": " cm"},
	{"what": "The lifetimes of the lamp batteries", "unit": " hours"},
	{"what": "The distances the patrols cover in a day", "unit": " km"},
	{"what": "The masses of the salvaged engine parts", "unit": " kg"},
]

const UNKNOWNS := ["z-from-area", "standardise-event", "within-k-sd", "unknown-sd", "unknown-mean", "sd-from-iqr",
	"sd-from-central-area", "mean-and-sd", "mean-from-equal-tails", "sd-from-equal-tails", "mean-from-two-z"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = NormalUnknownSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


static func W(x: Variant) -> String:
	return BinomialViews.W(x.to_float() if x is Q else x)


static func qf(x: float) -> Q:
	return GdcKit.qf(x)


static func sf_ans(label: String, x: float) -> Dictionary:
	var ans := Answer.make("number", {"v": qf(x)}, {}, label)
	ans.show = "sf"
	return ans


static func exact_ans(label: String, v: Q) -> Dictionary:
	var ans := Answer.make("number", {"v": v}, {}, label)
	ans.show = "dec"
	ans.exact = true
	return ans


static func vs(xs: Array) -> Array:
	return xs.map(func(x): return {"v": qf(x)})


static func final_step(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func ctx(s: Dictionary) -> Dictionary:
	return CONTEXTS[s.ctx]


static func rel(side: String) -> String:
	return "<" if side == "lt" else ">"


## A probability as a percentage: 20, 7.5.
static func pct(p: Q) -> String:
	return D(p.mul(Q.new(100)))


## "P(X < 30) = 0.2" or "20% of them are below 30 kg."
static func tail_line(rep: String, s: Dictionary, x: Variant, side: String, p: Q) -> String:
	if rep == "words":
		return "%s%% of them are %s %s%s." % [pct(p), "below" if side == "lt" else "above", D(x), ctx(s).unit]
	return "P(X %s %s) = %s" % [rel(side), D(x), D(p)]


## The left-tail area a GDC needs: "P(X < x) = 0.8".
static func left_step(s: Dictionary, x: Variant) -> String:
	if s.side == "lt":
		return "The area to the left of %s is %s." % [D(x), D(s.p)]
	return "invNorm uses the area to the left: 1 − %s = %s." % [D(s.p), D(Q.new(1).sub(s.p))]


static func left_q(s: Dictionary) -> Q:
	return s.p if s.side == "lt" else Q.new(1).sub(s.p)


## The curve with the areas shaded. mu and sg are what the facts force.
static func curve(mu: float, sg: float, shade: Array, marks: Array) -> Dictionary:
	return {"kind": "normal", "mu": mu, "sigma": sg, "x0": mu - 3.6 * sg, "x1": mu + 3.6 * sg, "shade": shade, "marks": marks}


static func side_shade(x: float, side: String) -> Array:
	return [[null, x]] if side == "lt" else [[x, null]]


## The opening line: X ~ N(35, σ²), or the story with what is known.
static func model(rep: String, s: Dictionary, mu: Variant, sg: Variant) -> String:
	if rep != "words":
		return "X ~ N(%s, %s²)" % ["μ" if mu == null else D(mu), "σ" if sg == null else D(sg)]
	var c := ctx(s)
	if mu == null and sg == null:
		return "%s are normally distributed." % c.what
	if sg == null:
		return "%s are normally distributed with mean %s%s." % [c.what, D(mu), c.unit]
	if mu == null:
		return "%s are normally distributed with standard deviation %s%s." % [c.what, D(sg), c.unit]
	return "%s are normally distributed with mean %s%s and standard deviation %s%s." % [c.what, D(mu), c.unit, D(sg), c.unit]


static func find(rep: String, sym: String, name: String) -> String:
	return "Find %s." % (sym if rep != "words" else "the " + name)


# ── z and the event for Z ────────────────────────────────────

func u_z_from_area(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var z: float = s.z
	var ans := sf_ans("k = ", z)
	var out := {"lines": ["Z ~ N(0, 1)", "P(Z %s k) = %s" % [rel(s.side), D(s.p)]], "asked": "Find k.", "answer": ans, "table": null}
	if rep == "diagram":
		out.graph = curve(0.0, 1.0, side_shade(z, s.side), [{"at": z, "label": "k"}, {"at": 0.0, "label": "0"}])
	out.wrongs = [wrong({"v": qf(-z)}, R_UPPER)] if s.side == "gt" else []
	out.generic = vs([-z, s.pz, z * 1.1, z + 0.5, z * 0.9])
	var left := left_q(s)
	out.methods = {"invnorm-z-then-solve": method([_left_text(s), "k = invNorm(%s, 0, 1) = %s" % [D(left), W(z)], final_step(ans)], ans.values),
		"gdc-solver": method(["Solve normalcdf(−%s, k, 0, 1) = %s for k: graph the left side and y = %s, or use the solver." % [INF, D(left), D(left)], "The graphs meet at k = %s." % W(z), final_step(ans)], ans.values)}
	return out


static func _left_text(s: Dictionary) -> String:
	if s.side == "lt":
		return "P(Z < k) = %s is already the area to the left of k." % D(s.p)
	return "invNorm uses the area to the left of k: P(Z < k) = 1 − %s = %s." % [D(s.p), D(left_q(s))]


func u_standardise_event(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var r := rel(s.side)
	var word := DifferentiationViews.form("P(Z %s %s)" % [r, D(s.zq)], ["P(Z ", {"pick": "rel", "options": ["<", ">"]}, " ", {"slot": "v"}, ")"], {"rel": r, "v": s.zq})
	word.exact = true
	var ev := "P(X %s %d)" % [r, s.x]
	var lines: Array = [model(rep, s, s.mu, s.sg)]
	var asked := "Write %s as a probability for Z ~ N(0, 1)." % ev
	if rep == "words":
		asked = "X is a value chosen at random. Write %s as a probability for Z ~ N(0, 1)." % ev
	var out := {"lines": lines, "asked": asked, "answer": word, "table": null}
	if rep == "diagram":
		var mu := float(s.mu)
		out.graph = curve(mu, float(s.sg), side_shade(float(s.x), s.side), [{"at": float(s.x), "label": str(s.x)}, {"at": mu, "label": str(s.mu)}])
	var flip := "<" if s.side == "gt" else ">"
	var other := func(rr: String, v: Q) -> Dictionary: return {"rel": rr, "v": v, "text": "P(Z %s %s)" % [rr, D(v)]}
	out.wrongs = [wrong(other.call(flip, s.zq), R_REVERSED), wrong(other.call(r, s.zv), R_VARIANCE)]
	out.generic = [other.call(r, s.zq.neg()), other.call(flip, s.zq.neg()), other.call(r, s.zq.add(Q.new(1)))]
	var a: float = s.area
	var line := "z = (x − μ) ÷ σ = (%d − %d) ÷ %d = %s" % [s.x, s.mu, s.sg, D(s.zq)]
	var gdc_x := "normalcdf(%s) = %s" % [_bounds(s, str(s.x), "%d, %d" % [s.mu, s.sg]), W(a)]
	var gdc_z := "normalcdf(%s) = %s" % [_bounds(s, D(s.zq), "0, 1"), W(a)]
	out.methods = {"standardise-bounds": method([line, "σ is positive, so the inequality keeps its direction.", "So %s = P(Z %s %s)." % [ev, r, D(s.zq)]], word.values),
		"gdc-both": method([line, "%s for X, and %s for Z: the same area." % [gdc_x, gdc_z], "So %s = P(Z %s %s)." % [ev, r, D(s.zq)]], word.values)}
	return out


## normalcdf's bounds and parameters for the event's tail.
static func _bounds(s: Dictionary, x: String, params: String) -> String:
	return "−%s, %s, %s" % [INF, x, params] if s.side == "lt" else "%s, %s, %s" % [x, INF, params]


func u_within_k_sd(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: float = s.k.to_float()
	var x: float = s.prob
	var ans := sf_ans("probability = ", x)
	var lines: Array = [model(rep, s, null, null) if rep == "words" else "X ~ N(μ, σ²)"]
	var asked := "Find P(μ − %sσ < X < μ + %sσ)." % [D(s.k), D(s.k)]
	if rep == "words":
		asked = "Find the probability that a value is within %s standard deviations of the mean." % D(s.k)
	var out := {"lines": lines, "asked": asked, "answer": ans, "table": null}
	var pos: float = NormalUnknownSituation.phi(k)
	out.generic = vs([pos, x / 2.0, 1.0 - x, x * 0.9])
	out.methods = {"standardise-bounds": method(["μ − %sσ gives z = −%s and μ + %sσ gives z = %s, whatever μ and σ are." % [D(s.k), D(s.k), D(s.k), D(s.k)],
			"P(−%s < Z < %s) = normalcdf(−%s, %s, 0, 1) = %s" % [D(s.k), D(s.k), D(s.k), D(s.k), W(x)], final_step(ans)], ans.values),
		"gdc-both": method(["Try any values: μ = 0 and σ = 1, or μ = 50 and σ = 10.", "normalcdf(−%s, %s, 0, 1) = %s, and the other pair gives the same area." % [D(s.k), D(s.k), W(x)], final_step(ans)], ans.values)}
	return out


# ── One parameter ────────────────────────────────────────────

func u_unknown_sd(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var sg: float = s.sg
	var ans := sf_ans("σ = ", sg)
	var out := {"lines": [model(rep, s, s.mu, null), tail_line(rep, s, s.x, s.side, s.p)], "asked": find(rep, "σ", "standard deviation"), "answer": ans, "table": null}
	if rep == "diagram":
		out.graph = curve(float(s.mu), sg, side_shade(float(s.x), s.side), [{"at": float(s.x), "label": str(s.x)}, {"at": float(s.mu), "label": str(s.mu)}])
	var gap := absi(s.x - s.mu)
	out.wrongs = [wrong({"v": qf(-sg)}, R_NEG_SD)]
	out.generic = vs([gap * absf(s.z), gap / s.p.to_float(), sg * 1.1, sg * 0.9])
	var left := left_q(s)
	out.methods = {"invnorm-z-then-solve": method([left_step(s, s.x), "z = invNorm(%s, 0, 1) = %s" % [D(left), W(s.z)],
			"z = (x − μ) ÷ σ, so σ = (%d − %d) ÷ %s" % [s.x, s.mu, _paren(s.z)], final_step(ans)], ans.values),
		"gdc-solver": method(["Graph y = normalcdf(−%s, %d, %d, x) and y = %s, with σ as x." % [INF, s.x, s.mu, D(left)], "The graphs meet at x = %s." % W(sg), final_step(ans)], ans.values)}
	return out


func u_unknown_mean(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var mu: float = s.mu
	var ans := sf_ans("μ = ", mu)
	var out := {"lines": [model(rep, s, null, s.sg), tail_line(rep, s, s.x, s.side, s.p)], "asked": find(rep, "μ", "mean"), "answer": ans, "table": null}
	if rep == "diagram":
		out.graph = curve(mu, float(s.sg), side_shade(float(s.x), s.side), [{"at": float(s.x), "label": str(s.x)}, {"at": mu, "label": "μ"}])
	out.wrongs = [wrong({"v": qf(s.mw)}, R_UPPER)]
	out.generic = vs([s.x - s.p.to_float() * s.sg, s.x + s.p.to_float() * s.sg, mu * 1.1, mu * 0.9])
	var left := left_q(s)
	out.methods = {"invnorm-z-then-solve": method([left_step(s, s.x), "z = invNorm(%s, 0, 1) = %s" % [D(left), W(s.z)],
			"z = (x − μ) ÷ σ, so μ = %d − %s × %d" % [s.x, _paren(s.z), s.sg], final_step(ans)], ans.values),
		"gdc-solver": method(["Graph y = normalcdf(−%s, %d, x, %d) and y = %s, with μ as x." % [INF, s.x, s.sg, D(left)], "The graphs meet at x = %s." % W(mu), final_step(ans)], ans.values)}
	return out


static func _paren(x: float) -> String:
	return W(x) if x >= 0.0 else "(%s)" % W(x)


func u_sd_from_iqr(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var sg: float = s.sg
	var ans := sf_ans("σ = ", sg)
	var half: Q = s.iqr.div(Q.new(2))
	var line: String = "The interquartile range of X is %s." % D(s.iqr) if rep != "words" else "The interquartile range is %s%s." % [D(s.iqr), ctx(s).unit]
	var out := {"lines": [model(rep, s, s.mu, null), line], "asked": find(rep, "σ", "standard deviation"), "answer": ans, "table": null}
	out.generic = vs([sg * 2.0, s.iqr.to_float() / 4.0 / s.z, s.iqr.to_float() / 2.0, s.iqr.to_float(), sg * 1.1])
	var q3: Q = Q.new(s.mu).add(half)
	out.methods = {"invnorm-z-then-solve": method(["The quartiles sit equally either side of the mean, so Q₃ = %d + %s = %s, and 75%% of values are below it." % [s.mu, D(half), D(q3)],
			"z = invNorm(0.75, 0, 1) = %s" % W(s.z), "z = (x − μ) ÷ σ, so σ = %s ÷ %s" % [D(half), W(s.z)], final_step(ans)], ans.values),
		"gdc-solver": method(["Q₃ = %d + %s = %s, and P(X < Q₃) = 0.75." % [s.mu, D(half), D(q3)],
			"Graph y = normalcdf(−%s, %s, %d, x) and y = 0.75: they meet at x = %s." % [INF, D(q3), s.mu, W(sg)], final_step(ans)], ans.values)}
	return out


func u_sd_from_central_area(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var sg: float = s.sg
	var ans := sf_ans("σ = ", sg)
	var lo: int = s.mu - s.a
	var hi: int = s.mu + s.a
	var line: String = "P(%d < X < %d) = %s" % [lo, hi, D(s.c)] if rep != "words" else "%s%% of them are between %d%s and %d%s." % [pct(s.c), lo, ctx(s).unit, hi, ctx(s).unit]
	var out := {"lines": [model(rep, s, s.mu, null), line], "asked": find(rep, "σ", "standard deviation"), "answer": ans, "table": null}
	if rep == "diagram":
		out.graph = curve(float(s.mu), sg, [[float(lo), float(hi)]], [{"at": float(lo), "label": str(lo)}, {"at": float(s.mu), "label": str(s.mu)}, {"at": float(hi), "label": str(hi)}])
	out.generic = vs([s.sw, sg * 2.0, s.a * s.z, sg * 1.1, sg * 0.9])
	var tails: Q = Q.new(1).sub(s.c).div(Q.new(2))
	var left: Q = Q.new(1).sub(tails)
	out.methods = {"invnorm-z-then-solve": method(["The two tails share 1 − %s, so each is %s, and the area to the left of %d is %s." % [D(s.c), D(tails), hi, D(left)],
			"z = invNorm(%s, 0, 1) = %s" % [D(left), W(s.z)], "%d = %d + zσ, so σ = %d ÷ %s" % [hi, s.mu, s.a, W(s.z)], final_step(ans)], ans.values),
		"gdc-solver": method(["Graph y = normalcdf(%d, %d, %d, x) and y = %s, with σ as x." % [lo, hi, s.mu, D(s.c)], "The graphs meet at x = %s." % W(sg), final_step(ans)], ans.values)}
	return out


# ── Both parameters ──────────────────────────────────────────

func u_mean_and_sd(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := Answer.make("named", {"v0": qf(s.mu), "v1": qf(s.sg)}, {"names": ["μ", "σ"]})
	ans.show = "sf"
	var side2: String = "gt" if s.form == "tails" else "lt"
	var lines: Array = [model(rep, s, null, null) if rep == "words" else "X ~ N(μ, σ²)",
		tail_line(rep, s, s.x1, "lt", s.p1), tail_line(rep, s, s.x2, side2, s.p2)]
	var asked := "Find μ and σ." if rep != "words" else "Find the mean μ and the standard deviation σ."
	var out := {"lines": lines, "asked": asked, "answer": ans, "table": null}
	if rep == "diagram":
		var shade: Array = [[null, float(s.x1)], [float(s.x2), null]] if s.form == "tails" else [[null, float(s.x2)]]
		out.graph = curve(s.mu, s.sg, shade, [{"at": float(s.x1), "label": str(s.x1)}, {"at": float(s.x2), "label": str(s.x2)}])
	var two := func(w: Dictionary) -> Dictionary: return {"v0": qf(w.mu), "v1": qf(w.sg)}
	out.wrongs = [wrong(two.call(s.prb), R_PROB_Z), wrong(two.call(s.dp1), R_ROUND_Z)]
	if not s.pos.is_empty():
		out.wrongs.insert(0, wrong(two.call(s.pos), R_BOTH_POS))
	out.generic = [{"v0": qf(s.sg), "v1": qf(s.mu)}, {"v0": qf(s.mu * 1.1), "v1": qf(s.sg)}, {"v0": qf(s.mu), "v1": qf(s.sg * 1.1)}]
	var a1 := D(s.p1)
	var a2 := D(Q.new(1).sub(s.p2)) if s.form == "tails" else D(s.p2)
	var eq1 := "μ %s σ = %d" % [_z_term(s.z1), s.x1]
	var eq2 := "μ %s σ = %d" % [_z_term(s.z2), s.x2]
	var zs := "z₁ = invNorm(%s, 0, 1) = %s and z₂ = invNorm(%s, 0, 1) = %s" % [a1, W(s.z1), a2, W(s.z2)]
	var gap: int = s.x2 - s.x1
	out.methods = {"simultaneous": method([zs, "x = μ + zσ gives %s and %s." % [eq1, eq2],
			"Subtract: %d = %s σ, so σ = %s" % [gap, W(s.z2 - s.z1), W(s.sg)], "μ = %d − %s × %s = %s" % [s.x1, _paren(s.z1), W(s.sg), W(s.mu)], final_step(ans)], ans.values),
		"gdc-solver": method([zs, "Enter %s and %s in the simultaneous equation solver." % [eq1, eq2], "It gives μ = %s and σ = %s." % [W(s.mu), W(s.sg)], final_step(ans)], ans.values)}
	return out


## "+ 0.8416" or "− 1.282", the z-term of x = mu + z sg.
static func _z_term(z: float) -> String:
	return ("+ " if z >= 0.0 else "− ") + W(absf(z))


func u_mean_from_equal_tails(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := exact_ans("μ = ", Q.new(s.mu))
	var line: String = "P(X < %d) = P(X > %d)" % [s.a1, s.b1]
	if rep == "words":
		line = "The percentage below %d%s equals the percentage above %d%s." % [s.a1, ctx(s).unit, s.b1, ctx(s).unit]
	var out := {"lines": [model(rep, s, null, null) if rep == "words" else "X ~ N(μ, σ²)", line], "asked": "Write down μ." if rep != "words" else "Write down the mean.", "answer": ans, "table": null}
	if rep == "diagram":
		var sg: float = s.half / 1.2
		out.graph = curve(float(s.mu), sg, [[null, float(s.a1)], [float(s.b1), null]], [{"at": float(s.a1), "label": str(s.a1)}, {"at": float(s.b1), "label": str(s.b1)}])
	out.generic = [{"v": Q.new(s.b1 - s.a1)}, {"v": Q.new(s.half)}, {"v": Q.new(s.a1 + s.b1)}, {"v": Q.new(s.mu + 1)}]
	out.methods = {"symmetric-tails": method(["Equal tails sit equally far either side of the mean.", "μ = (%d + %d) ÷ 2 = %d" % [s.a1, s.b1, s.mu], final_step(ans)], ans.values)}
	return out


func u_sd_from_equal_tails(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var sg: float = s.sg
	var ans := sf_ans("σ = ", sg)
	var line: String = "P(X < %d) = P(X > %d) = %s" % [s.a1, s.b1, D(s.p)]
	if rep == "words":
		line = "%s%% of them are below %d%s, and %s%% are above %d%s." % [pct(s.p), s.a1, ctx(s).unit, pct(s.p), s.b1, ctx(s).unit]
	var out := {"lines": [model(rep, s, null, null) if rep == "words" else "X ~ N(μ, σ²)", line], "asked": find(rep, "σ", "standard deviation"), "answer": ans, "table": null}
	out.generic = vs([s.half * 2.0 / s.z, s.half * s.z, sg * 1.1, sg * 0.9])
	var left: Q = Q.new(1).sub(s.p)
	out.methods = {"symmetric-tails": method(["Equal tails put μ in the middle: μ = (%d + %d) ÷ 2 = %d." % [s.a1, s.b1, s.mu], "z = invNorm(%s, 0, 1) = %s" % [D(left), W(s.z)],
			"%d = %d + zσ, so σ = %d ÷ %s" % [s.b1, s.mu, s.half, W(s.z)], final_step(ans)], ans.values),
		"simultaneous": method(["z = invNorm(%s, 0, 1) = %s, and the lower value has −z." % [D(left), W(s.z)], "μ − %s σ = %d and μ + %s σ = %d" % [W(s.z), s.a1, W(s.z), s.b1],
			"Subtract: %d = %s σ" % [s.b1 - s.a1, W(2.0 * s.z)], final_step(ans)], ans.values)}
	return out


func u_mean_from_two_z(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := exact_ans("μ = ", Q.new(s.mu))
	var lines: Array
	var c := ctx(s)
	if rep == "words":
		lines = [model(rep, s, null, null), "A value of %s%s has z-value %s." % [D(s.x1), c.unit, D(s.z1)], "A value of %s%s has z-value %s." % [D(s.x2), c.unit, D(s.z2)]]
	else:
		lines = ["X ~ N(μ, σ²)", "x = %s has z = %s" % [D(s.x1), D(s.z1)], "x = %s has z = %s" % [D(s.x2), D(s.z2)]]
	var out := {"lines": lines, "asked": find(rep, "μ", "mean"), "answer": ans, "table": null}
	var mid: Q = s.x1.add(s.x2).div(Q.new(2))
	out.generic = [{"v": mid}, {"v": Q.new(s.sg)}, {"v": s.x1.sub(s.z1)}, {"v": Q.new(s.mu + s.sg)}]
	var dz: Q = s.z2.sub(s.z1)
	var dx: Q = s.x2.sub(s.x1)
	var eq1 := "μ %s %sσ = %s" % ["−" if s.z1.sign() < 0 else "+", D(s.z1.abs_q()), D(s.x1)]
	var eq2 := "μ %s %sσ = %s" % ["−" if s.z2.sign() < 0 else "+", D(s.z2.abs_q()), D(s.x2)]
	out.methods = {"simultaneous": method(["x = μ + zσ gives %s and %s." % [eq1, eq2], "Subtract: %s = %sσ, so σ = %d" % [D(dx), D(dz), s.sg],
			"μ = %s − (%s) × %d = %d" % [D(s.x1), D(s.z1), s.sg, s.mu], final_step(ans)], ans.values),
		"gdc-solver": method(["Enter %s and %s in the simultaneous equation solver." % [eq1, eq2], "It gives μ = %d and σ = %d." % [s.mu, s.sg], final_step(ans)], ans.values)}
	return out
