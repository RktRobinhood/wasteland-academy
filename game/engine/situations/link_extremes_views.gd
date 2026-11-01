class_name LinkExtremesViews
extends ExtensionViews
## The views on the `fn-link-extremes` situation: one builder per unknown of
## fn-link-extremes (FAL-420). An extreme value found several ways: a height model's
## vertex, a wave's peak and range, the touching line, the ends of a closed interval and
## a cubic's turning points. Every answer is a whole number or a multiple of π, played
## as a choice of statements; the midpoint-of-roots working shows its roots to 6 s.f.

const T := "fn-link-extremes"


func needs() -> Dictionary:
	return {"max-height-methods": {"kind": "height"}, "wave-extremes": {"kind": "wave"}, "wave-max-point": {"kind": "wave"},
		"range-from-extremes": {"kind": "wave"}, "tangent-means-touch": {"kind": "tangent"},
		"endpoint-beats-vertex": {"kind": "interval"}, "cubic-turning": {"kind": "cubic"}}


func extra() -> Dictionary:
	var both := ["true-false-reason", "method-pick"]
	var out := {}
	for u in needs():
		out[u] = both
	return out


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = LinkExtremesSituation.export(s)
	return out


static func W(x: float) -> String:
	return Fmt.sf(x, 6)


static func pt(x: Variant, y: Variant) -> String:
	return Fmt.point(x, y)


static func pick(name: String, why: String) -> Dictionary:
	return {"name": name, "why": why}


## A choice question: right, misconception wrongs [[text, ref]], other wrong texts, and
## methods {angle: steps}, each ending with the final line.
static func ask(right: String, wrongs: Array, generic: Array, asked: String, lines: Array, methods: Dictionary, final: String,
		picks: Array) -> Dictionary:
	var out := LogFunctionViews.choice(right, wrongs.map(func(w): return wrong({"v": w[0]}, w[1])), generic)
	var ms := {}
	for a in methods:
		ms[a] = method((methods[a] + [final]).map(func(l): return ExpLogPairViews.M(l)), out.answer.values)
	out.merge({"asked": ExpLogPairViews.M(asked), "lines": lines.map(func(l): return ExpLogPairViews.M(l)), "methods": ms,
		"pick_wrongs": picks})
	return out


# ── The height model ─────────────────────────────────────────

static func h_text(s: Dictionary) -> String:
	return "h(t) = " + Fmt.poly([s.a, s.b, s.c], "t")


func u_max_height_methods(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var t0: int = s.T
	var top: int = s.H
	var say := func(what: String, v: int, t: int) -> String: return "a %s of %s m at t = %s s" % [what, N(v), N(t)]
	var right: String = say.call("maximum", top, t0)
	var vform := "%s(t − %d)² + %d" % [Fmt.lead(a), t0, top]
	var half := sqrt(float(top) / -a)
	var final: String = "So h has " + right + "."
	var lines := [h_text(s)]
	var out := ask(right, [[say.call("maximum", t0, top), "SL2.4.max-min#0"], [say.call("minimum", top, t0), "SL2.6.vertex#2"]],
		[say.call("maximum", c, 0), say.call("maximum", c, 2 * t0)],
		"A ball is thrown upwards. Its height after t seconds is %s metres. Find its greatest height and when it reaches it." % h_text(s),
		lines, {
			"complete-square": ["h(t) = %s(t² − %dt) + %d." % [Fmt.lead(a), 2 * t0, c], "Completing the square: h(t) = %s." % vform,
				"(t − %d)² ≥ 0 and %d < 0, so h is greatest when t = %d." % [t0, a, t0]],
			"formula-then-substitute": ["t = −b/(2a) = −%d/(2 × %s) = %d." % [b, P(a), t0], "h(%d) = %d." % [t0, top]],
			"midpoint-of-roots": ["h(t) = 0 at t = %s and t = %s (to 6 s.f.)." % [W(t0 - half), W(t0 + half)],
				"Their midpoint is t = %d." % t0, "h(%d) = %d." % [t0, top]],
			"gdc-max-min": ["Graph y = %s and use maximum: it gives (%d, %d)." % [Fmt.poly([a, b, c]), t0, top]],
			"derivative-zero": ["h′(t) = %s = 0, so t = %d." % [Fmt.poly([2 * a, b], "t"), t0],
				"h(%d) = %d, and h′ changes from + to − there, so it is a maximum." % [t0, top]],
			"solve-f-prime-zero": ["h′(t) = %s = 0 at t = %d." % [Fmt.poly([2 * a, b], "t"), t0],
				"h″(t) = %d < 0, so it is a maximum, and h(%d) = %d." % [2 * a, t0, top]],
			"vertex-form": ["In vertex form, h(t) = %s." % vform, "The vertex is %s, a maximum since a = %d < 0." % [pt(t0, top), a]],
		}, final,
		[pick("Solve h(t) = 0", "its roots are when the ball is at ground level, not at the top"),
			pick("Put t = 0", "that gives the height it starts from"),
			pick("Take the constant term as the greatest height", "the constant term is the height at t = 0")])
	if rep == "graph":
		var land := t0 + half
		out.lines = [ExpLogPairViews.M("The graph of %s is shown, from t = 0 until the ball lands." % h_text(s))]
		out.graph = Plot.spec([GdcKit.curve(func(t: float) -> float: return a * t * t + b * t + c, 0.0, land)],
			[[0.0, c, pt(0, c)]], 0, ceili(land) + 1, 0, ceili(top * 1.2))
	return out


# ── The wave ─────────────────────────────────────────────────

static func wave_text(s: Dictionary) -> String:
	return "y = %s sin(%dx)%s" % [Fmt.lead(s.A), s.B, Answer.plus_q(s.D)]


static func wave_graph(s: Dictionary) -> Dictionary:
	var A: int = s.A
	var B: int = s.B
	var D: int = s.D
	var amp := absi(A)
	return Plot.spec([GdcKit.curve(func(x: float) -> float: return A * sin(B * x) + D, 0.0, TAU)], [], 0, 7, D - amp - 1, D + amp + 1)


func u_wave_extremes(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A: int = s.A
	var D: int = s.D
	var amp := absi(A)
	var say := func(hi: int, lo: int) -> String: return "greatest %s, least %s" % [N(hi), N(lo)]
	var right: String = say.call(D + amp, D - amp)
	var final: String = "So: " + right + "."
	var wrongs := [[say.call(amp, -amp), "SL3.7.read-features#1"]]
	var ad := absi(A + D)
	if ad != 0 and ad != amp:
		wrongs.append([say.call(D + ad, D - ad), "SL3.7.read-features#1"])
	var out := ask(right, wrongs, [say.call(-D + amp, -D - amp), say.call(D + amp, D)],
		"Find the greatest and least values of %s." % wave_text(s), [wave_text(s)], {
			"read-from-form": ["sin(%dx) runs between −1 and 1." % s.B,
				"So %s sin(%dx) runs between %d and %d, and adding %s gives %d to %d." % [Fmt.lead(A), s.B, -amp, amp, N(D), D - amp, D + amp]],
			"vertex-or-asymptote": ["A wave has no vertex: it turns at its principal axis ± its amplitude.",
				"The principal axis is y = %s and the amplitude |%s| = %d." % [N(D), N(A), amp]],
			"read-parameters": ["Amplitude |A| = %d, principal axis y = D = %s." % [amp, N(D)],
				"Greatest %s + %d = %d, least %s − %d = %d." % [N(D), amp, D + amp, N(D), amp, D - amp]],
			"transform-base": ["y = sin x runs between −1 and 1.",
				"A vertical stretch by %s gives −%d to %d; then the shift by %s gives %d to %d." % [N(A), amp, amp, N(D), D - amp, D + amp]],
		}, final,
		[pick("Put x = 0", "that gives y = D only, the principal axis"),
			pick("Read A as the greatest value", "the principal axis D moves the whole wave up or down"),
			pick("Use x = −b/(2a)", "that is a parabola's axis; a wave has no vertex")])
	if rep == "graph":
		out.lines = [ExpLogPairViews.M("The graph of %s is shown, for 0 ≤ x ≤ 2π." % wave_text(s))]
		out.graph = wave_graph(s)
	return out


## The first positive x of the maximum, as a multiple of π.
static func peak(s: Dictionary) -> Q:
	return Q.new(1 if s.A > 0 else 3, 2 * s.B)


func u_wave_max_point(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A: int = s.A
	var B: int = s.B
	var up := A > 0
	var x := peak(s)
	var right := "x = " + Fmt.pi(x)
	var final: String = "So the first maximum is at %s." % right
	var bx := Fmt.pi(Q.new(1 if up else 3, 2))
	var out := ask(right, [["x = " + Fmt.num(Q.new(B * (1 if up else 3), 4)), "SL3.7.read-features#0"]],
		["x = " + bx, "x = " + Fmt.pi(Q.new(3 if up else 1, 2 * B)), "x = " + Fmt.pi(Q.new(2, B))],
		"Find the first positive value of x at which %s has its maximum." % wave_text(s), [wave_text(s)], {
			"read-from-form": [("The sine part is largest, 1, when %dx = π/2." % B) if up else
				("A = %s < 0, so y is largest when sin(%dx) = −1, first at %dx = 3π/2." % [N(A), B, B]),
				"So x = %s ÷ %d = %s." % [bx, B, Fmt.pi(x)]],
			"transform-base": ["y = %ssin x first peaks at x = %s." % ["" if up else "−", bx],
				"The %d inside divides every x by %d: x = %s." % [B, B, Fmt.pi(x)]],
		}, final,
		[pick("Take a quarter of the period, with period %d" % B, "the period is 2π/%d, not %d" % [B, B]),
			pick("Solve %s = 0" % wave_text(s).trim_prefix("y = "), "that is where the wave meets the x-axis, not its peak"),
			pick("Put x = π/2", "that is where sin x peaks, before the %d inside squeezes it" % B)])
	if rep == "graph":
		out.lines = [ExpLogPairViews.M("The graph of %s is shown, for 0 ≤ x ≤ 2π." % wave_text(s))]
		out.graph = wave_graph(s)
	return out


func u_range_from_extremes(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var amp := absi(s.A)
	var D: int = s.D
	var hi := D + amp
	var lo := D - amp
	var say := func(a: int, d: int) -> String: return "amplitude %s, principal axis y = %s" % [N(a), N(d)]
	var right: String = say.call(amp, D)
	return ask(right, [[say.call(absi(hi), D), "SL3.7.read-features#1"]], [say.call(hi - lo, D), say.call(amp, 0), say.call(amp, -D)],
		"Find the amplitude and the principal axis.",
		["The range of a wave y = A sin(Bx) + D, with A > 0, is %s ≤ y ≤ %s." % [N(lo), N(hi)]], {
			"read-parameters": ["The amplitude is half the height: (%s − %s)/2 = %d." % [N(hi), P(lo), amp],
				"The principal axis is halfway: y = (%s + %s)/2 = %s." % [N(hi), P(lo), N(D)]],
		}, "So: " + right + ".",
		[pick("Take the greatest value as the amplitude", "the principal axis lifts the whole wave"),
			pick("Take the greatest minus the least as the amplitude", "that is twice the amplitude"),
			pick("Take the principal axis as y = 0", "the range isn't centred on 0")])


# ── The touching line ────────────────────────────────────────

func u_tangent_means_touch(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: int = s.s
	var r: int = s.r
	var n: int = s.n
	var yc := k * k + r
	var curve := "x²" + Answer.plus_q(r)
	var line := "mx" + Answer.plus_q(n)
	var quad := "x² − mx + %d" % (k * k)
	var both := func(m: int, xa: int) -> String: return "m = %s at %s or m = %s at %s" % [N(-m), pt(-xa, yc), N(m), pt(xa, yc)]
	var right: String = both.call(2 * k, k)
	var final: String = "So " + right + "."
	var out := ask(right, [["m < %s or m > %d" % [N(-2 * k), 2 * k], "SL5.4.tangency-condition#1"]],
		["m = %d at %s only" % [2 * k, pt(k, yc)], both.call(2 * k, -k), "m = %s or m = %d" % [N(-4 * k * k), 4 * k * k]],
		"The line y = %s is a tangent to the curve y = %s. Find the possible values of m, and where each line touches." % [line, curve],
		["y = " + line, "y = " + curve], {
			"discriminant-condition": ["Equate: %s = %s, so %s = 0." % [curve, line, quad],
				"A tangent touches once, so Δ = m² − 4 × %d = 0: m² = %d, m = ±%d." % [k * k, 4 * k * k, 2 * k],
				"Then x = m/2 = ±%d, and y = (±%d)²%s = %d." % [k, k, Answer.plus_q(r), yc]],
			"discriminant-zero": ["%s = 0 has one repeated root when b² − 4ac = 0." % quad,
				"(−m)² − 4(1)(%d) = 0, so m = ±%d." % [k * k, 2 * k], "The repeated root is x = m/2 = ±%d, where y = %d." % [k, yc]],
			"gradient-match": ["The curve's gradient is 2x, so where the line touches, 2x = m.",
				"The point is on the line too: %s = 2x·x%s, so x² = %d and x = ±%d." % [curve, Answer.plus_q(n), k * k, k],
				"So m = 2x = ±%d, and y = %d." % [2 * k, yc]],
		}, final,
		[pick("Solve Δ > 0", "that gives the lines that cross the curve twice"),
			pick("Match the gradients at x = 0", "the line doesn't touch the curve at x = 0"),
			pick("Solve %s = 0" % curve, "that leaves the line out")])
	if rep == "graph":
		var w := k + 2
		out.lines = [ExpLogPairViews.M("The curve y = %s is shown, with the point %s that every line y = %s passes through." % [curve, pt(0, n), line])]
		out.graph = Plot.spec([GdcKit.curve(func(x: float) -> float: return x * x + r, -w, w)], [[0.0, n, pt(0, n)]],
			-w, w, mini(n, r) - 2, w * w + r)
	return out


# ── The closed interval ──────────────────────────────────────

static func fq(s: Dictionary, x: int) -> int:
	return x * x + s.b * x + s.c


func u_endpoint_beats_vertex(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var h: int = s.h
	var k: int = s.k
	var fp := fq(s, p)
	var fqq := fq(s, q)
	var hi := maxi(fp, fqq)
	var near := mini(fp, fqq)
	var far_x := q if fqq > fp else p
	var dom := "%s ≤ x ≤ %s" % [N(p), N(q)]
	var rng_t := func(lo: String, up: String) -> String: return "%s ≤ f(x) ≤ %s" % [lo, up]
	var right: String = rng_t.call(N(k), N(hi))
	var fx := "f(x) = " + Fmt.poly([1, s.b, s.c])
	var ends := "f(%s) = %s and f(%s) = %s" % [N(p), N(fp), N(q), N(fqq)]
	# Four misconceptions for three wrong options: the seed picks which three.
	var out := ask(right, rng.shuffled([[rng_t.call(N(k), N(near)), "SL2.4.max-min#1"], [rng_t.call(N(near), N(hi)), "SL2.2.range#0"],
		[dom, "SL2.2.range#2"], ["f(x) ≥ " + N(k), "SL5.8.closed-interval-extremes#0"]]), [],
		"Find the range of %s, for %s." % [fx, dom], [fx + ", for " + dom], {
			"graph-read": ["The lowest point of the graph is its vertex, %s." % pt(h, k),
				"The highest is the far end, %s." % pt(far_x, hi)],
			"endpoint-evaluation": [ends + ".", "The vertex, x = %s, lies inside the interval: f(%s) = %s." % [N(h), N(h), N(k)],
				"The least value is %s and the greatest %s." % [N(k), N(hi)]],
			"candidates-check": ["f′(x) = %s = 0 at x = %s, and f(%s) = %s." % [Fmt.poly([2, s.b]), N(h), N(h), N(k)],
				"At the ends, %s." % ends, "The least value is %s and the greatest %s." % [N(k), N(hi)]],
			"monotonic-shortcut": ["The ends give %s, but f turns at x = %s, inside the interval." % [ends, N(h)],
				"So the ends alone miss f(%s) = %s, the least value." % [N(h), N(k)]],
		}, "So the range is " + right + ".",
		[pick("Take the vertex as the only extreme", "the greatest value is at an end"),
			pick("Solve f(x) = 0", "its roots are where f is zero, not where it is greatest or least"),
			pick("Use the vertex and the nearer end", "the far end is higher")])
	if rep == "graph":
		out.lines = [ExpLogPairViews.M("The graph of %s is shown, for %s." % [fx, dom])]
		out.graph = Plot.spec([GdcKit.curve(func(x: float) -> float: return x * x + s.b * x + s.c, p, q)],
			[[p, fp, pt(p, fp)], [h, k, pt(h, k)], [q, fqq, pt(q, fqq)]], p - 1, q + 1, k - 2, hi + 2)
	return out


# ── The cubic ────────────────────────────────────────────────

func u_cubic_turning(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var yp: int = s.yp
	var yq: int = s.yq
	var say := func(xa: int, ya: int, xb: int, yb: int) -> String: return "maximum %s, minimum %s" % [pt(xa, ya), pt(xb, yb)]
	var right: String = say.call(p, yp, q, yq)
	var fx := "f(x) = " + Fmt.poly([1, s.b, s.c, s.d])
	var d1 := Fmt.poly([3, 2 * s.b, s.c])
	var fac := "3(%s)(%s)" % [Answer.x_minus(p), Answer.x_minus(q)]
	var vals := "f(%s) = %s and f(%s) = %s" % [N(p), N(yp), N(q), N(yq)]
	var out := ask(right, [[say.call(p, 0, q, 0), "SL5.8.find-stationary-points#2"]],
		[say.call(q, yq, p, yp), say.call(-q, LinkExtremesSituation.f_cubic(s, -q), -p, LinkExtremesSituation.f_cubic(s, -p)),
			say.call(p, yq, q, yp)],
		"Find the turning points of %s, and say which is a maximum." % fx, [fx], {
			"derivative-zero": ["f′(x) = %s = %s." % [d1, fac], "f′(x) = 0 at x = %s and x = %s: %s." % [N(p), N(q), vals],
				"f′ changes from + to − at x = %s (a maximum) and from − to + at x = %s (a minimum)." % [N(p), N(q)]],
			"solve-f-prime-zero": ["f′(x) = %s = 0 at x = %s and x = %s." % [fac, N(p), N(q)],
				"f″(x) = %s: f″(%s) = %d < 0, a maximum; f″(%s) = %d > 0, a minimum." % [Fmt.poly([6, 2 * s.b]), N(p), 6 * p + 2 * s.b, N(q), 6 * q + 2 * s.b],
				vals + "."],
		}, "So the turning points are: " + right + ".",
		[pick("Solve f(x) = 0", "its roots are where the graph crosses the x-axis, not where it turns"),
			pick("Substitute the x-values into f′", "f′ is 0 there; the y-values come from f"),
			pick("Use x = −b/(2a)", "that is a parabola's axis; a cubic has two turning points")])
	if rep == "graph":
		var lo := p - 2
		var up := q + 2
		var f := func(x: float) -> float: return x * x * x + s.b * x * x + s.c * x + s.d
		out.lines = [ExpLogPairViews.M("The graph of %s is shown." % fx)]
		out.graph = Plot.spec([GdcKit.curve(f, lo, up)], [], lo, up, mini(yq, yp) - 10, maxi(yq, yp) + 10)
	return out
