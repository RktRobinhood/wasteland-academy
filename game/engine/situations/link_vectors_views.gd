class_name LinkVectorsViews
extends ExtensionViews
## The views on the `fn-link-vectors` situation: one builder per unknown of fn-link-vectors
## (FAL-424). One "across, then up" vector as a graph translation, a vertex, a wave's shift,
## a line's direction, a 3D step and a time delay. A point or a set of coordinates is typed;
## an answer in two parts, or an equation, is a choice of statements. The type's formats are
## mcq, value, match and error-spot, but no misconception is an error-spot, so no spot is
## built (as fn-concept-transform-order). Every number is exact, so no rounding trap fits.

const TC := preload("res://engine/situations/transform_chain.gd")
const LS := preload("res://engine/situations/link_vectors.gd")
const SIGN := "SL2.11.translate#0"
const INSIDE := "SL2.11.translate#1"
const POINT_LEFT := "SL2.11.image-point#0"
const VERTEX_SIGN := "SL2.6.vertex#0"
const FLIPPED := "SL2.1.gradient#0"
const GRAD_SIGN := "SL2.1.gradient#1"
const WAVE_B := "SL3.7.transformations#0"
const WAVE_SIGN := "SL3.7.transformations#2"
const AVERAGED := "SL3.1.midpoint-3d#1"
const HALVED := "SL3.1.midpoint-3d#2"
const SUMMED := "SL3.1.distance-3d#0"
const NEGATIVE := "SL3.1.distance-3d#1"


func needs() -> Dictionary:
	return {"equation-from-vector": {"kind": "graph"}, "image-and-undo": {"kind": "graph"}, "image-from-equation": {"kind": "graph"},
		"vector-from-images": {"kind": "graph"}, "vector-from-vertex-form": {"kind": "vertex"}, "vertex-form-from-vector": {"kind": "vertex"},
		"direction-from-gradient": {"kind": "line"}, "gradient-from-vector": {"kind": "line"}, "wave-shift-vector": {"kind": "wave"},
		"step-in-3d": {"kind": "3d"}, "endpoint-from-midpoint": {"kind": "3d"}, "time-delay": {"kind": "delay"}}


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = LS.export(s)
	return out


static func ask(right: String, wrongs: Array, generic: Array, asked: String, lines: Array, methods: Dictionary, final: String) -> Dictionary:
	return LinkExtremesViews.ask(right, wrongs, generic, asked, lines, methods, final, [])


static func typed(ans: Dictionary, wrongs: Array, asked: String, lines: Array, methods: Dictionary) -> Dictionary:
	return LinkTransformationsViews.typed(ans, wrongs, asked, lines, methods, [])


static func vec(a: Variant, b: Variant) -> String:
	return Fmt.point(a, b)


# ── A translated graph ───────────────────────────────────────

## The graph moved by (a, b), as an equation's right side. A line is simplified.
static func moved(s: Dictionary, a: Q, b: Q) -> String:
	if s.fam == "line":
		return Fmt.poly([s.lm, s.ln.sub(s.lm.mul(a)).add(b)])
	return TC.rule(s, {"A": Q.new(1), "B": Q.new(1), "C": a, "D": b})


## The vertical part put inside the bracket: f(x − a + b), the sum left as it was written.
static func inside(s: Dictionary, a: Q, b: Q) -> String:
	var bracket := TC.x_minus(s, a) + TC.plus(s, b)
	if s.fam == "line":
		return "%s(%s)%s" % [Fmt.lead(s.lm), bracket, Fmt.plus(s.ln)]
	return TC.f_of(s, bracket)


static func parent(s: Dictionary) -> String:
	return Fmt.poly([s.lm, s.ln]) if s.fam == "line" else TC.f_rule(s)


static func words(s: Dictionary) -> String:
	return LinkTransformationsViews.move_words(s, s.a, s.b)


## The curve (or line) moved by a map, in pieces, in a window.
static func drawn(s: Dictionary, a: Q, b: Q, win: Array) -> Array:
	if s.fam == "line":
		var m: float = s.lm.to_float()
		var c: float = s.ln.to_float() - m * a.to_float() + b.to_float()
		return [GdcKit.curve(func(x: float) -> float: return m * x + c, win[0], win[1])]
	return TC.curves(s, {"A": Q.new(1), "B": Q.new(1), "C": a, "D": b}, win)


static func window_for(s: Dictionary, a: Q, b: Q) -> Array:
	var xs: Array = [s.px.to_float(), s.px.to_float() + a.to_float()]
	var ys: Array = [s.py.to_float(), s.py.to_float() + b.to_float()]
	return [mini(floori(xs.min()) - 3, -5), maxi(ceili(xs.max()) + 3, 5), mini(floori(ys.min()) - 3, -5), maxi(ceili(ys.max()) + 3, 5)]


func u_equation_from_vector(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Q = s.a
	var b: Q = s.b
	var right := "y = " + moved(s, a, b)
	var lines: Array = ["y = " + parent(s), "The graph is translated by the vector %s." % vec(a, b)]
	if rep == "words":
		lines = ["The graph of y = %s is moved %s." % [parent(s), words(s)]]
	var inner := "y = f(x − a) + b with a = %s: replace x with %s." % [N(a), TC.x_minus(s, a)]
	return ask(right, [["y = " + moved(s, a.neg(), b), SIGN], ["y = " + inside(s, a, b), INSIDE]],
		["y = " + moved(s, a, b.neg()), "y = " + moved(s, a.neg(), b.neg()), "y = " + moved(s, b, a)],
		"Find the equation of the new graph.", lines, {
			"substitute": [inner, "Add %s outside for the vertical part." % P(b)],
			"shift-features": ["Across goes inside, with the opposite sign: %s." % TC.x_minus(s, a), "Up goes outside: add %s." % P(b)],
		}, "So %s." % right)


func u_image_and_undo(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Q = s.a
	var b: Q = s.b
	var x: Q = s.px
	var y: Q = s.py
	var ix := x.add(a)
	var iy := y.add(b)
	var say := func(px: Q, py: Q, ba: Q, bb: Q) -> String: return "image %s, and the vector back is %s" % [vec(px, py), vec(ba, bb)]
	var right: String = say.call(ix, iy, a.neg(), b.neg())
	var p := vec(x, y)
	var lines: Array = ["The point P%s is on y = %s." % [p, parent(s)], "The graph is translated by the vector %s." % vec(a, b)]
	if rep == "words":
		lines = ["The point P%s is on y = %s." % [p, parent(s)], "The graph is moved %s." % words(s)]
	var add := "Add the vector: (%s + %s, %s + %s) = %s." % [N(x), P(a), N(y), P(b), vec(ix, iy)]
	var back := "Undoing a move means going the same way backwards, so the vector back is %s." % vec(a.neg(), b.neg())
	var out := ask(right, [], [say.call(ix, iy, a, b), say.call(x.sub(a), iy, a.neg(), b.neg()), say.call(x.sub(a), y.sub(b), a, b), say.call(x.sub(a), y.sub(b), a.neg(), b.neg())],
		"Find the image of P, and the vector that moves it back.", lines, {
			"track-points": ["Every point moves by the same vector, so follow P.", add, back],
			"mapping-rule": ["The mapping is (x, y) to (x + a, y + b), with a = %s and b = %s." % [N(a), N(b)], add, back],
		}, "So: %s." % right)
	if rep == "graph":
		var win := window_for(s, a, b)
		out.lines = [ExpLogPairViews.M("The graph of y = %s is shown, with the point P%s." % [parent(s), p]), ExpLogPairViews.M(lines[1])]
		var g := Plot.spec(drawn(s, Q.new(0), Q.new(0), win), [[x.to_float(), y.to_float(), "P" + p]], win[0], win[1], win[2], win[3])
		g.one_colour = true
		out.graph = g
	return out


func u_image_from_equation(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Q = s.a
	var b: Q = s.b
	var x: Q = s.px
	var y: Q = s.py
	var ix := x.add(a)
	var iy := y.add(b)
	return typed(Answer.make("point", {"x": ix, "y": iy}), [wrong({"x": x.sub(a), "y": iy}, POINT_LEFT), wrong({"x": ix, "y": y.sub(b)}), wrong({"x": x.sub(a), "y": y.sub(b)}), wrong({"x": iy, "y": ix})],
		"Find the image of the point on the new graph.", ["The point %s lies on y = f(x)." % vec(x, y), "The new graph is y = f(%s)%s." % [Answer.x_minus(a), Fmt.plus(b)]], {
			"mapping-rule": ["y = f(x − a) + b is a translation by (a, b), with a = %s and b = %s." % [N(a), N(b)], "So (x, y) goes to (x + a, y + b): (%s + %s, %s + %s)." % [N(x), P(a), N(y), P(b)]],
			"solve-for-input": ["f reads %s when %s = %s, so x = %s." % [N(x), Answer.x_minus(a), N(x), N(ix)], "There f gives %s, and adding %s gives y = %s." % [N(y), P(b), N(iy)]],
		})


func u_vector_from_images(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: Q = s.a
	var b: Q = s.b
	var x: Q = s.px
	var y: Q = s.py
	var ix := x.add(a)
	var iy := y.add(b)
	var say := func(va: Q, vb: Q) -> String: return "the vector is %s, so y = %s" % [vec(va, vb), moved(s, va, vb)]
	var right: String = say.call(a, b)
	var lines: Array = ["The point P%s on y = %s goes to P′%s under a translation." % [vec(x, y), parent(s), vec(ix, iy)]]
	var diff := "Across: %s − %s = %s. Up: %s − %s = %s." % [N(ix), P(x), N(a), N(iy), P(y), N(b)]
	var new_eq := "The new graph is y = %s." % moved(s, a, b)
	var wrongs: Array = ["the vector is %s, so y = %s" % [vec(a, b), moved(s, a.neg(), b)], say.call(a.neg(), b.neg()), say.call(b, a), say.call(a, b.neg())]
	var out := ask(right, [], wrongs, "Find the vector, then the equation of the new graph.", lines, {
		"substitute": [diff, "Replace x with %s and add %s." % [TC.x_minus(s, a), P(b)], new_eq],
		"mapping-rule": ["The mapping is (x, y) to (x + a, y + b), so a and b are the differences.", diff, new_eq],
	}, "So: %s." % right)
	if rep == "graph":
		var win := window_for(s, a, b)
		out.lines = [ExpLogPairViews.M("The graphs of y = %s and its image are shown. P%s goes to P′%s." % [parent(s), vec(x, y), vec(ix, iy)])]
		out.graph = LinkTransformationsViews.both(drawn(s, Q.new(0), Q.new(0), win), drawn(s, a, b, win),
			[[x.to_float(), y.to_float(), "P"], [ix.to_float(), iy.to_float(), "P′"]], win)
	return out


# ── Vertex form ──────────────────────────────────────────────

func u_vector_from_vertex_form(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: Q = s.k
	var h: Q = s.h
	var c: Q = s.c
	var form := "y = " + Fmt.vertex(k, h, c)
	var plain := "y = %sx²" % Fmt.lead(k)
	var b_coef := k.mul(h).mul(-2)
	var c_coef := k.mul(h).mul(h).add(c)
	var expanded := "y = " + Fmt.poly([k, b_coef, c_coef])
	var out := typed(Answer.make("point", {"x": h, "y": c}), [wrong({"x": h.neg(), "y": c}, VERTEX_SIGN), wrong({"x": h, "y": c.neg()}), wrong({"x": c, "y": h}), wrong({"x": h.neg(), "y": c.neg()})],
		"Find the vector that carries %s onto the graph." % plain, [form], {
			"shift-features": ["The vertex of %s is (0, 0), and the whole graph moves with it." % plain, "Here the vertex is %s, so that is the vector." % vec(h, c)],
			"read-vertex-form": ["y = k(x − h)² + c has vertex (h, c).", "Here %s is x − h with h = %s, and c = %s." % [Answer.x_minus(h), N(h), N(c)]],
			"formula-then-substitute": ["Expanded, %s." % expanded, "x = −b/(2a) = %s, and substituting gives y = %s." % [N(h), N(c)], "The vertex moved from (0, 0) to there."],
		})
	if rep == "graph":
		var fk := k.to_float()
		var fh := h.to_float()
		var fc := c.to_float()
		var win := [mini(-3, int(fh) - 3), maxi(3, int(fh) + 3), mini(-6, int(fc) - 6), maxi(6, int(fc) + 6)]
		out.lines = [ExpLogPairViews.M("The graphs of %s and %s are shown, with the new vertex marked." % [plain, form])]
		out.graph = LinkTransformationsViews.both([GdcKit.curve(func(x: float) -> float: return fk * x * x, win[0], win[1])],
			[GdcKit.curve(func(x: float) -> float: return fk * (x - fh) ** 2 + fc, win[0], win[1])], [[fh, fc, vec(h, c)]], win)
	return out


func u_vertex_form_from_vector(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var k: Q = s.k
	var h: Q = s.h
	var c: Q = s.c
	var say := func(fh: Q, fc: Q, vh: Q, vc: Q) -> String: return "y = %s, with vertex %s" % [Fmt.vertex(k, fh, fc), vec(vh, vc)]
	var right: String = say.call(h, c, h, c)
	var plain := "y = %sx²" % Fmt.lead(k)
	return ask(right, [[say.call(h.neg(), c, h, c), SIGN], [say.call(h, c, h.neg(), c), VERTEX_SIGN]], [say.call(h, c.neg(), h, c.neg()), say.call(c, h, c, h)],
		"Find the vertex form of the new graph, and its vertex.", ["The graph of %s is moved by the vector %s." % [plain, vec(h, c)]], {
			"read-vertex-form": ["The vector is the new vertex, as (0, 0) moves to %s." % vec(h, c), "y = k(x − h)² + c has vertex (h, c), and k stays %s." % N(k)],
		}, "So %s." % right)


# ── A line's direction ───────────────────────────────────────

## A line's equation with gradient m through (x0, y0).
static func line_through(m: Q, x0: Q, y0: Q) -> String:
	return "y = " + Fmt.poly([m, y0.sub(m.mul(x0))])


static func line_graph(s: Dictionary, labels: Array) -> Dictionary:
	var m: float = s.p.to_float() / s.q.to_float()
	var x1: Q = s.x0.add(s.q)
	var y1: Q = s.y0.add(s.p)
	var n: float = s.y0.to_float() - m * s.x0.to_float()
	var x0f: float = s.x0.to_float()
	var x1f: float = x1.to_float()
	var win := [mini(floori(x0f) - 3, -3), maxi(ceili(x1f) + 3, 3), mini(mini(s.y0.n, y1.n) - 3, -3), maxi(maxi(s.y0.n, y1.n) + 3, 3)]
	var g := Plot.spec([GdcKit.curve(func(x: float) -> float: return m * x + n, win[0], win[1])],
		[[x0f, s.y0.to_float(), labels[0]], [x1f, y1.to_float(), labels[1]]], win[0], win[1], win[2], win[3])
	g.one_colour = true
	return g


func u_direction_from_gradient(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: Q = s.p
	var q: Q = s.q
	var grad := Q.new(p.n, q.n)
	var lines: Array = ["y = " + Fmt.poly([grad, s.n])]
	if rep == "words":
		lines = ["A line has gradient %s." % N(grad)]
	var out := ask(vec(q, p), [[vec(p, q), FLIPPED]], [vec(q, p.neg()), vec(q.neg(), p), vec(p, q.neg()), vec(p.neg(), q)],
		"Which vector points along the line?", lines, {
			"rise-over-run": ["A gradient is rise over run: a run of %s comes with a rise of %s." % [N(q), N(p)], "A vector is written (across, up), so run comes first and rise second."],
		}, "So the answer is %s." % vec(q, p))
	if rep == "graph":
		out.lines = [ExpLogPairViews.M("The line y = %s is shown, through two grid points." % Fmt.poly([grad, s.n]))]
		out.graph = line_graph(s, [vec(s.x0, s.y0), vec(s.x0.add(q), s.y0.add(p))])
	return out


func u_gradient_from_vector(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var p: Q = s.p
	var q: Q = s.q
	var grad := Q.new(p.n, q.n)
	var x0: Q = s.x0
	var y0: Q = s.y0
	var x1 := x0.add(q)
	var y1 := y0.add(p)
	var say := func(m: Q) -> String: return "gradient %s, and %s" % [N(m), line_through(m, x0, y0)]
	var right: String = say.call(grad)
	var two := rep == "graph" or rng.chance(0.5)
	var lines: Array = ["A line through %s has direction vector %s." % [vec(x0, y0), vec(q, p)]]
	if two:
		lines = ["A line passes through %s and %s." % [vec(x0, y0), vec(x1, y1)]]
	var rise := ("The direction is (run, rise), so the gradient is rise ÷ run = %s ÷ %s = %s." % [N(p), N(q), N(grad)]) if not two else \
		("The rise is %s − %s = %s and the run is %s − %s = %s, so the gradient is %s." % [N(y1), P(y0), N(p), N(x1), P(x0), N(q), N(grad)])
	var c := y0.sub(grad.mul(x0))
	var through := "Through %s: c = %s − %s × %s = %s." % [vec(x0, y0), N(y0), P(grad), P(x0), N(c)]
	var out := ask(right, [[say.call(grad.neg()), GRAD_SIGN]], [say.call(Q.new(q.n, p.n)), say.call(Q.new(-q.n, p.n)), "gradient %s, and %s" % [N(grad), line_through(grad, x0, y0.neg())], "gradient %s, and %s" % [N(grad), line_through(grad, x0.neg(), y0)]],
		"Find the gradient, and the equation of the line.", lines, {
			"rise-over-run": [rise, through],
			"two-point-formula": ["m = (y₂ − y₁)/(x₂ − x₁) = (%s − %s)/(%s − %s) = %s." % [N(y1), P(y0), N(x1), P(x0), N(grad)], through],
		}, "So %s." % right)
	if rep == "graph":
		out.lines = [ExpLogPairViews.M("The line through %s and %s is shown." % [vec(x0, y0), vec(x1, y1)])]
		out.graph = line_graph(s, [vec(x0, y0), vec(x1, y1)])
	return out


# ── A wave ───────────────────────────────────────────────────

static func wave_text(s: Dictionary) -> String:
	var e: Q = s.E
	return "y = %s sin(%dx %s %s)%s" % [N(s.A), s.B.n, "+" if e.sign() > 0 else "−", Fmt.pi(e.abs_q()), Fmt.plus(s.D)]


static func pi_vec(e: Q, d: Q) -> String:
	return "(%s, %s)" % [Fmt.pi(e), N(d)]


func u_wave_shift_vector(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A: Q = s.A
	var B: Q = s.B
	var D: Q = s.D
	var E: Q = s.E
	var sh := E.div(B).neg()
	var text := wave_text(s)
	var base := "y = %s sin(%dx)" % [N(A), B.n]
	var inside_e := "%sx %s %s" % [N(B), "+" if E.sign() > 0 else "−", Fmt.pi(E.abs_q())]
	var factored := "%s(x %s %s)" % [N(B), "+" if E.sign() > 0 else "−", Fmt.pi(sh.abs_q())]
	var fact := "Take %s out of the bracket: %s = %s." % [N(B), inside_e, factored]
	var read := "So the graph of %s moves %s across and %s up." % [base, Fmt.pi(sh), N(D)]
	var out := ask(pi_vec(sh, D), [[pi_vec(E.neg(), D), WAVE_B], [pi_vec(sh.neg(), D), WAVE_SIGN]], [pi_vec(sh, D.neg()), pi_vec(sh, A), pi_vec(sh.mul(2), D)],
		"The graph of %s is mapped onto this graph by a translation. Find its vector." % base, [text], {
			"factor-b-first": [fact, read],
			"translation-vector": ["The form is y = A sin(B(x − c)) + d, moved by (c, d).", fact, read],
			"track-key-points": ["A maximum of %s comes where the inside of the sine is π/2." % base, "The inside now reads %s, so each x-coordinate changes by %s." % [inside_e, Fmt.pi(sh)], read],
		}, "So the answer is %s." % pi_vec(sh, D))
	if rep == "graph":
		var a := A.to_float()
		var b := B.to_float()
		var d := D.to_float()
		var e := E.to_float() * PI
		var top := ceili(absf(d) + a) + 1
		out.lines = [ExpLogPairViews.M("The graphs of %s and %s are shown." % [base, text])]
		out.graph = LinkTransformationsViews.both([GdcKit.curve(func(x: float) -> float: return a * sin(b * x), -4.0, 7.0)],
			[GdcKit.curve(func(x: float) -> float: return a * sin(b * x + e) + d, -4.0, 7.0)], [], [-4, 7, -top, top])
	return out


# ── Steps in 3D ──────────────────────────────────────────────

static func p3(v: Array) -> String:
	return "(%s, %s, %s)" % [Fmt.dec(v[0]), Fmt.dec(v[1]), Fmt.dec(v[2])]


static func a_of(s: Dictionary) -> Array:
	return [Q.new(s.ax), Q.new(s.ay), Q.new(s.az)]


static func step_of(s: Dictionary) -> Array:
	return [Q.new(s.sx), Q.new(s.sy), Q.new(s.sz)]


static func plus3(p: Array, v: Array, f: Q = Q.new(1)) -> Array:
	return [p[0].add(v[0].mul(f)), p[1].add(v[1].mul(f)), p[2].add(v[2].mul(f))]


## A length: "6", or "√20".
static func root_text(n: int) -> String:
	var r := roundi(sqrt(float(n)))
	return str(r) if r * r == n else "√%d" % n


func u_step_in_3d(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := a_of(s)
	var st := step_of(s)
	var half := Q.new(1, 2)
	var b := plus3(a, st)
	var mid := plus3(a, st, half)
	var say := func(step: Array, m: Array, d: String) -> String: return "step %s, midpoint %s, distance %s" % [p3(step), p3(m), d]
	var right: String = say.call(st, mid, str(s.len))
	var neg: int = s.neg
	var bad: Array = st.duplicate()
	bad[neg] = b[neg].add(a[neg])
	var bad_len := 0
	var total := 0
	for i in 3:
		bad_len += bad[i].n * bad[i].n
		total += st[i].n
	var lines: Array = ["A%s and B%s are points in 3D." % [p3(a), p3(b)]]
	var steps := "The step is B − A: %s." % p3(st)
	var midline := "The midpoint is A plus half the step: %s." % p3(mid)
	var sum := "%d² + %d² + %d²" % [absi(st[0].n), absi(st[1].n), absi(st[2].n)]
	return ask(right, [[say.call(st, mid, str(absi(total))), SUMMED], [say.call(bad, plus3(a, bad, half), root_text(bad_len)), NEGATIVE]],
		[say.call(st, b, str(s.len)), say.call(st, mid, str(s.len * s.len)), say.call(plus3(st, st, Q.new(-2)), mid, str(s.len))],
		"Find the step from A to B, the midpoint of AB, and the distance AB.", lines, {
			"repeat-the-step": [steps, midline, "The distance is the length of the step: √(%s) = %d." % [sum, s.len]],
			"average-coordinates": [steps, "Average each coordinate of A and B: %s." % p3(mid), "The distance is √(%s) = %d." % [sum, s.len]],
			"distance-formula": [steps, midline, "d = √(Δx² + Δy² + Δz²) = √(%s) = %d." % [sum, s.len]],
			"pythagoras-twice": [steps, midline, "Across the floor, %d² + %d² = %d. Then up: √(%d + %d²) = %d." % [absi(st[0].n), absi(st[1].n), st[0].n * st[0].n + st[1].n * st[1].n, st[0].n * st[0].n + st[1].n * st[1].n, absi(st[2].n), s.len]],
		}, "So: %s." % right)


func u_endpoint_from_midpoint(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a := a_of(s)
	var half := step_of(s).map(func(v): return v.div(2))
	var mid := plus3(a, half)
	var b := plus3(mid, half)
	var tuple := func(v: Array) -> Dictionary: return {"v0": v[0], "v1": v[1], "v2": v[2]}
	var avg := plus3(a, half, Q.new(1, 2))
	var ans := Answer.make("named", tuple.call(b), {"names": ["x", "y", "z"]})
	return typed(ans, [wrong(tuple.call(avg), AVERAGED), wrong(tuple.call(mid.map(func(v): return v.div(2))), HALVED), wrong(tuple.call(half)), wrong(tuple.call(plus3(a, half, Q.new(-1))))],
		"Find the coordinates of B.", ["A%s and M%s are points in 3D." % [p3(a), p3(mid)], "M is the midpoint of AB."], {
			"repeat-the-step": ["The step from A to M is %s." % p3(half), "M is halfway, so the same step again reaches B: %s + %s." % [p3(mid), p3(half)]],
			"solve-each-coordinate": ["Each coordinate of M is the average of A's and B's: M = (A + B)/2.", "So B = 2M − A, one coordinate at a time."],
		})


# ── A delay ──────────────────────────────────────────────────

static func s_rule(s: Dictionary, input: String) -> String:
	var wrapped := input if input == "t" else "(%s)" % input
	if s.dform == "sq":
		return "%s%s²" % [Fmt.lead(s.dm), wrapped]
	return "%s%s + %d" % [Fmt.lead(s.dm), wrapped, s.dn]


static func s_at(s: Dictionary, t: float) -> float:
	return s.dm * t * t if s.dform == "sq" else s.dm * t + s.dn


func u_time_delay(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var d: int = s.d
	var sa := "s_A(t) = " + s_rule(s, "t")
	var late := "t − %d" % d
	var soon := "t + %d" % d
	var secs := "1 second" if d == 1 else "%d seconds" % d
	var say := func(input: String, word: String) -> String: return "s_B(t) = %s: B reaches each position %s %s A" % [s_rule(s, input), secs, word]
	var right: String = say.call(late, "after")
	var lines: Array = [sa + ", in metres, for t seconds after the start.", "B's graph is A's moved by the vector (%d, 0)." % d]
	var plain := "Moving by (%d, 0) replaces t with %s." % [d, late]
	var meaning := "What A does at time t, B does at time t + %d, so B is %s behind." % [d, secs]
	var up := "s_B(t) = %s + %d: B reaches each position %s after A" % [s_rule(s, "t"), d, secs]
	var out := ask(right, [], [say.call(soon, "before"), say.call(soon, "after"), say.call(late, "before"), up],
		"Find s_B(t), and say what the vector means for B.", lines, {
			"substitute": [plain, "s_B(t) = s_A(%s) = %s." % [late, s_rule(s, late)], meaning],
			"track-points": ["A point (t, s) on A's graph goes to (t + %d, s) on B's." % d, "So the same s comes %s later." % secs, "That is the rule s_A(%s) = %s." % [late, s_rule(s, late)]],
		}, "So %s." % right)
	if rep == "graph":
		var top := s_at(s, 8.0)
		var fa := func(t: float) -> float: return s_at(s, t)
		var fb := func(t: float) -> float: return s_at(s, t - d)
		out.lines = [ExpLogPairViews.M("The graphs show A's displacement s_A(t) = %s, and B's, which is A's moved by the vector (%d, 0)." % [s_rule(s, "t"), d])]
		out.graph = LinkTransformationsViews.both([GdcKit.curve(fa, 0.0, 8.0)], [GdcKit.curve(fb, float(d), 8.0)], [], [0, 9, 0, ceili(top) + 2])
	return out
