class_name GraphTableSituation
extends RefCounted
## The `composite-graph-table` situation (curriculum/question-types.json): a graph of f
## through grid points, or a table of f and g, built so that every composite and inverse
## reading lands on a shown value (FAL-422).
##
## f (and g) are defined at consecutive whole numbers xs, with whole-number values:
##   fy, gy   the values of f and g at each of xs. A graph joins the points with straight
##            lines, so a one-to-one f is always rising or always falling.
## generate() returns, by mode (need.mode):
##   read     f only, one-to-one (rising or falling), 6 points
##   self     f one-to-one with at least two inputs whose output is also an input, so
##            (f∘f)(a) can be read twice
##   zero     f one-to-one with f(k) = 0 at a whole k whose k + 1 is also an input
##   pair     f and g, both one-to-one on the same inputs, with at least two inputs a for
##            which g(a) is an input of f (and f(a) one of g)
##   turn     f = c − (x − p)² (or c + (x − p)²) on p − 3 … p + 3: it turns back at p, so
##            f(x) = k has two answers and only one side of p has an inverse
##   rule     f(x) = c0 + c1·x + c2·x², with co = [c0, c1, c2], for a rule beside a graph
##
## The clean limits are the checker's too (tools/check_answers.py, GT_*).

const TRIES := 2000
const N_POINTS := 6


static func pick(rng: Seeded, xs: Array) -> Variant:
	return xs[rng.int_in(0, xs.size() - 1)]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var mode: String = need.get("mode", "read")
	# Direct substitution needs a rule to substitute into, whatever the rep.
	if mode == "self" and need.get("angle", "") == "direct-substitution":
		mode = "rule"
		need = need.duplicate()
		need.self = true
	for i in TRIES:
		var s := _draw(rng, mode, need)
		if not s.is_empty():
			s.mode = mode
			return s
	push_error("GraphTableSituation: no clean situation for %s" % need)
	return {}


## A rising or falling run of n whole numbers from `start`, steps of 1 to 2.
static func run(rng: Seeded, n: int, start: int, rising: bool) -> Array:
	var out: Array = [start]
	for i in n - 1:
		var step := rng.int_in(1, 2)
		out.append(out[i] + (step if rising else -step))
	return out


static func _draw(rng: Seeded, mode: String, need: Dictionary) -> Dictionary:
	var s := {}
	var x0 := rng.int_in(-3, 0)
	var xs: Array = range(x0, x0 + N_POINTS)
	s.xs = xs
	match mode:
		"read", "self", "zero", "pair":
			var rising := rng.chance(0.55)
			var fy: Array
			if mode == "zero":
				var j := rng.int_in(1, N_POINTS - 3)
				fy = run(rng, N_POINTS, 0, rising)
				var shift: int = fy[j]
				fy = fy.map(func(v): return v - shift)
				s.k = xs[j]
			else:
				fy = run(rng, N_POINTS, rng.int_in(x0 - 2, x0 + 2) if mode != "read" else rng.int_in(-5, 3), rising)
			s.fy = fy
			if mode == "self" and _inside(s, fy).size() < 2:
				return {}
			if mode == "pair":
				s.gy = run(rng, N_POINTS, rng.int_in(x0 - 2, x0 + 2), rng.chance(0.5))
				if _inside(s, s.gy).size() < 3 or _inside(s, fy).size() < 3:
					return {}
			if fy.map(func(v): return absi(v)).max() > 9:
				return {}
		"turn":
			var p: int = pick(rng, [-1, 1, 2])
			var c := rng.int_in(6, 9)
			var up := rng.chance(0.5)
			s.xs = range(p - 3, p + 4)
			s.p = p
			s.up = up
			s.fy = s.xs.map(func(x): return (c - (x - p) * (x - p)) if up else (-c + (x - p) * (x - p)))
			s.c = c
		"rule":
			var c2: int = pick(rng, [-1, -1, 1, 1, 2])
			var c1 := rng.int_in(-3, 3)
			var c0 := rng.int_in(-4, 6)
			s.co = [Q.new(c0), Q.new(c1), Q.new(c2)]
			s.xs = range(-4, 5)
			s.fy = s.xs.map(func(x): return c0 + c1 * x + c2 * x * x)
			if s.fy.map(func(v): return absi(v)).max() > 25:
				return {}
			if need.get("self", false):
				# A self-composite needs an input whose output is small and whose output's output isn't large.
				var ok := false
				for a in range(-3, 4):
					var m: int = c0 + c1 * a + c2 * a * a
					if absi(m) <= 6 and absi(c0 + c1 * m + c2 * m * m) <= 99:
						ok = true
				if not ok:
					return {}
	return s


## The positions of values (of f or g) that are themselves inputs.
static func _inside(s: Dictionary, ys: Array) -> Array:
	var out: Array = []
	for i in ys.size():
		if ys[i] in s.xs:
			out.append(i)
	return out


## f at the input x (a whole number in xs), or null if x isn't an input.
static func at(xs: Array, ys: Array, x: int) -> Variant:
	var i := xs.find(x)
	return null if i < 0 else ys[i]


## The input where ys takes the value y, or null.
static func where(xs: Array, ys: Array, y: int) -> Variant:
	var i := ys.find(y)
	return null if i < 0 else xs[i]


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
