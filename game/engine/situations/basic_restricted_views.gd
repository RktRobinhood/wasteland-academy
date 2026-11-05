class_name BasicRestrictedViews
extends ExtensionViews
## The views on the `basic-restricted` situation (FAL-424): one builder per unknown of
## fn-domain-range. The catalogue plays these as multiple choice: every answer is an
## interval or inequality picked from four written options (the `choice` kind), and the
## wrong ones are the type's misconceptions, with a rounding trap on Paper 2. The checker
## works each interval out again and reads every option as text.

const R_TURN := "SL2.2.range#0"
const R_ASYMPTOTE := "SL2.2.range#1"
const R_IN_X := "SL2.2.range#2"
const R_OPEN_END := "SL2.2.domain#0"
const R_NO_SHIFT := "SL2.2.domain#1"
const R_RANGE_ASKED := "SL2.2.domain#2"
const R_SAME_DOMAIN := "SL2.5.inverse-domain-range#0"
const R_Y_AXIS := "SL2.5.inverse-domain-range#1"


func needs() -> Dictionary:
	return {
		"range-quadratic": {"kind": "any-quad"},
		"range-rational": {"kind": "rat"},
		"range-reflected": {"kind": "arc"},
		"composite-condition": {"kind": "compose"},
		"range-restricted": {"kind": "arc"},
		"range-exponential": {"kind": "exp"},
		"range-from-graph": {"kind": "piece"},
		"domain-root": {"kind": "root"},
		"domain-log-or-fraction": {"kind": "logfrac"},
		"domain-from-graph": {"kind": "piece"},
		"domain-from-range": {"kind": "line"},
		"inverse-domain": {"kind": "inverse"},
		"restrict-for-inverse": {"kind": "split"},
	}


## With no graph on the card, the student draws the one these methods read.
const SKETCH_TITLES := {"graph-height": "Sketch f and read its vertical extent", "graph-extent": "Sketch f and read its horizontal extent"}

## A graph is read from grid points, whatever the paper.
func need(unknown: String, rep: String) -> Dictionary:
	var n := super.need(unknown, rep)
	if rep != "equation":
		n.grid = true
	return n


## Paper 2 where decimals change the sums; a calculator's method is Paper 2. The rest
## have whole ends on either paper, so the ratio of the exam's parts still holds.
func papers(_unknown: String, _rep: String, method_id: String) -> Array:
	return [2] if method_id.begins_with("gdc-") else [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = BasicRestrictedSituation.export(s)
	return out


# ── Helpers ──────────────────────────────────────────────────

static func N(v: Variant) -> String:
	return Fmt.num(v)


## A value as an option writes it: exact, or to 3 s.f. where it needs rounding.
static func say(v: Variant) -> String:
	return Fmt.sf(v) if Answer.needs_rounding(Q.of(v)) and Q.of(v).d > 12 else Fmt.dec(v) if Q.of(v).d % 3 != 0 else Fmt.num(v)


## lo ≤ y ≤ hi, each end left out when it is open.
static func iv(letter: String, lo: Variant, hi: Variant, lo_open: bool = false, hi_open: bool = false) -> String:
	return "%s %s %s %s %s" % [say(lo), "<" if lo_open else "≤", letter, "<" if hi_open else "≤", say(hi)]


## An option's text with its numbers at 2 s.f.: the rounding trap.
static func trap_of(out: Dictionary, text2: String, needed: bool) -> void:
	if needed:
		out.wrongs.push_front({"values": {"v": text2}, "ref": "", "trap": true})


static func s2(v: Variant) -> String:
	if not Answer.needs_rounding(Q.of(v)):
		return say(v)
	return Fmt.dec(Answer.parse_number(Fmt.sf(v, 2).replace("−", "-")).q)


static func rounds(v: Variant) -> bool:
	return Answer.needs_rounding(Q.of(v)) and Q.of(v).d > 12


static func eqn(s: Dictionary) -> String:
	return BasicFunctionSituation.eqn(s)


static func on(s: Dictionary) -> String:
	return "%s, for %s" % [eqn(s), iv("x", s.lo, s.hi)]


static func ways(steps: Dictionary, right: String, ans: Dictionary) -> Dictionary:
	return BasicFunctionViews.ways(steps, "So %s." % right, ans)


static func choose(right: String, bad: Array, plain: Array) -> Dictionary:
	return BasicFunctionViews.choose(right, bad, plain)


static func tag(text: String, ref: String) -> Dictionary:
	return BasicFunctionViews.tag(text, ref)


## The arc of f on its domain, with the ends and any turning point as filled dots.
static func arc_graph(s: Dictionary) -> Dictionary:
	var lo: float = s.lo.to_float()
	var hi: float = s.hi.to_float()
	var pts := Plot.sample(func(x): return BasicFunctionSituation.fl(s.f, x), lo, hi)
	var ys: Array = pts.map(func(p): return p[1])
	var win := GdcKit.window(lo, hi, minf(ys.min(), 0.0), maxf(ys.max(), 0.0))
	var g := Plot.spec([pts], [[lo, s.fa.to_float(), ""], [hi, s.fb.to_float(), ""], [s.h.to_float(), s.k.to_float(), ""]], win[0], win[1], win[2], win[3])
	for d in g.points:
		d.filled = true
	g.one_colour = true
	return g


## A piece of f with open or filled dots at its ends.
static func piece_graph(s: Dictionary) -> Dictionary:
	var lo: float = s.lo.to_float()
	var hi: float = s.hi.to_float()
	var pts := Plot.sample(func(x): return BasicFunctionSituation.fl(s.f, x), lo, hi)
	var ys: Array = pts.map(func(p): return p[1])
	var win := GdcKit.window(lo, hi, minf(ys.min(), 0.0), maxf(ys.max(), 0.0))
	var g := Plot.spec([pts], s.dots.map(func(d): return [d[0], d[1], ""]), win[0], win[1], win[2], win[3])
	for i in g.points.size():
		g.points[i].filled = not s.dots[i][2]
		g.points[i].open = s.dots[i][2]
	g.one_colour = true
	return g


## The whole curve of a rule, in a window round the points that matter.
static func curve_graph(s: Dictionary, lo: float, hi: float) -> Dictionary:
	return BasicFunctionViews.graph_of(s, lo, hi)


# ── range from a turning point or an asymptote ───────────────

func u_range_quadratic(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var up: bool = s.a.sign() > 0
	var rel := "≥" if up else "≤"
	var other := "≤" if up else "≥"
	var k: Q = s.k
	var right := "y %s %s" % [rel, say(k)]
	var out := {"asked": "State the range of f."}
	out.merge(choose(right, [tag("x %s %s" % [rel, say(k)], R_IN_X)], ["y %s %s" % [other, say(k)], "y %s %s" % [rel, say(s.h)] if not s.h.eq(k) else "y > %s" % say(k), "y %s %s" % [rel, say(s.f.co[0])], "all real numbers"]))
	trap_of(out, "y %s %s" % [rel, s2(k)], rounds(k))
	match rep:
		"graph":
			out.lines = ["The graph of the parabola y = f(x) is shown."]
			out.graph = curve_graph(s, s.h.to_float() - 4.0, s.h.to_float() + 4.0)
		"words":
			out.lines = ["f is a parabola with vertex %s, opening %s." % [Fmt.point(s.h, k), "upwards" if up else "downwards"]]
		_:
			out.lines = [eqn(s)]
	var turn := "The vertex is at x = %s, with height %s" % [BasicFunctionViews.W(s.h), BasicFunctionViews.W(k)]
	var opens := "The parabola opens %s, so %s is its %s value" % ["up" if up else "down", BasicFunctionViews.W(k), "least" if up else "greatest"]
	out.methods = ways({"vertex-or-asymptote": [turn, opens], "gdc-max-min": ["Graph y = f(x) and use the %s tool: %s" % ["minimum" if up else "maximum", BasicFunctionViews.W(k)], opens]}, right, out.answer)
	return out


func u_range_rational(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var big: Q = s.A
	var right := "y ≠ %s" % say(big)
	var out := {"asked": "State the range of f."}
	var hv: Q = s.hv
	out.merge(choose(right, [tag("all real numbers", R_ASYMPTOTE)], ["y ≠ %s" % say(hv) if not hv.eq(big) else "y ≠ 0", "x ≠ %s" % say(big), "y > %s" % say(big), "y ≠ 0"]))
	trap_of(out, "y ≠ %s" % s2(big), rounds(big))
	if rep == "graph":
		out.lines = ["The graph of y = f(x) is shown, with its asymptotes dashed."]
		var t := RationalCards.triple(s.f.a.to_float(), s.f.b.to_float(), s.f.c.to_float(), s.f.d.to_float())
		out.graph = RationalCards.plot(t)
		out.given = {"rat": true}
		var read := "The dashed horizontal line is y = %s" % say(big)
		out.methods = ways({"vertex-or-asymptote": [read, "The curve gets close to that line but never meets it, so %s is left out" % say(big)]}, right, out.answer)
		return out
	out.lines = [eqn(s)]
	var ratio := "For large x, f(x) gets close to the ratio of the x terms: %s" % say(big)
	out.methods = ways({"vertex-or-asymptote": [ratio, "So y = %s is the horizontal asymptote" % say(big), "f(x) never equals %s, and it takes every other value" % say(big)]}, right, out.answer)
	return out


func u_range_exponential(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Q = s.c
	var rel := ">" if s.up else "<"
	var right := "y %s %s" % [rel, N(c)]
	var out := {"asked": "State the range of f."}
	out.merge(choose(right, [tag("y %s %s" % ["≥" if s.up else "≤", N(c)], R_ASYMPTOTE)], ["y %s 0" % rel, "y %s %s" % [rel, N(s.y_int)], "all real numbers", "x %s %s" % [rel, N(c)]]))
	var why := "A power of a positive number is always positive, so the first term is never 0"
	var hit := "That leaves the value %s out: y = %s is the asymptote" % [N(c), N(c)]
	if rep == "graph":
		out.lines = ["The graph of y = f(x) is shown, with its asymptote dashed."]
		var g := BasicFunctionViews.graph_of(s, -4.0, 2.0, [], [[c.to_float(), ""]])
		out.graph = g
		var read := "The curve stays on one side of the dashed line y = %s" % N(c)
		out.methods = ways({"graph-height": [read, hit], "vertex-or-asymptote": [read, why, hit]}, right, out.answer)
		return out
	out.lines = [eqn(s)]
	out.titles = SKETCH_TITLES
	out.methods = ways({"graph-height": ["Sketch it: the curve flattens out towards y = %s" % N(c), hit], "vertex-or-asymptote": [why, hit]}, right, out.answer)
	return out


# ── range on a domain ────────────────────────────────────────

func u_range_restricted(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := iv("y", s.ymin, s.ymax)
	var near: Q = s.fa if s.fa.to_float() < s.fb.to_float() else s.fb
	var far: Q = s.fb if s.fa.to_float() < s.fb.to_float() else s.fa
	var out := {"asked": "State the range of f."}
	out.merge(choose(right, [tag(iv("y", near, far), R_TURN)], [iv("x", s.ymin, s.ymax), "y %s %s" % ["≥" if s.a.sign() > 0 else "≤", say(s.k)], iv("y", s.lo, s.hi), iv("y", s.fa, s.ymax if s.a.sign() < 0 else s.fb)]))
	var keep := rounds(s.ymin) or rounds(s.ymax)
	trap_of(out, "%s ≤ y ≤ %s" % [s2(s.ymin), s2(s.ymax)], keep)
	if rep == "graph":
		out.lines = ["The graph of f on its domain is shown."]
		out.graph = arc_graph(s)
	else:
		out.lines = [on(s)]
		out.titles = SKETCH_TITLES
	var W := BasicFunctionViews.W
	var ends := "End values: f(%s) = %s and f(%s) = %s" % [N(s.lo), W.call(s.fa), N(s.hi), W.call(s.fb)]
	var turn := "The vertex at x = %s is inside the domain, so its height %s counts too" % [W.call(s.h), W.call(s.k)]
	var pick := "The least of these is %s and the greatest is %s" % [W.call(s.ymin), W.call(s.ymax)]
	var look := "Look for the lowest and highest points of the curve on the domain" if rep == "graph" else "Sketch f on its domain and look for its lowest and highest points"
	out.methods = ways({"graph-height": [look, turn, ends, pick], "endpoint-evaluation": [ends, turn, pick],
		"gdc-max-min": ["Graph f on its domain and use the turning point tool", turn, ends, pick]}, right, out.answer)
	return out


func u_range_reflected(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var lo: Q = s.ymax.neg()
	var hi: Q = s.ymin.neg()
	var right := iv("y", lo, hi)
	var out := {"asked": "g(x) = −f(x). State the range of g."}
	out.merge(choose(right, [], [iv("y", s.ymin, s.ymax), "%s ≤ y ≤ %s" % [say(hi), say(lo)], iv("y", hi, s.ymax), iv("y", lo, s.ymin), "y ≤ %s" % say(hi)]))
	trap_of(out, "%s ≤ y ≤ %s" % [s2(lo), s2(hi)], rounds(lo) or rounds(hi))
	if rep == "graph":
		out.lines = ["The graph of f on its domain is shown."]
		out.graph = arc_graph(s)
	else:
		out.lines = [on(s)]
		out.titles = SKETCH_TITLES
	var W := BasicFunctionViews.W
	var f_range := "The range of f is %s" % iv("y", s.ymin, s.ymax)
	var flip := "Every output changes sign, so the greatest of f becomes the least of g: %s to %s" % [W.call(lo), W.call(hi)]
	var ends := "End values: f(%s) = %s and f(%s) = %s, and the vertex has height %s" % [N(s.lo), W.call(s.fa), N(s.hi), W.call(s.fb), W.call(s.k)]
	var look := "Reflecting in the x-axis turns the heights upside down" if rep == "graph" else "Sketch f on its domain: reflecting it in the x-axis turns the heights upside down"
	out.methods = ways({"graph-height": [look, f_range, flip], "endpoint-evaluation": [ends, f_range, flip]}, right, out.answer)
	return out


func u_composite_condition(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var m: Q = s.m
	var strict: bool = s.of == "quad" and s.form == "ln"
	var rel := "<" if strict else "≤"
	var right := "c %s %s" % [rel, say(m)]
	var other := "≤" if strict else "<"
	var g: String = "g(x) = √(x − c)" if s.form == "root" else "g(x) = ln(x − c)"
	var out := {"asked": "For which values of c is g(f(x)) defined for every real x?", "lines": [eqn(s), g]}
	out.merge(choose(right, [], ["c %s %s" % [other, say(m)], "c ≥ %s" % say(m), "c > %s" % say(m), "c ≤ 0"]))
	trap_of(out, "c %s %s" % [rel, s2(m)], rounds(m))
	var need_txt: String = "x − c ≥ 0, so x ≥ c" if s.form == "root" else "x − c > 0, so x > c"
	var range_txt: String = "y ≥ %s, from the vertex" % say(m) if s.of == "quad" else "y > %s, from the asymptote" % say(m)
	var fit: String = "Every output of f must fit: %s %s c holds when c %s %s" % [say(m), "≥" if s.form == "root" and s.of == "quad" else ">" if strict else "≥", rel, say(m)]
	if s.of == "exp":
		fit = "The outputs of f are all above %s, so they all fit when c ≤ %s, even at c = %s" % [say(m), say(m), say(m)]
	var dom := "g needs %s" % need_txt
	var rng_of := "The range of f is %s" % range_txt
	out.methods = ways({"vertex-or-asymptote": [rng_of, dom, fit], "restriction-rules": [dom, rng_of, fit]}, right, out.answer)
	return out


# ── domains ──────────────────────────────────────────────────

func u_domain_root(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Q = s.c
	var rel := "≤" if s.left else "≥"
	var strict := "<" if s.left else ">"
	var right := "x %s %s" % [rel, N(c)]
	var inside := "The number under the root must not be negative: %s ≥ 0" % Fmt.terms([s.f.m, s.f.n], [1, 0], "x", true)
	var out := {"asked": "State the largest possible domain of f.", "lines": [eqn(s)], "titles": SKETCH_TITLES}
	out.merge(choose(right, [tag("x %s %s" % [strict, N(c)], R_OPEN_END), tag("x %s 0" % rel, R_NO_SHIFT)], ["x %s %s" % [rel, N(c.neg())], "x %s %s" % ["≥" if s.left else "≤", N(c)], "all real numbers"]))
	out.methods = ways({"restriction-rules": [inside, "Solve it: x %s %s, and 0 under the root is allowed" % [rel, N(c)]], "graph-extent": ["Sketch f: the graph starts at x = %s, where the root is 0" % N(c), "It runs off to the %s from there, with that end included" % ("left" if s.left else "right")]}, right, out.answer)
	return out


func u_domain_log_or_fraction(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var c: Q = s.c
	var out := {"asked": "State the largest possible domain of f.", "lines": [eqn(s)]}
	var right: String
	if s.form == "log":
		right = "x > %s" % N(c)
		out.merge(choose(right, [], ["x ≥ %s" % N(c), "x > 0", "x > %s" % N(c.neg()), "x ≠ %s" % N(c)]))
		out.methods = ways({"restriction-rules": ["ln needs a positive input: %s > 0" % Fmt.terms([s.f.m, s.f.n], [1, 0], "x", true), "Solve it, and leave the end out: ln 0 is not defined"]}, right, out.answer)
	else:
		right = "x ≠ %s" % N(c)
		out.merge(choose(right, [], ["x ≠ 0", "x ≠ %s" % N(c.neg()), "x > %s" % N(c), "all real numbers"]))
		out.methods = ways({"restriction-rules": ["A fraction needs a bottom that is not 0: %s ≠ 0" % Fmt.terms([s.f.c, s.f.d], [1, 0], "x", true), "That rules out one value, and only that one"]}, right, out.answer)
	return out


func u_domain_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := iv("x", s.lo, s.hi, s.lo_open, s.hi_open)
	var out := {"asked": "State the domain of f.", "lines": ["The graph of f is shown. A filled dot is part of the graph; an open dot is not."], "graph": piece_graph(s)}
	out.merge(choose(right, [tag(iv("y", s.ylo, s.yhi, s.ylo_open, s.yhi_open), R_RANGE_ASKED)], [iv("x", s.lo, s.hi, not s.lo_open, s.hi_open), iv("x", s.lo, s.hi, s.lo_open, not s.hi_open), iv("x", s.ylo, s.yhi, s.ylo_open, s.yhi_open)]))
	out.methods = ways({"graph-extent": ["The domain is how far the graph runs from side to side", "Left end x = %s (%s), right end x = %s (%s)" % [N(s.lo), "open" if s.lo_open else "filled", N(s.hi), "open" if s.hi_open else "filled"]]}, right, out.answer)
	return out


func u_range_from_graph(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := iv("y", s.ylo, s.yhi, s.ylo_open, s.yhi_open)
	var out := {"asked": "State the range of f.", "lines": ["The graph of f is shown. A filled dot is part of the graph; an open dot is not."], "graph": piece_graph(s)}
	out.merge(choose(right, [], [iv("y", s.ylo, s.yhi, not s.ylo_open, s.yhi_open), iv("y", s.ylo, s.yhi, s.ylo_open, not s.yhi_open), iv("y", s.lo, s.hi, s.lo_open, s.hi_open), iv("x", s.ylo, s.yhi, s.ylo_open, s.yhi_open)]))
	out.methods = ways({"graph-height": ["The range is how far the graph runs from bottom to top", "Lowest y = %s (%s), highest y = %s (%s)" % [N(s.ylo), "left out" if s.ylo_open else "included", N(s.yhi), "left out" if s.yhi_open else "included"]]}, right, out.answer)
	return out


func u_domain_from_range(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right := iv("x", s.lo, s.hi)
	var c: Q = s.c
	var out := {"asked": "Find the domain of f."}
	var range_txt := iv("y", s.p, s.q)
	if rep == "words":
		out.lines = ["f is a straight line with gradient %s and y-intercept %s. Its domain is an interval, and its range is %s." % [N(s.m), N(c), range_txt]]
	else:
		out.lines = [eqn(s), "The range of f on its domain is %s." % range_txt]
	out.merge(choose(right, [], [iv("x", s.p, s.q), iv("x", s.lo.add(1), s.hi), iv("x", s.lo, s.hi.add(1)), iv("x", s.p.sub(c), s.q.sub(c)), iv("x", s.lo.sub(1), s.hi)]))
	out.methods = ways({"endpoint-evaluation": ["Solve f(x) = %s: %s = %s gives x = %s" % [N(s.p), BasicFunctionSituation.text(s.f), N(s.p), N(s.p.sub(c).div(s.m))],
		"Solve f(x) = %s: %s = %s gives x = %s" % [N(s.q), BasicFunctionSituation.text(s.f), N(s.q), N(s.q.sub(c).div(s.m))], "The smaller x is the lower end of the domain"]}, right, out.answer)
	return out


func u_inverse_domain(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var dom_f := _span("x", s.d1, s.d2)
	var ran_f := _span("y", s.r1, s.r2)
	var dom_inv := _span("x", s.r1, s.r2)
	var ran_inv := _span("y", s.d1, s.d2)
	var right := "domain %s, range %s" % [dom_inv, ran_inv]
	var out := {"asked": "State the domain and the range of f⁻¹."}
	out.merge(choose(right, [tag("domain %s, range %s" % [dom_f, ran_f], R_SAME_DOMAIN)], ["domain %s, range %s" % [dom_f, ran_inv], "domain %s, range %s" % [dom_inv, ran_f], "domain all real numbers, range %s" % ran_inv,
		"domain %s, range %s" % [_span("x", s.r1.add(1), s.r2.add(1) if s.r2 != null else null), ran_inv], "domain %s, range %s" % [dom_inv, _span("y", s.d1.add(1), s.d2.add(1) if s.d2 != null else null)]]))
	var dom_text := "for %s" % dom_f
	if rep == "graph":
		out.lines = ["The graph of f, one-to-one on its domain, is shown (%s)." % dom_text]
		var hi: float = s.d2.to_float() if s.d2 != null else s.d1.to_float() + 6.0
		var pts: Array = [[s.d1.to_float(), BasicFunctionSituation.at(s.f, s.d1).to_float(), ""]]
		out.graph = BasicFunctionViews.graph_of(s, s.d1.to_float(), hi, pts)
	else:
		out.lines = ["%s, %s" % [eqn(s), dom_text]]
	var swap := "f⁻¹ swaps inputs and outputs: its domain is the range of f, and its range is the domain of f"
	var ran := "The range of f is %s" % ran_f
	out.methods = ways({"swap-domain-range": [ran, swap], "horizontal-line": ["Each horizontal line meets f once, so f⁻¹ is a function", ran, swap]}, right, out.answer)
	return out


## An interval from two ends, either of which may be missing.
static func _span(letter: String, lo: Variant, hi: Variant) -> String:
	return "%s ≥ %s" % [letter, say(lo)] if hi == null else iv(letter, lo, hi)


func u_restrict_for_inverse(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var h: Q = s.h
	var right_side: bool = s.px.to_float() > h.to_float()
	var rel := "≥" if right_side else "≤"
	var other := "≤" if right_side else "≥"
	var right := "x %s %s" % [rel, N(h)]
	var pt := Fmt.point(s.px, s.py)
	var out := {"asked": "Find the largest domain containing the point %s on which f has an inverse." % pt}
	out.merge(choose(right, [tag("x %s 0" % rel, R_Y_AXIS)], ["x %s %s" % [other, N(h)], "x %s %s" % [rel, N(s.px)], "x %s %s" % [rel, N(s.k)]]))
	if rep == "graph":
		out.lines = ["The graph of the parabola y = f(x) is shown, with the point marked."]
		out.graph = BasicFunctionViews.graph_of(s, h.to_float() - 4.0, h.to_float() + 4.0, [[s.px.to_float(), s.py.to_float(), pt]])
	else:
		out.lines = [eqn(s)]
	var vx := "The vertex is at x = %s" % N(h)
	var half := "One side of the vertex is one-to-one, and the point is on the side where x %s %s" % [rel, N(h)]
	out.methods = ways({"restrict-at-vertex": [vx, half], "horizontal-line": ["A horizontal line meets the parabola twice until it is cut at the vertex", vx, half],
		"gdc-turning-point": ["Graph it and use the turning point tool: x = %s" % N(h), half]}, right, out.answer)
	return out
