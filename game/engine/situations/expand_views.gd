class_name ExpandViews
extends ExtensionViews
## The views on the `fn-pre-expand` situation: one builder per unknown of fn-pre-expand
## (FAL-459). The "graph" representation is the catalogue's area grid, drawn as a
## table: the bracket terms on the edges and the cells to fill. Answers are the poly
## kind (Ax² + Bx + C, with the x² term given when it is just x²).

const REF_SQUARE_EACH := "fn-pre-expand#0"
const REF_FRONT_FIRST := "fn-pre-expand#1"
const REF_SIGN := "fn-pre-expand#2"
const REF_D_TIMES_K := "fn-pre-expand#3"


func needs() -> Dictionary:
	return {
		"single-bracket": {"form": "single"},
		"double-bracket": {"form": "double"},
		"perfect-square": {"form": "square"},
		"scaled-product": {"form": "scaled"},
		"vertex-form-expand": {"form": "vertex"},
		"missing-term": {"form": "missing"},
	}


func extra() -> Dictionary:
	return {"vertex-form-expand": ["error-spot"]}


# ── Helpers ──────────────────────────────────────────────────

## (x + r): "(x + 3)", "(x − 5)".
static func br(r: Q) -> String:
	return Fmt.factor(r.neg())


## The expression shown for a situation.
static func shown(s: Dictionary) -> String:
	match s.form:
		"single":
			return Fmt.lead(s.k) + "x" + br(s.r)
		"double":
			return br(s.r) + br(s.s)
		"square":
			return br(s.r) + "²"
		"scaled":
			return Fmt.lead(s.k) + br(s.r) + br(s.s)
		"vertex":
			return Fmt.lead(s.k) + br(s.r) + "²" + Fmt.plus(s.d)
	return "?"


## The answer: Ax² + Bx + C, with the x² term given when A is 1.
static func expansion(s: Dictionary) -> Dictionary:
	if s.form == "single":
		return Answer.make("poly", {"c0": s.A, "c1": s.B}, {"powers": [2, 1]})
	if s.A.eq(1):
		return Answer.make("poly", {"c1": s.B, "c2": s.C}, {"powers": [2, 1, 0], "lead": Q.new(1)})
	return Answer.make("poly", {"c0": s.A, "c1": s.B, "c2": s.C}, {"powers": [2, 1, 0]})


## Values for a wrong Ax² + Bx + C in the answer's shape.
static func abc(ans: Dictionary, a: Q, b: Q, c: Q) -> Dictionary:
	if ans.fixed.has("lead"):
		return {"c1": b, "c2": c}
	if ans.fixed.powers.size() == 2:
		return {"c0": a, "c1": b}
	return {"c0": a, "c1": b, "c2": c}


static func poly(a: Variant, b: Variant, c: Variant) -> String:
	return Fmt.general(a, b, c)


## The area grid for (x + r)(x + s): edges given, cells to fill.
static func grid(r: Q, s: Q) -> Dictionary:
	return {"rows": [["×", ["x", signed(s)]], ["x", ["?", "?"]], [signed(r), ["?", "?"]]]}


static func given_of(s: Dictionary) -> Dictionary:
	return {"form": s.form, "k": s.k.key(), "r": s.r.key(), "s": s.s.key(), "d": s.d.key()}


## The four products of (x + r)(x + s).
static func products(r: Q, s: Q) -> String:
	return "x × x = x²,  x × %s = %s,  %s × x = %s,  %s × %s = %s" % [P(s), Fmt.term(s, 1, true), P(r), Fmt.term(r, 1, true), P(r), P(s), N(r.mul(s))]


## A check with a number: the first x of 1, 2, 3 that doesn't make a bracket 0.
static func check_x(s: Dictionary) -> Q:
	for x in [1, 2, 3]:
		if not s.r.add(x).is_zero() and not s.s.add(x).is_zero():
			return Q.new(x)
	return Q.new(4)


static func value_at(s: Dictionary, x: Q) -> Q:
	if s.form == "single":
		return s.k.mul(x).mul(x.add(s.r))
	return s.k.mul(x.add(s.r)).mul(x.add(s.s)).add(s.d)


## "Check with x = 1: (1 + 3)(1 + 5) = 24, and 1 + 8 + 15 = 24. They agree." The
## number-check forms (double, scaled, vertex) have no x outside a bracket.
static func check_step(s: Dictionary) -> String:
	var x := check_x(s)
	var right := N(s.A.mul(x.sq())) + Fmt.plus(s.B.mul(x)) + Fmt.plus(s.C)
	var v := value_at(s, x)
	return "Check with x = %s: %s = %s, and %s = %s. They agree." % [N(x), shown(s).replace("x", N(x)), N(v), right, N(v)]


# ── fn-pre-expand ────────────────────────────────────────────

func u_single_bracket(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := expansion(s)
	var kx := Fmt.lead(s.k) + "x"
	var steps := ["%s × x = %s,  %s × %s = %s" % [kx, Fmt.term(s.A, 2, true), kx, P(s.r), Fmt.term(s.B, 1, true)],
		"So %s." % Answer.text(ans)]
	return {"asked": "Expand and simplify.", "lines": [shown(s)], "given": given_of(s), "answer": ans,
		"generic": [abc(ans, s.k, s.r, Q.new(0)), abc(ans, Q.new(1), s.B, Q.new(0)), abc(ans, s.k, s.B.neg(), Q.new(0)), abc(ans, s.k, s.k.add(s.r), Q.new(0))],
		"methods": {"distribute": method(steps, ans.values)}}


func u_double_bracket(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := expansion(s)
	var final := "So %s." % Answer.text(ans)
	var out := {"asked": "Expand and simplify.", "lines": [shown(s)], "given": given_of(s), "answer": ans}
	if rep == "graph":
		out.table = grid(s.r, s.s)
		out.lines = [shown(s), "The area grid has the terms of each bracket on its edges."]
	var collect := "Collect the x terms: %s%s = %s" % [Fmt.term(s.s, 1, true), Fmt.term(s.r, 1, false), Fmt.term(s.B, 1, true)]
	out.methods = {
		"distribute": method([products(s.r, s.s), collect, final], ans.values),
		"grid": method(["Edges: x and %s down the side, x and %s along the top." % [signed(s.r), signed(s.s)],
			"Cells: " + products(s.r, s.s), "Add the cells: %s" % collect.substr(collect.find(":") + 2), final], ans.values),
		"number-check": method(["Multiply out: %s = %s" % [shown(s), poly(1, s.B, s.C)], check_step(s), final], ans.values),
	}
	out.wrongs = [wrong(abc(ans, s.A, s.B.neg(), s.C), REF_SIGN)]
	out.generic = [abc(ans, s.A, s.B, s.C.neg()), abc(ans, s.A, s.C, s.B), abc(ans, s.A, s.r.mul(s.s).add(1), s.C), abc(ans, s.A, Q.new(0), s.C)]
	return out


func u_perfect_square(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := expansion(s)
	var final := "So %s." % Answer.text(ans)
	var out := {"asked": "Expand and simplify.", "lines": [shown(s)], "given": given_of(s), "answer": ans}
	if rep == "graph":
		out.table = grid(s.r, s.r)
		out.lines = [shown(s), "The area grid has the terms of each bracket on its edges."]
	out.methods = {
		"grid": method(["Edges: x and %s down the side, and the same along the top." % signed(s.r),
			"Cells: " + products(s.r, s.r),
			"Add the cells: two middle cells %s each, so %s" % [Fmt.term(s.r, 1, true), Fmt.term(s.B, 1, true)], final], ans.values),
		"square-pattern": method(["(x + r)² = x² + 2rx + r² with r = %s" % N(s.r),
			"2 × %s = %s and %s² = %s" % [P(s.r), N(s.B), P(s.r), N(s.C)], final], ans.values),
	}
	out.wrongs = [wrong(abc(ans, s.A, Q.new(0), s.C), REF_SQUARE_EACH)]
	out.generic = [abc(ans, s.A, s.r, s.C), abc(ans, s.A, s.B, s.B), abc(ans, s.A, s.B, s.C.neg()), abc(ans, s.A, s.B.neg(), s.C)]
	return out


func u_scaled_product(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := expansion(s)
	var final := "So %s." % Answer.text(ans)
	var inner := poly(1, s.r.add(s.s), s.r.mul(s.s))
	var first := "First %s%s = %s" % [br(s.r), br(s.s), inner]
	var times := "Multiply every term by %s: %s" % [N(s.k), poly(s.A, s.B, s.C)]
	var out := {"asked": "Expand and simplify.", "lines": [shown(s)], "given": given_of(s), "answer": ans}
	out.methods = {
		"distribute": method([first, times, final], ans.values),
		"number-check": method(["%s, so %s = %s" % [first, shown(s), poly(s.A, s.B, s.C)], check_step(s), final], ans.values),
	}
	out.wrongs = [wrong(abc(ans, s.k, s.r.add(s.s), s.r.mul(s.s)), REF_FRONT_FIRST)]
	out.generic = [abc(ans, s.k, s.B, s.r.mul(s.s)), abc(ans, s.k, s.r.add(s.s), s.C), abc(ans, s.k, s.B.neg(), s.C), abc(ans, s.k, s.B, s.C.neg())]
	return out


func u_vertex_form_expand(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := expansion(s)
	var final := "So %s." % Answer.text(ans)
	var sq := poly(1, s.r.mul(2), s.r.sq())
	var kr2: Q = s.k.mul(s.r.sq())
	var scaled := "%s(%s) = %s" % [Fmt.lead(s.k), sq, poly(s.k, s.B, kr2)]
	var add_d := "Then add %s: %s%s = %s" % [N(s.d), N(kr2), Fmt.plus(s.d), N(s.C)]
	var out := {"asked": "Expand and simplify.", "lines": [shown(s)], "given": given_of(s), "answer": ans}
	out.methods = {
		"distribute": method(["%s² = %s%s = %s" % [br(s.r), br(s.r), br(s.r), sq], scaled, add_d, final], ans.values),
		"square-pattern": method(["%s² = x² + 2 × %s × x + %s² = %s" % [br(s.r), P(s.r), P(s.r), sq], scaled, add_d, final], ans.values),
		"number-check": method(["%s = %s(%s)%s = %s" % [shown(s), Fmt.lead(s.k), sq, Fmt.plus(s.d), poly(s.A, s.B, s.C)], check_step(s), final], ans.values),
	}
	var wrong_c: Q = s.k.mul(s.r.sq().add(s.d))
	out.wrongs = [wrong(abc(ans, s.k, Q.new(0), kr2.add(s.d)), REF_SQUARE_EACH), wrong(abc(ans, s.k, s.B, wrong_c), REF_D_TIMES_K)]
	out.generic = [abc(ans, s.k, s.k.mul(s.r), s.C), abc(ans, s.k, s.B, s.r.sq().add(s.d)), abc(ans, s.k, s.B.neg(), s.C), abc(ans, s.k, s.B, kr2)]
	out.spot = _spot_d_times_k(s, rng)
	return out


## A student's working for k(x + r)² + d that multiplies d by k somewhere: the first
## wrong line is 1, 2 or 3 (of 4), by where the d goes wrong.
static func _spot_d_times_k(s: Dictionary, rng: Seeded) -> Dictionary:
	var e := shown(s)
	var sq := poly(1, s.r.mul(2), s.r.sq())
	var kq := Fmt.lead(s.k)
	var kr2: Q = s.k.mul(s.r.sq())
	var bad_c: Q = s.k.mul(s.r.sq().add(s.d))
	var bad_full := poly(s.k, s.B, bad_c)
	var lines: Array
	var bad: int
	match rng.int_in(0, 3):
		0:
			var inner := poly(1, s.r.mul(2), s.r.sq().add(s.d))
			lines = ["%s = %s[%s²%s]" % [e, kq, br(s.r), Fmt.plus(s.d)],
				"%s²%s = %s" % [br(s.r), Fmt.plus(s.d), inner],
				"%s(%s) = %s" % [kq, inner, bad_full],
				"%s = %s" % [e, bad_full]]
			bad = 0
		1:
			lines = ["%s² = %s" % [br(s.r), sq],
				"%s = %s(%s%s)" % [e, kq, sq, Fmt.plus(s.d)],
				"%s(%s%s) = %s(%s)" % [kq, sq, Fmt.plus(s.d), kq, poly(1, s.r.mul(2), s.r.sq().add(s.d))],
				"%s(%s) = %s" % [kq, poly(1, s.r.mul(2), s.r.sq().add(s.d)), bad_full]]
			bad = 1
		2:
			lines = ["%s² = %s" % [br(s.r), sq],
				"%s%s² = %s" % [kq, br(s.r), poly(s.k, s.B, kr2)],
				"%s = %s" % [e, bad_full],
				"%s = %s" % [bad_full, "%s(%s)" % [kq, poly(1, s.r.mul(2), s.r.sq().add(s.d))]]]
			bad = 2
		_:
			lines = ["%s² = %s" % [br(s.r), sq],
				"%s = %s(%s)%s" % [e, kq, sq, Fmt.plus(s.d)],
				"%s(%s)%s = %s%s" % [kq, sq, Fmt.plus(s.d), poly(s.k, s.B, kr2), Fmt.plus(s.k.mul(s.d))],
				"%s%s = %s" % [poly(s.k, s.B, kr2), Fmt.plus(s.k.mul(s.d)), bad_full]]
			bad = 2
	return {"lines": lines, "bad": bad, "ref": REF_D_TIMES_K,
		"why": "the %s is added after the bracket is multiplied by %s, so it is not multiplied too: the constant is %s%s = %s, not %s" % [
			N(s.d), N(s.k), N(kr2), Fmt.plus(s.d), N(s.C), N(bad_c)]}


func u_missing_term(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: Q = s.r.mul(2)
	var c: Q = s.r.sq()
	var ans := Answer.make("named", {"v0": s.r, "v1": c}, {"names": ["r", "c"]})
	var steps := ["(x + r)² = x² + 2rx + r², so the x terms give 2r = %s" % N(b),
		"r = %s ÷ 2 = %s, and c = r² = %s² = %s" % [N(b), N(s.r), P(s.r), N(c)], "So %s." % Answer.text(ans)]
	return {"asked": "Find r and c.", "lines": ["(x + r)² = %s + c" % Fmt.poly([1, b])],
		"given": {"form": "missing", "b": b.key()}, "answer": ans,
		"generic": [{"v0": b, "v1": b.sq()}, {"v0": s.r, "v1": b}, {"v0": s.r.neg(), "v1": c}, {"v0": s.r, "v1": s.r.mul(2)}],
		"methods": {"square-pattern": method(steps, ans.values)}}
