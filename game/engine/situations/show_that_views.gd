class_name ShowThatViews
extends ExtensionViews
## The views on the `show-that-value` situation: one builder per unknown of
## t1-ext-numerical-show-that (FAL-780), SL1.6.numerical-show-that. Every answer is a picked `claim`:
## the one working that reaches the given result from the givens (or, for "verify", that puts the
## value in and works it out). Wrong options are the skill's three slips (checking the given answer,
## stating it with no working, a value rounded to fewer figures) and the type's own, each a working
## that only seems to show it. Error-spot shows a working that starts from the value to be shown, or
## one with a value rounded too early; true-false-reason plays on every cell. The catalogue's
## `order-steps` format isn't built in the engine.
##
## Representations: "equation" (the statement in symbols) and "words" (a story).

const SK := "SL1.6.numerical-show-that#"
const OWN := "t1-ext-numerical-show-that#"
const R_CHECK := SK + "0"
const R_JUMP := SK + "1"
const R_ROUNDED := SK + "2"
const R_DIVIDE_LOGS := OWN + "3"
const R_LAST_TERM := OWN + "4"
const R_DIVISOR := OWN + "5"
const R_UNWORKED := OWN + "6"
const R_NO_C := OWN + "7"
const R_SPOT_START := OWN + "8"
const R_SPOT_ROUND := OWN + "9"
const UNKNOWNS := ["log-difference", "series-sum", "common-difference", "interest-value", "verify-solution"]
const S := preload("res://engine/situations/show_that.gd")
const WHO := ["Kira", "Tomas", "Ines", "The caravan fund"]
const ASKED := "Which working shows this?"


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


func extra() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = ["true-false-reason"]
	out["series-sum"] = ["true-false-reason", "error-spot"]
	out["interest-value"] = ["true-false-reason", "error-spot"]
	return out


func papers(unknown: String, _rep: String, _angle: String) -> Array:
	if not has(unknown):
		return []
	return [2] if unknown == "interest-value" else [1]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = S.export(s)
	return out


# ── Writing things ───────────────────────────────────────────

## u₁₀, S₁₂: a letter with a subscript.
static func sub(letter: String, n: int) -> String:
	var out := letter
	for ch in str(n):
		out += Answer.SUBS[int(ch)]
	return out


static func lg(b: int) -> String:
	return Answer.log_name(b)


## A whole number in a product, in brackets if it is negative: 3, (−2).
static func br(v: int) -> String:
	return str(v) if v >= 0 else "(−%d)" % -v


func _pack(lines: Array, asked: String, right: String, wrongs: Array, steps: Dictionary) -> Dictionary:
	var built := SamplingViews.claims(right, wrongs)
	var out := {"lines": lines, "asked": asked, "answer": built.answer, "wrongs": built.wrongs, "fillers": built.fillers, "methods": {}, "table": null}
	for m in steps:
		out.methods[m] = method(steps[m] + [right], built.answer.values)
	return out


# ── Logarithms ───────────────────────────────────────────────

func u_log_difference(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var b: int = s.b
	var P: int = s.P
	var q: int = s.Q
	var k: int = s.k
	var bk := S.ipow(b, k)
	var statement := "%s %d − %s %d = %d" % [lg(b), P, lg(b), q, k]
	var right := "%s %d − %s %d = %s(%d/%d) = %s %d = %s(%d^%d) = %d" % [lg(b), P, lg(b), q, lg(b), P, q, lg(b), bk, lg(b), b, k, k]
	var wrongs: Array = [
		["If it is %d, then %d^%d × %d = %d, which is true, so the statement holds" % [k, b, k, q, P], R_CHECK],
		["%s, as required" % statement, R_JUMP],
		["%s %d − %s %d = %s %d ÷ %s %d = %d" % [lg(b), P, lg(b), q, lg(b), P, lg(b), q, k], R_DIVIDE_LOGS],
	]
	return _pack(["Show that %s." % statement], ASKED, right, wrongs, {
		"forward-derivation": ["Start from the left side and use the law log a − log b = log(a/b): %s %d − %s %d = %s(%d/%d)." % [lg(b), P, lg(b), q, lg(b), P, q],
			"%d/%d = %d = %d^%d, so %s %d = %d: the working ends at the given value." % [P, q, bk, b, k, lg(b), bk, k]],
		"both-sides": ["Left side: %s %d − %s %d = %s(%d/%d) = %s %d = %d, as %d = %d^%d." % [lg(b), P, lg(b), q, lg(b), P, q, lg(b), bk, k, bk, b, k],
			"Right side: %d. The two sides are equal, which shows it." % k],
	})


# ── Sequences ────────────────────────────────────────────────

static func terms(s: Dictionary) -> String:
	return "%d, %d, %d, …" % [s.u1, s.u1 + s.d, s.u1 + 2 * s.d]


static func sum_line(s: Dictionary) -> String:
	var n: int = s.n
	return "%s = %d/2 × (2 × %d + %d × %d)" % [sub("S", n), n, s.u1, n - 1, s.d]


func u_series_sum(rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var n: int = s.n
	var V: int = s.V
	var inner: int = 2 * s.u1 + (n - 1) * s.d
	var un: int = s.u1 + (n - 1) * s.d
	var Sn := sub("S", n)
	var lines: Array
	if rep == "words":
		lines = ["A stack of crates has %d in its top row, and each row below has %d more than the row above." % [s.u1, s.d], "Show that %d rows hold %d crates in all." % [n, V]]
	else:
		lines = ["The sequence %s is arithmetic." % terms(s), "Show that the sum of its first %d terms is %d." % [n, V]]
	var right := "%s = %d/2 × %d = %d" % [sum_line(s), n, inner, V]
	var wrongs: Array = [
		["Put %s = %d: %d = %d/2 × %d, which is true" % [Sn, V, V, n, inner], R_CHECK],
		["%s = %d, as required" % [Sn, V], R_JUMP],
		["%s = %d × %s = %d × %d = %d" % [Sn, n, sub("u", n), n, un, n * un], R_LAST_TERM],
	]
	var out := _pack(lines, ASKED, right, wrongs, {
		"forward-derivation": ["Use Sₙ = n/2 × (2u₁ + (n − 1)d), with u₁ = %d, d = %d and n = %d." % [s.u1, s.d, n],
			"%s = %d/2 × %d = %d: the working ends at the given value." % [sum_line(s), n, inner, V]],
	})
	var plan := "The first term is %d and the common difference is %d." % [s.u1, s.d]
	var spot: Array = ["%s = %d" % [Sn, V], "%d = %d/2 × (2 × %d + %d × %d)" % [V, n, s.u1, n - 1, s.d], "%d = %d/2 × %d" % [V, n, inner], "%d = %d, as required." % [V, V]]
	var bad := 0
	if rng.chance(0.5):
		spot = [plan, "%s = %d" % [Sn, V], "%d = %d/2 × (2 × %d + %d × %d)" % [V, n, s.u1, n - 1, s.d], "%d = %d, as required." % [V, V]]
		bad = 1
	out.spot = {"lines": spot, "bad": bad, "ref": R_SPOT_START, "why": "a 'show that' must reach %d at the end, so it can't start by writing %s = %d" % [V, Sn, V]}
	return out


func u_common_difference(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var p: int = s.p
	var q: int = s.q
	var A: int = s.A
	var B: int = s.B
	var D: int = s.D
	var gap: int = q - p
	var W: int = B - A
	var up := sub("u", p)
	var uq := sub("u", q)
	var lines: Array = ["In an arithmetic sequence, %s = %s and %s = %s." % [up, N(A), uq, N(B)], "Show that the common difference is %d." % D]
	var right := "%s − %s = %dd, so %dd = %s − %s = %d and d = %d/%d = %d" % [uq, up, gap, gap, N(B), br(A), W, W, gap, D]
	var wrongs: Array = [
		["With d = %d, %s = %s + %d × %d = %s, which is true" % [D, uq, N(A), gap, D, N(B)], R_CHECK],
		["The terms go up evenly, so d = %d" % D, R_JUMP],
		["d = (%s − %s)/%d = %d/%d = %s" % [N(B), br(A), q, W, q, Q.new(W, q).text()], R_DIVISOR],
	]
	return _pack(lines, ASKED, right, wrongs, {
		"forward-derivation": ["%s and %s are %d terms apart, so %s − %s = %dd." % [up, uq, gap, uq, up, gap],
			"%dd = %s − %s = %d, so d = %d/%d = %d: the working ends at the given value." % [gap, N(B), br(A), W, W, gap, D]],
	})


# ── Money ────────────────────────────────────────────────────

func u_interest_value(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var pv: int = s.pv
	var n: int = s.n
	var V: Q = s.V
	var exact: float = s.exact
	var factor := "%.3f" % (1.0 + s.r.to_float() / 100.0)
	var factor_n := pow(1.0 + s.r.to_float() / 100.0, n)
	var shown := "$" + Fmt.money(V)
	var lines: Array = ["%s invests $%d in an account that pays %s%% per year, compounded annually." % [WHO[s.ctx], pv, Fmt.dec(s.r)],
		"Show that the value after %d years is %s, to the nearest cent." % [n, shown]]
	var four := "%.4f" % exact
	var right := "%d × %s^%d = %s, which is %s to the nearest cent" % [pv, factor, n, four, shown]
	var wrongs: Array = [
		["%s ÷ %s^%d = %d.00, the amount invested, so %s is right" % [Fmt.money(V), factor, n, pv, shown], R_CHECK],
		["After %d years the value is %s" % [n, shown], R_JUMP],
		["%d × %s^%d = %d to the nearest dollar, so the value is %s" % [pv, factor, n, roundi(exact), shown], R_ROUNDED],
	]
	var out := _pack(lines, ASKED, right, wrongs, {
		"forward-derivation": ["Use the compound interest formula: the value is %d × (1 + %s/100)^%d = %d × %s^%d." % [pv, Fmt.dec(s.r), n, pv, factor, n],
			"%s^%d = %s, so the value is %d × %s = %s, more figures than the given value." % [factor, n, "%.6f" % factor_n, pv, "%.6f" % factor_n, four],
			"Rounded to the nearest cent that is %s: the working ends at the given value." % shown],
	})
	var spot: Array = ["Value = %d × (1 + %s/100)^%d" % [pv, Fmt.dec(s.r), n], "= %d × %s^%d" % [pv, factor, n], "= %d" % roundi(exact), "= %s, as required." % Fmt.money(V)]
	var bad := 2
	if rng.chance(0.5):
		spot = ["Value = %d × %s^%d" % [pv, factor, n], "= %d" % roundi(exact), "= %s" % Fmt.money(V), "So the value is %s, as required." % shown]
		bad = 1
	out.spot = {"lines": spot, "bad": bad, "ref": R_SPOT_ROUND, "why": "a value rounded to the nearest dollar can't show the cents; the working needs more figures, %s, before it rounds to %s" % [four, shown]}
	return out


# ── Verify ───────────────────────────────────────────────────

static func quad_text(a: int, b: int, c: int) -> String:
	var lead := "x²" if a == 1 else "%dx²" % a
	var mid := "%s %s" % ["+" if b > 0 else "−", ("x" if absi(b) == 1 else "%dx" % absi(b))]
	var end := "%s %d" % ["+" if c > 0 else "−", absi(c)]
	return "%s %s %s" % [lead, mid, end]


func u_verify_solution(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var a: int = s.a
	var r: int = s.r
	var b: int = s.bb
	var c: int = s.cc
	var eq := quad_text(a, b, c) + " = 0"
	var sub_text := "%s(%s)² %s %s(%s) %s %d" % ["" if a == 1 else str(a), N(r), "+" if b > 0 else "−", str(absi(b)) if absi(b) != 1 else "", N(r), "+" if c > 0 else "−", absi(c)]
	var t1 := a * r * r
	var t2 := b * r
	var parts := "%d %s %d %s %d" % [t1, "+" if t2 >= 0 else "−", absi(t2), "+" if c > 0 else "−", absi(c)]
	var right := "%s = %s = 0, so x = %s is a solution" % [sub_text, parts, N(r)]
	var no_c := "%s(%s)² %s %s(%s)" % ["" if a == 1 else str(a), N(r), "+" if b > 0 else "−", str(absi(b)) if absi(b) != 1 else "", N(r)]
	var wrongs: Array = [
		["x = %s is a solution of the equation" % N(r), R_JUMP],
		["%s, so x = %s is a solution" % [sub_text, N(r)], R_UNWORKED],
		["%s = %s, so x = %s is a solution" % [no_c, N(t1 + t2), N(r)], R_NO_C],
	]
	return _pack(["Verify that x = %s is a solution of %s." % [N(r), eq]], ASKED, right, wrongs, {
		"verify": ["Verify asks only whether the value works, so put x = %s into the left side." % N(r), "%s = %s = 0, which is the right side." % [sub_text, parts]],
		"both-sides": ["Left side with x = %s: %s = %s = 0." % [N(r), sub_text, parts], "Right side: 0. The two sides are equal."],
	})
