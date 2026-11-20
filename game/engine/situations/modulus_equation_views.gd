class_name ModulusEquationViews
extends ExtensionViews
## The views on the `modulus-equation` situation (FAL-1008): one builder per unknown of
## fn-ahl-modulus-equations (AHL2.16.modulus-equation, modulus-inequality). Builders return
## what QuadraticViews' builders return (see quadratic_views.gd).
##
## An equation's solutions are an `xs` answer (typed in any order; a slip may give another
## count, such as both roots kept where one must be rejected). A count is a typed number, the
## k for four solutions an `interval` and the k for three a number. A solution set is a
## `choice`, written canonically by ModulusEquationSituation.set_text (its pieces left to
## right, each "lo < x < hi", "x ≤ lo" or "x > hi", joined by "or"), so two options read the
## same only when they are the same set. Every cell is exact on either paper except the GDC
## methods' (Paper 2), and |f(x)| against a line, whose crossings are given to 3 s.f.

const SK := "AHL2.16."
const R_KEEP_NEG := SK + "modulus-equation#0"
const R_ONE_CASE := SK + "modulus-equation#1"
const R_SQUARE_KEEP := SK + "modulus-equation#2"
const R_UPPER_ONLY := SK + "modulus-inequality#0"
const R_CHAIN := SK + "modulus-inequality#1"
const R_DOMAIN := SK + "modulus-inequality#2"
## The type's own slips, by index.
const T := "fn-ahl-modulus-equations#"
const R_COUNT_F := T + "6"
const R_BOUNDARY := T + "7"
const R_COMPLEMENT := T + "8"

const S := preload("res://engine/situations/modulus_equation.gd")


func needs() -> Dictionary:
	return {
		"shifted-modulus": {"kind": "shift"},
		"linear-equals-constant": {"kind": "lin"},
		"modulus-equals-modulus": {"kind": "mm"},
		"modulus-equals-line": {"kind": "ml"},
		"count-solutions": {"kind": "count"},
		"modulus-less-than": {"kind": "lt"},
		"modulus-greater-than": {"kind": "gt"},
		"modulus-against-modulus": {"kind": "amm"},
		"modulus-vs-curve": {"kind": "curve"},
	}


func need(unknown: String, rep: String) -> Dictionary:
	var n := super.need(unknown, rep)
	if rep == "graph":
		n.graph = true
	return n


## A GDC method, and |f(x)| against a line, are Paper 2; every other cell is exact and can
## be asked on either paper.
func papers(unknown: String, _rep: String, method_id: String) -> Array:
	return [2] if method_id.begins_with("gdc-") or unknown == "modulus-vs-curve" else [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = S.export(s)
	return out


# ── Helpers ──────────────────────────────────────────────────

## "|2x − 5|".
static func md(a: Variant, b: Variant) -> String:
	return "|%s|" % Fmt.poly([a, b])


static func lin(a: Variant, b: Variant) -> String:
	return Fmt.poly([a, b])


## The distinct values, smallest first.
static func uniq(xs: Array) -> Array:
	var out: Array = []
	for x in xs:
		var q := Q.of(x)
		if not out.any(func(o): return o.eq(q)):
			out.append(q)
	out.sort_custom(func(p, q): return p.lt(q))
	return out


static func xs_vals(xs: Array) -> Dictionary:
	return Answer.xs_of(uniq(xs))


static func xs_ans(xs: Array) -> Dictionary:
	var ans := Answer.make("xs", xs_vals(xs), {"var": "x"})
	ans.exact = true
	return ans


static func fin(ans: Dictionary) -> String:
	return "So %s." % Answer.text(ans)


static func steps_of(m: Dictionary, ans: Dictionary) -> Dictionary:
	var out := {}
	for a in m:
		out[a] = method(m[a], ans.values)
	return out


## Points along y = fn(x) from x0 to x1 with the corners (where a modulus is 0) included.
static func trace(fn: Callable, x0: float, x1: float, corners: Array = []) -> Array:
	var xs: Array = []
	for i in 201:
		xs.append(x0 + (x1 - x0) * i / 200.0)
	for c in corners:
		var cf := float(c)
		if cf > x0 and cf < x1:
			xs.append(cf)
	xs.sort()
	return xs.map(func(x): return [x, fn.call(x)])


static func v_of(a: float, b: float, m: float = 1.0) -> Callable:
	return func(x: float) -> float: return m * absf(a * x + b)


static func line_of(m: float, c: float) -> Callable:
	return func(x: float) -> float: return m * x + c


## A window round the x-values that matter, and up to the heights there.
static func window(xs: Array, ys: Array) -> Array:
	var lo := INF
	var hi := -INF
	for x in xs:
		lo = minf(lo, float(x))
		hi = maxf(hi, float(x))
	var top := 2.0
	var bottom := -2.0
	for y in ys:
		top = maxf(top, float(y))
		bottom = minf(bottom, float(y))
	return [floori(lo) - 2, ceili(hi) + 2, maxi(floori(bottom) - 1, -8), ceili(top) + 2]


## "gives 2x = 10, so x = 5", or "gives x = 5" when the x term is x alone; a negative
## x term is divided out the same way: "gives −2x = −6, so x = 3".
static func solve_lin(coef: int, rhs: Variant) -> String:
	var v := Q.of(rhs).div(coef)
	if coef == 1:
		return "gives x = %s" % N(v)
	return "gives %sx = %s, so x = %s" % [Fmt.lead(coef), N(rhs), N(v)]


# ── |x − a| = k ──────────────────────────────────────────────

func u_shifted_modulus(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var k: int = s.k
	var inside := lin(1, -a)
	var ans := xs_ans(s.roots)
	var steps := [
		"Split into the two cases: %s = %d or %s = −%d." % [inside, k, inside, k],
		"%s = %d gives x = %s, and %s = −%d gives x = %s." % [inside, k, N(a + k), inside, k, N(a - k)],
		"The right-hand side %d is positive, so both are solutions. %s" % [k, fin(ans)],
	]
	return {"asked": "Solve the equation.", "lines": ["%s = %d" % [md(1, -a), k]], "answer": ans,
		"wrongs": [wrong(xs_vals([a + k]), R_ONE_CASE)],
		"fillers": [xs_vals([-a - k, -a + k]), xs_vals([a + k, -a - k]), xs_vals([k - a, k + a]), xs_vals([a, k]), xs_vals([a - k, -a - k])],
		"methods": steps_of({"split-into-cases": steps}, ans)}


# ── |ax + b| = k ─────────────────────────────────────────────

func u_linear_equals_constant(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var k: int = s.k
	var inside := lin(a, b)
	var ans := xs_ans(s.roots)
	var steps := [
		"Split into the two cases: %s = %d or %s = −%d." % [inside, k, inside, k],
		"%s = %d %s." % [inside, k, solve_lin(a, k - b)],
		"%s = −%d %s." % [inside, k, solve_lin(a, -k - b)],
		fin(ans),
	]
	return {"asked": "Solve the equation.", "lines": ["%s = %d" % [md(a, b), k]], "answer": ans,
		"wrongs": [wrong(xs_vals([Q.new(k - b, a)]), R_ONE_CASE)],
		"fillers": [xs_vals([Q.new(k + b, a), Q.new(-k + b, a)]), xs_vals([k - b, -k - b]), xs_vals([Q.new(k - b, a), Q.new(b - k, a)]),
			xs_vals([Q.new(k, a).sub(b), Q.new(-k, a).sub(b)])],
		"methods": steps_of({"split-into-cases": steps}, ans)}


# ── Squaring two linear sides ────────────────────────────────

## (px + u)² = (qx + v)² collected with a positive x² term, and its two factors:
## [text of the quadratic, factor 1, factor 2], (p − q)x + (u − v) and (p + q)x + (u + v),
## the first negated when the x² term would be negative.
static func squared(p: int, u: int, qq: int, v: int) -> Array:
	var A := p * p - qq * qq
	var B := 2 * (p * u - qq * v)
	var C := u * u - v * v
	var f1 := [p - qq, u - v]
	var f2 := [p + qq, u + v]
	if A < 0:
		A = -A
		B = -B
		C = -C
		f1 = [qq - p, v - u]
	# Both factors with a positive x term, and each in lowest terms.
	if f1[0] < 0:
		f1 = [-f1[0], -f1[1]]
		f2 = [-f2[0], -f2[1]]
	var g1 := Q.gcd(absi(f1[0]), absi(f1[1]))
	var g2 := Q.gcd(absi(f2[0]), absi(f2[1]))
	f1 = [f1[0] / g1, f1[1] / g1]
	f2 = [f2[0] / g2, f2[1] / g2]
	var quad := Fmt.poly([A, B, C]) + " = 0"
	var G := g1 * g2
	if G > 1:
		quad += ", that is %s = 0" % Fmt.poly([A / G, B / G, C / G])
	return [quad, lin(f1[0], f1[1]), lin(f2[0], f2[1])]


func u_modulus_equals_modulus(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var c: int = s.c
	var d: int = s.d
	var L := lin(a, b)
	var R := lin(c, d)
	var ans := xs_ans([s.r1, s.r2])
	var sq := squared(a, b, c, d)
	var out := {"asked": "Solve the equation.", "lines": ["%s = %s" % [md(a, b), md(c, d)]], "answer": ans,
		"wrongs": [wrong(xs_vals([s.r1]), R_ONE_CASE)],
		"fillers": [xs_vals([s.r1.neg(), s.r2.neg()]), xs_vals([s.r1, s.r2.neg()]), xs_vals([Q.new(d - b, a + c), Q.new(-b - d, a - c)]),
			xs_vals([Q.new(b - d, a - c), Q.new(b + d, a + c)]), xs_vals([Q.new(d - b, a - c), Q.new(b + d, a + c)])]}
	if rep == "graph":
		out.lines.append("The graphs of y = %s and y = %s are shown." % [md(a, b), md(c, d)])
		var xs := [s.r1.to_float(), s.r2.to_float(), -float(b) / a, -float(d) / c]
		var ys := [absf(a * s.r1.to_float() + b), absf(a * s.r2.to_float() + b)]
		var w := window(xs, ys)
		out.graph = Plot.spec([trace(v_of(a, b), w[0], w[1], [-float(b) / a]), trace(v_of(c, d), w[0], w[1], [-float(d) / c])], [], w[0], w[1], w[2], w[3])
	out.methods = steps_of({
		"split-into-cases": [
			"Two moduli are equal when the insides are equal or opposite: %s = %s or %s = −(%s)." % [L, R, L, R],
			"%s = %s %s." % [L, R, solve_lin(a - c, d - b)],
			"%s = −(%s) %s." % [L, R, solve_lin(a + c, -b - d)],
			fin(ans)],
		"square-both-sides": [
			"Both sides are at least 0, so square them: (%s)² = (%s)²." % [L, R],
			"Expand and collect: %s." % sq[0],
			"Factorise: (%s)(%s) = 0, so x = %s or x = %s." % [sq[1], sq[2], N(s.r1), N(s.r2)],
			"Both sides were moduli, so squaring brings in no false root. " + fin(ans)],
	}, ans)
	return out


func u_modulus_equals_line(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var b: int = s.b
	var m: int = s.m
	var c: int = s.c
	var L := lin(a, b)
	var line := lin(m, c)
	var good: Q = s.good
	var bad: Q = s.bad
	var at_bad := bad.mul(m).add(c)
	var at_good := good.mul(m).add(c)
	var ans := xs_ans([good])
	var both := xs_vals([s.x1, s.x2])
	var ref := R_SQUARE_KEEP if angle == "square-both-sides" else R_KEEP_NEG
	var out := {"asked": "Solve the equation.", "lines": ["%s = %s" % [md(a, b), line]], "answer": ans,
		"wrongs": [wrong(both, ref)],
		"fillers": [xs_vals([bad]), xs_vals([good.neg()]), xs_vals([s.x1.neg(), s.x2.neg()]), xs_vals([good, bad.neg()])]}
	if rep == "graph":
		out.lines.append("The graphs of y = %s and y = %s are shown." % [md(a, b), line])
		var xs := [good.to_float(), bad.to_float(), -float(b) / a]
		var ys := [at_good.to_float()]
		var w := window(xs, ys)
		out.graph = Plot.spec([trace(v_of(a, b), w[0], w[1], [-float(b) / a]), trace(line_of(m, c), w[0], w[1])], [], w[0], w[1], w[2], w[3])
	var check := "At x = %s the right-hand side %s is %s, below 0, which a modulus can never equal: reject it. At x = %s both sides are %s." % [
		N(bad), line, N(at_bad), N(good), N(at_good)]
	var sq := squared(a, b, m, c)
	out.methods = steps_of({
		"split-into-cases": [
			"%s = %s %s." % [L, line, solve_lin(a - m, c - b)],
			"−(%s) = %s %s." % [L, line, solve_lin(a + m, -b - c)],
			check, fin(ans)],
		"square-both-sides": [
			"Square both sides: (%s)² = (%s)², so %s." % [L, line, sq[0]],
			"Factorise: (%s)(%s) = 0, so x = %s or x = %s." % [sq[1], sq[2], N(s.x1), N(s.x2)],
			"Squaring can bring in a false root, so check each in the original. " + check, fin(ans)],
		"graph-intersections": [
			"Sketch y = %s, a V with its vertex at (%s, 0), and the line y = %s." % [md(a, b), N(Q.new(-b, a)), line],
			"They meet once, at x = %s, where both are %s." % [N(good), N(at_good)],
			"The other case gives x = %s, but there the line is at y = %s, below the x-axis, where the V never goes. %s" % [N(bad), N(at_bad), fin(ans)]],
	}, ans)
	return out


# ── Counting the solutions of |f(x)| = k ─────────────────────

static func f_text(s: Dictionary) -> String:
	var A: int = s.A
	return Fmt.poly([A, -A * (s.p + s.q), A * s.p * s.q])


static func f_count(s: Dictionary) -> Callable:
	return func(x: float) -> float: return absf(s.A * (x - s.p) * (x - s.q))


## How many times y = k meets y = f(x): two, one at the turning value, or none.
static func f_meets(s: Dictionary, k: int) -> int:
	var top: int = -s.dtop if s.A > 0 else s.dtop
	if k == top:
		return 1
	if s.A > 0:
		return 2 if k > top else 0
	return 2 if k < top else 0


func u_count_solutions(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var h: int = s.h
	var d: int = s.dtop
	var fh: int = -d if s.A > 0 else d
	var lines := ["f(x) = " + f_text(s)]
	var shape := [
		"f(x) = %s%s%s is 0 at x = %s and x = %s, and f(%s) = %s." % [Fmt.lead(s.A), Fmt.factor(p), Fmt.factor(q), N(p), N(q), N(h), N(fh)],
		"So y = |f(x)| meets the x-axis at x = %s and x = %s, with a hump between them whose top is %s; outside them each branch rises without bound." % [N(p), N(q), Fmt.point(h, d)],
	]
	var out := {"lines": lines}
	var k: int = s.k
	match s.ask:
		"count", "three":
			var n := 4 if k < d else 3
			var ans := Answer.make("number", {"v": Q.new(n)})
			ans.exact = true
			out.asked = "Find the number of solutions of |f(x)| = %d." % k
			out.answer = ans
			var fn := f_meets(s, k)
			out.wrongs = [wrong({"v": Q.new(fn)}, R_COUNT_F)] if fn != n else []
			out.fillers = [{"v": Q.new(2)}, {"v": Q.new(n - 1)}, {"v": Q.new(1)}, {"v": Q.new(0)}, {"v": Q.new(5)}]
			var meet := "The line y = %d, between 0 and %d, crosses the hump twice and each outer branch once." % [k, d] if n == 4 \
				else "The line y = %d touches the top of the hump and crosses each outer branch once." % k
			out.methods = steps_of({"graph-intersections": shape + [meet, "So |f(x)| = %d has %d solutions." % [k, n]]}, ans)
		"four":
			var ans := Answer.make("interval", {"shape": "between", "lo": Q.new(0), "hi": Q.new(d), "ends": "left out"}, {"var": "k"})
			ans.exact = true
			out.asked = "Find the set of values of k for which |f(x)| = k has exactly four solutions."
			out.answer = ans
			out.wrongs = []
			out.fillers = [{"shape": "between", "lo": Q.new(0), "hi": Q.new(d), "ends": "included"},
				{"shape": "outside", "lo": Q.new(0), "hi": Q.new(d), "ends": "left out"},
				{"shape": "between", "lo": Q.new(-d), "hi": Q.new(d), "ends": "left out"},
				{"shape": "between", "lo": Q.new(0), "hi": Q.new(absi(h)) if h != 0 and absi(h) != d else Q.new(2 * d), "ends": "left out"}]
			out.methods = steps_of({"graph-intersections": shape + [
				"A line y = k meets the graph four times when it crosses the hump twice and each outer branch once, for k between 0 and %d. At k = %d it touches the top (three solutions), and at k = 0 it meets only the zeros (two)." % [d, d],
				fin(ans)]}, ans)
		_:
			var ans := Answer.make("number", {"v": Q.new(d)}, {}, "k = ")
			ans.exact = true
			out.asked = "Find the value of k for which |f(x)| = k has exactly three solutions."
			out.answer = ans
			out.wrongs = []
			out.fillers = [{"v": Q.new(0)}, {"v": Q.new(-d)}, {"v": Q.new(h)}, {"v": Q.new(d + 1)}, {"v": Q.new(2 * d)}]
			out.methods = steps_of({"graph-intersections": shape + [
				"A line y = k crosses each outer branch once for k > 0, and meets the hump twice below its top, once at its top and not at all above it: three solutions only at the top.",
				fin(ans)]}, ans)
	if rep == "graph":
		out.lines.append("The graph of y = |f(x)| is shown.")
		var x0 := p - 3
		var x1 := q + 3
		var curves := [trace(f_count(s), x0, x1, [p, q])]
		if s.ask in ["count", "three"]:
			curves.append(trace(line_of(0.0, k), x0, x1))
		out.graph = Plot.spec(curves, [[h, d, Fmt.point(h, d)], [p, 0, ""], [q, 0, ""]], x0, x1, -2, d + 4)
	return out


# ── Inequalities against a constant ──────────────────────────

static func set_t(pieces: Array) -> String:
	return S.set_text(pieces)


## The ends written as the solutions of the equation: "x = −2 or x = 5".
static func ends_only(lo: Variant, hi: Variant) -> String:
	return "x = %s or x = %s" % [str(lo), str(hi)]


static func choice_of(right: String, bad: Array, plain: Array, rng: Seeded) -> Dictionary:
	return InverseRuleViews.pick_of(right, rng.shuffled(bad), plain)


static func tag(text: String, ref: String) -> Dictionary:
	return InverseRuleViews.tag(text, ref)


func _against_constant(lt: bool, s: Dictionary, rng: Seeded) -> Dictionary:
	var lo: Q = s.lo
	var hi: Q = s.hi
	var inc: bool = s.rel in ["≤", "≥"]
	var shift: bool = s.form == "shift"
	var inside := lin(1, -s.a) if shift else lin(s.a, s.b)
	var mod := md(1, -s.a) if shift else md(s.a, s.b)
	var right := set_t(S.between(lo, hi, inc) if lt else S.outside(lo, hi, inc))
	var bad: Array = [tag(ends_only(N(lo), N(hi)), R_BOUNDARY),
		tag(set_t(S.outside(lo, hi, not inc) if lt else S.between(lo, hi, not inc)), R_COMPLEMENT)]
	var r := "≤" if inc else "<"
	if lt:
		bad.append(tag("x %s %s" % [r, N(hi)], R_UPPER_ONLY))
	else:
		bad.append(tag("%s %s x %s %s" % [N(hi), r, r, N(lo)], R_CHAIN))
	var plain: Array = [set_t(S.between(lo, hi, not inc) if lt else S.outside(lo, hi, not inc)),
		set_t(S.between(hi.neg(), lo.neg(), inc) if lt else S.outside(hi.neg(), lo.neg(), inc)),
		set_t(S.outside(lo, hi, inc) if lt else S.between(lo, hi, inc))]
	var out := choice_of(right, bad, plain, rng)
	out.asked = "Solve the inequality."
	out.lines = ["%s %s %d" % [mod, s.rel, s.k]]
	var ans: Dictionary = out.answer
	var k: int = s.k
	var dist: Array
	if shift:
		dist = ["%s is the distance from x to %s on the number line." % [mod, N(s.a)],
			"%s %s %d: x is %s %d from %s, so %s." % [mod, s.rel, k, ("less than" if not inc else "at most") if lt else ("more than" if not inc else "at least"), k, N(s.a),
				"between %s and %s" % [N(lo), N(hi)] if lt else "below %s or above %s" % [N(lo), N(hi)]]]
	else:
		var centre := Q.new(-s.b, s.a)
		var rad := Q.new(k, s.a)
		dist = ["Take out %d: %s = %d|x %s %s|, so %s %s %d is |x %s %s| %s %s." % [s.a, mod, s.a, "−" if centre.sign() > 0 else "+", N(centre.abs_q()), mod, s.rel, k,
				"−" if centre.sign() > 0 else "+", N(centre.abs_q()), s.rel, N(rad)],
			"That is: the distance from x to %s is %s %s, so x is %s %s − %s = %s %s %s + %s = %s." % [N(centre), ("less than" if not inc else "at most") if lt else ("more than" if not inc else "at least"), N(rad),
				"between" if lt else "below", N(centre), N(rad), N(lo), "and" if lt else "or above", N(centre), N(rad), N(hi)]]
	dist.append(fin(ans))
	var sq0: String
	if shift:
		sq0 = Fmt.poly([1, -2 * s.a, s.a * s.a - k * k])
	else:
		sq0 = Fmt.poly([s.a * s.a, 2 * s.a * s.b, s.b * s.b - k * k])
	var sq := [
		"Both sides are at least 0, so squaring keeps the inequality: (%s)² %s %d." % [inside, s.rel, k * k],
		"Collect: %s %s 0, and %s = 0 at x = %s and x = %s." % [sq0, s.rel, sq0, N(lo), N(hi)],
		"Its x² term is positive, so it is %s 0 %s its roots%s." % ["below" if lt else "above", "between" if lt else "outside", ", and 0 at them" if inc else ""],
		fin(ans)]
	out.methods = steps_of({"distance-interpretation": dist, "square-then-quadratic": sq}, ans)
	return out


func u_modulus_less_than(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _against_constant(true, s, rng)


func u_modulus_greater_than(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _against_constant(false, s, rng)


# ── |x + a| against m|x − b| ─────────────────────────────────

func u_modulus_against_modulus(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var m: int = s.m
	var a: int = s.a
	var b: int = s.b
	var lo: Q = s.lo
	var hi: Q = s.hi
	var inc: bool = s.rel in ["≤", "≥"]
	var inside: bool = s.inside
	var left := md(1, a)
	var rightm := "%d%s" % [m, md(1, -b)]
	var right := set_t(S.between(lo, hi, inc) if inside else S.outside(lo, hi, inc))
	var bad: Array = [tag(ends_only(N(lo), N(hi)), R_BOUNDARY),
		tag(set_t(S.outside(lo, hi, not inc) if inside else S.between(lo, hi, not inc)), R_COMPLEMENT)]
	var plain: Array = [set_t(S.between(lo, hi, not inc) if inside else S.outside(lo, hi, not inc)),
		set_t(S.outside(lo, hi, inc) if inside else S.between(lo, hi, inc)),
		set_t(S.between(hi.neg(), lo.neg(), inc) if inside else S.outside(hi.neg(), lo.neg(), inc))]
	var out := choice_of(right, bad, plain, rng)
	out.asked = "Solve the inequality."
	out.lines = ["%s %s %s" % [left, s.rel, rightm]]
	var ans: Dictionary = out.answer
	if rep == "graph":
		out.lines.append("The graphs of y = %s and y = %s are shown." % [left, rightm])
		var w := window([lo.to_float(), hi.to_float(), -a, b], [absf(lo.to_float() + a), absf(hi.to_float() + a)])
		out.graph = Plot.spec([trace(v_of(1, a), w[0], w[1], [-a]), trace(v_of(1, -b, m), w[0], w[1], [b])], [], w[0], w[1], w[2], w[3])
	# m²(x − b)² − (x + a)² = ((m − 1)x − (mb + a))((m + 1)x + (a − mb)), with a positive x² term;
	# each factor is written in lowest terms, which only takes out a positive number.
	var quad := Fmt.poly([m * m - 1, -2 * m * m * b - 2 * a, m * m * b * b - a * a])
	var g1 := Q.gcd(m - 1, absi(m * b + a))
	var g2 := Q.gcd(m + 1, absi(a - m * b))
	var flip: String = {"<": ">", "≤": "≥", ">": "<", "≥": "≤"}[s.rel]
	var where := "between them" if inside else "outside them"
	var sq := [
		"Both sides are at least 0, so squaring keeps the inequality: (%s)² %s %d(%s)²." % [lin(1, a), s.rel, m * m, lin(1, -b)],
		"Take the left side from the right, which turns the sign round: %s %s 0, that is (%s)(%s) %s 0." % [quad, flip, lin((m - 1) / g1, -(m * b + a) / g1), lin((m + 1) / g2, (a - m * b) / g2), flip],
		"Its roots are x = %s and x = %s, and with a positive x² term it is %s 0 %s." % [N(lo), N(hi), "below" if inside else "above", where],
		fin(ans)]
	var gdc := [
		"Graph y = %s and y = %s on the GDC." % [left, rightm],
		"They meet at x = %s and x = %s, which are %s and %s." % [GdcKit.W(lo.to_float()), GdcKit.W(hi.to_float()), N(lo), N(hi)],
		"The steeper V, y = %s, is below y = %s between them (it is 0 at x = %s) and above it outside them%s." % [rightm, left, N(b), ", and they are equal at the crossings" if inc else ""],
		fin(ans)]
	out.methods = steps_of({"square-then-quadratic": sq, "gdc-graph-inequality": gdc}, ans)
	return out


# ── |f(x)| against a line, with the GDC ──────────────────────

static func curve_f(s: Dictionary) -> String:
	if s.fam == "quad":
		return Fmt.poly([1, s.B, s.C])
	return "%s%s x%s" % [Fmt.lead(s.A), s.fn, Fmt.plus(s.D) if s.D != 0 else ""]


static func curve_g(s: Dictionary) -> String:
	return Fmt.poly([s.m, s.c])


static func dom_text(s: Dictionary) -> String:
	return "%s ≤ x ≤ %s" % [s.dom[0].t, s.dom[1].t]


## The set with every crossing's end flipped in or out.
static func toggled(pieces: Array) -> Array:
	var out: Array = []
	for p in pieces:
		var c: Dictionary = p.duplicate()
		if c.lo != null and c.lo.get("x", false):
			c.lo_in = not c.lo_in
		if c.hi != null and c.hi.get("x", false):
			c.hi_in = not c.hi_in
		out.append(c)
	return out


func u_modulus_vs_curve(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var pieces: Array = s.set
	var right := set_t(pieces)
	var comp := S.complement(pieces, s.dom[0], s.dom[1])
	var bad: Array = [tag(set_t(comp), R_COMPLEMENT)]
	if not s.wide.is_empty():
		bad.append(tag(set_t(s.wide), R_DOMAIN))
	var plain: Array = [set_t(toggled(pieces)), "x = " + " or x = ".join(s.xs.map(func(x): return Fmt.sf(x))), set_t(toggled(comp))]
	var out := choice_of(right, bad, plain, rng)
	var g := curve_g(s)
	out.lines = ["f(x) = %s, %s" % [curve_f(s), dom_text(s)]]
	out.asked = "Solve |f(x)| %s %s. Give any end that is not exact to 3 s.f." % [s.rel, g]
	var ans: Dictionary = out.answer
	if rep == "graph":
		out.lines.append("The graphs of y = |f(x)| and y = %s are shown." % g)
		var lo: float = s.dom[0].v
		var hi: float = s.dom[1].v
		var fz: Array = []
		var prev := S.f_at(s, lo)
		for i in range(1, 401):
			var x := lo + (hi - lo) * i / 400.0
			var y := S.f_at(s, x)
			if (y > 0.0) != (prev > 0.0):
				fz.append(x)
			prev = y
		var curve := trace(func(x): return absf(S.f_at(s, x)), lo, hi, fz)
		var gl := trace(func(x): return S.g_at(s, x), lo, hi)
		var top := 2.0
		var bottom := -1.0
		for pt in curve + gl:
			top = maxf(top, pt[1])
			bottom = minf(bottom, pt[1])
		out.graph = Plot.spec([curve, gl], [], floori(lo) - 1, ceili(hi) + 1, maxi(floori(bottom) - 1, -8), mini(ceili(top) + 1, 16))
	var above: bool = s.rel in [">", "≥"]
	var meet := "x = " + " and x = ".join(s.xs.map(func(x): return GdcKit.W(x)))
	var gdc := [
		"Graph y = |%s| and y = %s on the GDC for %s." % [curve_f(s), g, dom_text(s)],
		"The GDC gives the crossing%s %s." % ["s" if s.xs.size() > 1 else "", meet],
		"The graph of y = |f(x)| is %s the line on %s, and the domain stops at x = %s and x = %s." % ["above" if above else "below", right, s.dom[0].t, s.dom[1].t],
		"So the solution set is %s." % right]
	out.methods = steps_of({"gdc-graph-inequality": gdc}, ans)
	return out
