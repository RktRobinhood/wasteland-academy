class_name ComplexPolarAiViews
extends ComplexPolarViews
## The views of t1-ai-complex-polar (AI-AHL1.13, FAL-1005) on the `complex-polar` recipe. Every AI
## paper allows a GDC, so every question is Paper 2. The exact conversions, products, quotients
## and maps reuse ComplexPolarViews' builders with the AI refs; the GDC conversions give 3 s.f.
## (radians), and the type adds powers, the least power, the image of a point under z ↦ wz and
## the sum of two sinusoids of one frequency.

const AI := "AI-AHL1.13."
const TI := "t1-ai-complex-polar#"
const AI_UNKNOWNS := ["to-polar", "to-cartesian", "polar-product", "product-cartesian", "power-polar", "power-cartesian",
	"least-power", "multiply-point", "describe-map", "add-sinusoids"]
## The recipe's ask for each unknown, where it isn't the unknown's own id.
const ASKS := {"power-polar": "ai-power-polar", "power-cartesian": "ai-power-cartesian", "least-power": "ai-least-power",
	"multiply-point": "rotate-point"}
## The AA builders' method ids -> this type's (the AI map's) ids.
const RENAME := {"modulus-argument": "r-theta-formulas", "sketch-and-read": "argand-sketch", "expand-cis": "r-theta-formulas",
	"modulus-argument-rules": "mod-arg-rules", "euler-index-laws": "exponent-laws", "rotation-enlargement": "polar-reading",
	"parallelogram": "vector-add"}
const CONTEXTS := {"voltage": ["V", "voltages", "V"], "wave": ["y", "waves", "y"], "current": ["I", "currents", "I"]}


## slip key -> the type's misconception ref (t1-ai-complex-polar's list, in order).
func slips() -> Dictionary:
	return {
		"arg-sign": AI + "convert-forms#0", "trig-swap": AI + "convert-forms#1", "degree-mode": AI + "convert-forms#2",
		"no-root": AI + "convert-forms#3", "mod-sum": AI + "multiply-divide-polar#0", "arg-mul": AI + "multiply-divide-polar#1",
		"quot-order": AI + "multiply-divide-polar#2", "parts-power": AI + "integer-powers#0", "mod-unraised": AI + "integer-powers#1",
		"arg-raised": AI + "integer-powers#2", "amp-sum": AI + "add-sinusoids#0", "phase-avg": AI + "add-sinusoids#1",
		"phase-degrees": AI + "add-sinusoids#2", "rotation-only": AI + "geometric-interpretation#0", "i-reflect": AI + "geometric-interpretation#1",
		"quadrant": TI + "15", "mod-add": TI + "16", "ref-signs": TI + "17", "unreduced": TI + "18", "clockwise": TI + "19",
		"add-rotates": TI + "20", "pos-only": TI + "21", "kind-swap": TI + "22",
	}


func unknowns() -> Array:
	return AI_UNKNOWNS


func needs() -> Dictionary:
	var out := {}
	for u in unknowns():
		out[u] = {"ask": ASKS.get(u, u), "ai": true}
	return out


## Every AI paper allows a GDC: every cell is Paper 2.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	var methods := {}
	for m in out.methods:
		methods[RENAME.get(m, m)] = out.methods[m]
	out.methods = methods
	return out


# ── Writing decimals ─────────────────────────────────────────

static func D(x: float) -> String:
	return Fmt.sf(x)


## A phase or an argument given to one decimal place: "0.4", "−1.2".
static func ph(x: float) -> String:
	return ("−" if x < 0.0 else "") + Fmt.work(absf(x), 3)


## A GDC value squared, for a working line: "(−2.345678)²".
static func G2(x: float) -> String:
	return ("(%s)²" if x < 0.0 else "%s²") % G(x)


## a + bi with each part to 3 s.f.
static func dtext(x: float, y: float) -> String:
	return D(x) + (" − " if y < 0.0 else " + ") + D(absf(y)) + "i"


static func dpolar(r: float, t: float, style: String) -> String:
	if style == "euler":
		return "%se^(%si)" % [D(r), D(t)]
	return "%s cis(%s)" % [D(r), D(t)]


static func dpolar_ans(head: String, r: float, t: float, style: String) -> Dictionary:
	var parts: Array = [head, {"slot": "r"}, "e^(", {"slot": "t"}, "i)"] if style == "euler" else [head, {"slot": "r"}, " cis(", {"slot": "t"}, ")"]
	return Answer.make("form", dpolar_val(head, r, t, style), {"parts": parts})


static func dpolar_val(head: String, r: float, t: float, style: String) -> Dictionary:
	return {"r": GdcKit.qf(r), "t": GdcKit.qf(t), "text": head + dpolar(r, t, style)}


static func dcart_ans(head: String, x: float, y: float) -> Dictionary:
	return Answer.make("form", dcart_val(head, x, y), {"parts": [head, {"slot": "re"}, " + ", {"slot": "im"}, "i"]})


static func dcart_val(head: String, x: float, y: float) -> Dictionary:
	return {"re": GdcKit.qf(x), "im": GdcKit.qf(y), "text": head + dtext(x, y)}


## The GDC's screen: 6 decimal places.
static func G(x: float) -> String:
	return ("−" if x < 0.0 else "") + "%.6f" % absf(x)


## (r e^(iθ))ⁿ's power as a superscript: "z⁵".
static func sup(n: int) -> String:
	var digits := "⁰¹²³⁴⁵⁶⁷⁸⁹"
	var out := ""
	for ch in str(n):
		out += digits[int(ch)]
	return out


# ── Cartesian and polar ──────────────────────────────────────

func u_to_polar(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	if angle != "gdc-convert":
		var out := super.u_to_polar(rep, s, rng)
		var z := S.cart(s.r, s.c)
		out.wrongs.append(slip("no-root", pwrong(out.answer, "z = ", S.sd(sq(z[0]).add(sq(z[1]))), s.c, s.style)))
		out.wrongs = out.wrongs.filter(func(w): return w != null)
		return out
	var a: int = s.a
	var b: int = s.b
	var style: String = s.style
	var r := sqrt(float(a * a + b * b))
	var t := atan2(float(b), float(a))
	var head := "z = "
	var ans := dpolar_ans(head, r, t, style)
	var wr: Array = [slip("arg-sign", dpolar_val(head, r, -t, style)), slip("no-root", dpolar_val(head, float(a * a + b * b), t, style))]
	if a < 0:
		wr.append(slip("quadrant", dpolar_val(head, r, atan(float(b) / float(a)), style)))
	wr.append(slip("mod-add", dpolar_val(head, float(absi(a) + absi(b)), t, style)))
	var fill: Array = [dpolar_val(head, r, t + PI / 2.0 if t < PI / 2.0 else t - PI / 2.0, style), dpolar_val(head, 2.0 * r, t, style),
		dpolar_val(head, r, PI - t if t > 0.0 else -PI - t, style)]
	var z := "%d%s" % [a, (" − " if b < 0 else " + ") + ("" if absi(b) == 1 else str(absi(b))) + "i"]
	z = z.replace("-", "−")
	var last := "So z = %s." % dpolar(r, t, style)
	var al := atan(absf(float(b) / float(a)))
	var q := 1 if a > 0 and b > 0 else 2 if a < 0 and b > 0 else 3 if a < 0 else 4
	var placed: String = ["", "In the first quadrant θ = %s." % D(al), "In the second quadrant θ = π − %s = %s." % [G(al), D(t)],
		"In the third quadrant θ = −(π − %s) = %s." % [G(al), D(t)], "In the fourth quadrant θ = −%s." % D(al)][q]
	var formulas: Array = ["r = √(%s + %s) = √%d = %s" % [P2(S.sd(a)), P2(S.sd(b)), a * a + b * b, D(r)],
		"z is in the %s quadrant; the angle with the real axis is arctan(%d/%d) = %s." % [QUADRANTS[q], absi(b), absi(a), G(al)], placed, last]
	var gdc: Array = ["Set the GDC to radians and convert %s to polar form." % z, "It gives r = %s and θ = %s." % [G(r), G(t)], last]
	var sketch: Array = ["Sketch z at (%d, %d): it is in the %s quadrant, so θ is %s." % [a, b, QUADRANTS[q], ["", "between 0 and π/2", "between π/2 and π", "between −π and −π/2", "between −π/2 and 0"][q]],
		"r = √%d = %s, and the angle with the real axis is arctan(%d/%d) = %s." % [a * a + b * b, D(r), absi(b), absi(a), G(al)], placed, last]
	for m in [formulas, sketch]:
		for i in m.size():
			m[i] = m[i].replace("(-", "(−").replace(" -", " −")
	return _pack(["z = " + z], polar_ask("z", style).replace("−π < θ ≤ π", "−π < θ ≤ π, giving r and θ to 3 significant figures"), ans, wr, fill,
		{"gdc-convert": gdc, "r-theta-formulas": formulas, "argand-sketch": sketch}, rng)


func u_to_cartesian(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	if angle != "gdc-convert":
		return super.u_to_cartesian(rep, s, rng)
	var rr: int = s.rr
	var tq: Q = s.t
	var t := tq.to_float()
	var style: String = s.style
	var x := rr * cos(t)
	var y := rr * sin(t)
	var head := "z = "
	var ans := dcart_ans(head, x, y)
	var wr: Array = [slip("degree-mode", dcart_val(head, rr * cos(deg_to_rad(t)), rr * sin(deg_to_rad(t)))), slip("trig-swap", dcart_val(head, y, x))]
	var fill: Array = [dcart_val(head, x, -y), dcart_val(head, -x, y), dcart_val(head, -x, -y)]
	var tt := ph(t)
	var shown := "%de^(%si)" % [rr, tt] if style == "euler" else "%d cis(%s)" % [rr, tt]
	var last := "So z = %s." % dtext(x, y)
	var formulas: Array = ["With the GDC in radians: a = r cos θ = %d cos(%s) = %s" % [rr, tt, G(x)], "and b = r sin θ = %d sin(%s) = %s." % [rr, tt, G(y)], last]
	var gdc: Array = ["Set the GDC to radians and enter %s, then convert it to a + bi." % shown, "It gives %s + %si." % [G(x), G(y)] if y >= 0.0 else "It gives %s − %si." % [G(x), G(absf(y))], last]
	return _pack(["z = " + shown], "Write z in the form a + bi, giving a and b to 3 significant figures.", ans, wr, fill,
		{"gdc-convert": gdc, "r-theta-formulas": formulas}, rng)


# ── Products, quotients and powers ───────────────────────────

func u_polar_product(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.u_polar_product(rep, s, rng)
	var v := pp_value(s)
	var C := S.principal(v[1])
	var name: String = pp_names(s)[0]
	var verb := "×" if s.mode == "product" else "÷"
	out.methods["gdc-check"] = method(["With the GDC in radians, enter z₁ %s z₂ and convert it to polar form." % verb,
		"It gives r = %s and θ = %s; θ ÷ π = %s, which is %s, so θ = %s." % [G(S.sval(v[0])), G(PI * C.to_float()), G(C.to_float()), C.text(), Fmt.pi(C)],
		"So %s = %s." % [name, PT(v[0], C, s.style)]], out.answer.values)
	return out


func u_power_polar(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var r: Array = s.r
	var c: Q = s.c
	var n: int = s.n
	var style: String = s.style
	var raw := c.mul(n)
	var C := S.principal(raw)
	var R := S.spow(r, n)
	var name := "z" + sup(n)
	var head := name + " = "
	var ans := polar_ans(head, R, C, style)
	var wr: Array = [slip("mod-unraised", pwrong(ans, head, r, C, style))]
	var pw := "(%s)%s" % [Fmt.pi(c), sup(n)]
	wr.append(slip("arg-raised", other(head + (S.stext(R) + "e^(%s i)" % pw if style == "euler" else S.stext(R) + " cis(%s)" % pw))))
	if not raw.eq(C):
		wr.append(slip("unreduced", pwrong(ans, head, R, raw, style)))
	var fill: Array = [pwrong(ans, head, S.sscale(r, n), C, style), pwrong(ans, head, R, C.neg(), style), pwrong(ans, head, R, S.principal(c.mul(n - 1)), style)]
	var adjust := "" if raw.eq(C) else ", which is %s in −π < θ ≤ π" % Fmt.pi(C)
	var last := "So %s = %s." % [name, PT(R, C, style)]
	var rule: Array = ["Raise the modulus to the power %d and multiply the argument by %d." % [n, n],
		"|%s| = %s%s = %s and arg %s = %d × %s = %s%s." % [name, S.stext(r), sup(n), S.stext(R), name, n, Fmt.pi(c), Fmt.pi(raw), adjust], last]
	var gdc: Array = ["With the GDC in radians, enter (%s)%s and convert it to polar form." % [PT(r, c, style), sup(n)],
		"It gives r = %s and θ = %s; θ ÷ π = %s, which is %s, so θ = %s." % [G(S.sval(R)), G(PI * C.to_float()), G(C.to_float()), C.text(), Fmt.pi(C)], last]
	var asked := "Find %s in the form %s, where r > 0 and −π < θ ≤ π." % [name, form_name(style)]
	return _pack(["z = " + PT(r, c, style)], asked, ans, wr, fill, {"power-rule": rule, "gdc-power": gdc}, rng)


func u_power_cartesian(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var r: Array = s.r
	var c: Q = s.c
	var n: int = s.n
	var C := S.principal(c.mul(n))
	var z := S.cart(r, c)
	var p := S.cart(S.spow(r, n), C)
	var name := "z" + sup(n)
	var head := name + " = "
	var ans := cart_ans(head, p)
	var wr: Array = [slip("mod-unraised", cwrong(ans, head, S.cart(r, C)))]
	# aⁿ + (bi)ⁿ: iⁿ is 1, i, −1 or −i.
	var an := S.spow(z[0], n)
	var bn := S.spow(z[1], n)
	var parts: Array = [[an, S.sd(0)], [an, bn], [S.sadd(an, S.sneg(bn)), S.sd(0)], [an, S.sneg(bn)]][n % 4]
	if n % 4 == 0 or n % 4 == 2:
		parts = [S.sadd(an, bn if n % 4 == 0 else S.sneg(bn)), S.sd(0)]
	if not parts[0].is_empty():
		wr.append(slip("parts-power", cwrong(ans, head, parts)))
	var fill: Array = [cwrong(ans, head, [p[0], S.sneg(p[1])]), cwrong(ans, head, [S.sneg(p[0]), p[1]]), cwrong(ans, head, [p[1], p[0]]),
		cwrong(ans, head, [S.sscale(p[0], 2), S.sscale(p[1], 2)])]
	var last := "So %s = %s." % [name, T(p)]
	var rule: Array = ["z = %s = %s, with |z| = %s and arg z = %s." % [T(z), PT(r, c, "cis"), S.stext(r), Fmt.pi(c)],
		"%s = %s%s cis(%d × %s) = %s" % [name, S.stext(r), sup(n), n, Fmt.pi(c), PT(S.spow(r, n), C, "cis")],
		"= %s(%s + %s i)" % [S.stext(S.spow(r, n)), S.stext(S.cos_sin(C)[0]), P(S.stext(S.cos_sin(C)[1]))], last]
	var gdc: Array = ["Enter (%s)%s on the GDC, with the brackets." % [T(z), sup(n)], "It gives %s." % T(p), last]
	return _pack(["z = " + T(z)], "Find %s in the form a + bi." % name, ans, wr, fill, {"power-rule": rule, "gdc-power": gdc}, rng)


func u_least_power(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var r: Array = s.r
	var c: Q = s.c
	var mode: String = s.mode
	var n := S.least_n(c, mode)
	var head := "n = "
	var ans := Answer.make("number", {"v": Q.new(n)}, {}, head)
	var wr: Array = []
	if mode == "real":
		wr.append(slip("pos-only", {"v": Q.new(S.least_n(c, "positive"))}))
	var other_kind: String = {"real": "imaginary", "imaginary": "real", "positive": "negative", "negative": "positive"}[mode]
	if S.least_n(c, other_kind) > 0:
		wr.append(slip("kind-swap", {"v": Q.new(S.least_n(c, other_kind))}))
	var fill: Array = [{"v": Q.new(n + 1)}, {"v": Q.new(maxi(n - 1, 2) if n != 2 else 3)}, {"v": Q.new(2 * n)}]
	var want: String = {"real": "real", "imaginary": "purely imaginary", "positive": "a positive real number", "negative": "a negative real number"}[mode]
	var cond: String = {"real": "a multiple of π", "imaginary": "an odd multiple of π/2", "positive": "a multiple of 2π", "negative": "an odd multiple of π"}[mode]
	var last := "So n = %d." % n
	var rule: Array = ["z^n = %s^n %s, so arg z^n is n × %s before it is brought into −π < θ ≤ π." % [S.stext(r), "e^(n × %s)" % S.pi_i(c) if s.style == "euler" else "cis(n × %s)" % Fmt.pi(c), Fmt.pi(c)],
		"z^n is %s when n × %s is %s." % [want, Fmt.pi(c), cond], last]
	return _pack(["z = " + PT(r, c, s.style)], "Find the least positive integer n for which z^n is %s." % want, ans, wr, fill, {"power-rule": rule}, rng)


# ── The Argand diagram ───────────────────────────────────────

func u_multiply_point(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var z: Array = s.z
	var w: Array = s.w
	var image := cmul(w, z)
	var head := "w × z = "
	var ans := cart_ans(head, image)
	var r := S.sval(w[0]) * S.sval(w[0]) + S.sval(w[1]) * S.sval(w[1])
	var wr: Array = []
	if S.csame(w, S.cx(0, 1)):
		wr.append(slip("i-reflect", cwrong(ans, head, [z[1], z[0]])))
	if absf(r - 1.0) > 1e-9 and not S.szero(w[1]):
		# The rotation alone: the multiplier's direction w/|w|, the stretch left out.
		var u := S.cart(S.sd(1), wq_arg(w))
		wr.append(slip("rotation-only", cwrong(ans, head, [S.sadd(S.smul(u[0], z[0]), S.sneg(S.smul(u[1], z[1]))), S.sadd(S.smul(u[0], z[1]), S.smul(u[1], z[0]))])))
	if not S.szero(w[1]):
		wr.append(slip("clockwise", cwrong(ans, head, cmul([w[0], S.sneg(w[1])], z))))
	var fill: Array = [cwrong(ans, head, S.cx(image[0][0].neg(), image[1][0].neg())), cwrong(ans, head, cmul(w, [z[0], S.sneg(z[1])])),
		cwrong(ans, head, S.cx(image[1][0], image[0][0])), cwrong(ans, head, S.cx(z[0][0].add(w[0][0]), z[1][0].add(w[1][0])))]
	var last := "So w × z = %s." % T(image)
	var steps: Array = ["A is the point %s, so z = %s." % [pt(z), T(z)], "w × z = (%s)(%s)" % [T(w), T(z)], "= %s, using i² = −1." % T(image), last]
	var asked := "The point A on the Argand diagram represents the complex number z, and w = %s. Find the complex number that represents the image of A under the map z ↦ wz, in the form a + bi." % T(w)
	return _pack([READ_A], asked, ans, wr, fill, {"compute-and-plot": steps}, rng, argand([[z, "A"]], [z]))


## arg w as a multiple of π, for a multiplier on a standard line.
static func wq_arg(w: Array) -> Q:
	for c in S.specials() + [Q.new(0)]:
		var u := S.cart(S.sd(1), c)
		if absf(S.sval(u[0]) * S.sval(w[1]) - S.sval(u[1]) * S.sval(w[0])) < 1e-9 and S.sval(u[0]) * S.sval(w[0]) + S.sval(u[1]) * S.sval(w[1]) > 0.0:
			return c
	return Q.new(0)


func u_describe_map(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.u_describe_map(rep, s, rng)
	if s.mode == "multiply" and S.csame(s.w, S.cx(0, 1)):
		out.wrongs.append(slip("i-reflect", claim("A reflection in the line y = x.")))
	return out


# ── Sinusoids of one frequency ───────────────────────────────

## "3 cos(5t + 0.4)", "4 sin(2t − 1.2)", "2 cos(3t)".
static func wave(amp: Variant, fn: String, w: int, p: float, decimals: bool) -> String:
	var a := D(amp) if decimals else str(amp)
	var tail := "" if absf(p) < 1e-12 else (" − " if p < 0.0 else " + ") + (D(absf(p)) if decimals else ph(absf(p)))
	return "%s %s(%dt%s)" % [a, fn, w, tail]


static func wave_ans(head: String, A: float, fn: String, w: int, B: float) -> Dictionary:
	return Answer.make("form", wave_val(head, A, fn, w, B), {"parts": [head, {"slot": "A"}, " %s(%dt + " % [fn, w], {"slot": "B"}, ")"]})


static func wave_val(head: String, A: float, fn: String, w: int, B: float) -> Dictionary:
	return {"A": GdcKit.qf(A), "B": GdcKit.qf(B), "text": head + wave(A, fn, w, B, true)}


func u_add_sinusoids(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var fn: String = s.fn
	var a1: int = s.amp
	var a2: int = s.amp2
	var w: int = s.w
	var p1: float = s.p1.to_float()
	var p2: float = s.p2.to_float()
	var cx: Array = CONTEXTS[s.context]
	var L: String = cx[0]
	var sum := S.phasor(a1, p1, a2, p2)
	var deg := S.phasor(a1, deg_to_rad(p1), a2, deg_to_rad(p2))
	var A: float = sum[0]
	var B: float = sum[1]
	var head := "%s₁ + %s₂ = " % [L, L]
	var ans := wave_ans(head, A, fn, w, B)
	var wr: Array = [slip("amp-sum", wave_val(head, float(a1 + a2), fn, w, B)), slip("phase-avg", wave_val(head, A, fn, w, (p1 + p2) / 2.0)),
		slip("phase-degrees", wave_val(head, deg[0], fn, w, rad_to_deg(deg[1])))]
	var fill: Array = [wave_val(head, A, fn, w, -B), wave_val(head, absf(float(a1 - a2)), fn, w, B), wave_val(head, A, fn, w, B + PI / 2.0 if B < PI / 2.0 else B - PI / 2.0)]
	var pt1 := ph(p1)
	var pt2 := ph(p2)
	var lines: Array = ["%s₁ = %s and %s₂ = %s, where t is the time in seconds." % [L, wave(a1, fn, w, p1, false), L, wave(a2, fn, w, p2, false)]]
	var asked := "Use complex numbers to write %s₁ + %s₂ in the form A %s(%dt + B), where A > 0 and −π < B ≤ π, giving A and B to 3 significant figures." % [L, L, fn, w]
	var part := "real" if fn == "cos" else "imaginary"
	var last := "So %s₁ + %s₂ = %s." % [L, L, wave(A, fn, w, B, true)]
	var z1 := "%de^(%si)" % [a1, pt1] if absf(p1) > 1e-12 else str(a1)
	var z2 := "%de^(%si)" % [a2, pt2]
	var sy := a1 * sin(p1) + a2 * sin(p2)
	var gdc_sum := "With the GDC in radians, %s + %s = %s %s %si." % [z1, z2, G(a1 * cos(p1) + a2 * cos(p2)), "+" if sy >= 0.0 else "−", G(absf(sy))]
	var phasor_steps: Array = ["Each wave is the %s part of a complex number times e^(%dit): %s₁ + %s₂ is the %s part of (%s + %s)e^(%dit)." % [part, w, L, L, part, z1, z2, w],
		gdc_sum,
		"In polar form that is %se^(%si), so A = %s and B = %s." % [G(A), G(B), D(A), D(B)], last]
	var x := a1 * cos(p1) + a2 * cos(p2)
	var y := a1 * sin(p1) + a2 * sin(p2)
	var vec: Array = ["Draw each amplitude as a vector at its phase: (%d cos %s, %d sin %s) and (%d cos %s, %d sin %s)." % [a1, pt1, a1, pt1, a2, pt2, a2, pt2],
		"Add them tip to tail: the sum is (%s, %s)." % [G(x), G(y)],
		"Its length is A = √(%s + %s) = %s, and its angle is B = %s, in the %s quadrant." % [G2(x), G2(y), D(A), D(B), QUADRANTS[1 if x > 0 and y >= 0 else 2 if x < 0 and y >= 0 else 3 if x < 0 else 4]], last]
	return _pack(lines, asked, ans, wr, fill, {"phasor-sum": phasor_steps, "vector-diagram": vec}, rng)
