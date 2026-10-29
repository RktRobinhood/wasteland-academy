class_name GraphTools
extends RefCounted
## The calculator's four graph tools (FAL-419): zeros, maxima, minima and intersections
## of the functions in a window, found with Brent's methods (engine/brent.gd). Each
## tool samples the window, brackets what it is looking for between samples, then
## lets Brent close in, so it finds every one in the window that the samples can
## separate. It also tells where a curve jumps (an asymptote), so the graph is drawn
## with a gap there and no tool reports a pole as a zero or a turning point.
##
## f and g are Callables float -> float (NAN where the function has no value).

const SAMPLES := 400
## Two answers this close (relative to the window) are one.
const SAME := 1e-7
## A touching zero (x² at 0) is a minimum of |f| at most this far from 0.
const TOUCH := 1e-10


## A function of x typed into the calculator, as a Callable. deg: trig in degrees.
static func function_of(tree: Variant, deg: bool = false) -> Callable:
	return func(x: float) -> float: return Expr.eval_float(tree, {"x": x, "deg": deg})


static func _samples(f: Callable, lo: float, hi: float, n: int = SAMPLES) -> Array:
	var xs: Array = []
	var ys: Array = []
	for i in n + 1:
		var x := lo + (hi - lo) * i / n
		xs.append(x)
		ys.append(f.call(x))
	return [xs, ys]


## Whether f jumps between a and b (a pole, as at x = 0 for 1/x): halving the interval
## 40 times towards the bigger change, a continuous f's change shrinks to nothing and a
## jump's doesn't.
static func jumps(f: Callable, a: float, b: float) -> bool:
	var fa: float = f.call(a)
	var fb: float = f.call(b)
	if not is_finite(fa) or not is_finite(fb):
		return true
	for k in 40:
		var m := (a + b) / 2.0
		var fm: float = f.call(m)
		if not is_finite(fm):
			return true
		if absf(fm - fa) > absf(fb - fm):
			b = m
			fb = fm
		else:
			a = m
			fa = fm
	return absf(fb - fa) > 1e-6 * maxf(1.0, maxf(absf(fa), absf(fb)))


## Every zero of f in [lo, hi], in order: a sign change between samples (not at a
## jump) closed in by Brent's root finder, and a touching zero (x² at 0) found by
## minimising |f| where it dips towards 0 without crossing.
static func zeros(f: Callable, lo: float, hi: float) -> Array:
	var s := _samples(f, lo, hi)
	var xs: Array = s[0]
	var ys: Array = s[1]
	var out: Array = []
	var absf_call := func(x: float) -> float: return absf(f.call(x))
	for i in xs.size():
		var y: float = ys[i]
		if not is_finite(y):
			continue
		if y == 0.0:
			_add(out, xs[i], lo, hi)
			continue
		if i + 1 < xs.size() and is_finite(ys[i + 1]) and ys[i + 1] != 0.0 and signf(y) != signf(ys[i + 1]):
			if not jumps(f, xs[i], xs[i + 1]):
				var r := Brent.root(f, xs[i], xs[i + 1])
				if r.ok:
					_add(out, r.x, lo, hi)
			continue
		# |f| dips here without f crossing 0: a touching zero, or a near miss.
		if i > 0 and i + 1 < xs.size() and is_finite(ys[i - 1]) and is_finite(ys[i + 1]) \
				and signf(ys[i - 1]) == signf(y) and signf(ys[i + 1]) == signf(y) \
				and absf(y) < absf(ys[i - 1]) and absf(y) <= absf(ys[i + 1]):
			var m := Brent.minimize(absf_call, xs[i - 1], xs[i], xs[i + 1])
			if m.fx <= TOUCH * maxf(1.0, absf(ys[i - 1]) + absf(ys[i + 1])) and not jumps(f, xs[i - 1], xs[i + 1]):
				_add(out, m.x, lo, hi)
	out.sort()
	return out


## Every turning point of f inside (lo, hi): kind "max" or "min". Each is
## {"x", "y"}, found by Brent's minimiser from a sample lower (or higher) than both its
## neighbours. A pole between those samples is not a turning point.
static func extrema(f: Callable, lo: float, hi: float, kind: String) -> Array:
	var sgn := -1.0 if kind == "max" else 1.0
	var g := func(x: float) -> float: return sgn * f.call(x)
	var s := _samples(g, lo, hi)
	var xs: Array = s[0]
	var ys: Array = s[1]
	var out: Array = []
	for i in range(1, xs.size() - 1):
		if not (is_finite(ys[i - 1]) and is_finite(ys[i]) and is_finite(ys[i + 1])):
			continue
		if ys[i] < ys[i - 1] and ys[i] <= ys[i + 1]:
			if jumps(f, xs[i - 1], xs[i + 1]):
				continue
			var m := Brent.minimize(g, xs[i - 1], xs[i], xs[i + 1])
			if m.x > lo and m.x < hi:
				var known := false
				for p in out:
					if absf(p.x - m.x) <= SAME * (hi - lo):
						known = true
				if not known:
					out.append({"x": m.x, "y": f.call(m.x)})
	return out


## Every point where f and g meet in [lo, hi], each {"x", "y"}: the zeros of f − g.
static func intersections(f: Callable, g: Callable, lo: float, hi: float) -> Array:
	var h := func(x: float) -> float: return f.call(x) - g.call(x)
	var out: Array = []
	for x in zeros(h, lo, hi):
		if not jumps(f, x - 1e-6 * (hi - lo), x + 1e-6 * (hi - lo)) and not jumps(g, x - 1e-6 * (hi - lo), x + 1e-6 * (hi - lo)):
			out.append({"x": x, "y": f.call(x)})
	return out


static func _add(out: Array, x: float, lo: float, hi: float) -> void:
	for y in out:
		if absf(y - x) <= SAME * (hi - lo):
			return
	out.append(x)
