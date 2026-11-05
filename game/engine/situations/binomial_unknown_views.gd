class_name BinomialUnknownViews
extends ExtensionViews
## The views on the `binomial-unknown` situation: one builder per unknown of
## t1-binomial-find-unknown (FAL-740). The answer is the letter (k, a, n) or x. One or two values
## are the `xs` kind, so a wrong option can have another count, as one sign of two. A surd on
## Paper 1 is the `form` kind, with the number under the root typed, and goes to 3 s.f. on Paper 2.
## Two letters are the `named` kind.
##
## The one representation is "equation": the exam gives a bracket and a coefficient, and nothing
## here needs a figure. Every GDC method is Paper 2, and Paper 1 never shows one.
##
## Misconceptions come from SL1.9, then the type's own, which are "<type id>#<index>".

const FIND := "SL1.9.find-unknown#"
const TERM := "SL1.9.specific-term#"
const OWN := "t1-binomial-find-unknown#"
const R_RAISE := FIND + "0"
const R_ONLY := FIND + "1"
const R_ZERO := FIND + "2"
const R_SIGN := TERM + "0"
const R_OTHER := TERM + "1"
const R_ODD := OWN + "5"
const R_COND := OWN + "6"
const R_SQRT := OWN + "7"
const R_NEG := OWN + "8"
const R_NCR := OWN + "9"
const R_STOP := OWN + "10"
const R_SHIFT := OWN + "11"
const R_INV := OWN + "12"
const R_DIVIDE := OWN + "13"
const R_NEXT := OWN + "14"
const R_TOP := OWN + "15"
const R_DENOM := OWN + "16"
const R_ROOT := OWN + "17"
const R_PLACE := OWN + "18"

const GDC := "gdc-search"
const UNKNOWNS := ["k-odd-power", "k-both-signs", "k-surd-both-signs", "k-positive-condition", "a-in-bracket",
	"n-from-coefficient", "n-from-power-bracket", "n-and-k-from-expansion", "n-and-k-two-coefficients", "equal-find-k",
	"equal-find-n", "ratio-find-k", "ratio-find-n", "two-brackets", "quotient-coefficient", "term-mean"]
const PLACES := ["first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth", "eleventh", "twelfth",
	"thirteenth", "fourteenth", "fifteenth"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## No calculator on Paper 1, and a power with n in it has no algebra at this level.
func papers(unknown: String, _rep: String, angle_id: String) -> Array:
	if not has(unknown):
		return []
	return [2] if angle_id == GDC or unknown == "n-from-power-bracket" else [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = BinomialUnknownSituation.export(s)
	if s.paper == 1:
		out.methods.erase(GDC)
	return out


# ── Writing things ───────────────────────────────────────────

static func C(n: int, r: int) -> int:
	return BinomialUnknownSituation.ncr(n, r)


static func pw(v: Q, e: int) -> Q:
	return BinomialUnknownSituation.qpow(v, e)


static func raised(base: String, e: int) -> String:
	return base + Fmt.sup(e)


static func x_text(m: int) -> String:
	return "x" + Fmt.sup(m)


## (1 + kx), (k + 2x), (x + k).
static func bracket(s: Dictionary) -> String:
	var xt := x_text(s.p)
	var one := "1"
	var two: String = s.letter + xt
	match s.shape:
		"ckx":
			one = str(s.c)
		"xk":
			one = xt
			two = s.letter
		"cxk":
			one = str(s.c) + xt
			two = s.letter
	return "(%s + %s)" % [two, one] if s.flip else "(%s + %s)" % [one, two]


static func power_text(s: Dictionary) -> String:
	return bracket(s) + Fmt.sup(s.n)


## (1 + 3x) or (1 − 3x), for a k that is known.
static func known_bracket(k: Q) -> String:
	return "(%s)" % Fmt.terms([Q.new(1), k], [0, 1])


## A number as a factor: −3 in brackets.
static func F(v: Variant) -> String:
	return P(v) if Q.of(v).sign() < 0 else N(v)


## 3k² for a number and a power of a letter; a power of 0 is the number alone.
static func letter_term(v: Variant, letter: String, e: int) -> String:
	return Fmt.terms([Q.of(v)], [e], letter)


## The value a GDC shows: in full where it ends, else to 5 s.f.
static func screen(v: Variant) -> String:
	var t := Fmt.dec(v)
	return Fmt.work(v, 5) if t.contains("/") or t.length() > 8 else t


# ── Answers ──────────────────────────────────────────────────

static func xs_ans(letter: String, vals: Array, exact: bool = true) -> Dictionary:
	var ans := Answer.make("xs", Answer.xs_of(vals), {"var": letter})
	if exact:
		ans.exact = true
	else:
		ans.show = "sf"
	return ans


static func named_ans(names: Array, vals: Array) -> Dictionary:
	var ans := Answer.make("named", {"v0": vals[0], "v1": vals[1]}, {"names": names})
	ans.exact = true
	return ans


## ±√d or √d, with the number under the root typed.
static func surd_ans(letter: String, d: int, both: bool) -> Dictionary:
	var head := "%s = %s√" % [letter, "±" if both else ""]
	var ans := Answer.make("form", {"r": Q.new(d), "text": head + str(d)}, {"parts": [head, {"slot": "r"}]})
	ans.exact = true
	return ans


static func wx(vals: Array, ref: String = "") -> Dictionary:
	return wrong(Answer.xs_of(vals), ref)


static func wi(v: int, ref: String = "") -> Dictionary:
	return wrong(Answer.xs_of([Q.new(v)]), ref)


static func wnamed(a: Q, b: Q, ref: String = "") -> Dictionary:
	return wrong({"v0": a, "v1": b}, ref)


static func walt(text: String, ref: String = "") -> Dictionary:
	return wrong({"text": text, "shape": "other"}, ref)


static func gi(vals: Array) -> Array:
	return vals.filter(func(v): return v > 0).map(func(v): return Answer.xs_of([Q.new(v)]))


static func gx(vals: Array) -> Array:
	return vals.map(func(v): return Answer.xs_of([v]))


static func gnamed(pairs: Array) -> Array:
	return pairs.map(func(p): return {"v0": p[0], "v1": p[1]})


static func whole_n(v: Q, n: int) -> bool:
	return v.is_int() and v.sign() > 0 and v.n != n


# ── A letter in the bracket ──────────────────────────────────

## The term with the letter, worked out: 6C3 × 2³ × (kx)³ = 160k³x³.
static func term_step(s: Dictionary) -> String:
	var l: String = s.letter
	var n: int = s.n
	var e: int = s.e
	var o: int = n - e
	var xt := x_text(s.p)
	var on_x: bool = s.shape in ["1kx", "ckx"]
	var bits: Array = ["%dC%d" % [n, e]]
	var lp := raised("(%s%s)" % [l, xt], e) if on_x else raised(l, e)
	if on_x:
		if s.c > 1:
			bits.append(raised(str(s.c), o))
		bits.append(lp)
	else:
		bits.append(raised("x", o) if s.c == 1 and s.p == 1 else raised("(%s%s)" % ["" if s.c == 1 else str(s.c), xt], o))
		bits.append(lp)
	return "The term in %s is %s = %s%s." % [x_text(s.m), " × ".join(bits), letter_term(s.mult, l, e), x_text(s.m)]


static func mag_of(s: Dictionary) -> Q:
	return GdcKit.qf(sqrt(float(s.d))) if s.d > 0 else s.val.abs_q()


## The value or values a wrong magnitude m takes, in the pattern of the answer.
static func pattern(s: Dictionary, m: Q) -> Array:
	if s.both:
		return [m.neg(), m]
	return [m.neg()] if s.val.sign() < 0 else [m]


static func root_step(s: Dictionary) -> String:
	var l: String = s.letter
	var e: int = s.e
	var eq := "%s = %s" % [raised(l, e), N(s.coef.div(s.mult))]
	if s.d > 0:
		var head := eq + ", so %s² = %d, as a square isn't negative" % [l, s.d] if e == 4 else eq
		var sign := "±" if s.both else ""
		var then := "%s, so %s = ±√%d" % [head, l, s.d]
		return then + "." if s.both else then + ". %s > 0 keeps %s = %s√%d." % [l, l, sign, s.d]
	var m: String = N(s.val.abs_q())
	if s.both:
		return "%s, so %s = ±%s." % [eq, l, m]
	if e % 2 == 0:
		return "%s, so %s = ±%s, and %s > 0 keeps %s = %s." % [eq, l, m, l, l, m]
	return "%s, so %s = %s, as an odd power has one real root." % [eq, l, N(s.val)]


static func gdc_read(s: Dictionary) -> String:
	var m: String = screen(mag_of(s))
	if s.both:
		return "The graphs cross at X = −%s and X = %s." % [m, m]
	if s.e % 2 == 0:
		return "The graphs cross at X = −%s and X = %s, and %s > 0 keeps the second." % [m, m, s.letter]
	return "The graphs cross at X = %s." % screen(s.val)


func _one(s: Dictionary, rng: Seeded) -> Dictionary:
	var l: String = s.letter
	var surd: bool = s.d > 0
	var by_hand: bool = surd and s.paper == 1
	var approx: bool = surd and s.paper == 2
	var mag := mag_of(s)
	var ans: Dictionary
	if by_hand:
		ans = surd_ans(l, s.d, s.both)
	else:
		ans = xs_ans(l, pattern(s, mag), not approx)
	var cond := ", where %s > 0," % l if s.positive else ","
	var lines := ["In the expansion of %s%s the coefficient of %s is %s." % [power_text(s), cond, x_text(s.m), N(s.coef)]]
	var asked := "Find the possible values of %s." % l if s.both else "Find the value of %s." % l
	if approx:
		asked += " Give your answers to 3 significant figures." if s.both else " Give your answer to 3 significant figures."
	var final := "So %s." % Answer.text(ans)
	var term := term_step(s)
	var says := "So %s = %s." % [letter_term(s.mult, l, s.e), N(s.coef)]
	var w: Dictionary = _surd_options(s) if by_hand else _letter_options(s, mag)
	return {"lines": lines, "asked": asked, "answer": ans, "wrongs": rng.shuffled(w.wrongs), "generic": w.generic,
		"methods": {"coefficient-equation": method([term, says, root_step(s), final], ans.values),
			GDC: method([term, "Graph Y1 = %s and Y2 = %s." % [letter_term(s.mult, "X", s.e), N(s.coef)], gdc_read(s), final], ans.values)}}


## Where the number in the bracket stayed at its first power, the power of the letter's value.
static func unraised_c(s: Dictionary) -> Variant:
	if s.c < 2 or s.n - s.e < 2:
		return null
	return BinomialUnknownSituation.exact_root(s.coef.abs_q().div(Q.new(C(s.n, s.e) * s.c)), s.e)


func _letter_options(s: Dictionary, mag: Q) -> Dictionary:
	var odd: bool = s.e % 2 == 1
	var two := [mag.neg(), mag]
	var w: Array = [wx([s.coef.div(s.mult)], R_RAISE)]
	if s.both:
		w.append(wx([mag], R_ONLY))
	elif odd and not s.positive:
		w.append(wx(two, R_ODD))
	elif not odd:
		w.append(wx(two, R_COND))
	if s.val.sign() < 0:
		w.append(wx([mag], R_SIGN))
	if s.e == 4:
		var once: Q = Q.new(s.d) if s.d > 0 else mag.sq()
		w.append(wx(pattern(s, once), R_SQRT))
	var other: Variant = unraised_c(s)
	if other != null:
		w.append(wx(pattern(s, other), R_OTHER))
	var gen: Array = []
	for m in [mag.add(1), mag.add(2), mag.mul(2), mag.add(3)]:
		gen.append(Answer.xs_of(pattern(s, m)))
	gen.append(Answer.xs_of([mag.neg()]) if not s.positive else Answer.xs_of([mag.add(4)]))
	return {"wrongs": w, "generic": gen}


func _surd_options(s: Dictionary) -> Dictionary:
	var l: String = s.letter
	var d: int = s.d
	var sign := "±" if s.both else ""
	var w: Array = [walt("%s = %s" % [l, N(s.coef.div(s.mult))], R_RAISE)]
	if s.both:
		w.append(walt("%s = √%d" % [l, d], R_ONLY))
	else:
		w.append(walt("%s = ±√%d" % [l, d], R_COND))
	if s.e == 4:
		w.append(walt("%s = %s%d" % [l, sign, d], R_SQRT))
	var gen: Array = []
	for r in [d + 1, d + 2, d + 3, 2 * d, d + 4]:
		if BinomialUnknownSituation.int_root(r, 2) < 0:
			gen.append({"r": Q.new(r), "text": "%s = %s√%d" % [l, sign, r]})
	return {"wrongs": w, "generic": gen}


func u_k_odd_power(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _one(s, rng)


func u_k_both_signs(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _one(s, rng)


func u_k_surd_both_signs(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _one(s, rng)


func u_k_positive_condition(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _one(s, rng)


func u_a_in_bracket(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	return _one(s, rng)


# ── n ──────────────────────────────────────────────────────

## n(n − 1) = v, as a line ending in the positive root.
static func quadratic_n(n: int) -> String:
	return "n² − n − %d = 0, so (n − %d)(n + %d) = 0" % [n * (n - 1), n, n - 1]


func u_n_from_coefficient(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var j: int = s.j
	var k: Q = s.k
	var each := pw(k, j)
	var ans := xs_ans("n", [Q.new(n)])
	var lines := ["In the expansion of %s^n, where n is a positive integer, the coefficient of %s is %s." % [known_bracket(k), x_text(j), N(s.coef)]]
	var final := "So n = %d." % n
	var term := "The term in %s is nC%d × %s = nC%d × %s." % [x_text(j), j, raised("(%s)" % Fmt.terms([k], [1]), j), j, letter_term(each, "x", j)]
	var hand: Array = [term, "So n(n − 1)/2 × %s = %s." % [F(each), N(s.coef)],
		"n(n − 1) = %s × 2 ÷ %s = %d." % [N(s.coef), F(each), n * (n - 1)], quadratic_n(n) + ".", "n is positive, so n = %d." % n]
	var table := "Table Y1 = (X nCr %d) × %s, with X going up in ones." % [j, F(each)]
	var read := "The table shows %s at X = %d and %s at X = %d." % [N(Q.new(C(n - 1, j)).mul(each)), n - 1, N(s.coef), n]
	var w: Array = [wi(C(n, j), R_NCR), wi(n * (n - 1) if j == 2 else n * (n - 1) * (n - 2), R_STOP)]
	var methods := {GDC: method([term, table, read, final], ans.values)}
	if j == 2:
		w.append(wrong(Answer.xs_of([Q.new(1 - n), Q.new(n)]), R_NEG))
		methods["coefficient-equation"] = method(hand, ans.values)
	return {"lines": lines, "asked": "Find the value of n.", "answer": ans, "wrongs": rng.shuffled(w), "generic": gi([n + 1, n - 1, n + 2, n - 2, n + 3]),
		"methods": methods}


## A power with n and a number in it: n + 1, n, n − 2.
static func n_plus(v: int) -> String:
	if v == 0:
		return "n"
	return "n + %d" % v if v > 0 else "n − %d" % -v


static func x_plus(v: int) -> String:
	return n_plus(v).replace("n", "X")


func u_n_from_power_bracket(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var shift: int = s.shift
	var N_: int = s.N
	var c: int = s.c
	var xt := x_text(s.p)
	var ans := xs_ans("n", [Q.new(n)])
	var top := n_plus(shift)
	var rest := shift - 2
	var base := "(%s)" % xt if s.p > 1 else xt
	var power_c := "%d^n" % c if rest == 0 else "%d^(%s)" % [c, n_plus(rest)]
	var term := "The term in %s has %s from two brackets, so it is (%s)C2 × %s × %s²." % [x_text(2 * s.p), xt, top, power_c, base]
	var X_top := "X" if shift == 0 else "(%s)" % x_plus(shift)
	var key_c := "%d^X" % c if rest == 0 else "%d^(%s)" % [c, x_plus(rest)]
	var table := "Table Y1 = (%s nCr 2) × %s, with X going up in ones." % [X_top, key_c]
	var below: int = C(N_ - 1, 2) * BinomialUnknownSituation.power(c, N_ - 3)
	var read := "The table shows %d at X = %d and %s at X = %d." % [below, n - 1, N(s.coef), n]
	return {"lines": ["Consider the expansion of (%d + %s)^(%s), where n is a positive integer." % [c, xt, top]],
		"asked": "Given that the coefficient of %s is %s, find the value of n." % [x_text(2 * s.p), N(s.coef)],
		"answer": ans, "wrongs": [wi(N_, R_SHIFT)], "generic": gi([n + 1, n - 1, n + 2, n - 2, n + 3]),
		"methods": {GDC: method([term, table, read, "So n = %d." % n], ans.values)}}


## 1 + 12x + 28k²x² + ...
func u_n_and_k_from_expansion(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var k: Q = s.k
	var p: Q = s.coef
	var q: int = C(n, 2)
	var nq := Q.new(n)
	var ans := named_ans(["n", "k"], [nq, k])
	var head := "%s + %dk²x² + ..." % [Fmt.terms([Q.new(1), p], [0, 1]), q]
	var first := "The coefficient of x gives nk = %s, so k isn't 0." % N(p)
	var last := "k = %s ÷ %d = %s." % [N(p), n, N(k)]
	var final := "So %s." % Answer.text(ans)
	var w: Array = [wnamed(nq, nq.div(p), R_DIVIDE), wnamed(Q.new(q), p.div(Q.new(q)), R_NCR)]
	if k.sign() < 0:
		w.append(wnamed(nq, k.abs_q(), R_SIGN))
	return {"lines": ["The expansion of (1 + kx)^n begins %s" % head, "n is a positive integer and k is a rational number."],
		"asked": "Find the value of n and the value of k.", "answer": ans, "wrongs": rng.shuffled(w),
		"generic": gnamed([[Q.new(n + 1), p.div(Q.new(n + 1))], [Q.new(n - 1), p.div(Q.new(n - 1))], [nq, k.add(1)], [nq, k.mul(2)], [Q.new(n + 2), p.div(Q.new(n + 2))]]),
		"methods": {"simultaneous": method([first, "The coefficient of x² gives n(n − 1)/2 × k² = %dk², so n(n − 1) = %d." % [q, n * (n - 1)],
			quadratic_n(n) + ", and n is positive, so n = %d." % n, last, final], ans.values),
			GDC: method([first, "The coefficient of x² gives nC2 × k² = %dk², so nC2 = %d." % [q, q],
				"Table Y1 = X nCr 2, with X going up in ones: it shows %d at X = %d." % [q, n], last, final], ans.values)}}


func u_n_and_k_two_coefficients(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var a: Q = s.a
	var p: Q = s.v1
	var q: Q = s.v2
	var nq := Q.new(n)
	var ans := named_ans(["n", "a"], [nq, a])
	var first := "The coefficient of x gives na = %s." % N(p)
	var second := "The coefficient of x² gives n(n − 1)/2 × a² = %s." % N(q)
	var last := "So %s." % Answer.text(ans)
	var gap: Q = q.mul(2).div(p)
	var w: Array = []
	if a.sign() < 0:
		w.append(wnamed(nq, a.abs_q(), R_SIGN))
	var n1: Q = gap.add(1)
	if whole_n(n1, n) and n1.n >= 2:
		w.append(wnamed(n1, p.div(n1), R_RAISE))
	var n2: Q = p.mul(p).div(q)
	if whole_n(n2, n):
		w.append(wnamed(n2, q.div(p), R_NCR))
	return {"lines": ["In the expansion of (1 + ax)^n, where n is a positive integer, the coefficient of x is %s and the coefficient of x² is %s." % [N(p), N(q)]],
		"asked": "Find the value of n and the value of a.", "answer": ans, "wrongs": rng.shuffled(w),
		"generic": gnamed([[Q.new(n + 1), p.div(Q.new(n + 1))], [Q.new(n - 1), p.div(Q.new(n - 1))], [nq, a.neg()], [nq, a.mul(2)], [nq, a.add(1)]]),
		"methods": {"simultaneous": method([first, second,
			"n(n − 1)a² is na(na − a), so %s × (%s − a) ÷ 2 = %s." % [F(p), N(p), N(q)],
			"%s − a = 2 × %s ÷ %s = %s, so a = %s, and n = %s ÷ %s = %d." % [N(p), F(q), F(p), N(gap), N(a), N(p), F(a), n], last], ans.values),
			GDC: method([first + " So a = %s ÷ n." % N(p), "The coefficient of x² gives nC2 × (%s ÷ n)² = %s." % [N(p), N(q)],
				"Table Y1 = (X nCr 2) × (%s ÷ X)², with X going up in ones: it shows %s at X = %d." % [N(p), N(q), n],
				"a = %s ÷ %d = %s." % [N(p), n, N(a)], last], ans.values)}}


# ── Two coefficients compared ────────────────────────────────

## The coefficients of x^j and x^(j + 1) in (1 + kx)^n, with n a number and k a letter.
static func both_terms(s: Dictionary, l: String = "k") -> Array:
	var n: int = s.n
	var j: int = s.j
	return ["The coefficient of %s is %dC%d × %s = %s." % [x_text(j), n, j, raised(l, j), letter_term(C(n, j), l, j)],
		"The coefficient of %s is %dC%d × %s = %s." % [x_text(j + 1), n, j + 1, raised(l, j + 1), letter_term(C(n, j + 1), l, j + 1)]]


func u_equal_find_k(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var j: int = s.j
	var k: Q = s.k
	var A: int = C(n, j)
	var B: int = C(n, j + 1)
	var ans := xs_ans("k", [k])
	var lines := ["In the expansion of (1 + kx)%s, where k ≠ 0, the coefficient of %s equals the coefficient of %s." % [Fmt.sup(n), x_text(j), x_text(j + 1)]]
	var terms := both_terms(s)
	var final := "So k = %s." % N(k)
	var w: Array = [wx([Q.new(0), k], R_ZERO), wx([Q.new(n - j, j + 1)], R_INV), wx([Q.new(j + 1, n)], R_NEXT)]
	var same := "So %s = %s." % [letter_term(A, "k", j), letter_term(B, "k", j + 1)]
	var cut := "k ≠ 0, so dividing by %s gives %d = %dk, and k = %d ÷ %d." % [raised("k", j), A, B, A, B]
	var graph := "Graph Y1 = %s − %s and find its zeros." % [letter_term(A, "X", j), letter_term(B, "X", j + 1)]
	var read := "The zeros are X = 0 and X = %s, and k ≠ 0 keeps the second." % screen(k)
	return {"lines": lines, "asked": "Find the value of k.", "answer": ans, "wrongs": rng.shuffled(w),
		"generic": gx([k.add(1), k.mul(2), k.div(2), k.neg(), k.add(2)]),
		"methods": {"coefficient-equation": method(terms + [same, cut, final], ans.values), GDC: method(terms + [graph, read, final], ans.values)}}


func u_equal_find_n(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var j: int = s.j
	var unit: bool = s.shape == "1kx"
	var c: int = s.c
	var k: int = s.k.n
	var ans := xs_ans("n", [Q.new(n)])
	var name := "(1 + %dx)^n" % k if unit else "(%d + x)^n" % c
	var lines := ["In the expansion of %s, where n is a positive integer, the coefficient of %s equals the coefficient of %s." % [name, x_text(j), x_text(j + 1)]]
	var form := "nC%d ÷ nC%d = (n − %d)/%d" % [j + 1, j, j, j + 1]
	var hand: Array
	var keyed: String
	if unit:
		hand = ["The coefficients are nC%d × %d%s and nC%d × %d%s." % [j, k, Fmt.sup(j), j + 1, k, Fmt.sup(j + 1)],
			"They are equal, so nC%d ÷ nC%d = 1/%d." % [j + 1, j, k],
			"%s, so (n − %d)/%d = 1/%d." % [form, j, j + 1, k],
			"n − %d = %d ÷ %d = %d, so n = %d." % [j, j + 1, k, n - j, n]]
		keyed = "(X nCr %d) × %d%s − (X nCr %d) × %d%s" % [j, k, Fmt.sup(j), j + 1, k, Fmt.sup(j + 1)]
	else:
		hand = ["The coefficients are nC%d × %d^(n − %d) and nC%d × %d^(n − %d)." % [j, c, j, j + 1, c, j + 1],
			"They are equal, so nC%d ÷ nC%d = %d." % [j + 1, j, c],
			"%s, so (n − %d)/%d = %d." % [form, j, j + 1, c],
			"n − %d = %d × %d = %d, so n = %d." % [j, j + 1, c, n - j, n]]
		keyed = "(X nCr %d) × %d^(X − %d) − (X nCr %d) × %d^(X − %d)" % [j, c, j, j + 1, c, j + 1]
	var w: Array = [wi(n - j, R_NEXT)]
	var flip: Q = Q.new(j).add(Q.new(j + 1).mul(Q.new(k))) if unit else Q.new(j).add(Q.new(j + 1, c))
	if whole_n(flip, n):
		w.append(wrong(Answer.xs_of([flip]), R_INV))
	var gdc: Array = [hand[0], "Table Y1 = %s, with X going up in ones." % keyed, "The table shows 0 at X = %d." % n, "So n = %d." % n]
	return {"lines": lines, "asked": "Find the value of n.", "answer": ans, "wrongs": rng.shuffled(w), "generic": gi([n + 1, n - 1, n + 2, n - 2, n + 3]),
		"methods": {"coefficient-equation": method(hand, ans.values), GDC: method(gdc, ans.values)}}


static func ratio_text(r: Q) -> String:
	return "%d : %d" % [r.n, r.d]


func u_ratio_find_k(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var j: int = s.j
	var k: Q = s.k
	var r: Q = s.ratio
	var A: int = C(n, j)
	var B: int = C(n, j + 1)
	var ans := xs_ans("k", [k])
	var lines := ["In the expansion of (1 + kx)%s, the coefficient of %s and the coefficient of %s are in the ratio %s." % [Fmt.sup(n), x_text(j + 1), x_text(j), ratio_text(r)]]
	var terms := both_terms(s)
	var final := "So k = %s." % N(k)
	var size := Q.new(B, A)
	var w: Array = [wx([Q.new(r.d, r.n).div(size)], R_INV), wx([r.mul(Q.new(j + 1, n))], R_NEXT)]
	var hand: Array = terms + ["Dividing, %s ÷ %s = %s, so (%s)k = %s." % [letter_term(B, "k", j + 1), letter_term(A, "k", j), N(r), N(size), N(r)],
		"k = %s ÷ %s." % [P(r), P(size)], final]
	var graph := "Graph Y1 = (%s) ÷ (%s) and Y2 = %s." % [letter_term(B, "X", j + 1), letter_term(A, "X", j), N(r) if r.d == 1 else "%d ÷ %d" % [r.n, r.d]]
	return {"lines": lines, "asked": "Find the value of k.", "answer": ans, "wrongs": rng.shuffled(w),
		"generic": gx([k.add(1), k.mul(2), k.div(2), k.add(2), k.add(3)]),
		"methods": {"coefficient-equation": method(hand, ans.values),
			GDC: method(terms + [graph, "The graphs cross at X = %s." % screen(k), final], ans.values)}}


func u_ratio_find_n(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var j: int = s.j
	var k: int = s.k.n
	var r: Q = s.ratio
	var ans := xs_ans("n", [Q.new(n)])
	var lines := ["In the expansion of (1 + %dx)^n, where n is a positive integer, the coefficient of %s and the coefficient of %s are in the ratio %s." % [k, x_text(j + 1), x_text(j), ratio_text(r)]]
	var given := "The coefficients are nC%d × %d%s and nC%d × %d%s." % [j, k, Fmt.sup(j), j + 1, k, Fmt.sup(j + 1)]
	var hand: Array = [given, "Dividing, nC%d ÷ nC%d × %d = %s." % [j + 1, j, k, N(r)],
		"nC%d ÷ nC%d = (n − %d)/%d, so (n − %d)/%d × %d = %s." % [j + 1, j, j, j + 1, j, j + 1, k, N(r)],
		"n − %d = %s × %d ÷ %d = %d, so n = %d." % [j, P(r), j + 1, k, n - j, n]]
	var keyed := "(X nCr %d) × %d ÷ (X nCr %d)" % [j + 1, k, j]
	var w: Array = [wi(n - j, R_NEXT)]
	var flip: Q = Q.new(j).add(Q.new(r.d, r.n).mul(Q.new(j + 1, k)))
	if whole_n(flip, n):
		w.append(wrong(Answer.xs_of([flip]), R_INV))
	return {"lines": lines, "asked": "Find the value of n.", "answer": ans, "wrongs": rng.shuffled(w), "generic": gi([n + 1, n - 1, n + 2, n - 2, n + 3]),
		"methods": {"coefficient-equation": method(hand, ans.values),
			GDC: method([given, "Table Y1 = %s, with X going up in ones." % keyed, "The table shows %s at X = %d." % [screen(r), n], "So n = %d." % n], ans.values)}}


# ── Two brackets ─────────────────────────────────────────────

func u_two_brackets(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var t: int = s.t
	var n1: int = s.n
	var n2: int = s.n2
	var a: Q = s.a
	var b: Q = s.b
	var u: int = n1 - t
	var v: int = n2 - t
	var d: int = n2 - n1
	var A: int = C(n1, t)
	var B: int = C(n2, t)
	var m: int = s.p * t
	var xt := x_text(s.p)
	var ans := named_ans(["a", "b"], [a, b])
	var line := "The coefficient of %s in the expansion of (a%s + b)%s is %s."
	var lines := [line % [x_text(m), xt, Fmt.sup(n1), N(s.v1)], line % [x_text(m), xt, Fmt.sup(n2), N(s.v2)]]
	var first := "The first gives %dC%d × %s%s = %d%s%s = %s." % [n1, t, raised("a", t), raised("b", u), A, raised("a", t), raised("b", u), N(s.v1)]
	var second := "The second gives %dC%d × %s%s = %d%s%s = %s." % [n2, t, raised("a", t), raised("b", v), B, raised("a", t), raised("b", v), N(s.v2)]
	var bp: Q = pw(b, d)
	var div := "Dividing the second by the first, (%s)%s = %s, so %s = %s" % [N(Q.new(B, A)), raised("b", d), N(s.v2.div(s.v1)), raised("b", d), N(bp)]
	div += ", and b > 0 gives b = %s." % N(b) if d == 2 else "."
	var at: Q = pw(a, t)
	var back := "%s = %s ÷ (%d × %s), which is %s" % [raised("a", t), N(s.v1), A, N(pw(b, u)), N(at)]
	back += ", and a > 0 gives a = %s." % N(a) if t % 2 == 0 else ", so a = %s." % N(a)
	var final := "So %s." % Answer.text(ans)
	var key1 := "(%s ÷ (%d%s))^(1/%d)" % [N(s.v1), A, raised("X", u), t]
	var key2 := "(%s ÷ (%d%s))^(1/%d)" % [N(s.v2), B, raised("X", v), t]
	var w: Array = [wnamed(at, b, R_RAISE)]
	if d == 2:
		w.append(wnamed(a, bp, R_ROOT))
	return {"lines": lines, "asked": "Find the value of a and the value of b, where a > 0 and b > 0.", "answer": ans, "wrongs": rng.shuffled(w),
		"generic": gnamed([[b, a], [a.mul(2), b], [a, b.add(1)], [a.add(1), b], [a, b.mul(2)], [a.add(1), b.add(1)]]),
		"methods": {"simultaneous": method([first, second, div, back, final], ans.values),
			GDC: method([first, second, "With X for b, a is Y1 = %s from the first and Y2 = %s from the second." % [key1, key2],
				"For X > 0 the graphs cross at X = %s, Y = %s." % [screen(b), screen(a)], final], ans.values)}}


func u_quotient_coefficient(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var t: int = s.t
	var m: int = s.m
	var p: int = s.p
	var c: int = s.c
	var a: Q = s.a
	var R: Q = s.R
	var A: int = C(n, t)
	var over := "%dx%s" % [c, Fmt.sup(p)]
	var ans := xs_ans("a", [a])
	var top := "(1 + ax)" if s.flip else "(ax + 1)"
	var given := "(%s)%s" % [N(R), raised("a", t - 1)] if R.d > 1 else "%s%s" % [N(R), raised("a", t - 1)]
	var lines := ["Consider the expansion of %s%s/(%s), where a ≠ 0." % [top, Fmt.sup(n), over], "The coefficient of the term in %s is %s." % [x_text(m), given]]
	var from := "Dividing by %s lowers each power by %d, so %s comes from the term in %s on top." % [over, p, x_text(m), x_text(t)]
	var left := letter_term(s.top, "a", t)
	var term := "That term is %dC%d × %s = %d%s%s, and dividing by %s leaves %s%s." % [n, t, raised("(ax)", t), A, raised("a", t), x_text(t), over, left, x_text(m)]
	var same := "So %s = %s." % [left, given]
	var cut := "a ≠ 0, so dividing by %s gives %s = %s." % [raised("a", t - 1), letter_term(s.top, "a", 1), N(R)]
	var final := "So a = %s." % N(a)
	var rg := N(R) if R.d == 1 else P(R)
	var graph := "Graph Y1 = %s − %s%s and find its zeros." % [letter_term(s.top, "X", t), rg, raised("X", t - 1)]
	var read := "The zeros are X = 0 and X = %s, and a ≠ 0 keeps the second." % screen(a)
	var w: Array = [wx([Q.new(0), a], R_ZERO), wx([R.div(Q.new(A))], R_DENOM)]
	var plain: Q = Q.new(C(n, m)).div(Q.new(c).mul(R))
	var slip: Variant = plain if p == 2 else BinomialUnknownSituation.exact_root(plain, p - 1)
	if slip != null:
		w.append(wx([slip], R_TOP))
	return {"lines": lines, "asked": "Find the value of a.", "answer": ans, "wrongs": rng.shuffled(w),
		"generic": gx([a.mul(2), a.add(1), Q.new(1).div(a), a.neg(), a.div(2)]),
		"methods": {"coefficient-equation": method([from, term, same, cut, final], ans.values),
			GDC: method([from, term, graph, read, final], ans.values)}}


# ── The value of x ───────────────────────────────────────────

## The roots of 2T(r) = T(r − 1) + T(r + 1) in (x + c)^n, as floats, or [] with no real pair.
static func mean_roots(n: int, r: int, c: int) -> Array:
	if r < 1 or r + 1 > n:
		return []
	var A := float(C(n, r - 1))
	var B := float(C(n, r))
	var d := B * B - A * float(C(n, r + 1))
	if d <= 0.0:
		return []
	return [c * (B - sqrt(d)) / A, c * (B + sqrt(d)) / A]


func u_term_mean(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var r: int = s.r
	var c: int = s.c
	var one := Q.new(c)
	var exact: bool = s.paper == 1
	var ans := xs_ans("x", [s.x1, s.x2], exact)
	var Ta: Q = Q.new(C(n, r - 1)).mul(pw(one, r - 1))
	var Tb: Q = Q.new(C(n, r)).mul(pw(one, r))
	var Tc: Q = Q.new(C(n, r + 1)).mul(pw(one, r + 1))
	var hi: int = n - r + 1
	var cut: int = hi - 2
	var t1 := letter_term(Ta, "x", hi)
	var t2 := letter_term(Tb, "x", hi - 1)
	var t3 := letter_term(Tc, "x", cut)
	var two: Q = Tb.mul(2)
	var g: int = Q.gcd(Q.gcd(Ta.n, two.n), Tc.n)
	var qa: int = Ta.n / g
	var qb: int = two.n / g
	var qc: int = Tc.n / g
	var disc: int = qb * qb - 4 * qa * qc
	var quad := Fmt.terms([Q.new(qa), Q.new(-qb), Q.new(qc)], [2, 1, 0])
	var lines := ["Consider the expansion of (x + %d)%s, where x ≠ 0, with its terms in descending powers of x." % [c, Fmt.sup(n)],
		"The %s term is the mean of the %s term and the %s term." % [PLACES[r], PLACES[r - 1], PLACES[r + 1]]]
	var asked := "Find the possible values of x."
	if not exact:
		asked += " Give your answers to 3 significant figures."
	var first := "The three terms are %s, %s and %s." % [t1, t2, t3]
	var mean := "The mean of the outer two is the middle one, so 2 × %s = %s + %s." % [t2, t1, t3]
	var divide := "x ≠ 0, so dividing by %s gives %s = 0." % [x_text(cut), quad]
	var whole_root := BinomialUnknownSituation.int_root(disc, 2)
	var solve := "x = (%d ± %s) ÷ %d." % [qb, str(whole_root) if whole_root >= 0 else "√%d" % disc, 2 * qa]
	var final := "So %s." % Answer.text(ans)
	var graph := "Graph Y1 = %s − %s + %s and find its zeros." % [t1, letter_term(two, "x", hi - 1), t3]
	graph = graph.replace("x", "X")
	var read := "The zeros are X = 0, X = %s and X = %s, and x ≠ 0 keeps the last two." % [screen(s.x1), screen(s.x2)]
	var w: Array = [wx([Q.new(0), s.x1, s.x2], R_ZERO)]
	if c > 1:
		w.append(wx([s.x1.div(one), s.x2.div(one)], R_OTHER))
	var next := mean_roots(n, r + 1, c)
	if not exact and next.size() == 2 and Fmt.sf(next[0]) != Fmt.sf(next[1]):
		w.append(wx([GdcKit.qf(next[0]), GdcKit.qf(next[1])], R_PLACE))
	return {"lines": lines, "asked": asked, "answer": ans, "wrongs": rng.shuffled(w),
		"generic": [Answer.xs_of([s.x1.add(1), s.x2.add(1)]), Answer.xs_of([s.x1]), Answer.xs_of([s.x2]), Answer.xs_of([s.x1.mul(2), s.x2.mul(2)]), Answer.xs_of([s.x1, s.x2.add(1)])],
		"methods": {"coefficient-equation": method([first, mean, divide, solve, final], ans.values),
			GDC: method([first, mean, graph, read, final], ans.values)}}
