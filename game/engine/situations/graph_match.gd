class_name GraphMatchSituation
extends RefCounted
## The `graph-match` situation (curriculum/question-types.json): an equation and its
## graph, matched by intercepts, a test point and end behaviour (FAL-420).
## fn-ext-match-graph is built on it. Paper 1: whole-number features.
##
## generate() returns:
##   fam   "exp" y = a·b^x + c (b 2, 3, ½ or ⅓; a ±1 or 2), or "quad" y = a(x − p)(x − q)
##   a, b, c (exp); a, p, q (quad), as Q
##   y0    the y-intercept
##   others  for match-several: two more functions of other families, [{"fam", ...}]
##   paper 1
##
## need: fam ("exp", "quad" or "any"), a_neg (quad: a < 0), decay (exp: a > 0, b < 1).

const BASES := [[2, 1], [3, 1], [1, 2], [1, 3]]


static func generate(rng: Seeded, need: Dictionary = {}) -> Dictionary:
	# The stream's first draw leans low (FAL-460), so it is spent first.
	rng.int_in(0, 1)
	var fam: String = need.get("fam", "any")
	if fam == "any":
		fam = "exp" if rng.chance(0.5) else "quad"
	var s := _one(rng, fam, need.get("a_neg", false))
	# decay: a decaying exponential above its asymptote, a > 0 and b < 1.
	if need.get("decay", false):
		s.a = Q.new(rng.int_in(1, 4))
		s.b = Q.new(1, rng.int_in(2, 3))
		s.y0 = y_at(s, 0.0)
	# Two more of the other shapes, for matching three at once.
	var other := _one(rng, fam, not need.get("a_neg", false) and fam == "quad")
	# Three different equations: the third of the same family isn't this one, or this one flipped.
	for i in 50:
		var flip: bool = (other.get("p") == s.get("p") and other.get("q") == s.get("q")) if fam == "quad" else (other.get("b") == s.get("b") and other.get("c") == s.get("c"))
		if text(other) != text(s) and not flip:
			break
		other = _one(rng, fam, not need.get("a_neg", false) and fam == "quad")
	s.others = [_one(rng, "quad" if fam == "exp" else "exp", false), other]
	s.paper = 1
	return s


static func _one(rng: Seeded, fam: String, a_neg: bool) -> Dictionary:
	var s := {"fam": fam}
	if fam == "exp":
		var bb: Array = BASES[rng.int_in(0, 3)]
		s.b = Q.new(bb[0], bb[1])
		s.a = Q.new([1, 2, -1][rng.int_in(0, 2)])
		s.c = Q.new(rng.int_in(-3, 3))
		if s.c.add(s.a).is_zero():
			s.c = s.c.add(Q.new(1))
	else:
		s.a = Q.new([1, -1][rng.int_in(0, 1)] if not a_neg else -1)
		# Roots away from 0, so the factors read (x + 3)(x − 1), never (x).
		var p: int = [-4, -3, -2, -1, 1][rng.int_in(0, 4)]
		var q := p + rng.int_in(2, 5)
		if q == 0:
			q += 1
		s.p = Q.new(p)
		s.q = Q.new(q)
	s.y0 = y_at(s, 0.0)
	return s


static func y_at(s: Dictionary, x: Variant) -> Variant:
	if x is float:
		if s.fam == "exp":
			return s.a.to_float() * pow(s.b.to_float(), x) + s.c.to_float()
		return s.a.to_float() * (x - s.p.to_float()) * (x - s.q.to_float())
	return Q.new(0)


## The y-intercept exactly.
static func y0_q(s: Dictionary) -> Q:
	if s.fam == "exp":
		return s.a.add(s.c)
	return s.a.mul(s.p).mul(s.q)


## The equation as written: "y = 2(3)^x − 1", "y = −(x + 1)(x − 3)".
static func text(s: Dictionary) -> String:
	if s.fam == "exp":
		var base := Fmt.num(s.b) if s.b.is_int() else "(%s)" % Fmt.num(s.b)
		var head := ("%s(%s)" % [Fmt.lead(s.a), Fmt.num(s.b)] if s.b.is_int() else "%s%s" % [Fmt.lead(s.a), base]) + "^x"
		if s.a.eq(1) or s.a.eq(-1):
			head = Fmt.lead(s.a) + base + "^x"
		return "y = " + head + Answer.plus_q(s.c)
	return "y = %s(%s)(%s)" % [Fmt.lead(s.a), Answer.x_minus(s.p), Answer.x_minus(s.q)]


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
