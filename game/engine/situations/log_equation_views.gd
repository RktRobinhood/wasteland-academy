class_name LogEquationViews
extends ExtensionViews
## The views on the `log-equation` situation: one builder per unknown of t1-log-equation (FAL-956).
## Every answer is x, exact, in one slot ("x = 7/2"), but for the rejected root, which is the value
## that must go. "Both roots" and "no solution" are options in another shape: they can be picked,
## never typed.
##
## The one representation is "equation", as the exam gives it. Paper 1 only, as the bank is: every
## root is whole or a half, so nothing needs a calculator.
##
## Every working ends by checking the root in each log's argument, or starts from the domain. A
## slip's x is offered only when it is a small number, and the checker works it out again.
##
## Misconceptions are the two map strings with no numbers in them, then the type's own,
## "<type id>#<index>". Every wrong option is a slip with its line, or a declared filler.

const OWN := "t1-log-equation#"
const R_KEEP := "SL1.7.log-equations#0"
const R_ADD := "SL1.7.log-equations#1"
const R_SWAP := OWN + "2"
const R_SUBTRACT := OWN + "3"
const R_FLIP := OWN + "4"
const R_ADD_C := OWN + "5"
const R_TIMES_C := OWN + "6"
const R_TWO_IN := OWN + "7"
const R_WRONG_WAY := OWN + "8"
const R_SAME_BASE := OWN + "9"
const R_NEGATIVE := OWN + "10"

const EXPONENTIATE := "combine-then-exponentiate"
const MATCH := "match-arguments"
const DOMAIN := "domain-first"
const CHECK := "check-each-root"
const FORMULA := "cob-formula"
const POWERS := "common-base-power"
const UNKNOWNS := ["combine-linear", "constant-as-log", "combine-quadratic", "change-of-base", "reject-root"]
## A slip's x is offered when it is at most this big, with a denominator at most DEN_MOST.
const SLIP_MOST := 60
const DEN_MOST := 12


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func papers(unknown: String, _rep: String, _angle_id: String) -> Array:
	return [1] if has(unknown) else []


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = LogEquationSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

## ax + p: "3x + 4", "x − 2", "x".
static func lin(arg: Array) -> String:
	var a: int = arg[0]
	var p: int = arg[1]
	var head := "x" if a == 1 else "%dx" % a
	if p == 0:
		return head
	return "%s %s %d" % [head, "+" if p > 0 else "−", absi(p)]


## An argument as a factor: "x" or "(x + 3)".
static func br(arg: Array) -> String:
	var t := lin(arg)
	return t if t == "x" else "(" + t + ")"


## The log of an argument: "log₂ x", "ln(x + 3)".
static func lg(L: String, arg: Array) -> String:
	var t := lin(arg)
	return L + " x" if t == "x" else "%s(%s)" % [L, t]


## The log of an expression that needs its own brackets: "log₂((x + 3)(x − 1))".
static func lgx(L: String, inside: String) -> String:
	return "%s(%s)" % [L, inside]


static func lgn(L: String, n: Variant) -> String:
	return "%s %s" % [L, N(n)]


## b^e: "2³", or b itself.
static func pw(b: int, e: int) -> String:
	return str(b) + Fmt.sup(e)


static func quot(top: Array, under: Array) -> String:
	return "%s/%s" % [br(top), br(under)]


## (ax + p)(x + q), with a bare x first: "x(x + 2)".
static func prod(one: Array, two: Array) -> String:
	if lin(two) == "x":
		return br(two) + br(one)
	return br(one) + br(two)


static func sq(arg: Array) -> String:
	return br(arg) + "²"


## B times an argument: "8(x − 2)", "8x".
static func times(B: Q, arg: Array) -> String:
	return N(B) + br(arg)


## A x² + B x + C, with zero terms left out.
static func poly(A: int, B: int, C: int) -> String:
	var out := ("x²" if A == 1 else "%dx²" % A)
	if B != 0:
		out += " %s %s" % ["+" if B > 0 else "−", "x" if absi(B) == 1 else "%dx" % absi(B)]
	if C != 0:
		out += " %s %d" % ["+" if C > 0 else "−", absi(C)]
	return out


## x − r as a factor, from a root: "(x − 3)", "(x + 7)", "x", "(2x − 5)" for 5/2.
static func factor(r: Q) -> String:
	if r.is_zero():
		return "x"
	var head := "x" if r.d == 1 else "%dx" % r.d
	return "(%s %s %d)" % [head, "−" if r.sign() > 0 else "+", absi(r.n)]


## A x² + … = 0 written as its factors, from the roots; A is 1 or 2.
static func factors(A: int, rs: Array) -> String:
	if A == 1 or rs.any(func(r): return r.d == 2):
		var fs: Array = rs.duplicate()
		fs.sort_custom(func(u, v): return u.is_zero() and not v.is_zero())
		return "".join(fs.map(func(r): return factor(r)))
	return "%d%s%s" % [A, factor(rs[0]), factor(rs[1])]


static func xv(v: Q) -> String:
	return "x = " + N(v)


## "x = −7 or x = 5", smallest first.
static func either(rs: Array) -> String:
	return "%s or %s" % [xv(rs[0]), xv(rs[1])]


## "x − 2 = 2 and 3x + 4 = 16"; a bare x is named, as its value is already said.
static func values_at(args: Array, x: Q) -> String:
	return " and ".join(args.map(func(a): return "x" if lin(a) == "x" else "%s = %s" % [lin(a), N(LogEquationSituation.at(a, x))]))


## "At x = 4, x − 2 = 2 and 3x + 4 = 16 are both positive, so x = 4."
static func check_line(args: Array, x: Q) -> String:
	return "At %s, %s are both positive, so %s." % [xv(x), values_at(args, x), xv(x)]


## The arguments a root makes zero or negative: "makes x + 3 and x − 1 negative".
static func spoils(args: Array, x: Q) -> String:
	var neg: Array = args.filter(func(a): return LogEquationSituation.at(a, x).sign() < 0).map(func(a): return lin(a))
	var zero: Array = args.filter(func(a): return LogEquationSituation.at(a, x).is_zero()).map(func(a): return lin(a))
	var bits: Array = []
	if not neg.is_empty():
		bits.append(" and ".join(neg) + " negative")
	if not zero.is_empty():
		bits.append(" and ".join(zero) + " zero")
	return "makes " + " and ".join(bits)


## "x + 2 and x are negative", "x − 7 is negative": the arguments a root spoils, as a clause.
static func spoiled(args: Array, x: Q) -> String:
	var bits: Array = []
	for want in [-1, 0]:
		var these: Array = args.filter(func(a): return LogEquationSituation.at(a, x).sign() == want).map(func(a): return lin(a))
		if not these.is_empty():
			bits.append("%s %s %s" % [" and ".join(these), "is" if these.size() == 1 else "are", "negative" if want < 0 else "zero"])
	return " and ".join(bits)


## The least x the logs allow: the largest of −p/a.
static func bound(args: Array) -> Q:
	var out: Q = null
	for a in args:
		var edge := Q.new(-a[1], a[0])
		if out == null or out.lt(edge):
			out = edge
	return out


static func domain_line(args: Array) -> String:
	return "The logs need %s, so x > %s." % [" and ".join(args.map(func(a): return lin(a) + " > 0")), N(bound(args))]


## "2³ = 8", or "3" for 3¹.
static func power_value(b: int, c: int) -> String:
	return str(b) if c == 1 else "%s = %d" % [pw(b, c), LogEquationSituation.ipow(b, c)]


## "Write 3 as a log: 3 = log₂ 2³ = log₂ 8."
static func constant_line(s: Dictionary) -> String:
	if s.c == 1:
		return "Write 1 as a log: 1 = %s." % lgn(s.L, s.b)
	return "Write %d as a log: %d = %s %s = %s." % [s.c, s.c, s.L, pw(s.b, s.c), lgn(s.L, s.B)]


## What the base is raised to: "In exponential form, (3x + 4)/(x − 2) = 2³ = 8."
static func exponential_line(s: Dictionary, lhs: String) -> String:
	if s.rhs == "const":
		return "In exponential form, %s = %s." % [lhs, power_value(s.b, s.c)]
	var base := "e" if s.b == LogEquationSituation.LOG_E else str(s.b)
	return "Raise %s to the power of each side: %s = %s." % [base, lhs, N(s.B)]


## The right side as the exam writes it: "3" or "ln 12".
static func right_text(s: Dictionary) -> String:
	return str(s.c) if s.rhs == "const" else lgn(s.L, s.B)


# ── Answers ──────────────────────────────────────────────────

static func x_ans(v: Q) -> Dictionary:
	var ans := Answer.make("form", {"v": v, "text": xv(v)}, {"parts": ["x = ", {"slot": "v"}]})
	ans.exact = true
	return ans


## A slip's x, kept only when it is a small number.
static func wx(v: Variant, ref: String, w: Array) -> void:
	if v == null:
		return
	var q: Q = v
	if q.d <= DEN_MOST and q.abs_q().to_float() <= SLIP_MOST:
		w.append(wrong({"v": q, "text": xv(q)}, ref))


## Another shape: it can be picked and never typed.
static func walt(text: String, ref: String = "") -> Dictionary:
	return wrong({"text": text, "shape": "other"}, ref)


## (top − bottom × B)/(B × … ), as x for the line ux + v = 0; null when there is no x.
static func solve_lin(u: Q, v: Q) -> Variant:
	return null if u.is_zero() else v.neg().div(u)


static func near(v: Q) -> Array:
	return [v.add(1), v.sub(1), v.add(2), v.neg(), v.mul(2), v.add(3)].filter(func(x): return not x.eq(v)).map(func(x): return {"v": x, "text": xv(x)})


func _answer(lines: Array, asked: String, ans: Dictionary, w: Array, gen: Array, rng: Seeded, methods: Dictionary) -> Dictionary:
	return {"lines": lines, "asked": asked, "answer": ans, "wrongs": rng.shuffled(w), "fillers": gen, "methods": methods}


# ── One root ─────────────────────────────────────────────────

## mx + n = B(x + r), solved: "3x + 4 = 8(x − 2), so 5x = 20 and x = 4."
static func solve_line(s: Dictionary, lead: String = "") -> String:
	var m: int = s.top[0]
	var n: int = s.top[1]
	var r: int = s.under[1]
	var B: Q = s.B
	var k := B.sub(m)
	var v := Q.new(n).sub(B.mul(r))
	if k.sign() < 0:
		k = k.neg()
		v = v.neg()
	var kx := "x" if k.eq(1) else N(k) + "x"
	var tail := "so %s = %s and %s" % [kx, N(v), xv(s.x)] if not k.eq(1) else "so %s" % xv(s.x)
	return "%s%s = %s, %s." % [lead, lin(s.top), times(B, s.under), tail]


func u_combine_linear(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: String = s.L
	var lhs := "%s − %s" % [lg(L, s.top), lg(L, s.under)]
	var q := quot(s.top, s.under)
	var ans := x_ans(s.x)
	var args: Array = [s.under, s.top]
	var joined := "By the quotient law, %s = %s." % [lhs, lgx(L, q)]
	var m_exp := [joined, exponential_line(s, q), solve_line(s), check_line(args, s.x)]
	var m_match: Array
	if s.rhs == "const":
		m_match = [constant_line(s), "The quotient law gives %s = %s, so the arguments are equal: %s = %s." % [lgx(L, q), lgn(L, s.B), q, N(s.B)],
			solve_line(s), check_line(args, s.x)]
	else:
		m_match = [joined, "The logs are equal, so their arguments are: %s = %s." % [q, N(s.B)], solve_line(s), check_line(args, s.x)]
	var w := _linear_slips(s)
	var m: int = s.top[0]
	var n: int = s.top[1]
	var r: int = s.under[1]
	var B: Q = s.B
	# (mx + n) − (x + r) = B, and x + r = B(mx + n).
	wx(solve_lin(Q.new(m - 1), Q.new(n - r).sub(B)), R_SUBTRACT, w)
	return _answer(["%s = %s" % [lhs, right_text(s)]], "Solve the equation for x.", ans, w, near(s.x), rng,
		{EXPONENTIATE: method(m_exp, ans.values), MATCH: method(m_match, ans.values)})


## The slips both linear forms share: the quotient upside down, and b and c swapped.
static func _linear_slips(s: Dictionary) -> Array:
	var w: Array = []
	var m: int = s.top[0]
	var n: int = s.top[1]
	var r: int = s.under[1]
	var B: Q = s.B
	wx(solve_lin(Q.new(1).sub(B.mul(m)), Q.new(r).sub(B.mul(n))), R_FLIP, w)
	if s.rhs == "const":
		var swapped := Q.new(LogEquationSituation.ipow(s.c, s.b))
		if not swapped.eq(B):
			wx(solve_lin(Q.new(m).sub(swapped), Q.new(n).sub(swapped.mul(r))), R_SWAP, w)
	return w


func u_constant_as_log(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: String = s.L
	var q := quot(s.top, s.under)
	var ans := x_ans(s.x)
	var args: Array = [s.under, s.top]
	var line := "%s = %d + %s" % [lg(L, s.top), s.c, lg(L, s.under)]
	var m_match := [constant_line(s), "So the right side is %s + %s = %s." % [lgn(L, s.B), lg(L, s.under), lgx(L, times(s.B, s.under))],
		solve_line(s, "The arguments are equal: "), check_line(args, s.x)]
	var m_exp := ["Take %s from each side: %s = %d." % [lg(L, s.under), lgx(L, q), s.c], exponential_line(s, q), solve_line(s), check_line(args, s.x)]
	var w := _linear_slips(s)
	var m: int = s.top[0]
	var n: int = s.top[1]
	var r: int = s.under[1]
	var c: int = s.c
	# mx + n = x + r + c, and mx + n = c(x + r).
	wx(solve_lin(Q.new(m - 1), Q.new(n - r - c)), R_ADD_C, w)
	wx(solve_lin(Q.new(m - c), Q.new(n - c * r)), R_TIMES_C, w)
	return _answer([line], "Solve the equation for x.", ans, w, near(s.x), rng,
		{MATCH: method(m_match, ans.values), EXPONENTIATE: method(m_exp, ans.values)})


# ── A quadratic, one root rejected ───────────────────────────

## The equation, what the logs combine to, and the quadratic's coefficients.
static func _quad_parts(s: Dictionary) -> Dictionary:
	var L: String = s.L
	var B: int = s.B.n
	var a: int = s.one[0]
	var p: int = s.one[1]
	var q: int = s.two[1]
	if s.shape == "sum":
		var pr := prod(s.one, s.two)
		return {"lhs": "%s + %s" % [lg(L, s.one), lg(L, s.two)], "law": "By the product law", "joined": pr, "dropped": pr + " = " + N(B),
			"poly": poly(a, a * q + p, p * q - B), "A": a}
	var fr := "%s/%s" % [sq(s.one), br(s.two)]
	return {"lhs": "2 %s − %s" % [lg(L, s.one), lg(L, s.two)], "law": "By the power and quotient laws", "joined": fr,
		"dropped": "%s = %s" % [sq(s.one), times(s.B, s.two)], "poly": poly(1, 2 * p - B, p * p - B * q), "A": 1}


static func roots_line(lead: String, poly_text: String, A: int, rs: Array) -> String:
	return "%s%s = 0, which is %s = 0: %s." % [lead, poly_text, factors(A, rs), either(rs)]


static func reject_line(s: Dictionary, args: Array) -> String:
	var why := ""
	if s.shape in ["power", "equal"]:
		why = ", though %s is positive there" % sq(s.one)
	return "%s %s, so reject it%s. %s" % [xv(s.bad), spoils(args, s.bad), why, check_line(args, s.x)]


func u_combine_quadratic(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: String = s.L
	var P := _quad_parts(s)
	var args: Array = [s.one, s.two]
	var ans := x_ans(s.x)
	var solved := roots_line("So ", P.poly, P.A, s.roots)
	var joined := "%s, %s = %s." % [P.law, P.lhs, lgx(L, P.joined)]
	var to_poly: String = "" if s.shape == "sum" else ", so " + P.dropped
	var m_exp := [joined, exponential_line(s, P.joined).trim_suffix(".") + to_poly + ".", solved, reject_line(s, args)]
	var second := "The logs are equal, so their arguments are: %s." % P.dropped
	if s.rhs == "const":
		second = "%s gives %s = %s, so %s." % [P.law.trim_prefix("By "), lgx(L, P.joined), lgn(L, s.B), P.dropped]
		second = second[0].to_upper() + second.substr(1)
	var m_match := [constant_line(s) if s.rhs == "const" else joined, second, solved, reject_line(s, args)]
	var m_domain := [domain_line(args), "Combine the logs and drop them: %s." % P.dropped, solved,
		"Only %s is in x > %s, so %s." % [xv(s.x), N(bound(args)), xv(s.x)]]
	var w: Array = []
	wx(s.bad, R_KEEP, w)
	w.append(walt(either(s.roots), R_KEEP))
	var B: Q = s.B
	var a: int = s.one[0]
	var p: int = s.one[1]
	var q: int = s.two[1]
	if s.shape == "sum":
		# (ax + p) + (x + q) = B.
		wx(solve_lin(Q.new(a + 1), Q.new(p + q).sub(B)), R_ADD, w)
	else:
		# 2(x + p) = B(x + q).
		wx(solve_lin(B.sub(2), B.mul(q).sub(2 * p)), R_TWO_IN, w)
	if s.x.sign() < 0:
		w.append(walt("No solution: both roots are negative", R_NEGATIVE))
	return _answer(["%s = %s" % [P.lhs, right_text(s)]], "Solve the equation for x.", ans, w, near(s.x), rng,
		{EXPONENTIATE: method(m_exp, ans.values), MATCH: method(m_match, ans.values), DOMAIN: method(m_domain, ans.values)})


func u_reject_root(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var P := _quad_parts(s)
	var args: Array = [s.one, s.two]
	var ans := x_ans(s.bad)
	var lines := ["%s = %s" % [P.lhs, right_text(s)], "Combining the logs and solving gives %s." % either(s.roots)]
	var m_check := ["At %s, %s are both positive, so it stands." % [xv(s.x), values_at(args, s.x)],
		"At %s, %s: the log of zero or a negative number isn't defined." % [xv(s.bad), spoiled(args, s.bad)],
		"So %s must be rejected." % xv(s.bad)]
	var m_domain := [domain_line(args), "%s is in x > %s, and %s isn't." % [xv(s.x), N(bound(args)), xv(s.bad)],
		"So %s must be rejected." % xv(s.bad)]
	var w: Array = [walt("Neither: both values solve the equation", R_KEEP)]
	if s.x.sign() < 0:
		w.append(walt("Both, as both values are negative", R_NEGATIVE))
	var gen: Array = [{"v": s.x, "text": xv(s.x)}]
	gen.append_array(near(s.bad))
	return _answer(lines, "Find the value of x that must be rejected.", ans, w, gen, rng,
		{CHECK: method(m_check, ans.values), DOMAIN: method(m_domain, ans.values)})


# ── Two bases ────────────────────────────────────────────────

func u_change_of_base(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	if s.shape == "equal":
		return _equal_bases(s, rng)
	var L: String = s.L
	var L2 := LogEquationSituation.log_of(s.big)
	var k: int = s.k
	var T: Array = s.top
	var ans := x_ans(s.x)
	var line := "%s + %s = %d" % [lg(L, T), lg(L2, T), s.c]
	var part := "%s %s" % [LogLawsViews.co(Q.new(1, k)), lg(L, T)]
	var change := "Change base: %s = %s/%s = %s." % [lg(L2, T), lg(L, T), lgn(L, s.big), part]
	var powers := "%d = %s, and %d^t = %d^(%dt), so %s = %s." % [s.big, pw(s.b, k), s.big, s.b, k, lg(L2, T), part]
	var kj: int = k * s.j
	var total := "So %s %s = %d, and %s = %d." % [LogLawsViews.co(Q.new(k + 1, k)), lg(L, T), s.c, lg(L, T), kj]
	var last := "In exponential form, %s = %s, so %s." % [lin(T), power_value(s.b, kj), xv(s.x)]
	var w: Array = []
	var m: int = T[0]
	var n: int = T[1]
	# The argument comes to b^j (log_(b^k) A = k log_b A), b^(c/2) (one base), or (kj)^b.
	wx(Q.new(LogEquationSituation.ipow(s.b, s.j) - n, m), R_WRONG_WAY, w)
	if s.c % 2 == 0 and LogEquationSituation.ipow(s.b, s.c / 2) <= 5000:
		wx(Q.new(LogEquationSituation.ipow(s.b, s.c / 2) - n, m), R_SAME_BASE, w)
	if kj != s.b and LogEquationSituation.ipow(kj, s.b) <= 5000:
		wx(Q.new(LogEquationSituation.ipow(kj, s.b) - n, m), R_SWAP, w)
	return _answer([line], "Solve the equation for x.", ans, w, near(s.x), rng,
		{FORMULA: method([change, total, last], ans.values), POWERS: method([powers, total, last], ans.values)})


func _equal_bases(s: Dictionary, rng: Seeded) -> Dictionary:
	var L: String = s.L
	var L2 := LogEquationSituation.log_of(s.big)
	var one: Array = s.one
	var two: Array = s.two
	var args: Array = [one, two]
	var ans := x_ans(s.x)
	var sides := [lg(L, one), lg(L2, two)]
	if s.flip:
		sides.reverse()
	var half := "(1/2) " + lg(L, two)
	var change := "Change base: %s = %s/%s = %s." % [lg(L2, two), lg(L, two), lgn(L, s.big), half]
	var powers := "%d = %s, and %d^t = %d^(2t), so %s = %s." % [s.big, pw(s.b, 2), s.big, s.b, lg(L2, two), half]
	var dropped := "So 2 %s = %s, and %s = %s." % [lg(L, one), lg(L, two), sq(one), lin(two)]
	var p: int = one[1]
	var m: int = two[0]
	var n: int = two[1]
	var solved := roots_line("Expand: ", poly(1, 2 * p - m, p * p - n), 1, s.roots)
	var w: Array = []
	wx(s.bad, R_KEEP, w)
	w.append(walt(either(s.roots), R_KEEP))
	# x + p = mx + n, as if one base.
	wx(solve_lin(Q.new(1 - m), Q.new(p - n)), R_SAME_BASE, w)
	# x + p = (mx + n)², from log_(b²) y = 2 log_b y: a root that keeps both arguments positive.
	var wrong_way: Array = LogEquationSituation.roots(m * m, 2 * m * n - 1, n * n - p).filter(
		func(r): return LogEquationSituation.valid(args, r))
	if not wrong_way.is_empty():
		wx(wrong_way[0], R_WRONG_WAY, w)
	return _answer(["%s = %s" % sides], "Solve the equation for x.", ans, w, near(s.x), rng,
		{FORMULA: method([change, dropped, solved, reject_line(s, args)], ans.values),
			POWERS: method([powers, dropped, solved, reject_line(s, args)], ans.values)})
