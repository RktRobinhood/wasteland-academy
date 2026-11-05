class_name SimultaneousViews
extends ExtensionViews
## The views on the `fn-pre-simultaneous` situation: one builder per unknown of
## fn-pre-simultaneous (FAL-424). A pair is a typed exact point, even in words, where the letters
## are named; "x alone" is a wrong option that can be picked but never typed. Which of no
## solution and infinitely many is a pick of written statements. Spots of "the right side left
## unscaled" and "checked in one equation" are checked against the true pair.

const T := "fn-pre-simultaneous#"
const R_ADD := T + "0"
const R_ONE_SIDE := T + "1"
const R_STOP := T + "2"
const R_ONE_CHECK := T + "3"
const NONE := "No solution: the left sides match but the right sides don't, so the lines are parallel"
const MANY := "Infinitely many solutions: one equation is a multiple of the other, so they are the same line"
const ONE := "Exactly one solution: the two lines cross once"
const NONE_SWAP := "No solution: the two equations are the same line"
const MANY_SWAP := "Infinitely many solutions: the two lines are parallel"

## Moves that don't solve a pair, for method-pick (after the catalogue's failing ones).
const NOT_SOLVE := [
	{"name": "Add up all the coefficients", "why": "that total says nothing about x or y"},
	{"name": "Divide one equation by the other", "why": "equations don't divide term by term"},
	{"name": "Put x = 0 into both equations", "why": "that finds where each line meets the y-axis, not where they meet each other"},
]


func needs() -> Dictionary:
	return {"matching-coefficient": {"form": "matching"}, "scale-one": {"form": "one"}, "scale-both": {"form": "both"}, "word-problem": {"form": "word"},
		"special-case": {"form": "special"}, "missing-coefficient": {"form": "missing"}}


func need(unknown: String, rep: String) -> Dictionary:
	var n := super.need(unknown, rep)
	n.erase("rep")
	return n


func extra() -> Dictionary:
	var mp := ["method-pick"]
	return {"matching-coefficient": mp, "scale-one": ["error-spot", "method-pick"], "scale-both": ["error-spot", "method-pick"], "word-problem": mp,
		"special-case": mp, "missing-coefficient": mp}


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = SimultaneousSituation.export(s)
	out.pick_wrongs = NOT_SOLVE
	return out


static func gk(a: Variant, b: Variant, k: Variant) -> String:
	return LineCrossingViews.gk(a, b, k)


static func lines_of(s: Dictionary) -> Array:
	return ["(1): " + gk(s.a1, s.b1, s.k1), "(2): " + gk(s.a2, s.b2, s.k2)]


static func point(s: Dictionary) -> Dictionary:
	var ans := Answer.make("point", {"x": s.X, "y": s.Y})
	ans.exact = true
	return ans


static func fin(ans: Dictionary) -> String:
	return "So " + Answer.text(ans) + "."


static func cy(c: int) -> String:
	return Fmt.term(Q.new(c), 1, true, "y")


static func cx(c: int) -> String:
	return Fmt.term(Q.new(c), 1, true)


## "3y = 12, so y = 4", or "y = 4" when the coefficient is 1.
static func so(coef: int, rhs: int, v: Q, letter: String) -> String:
	if coef == 1:
		return "%s = %s" % [letter, N(v)]
	return "%s = %s, so %s = %s" % [Fmt.term(Q.new(coef), 1, true, letter), N(rhs), letter, N(v)]


## a × v, for a check: "2 × (−3)".
static func times(a: int, v: Q) -> String:
	return "%s × %s" % [P(a), P(v)]


## "2 × 3 + (−1) × 4 = 2", the pair put into one equation.
static func into(s: Dictionary, a: int, b: int, k: int) -> String:
	return "%s + %s = %s" % [times(a, s.X), times(b, s.Y), N(k)]


static func check_both(s: Dictionary) -> Array:
	return ["Check (1): %s." % into(s, s.a1, s.b1, s.k1), "Check (2): %s." % into(s, s.a2, s.b2, s.k2)]


# ── One coefficient already matching ─────────────────────────

func u_matching_coefficient(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := point(s)
	var out := {"asked": "Solve the pair of equations.", "lines": lines_of(s), "answer": ans}
	var same: bool = s.b2 == 1
	var coef: int = s.a1 - s.a2 if same else s.a1 + s.a2
	var rhs: int = s.k1 - s.k2 if same else s.k1 + s.k2
	var add := "Subtract (2) from (1)" if same else "Add (1) and (2)"
	var elim := "%s to remove y: %s." % [add, so(coef, rhs, s.X, "x")]
	var back := "Put x = %s into (1): y = %s − %s = %s." % [N(s.X), N(s.k1), times(s.a1, s.X), N(s.Y)]
	out.wrongs = []
	if same:
		# Added anyway, with y treated as if it had gone.
		var x := Q.new(s.k1 + s.k2, s.a1 + s.a2)
		out.wrongs.append(wrong({"x": x, "y": x.mul(-s.a1).add(s.k1)}, R_ADD))
	out.generic = LineCrossingViews.point_wrongs(s)
	var y2 := Fmt.poly([-s.a2, s.k2]) if same else Fmt.poly([s.a2, -s.k2])
	var y1 := Fmt.poly([-s.a1, s.k1])
	out.methods = {
		"elimination": method([elim, back, fin(ans)], ans.values),
		"equate-expressions": method(["Make y the subject of each: y = %s and y = %s." % [y1, y2], "Set them equal: %s = %s." % [y1, y2], "Collect: %s." % so(coef, rhs, s.X, "x"), back, fin(ans)], ans.values),
		"check-both": method([elim + " Then y = %s." % N(s.Y)] + check_both(s) + [fin(ans)], ans.values),
	}
	return out


# ── One equation to scale ────────────────────────────────────

## From (2) with x alone, by scaling it by t and taking it from (1): the coefficient and the
## right side of y.
static func one_y(s: Dictionary) -> Array:
	return [s.b1 - s.t * s.b2, s.k1 - s.t * s.k2]


static func one_scaled(s: Dictionary) -> String:
	return gk(s.t, s.t * s.b2, s.t * s.k2)


static func one_sub(s: Dictionary) -> Array:
	var c: Array = one_y(s)
	var xs := "x = %s" % Fmt.poly([-s.b2, s.k2], "y")
	return ["(2) gives %s. Put it into (1): %s(%s)%s = %s." % [xs, N(s.t), Fmt.poly([-s.b2, s.k2], "y"), Fmt.term(Q.new(s.b1), 1, false, "y"), N(s.k1)],
		"Collect: %s." % so(c[0], c[1], s.Y, "y"), "Then x = %s − %s = %s." % [N(s.k2), times(s.b2, s.Y), N(s.X)]]


static func one_elim(s: Dictionary) -> Array:
	var c: Array = one_y(s)
	return ["Multiply (2) by %d: %s." % [s.t, one_scaled(s)], "Subtract it from (1) to remove x: %s." % so(c[0], c[1], s.Y, "y"),
		"Put y = %s into (2): x = %s − %s = %s." % [N(s.Y), N(s.k2), times(s.b2, s.Y), N(s.X)]]


## The two scaled equations added instead of subtracted, with x treated as gone.
static func one_added(s: Dictionary) -> Variant:
	var c: int = s.b1 + s.t * s.b2
	if c == 0:
		return null
	var y := Q.new(s.k1 + s.t * s.k2, c)
	return {"x": y.mul(-s.b2).add(s.k2), "y": y}


func u_scale_one(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := point(s)
	var out := {"asked": "Solve the pair of equations.", "lines": lines_of(s), "answer": ans}
	out.wrongs = [wrong({"x": s.X, "y": Q.new(0), "alone": true}, R_STOP)]
	var add: Variant = one_added(s)
	if add != null:
		out.wrongs.push_front(wrong(add, R_ADD))
	out.generic = LineCrossingViews.point_wrongs(s)
	var e := one_elim(s)
	out.methods = {
		"elimination": method(e + [fin(ans)], ans.values),
		"substitution": method(one_sub(s) + [fin(ans)], ans.values),
		"check-both": method(["Scale (2) by %d and subtract: y = %s, then x = %s." % [s.t, N(s.Y), N(s.X)]] + check_both(s) + [fin(ans)], ans.values),
	}
	# (2) scaled on the left only.
	var coef: int = one_y(s)[0]
	var rhs: int = s.k1 - s.k2
	var y := Q.new(rhs, coef)
	var bad := gk(s.t, s.t * s.b2, s.k2)
	var why := "the whole of (2) is multiplied by %d, so its right side is %s, not %s" % [s.t, N(s.t * s.k2), N(s.k2)]
	var sub := "%s = %s" % [cy(coef), N(rhs)]
	if rng.chance(0.5):
		out.spot = {"lines": [bad, sub, "y = %s" % N(y), "x = %s" % N(y.mul(-s.b2).add(s.k2))], "bad": 0, "ref": R_ONE_SIDE, "why": why}
	else:
		out.spot = {"lines": [gk(s.a2, s.b2, s.k2), bad, sub, "So y = %s" % N(y)], "bad": 1, "ref": R_ONE_SIDE, "why": why}
	return out


# ── Both to scale ────────────────────────────────────────────

func u_scale_both(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := point(s)
	var out := {"asked": "Solve the pair of equations.", "lines": lines_of(s), "answer": ans}
	var ub: int = s.u * s.b1
	var wb: int = s.w * s.b2
	var uk: int = s.u * s.k1
	var wk: int = s.w * s.k2
	var coef: int = ub - wb
	var rhs: int = uk - wk
	var s1 := gk(s.L, ub, uk)
	var s2 := gk(s.L, wb, wk)
	out.wrongs = [wrong({"x": s.X, "y": Q.new(0), "alone": true}, R_STOP)]
	out.generic = LineCrossingViews.point_wrongs(s)
	var back := "Put y = %s into (1): %s = %s, so x = %s." % [N(s.Y), cx(s.a1), N(s.Y.mul(-s.b1).add(s.k1)), N(s.X)]
	out.methods = {
		"elimination": method(["Multiply (1) by %d: %s." % [s.u, s1], "Multiply (2) by %d: %s." % [s.w, s2], "Subtract to remove x: %s." % so(coef, rhs, s.Y, "y"), back, fin(ans)], ans.values),
		"check-both": method(["Scale both to %dx and subtract: y = %s, then x = %s." % [s.L, N(s.Y), N(s.X)]] + check_both(s) + [fin(ans)], ans.values),
	}
	if rng.chance(0.5):
		# The student's y is one out, x fits (1), and only (1) gets the check.
		var y: Q = s.Y.add(1)
		var x: Q = y.mul(-s.b1).add(s.k1).div(s.a1)
		out.spot = {"lines": [s1, s2, "%s = %s" % [cy(coef), N(rhs + coef)], "So (%s, %s), which fits (1)" % [N(x), N(y)]], "bad": 2, "ref": R_ONE_CHECK,
			"why": "subtracting gives %s = %s, and a check in (1) alone missed it: the pair does not fit (2)" % [cy(coef), N(rhs)]}
	else:
		# One right side left unscaled.
		var first: bool = rng.chance(0.5)
		var rk: int = s.k1 - wk if first else uk - s.k2
		var bad := 0 if first else 1
		var written: Array = [gk(s.L, ub, s.k1), s2] if first else [s1, gk(s.L, wb, s.k2)]
		out.spot = {"lines": written + ["%s = %s" % [cy(coef), N(rk)], "So y = %s" % N(Q.new(rk, coef))], "bad": bad, "ref": R_ONE_SIDE,
			"why": "the right side is multiplied too, so it should read %s" % N(uk if first else wk)}
	return out


# ── In words ─────────────────────────────────────────────────

static func count(n: int, one: String, many: String) -> String:
	return "%d %s" % [n, one if n == 1 else many]


func u_word_problem(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := point(s)
	var c: Array = SimultaneousSituation.CONTEXTS[s.ctx]
	var say := func(a: int, b: int, k: int) -> String: return "%s and %s cost $%d." % [count(a, c[0], c[1]), count(b, c[2], c[3]), k]
	var out := {"asked": "Let x be the price of one %s and y the price of one %s, in dollars. Find (x, y)." % [c[0], c[2]], "answer": ans,
		"lines": [say.call(s.a1, s.b1, s.k1), say.call(s.a2, s.b2, s.k2)]}
	var write := "Write two equations: (1) %s and (2) %s." % [gk(s.a1, s.b1, s.k1), gk(s.a2, s.b2, s.k2)]
	out.wrongs = [wrong({"x": s.X, "y": Q.new(0), "alone": true}, R_STOP)]
	# Prices stay positive, so a slip that goes negative is no option here.
	out.generic = [{"x": s.Y, "y": s.X}, {"x": s.X.add(1), "y": s.Y.sub(1)}, {"x": s.X.sub(1), "y": s.Y.add(1)}]
	var e := one_elim(s)
	var sub := one_sub(s)
	out.methods = {
		"elimination": method([write, e[0] + " " + e[1], e[2], fin(ans)], ans.values),
		"substitution": method([write, sub[0], sub[1], sub[2], fin(ans)], ans.values),
	}
	return out


# ── No solution, or infinitely many ──────────────────────────

func u_special_case(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var right: String = MANY if s.many else NONE
	var out := {"asked": "How many solutions has the pair? Give the reason.", "lines": lines_of(s)}
	out.merge(InverseRuleViews.choose(right, [], [NONE if s.many else MANY, ONE, MANY_SWAP if s.many else NONE_SWAP, NONE_SWAP if s.many else MANY_SWAP]))
	var scaled := gk(s.a2, s.b2, s.t * s.k1)
	var gap: int = s.t * s.k1 - s.k2
	var ends := "Subtract (2): 0 = %s, which is %s." % [N(gap), "always true, so every point on the line works" if s.many else "never true, so no pair works"]
	out.methods = {"elimination": method(["Multiply (1) by %d: %s." % [s.t, scaled], ends, right + "."], {"v": right})}
	return out


# ── One coefficient missing ──────────────────────────────────

func u_missing_coefficient(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var on_y: bool = s.on == "y"
	var k: int = s.b1 if on_y else s.a1
	var other: int = s.a1 if on_y else s.b1
	var ans: Dictionary = InverseRuleViews.number("k = ", k)
	var first := "%s + ky = %s" % [cx(s.a1), N(s.k1)] if on_y else "kx%s = %s" % [Fmt.term(Q.new(s.b1), 1, false, "y"), N(s.k1)]
	var out := {"asked": "The pair has the solution (%s, %s). Find k." % [N(s.X), N(s.Y)], "answer": ans, "lines": ["(1): " + first, "(2): " + gk(s.a2, s.b2, s.k2)]}
	var at: Q = s.Y if on_y else s.X
	var off: Q = s.X if on_y else s.Y
	var known: Q = off.mul(other)
	var rest: Q = Q.new(s.k1).sub(known)
	var wrongs: Array = [Q.new(s.k1).add(known).div(at), Q.new(s.k1).sub(known), Q.new(s.k1).sub(at.mul(other)).div(off), Q.new(-k), Q.new(k + 1), Q.new(k - 1)]
	out.generic = wrongs.filter(func(v): return v.is_int()).map(func(v): return {"v": v})
	var shown := "%s + %s × k = %s" % [times(other, off), P(at), N(s.k1)]
	var solve := "So %s × k = %s, and k = %s ÷ %s = %s." % [P(at), N(rest), N(rest), P(at), N(k)]
	out.methods = {
		"substitution": method(["Put x = %s and y = %s into (1): %s." % [N(s.X), N(s.Y), shown], solve, fin(ans)], ans.values),
		"check-both": method(["Check (2) first: %s, so the pair fits it." % into(s, s.a2, s.b2, s.k2), "The pair must fit (1) too: %s." % shown, solve, fin(ans)], ans.values),
	}
	return out
