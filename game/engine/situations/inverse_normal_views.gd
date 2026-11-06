class_name InverseNormalViews
extends NormalProbabilityViews
## The views on the `inverse-normal` situation: one builder per unknown of t4-inverse-normal. They
## extend NormalProbabilityViews for its stories, its numbers and its curve. An area is given and
## the value that cuts it off is asked for. Paper 2 values are to 3 s.f. (show "sf", with the
## rounding trap). Paper 1 can't use invNorm, so its four unknowns reach a value the way the exam
## does: two curves with one σ, the mirror about μ, the 68-95-99.7 rule, or a line of N(0, 1) given.
## Those answers are exact, and their methods are via-z and sketch-tail only.
##
## Representations: "equation" (X ~ N(35, 5²) and P(X < a) = 0.2), "words" (a story with
## percentages) and "diagram" (the curve with the area shaded and the value marked by a letter:
## the stem gives the area and the figure says which side it is on).

const IN_SK := "SL4.9.inverse-normal#"
const IN_UPPER := IN_SK + "0"
const IN_Z_OR_P := IN_SK + "1"
const IN_CDF := IN_SK + "2"
const IN_T := "t4-inverse-normal#"
const IN_CONVERT := IN_T + "3"
const IN_NO_SD := IN_T + "4"
const IN_CENTRAL := IN_T + "5"
const IN_TO_END := IN_T + "6"
const IN_EQUAL := IN_T + "7"
const IN_SWAP := IN_T + "8"
const IN_OTHER_END := IN_T + "9"
const IN_KEEP := IN_T + "10"
const IN_SIDE := IN_T + "11"
const IN_GAP_WAY := IN_T + "12"
const IN_DISTANCE := IN_T + "13"
const IN_RULE_K := IN_T + "14"
const IN_PAST := IN_T + "15"

## One row for each of NormalUnknownViews.CONTEXTS: the measures, and the two ends of them.
const IN_WORDS := [
	{"attrs": "masses", "top": "heaviest", "bottom": "lightest"},
	{"attrs": "lengths", "top": "longest", "bottom": "shortest"},
	{"attrs": "times", "top": "slowest", "bottom": "fastest"},
	{"attrs": "volumes of water", "top": "fullest", "bottom": "least full"},
	{"attrs": "heights", "top": "tallest", "bottom": "shortest"},
	{"attrs": "lifetimes", "top": "longest-lasting", "bottom": "shortest-lived"},
	{"attrs": "daily distances", "top": "longest", "bottom": "shortest"},
	{"attrs": "masses", "top": "heaviest", "bottom": "lightest"},
]

## The share of the whole inside each band of the 68-95-99.7 rule.
const IN_BAND := {1: [68, 100], 2: [95, 100], 3: [997, 1000]}
const IN_RATIO := {2: "twice", 3: "three times", 4: "four times"}

const IN_ASKS := ["value-below", "value-above", "top-percent", "bottom-percent", "quartile", "percentile", "most-above",
	"central-bounds", "band-end", "ratio-tails", "shift-same-sd", "mirror-bound", "rule-value", "given-z"]


func needs() -> Dictionary:
	var out := {}
	for u in IN_ASKS:
		out[u] = {"ask": u}
	return out


## Paper 1 is the four unknowns that need no calculator, and every other is Paper 2.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	if not has(unknown):
		return []
	return [1] if unknown in InverseNormalSituation.P1_ASKS else [2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = InverseNormalSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func words_of(s: Dictionary) -> Dictionary:
	return IN_WORDS[s.ctx]


static func val_ans(label: String, unit: String, x: float) -> Dictionary:
	var ans := Answer.make("number", {"v": qf(x)}, {}, label, unit)
	ans.show = "sf"
	return ans


static func exact_val(label: String, x: Variant) -> Dictionary:
	var ans := Answer.make("number", {"v": Q.of(x)}, {}, label)
	ans.show = "dec"
	ans.exact = true
	return ans


## An answer named by the story's own measure: "mass = 39.2 kg".
static func story_ans(s: Dictionary, x: float) -> Dictionary:
	var c := scene(s)
	return val_ans(c.attr + " = ", c.unit, x)


static func wx(x: float, ref: String) -> Dictionary:
	return wrong({"v": qf(x)}, ref)


static func wq(x: Variant, ref: String) -> Dictionary:
	return wrong({"v": Q.of(x)}, ref)


## The left area as the working writes it.
static func left_text(s: Dictionary) -> String:
	return D(s.left) if s.has("left") else W(s.leftf)


static func signed_text(z: float) -> String:
	return W(z) if z >= 0.0 else "(%s)" % W(z)


static func mk(at: float, label: String) -> Dictionary:
	return {"at": at, "label": label}


## The curve with the area on `rel`'s side of the value shaded, the value marked by a letter.
static func tail_fig(s: Dictionary, letter: String) -> Dictionary:
	var x: float = Q.of(s.x).to_float() if s.x is Q else s.x
	var shade: Array = [[null, x]] if s.rel == "<" else [[x, null]]
	return curve(s.muf, s.sgf, shade, [mk(x, letter), mk(s.muf, D(s.mu))])


static func area_line(a: Variant) -> String:
	return "The shaded area is %s." % D(a)


static func ordinal(n: int) -> String:
	var end := "th"
	if n % 100 < 11 or n % 100 > 13:
		end = {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")
	return "%d%s" % [n, end]


## The area to the left, the step every invNorm needs.
static func left_line(s: Dictionary, letter: String) -> String:
	if s.rel == "<":
		return "The area to the left of %s is %s." % [letter, D(s.p)]
	return "invNorm needs the area to the left: 1 − %s = %s." % [D(s.p), D(s.left)]


static func invnorm_line(s: Dictionary, letter: String) -> String:
	return "%s = invNorm(%s, %s, %s) = %s" % [letter, left_text(s), D(s.mu), D(s.sg), W(s.x)]


static func z_line(s: Dictionary) -> String:
	return "z = invNorm(%s, 0, 1) = %s" % [left_text(s), W(s.z)]


## A z as the working shows it, so the next line follows from what is written.
static func shown(z: float) -> float:
	return W(z).replace("−", "-").to_float()


static func x_from_z(s: Dictionary, letter: String, z: float = NAN) -> String:
	var zv: float = s.z if is_nan(z) else z
	return "%s = μ + zσ = %s + %s × %s = %s" % [letter, D(s.mu), signed_text(zv), D(s.sg), W(s.muf + shown(zv) * s.sgf)]


## Which side of the mean the shaded area puts the value.
static func side_of_mean(s: Dictionary, letter: String, shaded: float) -> String:
	var share := "more than" if shaded > 0.5 else "less than"
	var side := "above" if s.leftf > 0.5 else "below"
	return "That area is %s a half, so %s is %s the mean %s." % [share, letter, side, D(s.mu)]


static func shade_line(rep: String, s: Dictionary, letter: String) -> String:
	var side := "left" if s.rel == "<" else "right"
	if rep == "diagram":
		return "On the curve, the shaded area %s is to the %s of %s." % [D(s.p), side, letter]
	return "Sketch the curve with the mean %s in the middle, and shade %s to the %s of %s." % [D(s.mu), D(s.p), side, letter]


## The three methods for a value with one left area. first is what comes before invNorm where the
## left area takes more than one line; shade replaces the sketch's first line.
func tail_methods(rep: String, s: Dictionary, letter: String, ans: Dictionary, first: Array = [], shade: String = "") -> Dictionary:
	var lead: Array = first if not first.is_empty() else [left_line(s, letter)]
	var top: String = shade if shade != "" else shade_line(rep, s, letter)
	var sketch: Array = [top]
	if first.is_empty():
		sketch.append(side_of_mean(s, letter, s.p.to_float()))
		if s.rel == ">":
			sketch.append(lead[0])
	else:
		sketch += lead
	return {"gdc-invnorm-left": method(lead + [invnorm_line(s, letter), final_step(ans)], ans.values),
		"via-z": method(lead + [z_line(s), x_from_z(s, letter), final_step(ans)], ans.values),
		"sketch-tail": method(sketch + [invnorm_line(s, letter), final_step(ans)], ans.values)}


## The slips of a plain value: the mirror (near, so it is always offered), then in the seed's
## order the others, which sit far from the mean and would give the answer away together.
func tail_options(out: Dictionary, s: Dictionary, near_ref: String, area: Q, rng: Seeded) -> void:
	var far: Array = [wx(s.no_sd, IN_NO_SD), wx(s.z, IN_Z_OR_P), wx(area.to_float(), IN_Z_OR_P), wx(s.cdf, IN_CDF)]
	out.wrongs = [wx(s.flip, near_ref)] + rng.shuffled(far)
	out.generic = vs([s.x + 0.5 * s.sgf, s.x - 0.5 * s.sgf, s.x + 0.25 * s.sgf, s.x - 0.25 * s.sgf])


# ── A tail ───────────────────────────────────────────────────

func _tail_eq(rep: String, s: Dictionary, near_ref: String, rng: Seeded) -> Dictionary:
	var ans := val_ans("a = ", "", s.x)
	var lines: Array = [opening("equation", s), "P(X %s a) = %s" % [s.rel, D(s.p)]]
	var out := {"lines": lines, "asked": "Find a.", "answer": ans, "table": null}
	if rep == "diagram":
		lines[1] = area_line(s.p)
		out.graph = tail_fig(s, "a")
	tail_options(out, s, near_ref, s.p, rng)
	out.methods = tail_methods(rep, s, "a", ans)
	return out


func u_value_below(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _tail_eq(rep, s, IN_CONVERT, rng)


func u_value_above(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _tail_eq(rep, s, IN_UPPER, rng)


## The top or bottom of a story. A figure shades it and marks the cut-off.
func _cut_off(rep: String, s: Dictionary, end: String, near_ref: String, rng: Seeded) -> Dictionary:
	var c := scene(s)
	var share := pct(s.p)
	var adj: String = words_of(s)[end]
	var best := "least" if end == "top" else "greatest"
	var lines: Array = [opening("words", s), "The %s %s%% of the %s, the %s, are set aside." % [end, share, c.items, adj]]
	var asked := "Find the %s %s of %s that is set aside." % [best, c.attr, an(c.item).to_lower()]
	var ans := story_ans(s, s.x)
	var out := {"lines": lines, "asked": asked, "answer": ans, "table": null}
	var letter := "x"
	if rep == "diagram":
		letter = "a"
		lines[1] = "The shaded region is the %s%% of the %s that are set aside." % [share, c.items]
		out.graph = tail_fig(s, "a")
	tail_options(out, s, near_ref, s.p, rng)
	out.methods = tail_methods(rep, s, letter, ans)
	return out


func u_top_percent(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _cut_off(rep, s, "top", IN_UPPER, rng)


func u_bottom_percent(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _cut_off(rep, s, "bottom", IN_CONVERT, rng)


func u_quartile(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := scene(s)
	var label: String = s.which + " quartile"
	var ans := val_ans(label + " = ", c.unit if rep == "words" else "", s.x)
	var lines: Array = [opening(rep, s)]
	var asked := "Find the %s of X." % label
	if rep == "words":
		asked = "Find the %s of the %s." % [label, words_of(s).attrs]
	var out := {"lines": lines, "asked": asked, "answer": ans, "table": null}
	if rep == "diagram":
		ans = val_ans("Q = ", "", s.x)
		out.answer = ans
		lines[0] = opening("equation", s)
		lines.append(area_line(s.p))
		out.asked = "Q is a quartile of X. Find Q."
		out.graph = tail_fig(s, "Q")
	# A figure can shade the left area already, and then the slip is converting it.
	tail_options(out, s, IN_CONVERT if rep == "diagram" and s.rel == "<" else IN_UPPER, s.left, rng)
	if rep == "diagram":
		out.methods = tail_methods(rep, s, "Q", ans)
		return out
	var why := "A quartile leaves a quarter of the area on one side: the %s, Q, has %s of the area to its left." % [label, D(s.left)]
	var top := "Sketch the curve with the mean %s in the middle, and shade %s to the left of Q." % [D(s.mu), D(s.left)]
	out.methods = tail_methods(rep, s, "Q", ans, [why], top)
	out.methods["sketch-tail"].steps.insert(1, side_of_mean(s, "Q", s.left.to_float()))
	return out


func u_percentile(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = roundi(s.p.to_float() * 100.0)
	var name := "%s percentile" % ordinal(n)
	var lines: Array = [opening("words", s)]
	var asked := "Find the %s of the %s." % [name, words_of(s).attrs]
	var ans := story_ans(s, s.x)
	var out := {"lines": lines, "asked": asked, "answer": ans, "table": null}
	var letter := "x"
	if rep == "diagram":
		letter = "a"
		lines.append("The %s of the %s is marked a." % [name, words_of(s).attrs])
		out.asked = "Find a."
		ans = val_ans("a = ", "", s.x)
		out.answer = ans
		out.graph = tail_fig(s, "a")
	tail_options(out, s, IN_CONVERT, s.p, rng)
	var first := "The %s has %d%% of the values below it, so the area to the left of %s is %s." % [name, n, letter, D(s.p)]
	out.methods = tail_methods(rep, s, letter, ans, [first], shade_line(rep, s, letter))
	out.methods["sketch-tail"].steps.insert(1, side_of_mean(s, letter, s.p.to_float()))
	return out


func u_most_above(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := scene(s)
	var ans := val_ans("a = ", "", s.x)
	var lines: Array = [opening(rep if rep == "words" else "equation", s), "P(X > a) = %s" % D(s.p)]
	if rep == "words":
		lines[1] = "%s%% of the %s have a %s above a%s." % [pct(s.p), c.items, c.attr, c.unit]
	var out := {"lines": lines, "asked": "Find a.", "answer": ans, "table": null}
	if rep == "diagram":
		lines[1] = area_line(s.p)
		out.graph = tail_fig(s, "a")
	tail_options(out, s, IN_UPPER, s.p, rng)
	out.methods = tail_methods(rep, s, "a", ans)
	return out


# ── Two ends ─────────────────────────────────────────────────

static func ends(lo: float, hi: float) -> Dictionary:
	return {"lo": qf(lo), "hi": qf(hi), "text": "a = %s, b = %s" % [Fmt.sf(lo), Fmt.sf(hi)]}


func u_central_bounds(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := scene(s)
	var ans := Answer.make("form", ends(s.lof, s.hif), {"parts": ["a = ", {"slot": "lo"}, ", b = ", {"slot": "hi"}]})
	ans.show = "sf"
	var lines: Array = [opening("equation", s), "P(a < X < b) = %s, and a and b are the same distance from the mean." % D(s.level)]
	if rep == "words":
		lines = [opening("words", s), "The middle %s%% of the %s lie between a%s and b%s, with the mean halfway between them." % [pct(s.level), c.items, c.unit, c.unit]]
	var out := {"lines": lines, "asked": "Find a and b.", "answer": ans, "table": null}
	if rep == "diagram":
		lines[1] = "The shaded area is %s, and a and b are the same distance from the mean." % D(s.level)
		out.graph = curve(s.muf, s.sgf, [[s.lof, s.hif]], [mk(s.lof, "a"), mk(s.muf, D(s.mu)), mk(s.hif, "b")])
	out.wrongs = [wrong(ends(s.wlo, s.whi), IN_CENTRAL), wrong(ends(s.nlo, s.nhi), IN_NO_SD), wrong(ends(-s.z, s.z), IN_Z_OR_P)]
	out.generic = [1.2, 0.8, 1.4, 0.6, 1.6].map(func(f): return ends(s.muf - s.z * s.sgf * f, s.muf + s.z * s.sgf * f))
	# With a small σ those can all round alike, so the last ones step by the third figure itself.
	var unit: float = pow(10.0, floorf(log(s.hif) / log(10.0)) - 2.0)
	for k in [1, 2, 3, 4]:
		out.generic.append(ends(s.lof - k * unit, s.hif + k * unit))
	var rest: Q = Q.new(1).sub(s.level)
	var tail: Q = rest.div(Q.new(2))
	var split := "What is left is 1 − %s = %s, so each tail is %s ÷ 2 = %s." % [D(s.level), D(rest), D(rest), D(tail)]
	var left := "The area to the left of b is %s + %s = %s." % [D(s.level), D(tail), D(s.left)]
	var mirror := "a is the mirror of b: %s − (%s − %s) = %s" % [D(s.mu), W(s.hif), D(s.mu), W(s.lof)]
	var step: float = shown(s.z) * s.sgf
	var both := "a = %s − %s × %s = %s and b = %s + %s × %s = %s" % [D(s.mu), W(s.z), D(s.sg), W(s.muf - step), D(s.mu), W(s.z), D(s.sg), W(s.muf + step)]
	var top := "Sketch the curve and shade the middle %s, with the mean %s in its centre, so a is below the mean and b above it." % [D(s.level), D(s.mu)]
	if rep == "diagram":
		top = "On the curve, the shaded area %s has the mean %s in its centre, so a is below the mean and b above it." % [D(s.level), D(s.mu)]
	var ending := final_step(ans)
	out.methods = {"gdc-invnorm-left": method([split, left, invnorm_line(s, "b"), mirror, ending], ans.values),
		"via-z": method([split, left, z_line(s), both, ending], ans.values),
		"sketch-tail": method([top, split + " " + left, invnorm_line(s, "b"), mirror, ending], ans.values)}
	return out


func u_band_end(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := scene(s)
	var lower: bool = s.which == "lower"
	var ans := val_ans("w = ", "", s.x)
	var event_text := "P(w < X < %s) = %s" % [D(s.b), D(s.level)] if lower else "P(%s < X < w) = %s" % [D(s.b), D(s.level)]
	var lines: Array = [opening(rep if rep == "words" else "equation", s), event_text]
	if rep == "words":
		var range_text := "w%s and %s%s" % [c.unit, D(s.b), c.unit] if lower else "%s%s and w%s" % [D(s.b), c.unit, c.unit]
		lines[1] = "%s%% of the %s have a %s between %s." % [pct(s.level), c.items, c.attr, range_text]
	var out := {"lines": lines, "asked": "Find w.", "answer": ans, "table": null}
	if rep == "diagram":
		lines[1] = area_line(s.level)
		var b: float = s.b.to_float()
		out.graph = curve(s.muf, s.sgf, [[s.x, b] if lower else [b, s.x]], [mk(s.x, "w"), mk(s.muf, D(s.mu)), mk(b, D(s.b))])
	out.wrongs = rng.shuffled([wx(s.to_end, IN_TO_END), wx(s.equal, IN_EQUAL)])
	out.generic = vs([s.x + 0.5 * s.sgf, s.x - 0.5 * s.sgf, s.x + 0.25 * s.sgf, s.x - 0.25 * s.sgf])
	var below := "P(X < %s) = normalcdf(−%s, %s, %s, %s) = %s" % [D(s.b), INF, D(s.b), D(s.mu), D(s.sg), W(s.below)]
	# The z route keys z as the line shows it, so each number here follows from the one before.
	var zb_key := Fmt.work(s.zb, 6)
	var below_key: float = InverseNormalSituation.phi(zb_key.replace("−", "-").to_float())
	var left_key: float = below_key - s.level.to_float() if lower else below_key + s.level.to_float()
	var z_key: float = InverseNormalSituation.inv(left_key)
	var below_z := "z for %s is (%s − %s) ÷ %s = %s, so P(X < %s) = normalcdf(−%s, %s, 0, 1) = %s" % [D(s.b), D(s.b), D(s.mu), D(s.sg), zb_key, D(s.b), INF, zb_key, W(below_key)]
	var take_z := "P(X < w) = %s %s %s = %s" % [W(below_key), "−" if lower else "+", D(s.level), W(left_key)]
	var key_z := "z = invNorm(%s, 0, 1) = %s" % [W(left_key), W(z_key)]
	var take := "P(X < w) = %s %s %s = %s" % [W(s.below), "−" if lower else "+", D(s.level), W(s.leftf)]
	var top := "Sketch the curve, mark %s and shade %s to its %s: w is the other end of the band." % [D(s.b), D(s.level), "left" if lower else "right"]
	if rep == "diagram":
		top = "On the curve, the shaded band runs %s %s, so w is its other end." % ["down from" if lower else "up from", D(s.b)]
	var ending := final_step(ans)
	out.methods = {"gdc-invnorm-left": method([below, take, invnorm_line(s, "w"), ending], ans.values),
		"via-z": method([below_z, take_z, key_z, x_from_z(s, "w", z_key), ending], ans.values),
		"sketch-tail": method([top, below, take, invnorm_line(s, "w"), ending], ans.values)}
	return out


func u_ratio_tails(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c := scene(s)
	var letter: String = s.which
	var ans := val_ans(letter + " = ", "", s.x)
	var r: int = s.r
	var hi_big: bool = s.big == "b"
	var link := "P(X > b) = %dP(X < a)" % r if hi_big else "P(X < a) = %dP(X > b)" % r
	var lines: Array = [opening(rep if rep == "words" else "equation", s), "P(a < X < b) = %s" % D(s.level), link]
	if rep == "words":
		lines[1] = "%s%% of the %s have a %s between a%s and b%s." % [pct(s.level), c.items, c.attr, c.unit, c.unit]
		var more := "above b%s" % c.unit if hi_big else "below a%s" % c.unit
		var less := "below a%s" % c.unit if hi_big else "above b%s" % c.unit
		lines[2] = "The share %s is %s the share %s." % [more, IN_RATIO[r], less]
	var out := {"lines": lines, "asked": "Find %s." % letter, "answer": ans, "table": null}
	if rep == "diagram":
		lines[1] = area_line(s.level)
		out.graph = curve(s.muf, s.sgf, [[s.afl, s.bfl]], [mk(s.afl, "a"), mk(s.muf, D(s.mu)), mk(s.bfl, "b")])
	out.wrongs = rng.shuffled([wx(s.equal, IN_EQUAL), wx(s.swap, IN_SWAP), wx(s.other, IN_OTHER_END)])
	out.generic = vs([s.x + 0.5 * s.sgf, s.x - 0.5 * s.sgf, s.x + 0.25 * s.sgf, s.x - 0.25 * s.sgf])
	var share := "The tails hold 1 − %s = %s, and one is %d times the other, so the smaller is %s ÷ %d = %s and the larger is %d × %s = %s." % [D(s.level), D(s.rest), r, D(s.rest), r + 1, D(s.small), r, D(s.small), D(s.large)]
	var left := "The area to the left of a is P(X < a) = %s." % D(s.ta)
	if letter == "b":
		left = "The area to the left of b is 1 − %s = %s." % [D(s.tb), D(s.left)]
	var bigger := "the tail above b" if hi_big else "the tail below a"
	var top := "Sketch the curve with a below the mean and b above it, and make %s the larger tail." % bigger
	if rep == "diagram":
		top = "On the curve, a is below the mean and b above it, and %s is the larger tail." % bigger
	var ending := final_step(ans)
	out.methods = {"gdc-invnorm-left": method([share, left, invnorm_line(s, letter), ending], ans.values),
		"via-z": method([share, left, z_line(s), x_from_z(s, letter), ending], ans.values),
		"sketch-tail": method([top, share, left, invnorm_line(s, letter), ending], ans.values)}
	return out


# ── Paper 1: no calculator ───────────────────────────────────

static func above_below(d: int) -> String:
	return "above" if d > 0 else "below"


func u_shift_same_sd(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := scene(s)
	var ans := exact_val("b = ", s.x)
	var d: int = s.dist
	var gap: int = s.gap
	var lines: Array = ["X ~ N(%d, σ²) and Y ~ N(%d, σ²)" % [s.mu1, s.mu2]]
	var asked := "Find b such that P(X %s b) = P(Y %s %d)." % [s.rel_x, s.rel_y, s.c]
	var ymean := "Y's mean"
	var xmean := "X's mean"
	if rep == "words":
		var side_x := "above" if s.rel_x == ">" else "below"
		var side_y := "above" if s.rel_y == ">" else "below"
		lines = ["In two groups of %s, A and B, the %s are normally distributed with the same standard deviation." % [c.items, words_of(s).attrs],
			"The mean is %d%s in group A and %d%s in group B." % [s.mu1, c.unit, s.mu2, c.unit]]
		asked = "The share of group A with a %s %s b%s equals the share of group B with a %s %s %d%s. Find b." % [c.attr, side_x, c.unit, c.attr, side_y, s.c, c.unit]
		ymean = "group B's mean"
		xmean = "group A's mean"
	var out := {"lines": lines, "asked": asked, "answer": ans, "table": null}
	out.wrongs = [wq(s.wrong_side, IN_SIDE), wq(s.c, IN_KEEP), wq(s.wrong_gap, IN_GAP_WAY)]
	out.generic = [{"v": Q.new(s.x + 1)}, {"v": Q.new(s.x + 2)}, {"v": Q.new(s.x + 5)}]
	var far := absi(gap)
	var y_name := "group B" if rep == "words" else "Y"
	var x_name := "group A" if rep == "words" else "X"
	var match_z := "The same z" if s.same else "The opposite z"
	var why := "the areas are on the same side" if s.same else "the areas are on opposite sides"
	var sum := "b = %d %s %d = %d" % [s.mu1, "+" if d > 0 else "−", absi(d), s.x]
	out.methods = {"via-z": method(["For %s, z = (%d − %d) ÷ σ = %s%d ÷ σ." % [y_name, s.c, s.mu2, "−" if gap < 0 else "", far],
			"%s fits %s, as %s: (b − %d) ÷ σ = %s%d ÷ σ." % [match_z, x_name, why, s.mu1, "−" if d < 0 else "", far],
			"σ cancels, so %s" % sum, final_step(ans)], ans.values),
		"sketch-tail": method(["Sketch both curves: the same shape, with %s %d and %s %d." % [xmean, s.mu1, ymean, s.mu2],
			"%d is %d %s %s, and the shaded tails must match, so b is %d %s %s." % [s.c, far, above_below(gap), ymean, far, above_below(d), xmean],
			sum, final_step(ans)], ans.values)}
	return out


func u_mirror_bound(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := scene(s)
	var ans := exact_val("a = ", s.x)
	var gap: int = s.gap
	var far := absi(gap)
	var other := ">" if s.rel == "<" else "<"
	var lines: Array = ["X ~ N(%s, σ²)" % D(s.mu), "P(X %s a) = P(X %s %d)" % [s.rel, other, s.c]]
	if rep == "words":
		var word_a := "below" if s.rel == "<" else "above"
		var word_c := "above" if s.rel == "<" else "below"
		lines = ["%s are normally distributed with mean %s%s." % [c.what, D(s.mu), c.unit],
			"As many of the %s have a %s %s a%s as have one %s %d%s." % [c.items, c.attr, word_a, c.unit, word_c, s.c, c.unit]]
	var out := {"lines": lines, "asked": "Find a.", "answer": ans, "table": null}
	if rep == "diagram":
		lines[1] = "The two shaded areas are equal."
		var cf := float(s.c)
		var xf := float(s.x)
		var shade: Array = [[null, xf], [cf, null]] if gap > 0 else [[null, cf], [xf, null]]
		out.graph = curve(s.muf, s.sgf, shade, [mk(xf, "a"), mk(s.muf, D(s.mu)), mk(cf, str(s.c))])
	out.wrongs = [wq(s.wrong_side, IN_PAST), wq(s.c, IN_KEEP), wq(far, IN_DISTANCE)]
	out.generic = [{"v": Q.new(s.x + 1)}, {"v": Q.new(s.x + 2)}, {"v": Q.new(s.x + 5)}]
	var sum := "a = %s %s %d = %d" % [D(s.mu), "−" if gap > 0 else "+", far, s.x]
	var top := "Sketch the curve and shade the two equal tails: they sit the same distance either side of the mean %s." % D(s.mu)
	if rep == "diagram":
		top = "On the curve, the two equal tails sit the same distance either side of the mean %s." % D(s.mu)
	out.methods = {"via-z": method(["z for %d is (%d − %s) ÷ σ = %s%d ÷ σ." % [s.c, s.c, D(s.mu), "−" if gap < 0 else "", far],
			"The other tail has the opposite z, so (a − %s) ÷ σ = %s%d ÷ σ." % [D(s.mu), "−" if gap > 0 else "", far],
			"σ cancels, so %s" % sum, final_step(ans)], ans.values),
		"sketch-tail": method([top, "%d is %d %s the mean, so a is %d %s it." % [s.c, far, above_below(gap), far, above_below(-gap)], sum, final_step(ans)], ans.values)}
	return out


func u_rule_value(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c := scene(s)
	var ans := exact_val("a = ", s.x)
	var lines: Array = [opening(rep if rep == "words" else "equation", s), "P(X %s a) = %s" % [s.rel, D(s.p)]]
	if rep == "words":
		lines[1] = "%s%% of the %s have a %s %s a%s." % [pct(s.p), c.items, c.attr, "below" if s.rel == "<" else "above", c.unit]
	var out := {"lines": lines, "asked": "Use the 68-95-99.7 rule to find a.", "answer": ans, "table": null}
	var xf: float = s.x.to_float()
	if rep == "diagram":
		lines[1] = area_line(s.p)
		out.graph = curve(s.muf, s.sgf, [[null, xf]] if s.rel == "<" else [[xf, null]], [mk(xf, "a"), mk(s.muf, D(s.mu))])
	out.wrongs = [wq(s.flip, IN_SIDE), wq(s.other_k, IN_RULE_K), wq(s.no_sd, IN_NO_SD)]
	out.generic = [{"v": s.x.add(Q.new(1))}, {"v": s.x.add(Q.new(2))}, {"v": s.x.add(Q.new(5))}]
	var band: Array = IN_BAND[s.k]
	var inside := Q.new(band[0], band[1])
	var left := Q.new(1).sub(inside)
	var tail: Q = left.div(Q.new(2))
	var rule := "The rule puts %s within %d standard deviation%s of the mean, which leaves %s in the two tails, and %s ÷ 2 = %s in each." % [D(inside), s.k, "" if s.k == 1 else "s", D(left), D(left), D(tail)]
	var whole := "P(X %s a) = %s leaves a tail of 1 − %s = %s on the other side of a." % [s.rel, D(s.p), D(s.p), D(s.tail)]
	var side: int = s.side
	var word := above_below(side)
	var sum := "a = %s %s %d × %s = %s" % [D(s.mu), "+" if side > 0 else "−", s.k, D(s.sg), D(s.x)]
	var top := "Sketch the curve with the mean %s in the middle, and shade %s %s a." % [D(s.mu), D(s.p), "below" if s.rel == "<" else "above"]
	if rep == "diagram":
		top = "On the curve, the shaded area %s lies %s a." % [D(s.p), "below" if s.rel == "<" else "above"]
	var z_steps: Array = [rule] + ([] if s.tailed else [whole]) + ["So z = %s%d, as a is %s the mean." % ["−" if side < 0 else "", s.k, word], sum, final_step(ans)]
	var more := "more than" if not s.tailed else "less than"
	out.methods = {"via-z": method(z_steps, ans.values),
		"sketch-tail": method([top, "That area is %s a half, so a is %s the mean." % [more, word], rule + " So a is %d standard deviation%s %s the mean." % [s.k, "" if s.k == 1 else "s", word], sum, final_step(ans)], ans.values)}
	return out


func u_given_z(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := exact_val("a = ", s.x)
	var zt := D(s.z0)
	var fact := "Z ~ N(0, 1) and P(Z < %s) = %s" % [zt, D(s.table)]
	var lines: Array = [opening("equation", s), fact, "P(X %s a) = %s" % [s.rel, D(s.p)]]
	var out := {"lines": lines, "asked": "Find a.", "answer": ans, "table": null}
	var xf: float = s.x.to_float()
	if rep == "diagram":
		lines[2] = area_line(s.p)
		out.graph = curve(s.muf, s.sgf, [[null, xf]] if s.rel == "<" else [[xf, null]], [mk(xf, "a"), mk(s.muf, D(s.mu))])
	out.wrongs = [wq(s.flip, IN_SIDE), wq(s.no_sd, IN_NO_SD), wq(s.z0, IN_Z_OR_P), wq(s.table, IN_Z_OR_P)]
	out.generic = [{"v": s.x.add(Q.new(1))}, {"v": s.x.add(Q.new(2))}, {"v": s.x.add(Q.new(5))}]
	var up: bool = s.up
	var why: String
	if s.rel == "<" and s.tailed:
		why = "P(X < a) = %s is the area in the line given, so z = %s." % [D(s.p), zt]
	elif s.tailed:
		why = "By symmetry P(Z > −%s) = %s, so z = −%s." % [zt, D(s.p), zt]
	elif s.rel == "<":
		why = "By symmetry P(Z < −%s) = 1 − %s = %s, so z = −%s." % [zt, D(s.table), D(s.p), zt]
	else:
		why = "P(Z > %s) = 1 − %s = %s, so z = %s." % [zt, D(s.table), D(s.p), zt]
	var sum := "a = %s %s %s × %s = %s" % [D(s.mu), "+" if up else "−", zt, D(s.sg), D(s.x)]
	var top := "Sketch the curve with the mean %s in the middle, and shade %s %s a." % [D(s.mu), D(s.p), "below" if s.rel == "<" else "above"]
	if rep == "diagram":
		top = "On the curve, the shaded area %s lies %s a." % [D(s.p), "below" if s.rel == "<" else "above"]
	var more := "more than" if (s.p.to_float() > 0.5) else "less than"
	out.methods = {"via-z": method([why, "a = μ + zσ, so %s" % sum, final_step(ans)], ans.values),
		"sketch-tail": method([top, "That area is %s a half, so a is %s the mean, and the line given puts it %s standard deviations away." % [more, "above" if up else "below", zt], sum, final_step(ans)], ans.values)}
	return out
