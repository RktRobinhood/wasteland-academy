class_name SurdsSituation
extends RefCounted
## The `fn-pre-surds` situation (curriculum/question-types.json): surds to simplify, for
## the prior-learning type fn-pre-surds (FAL-459), in the shapes exact quadratic
## answers take. Each one is built from its simplest form a√b (b with no square factor).
##
## generate() returns:
##   form   "simplify" √n, "add" √n1 + √n2, "multiply" √m × √n, "fraction"
##          (m0 ± √n)/d, "toroot" a√b written as √n
##   a, b   the simplest form a√b (for "fraction": h ± a√b, with h too)
##   and n; a1, a2, n1, n2 (add); m, n (multiply); m0, n, d, h (fraction)

const SQUARE_FREE := [2, 3, 5, 6, 7, 10, 11, 13, 14, 15, 17]
const TRIES := 1000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	# The stream's first draw leans low (see quadratic_inequality.gd), so it is spent.
	rng.int_in(0, 1)
	var form: String = need.get("form", "simplify")
	for i in TRIES:
		var s := _draw(rng, form)
		if not s.is_empty():
			s.form = form
			return s
	push_error("SurdsSituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, form: String) -> Dictionary:
	var b: int = rng.pick(SQUARE_FREE)
	match form:
		"simplify":
			# a has a smaller square factor than a² (4, 6, 8, 9, 10), so taking out a
			# smaller square first needs a second pass (the catalogue's slow note).
			var a: int = rng.pick([4, 6, 8, 9, 10])
			if a * a * b > 300:
				return {}
			return {"a": Q.new(a), "b": Q.new(b), "n": Q.new(a * a * b)}
		"add":
			var a1 := rng.int_in(2, 5)
			var a2 := rng.int_in(2, 5)
			if a1 == a2 or b > 7 or a1 * a1 * b > 200 or a2 * a2 * b > 200:
				return {}
			return {"a1": Q.new(a1), "a2": Q.new(a2), "n1": Q.new(a1 * a1 * b), "n2": Q.new(a2 * a2 * b), "a": Q.new(a1 + a2), "b": Q.new(b)}
		"multiply":
			# √m × √n = √(a²b) with m and n themselves not squares.
			var a := rng.int_in(2, 6)
			var total := a * a * b
			var divisors: Array = []
			for m in range(2, total):
				if total % m == 0 and m < total / m and not _square(m) and not _square(total / m) and total / m <= 60:
					divisors.append(m)
			if divisors.is_empty():
				return {}
			var m: int = rng.pick(divisors)
			return {"m": Q.new(m), "n": Q.new(total / m), "a": Q.new(a), "b": Q.new(b)}
		"fraction":
			var d := rng.int_in(2, 4)
			var h := ExtensionViews.nonzero(rng, -5, 5)
			var k := rng.int_in(1, 3)
			if b > 7:
				return {}
			var n := d * d * k * k * b
			if n > 300:
				return {}
			return {"d": Q.new(d), "h": Q.new(h), "m0": Q.new(d * h), "n": Q.new(n), "a": Q.new(k), "b": Q.new(b)}
		"toroot":
			var a := rng.int_in(2, 9)
			if a * a * b > 400:
				return {}
			return {"a": Q.new(a), "b": Q.new(b), "n": Q.new(a * a * b)}
	return {}


static func _square(n: int) -> bool:
	var r := roundi(sqrt(float(n)))
	return r * r == n


## The prime factors of n, smallest first: 48 -> [2, 2, 2, 2, 3].
static func primes(n: int) -> Array:
	var out: Array = []
	var p := 2
	while n > 1:
		while n % p == 0:
			out.append(p)
			n /= p
		p += 1
	return out


## The largest square factor of n.
static func largest_square(n: int) -> int:
	var best := 1
	for r in range(1, int(sqrt(float(n))) + 1):
		if n % (r * r) == 0:
			best = r * r
	return best


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
