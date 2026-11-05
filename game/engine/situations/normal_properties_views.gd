class_name NormalPropertiesViews
extends NormalProbabilityViews
## The views on the `normal-properties` situation: one builder per unknown of
## t4-normal-properties (FAL-740). They extend NormalProbabilityViews for its stories, its numbers
## and its curve. Answers are exact, except beyond-sd, tail-from-band and the three central
## intervals, which are GDC values to 3 s.f. and Paper 2 only. The rest make both papers, so the
## type can land on the exam's split. No Paper 1 step uses a calculator.
##
## Representations: "equation", "words" and "diagram" (the curve, or several curves, with PlotView's
## `normal`). pick-two-curves and pick-shaded are pick-the-graph questions: four GraphView cards.

const SK_P := "SL4.9.properties#"
const SK_S := "SL4.9.symmetry-probability#"
const SK_C := "SL4.9.central-interval#"
const OWN := "t4-normal-properties#"
const M_RULE := SK_P + "0"
const M_TALLER := SK_P + "1"
const M_POINT := SK_P + "2"
const M_ADD_TAILS := SK_S + "0"
const M_HALF := SK_S + "1"
const M_ABOUT_ZERO := SK_S + "2"
const M_LEFT_TAIL := SK_C + "0"
const M_ENDPOINT := SK_C + "1"
const M_OTHER_SIDE := OWN + "8"
const M_WHOLE_BAND := OWN + "9"
const M_HALF_BAND := OWN + "10"
const M_BOTH_TAILS := OWN + "11"
const M_ONE_TAIL_LEFT := OWN + "12"
const M_NOT_COUNTED := OWN + "13"
const M_WIDTH := OWN + "14"
const M_TO_MEAN := OWN + "15"
const M_ONE_SD := OWN + "16"
const M_MU_SHAPE := OWN + "17"
const M_SD_MOVES := OWN + "18"
const M_SD_BACKWARDS := OWN + "19"
const M_WRONG_WAY := OWN + "20"
const M_WRONG_MEAN := OWN + "21"
const M_FROM_MEAN := OWN + "22"
const M_CENTRED := OWN + "23"
const M_NO_SD := OWN + "24"
const M_COMPLEMENT := OWN + "25"
const M_NO_COMPLEMENT := OWN + "26"
const M_MEASURED_FROM_MEAN := OWN + "27"
const M_EQUAL_TAILS := OWN + "28"
const M_NO_SHIFT := OWN + "29"
const M_SHIFT_BACK := OWN + "30"
const M_SAME_SIDE := OWN + "31"
const M_ADD_MEAN := OWN + "32"
const M_NO_SIGMA := OWN + "33"
const M_SCALED_K := OWN + "34"

const RULE_NAME := "68-95-99.7 rule"
const RULE_LINE := "The rule: about 68% lie within 1 standard deviation of the mean, 95% within 2 and 99.7% within 3."
const LIST := ["empirical-share", "empirical-count", "empirical-tail", "empirical-band", "sd-from-rule", "other-sd-end",
	"point-probability", "effect-of-change", "match-curve", "pick-two-curves", "pick-shaded", "same-sd-shift", "shifted-mirror",
	"beyond-sd", "half-below-mean", "mirror-tail", "mirror-complement", "middle-from-tail", "tail-from-middle", "half-of-middle",
	"mean-to-point", "between-from-two-tails", "tail-from-band", "mirror-value", "central-k", "central-endpoints", "central-k-sd"]
const P2_ONLY := ["beyond-sd", "tail-from-band", "central-k", "central-endpoints", "central-k-sd"]
const WIDE_LOW := "It is wider and lower, with the same centre."
const NARROW_TALL := "It is narrower and taller, with the same centre."
const WIDE_TALL := "It is wider and taller, with the same centre."
const NARROW_LOW := "It is narrower and lower, with the same centre."


func needs() -> Dictionary:
	var out := {}
	for u in LIST:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	if not has(unknown):
		return []
	return [2] if unknown in P2_ONLY else [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = NormalPropertiesSituation.export(s)
	# The engine's last-resort nudges add 1, which is no probability.
	if out.has("near_p"):
		var v: Q = out.near_p
		var scale := Q.new(100) if s.get("form", "") == "pct" else Q.new(1)
		for k in [1, -1, 2, -2, 3, -3, 5, -5]:
			var x := v.add(Q.new(k, 100))
			if x.sign() > 0 and x.lt(Q.new(1)):
				out.generic.append({"v": x.mul(scale)})
	return out


# ── Writing things ───────────────────────────────────────────

static func share(k: int) -> Q:
	return NormalPropertiesSituation.share(k)


static func one_minus(v: Q) -> Q:
	return Q.new(1).sub(v)


static func half(v: Q) -> Q:
	return v.div(Q.new(2))


## "1 standard deviation", "1.5 standard deviations".
static func sds(k: Variant) -> String:
	var q := Q.of(k)
	return "%s standard deviation%s" % [D(q), "" if q.eq(1) else "s"]


## The number the rule gives, as the question asks it: 0.68 or 68%.
static func rule_ans(s: Dictionary, v: Q) -> Dictionary:
	if s.get("form", "pr") == "pct":
		var ans := Answer.make("number", {"v": v.mul(Q.new(100))}, {}, "percentage ≈ ", "%")
		ans.show = "dec"
		ans.exact = true
		return ans
	return exact_ans("probability ≈ ", v)


## A wrong option, only if it is a share of the whole.
static func pw(s: Dictionary, v: Q, ref: String) -> Array:
	if v.sign() <= 0 or not v.lt(Q.new(1)):
		return []
	return [wrong({"v": v.mul(Q.new(100)) if s.get("form", "pr") == "pct" else v}, ref)]


static func final_text(ans: Dictionary) -> String:
	return Answer.text(ans) + "."


static func mk(v: Q) -> Dictionary:
	return {"at": v.to_float(), "label": D(v)}


static func mk_as(v: Variant, label: String) -> Dictionary:
	return {"at": v.to_float() if v is Q else v, "label": label}


## The curve with its mean marked, and the given shading and other marks.
static func pic(s: Dictionary, shade: Array, marks: Array) -> Dictionary:
	return curve(s.muf, s.sgf, shade, [mk_as(s.muf, D(s.mu))] + marks)


## The first line of a sketch: what to draw, or what to read off the figure.
static func sketch_line(rep: String, s: Dictionary, marked: String, shaded: String) -> String:
	if rep == "diagram":
		return "Read the curve: the mean %s is in the middle, %s are marked, and the region is %s." % [D(s.mu), marked, shaded]
	return "Sketch the curve with the mean %s in the middle, mark %s, and shade %s." % [D(s.mu), marked, shaded]


static func bound_words(s: Dictionary, q: Q) -> String:
	return D(q) + scene(s).unit


static func both_ends(s: Dictionary) -> String:
	return "%s and %s" % [D(s.lo), D(s.hi)]


## The tail on the side `up`: "P(X > 13)" and its numbers.
static func tail_event(s: Dictionary, up: bool) -> String:
	return "X > %s" % D(s.hi) if up else "X < %s" % D(s.lo)


static func tail_x(s: Dictionary, up: bool) -> Q:
	return s.hi if up else s.lo


static func tail_side(up: bool) -> String:
	return "gt" if up else "lt"


static func tail_shade(s: Dictionary, up: bool) -> Array:
	return side_shade(tail_x(s, up).to_float(), tail_side(up))


## "the area above 13".
static func tail_words(s: Dictionary, up: bool) -> String:
	return "the area %s %s" % ["above" if up else "below", D(tail_x(s, up))]


## One chosen item is asked about: "Find the probability that its mass is below 7 kg."
static func ask_tail(rep: String, s: Dictionary, up: bool) -> String:
	if rep == "words":
		var c := scene(s)
		return "One %s is chosen at random. Find the probability that its %s is %s %s." % [c.item, c.attr, "above" if up else "below", bound_words(s, tail_x(s, up))]
	return "Find P(%s)." % tail_event(s, up)


static func ask_range(rep: String, s: Dictionary, lo: Q, hi: Q) -> String:
	if rep == "words":
		var c := scene(s)
		return "One %s is chosen at random. Find the probability that its %s is between %s and %s." % [c.item, c.attr, bound_words(s, lo), bound_words(s, hi)]
	return "Find P(%s < X < %s)." % [D(lo), D(hi)]


static func band_fact(rep: String, s: Dictionary, c: Q) -> String:
	if rep == "words":
		var u: String = scene(s).unit
		return "%s%% of them are between %s%s and %s%s." % [pct(c), D(s.lo), u, D(s.hi), u]
	return "P(%s < X < %s) = %s" % [D(s.lo), D(s.hi), D(c)]


static func curve_of(s: Dictionary) -> String:
	return "X ~ N(%s, σ²)" % D(s.mu)


# ── The 68-95-99.7 rule ──────────────────────────────────────

## How far the ends of the band are from the mean, in standard deviations.
static func reach_line(s: Dictionary) -> String:
	if s.get("sym", false):
		return "The ends are %s ± %s, and a is the standard deviation, so they are %s either side of the mean." % [D(s.mu), "a" if s.k == 1 else "%da" % s.k, sds(s.k)]
	if s.get("said", "") == "sds":
		return "The band is μ ± %s." % ("σ" if s.k == 1 else "%dσ" % s.k)
	var d: Q = s.hi.sub(s.mu)
	return "%s − %s = %s, and %s ÷ %s = %d, so the ends are %s either side of the mean." % [D(s.hi), D(s.mu), D(d), D(d), D(s.sg), s.k, sds(s.k)]


func u_empirical_share(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := share(s.k)
	var ans := rule_ans(s, c)
	var other := 2 if s.k != 2 else 1
	var lines: Array = [opening(rep, s)]
	var what := "P(%s)" % ("%s − %s < X < %s + %s" % [D(s.mu), "a" if s.k == 1 else "%da" % s.k, D(s.mu), "a" if s.k == 1 else "%da" % s.k] if s.get("sym", false) else "%s < X < %s" % [D(s.lo), D(s.hi)])
	var asked := "Use the %s to write down the approximate value of %s." % [RULE_NAME, what]
	if s.get("sym", false):
		lines = ["X ~ N(%s, a²), where a > 0" % D(s.mu)]
	var band := "%s and %s" % [D(s.lo), D(s.hi)]
	if rep == "words":
		var e: Dictionary = scene(s)
		var where: String = "within %s of the mean" % sds(s.k) if s.said == "sds" else "between %s and %s" % [bound_words(s, s.lo), bound_words(s, s.hi)]
		asked = "Use the %s to write down the approximate percentage of the %s with a %s %s." % [RULE_NAME, e.items, e.attr, where]
		if s.form != "pct":
			asked = "One %s is chosen at random. Use the %s to write down the approximate probability that its %s is %s." % [e.item, RULE_NAME, e.attr, where]
	elif rep == "diagram":
		asked = "Use the %s to write down the approximate area of the shaded region." % RULE_NAME
	var out := {"lines": lines, "asked": asked, "answer": ans, "table": null, "near_p": c}
	if rep == "diagram":
		out.graph = pic(s, [[s.lo.to_float(), s.hi.to_float()]], [mk(s.lo), mk(s.hi)])
	out.wrongs = pw(s, share(other), M_RULE) + pw(s, one_minus(c), M_OTHER_SIDE) + pw(s, half(c), M_HALF_BAND)
	out.generic = []
	var ending := "So %s" % final_text(ans)
	out.methods = {"empirical-rule": method([reach_line(s), RULE_LINE, ending], ans.values),
		"sketch-and-shade": method([sketch_line(rep, s, band, "the band between them") if not s.get("sym", false) else "Sketch the curve with the mean %s in the middle, and shade the band out to %s each side." % [D(s.mu), sds(s.k)],
			reach_line(s), "The shaded band reaches %s each side, so it holds about %s%% of the area." % [sds(s.k), pct(c)], ending], ans.values)}
	return out


func u_empirical_count(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := share(s.k)
	var e: Dictionary = scene(s)
	var n := Q.new(s.n)
	var out_side: Q = one_minus(c)
	var keep: Q = c if s.mode == "in" else out_side
	var v: Q = n.mul(keep)
	var ans := exact_ans("number ≈ ", v)
	var lines: Array = [opening("words", s), "There are %d %s in all." % [s.n, e.items]]
	var asked := "Use the %s to estimate how many have a %s %s." % [RULE_NAME, e.attr,
		("between %s and %s" if s.mode == "in" else "outside the range %s to %s") % [bound_words(s, s.lo), bound_words(s, s.hi)]]
	if rep == "diagram":
		asked = "Use the %s to estimate how many lie in the shaded %s." % [RULE_NAME, "band" if s.mode == "in" else "tails"]
	var out := {"lines": lines, "asked": asked, "answer": ans, "table": null}
	if rep == "diagram":
		var a := s.lo.to_float() as float
		var b := s.hi.to_float() as float
		out.graph = pic(s, [[a, b]] if s.mode == "in" else [[null, a], [b, null]], [mk(s.lo), mk(s.hi)])
	var other := 2 if s.k != 2 else 1
	var wrongs: Array = [wrong({"v": n.mul(share(other) if s.mode == "in" else one_minus(share(other)))}, M_RULE),
		wrong({"v": n.mul(out_side if s.mode == "in" else c)}, M_OTHER_SIDE)]
	if s.mode == "out" and half(v).is_int():
		wrongs.append(wrong({"v": half(v)}, M_ONE_TAIL_LEFT))
	wrongs.append(wrong({"v": keep}, M_NOT_COUNTED))
	out.wrongs = wrongs
	out.generic = [{"v": n.mul(Q.new(1, 2))}, {"v": n.mul(Q.new(34, 100))}, {"v": n.mul(Q.new(16, 100))}, {"v": v.mul(2)}]
	var steps: Array = ["%s − %s = %s, and %s ÷ %s = %d, so the ends are %s either side of the mean." % [D(s.hi), D(s.mu), D(s.hi.sub(s.mu)), D(s.hi.sub(s.mu)), D(s.sg), s.k, sds(s.k)]]
	if s.mode == "in":
		steps.append("By the rule, a share of about %s lies inside that band." % D(c))
	else:
		steps.append("By the rule, a share of about %s lies inside that band, so 1 − %s = %s lies outside it." % [D(c), D(c), D(keep)])
	steps.append("Multiply by the total: %d × %s = %s" % [s.n, D(keep), D(v)])
	steps.append("So %s." % Answer.text(ans))
	out.methods = {"empirical-rule": method(steps, ans.values)}
	return out


func u_empirical_tail(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := share(s.k)
	var inner: bool = (s.kind == "lt") == s.up
	var tail: Q = half(one_minus(c))
	var big: Q = half(c).add(Q.new(1, 2))
	var v: Q = big if inner else tail
	var ans := rule_ans(s, v)
	var e: Dictionary = scene(s)
	var other := 2 if s.k != 2 else 1
	var word: String = "below" if s.kind == "lt" else "above"
	var sign_text := rel(s.kind)
	var asked := "Use the %s to write down the approximate value of P(X %s %s)." % [RULE_NAME, sign_text, D(s.x)]
	if rep == "words":
		asked = "Use the %s to write down the approximate percentage of the %s with a %s %s %s." % [RULE_NAME, e.items, e.attr, word, bound_words(s, s.x)]
		if s.form != "pct":
			asked = "One %s is chosen at random. Use the %s to write down the approximate probability that its %s is %s %s." % [e.item, RULE_NAME, e.attr, word, bound_words(s, s.x)]
	elif rep == "diagram":
		asked = "Use the %s to write down the approximate area of the shaded region." % RULE_NAME
	var out := {"lines": [opening(rep, s)], "asked": asked, "answer": ans, "table": null, "near_p": v}
	if rep == "diagram":
		out.graph = pic(s, side_shade(s.x.to_float(), s.kind), [mk(s.x)])
	var wrongs: Array = []
	if inner:
		wrongs += pw(s, c, M_WHOLE_BAND) + pw(s, half(c), M_HALF) + pw(s, tail, M_OTHER_SIDE)
	else:
		wrongs += pw(s, one_minus(c), M_BOTH_TAILS) + pw(s, big, M_OTHER_SIDE) + pw(s, half(c), M_HALF_BAND)
	wrongs += pw(s, half(one_minus(share(other))) if not inner else half(share(other)).add(Q.new(1, 2)), M_RULE)
	out.wrongs = wrongs
	out.generic = []
	var d: Q = s.x.sub(s.mu).abs_q()
	var where := "%s is %s %s the mean" % [D(s.x), sds(s.k), "above" if s.up else "below"]
	var rule_steps: Array = [("%s: |%s − %s| = %s, and %s ÷ %s = %d." % [where, D(s.x), D(s.mu), D(d), D(d), D(s.sg), s.k])]
	var area := "the area %s %s" % [word, D(s.x)]
	var ending := "So %s" % final_text(ans)
	if inner:
		rule_steps.append("About %s lies inside the band, so half of it, %s ÷ 2 = %s, lies between the mean and %s." % [D(c), D(c), D(half(c)), D(s.x)])
		rule_steps.append("Add the half of the curve on the other side of the mean: 0.5 + %s = %s" % [D(half(c)), D(v)])
		out.methods = {"empirical-rule": method(rule_steps + [ending], ans.values),
			"sketch-and-shade": method([sketch_line(rep, s, D(s.x), area), "The shaded area is half of the curve, plus half of the band μ ± %s." % ("σ" if s.k == 1 else "%dσ" % s.k),
				"So it is 0.5 + %s ÷ 2 = %s, which is more than 0.5 as the sketch shows." % [D(c), D(v)], ending], ans.values)}
	else:
		rule_steps.append("About %s lies inside the band, so 1 − %s = %s lies outside it." % [D(c), D(c), D(one_minus(c))])
		rule_steps.append("That splits into two equal tails: %s ÷ 2 = %s" % [D(one_minus(c)), D(v)])
		out.methods = {"empirical-rule": method(rule_steps + [ending], ans.values),
			"sketch-and-shade": method([sketch_line(rep, s, D(s.x), area), "The shaded area is one of the two equal tails outside the band μ ± %s, whose area is 1 − %s = %s." % ["σ" if s.k == 1 else "%dσ" % s.k, D(c), D(one_minus(c))],
				"So it is %s ÷ 2 = %s, which is less than 0.5 as the sketch shows." % [D(one_minus(c)), D(v)], ending], ans.values)}
	return out


## "2 below the mean", in standard deviations.
static func z_words(z: int) -> String:
	return "%s %s the mean" % [sds(absi(z)), "above" if z > 0 else "below"]


func u_empirical_band(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.z1
	var b: int = s.z2
	var ha := NormalPropertiesSituation.half_share(a)
	var hb := NormalPropertiesSituation.half_share(b)
	var v: Q = hb.sub(ha)
	var ans := rule_ans(s, v)
	var e: Dictionary = scene(s)
	var asked := "Use the %s to write down the approximate value of P(%s < X < %s)." % [RULE_NAME, D(s.lo), D(s.hi)]
	if rep == "words":
		var where := "between %s and %s" % [bound_words(s, s.lo), bound_words(s, s.hi)]
		asked = "Use the %s to write down the approximate percentage of the %s with a %s %s." % [RULE_NAME, e.items, e.attr, where]
		if s.form != "pct":
			asked = "One %s is chosen at random. Use the %s to write down the approximate probability that its %s is %s." % [e.item, RULE_NAME, e.attr, where]
	elif rep == "diagram":
		asked = "Use the %s to write down the approximate area of the shaded region." % RULE_NAME
	var out := {"lines": [opening(rep, s)], "asked": asked, "answer": ans, "table": null, "near_p": v}
	if rep == "diagram":
		out.graph = pic(s, [[s.lo.to_float(), s.hi.to_float()]], [mk(s.lo), mk(s.hi)])
	var unhalved: Q = hb.sub(ha).mul(2)
	var swap := func(z: int) -> Q:
		if absi(z) == 3 or z == 0:
			return NormalPropertiesSituation.half_share(z)
		var t := NormalPropertiesSituation.half_share(3 - absi(z))
		return t.neg() if z < 0 else t
	var wrongs: Array = pw(s, unhalved, M_WHOLE_BAND)
	wrongs += pw(s, one_minus(v), M_OTHER_SIDE)
	if a != 0 and b != 0 and (a < 0) != (b < 0):
		wrongs += pw(s, hb.abs_q() if hb.abs_q().sub(ha.abs_q()).sign() > 0 else ha.abs_q(), M_HALF_BAND)
	wrongs += pw(s, swap.call(b).sub(swap.call(a)), M_RULE)
	out.wrongs = wrongs
	out.generic = []
	var parts: Array = []
	for z in [a, b]:
		if z != 0:
			parts.append("%s ÷ 2 = %s" % [D(share(absi(z))), D(NormalPropertiesSituation.half_share(absi(z)))])
	var first := "%s is the mean" % D(s.lo) if a == 0 else ("%s is the mean" % D(s.hi) if b == 0 else "%s is %s, and %s is %s" % [D(s.lo), z_words(a), D(s.hi), z_words(b)])
	var halves: String = "The area from the mean out to each end is half of its band: %s." % ", ".join(parts)
	if parts.size() == 1:
		halves = "The area from the mean out to the other end is half of its band: %s." % parts[0]
	var sum_line: String
	if a == 0 or b == 0:
		sum_line = "That is all of the region."
	elif (a < 0) != (b < 0):
		sum_line = "The ends are on opposite sides of the mean, so add: %s + %s = %s" % [D(ha.abs_q()), D(hb.abs_q()), D(v)]
	else:
		var big: Q = ha.abs_q() if ha.abs_q().sub(hb.abs_q()).sign() > 0 else hb.abs_q()
		var small: Q = ha.abs_q() if big == hb.abs_q() else hb.abs_q()
		sum_line = "The ends are on the same side of the mean, so subtract: %s − %s = %s" % [D(big), D(small), D(v)]
	var ending := "So %s" % final_text(ans)
	out.methods = {"empirical-rule": method(["%s." % first, halves, sum_line, ending], ans.values),
		"sketch-and-shade": method([sketch_line(rep, s, both_ends(s), "the region between them"), "%s." % first, halves + " " + sum_line, ending], ans.values)}
	return out


func u_sd_from_rule(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := share(s.k)
	var width: Q = s.hi.sub(s.lo)
	var ans := exact_ans("σ = " if rep != "words" else "standard deviation = ", s.sg)
	var e: Dictionary = scene(s)
	var other := 2 if s.k != 2 else 1
	var lines: Array = []
	var asked := "Use the %s to find σ." % RULE_NAME
	match rep:
		"words":
			lines = ["%s are normally distributed." % e.what, "About %s%% of them are between %s%s and %s%s, in a band centred on the mean." % [pct(c), D(s.lo), e.unit, D(s.hi), e.unit]]
			asked = "Use the %s to find the standard deviation." % RULE_NAME
		"diagram":
			lines = ["X ~ N(%s, σ²)" % D(s.mu), "The shaded band is centred on the mean and holds about %s%% of the area." % pct(c)]
		_:
			lines = ["X ~ N(%s, σ²)" % D(s.mu), "P(%s < X < %s) ≈ %s" % [D(s.lo), D(s.hi), D(c)]]
	var out := {"lines": lines, "asked": asked, "answer": ans, "table": null}
	if rep == "diagram":
		out.graph = curve(s.muf, s.sgf, [[s.lo.to_float(), s.hi.to_float()]], [mk(s.lo), mk(s.mu), mk(s.hi)])
	out.wrongs = [wrong({"v": width.div(Q.new(s.k))}, M_WIDTH), wrong({"v": width.div(Q.new(2 * other))}, M_RULE)]
	out.generic = [{"v": width}, {"v": s.sg.add(1)}, {"v": s.sg.mul(2)}, {"v": s.sg.add(2)}]
	if s.k == 1:
		out.wrongs.push_front(wrong({"v": width}, M_WIDTH))
	out.methods = {"empirical-rule": method(["The band is %s − %s = %s wide." % [D(s.hi), D(s.lo), D(width)],
		"By the rule, %s%% is the band μ ± %s, which is 2 × %d = %d standard deviations wide." % [pct(c), "σ" if s.k == 1 else "%dσ" % s.k, s.k, 2 * s.k],
		"σ = %s ÷ %d = %s" % [D(width), 2 * s.k, D(s.sg)], "So %s" % final_text(ans)], ans.values)}
	return out


func u_other_sd_end(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var u: String = scene(s).unit
	var given: Q = s.lo if s.given_low else s.hi
	var v: Q = s.hi if s.given_low else s.lo
	var ans := exact_ans("k = ", v)
	var a: String = D(s.lo) + u if s.given_low else "k" + u
	var b: String = "k" + u if s.given_low else D(s.hi) + u
	var lines: Array = [opening(rep, s)]
	if rep == "words":
		lines.append("Those between %s and %s lie within %s of the mean." % [a, b, sds(s.k)])
	else:
		lines.append("The values between %s and %s lie within %s of the mean." % [D(s.lo) if s.given_low else "k", "k" if s.given_low else D(s.hi), sds(s.k)])
	var out := {"lines": lines, "asked": "Write down the value of k.", "answer": ans, "table": null}
	var spread: Q = s.sg.mul(Q.new(s.k))
	if rep == "diagram":
		var ends := [mk(given), mk_as(v, "k")]
		out.graph = pic(s, [[s.lo.to_float(), s.hi.to_float()]], ends)
	var sign_v := 1 if s.given_low else -1
	var wrongs: Array = [wrong({"v": s.mu}, M_TO_MEAN)]
	if s.k > 1:
		wrongs.append(wrong({"v": s.mu.add(s.sg.mul(sign_v))}, M_ONE_SD))
	out.wrongs = wrongs
	out.generic = [{"v": s.mu.add(s.sg.mul(Q.new(sign_v * (s.k + 1))))}, {"v": v.add(s.sg.mul(sign_v))}, {"v": given.sub(s.sg.mul(sign_v))}, {"v": v.add(sign_v)}, {"v": v.sub(sign_v)}]
	var op := "+" if s.given_low else "−"
	var calc: String = "%s %s %s" % [D(s.mu), op, D(s.sg)] if s.k == 1 else "%s %s %d × %s" % [D(s.mu), op, s.k, D(s.sg)]
	var ending := "So %s" % final_text(ans)
	var check_line := "Within %s of the mean runs from μ − %s to μ + %s, and %s fits as the %s end." % [sds(s.k), _sig(s.k), _sig(s.k), D(given), "lower" if s.given_low else "upper"]
	out.methods = {"empirical-rule": method([check_line, "So k is the %s end: %s = %s" % ["upper" if s.given_low else "lower", calc, D(v)], ending], ans.values),
		"sketch-and-shade": method([sketch_line(rep, s, "%s and k" % D(given), "the band between them"), "%s is %s from the mean %s, so k is the same distance on the other side." % [D(given), D(spread), D(s.mu)],
			"k = %s %s %s = %s" % [D(s.mu), op, D(spread), D(v)], ending], ans.values)}
	return out


static func _sig(k: int) -> String:
	return "σ" if k == 1 else "%dσ" % k


func u_point_probability(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var e: Dictionary = scene(s)
	var ans := exact_ans("probability = " if rep == "words" else "P(X = %s) = " % D(s.x), Q.new(0))
	var asked := "Write down P(X = %s)." % D(s.x)
	if rep == "words":
		asked = "One %s is chosen at random. Write down the probability that its %s is exactly %s." % [e.item, e.attr, bound_words(s, s.x)]
	var below: Q = Q.new(1, 2).add(NormalPropertiesSituation.half_share(s.j))
	var out := {"lines": [opening(rep, s)], "asked": asked, "answer": ans, "table": null}
	var wrongs: Array = pw(s, below, M_POINT) + pw(s, one_minus(below), M_POINT)
	if s.j == 0:
		wrongs += pw(s, Q.new(34, 100), M_POINT)
	out.wrongs = wrongs
	out.generic = [{"v": Q.new(1)}, {"v": Q.new(68, 100)}, {"v": Q.new(95, 100)}]
	var first := "Sketch the curve and mark %s." % D(s.x)
	out.methods = {"sketch-and-shade": method([first, "X is continuous, so a probability is an area under the curve, and a single value is a line with no width.", "The area of a line is 0.", "So %s" % final_text(ans)], ans.values)}
	return out


func u_effect_of_change(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := scene(s)
	var slide := func(right: bool, d: Q) -> String: return "It slides %s to the %s, with the same shape." % [D(d), "right" if right else "left"]
	var moved: bool = s.change.begins_with("mu")
	var up: bool = s.change.ends_with("up")
	var right: String
	var opts: Array
	var d: Q
	if moved:
		d = s.d
		right = slide.call(up, d)
		opts = [[slide.call(not up, d), M_WRONG_WAY], [WIDE_LOW, M_MU_SHAPE], [NARROW_TALL, M_MU_SHAPE]]
	elif up:
		d = s.sg2.sub(s.sg)
		right = WIDE_LOW
		opts = [[WIDE_TALL, M_TALLER], [NARROW_TALL, M_SD_BACKWARDS], [slide.call(true, d), M_SD_MOVES]]
	else:
		d = s.sg.sub(s.sg2)
		right = NARROW_TALL
		opts = [[NARROW_LOW, M_TALLER], [WIDE_LOW, M_SD_BACKWARDS], [slide.call(false, d), M_SD_MOVES]]
	var all: Array = [right]
	for o in opts:
		all.append(o[0])
	var ans := Answer.make("choice", {"v": right}, {"options": all})
	var lines: Array
	var asked := "How does the curve of Y compare with the curve of X?"
	if rep == "words":
		var change: String
		if moved:
			change = "Later, the mean %s by %s%s and the standard deviation stays the same." % ["rises" if up else "falls", D(s.d), c.unit]
		else:
			change = "Later, the standard deviation changes to %s%s and the mean stays the same." % [D(s.sg2), c.unit]
		lines = [opening("words", s), change]
		asked = "How does the new normal curve compare with the old one?"
	else:
		lines = ["X ~ N(%s, %s²)" % [D(s.mu), D(s.sg)], "Y ~ N(%s, %s²)" % [D(s.mu2), D(s.sg2)]]
	var wrongs: Array = []
	for o in opts:
		wrongs.append(wrong({"v": o[0]}, o[1]))
	var steps: Array
	if moved:
		steps = ["μ is the centre of the curve: it goes from %s to %s, which is %s to the %s." % [D(s.mu), D(s.mu2), D(s.d), "right" if up else "left"],
			"σ stays %s, so the width and the height don't change." % D(s.sg), Answer.text(ans)]
	else:
		steps = ["μ stays %s, so the centre doesn't move." % D(s.mu),
			"σ goes from %s to %s, so the curve gets %s, and the total area stays 1, so it gets %s." % [D(s.sg), D(s.sg2), "wider" if up else "narrower", "lower" if up else "taller"], Answer.text(ans)]
	return {"lines": lines, "asked": asked, "answer": ans, "table": null, "wrongs": wrongs, "generic": [],
		"methods": {"parameter-effect": method(steps, ans.values)}}


## The second parameter as a question writes it: σ² as a square, or as the variance it is.
static func spread_text(sg: int, as_variance: bool) -> String:
	return str(sg * sg) if as_variance else "%d²" % sg


func u_match_curve(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var want: Dictionary = s.curves[s.want]
	var name := func(c: Dictionary) -> String: return "Curve " + str(c.label)
	var opts: Array = s.curves.map(func(c): return name.call(c))
	opts.sort()
	var ans := Answer.make("choice", {"v": name.call(want)}, {"options": opts})
	var wrongs: Array = []
	var both: Dictionary = {}
	var pair: Dictionary = {}
	for c in s.curves:
		if c.mu == want.mu and c.sg != want.sg:
			pair = c
			wrongs.push_front(wrong({"v": name.call(c)}, M_TALLER))
		elif c.mu != want.mu and c.sg == want.sg:
			wrongs.append(wrong({"v": name.call(c)}, M_WRONG_MEAN))
		elif c.mu != want.mu:
			both = c
	var sgs: Array = [s.curves[0].sg, s.curves[1].sg]
	var narrow: bool = want.sg == mini(sgs[0], sgs[1])
	var line: String = "μ = %d, so the curve is centred on %d. That leaves %s and %s." % [want.mu, want.mu, name.call(want), name.call(pair)]
	var sigma_line: String = "σ = %d is the %s of the two spreads, so it is the %s curve of those two." % [want.sg, "smaller" if narrow else "larger", "narrower, taller" if narrow else "wider, lower"]
	if s.as_variance:
		sigma_line = "The variance is %d, so σ = %d. That is the %s of the two spreads, so it is the %s curve of those two." % [want.sg * want.sg, want.sg, "smaller" if narrow else "larger", "narrower, taller" if narrow else "wider, lower"]
	var means: Array = [s.curves[0].mu, s.curves[3].mu]
	var graph := {"kind": "normal", "mu": float(means[0]), "sigma": float(sgs[0]), "x0": float(means[0]) - 3.4 * maxi(sgs[0], sgs[1]), "x1": float(means[1]) + 3.4 * maxi(sgs[0], sgs[1]),
		"curves": s.curves.map(func(c): return {"mu": float(c.mu), "sigma": float(c.sg), "label": c.label}), "shade": [],
		"marks": means.map(func(m): return {"at": float(m), "label": str(m)})}
	return {"lines": ["The diagram shows four normal curves, A, B, C and D, on the same axes."], "graph": graph, "table": null,
		"asked": "Which curve is the graph of X ~ N(%d, %s)?" % [want.mu, spread_text(want.sg, s.as_variance)], "answer": ans,
		"wrongs": wrongs + [wrong({"v": name.call(both)})], "generic": [],
		"methods": {"parameter-effect": method([line, sigma_line, Answer.text(ans) + "."], ans.values)}}


## A card: one or two curves, lettered at their peaks, in one window. y is scaled so the tallest
## curve in the question has height SCALE_HEIGHT, and the up axis has no numbers.
static func card_of(curves: Array, win: Array, tallest: float, ticks: Array, shade_on: Array = []) -> Dictionary:
	var drawn: Array = []
	var points: Array = []
	for c in curves:
		var f: Callable = func(x: float) -> float: return NormalPropertiesSituation.SCALE_HEIGHT * tallest / c.sg * exp(-0.5 * pow((x - c.mu) / c.sg, 2.0))
		drawn.append(GdcKit.curve(f, win[0], win[1]))
		if c.get("label", "") != "":
			points.append([c.mu, f.call(c.mu), c.label])
	var g := GdcKit.card(drawn, points, [floori(win[0]), ceili(win[1]), -1, 8])
	g.x_ticks = ticks
	g.y_bare = true
	g.x_name = ""
	g.y_name = ""
	if not shade_on.is_empty():
		var c: Dictionary = curves[0]
		var regions: Array = []
		for r in shade_on:
			var a: float = win[0] if r[0] == null else r[0]
			var b: float = win[1] if r[1] == null else r[1]
			var strips: Array = []
			for i in 61:
				var x: float = a + (b - a) * i / 60.0
				strips.append([x, 0.0, NormalPropertiesSituation.SCALE_HEIGHT * tallest / c.sg * exp(-0.5 * pow((x - c.mu) / c.sg, 2.0))])
			regions.append(strips)
		g.shade = regions
	return g


func u_pick_two_curves(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var mx := float(s.mx)
	var my := float(s.my)
	var sx := float(s.sx)
	var sy := float(s.sy)
	var big := maxf(sx, sy)
	var small := minf(sx, sy)
	var d := 2.0 * big
	var win: Array = [minf(mx, my) - d * 1.8, maxf(mx, my) + d * 1.8]
	if s.same:
		win[1] += d
	var ticks: Array = [[mx, str(s.mx)]] if s.same else [[mx, str(s.mx)], [my, str(s.my)]]
	if s.same:
		ticks.append([mx + d, str(int(mx + d))])
	var pair := func(a: float, b: float, c: float, e: float) -> Dictionary:
		return card_of([{"mu": a, "sg": b, "label": "X"}, {"mu": c, "sg": e, "label": "Y"}], win, small, ticks)
	var wrongs: Array
	if s.same:
		wrongs = [{"graph": pair.call(mx, sy, my, sx), "mistake": "taller", "ref": M_TALLER, "why": "the larger σ is drawn as the taller curve"},
			{"graph": pair.call(mx, sx, mx + d, sy), "mistake": "moved", "ref": M_WRONG_MEAN, "why": "the two curves have the same mean, so they share a centre"},
			{"graph": pair.call(mx, sx, my, sx), "mistake": "same-spread", "ref": "", "why": "the two curves are drawn with the same σ"}]
	else:
		wrongs = [{"graph": pair.call(mx, sy, my, sx), "mistake": "taller", "ref": M_TALLER, "why": "the larger σ is drawn as the taller curve"},
			{"graph": pair.call(my, sx, mx, sy), "mistake": "moved", "ref": M_WRONG_MEAN, "why": "the two means are the wrong way round"},
			{"graph": pair.call(my, sy, mx, sx), "mistake": "both", "ref": "", "why": "the means and the spreads are both the wrong way round"}]
	var pk := GdcKit.pick(pair.call(mx, sx, my, sy), wrongs, rng)
	var ans: Dictionary = pk.answer
	var first: String
	if s.same:
		first = "The means are the same, so both curves have their peak at %d." % s.mx
	else:
		first = "The means are %d for X and %d for Y, so the peak of %s is further right." % [s.mx, s.my, "X" if s.mx > s.my else "Y"]
	var wide := "Y" if s.sy > s.sx else "X"
	var slim := "X" if wide == "Y" else "Y"
	var sigma_line := "σ is %d for X and %d for Y, so %s is wider and lower, and %s is narrower and taller." % [s.sx, s.sy, wide, slim]
	if s.as_variance:
		sigma_line = "Y's variance is %d, so σ is %d for X and %d for Y. So %s is wider and lower, and %s is narrower and taller." % [s.sy * s.sy, s.sx, s.sy, wide, slim]
	return {"lines": ["X ~ N(%d, %d²)" % [s.mx, s.sx], "Y ~ N(%d, %s)" % [s.my, spread_text(s.sy, s.as_variance)]], "table": null,
		"asked": "Which graph shows the curves of X and Y on the same axes?", "answer": ans, "graphs": pk.graphs,
		"methods": {"parameter-effect": method([first, sigma_line, Answer.text(ans) + "."], ans.values)}}


func u_pick_shaded(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var mu: float = s.muf
	var sg: float = s.sgf
	var ticks: Array
	var event_text: String
	var win: Array = [mu - 5.6 * sg, mu + 5.6 * sg]
	var plain := {"mu": mu, "sg": sg}
	var one := func(c: Dictionary, shade: Array) -> Dictionary: return card_of([c], win, sg, ticks, shade)
	var wrongs: Array
	var right: Array
	var words: String
	if s.kind == "in":
		var a: float = s.lo.to_float()
		var b: float = s.hi.to_float()
		ticks = [[a, D(s.lo)], [mu, D(s.mu)], [b, D(s.hi)]] if a < mu and mu < b else ([[mu, D(s.mu)], [a, D(s.lo)], [b, D(s.hi)]] if a > mu else [[a, D(s.lo)], [b, D(s.hi)], [mu, D(s.mu)]])
		event_text = "%s < X < %s" % [D(s.lo), D(s.hi)]
		right = [[a, b]]
		var mid := (a + b) / 2.0
		var far: float = b if absf(b - mu) >= absf(a - mu) else a
		wrongs = [{"graph": one.call(plain, [[null, a], [b, null]]), "mistake": "outside", "ref": M_OTHER_SIDE, "why": "it shades outside the two values, not between them"},
			{"graph": one.call(plain, [[minf(mu, far), maxf(mu, far)]]), "mistake": "from-mean", "ref": M_FROM_MEAN, "why": "it shades from the mean, not from the two values"},
			{"graph": one.call({"mu": mid, "sg": sg}, [[a, b]]), "mistake": "centred", "ref": M_CENTRED, "why": "its peak is not at the mean"}]
		words = "the region between %s and %s" % [D(s.lo), D(s.hi)]
	else:
		var a: float = s.x.to_float()
		ticks = [[minf(a, mu), D(s.x if a < mu else s.mu)], [maxf(a, mu), D(s.mu if a < mu else s.x)]]
		event_text = "X %s %s" % [rel(s.kind), D(s.x)]
		right = side_shade(a, s.kind)
		var opposite: Array = side_shade(a, "lt" if s.kind == "gt" else "gt")
		wrongs = [{"graph": one.call(plain, opposite), "mistake": "other-side", "ref": M_OTHER_SIDE, "why": "it shades the wrong side of %s" % D(s.x)},
			{"graph": one.call(plain, [[minf(mu, a), maxf(mu, a)]]), "mistake": "from-mean", "ref": M_FROM_MEAN, "why": "it shades only from the mean to %s" % D(s.x)},
			{"graph": one.call({"mu": a, "sg": sg}, right), "mistake": "centred", "ref": M_CENTRED, "why": "its peak is at %s, not at the mean" % D(s.x)}]
		words = "the region %s %s, all the way to the end of the curve" % ["above" if s.kind == "gt" else "below", D(s.x)]
	var pk := GdcKit.pick(one.call(plain, right), wrongs, rng)
	var ans: Dictionary = pk.answer
	return {"lines": ["X ~ N(%s, %s²)" % [D(s.mu), D(s.sg)]], "table": null, "asked": "Which graph shows the region for P(%s) shaded?" % event_text,
		"answer": ans, "graphs": pk.graphs,
		"methods": {"sketch-and-shade": method(["Sketch the curve with its peak at the mean %s, then mark the values in the event." % D(s.mu), "P(%s) is %s." % [event_text, words], Answer.text(ans) + "."], ans.values)}}


func _shift_lines(s: Dictionary, sign_text: String) -> Array:
	return ["X ~ N(%s, a²) and Y ~ N(%s, a²), where a > 0" % [D(s.mu), D(s.mu2)], "P(X %s b) = P(Y > %s)" % [sign_text, D(s.x)]]


func u_same_sd_shift(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var d: Q = s.mu.sub(s.mu2)
	var v: Q = s.x.add(d)
	var ans := exact_ans("b = ", v)
	var move := "right" if d.sign() > 0 else "left"
	return {"lines": _shift_lines(s, ">"), "asked": "Find b.", "answer": ans, "table": null, "generic": [{"v": s.mu}, {"v": s.mu2}, {"v": v.add(1)}, {"v": v.sub(1)}],
		"wrongs": [wrong({"v": s.x}, M_NO_SHIFT), wrong({"v": s.x.sub(d)}, M_SHIFT_BACK)],
		"methods": {"parameter-effect": method(["X and Y have the same σ, so they are the same curve, and the curve of Y slides onto the curve of X.", "The slide is %s − %s = %s, which is %s to the %s." % [D(s.mu), D(s.mu2), D(d), D(d.abs_q()), move],
			"The point %s slides with the curve, so b = %s + (%s) = %s" % [D(s.x), D(s.x), D(d), D(v)], "So %s" % final_text(ans)], ans.values)}}


func u_shifted_mirror(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var off: Q = s.x.sub(s.mu2)
	var v: Q = s.mu.sub(off)
	var ans := exact_ans("b = ", v)
	ans.signed = true
	var d: Q = s.mu.sub(s.mu2)
	var same_side := "X and Y have the same σ, and %s is %s above Y's mean." % [D(s.x), D(off)]
	var ending := "So %s" % final_text(ans)
	return {"lines": _shift_lines(s, "<"), "asked": "Find b.", "answer": ans, "table": null, "generic": [{"v": s.mu}, {"v": v.add(1)}, {"v": v.sub(1)}, {"v": v.add(2)}],
		"wrongs": [wrong({"v": s.mu.add(off)}, M_SAME_SIDE), wrong({"v": s.x}, M_NO_SHIFT), wrong({"v": s.x.sub(d)}, M_SHIFT_BACK)],
		"methods": {"parameter-effect": method([same_side, "Slide the curve of Y onto the curve of X: %s goes to %s + %s = %s, with the same tail above it." % [D(s.x), D(s.mu), D(off), D(s.mu.add(off))],
			"P(X < b) is the mirror of that tail, so b is %s below X's mean: %s − %s = %s" % [D(off), D(s.mu), D(off), D(v)], ending], ans.values),
		"mirror-tails": method([same_side, "The tail P(X < b) has the same area, so b is the same distance from X's mean, on the other side.", "b = %s − %s = %s" % [D(s.mu), D(off), D(v)], ending], ans.values)}}


func u_beyond_sd(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var e: Dictionary = scene(s)
	var ans := sf_ans("probability = ", s.prob)
	var words := "more than %s %s" % [sds(s.h), {"gt": "above the mean", "lt": "below the mean", "out": "from the mean"}[s.kind]]
	var asked := "Find the probability that X is %s." % words
	if rep == "words":
		asked = "One %s is chosen at random. Find the probability that its %s is %s." % [e.item, e.attr, words]
	elif rep == "diagram":
		asked = "The shaded area is the probability that X is %s. Find it." % words
	var hs: Q = s.sg.mul(s.h)
	var hi: Q = s.mu.add(hs)
	var lo: Q = s.mu.sub(hs)
	var out := {"lines": [opening(rep, s)], "asked": asked, "answer": ans, "table": null}
	if rep == "diagram":
		var shade: Array
		var marks: Array
		if s.kind == "out":
			shade = [[null, lo.to_float()], [hi.to_float(), null]]
			marks = [mk(lo), mk(hi)]
		else:
			shade = side_shade(s.x.to_float(), s.kind)
			marks = [mk(s.x)]
		out.graph = pic(s, shade, marks)
	var wrongs: Array = [wrong_x(s.other, M_OTHER_SIDE)]
	if s.kind == "out":
		wrongs.append(wrong_x(s.prob / 2.0, M_ONE_TAIL_LEFT))
		wrongs.append(wrong_x(s.no_sd * 2.0, M_NO_SD))
	else:
		wrongs.append(wrong_x(s.no_sd, M_NO_SD))
	out.wrongs = wrongs
	out.generic = near(s.prob)
	var mark: String
	var key: String
	var value: float = s.prob
	match s.kind:
		"gt":
			mark = "μ + %sσ = %s + %s × %s = %s, and shade above it" % [D(s.h), D(s.mu), D(s.h), D(s.sg), D(hi)]
			key = "Key normalcdf(%s, %s, %s, %s) and read %s." % [D(hi), INF, D(s.mu), D(s.sg), W(value)]
		"lt":
			mark = "μ − %sσ = %s − %s × %s = %s, and shade below it" % [D(s.h), D(s.mu), D(s.h), D(s.sg), D(lo)]
			key = "Key normalcdf(−%s, %s, %s, %s) and read %s." % [INF, D(lo), D(s.mu), D(s.sg), W(value)]
		_:
			mark = "μ ± %sσ, which are %s and %s, and shade the two tails" % [D(s.h), D(lo), D(hi)]
			key = "Key normalcdf(%s, %s, %s, %s) for the middle: read %s. The tails are 1 minus that: %s." % [D(lo), D(hi), D(s.mu), D(s.sg), W(1.0 - value), W(value)]
	var first := "Sketch the curve and mark %s." % mark
	if rep == "diagram":
		first = "The curve marks %s." % mark.replace(", and shade above it", "").replace(", and shade below it", "").replace(", and shade the two tails", "")
	var far: bool = s.h.to_float() > 1.0
	var look: String = "%s %s 1, so the area must be %s %s, which fits." % [D(s.h), ">" if far else "<", "under" if far else "over", "0.32" if s.kind == "out" else "0.16"]
	out.methods = {"sketch-and-shade": method([first, key, look, final_step(ans)], ans.values)}
	return out


# ── Symmetry and area ────────────────────────────────────────

func u_half_below_mean(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var e: Dictionary = scene(s)
	var ans := exact_ans("probability = " if rep == "words" else "P(X %s %s) = " % [rel(s.kind), D(s.mu)], Q.new(1, 2))
	var asked := "Write down P(X %s %s)." % [rel(s.kind), D(s.mu)]
	if rep == "words":
		asked = "One %s is chosen at random. Write down the probability that its %s is %s %s." % [e.item, e.attr, "below" if s.kind == "lt" else "above", bound_words(s, s.mu)]
	elif rep == "diagram":
		asked = "Write down the area of the shaded region."
	var out := {"lines": [opening(rep, s)], "asked": asked, "answer": ans, "table": null, "near_p": Q.new(1, 2)}
	if rep == "diagram":
		out.graph = curve(s.muf, s.sgf, side_shade(s.muf, s.kind), [mk(s.mu)])
	out.wrongs = pw(s, Q.new(68, 100), M_WHOLE_BAND) + pw(s, Q.new(34, 100), M_HALF_BAND) + pw(s, Q.new(1, 4), M_HALF)
	out.generic = [{"v": Q.new(1)}]
	var ending := "So %s" % final_text(ans)
	out.methods = {"mirror-tails": method(["The curve is symmetric about μ = %s, so the area below %s mirrors the area above it." % [D(s.mu), D(s.mu)], "Two equal areas make the whole area 1, so each is 1 ÷ 2 = 0.5", ending], ans.values),
		"area-bookkeeping": method(["The total area is 1.", "The mean cuts the curve into two equal halves: 1 ÷ 2 = 0.5", ending], ans.values)}
	return out


## The lines for a tail: the mean, the fact.
func _tail_lines(rep: String, s: Dictionary, up: bool, p: Q) -> Array:
	return [model(rep, s, s.mu, null), tail_line(rep, s, tail_x(s, up), tail_side(up), p)]


func u_mirror_tail(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: Q = s.p
	var ans := exact_ans("probability = " if rep == "words" else "P(%s) = " % tail_event(s, not s.up), p)
	var asked := "Find the area below %s." % D(s.lo) if not s.up else "Find the area above %s." % D(s.hi)
	var out := {"lines": _tail_lines(rep, s, s.up, p), "asked": ask_tail(rep, s, not s.up) if rep != "diagram" else "The shaded area is %s. %s" % [D(p), asked.replace("Find the area", "Find the area on the other side,")], "answer": ans, "table": null, "near_p": p}
	if rep == "diagram":
		out.lines = [curve_of(s)]
		out.graph = pic(s, tail_shade(s, s.up), [mk(s.lo), mk(s.hi)])
	out.wrongs = pw(s, one_minus(p), M_COMPLEMENT) + pw(s, Q.new(1, 2).sub(p), M_MEASURED_FROM_MEAN) + pw(s, p.mul(2), M_BOTH_TAILS)
	out.generic = []
	var ending := "So %s" % final_text(ans)
	var dist := "%s and %s are both %s from the mean %s." % [D(s.lo), D(s.hi), D(s.a), D(s.mu)]
	out.methods = {"mirror-tails": method([dist, "Equal distances either side of μ cut off equal tails, so P(%s) = P(%s)." % [tail_event(s, false), tail_event(s, true)], ending], ans.values),
		"shaded-sketch": method([sketch_line(rep, s, both_ends(s), tail_words(s, s.up)), "Flip the picture about %s: %s lands on %s, and the two tails match." % [D(s.mu), tail_words(s, s.up), tail_words(s, not s.up)], ending], ans.values)}
	return out


func u_mirror_complement(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	# The fact is the large area, past the mean, up to one end; the tail asked is on the far side.
	var big: Q = one_minus(s.p)
	var up: bool = s.up
	var given_text := "P(X < %s) = %s" % [D(s.hi), D(big)] if up else "P(X > %s) = %s" % [D(s.lo), D(big)]
	var ask_up: bool = not up
	var lines: Array = [model(rep, s, s.mu, null), tail_line(rep, s, tail_x(s, up), "lt" if up else "gt", big)] if rep == "words" else [curve_of(s), given_text]
	var ans := exact_ans("probability = " if rep == "words" else "P(%s) = " % ("X < %s" % D(s.lo) if up else "X > %s" % D(s.hi)), s.p)
	var asked_event: String = "X < %s" % D(s.lo) if up else "X > %s" % D(s.hi)
	var asked: String = ask_tail(rep, s, ask_up) if rep == "words" else "Find P(%s)." % asked_event
	var out := {"lines": lines, "asked": asked, "answer": ans, "table": null, "near_p": s.p}
	if rep == "diagram":
		out.graph = pic(s, side_shade(tail_x(s, up).to_float(), "lt" if up else "gt"), [mk(s.lo), mk(s.hi)])
	out.wrongs = pw(s, big, M_NO_COMPLEMENT) + pw(s, big.sub(Q.new(1, 2)), M_MEASURED_FROM_MEAN) + pw(s, one_minus(s.p.mul(2)), M_WHOLE_BAND)
	out.generic = []
	var ending := "So %s" % final_text(ans)
	var near_end := "X > %s" % D(s.hi) if up else "X < %s" % D(s.lo)
	var past := "1 − %s = %s" % [D(big), D(s.p)]
	out.methods = {"mirror-tails": method(["The tail on the far side of that end is P(%s) = %s." % [near_end, past], "%s and %s are both %s from the mean, so P(%s) is the same tail mirrored." % [D(s.lo), D(s.hi), D(s.a), asked_event], ending], ans.values),
		"area-bookkeeping": method(["The half of the curve up to the mean holds 0.5, so the piece from the mean to %s is %s − 0.5 = %s." % [D(tail_x(s, up)), D(big), D(big.sub(Q.new(1, 2)))],
			"The mirrored piece on the other side of the mean is the same size, %s, and it leaves 0.5 − %s = %s." % [D(big.sub(Q.new(1, 2))), D(big.sub(Q.new(1, 2))), D(s.p)], ending], ans.values),
		"shaded-sketch": method([sketch_line(rep, s, both_ends(s), "the area of %s" % D(big)), "What is left over is 1 − %s = %s, in the tail beyond %s." % [D(big), D(s.p), D(tail_x(s, up))], "Flip that tail about the mean to reach P(%s)." % asked_event, ending], ans.values)}
	return out


func u_middle_from_tail(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: Q = s.p
	var v: Q = one_minus(p.mul(2))
	var ans := exact_ans("probability = " if rep == "words" else "P(%s < X < %s) = " % [D(s.lo), D(s.hi)], v)
	var out := {"lines": _tail_lines(rep, s, s.up, p), "asked": ask_range(rep, s, s.lo, s.hi), "answer": ans, "table": null, "near_p": v}
	if rep == "diagram":
		out.graph = pic(s, tail_shade(s, s.up), [mk(s.lo), mk(s.hi)])
	out.wrongs = pw(s, p.mul(2), M_ADD_TAILS) + pw(s, one_minus(p), M_ONE_TAIL_LEFT) + pw(s, Q.new(1, 2).sub(p), M_MEASURED_FROM_MEAN)
	out.generic = []
	var ending := "So %s" % final_text(ans)
	out.methods = {"mirror-tails": method(["%s and %s are both %s from the mean, so the two tails are equal: each is %s." % [D(s.lo), D(s.hi), D(s.a), D(p)], "Take both tails from the whole area: 1 − 2 × %s = %s" % [D(p), D(v)], ending], ans.values),
		"area-bookkeeping": method(["The whole area is 1, and P(%s) is %s by symmetry." % [tail_event(s, not s.up), D(p)], "The area below %s is 1 − %s = %s." % [D(s.hi), D(p), D(one_minus(p))], "Take off the lower tail: %s − %s = %s" % [D(one_minus(p)), D(p), D(v)], ending], ans.values),
		"shaded-sketch": method([sketch_line(rep, s, both_ends(s), "both tails"), "Each shaded tail is %s, and the middle is what is left." % D(p), "1 − %s − %s = %s" % [D(p), D(p), D(v)], ending], ans.values)}
	return out


func u_tail_from_middle(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Q = s.c
	var v: Q = s.p
	var ans := exact_ans("probability = " if rep == "words" else "P(%s) = " % tail_event(s, s.up), v)
	var out := {"lines": [model(rep, s, s.mu, null), band_fact(rep, s, c)], "asked": ask_tail(rep, s, s.up), "answer": ans, "table": null, "near_p": v}
	if rep == "diagram":
		out.graph = pic(s, [[s.lo.to_float(), s.hi.to_float()]], [mk(s.lo), mk(s.hi)])
	out.wrongs = pw(s, one_minus(c), M_BOTH_TAILS) + pw(s, half(c), M_HALF_BAND) + pw(s, half(c).add(Q.new(1, 2)), M_OTHER_SIDE)
	out.generic = []
	var ending := "So %s" % final_text(ans)
	var left := "1 − %s = %s" % [D(c), D(one_minus(c))]
	out.methods = {"mirror-tails": method(["The band is centred on the mean, as both ends are %s from %s, so its two tails are equal." % [D(s.a), D(s.mu)], "They share what is left: %s, then %s ÷ 2 = %s" % [left, D(one_minus(c)), D(v)], ending], ans.values),
		"area-bookkeeping": method(["The whole area is 1: tail + %s + tail = 1." % D(c), "2 × tail = %s, so tail = %s ÷ 2 = %s" % [left, D(one_minus(c)), D(v)], ending], ans.values),
		"shaded-sketch": method([sketch_line(rep, s, both_ends(s), "the band between them"), "What is unshaded is %s, in two tails that mirror each other." % left, "One tail is %s ÷ 2 = %s" % [D(one_minus(c)), D(v)], ending], ans.values)}
	return out


func u_half_of_middle(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Q = s.c
	var v := half(c)
	var a: Q = s.mu if s.up else s.lo
	var b: Q = s.hi if s.up else s.mu
	var ans := exact_ans("probability = " if rep == "words" else "P(%s < X < %s) = " % [D(a), D(b)], v)
	var out := {"lines": [model(rep, s, s.mu, null), band_fact(rep, s, c)], "asked": ask_range(rep, s, a, b), "answer": ans, "table": null, "near_p": v}
	if rep == "diagram":
		out.graph = pic(s, [[s.lo.to_float(), s.hi.to_float()]], [mk(s.lo), mk(s.hi)])
	out.wrongs = pw(s, c, M_WHOLE_BAND) + pw(s, half(one_minus(c)), M_OTHER_SIDE) + pw(s, v.add(Q.new(1, 2)), M_HALF)
	out.generic = []
	var ending := "So %s" % final_text(ans)
	out.methods = {"mirror-tails": method(["Both ends are %s from the mean %s, so the mean cuts the band into two mirror halves." % [D(s.a), D(s.mu)], "Each half is %s ÷ 2 = %s" % [D(c), D(v)], ending], ans.values),
		"area-bookkeeping": method(["The band's area is the two pieces either side of the mean: piece + piece = %s." % D(c), "The pieces are equal, so piece = %s ÷ 2 = %s" % [D(c), D(v)], ending], ans.values)}
	return out


func u_mean_to_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: Q = s.p
	var v: Q = Q.new(1, 2).sub(p)
	var a: Q = s.mu if s.up else s.lo
	var b: Q = s.hi if s.up else s.mu
	var ans := exact_ans("probability = " if rep == "words" else "P(%s < X < %s) = " % [D(a), D(b)], v)
	var out := {"lines": _tail_lines(rep, s, s.up, p), "asked": ask_range(rep, s, a, b), "answer": ans, "table": null, "near_p": v}
	if rep == "diagram":
		out.graph = pic(s, tail_shade(s, s.up), [mk(tail_x(s, s.up))])
	out.wrongs = pw(s, p, M_OTHER_SIDE) + pw(s, one_minus(p), M_HALF) + pw(s, one_minus(p.mul(2)), M_WHOLE_BAND)
	out.generic = []
	var ending := "So %s" % final_text(ans)
	var half_side := "above" if s.up else "below"
	out.methods = {"area-bookkeeping": method(["The half of the curve %s the mean holds 0.5." % half_side, "Take off the tail: 0.5 − %s = %s" % [D(p), D(v)], ending], ans.values),
		"shaded-sketch": method([sketch_line(rep, s, D(tail_x(s, s.up)), tail_words(s, s.up)), "The half of the curve %s the mean is 0.5, and the region asked is what is left when the tail is taken off." % half_side, "0.5 − %s = %s" % [D(p), D(v)], ending], ans.values)}
	return out


func u_between_from_two_tails(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p1: Q = s.p1
	var p2: Q = s.p2
	var v: Q = one_minus(p1).sub(p2)
	var ans := exact_ans("probability = " if rep == "words" else "P(%s < X < %s) = " % [D(s.x1), D(s.x2)], v)
	var lines: Array = [model(rep, s, null, null), tail_line(rep, s, s.x1, "lt", p1), tail_line(rep, s, s.x2, "gt", p2)]
	var out := {"lines": lines, "asked": ask_range(rep, s, s.x1, s.x2), "answer": ans, "table": null, "near_p": v}
	if rep == "diagram":
		out.graph = curve(s.muf, s.sgf, [[null, s.x1.to_float()], [s.x2.to_float(), null]], [mk(s.x1), mk(s.x2)])
	out.wrongs = pw(s, p1.add(p2), M_ADD_TAILS) + pw(s, one_minus(p1), M_ONE_TAIL_LEFT) + pw(s, one_minus(p2), M_ONE_TAIL_LEFT) + pw(s, one_minus(p1.mul(2)), M_EQUAL_TAILS)
	out.generic = []
	var ending := "So %s" % final_text(ans)
	out.methods = {"area-bookkeeping": method(["The three regions fill the whole area, so the total is 1.", "Take both tails off: 1 − %s − %s = %s" % [D(p1), D(p2), D(v)], ending], ans.values),
		"shaded-sketch": method([("Read the curve: the two tails are shaded." if rep == "diagram" else "Sketch the curve, mark %s and %s, and shade the two tails." % [D(s.x1), D(s.x2)]), "The tails are different sizes, %s and %s, and the middle is what is left." % [D(p1), D(p2)], "1 − %s − %s = %s" % [D(p1), D(p2), D(v)], ending], ans.values)}
	return out


func u_tail_from_band(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Q = s.c
	var ans := sf_ans("probability = " if rep == "words" else "P(X < w) = ", s.prob)
	var u: String = scene(s).unit
	var fact := "%s%% of them are between w%s and %s%s." % [pct(c), u, D(s.x), u] if rep == "words" else "P(w < X < %s) = %s" % [D(s.x), D(c)]
	var e: Dictionary = scene(s)
	var asked := "Find P(X < w)." if rep != "words" else "One %s is chosen at random. Find the probability that its %s is less than w%s." % [e.item, e.attr, u]
	var out := {"lines": [opening(rep, s), fact], "asked": asked, "answer": ans, "table": null}
	out.wrongs = [wrong_x(s.one, M_ONE_TAIL_LEFT), wrong_x(s.u, M_OTHER_SIDE)]
	out.generic = near(s.prob)
	var key := "Key normalcdf(%s, %s, %s, %s) and read P(X > %s) = %s." % [D(s.x), INF, D(s.mu), D(s.sg), D(s.x), W(s.u)]
	var sub := "1 − %s − %s = %s" % [D(c), W(s.u), W(s.prob)]
	out.methods = {"area-bookkeeping": method([key, "Below w, between w and %s, and above %s fill the whole area, so the three add up to 1." % [D(s.x), D(s.x)], sub, final_step(ans)], ans.values),
		"shaded-sketch": method(["Sketch the curve, mark w to the left of %s, and shade the band between them, which is %s." % [D(s.x), D(c)], key, "What is left is the tail below w: %s" % sub, final_step(ans)], ans.values)}
	return out


func u_mirror_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var given: Q = s.lo if s.given_low else s.hi
	var v: Q = s.hi if s.given_low else s.lo
	var ans := exact_ans("b = ", v)
	ans.signed = true
	var u: String = scene(s).unit
	var fact := "P(X < %s) = P(X > b)" % D(s.lo) if s.given_low else "P(X > %s) = P(X < b)" % D(s.hi)
	if rep == "words":
		fact = "The share of them below %s%s equals the share above b%s." % [D(s.lo), u, u] if s.given_low else "The share of them above %s%s equals the share below b%s." % [D(s.hi), u, u]
	var out := {"lines": [model(rep, s, s.mu, null), fact], "asked": "Find b.", "answer": ans, "table": null}
	if rep == "diagram":
		out.graph = pic(s, [[null, s.lo.to_float()], [s.hi.to_float(), null]], [mk(given), mk_as(v, "b")])
	out.wrongs = [wrong({"v": given.neg()}, M_ABOUT_ZERO), wrong({"v": given.add(s.mu)}, M_ADD_MEAN)]
	out.generic = [{"v": given}, {"v": s.a}, {"v": v.add(1)}, {"v": v.sub(1)}, {"v": v.add(2)}]
	var ending := "So %s" % final_text(ans)
	var d := "%s is %s %s the mean %s." % [D(given), D(s.a), "below" if s.given_low else "above", D(s.mu)]
	var calc := "b = %s %s %s = %s" % [D(s.mu), "+" if s.given_low else "−", D(s.a), D(v)]
	out.methods = {"mirror-tails": method([d, "Equal tails are cut off at equal distances either side of μ.", calc, ending], ans.values),
		"shaded-sketch": method([sketch_line(rep, s, "%s and b" % D(given), "the two equal tails"), d + " Flip it about the mean to reach b.", calc, ending], ans.values)}
	return out


# ── The central interval (Paper 2) ───────────────────────────

## The split of what is left, the area to the left, and invNorm: three lines for split-tails.
static func split_lines(s: Dictionary) -> Array:
	var c: Q = s.level
	var out_q: Q = one_minus(c)
	return ["What is left is 1 − %s = %s, which splits into two equal tails: %s ÷ 2 = %s." % [D(c), D(out_q), D(out_q), D(half(out_q))],
		"The area to the left of the upper end is %s + %s = %s." % [D(c), D(half(out_q)), D(c.add(half(out_q)))],
		"Key invNorm(%s, %s, %s) and read %s." % [D(c.add(half(out_q))), D(s.mu), D(s.sg), W(s.hif)]]


static func center_line(s: Dictionary) -> String:
	return "Key inverse normal with Tail: CENTER, area %s, μ = %s, σ = %s, and read the two ends: %s and %s." % [D(s.level), D(s.mu), D(s.sg), W(s.lof), W(s.hif)]


func u_central_k(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := sf_ans("k = ", s.width)
	var fact := "P(%s − k < X < %s + k) = %s" % [D(s.mu), D(s.mu), D(s.level)]
	var out := {"lines": ["X ~ N(%s, %s²)" % [D(s.mu), D(s.sg)], fact], "asked": "Find k.", "answer": ans, "table": null}
	if rep == "diagram":
		out.graph = curve(s.muf, s.sgf, [[s.lof, s.hif]], [mk_as(s.lof, "%s − k" % D(s.mu)), mk_as(s.muf, D(s.mu)), mk_as(s.hif, "%s + k" % D(s.mu))])
	out.wrongs = [wrong_x(s.zc * s.sgf, M_LEFT_TAIL), wrong_x(s.hif, M_ENDPOINT), wrong_x(s.z, M_NO_SIGMA)]
	out.generic = vs([s.width * 2.0, s.width * 1.1, s.width * 0.9, s.width + 1.0])
	var take := "k = %s − %s = %s" % [W(s.hif), D(s.mu), W(s.width)]
	out.methods = {"split-tails": method(split_lines(s) + [take, final_step(ans)], ans.values),
		"gdc-center": method([center_line(s), "k is the distance from the mean to the upper end: " + take, final_step(ans)], ans.values),
		"gdc-solver": method(["Graph y = normalcdf(%s − x, %s + x, %s, %s) and y = %s, or use the solver for x." % [D(s.mu), D(s.mu), D(s.mu), D(s.sg), D(s.level)], "The graphs meet at x = %s, so k = %s." % [W(s.width), W(s.width)], final_step(ans)], ans.values)}
	return out


static func ends_val(lo: float, hi: float) -> Dictionary:
	return {"lo": qf(lo), "hi": qf(hi), "text": "%s < X < %s" % [Fmt.sf(lo), Fmt.sf(hi)]}


func u_central_endpoints(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var v := ends_val(s.lof, s.hif)
	var ans := Answer.make("form", v, {"parts": [{"slot": "lo"}, " < X < ", {"slot": "hi"}]})
	ans.show = "sf"
	var asked := "Find the interval, symmetric about the mean, that holds an area of %s under the curve of X." % D(s.level)
	if rep == "words":
		asked = "Find the interval, symmetric about the mean, that contains %s%% of them. Write it with X for the %s." % [pct(s.level), scene(s).attr]
	var out := {"lines": [opening(rep, s)], "asked": asked, "answer": ans, "table": null}
	out.wrongs = [wrong(ends_val(s.wlo, s.whi), M_LEFT_TAIL), wrong(ends_val(s.zlo, s.zhi), M_NO_SIGMA)]
	out.generic = [ends_val(s.muf - s.width * 1.2, s.muf + s.width * 1.2), ends_val(s.muf - s.width * 0.8, s.muf + s.width * 0.8), ends_val(s.muf, s.hif)]
	var ending: String = "So %s, to 3 s.f." % Answer.text(ans)
	var low := "The lower end is the mirror of it: %s − (%s − %s) = %s" % [D(s.mu), W(s.hif), D(s.mu), W(s.lof)]
	out.methods = {"split-tails": method(split_lines(s) + [low, ending], ans.values),
		"gdc-center": method([center_line(s), ending], ans.values),
		"gdc-solver": method(["Graph y = normalcdf(%s − x, %s + x, %s, %s) and y = %s, or use the solver for x." % [D(s.mu), D(s.mu), D(s.mu), D(s.sg), D(s.level)], "The graphs meet at x = %s." % W(s.width), "The ends are %s − %s = %s and %s + %s = %s." % [D(s.mu), W(s.width), W(s.lof), D(s.mu), W(s.width), W(s.hif)], ending], ans.values)}
	return out


func u_central_k_sd(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := sf_ans("k = ", s.z)
	var e := "P(%s − %sk < X < %s + %sk) = %s" % [D(s.mu), D(s.sg), D(s.mu), D(s.sg), D(s.level)]
	if rep == "words":
		e = "%s%% of them lie within k standard deviations of the mean." % pct(s.level)
	var out := {"lines": [opening(rep, s), e], "asked": "Find k.", "answer": ans, "table": null}
	out.wrongs = [wrong_x(s.zc, M_LEFT_TAIL), wrong_x(s.width, M_SCALED_K), wrong_x(s.hif, M_ENDPOINT)]
	out.generic = vs([s.z * 2.0, s.z * 1.1, s.z * 0.9, s.z + 1.0])
	var last := "k counts standard deviations: (%s − %s) ÷ %s = %s" % [W(s.hif), D(s.mu), D(s.sg), W(s.z)]
	out.methods = {"split-tails": method(split_lines(s) + [last, final_step(ans)], ans.values),
		"gdc-center": method([center_line(s), last, final_step(ans)], ans.values),
		"gdc-solver": method(["Graph y = normalcdf(%s − %s x, %s + %s x, %s, %s) and y = %s, or use the solver for x." % [D(s.mu), D(s.sg), D(s.mu), D(s.sg), D(s.mu), D(s.sg), D(s.level)], "The graphs meet at x = %s, so k = %s." % [W(s.z), W(s.z)], final_step(ans)], ans.values)}
	return out
