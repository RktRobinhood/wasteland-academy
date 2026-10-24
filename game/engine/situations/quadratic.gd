class_name QuadraticSituation
extends RefCounted
## The `quadratic` situation (curriculum/question-types.json): one parabola with every
## linked quantity, consistent and with clean numbers.
##
## generate() returns a Dictionary of Q values (and arrays of them):
##   mode            "rational", "surd" or "none" (the situation's `modes`)
##   a, h, k, b, c   leading coefficient, vertex (h, k), general-form b and c
##   disc            the discriminant b² − 4ac
##   p, q            the roots, p < q (rational mode only; null otherwise)
##   surd            d in h ± √d (surd mode only)
##   x1, y1          the extra point (when need.point)
##   xs, ys          the table: f at 7 consecutive integers (when need.table)
##
## The situations that extend this one (quadratic-equation, quadratic-parameter,
## quadratic-inequality, log-quadratic) call generate() with their own `need` and add
## their quantities to the result. Nothing here has to change for them: `need` keys
## they don't use are ignored, and the result is a plain Dictionary they can extend.
##
## need (all optional):
##   mode       "rational", "surd", "none" or "any" (default "rational")
##   even       p + q even, so the axis and vertex are whole numbers (rational mode)
##   no_halves  a is a whole number, so a table or point stays whole
##   graph      roots, vertex and y-intercept on grid points and inside the plot
##   point      pick an extra point (x1, y1) with small whole coordinates
##   point_off_axis   the extra point is not the y-intercept
##   table      pick a table; "roots" makes it show both roots
##   a_not_one  a ≠ 1 (when "assumes a = 1" must be a wrong option)
##
## The clean limits below are the numbers behind the catalogue's `clean` text. The
## SymPy checker (tools/check_answers.py) holds its own copy and fails on any breach.

const A_CHOICES := [[1, 1], [-1, 1], [2, 1], [-2, 1], [1, 2], [-1, 2], [3, 1], [-3, 1]]
const ROOT_MAX := 7        ## |p|, |q| ≤ 7
const H_MAX := 5           ## |h| ≤ 5 in surd and no-real-roots modes
const SURDS := [2, 3, 5, 6, 7]
const K_MAX := 20
const B_MAX := 24
const C_MAX := 24
const GRAPH_Y_MAX := 16    ## on a graph: |k|, |c|, |y1| ≤ 16
const POINT_X_MAX := 6
const POINT_Y_MAX := 24
const TABLE_Y_MAX := 40
const TRIES := 4000


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var mode: String = need.get("mode", "rational")
	for i in TRIES:
		var m := mode
		if m == "any":
			m = ["rational", "rational", "rational", "surd", "none"][rng.int_in(0, 4)]
		var s := _draw(rng, m, need)
		if s.is_empty() or not _clean(s, need):
			continue
		if need.get("point", false) and not _pick_point(rng, s, need):
			continue
		if need.get("table", false) and not _pick_table(rng, s, need):
			continue
		return s
	push_error("QuadraticSituation: no clean situation for %s" % need)
	return {}


static func f(s: Dictionary, x: Variant) -> Q:
	var xq := Q.of(x)
	return s.a.mul(xq.sub(s.h).sq()).add(s.k)


static func _draw(rng: Seeded, mode: String, need: Dictionary) -> Dictionary:
	var ac: Array = A_CHOICES[rng.int_in(0, A_CHOICES.size() - 1)]
	var a := Q.new(ac[0], ac[1])
	if need.get("no_halves", false) and not a.is_int():
		return {}
	if need.get("a_not_one", false) and a.eq(1):
		return {}
	var s := {"mode": mode, "a": a, "p": null, "q": null, "surd": null, "x1": null, "y1": null, "xs": null, "ys": null}
	match mode:
		"rational":
			var p := rng.int_in(-ROOT_MAX, ROOT_MAX)
			var q := rng.int_in(-ROOT_MAX, ROOT_MAX)
			if p == q or p == 0 or q == 0 or p + q == 0:
				return {}
			if p > q:
				var t := p
				p = q
				q = t
			if need.get("even", false) and (p + q) % 2 != 0:
				return {}
			s.p = Q.new(p)
			s.q = Q.new(q)
			s.h = Q.new(p + q, 2)
			s.k = a.neg().mul(Q.new((q - p) * (q - p), 4))
			s.b = a.neg().mul(Q.new(p + q))
			s.c = a.mul(Q.new(p * q))
		"surd":
			var h := rng.int_in(-H_MAX, H_MAX)
			if h == 0:
				return {}
			var d: int = SURDS[rng.int_in(0, SURDS.size() - 1)]
			s.surd = Q.new(d)
			s.h = Q.new(h)
			s.k = a.neg().mul(Q.new(d))
			s.b = a.mul(Q.new(-2 * h))
			s.c = a.mul(Q.new(h * h)).add(s.k)
		"none":
			var h := rng.int_in(-H_MAX, H_MAX)
			if h == 0:
				return {}
			s.h = Q.new(h)
			s.k = Q.new(a.sign() * rng.int_in(1, 9))
			s.b = a.mul(Q.new(-2 * h))
			s.c = a.mul(Q.new(h * h)).add(s.k)
	s.disc = s.b.sq().sub(Q.new(4).mul(a).mul(s.c))
	return s


static func _clean(s: Dictionary, need: Dictionary) -> bool:
	var a: Q = s.a
	# ±3 only when nothing is halved.
	if absi(a.n) == 3 and not (s.h.is_int() and s.k.is_int() and s.c.is_int()):
		return false
	if need.get("no_halves", false) and not (s.h.is_int() and s.k.is_int() and s.b.is_int() and s.c.is_int()):
		return false
	# With q − p even (h whole), k is a whole number or a half.
	if s.h.is_int() and not s.k.mul(2).is_int():
		return false
	if absi(s.k.n) > K_MAX * s.k.d or absi(s.b.n) > B_MAX * s.b.d or absi(s.c.n) > C_MAX * s.c.d:
		return false
	# Roots, vertex and y-intercept are distinct points.
	if s.c.is_zero() or s.h.is_zero():
		return false
	if need.get("graph", false):
		if not (s.h.is_int() and s.k.is_int() and s.c.is_int()):
			return false
		if absi(s.k.n) > GRAPH_Y_MAX or absi(s.c.n) > GRAPH_Y_MAX:
			return false
	return true


static func _pick_point(rng: Seeded, s: Dictionary, need: Dictionary) -> bool:
	var ymax := GRAPH_Y_MAX if need.get("graph", false) else POINT_Y_MAX
	var options := []
	for x in range(-POINT_X_MAX, POINT_X_MAX + 1):
		var xq := Q.new(x)
		if xq.eq(s.h) or (s.p != null and (xq.eq(s.p) or xq.eq(s.q))):
			continue
		if x == 0 and need.get("point_off_axis", false):
			continue
		var y := f(s, xq)
		if y.is_int() and absi(y.n) <= ymax and absi(xq.sub(s.h).n) <= 4 * xq.sub(s.h).d:
			options.append(x)
	if options.is_empty():
		return false
	var x1: int = options[rng.int_in(0, options.size() - 1)]
	s.x1 = Q.new(x1)
	s.y1 = f(s, s.x1)
	return true


## Seven consecutive whole x values, centred near h, so a symmetric pair of equal
## outputs shows. need.table == "roots" also puts both roots in the table.
static func _pick_table(rng: Seeded, s: Dictionary, need: Dictionary) -> bool:
	if not s.h.is_int() or not s.a.is_int():
		return false
	var h: int = s.h.n
	var offsets := rng.shuffled([-1, 0, 1])
	for off in offsets:
		var start: int = h - 3 + off
		var ok := true
		if need.get("table") is String and need.table == "roots":
			ok = s.p != null and s.p.n >= start and s.q.n <= start + 6
		if not ok:
			continue
		var xs := []
		var ys := []
		for x in range(start, start + 7):
			var y := f(s, x)
			if not y.is_int() or absi(y.n) > TABLE_Y_MAX:
				ok = false
				break
			xs.append(Q.new(x))
			ys.append(y)
		if ok:
			s.xs = xs
			s.ys = ys
			return true
	return false


## The situation as plain strings, for the answer export.
static func export(s: Dictionary) -> Dictionary:
	var out := {}
	for key in s:
		var v = s[key]
		if v is Q:
			out[key] = v.key()
		elif v is Array:
			out[key] = v.map(func(e): return e.key())
		else:
			out[key] = v
	return out
