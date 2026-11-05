class_name SubstituteViews
extends ExtensionViews
## The views on the `fn-pre-substitute` situation (FAL-424): one builder per unknown of
## fn-pre-substitute. A value is typed and marked exactly. Words say "find the value of … when
## x = …", and a table is one to complete, its missing entry the input under test.
##
## missing-input lists one method, estimate-check, which the catalogue says can't find the
## input: its working says so, undoes the steps, and then does the check.

const T := "fn-pre-substitute"
const R_SQUARE := T + "#0"
const R_TIMES_FIRST := T + "#1"
const R_DROP_SIGN := T + "#2"
const R_LEFT_RIGHT := T + "#3"
const LAST := "So the value is %s."


func needs() -> Dictionary:
	return {
		"negative-into-square": {"kind": "square"},
		"negative-into-linear": {"kind": "linear"},
		"coefficient-and-power": {"kind": "power"},
		"fraction-input": {"kind": "fraction"},
		"rational-expression": {"kind": "rational"},
		"missing-input": {"kind": "missing"},
	}


func extra() -> Dictionary:
	return {"rational-expression": ["error-spot"]}


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = SubstituteSituation.export(s)
	return out


# ── Helpers ──────────────────────────────────────────────────

static func exact(kind: String = "number", values: Dictionary = {}) -> Dictionary:
	var ans := Answer.make(kind, values)
	ans.exact = true
	return ans


## The expression with the input written in: "2(−3)² + 5(−3) − 1".
static func put_in(s: Dictionary) -> String:
	return s.text.replace("x", "(%s)" % N(s.x0))


## Numbers added up: "18 − 15 − 1".
static func sum_line(vals: Array) -> String:
	var kept: Array = vals.filter(func(v): return not v.is_zero())
	var out := ""
	for v in kept:
		out += N(v) if out == "" else Fmt.plus(v)
	return out if out != "" else "0"


## The polynomial's terms at x0, top power first.
static func terms(s: Dictionary) -> Array:
	var out: Array = []
	var n: int = s.co.size()
	for i in n:
		var t := Q.of(s.co[i])
		for j in n - 1 - i:
			t = t.mul(s.x0)
		out.append(t)
	return out


## The question's text and table, by representation. A table is completed from the expression.
static func show(rep: String, s: Dictionary, out: Dictionary) -> Dictionary:
	match rep:
		"words":
			out.asked = "Find the value of %s when x = %s." % [s.text, N(s.x0)]
		"table":
			out.asked = "Find the missing value in the table."
			out.lines = ["y = %s" % s.text]
			var ys: Array = s.xs.map(func(x): return "?" if x.eq(s.x0) else N(at(s, x)))
			out.table = {"rows": [["x", s.xs.map(func(x): return N(x))], ["y", ys]]}
		_:
			out.asked = "Find the value of the expression."
			out.lines = [s.text, "x = %s" % N(s.x0)]
	return out


static func at(s: Dictionary, x: Q) -> Q:
	return SubstituteSituation.poly_at(s.co, x) if s.has("co") else SubstituteSituation.lin_at(s.top, x).div(SubstituteSituation.lin_at(s.bottom, x))


## A method's steps with the last line added.
static func ways(steps: Dictionary, ans: Dictionary) -> Dictionary:
	return BasicFunctionViews.ways(steps, LAST % Answer.text(ans), ans)


static func sign_word(v: Q) -> String:
	return "positive" if v.sign() > 0 else "negative"


static func opts(vals: Array) -> Array:
	return vals.map(func(v): return {"v": v})


# ── Powers and signs ─────────────────────────────────────────

func u_negative_into_square(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := exact("number", {"v": s.value})
	var a := Q.of(s.co[0])
	var b := Q.of(s.co[1])
	var c := Q.of(s.co[2])
	var x0: Q = s.x0
	var sq := x0.sq()
	var ts := terms(s)
	var out := show(rep, s, {"answer": ans})
	out.wrongs = [wrong({"v": s.value.sub(ts[0].mul(2))}, R_SQUARE)]
	out.generic = opts([a.mul(2).mul(x0).add(ts[1]).add(c), ts[0].sub(ts[1]).add(c), s.value.neg(), s.value.add(2)])
	var sums := "%s = %s" % [sum_line(ts), N(s.value)]
	out.methods = ways({
		"bracket-first": ["Replace x with (%s): %s" % [N(x0), put_in(s)], "(%s)² = %s, so the terms are %s" % [N(x0), N(sq), sum_line(ts)], sums],
		"order-of-operations": ["Powers first: (%s)² = %s" % [N(x0), N(sq)], "Then multiply: the terms are %s" % sum_line(ts), "Then add and subtract: %s" % sums],
		"estimate-check": ["The square (%s)² = %s is positive, so the x² term is %s, which is %s" % [N(x0), N(sq), N(ts[0]), sign_word(ts[0])], "Work it out: %s" % sums,
			"The sign and size fit: the x² term has size %s and the rest adds %s" % [N(ts[0].abs_q()), N(s.value.sub(ts[0]))]],
	}, ans)
	return out


func u_negative_into_linear(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := exact("number", {"v": s.value})
	var m := Q.of(s.co[0])
	var c := Q.of(s.co[1])
	var x0: Q = s.x0
	var out := show(rep, s, {"answer": ans})
	var dropped := m.mul(x0.abs_q()).add(c)
	out.wrongs = [wrong({"v": dropped}, R_DROP_SIGN)]
	out.generic = opts([m.mul(x0), s.value.neg(), s.value.add(1), m.add(x0).add(c)])
	var mx := m.mul(x0)
	out.methods = ways({"bracket-first": ["Replace x with (%s): %s" % [N(x0), put_in(s)], "%s × %s = %s" % [Fmt.paren(m), Fmt.paren(x0), N(mx)], "%s = %s" % [sum_line([c, mx]), N(s.value)]]}, ans)
	return out


func u_coefficient_and_power(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := exact("number", {"v": s.value})
	var a := Q.of(s.co[0])
	var x0: Q = s.x0
	var out := show(rep, s, {"answer": ans})
	var wrongs: Array = [wrong({"v": a.mul(x0).sq()}, R_TIMES_FIRST)]
	if a.sign() < 0 or x0.sign() < 0:
		wrongs.append(wrong({"v": s.value.neg()}, R_SQUARE))
	out.wrongs = wrongs
	out.generic = opts([a.mul(x0).mul(2), a.mul(x0), s.value.neg(), s.value.add(a)])
	var sq := x0.sq()
	var bracket := "Replace x with (%s): %s" % [N(x0), put_in(s)]
	var square := "Square first: (%s)² = %s" % [N(x0), N(sq)]
	var times := "Then multiply: %s × %s = %s" % [Fmt.paren(a), N(sq), N(s.value)]
	out.methods = ways({"bracket-first": [bracket, square, times], "order-of-operations": [square, times]}, ans)
	return out


# ── Fractions ────────────────────────────────────────────────

func u_fraction_input(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := exact("number", {"v": s.value})
	var x0: Q = s.x0
	var out := show(rep, s, {"answer": ans})
	var work: Array
	var sign_step: String
	if s.has("co"):
		var ts := terms(s)
		out.generic = opts([s.value.add(1), s.value.neg(), s.value.add(ts[0]), SubstituteSituation.poly_at(s.co, x0.neg()), Q.new(1).div(s.value)])
		work = ["Replace x with (%s): %s" % [N(x0), put_in(s)], "Work each term out as a fraction: %s" % sum_line(ts), "Put it over one denominator: top %s, bottom %s" % [Fmt.num(Q.new(s.value.n)), Fmt.num(Q.new(s.value.d))]]
		sign_step = "Sign and size: the terms are %s, so about %s" % [sum_line(ts), Fmt.dec(Q.new(roundi(s.value.to_float() * 10.0), 10))]
	else:
		out.generic = opts([Q.new(1).div(s.value), s.value.neg(), s.t, s.b, s.value.add(1)])
		work = ["Top: %s = %s" % [put_top(s), N(s.t)], "Bottom: %s = %s" % [put_bottom(s), N(s.b)], "Divide: %s ÷ %s = %s" % [N(s.t), Fmt.paren(s.b), N(s.value)]]
		sign_step = "Sign and size: the top is %s and the bottom is %s, so the answer is %s" % [sign_word(s.t), sign_word(s.b), sign_word(s.value)]
	out.methods = ways({"top-and-bottom": work, "estimate-check": [sign_step, work[-1]]}, ans)
	return out


## A part of a fraction with the input written in: a lone x needs no brackets round a
## positive number, but 3x does: "3 + 2", "2 + 3(4)".
static func put_part(l: Dictionary, x0: Q) -> String:
	var text := SubstituteSituation.lin_text(l)
	if text.begins_with("x"):
		return Fmt.paren(x0) + text.substr(1)
	return text.replace("x", "(%s)" % N(x0))


static func put_top(s: Dictionary) -> String:
	return put_part(s.top, s.x0)


static func put_bottom(s: Dictionary) -> String:
	return put_part(s.bottom, s.x0)


func u_rational_expression(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := exact("number", {"v": s.value})
	var out := show(rep, s, {"answer": ans})
	out.wrongs = [wrong({"v": s.ltr_value}, R_LEFT_RIGHT)]
	out.generic = opts([Q.new(1).div(s.value), s.value.neg(), s.t, s.b, s.t.add(s.b)])
	var top := "Top: %s = %s" % [put_top(s), N(s.t)]
	var bottom := "Bottom: %s = %s" % [put_bottom(s), N(s.b)]
	var divide := "Divide: %s ÷ %s = %s" % [N(s.t), Fmt.paren(s.b), N(s.value)]
	out.methods = ways({"top-and-bottom": [top, bottom, divide],
		"estimate-check": ["Sign and size: the top is %s and the bottom is %s, so the answer is %s" % [sign_word(s.t), sign_word(s.b), sign_word(s.value)], top, bottom, divide]}, ans)
	out.spot = _spot(s, rng)
	return out


## A student's working that takes the top or the bottom left to right (catalogue error-spot).
## The first wrong line is that part's: the top comes second and the bottom third.
static func _spot(s: Dictionary, _rng: Seeded) -> Dictionary:
	var top_bad: bool = s.loose == "top"
	var l: Dictionary = s.top if top_bad else s.bottom
	var x0: Q = s.x0
	var mid := Q.new(l.c + l.m)
	var slip := "%s %s %s = %s, then %s × %s = %s" % [Fmt.num(l.c), "+" if l.m > 0 else "−", Fmt.num(absi(l.m)), N(mid), Fmt.paren(mid), Fmt.paren(x0), N(s.ltr)]
	var t: Q = s.ltr if top_bad else s.t
	var b: Q = s.b if top_bad else s.ltr
	return {"lines": ["Put x = %s in: top %s, bottom %s" % [N(x0), put_top(s), put_bottom(s)],
		"Top: %s" % (slip if top_bad else "%s = %s" % [put_top(s), N(s.t)]),
		"Bottom: %s" % ("%s = %s" % [put_bottom(s), N(s.b)] if top_bad else slip),
		"So the value is %s" % N(t.div(b))],
		"bad": 1 if top_bad else 2, "ref": R_LEFT_RIGHT,
		"why": "multiply before adding or subtracting: %s is %s, not %s" % [put_top(s) if top_bad else put_bottom(s), N(s.t if top_bad else s.b), N(s.ltr)]}


# ── Reversed ─────────────────────────────────────────────────

func u_missing_input(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := exact("xval", {"v": s.x0})
	var a := Q.of(s.co[0])
	var b := Q.of(s.co[1])
	var v: Q = s.value
	var out := {"answer": ans, "asked": "Find x."}
	if rep == "words":
		out.asked = "The expression %s has the value %s. Find x." % [s.text, N(v)]
	else:
		out.lines = ["%s = %s" % [s.text, N(v)]]
	out.generic = opts([v.add(b).div(a), v.div(a).sub(b), a.mul(v).add(b), s.x0.neg(), s.x0.add(1)])
	var last := "So %s." % Answer.text(ans)
	var check := "Check: %s = %s, the right size and sign" % [s.text.replace("x", "(%s)" % N(s.x0)), N(v)]
	var rest := v.sub(b)
	out.methods = BasicFunctionViews.ways({"estimate-check": ["A check can't find x by itself, so undo the steps first: %s" % LinearInequalityViews.take(b, "both sides"),
		"That leaves %s = %s, so divide by %s: x = %s" % [Fmt.term(a, 1, true), N(rest), N(a), N(s.x0)], check]}, last, ans)
	return out
