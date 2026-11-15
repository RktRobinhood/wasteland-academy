class_name RateOfRateViews
extends ExtensionViews
## The views on the `rate-of-rate` situation: one builder per unknown of
## t5-ext-interpret-second-derivative (FAL-777). Every answer is a pick of four: a sentence about
## the quantity, or a pair of signs. The slips read the sign of f″ as the direction, swap what f′
## and f″ say, read "rising at a decreasing rate" as falling, or take f″ < 0 as "slowing down"
## for a quantity that falls.
##
## Representations: "equation" (the signs, or a cubic model), "words" (a sentence) and "graph"
## (the quantity against time, with one moment marked).

const SK := "SL5.7.interpret-second-derivative#"
const R_F2_DIRECTION := SK + "0"
const R_RATE_FALLING := SK + "1"
const T := "t5-ext-interpret-second-derivative#"
const R_SWAP := T + "2"
const R_SLOWING := T + "3"
const UNKNOWNS := ["sentence-from-signs", "signs-from-sentence", "from-graph", "from-model"]
const RR := preload("res://engine/situations/rate_of_rate.gd")


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = ["true-false-reason"]
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [1] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = RR.export(s)
	out.fn_name = story(s).q
	return out


static func story(s: Dictionary) -> Dictionary:
	return RR.STORIES[s.story]


static func pick(right: String, tagged: Array, fillers: Array = []) -> Dictionary:
	var out := InverseRuleViews.choose(right, tagged, fillers)
	out.fillers = out.get("fillers", []) + out.get("generic", [])
	out.erase("generic")
	return out


static func tag(text: String, ref: String) -> Dictionary:
	return InverseRuleViews.tag(text, ref)


static func way(st: Dictionary, s1: int) -> String:
	return st.up if s1 > 0 else st.down


## The sentence for a direction and a change of speed: the speed grows when the signs agree.
static func sentence(st: Dictionary, s1: int, faster: bool) -> String:
	if faster:
		return "The %s is %s more and more quickly." % [st.name, way(st, s1)]
	return "The %s is %s, but more and more slowly." % [st.name, way(st, s1)]


static func right_sentence(s: Dictionary) -> String:
	return sentence(story(s), s.s1, s.s1 * s.s2 > 0)


## The wrong sentences: f″'s sign as the direction (bare), f′ and f″ swapped, and f″ < 0 read
## as slowing down for a quantity that falls. The rest of the four sentences are fillers.
static func sentence_options(s: Dictionary) -> Dictionary:
	var st := story(s)
	var right := right_sentence(s)
	var tagged: Array = []
	if s.s1 != s.s2:
		tagged.append(tag("The %s is %s." % [st.name, way(st, s.s2)], R_F2_DIRECTION))
		tagged.append(tag(sentence(st, s.s2, s.s1 * s.s2 > 0), R_SWAP))
	if s.s1 < 0:
		tagged.append(tag(sentence(st, s.s1, s.s2 > 0), R_SLOWING))
	var fillers: Array = []
	for d in [1, -1]:
		for f in [true, false]:
			fillers.append(sentence(st, d, f))
	fillers.append("The %s is not changing." % st.name)
	return pick(right, tagged, fillers)


static func cmp(sg: int) -> String:
	return "> 0" if sg > 0 else "< 0"


static func signs_text(q: String, s1: int, s2: int, at: String = "t") -> String:
	return "%s′(%s) %s and %s″(%s) %s" % [q, at, cmp(s1), q, at, cmp(s2)]


## What the sign of f″ says about the rate f′, in words.
static func rate_line(q: String, s1: int, s2: int, at: String = "t") -> String:
	var rate := "%s′(%s)" % [q, at]
	if s1 > 0:
		return "%s″(%s) %s, so the rate %s is positive and getting %s." % [q, at, cmp(s2), rate, "larger" if s2 > 0 else "smaller, towards 0"]
	return "%s″(%s) %s, so the rate %s is negative and %s." % [q, at, cmp(s2), rate, "going up towards 0" if s2 > 0 else "going down, further from 0"]


static func dir_line(st: Dictionary, s1: int, at: String = "t") -> String:
	return "%s′(%s) %s, so the %s is %s." % [st.q, at, cmp(s1), st.name, way(st, s1)]


## The short curve with that slope and bend, in words.
static func shape(s1: int, s2: int) -> String:
	var bend := "bending upwards (concave up)" if s2 > 0 else "bending downwards (concave down)"
	var flat := "gets steeper" if s1 * s2 > 0 else "flattens out"
	return "a curve going %s and %s: it %s" % ["up" if s1 > 0 else "down", bend, flat]


static func two_layer(s: Dictionary, right: String, at: String = "t") -> Dictionary:
	var st := story(s)
	return method([dir_line(st, s.s1, at), rate_line(st.q, s.s1, s.s2, at), right], {"v": right})


static func curve_shape(s: Dictionary, right: String) -> Dictionary:
	var st := story(s)
	return method(["Sketch a short piece of %s." % shape(s.s1, s.s2),
		"A curve that %s shows a quantity %s %s." % [shape(s.s1, s.s2).get_slice(": it ", 1), way(st, s.s1), "more and more quickly" if s.s1 * s.s2 > 0 else "more and more slowly"],
		right], {"v": right})


## The first letter in capitals ("More and more slowly"); capitalize() would do every word.
static func cap(text: String) -> String:
	return text.left(1).to_upper() + text.substr(1)


static func stretch(s: Dictionary) -> String:
	return "%d < t < %d" % [s.t1, s.t2]


func u_sentence_from_signs(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var st := story(s)
	var right := right_sentence(s)
	var out := {"lines": ["%s(t) is the %s, t hours after midnight." % [st.q, st.name], "For %s, %s." % [stretch(s), signs_text(st.q, s.s1, s.s2)]],
		"asked": "Which sentence describes the %s for %s?" % [st.name, stretch(s)]}
	out.merge(sentence_options(s))
	out.methods = {"two-layer-reading": two_layer(s, right), "curve-shape": curve_shape(s, right)}
	return out


func u_signs_from_sentence(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var st := story(s)
	var said: String = ("The %s is %s at a decreasing rate." % [st.name, st.up]) if s.rate_words else right_sentence(s)
	var right := signs_text(st.q, s.s1, s.s2)
	var tagged: Array = []
	if s.s1 > 0 and s.s2 < 0:
		tagged.append(tag(signs_text(st.q, -1, -1), R_RATE_FALLING))
	if s.s1 != s.s2:
		tagged.append(tag(signs_text(st.q, s.s2, s.s1), R_SWAP))
	if s.s1 < 0:
		tagged.append(tag(signs_text(st.q, -1, -s.s2), R_SLOWING))
	var fillers: Array = []
	for a in [1, -1]:
		for b in [1, -1]:
			fillers.append(signs_text(st.q, a, b))
	var out := {"lines": ["%s(t) is the %s, t hours after midnight. For %s:" % [st.q, st.name, stretch(s)], said],
		"asked": "Which is true for %s?" % stretch(s)}
	out.merge(pick(right, tagged, fillers))
	var speed := "more and more quickly" if s.s1 * s.s2 > 0 else "more and more slowly"
	out.methods = {
		"two-layer-reading": method(["%s: the %s goes %s, so %s′(t) %s." % [cap(way(st, s.s1)), st.name, "up" if s.s1 > 0 else "down", st.q, cmp(s.s1)],
			"%s: %s" % [cap(speed), rate_line(st.q, s.s1, s.s2).get_slice(", so ", 1).trim_suffix(".")] + (", so %s″(t) %s." % [st.q, cmp(s.s2)]), right + "."], {"v": right}),
		"curve-shape": method(["Sketch it: %s." % shape(s.s1, s.s2),
			"Going %s means %s′(t) %s; %s means %s″(t) %s." % ["up" if s.s1 > 0 else "down", st.q, cmp(s.s1), "bending upwards" if s.s2 > 0 else "bending downwards", st.q, cmp(s.s2)],
			right + "."], {"v": right}),
	}
	return out


func u_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var st := story(s)
	var c: Array = s.c
	var right := right_sentence(s)
	var f := func(x: float) -> float: return ((c[0] * x + c[1]) * x + c[2]) * x + c[3]
	var y0 := RR.value(c, s.t0).to_float()
	var curve := GdcKit.curve(f, 0.0, float(RR.END))
	var top := 0.0
	for p in curve:
		top = maxf(top, p[1])
	var g := Plot.spec([curve], [[float(s.t0), y0, "t = %d" % s.t0]], 0, RR.END, 0, Plot.nice_top(top))
	g.x_name = "t"
	g.y_name = st.q
	var at := str(s.t0)
	var out := {"graph": g, "lines": ["The graph shows %s(t), the %s, t hours after midnight. The point where t = %d is marked." % [st.q, st.name, s.t0]],
		"asked": "Which sentence describes the %s at t = %d?" % [st.name, s.t0]}
	out.merge(sentence_options(s))
	out.methods = {
		"two-layer-reading": method(["At t = %d the graph goes %s, so %s′(%s) %s." % [s.t0, "up" if s.s1 > 0 else "down", st.q, at, cmp(s.s1)],
			"It bends %s there, so %s″(%s) %s: %s" % ["upwards" if s.s2 > 0 else "downwards", st.q, at, cmp(s.s2), rate_line(st.q, s.s1, s.s2, at).get_slice(", so ", 1)],
			right], {"v": right}),
		"curve-shape": method(["Near t = %d the graph is %s." % [s.t0, shape(s.s1, s.s2)],
			"A curve that %s shows a quantity %s %s." % [shape(s.s1, s.s2).get_slice(": it ", 1), way(st, s.s1), "more and more quickly" if s.s1 * s.s2 > 0 else "more and more slowly"],
			right], {"v": right}),
	}
	return out


func u_from_model(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var st := story(s)
	var c: Array = s.c
	var right := right_sentence(s)
	var t0: int = s.t0
	var v1 := RR.d1(c, t0)
	var v2 := RR.d2(c, t0)
	var at := str(t0)
	var out := {"lines": ["The %s t hours after midnight is modelled by %s(t) = %s, for 0 ≤ t ≤ %d." % [st.name, st.q, Fmt.poly(c, "t"), RR.END]],
		"asked": "Use %s′(%d) and %s″(%d) to describe the %s at t = %d." % [st.q, t0, st.q, t0, st.name, t0]}
	out.merge(sentence_options(s))
	out.methods = {"two-layer-reading": method([
		"%s′(t) = %s, so %s′(%d) = %s %s." % [st.q, Fmt.poly([3 * c[0], 2 * c[1], c[2]], "t"), st.q, t0, N(v1), cmp(s.s1)],
		"%s″(t) = %s, so %s″(%d) = %s %s." % [st.q, Fmt.poly([6 * c[0], 2 * c[1]], "t"), st.q, t0, N(v2), cmp(s.s2)],
		"%s′(%s) %s says the %s is %s; %s" % [st.q, at, cmp(s.s1), st.name, way(st, s.s1), rate_line(st.q, s.s1, s.s2, at).get_slice(", so ", 1)],
		right], {"v": right})}
	return out
