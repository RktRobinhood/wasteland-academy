class_name NormalProbabilityViews
extends NormalUnknownViews
## The views on the `normal-probability` situation: one builder per unknown of
## t4-normal-probability (FAL-728). They extend NormalUnknownViews for its stories, its numbers
## and its curve. Every question is Paper 2. Answers are to 3 s.f. (show "sf", with the rounding
## trap), except between-from-tails, which is exact.
##
## Representations: "equation" (X ~ N(35, 5²) and an event), "words" (a story) and "diagram"
## (the curve with the region shaded, which the question doesn't state again). The sketch-check
## method reads the drawn curve on a diagram, and asks for a quick sketch everywhere else.

const R_VARIANCE_GDC := "SL4.9.normal-probability#0"
const R_ZERO := "SL4.9.normal-probability#1"
const R_COUNT := "SL4.9.normal-probability#2"
const R_OTHER := "t4-normal-probability#3"
const R_UPPER_ONLY := "t4-normal-probability#4"
const R_ONE_TAIL := "t4-normal-probability#5"
const R_DECIMAL := "t4-normal-probability#6"
const R_WHOLE_UNIT := "t4-normal-probability#7"
const R_HALF_UP := "t4-normal-probability#8"
const R_WHOLE_COUNT := "t4-normal-probability#9"
const R_LEFT_TAIL := "t4-normal-probability#10"
const R_ADD_TAILS := "t4-normal-probability#11"

## One thing from each of NormalUnknownViews.CONTEXTS: what it is, its plural, what is measured,
## and what happens to one that fails a rule.
const ITEMS := [
	{"item": "grain sack", "items": "grain sacks", "attr": "mass", "out": "rejected"},
	{"item": "copper pipe", "items": "copper pipes", "attr": "length", "out": "rejected"},
	{"item": "crossing", "items": "crossings", "attr": "time", "out": "flagged"},
	{"item": "filled can", "items": "filled cans", "attr": "volume of water", "out": "rejected"},
	{"item": "fence post", "items": "fence posts", "attr": "height", "out": "rejected"},
	{"item": "lamp battery", "items": "lamp batteries", "attr": "lifetime", "out": "rejected"},
	{"item": "patrol", "items": "patrols", "attr": "daily distance", "out": "flagged"},
	{"item": "engine part", "items": "engine parts", "attr": "mass", "out": "rejected"},
]

## Stories where X can be negative, so 0 is no lower limit.
const NEGATIVE := [
	{"what": "The night temperatures at the north camp", "unit": " °C", "item": "night", "attr": "temperature", "sym": "X is a temperature in °C."},
	{"what": "The temperatures in the cold store", "unit": " °C", "item": "reading", "attr": "temperature", "sym": "X is a temperature in °C."},
	{"what": "The daily changes in the depot's water level", "unit": " cm", "item": "day", "attr": "change in level", "sym": "X is a change in level in cm."},
]

const ASKS := ["prob-below", "prob-above", "prob-between", "percentage-in-range", "expected-number", "outside-interval",
	"rejected-rule", "expected-rejected", "negative-lower-tail", "variance-given", "recorded-value", "between-from-tails"]


func needs() -> Dictionary:
	var out := {}
	for u in ASKS:
		out[u] = {"ask": u}
	return out


# ── Writing things ───────────────────────────────────────────

static func scene(s: Dictionary) -> Dictionary:
	if s.get("neg", false):
		return NEGATIVE[s.ctx]
	return CONTEXTS[s.ctx].merged(ITEMS[s.ctx])


static func an(word: String) -> String:
	return ("An " if word[0] in "aeiou" else "A ") + word


## σ as it goes into a GDC: exact, or the root to 6 s.f.
static func sg_text(s: Dictionary) -> String:
	return D(s.sg) if s.has("sg") else W(s.sgf)


## The opening line.
static func opening(rep: String, s: Dictionary) -> String:
	var c := scene(s)
	if s.has("variance"):
		var m := "X ~ N(%s, %d)" % [D(s.mu), s.variance]
		return m if rep != "words" else "%s, X%s, follow %s." % [c.what, c.unit, m]
	if rep != "words":
		return "X ~ N(%s, %s²)" % [D(s.mu), D(s.sg)]
	return "%s are normally distributed with mean %s%s and standard deviation %s%s." % [c.what, D(s.mu), c.unit, D(s.sg), c.unit]


## The event for X: "X < 30", "30 < X < 40", "X < 30 or X > 40".
static func event(s: Dictionary) -> String:
	match s.kind:
		"lt":
			return "X < %s" % D(s.hi)
		"gt":
			return "X > %s" % D(s.lo)
		"in":
			return "%s < X < %s" % [D(s.lo), D(s.hi)]
	return "X < %s or X > %s" % [D(s.lo), D(s.hi)]


## The same event in a story: "less than 30 kg", "between 30 kg and 40 kg".
static func in_words(s: Dictionary) -> String:
	var u: String = scene(s).unit
	match s.kind:
		"lt":
			return "less than %s%s" % [D(s.hi), u]
		"gt":
			return "more than %s%s" % [D(s.lo), u]
	return "between %s%s and %s%s" % [D(s.lo), u, D(s.hi), u]


## The region as a sketch shades it.
static func region(s: Dictionary) -> String:
	match s.kind:
		"lt":
			return "the area below %s" % D(s.hi)
		"gt":
			return "the area above %s" % D(s.lo)
		"in":
			return "the area between %s and %s" % [D(s.lo), D(s.hi)]
	return "the two tails, below %s and above %s" % [D(s.lo), D(s.hi)]


## normalcdf's bounds for the region, or for the middle of a two-tail event.
static func _ends(s: Dictionary, low: String, high: String) -> String:
	match s.kind:
		"lt":
			return "−%s, %s" % [INF, high]
		"gt":
			return "%s, %s" % [low, INF]
	return "%s, %s" % [low, high]


## normalcdf on X, its value included: "1 − normalcdf(30, 40, 35, 5) = 1 − 0.6 = 0.4" for two tails.
static func cdf_x(s: Dictionary) -> String:
	var call_text := "normalcdf(%s, %s, %s)" % [_ends(s, _bound(s, "lo"), _bound(s, "hi")), D(s.mu), sg_text(s)]
	return _value_of(s, call_text)


static func cdf_z(s: Dictionary) -> String:
	var call_text := "normalcdf(%s, 0, 1)" % _ends(s, _z(s, "zlo"), _z(s, "zhi"))
	return _value_of(s, call_text)


static func _value_of(s: Dictionary, call_text: String) -> String:
	if s.kind == "out":
		return "1 − %s = 1 − %s = %s" % [call_text, W(s.other), W(s.p)]
	return "%s = %s" % [call_text, W(s.p)]


static func _bound(s: Dictionary, key: String) -> String:
	return D(s[key]) if s.has(key) else ""


static func _z(s: Dictionary, key: String) -> String:
	return W(s[key]) if s.has(key) else ""


## "(4 − 2) ÷ 5", with a negative mean in brackets.
static func _z_line(s: Dictionary, x: Q, z: float) -> String:
	var mu := D(s.mu) if s.mu.sign() >= 0 else "(%s)" % D(s.mu)
	return "z = (%s − %s) ÷ %s = %s" % [D(x), mu, sg_text(s), W(z)]


## The event for Z.
static func z_event(s: Dictionary) -> String:
	match s.kind:
		"lt":
			return "P(Z < %s)" % W(s.zhi)
		"gt":
			return "P(Z > %s)" % W(s.zlo)
		"in":
			return "P(%s < Z < %s)" % [W(s.zlo), W(s.zhi)]
	return "P(Z < %s or Z > %s)" % [W(s.zlo), W(s.zhi)]


## The curve with the region shaded and its bounds marked.
static func figure(s: Dictionary) -> Dictionary:
	var lo: Variant = s.lo.to_float() if s.has("lo") else null
	var hi: Variant = s.hi.to_float() if s.has("hi") else null
	var shade: Array = [[null, lo], [hi, null]] if s.kind == "out" else [[lo, hi]]
	var marks: Array = [{"at": s.muf, "label": D(s.mu)}]
	for k in ["lo", "hi"]:
		if s.has(k):
			marks.append({"at": s[k].to_float(), "label": D(s[k])})
	return curve(s.muf, s.sgf, shade, marks)


## Under or over what a quick look gives, in hundredths, with why: [word, hundredths, reason].
static func _look(s: Dictionary) -> Array:
	if s.kind == "lt":
		return _tail_look(s.zhi, D(s.hi), true)
	if s.kind == "gt":
		return _tail_look(s.zlo, D(s.lo), false)
	var who := "The middle" if s.kind == "out" else "The region"
	var a: float = s.zlo
	var b: float = s.zhi
	var mid: Array
	if b <= 0.0 or a >= 0.0:
		mid = ["under", 50, "%s is all on one side of the mean" % who]
	elif a <= -1.0 and b >= 1.0:
		mid = ["over", 68, "%s holds all of μ ± σ" % who]
	elif a >= -1.0 and b <= 1.0:
		mid = ["under", 70, "%s fits inside μ ± σ" % who]
	elif a >= -2.0 and b <= 2.0:
		mid = ["under", 96, "%s fits inside μ ± 2σ" % who]
	else:
		mid = ["over", 34, "%s reaches from μ to past one σ away" % who]
	if s.kind != "out":
		return mid
	return ["over" if mid[0] == "under" else "under", 100 - mid[1], mid[2]]


## below: the area below x; otherwise the area above it.
static func _tail_look(z: float, x: String, below: bool) -> Array:
	var far := absf(z) >= 1.0
	var why := "%s is %s the mean" % [x, ("at least one standard deviation " if far else "") + ("below" if z < 0.0 else "above")]
	if (z < 0.0) == below:
		return ["under", 16 if far else 50, why]
	return ["over", 84 if far else 50, why]


## The sketch's three lines: shade it, what the area must be, and the GDC agrees.
func _sketch_lines(rep: String, s: Dictionary) -> Array:
	var first := "Read the shaded region on the curve: it is %s." % region(s)
	if rep != "diagram":
		first = "Sketch the curve with the mean %s in the middle, and shade %s." % [D(s.mu), region(s)]
	var look := _look(s)
	return [first, "%s, so the area must be %s %s." % [look[2], look[0], D(Q.new(look[1], 100))], "%s, which fits." % cdf_x(s)]


func _methods(rep: String, s: Dictionary, ans: Dictionary, after: Array = []) -> Dictionary:
	var first: Array = []
	if s.has("variance"):
		first = ["The second number in N(μ, σ²) is the variance, so σ = √%d = %s." % [s.variance, sg_text(s)]]
	var end: Array = after + [final_step(ans)]
	var gdc: Array = ["P(%s) = %s" % [event(s), cdf_x(s)]]
	if s.get("neg", false):
		gdc.push_front("X can be negative, so the lower end is −%s, not 0." % INF)
	var std: Array = []
	if s.has("lo"):
		std.append(_z_line(s, s.lo, s.zlo))
	if s.has("hi"):
		std.append(_z_line(s, s.hi, s.zhi))
	std.append("P(%s) = %s = %s" % [event(s), z_event(s), cdf_z(s)])
	return {"gdc-normalcdf": method(first + gdc + end, ans.values),
		"sketch-check": method(first + _sketch_lines(rep, s) + end, ans.values),
		"standardise-first": method(first + std + end, ans.values)}


func _question(rep: String, s: Dictionary, lines: Array, asked: String, ans: Dictionary) -> Dictionary:
	var out := {"lines": lines, "asked": asked, "answer": ans, "table": null}
	if rep == "diagram":
		out.graph = figure(s)
	return out


## Near values for a number that must stay a probability.
static func near(p: float, scale: float = 1.0) -> Array:
	var out: Array = []
	for f in [0.9, 1.1, 0.8, 1.2]:
		if p * f < 1.0:
			out.append(p * f * scale)
	return vs(out)


static func wrong_x(x: float, ref: String) -> Dictionary:
	return wrong({"v": qf(x)}, ref)


## The shared opening for a question on one chosen value.
func _chosen(rep: String, s: Dictionary) -> Dictionary:
	var c := scene(s)
	var lines: Array = [opening(rep, s)]
	if s.get("neg", false) and rep != "words":
		lines.append(c.sym)
	var asked := "Find P(%s)." % event(s)
	if rep == "words":
		asked = "One %s is chosen at random. Find the probability that its %s is %s." % [c.item, c.attr, in_words(s)]
	elif rep == "diagram":
		asked = "Find the probability shown by the shaded area."
	var ans := sf_ans("probability = ", s.p)
	var out := _question(rep, s, lines, asked, ans)
	out.wrongs = [wrong_x(s.other, R_OTHER)]
	out.generic = near(s.p)
	return out


# ── One value ────────────────────────────────────────────────

func u_prob_below(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := _chosen(rep, s)
	out.methods = _methods(rep, s, out.answer)
	return out


func u_prob_above(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := _chosen(rep, s)
	out.methods = _methods(rep, s, out.answer)
	return out


func u_prob_between(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := _chosen(rep, s)
	out.wrongs.push_front(wrong_x(s.upper, R_UPPER_ONLY))
	out.methods = _methods(rep, s, out.answer)
	return out


func u_outside_interval(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := _chosen(rep, s)
	if rep == "words":
		var c := scene(s)
		out.asked = "One %s is chosen at random. Find the probability that its %s is not between %s%s and %s%s." % [c.item, c.attr, D(s.lo), c.unit, D(s.hi), c.unit]
	out.wrongs.append(wrong_x(s.one, R_ONE_TAIL))
	out.methods = _methods(rep, s, out.answer)
	return out


func u_negative_lower_tail(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := _chosen(rep, s)
	out.wrongs.push_front(wrong_x(s.zero, R_ZERO))
	out.methods = _methods(rep, s, out.answer)
	return out


func u_variance_given(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := _chosen(rep, s)
	out.wrongs.push_front(wrong_x(s.slip, R_VARIANCE_GDC))
	out.methods = _methods(rep, s, out.answer)
	return out


func u_percentage_in_range(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var pc: bool = s.form == "percentage"
	var ans: Dictionary = sf_ans("proportion = ", s.p)
	if pc:
		ans = Answer.make("number", {"v": qf(s.p * 100.0)}, {}, "percentage = ", "%")
		ans.show = "sf"
	var what := "What %s of them are %s?" % [s.form, in_words(s)]
	if rep == "diagram":
		what = "What %s of them lie in the shaded region?" % s.form
	var out := _question(rep, s, [opening("words", s)], what, ans)
	var scale := 100.0 if pc else 1.0
	out.wrongs = [wrong_x(s.other * scale, R_OTHER)]
	if pc:
		out.wrongs.append(wrong_x(s.p, R_DECIMAL))
	out.generic = near(s.p, scale)
	out.methods = _methods(rep, s, ans, ["As a percentage: %s × 100 = %s%%" % [W(s.p), W(s.p * 100.0)]] if pc else [])
	return out


# ── A sample ─────────────────────────────────────────────────

static func count_ans(x: float) -> Dictionary:
	return sf_ans("expected number = ", x)


static func count_step(s: Dictionary, x: float) -> Array:
	return ["Expected number = n × p = %d × %s = %s" % [s.n, W(s.p), W(x)]]


## The options of a count: the probability left as it is, and the region left out.
static func count_options(out: Dictionary, s: Dictionary, x: float) -> void:
	out.wrongs = [wrong_x(s.p, R_COUNT), wrong_x(s.n * s.other, R_OTHER)]
	out.generic = near(s.p, float(s.n))
	# Below 100, the rounding trap is the count rounded to a whole number.
	if x < 99.5:
		out.trap_ref = R_WHOLE_COUNT


func u_expected_number(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var x: float = s.n * s.p
	var ans := count_ans(x)
	var c := scene(s)
	var lines: Array
	var asked: String
	if rep == "words":
		lines = [opening(rep, s), "A random sample of %d %s is taken." % [s.n, c.items]]
		asked = "Find the expected number of %s whose %s is %s." % [c.items, c.attr, in_words(s)]
	else:
		lines = [opening(rep, s), "A random sample of %d values of X is taken." % s.n]
		asked = "Find the expected number of values with %s." % event(s) if rep == "equation" else "Find the expected number of values in the shaded region."
	var out := _question(rep, s, lines, asked, ans)
	count_options(out, s, x)
	out.methods = _methods(rep, s, ans, count_step(s, x))
	return out


## The rule a story gives: "A grain sack is rejected unless its mass is between 30 kg and 40 kg."
static func rule(rep: String, s: Dictionary) -> String:
	var c := scene(s)
	var who := an(c.item)
	if rep == "diagram":
		return "%s is %s if its %s is in the shaded region." % [who, c.out, c.attr]
	if s.kind == "out":
		return "%s is %s unless its %s is %s." % [who, c.out, c.attr, in_words(s)]
	return "%s is %s if its %s is %s." % [who, c.out, c.attr, in_words(s)]


func u_rejected_rule(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := scene(s)
	var asked := "Find the probability that a chosen %s is %s." % [c.item, c.out]
	var ans := sf_ans("probability = ", s.p)
	var out := _question(rep, s, [opening("words", s), rule(rep, s)], asked, ans)
	out.wrongs = [wrong_x(s.other, R_OTHER)]
	if s.kind == "out":
		out.wrongs.append(wrong_x(s.one, R_ONE_TAIL))
	out.generic = near(s.p)
	out.methods = _methods(rep, s, ans)
	return out


func u_expected_rejected(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := scene(s)
	var x: float = s.n * s.p
	var ans := count_ans(x)
	var lines: Array = [opening("words", s), rule(rep, s), "A random sample of %d %s is checked." % [s.n, c.items]]
	var out := _question(rep, s, lines, "Find the expected number of %s %s." % [c.items, c.out], ans)
	count_options(out, s, x)
	out.methods = _methods(rep, s, ans, count_step(s, x))
	return out


# ── A rounded value, and a middle from two tails ─────────────

func u_recorded_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := scene(s)
	var line: String
	var asked: String
	if rep == "words":
		line = "Each %s is measured and recorded to the nearest %s%s." % [c.item, D(s.u), c.unit]
		asked = "Find the probability that a chosen %s has its %s recorded as %s%s." % [c.item, c.attr, D(s.v), c.unit]
	else:
		line = "A value of X is recorded to the nearest %s." % D(s.u)
		asked = "Find the probability that it is recorded as %s." % D(s.v)
	var ans := sf_ans("probability = ", s.p)
	var out := _question(rep, s, [opening(rep, s), line], asked, ans)
	out.wrongs = [wrong_x(s.wide, R_WHOLE_UNIT), wrong_x(s.half_up, R_HALF_UP)]
	out.generic = near(s.p)
	var width := "A value recorded as %s is one from %s up to %s, half a unit either side." % [D(s.v), D(s.lo), D(s.hi)]
	var m := _methods(rep, s, ans)
	m["gdc-normalcdf"].steps.push_front(width)
	m["standardise-first"].steps.push_front(width)
	var top := 0.4 / s.sgf
	m["sketch-check"].steps = [width, "Sketch the curve and shade the thin strip from %s to %s." % [D(s.lo), D(s.hi)],
		"The curve is at most about 0.4 ÷ %s = %s high and the strip is %s wide, so the area must be under %s." % [sg_text(s), W(top), D(s.u), W(top * s.u.to_float())],
		"%s, which fits." % cdf_x(s), final_step(ans)]
	out.methods = m
	return out


func u_between_from_tails(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var lines: Array = [model("words", s, null, null) if rep == "words" else "X ~ N(μ, σ²)",
		tail_line(rep, s, s.x1, "lt", s.p1), tail_line(rep, s, s.x2, "gt", s.p2)]
	var c := scene(s)
	var asked := "Find P(%d < X < %d)." % [s.x1, s.x2]
	if rep == "words":
		asked = "One %s is chosen at random. Find the probability that its %s is %s." % [c.item, c.attr, in_words(s)]
	elif rep == "diagram":
		asked = "Find the probability shown by the shaded area."
	var ans := exact_ans("probability = ", s.mid)
	var out := {"lines": lines, "asked": asked, "answer": ans, "table": null}
	if rep == "diagram":
		out.graph = curve(s.muf, s.sgf, [[float(s.x1), float(s.x2)]], [{"at": float(s.x1), "label": str(s.x1)}, {"at": float(s.x2), "label": str(s.x2)}])
	out.wrongs = [wrong({"v": s.left}, R_LEFT_TAIL), wrong({"v": s.sum}, R_ADD_TAILS)]
	out.generic = [{"v": Q.new(1).sub(s.p2)}, {"v": s.mid.add(Q.new(1, 10))}, {"v": s.mid.mul(Q.new(1, 2))}]
	var first := "Sketch the curve and shade the tails below %d and above %d: the middle is what they leave." % [s.x1, s.x2]
	if rep == "diagram":
		first = "On the curve, the shaded middle is what the two tails leave."
	out.methods = {"sketch-check": method([first, "The whole area is 1, so the middle is 1 − %s − %s = %s." % [D(s.p1), D(s.p2), D(s.mid)], final_step(ans)], ans.values)}
	return out
