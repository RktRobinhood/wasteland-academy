class_name TrigModelEquationViews
extends TrigWaveViews
## The views on the `trig-model-equation` situation (FAL-752): t3-trig-model-equation, solving a
## trig equation or inequality for its times, or counting its solutions. They extend TrigWaveViews
## for its model text, graph and crossings, the way TrigWaveViews extends TrigModelViews.
##
## Paper 1 is exact, by the reference angle or by a sketch. Paper 2 is to 3 s.f. with a GDC, or by a
## sketch that says how many solutions to look for. A count or a band of k can be on either paper.
##
## Representations: "equation" (written out), "graph" (the curves drawn, with the line dashed) and,
## for a story model, "words".

const R_PART := "SL3.8.graphical#0"
const R_TOUCH_END := "SL3.8.graphical#1"
const R_GDC_DEGREES := "SL3.8.graphical#2"
const R_WHOLE_RANGE := "SL3.8.graphical#3"
const R_TOUCH_TWICE := "SL3.8.graphical#4"
const R_ONCE_A_CYCLE := "SL3.8.graphical#5"
const R_ONE_CYCLE_SHARE := "SL3.8.graphical#6"
const R_DROP_ENDS := "SL3.8.graphical#7"
const R_ORIGIN := "SL3.8.graphical#8"
const R_EVERY_CYCLE := "SL3.8.graphical#9"
const R_OTHER_EXTREME := "SL3.8.graphical#10"
const R_STOP_AT_ONE := "SL3.8.solve-basic#0"
const R_COS_LIKE_SIN := "SL3.8.solve-basic#1"

const M_GDC := "gdc-intersect"
const M_SKETCH := "sketch-and-count"
const M_RANGE := "range-reasoning"
const M_CAST := "unit-circle-cast"
## These read the wave's turning points and never intersect anything.
const READ_TURNS := {M_GDC: "Read the turning points on a GDC"}

const EXACT := ["exact-times-level", "time-at-least-exact"]
const STORY := ["times-in-window", "set-above-level", "set-below-level", "set-two-spans", "chance-above", "time-past-level"]
const WAVE := ["count-solutions", "count-at-extreme", "k-exactly-n", "k-any-solution", "k-no-solution", "touch-find-constant", "touch-one-solution"]
const VS := ["solve-vs-line", "solve-vs-exp", "count-vs-line"]
## Unknowns whose answer is the wave's own heights at the ends of its interval.
const EXACT_ENDS := ["k-exactly-n", "touch-one-solution"]


func needs() -> Dictionary:
	var out := {}
	for u in EXACT + STORY + WAVE + VS:
		out[u] = {"ask": u}
	return out


## Exact times are Paper 1, as the bank's one Paper 1 part is. A story's level and a curve against a
## line need a calculator. A count or a band of k works from a sketch, so it is on both.
func papers(unknown: String, _rep: String, _method_id: String) -> Array:
	if not has(unknown):
		return []
	if unknown in EXACT:
		return [1]
	if unknown in WAVE:
		return [1, 2]
	return [2]


# ── Exact times ──────────────────────────────────────────────

## The two values of the bracket in the first turn, as Qs of π, in order.
static func exact_us(s: Dictionary) -> Array:
	var pos: bool = s.ratio.sign() > 0
	if s.fn == "sin":
		return [Q.new(1, 6), Q.new(5, 6)] if pos else [Q.new(7, 6), Q.new(11, 6)]
	return [Q.new(1, 3), Q.new(5, 3)] if pos else [Q.new(2, 3), Q.new(4, 3)]


## The times with the bracket at these values, up to L.
static func exact_ts(s: Dictionary, us: Array, L: Q) -> Array:
	var out: Array = []
	var half: Q = s.period.div(2)
	for u in us:
		var t: Q = u.mul(half)
		while t.lt(L) or t.eq(L):
			out.append(t)
			t = t.add(s.period)
	out.sort_custom(func(x, y): return x.lt(y))
	return out


static func exact_xs(ts: Array) -> Dictionary:
	return Answer.xs_of(ts)


static func quadrants(s: Dictionary) -> String:
	var pos: bool = s.ratio.sign() > 0
	if s.fn == "sin":
		return "first and second" if pos else "third and fourth"
	return "first and fourth" if pos else "second and third"


static func exact_rearrange(s: Dictionary) -> String:
	var r: Q = s.ratio
	return "Set the model equal to the level: %s(%s) = (%s − %s) ÷ %s = %s" % [s.fn, m_inner(s), D(s.level), PD(s.d), PD(s.A), D(r)]


static func exact_cast(s: Dictionary) -> Array:
	var us := exact_us(s)
	var alpha := Fmt.pi(Q.new(1, 6) if s.fn == "sin" else Q.new(1, 3))
	var half: Q = s.period.div(2)
	return [exact_rearrange(s),
		"The reference angle is %s, and %s is %s in the %s quadrants, so the bracket is %s or %s." % [alpha, s.fn, "positive" if s.ratio.sign() > 0 else "negative", quadrants(s), Fmt.pi(us[0]), Fmt.pi(us[1])],
		"The bracket is %s, so t is its multiple of π times %s: t = %s or t = %s, then every %s." % [m_inner(s), D(half), D(us[0].mul(half)), D(us[1].mul(half)), D(s.period)]]


## The peak or trough the level is nearer: the crossings sit equally far either side of it.
static func exact_h(s: Dictionary) -> Q:
	return s.period.div(6)


static func exact_near(s: Dictionary) -> Dictionary:
	var over: bool = s.level.sub(s.d).sign() > 0
	return {"word": "peak" if over else "trough", "t": Q.new(1, 4).mul(s.period).mul(exact_quarters(s, over))}


## Where the nearer peak or trough is, in quarters of a period.
static func exact_quarters(s: Dictionary, peak: bool) -> int:
	var at := 1 if s.fn == "sin" else 0
	if s.A.sign() < 0:
		at += 2
	if not peak:
		at += 2
	return at % 4


static func exact_sketch(s: Dictionary) -> Array:
	var n := exact_near(s)
	var h := exact_h(s)
	return ["Sketch the model and y = %s: the line is halfway from the axis to each %s, so it crosses twice around every %s." % [D(s.level), n.word, n.word],
		"Let u be the time from a %s to a crossing. Half of the amplitude means cos(2πu/%s) = 1/2, so 2πu/%s = π/3 and u = %s" % [n.word, D(s.period), D(s.period), D(h)]]


func exact_setup(rep: String, s: Dictionary, span: float) -> Dictionary:
	return m_setup(rep, s, span, s.level)


func u_exact_times_level(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var L_: Q = s.L
	var us := exact_us(s)
	var ts := exact_ts(s, us, L_)
	var a := Answer.make("xs", exact_xs(ts), {"var": "t"})
	a.show = "dec"
	a.exact = true
	var set := exact_setup(rep, s, L_.to_float())
	var out := {"answer": a, "lines": set.lines, "graph": set.graph, "asked": "Find the exact value of every time in 0 ≤ t ≤ %s when %s is %s%s." % [D(L_), what(s), D(s.level), unit_of(s)]}
	out.wrongs = [wrong(exact_xs(ts.slice(0, 1)), R_STOP_AT_ONE)]
	if s.period.lt(L_):
		out.wrongs.append(wrong(exact_xs(exact_ts(s, us, s.period)), R_PART))
	if s.fn == "cos":
		out.wrongs.append(wrong(exact_xs(exact_ts(s, [us[0], Q.new(1).sub(us[0])], L_)), R_COS_LIKE_SIN))
	var flipped := s.duplicate()
	flipped.ratio = s.ratio.neg()
	var half: Q = s.period.div(2)
	out.generic = [exact_xs(exact_ts(flipped, exact_us(flipped), L_)), exact_xs(ts.map(func(t): return t.add(half))), exact_xs(ts.map(func(t): return t.add(1))), exact_xs(ts + [ts[ts.size() - 1].add(s.period)])]
	var last := "The times in 0 ≤ t ≤ %s are %s." % [D(L_), Answer.xs_list(ts.map(func(t): return D(t)))]
	var near := exact_near(s)
	out.methods = {M_CAST: method(exact_cast(s) + [last, say(a)], a.values),
		M_SKETCH: method(exact_sketch(s) + ["The %ss are at t = %s, then every %s, so the crossings are %s either side of them." % [near.word, D(near.t), D(s.period), D(exact_h(s))], last, say(a)], a.values)}
	return out


func u_time_at_least_exact(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var us := exact_us(s)
	var half: Q = s.period.div(2)
	var t1: Q = us[0].mul(half)
	var t2: Q = us[1].mul(half)
	var inside: Q = t2.sub(t1)
	var mid := t1.add(t2).div(2).to_float()
	var inside_is_above: bool = m_value(s, mid) > s.level.to_float()
	var w: Q = inside if inside_is_above == s.above else s.period.sub(inside)
	var word := "at least" if s.above else "at most"
	var a := Answer.make("number", {"v": w}, {}, "Time = ", " " + ctx(s).time)
	a.exact = true
	a.show = "dec"
	var set := exact_setup(rep, s, 1.25 * s.T)
	var out := {"answer": a, "lines": set.lines, "graph": set.graph, "asked": "In one full cycle of the model, for how long is %s %s %s%s? Give the exact value." % [what(s), word, D(s.level), unit_of(s)]}
	out.wrongs = [wrong({"v": s.period.sub(w)}, R_OTHER_SIDE)]
	# Half of a stretch round a peak: at a trough the string's "peak" wouldn't be true.
	if s.above and w.lt(s.period) and s.level.sub(s.d).sign() > 0:
		out.wrongs.append(wrong({"v": w.div(2)}, R_ONE_SIDE))
	out.generic = [{"v": t1}, {"v": t2}, {"v": s.period}, {"v": s.period.div(2)}, {"v": w.add(1)}, {"v": w.mul(2)}]
	var near := exact_near(s)
	var round_it: Q = exact_h(s).mul(2)
	var above_near: bool = near.word == "peak"
	var other := "So in each cycle it is %s %s for 2 × %s = %s" % ["above" if above_near else "below", D(s.level), D(exact_h(s)), D(round_it)]
	var want := "It is %s %s for %s of each cycle of %s." % [word, D(s.level), D(w), D(s.period)]
	if above_near != s.above:
		other += ", and on the other side of it for %s − %s = %s" % [D(s.period), D(round_it), D(w)]
	var between := "Between them the model is %s the level, and the rest of the cycle is the other side." % ("above" if inside_is_above else "below")
	var gap := "%s − %s = %s" % [D(t2), D(t1), D(inside)]
	var rest: String = "The time asked for is that gap: %s" % gap if inside_is_above == s.above else "The time asked for is the rest of the cycle: %s, then %s − %s = %s" % [gap, D(s.period), D(inside), D(w)]
	out.methods = {M_CAST: method(exact_cast(s) + [between, rest, say(a)], a.values),
		M_SKETCH: method(exact_sketch(s) + [other, want, say(a)], a.values)}
	return out


# ── A story and a level ──────────────────────────────────────

## The stretches of 0 ≤ t ≤ L on one side of k: [[from, to], ...].
static func pieces(s: Dictionary, k: float, L_: float, above: bool, degrees: bool = false) -> Array:
	var xs: Array = [0.0] + crossings(s, k, L_, degrees) + [float(L_)]
	var out: Array = []
	for i in xs.size() - 1:
		if xs[i + 1] - xs[i] > 1e-9 and (m_value(s, (xs[i] + xs[i + 1]) / 2.0, degrees) > k) == above:
			out.append([xs[i], xs[i + 1]])
	return out


static func total(ps: Array) -> float:
	var out := 0.0
	for p in ps:
		out += p[1] - p[0]
	return out


static func stretch(p: Array, L_: float) -> String:
	var lo: String = "0 ≤ t" if p[0] <= 0.0 else GdcKit.S(p[0]) + " < t"
	var hi: String = " ≤ " + str(int(L_)) if p[1] >= L_ else " < " + GdcKit.S(p[1])
	return lo + hi


static func set_text(ps: Array, L_: float) -> String:
	return " or ".join(ps.map(func(p): return stretch(p, L_)))


## Slot values are the ends to 3 s.f., as the options write them.
static func rounded(x: float) -> Q:
	return Answer.parse_number(GdcKit.S(x).replace("−", "-")).q


static func set_answer(ps: Array, L_: float) -> Dictionary:
	var parts: Array = []
	var vals := {}
	for i in ps.size():
		var p: Array = ps[i]
		if i > 0:
			parts.append(" or ")
		if p[0] <= 0.0:
			parts.append("0 ≤ t")
		else:
			parts.append({"slot": "a%d" % i})
			parts.append(" < t")
			vals["a%d" % i] = rounded(p[0])
		if p[1] >= L_:
			parts.append(" ≤ " + str(int(L_)))
		else:
			parts.append(" < ")
			parts.append({"slot": "b%d" % i})
			vals["b%d" % i] = rounded(p[1])
	return DifferentiationViews.form(set_text(ps, L_), parts, vals)


## The ends a set answer turns on.
static func inner_ends(ps: Array, L_: float) -> Array:
	var out: Array = []
	for p in ps:
		if p[0] > 0.0:
			out.append(p[0])
		if p[1] < L_:
			out.append(p[1])
	return out


static func stretches_text(ps: Array) -> String:
	return Answer.xs_list(ps.map(func(p): return "%s to %s" % [GdcKit.W(p[0]), GdcKit.W(p[1])]))


static func word_of(s: Dictionary) -> String:
	return "above" if s.above else "below"


static func window_text(s: Dictionary) -> String:
	return "%d ≤ t ≤ %d" % [s.t_from, s.t_to]


func u_times_in_window(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: float = s.level.to_float()
	var all := crossings(s, k, s.t_to)
	var xs := all.filter(func(x): return x > s.t_from)
	var like := func(vals: Array) -> Dictionary: return Answer.xs_of(vals.map(func(x): return GdcKit.qf(x)))
	var a := Answer.make("xs", like.call(xs), {"var": "t"})
	a.show = "sf"
	var set := m_setup(rep, s, s.t_to, s.level)
	var out := {"answer": a, "lines": set.lines, "graph": set.graph, "sfs": xs, "asked": "Find every time in %s when %s is %s%s, to 3 significant figures." % [window_text(s), what(s), D(s.level), unit_of(s)]}
	out.wrongs = [wrong(like.call(xs.slice(0, xs.size() - 1)), R_PART)]
	# A degree-mode wave has hardly begun, so it may not cross in the window at all.
	var deg := crossings(s, k, s.t_to, true).filter(func(x): return x > s.t_from)
	if not deg.is_empty():
		out.wrongs.append(wrong(like.call(deg), R_GDC_DEGREES))
	out.generic = [like.call(all), like.call(xs.map(func(x): return x + 1.0)), like.call(xs.map(func(x): return x + s.T / 4.0)), like.call(xs + [xs[xs.size() - 1] + s.T])]
	var found := "Intersect finds each one: t = %s." % list(xs)
	out.methods = {M_GDC: method([gdc_line(s, s.level), "Set the window to %s: they cross %d times." % [window_text(s), xs.size()], found, say(a)], a.values),
		M_SKETCH: method(["Sketch the model and the line over %s: they cross %d times, once going up and once going down in each cycle." % [window_text(s), xs.size()],
			rearrange(s, s.level), us_text(s, s.level), "Undoing the bracket and moving on by the period, %s, the times in the window are t = %s." % [GdcKit.W(s.T), list(xs)], say(a)], a.values)}
	return out


func set_view(rep: String, s: Dictionary) -> Dictionary:
	var k: float = s.level.to_float()
	var ps := pieces(s, k, s.L, s.above)
	var a := set_answer(ps, s.L)
	var set := m_setup(rep, s, s.L, s.level)
	var word := word_of(s)
	var out := {"answer": a, "lines": set.lines, "graph": set.graph, "sfs": inner_ends(ps, s.L),
		"asked": "For 0 ≤ t ≤ %d, find the set of times when %s is %s %s%s. Give the times to 3 significant figures." % [s.L, what(s), word, D(s.level), unit_of(s)]}
	out.wrongs = [DifferentiationViews.alt(set_text(pieces(s, k, s.L, not s.above), s.L), R_OTHER_SIDE)]
	# A degree-mode wave has hardly begun: it may stay past the level all span, or not reach it.
	var deg := pieces(s, k, s.L, s.above, true)
	if not deg.is_empty():
		out.wrongs.append(DifferentiationViews.alt(set_text(deg, s.L), R_GDC_DEGREES))
	if ps.size() == 2:
		out.wrongs.push_front(DifferentiationViews.alt(set_text(ps.slice(0, 1), s.L), R_PART))
	elif s.above:
		var p: Array = ps[0]
		out.wrongs.append(DifferentiationViews.alt(set_text([[p[0], (p[0] + p[1]) / 2.0]], s.L), R_ONE_SIDE))
	var shift := func(dt: float) -> Array: return ps.map(func(p): return [p[0] + dt if p[0] > 0.0 else 0.0, minf(p[1] + dt, s.L)])
	out.generic = [DifferentiationViews.alt(set_text(shift.call(1.0), s.L)).values, DifferentiationViews.alt(set_text(shift.call(s.T / 4.0), s.L)).values,
		DifferentiationViews.alt(set_text(shift.call(-0.5), s.L)).values, DifferentiationViews.alt(set_text(pieces(s, k + s.a.to_float() / 4.0, s.L, s.above), s.L)).values]
	var xs := crossings(s, k, s.L)
	var said := "The model is %s %s for %s." % [word, D(s.level), stretches_text(ps)]
	out.methods = {M_GDC: method([gdc_line(s, s.level), "For 0 ≤ t ≤ %d they cross at t = %s." % [s.L, list(xs)], said, say(a)], a.values),
		M_SKETCH: method(["Sketch the model and the line for 0 ≤ t ≤ %d: they cross %d times, and the curve is %s the line %s." % [s.L, xs.size(), word, "once" if ps.size() == 1 else "in two stretches"],
			rearrange(s, s.level), us_text(s, s.level), "Undoing the bracket, the crossings are at t = %s." % list(xs), said, say(a)], a.values)}
	return out


func u_set_above_level(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return set_view(rep, s)


func u_set_below_level(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return set_view(rep, s)


func u_set_two_spans(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return set_view(rep, s)


## The working of a time past a level in a span, up to its total.
func span_methods(s: Dictionary, a: Dictionary, ps: Array, end: Array) -> Dictionary:
	var k: float = s.level.to_float()
	var xs := crossings(s, k, s.L)
	var said := "It is %s %s for %s, which adds up to %s." % [word_of(s), D(s.level), stretches_text(ps), GdcKit.W(total(ps))]
	var crossed := "For 0 ≤ t ≤ %d they cross at t = %s." % [s.L, list(xs)] if not xs.is_empty() else "They don't cross for 0 ≤ t ≤ %d." % s.L
	var solved: Array = [crossed] if xs.is_empty() else [rearrange(s, s.level) + " " + us_text(s, s.level), "Undoing the bracket, " + crossed.substr(0, 1).to_lower() + crossed.substr(1)]
	return {M_GDC: method([gdc_line(s, s.level), crossed, said] + end + [say(a)], a.values),
		M_SKETCH: method(["Sketch the model and the line for 0 ≤ t ≤ %d: the span holds %s periods, so count the stretches past the line one by one, not by cycles." % [s.L, GdcKit.S(s.L / s.T)],
			] + solved + [said] + end + [say(a)], a.values)}


## The options offered are the first few, so a question starts its slips at its own `spin`. Every
## slip then shows up across the seeds, whatever else the question offers.
static func spun(wrongs: Array, s: Dictionary) -> Array:
	var at: int = s.spin % wrongs.size()
	return wrongs.slice(at) + wrongs.slice(0, at)


func u_chance_above(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: float = s.level.to_float()
	var ps := pieces(s, k, s.L, true)
	var tot := total(ps)
	var p: float = tot / s.L
	var a := fnum("P = ", p)
	var set := m_setup(rep, s, s.L, s.level)
	var out := {"answer": a, "lines": set.lines, "graph": set.graph, "sfs": [p],
		"asked": "A reading is taken at a random time in the first %d %s. Find the probability that %s is above %s%s at that time, to 3 significant figures." % [s.L, ctx(s).time, what(s), D(s.level), unit_of(s)]}
	var w: float = 2.0 * peak_around(s, k)[1]
	out.wrongs = [wrong(v_of(w / s.T), R_ONE_CYCLE_SHARE), wrong(v_of(1.0 - p), R_OTHER_SIDE)]
	# A degree-mode wave has hardly begun: it may stay past the level all span, or not reach it.
	var d := total(pieces(s, k, s.L, true, true))
	if d > 0.0:
		out.wrongs.append(wrong(v_of(d / s.L), R_GDC_DEGREES))
	out.wrongs = spun(out.wrongs, s)
	out.generic = [v_of(p / 2.0), v_of(minf(p + 0.1, 0.95)), v_of(maxf(p - 0.1, 0.03)), v_of(0.5)]
	out.methods = span_methods(s, a, ps, ["The chance is the share of the span: %s ÷ %d = %s" % [GdcKit.W(tot), s.L, GdcKit.W(p)]])
	return out


func u_time_past_level(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: float = s.level.to_float()
	var ps := pieces(s, k, s.L, s.above)
	var tot := total(ps)
	var a := t_ans(s, tot)
	a.label = "Time = "
	var set := m_setup(rep, s, s.L, s.level)
	var out := {"answer": a, "lines": set.lines, "graph": set.graph, "sfs": [tot],
		"asked": "For how long in 0 ≤ t ≤ %d is %s %s %s%s? Answer to 3 significant figures." % [s.L, what(s), word_of(s), D(s.level), unit_of(s)]}
	var above_w: float = 2.0 * peak_around(s, k)[1]
	var w: float = above_w if s.above else s.T - above_w
	var full := floori(s.L / s.T)
	out.wrongs = [wrong(v_of(s.L - tot), R_OTHER_SIDE), wrong(v_of(w * s.L / s.T), R_ONE_CYCLE_SHARE), wrong(v_of(w * full), R_PART)]
	var d := total(pieces(s, k, s.L, s.above, true))
	if d > 0.0:
		out.wrongs.append(wrong(v_of(d), R_GDC_DEGREES))
	out.wrongs = spun(out.wrongs, s)
	out.generic = [v_of(tot / 2.0), v_of(tot + w), v_of(float(s.L)), v_of(tot + 1.0)]
	out.methods = span_methods(s, a, ps, [])
	return out


# ── A wave on an interval ────────────────────────────────────

## b as a number, and in degree mode as what b × x reads as.
static func x_b(s: Dictionary, degrees: bool = false) -> float:
	var b: float = s.bq.to_float() * (PI if s.kind == "pi" else 1.0)
	return deg_to_rad(b) if degrees else b


static func x_end(s: Dictionary, v: Q) -> float:
	return v.to_float() * (PI if s.kind == "x" else 1.0)


static func x_value(s: Dictionary, x: float, degrees: bool = false) -> float:
	var u := x_b(s, degrees) * x
	return s.a.to_float() * (sin(u) if s.fn == "sin" else cos(u)) + s.d.to_float()


## The ends of the interval and the turning points inside it, in order: [[x, y], ...]. The wave is
## monotonic between two neighbours.
static func nodes(s: Dictionary, degrees: bool = false) -> Array:
	var lo := x_end(s, s.lo_x)
	var hi := x_end(s, s.hi_x)
	var b := x_b(s, degrees)
	var step := PI / b
	var first: float = step / 2.0 if s.fn == "sin" else 0.0
	var i := ceili((lo - first) / step - 1e-9)
	var xs: Array = [lo]
	while first + i * step < hi - 1e-9:
		var x: float = first + i * step
		if x > lo + 1e-9:
			xs.append(x)
		i += 1
	xs.append(hi)
	return xs.map(func(x): return [x, x_value(s, x, degrees)])


## How many times y = k meets the wave on its interval, with ups and downs: [all, up, down].
static func count_parts(s: Dictionary, k: float, degrees: bool = false) -> Array:
	var ns := nodes(s, degrees)
	var n := 0
	var up := 0
	var down := 0
	for i in ns.size():
		var y: float = ns[i][1]
		if absf(y - k) < 1e-9:
			n += 1
		if i + 1 < ns.size():
			var y2: float = ns[i + 1][1]
			if absf(y - k) >= 1e-9 and absf(y2 - k) >= 1e-9 and (y - k) * (y2 - k) < 0.0:
				n += 1
				if y2 > y:
					up += 1
				else:
					down += 1
	return [n, up, down]


static func count_k(s: Dictionary, k: float, degrees: bool = false) -> int:
	return count_parts(s, k, degrees)[0]


## Every x where y = k meets the wave, in order.
static func x_roots(s: Dictionary, k: float) -> Array:
	var ns := nodes(s)
	var out: Array = []
	for i in ns.size():
		if absf(ns[i][1] - k) < 1e-9:
			out.append(ns[i][0])
		elif i + 1 < ns.size() and absf(ns[i + 1][1] - k) >= 1e-9 and (ns[i][1] - k) * (ns[i + 1][1] - k) < 0.0:
			var lo: float = ns[i][0]
			var hi: float = ns[i + 1][0]
			var slo: float = ns[i][1] - k
			for _i in 60:
				var m := (lo + hi) / 2.0
				if (x_value(s, m) - k) * slo > 0.0:
					lo = m
				else:
					hi = m
			out.append((lo + hi) / 2.0)
	return out


## The heights the count can change at, low to high, with the count at each and between: each
## {"lo", "hi", "n"}, where lo = hi at a height. [] if an end isn't at the axis, the top or the bottom.
static func bands(s: Dictionary) -> Array:
	var hs: Array = []
	for n in nodes(s):
		var hit := false
		for q in [s.low, s.d, s.top]:
			if absf(q.to_float() - n[1]) < 1e-9:
				hit = true
				if not hs.any(func(h): return h.eq(q)):
					hs.append(q)
		if not hit:
			return []
	hs.sort_custom(func(x, y): return x.lt(y))
	var out: Array = []
	for i in hs.size():
		var q: Q = hs[i]
		out.append({"lo": q, "hi": q, "n": count_k(s, q.to_float())})
		if i + 1 < hs.size():
			var mid: Q = q.add(hs[i + 1]).div(2)
			out.append({"lo": q, "hi": hs[i + 1], "n": count_k(s, mid.to_float())})
	return out


static func band_word(n: int) -> String:
	return "%d solution%s" % [n, "" if n == 1 else "s"]


## "k = −2 gives 1 solution, −2 < k < 1 gives 2 solutions, ..."
static func bands_text(s: Dictionary) -> String:
	var parts: Array = []
	for b in bands(s):
		var head: String = "k = %s" % D(b.lo) if b.lo.eq(b.hi) else "%s < k < %s" % [D(b.lo), D(b.hi)]
		parts.append("%s gives %s" % [head, band_word(b.n)])
	return ", ".join(parts)


static func ends_text(s: Dictionary) -> String:
	return "%s ≤ x ≤ %s" % [x_place(s, s.lo_x), x_place(s, s.hi_x)]


static func x_place(s: Dictionary, v: Q) -> String:
	return Fmt.pi(v) if s.kind == "x" else D(v)


## The wave's period as the working writes it.
static func per_text(s: Dictionary) -> String:
	return at_w(s, per(s))


## How many periods the interval holds.
static func cycles(s: Dictionary) -> float:
	return (x_end(s, s.hi_x) - x_end(s, s.lo_x)) / x_period(s)


static func x_period(s: Dictionary) -> float:
	return TAU / x_b(s)


static func cycles_text(s: Dictionary) -> String:
	return GdcKit.W(snappedf(cycles(s), 0.001))


static func x_graph(s: Dictionary, k: Variant = null, marks: bool = false) -> Dictionary:
	var lo := x_end(s, s.lo_x)
	var hi := x_end(s, s.hi_x)
	var f := func(x: float) -> float: return x_value(s, x)
	var y_lo: float = s.low.to_float()
	var y_hi: float = s.top.to_float()
	if k != null:
		y_lo = minf(y_lo, k.to_float())
		y_hi = maxf(y_hi, k.to_float())
	var hl: Array = [] if k == null else [[k.to_float(), "y = %s" % D(k)]]
	var pts: Array = []
	if marks:
		var ns := nodes(s)
		for name in ["max", "min"]:
			var want: Q = s.top if name == "max" else s.low
			for n in ns.slice(1, ns.size() - 1):
				if absf(n[1] - want.to_float()) < 1e-9:
					pts.append([n[0], n[1], "%s (%s, %s)" % [name, x_decimal_place(s, n[0]), D(want)]])
					break
	var g: Dictionary
	if s.kind == "x":
		var span: float = cycles(s)
		var step: Q = per(s).div(4 if span <= 2.0 else (2 if span <= 4.0 else 1))
		g = TrigKit.wave(f, s.lo_x, s.hi_x, floori(y_lo) - 1, ceili(y_hi) + 1, step, pts, hl)
	else:
		g = Plot.spec([Plot.sample(f, lo, hi)], pts, floori(lo), ceili(hi), floori(y_lo) - 1, ceili(y_hi) + 1, hl)
	g.x_name = "x"
	g.y_name = "y"
	return g


## A place on a figure: exact for kinds "x" and "pi", where a turning point is on the quarters.
static func x_decimal_place(s: Dictionary, x: float) -> String:
	match s.kind:
		"x":
			return Fmt.pi(Q.new(roundi(x / PI * 720.0), 720))
		"pi":
			return D(Q.new(roundi(x * 720.0), 720))
	return GdcKit.S(x)


func x_view(rep: String, s: Dictionary, k: Variant, marks: bool, tail: String = "") -> Dictionary:
	var eq := "f(x) = %s, for %s, with x in radians." % [wave_text(s), ends_text(s)]
	if rep != "graph":
		return {"lines": [eq], "graph": null}
	var line := "The graph of y = f(x) is shown%s." % tail
	return {"lines": [eq, line], "graph": x_graph(s, k, marks)}


## The extreme at this height: "maximum" or "minimum".
static func extreme_word(s: Dictionary, big: bool) -> String:
	return "maximum" if big else "minimum"


static func first_of(s: Dictionary, big: bool) -> Q:
	return next_peak(s, (s.a.sign() < 0) == big, s.fn)


func u_count_solutions(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: float = s.k.to_float()
	var parts := count_parts(s, k)
	var n: int = parts[0]
	var a := plain("Number of solutions = ", Q.new(n))
	var v := x_view(rep, s, s.k, false, ", with the line y = %s dashed" % D(s.k))
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "asked": "Find the number of solutions of f(x) = %s." % D(s.k)}
	out.wrongs = []
	var span_cycles := cycles(s)
	var whole := floori(span_cycles + 1e-9)
	if s.kind != "dec":
		var one := s.duplicate()
		one.hi_x = s.lo_x.add(per(s))
		var c1 := count_k(one, k)
		if c1 != n:
			out.wrongs.append(wrong({"v": Q.new(c1)}, R_PART))
	if whole != n and whole > 0:
		out.wrongs.append(wrong({"v": Q.new(whole)}, R_ONCE_A_CYCLE))
	if s.paper == 2:
		var deg := count_k(s, k, true)
		if deg != n:
			out.wrongs.append(wrong({"v": Q.new(deg)}, R_GDC_DEGREES))
	out.generic = [{"v": Q.new(n + 1)}, {"v": Q.new(n + 2)}, {"v": Q.new(maxi(n - 1, 1))}, {"v": Q.new(2 * n)}]
	var between := "%s < %s < %s, so the line crosses the wave." % [D(s.low), D(s.k), D(s.top)]
	var extra: int = n - 2 * whole
	var said := "Number of solutions = %d." % n
	out.methods = {M_SKETCH: method(["The wave has period %s and runs between %s and %s." % [per_text(s), D(s.low), D(s.top)],
			"The interval holds %s periods, so sketch that many with the line y = %s." % [cycles_text(s), D(s.k)],
			"Count along the sketch: it crosses going up %d times and going down %d times." % [parts[1], parts[2]], said], a.values),
		M_RANGE: method([between, "A line inside the range crosses twice in each full cycle, so the %s in the interval give%s %d." % ["1 full cycle" if whole == 1 else "%d full cycles" % whole, "s" if whole == 1 else "", 2 * whole],
			"What is left of the interval gives %d more." % extra, said], a.values)}
	if s.paper == 2:
		var xs := x_roots(s, k)
		out.methods[M_GDC] = method(["Graph y = %s and y = %s in radian mode, with the window %s." % [wave_text(s), D(s.k), ends_text(s)],
			"Intersect finds them from x = %s to x = %s, and there are %d in all." % [GdcKit.W(xs[0]), GdcKit.W(xs[xs.size() - 1]), n], said], a.values)
	return out


func u_count_at_extreme(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: float = s.k.to_float()
	var n := count_k(s, k)
	var a := plain("Number of solutions = ", Q.new(n))
	var v := x_view(rep, s, s.k, false, ", with the line y = %s dashed" % D(s.k))
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "titles": READ_TURNS, "asked": "Find the number of solutions of f(x) = %s." % D(s.k)}
	out.wrongs = [wrong({"v": Q.new(2 * n)}, R_TOUCH_TWICE)]
	out.wrongs.append(wrong({"v": Q.new(1)}, R_PART))
	out.generic = [{"v": Q.new(n + 1)}, {"v": Q.new(n + 2)}, {"v": Q.new(maxi(n - 1, 2))}, {"v": Q.new(2 * n + 1)}, {"v": Q.new(0)}]
	var word := extreme_word(s, s.big)
	var first := first_of(s, s.big)
	var last := along(s, first, n - 1)
	var value := "The %s of f is %s %s %s = %s, which is the line's height." % [word, D(s.d), "+" if s.big else "−", D(s.a.abs_q()), D(s.k)]
	var touch := "The line only touches the wave at each %s, so each one is one solution, not two." % word
	var place := "The %s in the interval are at x = %s, then every %s, up to x = %s." % ["maxima" if s.big else "minima", at_w(s, first), per_text(s), at_w(s, last)]
	var said := "Number of solutions = %d." % n
	out.methods = {M_RANGE: method([value, touch, place, said], a.values),
		M_SKETCH: method(["Sketch the wave over the interval, which holds %s periods, with the line y = %s." % [cycles_text(s), D(s.k)], value, touch, place, said], a.values)}
	if s.paper == 2:
		out.methods[M_GDC] = method(["Graph y = %s in radian mode, with the window %s." % [wave_text(s), ends_text(s)], "Each %s is at height %s, on the line, and the first is at x = %s." % [word, D(s.k), at_w(s, first)], place, said], a.values)
	return out


func u_k_exactly_n(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var vals := {"lo": s.k_lo, "r1": s.r1, "r2": s.r2, "hi": s.k_hi}
	var a := Answer.make("range2", vals, {"var": "k"})
	a.show = "dec"
	a.exact = true
	var v := x_view(rep, s, null, true)
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "titles": READ_TURNS, "asked": "Find the set of values of k for which f(x) = k has exactly %d solutions." % s.n_sol}
	var at_extreme: bool = (s.r1 == "<" and s.k_lo.eq(s.low)) or (s.r2 == "<" and s.k_hi.eq(s.top))
	out.wrongs = []
	if at_extreme:
		var to := vals.duplicate()
		if s.k_lo.eq(s.low):
			to.r1 = "≤"
		if s.k_hi.eq(s.top):
			to.r2 = "≤"
		out.wrongs.append(wrong(to, R_TOUCH_END))
	out.wrongs.append(wrong(range_vals(s.low, s.top), R_WHOLE_RANGE))
	out.generic = [range_vals(s.k_lo, s.k_hi), range_vals(s.k_lo, s.k_hi, "<"), range_vals(s.low, s.top, "<"), range_vals(s.low, s.d), range_vals(s.d, s.top), range_vals(s.low, s.d, "<"), range_vals(s.d, s.top, "<")]
	var counts := bands_text(s)
	var right := "So exactly %d solutions needs %s." % [s.n_sol, Answer.text(a)]
	out.methods = {M_SKETCH: method(["Sketch the wave over the interval, and slide the line y = k up from %s to %s." % [D(s.low), D(s.top)], counts + ".", right], a.values),
		M_RANGE: method(["y = k meets the wave only for %s ≤ k ≤ %s, as those are its minimum and maximum." % [D(s.low), D(s.top)], "At a turning point the line only touches, and at the ends of the interval it can stop crossing, so the count can change only at those heights.", counts + ".", right], a.values)}
	if s.paper == 2:
		out.methods[M_GDC] = method(["Graph y = %s in radian mode, with the window %s." % [wave_text(s), ends_text(s)], "Read the turning points and the two ends, then count the crossings of a line at each height: %s." % counts, right], a.values)
	return out


static func gdc_values(s: Dictionary) -> String:
	return "Its maximum value is %s and its minimum value is %s." % [D(s.top), D(s.low)]


func u_k_any_solution(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := Answer.make("range2", range_vals(s.low, s.top), {"var": "k"})
	a.show = "dec"
	a.exact = true
	var amp: Q = s.a.abs_q()
	var v := x_view(rep, s, null, true)
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "titles": READ_TURNS, "asked": "Find the set of values of k for which f(x) = k has at least one solution."}
	out.wrongs = [wrong(range_vals(s.low, s.top, "<"), R_DROP_ENDS), wrong(range_vals(amp.neg(), amp), R_NO_D)]
	out.generic = [range_vals(s.d, s.top), range_vals(s.low, s.d), range_vals(s.low.sub(amp), s.top.add(amp)), range_vals(s.low.sub(1), s.top.add(1))]
	var turn := "The interval holds %s periods, so the wave reaches both its maximum and its minimum." % cycles_text(s)
	var range_ := "%s runs from −1 to 1, so f runs from %s − %s = %s to %s + %s = %s." % [s.fn, D(s.d), D(amp), D(s.low), D(s.d), D(amp), D(s.top)]
	var meets := "y = k meets the wave for every height from the minimum to the maximum, the two ends included."
	var right := say(a)
	out.methods = {M_RANGE: method([turn, range_, meets, right], a.values)}
	if s.paper == 2:
		out.methods[M_GDC] = method([gdc_step(s), gdc_values(s), meets, right], a.values)
	return out


static func outside_text(lo: Q, hi: Q, strict: bool) -> String:
	return "k %s %s or k %s %s" % ["<" if strict else "≤", D(lo), ">" if strict else "≥", D(hi)]


func u_k_no_solution(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var amp: Q = s.a.abs_q()
	var a := DifferentiationViews.form(outside_text(s.low, s.top, true), ["k < ", {"slot": "lo"}, " or k > ", {"slot": "hi"}], {"lo": s.low, "hi": s.top})
	var v := x_view(rep, s, null, true)
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "titles": READ_TURNS, "asked": "Find the set of values of k for which f(x) = k has no solutions."}
	out.wrongs = [DifferentiationViews.alt(outside_text(s.low, s.top, false), R_TOUCH_END), DifferentiationViews.alt(outside_text(amp.neg(), amp, true), R_NO_D, {"lo": amp.neg(), "hi": amp})]
	out.generic = [DifferentiationViews.alt("%s < k < %s" % [D(s.low), D(s.top)]).values, DifferentiationViews.alt(outside_text(s.d, s.top, true), "", {"lo": s.d, "hi": s.top}).values,
		DifferentiationViews.alt(outside_text(s.low, s.d, true), "", {"lo": s.low, "hi": s.d}).values, DifferentiationViews.alt(outside_text(s.low.sub(1), s.top.add(1), true), "", {"lo": s.low.sub(1), "hi": s.top.add(1)}).values]
	var turn := "The interval holds %s periods, so the wave reaches both its maximum and its minimum." % cycles_text(s)
	var range_ := "%s runs from −1 to 1, so f runs from %s − %s = %s to %s + %s = %s." % [s.fn, D(s.d), D(amp), D(s.low), D(s.d), D(amp), D(s.top)]
	var miss := "y = k misses the wave only if it is below the minimum or above the maximum. At those two heights it still touches."
	var right := say(a)
	out.methods = {M_RANGE: method([turn, range_, miss, right], a.values)}
	if s.paper == 2:
		out.methods[M_GDC] = method([gdc_step(s), gdc_values(s), miss, right], a.values)
	return out


## f with the letter p in place of a or d.
static func touch_text(s: Dictionary) -> String:
	if s.which == "d":
		return "%s%s(%s) + p" % [lead(s.a), s.fn, inside(s)]
	return "p %s(%s)%s" % [s.fn, inside(s), tail(s.d)]


func u_touch_find_constant(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: Q = s.d if s.which == "d" else s.a
	var word := extreme_word(s, s.big)
	var given := "f(x) = %s, with x in radians%s." % [touch_text(s), ", and p > 0" if s.which == "a" else ""]
	var a := plain("p = ", p)
	var touch := "The line y = %s touches the graph of f at its %s points." % [D(s.k), word]
	var out := {"answer": a, "lines": [given, touch], "titles": READ_TURNS, "asked": "Find p."}
	if rep == "graph":
		out.lines = [given, touch + " The graph and the line are shown."]
		out.graph = x_graph(s, s.k)
	var amp: Q = s.a.abs_q()
	var sum: String
	if s.which == "d":
		out.wrongs = [wrong({"v": s.k.add(amp) if s.big else s.k.sub(amp)}, R_OTHER_EXTREME)]
		out.generic = [{"v": s.k}, {"v": amp}, {"v": s.k.add(amp.mul(2))}, {"v": amp.neg()}, {"v": p.add(1)}]
		sum = "%s %s %s = %s" % [D(s.k), "−" if s.big else "+", PD(amp), D(p)]
	else:
		out.wrongs = [wrong({"v": p.neg()}, R_OTHER_EXTREME), wrong({"v": s.k if s.big else s.k.neg()}, R_NO_D)]
		out.generic = [{"v": s.k.add(s.d)}, {"v": s.d}, {"v": p.mul(2)}, {"v": p.add(1)}]
		sum = "%s − %s = %s" % [PD(s.k if s.big else s.d), PD(s.d if s.big else s.k), D(p)]
	var head := "The line touches at a %s, so %s is the %s value of f." % [word, D(s.k), word]
	var formula: String
	if s.which == "d":
		formula = "The %s of f is p %s %s, so p %s %s = %s." % [word, "+" if s.big else "−", D(amp), "+" if s.big else "−", D(amp), D(s.k)]
	else:
		formula = "The %s of f is %s %s p, as p > 0, so %s %s p = %s." % [word, D(s.d), "+" if s.big else "−", D(s.d), "+" if s.big else "−", D(s.k)]
	out.methods = {M_RANGE: method([head, formula, "p = " + sum, say(a)], a.values)}
	if s.paper == 2:
		var shape: String = "%s%s(%s)" % [lead(s.a) if s.which == "d" else "", s.fn, inside(s)]
		var seen: String = D(amp if s.big else amp.neg()) if s.which == "d" else ("1" if s.big else "−1")
		out.methods[M_GDC] = method(["Graph y = %s in radian mode: its %s value is %s." % [shape, word, seen], formula, "p = " + sum, say(a)], a.values)
	return out


func u_touch_one_solution(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := Answer.make("kvals", {"r1": s.low, "r2": s.top}, {"var": "k"})
	a.show = "dec"
	a.exact = true
	var amp: Q = s.a.abs_q()
	var v := x_view(rep, s, null, true)
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "titles": READ_TURNS, "asked": "Find the two values of k for which f(x) = k has exactly one solution."}
	out.wrongs = [wrong({"r1": amp.neg(), "r2": amp}, R_NO_D)]
	out.generic = [{"r1": s.low, "r2": s.d}, {"r1": s.d, "r2": s.top}, {"r1": s.low.sub(amp), "r2": s.top.add(amp)}, {"r1": s.low.sub(1), "r2": s.top.add(1)}]
	var one := "The wave reaches its maximum %s and its minimum %s once each on this interval, and the line only touches there." % [D(s.top), D(s.low)]
	var rest := "The ends of the interval are at height %s, and every k between the turning points is crossed at least twice." % D(s.d)
	var right := say(a)
	out.methods = {M_SKETCH: method(["Sketch the one cycle, from the axis back to the axis, and slide the line y = k up it.", one, rest, right], a.values),
		M_RANGE: method(["%s runs from −1 to 1, so f runs from %s to %s." % [s.fn, D(s.low), D(s.top)], one, rest, right], a.values)}
	if s.paper == 2:
		out.methods[M_GDC] = method([gdc_step(s), gdc_values(s), rest, right], a.values)
	return out


# ── A trig curve and another curve ───────────────────────────

static func vs_rhs_text(s: Dictionary) -> String:
	if s.vs == "line":
		return D(s.m) + "x"
	return "e^(−x)" if s.e.eq(1) else "e^(−%sx)" % D(s.e)


static func vs_lhs_text(s: Dictionary) -> String:
	return "%s%s(%s)" % [lead(s.a), s.fn, b_x(s)]


static func vs_eq(s: Dictionary) -> String:
	return "%s = %s" % [vs_lhs_text(s), vs_rhs_text(s)]


static func vs_ends(s: Dictionary) -> String:
	return "%s ≤ x ≤ %s" % [Fmt.pi(s.lo_x), Fmt.pi(s.hi_x)]


static func vs_trig(s: Dictionary, x: float, degrees: bool = false) -> float:
	var u: float = s.bq.to_float() * x
	if degrees:
		u = deg_to_rad(u)
	return s.a.to_float() * (sin(u) if s.fn == "sin" else cos(u))


static func vs_rhs(s: Dictionary, x: float) -> float:
	return s.m.to_float() * x if s.vs == "line" else exp(-s.e.to_float() * x)


## Every solution in the interval, in order. A sine against a line through 0 is odd, so x = 0 is one.
static func vs_roots(s: Dictionary, degrees: bool = false) -> Array:
	var f := func(x: float) -> float: return vs_trig(s, x, degrees) - vs_rhs(s, x)
	var lo: float = s.lo_x.to_float() * PI
	var hi: float = s.hi_x.to_float() * PI
	if not s.origin:
		return GdcKit.zeros(f, lo, hi, 2000)
	var pos := GdcKit.zeros(f, 1e-6, hi, 2000)
	var out: Array = []
	if lo < 0.0:
		for i in range(pos.size() - 1, -1, -1):
			out.append(-pos[i])
	out.append(0.0)
	return out + pos


## Clear crossings: well apart, off the ends, and no near miss of the two curves.
static func vs_clean(s: Dictionary, xs: Array) -> bool:
	var f := func(x: float) -> float: return vs_trig(s, x) - vs_rhs(s, x)
	var lo: float = s.lo_x.to_float() * PI
	var hi: float = s.hi_x.to_float() * PI
	for i in xs.size():
		if absf(xs[i]) > 1e-6 and (absf(xs[i] - lo) < 0.15 or absf(xs[i] - hi) < 0.15):
			return false
		if i > 0 and xs[i] - xs[i - 1] < 0.3:
			return false
		var h := 1e-5
		if absf(f.call(xs[i] + h) - f.call(xs[i] - h)) / (2.0 * h) < 0.12:
			return false
	if s.origin and s.lo_x.is_zero():
		return _no_near_miss(f, lo + 0.05, hi)
	return absf(f.call(lo)) > 0.05 and _no_near_miss(f, lo, hi)


static func _no_near_miss(f: Callable, lo: float, hi: float) -> bool:
	var n := 1600
	var a: float = f.call(lo)
	var b: float = f.call(lo + (hi - lo) / n)
	for i in range(2, n + 1):
		var c: float = f.call(lo + (hi - lo) * i / n)
		if (b - a) * (c - b) < 0.0 and absf(b) < 0.06:
			return false
		a = b
		b = c
	return absf(b) > 0.05


static func vs_list(xs: Array) -> Dictionary:
	return Answer.xs_of(xs.map(func(x): return GdcKit.qf(x)))


func vs_view(rep: String, s: Dictionary) -> Dictionary:
	var eq := "%s, for %s, with x in radians." % [vs_eq(s), vs_ends(s)]
	if rep != "graph":
		return {"lines": [eq], "graph": null}
	var lo: float = s.lo_x.to_float() * PI
	var hi: float = s.hi_x.to_float() * PI
	var trig := func(x: float) -> float: return vs_trig(s, x)
	var other := func(x: float) -> float: return vs_rhs(s, x)
	var span: float = absf(s.a.to_float())
	var y_hi: float = maxf(span, 1.0) if s.vs == "exp" else maxf(span, minf(absf(vs_rhs(s, hi)), 2.0 * span))
	var y_lo: float = -y_hi
	var cap := func(x: float) -> float:
		var y: float = other.call(x)
		return y if y <= y_hi + 0.5 and y >= y_lo - 0.5 else NAN
	var g := Plot.spec([Plot.sample(trig, lo, hi), Plot.sample(cap, lo, hi)], [], floori(lo), ceili(hi), floori(y_lo) - 1, ceili(y_hi) + 1)
	g.x_ticks = TrigKit.pi_ticks(s.lo_x, s.hi_x, Q.new(1, 2) if (s.hi_x.sub(s.lo_x)).to_float() <= 3.0 else Q.new(1))
	g.x_name = "x"
	g.y_name = "y"
	return {"lines": [eq, "The graph shows y = %s and y = %s." % [vs_lhs_text(s), vs_rhs_text(s)]], "graph": g}


func vs_gdc(s: Dictionary, xs: Array, a: Dictionary) -> Dictionary:
	return method(["Graph y = %s and y = %s in radian mode, with the window %s." % [vs_lhs_text(s), vs_rhs_text(s), vs_ends(s)],
		"No algebra rearranges this, so use intersect on each crossing: x = %s." % list(xs), say(a)], a.values)


func vs_sketch(s: Dictionary, xs: Array, a: Dictionary) -> Dictionary:
	var shape: String = "a line through the origin" if s.vs == "line" and s.origin else ("a line" if s.vs == "line" else "a falling curve")
	return method(["Sketch the wave and %s over %s: they cross %d times, so there are %d solutions to find." % [shape, vs_ends(s), xs.size(), xs.size()],
		"Solve near each crossing with the calculator, in radians: x = %s." % list(xs), say(a)], a.values)


func vs_solve(rep: String, s: Dictionary) -> Dictionary:
	var xs := vs_roots(s)
	var a := Answer.make("xs", vs_list(xs), {"var": "x"})
	a.show = "sf"
	var v := vs_view(rep, s)
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "sfs": xs.filter(func(x): return absf(x) > 1e-6), "asked": "Find every solution of %s for %s, to 3 significant figures." % [vs_eq(s), vs_ends(s)]}
	out.methods = {M_GDC: vs_gdc(s, xs, a), M_SKETCH: vs_sketch(s, xs, a)}
	return out


func u_solve_vs_line(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := vs_solve(rep, s)
	var xs := vs_roots(s)
	var right_side := xs.filter(func(x): return x > -1e-6)
	out.wrongs = [] if right_side.is_empty() else [wrong(vs_list(right_side), R_PART)]
	if s.origin:
		out.wrongs.append(wrong(vs_list(xs.filter(func(x): return absf(x) > 1e-6)), R_ORIGIN))
	var deg := vs_roots(s, true)
	if not deg.is_empty():
		out.wrongs.append(wrong(vs_list(deg), R_GDC_DEGREES))
	out.generic = [vs_list(xs.map(func(x): return x + 0.5)), vs_list(xs.map(func(x): return x * 1.25)), vs_list(xs.map(func(x): return x - 0.25)), vs_list(xs + [xs[xs.size() - 1] + 1.0])]
	return out


func u_solve_vs_exp(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var out := vs_solve(rep, s)
	var xs := vs_roots(s)
	out.wrongs = [wrong(vs_list(xs.slice(0, xs.size() - 1)), R_PART)]
	var deg := vs_roots(s, true)
	if not deg.is_empty():
		out.wrongs.append(wrong(vs_list(deg), R_GDC_DEGREES))
	out.generic = [vs_list(xs.map(func(x): return x + 0.5)), vs_list(xs.map(func(x): return x * 1.25)), vs_list(xs.map(func(x): return x + 0.25)), vs_list(xs + [xs[xs.size() - 1] + 1.0])]
	return out


func u_count_vs_line(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var xs := vs_roots(s)
	var n: int = xs.size()
	var a := plain("Number of solutions = ", Q.new(n))
	var v := vs_view(rep, s)
	var out := {"answer": a, "lines": v.lines, "graph": v.graph, "asked": "Find the number of solutions of %s for %s." % [vs_eq(s), vs_ends(s)]}
	var amp: Q = s.a.abs_q()
	var reach: float = amp.to_float() / s.m.to_float()
	var hi: float = s.hi_x.to_float() * PI
	var lo: float = s.lo_x.to_float() * PI
	out.wrongs = []
	var waves := floori((hi - lo) * s.bq.to_float() / TAU + 1e-9)
	if reach < hi and 2 * waves != n:
		out.wrongs.append(wrong({"v": Q.new(2 * waves)}, R_EVERY_CYCLE))
	if lo < 0.0:
		var right_side := xs.filter(func(x): return x > 1e-6).size()
		if right_side != n and right_side > 0:
			out.wrongs.append(wrong({"v": Q.new(right_side)}, R_PART))
	if s.origin:
		out.wrongs.append(wrong({"v": Q.new(n - 1)}, R_ORIGIN))
	var deg := vs_roots(s, true).size()
	if deg != n:
		out.wrongs.append(wrong({"v": Q.new(deg)}, R_GDC_DEGREES))
	out.wrongs = spun(out.wrongs, s)
	out.generic = [{"v": Q.new(n + 1)}, {"v": Q.new(n + 2)}, {"v": Q.new(maxi(n - 2, 1))}, {"v": Q.new(2 * n)}]
	var said := "Number of solutions = %d." % n
	var bound := "The wave stays between −%s and %s, and the line is outside that once the size of x passes %s ÷ %s = %s." % [D(amp), D(amp), D(amp), D(s.m), GdcKit.W(reach)]
	var widest: float = maxf(hi, -lo)
	var inside_: String = "So no crossing is further from the origin than x = %s, and the humps inside that are all that count." % GdcKit.W(reach) if reach < widest else "The interval stops before that, so the line stays inside the band all the way across."
	var by_side: String
	if lo < 0.0:
		by_side = "Counting along the sketch gives %d crossings left of the y-axis, %d right of it and %d at the origin." % [xs.filter(func(x): return x < -1e-6).size(), xs.filter(func(x): return x > 1e-6).size(), 1 if s.origin else 0]
	else:
		by_side = "Counting along the sketch from x = 0 gives %d crossings%s." % [n, " with the one at the origin" if s.origin else ""]
	out.methods = {M_SKETCH: method(["Sketch y = %s and y = %s over %s." % [vs_lhs_text(s), vs_rhs_text(s), vs_ends(s)], by_side, said], a.values),
		M_RANGE: method([bound, inside_, by_side.replace("along the sketch", "hump by hump inside the band"), said], a.values),
		M_GDC: method(["Graph y = %s and y = %s in radian mode, with the window %s." % [vs_lhs_text(s), vs_rhs_text(s), vs_ends(s)], "Intersect finds them from x = %s to x = %s, and there are %d in all." % [GdcKit.W(xs[0]), GdcKit.W(xs[n - 1]), n], said], a.values)}
	return out
