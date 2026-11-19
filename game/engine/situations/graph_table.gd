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
	if mode == "self" and need.get("angle", "") in ["direct-substitution", "build-then-substitute"]:
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
			# More than one fixed point (f(x) = x) makes f look like its own inverse.
			if range(N_POINTS).filter(func(i): return fy[i] == xs[i]).size() > 1:
				return {}
			if mode == "self" and (_inside(s, fy).size() < 2 or self_inputs(s).is_empty()):
				return {}
			if mode == "pair":
				s.gy = run(rng, N_POINTS, rng.int_in(x0 - 2, x0 + 2), rng.chance(0.5))
				if _inside(s, s.gy).size() < 3 or _inside(s, fy).size() < 3:
					return {}
				# Every two-function reading must have an input whose answer is not the input
				# itself or the inner value (FAL-1055).
				if composite_inputs(s, "g", "f").is_empty() or composite_inputs(s, "f", "g").is_empty() \
						or mixed_outputs(s).is_empty() or missing_inputs(s).is_empty():
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
			if need.get("self", false) and self_inputs(s).is_empty():
				return {}
	return s


## f at x: from the rule in rule mode, else from the points (null off the points).
static func f_at(s: Dictionary, x: int) -> Variant:
	if s.has("co"):
		return s.co[0].n + s.co[1].n * x + s.co[2].n * x * x
	return at(s.xs, s.fy, x)


## The inputs a for (f∘f)(a) whose inner value f(a) is a shown input, and whose answer
## f(f(a)) is not a, not f(a) and not f(a)² (a fixed point or a 2-cycle gives the input or
## the inner value back, so a slip would be the key). From a rule, a runs over −3 … 3.
static func self_inputs(s: Dictionary) -> Array:
	var out: Array = []
	for a in (range(-3, 4) if s.has("co") else s.xs):
		var m = f_at(s, a)
		if m == null or not m in s.xs:
			continue
		var v = f_at(s, m)
		if v != a and v != m and m != a and v != m * m:
			out.append(a)
	return out


## The inputs a for (outer∘inner)(a) whose inner value is an input, and whose answer is
## not a and not the inner value.
static func composite_inputs(s: Dictionary, inner: String, outer: String) -> Array:
	var iy: Array = s.gy if inner == "g" else s.fy
	var oy: Array = s.gy if outer == "g" else s.fy
	var out: Array = []
	for x in s.xs:
		var m = at(s.xs, iy, x)
		if not m in s.xs:
			continue
		var v = at(s.xs, oy, m)
		if v != x and v != m:
			out.append(x)
	return out


## The outputs b of g for (f∘g⁻¹)(b) whose answer f(g⁻¹(b)) is not b and not g⁻¹(b).
static func mixed_outputs(s: Dictionary) -> Array:
	var out: Array = []
	for i in s.xs.size():
		var b: int = s.gy[i]
		var v: int = s.fy[i]
		if v != b and v != s.xs[i]:
			out.append(b)
	return out


## The inputs a whose g(a) can be the missing entry: g(a) is an input of f, g(a) is not a,
## and (f∘g)(a) is not g(a) (or the composite's value would be the key).
static func missing_inputs(s: Dictionary) -> Array:
	var out: Array = []
	for x in s.xs:
		var ga = at(s.xs, s.gy, x)
		if ga in s.xs and ga != x and at(s.xs, s.fy, ga) != ga:
			out.append(x)
	return out


## The outputs b for f⁻¹(b) whose answer is not b, and not f(b) (the inverse-undo#2 slip).
static func inverse_outputs(s: Dictionary) -> Array:
	var out: Array = []
	for i in s.xs.size():
		var b: int = s.fy[i]
		var a: int = s.xs[i]
		if b != a and at(s.xs, s.fy, b) != a:
			out.append(b)
	return out


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
