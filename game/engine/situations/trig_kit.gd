class_name TrigKit
extends RefCounted
## Exact trig values for the Topic 3 types of FAL-727. A value is [a, b, r], which is a + b√r, with
## a and b as Q and r square-free (r is 1 when b is 0). That covers every landmark value, every
## sum of two landmark values the types ask, and any ratio worked from a given ratio.
##
## An answer is a `form` answer: its slots follow the shape of the value, so a wrong option in
## another shape can be picked but not typed (see DifferentiationViews.form).

const FNS := ["sin", "cos", "tan"]


static func V(a: Variant, b: Variant = 0, r: int = 1) -> Array:
	var q := Q.of(b)
	if q.is_zero() or r == 1:
		return [Q.of(a).add(q if r == 1 else Q.new(0)), Q.new(0), 1]
	return [Q.of(a), q, r]


## √n as a value, for a whole n.
static func root(n: int) -> Array:
	var m := 1
	var f := 2
	var rest := n
	while f * f <= rest:
		while rest % (f * f) == 0:
			rest /= f * f
			m *= f
		f += 1
	return V(0, m, rest)


static func is_zero(v: Array) -> bool:
	return v[0].is_zero() and v[1].is_zero()


static func fl(v: Array) -> float:
	return v[0].to_float() + v[1].to_float() * sqrt(float(v[2]))


static func same(v: Array, w: Array) -> bool:
	return v[0].eq(w[0]) and v[1].eq(w[1]) and v[2] == w[2]


static func neg(v: Array) -> Array:
	return times(v, -1)


static func times(v: Array, k: Variant) -> Array:
	return V(v[0].mul(k), v[1].mul(k), v[2])


## The sum, or [] where it would have two different surds.
static func plus(v: Array, w: Array) -> Array:
	if v[1].is_zero():
		return V(v[0].add(w[0]), w[1], w[2])
	if w[1].is_zero() or v[2] == w[2]:
		return V(v[0].add(w[0]), v[1].add(w[1]), v[2])
	return []


## The product of two values of one term each (a rational or a surd).
static func mul(v: Array, w: Array) -> Array:
	var c: Q = v[0].add(v[1]).mul(w[0].add(w[1]))
	return times(root(v[2] * w[2]), c)


## The square of a value of one term.
static func sq(v: Array) -> Array:
	return mul(v, v)


## The quotient of two values of one term each.
static func over(v: Array, w: Array) -> Array:
	if w[1].is_zero():
		return times(v, Q.new(1).div(w[0]))
	return times(mul(v, root(w[2])), Q.new(1).div(w[1].mul(w[2])))


## The positive square root of a rational: √(p/q) = √(pq)/q.
static func sqrt_q(q: Q) -> Array:
	return times(root(q.n * q.d), Q.new(1, q.d))


# ── Landmarks ────────────────────────────────────────────────

## sin of 0, π/6, π/4, π/3, π/2.
static func _sin_first(t: Q) -> Array:
	match t.key():
		"0":
			return V(0)
		"1/6":
			return V(Q.new(1, 2))
		"1/4":
			return V(0, Q.new(1, 2), 2)
		"1/3":
			return V(0, Q.new(1, 2), 3)
		"1/2":
			return V(1)
	return []


## sin tπ, for a landmark t, on any turn.
static func sin_pi(t: Q) -> Array:
	var u: Q = turn(t)
	if u.lt(Q.new(1, 2)) or u.eq(Q.new(1, 2)):
		return _sin_first(u)
	if u.lt(Q.new(1)) or u.eq(Q.new(1)):
		return _sin_first(Q.new(1).sub(u))
	if u.lt(Q.new(3, 2)) or u.eq(Q.new(3, 2)):
		return neg(_sin_first(u.sub(1)))
	return neg(_sin_first(Q.new(2).sub(u)))


static func cos_pi(t: Q) -> Array:
	return sin_pi(t.add(Q.new(1, 2)))


## tan tπ, or [] where it has no value.
static func tan_pi(t: Q) -> Array:
	var u: Q = turn(t)
	if u.sub(Q.new(1, 2)).is_int():
		return []
	var r: Q = u if u.lt(Q.new(1)) else u.sub(1)
	var size: Array
	var ref: Q = r if r.lt(Q.new(1, 2)) else Q.new(1).sub(r)
	match ref.key():
		"0":
			size = V(0)
		"1/6":
			size = V(0, Q.new(1, 3), 3)
		"1/4":
			size = V(1)
		"1/3":
			size = V(0, 1, 3)
	return size if r.lt(Q.new(1, 2)) else neg(size)


static func of(fn: String, t: Q) -> Array:
	match fn:
		"sin":
			return sin_pi(t)
		"cos":
			return cos_pi(t)
	return tan_pi(t)


## t on the first turn: 0 ≤ t < 2.
static func turn(t: Q) -> Q:
	var turns := floori(t.div(2).to_float())
	var u: Q = t.sub(turns * 2)
	return u.sub(2) if not u.lt(Q.new(2)) else u


## The angle to the nearest x-axis, as a multiple of π.
static func ref_of(t: Q) -> Q:
	var u: Q = turn(t)
	var r: Q = u if u.lt(Q.new(1)) else u.sub(1)
	return r if r.lt(Q.new(1, 2)) or r.eq(Q.new(1, 2)) else Q.new(1).sub(r)


## The quadrant of a t that is not on an axis: 1 to 4.
static func quadrant(t: Q) -> int:
	return floori(turn(t).mul(2).to_float()) + 1


# ── Writing ──────────────────────────────────────────────────

## "√3/2", "−1/2", "3√2/2", "(1 + √3)/2", "1 + √2".
static func text(v: Array) -> String:
	if v[1].is_zero():
		return Fmt.num(v[0])
	var d: int = lcm(v[0].d, v[1].d)
	var a: int = v[0].mul(d).n
	var b: int = v[1].mul(d).n
	var body := _surd(b, v[2])
	if a == 0:
		return body + ("" if d == 1 else "/%d" % d)
	var two := "%s %s %s" % [Fmt.num(a), "+" if b > 0 else "−", _surd(absi(b), v[2])]
	return two if d == 1 else "(%s)/%d" % [two, d]


## "1/2 + √3/3", "1/2 − √3/3": two values added, for the working.
static func sum_text(v: Array, w: Array) -> String:
	return "%s %s %s" % [text(v), "−" if fl(w) < 0.0 else "+", text(times(w, -1) if fl(w) < 0.0 else w)]


static func _surd(b: int, r: int) -> String:
	return ("−" if b < 0 else "") + ("" if absi(b) == 1 else str(absi(b))) + "√%d" % r


static func lcm(a: int, b: int) -> int:
	var x := a
	var y := b
	while y != 0:
		var t := x % y
		x = y
		y = t
	return a * b / x


## "n", "s" or "m": a rational, one surd, or a rational and a surd.
static func shape(v: Array) -> String:
	if v[1].is_zero():
		return "n"
	return "s" if v[0].is_zero() else "m"


## The slots of a value, with `tag` on each id so two values can sit in one answer.
static func slots(v: Array, tag: String = "") -> Dictionary:
	if v[1].is_zero():
		return {"v" + tag: v[0]}
	var d: int = lcm(v[0].d, v[1].d)
	if v[0].is_zero():
		return {"m" + tag: v[1].mul(d), "r" + tag: Q.new(v[2]), "d" + tag: Q.new(d)}
	return {"a" + tag: v[0].mul(d), "m" + tag: v[1].mul(d), "r" + tag: Q.new(v[2]), "d" + tag: Q.new(d)}


static func parts(v: Array, tag: String = "") -> Array:
	match shape(v):
		"n":
			return [{"slot": "v" + tag}]
		"s":
			return [{"slot": "m" + tag}, "√", {"slot": "r" + tag}, "/", {"slot": "d" + tag}]
	return ["(", {"slot": "a" + tag}, " + ", {"slot": "m" + tag}, "√", {"slot": "r" + tag}, ")/", {"slot": "d" + tag}]


## A value as a `form` answer.
static func ans(label: String, v: Array, tail: String = "") -> Dictionary:
	var out := DifferentiationViews.form(label + text(v) + tail, [label] + parts(v) + [tail], slots(v))
	out.head = label
	out.tail = tail
	out.shape = shape(v)
	return out


## A wrong option in the answer's own terms, or none where the value is the answer.
static func like(a: Dictionary, v: Array, ref: String = "") -> Array:
	if v.is_empty():
		return []
	var t: String = a.head + text(v) + a.tail
	return [DifferentiationViews.alt(t, ref, slots(v) if shape(v) == a.shape else {})]


## Wrong options with no misconception behind them.
static func others(a: Dictionary, vs: Array) -> Array:
	var out: Array = []
	for v in vs:
		for w in like(a, v):
			out.append(w.values)
	return out


# ── Angles ───────────────────────────────────────────────────

## A multiple of π as the question writes it, in radians or degrees.
static func angle(t: Q, form: String) -> String:
	return Fmt.dec(t.mul(180)) + "°" if form == "deg" else Fmt.pi(t)


## "sin(5π/6)", "cos 150°".
static func call_text(fn: String, t: Q, form: String) -> String:
	return "%s %s" % [fn, angle(t, form)] if form == "deg" else "%s(%s)" % [fn, angle(t, form)]


## The sign of fn in quadrant q: +1 or −1.
static func sign_in(fn: String, q: int) -> int:
	match fn:
		"sin":
			return 1 if q <= 2 else -1
		"cos":
			return 1 if q == 1 or q == 4 else -1
	return 1 if q == 1 or q == 3 else -1


## A point on the unit circle for PlotView's `unit-circle`.
static func point(t: float, label: String) -> Dictionary:
	return {"x": cos(t), "y": sin(t), "label": label}


## y = sin x, cos x or tan x over [x0, x1] tπ on GraphView, with its grid at π/2 or π/3, say.
static func wave(f: Callable, x0: Q, x1: Q, ylo: int, yhi: int, step: Q, points: Array = [], hlines: Array = []) -> Dictionary:
	var g := Plot.spec([Plot.sample(f, x0.to_float() * PI, x1.to_float() * PI)], points, floori(x0.to_float() * PI), ceili(x1.to_float() * PI), ylo, yhi, hlines)
	g.x_ticks = pi_ticks(x0, x1, step)
	return g


## A sampled curve with gaps (tan's asymptotes) as one curve per branch.
static func branches(curve: Array) -> Array:
	var out: Array = [[]]
	var gap := 1.5 * absf(curve[1][0] - curve[0][0])
	for i in curve.size():
		if i > 0 and curve[i][0] - curve[i - 1][0] > gap:
			out.append([])
		out[out.size() - 1].append(curve[i])
	return out


## [[x, "π/2"], ...]: the across axis in multiples of step π.
static func pi_ticks(x0: Q, x1: Q, step: Q) -> Array:
	var out: Array = []
	var t := x0
	while t.lt(x1) or t.eq(x1):
		if not t.is_zero():
			out.append([t.to_float() * PI, Fmt.pi(t)])
		t = t.add(step)
	return out
