class_name DeMoivreViews
extends ComplexPolarViews
## The views of t1-ahl-de-moivre (AHL1.14, FAL-1005) on the `de-moivre` situation, which is
## ComplexPolarSituation's recipe: powers by De Moivre's theorem in polar or Cartesian form, the
## least power of a kind, one or all of the nth roots and the polygon they make, multiple-angle
## and power identities, and the proof by induction with a line missing or wrong.
##
## A polar answer is a `form` answer as in ComplexPolarViews; the least power is a number; a
## polygon's side, perimeter or area is a `form` answer m√r with the root in the box's frame; a
## list of roots, an identity and a line of a proof are claims, picked from four.

const DP := "AHL1.14.de-moivre-powers#"
const NR := "AHL1.14.nth-roots#"
const MA := "AHL1.14.multiple-angle-identities#"
const DI := "AHL1.14.de-moivre-induction#"
const TD := "t1-ahl-de-moivre#"
const DM_UNKNOWNS := ["power-polar", "power-cartesian", "least-power", "nth-root", "all-roots", "roots-polygon", "multiple-angle",
	"power-reduction", "induction-gap", "induction-flaw"]
const KINDS := {"real": "real", "imaginary": "purely imaginary", "positive": "a positive real number", "negative": "a negative real number"}
const OTHER_KIND := {"real": "imaginary", "imaginary": "real", "positive": "negative", "negative": "positive"}
const SHAPES := {3: "an equilateral triangle", 4: "a square", 6: "a regular hexagon"}


## slip key -> the type's misconception ref (t1-ahl-de-moivre's list, in order).
func slips() -> Dictionary:
	return {
		"arg-kept": DP + "0", "mod-times": DP + "1", "parts": DP + "2",
		"principal": NR + "0", "mod-div": NR + "1", "after-div": NR + "2",
		"no-coef": MA + "0", "no-i": MA + "1", "i2-sign": MA + "2",
		"assume-next": DI + "0", "i2-expand": DI + "1", "no-base": DI + "2",
		"unreduced": TD + "12", "mod-kept": TD + "13", "full-turn": TD + "14", "other-kind": TD + "15", "quadrant": TD + "16",
		"half-space": TD + "17", "radius-side": TD + "18", "no-half": TD + "19", "no-divide": TD + "20",
	}


func unknowns() -> Array:
	return DM_UNKNOWNS


# ── Writing things ───────────────────────────────────────────

## A surd to a power, for a working line: "(√2)⁵", "2⁶".
static func base_pow(r: Array, n: int) -> String:
	var t := S.stext(r)
	return ("(%s)" % t if t.contains("√") or t.contains("/") or t.begins_with("−") else t) + Fmt.sup(n)


## An angle in a product, bracketed when negative: "(−π/4)".
static func pp(c: Q) -> String:
	return "(" + Fmt.pi(c) + ")" if c.sign() < 0 else Fmt.pi(c)


## The sentence that brings an argument into −π < θ ≤ π, or "" when it already is.
static func reduce_line(raw: Q, c: Q) -> String:
	if raw.eq(c):
		return ""
	var d := raw.sub(c)
	return "%s is outside −π < θ ≤ π, so %s %s: %s %s %s = %s." % [Fmt.pi(raw), "take away" if d.sign() > 0 else "add", Fmt.pi(d.abs_q()),
		Fmt.pi(raw), "−" if d.sign() > 0 else "+", Fmt.pi(d.abs_q()), Fmt.pi(c)]


## A list as the IB writes it: "A", "A or B", "A, B or C".
static func list_text(items: Array) -> String:
	if items.size() == 1:
		return items[0]
	return ", ".join(items.slice(0, -1)) + " or " + items[-1]


## The arguments as a list for a working line: "−π/2, π/6 and 5π/6".
static func args_text(args: Array) -> String:
	var t: Array = args.map(func(c): return Fmt.pi(c))
	if t.size() == 1:
		return t[0]
	return ", ".join(t.slice(0, -1)) + " and " + t[-1]


## The equation zⁿ = w as the question writes it.
static func root_line(s: Dictionary) -> String:
	var w := T(S.cart(s.big, s.phi)) if s.wform == "cartesian" else PT(s.big, s.phi, s.style)
	return "z%s = %s" % [Fmt.sup(s.n), w]


## m√r for a working line, with the root left out when it is 1.
static func ST(a: Array) -> String:
	return S.stext(a)


# ── Powers ───────────────────────────────────────────────────

func u_power_polar(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var r: Array = s.r
	var c: Q = s.c
	var n: int = s.n
	var style: String = s.style
	var R := S.spow(r, n)
	var raw: Q = c.mul(n)
	var C := S.principal(raw)
	var name := "z" + Fmt.sup(n)
	var head := name + " = "
	var ans := polar_ans(head, R, C, style)
	var wr: Array = [slip("arg-kept", pwrong(ans, head, R, c, style)), slip("mod-times", pwrong(ans, head, S.sscale(r, n), C, style))]
	if not raw.eq(C):
		wr.append(slip("unreduced", pwrong(ans, head, R, raw, style)))
	if not S.ssame(r, S.sd(1)):
		wr.append(slip("mod-kept", pwrong(ans, head, r, C, style)))
	var fill: Array = [pwrong(ans, head, R, S.principal(C.neg()), style), pwrong(ans, head, R, S.principal(C.add(Q.new(1, 2))), style),
		pwrong(ans, head, S.sscale(R, 2), C, style), pwrong(ans, head, R, S.principal(C.add(1)), style)]
	var last := "So %s = %s." % [name, PT(R, C, style)]
	var steps: Array = ["By De Moivre's theorem, (r cis θ)^%d = r%s cis(%dθ): raise the modulus to the power and multiply the argument by it." % [n, Fmt.sup(n), n],
		"|%s| = %s = %s" % [name, base_pow(r, n), ST(R)], "arg %s = %d × %s = %s" % [name, n, pp(c), Fmt.pi(raw)]]
	if not raw.eq(C):
		steps.append(reduce_line(raw, C))
	steps.append(last)
	return _pack(["z = " + PT(r, c, style)], polar_ask(name, style), ans, wr, fill, {"de-moivre": steps}, rng)


## aⁿ + (bi)ⁿ, each part raised on its own: [] when the real parts don't add to one surd.
static func parts_power(z: Array, n: int) -> Array:
	var an := S.spow(z[0], n)
	var bn := S.spow(z[1], n)
	match n % 4:
		0:
			var re := S.sadd(an, bn)
			return [] if re.is_empty() else [re, S.sd(0)]
		1:
			return [an, bn]
		2:
			var re := S.sadd(an, S.sneg(bn))
			return [] if re.is_empty() else [re, S.sd(0)]
	return [an, S.sneg(bn)]


## zᵏ for a working line.
static func zk(r: Array, c: Q, k: int) -> Array:
	return S.cart(S.spow(r, k), S.principal(c.mul(k)))


func u_power_cartesian(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var r: Array = s.r
	var c: Q = s.c
	var n: int = s.n
	var z := S.cart(r, c)
	var R := S.spow(r, n)
	var raw: Q = c.mul(n)
	var C := S.principal(raw)
	var P := S.cart(R, C)
	var name := "z" + Fmt.sup(n)
	var head := name + " = "
	var ans := cart_ans(head, P)
	var wr: Array = [slip("arg-kept", cwrong(ans, head, S.cart(R, c))), slip("mod-times", cwrong(ans, head, S.cart(S.sscale(r, n), C)))]
	var sep := parts_power(z, n)
	if not sep.is_empty():
		wr.append(slip("parts", cwrong(ans, head, sep)))
	var fill: Array = [cwrong(ans, head, [P[0], S.sneg(P[1])]), cwrong(ans, head, [S.sneg(P[0]), S.sneg(P[1])]), cwrong(ans, head, [P[1], P[0]]),
		cwrong(ans, head, [S.sscale(P[0], 2), S.sscale(P[1], 2)]), cwrong(ans, head, [S.sneg(P[0]), P[1]])]
	var al := ref_angle(c)
	var ratio := ST(S.sd(z[1][0].abs_q(), z[1][1])) + "/" + ST(S.sd(z[0][0].abs_q(), z[0][1]))
	var to_polar := "The angle with the real axis is arctan(%s) = %s. %s So z = %s." % [ratio, Fmt.pi(al), placed(c), PT(r, c, "cis")]
	var dm := "By De Moivre's theorem, %s = %s cis(%d × %s) = %s cis(%s)%s." % [name, base_pow(r, n), n, pp(c), ST(R), Fmt.pi(raw),
		"" if raw.eq(C) else " = %s cis(%s)" % [ST(R), Fmt.pi(C)]]
	var methods := {"de-moivre": [mod_line(z, r) + ".", to_polar, dm, "%s, so %s = %s." % [trig_line(C), name, T(P)]]}
	# Squaring and multiplying: z², then z⁴ or z³, then zⁿ.
	var chain: Dictionary = {3: [[2, 1, 1], [3, 2, 1]], 4: [[2, 1, 1], [4, 2, 2]], 5: [[2, 1, 1], [4, 2, 2], [5, 4, 1]],
		6: [[2, 1, 1], [3, 2, 1], [6, 3, 3]], 8: [[2, 1, 1], [4, 2, 2], [8, 4, 4]]}
	if chain.has(n):
		var sq_steps: Array = []
		for st: Array in chain[n]:
			var k: int = st[0]
			var a: int = st[1]
			var b: int = st[2]
			var zt := T(zk(r, c, k))
			var za := "z" if a == 1 else "z" + Fmt.sup(a)
			if a == b:
				sq_steps.append("z%s = (%s)² = (%s)² = %s" % [Fmt.sup(k), za, T(zk(r, c, a)), zt])
			else:
				sq_steps.append("z%s = %s × z = (%s)(%s) = %s" % [Fmt.sup(k), za, T(zk(r, c, a)), T(z), zt])
		sq_steps[0] = sq_steps[0].replace("(z)² = ", "") + ", as i² = −1"
		sq_steps.append("So %s = %s." % [name, T(P)])
		methods["repeated-squaring"] = sq_steps
	if int(P[0][1]) == 1 and int(P[1][1]) == 1:
		methods["gdc-power"] = ["Set the GDC to complex mode and enter (%s)^%d." % [T(z), n],
			"It shows %s; both parts are whole numbers, so the value is exact." % T(P), "So %s = %s." % [name, T(P)]]
	return _pack(["z = " + T(z)], "Find %s in the form a + bi." % name, ans, wr, fill, methods, rng)


func u_least_power(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var c: Q = s.c
	var r: Array = s.r
	var mode: String = s.mode
	var cartesian: bool = s.form == "cartesian"
	var z := S.cart(r, c)
	var n := S.least_n(c, mode)
	var ans := Answer.make("number", {"v": Q.new(n)}, {}, "n = ")
	ans.exact = true
	var wr: Array = []
	if mode == "real":
		var m := S.least_n(c, "positive")
		if m > 0 and m != n:
			wr.append(slip("full-turn", {"v": Q.new(m)}))
	var o := S.least_n(c, OTHER_KIND[mode])
	if o > 0 and o != n:
		wr.append(slip("other-kind", {"v": Q.new(o)}))
	if cartesian and S.quadrant(c) in [2, 3]:
		var m := S.least_n(atan_ratio(c), mode)
		if m > 0 and m != n:
			wr.append(slip("quadrant", {"v": Q.new(m)}))
	var fill: Array = [{"v": Q.new(n + 1)}, {"v": Q.new(2 * n)}, {"v": Q.new(n - 1)}, {"v": Q.new(n + 2)}]
	var intro: Array
	if cartesian:
		var ratio := ST(S.sd(z[1][0].abs_q(), z[1][1])) + "/" + ST(S.sd(z[0][0].abs_q(), z[0][1]))
		intro = [mod_line(z, r) + ".", "The angle with the real axis is arctan(%s) = %s. %s" % [ratio, Fmt.pi(ref_angle(c)), placed(c)]]
	else:
		intro = ["|z| = %s and arg z = %s." % [ST(r), Fmt.pi(c)]]
	var cond: String = {"real": "a multiple of π", "imaginary": "an odd multiple of π/2", "positive": "a multiple of 2π", "negative": "an odd multiple of π"}[mode]
	var nc: Q = c.mul(n)
	var least := "n = %d gives %d × %s = %s, %s, and no smaller n does." % [n, n, pp(c), Fmt.pi(nc), cond]
	var arg_cond: Array = intro + ["arg(z^n) = n × %s, and z^n is %s when this is %s." % [pp(c), KINDS[mode], cond], least, "So n = %d." % n]
	var trig: String = {"real": "sin(n × %s) = 0", "imaginary": "cos(n × %s) = 0", "positive": "cos(n × %s) = 1", "negative": "cos(n × %s) = −1"}[mode] % pp(c)
	var value := T(S.cart(S.spow(r, n), S.principal(nc)))
	var dm: Array = intro + ["By De Moivre's theorem, z^n = %s^n(cos(n × %s) + i sin(n × %s)), which is %s when %s." % [ST(r) if not ST(r).contains("√") else "(" + ST(r) + ")", pp(c), pp(c), KINDS[mode], trig],
		"The least such n is %d: z^%d = %s cis(%s) = %s." % [n, n, ST(S.spow(r, n)), Fmt.pi(S.principal(nc)), value], "So n = %d." % n]
	var lines: Array = ["z = " + (T(z) if cartesian else PT(r, c, s.style))]
	return _pack(lines, "Find the least positive integer n for which z^n is %s." % KINDS[mode], ans, wr, fill, {"argument-condition": arg_cond, "de-moivre": dm}, rng)


# ── Roots ────────────────────────────────────────────────────

## The arguments (φ + kπ)/n, k = 0 to n − 1: the roots spaced π/n apart, least first.
static func half_args(phi: Q, n: int) -> Array:
	var out: Array = []
	for k in n:
		out.append(phi.add(k).div(n))
	out.sort_custom(func(a, b): return a.lt(b))
	return out


## The argument the question's rule picks from a list, or null: the least positive, the
## greatest, or the only one in the quadrant.
static func pick_arg(args: Array, mode: String, quad: int) -> Variant:
	match mode:
		"least-positive":
			for c in args:
				if Q.new(0).lt(c):
					return c
			return null
		"greatest":
			return args[-1]
	var inq: Array = args.filter(func(c): return S.quadrant(c) == quad)
	return inq[0] if inq.size() == 1 else null


## The two opening lines of the polar working: w with its general argument, then the roots.
static func general_lines(s: Dictionary) -> Array:
	var n: int = s.n
	return ["|w| = %s and arg w = %s, so z%s = %s cis(%s + 2kπ) for any integer k." % [ST(s.big), Fmt.pi(s.phi), Fmt.sup(n), ST(s.big), Fmt.pi(s.phi)],
		"So z = %s^(1/%d) cis((%s + 2kπ)/%d) = %d cis((%s + 2kπ)/%d), for k = 0 to %d." % [ST(s.big), n, Fmt.pi(s.phi), n, s.rho, Fmt.pi(s.phi), n, n - 1]]


## The opening lines of the polygon working: the circle, then one root and the spacing.
static func polygon_lines(s: Dictionary) -> Array:
	var n: int = s.n
	var first: Q = s.phi.div(n)
	return ["|z|%s = |w| = %s, so every root has modulus %s^(1/%d) = %d." % [Fmt.sup(n), ST(s.big), ST(s.big), n, s.rho],
		"One root has argument %s/%d = %s, and the %d roots are spaced 2π/%d = %s apart round the circle." % [pp(s.phi), n, Fmt.pi(first), n, n, Fmt.pi(Q.new(2, n))]]


func u_nth_root(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var rho: int = s.rho
	var phi: Q = s.phi
	var style: String = s.style
	var mode: String = s.mode
	var quad: int = s.get("quad", 0)
	var roots := S.root_args(phi, n)
	var C: Q = S.chosen_root(s)
	var R := S.sd(rho)
	var head := "z = "
	var ans := polar_ans(head, R, C, style)
	var wr: Array = []
	var p0 := phi.div(n)
	if not p0.eq(C):
		wr.append(slip("principal", pwrong(ans, head, R, p0, style)))
	var big := int(pow(rho, n))
	if big % n == 0 and big / n != rho:
		wr.append(slip("mod-div", pwrong(ans, head, S.sd(big / n), C, style)))
	var hs: Variant = pick_arg(half_args(phi, n), mode, quad)
	if hs != null and not hs.eq(C):
		wr.append(slip("half-space", pwrong(ans, head, R, hs, style)))
	var fill: Array = []
	for c in roots:
		if not c.eq(C):
			fill.append(pwrong(ans, head, R, c, style))
	fill = fill.slice(0, 2) + [pwrong(ans, head, S.sscale(R, 2), C, style), pwrong(ans, head, R, S.principal(C.neg()), style),
		pwrong(ans, head, R, S.principal(C.add(Q.new(1, 2))), style)]
	var which: String = {"least-positive": "Find the root of this equation with the least positive argument.",
		"greatest": "Find the root of this equation with the greatest argument.",
		"quadrant": "One root of this equation lies in the %s quadrant. Find this root." % QUADRANTS[quad]}[mode]
	var asked := which + " Give it in the form %s, where r > 0 and −π < θ ≤ π." % form_name(style)
	var pick: String = {"least-positive": "The least positive of these is %s", "greatest": "The greatest of these is %s",
		"quadrant": "The one in the %s quadrant is %s" % [QUADRANTS[quad], "%s"]}[mode] % Fmt.pi(C)
	var last := "%s, so z = %s." % [pick, PT(R, C, style)]
	var general: Array = general_lines(s) + ["For k = 0 to %d, brought into −π < θ ≤ π, the arguments are %s." % [n - 1, args_text(roots)], last]
	var polygon: Array = polygon_lines(s) + ["Turning by %s each time, the arguments in −π < θ ≤ π are %s." % [Fmt.pi(Q.new(2, n)), args_text(roots)], last]
	return _pack([root_line(s)], asked, ans, wr, fill, {"polar-general-argument": general, "regular-polygon": polygon}, rng)


## Every root, as the answer lists them: "z = 2e^(−πi/2), 2e^(πi/6) or 2e^(5πi/6)".
static func roots_text(R: Array, args: Array, style: String, out: String) -> String:
	var items: Array = args.map(func(c): return T(S.cart(R, c)) if out == "cartesian" else PT(R, c, style))
	return "z = " + list_text(items)


static func sorted_q(args: Array) -> Array:
	var out := args.duplicate()
	out.sort_custom(func(a, b): return a.lt(b))
	return out


static func all_special(args: Array) -> bool:
	return args.all(func(c): return S.is_special(c))


func u_all_roots(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var rho: int = s.rho
	var phi: Q = s.phi
	var style: String = s.style
	var out: String = s.out
	var args := S.root_args(phi, n)
	var R := S.sd(rho)
	var right := roots_text(R, args, style, out)
	var ans := claim_ans(right)
	var p0 := phi.div(n)
	var one: String = T(S.cart(R, p0)) if out == "cartesian" else PT(R, p0, style)
	var wr: Array = [slip("principal", claim("z = %s only" % one))]
	var big := int(pow(rho, n))
	if big % n == 0 and big / n != rho:
		wr.append(slip("mod-div", claim(roots_text(S.sd(big / n), args, style, out))))
	if out == "polar":
		var unred: Array = []
		for k in n:
			unred.append(PT(R, p0.add(2 * k), style))
		wr.append(slip("after-div", claim("z = " + list_text(unred))))
	var hs := half_args(phi, n)
	if out == "polar" or all_special(hs):
		wr.append(slip("half-space", claim(roots_text(R, hs, style, out))))
	var conj := sorted_q(args.map(func(c): return S.principal(c.neg())))
	var quarter := sorted_q(args.map(func(c): return S.principal(c.add(Q.new(1, 2)))))
	var turned := sorted_q(args.map(func(c): return S.principal(c.add(Q.new(1, n)))))
	var fill: Array = [claim(roots_text(R, conj, style, out)), claim(roots_text(S.sd(2 * rho), args, style, out)), claim(roots_text(R, quarter, style, out))]
	if out == "polar" or all_special(turned):
		fill.append(claim(roots_text(R, turned, style, out)))
	var form := "re^(iθ), where r > 0 and −π < θ ≤ π" if style == "euler" else "r cis θ, where r > 0 and −π < θ ≤ π"
	var asked := "Find all the roots of this equation, giving them in the form %s." % (form if out == "polar" else "a + bi")
	var last := ("Writing each in the form a + bi, %s." if out == "cartesian" else "So %s.") % right
	var argline := "For k = 0 to %d, brought into −π < θ ≤ π, the arguments are %s." % [n - 1, args_text(args)]
	var methods := {"polar-general-argument": general_lines(s) + [argline, last],
		"regular-polygon": polygon_lines(s) + ["Turning by %s each time, the arguments in −π < θ ≤ π are %s." % [Fmt.pi(Q.new(2, n)), args_text(args)], last]}
	if phi.is_zero() and n in [3, 4] and out == "cartesian":
		var lead := "z%s − %d" % [Fmt.sup(n), big]
		if n == 4:
			var b := rho * rho
			var pm := "±%s" % ("" if rho == 1 else str(rho))
			methods["factorise"] = ["%s = (z² − %d)(z² + %d) = 0." % [lead, b, b],
				"z² = %d gives z = ±%d, and z² = −%d gives z = %si." % [b, rho, b, pm], "So %s." % right]
		else:
			var zt := "z" if rho == 1 else "%dz" % rho
			var quad := "z² + %s + %d" % [zt, rho * rho]
			var pair: Array = args.filter(func(c): return not c.is_zero()).map(func(c): return T(S.cart(R, c)))
			methods["factorise"] = ["%s = (z − %d)(%s) = 0, so z = %d or %s = 0." % [lead, rho, quad, rho, quad],
				"By the quadratic formula, z = (−%d ± √(%d − %d))/2 = (−%d ± √(−%d))/2, so z = %s or z = %s." % [rho, rho * rho, 4 * rho * rho, rho, 3 * rho * rho, pair[0], pair[1]],
				"So %s." % right]
	return _pack([root_line(s)], asked, ans, wr, fill, methods, rng)


## The answer m√r for a length or an area, the root written in the box's frame.
static func surd_ans(head: String, v: Array) -> Dictionary:
	var parts: Array = [head, {"slot": "m"}]
	if int(v[1]) != 1:
		parts.append("√%d" % v[1])
	var ans := Answer.make("form", {"m": v[0], "text": head + ST(v)}, {"parts": parts, "root": int(v[1])})
	ans.exact = true
	return ans


## A wrong m√r: typed where its root is the answer's, else only picked.
static func surd_wrong(ans: Dictionary, head: String, v: Array) -> Dictionary:
	if int(v[1]) == int(ans.fixed.root):
		return {"m": v[0], "text": head + ST(v)}
	return other(head + ST(v))


## The side 2ρ sin(π/n), the perimeter or the area (n/2)ρ² sin(2π/n) of the polygon.
static func polygon_value(n: int, rho: Q, mode: String) -> Array:
	var side: Array = {3: [rho, 3], 4: [rho, 2], 6: [rho, 1]}[n]
	match mode:
		"side":
			return side
		"perimeter":
			return S.sscale(side, n)
	var r2 := rho.sq()
	return {3: [r2.mul(Q.new(3, 4)), 3], 4: [r2.mul(2), 1], 6: [r2.mul(Q.new(3, 2)), 3]}[n]


func u_roots_polygon(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var rho: int = s.rho
	var mode: String = s.mode
	var head: String = {"side": "Side = ", "area": "Area = ", "perimeter": "Perimeter = "}[mode]
	var v := polygon_value(n, Q.new(rho), mode)
	var ans := surd_ans(head, v)
	var wr: Array = []
	var big := int(pow(rho, n))
	if big % n != 0 or big / n != rho:
		wr.append(slip("mod-div", surd_wrong(ans, head, polygon_value(n, Q.new(big, n), mode))))
	if n != 6:
		var rq := Q.new(rho)
		var as_side: Array = {"side": [rq, 1], "perimeter": [rq.mul(n), 1], "area": [rq.sq().div(4), 3] if n == 3 else [rq.sq(), 1]}[mode]
		wr.append(slip("radius-side", surd_wrong(ans, head, as_side)))
	if mode == "area":
		wr.append(slip("no-half", surd_wrong(ans, head, S.sscale(v, 2))))
	var fill: Array = [surd_wrong(ans, head, S.sscale(v, 2)), surd_wrong(ans, head, S.sscale(v, Q.new(1, 2))), surd_wrong(ans, head, S.sscale(v, 3)),
		surd_wrong(ans, head, [v[0], 3 if int(v[1]) == 1 else 1])]
	var what: String = {"side": "length of each side", "area": "area", "perimeter": "perimeter"}[mode]
	var asked := "The roots of this equation are the vertices of a regular polygon on the Argand diagram. Find the exact %s of the polygon." % what
	var side := polygon_value(n, Q.new(rho), "side")
	var last := head + ST(v) + "."
	var tail: Array
	match mode:
		"side":
			tail = [last]
		"perimeter":
			tail = ["The perimeter is %d × %s = %s." % [n, ST(side), ST(v)], last]
		_:
			tail = ["The polygon is %d triangles from 0, each with two sides %d and the angle 2π/%d between them: area = %d × (1/2) × %d² × sin(2π/%d) = %s." % [n, rho, n, n, rho, n, ST(v)], last]
	var s2: Q = {3: Q.new(3 * rho * rho), 4: Q.new(2 * rho * rho), 6: Q.new(rho * rho)}[n]
	var a0: Q = s.phi.div(n)
	var a1: Q = S.principal(s.phi.add(2).div(n))
	var general: Array = ["The roots are %d cis((%s + 2kπ)/%d), k = 0 to %d; two next to each other are %s and %s." % [rho, Fmt.pi(s.phi), n, n - 1, PT(S.sd(rho), a0, "cis"), PT(S.sd(rho), a1, "cis")],
		"The angle between them at 0 is 2π/%d, so by the cosine rule the side s has s² = %d² + %d² − 2 × %d × %d × cos(2π/%d) = %s, so s = %s." % [n, rho, rho, rho, rho, n, s2.text(), ST(side)]] + tail
	var shape: String = SHAPES[n]
	var polygon: Array = ["|w| = %s, so the roots lie on the circle of radius %s^(1/%d) = %d about 0." % [ST(s.big), ST(s.big), n, rho],
		"They are %d points spaced 2π/%d apart, the vertices of %s with circumradius %d." % [n, n, shape, rho]]
	if mode == "area":
		polygon += tail
	else:
		polygon.append("Each side subtends 2π/%d at 0, so its length is 2 × %d × sin(π/%d) = %s." % [n, rho, n, ST(side)])
		polygon += tail
	return _pack([root_line(s)], asked, ans, wr, fill, {"regular-polygon": polygon, "polar-general-argument": general}, rng)


# ── Identities ───────────────────────────────────────────────

static func binom(n: int, k: int) -> int:
	var out := 1
	for i in k:
		out = out * (n - i) / (i + 1)
	return out


## The real part (cos) or the imaginary part (sin) of (cos θ + i sin θ)ⁿ as a polynomial in
## cos θ (or sin θ), coefficients by power. coef false leaves out the binomial coefficients,
## sign false the signs from i².
static func ma_poly(fn: String, n: int, coef: bool = true, sign: bool = true) -> Array:
	var out: Array = []
	out.resize(n + 1)
	out.fill(0)
	for k in range(0, n + 1):
		if (k % 2 == 0) != (fn == "cos"):
			continue
		var cf := binom(n, k) if coef else 1
		if sign and (k / 2) % 2 == 1:
			cf = -cf
		# cos: sin^k = (1 − cos²)^(k/2); sin: cos^(n−k) = (1 − sin²)^((n−k)/2).
		var m := k / 2 if fn == "cos" else (n - k) / 2
		var base := n - k if fn == "cos" else k
		for j in range(0, m + 1):
			out[base + 2 * j] += cf * binom(m, j) * (1 if j % 2 == 0 else -1)
	return out


## A product of powers for a working line: "cos³θ", "cos θ", "" for the power 0.
static func fac(fn: String, e: int, L: String) -> String:
	if e == 0:
		return ""
	return fn + " " + L if e == 1 else fn + Fmt.sup(e) + L


## Signed terms [coefficient, its text without the sign] joined: "4cos³θ − 3cos θ".
static func signed_join(items: Array) -> String:
	var out := ""
	for i in items.size():
		var neg: bool = items[i][0] < 0
		if i == 0:
			out = ("−" if neg else "") + items[i][1]
		else:
			out += (" − " if neg else " + ") + items[i][1]
	return out


## A coefficient's size in front of a term: "" for 1.
static func lead(cf: int, body: String) -> String:
	var a := absi(cf)
	if body == "":
		return str(a)
	return ("" if a == 1 else str(a)) + body


## A polynomial in cos θ or sin θ, highest power first unless that term is negative.
static func poly_text(p: Array, fn: String, L: String) -> String:
	var terms: Array = []
	for e in range(p.size() - 1, -1, -1):
		if p[e] != 0:
			terms.append([p[e], lead(p[e], fac(fn, e, L))])
	if terms.is_empty():
		return "0"
	if terms[0][0] < 0:
		terms.reverse()
	return signed_join(terms)


func u_multiple_angle(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var fn: String = s.fn
	var n: int = s.n
	var L: String = s.letter
	var lhs := "%s %d%s" % [fn, n, L]
	var right := "%s = %s" % [lhs, poly_text(ma_poly(fn, n), fn, L)]
	var ans := claim_ans(right)
	var wr: Array = [slip("no-coef", claim("%s = %s" % [lhs, poly_text(ma_poly(fn, n, false), fn, L)])),
		slip("i2-sign", claim("%s = %s" % [lhs, poly_text(ma_poly(fn, n, true, false), fn, L)]))]
	var p := ma_poly(fn, n)
	var low := p.duplicate()
	for e in p.size():
		if p[e] != 0:
			low[e] = -p[e]
			break
	var top := p.duplicate()
	top[n] = 2 * p[n]
	var neg: Array = p.map(func(x): return -x)
	var fill: Array = [claim("%s = %s" % [lhs, poly_text(low, fn, L)]), claim("%s = %s" % [lhs, poly_text(top, fn, L)]),
		claim("%s = %s" % [lhs, poly_text(neg, fn, L)])]
	var other_fn := "sin" if fn == "cos" else "cos"
	var cis := "cos %s + i sin %s" % [L, L]
	# The binomial expansion's real (cos) or imaginary (sin) part, in cos and sin.
	var raw: Array = []
	var subst: Array = []
	for k in range(0, n + 1):
		if (k % 2 == 0) != (fn == "cos"):
			continue
		var cf := binom(n, k) * (-1 if (k / 2) % 2 == 1 else 1)
		raw.append([cf, lead(cf, " ".join([fac("cos", n - k, L), fac("sin", k, L)].filter(func(t): return t != "")))])
		var keep := fac("cos", n - k, L) if fn == "cos" else fac("sin", k, L)
		var swap := (k if fn == "cos" else n - k) / 2
		var br := "" if swap == 0 else "(1 − %s²%s)%s" % [fn, L, Fmt.sup(swap)]
		subst.append([cf, lead(cf, keep + br)])
	var part := "real" if fn == "cos" else "imaginary"
	var binomial: Array = ["By De Moivre's theorem, cos %d%s + i sin %d%s = (%s)%s, and the binomial theorem expands the right side." % [n, L, n, L, cis, Fmt.sup(n)],
		"Equating the %s parts, %s = %s." % [part, lhs, signed_join(raw)],
		"Replace %s²%s by 1 − %s²%s: %s = %s." % [other_fn, L, fn, L, lhs, signed_join(subst)], "So %s." % right]
	var methods := {"binomial-real-part": binomial}
	var c2 := "2cos²%s − 1" % L
	match "%s%d" % [fn, n]:
		"cos2":
			methods["compound-angle-route"] = ["cos 2%s = cos(%s + %s) = cos²%s − sin²%s." % [L, L, L, L, L],
				"Replace sin²%s by 1 − cos²%s: cos²%s − (1 − cos²%s)." % [L, L, L, L], "So %s." % right]
		"cos3":
			methods["compound-angle-route"] = ["cos 3%s = cos(2%s + %s) = cos 2%s cos %s − sin 2%s sin %s." % [L, L, L, L, L, L, L],
				"With cos 2%s = %s and sin 2%s = 2sin %s cos %s, this is (%s)cos %s − 2sin²%s cos %s." % [L, c2, L, L, L, c2, L, L, L],
				"Replace sin²%s by 1 − cos²%s: 2cos³%s − cos %s − 2cos %s + 2cos³%s." % [L, L, L, L, L, L], "So %s." % right]
		"cos4":
			methods["compound-angle-route"] = ["cos 4%s = cos(2 × 2%s) = 2cos²(2%s) − 1." % [L, L, L],
				"With cos 2%s = %s, this is 2(%s)² − 1 = 2(4cos⁴%s − 4cos²%s + 1) − 1." % [L, c2, c2, L, L], "So %s." % right]
		"sin3":
			methods["compound-angle-route"] = ["sin 3%s = sin(2%s + %s) = sin 2%s cos %s + cos 2%s sin %s." % [L, L, L, L, L, L, L],
				"With sin 2%s = 2sin %s cos %s and cos 2%s = 1 − 2sin²%s, this is 2sin %s cos²%s + sin %s − 2sin³%s." % [L, L, L, L, L, L, L, L, L],
				"Replace cos²%s by 1 − sin²%s: 2sin %s − 2sin³%s + sin %s − 2sin³%s." % [L, L, L, L, L, L], "So %s." % right]
	return _pack([], "Express %s as a polynomial in %s %s." % [lhs, fn, L], ans, wr, fill, methods, rng)


## The coefficients of cosⁿθ (fn cos) or sinⁿθ (fn sin) in multiple angles, from (z ± 1/z)ⁿ:
## [the terms' function, {m: Q}], m = 0 the constant. coef false leaves out the binomial
## coefficients, with_i false takes z − 1/z as 2 sin θ, divide false leaves out the 2ⁿ.
static func pr_terms(fn: String, n: int, coef: bool = true, with_i: bool = true, divide: bool = true) -> Array:
	var a: Array = []
	for k in n + 1:
		a.append((binom(n, k) if coef else 1) * (-1 if fn == "sin" and k % 2 == 1 else 1))
	var tfn := "sin" if fn == "sin" and n % 2 == 1 else "cos"
	var out := {}
	for k in n + 1:
		var m := n - 2 * k
		if m > 0:
			out[m] = Q.new(2 * a[k])
		elif m == 0:
			out[0] = Q.new(a[k])
	# (2cos θ)ⁿ = 2ⁿcosⁿθ; (2i sin θ)ⁿ = 2ⁿiⁿ sinⁿθ, and an odd power's 2i sin mθ leaves i^(n − 1).
	var den := Q.new(int(pow(2, n)) if divide else 1)
	if fn == "sin" and with_i:
		var sgn := 1 if ((n - 1) / 2 if n % 2 == 1 else n / 2) % 2 == 0 else -1
		den = den.mul(sgn)
	var res := {}
	for m in out:
		res[m] = out[m].div(den)
	return [tfn, res]


## A sum of multiple angles over a common denominator: "(cos 3θ + 3cos θ)/4".
static func pr_text(t: Array, L: String) -> String:
	var fn: String = t[0]
	var co: Dictionary = t[1]
	var ms: Array = co.keys()
	ms.sort()
	ms.reverse()
	var den := 1
	for m in ms:
		var d: int = co[m].d
		den = den / Q.gcd(den, d) * d
	var terms: Array = []
	for m in ms:
		var v: int = co[m].mul(den).n
		if v != 0:
			terms.append([v, lead(v, "" if m == 0 else "%s %s%s" % [fn, "" if m == 1 else str(m), L])])
	if terms[0][0] < 0:
		terms.reverse()
	var body := signed_join(terms)
	return body if den == 1 else "(%s)/%d" % [body, den]


func u_power_reduction(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var mode: String = s.mode
	var fn := mode.substr(0, 3)
	var n := int(mode.substr(3))
	var L: String = s.letter
	var lhs := "%s%s%s" % [fn, Fmt.sup(n), L]
	var t := pr_terms(fn, n)
	var right := "%s = %s" % [lhs, pr_text(t, L)]
	var ans := claim_ans(right)
	var wr: Array = [slip("no-coef", claim("%s = %s" % [lhs, pr_text(pr_terms(fn, n, false), L)])),
		slip("no-divide", claim("%s = %s" % [lhs, pr_text(pr_terms(fn, n, true, true, false), L)]))]
	if mode == "sin3":
		wr.append(slip("no-i", claim("%s = %s" % [lhs, pr_text(pr_terms(fn, n, true, false), L)])))
	var co: Dictionary = t[1]
	var ms: Array = co.keys()
	ms.sort()
	var halved := {}
	var low := {}
	var high := {}
	for m in ms:
		halved[m] = co[m].div(2)
		low[m] = co[m].neg() if m == ms[0] else co[m]
		high[m] = co[m].neg() if m == ms[-1] else co[m]
	var fill: Array = [claim("%s = %s" % [lhs, pr_text([t[0], halved], L)]), claim("%s = %s" % [lhs, pr_text([t[0], low], L)]),
		claim("%s = %s" % [lhs, pr_text([t[0], high], L)])]
	var names: Array = []
	ms.reverse()
	for m in ms:
		names.append("a constant" if m == 0 else "%s %s%s" % [t[0], "" if m == 1 else str(m), L])
	var asked := "Use z = cos %s + i sin %s to express %s in terms of %s." % [L, L, lhs, list_text(names).replace(" or ", " and ")]
	# (z ± 1/z)ⁿ term by term, then grouped in pairs.
	var sg := "+" if fn == "cos" else "−"
	var terms: Array = []
	var groups: Array = []
	for k in n + 1:
		var a := binom(n, k) * (-1 if fn == "sin" and k % 2 == 1 else 1)
		var e := n - 2 * k
		var zt := ("z" + Fmt.sup(e)) if e > 0 else ("" if e == 0 else "/z" + Fmt.sup(-e))
		terms.append([a, (lead(a, zt) if e >= 0 else str(absi(a)) + zt)])
		if e > 0:
			var b := binom(n, n - k) * (-1 if fn == "sin" and (n - k) % 2 == 1 else 1)
			var inner := "z%s %s 1/z%s" % [Fmt.sup(e), "+" if b * a > 0 else "−", Fmt.sup(e)]
			groups.append([a, ("" if absi(a) == 1 else str(absi(a))) + "(" + inner + ")"])
		elif e == 0:
			groups.append([a, str(absi(a))])
	var odd_sin := fn == "sin" and n % 2 == 1
	var lhs2: String
	if fn == "cos":
		lhs2 = "%dcos%s%s" % [int(pow(2, n)), Fmt.sup(n), L]
	else:
		var sgn := 1 if ((n - 1) / 2 if odd_sin else n / 2) % 2 == 0 else -1
		lhs2 = "%s%d%s sin%s%s" % ["−" if sgn < 0 else "", int(pow(2, n)), "i" if odd_sin else "", Fmt.sup(n), L]
	var rhs: Array = []
	var raw: Dictionary = pr_terms(fn, n, true, true, false)[1]
	var sgn2 := 1
	if fn == "sin":
		sgn2 = 1 if ((n - 1) / 2 if odd_sin else n / 2) % 2 == 0 else -1
	var rms: Array = raw.keys()
	rms.sort()
	rms.reverse()
	for m in rms:
		var v: int = raw[m].mul(sgn2).n
		var body := "" if m == 0 else "%s%s %s%s" % ["i " if odd_sin else "", t[0], "" if m == 1 else str(m), L]
		if odd_sin and m != 0:
			body = "i sin %s%s" % ["" if m == 1 else str(m), L]
		rhs.append([v, lead(v, body)])
	var pair := "z^m + z^(−m) = 2cos m%s" % L if fn == "cos" else ("z^m − z^(−m) = 2i sin m%s" % L if odd_sin else "z^m + z^(−m) = 2cos m%s and z^m − z^(−m) = 2i sin m%s" % [L, L])
	var base := "z + 1/z = 2cos %s" % L if fn == "cos" else "z − 1/z = 2i sin %s" % L
	var steps: Array = ["Let z = %s. By De Moivre's theorem %s for each whole m, so %s." % [cis_of(L), pair, base],
		"(%s)%s = (z %s 1/z)%s = %s = %s." % [base.substr(base.find("= ") + 2), Fmt.sup(n), sg, Fmt.sup(n), signed_join(terms), signed_join(groups)],
		"So %s = %s." % [lhs2, signed_join(rhs)], "So %s." % right]
	return _pack([], asked, ans, wr, fill, {"z-plus-reciprocal": steps}, rng)


static func cis_of(L: String) -> String:
	return "cos %s + i sin %s" % [L, L]


# ── The proof by induction ───────────────────────────────────

## The proof's six lines: "compound" multiplies out and uses the compound-angle formulae,
## "polar" multiplies the moduli and adds the arguments.
static func proof_lines(L: String, kind: String) -> Array:
	var c := cis_of(L)
	var step := "= cos(k + 1)%s + i sin(k + 1)%s, %sso the statement is true for n = k + 1." % [L, L, "by the compound-angle formulae, " if kind == "compound" else ""]
	return ["When n = 1, both sides are %s, so the statement is true for n = 1." % c,
		"Assume (%s)^k = cos k%s + i sin k%s for some positive integer k." % [c, L, L],
		"Then (%s)^(k + 1) = (cos k%s + i sin k%s)(%s)" % [c, L, L, c],
		expansion(L, kind, "−", "+") if kind == "compound" else "= cos(k%s + %s) + i sin(k%s + %s), multiplying the moduli and adding the arguments" % [L, L, L, L],
		step,
		"It is true for n = 1, and if it is true for n = k it is true for n = k + 1, so by induction it is true for every positive integer n."]


static func expansion(L: String, _kind: String, s1: String, s2: String) -> String:
	return "= (cos k%s cos %s %s sin k%s sin %s) + i(sin k%s cos %s %s cos k%s sin %s)" % [L, L, s1, L, L, L, L, s2, L, L]


const GAP_LINE := {"assumption": 1, "expansion": 3, "step": 4, "conclusion": 5}


## The proof shown: the asked method's, or either for no method.
func proof_kind(rng: Seeded) -> String:
	if angle == "induction-compound-angle":
		return "compound"
	if angle == "induction-polar-product":
		return "polar"
	return rng.pick(["compound", "polar"])


static func proof_shown(L: String, lines: Array) -> Array:
	var out: Array = ["Prove by induction that (%s)^n = cos n%s + i sin n%s for every positive integer n." % [cis_of(L), L, L]]
	for i in lines.size():
		out.append("Line %d: %s" % [i + 1, lines[i]])
	return out


static func method_id(kind: String) -> String:
	return "induction-compound-angle" if kind == "compound" else "induction-polar-product"


func u_induction_gap(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: String = s.letter
	var mode: String = s.mode
	var kind := proof_kind(rng)
	var lines := proof_lines(L, kind)
	var gap: int = GAP_LINE[mode]
	var right: String = lines[gap]
	var ans := claim_ans(right)
	var c := cis_of(L)
	var wr: Array = []
	var fill: Array = []
	var why: Array
	match mode:
		"assumption":
			wr.append(slip("assume-next", claim("Assume (%s)^(k + 1) = cos(k + 1)%s + i sin(k + 1)%s for some positive integer k." % [c, L, L])))
			fill = [claim("Assume (%s)^n = cos n%s + i sin n%s for every positive integer n." % [c, L, L]),
				claim("Assume (%s)^k = k(%s) for some positive integer k." % [c, c]),
				claim("Assume (%s)^k = cos k%s − i sin k%s for some positive integer k." % [c, L, L])]
			why = ["The inductive step assumes the statement for n = k, and Line 3 uses it to replace (%s)^k by cos k%s + i sin k%s." % [c, L, L],
				"Assuming it for n = k + 1 would assume what is to be proved."]
		"expansion":
			if kind == "compound":
				wr.append(slip("i2-expand", claim(expansion(L, kind, "+", "+"))))
				fill = [claim(expansion(L, kind, "−", "−")), claim("= cos k%s cos %s + i sin k%s sin %s" % [L, L, L, L]),
					claim("= (cos k%s + cos %s) + i(sin k%s + sin %s)" % [L, L, L, L])]
				why = ["Multiply out (cos k%s + i sin k%s)(%s): the last term is i² sin k%s sin %s = −sin k%s sin %s." % [L, L, c, L, L, L, L],
					"So the real part is cos k%s cos %s − sin k%s sin %s and the imaginary part is sin k%s cos %s + cos k%s sin %s." % [L, L, L, L, L, L, L, L]]
			else:
				fill = [claim("= cos(k%s − %s) + i sin(k%s − %s), multiplying the moduli and subtracting the arguments" % [L, L, L, L]),
					claim("= cos(k%s × %s) + i sin(k%s × %s), multiplying the moduli and multiplying the arguments" % [L, L, L, L]),
					claim("= 2(cos(k%s + %s) + i sin(k%s + %s)), adding the moduli and adding the arguments" % [L, L, L, L])]
				why = ["cos k%s + i sin k%s and %s both have modulus 1, with arguments k%s and %s." % [L, L, c, L, L],
					"A product multiplies the moduli, 1 × 1 = 1, and adds the arguments: k%s + %s." % [L, L]]
		"step":
			var tail := ", %sso the statement is true for n = k + 1." % ("by the compound-angle formulae, " if kind == "compound" else "")
			fill = [claim("= cos(k − 1)%s + i sin(k − 1)%s%s" % [L, L, tail]), claim("= cos(k + 1)%s − i sin(k + 1)%s%s" % [L, L, tail]),
				claim("= (k + 1)(%s)%s" % [c, tail])]
			if kind == "compound":
				why = ["cos A cos B − sin A sin B = cos(A + B) and sin A cos B + cos A sin B = sin(A + B), with A = k%s and B = %s." % [L, L],
					"k%s + %s = (k + 1)%s, which gives the statement for n = k + 1." % [L, L, L]]
			else:
				why = ["Line 4 gives the argument k%s + %s, and k%s + %s = (k + 1)%s." % [L, L, L, L, L], "That is the statement for n = k + 1."]
		_:
			wr.append(slip("no-base", claim("If it is true for n = k it is true for n = k + 1, so by induction it is true for every positive integer n.")))
			fill = [claim("So the statement is true for n = k + 1 only."), claim("It is true for n = 1, so it is true for every positive integer n."),
				claim("It is true for n = 1 and for n = k + 1, so it is true for every real number n.")]
			why = ["Line 1 is the base case, and Lines 2 to 5 show that the statement for n = k gives it for n = k + 1.",
				"The conclusion joins the two: true for n = 1, and true for n = k + 1 whenever it is true for n = k."]
	var shown := lines.duplicate()
	shown[gap] = "(missing)"
	var steps: Array = why + ["So Line %d is: %s" % [gap + 1, right]]
	return _pack(proof_shown(L, shown), "One line of this proof is missing. Which line completes the proof?", ans, wr, fill, {method_id(kind): steps}, rng)


func u_induction_flaw(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: String = s.letter
	var mode: String = s.mode
	var kind := proof_kind(rng)
	var lines := proof_lines(L, kind)
	var bad: int = GAP_LINE[mode]
	var c := cis_of(L)
	var why: String
	match mode:
		"assumption":
			lines[bad] = "Assume (%s)^(k + 1) = cos(k + 1)%s + i sin(k + 1)%s for some positive integer k." % [c, L, L]
			why = "Line 2 assumes the statement for n = k + 1, which is what has to be proved; it should assume it for n = k."
		"expansion":
			if kind == "compound":
				lines[bad] = expansion(L, kind, "+", "+")
				why = "Multiplying out, i sin k%s × i sin %s = i² sin k%s sin %s = −sin k%s sin %s, so the real part is cos k%s cos %s − sin k%s sin %s; Line 4 has a plus sign there." % [L, L, L, L, L, L, L, L, L, L]
			else:
				lines[bad] = "= cos(k%s − %s) + i sin(k%s − %s), multiplying the moduli and subtracting the arguments" % [L, L, L, L]
				why = "A product of two complex numbers adds their arguments, so the product has argument k%s + %s; Line 4 subtracts them." % [L, L]
		_:
			if kind == "compound":
				lines[bad] = "= cos(k + 1)%s + i sin(k − 1)%s, by the compound-angle formulae, so the statement is true for n = k + 1." % [L, L]
				why = "sin k%s cos %s + cos k%s sin %s = sin(k%s + %s) = sin(k + 1)%s, so Line 5's sin(k − 1)%s is wrong." % [L, L, L, L, L, L, L, L]
			else:
				lines[bad] = "= cos k%s + cos %s + i(sin k%s + sin %s), so the statement is true for n = k + 1." % [L, L, L, L]
				why = "cos(k%s + %s) is cos(k + 1)%s; cosine and sine don't split over a sum, so Line 5 is wrong." % [L, L, L]
	var right := "Line %d" % (bad + 1)
	var ans := claim_ans(right)
	var fill: Array = []
	for i in rng.shuffled(range(1, 7)):
		if i != bad + 1:
			fill.append(claim("Line %d" % i))
	var before := "Line 1 checks n = 1, which is right." if bad == 1 else "Lines 1 to %d are right: the base case, the assumption for n = k%s." % [bad, ", and the product" if bad == 3 else ", the product and its expansion"]
	var steps: Array = [before, why, "So the first incorrect line is %s." % right]
	return _pack(proof_shown(L, lines), "One line of this proof is wrong. Which is the first incorrect line?", ans, [], fill, {method_id(kind): steps}, rng)
