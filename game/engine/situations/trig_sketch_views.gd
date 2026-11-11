class_name TrigSketchViews
extends ExtensionViews
## The views on the `trig-sketch` situation (FAL-754): t3-trig-sketch, a circular function sketched
## on a given domain. Students can't draw on a phone, so the three sketches are pick-the-graph
## questions: four cards that share one window and one set of axis marks, each wrong card one slip
## (tan drawn with turning points, a cosine started on its axis, straight lines for a curve, the wrong
## period, a missed reflection, d the wrong way). The rest ask what a sketch must mark, typed: its
## maximum and minimum points, where it meets the axes, tan's asymptotes and the five key points.
## Paper 1 is exact, as a multiple of π or in degrees. The GDC's cells are Paper 2: a sketch keeps its
## Paper 1 numbers, and a maximum point or an intercept is on a wave with tenths, to 3 s.f.
##
## Representations: "equation" (y = 3 sin(2x) + 1, for 0 ≤ x ≤ 2π), "table" (five key points of one
## period) and "graph" (the sketch drawn with nothing marked, to find its x-intercepts). Every card's
## curve is sampled in radians; a degree domain only labels the axis in degrees.

const R_TAN_TURN := "SL3.7.sketch#0"
const R_COS_AXIS := "SL3.7.sketch#1"
const R_ZIGZAG := "SL3.7.sketch#2"
const R_D_WAY := "SL3.7.sketch#3"
const R_BASE := "SL3.7.sketch#4"
const R_TAN_ZEROS := "SL3.7.sketch#5"
const R_SIN_PEAK := "SL3.7.sketch#6"
const R_TAN_SIN := "SL3.7.read-features#3"
const R_SIN_TAN := "SL3.7.read-features#4"
const R_NO_D := "SL3.7.read-features#5"
const R_MINUS := "SL3.7.read-features#8"
const R_PEAKS := "SL3.7.read-features#9"
const R_ONE := "SL3.8.solve-basic#0"
const R_COS_AS_SIN := "SL3.8.solve-basic#1"

const QPP := "quarter-period-points"
const TB := "transform-base"
const GDC := "gdc-transfer"
const UNKNOWNS := ["sketch-wave", "sketch-from-table", "sketch-reflected", "sketch-tan", "max-min-points", "y-intercept", "x-intercepts", "tan-asymptotes", "key-points"]
## fn at 0, ¼, ½, ¾ and 1 of a period.
const PATTERN := {"sin": [0, 1, 0, -1, 0], "cos": [1, 0, -1, 0, 1]}
## How far beyond its centre a tan card is drawn, in units of |a|.
const TAN_CLIP := 3.0


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## The GDC needs Paper 2; everything else is Paper 1, as both bank parts are.
func papers(unknown: String, _rep: String, method_id: String) -> Array:
	if not has(unknown):
		return []
	return [2] if method_id == GDC else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = TrigSketchSituation.export(s)
	said_once(out.methods, out.answer)
	return out


# ── Writing the function ─────────────────────────────────────

static func D(v: Variant) -> String:
	return Fmt.dec(v)


## The number in front: "", "−", "3 ", "−2.5 ".
static func lead(a: Q) -> String:
	if a.eq(1):
		return ""
	return "−" if a.eq(-1) else D(a) + " "


## fn(bx) as the question writes it: "sin x", "cos(2x)", "tan(x/2)", "sin(1.3x)".
static func call_of(fn: String, b: Q) -> String:
	if b.eq(1):
		return fn + " x"
	return "%s(%s)" % [fn, bx_text(b)]


## bx alone: "2x", "x/2", "1.3x".
static func bx_text(b: Q) -> String:
	if b.eq(1):
		return "x"
	if b.is_int() or b.d == 10:
		return D(b) + "x"
	return "%sx/%d" % ["" if b.n == 1 else str(b.n), b.d]


static func fn_text(a: Q, fn: String, b: Q, d: Q) -> String:
	return lead(a) + call_of(fn, b) + TrigWaveViews.tail(d)


static func f_text(s: Dictionary) -> String:
	return fn_text(s.a, s.fn, s.b, s.d)


## A place across: a multiple of π, degrees, or a plain number on Paper 2.
static func X(s: Dictionary, v: Q) -> String:
	if s.kind == "dec":
		return D(v)
	return TrigKit.angle(v, s.form)


static func domain(s: Dictionary) -> String:
	return "%s ≤ x ≤ %s" % [X(s, s.lo), X(s, s.hi)]


static func eq_line(s: Dictionary) -> String:
	return "y = %s, for %s" % [f_text(s), domain(s)]


static func per(s: Dictionary) -> Q:
	return TrigSketchSituation.period(s)


## "a, b and c".
static func list_of(names: Array) -> String:
	if names.size() <= 1:
		return names[0] if names.size() == 1 else ""
	return ", ".join(names.slice(0, names.size() - 1)) + " and " + names[-1]


## b as a number to divide by: "3", "(1/2)", "1.3".
static func B(b: Q) -> String:
	if b.is_int() or b.d == 10:
		return D(b)
	return "(%s)" % Fmt.num(b)


## A slot's value: the Q of π, or its degrees.
static func slot_value(s: Dictionary, x: Q) -> Q:
	return x.mul(180) if s.form == "deg" else x


static func unit(s: Dictionary) -> String:
	return "°" if s.form == "deg" else "π"


## y at a place given as a Q of π, exactly: d + a × fn's landmark there (sin and cos only).
static func y_at(s: Dictionary, x: Q, fn: String = "", a: Variant = null, d: Variant = null) -> Q:
	var f: String = s.fn if fn == "" else fn
	var aa: Q = s.a if a == null else a
	var dd: Q = s.d if d == null else d
	var v := TrigKit.of(f, x.mul(s.b))
	return dd.add(aa.mul(v[0])) if v.size() > 0 else dd


# ── Cards ────────────────────────────────────────────────────

## The domain in radians.
static func span(s: Dictionary) -> Array:
	if s.kind == "dec":
		return [s.lo.to_float(), s.hi.to_float()]
	return [s.lo.to_float() * PI, s.hi.to_float() * PI]


static func f_of(a: float, fn: String, b: float, d: float) -> Callable:
	match fn:
		"sin":
			return func(x: float) -> float: return a * sin(b * x) + d
		"cos":
			return func(x: float) -> float: return a * cos(b * x) + d
	return func(x: float) -> float: return a * tan(b * x) + d


static func wave_f(s: Dictionary) -> Callable:
	return f_of(s.a.to_float(), s.fn, s.b.to_float(), s.d.to_float())


## Straight lines through the key points, a quarter of a period apart from the start of the domain.
static func zigzag_f(s: Dictionary) -> Callable:
	var f := wave_f(s)
	var lo: float = span(s)[0]
	var q: float = per(s).to_float() * PI / 4.0
	return func(x: float) -> float:
		var i := floori((x - lo) / q + 1e-9)
		var x0 := lo + i * q
		var y0: float = f.call(x0)
		var y1: float = f.call(x0 + q)
		return y0 + (y1 - y0) * (x - x0) / q


## The axis marks, a quarter of the domain apart.
static func ticks(s: Dictionary) -> Array:
	var step: Q = s.hi.sub(s.lo).div(4)
	var out: Array = []
	for k in 5:
		var t: Q = s.lo.add(step.mul(k))
		if not t.is_zero():
			out.append([t.to_float() * PI, X(s, t)])
	return out


## Every sample's turning points and the two ends, as dots: each card marks its own the same way.
static func dots_of(curve: Array) -> Array:
	var out: Array = [[curve[0][0], curve[0][1], ""]]
	for i in range(1, curve.size() - 1):
		var a: float = curve[i][1] - curve[i - 1][1]
		var b: float = curve[i + 1][1] - curve[i][1]
		if a * b < 0.0:
			out.append([curve[i][0], curve[i][1], ""])
	out.append([curve[-1][0], curve[-1][1], ""])
	return out


static func sample(s: Dictionary, f: Callable) -> Array:
	var w := span(s)
	return GdcKit.curve(f, w[0], w[1])


## A sin or cos card window holding every card's curve, with the x-axis in it.
static func wave_win(s: Dictionary, fs: Array) -> Array:
	var lo := 0.0
	var hi := 0.0
	for f in fs:
		for p in sample(s, f):
			lo = minf(lo, p[1])
			hi = maxf(hi, p[1])
	var w := span(s)
	return [floori(w[0]), ceili(w[1]), floori(lo) - 1, ceili(hi) + 1]


static func card(s: Dictionary, curves: Array, dots: Array, win: Array, vlines: Array = []) -> Dictionary:
	var g := GdcKit.card(curves, dots, win, vlines)
	g.x_ticks = ticks(s)
	g.one_colour = true
	return g


static func wave_card(s: Dictionary, f: Callable, win: Array) -> Dictionary:
	var c := sample(s, f)
	return card(s, [c], dots_of(c), win)


static func one_wrong(graph: Dictionary, mistake: String, ref: String, why: String) -> Dictionary:
	return {"graph": graph, "mistake": mistake, "ref": ref, "why": why}


## A question's slips, starting at its spin, so each shows up across the seeds.
static func spun(items: Array, spin: int) -> Array:
	if items.is_empty():
		return items
	var at := spin % items.size()
	return items.slice(at) + items.slice(0, at)


static func ending(letter: String) -> String:
	return "So the sketch is %s." % letter


static func start_text(s: Dictionary, f: Callable) -> String:
	return "(%s, %s)" % [X(s, s.lo), D(GdcKit.qf(f.call(span(s)[0])))]


# ── Five key points ──────────────────────────────────────────

## The five key points of the period that starts at x0 (a Q of π): [[x, y], ...].
static func key_points(s: Dictionary, x0: Q, fn: String = "", a: Variant = null, d: Variant = null) -> Array:
	var q := per(s).div(4)
	var out: Array = []
	for i in 5:
		var x := x0.add(q.mul(i))
		out.append([x, y_at(s, x, fn, a, d)])
	return out


static func points_text(s: Dictionary, pts: Array) -> String:
	return list_of(pts.map(func(p): return "(%s, %s)" % [X(s, p[0]), D(p[1])]))


static func quarter_line(s: Dictionary) -> String:
	var base := "π" if s.fn == "tan" else "2π"
	if s.form == "deg":
		base = "180°" if s.fn == "tan" else "360°"
	var P := "%s ÷ %s = %s" % [base, B(s.b), X(s, per(s))] if not s.b.eq(1) else base
	return "One period is %s, so the key points are a quarter of that, %s, apart." % [P, X(s, per(s).div(4))]


static func pattern_line(s: Dictionary) -> String:
	if s.fn == "sin":
		return "sin starts on its axis and goes up: axis, maximum, axis, minimum, axis, so fn is 0, 1, 0, −1, 0 at the five points."
	return "cos starts at its maximum: maximum, axis, minimum, axis, maximum, so fn is 1, 0, −1, 0, 1 at the five points."


static func base_line(s: Dictionary) -> String:
	var full := "360°" if s.form == "deg" else "2π"
	if s.fn == "sin":
		return "y = sin x starts on its axis at (0, 0), rises to 1, and repeats every %s." % full
	return "y = cos x starts at its maximum (0, 1), falls to −1, and repeats every %s." % full


## What a, b and d do to the base graph, in one line.
static func stretch_line(s: Dictionary) -> String:
	var parts: PackedStringArray = []
	if not s.b.eq(1):
		parts.append("b = %s makes the period %s ÷ %s = %s" % [Fmt.num(s.b), "360°" if s.form == "deg" else "2π", B(s.b), X(s, per(s))])
	var size: Q = s.a.abs_q()
	if s.a.sign() < 0:
		parts.append("the minus sign reflects it in its axis")
	if not size.eq(1):
		parts.append("%s stretches it to %s above and below its axis" % [D(size), D(size)])
	if not s.d.is_zero():
		parts.append("d = %s moves it %s %s, so its axis is y = %s" % [D(s.d), "up" if s.d.sign() > 0 else "down", D(s.d.abs_q()), D(s.d)])
	if parts.is_empty():
		return "Nothing else changes."
	return "Then " + "; ".join(parts) + "."


static func gdc_line(s: Dictionary) -> String:
	var w := span(s)
	return "Graph y = %s in radian mode, with the window %s ≤ x ≤ %s." % [f_text(s), Fmt.work(w[0], 3), Fmt.work(w[1], 3)]


# ── The sketches ─────────────────────────────────────────────

## The slips a sin or cos card can show, in order; spun() takes three.
func wave_wrongs(s: Dictionary, win_fs: Array, reflected: bool) -> Array:
	var a: float = s.a.to_float()
	var b: float = s.b.to_float()
	var d: float = s.d.to_float()
	var other := "cos" if s.fn == "sin" else "sin"
	var mk: Array = []
	var f := wave_f(s)
	var g := f_of(a, other, b, d)
	var start_ref := R_COS_AXIS if s.fn == "cos" else R_PEAKS
	mk.append(["start", g, start_ref, "it starts at %s, but y = %s starts at %s" % [start_text(s, g), f_text(s), start_text(s, f)]])
	mk.append(["zigzag", zigzag_f(s), R_ZIGZAG, "it joins the key points with straight lines, and a wave is a smooth curve"])
	if s.b.eq(1):
		var p2 := per(s).div(2)
		mk.append(["period", f_of(a, s.fn, 2.0 * b, d), R_SIN_TAN, "its period is %s, but %s repeats every %s" % [X(s, p2), call_of(s.fn, s.b), X(s, per(s))]])
	else:
		mk.append(["period", f_of(a, s.fn, 1.0, d), R_BASE, "its period is %s, the period of %s x, not %s" % [X(s, Q.new(2)), s.fn, X(s, per(s))]])
	if not s.d.is_zero():
		mk.append(["shift", f_of(a, s.fn, b, -d), R_D_WAY, "its axis is y = %s, but d = %s puts it at y = %s" % [D(s.d.neg()), D(s.d), D(s.d)]])
	if reflected:
		mk.append(["unflipped", f_of(-a, s.fn, b, d), R_MINUS, "it is y = %s, with no reflection for the minus sign" % fn_text(s.a.neg(), s.fn, s.b, s.d)])
	else:
		mk.append(["flipped", f_of(-a, s.fn, b, d), "", "it is reflected in its axis: it is y = %s" % fn_text(s.a.neg(), s.fn, s.b, s.d)])
	var picked := spun(mk, s.spin).slice(0, 3)
	for m in picked:
		win_fs.append(m[1])
	return picked


func _wave_pick(rep: String, s: Dictionary, rng: Seeded, reflected: bool) -> Dictionary:
	var f := wave_f(s)
	var fs: Array = [f]
	var picked := wave_wrongs(s, fs, reflected)
	var win := wave_win(s, fs)
	var wrongs: Array = picked.map(func(m): return one_wrong(wave_card(s, m[1], win), m[0], m[2], m[3]))
	var pk := GdcKit.pick(wave_card(s, f, win), wrongs, rng)
	var ans: Dictionary = pk.answer
	var letter: String = ans.values.v
	var kp := key_points(s, s.lo)
	var out := {"answer": ans, "graphs": pk.graphs, "lines": [eq_line(s)], "asked": "Which graph is the sketch of the function on this domain?"}
	var top: Q = s.d.add(s.a.abs_q())
	var low: Q = s.d.sub(s.a.abs_q())
	if rep == "table":
		out.lines = ["f is a sine or cosine wave. The table gives its five key points over one period, %s." % domain(s)]
		out.table = key_table(s, kp, [])
		out.asked = "Which graph shows y = f(x) on this domain?"
		out.methods = {QPP: method(["Plot the five points: %s." % points_text(s, kp),
			"They are a quarter of a period apart, and fn's pattern between them is that of %s." % ("a sine wave: axis, maximum, axis, minimum, axis" if s.fn == "sin" else "a cosine wave: maximum, axis, minimum, axis, maximum") if not reflected else "",
			"Join them with a smooth wave, rounded at the top and bottom, not with straight lines.", ending(letter)], ans.values)}
		out.methods[QPP].steps = out.methods[QPP].steps.filter(func(t): return t != "")
		return out
	var reps := 1 if s.hi.eq(per(s)) else 0
	var more := "" if reps == 1 else " Repeat them every %s to the end of the domain, x = %s." % [X(s, per(s)), X(s, s.hi)]
	out.methods = {
		QPP: method([quarter_line(s), pattern_line(s) + " With a = %s and d = %s, y = %s." % [D(s.a), D(s.d), list_of(kp.map(func(p): return D(p[1])))],
			"Plot %s and join them with a smooth wave.%s" % [points_text(s, kp), more], ending(letter)], ans.values),
		TB: method([base_line(s), stretch_line(s), "So it runs between y = %s and y = %s and starts at %s." % [D(low), D(top), start_text(s, f)], ending(letter)], ans.values),
		GDC: method([gdc_line(s), "Copy its shape: it starts at %s and runs between y = %s and y = %s, repeating every %s." % [start_text(s, f), D(low), D(top), X(s, per(s))], ending(letter)], ans.values),
	}
	return out


func u_sketch_wave(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _wave_pick(rep, s, rng, false)


func u_sketch_from_table(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _wave_pick("table", s, rng, false)


func u_sketch_reflected(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _wave_pick(rep, s, rng, true)


## a tan(bx) + d, cut off TAN_CLIP |a| either side of d, split into its branches.
static func tan_curves(s: Dictionary, f: Callable, d: float) -> Array:
	var c: float = TAN_CLIP * s.a.abs_q().to_float()
	var w := span(s)
	var pts: Array = []
	var n := 480
	for i in n + 1:
		var x: float = w[0] + (w[1] - w[0]) * i / n
		var y: float = f.call(x)
		if is_finite(y) and absf(y - d) <= c:
			pts.append([x, y])
	var out: Array = [[]]
	var gap: float = 1.5 * (w[1] - w[0]) / n
	for i in pts.size():
		if i > 0 and (pts[i][0] - pts[i - 1][0] > gap or absf(pts[i][1] - pts[i - 1][1]) > c):
			out.append([])
		out[-1].append(pts[i])
	return out.filter(func(b): return b.size() > 1)


## Where tan(kx + shift) has its asymptotes on the domain, in radians.
static func asym_at(s: Dictionary, k: float, shift: float) -> Array:
	var w := span(s)
	var out: Array = []
	for m in range(-4, 20):
		var x := (PI / 2.0 + m * PI - shift) / k
		if x >= w[0] - 1e-9 and x <= w[1] + 1e-9:
			out.append([x, ""])
	return out


static func tan_card(s: Dictionary, a: float, k: float, shift: float, d: float, win: Array) -> Dictionary:
	var f := func(x: float) -> float: return a * tan(k * x + shift) + d
	var curves := tan_curves(s, f, d)
	var dots: Array = []
	for c in curves:
		for i in range(1, c.size()):
			if (c[i - 1][1] - d) * (c[i][1] - d) < 0.0 or c[i - 1][1] == d:
				dots.append([c[i - 1][0], c[i - 1][1], ""])
	return card(s, curves, dots, win, asym_at(s, k, shift))


func u_sketch_tan(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: float = s.a.to_float()
	var b: float = s.b.to_float()
	var d: float = s.d.to_float()
	var c: float = TAN_CLIP * absf(a)
	var win := [floori(span(s)[0]), ceili(span(s)[1]), floori(minf(0.0, d - c - absf(d) * 2.0)) - 1, ceili(maxf(0.0, d + c + absf(d) * 2.0)) + 1]
	var P := per(s)
	var asym := list_of([P.div(2), P.mul(Q.new(3, 2))].map(func(x): return "x = " + X(s, x)))
	var mk: Array = []
	var turn := f_of(2.0 * a, "sin", b, d)
	var turn_card := card(s, [sample(s, turn)], dots_of(sample(s, turn)), win)
	mk.append(one_wrong(turn_card, "turning", R_TAN_TURN, "it turns at %s, where the graph has vertical asymptotes" % asym))
	mk.append(one_wrong(tan_card(s, a, b / 2.0, 0.0, d, win), "period", R_TAN_SIN, "its period is %s, but tan's period is π ÷ b = %s" % [X(s, P.mul(2)), X(s, P)]))
	mk.append(one_wrong(tan_card(s, a, b, PI / 2.0, d, win), "zeros", R_TAN_ZEROS, "its asymptotes are at x = %s, where %s is 0, not halfway between those" % [list_of([Q.new(0), P, P.mul(2)].map(func(x): return X(s, x))), call_of("tan", s.b)]))
	if a < 0.0:
		mk.append(one_wrong(tan_card(s, -a, b, 0.0, d, win), "unflipped", R_MINUS, "it is y = %s, with no reflection for the minus sign" % fn_text(s.a.neg(), "tan", s.b, s.d)))
	if d != 0.0:
		mk.append(one_wrong(tan_card(s, a, b, 0.0, -d, win), "shift", R_D_WAY, "its branches cross y = %s, but d = %s centres them on y = %s" % [D(s.d.neg()), D(s.d), D(s.d)]))
	if a > 0.0 and d == 0.0:
		mk.append(one_wrong(tan_card(s, -a, b, 0.0, d, win), "flipped", "", "it is reflected: it is y = %s" % fn_text(s.a.neg(), "tan", s.b, s.d)))
	var pk := GdcKit.pick(tan_card(s, a, b, 0.0, d, win), spun(mk, s.spin).slice(0, 3), rng)
	var ans: Dictionary = pk.answer
	var letter: String = ans.values.v
	var q := P.div(4)
	var near := "(%s, %s) and (%s, %s)" % [X(s, q), D(s.d.add(s.a)), X(s, q.mul(3)), D(s.d.sub(s.a))]
	var out := {"answer": ans, "graphs": pk.graphs, "lines": [eq_line(s)], "asked": "Which graph is the sketch of the function on this domain?"}
	var base := "x = π/2 + kπ" if s.form == "pi" else "x = 90° + k × 180°"
	out.methods = {
		QPP: method([quarter_line(s), "From x = 0 the points go: (0, %s) on its centre line, then %s a quarter of a period on. Each asymptote is half a period from a centre-line crossing: on this domain, %s." % [D(s.d), "(%s, %s)" % [X(s, q), D(s.d.add(s.a))], asym],
			"Each branch %s through its centre line, from one asymptote to the next, with no turning point." % ("rises" if a > 0.0 else "falls"), ending(letter)], ans.values),
		TB: method(["y = tan x crosses the x-axis at x = 0, rises with no turning point, and has vertical asymptotes at %s." % base,
			("b = %s makes the period %s ÷ %s = %s, and the asymptotes on this domain are at %s." % [Fmt.num(s.b), "180°" if s.form == "deg" else "π", B(s.b), X(s, P), asym] if not s.b.eq(1) else "With b = 1 the period stays %s, and the asymptotes on this domain are at %s." % [X(s, P), asym]),
			tan_stretch_line(s) + " The graph passes through %s." % near, ending(letter)], ans.values),
		GDC: method([gdc_line(s), "Copy its branches: each %s through y = %s, and the GDC's steep jumps mark the asymptotes at %s." % ["rises" if a > 0.0 else "falls", D(s.d), asym], ending(letter)], ans.values),
	}
	return out


## What a and d do to tan, in one line.
static func tan_stretch_line(s: Dictionary) -> String:
	var parts: PackedStringArray = []
	if s.a.sign() < 0:
		parts.append("the minus sign reflects it, so each branch falls")
	if not s.a.abs_q().eq(1):
		parts.append("%s stretches it vertically by %s" % [D(s.a.abs_q()), D(s.a.abs_q())])
	if not s.d.is_zero():
		parts.append("d = %s moves it %s %s, centring each branch on y = %s" % [D(s.d), "up" if s.d.sign() > 0 else "down", D(s.d.abs_q()), D(s.d)])
	if parts.is_empty():
		return "Nothing else changes."
	return "Then " + "; ".join(parts) + "."


# ── The features of a sketch ─────────────────────────────────

## Where the maximum and minimum are, as Qs of π: the first after the start of the domain.
static func turn_places(s: Dictionary, fn: String, a_sign: int, P: Q) -> Array:
	var top := Q.new(1, 4) if fn == "sin" else Q.new(0)
	if a_sign < 0:
		top = top.add(Q.new(1, 2))
	var low := top.add(Q.new(1, 2))
	var out: Array = []
	for t in [top, low]:
		var x: Q = t.mul(P)
		while x.lt(s.lo):
			x = x.add(P)
		while s.lo.add(P).lt(x) or s.lo.add(P).eq(x):
			x = x.sub(P)
		out.append(x)
	return out


static func mm_text(s: Dictionary, xt: Q, top: Q, xl: Q, low: Q) -> String:
	return "Maximum (%s, %s), minimum (%s, %s)" % [X(s, xt), D(top), X(s, xl), D(low)]


static func mm_slots(s: Dictionary, xt: Q, top: Q, xl: Q, low: Q) -> Dictionary:
	return {"p": slot_value(s, xt), "m": top, "q": slot_value(s, xl), "n": low}


static func mm_alt(s: Dictionary, v: Array, ref: String = "") -> Dictionary:
	return DifferentiationViews.alt(mm_text(s, v[0], v[1], v[2], v[3]), ref, mm_slots(s, v[0], v[1], v[2], v[3]))


func u_max_min_points(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	if s.kind == "dec":
		return _dec_max_min(rep, s, rng)
	var P := per(s)
	var size: Q = s.a.abs_q()
	var top: Q = s.d.add(size)
	var low: Q = s.d.sub(size)
	var at := turn_places(s, s.fn, s.a.sign(), P)
	var u := unit(s)
	var a := DifferentiationViews.form(mm_text(s, at[0], top, at[1], low),
		["Maximum (", {"slot": "p"}, u, ", ", {"slot": "m"}, "), minimum (", {"slot": "q"}, u, ", ", {"slot": "n"}, ")"], mm_slots(s, at[0], top, at[1], low))
	var out := {"answer": a, "lines": [eq_line(s)], "asked": "Write down the coordinates of the maximum point and of the minimum point on this domain."}
	var other := "cos" if s.fn == "sin" else "sin"
	var ot := turn_places(s, other, s.a.sign(), P)
	out.wrongs = [mm_alt(s, [ot[0], top, ot[1], low], R_COS_AXIS if s.fn == "cos" else R_PEAKS)]
	if s.a.sign() < 0:
		var un := turn_places(s, s.fn, 1, P)
		out.wrongs.append(mm_alt(s, [un[0], top, un[1], low], R_MINUS))
	if not s.d.is_zero():
		out.wrongs.append(mm_alt(s, [at[0], size, at[1], size.neg()], R_NO_D))
		out.wrongs.append(mm_alt(s, [at[0], s.d.neg().add(size), at[1], s.d.neg().sub(size)], R_D_WAY))
	var pw := Q.new(2) if not s.b.eq(1) else P.div(2)
	var w := turn_places(s.merged({"lo": Q.new(0)}, true), s.fn, s.a.sign(), pw)
	out.wrongs.append(mm_alt(s, [w[0], top, w[1], low], R_BASE if not s.b.eq(1) else R_SIN_TAN))
	out.wrongs = spun(out.wrongs, s.spin)
	out.generic = [mm_alt(s, [at[1], top, at[0], low]).values, mm_alt(s, [at[0], low, at[1], top]).values, mm_alt(s, [at[0], top.add(1), at[1], low.sub(1)]).values,
		mm_alt(s, [at[0], s.a.add(s.d), at[1], s.d]).values, mm_alt(s, [at[0].add(P.div(4)), top, at[1].add(P.div(4)), low]).values]
	var kp := key_points(s, s.lo)
	var top_line := "The highest of them is (%s, %s) and the lowest (%s, %s)." % [X(s, at[0]), D(top), X(s, at[1]), D(low)]
	var base_max := "π/2" if s.fn == "sin" else "0"
	var base_min := "3π/2" if s.fn == "sin" else "π"
	if s.form == "deg":
		base_max = "90°" if s.fn == "sin" else "0°"
		base_min = "270°" if s.fn == "sin" else "180°"
	var swap := " The minus sign reflects it, so the maximum and minimum swap places." if s.a.sign() < 0 else ""
	out.methods = {
		QPP: method([quarter_line(s), "From x = %s the key points are %s." % [X(s, s.lo), points_text(s, kp)], top_line, say(a)], a.values),
		TB: method(["%s x has its maximum at x = %s and its minimum at x = %s.%s" % [s.fn, base_max, base_min, swap],
			"The heights are d ± |a| = %s ± %s: %s and %s." % [D(s.d), D(size), D(top), D(low)],
			"b = %s divides each x by %s, and on %s that puts the maximum at x = %s and the minimum at x = %s." % [Fmt.num(s.b), B(s.b), domain(s), X(s, at[0]), X(s, at[1])] if not s.b.eq(1) else "With b = 1, on %s that puts the maximum at x = %s and the minimum at x = %s." % [domain(s), X(s, at[0]), X(s, at[1])],
			say(a)], a.values),
	}
	return out


static func say(a: Dictionary) -> String:
	var text := Answer.text(a)
	return text + "." if text.begins_with("Maximum") else "So " + text + "."


func _dec_max_min(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var size: Q = s.a.abs_q()
	var top: Q = s.d.add(size)
	var low: Q = s.d.sub(size)
	var xt: float = s.tops[0]
	var xl: float = s.lows[0]
	var names := ["Maximum at x", "y", "minimum at x", "y"]
	var a := TrigModelViews.named(names, [GdcKit.qf(xt), top, GdcKit.qf(xl), low], true)
	var out := {"answer": a, "lines": [eq_line(s)], "asked": "Write down the coordinates of the maximum point and of the minimum point on this domain, to 3 significant figures."}
	var v := func(p: float, t: Q, q: float, l: Q) -> Dictionary: return TrigModelViews.named_vals([GdcKit.qf(p), t, GdcKit.qf(q), l])
	out.wrongs = [wrong(v.call(xt, size, xl, size.neg()), R_NO_D), wrong(v.call(xt, s.d.neg().add(size), xl, s.d.neg().sub(size)), R_D_WAY)]
	if s.a.sign() < 0:
		out.wrongs.append(wrong(v.call(xl, top, xt, low), R_MINUS))
	var T: float = TAU / s.b.to_float()
	var shift := T / 4.0 if s.fn == "cos" else -T / 4.0
	out.wrongs.append(wrong(v.call(xt + shift, top, xl + shift, low), R_COS_AXIS if s.fn == "cos" else R_PEAKS))
	out.wrongs = spun(out.wrongs, s.spin)
	out.generic = [v.call(xl, top, xt, low), v.call(xt, low, xl, top), v.call(xt * 2.0, top, xl * 2.0, low), v.call(xt, top.add(1), xl, low.sub(1))]
	out.methods = {GDC: method([gdc_line(s), "The maximum tool gives (%s, %s) and the minimum tool (%s, %s)." % [GdcKit.W(xt), D(top), GdcKit.W(xl), D(low)], say(a)], a.values)}
	return out


func u_y_intercept(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var y: Q = s.a.add(s.d) if s.fn == "cos" else s.d
	var a := Answer.make("yint", {"y": y})
	a.exact = true
	var out := {"answer": a, "lines": [eq_line(s)], "asked": "Write down the coordinates of the point where the sketch meets the y-axis."}
	var size: Q = s.a.abs_q()
	if s.fn == "cos":
		out.wrongs = [wrong({"y": s.d}, R_COS_AXIS), wrong({"y": s.a}, R_NO_D), wrong({"y": s.a.sub(s.d)}, R_D_WAY)]
		if s.a.sign() < 0:
			out.wrongs.append(wrong({"y": size.add(s.d)}, R_MINUS))
	else:
		out.wrongs = [wrong({"y": s.d.neg()}, R_D_WAY)]
		if s.fn == "sin":
			out.wrongs.append(wrong({"y": s.a.add(s.d)}, R_SIN_PEAK))
	out.wrongs = spun(out.wrongs, s.spin)
	out.generic = [{"y": s.d.add(1)}, {"y": s.a}, {"y": s.d.sub(size)}, {"y": s.d.add(size)}, {"y": Q.new(0)}, {"y": s.d.sub(1)}]
	var f0: String = {"sin": "sin 0 = 0", "cos": "cos 0 = 1", "tan": "tan 0 = 0"}[s.fn]
	var start: String = {"sin": "a sine period starts on its axis, y = d", "cos": "a cosine period starts at a %s, y = a + d" % ("maximum" if s.a.sign() > 0 else "minimum, as a is negative,"), "tan": "a tan branch is centred on y = d"}[s.fn]
	out.methods = {
		QPP: method(["The first key point is at x = 0, the start of a period: %s." % start, "y = %s" % ("%s + %s = %s" % [D(s.a), P(s.d), D(y)] if s.fn == "cos" else D(y)), say(a)], a.values),
		TB: method(["%s, so the base graph meets the y-axis at (0, %s)." % [f0, "1" if s.fn == "cos" else "0"],
			"Stretch by a and lift by d: y = %s × %s + %s = %s" % [P(s.a), "1" if s.fn == "cos" else "0", P(s.d), D(y)], say(a)], a.values),
	}
	return out


## The sketch with nothing marked, for the graph representation: its equation stays in the words.
static func plain_figure(out: Dictionary, rep: String, s: Dictionary) -> void:
	if rep != "graph":
		return
	var f := wave_f(s)
	var win := wave_win(s, [f])
	out.lines = ["The sketch shows y = %s, for %s, with nothing marked." % [f_text(s), domain(s)]]
	var g := Plot.spec([sample(s, f)], [], win[0], win[1], win[2], win[3])
	if s.kind != "dec":
		g.x_ticks = ticks(s)
	out.graph = g


static func xs_text(s: Dictionary, xs: Array) -> String:
	return "x = " + list_of(xs.map(func(x): return X(s, x)))


func u_x_intercepts(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	if s.kind == "dec":
		return _dec_zeros(rep, s)
	var xs: Array = s.xs
	var a := TrigEquationViews.xs_ans({"form": s.form, "xs": xs})
	var out := {"answer": a, "lines": [eq_line(s)], "asked": "Find the x-intercepts of the sketch on this domain."}
	plain_figure(out, rep, s)
	var k: Q = s.d.neg().div(s.a)
	var st := {"form": s.form, "xs": xs}
	var wrong_way := TrigSketchSituation.zeros_exact(s.fn, k.neg(), s.b)
	out.wrongs = TrigEquationViews.xs_alt(a, st, wrong_way, R_D_WAY)
	if s.fn == "cos":
		var al: Q = Q.new(1, 3) if k.sign() > 0 else Q.new(2, 3)
		out.wrongs += TrigEquationViews.xs_alt(a, st, [al.div(s.b), Q.new(1).sub(al).div(s.b)], R_COS_AS_SIN)
	if not s.b.eq(1):
		out.wrongs += TrigEquationViews.xs_alt(a, st, TrigSketchSituation.zeros_exact(s.fn, k, Q.new(1)), R_BASE)
	out.wrongs += TrigEquationViews.xs_alt(a, st, [xs[0]], R_ONE)
	out.wrongs = spun(out.wrongs, s.spin)
	var P := per(s)
	out.generic = TrigEquationViews.xs_others(a, st, [[xs[0], P.sub(xs[0])], [P.div(4).sub(xs[0].div(2)).abs_q().add(P.div(8)), xs[1]], [xs[0].add(P.div(4)), xs[1].add(P.div(4))], [xs[0].div(2), xs[1].div(2)]])
	var base := TrigSketchSituation.zeros_exact(s.fn, k, Q.new(1))
	var theta := "%s θ = %s at θ = %s" % [s.fn, Fmt.num(k), list_of(base.map(func(t): return TrigKit.angle(t, s.form)))]
	var last := "Here θ = x, so those are the intercepts." if s.b.eq(1) else "Here θ = %s, so divide by %s: x = %s." % [bx_text(s.b), B(s.b), list_of(xs.map(func(x): return X(s, x)))]
	out.methods = {TB: method(["The sketch meets the x-axis where %s = 0, so %s = −d ÷ a = %s." % [f_text(s), call_of(s.fn, s.b), Fmt.num(k)],
		"On the base graph, over one turn, " + theta + ".", last, say(a)], a.values)}
	return out


func _dec_zeros(rep: String, s: Dictionary) -> Dictionary:
	var xs: Array = s.xs
	var a := GdcCurveViews.xs_ans(xs)
	var out := {"answer": a, "lines": [eq_line(s)], "asked": "Find the x-intercepts of the sketch on this domain, to 3 significant figures."}
	plain_figure(out, rep, s)
	var hi: float = s.hi.to_float()
	var flip := TrigSketchSituation.dec_zeros(s.merged({"d": s.d.neg()}, true), 0.0, hi)
	out.wrongs = []
	if flip.size() >= 1:
		out.wrongs.append(wrong(Answer.xs_of(flip.map(func(x): return GdcKit.qf(x))), R_D_WAY))
	out.wrongs.append(wrong(Answer.xs_of(xs.slice(0, 1)), R_ONE))
	out.wrongs = spun(out.wrongs, s.spin)
	var x0: float = xs[0].to_float()
	var x1: float = xs[1].to_float()
	out.generic = [Answer.xs_of([GdcKit.qf(x0), GdcKit.qf(x1 + 0.5)]), Answer.xs_of([GdcKit.qf(x0 * 2.0), GdcKit.qf(x1 * 2.0)]), Answer.xs_of([GdcKit.qf(x0 / 2.0), GdcKit.qf(x1 / 2.0)]), Answer.xs_of([GdcKit.qf(x0 + 0.3), GdcKit.qf(x1 + 0.3)])]
	out.methods = {GDC: method([gdc_line(s), "The zero tool gives x = %s and x = %s." % [GdcKit.W(x0), GdcKit.W(x1)], "So " + Answer.text(a) + "."], a.values)}
	return out


## tan's asymptotes, two equations in any order: "x = π/4 and x = 3π/4".
static func asym_ans(s: Dictionary, xs: Array) -> Dictionary:
	var u := unit(s)
	var parts: Array = ["x = ", {"slot": "a0"}, u, " and x = ", {"slot": "a1"}, u]
	var out := DifferentiationViews.form(asym_text(s, xs), parts, {"a0": slot_value(s, xs[0]), "a1": slot_value(s, xs[1])})
	out.unordered = [["a0", "a1"]]
	return out


static func asym_text(s: Dictionary, xs: Array) -> String:
	var sorted := xs.duplicate()
	sorted.sort_custom(func(p, q): return p.lt(q))
	var ts: Array = sorted.map(func(x): return "x = " + X(s, x))
	return ", ".join(ts.slice(0, ts.size() - 1)) + " and " + ts[-1] if ts.size() > 1 else ts[0]


static func asym_alt(s: Dictionary, xs: Array, ref: String = "") -> Dictionary:
	var sorted := xs.duplicate()
	sorted.sort_custom(func(p, q): return p.lt(q))
	if xs.size() != 2:
		return DifferentiationViews.alt(asym_text(s, sorted), ref)
	return DifferentiationViews.alt(asym_text(s, sorted), ref, {"a0": slot_value(s, sorted[0]), "a1": slot_value(s, sorted[1])})


func u_tan_asymptotes(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var P := per(s)
	var xs: Array = [P.div(2), P.mul(Q.new(3, 2))]
	var a := asym_ans(s, xs)
	var out := {"answer": a, "lines": [eq_line(s)], "asked": "Write down the equations of the vertical asymptotes on this domain."}
	out.wrongs = [asym_alt(s, [Q.new(0), P, P.mul(2)], R_TAN_ZEROS), asym_alt(s, [P], R_TAN_SIN)]
	if not s.b.eq(1):
		out.wrongs.append(asym_alt(s, [Q.new(1, 2), Q.new(3, 2)], R_BASE))
	out.wrongs = spun(out.wrongs, s.spin)
	out.generic = [asym_alt(s, [P.div(4), P.mul(Q.new(3, 4))]).values, asym_alt(s, [P, P.mul(2)]).values, asym_alt(s, [P.div(2), P]).values, asym_alt(s, [P.div(2), P.mul(Q.new(5, 2))]).values, asym_alt(s, [P.mul(2), P.mul(3)]).values]
	var base := "x = π/2 + kπ" if s.form == "pi" else "x = 90° + k × 180°"
	var list := list_of(xs.map(func(x): return X(s, x)))
	out.methods = {
		QPP: method([quarter_line(s), "A tan period's key points are an asymptote, then y = d − a, d, d + a, then an asymptote: the branch through (0, %s) has its asymptotes half a period either side, at x = ±%s." % [D(s.d), X(s, P.div(2))],
			"Going on a period at a time, the asymptotes on %s are at x = %s." % [domain(s), list], say(a)], a.values),
		TB: method(["y = tan x has its vertical asymptotes at %s." % base,
			"b = %s divides every x by %s, and a and d don't move the asymptotes: x = %s + k × %s." % [Fmt.num(s.b), B(s.b), X(s, P.div(2)), X(s, P)] if not s.b.eq(1) else "With b = 1, and a and d moving no asymptote, they stay at x = %s + k × %s." % [X(s, P.div(2)), X(s, P)],
			"On %s that is x = %s." % [domain(s), list], say(a)], a.values),
	}
	return out


## The table of five key points; blanks (indices) read p and q.
static func key_table(s: Dictionary, kp: Array, blanks: Array) -> Dictionary:
	var ys: Array = []
	for i in kp.size():
		var at := blanks.find(i)
		ys.append(["p", "q"][at] if at >= 0 else D(kp[i][1]))
	return {"rows": [["x", kp.map(func(p): return X(s, p[0]))], ["y", ys]]}


func u_key_points(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var kp := key_points(s, s.lo)
	var bl: Array = s.blanks
	var vals := func(pts: Array) -> Array: return [pts[bl[0]][1], pts[bl[1]][1]]
	var right: Array = vals.call(kp)
	var a := TrigModelViews.named(["p", "q"], right, false)
	var out := {"answer": a, "lines": ["f(x) = %s. The table gives its five key points over one period, %s." % [f_text(s), domain(s)]], "asked": "Find p and q.",
		"table": key_table(s, kp, bl)}
	var other := "cos" if s.fn == "sin" else "sin"
	var nv := func(pts: Array) -> Dictionary: return TrigModelViews.named_vals(vals.call(pts))
	out.wrongs = [wrong(nv.call(key_points(s, s.lo, other)), R_COS_AXIS if s.fn == "cos" else R_SIN_PEAK),
		wrong(nv.call(key_points(s, s.lo, "", null, Q.new(0))), R_NO_D), wrong(nv.call(key_points(s, s.lo, "", null, s.d.neg())), R_D_WAY)]
	if s.a.sign() < 0:
		out.wrongs.append(wrong(nv.call(key_points(s, s.lo, "", s.a.neg())), R_MINUS))
	out.wrongs = spun(out.wrongs, s.spin)
	out.generic = [TrigModelViews.named_vals([right[1], right[0]]), TrigModelViews.named_vals([right[0].add(1), right[1]]), TrigModelViews.named_vals([right[0], right[1].sub(1)]),
		TrigModelViews.named_vals([s.a, s.d]), TrigModelViews.named_vals([right[0].neg(), right[1].neg()])]
	var pat: Array = PATTERN[s.fn]
	var ys := list_of(kp.map(func(p): return D(p[1])))
	out.methods = {
		QPP: method([quarter_line(s), pattern_line(s), "Then y = d + a × fn = %s + %s × (%s) = %s." % [D(s.d), P(s.a), ", ".join(pat.map(func(v): return Fmt.num(v))), ys], say(a)], a.values),
		TB: method([base_line(s), stretch_line(s), "Each key point's y is %s + %s × (%s): %s." % [D(s.d), P(s.a), ", ".join(pat.map(func(v): return Fmt.num(v))), ys], say(a)], a.values),
	}
	return out
