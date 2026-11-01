class_name LinkExtremesSituation
extends RefCounted
## The `fn-link-extremes` situation (curriculum/question-types.json): an extreme value
## picked first and the function built around it (FAL-420). fn-link-extremes is built
## on it. Every extreme is a whole number (Paper 1), except where a view says otherwise.
##
## generate() returns, by need.kind:
##   "height"    h(t) = a t² + b t + c with a < 0 and its top (T, H): b = −2aT, H = c − aT²,
##               and surd roots
##   "wave"      y = A sin(Bx) + D: |A| 2 to 5, B 2 to 6, D ≠ 0, ±|A| or −2|A|
##   "tangent"   the line y = mx + n touching y = x² + r: n = r − s², m = ±2s, contact (±s, s² + r)
##   "interval"  f(x) = (x − h)² + k on [p, q], h inside and one end further from it
##   "cubic"     f(x) = x³ + bx² + cx + d with f′(x) = 3(x − p)(x − q), p < q whole numbers
## plus kind and paper. tools/check_answers.py (check_link_extremes) reads each function
## back from the question and finds its extremes again.

const TRIES := 2000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var kind: String = need.get("kind", "height")
	var s: Dictionary
	match kind:
		"wave":
			s = _wave(rng)
		"tangent":
			s = _tangent(rng)
		"interval":
			s = _interval(rng)
		"cubic":
			s = _cubic(rng)
		_:
			s = _height(rng)
	if s.is_empty():
		return {}
	s.kind = kind
	s.paper = 1
	return s


static func _height(rng: Seeded) -> Dictionary:
	for i in TRIES:
		var a: int = [-5, -4, -2, -1][rng.int_in(0, 3)]
		var T := rng.int_in(1, 5)
		var c := rng.int_in(1, 20)
		var H := c - a * T * T
		# The roots T ± √(H/−a) are surds: H·(−a) is not a square.
		var sq := roundi(sqrt(float(H * -a)))
		if sq * sq != H * -a:
			return {"a": a, "b": -2 * a * T, "c": c, "T": T, "H": H}
	return {}


static func _wave(rng: Seeded) -> Dictionary:
	var A := ExtensionViews.nonzero(rng, -5, 5)
	while absi(A) < 2:
		A = ExtensionViews.nonzero(rng, -5, 5)
	# D clear of ±|A| and −2|A|, so neither end of the range is 0 and the greatest value's
	# size is never the amplitude.
	var D := ExtensionViews.nonzero(rng, -4, 4)
	while absi(D) == absi(A) or D == -2 * absi(A):
		D = ExtensionViews.nonzero(rng, -4, 4)
	return {"A": A, "B": rng.int_in(2, 6), "D": D}


static func _tangent(rng: Seeded) -> Dictionary:
	for i in TRIES:
		var s := rng.int_in(1, 4)
		var r := rng.int_in(-3, 5)
		var n := r - s * s
		if n != 0:
			return {"s": s, "r": r, "n": n}
	return {}


static func _interval(rng: Seeded) -> Dictionary:
	var h := rng.int_in(-2, 3)
	var k := rng.int_in(-6, 2)
	var near := rng.int_in(1, 2)
	var far := rng.int_in(3, 4)
	# The far end is on the right or the left.
	var right := rng.chance(0.5)
	var p := h - (near if right else far)
	var q := h + (far if right else near)
	return {"h": h, "k": k, "p": p, "q": q, "b": -2 * h, "c": h * h + k}


static func _cubic(rng: Seeded) -> Dictionary:
	for i in TRIES:
		var p := rng.int_in(-4, 2)
		var q := p + 2 * rng.int_in(1, 3)
		var d := rng.int_in(-9, 9)
		var s := {"p": p, "q": q, "b": -3 * (p + q) / 2, "c": 3 * p * q, "d": d}
		s.yp = f_cubic(s, p)
		s.yq = f_cubic(s, q)
		if absi(s.yp) <= 60 and absi(s.yq) <= 60 and s.yp != 0 and s.yq != 0:
			return s
	return {}


## f(x) for the cubic, at a whole number.
static func f_cubic(s: Dictionary, x: int) -> int:
	return x * x * x + s.b * x * x + s.c * x + s.d


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
