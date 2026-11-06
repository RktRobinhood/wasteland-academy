class_name LogLawsViews
extends ExtensionViews
## The views on the `log-laws` situation: one builder per unknown of t1-log-laws (FAL-751). Every
## answer is the `form` kind, so a wrong option in another shape can be picked but never typed: a
## number is one slot, a single log has its number typed, and an expression in p and q has its
## coefficients typed. The 3 s.f. value is the `number` kind, with the rounding trap.
##
## The one representation is "equation": the exam gives an expression and nothing needs a figure.
## Bases with a root or letters in them read "log base ab of", as Answer's logform does, since
## the font has no such subscripts. A log's argument is an atom or a bracket, never a bare fraction.
##
## Paper 1 only, as the bank is, except what needs a calculator: the two GDC checks, the log-base
## template, and the 3 s.f. value. A GDC check tries one value. It agrees or it doesn't, and the
## working says that's a check, and that the laws are the proof.
##
## Misconceptions are the two map strings with no numbers in them, then the type's own, which are
## "<type id>#<index>".

const OWN := "t1-log-laws#"
const R_SPLIT := "SL1.7.log-laws#0"
const R_QUOT := "SL1.7.log-laws#1"
const R_POWER_LOG := OWN + "2"
const R_INVERT := OWN + "3"
const R_SIMPLIFY := OWN + "4"
const R_BASE_ITSELF := OWN + "5"
const R_STOP := OWN + "6"
const R_DIV_LOGS := OWN + "7"
const R_MUL_LOGS := OWN + "8"
const R_TIMES_IN := OWN + "9"
const R_ROOT_TWO := OWN + "10"
const R_PLUS := OWN + "11"
const R_NO_MINUS := OWN + "12"
const R_NUM_BASE := OWN + "13"
const R_RECIPROCAL := OWN + "14"
const R_LOG_BASE := OWN + "15"
const R_TIMES_BASE := OWN + "16"
const R_AB_NEG := OWN + "17"
const R_SWAP := OWN + "18"
const R_ADD_IN := OWN + "19"
const R_SUB_IN := OWN + "20"
const R_NO_ROOT := OWN + "21"
const R_ROOT_BASE := OWN + "22"
const R_SCALE := OWN + "23"

const GDC_CHECK := "gdc-check"
const GDC_BASE := "gdc-logbase"
const COMBINE := "combine"
const SEPARATE := "evaluate-separately"
const EXPAND := "expand"
const FORMULA := "cob-formula"
const POWERS := "common-base-power"
const DEFINE := "define-and-log"
const UNKNOWNS := ["value-difference", "value-hidden", "value-quotient", "single-ln-k", "single-log-letters", "expand-letters",
	"expand-numbers", "show-number", "given-log-laws", "ab-base-value", "ab-base-hence", "evaluate-single", "log-of-root",
	"cob-common-base", "cob-in-p-q", "given-log-base", "base-power-letter", "value-3sf"]
const CHECK_NOTE := "They agree, which supports the answer. One value is a check, not a proof: the laws are the proof."
const SCREEN := 5


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## A 3 s.f. value needs a calculator, and a calculator method is Paper 2 (the engine sees to that).
func papers(unknown: String, _rep: String, _angle_id: String) -> Array:
	if not has(unknown):
		return []
	return [2] if unknown == "value-3sf" else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = LogLawsSituation.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

static func lg(L: String, arg: String) -> String:
	return L + arg if arg.begins_with("(") and not L.ends_with(" of") else L + " " + arg


## 243 as a power: "3⁵".
static func pw(b: Variant, e: int) -> String:
	return str(b) + Fmt.sup(e)


## 243 = 3⁵, so log₃ 243 = 5; the log of the base itself says so.
static func power_line(L: String, b: int, e: int) -> String:
	var n := LogLawsSituation.ipow(b, e)
	if e == 1:
		return "%s = 1, as it's the log of the base." % lg(L, str(b))
	return "%d = %s, so %s = %d." % [n, pw(b, e), lg(L, str(n)), e]


## b^e with a whole or fractional power: 2^6, 2^(2/3).
static func to_pow(b: int, e: Q) -> String:
	return "%d^%s" % [b, N(e)] if e.is_int() and e.sign() > 0 else "%d^(%s)" % [b, N(e)]


## A number as a coefficient before a log: 3, (1/2), −(1/2), nothing for 1.
static func co(v: Q) -> String:
	if v.eq(1):
		return ""
	if v.eq(-1):
		return "−"
	if v.is_int():
		return N(v)
	return ("−" if v.sign() < 0 else "") + "(%s)" % N(v.abs_q())


## c L x, for a known coefficient.
static func times(v: Q, tail: String) -> String:
	var c := co(v)
	return tail if c == "" else (c + " " + tail if c != "−" else "−" + tail)


## A term in p: 3p, p/2, 3p/2, for a positive size.
static func letter_term(v: Q, l: String) -> String:
	var a := v.abs_q()
	var top := "" if a.n == 1 else str(a.n)
	return top + l if a.d == 1 else "%s%s/%d" % [top, l, a.d]


## up + vq + k, skipping zero terms; the number comes first, as 1 − p + q.
static func pq_text(u: Q, v: Q, k: Q = Q.new(0), p: String = "p", q: String = "q") -> String:
	var bits: Array = []
	if not k.is_zero():
		bits.append([k.sign(), N(k.abs_q())])
	if not u.is_zero():
		bits.append([u.sign(), letter_term(u, p)])
	if not v.is_zero():
		bits.append([v.sign(), letter_term(v, q)])
	var out := ""
	for b in bits:
		if out == "":
			out = ("−" if b[0] < 0 else "") + b[1]
		else:
			out += (" − " if b[0] < 0 else " + ") + b[1]
	return out if out != "" else "0"


## pq_text with each whole multiple written as a power: 3p − 2q as p³ − q².
static func power_text(u: Q, v: Q, k: Q = Q.new(0)) -> String:
	var bits: Array = []
	if not k.is_zero():
		bits.append([k.sign(), N(k.abs_q())])
	for pair in [[u, "p"], [v, "q"]]:
		var c: Q = pair[0]
		if c.is_zero():
			continue
		var a := c.abs_q()
		bits.append([c.sign(), pair[1] + Fmt.sup(a.n) if a.d == 1 else letter_term(a, pair[1])])
	var out := ""
	for b in bits:
		if out == "":
			out = ("−" if b[0] < 0 else "") + b[1]
		else:
			out += (" − " if b[0] < 0 else " + ") + b[1]
	return out


## a p/q with a whole number or a fraction: 3p/q, 3p/(2q), p/(2q).
static func ratio_text(a: Q, top: String = "p", bottom: String = "q") -> String:
	var n := "" if a.n == 1 else str(a.n)
	return "%s%s/%s" % [n, top, bottom] if a.d == 1 else "%s%s/(%d%s)" % [n, top, a.d, bottom]


# ── Answers ──────────────────────────────────────────────────

## A number, exact, in one slot; head goes before it.
static func val_ans(v: Q, head: String = "") -> Dictionary:
	var parts: Array = [{"slot": "v"}]
	if head != "":
		parts.push_front(head)
	var ans := Answer.make("form", {"v": v, "text": head + N(v)}, {"parts": parts})
	ans.exact = true
	return ans


static func wv(v: Variant, ref: String = "", head: String = "") -> Dictionary:
	return wrong({"v": Q.of(v), "text": head + N(v)}, ref)


## Another shape: it can be picked and never typed.
static func walt(text: String, ref: String = "") -> Dictionary:
	return wrong({"text": text, "shape": "other"}, ref)


static func gv(vals: Array, head: String = "") -> Array:
	return vals.map(func(v): return {"v": Q.of(v), "text": head + N(v)})


## L k: only k is typed.
static func one_log(L: String, k: Q) -> Dictionary:
	var ans := Answer.make("form", {"k": k, "text": k_text(L, k)}, {"parts": [L + " ", {"slot": "k"}]})
	ans.exact = true
	return ans


static func k_text(L: String, k: Q) -> String:
	return lg(L, N(k) if k.is_int() else "(%s)" % N(k))


static func wk(L: String, k: Q, ref: String = "") -> Dictionary:
	return wrong({"k": k, "text": k_text(L, k)}, ref)


## up + vq (+ k), with its coefficients typed.
static func pq_ans(u: Q, v: Q, k: Q) -> Dictionary:
	var parts: Array = [{"slot": "u"}, "p + ", {"slot": "c"}, "q"]
	var values := {"u": u, "c": v, "text": pq_text(u, v, k)}
	if not k.is_zero():
		parts = [{"slot": "n"}, " + ", {"slot": "u"}, "p + ", {"slot": "c"}, "q"]
		values.n = k
	var ans := Answer.make("form", values, {"parts": parts})
	ans.exact = true
	return ans


static func pq_vals(u: Q, v: Q, k: Q) -> Dictionary:
	var values := {"u": u, "c": v, "text": pq_text(u, v, k)}
	if not k.is_zero():
		values.n = k
	return values


static func wpq(u: Q, v: Q, k: Q, ref: String = "") -> Dictionary:
	return wrong(pq_vals(u, v, k), ref)


## The filler options for an expression in p and q.
static func gpq(u: Q, v: Q, k: Q) -> Array:
	return [pq_vals(u.add(1), v, k), pq_vals(u, v.add(1), k), pq_vals(u.add(1), v.add(1), k), pq_vals(v, u, k), pq_vals(u.mul(2), v, k),
		pq_vals(u, v.mul(2), k)]


func _number(s: Dictionary, lines: Array, asked: String, w: Array, gen: Array, rng: Seeded, methods: Dictionary, ans: Dictionary) -> Dictionary:
	return {"lines": lines, "asked": asked, "answer": ans, "wrongs": rng.shuffled(w), "generic": gen, "methods": methods}


static func said(ans: Dictionary) -> String:
	return "So the value is %s." % Answer.text(ans)


## The values a number answer's fillers come from.
static func near(v: Q) -> Array:
	return [v.add(1), v.sub(1), v.add(2), v.mul(2), v.add(3), v.neg()].filter(func(x): return not x.eq(v))


# ── The laws ─────────────────────────────────────────────────

func u_value_difference(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: String = s.L
	var minus: bool = s.shape == "−"
	var ans := val_ans(s.val)
	var a := lg(L, str(s.m))
	var b := lg(L, str(s.n))
	var expr := "%s %s %s" % [a, s.shape, b]
	var inside: Q = Q.new(s.m, s.n) if minus else Q.new(s.m * s.n)
	var joined := "%s(%d/%d)" % [L, s.m, s.n] if minus else "%s(%d × %d)" % [L, s.m, s.n]
	var together: int = s.i - s.j if minus else s.i + s.j
	var w: Array = [wv(inside, R_STOP)]
	w.append(wv(Q.new(s.i, s.j), R_DIV_LOGS) if minus else wv(s.i * s.j, R_MUL_LOGS))
	var over: Q = Q.new(s.m, s.b).sub(Q.new(s.n, s.b)) if minus else Q.new(s.m, s.b).add(Q.new(s.n, s.b))
	w.append(wv(over, R_NUM_BASE))
	var m_combine := [expr + " = %s = %s." % [joined, lg(L, N(inside))],
		power_line(L, s.b, together), said(ans)]
	var m_each := [power_line(L, s.b, s.i), power_line(L, s.b, s.j),
		"%d %s %d = %d." % [s.i, s.shape, s.j, together], said(ans)]
	return _number(s, [expr], "Find the exact value.", w, gv(near(s.val)), rng,
		{COMBINE: method(m_combine, ans.values), SEPARATE: method(m_each, ans.values)}, ans)


func u_value_hidden(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: String = s.L
	var ans := val_ans(s.val)
	var a := lg(L, str(s.A))
	var b := lg(L, str(s.B))
	var p := LogLawsSituation.ipow(s.b, s.k)
	var pl := lg(L, str(p))
	var last := power_line(L, s.b, s.k)
	var expr: String
	var steps: Array
	var w: Array = []
	match s.shape:
		"sum":
			expr = "%s + %s" % [a, b]
			steps = [expr + " = %s(%d × %d) = %s." % [L, s.A, s.B, pl], last, said(ans)]
			w = [wv(p, R_STOP), walt(lg(L, str(s.A + s.B)), R_ADD_IN)]
		"diff":
			expr = "%s − %s" % [a, b]
			steps = [expr + " = %s(%d/%d) = %s." % [L, s.A, s.B, pl], last, said(ans)]
			w = [wv(p, R_STOP), walt(lg(L, str(s.A - s.B)), R_SUB_IN)]
		"coef":
			expr = "2 %s + %s" % [lg(L, str(s.c)), b]
			steps = ["2 %s = %s." % [lg(L, str(s.c)), a], "%s + %s = %s(%d × %d) = %s." % [a, b, L, s.A, s.B, pl], last, said(ans)]
			w = [wv(p, R_STOP), walt(lg(L, str(s.A + s.B)), R_ADD_IN)]
			if s.c != 2:
				w.append(walt(lg(L, str(2 * s.c * s.B)), R_TIMES_IN))
		"split":
			expr = "%s(%d + %d)" % [L, s.A, s.B]
			steps = ["There's no law for the log of a sum, so add first: %s = %s." % [expr, pl], last, said(ans)]
			w = [walt("%s + %s" % [a, b], R_SPLIT), wv(p, R_STOP)]
	return _number(s, [expr], "Find the exact value.", w, gv(near(s.val)), rng, {COMBINE: method(steps, ans.values)}, ans)


func u_value_quotient(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: String = s.L
	var ans := val_ans(s.val)
	var base := lg(L, str(s.p))
	var expr := "%s/%s" % [lg(L, str(s.m)), lg(L, str(s.n))]
	var steps := ["%d = %s, so %s = %d %s." % [s.m, pw(s.p, s.a), lg(L, str(s.m)), s.a, base],
		"%d = %s, so %s = %d %s." % [s.n, pw(s.p, s.e), lg(L, str(s.n)), s.e, base],
		"%s = %d %s/(%d %s) = %s, as %s cancels." % [expr, s.a, base, s.e, base, N(s.val), base], said(ans)]
	var inside := Q.new(s.m, s.n)
	var w: Array = [walt(k_text(L, inside), R_QUOT), wv(Q.new(s.e, s.a), R_INVERT)]
	return _number(s, [expr], "Find the exact value.", w, gv([Q.new(s.a + 1, s.e), Q.new(s.a, s.e + 1), s.val.add(1), s.val.add(2)]), rng,
		{EXPAND: method(steps, ans.values)}, ans)


func u_single_ln_k(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: String = s.L
	var k := Q.new(s.k)
	var ans := one_log(L, k)
	var u := lg(L, str(s.u))
	var v := lg(L, str(s.v))
	var done := "So the expression is %s." % Answer.text(ans)
	var expr: String
	var steps: Array
	var w: Array = []
	match s.shape:
		"sum":
			expr = "%s + %s" % [u, v]
			steps = [expr + " = %s(%d × %d) = %s." % [L, s.u, s.v, lg(L, str(s.k))], done]
			w = [wk(L, Q.new(s.u + s.v), R_ADD_IN)]
		"power":
			expr = "%d %s" % [s.c, u]
			steps = ["%s = %s." % [expr, lg(L, pw(s.u, s.c))], "%s = %d, so %s = %s." % [pw(s.u, s.c), s.k, expr, lg(L, str(s.k))], done]
			w = [wk(L, Q.new(s.c * s.u), R_TIMES_IN)]
			if s.c != s.u and LogLawsSituation.ipow(s.c, s.u) != s.k:
				w.append(wk(L, Q.new(LogLawsSituation.ipow(s.c, s.u)), R_SWAP))
		"neg":
			expr = "−%s(1/%d)" % [L, s.u]
			steps = ["%s = (−1) %s(1/%d) = %s((1/%d)^(−1)) = %s." % [expr, L, s.u, L, s.u, lg(L, str(s.k))], done]
			w = [wk(L, Q.new(1, s.u), R_NO_MINUS)]
		"diff":
			expr = "%s − %s" % [u, v]
			steps = [expr + " = %s(%d/%d) = %s." % [L, s.u, s.v, lg(L, str(s.k))], done]
			w = [wk(L, Q.new(s.u - s.v), R_SUB_IN), wk(L, Q.new(s.u * s.v), R_PLUS)]
		"root":
			expr = "(1/%d) %s" % [s.c, u]
			var r := "√" if s.c == 2 else "the cube root of "
			steps = ["%s = %s, as %s%d is %d." % [expr, lg(L, str(s.k)), r, s.u, s.k], done]
			steps.push_front("%s = %s^(1/%d)." % [expr, lg(L, str(s.u)), s.c])
			w = [wk(L, Q.new(s.u, s.c), R_TIMES_IN), wk(L, Q.new(s.u), R_NO_ROOT)]
		"mix":
			expr = "%d %s + %s" % [s.c, u, v]
			steps = ["%d %s = %s." % [s.c, u, lg(L, str(LogLawsSituation.ipow(s.u, s.c)))],
				"%s + %s = %s(%d × %d) = %s." % [lg(L, str(LogLawsSituation.ipow(s.u, s.c))), v, L, LogLawsSituation.ipow(s.u, s.c), s.v, lg(L, str(s.k))], done]
			w = [wk(L, Q.new(s.c * s.u * s.v), R_TIMES_IN), wk(L, Q.new(LogLawsSituation.ipow(s.u, s.c) + s.v), R_ADD_IN)]
	var gen: Array = [k.add(1), k.add(2), k.sub(1), k.mul(2), k.add(3)].filter(func(x): return x.sign() > 0).map(func(x): return {"k": x, "text": k_text(L, x)})
	return {"lines": [expr], "asked": "Write this as %s k, where k is a positive whole number." % L, "answer": ans, "wrongs": rng.shuffled(w), "generic": gen,
		"methods": {COMBINE: method(steps, ans.values)}}


## 5x²/2 or 3x²/y³ or 3√x/y, for a coefficient and the rest. top is the part over nothing.
static func mono(c: Q, top: String, under: String) -> String:
	var head := "" if c.n == 1 else str(c.n)
	var bottom := ("" if c.d == 1 else str(c.d)) + under
	if bottom == "":
		return head + top
	return "%s%s/%s" % [head, top, bottom if c.d == 1 or under == "" else "(%s)" % bottom]


static func letters_ans(L: String, c: Q, top: String, under: String) -> Dictionary:
	var tail := top if under == "" else "%s/%s" % [top, under]
	var text := "%s(%s)" % [L, mono(c, top, under)]
	var ans := Answer.make("form", {"c": c, "text": text}, {"parts": [L + "(", {"slot": "c"}, " " + tail + ")"]})
	ans.exact = true
	return ans


## What the GDC shows for a log at x and y, for the check.
func _screen(v: float) -> String:
	return Fmt.work(GdcKit.qf(v), SCREEN)


func u_single_log_letters(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: String = s.L
	var c: int = s.c
	var d: int = s.d
	var m: int = s.m
	var n: int = s.n
	var lx := lg(L, "x")
	var ly := lg(L, "y")
	var xp := "x" + Fmt.sup(c)
	var yp := "y" + Fmt.sup(d)
	var expr: String
	var top: String
	var under := ""
	var law: String
	var w: Array = []
	var value: float
	var cx: float = s.cx
	var cy: float = s.cy
	var b: int = s.b
	match s.shape:
		"one":
			expr = "%d %s + %s − %s" % [c, lx, lg(L, str(m)), lg(L, str(n))]
			top = xp
			law = "%d %s = %s." % [c, lx, lg(L, xp)]
			w = [wrong({"c": Q.new(m * n), "text": "%s(%s)" % [L, mono(Q.new(m * n), top, under)]}, R_PLUS), walt("%s(%s)" % [L, mono(s.co.mul(c), "x", "")], R_TIMES_IN),
				walt("%s(%s + %d − %d)" % [L, xp, m, n], R_ADD_IN), walt("(%s)%s + %s" % [lx, Fmt.sup(c), k_text(L, s.co)], R_POWER_LOG)]
			value = c * LogLawsSituation.lg(b, cx) + LogLawsSituation.lg(b, m) - LogLawsSituation.lg(b, n)
		"two":
			expr = "%d %s − %s + %s" % [c, lx, times(Q.new(d), ly), lg(L, str(m))]
			top = xp
			under = yp
			law = "%d %s = %s, and %s = %s." % [c, lx, lg(L, xp), times(Q.new(d), ly), lg(L, yp)] if d > 1 else "%d %s = %s." % [c, lx, lg(L, xp)]
			w = [walt("%s(%d%s%s)" % [L, m, xp, yp], R_PLUS), walt("%s(%s)" % [L, mono(Q.new(m * c, d), "x", "y")], R_TIMES_IN),
				walt("%s(%s − %s + %d)" % [L, xp, yp, m], R_ADD_IN), walt("(%s)%s − %s + %s" % [lx, Fmt.sup(c), ("(%s)%s" % [ly, Fmt.sup(d)]) if d > 1 else ly, lg(L, str(m))], R_POWER_LOG)]
			value = c * LogLawsSituation.lg(b, cx) - d * LogLawsSituation.lg(b, cy) + LogLawsSituation.lg(b, m)
		"root":
			expr = "%s + (1/2) %s − %s" % [lg(L, str(m)), lx, times(Q.new(d), ly)]
			top = "√x"
			under = yp
			law = "(1/2) %s = %s √x%s." % [lx, L, ", and %s = %s" % [times(Q.new(d), ly), lg(L, yp)] if d > 1 else ""]
			w = [walt("%s(%d%s√x)" % [L, m, yp], R_PLUS), walt("%s(%s)" % [L, mono(Q.new(m), "x²", yp)], R_ROOT_TWO),
				walt("%s(%s)" % [L, mono(Q.new(m, 2 * d), "x", "y")], R_TIMES_IN), walt("%s(%d + √x − %s)" % [L, m, yp], R_ADD_IN)]
			value = LogLawsSituation.lg(b, m) + 0.5 * LogLawsSituation.lg(b, cx) - d * LogLawsSituation.lg(b, cy)
	var ans := letters_ans(L, s.co, top, under)
	var single := Answer.text(ans)
	var steps := [law, "Plus signs multiply inside the log and minus signs divide: %s." % single]
	var gen: Array = [s.co.add(1), s.co.add(2), s.co.mul(3), s.co.add(3)].map(func(q): return {"c": q, "text": "%s(%s)" % [L, mono(q, top, under)]})
	var at := "x = %d" % s.cx if s.shape == "one" else "x = %d and y = %d" % [s.cx, s.cy]
	var check_steps := [steps[0], steps[1], "With %s, both forms show %s on the GDC." % [at, _screen(value)], CHECK_NOTE, "So the single log is %s." % single]
	return {"lines": [expr], "asked": "Write this as a single logarithm.", "answer": ans, "wrongs": rng.shuffled(w), "generic": gen,
		"methods": {COMBINE: method(steps + ["So the single log is %s." % single], ans.values), GDC_CHECK: method(check_steps, ans.values)}}


## The argument of expand-letters as the question shows it, and its factors: [coefficient, what].
static func arg_of(s: Dictionary) -> String:
	var xp := "x" + Fmt.sup(s.i)
	var yp := "y" + Fmt.sup(s.j)
	match s.shape:
		"mul":
			return xp + yp
		"div":
			return "%s/%s" % [xp, yp]
		"mulroot":
			return xp + "√y"
		"divroot":
			return "%s/√y" % xp
		"rootdiv":
			return "√x/%s" % yp
		"rootall":
			return "√(x%s)" % yp
	return "%d%s/%s" % [s.b, xp, yp]


func u_expand_letters(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: String = s.L
	var u: Q = s.u
	var v: Q = s.v
	var k := Q.new(s.k)
	var ans := pq_ans(u, v, k)
	var arg := arg_of(s)
	var whole := lg(L, arg) if s.shape == "rootall" else "%s(%s)" % [L, arg]
	var lx := lg(L, "x")
	var ly := lg(L, "y")
	var parts := times(u, lx)
	parts += (" + " if v.sign() > 0 else " − ") + times(v.abs_q(), ly)
	if s.k > 0:
		parts = "%s %s" % [lg(L, str(s.b)), "+ " + parts]
	var steps := ["%s = %s." % [whole, parts]]
	if s.k > 0:
		steps.append("%s = 1, as it's the log of the base." % lg(L, str(s.b)))
	steps.append("Put in p for %s and q for %s: %s." % [lx, ly, pq_text(u, v, k)])
	steps.append("So %s = %s." % [whole, pq_text(u, v, k)])
	var w: Array = [wpq(u, v.neg(), k, R_PLUS)]
	if s.shape == "rootall":
		w.append(wpq(u.mul(4), v.mul(4), k, R_ROOT_TWO))
	elif not v.is_int():
		w.append(wpq(u, v.mul(4), k, R_ROOT_TWO))
	elif not u.is_int():
		w.append(wpq(u.mul(4), v, k, R_ROOT_TWO))
	if (u.is_int() and u.n > 1) or (v.is_int() and v.abs_q().n > 1):
		w.append(walt(power_text(u, v, k), R_POWER_LOG))
	if s.shape == "mul":
		w.append(walt("%spq" % ("" if s.i * s.j == 1 else str(s.i * s.j)), R_MUL_LOGS))
	if s.k > 0:
		w.append(walt(pq_text(u, v), R_LOG_BASE))
	var at := "x = %d and y = %d" % [s.cx, s.cy]
	var value := u.to_float() * LogLawsSituation.lg(s.b, s.cx) + v.to_float() * LogLawsSituation.lg(s.b, s.cy) + float(s.k)
	var check_steps := [steps[0], "With %s, both forms show %s on the GDC." % [at, _screen(value)], CHECK_NOTE, steps[-1]]
	return {"lines": ["Let p = %s and q = %s, where x, y > 0." % [lx, ly]], "asked": "Express %s in terms of p and q." % whole, "answer": ans,
		"wrongs": rng.shuffled(w), "generic": gpq(u, v, k), "methods": {EXPAND: method(steps, ans.values), GDC_CHECK: method(check_steps, ans.values)}}


func u_expand_numbers(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: String = s.L
	var u: Q = s.u
	var v: Q = s.v
	var k := Q.new(s.k)
	var ans := pq_ans(u, v, k)
	var p1 := lg(L, str(s.p1))
	var p2 := lg(L, str(s.p2))
	var arg: String
	var factors: String
	match s.shape:
		"mul":
			arg = str(s.N)
			factors = "%d = %s × %s." % [s.N, pw(s.p1, s.i), pw(s.p2, s.j)]
		"div":
			arg = "(%d/%d)" % [LogLawsSituation.ipow(s.p1, s.i), LogLawsSituation.ipow(s.p2, s.j)]
			var says: Array = []
			for pair in [[s.p1, s.i], [s.p2, s.j]]:
				if pair[1] > 1:
					says.append("%d = %s" % [LogLawsSituation.ipow(pair[0], pair[1]), pw(pair[0], pair[1])])
			factors = " and ".join(says) + "." if not says.is_empty() else ""
		"root":
			arg = "√%d" % s.N
			factors = "√%d = %d^(1/2), and %d = %s × %s." % [s.N, s.N, s.N, pw(s.p1, s.i), pw(s.p2, s.j)]
		"ten":
			arg = str(s.N)
			if s.i < 0:
				factors = "%d = 10%s/2." % [s.N, " × " + pw(3, s.j) if s.j > 0 else ""]
			else:
				var fs: Array = ["10"]
				if s.i > 0:
					fs.append(pw(2, s.i))
				if s.j > 0:
					fs.append(pw(3, s.j))
				factors = "%d = %s." % [s.N, " × ".join(fs)]
	var whole := lg(L, arg)
	var out := pq_text(u, v, k)
	var expanded := ""
	if not k.is_zero():
		expanded = lg(L, "10")
	if not u.is_zero():
		expanded += (" " if expanded != "" else "") + ("" if expanded == "" else ("+ " if u.sign() > 0 else "− ")) + (times(u if expanded == "" else u.abs_q(), p1))
	if not v.is_zero():
		expanded += (" + " if v.sign() > 0 else " − ") + times(v.abs_q(), p2)
	var steps := [factors, "%s = %s." % [whole, expanded]]
	if factors == "":
		steps.pop_front()
	if s.k > 0:
		steps.append("%s = 1, so this is %s." % [lg(L, "10"), out])
	steps.append("So %s = %s." % [whole, out])
	var w: Array = []
	if s.shape == "root":
		w.append(wpq(u.mul(4), v.mul(4), k, R_ROOT_TWO))
	if s.shape == "div":
		w.append(wpq(u, v.neg(), k, R_PLUS))
	if s.k > 0:
		w.append(walt(pq_text(u, v), R_LOG_BASE))
	if s.shape in ["mul", "div"] and (s.i > 1 or s.j > 1):
		w.append(walt(power_text(u, v), R_POWER_LOG))
	if s.shape == "mul":
		w.append(walt("%dpq" % (s.i * s.j) if s.i * s.j > 1 else "pq", R_MUL_LOGS))
	return {"lines": ["Let %s = p and %s = q." % [p1, p2]], "asked": "Express %s in terms of p and q." % whole, "answer": ans, "wrongs": rng.shuffled(w),
		"generic": gpq(u, v, k), "methods": {EXPAND: method(steps, ans.values)}}


func u_show_number(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: String = s.L
	var c := lg(L, str(s.c))
	var top := lg(L, str(s.top))
	var low := lg(L, str(s.low))
	var sign := "−" if s.shape == "diff" else "+"
	var expr := "%s %s %s" % [top, sign, low]
	var ans := val_ans(s.val, "k = ")
	var num := LogLawsSituation.ipow(s.c, s.k)
	var state := "This shows it, with k = %d." % s.k
	var joined := "%s(%d/%d)" % [L, s.top, s.low] if s.shape == "diff" else "%s(%d × %d)" % [L, s.top, s.low]
	var m1 := ["%s = %s = %s." % [expr, joined, lg(L, str(num))], "%d = %s, so %s = %d %s." % [num, pw(s.c, s.k), lg(L, str(num)), s.k, c], state]
	var m2: Array
	if s.shape == "diff":
		m2 = ["%d = %d × %s, so %s = %s + %d %s." % [s.top, s.low, pw(s.c, s.k), top, low, s.k, c], "%s − %s = %d %s." % [top, low, s.k, c], state]
	else:
		m2 = []
		for pair in [[s.top, s.i, top], [s.low, s.k - s.i, low]]:
			if pair[1] > 1:
				m2.append("%d = %s, so %s = %d %s." % [pair[0], pw(s.c, pair[1]), pair[2], pair[1], c])
		var left := times(Q.new(s.i), c)
		var right := times(Q.new(s.k - s.i), c)
		m2.append_array(["%s + %s = %s + %s = %d %s." % [top, low, left, right, s.k, c], state])
	var w: Array = [wv(num, R_STOP, "k = "), wv(Q.new(num, s.c), R_NUM_BASE, "k = ")]
	return _number(s, ["%s = k %s" % [expr, c]], "Show that this holds for a whole number k, and state k.", w, gv(near(s.val).filter(func(x): return x.sign() > 0), "k = "), rng,
		{COMBINE: method(m1, ans.values), EXPAND: method(m2, ans.values)}, ans)


func u_given_log_laws(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: String = s.L
	var m: Q = s.m
	var r: int = s.r
	var ans := val_ans(s.val)
	var la := lg(L, "a")
	var b: int = s.base
	var arg: String
	var law: String
	var w: Array = []
	var lb := lg(L, str(b))
	match s.shape:
		"recip":
			arg = "(1/a)"
			law = "%s = %s 1 − %s = 0 − %s." % [lg(L, arg), L, la, la]
			w = [wv(Q.new(1).div(m), R_RECIPROCAL), wv(m, R_NO_MINUS)]
		"pow":
			arg = "a" + Fmt.sup(r)
			law = "%s = %d %s." % [lg(L, arg), r, la]
			w = [wv(m.mul(m) if r == 2 else m.mul(m).mul(m), R_POWER_LOG)]
		"root":
			arg = "√a" if r == 2 else "a^(1/3)"
			law = "%s = (1/%d) %s." % [lg(L, arg), r, la]
			w = [wv(m.mul(r), R_ROOT_TWO)]
		"scale":
			arg = "(%da)" % b
			law = "%s = %s + %s = 1 + %s." % [lg(L, arg), lb, la, la]
			w = [wv(m, R_LOG_BASE), wv(m.mul(b), R_SCALE)]
		"over":
			arg = "(%d/a)" % b
			law = "%s = %s − %s = 1 − %s." % [lg(L, arg), lb, la, la]
			w = [wv(m.neg(), R_LOG_BASE), wv(m.add(1), R_PLUS)]
		"scalepow":
			arg = "(a%s/%d)" % [Fmt.sup(r), b]
			law = "%s = %d %s − %s = %d %s − 1." % [lg(L, arg), r, la, lb, r, la]
			w = [wv(m.mul(r), R_LOG_BASE), wv(m.mul(r).add(1), R_PLUS)]
	var steps := [law, "Put in %s = %s: the value is %s." % [la, N(m), N(s.val)], said(ans)]
	return _number(s, ["It is given that %s = %s, where a > 0." % [la, N(m)]], "Find the value of %s." % lg(L, arg), w, gv(near(s.val)), rng,
		{EXPAND: method(steps, ans.values)}, ans)


static func ab_log(s: Dictionary, arg: String) -> String:
	return "log base %s%s of %s" % [s.l1, s.l2, arg]


func u_ab_base_value(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var l1: String = s.l1
	var l2: String = s.l2
	var ab := l1 + l2
	var m: Q = s.m
	var ans := val_ans(s.val)
	var la := ab_log(s, l1)
	var lb := ab_log(s, l2)
	var steps := ["%s = 1, as %s is the base." % [ab_log(s, ab), ab], "%s = %s + %s, as %s is %s × %s." % [ab_log(s, ab), la, lb, ab, l1, l2],
		"So %s + %s = 1, which gives %s = 1 − %s = %s." % [la, lb, lb, N(m), N(s.val)], said(ans)]
	if m.sign() < 0:
		steps[2] = "So %s + %s = 1, which gives %s = 1 − (%s) = %s." % [la, lb, lb, N(m), N(s.val)]
	var w: Array = [wv(m.neg(), R_AB_NEG), wv(m.add(1), R_PLUS)]
	return _number(s, ["It is given that %s = %s, where %s, %s > 0 and %s ≠ 1." % [la, N(m), l1, l2, ab]], "Find the value of %s." % lb, w, gv(near(s.val) + [Q.new(1).div(m), m.sub(1)]), rng,
		{EXPAND: method(steps, ans.values)}, ans)


func u_ab_base_hence(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var l1: String = s.l1
	var l2: String = s.l2
	var ab := l1 + l2
	var m: Q = s.m
	var mb: Q = s.mb
	var e1: Q = s.e1
	var e2: Q = s.e2
	var ans := val_ans(s.val)
	var la := ab_log(s, l1)
	var lb := ab_log(s, l2)
	var ptext := func(l: String, e: Q) -> String: return l + ("^(%s)" % N(e) if not e.is_int() else Fmt.sup(e.n))
	var arg: String = "(%s/%s)" % [ptext.call(l1, e1), ptext.call(l2, e2)]
	var whole := ab_log(s, arg)
	var steps := ["%s + %s = %s = 1, so %s = %s." % [la, lb, ab_log(s, ab), lb, N(mb)],
		"%s = %s − %s." % [whole, times(e1, la), times(e2, lb)],
		"= %s × %s − %s × %s = %s." % [N(e1), P(m), N(e2), P(mb), N(s.val)], said(ans)]
	var w: Array = [wv(e2.mul(m).sub(e1.mul(mb)), R_SWAP), wv(e1.mul(m).add(e2.mul(mb)), R_PLUS), wv(e1.mul(m).add(e2.mul(m)), R_AB_NEG)]
	return _number(s, ["It is given that %s = %s, where %s, %s > 0 and %s ≠ 1." % [la, N(m), l1, l2, ab]], "Find the value of %s." % whole, w, gv(near(s.val)), rng,
		{EXPAND: method(steps, ans.values)}, ans)


# ── Change of base ───────────────────────────────────────────

func u_evaluate_single(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: String = s.L
	var p: int = s.p
	var t: int = s.t
	var e: int = s.e
	var num := LogLawsSituation.ipow(p, t)
	var ans := val_ans(s.val)
	var y := N(s.val)
	var arg := "(1/%d)" % num if s.shape == "recip" else str(num)
	var expr := lg(L, arg)
	var w: Array = []
	var m_power: Array
	var m_define: Array
	var m_formula: Array
	match s.shape:
		"whole":
			m_power = ["%d = %s, so the power of %d that gives %d is %d." % [num, pw(p, t), p, num, t], said(ans)]
			m_define = ["Let y = %s, so %d^y = %d." % [expr, p, num], "Take logs: y log %d = log %d = %d log %d." % [p, num, t, p], "So y = %d." % t, said(ans)]
			m_formula = ["%s = log %d/log %d." % [expr, num, p], "= %d log %d/log %d = %d." % [t, p, p, t], said(ans)]
			w = [wv(Q.new(1, t), R_INVERT), wv(Q.new(num, p), R_NUM_BASE)]
		"recip":
			m_power = ["1/%d = %s^(−%d), so the power is −%d." % [num, p, t, t], said(ans)]
			m_define = ["Let y = %s, so %d^y = 1/%d." % [expr, p, num], "Take logs: y log %d = −log %d = −%d log %d." % [p, num, t, p], "So y = −%d." % t, said(ans)]
			m_formula = ["%s = log(1/%d)/log %d." % [expr, num, p], "= −%d log %d/log %d = −%d." % [t, p, p, t], said(ans)]
			w = [wv(t, R_NO_MINUS), wv(Q.new(-1, t), R_INVERT), wv(Q.new(1, num), R_STOP)]
		"frac":
			var big: int = s.b
			m_power = ["%d = %s and %d = %s." % [big, pw(p, e), num, pw(p, t)], "So %d^y = %d means %d^(%dy) = %s, and %dy = %d." % [big, num, p, e, pw(p, t), e, t],
				"y = %s." % y, said(ans)]
			m_define = ["Let y = %s, so %d^y = %d." % [expr, big, num], "Take logs: y log %d = log %d, so %dy log %d = %d log %d." % [big, num, e, p, t, p],
				"y = %s." % y, said(ans)]
			m_formula = ["%s = log %d/log %d." % [expr, num, big], "= %d log %d/(%d log %d) = %s, as log %d cancels." % [t, p, e, p, y, p], said(ans)]
			w = [wv(Q.new(e, t), R_INVERT), wv(Q.new(num, big), R_NUM_BASE), wv(Q.new(t * e), R_TIMES_BASE)]
		"surd":
			m_power = ["√%d = %d^(1/2) and %d = %s." % [p, p, num, pw(p, t)], "So (√%d)^y = %d means %d^(y/2) = %s, and y/2 = %d." % [p, num, p, pw(p, t), t], "y = %d." % (2 * t), said(ans)]
			m_define = ["Let y = %s, so (√%d)^y = %d." % [expr, p, num], "Take logs: y log √%d = log %d, so (y/2) log %d = %d log %d." % [p, num, p, t, p], "y = %d." % (2 * t), said(ans)]
			m_formula = ["%s = log %d/log √%d." % [expr, num, p], "= %d log %d/((1/2) log %d) = %d." % [t, p, p, 2 * t], said(ans)]
			w = [wv(t, R_ROOT_BASE), wv(Q.new(1, 2 * t), R_INVERT)]
	return _number(s, [expr], "Find the exact value.", w, gv(near(s.val)), rng,
		{POWERS: method(m_power, ans.values), DEFINE: method(m_define, ans.values), FORMULA: method(m_formula, ans.values)}, ans)


func u_log_of_root(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var B: int = s.base
	var p: int = s.p
	var e: int = s.e
	var t: int = s.t
	var n: int = s.n
	var root_text := "√%d" % n if s.root == 2 else "%d^(1/3)" % n
	var ans := val_ans(s.val)
	var y := N(s.val)
	var expr := lg(s.L, root_text)
	var lines: Array = [expr]
	var asked := "Find the exact value."
	var lead: Array = []
	if s.shape == "function":
		lines = ["f(x) = %d^x" % B]
		asked = "Find the value of f⁻¹(%s)." % root_text
		lead = ["The inverse of %d^x is f⁻¹(x) = %s." % [B, lg(s.L, "x")]]
	var whole := Q.new(t, s.root)
	var m_power := lead + ["%d = %s and %s = %s^(%s)." % [B, pw(p, e), root_text, p, N(whole)], "So %d^y = %s means %dy = %s." % [B, root_text, e, N(whole)], "y = %s." % y, said(ans)]
	var m_define := lead + ["Let y = %s, so %d^y = %s." % [expr, B, root_text], "Take logs: y log %d = (%s) log %d, so %dy log %d = (%s) log %d." % [B, N(whole), p, e, p, N(whole), p], "y = %s." % y, said(ans)]
	var w: Array = [wv(Q.new(t, e), R_NO_ROOT), wv(Q.new(s.root * t, e), R_ROOT_TWO), wv(Q.new(s.root * e, t), R_INVERT)]
	return _number(s, lines, asked, w, gv(near(s.val)), rng, {POWERS: method(m_power, ans.values), DEFINE: method(m_define, ans.values)}, ans)


func u_cob_common_base(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var H: String = s.L
	var c: int = s.c
	var d: int = s.d
	var k: int = s.k
	var N_: int = s.N
	var LC := LogLawsSituation.log_of(c)
	var ld := lg(H, str(d))
	var lc := lg(H, str(c))
	var whole := lg(LC, str(N_))
	var text := "%d %s/%s" % [k, ld, lc]
	var ans := Answer.make("form", {"k": Q.new(k), "text": text}, {"parts": [{"slot": "k"}, " %s/%s" % [ld, lc]]})
	ans.exact = true
	var m1 := ["%s = %s/%s, by the change of base formula." % [whole, lg(H, str(N_)), lc], "%d = %s, so %s = %d %s." % [N_, pw(d, k), lg(H, str(N_)), k, ld], "So %s = %s." % [whole, text]]
	var m2 := ["Let y = %s, so %d^y = %d." % [whole, c, N_], "Take %s of both sides: y %s = %s = %d %s." % [H, lc, lg(H, str(N_)), k, ld], "So y = %s." % text]
	var w: Array = [walt("%s/(%d %s)" % [lc, k, ld], R_INVERT), walt("%s(%d/%d)" % [H, N_, c], R_SIMPLIFY),
		walt("(%s)%s/%s" % [ld, Fmt.sup(k), lc], R_POWER_LOG)]
	var gen: Array = [k + 1, k + 2, k + 3].map(func(x): return {"k": Q.new(x), "text": "%d %s/%s" % [x, ld, lc]})
	return {"lines": [whole], "asked": "Express this in terms of %s and %s." % [ld, lc], "answer": ans, "wrongs": rng.shuffled(w), "generic": gen,
		"methods": {FORMULA: method(m1, ans.values), DEFINE: method(m2, ans.values)}}


func u_cob_in_p_q(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var H: String = s.L
	var co_: Q = s.co
	var j: int = s.j
	var k: int = s.k
	var c: int = s.c
	var d: int = s.d
	var base: int = s.base
	var LB := LogLawsSituation.log_of(base)
	var whole := lg(LB, str(s.N))
	var lc := lg(H, str(c))
	var ld := lg(H, str(d))
	var tail := "" if j == 0 else " + %d" % j
	var text := ratio_text(co_) + tail
	var parts: Array = [{"slot": "a"}, "p/q"]
	var values := {"a": co_, "text": text}
	if j > 0:
		parts.append_array([" + ", {"slot": "e"}])
		values.e = Q.new(j)
	var ans := Answer.make("form", values, {"parts": parts})
	ans.exact = true
	var over := lg(H, str(base))
	var top := "%d %s" % [k, lc] if j == 0 else "%d %s + %s" % [k, lc, times(Q.new(j), ld)]
	var top_p := "%dp" % k if j == 0 else "%dp + %s" % [k, letter_term(Q.new(j), "q")]
	var bottom_q := "2q" if base != d else "q"
	var bottom := "%s = 2 %s = 2q" % [over, ld] if base != d else "%s = q" % over
	var under := bottom_q if base == d else "(%s)" % bottom_q
	var quotient := "%s/%s" % [top_p, under] if j == 0 else "(%s)/%s" % [top_p, under]
	var m1 := ["%s = %s/%s." % [whole, lg(H, str(s.N)), over], "%s = %s = %s, and %s." % [lg(H, str(s.N)), top, top_p, bottom], "So %s = %s = %s." % [whole, quotient, text]]
	if quotient == text:
		m1[2] = "So %s = %s." % [whole, text]
	var m2 := ["Let y = %s, so %d^y = %d." % [whole, base, s.N], "Take %s of both sides: y %s = %s." % [H, over, lg(H, str(s.N))], "That is %s × y = %s." % [bottom_q, top_p], "So y = %s." % text]
	var w: Array = [walt("%s/(%s)" % [bottom_q, top_p], R_INVERT)]
	if j == 0:
		w.append(walt("%s − %s" % [top_p, bottom_q], R_SIMPLIFY))
		w.append(walt("p%s/%s" % [Fmt.sup(k), bottom_q if base == d else "(%s)" % bottom_q], R_POWER_LOG))
	else:
		w.append(walt(pq_text(Q.new(k), Q.new(j - 1)), R_SIMPLIFY))
		w.append(walt(ratio_text(co_), R_LOG_BASE))
	var gen: Array = []
	for g in [co_.add(1), co_.add(2), co_.mul(2), co_.add(3)]:
		var v := {"a": g, "text": ratio_text(g) + tail}
		if j > 0:
			v.e = Q.new(j)
		gen.append(v)
	return {"lines": ["Let %s = p and %s = q." % [lc, ld]], "asked": "Find an expression for %s in terms of p and q." % whole, "answer": ans,
		"wrongs": rng.shuffled(w), "generic": gen, "methods": {FORMULA: method(m1, ans.values), DEFINE: method(m2, ans.values)}}


func u_given_log_base(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: String = s.L
	var big: int = s.big
	var B: int = s.base
	var k: int = s.k
	var r: int = s.r
	var m: Q = s.m
	var ans := val_ans(s.val)
	var arg := "a" + Fmt.sup(r)
	var whole := lg(s.big_L, arg)
	var top := m.mul(r)
	var given := lg(L, "a")
	var ltop := lg(L, arg)
	var step0 := "%s = %d × %s = %s." % [ltop, r, N(m) if m.sign() > 0 else P(m), N(top)] if r > 1 else ""
	var rhs := "%s = %s" % [ltop, N(top)]
	var m1 := ["%s = %s/%s." % [whole, ltop, lg(L, str(big))], "%s = %d, as %d = %s." % [lg(L, str(big)), k, big, pw(B, k)], "%s/%d = %s." % [N(top) if top.is_int() else "(%s)" % N(top), k, N(s.val)], said(ans)]
	var m2 := ["%s means %s = %s." % [rhs, arg, to_pow(B, top)], "%d = %d^(1/%d), so %s = %s." % [B, big, k, arg, to_pow(big, s.val)],
		"The power of %d is %s." % [big, N(s.val)], said(ans)]
	var m3 := ["Let y = %s, so %d^y = %s." % [whole, big, arg], "Take %s of both sides: y %s = %s." % [L, lg(L, str(big)), ltop], "%dy = %s, so y = %s." % [k, N(top), N(s.val)], said(ans)]
	if r > 1:
		for mm in [m1, m2, m3]:
			mm.push_front(step0)
	var w: Array = [wv(top.mul(k), R_TIMES_BASE), wv(top.div(big), R_BASE_ITSELF), wv(Q.new(k).div(top), R_INVERT)]
	return _number(s, ["It is given that %s = %s, where a > 0." % [given, N(m)]], "Find the value of %s." % whole, w, gv(near(s.val)), rng,
		{FORMULA: method(m1, ans.values), POWERS: method(m2, ans.values), DEFINE: method(m3, ans.values)}, ans)


func u_base_power_letter(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var L: String = s.L
	var big: int = s.big
	var B: int = s.base
	var k: int = s.k
	var r: int = s.r
	var c: Q = s.val
	var arg := "x" + Fmt.sup(r)
	var whole := lg(s.big_L, arg)
	var lx := lg(L, "x")
	var text := times(c, lx)
	var ans := Answer.make("form", {"c": c, "text": text}, {"parts": [{"slot": "c"}, " " + lx]})
	ans.exact = true
	var over := lg(L, str(big))
	var r_co := times(Q.new(r), lx)
	var m1 := ["%s = %s/%s." % [whole, lg(L, arg), over], "%s = %d, as %d = %s." % [over, k, big, pw(B, k)], "So %s = %s." % [whole, text]]
	var m2 := ["Let y = %s, so %d^y = %s." % [whole, big, arg], "%d = %s, so %d^(%dy) = %s." % [big, pw(B, k), B, k, arg], "%dy = %s." % [k, r_co], "So y = %s." % text]
	var m3 := ["Let y = %s, so %d^y = %s." % [whole, big, arg], "Take %s of both sides: y %s = %s." % [L, over, lg(L, arg)], "%dy = %s." % [k, r_co], "So y = %s." % text]
	var w: Array = [wrong({"c": Q.new(r, big), "text": times(Q.new(r, big), lx)}, R_BASE_ITSELF), wrong({"c": Q.new(r * k), "text": times(Q.new(r * k), lx)}, R_TIMES_BASE)]
	w.append(walt("%d/(%s)" % [k, r_co] if r > 1 else "%d/%s" % [k, lx], R_INVERT))
	var gen: Array = [c.add(1), c.add(2), Q.new(r + 1, k), Q.new(r, k + 1), c.mul(3)].filter(func(x): return not x.eq(c) and not x.eq(1)).map(func(x): return {"c": x, "text": times(x, lx)})
	return {"lines": [whole], "asked": "Write this in terms of %s, where x > 0." % lx, "answer": ans, "wrongs": rng.shuffled(w), "generic": gen,
		"methods": {FORMULA: method(m1, ans.values), POWERS: method(m2, ans.values), DEFINE: method(m3, ans.values)}}


func u_value_3sf(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var N_: int = s.N
	var B: int = s.base
	var H: String = s.over
	var whole := lg(s.L, str(N_))
	var ans := Answer.make("number", {"v": s.val})
	ans.show = "sf"
	var hb: int = 0 if H == "ln" else 10
	var a := LogLawsSituation.lg(hb, N_)
	var b := LogLawsSituation.lg(hb, B)
	var said3 := "So %s = %s to 3 s.f." % [whole, Fmt.sf(s.val)]
	var m1 := ["%s = %s/%s." % [whole, lg(H, str(N_)), lg(H, str(B))], "%s = %s and %s = %s." % [lg(H, str(N_)), Fmt.work(a, 6), lg(H, str(B)), Fmt.work(b, 6)],
		"%s/%s = %s." % [Fmt.work(a, 6), Fmt.work(b, 6), Fmt.work(s.val, 4)], said3]
	var m2 := ["Put %d and %d into the log-base template: %s." % [B, N_, whole], "The GDC shows %s." % Fmt.work(s.val, 5), said3]
	var w: Array = [wrong({"v": GdcKit.qf(1.0 / s.v)}, R_INVERT), wrong({"v": GdcKit.qf(log(float(N_) / B) / log(10.0))}, R_SIMPLIFY),
		wrong({"v": GdcKit.qf(float(N_) / B)}, R_NUM_BASE)]
	var gen: Array = [1.1, 0.9, 1.3].map(func(f): return {"v": GdcKit.qf(s.v * f)})
	return {"lines": [whole], "asked": "Find the value. Give your answer to 3 significant figures.", "answer": ans, "wrongs": rng.shuffled(w), "generic": gen,
		"methods": {FORMULA: method(m1, ans.values), GDC_BASE: method(m2, ans.values)}}
