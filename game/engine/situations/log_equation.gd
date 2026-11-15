class_name LogEquationSituation
extends RefCounted
## The `log-equation` situation (curriculum/question-types.json): a log equation in x to combine,
## change to one base, drop the logs from and solve, rejecting any root that makes an argument zero
## or negative, for t1-log-equation (FAL-956). The answer is drawn first, so every root is exact.
##
## need.ask is the unknown (see LogEquationViews). generate() returns a Dictionary:
##   paper, ask, shape   always Paper 1; shape is the draw's form, named in each function
##   b, L     the log's base (0 for e, 10 for log) and how it is written: ln, log, log₂
##   rhs      "const" for a number on the right, c, or "log" for the log of a number, K
##   c, B     the constant and what the logs' arguments come to: B = b^c, or K
##   top, under, one, two   the arguments, each [a, p] for ax + p
##   x        the solution, Q; bad and roots where a root is rejected
##
## Every equation's arguments are linear in x. A quadratic has whole or half roots, and exactly one
## of them is rejected. The numbers are drawn, not taken from any one exam question.

const TRIES := 4000
const LOG_E := 0
const ROOT_MOST := 12
const X_MOST := 20


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var ask: String = need.get("ask", "combine-linear")
	for i in TRIES:
		var s := {"paper": 1, "ask": ask, "shape": "", "b": 10, "L": "log", "rhs": "const", "c": 0, "B": Q.new(1), "x": Q.new(0)}
		if _draw(rng, s):
			return s
	return {}


static func _draw(rng: Seeded, s: Dictionary) -> bool:
	match s.ask:
		"combine-linear":
			return _linear(rng, s, true)
		"constant-as-log":
			return _linear(rng, s, false)
		"combine-quadratic", "reject-root":
			return _quadratic(rng, s)
		"change-of-base":
			return _change_base(rng, s)
	return false


# ── Small tools ──────────────────────────────────────────────

static func ipow(b: int, e: int) -> int:
	var r := 1
	for i in e:
		r *= b
	return r


## log written for a base: ln for 0, log for 10, log₂ otherwise.
static func log_of(b: int) -> String:
	if b == LOG_E:
		return "ln"
	return "log" if b == 10 else Answer.log_name(b)


static func set_base(s: Dictionary, b: int) -> void:
	s.b = b
	s.L = log_of(b)


## The value of the argument ax + p at x.
static func at(arg: Array, x: Q) -> Q:
	return Q.new(arg[0]).mul(x).add(arg[1])


## Whether every argument is positive at x.
static func valid(args: Array, x: Q) -> bool:
	return args.all(func(a): return at(a, x).sign() > 0)


static func isqrt(n: int) -> int:
	if n < 0:
		return -1
	var r := int(sqrt(float(n)))
	while r * r > n:
		r -= 1
	while (r + 1) * (r + 1) <= n:
		r += 1
	return r


## The rational roots of A x² + B x + C, smallest first; [] when they aren't rational and distinct.
static func roots(A: int, B: int, C: int) -> Array:
	var disc := B * B - 4 * A * C
	var r := isqrt(disc)
	if A == 0 or disc <= 0 or r * r != disc:
		return []
	var out := [Q.new(-B - r, 2 * A), Q.new(-B + r, 2 * A)]
	if out[1].lt(out[0]):
		out.reverse()
	return out


## A number on the right: b^c for a whole c with b^c from lo to hi, or the log of a number K.
static func _right(rng: Seeded, s: Dictionary, lo: int, hi: int, log_chance: float) -> bool:
	s.rhs = "log" if s.b == LOG_E or rng.chance(log_chance) else "const"
	if s.rhs == "log":
		s.c = 0
		s.B = Q.new(rng.int_in(lo, hi))
		return true
	s.c = rng.int_in(1, 3)
	var big := ipow(s.b, s.c)
	s.B = Q.new(big)
	return big >= lo and big <= hi


# ── The draws ────────────────────────────────────────────────

## log_b(mx + n) − log_b(x + r) = c, or = log_b K. constant-as-log writes it
## log_b(mx + n) = c + log_b(x + r), always with a number c. Either way mx + n = B(x + r).
static func _linear(rng: Seeded, s: Dictionary, any_right: bool) -> bool:
	set_base(s, rng.pick([2, 3, 5, 10, LOG_E] if any_right else [2, 3, 5, 10]))
	s.shape = "quotient" if any_right else "constant"
	if not _right(rng, s, 3, 125, 0.3 if any_right else 0.0):
		return false
	var m := rng.int_in(1, 6)
	var r := rng.int_in(-6, 6)
	var n := rng.int_in(-20, 30)
	var B: Q = s.B
	# (mx + n)/(x + r) is the constant m when n = mr, and never B = m.
	if n == m * r or B.eq(m):
		return false
	var x := Q.new(n).sub(B.mul(r)).div(B.sub(m))
	if x.d > 4 or x.is_zero() or x.abs_q().to_float() > X_MOST:
		return false
	s.top = [m, n]
	s.under = [1, r]
	if not valid([s.top, s.under], x):
		return false
	s.x = x
	return true


## Two logs that combine into a quadratic with one root rejected.
##   sum    log_b(ax + p) + log_b(x + q) = c or log_b K: (ax + p)(x + q) = B
##   power  2 log_b(x + p) − log_b(x + q) = c or log_b K: (x + p)² = B(x + q)
## With both arguments rising in x, the rejected root is always the smaller one.
static func _quadratic(rng: Seeded, s: Dictionary) -> bool:
	set_base(s, rng.pick([2, 3, 5, 10, LOG_E]))
	s.shape = "power" if rng.chance(0.35) else "sum"
	if not _right(rng, s, 2, 60, 0.25):
		return false
	var B: int = s.B.n
	var p := rng.int_in(-8, 8)
	var q := rng.int_in(-8, 10)
	var rs: Array
	if s.shape == "sum":
		var a: int = rng.pick([1, 1, 1, 2])
		if a == 1 and p == q:
			return false
		s.one = [a, p]
		s.two = [1, q]
		rs = roots(a, a * q + p, p * q - B)
	else:
		if p == q:
			return false
		s.one = [1, p]
		s.two = [1, q]
		rs = roots(1, 2 * p - B, p * p - B * q)
	return _one_root(s, rs, [s.one, s.two])


## Keeps a draw whose two roots are small, with exactly one making every argument positive.
static func _one_root(s: Dictionary, rs: Array, args: Array) -> bool:
	if rs.size() != 2 or rs.any(func(r): return r.abs_q().to_float() > ROOT_MOST or r.d > 2):
		return false
	var good: Array = rs.filter(func(r): return valid(args, r))
	if good.size() != 1:
		return false
	s.roots = rs
	s.x = good[0]
	s.bad = rs[0] if rs[1].eq(good[0]) else rs[1]
	return true


## Two bases, b and b^k.
##   equal  log_b(x + p) = log_(b²)(mx + n): (x + p)² = mx + n, one root rejected
##   same   log_b(mx + n) + log_(b^k)(mx + n) = c, with c = (k + 1)j: mx + n = b^(kj)
static func _change_base(rng: Seeded, s: Dictionary) -> bool:
	var b: int = rng.pick([2, 3, 5])
	set_base(s, b)
	s.shape = "equal" if rng.chance(0.55) else "same"
	if s.shape == "equal":
		s.k = 2
		s.big = b * b
		var p := rng.int_in(-6, 6)
		var m := rng.int_in(1, 8)
		var n := rng.int_in(-10, 20)
		s.one = [1, p]
		s.two = [m, n]
		s.flip = rng.chance(0.4)
		if m == 1 and n == p:
			return false
		return _one_root(s, roots(1, 2 * p - m, p * p - n), [s.one, s.two])
	s.k = rng.pick([2, 3])
	s.big = ipow(b, s.k)
	s.j = rng.int_in(1, 2)
	s.c = (s.k + 1) * s.j
	var A := ipow(b, s.k * s.j)
	if A > 125:
		return false
	var m := rng.int_in(1, 6)
	var n := rng.int_in(-12, 12)
	var x := Q.new(A - n, m)
	if x.d > 4 or x.is_zero() or x.abs_q().to_float() > X_MOST:
		return false
	s.top = [m, n]
	s.B = Q.new(A)
	s.x = x
	return true


## Plain data for the export and the checker.
static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
