class_name AlwaysIncreasingViews
extends ExtensionViews
## The views on the `always-increasing` situation: one builder per unknown of
## t5-ext-always-increasing (FAL-776). Each answer is a pick of four written arguments: the right
## one for the asked method, and slips that check a few points, argue about f instead of f′, claim
## a square is always positive, or get a number wrong. Error-spot shows a working with one slip;
## method-pick offers the methods that fail here and two that never prove it.
##
## Representations: "equation" (f(x)) and, for gdc-minimum, "graph" (y = f′(x) as the GDC draws it).

const SK := "SL5.2.show-always-increasing#"
const R_POINTS := SK + "0"
const R_F_POSITIVE := SK + "1"
const R_STRICT := SK + "2"
const R_SQUARE_SLIP := "t5-ext-always-increasing#3"
const R_TERM_SLIP := "t5-ext-always-increasing#4"
const UNKNOWNS := ["quadratic-derivative", "decreasing-quadratic", "sum-of-terms", "inverse-exists", "gdc-minimum"]
const PICK_WRONGS := [
	{"name": "Check f′ at a few values of x", "why": "a few values can't show that f′ keeps its sign for every x"},
	{"name": "Show that f(x) > 0", "why": "f being positive says nothing about whether f increases"},
]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = ["true-false-reason", "method-pick"] + (["error-spot"] if u != "gdc-minimum" else [])
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	if not has(unknown):
		return []
	return [2] if unknown == "gdc-minimum" else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = AlwaysIncreasingSituation.export(s)
	out.pick_wrongs = PICK_WRONGS
	return out


static func SUM(terms: Array) -> String:
	return DifferentiationViews.SUM(terms)


static func T(c: Variant, body: String) -> String:
	return DifferentiationViews.T(c, body)


static func pick(right: String, tagged: Array, plain: Array) -> Dictionary:
	return InverseRuleViews.choose(right, tagged, plain)


static func tag(text: String, ref: String) -> Dictionary:
	return InverseRuleViews.tag(text, ref)


static func E(s: int) -> String:
	return "e^x" if s == 1 else "e^(%dx)" % s


# ── A quadratic f′ ───────────────────────────────────────────

## f′ = sg·(3a(x − h)² + k) as [x², x, 1] coefficients.
static func fp_coeffs(s: Dictionary) -> Array:
	var a: int = s.a
	var h: int = s.h
	return [3 * a * s.sg, -6 * a * h * s.sg, (3 * a * h * h + s.k) * s.sg]


static func f_text(s: Dictionary) -> String:
	var a: int = s.a
	var h: int = s.h
	return Fmt.poly([a * s.sg, -3 * a * h * s.sg, (3 * a * h * h + s.k) * s.sg, s.d])


static func sq(h: int) -> String:
	return Fmt.factor(h) + "²"


## sg·(3a(x − h)² + k) written as a square: "3(x − 1)² + 2", "−3(x − 1)² − 2".
static func vertex(s: Dictionary, k: int) -> String:
	return SUM([[3 * s.a * s.sg, sq(s.h)], [k * s.sg, ""]])


static func quad_f(s: Dictionary) -> String:
	var c := fp_coeffs(s)
	return Fmt.poly(c)


static func at(c: Array, x: int) -> int:
	return c[0] * x * x + c[1] * x + c[2]


func _quadratic(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var up: bool = s.sg > 0
	var g := "f" if up else "g"
	var c := fp_coeffs(s)
	var k: int = s.k
	var ends := "≥ %s > 0 for all x, so f is increasing" % N(k) if up else "≤ %s < 0 for all x, so g is decreasing" % N(-k)
	var strict := "> %s for all x, so f is increasing" % N(k) if up else "< %s for all x, so g is decreasing" % N(-k)
	var sign_word := "positive" if up else "negative"
	var sign_end := "f′(x) > 0 for all x" if up else "g′(x) < 0 for all x"
	var delta: int = c[1] * c[1] - 4 * c[0] * c[2]
	var cs := "%s′(x) = %s %s" % [g, vertex(s, k), ends]
	var disc := "%s′(x) = %s has discriminant %s < 0 and a %s x² coefficient, so %s" % [g, quad_f(s), N(delta), sign_word, sign_end]
	# The slips: the square's constant not times the leading coefficient, and b halved in Δ.
	var k_slip: int = k + (3 * s.a - 1) * s.h * s.h
	var cs_slip := "%s′(x) = %s %s" % [g, vertex(s, k_slip), ("≥ %s > 0 for all x, so f is increasing" % N(k_slip)) if up else ("≤ %s < 0 for all x, so g is decreasing" % N(-k_slip))]
	var d_slip: int = (c[1] / 2) * (c[1] / 2) - 4 * c[0] * c[2]
	var disc_slip := "%s′(x) = %s has discriminant %s < 0 and a %s x² coefficient, so %s" % [g, quad_f(s), N(d_slip), sign_word, sign_end]
	var x1: int = s.x1
	var x2: int = x1 + 2
	var points := "%s′(%s) = %s and %s′(%s) = %s are both %s, so %s" % [g, N(x1), N(at(c, x1)), g, N(x2), N(at(c, x2)), sign_word, sign_end]
	var tagged := [tag(points, R_POINTS), tag("%s′(x) = %s %s" % [g, vertex(s, k), strict], R_STRICT)]
	var right := cs if angle == "complete-square" else disc
	var plain := [cs_slip, disc_slip] if angle == "complete-square" else [disc_slip, cs_slip]
	var out := {"asked": "Which statement shows that %s is %s for all x?" % [g, "increasing" if up else "decreasing"],
		"lines": ["%s(x) = %s" % [g, f_text(s)]]}
	out.merge(pick(right, tagged, plain))
	var a3: int = c[0]
	var inner := SUM([[1, "x²"], [-2 * s.h, "x"]])
	var opened := SUM([[a3, sq(s.h)], [-a3 * s.h * s.h, ""], [c[2], ""]])
	# The answer is the asked method's own argument. The other method is worked too, and its
	# last line says the same fact in the asked method's words, so every working ends at the answer.
	var both := {
		"complete-square": method(["%s′(x) = %s." % [g, quad_f(s)],
			"Take out %s: %s′(x) = %s = %s." % [N(a3), g, SUM([[a3, "(%s)" % inner], [c[2], ""]]), opened],
			"%s ≥ 0 for every x, and it is 0 at x = %s." % [sq(s.h), N(s.h)], cs + "."], {"v": right}),
		"discriminant-negative": method(["%s′(x) = %s, a quadratic with a = %s, b = %s and c = %s." % [g, quad_f(s), N(c[0]), N(c[1]), N(c[2])],
			"Δ = b² − 4ac = %s² − 4 × %s × %s = %s." % [P(c[1]), P(c[0]), P(c[2]), N(delta)], disc + "."], {"v": right}),
	}
	var other := "discriminant-negative" if right == cs else "complete-square"
	both[other].steps.append(("In completed-square form, the same fact reads: %s." % cs) if right == cs
		else ("By the discriminant, the same fact reads: %s." % disc))
	out.methods = both
	# Error-spot: the square completed with h² for a·h².
	var f1 := "%s′(x) = %s" % [g, quad_f(s)]
	var slip := "= %s" % SUM([[a3, sq(s.h)], [-s.sg * s.h * s.h, ""], [c[2], ""]])
	var last := "%s %s" % [vertex(s, k_slip), ("≥ %s > 0, so f′(x) > 0 for all x" % N(k_slip)) if up else ("≤ %s < 0, so g′(x) < 0 for all x" % N(-k_slip))]
	var lines := [f1, "= %s" % SUM([[a3, "(%s)" % inner], [c[2], ""]]), slip, "= " + last]
	var bad := 2
	if rng.chance(0.5):
		lines = [f1, slip, "= " + vertex(s, k_slip), last.substr(vertex(s, k_slip).length() + 1)]
		bad = 1
	out.spot = {"lines": lines, "bad": bad, "ref": R_SQUARE_SLIP,
		"why": "taking out %s turns the %s inside the bracket into %s, so the constant is %s, not %s" % [N(a3), N(s.h * s.h), N(a3 * s.h * s.h), N(-a3 * s.h * s.h), N(-s.sg * s.h * s.h)]}
	return out


func u_quadratic_derivative(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _quadratic(rep, s, rng)


func u_decreasing_quadratic(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _quadratic(rep, s, rng)


# ── A sum of terms ───────────────────────────────────────────

static func claims(t: Array, strict_square: bool) -> String:
	return "%s %s 0, %s > 0 and %s > 0" % [T(t[0][0], t[0][1]), ">" if strict_square else "≥", N(t[1][0]), T(t[2][0], t[2][1])]


func u_sum_of_terms(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var r: int = s.r
	var e: int = s.s
	var f := SUM([[p, "x³"], [q, "x"], [r, E(e)]])
	var t := [[3 * p, "x²"], [q, ""], [r * e, E(e)]]
	var fp := SUM(t)
	var right := "%s, so f′(x) = %s > 0 for all x" % [claims(t, false), fp]
	var points := "f′(0) = %s and f′(1) = %s are both positive, so f′(x) > 0 for all x" % [N(q + r * e), SUM([[3 * p + q, ""], [r * e, "e" + Fmt.sup(e)]])]
	var slip_t := [[3 * p, "x²"], [q, ""], [r, E(e)]] if e > 1 else [[p, "x²"], [q, ""], [r, E(e)]]
	var slip := "%s, so f′(x) = %s > 0 for all x" % [claims(slip_t, false), SUM(slip_t)]
	var out := {"asked": "Which statement shows that f is increasing for all x?", "lines": ["f(x) = " + f]}
	out.merge(pick(right, [tag(points, R_POINTS), tag("%s > 0 for all x, so f is increasing" % f, R_F_POSITIVE),
		tag("%s, so f′(x) = %s > 0 for all x" % [claims(t, true), fp], R_STRICT)], [slip]))
	out.methods = {"sum-of-positive-terms": method(["f′(x) = %s." % fp,
		"A square is never negative, a positive number times an exponential is always positive, and %s > 0." % N(q), right + "."], {"v": right})}
	var lines := ["f′(x) = " + SUM(slip_t), claims(slip_t, false), "So f′(x) > 0 for all x", "So f is increasing for all x"]
	var bad := 0
	if rng.chance(0.5):
		lines = ["f(x) = " + f, lines[0], lines[1], lines[2]]
		bad = 1
	var why := "the derivative of %s is %s: the chain rule brings down the %s" % [T(r, E(e)), T(r * e, E(e)), N(e)] if e > 1 \
		else "the derivative of %s is %s: the power comes down" % [T(p, "x³"), T(3 * p, "x²")]
	out.spot = {"lines": lines, "bad": bad, "ref": R_TERM_SLIP, "why": why}
	return out


func u_inverse_exists(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var f := SUM([[a, "x²"], [b, "ln x"]])
	var fp := SUM([[2 * a, "x"], [b, "/x"]])
	var right := "For x > 0, %s > 0 and %s > 0, so f′(x) = %s > 0: f is increasing, so it is one-to-one and has an inverse" % [T(2 * a, "x"), T(b, "/x"), fp]
	var points := "f′(1) = %s and f′(2) = %s are both positive, so f is increasing and has an inverse" % [N(2 * a + b), N(Q.new(8 * a + b, 2))]
	var positive := "%s > 0 and %s > 0 for x > 0, so f(x) > 0 and f has an inverse" % [T(a, "x²"), T(b, "ln x")]
	var slip_fp := SUM([[2 * a, "x"], [b, "/x²"]])
	var slip := "For x > 0, %s > 0 and %s > 0, so f′(x) = %s > 0: f is increasing, so it is one-to-one and has an inverse" % [T(2 * a, "x"), T(b, "/x²"), slip_fp]
	var out := {"asked": "Which statement shows that f′(x) > 0 for x > 0, and explains why f has an inverse?", "lines": ["f(x) = %s, for x > 0" % f]}
	out.merge(pick(right, [tag(points, R_POINTS), tag(positive, R_F_POSITIVE)], [slip]))
	out.methods = {"sum-of-positive-terms": method(["f′(x) = %s." % fp, "For x > 0, %s and %s are both positive." % [T(2 * a, "x"), T(b, "/x")], right + "."], {"v": right})}
	var lines := ["f′(x) = " + slip_fp, "For x > 0, %s > 0 and %s > 0" % [T(2 * a, "x"), T(b, "/x²")], "So f′(x) > 0 for x > 0", "So f is one-to-one and has an inverse"]
	var bad := 0
	if rng.chance(0.5):
		lines = ["f(x) = %s is defined for x > 0" % f, lines[0], lines[1], lines[2]]
		bad = 1
	out.spot = {"lines": lines, "bad": bad, "ref": R_TERM_SLIP, "why": "the derivative of %s is %s, not %s" % [T(b, "ln x"), T(b, "/x"), T(b, "/x²")]}
	return out


# ── On the GDC ───────────────────────────────────────────────

static func S(x: float) -> String:
	return GdcKit.S(x)


func u_gdc_minimum(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var A: int = s.A
	var m: int = s.m
	var n: int = s.n
	var f := SUM([[A, "e^x"], [-m / 2, "x²"], [n, "x"]])
	var fp := SUM([[A, "e^x"], [-m, "x"], [n, ""]])
	var right := "The GDC shows the least value of f′(x) is %s, at x = %s, so f′(x) > 0 for all x" % [S(s.v), S(s.xm)]
	var points := "f′(0) = %s and f′(1) = %s are both positive, so f′(x) > 0 for all x" % [N(A + n), S(AlwaysIncreasingSituation.fp(s, 1.0))]
	var at_zero := "The GDC shows the least value of f′(x) is %s, at x = 0, so f′(x) > 0 for all x" % N(A + n)
	var zero := "The GDC shows f′(x) = 0 at x = %s, so f has a stationary point there" % S(s.xm)
	var out := {"asked": "Which statement shows that f is increasing for all x?", "lines": ["f(x) = " + f]}
	if rep == "graph":
		out.lines.append("The graph of y = f′(x) is shown.")
		var lo := floori(s.xm) - 3
		var hi := floori(s.xm) + 3
		var g := func(x: float) -> float: return AlwaysIncreasingSituation.fp(s, x)
		var c := GdcKit.curve(g, float(lo), float(hi))
		var top := 0.0
		for pt in c:
			top = maxf(top, pt[1])
		out.graph = Plot.spec([c], [], lo, hi, -2, mini(ceili(top) + 1, 40))
	out.merge(pick(right, [tag(points, R_POINTS)], [at_zero, zero]))
	out.methods = {"graph-f-prime": method(["f′(x) = %s." % fp, "Graph y = f′(x) on the GDC and find its minimum point: (%s, %s)." % [S(s.xm), S(s.v)], right + "."], {"v": right})}
	return out
