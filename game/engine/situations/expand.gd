class_name ExpandSituation
extends RefCounted
## The `fn-pre-expand` situation (curriculum/question-types.json): brackets to expand,
## for the prior-learning type fn-pre-expand (FAL-459). Small whole numbers in one or
## two brackets, sometimes with a factor in front and a constant after.
##
## generate() returns:
##   form   "single" k·x(x + r), "double" (x + r)(x + s), "square" (x + r)²,
##          "scaled" k(x + r)(x + s), "vertex" k(x + r)² + d, "missing" (x + r)² = x² + bx + c
##   k, r, s, d   the numbers in the brackets (Q), between −9 and 9 and not 0
##   A, B, C      the expansion Ax² + Bx + C (C is 0 for single)

const TRIES := 500


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	var form: String = need.get("form", "double")
	for i in TRIES:
		var s := _draw(rng, form)
		if not s.is_empty():
			s.form = form
			return s
	push_error("ExpandSituation: no clean situation for %s" % need)
	return {}


static func _draw(rng: Seeded, form: String) -> Dictionary:
	var k := Q.new(1)
	var r := Q.new(ExtensionViews.nonzero(rng, -9, 9))
	var s := r
	var d := Q.new(0)
	match form:
		"single":
			k = Q.new(rng.pick([-3, -2, 2, 3, 4, 5]))
		"double", "scaled":
			s = Q.new(ExtensionViews.nonzero(rng, -9, 9))
			# Two different brackets with a middle term.
			if s.eq(r) or s.add(r).is_zero():
				return {}
			if form == "scaled":
				k = Q.new(rng.pick([-3, -2, 2, 3, 4, 5]))
		"vertex":
			k = Q.new(rng.pick([-3, -2, 2, 3, 4]))
			d = Q.new(ExtensionViews.nonzero(rng, -9, 9))
			if k.mul(r.sq()).add(d).is_zero():
				return {}
		"square", "missing":
			pass
		_:
			return {}
	var out := {"k": k, "r": r, "s": s, "d": d}
	if form == "single":
		out.A = k
		out.B = k.mul(r)
		out.C = Q.new(0)
	else:
		out.A = k
		out.B = k.mul(r.add(s))
		out.C = k.mul(r).mul(s).add(d)
	return out


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
